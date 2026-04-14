pragma Singleton

import Niri
import QtQml

Niri {
    id: niri
    Component.onCompleted: niri.connect()
    onConnected: console.log("Connected to niri")
    onErrorOccurred: function (error) {
        console.error("Niri error:", error);
    }
}
