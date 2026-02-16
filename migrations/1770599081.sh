#!/bin/bash

# Add kernel upgrade protection: snap-pac for automatic snapshots + snapper config for ASUS

set -e

echo "Configuring kernel upgrade protection (snap-pac + snapper)..."

# Install snap-pac for automatic before/after snapshots on every pacman transaction
sudo pacman -S --noconfirm --needed snap-pac

# Detect hardware and bootloader
IS_ASUS=false
if cat /sys/class/dmi/id/sys_vendor 2>/dev/null | grep -qi "ASUSTeK"; then
  IS_ASUS=true
fi

# ASUS/systemd-boot systems need snapper configured (Limine path already handles this)
if [[ "$IS_ASUS" == "true" ]] && command -v bootctl &>/dev/null; then
  if ! sudo snapper list-configs 2>/dev/null | grep -q "root"; then
    sudo snapper -c root create-config /
  fi

  if ! sudo snapper list-configs 2>/dev/null | grep -q "home"; then
    sudo snapper -c home create-config /home
  fi

  sudo btrfs quota enable / 2>/dev/null || true

  # Tweak Snapper configs
  sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/{root,home} 2>/dev/null || true
  sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/{root,home} 2>/dev/null || true
  sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/{root,home} 2>/dev/null || true
  sudo sed -i 's/^SPACE_LIMIT="0.5"/SPACE_LIMIT="0.3"/' /etc/snapper/configs/{root,home} 2>/dev/null || true
  sudo sed -i 's/^FREE_LIMIT="0.2"/FREE_LIMIT="0.3"/' /etc/snapper/configs/{root,home} 2>/dev/null || true

  echo "✓ Snapper configured for ASUS/systemd-boot"
fi

echo "✓ Kernel upgrade protection configured (snap-pac active)"
