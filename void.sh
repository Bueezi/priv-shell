# adding repos
sudo xbps-install -Su void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree

sudo echo "repository=https://github.com/index-0/librewolf-void/releases/latest/download/" > /etc/xbps.d/20-librewolf.conf

# network driver
sudo xbps-install -Su wifi-firmware
# amd iGPU driver
sudo xbps-install -Su linux-firmware-amd mesa-dri vulkan-loader mesa-vulkan-radeon mesa-vaapi mesa-vdpau
sudo xbps-install -Su libglvnd-32bit mesa-dri-32bit
# gnome install
sudo xbps-install -Su gnome-core alacritty baobab gnome-calculator gnome-tweaks loupe showtime papers power-profiles-daemon extension-manager gnome-system-monitor gnome-backgrounds

# apps
sudo xbps-install -Su librewolf

# fonts
sudo xbps-install -Su cantarell-fonts dejavu-fonts-ttf noto-fonts-emoji

# bash tools
sudo xbps-install -Su flatpak btop lm_sensors fastfetch vim

# audio & bluetooth
sudo xbps-install pipewire wireplumber pipewire-pulse alsa-pipewire libjack-pipewire bluez libspa-bluetooth

sudo ln -s /etc/sv/dbus /var/service/
sudo ln -s /etc/sv/gdm /var/service/
sudo sv stop dhcpcd
sudo sv disable dhcpcd
sudo ln -s /etc/sv/NetworkManager /var/service/
sudo ln -s /etc/sv/bluetoothd /var/service/
