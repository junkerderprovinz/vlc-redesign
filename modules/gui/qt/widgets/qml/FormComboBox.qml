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
import QtQml.Models

import VLC.Style
import VLC.Util
import VLC.Widgets as Widgets

// The drop-down list of a setting. With `checkable` the model is one of the
// player's choice or track models, whose rows carry a `checked` role that
// selects them; otherwise `selectedIndex` names the entry to show.
Widgets.ComboBoxExt {
    id: control

    property bool checkable: false
    // role giving an icon glyph shown before each entry
    property string iconRole: ""
    // role giving the url of an image shown before each entry, or a function
    // giving that url from the text of an entry
    property string imageRole: ""
    property var imageForText: null

    property int selectedIndex: -1

    implicitWidth: VLCStyle.dp(220, VLCStyle.scale)
    font.pixelSize: VLCStyle.fontSize_normal

    Binding on currentIndex {
        when: !control.checkable
        value: control.selectedIndex
        restoreMode: Binding.RestoreNone
    }

    onActivated: (index) => {
        if (checkable)
            model.setData(model.index(index, 0), true, Qt.CheckStateRole)
        else
            // the owner may refuse the choice, the shown entry stays its own
            Qt.callLater(() => { control.currentIndex = control.selectedIndex })
    }

    function _text(model, modelData) {
        if (!textRole)
            return modelData
        return Helpers.isArray(control.model) ? modelData[textRole] : model[textRole]
    }

    Instantiator {
        model: control.checkable ? control.model : null

        delegate: QtObject {
            required property bool checked
            required property int index

            onCheckedChanged: if (checked) control.currentIndex = index
            Component.onCompleted: if (checked) control.currentIndex = index
        }
    }

    Component {
        id: iconDelegate

        T.ItemDelegate {
            id: entry

            readonly property bool current: (index === control.currentIndex)
            readonly property string _text: control._text(model, modelData)
            readonly property string _icon: (control.iconRole && Helpers.isArray(control.model))
                                            ? (modelData[control.iconRole] ?? "") : ""
            readonly property string _image: {
                if (control.imageForText)
                    return control.imageForText(_text)
                if (control.imageRole && Helpers.isArray(control.model))
                    return modelData[control.imageRole] ?? ""
                return ""
            }

            width: ListView.view ? ListView.view.width : control.width
            implicitHeight: VLCStyle.dp(44, VLCStyle.scale)

            leftPadding: VLCStyle.dp(14, VLCStyle.scale)
            rightPadding: VLCStyle.dp(14, VLCStyle.scale)
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            highlighted: control.highlightedIndex === index
            font: control.font

            readonly property ColorContext colorContext: ColorContext {
                id: entryTheme
                colorSet: ColorContext.ComboBox
            }

            background: Rectangle {
                radius: VLCStyle.button_radius
                color: (entry.highlighted || entry.current || entry.hovered) ? entryTheme.bg.highlight
                                                                             : "transparent"
            }

            contentItem: Item {
                implicitHeight: label.implicitHeight

                Widgets.IconLabel {
                    id: glyph

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    width: visible ? VLCStyle.icon_normal : 0
                    visible: entry._icon !== ""

                    text: entry._icon
                    color: entryTheme.accent
                    font.pixelSize: VLCStyle.icon_normal
                }

                Image {
                    id: image

                    anchors.left: glyph.right
                    anchors.verticalCenter: parent.verticalCenter

                    width: visible ? VLCStyle.icon_normal : 0
                    height: VLCStyle.icon_normal
                    visible: entry._image !== ""

                    sourceSize: Qt.size(VLCStyle.icon_normal, VLCStyle.icon_normal)
                    source: entry._image
                }

                T.Label {
                    id: label

                    anchors.left: image.right
                    anchors.leftMargin: (glyph.visible || image.visible) ? entry.spacing : 0
                    anchors.right: check.left
                    anchors.rightMargin: entry.spacing
                    anchors.verticalCenter: parent.verticalCenter

                    text: entry._text
                    color: control.color
                    font: entry.font
                    elide: Text.ElideRight
                }

                Widgets.IconLabel {
                    id: check

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    width: VLCStyle.icon_normal

                    text: VLCIcons.check
                    color: entryTheme.accent
                    font.pixelSize: VLCStyle.icon_normal
                    horizontalAlignment: Text.AlignHCenter

                    visible: entry.current
                }
            }
        }
    }

    Component.onCompleted: {
        if (iconRole || imageRole || imageForText)
            delegate = iconDelegate
    }
}
