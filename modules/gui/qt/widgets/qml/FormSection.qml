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

// A titled group of settings, separated from the group above by a line
ColumnLayout {
    id: root

    property string title
    property bool separator: true
    // the title leads somewhere, headingClicked() is emitted on a click
    property bool linked: false

    default property alias content: body.data
    property alias bodySpacing: body.spacing

    // the margins of the rows; the title sits a little further in
    property real padding: VLCStyle.dp(20, VLCStyle.scale)
    property real headingIndent: VLCStyle.dp(4, VLCStyle.scale)
    property real headingTopMargin: VLCStyle.dp(20, VLCStyle.scale)
    property real headingHeight: -1
    property real bodyTopMargin: VLCStyle.dp(10, VLCStyle.scale)
    property real bodyBottomMargin: VLCStyle.dp(20, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    property color headingColor: theme.tokens.fgA1
    property color linkColor: theme.tokens.fg1

    signal headingClicked()

    Layout.fillWidth: true
    spacing: 0

    Rectangle {
        visible: root.separator

        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.border

        color: theme.tokens.dividerDim
    }

    T.AbstractButton {
        id: heading

        visible: root.title !== ""

        Layout.topMargin: root.headingTopMargin
        Layout.leftMargin: root.padding + root.headingIndent
        Layout.rightMargin: root.padding + root.headingIndent
        Layout.preferredHeight: root.headingHeight

        enabled: root.linked
        focusPolicy: root.linked ? Qt.StrongFocus : Qt.NoFocus
        text: root.title

        Accessible.role: root.linked ? Accessible.Link : Accessible.Heading

        onClicked: root.headingClicked()

        background: null

        contentItem: Row {
            spacing: VLCStyle.dp(4, VLCStyle.scale)

            Widgets.LabelExt {
                anchors.verticalCenter: parent.verticalCenter
                text: heading.text
                color: heading.hovered ? root.linkColor : root.headingColor
                font.pixelSize: VLCStyle.fontSize_large
                font.weight: Font.Medium
            }

            Widgets.IconLabel {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.linked
                text: VLCIcons.chevron_right
                color: theme.tokens.fgA2
                font.pixelSize: VLCStyle.icon_normal
            }
        }
    }

    ColumnLayout {
        id: body

        Layout.fillWidth: true
        Layout.topMargin: root.bodyTopMargin
        Layout.bottomMargin: root.bodyBottomMargin
        Layout.leftMargin: root.padding
        Layout.rightMargin: root.padding

        spacing: VLCStyle.dp(5, VLCStyle.scale)
    }
}
