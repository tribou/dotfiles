#!/bin/bash
function mkrepo()
{
  if [ -z "$1" ]; then
    echo "Usage: mkrepo <project-name>"
    return 1
  fi

  # 1. Create directory and navigate into it
  mkdir -p "$1"
  cd "$1" || return

  # 2. Initialize git, create README and .gitignore
  git init -b main
  echo "# $1" > README.md
  cat > .gitignore <<'EOF'
# OS / editor noise
.DS_Store
Thumbs.db
*.swp
*.swo
*~
.idea/

# Secrets
private
.env
.env.local
.env.*.local

# Logs
*.log

# Build artifacts
node_modules/
dist/
build/
coverage/
*.tsbuildinfo

# AI / agent local state
.claude/settings.json
.opencode/local/
.opencode/local.json
.aider*

# Git worktrees
.worktrees/

# Local mise configs (mise.toml is committed; these are personal overrides)
mise.local.toml
mise.local.lock
.mise.local.toml
EOF

  # 3. Initial commit
  git add README.md .gitignore
  git commit -m "Initial commit"

  # 4. Create the repo under the 'tribou' owner
  # --source=. tells gh to use the current folder
  # --push automatically pushes the initial commit
  gh repo create "tribou/$1" --private --source=. --remote=origin --push

  # Handle bug where claude skills don't install without the directory
  mkdir -p .claude/skills

  # 5. Install AI agent skills (all obra/superpowers + most tribou/dotfiles)
  if npx --yes skills@latest add obra/superpowers \
        --skill '*' --agent opencode --agent claude-code -y \
     && npx --yes skills@latest add tribou/dotfiles \
        --skill brainstorming-to-issue --skill issue-to-plan \
        --skill organize-ai-context --skill plan-to-implementation \
        --skill prd --agent opencode --agent claude-code -y; then
    git add -A
    git commit -m "Add AI agent skills"
    git push
  else
    echo "⚠️  Skill installation failed. Install manually with 'npx skills@latest add obra/superpowers'."
  fi

  echo "✅ Created https://github.com/tribou/$1 and synced locally."
}
