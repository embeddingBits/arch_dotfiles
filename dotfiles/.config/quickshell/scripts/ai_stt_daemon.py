#!/usr/bin/env python3
"""
Resident speech-to-text worker for the ai overlay.

    quickshell  <--line-delimited JSON on stdin/stdout-->  this  -->  faster-whisper

Why a daemon rather than invoking a CLI per transcription: whisper-cli reloads
its model on every single call (~700-900ms before it does any work). Here the
model loads once and every request afterwards is pure inference.

Requests (one JSON object per line on stdin):
    {"cmd": "final", "id": N, "path": "/path/to/finished.wav"}
    {"cmd": "load"}                 warm the model up before it is needed

Responses (one JSON object per line on stdout):
    {"type": "ready", "backend": "..."}     model resident, requests will be fast
    {"type": "final",   "id": N, "text": "..."}
    {"type": "error",   "id": N, "message": "..."}
"""

import json
import os
import re
import sys

SAMPLE_RATE = 16000
WAV_HEADER_BYTES = 44          # parecord writes a canonical 44-byte header
BYTES_PER_SAMPLE = 2           # s16le mono

# GPU first, CPU as a fallback. distil-large-v3 is the most accurate model that
# fits comfortably (about 1.1 GB of the 1650 Ti's 4 GB) and still beats small.en
# on CPU for speed: ~1.7s vs ~3.8s on a 10s recording.
MODEL_NAME = os.environ.get("QS_AI_FW_MODEL", "distil-large-v3")
CUDA_COMPUTE = os.environ.get("QS_AI_FW_COMPUTE", "int8_float16")
DEVICE = os.environ.get("QS_AI_FW_DEVICE", "auto")

# Fallback if CUDA is unusable — a smaller model, since CPU pays for size.
CPU_MODEL_NAME = os.environ.get("QS_AI_FW_CPU_MODEL", "base.en")
CPU_COMPUTE = "int8"

# Off by default: see the note in transcribe().
VAD_FILTER = os.environ.get("QS_AI_VAD_FILTER", "0") not in ("0", "", "false")

# Vocabulary priming. Whisper leans toward words it has already seen, so listing
# terms it keeps mangling makes it far likelier to produce them.
INITIAL_PROMPT = os.environ.get("QS_AI_PROMPT", "")

# Whisper emits these for non-speech; they are not words.
NOISE_RE = re.compile(r"\[[A-Z_ ]+\]|\([^)]*\)")

_model = None
_backend = None


def emit(obj):
    sys.stdout.write(json.dumps(obj) + "\n")
    sys.stdout.flush()


def preload_cuda_libs():
    """
    Make the CUDA 12 libraries visible to ctranslate2.

    ctranslate2 links against CUDA 12 while this machine has CUDA 13, so
    libcublas.so.12 is missing and GPU inference dies with "Library
    libcublas.so.12 is not found". The nvidia-*-cu12 wheels ship those exact
    libraries, but the dynamic loader only searches LD_LIBRARY_PATH, which has
    to be set before the process starts. Opening them RTLD_GLOBAL from inside
    the process has the same effect without needing the caller's cooperation.
    """
    try:
        import nvidia.cublas.lib
        import nvidia.cudnn.lib
    except ImportError:
        return False

    import ctypes
    import glob

    found = 0
    for mod in (nvidia.cublas.lib, nvidia.cudnn.lib):
        for directory in mod.__path__:
            for so in sorted(glob.glob(os.path.join(directory, "*.so*"))):
                try:
                    ctypes.CDLL(so, mode=ctypes.RTLD_GLOBAL)
                    found += 1
                except OSError:
                    pass
    return found > 0


def get_model():
    global _model, _backend
    if _model is not None:
        return _model

    from faster_whisper import WhisperModel  # imported late: ~1s of import time
    import numpy as np

    attempts = []
    if DEVICE in ("auto", "cuda") and preload_cuda_libs():
        attempts.append((MODEL_NAME, "cuda", CUDA_COMPUTE))
    if DEVICE != "cuda":
        attempts.append((CPU_MODEL_NAME, "cpu", CPU_COMPUTE))

    errors = []
    for name, device, compute in attempts:
        try:
            model = WhisperModel(name, device=device, compute_type=compute)
            # Constructing the model succeeds even when the CUDA libraries are
            # missing — it only fails once something actually runs. So force a
            # tiny inference here rather than discovering it mid-dictation.
            list(model.transcribe(np.zeros(1600, dtype=np.float32), language="en")[0])
            _model, _backend = model, "%s on %s (%s)" % (name, device, compute)
            return _model
        except Exception as e:
            errors.append("%s/%s: %s" % (name, device, e))

    raise RuntimeError("no usable backend -- " + " | ".join(errors))


def read_pcm(path, window_s=None):
    """
    Read a capture as float32 mono, skipping the wav header outright.

    parecord only patches the RIFF data-length field when it exits, and reading
    raw bytes past the header is immune to that either way — so this works on a
    capture that is still open as well as a finished one.
    """
    import numpy as np

    with open(path, "rb") as fh:
        fh.seek(0, os.SEEK_END)
        size = fh.tell()

        data_bytes = size - WAV_HEADER_BYTES
        if data_bytes <= 0:
            return None

        start = WAV_HEADER_BYTES
        if window_s is not None:
            want = int(window_s * SAMPLE_RATE) * BYTES_PER_SAMPLE
            if data_bytes > want:
                start = size - want
                # Keep the offset on a sample boundary or the audio turns to noise.
                start -= (start - WAV_HEADER_BYTES) % BYTES_PER_SAMPLE

        fh.seek(start)
        raw = fh.read()

    if len(raw) < BYTES_PER_SAMPLE:
        return None
    raw = raw[: len(raw) - (len(raw) % BYTES_PER_SAMPLE)]
    return np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0


def clean(text):
    text = NOISE_RE.sub("", text)
    return re.sub(r"\s+", " ", text).strip()


def transcribe(path, window_s):
    pcm = read_pcm(path, window_s)
    if pcm is None or len(pcm) < SAMPLE_RATE // 4:   # under 0.25s, nothing to say
        return ""

    # vad_filter is deliberately OFF. Silero VAD drops audio it judges to be
    # non-speech *before* whisper sees it, which silently eats quiet or trailing
    # words — the recording here is already bounded by the user pressing stop, so
    # there is no long silence to skip and nothing to gain. It existed to make
    # the old live preview cheap; that preview no longer exists.
    segments, _info = get_model().transcribe(
        pcm,
        language="en",
        vad_filter=VAD_FILTER,
        condition_on_previous_text=False,
        initial_prompt=INITIAL_PROMPT or None,
    )
    return clean(" ".join(s.text for s in segments))


def main():
    for line in sys.stdin:
        line = line.strip()
        if not line:
            continue

        try:
            req = json.loads(line)
        except ValueError:
            continue

        cmd = req.get("cmd")
        rid = req.get("id")

        try:
            if cmd == "load":
                get_model()
                emit({"type": "ready", "backend": _backend})
            elif cmd == "final":
                emit({"type": "final", "id": rid,
                      "text": transcribe(req["path"], None)})
        except FileNotFoundError:
            emit({"type": "error", "id": rid, "message": "recording not found"})
        except Exception as e:                       # never let one bad request kill the worker
            emit({"type": "error", "id": rid,
                  "message": "%s: %s" % (type(e).__name__, e)})

    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        sys.exit(0)
