import QtQuick
import QtQuick.Window

Window {
    id: mainWindow

    // Width/height are managed by layer-shell anchors in main.cpp.
    // These are just fallback values.
    width: 900
    height: 400
    visible: false  // main.cpp shows it after layer-shell is configured
    title: "Kittyboard"

    // No special focus flags needed here — layer-shell in main.cpp
    // handles all of that at the Wayland protocol level.
    // Qt.FramelessWindowHint is still fine for aesthetics.
    flags: Qt.FramelessWindowHint

    property var t: ({})

    Connections {
        target: ThemeManager
        function onThemeChanged() {
            t = ThemeManager.theme;
        }
    }

    Component.onCompleted: {
        if (ThemeManager.theme && Object.keys(ThemeManager.theme).length > 0) {
            t = ThemeManager.theme;
        }
    }

    Rectangle {
        anchors.fill: parent
        color: t.visual?.background ?? "#121212"
    }

    Column {
        anchors.centerIn: parent
        spacing: t.layout?.rowSpacing ?? 12

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: t.layout?.keySpacing ?? 8
            Repeater {
                model: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
                KeyButton {
                    label: modelData
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
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: t.layout?.keySpacing ?? 8

            KeyButton {
                label: "Space"
                width: 300
                height: t.layout?.keyHeight ?? 72
                autoSend: false
                onKeyPressed: KeyboardSimulator.sendSpace()
            }

            KeyButton {
                label: "←"
                width: t.layout?.keyWidth ?? 72
                height: t.layout?.keyHeight ?? 72
                autoSend: false
                onKeyPressed: KeyboardSimulator.sendBackspace()
            }

            KeyButton {
                label: "Enter"
                width: 150
                height: t.layout?.keyHeight ?? 72
                autoSend: false
                onKeyPressed: KeyboardSimulator.sendEnter()
            }
        }
    }
}
