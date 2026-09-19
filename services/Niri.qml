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

    function maximizeColumn(id: int) {
        const focusResult = niri.focusWindow(id);
        if (!focusResult.ok) {
            console.error("Failed to focus window before maximizing column:", focusResult.error);
            return;
        }

        const result = niri.sendRawAction({
            MaximizeColumn: {}
        });
        if (!result.ok) {
            console.error("Failed to maximize column:", result.error);
        }
    }

    function maximizeWindowToEdges(id: int) {
        const result = niri.sendRawAction({
            MaximizeWindowToEdges: {
                id: id
            }
        });
        if (!result.ok) {
            console.error("Failed to maximize window to edges:", result.error);
        }
    }

    function toggleFullscreen(id: int) {
        const result = niri.sendRawAction({
            FullscreenWindow: {
                id: id
            }
        });
        if (!result.ok) {
            console.error("Failed to toggle fullscreen:", result.error);
        }
    }

    function toggleFloating(id: int) {
        const result = niri.sendRawAction({
            ToggleWindowFloating: {
                id: id
            }
        });
        if (!result.ok) {
            console.error("Failed to toggle floating:", result.error);
        }
    }
}
