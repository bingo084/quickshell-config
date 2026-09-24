import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.components.bar

RowLayout {
    spacing: 0
    Repeater {
        model: SystemTray.items
        Button {
            id: trayButton
            required property var modelData
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            horizontalPadding: 3
            onClicked: mouse => {
                PopupManager.dismiss();
                if (mouse.button === Qt.LeftButton) {
                    trayButton.modelData.activate();
                } else if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                    menuAnchor.open();
                }
            }
            content: IconImage {
                implicitSize: 18
                source: trayButton.modelData.icon
            }
            QsMenuAnchor {
                id: menuAnchor
                menu: trayButton.modelData.menu
                anchor {
                    item: trayButton
                    edges: Edges.Bottom // qmllint disable missing-type
                }
            }
        }
    }
}
