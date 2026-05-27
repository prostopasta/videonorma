#!/usr/bin/env bash
# Install the Nautilus right-click script for videonorma
# Run once: bash nautilus-script-install.sh

set -euo pipefail

SCRIPTS_DIR="$HOME/.local/share/nautilus/scripts"
mkdir -p "$SCRIPTS_DIR"

cat > "$SCRIPTS_DIR/▶ Play normalized" << 'EOF'
#!/usr/bin/env bash
# videonorma: Nautilus script — normalize selected file and open in player
set -euo pipefail

INPUT="$NAUTILUS_SCRIPT_SELECTED_FILE_PATHS"
INPUT=$(echo "$INPUT" | head -1 | tr -d '\n')
[[ -z "$INPUT" ]] && zenity --error --text="No file selected" && exit 1

DIR=$(dirname "$INPUT")
BASE=$(basename "$INPUT")
EXT="${BASE##*.}"
NAME="${BASE%.*}"
OUTPUT="$DIR/${NAME}_normalized.${EXT}"

if [[ -f "$OUTPUT" ]]; then
    notify-send "videonorma" "Already normalized — opening." -i video-x-generic -t 3000
    xdg-open "$OUTPUT" &
    exit 0
fi

notify-send "videonorma" "Normalizing: $BASE\nThis will take ~30s..." -i video-x-generic -t 5000

(
    normalize-audio "$INPUT" > /tmp/videonorma_last.log 2>&1
    notify-send "videonorma ✓" "Done: ${NAME}_normalized.${EXT}" -i video-x-generic -t 5000
    xdg-open "$OUTPUT"
) &
EOF

chmod +x "$SCRIPTS_DIR/▶ Play normalized"
echo "✓ Installed: $SCRIPTS_DIR/▶ Play normalized"
echo ""
echo "Right-click any video file in Files → Scripts → ▶ Play normalized"
