import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.widgets.network

BarButton {
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
        name: NetworkService.iconName()
    }
}
