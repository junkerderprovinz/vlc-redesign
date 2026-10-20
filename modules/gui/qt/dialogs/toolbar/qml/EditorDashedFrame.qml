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
Canvas {
    id: frame

    property color color: "transparent"
    property color fillColor: "transparent"
    property real dashLength: VLCStyle.dp(4, VLCStyle.scale)
    property real lineWidth: VLCStyle.border

    onColorChanged: requestPaint()
    onFillColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()

        const w = Math.floor(width)
        const h = Math.floor(height)
        if (w <= 0 || h <= 0)
            return

        if (fillColor.a > 0) {
            ctx.fillStyle = fillColor
            ctx.fillRect(0, 0, w, h)
        }

        ctx.fillStyle = color

        const step = dashLength * 2

        for (let x = 0; x < w; x += step) {
            const length = Math.min(dashLength, w - x)
            ctx.fillRect(x, 0, length, lineWidth)
            ctx.fillRect(x, h - lineWidth, length, lineWidth)
        }

        for (let y = 0; y < h; y += step) {
            const length = Math.min(dashLength, h - y)
            ctx.fillRect(0, y, lineWidth, length)
            ctx.fillRect(w - lineWidth, y, lineWidth, length)
        }
    }
}
