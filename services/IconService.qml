pragma Singleton

import QtCore
import QtQml
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var files
    property bool refreshing: false

    FileView {
        path: StandardPaths.writableLocation(StandardPaths.ConfigLocation) + "/qt6ct/qt6ct.conf"
        preload: true
        watchChanges: true
        printErrors: false
        onFileChanged: refreshDelay.restart()
    }

    Timer {
        id: refreshDelay
        // qt6ct applies icon theme changes after a three-second debounce.
        interval: 3500
        onTriggered: {
            root.refreshing = true;
            Qt.callLater(() => root.refreshing = false);
        }
    }

    Component.onCompleted: {
        CommandService.run(["find", Quickshell.shellPath("assets"), "-type", "f", "-name", "*.svg"]).then(result => {
            if (result.exitCode !== 0)
                console.warn("Icon scan failed (exit " + result.exitCode + "):", result.stderr.trim());
            const files = {};
            const assetsPath = Quickshell.shellPath("assets") + "/";
            for (const path of result.stdout.trim().split("\n")) {
                if (!path)
                    continue;
                const name = path.substring(assetsPath.length).replace(/\.svg$/, "");
                files[name] = "file://" + path;
            }
            root.files = files;
        }).catch(error => {
            root.files = {};
            console.warn("Icon scan failed:", error.message);
        });
    }

    function resolve(name: string, source = "", theme = ""): var {
        source = source.toString();
        if (source) {
            const prefix = "image://icon/";
            name = source.startsWith(prefix) ? source.substring(prefix.length).split("?")[0] : "";
        }
        if (theme && name) {
            const file = themeFile(name, theme);
            if (file)
                return {
                    name: "",
                    source: file
                };
        }
        if (name === "input-keyboard-symbolic")
            name = "on-screen-keyboard-symbolic";
        else if (name === "input-gaming-symbolic")
            name = "gamepad-symbolic";
        const file = root.files?.[name];
        return {
            name: file || root.refreshing ? "" : name,
            source: file || (root.refreshing && name ? "" : source)
        };
    }

    function themeFile(name: string, theme: string): string {
        if (name.startsWith("/"))
            return "file://" + name;
        const extensions = /\.(svg|png|xpm)$/i.test(name) ? [""] : [".svg", ".png", ".xpm"];
        for (const size of ["scalable", "symbolic", "48x48", "32x32", "24x24", "22x22", "16x16", "64x64", "128x128", "256x256", "512x512"]) {
            for (const extension of extensions) {
                const file = StandardPaths.locate(StandardPaths.GenericDataLocation, "icons/" + theme + "/" + size + "/apps/" + name + extension).toString();
                if (file)
                    return file;
            }
        }
        return "";
    }
}
