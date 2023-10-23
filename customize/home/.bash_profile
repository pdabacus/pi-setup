#
# ~/.bash_profile
#

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
    [[ -f ~/init.sh ]] && ~/init.sh && [[ -f ~/main.sh ]] && ~/main.sh
    #startx
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -f ~/.proxy.env ]] && . ~/.proxy.env
