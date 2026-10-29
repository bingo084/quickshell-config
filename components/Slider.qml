import QtQuick
import QtQuick.Controls as Controls
import qs.config

Controls.Slider {
    id: root
    property real displayedPosition: position
    property real trackHeight: 6
    property real handleOpacity: 1

    implicitWidth: 200
    implicitHeight: 24
    padding: 0
    wheelEnabled: true
    opacity: enabled ? 1 : 0.5
    palette.highlight: Theme.accent
    palette.mid: Theme.trackBackground

    Behavior on displayedPosition {
        enabled: !root.pressed
        NumberAnimation {
            duration: 120
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    background: Rectangle {
        x: root.leftPadding + root.handle.width / 2
        y: root.topPadding + (root.availableHeight - height) / 2
        width: root.availableWidth - root.handle.width
        height: root.trackHeight
        radius: height / 2
        color: root.palette.mid
        scale: root.mirrored ? -1 : 1
        Rectangle {
            width: root.displayedPosition * parent.width
            height: parent.height
            radius: parent.radius
            color: root.palette.highlight
        }
    }

    handle: Rectangle {
        x: root.leftPadding + (root.mirrored ? 1 - root.displayedPosition : root.displayedPosition) * (root.availableWidth - width)
        y: root.topPadding + (root.availableHeight - height) / 2
        implicitWidth: 12
        implicitHeight: 12
        radius: width / 2
        scale: root.pressed ? 7 / 6 : 1
        opacity: root.handleOpacity
        color: Theme.handleBackground
        border.width: root.visualFocus ? 2 : 1
        border.color: root.visualFocus ? Theme.accent : Theme.handleBorder
    }
}
