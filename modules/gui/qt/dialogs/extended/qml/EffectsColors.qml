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

// The design tokens of the palette the player settings panel is drawn with
ColorContext {
    colorSet: ColorContext.Window

    readonly property var tokens: palette ?? VLCStyle.palette

    readonly property color panel: tokens.bgB1Glass
    readonly property color field: tokens.bgB2
    readonly property color card: tokens.bgA3
    readonly property color hover: tokens.bgA4
    readonly property color divider: tokens.dividerDim

    readonly property color heading: tokens.fgA1
    readonly property color text: tokens.fgA2
    readonly property color label: tokens.fgA3
}
