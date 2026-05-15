# Prompt
parse_git_branch() {
  local branch
  branch=$(git symbolic-ref --short HEAD 2>/dev/null) || return
  printf ' %s' "$branch"
}

autoload -U colors && colors
setopt PROMPT_SUBST

PROMPT='%n %1~ %F{green}$(parse_git_branch)%f $ '
