#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.5.9.2
#Date: 01/01/2024
#Description: The "lamw-install.sh" is part of the core of LAMW Manager. This script configures the development environment for LAMW
#-------------------------------------------------------------------------------------------------#

# Verifica condicoes de inicializacao

export LAMW_MANAGER_MODULES_PATH=$(dirname "$0")

source /etc/os-release

#importando modulos de headers 
source "$LAMW_MANAGER_MODULES_PATH/headers/.index"
source "$LAMW_MANAGER_MODULES_PATH/installer/services.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/distro-overrides.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/configure.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/installer.sh"
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/lamw-settings-editor.sh"
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/root-lamw-settings-editor.sh"
source "$LAMW_MANAGER_MODULES_PATH/cross-builder/cross-builder.sh"
source "$LAMW_MANAGER_MODULES_PATH/components/progress-bar.sh"
source "$LAMW_MANAGER_MODULES_PATH/headers/admin-parser.sh"


getFiller
checkIfDistroIsLikeDebian
testConnectionInternetOnDemand $1

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
		RunAsAdmin 1
	;;

	"--sdkmanager")
		getStatusInstalation;
		[ $LAMW_INSTALL_STATUS = 0 ] && mainInstall
		echo "Please wait, starting ${NEGRITO}Android SDK Manager Command Line ${NORMAL} ..."
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
	"--reinstall")
		printf "Please wait ...\n"
		mainInstall
	;;

	"--reset")
		printf "Please wait ...\n"
		getStatusInstalation
		RunAsAdmin 2
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
	"" | "--use_proxy" |"--minimal")
		startImplicitAction	
	;;
	"--help"| "help") 
		lamw_manager_help
	;;
	"build-lazarus")
		getStatusInstalation
		if [ $LAMW_INSTALL_STATUS = 0 ]; then 
			testConnectionInternet 1>&2
			mainInstall
		else
			FORCE_LAZARUS_CLEAN_BUILD=1
			Repair 
			BuildLazarusIDE
			changeOwnerAllLAMW 1
		fi
	;;
	"get-root-lamw")
		echo "$ROOT_LAMW"
	;;
	*)
		printf "${VERMELHO}Invalid argument!${NORMAL}\n$(lamw_manager_help)" >&2
		exit 1
	;;
esac

exit $EXIT_STATUS