import Quickshell
import Quickshell.Services.UPower
import QtQuick
import ".."

Text {
    color: batteryColor
    font.pixelSize: 20
    text: batteryIcon

    readonly property real battery: Math.ceil(UPower.displayDevice.percentage * 100)
    readonly property string batteryIcon: UPower.displayDevice.state == UPowerDeviceState.Charging ? batteryChargingIconFor(battery) : batteryIconFor(battery)
    readonly property color batteryColor: batteryColorFor(battery)

    function batteryIconFor(pct: int): string {
        if (pct > 95) return "\udb80\udc79"
        if (pct > 85) return "\udb80\udc82"
        if (pct > 75) return "\udb80\udc81"
        if (pct > 65) return "\udb80\udc80"
        if (pct > 55) return "\udb80\udc7f"
        if (pct > 45) return "\udb80\udc7e"
        if (pct > 35) return "\udb80\udc7d"
        if (pct > 25) return "\udb80\udc7c"
        if (pct > 15) return "\udb80\udc7b"
        if (pct > 5) return "\udb80\udc7a"
        return "\udb80\udc8e"
    }

    function batteryChargingIconFor(pct: int): string {
        if (pct > 95) return "\udb80\udc85"
        if (pct > 85) return "\udb80\udc8b"
        if (pct > 75) return "\udb80\udc8a"
        if (pct > 65) return "\udb82\udc9e"
        if (pct > 55) return "\udb80\udc89"
        if (pct > 45) return "\udb82\udc9d"
        if (pct > 35) return "\udb80\udc88"
        if (pct > 25) return "\udb80\udc87"
        if (pct > 15) return "\udb80\udc86"
        if (pct > 5) return "\udb82\udc9c"
        return "\udb82\udc9f"
    }

    function batteryColorFor(pct: int): color {
        if (pct > 30) return Theme.success.content
        if (pct > 15) return Theme.warn.content
        return Theme.error.content
    }
}