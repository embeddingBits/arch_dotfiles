import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.LocalStorage 2.15

ApplicationWindow {
    id: window
    visible: true
    width: 900
    height: 700
    title: "Calendar with Tasks"
    color: "#2E3440" // Nord Polar Night background

    property int currentMonth: (new Date()).getMonth()
    property int currentYear: (new Date()).getFullYear()
    property var tasks: []
    property string selectedDate: "" // Store selected date

    // Database initialization and task management
    Component.onCompleted: {
        var db = LocalStorage.openDatabaseSync("TaskCalendar", "1.0", "Task Calendar Database", 1000000)
        db.transaction(function(tx) {
            tx.executeSql('CREATE TABLE IF NOT EXISTS Tasks(date TEXT, title TEXT, color TEXT)')
            var rs = tx.executeSql('SELECT * FROM Tasks')
            var tempTasks = []
            for(var i = 0; i < rs.rows.length; i++) {
                tempTasks.push({
                    date: rs.rows.item(i).date,
                    title: rs.rows.item(i).title,
                    color: rs.rows.item(i).color
                })
            }
            tasks = tempTasks
        })
    }

    function addTask(date, title, color) {
        var db = LocalStorage.openDatabaseSync("TaskCalendar", "1.0", "Task Calendar Database", 1000000)
        db.transaction(function(tx) {
            tx.executeSql('INSERT INTO Tasks VALUES(?, ?, ?)', [date, title, color])
        })
        tasks = tasks.concat([{date: date, title: title, color: color}])
    }

    function removeTask(index) {
        var task = tasks[index]
        var db = LocalStorage.openDatabaseSync("TaskCalendar", "1.0", "Task Calendar Database", 1000000)
        db.transaction(function(tx) {
            tx.executeSql('DELETE FROM Tasks WHERE date = ? AND title = ?', [task.date, task.title])
        })
        tasks = tasks.filter((_, i) => i !== index)
    }

    function daysInMonth(month, year) {
        return new Date(year, month + 1, 0).getDate()
    }

    function firstDayOfMonth(month, year) {
        return new Date(year, month, 1).getDay()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        // Header with month navigation and add task button
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20

            Button {
                text: "<"
                Layout.preferredWidth: 40
                background: Rectangle { color: "#3B4252"; radius: 4 } // Nord Polar Night
                contentItem: Text { text: "<"; color: "#D8DEE9"; horizontalAlignment: Text.AlignHCenter } // Nord Snow Storm
                onClicked: {
                    if (currentMonth === 0) {
                        currentMonth = 11
                        currentYear -= 1
                    } else {
                        currentMonth -= 1
                    }
                    selectedDate = "" // Reset selected date on month change
                }
            }

            Label {
                text: Qt.formatDate(new Date(currentYear, currentMonth, 1), "MMMM yyyy")
                font.pixelSize: 20
                font.bold: true
                color: "#ECEFF4" // Nord Snow Storm
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true
            }

            Button {
                text: ">"
                Layout.preferredWidth: 40
                background: Rectangle { color: "#3B4252"; radius: 4 } // Nord Polar Night
                contentItem: Text { text: ">"; color: "#D8DEE9"; horizontalAlignment: Text.AlignHCenter } // Nord Snow Storm
                onClicked: {
                    if (currentMonth === 11) {
                        currentMonth = 0
                        currentYear += 1
                    } else {
                        currentMonth += 1
                    }
                    selectedDate = "" // Reset selected date on month change
                }
            }

            Button {
                text: "Add Task"
                background: Rectangle { color: "#5E81AC"; radius: 4 } // Nord Frost
                contentItem: Text { text: "Add Task"; color: "#ECEFF4"; horizontalAlignment: Text.AlignHCenter } // Nord Snow Storm
                onClicked: addTaskDialog.open()
            }
        }

        // Calendar grid
        GridLayout {
            id: calendarGrid
            columns: 7
            Layout.fillWidth: true
            Layout.fillHeight: true
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
                delegate: Label {
                    text: modelData
                    font.pixelSize: 14
                    font.bold: true
                    color: "#D8DEE9" // Nord Snow Storm
                    horizontalAlignment: Text.AlignHCenter
                    Layout.alignment: Qt.AlignHCenter
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                }
            }

            Repeater {
                model: firstDayOfMonth(currentMonth, currentYear)
                delegate: Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                }
            }

            Repeater {
                model: daysInMonth(currentMonth, currentYear)
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    radius: 6
                    border.color: "#434C5E" // Nord Polar Night
                    color: {
                        let dayStr = currentYear + "-" +
                                     ("0" + (currentMonth + 1)).slice(-2) + "-" +
                                     ("0" + (index + 1)).slice(-2)
                        let task = tasks.find(t => t.date === dayStr)
                        return task ? task.color : "#3B4252" // Nord Polar Night
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            selectedDate = currentYear + "-" +
                                          ("0" + (currentMonth + 1)).slice(-2) + "-" +
                                          ("0" + (index + 1)).slice(-2)
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4

                        Text {
                            text: index + 1
                            font.pixelSize: 16
                            font.bold: true
                            color: "#ECEFF4" // Nord Snow Storm
                            Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                        }

                        Repeater {
                            model: {
                                let dayStr = currentYear + "-" +
                                             ("0" + (currentMonth + 1)).slice(-2) + "-" +
                                             ("0" + (index + 1)).slice(-2)
                                return tasks.filter(t => t.date === dayStr)
                            }
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Qt.lighter(modelData.color, 1.2)
                                radius: 4
                                border.color: Qt.darker(modelData.color, 1.2)

                                Text {
                                    text: modelData.title
                                    font.pixelSize: 12
                                    color: "#2E3440" // Nord Polar Night (black)
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }
        }

        // Task list section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            color: "#3B4252" // Nord Polar Night
            radius: 8
            border.color: "#434C5E" // Nord Polar Night

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Label {
                    text: "Tasks"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#ECEFF4" // Nord Snow Storm
                }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: tasks
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 48
                        color: modelData.color
                        radius: 6
                        border.color: Qt.darker(modelData.color, 1.2)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8

                            Text {
                                text: modelData.title + " (" + modelData.date + ")"
                                font.pixelSize: 14
                                color: "#2E3440" // Nord Polar Night (black)
                                Layout.fillWidth: true
                                wrapMode: Text.WordWrap
                                maximumLineCount: 1
                                elide: Text.ElideRight
                            }

                            Button {
                                text: "X"
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                background: Rectangle { color: "#BF616A"; radius: 4 } // Nord Aurora
                                contentItem: Text { text: "X"; color: "#ECEFF4"; horizontalAlignment: Text.AlignHCenter } // Nord Snow Storm
                                onClicked: removeTask(index)
                            }
                        }
                    }
                }
            }
        }
    }

    // Add Task Dialog
    Dialog {
        id: addTaskDialog
        title: "Add New Task"
        modal: true
        anchors.centerIn: parent
        width: 300
        background: Rectangle { color: "#3B4252"; radius: 8 } // Nord Polar Night

        onOpened: {
            if (selectedDate) {
                taskDateField.text = selectedDate
            } else {
                taskDateField.text = ""
            }
        }

        ColumnLayout {
            width: parent.width
            spacing: 10

            TextField {
                id: taskTitleField
                placeholderText: "Task title"
                Layout.fillWidth: true
                color: "#ECEFF4" // Nord Snow Storm
                placeholderTextColor: "#81A1C1" // Nord Frost
                background: Rectangle { color: "#4C566A"; radius: 4 } // Nord Polar Night
            }

            TextField {
                id: taskDateField
                placeholderText: "YYYY-MM-DD"
                Layout.fillWidth: true
                color: "#ECEFF4" // Nord Snow Storm
                placeholderTextColor: "#81A1C1" // Nord Frost
                background: Rectangle { color: "#4C566A"; radius: 4 } // Nord Polar Night
                validator: RegularExpressionValidator { regularExpression: /^\d{4}-\d{2}-\d{2}$/ }
            }

            ComboBox {
                id: taskColorCombo
                Layout.fillWidth: true
                model: ["#BF616A", "#D08770", "#EBCB8B", "#A3BE8C"] // Nord Aurora colors
                delegate: ItemDelegate {
                    width: parent.width
                    contentItem: Rectangle {
                        width: parent.width
                        height: 30
                        color: modelData
                        Text { text: modelData; color: "#ECEFF4"; anchors.centerIn: parent } // Nord Snow Storm
                    }
                }
                background: Rectangle { color: "#4C566A"; radius: 4 } // Nord Polar Night
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    text: "Cancel"
                    Layout.fillWidth: true
                    background: Rectangle { color: "#4C566A"; radius: 4 } // Nord Polar Night
                    contentItem: Text { text: "Cancel"; color: "#D8DEE9"; horizontalAlignment: Text.AlignHCenter } // Nord Snow Storm
                    onClicked: addTaskDialog.close()
                }

                Button {
                    text: "Add"
                    Layout.fillWidth: true
                    background: Rectangle { color: "#5E81AC"; radius: 4 } // Nord Frost
                    contentItem: Text { text: "Add"; color: "#ECEFF4"; horizontalAlignment: Text.AlignHCenter } // Nord Snow Storm
                    onClicked: {
                        if (taskTitleField.text && taskDateField.acceptableInput) {
                            addTask(taskDateField.text, taskTitleField.text, taskColorCombo.currentValue)
                            addTaskDialog.close()
                            taskTitleField.text = ""
                            taskDateField.text = ""
                            selectedDate = "" // Reset after adding
                        }
                    }
                }
            }
        }
    }
}
