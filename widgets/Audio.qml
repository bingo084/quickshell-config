import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services
import qs.widgets.audio

BarButton {
    id: root

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.toggle();
        } else {
            popup.closeAll();
            AudioService.toggleMuted();
        }
    }
    onWheel: wheel => {
        AudioService.adjustVolume(wheel.angleDelta.y > 0 ? 0.01 : -0.01);
        wheel.accepted = true;
    }

    content: RowLayout {
        spacing: 4
        Icon {
            color: AudioService.muted ? Theme.textSecondary : Theme.textPrimary
            name: AudioService.volumeIconName(AudioService.sink)
        }
        Text {
            color: AudioService.muted ? Theme.textSecondary : Theme.textPrimary
            text: AudioService.ready ? AudioService.percent + "%" : "--%"
        }
    }

    AudioPopup {
        id: popup
        anchorItem: root
    }
}
