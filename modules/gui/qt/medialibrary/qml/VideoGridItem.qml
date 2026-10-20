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

import VLC.MainInterface
import VLC.MediaLibrary

import VLC.Widgets as Widgets
import VLC.Util
import VLC.Style

Widgets.GridItem {
    id: root

    property var labels

    readonly property real progress: Helpers.clamp(model.progress !== undefined ? model.progress : 0, 0, 1)

    // A finished video has its progress reset, only the play count remains.
    readonly property bool watched: progress >= 0.85 || ((model.playcount ?? 0) > 0 && !(progress > 0))

    function play() {
        if ( model.id !== undefined ) {
            MediaLib.addAndPlay( model.id )
            MainCtx.playerView = true
        }
    }

    image: model.thumbnail || ""
    fallbackImage: VLCStyle.noArtVideoCover
    fillMode: Image.PreserveAspectCrop

    title: model.title || qsTr("Unknown title")
    subtitle: ""
    pictureWidth: VLCStyle.gridCover_video_width
    pictureHeight: VLCStyle.gridCover_video_height

    pictureDimmed: true
    dimmed: watched

    Widgets.VideoProgressBar {
        id: progressBar

        parent: root.mediaCover

        z: 1

        anchors {
            bottom: parent.bottom
            left: parent.left
            right: parent.right
        }

        visible: root.progress > 0 || root.watched

        radius: root.pictureRadius
        value: root.progress > 0 ? root.progress : 1
    }

    pictureOverlay: Item {
        implicitWidth: root.pictureWidth
        implicitHeight: root.pictureHeight

        Widgets.VideoQualityLabels {
            anchors {
                top: parent.top
                right: parent.right
                topMargin: VLCStyle.margin_xxsmall
                leftMargin: VLCStyle.margin_xxsmall
                rightMargin: VLCStyle.margin_xxsmall
            }

            labels: root.labels
        }
    }

    onPlayClicked: root.play()
}
