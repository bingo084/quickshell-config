import QtQuick
import Quickshell
import qs.components
import qs.components.bar
import qs.services
import qs.widgets.network

Button {
    id: root
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            NetworkPopup.toggle(root);
        } else {
            PopupHost.close();
            Quickshell.execDetached(["nm-connection-editor"]);
        }
    }

    content: Icon {
        name: Network.iconName()
    }
}
