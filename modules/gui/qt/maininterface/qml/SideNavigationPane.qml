/*****************************************************************************
 * Copyright (C) 2024 VLC authors and VideoLAN
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
import QtQml.Models

import VLC.Style
import VLC.Widgets as Widgets

import VLC.MainInterface
import VLC.Dialogs
import VLC.Util

T.Pane {
    id: root

    // The PageLoader that shows the selected section.
    property Item pageLoader: null

    // Icons only, as a rail beside the player or when the window is narrow.
    property bool compact: false

    // The navigation sits on a rounded card next to the full library, and
    // directly on the window background as a rail.
    property bool card: true

    property alias model: navigationModel

    readonly property real cardPadding: card ? VLCStyle.margin_xsmall : 0

    implicitWidth: compact ? (card ? VLCStyle.dp(66, VLCStyle.scale) : VLCStyle.dp(50, VLCStyle.scale))
                           : VLCStyle.dp(217, VLCStyle.scale)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: cardPadding

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    ColorContext {
        id: viewTheme
        colorSet: ColorContext.View
    }

    Accessible.name: qsTr("Sidebar")

    NavigationModel {
        id: navigationModel
        hasMedialib: MainCtx.mediaLibraryAvailable
    }

    Connections {
        target: History

        // NOTE: handles cases where the path changes not by clicking in the sidebar
        function onViewPathChanged(viewPath) {
            for (let i = 0; i < listView.count; ++i) {
                const rowIndex = navigationModel.index(i, 0)
                const uri = navigationModel.data(rowIndex, NavigationModel.URI)

                if (uri && History.match(viewPath, uri)) {
                    // handle back button
                    listView.currentIndex = i

                    // handle keyboard navigation
                    if (!navigationModel.data(rowIndex, NavigationModel.EXPANDED))
                        navigationModel.setData(rowIndex, true, NavigationModel.EXPANDED)

                    return
                }
            }
        }
    }

    background: Rectangle {
        color: root.card ? viewTheme.bg.primary : theme.bg.secondary
    }

    AddMediaMenu {
        id: addMediaMenu
    }

    NavigationBarContextMenu {
        id: navigationBarContextMenu

        ctx: MainCtx

        model: navigationModel

        onPageRequested: (uri) => root._open(uri)
    }

    function _open(uri) {
        if ((root.pageLoader && root.pageLoader.isDefaulLoadedForPath([...uri])) ||
            (uri.length > 0 && History.exactMatch(History.viewPath, uri))) {
            root.pageLoader?.positionContentAtBeginning()
            return
        }

        History.push(uri)
    }

    contentItem: Rectangle {
        id: contentItemId

        color: root.card ? theme.bg.secondary : "transparent"
        radius: root.card ? VLCStyle.dp(6, VLCStyle.scale) : 0

        readonly property real horizontalPadding: root.compact ? (width - addButton.iconWidth) / 2
                                                               : VLCStyle.margin_normal
        readonly property real verticalPadding: root.card ? VLCStyle.margin_small : VLCStyle.margin_xsmall

        //don't use Layout as top item as items put as children of the Control
        //would be parented (and layouted) to the Layout
        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: contentItemId.horizontalPadding
            anchors.rightMargin: contentItemId.horizontalPadding
            anchors.topMargin: contentItemId.verticalPadding
            anchors.bottomMargin: contentItemId.verticalPadding

            spacing: 0

            Widgets.ListViewExt {
                id: listView

                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, parent.height - addButton.height)

                // Delegates carry the gap below them, so that hidden sub entries take no room.
                readonly property real gap: VLCStyle.dp(14, VLCStyle.scale)

                clip: !fadingEdge.implicitClipping && (height < contentHeight)
                focus: true

                model: navigationModel

                Binding {
                    target: listView.T.ScrollBar.vertical
                    property: "policy"
                    when: listView.T.ScrollBar.vertical?.size > (1.0 - Number.EPSILON)
                    value: T.ScrollBar.AlwaysOff
                }

                colorContext.colorSet: ColorContext.Window

                fadingEdge.backgroundColor: "transparent"

                component DelegateAnimation : NumberAnimation {
                    easing.type: Easing.InOutSine
                    duration: VLCStyle.duration_long
                }

                reuseItems: false // Not relevant here, we disable it because of QTBUG-131106 when transition is involved.

                // As the docs note, `ListView` transitions do not seem to handle height animation. For that reason,
                // we animate the height directly in the delegate (Qt's recommended workaround). Because of this, we
                // do not need to have `addDisplaced` transition here, but we can have `removeDisplaced` here:
                removeDisplaced: Transition {
                    DelegateAnimation { property: "y" }
                }

                onCurrentIndexChanged: {
                    const rowIndex = navigationModel.index(currentIndex, 0)

                    if (rowIndex.valid && !navigationModel.data(rowIndex, NavigationModel.EXPANDED)
                            && History.match(History.viewPath, navigationModel.data(rowIndex, NavigationModel.URI)))
                        navigationModel.setData(rowIndex, true, NavigationModel.EXPANDED)
                }

                property bool readyForAnimations: false

                onModelChanged: {
                    if (!listView.readyForAnimations)
                        Qt.callLater(() => { listView.readyForAnimations = true })
                }

                Navigation.parentItem: root
                Navigation.downItem: addButton

                delegate: SideNavigationDelegate {
                    id: delegate

                    width: ListView.view.contentWidth
                    height: preferredHeight

                    property real preferredHeight: shouldShow ? VLCStyle.heightBar_normal + listView.gap : 0.0

                    bottomInset: listView.gap
                    bottomPadding: listView.gap

                    iconTxt: icon_alias
                    text: title

                    showText: !root.compact
                    indented: (depth > 0)

                    required property string title
                    required property var uri
                    required property int depth
                    // TODO: Qt 6.2 has property `icon` marked final, so we can't override it:
                    required property string icon_alias
                    required property bool expandable
                    required property bool expanded

                    required property int index

                    visible: (height > 0.0)

                    property bool shouldShow: showText || (iconTxt.length > 0)

                    onShouldShowChanged: {
                        if (listView.readyForAnimations)
                            heightBehavior.enabled = true // At this point, it can keep being enabled for good.
                    }

                    Binding on highlighted {
                        when: !!uri && History.match(History.viewPath, uri)
                        value: true
                    }
                    checked: (!showText || !expanded) && highlighted

                    onClicked: {
                        // Without labels the sub entries of the current section are in a menu.
                        if (root.compact && expandable && highlighted)
                            navigationBarContextMenu.popup(index, mapToGlobal(width, 0), !hovered)
                        else
                            root._open(uri)

                        listView.currentIndex = index
                        listView.forceActiveFocus(focusReason)
                    }

                    Behavior on height {
                        id: heightBehavior

                        enabled: false

                        DelegateAnimation {
                            onRunningChanged: {
                                if (running) {
                                    delegate.clip = true
                                } else {
                                    delegate.clip = false
                                }
                            }
                        }
                    }

                    ListView.onAdd: {
                        if (listView.readyForAnimations && delegate.showText) {
                            heightBehavior.enabled = false
                            delegate.height = 0.0
                            heightBehavior.enabled = true
                            delegate.height = Qt.binding(() => delegate.preferredHeight)
                            heightBehavior.enabled = false
                        }
                    }
                }
            }

            SideNavigationDelegate {
                id: addButton

                AccessibleCompat.id: "addItemButton"

                Layout.fillWidth: true
                Layout.preferredHeight: VLCStyle.heightBar_normal

                iconTxt: VLCIcons.add
                text: qsTr("Add item")

                showText: !root.compact

                onClicked: addMediaMenu.show(addButton)

                //SideNavigationDelegate is an ItemDelegate and has NoFocus by default
                focusPolicy: Qt.StrongFocus

                Navigation.parentItem: root
                Navigation.upItem: listView

                Keys.priority: Keys.AfterItem
                Keys.onPressed: (e) => Navigation.defaultKeyAction(e)
                Keys.onReleased: (e) => Navigation.defaultKeyReleaseAction(e)
            }

            Item {
                Layout.fillHeight: true
            }

            Loader {
                id: loaderProgress

                Layout.fillWidth: true

                active: !root.compact && (MainCtx.mediaLibraryAvailable && MainCtx.mediaLibrary.idle === false)
                visible: active

                source: "qrc:///qt/qml/VLC/MediaLibrary/ScanProgressBar.qml"

                onLoaded: {
                    if (item.background) {
                        item.background.opacity = 0.6
                        item.background.radius = Qt.binding(() => VLCStyle.dp(4, VLCStyle.scale))
                    }
                }
            }
        }
    }
}
