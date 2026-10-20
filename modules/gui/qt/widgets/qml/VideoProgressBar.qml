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
import VLC.Style

// The bar lies on the bottom edge of the thumbnail. It is the clipped bottom
// slice of a rectangle with the thumbnail radius, so its ends follow the corners.
Item {
    id: progressBar

    implicitHeight: VLCStyle.dp(4, VLCStyle.scale)

    clip: true

    property real value: 0
    property int radius: implicitHeight

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Slider
    }

    Rectangle {
        id: rectangle

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        height: Math.max(progressBar.radius * 2, parent.height + radius)

        radius: progressBar.radius

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: progressBar.value; color: theme.accent }
            GradientStop { position: progressBar.value + (1. / rectangle.width); color: "transparent" }
        }
    }
}
