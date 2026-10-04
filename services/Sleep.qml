pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    signal resumed

    Process {
        id: monitor
        // Line-buffer stdout so infrequent wake signals are delivered promptly.
        command: ["stdbuf", "-oL", "gdbus", "monitor", "--system", "--dest", "org.freedesktop.login1", "--object-path", "/org/freedesktop/login1"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                // false ends the sleep cycle: resumed, failed or cancelled.
                if (line === "/org/freedesktop/login1: org.freedesktop.login1.Manager.PrepareForSleep (false,)")
                    root.resumed();
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("Sleep monitor:", line)
        }
        // qmllint disable signal-handler-parameters
        onExited: reconnect.restart()
        // qmllint enable signal-handler-parameters
    }

    Timer {
        id: reconnect
        interval: 3000
        onTriggered: monitor.running = true
    }
}
