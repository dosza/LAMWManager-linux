
#!/bin/bash
#Universidade federal de Mato Grosso
#Curso ciencia da computação
#Versao  0.3.2
#Descrição: Este script configura o ambiente de desenvolvimento para o LAMW
#V


#zenity --info --text "ANDROID_HOME=$ROOT_LAMW"

LAMW_MANAGER_MODULES_PATH=$0
LAMW_MANAGER_MODULES_PATH=${LAMW_MANAGER_MODULES_PATH%/lamw-install.sh*}

source "$LAMW_MANAGER_MODULES_PATH/modules/lamw_headers"
source "$LAMW_MANAGER_MODULES_PATH/modules/common-shell.sh"
source "$LAMW_MANAGER_MODULES_PATH/modules/installer.sh"
source "$LAMW_MANAGER_MODULES_PATH/modules/lamw-settings-editor.sh"
source "$LAMW_MANAGER_MODULES_PATH/modules/cross-builder.sh"

#_------------ OS function t

TrapControlC(){
	sdk_tools_zip=$ANDROID_SDK
	#echo "magicTrapIndex=$magicTrapIndex";read
	magic_trap=(
		"$ANT_TAR_FILE" #0 
		"$ANT_HOME"		#1
		"$GRADLE_ZIP_FILE" #2
		"$GRADLE_HOME"   #3
		"$sdk_tools_zip" #4
		"$ANDROID_SDK" #5
		"android-ndk-r18b-linux-x86_64.zip" #6
		"android-ndk-r18b" #7
	)
	
	if [ "$magicTrapIndex" != "-1" ]; then
		file_deleted="${magic_trap[magicTrapIndex]}"
		if [ -e "$file_deleted" ]; then
			echo "deleting... $file_deleted"
			rm  -rv $file_deleted
		fi
	fi
	exit 2
}



checkForceLAMW4LinuxInstall(){
	args=($*)
	for((i=0;i<${#args[*]};i++))
	do
		#printf "${VERMELHO} ${args[i]} ${NORMAL}\n"
		if [ "${args[i]}" = "--force" ]; then
			export FORCE_LAWM4INSTALL=1
			break
		fi
	done
}


#Build lazarus ide
BuildLazarusIDE(){
	
	make_opts=()

	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		wrapperParseFPC
		if [ -e "/usr/local/bin/fpc" ]; then
			cp "$PPC_CONFIG_PATH" "/root/.fpc.cfg"
			export PATH=$FPC_TRUNK_LIB_PATH:/usr/local/bin:$PATH
			make_opts=(
				"PP=${FPC_TRUNK_LIB_PATH}/ppcx64"
				"FPC_VERSION=$FPC_TRUNK_VERSION"
			)
			echo "${make_opts[*]}"
		fi
	fi
	ln -sf $LAMW4LINUX_HOME/$LAZARUS_STABLE $LAMW_IDE_HOME  # link to lamw4_home directory 
	ln -sf $LAMW_IDE_HOME/lazarus $LAMW4LINUX_EXE_PATH #link  to lazarus executable
	changeDirectory $LAMW_IDE_HOME
	if [ $# = 0 ]; then 
		make clean all  ${make_opts[*]}
	fi
		#build ide  with lamw framework 
	for((i=0;i< ${#LAZBUILD_PARAMETERS[@]};i++))
	do
		./lazbuild ${LAZBUILD_PARAMETERS[i]}
		if [ $? != 0 ]; then
			./lazbuild ${LAZBUILD_PARAMETERS[i]}
		fi
	done

	if [ -e /root/.fpc.cfg ]; then
		rm /root/.fpc.cfg
	fi
}

#cd not a native command, is a systemcall used to exec, read more in exec man 

#this code add support a proxy 
checkProxyStatus(){
	if [ $USE_PROXY = 1 ] ; then
		ActiveProxy 1
	else
		ActiveProxy 0
	fi
}

#this function repair fpc, caso este tenha sido desinstalado ou atualizado


	checkForceLAMW4LinuxInstall $*
	# echo "----------------------------------------------------------------------"
	 printf "${LAMW_INSTALL_WELCOME[*]}"
	# echo "----------------------------------------------------------------------"
	#echo "LAMW Manager (Linux supported Debian 9, Ubuntu 16.04 LTS, Linux Mint 18)
	#Generate LAMW4Linux to android-sdk=$SDK_VERSION"
	if [ $FORCE_LAWM4INSTALL = 1 ]; then
		echo "${NEGRITO}Warning: Earlier versions of Lazarus (debian package) will be removed!${NORMAL}"
	else
		echo "${NEGRITO}Warning:${NORMAL}${NEGRITO}This application not  is compatible with ${VERMELHO}lazarus-project${NORMAL} (debian package)${NORMAL}"
		echo "use ${NEGRITO}--force${NORMAL} parameter remove anywhere lazarus (debian package)"
		sleep 1
	fi

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
	 
	GenerateScapesStr
	

#Parameters are useful for understanding script operation
case "$1" in
	"version")
	echo "LAMW4Linux  version $LAMW_INSTALL_VERSION"
	;;

	"uninstall")
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
			wrapperRepair
			checkProxyStatus;
			echo "Updating LAMW";
			getLAMWFramework;
			sleep 1;
			BuildLazarusIDE "1";
			changeOwnerAllLAMW "1";
		fi
	;;
	"install")
		export OLD_ANDROID_SDK=1
		export NO_GUI_OLD_SDK=1
		mainInstall
		changeOwnerAllLAMW
	;;

	"--reset")
		printf "Please wait ...\n"
		CleanOldConfig
		printf "Mode SDKTOOLS=24 with ant support "
		export OLD_ANDROID_SDK=1
		export NO_GUI_OLD_SDK=1
		mainInstall
		changeOwnerAllLAMW
	;;
	"--reset-aapis")
		export OLD_ANDROID_SDK=1
		export NO_GUI_OLD_SDK=1
		getStatusInstalation
		if [ $LAMW_INSTALL_STATUS = 1 ]; then
			RepairOldSDKAndroid
		else
			mainInstall
		fi
	;;
	"delete_paths")
		cleanPATHS
	;;
	"get-status")
		getStatusInstalation
	;;
	
	"")
		
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
			wrapperRepair
			checkProxyStatus;
			echo "Updating LAMW";
			getLAMWFramework;
			BuildLazarusIDE "1";
			changeOwnerAllLAMW "1";
		fi					
	;;
	"--use_proxy")
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
			checkProxyStatus;
			echo "Updating LAMW";
			getLAMWFramework;
			BuildLazarusIDE "1";
			changeOwnerAllLAMW "1";
		fi
	;;

	*)
		printf "${lamw_opts[*]}"
	;;

esac
