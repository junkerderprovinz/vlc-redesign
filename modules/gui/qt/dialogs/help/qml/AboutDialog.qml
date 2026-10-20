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
import VLC.Style
import VLC.Dialogs

FramelessDialog {
    id: root

    title: qsTr("About VLC")

    baseWidth: VLCStyle.dp(713, VLCStyle.scale)
    baseHeight: VLCStyle.dp(589, VLCStyle.scale)

    acceptText: qsTr("OK")
    cancelVisible: false

    property int _page: 0

    onVisibleChanged: if (visible) _page = 0

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
        anchors.topMargin: VLCStyle.dp(22, VLCStyle.scale)

        spacing: VLCStyle.dp(20, VLCStyle.scale)

        RowLayout {
            Layout.fillWidth: true

            spacing: VLCStyle.dp(16, VLCStyle.scale)

            Image {
                Layout.preferredWidth: VLCStyle.icon_medium
                Layout.preferredHeight: VLCStyle.icon_medium

                sourceSize: Qt.size(width, height)
                fillMode: Image.PreserveAspectFit
                source: MainCtx.useXmasCone() ? "qrc:///logo/vlc48-xmas.png"
                                              : "qrc:///misc/cone.svg"
            }

            ColumnLayout {
                Layout.fillWidth: true

                spacing: 0

                Widgets.LabelExt {
                    Layout.fillWidth: true

                    text: qsTr("VLC media player")
                    color: VLCStyle.palette.fg2
                    font.pixelSize: VLCStyle.fontSize_xlarge
                    textFormat: Text.PlainText
                }

                Widgets.LabelExt {
                    Layout.fillWidth: true

                    text: AboutModel.version
                    color: VLCStyle.palette.fgA3
                    font.pixelSize: VLCStyle.fontSize_large
                    textFormat: Text.PlainText
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            spacing: VLCStyle.dp(4, VLCStyle.scale)

            Repeater {
                model: [qsTr("About"), qsTr("Authors"), qsTr("License"), qsTr("Credits")]

                delegate: Widgets.ButtonExt {
                    id: pageButton

                    required property int index
                    required property string modelData

                    Layout.preferredHeight: VLCStyle.dp(32, VLCStyle.scale)

                    leftPadding: VLCStyle.dp(14, VLCStyle.scale)
                    rightPadding: VLCStyle.dp(14, VLCStyle.scale)

                    text: modelData
                    checked: root._page === index
                    color: checked ? VLCStyle.palette.fg2 : VLCStyle.palette.fgA3

                    background: Rectangle {
                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: pageButton.checked ? VLCStyle.palette.bgA1
                                                  : (pageButton.hovered ? VLCStyle.palette.bgA2 : "transparent")
                    }

                    onClicked: root._page = index
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: VLCStyle.palette.bgB2

            ScrollView {
                id: scroll

                anchors.fill: parent
                anchors.margins: VLCStyle.dp(12, VLCStyle.scale)

                contentWidth: availableWidth

                TextEdit {
                    width: scroll.availableWidth

                    readOnly: true
                    selectByMouse: true
                    wrapMode: TextEdit.Wrap
                    color: VLCStyle.palette.fgA2
                    selectionColor: VLCStyle.palette.bgAccentBright
                    font.pixelSize: VLCStyle.fontSize_large
                    textFormat: root._page === 0 ? TextEdit.RichText : TextEdit.PlainText

                    text: {
                        switch (root._page) {
                        case 1: return AboutModel.authors
                        case 2: return AboutModel.license
                        case 3: return AboutModel.thanks
                        default: return root._aboutText
                        }
                    }

                    onLinkActivated: (link) => Qt.openUrlExternally(link)

                    HoverHandler {
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.IBeamCursor
                    }
                }
            }
        }
    }

    readonly property string _aboutText: {
        const link = (url, text) => "<a style=\"color:%1\" href=\"%2\">%3</a>"
                                     .arg(VLCStyle.palette.accent).arg(url).arg(text)
        return "<p style=\"line-height:150%\">"
            + qsTr("VLC media player is a free and open source media player, encoder, and streamer made by the volunteers of the %1 community.")
                  .arg(link("https://www.videolan.org/", "VideoLAN"))
            + "</p><p style=\"line-height:150%\">"
            + qsTr("VLC uses its internal codecs, works on essentially every popular platform, and can read almost all files, CDs, DVDs, network streams, capture cards and other media formats!")
            + "</p><p style=\"line-height:150%\">"
            + link("https://www.videolan.org/contribute/", qsTr("Help and join us!"))
            + "</p><p style=\"line-height:150%\">"
            + qsTr("Interface design by %1, licensed under %2.")
                  .arg("Juxtopposed")
                  .arg(link("https://creativecommons.org/licenses/by/4.0/", "CC BY 4.0"))
            + "</p>"
    }
}
