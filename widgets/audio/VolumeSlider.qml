import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.components
import qs.config
import qs.services

Slider {
    id: root
    required property PwNode node
    readonly property bool ready: node?.audio != null

    Layout.fillWidth: true
    enabled: ready
    value: ready ? node.audio.volume : 0
    stepSize: 0.01
    palette.highlight: ready && node.audio.muted ? Theme.textSecondary : Theme.accent
    onMoved: Audio.setVolume(value, node)
}
