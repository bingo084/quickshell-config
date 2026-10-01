import Quickshell
import qs.components
import qs.components.bar
import qs.services

Button {
    onClicked: {
        PopupManager.dismiss();
        Launcher.toggle();
    }
    content: Icon {
        implicitSize: 18
        source: Quickshell.iconPath("system-search-symbolic", true)
    }
}
