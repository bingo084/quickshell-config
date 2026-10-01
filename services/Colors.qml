pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string palettePath: Qt.resolvedUrl("../config/colors.json")
    property var data: JSON.parse(paletteFile.text())
    FileView {
        id: paletteFile
        path: root.palettePath
        blockLoading: true
        watchChanges: true
        onFileChanged: paletteFile.reload()
    }
}
