import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

ColumnLayout {
    id: root
    required property PwNode node
    required property bool expanded
    property bool expandable: true
    signal toggleExpanded

    Layout.fillWidth: true
    spacing: 4

    WrapperRectangle {
        Layout.fillWidth: true
        implicitHeight: 28
        radius: 6
        color: {
            if (!root.expandable)
                return "transparent";
            const background = root.expanded ? Theme.selectedBackground : Theme.meterBackground;
            const overlay = deviceArea.pressed ? Theme.pressedBackground : deviceArea.containsMouse ? Theme.hoveredBackground : "transparent";
            return Qt.tint(background, overlay);
        }
        border.color: !root.expandable ? "transparent" : root.expanded ? Theme.accent : Theme.popupBorder

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
                    color: root.expanded ? Theme.textOnSelected : Theme.textPrimary
                    elide: Text.ElideRight
                    text: [root.node?.description || root.node?.nickname || root.node?.name || "Audio", Audio.activePort(root.node)?.description].filter(Boolean).join(" · ")
                }
                Icon {
                    implicitSize: 14
                    color: root.expanded ? Theme.textOnSelected : Theme.textPrimary
                    visible: root.expandable
                    source: Quickshell.iconPath(root.expanded ? "pan-up-symbolic" : "pan-down-symbolic")
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Button {
            icon.name: Audio.volumeIconName(root.node)
            checked: root.node?.audio?.muted ?? false
            flat: true
            onClicked: Audio.toggleMuted(root.node)
        }
        VolumeSlider {
            node: root.node
        }
        PercentText {
            node: root.node
        }
    }
}
