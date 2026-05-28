<p align="center">
  <img src="assets/logo.svg" width="100" alt="videonorma logo"/>
</p>

<h1 align="center">videonorma</h1>

<p align="center">
  Fix quiet macOS screen recordings and screencasts on Linux — one click or one command.
</p>

<p align="center">
  <img src="https://img.shields.io/github/v/release/prostopasta/videonorma?style=flat-square&label=latest&color=brightgreen"/>
  <img src="https://img.shields.io/badge/platform-Linux-blue?logo=linux&logoColor=white&style=flat-square"/>
  <img src="https://img.shields.io/badge/tested-Ubuntu%20%7C%20Fedora%20%7C%20Arch%20%7C%20openSUSE-informational?style=flat-square"/>
  <img src="https://img.shields.io/badge/powered%20by-ffmpeg--normalize-green?style=flat-square"/>
  <img src="https://img.shields.io/github/license/prostopasta/videonorma?style=flat-square&color=lightgrey"/>
</p>

---

## Table of Contents

- [The problem](#the-problem)
- [What it does](#what-it-does)
- [Before / After](#before--after)
- [Compatibility](#compatibility)
- [Requirements](#requirements)
- [Installation](#installation)
  - [Ubuntu / Debian — .deb](#ubuntu--debian--deb-package-recommended)
  - [Arch Linux — AUR](#arch-linux--aur)
  - [Fedora / RHEL — .rpm](#fedora--rhel--rpm-package)
  - [Any distro — from source](#any-distro--from-source-archive)
  - [From git (development)](#from-git-development)
- [Usage](#usage)
  - [CLI](#cli)
  - [File manager](#file-manager-gnome-cinnamon-mate)
  - [Daemon](#daemon-automatic-background)
- [Supported formats](#supported-formats)
- [Roadmap](#roadmap)
- [How it works](#how-it-works)
- [Contributing](#contributing)
- [License](#license)

---

## The problem

**macOS screen recordings arrive whisper-quiet on Linux.**

QuickTime, Zoom, Loom, Teams, and other screen-recording tools on macOS capture audio at a very low input level — typically **−40 to −50 dB LUFS** average loudness. When you open these files on Linux there is no automatic loudness compensation, so the video is barely audible even at maximum system volume.

Common sources of the problem:

| Recording tool | Typical loudness | Audible on Linux? |
|---|---|---|
| QuickTime screen recording | −44 dBFS | ❌ barely |
| Zoom cloud / local recording | −38 to −46 dBFS | ❌ barely |
| Loom screen recording | −40 to −48 dBFS | ❌ barely |
| macOS Screenshot.app (⌘+Shift+5) | −42 to −50 dBFS | ❌ barely |
| Slack video message | −40 to −50 dBFS | ❌ barely |
| OBS (default settings) | −18 to −23 dBFS | ✅ fine |

videonorma fixes all of them.

## What it does

- Normalizes video/audio loudness to **EBU R128 −16 LUFS** (broadcast standard)
- **Never modifies the original** — output is `<name>_normalized.<ext>` alongside the source
- Copies the video stream without re-encoding (fast, no quality loss)
- Re-encodes audio to AAC 192 kbps with corrected loudness
- Works as a **CLI tool**, a **file manager right-click script**, and a **background daemon** that watches `~/Downloads` and normalizes new videos automatically

## Before / After

| | Original (macOS screen recording) | Normalized |
|--|--|--|
| Mean loudness | −46.1 LUFS | −16.0 LUFS |
| True peak | −21.0 dBTP | −1.5 dBTP |
| Perceived | barely audible | broadcast-level |

---

## Compatibility

### Distributions

| Distro | CLI | File manager script | Package | Notes |
|--------|:---:|:-------------------:|:-------:|-------|
| Ubuntu 22.04+ | ✅ | ✅ | `.deb` | Fully tested |
| Debian 12+ | ✅ | ✅ | `.deb` | |
| Fedora 38+ | ✅ | ✅ | `.rpm` | ffmpeg needs [RPM Fusion](#fedora--rhel--rpm-package) |
| Arch / Manjaro | ✅ | ✅ | AUR | |
| openSUSE Tumbleweed | ✅ | ✅ | tarball | |
| Other systemd distros | ✅ | ⚠️ | tarball | Manual file manager setup |

### File managers

| File manager | Desktop | Auto-install | How |
|---|---|:---:|---|
| Nautilus (Files) | GNOME | ✅ | `install.sh` puts script in `~/.local/share/nautilus/scripts/` |
| Nemo | Cinnamon | ✅ | `~/.local/share/nemo/scripts/` |
| Caja | MATE | ✅ | `~/.config/caja/scripts/` |
| Dolphin | KDE | ⚠️ | Manual [service menu](https://develop.kde.org/docs/apps/dolphin/service-menus/) |
| Thunar | XFCE | ⚠️ | Edit → Configure custom actions → Command: `normalize-audio %f` |
| Any | — | — | CLI always works regardless of desktop |

---

## Requirements

| Dependency | Required for | Installed by |
|---|---|---|
| `ffmpeg` ≥ 4.2 | core normalization | `install.sh` |
| `pipx` | installing ffmpeg-normalize | `install.sh` |
| `ffmpeg-normalize` | core normalization | `install.sh` |
| `libnotify` (`notify-send`) | desktop notifications | `install.sh` (optional) |
| `xdg-utils` (`xdg-open`) | opening result in player | `install.sh` (optional) |
| `zenity` | error dialogs | `install.sh` (optional) |

A video player (VLC, mpv, Totem, etc.) is needed to play the output — `xdg-open` uses your system default.

---

## Installation

### Ubuntu / Debian — .deb package (recommended)

```bash
# Download the latest .deb from the releases page
wget https://github.com/prostopasta/videonorma/releases/latest/download/videonorma_$(curl -s https://api.github.com/repos/prostopasta/videonorma/releases/latest | grep tag_name | cut -d'"' -f4 | tr -d v)_all.deb
sudo dpkg -i videonorma_*_all.deb
sudo apt-get install -f   # install any missing system dependencies
```

The package installs `normalize-audio` to `/usr/local/bin/` and runs `pipx install ffmpeg-normalize` automatically.

### Arch Linux — AUR

Install via your AUR helper:

```bash
yay -S videonorma
# or
paru -S videonorma
```

**Manual install from PKGBUILD** (download the `PKGBUILD` from the [releases page](https://github.com/prostopasta/videonorma/releases/latest)):

```bash
mkdir videonorma && cd videonorma
curl -LO https://github.com/prostopasta/videonorma/releases/latest/download/PKGBUILD
makepkg -si
```

After install, enable `pipx` and install `ffmpeg-normalize`:

```bash
pipx install ffmpeg-normalize
```

### Fedora / RHEL — .rpm package

Enable [RPM Fusion](https://rpmfusion.org/) (required for `ffmpeg`), then install the `.rpm`:

```bash
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm

VER=$(curl -s https://api.github.com/repos/prostopasta/videonorma/releases/latest \
  | grep tag_name | cut -d'"' -f4 | tr -d v)
sudo dnf install -y \
  "https://github.com/prostopasta/videonorma/releases/latest/download/videonorma-${VER}-1.noarch.rpm"
```

After install, enable `pipx` and install `ffmpeg-normalize`:

```bash
pipx install ffmpeg-normalize
```

### Any distro — from source archive

```bash
# Download and extract
wget https://github.com/prostopasta/videonorma/releases/latest/download/videonorma-VERSION.tar.gz
tar -xzf videonorma-VERSION.tar.gz
cd videonorma-VERSION/

# Run the installer (auto-detects apt / dnf / pacman / zypper)
bash install.sh
```

**CLI only** (no file manager integration):

```bash
bash install.sh --cli-only
```

### From git (development)

```bash
git clone https://github.com/prostopasta/videonorma.git
cd videonorma
bash install.sh
```

---

## Usage

### CLI

```bash
# Single file — macOS screen recording, Zoom export, Loom download, etc.
normalize-audio recording.mov

# Multiple files at once
normalize-audio *.mp4

# Output is created next to the original:
# recording.mov  →  recording_normalized.mov
```

### File manager (GNOME, Cinnamon, MATE)

Right-click any video file → **Scripts → ▶ Play normalized**

The script:
1. Checks if `_normalized` version already exists (skips re-processing)
2. Shows a desktop notification while normalizing in the background
3. Opens the result in your default player when done
4. Logs errors to `/tmp/videonorma_last.log`

### Daemon (automatic, background)

The daemon watches `~/Downloads` and notifies you when a new video arrives:

1. A desktop notification pops up: **Normalize / Skip / Dismiss**
2. Click **Normalize** — it processes in the background and opens the result when done
3. The tray icon lets you pause watching, toggle auto-normalize, and quit

**The daemon starts automatically on login** (systemd user service). Control it manually:

```bash
systemctl --user status videonorma    # check status
systemctl --user stop videonorma      # stop
systemctl --user start videonorma     # start
journalctl --user -u videonorma -f    # live log
```

**Additional daemon dependencies** (installed automatically by `install.sh`):

| Dependency | Purpose |
|---|---|
| `python3-watchdog` | file system events |
| `gir1.2-ayatanaappindicator3-0.1` | system tray icon |
| `python3-gi` | GTK/GLib Python bindings |

---

## Supported formats

Any container supported by ffmpeg: `.mov`, `.mp4`, `.mkv`, `.webm`, `.avi`, `.m4v`, `.ts`, and more.

---

## Roadmap

- [x] Phase 1 — CLI tool + file manager right-click script
- [x] Phase 2 — **videonorma daemon**: watches `~/Downloads`, desktop notification with one-click "Normalize", system tray icon with dark/light theme support
- [x] Phase 3.1 — PKGBUILD for **Arch Linux / AUR** and `.rpm` for **Fedora / RHEL** — both published as GitHub Release assets
- [ ] Phase 3.2 — **AUR submission**: real checksums in PKGBUILD, `.SRCINFO`, auto-push to `aur.archlinux.org` on every release
- [ ] Phase 3.3 — **Fedora COPR**: auto-publish `.rpm` to a COPR repository so users can `dnf install` with a one-time `dnf copr enable`
- [ ] Phase 4 — **Flatpak / Flathub** (cross-distro, works on Ubuntu / Fedora / Arch / openSUSE); multi-directory watch; per-directory rules; GUI settings window

> Want to help? See [CONTRIBUTING.md](CONTRIBUTING.md) for guides on AUR submission, COPR setup, Flatpak packaging, and package testing.

---

## How it works

`normalize-audio` calls [`ffmpeg-normalize`](https://github.com/slhck/ffmpeg-normalize) with EBU R128 two-pass loudness normalization:

```
Target:     −16 LUFS
True peak:  −1.5 dBTP
LRA:        11 LU
Video:      stream copy (no re-encode)
Audio:      AAC 192 kbps
```

---

## Keywords

> macOS screen recording too quiet · QuickTime recording low volume · Zoom recording quiet Linux ·
> Loom video quiet · screencast audio normalization · video loudness fix Linux · EBU R128 normalization ·
> ffmpeg normalize audio · normalize video loudness · macOS screen capture audio boost ·
> fix quiet video Linux · audio normalization tool Linux · video audio too low ·
> normalize mp4 loudness · normalize mov file audio · ffmpeg-normalize GUI · screencast loudness ·
> macOS recording volume fix · low volume video fix · LUFS normalization Linux

---

## Contributing

Contributions are welcome! See **[CONTRIBUTING.md](CONTRIBUTING.md)** for:

- How to submit videonorma to **AUR** (Arch User Repository)
- How to publish to **Fedora COPR** so Fedora/RHEL users can `dnf install`
- How to package for **Flatpak / Flathub**
- How to **test packages** on each distro (Ubuntu, Fedora, Arch)

If you want to take ownership of the AUR or COPR package — open an issue or start a discussion, it's very welcome.

---

## License

MIT — see [LICENSE](LICENSE)
