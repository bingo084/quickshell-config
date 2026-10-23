import QtQuick
import qs.config

Item {
    id: root

    required property real fraction
    required property bool valid
    property int level

    implicitWidth: 64
    implicitHeight: 64
    onFractionChanged: ring.requestPaint()
    onValidChanged: ring.requestPaint()

    Canvas {
        id: ring

        readonly property color trackColor: Theme.trackBackground
        readonly property color fillColor: Theme.levelColor(root.level, Theme.accent)

        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onTrackColorChanged: requestPaint()
        onFillColorChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const radius = Math.min(width, height) / 2 - 3;
            ctx.lineWidth = 4;
            ctx.strokeStyle = trackColor;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, radius, 0, 2 * Math.PI);
            ctx.stroke();
            if (!root.valid || root.fraction <= 0)
                return;

            ctx.strokeStyle = fillColor;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, radius, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.min(1, root.fraction));
            ctx.stroke();
        }
    }

    Text {
        anchors.centerIn: parent
        color: Theme.levelColor(root.level)
        font.pixelSize: 16
        text: root.valid ? Math.round(root.fraction * 100) + "%" : "—"
    }
}
