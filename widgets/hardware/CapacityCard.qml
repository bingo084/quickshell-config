import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config

WrapperMouseArea {
    id: root
    required property var metric

    cursorShape: Qt.PointingHandCursor

    WrapperRectangle {
        margin: 12
        radius: 6
        color: Theme.barBackground
        ColumnLayout {
            spacing: 8

            Text {
                color: Theme.textPrimary
                font.weight: Font.Medium
                text: root.metric.title
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 12

                Ring {
                    fraction: root.metric.fraction
                    valid: root.metric.valid
                    level: root.metric.level
                }

                ColumnLayout {
                    spacing: 4

                    Text {
                        color: [Theme.textPrimary, Theme.warning, Theme.critical][root.metric.level]
                        font.pixelSize: 13
                        text: root.metric.value
                    }

                    Text {
                        color: Theme.textSecondary
                        font.pixelSize: 11
                        text: root.metric.available
                    }
                }
            }
        }
    }
}
