import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.services

WrapperRectangle {
    id: root
    required property var node
    signal clicked

    Layout.fillWidth: true
    implicitHeight: 28
    radius: 6
    color: deviceArea.pressed ? "#d9d9d9" : deviceArea.containsMouse ? "#efefef" : "transparent"

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
                color: "#1a1a1a"
                elide: Text.ElideRight
                text: root.node?.description || root.node?.nickname || root.node?.name || "Audio"
            }

            Text {
                Layout.maximumWidth: 90
                color: "#777777"
                font.pixelSize: 11
                elide: Text.ElideRight
                text: root.node.properties["device.profile.description"] || root.node.properties["media.class"] || ""
                visible: text !== ""
            }
        }
    }
}
