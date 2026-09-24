import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components.bar

RowLayout {
    Repeater {
        model: SystemTray.items

        Button {
            id: trayButton
            required property var modelData
            onClicked: {
                PopupManager.dismiss();
                trayButton.modelData.activate();
            }
            content: IconImage {
                implicitSize: 18
                source: trayButton.modelData.icon
            }
        }
    }
}
