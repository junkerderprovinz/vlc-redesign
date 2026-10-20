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

import VLC.Widgets as Widgets
import VLC.Style

// List view of compact rows, flowing into as many columns as the width allows.
Widgets.ExpandGridView {
    id: root

    property int minimumCellWidth: VLCStyle.dp(360, VLCStyle.scale)

    nbItemPerRow: Math.max(Math.floor((_availableContentWidth + horizontalSpacing)
                                      / (minimumCellWidth + horizontalSpacing)), 1)

    cellWidth: Math.floor((_availableContentWidth + horizontalSpacing) / nbItemPerRow - horizontalSpacing)
    cellHeight: VLCStyle.dp(32, VLCStyle.scale)

    horizontalSpacing: VLCStyle.dp(10, VLCStyle.scale)
    verticalSpacing: VLCStyle.dp(10, VLCStyle.scale)
}
