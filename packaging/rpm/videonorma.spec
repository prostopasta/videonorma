Name:           videonorma
Version:        __VERSION__
Release:        1%{?dist}
Summary:        Fix quiet macOS screen recordings on Linux — normalize video loudness to EBU R128

License:        MIT
URL:            https://github.com/prostopasta/videonorma
Source0:        https://github.com/prostopasta/videonorma/releases/download/v%{version}/videonorma-%{version}.tar.gz

BuildArch:      noarch
BuildRequires:  sed

Requires:       ffmpeg
Requires:       python3-watchdog
Requires:       python3-gobject
Requires:       libnotify
Requires:       xdg-utils

%description
videonorma fixes quiet macOS screen recordings (QuickTime, Zoom, Loom, Teams)
that arrive at -40 to -50 LUFS on Linux. It normalizes video/audio loudness to
EBU R128 (-16 LUFS, broadcast standard) using ffmpeg-normalize.

Includes:
  - CLI tool: normalize-audio
  - File manager right-click script (Nautilus, Nemo, Caja)
  - Background daemon with system tray icon that watches ~/Downloads

%prep
%autosetup -n videonorma-%{version}

%install
# CLI tool
install -Dm755 normalize-audio \
    %{buildroot}%{_prefix}/local/bin/normalize-audio

# Daemon
install -Dm755 daemon/videonorma-daemon \
    %{buildroot}%{_prefix}/local/bin/videonorma-daemon

# Tray icons (XDG hicolor standard path)
install -Dm644 assets/videonorma-dark.svg \
    %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/videonorma-dark.svg
install -Dm644 assets/videonorma-light.svg \
    %{buildroot}%{_datadir}/icons/hicolor/scalable/apps/videonorma-light.svg

# systemd user unit
install -Dm644 daemon/videonorma.service \
    %{buildroot}%{_userunitdir}/videonorma.service

# Patch service ExecStart for system-wide binary path
sed -i \
    's|%%h/.local/bin/videonorma-daemon|%{_prefix}/local/bin/videonorma-daemon|' \
    %{buildroot}%{_userunitdir}/videonorma.service

# Docs
install -Dm644 README.md %{buildroot}%{_docdir}/%{name}/README.md

%files
%license LICENSE
%doc README.md
%{_prefix}/local/bin/normalize-audio
%{_prefix}/local/bin/videonorma-daemon
%{_datadir}/icons/hicolor/scalable/apps/videonorma-dark.svg
%{_datadir}/icons/hicolor/scalable/apps/videonorma-light.svg
%{_userunitdir}/videonorma.service

%post
# Run pipx install for the real user (not root)
REAL_USER="${SUDO_USER:-}"
if [ -z "$REAL_USER" ] || [ "$REAL_USER" = "root" ]; then
    REAL_USER=$(logname 2>/dev/null || true)
fi
if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
    su -l "$REAL_USER" -c '
        if command -v pipx > /dev/null 2>&1; then
            pipx install ffmpeg-normalize 2>/dev/null || \
            pipx upgrade ffmpeg-normalize 2>/dev/null || true
        fi
    ' || true

    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

    # Enable daemon via wants symlink (works without an active user session)
    WANTS_DIR="$REAL_HOME/.config/systemd/user/default.target.wants"
    mkdir -p "$WANTS_DIR"
    ln -sf %{_userunitdir}/videonorma.service \
        "$WANTS_DIR/videonorma.service"

    # Start immediately if the user session bus is reachable
    REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || true)
    if [ -n "$REAL_UID" ] && [ -S "/run/user/$REAL_UID/bus" ]; then
        su -l "$REAL_USER" -c "
            export XDG_RUNTIME_DIR=/run/user/$REAL_UID
            export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$REAL_UID/bus
            systemctl --user daemon-reload 2>/dev/null || true
            systemctl --user restart videonorma.service 2>/dev/null || true
        " || true
    fi
fi

%preun
if [ $1 -eq 0 ]; then
    REAL_USER="${SUDO_USER:-}"
    if [ -z "$REAL_USER" ] || [ "$REAL_USER" = "root" ]; then
        REAL_USER=$(logname 2>/dev/null || true)
    fi
    if [ -n "$REAL_USER" ] && [ "$REAL_USER" != "root" ]; then
        REAL_UID=$(id -u "$REAL_USER" 2>/dev/null || true)
        if [ -n "$REAL_UID" ] && [ -S "/run/user/$REAL_UID/bus" ]; then
            su -l "$REAL_USER" -c "
                export XDG_RUNTIME_DIR=/run/user/$REAL_UID
                export DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$REAL_UID/bus
                systemctl --user stop videonorma.service 2>/dev/null || true
                systemctl --user disable videonorma.service 2>/dev/null || true
            " || true
        fi
    fi
fi

%changelog
* Wed May 28 2026 prostopasta <https://github.com/prostopasta/videonorma> - __VERSION__-1
- Initial RPM package
