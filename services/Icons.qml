pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var files

    function source(name: string): string {
        if (!name || !root.files)
            return "";
        return root.files[name] ?? Quickshell.iconPath(name);
    }

    Process {
        running: true
        command: ["sh", "-c", "for icon in /usr/share/icons/MacTahoe/*/symbolic/*.svg; do [ -f \"$icon\" ] && printf '%s\\n' \"$icon\"; done; find \"$1\" -type f -name '*.svg'", "sh", Quickshell.shellPath("assets")]
        stdout: StdioCollector {
            onStreamFinished: {
                const files = {};
                const assetsPath = Quickshell.shellPath("assets") + "/";
                for (const path of text.trim().split("\n")) {
                    if (!path || path.includes("@2x/"))
                        continue;
                    const relativePath = path.startsWith(assetsPath) ? path.substring(assetsPath.length) : path.substring(path.lastIndexOf("/") + 1);
                    const name = relativePath.replace(/\.svg$/, "");
                    files[name] = "file://" + path;
                }
                root.files = files;
                if (!Object.keys(files).length)
                    console.warn("Local and MacTahoe icons not found; using the system icon theme.");
            }
        }
    }
}
