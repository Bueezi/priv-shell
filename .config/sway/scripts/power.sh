#!/bin/sh
choice=$(printf "  Sleep\n  Hibernate\n  Shutdown" |
  fuzzel --dmenu --width 20 --lines 3)

if [ "$(hostname)" = "void" ]; then
    case "$choice" in
    *Sleep)     loginctl suspend ;;
    *Hibernate) loginctl hibernate ;;
    *Shutdown)  loginctl poweroff ;;
    esac
else
    case "$choice" in
    *Sleep)     systemctl suspend ;;
    *Hibernate) systemctl hibernate ;;
    *Shutdown)  systemctl poweroff ;;
    esac
fi
