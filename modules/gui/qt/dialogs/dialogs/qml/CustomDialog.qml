/*****************************************************************************
 * Copyright (C) 2020 VLC authors and VideoLAN
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
import VLC.Style
import VLC.Widgets as Widgets

ModalDialog {
    id: root

    property string text

    property alias cancelTxt: cancelBtn.text
    property alias okTxt: okBtn.text

    property var _acceptCb: undefined
    property var _rejectCb: undefined

    function ask(text, acceptCb, rejectCb, buttons) {
        //TODO: use a Promise here when dropping support of Qt 5.11
        let okTxt = qsTr("OK")
        let cancelTxt = qsTr("Cancel")
        if (buttons) {
            if (buttons.cancel) {
                cancelTxt = buttons.cancel
            }
            if (buttons.ok) {
                okTxt = buttons.ok
            }
        }
        root.cancelTxt = cancelTxt
        root.okTxt = okTxt
        root.text = text
        root._acceptCb = acceptCb
        root._rejectCb = rejectCb
        root.open()
    }

    onAccepted: {
        if (_acceptCb)
            _acceptCb()
    }

    onRejected: {
        if (_rejectCb)
            _rejectCb()
    }

    width: Math.max(implicitWidth, VLCStyle.dp(440, VLCStyle.scale))

    contentItem: Text {
        focus: false
        font.pixelSize: VLCStyle.fontSize_large
        lineHeight: VLCStyle.dp(25, VLCStyle.scale)
        lineHeightMode: Text.FixedHeight
        color: root.colorContext.fg.secondary
        wrapMode: Text.WordWrap
        text: root.text
    }

    footer: FocusScope {
        focus: true
        id: questionButtons

        implicitWidth: buttonRow.implicitWidth + buttonRow.anchors.margins * 2
        implicitHeight: buttonRow.implicitHeight + buttonRow.anchors.margins * 2

        readonly property ColorContext colorContext: ColorContext {
            palette: root.colorContext.palette
        }

        RowLayout {
            id: buttonRow

            anchors.fill: parent
            anchors.margins: VLCStyle.dp(20, VLCStyle.scale)

            spacing: VLCStyle.dp(20, VLCStyle.scale)

            Widgets.DialogButton {
                id: cancelBtn
                focus: true
                visible: cancelBtn.text !== ""

                onClicked: root.reject()

                Navigation.rightItem: okBtn
                Keys.priority: Keys.AfterItem
                Keys.onPressed: (event) => okBtn.Navigation.defaultKeyAction(event)
            }

            Item {
                Layout.fillWidth: true
            }

            Widgets.DialogButton {
                id: okBtn
                visible: okBtn.text !== ""

                primary: true

                onClicked: root.accept()

                Navigation.leftItem: cancelBtn
                Keys.priority: Keys.AfterItem
                Keys.onPressed: (event) => cancelBtn.Navigation.defaultKeyAction(event)
            }
        }
    }
}
