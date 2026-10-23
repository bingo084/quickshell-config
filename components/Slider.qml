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
    palette.mid: Theme.trackBackground

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
        color: Theme.handleBackground
        border.width: root.visualFocus ? 2 : 1
        border.color: root.visualFocus ? Theme.accent : Qt.alpha("#000000", 0.18)
    }
}
