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
  chmod +x "$BATS_TEST_TMPDIR"/bin/*

  cd "$BATS_TEST_TMPDIR/repo" || return 1
  git init -q
}

config_dir() {
  echo "$HOME/.config/gh-projects/myproject"
}

@test "defaults the name to the repo folder" {
  run "$SCRIPT" <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  grep -qx "GH_CONFIG_DIR=$HOME/.config/gh-projects/repo gh auth status" "$GH_LOG"
}

@test "rejects a repo folder name that is not a valid name" {
  mkdir "$BATS_TEST_TMPDIR/my repo" && cd "$BATS_TEST_TMPDIR/my repo" && git init -q
  run "$SCRIPT" <<<"$FAKE_TOKEN"
  [ "$status" -ne 0 ]
  [[ "$output" == *"'my repo' is not a valid name"* ]]
  [ ! -e "$GH_LOG" ]
}

@test "rejects a name with a slash" {
  run "$SCRIPT" ../escape <<<"$FAKE_TOKEN"
  [ "$status" -ne 0 ]
  [ ! -e "$GH_LOG" ]
  [ ! -e "$HOME/.config/escape" ]
}

@test "fails outside a git repo" {
  cd "$BATS_TEST_TMPDIR"
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -ne 0 ]
  [[ "$output" == *"git repo"* ]]
}

@test "fails when no token is given" {
  run "$SCRIPT" myproject </dev/null
  [ "$status" -ne 0 ]
  [[ "$output" == *"no token"* ]]
  [ ! -e .claude/settings.local.json ]
}

@test "creates a private config dir" {
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  [ "$(stat -f %Lp "$(config_dir)")" = 700 ]
}

@test "logs in with the token into the project config dir" {
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  grep -qx "GH_CONFIG_DIR=$(config_dir) gh auth login --with-token --insecure-storage" "$GH_LOG"
  grep -qx "stdin=$FAKE_TOKEN" "$GH_LOG"
}

@test "does not print the token" {
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [[ "$output" != *"$FAKE_TOKEN"* ]]
}

@test "creates settings.local.json at the repo root" {
  mkdir sub && cd sub
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  [ "$(jq -r .env.GH_CONFIG_DIR ../.claude/settings.local.json)" = "$(config_dir)" ]
}

@test "keeps existing keys in settings.local.json" {
  mkdir .claude
  echo '{"model":"x","env":{"FOO":"bar"}}' > .claude/settings.local.json
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  [ "$(jq -r .model .claude/settings.local.json)" = x ]
  [ "$(jq -r .env.FOO .claude/settings.local.json)" = bar ]
  [ "$(jq -r .env.GH_CONFIG_DIR .claude/settings.local.json)" = "$(config_dir)" ]
}

@test "shows auth status for the project" {
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  grep -qx "GH_CONFIG_DIR=$(config_dir) gh auth status" "$GH_LOG"
}

@test "leaves settings alone when login fails" {
  printf '#!/bin/sh\necho "bad token" >&2\nexit 1\n' > "$BATS_TEST_TMPDIR/bin/gh"
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -ne 0 ]
  [ ! -e .claude/settings.local.json ]
}

@test "keeps invalid settings.local.json untouched and leaves no temp file" {
  mkdir .claude
  echo 'not json' > .claude/settings.local.json
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -ne 0 ]
  [ "$(cat .claude/settings.local.json)" = "not json" ]
  [ ! -e .claude/settings.local.json.tmp ]
}

@test "rerunning restores permissions and keeps the config dir" {
  "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  chmod 755 "$(config_dir)"
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  [ "$(stat -f %Lp "$(config_dir)")" = 700 ]
  [ "$(jq -r .env.GH_CONFIG_DIR .claude/settings.local.json)" = "$(config_dir)" ]
  [ "$(grep -c 'gh auth login' "$GH_LOG")" = 2 ]
}

@test "fails when the token is not fine-grained" {
  run "$SCRIPT" myproject <<<"ghp_classic"
  [ "$status" -ne 0 ]
  [[ "$output" == *github_pat_* ]]
  [ ! -e "$GH_LOG" ]
}

@test "strips whitespace around the token" {
  run "$SCRIPT" myproject <<<"  $FAKE_TOKEN  "
  [ "$status" -eq 0 ]
  grep -qx "stdin=$FAKE_TOKEN" "$GH_LOG"
}

@test "accepts piped input without a final newline" {
  run bash -c 'printf %s "$FAKE_TOKEN" | "$0" myproject' "$SCRIPT"
  [ "$status" -eq 0 ]
  grep -qx "stdin=$FAKE_TOKEN" "$GH_LOG"
}

@test "rejects . and .. as names" {
  run "$SCRIPT" . <<<"$FAKE_TOKEN"
  [ "$status" -ne 0 ]
  run "$SCRIPT" .. <<<"$FAKE_TOKEN"
  [ "$status" -ne 0 ]
  [ ! -e "$GH_LOG" ]
}

@test "fills in an empty settings.local.json" {
  mkdir .claude
  : > .claude/settings.local.json
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  [ "$(jq -r .env.GH_CONFIG_DIR .claude/settings.local.json)" = "$(config_dir)" ]
}

@test "creates the parent config dir as private" {
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  [ "$(stat -f %Lp "$HOME/.config/gh-projects")" = 700 ]
}

@test "lets the sandbox read only this project's config dir" {
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  [ "$(jq -c .sandbox.filesystem.allowRead .claude/settings.local.json)" = "[\"$(config_dir)\"]" ]
}

@test "keeps other allowRead entries and does not repeat its own" {
  mkdir .claude
  echo '{"sandbox":{"filesystem":{"allowRead":["/opt/data"]}}}' > .claude/settings.local.json
  "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  [ "$(jq -c .sandbox.filesystem.allowRead .claude/settings.local.json)" = "[\"/opt/data\",\"$(config_dir)\"]" ]
}

@test "drops the old project's folder when the name changes" {
  "$SCRIPT" oldname <<<"$FAKE_TOKEN"
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  [ "$(jq -c .sandbox.filesystem.allowRead .claude/settings.local.json)" = "[\"$(config_dir)\"]" ]
}

@test "keeps other sandbox settings" {
  mkdir .claude
  echo '{"sandbox":{"enabled":true,"network":{"allowedDomains":["example.com"]},"filesystem":{"denyRead":["/secret"]}}}' > .claude/settings.local.json
  run "$SCRIPT" myproject <<<"$FAKE_TOKEN"
  [ "$status" -eq 0 ]
  [ "$(jq -c '.sandbox | del(.filesystem.allowRead)' .claude/settings.local.json)" = '{"enabled":true,"network":{"allowedDomains":["example.com"]},"filesystem":{"denyRead":["/secret"]}}' ]
}
