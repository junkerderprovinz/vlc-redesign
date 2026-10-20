
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

    readonly property ColorContext colorContext: ColorContext {
        id: popupTheme
        colorSet: ColorContext.Window
    }

    background: null

    contentItem: Widgets.FloatingPanel {
        // popups are not parented to the root, so the palette is passed on to the children
        colorContext.palette: popupTheme.palette

        currentTab: root.currentTab

        tabs: [
            { text: qsTr("Video"), iconTxt: VLCIcons.video },
            { text: qsTr("Audio"), iconTxt: VLCIcons.audio },
            { text: qsTr("Subtitles"), iconTxt: VLCIcons.subtitles }
        ]

        onTabClicked: (index) => root.currentTab = index

        T.StackView {
            id: stackView

            anchors.fill: parent

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
