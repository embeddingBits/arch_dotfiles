#!/usr/bin/env python3
import json
import os
import re
import sys
import urllib.error
import urllib.request
from datetime import date

CACHE_DIR = os.path.expanduser("~/.cache/quickshell/holidays")
NAGER_URL = "https://date.nager.at/api/v3/PublicHolidays/{year}/{cc}"
ICS_URL = (
    "https://calendar.google.com/calendar/ical/"
    "{cid}%23holiday%40group.v.calendar.google.com/public/basic.ics"
)

ICS_ALT = {"IN": "en.indian", "MY": "en.malaysia", "TW": "en.taiwan", "IL": "en.jewish"}

MONTHS = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
]
DAYS = [
    "Monday", "Tuesday", "Wednesday", "Thursday",
    "Friday", "Saturday", "Sunday",
]


def detect_country():
    tz = ""
    try:
        tz = os.path.realpath("/etc/localtime").split("zoneinfo/")[-1]
    except OSError:
        pass
    if tz:
        try:
            with open("/usr/share/zoneinfo/zone.tab") as f:
                for line in f:
                    if line.startswith("#"):
                        continue
                    parts = line.split()
                    if len(parts) >= 3 and parts[2] == tz:
                        return parts[0]
        except OSError:
            pass
    for var in ("LC_TIME", "LC_ALL", "LANG"):
        m = re.search(r"_([A-Za-z]{2})", os.environ.get(var, ""))
        if m:
            return m.group(1)
    return ""


def fetch(url, timeout=20):
    req = urllib.request.Request(url, headers={"User-Agent": "quickshell-holidays"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            if r.status != 200:
                return None
            body = r.read().decode("utf-8", "replace")
            return body or None
    except (urllib.error.URLError, urllib.error.HTTPError, OSError, ValueError):
        return None


def entry(d, name):
    return {
        "date": d.isoformat(),
        "day": d.day,
        "month": MONTHS[d.month - 1],
        "monthNum": d.month,
        "year": d.year,
        "dayOfWeek": DAYS[d.weekday()],
        "dayOfWeekShort": DAYS[d.weekday()][:3],
        "name": name,
    }


def from_nager(year, cc):
    body = fetch(NAGER_URL.format(year=year, cc=cc))
    if not body:
        return []
    try:
        raw = json.loads(body)
    except ValueError:
        return []
    if not isinstance(raw, list):
        return []
    out = []
    for h in raw:
        try:
            y, m, d = (int(p) for p in h["date"].split("-"))
            name = h.get("localName") or h.get("name") or ""
            if name:
                out.append(entry(date(y, m, d), name))
        except (KeyError, TypeError, ValueError):
            continue
    return out


def unescape(text):
    return (
        text.replace("\\n", " ")
        .replace("\\N", " ")
        .replace("\\,", ",")
        .replace("\\;", ";")
        .replace("\\\\", "\\")
        .strip()
    )


def from_ics(year, cc):
    for cid in (f"en.{cc.lower()}", ICS_ALT.get(cc)):
        if not cid:
            continue
        body = fetch(ICS_URL.format(cid=cid))
        if not body:
            continue
        body = body.replace("\r\n", "\n").replace("\n ", "").replace("\n\t", "")
        out = []
        for block in re.findall(r"BEGIN:VEVENT(.*?)END:VEVENT", body, re.S):
            start = re.search(r"^DTSTART[^:\n]*:(\d{8})", block, re.M)
            summary = re.search(r"^SUMMARY[^:\n]*:(.*)$", block, re.M)
            if not start or not summary:
                continue
            stamp = start.group(1)
            try:
                d = date(int(stamp[:4]), int(stamp[4:6]), int(stamp[6:8]))
            except ValueError:
                continue
            if d.year != year:
                continue
            name = unescape(summary.group(1))
            if name:
                out.append(entry(d, name))
        if out:
            return out
    return []


def dedupe(rows):
    seen = set()
    out = []
    for r in sorted(rows, key=lambda r: (r["date"], r["name"])):
        key = (r["date"], r["name"])
        if key in seen:
            continue
        seen.add(key)
        out.append(r)
    return out


def main():
    year = date.today().year
    if len(sys.argv) > 1 and sys.argv[1].strip():
        try:
            year = int(sys.argv[1])
        except ValueError:
            pass

    cc = sys.argv[2].strip().upper() if len(sys.argv) > 2 else ""
    if not cc:
        cc = detect_country().upper()
    if not re.fullmatch(r"[A-Z]{2}", cc):
        print("[]")
        return 1

    cache_file = os.path.join(CACHE_DIR, f"{cc}-{year}.json")
    try:
        with open(cache_file) as f:
            cached = json.load(f)
        if isinstance(cached, list) and cached:
            print(json.dumps(cached))
            return 0
    except (OSError, ValueError):
        pass

    rows = dedupe(from_nager(year, cc) or from_ics(year, cc))
    if not rows:
        print("[]")
        return 1

    payload = json.dumps(rows)
    try:
        os.makedirs(CACHE_DIR, exist_ok=True)
        tmp = cache_file + ".tmp"
        with open(tmp, "w") as f:
            f.write(payload)
        os.replace(tmp, cache_file)
    except OSError:
        pass

    print(payload)
    return 0


if __name__ == "__main__":
    sys.exit(main())
