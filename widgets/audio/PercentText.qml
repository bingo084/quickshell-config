import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.config

Text {
    id: root
    required property PwNode node
    readonly property bool ready: node?.audio != null

    Layout.preferredWidth: metrics.advanceWidth
    horizontalAlignment: Text.AlignRight
    color: ready && node.audio.muted ? Theme.textSecondary : Theme.textPrimary
    text: ready ? Math.round(node.audio.volume * 100) + "%" : "--%"

    TextMetrics {
        id: metrics
        font: root.font
        text: "100%"
    }
}
