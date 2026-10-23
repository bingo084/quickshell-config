import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Flickable {
    id: root
    default property alias content: body.data
    property real maximumHeight: 460
    property alias spacing: body.spacing

    Layout.fillWidth: true
    implicitHeight: Math.min(contentHeight, maximumHeight)
    contentWidth: width - (contentHeight > height ? scrollbar.implicitWidth + 4 : 0)
    contentHeight: body.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    data: ColumnLayout {
        id: body
        parent: root.contentItem
        width: root.contentWidth
        spacing: 14
    }

    Controls.ScrollBar.vertical: ScrollBar {
        id: scrollbar
    }
}
