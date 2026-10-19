import QtQuick
import qs.components
import qs.components.bar
import qs.services
import qs.widgets.network

Button {
    id: root
    onClicked: NetworkPopup.toggle(root)

    content: Icon {
        name: Network.iconName()
    }
}
