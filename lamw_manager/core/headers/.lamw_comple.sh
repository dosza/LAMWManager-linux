#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.8
#Description: This script contains routines for completing LAMW Manager arguments.
#Ref:https://www.vivaolinux.com.br/dica/Shell-script-autocompletion-Como-implementar
#-------------------------------------------------------------------------------------------------#


if [ -e ~/.bashrc ]; then 
	source ~/.bashrc
else
	[ -e  /etc/bash.bashrc ] && source /etc/bash.bashrc
fi

_lamw_manager_completion() {
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="--help  --minimal --port --reinstall --reset --reset-aapis --sdkmanager  --server --update-lamw  --use_proxy"

	if [[ ${cur} == -* ]] ; then
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
		return 0
	fi
}

_sdkmanager_completion(){
	local cur prev opts
	COMPREPLY=()
	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	opts="--channel= --help --include_obsolete --install --licenses --list --list_installed --no_https --package --package_combination --proxy= --proxy_host= --proxy_port= --sdk_root= --uninstall --update --verbose --version"

	if [[ ${cur} == -* ]] ; then
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
		return 0
	fi
}
complete -F _lamw_manager_completion lamw_manager
complete -F _lamw_manager_completion ./lamw_manager
complete -F  _sdkmanager_completion sdkmanager
