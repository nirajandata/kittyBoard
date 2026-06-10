import QtQuick
import QtQuick.Window

Window {
    id: mainWindow
    width: 1200
    height: 560
    minimumWidth: 800
    minimumHeight: 420
    visible: false
    title: "Kittyboard"
    flags: Qt.FramelessWindowHint

    property real appX: 100
    property real appY: 100
    property var t: ThemeManager.theme ?? ({})
    property bool capsLock: false

    property real dragStartAppX: 0
    property real dragStartAppY: 0
    property var dragStartGlobal: Qt.point(0, 0)

    Component.onCompleted: {
        KeyboardSimulator.moveWindow(Math.round(mainWindow.appX), Math.round(mainWindow.appY));
    }

    Rectangle {
        anchors.fill: parent
        color: t.visual?.background ?? "#121212"
        radius: t.visual?.radius ?? 18
        opacity: t.visual?.backgroundOpacity ?? 1.0
        layer.enabled: true
        layer.smooth: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            visible: t.visual?.backgroundGradient?.enabled ?? false
            gradient: Gradient {
                orientation: {
                    var a = t.visual?.backgroundGradient?.angle ?? 135;
                    if (a === 0 || a === 180)
                        return Gradient.Horizontal;
                    return Gradient.Vertical;
                }
                GradientStop {
                    position: 0.0
                    color: t.visual?.backgroundGradient?.startColor ?? "#1a1a2e"
                }
                GradientStop {
                    position: 1.0
                    color: t.visual?.backgroundGradient?.endColor ?? "#16213e"
                }
            }
            opacity: 0.9
        }

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
            height: 36
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
                id: settingsBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 10
                width: 28
                height: 28
                radius: 14
                color: settingsArea.containsMouse ? "#444444" : "#333333"
                Text {
                    anchors.centerIn: parent
                    text: "⚙"
                    color: "#ffffff"
                    font.pixelSize: 16
                }
                MouseArea {
                    id: settingsArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: themeEditor.visible = true
                }
            }

            Rectangle {
                id: closeBtn
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 10
                width: 24
                height: 24
                radius: 12
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
                    font.pixelSize: 12
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
                id: dragArea
                anchors.left: settingsBtn.right
                anchors.right: closeBtn.left
                anchors.rightMargin: 8
                anchors.leftMargin: 8
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                cursorShape: Qt.SizeAllCursor

                onPressed: {
                    mainWindow.dragStartGlobal = KeyboardSimulator.globalMouse();
                    mainWindow.dragStartAppX = mainWindow.appX;
                    mainWindow.dragStartAppY = mainWindow.appY;
                }

                Timer {
                    id: dragTimer
                    interval: 4
                    repeat: true
                    running: dragArea.pressed
                    onTriggered: {
                        var globalNow = KeyboardSimulator.globalMouse();
                        var newX = mainWindow.dragStartAppX + (globalNow.x - mainWindow.dragStartGlobal.x);
                        var newY = mainWindow.dragStartAppY + (globalNow.y - mainWindow.dragStartGlobal.y);
                        var roundedX = Math.round(newX);
                        var roundedY = Math.round(newY);
                        if (roundedX !== Math.round(mainWindow.appX) || roundedY !== Math.round(mainWindow.appY)) {
                            mainWindow.appX = newX;
                            mainWindow.appY = newY;
                            KeyboardSimulator.moveWindow(roundedX, roundedY);
                        }
                    }
                }

                onReleased: {
                    dragTimer.stop();
                    KeyboardSimulator.moveWindow(Math.round(mainWindow.appX), Math.round(mainWindow.appY));
                }
            }
        }

        Row {
            id: suggestionBar

            readonly property var suggs: (typeof KeyboardSimulator !== "undefined" && KeyboardSimulator !== null && KeyboardSimulator.suggestions) ? KeyboardSimulator.suggestions : []

            anchors.top: dragHandle.bottom
            anchors.topMargin: 4
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            height: suggs.length > 0 ? 46 : 0
            opacity: suggs.length > 0 ? 1.0 : 0.0

            Behavior on height {
                NumberAnimation {
                    duration: 150
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Repeater {
                model: suggestionBar.suggs

                delegate: Rectangle {
                    id: chip
                    width: Math.max(100, chipLabel.implicitWidth + 44)
                    height: 42
                    radius: t.visual?.radius ?? 14

                    property bool hovered: chipMouse.containsMouse
                    property bool isPressed: chipMouse.containsPress

                    color: isPressed ? (t.visual?.keyPressedColor ?? "#1a2a2a") : hovered ? (t.visual?.keyHoverColor ?? "#2a3a2a") : (t.visual?.keyColor ?? "#1e2d3d")
                    opacity: isPressed ? 0.75 : 1.0
                    border.color: t.visual?.textColor ?? "#00e5a0"
                    border.width: hovered ? 1 : 0

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 80
                        }
                    }
                    Behavior on border.width {
                        NumberAnimation {
                            duration: 100
                        }
                    }

                    transform: Scale {
                        origin.x: chip.width / 2
                        origin.y: chip.height / 2
                        xScale: chip.isPressed ? 0.93 : 1.0
                        yScale: chip.isPressed ? 0.93 : 1.0
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

                    Text {
                        id: chipLabel
                        anchors.centerIn: parent
                        text: modelData
                        color: t.visual?.textColor ?? "#00e5a0"
                        font.pixelSize: t.label?.fontSize ?? 15
                        font.bold: t.label?.bold ?? false
                        font.italic: t.label?.italic ?? false
                        font.letterSpacing: t.label?.letterSpacing ?? 0.5
                        font.family: t.label?.fontFamily ?? "Inter"
                        font.weight: {
                            var w = t.label?.fontWeight ?? "Medium";
                            if (w === "Thin")
                                return Font.Thin;
                            if (w === "Light")
                                return Font.Light;
                            if (w === "Normal")
                                return Font.Normal;
                            if (w === "Medium")
                                return Font.Medium;
                            if (w === "Bold")
                                return Font.Bold;
                            if (w === "Black")
                                return Font.Black;
                            return Font.Medium;
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

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: suggestionBar.bottom
            anchors.topMargin: 6
            spacing: t.layout?.rowSpacing ?? 12

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: t.layout?.keySpacing ?? 8

                KeyButton {
                    label: "`"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "1"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "2"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "3"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "4"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "5"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "6"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "7"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "8"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "9"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "0"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "-"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "="
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "Backspace"
                    width: (t.layout?.keyWidth ?? 72) * 1.5
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendBackspace()
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: t.layout?.keySpacing ?? 8

                KeyButton {
                    label: "Tab"
                    width: (t.layout?.keyWidth ?? 72) * 1.25
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendTab()
                }
                KeyButton {
                    label: "q"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "w"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "e"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "r"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "t"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "y"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "u"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "i"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "o"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "p"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "["
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "]"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "\\"
                    isCapsLock: mainWindow.capsLock
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: t.layout?.keySpacing ?? 8

                KeyButton {
                    label: "Caps"
                    width: (t.layout?.keyWidth ?? 72) * 1.5
                    autoSend: false
                    isCapsActive: mainWindow.capsLock
                    onKeyPressed: mainWindow.capsLock = !mainWindow.capsLock
                }
                KeyButton {
                    label: "a"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "s"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "d"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "f"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "g"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "h"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "j"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "k"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "l"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: ";"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "'"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "Enter"
                    width: (t.layout?.keyWidth ?? 72) * 2
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendEnter()
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: t.layout?.keySpacing ?? 8

                KeyButton {
                    label: "Shift"
                    width: (t.layout?.keyWidth ?? 72) * 2
                    autoSend: false
                    onKeyPressed: mainWindow.capsLock = !mainWindow.capsLock
                }
                KeyButton {
                    label: "z"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "x"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "c"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "v"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "b"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "n"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "m"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: ","
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "."
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "/"
                    isCapsLock: mainWindow.capsLock
                }
                KeyButton {
                    label: "Shift"
                    width: (t.layout?.keyWidth ?? 72) * 2
                    autoSend: false
                    onKeyPressed: mainWindow.capsLock = !mainWindow.capsLock
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: t.layout?.keySpacing ?? 8

                KeyButton {
                    label: "Ctrl"
                    width: (t.layout?.keyWidth ?? 72) * 1.25
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendKey("ctrl")
                }
                KeyButton {
                    label: "Alt"
                    width: (t.layout?.keyWidth ?? 72) * 1.25
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendKey("alt")
                }
                KeyButton {
                    label: "Space"
                    width: (t.layout?.keyWidth ?? 72) * 4.5
                    height: t.layout?.keyHeight ?? 72
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendSpace()
                }
                KeyButton {
                    label: "Alt"
                    width: (t.layout?.keyWidth ?? 72) * 1.25
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendKey("alt")
                }
                KeyButton {
                    label: "Super"
                    width: (t.layout?.keyWidth ?? 72) * 1.25
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendKey("super")
                }
                KeyButton {
                    label: "←"
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendArrow("left")
                }
                KeyButton {
                    label: "↓"
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendArrow("down")
                }
                KeyButton {
                    label: "↑"
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendArrow("up")
                }
                KeyButton {
                    label: "→"
                    autoSend: false
                    onKeyPressed: KeyboardSimulator.sendArrow("right")
                }
            }
        }

        Item {
            id: resizeHandle
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: 24
            height: 24

            Canvas {
                id: resizeCanvas
                anchors.fill: parent
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.strokeStyle = t.visual?.textColor ?? "#00e5a0";
                    ctx.globalAlpha = resizeMouse.containsMouse ? 0.7 : 0.3;
                    ctx.lineWidth = 1.5;
                    ctx.lineCap = "round";
                    var margin = 4;
                    var gap = 5;
                    for (var i = 0; i < 3; i++) {
                        var offset = margin + i * gap;
                        ctx.beginPath();
                        ctx.moveTo(width - margin, offset);
                        ctx.lineTo(offset, height - margin);
                        ctx.stroke();
                    }
                }

                Connections {
                    target: resizeMouse
                    function onContainsMouseChanged() {
                        resizeCanvas.requestPaint();
                    }
                }
            }

            MouseArea {
                id: resizeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeFDiagCursor

                property real startMouseX: 0
                property real startMouseY: 0
                property real startWidth: 0
                property real startHeight: 0

                onPressed: mouse => {
                    startMouseX = mouse.x + mainWindow.appX + resizeHandle.x;
                    startMouseY = mouse.y + mainWindow.appY + resizeHandle.y;
                    startWidth = mainWindow.width;
                    startHeight = mainWindow.height;
                }

                onPositionChanged: mouse => {
                    if (!pressed)
                        return;
                    var globalX = mouse.x + mainWindow.appX + resizeHandle.x;
                    var globalY = mouse.y + mainWindow.appY + resizeHandle.y;
                    var newW = startWidth + (globalX - startMouseX);
                    var newH = startHeight + (globalY - startMouseY);
                    mainWindow.width = Math.max(mainWindow.minimumWidth, newW);
                    mainWindow.height = Math.max(mainWindow.minimumHeight, newH);
                }
            }
        }

        ThemeEditor {
            id: themeEditor
            anchors.fill: parent
            visible: false
        }
    }
}
