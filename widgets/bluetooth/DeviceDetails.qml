pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

            TextField {
                id: nameField
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
            }

            Button {
                iconName: "edit-undo-symbolic"
                enabled: nameField.text.trim() !== (root.device?.deviceName ?? "")
                onClicked: {
                    nameField.text = root.device.deviceName;
                    nameField.forceActiveFocus();
                }

                tooltip.text: "Restore “" + (root.device?.deviceName ?? "") + "”"
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

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 10

            Button {
                size: root.controlSize
                variant: Button.Filled
                iconName: root.device?.connected ? "entries-unlinked-symbolic" : "entries-linked-symbolic"
                enabled: root.device?.adapter?.state === BluetoothAdapterState.Enabled && !root.busy && !root.device.blocked
                onClicked: root.device.connected ? root.device.disconnect() : root.device.connect()
                tooltip.text: root.device?.blocked ? "Blocked" : root.busy ? BluetoothDeviceState.toString(root.device.state) + "…" : root.device?.connected ? "Disconnect" : "Connect"
            }

            Button {
                size: root.controlSize
                variant: Button.Filled
                enabled: !root.confirming
                iconName: "user-trash-symbolic"
                palette.buttonText: Theme.critical
                onClicked: root.confirming = true
                tooltip.text: "Forget device"
            }
        }
    }

    WrapperRectangle {
        Layout.fillWidth: true
        visible: root.confirming
        margin: 12
        radius: 8
        color: Theme.controlBackground

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

    Separator {
        Layout.topMargin: 4
        Layout.bottomMargin: 4
    }

    ColumnLayout {
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        spacing: 0

        TextMetrics {
            id: labelMetrics
            text: "Address"
            font.pixelSize: 12
        }

        RowLayout {
            visible: root.device?.batteryAvailable ?? false
            Layout.minimumHeight: root.controlSize
            spacing: 8

            Text {
                Layout.minimumWidth: Math.ceil(labelMetrics.advanceWidth)
                text: "Battery"
                font.pixelSize: 12
                color: Theme.textPrimary
            }

            CopyButton {
                Layout.rightMargin: -rightPadding
                iconName: "battery-level-" + Math.round((root.device?.battery ?? 0) * 10) * 10 + "-symbolic"
                icon.color: "transparent"
                text: Math.round((root.device?.battery ?? 0) * 100) + "%"
                palette.buttonText: Theme.textSecondary
            }
        }

        RowLayout {
            Layout.minimumHeight: root.controlSize
            spacing: 8

            Text {
                Layout.minimumWidth: Math.ceil(labelMetrics.advanceWidth)
                text: "Address"
                color: Theme.textPrimary
                font.pixelSize: 12
            }

            CopyButton {
                Layout.rightMargin: -rightPadding
                text: root.device?.address ?? ""
                palette.buttonText: Theme.textSecondary
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
}
