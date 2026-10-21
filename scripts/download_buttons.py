"""The download buttons the README shows, read by gen_download_buttons.py.

Each entry names a button the generator knows and where it leads. The rows,
their order, the colours and the words are the generator's, the same in every
repository.
"""

REPO = "vlc-redesign"
RELEASE = "https://github.com/junkerderprovinz/vlc-redesign/releases/latest/download/"

BUTTONS = {
    "windows": RELEASE + "vlc-redesign-windows-amd64.zip",
    "windows-portable": RELEASE + "vlc-redesign-windows-amd64-portable.zip",
    "linux": RELEASE + "vlc-redesign-linux-amd64.AppImage",
    # A release's "Source code (zip)" is the whole repository at that tag, and
    # GitHub gives the newest one no fixed address, so this leads to the release
    # that lists it.
    "source": "https://github.com/junkerderprovinz/vlc-redesign/releases/latest",
}
