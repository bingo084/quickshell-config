import QtQuick
import Quickshell
import qs.components
import qs.services
import qs.widgets.osd

Scope {
    id: root
    property var audioState: null
    property var brightnessState: null
    property string kind: "volume"

    function suppressed(kind: string): bool {
        if (!PopupHost.opened)
            return false;
        const anchor = PopupHost.activePopup?.anchorItem;
        return kind === "volume" ? anchor instanceof Audio : anchor instanceof Brightness;
    }

    function show(kind: string, screen: ShellScreen) {
        if (!screen || suppressed(kind))
            return;
        if (view.screen !== screen)
            view.dismiss();
        root.kind = kind;
        view.screen = screen;
        view.showOsd();
    }

    function audioScreen(): ShellScreen {
        const workspaces = NiriService.workspaces;
        for (let i = 0; i < workspaces.count; i++) {
            const workspace = workspaces.get(i);
            if (workspace.isFocused)
                return Quickshell.screens.find(screen => screen.name === workspace.output) ?? null;
        }
        return Quickshell.screens[0] ?? null;
    }

    function syncAudio() {
        const previous = audioState;
        const current = AudioService.ready ? {
            node: AudioService.sink,
            percent: AudioService.percent,
            muted: AudioService.muted
        } : null;
        audioState = current;
        if (!current || !previous || current.node !== previous.node)
            return;
        if (current.percent !== previous.percent || current.muted !== previous.muted)
            show("volume", audioScreen());
    }

    function syncBrightness() {
        const previous = brightnessState;
        const current = BrightnessService.available ? {
            device: BrightnessService.device,
            level: BrightnessService.level
        } : null;
        brightnessState = current;
        if (!current || !previous || current.device !== previous.device)
            return;
        if (current.level !== previous.level)
            show("brightness", Quickshell.screens.find(screen => screen.name === BrightnessService.output) ?? null);
    }

    Component.onCompleted: {
        Qt.callLater(syncAudio);
        Qt.callLater(syncBrightness);
    }

    Connections {
        target: AudioService
        function onSinkChanged() {
            root.audioState = null;
            Qt.callLater(root.syncAudio);
        }
        function onReadyChanged() {
            root.audioState = null;
            Qt.callLater(root.syncAudio);
        }
        function onPercentChanged() {
            Qt.callLater(root.syncAudio);
        }
        function onMutedChanged() {
            Qt.callLater(root.syncAudio);
        }
    }
    Connections {
        target: BrightnessService
        function onAvailableChanged() {
            root.brightnessState = null;
            Qt.callLater(root.syncBrightness);
        }
        function onDeviceChanged() {
            root.brightnessState = null;
            Qt.callLater(root.syncBrightness);
        }
        function onLevelChanged() {
            Qt.callLater(root.syncBrightness);
        }
    }
    Connections {
        target: PopupHost
        function onOpenedChanged() {
            if (root.suppressed(root.kind))
                view.closeOsd();
        }
        function onActivePopupChanged() {
            if (root.suppressed(root.kind))
                view.closeOsd();
        }
    }

    OsdWindow {
        id: view
        value: root.kind === "brightness" ? BrightnessService.level : AudioService.volume
        muted: root.kind === "volume" && AudioService.muted
        iconName: root.kind === "brightness" ? BrightnessService.iconName : AudioService.volumeIconName(AudioService.sink)
    }
}
