/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
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
import QtQuick.Window


import VLC.MainInterface
import VLC.Player
import VLC.PlayerControls
import VLC.Playlist
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Util

// Card in the bottom right corner of the library while something plays. The
// item itself takes no height, so the library keeps its whole page.
T.Pane {
    id: root

    Accessible.name: qsTr("Mini player")
    AccessibleCompat.id: "miniplayerControlBar"

    readonly property bool shown: Player.isStarted

    // Popups opened from the card align on its top edge.
    readonly property real sliderY: card.y

    readonly property bool showsVideo: MainCtx.hasEmbededVideo && MainCtx.canShowVideoPIP

    // The play queue opens inside the card, above the video.
    property bool queueVisible: false

    readonly property string _folder: {
        const text = Player.url.toString()
        if (!text.startsWith("file://"))
            return text.replace(/^[a-z]+:\/\//i, "").split("/")[0]
        const parts = text.split("/")
        if (parts.length < 2)
            return ""
        try {
            return decodeURIComponent(parts[parts.length - 2])
        } catch (e) {
            return parts[parts.length - 2]
        }
    }

    implicitHeight: 0
    height: 0

    padding: 0

    visible: card.opacity > 0

    focusPolicy: Qt.NoFocus

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    background: Item { }

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => root.Navigation.defaultKeyAction(event)

    FocusScope {
        id: card

        anchors.right: parent.right
        anchors.rightMargin: VLCStyle.dp(6, VLCStyle.scale) + VLCStyle.applicationHorizontalMargin

        width: VLCStyle.dp(391, VLCStyle.scale)
        height: content.implicitHeight + 2 * VLCStyle.dp(8, VLCStyle.scale)

        y: (root.shown ? -height - VLCStyle.dp(6, VLCStyle.scale) - VLCStyle.applicationVerticalMargin
                       : VLCStyle.margin_large - height)

        opacity: root.shown ? 1.0 : 0.0

        focus: true

        Behavior on opacity {
            enabled: theme.initialized

            NumberAnimation {
                duration: VLCStyle.duration_long
                easing.type: Easing.InOutSine
            }
        }

        Behavior on y {
            enabled: theme.initialized

            NumberAnimation {
                duration: VLCStyle.duration_long
                easing.type: Easing.InOutSine
            }
        }

        HoverHandler {
            id: cardHover
        }

        Rectangle {
            anchors.fill: parent

            radius: VLCStyle.dp(14, VLCStyle.scale)
            color: theme.bg.primary

            Widgets.RoundedRectangleShadow {
                z: -1
                color: Qt.rgba(0, 0, 0, theme.tokens.isDark ? 0.38 : 0.18)
                blurRadius: VLCStyle.dp(12, VLCStyle.scale)
            }
        }

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: VLCStyle.dp(8, VLCStyle.scale)

            spacing: VLCStyle.dp(20, VLCStyle.scale)

            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: -content.anchors.margins
                Layout.leftMargin: -content.anchors.margins
                Layout.rightMargin: -content.anchors.margins
                Layout.preferredHeight: VLCStyle.dp(339, VLCStyle.scale)

                visible: root.queueVisible

                spacing: VLCStyle.dp(1, VLCStyle.scale)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(58, VLCStyle.scale)

                    radius: VLCStyle.dp(14, VLCStyle.scale)
                    color: theme.tokens.bgA5

                    // square off the bottom corners
                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom

                        height: parent.radius
                        color: parent.color
                    }

                    T.Label {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: VLCStyle.dp(16, VLCStyle.scale)

                        text: qsTr("Play Queue")
                        color: theme.tokens.fgA2
                        font.pixelSize: VLCStyle.fontSize_large
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }
                }

                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: content.anchors.margins
                    Layout.rightMargin: content.anchors.margins

                    active: root.queueVisible

                    sourceComponent: PlaylistPane {
                        useAcrylic: false
                        wheelEnabled: true

                        topPadding: 0
                        bottomPadding: 0

                        background: null

                        Navigation.parentItem: root
                        Navigation.downItem: playButton
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true

                spacing: VLCStyle.dp(4, VLCStyle.scale)

                Item {
                    id: videoArea

                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(211, VLCStyle.scale)

                    Rectangle {
                        anchors.fill: parent

                        visible: !root.showsVideo

                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: theme.tokens.bgA4
                        border.width: VLCStyle.dp(2, VLCStyle.scale)
                        border.color: theme.tokens.bgB2

                        Widgets.ImageExt {
                            anchors.fill: parent
                            anchors.margins: parent.border.width

                            source: (Player.artwork && Player.artwork.toString()) ? VLCAccessImage.uri(Player.artwork)
                                                                                 : VLCStyle.noArtAlbumCover
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            radius: VLCStyle.dp(4, VLCStyle.scale)

                            sourceSize: Qt.size(width * MainCtx.effectiveDevicePixelRatio(Window.window),
                                                height * MainCtx.effectiveDevicePixelRatio(Window.window))
                        }
                    }

                    VideoSurface {
                        id: videoSurface

                        anchors.fill: parent
                        anchors.margins: VLCStyle.dp(2, VLCStyle.scale)

                        visible: root.showsVideo

                        videoSurfaceProvider: (root.showsVideo && root.shown && root.visible) ? MainCtx.videoSurfaceProvider
                                                                                             : null
                    }

                    VideoFrame {
                        anchors.fill: parent

                        visible: root.showsVideo

                        target: videoSurface
                        frameWidth: VLCStyle.dp(2, VLCStyle.scale)
                        radius: VLCStyle.dp(4, VLCStyle.scale)
                        color: theme.tokens.bgB2
                    }

                    Rectangle {
                        id: overlay

                        anchors.fill: parent

                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: Qt.rgba(0, 0, 0, 0.6)

                        opacity: (cardHover.hovered || card.activeFocus) ? 1.0 : 0.0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation {
                                duration: VLCStyle.duration_short
                            }
                        }
                    }

                    TapHandler {
                        onTapped: MainPlaylistController.togglePlayPause()
                        onDoubleTapped: MainCtx.playerView = true
                    }

                    OverlayButton {
                        id: closeButton

                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: VLCStyle.dp(14, VLCStyle.scale)

                        text: VLCIcons.close
                        description: qsTr("Stop")

                        onClicked: MainPlaylistController.stop()

                        Navigation.parentItem: root
                        Navigation.rightItem: previousButton
                    }

                    OverlayButton {
                        id: openButton

                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: VLCStyle.dp(14, VLCStyle.scale)

                        text: VLCIcons.open
                        description: qsTr("Back to player")

                        onClicked: MainCtx.playerView = true

                        Navigation.parentItem: root
                        Navigation.leftItem: nextButton
                        Navigation.downItem: queueButton
                    }

                    Row {
                        anchors.centerIn: parent

                        spacing: VLCStyle.dp(26, VLCStyle.scale)

                        OverlayButton {
                            id: previousButton

                            big: true

                            enabled: MainPlaylistController.hasPrev
                            text: VLCIcons.previous
                            description: qsTr("Previous")

                            onClicked: MainPlaylistController.prev()

                            Navigation.parentItem: root
                            Navigation.leftItem: closeButton
                            Navigation.rightItem: playButton
                        }

                        OverlayButton {
                            id: playButton

                            big: true

                            readonly property bool playing: Player.playingState === Player.PLAYING_STATE_PLAYING

                            text: playing ? VLCIcons.pause_filled : VLCIcons.play_filled
                            description: playing ? qsTr("Pause") : qsTr("Play")

                            focus: true

                            onClicked: MainPlaylistController.togglePlayPause()

                            Navigation.parentItem: root
                            Navigation.leftItem: previousButton
                            Navigation.rightItem: nextButton
                        }

                        OverlayButton {
                            id: nextButton

                            big: true

                            enabled: MainPlaylistController.hasNext
                            text: VLCIcons.next
                            description: qsTr("Next")

                            onClicked: MainPlaylistController.next()

                            Navigation.parentItem: root
                            Navigation.leftItem: playButton
                            Navigation.rightItem: openButton
                        }
                    }
                }

                SliderBar {
                    id: progress

                    Layout.fillWidth: true

                    barHeight: VLCStyle.dp(16, VLCStyle.scale)

                    enabled: Player.playingState === Player.PLAYING_STATE_PLAYING
                             || Player.playingState === Player.PLAYING_STATE_PAUSED

                    handleVisible: cardHover.hovered || visualFocus

                    Accessible.name: qsTr("Progress")

                    Navigation.parentItem: root
                    Navigation.upItem: playButton
                    Navigation.downItem: queueButton
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
                Layout.rightMargin: VLCStyle.dp(8, VLCStyle.scale)
                Layout.bottomMargin: VLCStyle.dp(4, VLCStyle.scale)

                spacing: VLCStyle.dp(14, VLCStyle.scale)

                T.Label {
                    Layout.fillWidth: true

                    text: Player.title
                    color: theme.tokens.fgA1
                    font.pixelSize: VLCStyle.fontSize_xlarge
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true

                    spacing: VLCStyle.dp(20, VLCStyle.scale)

                    Chip {
                        glyph: VLCIcons.folder
                        text: root._folder
                    }

                    Chip {
                        glyph: VLCIcons.artist
                        text: Player.artist
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    ControlButton {
                        id: queueButton

                        text: VLCIcons.lists
                        description: qsTr("Play Queue")

                        // Clicking keeps the focus where it is, so the overlay hides with the pointer.
                        focusPolicy: Qt.TabFocus

                        checked: root.queueVisible

                        onClicked: root.queueVisible = !root.queueVisible

                        Navigation.parentItem: root
                        Navigation.upItem: progress
                    }
                }
            }
        }
    }

    component OverlayButton : Widgets.IconToolButton {
        property bool big: false

        implicitWidth: big ? VLCStyle.dp(54, VLCStyle.scale) : VLCStyle.dp(28, VLCStyle.scale)
        implicitHeight: big ? VLCStyle.dp(50, VLCStyle.scale) : VLCStyle.dp(28, VLCStyle.scale)

        radius: VLCStyle.dp(7, VLCStyle.scale)

        font.pixelSize: big ? VLCStyle.dp(43, VLCStyle.scale) : VLCStyle.icon_normal

        color: "white"
        backgroundColor: hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent"

        opacity: overlay.opacity
        visible: opacity > 0
    }

    component Chip : RowLayout {
        id: chip

        property string glyph
        property string text

        Layout.maximumWidth: VLCStyle.dp(150, VLCStyle.scale)

        visible: text !== ""

        spacing: VLCStyle.margin_xsmall

        Widgets.IconLabel {
            text: chip.glyph
            color: theme.tokens.fgA2
            font.pixelSize: VLCStyle.icon_normal
        }

        T.Label {
            Layout.fillWidth: true

            text: chip.text
            color: theme.tokens.fgA1
            font.pixelSize: VLCStyle.fontSize_xlarge
            elide: Text.ElideRight
        }
    }
}
