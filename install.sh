#!/usr/bin/env bash
# Install the claude-code-spec-driven-development skills, commands and agents into ~/.claude.
# Default: symlink (so `git pull` updates them live). --copy copies instead.
# An existing skill/command/agent of the same name that this installer did not place is
# left alone (reported as skip); --force replaces it.
set -euo pipefail

MODE="link"; FORCE=0
for arg in "$@"; do
  case "$arg" in
    --copy)  MODE="copy" ;;
    --force) FORCE=1 ;;
    *) echo "usage: $0 [--copy] [--force]" >&2; exit 2 ;;
  esac
done

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
SKILLS="$CLAUDE_DIR/skills"
COMMANDS="$CLAUDE_DIR/commands"
AGENTS="$CLAUDE_DIR/agents"
mkdir -p "$SKILLS" "$COMMANDS" "$AGENTS"
CLAUDE_DIR="$(cd "$CLAUDE_DIR" && pwd -P)"          # one spelling, so manifest lookups match
SKILLS="$CLAUDE_DIR/skills"; COMMANDS="$CLAUDE_DIR/commands"; AGENTS="$CLAUDE_DIR/agents"

MANIFEST="$CLAUDE_DIR/.sdd-toolkit-installed"   # paths this installer placed (copy mode)
touch "$MANIFEST"

ours() { # dst was placed by this installer: a symlink into this repo, or listed in the manifest
  local dst="$1"
  if [[ -L "$dst" ]]; then
    [[ ! -e "$dst" ]] && return 0                      # dangling link (repo moved): replaceable
    local target dir; target="$(readlink "$dst")"
    [[ "$target" == /* ]] || target="$(dirname "$dst")/$target"   # relative to the link's folder
    dir="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)" || return 1
    [[ "$dir" == "$REPO" || "$dir" == "$REPO"/* ]]; return
  fi
  grep -qxF "$dst" "$MANIFEST"
}

place() { # src dst
  local src="$1" dst="$2"
  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ $FORCE == 0 ]] && ! ours "$dst"; then
      echo "  skip  $dst (exists and is not from this repo; re-run with --force to replace it)"
      return
    fi
    rm -rf "$dst"
  fi
  if [[ "$MODE" == "copy" ]]; then
    cp -R "$src" "$dst"
    grep -qxF "$dst" "$MANIFEST" || echo "$dst" >> "$MANIFEST"
  else
    ln -s "$src" "$dst"
  fi
  echo "  $MODE  $dst"
}

echo "Installing skills ($MODE):"
for s in task-analyzer research autopilot make-plan implement-specs fix spec-loop what-now diagnose ui-walkthrough; do
  place "$REPO/skills/$s" "$SKILLS/$s"
done

echo "Installing commands ($MODE):"
for c in task-analyzer research autopilot make-plan implement-specs fix spec-loop what-now; do
  place "$REPO/commands/$c.md" "$COMMANDS/$c.md"
done

echo "Installing agents ($MODE):"
for a in diff-reviewer security-reviewer edge-case-reviewer; do
  place "$REPO/agents/$a.md" "$AGENTS/$a.md"
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

# 2) grill-me skill (mattpocock, MIT) — used by /make-plan to clarify
if [[ -e "$SKILLS/grill-me/SKILL.md" ]]; then
  echo "  ✓ grill-me skill present"
elif command -v npx >/dev/null 2>&1; then
  echo "  → installing grill-me…"; npx skills add mattpocock/skills --skill=grill-me -y -g >/dev/null 2>&1 \
    && echo "  ✓ grill-me installed" || echo "  ✗ grill-me install failed — run: npx skills add mattpocock/skills --skill=grill-me -y -g"
else
  echo "  ✗ npx not found — run: npx skills add mattpocock/skills --skill=grill-me -y -g"
fi

# 3) Claude Code plugin packs — dev-workflows (code-verifier, code-reviewer, technical-designer, quality-fixer)
#    and fullstack-dev-skills (nestjs-expert, postgres-pro, react-expert, … = implementation experts)
if command -v claude >/dev/null 2>&1; then
  installed() { claude plugin list 2>/dev/null | grep -q "$1"; }
  add_plugin() { # marketplace-source  plugin@marketplace  label
    local src="$1" plugin="$2" label="$3"
    if installed "$label"; then echo "  ✓ $label already installed"; return; fi
    echo "  → adding marketplace $src and installing $plugin ..."
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
