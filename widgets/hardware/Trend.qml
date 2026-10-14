import QtQuick
import qs.config

Item {
    id: root
    property var series: []
    property real maximum: 100

    implicitHeight: 72
    onSeriesChanged: graph.requestPaint()
    onMaximumChanged: graph.requestPaint()

    Canvas {
        id: graph
        readonly property color gridColor: Theme.meterBackground
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
                values.forEach((value, point) => {
                    const x = point * width / (values.length - 1);
                    const y = 1 + (1 - Math.max(0, Math.min(1, value / root.maximum))) * (height - 2);
                    if (point === 0)
                        ctx.moveTo(x, y);
                    else
                        ctx.lineTo(x, y);
                });
                ctx.stroke();
            });
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.series.length === 0
        color: Theme.textSecondary
        text: "—"
    }
}
