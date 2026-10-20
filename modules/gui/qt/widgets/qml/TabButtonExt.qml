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
import VLC.Widgets as Widgets
import VLC.Style

T.TabButton {
    id: control

    // Properties

    property string iconTxt: ""

    // an image drawn instead of iconTxt, such as a two-tone svg
    property url iconSource
    property url checkedIconSource: iconSource

    property real indicatorMargin: VLCStyle.margin_small

    // Settings

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    topPadding: VLCStyle.dp(14, VLCStyle.scale)
    bottomPadding: VLCStyle.dp(16, VLCStyle.scale)
    leftPadding: VLCStyle.margin_xsmall
    rightPadding: VLCStyle.margin_xsmall

    spacing: VLCStyle.margin_xsmall

    font.pixelSize: VLCStyle.fontSize_normal

    // Keys

    Keys.priority: Keys.AfterItem

    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

    // Accessible

    Accessible.onPressAction: control.clicked()

    // Children

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.TabButton

        focused: control.visualFocus
        hovered: control.hovered
        pressed: control.down
        enabled: control.enabled
    }

    background: Item {
        implicitHeight: VLCStyle.dp(50, VLCStyle.scale)

        Rectangle {
            anchors.fill: parent

            color: "transparent"

            border.width: VLCStyle.focus_border
            border.color: control.visualFocus ? theme.visualFocus : "transparent"
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: control.indicatorMargin
            anchors.rightMargin: control.indicatorMargin

            height: VLCStyle.heightBar_xxxsmall

            color: theme.accent

            visible: control.checked
        }
    }

    contentItem: RowLayout {
        spacing: control.spacing

        Item {
            Layout.fillWidth: true
        }

        Image {
            visible: source.toString().length > 0

            source: control.checked ? control.checkedIconSource : control.iconSource

            sourceSize.width: VLCStyle.dp(20, VLCStyle.scale)
            sourceSize.height: VLCStyle.dp(20, VLCStyle.scale)

            Layout.alignment: Qt.AlignVCenter
        }

        Widgets.IconLabel {
            visible: text.length > 0 && control.iconSource.toString().length === 0

            text: control.iconTxt

            color: control.checked ? theme.accent : label.color

            font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)

            Layout.alignment: Qt.AlignVCenter
        }

        T.Label {
            id: label

            text: control.text

            color: control.checked ? theme.fg.secondary : theme.fg.primary

            font: control.font

            elide: Text.ElideRight

            //button text is already exposed
            Accessible.ignored: true

            Layout.alignment: Qt.AlignVCenter
            Layout.maximumWidth: implicitWidth + 1
            Layout.fillWidth: true
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
