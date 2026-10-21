pragma Singleton

import QtQml
import Quickshell
import Quickshell.Networking

Singleton {
    id: root
    readonly property WifiDevice adapter: (Networking.devices.values.find(device => device.type === DeviceType.Wifi && device.connected) ?? Networking.devices.values.find(device => device.type === DeviceType.Wifi)) ?? null // qmllint disable missing-property
    readonly property WiredDevice wired: Networking.devices.values.find(device => device.type === DeviceType.Wired && device.connected) ?? null // qmllint disable missing-property
    readonly property WifiDevice wifi: adapter?.connected ? adapter : null
    readonly property list<WifiNetwork> networks: adapter?.networks.values ?? [] // qmllint disable missing-property
    readonly property WifiNetwork wifiNetwork: wifi?.networks.values.find(network => network.connected) ?? null // qmllint disable missing-property
    readonly property NetworkDevice device: wired ?? wifi
    readonly property bool online: device !== null && (!Networking.connectivityCheckEnabled || Networking.connectivity === NetworkConnectivity.Full)
    property var wifiLink: null
    property var wifiRequest: null
    signal ready

    onOnlineChanged: {
        if (online)
            refreshDelay.restart();
        else
            refreshDelay.stop();
    }
    onWifiNetworkChanged: {
        wifiLink = null;
        refreshWifiLink();
    }

    function queryDetails(device: NetworkDevice): var {
        return CommandService.run(["env", "LC_ALL=C", "nmcli", "--terse", "--escape", "no", "--fields", "GENERAL.CON-UUID,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS,AP.IN-USE,AP.SECURITY", "device", "show", device.name]).then(result => {
            if (result.exitCode !== 0)
                throw new Error(result.stderr.trim());
            const details = parseDetails(result.stdout);
            const active = Object.keys(details).find(key => key.endsWith(".IN-USE") && details[key][0] === "*");
            if (active)
                details["WIFI.SECURITY"] = details[active.replace(".IN-USE", ".SECURITY")];
            return details;
        });
    }

    function scan(ssid = ""): var {
        const command = ["nmcli", "device", "wifi", "rescan", "ifname", adapter.name];
        if (ssid !== "")
            command.push("ssid", ssid);
        return CommandService.run(command).then(result => {
            if (result.exitCode !== 0)
                throw new Error(result.stderr.trim());
        });
    }

    function queryShare(network: WifiNetwork, profile): var {
        const name = network.name;
        const secured = usesPassword(network);
        const hidden = profile?.read()?.["802-11-wireless"]?.hidden ?? false;
        const password = secured ? CommandService.run(["nmcli", "--show-secrets", "--escape", "no", "--get-values", "802-11-wireless-security.psk", "connection", "show", "uuid", profile.uuid]).then(result => {
            if (result.exitCode !== 0)
                throw new Error("Could not read the saved Wi-Fi password.");
            const password = result.stdout.replace(/\n$/, "");
            if (password === "")
                throw new Error("No saved password is available for this network.");
            return password;
        }) : Promise.resolve("");
        return password.then(password => {
            const escape = value => /^[0-9a-f]+$/i.test(value) ? '"' + value + '"' : value.replace(/[\\;,:\"]/g, "\\$&");
            const content = `WIFI:T:${secured ? "WPA" : "nopass"};S:${escape(name)};P:${escape(password)};H:${hidden};;`;
            return CommandService.run(["qrencode", "--type", "SVG", "--level", "M", "--output", "-", content]).then(result => {
                if (result.exitCode !== 0)
                    throw new Error("Could not generate the Wi-Fi QR code.");
                return {
                    password,
                    image: "data:image/svg+xml," + encodeURIComponent(result.stdout)
                };
            });
        });
    }

    function iconName(network = root.wired?.network ?? root.wifiNetwork): string {
        if (network === null)
            return "network-wireless-disconnected-symbolic";
        if (network.device.type === DeviceType.Wired)
            return "network-wired-symbolic";
        const wifi = network as WifiNetwork;
        const strength = wifi.signalStrength;
        const level = strength < 0.25 ? "weak" : strength < 0.5 ? "ok" : strength < 0.75 ? "good" : "excellent";
        return `network-wireless-signal-${level}-symbolic`;
    }

    function usesPassword(network: WifiNetwork): bool {
        return [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(network.security);
    }

    function validPassword(network: WifiNetwork, password: string): bool {
        if (network?.security === WifiSecurityType.Sae)
            return password.length > 0;
        return password.length >= 8 && password.length <= 63 || /^[0-9a-fA-F]{64}$/.test(password);
    }

    function markHidden(network: WifiNetwork) {
        queryDetails(network.device).then(details => {
            const profile = network.nmSettings.find(profile => profile.uuid === details["GENERAL.CON-UUID"]?.[0]);
            profile?.write({
                "802-11-wireless": {
                    hidden: true
                }
            });
        }).catch(error => console.warn("Could not save hidden network settings:", error.message));
    }

    function refreshWifiLink() {
        if (!root.wifiNetwork) {
            root.wifiRequest = null;
            root.wifiLink = null;
            return;
        }
        const request = CommandService.run(["iw", "dev", root.wifi.name, "link"]);
        root.wifiRequest = request;
        return request.then(result => {
            if (root.wifiRequest !== request)
                return;
            if (result.exitCode !== 0)
                throw new Error(result.stderr.trim());
            root.wifiLink = parseWifiLink(result.stdout);
            root.wifiRequest = null;
        }).catch(error => {
            if (root.wifiRequest !== request)
                return;
            root.wifiLink = null;
            root.wifiRequest = null;
            console.warn("Wi-Fi link query failed:", error.message);
        });
    }

    function parseWifiLink(text: string): var {
        const details = parseDetails(text);
        const tx = details["tx bitrate"]?.[0] ?? "";
        const rx = details["rx bitrate"]?.[0] ?? "";
        const rates = tx + " " + rx;
        const speed = Number.parseFloat(tx);
        const frequency = Number(details.freq?.[0] ?? 0);
        return {
            speed: Number.isFinite(speed) ? speed : -1,
            band: frequency >= 2400 && frequency < 2500 ? "2.4 GHz" : frequency >= 4900 && frequency < 5925 ? "5 GHz" : frequency >= 5925 && frequency <= 7125 ? "6 GHz" : "",
            standard: rates.includes("EHT-MCS") ? "Wi-Fi 7" : rates.includes("HE-MCS") ? "Wi-Fi 6" : rates.includes("VHT-MCS") ? "Wi-Fi 5" : /\bMCS\b/.test(rates) ? "Wi-Fi 4" : ""
        };
    }

    function parseDetails(text: string): var {
        const result = {};
        for (const line of text.split("\n")) {
            const colon = line.indexOf(":");
            if (colon < 0)
                continue;
            const key = line.slice(0, colon).trim().replace(/\[\d+\]$/, "");
            const value = line.slice(colon + 1).trim();
            if (value === "")
                continue;
            if (!result[key])
                result[key] = [];
            result[key].push(value);
        }
        return result;
    }

    Timer {
        id: refreshDelay
        interval: 2000
        onTriggered: root.ready()
    }
}
