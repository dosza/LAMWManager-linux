#!/bin/bash

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
		SDK_LICENSES_PARAMETERS=( --licenses --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
		SDK_MANAGER_CMD_PARAMETERS[${#SDK_LICENSES_PARAMETERS[*]}]="--no_https --proxy=http"
		SDK_MANAGER_CMD_PARAMETERS[${#SDK_LICENSES_PARAMETERS[*]}]="--proxy_host=$PROXY_SERVER"
		SDK_MANAGER_CMD_PARAMETERS[${#SDK_LICENSES_PARAMETERS[*]}]="--proxy_port=$PORT_SERVER" 

		SDK_MANAGER_CMD_PARAMETERS2_PROXY=(
			'--no_https' 
			"--proxy-host=$PROXY_SERVER" 
			"--proxy-port=$PORT_SERVER" #'--proxy=http'
		)
		
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
