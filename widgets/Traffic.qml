import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.components
import qs.config
import qs.services

RowLayout {
    id: root
    readonly property real displayBps: Math.max(Traffic.rxBps, Traffic.txBps)

    spacing: 4
    visible: Traffic.valid && root.displayBps > 102400

    Icon {
        readonly property string direction: Traffic.rxBps === Traffic.txBps ? "transmit-receive" : Traffic.rxBps > Traffic.txBps ? "receive" : "transmit"

        implicitSize: 18
        source: Quickshell.iconPath(`network-${direction}-symbolic`)
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
