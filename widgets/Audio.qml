import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.bar as Bar
import qs.config
import qs.services
import qs.widgets.audio

Bar.Button {
    id: root

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.toggle();
        } else {
            popup.closeAll();
            Audio.toggleMuted();
        }
    }
    onWheel: wheel => {
        Audio.adjustVolume(wheel.angleDelta.y > 0 ? 0.01 : -0.01);
        wheel.accepted = true;
    }

    content: RowLayout {
        spacing: 4
        Icon {
            color: Audio.muted ? Theme.textSecondary : Theme.textPrimary
            name: Audio.volumeIconName(Audio.sink)
        }
        Text {
            color: Audio.muted ? Theme.textSecondary : Theme.textPrimary
            text: Audio.ready ? Audio.percent + "%" : "--%"
        }
    }

    AudioPopup {
        id: popup
        anchorItem: root
    }
}
