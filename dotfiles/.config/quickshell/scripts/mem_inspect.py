#!/usr/bin/env python3
"""
Quickshell memory inspector.
Usage:
  python3 mem_inspect.py            # snapshot
  python3 mem_inspect.py --watch    # refresh every 3 s
  python3 mem_inspect.py --diff     # compare two snapshots (press Enter between)
  python3 mem_inspect.py --qml      # show QML/cache file mappings only
"""

import re
import sys
import time
import os
import subprocess
from collections import defaultdict
from pathlib import Path

RESET  = "\033[0m"
BOLD   = "\033[1m"
RED    = "\033[91m"
YELLOW = "\033[93m"
GREEN  = "\033[92m"
CYAN   = "\033[96m"
DIM    = "\033[2m"


def find_pid(name="quickshell"):
    try:
        out = subprocess.check_output(["pgrep", "-x", name], text=True).strip()
        pids = out.splitlines()
        return int(pids[0]) if pids else None
    except subprocess.CalledProcessError:
        return None


def parse_smaps(pid):
    path = f"/proc/{pid}/smaps"
    regions = []
    current = None
    try:
        with open(path) as f:
            for line in f:
                if re.match(r'^[0-9a-f]+-[0-9a-f]+', line):
                    if current:
                        regions.append(current)
                    parts = line.split()
                    current = {
                        "addr":   parts[0],
                        "perms":  parts[1],
                        "name":   " ".join(parts[5:]) if len(parts) > 5 else "[anon]",
                        "rss":    0,
                        "pss":    0,
                        "private_dirty": 0,
                        "private_clean": 0,
                        "shared_dirty":  0,
                        "shared_clean":  0,
                        "size":   0,
                    }
                elif current:
                    m = re.match(r'^(\w+):\s+(\d+) kB', line)
                    if m:
                        key = m.group(1).lower()
                        val = int(m.group(2))
                        if key == "rss":            current["rss"]    = val
                        elif key == "pss":          current["pss"]    = val
                        elif key == "private_dirty":current["private_dirty"] = val
                        elif key == "private_clean":current["private_clean"] = val
                        elif key == "shared_dirty": current["shared_dirty"]  = val
                        elif key == "shared_clean": current["shared_clean"]  = val
                        elif key == "size":         current["size"]   = val
        if current:
            regions.append(current)
    except PermissionError:
        print(f"{RED}Cannot read {path} — try running with sudo{RESET}")
        sys.exit(1)
    return regions


def categorize(regions):
    cats = defaultdict(lambda: {"rss": 0, "pss": 0, "private_dirty": 0, "count": 0, "names": []})

    for r in regions:
        name = r["name"]
        pd   = r["private_dirty"]
        rss  = r["rss"]
        pss  = r["pss"]

        if name == "[anon]" or name == "":
            cat = "anonymous (JS heap / Qt allocs)"
        elif name == "[stack]" or name.startswith("[stack:"):
            cat = "thread stacks"
        elif name == "[heap]":
            cat = "glibc heap"
        elif "/.cache/qml" in name or "qmlcache" in name.lower() or name.endswith(".qmlc"):
            cat = "QML disk cache (.qmlc)"
        elif name.endswith(".qml"):
            cat = "QML source files (mmap)"
        elif "JSGCHeap" in name or "JITCode" in name or "QtQml" in name:
            cat = "QML JS engine (GC heap / JIT)"
        elif "libQt" in name or "libqt" in name:
            cat = "Qt libraries"
        elif "libLLVM" in name or "libclang" in name:
            cat = "libLLVM (shader compiler)"
        elif "libGL" in name or "libEGL" in name or "libvulkan" in name or "nvidia" in name.lower() or "amdgpu" in name.lower() or "radeon" in name.lower() or "gallium" in name.lower() or "libcuda" in name.lower() or "libmesa" in name.lower():
            cat = "GPU / graphics libs"
        elif "libav" in name or "libx264" in name or "libx265" in name or "libaom" in name or "librav1e" in name or "ffmpeg" in name.lower() or "libsrt" in name or "libopenmpt" in name:
            cat = "FFmpeg / multimedia codecs"
        elif "quickshell" in name:
            cat = "quickshell binary"
        elif name.startswith("/"):
            cat = "other mapped files"
        elif name.startswith("["):
            cat = "kernel pseudo-regions"
        else:
            cat = "other anonymous"

        cats[cat]["rss"]           += rss
        cats[cat]["pss"]           += pss
        cats[cat]["private_dirty"] += pd
        cats[cat]["count"]         += 1
        if name not in cats[cat]["names"] and name not in ("[anon]", ""):
            cats[cat]["names"].append(name)

    return cats


def fmt_mb(kb):
    return f"{kb/1024:.1f} MB"


def fmt_bar(val, max_val, width=20):
    filled = int(width * val / max_val) if max_val else 0
    return "█" * filled + "░" * (width - filled)


