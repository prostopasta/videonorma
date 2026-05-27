<p align="center">
  <img src="assets/logo.svg" width="100" alt="videonorma logo"/>
</p>

<h1 align="center">videonorma</h1>

<p align="center">
  Fix quiet videos from Slack, macOS screen recordings, and anywhere else — right from your file manager or terminal.
</p>

<p align="center">
  <a href="https://github.com/prostopasta/videonorma/releases/latest">
    <img src="https://img.shields.io/github/v/release/prostopasta/videonorma?style=flat-square&label=latest&color=brightgreen"/>
  </a>
  <img src="https://img.shields.io/badge/platform-Linux-blue?logo=linux&logoColor=white&style=flat-square"/>
  <img src="https://img.shields.io/badge/tested-Ubuntu%20%7C%20Fedora%20%7C%20Arch%20%7C%20openSUSE-informational&style=flat-square"/>
  <img src="https://img.shields.io/badge/powered%20by-ffmpeg--normalize-green&style=flat-square"/>
  <img src="https://img.shields.io/github/license/prostopasta/videonorma?style=flat-square&color=lightgrey"/>
</p>

---

## The problem

macOS screen recordings and Slack video downloads often arrive at **−40 to −50 dB** average loudness — whisper-quiet even at maximum system volume. On Linux, there is no automatic loudness correction for downloaded files.

videonorma fixes that.

## What it does

- Normalizes video/audio loudness to **EBU R128 −16 LUFS** (broadcast standard)
- **Never modifies the original** — output is `<name>_normalized.<ext>` alongside the source
- Copies the video stream without re-encoding (fast, no quality loss)
- Re-encodes audio to AAC 192 kbps with corrected loudness
- Works as a **CLI tool** and a **file manager right-click script**

## Before / After

| | Original | Normalized |
|--|--|--|
| Mean loudness | −46.1 dB | −18.7 dB |
| Peak | −21.0 dB | −0.4 dB |
| Perceived | barely audible | normal |

---

## Compatibility

### Distributions

| Distro | CLI | File manager script | Notes |
|--------|:---:|:-------------------:|-------|
| Ubuntu 22.04+ | ✅ | ✅ | Fully tested |
| Debian 12+ | ✅ | ✅ | |
| Fedora 38+ | ✅ | ✅ | ffmpeg needs [RPM Fusion](#fedora--rhel) |
| Arch / Manjaro | ✅ | ✅ | |
| openSUSE Tumbleweed | ✅ | ✅ | |
| Other systemd distros | ✅ | ⚠️ | Manual file manager setup |

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

```bash
git clone https://github.com/prostopasta/videonorma.git
cd videonorma
bash install.sh
```

The installer detects your package manager and file manager automatically.

**CLI only** (no file manager integration, no sudo needed except for ffmpeg):

```bash
bash install.sh --cli-only
```

### Fedora / RHEL

`ffmpeg` is not in the default Fedora repositories. Enable RPM Fusion first:

```bash
sudo dnf install -y \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf install -y ffmpeg
```

Then run `bash install.sh` as usual.

---

## Usage

### CLI

```bash
# Single file
normalize-audio recording.mov

# Multiple files
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

---

## Supported formats

Any container supported by ffmpeg: `.mov`, `.mp4`, `.mkv`, `.webm`, `.avi`, `.m4v`, `.ts`, and more.

---

## Roadmap

- [x] Phase 1 — CLI tool + file manager script
- [ ] Phase 2 — **videonorma daemon**: watches `~/Downloads`, shows a desktop notification with a one-click "Normalize" action, system tray icon to enable/disable

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

## License

MIT — see [LICENSE](LICENSE)
