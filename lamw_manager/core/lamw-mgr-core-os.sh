#!/usr/bin/env bash 

export LAMW_MANAGER_MODULES_PATH=$(dirname "$0")

source /etc/os-release

#importando modulos de headers 
source "$LAMW_MANAGER_MODULES_PATH/headers/common-shell.sh"
source "$LAMW_MANAGER_MODULES_PATH/headers/lamw4linux_env.sh"
source "$LAMW_MANAGER_MODULES_PATH/headers/lamw_headers"
source "$LAMW_MANAGER_MODULES_PATH/headers/parser.sh"
source "$LAMW_MANAGER_MODULES_PATH/headers/admin-parser.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/services.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/distro-overrides.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/configure.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/installer.sh"
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/lamw-settings-editor.sh"
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/root-lamw-settings-editor.sh"
source "$LAMW_MANAGER_MODULES_PATH/cross-builder/cross-builder.sh"
source "$LAMW_MANAGER_MODULES_PATH/components/progress-bar.sh"



isSafeLamwMgrCoreOs(){
	
	if [ ! $UID  = 0  ]|| [ ! -e "$LAMW_MANAGER_LOCK" ]; then
		return 1
	fi

	if ! ps ax | grep "$PPID\s.*lamw_manager" -q ;then 
		return 1
	fi

	return 0
}

CheckIfSafeStartLamwManager(){
	if ! isSafeLamwMgrCoreOs; then
		printf "${VERMELHO}Fatal Error: you need run lamw_manager first! ${NORMAL}\n"
		exit 1
	fi
}

checkRootLAMWInitStatus(){
	( [ $UID != 0 ]|| [ "$NO_EXISTENT_ROOT_LAMW_PARENT" = "" ]) && return 

	local parent="$(dirname NO_EXISTENT_ROOT_LAMW_PARENT)"

	if [ -e $parent ];then
		if [ -O $parent ]; then
				initROOT_LAMW
		fi
	fi

}

isLAMWUserOwnerROOTLAMW(){
	local status=0
	if [ -e "$ROOT_LAMW" ]; then 
		if  [ $UID = 0 ] && [ -O  "$ROOT_LAMW" ];then 
			status=1
		fi
	fi
	return $status
}

checkNeedXfceMitigation(){
	[ $NEED_XFCE_MITIGATION = 1 ] && return 
	
	if [ "$LAMW_USER_XDG_CURRENT_DESKTOP" = "XFCE" ] && [ "$LAMW_USER_DESKTOP_SESSION" = "XFCE" ]; then
		NEED_XFCE_MITIGATION=1
		PROG_TOOLS+=" gnome-terminal"
	fi
}


installSystemDependencies(){
	if [ $IS_DEBIAN = 0 ];then 
		CheckIfYourLinuxIsSupported; return
	fi
	installDebianDependencies	
}

adminInstallTasks(){
	checkIfDistroIsLikeDebian
	LAMWPackageManager
	checkRootLAMWInitStatus
	if ! isLAMWUserOwnerROOTLAMW; then
		changeOwnerAllLAMW
	fi
	installSystemDependencies
	CleanOldCrossCompileBins
}

runPostInstallActions(){
		IsFileBusy  "postInstall actions" "$LAMW_MANAGER_CORE_LOCK" 
		enableADBtoUdev
		IsFileBusy "crossbinLock" "$CROSSBIN_LOCK"
		CleanOldCrossCompileBins
}


main(){
	
	CheckIfSafeStartLamwManager
	getFiller

	case "$1" in 
		"0")
		
			adminInstallTasks
			runPostInstallActions &
		;;
		"1")
			CleanOldConfig
		;;
		"2")
			CleanOldConfig
			adminInstallTasks
			runPostInstallActions &
		;;
	esac
}

main $1