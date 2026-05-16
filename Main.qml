import QtQuick
import QtQuick.Window

Window {
    width: 900
    height: 400
    visible: true
    title: "Kiraboard"

    property var t: ThemeManager.theme

    Rectangle {
        anchors.fill: parent
        color: t.visual.background
    }

    // =========================
    // CENTERED KEYBOARD AREA
    // =========================

    Column {
        id: keyboard

        anchors.centerIn: parent

        spacing: t.layout.rowSpacing

        // =====================
        // FIRST ROW
        // =====================

        Row {
            spacing: t.layout.keySpacing

            Repeater {
                model: ["Q","W","E","R","T","Y","U","I","O","P"]

                KeyButton {
                    label: modelData

                    onKeyPressed: function(key) {
                        console.log("Pressed:", key)
                    }
                }
            }
        }

        // =====================
        // SECOND ROW
        // =====================

        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            spacing: t.layout.keySpacing

            Repeater {
                model: ["A","S","D","F","G","H","J","K","L"]

                KeyButton {
                    label: modelData
                }
            }
        }

        // =====================
        // THIRD ROW
        // =====================

        Row {
            anchors.horizontalCenter: parent.horizontalCenter

            spacing: t.layout.keySpacing

            Repeater {
                model: ["Z","X","C","V","B","N","M"]

                KeyButton {
                    label: modelData
                }
            }
        }
    }
}