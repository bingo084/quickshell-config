import QtQuick
import QtQuick.Layouts
import qs.components
import qs.components.bar
import qs.config
import qs.services
import "../assets/qweather/Offsets.js" as IconOffsets

Button {
    id: root
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.visible = !popup.visible;
        } else if (mouse.button === Qt.RightButton) {
            if (PopupManager.activePopup !== popup)
                PopupManager.dismiss();
            Weather.refresh();
        } else if (Weather.weatherUrl !== "") {
            PopupManager.dismiss();
            Qt.openUrlExternally(Weather.weatherUrl);
        }
    }

    function detailsText(current): string {
        if (current === null)
            return "No weather data";
        const lines = [];
        lines.push(current.condition.text);
        lines.push(`Temperature: ${Math.round(current.temperature.value)}${current.temperature.unit}`);
        lines.push(`Feels like: ${Math.round(current.feelsLike.value)}${current.feelsLike.unit}`);
        lines.push(`Humidity: ${Math.round(current.humidity * 100)}%`);
        lines.push(`Wind: ${current.wind.direction.compass.toUpperCase()}, ${current.wind.speed.value} ${current.wind.speed.unit}`);
        lines.push(`Wind scale: ${current.wind.scale}`);
        lines.push(`Precipitation: ${current.precipitation.amount.value} ${current.precipitation.amount.unit}`);
        lines.push(`Pressure: ${current.pressure.value} ${current.pressure.unit}`);
        lines.push(`Visibility: ${current.visibility.value} ${current.visibility.unit}`);
        lines.push(`Cloud cover: ${Math.round(current.cloudCover * 100)}%`);
        lines.push(`Dew point: ${current.dewPoint.value}${current.dewPoint.unit}`);
        lines.push(`Fetched: ${Qt.formatDateTime(current.fetchedAt, "MM-dd hh:mm")}`);
        return lines.join("\n");
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
            implicitSize: 16
            transform: Translate {
                x: weatherIcon.opticalOffset.x * weatherIcon.actualSize / 16
                y: weatherIcon.opticalOffset.y * weatherIcon.actualSize / 16
            }
            source: Qt.resolvedUrl(`../assets/qweather/${weatherIcon.code}-fill.svg`)
            Icon {
                anchors.fill: parent
                visible: weatherIcon.status === Image.Error
                source: Qt.resolvedUrl("../assets/qweather/999-fill.svg")
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
        ColumnLayout {
            spacing: 6
            Text {
                color: Theme.textPrimary
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
                Layout.preferredWidth: 280
                wrapMode: Text.Wrap
                visible: text !== ""
                color: Theme.warning
                text: Weather.error
            }
            Text {
                color: Theme.textPrimary
                text: root.detailsText(Weather.current)
            }
        }
    }
}
