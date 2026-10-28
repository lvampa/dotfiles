#!/usr/bin/env bats

SCRIPT="$BATS_TEST_DIRNAME/../dot_local/bin/executable_gh-project"

setup() {
  export HOME="$BATS_TEST_TMPDIR/home"
  export GH_LOG="$BATS_TEST_TMPDIR/gh.log"
  export FAKE_TOKEN="github_pat_fake"
  mkdir -p "$HOME" "$BATS_TEST_TMPDIR/bin" "$BATS_TEST_TMPDIR/repo"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"

  # The fake gh records its config dir, arguments, and stdin so tests can check the login call.
  cat > "$BATS_TEST_TMPDIR/bin/gh" <<'EOF'
#!/bin/sh
echo "GH_CONFIG_DIR=$GH_CONFIG_DIR gh $*" >> "$GH_LOG"
if [ "$1 $2" = "auth login" ]; then
  echo "stdin=$(cat)" >> "$GH_LOG"
fi
EOF
  cat > "$BATS_TEST_TMPDIR/bin/pbpaste" <<'EOF'
#!/bin/sh
printf '%s' "$FAKE_TOKEN"
EOF
  cat > "$BATS_TEST_TMPDIR/bin/pbcopy" <<'EOF'
#!/bin/sh
echo "pbcopy=$(cat)" >> "$GH_LOG"
EOF
  chmod +x "$BATS_TEST_TMPDIR"/bin/*

  cd "$BATS_TEST_TMPDIR/repo" || return 1
  git init -q
}

config_dir() {
  echo "$HOME/.config/gh-projects/myproject"
}

@test "fails without a project name" {
  run "$SCRIPT"
  [ "$status" -ne 0 ]
  [[ "$output" == *usage* ]]
}

@test "rejects a name with a slash" {
  run "$SCRIPT" ../escape
  [ "$status" -ne 0 ]
  [ ! -e "$HOME/.config/escape" ]
}

@test "fails outside a git repo" {
  cd "$BATS_TEST_TMPDIR"
  run "$SCRIPT" myproject
  [ "$status" -ne 0 ]
  [[ "$output" == *"git repo"* ]]
}

@test "fails when the clipboard is empty" {
  printf '#!/bin/sh\n' > "$BATS_TEST_TMPDIR/bin/pbpaste"
  run "$SCRIPT" myproject
  [ "$status" -ne 0 ]
  [[ "$output" == *clipboard* ]]
  [ ! -e .claude/settings.local.json ]
}

@test "creates a private config dir" {
  run "$SCRIPT" myproject
  [ "$status" -eq 0 ]
  [ "$(stat -f %Lp "$(config_dir)")" = 700 ]
}

@test "logs in with the clipboard token into the project config dir" {
  run "$SCRIPT" myproject
  [ "$status" -eq 0 ]
  grep -qx "GH_CONFIG_DIR=$(config_dir) gh auth login --with-token --insecure-storage" "$GH_LOG"
  grep -qx "stdin=$FAKE_TOKEN" "$GH_LOG"
}

@test "does not print the token" {
  run "$SCRIPT" myproject
  [[ "$output" != *"$FAKE_TOKEN"* ]]
}

@test "creates settings.local.json at the repo root" {
  mkdir sub && cd sub
  run "$SCRIPT" myproject
  [ "$status" -eq 0 ]
  [ "$(jq -r .env.GH_CONFIG_DIR ../.claude/settings.local.json)" = "$(config_dir)" ]
}

@test "keeps existing keys in settings.local.json" {
  mkdir .claude
  echo '{"model":"x","env":{"FOO":"bar"}}' > .claude/settings.local.json
  run "$SCRIPT" myproject
  [ "$status" -eq 0 ]
  [ "$(jq -r .model .claude/settings.local.json)" = x ]
  [ "$(jq -r .env.FOO .claude/settings.local.json)" = bar ]
  [ "$(jq -r .env.GH_CONFIG_DIR .claude/settings.local.json)" = "$(config_dir)" ]
}

@test "shows auth status for the project" {
  run "$SCRIPT" myproject
  grep -qx "GH_CONFIG_DIR=$(config_dir) gh auth status" "$GH_LOG"
}

@test "leaves settings alone when login fails" {
  printf '#!/bin/sh\necho "bad token" >&2\nexit 1\n' > "$BATS_TEST_TMPDIR/bin/gh"
  run "$SCRIPT" myproject
  [ "$status" -ne 0 ]
  [ ! -e .claude/settings.local.json ]
}

@test "keeps invalid settings.local.json untouched and leaves no temp file" {
  mkdir .claude
  echo 'not json' > .claude/settings.local.json
  run "$SCRIPT" myproject
  [ "$status" -ne 0 ]
  [ "$(cat .claude/settings.local.json)" = "not json" ]
  [ ! -e .claude/settings.local.json.tmp ]
}

@test "rerunning restores permissions and keeps the config dir" {
  "$SCRIPT" myproject
  chmod 755 "$(config_dir)"
  run "$SCRIPT" myproject
  [ "$status" -eq 0 ]
  [ "$(stat -f %Lp "$(config_dir)")" = 700 ]
  [ "$(jq -r .env.GH_CONFIG_DIR .claude/settings.local.json)" = "$(config_dir)" ]
  [ "$(grep -c 'gh auth login' "$GH_LOG")" = 2 ]
}

@test "fails when the clipboard is not a fine-grained token" {
  printf '#!/bin/sh\necho some other text\n' > "$BATS_TEST_TMPDIR/bin/pbpaste"
  run "$SCRIPT" myproject
  [ "$status" -ne 0 ]
  [[ "$output" == *github_pat_* ]]
  [ ! -e "$GH_LOG" ]
}

@test "clears the clipboard after login" {
  run "$SCRIPT" myproject
  [ "$status" -eq 0 ]
  grep -qx "pbcopy=" "$GH_LOG"
}

@test "fills in an empty settings.local.json" {
  mkdir .claude
  : > .claude/settings.local.json
  run "$SCRIPT" myproject
  [ "$status" -eq 0 ]
  [ "$(jq -r .env.GH_CONFIG_DIR .claude/settings.local.json)" = "$(config_dir)" ]
}

@test "creates the parent config dir as private" {
  run "$SCRIPT" myproject
  [ "$status" -eq 0 ]
  [ "$(stat -f %Lp "$HOME/.config/gh-projects")" = 700 ]
}
