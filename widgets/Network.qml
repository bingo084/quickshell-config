import Quickshell
import Quickshell.Widgets
import Quickshell.Networking as Net
import qs.services

IconImage {
    id: root
    readonly property Net.WifiNetwork wifiNetwork: Network.network as Net.WifiNetwork
    implicitSize: 18
    source: {
        if (Network.wired)
            return Quickshell.iconPath("network-wired-symbolic");
        if (root.wifiNetwork) {
            const strength = root.wifiNetwork.signalStrength;
            const level = strength < 0.25 ? "weak" : strength < 0.5 ? "ok" : strength < 0.75 ? "good" : "excellent";
            return Quickshell.iconPath(`network-wireless-signal-${level}-symbolic`);
        }
        return Quickshell.iconPath("network-wireless-disconnected-symbolic");
    }
}
