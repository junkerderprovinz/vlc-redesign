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
import QtQuick.Controls.Basic
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Widgets as Widgets
import VLC.Style
import VLC.Dialogs

ModalDialog {
    id: root

    property int currentIndex: 0

    readonly property list<Component> pages: [
        welcomePage,
        privacyPage,
        appearancePage,
        shortcutsPage
    ]

    readonly property bool lastPage: currentIndex === pages.length - 1

    // the pages are laid out at this size and scaled down to fit small windows
    readonly property real baseWidth: VLCStyle.dp(1090, VLCStyle.scale)
    readonly property real baseHeight: VLCStyle.dp(759, VLCStyle.scale)
    readonly property real fitScale: {
        if (!parent)
            return 1
        const margin = VLCStyle.dp(32, VLCStyle.scale)
        return Math.min(1, (parent.width - margin) / baseWidth, (parent.height - margin) / baseHeight)
    }

    property bool _done: false

    // given the overlay as parent after its creation, so it is centred by hand
    anchors.centerIn: undefined
    x: parent ? (parent.width - width) / 2 : 0
    y: parent ? (parent.height - height) / 2 : 0

    width: baseWidth
    height: baseHeight
    scale: fitScale

    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0
    margins: 0

    header: null
    closeButtonVisible: false

    closePolicy: Popup.CloseOnEscape

    function next() {
        if (lastPage) {
            finish()
            return
        }
        pageLoader.direction = 1
        currentIndex = currentIndex + 1
    }

    function back() {
        if (currentIndex === 0)
            return
        pageLoader.direction = -1
        currentIndex = currentIndex - 1
    }

    function finish() {
        if (_done)
            return
        _done = true
        firstRunController.finish()
        close()
    }

    function skip() {
        if (_done)
            return
        _done = true
        firstRunController.skip()
        close()
    }

    onOpened: nextButton.forceActiveFocus(Qt.OtherFocusReason)

    onRejected: skip()

    // unloads the dialog, which must not happen from its own signal handler
    onClosed: Qt.callLater(() => { DialogsProvider.firstRunDialogVisible = false })

    FirstRunController {
        id: firstRunController

        ctx: MainCtx
    }

    background: Rectangle {
        color: VLCStyle.palette.bgB1
        radius: VLCStyle.dp(14, VLCStyle.scale)

        Widgets.RoundedRectangleShadow {
            yOffset: VLCStyle.dp(4, VLCStyle.scale)
            blurRadius: VLCStyle.dp(11.8, VLCStyle.scale)

            opacity: 0.38

            color: "black"
        }
    }

    contentItem: FocusScope {
        id: content

        readonly property ColorContext colorContext: ColorContext {
            palette: VLCStyle.palette
            colorSet: ColorContext.Window
        }

        clip: true

        Accessible.role: Accessible.Dialog
        Accessible.name: qsTr("Welcome to VLC!")

        Navigation.leftAction: root.back
        Navigation.rightAction: root.next
        Navigation.cancelAction: root.skip

        Keys.priority: Keys.AfterItem
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                event.accepted = true

                const item = root.contentItem.Window.activeFocusItem
                if (item instanceof T.AbstractButton)
                    item.clicked()
                else
                    root.next()
                return
            }

            Navigation.defaultKeyAction(event)
        }

        Loader {
            id: pageLoader

            width: parent.width
            height: parent.height

            focus: true

            sourceComponent: root.pages[root.currentIndex]

            // the side the new page slides in from
            property int direction: 0

            onLoaded: {
                if (direction !== 0)
                    enterAnimation.restart()
            }

            ParallelAnimation {
                id: enterAnimation

                NumberAnimation {
                    target: pageLoader
                    property: "x"
                    from: pageLoader.direction * VLCStyle.dp(24, VLCStyle.scale)
                    to: 0
                    duration: VLCStyle.duration_long
                    easing.type: Easing.OutCubic
                }

                NumberAnimation {
                    target: pageLoader
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: VLCStyle.duration_long
                    easing.type: Easing.OutCubic
                }
            }
        }

        T.AbstractButton {
            id: skipButton

            x: VLCStyle.dp(62, VLCStyle.scale)
            y: VLCStyle.dp(671, VLCStyle.scale)

            implicitWidth: contentItem.implicitWidth
            implicitHeight: VLCStyle.dp(28, VLCStyle.scale)

            // pages with their own footer content have no room for it
            visible: !(pageLoader.item?.hasAside ?? false)

            text: qsTr("Skip")
            font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)

            Navigation.parentItem: content
            Navigation.rightItem: backButton.visible ? backButton : nextButton
            Navigation.upItem: pageLoader

            Keys.priority: Keys.AfterItem
            Keys.onPressed: (event) => Navigation.defaultKeyAction(event)

            onClicked: root.skip()

            contentItem: T.Label {
                text: skipButton.text
                font: skipButton.font
                verticalAlignment: Text.AlignVCenter
                color: (skipButton.hovered || skipButton.visualFocus) ? VLCStyle.palette.fgA2
                                                                      : VLCStyle.palette.fgA3
            }

            background: Rectangle {
                anchors.fill: parent
                anchors.margins: -VLCStyle.dp(4, VLCStyle.scale)

                visible: skipButton.visualFocus
                color: "transparent"
                radius: VLCStyle.dp(6, VLCStyle.scale)
                border.width: VLCStyle.dp(2, VLCStyle.scale)
                border.color: root.colorContext.visualFocus
            }
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: VLCStyle.dp(62, VLCStyle.scale)
            y: VLCStyle.dp(671, VLCStyle.scale)

            spacing: VLCStyle.dp(8, VLCStyle.scale)

            Widgets.DialogButton {
                id: backButton

                visible: root.currentIndex > 0

                height: VLCStyle.dp(32, VLCStyle.scale)
                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)

                text: qsTr("Back")

                Navigation.parentItem: content
                Navigation.leftItem: skipButton.visible ? skipButton : null
                Navigation.rightItem: nextButton
                Navigation.upItem: pageLoader

                onClicked: root.back()
            }

            Widgets.DialogButton {
                id: nextButton

                primary: true

                // filled with the accent, unlike the primary button of other dialogs
                color: colorContext.fg.primary
                backgroundColor: colorContext.bg.primary

                height: VLCStyle.dp(32, VLCStyle.scale)
                font.pixelSize: VLCStyle.dp(16, VLCStyle.scale)

                text: root.lastPage ? qsTr("Finish") : qsTr("Next")

                Navigation.parentItem: content
                Navigation.leftItem: backButton.visible ? backButton
                                                        : (skipButton.visible ? skipButton : null)
                Navigation.upItem: pageLoader

                onClicked: root.next()
            }
        }
    }

    Component {
        id: welcomePage

        FirstRunWelcome {
            controller: firstRunController

            Navigation.parentItem: content
            Navigation.downItem: nextButton
        }
    }

    Component {
        id: privacyPage

        FirstRunPrivacy {
            controller: firstRunController

            Navigation.parentItem: content
            Navigation.downItem: nextButton
        }
    }

    Component {
        id: appearancePage

        FirstRunAppearance {
            controller: firstRunController

            Navigation.parentItem: content
            Navigation.downItem: nextButton
        }
    }

    Component {
        id: shortcutsPage

        FirstRunShortcuts {
            controller: firstRunController

            Navigation.parentItem: content
            Navigation.downItem: nextButton
        }
    }
}
