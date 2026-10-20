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

// A hexadecimal colour box with a swatch; VLC keeps these colours as 0xRRGGBB
EffectsValueField {
    id: root

    property int rgb: 0

    signal picked(int rgb)

    numeric: false
    implicitWidth: VLCStyle.dp(116, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
    rightPadding: swatch.width + VLCStyle.dp(10, VLCStyle.scale)

    function _hex(value) {
        return "#" + (value & 0xFFFFFF).toString(16).toUpperCase().padStart(6, "0")
    }

    function _show() {
        text = _hex(rgb)
    }

    onRgbChanged: if (!activeFocus) _show()
    Component.onCompleted: _show()
    onActiveFocusChanged: if (!activeFocus) _show()

    onEditingFinished: {
        const typed = text.trim().replace(/^#/, "")
        if (/^[0-9a-fA-F]{6}$/.test(typed))
            root.picked(parseInt(typed, 16))
        _show()
    }

    Rectangle {
        id: swatch

        anchors.right: parent.right
        anchors.rightMargin: VLCStyle.dp(5, VLCStyle.scale)
        anchors.verticalCenter: parent.verticalCenter

        width: VLCStyle.dp(22, VLCStyle.scale)
        height: width
        radius: VLCStyle.dp(2, VLCStyle.scale)

        color: root._hex(root.rgb)
        border.width: VLCStyle.dp(1.5, VLCStyle.scale)
        border.color: Qt.rgba(1, 1, 1, 0.21)
    }
}
