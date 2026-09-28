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
    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            cpuFile.reload();
            memoryFile.reload();
        }
    }
}
