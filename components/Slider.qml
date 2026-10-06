import QtQuick
import QtQuick.Controls as Controls
import qs.config

Controls.Slider {
    id: root

    implicitWidth: 200
    implicitHeight: 24
    padding: 0
    wheelEnabled: true
    opacity: enabled ? 1 : 0.5
    palette.highlight: Theme.accent
    palette.mid: Theme.meterBackground

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    background: Rectangle {
        x: root.leftPadding + root.handle.width / 2
        y: root.topPadding + (root.availableHeight - height) / 2
        width: root.availableWidth - root.handle.width
        height: 6
        radius: height / 2
        color: root.palette.mid
        scale: root.mirrored ? -1 : 1
        Rectangle {
            width: root.position * parent.width
            height: parent.height
            radius: parent.radius
            color: root.palette.highlight
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2
        implicitWidth: 12
        implicitHeight: 12
        radius: width / 2
        scale: root.pressed ? 7 / 6 : 1
        color: root.palette.highlight
        border.width: root.visualFocus ? 2 : 0
        border.color: Theme.textPrimary
    }
}
