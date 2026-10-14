pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.components

Singleton {
    id: root
    property real uptime: -1
    property var cpuInfo: null
    property real cpuClock: -1
    property var loadAverage: []
    property real cpuUsage
    property bool cpuValid
    property var previousCpu: null
    property var cpuHistory: []
    readonly property var cpuStats: usageStats(cpuHistory)
    property string cpuTemperaturePath
    property real cpuTemperature
    property bool cpuTemperatureValid
    property string gpuModel
    property var gpuInfo: null
    readonly property real gpuUsage: (gpuInfo?.usage ?? 0) / 100
    readonly property bool gpuValid: gpuInfo !== null && gpuInfo.usage !== null
    readonly property real gpuTemperature: gpuInfo?.temperature ?? 0
    readonly property bool gpuTemperatureValid: gpuInfo !== null && gpuInfo.temperature !== null
    property var gpuHistory: []
    readonly property var gpuStats: usageStats(gpuHistory)
    property real memoryTotal
    property real memoryUsed
    property real memoryUsage
    property bool memoryValid
    property var swap
    property real diskTotal
    property real diskUsed
    property real diskAvailable
    property bool diskValid
    property var diskInfo: []
    property var rootFilesystem: null
    property var diskDevices: []
    property real diskReadBps
    property real diskWriteBps
    property bool diskIoValid
    property var previousDisk: null
    property var diskHistory: []
    readonly property real diskPeak: diskHistory.reduce((peak, point) => Math.max(peak, point.read ?? 0, point.write ?? 0), 0)

    Component.onCompleted: {
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
            root.cpuTemperaturePath = result.stdout.trim();
        }).catch(error => console.warn("CPU temperature discovery failed:", error.message));
        root.readCpuInfo();
        root.readDiskInfo();
        root.discoverDisks();
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

    function readCpuInfo() {
        Command.run(["env", "LC_ALL=C", "lscpu", "--json", "--extended=MODELNAME,CORE,SOCKET"]).then(result => {
            if (result.exitCode !== 0)
                throw new Error("exit " + result.exitCode + ": " + result.stderr.trim());
            const cpus = JSON.parse(result.stdout).cpus;
            if (cpus.length === 0)
                throw new Error("No CPU information");
            const cores = new Set(cpus.filter(cpu => Number.isInteger(cpu.socket) && Number.isInteger(cpu.core)).map(cpu => `${cpu.socket}:${cpu.core}`));
            root.cpuInfo = {
                model: [...new Set(cpus.map(cpu => cpu.modelname).filter(Boolean))].join(" / "),
                cores: cores.size || null,
                threads: cpus.length
            };
        }).catch(error => {
            root.cpuInfo = null;
            console.warn("CPU information query failed:", error.message);
        });
    }

    function readDiskInfo() {
        Command.run(["lsblk", "--json", "--list", "--output", "NAME,PKNAME,PATH,MODEL,TRAN,FSTYPE,MOUNTPOINTS"]).then(result => {
            if (result.exitCode !== 0)
                throw new Error("exit " + result.exitCode + ": " + result.stderr.trim());
            const devices = JSON.parse(result.stdout).blockdevices;
            root.diskInfo = devices;
            const volume = devices.find(device => device.mountpoints?.includes("/"));
            if (!volume) {
                root.rootFilesystem = null;
                return;
            }
            let disk = volume;
            while (disk.pkname) {
                const parent = devices.find(device => device.name === disk.pkname);
                if (!parent)
                    break;
                disk = parent;
            }
            root.rootFilesystem = {
                device: volume.path,
                model: disk.model?.trim() ?? "",
                fstype: volume.fstype
            };
        }).catch(error => {
            root.diskInfo = [];
            root.rootFilesystem = null;
            console.warn("Disk information query failed:", error.message);
        });
    }

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

    function sampleCpuClock(text: string) {
        const values = (text.match(/^cpu MHz\s*:\s*\d+(?:\.\d+)?$/gm) ?? []).map(line => Number(line.split(":")[1])).filter(value => value > 0);
        cpuClock = values.length > 0 ? values.reduce((sum, value) => sum + value, 0) / values.length : -1;
    }

    function recordCpu() {
        const time = Date.now();
        cpuHistory = cpuHistory.filter(point => point.time >= time - 60000).concat({
            time,
            value: cpuValid ? cpuUsage * 100 : null
        });
    }

    function sampleGpu(text: string) {
        const output = text.trim();
        if (output === "") {
            gpuInfo = null;
            return;
        }
        const fields = output.split(",").map(field => field.trim());
        if (fields.length !== 6) {
            gpuInfo = null;
            console.warn("Unexpected GPU query output:", output);
            return;
        }
        const values = fields.slice(1).map(field => {
            const value = Number(field || NaN);
            return Number.isFinite(value) && value >= 0 ? value : null;
        });
        const [usage, temperature, used, total, clock] = values;
        gpuModel = fields[0] || gpuModel;
        gpuInfo = {
            usage: usage !== null && usage <= 100 ? usage : null,
            temperature,
            memoryUsed: used !== null ? used * 1024 ** 2 : null,
            memoryTotal: total !== null && total > 0 ? total * 1024 ** 2 : null,
            clock
        };
    }

    function recordGpu() {
        const time = Date.now();
        gpuHistory = gpuHistory.filter(point => point.time >= time - 60000).concat({
            time,
            value: gpuValid ? gpuUsage * 100 : null
        });
    }

    function discoverDisks() {
        Command.run(["sh", "-c", `
            for device in /sys/block/*; do
                [ -e "$device/device" ] || continue
                [ -r "$device/stat" ] || continue
                printf "%s\\n" "\${device##*/}"
            done
        `]).then(result => {
            if (result.exitCode !== 0)
                throw new Error("exit " + result.exitCode + ": " + result.stderr.trim());
            root.diskDevices = result.stdout.trim().split("\n").filter(Boolean);
            root.previousDisk = null;
            diskIoFile.reload();
        }).catch(error => {
            root.diskDevices = [];
            root.previousDisk = null;
            root.diskIoValid = false;
            console.warn("Disk discovery failed:", error.message);
        });
    }

    function sampleDisk(text: string) {
        const current = {};
        for (const line of text.trim().split("\n")) {
            const fields = line.trim().split(/\s+/);
            const name = fields[2];
            if (!diskDevices.includes(name))
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
            previousDisk = null;
            diskIoValid = false;
            return;
        }
        const before = previousDisk;
        previousDisk = current;
        const seconds = diskSampleTimer.restart();
        if (before === null || seconds <= 0) {
            diskIoValid = false;
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
        diskIoValid = matched > 0;
        diskReadBps = diskIoValid ? readSectors * 512 / seconds : 0;
        diskWriteBps = diskIoValid ? writeSectors * 512 / seconds : 0;
    }

    function recordDisk() {
        const time = Date.now();
        diskHistory = diskHistory.filter(point => point.time >= time - 60000).concat({
            time,
            read: diskIoValid ? diskReadBps : null,
            write: diskIoValid ? diskWriteBps : null
        });
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
        const swapTotal = Number(text.match(/^SwapTotal:\s+(\d+)\s+kB$/m)?.[1]);
        const swapFree = Number(text.match(/^SwapFree:\s+(\d+)\s+kB$/m)?.[1]);
        root.swap = swapTotal >= 0 && swapFree >= 0 && swapFree <= swapTotal ? {
            total: swapTotal * 1024,
            used: (swapTotal - swapFree) * 1024
        } : null;
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

    FileView {
        id: loadFile
        path: "/proc/loadavg"
        onLoaded: {
            const values = loadFile.text().trim().split(/\s+/).slice(0, 3).map(Number);
            root.loadAverage = values.length === 3 && values.every(value => Number.isFinite(value) && value >= 0) ? values : [];
        }
        onLoadFailed: root.loadAverage = []
    }

    FileView {
        id: cpuTemperatureFile
        path: root.cpuTemperaturePath
        onLoaded: {
            const value = Number(cpuTemperatureFile.text().trim() || NaN);
            root.cpuTemperatureValid = Number.isFinite(value);
            if (root.cpuTemperatureValid)
                root.cpuTemperature = value / 1000;
        }
        onLoadFailed: root.cpuTemperatureValid = false
    }

    FileView {
        id: cpuClockFile
        path: "/proc/cpuinfo"
        onLoaded: root.sampleCpuClock(cpuClockFile.text())
        onLoadFailed: root.cpuClock = -1
    }

    FileView {
        id: cpuFile
        path: "/proc/stat"
        onLoaded: {
            root.sampleCpu(cpuFile.text());
            root.recordCpu();
        }
        onLoadFailed: {
            root.previousCpu = null;
            root.cpuValid = false;
            root.recordCpu();
        }
    }

    FileView {
        id: memoryFile
        path: "/proc/meminfo"
        onLoaded: root.sampleMemory(memoryFile.text())
        onLoadFailed: {
            root.memoryValid = false;
            root.swap = null;
        }
    }

    ElapsedTimer {
        id: diskSampleTimer
    }

    FileView {
        id: diskIoFile
        path: "/proc/diskstats"
        onLoaded: {
            root.sampleDisk(diskIoFile.text());
            root.recordDisk();
        }
        onLoadFailed: {
            root.previousDisk = null;
            root.diskIoValid = false;
            root.recordDisk();
        }
    }

    Process {
        id: diskProcess
        skipIfRunning: true
        running: true
        command: ["df", "-B1", "--output=size,used,avail", "/"]
        stdout: StdioCollector {
            id: diskOutput
        }
        stderr: StdioCollector {
            id: diskError
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.diskValid = false;
                console.warn("disk usage query failed (exit " + exitCode + "):", diskError.text.trim());
                return;
            }
            const fields = diskOutput.text.trim().split("\n").slice(1).join(" ").trim().split(/\s+/);
            const values = fields.map(Number);
            const [total, used, available] = values;
            root.diskValid = values.length === 3 && values.every(Number.isFinite) && total > 0 && used >= 0 && used <= total && available <= total;
            if (!root.diskValid) {
                console.warn("Unexpected disk usage output:", diskOutput.text.trim());
                return;
            }
            root.diskTotal = total;
            root.diskUsed = used;
            root.diskAvailable = available;
        }
    }

    Process {
        id: gpuProcess
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
            id: gpuError
        }
        onExited: exitCode => {
            if (exitCode === 0)
                root.sampleGpu(gpuOutput.text);
            else {
                root.gpuInfo = null;
                console.warn("GPU query failed (exit " + exitCode + "):", gpuError.text.trim());
            }
            root.recordGpu();
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            gpuProcess.run();
            uptimeFile.reload();
            loadFile.reload();
            cpuFile.reload();
            cpuClockFile.reload();
            diskIoFile.reload();
            memoryFile.reload();
            if (root.cpuTemperaturePath !== "")
                cpuTemperatureFile.reload();
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: diskProcess.run()
    }

    Connections {
        target: Sleep
        function onResumed() {
            uptimeFile.reload();
            loadFile.reload();
            cpuClockFile.reload();
            memoryFile.reload();
            root.readDiskInfo();
            root.gpuInfo = null;
            root.gpuHistory = [];
            gpuProcess.run();
            root.previousCpu = null;
            root.cpuHistory = [];
            root.cpuValid = false;
            cpuFile.reload();
            root.previousDisk = null;
            root.diskHistory = [];
            root.diskIoValid = false;
            root.discoverDisks();
        }
    }
}
