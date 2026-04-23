#!/usr/bin/env bash

set -e

sudo -v

# ---- CONFIG ----
DEFAULT_THEME="af-magic"

# ---- 0. SYSTEM UPDATE (APT ONLY) ----
if command -v apt >/dev/null 2>&1; then
  echo "Updating package lists..."
  sudo apt update
fi

# ---- 1. ASK FOR ZSH THEME ----
read -rp "Enter Zsh theme [${DEFAULT_THEME}]: " ZSH_THEME
ZSH_THEME="${ZSH_THEME:-$DEFAULT_THEME}"

echo "Using theme: $ZSH_THEME"

# ---- 2. INSTALL ZSH ----
if ! command -v zsh >/dev/null 2>&1; then
  echo "Installing zsh..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt install -y zsh
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y zsh
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm zsh
  else
    echo "Unsupported package manager. Install zsh manually."
    exit 1
  fi
else
  echo "Zsh already installed."
fi

# ---- 3. SET DEFAULT SHELL ----
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "Changing default shell to zsh..."
  chsh -s "$(which zsh)" "$USER" || echo "You may need to log out/in or run with sudo privileges"
fi

# ---- 4. INSTALL OH-MY-ZSH ----
OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"

if [ ! -d "$OH_MY_ZSH_DIR" ]; then
  echo "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed."
fi

# ---- 5. SET ZSH THEME ----
ZSHRC="$HOME/.zshrc"

if [ -f "$ZSHRC" ]; then
  echo "Setting Zsh theme..."
  sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$ZSH_THEME\"/" "$ZSHRC" || true
fi

# ---- 6. INSTALL FASTFETCH ----
if ! command -v fastfetch >/dev/null 2>&1; then
  echo "Installing fastfetch..."
  if command -v apt >/dev/null 2>&1; then
    sudo apt install -y fastfetch 2>/dev/null || {
      echo "fastfetch not found in repo, installing via GitHub release..."
      curl -L https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb -o fastfetch.deb
      sudo dpkg -i fastfetch.deb || sudo apt -f install -y
      rm fastfetch.deb
    }
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf install -y fastfetch
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm fastfetch
  else
    echo "Please install fastfetch manually: https://github.com/fastfetch-cli/fastfetch"
  fi
else
  echo "fastfetch already installed."
fi

# ---- 7. ADD FASTFETCH TO ZSHRC ----
if [ -f "$ZSHRC" ]; then
  if ! grep -q "fastfetch" "$ZSHRC"; then
    echo "Adding fastfetch to .zshrc..."
    echo -e "\n# Run fastfetch on shell start\nfastfetch\n" >> "$ZSHRC"
  else
    echo "fastfetch already in .zshrc"
  fi
fi

# ---- 8. HUSHLOGIN ----
touch "$HOME/.hushlogin"

echo "Done. Restart terminal or run: exec zsh"
