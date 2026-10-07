import QtQuick
import Quickshell
import qs.components.bar

Scope {
    id: root
    required property Item anchorItem
    default property Item content
    property real contentMargin: 12
    property real contentWidth: content.implicitWidth
    readonly property bool visible: PopupHost.activePopup === root && PopupHost.opened

    function open() {
        PopupHost.open(root);
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

    function toggle() {
        if (visible)
            close();
        else
            open();
    }

    Component.onDestruction: {
        if (PopupHost.activePopup === root)
            PopupHost.release();
    }
}
