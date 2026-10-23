import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

ListView {
    property real maximumHeight: 320

    Layout.fillWidth: true
    implicitHeight: Math.min(contentHeight, maximumHeight)
    contentWidth: width - (contentHeight > height ? scrollbar.implicitWidth + 4 : 0)
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    spacing: 4

    Controls.ScrollBar.vertical: ScrollBar {
        id: scrollbar
    }
}
