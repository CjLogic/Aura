#!/bin/bash
# systemd-boot configuration for ASUS hardware
# ASUS/AMI firmware works better with systemd-boot than GRUB/Limine

# Only run on ASUS hardware
IS_ASUS=false
if cat /sys/class/dmi/id/sys_vendor 2>/dev/null | grep -qi "ASUSTeK"; then
  IS_ASUS=true
fi

if [[ "$IS_ASUS" != "true" ]]; then
  echo "Not ASUS hardware - skipping systemd-boot ASUS configuration"
  exit 0
fi

# Only run on systemd-boot installations
if ! command -v bootctl &>/dev/null; then
  echo "systemd-boot not installed - skipping"
  exit 0
fi

echo "Configuring systemd-boot for ASUS compatibility..."

# Configure mkinitcpio hooks (same as Limine but without limine-specific hooks)
sudo tee /etc/mkinitcpio.conf.d/aura_hooks.conf <<EOF >/dev/null
HOOKS=(base udev plymouth keyboard autodetect microcode modconf kms keymap consolefont block encrypt filesystems fsck)
EOF

sudo tee /etc/mkinitcpio.conf.d/thunderbolt_module.conf <<EOF >/dev/null
MODULES+=(thunderbolt)
EOF

# Install snap-pac for automatic before/after snapshots on every pacman transaction
sudo pacman -S --noconfirm --needed snap-pac

# Configure Snapper for btrfs snapshot management
if [[ -z ${AURA_CHROOT_INSTALL:-} ]]; then
  if ! sudo snapper list-configs 2>/dev/null | grep -q "root"; then
    sudo snapper -c root create-config /
  fi

  if ! sudo snapper list-configs 2>/dev/null | grep -q "home"; then
    sudo snapper -c home create-config /home
  fi
fi

# Enable btrfs quota for space-aware snapshot cleanup
sudo btrfs quota enable / 2>/dev/null || true

# Tweak Snapper configs (same values as Limine path)
sudo sed -i 's/^TIMELINE_CREATE="yes"/TIMELINE_CREATE="no"/' /etc/snapper/configs/{root,home} 2>/dev/null || true
sudo sed -i 's/^NUMBER_LIMIT="50"/NUMBER_LIMIT="5"/' /etc/snapper/configs/{root,home} 2>/dev/null || true
sudo sed -i 's/^NUMBER_LIMIT_IMPORTANT="10"/NUMBER_LIMIT_IMPORTANT="5"/' /etc/snapper/configs/{root,home} 2>/dev/null || true
sudo sed -i 's/^SPACE_LIMIT="0.5"/SPACE_LIMIT="0.3"/' /etc/snapper/configs/{root,home} 2>/dev/null || true
sudo sed -i 's/^FREE_LIMIT="0.2"/FREE_LIMIT="0.3"/' /etc/snapper/configs/{root,home} 2>/dev/null || true

echo "✓ Snapper configured for automatic pacman snapshots"

# Customize systemd-boot configuration
sudo tee /boot/loader/loader.conf <<EOF >/dev/null
timeout 0
default @saved
console-mode max
editor no
EOF

echo "✓ systemd-boot loader configuration updated"

# Rebuild initramfs with updated hooks (includes plymouth)
sudo mkinitcpio -P
echo "✓ Initramfs rebuilt with plymouth support"

# Update boot entries with Aura branding
echo "Updating boot entry titles..."

# Find and update the main boot entry
BOOT_ENTRY=$(find /boot/loader/entries -name "*.conf" -type f | grep -v "fallback" | head -n1)

if [[ -f "$BOOT_ENTRY" ]]; then
  # Update title to Aura branding
  sudo sed -i 's/^title.*/title Aura/' "$BOOT_ENTRY"

  # Add Plymouth parameters (splash quiet) if not already present
  if ! grep -q "splash" "$BOOT_ENTRY"; then
    sudo sed -i '/^options/ s/$/ splash quiet/' "$BOOT_ENTRY"
    echo "✓ Added Plymouth parameters (splash quiet)"
  fi

  # Add NVIDIA DRM modeset parameter if not already present
  if ! grep -q "nvidia-drm.modeset=1" "$BOOT_ENTRY"; then
    sudo sed -i '/^options/ s/$/ nvidia-drm.modeset=1/' "$BOOT_ENTRY"
    echo "✓ Added NVIDIA DRM modeset parameter"
  fi

  echo "✓ Boot entry updated: $BOOT_ENTRY"
fi

# Find and update the fallback boot entry
FALLBACK_ENTRY=$(find /boot/loader/entries -name "*fallback*.conf" -type f | head -n1)

if [[ -f "$FALLBACK_ENTRY" ]]; then
  # Update fallback title
  sudo sed -i 's/^title.*/title Aura (fallback)/' "$FALLBACK_ENTRY"

  # Add Plymouth parameters to fallback too
  if ! grep -q "splash" "$FALLBACK_ENTRY"; then
    sudo sed -i '/^options/ s/$/ splash quiet/' "$FALLBACK_ENTRY"
    echo "✓ Added Plymouth parameters to fallback"
  fi

  # Add NVIDIA DRM modeset parameter to fallback if not already present
  if ! grep -q "nvidia-drm.modeset=1" "$FALLBACK_ENTRY"; then
    sudo sed -i '/^options/ s/$/ nvidia-drm.modeset=1/' "$FALLBACK_ENTRY"
    echo "✓ Added NVIDIA DRM modeset parameter to fallback"
  fi

  echo "✓ Fallback entry updated: $FALLBACK_ENTRY"
fi

# Re-enable mkinitcpio hooks (they were disabled during install for performance)
echo "Re-enabling mkinitcpio hooks..."

if [ -f /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled ]; then
  sudo mv /usr/share/libalpm/hooks/90-mkinitcpio-install.hook.disabled /usr/share/libalpm/hooks/90-mkinitcpio-install.hook
fi

if [ -f /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled ]; then
  sudo mv /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook.disabled /usr/share/libalpm/hooks/60-mkinitcpio-remove.hook
fi

echo "✓ mkinitcpio hooks re-enabled"

# Ensure NVRAM entry exists and is set as default
if [[ -d /sys/firmware/efi ]]; then
  echo "Configuring EFI boot entries..."

  # Update systemd-boot in ESP
  sudo bootctl update

  # Check if NVRAM entry exists
  if efibootmgr | grep -qi "Linux Boot Manager"; then
    echo "✓ NVRAM entry 'Linux Boot Manager' exists"
  else
    echo "⚠ NVRAM entry not found - AMI firmware may not preserve boot order"
    echo "  Fallback bootloader at /boot/EFI/BOOT/BOOTX64.EFI will be used"
  fi

  # Show current boot order
  echo ""
  echo "Current EFI boot configuration:"
  efibootmgr | head -n 10
fi

echo ""
echo "✓ systemd-boot configured for ASUS hardware"
echo "  Bootloader: systemd-boot (ASUS-compatible)"
echo "  Timeout: 0 (hold SPACE during boot for menu)"
echo "  Plymouth: enabled (splash quiet)"
echo "  NVIDIA DRM: modeset enabled (nvidia-drm.modeset=1)"
echo "  Snapper: configured (root + home)"
echo "  snap-pac: automatic before/after snapshots on pacman transactions"
echo "  Editor: disabled (security)"
