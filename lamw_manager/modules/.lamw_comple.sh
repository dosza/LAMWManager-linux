#!/bin/bash
#https://www.vivaolinux.com.br/dica/Shell-script-autocompletion-Como-implementar
_ola() {
    local cur prev opts
       COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="uninstall DEBUG=1 version --help   --sdkmanager --reset --reset-aapis --update-lamw   --use_proxy --server --port "

    if [[ ${cur} == -* ]] ; then
          COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
          return 0
    fi
  }
  complete -F _ola lamw_manager
  complete -F _ola lamw-manager
  complete -F _ola ./lamw_manager
  complete -F _ola ./lamw-manager