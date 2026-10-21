pragma Singleton

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string mode: awakeProcess.running ? "awake" : activeProcess.running ? "active" : "off"
    property int duration: 0
    property double expiresAt: 0
    property double now: Date.now()
    readonly property real remaining: expiresAt > 0 ? Math.max(0, (expiresAt - now) / 60000) : 0

    Component.onCompleted: {
        const state = JSON.parse(stateFile.text() || "{}");
        duration = state.duration ?? 0;
        expiresAt = state.expiresAt ?? 0;
        setMode(expiresAt > 0 && expiresAt <= now ? "off" : state.mode ?? "off");
    }

    function cycle() {
        const nextMode = mode === "off" ? "awake" : mode === "awake" ? "active" : "off";
        setMode(nextMode);
    }

    function setMode(nextMode: string) {
        awakeProcess.running = nextMode === "awake";
        activeProcess.running = nextMode === "active";
        if (nextMode === "off") {
            duration = 0;
            expiresAt = 0;
        }
        save(nextMode);
    }

    function setDuration(minutes: int) {
        if (mode === "off")
            return;
        now = Date.now();
        duration = minutes;
        expiresAt = minutes > 0 ? now + minutes * 60000 : 0;
        save();
    }

    function save(nextMode = mode) {
        stateFile.setText(JSON.stringify({
            mode: nextMode,
            duration,
            expiresAt
        }));
    }

    FileView {
        id: stateFile
        path: `${StandardPaths.writableLocation(StandardPaths.RuntimeLocation)}/quickshell/inhibit-${Quickshell.env("XDG_SESSION_ID")}.state`
        blockLoading: true
        blockWrites: true
        printErrors: false
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                console.warn("Could not read inhibitor state:", FileViewError.toString(error));
        }
        onSaveFailed: error => console.warn("Could not save inhibitor state:", FileViewError.toString(error))
    }

    Process {
        id: awakeProcess
        // Closing Quickshell's stdin pipe ends cat and releases the inhibitor.
        stdinEnabled: true
        command: ["systemd-inhibit", "--what=sleep", "--who=Quickshell", "--why=Manual sleep inhibit", "cat"]
        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim();
                if (message !== "")
                    console.warn("Awake inhibitor:", message);
            }
        }
    }

    Process {
        id: activeProcess
        stdinEnabled: true
        command: ["systemd-inhibit", "--what=idle:sleep", "--who=Quickshell", "--why=Manual idle and sleep inhibit", "cat"]
        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim();
                if (message !== "")
                    console.warn("Active inhibitor:", message);
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.mode !== "off" && root.expiresAt > 0
        onTriggered: {
            root.now = Date.now();
            if (root.expiresAt <= root.now)
                root.setMode("off");
        }
    }
}
