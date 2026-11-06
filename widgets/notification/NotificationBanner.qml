pragma ComponentBehavior: Bound

import QtQuick
import qs.services

NotificationCard {
    id: root
    property real progress: 0
    readonly property real timeout: record.timeout
    signal finished

    opacity: progress
    x: 18 * (1 - progress)
    enabled: !record.bannerClosing
    onDismissRequested: NotificationService.dismiss(record)
    Component.onCompleted: motion.start()

    Connections {
        target: root.record
        function onBannerClosingChanged() {
            motion.restart();
        }
        function onRefreshed() {
            root.expanded = false;
            if (hideTimer.running)
                hideTimer.restart();
        }
    }
    Timer {
        id: hideTimer
        interval: Math.max(1, root.timeout)
        running: root.timeout > 0 && !root.hovering && !root.expanded && !root.record.bannerClosing
        onTriggered: root.record.hideBanner()
    }
    NumberAnimation {
        id: motion
        target: root
        property: "progress"
        to: root.record.bannerClosing ? 0 : 1
        duration: root.record.bannerClosing ? 160 : 180
        easing.type: Easing.OutCubic
        onFinished: {
            if (root.record.bannerClosing)
                root.finished();
        }
    }
}
