import QtQuick
import qs.services

Text {
    text: (Audio.volume ? Math.round(Audio.volume * 100) : "--") + "%"
}
