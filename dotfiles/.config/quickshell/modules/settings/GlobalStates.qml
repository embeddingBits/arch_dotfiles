import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
pragma Singleton
pragma ComponentBehavior: Bound

Singleton{
    id: root
    property bool appLauncherOpen: false
    property bool settingsOpen: false
    property int  settingsPage: 9
    property bool widgetEditMode: false
    // True only while a desktop widget's text field holds focus. Drives the
    // widget layer's keyboard mode so it never holds the keyboard at rest.
    property bool widgetTextFocus: false
    property bool osdOpen: false
    property bool toolsWidgetOpen: false
    property bool shutdownWindow: false
    property bool fileDialogOpen: false
    property bool areaSelectOpen: false
    property bool liveTextOpen: false
    property bool overviewOpen: false
    property bool welcomeOpen: false
    property string areaSelectMode: ""   // "screenshot" or "recording"
}
