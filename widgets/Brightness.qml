import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.components
import qs.components.bar
import qs.services

Button {
    id: root
    required property ShellScreen screen

    visible: Brightness.available && root.screen?.name === Brightness.output
    onClicked: popup.toggle()
    onWheel: event => {
        if (event.angleDelta.y > 0) {
            Brightness.change(1);
        } else if (event.angleDelta.y < 0) {
            Brightness.change(-1);
        }
    }

    content: RowLayout {
        spacing: 4
        Icon {
            id: brightnessIcon
            readonly property string strength: Brightness.level < 1 / 3 ? "low" : Brightness.level < 2 / 3 ? "medium" : "high"
            name: `display-brightness-${strength}-symbolic`
        }
        Text {
            color: Theme.textPrimary
            text: Math.round(Brightness.level * 100) + "%"
        }
    }

    Popup {
        id: popup
        anchorItem: root
        contentWidth: 280

        ColumnLayout {
            spacing: 8

            Text {
                Layout.leftMargin: 6
                text: "Brightness"
                color: Theme.textPrimary
                font.pixelSize: 14
                font.bold: true
            }

            RowLayout {
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                spacing: 0

                Icon {
                    size: 32
                    name: brightnessIcon.name
                }

                Slider {
                    Layout.fillWidth: true
                    from: Brightness.minimumLevel
                    value: Brightness.level
                    onMoved: Brightness.setLevel(value)
                }

                Text {
                    id: percent
                    Layout.leftMargin: 6
                    Layout.preferredWidth: Math.ceil(metrics.advanceWidth)
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Brightness.level * 100) + "%"
                    color: Theme.textPrimary
                    font.pixelSize: 13

                    TextMetrics {
                        id: metrics
                        font: percent.font
                        text: "100%"
                    }
                }
            }
        }
    }
}
