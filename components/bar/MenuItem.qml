import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config

WrapperRectangle {
    id: root
    required property string icon
    property string fallbackIcon
    readonly property string resolvedIcon: fallbackIcon !== "" && !Quickshell.hasThemeIcon(icon) ? fallbackIcon : icon
    required property string label
    signal triggered

    Layout.fillWidth: true
    implicitHeight: 30
    radius: 6
    color: buttonArea.pressed ? "#d9d9d9" : buttonArea.containsMouse ? "#efefef" : "transparent"
    opacity: enabled ? 1 : 0.5

    WrapperMouseArea {
        id: buttonArea
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        margin: 6
        onClicked: root.triggered()
        RowLayout {
            IconImage {
                implicitSize: 16
                source: Quickshell.iconPath(root.resolvedIcon, true)
            }
            Text {
                Layout.fillWidth: true
                color: Theme.textPrimary
                text: root.label
            }
        }
    }
}
