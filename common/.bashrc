# ~/.bashrc - basic interactive shell setup (common)

# Only run in interactive shells
case $- in
  *i*) ;;
  *) return ;;
esac

export EDITOR=vim
export VISUAL=vim

# History
HISTCONTROL=ignoredups:erasedups
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend

# Prompt (user@host:cwd$)
PS1='\u@\h:\w\$ '

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias v='vim'
alias grep='grep --color=auto'

# PATH for local bin
if [ -d "$HOME/.local/bin" ]; then
  PATH="$HOME/.local/bin:$PATH"
fi

# OS-specific overlay (e.g. arch-linux → ~/.bashrc_arch)
if [ -f "$HOME/.bashrc_arch" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.bashrc_arch"
fi
