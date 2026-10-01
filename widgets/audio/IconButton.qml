import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config

WrapperRectangle {
    id: root
    required property string icon
    property string fallbackIcon: icon
    property bool checked: false
    property bool subtle: false
    signal clicked

    implicitWidth: 26
    implicitHeight: 24
    radius: 5
    color: checked ? Theme.selectedBackground : buttonArea.pressed ? Theme.pressedBackground : buttonArea.containsMouse ? Theme.hoveredBackground : subtle ? "transparent" : Theme.controlBackground
    border.color: subtle && !buttonArea.containsMouse && !checked ? "transparent" : checked ? Theme.accent : Theme.popupBorder
    border.width: 1

    WrapperMouseArea {
        id: buttonArea
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        margin: 4
        onClicked: root.clicked()

        Icon {
            implicitSize: 16
            color: root.checked ? Theme.textOnSelected : Theme.textPrimary
            source: Quickshell.iconPath(root.icon, root.fallbackIcon)
        }
    }
}
