import QtQuick
import qs.services

Text {
    text: (Audio.ready ? Math.round(Audio.volume * 100) : "--") + "%"
}
