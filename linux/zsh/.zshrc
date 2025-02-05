export PATH=$HOME/.local/bin:$PATH

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Zinit plugin
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

#alias
alias ll='ls -l --color'
alias lla='ls -la --color'
alias reload='source ~/.zshrc'

# history
export HISTFILE=${HOME}/.zsh_history
export HISTSIZE=10000
export SAVEHIST=100000
setopt inc_append_history        # コマンド実行後すぐに履歴を保存
setopt share_history             # 他のターミナルと履歴を共有
setopt hist_ignore_dups          # 直前と同じコマンドの場合は履歴に追加しない
setopt hist_ignore_all_dups      # 履歴の重複を削除
setopt hist_ignore_space         # スペースから始まるコマンドを履歴に残さない

# ^rで履歴の表示
function peco-select-history() {
  emulate -L zsh

  local delimiter=$'\0; \0' newline=$'\n'

  BUFFER=${"$(print -rl ${history//$newline/$delimiter} | peco --query "$LBUFFER")"//$delimiter/$newline}
  CURSOR=$#BUFFER
  zle -Rc
  zle reset-prompt
}
zle -N peco-select-history
bindkey '^r' peco-select-history

# 単語単位の移動
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# --- Local Ubuntu ---

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# use VS Code
alias vim='code'

function peco-open-repository() {
  local dir=$(ls ~/repository | peco --query "$LBUFFER")
  if [ -n "${dir}" ]; then
    BUFFER="code ~/repository/${dir}"
    zle accept-line
  fi
  zle clear-screen
}
zle -N peco-open-repository
bindkey '^o' peco-open-repository
