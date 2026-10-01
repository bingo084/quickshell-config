import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.config
import qs.services

WrapperRectangle {
    id: root
    required property PwNode node
    signal clicked

    Layout.fillWidth: true
    implicitHeight: 28
    radius: 6
    color: deviceArea.pressed ? Theme.pressedBackground : deviceArea.containsMouse ? Theme.hoveredBackground : "transparent"

    WrapperMouseArea {
        id: deviceArea
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        margin: 6
        onClicked: root.clicked()

        RowLayout {
            spacing: 6

            IconImage {
                implicitSize: 18
                source: Quickshell.iconPath(Audio.nodeIconName(root.node))
            }

            Text {
                Layout.fillWidth: true
                color: Theme.textPrimary
                elide: Text.ElideRight
                text: root.node?.description || root.node?.nickname || root.node?.name || "Audio"
            }

            Text {
                Layout.maximumWidth: 90
                color: Theme.textSecondary
                font.pixelSize: 11
                elide: Text.ElideRight
                text: root.node.properties["device.profile.description"] || root.node.properties["media.class"] || ""
                visible: text !== ""
            }
        }
    }
}
