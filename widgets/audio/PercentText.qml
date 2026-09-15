import QtQuick
import Quickshell.Services.Pipewire

Text {
    required property PwNode node
    readonly property bool ready: node?.audio != null

    color: ready && node.audio.muted ? "#777777" : "#1a1a1a"
    text: ready ? Math.round(node.audio.volume * 100) + "%" : "--%"
}
