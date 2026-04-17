pragma Singleton

import Niri
import QtQml

Niri {
    id: niri
    readonly property SortFilterProxyModel sortedWindows: SortFilterProxyModel {
        model: niri.windows
        sorters: [
            RoleSorter {
                roleName: "columnIndex"
            },
            RoleSorter {
                roleName: "tileIndex"
            }
        ]
    }

    Component.onCompleted: connect()
    onConnected: console.log("Connected to niri")
    onErrorOccurred: error => console.error("Niri error:", error)
}
