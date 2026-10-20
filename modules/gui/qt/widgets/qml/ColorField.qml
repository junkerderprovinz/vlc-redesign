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

import VLC.Style
import VLC.Widgets as Widgets

// A hexadecimal color box with a swatch. VLC keeps colors as 0xRRGGBB, so
// `rgb` is that number; picked() reports a valid typed color.
Widgets.FormTextField {
    id: root

    property int rgb: 0
    // the swatch is a button, swatchClicked() asks for a color picker
    property bool pickable: false

    readonly property alias swatch: swatchButton

    signal picked(int rgb)
    signal swatchClicked()

    function hex(value) {
        return "#" + (value & 0xFFFFFF).toString(16).toUpperCase().padStart(6, "0")
    }

    implicitWidth: VLCStyle.dp(116, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)
    rightPadding: swatchButton.width + VLCStyle.dp(10, VLCStyle.scale)

    value: hex(rgb)

    onCommitted: (text) => {
        const typed = text.trim().replace(/^#/, "")
        if (/^[0-9a-fA-F]{6}$/.test(typed))
            root.picked(parseInt(typed, 16))
    }

    T.AbstractButton {
        id: swatchButton

        anchors.right: parent.right
        anchors.rightMargin: VLCStyle.dp(5, VLCStyle.scale)
        anchors.verticalCenter: parent.verticalCenter

        width: VLCStyle.dp(22, VLCStyle.scale)
        height: width

        enabled: root.pickable
        focusPolicy: Qt.NoFocus

        Accessible.name: qsTr("Pick a color")

        onClicked: root.swatchClicked()

        background: Rectangle {
            radius: VLCStyle.dp(2, VLCStyle.scale)
            color: root.hex(root.rgb)
            border.width: VLCStyle.dp(1.5, VLCStyle.scale)
            border.color: Qt.rgba(1, 1, 1, 0.21)
        }
    }
}
