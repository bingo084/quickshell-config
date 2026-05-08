pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioSink)
    readonly property var sources: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioSource)
    readonly property var streams: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioOutStream)
    readonly property bool ready: Pipewire.ready && sink?.audio != null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready && sink.audio.muted
    readonly property int percent: Math.round(volume * 100)

    function volumeIconName(node) {
        const volume = node?.audio?.volume ?? 0;
        const prefix = node?.type === PwNodeType.AudioSource ? "microphone-sensitivity" : "audio-volume";
        const muted = node?.audio?.muted || volume <= 0;
        const level = muted ? "muted" : volume < 0.34 ? "low" : volume < 0.67 ? "medium" : "high";
        return `${prefix}-${level}-symbolic`;
    }

    function nodeIconName(node) {
        const props = node?.properties ?? {};
        if (node?.type === PwNodeType.AudioOutStream)
            return props["application.icon-name"] || "application-x-executable-symbolic";
        if (props["device.api"] === "bluez5")
            return "audio-headset-symbolic";
        if (node?.type === PwNodeType.AudioSource)
            return props["device.icon-name"] || "audio-input-microphone-symbolic";
        if (node?.type === PwNodeType.AudioSink)
            return props["device.icon-name"] || "audio-card-symbolic";
        return "audio-card-symbolic";
    }

    function setSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setSource(node) {
        Pipewire.preferredDefaultAudioSource = node;
    }

    function setNodeVolume(node, value) {
        if (node?.audio == null)
            return;

        const next = Math.min(1, Math.max(0, value));
        node.audio.volume = next;
        if (next > 0 && node.audio.muted)
            node.audio.muted = false;
    }

    function toggleNodeMuted(node) {
        if (node?.audio != null)
            node.audio.muted = !node.audio.muted;
    }

    PwObjectTracker {
        objects: root.sinks.concat(root.sources, root.streams)
    }
}
