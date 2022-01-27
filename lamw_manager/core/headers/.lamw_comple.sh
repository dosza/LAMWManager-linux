#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.5
#Description: This script contains routines for completing LAMW Manager arguments.
#Ref:https://www.vivaolinux.com.br/dica/Shell-script-autocompletion-Como-implementar
#-------------------------------------------------------------------------------------------------#


_lamw_manager_completion() {
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="--help  --sdkmanager --reset --reset-aapis --update-lamw --use_proxy --server --port "

	if [[ ${cur} == -* ]] ; then
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
		return 0
	fi
}


complete -F _lamw_manager_completion lamw_manager
complete -F _lamw_manager_completion lamw-manager
complete -F _lamw_manager_completion ./lamw_manager
complete -F _lamw_manager_completion ./lamw-manager