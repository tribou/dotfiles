setup() {
  load 'test_helper/common_setup'
  common_setup
}

@test "macOS workflow is valid YAML" {
  run ruby -e 'require "yaml"; YAML.load_file(ARGV.fetch(0), aliases: true)' \
    "$REPO_ROOT/.github/workflows/macos-tests.yml"
  assert_success
}
