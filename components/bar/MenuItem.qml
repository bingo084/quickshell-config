import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.components
import qs.config

WrapperRectangle {
    id: root
    required property string icon
    required property string label
    signal triggered

    Layout.fillWidth: true
    implicitHeight: 30
    radius: 6
    color: buttonArea.pressed ? Theme.pressedBackground : buttonArea.containsMouse ? Theme.hoveredBackground : "transparent"
    opacity: enabled ? 1 : 0.5

    WrapperMouseArea {
        id: buttonArea
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        margin: 6
        onClicked: root.triggered()
        RowLayout {
            Icon {
                implicitSize: 16
                name: root.icon
            }
            Text {
                Layout.fillWidth: true
                color: Theme.textPrimary
                text: root.label
            }
        }
    }
}
