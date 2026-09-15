import QtQuick
import Quickshell.Widgets
import qs.config

WrapperRectangle {
    id: root
    property alias content: area.child
    property alias acceptedButtons: area.acceptedButtons
    signal clicked(var mouse)
    signal wheel(var wheel)

    radius: Theme.barItemRadius
    color: Qt.darker(Theme.barItemBackground, area.pressed ? 1.08 : area.containsMouse ? 1.03 : 1.0)

    WrapperMouseArea {
        id: area
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        margin: 6
        onClicked: mouse => root.clicked(mouse)
        onWheel: wheel => root.wheel(wheel)
    }
}
