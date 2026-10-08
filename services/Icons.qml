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
        command: ["sh", "-c", "for icon in /usr/share/icons/MacTahoe/*/symbolic/*.svg \"$1\"/*.svg; do [ -f \"$icon\" ] && printf '%s\\n' \"$icon\"; done", "sh", Quickshell.shellPath("assets")]
        stdout: StdioCollector {
            onStreamFinished: {
                const files = {};
                for (const path of text.trim().split("\n")) {
                    if (!path || path.includes("@2x/"))
                        continue;
                    const name = path.substring(path.lastIndexOf("/") + 1).replace(/\.svg$/, "");
                    files[name] = "file://" + path;
                }
                root.files = files;
                if (!Object.keys(files).length)
                    console.warn("Local and MacTahoe icons not found; using the system icon theme.");
            }
        }
    }
}
