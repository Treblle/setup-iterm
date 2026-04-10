# iTerm2 + Shell Setup

A reproducible install script for my terminal setup on macOS.

## What's included

| Tool | Purpose |
|------|---------|
| [iTerm2](https://iterm2.com) | Terminal emulator |
| [JetBrains Mono Nerd Font](https://www.nerdfonts.com) | Font with icon support (16pt) |
| [oh-my-zsh](https://ohmyz.sh) | zsh framework (plugins: `git z extract colored-man-pages macos`) |
| [Pure](https://github.com/sindresorhus/pure) | Minimal async prompt via zplug |
| [eza](https://github.com/eza-community/eza) | Modern `ls` with icons and git status |
| [bat](https://github.com/sharkdp/bat) | `cat` with syntax highlighting |
| [ripgrep](https://github.com/BurntSushi/ripgrep) | Fast `grep` (`rg`) |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder (`Ctrl+T`, `Ctrl+R`, `Alt+C`) |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | Smart `cd` that learns your most-used dirs |
| [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Ghost completions from history |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Command validation highlighting |

## Install

```bash
bash install-iterm-setup.sh
```

The script is idempotent — safe to re-run. Requires macOS with internet access.

### After running

1. Restart iTerm2 (or open a new window)
2. On first launch zplug will prompt to install Pure — type `y`
3. Set the font manually: **iTerm2 → Preferences → Profiles → Default → Text → Font**
   - Font: `JetBrains Mono Nerd Font`
   - Size: `16`

## Aliases

```zsh
ls   → eza --icons
ll   → eza -la --icons --git
la   → eza -a --icons
cat  → bat --paging=never
grep → rg
```

## Key bindings (fzf)

| Shortcut | Action |
|----------|--------|
| `Ctrl+T` | Fuzzy search files and paste path |
| `Ctrl+R` | Fuzzy search command history |
| `Alt+C`  | Fuzzy cd into a subdirectory |
