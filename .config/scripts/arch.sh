#!/bin/bash
# iwctl
#	station <device> connect "SSID"
# ping 8.8.8.8
# timedatectl

# gdisk, cryptsetup, mkfs

echo -n "Root Pass : " && read root_pass
echo -n "Username : " && read usr_name
echo -n "Are u using intel, amd or nvidia ? (i/a/n): " && read hardware
echo -n "Do you want linux-zen? (y/n)" && read kernel_zen
echo -n "What WM do u want gnome or sway ? (gnome/sway): " && read wm

lsblk && echo -e "-------------------------------------\nDisks :" && lsblk | grep disk && echo -e "\n\n\n"

echo -n "Proceed ? (y/n) : " && read proceed

if [ "$proceed" != "y" ]; then
    echo "Aborting."
    exit 1
fi

LUKS_UUID=$(cryptsetup luksUUID $(cryptsetup status cryptroot | grep 'device:' | awk '{print $2}'))

# Enable multilib in live environment & increase parallel downloads
sed -i '/#\[multilib\]/,/#Include/ s/^#//' /etc/pacman.conf
sed -i 's/^ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf

if [ "$kernel_zen" == "y" ]; then
    kernel_name="linux-zen"
    kernel_pkg="$kernel_name linux-zen-headers"
else
    kernel_name="linux"
    kernel_pkg="$kernel_name"
fi

if lscpu | grep -q "GenuineIntel"; then
    ucode="intel-ucode"
else
    ucode="amd-ucode"
fi

if [ "$hardware" == "i" ]; then
    hardware="$kernel_pkg $ucode mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver libva libvpl vpl-gpu-rt"
elif [ "$hardware" == "a" ]; then
    hardware="$kernel_pkg $ucode mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver opencl-mesa radeontop vulkan-tools"
elif [ "$hardware" == "n" ]; then
    hardware="$kernel_pkg $ucode nvidia-open nvidia-utils lib32-nvidia-utils nvidia-settings libva-nvidia-driver"
fi



if [ "$wm" == "sway" ]; then
    wm_packages="foot fuzzel mako polkit-gnome brightnessctl network-manager-applet networkmanager-dmenu blueman dmenu-bluetooth wl-clipboard cliphist swaylock swayidle xorg-xwayland xdg-desktop-portal-wlr seatd polkit nwg-look i3status-rust grim slurp thunar"
    wm_packages_aur="swayfx"
elif [ "$wm" == "gnome" ]; then
    wm_packages="gdm gnome-shell gnome-control-center gnome-settings-daemon gnome-session gnome-tweaks gnome-system-monitor xdg-utils xdg-desktop-portal-gnome gnome-backgrounds gnome-disk-utility power-profiles-daemon nautilus gnome-calculator gnome-text-editor loupe showtime alacritty gvfs"
    wm_packages_aur="extension-manager"
fi

audio="pipewire lib32-pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack lib32-pipewire-jack"
bash_tools="libva-utils neovim htop btop openssh wireguard-tools curl wget bash-completion man-db man-pages zip unzip 7zip ntfs-3g dosfstools less fastfetch cowsay ffmpeg mpv stress gamemode lib32-gamemode fd"
fonts="ttf-iosevka-nerd ttf-jetbrains-mono-nerd ttf-noto-nerd"
apps="chromium spotify-launcher steam vlc zed libreoffice-still"
aur="librewolf-bin visual-studio-code-bin $wm_packages_aur"
dev="nodejs npm rust python python-pip python-virtualenv docker docker-compose"
#aur_slow="protonplus ani-cli stremio lmstudio-bin"
package_list="$hardware $wm_packages $audio $bash_tools $fonts $apps $dev"

base="linux-firmware base base-devel git efibootmgr networkmanager sudo vi vim bluez bluez-utils ufw cryptsetup reflector qt5-wayland qt6-wayland gnome-keyring"

pacstrap -K /mnt $base $package_list
genfstab -U /mnt >>/mnt/etc/fstab
arch-chroot /mnt <<EOF

ln -sf /usr/share/zoneinfo/Europe/Brussels /etc/localtime
hwclock --systohc
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" >> /etc/vconsole.conf
echo "arch" >> /etc/hostname
echo "root:$root_pass" | chpasswd
useradd -m -G wheel,seat "$usr_name"
echo "$usr_name:$root_pass" | chpasswd
sed -i "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers

mkdir -p /home/$usr_name/{Downloads,Documents}
chown -R $usr_name:$usr_name /home/$usr_name

systemctl enable NetworkManager
systemctl enable bluetooth.service
systemctl enable ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable

if [ "$wm" == "sway" ]; then
    systemctl enable seatd.service
    # Setup synced dotfiles.
    su - $usr_name -c "git clone --bare https://github.com/Bueezi/dotfiles.git /home/$usr_name/.dotfiles"
    su - $usr_name -c "/usr/bin/git --git-dir=/home/$usr_name/.dotfiles --work-tree=/home/$usr_name config --local status.showUntrackedFiles no"
    su - $usr_name -c "/usr/bin/git --git-dir=/home/$usr_name/.dotfiles --work-tree=/home/$usr_name checkout"
elif [ "$wm" == "gnome" ]; then
    systemctl enable gdm
fi

mkdir -p /boot/loader/entries
touch /boot/loader/entries/arch.conf

echo -e "default arch.conf\ntimeout 3\neditor no" > /boot/loader/loader.conf
echo -e "title   Arch Linux\nlinux   /vmlinuz-${kernel_name}\ninitrd  /${ucode}.img\ninitrd  /initramfs-${kernel_name}.img\noptions rd.luks.name=${LUKS_UUID}=cryptroot root=/dev/mapper/cryptroot rw" > /boot/loader/entries/arch.conf
sed -i -E \
    -e 's/\budev\b/systemd/g' \
    -e 's/\bkeymap\b//g' \
    -e 's/\bconsolefont\b//g' \
    -e 's/\bfilesystems\b/sd-encrypt filesystems/' \
    /etc/mkinitcpio.conf
mkinitcpio -P

# Enable multilib, parallel downloads, colors, and ILoveCandy
cp /etc/pacman.conf /etc/pacman.conf.bak
sed -i 's/^#\[multilib\]/[multilib]/' /etc/pacman.conf
sed -i '/^\[multilib\]/,/^$/ s/^#Include/Include/' /etc/pacman.conf
sed -i 's/^#ParallelDownloads.*/ParallelDownloads = 10/; s/^ParallelDownloads.*/ParallelDownloads = 10/' /etc/pacman.conf
sed -i 's/^#Color/Color/' /etc/pacman.conf
sed -i '/# Misc options/a ILoveCandy' /etc/pacman.conf

sed -i 's/^#MAKEFLAGS="-j2"/MAKEFLAGS="-j'"$(nproc)"'"/g' /etc/makepkg.conf

echo "$usr_name ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers # Allow user to use sudo without password
# Yay

su - $usr_name -c "git clone https://aur.archlinux.org/yay.git ~/yay && cd ~/yay && makepkg -si --noconfirm && cd .. && rm -rf yay"

su - $usr_name -c "yay -S --noconfirm $aur $aur_slow"

sed -i "/^$usr_name ALL=(ALL) NOPASSWD: ALL$/d" /etc/sudoers # Remove NOPASSWD line

# Local Pacman mirrors
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector --country 'Belgium,France,Netherlands,Germany' --age 12 --protocol https --sort rate --fastest 10 --save /etc/pacman.d/mirrorlist

EOF
bootctl --path=/mnt/boot install

echo "Install finished !"
