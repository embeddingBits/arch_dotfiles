import QtQuick

import "../utils/DateUtils.js" as DateUtils
import "../utils/FestivalUtils.js" as FestivalUtils

Item {
    id: root

    // ── Public state ──
    property date today: new Date()
    property string todayKey: DateUtils.dateKey(today.getFullYear(), today.getMonth(), today.getDate())
    property int calYear: today.getFullYear()
    property int calMonth: today.getMonth()
    property int weekStart: 1 // Monday
    property date calViewDate: new Date(calYear, calMonth, 1)
    property var calWeeks: DateUtils.monthGrid(calYear, calMonth, weekStart, todayKey)
    property real yearDone: DateUtils.yearProgress(today.getFullYear(), today.getMonth(), today.getDate())
    property int yearDonePercent: Math.round(yearDone * 100)

    // ── Public API ──
    function refreshCalendar() {
        root.today = new Date();
        root.todayKey = DateUtils.dateKey(root.today.getFullYear(), root.today.getMonth(), root.today.getDate());
        root.calYear = root.today.getFullYear();
        root.calMonth = root.today.getMonth();
        root.calWeeks = DateUtils.monthGrid(root.calYear, root.calMonth, root.weekStart, root.todayKey);
        root.yearDone = DateUtils.yearProgress(root.today.getFullYear(), root.today.getMonth(), root.today.getDate());
        root.yearDonePercent = Math.round(root.yearDone * 100);
    }

    function stepCalMonth(delta) {
        let d = new Date(root.calYear, root.calMonth + delta, 1);
        root.calYear = d.getFullYear();
        root.calMonth = d.getMonth();
        root.calWeeks = DateUtils.monthGrid(root.calYear, root.calMonth, root.weekStart, root.todayKey);
    }

    function festivalsForDate(y, m, d) {
        return FestivalUtils.festivalsForDate(y, m, d);
    }

    function eventDotColor(idx) {
        return FestivalUtils.eventDotColor(idx);
    }

    function weekdayOrder(start) {
        return DateUtils.weekdayOrder(start);
    }

    function pad2(v) {
        return DateUtils.pad2(v);
    }

    function dateKey(y, m, d) {
        return DateUtils.dateKey(y, m, d);
    }
}
