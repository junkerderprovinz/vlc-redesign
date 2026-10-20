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
import QtQuick.Templates as T


import VLC.MainInterface
import VLC.Style
import VLC.Widgets as Widgets

T.SpinBox {
    id: control

    property color textColor: theme.fg.primary
    property color bgColor: theme.bg.primary
    property color borderColor:  theme.border
    property int borderWidth: VLCStyle.dp(2, VLCStyle.scale)

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.SpinBox

        enabled: control.enabled
        focused: (control.visualFocus || textInput.activeFocus)
        hovered: control.hovered
    }

    font.pixelSize: VLCStyle.fontSize_large

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                              contentItem.implicitWidth + leftPadding + rightPadding)

    implicitHeight: Math.max(implicitContentHeight + topPadding + bottomPadding,
                           implicitBackgroundHeight,
                           up.implicitIndicatorHeight,
                           down.implicitIndicatorHeight)

    padding: VLCStyle.margin_xxsmall
    leftPadding: VLCStyle.margin_small + (control.mirrored ? up.indicator.width : 0)
    rightPadding: VLCStyle.margin_xxsmall + (control.mirrored ? 0 : up.indicator.width)
    topPadding: padding + control.borderWidth
    bottomPadding: padding + control.borderWidth

    Keys.priority: Keys.AfterItem
    Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

    //ideally we should use Keys.onShortcutOverride but it doesn't
    //work with TextField before 5.13 see QTBUG-68711
    onActiveFocusChanged: {
        if (activeFocus)
            MainCtx.useGlobalShortcuts = false
        else
            MainCtx.useGlobalShortcuts = true
    }

    background: Rectangle {
        implicitHeight: VLCStyle.dp(36, VLCStyle.scale)

        radius: VLCStyle.dp(6, VLCStyle.scale)
        border.color: control.borderColor
        border.width: control.borderWidth
        border.pixelAligned: (radius < Number.EPSILON)
        color: control.bgColor
    }

    contentItem: TextInput {
        id: textInput

        // NOTE: This is required for InterfaceWindowHandler::applyKeyEvent.
        property bool visualFocus: control.activeFocus

        text: control.textFromValue(control.value, control.locale)

        font: control.font
        color: control.textColor
        selectionColor: theme.bg.highlight
        selectedTextColor: theme.fg.highlight

        padding: 0
        horizontalAlignment: Qt.AlignLeft
        verticalAlignment: Qt.AlignVCenter

        selectByMouse: true
        autoScroll: false
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly

        Keys.priority: Keys.AfterItem

        Navigation.parentItem: control
    }

    component StepIndicator : Item {
        id: indicator

        required property QtObject button
        required property string iconTxt
        required property bool available

        x: control.mirrored ? control.borderWidth : control.width - width - control.borderWidth - VLCStyle.margin_xxsmall

        implicitWidth: VLCStyle.icon_normal
        implicitHeight: VLCStyle.dp(14, VLCStyle.scale)

        height: (control.height - control.borderWidth * 2) / 2

        ColorContext {
            id: stepTheme
            colorSet: ColorContext.SpinBox

            enabled: control.enabled && indicator.available
            hovered: indicator.button.hovered
            pressed: indicator.button.pressed

            // root control handles focused state
            focused: false
        }

        Widgets.IconLabel {
            anchors.fill: parent

            text: indicator.iconTxt
            color: stepTheme.fg.secondary

            font.pixelSize: VLCStyle.icon_small
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    up.indicator: StepIndicator {
        y: control.borderWidth

        button: control.up
        iconTxt: VLCIcons.chevron_up
        available: control.wrap || control.value < Math.max(control.from, control.to)
    }

    down.indicator: StepIndicator {
        y: control.height - height - control.borderWidth

        button: control.down
        iconTxt: VLCIcons.chevron_down
        available: control.wrap || control.value > Math.min(control.from, control.to)
    }
}
