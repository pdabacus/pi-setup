#
# ~/.bash_profile
#

if [[ -z $DISPLAY ]] && [[ $(tty) = /dev/tty1 ]]; then
    [[ -f ~/init.sh ]] && ~/init.sh
fi

[[ -f ~/.bashrc ]] && . ~/.bashrc
[[ -f ~/.proxy.env ]] && . ~/.proxy.env
