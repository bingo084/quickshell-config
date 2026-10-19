import Quickshell.Services.UPower
import qs.components

SegmentedControl {
    id: root

    implicitHeight: 40
    currentIndex: PowerProfiles.profile
    onActivated: index => PowerProfiles.profile = root.model[index].profile
    model: [
        {
            tooltip: "Power Saver",
            icon: "power-saver-symbolic",
            profile: PowerProfile.PowerSaver
        },
        {
            tooltip: "Balanced",
            icon: "power-balanced-symbolic",
            profile: PowerProfile.Balanced
        },
        {
            tooltip: "Performance",
            icon: "power-performance-symbolic",
            profile: PowerProfile.Performance,
            enabled: PowerProfiles.hasPerformanceProfile
        }
    ]
}
