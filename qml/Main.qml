import QtQuick
import QtQuick.Window

Window {
    id: mainWindow
    width: 900
    height: 480
    minimumWidth: 600
    minimumHeight: 380
    visible: false
    title: "Kittyboard"
    flags: Qt.FramelessWindowHint

    property real appX: 100
    property real appY: 100
    property var t: ({})
    property bool capsLock: false

    property real dragStartAppX: 0
    property real dragStartAppY: 0
    property var dragStartGlobal: Qt.point(0, 0)

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
