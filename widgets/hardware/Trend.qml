import QtQuick
import qs.config

Item {
    id: root
    property var series: []
    property real maximum: 100
    readonly property real endTime: Math.max(0, ...series.map(values => values[values.length - 1]?.time ?? 0))
    readonly property bool hasData: series.some(values => values.some(point => point.value !== null))

    implicitHeight: 72
    onSeriesChanged: graph.requestPaint()
    onMaximumChanged: graph.requestPaint()

    Canvas {
        id: graph
        readonly property color gridColor: Theme.trackBackground
        readonly property color lineColor: Theme.accent
        readonly property color secondLineColor: Theme.textSecondary

        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onGridColorChanged: requestPaint()
        onLineColorChanged: requestPaint()
        onSecondLineColorChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            ctx.strokeStyle = gridColor;
            ctx.lineWidth = 1;
            for (const fraction of [0, 0.5, 1]) {
                const y = 0.5 + fraction * (height - 1);
                ctx.beginPath();
                ctx.moveTo(0, y);
                ctx.lineTo(width, y);
                ctx.stroke();
            }
            root.series.forEach((values, index) => {
                if (values.length < 2)
                    return;

                ctx.strokeStyle = index === 0 ? lineColor : secondLineColor;
                ctx.lineWidth = 1.5;
                ctx.lineJoin = "round";
                ctx.beginPath();
                let previous = null;
                values.forEach(point => {
                    if (point.value === null) {
                        previous = null;
                        return;
                    }
                    const x = (point.time - (root.endTime - 60000)) * width / 60000;
                    const y = 1 + (1 - Math.max(0, Math.min(1, point.value / root.maximum))) * (height - 2);
                    if (previous === null || point.time - previous.time > 5000)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                    previous = point;
                });
                ctx.stroke();
            });
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !root.hasData
        color: Theme.textSecondary
        text: "—"
    }
}
