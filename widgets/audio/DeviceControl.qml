import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.services

ColumnLayout {
    id: root
    required property PwNode node
    required property bool expanded
    property bool expandable: true
    signal toggleExpanded

    Layout.fillWidth: true
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        IconButton {
            icon: Audio.volumeIconName(root.node)
            checked: root.node?.audio?.muted ?? false
            onClicked: Audio.toggleMuted(root.node)
        }

        WrapperRectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 6
            color: root.expanded ? "#eaf3ff" : deviceArea.pressed ? "#d9d9d9" : deviceArea.containsMouse ? "#efefef" : "transparent"

            WrapperMouseArea {
                id: deviceArea
                hoverEnabled: root.expandable
                cursorShape: root.expandable ? Qt.PointingHandCursor : Qt.ArrowCursor
                margin: 6
                onClicked: {
                    if (root.expandable)
                        root.toggleExpanded();
                }

                RowLayout {
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        color: "#1a1a1a"
                        elide: Text.ElideRight
                        text: root.node?.description || root.node?.nickname || root.node?.name || "Audio"
                    }

                    PercentText {
                        node: root.node
                    }

                    IconImage {
                        implicitSize: 14
                        visible: root.expandable
                        source: Quickshell.iconPath(root.expanded ? "pan-up-symbolic" : "pan-down-symbolic")
                    }
                }
            }
        }
    }

    VolumeSlider {
        node: root.node
    }
}
