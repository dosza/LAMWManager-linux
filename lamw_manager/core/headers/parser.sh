#!/bin/bash


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
	"\t$lamw_mgr\t${VERDE}--sdkmanager${NORMAL}                Install LAMW and Run Android SDK Manager³\n"
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
	"\n\n${NEGRITO}Note:\n${NORMAL}"
	"\t¹ By default the installation waives the use of parameters, if LAMW is installed, it will only be updated!\n"
	"\t² After directory verification and validation (system directories and mount points will not be accepted)!\n"
	"\t³ If it is already installed, just run the Android SDK Tools\n"
	"\n"
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
	local sdk_tools_zip=$ANDROID_SDK
	#echo "MAGIC_TRAP_INDEX=$MAGIC_TRAP_INDEX";read
	local magic_trap=(
		"$ANT_TAR_FILE" #0 
		"$ANT_HOME"		#1
		"$GRADLE_ZIP_FILE" #2
		"$GRADLE_HOME"   #3
		"$sdk_tools_zip" #4
		"$ANDROID_SDK" #5
		"$NDK_ZIP" #6
		"$NDK_DIR_UNZIP" #7
	)
	
	if [ "$MAGIC_TRAP_INDEX" != "-1" ]; then
		local file_deleted="${magic_trap[MAGIC_TRAP_INDEX]}"
		if [ -e "$file_deleted" ]; then
			echo "deleting... $file_deleted"	
			rm  -rv $file_deleted
		fi
	fi
#	chattr -i /tmp/lamw-overrides.conf
	#exit 2
	rm '/tmp/lamw-overrides.conf'
}

TrapTermProcess(){
	TrapActions
	exit 15
}
TrapControlC(){
	TrapActions
	exit 2
}

startImplicitAction(){
	getImplicitInstall
	if [ $LAMW_IMPLICIT_ACTION_MODE = 0 ]; then
		echo "Please wait..."
		printf "${NEGRITO}Implicit installation of LAMW starting in $TIME_WAIT seconds  ... ${NORMAL}\n"
		printf "Press control+c to exit ...\n"
		sleep $TIME_WAIT
		mainInstall
		changeOwnerAllLAMW;
	else
		echo "Please wait ..."
		printf "${NEGRITO}Implicit LAMW Framework update starting in $TIME_WAIT seconds ... ${NORMAL}...\n"
		printf "Press control+c to exit ...\n"
		sleep $TIME_WAIT 
		Repair
		checkProxyStatus;
		echo "Updating LAMW";
		getLAMWFramework;
		BuildLazarusIDE "1";
		changeOwnerAllLAMW "1";
	fi				
}

#instalando tratadores de sinal	
trap TrapControlC 2 
if [ $# = 6 ] || [ $# = 7 ]; then
	if [ "$2" = "--use_proxy" ] ;then 
		if [ "$3" = "--server" ]; then
			if [ "$5" = "--port" ] ;then
				initParameters $2 $4 $6
			fi
		fi
	fi
else
	initParameters
fi

