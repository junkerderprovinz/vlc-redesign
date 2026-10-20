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
pragma Singleton

import QtQuick

import VLC.Style

// Short names for the palette tokens and metrics the settings dialog uses.
QtObject {
    readonly property SystemPalette palette: VLCStyle.palette

    readonly property bool dark: palette.isDark

    readonly property color accent: palette.accent
    readonly property color accentDim: palette.accentDim
    readonly property color accentBgBright: palette.bgAccentBright

    readonly property color fg1: palette.fg1
    readonly property color fg2: palette.fg2
    readonly property color fgA1: palette.fgA1
    readonly property color fgA2: palette.fgA2
    readonly property color fgA3: palette.fgA3
    readonly property color fgA4: palette.fgA4

    readonly property color bgA1: palette.bgA1
    readonly property color bgA2: palette.bgA2
    readonly property color bgA3: palette.bgA3
    readonly property color bgA4: palette.bgA4
    readonly property color bgA5: palette.bgA5
    readonly property color bgB1: palette.bgB1
    readonly property color bgB2: palette.bgB2
    readonly property color bgA3Glass: palette.bgA3Glass

    readonly property color danger: "#d33718"

    function mix(a, b, amount) {
        return Qt.rgba(a.r * amount + b.r * (1 - amount),
                       a.g * amount + b.g * (1 - amount),
                       a.b * amount + b.b * (1 - amount),
                       1)
    }

    function dp(px) {
        return VLCStyle.dp(px, VLCStyle.scale)
    }

    readonly property real fontSmall: dp(12)
    readonly property real fontNormal: dp(14)
    readonly property real fontLarge: dp(16)

    readonly property real controlWidth: dp(320)
}
