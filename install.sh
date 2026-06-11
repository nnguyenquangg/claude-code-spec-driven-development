#!/usr/bin/env bash
# Install the claude-code-spec-driven-development skills & commands into ~/.claude.
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
for s in my-goal implement-specs spec-loop what-now; do
  place "$REPO/skills/$s" "$SKILLS/$s"
done

echo "Installing commands ($MODE):"
for c in my-goal implement-specs spec-loop what-now; do
  place "$REPO/commands/$c.md" "$COMMANDS/$c.md"
done

echo ""
echo "Installing dependencies:"

# 1) OpenSpec CLI (npm global)
if command -v openspec >/dev/null 2>&1; then
  echo "  ✓ openspec $(openspec --version 2>/dev/null)"
elif command -v npm >/dev/null 2>&1; then
  echo "  → installing openspec…"; npm install -g @fission-ai/openspec@latest >/dev/null 2>&1 \
    && echo "  ✓ openspec $(openspec --version 2>/dev/null)" || echo "  ✗ openspec install failed — run: npm install -g @fission-ai/openspec@latest"
else
  echo "  ✗ npm not found — install Node, then: npm install -g @fission-ai/openspec@latest"
fi

# 2) grill-me skill (mattpocock, MIT) — used by Step 2
if [[ -e "$SKILLS/grill-me/SKILL.md" ]]; then
  echo "  ✓ grill-me skill present"
elif command -v npx >/dev/null 2>&1; then
  echo "  → installing grill-me…"; npx skills add mattpocock/skills --skill=grill-me -y -g >/dev/null 2>&1 \
    && echo "  ✓ grill-me installed" || echo "  ✗ grill-me install failed — run: npx skills add mattpocock/skills --skill=grill-me -y -g"
else
  echo "  ✗ npx not found — run: npx skills add mattpocock/skills --skill=grill-me -y -g"
fi

# 3) Claude Code plugin packs — dev-workflows (task-analyzer, code-verifier, quality-fixer)
#    and fullstack-dev-skills (nestjs-expert, postgres-pro, react-expert, … = Step-4 experts)
if command -v claude >/dev/null 2>&1; then
  installed() { claude plugin list 2>/dev/null | grep -q "$1"; }
  add_plugin() { # marketplace-source  plugin@marketplace  label
    local src="$1" plugin="$2" label="$3"
    if installed "$label"; then echo "  ✓ $label already installed"; return; fi
    echo "  → adding marketplace $src and installing $plugin…"
    claude plugin marketplace add "$src" >/dev/null 2>&1 || true
    claude plugin install "$plugin" --scope user >/dev/null 2>&1 \
      && echo "  ✓ $label installed" || echo "  ✗ $label failed — run: claude plugin marketplace add $src && claude plugin install $plugin"
  }
  add_plugin "shinpr/claude-code-workflows" "dev-workflows@claude-code-workflows"        "dev-workflows"
  add_plugin "jeffallan/claude-skills"      "fullstack-dev-skills@fullstack-dev-skills"  "fullstack-dev-skills"
else
  echo "  ✗ 'claude' CLI not found — install the plugin packs manually:"
  echo "      claude plugin marketplace add shinpr/claude-code-workflows && claude plugin install dev-workflows@claude-code-workflows"
  echo "      claude plugin marketplace add jeffallan/claude-skills && claude plugin install fullstack-dev-skills@fullstack-dev-skills"
fi

echo ""
echo "Done. Restart Claude Code so the new skills/commands/plugins load."
echo "Per project: run 'openspec init --tools claude' and paste docs/CLAUDE-snippet.md into the project's CLAUDE.md."
