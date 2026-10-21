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
    readonly property var packages: sortedPackages(state.official.packages).concat(sortedPackages(state.aur.packages))
    property var news: []
    readonly property int count: packages.length
    property bool checking
    readonly property bool installerOpen: installer.running
    property bool pending
    property var updatedAt
    readonly property string error: [state.official.error, state.aur.error, state.newsError].filter(Boolean).join("\n")

    QtObject {
        id: state
        property var official: ({
                packages: [],
                error: ""
            })
        property var aur: ({
                packages: [],
                error: ""
            })
        property string newsError
    }

    Component.onCompleted: refresh()

    function refresh() {
        if (checking)
            return;
        checking = true;
        pending = false;
        refreshDelay.stop();
        const packages = refreshPackages();
        const news = refreshNews();
        return waitAll([packages, news]).catch(error => {
            console.warn("Updates refresh failed:", error.message);
        }).then(() => {
            root.checking = false;
            if (root.pending && !refreshDelay.running)
                refreshDelay.start();
        });
    }

    function refreshPackages() {
        const official = refreshSource("Official", ["checkupdates", "--nocolor"], 2);
        const aur = refreshSource("AUR", ["paru", "-Qua", "--color", "never"], 1);
        return Promise.all([official, aur]).then(success => {
            if (success.every(Boolean))
                root.updatedAt = new Date();
            return refreshLinks();
        });
    }

    function refreshSource(source: string, command: list<string>, emptyExitCode: int): var {
        const key = source.toLowerCase();
        return CommandService.run(command).then(result => {
            const text = result.stdout.trim();
            const stderr = result.stderr.trim();
            const noUpdates = result.exitCode === emptyExitCode && text === "" && stderr === "";
            if (result.exitCode !== 0 && !noUpdates)
                throw new Error(source + " updates query failed (exit " + result.exitCode + "): " + stderr);
            state[key] = {
                packages: parsePackages(text, source),
                error: ""
            };
            return true;
        }).catch(error => {
            state[key] = {
                packages: state[key].packages,
                error: error.message
            };
            console.warn(error.message);
            return false;
        });
    }

    function parsePackages(text: string, source: string): var {
        const packages = [];
        for (const line of text ? text.split("\n") : []) {
            if (line.trim().endsWith(" [ignored]"))
                continue;
            const fields = line.trim().split(/\s+/);
            const [name, oldVersion, arrow, newVersion] = fields;
            if (fields.length !== 4 || arrow !== "->")
                throw new Error(source + " unexpected update entry: " + line);
            packages.push({
                name,
                oldVersion,
                newVersion,
                source
            });
        }
        return packages;
    }

    function refreshLinks() {
        const names = root.packages.map(pkg => pkg.name).filter(name => !root.links[name]);
        if (names.length === 0) {
            root.websites = {};
            return Promise.resolve();
        }
        return CommandService.run(["env", "LC_ALL=C", "pacman", "-Qi"].concat(names)).then(result => {
            if (result.exitCode !== 0)
                throw new Error("Package URL query failed: " + result.stderr.trim());
            const websites = {};
            for (const record of result.stdout.split(/\n\s*\n/)) {
                const name = record.match(/^Name\s*:\s*(\S+)/m)?.[1];
                const url = record.match(/^URL\s*:\s*(\S+)/m)?.[1];
                if (name && url && url !== "None")
                    websites[name] = url;
            }
            root.websites = websites;
        }).catch(error => console.warn(error.message));
    }

    function refreshNews() {
        const buildDate = readBuildDate();
        const feed = newsFeed.read();
        return waitAll([buildDate, feed]).then(([latestBuild, items]) => {
            root.news = items.filter(item => item.date.getTime() >= latestBuild);
            state.newsError = "";
        }).catch(error => {
            state.newsError = error.message;
            console.warn(error.message);
        });
    }

    function readBuildDate() {
        return CommandService.run(["sh", "-c", "awk '/^%BUILDDATE%$/ { getline; if ($0 > latest) latest = $0 } END { printf \"%.0f\\n\", latest }' /var/lib/pacman/local/*/desc"]).then(result => {
            if (result.exitCode !== 0)
                throw new Error("Arch news package query failed: " + result.stderr.trim());
            return Number(result.stdout.trim()) * 1000;
        });
    }

    // Wait for every task before propagating a failure, so refreshes cannot overlap.
    function waitAll(promises): var {
        const tasks = promises.map(promise => promise.then(value => ({
                        value
                    }), error => ({
                        error
                    })));
        return Promise.all(tasks).then(results => {
            const failure = results.find(result => result.error);
            if (failure)
                throw failure.error;
            return results.map(result => result.value);
        });
    }

    function install() {
        if (!installerOpen)
            installer.running = true;
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
        target: SleepService

        function onResumed() {
            root.refresh();
        }
    }

    Connections {
        target: NetworkService

        function onReady() {
            root.refresh();
        }
    }

    Process {
        id: installer
        command: ["kitty", "--title", "System update", "zsh", "-ic", "command paru; update_exit=$?; printf '\\nPress Enter to close...'; read -r; exit $update_exit"]
    }

    XmlListModel {
        id: newsFeed
        property var completion: null
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

        function read() {
            return new Promise((resolve, reject) => {
                completion = {
                    resolve,
                    reject
                };
                if (source.toString() === "")
                    source = "https://archlinux.org/feeds/news/";
                else
                    reload();
            });
        }

        function finish(items, error = null) {
            const callbacks = completion;
            completion = null;
            newsTimeout.stop();
            if (error)
                callbacks.reject(error);
            else
                callbacks.resolve(items);
        }

        onStatusChanged: {
            if (!completion)
                return;
            if (status === XmlListModel.Loading) {
                newsTimeout.restart();
            } else if (status === XmlListModel.Error) {
                finish(null, new Error("Arch news query failed: " + errorString()));
            } else if (status === XmlListModel.Ready) {
                if (count === 0) {
                    finish(null, new Error("Arch news feed is empty or invalid."));
                    return;
                }
                const items = [];
                for (let i = 0; i < newsItems.items.count; i++) {
                    const item = newsItems.items.get(i).model;
                    items.push({
                        title: item.title,
                        url: item.url,
                        date: new Date(item.date)
                    });
                }
                finish(items);
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
            newsFeed.finish(null, new Error("Arch news request timed out."));
            newsFeed.source = "";
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

    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
