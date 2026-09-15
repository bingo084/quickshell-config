import QtQuick
import Quickshell
import Quickshell.Widgets

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
    color: checked ? "#eaf3ff" : buttonArea.pressed ? "#d9d9d9" : buttonArea.containsMouse ? "#efefef" : subtle ? "transparent" : "#f7f7f7"
    border.color: subtle && !buttonArea.containsMouse && !checked ? "transparent" : checked ? "#b7d7ff" : "#e1e1e1"
    border.width: 1

    WrapperMouseArea {
        id: buttonArea
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        margin: 4
        onClicked: root.clicked()

        IconImage {
            implicitSize: 16
            source: Quickshell.iconPath(root.icon, root.fallbackIcon)
        }
    }
}
