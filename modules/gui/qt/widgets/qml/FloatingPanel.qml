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

import VLC.Widgets as Widgets
import VLC.Style

// Rounded panel floating over the player, with a row of tabs on top.
T.Pane {
    id: root

    // Properties

    // { text, iconTxt } per tab, checkedIconSource replaces the glyph of the current tab
    property var tabs: []
    property int currentTab: 0

    default property alias content: body.data

    // Signals

    signal tabClicked(int index)

    // Settings

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 0

    focusPolicy: Qt.NoFocus

    // Children

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    background: Rectangle {
        radius: VLCStyle.dp(10, VLCStyle.scale)
        color: theme.tokens.bgB1Glass

        Widgets.RoundedRectangleShadow {
            z: -1
            color: theme.shadow
            yOffset: VLCStyle.dp(8, VLCStyle.scale)
            blurRadius: VLCStyle.dp(15, VLCStyle.scale)
        }
    }

    contentItem: ColumnLayout {
        spacing: VLCStyle.dp(1, VLCStyle.scale)

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(50, VLCStyle.scale)

            radius: VLCStyle.dp(10, VLCStyle.scale)
            color: theme.tokens.bgB2

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

                Repeater {
                    model: root.tabs

                    delegate: Widgets.TabButtonExt {
                        required property var modelData
                        required property int index

                        readonly property url _checkedIcon: modelData.checkedIconSource ?? ""

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        indicatorMargin: VLCStyle.margin_xsmall

                        text: modelData.text
                        font.pixelSize: VLCStyle.fontSize_small
                        checked: root.currentTab === index
                        iconTxt: (checked && _checkedIcon.toString().length > 0) ? "" : modelData.iconTxt
                        checkedIconSource: _checkedIcon

                        Accessible.role: Accessible.PageTab

                        onClicked: root.tabClicked(index)
                    }
                }
            }
        }

        Item {
            id: body

            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
