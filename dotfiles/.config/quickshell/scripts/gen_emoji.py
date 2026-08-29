#!/usr/bin/env python3
"""Generate assets/emoji.json for the launcher's `:` emoji mode.

Uses only the stdlib `unicodedata` table, so there is nothing to install and
nothing to fetch at runtime. Run once after checkout (install.sh calls it);
re-run only when you want to pick up a newer Python's Unicode tables.

    python3 scripts/gen_emoji.py
"""

import json
import os
import sys
import unicodedata

# Blocks that are pictographic emoji end to end. Ranges are inclusive.
PICTOGRAPHIC_BLOCKS = [
    (0x1F300, 0x1F5FF),  # Misc Symbols and Pictographs
    (0x1F600, 0x1F64F),  # Emoticons
    (0x1F680, 0x1F6FF),  # Transport and Map
    (0x1F900, 0x1F9FF),  # Supplemental Symbols and Pictographs
    (0x1FA70, 0x1FAFF),  # Symbols and Pictographs Extended-A
]

# Misc Symbols / Dingbats are mixed bags — they hold real emoji alongside
# typographic marks, chess pieces and arrows. Take the emoji-presentation
# stretches rather than the whole blocks.
CURATED_RANGES = [
    (0x2600, 0x2604), (0x260E, 0x260E), (0x2611, 0x2611),
    (0x2614, 0x2615), (0x2618, 0x2618), (0x261D, 0x261D),
    (0x2620, 0x2620), (0x2622, 0x2623), (0x2626, 0x2626),
    (0x262A, 0x262A), (0x262E, 0x262F), (0x2638, 0x263A),
    (0x2640, 0x2640), (0x2642, 0x2642), (0x2648, 0x2653),
    (0x265F, 0x2660), (0x2663, 0x2663), (0x2665, 0x2666),
    (0x2668, 0x2668), (0x267B, 0x267B), (0x267E, 0x267F),
    (0x2692, 0x2697), (0x2699, 0x2699), (0x269B, 0x269C),
    (0x26A0, 0x26A1), (0x26A7, 0x26A7), (0x26AA, 0x26AB),
    (0x26B0, 0x26B1), (0x26BD, 0x26BE), (0x26C4, 0x26C5),
    (0x26C8, 0x26C8), (0x26CE, 0x26CF), (0x26D1, 0x26D1),
    (0x26D3, 0x26D4), (0x26E9, 0x26EA), (0x26F0, 0x26F5),
    (0x26F7, 0x26FA), (0x26FD, 0x26FD),
    (0x2702, 0x2702), (0x2705, 0x2705), (0x2708, 0x270D),
    (0x270F, 0x270F), (0x2712, 0x2712), (0x2714, 0x2714),
    (0x2716, 0x2716), (0x271D, 0x271D), (0x2721, 0x2721),
    (0x2728, 0x2728), (0x2733, 0x2734), (0x2744, 0x2744),
    (0x2747, 0x2747), (0x274C, 0x274C), (0x274E, 0x274E),
    (0x2753, 0x2755), (0x2757, 0x2757), (0x2763, 0x2764),
    (0x2795, 0x2797), (0x27A1, 0x27A1), (0x27B0, 0x27B0),
    (0x27BF, 0x27BF),
    (0x1F004, 0x1F004), (0x1F0CF, 0x1F0CF),
    (0x1F170, 0x1F171), (0x1F17E, 0x1F17F), (0x1F18E, 0x1F18E),
    (0x1F191, 0x1F19A),
]

# Unassigned-but-in-block codepoints raise ValueError from ud.name(); those are
# skipped. These prefixes are assigned but are not emoji people search for.
NAME_PREFIX_BLOCKLIST = (
    "VARIATION SELECTOR",
    "ZERO WIDTH",
    "TAG ",
    "REGIONAL INDICATOR",
)

# Extra search terms the Unicode names don't give you. `:fire` already works
# because the name is FIRE, but nobody searches for "GRINNING FACE" when they
# want :happy.
EXTRA_KEYWORDS = {
    "😀": "happy smile grin",
    "😂": "lol laugh cry funny",
    "🤣": "lol rofl laugh",
    "😊": "happy blush smile",
    "😍": "love heart eyes",
    "🥰": "love hearts adore",
    "😎": "cool sunglasses",
    "😭": "sad cry sob",
    "😡": "angry mad rage",
    "🤔": "think hmm consider",
    "🙃": "upside down sarcasm",
    "😴": "sleep tired zzz",
    "🤦": "facepalm",
    "🤷": "shrug idk",
    "👍": "thumbsup yes good approve lgtm",
    "👎": "thumbsdown no bad",
    "👏": "clap applause",
    "🙏": "pray thanks please",
    "💪": "strong muscle flex",
    "🔥": "fire lit hot burn",
    "💯": "hundred perfect score",
    "🎉": "party celebrate tada",
    "🚀": "rocket ship launch fast deploy",
    "✅": "check done yes tick",
    "❌": "cross no wrong fail",
    "⚠️": "warning caution alert",
    "🐛": "bug insect defect",
    "💡": "idea lightbulb tip",
    "📌": "pin pinned",
    "🔗": "link url",
    "⭐": "star favorite",
    "❤️": "heart love red",
    "👀": "eyes look watch",
    "🤖": "robot bot ai",
    "🎯": "target goal bullseye",
    "🧠": "brain smart mind",
    "☕": "coffee cafe tea",
    "🍕": "pizza food",
    "😅": "sweat nervous laugh",
    "🥲": "tear smile happy sad",
    "💀": "skull dead dying",
    "🫠": "melt melting",
    "🙌": "raise hands celebrate",
}


def wanted(cp: int) -> bool:
    for lo, hi in PICTOGRAPHIC_BLOCKS:
        if lo <= cp <= hi:
            return True
    for lo, hi in CURATED_RANGES:
        if lo <= cp <= hi:
            return True
    return False


def build():
    out = []
    seen = set()

    for lo, hi in PICTOGRAPHIC_BLOCKS + CURATED_RANGES:
        for cp in range(lo, hi + 1):
            if cp in seen or not wanted(cp):
                continue
            ch = chr(cp)
            try:
                name = unicodedata.name(ch)
            except ValueError:
                continue  # unassigned in this Python's Unicode table
            if name.startswith(NAME_PREFIX_BLOCKLIST):
                continue
            seen.add(cp)

            label = name.title()
            keywords = name.lower().replace("-", " ")
            extra = EXTRA_KEYWORDS.get(ch)
            if extra:
                keywords += " " + extra

            out.append({"ch": ch, "name": label, "kw": keywords})

    out.sort(key=lambda e: e["name"])
    return out


def main():
    here = os.path.dirname(os.path.abspath(__file__))
    dest = os.path.join(os.path.dirname(here), "assets", "emoji.json")
    os.makedirs(os.path.dirname(dest), exist_ok=True)

    data = build()

    # Atomic write so a half-written file can never be read by the shell.
    tmp = dest + ".tmp"
    with open(tmp, "w", encoding="utf-8") as fh:
        json.dump(data, fh, ensure_ascii=False, separators=(",", ":"))
    os.replace(tmp, dest)

    print(f"wrote {len(data)} emoji to {dest}", file=sys.stderr)


if __name__ == "__main__":
    main()
