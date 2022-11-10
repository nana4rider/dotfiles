#alias
alias vim='code'
alias ll='ls -al'
alias pg='grep -P'
alias pgu='grep -Pv'
alias zshrc='source ~/.zshrc'

# history
export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=1000
export SAVEHIST=100000
setopt hist_ignore_dups
setopt EXTENDED_HISTORY

# peco
function peco-select-history() {
  BUFFER=$(\history -n -r 1 | peco --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history

function peco-open-code() {
  local dir=$(ls ~/repository | peco --query "$LBUFFER")
  BUFFER="code ~/repository/${dir}"
  zle accept-line
  zle clear-screen
}
zle -N peco-open-code
bindkey '^.' peco-open-code

PROMPT="%F{45}%~%f > "

bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word