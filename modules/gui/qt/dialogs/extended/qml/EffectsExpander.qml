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
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.Style
import VLC.Widgets as Widgets

// The "Expand Settings" card that unfolds the settings of a filter
Rectangle {
    id: root

    // an object remembering which cards are open, under `key`
    property var store: null
    property string key

    property bool expanded: (store && key) ? !!store[key] : false

    onExpandedChanged: {
        if (store && key)
            store[key] = expanded
    }

    default property alias content: body.data

    readonly property EffectsColors colors: EffectsColors { }

    Layout.fillWidth: true
    implicitHeight: head.height + (expanded ? body.implicitHeight + VLCStyle.dp(10, VLCStyle.scale) : 0)

    radius: VLCStyle.dp(6, VLCStyle.scale)
    color: expanded ? colors.card : colors.field

    T.AbstractButton {
        id: head

        width: parent.width
        height: VLCStyle.dp(48, VLCStyle.scale)

        leftPadding: VLCStyle.dp(16, VLCStyle.scale)
        rightPadding: VLCStyle.dp(10, VLCStyle.scale)

        text: root.expanded ? qsTr("Collapse Settings") : qsTr("Expand Settings")

        Accessible.role: Accessible.Button
        Accessible.name: text

        onClicked: root.expanded = !root.expanded

        contentItem: RowLayout {
            Widgets.LabelExt {
                Layout.fillWidth: true

                text: head.text
                color: head.hovered ? root.colors.text : root.colors.label
                font.pixelSize: VLCStyle.fontSize_normal
            }

            Widgets.IconLabel {
                text: root.expanded ? VLCIcons.chevron_down : VLCIcons.chevron_right
                color: head.hovered ? root.colors.text : root.colors.label
                font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
            }
        }

        background: Rectangle {
            radius: root.radius
            color: "transparent"
            border.width: head.visualFocus ? VLCStyle.dp(2, VLCStyle.scale) : 0
            border.color: root.colors.accent
        }
    }

    ColumnLayout {
        id: body

        anchors.top: head.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
        anchors.rightMargin: VLCStyle.dp(16, VLCStyle.scale)

        visible: root.expanded
        spacing: VLCStyle.dp(10, VLCStyle.scale)
    }
}
