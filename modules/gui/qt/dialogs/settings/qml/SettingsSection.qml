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

import VLC.Widgets as Widgets
import VLC.Dialogs

// The rows of one section of a settings page
Widgets.FormSection {
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

    title: modelData.title ?? ""
    linked: linkPage !== null
    separator: false
    padding: 0
    headingIndent: 0
    headingTopMargin: 0
    headingHeight: t.dp(39)
    bodyTopMargin: 0
    bodyBottomMargin: 0
    bodySpacing: 0
    headingColor: t.fg2

    onHeadingClicked: root.jumpRequested(null)

    Repeater {
        id: rows

        model: root.modelData.rows

        delegate: SettingsRow {
            required property var modelData

            Layout.fillWidth: true
            row: modelData
            query: root.query

            onActionRequested: (name) => root.actionRequested(name)
            onJumpRequested: root.jumpRequested(modelData)
        }
    }
}
