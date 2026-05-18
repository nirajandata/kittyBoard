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
        textInput.focus = true
    }

    Rectangle {
        anchors.fill: parent
        color: t.visual?.background ?? "#121212"
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Text input area
        Rectangle {
            width: parent.width
            height: 80
            color: t.visual?.keyColor ?? "#2b2b2b"
            radius: t.visual?.radius ?? 18
            border.color: t.visual?.borderColor ?? "#33ffffff"
            border.width: 2

            TextInput {
                id: textInput
                anchors.fill: parent
                anchors.margins: 15
                verticalAlignment: Text.AlignVCenter
                color: t.visual?.textColor ?? "#ffffff"
                font.pixelSize: 24
                font.bold: false
                selectByMouse: true
                cursorVisible: true
                focus: true

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        KeyboardSimulator.sendEnter()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Backspace) {
                        KeyboardSimulator.sendBackspace()
                        event.accepted = true
                    }
                }
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
                            textInput.insert(textInput.cursorPosition, key)
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
                            textInput.insert(textInput.cursorPosition, key)
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
                            textInput.insert(textInput.cursorPosition, key)
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
                        textInput.insert(textInput.cursorPosition, " ")
                    }
                }

                KeyButton {
                    label: "←"
                    width: t.layout?.keyWidth ?? 72
                    height: t.layout?.keyHeight ?? 72

                    onKeyPressed: {
                        KeyboardSimulator.sendBackspace()
                        if (textInput.cursorPosition > 0) {
                            textInput.remove(textInput.cursorPosition - 1, textInput.cursorPosition)
                        }
                    }
                }

                KeyButton {
                    label: "Clear"
                    width: 150
                    height: t.layout?.keyHeight ?? 72

                    onKeyPressed: {
                        textInput.clear()
                    }
                }
            }
        }
    }
}
