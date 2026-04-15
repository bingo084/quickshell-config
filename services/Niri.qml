pragma Singleton

import Niri
import QtQml

Niri {
    function title(output: string): string {
        return _titleByOutput[output] ?? "";
    }

    property var _titleByOutput: ({})

    function _refreshTitles() {
        const activeWinIdByOutput = {};
        for (let i = 0; i < workspaces.count; i++) {
            const idx = workspaces.index(i, 0);
            const isActive = workspaces.data(idx, 261);
            if (!isActive) {
                continue;
            }
            const output = workspaces.data(idx, 260);
            const activeWindowId = workspaces.data(idx, 264);
            activeWinIdByOutput[output] = activeWindowId;
        }
        const titleByWinId = {};
        for (let i = 0; i < windows.count; i++) {
            const idx = windows.index(i, 0);
            const winId = windows.data(idx, 257);
            const title = windows.data(idx, 258);
            titleByWinId[winId] = title;
        }
        const nextTitleByOutput = {};
        for (const output in activeWinIdByOutput) {
            nextTitleByOutput[output] = titleByWinId[activeWinIdByOutput[output]];
        }
        _titleByOutput = nextTitleByOutput;
    }

    Component.onCompleted: connect()
    onConnected: console.log("Connected to niri")
    onFocusedWindowChanged: _refreshTitles()
    onErrorOccurred: error => console.error("Niri error:", error)
}
