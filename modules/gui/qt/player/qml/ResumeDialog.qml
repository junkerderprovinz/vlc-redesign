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
import QtQuick.Templates as T


import VLC.MainInterface
import VLC.Player
import VLC.Style
import VLC.Widgets as Widgets
import VLC.Util

T.Pane {
    id: resumePanel

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: VLCStyle.dp(10, VLCStyle.scale)
    leftPadding: VLCStyle.dp(20, VLCStyle.scale)

    visible: false
    enabled: visible

    focusPolicy: Qt.NoFocus

    Accessible.role: Accessible.Dialog
    Accessible.name: qsTr("Resume dialog")

    signal hidden()

    function showResumePanel ()
    {
        resumePanel.visible = true
        continueBtn.forceActiveFocus()
        resumeTimeout.start()
    }

    function hideResumePanel() {
        resumeTimeout.stop()
        resumePanel.visible = false
        Player.acknowledgeRestoreCallback()
        hidden()
    }

    Timer {
        id: resumeTimeout
        interval: 10000
        onTriggered: {
            resumePanel.visible = false
            hidden()
        }
    }

    Connections {
        target: Player
        function onCanRestorePlaybackChanged() {
            if (Player.canRestorePlayback) {
                showResumePanel()
            } else {
                hideResumePanel()
            }
        }
    }

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    Component.onCompleted: {
        if (Player.canRestorePlayback) {
            showResumePanel()
        }
    }

    Navigation.cancelAction: function() {
        hideResumePanel()
    }

    background: Rectangle {
        radius: VLCStyle.dp(16, VLCStyle.scale)
        color: theme.tokens.bgA3Glass

        Widgets.RoundedRectangleShadow {
            z: -1
            color: theme.shadow
            yOffset: VLCStyle.dp(8, VLCStyle.scale)
            blurRadius: VLCStyle.dp(15, VLCStyle.scale)
        }
    }

    contentItem: RowLayout {
        spacing: VLCStyle.dp(60, VLCStyle.scale)

        T.Label {
            id: label

            Layout.fillWidth: true

            color: theme.tokens.fg2
            font.pixelSize: VLCStyle.fontSize_xlarge
            elide: Text.ElideRight

            text: qsTr("You already watched part of this video.")
        }

        RowLayout {
            spacing: VLCStyle.dp(10, VLCStyle.scale)

            T.Button {
                id: continueBtn

                implicitWidth: implicitContentWidth + leftPadding + rightPadding
                implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

                horizontalPadding: VLCStyle.margin_xsmall

                text: qsTr("Continue Watching")

                AccessibleCompat.id: "resumeContinueButton"

                focus: true

                readonly property ColorContext colorContext: ColorContext {
                    id: accentTheme
                    colorSet: ColorContext.ButtonAccent
                    hovered: continueBtn.hovered
                    focused: continueBtn.visualFocus
                    pressed: continueBtn.down
                }

                background: Rectangle {
                    radius: VLCStyle.dp(6, VLCStyle.scale)
                    color: accentTheme.bg.primary
                }

                contentItem: T.Label {
                    text: continueBtn.text
                    color: accentTheme.fg.primary
                    font.pixelSize: VLCStyle.fontSize_large
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                }

                onClicked: {
                    Player.restorePlaybackPos()
                    hideResumePanel()
                }

                Navigation.parentItem: resumePanel
                Navigation.rightItem: closeBtn
                Keys.priority: Keys.AfterItem
                Keys.onPressed: (event) =>  continueBtn.Navigation.defaultKeyAction(event)
            }

            Widgets.IconToolButton {
                id: closeBtn

                implicitWidth: VLCStyle.dp(44, VLCStyle.scale)
                implicitHeight: VLCStyle.dp(32, VLCStyle.scale)

                radius: VLCStyle.dp(6, VLCStyle.scale)
                backgroundColor: theme.tokens.bgA1

                text: VLCIcons.close
                description: qsTr("Dismiss")

                AccessibleCompat.id: "resumeDismissButton"

                onClicked: hideResumePanel()

                Navigation.parentItem: resumePanel
                Navigation.leftItem: continueBtn
            }
        }
    }
}
