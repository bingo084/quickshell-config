import QtQuick
import Quickshell.Services.Pipewire
import qs.config

Text {
    required property PwNode node
    property bool selected: false
    readonly property bool ready: node?.audio != null

    color: selected ? Theme.textOnSelected : ready && node.audio.muted ? Theme.textSecondary : Theme.textPrimary
    text: ready ? Math.round(node.audio.volume * 100) + "%" : "--%"
}
