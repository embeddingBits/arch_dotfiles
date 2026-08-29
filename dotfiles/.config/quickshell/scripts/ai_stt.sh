#!/usr/bin/env bash
# Recording and transcription for the ai overlay.
#
#   ai_stt.sh check                 report anything missing, exit 1 if unusable
#
# Transcription lives in ai_stt_daemon.py (faster-whisper, model kept
# resident). This script only handles capture and the environment check.
#   ai_stt.sh record <out.wav>      record until killed (quickshell kills it to stop)
#   ai_stt.sh transcribe <in.wav>   print the transcript on stdout, nothing else
#
# Errors go to stderr prefixed with "ERR:" so ServiceAi can surface them verbatim.

set -uo pipefail

MODEL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/quickshell/whisper"
MODEL_NAME="${QS_AI_MODEL:-ggml-base.en.bin}"
MODEL_PATH="$MODEL_DIR/$MODEL_NAME"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$MODEL_NAME"

# The live preview re-transcribes a rolling window every couple of seconds, so
# it runs a smaller model than the authoritative pass. Accuracy there costs
# nothing — the preview never decides what gets sent.
STREAM_MODEL_NAME="${QS_AI_STREAM_MODEL:-ggml-tiny.en.bin}"
STREAM_MODEL_PATH="$MODEL_DIR/$STREAM_MODEL_NAME"
STREAM_MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$STREAM_MODEL_NAME"

# Package has used a few names across versions; take whichever exists.
find_whisper() {
  for c in whisper-cli whisper-cpp whisper.cpp main; do
    if command -v "$c" >/dev/null 2>&1; then echo "$c"; return 0; fi
  done
  return 1
}

die() { echo "ERR: $*" >&2; exit 1; }

cmd_check() {
  local ok=0
  local venv="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell/.venv/bin/python"

  command -v parecord >/dev/null 2>&1 || { echo "ERR: parecord not found (libpulse)" >&2; ok=1; }

  if [ ! -x "$venv" ]; then
    echo "ERR: python venv missing at $venv" >&2
    ok=1
  elif ! "$venv" -c "import faster_whisper" 2>/dev/null; then
    echo "ERR: faster-whisper not installed — uv pip install --python $venv faster-whisper" >&2
    ok=1
  fi

  # whisper-cli and the ggml models are only used by the `transcribe` debug
  # subcommand now; their absence is not fatal.
  find_whisper >/dev/null || echo "note: whisper-cli absent (only affects '$0 transcribe')" >&2
  [ "$ok" -eq 0 ] && echo "ok"
  return $ok
}

_fetch_one() {
  local name="$1" path="$2" url="$3"
  if [ -f "$path" ]; then
    echo "already present: $path"
    return 0
  fi
  echo "downloading $name -> $path"
  curl -fL --progress-bar -o "$path.part" "$url" || die "download failed: $name"
  mv "$path.part" "$path"
  echo "done: $(du -h "$path" | cut -f1)"
}

cmd_fetch_model() {
  mkdir -p "$MODEL_DIR"
  _fetch_one "$MODEL_NAME" "$MODEL_PATH" "$MODEL_URL"
  _fetch_one "$STREAM_MODEL_NAME" "$STREAM_MODEL_PATH" "$STREAM_MODEL_URL"
}

cmd_record() {
  local out="${1:-}"
  [ -n "$out" ] || die "record needs an output path"
  mkdir -p "$(dirname "$out")"
  rm -f "$out"
  # 16 kHz mono is what whisper resamples to anyway; recording it directly
  # avoids a conversion step. exec so quickshell's kill lands on parecord itself
  # rather than on a wrapping shell that would leave it orphaned.
  #
  # --latency-msec is not a nicety: at the default buffer size parecord drops
  # roughly the first second of audio before samples start flowing, which clips
  # the first word of every dictation. At 20ms the startup gap is ~40ms.
  exec parecord \
    --rate=16000 \
    --channels=1 \
    --format=s16le \
    --latency-msec=20 \
    --file-format=wav \
    ${QS_AI_SOURCE:+--device="$QS_AI_SOURCE"} \
    "$out"
}

cmd_transcribe() {
  local in="${1:-}"
  [ -n "$in" ] || die "transcribe needs an input path"
  [ -f "$in" ] || die "no recording was produced"

  local bin
  bin="$(find_whisper)" || die "whisper not found — install with: sudo pacman -S whisper-cpp"
  [ -f "$MODEL_PATH" ] || die "model missing at $MODEL_PATH"

  # A wav header alone is 44 bytes; anything near that captured no audio.
  local size
  size=$(stat -c%s "$in" 2>/dev/null || echo 0)
  [ "$size" -gt 8000 ] || die "didn't hear anything"

  # Reject near-silence so we never send an empty prompt to the browser.
  if command -v sox >/dev/null 2>&1; then
    local peak
    peak=$(sox "$in" -n stat 2>&1 | awk '/Maximum amplitude/ {print $3}')
    if [ -n "$peak" ] && awk "BEGIN{exit !($peak < 0.012)}"; then
      die "didn't hear anything"
    fi
  fi

  local text
  text=$("$bin" -m "$MODEL_PATH" -f "$in" -l en -nt -np -t "$(nproc)" 2>/dev/null)
  local rc=$?
  [ $rc -eq 0 ] || die "whisper failed (exit $rc)"

  # Collapse whitespace, drop whisper's bracketed non-speech markers.
  text=$(printf '%s' "$text" \
    | sed -E 's/\[[A-Z_]+\]//g; s/\([^)]*\)//g' \
    | tr '\n' ' ' \
    | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//')

  [ -n "$text" ] || die "didn't hear anything"
  printf '%s' "$text"
}

case "${1:-}" in
  check)       shift; cmd_check "$@" ;;
  fetch-model) shift; cmd_fetch_model "$@" ;;
  record)      shift; cmd_record "$@" ;;
  transcribe)  shift; cmd_transcribe "$@" ;;
  *)           die "usage: $0 {check|fetch-model|record|transcribe}" ;;
esac
