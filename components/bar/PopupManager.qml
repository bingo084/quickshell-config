pragma Singleton

import Quickshell

Singleton {
    property PopupWindow activePopup: null

    function activate(popup: PopupWindow) {
        if (activePopup === popup)
            return;
        const oldPopup = activePopup;
        activePopup = popup;
        if (oldPopup !== null)
            oldPopup.visible = false;
    }

    function deactivate(popup: PopupWindow) {
        if (activePopup === popup)
            activePopup = null;
    }

    function dismiss() {
        const popup = activePopup;
        activePopup = null;
        if (popup !== null)
            popup.visible = false;
    }
}
