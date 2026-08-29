#!/bin/bash
CACHE_DIR="$HOME/.cache/quickshell/holidays"
YEAR=${1:-$(date +%Y)}
CACHE_FILE="$CACHE_DIR/$YEAR.json"

mkdir -p "$CACHE_DIR"

# Return cached if exists
if [ -f "$CACHE_FILE" ]; then
    cat "$CACHE_FILE"
    exit 0
fi

# Fetch and parse
echo "Fetching holidays for $YEAR..." >&2

gcalcli --nocolor agenda "1/1/$YEAR" "12/31/$YEAR" | \
awk -v year="$YEAR" '
BEGIN { 
    print "[" 
    first = 1
    # Month name to number mapping
    month_num["Jan"] = 1; month_num["Feb"] = 2; month_num["Mar"] = 3
    month_num["Apr"] = 4; month_num["May"] = 5; month_num["Jun"] = 6
    month_num["Jul"] = 7; month_num["Aug"] = 8; month_num["Sep"] = 9
    month_num["Oct"] = 10; month_num["Nov"] = 11; month_num["Dec"] = 12
    
    # Full month names
    full_month["Jan"] = "January"; full_month["Feb"] = "February"
    full_month["Mar"] = "March"; full_month["Apr"] = "April"
    full_month["May"] = "May"; full_month["Jun"] = "June"
    full_month["Jul"] = "July"; full_month["Aug"] = "August"
    full_month["Sep"] = "September"; full_month["Oct"] = "October"
    full_month["Nov"] = "November"; full_month["Dec"] = "December"
    
    # Full day names
    day_name["Mon"] = "Monday"; day_name["Tue"] = "Tuesday"
    day_name["Wed"] = "Wednesday"; day_name["Thu"] = "Thursday"
    day_name["Fri"] = "Friday"; day_name["Sat"] = "Saturday"
    day_name["Sun"] = "Sunday"
}

/^[A-Z][a-z]{2} [A-Z][a-z]{2} [0-9]{2}/ {
    # Parse new date line
    dow_short = $1
    month_short = $2
    day_num = int($3)

    # Get holiday name
    name = ""
    for (i = 4; i <= NF; i++) {
        name = name (i > 4 ? " " : "") $i
    }

    # Escape quotes
    gsub(/"/, "\\\"", name)

    if (!first) print ","
    first = 0

    printf "  {"
    printf "\"date\":\"%04d-%02d-%02d\",", year, month_num[month_short], day_num
    printf "\"day\":%d,", day_num
    printf "\"month\":\"%s\",", full_month[month_short]
    printf "\"monthNum\":%d,", month_num[month_short]
    printf "\"year\":%d,", year
    printf "\"dayOfWeek\":\"%s\",", day_name[dow_short]
    printf "\"dayOfWeekShort\":\"%s\",", dow_short
    printf "\"name\":\"%s\"", name
    printf "}"
    next
}

/^[[:space:]]/ {
    # Continuation line (same date as current)
    name = $0
    gsub(/^[[:space:]]+/, "", name)
    gsub(/"/, "\\\"", name)

    if (name != "") {
        print ","
        printf "  {"
        printf "\"date\":\"%04d-%02d-%02d\",", year, month_num[month_short], day_num
        printf "\"day\":%d,", day_num
        printf "\"month\":\"%s\",", full_month[month_short]
        printf "\"monthNum\":%d,", month_num[month_short]
        printf "\"year\":%d,", year
        printf "\"dayOfWeek\":\"%s\",", day_name[dow_short]
        printf "\"dayOfWeekShort\":\"%s\",", dow_short
        printf "\"name\":\"%s\"", name
        printf "}"
    }
}

END { 
    print ""
    print "]" 
}
' > "$CACHE_FILE"

cat "$CACHE_FILE"
