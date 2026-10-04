pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    readonly property var packages: repoQuery.packages.concat(aurQuery.packages)
    readonly property int count: packages.length
    readonly property bool checking: repoQuery.running || aurQuery.running
    property bool updating: false
    readonly property string error: [repoQuery.error, aurQuery.error].filter(Boolean).join("\n")

    function refresh() {
        if (!repoQuery.running)
            repoQuery.running = true;
        if (!aurQuery.running)
            aurQuery.running = true;
    }

    function install() {
        if (!updateTerminal.running && !root.updating)
            updateTerminal.running = true;
    }

    Connections {
        target: Sleep
        function onResumed() {
            root.refresh();
        }
    }
    IpcHandler {
        target: "updates"

        function begin(): void {
            root.updating = true;
        }

        function end(): void {
            root.updating = false;
            root.refresh();
        }
    }
    Process {
        id: updateTerminal
        command: ["kitty", "--title", "System update", "zsh", "-ic", "paru; update_exit=$?; printf '\\nPress Enter to close...'; read -r; exit $update_exit"]
        // qmllint disable signal-handler-parameters
        onExited: {
            if (root.updating) {
                root.updating = false;
                root.refresh();
            }
        }
        // qmllint enable signal-handler-parameters
    }

    component UpdateQuery: Process {
        id: query
        required property string sourceName
        required property int emptyExitCode
        property var packages: []
        property string error
        stdout: StdioCollector {
            id: stdout
        }
        stderr: StdioCollector {
            id: stderr
        }
        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            const text = stdout.text.trim();
            const noUpdates = exitCode === query.emptyExitCode && text === "" && stderr.text.trim() === "";
            if (exitCode !== 0 && !noUpdates) {
                query.error = query.sourceName + " updates query failed (exit " + exitCode + "): " + stderr.text.trim();
                console.warn(query.error);
                return;
            }
            const packages = [];
            if (exitCode === 0) {
                const lines = text ? text.split("\n") : [];
                for (const line of lines) {
                    if (line.trim().endsWith(" [ignored]"))
                        continue;
                    const fields = line.trim().split(/\s+/);
                    const [name, oldVersion, arrow, newVersion] = fields;
                    if (fields.length !== 4 || arrow !== "->") {
                        query.error = query.sourceName + " unexpected update entry: " + line;
                        console.warn(query.error);
                        return;
                    }
                    packages.push({
                        name,
                        oldVersion,
                        newVersion,
                        source: query.sourceName
                    });
                }
            }
            query.packages = packages;
            query.error = "";
        }
        // qmllint enable signal-handler-parameters
    }

    UpdateQuery {
        id: repoQuery
        sourceName: "Official"
        emptyExitCode: 2
        running: true
        command: ["checkupdates", "--nocolor"]
    }
    UpdateQuery {
        id: aurQuery
        sourceName: "AUR"
        emptyExitCode: 1
        running: true
        command: ["paru", "-Qua", "--color", "never"]
    }
    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
