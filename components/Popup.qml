import QtQuick
import Quickshell

Scope {
    id: root
    required property Item anchorItem
    default property Item content
    property real contentMargin: 12
    property real contentWidth: content.implicitWidth
    readonly property bool visible: PopupHost.activePopup === root && PopupHost.opened

    function open(anchorItem = root.anchorItem) {
        PopupHost.open(root, anchorItem);
    }

    function close() {
        if (PopupHost.activePopup === root)
            closeAll();
    }

    function closeOthers() {
        if (!visible)
            closeAll();
    }

    function closeAll() {
        PopupHost.close();
    }

    function toggle(anchorItem = root.anchorItem) {
        if (visible && root.anchorItem === anchorItem)
            close();
        else
            open(anchorItem);
    }

    Component.onDestruction: {
        if (PopupHost.activePopup === root)
            PopupHost.release();
    }
}
