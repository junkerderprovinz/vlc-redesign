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

            background: Item {
                id: wedge

                implicitWidth: volControl.implicitWidth
                implicitHeight: volControl.implicitHeight

                readonly property real fill: _player.muted ? 0 : root._fillForVolume(volControl.value)

                readonly property color trackColor: theme.tokens.isDark ? theme.tokens.bgB2 : theme.tokens.bgA4

                // an empty map keeps the green to red level of the svg
                readonly property var levelColor: MainCtx.volumeAccentColor ? ({ "url(#level)": theme.accent }) : ({})

                readonly property string _source: "qrc:///icons/ui/volume-wedge.svg"

                opacity: _player.muted ? 0.5 : 1.0

                // the level is painted in the track color, so only the track shows
                Image {
                    anchors.fill: parent

                    sourceSize: Qt.size(width, height)
                    source: SVGColorImage.colorize(wedge._source)
                                         .color1(wedge.trackColor)
                                         .any({ "url(#level)": wedge.trackColor })
                                         .uri()
                }

                Item {
                    width: wedge.fill * parent.width
                    height: parent.height

                    clip: true

                    Image {
                        width: wedge.width
                        height: wedge.height

                        sourceSize: Qt.size(width, height)
                        source: SVGColorImage.colorize(wedge._source)
                                             .color1(wedge.trackColor)
                                             .any(wedge.levelColor)
                                             .uri()
                    }
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
