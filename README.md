<p align="center">
  <img src="assets/logo.svg" width="100" alt="videonorma logo"/>
</p>

<h1 align="center">videonorma</h1>

<p align="center">
  Fix quiet videos from Slack, macOS screen recordings, and anywhere else — right from your file manager.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Linux-blue?logo=linux&logoColor=white"/>
  <img src="https://img.shields.io/badge/Ubuntu-24.04-orange?logo=ubuntu&logoColor=white"/>
  <img src="https://img.shields.io/badge/ffmpeg-normalize-green"/>
  <img src="https://img.shields.io/badge/license-MIT-lightgrey"/>
</p>

---

## The problem

macOS screen recordings and Slack video downloads often arrive at **−40 to −50 dB** average loudness — whisper-quiet even at maximum system volume. On Linux, there is no automatic loudness correction for downloaded files.

videonorma fixes that.

## What it does

- Normalizes video/audio loudness to **EBU R128 −16 LUFS** (broadcast standard)
- **Never modifies the original** — creates `<name>_normalized.<ext>` alongside
- Copies the video stream without re-encoding (fast, lossless quality)
- Re-encodes audio to AAC 192k with correct loudness
- Works as a **CLI tool** or a **Nautilus right-click script**

## Before / After

| | Original | Normalized |
|--|--|--|
| Mean loudness | −46.1 dB | −18.7 dB |
| Peak | −21.0 dB | −0.4 dB |
| Perceived | barely audible | normal |

## Requirements

- Ubuntu 24.04 (or any Linux with `ffmpeg` ≥ 4.2)
- [`pipx`](https://pipx.pypa.io/)

## Installation

```bash
# 1. Install ffmpeg-normalize
pipx install ffmpeg-normalize

# 2. Clone this repo and add CLI to PATH
git clone https://github.com/prostopasta/videonorma.git
cd videonorma
cp normalize-audio ~/.local/bin/
chmod +x ~/.local/bin/normalize-audio

# 3. (Optional) Install Nautilus right-click script
bash nautilus-script-install.sh
```

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

### Nautilus (Files)

Right-click any video file → **Scripts → ▶ Play normalized**

The script:
1. Normalizes in the background with a desktop notification
2. Opens the result in your default player when done
3. Skips normalization if `_normalized` version already exists

## Supported formats

Any format supported by ffmpeg: `.mov`, `.mp4`, `.mkv`, `.webm`, `.avi`, `.m4v`, and more.

## Roadmap

- [x] Phase 1 — CLI tool + Nautilus script
- [ ] Phase 2 — **videonorma daemon**: watches `~/Downloads`, shows a notification with a "Normalize" action button, system tray icon to enable/disable

## How it works

Under the hood, `normalize-audio` calls [`ffmpeg-normalize`](https://github.com/slhck/ffmpeg-normalize) with EBU R128 two-pass loudness normalization:

```
Target: −16 LUFS  |  True peak: −1.5 dBTP  |  LRA: 11 LU
Video:  stream copy (no re-encode)
Audio:  AAC 192k
```

## License

MIT
