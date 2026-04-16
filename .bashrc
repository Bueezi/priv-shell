#
# ~/.bashrc
#

export PATH="/home/ben/.cargo/bin:$PATH"

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '


if [ "$(tty)" = "/dev/tty1" ]; then
    exec sway
fi

alias config='/usr/bin/git --git-dir=$HOME/.dotfiles --work-tree=$HOME'

alias gc='gcc -std=c99 -Wall -Wextra -pedantic'

alias hx='helix'

# Added by LM Studio CLI (lms)
export PATH="$PATH:/home/ben/.lmstudio/bin"
# End of LM Studio CLI section

