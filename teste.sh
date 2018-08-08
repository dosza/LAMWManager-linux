#!/bin/bash
#https://www.vivaolinux.com.br/dica/Shell-script-autocompletion-Como-implementar
_ola() {
    local cur prev opts
       COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    opts="--help --message --version"

    if [[ ${cur} == -* ]] ; then
          COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
          return 0
    fi
  }
  complete -F _ola teste
teste(){
	if [ "$1" = "--version" ]
  	then
  		echo "works"
  	fi
}