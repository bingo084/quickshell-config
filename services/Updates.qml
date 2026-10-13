pragma Singleton
pragma ComponentBehavior: Bound

import QtQml.Models
import QtQml.XmlListModel
import QtQuick
import Quickshell
import Quickshell.Io
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
    property var news: []
    readonly property int count: packages.length
    readonly property bool packagesChecking: repoQuery.running || aurQuery.running
    readonly property bool checking: packagesChecking || buildQuery.running || newsFeed.status === XmlListModel.Loading
    readonly property bool busy: checking || websiteQuery.running
    readonly property bool installerOpen: installer.running
    property bool pending
    property var updatedAt
    readonly property string error: [repoQuery.error, aurQuery.error, buildQuery.error, newsFeed.error].filter(Boolean).join("\n")

    Component.onCompleted: refreshNews()

    onPackagesCheckingChanged: {
        if (!packagesChecking)
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
        refreshNews();
        repoQuery.running = true;
        aurQuery.running = true;
    }

    function refreshNews() {
        buildQuery.run();
        if (newsFeed.source.toString() === "")
            newsFeed.source = "https://archlinux.org/feeds/news/";
        else
            newsFeed.reload();
    }

    function updateNews() {
        if (buildQuery.running || newsFeed.status !== XmlListModel.Ready || buildQuery.latestBuild < 0 || buildQuery.error !== "" || newsFeed.error !== "")
            return;
        const news = [];
        for (let i = 0; i < newsItems.items.count; i++) {
            const item = newsItems.items.get(i).model;
            const date = new Date(item.date);
            if (date.getTime() >= buildQuery.latestBuild)
                news.push({
                    title: item.title,
                    url: item.url,
                    date
                });
        }
        root.news = news;
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
        id: buildQuery
        property double latestBuild: -1
        property string error
        // Paru 2.1.0 uses the latest build date across all installed packages.
        command: ["sh", "-c", "awk '/^%BUILDDATE%$/ { getline; if ($0 > latest) latest = $0 } END { printf \"%.0f\\n\", latest }' /var/lib/pacman/local/*/desc"]
        stdout: StdioCollector {
            id: buildOutput
        }
        stderr: StdioCollector {
            id: buildErrors
        }
        onExited: exitCode => {
            if (exitCode !== 0) {
                error = "Arch news package query failed: " + buildErrors.text.trim();
                console.warn(error);
                return;
            }
            latestBuild = Number(buildOutput.text.trim()) * 1000;
            error = "";
            root.updateNews();
        }
    }

    XmlListModel {
        id: newsFeed
        property string error
        query: "/rss/channel/item"
        XmlListModelRole {
            name: "title"
            elementName: "title"
        }
        XmlListModelRole {
            name: "url"
            elementName: "link"
        }
        XmlListModelRole {
            name: "date"
            elementName: "pubDate"
        }

        onStatusChanged: {
            if (status === XmlListModel.Loading) {
                error = "";
                newsTimeout.restart();
                return;
            }
            newsTimeout.stop();
            if (status === XmlListModel.Error) {
                error = "Arch news query failed: " + errorString();
                console.warn(error);
            } else if (status === XmlListModel.Ready) {
                if (count === 0) {
                    error = "Arch news feed is empty or invalid.";
                    console.warn(error);
                } else {
                    root.updateNews();
                }
            }
        }
    }

    DelegateModel {
        id: newsItems
        model: newsFeed
    }

    Timer {
        id: newsTimeout
        interval: 15000
        onTriggered: {
            newsFeed.source = "";
            newsFeed.error = "Arch news request timed out.";
            console.warn(newsFeed.error);
        }
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
            if (!root.packagesChecking && repoQuery.error === "" && aurQuery.error === "")
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
