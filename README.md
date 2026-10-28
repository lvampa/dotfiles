# dotfiles

Personal dotfiles managed with [chezmoi](https://chezmoi.io).

## Setup

```sh
chezmoi init lvampa
chezmoi apply
```

## Common commands

```sh
chezmoi add ~/.zshrc        # track a new file
chezmoi edit ~/.zshrc       # edit a tracked file
chezmoi apply               # apply changes to home directory
chezmoi diff                # preview changes before applying
chezmoi update              # pull latest and apply
```

## Per-project GitHub access

`gh-project` gives Claude Code in one repo its own `gh` login.
Claude uses it to open and review PRs and check workflow runs and deployments.
Git keeps using your SSH key.

Create a fine-grained token scoped to that repo with these permissions:

- Pull requests: read and write.
- Contents, Actions, Deployments, and Commit statuses: read.

Run this in the repo and paste the token when asked:

```sh
gh-project
```

The name defaults to the repo folder name, and the token is stored in `~/.config/gh-projects/<name>`.
The repo's `.claude/settings.local.json` gets `GH_CONFIG_DIR` and a sandbox read exception for that folder only.
Restart Claude Code in the repo afterwards.
Run it again with a new token when the old one expires.

## Tests

```sh
bats tests/
shellcheck dot_local/bin/executable_gh-project tests/*.bats
```
