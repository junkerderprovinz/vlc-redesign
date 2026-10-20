/*****************************************************************************
 * Copyright (C) 2024 VLC authors and VideoLAN
 *
 * Authors: Leon Vitanos <leon.vitanos@gmail.com>
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
import QtQuick.Templates as T


import VLC.MainInterface
import VLC.Style
import VLC.Util

T.Pane {
    id: root

    // Properties
    required property Item view

    leftPadding: view?.contentLeftMargin ?? 0
    rightPadding: view?.contentRightMargin ?? 0

    bottomPadding: 0
    topPadding: VLCStyle.dp(57, VLCStyle.scale)

    // Aliases

    property alias text: label.text

    property alias seeAllButton: button

    // Signals

    signal seeAllButtonClicked(int reason)

    // Settings

    width: view.width
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    Navigation.parentItem: view
    Navigation.navigable: button.visible

    Component.onCompleted: {
        // Qt Quick Pane sets a cursor for itself, unset it so that if the view has
        // busy cursor, it is visible over the header:
        MainCtx.unsetCursor(this)
    }

    // Children

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.View
    }

    // Events
    onContentItemChanged: {
      console.assert(contentItem === root.row)
    }

    RowLayout {
        id: row

        anchors.fill: parent

        spacing: VLCStyle.dp(5, VLCStyle.scale)

        LabelExt {
            id: label

            Layout.maximumWidth: row.width - (button.visible ? button.width + row.spacing : 0)

            elide: Text.ElideRight
            textFormat: Text.PlainText

            font.pixelSize: VLCStyle.fontSize_xlarge

            color: (button.visible && labelHover.hovered) ? theme.fg.highlight : theme.fg.primary

            HoverHandler {
                id: labelHover

                enabled: button.visible
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                enabled: button.visible

                onTapped: root.seeAllButtonClicked(Qt.MouseFocusReason)
            }
        }

        IconToolButton {
            id: button

            visible: false

            focus: true

            Binding on focusReason {
                // NOTE: This is an explicit binding so that it does not get overridden:
                value: root.focusReason
            }

            description: qsTr("See All")
            text: VLCIcons.chevron_right

            Navigation.parentItem: root

            onClicked: root.seeAllButtonClicked(focusReason)
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
