#!/bin/bash
# =============================================================================
# iTerm2 + Shell Setup Installer
# =============================================================================
# Reproduces the following setup:
#   - iTerm2 with JetBrains Mono Nerd Font (16pt)
#   - zsh + oh-my-zsh + Pure prompt (via zplug)
#   - oh-my-zsh plugins: git, z, extract, colored-man-pages, macos
#   - Modern CLI replacements: eza, bat, ripgrep, fzf, zoxide
#   - zsh-autosuggestions + zsh-syntax-highlighting
# =============================================================================

set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()    { echo -e "${GREEN}==>${NC} ${BOLD}$1${NC}"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }

# -----------------------------------------------------------------------------
# 1. Homebrew
# -----------------------------------------------------------------------------
info "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon path
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "  Homebrew already installed."
fi

# -----------------------------------------------------------------------------
# 2. iTerm2
# -----------------------------------------------------------------------------
info "Installing iTerm2..."
brew install --cask iterm2 2>/dev/null || echo "  iTerm2 already installed."

# -----------------------------------------------------------------------------
# 3. Font: JetBrains Mono Nerd Font
# -----------------------------------------------------------------------------
info "Installing JetBrains Mono Nerd Font..."
brew install --cask font-jetbrains-mono-nerd-font 2>/dev/null || echo "  Font already installed."

# -----------------------------------------------------------------------------
# 4. zsh (macOS ships with zsh, but ensure it's Homebrew's for consistency)
# -----------------------------------------------------------------------------
info "Checking zsh..."
if ! brew list zsh &>/dev/null; then
  brew install zsh
fi
# Set zsh as default shell if not already
if [[ "$SHELL" != *"zsh"* ]]; then
  info "Setting zsh as default shell..."
  ZSH_PATH="$(brew --prefix)/bin/zsh"
  if ! grep -qF "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
  fi
  chsh -s "$ZSH_PATH"
fi

# -----------------------------------------------------------------------------
# 5. oh-my-zsh
# -----------------------------------------------------------------------------
info "Installing oh-my-zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no CHSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "  oh-my-zsh already installed."
fi

# -----------------------------------------------------------------------------
# 6. zplug (plugin manager for Pure theme)
# -----------------------------------------------------------------------------
info "Installing zplug..."
brew install zplug 2>/dev/null || echo "  zplug already installed."

# -----------------------------------------------------------------------------
# 7. Modern CLI tools
# -----------------------------------------------------------------------------
info "Installing modern CLI tools..."
PACKAGES=(
  fzf               # fuzzy finder (Ctrl+T, Ctrl+R, Alt+C)
  zoxide            # smart cd — learns your most-used dirs
  zsh-autosuggestions   # grey ghost completions from history
  zsh-syntax-highlighting  # red = bad command, green = good
  eza               # modern ls with icons and git status
  bat               # cat with syntax highlighting
  ripgrep           # fast grep (rg)
)

for pkg in "${PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    echo "  $pkg already installed."
  else
    brew install "$pkg"
  fi
done

# fzf shell integration (key bindings + completions)
if [ -f "$(brew --prefix)/opt/fzf/install" ]; then
  info "Setting up fzf key bindings..."
  "$(brew --prefix)/opt/fzf/install" --key-bindings --completion --no-update-rc
fi

# -----------------------------------------------------------------------------
# 8. Write .zshrc
# -----------------------------------------------------------------------------
info "Writing ~/.zshrc..."

ZSHRC="$HOME/.zshrc"
BREW_PREFIX="$(brew --prefix)"

cat > "$ZSHRC" << 'ZSHRC_CONTENT'
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# No built-in theme — Pure is loaded via zplug below
ZSH_THEME=""

# oh-my-zsh plugins
plugins=(git z extract colored-man-pages macos)

source $ZSH/oh-my-zsh.sh

# ── zplug + Pure prompt ──────────────────────────────────────────────────────
export ZPLUG_HOME=$(brew --prefix)/opt/zplug
source $ZPLUG_HOME/init.zsh

zplug "mafredri/zsh-async", from:github
zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme

zplug load

if ! zplug check --verbose; then
    printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# ── PATH ─────────────────────────────────────────────────────────────────────
export PATH="$HOME/.composer/vendor/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Java (OpenJDK 21 via Homebrew)
export JAVA_HOME=$(brew --prefix)/opt/openjdk@21
export PATH="$JAVA_HOME/bin:$PATH"

# ── Claude Code ───────────────────────────────────────────────────────────────
export DISABLE_AUTOUPDATER=1   # managed by Homebrew, skip built-in updater

# ── Modern CLI tools ─────────────────────────────────────────────────────────

# fzf: fuzzy finder (Ctrl+T files, Ctrl+R history, Alt+C cd)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zoxide: smart cd (replaces z/autojump) — use: z <partial-dir>
eval "$(zoxide init zsh)"

# zsh-autosuggestions: ghost completions from history — → to accept
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# zsh-syntax-highlighting: green = valid command, red = not found
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# ── Aliases ───────────────────────────────────────────────────────────────────
alias ls='eza --icons'
alias ll='eza -la --icons --git'
alias la='eza -a --icons'
alias cat='bat --paging=never'
alias grep='rg'
alias python=python3
ZSHRC_CONTENT

echo "  ~/.zshrc written."

# -----------------------------------------------------------------------------
# 9. Write .zprofile (Homebrew env init — required on Apple Silicon)
# -----------------------------------------------------------------------------
info "Writing ~/.zprofile..."
cat > "$HOME/.zprofile" << 'ZPROFILE_CONTENT'
eval "$(/opt/homebrew/bin/brew shellenv)"
ZPROFILE_CONTENT
echo "  ~/.zprofile written."

# -----------------------------------------------------------------------------
# 10. iTerm2 preferences
# -----------------------------------------------------------------------------
info "Configuring iTerm2 preferences..."

# Set font to JetBrains Mono Nerd Font 16pt in the Default profile
# (This patches the live defaults — open iTerm2 after running this script)
PROFILE_GUID=$(defaults read com.googlecode.iterm2 'New Bookmarks' 2>/dev/null \
  | grep -A2 '"Name" = "Default"' | grep "Guid" | sed 's/.*= "\(.*\)".*/\1/' | head -1 || true)

defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "$PROFILE_GUID" 2>/dev/null || true

# Point iTerm2 to load prefs from this directory if you want shared config:
# defaults write com.googlecode.iterm2 PrefsCustomFolder -string "$(pwd)"
# defaults write com.googlecode.iterm2 LoadPrefsFromCustomFolder -bool true

warning "Font will be applied the first time you open iTerm2 after install."
warning "In iTerm2: Preferences > Profiles > Default > Text > Font → JetBrainsMonoNFM-Regular 16"

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
echo ""
echo -e "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Restart your terminal (or open a new iTerm2 window)"
echo "  2. On first launch, zplug will prompt to install Pure — type y"
echo "  3. In iTerm2 → Preferences → Profiles → Default → Text:"
echo "       Set font to: JetBrains Mono Nerd Font, size 16"
echo ""
echo "Key features installed:"
echo "  eza   → ls / ll / la  (icons + git status)"
echo "  bat   → cat           (syntax highlighting)"
echo "  rg    → grep          (fast ripgrep)"
echo "  fzf   → Ctrl+T / Ctrl+R / Alt+C"
echo "  zoxide→ z <partial>   (smart directory jumping)"
echo "  Pure  → minimal async prompt"
