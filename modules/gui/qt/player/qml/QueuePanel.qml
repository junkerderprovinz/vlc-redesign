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
import QtQuick.Layouts


import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Widgets as Widgets
import VLC.Playlist
import VLC.Player
import VLC.Style
import VLC.Util
import VLC.Dialogs

// Floating panel of the player with the play queue, the bookmarks and the
// chapters of the current media.
T.Pane {
    id: root

    enum Tab {
        Queue,
        Bookmarks,
        Chapters
    }

    property int currentTab: QueuePanel.Tab.Queue

    property alias playlistView: playlistView

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 0

    focusPolicy: Qt.NoFocus

    readonly property var _tokens: theme.palette ?? VLCStyle.palette

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    background: Rectangle {
        radius: VLCStyle.dp(10, VLCStyle.scale)
        color: root._tokens.bgB1Glass

        Widgets.RoundedRectangleShadow {
            z: -1
            color: Qt.rgba(0, 0, 0, root._tokens.isDark ? 0.46 : 0.18)
            yOffset: VLCStyle.dp(8, VLCStyle.scale)
            blurRadius: VLCStyle.dp(15, VLCStyle.scale)
        }
    }

    contentItem: ColumnLayout {
        spacing: VLCStyle.dp(1, VLCStyle.scale)

        Rectangle {
            id: tabBar

            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(50, VLCStyle.scale)

            radius: VLCStyle.dp(10, VLCStyle.scale)
            color: root._tokens.bgB2

            // square off the bottom corners
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                height: parent.radius
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.dp(6, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(6, VLCStyle.scale)

                spacing: 0

                TabButton {
                    tab: QueuePanel.Tab.Queue
                    glyph: VLCIcons.queue
                    text: qsTr("Queue")
                }

                TabButton {
                    tab: QueuePanel.Tab.Bookmarks
                    glyph: VLCIcons.bookmarks
                    text: qsTr("Bookmarks")
                }

                TabButton {
                    tab: QueuePanel.Tab.Chapters
                    glyph: VLCIcons.chapters
                    text: qsTr("Chapters")
                }
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true

            currentIndex: root.currentTab

            PlaylistPane {
                id: playlistView

                useAcrylic: false
                focus: true

                wheelEnabled: true

                topPadding: 0
                bottomPadding: 0

                background: null
            }

            ColumnLayout {
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: VLCStyle.dp(20, VLCStyle.scale)
                    Layout.bottomMargin: VLCStyle.dp(8, VLCStyle.scale)
                    Layout.leftMargin: VLCStyle.dp(28, VLCStyle.scale)
                    Layout.rightMargin: VLCStyle.dp(20, VLCStyle.scale)

                    spacing: VLCStyle.margin_small

                    T.Label {
                        Layout.fillWidth: true

                        text: qsTr("%1 Bookmark", "%1 Bookmarks", bookmarkList.count).arg(bookmarkList.count)
                        color: root._tokens.fgA3
                        font.pixelSize: VLCStyle.fontSize_large
                        elide: Text.ElideRight
                    }

                    Widgets.IconToolButton {
                        font.pixelSize: VLCStyle.icon_normal

                        text: VLCIcons.edit
                        description: qsTr("Manage bookmarks")

                        onClicked: DialogsProvider.bookmarksDialog()
                    }

                    Widgets.IconToolButton {
                        font.pixelSize: VLCStyle.icon_normal

                        enabled: MainCtx.mediaLibraryAvailable && Player.isStarted
                        text: VLCIcons.add
                        description: qsTr("Add bookmark")

                        onClicked: bookmarkLoader.item?.add()
                    }
                }

                Loader {
                    id: bookmarkLoader

                    active: MainCtx.mediaLibraryAvailable

                    sourceComponent: MLBookmarkModel {
                        player: Player
                        ml: MediaLib
                    }
                }

                ChoiceList {
                    id: bookmarkList

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    model: bookmarkLoader.item

                    emptyText: MainCtx.mediaLibraryAvailable ? qsTr("Add a bookmark to jump back to this moment later.")
                                                             : qsTr("Bookmarks need the media library.")

                    delegate: MarkRow {
                        required property var model
                        required property int index

                        name: model.name
                        trailing: model.time

                        onClicked: bookmarkLoader.item.select(bookmarkLoader.item.index(index, 0))
                    }
                }
            }

            ChoiceList {
                id: chapterList

                topMargin: VLCStyle.dp(20, VLCStyle.scale)

                model: Player.chapters

                emptyText: qsTr("This media has no chapters.")

                delegate: MarkRow {
                    required property var model
                    required property int index

                    number: index + 1
                    name: model.display
                    trailing: model.time.formatHMS()
                    current: model.checked

                    onClicked: Player.chapters.selectChapter(index)
                }
            }
        }
    }

    component TabButton : T.TabButton {
        id: tabButton

        required property int tab
        required property string glyph

        readonly property bool selected: root.currentTab === tab

        Layout.fillWidth: true
        Layout.fillHeight: true

        hoverEnabled: true
        focusPolicy: Qt.TabFocus

        Accessible.role: Accessible.PageTab
        Accessible.name: text

        onClicked: root.currentTab = tab

        background: Item {
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: VLCStyle.margin_xsmall
                anchors.rightMargin: VLCStyle.margin_xsmall

                height: VLCStyle.dp(2, VLCStyle.scale)

                visible: tabButton.selected
                color: theme.accent
            }
        }

        contentItem: Item {
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: VLCStyle.dp(2, VLCStyle.scale)

                spacing: VLCStyle.margin_xsmall

                Widgets.IconLabel {
                    anchors.verticalCenter: parent.verticalCenter

                    text: tabButton.glyph
                    font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
                    color: tabButton.selected ? theme.accent : label.color
                }

                T.Label {
                    id: label

                    anchors.verticalCenter: parent.verticalCenter

                    text: tabButton.text
                    font.pixelSize: VLCStyle.fontSize_normal
                    color: (tabButton.selected || tabButton.hovered || tabButton.visualFocus)
                           ? root._tokens.fgA2 : root._tokens.fgA3
                }
            }
        }
    }

    component ChoiceList : ListView {
        id: list

        property string emptyText

        clip: true
        spacing: VLCStyle.margin_small

        leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        rightMargin: VLCStyle.dp(20, VLCStyle.scale)
        bottomMargin: VLCStyle.dp(20, VLCStyle.scale)

        boundsBehavior: Flickable.StopAtBounds

        T.ScrollBar.vertical: Widgets.ScrollBarExt { }

        T.Label {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: VLCStyle.dp(8, VLCStyle.scale)

            visible: list.count === 0

            text: list.emptyText
            color: root._tokens.fgA3
            font.pixelSize: VLCStyle.fontSize_large
            wrapMode: Text.WordWrap
        }
    }

    component MarkRow : T.ItemDelegate {
        id: row

        property string name
        property string trailing
        property int number: 0
        property bool current: false

        width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
        implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

        horizontalPadding: VLCStyle.dp(4, VLCStyle.scale)

        hoverEnabled: true

        Accessible.name: name

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: (row.hovered || row.visualFocus) ? Qt.alpha(root._tokens.fg1, 0.06) : "transparent"
        }

        contentItem: RowLayout {
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            T.Label {
                Layout.preferredWidth: VLCStyle.dp(34, VLCStyle.scale)

                visible: row.number > 0

                text: row.number
                color: theme.accent
                font.pixelSize: VLCStyle.fontSize_large
                font.weight: Font.Medium
            }

            T.Label {
                Layout.fillWidth: true

                text: row.name
                color: row.current ? theme.accent : root._tokens.fgA1
                font.pixelSize: VLCStyle.fontSize_large
                elide: Text.ElideRight
            }

            T.Label {
                text: row.trailing
                color: root._tokens.fgA3
                font.pixelSize: VLCStyle.fontSize_large
            }
        }
    }
}
