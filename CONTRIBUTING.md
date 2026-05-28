# Contributing to videonorma

Thank you for your interest! This guide covers how to help with package distribution and testing.

---

## Table of Contents

- [AUR submission (Arch Linux)](#aur-submission-arch-linux)
- [Fedora COPR](#fedora-copr)
- [Flatpak / Flathub](#flatpak--flathub)
- [Testing packages](#testing-packages)
- [General development](#general-development)

---

## AUR submission (Arch Linux)

The `PKGBUILD` is included in every release. What's missing is the actual AUR submission and keeping it up to date after each release.

### One-time setup

1. **Create an AUR account** at https://aur.archlinux.org/register

2. **Add your SSH key** to your AUR account at https://aur.archlinux.org/account (Settings → SSH Public Key)

3. **Clone the (empty) AUR package repository:**
   ```bash
   git clone ssh://aur@aur.archlinux.org/videonorma.git
   cd videonorma
   ```

4. **Download the PKGBUILD from the latest release:**
   ```bash
   curl -LO https://github.com/prostopasta/videonorma/releases/latest/download/PKGBUILD
   ```

5. **Replace `sha256sums=('SKIP')` with the real checksum:**
   ```bash
   VER=$(grep ^pkgver PKGBUILD | cut -d= -f2)
   curl -LO "https://github.com/prostopasta/videonorma/releases/download/v${VER}/videonorma-${VER}.tar.gz"
   SHA=$(sha256sum "videonorma-${VER}.tar.gz" | cut -d' ' -f1)
   sed -i "s/sha256sums=('SKIP')/sha256sums=('${SHA}')/" PKGBUILD
   rm "videonorma-${VER}.tar.gz"
   ```

6. **Generate `.SRCINFO`** (required by AUR):
   ```bash
   makepkg --printsrcinfo > .SRCINFO
   ```

7. **Commit and push to AUR:**
   ```bash
   git add PKGBUILD .SRCINFO
   git commit -m "Initial import: videonorma ${VER}"
   git push
   ```

### After each new release

Repeat steps 4–7 with the new version. If you want to automate this, see the "Auto-updating AUR" section below.

### Auto-updating AUR via GitHub Actions (optional)

Add the following secrets to the GitHub repository:
- `AUR_SSH_PRIVATE_KEY` — SSH private key linked to your AUR account

Then add a workflow step after "Publish release" that:
1. Downloads the new tarball and computes its sha256
2. Updates `pkgver` and `sha256sums` in `packaging/arch/PKGBUILD`
3. Runs `makepkg --printsrcinfo > .SRCINFO`
4. Pushes to `ssh://aur@aur.archlinux.org/videonorma.git`

A reference implementation: [KSXGitHub/github-actions-deploy-aur](https://github.com/KSXGitHub/github-actions-deploy-aur)

---

## Fedora COPR

COPR is Fedora's "Copr Build System" — like Ubuntu's PPA. It allows users to enable a repository once and then install/update via `dnf`.

### One-time setup

1. **Create a Fedora account** at https://accounts.fedoraproject.org

2. **Create a COPR project** at https://copr.fedorainfracloud.org:
   - Click "New Project"
   - Name: `videonorma`
   - Chroots (build targets): `fedora-rawhide-x86_64`, `fedora-40-x86_64`, `fedora-41-x86_64`, `epel-9-x86_64`
   - Description: "Normalize video loudness to EBU R128 (-16 LUFS)"

3. **Get your COPR API token** from https://copr.fedorainfracloud.org/api

### Building in COPR

COPR builds from a `.src.rpm` (source RPM). The workflow is:

```bash
# Install tools
sudo dnf install -y rpm-build copr-cli

# Download the source tarball
VER=1.3.2
curl -LO "https://github.com/prostopasta/videonorma/releases/download/v${VER}/videonorma-${VER}.tar.gz"

# Copy spec and source to rpmbuild tree
mkdir -p ~/rpmbuild/{SPECS,SOURCES}
cp packaging/rpm/videonorma.spec ~/rpmbuild/SPECS/
sed -i "s/__VERSION__/${VER}/g" ~/rpmbuild/SPECS/videonorma.spec
cp "videonorma-${VER}.tar.gz" ~/rpmbuild/SOURCES/

# Build source RPM
rpmbuild -bs ~/rpmbuild/SPECS/videonorma.spec \
  --define "_userunitdir /usr/lib/systemd/user"

# Submit to COPR
copr-cli build <your-username>/videonorma ~/rpmbuild/SRPMS/videonorma-${VER}-1.*.src.rpm
```

### Users install from COPR

Once the package is published, users can install it with:

```bash
sudo dnf copr enable <your-username>/videonorma
sudo dnf install videonorma
```

### Auto-publishing to COPR via GitHub Actions (optional)

Add `COPR_API_TOKEN` as a GitHub secret (content of `~/.config/copr`). Then add a workflow step that builds the `.src.rpm` and calls `copr-cli build`.

---

## Flatpak / Flathub

Flatpak works on Ubuntu, Fedora, Arch, openSUSE, and most other Linux distros — a single package for all of them.

### What's needed

A `org.prostopasta.videonorma.yml` manifest (Flatpak uses YAML or JSON). The main challenge for videonorma is that it depends on `ffmpeg-normalize` (a Python package installed via pipx), which needs to be bundled inside the Flatpak sandbox.

### High-level steps

1. **Install Flatpak build tools:**
   ```bash
   sudo apt install flatpak flatpak-builder   # Ubuntu
   sudo dnf install flatpak flatpak-builder   # Fedora
   ```

2. **Add the Flathub remote:**
   ```bash
   flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
   ```

3. **Create the manifest** `org.prostopasta.videonorma.yml` (see [Flathub submission guide](https://docs.flathub.org/docs/for-app-authors/submission))

4. **Test the build locally:**
   ```bash
   flatpak-builder --force-clean build-dir org.prostopasta.videonorma.yml
   flatpak-builder --run build-dir org.prostopasta.videonorma.yml normalize-audio --help
   ```

5. **Submit to Flathub** by opening a PR at https://github.com/flathub/flathub with your manifest

This is the most complex packaging task — if you have Flatpak experience and want to take it on, please open an issue.

---

## Testing packages

Even if you don't want to maintain packages, **testing on your distro is extremely valuable**.

### What to test

After installing the package (`.deb`, `.rpm`, or AUR), verify:

- [ ] `normalize-audio --help` and `normalize-audio --version` work
- [ ] `normalize-audio /path/to/recording.mov` produces `recording_normalized.mov` with correct loudness
- [ ] Desktop notification appears while normalizing
- [ ] File manager right-click script works (if applicable)
- [ ] `systemctl --user status videonorma` shows the daemon running after login
- [ ] Tray icon appears and menu works (Pause / Resume / Quit)
- [ ] After `sudo apt remove videonorma` (or `dnf remove` / `pacman -R`), the daemon stops

### Test with a real macOS recording

Download a quiet sample file, or record your screen on macOS with QuickTime and copy the file to Linux. The mean loudness should be around −40 to −50 LUFS before normalization and −16 LUFS after.

Check loudness with ffmpeg:
```bash
ffmpeg -i recording.mov -af ebur128 -f null - 2>&1 | tail -20
```

### Reporting issues

Open an issue at https://github.com/prostopasta/videonorma/issues and include:
- Distro + version
- Package version (`normalize-audio --version`)
- Install method (`.deb`, `.rpm`, AUR, `install.sh`)
- Steps to reproduce
- Output of `journalctl --user -u videonorma -n 50` (for daemon issues)

---

## General development

```bash
git clone https://github.com/prostopasta/videonorma.git
cd videonorma
bash install.sh
```

The project follows [Conventional Commits](https://www.conventionalcommits.org/):
- `fix: ...` → patch release
- `feat: ...` → minor release
- `docs: ...` → no release
- `ci: ...` → no release

Releases are fully automated via GitHub Actions on every merge to `main`.
