export XDG_CONFIG_HOME="$HOME/.config"
export PATH="$HOME/zig:$PATH"
export PATH="$HOME/coding/zls/zig-out/bin:$PATH"
export PATH="$HOME/nvim/bin:$PATH"
export VISUAL="nvim"
export EDITOR="nvim"
export LLDB_USE_NATIVE_PDB_READER="yes"

# export PATH="$HOME/go/bin:$PATH"
export GOPATH="$HOME/go-path"
export PATH="$GOPATH/bin:$PATH"
export TEMPL_EXPERIMENT="rawgo"
export PATH="/home/anton/.cargo/bin:$PATH"

export PATH="$PATH:/opt/mssql-tools18/bin"

plugins=(
	git
	vi-mode
    ssh-agent
)

source ~/.oh-my-zsh/oh-my-zsh.sh

# vi mode
bindkey -v
export KEYTIMEOUT=1

unsetopt autocd

# Change cursor shape for different vi modes.
function zle-keymap-select {
  if [[ ${KEYMAP} == vicmd ]] ||
     [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'
  elif [[ ${KEYMAP} == main ]] ||
       [[ ${KEYMAP} == viins ]] ||
       [[ ${KEYMAP} = '' ]] ||
       [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
  fi
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins # initiate `vi insert` as keymap (can be removed if `bindkey -V` has been set elsewhere)
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q' # Use beam shape cursor on startup.
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt.

# This doesn't seem possible to do
# I wanted ctrl+backspace to delete a word, but that sends it a regular
# backspace signal instead (equivalent to ^H)
bindkey '^H' backward-delete-word

function _load_ssh_keys() {
    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/github_wsl"
}
_load_ssh_keys

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

source ~/powerlevel10k/powerlevel10k.zsh-theme

alias nvim-config="nvim ~/.config/nvim"
alias asdc="cd $HOME/coding/uniCourse_dataStructuresAndAlgorithms; $HOME/tmux_attach_session.sh asdc"
alias unilatex="cd $HOME/uni_thesisTemplate; $HOME/tmux_attach_session.sh unilatex"
alias testgen="cd $HOME/coding/test_gen; $HOME/tmux_attach_session.sh testgen"
alias explorer="explorer.exe"
alias https_to_ssh="~/https_to_ssh.sh"

export PATH=$PATH:$HOME/.pulumi/bin
