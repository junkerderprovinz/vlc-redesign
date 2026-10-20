/*****************************************************************************
 * Copyright (C) 2023 VLC authors and VideoLAN
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
import QtQuick.Layouts
import QtQml.Models


import VLC.MainInterface
import VLC.Style
import VLC.Player
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Dialogs

FocusScope {
    id: root

    property int tab: TracksMenu.Tab.Subtitles

    //FIXME make TrackMenuController a proper type (see TrackMenu)
    required property QtObject trackMenuController

    focus: true

    readonly property ColorContext colorContext: ColorContext {
        id: theme

        colorSet: ColorContext.Window
    }

    Flickable {
        id: flickable

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: footer.top

        contentHeight: column.implicitHeight
        clip: contentHeight > height

        boundsBehavior: Flickable.StopAtBounds

        T.ScrollBar.vertical: Widgets.ScrollBarExt { }

        ColumnLayout {
            id: column

            width: flickable.width

            spacing: 0

            Section {
                title: qsTr("Embedded Tracks")

                Action {
                    visible: root.tab === TracksMenu.Tab.Video
                    glyph: VLCIcons.add
                    description: qsTr("Add video track")
                    onClicked: {
                        root.trackMenuController.requestClose()
                        DialogsProvider.loadVideoFile()
                    }
                }

                Action {
                    visible: root.tab === TracksMenu.Tab.Audio
                    glyph: VLCIcons.edit
                    description: qsTr("Synchronize audio")
                    onClicked: root.trackMenuController.requestAudioPage()
                }

                Action {
                    visible: root.tab === TracksMenu.Tab.Audio
                    glyph: VLCIcons.add
                    description: qsTr("Add audio track")
                    onClicked: {
                        root.trackMenuController.requestClose()
                        DialogsProvider.loadAudioFile()
                    }
                }
            }

            ChoiceList {
                id: trackList

                withNone: root.tab !== TracksMenu.Tab.Video

                model: {
                    switch (root.tab) {
                    case TracksMenu.Tab.Video:
                        return Player.videoTracks
                    case TracksMenu.Tab.Audio:
                        return Player.audioTracks
                    default:
                        return Player.subtitleTracks
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)

                visible: root.tab === TracksMenu.Tab.Audio

                implicitHeight: VLCStyle.dp(1, VLCStyle.scale)
                color: theme.separator
            }

            Section {
                visible: root.tab === TracksMenu.Tab.Audio

                title: qsTr("Output Device")
            }

            ChoiceList {
                visible: root.tab === TracksMenu.Tab.Audio

                model: (root.tab === TracksMenu.Tab.Audio) ? Player.audioDevices : null
            }

            Section {
                visible: root.tab === TracksMenu.Tab.Subtitles

                Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)

                title: qsTr("External Tracks")

                Action {
                    glyph: VLCIcons.edit
                    description: qsTr("Synchronize subtitles")
                    onClicked: root.trackMenuController.requestSubtitlePage()
                }

                Action {
                    glyph: VLCIcons.add
                    description: qsTr("Add subtitle file")
                    onClicked: {
                        root.trackMenuController.requestClose()
                        DialogsProvider.loadSubtitlesFile()
                    }
                }

                Action {
                    glyph: VLCIcons.ic_fluent_arrow_download_24_regular
                    description: qsTr("Download subtitles")
                    onClicked: {
                        root.trackMenuController.requestClose()
                        Player.openVLsub()
                    }
                }
            }
        }
    }

    Item {
        id: footer

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        implicitHeight: preferencesButton.implicitHeight + 2 * VLCStyle.dp(20, VLCStyle.scale)

        Widgets.ButtonExt {
            id: preferencesButton

            anchors.fill: parent
            anchors.margins: VLCStyle.dp(20, VLCStyle.scale)

            text: qsTr("Global Settings")

            onClicked: {
                root.trackMenuController.requestClose()
                DialogsProvider.prefsDialog()
            }
        }
    }

    component Section : RowLayout {
        id: section

        required property string title

        Layout.fillWidth: true
        Layout.preferredHeight: VLCStyle.dp(60, VLCStyle.scale)
        Layout.leftMargin: VLCStyle.dp(28, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

        spacing: VLCStyle.margin_small

        T.Label {
            Layout.fillWidth: true

            text: section.title
            color: theme.tokens.fgA3
            font.pixelSize: VLCStyle.fontSize_large
            elide: Text.ElideRight
        }
    }

    component Action : Widgets.IconToolButton {
        required property string glyph

        text: glyph
        font.pixelSize: VLCStyle.icon_normal
    }

    component ChoiceList : ColumnLayout {
        id: list

        property alias model: repeater.model

        // Lets the user turn the track off, which the models only express by having no row checked.
        property bool withNone: false

        property int _revision: 0

        readonly property bool _noneChecked: {
            void _revision
            for (let i = 0; i < repeater.count; ++i) {
                const item = repeater.itemAt(i)
                if (item && item.selected)
                    return false
            }
            return true
        }

        Layout.fillWidth: true
        Layout.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

        spacing: VLCStyle.margin_small

        Choice {
            visible: list.withNone && repeater.count > 0

            text: qsTr("None")
            selected: list._noneChecked

            onClicked: {
                for (let i = 0; i < repeater.count; ++i) {
                    const item = repeater.itemAt(i)
                    if (item && item.selected)
                        item.uncheck()
                }
            }
        }

        Repeater {
            id: repeater

            delegate: Choice {
                required property var model

                text: model.display
                selected: model.checked

                onSelectedChanged: ++list._revision

                function uncheck() {
                    model.checked = false
                }

                onClicked: model.checked = true
            }
        }
    }

    component Choice : T.ItemDelegate {
        id: choice

        property bool selected: false

        Layout.fillWidth: true

        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

        leftPadding: VLCStyle.dp(4, VLCStyle.scale)
        rightPadding: VLCStyle.dp(4, VLCStyle.scale)

        hoverEnabled: true

        Accessible.role: Accessible.RadioButton
        Accessible.checkable: true
        Accessible.checked: selected
        Accessible.name: text

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: (choice.hovered || choice.visualFocus) ? theme.tokens.hover : "transparent"
        }

        contentItem: RowLayout {
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            Widgets.IconLabel {
                Layout.preferredWidth: VLCStyle.icon_normal

                text: VLCIcons.check
                color: theme.accent
                font.pixelSize: VLCStyle.icon_normal
                opacity: choice.selected ? 1.0 : 0.0
            }

            T.Label {
                Layout.fillWidth: true

                text: choice.text
                color: choice.selected ? theme.tokens.fg2 : theme.tokens.fgA1
                font.pixelSize: VLCStyle.fontSize_large
                elide: Text.ElideRight
            }
        }
    }
}
