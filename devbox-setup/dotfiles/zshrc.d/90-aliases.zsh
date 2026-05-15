# Aliases
# remove all node_modules recursive (inside nested folders too)
alias rmnm="find . -name 'node_modules' -type d -prune -print -exec rm -rf '{}' +"

alias gitst='git status'
alias gitch='git checkout'
alias gitme='git merge --no-ff'
alias gitre='git rebase'
alias gitsu='git submodule update --init --recursive'
alias gitrec='git rebase --continue'

alias lg='lazygit'
alias dc='docker compose'
alias ta='tmux attach'
alias tn='tmux new -s'
