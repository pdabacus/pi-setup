#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias l='ls -CF'
alias l.='ls -d .*'
alias la='ls -A'
alias ll='ls -ahlF'
alias sl='ls'
alias vi='vim'
alias :q='exit'
alias shit='git'

# cd .. multiple times
cd-() {
    s=""
    for i in $(seq 1 $1); do
        s="$s../"
    done
    cd "$s"
}

# shell prompt
PS1='[\u@\h \W]\$ '

# vim default editor
export EDITOR=/usr/bin/vim

# set tab space
tabs 4

# history
HISTCONTROL=ignorespace

[ -r /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
