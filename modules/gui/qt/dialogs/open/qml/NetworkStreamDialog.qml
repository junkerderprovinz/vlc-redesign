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
import QtQuick.Controls.Basic

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Playlist
import VLC.Style
import VLC.Dialogs

FramelessDialog {
    id: root

    title: qsTr("Open Network Stream")

    baseHeight: VLCStyle.dp(631, VLCStyle.scale)

    acceptEnabled: _urls.length > 0

    readonly property var _urls: urlField.text.split(/\s+/).filter(
        (url) => /^[a-z][a-z0-9+.-]*:\/\/\S+$/i.test(url))

    onAccepted: {
        const name = nameField.text.trim()
        if (name.length > 0 && playlistCreator.item)
            playlistCreator.item.create(name, _urls)

        MainPlaylistController.append(_urls, true)
    }

    Loader {
        id: playlistCreator

        active: MainCtx.mediaLibraryAvailable
        source: "qrc:///qt/qml/VLC/Dialogs/PlaylistCreator.qml"
    }

    footerData: Widgets.TextToolButton {
        anchors.verticalCenter: parent.verticalCenter

        text: qsTr("Advanced Options")
        font.pixelSize: VLCStyle.fontSize_normal

        onClicked: {
            root.hide()
            DialogsProvider.openNetAdvancedDialog()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
        anchors.topMargin: VLCStyle.dp(22, VLCStyle.scale)
        anchors.bottomMargin: VLCStyle.dp(22, VLCStyle.scale)

        spacing: VLCStyle.dp(20, VLCStyle.scale)

        DialogHeading {
            Layout.fillWidth: true

            title: qsTr("Network URL")
            description: qsTr("You can enter multiple links to load.")
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(194, VLCStyle.scale)

            background: FieldBackground {
                active: urlField.activeFocus
            }

            TextArea {
                id: urlField

                focus: true

                leftPadding: VLCStyle.dp(14, VLCStyle.scale)
                rightPadding: VLCStyle.dp(18, VLCStyle.scale)
                topPadding: VLCStyle.dp(10, VLCStyle.scale)
                bottomPadding: VLCStyle.dp(10, VLCStyle.scale)

                placeholderText: qsTr("e.g., https://www.example.com/stream.avi")
                placeholderTextColor: VLCStyle.palette.fgA4
                color: VLCStyle.palette.fgA2
                selectionColor: VLCStyle.palette.bgAccentBright
                selectedTextColor: VLCStyle.palette.fg1
                font.pixelSize: VLCStyle.fontSize_normal
                wrapMode: TextEdit.WrapAnywhere
                background: null

                Accessible.name: qsTr("Network URL")

                KeyNavigation.tab: nameField
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.border

            visible: MainCtx.mediaLibraryAvailable
            color: VLCStyle.palette.dividerDim
        }

        DialogHeading {
            Layout.fillWidth: true

            visible: MainCtx.mediaLibraryAvailable
            title: qsTr("Playlist Name (optional)")
            description: qsTr("The playlist will be saved and displayed with this title.")
        }

        Widgets.TextFieldExt {
            id: nameField

            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(37, VLCStyle.scale)

            visible: MainCtx.mediaLibraryAvailable

            leftPadding: VLCStyle.dp(14, VLCStyle.scale)
            rightPadding: VLCStyle.dp(18, VLCStyle.scale)

            placeholderText: qsTr("e.g., Favorite TV Channels")
            font.pixelSize: VLCStyle.fontSize_normal

            background: FieldBackground {
                active: nameField.activeFocus
            }

            Accessible.name: qsTr("Playlist Name")

            onAccepted: root.accept()
        }

        Item {
            Layout.fillHeight: true
        }
    }

    component FieldBackground: Rectangle {
        property bool active: false

        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: VLCStyle.palette.bgB2
        border.width: VLCStyle.dp(2, VLCStyle.scale)
        border.color: active ? VLCStyle.palette.accentDim : VLCStyle.palette.bgA4
    }
}
