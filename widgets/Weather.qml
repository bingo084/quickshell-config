import QtQuick
import QtQuick.Layouts
import qs.components.bar
import qs.config
import qs.services

Button {
    id: root
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: mouse => {
        if (mouse.button === Qt.LeftButton) {
            popup.visible = !popup.visible;
        } else if (mouse.button === Qt.RightButton) {
            if (PopupManager.activePopup !== popup)
                PopupManager.dismiss(popup);
            Weather.refresh();
        } else if (Weather.weatherUrl !== "") {
            PopupManager.dismiss();
            Qt.openUrlExternally(Weather.weatherUrl);
        }
    }
    content: Text {
        color: Weather.error !== "" ? Theme.warning : Theme.textPrimary
        text: {
            const current = Weather.current;
            if (current === null)
                return Weather.refreshing ? "Weather…" : "Weather —";
            const temperature = current.temperature;
            return `${current.condition.text} ${Math.round(temperature.value)}${temperature.unit}`;
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
                text: {
                    const current = Weather.current;
                    if (current === null)
                        return "No weather data";
                    return [current.condition.text, `Temperature: ${Math.round(current.temperature.value)}${current.temperature.unit}`, `Feels like: ${Math.round(current.feelsLike.value)}${current.feelsLike.unit}`, `Humidity: ${Math.round(current.humidity * 100)}%`, `Wind: ${current.wind.speed.value} ${current.wind.speed.unit}`, `Fetched: ${Qt.formatDateTime(current.fetchedAt, "hh:mm")}`].join("\n");
                }
            }
        }
    }
}
