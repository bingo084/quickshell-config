pragma Singleton

import QtQuick
import QtCore
import Quickshell
import Quickshell.Io

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

    function fetchJson(url: string, label: string, apiKey: string): var {
        return new Promise((resolve, reject) => {
            const request = new XMLHttpRequest();
            requestState.request = request;
            requestTimeout.reject = reject;
            request.open("GET", url);
            if (apiKey !== "")
                request.setRequestHeader("X-QW-Api-Key", apiKey);
            request.onreadystatechange = () => {
                if (request.readyState !== XMLHttpRequest.DONE || requestState.request !== request)
                    return;
                requestTimeout.stop();
                requestTimeout.reject = null;
                requestState.request = null;
                request.onreadystatechange = null;
                if (request.status !== 200) {
                    reject(new Error(label + " request failed (HTTP " + request.status + ")."));
                    return;
                }
                try {
                    resolve(JSON.parse(request.responseText));
                } catch (e) {
                    reject(new Error(label + " returned invalid JSON."));
                }
            };
            requestTimeout.restart();
            request.send();
        });
    }

    function fetchWeather(config) {
        return fetchLocation(config).then(location => root.fetchCurrent(config, location)).then(coordinates => root.fetchWeatherUrl(config, coordinates)).then(() => {
            root.refreshing = false;
        }).catch(error => root.fail(error.message));
    }

    function fetchLocation(config): var {
        const map = config.tencent_map;
        const api = "/ws/location/v1/ip?key=" + encodeURIComponent(map.key);
        const signature = Qt.md5(api + map.secret_key);
        return fetchJson("https://apis.map.qq.com" + api + "&sig=" + signature, "Location", "").then(response => {
            const location = response?.result;
            const coordinates = location?.location;
            if (response?.status !== 0 || !Number.isFinite(coordinates?.lat) || !Number.isFinite(coordinates?.lng))
                throw new Error("Location lookup failed or returned invalid coordinates.");
            return location;
        });
    }

    function fetchCurrent(config, location): var {
        const coordinates = location.location;
        const position = coordinates.lat.toFixed(2) + "/" + coordinates.lng.toFixed(2);
        const url = "https://" + config.weather_host + "/weather/v1/current/" + position + "?lang=zh";
        return fetchJson(url, "Weather", config.weather_key).then(response => {
            if (!Number.isFinite(response?.temperature?.value))
                throw new Error("Weather lookup failed or returned invalid temperature.");
            root.location = location;
            current = Object.assign({}, response, {
                fetchedAt: new Date()
            });
            error = "";
            return coordinates;
        });
    }

    function fetchWeatherUrl(config, coordinates) {
        const position = coordinates.lng.toFixed(2) + "," + coordinates.lat.toFixed(2);
        if (requestState.linkPosition === position && weatherUrl !== "")
            return;
        weatherUrl = "";
        const url = "https://" + config.weather_host + "/geo/v2/city/lookup?location=" + encodeURIComponent(position) + "&number=1&lang=zh";
        return fetchJson(url, "Weather page", config.weather_key).then(response => {
            const link = response?.location?.[0]?.fxLink;
            if (response?.code !== "200" || typeof link !== "string" || !link.startsWith("https://"))
                throw new Error("Weather page lookup failed or returned no link.");
            requestState.linkPosition = position;
            weatherUrl = link;
        });
    }

    Connections {
        target: SleepService

        function onResumed() {
            root.refresh();
        }
    }

    Connections {
        target: NetworkService

        function onReady() {
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
        property var reject
        interval: 20000
        onTriggered: {
            const request = requestState.request;
            const reject = requestTimeout.reject;
            if (request === null)
                return;
            requestState.request = null;
            requestTimeout.reject = null;
            request.onreadystatechange = null;
            request.abort();
            reject(new Error("Weather refresh timed out."));
        }
    }

    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
