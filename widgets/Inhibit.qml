pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Widgets
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
    content: IconImage {
        implicitSize: 18
        source: Qt.resolvedUrl("../assets/coffee.svg")
        layer.enabled: true
        layer.effect: MultiEffect {
            contrast: -1
            brightness: 0.5
            colorization: 1
            colorizationColor: Inhibit.mode === "sleep" ? Theme.warning : Inhibit.mode === "idle" ? Theme.critical : Theme.textPrimary
        }
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
