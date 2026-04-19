#!/bin/sh
choice=$(printf "  Sleep\n  Hibernate\n  Reboot\n  Shutdown" |
  fuzzel --dmenu --width 20 --lines 4)

if [ "$(hostname)" = "void" ]; then
    case "$choice" in
    *Sleep)     loginctl suspend ;;
    *Hibernate) loginctl hibernate ;;
    *Reboot)    loginctl reboot ;;
    *Shutdown)  loginctl poweroff ;;
    esac
else
    case "$choice" in
    *Sleep)     systemctl suspend ;;
    *Hibernate) systemctl hibernate ;;
    *Reboot)    systemctl reboot ;;
    *Shutdown)  systemctl poweroff ;;
    esac
fi
