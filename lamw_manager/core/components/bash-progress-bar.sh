#!/usr/bin/env bash 


GREEN=$'\e[1;32m'
BOLD=$'\e[1m'
RED=$'\e[1;31m'
BLUE=$'\e[1;34m'
DEFAULT=$'\e[0m'
_PPID=$4

_F='='
_C=' '
_FE=' '
_CE='🟦️'
LINE_BAR=(
	"[$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_C$_C$_C$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
	"[$_F$_F$_F$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"	
)
EMOJI_BAR=(
	"[$_CE                                    ]"
	"[   $_CE                                 ]"
	"[      $_CE                              ]"
	"[         $_CE                           ]"
	"[            $_CE                        ]"
	"[               $_CE                     ]"
	"[                  $_CE                  ]"
	"[                     $_CE               ]"
	"[                        $_CE            ]"
	"[                           $_CE         ]"
	"[                              $_CE      ]"
	"[                                 $_CE   ]"
	"[                                    $_CE]"
	"[                                 $_CE   ]"
	"[                              $_CE      ]"
	"[                           $_CE         ]"
	"[                        $_CE            ]"
	"[                     $_CE               ]"
	"[                  $_CE                  ]"
	"[               $_CE                     ]"
	"[            $_CE                        ]"
	"[         $_CE                           ]"
	"[      $_CE                              ]"
	"[   $_CE                                 ]"
	"[$_CE                                    ]"
)

FINISH_EMOJI_BAR="[$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE$_CE]"
EMPITY_EMOJI_BAR="[$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE$_FE]"
EMPITY_BAR="[$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C$_C]"
FINISH_BAR="[$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F$_F]"
SPINER_CLOCK=(🕛️ 🕑️ 🕒️ 🕕️ 🕗️ 🕘️ )
SPINER=("|" "/" "—" '\')
MESSAGE="$2"
BAR_TYPE=$3
STATUS_PARENT='failed'

doExit(){
	exit
}

onSuccessFinishEmojiBar(){
	local correct_emoji="${BLUE}✅${DEFAULT}"
	echo -e "\r[ ${correct_emoji} ] ${FINISH_EMOJI_BAR}\t${MESSAGE} success!                  "
	doExit
}

onFailedEmojiBar(){
	local fail_label="${RED}❌${DEFAULT}"
	echo -e "\r[ ${fail_label} ] ${EMPITY_EMOJI_BAR}\t${MESSAGE} ${STATUS_PARENT}!                  "
	doExit
}

onSuccessFinishProgressBar(){
	local sucess_label="${GREEN}+${DEFAULT}"
	echo -e "\r[ ${sucess_label} ] ${FINISH_BAR} ${MESSAGE} success!                  "
	doExit
}

onFailedProgressBar(){
	local status="${RED}X${DEFAULT}"
	echo -e "\r[ ${status} ] ${EMPITY_BAR} ${MESSAGE} ${STATUS_PARENT}!                  "
	doExit
}

checkIfProcessParentIsALive(){
	local count=$((i%1000))
	[ $count != 0 ] && return 
	if !  ps --pid ${_PPID} &> /dev/null; then 
		handleExitFailed
	fi
}


runProgressBar(){
	local -n ref_spiner=$1
	local -n ref_progress_bar=$2
	local -i i=0
	local progress_bar_size=${#ref_progress_bar[@]}
	local spiner_size=${#ref_spiner[@]}

	while true; do 
		index_progress_bar=$((i%progress_bar_size))
		index_spiner=$((i%spiner_size))
		current_progress_bar="${ref_progress_bar[$index_progress_bar]}"
		current_spiner="${BLUE}${ref_spiner[$index_spiner]}${DEFAULT}"
		message="\r[ ${current_spiner} ] ${current_progress_bar} please wait, $3 ..."
		echo -en "$message"
		sleep $4
		checkIfProcessParentIsALive
		let i=i+1
	done
}

startEmojiProgressBar(){
	runProgressBar SPINER_CLOCK EMOJI_BAR "$2" "$1"
}

startSimpleProgressBar(){
	runProgressBar SPINER LINE_BAR "$2" "$1"
}

handleSigTerm(){
	[  "$BAR_TYPE" = "0" ] && onSuccessFinishEmojiBar
	onSuccessFinishProgressBar
}

handleExitFailed(){
	[ "$BAR_TYPE" = "0" ] && onFailedEmojiBar
	onFailedProgressBar
	doExit
}

handleSigInt(){
	STATUS_PARENT='canceled'
	handleExitFailed
}

handleSigUsr1(){
	handleSigInt
	doExit
}
initProgressBar(){
	[ "$BAR_TYPE" = "0" ] && startEmojiProgressBar "$1" "$2"
	startSimpleProgressBar "$1" "$2"
}

trap handleSigTerm SIGTERM
trap handleExitFailed SIGHUP
trap handleSigInt SIGINT
trap handleSigUsr1 SIGUSR1

if [  $# =  4 ] && [ "$1" != "0" ]; then 
	initProgressBar "$1" "$2"
fi