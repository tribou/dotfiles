#!/usr/bin/env bash
# Build write-spec claim-check fixture repos under $1 (default: ./repos).
set -euo pipefail
ROOT="${1:-./repos}"

mklib() { # $1 = repo dir; creates 11 lib modules (index.sh written by caller)
  mkdir -p "$1/lib" "$1/tests"
  # Under en_US.UTF-8 collation (underscore ignored) _shared.sh sorts 10th of 11.
  for m in ai aliases completions env fzf history path zsh; do
    printf '#!/usr/bin/env bash\n# %s helpers\n' "$m" > "$1/lib/$m.sh"
  done
  # A 1,384-line commands.sh with 61 functions and 135 aliases, as #42 states.
  {
    printf '#!/usr/bin/env bash\n# General commands: git, npm, docker, tmux, cloud, and shell helpers.\n'
    domains=(git npm docker tmux aws "do" terraform ssh shell)
    for i in $(seq 1 59); do d=${domains[$((i % 9))]}; printf '%s_cmd_%s() {\n  : # %s helper\n}\n' "$d" "$i" "$d"; done
    printf 'mkrepo() {\n  : # scaffold a repo\n}\nkeepalive_claude() {\n  : # agent keep-alive\n}\n'
    for i in $(seq 1 135); do printf "alias c%s='true'\n" "$i"; done
  } > "$1/lib/commands.sh"
  while [ "$(wc -l < "$1/lib/commands.sh")" -lt 1384 ]; do echo '# ---' >> "$1/lib/commands.sh"; done
  printf '#!/usr/bin/env bash\n# Shared helpers other modules call at source time.\n_dotfiles_log() { printf "%%s\\n" "$*" >&2; }\n' > "$1/lib/_shared.sh"
}

# S5-true: index.sh still sources by plain glob, so _shared.sh is not first.
R="$ROOT/S5-true"; rm -rf "$R"; mklib "$R"
cat > "$R/lib/index.sh" <<'EOF'
#!/usr/bin/env bash
# Load every lib module.
DOTFILES_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for f in "$DOTFILES_LIB"/*.sh; do
  [ "$(basename "$f")" = index.sh ] && continue
  source "$f"
done
EOF

# S5-stale: the ordering fix already landed; _*.sh load first, with a test.
R="$ROOT/S5-stale"; rm -rf "$R"; mklib "$R"
cat > "$R/lib/index.sh" <<'EOF'
#!/usr/bin/env bash
# Load lib modules. Underscore-prefixed modules load first, explicitly (#153).
DOTFILES_LIB="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for f in "$DOTFILES_LIB"/_*.sh; do source "$f"; done
for f in "$DOTFILES_LIB"/*.sh; do
  case "$(basename "$f")" in _*|index.sh) continue ;; esac
  source "$f"
done
EOF
cat > "$R/tests/index_order.bats" <<'EOF'
#!/usr/bin/env bats
@test "index.sh sources _shared.sh before every other module" {
  run bash -c 'set -x; source lib/index.sh' 2>&1
  first=$(grep -o 'source [^ ]*\.sh' <<<"$output" | head -1)
  [[ "$first" == *"_shared.sh" ]]
}
EOF

# S1-repo: a search page with an existing persistence hook the skill must not prescribe.
R="$ROOT/S1-repo"; rm -rf "$R"; mkdir -p "$R/src/search" "$R/src/hooks"
printf '{ "name": "shop-web", "private": true }\n' > "$R/package.json"
printf 'export function usePersistentState(key, initial) { /* wraps localStorage */ }\n' > "$R/src/hooks/usePersistentState.ts"
printf 'export const DEFAULT_FILTERS = { sort: "relevance" };\n' > "$R/src/search/filters.ts"
printf 'import { DEFAULT_FILTERS } from "./filters";\nexport function SearchPage() { /* filters live in component state */ }\n' > "$R/src/search/SearchPage.tsx"

for d in "$ROOT"/*/; do git -C "$d" init -q; done
echo "built: $(ls "$ROOT")"
