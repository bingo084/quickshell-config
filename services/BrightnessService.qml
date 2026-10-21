pragma Singleton

import QtQml
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

    Component.onCompleted: {
        CommandService.run(["brightnessctl", "-c", "backlight", "-m"]).then(result => {
            if (result.exitCode !== 0)
                throw new Error("brightnessctl query failed (exit " + result.exitCode + "): " + result.stderr.trim());
            const text = result.stdout.trim();
            const fields = text.split("\n")[0].split(",");
            if (fields.length < 5 || fields[0] === "")
                throw new Error("Unexpected brightnessctl output: " + text);
            root.device = fields[0];
            return CommandService.run(["readlink", "-f", `/sys/class/backlight/${root.device}`]);
        }).then(result => {
            if (result.exitCode !== 0)
                throw new Error("backlight path query failed (exit " + result.exitCode + "): " + result.stderr.trim());
            const path = result.stdout.trim();
            const match = path.match(/\/card\d+-([^/]+)\//);
            if (!match)
                throw new Error("Cannot identify backlight output: " + path);
            root.output = match[1];
        }).catch(error => console.warn(error.message));
    }

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
