import QtQuick

Rectangle {
    id: root
    width: ThemeManager.getThemeProperty("layout.keyWidth") || 72
    height: ThemeManager.getThemeProperty("layout.keyHeight") || 72
    radius: ThemeManager.getThemeProperty("visual.radius") || 14

    property string label: ""
    property bool isCapsLock: false
    property bool isCapsActive: false
    property bool autoSend: true
    signal keyPressed

    property var theme: ThemeManager.theme || ({})

    property string fontFamily: theme.label?.fontFamily || "Inter"
    property int fontSize: theme.label?.fontSize || 15
    property bool fontBold: theme.label?.bold || false
    property bool fontItalic: theme.label?.italic || false
    property real fontLetterSpacing: theme.label?.letterSpacing || 0.5
    property bool fontUppercase: theme.label?.uppercase || false
    property string fontWeightStr: theme.label?.fontWeight || "Medium"

    property string keyStyle: theme.visual?.keyStyle || "flat"
    property real keyBorderWidth: theme.visual?.keyBorderWidth || 1

    property color baseColor: {
        if (isCapsActive)
            return theme.visual?.keyPressedColor || "#3a3a3a";
        return theme.visual?.keyColor || "#2b2b2b";
    }
    property color pressedColor: theme.visual?.keyPressedColor || "#3a3a3a"
    property color hoverColor: theme.visual?.keyHoverColor || "#353535"
    property color textColor: theme.visual?.textColor || "#ffffff"

    property bool shadowEnabled: theme.visual?.keyShadow?.enabled || false
    property color shadowColor: theme.visual?.keyShadow?.color || "#000000"
    property real shadowX: theme.visual?.keyShadow?.x || 0
    property real shadowY: theme.visual?.keyShadow?.y || 4
    property real shadowOpacity: theme.visual?.keyShadow?.opacity || 0.3

    property bool gradientEnabled: theme.visual?.keyGradient?.enabled || false
    property color gradientStart: theme.visual?.keyGradient?.startColor || "#3a3a3a"
    property color gradientEnd: theme.visual?.keyGradient?.endColor || "#2b2b2b"

    color: {
        if (mouseArea.containsPress)
            return pressedColor;
        if (mouseArea.containsMouse && (theme.features?.enableHover !== false))
            return hoverColor;
        if (keyStyle === "dish")
            return Qt.darker(baseColor, 1.1);
        return baseColor;
    }

    border.color: theme.visual?.borderColor || "#33ffffff"
    border.width: keyBorderWidth

    Rectangle {
        id: shadowRect
        anchors.fill: parent
        radius: parent.radius
        color: shadowColor
        opacity: shadowOpacity
        visible: shadowEnabled && !mouseArea.containsPress
        anchors.leftMargin: shadowX
        anchors.topMargin: shadowY
        z: -1
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        visible: gradientEnabled && !mouseArea.containsPress
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0.0
                color: gradientStart
            }
            GradientStop {
                position: 1.0
                color: gradientEnd
            }
        }
        opacity: 0.85
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        visible: keyStyle === "dish"
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop {
                position: 0.0
                color: "#40ffffff"
            }
            GradientStop {
                position: 0.5
                color: "transparent"
            }
            GradientStop {
                position: 1.0
                color: "#20000000"
            }
        }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: fontUppercase ? root.label.toUpperCase() : root.label
        color: textColor
        font.family: fontFamily
        font.pixelSize: fontSize
        font.bold: fontBold
        font.italic: fontItalic
        font.letterSpacing: fontLetterSpacing
        font.weight: {
            if (fontWeightStr === "Thin")
                return Font.Thin;
            if (fontWeightStr === "Light")
                return Font.Light;
            if (fontWeightStr === "Normal")
                return Font.Normal;
            if (fontWeightStr === "Medium")
                return Font.Medium;
            if (fontWeightStr === "Bold")
                return Font.Bold;
            if (fontWeightStr === "Black")
                return Font.Black;
            return Font.Medium;
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: theme.features?.enableHover !== false

        onPressed: {
            if (autoSend) {
                var key = isCapsLock ? label.toUpperCase() : label;
                KeyboardSimulator.sendKey(key);
            }
            root.keyPressed();
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: theme.behavior?.pressAnimationMs || 60
        }
    }

    transform: Scale {
        origin.x: root.width / 2
        origin.y: root.height / 2
        xScale: mouseArea.containsPress ? (theme.visual?.pressScale || 0.93) : 1.0
        yScale: mouseArea.containsPress ? (theme.visual?.pressScale || 0.93) : 1.0
        Behavior on xScale {
            NumberAnimation {
                duration: theme.behavior?.pressAnimationMs || 60
                easing.type: Easing.OutCubic
            }
        }
        Behavior on yScale {
            NumberAnimation {
                duration: theme.behavior?.pressAnimationMs || 60
                easing.type: Easing.OutCubic
            }
        }
    }
}
