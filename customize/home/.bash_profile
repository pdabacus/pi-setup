#
# ~/.bash_profile
#

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
    echo startx
    #exec startx
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -f ~/.proxy.env ]] && . ~/.proxy.env
