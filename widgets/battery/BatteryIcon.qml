import QtQuick
import Quickshell.Services.UPower
import qs.components

Icon {
    required property UPowerDevice device

    color: "transparent"
    name: {
        if (!device.ready || (device.type === UPowerDeviceType.Battery && !device.isPresent))
            return device.iconName || "battery-missing-symbolic";
        if (device.state === UPowerDeviceState.FullyCharged)
            return "battery-level-100-charged-symbolic";
        const level = Math.round(device.percentage * 10) * 10;
        if (device.state === UPowerDeviceState.Charging || device.state === UPowerDeviceState.PendingCharge)
            return "battery-level-" + Math.min(90, level) + "-charging-symbolic";
        return "battery-level-" + level + "-symbolic";
    }
}
