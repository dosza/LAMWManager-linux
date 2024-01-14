#!/usr/bin/env bash

lamw_manager_help(){
	local lamw_mgr="./lamw_manager"
	if [ "$USE_SETUP" = "1" ]; then
		lamw_mgr="bash lamw_manager_setup.sh\t${VERDE}--${NORMAL}"
	fi

	LAMW_OPTS=(
	"syntax:\n"
	"${NEGRITO}env LOCAL_ROOT_LAMW=${VERDE}[dir]${NORMAL}\t${NORMAL}${lamw_mgr//\-\-}\n"
	"${NEGRITO}env LOCAL_ROOT_LAMW=${VERDE}[dir]${NORMAL}\t${NORMAL}$lamw_mgr\t${NEGRITO}[actions]${NORMAL} ${VERDE}[options]${NORMAL}\n"
	"${lamw_mgr//\-\-}\tor\t$lamw_mgr\t${NEGRITO}[actions]${NORMAL} ${VERDE}[options]${NORMAL}\n"
	"${NEGRITO}Usage${NORMAL}:\n"
	"\t${NEGRITO}env LOCAL_ROOT_LAMW=[dir]${NORMAL} ${lamw_mgr}    Installing LAMW and dependencies¹ on custom² directory\n"
	"\t${NEGRITO}${lamw_mgr//\-\-/'      '}${NORMAL}                              Install LAMW and dependencies¹\n"
	"\t$lamw_mgr\t${VERDE}--minimal${NORMAL}                   Install LAMW and dependencies with minimal crosscompile to Android¹\n"
	"\t$lamw_mgr\t${VERDE}--reinstall${NORMAL}                 Reinstall LAMW and dependencies without reset³\n"
	"\t$lamw_mgr\t${VERDE}--sdkmanager${NORMAL}\t${VERDE}[ARGS]${NORMAL}      Install LAMW and Run Android SDK Manager⁴\n"
	"\t$lamw_mgr\t${VERDE}--update-lamw${NORMAL}               To just upgrade LAMW framework (with the latest version available in git)\n"
	"\t$lamw_mgr\t${VERDE}--reset${NORMAL}                     To clean and reinstall LAMW\n"
	"\t$lamw_mgr\t${VERDE}--reset-aapis${NORMAL}               Reset Android API's to default\n"
	"\t${lamw_mgr//\-\-/}\t${NEGRITO}uninstall${NORMAL}                   To uninstall LAMW :(\n"
	"\t$lamw_mgr\t${VERDE}--help${NORMAL}, ${NEGRITO} help ${NORMAL}              Show help\n"                 
	"\n"
	"${NEGRITO}Installing LAMW on custom directory${NORMAL}\n"
	"\tenv LOCAL_ROOT_LAMW=[dir] ${lamw_mgr}\n"
	"sample:\n"
	"\t${NEGRITO}env LOCAL_ROOT_LAMW=${VERDE}/opt/LAMW${NORMAL}\t${lamw_mgr}\n"
	"\n"
	"${NEGRITO}Proxy Options:${NORMAL}\n"
	"\t$lamw_mgr\t${NEGRITO}[action]${NORMAL}  --use_proxy --server ${VERDE}[HOST]${NORMAL} --port ${VERDE}[NUMBER]${NORMAL}\n"
	"sample:\n\t$lamw_mgr\t --update-lamw --use_proxy --server 10.0.16.1 --port 3128\n"
	"\n"
	"${NEGRITO}Android SDK Manager [ARGS]:${NORMAL}\n"
	"sample:\n\t$lamw_mgr\t --sdkmanager  ${VERDE}--list_installed${NORMAL}\n"
	"\n\n${NEGRITO}Note:\n${NORMAL}"
	"\t¹ By default the installation waives the use of parameters, if LAMW is installed, it will only be updated!\n"
	"\t² After directory verification and validation (system directories and mount points will not be accepted)!\n"
	"\t³ Force a complete reinstall [ with all Android crosscompile ].\n"
	"\t⁴ If it is already installed, just run the Android SDK Tools with [ARGS].\n"
	)

	printf "${LAMW_OPTS[*]}" 

}
#iniciandoparametros
initParameters(){
	if [ $# = 3 ] ; then 
		if [ "$1" = "--use_proxy" ]; then 
			export USE_PROXY=1
			export PROXY_SERVER=$2
			export PORT_SERVER=$3
			export PROXY_URL="http://$2:$3"
			printf "PROXY_SERVER=$2\nPORT_SERVER=$3\n"
		fi
	fi
	
	if [ $USE_PROXY = 1 ]; then
		
		export http_proxy=$PROXY_URL
		export https_proxy=$PROXY_URL
	fi
}

TrapActions(){
	local magic_trap=(
		"$ANT_TAR_FILE" #0 
		"$ANT_HOME"		#1
		"$GRADLE_ZIP_FILE" #2
		"$GRADLE_HOME"   #3
		"$CMD_SDK_TOOLS_ZIP" #4
		"$CMD_SDK_TOOLS_DIR" #5
		"$FIXLP_ZIP" 
	)
	
	if [ $MAGIC_TRAP_INDEX -ge 0 ]; then
		local file_deleted="${magic_trap[MAGIC_TRAP_INDEX]}"
		if [ -e "$file_deleted" ]; then	
			rm  -r $file_deleted
		fi
	fi
	
	rm "$LAMW_MANAGER_LOCK"
}

handleSigTerm(){
	isProtectedTrapActions && return

	TrapActions 
	[ "$bg_pid" != "" ] && stopProgressBarAsFail
	wait
	
	exit 15
}
handleSigInt(){
	isProtectedTrapActions && return

	TrapActions 
	[ "$bg_pid" != "" ] &&  stopProgressBarAsCancel
	exit 2
}


resetTrapActions(){
	MAGIC_TRAP_INDEX=-1
}

protectedTrapActions(){
	MAGIC_TRAP_INDEX=-2
}

isProtectedTrapActions(){
	[ $MAGIC_TRAP_INDEX = -2 ]
}

startImplicitAction(){
	getImplicitInstall
	echo ""
	if [ $LAMW_IMPLICIT_ACTION_MODE = 0 ]; then
		printf "${NEGRITO}Implicit installation of LAMW starting in $TIME_WAIT seconds  ... ${NORMAL}\n"
		printf "Press control+c to exit ...\n"
		sleep $TIME_WAIT
		mainInstall
	else
		printf "${NEGRITO}Implicit LAMW Framework update starting in $TIME_WAIT seconds ... ${NORMAL}\n"
		printf "Press control+c to exit ...\n"
		sleep $TIME_WAIT 
		Repair
		checkProxyStatus;
		echo "Updating LAMW";
		getLAMWFramework;
		getFiller
		BuildLazarusIDE "1";
		changeOwnerAllLAMW "1";
	fi				
}

getCurrentSucessFiller(){
	case $1 in 
		0) echo "build to FPC ${NEGRITO}${2}${NORMAL}";;
		1) echo "build to Lazarus ${NEGRITO}${2}${NORMAL}";;
		2) echo "cleaning to FPC Sources ${NEGRITO}${2}${NORMAL}";;
		3) echo "building ${NEGRITO}${2}${NORMAL}";;
		4) echo "git checkout ${NEGRITO}${2}${NORMAL}";;			
	esac
}

