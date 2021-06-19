#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.0
#Date: 06/12/2021
#Description: "installer.sh" is part of the core of LAMW Manager. Contains routines for installing LAMW development environment
#-------------------------------------------------------------------------------------------------#


#prepare upgrade
LAMWPackageManager(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then 
		
		local old_lamw_ide_home="$LAMW4LINUX_HOME/lamw4linux"

		if [ -e "$old_lamw_ide_home"  ]; then
			echo "Uninstalling  Old Lazarus ..."
			rm "$old_lamw_ide_home"  -rf
		fi

		for((i=0;i<${#LAZARUS_OLD_STABLE[*]};i++))
		do
			local old_lazarus_home=$LAMW4LINUX_HOME/${LAZARUS_OLD_STABLE[i]}
			if [ -e "$old_lazarus_home" ]; then
				rm "$old_lazarus_home" -rf
			fi
		done
		
		if [ -e "$OLD_FPC_CFG_PATH" ]; then
			rm "$OLD_FPC_CFG_PATH"
		fi
	
		#fixs 0.3.1 to 0.3.2

		for i  in ${!OLD_FPC_SOURCES[*]}; do
			if [ -e ${OLD_FPC_SOURCES[i]} ]; then
				rm  -rf ${OLD_FPC_SOURCES[i]}
			fi
		done

		for gradle in ${OLD_GRADLE[*]}
		do
			if [ -e "$gradle" ]; then
				./$gradle/bin/gradle --stop
				rm -rf $gradle 
			fi
		done

		for ((i=0;i<${#OLD_ANT[*]};i++))
		do
			if [ -e ${OLD_ANT[i]} ]; then 
				rm -rf ${OLD_ANT[i]}
			fi
		done
	fi

}
getStatusInstalation(){
	CheckUnsupporteFPC
	if [  -e $LAMW4LINUX_HOME/lamw-install.log ]; then
		export LAMW_INSTALL_STATUS=1
		return 1
	else 
		export OLD_ANDROID_SDK=1
		export NO_GUI_OLD_SDK=1
		return 0;
	fi
}

SearchPackage(){
	local index=-1
	#vetor que armazena informações sobre a intalação do pacote
	if [ "$1" != "" ]  ; then
		PACKS=( $(dpkg -l $1) )
		
		local tam=${#PACKS[@]}
		if  [ $tam = 0 ] ; then
			apt-get install fpc -y
			PACKS=( $(dpkg -l $1) )
		fi

		for (( i = 0 ; i < ${#PACKS[*]};i++))
		do
			if [ "${PACKS[i]}" = "$1" ] ; then
				((index=i))
				((index++))
				FPC_VERSION=${PACKS[index]}
				#echo "${PACKS[index]}"
				break
			fi
		done
	fi
	return $index
}

CheckUnsupporteFPC(){
	if [ $UNSUPPORTED_FPC_MSG = 0 ]; then
		exec 2> /dev/null dpkg -s  fpc | grep 'Status: install'  > /dev/null
		if [ $? = 0 ]; then
			echo  -e "\n${VERMELHO}Warning:${NORMAL} Freepascal of fpc package detected!"
			echo  -e "We recommend uninstalling this command: ${NEGRITO}sudo apt-get remove fpc --autoremove -y${NORMAL}\n"
			export UNSUPPORTED_FPC_MSG=1	
		fi
		
	fi
}

#Fix Debian 10/OpenJDK Support 
CheckOpenJDK8Support(){
	exec 2> /dev/null apt show  openjdk-8-jdk | grep 'Source: openjdk-8' > /dev/null
	if [ $? != 0 ]; then 
		printf "Warning:${VERMELHO}OpenJDK 8 is not supported, using OpenJDK11!${NORMAL}\n"
		export OPENJDK_DEFAULT=$OPENJDK_LTS
	fi
}

#setJRE8 as default
setJava8asDefault(){
	#se o jdk > 8 nada  sai da funçao
	if [ $OPENJDK_DEFAULT = $OPENJDK_LTS ]; then 
		return 
	fi

	local path_java=($(dpkg -L openjdk-8-jre))
	local found_path=""
	for((i = 0; i < ${#path_java[@]} ; i++ )); do
		wi=${path_java[$i]}
		case "$wi" in
			*"jre"*)
				if [ -e $wi/bin/java ]; then
					#printf "found: i=$i $wi\nStopping search ...\n"
					found_path=$wi
					export JAVA_PATH="$found_path/bin/java"
					update-alternatives --set java $JAVA_PATH
					break;
				fi
			;;
		esac
	done
}

#install deps
installDependences(){
	CheckOpenJDK8Support
	AptInstall $LIBS_ANDROID $PROG_TOOLS  openjdk-${OPENJDK_DEFAULT}-jdk 
		
}

getFPCSourcesTrunk(){
	mkdir -p $FPC_TRUNK_SOURCE_PATH
	changeDirectory $FPC_TRUNK_SOURCE_PATH
	svn checkout $FPC_TRUNK_URL --force
	if [ $? != 0 ]; then
		svn cleanup "$FPC_TRUNK_SVNTAG"
		svn checkout "$FPC_TRUNK_URL" --force
		if [ $? != 0 ]; then 
			svn cleanup "$FPC_TRUNK_SVNTAG"
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
	parseFPCTrunk
}

getFPCStable(){
	local link="https://sourceforge.net/projects/lazarus/files/Lazarus%20Linux%20amd64%20DEB/Lazarus%202.0.8/fpc-laz_3.0.4-1_amd64.deb"
	if [ ! -e "$LAMW4LINUX_HOME/usr" ]; then 
		mkdir -p "$LAMW4LINUX_HOME/usr"
	fi

	cd "$LAMW4LINUX_HOME/usr"
	if  [ ! -e "$FPC_LIB_PATH" ]; then
		echo "doesn't exist $FPC_PATH"
		Wget $link
		if [ -e "$FPC_DEB" ]; then
			local tmp_files=(
				data.tar.xz
				control.tar.gz
				debian-binary
				"$FPC_DEB"
			)
			ar x "$FPC_DEB"
			if [ -e data.tar.xz ]; then 
				tar -xvf data.tar.xz
			fi
			if [ -e $LAMW4LINUX_HOME/usr/usr ]; then
				mv $LAMW4LINUX_HOME/usr/usr $LAMW4LINUX_HOME/usr/local
			fi
			for i in ${!tmp_files[@]}; do  
				if [ -e ${tmp_files[i]} ]; then rm ${tmp_files[i]} ; fi
			done	
		fi
		export PPC_CONFIG_PATH=$FPC_LIB_PATH
		$FPC_MKCFG_EXE -d basepath=$FPC_LIB_PATH -o $FPC_LIB_PATH/fpc.cfg;
	fi
}
#get Lazarus Sources
getLazarusSources(){
	changeDirectory $LAMW4LINUX_HOME
	svn co $LAZARUS_STABLE_SRC_LNK
	if [ $? != 0 ]; then  #case fails last command , try svn chekout 
		svn cleanup $LAZARUS_STABLE
		svn co $LAZARUS_STABLE_SRC_LNK
		if [ $? != 0 ]; then 
			svn cleanup $LAZARUS_STABLE
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
}

#GET LAMW FrameWork
getLAMWFramework(){
	local git_param=("clone" "$LAMW_SRC_LNK")
	changeDirectory $ROOT_LAMW
	#Remove LAMW  downloaded by SVN
	if [ -e "$ROOT_LAMW/lazandroidmodulewizard.git" ]; then 
		if [ -e "$ROOT_LAMW/lazandroidmodulewizard" ]; then 
			rm -fr "$ROOT_LAMW/lazandroidmodulewizard"
			rm -fr "$ROOT_LAMW/lazandroidmodulewizard.git"
		fi
	fi

	if [ -e lazandroidmodulewizard/.git ]  ; then
		changeDirectory "$ROOT_LAMW/lazandroidmodulewizard"
		git_param=("pull")
	fi
	
	git ${git_param[*]}
	if [ $? != 0 ]; then #case fails last command , try svn chekout
		
		git_param=("clone" "$LAMW_SRC_LNK")
		changeDirectory $ROOT_LAMW
		#chmod 777 -Rv lazandroidmodulewizard
		if [ -e $ROOT_LAMW/lazandroidmodulewizard ]; then 
			rm -rf $ROOT_LAMW/lazandroidmodulewizard
		fi
		git ${git_param[*]}
		if [ $? != 0 ]; then 
			if [ -e $ROOT_LAMW/lazandroidmodulewizard ]; then 
				rm -rf $ROOT_LAMW/lazandroidmodulewizard
			fi
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
	
}
AntTrigger(){
	if [ $OLD_ANDROID_SDK = 1 ]; then 
		if [ $OPENJDK_DEFAULT = $OPENJDK_LTS ]; then 
			if [ -e "$ANDROID_SDK/tools/ant" ]; then 
				mv "$ANDROID_SDK/tools/ant" "$ANDROID_SDK/tools/.ant"
			fi
		else 
			if [ -e "$ANDROID_SDK/tools/.ant" ]; then 
				mv "$ANDROID_SDK/tools/.ant" "$ANDROID_SDK/tools/ant"
			fi
		fi
	fi
}
#this function get ant 
getAnt(){
	if [ $OLD_ANDROID_SDK = 0 ]; then  #sem ação se ant nao é suportado
		return
	fi
	changeDirectory "$ROOT_LAMW" 
	if [ ! -e "$ANT_HOME" ]; then
		MAGIC_TRAP_INDEX=0 # preperando o indice do arquivo/diretório a ser removido
		trap TrapControlC  2
		Wget $ANT_TAR_URL
		MAGIC_TRAP_INDEX=1
		tar -xvf "$ANT_TAR_FILE"
	fi

	if [ -e  $ANT_TAR_FILE ]; then
		rm $ANT_TAR_FILE
	fi
}

getGradle(){
	changeDirectory $ROOT_LAMW
	if [ ! -e "$GRADLE_HOME" ]; then
		MAGIC_TRAP_INDEX=2 #Set arquivo a ser removido
		trap TrapControlC  2 # set armadilha para o signal2 (siginterrupt)
		Wget $GRADLE_ZIP_LNK
		MAGIC_TRAP_INDEX=3
		unzip -o  $GRADLE_ZIP_FILE
	fi

	if [ -e  $GRADLE_ZIP_FILE ]; then
		rm $GRADLE_ZIP_FILE
	fi
}

getNDK(){
	if [ $OLD_ANDROID_SDK = 0 ]; then
		return 
	fi
	changeDirectory "$ANDROID_SDK"
	if [ -e  "$ANDROID_SDK/ndk-bundle" ]; then 
		for i in ${!OLD_NDK_VERSION_STR[*]}; do
			 grep ${OLD_NDK_VERSION_STR[i]} "$ANDROID_SDK/ndk-bundle/source.properties" > /dev/null
			if [ $? = 0 ]; then 
				rm -rf $ANDROID_SDK/ndk-bundle
				break
			fi
		done
	fi

	if [ ! -e ndk-bundle ] ; then
		MAGIC_TRAP_INDEX=6
		trap TrapControlC 2 
		Wget $NDK_URL	
		MAGIC_TRAP_INDEX=7
		unzip -o  $NDK_ZIP
		MAGIC_TRAP_INDEX=-1
		mv $NDK_DIR_UNZIP ndk-bundle
		if [ -e $NDK_ZIP ]; then 
			rm $NDK_ZIP
		fi
	fi
	trap - SIGINT  #removendo a traps
	MAGIC_TRAP_INDEX=-1
}
#Get Gradle and SDK Tools 
getAndroidSDKTools(){
	initROOT_LAMW
	changeDirectory $ROOT_LAMW

	if [ $OLD_ANDROID_SDK = 1 ]; then #mode OLD SDK (2-4 with ant support )
		export SDK_TOOLS_VERSION="r25.2.5"
		export SDK_TOOLS_URL="https://dl.google.com/android/repository/tools_r25.2.5-linux.zip"
		export SDK_TOOLS_ZIP="tools_r25.2.5-linux.zip"
	fi

	changeDirectory $ANDROID_SDK
	if [ ! -e tools ];then
		trap TrapControlC  2
		MAGIC_TRAP_INDEX=4
		Wget $SDK_TOOLS_URL
		MAGIC_TRAP_INDEX=5
		unzip -o  $SDK_TOOLS_ZIP
		rm $SDK_TOOLS_ZIP
		AntTrigger
	fi
}

getSDKAndroid(){
	changeDirectory $ANDROID_SDK/tools/bin #change directory
	yes | ./sdkmanager ${SDK_LICENSES_PARAMETERS[*]}
	if [ $? != 0 ]; then 
		yes | ./sdkmanager ${SDK_LICENSES_PARAMETERS[*]}
		if [ $? != 0 ]; then
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
	for((i=0;i<${#SDK_MANAGER_CMD_PARAMETERS[*]};i++))
	do
		echo "Please wait, downloading ${NEGRITO}${SDK_MANAGER_CMD_PARAMETERS[i]}${NORMAL}\"..."
		if [ $i = 0 ]; then 
			yes | ./sdkmanager ${SDK_MANAGER_CMD_PARAMETERS[i]}  # instala sdk sem intervenção humana 
			if [ $? != 0 ]; then 
				yes | ./sdkmanager ${SDK_MANAGER_CMD_PARAMETERS[i]}
				if [ $? != 0 ]; then
					echo "possible network instability! Try later!"
					exit 1
				fi
			fi 
		else
			./sdkmanager ${SDK_MANAGER_CMD_PARAMETERS[i]}

			if [ $? != 0 ]; then 
				./sdkmanager ${SDK_MANAGER_CMD_PARAMETERS[i]}
				if [ $? != 0 ]; then
					echo "possible network instability! Try later!"
					exit 1
				fi
			fi
		fi
	done
}

getOldAndroidSDK(){
	local sdk_manager_sdk_paths=(
		"$ANDROID_SDK/platforms/android-$ANDROID_SDK_TARGET"
		"$ANDROID_SDK/platform-tools"
		"$ANDROID_SDK/build-tools/$ANDROID_BUILD_TOOLS_TARGET"
		"$ANDROID_SDK/extras/google/google_play_services"
		$ANDROID_SDK/extras/{android,google}/m2repository
		$ANDROID_SDK/extras/google/market_{licensing,apk_expansion}
		"$ANDROID_SDK/build-tools/$GRADLE_MIN_BUILD_TOOLS"
	)

	if [ -e $ANDROID_SDK/tools/android  ]; then 
		changeDirectory $ANDROID_SDK/tools
		if [ $NO_GUI_OLD_SDK = 0 ]; then
			echo "before update-sdk"
			$ANDROID_SDK/tools/android  update sdk
		else 
			for((i=0;i<${#SDK_MANAGER_CMD_PARAMETERS2[*]};i++))
			do
				echo "Getting ${NEGRITO}${SDK_MANAGER_CMD_PARAMETERS2[i]}${NORMAL} ..."
				#read;
			#	ls "$ANDROID_SDK/${sdk_manager_sdk_paths[i]}";read
				if [ ! -e "${sdk_manager_sdk_paths[i]}" ];then
					echo "y" |   ./android update sdk --all --no-ui --filter ${SDK_MANAGER_CMD_PARAMETERS2[i]} ${SDK_MANAGER_CMD_PARAMETERS2_PROXY[*]}
					if [ ! -e "${sdk_manager_sdk_paths[i]}" ]; then
						echo "y" |   ./android update sdk --all --no-ui --filter ${SDK_MANAGER_CMD_PARAMETERS2[i]} ${SDK_MANAGER_CMD_PARAMETERS2_PROXY[*]}
						if [ ! -e "${sdk_manager_sdk_paths[i]}" ]; then
							echo "possible network instability! Try later!"
							exit 1
						fi
					fi
				fi	
			done 
		fi
	fi
}

RepairOldSDKAndroid(){
	local sdk_manager_fails=(
		"platforms"
		"platform-tools"
		"build-tools"
		"extras"
	)
	echo "${VERMELHO}Warning:${NORMAL} All Android API'S will  be unistalled!"
	echo "Only the default APIs will be reinstalled!"
	for ((i=0;i<${#sdk_manager_fails[*]};i++))
	do
		local current_sdk_path="${ANDROID_SDK}/${sdk_manager_fails[i]}"
		if [ -e $current_sdk_path ]; then
			rm -rf $current_sdk_path
		fi
	done

	setLAMWDeps
	getOldAndroidSDK
	for ((i=0;i<${#sdk_manager_fails[*]};i++))
	do
		local current_sdk_path="${ANDROID_SDK}/${sdk_manager_fails[i]}"
		if [ -e $current_sdk_path ]; then
			chown $LAMW_USER:$LAMW_USER -R $current_sdk_path
		fi
		chown $LAMW_USER:$LAMW_USER -R $LAMW_USER_HOME/.android
	done

}



#Addd sdk to .bashrc and .profile


getAndroidAPIS(){
	if [ $OLD_ANDROID_SDK = 0 ]; then
		getSDKAndroid
	else
		getOldAndroidSDK
	fi
}
Repair(){
	local flag_need_repair=0 # flag de reparo 
	local flag_upgrade_lazarus=0
	local aux_path="$LAMW4LINUX_HOME/fpcsrc"
	local expected_fpc_src_path="$FPC_TRUNK_SOURCE_PATH/${FPC_TRUNK_SVNTAG}"

	getStatusInstalation 
	if [ $LAMW_INSTALL_STATUS = 1 ]; then # só executa essa funcao se o lamw tiver instalado
		local flag_old_fpc=""
		checkLAMWManagerVersion

		if [ "$(which git)" = "" ] || [ "$(which wget)" = "" ] || [ "$(which jq)" = "" ]; then
			echo "Missing lamw_manager required tools!, starting install base Dependencies ..."
			installDependences
			flag_need_repair=1
		fi
		wrapperParseFPC
		if [ ! -e $expected_fpc_src_path ]; then
			getFPCSourcesTrunk
			flag_need_repair=1
		fi
			
		if [ $flag_need_repair = 1 ]; then
			ConfigureFPCCrossAndroid
			CleanOldCrossCompileBins
			buildCrossAndroid
			BuildLazarusIDE
			CreateBinutilsSimbolicLinks
			enableADBtoUdev
			writeLAMWLogInstall
			changeOwnerAllLAMW
		fi
	fi
}

setOldAndroidSDKStatus(){
	if [  $1 = 0 ]; then
		export OLD_ANDROID_SDK=0
	else 
		export OLD_ANDROID_SDK=1
	fi
}

checkLAMWManagerVersion(){
	local ret=0
	for i  in ${!OLD_LAMW_INSTALL_VERSION[*]};do
		grep "^Generate LAMW_INSTALL_VERSION=${OLD_LAMW_INSTALL_VERSION[i]}"  "$ANDROID_SDK/ndk-bundle/source.properties" > /dev/null
		if [ $? = 0 ]; then 
			CURRENT_OLD_LAMW_INSTALL_INDEX=$i
			ret=1;
			break
		fi
	done

	echo $ret;
}

setOldLAMW4LinuxActions(){
	if [ $1 = 1 ]; then 
		echo "You need upgrade your LAMW4Linux!"
		export LAMW_IMPLICIT_ACTION_MODE=0
		export NO_GUI_OLD_SDK=1
		LAMWPackageManager
	else
		echo "${VERMELHO}Your LAMW development environment was generated by a newer version of LAMW Manager!${NORMAL}"
		exit 1
	fi
}

checkChangeLAMWDeps(){
	local flag_is_old_lamw=$(updateLAMWDeps)
			
	if [ $flag_is_old_lamw = 0 ]; then
		export LAMW_IMPLICIT_ACTION_MODE=1
	else
		setOldLAMW4LinuxActions $flag_is_old_lamw
	fi
}

#get implict install 
getImplicitInstall(){

	local lamw_install_log_path="$LAMW4LINUX_HOME/lamw-install.log"

	if [ ! -e "$lamw_install_log_path" ]; then
		export NO_GUI_OLD_SDK=1
	else
		grep "OLD_ANDROID_SDK=0" "$lamw_install_log_path"  > /dev/null
		setOldAndroidSDKStatus $?
		
		grep "Generate LAMW_INSTALL_VERSION=$LAMW_INSTALL_VERSION" "$lamw_install_log_path" 	> /dev/null
		
		if [ $? = 0 ]; then
			checkChangeLAMWDeps
		else
			local flag_is_old_lamw=$(checkLAMWManagerVersion)
			setOldLAMW4LinuxActions $flag_is_old_lamw
		fi
	fi
}

#Build lazarus ide
BuildLazarusIDE(){
	
	local make_opts=()

	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		wrapperParseFPC
		if [ -e "$FPC_TRUNK_EXEC_PATH/fpc" ]; then
			export PATH=$FPC_TRUNK_LIB_PATH:$FPC_TRUNK_EXEC_PATH:$PATH
			make_opts=(
				"PP=${FPC_TRUNK_LIB_PATH}/ppcx64"
				"FPC_VERSION=$_FPC_TRUNK_VERSION"
			)
		fi
	fi


	if [ ! -e "$LAMW_IDE_HOME" ]; then  
		ln -sf $LAMW4LINUX_HOME/$LAZARUS_STABLE $LAMW_IDE_HOME # link to lamw4_home directory 
	fi  

	if [ ! -e "$LAMW4LINUX_EXE_PATH" ]; then 
		ln -sf $LAMW_IDE_HOME/lazarus $LAMW4LINUX_EXE_PATH  #link  to lazarus executable
	fi


	changeDirectory $LAMW_IDE_HOME
	if [ $# = 0 ]; then 
		make clean all  ${make_opts[*]}
	fi
	
	initLAMw4LinuxConfig
		#build ide  with lamw framework 
	for((i=0;i< ${#LAMW_PACKAGES[@]};i++))
	do
		local lamw_build_opts=(--build-ide= --add-package ${LAMW_PACKAGES[i]} --primary-config-path=$LAMW4_LINUX_PATH_CFG  --lazarusdir=$LAMW_IDE_HOME)
		./lazbuild  ${lamw_build_opts[*]}
		if [ $? != 0 ]; then
			./lazbuild ${lamw_build_opts[*]}
		fi
	done
}

#this code add support a proxy 
checkProxyStatus(){
	if [ $USE_PROXY = 1 ] ; then
		ActiveProxy 1
	else
		ActiveProxy 0
	fi
}



mainInstall(){
	initROOT_LAMW
	installDependences
	setLAMWDeps
	checkProxyStatus
	wrapperParseFPC
	getAnt
	getGradle
	getAndroidSDKTools
	getNDK
	setJava8asDefault
	getAndroidAPIS 
	getFPCStable
	getFPCSourcesTrunk
	getLazarusSources
	getLAMWFramework
	CreateBinutilsSimbolicLinks
	AddSDKPathstoProfile
	CleanOldCrossCompileBins
	buildCrossAndroid
	ConfigureFPCCrossAndroid
	BuildLazarusIDE
	changeDirectory $ROOT_LAMW
	LAMW4LinuxPostConfig
	enableADBtoUdev
	writeLAMWLogInstall
}
