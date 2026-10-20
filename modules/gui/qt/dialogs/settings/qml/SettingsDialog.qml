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
import QtQuick.Window
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.MediaLibrary
import VLC.Style
import VLC.Util
import VLC.Widgets as Widgets
import VLC.Dialogs

// The Global Settings dialog: a category list on the left, one page of
// settings on the right, and a search across every page. Options are written
// as they change and saved when the dialog closes.
Window {
    id: root

    readonly property var t: SettingsTheme

    property string pageId: "general"
    readonly property var page: pages.pages.find((p) => p.id === pageId) ?? pages.pages[0]
    readonly property string query: searchField.text.trim()

    // pages whose advanced options are shown
    property var expanded: ({})

    transientParent: MainCtx.intfMainWindow
    flags: Qt.Dialog | Qt.FramelessWindowHint
    modality: Qt.ApplicationModal

    title: qsTr("Global Settings")

    width: Math.min(t.dp(1048), Screen.desktopAvailableWidth - t.dp(32))
    height: Math.min(t.dp(865), Screen.desktopAvailableHeight - t.dp(32))

    color: t.bgB1

    function open(pageName) {
        if (pageName)
            pageId = pageName
        searchField.text = ""
        const parent = MainCtx.intfMainWindow
        if (parent && !visible) {
            x = parent.x + (parent.width - width) / 2
            y = parent.y + Math.max(0, (parent.height - height) / 2)
        }
        show()
        raise()
        requestActivate()
        searchField.forceActiveFocus()
    }

    function showPage(id) {
        searchField.text = ""
        pageId = id
        content.contentY = 0
    }

    function setExpanded(id, on) {
        const next = Object.assign({}, expanded)
        next[id] = on
        expanded = next
    }

    function matches(row, section) {
        const q = query.toLowerCase()
        return (row.label ?? "").toLowerCase().includes(q)
            || (row.info ?? "").toLowerCase().includes(q)
            || (section.title ?? "").toLowerCase().includes(q)
    }

    readonly property var results: {
        if (query.length === 0)
            return []
        const groups = []
        for (const p of pages.pages) {
            const rows = []
            for (const s of p.sections.concat(p.advanced ?? [])) {
                for (const r of s.rows) {
                    if ((r.label ?? "").length > 0 && matches(r, s))
                        rows.push(r)
                }
            }
            if (rows.length > 0)
                groups.push({ page: p, title: p.title, rows: rows })
        }
        return groups
    }

    function isAdvanced(p, row) {
        return (p.advanced ?? []).some((s) => s.rows.includes(row))
    }

    function findRow(item, row) {
        if (item.row === row && item.flash)
            return item
        for (const child of item.children) {
            const found = findRow(child, row)
            if (found)
                return found
        }
        return null
    }

    function jumpTo(p, row) {
        if (row && isAdvanced(p, row))
            setExpanded(p.id, true)
        showPage(p.id)
        if (!row)
            return
        Qt.callLater(() => {
            const item = findRow(pageColumn, row)
            if (!item)
                return
            const y = item.mapToItem(pageColumn, 0, 0).y
            content.contentY = Math.max(0, Math.min(y - content.height / 2,
                                                    content.contentHeight - content.height))
            item.flash()
            item.forceActiveFocus()
        })
    }

    function runAction(name) {
        switch (name) {
        case "advancedPreferences":
            DialogsProvider.advancedPrefsDialog()
            break
        case "keyboardShortcuts":
            DialogsProvider.keyboardShortcutsDialog()
            break
        case "openConfigDirectory":
            SettingsBridge.openConfigDirectory()
            break
        case "resetAll":
            SettingsBridge.resetAll()
            break
        case "resetHotkeys":
            SettingsBridge.resetHotkeys()
            break
        case "clearHistory":
            recents.item?.clearHistory()
            break
        case "resetPicture":
            SettingsBridge.resetOptions(["hue", "brightness", "contrast", "saturation", "gamma"])
            SettingsBridge.syncFilter("video-filter", "adjust", ["hue", "brightness", "contrast", "saturation", "gamma"])
            break
        }
    }

    onVisibleChanged: {
        if (!visible)
            SettingsBridge.save()
    }

    Component.onCompleted: {
        if (MainCtx.createWindowWithoutRedirectionSurface)
            MainCtx.createWindowWithoutRedirectionSurface(this)
    }

    SettingsPages { id: pages }

    Loader {
        id: recents

        active: MainCtx.mediaLibraryAvailable
        sourceComponent: MLRecentMediaModel { ml: MediaLib }
    }

    // writes the configuration file a moment after the last change, in case
    // VLC does not get to close the dialog
    Timer {
        id: saveTimer

        interval: 2000
        onTriggered: SettingsBridge.save()
    }

    Connections {
        target: SettingsBridge
        function onOptionChanged() { saveTimer.restart() }
    }

    Connections {
        target: DialogsProvider
        function onPrefsDialogVisibleChanged() {
            if (!DialogsProvider.prefsDialogVisible)
                SettingsBridge.refresh()
        }
    }

    Rectangle {
        id: frame

        anchors.fill: parent
        color: t.bgB1
        border.width: t.dp(1)
        border.color: t.dark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.08)

        readonly property ColorContext colorContext: ColorContext {
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }

        focus: true

        Keys.onEscapePressed: (event) => {
            if (searchField.text.length > 0)
                searchField.text = ""
            else
                root.close()
        }

        Rectangle {
            id: header

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: frame.border.width
            height: t.dp(50)
            color: t.bgB2

            DragHandler {
                target: null
                onActiveChanged: {
                    if (active)
                        root.startSystemMove()
                }
            }

            Rectangle {
                id: searchBox

                anchors.left: parent.left
                anchors.leftMargin: t.dp(8)
                anchors.verticalCenter: parent.verticalCenter
                width: t.dp(200)
                height: t.dp(34)
                radius: t.dp(6)
                color: t.bgA5

                Widgets.IconLabel {
                    id: searchIcon

                    anchors.left: parent.left
                    anchors.leftMargin: t.dp(8)
                    anchors.verticalCenter: parent.verticalCenter
                    text: VLCIcons.search
                    color: t.fgA2
                    font.pixelSize: t.dp(24)
                }

                TextInput {
                    id: searchField

                    anchors.left: searchIcon.right
                    anchors.leftMargin: t.dp(10)
                    anchors.right: parent.right
                    anchors.rightMargin: t.dp(8)
                    anchors.verticalCenter: parent.verticalCenter
                    color: t.fgA2
                    selectionColor: t.accentBgBright
                    selectByMouse: true
                    clip: true
                    font.pixelSize: t.fontNormal

                    Accessible.role: Accessible.EditableText
                    Accessible.name: qsTr("Search settings")

                    Keys.onReturnPressed: {
                        if (root.results.length > 0)
                            root.jumpTo(root.results[0].page, root.results[0].rows[0])
                    }

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: searchField.text.length === 0
                        text: qsTr("Search")
                        color: t.fgA4
                        font.pixelSize: t.fontNormal
                    }
                }
            }

            Text {
                anchors.left: searchBox.right
                anchors.leftMargin: t.dp(32)
                anchors.right: closeButton.left
                anchors.rightMargin: t.dp(32)
                anchors.verticalCenter: parent.verticalCenter
                text: root.query.length > 0 ? qsTr("Search Results") : root.page.title
                color: t.fgA1
                font.pixelSize: t.fontLarge
                elide: Text.ElideRight

                Accessible.role: Accessible.Heading
            }

            T.AbstractButton {
                id: closeButton

                anchors.right: parent.right
                anchors.rightMargin: t.dp(14)
                anchors.verticalCenter: parent.verticalCenter
                width: t.dp(32)
                height: t.dp(32)
                focusPolicy: Qt.StrongFocus

                Accessible.name: qsTr("Close")

                onClicked: root.close()

                background: Rectangle {
                    radius: t.dp(4)
                    color: closeButton.hovered ? t.bgA2 : "transparent"
                    border.width: closeButton.visualFocus ? t.dp(1) : 0
                    border.color: t.accentDim
                }

                contentItem: Widgets.IconLabel {
                    text: VLCIcons.close
                    color: closeButton.hovered ? t.fg1 : t.fgA2
                    font.pixelSize: t.dp(24)
                }
            }
        }

        Rectangle {
            id: navigation

            anchors.left: parent.left
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.margins: t.dp(8)
            anchors.leftMargin: t.dp(8) + frame.border.width
            width: t.dp(200)
            radius: t.dp(6)
            color: t.bgA3Glass

            Flickable {
                anchors.fill: parent
                anchors.margins: t.dp(6)
                contentHeight: navColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: navColumn

                    width: parent.width
                    spacing: t.dp(8)

                    Repeater {
                        model: pages.groups

                        delegate: Column {
                            id: group

                            required property int index
                            required property string modelData

                            width: navColumn.width
                            spacing: t.dp(8)

                            Text {
                                width: parent.width
                                height: t.dp(33)
                                leftPadding: t.dp(10)
                                verticalAlignment: Text.AlignVCenter
                                text: group.modelData
                                color: t.fgA3
                                font.pixelSize: t.fontNormal
                            }

                            Repeater {
                                model: pages.pages.filter((p) => p.group === group.index)

                                delegate: T.AbstractButton {
                                    id: category

                                    required property var modelData

                                    readonly property bool current: root.query.length === 0
                                                                    && root.pageId === modelData.id
                                    readonly property bool dimmed: root.query.length > 0
                                                                   && !root.results.some((r) => r.page === modelData)
                                    readonly property string iconName: modelData.icon === "interface"
                                                                       ? "interface_settings" : modelData.icon

                                    width: group.width
                                    height: t.dp(40)
                                    padding: t.dp(4)
                                    focusPolicy: Qt.StrongFocus
                                    opacity: dimmed ? 0.35 : 1
                                    text: modelData.name

                                    Accessible.role: Accessible.PageTab
                                    Accessible.selected: current

                                    onClicked: root.showPage(modelData.id)

                                    background: Rectangle {
                                        radius: t.dp(2)
                                        color: category.current ? t.bgA1 : (category.hovered ? t.bgA2 : "transparent")
                                        border.width: category.visualFocus ? t.dp(1) : 0
                                        border.color: t.accentDim
                                    }

                                    contentItem: Row {
                                        spacing: t.dp(8)

                                        Item {
                                            width: t.dp(32)
                                            height: t.dp(32)
                                            anchors.verticalCenter: parent.verticalCenter

                                            Image {
                                                id: activeIcon

                                                anchors.centerIn: parent
                                                width: t.dp(26)
                                                height: t.dp(26)
                                                sourceSize: Qt.size(width, height)
                                                visible: category.current && status === Image.Ready
                                                source: category.current
                                                        ? SVGColorImage.colorize("qrc:///icons/figma/" + category.modelData.icon + "-active.svg")
                                                                       .accent(t.accent).uri()
                                                        : ""
                                            }

                                            Widgets.IconLabel {
                                                anchors.centerIn: parent
                                                visible: !activeIcon.visible
                                                text: VLCIcons[category.iconName] ?? ""
                                                color: category.current ? t.accent : t.fgA2
                                                font.pixelSize: t.dp(26)
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: category.text
                                            color: category.current ? t.fg1 : t.fgA2
                                            font.pixelSize: t.fontNormal
                                            font.weight: category.current ? Font.DemiBold : Font.Normal
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Flickable {
            id: content

            anchors.left: navigation.right
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.bottomMargin: frame.border.width
            anchors.rightMargin: frame.border.width

            contentHeight: pageColumn.height + t.dp(60)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            Column {
                id: pageColumn

                x: t.dp(24)
                y: t.dp(20)
                width: content.width - t.dp(48)
                spacing: t.dp(20)

                Repeater {
                    model: root.query.length === 0 ? root.page.sections : []

                    delegate: SettingsSection {
                        width: pageColumn.width
                        query: ""
                        onActionRequested: (name) => root.runAction(name)
                    }
                }

                T.AbstractButton {
                    id: advancedToggle

                    readonly property bool open: root.expanded[root.page.id] ?? false

                    visible: root.query.length === 0 && (root.page.advanced ?? []).length > 0
                    width: pageColumn.width
                    height: t.dp(38)
                    focusPolicy: Qt.StrongFocus
                    text: qsTr("Advanced Options")

                    Accessible.role: Accessible.Button

                    onClicked: root.setExpanded(root.page.id, !open)

                    background: Rectangle {
                        radius: t.dp(2)
                        color: advancedToggle.hovered ? t.bgA2 : t.bgA3Glass
                        border.width: advancedToggle.visualFocus ? t.dp(1) : 0
                        border.color: t.accentDim
                    }

                    contentItem: Item {
                        Row {
                            anchors.centerIn: parent
                            spacing: t.dp(10)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: advancedToggle.text
                                color: t.fgA2
                                font.pixelSize: t.fontNormal
                            }

                            Widgets.IconLabel {
                                anchors.verticalCenter: parent.verticalCenter
                                text: advancedToggle.open ? VLCIcons.chevron_down : VLCIcons.chevron_right
                                color: t.fgA2
                                font.pixelSize: t.dp(24)
                            }
                        }
                    }
                }

                Repeater {
                    model: root.query.length === 0 && advancedToggle.open
                           ? (root.page.advanced ?? []).concat([{ rows: [pages.allPreferences] }])
                           : []

                    delegate: SettingsSection {
                        width: pageColumn.width
                        query: ""
                        onActionRequested: (name) => root.runAction(name)
                    }
                }

                // search results, grouped by page
                Repeater {
                    model: root.results

                    delegate: SettingsSection {
                        width: pageColumn.width
                        query: root.query
                        linkPage: modelData.page
                        onActionRequested: (name) => root.runAction(name)
                        onJumpRequested: (row) => root.jumpTo(modelData.page, row)
                    }
                }

                Text {
                    visible: root.query.length > 0 && root.results.length === 0
                    width: pageColumn.width
                    topPadding: t.dp(60)
                    horizontalAlignment: Text.AlignHCenter
                    text: qsTr("No settings match “%1”").arg(root.query)
                    color: t.fgA3
                    font.pixelSize: t.fontNormal
                }
            }
        }
    }
}
