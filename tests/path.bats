setup() {
  load 'test_helper/common_setup'
  common_setup
  _ORIG_PATH="$PATH"
  . "$REPO_ROOT/lib/path.sh"
}

teardown() {
  export PATH="$_ORIG_PATH"
}

@test "_path_strip removes entries matching a single glob pattern" {
  export PATH="/usr/bin:/opt/homebrew/bin:/bin"
  _path_strip "*homebrew*"
  assert_equal "$PATH" "/usr/bin:/bin"
}

@test "_path_strip removes entries matching multiple glob patterns" {
  export PATH="/usr/bin:/opt/homebrew/bin:/home/linuxbrew/.linuxbrew/bin:/bin"
  _path_strip "*homebrew*" "*linuxbrew*"
  assert_equal "$PATH" "/usr/bin:/bin"
}

@test "_path_strip preserves PATH when no entries match" {
  export PATH="/usr/bin:/usr/local/bin:/bin"
  _path_strip "*homebrew*"
  assert_equal "$PATH" "/usr/bin:/usr/local/bin:/bin"
}

@test "_path_strip handles empty PATH" {
  export PATH=""
  _path_strip "*homebrew*"
  assert_equal "$PATH" ""
}

@test "_path_strip with no arguments is a no-op" {
  export PATH="/usr/bin:/bin"
  _path_strip
  assert_equal "$PATH" "/usr/bin:/bin"
}

@test "_path_strip removes all entries when all match" {
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin"
  _path_strip "*homebrew*"
  assert_equal "$PATH" ""
}

@test "_path_dedup removes duplicate entries preserving first occurrence" {
  export PATH="/usr/bin:/usr/local/bin:/usr/bin:/bin"
  _path_dedup
  assert_equal "$PATH" "/usr/bin:/usr/local/bin:/bin"
}

@test "_path_dedup preserves order of first occurrences" {
  export PATH="/a:/b:/c:/b:/a"
  _path_dedup
  assert_equal "$PATH" "/a:/b:/c"
}

@test "_path_dedup is a no-op on a PATH with no duplicates" {
  export PATH="/usr/bin:/usr/local/bin:/bin"
  _path_dedup
  assert_equal "$PATH" "/usr/bin:/usr/local/bin:/bin"
}

@test "_path_dedup handles empty PATH" {
  export PATH=""
  _path_dedup
  assert_equal "$PATH" ""
}

@test "_path_dedup is a no-op on a single-entry PATH" {
  export PATH="/usr/bin"
  _path_dedup
  assert_equal "$PATH" "/usr/bin"
}
