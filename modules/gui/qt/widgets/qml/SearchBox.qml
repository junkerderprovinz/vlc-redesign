/*****************************************************************************
 * Copyright (C) 2021 VLC authors and VideoLAN
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
import VLC.Style
import VLC.Widgets as Widgets

FocusScope {
    id: root

    implicitWidth: collapsible ? iconButton.implicitWidth : textField.implicitWidth
    implicitHeight: collapsible ? iconButton.implicitHeight : textField.implicitHeight

    // when false, the search field is always shown instead of a button that opens it
    property bool collapsible: true

    property alias popup: popup
    property real maxSearchFieldWidth: Number.MAX_VALUE
    property alias buttonWidth: iconButton.implicitWidth
    property string searchPattern
    property alias regexButtonToggled: regexToggleButton.checked
    property alias caseSensitiveButtonToggled: caseSensitiveToggleButton.checked
    property alias compressSearchPatternChanges: searchPatternBinding.delayed
    compressSearchPatternChanges: true
    property alias displayRegexToggleButton: regexToggleButton.visible
    displayRegexToggleButton: false
    property alias displayCaseSensitiveToggleButton: caseSensitiveToggleButton.visible
    displayCaseSensitiveToggleButton: false

    Binding on searchPattern {
        id: searchPatternBinding
        value: textField.text
    }

    property bool popBelow: true
    property alias toggleButton: iconButton
    property alias textField: textField
    readonly property bool expanded: !collapsible || popup.visible

    // public functions

    function expandAndFocus() {
        if (collapsible)
            popup.open()
        textField.forceActiveFocus(Qt.ShortcutFocusReason)
    }

    function retract() {
        if (collapsible)
            popup.close()
        else
            textField.clear()
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
    }

    Widgets.IconToolButton {
        id: iconButton

        anchors.fill: parent

        visible: root.collapsible

        font.pixelSize: VLCStyle.icon_banner

        text: VLCIcons.search
        description: qsTr("Filter")

        focus: root.collapsible
        checked: popup.visible

        Navigation.parentItem: root
        Navigation.downItem: root.popBelow ? textField : null
        Navigation.upItem: root.popBelow ? null : textField

        onClicked: {
            if (!popup.visible)
                expandAndFocus()
            else
                root.retract()
        }

        T.Popup {
            id: popup

            x: -width + parent.width
            y: root.popBelow ? parent.height : -height

            implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                                    implicitContentWidth + leftPadding + rightPadding)
            implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                                     implicitContentHeight + topPadding + bottomPadding)

            closePolicy: T.Popup.NoAutoClose

            Binding on closePolicy {
                when: textField.text.length === 0
                value: T.Popup.CloseOnPressOutside
            }

            height: 0

            onOpened: {
                textField.forceActiveFocus(iconButton.focusReason)
            }

            onClosed: {
                iconButton.forceActiveFocus(iconButton.focusReason)
            }

            onAboutToHide: {
                textField.text = ""
            }

            component EnterExitTransition : Transition {
                id: transition

                property alias to: animation.to

                NumberAnimation {
                    id: animation

                    property: "height"
                    easing.type: Easing.InOutSine
                    duration: VLCStyle.duration_long
                }

                onRunningChanged: {
                    if (running)
                        textField.clip = true
                    else
                        textField.clip = false
                }
            }

            enter: EnterExitTransition {
                // NOTE: It is intentional that `from` is not used.
                to: popup.implicitHeight
            }

            exit: EnterExitTransition {
                // NOTE: It is intentional that `from` is not used.
                to: 0.0
            }

            contentItem: Item {
                id: popupContent

                implicitWidth: textField.implicitWidth
                implicitHeight: textField.implicitHeight
            }
        }
    }

    TextFieldExt {
        id: textField

        property bool _keyPressed: false

        // the field lives in the popup unless it is always shown
        parent: root.collapsible ? popupContent : root

        anchors.fill: parent

        focus: !root.collapsible

        colorContext.palette: theme.palette

        implicitWidth: VLCStyle.widthSearchInput

        padding: VLCStyle.dp(5, VLCStyle.scale)
        leftPadding: VLCStyle.margin_xsmall + searchIcon.width + VLCStyle.dp(10, VLCStyle.scale)
        rightPadding: VLCStyle.margin_xsmall + (insideRow.visible ? insideRow.width : 0.0)

        background: Rectangle {
            implicitHeight: VLCStyle.dp(34, VLCStyle.scale)

            radius: VLCStyle.dp(6, VLCStyle.scale)

            color: textField.colorContext.bg.secondary

            border.width: textField.activeFocus ? VLCStyle.border : 0
            border.color: textField.colorContext.border
        }

        selectByMouse: true

        placeholderText: qsTr("Search")

        Navigation.parentItem: root
        Navigation.upItem: root.collapsible && root.popBelow ? iconButton : null
        Navigation.downItem: root.collapsible && !root.popBelow ? iconButton : null
        Navigation.rightItem: caseSensitiveToggleButton.visible ? caseSensitiveToggleButton
                                                                : (regexToggleButton.visible ? regexToggleButton
                                                                                             : (clearButton.visible ? clearButton : null))
        Navigation.cancelAction: function() {
            root.retract()
            iconButton.focusReason = Qt.ShortcutFocusReason
        }

        Accessible.searchEdit: true

        //ideally we should use Keys.onShortcutOverride but it doesn't
        //work with TextField before 5.13 see QTBUG-68711
        onActiveFocusChanged: {
            if (activeFocus)
                MainCtx.useGlobalShortcuts = false
            else
                MainCtx.useGlobalShortcuts = true
        }

        Keys.priority: Keys.AfterItem

        Keys.onPressed: (event) => {
            _keyPressed = true

            //we don't want Navigation.cancelAction to match Backspace
            if (event.matches(StandardKey.Backspace))
                event.accepted = true

            Navigation.defaultKeyAction(event)
        }

        Keys.onReleased: (event) => {
            if (_keyPressed === false)
                return

            _keyPressed = false

            //we don't want Navigation.cancelAction to match Backspace
            if (event.matches(StandardKey.Backspace))
                event.accepted = true

            Navigation.defaultKeyReleaseAction(event)
        }

        Widgets.IconLabel {
            id: searchIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: VLCStyle.margin_xsmall

            visible: parent.height > height

            text: VLCIcons.search
            color: textField.colorContext.indicator

            font.pixelSize: VLCStyle.icon_normal
        }

        Row {
            id: insideRow

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: VLCStyle.margin_xxsmall

            spacing: VLCStyle.margin_xxsmall

            visible: parent.height > height

            Widgets.IconToolButton {
                id: caseSensitiveToggleButton

                anchors.verticalCenter: parent.verticalCenter

                // Animating font properties with native rendering is probably not a good idea:
                font.pixelSize: 0.6 * (contentItem.renderType === Text.QtRendering ? textField.height
                                                                                   : textField.implicitHeight)
                text: VLCIcons.ic_fluent_text_change_case_24_regular

                description: qsTr("Case sensitive")

                onClicked: {
                    checked = !checked
                }

                Navigation.parentItem: textField
                Navigation.leftItem: textField
                Navigation.rightItem: regexToggleButton
            }

            Widgets.IconToolButton {
                id: regexToggleButton

                anchors.verticalCenter: parent.verticalCenter

                // Animating font properties with native rendering is probably not a good idea:
                font.pixelSize: 0.6 * (contentItem.renderType === Text.QtRendering ? textField.height
                                                                                   : textField.implicitHeight)
                text: VLCIcons.regex

                description: qsTr("Use regular expression")

                onClicked: {
                    checked = !checked
                }

                Navigation.parentItem: textField
                Navigation.leftItem: caseSensitiveToggleButton
                Navigation.rightItem: clearButton
            }

            Widgets.IconToolButton {
                id: clearButton

                anchors.verticalCenter: parent.verticalCenter

                // Animating font properties with native rendering is probably not a good idea:
                font.pixelSize: 0.6 * (contentItem.renderType === Text.QtRendering ? textField.height
                                                                                   : textField.implicitHeight)
                text: VLCIcons.close

                description: qsTr("Clear")

                visible: (textField.text.length > 0)

                onVisibleChanged: {
                    if (activeFocus && !visible && parent.visible) {
                        textField.focus = true
                        textField.focusReason = focusReason
                    }
                }
                onClicked: textField.clear()

                Navigation.parentItem: textField
                Navigation.leftItem: regexToggleButton
            }
        }
    }
}
