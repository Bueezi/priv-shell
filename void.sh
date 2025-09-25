echo "max-transactions=10" | sudo tee /etc/xbps.d/xbps.conf
# adding repos
sudo xbps-install -Su void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree

echo "repository=https://github.com/index-0/librewolf-void/releases/latest/download/" | sudo tee /etc/xbps.d/20-librewolf.conf
# package groups
wifi="wifi-firmware"

igpu_driver="linux-firmware-amd mesa-dri vulkan-loader mesa-vulkan-radeon mesa-vaapi mesa-vdpau \
libglvnd-32bit mesa-dri-32bit vulkan-radeon-32bit libvulkan-32bit"

gnome="gnome-core alacritty baobab gnome-calculator gnome-tweaks loupe showtime papers \
power-profiles-daemon extension-manager gnome-system-monitor gnome-backgrounds"

apps="librewolf"

fonts="cantarell-fonts dejavu-fonts-ttf noto-fonts-emoji"

bash_tools="flatpak btop lm_sensors fastfetch vim"

audio_bt="pipewire wireplumber pipewire-pulse alsa-pipewire libjack-pipewire bluez libspa-bluetooth"

# collect everything
packages="$wifi $igpu_driver $gnome $apps $fonts $bash_tools $audio_bt"

# install
sudo xbps-install -Su $packages

sudo ln -s /etc/sv/dbus /var/service/
sudo ln -s /etc/sv/gdm /var/service/
sudo sv stop dhcpcd
sudo sv disable dhcpcd
sudo rm /var/service/dhcpcd
sudo ln -s /etc/sv/NetworkManager /var/service/
sudo ln -s /etc/sv/bluetoothd /var/service/
