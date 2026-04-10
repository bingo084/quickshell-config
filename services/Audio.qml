pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio.volume ?? 0
    readonly property bool ready: Pipewire.ready && !isNaN(volume)

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
}
