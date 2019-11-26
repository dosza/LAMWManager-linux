#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (mater-alma)
#Course: Science Computer
#version: 0.0.1
#Date: 11/23/19
#Description: This script is not part of LAMW Manager! It is an external library that implements routines common to shell script.
#-------------------------------------------------------------------------------------------------#

#GLOBAL VARIABLES
#----ColorTerm
export VERDE=$'\e[1;32m'
export AMARELO=$'\e[01;33m'
export SUBLINHADO=$'4'
export NEGRITO=$'\e[1m'
export VERMELHO=$'\e[1;31m'
export VERMELHO_SUBLINHADO=$'\e[1;4;31m'
export AZUL=$'\e[1;34m'
export NORMAL=$'\e[0m'
APT_LOCKS=(
	"/var/lib/dpkg/lock"
	"/var/lib/apt/lists/lock"
	"/var/cache/apt/archives/lock"
	"/var/lib/dpkg/lock-frontend"
)
shopt  -s expand_aliases
alias newPtr='declare -n'
#cd not a native command, is a systemcall used to exec, read more in exec man 
changeDirectory(){
	if [ "$1" != "" ] ; then
		if [ -e "$1"  ]; then
			cd "$1"
		else
			echo "\"$1\" does not exists!" &<2
			exit 1
		fi
	fi 
}

# searchLineinFile(FILE *fp, char * str )
#$1 is File Path
#$2 is a String to search 
#this function return 0 if not found or 1  if found
searchLineinFile(){
	flag=0
	line='NONE'
	if [ "$1" != "" ]; then
		if [ "$2" != "" ]; then
			for i in $(cat "$1")
			do
				if [ "$2" = "$i" ]; then
					flag=1
					break
				fi
			done
		fi
	fi
	return $flag # return value 
}
#args $1 is str
#args $2 is delimeter token 
#call this function output=($(SplitStr $str $delimiter))
splitStr(){
	str=""
	token=""
	str_spl=()
	if [ "$1" != "" ] && [ "$2" != "" ] ; then 
		str="$1"
		delimeter=$2
		case "$delimeter" in 
			"/")
			str_spl=(${str//\// })
			echo "${str_spl[@]}"
			;;
			*)
				#if [ $(echo $str | grep [a-zA-Z0-9;]) = 0 ] ; then  # if str  regex alphanumeric
					str_spl=(${str//$delimeter/ })
					echo "${str_spl[@]}"
				#fi
			;;
		esac
	fi
}
GenerateScapesStr(){
	tam=${#HOME_USER_SPLITTED_ARRAY[@]}
	str_scapes=""
	if [ "$1" = "" ] ; then
		for ((i=0;i<tam;i++))
		do
			HOME_STR_SPLITTED=$HOME_STR_SPLITTED"\/"${HOME_USER_SPLITTED_ARRAY[i]}
		#echo ${HOME_USER_SPLITTED_ARRAY[i]}
		done
	else
		str_array=($(splitStr "$1" "/"))
		tam=${#str_array[@]}
		for ((i=0;i<tam;i++))
		do
			str_scapes=$str_scapes"\/"${str_array[i]}
		done
		echo "$str_scapes"
	fi
}



# this function split string and add a array
#his array must be passed by reference


Split (){ 
    if [ $# = 3 ] ; then
        str=$1;
        delimiter=$2;
        newPtr out=$3
        echo "$1" | grep "$2"  > /dev/null
        if [ $? = 0 ]; then 
            new_str=${str//$delimiter/ };
            out=($(echo $new_str))
            return 0
        fi   
    else
        return 1
    fi
}

#write override writefile
#$1 filename
#$2 stream 
#note a stream must to be a formatted string
WriterFile(){
	if [ $# = 2 ]; then
		filename="$1"
		newPtr stream=$2
		for((i=0;i<${#stream[*]};i++))
		do
			if [ $i = 0 ]; then 
				printf "%b" "${stream[i]}" > "$filename"
			else
				printf "%b" "${stream[i]}" >> "$filename"
			fi
		done
	fi
}

WriterFileln(){
	if [ $# = 2 ]; then
		filename="$1"
		newPtr stream=$2
		for((i=0;i<${#stream[*]};i++))
		do
			if [ $i = 0 ]; then 
				printf "%b\n" "${stream[i]}" > "$filename"
			else
				printf "%b\n" "${stream[i]}" >> "$filename"
			fi
		done
	fi
}

#Append a file if exists
#$1 filename
#$2 stream reference
#sintaxy WriterFile(char filename, char * stream )
#note a stream must to be a formatted string
AppendFile(){
	if [ $# = 2 ]; then
		filename="$1"
		newPtr stream=$2
		if [  -e  $filename ]; then 
			for((i=0;i<${#stream[*]};i++))
			do
					printf "%b" "${stream[i]}" >> "$filename"
			done
		else
			echo "\"$filename\" does not exists!"
		fi
	fi
}

AppendFileln(){
	if [ $# = 2 ]; then
		filename="$1"
		newPtr stream=$2
		if [  -e  "$filename" ]; then 
			for((i=0;i<${#stream[*]};i++))
			do
				printf "%b\n" "${stream[i]}" >> "$filename"
			done
		else
			echo "\"$filename\" does not exists!"
		fi
	fi
}

InsertUniqueBlankLine(){
	if [ "$1" != "" ] ; then
		if [ -e "$1" ] ; then 
			aux=$(tail -1 "$1" )       #tail -1 mostra a última linha do arquivo 
			if [ "$aux" != "" ] ; then   # verifica se a última linha é vazia
				sed  -i '$a\' "$1" #adiciona uma linha ao fim do arquivo
			fi
		fi
	fi
}

IsUserRoot(){
	if  [  "$(whoami)" = "root" ];then #impede que o script seja executado pelo root 
		printf "Error: \"$1\" was designed  to run without root privileges\nExiting...\n" >&2 # >&2 is a file descriptor to /dev/stderror
		exit 1
	fi
}

Wget(){
	if [ $1 = "" ]; then
		echo "Wget needs a argument"
		exit 1
	fi
	local wget_opts="-c --timeout=300"
	wget $wget_opts $1
	if [ $? != 0 ]; then
		wget $wget_opts $1
		if [ $? != 0 ]; then 
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
}

#Verifica se um ou mais arquivos estão sendo usados por processos, 
#$1 é  mensagem que será exibida na espera ...
IsFileBusy(){
	if [ $# = 0 ]; then
		echo "IsFileBusy needs a argument"
		exit 1;
	fi

	local args=($*)
	unset args[0]
	local msg=0
	while fuser ${args[*]} > /dev/null 2<&1 #enquato os arquivos estiverem ocupados ....
	do
		if  [ $msg = 0 ]; then 
			echo "Wait for $1..."
			msg=1;
		fi
	done
}

#Essa instala um ou mais pacotes from apt 
AptInstall(){
	
	local apt_opts=(-y --allow-unauthenticated)
	local apt_opts_err=(--fix-missing)

	if [ $# = 0 ]; then
		echo "AptInstall requires arguments"
		exit 1
	fi
	IsFileBusy apt ${APT_LOCKS[*]}
	apt-get update
	apt-get install $* ${apt_opts[*]}
	if [ "$?" != "0" ]; then
		apt-get install $* ${apt_opts[*]} ${apt_opts_err[*]}
		if [ $? = 0 ]; then 
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
	apt-get clean
	apt-get autoclean
}
