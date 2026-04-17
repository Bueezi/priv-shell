echo -n "What WM do u want gnome or sway ? (gnome/sway): " && read wm


echo "max-transactions=10" | sudo tee /etc/xbps.d/xbps.conf
# adding repos
sudo xbps-install -Su void-repo-nonfree void-repo-multilib void-repo-multilib-nonfree

echo "repository=https://github.com/index-0/librewolf-void/releases/latest/download/" | sudo tee /etc/xbps.d/20-librewolf.conf
# package groups
wifi="wifi-firmware"

igpu_driver="linux-firmware-amd mesa-dri vulkan-loader mesa-vulkan-radeon mesa-vaapi mesa-vdpau \
libglvnd-32bit mesa-dri-32bit vulkan-radeon-32bit libvulkan-32bit"


if [ "$wm" == "sway" ]; then
  wm_packages="sway swaybg foot fuzzel mako polkit-gnome brightnessctl network-manager-applet networkmanager-dmenu \
   blueman wl-clipboard cliphist swaylock swayidle xorg-xwayland xdg-desktop-portal-wlr seatd polkit nwg-look \
   i3status-rust grim slurp thunar"
elif [ "$wm" == "gnome" ]; then
  wm_packages="dbus gnome-core alacritty baobab gnome-calculator gnome-tweaks loupe showtime papers \
  power-profiles-daemon extension-manager gnome-system-monitor gnome-backgrounds gsound"
fi

apps="librewolf"

fonts="cantarell-fonts dejavu-fonts-ttf noto-fonts-emoji"

bash_tools="flatpak btop lm_sensors fastfetch vim"

audio_bt="pipewire wireplumber pipewire-pulse alsa-pipewire libjack-pipewire bluez libspa-bluetooth"

# collect everything
packages="$wifi $igpu_driver $gnome $apps $fonts $bash_tools $audio_bt"

# install
sudo xbps-install -Su $packages

"""
sudo ln -s /etc/sv/dbus /var/service/
sudo ln -s /etc/sv/gdm /var/service/
sudo sv stop dhcpcd
sudo sv disable dhcpcd
sudo rm /var/service/dhcpcd
sudo ln -s /etc/sv/NetworkManager /var/service/
sudo ln -s /etc/sv/bluetoothd /var/service/
"""
