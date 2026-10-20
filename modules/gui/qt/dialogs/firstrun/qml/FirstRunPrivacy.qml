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

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Dialogs

FocusScope {
    id: root

    required property FirstRunController controller

    readonly property bool hasAside: false

    readonly property ColorContext colorContext: ColorContext {
        palette: VLCStyle.palette
        colorSet: ColorContext.Window
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        // centred in the area above the footer
        y: (VLCStyle.dp(655, VLCStyle.scale) - height) / 2

        width: VLCStyle.dp(595, VLCStyle.scale)

        spacing: VLCStyle.dp(40, VLCStyle.scale)

        T.Label {
            width: parent.width

            text: qsTr("Choose what VLC may fetch from the Internet.")
            color: VLCStyle.palette.fgA1
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            font.pixelSize: VLCStyle.dp(24, VLCStyle.scale)
            font.weight: Font.Light
        }

        T.Label {
            width: parent.width

            text: qsTr("<p>In order to protect your privacy, <i>VLC media player</i> "
                       + "does <b>not</b> collect personal data or transmit them, "
                       + "not even in anonymized form, to anyone."
                       + "</p>\n"
                       + "<p>Nevertheless, <i>VLC</i> is able to automatically retrieve "
                       + "information about the media in your play queue from third party "
                       + "Internet-based services. This includes cover art, track names, "
                       + "artist names and other meta-data."
                       + "</p>\n"
                       + "<p>Consequently, this may entail identifying some of your media files to third party "
                       + "entities. Therefore the <i>VLC</i> developers require your express "
                       + "consent for the media player to access the Internet automatically."
                       + "</p>\n")
            textFormat: Text.StyledText
            color: VLCStyle.palette.fgA1
            wrapMode: Text.WordWrap
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            font.weight: Font.Light
            lineHeight: VLCStyle.dp(28, VLCStyle.scale)
            lineHeightMode: Text.FixedHeight
        }

        Widgets.CheckBoxExt {
            width: parent.width

            focus: true

            padding: 0
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)

            text: qsTr("Allow metadata network access")

            checked: root.controller.metadataNetworkAccess
            onToggled: root.controller.metadataNetworkAccess = checked

            Navigation.parentItem: root
        }
    }
}