#instalando tratadores de sinal	
setSignalHandles(){
	trap handleSigInt SIGINT 
	trap handleSigTerm SIGTERM
}

findUseProxyOpt(){
	for arg_index in ${!ARGS[@]}; do 
		arg=${ARGS[$arg_index]}
		if [ "$arg" = "--use_proxy" ];then
			INDEX_FOUND_USE_PROXY=$arg_index
			break
		fi
	done

}

parseProxyOpt(){
	if [ $INDEX_FOUND_USE_PROXY -lt 0 ]; then
		initParameters
	else 
		index_proxy_server=$((INDEX_FOUND_USE_PROXY+1))
		index_server_value=$((index_proxy_server+1))
		index_port_server=$((index_server_value+1))
		index_port_value=$((index_port_server+1))
		if [ "${ARGS[$index_proxy_server]}" = "--server" ]; then
			if [ "${ARGS[$index_port_server]}" = "--port" ] ;then
				initParameters "${ARGS[$INDEX_FOUND_USE_PROXY]}" "${ARGS[$index_server_value]}" "${ARGS[$index_port_value]}"
			else 
				echo "${VERMELHO}Error:${NORMAL}missing ${NEGRITO}--port${NORMAL}";exit 1
			fi
			unset ARGS[$INDEX_FOUND_USE_PROXY]
			unset ARGS[$index_proxy_server]
			unset ARGS[$index_server_value]
			unset ARGS[$index_port_server]
			unset ARGS[$index_port_value]
		else 
			echo "${VERMELHO}Error:${NORMAL}missing ${NEGRITO}--server${NORMAL}";exit 1
		fi
	fi
}

