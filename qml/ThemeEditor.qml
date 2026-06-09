import QtQuick

Rectangle {
    id: editor
    anchors.fill: parent
    color: "#cc000000"
    visible: false

    property var t: ThemeManager.theme ?? ({})

    function tv(path, def) {
        var parts = path.split(".");
        var cur = t;
        for (var i = 0; i < parts.length; i++) {
            if (cur === undefined || cur === null)
                return def;
            cur = cur[parts[i]];
        }
        return (cur !== undefined && cur !== null) ? cur : def;
    }

    function normalizeHex(raw) {
        var s = String(raw || "#000000").replace(/^#/, "");
        if (s.length === 3)
            s = s.split("").map(function (c) {
                return c + c;
            }).join("");
        if (s.length === 8)
            s = s.substring(2);
        if (s.length !== 6)
            s = "000000";
        return "#" + s;
    }

    function hexToRgb(hex) {
        var s = normalizeHex(hex).replace("#", "");
        var num = parseInt(s, 16) || 0;
        return {
            r: (num >> 16) & 255,
            g: (num >> 8) & 255,
            b: num & 255
        };
    }

    function rgbToHex(r, g, b) {
        var toHex = function (x) {
            x = Math.max(0, Math.min(255, Math.round(x)));
            var h = x.toString(16);
            return h.length === 1 ? "0" + h : h;
        };
        return "#" + toHex(r) + toHex(g) + toHex(b);
    }

    function hexToHsl(hex) {
        var c = hexToRgb(hex);
        var r = c.r / 255;
        var g = c.g / 255;
        var b = c.b / 255;
        var max = Math.max(r, g, b);
        var min = Math.min(r, g, b);
        var h = 0;
        var s = 0;
        var l = (max + min) / 2;
        if (max !== min) {
            var d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            if (max === r) {
                h = ((g - b) / d + (g < b ? 6 : 0)) / 6;
            } else if (max === g) {
                h = ((b - r) / d + 2) / 6;
            } else {
                h = ((r - g) / d + 4) / 6;
            }
        }
        return {
            h: h * 360,
            s: s,
            l: l
        };
    }

    function hslToHex(h, s, l) {
        h = ((h % 360) + 360) % 360 / 360;
        var r, g, b;
        if (s === 0) {
            r = g = b = l;
        } else {
            var hue2rgb = function (p, q, t) {
                if (t < 0)
                    t += 1;
                if (t > 1)
                    t -= 1;
                if (t < 1 / 6)
                    return p + (q - p) * 6 * t;
                if (t < 1 / 2)
                    return q;
                if (t < 2 / 3)
                    return p + (q - p) * (2 / 3 - t) * 6;
                return p;
            };
            var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            var p = 2 * l - q;
            r = hue2rgb(p, q, h + 1 / 3);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1 / 3);
        }
        return rgbToHex(r * 255, g * 255, b * 255);
    }

    property int currentTab: 0
    property var tabs: ["Keyboard", "Keys", "Label"]

    MouseArea {
        anchors.fill: parent
        onClicked: editor.visible = false
    }

    Rectangle {
        id: card
        width: 520
        height: Math.min(editor.height - 60, 720)
        anchors.centerIn: parent
        radius: 24
        color: "#1e1e1e"
        border.color: "#333"
        border.width: 1

        MouseArea {
            anchors.fill: parent
        }

        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 0

            Row {
                width: parent.width
                height: 44
                spacing: 12

                Text {
                    text: "Theme Editor"
                    color: "#fff"
                    font.pixelSize: 20
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
                Item {
                    width: parent.width - 200
                    height: 1
                }
                Rectangle {
                    width: 36
                    height: 36
                    radius: 10
                    color: closeHdr.containsMouse ? "#e05555" : "#333"
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "#fff"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    MouseArea {
                        id: closeHdr
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: editor.visible = false
                    }
                }
            }

            Row {
                width: parent.width
                height: 40
                spacing: 8
                topPadding: 8
                bottomPadding: 16

                Repeater {
                    model: tabs
                    Rectangle {
                        width: tabTxt.implicitWidth + 24
                        height: 34
                        radius: 10
                        color: currentTab === index ? "#00e5a0" : "#2a2a2a"
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            id: tabTxt
                            anchors.centerIn: parent
                            text: modelData
                            color: currentTab === index ? "#000" : "#aaa"
                            font.bold: true
                            font.pixelSize: 13
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: currentTab = index
                        }
                    }
                }
            }

            Flickable {
                width: parent.width
                height: parent.height - 140
                contentHeight: contentCol.implicitHeight + 20
                clip: true
                interactive: true

                Column {
                    id: contentCol
                    width: parent.width
                    spacing: 6

                    Column {
                        visible: currentTab === 0
                        width: parent.width
                        spacing: 10

                        SectionTitle {
                            text: "Background"
                        }
                        SliderRow {
                            label: "Opacity"
                            path: "visual.backgroundImageOpacity"
                            min: 0
                            max: 1
                            decimals: 2
                        }
                        ToggleRow {
                            label: "Gradient"
                            path: "visual.backgroundGradient.enabled"
                        }
                        ColorRow {
                            label: "Gradient Start"
                            path: "visual.backgroundGradient.startColor"
                        }
                        ColorRow {
                            label: "Gradient End"
                            path: "visual.backgroundGradient.endColor"
                        }
                        SliderRow {
                            label: "Gradient Angle"
                            path: "visual.backgroundGradient.angle"
                            min: 0
                            max: 360
                        }

                        SectionTitle {
                            text: "Window Shadow"
                        }
                        ToggleRow {
                            label: "Enable Shadow"
                            path: "visual.shadow.enabled"
                        }
                        ColorRow {
                            label: "Shadow Color"
                            path: "visual.shadow.color"
                        }
                        SliderRow {
                            label: "Blur"
                            path: "visual.shadow.blur"
                            min: 0
                            max: 64
                        }
                        SliderRow {
                            label: "X Offset"
                            path: "visual.shadow.x"
                            min: -32
                            max: 32
                        }
                        SliderRow {
                            label: "Y Offset"
                            path: "visual.shadow.y"
                            min: -32
                            max: 32
                        }
                        SliderRow {
                            label: "Strength"
                            path: "visual.shadow.opacity"
                            min: 0
                            max: 1
                            decimals: 2
                        }
                    }

                    Column {
                        visible: currentTab === 1
                        width: parent.width
                        spacing: 10

                        SectionTitle {
                            text: "Style"
                        }
                        SegmentedRow {
                            label: "Key Style"
                            path: "visual.keyStyle"
                            options: ["flat", "gradient", "dish"]
                        }

                        SectionTitle {
                            text: "Colors"
                        }
                        ColorRow {
                            label: "Key Color"
                            path: "visual.keyColor"
                        }
                        ColorRow {
                            label: "Pressed"
                            path: "visual.keyPressedColor"
                        }
                        ColorRow {
                            label: "Hover"
                            path: "visual.keyHoverColor"
                        }
                        ColorRow {
                            label: "Border"
                            path: "visual.borderColor"
                        }
                        SliderRow {
                            label: "Border Width"
                            path: "visual.keyBorderWidth"
                            min: 0
                            max: 8
                        }
                        SliderRow {
                            label: "Roundness"
                            path: "visual.radius"
                            min: 0
                            max: 40
                        }

                        SectionTitle {
                            text: "Key Gradient"
                        }
                        ToggleRow {
                            label: "Enable"
                            path: "visual.keyGradient.enabled"
                        }
                        ColorRow {
                            label: "Start"
                            path: "visual.keyGradient.startColor"
                        }
                        ColorRow {
                            label: "End"
                            path: "visual.keyGradient.endColor"
                        }
                        SliderRow {
                            label: "Angle"
                            path: "visual.keyGradient.angle"
                            min: 0
                            max: 360
                        }

                        SectionTitle {
                            text: "Key Shadow"
                        }
                        ToggleRow {
                            label: "Enable"
                            path: "visual.keyShadow.enabled"
                        }
                        ColorRow {
                            label: "Color"
                            path: "visual.keyShadow.color"
                        }
                        SliderRow {
                            label: "Blur"
                            path: "visual.keyShadow.blur"
                            min: 0
                            max: 48
                        }
                        SliderRow {
                            label: "X Offset"
                            path: "visual.keyShadow.x"
                            min: -16
                            max: 16
                        }
                        SliderRow {
                            label: "Y Offset"
                            path: "visual.keyShadow.y"
                            min: -16
                            max: 16
                        }
                        SliderRow {
                            label: "Strength"
                            path: "visual.keyShadow.opacity"
                            min: 0
                            max: 1
                            decimals: 2
                        }

                        SectionTitle {
                            text: "Layout"
                        }
                        SliderRow {
                            label: "Key Width"
                            path: "layout.keyWidth"
                            min: 40
                            max: 120
                        }
                        SliderRow {
                            label: "Key Height"
                            path: "layout.keyHeight"
                            min: 40
                            max: 120
                        }
                        SliderRow {
                            label: "Key Gap"
                            path: "layout.keySpacing"
                            min: 0
                            max: 24
                        }
                        SliderRow {
                            label: "Row Gap"
                            path: "layout.rowSpacing"
                            min: 0
                            max: 32
                        }
                        SliderRow {
                            label: "Press Scale"
                            path: "visual.pressScale"
                            min: 0.5
                            max: 1.0
                            decimals: 2
                        }
                    }

                    Column {
                        visible: currentTab === 2
                        width: parent.width
                        spacing: 10

                        SectionTitle {
                            text: "Font"
                        }
                        DropdownRow {
                            label: "Family"
                            path: "label.fontFamily"
                            options: ["Inter", "Roboto", "JetBrains Mono", "SF Pro", "System OS"]
                        }
                        SliderRow {
                            label: "Size"
                            path: "label.fontSize"
                            min: 8
                            max: 32
                        }
                        ToggleRow {
                            label: "Bold"
                            path: "label.bold"
                        }
                        ToggleRow {
                            label: "Italic"
                            path: "label.italic"
                        }
                        SliderRow {
                            label: "Letter Spacing"
                            path: "label.letterSpacing"
                            min: -2
                            max: 8
                            decimals: 1
                        }
                        ToggleRow {
                            label: "Uppercase"
                            path: "label.uppercase"
                        }

                        SectionTitle {
                            text: "Weight"
                        }
                        SegmentedRow {
                            label: "Weight"
                            path: "label.fontWeight"
                            options: ["Thin", "Light", "Normal", "Medium", "Bold", "Black"]
                        }

                        SectionTitle {
                            text: "Color"
                        }
                        ColorRow {
                            label: "Text Color"
                            path: "visual.textColor"
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 50
                spacing: 12
                topPadding: 8

                Rectangle {
                    width: parent.width / 2 - 6
                    height: 40
                    radius: 10
                    color: saveArea.containsMouse ? "#00c48c" : "#00e5a0"
                    Text {
                        anchors.centerIn: parent
                        text: "Save Theme"
                        color: "#000"
                        font.bold: true
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: saveArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: ThemeManager.saveCurrentTheme()
                    }
                }

                Rectangle {
                    width: parent.width / 2 - 6
                    height: 40
                    radius: 10
                    color: resetArea.containsMouse ? "#444" : "#333"
                    Text {
                        anchors.centerIn: parent
                        text: "Reset"
                        color: "#fff"
                        font.bold: true
                        font.pixelSize: 14
                    }
                    MouseArea {
                        id: resetArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: ThemeManager.loadTheme(ThemeManager.currentTheme)
                    }
                }
            }
        }
    }

    Rectangle {
        id: colorPopup
        anchors.fill: parent
        color: "#aa000000"
        visible: false
        z: 200

        property string targetPath: ""
        property real h: 0
        property real s: 0
        property real l: 0.5

        function open(path) {
            targetPath = path;
            var c = editor.normalizeHex(editor.tv(path, "#000000"));
            var hsl = editor.hexToHsl(c);
            h = hsl.h;
            s = hsl.s;
            l = hsl.l;
            visible = true;
        }

        function save() {
            ThemeManager.setThemeProperty(targetPath, editor.hslToHex(h, s, l));
            visible = false;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: colorPopup.visible = false
        }

        Rectangle {
            id: popupCard
            width: Math.max(280, Math.min(340, parent.width - 32))
            height: Math.max(300, Math.min(440, parent.height - 32))
            anchors.centerIn: parent
            radius: 20
            color: "#252525"
            border.color: "#444"
            border.width: 1

            MouseArea {
                anchors.fill: parent
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 20
                contentHeight: popupCol.implicitHeight
                clip: true

                Column {
                    id: popupCol
                    width: parent.width
                    spacing: 12

                    Row {
                        width: parent.width
                        Text {
                            text: "Color Picker"
                            color: "#fff"
                            font.pixelSize: 18
                            font.bold: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Item {
                            width: parent.width - 100
                            height: 1
                        }
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 8
                            color: "#333"
                            Text {
                                anchors.centerIn: parent
                                text: "✕"
                                color: "#fff"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: colorPopup.visible = false
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 40
                        radius: 12
                        color: editor.hslToHex(colorPopup.h, colorPopup.s, colorPopup.l)
                        border.color: "#555"
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: parent.color.toString()
                            color: {
                                var c = editor.hexToRgb(parent.color);
                                var yiq = ((c.r * 299) + (c.g * 587) + (c.b * 114)) / 1000;
                                return yiq >= 128 ? "#000" : "#fff";
                            }
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 32
                        radius: 8
                        color: "#1a1a1a"
                        border.color: "#444"
                        TextInput {
                            id: hexInput
                            anchors.fill: parent
                            anchors.margins: 8
                            text: editor.hslToHex(colorPopup.h, colorPopup.s, colorPopup.l)
                            color: "#fff"
                            font.pixelSize: 14
                            onEditingFinished: {
                                var c = editor.normalizeHex(text);
                                var hsl = editor.hexToHsl(c);
                                colorPopup.h = hsl.h;
                                colorPopup.s = hsl.s;
                                colorPopup.l = hsl.l;
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: Math.min(140, parent.width * 0.45)
                        Canvas {
                            id: hsCanvas
                            anchors.fill: parent
                            onPaint: {
                                var ctx = getContext("2d");
                                var w = width;
                                var h = height;
                                for (var x = 0; x < w; x++) {
                                    var hue = (x / w) * 360;
                                    var grad = ctx.createLinearGradient(x, 0, x, h);
                                    grad.addColorStop(0, editor.hslToHex(hue, 1, 0.5));
                                    grad.addColorStop(1, editor.hslToHex(hue, 0, 0.5));
                                    ctx.fillStyle = grad;
                                    ctx.fillRect(x, 0, 1, h);
                                }
                            }
                        }
                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: "transparent"
                            border.color: "#fff"
                            border.width: 2
                            x: (colorPopup.h / 360) * parent.width - 6
                            y: (1 - colorPopup.s) * parent.height - 6
                        }
                        MouseArea {
                            anchors.fill: parent
                            function update(mx, my) {
                                colorPopup.h = Math.max(0, Math.min(360, (mx / parent.width) * 360));
                                colorPopup.s = Math.max(0, Math.min(1, 1 - (my / parent.height)));
                            }
                            onPressed: mouse => update(mouse.x, mouse.y)
                            onPositionChanged: mouse => {
                                if (pressed)
                                    update(mouse.x, mouse.y);
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: 20
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: editor.hslToHex(colorPopup.h, colorPopup.s, 0)
                                }
                                GradientStop {
                                    position: 0.5
                                    color: editor.hslToHex(colorPopup.h, colorPopup.s, 0.5)
                                }
                                GradientStop {
                                    position: 1.0
                                    color: editor.hslToHex(colorPopup.h, colorPopup.s, 1)
                                }
                            }
                        }
                        Rectangle {
                            width: 4
                            height: parent.height + 4
                            radius: 2
                            color: "#fff"
                            anchors.verticalCenter: parent.verticalCenter
                            x: colorPopup.l * parent.width - 2
                        }
                        MouseArea {
                            anchors.fill: parent
                            function update(mx) {
                                colorPopup.l = Math.max(0, Math.min(1, mx / parent.width));
                            }
                            onPressed: mouse => update(mouse.x)
                            onPositionChanged: mouse => {
                                if (pressed)
                                    update(mouse.x);
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 10
                        Text {
                            text: "H: " + Math.round(colorPopup.h)
                            color: "#aaa"
                            font.pixelSize: 12
                        }
                        Text {
                            text: "S: " + Math.round(colorPopup.s * 100) + "%"
                            color: "#aaa"
                            font.pixelSize: 12
                        }
                        Text {
                            text: "L: " + Math.round(colorPopup.l * 100) + "%"
                            color: "#aaa"
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: 10
                        color: okArea.containsMouse ? "#00c48c" : "#00e5a0"
                        Text {
                            anchors.centerIn: parent
                            text: "Apply"
                            color: "#000"
                            font.bold: true
                            font.pixelSize: 15
                        }
                        MouseArea {
                            id: okArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: colorPopup.save()
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: optionsPopup
        anchors.fill: parent
        color: "#aa000000"
        visible: false
        z: 200

        property string targetPath: ""
        property string labelTitle: ""
        property var optionsList: []
        property string defaultValue: ""

        function open(title, path, options, def) {
            labelTitle = title;
            targetPath = path;
            optionsList = options;
            defaultValue = def;
            visible = true;
        }

        MouseArea {
            anchors.fill: parent
            onClicked: optionsPopup.visible = false
        }

        Rectangle {
            id: optPopupCard
            width: 280
            height: Math.min(400, optPopupCol.implicitHeight + 40)
            anchors.centerIn: parent
            radius: 20
            color: "#252525"
            border.color: "#444"
            border.width: 1

            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: optPopupCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Row {
                    width: parent.width
                    Text {
                        text: optionsPopup.labelTitle
                        color: "#fff"
                        font.pixelSize: 16
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item {
                        width: parent.width - 100
                        height: 1
                    }
                    Rectangle {
                        width: 32
                        height: 32
                        radius: 8
                        color: "#333"
                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: "#fff"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: optionsPopup.visible = false
                        }
                    }
                }

                Flickable {
                    width: parent.width
                    height: Math.min(300, optItemsCol.implicitHeight)
                    contentHeight: optItemsCol.implicitHeight
                    clip: true

                    Column {
                        id: optItemsCol
                        width: parent.width
                        spacing: 6

                        Repeater {
                            model: optionsPopup.optionsList
                            Rectangle {
                                width: parent.width
                                height: 36
                                radius: 8
                                color: editor.tv(optionsPopup.targetPath, optionsPopup.defaultValue) === modelData ? "#00e5a0" : (optItemArea.containsMouse ? "#333" : "#2a2a2a")

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: editor.tv(optionsPopup.targetPath, optionsPopup.defaultValue) === modelData ? "#000" : "#fff"
                                    font.bold: true
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    id: optItemArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        ThemeManager.setThemeProperty(optionsPopup.targetPath, modelData);
                                        optionsPopup.visible = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component SectionTitle: Text {
        color: "#00e5a0"
        font.pixelSize: 12
        font.bold: true
        topPadding: 14
        bottomPadding: 4
    }

    component ColorRow: Row {
        property string label: ""
        property string path: ""
        property string defaultValue: "#000000"
        spacing: 12
        height: 36

        Text {
            text: label
            color: "#ccc"
            width: 120
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 200
            height: 32
            radius: 8
            color: "#2a2a2a"
            border.color: "#444"

            Row {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 8

                Rectangle {
                    width: 24
                    height: 24
                    radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: editor.normalizeHex(editor.tv(path, defaultValue))
                    border.color: "#666"
                    border.width: 1
                }
                Text {
                    text: String(editor.tv(path, defaultValue))
                    color: "#fff"
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    width: 90
                }
                Item {
                    width: 4
                    height: 1
                }
                Rectangle {
                    width: 50
                    height: 24
                    radius: 6
                    color: pickArea.containsMouse ? "#444" : "#333"
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        anchors.centerIn: parent
                        text: "Pick"
                        color: "#fff"
                        font.pixelSize: 11
                        font.bold: true
                    }
                    MouseArea {
                        id: pickArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: colorPopup.open(path)
                    }
                }
            }
        }
    }

    component SliderRow: Row {
        property string label: ""
        property string path: ""
        property real min: 0
        property real max: 1
        property real defaultValue: 0
        property int decimals: 0
        spacing: 12
        height: 36

        Text {
            text: label
            color: "#ccc"
            width: 120
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            id: sliderTrack
            width: 200
            height: 18
            radius: 9
            color: "#333"
            clip: true
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: {
                    var ratio = (Number(editor.tv(path, defaultValue)) - min) / (max - min);
                    return sliderTrack.width * Math.max(0, Math.min(1, ratio));
                }
                height: parent.height
                radius: 9
                color: "#00e5a0"
            }

            MouseArea {
                anchors.fill: parent
                preventStealing: true
                function update(mx) {
                    var ratio = Math.max(0, Math.min(1, mx / sliderTrack.width));
                    var raw = min + ratio * (max - min);
                    var v = decimals === 0 ? Math.round(raw) : Math.round(raw * Math.pow(10, decimals)) / Math.pow(10, decimals);
                    ThemeManager.setThemeProperty(path, v);
                }
                onPressed: mouse => update(mouse.x)
                onPositionChanged: mouse => {
                    if (pressed)
                        update(mouse.x);
                }
            }
        }

        Text {
            text: {
                var v = Number(editor.tv(path, defaultValue));
                if (isNaN(v))
                    v = defaultValue;
                return decimals === 0 ? Math.round(v).toString() : v.toFixed(decimals);
            }
            color: "#fff"
            width: 40
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    component ToggleRow: Row {
        property string label: ""
        property string path: ""
        property bool defaultValue: false
        spacing: 12
        height: 36

        Text {
            text: label
            color: "#ccc"
            width: 120
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 48
            height: 26
            radius: 13
            color: editor.tv(path, defaultValue) ? "#00e5a0" : "#444"
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: "#fff"
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: editor.tv(path, defaultValue) ? 24 : 3
                Behavior on anchors.leftMargin {
                    NumberAnimation {
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: ThemeManager.setThemeProperty(path, !editor.tv(path, defaultValue))
            }
        }
    }

    component SegmentedRow: Row {
        property string label: ""
        property string path: ""
        property var options: []
        property string defaultValue: ""
        spacing: 12
        height: 36

        Text {
            text: label
            color: "#ccc"
            width: 120
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            spacing: 0
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: options
                Rectangle {
                    property bool isFirst: index === 0
                    property bool isLast: index === options.length - 1
                    property bool active: editor.tv(path, defaultValue) === modelData

                    width: segText.implicitWidth + 20
                    height: 28
                    color: active ? "#00e5a0" : "#2a2a2a"
                    layer.enabled: true
                    layer.smooth: true

                    Rectangle {
                        anchors.fill: parent
                        radius: isFirst || isLast ? 7 : 0
                        color: active ? "#00e5a0" : "#2a2a2a"
                        border.color: "#555"
                        border.width: 1
                        Rectangle {
                            visible: isFirst && !isLast
                            anchors.right: parent.right
                            width: parent.radius
                            height: parent.height
                            color: parent.color
                        }
                        Rectangle {
                            visible: isLast && !isFirst
                            anchors.left: parent.left
                            width: parent.radius
                            height: parent.height
                            color: parent.color
                        }
                        Rectangle {
                            visible: !isFirst
                            anchors.left: parent.left
                            width: 1
                            height: parent.height
                            color: active ? "#00e5a0" : "#2a2a2a"
                        }
                    }

                    Text {
                        id: segText
                        anchors.centerIn: parent
                        text: modelData
                        color: active ? "#000" : "#aaa"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: ThemeManager.setThemeProperty(path, modelData)
                    }
                }
            }
        }
    }

    component TextRow: Row {
        property string label: ""
        property string path: ""
        property string defaultValue: ""
        spacing: 12
        height: 36

        Text {
            text: label
            color: "#ccc"
            width: 120
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 200
            height: 32
            radius: 8
            color: "#2a2a2a"
            border.color: "#444"
            anchors.verticalCenter: parent.verticalCenter
            TextInput {
                anchors.fill: parent
                anchors.margins: 6
                text: String(editor.tv(path, defaultValue))
                color: "#fff"
                font.pixelSize: 13
                onEditingFinished: ThemeManager.setThemeProperty(path, text)
            }
        }
    }

    component DropdownRow: Row {
        property string label: ""
        property string path: ""
        property var options: []
        property string defaultValue: ""
        spacing: 12
        height: 36

        Text {
            text: label
            color: "#ccc"
            width: 120
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 200
            height: 32
            radius: 8
            color: "#2a2a2a"
            border.color: "#444"
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: String(editor.tv(path, defaultValue))
                color: "#fff"
                font.pixelSize: 13
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "▼"
                color: "#888"
                font.pixelSize: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
            }

            MouseArea {
                anchors.fill: parent
                onClicked: optionsPopup.open(label, path, options, defaultValue)
            }
        }
    }
}
