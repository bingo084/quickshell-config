pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string mode: sleepProcess.running ? "sleep" : idleProcess.running ? "idle" : "off"

    function cycle() {
        const nextMode = mode === "off" ? "sleep" : mode === "sleep" ? "idle" : "off";
        sleepProcess.running = nextMode === "sleep";
        idleProcess.running = nextMode === "idle";
    }

    Process {
        id: sleepProcess
        command: ["systemd-inhibit", "--what=sleep", "--who=Quickshell", "--why=Manual sleep inhibit", "sleep", "infinity"]
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
        command: ["systemd-inhibit", "--what=idle", "--who=Quickshell", "--why=Manual idle inhibit", "sleep", "infinity"]
        stderr: StdioCollector {
            onStreamFinished: {
                const message = text.trim();
                if (message !== "")
                    console.warn("Idle inhibitor:", message);
            }
        }
    }
}
