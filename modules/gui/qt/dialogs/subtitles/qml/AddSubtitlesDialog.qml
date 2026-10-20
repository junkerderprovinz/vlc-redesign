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
import QtQml.Models

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Player
import VLC.Style
import VLC.Dialogs

FramelessDialog {
    id: root

    title: qsTr("Add Subtitles")

    backgroundColor: VLCStyle.palette.bgB1

    acceptEnabled: subtitles.canApply

    onVisibleChanged: {
        if (!visible)
            return
        subtitles.refresh()
        subtitles.link = ""
        targetSelect.currentIndex = subtitles.hasMedia ? 0 : 2
        originSelect.currentIndex = 0
    }

    onAccepted: subtitles.apply()

    SubtitlesModel {
        id: subtitles

        ctx: MainCtx
        target: targetSelect.currentValue ?? SubtitlesModel.TARGET_FILE
        origin: originSelect.currentValue ?? SubtitlesModel.ORIGIN_COMPUTER
    }

    toolbarData: RowLayout {
        anchors.fill: parent

        spacing: VLCStyle.dp(10, VLCStyle.scale)

        DialogSelect {
            id: targetSelect

            model: [
                { text: qsTr("To This File"), value: SubtitlesModel.TARGET_FILE },
                { text: qsTr("To This Folder"), value: SubtitlesModel.TARGET_FOLDER },
                { text: qsTr("To This Playlist"), value: SubtitlesModel.TARGET_QUEUE }
            ]

            Accessible.name: qsTr("Add subtitles to")
        }

        DialogSelect {
            id: originSelect

            model: [
                { text: qsTr("From Computer"), value: SubtitlesModel.ORIGIN_COMPUTER },
                { text: qsTr("From OpenSubtitles"), value: SubtitlesModel.ORIGIN_OPENSUBTITLES },
                { text: qsTr("From Link ..."), value: SubtitlesModel.ORIGIN_LINK }
            ]

            Accessible.name: qsTr("Subtitle source")
        }

        DialogToolbarField {
            visible: subtitles.origin === SubtitlesModel.ORIGIN_COMPUTER

            readOnly: true
            iconText: VLCIcons.folder
            text: subtitles.folderLabel
            placeholderText: qsTr("Choose a folder")

            onClicked: subtitles.browseFolder()
        }

        DialogToolbarField {
            visible: subtitles.origin === SubtitlesModel.ORIGIN_LINK

            iconText: VLCIcons.link
            placeholderText: "https://example.com/subtitles.srt"

            onTextChanged: subtitles.link = text
        }

        Item {
            Layout.fillWidth: true
            visible: subtitles.origin === SubtitlesModel.ORIGIN_OPENSUBTITLES
        }
    }

    ListView {
        id: list

        anchors.fill: parent
        anchors.topMargin: VLCStyle.dp(22, VLCStyle.scale)
        anchors.leftMargin: subtitles.pairing ? 0 : VLCStyle.dp(20, VLCStyle.scale)
        anchors.rightMargin: subtitles.pairing ? 0 : VLCStyle.dp(20, VLCStyle.scale)

        visible: subtitles.origin !== SubtitlesModel.ORIGIN_OPENSUBTITLES

        clip: true
        model: subtitles
        spacing: VLCStyle.dp(4, VLCStyle.scale)
        boundsBehavior: Flickable.StopAtBounds

        T.ScrollBar.vertical: Widgets.ScrollBarExt { }

        delegate: subtitles.pairing ? pairDelegate : checkDelegate

        footer: Item {
            width: ListView.view.width
            height: VLCStyle.dp(22, VLCStyle.scale)
        }

        Widgets.LabelExt {
            x: VLCStyle.dp(8, VLCStyle.scale) + (subtitles.pairing ? VLCStyle.dp(20, VLCStyle.scale) : 0)

            visible: list.count === 0
            color: VLCStyle.palette.fgA3
            font.pixelSize: VLCStyle.fontSize_large
            textFormat: Text.PlainText

            text: {
                if (!subtitles.pairing && !subtitles.hasMedia)
                    return qsTr("Nothing is playing. Play a file first, or add subtitles to a folder or to the playlist.")
                if (subtitles.origin === SubtitlesModel.ORIGIN_LINK)
                    return qsTr("Paste a link to a subtitle file (.srt, .vtt, .ass).")
                if (subtitles.target === SubtitlesModel.TARGET_QUEUE)
                    return qsTr("The playlist is empty.")
                if (subtitles.target === SubtitlesModel.TARGET_FOLDER)
                    return qsTr("No videos in this folder.")
                return qsTr("No subtitles found.")
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: VLCStyle.dp(20, VLCStyle.scale)
        anchors.topMargin: VLCStyle.dp(22, VLCStyle.scale)

        visible: subtitles.origin === SubtitlesModel.ORIGIN_OPENSUBTITLES

        spacing: VLCStyle.dp(20, VLCStyle.scale)

        DialogHeading {
            Layout.fillWidth: true

            title: qsTr("OpenSubtitles")
            description: qsTr("VLsub searches OpenSubtitles for the playing file and loads the subtitles you pick.")
        }

        Widgets.DialogButton {
            primary: true
            enabled: subtitles.hasMedia
            text: qsTr("Search OpenSubtitles")

            onClicked: {
                root.hide()
                Player.openVLsub()
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }

    Component {
        id: checkDelegate

        T.ItemDelegate {
            id: check

            required property int index
            required property string subtitleName
            required property var model

            checked: model.checked

            width: ListView.view.width
            height: VLCStyle.dp(36, VLCStyle.scale)

            leftPadding: VLCStyle.dp(8, VLCStyle.scale)
            rightPadding: VLCStyle.dp(8, VLCStyle.scale)

            Accessible.role: Accessible.CheckBox
            Accessible.checked: checked
            Accessible.name: subtitleName

            onClicked: subtitles.toggle(index)

            background: Rectangle {
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: (check.checked || check.hovered) ? VLCStyle.palette.bgB2 : "transparent"
                border.width: check.visualFocus ? VLCStyle.focus_border : 0
                border.color: VLCStyle.palette.accentDim
            }

            contentItem: RowLayout {
                spacing: VLCStyle.dp(14, VLCStyle.scale)

                SubtitleName {
                    Layout.fillWidth: true
                    text: check.subtitleName
                }

                Widgets.IconLabel {
                    visible: check.checked
                    text: VLCIcons.check
                    color: VLCStyle.palette.accent
                    font.pixelSize: VLCStyle.icon_normal
                }
            }
        }
    }

    Component {
        id: pairDelegate

        Item {
            id: pair

            required property int index
            required property string mediaName
            required property string subtitleName

            width: ListView.view.width
            height: VLCStyle.dp(36, VLCStyle.scale)

            RowLayout {
                id: mediaPart

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: VLCStyle.dp(30, VLCStyle.scale)
                width: parent.width * 519 / 1048 - anchors.leftMargin

                spacing: VLCStyle.dp(14, VLCStyle.scale)

                Widgets.IconLabel {
                    text: VLCIcons.video
                    color: VLCStyle.palette.fgA2
                    font.pixelSize: VLCStyle.icon_normal
                }

                Widgets.LabelExt {
                    Layout.maximumWidth: mediaPart.width * 0.6

                    text: pair.mediaName
                    elide: Text.ElideMiddle
                    color: VLCStyle.palette.fgA1
                    font.pixelSize: VLCStyle.fontSize_large
                    textFormat: Text.PlainText
                }

                // dashed line from the video to its subtitle
                Row {
                    Layout.fillWidth: true
                    Layout.minimumWidth: VLCStyle.margin_large

                    clip: true
                    spacing: VLCStyle.dp(8, VLCStyle.scale)

                    Repeater {
                        model: Math.ceil(parent.width / (2 * VLCStyle.dp(8, VLCStyle.scale)))

                        Rectangle {
                            width: VLCStyle.dp(8, VLCStyle.scale)
                            height: VLCStyle.border
                            color: VLCStyle.palette.dividerBright
                        }
                    }
                }
            }

            T.ItemDelegate {
                id: subtitleRow

                anchors.left: mediaPart.right
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

                leftPadding: VLCStyle.dp(8, VLCStyle.scale)
                rightPadding: VLCStyle.dp(8, VLCStyle.scale)

                Accessible.name: qsTr("Change subtitle for %1").arg(pair.mediaName)

                onClicked: swapMenu.popup(swapButton, 0, swapButton.height)

                background: Rectangle {
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: subtitleRow.hovered || swapMenu.visible ? VLCStyle.palette.bgB2 : "transparent"
                    border.width: subtitleRow.visualFocus ? VLCStyle.focus_border : 0
                    border.color: VLCStyle.palette.accentDim
                }

                contentItem: RowLayout {
                    spacing: VLCStyle.dp(16, VLCStyle.scale)

                    SubtitleName {
                        Layout.fillWidth: true
                        text: pair.subtitleName.length > 0 ? pair.subtitleName : qsTr("No subtitle")
                        dimmed: pair.subtitleName.length === 0
                    }

                    Widgets.IconLabel {
                        id: swapButton

                        visible: subtitleRow.hovered || subtitleRow.visualFocus || swapMenu.visible
                        text: VLCIcons.swap
                        color: VLCStyle.palette.fgA2
                        font.pixelSize: VLCStyle.icon_normal
                    }
                }
            }

            Widgets.MenuExt {
                id: swapMenu

                onAboutToShow: candidates.model = subtitles.candidates(pair.index)

                Instantiator {
                    id: candidates

                    model: []

                    delegate: Widgets.MenuItemExt {
                        required property var modelData

                        text: modelData.name
                        checkable: true
                        checked: modelData.name === pair.subtitleName

                        onTriggered: subtitles.setSubtitle(pair.index, modelData.url)
                    }

                    onObjectAdded: (index, object) => swapMenu.insertItem(index, object)
                    onObjectRemoved: (index, object) => swapMenu.removeItem(object)
                }

                Widgets.MenuSeparatorExt { }

                Widgets.MenuItemExt {
                    text: qsTr("No subtitle")
                    checkable: true
                    checked: pair.subtitleName.length === 0

                    onTriggered: subtitles.setSubtitle(pair.index, "")
                }
            }
        }
    }

    component SubtitleName: RowLayout {
        property alias text: label.text
        property bool dimmed: false

        spacing: VLCStyle.dp(14, VLCStyle.scale)

        Widgets.IconLabel {
            text: VLCIcons.subtitle
            color: VLCStyle.palette.fgA2
            font.pixelSize: VLCStyle.icon_normal
        }

        Widgets.LabelExt {
            id: label

            Layout.fillWidth: true

            elide: Text.ElideMiddle
            color: parent.dimmed ? VLCStyle.palette.fgA4 : VLCStyle.palette.fgA1
            font.pixelSize: VLCStyle.fontSize_large
            textFormat: Text.PlainText
        }
    }
}
