pragma Singleton

import Quickshell
import Quickshell.Networking

Singleton {
    id: root
    readonly property NetworkDevice wired: Networking.devices.values.find(device => device.type === DeviceType.Wired && device.connected) ?? null
    readonly property NetworkDevice wifi: Networking.devices.values.find(device => device.type === DeviceType.Wifi && device.connected) ?? null
    readonly property NetworkDevice device: wired ?? wifi
    readonly property Network network: device?.networks.values.find(network => network.connected) ?? null
}
