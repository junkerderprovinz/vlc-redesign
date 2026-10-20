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

import VLC.Style

// The pages of the settings dialog. Each row names the VLC option it edits;
// rows whose option or module is missing from this build are not shown.
//
// Row fields:
//   type      control: "auto" (from the option type), "toggle", "select",
//             "text", "file", "folder", "range", "color", "action", or one of
//             the composite rows handled by SettingsRow
//   option    VLC configuration name
//   invert    toggle shows the opposite of a boolean option
//   choices   [{ value, text }] replacing the option's own list
//   scale     displayed value = option value / scale
//   when      { option, value } or { option, not } enabling the row
QtObject {
    id: root

    function row(type, option, label, info, extra) {
        const r = { type: type, option: option, label: label, info: info ?? "" }
        if (extra) {
            for (const k in extra)
                r[k] = extra[k]
        }
        return r
    }

    function toggle(option, label, info, extra) { return row("toggle", option, label, info, extra) }
    function select(option, label, info, extra) { return row("select", option, label, info, extra) }
    function text(option, label, info, extra) { return row("text", option, label, info, extra) }
    function range(option, label, info, extra) { return row("range", option, label, info, extra) }
    function filter(chain, module, label, info, extra) {
        return row("filter", chain, label, info, Object.assign({ module: module }, extra ?? {}))
    }
    function action(name, label, button, info, extra) {
        return row("action", "", label, info, Object.assign({ run: name, button: button }, extra ?? {}))
    }

    function choice(value, text) { return { value: value, text: text } }

    readonly property var allPreferences: action("advancedPreferences", qsTr("All preferences"), qsTr("Open"),
                                                 qsTr("Every option of VLC and its modules, in the classic preferences window."))

    readonly property var groups: [qsTr("App"), qsTr("Media"), qsTr("System")]

    readonly property var pages: [
        {
            id: "general",
            name: qsTr("General"),
            title: qsTr("Global Settings"),
            group: 0,
            icon: "preferences",
            sections: [
                {
                    title: qsTr("Appearance"),
                    rows: [
                        row("theme", "", qsTr("Theme")),
                        row("accent", "qt-accent-color", qsTr("Accent color"))
                    ]
                },
                {
                    title: qsTr("Startup"),
                    rows: [
                        toggle("qt-error-dialogs", qsTr("Show confirmation and error dialogs"),
                               qsTr("Reports errors in a dialog.")),
                        toggle("qt-updates-notif", qsTr("Check for updates automatically"),
                               qsTr("Looks for a new version of VLC every few days."))
                    ]
                },
                {
                    title: qsTr("Diagnostics"),
                    rows: [
                        toggle("file-logging", qsTr("Save a log"),
                               qsTr("Writes what VLC does to a file you can share when reporting a bug.")),
                        row("file", "logfile", qsTr("Log file"), qsTr("Where the log is saved."),
                            { save: true, when: { option: "file-logging", value: true } }),
                        select("log-verbose", qsTr("Log details"), qsTr("How much the log records."),
                               { when: { option: "file-logging", value: true } })
                    ]
                }
            ],
            advanced: [
                {
                    rows: [
                        select("logmode", qsTr("Log format"), qsTr("The file format of the saved log.")),
                        toggle("stats", qsTr("Collect playback statistics"),
                               qsTr("Counts dropped frames and bitrates for the media information window.")),
                        action("openConfigDirectory", qsTr("Open configurations folder"), qsTr("Open"),
                               qsTr("Shows the folder where VLC keeps its settings."), { done: qsTr("Opened") }),
                        action("resetAll", qsTr("Reset all settings"), qsTr("Reset"),
                               qsTr("Puts every setting back to its default value."),
                               { danger: true, confirm: qsTr("Confirm") })
                    ]
                },
                {
                    title: qsTr("Developer Options"),
                    rows: [
                        toggle("syslog", qsTr("Write to the system log"),
                               qsTr("Sends VLC messages to the log of your operating system.")),
                        toggle("syslog-debug", qsTr("Include debug messages in the system log"),
                               qsTr("Adds detailed debug output to the system log."),
                               { when: { option: "syslog", value: true } }),
                        text("syslog-ident", qsTr("System log identity"), qsTr("The name VLC uses in the system log."),
                             { compact: true, when: { option: "syslog", value: true } }),
                        select("syslog-facility", qsTr("System log facility"), qsTr("The system log category VLC writes to."),
                               { when: { option: "syslog", value: true } })
                    ]
                }
            ]
        },
        {
            id: "interface",
            name: qsTr("Interface"),
            title: qsTr("Interface Settings"),
            group: 0,
            icon: "interface",
            sections: [
                {
                    title: qsTr("Skin"),
                    rows: [
                        row("skin", "intf", qsTr("Use a custom skin"), qsTr("Replaces the standard look with a skin file. Takes effect after a restart.")),
                        row("file", "skins2-last", qsTr("Skin file"), qsTr("The skin to load, a .vlt or .xml file."),
                            { whenSkin: true })
                    ]
                },
                {
                    title: qsTr("Window"),
                    rows: [
                        toggle("embedded-video", qsTr("Play video inside main window"),
                               qsTr("Shows video in the main window instead of a separate one.")),
                        select("qt-video-autoresize", qsTr("Resize window to fit video"),
                               qsTr("Changes the window size to match the size of the video."),
                               { choices: [choice(false, qsTr("Never")), choice(true, qsTr("Always"))] }),
                        toggle("video-on-top", qsTr("Keep window above other windows"),
                               qsTr("Keeps the video window in front even when another app is active.")),
                        toggle("qt-titlebar", qsTr("Show window decorations"),
                               qsTr("Shows the title bar and border of the operating system.")),
                        toggle("qt-name-in-title", qsTr("Show the file name in the title bar"),
                               qsTr("Uses the name of the playing file as the window title.")),
                        row("screen", "qt-fullscreen-screennumber", qsTr("Open fullscreen on"),
                            qsTr("The screen that fullscreen video appears on."))
                    ]
                },
                {
                    title: qsTr("Playback Controls"),
                    rows: [
                        toggle("qt-minimal-view", qsTr("Start in compact mode"),
                               qsTr("Opens VLC with a smaller control bar.")),
                        select("qt-pin-controls", qsTr("Auto-hide the controls"),
                               qsTr("Hides the controls over the video when the mouse stops moving."),
                               { choices: [choice(true, qsTr("Never")), choice(false, qsTr("Always"))] }),
                        range("mouse-hide-timeout", qsTr("Hide after"), "",
                              { from: 0, to: 10, step: 0.5, scale: 1000, unit: qsTr("s"),
                                labels: [qsTr("0 s"), qsTr("5 s"), qsTr("10 s")],
                                when: { option: "qt-pin-controls", value: false } }),
                        toggle("qt-fs-controller", qsTr("Show controls in fullscreen"),
                               qsTr("Shows the control bar when you move the mouse in fullscreen."))
                    ]
                },
                {
                    title: qsTr("Notifications and System Tray"),
                    rows: [
                        toggle("qt-system-tray", qsTr("Show a system tray icon"),
                               qsTr("Keeps a VLC icon in the notification area.")),
                        toggle("qt-start-minimized", qsTr("Start minimized to the tray"),
                               qsTr("Opens VLC as a tray icon without a window."),
                               { when: { option: "qt-system-tray", value: true } }),
                        select("qt-notification", qsTr("Show a popup when the track changes"),
                               qsTr("Shows the title of the next track in a small notification."))
                    ]
                },
                {
                    title: qsTr("Playlist"),
                    rows: [
                        toggle("playlist-tree", qsTr("Show the playlist as a tree"),
                               qsTr("Groups playlist items by folder and album."))
                    ]
                }
            ],
            advanced: [
                {
                    rows: [
                        range("qt-opacity", qsTr("Window opacity"), "",
                              { from: 10, to: 100, step: 10, scale: 0.01, unit: "%", labels: ["10%", "100%"] }),
                        toggle("qt-pause-minimized", qsTr("Pause video when window is minimized")),
                        select("qt-auto-raise", qsTr("Bring VLC to the front when playback starts"),
                               qsTr("Moves the window in front of other apps when this kind of media starts.")),
                        toggle("qt-embedded-open", qsTr("Show the file browser inside the open dialog")),
                        toggle("qt-icon-change", qsTr("Allow the app icon to change")),
                        range("qt-fs-opacity", qsTr("Fullscreen controls opacity"), "",
                              { from: 10, to: 100, step: 10, scale: 0.01, unit: "%", labels: ["10%", "100%"] }),
                        text("qt-fs-sensitivity", qsTr("Fullscreen controls sensitivity"),
                             qsTr("How far the mouse has to move before the controls show up."),
                             { unit: qsTr("px") })
                    ]
                }
            ]
        },
        {
            id: "privacy",
            name: qsTr("Privacy"),
            title: qsTr("Privacy Settings"),
            group: 0,
            icon: "privacy",
            sections: [
                {
                    title: qsTr("History"),
                    rows: [
                        toggle("save-recentplay", qsTr("Save recently played items"),
                               qsTr("Lists what you played lately on the home page.")),
                        action("clearHistory", qsTr("Clear history now"), qsTr("Clear"),
                               qsTr("Forgets recently played items and saved positions."),
                               { done: qsTr("Cleared"), needsMediaLibrary: true })
                    ]
                },
                {
                    title: qsTr("Network"),
                    rows: [
                        toggle("metadata-network-access", qsTr("Fetch titles and cover art from the internet"),
                               qsTr("Looks up missing titles and artwork online.")),
                        row("intf", "audioscrobbler", qsTr("Submit played tracks to last.fm"),
                            qsTr("Shares the music you play with your last.fm profile.")),
                        text("lastfm-username", qsTr("Last.fm username"), qsTr("The account your tracks are submitted to."),
                             { whenIntf: "audioscrobbler" }),
                        text("lastfm-password", qsTr("Last.fm password"), qsTr("The password of that account."),
                             { whenIntf: "audioscrobbler" }),
                        text("scrobbler-url", qsTr("Last.fm submission URL"),
                             qsTr("Only change this to submit to a compatible service."),
                             { whenIntf: "audioscrobbler" })
                    ]
                }
            ]
        },
        {
            id: "controls",
            name: qsTr("Controls"),
            title: qsTr("Mouse, Keyboard & Remote Controls"),
            group: 0,
            icon: "hotkeys",
            sections: [
                {
                    title: qsTr("Keyboard Shortcuts"),
                    rows: [
                        action("advancedPreferences", qsTr("Defaults"), qsTr("Edit Keyboard Shortcuts"), "", { wide: true }),
                        action("resetHotkeys", qsTr("Reset all shortcuts"), qsTr("Reset"), "",
                               { wide: true, confirm: qsTr("Confirm"), done: qsTr("Done") })
                    ]
                },
                {
                    title: qsTr("Skip Amounts"),
                    rows: [
                        text("extrashort-jump-size", qsTr("Very short skip"), "", { unit: qsTr("s") }),
                        text("short-jump-size", qsTr("Short skip"), "", { unit: qsTr("s") }),
                        text("medium-jump-size", qsTr("Medium skip"), "", { unit: qsTr("s") }),
                        text("long-jump-size", qsTr("Long skip"), "", { unit: qsTr("s") })
                    ]
                },
                {
                    title: qsTr("Mouse"),
                    rows: [
                        select("hotkeys-y-wheel-mode", qsTr("Scroll wheel")),
                        select("hotkeys-x-wheel-mode", qsTr("Horizontal scroll"))
                    ]
                },
                {
                    title: qsTr("Remotes"),
                    rows: [
                        row("intf", "http", qsTr("Web remote control"),
                            qsTr("Lets a browser on another device control VLC. Takes effect after a restart."),
                            { module: "lua" }),
                        text("http-port", qsTr("Port"), "", { whenIntf: "http" }),
                        text("http-password", qsTr("Password"), qsTr("The web remote only works with a password."),
                             { whenIntf: "http" })
                    ]
                }
            ],
            advanced: [
                {
                    title: qsTr("Common Shortcuts"),
                    rows: [
                        row("shortcuts", "", "", "", {
                            keys: [
                                { option: "key-play-pause", text: qsTr("Play / Pause") },
                                { option: "key-toggle-fullscreen", text: qsTr("Toggle fullscreen") },
                                { option: "key-leave-fullscreen", text: qsTr("Leave fullscreen") },
                                { option: "key-vol-mute", text: qsTr("Mute") },
                                { option: "key-vol-up", text: qsTr("Volume up") },
                                { option: "key-vol-down", text: qsTr("Volume down") },
                                { option: "key-jump+extrashort", text: qsTr("Very short skip forward") },
                                { option: "key-jump+short", text: qsTr("Short skip forward") },
                                { option: "key-jump+medium", text: qsTr("Medium skip forward") },
                                { option: "key-next", text: qsTr("Next item") },
                                { option: "key-prev", text: qsTr("Previous item") },
                                { option: "key-faster", text: qsTr("Faster") },
                                { option: "key-slower", text: qsTr("Slower") },
                                { option: "key-snapshot", text: qsTr("Take a snapshot") }
                            ]
                        })
                    ]
                }
            ]
        },
        {
            id: "playback",
            name: qsTr("Playback"),
            title: qsTr("Playback Preferences"),
            group: 1,
            icon: "playback",
            sections: [
                {
                    title: qsTr("Startup"),
                    rows: [
                        select("restore-playback-pos", qsTr("Continue where you left off"),
                               qsTr("Starts a file you watched before at the point where you stopped.")),
                        toggle("playlist-autostart", qsTr("Start playing as soon as a file opens"),
                               qsTr("Plays a file right away instead of waiting for you to press play.")),
                        range("rate", qsTr("Default playback speed"), "",
                              { from: 0.25, to: 2, step: 0.25, unit: "×",
                                labels: ["0.25", "0.5", "0.75", "1", "1.25", "1.5", "1.75", "2"] }),
                        toggle("playlist-cork", qsTr("Pause when another app uses audio"),
                               qsTr("Pauses during calls and other apps that play sound."))
                    ]
                },
                {
                    title: qsTr("Tracks"),
                    rows: [
                        select("preferred-resolution", qsTr("Preferred video quality"),
                               qsTr("The quality VLC picks for streams that offer several.")),
                        text("menu-language", qsTr("Preferred menu language"),
                             qsTr("The language VLC picks for DVD and Blu-ray menus, as a comma separated list of language codes.")),
                        text("audio-track", qsTr("Default audio track"),
                             qsTr("The number of the audio track to play first, counting from 0. -1 lets VLC choose.")),
                        text("sub-track", qsTr("Default subtitle track"),
                             qsTr("The number of the subtitle track to show first, counting from 0. -1 lets VLC choose."))
                    ]
                },
                {
                    title: qsTr("Order"),
                    rows: [
                        row("repeat", "repeat", qsTr("Repeat"),
                            qsTr("Plays the current item or the whole list again when it ends.")),
                        toggle("random", qsTr("Shuffle"), qsTr("Plays the items of a list in random order.")),
                        toggle("play-and-stop", qsTr("Stop after each item"),
                               qsTr("Stops instead of moving on to the next item.")),
                        select("play-and-exit", qsTr("When playback finishes"), qsTr("What VLC does when the last item ends."),
                               { choices: [choice(false, qsTr("Stop")), choice(true, qsTr("Quit VLC"))] })
                    ]
                },
                {
                    title: qsTr("Seeking"),
                    rows: [
                        toggle("input-fast-seek", qsTr("Seek precisely"),
                               qsTr("Jumps to the exact frame, which can take a little longer."), { invert: true })
                    ]
                },
                {
                    title: qsTr("Files & Discs"),
                    rows: [
                        text("dvd", qsTr("Default optical drive"), qsTr("The drive VLC opens when you play a disc.")),
                        select("avi-index", qsTr("Repair damaged AVI files"),
                               qsTr("Rebuilds a broken AVI index so you can seek in the file.")),
                        toggle("mkv-preload-local-dir", qsTr("Load matching .mkv files from the same folder"),
                               qsTr("Opens the other parts of a split MKV file automatically."))
                    ]
                }
            ],
            advanced: [
                {
                    rows: [
                        row("folder", "input-timeshift-path", qsTr("Time-shift buffer folder"),
                            qsTr("Where VLC stores live streams so you can pause and rewind them."), { compact: true })
                    ]
                }
            ]
        },
        {
            id: "video",
            name: qsTr("Video"),
            title: qsTr("Video Defaults"),
            group: 1,
            icon: "video",
            sections: [
                {
                    title: qsTr("Output"),
                    rows: [
                        toggle("video", qsTr("Enable video"), qsTr("Turn this off to play only the sound of video files.")),
                        toggle("fullscreen", qsTr("Start videos in fullscreen"), qsTr("Opens every video in fullscreen.")),
                        select("disable-screensaver", qsTr("Stop the screensaver during playback"),
                               qsTr("Keeps the screen awake while a video plays.")),
                        toggle("video-wallpaper", qsTr("Play video as desktop wallpaper"),
                               qsTr("Shows the video behind your desktop icons."))
                    ]
                },
                {
                    title: qsTr("Picture"),
                    rows: [
                        range("hue", qsTr("Hue"), "", { from: -180, to: 180, step: 1, module: "adjust", picture: true }),
                        range("brightness", qsTr("Brightness"), "", { from: 0, to: 2, step: 0.01, module: "adjust", picture: true }),
                        range("contrast", qsTr("Contrast"), "", { from: 0, to: 2, step: 0.01, module: "adjust", picture: true }),
                        range("saturation", qsTr("Saturation"), "", { from: 0, to: 3, step: 0.01, module: "adjust", picture: true }),
                        range("gamma", qsTr("Gamma"), "", { from: 0.01, to: 10, step: 0.01, module: "adjust", picture: true }),
                        action("resetPicture", qsTr("Reset picture"), qsTr("Reset"), "", { module: "adjust" })
                    ]
                },
                {
                    title: qsTr("Deinterlacing"),
                    rows: [
                        select("deinterlace", qsTr("Deinterlacing"),
                               qsTr("Removes the comb lines that interlaced video shows on a computer screen.")),
                        select("deinterlace-mode", qsTr("Method"), qsTr("The filter used to deinterlace."))
                    ]
                },
                {
                    title: qsTr("Framing"),
                    rows: [
                        select("aspect-ratio", qsTr("Aspect ratio"), qsTr("The shape VLC gives the picture."), {
                            choices: [choice("", qsTr("Automatic")), choice("1:1", "1:1"), choice("4:3", "4:3"),
                                      choice("5:4", "5:4"), choice("16:9", "16:9"), choice("16:10", "16:10"),
                                      choice("221:100", "2.21:1"), choice("235:100", "2.35:1"), choice("239:100", "2.39:1")]
                        }),
                        select("crop", qsTr("Crop"), qsTr("Cuts the picture to this shape, for example to remove black bars."), {
                            choices: [choice("", qsTr("None")), choice("1:1", "1:1"), choice("4:3", "4:3"),
                                      choice("5:3", "5:3"), choice("5:4", "5:4"), choice("16:9", "16:9"),
                                      choice("16:10", "16:10"), choice("185:100", "1.85:1"), choice("221:100", "2.21:1"),
                                      choice("235:100", "2.35:1"), choice("239:100", "2.39:1")]
                        }),
                        toggle("autoscale", qsTr("Scale video to the window"), qsTr("Grows or shrinks the video to fill the window.")),
                        select("zoom", qsTr("Zoom"), qsTr("The size of the video relative to its own resolution."), {
                            choices: [choice(0.25, "1:4"), choice(0.5, "1:2"), choice(1, "1:1"), choice(2, "2:1")],
                            when: { option: "autoscale", value: false }
                        }),
                        select("align", qsTr("Position in the window"),
                               qsTr("Where the video sits when it does not fill the window."))
                    ]
                },
                {
                    title: qsTr("Snapshots"),
                    rows: [
                        row("folder", "snapshot-path", qsTr("Save to"), qsTr("The folder for snapshots."), { compact: true }),
                        text("snapshot-prefix", qsTr("File name prefix"), qsTr("Text at the start of every snapshot file name."),
                             { compact: true }),
                        select("snapshot-format", qsTr("Format"), qsTr("The image format of snapshots.")),
                        toggle("snapshot-sequential", qsTr("Number files sequentially"),
                               qsTr("Adds 1, 2, 3 to file names instead of the time.")),
                        toggle("snapshot-preview", qsTr("Show a preview after capture"),
                               qsTr("Shows the snapshot in the corner for a moment."))
                    ]
                }
            ],
            advanced: [
                {
                    rows: [
                        text("custom-aspect-ratios", qsTr("Custom aspect ratios"),
                             qsTr("Extra ratios for the aspect ratio menu, separated by commas."),
                             { compact: true, placeholder: "18:9,21:9" }),
                        text("custom-crop-ratios", qsTr("Custom crop ratios"),
                             qsTr("Extra ratios for the crop menu, separated by commas."),
                             { compact: true, placeholder: "18:9,21:9" }),
                        text("monitor-par", qsTr("Monitor pixel aspect ratio"),
                             qsTr("Only change this if your screen has pixels that are not square."),
                             { compact: true, placeholder: "1:1" })
                    ]
                }
            ]
        },
        {
            id: "audio",
            name: qsTr("Audio"),
            title: qsTr("Audio Defaults"),
            group: 1,
            icon: "audio",
            sections: [
                {
                    title: qsTr("Output"),
                    rows: [
                        toggle("audio", qsTr("Enable audio"), qsTr("Turn this off to play videos without sound.")),
                        row("device", "", qsTr("Output device"), qsTr("Where the sound plays."))
                    ]
                },
                {
                    title: qsTr("Volume"),
                    rows: [
                        range("qt-max-volume", qsTr("Maximum volume"), "",
                              { from: 100, to: 300, step: 25, unit: "%", labels: ["100%", "200%", "300%"] }),
                        row("startVolume", "volume-save", qsTr("Startup volume"), qsTr("The volume VLC starts with.")),
                        text("volume-step", qsTr("Volume step"),
                             qsTr("How much the volume changes per key press or scroll step."),
                             { scale: 2.56, unit: "%" })
                    ]
                },
                {
                    title: qsTr("Loudness"),
                    rows: [
                        filter("audio-filter", "normvol", qsTr("Normalize loudness"),
                               qsTr("Evens out the volume between quiet and loud files.")),
                        text("norm-max-level", qsTr("Target level"), qsTr("How loud normalized audio gets."),
                             { whenModule: ["audio-filter", "normvol"] }),
                        select("audio-replay-gain-mode", qsTr("Replay gain"),
                               qsTr("Uses the loudness stored in music files to even out the volume.")),
                        text("audio-replay-gain-preamp", qsTr("Replay gain preamp"),
                             qsTr("Extra gain for files with replay gain information."),
                             { unit: qsTr("dB"), when: { option: "audio-replay-gain-mode", not: "none" } })
                    ]
                },
                {
                    title: qsTr("Effects"),
                    rows: [
                        filter("audio-filter", "equalizer", qsTr("Equalizer"), qsTr("Turns the equalizer below on or off.")),
                        row("eqPreset", "equalizer-preset", qsTr("Equalizer preset"),
                            qsTr("Sets every band at once for a kind of music.")),
                        row("equalizer", "equalizer-bands", ""),
                        toggle("equalizer-2pass", qsTr("Two-pass"), qsTr("Runs the equalizer twice for a stronger effect.")),
                        filter("audio-filter", "spatializer", qsTr("Spatial audio"),
                               qsTr("Makes the sound seem to come from around you.")),
                        filter("audio-filter", "stereo_widen", qsTr("Stereo widening"),
                               qsTr("Spreads the left and right channels further apart.")),
                        filter("audio-filter", "compressor", qsTr("Compressor"),
                               qsTr("Brings loud and quiet parts closer together.")),
                        text("pitch-shift", qsTr("Pitch shift"), qsTr("Raises or lowers the pitch in semitones."),
                             { compact: true, module: "scaletempo_pitch", pitch: true }),
                        filter("audio-filter", "chorus_flanger", qsTr("Chorus/flanger"), qsTr("Adds a sweeping, doubled sound.")),
                        filter("audio-filter", "karaoke", qsTr("Karaoke"), qsTr("Removes the voice from many songs."))
                    ]
                },
                {
                    title: qsTr("Tracks"),
                    rows: [
                        text("audio-language", qsTr("Preferred audio language"),
                             qsTr("The language VLC picks when a file has several audio tracks, as a comma separated list of language codes.")),
                        text("audio-desync", qsTr("Audio delay"), qsTr("Shifts the sound to match the picture."),
                             { unit: qsTr("ms") })
                    ]
                },
                {
                    title: qsTr("Visualization"),
                    rows: [
                        row("visualizer", "audio-visual", qsTr("Visualizer"), qsTr("An animation that plays along with music."))
                    ]
                }
            ],
            advanced: [
                {
                    rows: [
                        select("aout", qsTr("Output module"), qsTr("The audio system VLC plays through.")),
                        toggle("spdif", qsTr("Pass compressed audio to the receiver"),
                               qsTr("Lets an AV receiver decode Dolby and DTS sound itself.")),
                        select("force-dolby-surround", qsTr("Detect Dolby Surround"),
                               qsTr("Decodes surround sound hidden in stereo tracks.")),
                        select("role", qsTr("Media role"), qsTr("Tells the operating system what kind of sound VLC plays."))
                    ]
                }
            ]
        },
        {
            id: "subtitles",
            name: qsTr("Subtitles"),
            title: qsTr("Subtitle Defaults"),
            group: 1,
            icon: "subtitles",
            sections: [
                {
                    title: qsTr("Tracks & Languages"),
                    rows: [
                        toggle("spu", qsTr("Enable subtitles"), qsTr("Shows subtitles when a file has them.")),
                        text("sub-language", qsTr("Preferred language"),
                             qsTr("The language VLC picks when a file has several subtitle tracks, as a comma separated list of language codes.")),
                        select("subsdec-encoding", qsTr("Text encoding"), qsTr("Change this if subtitle characters show up garbled."))
                    ]
                },
                {
                    title: qsTr("Loading Subtitles"),
                    rows: [
                        toggle("sub-autodetect-file", qsTr("Load subtitle files automatically"),
                               qsTr("Looks for subtitle files next to the video.")),
                        select("sub-autodetect-fuzzy", qsTr("File name matching"),
                               qsTr("How closely a subtitle file name must match the video name."), {
                                   choices: [choice(0, qsTr("Off")), choice(1, qsTr("Any title")),
                                             choice(2, qsTr("Contains title")), choice(3, qsTr("Title with extra characters")),
                                             choice(4, qsTr("Exact title match"))],
                                   when: { option: "sub-autodetect-file", value: true }
                               })
                    ]
                },
                {
                    title: qsTr("Appearance"),
                    rows: [
                        text("freetype-font", qsTr("Font"), qsTr("The font for subtitle text.")),
                        select("sub-text-scale", qsTr("Font size"), qsTr("The size of subtitle text relative to the video."), {
                            choices: [choice(50, qsTr("Smaller")), choice(75, qsTr("Small")), choice(100, qsTr("Normal")),
                                      choice(150, qsTr("Large")), choice(200, qsTr("Larger"))]
                        }),
                        toggle("freetype-bold", qsTr("Bold")),
                        row("color", "freetype-color", qsTr("Text color")),
                        range("freetype-opacity", qsTr("Text opacity"), "",
                              { from: 0, to: 100, step: 1, scale: 2.55, unit: "%", labels: ["0%", "50%", "100%"] }),
                        select("freetype-outline-thickness", qsTr("Outline thickness")),
                        row("color", "freetype-outline-color", qsTr("Outline color"),
                            "", { when: { option: "freetype-outline-thickness", not: 0 } }),
                        row("opacityToggle", "freetype-shadow-opacity", qsTr("Shadow")),
                        row("color", "freetype-shadow-color", qsTr("Shadow color"),
                            "", { when: { option: "freetype-shadow-opacity", not: 0 } }),
                        select("freetype-shadow-distance", qsTr("Shadow distance"), "", {
                            choices: [choice(0.03, qsTr("Small")), choice(0.06, qsTr("Medium")), choice(0.12, qsTr("Large"))],
                            when: { option: "freetype-shadow-opacity", not: 0 }
                        }),
                        row("opacitySelect", "freetype-background-opacity", qsTr("Background")),
                        row("color", "freetype-background-color", qsTr("Background color"),
                            "", { when: { option: "freetype-background-opacity", not: 0 } }),
                        range("freetype-background-opacity", qsTr("Background opacity"), "",
                              { from: 0, to: 100, step: 1, scale: 2.55, unit: "%", labels: ["0%", "50%", "100%"] }),
                        text("sub-margin", qsTr("Vertical position"),
                             qsTr("Distance of the subtitles from the bottom of the video."), { unit: qsTr("px") })
                    ]
                },
                {
                    title: qsTr("Timing"),
                    rows: [
                        range("sub-delay", qsTr("Subtitle delay"), "",
                              { from: -5, to: 5, step: 0.1, scale: 10, unit: qsTr("s"),
                                labels: [qsTr("-5 s"), qsTr("0 s"), qsTr("+5 s")] })
                    ]
                },
                {
                    title: qsTr("On-Screen Messages"),
                    rows: [
                        toggle("osd", qsTr("Show feedback for shortcuts"),
                               qsTr("Shows the new volume, speed or position when you press a shortcut.")),
                        toggle("video-title-show", qsTr("Show filename when a video starts"),
                               qsTr("Shows the file name over the video for a moment.")),
                        range("video-title-timeout", qsTr("Show filename for"), "",
                              { from: 1, to: 10, step: 0.5, scale: 1000, unit: qsTr("s"),
                                labels: [qsTr("1 s"), qsTr("10 s")],
                                when: { option: "video-title-show", value: true } })
                    ]
                }
            ],
            advanced: [
                {
                    rows: [
                        text("sub-autodetect-path", qsTr("Load subtitles from these folders"),
                             qsTr("Extra folders to search for subtitle files, separated by commas.")),
                        text("freetype-shadow-angle", qsTr("Shadow angle"), qsTr("The direction of the shadow in degrees."),
                             { unit: "°" }),
                        select("freetype-text-direction", qsTr("Text direction"), qsTr("The reading direction of subtitle text.")),
                        text("freetype-monofont", qsTr("Monospace font"),
                             qsTr("The font for subtitles that need even character widths."))
                    ]
                }
            ]
        },
        {
            id: "library",
            name: qsTr("Library"),
            title: qsTr("Playlists, Folders & Files"),
            group: 1,
            icon: "folder",
            sections: [
                {
                    title: qsTr("Opening Files"),
                    rows: [
                        toggle("one-instance", qsTr("Only allow one VLC window"),
                               qsTr("Opens new files in the window that is already running.")),
                        toggle("one-instance-when-started-from-file", qsTr("Apply to files opened from the file manager"),
                               qsTr("Also reuses the window for files you double click."),
                               { when: { option: "one-instance", value: true } }),
                        toggle("playlist-enqueue", qsTr("Add to the playlist instead of replacing it"),
                               qsTr("Queues new files behind what is playing."),
                               { when: { option: "one-instance", value: true } }),
                        select("recursive", qsTr("When opening a folder"), qsTr("Whether files in subfolders are added too.")),
                        toggle("show-hiddenfiles", qsTr("Show hidden files"),
                               qsTr("Lists files and folders whose name starts with a dot."))
                    ]
                },
                {
                    title: qsTr("Metadata & Artwork"),
                    rows: [
                        select("metadata-network-access", qsTr("Fetch titles and artwork"),
                               qsTr("Where VLC gets titles and cover art for your media."),
                               { choices: [choice(false, qsTr("From the file only")),
                                           choice(true, qsTr("From the file and the internet"))] }),
                        toggle("media-library", qsTr("Use the media library"),
                               qsTr("Indexes your folders so videos and music show up on the home page. Takes effect after a restart."))
                    ]
                }
            ],
            advanced: [
                {
                    rows: [
                        text("ignore-filetypes", qsTr("Ignored file extensions"),
                             qsTr("File types skipped when a folder is opened, separated by commas."))
                    ]
                }
            ]
        },
        {
            id: "network",
            name: qsTr("Network"),
            title: qsTr("Network Connections & Security"),
            group: 2,
            icon: "streaming",
            sections: [
                {
                    title: qsTr("Buffering"),
                    rows: [
                        row("caching", "file-caching", qsTr("Buffering"),
                            qsTr("How much VLC loads ahead. Choose Custom to set each source below.")),
                        text("file-caching", qsTr("Local files"), "", { unit: qsTr("ms"), whenCustomCaching: true }),
                        text("disc-caching", qsTr("Discs"), "", { unit: qsTr("ms"), whenCustomCaching: true }),
                        text("network-caching", qsTr("Network streams"), "", { unit: qsTr("ms"), whenCustomCaching: true }),
                        text("live-caching", qsTr("Live capture"), "", { unit: qsTr("ms"), whenCustomCaching: true })
                    ]
                },
                {
                    title: qsTr("Proxy"),
                    rows: [
                        text("http-proxy", qsTr("HTTP proxy"), qsTr("The proxy for web streams, as http://host:port/."),
                             { placeholder: qsTr("System proxy") }),
                        text("http-proxy-pwd", qsTr("HTTP proxy password"), qsTr("Only needed if the proxy asks for one."))
                    ]
                },
                {
                    title: qsTr("Security"),
                    rows: [
                        toggle("gnutls-system-trust", qsTr("Verify certificates against the system trust store"),
                               qsTr("Trusts the certificates your system trusts for secure streams.")),
                        select("gnutls-priorities", qsTr("Cipher preference"),
                               qsTr("Stricter settings refuse older encryption that some servers still use."))
                    ]
                }
            ],
            advanced: [
                {
                    rows: [
                        text("ipv4-timeout", qsTr("Network timeout"), qsTr("How long VLC waits for a server before giving up."),
                             { unit: qsTr("ms") })
                    ]
                }
            ]
        },
        {
            id: "performance",
            name: qsTr("Performance"),
            title: qsTr("Performance Settings"),
            group: 2,
            icon: "preferences",
            sections: [
                {
                    title: qsTr("Decoding"),
                    rows: [
                        select("dec-dev", qsTr("Hardware-accelerated decoding"),
                               qsTr("Lets the graphics card decode video to save power.")),
                        range("postproc-q", qsTr("Video post-processing"),
                              qsTr("Smooths out blocky compression artefacts. Applies when the post-processing filter is used."),
                              { from: 0, to: 6, step: 1, labels: [qsTr("Off"), qsTr("Highest")] }),
                        select("avcodec-skiploopfilter", qsTr("Skip the H.264 loop filter"),
                               qsTr("Speeds up H.264 decoding on slow computers at some cost to quality.")),
                        text("avcodec-threads", qsTr("Decoding threads"),
                             qsTr("How many processor threads decode video. 0 picks a number for you."))
                    ]
                },
                {
                    title: qsTr("Smooth Playback"),
                    rows: [
                        toggle("drop-late-frames", qsTr("Drop frames when the system can't keep up")),
                        select("avcodec-skip-frame", qsTr("Skip frames when decoding"),
                               qsTr("Lets the decoder skip frames on slow computers."))
                    ]
                }
            ],
            advanced: [
                {
                    title: qsTr("Developer"),
                    rows: [
                        text("codec", qsTr("Decoder"), qsTr("The decoders VLC tries first, as a comma separated list.")),
                        select("clock-synchro", qsTr("Clock synchronisation"),
                               qsTr("Follows the clock of a live source to avoid drift.")),
                        text("clock-jitter", qsTr("Clock jitter"), qsTr("How far the clock may drift before VLC corrects it."),
                             { unit: qsTr("ms") }),
                        text("cr-average", qsTr("Clock reference averaging"), qsTr("How many clock samples VLC averages."))
                    ]
                }
            ]
        },
        {
            id: "recording",
            name: qsTr("Recording"),
            title: qsTr("Recording, Casting & Streaming Out"),
            group: 2,
            icon: "record",
            sections: [
                {
                    title: qsTr("Recording"),
                    rows: [
                        row("folder", "input-record-path", qsTr("Save recordings to"), qsTr("The folder for recordings.")),
                        toggle("input-record-native", qsTr("Record without re-encoding when possible"))
                    ]
                },
                {
                    title: qsTr("Casting"),
                    rows: [
                        select("sout-chromecast-conversion-quality", qsTr("Cast quality"),
                               qsTr("Lower quality casts more smoothly over a slow network."))
                    ]
                },
                {
                    title: qsTr("Streaming"),
                    rows: [
                        toggle("sout-display", qsTr("Play locally while streaming")),
                        toggle("sout-audio", qsTr("Include audio")),
                        toggle("sout-video", qsTr("Include video")),
                        toggle("sout-spu", qsTr("Include subtitles")),
                        select("sout-x264-preset", qsTr("Encoding preset"),
                               qsTr("Slower presets give better quality for the same file size.")),
                        select("sout-x264-tune", qsTr("Tuning"), qsTr("Tunes the encoder for a kind of content."))
                    ]
                }
            ],
            advanced: [
                {
                    rows: [
                        text("sout-chromecast-http-port", qsTr("Cast port"), qsTr("The port cast devices connect to."))
                    ]
                }
            ]
        },
        {
            id: "extensions",
            name: qsTr("Extensions"),
            title: qsTr("Add-ons & Scripts"),
            group: 2,
            icon: "plugins",
            sections: [
                {
                    title: qsTr("Add-ons"),
                    rows: [
                        row("addons", "", ""),
                        toggle("qt-autoload-extensions", qsTr("Load add-ons on startup"))
                    ]
                }
            ],
            advanced: [ { rows: [] } ]
        }
    ]
}
