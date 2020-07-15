#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.3.5
#Date: 07/14/2020
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

		for ((i=0;i<${#OLD_GRADLE[*]};i++))
		do
			if [ -e ${OLD_GRADLE[i]} ]; then 
				rm -rf ${OLD_GRADLE[i]} 
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

CheckExistsFPCLaz(){
	exec 2> /dev/null dpkg -s  $FPC_ALTERNATIVE_DEB_PACK | grep 'Status: install'  > /dev/null
	if [ $? = 0 ]; then
		export FPC_DEFAULT_DEB_PACK=$FPC_ALTERNATIVE_DEB_PACK
		return 1
	fi
	return 0
}
CheckFPCSupport(){
	if [ $FPC_DEFAULT_DEB_PACK = $FPC_ALTERNATIVE_DEB_PACK ]; then
		return
	fi
	exec 2> /dev/null apt show fpc | grep 'Version: 3.0.0'  > /dev/null 
	if [ $? = 0 ]; then
		export NEED_UPGRADE_FPC=1
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

enableUpgradeFPC(){
	cat  /etc/apt/sources.list | grep "${FPC_DEBIAN_BACKPORTS[1]}"
	if [ $? != 0 ]; then
		WriterFileln  "/etc/apt/sources.list.d/fpc-backports.list" "FPC_DEBIAN_BACKPORTS"
	fi
}
disableUpgradeFPC(){
	if [ -e /etc/apt/sources.list.d/fpc-backports.list ]; then
		rm /etc/apt/sources.list.d/fpc-backports.list
		rm  /var/lib/apt/lists/deb.debian.org_debian_dists_stretch-backports_*
	fi
}
#unistall java not supported
unistallJavaUnsupported(){
	#se o jdk > 8 nada  sai da funçao
	if [ $OPENJDK_DEFAULT = $OPENJDK_LTS ]; then 
		return 
	fi

	if [ $flag_new_ubuntu_lts = 1 ]; then
		apt-get remove --purge openjdk-9-* -y 
		apt-get remove --purge openjdk-11* -y
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
	exec 2> /dev/null apt show $NON_FREE_TOOLS | grep 'Source: unrar-nonfree' > /dev/null
	if [ $? = 0 ]; then
		PROG_TOOLS="$PROG_TOOLS$NON_FREE_TOOLS"
	else
		printf "${VERMELHO}Warning: The unrar package isn't available!\nCheck your /etc/apt/sources.list file${NORMAL}\nIgnoring instalation of ${NEGRITO}unrar${NORMAL} package!\n"
		sleep 1
	fi
	AptInstall $LIBS_ANDROID $PROG_TOOLS  openjdk-${OPENJDK_DEFAULT}-jdk 
		
	
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
#Get FPC Sources
getFPCSources(){
	changeDirectory $LAMW_USER_HOME
	mkdir -p $LAMW4LINUX_HOME/fpcsrc
	changeDirectory $LAMW4LINUX_HOME/fpcsrc
	svn checkout $URL_FPC
	if [ $? != 0 ]; then
		# rm $FPC_RELEASE/.svn -r
		 rm -rf $FPC_RELEASE
		svn checkout $URL_FPC
		if [ $? != 0 ]; then 
			 rm -rf $FPC_RELEASE
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
}

getFPCSourcesTrunk(){
	mkdir -p $FPC_TRUNK_SOURCE_PATH
	changeDirectory $FPC_TRUNK_SOURCE_PATH
	svn checkout $FPC_TRUNK_URL --force
	if [ $? != 0 ]; then
		rm -rf "$FPC_TRUNK_SVNTAG"
		svn checkout "$FPC_TRUNK_URL" --force
		if [ $? != 0 ]; then 
			rm -rf "$FPC_TRUNK_SVNTAG"
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
#wrapper to get FPC Sources 
getWrapperFPCSources(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		echo "Warning:mode experimental Android Aarch64!"
		getFPCSourcesTrunk
	else
		getFPCSources
	fi
}
#get Lazarus Sources
getLazarusSources(){
	changeDirectory $LAMW4LINUX_HOME
	svn co $LAZARUS_STABLE_SRC_LNK
	if [ $? != 0 ]; then  #case fails last command , try svn chekout 
		rm -rf $LAZARUS_STABLE
		svn co $LAZARUS_STABLE_SRC_LNK
		if [ $? != 0 ]; then 
			rm -rf $LAZARUS_STABLE
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
		unzip $GRADLE_ZIP_FILE
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
			cat "$ANDROID_SDK/ndk-bundle/source.properties" | grep ${OLD_NDK_VERSION_STR[i]} > /dev/null
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
		unzip $NDK_ZIP
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
		unzip $SDK_TOOLS_ZIP
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
		echo "Please wait, downloading \" ${SDK_MANAGER_CMD_PARAMETERS[i]}\"..."
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
		# # "$ANDROID_SDK/extras/google/google_play_services"  
		# "$ANDROID_SDK/extras/android/m2repository"
		# "$ANDROID_SDK/extras/google/m2repository" 
		# "$ANDROID_SDK/extras/google/market_licensing" 
		# "$ANDROID_SDK/extras/google/market_apk_expansion"
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
				echo "Getting \"${SDK_MANAGER_CMD_PARAMETERS2[i]}\" ..."
				#read;
			#	ls "$ANDROID_SDK/${sdk_manager_sdk_paths[i]}";read
				if [ ! -e "${sdk_manager_sdk_paths[i]}" ];then
					echo "y" |   ./android update sdk --all --no-ui --filter ${SDK_MANAGER_CMD_PARAMETERS2[i]} ${SDK_MANAGER_CMD_PARAMETERS2_PROXY[*]}
					if [ $? != 0 ]; then
						echo "y" |   ./android update sdk --all --no-ui --filter ${SDK_MANAGER_CMD_PARAMETERS2[i]} ${SDK_MANAGER_CMD_PARAMETERS2_PROXY[*]}
						if [ $? != 0 ]; then
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


WrappergetAndroidSDK(){
	if [ $OLD_ANDROID_SDK = 0 ]; then
		getSDKAndroid
	else
		getOldAndroidSDK
	fi

}

Repair(){
	local flag_need_repair=0 # flag de reparo 
	getStatusInstalation 
	if [ $LAMW_INSTALL_STATUS = 1 ]; then # só executa essa funcao se o lamw tiver instalado
		local flag_old_fpc=""
		local fpc_exe=$(which fpc) #verifica se existe o executavel para o fpc
		local fpc_arm=$(which ppcarm )
		if [ "$fpc_exe" = "" ]; then
			flag_need_repair=1
			installDependences # caso não exista -reinstale
			setJava8asDefault
		fi
		CheckFPCSupport
		if [ $NEED_UPGRADE_FPC = 1 ]; then
			installDependences
			flag_need_repair=1
			configureFPC
		fi
		if [ "$fpc_arm" = "" ]; then
			flag_need_repair=1  # caso o  crosscompile para arm nao exista,  sinaliza reparo
		fi
		#searchLineinFile "$LAMW4LINUX_HOME/lamw-install.log" "FPC_VERSION=$FPC_VERSION
		#configureFPC
		wrapperParseFPC
		if [ -e $LAMW4LINUX_HOME/fpcsrc ]; then 
			# verifica se  a versao do codigo fonte do fpc casa com a versão do sistema
			ls $LAMW4LINUX_HOME/fpcsrc | grep $FPC_RELEASE   
			local flag_old_fpc=$?
			#echo "flag_old_fpc=$flag_old_fpc";read
			local aux_path=""
			if [ $flag_old_fpc != 0 ] ; then # caso o código fonte do fpc do LAMW4Linux não match com o do sistema, verifica se necessita fazer downgrade ou upgrade
				if [ -e "$LAMW4LINUX_HOME/fpcsrc/release_3_0_0" ]; then
					aux_path="$LAMW4LINUX_HOME/fpcsrc/release_3_0_0"  #faz downgrade
				else
					if [ -e "$LAMW4LINUX_HOME/fpcsrc/release_3_0_4" ]; then
						aux_path="$LAMW4LINUX_HOME/fpcsrc/release_3_0_4"
					else
						if [ -e "$FPC_TRUNK_SOURCE_PATH/trunk" ]; then
							aux_path="$FPC_TRUNK_SOURCE_PATH/trunk"
						fi
					fi
				fi
				wrapperConfigureFPC
				if [ -e $aux_path ]; then 
					rm -rf $aux_path
					flag_need_repair=1
					getWrapperFPCSources
				fi
			fi
		fi


		local expected_fpc_src_path="${LAMW4LINUX_HOME}/fpcsrc/"
		local expected_fpc_src_path="${expected_fpc_src_path}${FPC_RELEASE}"
		#echo "$expected_fpc_src_path";read
		if [ ! -e $expected_fpc_src_path ]; then
		#	echo "expected_fpc_src_path does not exits"; read
			getFPCSources
			flag_need_repair=1
		fi
			
		if [ $flag_need_repair = 1 ]; then
			
			CleanOldCrossCompileBins
			BuildCrossArm $FPC_ID_DEFAULT
			BuildLazarusIDE
			CreateSDKSimbolicLinks
			enableADBtoUdev
			writeLAMWLogInstall
			changeOwnerAllLAMW
			#chown $LAMW_USER:$LAMW_USER -R $LAMW4LINUX_HOME
		fi
		
		if  [ -e $FPC_CFG_PATH ]; then 
			chown $LAMW_USER:$LAMW_USER $FPC_CFG_PATH
			
		fi
	fi
}
Repair1(){
	local flag_need_repair=0 # flag de reparo 
	local flag_upgrade_lazarus=0
	local aux_path="$LAMW4LINUX_HOME/fpcsrc"
	local expected_fpc_src_path="$FPC_TRUNK_SOURCE_PATH/${FPC_TRUNK_SVNTAG}"

	getStatusInstalation 
	if [ $LAMW_INSTALL_STATUS = 1 ]; then # só executa essa funcao se o lamw tiver instalado
		local flag_old_fpc=""
		local fpc_exe=$(which fpc) #verifica se existe o executavel para o fpc
		local fpc_aarch=$(which ppca64)	
		if [ "$fpc_exe" = "" ]; then
			flag_need_repair=1
			installDependences # caso não exista -reinstale
			setJava8asDefault
		fi

		if [ "$fpc_aarch" = "" ];  then
			flag_need_repair=1
		fi

		CheckFPCSupport
		if [ $NEED_UPGRADE_FPC = 1 ]; then
			installDependences
			flag_need_repair=1
			#configureFPC
			wrapperConfigureFPC
		fi

		wrapperParseFPC
		# verifica se  a versao do codigo fonte do fpc casa com a versão do sistema
	
		if [ -e "$aux_path" ]; then 
			rm -rf $aux_path
			flag_need_repair=1
			getWrapperFPCSources
		fi
	
		if [ ! -e $expected_fpc_src_path ]; then
			getWrapperFPCSources
			flag_need_repair=1
		fi
			
		if [ $flag_need_repair = 1 ]; then
			wrapperConfigureFPC
			CleanOldCrossCompileBins
			#BuildCrossArm $FPC_ID_DEFAULT
			wrapperBuildFPCCross
			if [ -e "$LAMW4LINUX_HOME/${LAZARUS_OLD_STABLE[0]}" ]; then
				rm -rf "$LAMW4LINUX_HOME/${LAZARUS_OLD_STABLE[0]}"
				getLazarusSources
			fi
			BuildLazarusIDE
			wrapperCreateSDKSimbolicLinks
			enableADBtoUdev
			writeLAMWLogInstall
			changeOwnerAllLAMW
		fi
		
		if  [ -e $FPC_CFG_PATH ]; then 
			chown $LAMW_USER:$LAMW_USER $FPC_CFG_PATH	
		fi
	fi
}

wrapperRepair(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		#Repair1
		Repair1
		true
	else
		Repair
	fi
}
#get implict install 
getImplicitInstall(){
	if [  -e $LAMW4LINUX_HOME/lamw-install.log ]; then
		cat $LAMW4LINUX_HOME/lamw-install.log |  grep "OLD_ANDROID_SDK=0" > /dev/null
		if [ $? = 0 ]; then
			export OLD_ANDROID_SDK=0
		else 
			export OLD_ANDROID_SDK=1
		fi
		cat $LAMW4LINUX_HOME/lamw-install.log |  grep "Generate LAMW_INSTALL_VERSION=$LAMW_INSTALL_VERSION" > /dev/null
		if [ $? = 0 ]; then  
			export LAMW_IMPLICIT_ACTION_MODE=1 #apenas atualiza o lamw 
		else
			echo "You need upgrade your LAMW4Linux!"
			export LAMW_IMPLICIT_ACTION_MODE=0
			export OLD_ANDROID_SDK=1 #obetem por padrão o old sdk 
			export NO_GUI_OLD_SDK=1
			LAMWPackageManager
		fi
	else
		export OLD_ANDROID_SDK=1 #obetem por padrão o old sdk 
		export NO_GUI_OLD_SDK=1
	fi
}

mainInstall(){
	initROOT_LAMW
	installDependences
	checkProxyStatus
	#configureFPC
	wrapperParseFPC
	getAnt
	getGradle
	getAndroidSDKTools
	getNDK
	getFPCStable
	#unistallJavaUnsupported
	setJava8asDefault
	#getSDKAndroid
	WrappergetAndroidSDK #temporariamente comentado
	
	#getFPCSources
	getWrapperFPCSources
	getLazarusSources
	getLAMWFramework
	#CreateSDKSimbolicLinks
	wrapperCreateSDKSimbolicLinks
	AddSDKPathstoProfile
	CleanOldCrossCompileBins
	#BuildCrossArm 
	wrapperBuildFPCCross
	wrapperConfigureFPC
	BuildLazarusIDE
	changeDirectory $ROOT_LAMW
	LAMW4LinuxPostConfig
	enableADBtoUdev
	writeLAMWLogInstall
}