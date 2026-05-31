setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "performance: prompt latency is within budget" {
  # Set TERM to avoid terminal warnings and ensure tput functions correctly
  export TERM=xterm-256color

  # Create a temporary non-git directory using BATS_TEST_TMPDIR
  local nongit_dir="$BATS_TEST_TMPDIR/non-git-dir"
  mkdir -p "$nongit_dir"

  # Helper function to run the prompt lifecycle (PROMPT_COMMAND + PS1 expansion)
  # inside a subshell for a given target directory
  run_measure() {
    local target_dir="$1"
    bash -c '
      source "$REPO_ROOT/bash_profile" >/dev/null 2>&1
      
      # Force interactive prompt settings
      export PS1="\[\033[0;34m\]\W \$(get_git_location) > \[$(tput sgr0 2>/dev/null)\]"
      
      cd "$1" || exit 1
      
      # Warm-up run
      eval "$PROMPT_COMMAND" >/dev/null 2>&1
      dummy="${PS1@P}"
      
      start="${EPOCHREALTIME/./}"
      for i in {1..5}; do
        eval "$PROMPT_COMMAND" >/dev/null 2>&1
        dummy="${PS1@P}"
      done
      end="${EPOCHREALTIME/./}"
      
      # Calculate average milliseconds per render
      ms=$(( (end - start) / 5000 ))
      echo "$ms"
    ' -- "$target_dir"
  }

  # Measure non-git directory (best of 3 runs)
  local best_nongit=999999
  for run in 1 2 3; do
    local ms=$(run_measure "$nongit_dir")
    if [ "$ms" -lt "$best_nongit" ]; then
      best_nongit=$ms
    fi
  done

  # Measure git directory (best of 3 runs)
  local best_git=999999
  for run in 1 2 3; do
    local ms=$(run_measure "$REPO_ROOT")
    if [ "$ms" -lt "$best_git" ]; then
      best_git=$ms
    fi
  done

  echo "Best non-git prompt render time: ${best_nongit}ms (Budget: ${PROMPT_NONGIT_BUDGET:-1}ms)"
  echo "Best git prompt render time: ${best_git}ms (Budget: ${PROMPT_GIT_BUDGET:-1}ms)"

  # Performance budgets: 50ms for non-git, 60ms for git
  local nongit_budget=${PROMPT_NONGIT_BUDGET:-50}
  local git_budget=${PROMPT_GIT_BUDGET:-60}

  # Log to performance file
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  local commit
  commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  echo "{\"timestamp\": \"$timestamp\", \"commit\": \"$commit\", \"metric\": \"prompt_nongit_ms\", \"value\": $best_nongit}" >> "$REPO_ROOT/tests/.perf_log.jsonl"
  echo "{\"timestamp\": \"$timestamp\", \"commit\": \"$commit\", \"metric\": \"prompt_git_ms\", \"value\": $best_git}" >> "$REPO_ROOT/tests/.perf_log.jsonl"

  [ "$best_nongit" -lt "$nongit_budget" ]
  [ "$best_git" -lt "$git_budget" ]
}
