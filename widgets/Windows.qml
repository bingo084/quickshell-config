pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.config
import qs.services

RowLayout {
    id: root
    required property ShellScreen screen
    spacing: 0

    Repeater {
        model: Niri.workspaces

        RowLayout {
            id: workspace
            required property var model
            readonly property int _id: model.id
            required property bool isActive
            required property string output
            spacing: 0

            Repeater {
                model: workspace.isActive && workspace.output === root.screen.name ? Niri.sortedWindows : 0

                Rectangle {
                    id: window
                    required property var model
                    readonly property int _id: model.id
                    required property int index
                    required property string title
                    required property string appId
                    required property int workspaceId
                    required property bool isFocused
                    required property bool isFloating
                    required property string iconPath
                    readonly property string fixedIconPath: title === "飞书" ? "/usr/share/icons/hicolor/256x256/apps/bytedance-feishu.png" : iconPath
                    readonly property color baseColor: isFocused ? "#eeeeee" : "#ffffff"
                    visible: workspace._id === window.workspaceId
                    implicitWidth: row.implicitWidth + 10
                    implicitHeight: 30
                    radius: 4
                    color: Qt.darker(baseColor, area.pressed ? 1.08 : area.containsMouse ? 1.03 : 1.0)

                    RowLayout {
                        id: row
                        anchors.centerIn: parent

                        IconImage {
                            implicitSize: 18
                            source: window.fixedIconPath ? "file://" + window.fixedIconPath : ""
                            visible: window.fixedIconPath !== ""
                        }
                        Text {
                            text: _format(window.title, window.appId)
                            color: window.isFocused ? "#007aff" : "black"

                            function _format(title: string, appId: string): string {
                                if ((appId === "google-chrome")) {
                                    return title.replace(/ - Google Chrome$/, "");
                                }
                                return title;
                            }
                        }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            const sameAnchor = popup.visible && popup.anchorItem === window;
                            BarPopupManager.dismiss();
                            if (mouse.button === Qt.LeftButton)
                                Niri.focusWindow(window._id);
                            else if (mouse.button === Qt.RightButton && !sameAnchor) {
                                popup.anchorItem = window;
                                popup.visible = true;
                            } else if (mouse.button === Qt.MiddleButton)
                                Niri.closeWindow(window._id);
                        }
                    }
                }
            }
        }
    }
    BarPopup {
        id: popup
        anchorItem: root
        readonly property var window: anchorItem

        ColumnLayout {
            spacing: 1

            MenuButton {
                icon: "zoom-fit-best-symbolic"
                label: "Maximize Column"
                onTriggered: {
                    popup.visible = false;
                    Niri.maximizeColumn(popup.window._id);
                }
            }
            MenuButton {
                icon: "window-maximize-symbolic"
                label: "Maximize Window To Edges"
                onTriggered: {
                    popup.visible = false;
                    Niri.maximizeWindowToEdges(popup.window._id);
                }
            }
            MenuButton {
                icon: "view-fullscreen-symbolic"
                label: "Toggle Fullscreen"
                onTriggered: {
                    popup.visible = false;
                    Niri.toggleFullscreen(popup.window._id);
                }
            }
            MenuButton {
                icon: "window-pop-out-symbolic"
                label: `${popup.window?.isFloating ? "Disable" : "Enable"} Floating`
                onTriggered: {
                    popup.visible = false;
                    Niri.toggleFloating(popup.window._id);
                }
            }
            MenuButton {
                icon: "window-close-symbolic"
                label: "Close"
                onTriggered: {
                    popup.visible = false;
                    Niri.closeWindow(popup.window._id);
                }
            }
        }
    }
    component MenuButton: WrapperRectangle {
        id: button
        required property string icon
        required property string label
        signal triggered

        Layout.fillWidth: true
        implicitHeight: 30
        radius: 6
        color: buttonArea.pressed ? "#d9d9d9" : buttonArea.containsMouse ? "#efefef" : "transparent"
        opacity: enabled ? 1 : 0.5

        WrapperMouseArea {
            id: buttonArea
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            margin: 6
            onClicked: button.triggered()
            RowLayout {
                IconImage {
                    implicitSize: 16
                    source: Quickshell.iconPath(button.icon, true)
                }
                Text {
                    Layout.fillWidth: true
                    color: Theme.textPrimary
                    text: button.label
                }
            }
        }
    }
}
