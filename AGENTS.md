# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io). This repo is the
chezmoi source directory (`~/.local/share/chezmoi`); the target is `$HOME`.

## Workflow

- Never edit files in `$HOME` directly. Edit the source file in this repo, then
  run `chezmoi apply <target>` (for example `chezmoi apply ~/.zshrc`).
- Find the source file for a target with `chezmoi source-path ~/.zshrc`.
- Before changing anything, check for drift with `chezmoi status` and
  `chezmoi diff`. In the diff, `-` lines are the current file in `$HOME` and
  `+` lines are what the source would install.
- Resolving drift: if the `$HOME` copy holds the intended change, run
  `chezmoi re-add <target>`. If the source is intended, run `chezmoi apply`.
  Ask when it is unclear which side is right.
- `chezmoi apply` prompts when the target changed since chezmoi last wrote it.
  In a non-interactive shell pass `--force` only after reviewing the diff.
- After applying, confirm `chezmoi status` no longer lists the file, then commit.

## Naming conventions

- `dot_` prefix becomes a leading dot in the target name.
- `.tmpl` suffix marks a Go template rendered by chezmoi.
- Other chezmoi attributes (`private_`, `readonly_`, `executable_`,
  `symlink_`) follow the chezmoi docs.
- Any repo-only file at the root (`README.md`, `AGENTS.md`, `CLAUDE.md`) must be
  listed in `.chezmoiignore`, otherwise chezmoi installs it into `$HOME`.

## Secrets

- Never commit secrets. Templates read them from the environment, for example
  `env "FIGMA_ACCESS_TOKEN"`, or from chezmoi data such as `.bitbucket_token`.
- Chezmoi data is defined in `.chezmoi.toml.tmpl`, which prompts at
  `chezmoi init`. The rendered `~/.config/chezmoi/chezmoi.toml` is local and
  gitignored.
- `chezmoi diff` renders templates, so its output can contain secret values.
  Do not paste diff output into commits, docs, or chat logs.

## Claude Code settings

- `dot_claude/settings.json.tmpl` installs `~/.claude/settings.json`.
- Claude Code writes `model`, `voice`, and `theme` into that file on its own
  when a default is saved via `/model`, `/voice`, or `/config`. This repo is the
  source of truth: when drift appears there, decide whether to adopt the value
  into the template or re-apply the template.
