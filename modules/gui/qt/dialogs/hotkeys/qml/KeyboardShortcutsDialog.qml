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
import QtQuick.Layouts
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Dialogs

FramelessDialog {
    id: root

    title: qsTr("Keyboard Shortcuts")

    acceptEnabled: hotkeys.modified

    readonly property real _cellWidth: VLCStyle.dp(270, VLCStyle.scale)
    readonly property real _actionWidth: VLCStyle.dp(290, VLCStyle.scale)

    property string _notice: ""

    onVisibleChanged: {
        if (!visible)
            return
        hotkeys.reload()
        _notice = ""
        searchField.text = ""
        searchField.forceActiveFocus()
    }

    onAccepted: hotkeys.apply()

    HotkeysModel {
        id: hotkeys

        ctx: MainCtx
        filterText: searchField.text
        filterField: scopeSelect.currentValue ?? HotkeysModel.ANY_FIELD
    }

    toolbarData: RowLayout {
        anchors.fill: parent

        spacing: VLCStyle.dp(10, VLCStyle.scale)

        DialogToolbarField {
            id: searchField

            focus: true
            iconText: VLCIcons.search
            placeholderText: qsTr("Search Keyboard Shortcuts...")
        }

        DialogSelect {
            id: scopeSelect

            model: [
                { text: qsTr("All Fields"), value: HotkeysModel.ANY_FIELD },
                { text: qsTr("Action"), value: HotkeysModel.ACTION_FIELD },
                { text: qsTr("Hotkey"), value: HotkeysModel.HOTKEY_FIELD },
                { text: qsTr("Global Hotkey"), value: HotkeysModel.GLOBAL_HOTKEY_FIELD }
            ]
        }
    }

    footerData: Widgets.LabelExt {
        anchors.fill: parent

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        color: VLCStyle.palette.fgA3
        font.pixelSize: VLCStyle.fontSize_large
        textFormat: Text.PlainText

        text: root._notice.length > 0 ? root._notice
                                      : (hotkeys.modified ? qsTr("Changes take effect after VLC restarts.") : "")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: VLCStyle.dp(20, VLCStyle.scale)
        anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
        anchors.topMargin: VLCStyle.dp(20, VLCStyle.scale)

        spacing: 0

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: VLCStyle.dp(25, VLCStyle.scale)

            spacing: 0

            HeaderLabel {
                Layout.preferredWidth: root._actionWidth
                text: qsTr("Action")
                horizontalAlignment: Text.AlignLeft
            }

            Item { Layout.fillWidth: true }

            HeaderLabel {
                Layout.preferredWidth: root._cellWidth
                text: qsTr("Hotkey")
            }

            Item { Layout.fillWidth: true }

            HeaderLabel {
                Layout.preferredWidth: root._cellWidth
                text: qsTr("Global Hotkey")
            }
        }

        ListView {
            id: list

            Layout.fillWidth: true
            Layout.fillHeight: true

            clip: true
            model: hotkeys
            spacing: VLCStyle.dp(14, VLCStyle.scale)
            boundsBehavior: Flickable.StopAtBounds

            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            section.property: "section"
            section.delegate: ColumnLayout {
                required property string section

                width: ListView.view.width

                spacing: VLCStyle.dp(20, VLCStyle.scale)

                Item { Layout.preferredHeight: VLCStyle.dp(6, VLCStyle.scale) }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.border
                    color: VLCStyle.palette.dividerDim
                }

                Widgets.LabelExt {
                    Layout.fillWidth: true
                    Layout.preferredHeight: VLCStyle.dp(28, VLCStyle.scale)
                    Layout.bottomMargin: VLCStyle.dp(6, VLCStyle.scale)

                    text: parent.section
                    verticalAlignment: Text.AlignVCenter
                    color: VLCStyle.palette.fgA1
                    font.pixelSize: VLCStyle.fontSize_xlarge
                    textFormat: Text.PlainText
                }
            }

            delegate: RowLayout {
                id: row

                required property int index
                required property string label
                required property string hotkey
                required property string globalHotkey
                required property bool hotkeyModified
                required property bool globalHotkeyModified

                width: ListView.view.width
                height: VLCStyle.dp(33, VLCStyle.scale)

                spacing: 0

                Widgets.LabelExt {
                    Layout.preferredWidth: root._actionWidth

                    text: row.label
                    elide: Text.ElideRight
                    color: VLCStyle.palette.fg2
                    font.pixelSize: VLCStyle.fontSize_large
                    textFormat: Text.PlainText
                }

                Item { Layout.fillWidth: true }

                KeyCell {
                    row: row.index
                    actionLabel: row.label
                    keys: row.hotkey
                    modified: row.hotkeyModified
                    isGlobal: false
                }

                Item { Layout.fillWidth: true }

                KeyCell {
                    row: row.index
                    actionLabel: row.label
                    keys: row.globalHotkey
                    modified: row.globalHotkeyModified
                    isGlobal: true
                }
            }

            footer: Item {
                width: ListView.view.width
                height: VLCStyle.dp(22, VLCStyle.scale)
            }

            Widgets.LabelExt {
                anchors.top: parent.top
                anchors.topMargin: VLCStyle.dp(20, VLCStyle.scale)

                visible: list.count === 0
                text: qsTr("No shortcuts match your search.")
                color: VLCStyle.palette.fgA3
                font.pixelSize: VLCStyle.fontSize_large
                textFormat: Text.PlainText
            }
        }
    }

    component HeaderLabel: Widgets.LabelExt {
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: VLCStyle.palette.fgA3
        font.pixelSize: VLCStyle.fontSize_large
        textFormat: Text.PlainText
    }

    component KeyCell: T.AbstractButton {
        id: cell

        required property int row
        required property string actionLabel
        required property string keys
        required property bool modified
        required property bool isGlobal

        property bool recording: false

        Layout.preferredWidth: root._cellWidth
        Layout.fillHeight: true

        focusPolicy: Qt.StrongFocus
        hoverEnabled: true

        Accessible.name: (isGlobal ? qsTr("Global hotkey for %1") : qsTr("Hotkey for %1")).arg(actionLabel)
        Accessible.description: keys

        T.ToolTip.visible: hovered && !recording
        T.ToolTip.delay: VLCStyle.delayToolTipAppear
        T.ToolTip.text: qsTr("Click to change, Delete to remove, right-click to reset")

        onClicked: {
            recording = true
            forceActiveFocus()
        }

        onActiveFocusChanged: if (!activeFocus) recording = false

        Keys.onPressed: (event) => {
            if (!recording) {
                if (event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace) {
                    event.accepted = true
                    hotkeys.unset(row, isGlobal)
                }
                return
            }

            if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab)
                return
            event.accepted = true

            if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                recording = false
                return
            }
            if ((event.key === Qt.Key_Delete || event.key === Qt.Key_Backspace)
                    && event.modifiers === Qt.NoModifier) {
                hotkeys.unset(row, isGlobal)
                recording = false
                return
            }

            const key = hotkeys.keyFromEvent(event.key, event.modifiers, event.text)
            if (key.length === 0)
                return

            const conflict = hotkeys.conflictingAction(row, isGlobal, key)
            root._notice = conflict.length > 0
                ? qsTr("The key was removed from \"%1\".").arg(conflict)
                : ""
            hotkeys.assign(row, isGlobal, key)
            recording = false
        }

        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: {
                cell.recording = false
                hotkeys.reset(cell.row, cell.isGlobal)
            }
        }

        background: Rectangle {
            radius: VLCStyle.dp(6, VLCStyle.scale)
            color: VLCStyle.palette.bgB2
            border.width: cell.recording || cell.visualFocus ? VLCStyle.focus_border : 0
            border.color: VLCStyle.palette.accentDim
        }

        contentItem: Item {
            Widgets.LabelExt {
                anchors.centerIn: parent
                width: Math.min(implicitWidth, parent.width - 2 * VLCStyle.dp(34, VLCStyle.scale))

                text: cell.recording ? qsTr("Press a key") : cell.keys
                elide: Text.ElideRight
                color: cell.recording ? VLCStyle.palette.accent : VLCStyle.palette.fg2
                font.pixelSize: VLCStyle.fontSize_large
                font.weight: cell.modified ? Font.DemiBold : Font.Normal
                textFormat: Text.PlainText
            }

            Widgets.IconLabel {
                anchors.right: parent.right
                anchors.rightMargin: VLCStyle.dp(5, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter

                text: VLCIcons.edit
                color: cell.hovered ? VLCStyle.palette.fgA2 : VLCStyle.palette.fgA3
                font.pixelSize: VLCStyle.icon_normal
            }
        }
    }
}
