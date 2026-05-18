import QtQuick
import QtQuick.Window

Window {
    id: mainWindow
    width: 900
    height: 420
    visible: false
    title: "Kittyboard"
    flags: Qt.FramelessWindowHint

    property real appX: 100
    property real appY: 100

    property var t: ({})
    property bool capsLock: false

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
        KeyboardSimulator.moveWindow(Math.round(mainWindow.appX), Math.round(mainWindow.appY));
    }

    Rectangle {
        anchors.fill: parent
        color: t.visual?.background ?? "#121212"
        radius: t.visual?.radius ?? 18

        Rectangle {
            id: dragHandle
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 32
            color: "transparent"

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

            MouseArea {
                anchors.left: parent.left
                anchors.right: closeBtn.left
                anchors.rightMargin: 8
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                cursorShape: Qt.SizeAllCursor

                property point startGlobalPos
                property real startAppX
                property real startAppY

                property real startX
                property real startY

                onPressed: mouse => {
                    startGlobalPos = KeyboardSimulator.globalMouse();
                    startAppX = mainWindow.appX;
                    startAppY = mainWindow.appY;

                    startX = mouse.x;
                    startY = mouse.y;
                }

                onPositionChanged: mouse => {
                    if (!pressed)
                        return;

                    let currentGlobal = KeyboardSimulator.globalMouse();
                    let dx = currentGlobal.x - startGlobalPos.x;
                    let dy = currentGlobal.y - startGlobalPos.y;

                    if (startGlobalPos.x === 0 && startGlobalPos.y === 0 && currentGlobal.x === 0) {
                        dx = mouse.x - startX;
                        dy = mouse.y - startY;

                        if (dx === 0 && dy === 0)
                            return;

                        mainWindow.appX += dx;
                        mainWindow.appY += dy;

                        startX = mouse.x;
                        startY = mouse.y;
                    } else {
                        if (dx === 0 && dy === 0)
                            return;

                        mainWindow.appX = startAppX + dx;
                        mainWindow.appY = startAppY + dy;
                    }

                    KeyboardSimulator.moveWindow(Math.round(mainWindow.appX), Math.round(mainWindow.appY));
                }
            }
        }

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
                        isCapsLock: mainWindow.capsLock
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: t.layout?.keySpacing ?? 8

                KeyButton {
                    label: "Caps"
                    width: 100
                    autoSend: false
                    isCapsActive: mainWindow.capsLock
                    onKeyPressed: mainWindow.capsLock = !mainWindow.capsLock
                }

                Repeater {
                    model: ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
                    KeyButton {
                        label: modelData
                        isCapsLock: mainWindow.capsLock
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
                        isCapsLock: mainWindow.capsLock
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
