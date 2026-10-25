pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs.components
import qs.config
import qs.services

// qmllint disable unresolved-type
Singleton {
    id: root
    property string page: "list"
    property Network selected: null
    property WifiNetwork pending: null
    property string error
    property bool findingHidden
    property string hiddenName
    property string hiddenPassword
    property var scanRequest: null
    readonly property bool busy: pending !== null || findingHidden
    readonly property list<WifiNetwork> networks: NetworkService.networks.filter(network => !network.connected).sort((a, b) => Number(b.known) - Number(a.known) || b.signalStrength - a.signalStrength)
    readonly property WifiNetwork hiddenNetwork: findingHidden ? NetworkService.networks.find(network => network.name === hiddenName) ?? null : null

    function toggle(anchorItem: Item) {
        popup.toggle(anchorItem);
    }

    function choose(network: WifiNetwork) {
        selected = network;
        error = "";
        if (!network.known && NetworkService.usesPassword(network))
            page = "password";
        else if (!network.known && ![WifiSecurityType.Open, WifiSecurityType.Owe].includes(network.security))
            error = "Configure this network's authentication in your network settings first.";
        else
            join();
    }

    function join(password = "") {
        const network = selected as WifiNetwork;
        if (network === null)
            return;
        error = "";
        if (network.connected) {
            findingHidden = false;
            if (page !== "details")
                page = "list";
            return;
        }
        pending = network;
        timeout.restart();
        if (password !== "")
            network.connectWithPsk(password);
        else
            network.connect();
    }

    function cancel() {
        const network = pending;
        pending = null;
        findingHidden = false;
        hiddenName = "";
        hiddenPassword = "";
        scanRequest = null;
        timeout.stop();
        network?.disconnect();
        page = "list";
        selected = null;
        error = "";
    }

    function fail(message: string, password = false) {
        pending = null;
        findingHidden = false;
        hiddenPassword = "";
        timeout.stop();
        error = message;
        if (password)
            page = "password";
    }

    function refresh(ssid = "") {
        const request = NetworkService.scan(ssid);
        scanRequest = request;
        error = "";
        return request.catch(error => {
            if (scanRequest === request)
                fail("Could not scan for networks: " + error.message);
        }).then(() => {
            if (scanRequest === request)
                scanRequest = null;
        });
    }

    function joinHidden(name: string, password: string) {
        hiddenName = name;
        hiddenPassword = password;
        findingHidden = true;
        timeout.restart();
        refresh(name);
    }

    function connectHidden() {
        const network = hiddenNetwork;
        if (network === null)
            return;
        const password = hiddenPassword;
        hiddenPassword = "";
        findingHidden = false;
        selected = network;
        if (password !== "" && !NetworkService.usesPassword(network)) {
            fail("This network does not use a personal Wi-Fi password.");
            return;
        }
        if (password === "" && NetworkService.usesPassword(network)) {
            fail("Enter the network's password.", true);
            return;
        }
        if (NetworkService.usesPassword(network) && !NetworkService.validPassword(network, password)) {
            fail("Use 8–63 characters, or a 64-digit hexadecimal key.", true);
            return;
        }
        join(password);
    }

    onHiddenNetworkChanged: if (hiddenNetwork !== null)
        Qt.callLater(connectHidden)
    onSelectedChanged: if (selected === null && page !== "hidden")
        page = "list"
    onBusyChanged: if (!busy)
        timeout.stop()

    Binding {
        target: NetworkService.adapter
        property: "scannerEnabled"
        value: true
        when: NetworkService.adapter !== null && Networking.wifiEnabled && (popup.visible || root.busy)
    }

    Connections {
        target: root.pending

        function onConnectedChanged() {
            if (root.pending?.connected) {
                if (root.pending.name === root.hiddenName)
                    NetworkService.markHidden(root.pending);
                root.hiddenName = "";
                root.pending = null;
                if (root.page !== "details") {
                    root.selected = null;
                    root.page = "list";
                }
                root.error = "";
            }
        }

        function onStateChanged() {
            const network = root.pending;
            if (network?.state === ConnectionState.Disconnected)
                Qt.callLater(() => {
                    if (root.pending === network)
                        root.fail("Could not connect. Please try again.");
                });
        }

        function onConnectionFailed(reason: int) {
            const password = NetworkService.usesPassword(root.pending);
            switch (reason) {
            case ConnectionFailReason.NoSecrets:
                root.fail(password ? "A password is required, or the saved password was rejected." : "This network requires additional authentication.", password);
                break;
            case ConnectionFailReason.WifiAuthTimeout:
                root.fail("Authentication timed out. Check the password and try again.", password);
                break;
            case ConnectionFailReason.WifiNetworkLost:
                root.fail("The network is no longer in range.");
                break;
            default:
                root.fail("Could not connect. Please try again.");
            }
        }
    }

    Connections {
        target: NetworkService
        function onAdapterChanged() {
            root.cancel();
        }
    }

    Connections {
        target: Networking
        function onWifiEnabledChanged() {
            if (!Networking.wifiEnabled)
                root.cancel();
        }
    }

    Timer {
        id: timeout
        interval: 90000
        onTriggered: {
            const network = root.pending;
            const message = root.findingHidden ? "Could not find this network. Check its name and try again." : "The connection timed out. Please try again.";
            root.fail(message);
            network?.disconnect();
        }
    }

    Popup {
        id: popup
        readonly property int controlSize: 32
        anchorItem: null
        contentWidth: 316
        contentMargin: 13
        onVisibleChanged: {
            if (visible && !root.busy) {
                root.page = "list";
                root.selected = null;
                root.error = "";
            }
        }
        onAnchorItemChanged: if (anchorItem === null && visible)
            close()

        ColumnLayout {
            spacing: 10

            RowLayout {
                Layout.leftMargin: root.page === "list" ? 6 : 0

                Button {
                    visible: root.page !== "list"
                    size: popup.controlSize
                    radius: height / 2
                    iconName: "go-previous-symbolic"
                    onClicked: root.page === "share" ? root.page = "details" : root.cancel()
                }

                Text {
                    Layout.fillWidth: true
                    text: root.page === "share" ? "Share network" : root.page === "details" ? "Network details" : root.page === "hidden" ? "Join other network" : root.page === "password" ? "Join network" : "Wi-Fi"
                    color: Theme.textPrimary
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Switch {
                    visible: root.page === "list"
                    checked: Networking.wifiEnabled
                    enabled: NetworkService.adapter !== null && Networking.wifiHardwareEnabled
                    onToggled: Networking.wifiEnabled = checked
                }
            }

            ColumnLayout {
                visible: root.page === "list"
                spacing: 4

                Button {
                    Layout.fillWidth: true
                    visible: NetworkService.wired !== null
                    onClicked: {
                        root.selected = NetworkService.wired.network;
                        root.page = "details";
                    }

                    contentItem: RowLayout {
                        spacing: 8
                        Icon {
                            size: popup.controlSize
                            name: "network-wired-symbolic"
                            color: Theme.textSecondary
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: "Ethernet"
                                color: Theme.textPrimary
                                font.pixelSize: 13
                            }
                            Text {
                                text: "Connected"
                                color: Theme.textSecondary
                                font.pixelSize: 11
                            }
                        }
                        Icon {
                            size: popup.controlSize
                            name: "preferences-system-symbolic"
                            color: Theme.textSecondary
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    visible: NetworkService.adapter === null || !Networking.wifiEnabled || !Networking.wifiHardwareEnabled
                    text: NetworkService.adapter === null ? "No Wi-Fi adapter" : !Networking.wifiHardwareEnabled ? "Wi-Fi is blocked" : "Wi-Fi is off"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }

                NetworkRow {
                    Layout.fillWidth: true
                    visible: network !== null
                    network: NetworkService.wifiNetwork
                    controlSize: popup.controlSize
                    enabled: !root.busy
                    onDetailsRequested: {
                        root.selected = network;
                        root.page = "details";
                    }
                }

                Separator {
                    visible: NetworkService.wifiNetwork !== null || NetworkService.wired !== null
                    Layout.topMargin: 4
                    Layout.bottomMargin: 4
                }

                RowLayout {
                    visible: NetworkService.adapter !== null && Networking.wifiEnabled && Networking.wifiHardwareEnabled
                    Layout.leftMargin: 8

                    Text {
                        Layout.fillWidth: true
                        text: "Other networks"
                        color: Theme.textSecondary
                        font.pixelSize: 13
                    }

                    Button {
                        Layout.preferredWidth: popup.controlSize
                        Layout.preferredHeight: popup.controlSize
                        Layout.rightMargin: rightPadding
                        verticalPadding: (popup.controlSize - contentItem.implicitHeight) / 2
                        enabled: root.scanRequest === null && !root.busy
                        onClicked: root.refresh()

                        contentItem: Icon {
                            name: "view-refresh-symbolic"
                            implicitSize: 16
                            spinning: root.scanRequest !== null
                            color: Theme.textSecondary
                        }

                        tooltip.text: "Scan for networks"
                    }
                }

                ListView {
                    id: networkList
                    visible: NetworkService.adapter !== null && Networking.wifiEnabled && Networking.wifiHardwareEnabled
                    model: root.networks

                    delegate: NetworkRow {
                        required property WifiNetwork modelData
                        width: networkList.contentWidth
                        network: modelData
                        controlSize: popup.controlSize
                        joining: root.pending === modelData
                        enabled: !root.busy || joining
                        onChosen: root.choose(modelData)
                        onCancelRequested: root.cancel()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    visible: networkList.visible && root.networks.length === 0
                    text: "No other networks found"
                    color: Theme.textSecondary
                    font.pixelSize: 12
                }

                Button {
                    Layout.fillWidth: true
                    visible: networkList.visible
                    enabled: !root.busy
                    text: "Join other network…"
                    font.pixelSize: 12
                    palette.buttonText: Theme.textSecondary
                    onClicked: {
                        root.selected = null;
                        root.error = "";
                        root.page = "hidden";
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.margins: 8
                    visible: root.error !== ""
                    text: root.error
                    color: Theme.warning
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.leftMargin: 8
                Layout.rightMargin: 8
                active: root.page === "password" || root.page === "hidden"
                visible: active
                sourceComponent: NetworkJoin {
                    network: root.selected as WifiNetwork
                    hidden: root.page === "hidden"
                    busy: root.busy
                    opened: popup.visible
                    error: root.error
                    onJoinRequested: (name, password) => root.page === "hidden" ? root.joinHidden(name, password) : root.join(password)
                    onCancelRequested: root.cancel()
                }
            }

            Flickable {
                visible: root.page === "details"

                NetworkDetails {
                    id: details
                    network: root.page === "details" || root.page === "share" ? root.selected : null
                    controlSize: popup.controlSize
                    opened: popup.visible && root.page === "details"
                    connectionError: root.error
                    onJoinRequested: {
                        if (wifi !== null) {
                            root.choose(wifi);
                        } else {
                            root.selected.connect();
                        }
                    }
                    onForgotten: root.cancel()
                    onShareRequested: root.page = "share"
                }
            }

            Loader {
                Layout.fillWidth: true
                active: popup.visible && root.page === "share"
                visible: active
                sourceComponent: NetworkShare {
                    network: root.selected as WifiNetwork
                    profile: details.profile
                }
            }
        }
    }
}
