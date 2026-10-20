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

// The ON/OFF toggle drawn by CheckButton and CheckBoxExt.
Rectangle {
    id: root

    property bool checked: false

    // 0.0 puts the knob on the left (off), 1.0 on the right (on)
    property real position: checked ? 1.0 : 0.0

    property bool animated: true

    property int animationDuration: VLCStyle.duration_short

    property bool visualFocus: false

    property color plateColor: checked ? theme.bg.secondary : theme.bg.highlight
    property color knobColor: checked ? theme.accent : theme.indicator
    property color textColor: checked ? theme.fg.secondary : theme.fg.primary

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Switch

        enabled: root.enabled
        focused: root.visualFocus
    }

    readonly property real _inset: VLCStyle.dp(3, VLCStyle.scale)

    implicitWidth: VLCStyle.dp(68, VLCStyle.scale)
    implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

    radius: VLCStyle.dp(6, VLCStyle.scale)

    color: theme.bg.primary

    border.width: visualFocus ? VLCStyle.focus_border : 0
    border.color: theme.visualFocus

    Behavior on position {
        enabled: root.animated

        NumberAnimation {
            duration: root.animationDuration
            easing.type: Easing.OutQuad
        }
    }

    Rectangle {
        id: plate

        x: root._inset + (1.0 - root.position) * (root.width - root._inset * 2 - width)
        y: root._inset

        width: VLCStyle.dp(33, VLCStyle.scale)
        height: root.height - root._inset * 2

        radius: VLCStyle.dp(3, VLCStyle.scale)

        color: root.plateColor

        Text {
            anchors.centerIn: parent

            text: root.checked ? qsTr("ON") : qsTr("OFF")

            color: root.textColor

            font.pixelSize: VLCStyle.fontSize_normal

            Accessible.ignored: true
        }
    }

    Rectangle {
        x: root._inset + root.position * (root.width - root._inset * 2 - width)
        y: root._inset

        width: height
        height: plate.height

        radius: plate.radius

        color: root.knobColor
    }
}
