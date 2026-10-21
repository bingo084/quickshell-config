import QtQuick
import QtQuick.Layouts
import qs.components
import qs.config
import qs.services

RowLayout {
    id: root
    readonly property real displayBps: Math.max(TrafficService.rxBps, TrafficService.txBps)

    spacing: 4
    visible: TrafficService.valid && root.displayBps > 102400

    Icon {
        readonly property string direction: TrafficService.rxBps === TrafficService.txBps ? "transmit-receive" : TrafficService.rxBps > TrafficService.txBps ? "receive" : "transmit"

        name: `network-${direction}-symbolic`
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
