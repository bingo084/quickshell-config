pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import qs.config

Controls.Menu {
    id: root
    readonly property var items: Array.from({
        length: count
    }, (_, index) => itemAt(index))
    readonly property bool hasIcons: items.some(item => item.icon?.source.toString())

    popupType: Controls.Popup.Window
    padding: 7
    overlap: -6
    width: Math.max(120, Math.min(320, Math.ceil(Math.max(0, ...items.map(item => item.implicitWidth)) + leftPadding + rightPadding)))

    delegate: MenuItem {
        reserveIcon: root.hasIcons
        icon.color: "transparent"
    }

    contentItem: ListView {
        implicitHeight: contentHeight
        model: root.contentModel
        currentIndex: root.currentIndex
        spacing: 1
        clip: true
        interactive: contentHeight > height
        Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {}
    }

    background: Rectangle {
        radius: Theme.popupRadius
        color: Theme.popupBackground
        border.color: Theme.popupBorder
    }
}
