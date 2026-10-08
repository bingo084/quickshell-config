pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.components
import qs.components.bar
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

            spacing: 0

            Repeater {
                model: workspace.model.isActive && workspace.model.output === root.screen?.name ? Niri.sortedWindows : 0

                WrapperMouseArea {
                    id: area
                    required property var model

                    visible: workspace.model.id === model.workspaceId
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onClicked: mouse => {
                        const sameAnchor = popup.visible && popup.anchorItem === area;
                        popup.closeAll();
                        if (mouse.button === Qt.LeftButton)
                            Niri.focusWindow(model.id);
                        else if (mouse.button === Qt.RightButton && !sameAnchor) {
                            popup.anchorItem = area;
                            popup.open();
                        } else if (mouse.button === Qt.MiddleButton)
                            Niri.closeWindow(model.id);
                    }

                    WrapperRectangle {
                        readonly property color overlayColor: area.pressed ? Theme.pressedBackground : area.containsMouse ? Theme.hoveredBackground : "transparent"

                        implicitHeight: 30
                        margin: 5
                        radius: 4
                        color: area.model.isFocused ? Qt.tint(Theme.selectedBackground, overlayColor) : overlayColor

                        RowLayout {
                            Icon {
                                readonly property var iconByTitle: ({
                                        "飞书": "/usr/share/icons/hicolor/256x256/apps/bytedance-feishu.png"
                                    })
                                readonly property string fixedIconPath: iconByTitle[area.model.title] ?? area.model.iconPath

                                colorize: false
                                source: fixedIconPath ? "file://" + fixedIconPath : ""
                                visible: fixedIconPath !== ""
                            }
                            Text {
                                text: _format(area.model.title, area.model.appId)
                                color: area.model.isFocused ? Theme.textOnSelected : Theme.textPrimary

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
        contentMargin: 6
        readonly property var targetItem: anchorItem

        ColumnLayout {
            spacing: 1
            MenuItem {
                icon: "zoom-fit-best-symbolic"
                label: "Maximize Column"
                onTriggered: {
                    popup.close();
                    Niri.maximizeColumn(popup.targetItem.model.id);
                }
            }
            MenuItem {
                icon: "window-maximize-symbolic"
                label: "Maximize Window To Edges"
                onTriggered: {
                    popup.close();
                    Niri.maximizeWindowToEdges(popup.targetItem.model.id);
                }
            }
            MenuItem {
                icon: "view-fullscreen-symbolic"
                label: "Toggle Fullscreen"
                onTriggered: {
                    popup.close();
                    Niri.toggleFullscreen(popup.targetItem.model.id);
                }
            }
            MenuItem {
                icon: "window-pop-out-symbolic"
                label: `${popup.targetItem?.model?.isFloating ? "Disable" : "Enable"} Floating`
                onTriggered: {
                    popup.close();
                    Niri.toggleFloating(popup.targetItem.model.id);
                }
            }
            MenuItem {
                icon: "window-close-symbolic"
                label: "Close"
                onTriggered: {
                    popup.close();
                    Niri.closeWindow(popup.targetItem.model.id);
                }
            }
        }
    }
}
