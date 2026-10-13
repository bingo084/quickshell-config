pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

Singleton {
    id: root
    readonly property var importantPackages: ["linux", "nvidia-open-dkms", "mesa", "niri", "quickshell"]
    readonly property var links: ({
            "chezmoi": "https://github.com/twpayne/chezmoi/releases",
            "firefox": "https://www.firefox.com/en-US/releases/",
            "fish": "https://fishshell.com/docs/current/relnotes.html",
            "google-chrome": "https://chromereleases.googleblog.com/search/label/Stable%20updates",
            "kitty": "https://sw.kovidgoyal.net/kitty/changelog/",
            "neovim": "https://github.com/neovim/neovim/releases",
            "quickshell": "https://github.com/quickshell-mirror/quickshell/releases",
            "quickshell-git": "https://github.com/quickshell-mirror/quickshell/commits",
            "rbw": "https://git.tozt.net/rbw/tree/CHANGELOG.md",
            "rofi": "https://github.com/davatorium/rofi/releases",
            "sing-box": "https://sing-box.sagernet.org/changelog/",
            "starship": "https://github.com/starship/starship/releases",
            "telegram-desktop": "https://desktop.telegram.org/changelog",
            "wofi": "https://hg.sr.ht/~scoopta/wofi/log",
            "xremap-wlroots-bin": "https://github.com/xremap/xremap/releases",
            "zsh": "https://github.com/zsh-users/zsh/blob/master/NEWS"
        })
    property var websites: ({})
    readonly property var packages: sortedPackages(repoQuery.packages).concat(sortedPackages(aurQuery.packages))
    readonly property int count: packages.length
    readonly property bool checking: repoQuery.running || aurQuery.running
    readonly property bool busy: checking || websiteQuery.running
    readonly property bool installerOpen: installer.running
    property bool pending
    property var updatedAt
    readonly property string error: [repoQuery.error, aurQuery.error].filter(Boolean).join("\n")

    onCheckingChanged: {
        if (!checking)
            refreshLinks();
    }

    onBusyChanged: {
        if (!busy && pending && !refreshDelay.running)
            refreshDelay.start();
    }

    function refresh() {
        if (busy)
            return;
        pending = false;
        refreshDelay.stop();
        repoQuery.running = true;
        aurQuery.running = true;
    }

    function install() {
        if (!installerOpen)
            installer.running = true;
    }

    function refreshLinks() {
        websiteQuery.packageNames = root.packages.map(pkg => pkg.name).filter(name => !root.links[name]);
        if (websiteQuery.packageNames.length === 0) {
            root.websites = {};
            return;
        }
        websiteQuery.running = true;
    }

    function link(name: string): string {
        const url = root.links[name];
        if (url)
            return url;
        const website = root.websites[name];
        if (!website)
            return "";
        const repo = website.match(/^https?:\/\/(github\.com|codeberg\.org)\/([^/]+)\/([^/?#]+)/);
        if (!repo || repo[1] === "codeberg.org" && name.endsWith("-git"))
            return website;
        const path = name.endsWith("-git") ? "commits" : "releases";
        return "https://" + repo[1] + "/" + repo[2] + "/" + repo[3].replace(/\.git$/, "") + "/" + path;
    }

    function openDetails(name: string) {
        const url = root.link(name);
        if (url)
            Qt.openUrlExternally(url);
    }

    function sortedPackages(packages: var): var {
        const priority = name => {
            const index = root.importantPackages.indexOf(name);
            return index === -1 ? root.importantPackages.length : index;
        };
        return packages.slice().sort((a, b) => priority(a.name) - priority(b.name) || a.name.localeCompare(b.name));
    }

    function updateLevel(oldVersion: string, newVersion: string): string {
        const versions = [oldVersion, newVersion].map(version => version.match(/^(?:\d+:)?v?(\d{1,4})(?:[._](\d+))?(?=$|[._+~-]|alpha|beta|rc)/i));
        if (versions.some(version => version === null))
            return "normal";
        const [previous, next] = versions.map(version => [Number(version[1]), Number(version[2] || 0)]);
        if (next[0] > previous[0])
            return "major";
        if (next[0] === previous[0] && next[1] > previous[1])
            return "minor";
        return "normal";
    }

    Connections {
        target: Sleep

        function onResumed() {
            root.refresh();
        }
    }

    Connections {
        target: Network

        function onReady() {
            root.refresh();
        }
    }

    Process {
        id: installer
        command: ["kitty", "--title", "System update", "zsh", "-ic", "command paru; update_exit=$?; printf '\\nPress Enter to close...'; read -r; exit $update_exit"]
    }

    Process {
        autoRestart: true
        command: ["tail", "-n", "0", "-F", "/var/log/pacman.log"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                if (line.endsWith("[ALPM] transaction completed")) {
                    root.pending = true;
                    refreshDelay.restart();
                }
            }
        }
        stderr: SplitParser {
            onRead: line => console.warn("Package monitor:", line)
        }
    }

    Timer {
        id: refreshDelay
        interval: 1000
        onTriggered: root.refresh()
    }

    Process {
        id: websiteQuery
        property var packageNames: []
        command: ["env", "LC_ALL=C", "pacman", "-Qi"].concat(packageNames)

        stdout: StdioCollector {
            id: websiteOutput
        }
        stderr: StdioCollector {
            id: websiteErrors
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("Package URL query failed:", websiteErrors.text.trim());
                return;
            }
            const websites = {};
            for (const record of websiteOutput.text.split(/\n\s*\n/)) {
                const name = record.match(/^Name\s*:\s*(\S+)/m)?.[1];
                const url = record.match(/^URL\s*:\s*(\S+)/m)?.[1];
                if (name && url && url !== "None")
                    websites[name] = url;
            }
            root.websites = websites;
        }
    }

    component UpdateQuery: Process {
        id: query
        required property string sourceName
        required property int emptyExitCode
        property var packages: []
        property string error

        running: true

        stdout: StdioCollector {
            id: queryOutput
        }
        stderr: StdioCollector {
            id: queryErrors
        }
        onExited: exitCode => {
            const text = queryOutput.text.trim();
            const noUpdates = exitCode === query.emptyExitCode && text === "" && queryErrors.text.trim() === "";
            if (exitCode !== 0 && !noUpdates) {
                query.error = query.sourceName + " updates query failed (exit " + exitCode + "): " + queryErrors.text.trim();
                console.warn(query.error);
                return;
            }
            const packages = [];
            if (exitCode === 0) {
                const lines = text ? text.split("\n") : [];
                for (const line of lines) {
                    if (line.trim().endsWith(" [ignored]"))
                        continue;
                    const fields = line.trim().split(/\s+/);
                    const [name, oldVersion, arrow, newVersion] = fields;
                    if (fields.length !== 4 || arrow !== "->") {
                        query.error = query.sourceName + " unexpected update entry: " + line;
                        console.warn(query.error);
                        return;
                    }
                    packages.push({
                        name,
                        oldVersion,
                        newVersion,
                        source: query.sourceName
                    });
                }
            }
            query.packages = packages;
            query.error = "";
            if (!repoQuery.running && !aurQuery.running && root.error === "")
                root.updatedAt = new Date();
        }
    }

    UpdateQuery {
        id: repoQuery
        sourceName: "Official"
        emptyExitCode: 2
        command: ["checkupdates", "--nocolor"]
    }

    UpdateQuery {
        id: aurQuery
        sourceName: "AUR"
        emptyExitCode: 1
        command: ["paru", "-Qua", "--color", "never"]
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
