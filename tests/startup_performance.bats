setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "startup: bash_profile loads within 300ms budget" {
  # Run bash non-interactively to measure sourcing overhead
  # We run multiple times and take the best to reduce noise from system load
  local best_ms=999999
  for i in 1 2 3; do
    local start end ms
    start=$(date +%s%N)
    bash -c 'source "$REPO_ROOT/bash_profile"'
    end=$(date +%s%N)
    ms=$(( (end - start) / 1000000 ))
    if [ "$ms" -lt "$best_ms" ]; then
      best_ms=$ms
    fi
  done

  echo "Best startup time: ${best_ms}ms"
  [ "$best_ms" -lt 300 ]
}
