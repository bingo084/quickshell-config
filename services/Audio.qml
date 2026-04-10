pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    property real volume: Pipewire.defaultAudioSink?.audio.volume

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
}
