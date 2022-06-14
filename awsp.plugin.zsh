#!/bin/zsh

autoload -U colors && colors
autoload -U compinit && compinit

if [[ -f ~/.oh-my-zsh/custom/plugins/awsp/awsp_colors.sh ]]; then
  source ~/.oh-my-zsh/custom/plugins/awsp/awsp_colors.sh
elif [[ -f ~/.oh-my-zsh/custom/plugins/awsp/awsp_colors.default.sh ]]; then
  source ~/.oh-my-zsh/custom/plugins/awsp/awsp_colors.default.sh
fi

function _aws_prompt_info() {
  if [[ "$AWSP_RPOMPT_OPT_OUT" != "" ]]; then
    disable_aws_prompt
  else
    AWS_PROFILE_TEXT=$AWS_PROFILE
    if [[ "$AWS_PROFILE" == "default" || -z $AWS_PROFILE ]]; then
      AWS_PROFILE_TEXT='default(unset)'
    fi
    local printed="false"
    for key value in ${(kv)AWSP_PROFILE_COLORS}; do
      if [[ "${AWS_PROFILE:-default}" == "$key" || "$AWS_PROFILE" == *'*' && "$AWS_PROFILE" == "${key%'*'}"* ]]; then
        echo "%{$fg[$value]%}${ZSH_THEME_AWS_PREFIX:=<aws:}${AWS_PROFILE_TEXT}${ZSH_THEME_AWS_SUFFIX:=>}%{$reset_color%}"
        printed="true"
      fi
    done
    if [[ "$printed" == "false" ]]; then
      echo "%{$fg[red]%}${ZSH_THEME_AWS_PREFIX:=<aws:}${AWS_PROFILE:=default}${ZSH_THEME_AWS_SUFFIX:=>}%{$reset_color%}"
    fi
  fi
}

function enable_aws_prompt() {
  if [[ "$AWSP_RPOMPT_OPT_OUT" == "" && "$RPROMPT" != *'$(_aws_prompt_info)'* ]]; then
    RPROMPT='$(_aws_prompt_info)'"$RPROMPT"
  fi
}

function disable_aws_prompt() {
  RPROMPT=${RPROMPT%'$(_aws_prompt_info)'}
}

# aws_prompt


function _awsp() {
  local state

  _arguments \
    '1: :->aws_profile'

  case $state in
    (aws_profile) _arguments '1:profiles:($(cat ~/.aws/config | grep "\[" | sed "s/profile\ //; s/\[//; s/\]//" | sort))' ;;
  esac
}

enable_aws_prompt

function awsp() {
  local profiles=$(cat ~/.aws/config | grep '\[' | sed 's/profile\ //; s/\[//; s/\]//' | sort)
  enable_aws_prompt

  if [[ "$1" != "" ]]; then
    if [[ "$1" == "-d" || "$1" == "--disable" || "$AWSP_RPOMPT_OPT_OUT" != "" ]]; then
      disable_aws_prompt
    elif [[ "$1" == "-h" || "$1" == "--help" ]]; then
      echo "Usage: awsp [OPTIONS] [PROFILE]"
      echo ""
      echo "An intuitive aws profile manager."
      echo ""
      echo "Reads profile data from ~/.aws/config."
      echo "Reads colors from ~/.oh-my-zsh/custom/plugins/awsp/awsp_colors.sh"
      echo "Default colors ~/.oh-my-zsh/custom/plugins/awsp/awsp_colors.default.sh"
      echo ""
      echo "Options:"
      echo "  -h, --help    Get help"
      echo "  -d, --disable Remove aws profile information from RPROMPT"
      echo ""
      echo "Set AWSP_RPOMPT_OPT_OUT to any non-empty value to permanently opt"
      echo "out of RPROMPT info."
    elif [[ $(echo $profiles | grep -c "$1") -eq 0 ]]; then
      echo "Profile '$1' not found in ~/.aws/config" >&2
    else
      export AWS_PROFILE="$1"
    fi
  else
    echo $profiles
  fi
}

function awsps() {
  if [[ "$AWS_PROFILE" != "" ]]; then
    cat ~/.aws/config | sed -n -e "/$AWS_PROFILE/,/\\[/p" | sed -e '$d'
  else
    echo "AWS_PROFILE is unset" >&2
  fi
}

compdef _awsp awsp
