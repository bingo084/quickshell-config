pragma Singleton

import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Wayland
import qs.services

Singleton {
    id: root
    readonly property list<MprisPlayer> players: Mpris.players.values.filter(player => player.playbackState !== MprisPlaybackState.Stopped) // qmllint disable missing-property
    property MprisPlayer selected: null
    readonly property MprisPlayer player: selected ?? players.find(player => player.isPlaying) ?? players[0] ?? null
    readonly property string title: player?.trackTitle || player?.identity || ""
    readonly property string subtitle: [player?.trackArtist, player?.trackAlbum].filter(Boolean).join(" · ")
    readonly property string artwork: player?.trackArtUrl ?? ""
    property url coverSource
    property bool coverLoading: false
    property var coverColors: null
    readonly property var coverCache: new Map()
    property list<real> spectrum: Array(24).fill(0)

    function windowFor(player: MprisPlayer): Toplevel {
        const appId = player?.desktopEntry;
        return appId ? ToplevelManager.toplevels.values.find(window => window.appId === appId) ?? null : null;
    }

    function canActivate(player: MprisPlayer): bool {
        return (player?.canRaise ?? false) || windowFor(player) !== null;
    }

    function activate(player: MprisPlayer) {
        if (player?.canRaise)
            player.raise();
        else
            windowFor(player)?.activate();
    }

    onPlayersChanged: {
        if (selected !== null && !players.includes(selected))
            selected = null;
    }

    onArtworkChanged: {
        if (!artwork) {
            coverLoading = false;
            coverSource = "";
            coverColors = null;
            return;
        }
        const url = artwork;
        const remote = /^https?:/.test(url);
        const file = remote ? Quickshell.cachePath("media/" + Qt.md5(url)) : decodeURIComponent(url.replace(/^file:\/\//, ""));
        const source = remote ? "file://" + file : url;
        const colors = coverCache.get(url);
        if (colors) {
            coverSource = source;
            coverColors = colors;
            coverLoading = false;
            return;
        }
        coverLoading = true;
        const ready = remote ? CommandService.run(["curl", "-fLsS", "--max-time", "15", "--create-dirs", "--output", file, url]).then(result => {
            if (result.exitCode !== 0)
                throw new Error("Cover download failed: " + result.stderr.trim());
        }) : Promise.resolve();
        ready.then(() => {
            if (root.artwork !== url)
                return null;
            root.coverSource = source;
            root.coverLoading = false;
            return CommandService.run(["matugen", "--dry-run", "--json", "hex", "--source-color-index", "0", "image", file]);
        }).then(result => {
            if (!result || root.artwork !== url)
                return;
            if (result.exitCode !== 0)
                throw new Error("Media color generation failed: " + result.stderr.trim());
            const primary = JSON.parse(result.stdout).colors.primary;
            root.coverColors = {
                light: primary.light.color,
                dark: primary.dark.color
            };
            root.coverCache.set(url, root.coverColors);
            if (root.coverCache.size > 16)
                root.coverCache.delete(root.coverCache.keys().next().value);
        }).catch(error => {
            if (root.artwork !== url)
                return;
            root.coverLoading = false;
            root.coverColors = null;
            if (root.coverSource.toString() !== source)
                root.coverSource = "";
            console.warn("Media colors:", error.message);
        });
    }

    Process {
        command: ["cava", "-p", Quickshell.shellPath("config/cava.conf")]
        running: root.player?.isPlaying ?? false
        onRunningChanged: {
            if (!running)
                root.spectrum = root.spectrum.map(() => 0);
        }
        stdout: SplitParser {
            onRead: data => root.spectrum = data.split(";").filter(Boolean).map(value => Number(value) / 100)
        }
        stderr: SplitParser {
            onRead: data => console.warn("Media spectrum:", data)
        }
    }
}
