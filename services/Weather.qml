pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    property string configPath: StandardPaths.writableLocation(StandardPaths.GenericDataLocation) + "/quickshell/weather.json"
    // QWeather current response: https://dev.qweather.com/docs/api/weather/weather-current/
    property var current: null
    // Tencent IP lookup response: https://lbs.qq.com/service/webService/webServiceGuide/position/webServiceIp
    property var location: null
    property string weatherUrl
    property bool refreshing: false
    property string error

    function refresh() {
        if (refreshing)
            return;
        refreshing = true;
        configFile.reload();
    }

    function fail(message: string) {
        error = message;
        refreshing = false;
        console.warn(message);
    }

    function fetchJson(url: string, label: string, callback, apiKey: string) {
        const request = new XMLHttpRequest();
        requestState.request = request;
        request.open("GET", url);
        if (apiKey !== "")
            request.setRequestHeader("X-QW-Api-Key", apiKey);
        request.onreadystatechange = () => {
            if (request.readyState !== XMLHttpRequest.DONE || requestState.request !== request)
                return;
            requestTimeout.stop();
            requestState.request = null;
            request.onreadystatechange = null;
            if (request.status !== 200) {
                fail(label + " request failed (HTTP " + request.status + ").");
                return;
            }
            let response;
            try {
                response = JSON.parse(request.responseText);
            } catch (e) {
                fail(label + " returned invalid JSON.");
                return;
            }
            callback(response);
        };
        requestTimeout.restart();
        request.send();
    }

    function fetchWeather(config) {
        const map = config.tencent_map;
        const api = "/ws/location/v1/ip?key=" + encodeURIComponent(map.key);
        const signature = Qt.md5(api + map.secret_key);
        fetchJson("https://apis.map.qq.com" + api + "&sig=" + signature, "Location", response => {
            const location = response?.result;
            const coordinates = location?.location;
            if (response?.status !== 0 || !Number.isFinite(coordinates?.lat) || !Number.isFinite(coordinates?.lng)) {
                fail("Location lookup failed or returned invalid coordinates.");
                return;
            }

            const position = coordinates.lat.toFixed(2) + "/" + coordinates.lng.toFixed(2);
            const url = "https://" + config.weather_host + "/weather/v1/current/" + position + "?lang=zh";
            fetchJson(url, "Weather", response => {
                if (!Number.isFinite(response?.temperature?.value)) {
                    fail("Weather lookup failed or returned invalid temperature.");
                    return;
                }
                root.location = location;
                current = Object.assign({}, response, {
                    fetchedAt: new Date()
                });
                error = "";
                fetchWeatherUrl(config, coordinates);
            }, config.weather_key);
        }, "");
    }

    function fetchWeatherUrl(config, coordinates) {
        const position = coordinates.lng.toFixed(2) + "," + coordinates.lat.toFixed(2);
        if (requestState.linkPosition === position && weatherUrl !== "") {
            refreshing = false;
            return;
        }
        weatherUrl = "";
        const url = "https://" + config.weather_host + "/geo/v2/city/lookup?location=" + encodeURIComponent(position) + "&number=1&lang=zh";
        fetchJson(url, "Weather page", response => {
            const link = response?.location?.[0]?.fxLink;
            if (response?.code !== "200" || typeof link !== "string" || !link.startsWith("https://")) {
                fail("Weather page lookup failed or returned no link.");
                return;
            }
            requestState.linkPosition = position;
            weatherUrl = link;
            refreshing = false;
        }, config.weather_key);
    }

    Connections {
        target: Sleep
        function onResumed() {
            root.refresh();
        }
    }
    FileView {
        id: configFile
        path: root.configPath
        printErrors: false
        onLoaded: {
            root.refreshing = true;
            let config;
            try {
                config = JSON.parse(configFile.text());
            } catch (e) {
                root.fail("Weather configuration is not valid JSON.");
                return;
            }
            if (typeof config?.weather_host !== "string" || !/^[a-zA-Z0-9.-]+$/.test(config.weather_host) || !config.weather_key || !config.tencent_map?.key || !config.tencent_map?.secret_key) {
                root.fail("Weather configuration requires weather_host, weather_key and tencent_map credentials.");
                return;
            }
            root.fetchWeather(config);
        }
        onLoadFailed: root.fail("Could not read weather configuration.")
    }
    QtObject {
        id: requestState
        property var request: null
        property string linkPosition
    }
    Timer {
        id: requestTimeout
        interval: 20000
        onTriggered: {
            const request = requestState.request;
            requestState.request = null;
            if (request !== null) {
                request.onreadystatechange = null;
                request.abort();
            }
            root.fail("Weather refresh timed out.");
        }
    }
    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
