function peco-select-history() {
    local selected=$(history | peco)

    if [ -n "$selected" ]; then
        local cmd=$(echo "$selected" | sed -E 's/^[ ]*[0-9]+[ ]+//')
        READLINE_LINE="$cmd"
        READLINE_POINT=${#cmd}
    fi
}

bind -x '"\C-r": "peco-select-history"'

function peco-open-code() {
    local repository_path="$HOME/repository"

    local dir=$(ls "$repository_path" | grep -v "\." | peco)

    if [ -n "$dir" ]; then
        code "$repository_path/$dir"
    fi
}

bind '"\C-o":"peco-open-code\n"'
