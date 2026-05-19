import QtQuick

Item {
    id: root

    property var t: ThemeManager ? ThemeManager.theme : {}
    property string label: "A"
    property bool autoSend: true

    property bool isCapsLock: false
    property bool isCapsActive: false
    property bool isAlpha: label.length === 1 && label.match(/[a-z]/i)
    property string displayText: isAlpha ? (isCapsLock ? label.toUpperCase() : label.toLowerCase()) : label

    property real bgImageOpacity: t.visual?.backgroundImageOpacity ?? 0.0

    signal keyPressed(string key)

    property bool pressed: false
    property bool hovered: false

    property color glowColor: {
        let textColor = t.visual?.textColor ?? "white";
        if (textColor.toLowerCase() === "#00ff88" || textColor.toLowerCase() === "#00ff00") {
            return "#ff00ff";
        } else if (textColor.toLowerCase() === "#ffffff") {
            return "#00ff88";
        } else {
            return "#00ffff";
        }
    }

    property color resolvedKeyColor: (root.pressed || root.isCapsActive) ? (t.visual?.keyPressedColor ?? "#3a3a3a") : (t.visual?.keyColor ?? "#2b2b2b")

    property real keyAlpha: Math.max(0.15, 1.0 - bgImageOpacity * 0.85)

    width: t.layout?.keyWidth ?? 72
    height: t.layout?.keyHeight ?? 72

    // Drop shadow
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.95
        height: parent.height * 0.95
        radius: t.visual?.radius ?? 18
        color: "#000000"
        opacity: root.pressed ? 0.10 : 0.25
        y: root.pressed ? 2 : 6
    }

    Rectangle {
        id: glowLayer
        anchors.fill: parent
        radius: t.visual?.radius ?? 18
        color: "transparent"
        visible: root.isCapsActive && root.isCapsLock
        border.color: root.glowColor
        border.width: 2

        Behavior on border.width {
            NumberAnimation {
                duration: 200
            }
        }
    }

    Rectangle {
        anchors.fill: glowLayer
        anchors.margins: -4
        radius: glowLayer.radius + 4
        color: "transparent"
        visible: root.isCapsActive && root.isCapsLock

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: root.glowColor
            opacity: 0.15
            z: -1
        }
    }

    Rectangle {
        id: base
        anchors.fill: parent
        radius: t.visual?.radius ?? 18

        color: Qt.rgba(root.resolvedKeyColor.r, root.resolvedKeyColor.g, root.resolvedKeyColor.b, root.keyAlpha)

        y: root.pressed ? 2 : 0

        Behavior on y {
            NumberAnimation {
                duration: t.behavior?.pressAnimationMs ?? 60
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: t.behavior?.pressAnimationMs ?? 60
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height * 0.45
            radius: parent.radius
            color: "#ffffff"
            opacity: 0.06
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: root.hovered ? (t.visual?.hoverOpacity ?? 0.08) : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: t.behavior?.hoverAnimationMs ?? 150
                }
            }
        }

        Text {
            anchors.centerIn: parent
            text: root.displayText
            color: root.isCapsActive ? root.glowColor : (t.visual?.textColor ?? "white")
            font.pixelSize: 22
            font.bold: true

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true

        onEntered: root.hovered = true
        onExited: root.hovered = false
        onPressed: root.pressed = true

        onReleased: {
            root.pressed = false;
            if (root.autoSend) {
                KeyboardSimulator.sendKey(root.displayText);
            }
            root.keyPressed(root.displayText);
        }
    }
}
