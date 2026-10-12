pragma Singleton
pragma ComponentBehavior: Bound

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
    property var updatedAt
    readonly property string error: [repoQuery.error, aurQuery.error].filter(Boolean).join("\n")

    function refresh() {
        if (repoQuery.running || aurQuery.running || updating)
            return;
        repoQuery.running = true;
        aurQuery.running = true;
    }

    function install() {
        if (!updateTerminal.running && !root.updating)
            updateTerminal.running = true;
    }

    function updateLevel(oldVersion: string, newVersion: string): string {
        const versions = [oldVersion, newVersion].map(version => version.match(/^(?:\d+:)?v?(\d{1,4})(?:[._](\d+))?(?=$|[._+~-]|alpha|beta|rc)/i));
        if (versions.some(version => version === null))
            return "normal";
        const [previous, next] = versions.map(version => [Number(version[1]), Number(version[2] || 0)]);
        if (next[0] > previous[0])
            return "major";
        if (next[0] === previous[0] && next[1] > previous[1])
            return "minor";
        return "normal";
    }

    Connections {
        target: Sleep

        function onResumed() {
            root.refresh();
        }
    }

    Connections {
        target: Network

        function onReady() {
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
        onExited: {
            if (root.updating) {
                root.updating = false;
                root.refresh();
            }
        }
    }

    component UpdateQuery: Process {
        id: query
        required property string sourceName
        required property int emptyExitCode
        property var packages: []
        property string error

        running: true

        stdout: StdioCollector {
            id: queryOutput
        }
        stderr: StdioCollector {
            id: queryErrors
        }
        onExited: exitCode => {
            const text = queryOutput.text.trim();
            const noUpdates = exitCode === query.emptyExitCode && text === "" && queryErrors.text.trim() === "";
            if (exitCode !== 0 && !noUpdates) {
                query.error = query.sourceName + " updates query failed (exit " + exitCode + "): " + queryErrors.text.trim();
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
            if (!repoQuery.running && !aurQuery.running && root.error === "")
                root.updatedAt = new Date();
        }
    }

    UpdateQuery {
        id: repoQuery
        sourceName: "Official"
        emptyExitCode: 2
        command: ["checkupdates", "--nocolor"]
    }

    UpdateQuery {
        id: aurQuery
        sourceName: "AUR"
        emptyExitCode: 1
        command: ["paru", "-Qua", "--color", "never"]
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
