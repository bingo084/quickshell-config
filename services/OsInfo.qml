pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    FileView {
        id: osRelease
        path: "/etc/os-release"
        blockLoading: true
    }

    function get(key) {
        const m = osRelease.text().match(new RegExp(`^${key}=(.*)$`, "m"));
        return m ? m[1].trim().replace(/^['"]|['"]$/g, "") : "";
    }

    function logo() {
        return Quickshell.iconPath("/usr/share/pixmaps/" + get("LOGO") + ".svg", get("LOGO"));
    }
}
