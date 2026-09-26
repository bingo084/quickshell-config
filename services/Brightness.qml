pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string device
    readonly property real current: Number(brightnessFile.text().trim() || NaN)
    readonly property int minimum: 2
    readonly property real maximum: Number(maximumFile.text().trim() || NaN)
    readonly property bool available: brightnessFile.readOk && maximumFile.readOk && Number.isFinite(root.maximum) && root.maximum > 0 && root.current >= 0 && root.current <= root.maximum
    readonly property real level: root.available ? root.current / root.maximum : 0
    readonly property real minimumLevel: root.available ? root.minimum / root.maximum : 0
    property string output

    function change(step: int) {
        if (!root.available || step === 0)
            return;
        const value = step > 0 ? `${step}%+` : `${-step}%-`;
        Quickshell.execDetached(["brightnessctl", "-d", root.device, "-e4", `-n${root.minimum}`, "set", value]);
    }

    function setLevel(level: real) {
        if (!root.available || !Number.isFinite(level) || level < 0 || level > 1)
            return;
        const value = Math.round(level * root.maximum);
        Quickshell.execDetached(["brightnessctl", "-d", root.device, `-n${root.minimum}`, "set", value]);
    }

    Process {
        running: true
        command: ["brightnessctl", "-c", "backlight", "-m"]
        stdout: StdioCollector {
            id: stdout
        }
        stderr: StdioCollector {
            id: stderr
        }
        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("brightnessctl query failed (exit " + exitCode + "):", stderr.text.trim());
                return;
            }
            const fields = stdout.text.trim().split("\n")[0].split(",");
            if (fields.length < 5 || fields[0] === "") {
                console.warn("Unexpected brightnessctl output:", stdout.text.trim());
                return;
            }
            root.device = fields[0];
            outputQuery.running = true;
        }
        // qmllint enable signal-handler-parameters
    }
    Process {
        id: outputQuery
        command: ["readlink", "-f", `/sys/class/backlight/${root.device}`]
        stdout: StdioCollector {
            id: outputPath
        }
        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("Failed to resolve backlight path:", root.device);
                return;
            }
            const path = outputPath.text.trim();
            const match = path.match(/\/card\d+-([^/]+)\//);
            if (!match) {
                console.warn("Cannot identify backlight output:", path);
                return;
            }
            root.output = match[1];
        }
        // qmllint enable signal-handler-parameters
    }
    FileView {
        id: brightnessFile
        property bool readOk

        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        watchChanges: true

        onLoaded: brightnessFile.readOk = true
        onLoadFailed: brightnessFile.readOk = false
        onFileChanged: brightnessFile.reload()
    }
    FileView {
        id: maximumFile
        property bool readOk

        path: root.device ? `/sys/class/backlight/${root.device}/max_brightness` : ""

        onLoaded: maximumFile.readOk = true
        onLoadFailed: maximumFile.readOk = false
    }
}
