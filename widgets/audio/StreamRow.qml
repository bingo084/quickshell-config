import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import qs.components
import qs.config
import qs.services

ColumnLayout {
    id: root
    required property PwNode node

    Layout.fillWidth: true
    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Icon {
            colorize: false
            source: Quickshell.iconPath(Audio.nodeIconName(root.node))
        }
        Text {
            readonly property string appName: root.node.properties["application.name"] || root.node.name
            readonly property string mediaName: root.node.properties["media.name"] || ""

            Layout.fillWidth: true
            color: Theme.textPrimary
            elide: Text.ElideRight
            text: mediaName && mediaName !== appName ? appName + " · " + mediaName : appName
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6
        Button {
            icon.name: Audio.volumeIconName(root.node)
            checked: root.node.audio.muted
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
