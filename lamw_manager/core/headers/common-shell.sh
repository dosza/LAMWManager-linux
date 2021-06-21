#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (mater-alma)
#Course: Science Computer
#version: 0.1.0	
#Date: 06/12/2021
#Description: Thi script provides common shell functions
#-------------------------------------------------------------------------------------------------#

#GLOBAL VARIABLES
#----ColorTerm
export VERDE=$'\e[1;32m'
export AMARELO=$'\e[01;33m'
export SUBLINHADO=$'\e[4'
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

isVariabelDeclared(){
	if [ "$1" = "" ]; then return 1; fi

	declare -p "$1" &> /dev/null
	return $?
}

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

# Verify se user is sudo member (return  1 false, 0 to true 	yttttt)
isUsersSudo(){
	local ret=0
	if [ "$1" = "" ]; then 
		echo "$1 can't be empty"
		ret=1
	fi

	grep sudo /etc/group  | grep $1 /dev/null 2>&1
	if [ $? != 0 ]; then
		ret=$?
	fi
	return $ret

}
# searchLineinFile(FILE *fp, char * str )
#$1 is File Path
#$2 is a String to search 
#this function return 0 if not found or 1  if found
searchLineinFile(){
	local flag=0
	local line=''
	if [ "$1" != "" ]; then
		if [ "$2" != "" ]; then
			while  read line 
			do
				if [ "$line" = "$2" ]; then
					flag=1
					break
				fi
			done < "$1"
		fi
	fi
	return $flag # return value 
}
#args $1 is str
#args $2 is delimeter token 
#call this function output=($(SplitStr $str $delimiter))
splitStr(){
	local str=""
	local token=""
	local str_spl=()
	if [ "$1" != "" ] && [ "$2" != "" ] ; then 
		local str="$1"
		local delimeter=$2
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
	if [ "$1" = "" ] ; then
		echo "There is no string to scape!"
		return 1
	else
		echo "$1" | grep '\\' > /dev/null
		if [  $? != 0 ]; then 
			echo "$1" | sed 's|\/|\\\/|g'  | sed "s|\.|\\\.|g" | sed "s|\-|\\\-|g" | sed "s|\"|\\\"|g" | sed "s/'/\\\'/g"
		fi
	fi
}


# Find and replace line an file 
# $1 filepath
# $2 string_to_find (scapped)
# $3 string_to_replace(scapped)
replaceLine(){
	if [  $# -lt 3 ]; then 
		echo "missing args! $1 filename,$2 string to find, $3 string to replace"
		return 1
	fi

	if [ ! -e "$1" ]; then 
		echo "There is no \"$1\" file"
		return 1;
	fi
	local str_to_find="$2"
	local str_to_replace="$3"
	sed -i "s|${str_to_find}|${str_to_replace}|g" "$1"	
}


# this function split string and add a array
#his array must be passed by reference


Split (){ 
    if [ $# = 3 ] ; then
        local str=$1;
        local delimiter=$2;
        newPtr out=$3
        echo "$1" | grep "$2"  > /dev/null
        if [ $? = 0 ]; then 
            local new_str=${str//$delimiter/ };
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
		local filename="$1"
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
		local filename="$1"
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
		local filename="$1"
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
		local filename="$1"
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
			local aux=$(tail -1 "$1" )       #tail -1 mostra a última linha do arquivo 
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
	wget $wget_opts $*
	if [ $? != 0 ]; then
		wget $wget_opts $*
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
		if [ $? != 0 ]; then 
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
	apt-get clean
	apt-get autoclean
}


#Retorna verdadeiro se o pacote $1 está instalado
isDebPackInstalled(){
	if [ "$1" = "" ]; then
		echo "missing package name";
		return 0;
	fi
	exec 2> /dev/null dpkg -s "$1" | grep 'Status: install' > /dev/null #exec 2 redireciona a saída do stderror para /dev/null
	
	if [ $?  = 0 ]; then
		return 1
	else
		return 0;
	fi
}