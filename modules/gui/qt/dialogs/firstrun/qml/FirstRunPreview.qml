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

// A miniature of the player drawn with the live palette, so it follows the
// theme and accent picked next to it.
Rectangle {
    id: root

    readonly property SystemPalette tokens: VLCStyle.palette
    readonly property real _iconSize: VLCStyle.dp(13, VLCStyle.scale)

    color: tokens.bgB2

    Accessible.ignored: true

    component Glyph: Widgets.IconLabel {
        font.pixelSize: root._iconSize
        color: root.tokens.fgA2
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        height: VLCStyle.dp(22, VLCStyle.scale)

        color: root.tokens.bgA4

        Image {
            anchors.left: parent.left
            anchors.leftMargin: VLCStyle.dp(7, VLCStyle.scale)
            anchors.verticalCenter: parent.verticalCenter

            width: root._iconSize
            height: root._iconSize
            sourceSize: Qt.size(width, height)

            source: SVGColorImage.colorize("qrc:///icons/ui/vlc.svg")
                                 .accent(root.tokens.accent)
                                 .uri()
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: VLCStyle.dp(3.3, VLCStyle.scale)
            anchors.verticalCenter: parent.verticalCenter

            spacing: VLCStyle.dp(6.6, VLCStyle.scale)

            Glyph { text: VLCIcons.minimize }
            Glyph { text: VLCIcons.maximize }
            Glyph { text: VLCIcons.fullscreen }
            Glyph { text: VLCIcons.close }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: VLCStyle.dp(30, VLCStyle.scale)

        color: root.tokens.bgA3

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            height: Math.max(1, VLCStyle.dp(0.55, VLCStyle.scale))
            color: root.tokens.dividerDim
        }

        Row {
            id: controls

            anchors.fill: parent
            anchors.leftMargin: VLCStyle.dp(11, VLCStyle.scale)
            anchors.rightMargin: VLCStyle.dp(11, VLCStyle.scale)

            spacing: VLCStyle.dp(11, VLCStyle.scale)

            Row {
                id: playGroup

                anchors.verticalCenter: parent.verticalCenter
                spacing: VLCStyle.dp(4.4, VLCStyle.scale)

                Glyph { text: VLCIcons.previous }

                Rectangle {
                    width: VLCStyle.dp(30, VLCStyle.scale)
                    height: VLCStyle.dp(15, VLCStyle.scale)
                    radius: VLCStyle.dp(3.3, VLCStyle.scale)
                    color: root.tokens.accent

                    Glyph {
                        anchors.centerIn: parent
                        text: VLCIcons.play
                        color: root.tokens.fgOnAccent
                    }
                }

                Glyph { text: VLCIcons.next }
            }

            Row {
                id: seek

                anchors.verticalCenter: parent.verticalCenter
                width: controls.width - playGroup.width - volumeGroup.width - tools.width
                       - playlistGlyph.width - controls.spacing * 4

                spacing: VLCStyle.dp(4.4, VLCStyle.scale)

                component Time: T.Label {
                    anchors.verticalCenter: parent.verticalCenter
                    width: VLCStyle.dp(42, VLCStyle.scale)
                    horizontalAlignment: Text.AlignHCenter
                    color: root.tokens.fgA2
                    font.pixelSize: VLCStyle.dp(8.25, VLCStyle.scale)
                }

                Time { text: "00:02:10" }

                Rectangle {
                    width: seek.width - VLCStyle.dp(84, VLCStyle.scale) - seek.spacing * 2
                    height: VLCStyle.dp(15, VLCStyle.scale)
                    radius: VLCStyle.dp(3.3, VLCStyle.scale)
                    color: root.tokens.bgB2

                    Rectangle {
                        x: VLCStyle.dp(1, VLCStyle.scale)
                        y: VLCStyle.dp(1, VLCStyle.scale)
                        width: VLCStyle.dp(54, VLCStyle.scale)
                        height: VLCStyle.dp(13, VLCStyle.scale)
                        radius: VLCStyle.dp(2.2, VLCStyle.scale)
                        color: root.tokens.bgAccentBright
                    }

                    Rectangle {
                        x: VLCStyle.dp(51, VLCStyle.scale)
                        y: VLCStyle.dp(1, VLCStyle.scale)
                        width: VLCStyle.dp(4, VLCStyle.scale)
                        height: VLCStyle.dp(13, VLCStyle.scale)
                        radius: VLCStyle.dp(2.2, VLCStyle.scale)
                        color: root.tokens.accent
                    }
                }

                Time { text: "00:25:40" }
            }

            Row {
                id: volumeGroup

                anchors.verticalCenter: parent.verticalCenter
                spacing: VLCStyle.dp(4.4, VLCStyle.scale)

                Glyph { text: VLCIcons.volume_high }

                Item {
                    id: wedge

                    readonly property string _source: "qrc:///icons/ui/volume-wedge.svg"
                    readonly property color trackColor: root.tokens.bgB2

                    width: VLCStyle.dp(48, VLCStyle.scale)
                    height: VLCStyle.dp(15, VLCStyle.scale)

                    // the level is painted in the track color, so only the track shows
                    Image {
                        anchors.fill: parent
                        sourceSize: Qt.size(width, height)
                        source: SVGColorImage.colorize(wedge._source)
                                             .color1(wedge.trackColor)
                                             .any({ "url(#level)": wedge.trackColor })
                                             .uri()
                    }

                    Item {
                        width: parent.width * 0.375
                        height: parent.height
                        clip: true

                        Image {
                            width: wedge.width
                            height: wedge.height
                            sourceSize: Qt.size(width, height)
                            source: SVGColorImage.colorize(wedge._source)
                                                 .color1(wedge.trackColor)
                                                 .uri()
                        }
                    }
                }
            }

            Row {
                id: tools

                anchors.verticalCenter: parent.verticalCenter
                spacing: VLCStyle.dp(6.6, VLCStyle.scale)

                Glyph { text: VLCIcons.audio }
                Glyph { text: VLCIcons.subtitles }
                Glyph { text: VLCIcons.playback_settings }
            }

            Glyph {
                id: playlistGlyph

                anchors.verticalCenter: parent.verticalCenter
                text: VLCIcons.lists
            }
        }
    }
}
