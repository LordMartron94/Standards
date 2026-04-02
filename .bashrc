# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc
. "$HOME/.cargo/env"

# FOUND: https://askubuntu.com/questions/730754/how-do-i-show-the-git-branch-with-colours-in-bash-prompt

# Color Definitions
CLR_RESET='\[\033[00m\]'
CLR_BOLD_GREEN='\[\033[01;32m\]'
CLR_BOLD_BLUE='\[\033[01;34m\]'
CLR_BOLD_RED='\[\033[01;31m\]'

# Show git branch name
force_color_prompt=yes
color_prompt=yes

parse_git_info() {
  local repo_path=$(git rev-parse --show-toplevel 2>/dev/null)
  if [ -z "$repo_path" ]; then
    return
  fi

  local repo_name=$(basename "$repo_path")
  
  local branch_name=$(git symbolic-ref --short HEAD 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
  
  echo "($repo_name:$branch_name)"
}

if [ "$color_prompt" = yes ]; then
    # Structure: [User@Host][Path][(Repo:Branch)]
    PS1='${debian_chroot:+($debian_chroot)}'
    PS1+="${CLR_BOLD_GREEN}\u@\h${CLR_RESET}:"
    PS1+="${CLR_BOLD_BLUE}\w"
    PS1+="${CLR_BOLD_RED} \$(parse_git_info)"
    PS1+="${CLR_RESET}\$ "
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w \$(parse_git_info) \$ '
fi

unset color_prompt force_color_prompt
