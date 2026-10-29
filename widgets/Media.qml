pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.widgets.media

BarButton {
    id: root
    visible: MediaService.player !== null
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.toggle();
        } else if (mouse.button === Qt.RightButton && MediaService.player?.canTogglePlaying) {
            MediaService.player.togglePlaying();
        } else if (mouse.button === Qt.MiddleButton && MediaService.canActivate(MediaService.player)) {
            popup.closeAll();
            MediaService.activate(MediaService.player);
        }
    }

    content: Item {
        implicitWidth: labels.implicitWidth
        implicitHeight: labels.implicitHeight

        Spectrum {
            barWidth: 5
            spacing: 2
            anchors.centerIn: parent
            width: root.width
            height: root.height
            z: -1
        }

        RowLayout {
            id: labels
            anchors.fill: parent
            spacing: 6

            Icon {
                name: "audio-x-generic-symbolic"
                implicitSize: 16
            }

            Text {
                id: title
                Layout.maximumWidth: 160
                text: MediaService.title
                elide: Text.ElideRight
                color: Theme.textPrimary

                Tooltip {
                    anchorItem: title
                    enabled: title.truncated
                    text: [MediaService.title, MediaService.subtitle].filter(Boolean).join("\n")
                }
            }
        }
    }

    MediaPopup {
        id: popup
        anchorItem: root
    }
}
