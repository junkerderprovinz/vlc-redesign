/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
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


import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Player
import VLC.Playlist
import VLC.Util

T.Control {
    id: root

    // Properties

    property bool paintOnly: false

    readonly property bool playing: !paintOnly
                                    && Player.playingState !== Player.PLAYING_STATE_PAUSED
                                    && Player.playingState !== Player.PLAYING_STATE_STOPPED

    // the colour context has no palette until it is attached
    readonly property var _tokens: theme.palette ?? VLCStyle.palette

    readonly property ColorContext colorContext: ColorContext {
        id: theme

        colorSet: ColorContext.ButtonAccent

        enabled: root.enabled || root.paintOnly
        focused: root.activeFocus
        hovered: root.cursorInside
        pressed: mouseArea.containsPress
    }

    property bool _keyOkPressed: false

    // Aliases

    property alias cursorInside: mouseArea.containsMouse

    // Settings

    implicitWidth: implicitBackgroundWidth + leftInset + rightInset
    implicitHeight: implicitBackgroundHeight + topInset + bottomInset

    // Optically centres the play glyph.
    leftPadding: VLCStyle.dp(playing ? 15 : 17, VLCStyle.scale)
    rightPadding: VLCStyle.dp(15, VLCStyle.scale)
    verticalPadding: VLCStyle.dp(2, VLCStyle.scale)

    scale: (_keyOkPressed || (mouseArea.pressed && cursorInside)) ? 0.95
                                                                  : 1.00

    Accessible.role: Accessible.Button
    Accessible.name: playing ? qsTr("Pause") : qsTr("Play")
    AccessibleCompat.id: "playButton"
    Accessible.checkable: true
    Accessible.checked: playing
    Accessible.onPressAction: MainPlaylistController.togglePlayPause()
    Accessible.onToggleAction: MainPlaylistController.togglePlayPause()

    // Tooltip

    T.ToolTip.visible: (hovered || visualFocus)
    T.ToolTip.delay: VLCStyle.delayToolTipAppear
    T.ToolTip.text: root.Accessible.name

    // Keys

    Keys.onPressed: (event) => {
        if (KeyHelper.matchOk(event) ) {
            if (!event.isAutoRepeat) {
                _keyOkPressed = true
                keyHoldTimer.restart()
            }
            event.accepted = true
        }
        Navigation.defaultKeyAction(event)
    }

    Keys.onReleased: (event) => {
        if (KeyHelper.matchOk(event)) {
            if (!event.isAutoRepeat) {
                _keyOkPressed = false
                keyHoldTimer.stop()
                if (Player.playingState !== Player.PLAYING_STATE_STOPPED)
                    MainPlaylistController.togglePlayPause()
            }
            event.accepted = true
        }
    }

    // Functions

    function _pressAndHoldAction() {
        _keyOkPressed = false
        MainPlaylistController.stop()
    }

    // Children

    Timer {
        id: keyHoldTimer

        interval: mouseArea.pressAndHoldInterval
        repeat: false

        Component.onCompleted: {
            triggered.connect(_pressAndHoldAction)
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent

        hoverEnabled: true

        onPressed: (mouse) => {
            root.forceActiveFocus(Qt.MouseFocusReason)
        }

        onClicked: (mouse) => {
            MainPlaylistController.togglePlayPause()
            mouse.accepted = true
        }

        onPressAndHold: (mouse) => {
            _pressAndHoldAction()
            mouse.accepted = true
        }
    }

    contentItem: Widgets.IconLabel {
        text: root.playing ? VLCIcons.pause_filled : VLCIcons.play_filled

        color: root.playing ? _tokens.bgB1 : theme.fg.primary

        font.pixelSize: VLCStyle.icon_toolbar

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

    background: Rectangle {
        implicitWidth: VLCStyle.dp(54, VLCStyle.scale)
        implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

        radius: VLCStyle.dp(6, VLCStyle.scale)

        color: {
            if (!root.playing)
                return theme.bg.primary
            return root.cursorInside ? _tokens.fgA2 : _tokens.fgA3
        }

        border.width: root.visualFocus ? VLCStyle.dp(1, VLCStyle.scale) : 0
        border.color: _tokens.fg1

        Behavior on color {
            enabled: theme.initialized

            ColorAnimation {
                duration: VLCStyle.duration_veryShort
                easing.type: Easing.InOutSine
            }
        }
    }
}
