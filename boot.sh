#!/bin/bash

# Set install mode to online since boot.sh is used for curl installations
export AURA_ONLINE_INSTALL=true

ansi_art='
          ▄▄▄                         ▄▄▄
         █████   ██    ██  ██████    █████
        ██   ██  ██    ██  ██   ██  ██   ██
        ███████  ██    ██  ██████   ███████
        ██   ██  ██    ██  ██   ██  ██   ██
        ██   ██   ██████   ██   ██  ██   ██

    = Beautiful aesthetics meets powerful dev tools
'

clear
echo -e "\n$ansi_art\n"

sudo pacman -Syu --noconfirm --needed git

# Use custom repo if specified, otherwise default to cjlogic/aura-ambxst
AURA_REPO="${AURA_REPO:-cjlogic/aura-ambxst}"

echo -e "\nCloning Aura from: https://github.com/${AURA_REPO}.git"
rm -rf ~/.local/share/aura/
git clone "https://github.com/${AURA_REPO}.git" ~/.local/share/aura >/dev/null

# Use custom branch if instructed, otherwise default to -master
AURA_REF="${AURA_REF:-master}"
if [[ $AURA_REF != "-master" ]]; then
  echo -e "\e[32mUsing branch: $AURA_REF\e[0m"
  cd ~/.local/share/aura
  git fetch origin "${AURA_REF}" && git checkout "${AURA_REF}"
  cd -
fi

echo -e "\nInstallation starting..."
source ~/.local/share/aura/install.sh
