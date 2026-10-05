pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Singleton {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property list<PwNode> sinks: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioSink)
    readonly property list<PwNode> sources: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioSource)
    readonly property list<PwNode> streams: Pipewire.nodes.values.filter(node => node.type === PwNodeType.AudioOutStream)
    readonly property bool ready: Pipewire.ready && sink?.audio != null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready && sink.audio.muted
    readonly property int percent: Math.round(volume * 100)
    property var portData: ({})

    function ports(node: PwNode): var {
        return portData[node?.name]?.ports ?? [];
    }

    function activePort(node: PwNode): var {
        return portData[node?.name]?.activePort ?? null;
    }

    function volumeIconName(node): string {
        const volume = node?.audio?.volume ?? 0;
        const prefix = node?.type === PwNodeType.AudioSource ? "microphone-sensitivity" : "audio-volume";
        const muted = node?.audio?.muted || volume <= 0;
        const level = muted ? "muted" : volume < 0.34 ? "low" : volume < 0.67 ? "medium" : "high";
        return `${prefix}-${level}-symbolic`;
    }

    function nodeIconName(node): string {
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

    function portIconName(port: var, node: PwNode): string {
        switch (port?.type) {
        case "Speaker": return "audio-speakers-symbolic";
        case "Headphones": return "audio-headphones-symbolic";
        case "Mic": return "audio-input-microphone-symbolic";
        case "HDMI": return "video-display-symbolic";
        default: return nodeIconName(node);
        }
    }

    function setVolume(value: real, node = root.sink) {
        if (node?.audio == null)
            return;
        const next = Math.min(1, Math.max(0, value));
        node.audio.volume = next;
        if (next > 0 && node.audio.muted)
            node.audio.muted = false;
    }

    function adjustVolume(delta: real, node = root.sink) {
        if (node?.audio == null)
            return;
        setVolume(node.audio.volume + delta, node);
    }

    function toggleMuted(node = root.sink) {
        if (node?.audio != null)
            node.audio.muted = !node.audio.muted;
    }

    function setDevice(node) {
        if (!node)
            return;
        if (node.type === PwNodeType.AudioSource)
            Pipewire.preferredDefaultAudioSource = node;
        else
            Pipewire.preferredDefaultAudioSink = node;
    }

    function selectDevice(node, port): bool {
        if (!node || port?.availability === "not available" || portSwitch.running)
            return false;
        if (!port || port.name === activePort(node)?.name) {
            setDevice(node);
            return true;
        }
        portSwitch.node = node;
        portSwitch.port = port.name;
        portSwitch.running = true;
        return true;
    }

    function refreshPorts() {
        if (portQuery.running) {
            portQuery.pending = true;
            return;
        }
        portQuery.running = true;
    }

    PwObjectTracker {
        objects: root.sinks.concat(root.sources, root.streams)
    }
    Process {
        id: portQuery
        property bool pending: false
        command: ["pactl", "--format=json", "list"]
        // qmllint disable incompatible-type
        environment: ({ LC_ALL: "C" })
        // qmllint enable incompatible-type
        stdout: StdioCollector { id: portOutput }
        stderr: StdioCollector { id: portErrors }
        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (pending) {
                pending = false;
                Qt.callLater(root.refreshPorts);
            }
            if (exitCode !== 0) {
                root.portData = {};
                console.warn("Audio ports query failed:", portErrors.text.trim());
                return;
            }
            const data = JSON.parse(portOutput.text);
            const result = data.sinks.concat(data.sources).reduce((result, device) => {
                result[device.name] = {
                    ports: device.ports,
                    activePort: device.ports.find(port => port.name === device.active_port) ?? null
                };
                return result;
            }, {});
            if (JSON.stringify(result) === JSON.stringify(root.portData))
                return;
            root.portData = result;
        }
        // qmllint enable signal-handler-parameters
    }
    Process {
        id: portSwitch
        property var node: null
        property string port
        command: ["pactl", node?.type === PwNodeType.AudioSource ? "set-source-port" : "set-sink-port", node?.name ?? "", port]
        stderr: StdioCollector { id: switchErrors }
        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("Audio port switch failed:", switchErrors.text.trim());
                return;
            }
            root.setDevice(node);
            root.refreshPorts();
        }
        // qmllint enable signal-handler-parameters
    }
    Process {
        id: portMonitor
        command: ["pactl", "subscribe"]
        // qmllint disable incompatible-type
        environment: ({ LC_ALL: "C" })
        // qmllint enable incompatible-type
        running: true
        onStarted: root.refreshPorts()
        stdout: SplitParser {
            onRead: line => {
                if (/ on (sink|source|card|server) #/.test(line))
                    portRefresh.restart();
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("Audio port monitor:", line)
        }
        // qmllint disable signal-handler-parameters
        onExited: {
            root.portData = {};
            portRefresh.stop();
            reconnect.restart();
        }
        // qmllint enable signal-handler-parameters
    }
    Timer {
        id: portRefresh
        interval: 150
        onTriggered: root.refreshPorts()
    }
    Timer {
        id: reconnect
        interval: 3000
        onTriggered: portMonitor.running = true
    }
}
