#!/usr/bin/env bash
# Install the claude-sdd-pipeline skills & commands into ~/.claude.
# Default: symlink (so `git pull` updates them live). Use --copy to copy instead.
set -euo pipefail

MODE="link"
[[ "${1:-}" == "--copy" ]] && MODE="copy"

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
SKILLS="$CLAUDE_DIR/skills"
COMMANDS="$CLAUDE_DIR/commands"
mkdir -p "$SKILLS" "$COMMANDS"

place() { # src dst
  local src="$1" dst="$2"
  if [[ -e "$dst" || -L "$dst" ]]; then rm -rf "$dst"; fi
  if [[ "$MODE" == "copy" ]]; then cp -R "$src" "$dst"; else ln -s "$src" "$dst"; fi
  echo "  $MODE  $dst"
}

echo "Installing skills ($MODE):"
for s in my-goal spec-loop what-now; do
  place "$REPO/skills/$s" "$SKILLS/$s"
done

echo "Installing commands ($MODE):"
for c in my-goal spec-loop what-now; do
  place "$REPO/commands/$c.md" "$COMMANDS/$c.md"
done

echo ""
echo "Checking dependencies:"
if command -v openspec >/dev/null 2>&1; then
  echo "  ✓ openspec $(openspec --version 2>/dev/null)"
else
  echo "  ✗ openspec missing → npm install -g @fission-ai/openspec@latest"
fi
if [[ -e "$SKILLS/grill-me/SKILL.md" ]]; then
  echo "  ✓ grill-me skill present"
else
  echo "  ✗ grill-me missing → npx skills add mattpocock/skills --skill=grill-me -y -g"
fi

echo ""
echo "Done. Restart Claude Code so the new skills/commands load."
echo "Per project: run 'openspec init --tools claude' and paste docs/CLAUDE-snippet.md into the project's CLAUDE.md."
