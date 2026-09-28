pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property real cpuUsage
    property bool cpuValid
    property var previousCpu: null
    property real memoryTotal
    property real memoryUsed
    property real memoryUsage
    property bool memoryValid
    property real diskTotal
    property real diskUsed
    property real diskAvailable
    property bool diskValid

    function sampleCpu(text: string) {
        const fields = text.split("\n", 1)[0].trim().split(/\s+/);
        const counters = fields.slice(1, 9).map(Number);
        if (fields[0] !== "cpu" || counters.length !== 8 || counters.some(value => !Number.isFinite(value) || value < 0)) {
            root.previousCpu = null;
            root.cpuValid = false;
            return;
        }

        const current = {
            total: counters.reduce((sum, value) => sum + value, 0),
            idle: counters[3] + counters[4]
        };
        const previous = root.previousCpu;
        root.previousCpu = current;

        if (previous === null) {
            root.cpuValid = false;
            return;
        }

        const totalDelta = current.total - previous.total;
        const idleDelta = current.idle - previous.idle;
        root.cpuValid = totalDelta > 0 && idleDelta >= 0 && idleDelta <= totalDelta;
        if (root.cpuValid)
            root.cpuUsage = (totalDelta - idleDelta) / totalDelta;
    }

    function sampleMemory(text: string) {
        const total = Number(text.match(/^MemTotal:\s+(\d+)\s+kB$/m)?.[1]);
        const available = Number(text.match(/^MemAvailable:\s+(\d+)\s+kB$/m)?.[1]);
        root.memoryValid = total > 0 && available >= 0 && available <= total;
        if (root.memoryValid) {
            root.memoryTotal = total * 1024;
            root.memoryUsed = (total - available) * 1024;
            root.memoryUsage = (total - available) / total;
        }
    }

    FileView {
        id: cpuFile
        path: "/proc/stat"
        onLoaded: root.sampleCpu(cpuFile.text())
        onLoadFailed: {
            root.previousCpu = null;
            root.cpuValid = false;
        }
    }
    FileView {
        id: memoryFile
        path: "/proc/meminfo"
        onLoaded: root.sampleMemory(memoryFile.text())
        onLoadFailed: root.memoryValid = false
    }
    Process {
        id: diskProcess
        running: true
        command: ["df", "-B1", "--output=size,used,avail", "/"]
        stdout: StdioCollector {
            id: diskOutput
        }
        stderr: StdioCollector {
            id: diskError
        }
        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.diskValid = false;
                console.warn("disk usage query failed (exit " + exitCode + "):", diskError.text.trim());
                return;
            }

            const fields = diskOutput.text.trim().split("\n").slice(1).join(" ").trim().split(/\s+/);
            const values = fields.map(Number);
            const [total, used, available] = values;
            root.diskValid = values.length === 3 && values.every(Number.isFinite)
                && total > 0 && used >= 0 && used <= total && available <= total;
            if (!root.diskValid) {
                console.warn("Unexpected disk usage output:", diskOutput.text.trim());
                return;
            }

            root.diskTotal = total;
            root.diskUsed = used;
            root.diskAvailable = available;
        }
        // qmllint enable signal-handler-parameters
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuFile.reload();
            memoryFile.reload();
        }
    }
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            if (!diskProcess.running)
                diskProcess.running = true;
        }
    }
}
