pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.components
import qs.config
import qs.services

Popup {
    id: root
    readonly property MprisPlayer player: MediaService.player
    preferredWidth: 360
    onPlayerChanged: {
        if (player === null)
            close();
    }

    component PlayerSwitch: Button {
        required property int offset
        readonly property MprisPlayer targetPlayer: {
            const players = MediaService.players;
            const index = players.indexOf(root.player);
            return players[(index + offset + players.length) % players.length] ?? null;
        }

        visible: targetPlayer !== null && targetPlayer !== root.player
        size: 32
        radius: height / 2
        iconName: offset < 0 ? "go-previous-symbolic" : "go-next-symbolic"
        palette.buttonText: Theme.textSecondary
        onClicked: {
            header.prepareSwitch(targetPlayer, offset);
            MediaService.selected = targetPlayer;
        }
    }

    Item {
        id: panel
        implicitWidth: body.implicitWidth
        implicitHeight: body.implicitHeight

        FluidCover {
            x: -root.contentMargin
            y: x
            width: panel.width + 2 * root.contentMargin
            height: panel.height + 2 * root.contentMargin
            source: MediaService.coverSource
            visible: root.visible
            playing: root.player?.isPlaying ?? false
        }

        ColumnLayout {
            id: body
            width: parent.width
            spacing: 16

            Item {
                Layout.fillWidth: true
                implicitHeight: header.implicitHeight

                MediaHeader {
                    id: header
                    anchors.fill: parent
                    sideWidth: MediaService.players.length > 1 ? previousPlayer.implicitWidth + root.contentMargin : 0
                    entry: root.player ? {
                        key: root.player,
                        source: MediaService.coverSource,
                        provider: root.player.identity,
                        title: MediaService.title,
                        subtitle: MediaService.subtitle,
                        playing: root.player.isPlaying,
                        canActivate: MediaService.canActivate(root.player),
                        loading: MediaService.coverLoading
                    } : null
                    onActivated: player => {
                        root.close();
                        MediaService.activate(player);
                    }
                }

                PlayerSwitch {
                    id: previousPlayer
                    x: (header.sideWidth - width) / 2
                    y: (header.artworkHeight - height) / 2
                    offset: -1
                }

                PlayerSwitch {
                    x: parent.width - (header.sideWidth + width) / 2
                    y: (header.artworkHeight - height) / 2
                    offset: 1
                }
            }

            Item {
                id: footer
                readonly property real edgeInset: root.contentMargin + 1
                Layout.fillWidth: true
                implicitHeight: playback.implicitHeight

                Spectrum {
                    id: spectrum
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: -footer.edgeInset
                    anchors.rightMargin: -footer.edgeInset
                    anchors.bottomMargin: -footer.edgeInset
                    height: parent.height + body.spacing - anchors.bottomMargin
                    visible: root.visible
                    opacity: 0.65 - 0.35 * timeline.expansion
                }

                ColumnLayout {
                    id: playback
                    width: parent.width
                    spacing: 4

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 12

                        Button {
                            iconName: root.player?.shuffle ? "media-playlist-shuffle-symbolic" : "media-playlist-consecutive-symbolic"
                            size: 28
                            enabled: root.player !== null && root.player.canControl && root.player.shuffleSupported
                            onClicked: root.player.shuffle = !root.player.shuffle
                        }

                        Button {
                            iconName: "media-skip-backward-symbolic"
                            size: 32
                            enabled: root.player?.canGoPrevious ?? false
                            onClicked: root.player.previous()
                        }

                        Button {
                            iconName: root.player?.isPlaying ? "media-playback-pause-symbolic" : "media-playback-start-symbolic"
                            size: 40
                            radius: height / 2
                            variant: Button.Filled
                            icon.width: 20
                            icon.height: 20
                            enabled: root.player?.canTogglePlaying ?? false
                            onClicked: root.player.togglePlaying()
                        }

                        Button {
                            iconName: "media-skip-forward-symbolic"
                            size: 32
                            enabled: root.player?.canGoNext ?? false
                            onClicked: root.player.next()
                        }

                        Button {
                            readonly property int mode: root.player?.loopState ?? MprisLoopState.None
                            iconName: mode === MprisLoopState.Track ? "media-playlist-repeat-one-symbolic" : "media-playlist-repeat-symbolic"
                            size: 28
                            enabled: root.player !== null && root.player.canControl && root.player.loopSupported
                            onClicked: root.player.loopState = mode === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.Playlist
                        }
                    }

                    MediaTimeline {
                        id: timeline
                        Layout.fillWidth: true
                        Layout.leftMargin: -footer.edgeInset
                        Layout.rightMargin: -footer.edgeInset
                        Layout.bottomMargin: -footer.edgeInset
                        player: root.player
                        active: root.visible
                        inset: footer.edgeInset
                        color: spectrum.barColor
                    }
                }
            }
        }
    }
}
