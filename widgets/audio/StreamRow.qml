import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.services

ColumnLayout {
    id: root
    required property PwNode node

    Layout.fillWidth: true
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        IconImage {
            implicitSize: 18
            source: Quickshell.iconPath(Audio.nodeIconName(root.node))
        }

        Text {
            Layout.fillWidth: true
            color: "#1a1a1a"
            elide: Text.ElideRight
            text: root.node.properties["application.name"] || root.node.name
        }

        PercentText {
            node: root.node
        }

        IconButton {
            icon: Audio.volumeIconName(root.node)
            checked: root.node.audio.muted
            subtle: true
            onClicked: Audio.toggleMuted(root.node)
        }
    }

    VolumeSlider {
        node: root.node
    }
}
