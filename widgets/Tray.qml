import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import qs.components
import qs.components.bar
import qs.widgets.tray

RowLayout {
    spacing: 0

    Repeater {
        model: SystemTray.items

        Button {
            id: trayButton
            required property SystemTrayItem modelData

            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            horizontalPadding: 3
            onClicked: mouse => {
                PopupHost.close();
                if (mouse.button === Qt.LeftButton) {
                    if (modelData.hasMenu && modelData.onlyMenu) {
                        menu.popup(trayButton, 0, trayButton.height);
                    } else {
                        modelData.activate();
                    }
                } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                    menu.popup(trayButton, 0, trayButton.height);
                } else if (mouse.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                }
            }
            content: Icon {
                colorize: false
                source: trayButton.modelData.icon
            }
            TrayMenu {
                id: menu
                handle: trayButton.modelData.menu
            }
        }
    }
}
