import QtQuick
import Quickshell.Widgets
import qs.config

WrapperMouseArea {
    id: root
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    property alias content: background.child
    property int horizontalPadding: 6

    WrapperRectangle {
        id: background
        radius: Theme.barItemRadius
        color: root.pressed ? Theme.pressedBackground : root.containsMouse ? Theme.hoveredBackground : "transparent"
        margin: 6
        leftMargin: root.horizontalPadding
        rightMargin: root.horizontalPadding
    }
}
