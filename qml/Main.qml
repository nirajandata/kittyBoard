import QtQuick
import QtQuick.Window

Window {
    id: mainWindow
    width: 900
    height: 480
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
        layer.enabled: true
        layer.smooth: true

        Image {
            anchors.fill: parent
            source: t.visual?.backgroundImage ? t.visual.backgroundImage : ""
            opacity: t.visual?.backgroundImageOpacity ?? 0.3
            fillMode: Image.PreserveAspectCrop
            smooth: true
            visible: source !== ""
        }

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

                property real lastX: 0
                property real lastY: 0

                onPressed: mouse => {
                    lastX = mouse.x;
                    lastY = mouse.y;
                }

                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    mainWindow.appX += mouse.x - lastX;
                    mainWindow.appY += mouse.y - lastY;
                    lastX = mouse.x;
                    lastY = mouse.y;
                    KeyboardSimulator.moveWindow(Math.round(mainWindow.appX), Math.round(mainWindow.appY));
                }

                onReleased: {
                    KeyboardSimulator.moveWindow(Math.round(mainWindow.appX), Math.round(mainWindow.appY));
                }
            }
        }

        Rectangle {
            id: suggestionBar
            anchors.top: dragHandle.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            height: 44
            width: parent.width - 24
            radius: 22
            color: "#0f0f0f"
            border.color: "#2a2a2a"
            border.width: 1

            readonly property var suggs: (typeof KeyboardSimulator !== "undefined" && KeyboardSimulator !== null && KeyboardSimulator.suggestions) ? KeyboardSimulator.suggestions : []

            visible: suggs.length > 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                }
            }

            opacity: suggs.length > 0 ? 1.0 : 0.0

            Row {
                id: suggRow
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: suggestionBar.suggs

                    delegate: Rectangle {
                        id: suggChip
                        width: Math.max(88, chipLabel.implicitWidth + 36)
                        height: 36
                        radius: 18

                        property bool hovered: chipMouse.containsMouse
                        property bool isPressed: chipMouse.containsPress

                        color: isPressed ? "#3a3a3a" : (hovered ? "#252525" : "transparent")

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }

                        transform: Scale {
                            origin.x: suggChip.width / 2
                            origin.y: suggChip.height / 2
                            xScale: suggChip.isPressed ? 0.94 : 1.0
                            yScale: suggChip.isPressed ? 0.94 : 1.0
                            Behavior on xScale {
                                NumberAnimation {
                                    duration: 80
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on yScale {
                                NumberAnimation {
                                    duration: 80
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        Rectangle {
                            visible: index < suggestionBar.suggs.length - 1
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 16
                            color: "#2a2a2a"
                        }

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: modelData
                            color: suggChip.hovered ? "#ffffff" : "#c8c8c8"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            font.letterSpacing: 0.3
                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                        }

                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: KeyboardSimulator.applySuggestion(modelData)
                        }
                    }
                }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: suggestionBar.bottom
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
