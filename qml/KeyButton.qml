import QtQuick

Item {
    id: root

    property var t: ThemeManager ? ThemeManager.theme : {}
    property string label: "A"

    // Set to false for Space/Backspace/Enter — Main.qml handles their
    // send call via onKeyPressed. For letter/number keys this stays true.
    property bool autoSend: true

    signal keyPressed(string key)

    property bool pressed: false
    property bool hovered: false

    width: t.layout?.keyWidth ?? 72
    height: t.layout?.keyHeight ?? 72

    // Shadow
    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 0.95
        height: parent.height * 0.95
        radius: t.visual?.radius ?? 18
        color: "#000000"
        opacity: root.pressed ? 0.15 : 0.35
        y: root.pressed ? 2 : 6
    }

    Rectangle {
        id: base
        anchors.fill: parent
        radius: t.visual?.radius ?? 18
        color: root.pressed ? (t.visual?.keyPressedColor ?? "#3a3a3a") : (t.visual?.keyColor ?? "#2b2b2b")
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
            text: root.label
            color: t.visual?.textColor ?? "white"
            font.pixelSize: 22
            font.bold: true
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
            if (root.autoSend)
                KeyboardSimulator.sendKey(root.label);
            root.keyPressed(root.label);
        }
    }
}
