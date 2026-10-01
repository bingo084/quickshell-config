import QtQuick
import Quickshell.Services.Pipewire
import qs.config

Text {
    required property PwNode node
    readonly property bool ready: node?.audio != null

    color: ready && node.audio.muted ? Theme.textSecondary : Theme.textPrimary
    text: ready ? Math.round(node.audio.volume * 100) + "%" : "--%"
}
