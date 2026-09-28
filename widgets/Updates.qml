pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.bar
import qs.config
import qs.services

Button {
    id: root
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    visible: Updates.checking || Updates.error !== "" || Updates.count > 0
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            if (PopupManager.activePopup !== popup)
                PopupManager.dismiss();
            Updates.refresh();
        } else {
            popup.visible = !popup.visible;
        }
    }
    content: RowLayout {
        spacing: 4
        IconImage {
            id: refreshIcon
            implicitSize: 18
            source: Quickshell.iconPath("emblem-synchronizing-symbolic")
            RotationAnimator {
                target: refreshIcon
                from: 0
                to: 360
                duration: 1300
                loops: Animation.Infinite
                running: Updates.checking
            }
        }
        Text {
            color: Updates.error !== "" ? Theme.warning : Theme.textPrimary
            text: Updates.count
        }
    }
    Popup {
        id: popup
        anchorItem: root
        ColumnLayout {
            Text {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: Updates.error !== ""
                text: Updates.error
                color: Theme.warning
                wrapMode: Text.Wrap
            }
            Text {
                visible: Updates.count === 0 && Updates.error === ""
                text: "No updates"
                color: Theme.textPrimary
            }
            ListView {
                id: packageList
                implicitWidth: 420
                implicitHeight: Math.min(contentHeight, 320)
                clip: true
                spacing: 4
                model: Updates.packages
                delegate: RowLayout {
                    id: packageRow
                    required property var modelData
                    width: packageList.width
                    height: 24
                    spacing: 8
                    Text {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 2
                        elide: Text.ElideRight
                        color: Theme.textPrimary
                        text: packageRow.modelData.name
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        elide: Text.ElideRight
                        color: Theme.textPrimary
                        text: packageRow.modelData.oldVersion
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        elide: Text.ElideRight
                        color: Theme.textPrimary
                        text: packageRow.modelData.newVersion
                    }
                }
            }
        }
    }
}
