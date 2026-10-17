pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.components
import qs.components.bar as Bar
import qs.config

// qmllint disable unresolved-type
Singleton {
    id: root
    readonly property BluetoothAdapter adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter?.devices.values.filter(device => device.paired || device.connected).sort((a, b) => Number(b.connected) - Number(a.connected)) ?? [] // qmllint disable missing-property
    property BluetoothDevice selected: null
    property BluetoothDevice pairingDevice: null
    property bool adding: false
    readonly property bool visible: popup.visible
    readonly property bool pairing: (pairingPage.item as DevicePairing)?.busy ?? false

    function toggle(anchorItem: Item) {
        popup.toggle(anchorItem);
    }

    function sync() {
        if (!visible || !adding || pairingDevice !== null || adapter?.state !== BluetoothAdapterState.Enabled) {
            release();
            return;
        }
        if (adapter.discovering)
            return;
        state.requested = true;
        adapter.discovering = true;
    }

    function release() {
        if (!state.requested)
            return;
        if (adapter === null || adapter.state !== BluetoothAdapterState.Enabled) {
            state.requested = false;
            return;
        }
        // A pending start can finish after the page closes. Release it when Discovering arrives.
        if (!adapter.discovering)
            return;
        state.requested = false;
        adapter.discovering = false;
    }

    onVisibleChanged: {
        if (visible && pairingDevice === null) {
            selected = null;
            adding = false;
        }
        sync();
    }
    onAddingChanged: sync()
    onPairingDeviceChanged: sync()
    onAdapterChanged: {
        selected = null;
        pairingDevice = null;
        adding = false;
        sync();
    }
    onDevicesChanged: {
        if (selected !== null && !devices.includes(selected))
            selected = null;
    }
    Component.onDestruction: release()

    PersistentProperties {
        id: state
        reloadableId: "bluetooth-discovery"
        property bool requested: false
        onLoaded: root.sync()
    }

    Connections {
        target: root.adapter
        function onDiscoveringChanged() {
            root.sync();
        }
        function onStateChanged() {
            root.sync();
        }
    }

    Bar.Popup {
        id: popup
        readonly property int controlSize: 32

        anchorItem: null
        contentWidth: 316
        contentMargin: 13
        focusable: true
        onAnchorItemChanged: {
            if (anchorItem === null && visible)
                close();
        }

        ColumnLayout {
            spacing: 10

            ColumnLayout {
                Layout.leftMargin: 6
                visible: root.selected === null && !root.adding
                spacing: 12

                RowLayout {
                    Text {
                        Layout.fillWidth: true
                        text: "Bluetooth"
                        color: Theme.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Switch {
                        checked: root.adapter?.enabled ?? false
                        enabled: root.adapter !== null && (root.adapter.state === BluetoothAdapterState.Enabled || root.adapter.state === BluetoothAdapterState.Disabled)
                        onToggled: root.adapter.enabled = checked
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.adapter?.state !== BluetoothAdapterState.Enabled || root.devices.length === 0
                    color: root.adapter?.state === BluetoothAdapterState.Blocked ? Theme.warning : Theme.textSecondary
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                    text: {
                        if (root.adapter === null)
                            return "No Bluetooth adapter";
                        switch (root.adapter.state) {
                        case BluetoothAdapterState.Disabled:
                            return "Bluetooth is off";
                        case BluetoothAdapterState.Enabling:
                            return "Turning on…";
                        case BluetoothAdapterState.Disabling:
                            return "Turning off…";
                        case BluetoothAdapterState.Blocked:
                            return "Bluetooth is blocked";
                        default:
                            return "No paired devices";
                        }
                    }
                }
            }

            RowLayout {
                visible: root.selected !== null || root.adding

                Button {
                    Layout.alignment: Qt.AlignBaseline
                    Layout.preferredWidth: popup.controlSize
                    Layout.preferredHeight: popup.controlSize
                    font: title.font
                    radius: height / 2
                    iconName: "go-previous-symbolic"
                    enabled: !root.pairing
                    onClicked: {
                        if (root.pairingDevice !== null) {
                            root.pairingDevice = null;
                            return;
                        }
                        root.selected = null;
                        root.adding = false;
                    }
                }

                Text {
                    id: title
                    Layout.alignment: Qt.AlignBaseline
                    text: root.pairingDevice !== null ? "Pair device" : root.selected !== null ? "Device details" : "Add device"
                    font.pixelSize: 14
                    font.bold: true
                    color: Theme.textPrimary
                }
            }

            ListView {
                id: deviceList
                Layout.fillWidth: true
                visible: root.selected === null && !root.adding && root.adapter?.state === BluetoothAdapterState.Enabled && root.devices.length > 0
                implicitHeight: Math.min(contentHeight, 310)
                clip: true
                spacing: 4
                model: root.devices
                Controls.ScrollBar.vertical: Controls.ScrollBar {}

                delegate: DeviceRow {
                    required property BluetoothDevice modelData
                    width: deviceList.width
                    device: modelData
                    controlSize: popup.controlSize
                    onDetailsRequested: root.selected = modelData
                }
            }

            Separator {
                visible: root.selected === null && !root.adding
            }

            Button {
                id: addButton
                Layout.fillWidth: true
                visible: root.selected === null && !root.adding
                enabled: root.adapter?.state === BluetoothAdapterState.Enabled
                text: "Add device"
                verticalPadding: 2
                onClicked: root.adding = true

                contentItem: RowLayout {
                    spacing: 8

                    Icon {
                        Layout.alignment: Qt.AlignBaseline
                        padding: (popup.controlSize - implicitSize) / 2
                        font: addText.font
                        name: "list-add-symbolic"
                        color: Theme.textSecondary
                    }

                    Text {
                        id: addText
                        Layout.alignment: Qt.AlignBaseline
                        Layout.fillWidth: true
                        text: addButton.text
                        font.pixelSize: 13
                        color: Theme.textPrimary
                    }
                }
            }

            DeviceDiscovery {
                visible: root.adding && root.selected === null && root.pairingDevice === null
                adapter: root.adapter
                controlSize: popup.controlSize
                scanning: root.visible && root.adding && (root.adapter?.discovering ?? false)
                onPairRequested: device => root.pairingDevice = device
            }

            Loader {
                id: pairingPage
                Layout.fillWidth: true
                active: root.pairingDevice !== null
                visible: active
                sourceComponent: DevicePairing {
                    device: root.pairingDevice
                    controlSize: popup.controlSize
                    opened: root.visible
                    onPaired: {
                        root.adding = false;
                        root.pairingDevice = null;
                    }
                    onCancelled: root.pairingDevice = null
                }
            }

            Flickable {
                Layout.fillWidth: true
                visible: root.selected !== null
                implicitHeight: Math.min(details.implicitHeight, 460)
                contentHeight: details.implicitHeight
                clip: true
                Controls.ScrollBar.vertical: Controls.ScrollBar {}

                Loader {
                    id: details
                    width: parent.width
                    active: root.selected !== null
                    sourceComponent: DeviceDetails {
                        device: root.selected
                        controlSize: popup.controlSize
                        onBackRequested: root.selected = null
                    }
                }
            }
        }
    }
}
