pragma ComponentBehavior: Bound

import QtQuick
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
        opacity: Inhibit.mode === "off" ? 0.45 : 1
        source: Qt.resolvedUrl("../assets/coffee.svg")
    }
    Popup {
        id: popup
        anchorItem: root
        Text {
            color: Theme.textPrimary
            text: "Inhibit " + Inhibit.mode
        }
    }
}
