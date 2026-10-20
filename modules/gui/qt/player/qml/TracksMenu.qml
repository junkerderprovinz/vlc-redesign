
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
import QtQuick.Templates as T
import QtQuick.Layouts
import QtQml.Models


import VLC.Style
import VLC.Widgets as Widgets
import VLC.Util

// FIXME: Keyboard navigation needs to be fixed for this Popup.
T.Popup {
    id: root

    enum Tab {
        Video,
        Audio,
        Subtitles
    }

    property int currentTab: TracksMenu.Tab.Subtitles

    // Settings

    width: Math.min(VLCStyle.dp(400, VLCStyle.scale), root.parent.width)

    height: Math.min(VLCStyle.dp(524, VLCStyle.scale), root.parent.height - VLCStyle.dp(40, VLCStyle.scale))

    padding: 0

    onCurrentTabChanged: stackView.pop(null)

    onClosed: stackView.pop(null, T.StackView.Immediate)

    enter: Transition {
        NumberAnimation {
            property: "opacity"
            from: 0.0
            to: 1.0
            duration: VLCStyle.duration_veryShort
        }
    }

    // Children

    // the colour context has no palette until it is attached
    readonly property var _tokens: popupTheme.palette ?? VLCStyle.palette

    readonly property ColorContext colorContext: ColorContext {
        id: popupTheme
        colorSet: ColorContext.Window
    }

    background: Rectangle {
        radius: VLCStyle.dp(10, VLCStyle.scale)
        color: root._tokens.bgB1Glass

        Widgets.RoundedRectangleShadow {
            z: -1
            color: Qt.rgba(0, 0, 0, root._tokens.isDark ? 0.46 : 0.18)
            yOffset: VLCStyle.dp(8, VLCStyle.scale)
            blurRadius: VLCStyle.dp(15, VLCStyle.scale)
        }
    }

    contentItem: Item {
        // popups are not parented to the root, so the context is duplicated for the children
        readonly property ColorContext colorContext: ColorContext {
            id: theme
            colorSet: popupTheme.colorSet
            palette: popupTheme.palette
        }

        clip: true

        Rectangle {
            id: tabBar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            height: VLCStyle.dp(50, VLCStyle.scale)

            radius: VLCStyle.dp(10, VLCStyle.scale)

            color: root._tokens.bgB2

            // square off the bottom corners
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                height: parent.radius
                color: parent.color
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.dp(6, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(6, VLCStyle.scale)

                spacing: 0

                TabButton {
                    tab: TracksMenu.Tab.Video
                    glyph: VLCIcons.video
                    text: qsTr("Video")
                }

                TabButton {
                    tab: TracksMenu.Tab.Audio
                    glyph: VLCIcons.audio
                    text: qsTr("Audio")
                }

                TabButton {
                    tab: TracksMenu.Tab.Subtitles
                    glyph: VLCIcons.subtitles
                    text: qsTr("Subtitles")
                }
            }
        }

        T.StackView {
            id: stackView

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: tabBar.bottom
            anchors.topMargin: VLCStyle.dp(1, VLCStyle.scale)
            anchors.bottom: parent.bottom

            focus: true
            clip: true

            initialItem: TracksListPage {
                tab: root.currentTab
                trackMenuController: trackMenuController
            }

            pushEnter: Transition {
                OpacityAnimator {
                    from: 0
                    to: 1
                    duration: VLCStyle.duration_long
                }
            }
            pushExit: Transition {
                OpacityAnimator {
                    from: 1
                    to: 0
                    duration: VLCStyle.duration_long
                }
            }
            popEnter: Transition {
                OpacityAnimator {
                    from: 0
                    to: 1
                    duration: VLCStyle.duration_long
                }
            }
            popExit: Transition {
                OpacityAnimator {
                    from: 1
                    to: 0
                    duration: VLCStyle.duration_long
                }
            }
        }
    }

    component TabButton : T.TabButton {
        id: tabButton

        required property int tab
        required property string glyph

        readonly property bool selected: root.currentTab === tab

        Layout.fillWidth: true
        Layout.fillHeight: true

        hoverEnabled: true
        focusPolicy: Qt.TabFocus

        Accessible.role: Accessible.PageTab
        Accessible.name: text

        onClicked: root.currentTab = tab

        background: Item {
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: VLCStyle.margin_xsmall
                anchors.rightMargin: VLCStyle.margin_xsmall

                height: VLCStyle.dp(2, VLCStyle.scale)

                visible: tabButton.selected
                color: popupTheme.accent
            }
        }

        contentItem: Item {
            Row {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: VLCStyle.dp(2, VLCStyle.scale)

                spacing: VLCStyle.margin_xsmall

                Widgets.IconLabel {
                    anchors.verticalCenter: parent.verticalCenter

                    text: tabButton.glyph
                    font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
                    color: tabButton.selected ? popupTheme.accent : label.color
                }

                T.Label {
                    id: label

                    anchors.verticalCenter: parent.verticalCenter

                    text: tabButton.text
                    font.pixelSize: VLCStyle.dp(12, VLCStyle.scale)
                    color: (tabButton.selected || tabButton.hovered || tabButton.visualFocus)
                           ? root._tokens.fgA2 : root._tokens.fgA3
                }
            }
        }
    }

    QtObject {
      id: trackMenuController

      signal requestAudioPage()
      signal requestSubtitlePage()
      signal requestPlaybackSpeedPage()
      signal requestBack()
      signal requestClose()

      onRequestBack: {
          stackView.pop()
      }

      onRequestClose: {
          root.close()
      }

      onRequestAudioPage: {
          stackView.push("qrc:///qt/qml/VLC/Player/TracksPageAudio.qml", {"trackMenuController": trackMenuController})
      }

      onRequestSubtitlePage: {
          stackView.push("qrc:///qt/qml/VLC/Player/TracksPageSubtitle.qml", {"trackMenuController": trackMenuController})
      }

      onRequestPlaybackSpeedPage: {
          stackView.push("qrc:///qt/qml/VLC/Player/TracksPageSpeed.qml", {"trackMenuController": trackMenuController})
      }
    }
}
