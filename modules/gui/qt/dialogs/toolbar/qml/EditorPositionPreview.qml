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

import VLC.Style
import VLC.Player

// Picture of the seek bar for the editor. The real one handles the pointer
// itself and would take the drag away from the editor.
Item {
    id: root

    property bool paintOnly: true

    implicitWidth: VLCStyle.dp(600, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

    Layout.minimumWidth: VLCStyle.dp(240, VLCStyle.scale)

    readonly property bool _started: Player.length.valid() && Player.length.toSeconds() > 0
    readonly property real _position: _started ? Player.position : 0.1

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    RowLayout {
        anchors.fill: parent

        spacing: VLCStyle.margin_xsmall

        T.Label {
            Layout.preferredWidth: VLCStyle.dp(76, VLCStyle.scale)

            text: root._started ? Player.time.formatHMS() : "00:02:10"
            color: theme.palette.fgA2
            font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            id: track

            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: theme.palette.bgB2

            readonly property real inset: VLCStyle.dp(2, VLCStyle.scale)
            readonly property real thumbWidth: VLCStyle.dp(8, VLCStyle.scale)
            readonly property real thumbX: inset + root._position * (width - 2 * inset - thumbWidth)

            Rectangle {
                x: track.inset
                y: track.inset
                width: track.thumbX - track.inset + track.thumbWidth
                height: parent.height - 2 * track.inset

                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: theme.palette.bgAccentBright
            }

            Rectangle {
                x: track.thumbX
                y: track.inset
                width: track.thumbWidth
                height: parent.height - 2 * track.inset

                radius: VLCStyle.dp(4, VLCStyle.scale)
                color: theme.palette.accent
            }
        }

        T.Label {
            Layout.preferredWidth: VLCStyle.dp(76, VLCStyle.scale)

            text: root._started ? Player.length.formatHMS() : "00:25:40"
            color: theme.palette.fgA2
            font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
