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

import VLC.Style

// Paints everything around `target` and rounds its corners. The video is
// composited below the interface, so the frame has to be drawn over it.
Item {
    id: root

    required property Item target

    property real frameWidth: VLCStyle.dp(10, VLCStyle.scale)
    property real radius: VLCStyle.dp(9, VLCStyle.scale)
    property color color

    readonly property rect _hole: Qt.rect(target.x, target.y, target.width, target.height)

    visible: frameWidth > 0

    Rectangle {
        width: parent.width
        height: root._hole.y
        color: root.color
    }

    Rectangle {
        y: root._hole.y + root._hole.height
        width: parent.width
        height: parent.height - y
        color: root.color
    }

    Rectangle {
        y: root._hole.y
        width: root._hole.x
        height: root._hole.height
        color: root.color
    }

    Rectangle {
        x: root._hole.x + root._hole.width
        y: root._hole.y
        width: parent.width - x
        height: root._hole.height
        color: root.color
    }

    // Rounds the corners of the hole: a border as thick as the corner, with
    // an inner radius equal to the frame radius.
    Rectangle {
        readonly property real thickness: root.radius + 1

        x: root._hole.x - thickness
        y: root._hole.y - thickness
        width: root._hole.width + 2 * thickness
        height: root._hole.height + 2 * thickness

        radius: root.radius + thickness
        color: "transparent"
        border.width: thickness
        border.color: root.color

        antialiasing: true
    }
}
