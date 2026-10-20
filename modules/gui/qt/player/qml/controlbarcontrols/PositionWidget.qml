/*****************************************************************************
 * Copyright (C) 2026 VLC authors and VideoLAN
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


import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Player
import VLC.Util

// Current time, seek bar and duration in one control bar item.
FocusScope {
    id: root

    property bool paintOnly: false

    readonly property bool _active: Player.playingState === Player.PLAYING_STATE_PLAYING
                                    || Player.playingState === Player.PLAYING_STATE_PAUSED

    implicitWidth: VLCStyle.dp(600, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

    Layout.minimumWidth: VLCStyle.dp(240, VLCStyle.scale)
    Layout.fillWidth: true

    Accessible.role: Accessible.Grouping
    Accessible.name: qsTr("Seek bar")

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    function _format(seconds) {
        seconds = Math.max(0, Math.floor(seconds))
        const pad = (n) => (n < 10 ? "0" : "") + n
        return pad(Math.floor(seconds / 3600)) + ":" + pad(Math.floor(seconds / 60) % 60) + ":" + pad(seconds % 60)
    }

    function _parse(text) {
        const parts = text.trim().split(":")
        let seconds = 0
        for (let i = 0; i < parts.length; ++i) {
            const n = Number(parts[i])
            if (parts[i] === "" || !Number.isFinite(n) || n < 0)
                return -1
            seconds = seconds * 60 + n
        }
        return seconds
    }

    component TimeBox : T.Control {
        id: box

        property alias text: label.text
        property bool highlighted: false

        implicitWidth: VLCStyle.dp(76, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

        Layout.alignment: Qt.AlignVCenter

        hoverEnabled: true

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: (box.hovered || box.highlighted) ? theme.tokens.bgB2 : "transparent"
        }

        contentItem: T.Label {
            id: label

            color: theme.tokens.fgA2
            font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideNone
        }
    }

    RowLayout {
        anchors.fill: parent

        spacing: VLCStyle.margin_xsmall

        opacity: (root._active || root.paintOnly) ? 1.0 : 0.5

        TimeBox {
            id: currentTime

            text: root.paintOnly ? "00:02:10" : root._format(Player.time.toSeconds())

            highlighted: timeInput.visible

            T.ToolTip.visible: hovered && !timeInput.visible
            T.ToolTip.delay: VLCStyle.delayToolTipAppear
            T.ToolTip.text: qsTr("Jump to time")

            contentItem.visible: !timeInput.visible

            TapHandler {
                enabled: root._active && !root.paintOnly

                onTapped: {
                    timeInput.text = currentTime.text
                    timeInput.visible = true
                    timeInput.forceActiveFocus(Qt.MouseFocusReason)
                    timeInput.selectAll()
                }
            }

            TextInput {
                id: timeInput

                anchors.fill: parent

                visible: false

                color: theme.tokens.fgA2
                selectionColor: theme.accent
                selectedTextColor: theme.tokens.fgB1
                font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                horizontalAlignment: TextInput.AlignHCenter
                verticalAlignment: TextInput.AlignVCenter

                Accessible.name: qsTr("Jump to time")

                function finish(commit) {
                    if (!visible)
                        return
                    visible = false
                    if (!commit)
                        return
                    const seconds = root._parse(text)
                    const length = Player.length.toSeconds()
                    if (seconds >= 0 && length > 0)
                        Player.position = Math.min(seconds / length, 1.0)
                }

                Keys.onReturnPressed: finish(true)
                Keys.onEnterPressed: finish(true)
                Keys.onEscapePressed: finish(false)

                onActiveFocusChanged: {
                    if (!activeFocus)
                        finish(false)
                }
            }
        }

        SliderBar {
            id: trackPositionSlider

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            barHeight: VLCStyle.dp(28, VLCStyle.scale)

            waveform: !Player.hasVideoOutput && !root.paintOnly
            enabled: root._active && !root.paintOnly

            focus: true
            activeFocusOnTab: true

            Accessible.role: Accessible.Slider
            Accessible.name: qsTr("Progress")
            AccessibleCompat.id: "progressSlider"

            Navigation.parentItem: root
            Keys.onPressed: (event) => Navigation.defaultKeyAction(event)
        }

        TimeBox {
            id: duration

            readonly property bool showRemaining: MainCtx.showRemainingTime && Player.remainingTime.valid()

            text: {
                if (root.paintOnly)
                    return "00:25:40"
                if (showRemaining)
                    return "-" + root._format(Player.remainingTime.toSeconds())
                return root._format(Player.length.toSeconds())
            }

            T.ToolTip.visible: hovered
            T.ToolTip.delay: VLCStyle.delayToolTipAppear
            T.ToolTip.text: showRemaining ? qsTr("Show duration") : qsTr("Show remaining time")

            TapHandler {
                enabled: !root.paintOnly
                onTapped: MainCtx.showRemainingTime = !MainCtx.showRemainingTime
            }
        }
    }
}
