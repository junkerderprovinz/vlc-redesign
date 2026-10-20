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

import VLC.Style
import VLC.Widgets as Widgets

// A setting: its label on the left, with an optional explanation behind an
// info icon, and its controls on the right.
RowLayout {
    id: root

    property string label
    // the first match of this text in the label is drawn in the accent color
    property string highlight
    property string info
    property bool labelVisible: true
    // the label leads somewhere, labelClicked() is emitted on a click
    property bool linked: false

    property real minimumHeight: VLCStyle.dp(48, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    property color labelColor: theme.tokens.fgA3
    property color linkColor: theme.tokens.fg1

    signal labelClicked()

    function _highlighted() {
        const escape = (s) => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        const at = label.toLowerCase().indexOf(highlight.toLowerCase())
        if (at < 0)
            return escape(label)
        return escape(label.slice(0, at)) + "<font color=\"" + theme.tokens.accent + "\">"
               + escape(label.slice(at, at + highlight.length)) + "</font>"
               + escape(label.slice(at + highlight.length))
    }

    Layout.fillWidth: true
    Layout.minimumHeight: minimumHeight
    // in line with the title of a FormSection
    Layout.leftMargin: VLCStyle.dp(4, VLCStyle.scale)

    spacing: VLCStyle.dp(10, VLCStyle.scale)

    Widgets.LabelExt {
        id: labelItem

        Layout.fillWidth: true
        // styled text reports the width it is given, the plain text is measured instead
        Layout.maximumWidth: Math.ceil(labelMetrics.advanceWidth)

        visible: root.labelVisible
        text: root.highlight.length > 0 ? root._highlighted() : root.label
        textFormat: root.highlight.length > 0 ? Text.StyledText : Text.PlainText
        color: labelLink.containsMouse ? root.linkColor : root.labelColor
        font.pixelSize: VLCStyle.fontSize_normal
        elide: Text.ElideRight

        TextMetrics {
            id: labelMetrics

            font: labelItem.font
            text: root.label
        }

        MouseArea {
            id: labelLink

            anchors.fill: parent
            enabled: root.linked
            hoverEnabled: enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.labelClicked()
        }
    }

    Widgets.IconLabel {
        visible: root.labelVisible && root.info.length > 0
        text: VLCIcons.info
        color: infoHover.hovered ? theme.tokens.fgA2 : theme.tokens.fgA4
        font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)

        HoverHandler { id: infoHover }

        Widgets.ToolTipExt {
            visible: infoHover.hovered
            text: root.info
            delay: VLCStyle.delayToolTipAppear
        }
    }

    Item {
        visible: root.labelVisible
        Layout.fillWidth: true
    }
}
