import QtQuick

Text {
    required property var node
    readonly property bool ready: node?.audio != null

    color: ready && node.audio.muted ? "#777777" : "#1a1a1a"
    text: ready ? Math.round(node.audio.volume * 100) + "%" : "--%"
}
