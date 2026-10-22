import QtQuick
import QtQuick.Controls as Controls
import qs.config

Controls.Switch {
    id: root

    spacing: 12
    opacity: enabled ? 1 : 0.5

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    indicator: Rectangle {
        implicitWidth: 36
        implicitHeight: 20
        x: root.width - root.rightPadding - width
        y: root.topPadding + (root.availableHeight - height) / 2
        radius: height / 2
        color: root.checked ? Theme.accent : Theme.meterBackground
        border.color: root.visualFocus ? Theme.accent : "transparent"

        Rectangle {
            x: 2 + root.visualPosition * (parent.width - width - 4)
            y: 2
            height: parent.height - 2 * y
            width: height
            radius: height / 2
            color: "#ffffff"
            border.width: 1
            border.color: Qt.alpha("#000000", 0.12)

            Behavior on x {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    contentItem: Text {
        text: root.text
        font: root.font
        color: Theme.textPrimary
        rightPadding: root.indicator.width + (root.text ? root.spacing : 0)
        verticalAlignment: Text.AlignVCenter
    }
}
