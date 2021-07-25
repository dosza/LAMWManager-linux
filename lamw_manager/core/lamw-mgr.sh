#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.0
#Date: 06/12/2021
#Description: The "lamw-install.sh" is part of the core of LAMW Manager. This script configures the development environment for LAMW
#-------------------------------------------------------------------------------------------------#

# Verifica condicoes de inicializacao

LAMW_MANAGER_MODULES_PATH=$0
LAMW_MANAGER_MODULES_PATH=${LAMW_MANAGER_MODULES_PATH%/lamw-mgr.sh*}

#importando modulos de headers 
source "$LAMW_MANAGER_MODULES_PATH/headers/.index"
source "$LAMW_MANAGER_MODULES_PATH/installer/api.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/installer.sh"
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/lamw-settings-editor.sh"
source "$LAMW_MANAGER_MODULES_PATH/cross-builder/cross-builder.sh"



#Parameters are useful for understanding script operation
case "$1" in
	"version")
		printf "${LAMW_INSTALL_WELCOME[*]}"
		printf "Linux supported\n${LAMW_LINUX_SPP[*]}"
	;;

	"uninstall")
		UNINSTALL_LAMW=1
		getStatusInstalation
		[ $LAMW_INSTALL_STATUS = 1 ] && checkLAMWManagerVersion >/dev/null
		CleanOldConfig;
		changeOwnerAllLAMW
	;;

	"--sdkmanager")
	getStatusInstalation;
	if [ $LAMW_INSTALL_STATUS = 1 ];then
		$ANDROID_SDK/tools/android update sdk
		changeOwnerAllLAMW 

	else
		mainInstall
		$ANDROID_SDK/tools/android update sdk
		changeOwnerAllLAMW
	fi 	
	;;
	"--update-lamw")
		getStatusInstalation
		if [ $LAMW_INSTALL_STATUS  = 0 ]; then
			mainInstall
			changeOwnerAllLAMW

		else

			Repair
			if [ $(updateLAMWDeps) = 1 ]; then
				echo "${VERMELHO}Warning:There are updates for LAMW4Linux${NORMAL}"
				echo "run ${NEGRITO}./lamw_manager to update:${NORMAL}"
			fi
			
			checkProxyStatus;
			echo "Updating LAMW";
			getLAMWFramework;
			sleep 1;
			BuildLazarusIDE "1"
			changeOwnerAllLAMW "1";
		fi
	;;
	"install")
		#export OLD_ANDROID_SDK=1
		export NO_GUI_OLD_SDK=1
		mainInstall
		changeOwnerAllLAMW
	;;

	"--reset")
		printf "Please wait ...\n"
		getStatusInstalation
		CleanOldConfig
	#	printf "Mode SDKTOOLS=24 with ant support "
	#	export OLD_ANDROID_SDK=1
		export NO_GUI_OLD_SDK=1
		mainInstall
		changeOwnerAllLAMW
	;;
	"--reset-aapis")
	#	export OLD_ANDROID_SDK=1
		export NO_GUI_OLD_SDK=1
		getStatusInstalation
		if [ $LAMW_INSTALL_STATUS = 1 ]; then
			RepairOldSDKAndroid
		else
			mainInstall
			changeOwnerAllLAMW
		fi
	;;
	"")
		startImplicitAction	
	;;
	"--use_proxy")
		startImplicitAction
	;;
	"--help"| "help") 
		lamw_manager_help
	;;
	"build-lazarus")
		BuildLazarusIDE 1
		changeOwnerAllLAMW 1
	;;
	*)
		printf "${VERMELHO}Invalid argument!${NORMAL}\n$(lamw_manager_help)" >&2
		exit 1
	;;
esac
#chattr -i /tmp/lamw-overrides.conf