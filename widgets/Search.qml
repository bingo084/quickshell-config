import qs.components
import qs.components.bar
import qs.services

Button {
    onClicked: {
        PopupHost.close();
        Launcher.toggle();
    }

    content: Icon {
        name: "system-search-symbolic"
    }
}
