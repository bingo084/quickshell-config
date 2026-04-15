pragma Singleton

import Niri
import QtQml

Niri {
    Component.onCompleted: connect()
    onConnected: console.log("Connected to niri")
    onErrorOccurred: error => console.error("Niri error:", error)
}
