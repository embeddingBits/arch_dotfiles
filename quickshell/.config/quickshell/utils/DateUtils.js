.pragma library

function pad2(v) {
    var n = Number(v);
    return (n < 10 ? "0" : "") + n;
}

function dateKey(y, m, d) {
    return y + "-" + pad2(m + 1) + "-" + pad2(d);
}

function dayOfYear(y, m, d) {
    return Math.round((Date.UTC(y, m, d) - Date.UTC(y, 0, 1)) / 86400000) + 1;
}

function daysInYear(y) {
    return dayOfYear(y, 11, 31);
}

function yearProgress(y, m, d) {
    var tot = daysInYear(y);
    if (tot <= 0)
        return 0;
    return Math.max(0, Math.min(1, (dayOfYear(y, m, d) - 1) / tot));
}

function isoWeek(y, m, d) {
    var dt = new Date(Date.UTC(y, m, d));
    var wd = dt.getUTCDay() || 7;
    dt.setUTCDate(dt.getUTCDate() + 4 - wd);
    var ys = new Date(Date.UTC(dt.getUTCFullYear(), 0, 1));
    return Math.ceil(((dt.getTime() - ys.getTime()) / 86400000 + 1) / 7);
}

function weekdayOrder(start) {
    var s = ((start % 7) + 7) % 7;
    var o = [];
    for (var i = 0; i < 7; i++)
        o.push((s + i) % 7);
    return o;
}

function monthGrid(year, month, weekStart, todayKey) {
    var start = ((weekStart % 7) + 7) % 7;
    var leading = (new Date(year, month, 1).getDay() - start + 7) % 7;
    var cursor = new Date(year, month, 1 - leading);
    var tk = String(todayKey || "");
    var weeks = [];

    for (var w = 0; w < 6; w++) {
        var days = [];
        var th = null;
        for (var d = 0; d < 7; d++) {
            var cy = cursor.getFullYear();
            var cm = cursor.getMonth();
            var cd = cursor.getDate();
            var wd = cursor.getDay();
            var k = dateKey(cy, cm, cd);
            if (wd === 4)
                th = {
                    year: cy,
                    month: cm,
                    day: cd
                };
            days.push({
                key: k,
                year: cy,
                month: cm,
                day: cd,
                weekday: wd,
                inMonth: cm === month && cy === year,
                weekend: wd === 0 || wd === 6,
                today: k === tk
            });
            cursor.setDate(cursor.getDate() + 1);
        }
        var anchor = th || days[0];
        weeks.push({
            week: isoWeek(anchor.year, anchor.month, anchor.day),
            days: days
        });
    }
    return weeks;
}
