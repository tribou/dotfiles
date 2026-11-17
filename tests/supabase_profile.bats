# covers: lib/cloud.sh
# tests/supabase_profile.bats
setup() {
  load 'test_helper/common_setup'
  common_setup
  export SUPABASE_PROFILES="$BATS_TEST_TMPDIR/profiles.tsv"
  fzf() { head -n1; }
  unset SUPABASE_ACCESS_TOKEN SUPABASE_PROJECT_REF SUPABASE_URL
}

@test "supabase-profile: keeps later fields in place when the project ref is empty" {
  printf 'work\ttok123456789\t\thttps://work.supabase.co\n' > "$SUPABASE_PROFILES"
  supabase-profile >/dev/null
  assert_equal "$SUPABASE_ACCESS_TOKEN" "tok123456789"
  assert_equal "${SUPABASE_PROJECT_REF-unset}" "unset"
  assert_equal "$SUPABASE_URL" "https://work.supabase.co"
}

@test "supabase-profile: reads all four fields" {
  printf 'work\ttok123456789\tref1\thttps://work.supabase.co\n' > "$SUPABASE_PROFILES"
  supabase-profile >/dev/null
  assert_equal "$SUPABASE_ACCESS_TOKEN" "tok123456789"
  assert_equal "$SUPABASE_PROJECT_REF" "ref1"
  assert_equal "$SUPABASE_URL" "https://work.supabase.co"
}

@test "supabase-profile: creates a private template without changing the shell umask" {
  umask 022
  run supabase-profile
  assert_failure
  [ -f "$SUPABASE_PROFILES" ]
  assert_equal "$(umask)" "0022"
  supabase-profile 2>/dev/null || true
  rm "$SUPABASE_PROFILES"
  supabase-profile 2>/dev/null || true
  assert_equal "$(umask)" "0022"
  assert_equal "$(stat -c %a "$SUPABASE_PROFILES" 2>/dev/null || stat -f %Lp "$SUPABASE_PROFILES")" "600"
}
