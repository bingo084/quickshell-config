import Quickshell
import Quickshell.Widgets
import qs.components.bar
import qs.services

Button {
    onClicked: {
        PopupManager.dismiss();
        Launcher.toggle();
    }
    content: IconImage {
        implicitSize: 18
        source: Quickshell.iconPath("system-search-symbolic", true)
    }
}
