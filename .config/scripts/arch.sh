#!/bin/bash
# iwctl
#	station <device> connect "SSID"
# ping 8.8.8.8
# timedatectl

# gdisk, cryptsetup, mkfs

echo -n "Root Pass : " && read root_pass
echo -n "Username : " && read usr_name
echo -n "Are u using intel, amd or nvidia ? (i/a/n): " && read hardware
echo -n "What WM do u want gnome or sway ? (gnome/sway): " && read wm
echo -n "Which AUR helper do you want(yay/paru): " && read aur_helper

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

if [ "$hardware" == "i" ]; then
    ucode="intel-ucode"
    kernel="linux"
    hardware="$kernel intel-ucode mesa lib32-mesa vulkan-intel lib32-vulkan-intel intel-media-driver libva libvpl vpl-gpu-rt"
elif [ "$hardware" == "a" ]; then
    ucode="amd-ucode"
    kernel="linux"
    hardware="$kernel sof-firmware amd-ucode mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon libva-mesa-driver lib32-libva-mesa-driver opencl-mesa radeontop vulkan-tools"
elif [ "$hardware" == "n" ]; then
    ucode="amd-ucode"   # or intel, depending on your CPU
    kernel="linux-zen"
    hardware="$kernel linux-zen-headers amd-ucode nvidia-open nvidia-utils lib32-nvidia-utils nvidia-settings libva-nvidia-driver"
fi

if [ "$wm" == "sway" ]; then
    wm_packages="foot fuzzel waybar dunst polkit-gnome brightnessctl network-manager-applet blueman wl-clipboard cliphist swaybg swaylock swayidle xorg-xwayland xdg-desktop-portal-wlr seatd polkit nnn"
    wm_packages_aur="swayfx"
elif [ "$wm" == "gnome" ]; then
    wm_packages="gdm gnome-shell gnome-control-center gnome-settings-daemon gnome-session gnome-keyring gnome-tweaks gnome-system-monitor xdg-utils xdg-desktop-portal-gnome gnome-backgrounds gnome-disk-utility power-profiles-daemon nautilus gnome-calculator gnome-text-editor loupe showtime alacritty gvfs"
    wm_packages_aur="extension-manager"
fi

audio="pipewire lib32-pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack lib32-pipewire-jack"
bash_tools="bc libva-utils neovim htop btop openssh curl wget bash-completion man-db man-pages zip unzip 7zip ntfs-3g dosfstools less fastfetch cowsay reflector python python-virtualenv ffmpeg mpv stress gamemode lib32-gamemode rust fd xdg-user-dirs"
fonts="ttf-iosevka-nerd ttf-jetbrains-mono-nerd ttf-noto-nerd"
apps="chromium spotify-launcher steam vlc zed"
aur="librewolf-bin visual-studio-code-bin $wm_packages_aur"
school="nodejs npm"
aur_slow="protonplus ani-cli stremio"
package_list="$hardware $wm_packages $audio $bash_tools $fonts $apps $school"

base="linux-firmware base base-devel git efibootmgr networkmanager sudo vim vi bluez bluez-utils ufw cryptsetup"

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
su - $usr_name -c "xdg-user-dirs-update"
echo "$usr_name:$root_pass" | chpasswd
sed -i "s/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/" /etc/sudoers
#localectl set-keymap be-latin1

# Install Lazy Vim
mkdir -p /home/"$usr_name"/.config/nvim /home/"$usr_name"/Documents /home/"$usr_name"/Downloads /home/"$usr_name"/.config/gtk-3.0 /home/"$usr_name"/.config/gtk-4.0 /home/"$usr_name"/.config/foot
git clone https://github.com/LazyVim/starter /home/"$usr_name"/.config/nvim
chown -R $usr_name:$usr_name /home/$usr_name

systemctl enable NetworkManager
systemctl enable bluetooth.service
systemctl enable ufw
ufw default deny incoming
ufw default allow outgoing
ufw enable

if [ "$wm" == "sway" ]; then
    #cd /home/"$usr_name" && rm -rf .config && git clone --depth 1 --filter=blob:none --sparse https://github.com/Bueezi/priv-shell.git temp-clone && cd temp-clone && git sparse-checkout set .config && mv .config /home/"$usr_name"/ && cd /home/"$usr_name" && rm -rf temp-clone
    #ln -sf /home/"$usr_name"/.config/gtk-3.0/settings.ini /home/"$usr_name"/.config/gtk-4.0/settings.ini
    systemctl enable seatd.service
elif [ "$wm" == "gnome" ]; then
    systemctl enable gdm
fi

mkdir -p /boot/loader/entries
touch /boot/loader/entries/arch.conf

echo -e "default arch.conf\ntimeout 3\neditor no" > /boot/loader/loader.conf
echo -e "title   Arch Linux\nlinux   /vmlinuz-${kernel}\ninitrd  /${ucode}.img\ninitrd  /initramfs-${kernel}.img\noptions rd.luks.name=${LUKS_UUID}=cryptroot root=/dev/mapper/cryptroot rw" > /boot/loader/entries/arch.conf
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

if [ "$aur_helper" == "yay" ]; then
    su - $usr_name -c "git clone https://aur.archlinux.org/yay.git ~/yay && cd ~/yay && makepkg -si --noconfirm && cd .. && rm -rf yay"
else
    su - $usr_name -c "git clone https://aur.archlinux.org/paru.git ~/paru && cd ~/paru && makepkg -si --noconfirm && cd .. && rm -rf paru"
fi

su - $usr_name -c "$aur_helper -S --noconfirm $aur $aur_slow"

sed -i "/^$usr_name ALL=(ALL) NOPASSWD: ALL$/d" /etc/sudoers # Remove NOPASSWD line

#systemctl enable gdm

# Local Pacman mirrors
cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector --country 'Belgium,France,Netherlands,Germany' --age 12 --protocol https --sort rate --fastest 10 --save /etc/pacman.d/mirrorlist

EOF
bootctl --path=/mnt/boot install

echo "Install finished !"
