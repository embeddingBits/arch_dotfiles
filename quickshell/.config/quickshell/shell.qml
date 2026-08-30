import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Widgets

ShellRoot {
    id: root

    property color colBg: "#1d2021"
    property color colFg: "#ebdbb2"
    property color colAccent: "#d79221"
    property color colBorder: "#d79221" 
    property color colBorderMuted: "#504945" 
    property color colHover: "#3c3836"
    property color colMuted: "#928374"
    property int barHeight: 38
    property string fontFamily: "JetBrainsMono Nerd Font"
    property string fontFamilyFallback: "JetBrainsMono Nerd Font"
    property int clockFontSize: 15
    property int iconFontSize: 14
    property int smallFontSize: 12
    property int radius: 0
    property int radiusSmall: 0

    // ── underline colors per bar element (distinct) ──
    property color colUnderlineMenu: "#fabd2f"
    property color colUnderlineWorkspaces: "#fe8019"
    property color colUnderlineClock: "#83a598"
    property color colUnderlineTray: "#a89984"
    property color colUnderlineAudio: "#8ec07c"
    property color colUnderlineNetwork: "#458588"
    property color colUnderlineBluetooth: "#d3869b"
    property color colUnderlineBattery: "#b8bb26"
    property color colUnderlinePower: "#fb4934"

    property bool calendarOpen: false
    property date today: new Date()
    property string todayKey: dateKey(today.getFullYear(), today.getMonth(), today.getDate())
    property int calYear: today.getFullYear()
    property int calMonth: today.getMonth()
    property int weekStart: 1
    property date calViewDate: new Date(calYear, calMonth, 1)
    property var calWeeks: monthGrid(calYear, calMonth, weekStart, todayKey)
    property real yearDone: yearProgress(today.getFullYear(), today.getMonth(), today.getDate())
    property int yearDonePercent: Math.round(yearDone * 100)

    property bool volumePopupOpen: false
    property bool wifiPopupOpen: false
    property bool bluetoothPopupOpen: false
    function closeAllPopups(){
        calendarOpen=false; volumePopupOpen=false; wifiPopupOpen=false; bluetoothPopupOpen=false;
    }
    function toggleVolume(){ let o=!volumePopupOpen; closeAllPopups(); volumePopupOpen=o; }
    function toggleWifi(){ let o=!wifiPopupOpen; closeAllPopups(); wifiPopupOpen=o; }
    function toggleBluetooth(){ let o=!bluetoothPopupOpen; closeAllPopups(); bluetoothPopupOpen=o; }
    function toggleCalendar(){ let o=!calendarOpen; closeAllPopups(); calendarOpen=o; if(o) refreshCalendar(); }

    function pad2(v){ let n=Number(v); return (n<10?"0":"")+n; }
    function dateKey(y,m,d){ return y+"-"+pad2(m+1)+"-"+pad2(d); }
    function dayOfYear(y,m,d){ return Math.round((Date.UTC(y,m,d)-Date.UTC(y,0,1))/86400000)+1; }
    function daysInYear(y){ return dayOfYear(y,11,31); }
    function yearProgress(y,m,d){ let tot=daysInYear(y); return tot<=0?0:Math.max(0,Math.min(1,(dayOfYear(y,m,d)-1)/tot)); }
    function isoWeek(y,m,d){
        let dt=new Date(Date.UTC(y,m,d)); let wd=dt.getUTCDay()||7;
        dt.setUTCDate(dt.getUTCDate()+4-wd);
        let ys=new Date(Date.UTC(dt.getUTCFullYear(),0,1));
        return Math.ceil(((dt.getTime()-ys.getTime())/86400000+1)/7);
    }
    function weekdayOrder(start){ let s=((start%7)+7)%7; let o=[]; for(let i=0;i<7;i++) o.push((s+i)%7); return o; }
    function monthGrid(year, month, weekStart, todayKey){
        let start=((weekStart%7)+7)%7;
        let leading=(new Date(year,month,1).getDay()-start+7)%7;
        let cursor=new Date(year,month,1-leading);
        let tk=String(todayKey||""); let weeks=[];
        for(let w=0;w<6;w++){
            let days=[]; let th=null;
            for(let d=0;d<7;d++){
                let cy=cursor.getFullYear(), cm=cursor.getMonth(), cd=cursor.getDate();
                let wd=cursor.getDay(); let k=dateKey(cy,cm,cd);
                if(wd===4) th={year:cy,month:cm,day:cd};
                days.push({key:k,year:cy,month:cm,day:cd,weekday:wd,inMonth:cm===month&&cy===year, weekend:wd===0||wd===6, today:k===tk});
                cursor.setDate(cursor.getDate()+1);
            }
            let anchor=th||days[0];
            weeks.push({week: isoWeek(anchor.year,anchor.month,anchor.day), days:days});
        }
        return weeks;
    }
    function refreshCalendar(){
        root.today=new Date();
        root.todayKey=dateKey(root.today.getFullYear(), root.today.getMonth(), root.today.getDate());
        root.calYear=root.today.getFullYear(); root.calMonth=root.today.getMonth();
        root.calWeeks=monthGrid(root.calYear, root.calMonth, root.weekStart, root.todayKey);
        root.yearDone=yearProgress(root.today.getFullYear(), root.today.getMonth(), root.today.getDate());
        root.yearDonePercent=Math.round(root.yearDone*100);
    }
    function stepCalMonth(delta){
        let d=new Date(root.calYear, root.calMonth+delta, 1);
        root.calYear=d.getFullYear(); root.calMonth=d.getMonth();
        root.calWeeks=monthGrid(root.calYear, root.calMonth, root.weekStart, root.todayKey);
    }

    // ── Festival / Event data ──
    // Fixed recurring festivals (MM-DD)
    function fixedFestivalsFor(md){
        let m={
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
    function specialFestivalsFor(ymd){
        let m={
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
    function festivalsForDate(y,m,d){
        let md=pad2(m+1)+"-"+pad2(d);
        let ymd=y+"-"+md;
        let fixed=fixedFestivalsFor(md);
        let spec=specialFestivalsFor(ymd);
        // merge unique
        let out=[]; let seen={};
        for(let i=0;i<fixed.length;i++){ if(!seen[fixed[i]]){ seen[fixed[i]]=true; out.push(fixed[i]); } }
        for(let i=0;i<spec.length;i++){ if(!seen[spec[i]]){ seen[spec[i]]=true; out.push(spec[i]); } }
        // also check month-day from special that may overlap already handled, but we also want to avoid duplicate of fixed that already includes; above merges.
        return out;
    }
    function eventDotColor(idx){
        let palette=["#fabd2f","#fe8019","#83a598","#8ec07c","#d3869b","#fb4934","#458588","#b8bb26"];
        return palette[idx % palette.length];
    }
    function upcomingEventsFromToday(count, daysAhead){
        let res=[]; let lim=count||6; let span=daysAhead||60;
        let cur=new Date(root.today.getFullYear(), root.today.getMonth(), root.today.getDate());
        for(let i=0;i<span && res.length<lim;i++){
            let y=cur.getFullYear(), m=cur.getMonth(), d=cur.getDate();
            let ev=festivalsForDate(y,m,d);
            if(ev.length>0){
                res.push({key: dateKey(y,m,d), date: new Date(y,m,d), events: ev});
            }
            cur.setDate(cur.getDate()+1);
        }
        return res;
    }

    property var niriWorkspaces: []
    property var niriRaw: []
    Process {
        id: niriProc
        command: ["niri", "msg", "-j", "workspaces"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let t=String(text||"").trim();
                if(!t) return;
                try{
                    let arr=JSON.parse(t);
                    if(!Array.isArray(arr)) return;
                    root.niriRaw=arr;
                    let map={};
                    for(let i=0;i<arr.length;i++){
                        let w=arr[i]; let idx=Number(w.idx);
                        if(!isFinite(idx)) continue;
                        if(!map[idx]) map[idx]={idx:idx, is_focused:false, is_active:false, occupied:false, output: w.output||""};
                        if(w.is_focused) map[idx].is_focused=true;
                        if(w.is_active) map[idx].is_active=true;
                        if(w.active_window_id!==null && w.active_window_id!==undefined) map[idx].occupied=true;
                    }
                    let out=[];
                    for(let k in map) out.push(map[k]);
                    for(let c=1;c<=5;c++) if(!map[c]) out.push({idx:c, is_focused:false, is_active:false, occupied:false, output:""});
                    out.sort((a,b)=>a.idx-b.idx);
                    root.niriWorkspaces=out;
                }catch(e){ console.warn("niri workspaces parse failed", e); }
            }
        }
    }
    Process {
        id: niriWindowsProc
        command: ["niri", "msg", "-j", "windows"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let t=String(text||"").trim();
                if(!t) return;
                try{
                    let wins=JSON.parse(t);
                    if(!Array.isArray(wins)) return;
                    let occupiedSet={};
                    for(let i=0;i<wins.length;i++) occupiedSet[wins[i].workspace_id]=true;
                    let idToIdx={};
                    for(let i=0;i<root.niriRaw.length;i++) idToIdx[root.niriRaw[i].id]=root.niriRaw[i].idx;
                    let idxOccupied={};
                    for(let id in occupiedSet){ let idx=idToIdx[id]; if(idx!==undefined) idxOccupied[idx]=true; }
                    let cur=root.niriWorkspaces.slice();
                    for(let j=0;j<cur.length;j++) if(idxOccupied[cur[j].idx]) cur[j].occupied=true;
                    root.niriWorkspaces=cur;
                }catch(e){}
            }
        }
    }
    Timer { id: niriPollTimer; interval: 700; running: true; repeat: true; onTriggered: { if(!niriProc.running) niriProc.running=true; if(!niriWindowsProc.running) niriWindowsProc.running=true; } }
    Component.onCompleted: { niriProc.running=true; niriWindowsProc.running=true; }
    Process {
        id: niriEventProc
        command: ["niri", "msg", "event-stream"]
        running: true
        stdout: SplitParser {
            onRead: function(line){
                let s=String(line||"");
                if(s.indexOf("Workspaces changed")!==-1 || s.indexOf("Windows changed")!==-1){
                    if(!niriProc.running) niriProc.running=true;
                    if(!niriWindowsProc.running) niriWindowsProc.running=true;
                }
            }
        }
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource] }

    property var netDevices: Networking.devices ? Networking.devices.values : []
    property var wifiDev: {
        for(let i=0;i<netDevices.length;i++) if(netDevices[i] && netDevices[i].type===DeviceType.Wifi) return netDevices[i];
        return null;
    }
    property var wifiNets: wifiDev && wifiDev.networks ? wifiDev.networks.values : []
    property var btAdapter: Bluetooth.defaultAdapter
    property var btDevices: Bluetooth.devices ? Bluetooth.devices.values : []

    PanelWindow {
        id: bar
        anchors { left: true; right: true; top: true }
        implicitHeight: root.barHeight
        color: root.colBg

        Rectangle {
            anchors.fill: parent
            color: root.colBg
            border.color: "transparent"
            border.width: 0
            // thin bottom separator (no box)
            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; height: 1; color: Qt.rgba(root.colMuted.r, root.colMuted.g, root.colMuted.b, 0.25) }
        }

        Item {
            id: barContent
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            RowLayout {
                id: leftSection
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Item {
                    id: menuBtn
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 26
                    Rectangle {
                        anchors.fill: parent
                        color: menuMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : "transparent"
                        radius: root.radius
                    }
                    Text { anchors.centerIn: parent; text: "󰣇"; font.family: root.fontFamily; font.pixelSize: root.clockFontSize; color: root.colFg }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: 2; radius: 1
                        color: root.colUnderlineMenu
                        opacity: menuMouse.containsMouse ? 1.0 : 0.95
                    }
                    MouseArea { id: menuMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash","-c","rofi -show drun &"]) }
                }

                Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 18; color: Qt.rgba(root.colMuted.r, root.colMuted.g, root.colMuted.b, 0.35); opacity: 0.6 }

                RowLayout {
                    spacing: 6
                    Repeater {
                        id: wsRepeater
                        model: root.niriWorkspaces
                        delegate: Item {
                            id: wsDelegate
                            required property var modelData
                            property bool focused: modelData.is_focused
                            property bool occupied: modelData.occupied
                            Layout.preferredWidth: wsDelegate.focused ? 30 : 26
                            Layout.preferredHeight: 26
                            Rectangle {
                                anchors.fill: parent
                                radius: root.radius
                                color: wsMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08)
                                     : wsDelegate.focused ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.10)
                                     : "transparent"
                                // no border
                            }
                            Text {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -1
                                text: wsDelegate.focused ? "󰝥" : String(wsDelegate.modelData.idx)
                                font.family: root.fontFamily
                                font.pixelSize: root.clockFontSize
                                font.weight: wsDelegate.focused ? 700 : 600
                                color: wsDelegate.focused ? root.colAccent : (wsDelegate.occupied ? root.colFg : Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.55))
                                opacity: wsDelegate.occupied || wsDelegate.focused ? 1 : 0.60
                            }
                            Rectangle {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                height: wsDelegate.focused ? 2.5 : 2
                                radius: 1
                                color: wsDelegate.focused ? root.colUnderlineWorkspaces : (wsDelegate.occupied ? Qt.rgba(root.colUnderlineWorkspaces.r, root.colUnderlineWorkspaces.g, root.colUnderlineWorkspaces.b, 0.85) : Qt.rgba(root.colUnderlineWorkspaces.r, root.colUnderlineWorkspaces.g, root.colUnderlineWorkspaces.b, 0.35))
                                opacity: wsMouse.containsMouse ? 1 : 0.9
                            }
                            MouseArea {
                                id: wsMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Quickshell.execDetached(["niri","msg","action","focus-workspace", String(wsDelegate.modelData.idx)])
                            }
                        }
                    }
                }
            }

            Item {
                id: centerSection
                anchors.centerIn: parent
                width: clock.implicitWidth + 28
                height: parent.height
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    radius: root.radius
                    color: clockMouse.containsMouse || root.calendarOpen ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
                    // no border box
                }
                Text {
                    id: clock
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    color: root.colFg
                    font.family: root.fontFamily
                    font.weight: 700
                    font.pixelSize: root.clockFontSize
                    property date currentTime: new Date()
                    text: Qt.formatDateTime(currentTime, "dddd hh:mm:ss AP")
                    Timer { interval: 1000; running: true; repeat: true; onTriggered: clock.currentTime = new Date() }
                }
                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                    anchors.bottomMargin: 4
                    height: 2; radius: 1
                    color: root.colUnderlineClock
                    opacity: clockMouse.containsMouse || root.calendarOpen ? 1 : 0.92
                }
                MouseArea {
                    id: clockMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleCalendar()
                }
            }

            RowLayout {
                id: rightSection
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                RowLayout {
                    visible: SystemTray.items.values.length > 0
                    spacing: 2
                    Repeater {
                        model: SystemTray.items
                        delegate: Item {
                            required property var modelData
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 26
                            Rectangle {
                                anchors.fill: parent
                                radius: root.radius
                                color: trayMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
                            }
                            IconImage { anchors.centerIn: parent; anchors.verticalCenterOffset: -1; width: 16; height: 16; source: modelData.icon; asynchronous: true }
                            Rectangle {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                height: 2; radius: 1
                                color: root.colUnderlineTray
                                opacity: trayMouse.containsMouse ? 1 : 0.85
                            }
                            MouseArea {
                                id: trayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onClicked: function(mouse){
                                    if(mouse.button===Qt.LeftButton) modelData.activate();
                                    else if(mouse.button===Qt.RightButton && modelData.hasMenu) modelData.display(Qt.point(width/2,height));
                                }
                            }
                        }
                    }
                    Rectangle { Layout.preferredWidth: 1; Layout.preferredHeight: 16; color: Qt.rgba(root.colMuted.r, root.colMuted.g, root.colMuted.b, 0.35); visible: SystemTray.items.values.length>0 }
                }

                Item {
                    id: audioBtn
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 26
                    property real vol: Pipewire.defaultAudioSink?.audio?.volume ?? 0
                    property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
                    Rectangle {
                        anchors.fill: parent
                        radius: root.radius
                        color: audioMouse.containsMouse || root.volumePopupOpen ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
                    }
                    RowLayout {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        spacing: 4
                        Text {
                            text: {
                                if (!Pipewire.defaultAudioSink?.audio) return "󰖁";
                                if (audioBtn.muted || audioBtn.vol===0) return "󰝟";
                                if (audioBtn.vol < 0.33) return "󰕿";
                                if (audioBtn.vol < 0.66) return "󰖀";
                                return "󰕾";
                            }
                            font.family: root.fontFamily
                            font.pixelSize: root.clockFontSize
                            color: root.colFg
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: Math.round(audioBtn.vol*100) + "%"
                            font.family: root.fontFamily
                            font.pixelSize: root.clockFontSize
                            font.weight: 600
                            color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.90)
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: 2; radius: 1
                        color: root.colUnderlineAudio
                        opacity: audioMouse.containsMouse || root.volumePopupOpen ? 1 : 0.92
                    }
                    MouseArea {
                        id: audioMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleVolume()
                        onWheel: function(wheel){
                            if(!Pipewire.defaultAudioSink?.audio) return;
                            let s=0.05; let v=Pipewire.defaultAudioSink.audio.volume + (wheel.angleDelta.y>0?s:-s);
                            Pipewire.defaultAudioSink.audio.volume=Math.max(0,Math.min(1,v));
                            if(Pipewire.defaultAudioSink.audio.muted && v>0) Pipewire.defaultAudioSink.audio.muted=false;
                        }
                    }
                }

                Item {
                    id: networkBtn
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 26
                    Rectangle {
                        anchors.fill: parent
                        radius: root.radius
                        color: netMouse.containsMouse || root.wifiPopupOpen ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        text: {
                            let d=root.wifiDev;
                            if(!d) return "󰤯";
                            if(!Networking.wifiEnabled) return "󰤮";
                            for(let i=0;i<root.wifiNets.length;i++) if(root.wifiNets[i] && root.wifiNets[i].connected) {
                                let s=root.wifiNets[i].signalStrength||0;
                                if(s>0.66) return "󰤨";
                                if(s>0.33) return "󰤥";
                                return "󰤢";
                            }
                            return "󰤯";
                        }
                        font.family: root.fontFamily
                        font.pixelSize: root.clockFontSize
                        color: root.colFg
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: 2; radius: 1
                        color: root.colUnderlineNetwork
                        opacity: netMouse.containsMouse || root.wifiPopupOpen ? 1 : 0.92
                    }
                    MouseArea { id: netMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleWifi() }
                }

                Item {
                    id: bluetoothBtn
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 26
                    Rectangle {
                        anchors.fill: parent
                        radius: root.radius
                        color: btMouse.containsMouse || root.bluetoothPopupOpen ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
                    }
                    Text {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        text: {
                            let a=root.btAdapter;
                            if(!a) return "󰂯";
                            if(!a.enabled) return "󰂲";
                            for(let i=0;i<root.btDevices.length;i++) if(root.btDevices[i] && root.btDevices[i].connected) return "󰂱";
                            return "󰂯";
                        }
                        font.family: root.fontFamily
                        font.pixelSize: root.clockFontSize
                        color: root.colFg
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: 2; radius: 1
                        color: root.colUnderlineBluetooth
                        opacity: btMouse.containsMouse || root.bluetoothPopupOpen ? 1 : 0.92
                    }
                    MouseArea { id: btMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.toggleBluetooth() }
                }

                Item {
                    id: battBtn
                    visible: UPower.displayDevice && UPower.displayDevice.isPresent && UPower.displayDevice.isLaptopBattery
                    Layout.preferredWidth: 58
                    Layout.preferredHeight: 26
                    property real pct: (UPower.displayDevice?.percentage ?? 0)
                    property int devState: (UPower.displayDevice?.state ?? 0)
                    Rectangle {
                        anchors.fill: parent
                        radius: root.radius
                        color: battMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
                    }
                    RowLayout {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        spacing: 4
                        Text {
                            text: {
                                let p=battBtn.pct*100; let ch=battBtn.devState===1;
                                if(ch) return "󰂄";
                                if(p>90) return "󰁹";
                                if(p>70) return "󰂀";
                                if(p>50) return "󰁿";
                                if(p>30) return "󰁾";
                                if(p>15) return "󰁼";
                                return "󰁺";
                            }
                            font.family: root.fontFamily
                            font.pixelSize: root.clockFontSize
                            color: battBtn.pct<0.2 && battBtn.devState!==1 ? "#cc241d" : root.colFg
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text { text: Math.round(battBtn.pct*100)+"%"; font.family: root.fontFamily; font.pixelSize: root.clockFontSize; font.weight: 600; color: root.colFg; Layout.alignment: Qt.AlignVCenter }
                    }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: 2; radius: 1
                        color: root.colUnderlineBattery
                        opacity: battMouse.containsMouse ? 1 : 0.92
                    }
                    MouseArea { id: battMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor }
                }

                Item {
                    id: powerBtn
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 26
                    Rectangle {
                        anchors.fill: parent
                        radius: root.radius
                        color: powerMouse.containsMouse ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.12) : "transparent"
                    }
                    Text { anchors.centerIn: parent; anchors.verticalCenterOffset: -1; text: "󰐥"; font.family: root.fontFamily; font.pixelSize: root.clockFontSize; color: powerMouse.containsMouse? root.colAccent : root.colFg }
                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                        height: 2; radius: 1
                        color: root.colUnderlinePower
                        opacity: powerMouse.containsMouse ? 1 : 0.92
                    }
                    MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash","-c","wlogout &"]) }
                }
            }
        }
    }

    PopupWindow {
        id: calPopup
        visible: root.calendarOpen
        color: "transparent"
        anchor.window: bar
        anchor.rect.x: Math.round(bar.width/2 - implicitWidth/2)
        anchor.rect.y: bar.height + 6
        anchor.rect.width: 1
        anchor.rect.height: 1
        implicitWidth: 380
        implicitHeight: calColumn.implicitHeight + 28
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.colBg
            border.color: root.colBorder
            border.width: 1
            Column {
                id: calColumn
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Item {
                    width: parent.width; height: 42
                    Row { anchors.centerIn: parent; spacing: 12
                        Text { text: "󰃭"; font.family: root.fontFamily; font.pixelSize: 28; color: root.colFg; anchors.baseline: heroDate.baseline }
                        Text { id: heroDate; text: Qt.formatDate(root.today, "MMMM d"); font.family: root.fontFamily; font.pixelSize: 26; font.weight: 700; color: root.colFg }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.refreshCalendar() }
                }
                Column {
                    width: parent.width; spacing: 4
                    RowLayout {
                        width: parent.width; spacing: 8
                        Text { text: String(root.today.getFullYear()); font.family: root.fontFamily; font.pixelSize: 11; color: Qt.darker(root.colFg,1.4); font.letterSpacing: 1 }
                        Item { Layout.fillWidth: true; Layout.preferredHeight: 1 }
                        Text { id: yearPct; text: root.yearDonePercent + "%"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg }
                    }
                    Rectangle {
                        width: parent.width; height: 6; radius: root.radius; color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.12)
                        Rectangle { width: parent.width * root.yearDone; height: parent.height; radius: root.radius; color: root.colAccent; Behavior on width { NumberAnimation{ duration:160; easing.type: Easing.OutCubic } } }
                    }
                }
                Item {
                    width: parent.width; height: 30
                    Text { anchors.centerIn: parent; width: 140; horizontalAlignment: Text.AlignHCenter; text: Qt.formatDate(root.calViewDate, "MMMM yyyy").toUpperCase(); font.family: root.fontFamily; font.pixelSize: 12; font.letterSpacing: 1; color: Qt.darker(root.colFg,1.2) }
                    Rectangle {
                        anchors.left: parent.left; width: 28; height: 28; radius: root.radius
                        color: prevMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : "transparent"
                        border.color: prevMouse.containsMouse ? root.colBorder : "transparent"; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰅁"; font.family: root.fontFamily; font.pixelSize: 14; color: root.colFg }
                        MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.stepCalMonth(-1) }
                    }
                    Rectangle {
                        anchors.right: parent.right; width: 28; height: 28; radius: root.radius
                        color: nextMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : "transparent"
                        border.color: nextMouse.containsMouse ? root.colBorder : "transparent"; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰅂"; font.family: root.fontFamily; font.pixelSize: 14; color: root.colFg }
                        MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.stepCalMonth(1) }
                    }
                }
                Row {
                    width: parent.width; spacing: 2
                    Item { width: 28; height: 16 }
                    Repeater {
                        model: root.weekdayOrder(root.weekStart)
                        delegate: Text {
                            required property int modelData
                            width: (parent.width - 28 - 6*2)/7; height: 16
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            text: ["SUN","MON","TUE","WED","THU","FRI","SAT"][modelData].substring(0,2)
                            font.family: root.fontFamily; font.pixelSize: 9; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.5)
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 2
                    Repeater {
                        model: root.calWeeks
                        delegate: Row {
                            required property var modelData
                            width: parent.width; spacing: 2
                            Text { width: 28; height: 30; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: String(modelData.week); font.family: root.fontFamily; font.pixelSize: 9; color: Qt.darker(root.colFg,1.8) }
                            Repeater {
                                model: modelData.days
                                delegate: Item {
                                    required property var modelData
                                    width: (parent.parent.width - 28 - 6*2)/7; height: 34
                                    property var dayEvents: root.festivalsForDate(modelData.year, modelData.month, modelData.day)
                                    property bool hasEvents: dayEvents.length > 0
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: root.radius
                                        color: dayMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : (modelData.today ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.14) : "transparent")
                                        border.width: modelData.today ? 1 : 0
                                        border.color: root.colBorder
                                    }
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: String(modelData.day)
                                            font.family: root.fontFamily; font.pixelSize: 12; font.weight: modelData.today ? 700 : 400
                                            color: modelData.inMonth ? (modelData.weekend ? Qt.darker(root.colFg,1.3) : root.colFg) : Qt.darker(root.colFg,2.0)
                                        }
                                        Row {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            spacing: 2
                                            visible: hasEvents
                                            Repeater {
                                                model: dayEvents.slice(0,3)
                                                delegate: Rectangle {
                                                    required property var modelData
                                                    required property int index
                                                    width: 5; height: 5; radius: 2.5
                                                    color: root.eventDotColor(index)
                                                }
                                            }
                                            // if many events show +n
                                            Text {
                                                visible: dayEvents.length > 3
                                                text: "+"+(dayEvents.length-3)
                                                font.family: root.fontFamily; font.pixelSize: 6; color: root.colMuted
                                                anchors.verticalCenter: parent.verticalCenter
                                            }
                                        }
                                    }
                                    // limit dot display to 3
                                    MouseArea {
                                        id: dayMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: hasEvents ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    }
                                    ToolTip {
                                        visible: dayMouse.containsMouse && hasEvents
                                        delay: 300
                                        timeout: 3000
                                        text: dayEvents.join("\n")
                                        contentItem: Text {
                                            text: dayMouse.containsMouse && hasEvents ? dayEvents.join("\n") : ""
                                            font.family: root.fontFamily; font.pixelSize: 10; color: root.colFg
                                            wrapMode: Text.Wrap
                                        }
                                        background: Rectangle {
                                            color: root.colBg
                                            border.color: root.colBorder
                                            border.width: 1
                                            radius: 4
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                // legend
                Row {
                    width: parent.width
                    spacing: 6
                    visible: true
                    Text { text: "\u25CF  festival / event"; font.family: root.fontFamily; font.pixelSize: 9; color: Qt.darker(root.colFg,1.5); anchors.verticalCenter: parent.verticalCenter }
                    Item { width: 6; height: 1 }
                    Rectangle { width: 8; height: 8; radius: 4; color: root.colAccent; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "today"; font.family: root.fontFamily; font.pixelSize: 9; color: Qt.darker(root.colFg,1.5); anchors.verticalCenter: parent.verticalCenter }
                }
                // upcoming events list
                Rectangle { width: parent.width; height: 1; color: Qt.rgba(root.colMuted.r, root.colMuted.g, root.colMuted.b, 0.25) }
                Column {
                    width: parent.width; spacing: 6
                    Text { text: "UPCOMING  \u25B8  NEXT "+upcomingRepeater.count+" EVENTS"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                    Repeater {
                        id: upcomingRepeater
                        model: root.upcomingEventsFromToday(6, 90)
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 30; radius: 6
                            color: upcomingMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.06) : "transparent"
                            border.color: upcomingMouse.containsMouse ? Qt.rgba(root.colMuted.r, root.colMuted.g, root.colMuted.b, 0.25) : "transparent"
                            border.width: 1
                            Row {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                Rectangle {
                                    width: 36; height: 20; radius: 4
                                    color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.14)
                                    Text {
                                        anchors.centerIn: parent
                                        text: Qt.formatDate(modelData.date, "MMM d")
                                        font.family: root.fontFamily; font.pixelSize: 9; font.weight: 600; color: root.colAccent
                                    }
                                }
                                Column {
                                    width: parent.width - 52
                                    spacing: 1
                                    Text {
                                        text: modelData.events.join(" \u2022 ")
                                        font.family: root.fontFamily; font.pixelSize: 11; font.weight: 500; color: root.colFg
                                        elide: Text.ElideRight; width: parent.width
                                    }
                                    Text {
                                        text: {
                                            let d=modelData.date; let now=new Date(root.today.getFullYear(), root.today.getMonth(), root.today.getDate());
                                            let diff=Math.round((d - now)/86400000);
                                            if(diff===0) return "Today";
                                            if(diff===1) return "Tomorrow";
                                            return "In "+diff+" days  \u2022  "+Qt.formatDate(d, "dddd");
                                        }
                                        font.family: root.fontFamily; font.pixelSize: 9; color: Qt.darker(root.colFg,1.5)
                                        elide: Text.ElideRight; width: parent.width
                                    }
                                }
                            }
                            MouseArea {
                                id: upcomingMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.calYear=modelData.date.getFullYear(); root.calMonth=modelData.date.getMonth();
                                    root.calWeeks=root.monthGrid(root.calYear, root.calMonth, root.weekStart, root.todayKey);
                                }
                            }
                        }
                    }
                    Text {
                        visible: upcomingRepeater.count===0
                        text: "No festivals in next 90 days"
                        font.family: root.fontFamily; font.pixelSize: 10; color: Qt.darker(root.colFg,1.5); font.italic: true
                    }
                }
                Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: "Hover dot for details \u2022 Click upcoming to jump"; font.family: root.fontFamily; font.pixelSize: 9; color: Qt.darker(root.colFg,1.6) }
            }
            WheelHandler { onWheel: function(e){ if(e.angleDelta.y!==0) root.stepCalMonth(e.angleDelta.y>0?-1:1); } }
        }
    }

    PopupWindow {
        id: volumePopup
        visible: root.volumePopupOpen
        color: "transparent"
        anchor.window: bar
        anchor.rect.x: bar.width - implicitWidth - 90
        anchor.rect.y: bar.height + 6
        anchor.rect.width: 1
        anchor.rect.height: 1
        implicitWidth: 360
        implicitHeight: volumeCol.implicitHeight + 24
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.colBg
            border.color: root.colBorder
            border.width: 1
            Column {
                id: volumeCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 12
                Row {
                    width: parent.width
                    Text { text: "󰕾  Audio"; font.family: root.fontFamily; font.pixelSize: 14; font.weight: 700; color: root.colFg }
                    Item { width: 12; height: 1 }
                    Text { text: Pipewire.defaultAudioSink?.audio?.muted ? "MUTED" : Math.round((Pipewire.defaultAudioSink?.audio.volume??0)*100)+"%" ; font.family: root.fontFamily; font.pixelSize: 11; color: Qt.darker(root.colFg,1.4); anchors.verticalCenter: parent.verticalCenter }
                    Item { Layout.fillWidth: true; width: 20; height: 1 }
                }
                Column {
                    width: parent.width; spacing: 6
                    RowLayout { width: parent.width
                        Text { text: "OUTPUT"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                        Item { Layout.fillWidth: true; height: 1 }
                        Text { text: Math.round((Pipewire.defaultAudioSink?.audio.volume??0)*100)+"%"; font.family: root.fontFamily; font.pixelSize: 10; color: root.colFg }
                    }
                    Rectangle {
                        width: parent.width; height: 28; radius: root.radius; color: "transparent"; border.color: root.colBorderMuted; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 8
                            Text { text: Pipewire.defaultAudioSink?.audio?.muted ? "󰝟" : "󰕾"; font.family: root.fontFamily; font.pixelSize: 14; color: root.colFg; Layout.alignment: Qt.AlignVCenter }
                            Item {
                                Layout.fillWidth: true; height: 6; Layout.alignment: Qt.AlignVCenter
                                Rectangle { anchors.fill: parent; radius: root.radius; color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.18) }
                                Rectangle {
                                    width: parent.width * (Pipewire.defaultAudioSink?.audio.volume??0); height: parent.height; radius: root.radius; color: root.colAccent
                                }
                                Slider {
                                    id: outSlider
                                    anchors.fill: parent
                                    from: 0; to: 1; stepSize: 0.02
                                    value: Pipewire.defaultAudioSink?.audio.volume ?? 0
                                    onMoved: { if(Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.volume=value; }
                                    background: Item {}
                                    handle: Rectangle { visible: false; width: 1; height: 1 }
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: root.radius; color: volMuteMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : "transparent"; border.color: volMuteMouse.containsMouse ? root.colBorder : "transparent"; border.width: 1
                                Text { anchors.centerIn: parent; text: Pipewire.defaultAudioSink?.audio?.muted ? "󰝟" : "󰝧"; font.family: root.fontFamily; font.pixelSize: 12; color: root.colFg }
                                MouseArea { id: volMuteMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if(Pipewire.defaultAudioSink?.audio) Pipewire.defaultAudioSink.audio.muted=!Pipewire.defaultAudioSink.audio.muted }
                            }
                        }
                    }
                    Column {
                        width: parent.width; spacing: 4
                        Repeater {
                            model: {
                                let ns=Pipewire.nodes ? Pipewire.nodes.values : [];
                                let out=[];
                                for(let i=0;i<ns.length;i++){ let n=ns[i]; if(n && n.isSink && !n.isStream) out.push(n); }
                                return out.slice(0,5);
                            }
                            delegate: Rectangle {
                                required property var modelData
                                width: parent.width; height: 26; radius: root.radius
                                color: sinkMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : (Pipewire.defaultAudioSink && modelData.id===Pipewire.defaultAudioSink.id ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.12) : "transparent")
                                border.color: Pipewire.defaultAudioSink && modelData.id===Pipewire.defaultAudioSink.id ? root.colBorder : (sinkMouse.containsMouse ? root.colBorderMuted : "transparent")
                                border.width: 1
                                Row {
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                    Text { text: "󰓃"; font.family: root.fontFamily; font.pixelSize: 12; color: root.colFg; anchors.verticalCenter: parent.verticalCenter }
                                    Text { text: modelData.description || modelData.name || "Unknown"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg; elide: Text.ElideRight; width: parent.width - 30; anchors.verticalCenter: parent.verticalCenter }
                                }
                                MouseArea { id: sinkMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Pipewire.preferredDefaultAudioSink=modelData }
                            }
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 6
                    RowLayout { width: parent.width
                        Text { text: "INPUT"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                        Item { Layout.fillWidth: true; height: 1 }
                        Text { text: Pipewire.defaultAudioSource?.audio ? Math.round((Pipewire.defaultAudioSource.audio.volume??0)*100)+"%" : "--"; font.family: root.fontFamily; font.pixelSize: 10; color: root.colFg }
                    }
                    Rectangle {
                        visible: !!Pipewire.defaultAudioSource
                        width: parent.width; height: 28; radius: root.radius; color: "transparent"; border.color: root.colBorderMuted; border.width: 1
                        RowLayout {
                            anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 8
                            Text { text: Pipewire.defaultAudioSource?.audio?.muted ? "󰍭" : "󰍬"; font.family: root.fontFamily; font.pixelSize: 14; color: root.colFg }
                            Item {
                                Layout.fillWidth: true; height: 6
                                Rectangle { anchors.fill: parent; radius: root.radius; color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.18) }
                                Rectangle { width: parent.width * (Pipewire.defaultAudioSource?.audio.volume??0); height: parent.height; radius: root.radius; color: root.colAccent }
                                Slider {
                                    anchors.fill: parent
                                    from: 0; to: 1; stepSize: 0.02
                                    value: Pipewire.defaultAudioSource?.audio.volume ?? 0
                                    onMoved: if(Pipewire.defaultAudioSource?.audio) Pipewire.defaultAudioSource.audio.volume=value
                                    background: Item {}
                                    handle: Rectangle { visible: false; width: 1; height: 1 }
                                }
                            }
                            Rectangle {
                                Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: root.radius; color: inMuteMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08) : "transparent"; border.color: inMuteMouse.containsMouse ? root.colBorder : "transparent"; border.width: 1
                                Text { anchors.centerIn: parent; text: Pipewire.defaultAudioSource?.audio?.muted ? "󰍭" : "󰍬"; font.family: root.fontFamily; font.pixelSize: 12; color: root.colFg }
                                MouseArea { id: inMuteMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if(Pipewire.defaultAudioSource?.audio) Pipewire.defaultAudioSource.audio.muted=!Pipewire.defaultAudioSource.audio.muted }
                            }
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 6
                    visible: {
                        let ns=Pipewire.nodes?Pipewire.nodes.values:[]; let c=0;
                        for(let i=0;i<ns.length;i++) if(ns[i] && ns[i].isStream && ns[i].isSink) c++;
                        return c>0;
                    }
                    Text { text: "APPS"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                    Repeater {
                        model: {
                            let ns=Pipewire.nodes?Pipewire.nodes.values:[]; let out=[];
                            for(let i=0;i<ns.length;i++){ let n=ns[i]; if(n && n.isStream && n.isSink) out.push(n); }
                            return out.slice(0,6);
                        }
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 30; radius: root.radius; color: streamMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.06) : "transparent"; border.color: streamMouse.containsMouse ? root.colBorderMuted : "transparent"; border.width: 1
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 6
                                Text { text: modelData.audio?.muted ? "󰝟" : "󰕾"; font.family: root.fontFamily; font.pixelSize: 12; color: root.colFg; Layout.alignment: Qt.AlignVCenter }
                                Text {
                                    Layout.fillWidth: true; elide: Text.ElideRight
                                    text: modelData.description || modelData.name || "Stream"
                                    font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg
                                }
                                Text { text: Math.round((modelData.audio.volume??0)*100)+"%"; font.family: root.fontFamily; font.pixelSize: 10; color: Qt.darker(root.colFg,1.2) }
                                Rectangle {
                                    Layout.preferredWidth: 22; Layout.preferredHeight: 22; radius: root.radius; color: "transparent"; border.color: "transparent"; border.width: 1
                                    Text { anchors.centerIn: parent; text: modelData.audio?.muted ? "󰝟" : "󰝧"; font.family: root.fontFamily; font.pixelSize: 10; color: root.colFg }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(modelData.audio) modelData.audio.muted=!modelData.audio.muted }
                                }
                            }
                            Slider {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.leftMargin: 6; anchors.rightMargin: 6; anchors.bottomMargin: 2
                                height: 4; from: 0; to: 1.2; value: modelData.audio.volume??0
                                onMoved: if(modelData.audio) modelData.audio.volume=value
                                background: Rectangle { radius: root.radius; color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.14); implicitHeight: 4 }
                                handle: Rectangle { visible: false }
                            }
                            MouseArea { id: streamMouse; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                        }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: wifiPopup
        visible: root.wifiPopupOpen
        color: "transparent"
        anchor.window: bar
        anchor.rect.x: bar.width - implicitWidth - 48
        anchor.rect.y: bar.height + 6
        anchor.rect.width: 1
        anchor.rect.height: 1
        implicitWidth: 360
        implicitHeight: wifiCol.implicitHeight + 24
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.colBg
            border.color: root.colBorder
            border.width: 1
            Column {
                id: wifiCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Row {
                    width: parent.width
                    Text { text: "󰖩  Wi-Fi"; font.family: root.fontFamily; font.pixelSize: 14; font.weight: 700; color: root.colFg }
                    Item { width: 8; height: 1 }
                    Text {
                        text: Networking.wifiEnabled ? "ON" : "OFF"
                        font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true
                        color: Networking.wifiEnabled ? root.colAccent : Qt.darker(root.colFg,1.4)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item { Layout.fillWidth: true; width: 20; height: 1 }
                    Rectangle {
                        width: 44; height: 22; radius: root.radius; color: Networking.wifiEnabled ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.18) : Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08)
                        border.color: Networking.wifiEnabled ? root.colBorder : root.colBorderMuted; border.width: 1
                        Rectangle {
                            width: 16; height: 16; radius: root.radius; color: root.colFg
                            x: Networking.wifiEnabled ? parent.width - width - 3 : 3
                            y: 3
                            Behavior on x { NumberAnimation{ duration:140; easing.type: Easing.OutCubic } }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Networking.wifiEnabled=!Networking.wifiEnabled }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: root.colBorderMuted; opacity: 0.5 }
                Column {
                    width: parent.width; spacing: 4
                    visible: {
                        for(let i=0;i<root.wifiNets.length;i++) if(root.wifiNets[i] && root.wifiNets[i].connected) return true;
                        return false;
                    }
                    Text { text: "CONNECTED"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                    Repeater {
                        model: {
                            let out=[];
                            for(let i=0;i<root.wifiNets.length;i++) if(root.wifiNets[i] && root.wifiNets[i].connected) out.push(root.wifiNets[i]);
                            return out.slice(0,1);
                        }
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 32; radius: root.radius; color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.10); border.color: root.colBorder; border.width: 1
                            Row {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                Text { text: "󰤨"; font.family: root.fontFamily; font.pixelSize: 13; color: root.colAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.ssid || modelData.name || "Wi-Fi"; font.family: root.fontFamily; font.pixelSize: 12; font.weight: 600; color: root.colFg; elide: Text.ElideRight; width: parent.width - 80; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: Math.round((modelData.signalStrength||0)*100)+"%"; font.family: root.fontFamily; font.pixelSize: 10; color: Qt.darker(root.colFg,1.2); anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 6
                    Text { text: "AVAILABLE"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                    Repeater {
                        model: {
                            let all=root.wifiNets.slice(0);
                            all.sort((a,b)=> (b.signalStrength||0)-(a.signalStrength||0));
                            return all.slice(0,8);
                        }
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 28; radius: root.radius
                            color: wifiRowMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
                            border.color: modelData.connected ? root.colBorder : (wifiRowMouse.containsMouse ? root.colBorderMuted : "transparent")
                            border.width: 1
                            Row {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                Text {
                                    text: {
                                        let s=modelData.signalStrength||0;
                                        if(s>0.66) return "󰤨";
                                        if(s>0.33) return "󰤥";
                                        return "󰤢";
                                    }
                                    font.family: root.fontFamily; font.pixelSize: 12; color: modelData.connected ? root.colAccent : root.colFg; anchors.verticalCenter: parent.verticalCenter
                                }
                                Text { text: modelData.ssid || modelData.name || "Hidden"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg; elide: Text.ElideRight; width: parent.width - 90; anchors.verticalCenter: parent.verticalCenter; font.weight: modelData.connected?600:400 }
                                Text { text: modelData.security!==0 ? "󰌾" : ""; font.family: root.fontFamily; font.pixelSize: 10; color: Qt.darker(root.colFg,1.4); anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.connected ? "●" : ""; font.family: root.fontFamily; font.pixelSize: 8; color: root.colAccent; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea {
                                id: wifiRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if(modelData.connected) modelData.disconnect();
                                    else {
                                        if(modelData.known) modelData.connect();
                                        else {
                                            if(modelData.security===0) modelData.connect();
                                            else Quickshell.execDetached(["bash","-c","alacritty -e nmtui &"]);
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        visible: root.wifiNets.length===0
                        text: Networking.wifiEnabled ? "Scanning…" : "Wi-Fi disabled"
                        font.family: root.fontFamily; font.pixelSize: 11; color: Qt.darker(root.colFg,1.5); font.italic: true
                    }
                }
                Row {
                    width: parent.width; spacing: 8
                    Rectangle {
                        width: (parent.width-8)/2; height: 26; radius: root.radius; color: footWifiMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"; border.color: footWifiMouse.containsMouse ? root.colBorder : root.colBorderMuted; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰑓 Refresh"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg }
                        MouseArea { id: footWifiMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if(root.wifiDev) root.wifiDev.scannerEnabled=true }
                    }
                    Rectangle {
                        width: (parent.width-8)/2; height: 26; radius: root.radius; color: footWifi2Mouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"; border.color: footWifi2Mouse.containsMouse ? root.colBorder : root.colBorderMuted; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰖩 Settings"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg }
                        MouseArea { id: footWifi2Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash","-c","nm-connection-editor &"]) }
                    }
                }
            }
        }
    }

    PopupWindow {
        id: btPopup
        visible: root.bluetoothPopupOpen
        color: "transparent"
        anchor.window: bar
        anchor.rect.x: bar.width - implicitWidth - 12
        anchor.rect.y: bar.height + 6
        anchor.rect.width: 1
        anchor.rect.height: 1
        implicitWidth: 360
        implicitHeight: btCol.implicitHeight + 24
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.colBg
            border.color: root.colBorder
            border.width: 1
            Column {
                id: btCol
                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 14
                spacing: 10
                Row {
                    width: parent.width
                    Text { text: "󰂯  Bluetooth"; font.family: root.fontFamily; font.pixelSize: 14; font.weight: 700; color: root.colFg }
                    Item { width: 8; height: 1 }
                    Text { text: root.btAdapter && root.btAdapter.enabled ? "ON" : "OFF"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: root.btAdapter && root.btAdapter.enabled ? root.colAccent : Qt.darker(root.colFg,1.4); anchors.verticalCenter: parent.verticalCenter }
                    Item { Layout.fillWidth: true; width: 20; height: 1 }
                    Rectangle {
                        width: 44; height: 22; radius: root.radius; color: root.btAdapter && root.btAdapter.enabled ? Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.18) : Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.08)
                        border.color: root.btAdapter && root.btAdapter.enabled ? root.colBorder : root.colBorderMuted; border.width: 1
                        Rectangle { width: 16; height: 16; radius: root.radius; color: root.colFg; x: root.btAdapter && root.btAdapter.enabled ? parent.width - width - 3 : 3; y: 3; Behavior on x { NumberAnimation{ duration:140; easing.type: Easing.OutCubic } } }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(root.btAdapter) root.btAdapter.enabled=!root.btAdapter.enabled }
                    }
                }
                Rectangle { width: parent.width; height: 1; color: root.colBorderMuted; opacity: 0.5 }
                Column {
                    width: parent.width; spacing: 4
                    visible: {
                        for(let i=0;i<root.btDevices.length;i++) if(root.btDevices[i] && root.btDevices[i].connected) return true;
                        return false;
                    }
                    Text { text: "CONNECTED"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                    Repeater {
                        model: {
                            let out=[];
                            for(let i=0;i<root.btDevices.length;i++) if(root.btDevices[i] && root.btDevices[i].connected) out.push(root.btDevices[i]);
                            return out.slice(0,4);
                        }
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 32; radius: root.radius; color: Qt.rgba(root.colAccent.r, root.colAccent.g, root.colAccent.b, 0.10); border.color: root.colBorder; border.width: 1
                            Row {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                Text { text: "󰂱"; font.family: root.fontFamily; font.pixelSize: 13; color: root.colAccent; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.name || modelData.deviceName || modelData.address || "Device"; font.family: root.fontFamily; font.pixelSize: 12; font.weight: 600; color: root.colFg; elide: Text.ElideRight; width: parent.width - 80; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.batteryAvailable ? Math.round(modelData.battery*100)+"%" : ""; font.family: root.fontFamily; font.pixelSize: 10; color: Qt.darker(root.colFg,1.2); anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if(modelData.disconnect) modelData.disconnect(); else if(modelData.connected) Quickshell.execDetached(["bluetoothctl","disconnect", modelData.address]) }
                        }
                    }
                }
                Column {
                    width: parent.width; spacing: 6
                    Text { text: "DEVICES"; font.family: root.fontFamily; font.pixelSize: 10; font.letterSpacing: 1; font.bold: true; color: Qt.darker(root.colFg,1.3) }
                    Repeater {
                        model: root.btDevices.slice(0,8)
                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width; height: 28; radius: root.radius
                            color: btRowMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"
                            border.color: modelData.connected ? root.colBorder : (btRowMouse.containsMouse ? root.colBorderMuted : "transparent")
                            border.width: 1
                            Row {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 8
                                Text { text: modelData.connected ? "󰂱" : (modelData.paired ? "󰂯" : "󰂲"); font.family: root.fontFamily; font.pixelSize: 12; color: modelData.connected ? root.colAccent : root.colFg; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.name || modelData.deviceName || modelData.address || "Unknown"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg; elide: Text.ElideRight; width: parent.width - 70; anchors.verticalCenter: parent.verticalCenter; font.weight: modelData.connected?600:400 }
                                Text { text: modelData.connected ? "●" : ""; font.family: root.fontFamily; font.pixelSize: 8; color: root.colAccent; anchors.verticalCenter: parent.verticalCenter }
                            }
                            MouseArea {
                                id: btRowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if(modelData.connected){
                                        if(modelData.disconnect) modelData.disconnect();
                                        else Quickshell.execDetached(["bluetoothctl","disconnect", modelData.address]);
                                    } else {
                                        if(modelData.paired) {
                                            if(modelData.connect) modelData.connect();
                                            else Quickshell.execDetached(["bluetoothctl","connect", modelData.address]);
                                        } else {
                                            Quickshell.execDetached(["bluetoothctl","pair", modelData.address]);
                                            if(modelData.connect) Qt.callLater(function(){ modelData.connect(); });
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Text {
                        visible: root.btDevices.length===0
                        text: !root.btAdapter ? "No adapter" : (!root.btAdapter.enabled ? "Bluetooth off" : "Scanning…")
                        font.family: root.fontFamily; font.pixelSize: 11; color: Qt.darker(root.colFg,1.5); font.italic: true
                    }
                }
                Row {
                    width: parent.width; spacing: 8
                    Rectangle {
                        width: (parent.width-8)/2; height: 26; radius: root.radius; color: footBtMouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"; border.color: footBtMouse.containsMouse ? root.colBorder : root.colBorderMuted; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰂯 Scan"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg }
                        MouseArea { id: footBtMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if(root.btAdapter) root.btAdapter.discovering=!root.btAdapter.discovering }
                    }
                    Rectangle {
                        width: (parent.width-8)/2; height: 26; radius: root.radius; color: footBt2Mouse.containsMouse ? Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.07) : "transparent"; border.color: footBt2Mouse.containsMouse ? root.colBorder : root.colBorderMuted; border.width: 1
                        Text { anchors.centerIn: parent; text: "󰂯 Settings"; font.family: root.fontFamily; font.pixelSize: 11; color: root.colFg }
                        MouseArea { id: footBt2Mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Quickshell.execDetached(["bash","-c","blueman-manager &"]) }
                    }
                }
            }
        }
    }

    PanelWindow {
        visible: root.calendarOpen || root.volumePopupOpen || root.wifiPopupOpen || root.bluetoothPopupOpen
        anchors.top: true; anchors.bottom: true; anchors.left: true; anchors.right: true
        color: "transparent"
        exclusiveZone: 0
        MouseArea { anchors.fill: parent; onClicked: root.closeAllPopups() }
    }

    Scope {
        id: volumeOsd
        PwObjectTracker { objects: [ Pipewire.defaultAudioSink ] }
        Connections {
            target: Pipewire.defaultAudioSink?.audio
            function onVolumeChanged() { volumeOsd.shouldShowOsd = true; hideTimer.restart(); }
        }
        property bool shouldShowOsd: false
        Timer { id: hideTimer; interval: 1000; onTriggered: volumeOsd.shouldShowOsd=false }
        LazyLoader {
            active: volumeOsd.shouldShowOsd
            PanelWindow {
                anchors.bottom: true
                margins.bottom: screen.height / 5
                exclusiveZone: 0
                implicitWidth: 400
                implicitHeight: 50
                color: root.colBg
                mask: Region {}
                Rectangle {
                    anchors.fill: parent
                    border.color: root.colBorder
                    border.width: 1
                    radius: root.radius
                    color: root.colBg
                    RowLayout {
                        anchors { fill: parent; leftMargin: 10; rightMargin: 15 }
                        Text {
                            Layout.preferredWidth: 30; Layout.preferredHeight: 30
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            font.family: root.fontFamily; font.pixelSize: 18; color: root.colFg
                            text: {
                                const s=Pipewire.defaultAudioSink;
                                if(!s?.audio) return "\uf026";
                                if(s.audio.muted||s.audio.volume===0) return "\uf026";
                                if(s.audio.volume<0.5) return "\uf027";
                                return "\uf028";
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: 6; radius: root.radius; color: Qt.rgba(root.colFg.r, root.colFg.g, root.colFg.b, 0.18)
                            Rectangle { anchors { left: parent.left; top: parent.top; bottom: parent.bottom } radius: root.radius; implicitWidth: parent.width*(Pipewire.defaultAudioSink?.audio.volume??0); color: root.colAccent; Behavior on implicitWidth{ NumberAnimation{duration:120; easing.type:Easing.OutCubic} } }
                        }
                        Text { text: Math.round((Pipewire.defaultAudioSink?.audio.volume??0)*100)+"%"; font.family: root.fontFamily; font.pixelSize: 12; font.weight:600; color: root.colFg }
                    }
                }
            }
        }
    }
}
