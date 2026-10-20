import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

WrapperItem {
    id: root
    required property PwNode node
    required property int controlSize
    property VolumeScroll wheelArea
    readonly property bool ready: node?.audio != null

    Layout.fillWidth: true
    leftMargin: 6
    rightMargin: leftMargin + muteButton.padding

    RowLayout {
        spacing: 0

        Button {
            id: muteButton
            iconName: Audio.volumeIconName(root.node)
            icon.width: 18
            icon.height: 18
            padding: (root.controlSize - icon.width) / 2
            horizontalPadding: padding
            enabled: root.ready
            checked: root.node?.audio?.muted ?? false
            onClicked: Audio.toggleMuted(root.node)
        }
        Slider {
            id: slider
            Layout.fillWidth: true
            enabled: root.ready
            wheelEnabled: !root.wheelArea || !root.wheelArea.wheelLocked || root.wheelArea.wheelOwner === slider
            value: root.ready ? root.node.audio.volume : 0
            stepSize: 0.01
            palette.highlight: root.ready && root.node.audio.muted ? Theme.textSecondary : Theme.accent
            onMoved: Audio.setVolume(value, root.node)

            WheelHandler {
                enabled: root.wheelArea !== null
                target: null
                blocking: false
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    root.wheelArea.beginWheel(slider);
                    event.accepted = root.wheelArea.wheelOwner !== null && root.wheelArea.wheelOwner !== slider;
                }
            }
        }
        Text {
            id: percent
            Layout.leftMargin: 6
            Layout.preferredWidth: Math.ceil(metrics.advanceWidth)
            horizontalAlignment: Text.AlignRight
            color: root.ready && root.node.audio.muted ? Theme.textSecondary : Theme.textPrimary
            text: root.ready ? Math.round(root.node.audio.volume * 100) + "%" : "--%"
            font.pixelSize: 13

            TextMetrics {
                id: metrics
                font: percent.font
                text: "100%"
            }
        }
    }
}
