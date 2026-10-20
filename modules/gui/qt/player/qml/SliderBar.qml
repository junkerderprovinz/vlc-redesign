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
import QtQuick.Templates as T
import QtQuick.Layouts

import VLC.Player
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util
import VLC.MainInterface

T.ProgressBar {
    id: control

    property int barHeight: VLCStyle.dp(28, VLCStyle.scale)

    // Draws the track as the bars of a waveform, as the music player does.
    property bool waveform: false

    property bool handleVisible: true

    property bool _isSeekPointsShown: true

    property color backgroundColor: theme.tokens.bgB2
    property real touchHandlerMargin: VLCStyle.touchHandlerMargin

    readonly property real _inset: VLCStyle.dp(2, VLCStyle.scale)
    readonly property real _handleWidth: VLCStyle.dp(waveform ? 4 : 8, VLCStyle.scale)
    readonly property real _range: Math.max(1, width - 2 * _inset - _handleWidth)
    readonly property real _handleX: _inset + control.visualPosition * _range

    Keys.onRightPressed: Player.jumpFwd()
    Keys.onLeftPressed: Player.jumpBwd()

    Accessible.onIncreaseAction: Player.jumpFwd()
    Accessible.onDecreaseAction: Player.jumpBwd()

    function showChapterMarks() {
        _isSeekPointsShown = true
        seekpointTimer.restart()
    }

    function _positionAt(x) {
        return (x - _inset - _handleWidth / 2) / _range
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Slider

        enabled: control.enabled
        focused: control.visualFocus
        hovered: hoverHandler.hovered
    }

    Timer {
        id: seekpointTimer
        running: Player.hasChapters && !hoverHandler.hovered && _isSeekPointsShown
        interval: 3000
        onTriggered: control._isSeekPointsShown = false
    }

    Widgets.PointingToolTipAttached.visible: (hoverHandler.hovered || control.visualFocus || dragHandler.active)

    Widgets.PointingToolTipAttached.text: {
        if (!Widgets.PointingToolTipAttached.instance?.visible)
            return ""

        let _text

        const length = Player.length
        const position = Helpers.clamp(control._positionAt(Widgets.PointingToolTipAttached.instance.pos.x), 0, 1)
        if (hoverHandler.hovered)
            _text = length.scale(position)
        else
            _text = Player.time

        _text = _text.formatHMS(length.isSubSecond() ? VLCTick.SubSecondFormattedAsMS : 0)

        if (Player.hasChapters)
            _text += " - " + Player.chapters.getNameAtPosition(position)

        return _text
    }

    Widgets.PointingToolTipAttached.pos: Qt.point(hoverHandler.hovered ? Helpers.clamp(hoverHandler.point.position.x, 0, control.availableWidth)
                                                                       : (control._handleX + control._handleWidth / 2), 0)

    FSM {
        id: fsm
        signal playerUpdatePosition(real position)
        signal pressControl(real position, bool forcePrecise)
        signal releaseControl(real position, bool forcePrecise)
        signal moveControl(real position, bool forcePrecise)
        signal inputChanged()

        //each signal is associated to a key, when a signal is received,
        //transitions of active state for the given key are evaluated
        signalMap: ({
            "playerUpdatePosition": fsm.playerUpdatePosition,
            "pressControl": fsm.pressControl,
            "releaseControl": fsm.releaseControl,
            "moveControl": fsm.moveControl,
            "inputChanged": fsm.inputChanged
        })

        initialState: fsmReleased

        function _setPositionFromValue(position) {
            control.value = position
        }

        function _seekToPosition(position, threshold, forcePrecise) {
            position = Helpers.clamp(position, 0., 1.)
            control.value = position
            if (!forcePrecise) {
                const chapter = Player.chapters.getClosestChapterFromPos(position, threshold)
                if (chapter !== -1) {
                    Player.chapters.selectChapter(chapter)
                    return
                }
            }
            Player.position = position
        }

        FSMState {
            id: fsmReleased

            transitions: ({
                "playerUpdatePosition": {
                    action: (position) => {
                        control.value = position
                    }
                },
                "pressControl": {
                    action: (position, forcePrecise) => {
                        control.forceActiveFocus()
                        fsm._seekToPosition(position, VLCStyle.dp(4, VLCStyle.scale) / control._range, forcePrecise)
                    },
                    target: fsmHeld
                }
            })
        }

        FSMState  {
            id: fsmHeld

            transitions: ({
                "moveControl": {
                    action: (position, forcePrecise) => {
                        fsm._seekToPosition(position, VLCStyle.dp(2, VLCStyle.scale) / control._range, forcePrecise)
                    }
                },
                "releaseControl": {
                    target: fsmReleased
                },
                "inputChanged": {
                    target: fsmHeldWrongInput
                }
            })
        }

        FSMState  {
            id: fsmHeldWrongInput

            function enter() {
                fsm._setPositionFromValue(Player.position)
            }

            transitions: ({
                "playerUpdatePosition": {
                    action: fsm._setPositionFromValue
                },
                "releaseControl": {
                    target: fsmReleased
                }
            })
        }
    }

    Connections {
        target: Player
        function onPositionChanged() {  fsm.playerUpdatePosition(Player.position) }
        function onInputChanged() {  fsm.inputChanged() }
    }

    Component.onCompleted: value = Player.position

    implicitHeight: control.barHeight
    height: implicitHeight

    padding: 0

    //we use our own HoverHandler
    hoverEnabled: false

    HoverHandler {
        id: hoverHandler

        onHoveredChanged: () => {
            if (hovered) {
                if(Player.hasChapters)
                    control._isSeekPointsShown = true
            } else {
                if(Player.hasChapters)
                    seekpointTimer.restart()
            }
        }
    }

    contentItem: Item {
        implicitHeight: control.implicitHeight
        implicitWidth: control.implicitWidth

        //placing the TapHandler directly in the Control doesn't work with 6.2
        TapHandler {
            acceptedButtons: Qt.LeftButton

            gesturePolicy: TapHandler.WithinBounds

            // Make it easier to tap with touch screen:
            margin: MainCtx.usingTouch ? control.touchHandlerMargin : 0.0

            onPressedChanged: {
                if (pressed) {
                    fsm.pressControl(control._positionAt(point.position.x), point.modifiers === Qt.ShiftModifier)
                } else {
                    // NOTE: Point is still valid at this point.
                    fsm.releaseControl(control._positionAt(point.position.x), point.modifiers === Qt.ShiftModifier)
                }
            }
        }

        DragHandler {
            id: dragHandler
            acceptedButtons: Qt.LeftButton

            // Make it easier to drag with touch screen:
            margin: MainCtx.usingTouch ? control.touchHandlerMargin : 0

            target: null
            dragThreshold: 0
            grabPermissions: PointerHandler.CanTakeOverFromAnything

            property bool filterEvents: false

            function moveControl() {
                fsm.moveControl(control._positionAt(dragHandler.centroid.position.x),
                                dragHandler.centroid.modifiers === Qt.ShiftModifier)
            }

            onActiveChanged: {
                if (active) {
                    filterEvents = false
                    fsm.pressControl(control._positionAt(centroid.position.x), centroid.modifiers === Qt.ShiftModifier)
                } else {
                    fsm.releaseControl(control._positionAt(centroid.position.x), centroid.modifiers === Qt.ShiftModifier)
                }
            }

            onCentroidChanged: {
                // FIXME: Qt 6.5 use xAxis.onActiveValueChanged in the DragHandler
                if (filterEvents) {
                    Qt.callLater(dragHandler.moveControl)
                } else {
                    dragHandler.moveControl()
                    filterEvents = true
                }
            }
        }

        WheelHandler {
            orientation: Qt.Vertical | Qt.Horizontal

            acceptedDevices: PointerDevice.AllDevices

            onWheel: (wheel) => {
                wheelToVLC.qmlWheelEvent(wheel)
                wheel.accepted = true
            }
        }

        WheelToVLCConverter {
            id: wheelToVLC

            function handleVertical(steps: int) {
                if (steps > 0)
                    Player.jumpFwd()
                else
                    Player.jumpBwd()
            }

            function handleHorizontal(steps: int) {
                if (steps > 0)
                    Player.jumpBwd()
                else
                    Player.jumpFwd()
            }

            Component.onCompleted: {
                wheelUpDown.connect(wheelToVLC, wheelToVLC.handleVertical)
                wheelLeftRight.connect(wheelToVLC, wheelToVLC.handleHorizontal)
            }
        }
    }

    background: Rectangle {
        id: track

        width: control.availableWidth
        implicitHeight: control.implicitHeight
        height: implicitHeight

        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: control.backgroundColor

        Rectangle {
            id: progressRect

            x: control._inset
            y: control._inset
            width: control._handleX + control._handleWidth - x
            height: parent.height - 2 * control._inset

            visible: !control.waveform
            radius: VLCStyle.dp(4, VLCStyle.scale)
            color: theme.tokens.bgAccentBright

            // We use dynamic mutability group because time interpolation
            // may induce rapid change:
            // TODO: Do not use `Binding` when minimum Qt is 6.12:
            Binding {
                target: progressRect
                property: "mutabilityGroup"
                when: (progressRect.mutabilityGroup !== undefined)
                value: (Player.playingState === Player.PLAYING_STATE_PLAYING) ? Item.DynamicMutabilityGroup
                                                                              : Item.StaticMutabilityGroup
            }
        }

        Loader {
            id: waveLoader

            anchors.fill: parent

            active: control.waveform

            sourceComponent: Item {
                id: wave

                readonly property real pitch: VLCStyle.dp(5, VLCStyle.scale)
                readonly property real barWidth: VLCStyle.dp(2, VLCStyle.scale)
                readonly property real start: VLCStyle.dp(6, VLCStyle.scale)
                readonly property int count: Math.max(0, Math.floor((width - start - control._inset - barWidth) / pitch) + 1)

                // Bars are seeded by the media, so a song always draws the same waveform.
                readonly property int seed: {
                    const text = Player.url.toString()
                    let x = 2166136261
                    for (let i = 0; i < text.length; ++i)
                        x = Math.imul(x ^ text.charCodeAt(i), 16777619)
                    return x >>> 0
                }

                readonly property var heights: [2, 4, 6, 8, 10, 12, 14, 14, 14, 14]
                readonly property var intro: [2, 4, 6, 4, 6, 2, 4, 6, 6, 2]

                function barHeight(i) {
                    if (i < intro.length)
                        return VLCStyle.dp(intro[i], VLCStyle.scale)
                    let x = (seed ^ Math.imul(i, 2654435761)) >>> 0
                    x = Math.imul(x ^ (x >>> 15), 2246822507) >>> 0
                    x = Math.imul(x ^ (x >>> 13), 3266489909) >>> 0
                    return VLCStyle.dp(heights[((x ^ (x >>> 16)) >>> 0) % heights.length], VLCStyle.scale)
                }

                component Bars : Repeater {
                    id: bars

                    required property color barColor

                    model: wave.count

                    Rectangle {
                        required property int index

                        x: wave.start + index * wave.pitch
                        width: wave.barWidth
                        height: wave.barHeight(index)
                        y: (wave.height - height) / 2
                        radius: VLCStyle.dp(1, VLCStyle.scale)
                        color: bars.barColor
                    }
                }

                Bars {
                    barColor: theme.tokens.fgA4
                }

                Item {
                    width: control._handleX
                    height: parent.height
                    clip: true

                    Bars {
                        barColor: theme.tokens.accentDim
                    }
                }
            }
        }

        Repeater {
            model: Player.hasChapters ? Player.chapters : 0

            Rectangle {
                required property var model

                readonly property real startPosition: model.startPosition ?? 0.0

                visible: startPosition > 0 && control._isSeekPointsShown && !control.waveform

                x: control._inset + startPosition * control._range + control._handleWidth / 2 - width / 2
                y: control._inset
                width: VLCStyle.dp(2, VLCStyle.scale)
                height: parent.height - 2 * control._inset

                color: control.backgroundColor
            }
        }

        Rectangle {
            id: bufferRect
            property int bufferAnimWidth: VLCStyle.dp(100, VLCStyle.scale)
            property int bufferAnimPosition: 0
            property int bufferFrames: 1000
            property alias animateLoading: loadingAnim.running
            property bool display: false
            property bool buffering: Player.buffering > 0 && Player.buffering < 1

            y: control._inset
            height: parent.height - 2 * control._inset
            opacity: 0.4
            color: theme.accent
            radius: VLCStyle.dp(4, VLCStyle.scale)

            // TODO: Do not use `Binding` when minimum Qt is 6.12:
            Binding {
                target: bufferRect
                property: "mutabilityGroup"
                when: bufferRect.mutabilityGroup !== undefined
                value: bufferRect.buffering ? Item.DynamicMutabilityGroup
                                            : Item.StaticMutabilityGroup
            }

            Timer {
                id: bufferingTimer
                interval: VLCStyle.duration_humanMoment
                repeat: false
                running: false
                onTriggered: {
                    bufferRect.display = true
                }
            }

            onBufferingChanged: {
                if(buffering)
                {
                    bufferingTimer.start()
                }
                else
                {
                    bufferingTimer.stop()
                    bufferRect.display = false
                }
            }

            states: [
                State {
                    name: "hidden"
                    when: !control.visible
                    PropertyChanges {
                        target: bufferRect
                        width: bufferAnimWidth
                        visible: false
                        x: 0
                        animateLoading: false
                    }
                },
                State {
                    name: "buffering not started"
                    when: control.visible && Player.buffering === 0
                    PropertyChanges {
                        target: bufferRect
                        width: bufferAnimWidth
                        visible: true
                        x: (bufferAnimPosition / bufferFrames) * (parent.width - bufferAnimWidth)
                        animateLoading: true
                    }
                },
                State {
                    name: "time to start playing known"
                    when: control.visible && bufferRect.display
                    PropertyChanges {
                        target: bufferRect
                        width: Player.buffering * parent.width
                        visible: true
                        x: 0
                        animateLoading: false
                    }
                },
                State {
                    name: "playing from buffer"
                    when: control.visible && !bufferRect.display
                    PropertyChanges {
                        target: bufferRect
                        width: Player.buffering * parent.width
                        visible: false
                        x: 0
                        animateLoading: false
                    }
                }
            ]

            SequentialAnimation on bufferAnimPosition {
                id: loadingAnim
                running: bufferRect.animateLoading
                loops: Animation.Infinite
                PropertyAnimation {
                    from: 0.0
                    to: bufferRect.bufferFrames
                    duration: VLCStyle.durationSliderBouncing
                    easing.type: "OutBounce"
                }
                PauseAnimation {
                    duration: VLCStyle.duration_veryLong
                }
                PropertyAnimation {
                    from: bufferRect.bufferFrames
                    to: 0.0
                    duration: VLCStyle.durationSliderBouncing
                    easing.type: "OutBounce"
                }
                PauseAnimation {
                    duration: VLCStyle.duration_veryLong
                }
            }
        }

        Rectangle {
            id: sliderHandle

            x: control._handleX
            y: control._inset
            width: control._handleWidth
            height: parent.height - 2 * control._inset

            visible: control.enabled && control.handleVisible
            radius: VLCStyle.dp(control.waveform ? 1 : 4, VLCStyle.scale)
            color: theme.accent

            border.width: control.visualFocus ? VLCStyle.dp(1, VLCStyle.scale) : 0
            border.color: theme.tokens.fg1

            // We use dynamic mutability group because time interpolation
            // may induce rapid change:
            // TODO: Do not use `Binding` when minimum Qt is 6.12:
            Binding {
                target: sliderHandle
                property: "mutabilityGroup"
                when: (sliderHandle.mutabilityGroup !== undefined)
                value: (Player.playingState === Player.PLAYING_STATE_PLAYING) ? Item.DynamicMutabilityGroup
                                                                              : Item.StaticMutabilityGroup
            }
        }
    }
}
