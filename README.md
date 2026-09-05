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
