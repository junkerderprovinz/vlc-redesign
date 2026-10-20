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
import VLC.Network
import VLC.Widgets as Widgets
import VLC.Dialogs

// The installed extensions, as the add-ons manager knows them
Column {
    id: root

    readonly property var t: SettingsTheme

    property int selected: -1

    spacing: t.dp(5)

    Rectangle {
        width: parent.width
        height: t.dp(194)
        radius: t.dp(6)
        color: t.bgB2
        border.width: t.dp(2)
        border.color: list.activeFocus ? t.accentDim : t.bgA4

        ListView {
            id: list

            anchors.fill: parent
            anchors.margins: t.dp(6)
            clip: true
            spacing: t.dp(2)
            activeFocusOnTab: true
            boundsBehavior: Flickable.StopAtBounds

            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            model: ServicesDiscoveryModel {
                id: addons

                ctx: MainCtx
                typeFilter: ServicesDiscoveryModel.TYPE_EXTENSION
                stateFilter: ServicesDiscoveryModel.STATE_INSTALLED
                searchPattern: search.text
            }

            Keys.onDeletePressed: removeButton.clicked()

            delegate: T.ItemDelegate {
                id: item

                required property int index
                required property var model

                width: ListView.view.width
                implicitHeight: t.dp(36)
                leftPadding: t.dp(10)
                rightPadding: t.dp(10)
                highlighted: root.selected === index

                onClicked: {
                    root.selected = index
                    list.forceActiveFocus()
                }

                background: Rectangle {
                    radius: t.dp(4)
                    color: item.highlighted ? t.accentBgBright : (item.hovered ? t.bgA4 : "transparent")
                }

                contentItem: Row {
                    spacing: t.dp(12)

                    Text {
                        id: nameLabel

                        anchors.verticalCenter: parent.verticalCenter
                        text: item.model.name ?? ""
                        color: item.highlighted ? t.accent : t.fgA2
                        font.pixelSize: t.fontNormal
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - nameLabel.width - versionLabel.width - parent.spacing * 2
                        text: item.model.summary ?? ""
                        color: t.fgA3
                        font.pixelSize: t.fontNormal
                        elide: Text.ElideRight
                    }

                    Text {
                        id: versionLabel

                        anchors.verticalCenter: parent.verticalCenter
                        text: item.model.version ?? ""
                        color: t.fgA3
                        font.pixelSize: t.fontSmall
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: list.count === 0
                text: search.text.length > 0 ? qsTr("No add-ons match your search") : qsTr("No add-ons installed")
                color: t.fgA3
                font.pixelSize: t.fontNormal
            }
        }
    }

    Item {
        width: parent.width
        height: t.dp(42)

        Widgets.TextFieldExt {
            id: search

            anchors.verticalCenter: parent.verticalCenter
            width: t.dp(210)
            height: t.dp(36)
            rightPadding: t.dp(18)
            font.pixelSize: t.fontNormal
            selectByMouse: true
            placeholderText: qsTr("Search")
            onTextChanged: root.selected = -1
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: t.dp(10)

            SettingsButton {
                text: qsTr("Find more extensions")
                onClicked: Qt.openUrlExternally("https://addons.videolan.org/")
            }

            SettingsButton {
                text: qsTr("Add")
                onClicked: DialogsProvider.pluginDialog()
            }

            SettingsButton {
                id: removeButton

                text: qsTr("Remove")
                enabled: root.selected >= 0 && root.selected < list.count
                onClicked: {
                    addons.removeService(root.selected)
                    root.selected = -1
                }
            }
        }
    }
}
