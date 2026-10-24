import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.components
import qs.widgets.tray

RowLayout {
    spacing: 0

    Repeater {
        model: SystemTray.items

        BarButton {
            id: trayButton
            required property SystemTrayItem modelData

            visible: modelData.id !== "nm-applet"
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            horizontalPadding: 3
            onClicked: mouse => {
                PopupHost.close();
                if (mouse.button === Qt.LeftButton) {
                    if (modelData.hasMenu && modelData.onlyMenu) {
                        TrayMenu.toggle(modelData.menu, trayButton);
                    } else {
                        modelData.activate();
                    }
                } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                    TrayMenu.toggle(modelData.menu, trayButton);
                } else if (mouse.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                }
            }
            content: Icon {
                color: "transparent"
                theme: "hicolor"
                source: trayButton.modelData.icon
            }
        }
    }
}
