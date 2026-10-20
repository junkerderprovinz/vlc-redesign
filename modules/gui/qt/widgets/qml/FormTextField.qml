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
import VLC.Widgets as Widgets

// A text field that shows `value` while it is not edited and reports a
// finished edit through committed(), and through numberCommitted() when the
// text is a number. Escape restores the value.
Widgets.TextFieldExt {
    id: root

    property string value
    // shown after the text
    property string unit

    signal committed(string text)
    signal numberCommitted(real number)

    implicitWidth: VLCStyle.dp(140, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(36, VLCStyle.scale)

    topPadding: 0
    bottomPadding: 0
    rightPadding: unitLabel.visible ? unitLabel.width + VLCStyle.dp(18, VLCStyle.scale)
                                    : VLCStyle.dp(18, VLCStyle.scale)

    font.pixelSize: VLCStyle.fontSize_normal
    selectByMouse: true

    text: value

    onEditingFinished: {
        if (text !== value) {
            committed(text)
            const number = parseFloat(text.replace(",", "."))
            if (Number.isFinite(number))
                numberCommitted(number)
        }
        text = value
    }

    onValueChanged: {
        if (!activeFocus)
            text = value
    }

    onActiveFocusChanged: {
        if (activeFocus)
            selectAll()
        else
            text = value
    }

    Keys.onEscapePressed: (event) => {
        event.accepted = text !== value
        text = value
    }

    Text {
        id: unitLabel

        x: Math.min(root.leftPadding + root.contentWidth + VLCStyle.dp(4, VLCStyle.scale),
                    root.width - width - VLCStyle.dp(14, VLCStyle.scale))
        anchors.verticalCenter: parent.verticalCenter
        visible: root.unit.length > 0 && root.text.length > 0
        text: root.unit
        color: root.colorContext.tokens.fgA3
        font.pixelSize: root.font.pixelSize
    }
}
