if [ -f ~/.bashrc ] ; then
. ~/.bashrc
fi

peco_search_history() {
    SELECTED_COMMAND=$(tac ~/.bash_history | peco)
    if [ "$SELECTED_COMMAND" != "" ]; then
        echo "exec: ${SELECTED_COMMAND}"
        eval $SELECTED_COMMAND
        history -s $SELECTED_COMMAND
    fi
}

bind -x '"\C-r": peco_search_history'

alias ll='ls -al'
alias pg='grep -P'
alias pgu='grep -Pv'
alias rbp='source ~/.bash_profile'