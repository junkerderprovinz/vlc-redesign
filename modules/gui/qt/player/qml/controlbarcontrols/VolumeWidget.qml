/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style
import VLC.Player

T.Pane {
    id: root

    property bool paintOnly: false

    readonly property var _player: paintOnly ? ({ muted: false, volume: .5 }) : Player
    readonly property int _maxvol: MainCtx.maxVolume
    readonly property real _maxvolpos: _maxvol / 100

    // Fill width of the wedge, out of 88, for each volume level up to 200 %.
    readonly property var _levels: [[0, 0], [0.1, 7], [0.2, 14], [0.3, 20], [0.4, 26], [0.5, 33], [0.6, 41],
                                    [0.7, 48], [0.8, 53], [0.9, 58], [1, 63], [1.5, 75], [2, 88]]

    function _interpolate(value, from, to) {
        for (let i = 1; i < _levels.length; ++i) {
            const a = _levels[i - 1]
            const b = _levels[i]
            if (value <= b[from])
                return a[to] + (value - a[from]) / (b[from] - a[from]) * (b[to] - a[to])
        }
        return _levels[_levels.length - 1][to]
    }

    // The wedge spans the whole volume range, the levels above go up to 200 %.
    function _fillForVolume(volume) {
        return _interpolate(Helpers.clamp(volume / _maxvolpos * 2, 0, 2), 0, 1) / 88
    }

    function _volumeForFill(ratio) {
        return _interpolate(Helpers.clamp(ratio * 88, 0, 88), 1, 0) / 2 * _maxvolpos
    }

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    contentWidth: volumeWidget.implicitWidth
    contentHeight: volumeWidget.implicitHeight

    // The volume keeps its distance from the buttons that follow it.
    rightPadding: VLCStyle.margin_xsmall

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    RowLayout {
        id: volumeWidget

        anchors.fill: parent
        spacing: VLCStyle.margin_xsmall

        ControlButton {
            id: volumeBtn

            focus: true
            paintOnly: root.paintOnly

            horizontalPadding: 0
            verticalPadding: 0

            text: {
                if (_player.muted)
                    return VLCIcons.volume_muted
                else if (_player.volume === 0)
                    return VLCIcons.volume_zero
                else if (_player.volume < .33)
                    return VLCIcons.volume_low
                else if (_player.volume <= .66)
                    return VLCIcons.volume_medium
                else
                    return VLCIcons.volume_high
            }
            description: _player.muted ? qsTr("Unmute") : qsTr("Mute")

            AccessibleCompat.id: "muteButton"

            onClicked: Player.muted = !Player.muted

            Accessible.onIncreaseAction: {
                Player.muted = false
                Player.setVolumeUp()
            }

            Accessible.onDecreaseAction: {
                Player.muted = false
                Player.setVolumeDown()
            }

            Navigation.parentItem: root
            Navigation.rightItem: volControl
        }

        T.Slider {
            id: volControl

            implicitWidth: VLCStyle.dp(88, VLCStyle.scale)
            implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

            Layout.alignment: Qt.AlignVCenter

            property bool _inhibitPlayerVolumeUpdate: false

            property bool _shiftPressed: false

            property real _clamp: 0.01

            property bool _keyPressed: false

            property bool filterEvents: false

            from: 0
            to: root._maxvolpos
            stepSize: 0.05

            enabled: !root.paintOnly

            Accessible.name: qsTr("Volume")
            AccessibleCompat.id: "volumeSlider"

            T.ToolTip.visible: hovered || sliderMouseArea.pressed
            T.ToolTip.delay: VLCStyle.delayToolTipAppear
            T.ToolTip.text: qsTr("Volume %1%").arg(Math.round(_player.volume * 100))

            hoverEnabled: true

            Keys.onPressed: (event) => {
                if (KeyHelper.matchOk(event)) {
                    event.accepted = true

                    _keyPressed = true
                } else {
                    Navigation.defaultKeyAction(event)
                }
            }

            Keys.onReleased: (event) => {
                if (_keyPressed === false)
                    return

                _keyPressed = false

                if (KeyHelper.matchOk(event)) {
                    Player.muted = !Player.muted
                }
            }

            function _syncVolumeWithPlayer() {
                volControl._inhibitPlayerVolumeUpdate = true
                volControl.value = _player.volume
                volControl._inhibitPlayerVolumeUpdate = false
            }

            function _adjustPlayerVolume() {
                Player.muted = false

                let value = volControl.value

                // NOTE: We are clamping the value to make it easier to restore the default volume.
                if (_shiftPressed === false) {
                    if (Math.abs(value - 1.0) < _clamp)
                        value = 1.0
                    else
                        _clamp = 0.01
                }

                Player.volume = value

                volControl.value = value
            }

            Component.onCompleted: {
                root.paintOnlyChanged.connect(_syncVolumeWithPlayer)
                volControl._syncVolumeWithPlayer()
            }

            Connections {
                target: Player
                enabled: !paintOnly

                function onVolumeChanged() { volControl._syncVolumeWithPlayer() }
            }

            Navigation.leftItem: volumeBtn
            Navigation.parentItem: root

            Keys.onUpPressed: (event) => {
                Player.muted = false
                Player.setVolumeUp()
            }

            Keys.onDownPressed: (event) => {
                Player.muted = false
                Player.setVolumeDown()
            }

            Keys.onRightPressed: (event) => {
                Player.muted = false
                Player.setVolumeUp()
            }

            Keys.onLeftPressed: (event) => {
                Player.muted = false
                Player.setVolumeDown()
            }

            Keys.priority: Keys.BeforeItem

            onValueChanged: {
                if (paintOnly)
                    return

                if (!volControl._inhibitPlayerVolumeUpdate) {
                    if (filterEvents) {
                        Qt.callLater(volControl._adjustPlayerVolume)
                    } else {
                        volControl._adjustPlayerVolume()
                        filterEvents = true
                    }
                }
            }

            handle: null

            background: Canvas {
                id: wedge

                implicitWidth: volControl.implicitWidth
                implicitHeight: volControl.implicitHeight

                readonly property real fill: _player.muted ? 0 : root._fillForVolume(volControl.value)

                readonly property color trackColor: theme.tokens.isDark ? theme.tokens.bgB2 : theme.tokens.bgA4

                opacity: _player.muted ? 0.5 : 1.0

                onFillChanged: requestPaint()
                onTrackColorChanged: requestPaint()

                // Paths of the wedge, in a 88 x 28 box.
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.scale(width / 88, height / 28)

                    ctx.beginPath()
                    ctx.moveTo(3.6, 19.36)
                    ctx.bezierCurveTo(1.55, 19.16, 0, 17.44, 0, 15.38)
                    ctx.lineTo(0, 12.62)
                    ctx.bezierCurveTo(0, 10.56, 1.55, 8.84, 3.6, 8.64)
                    ctx.lineTo(84.7, 0.33)
                    ctx.bezierCurveTo(86.47, 0.16, 88, 1.54, 88, 3.32)
                    ctx.lineTo(88, 24.68)
                    ctx.bezierCurveTo(88, 26.46, 86.47, 27.84, 84.7, 27.67)
                    ctx.closePath()
                    ctx.fillStyle = trackColor
                    ctx.fill()

                    if (fill <= 0)
                        return

                    ctx.save()
                    ctx.beginPath()
                    ctx.rect(0, 0, fill * 88, 28)
                    ctx.clip()

                    ctx.beginPath()
                    ctx.moveTo(3.29, 17.69)
                    ctx.bezierCurveTo(2.27, 17.58, 1.5, 16.72, 1.5, 15.7)
                    ctx.lineTo(1.5, 12.3)
                    ctx.bezierCurveTo(1.5, 11.28, 2.27, 10.42, 3.29, 10.31)
                    ctx.lineTo(85.29, 1.73)
                    ctx.bezierCurveTo(86.47, 1.61, 87.5, 2.53, 87.5, 3.72)
                    ctx.lineTo(87.5, 24.28)
                    ctx.bezierCurveTo(87.5, 25.47, 86.47, 26.39, 85.29, 26.27)
                    ctx.closePath()

                    const gradient = ctx.createLinearGradient(-2.5, 0, 87.5, 0)
                    gradient.addColorStop(0, "#95d318")
                    gradient.addColorStop(0.58, "#b2a918")
                    gradient.addColorStop(0.79, "#d37918")
                    gradient.addColorStop(1, "#ff3737")
                    ctx.fillStyle = gradient
                    ctx.fill()

                    ctx.fillStyle = Qt.rgba(0, 0, 0, 0.2)
                    ctx.fill()

                    ctx.restore()
                }
            }

            MouseArea {
                id: sliderMouseArea

                anchors.fill: parent

                acceptedButtons: Qt.LeftButton

                function adjustVolume(mouse) {
                    volControl._shiftPressed = (mouse.modifiers === Qt.ShiftModifier)
                    volControl.value = root._volumeForFill(mouse.x / width)
                }

                onPressed: (mouse) => {
                    if (root.paintOnly)
                        return

                    volControl.forceActiveFocus(Qt.MouseFocusReason)
                    volControl.filterEvents = false
                    adjustVolume(mouse)
                }

                onPositionChanged: (mouse) => {
                    if (pressed && !root.paintOnly)
                        adjustVolume(mouse)
                }

                onWheel: (wheel) => {
                    if ((Math.abs(wheel.pixelDelta.x) % 120 > 0) || (Math.abs(wheel.pixelDelta.y) % 120 > 0)) {
                        let delta = 0
                        if (Math.abs(wheel.pixelDelta.x) > Math.abs(wheel.pixelDelta.y))
                            delta = wheel.pixelDelta.x
                        else
                            delta = wheel.pixelDelta.y

                        if (wheel.inverted)
                            delta = -delta
                        volControl.value += 0.001 * delta
                    }
                    else
                        wheelToVLC.qmlWheelEvent(wheel)

                    wheel.accepted = true
                }

                WheelToVLCConverter {
                    id: wheelToVLC

                    function handle(steps: int) {
                        if (steps > 0)
                            Player.setVolumeUp(steps)
                        else
                            Player.setVolumeDown(-steps)
                    }

                    Component.onCompleted: {
                        wheelUpDown.connect(wheelToVLC.handle)
                        wheelLeftRight.connect(wheelToVLC.handle)
                    }
                }
            }
        }
    }
}
