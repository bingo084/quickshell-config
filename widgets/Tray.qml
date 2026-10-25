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
                if (modelData.hasMenu && (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && modelData.onlyMenu))) {
                    TrayMenu.toggle(modelData.menu, trayButton);
                    return;
                }
                PopupHost.close();
                if (mouse.button === Qt.LeftButton)
                    modelData.activate();
                else if (mouse.button === Qt.MiddleButton)
                    modelData.secondaryActivate();
            }
            content: Icon {
                color: "transparent"
                theme: "hicolor"
                source: trayButton.modelData.icon
            }
        }
    }
}
