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
            spacing: 0

            Repeater {
                model: workspace.model.isActive && workspace.model.output === root.screen.name ? Niri.sortedWindows : 0

                WrapperMouseArea {
                    id: area
                    required property var model
                    visible: workspace.model.id === model.workspaceId
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        const sameAnchor = popup.visible && popup.anchorItem === area;
                        PopupManager.dismiss();
                        if (mouse.button === Qt.LeftButton)
                            Niri.focusWindow(model.id);
                        else if (mouse.button === Qt.RightButton && !sameAnchor) {
                            popup.anchorItem = area;
                            popup.visible = true;
                        } else if (mouse.button === Qt.MiddleButton)
                            Niri.closeWindow(model.id);
                    }

                    WrapperRectangle {
                        readonly property color baseColor: area.model.isFocused ? "#eeeeee" : "#ffffff"
                        implicitHeight: 30
                        margin: 5
                        radius: 4
                        color: Qt.darker(baseColor, area.pressed ? 1.08 : area.containsMouse ? 1.03 : 1.0)

                        RowLayout {
                            IconImage {
                                readonly property var iconByTitle: ({
                                        "飞书": "/usr/share/icons/hicolor/256x256/apps/bytedance-feishu.png"
                                    })
                                readonly property string fixedIconPath: iconByTitle[area.model.title] ?? area.model.iconPath
                                implicitSize: 18
                                source: fixedIconPath ? "file://" + fixedIconPath : ""
                                visible: fixedIconPath !== ""
                            }
                            Text {
                                text: _format(area.model.title, area.model.appId)
                                color: area.model.isFocused ? "#007aff" : "black"

                                function _format(title: string, appId: string): string {
                                    if (appId === "google-chrome") {
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
        readonly property var targetItem: anchorItem

        ColumnLayout {
            spacing: 1

            MenuItem {
                icon: "zoom-fit-best-symbolic"
                label: "Maximize Column"
                onTriggered: {
                    popup.visible = false;
                    Niri.maximizeColumn(popup.targetItem.model.id);
                }
            }
            MenuItem {
                icon: "window-maximize-symbolic"
                label: "Maximize Window To Edges"
                onTriggered: {
                    popup.visible = false;
                    Niri.maximizeWindowToEdges(popup.targetItem.model.id);
                }
            }
            MenuItem {
                icon: "view-fullscreen-symbolic"
                label: "Toggle Fullscreen"
                onTriggered: {
                    popup.visible = false;
                    Niri.toggleFullscreen(popup.targetItem.model.id);
                }
            }
            MenuItem {
                icon: "window-pop-out-symbolic"
                label: `${popup.targetItem?.model?.isFloating ? "Disable" : "Enable"} Floating`
                onTriggered: {
                    popup.visible = false;
                    Niri.toggleFloating(popup.targetItem.model.id);
                }
            }
            MenuItem {
                icon: "window-close-symbolic"
                label: "Close"
                onTriggered: {
                    popup.visible = false;
                    Niri.closeWindow(popup.targetItem.model.id);
                }
            }
        }
    }
}
