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
import VLC.Util
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
        y: VLCStyle.dp(116, VLCStyle.scale)

        width: VLCStyle.dp(595, VLCStyle.scale)

        Image {
            anchors.horizontalCenter: parent.horizontalCenter

            width: VLCStyle.dp(141, VLCStyle.scale)
            height: width
            sourceSize: Qt.size(width, height)

            source: SVGColorImage.colorize("qrc:///icons/figma/vlc.svg")
                                 .accent(VLCStyle.palette.accent)
                                 .uri()
        }

        T.Label {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: VLCStyle.dp(29, VLCStyle.scale)

            text: qsTr("Welcome to VLC!")
            color: VLCStyle.palette.fg1
            font.pixelSize: VLCStyle.dp(32, VLCStyle.scale)
            font.weight: Font.Light
        }

        T.Label {
            width: parent.width
            topPadding: VLCStyle.dp(37, VLCStyle.scale)

            text: qsTr("VLC is a free and open source cross-platform multimedia player and framework that plays most multimedia files as well as DVDs, Audio CDs, VCDs, and various streaming protocols.")
            color: VLCStyle.palette.fgA1
            wrapMode: Text.WordWrap
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
            font.weight: Font.Light
            lineHeight: VLCStyle.dp(28, VLCStyle.scale)
            lineHeightMode: Text.FixedHeight
        }

        Item {
            width: 1
            height: VLCStyle.dp(54, VLCStyle.scale)
        }

        T.Label {
            text: MainCtx.mediaLibraryAvailable ? qsTr("Choose a Media Folder to get started with")
                                                : qsTr("This build of VLC has no media library.")
            color: VLCStyle.palette.fgA2
            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
            bottomPadding: VLCStyle.dp(16, VLCStyle.scale)
        }

        Row {
            visible: MainCtx.mediaLibraryAvailable

            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Widgets.TextFieldExt {
                id: folderField

                focus: true

                width: VLCStyle.dp(471, VLCStyle.scale)
                height: VLCStyle.dp(36, VLCStyle.scale)

                leftPadding: VLCStyle.dp(12, VLCStyle.scale)
                rightPadding: VLCStyle.dp(18, VLCStyle.scale)
                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)

                color: VLCStyle.palette.fg2
                backgroundColor: VLCStyle.palette.bgB2
                borderColor: activeFocus ? VLCStyle.palette.accentDim : VLCStyle.palette.bgA4

                text: root.controller.folder
                onTextEdited: root.controller.folder = text

                Accessible.name: qsTr("Media folder")

                Navigation.parentItem: root
                Navigation.rightItem: browseButton
                Keys.priority: Keys.AfterItem
                Keys.onPressed: (event) => Navigation.defaultKeyAction(event)
            }

            Widgets.DialogButton {
                id: browseButton

                anchors.verticalCenter: folderField.verticalCenter

                width: VLCStyle.dp(114, VLCStyle.scale)
                height: VLCStyle.dp(35, VLCStyle.scale)

                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)
                font.weight: Font.Normal

                text: qsTr("Browse")

                Navigation.parentItem: root
                Navigation.leftItem: folderField

                onClicked: root.controller.browseFolder()
            }
        }
    }
}
