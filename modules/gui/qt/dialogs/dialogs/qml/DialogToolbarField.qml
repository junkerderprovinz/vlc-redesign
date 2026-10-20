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

import VLC.Widgets as Widgets
import VLC.Style

// A text field of a dialog toolbar with a leading icon. A read only field
// acts as a button.
FocusScope {
    id: root

    property alias iconText: icon.text
    property alias text: input.text
    property alias placeholderText: placeholder.text
    property bool readOnly: false

    signal clicked()

    Layout.fillWidth: true
    Layout.fillHeight: true

    implicitHeight: VLCStyle.dp(34, VLCStyle.scale)

    activeFocusOnTab: true

    Accessible.role: readOnly ? Accessible.Button : Accessible.EditableText
    Accessible.name: input.text.length > 0 ? input.text : placeholder.text
    Accessible.onPressAction: if (readOnly) root.clicked()

    Keys.onPressed: (event) => {
        if (readOnly && (event.key === Qt.Key_Return || event.key === Qt.Key_Space)) {
            event.accepted = true
            root.clicked()
        }
    }

    Rectangle {
        anchors.fill: parent

        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: (root.readOnly && hoverHandler.hovered) ? (VLCStyle.palette.isDark ? VLCStyle.palette.bgA4 : VLCStyle.palette.bgA1)
                                                        : (VLCStyle.palette.isDark ? VLCStyle.palette.bgA5 : VLCStyle.palette.bgA2)
        border.color: VLCStyle.palette.accentDim
        border.width: (input.activeFocus || (root.readOnly && root.activeFocus)) ? VLCStyle.focus_border : 0
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: root.readOnly ? Qt.PointingHandCursor : Qt.IBeamCursor
    }

    TapHandler {
        enabled: root.readOnly
        onTapped: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
        anchors.rightMargin: VLCStyle.dp(8, VLCStyle.scale)

        spacing: VLCStyle.dp(10, VLCStyle.scale)

        Widgets.IconLabel {
            id: icon

            color: VLCStyle.palette.fgA2
            font.pixelSize: VLCStyle.icon_normal
        }

        TextInput {
            id: input

            Layout.fillWidth: true

            focus: !root.readOnly
            readOnly: root.readOnly
            enabled: !root.readOnly
            clip: true

            color: VLCStyle.palette.fgA1
            selectionColor: VLCStyle.palette.bgAccentBright
            selectedTextColor: VLCStyle.palette.fg1
            font.pixelSize: VLCStyle.fontSize_large
            verticalAlignment: TextInput.AlignVCenter

            Widgets.LabelExt {
                id: placeholder

                anchors.fill: parent

                visible: input.text.length === 0
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight
                color: VLCStyle.palette.fgA4
                font.pixelSize: VLCStyle.fontSize_large
                textFormat: Text.PlainText
            }
        }
    }
}
