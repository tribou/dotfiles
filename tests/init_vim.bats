setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "init.vim: CopilotChat require is guarded with pcall to avoid errors on fresh install" {
  # Unguarded: require("CopilotChat")  =>  must NOT exist bare
  # Guarded: pcall(require, "CopilotChat") or pcall(function() require(...) end)
  run bash -c "grep -n 'require.*CopilotChat' \"$REPO_ROOT/init.vim\" | grep -v pcall"
  [ "$status" -ne 0 ]
}

@test "init.vim: colorizer require is guarded with pcall to avoid errors on fresh install" {
  run bash -c "grep -n 'require.*colorizer' \"$REPO_ROOT/init.vim\" | grep -v pcall"
  [ "$status" -ne 0 ]
}
