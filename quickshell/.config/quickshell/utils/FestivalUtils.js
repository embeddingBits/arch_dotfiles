.pragma library

.import "DateUtils.js" as DateUtils

function fixedFestivalsFor(md) {
    var m = {
        "01-01": ["New Year's Day"],
        "01-13": ["Lohri"],
        "01-14": ["Makar Sankranti"],
        "01-26": ["Republic Day \uD83C\uDDEE\uD83C\uDDF3"],
        "02-14": ["Valentine's Day"],
        "03-08": ["Maha Shivratri", "International Women's Day"],
        "03-14": ["Holi \u2022 Festival of Colours"],
        "04-13": ["Baisakhi"],
        "04-14": ["Ambedkar Jayanti"],
        "05-01": ["Labour Day / Maharashtra Day"],
        "06-05": ["World Environment Day"],
        "06-21": ["International Yoga Day"],
        "08-15": ["Independence Day \uD83C\uDDEE\uD83C\uDDF3"],
        "08-27": ["Ganesh Chaturthi"],
        "09-05": ["Teachers' Day"],
        "10-02": ["Gandhi Jayanti"],
        "10-12": ["Dussehra / Vijayadashami"],
        "10-20": ["Diwali \u2022 Festival of Lights"],
        "10-21": ["Govardhan Puja"],
        "10-22": ["Bhai Dooj"],
        "11-14": ["Children's Day"],
        "11-24": ["Guru Nanak Jayanti"],
        "12-25": ["Christmas \u2603"],
        "12-31": ["New Year's Eve"]
    };
    return m[md] || [];
}

function specialFestivalsFor(ymd) {
    var m = {
        "2026-01-01": ["New Year's Day"],
        "2026-03-03": ["Holi"],
        "2026-03-20": ["Eid al-Fitr \u2606"],
        "2026-03-31": ["Ram Navami"],
        "2026-04-05": ["Easter Sunday"],
        "2026-05-27": ["Eid al-Adha"],
        "2026-08-28": ["Raksha Bandhan"],
        "2026-08-29": ["Raksha Bandhan (obs.)"],
        "2026-09-04": ["Janmashtami"],
        "2026-09-14": ["Onam"],
        "2026-10-02": ["Gandhi Jayanti", "Dussehra"],
        "2026-10-20": ["Diwali"],
        "2026-11-08": ["Karva Chauth"],
        "2026-12-25": ["Christmas"]
    };
    return m[ymd] || [];
}

function festivalsForDate(y, m, d) {
    var md = DateUtils.pad2(m + 1) + "-" + DateUtils.pad2(d);
    var ymd = y + "-" + md;
    var fixed = fixedFestivalsFor(md);
    var spec = specialFestivalsFor(ymd);

    var out = [];
    var seen = {};

    for (var i = 0; i < fixed.length; i++) {
        if (!seen[fixed[i]]) {
            seen[fixed[i]] = true;
            out.push(fixed[i]);
        }
    }
    for (var j = 0; j < spec.length; j++) {
        if (!seen[spec[j]]) {
            seen[spec[j]] = true;
            out.push(spec[j]);
        }
    }
    return out;
}

function eventDotColor(idx) {
    var palette = ["#fabd2f", "#fe8019", "#83a598", "#8ec07c", "#d3869b", "#fb4934", "#458588", "#b8bb26"];
    return palette[idx % palette.length];
}

function upcomingEventsFromToday(today, count, daysAhead) {
    var res = [];
    var lim = count || 6;
    var span = daysAhead || 60;
    var cur = new Date(today.getFullYear(), today.getMonth(), today.getDate());

    for (var i = 0; i < span && res.length < lim; i++) {
        var y = cur.getFullYear();
        var m = cur.getMonth();
        var d = cur.getDate();
        var ev = festivalsForDate(y, m, d);
        if (ev.length > 0) {
            res.push({
                key: DateUtils.dateKey(y, m, d),
                date: new Date(y, m, d),
                events: ev
            });
        }
        cur.setDate(cur.getDate() + 1);
    }
    return res;
}
