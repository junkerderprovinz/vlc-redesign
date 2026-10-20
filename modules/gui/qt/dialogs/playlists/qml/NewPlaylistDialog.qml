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

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Dialogs

FramelessDialog {
    id: root

    title: qsTr("New Playlist")

    designWidth: VLCStyle.dp(713, VLCStyle.scale)
    designHeight: VLCStyle.dp(589, VLCStyle.scale)

    acceptEnabled: titleField.text.trim().length > 0

    onVisibleChanged: {
        if (!visible)
            return
        titleField.text = ""
        files.clear()
        titleField.forceActiveFocus()
    }

    onAccepted: {
        const urls = []
        for (let i = 0; i < files.count; ++i)
            urls.push(files.get(i).url)
        playlistCreator.create(titleField.text.trim(), urls)
    }

    function addFiles(urls) {
        for (const url of urls) {
            const text = url.toString()
            let known = false
            for (let i = 0; i < files.count && !known; ++i)
                known = (files.get(i).url === text)
            if (known)
                continue
            const name = decodeURIComponent(text.substring(text.lastIndexOf("/") + 1))
            files.append({ url: text, name: name.length > 0 ? name : text })
        }
    }

    function browse() {
        addFiles(DialogsProvider.showSimpleOpen(qsTr("Select Files")))
    }

    ListModel {
        id: files
    }

    PlaylistCreator {
        id: playlistCreator
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

            title: qsTr("Playlist Details")
            description: qsTr("The playlist will be saved and displayed with this title.")
        }

        Widgets.TextFieldExt {
            id: titleField

            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(37, VLCStyle.scale)

            leftPadding: VLCStyle.dp(14, VLCStyle.scale)
            rightPadding: VLCStyle.dp(18, VLCStyle.scale)

            placeholderText: qsTr("e.g., Favorite Videos")
            font.pixelSize: VLCStyle.fontSize_large

            background: Rectangle {
                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: VLCStyle.palette.bgB2
                border.width: VLCStyle.dp(2, VLCStyle.scale)
                border.color: titleField.activeFocus ? VLCStyle.palette.accentDim : VLCStyle.palette.bgA4
            }

            Accessible.name: qsTr("Playlist title")

            onAccepted: root.accept()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.border

            color: VLCStyle.palette.dividerDim
        }

        DialogHeading {
            Layout.fillWidth: true

            title: qsTr("Select Files")
            description: qsTr("These files will be added to the playlist.")
        }

        Item {
            id: dropZone

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: VLCStyle.dp(186, VLCStyle.scale)

            activeFocusOnTab: true

            Accessible.role: Accessible.Button
            Accessible.name: qsTr("Add files")
            Accessible.onPressAction: root.browse()

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                    event.accepted = true
                    root.browse()
                }
            }

            Rectangle {
                anchors.fill: parent

                radius: VLCStyle.dp(6, VLCStyle.scale)
                color: VLCStyle.palette.bgB2
            }

            Canvas {
                id: dashes

                anchors.fill: parent

                readonly property color strokeColor: (dropArea.containsDrag || dropZone.activeFocus)
                                                     ? VLCStyle.palette.accentDim
                                                     : VLCStyle.palette.dividerBright

                onStrokeColorChanged: requestPaint()
                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d")
                    const lineWidth = VLCStyle.dp(2, VLCStyle.scale)
                    const r = VLCStyle.dp(6, VLCStyle.scale)
                    const inset = lineWidth / 2
                    ctx.reset()
                    ctx.strokeStyle = strokeColor
                    ctx.lineWidth = lineWidth
                    ctx.setLineDash([3, 3])
                    ctx.beginPath()
                    ctx.roundedRect(inset, inset, width - lineWidth, height - lineWidth, r, r)
                    ctx.stroke()
                }
            }

            TapHandler {
                enabled: files.count === 0
                onTapped: root.browse()
            }

            DropArea {
                id: dropArea

                anchors.fill: parent

                onDropped: (drop) => {
                    if (!drop.hasUrls)
                        return
                    root.addFiles(drop.urls)
                    drop.accept()
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: VLCStyle.dp(12, VLCStyle.scale)

                spacing: VLCStyle.dp(12, VLCStyle.scale)

                Item {
                    Layout.fillHeight: true
                    visible: files.count === 0
                }

                Widgets.LabelExt {
                    Layout.alignment: Qt.AlignHCenter

                    visible: files.count === 0
                    text: qsTr("Drag files into the box or click here to select files.")
                    color: VLCStyle.palette.fgA4
                    font.pixelSize: VLCStyle.fontSize_large
                    textFormat: Text.PlainText
                }

                ListView {
                    id: fileList

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    visible: files.count > 0
                    clip: true
                    spacing: VLCStyle.dp(4, VLCStyle.scale)
                    model: files

                    delegate: Rectangle {
                        id: fileRow

                        required property int index
                        required property string name

                        width: ListView.view.width
                        height: VLCStyle.dp(36, VLCStyle.scale)

                        radius: VLCStyle.dp(6, VLCStyle.scale)
                        color: rowHover.hovered ? VLCStyle.palette.bgA4 : "transparent"

                        HoverHandler {
                            id: rowHover
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)
                            anchors.rightMargin: VLCStyle.dp(4, VLCStyle.scale)

                            spacing: VLCStyle.dp(14, VLCStyle.scale)

                            Widgets.IconLabel {
                                text: VLCIcons.video
                                color: VLCStyle.palette.fgA2
                                font.pixelSize: VLCStyle.icon_normal
                            }

                            Widgets.LabelExt {
                                Layout.fillWidth: true

                                text: fileRow.name
                                elide: Text.ElideMiddle
                                color: VLCStyle.palette.fgA1
                                font.pixelSize: VLCStyle.fontSize_large
                                textFormat: Text.PlainText
                            }

                            Widgets.IconToolButton {
                                text: VLCIcons.close
                                description: qsTr("Remove %1").arg(fileRow.name)
                                font.pixelSize: VLCStyle.icon_normal

                                onClicked: files.remove(fileRow.index)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: VLCStyle.dp(84, VLCStyle.scale)
                    Layout.preferredHeight: VLCStyle.dp(30, VLCStyle.scale)

                    radius: VLCStyle.dp(5, VLCStyle.scale)
                    color: VLCStyle.palette.fgB1

                    TapHandler {
                        enabled: files.count > 0
                        onTapped: root.browse()
                    }

                    Widgets.IconLabel {
                        anchors.centerIn: parent

                        text: VLCIcons.add
                        color: dropZoneHover.hovered ? VLCStyle.palette.fg1 : VLCStyle.palette.fgA2
                        font.pixelSize: VLCStyle.icon_normal
                    }
                }

                Item {
                    Layout.fillHeight: true
                    visible: files.count === 0
                }
            }

            HoverHandler {
                id: dropZoneHover
                cursorShape: Qt.PointingHandCursor
            }
        }
    }
}
