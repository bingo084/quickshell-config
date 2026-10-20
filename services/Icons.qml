pragma Singleton

import QtQml
import Quickshell
import qs.config

Singleton {
    id: root
    property var files

    Component.onCompleted: {
        Command.run(["sh", "-c", "for theme in MacTahoe-light MacTahoe-dark; do for icon in /usr/share/icons/\"$theme\"/*/16/*.svg /usr/share/icons/\"$theme\"/*/symbolic/*.svg; do [ -f \"$icon\" ] && printf '%s\\n' \"$icon\"; done; done; find \"$1\" -type f -name '*.svg'", "sh", Quickshell.shellPath("assets")]).then(result => {
            if (result.exitCode !== 0)
                console.warn("Icon scan failed (exit " + result.exitCode + "):", result.stderr.trim());
            const files = {
                light: {},
                dark: {},
                assets: {}
            };
            const assetsPath = Quickshell.shellPath("assets") + "/";
            for (const path of result.stdout.trim().split("\n")) {
                if (!path || path.includes("@2x/"))
                    continue;
                const local = path.startsWith(assetsPath);
                const relativePath = local ? path.substring(assetsPath.length) : path.substring(path.lastIndexOf("/") + 1);
                const name = relativePath.replace(/\.svg$/, "");
                const group = local ? files.assets : path.startsWith("/usr/share/icons/MacTahoe-dark/") ? files.dark : files.light;
                group[name] = "file://" + path;
            }
            root.files = files;
            if (![files.light, files.dark, files.assets].some(group => Object.keys(group).length))
                console.warn("Local and MacTahoe icons not found; using the system icon theme.");
        }).catch(error => {
            root.files = {
                light: {},
                dark: {},
                assets: {}
            };
            console.warn("Icon scan failed:", error.message);
        });
    }

    function source(name: string, fallback = ""): string {
        if (!name)
            return "";
        if (!root.files)
            return fallback;
        const theme = Theme.dark ? root.files.dark : root.files.light;
        const other = Theme.dark ? root.files.light : root.files.dark;
        return root.files.assets[name] ?? theme[name] ?? other[name] ?? (fallback || Quickshell.iconPath(name));
    }

    function resolve(source: string): string {
        const prefix = "image://icon/";
        if (!source.startsWith(prefix))
            return source;
        const name = source.substring(prefix.length).split("?")[0];
        return root.source(name, source);
    }
}
