#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.3.1
#Date: 12/13/2021
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
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/root-lamw-settings-editor.sh"
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
	[ $LAMW_INSTALL_STATUS = 0 ] && mainInstall
	getAndroidAPIS  ${ARGS[@]:1}
	changeOwnerAllLAMW
 
	;;
	"--update-lamw")
		getStatusInstalation
		if [ $LAMW_INSTALL_STATUS  = 0 ]; then
			mainInstall

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
		mainInstall
	;;

	"--reset")
		printf "Please wait ...\n"
		getStatusInstalation
		CleanOldConfig
		mainInstall
	;;
	"--reset-aapis")
		getStatusInstalation
		if [ $LAMW_INSTALL_STATUS = 1 ]; then
			resetAndroidAPIS
		else
			mainInstall
		fi
	;;
	"" | "--use_proxy")
		startImplicitAction	
	;;
	"--help"| "help") 
		lamw_manager_help
	;;
	"build-lazarus")
		getStatusInstalation
		if [ $LAMW_INSTALL_STATUS = 0 ]; then 
			mainInstall
		else
			Repair 
			BuildLazarusIDE
			changeOwnerAllLAMW 1
		fi
	;;
	*)
		printf "${VERMELHO}Invalid argument!${NORMAL}\n$(lamw_manager_help)" >&2
		exit 1
	;;
esac