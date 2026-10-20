pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import Quickshell
import qs.components

Menu {
    id: root
    property var handle: null
    property QsMenuEntry entry

    title: entry?.text ?? ""
    enabled: entry?.enabled ?? true
    icon.source: entry ? entry.icon : ""
    opacity: count > 0 ? 1 : 0

    function insert(index: int, control: var, entry: QsMenuEntry) {
        if (entry.isSeparator) {
            insertItem(index, control);
        } else {
            control.entry = entry;
            if (entry.hasChildren) {
                control.handle = entry;
                insertMenu(index, control);
            } else {
                insertItem(index, control);
            }
        }
    }

    function remove(loader: var) {
        if (!loader.item)
            return;
        const index = items.findIndex(item => item === loader.item || item.subMenu === loader.item);
        // Detach only: Loader owns and destroys the controls.
        if (loader.item instanceof Controls.Menu)
            takeMenu(index);
        else
            takeItem(index);
    }

    QsMenuOpener {
        id: opener
        menu: root.visible ? root.handle : null
    }

    Instantiator {
        model: opener.children

        delegate: Loader {
            required property int index
            required property QsMenuEntry modelData
            readonly property Component component: modelData.isSeparator ? separator : modelData.hasChildren ? Qt.createComponent(Qt.resolvedUrl("TrayMenu.qml")) : action

            onComponentChanged: {
                root.remove(this);
                sourceComponent = component;
            }
            onLoaded: root.insert(index, item, modelData)
        }

        onObjectRemoved: (index, object) => root.remove(object)
    }

    Component {
        id: action

        MenuItem {
            property QsMenuEntry entry

            text: entry?.text ?? ""
            enabled: entry?.enabled ?? false
            icon.source: entry ? entry.icon : ""
            icon.color: "transparent"
            reserveIcon: root.hasIcons
            checkState: entry?.checkState ?? Qt.Unchecked
            checked: checkState !== Qt.Unchecked
            radio: entry?.buttonType === QsMenuButtonType.RadioButton
            onTriggered: entry.triggered()
        }
    }

    Component {
        id: separator

        Controls.MenuSeparator {
            verticalPadding: 4
            contentItem: Separator {}
        }
    }
}