def print_summary(regions, pid, label=""):
    cats  = categorize(regions)
    total_rss = sum(r["rss"] for r in regions)
    total_pss = sum(r["pss"] for r in regions)
    total_pd  = sum(r["private_dirty"] for r in regions)

    print(f"\n{BOLD}{CYAN}{'='*60}{RESET}")
    print(f"{BOLD}  Quickshell RAM (PID {pid}){f'  [{label}]' if label else ''}{RESET}")
    print(f"{CYAN}{'='*60}{RESET}")
    print(f"  {BOLD}RSS{RESET}           {fmt_mb(total_rss):>10}   (all mapped pages, incl. shared)")
    print(f"  {BOLD}PSS{RESET}           {fmt_mb(total_pss):>10}   (proportional — best 'true' footprint)")
    print(f"  {BOLD}Private Dirty{RESET} {fmt_mb(total_pd):>10}   (exclusively yours, not reclaimable)")
    print(f"{CYAN}{'-'*60}{RESET}")
    print(f"  {'Category':<38} {'PSS':>7}  {'Priv.Dirty':>10}")
    print(f"{DIM}  {'-'*57}{RESET}")

    sorted_cats = sorted(cats.items(), key=lambda x: x[1]["pss"], reverse=True)
    max_pss = sorted_cats[0][1]["pss"] if sorted_cats else 1

    for cat, info in sorted_cats:
        bar   = fmt_bar(info["pss"], max_pss, 10)
        color = RED if info["pss"] > 50_000 else (YELLOW if info["pss"] > 20_000 else GREEN)
        print(f"  {color}{cat:<38}{RESET} {fmt_mb(info['pss']):>7}  {fmt_mb(info['private_dirty']):>10}  {DIM}{bar}{RESET}")

    print(f"{CYAN}{'='*60}{RESET}\n")


def print_qml_mappings(regions, pid):
    """Show which QML source files and cache files are mapped."""
    print(f"\n{BOLD}{CYAN}  QML File Mappings (PID {pid}){RESET}")
    print(f"{CYAN}{'-'*60}{RESET}")
    qml_total = 0
    cache_total = 0
    rows = []
    for r in regions:
        name = r["name"]
        if name.endswith(".qml") or ".qmlc" in name or "qmlcache" in name.lower():
            rows.append((r["pss"], r["rss"], name))
            if ".qmlc" in name or "qmlcache" in name.lower():
                cache_total += r["rss"]
            else:
                qml_total += r["rss"]

    rows.sort(reverse=True)
    if not rows:
        print(f"  {DIM}No QML files found in mappings (they may be in anonymous regions after compilation){RESET}")
    else:
        for pss, rss, name in rows:
            short = name.replace("/home/steel/.config/quickshell/", "~/qs/")
            short = short.replace("/home/steel/.cache/", "~/.cache/")
            print(f"  {fmt_mb(rss):>8} RSS  {short}")
        print(f"\n  QML sources: {fmt_mb(qml_total)}  |  QML cache: {fmt_mb(cache_total)}")

    print(f"{CYAN}{'='*60}{RESET}\n")


def print_anon_detail(regions):
    """Break down anonymous regions by size buckets."""
    anon = [r for r in regions if r["name"] in ("[anon]", "") or not r["name"]]
    if not anon:
        return

    anon.sort(key=lambda x: x["private_dirty"], reverse=True)
    big   = [r for r in anon if r["private_dirty"] > 10_000]
    total = sum(r["private_dirty"] for r in anon)

    print(f"{BOLD}  Anonymous regions > 10 MB (private dirty):{RESET}")
    for r in big[:15]:
        addr_short = r["addr"].split("-")[0]
        print(f"    0x{addr_short}  {fmt_mb(r['private_dirty']):>8} priv  {fmt_mb(r['rss']):>8} rss  perms={r['perms']}")
    print(f"    ... ({len(anon)} anon regions total, {fmt_mb(total)} private dirty)\n")


def snapshot(pid):
    regions = parse_smaps(pid)
    print_summary(regions, pid)
    print_anon_detail(regions)
    return regions


def diff_snapshots(a, b):
    def totals(regions):
        return {
            "rss": sum(r["rss"] for r in regions),
            "pss": sum(r["pss"] for r in regions),
            "pd":  sum(r["private_dirty"] for r in regions),
        }
    ta, tb = totals(a), totals(b)
    print(f"\n{BOLD}  Delta (B - A):{RESET}")
    for k in ("rss", "pss", "pd"):
        d = tb[k] - ta[k]
        color = RED if d > 5000 else (GREEN if d < -5000 else RESET)
        sign  = "+" if d >= 0 else ""
        print(f"    {k.upper():>10}: {color}{sign}{fmt_mb(d)}{RESET}")
    print()


def main():
    args = set(sys.argv[1:])
    watch = "--watch" in args
    diff  = "--diff"  in args
    qml   = "--qml"   in args

    pid = find_pid()
    if not pid:
        print(f"{RED}quickshell process not found{RESET}")
        sys.exit(1)

    if diff:
        print(f"Snapshot A taken. Open a panel or do something, then press Enter...")
        a = parse_smaps(pid)
        print_summary(a, pid, "A")
        input()
        b = parse_smaps(pid)
        print_summary(b, pid, "B")
        diff_snapshots(a, b)
        return

    if qml:
        regions = parse_smaps(pid)
        print_qml_mappings(regions, pid)
        return

    if watch:
        try:
            while True:
                os.system("clear")
                snapshot(pid)
                print(f"{DIM}  Refreshing every 3 s — Ctrl+C to stop{RESET}")
                time.sleep(3)
        except KeyboardInterrupt:
            pass
        return

    snapshot(pid)
    print(f"{DIM}  Tips:{RESET}")
    print(f"{DIM}  --watch   live monitor{RESET}")
    print(f"{DIM}  --diff    measure RAM change from an action{RESET}")
    print(f"{DIM}  --qml     show which QML files are mapped{RESET}")
    print(f"{DIM}  QV4_MM_STATS=1 quickshell   JS GC heap report on exit{RESET}")
    print(f"{DIM}  QT_QUICK_PIXMAP_CACHE_LIMIT=30720 quickshell   limit pixmap cache to 30 MB{RESET}\n")


if __name__ == "__main__":
    main()
