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
import QtQuick.Controls.Basic
import QtQuick.Templates as T


import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Util

T.ComboBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + spacing + implicitIndicatorWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorHeight + topPadding + bottomPadding)

    // the field sits inside a frame of this width
    readonly property real frameWidth: VLCStyle.margin_xxxsmall

    padding: frameWidth
    leftPadding: frameWidth + VLCStyle.dp(14, VLCStyle.scale)
    rightPadding: frameWidth + VLCStyle.dp(14, VLCStyle.scale)
    spacing: VLCStyle.dp(10, VLCStyle.scale)

    font.pixelSize: VLCStyle.fontSize_large

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.ComboBox

        focused: control.visualFocus
        enabled: control.enabled
        hovered: control.hovered
        pressed: control.pressed
    }

    property color color: theme.fg.primary
    property color bgColor: theme.bg.secondary
    property color frameColor: theme.bg.primary
    property color borderColor: theme.border

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

    delegate: T.ItemDelegate {
        id: delegate

        readonly property bool current: (index === control.currentIndex)

        width: ListView.view ? ListView.view.width : control.width
        implicitHeight: VLCStyle.dp(44, VLCStyle.scale)

        leftPadding: VLCStyle.dp(14, VLCStyle.scale)
        rightPadding: VLCStyle.dp(14, VLCStyle.scale)

        highlighted: control.highlightedIndex === index

        font: control.font

        background: Rectangle {
            radius: VLCStyle.button_radius

            color: (delegate.highlighted || delegate.current || delegate.hovered) ? popupTheme.bg.highlight
                                                                                  : "transparent"
        }

        contentItem: Item {
            implicitHeight: label.implicitHeight

            T.Label {
                id: label

                anchors.left: parent.left
                anchors.right: check.left
                anchors.rightMargin: control.spacing
                anchors.verticalCenter: parent.verticalCenter

                text: control.textRole ? (Helpers.isArray(control.model) ? modelData[control.textRole] : model[control.textRole])
                                       : modelData
                color: control.color
                font: delegate.font
                elide: Text.ElideRight
            }

            Widgets.IconLabel {
                id: check

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                width: VLCStyle.icon_normal

                text: VLCIcons.check
                color: popupTheme.accent
                font.pixelSize: VLCStyle.icon_normal
                horizontalAlignment: Text.AlignHCenter

                visible: delegate.current
            }
        }
    }

    indicator: Widgets.IconLabel {
        x: control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        font.pixelSize: VLCStyle.icon_normal
        text: VLCIcons.chevron_down
        color: control.color
        rotation: control.popup.visible ? 180 : 0
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    contentItem: T.Label {
        rightPadding: control.spacing + control.indicator.width

        text: control.displayText
        color: control.color
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitHeight: VLCStyle.dp(48, VLCStyle.scale)

        radius: VLCStyle.dp(6, VLCStyle.scale)
        color: control.frameColor

        border.width: control.visualFocus ? VLCStyle.focus_border : 0
        border.color: theme.visualFocus

        Widgets.AnimatedBackground {
            anchors.fill: parent
            anchors.margins: control.frameWidth

            enabled: theme.initialized

            animationDuration: VLCStyle.duration_short

            radius: VLCStyle.button_radius
            color: control.bgColor
            border.width: 0
        }
    }

    // like the design, the open list covers the field
    popup: Popup {
        y: 0

        // NOTE: This Popup should be on top of other Popup(s) most of the time.
        z: 100

        width: control.width
        padding: control.frameWidth

        ColorContext {
            id: popupTheme
            palette: theme.palette
            colorSet: ColorContext.ComboBox
            enabled: control.enabled
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            spacing: control.frameWidth
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex

            ScrollBar.vertical: Widgets.ScrollBarExt {
                colorContext.palette: popupTheme.palette
            }
        }

        background: Rectangle {
            color: popupTheme.bg.secondary
            border.color: control.borderColor
            border.width: control.borderColor.a > 0 ? VLCStyle.border : 0
            border.pixelAligned: (radius < Number.EPSILON)
            radius: VLCStyle.dp(6, VLCStyle.scale)

            Widgets.RoundedRectangleShadow {
                yOffset: VLCStyle.margin_xxsmall
                blurRadius: VLCStyle.dp(7, VLCStyle.scale)

                color: popupTheme.shadow
            }
        }
    }
}
