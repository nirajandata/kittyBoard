import QtQuick
import QtQuick.Window
import QtQuick.Controls

Window {
    width: 900
    height: 500
    visible: true
    title: "Kittyboard"

    property var t: ({})

    Connections {
        target: ThemeManager
        function onThemeChanged() {
            t = ThemeManager.theme
        }
    }

    Component.onCompleted: {
        if (ThemeManager.theme && Object.keys(ThemeManager.theme).length > 0) {
            t = ThemeManager.theme
        }
    }

    Rectangle {
        anchors.fill: parent
        color: t.visual?.background ?? "#121212"
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Text input area (display only, no focus)
        Rectangle {
            width: parent.width
            height: 80
            color: t.visual?.keyColor ?? "#2b2b2b"
            radius: t.visual?.radius ?? 18
            border.color: t.visual?.borderColor ?? "#33ffffff"
            border.width: 2

            Text {
                id: displayText
                anchors.fill: parent
                anchors.margins: 15
                verticalAlignment: Text.AlignVCenter
                color: t.visual?.textColor ?? "#ffffff"
                font.pixelSize: 24
                font.bold: false
                text: "Type on your keyboard or click buttons"
                opacity: 0.6
            }
        }

        // Keyboard
        Column {
            id: keyboard
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: t.layout?.rowSpacing ?? 12

            Row {
                spacing: t.layout?.keySpacing ?? 8

                Repeater {
                    model: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]

                    KeyButton {
                        label: modelData

                        onKeyPressed: function (key) {
                            KeyboardSimulator.sendKey(key)
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: t.layout?.keySpacing ?? 8

                Repeater {
                    model: ["A", "S", "D", "F", "G", "H", "J", "K", "L"]

                    KeyButton {
                        label: modelData

                        onKeyPressed: function (key) {
                            KeyboardSimulator.sendKey(key)
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: t.layout?.keySpacing ?? 8

                Repeater {
                    model: ["Z", "X", "C", "V", "B", "N", "M"]

                    KeyButton {
                        label: modelData

                        onKeyPressed: function (key) {
                            KeyboardSimulator.sendKey(key)
                        }
                    }
                }
            }

            // Spacebar and backspace
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: t.layout?.keySpacing ?? 8

                KeyButton {
                    label: "Space"
                    width: 300
                    height: t.layout?.keyHeight ?? 72

                    onKeyPressed: {
                        KeyboardSimulator.sendSpace()
                    }
                }

                KeyButton {
                    label: "←"
                    width: t.layout?.keyWidth ?? 72
                    height: t.layout?.keyHeight ?? 72

                    onKeyPressed: {
                        KeyboardSimulator.sendBackspace()
                    }
                }

                KeyButton {
                    label: "Enter"
                    width: 150
                    height: t.layout?.keyHeight ?? 72

                    onKeyPressed: {
                        KeyboardSimulator.sendEnter()
                    }
                }
            }
        }
    }
}
