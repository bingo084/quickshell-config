pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs.config
import qs.services

ClippingRectangle {
    id: root
    property real barWidth
    property real spacing: 1
    readonly property int barCount: barWidth > 0 ? Math.max(0, Math.floor((width + spacing) / (barWidth + spacing))) : MediaService.spectrum.length
    readonly property real actualBarWidth: barWidth > 0 ? barWidth : barCount > 0 ? Math.max(0, (width - (barCount - 1) * spacing) / barCount) : 0
    readonly property var levels: resample(MediaService.spectrum, barCount)
    property real maximumHeight: height * 0.9
    property color barColor: MediaService.coverColors?.[Theme.dark ? "dark" : "light"] ?? Theme.accent

    function resample(samples: list<real>, count: int): list<real> {
        if (samples.length === 0)
            return Array(count).fill(0);
        if (count === samples.length)
            return samples;

        return Array.from({
            length: count
        }, (_, index) => {
            if (count > samples.length) {
                const position = index * (samples.length - 1) / (count - 1);
                const left = Math.floor(position);
                const right = Math.min(left + 1, samples.length - 1);
                return samples[left] + (samples[right] - samples[left]) * (position - left);
            }

            const start = index * samples.length / count;
            const end = (index + 1) * samples.length / count;
            let sum = 0;
            for (let i = Math.floor(start); i < Math.ceil(end); i++) {
                const weight = Math.min(i + 1, end) - Math.max(i, start);
                sum += samples[i] * weight;
            }
            return sum / (end - start);
        });
    }

    radius: Theme.barItemRadius
    color: "transparent"
    opacity: 0.65

    Behavior on barColor {
        ColorAnimation {
            duration: 200
        }
    }

    Row {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        height: root.height
        spacing: root.spacing

        Repeater {
            model: root.barCount

            Item {
                id: slot
                required property int index
                width: root.actualBarWidth
                height: root.height

                Rectangle {
                    id: bar
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: root.visible ? root.levels[slot.index] * root.maximumHeight : 0
                    radius: 1
                    color: root.barColor

                    Behavior on height {
                        id: heightBehavior
                        NumberAnimation {
                            duration: heightBehavior.targetValue > bar.height ? 60 : 180
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}
