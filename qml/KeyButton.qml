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

    signal keyPressed(string key)

    property bool pressed: false
    property bool hovered: false

    // Determine glow color based on text color
    property color glowColor: {
        let textColor = t.visual?.textColor ?? "white";
        if (textColor.toLowerCase() === "#00ff88" || textColor.toLowerCase() === "#00ff00") {
            return "#ff00ff";  // Magenta for neon green text
        } else if (textColor.toLowerCase() === "#ffffff") {
            return "#00ff88";  // Green for white text
        } else {
            return "#00ffff";  // Cyan as fallback
        }
    }

    width: t.layout?.keyWidth ?? 72
    height: t.layout?.keyHeight ?? 72

    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.95
        height: parent.height * 0.95
        radius: t.visual?.radius ?? 18
        color: "#000000"
        opacity: root.pressed ? 0.15 : 0.35
        y: root.pressed ? 2 : 6
    }

    // Glow layer for Caps Lock indicator
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

    // Subtle glow shadow effect
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
        color: (root.pressed || root.isCapsActive) ? (t.visual?.keyPressedColor ?? "#3a3a3a") : (t.visual?.keyColor ?? "#2b2b2b")
        y: root.pressed ? 2 : 0

        Behavior on y {
            NumberAnimation {
                duration: t.behavior?.pressAnimationMs ?? 60
            }
        }

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Qt.lighter(base.color, 1.2)
            }
            GradientStop {
                position: 1.0
                color: Qt.darker(base.color, 1.3)
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#ffffff"
            opacity: root.hovered ? (t.visual?.hoverOpacity ?? 0.08) : 0.0
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
