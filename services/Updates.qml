pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var packages: []
    readonly property int count: packages.length
    readonly property bool checking: query.running
    property string error

    function refresh() {
        if (!query.running)
            query.running = true;
    }

    Process {
        id: query
        running: true
        command: ["checkupdates", "--nocolor"]
        stdout: StdioCollector {
            id: stdout
        }
        stderr: StdioCollector {
            id: stderr
        }
        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode !== 0 && exitCode !== 2) {
                root.error = "updates query failed (exit " + exitCode + "): " + stderr.text.trim();
                console.warn(root.error);
                return;
            }
            const packages = [];
            if (exitCode === 0) {
                const text = stdout.text.trim();
                const lines = text ? text.split("\n") : [];
                for (const line of lines) {
                    const fields = line.trim().split(/\s+/);
                    const [name, oldVersion, arrow, newVersion] = fields;
                    if (fields.length !== 4 || arrow !== "->") {
                        root.error = "Unexpected update entry: " + line;
                        console.warn(root.error);
                        return;
                    }
                    packages.push({
                        name,
                        oldVersion,
                        newVersion
                    });
                }
            }
            root.packages = packages;
            root.error = "";
        }
        // qmllint enable signal-handler-parameters
    }
    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
