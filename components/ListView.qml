import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

ListView {
    id: root
    property real maximumHeight: 320

    Layout.fillWidth: true
    implicitHeight: Math.min(contentHeight, maximumHeight)
    contentWidth: width
    contentItem.z: 1
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    spacing: 4

    SmoothScroll {
        flickable: root
    }

    Controls.ScrollBar.vertical: ScrollBar {
        viewport: root
    }
}
