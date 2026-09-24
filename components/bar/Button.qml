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
        color: Qt.darker(Theme.barItemBackground, root.pressed ? 1.08 : root.containsMouse ? 1.03 : 1.0)
        margin: 6
        leftMargin: root.horizontalPadding
        rightMargin: root.horizontalPadding
    }
}
