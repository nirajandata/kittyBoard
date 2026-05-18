import QtQuick
import QtQuick.Window

Window {
    id: mainWindow
    width: 900
    height: 420
    visible: false  // main.cpp shows it after layer-shell is configured
    title: "Kittyboard"
    flags: Qt.FramelessWindowHint

    property var t: ({})

    Connections {
        target: ThemeManager
        function onThemeChanged() {
            t = ThemeManager.theme;
        }
    }

    Component.onCompleted: {
        if (ThemeManager.theme && Object.keys(ThemeManager.theme).length > 0)
            t = ThemeManager.theme;
    }

    // Root background
    Rectangle {
        anchors.fill: parent
        color: t.visual?.background ?? "#121212"
        radius: t.visual?.radius ?? 18

        // ── Drag handle ──────────────────────────────────────────────────
        Rectangle {
            id: dragHandle
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 32
            color: "transparent"

            // Grip dots (centred, stays clear of the close button)
            Row {
                anchors.centerIn: parent
                spacing: 5
                Repeater {
                    model: 5
                    Rectangle {
                        width: 28
                        height: 3
                        radius: 2
                        color: t.visual?.textColor ?? "#ffffff"
                        opacity: 0.25
                    }
                }
            }

            // Close button — top-right corner
            Rectangle {
                id: closeBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 10
                width: 22
                height: 22
                radius: 11
                color: closeBtnArea.containsMouse ? "#e05555" : "#aa3333"

                Behavior on color {
                    ColorAnimation {
                        duration: 120
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: "#ffffff"
                    font.pixelSize: 11
                    font.bold: true
                }

                MouseArea {
                    id: closeBtnArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: Qt.quit()
                }
            }

            // Drag area — leave room on the right for the close button
            MouseArea {
                anchors.left: parent.left
                anchors.right: closeBtn.left
                anchors.rightMargin: 8
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                cursorShape: Qt.SizeAllCursor
                property point startPos

                onPressed: mouse => {
                    startPos = Qt.point(mouse.screenX, mouse.screenY);
                }
                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    let dx = mouse.screenX - startPos.x;
                    let dy = mouse.screenY - startPos.y;
                    mainWindow.x += dx;
                    mainWindow.y += dy;
                    startPos = Qt.point(mouse.screenX, mouse.screenY);
                }
            }
        }

        // ── Keys ─────────────────────────────────────────────────────────
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: dragHandle.bottom
            anchors.topMargin: 8
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
}