testConnectionInternet(){
	
	local sucess_filler="checking your internet connection"

	getFiller

	echo "${sucess_filler^} ..."

	startProgressBar
	
	if ! ping google.com -q -c4 &>/dev/null; then
		echo "${VERMELHO}Error:${NORMAL} check your internet connection"
		sleep 0.02
		stopProgressBarAsFail
		exit 1
	fi
	stopAsSuccessProgressBar
}


testConnectionInternetOnDemand(){
	for action in ${NEED_INTERNET_ACTIONS_REGEX[@]};do
		if [[ "${ARGS[@]}" =~ $action ]] || [[ "${ARGS[@]}" = "" ]]; then 
			testConnectionInternet 1>&2
			return
		fi
	done
}


parseFlags(){
    CheckFlags USE_PKEXEC "PKEXEC=1" 1
    CheckFlags NOBLINK 'NOBLINK=1' 1
}


helloMessage(){

	LAMW_INSTALL_VERSION=$(
		grep LAMW_INSTALL_VERSION\
		-m1  $LAMW_MANAGER_MODULES_PATH/headers/lamw_headers | 
		awk -F'=' '{ print $2 }' )

	LAMW_INSTALL_VERSION=${LAMW_INSTALL_VERSION//\"/}

	local message="$(<${LAMW_MANAGER_MODULES_PATH}/headers/.hello.txt)"
	local id=96
	local italic=3
	local blink=5
	local style1=$'\e[1;'$id'm'
	local style2=$'\e[1;'$blink'm'
	local style3=$'\e[1;'$italic'm'
	local version_message="${style3}v${LAMW_INSTALL_VERSION}${NORMAL}"

	local lamw_mgr="./lamw_manager"
	if [ "$USE_SETUP" = "1" ]; then
		lamw_mgr="bash lamw_manager_setup.sh\t${VERDE}--${NORMAL}"
	fi

	if [ $NOBLINK =  0 ]; then 
		echo -en "\n${style2}${style1}$message\t${version_message}\n\n"
		echo "${VERMELHO}Warning: ${NORMAL}use ${NEGRITO}NOBLINK=1${NORMAL} if you are photosensitive, sample:" 
		echo -e "\t$lamw_mgr ${NEGRITO}NOBLINK=1${NORMAL}\n\n" 
	else 
		echo -en "\n${style1}$message\t${version_message}${NORMAL}\n\n"
   	fi
}

parseMinimalOpt(){
	if [[ "${ARGS[*]}" =~ $MINIMAL_REGEX ]];then 
		LAMW_MINIMAL_INSTALL=1
		ARGS=(${ARGS[@]//'--minimal'/})
	fi
}


parseOpts(){
	findUseProxyOpt
	parseProxyOpt
	parseMinimalOpt
	parseFlags
}

initialConfig(){
	setSignalHandles
	parseOpts
	helloMessage 1>&2
	IsFileBusy "lamw_manager" "$LAMW_MANAGER_LOCK" 1>&2
	createLamwManagerLock
	getFiller
	checkIfDistroIsLikeDebian
	testConnectionInternetOnDemand
	StopGradleDaemon 1>&2
}


