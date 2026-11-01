#!/usr/bin/env bash
# Scaffold a personal harness folder: layered context (global > layer > client > project) that
# Claude Code loads through @imports. Nothing is committed into your project repos.
#
#   harness-scaffold.sh init    <dir>                              global protocol + standards
#   harness-scaffold.sh layer   <dir> <layer>                      a tech layer (nestjs, postgres, ...)
#   harness-scaffold.sh project <dir> <client>/<project> [layer ...]
#   harness-scaffold.sh link    <dir> <client>/<project> [repo]    repo's CLAUDE.local.md imports it
#   harness-scaffold.sh global  <dir>                              ~/.claude/CLAUDE.md imports global/
#
# Existing files are never overwritten; re-running only adds what is missing.
# Keep the harness dir private and writable only by you: `global` and `link` load it into
# every session, so whoever can edit it can instruct your agent.
set -euo pipefail

TEMPLATE="$(cd "$(dirname "${BASH_SOURCE[0]}")/../harness-template" && pwd -P)"
die() { echo "error: $*" >&2; exit 1; }
usage() { sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 2; }
name_ok() { [[ "$1" =~ ^[a-z0-9][a-z0-9._-]*$ ]] || die "'$1': use lowercase letters, digits, . _ -"; }
abs() { # absolute path of an existing dir; @imports cannot hold whitespace, so refuse it
  local d; d="$(cd "$1" 2>/dev/null && pwd -P)" || die "'$1' does not exist"
  [[ "$d" =~ [[:space:]] ]] && die "'$d' contains whitespace, which @imports cannot hold; pick a path without spaces"
  printf '%s\n' "$d"
}
mkabs() { # like abs, but create the dir (init only); check the name before creating anything
  [[ "$1" =~ [[:space:]] ]] && die "'$1' contains whitespace, which @imports cannot hold; pick a path without spaces"
  mkdir -p "$1" && abs "$1"
}

# append one line, starting a new line first if the file does not end in one
append_line() { # file line
  if [[ -s "$1" && -n "$(tail -c 1 "$1")" ]]; then printf '\n' >> "$1"; fi
  printf '%s\n' "$2" >> "$1"
}

# copy one template file, filling {{NAME}}; never overwrite
put() { # src dst name
  local src="$1" dst="$2" name="$3"
  [[ -e "$dst" ]] && { echo "  keep   $dst"; return; }
  mkdir -p "$(dirname "$dst")"
  sed "s/{{NAME}}/$name/g" "$src" > "$dst"
  echo "  create $dst"
}
put_dir() { # template-subdir dst name
  local sub="$1" dst="$2" name="$3" f rel
  while IFS= read -r f; do
    rel="${f#"$TEMPLATE/$sub/"}"
    put "$f" "$dst/$rel" "$name"
  done < <(find "$TEMPLATE/$sub" -type f | sort)
}

cmd="${1:-}"; [[ -n "$cmd" ]] || usage; shift
case "$cmd" in
  init)
    [[ $# -eq 1 ]] || usage
    H="$(mkabs "$1")"; chmod 700 "$H"   # private: it is read as instructions in every session
    put_dir global "$H/global" global
    mkdir -p "$H/layers" "$H/clients"
    echo "Next: '$0 global $H' so every session reads the protocol."
    ;;
  layer)
    [[ $# -eq 2 ]] || usage
    H="$(abs "$1")"; name_ok "$2"
    put_dir layer "$H/layers/$2" "$2"
    ;;
  project)
    [[ $# -ge 2 ]] || usage
    H="$(abs "$1")"; key="$2"; shift 2
    [[ "$key" == */* ]] || die "project key is <client>/<project>"
    client="${key%%/*}"; project="${key#*/}"; name_ok "$client"; name_ok "$project"
    [[ -d "$H/global" ]] || die "$H is not initialised; run '$0 init $H' first"
    put_dir client "$H/clients/$client" "$client"
    P="$H/clients/$client/projects/$project"
    put_dir project "$P" "$project"
    for l in "$@"; do name_ok "$l"; put_dir layer "$H/layers/$l" "$l"; done
    # index.md: what a session in this project's repo loads (relative imports, 1 hop deep)
    if [[ ! -e "$P/index.md" ]]; then
      {
        echo "# Harness context: $client/$project"
        echo
        for l in "$@"; do echo "@../../../../layers/$l/standards.md"; echo "@../../../../layers/$l/notes.md"; done
        echo "@../../standards.md"
        echo "@../../notes.md"
        echo "@standards.md"
        echo "@context.md"
        echo "@glossary.md"
        echo
        echo "Specs go in \`specs/\` (or an OpenSpec change in the repo), decisions in \`decisions/\`,"
        echo "the session log in \`progress.md\` - all in this folder: $P"
      } > "$P/index.md"
      echo "  create $P/index.md"
    else
      echo "  keep   $P/index.md (add new layers to it by hand)"
    fi
    echo "Next: fill context.md and glossary.md, then '$0 link $H $key <repo>'."
    ;;
  link)
    [[ $# -ge 2 && $# -le 3 ]] || usage
    H="$(abs "$1")"; key="$2"; repo="${3:-.}"
    [[ "$key" == */* ]] || die "project key is <client>/<project>"
    name_ok "${key%%/*}"; name_ok "${key#*/}"
    P="$H/clients/${key%%/*}/projects/${key#*/}"
    [[ -f "$P/index.md" ]] || die "no project $key in $H; run '$0 project $H $key' first"
    repo="$(cd "$repo" && pwd -P)"
    git -C "$repo" rev-parse --git-dir >/dev/null 2>&1 || die "$repo is not a git repository"
    local_md="$repo/CLAUDE.local.md"; line="@$P/index.md"
    [[ -L "$local_md" ]] && die "$local_md is a symlink; not writing through it"
    git -C "$repo" ls-files --error-unmatch CLAUDE.local.md >/dev/null 2>&1 \
      && die "$local_md is tracked by the repo; an import there would be committed. Use ~/.claude/CLAUDE.md or untrack it first"
    if [[ -f "$local_md" ]] && grep -qxF "$line" "$local_md"; then
      echo "  keep   $local_md (already imports $key)"
    else
      append_line "$local_md" "$line"; echo "  import $key into $local_md"
    fi
    # keep it out of the client's repo: a local exclude, not their .gitignore
    exclude="$(git -C "$repo" rev-parse --git-path info/exclude)"
    [[ "$exclude" == /* ]] || exclude="$repo/$exclude"
    mkdir -p "$(dirname "$exclude")"
    grep -qxF "CLAUDE.local.md" "$exclude" 2>/dev/null || { append_line "$exclude" "CLAUDE.local.md"; echo "  ignore CLAUDE.local.md locally ($exclude)"; }
    echo "Claude Code asks once to allow these external imports in this repo: approve it."
    ;;
  global)
    [[ $# -eq 1 ]] || usage
    H="$(abs "$1")"; [[ -d "$H/global" ]] || die "$H is not initialised"
    G="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/CLAUDE.md"; mkdir -p "$(dirname "$G")"
    backed_up=0; [[ -f "$G" ]] || backed_up=1    # nothing to back up on a first run
    for f in protocol.md standards.md; do
      line="@$H/global/$f"
      grep -qxF "$line" "$G" 2>/dev/null && { echo "  keep   $line"; continue; }
      if [[ $backed_up == 0 ]]; then cp "$G" "$G.bak.$(date +%Y%m%d%H%M%S)"; backed_up=1; fi
      append_line "$G" "$line"; echo "  import $line into $G"
    done
    ;;
  -h|--help|help) usage ;;
  *) usage ;;
esac
