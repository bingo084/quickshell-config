pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.config

WrapperMouseArea {
    id: root
    required property var metric
    implicitHeight: 136
    cursorShape: Qt.PointingHandCursor

    WrapperRectangle {
        margin: 12
        radius: 6
        color: Theme.barBackground
        ColumnLayout {
            spacing: 6

            RowLayout {
                Text {
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                    font.weight: Font.Medium
                    text: root.metric.title
                }
                Text {
                    visible: root.metric.readings.length === 0
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    text: root.metric.value
                }
            }

            RowLayout {
                visible: root.metric.readings.length > 0
                Repeater {
                    model: root.metric.readings
                    Text {
                        required property string modelData
                        Layout.fillWidth: true
                        color: Theme.textSecondary
                        font.pixelSize: 10
                        text: modelData
                    }
                }
            }

            Trend {
                Layout.fillWidth: true
                Layout.fillHeight: true
                series: root.metric.series
                maximum: root.metric.maximum ?? 100
            }

            RowLayout {
                Text {
                    Layout.fillWidth: true
                    color: Theme.textSecondary
                    font.pixelSize: 9
                    text: "−60s"
                }
                Text {
                    color: Theme.textSecondary
                    font.pixelSize: 9
                    text: "Now"
                }
            }
        }
    }
}
