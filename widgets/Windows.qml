pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components.bar
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

                WrapperRectangle {
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
                    implicitHeight: 30
                    radius: 4
                    color: Qt.darker(baseColor, area.pressed ? 1.08 : area.containsMouse ? 1.03 : 1.0)

                    WrapperMouseArea {
                        id: area
                        margin: 5
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => {
                            const sameAnchor = popup.visible && popup.anchorItem === window;
                            PopupManager.dismiss();
                            if (mouse.button === Qt.LeftButton)
                                Niri.focusWindow(window._id);
                            else if (mouse.button === Qt.RightButton && !sameAnchor) {
                                popup.anchorItem = window;
                                popup.visible = true;
                            } else if (mouse.button === Qt.MiddleButton)
                                Niri.closeWindow(window._id);
                        }
                        RowLayout {
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
                    }
                }
            }
        }
    }
    Popup {
        id: popup
        anchorItem: root
        readonly property var window: anchorItem

        ColumnLayout {
            spacing: 1

            MenuItem {
                icon: "zoom-fit-best-symbolic"
                label: "Maximize Column"
                onTriggered: {
                    popup.visible = false;
                    Niri.maximizeColumn(popup.window._id);
                }
            }
            MenuItem {
                icon: "window-maximize-symbolic"
                label: "Maximize Window To Edges"
                onTriggered: {
                    popup.visible = false;
                    Niri.maximizeWindowToEdges(popup.window._id);
                }
            }
            MenuItem {
                icon: "view-fullscreen-symbolic"
                label: "Toggle Fullscreen"
                onTriggered: {
                    popup.visible = false;
                    Niri.toggleFullscreen(popup.window._id);
                }
            }
            MenuItem {
                icon: "window-pop-out-symbolic"
                label: `${popup.window?.isFloating ? "Disable" : "Enable"} Floating`
                onTriggered: {
                    popup.visible = false;
                    Niri.toggleFloating(popup.window._id);
                }
            }
            MenuItem {
                icon: "window-close-symbolic"
                label: "Close"
                onTriggered: {
                    popup.visible = false;
                    Niri.closeWindow(popup.window._id);
                }
            }
        }
    }
}
