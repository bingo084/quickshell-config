import QtQuick
import Quickshell
import qs.components
import qs.config

Button {
    id: root
    readonly property Region region: Region {
        item: root.visible && root.opacity > 0 ? root.background : null
        radius: background.radius
    }

    font.pixelSize: 12
    icon.width: 14
    icon.height: 14
    leftPadding: size > 0 ? padding : 10
    rightPadding: leftPadding
    verticalPadding: size > 0 ? padding : 4
    background: Rectangle {
        id: background
        radius: height / 2
        color: Qt.tint(Theme.background, root.down ? Theme.pressOverlay : root.hovered ? Theme.hoverOverlay : "transparent")
        border.width: 1
        border.color: root.visualFocus ? Theme.accent : Theme.border
    }
}
