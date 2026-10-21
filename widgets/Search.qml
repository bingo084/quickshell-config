import qs.components
import qs.services

BarButton {
    onClicked: {
        PopupHost.close();
        LauncherService.toggle();
    }

    content: Icon {
        name: "system-search-symbolic"
    }
}
