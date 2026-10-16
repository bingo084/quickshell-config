pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Widgets
import qs.components
import qs.config

// qmllint disable unresolved-type
ColumnLayout {
    id: root
    required property BluetoothDevice device
    required property int controlSize
    readonly property bool busy: device?.state === BluetoothDeviceState.Connecting || device?.state === BluetoothDeviceState.Disconnecting
    property bool editing: false
    property bool confirming: false
    signal backRequested

    spacing: 4
    enabled: device !== null

    ColumnLayout {
        Layout.bottomMargin: 6
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 8

        Icon {
            Layout.alignment: Qt.AlignHCenter
            implicitSize: root.controlSize
            name: (root.device?.icon || "bluetooth") + "-symbolic"
            pulsing: root.busy
            color: Theme.textSecondary
        }

        Item {
            visible: !root.editing
            Layout.fillWidth: true
            implicitHeight: Math.max(deviceName.implicitHeight, editButton.implicitHeight)

            Text {
                id: deviceName
                anchors.centerIn: parent
                width: Math.min(implicitWidth, parent.width - 2 * (editButton.width + editButton.anchors.leftMargin))
                text: root.device?.name || root.device?.address || ""
                font.pixelSize: 15
                font.bold: true
                color: Theme.textPrimary
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter

                Tooltip {
                    anchorItem: deviceName
                    text: deviceName.text
                    enabled: deviceName.truncated
                }
            }

            Button {
                id: editButton
                anchors.left: deviceName.right
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                iconName: "edit-symbolic"
                icon.width: 14
                icon.height: 14
                palette.buttonText: Theme.textSecondary
                onClicked: {
                    nameField.text = root.device.name;
                    root.editing = true;
                    Qt.callLater(() => {
                        nameField.forceActiveFocus();
                        nameField.selectAll();
                    });
                }
            }
        }

        RowLayout {
            visible: root.editing
            spacing: 4

            Controls.TextField {
                id: nameField
                Layout.fillWidth: true
                color: Theme.textPrimary
                font.pixelSize: 15

                function save() {
                    const value = text.trim();
                    if (value === "")
                        return;
                    root.device.name = value === root.device.deviceName ? "" : value;
                    root.editing = false;
                }

                onAccepted: save()
                Keys.onEscapePressed: root.editing = false

                background: Rectangle {
                    radius: 5
                    color: Theme.controlBackground
                    border.color: nameField.activeFocus ? Theme.accent : Theme.popupBorder
                }
            }

            Button {
                id: restoreControl
                iconName: "edit-undo-symbolic"
                enabled: nameField.text.trim() !== (root.device?.deviceName ?? "")
                onClicked: {
                    nameField.text = root.device.deviceName;
                    nameField.forceActiveFocus();
                }

                Tooltip {
                    anchorItem: restoreControl
                    text: "Restore “" + (root.device?.deviceName ?? "") + "”"
                }
            }

            Button {
                iconName: "object-select-symbolic"
                enabled: nameField.text.trim() !== ""
                onClicked: nameField.save()
            }

            Button {
                iconName: "window-close-symbolic"
                onClicked: root.editing = false
            }
        }

        Button {
            variant: Button.Filled
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: 12
            text: {
                if (root.device?.blocked)
                    return "Blocked";
                if (root.busy)
                    return BluetoothDeviceState.toString(root.device.state) + "…";
                return root.device?.connected ? "Disconnect" : "Connect";
            }
            enabled: root.device?.adapter?.state === BluetoothAdapterState.Enabled && !root.busy && !root.device.blocked
            onClicked: root.device.connected ? root.device.disconnect() : root.device.connect()
        }
    }

    Separator {
        Layout.topMargin: 4
        Layout.bottomMargin: 4
    }

    RowLayout {
        visible: root.device?.batteryAvailable ?? false
        Layout.minimumHeight: root.controlSize
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 4

        Text {
            Layout.fillWidth: true
            text: "Battery"
            font.pixelSize: 12
            color: Theme.textPrimary
        }

        Icon {
            implicitSize: 16
            name: "battery-level-" + Math.round((root.device?.battery ?? 0) * 10) * 10 + "-symbolic"
            color: Theme.textSecondary
        }

        Text {
            text: Math.round((root.device?.battery ?? 0) * 100) + "%"
            font.pixelSize: 12
            color: Theme.textSecondary
        }
    }

    RowLayout {
        Layout.minimumHeight: root.controlSize
        Layout.leftMargin: 8
        Layout.rightMargin: 8

        Text {
            Layout.fillWidth: true
            text: "Address"
            color: Theme.textPrimary
            font.pixelSize: 12
        }

        Button {
            Layout.rightMargin: -rightPadding
            text: root.device?.address ?? ""
            font.pixelSize: 11
            palette.buttonText: Theme.textSecondary
            iconName: copyFeedback.running ? "object-select-symbolic" : "edit-copy-symbolic"
            onClicked: {
                Quickshell.clipboardText = root.device.address;
                copyFeedback.restart();
            }

            Timer {
                id: copyFeedback
                interval: 1500
            }
        }
    }

    Separator {
        Layout.topMargin: 4
        Layout.bottomMargin: 4
    }

    Switch {
        Layout.fillWidth: true
        horizontalPadding: 8
        font.pixelSize: 12
        text: "Trust this device"
        checked: root.device?.trusted ?? false
        onToggled: root.device.trusted = checked
    }

    Switch {
        Layout.fillWidth: true
        horizontalPadding: 8
        font.pixelSize: 12
        text: "Allow wake"
        checked: root.device?.wakeAllowed ?? false
        onToggled: root.device.wakeAllowed = checked
    }

    Switch {
        Layout.fillWidth: true
        horizontalPadding: 8
        font.pixelSize: 12
        text: "Block connections"
        checked: root.device?.blocked ?? false
        onToggled: root.device.blocked = checked
    }

    Button {
        id: forgetButton
        Layout.fillWidth: true
        visible: !root.confirming
        leftPadding: 8
        rightPadding: 8
        text: "Forget device"
        font.pixelSize: 12
        palette.buttonText: Theme.critical
        onClicked: root.confirming = true

        contentItem: Text {
            text: forgetButton.text
            font: forgetButton.font
            color: forgetButton.palette.buttonText
        }
    }

    WrapperRectangle {
        Layout.fillWidth: true
        visible: root.confirming
        margin: 12
        radius: 8
        color: Qt.alpha(Theme.textPrimary, 0.04)

        ColumnLayout {
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Forget this device? You'll need to pair it again."
                wrapMode: Text.Wrap
                color: Theme.textPrimary
                font.pixelSize: 12
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight

                Button {
                    text: "Cancel"
                    font.pixelSize: 12
                    onClicked: root.confirming = false
                }

                Button {
                    text: "Forget"
                    font.pixelSize: 12
                    palette.buttonText: Theme.critical
                    onClicked: {
                        root.device.forget();
                        root.backRequested();
                    }
                }
            }
        }
    }
}
