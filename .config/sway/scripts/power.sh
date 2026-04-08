#!/bin/sh
choice=$(printf "  Sleep\n  Hibernate\n  Shutdown" |
  fuzzel --dmenu --width 20 --lines 3)

case "$choice" in
*Sleep) systemctl suspend ;;
*Hibernate) systemctl hibernate ;;
*Shutdown) systemctl poweroff ;;
esac
