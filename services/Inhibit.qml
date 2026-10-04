pragma Singleton

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string mode: sleepProcess.running ? "sleep" : idleProcess.running ? "idle" : "off"

    Component.onCompleted: setMode(stateFile.text().trim() || "off")

    function cycle() {
        const nextMode = mode === "off" ? "sleep" : mode === "sleep" ? "idle" : "off";
        setMode(nextMode);
    }

    function setMode(nextMode: string) {
        sleepProcess.running = nextMode === "sleep";
        idleProcess.running = nextMode === "idle";
        stateFile.setText(nextMode);
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
        id: sleepProcess
        // Closing Quickshell's stdin pipe ends cat and releases the inhibitor.
        stdinEnabled: true
        command: ["systemd-inhibit", "--what=sleep", "--who=Quickshell", "--why=Manual sleep inhibit", "cat"]
        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim();
                if (message !== "")
                    console.warn("Sleep inhibitor:", message);
            }
        }
    }
    Process {
        id: idleProcess
        stdinEnabled: true
        command: ["systemd-inhibit", "--what=idle", "--who=Quickshell", "--why=Manual idle inhibit", "cat"]
        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim();
                if (message !== "")
                    console.warn("Idle inhibitor:", message);
            }
        }
    }
}
