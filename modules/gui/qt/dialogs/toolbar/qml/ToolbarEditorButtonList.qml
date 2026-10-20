/*****************************************************************************
 * Copyright (C) 2019 VLC authors and VideoLAN
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


import VLC.Player
import VLC.PlayerControls
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Util

GridView {
    id: root

    clip: true

    T.ScrollBar.vertical: Widgets.ScrollBarExt { }

    currentIndex: -1
    highlightFollowsCurrentItem: false

    cellWidth: VLCStyle.dp(86 + 24, VLCStyle.scale)
    cellHeight: VLCStyle.dp(82 + 38, VLCStyle.scale)

    boundsBehavior: Flickable.StopAtBounds

    // The layout being edited; controls it already holds are left out,
    // except the ones that may appear several times.
    property PlayerControlbarModel barModel: null

    required property Item dragItem

    signal controlDragStarted(int id)
    signal controlDragStopped(int id)

    readonly property var repeatable: [
        ControlListModel.WIDGET_SPACER,
        ControlListModel.WIDGET_SPACER_EXTEND,
        ControlListModel.WIDGET_DIVIDER
    ]

    // Optional controls in the order of the design, then the ones the default
    // layout uses, then everything else the player offers.
    readonly property var entries: [
        { id: ControlListModel.WIDGET_SPACER, text: qsTr("Spacer") },
        { id: ControlListModel.WIDGET_DIVIDER, text: qsTr("Divider") },
        { id: ControlListModel.PLAYBACK_SPEED_BUTTON, text: qsTr("Playback Speed"), glyph: VLCIcons.speed },
        { id: ControlListModel.SKIP_FW_BUTTON, text: qsTr("Forward 10s"), glyph: VLCIcons.forward_10_sec },
        { id: ControlListModel.SKIP_BACK_BUTTON, text: qsTr("Backward 10s"), glyph: VLCIcons.backward_10_sec },
        { id: ControlListModel.SKIP_FW_15_BUTTON, text: qsTr("Forward 15s") },
        { id: ControlListModel.SKIP_BACK_15_BUTTON, text: qsTr("Backward 15s") },
        { id: ControlListModel.STOP_BUTTON, text: qsTr("Stop") },
        { id: ControlListModel.LOOP_BUTTON, text: qsTr("Repeat"), glyph: VLCIcons.repeat_right },
        { id: ControlListModel.RANDOM_BUTTON, text: qsTr("Shuffle"), glyph: VLCIcons.shuffle_right },
        { id: ControlListModel.RECORD_BUTTON, text: qsTr("Record") },
        { id: ControlListModel.SNAPSHOT_BUTTON, text: qsTr("Snapshot") },
        { id: ControlListModel.QUIT_BUTTON, text: qsTr("Quit VLC"), glyph: VLCIcons.quit },
        { id: ControlListModel.PREFERENCES_BUTTON, text: qsTr("VLC Settings") },
        { id: ControlListModel.HOME_BUTTON, text: qsTr("Go Home") },
        { id: ControlListModel.THUMBNAIL_WIDGET, text: qsTr("Thumbnail") },
        { id: ControlListModel.TITLE_WIDGET, text: qsTr("File Name") },
        { id: ControlListModel.ARTIST_WIDGET, text: qsTr("Artist Name") },
        { id: ControlListModel.FOLDER_WIDGET, text: qsTr("Folder Name") },
        { id: ControlListModel.INFO_BUTTON, text: qsTr("Properties") },
        { id: ControlListModel.REPLAY_BUTTON, text: qsTr("Replay") },
        { id: ControlListModel.BOOKMARK_BUTTON, text: qsTr("Bookmarks"), glyph: VLCIcons.bookmarks },
        { id: ControlListModel.PLAYLISTS_BUTTON, text: qsTr("Playlists") },
        { id: ControlListModel.PREVIOUS_BUTTON, text: qsTr("Previous") },
        { id: ControlListModel.PLAY_BUTTON, text: qsTr("Play") },
        { id: ControlListModel.NEXT_BUTTON, text: qsTr("Next") },
        { id: ControlListModel.VOLUME, text: qsTr("Volume") },
        { id: ControlListModel.AUDIO_TRACK_BUTTON, text: qsTr("Audio") },
        { id: ControlListModel.LANG_BUTTON, text: qsTr("Subtitles") },
        { id: ControlListModel.EXTENDED_BUTTON, text: qsTr("Player Settings"), glyph: VLCIcons.settings },
        { id: ControlListModel.PLAYLIST_BUTTON, text: qsTr("Playlist"), glyph: VLCIcons.lists }
    ]

    property int _revision: 0

    Connections {
        target: root.barModel

        function onControlListChanged() {
            ++root._revision
        }
    }

    function _placed(id) {
        return [barModel.left, barModel.center, barModel.right].some((list) => list.contains(id))
    }

    model: {
        // Evaluated again whenever the edited layout changes.
        root._revision

        const known = entries.map((entry) => entry.id)
        const others = PlayerControlbarControls.controlList
            .filter((control) => !known.includes(control.id) && control.id !== ControlListModel.POSITION_WIDGET)
            .map((control) => ({ id: control.id, text: control.text }))

        const all = entries.concat(others)
        if (!barModel)
            return all

        return all.filter((entry) => repeatable.includes(entry.id) || !_placed(entry.id))
    }

    MouseArea {
        anchors.fill: parent
        z: -1

        preventStealing: true
    }

    property Component implicitFlickableScrollHandler: DefaultFlickableScrollHandler { }

    // NOTE: This property can be set to null to prevent using a scroll handler:
    property FlickableScrollHandler scrollHandler: {
        if (interactive) {
            // JS ownership:
            return implicitFlickableScrollHandler.createObject(null, { target: root })
        } else {
            return null
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 1

        visible: root.dragItem.Drag.active

        cursorShape: visible ? Qt.DragMoveCursor : Qt.ArrowCursor
    }

    delegate: MouseArea {
        id: tile

        width: root.cellWidth
        height: root.cellHeight

        hoverEnabled: true
        cursorShape: Qt.OpenHandCursor

        objectName: "buttonsList"

        drag.target: root.dragItem

        drag.smoothed: false

        required property var modelData

        readonly property int mIndex: modelData.id
        readonly property string glyph: modelData.glyph ?? PlayerControlbarControls.control(mIndex).label ?? ""

        readonly property bool narrow: (mIndex === ControlListModel.WIDGET_SPACER)
                                       || (mIndex === ControlListModel.WIDGET_DIVIDER)

        readonly property bool active: containsMouse && !root.dragItem.Drag.active

        Accessible.role: Accessible.Button
        Accessible.name: modelData.text

        readonly property ColorContext colorContext: ColorContext {
            id: tileTheme
            colorSet: ColorContext.Item
        }

        drag.onActiveChanged: {
            if (drag.active) {
                root.controlDragStarted(mIndex)

                root.dragItem.text = tile.glyph
                root.dragItem.Drag.source = this
                root.dragItem.Drag.start()

                GridView.delayRemove = true
            } else {
                root.dragItem.Drag.drop()

                root.controlDragStopped(mIndex)

                GridView.delayRemove = false
            }
        }

        onPressed: (mouse) => {
            const pos = mapToItem(root.dragItem.parent, mouseX, mouseY)
            root.dragItem.y = pos.y - root.dragItem.height / 2
            root.dragItem.x = pos.x - root.dragItem.width / 2
        }

        EditorDummyButton {
            id: box

            x: (VLCStyle.dp(86, VLCStyle.scale) - width) / 2
            width: tile.narrow ? VLCStyle.dp(24, VLCStyle.scale) : implicitWidth

            color: tile.active ? tileTheme.palette.fg1 : tileTheme.palette.fgA2
            frameColor: tile.active ? tileTheme.palette.fgA2 : tileTheme.palette.fgA3
            backgroundColor: tile.active ? tileTheme.palette.bgA1 : "transparent"

            text: (tile.mIndex === ControlListModel.WIDGET_SPACER || tile.mIndex === ControlListModel.WIDGET_DIVIDER
                   || tile.mIndex === ControlListModel.THUMBNAIL_WIDGET) ? "" : tile.glyph

            Rectangle {
                anchors.centerIn: parent

                visible: tile.mIndex === ControlListModel.WIDGET_DIVIDER

                width: VLCStyle.border
                height: VLCStyle.dp(16, VLCStyle.scale)

                color: box.color
            }

            Rectangle {
                anchors.centerIn: parent

                visible: tile.mIndex === ControlListModel.THUMBNAIL_WIDGET

                width: VLCStyle.dp(20, VLCStyle.scale)
                height: width
                radius: VLCStyle.dp(2, VLCStyle.scale)

                color: Qt.alpha(tileTheme.palette.fgA3, 0.5)
            }
        }

        T.Label {
            anchors.top: box.bottom
            anchors.topMargin: VLCStyle.margin_normal

            width: VLCStyle.dp(86, VLCStyle.scale)

            text: tile.modelData.text.replace(/ (\d+s)$/, "\n$1")
            color: tile.active ? tileTheme.palette.fg1 : tileTheme.palette.fgA2
            font.pixelSize: VLCStyle.fontSize_large
            lineHeight: VLCStyle.dp(17, VLCStyle.scale)
            lineHeightMode: Text.FixedHeight
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
