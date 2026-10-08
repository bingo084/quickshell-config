import Quickshell
import qs.components
import qs.components.bar
import qs.services

Button {
    onClicked: {
        PopupHost.close();
        Launcher.toggle();
    }

    content: Icon {
        source: Quickshell.iconPath("system-search-symbolic", true)
    }
}
