pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string device
    readonly property real current: Number(brightnessFile.text().trim() || NaN)
    readonly property real maximum: Number(maximumFile.text().trim() || NaN)
    readonly property bool available: brightnessFile.readOk && maximumFile.readOk && Number.isFinite(root.maximum) && root.maximum > 0 && root.current >= 0 && root.current <= root.maximum
    readonly property real level: root.available ? root.current / root.maximum : 0

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
