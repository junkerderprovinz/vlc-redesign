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

// Rectangle outline drawn with dashes of equal length and gap.
Item {
    id: frame

    property color color: "transparent"
    property color fillColor: "transparent"
    property real dashLength: VLCStyle.dp(4, VLCStyle.scale)
    property real lineWidth: VLCStyle.border

    readonly property real _width: Math.floor(width)
    readonly property real _height: Math.floor(height)
    readonly property real _step: 2 * dashLength
    readonly property int _columns: Math.ceil(_width / _step)
    readonly property int _rows: Math.ceil(_height / _step)

    Rectangle {
        width: frame._width
        height: frame._height

        visible: frame.fillColor.a > 0
        color: frame.fillColor
    }

    Repeater {
        model: frame._columns

        delegate: Rectangle {
            required property int index

            x: index * frame._step
            width: Math.min(frame.dashLength, frame._width - x)
            height: frame.lineWidth
            color: frame.color
        }
    }

    Repeater {
        model: frame._columns

        delegate: Rectangle {
            required property int index

            x: index * frame._step
            y: frame._height - frame.lineWidth
            width: Math.min(frame.dashLength, frame._width - x)
            height: frame.lineWidth
            color: frame.color
        }
    }

    Repeater {
        model: frame._rows

        delegate: Rectangle {
            required property int index

            y: index * frame._step
            width: frame.lineWidth
            height: Math.min(frame.dashLength, frame._height - y)
            color: frame.color
        }
    }

    Repeater {
        model: frame._rows

        delegate: Rectangle {
            required property int index

            x: frame._width - frame.lineWidth
            y: index * frame._step
            width: frame.lineWidth
            height: Math.min(frame.dashLength, frame._height - y)
            color: frame.color
        }
    }
}
