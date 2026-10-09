import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.bar
import qs.config
import qs.services
import "../assets/qweather/Offsets.mjs" as IconOffsets

Button {
    id: root

    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.toggle();
        } else if (mouse.button === Qt.RightButton) {
            popup.closeOthers();
            Weather.refresh();
        } else if (Weather.weatherUrl !== "") {
            popup.closeAll();
            Qt.openUrlExternally(Weather.weatherUrl);
        }
    }

    function windText(current): string {
        if (current === null)
            return "";
        const directions = {
            N: "北",
            NNE: "东北偏北",
            NE: "东北",
            ENE: "东北偏东",
            E: "东",
            ESE: "东南偏东",
            SE: "东南",
            SSE: "东南偏南",
            S: "南",
            SSW: "西南偏南",
            SW: "西南",
            WSW: "西南偏西",
            W: "西",
            WNW: "西北偏西",
            NW: "西北",
            NNW: "西北偏北"
        };
        const wind = current.wind;
        const compass = wind.direction.compass.toUpperCase();
        const direction = directions[compass];
        return `${direction ? direction + "风" : compass} · ${wind.scale}级 · ${wind.speed.value} ${wind.speed.unit}`;
    }

    content: RowLayout {
        spacing: 4

        Icon {
            id: weatherIcon
            readonly property string code: Weather.current?.condition?.code ?? "999"
            readonly property point opticalOffset: {
                const code = weatherIcon.status === Image.Error ? "999" : weatherIcon.code;
                const offset = IconOffsets.offsets[code] ?? [0, 0];
                return Qt.point(offset[0], offset[1]);
            }
            transform: Translate {
                x: weatherIcon.opticalOffset.x * weatherIcon.actualSize / 16
                y: weatherIcon.opticalOffset.y * weatherIcon.actualSize / 16
            }
            source: Qt.resolvedUrl(`../assets/qweather/${weatherIcon.code}.svg`)
            Icon {
                anchors.fill: parent
                visible: weatherIcon.status === Image.Error
                source: Qt.resolvedUrl("../assets/qweather/999.svg")
            }
        }

        Text {
            color: Weather.error !== "" ? Theme.warning : Theme.textPrimary
            text: {
                const current = Weather.current;
                if (current === null)
                    return Weather.refreshing ? "…" : "—";
                const temperature = current.temperature;
                return `${Math.round(temperature.value)}${temperature.unit}`;
            }
        }
    }

    Popup {
        id: popup
        anchorItem: root
        contentWidth: 240

        ColumnLayout {
            id: details
            readonly property var current: Weather.current

            spacing: 12
            Text {
                Layout.alignment: Qt.AlignHCenter
                color: Theme.textPrimary
                font.pixelSize: 13
                font.bold: true
                visible: text !== ""
                text: {
                    const area = Weather.location?.ad_info;
                    const city = area?.city || area?.province || area?.nation;
                    return [city, area?.district].filter(Boolean).join(" · ");
                }
            }
            Text {
                Layout.fillWidth: true
                wrapMode: Text.Wrap
                visible: text !== ""
                color: Theme.warning
                text: Weather.error
            }
            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: details.current === null
                color: Theme.textSecondary
                text: Weather.refreshing ? "正在更新…" : "暂无天气数据"
            }

            ColumnLayout {
                visible: details.current !== null
                spacing: 12

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 10
                    Icon {
                        id: popupIcon
                        implicitSize: 36
                        source: weatherIcon.status === Image.Error ? Qt.resolvedUrl("../assets/qweather/999.svg") : weatherIcon.source
                        transform: Translate {
                            x: weatherIcon.opticalOffset.x * popupIcon.actualSize / 16
                            y: weatherIcon.opticalOffset.y * popupIcon.actualSize / 16
                        }
                    }
                    Text {
                        color: Theme.textPrimary
                        font.pixelSize: 36
                        font.weight: Font.Medium
                        text: details.current ? `${Math.round(details.current.temperature.value)}°` : ""
                    }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.textPrimary
                    font.pixelSize: 13
                    text: details.current ? `${details.current.condition.text} · 体感 ${Math.round(details.current.feelsLike.value)}${details.current.feelsLike.unit}` : ""
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    color: Theme.textSecondary
                    font.pixelSize: 13
                    text: root.windText(details.current)
                }

                Separator {}

                GridLayout {
                    columns: 2
                    uniformCellWidths: true
                    columnSpacing: 18
                    rowSpacing: 10
                    Repeater {
                        model: {
                            const current = details.current;
                            if (current === null)
                                return [];
                            return [
                                {
                                    label: "湿度",
                                    value: `${Math.round(current.humidity * 100)}%`
                                },
                                {
                                    label: "降水",
                                    value: `${current.precipitation.amount.value} ${current.precipitation.amount.unit}`
                                },
                                {
                                    label: "气压",
                                    value: `${current.pressure.value} ${current.pressure.unit}`
                                },
                                {
                                    label: "能见度",
                                    value: `${current.visibility.value} ${current.visibility.unit}`
                                },
                                {
                                    label: "云量",
                                    value: `${Math.round(current.cloudCover * 100)}%`
                                },
                                {
                                    label: "露点",
                                    value: `${current.dewPoint.value}${current.dewPoint.unit}`
                                }
                            ];
                        }

                        RowLayout {
                            id: metric
                            required property var modelData

                            spacing: 6
                            Text {
                                Layout.fillWidth: true
                                color: Theme.textTertiary
                                font.pixelSize: 13
                                text: metric.modelData.label
                            }
                            Text {
                                color: Theme.textPrimary
                                font.pixelSize: 13
                                text: metric.modelData.value
                            }
                        }
                    }
                }

                Text {
                    color: Theme.textTertiary
                    font.pixelSize: 11
                    text: details.current ? `更新于 ${Qt.formatDateTime(details.current.fetchedAt, "hh:mm")}` : ""
                }
            }
        }
    }
}
