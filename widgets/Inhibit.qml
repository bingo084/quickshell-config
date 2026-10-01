pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.components
import qs.components.bar
import qs.config
import qs.services

Button {
    id: root
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.visible = !popup.visible;
        } else if (mouse.button === Qt.RightButton) {
            if (PopupManager.activePopup !== popup)
                PopupManager.dismiss();
            Inhibit.cycle();
        }
    }
    content: Icon {
        implicitSize: 18
        color: Inhibit.mode === "off" ? Theme.textPrimary : Inhibit.mode === "sleep" ? Theme.warning : Theme.critical
        source: Qt.resolvedUrl("../assets/coffee.svg")
    }
    Popup {
        id: popup
        anchorItem: root
        ColumnLayout {
            Controls.RadioButton {
                text: "Off"
                checked: Inhibit.mode === "off"
                onClicked: Inhibit.setMode("off")
            }
            Controls.RadioButton {
                text: "Prevent Sleep"
                checked: Inhibit.mode === "sleep"
                onClicked: Inhibit.setMode("sleep")
            }
            Controls.RadioButton {
                text: "Prevent Idle"
                checked: Inhibit.mode === "idle"
                onClicked: Inhibit.setMode("idle")
            }
        }
    }
}
