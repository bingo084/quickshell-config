pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Singleton {
    id: root
    property real uptime: -1

    function level(value: real, warning: real, critical: real): int {
        return value >= critical ? 2 : value >= warning ? 1 : 0;
    }

    function usageStats(history: var): var {
        const values = history.filter(point => point.value !== null).map(point => point.value);
        if (values.length === 0)
            return null;
        return {
            average: values.reduce((sum, value) => sum + value, 0) / values.length,
            peak: Math.max(...values)
        };
    }

    function record(history: var, values: var): var {
        const time = Date.now();
        return history.filter(point => point.time >= time - 60000).concat(Object.assign({
            time
        }, values));
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            const value = Number(uptimeFile.text().trim().split(/\s+/)[0] || NaN);
            root.uptime = Number.isFinite(value) && value >= 0 ? value : -1;
        }
        onLoadFailed: root.uptime = -1
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            uptimeFile.reload();
            root.cpu.refresh();
            root.gpu.refresh();
            root.memory.refresh();
            root.diskIo.refresh();
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.filesystem.refresh()
    }

    Connections {
        target: Sleep
        function onResumed() {
            uptimeFile.reload();
            root.cpu.resume();
            root.gpu.resume();
            root.memory.refresh();
            root.diskIo.resume();
        }
    }

    readonly property var cpu: Scope {
        id: cpuState
        property var info: null
        property real clock: -1
        property var loadAverage: []
        property real usage: -1
        readonly property bool valid: usage >= 0
        readonly property int level: valid ? root.level(usage, 0.5, 0.8) : 0
        property real temperature: NaN
        readonly property bool temperatureValid: Number.isFinite(temperature)
        readonly property int temperatureLevel: temperatureValid ? root.level(temperature, 70, 90) : 0
        property var history: []
        readonly property var stats: root.usageStats(history)

        Component.onCompleted: {
            readInfo();
            Command.run(["sh", "-c", `
                for sensor in /sys/class/hwmon/hwmon*; do
                    [ -r "$sensor/name" ] || continue
                    read -r name < "$sensor/name" || continue
                    [ "$name" = coretemp ] || continue
                    for label in "$sensor"/temp*_label; do
                        [ -r "$label" ] || continue
                        read -r name < "$label" || continue
                        [ "$name" = "Package id 0" ] || continue
                        input="\${label%_label}_input"
                        [ -r "$input" ] || continue
                        printf "%s\\n" "$input"
                        exit 0
                    done
                done
            `]).then(result => {
                if (result.exitCode !== 0)
                    throw new Error("exit " + result.exitCode + ": " + result.stderr.trim());
                cpuTemperatureFile.path = result.stdout.trim();
            }).catch(error => console.warn("CPU temperature discovery failed:", error.message));
        }

        function readInfo() {
            Command.run(["env", "LC_ALL=C", "lscpu", "--json", "--extended=MODELNAME,CORE,SOCKET"]).then(result => {
                if (result.exitCode !== 0)
                    throw new Error("exit " + result.exitCode + ": " + result.stderr.trim());
                const cpus = JSON.parse(result.stdout).cpus;
                if (cpus.length === 0)
                    throw new Error("No CPU information");
                const cores = new Set(cpus.filter(cpu => Number.isInteger(cpu.socket) && Number.isInteger(cpu.core)).map(cpu => `${cpu.socket}:${cpu.core}`));
                cpuState.info = {
                    model: [...new Set(cpus.map(cpu => cpu.modelname).filter(Boolean))].join(" / "),
                    cores: cores.size || null,
                    threads: cpus.length
                };
            }).catch(error => {
                cpuState.info = null;
                console.warn("CPU information query failed:", error.message);
            });
        }

        function sample(text: string) {
            const fields = text.split("\n", 1)[0].trim().split(/\s+/);
            const counters = fields.slice(1, 9).map(Number);
            if (fields[0] !== "cpu" || counters.length !== 8 || counters.some(value => !Number.isFinite(value) || value < 0)) {
                cpuFile.previous = null;
                usage = -1;
                return;
            }
            const current = {
                total: counters.reduce((sum, value) => sum + value, 0),
                idle: counters[3] + counters[4]
            };
            const previous = cpuFile.previous;
            cpuFile.previous = current;
            if (previous === null) {
                usage = -1;
                return;
            }
            const totalDelta = current.total - previous.total;
            const idleDelta = current.idle - previous.idle;
            usage = totalDelta > 0 && idleDelta >= 0 && idleDelta <= totalDelta ? (totalDelta - idleDelta) / totalDelta : -1;
        }

        function sampleClock(text: string) {
            const values = (text.match(/^cpu MHz\s*:\s*\d+(?:\.\d+)?$/gm) ?? []).map(line => Number(line.split(":")[1])).filter(value => value > 0);
            clock = values.length > 0 ? values.reduce((sum, value) => sum + value, 0) / values.length : -1;
        }

        function record() {
            history = root.record(history, {
                value: valid ? usage * 100 : null
            });
        }

        function refresh() {
            loadFile.reload();
            cpuFile.reload();
            cpuClockFile.reload();
            if (cpuTemperatureFile.path !== "")
                cpuTemperatureFile.reload();
        }

        function resume() {
            cpuFile.previous = null;
            history = [];
            usage = -1;
            loadFile.reload();
            cpuClockFile.reload();
            cpuFile.reload();
        }

        FileView {
            id: loadFile
            path: "/proc/loadavg"
            onLoaded: {
                const values = loadFile.text().trim().split(/\s+/).slice(0, 3).map(Number);
                cpuState.loadAverage = values.length === 3 && values.every(value => Number.isFinite(value) && value >= 0) ? values : [];
            }
            onLoadFailed: cpuState.loadAverage = []
        }

        FileView {
            id: cpuTemperatureFile
            onLoaded: {
                const value = Number(cpuTemperatureFile.text().trim() || NaN);
                cpuState.temperature = Number.isFinite(value) ? value / 1000 : NaN;
            }
            onLoadFailed: cpuState.temperature = NaN
        }

        FileView {
            id: cpuClockFile
            path: "/proc/cpuinfo"
            onLoaded: cpuState.sampleClock(cpuClockFile.text())
            onLoadFailed: cpuState.clock = -1
        }

        FileView {
            id: cpuFile
            property var previous: null
            path: "/proc/stat"
            onLoaded: {
                cpuState.sample(cpuFile.text());
                cpuState.record();
            }
            onLoadFailed: {
                previous = null;
                cpuState.usage = -1;
                cpuState.record();
            }
        }
    }

    readonly property var gpu: Scope {
        id: gpuState
        property string model
        property var sample: null
        readonly property real usage: (sample?.usage ?? 0) / 100
        readonly property bool valid: sample !== null && sample.usage !== null
        readonly property int level: valid ? root.level(usage, 0.5, 0.8) : 0
        readonly property real temperature: sample?.temperature ?? 0
        readonly property bool temperatureValid: sample !== null && sample.temperature !== null
        readonly property int temperatureLevel: temperatureValid ? root.level(temperature, 70, 90) : 0
        property var history: []
        readonly property var stats: root.usageStats(history)

        function parse(text: string) {
            const output = text.trim();
            if (output === "") {
                sample = null;
                return;
            }
            const fields = output.split(",").map(field => field.trim());
            if (fields.length !== 6) {
                sample = null;
                console.warn("Unexpected GPU query output:", output);
                return;
            }
            const values = fields.slice(1).map(field => {
                const value = Number(field || NaN);
                return Number.isFinite(value) && value >= 0 ? value : null;
            });
            const [usage, temperature, used, total, clock] = values;
            model = fields[0] || model;
            sample = {
                usage: usage !== null && usage <= 100 ? usage : null,
                temperature,
                memoryUsed: used !== null ? used * 1024 ** 2 : null,
                memoryTotal: total !== null && total > 0 ? total * 1024 ** 2 : null,
                clock
            };
        }

        function record() {
            history = root.record(history, {
                value: valid ? usage * 100 : null
            });
        }

        function refresh() {
            gpuQuery.run();
        }

        function resume() {
            sample = null;
            history = [];
            refresh();
        }

        Process {
            id: gpuQuery
            skipIfRunning: true
            running: true
            command: ["sh", "-c", `
                command -v nvidia-smi >/dev/null 2>&1 || exit 0
                for device in /sys/bus/pci/devices/*; do
                    read -r vendor < "$device/vendor" || continue
                    [ "$vendor" = 0x10de ] || continue
                    read -r class < "$device/class" || continue
                    case "$class" in 0x03*) ;; *) continue ;; esac
                    read -r state < "$device/power/runtime_status" || exit 0
                    [ "$state" = active ] || exit 0
                    exec nvidia-smi -i "\${device##*/}" --query-gpu=name,utilization.gpu,temperature.gpu,memory.used,memory.total,clocks.current.graphics --format=csv,noheader,nounits
                done
            `]
            stdout: StdioCollector {
                id: gpuOutput
            }
            stderr: StdioCollector {
                id: gpuErrors
            }
            onExited: exitCode => {
                if (exitCode === 0)
                    gpuState.parse(gpuOutput.text);
                else {
                    gpuState.sample = null;
                    console.warn("GPU query failed (exit " + exitCode + "):", gpuErrors.text.trim());
                }
                gpuState.record();
            }
        }
    }

    readonly property var memory: Scope {
        id: memoryState
        property var info: null
        property var sample: null
        property var swap: null
        readonly property bool valid: sample !== null
        readonly property real total: sample?.total ?? 0
        readonly property real used: sample?.used ?? 0
        readonly property real usage: valid ? used / total : 0
        readonly property int level: valid ? root.level(usage, 0.7, 0.9) : 0

        Component.onCompleted: readInfo()

        function readInfo() {
            Command.run(["udevadm", "info", "--query=all", "--path=/sys/devices/virtual/dmi/id", "--json=short"]).then(result => {
                if (result.exitCode !== 0)
                    throw new Error("exit " + result.exitCode + ": " + result.stderr.trim());
                const properties = JSON.parse(result.stdout);
                const slots = Object.keys(properties).filter(key => /^MEMORY_DEVICE_\d+_SIZE$/.test(key) && Number(properties[key]) > 0).map(key => key.slice(0, -5));
                memoryState.info = {
                    types: [...new Set(slots.map(slot => properties[slot + "_TYPE"]).filter(type => type && type !== "Unknown"))],
                    speeds: [...new Set(slots.map(slot => Number(properties[slot + "_CONFIGURED_SPEED_MTS"])).filter(speed => speed > 0))]
                };
            }).catch(error => {
                memoryState.info = null;
                console.warn("Memory information query failed:", error.message);
            });
        }

        function parse(text: string) {
            const total = Number(text.match(/^MemTotal:\s+(\d+)\s+kB$/m)?.[1]);
            const available = Number(text.match(/^MemAvailable:\s+(\d+)\s+kB$/m)?.[1]);
            sample = total > 0 && available >= 0 && available <= total ? {
                total: total * 1024,
                used: (total - available) * 1024
            } : null;
            const swapTotal = Number(text.match(/^SwapTotal:\s+(\d+)\s+kB$/m)?.[1]);
            const swapFree = Number(text.match(/^SwapFree:\s+(\d+)\s+kB$/m)?.[1]);
            swap = swapTotal >= 0 && swapFree >= 0 && swapFree <= swapTotal ? {
                total: swapTotal * 1024,
                used: (swapTotal - swapFree) * 1024
            } : null;
        }

        function refresh() {
            memoryFile.reload();
        }

        FileView {
            id: memoryFile
            path: "/proc/meminfo"
            onLoaded: memoryState.parse(memoryFile.text())
            onLoadFailed: {
                memoryState.sample = null;
                memoryState.swap = null;
            }
        }
    }

    readonly property var filesystem: Scope {
        id: filesystemState
        property var sample: null
        readonly property bool valid: sample !== null
        readonly property real total: sample?.total ?? 0
        readonly property real used: sample?.used ?? 0
        readonly property real available: sample?.available ?? 0
        readonly property real usage: valid ? used / total : 0
        readonly property int level: valid ? root.level(usage, 0.8, 0.9) : 0
        readonly property var info: {
            const devices = root.diskIo.info;
            const volume = devices.find(device => device.mountpoints?.includes("/"));
            if (!volume)
                return null;
            let disk = volume;
            while (disk.pkname) {
                const parent = devices.find(device => device.name === disk.pkname);
                if (!parent)
                    break;
                disk = parent;
            }
            return {
                device: volume.path,
                model: disk.model?.trim() ?? "",
                fstype: volume.fstype
            };
        }

        function refresh() {
            filesystemQuery.run();
        }

        function parse(text: string) {
            const values = text.trim().split("\n").slice(1).join(" ").trim().split(/\s+/).map(Number);
            const [total, used, available] = values;
            sample = values.length === 3 && values.every(Number.isFinite) && total > 0 && used >= 0 && used <= total && available <= total ? {
                total,
                used,
                available
            } : null;
            if (!valid)
                console.warn("Unexpected disk usage output:", text.trim());
        }

        Process {
            id: filesystemQuery
            skipIfRunning: true
            running: true
            command: ["df", "-B1", "--output=size,used,avail", "/"]
            stdout: StdioCollector {
                id: filesystemOutput
            }
            stderr: StdioCollector {
                id: filesystemErrors
            }
            onExited: exitCode => {
                if (exitCode !== 0) {
                    filesystemState.sample = null;
                    console.warn("disk usage query failed (exit " + exitCode + "):", filesystemErrors.text.trim());
                    return;
                }
                filesystemState.parse(filesystemOutput.text);
            }
        }
    }

    readonly property var diskIo: Scope {
        id: diskIoState
        property var info: []
        property var devices: []
        property var sample: null
        readonly property bool valid: sample !== null
        readonly property real readBps: sample?.read ?? 0
        readonly property real writeBps: sample?.write ?? 0
        property var history: []
        readonly property real peak: history.reduce((peak, point) => Math.max(peak, point.read ?? 0, point.write ?? 0), 0)

        Component.onCompleted: {
            readInfo();
            discover();
        }

        function readInfo() {
            Command.run(["lsblk", "--json", "--list", "--output", "NAME,PKNAME,PATH,MODEL,TRAN,FSTYPE,MOUNTPOINTS"]).then(result => {
                if (result.exitCode !== 0)
                    throw new Error("exit " + result.exitCode + ": " + result.stderr.trim());
                const devices = JSON.parse(result.stdout).blockdevices;
                diskIoState.info = devices;
            }).catch(error => {
                diskIoState.info = [];
                console.warn("Disk information query failed:", error.message);
            });
        }

        function discover() {
            Command.run(["sh", "-c", `
                for device in /sys/block/*; do
                    [ -e "$device/device" ] || continue
                    [ -r "$device/stat" ] || continue
                    printf "%s\\n" "\${device##*/}"
                done
            `]).then(result => {
                if (result.exitCode !== 0)
                    throw new Error("exit " + result.exitCode + ": " + result.stderr.trim());
                diskIoState.devices = result.stdout.trim().split("\n").filter(Boolean);
                diskIoFile.previous = null;
                diskIoFile.reload();
            }).catch(error => {
                diskIoState.devices = [];
                diskIoFile.previous = null;
                diskIoState.sample = null;
                console.warn("Disk discovery failed:", error.message);
            });
        }

        function parse(text: string) {
            const current = {};
            for (const line of text.trim().split("\n")) {
                const fields = line.trim().split(/\s+/);
                const name = fields[2];
                if (!devices.includes(name))
                    continue;
                const read = Number(fields[5]);
                const write = Number(fields[9]);
                if (!Number.isFinite(read) || !Number.isFinite(write) || read < 0 || write < 0)
                    continue;
                current[name] = {
                    read,
                    write
                };
            }
            if (Object.keys(current).length === 0) {
                diskIoFile.previous = null;
                sample = null;
                return;
            }
            const before = diskIoFile.previous;
            diskIoFile.previous = current;
            const seconds = diskSampleTimer.restart();
            if (before === null || seconds <= 0) {
                sample = null;
                return;
            }
            let readSectors = 0;
            let writeSectors = 0;
            let matched = 0;
            for (const name of Object.keys(current)) {
                const old = before[name];
                const after = current[name];
                if (old === undefined || after.read < old.read || after.write < old.write)
                    continue;
                readSectors += after.read - old.read;
                writeSectors += after.write - old.write;
                matched++;
            }
            sample = matched > 0 ? {
                read: readSectors * 512 / seconds,
                write: writeSectors * 512 / seconds
            } : null;
        }

        function record() {
            history = root.record(history, {
                read: valid ? readBps : null,
                write: valid ? writeBps : null
            });
        }

        function refresh() {
            diskIoFile.reload();
        }

        function resume() {
            diskIoFile.previous = null;
            history = [];
            sample = null;
            readInfo();
            discover();
        }

        ElapsedTimer {
            id: diskSampleTimer
        }

        FileView {
            id: diskIoFile
            property var previous: null
            path: "/proc/diskstats"
            onLoaded: {
                diskIoState.parse(diskIoFile.text());
                diskIoState.record();
            }
            onLoadFailed: {
                previous = null;
                diskIoState.sample = null;
                diskIoState.record();
            }
        }
    }
}
