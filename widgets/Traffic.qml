import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.services

RowLayout {
    id: root
    readonly property real displayBps: Math.max(Traffic.rxBps, Traffic.txBps)
    spacing: 4
    visible: Traffic.valid && root.displayBps > 102400
    IconImage {
        implicitSize: 18
        source: Quickshell.iconPath(Traffic.rxBps === Traffic.txBps ? "network-transmit-receive-symbolic" : Traffic.rxBps > Traffic.txBps ? "network-receive-symbolic" : "network-transmit-symbolic")
    }
    Text {
        color: Theme.textPrimary
        text: {
            const useMB = root.displayBps >= 1000 * 1000;
            const divisor = useMB ? 1000 * 1000 : 1000;
            return (root.displayBps / divisor).toFixed(1) + (useMB ? " MB/s" : " KB/s");
        }
    }
}
