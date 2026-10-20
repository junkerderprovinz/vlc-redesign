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
import VLC.Dialogs

// A titled group of settings rows
Column {
    id: root

    readonly property var t: SettingsTheme

    required property var modelData

    property string query: ""
    // in the search results the title leads to this page
    property var linkPage: null

    signal actionRequested(string name)
    signal jumpRequested(var row)

    readonly property bool hasVisibleRows: {
        for (let i = 0; i < rows.count; ++i) {
            const item = rows.itemAt(i)
            if (item && item.available)
                return true
        }
        return false
    }

    visible: hasVisibleRows

    T.AbstractButton {
        id: heading

        visible: (root.modelData.title ?? "").length > 0
        width: implicitContentWidth
        height: t.dp(39)
        enabled: root.linkPage !== null
        focusPolicy: root.linkPage ? Qt.StrongFocus : Qt.NoFocus
        text: root.modelData.title ?? ""

        Accessible.role: root.linkPage ? Accessible.Link : Accessible.Heading

        onClicked: root.jumpRequested(null)

        background: null

        contentItem: Row {
            spacing: t.dp(4)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: heading.text
                color: heading.hovered ? t.fg1 : t.fg2
                font.pixelSize: t.fontLarge
                font.weight: Font.Medium
            }

            Widgets.IconLabel {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.linkPage !== null
                text: VLCIcons.chevron_right
                color: t.fgA2
                font.pixelSize: t.dp(24)
            }
        }
    }

    Repeater {
        id: rows

        model: root.modelData.rows

        delegate: SettingsRow {
            required property var modelData

            width: root.width
            row: modelData
            query: root.query

            onActionRequested: (name) => root.actionRequested(name)
            onJumpRequested: root.jumpRequested(modelData)
        }
    }
}
