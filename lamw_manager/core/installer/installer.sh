#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.2
#Date: 10/26/2021
#Description: "installer.sh" is part of the core of LAMW Manager. Contains routines for installing LAMW development environment
#-------------------------------------------------------------------------------------------------#

#prepare upgrade
LAMWPackageManager(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then 
		
		local old_lamw_ide_home="$LAMW4LINUX_HOME/lamw4linux"
		local old_lamw4linux_exec=$old_lamw_ide_home/lamw4linux


		[ -e /usr/bin/startlamw4linux ] && 	rm /usr/bin/startlamw4linux

		if [ -e "$old_lamw_ide_home"  ] &&  [ -L $old_lamw_ide_home ] && [ -d $old_lamw_ide_home ]; then # remove deprecated symbolik links
			if [ -e $old_lamw4linux_exec ]; then
				rm $old_lamw4linux_exec
			fi
			rm "$old_lamw_ide_home"  -rf
		fi

		for((i=0;i<${#OLD_LAZARUS_STABLE_VERSION[*]};i++)); do
			local old_lazarus_release=lazarus_${OLD_LAZARUS_STABLE_VERSION[i]//\./_}
			local old_lazarus_home=$LAMW4LINUX_HOME/${old_lazarus_release}
			[ -e "$old_lazarus_home" ] && rm "$old_lazarus_home" -rf
		done
		
		[ -e "$OLD_FPC_CFG_PATH" ] && grep  "$ROOT_LAMW" "$OLD_FPC_CFG_PATH" && rm "$OLD_FPC_CFG_PATH"
	
		#fixs 0.3.1 to 0.3.2

		for i  in ${!OLD_FPC_SOURCES[*]}; do
			[ -e ${OLD_FPC_SOURCES[i]} ] && rm  -rf ${OLD_FPC_SOURCES[i]}
		done


		for gradle in ${OLD_GRADLE[*]}; do
			if [ -e "$gradle" ]; then
				rm -rf $gradle 
			fi
		done

		for ((i=0;i<${#OLD_ANT[*]};i++)); do
			[ -e ${OLD_ANT[i]} ] && rm -rf ${OLD_ANT[i]}
		done

		for old_fpc_stable in ${OLD_FPC_STABLE[*]}; do 
			[ -e $old_fpc_stable ] && rm -rf $old_fpc_stable
		done
	fi

}
getStatusInstalation(){
	if [  -e $LAMW4LINUX_HOME/lamw-install.log ]; then
		export LAMW_INSTALL_STATUS=1
		return 1
	else 
		return 0;
	fi
}


#install deps
installDependences(){
	getCurrentDebianFrontend
	AptInstall $LIBS_ANDROID $PROG_TOOLS
		
}




getCompressFile(){
	local compress_url="$1"
	local compress_file="$2"
	local uncompress_command="$3"
	local before_uncompress="$4"
	local error_uncompress_msg="${VERMELHO}Error:${NORMAL} corrupt/unsupported file"
	local initial_msg="Please wait, extracting ${NEGRITO}$compress_file${NORMAL} ..." 
	Wget $compress_url
	if [ -e $compress_file ]; then
		printf "%s" "$initial_msg"	
		[ "$before_uncompress" != "" ] &&  eval "$before_uncompress"
		$uncompress_command
		check_error_and_exit "$error_uncompress_msg"
		printf  "%s\n" "${FILLER:${#compress_file}}${VERDE} [OK]${NORMAL}"
		rm $compress_file
	fi
}

getJDK(){
	checkJDKVersionStatus
	if [ $JDK_STATUS = 1 ]; then 
		[ -e "$OLD_JAVA_HOME" ] && rm -rf "$OLD_JAVA_HOME"
		changeDirectory "$ROOT_LAMW/jdk"
		[ -e "$JAVA_HOME" ] && rm -r "$JAVA_HOME"
		getCompressFile "$JDK_URL" "$JDK_TAR" "tar -zxf $JDK_TAR"
		mv "$JDK_FILE" "${JDK_VERSION_DIR}"
	fi
}

getFromGit(){
	local git_src_url="$1"
	local git_src_dir="$2"
	local git_branch="$3"

	if [ ! -e "$git_src_dir" ]; then 
		if [ $# -lt 3 ]; then 
			local git_param=(clone "$git_src_url")
		else 
			local git_param=(clone "$git_src_url" -b "$git_branch" "$git_src_dir" )
		fi
		git ${git_param[@]}
		if [ $? != 0 ]; then 
			git ${git_param[@]}
			check_error_and_exit "possible network instability!! Try later!"
		fi
	else
		if [ $# -lt 3 ]; then 
			local git_param=(pull)
		else 
			local git_param=(pull origin $git_branch )
		fi
		changeDirectory "$git_src_dir"
		git config pull.ff only

		git ${git_param[@]}
		if [ $? != 0 ]; then
		local git_reset_param=(reset --hard)
			git ${git_reset_param[@]}
			git ${git_param[@]}
			if [ $? != 0 ]; then
				changeDirectory .. 
				rm -rf $git_src_dir
				echo "possible network instability!! Try later!"
				exit 1
			fi
		fi
	fi
}


getFromSVN(){
	local svn_src_url="$1"
	local svn_src_dir="$2"

	svn checkout "$svn_src_url" --force
	if [ $? != 0 ]; then
		svn cleanup "$svn_src_dir"
		svn checkout "$svn_src_url" --force
		if [ $? != 0 ]; then 
			svn cleanup "$svn_src_dir"
			[ $? != 0 ] && rm -rf "$svn_src_dir" && echo "possible network instability! Try later!" && exit 1
		fi
	fi
}


getFPCStable(){
	if [ ! -e "$LAMW4LINUX_HOME/usr" ]; then 
		mkdir -p "$LAMW4LINUX_HOME/usr"
	fi

	cd "$LAMW4LINUX_HOME/usr"
	if  [ ! -e "$FPC_LIB_PATH" ]; then

		getCompressFile "$FPC_DEB_LINK" "$FPC_DEB" "ar x $FPC_DEB data.tar.xz"
		if [ -e data.tar.xz ]; then 
			tar -xf data.tar.xz 
			rm -rf $LAMW4LINUX_HOME/usr/local
			[ -e $LAMW4LINUX_HOME/usr/usr ] && mv $LAMW4LINUX_HOME/usr/usr/ $LAMW4LINUX_HOME/usr/local
			rm data.tar.xz
		fi
		export PPC_CONFIG_PATH=$FPC_LIB_PATH

		$FPC_MKCFG_EXE -d basepath=$FPC_LIB_PATH -o $FPC_LIB_PATH/fpc.cfg;
	fi
}

getFPCSourcesTrunk(){
	mkdir -p $FPC_TRUNK_SOURCE_PATH
	changeDirectory $FPC_TRUNK_SOURCE_PATH
	if [ ! -e $FPC_TRUNK_SVNTAG ]; then
		local url_fpc_src="https://sourceforge.net/projects/freepascal/files/Source/${_FPC_TRUNK_VERSION}/fpc-${_FPC_TRUNK_VERSION}.source.tar.gz"
		local tar_fpc_src="fpc-${_FPC_TRUNK_VERSION}.source.tar.gz"
		local untar_fpc_src="tar -zxf $tar_fpc_src"
		local fpc_src_file="fpc-${_FPC_TRUNK_VERSION}"
		getCompressFile "$url_fpc_src" "$tar_fpc_src" "$untar_fpc_src"
		mv $fpc_src_file $FPC_TRUNK_SVNTAG
	fi
	#getFromSVN "$FPC_TRUNK_URL" "$FPC_TRUNK_SVNTAG"
	parseFPCTrunk
}

#get Lazarus Sources
getLazarusSources(){
	local msg="${VERMELHO}Warning:${NORMAL}${NEGRITO}Lazarus has been downgraded to version 2.0.12!!${NORMAL}"
	printf "%s\n" "$msg"
	changeDirectory $LAMW4LINUX_HOME
	getFromGit "$LAZARUS_STABLE_SRC_LNK" "$LAMW_IDE_HOME" "$LAZARUS_STABLE"
}

#GET LAMW FrameWork
getLAMWFramework(){
	local old_lamw_framework_home="$ROOT_LAMW/lazandroidmodulewizard.git"
	changeDirectory $ROOT_LAMW
	[  -e "$old_lamw_framework_home" ] && [ -e "$LAMW_FRAMEWORK_HOME" ] && 
		rm -rf "$old_lamw_framework_home" && rm -rf "$LAMW_FRAMEWORK_HOME"

	getFromGit "$LAMW_SRC_LNK"  "$LAMW_FRAMEWORK_HOME"
}


AntTrigger(){
	if [ $OLD_ANDROID_SDK = 0 ] && [ -e "$ANDROID_SDK_ROOT/tools/ant" ]; then 
		mv  "$ANDROID_SDK_ROOT/tools/ant" "$ANDROID_SDK_ROOT/tools/.ant"
	fi
}

#this function get ant 
getAnt(){
	[ $OLD_ANDROID_SDK = 0 ] && return   #sem ação se ant nao é suportado
		
	changeDirectory "$ROOT_LAMW" 
	if [ ! -e "$ANT_HOME" ]; then
		MAGIC_TRAP_INDEX=0 # preperando o indice do arquivo/diretório a ser removido
		trap TrapControlC  2
		MAGIC_TRAP_INDEX=1
		getCompressFile "$ANT_TAR_URL" "$ANT_TAR_FILE" "tar -xf $ANT_TAR_FILE"
	fi

}

getGradle(){
	changeDirectory $ROOT_LAMW
	if [ ! -e "$GRADLE_HOME" ]; then
		MAGIC_TRAP_INDEX=2 #Set arquivo a ser removido
		trap TrapControlC  2 # set armadilha para o signal2 (siginterrupt)
		getCompressFile "$GRADLE_ZIP_LNK" "$GRADLE_ZIP_FILE" "unzip -o -q $GRADLE_ZIP_FILE" "MAGIC_TRAP_INDEX=3"
	fi
}

#Get Gradle and SDK Tools 
getAndroidSDKTools(){
	initROOT_LAMW
	changeDirectory $ROOT_LAMW
	changeDirectory $ANDROID_SDK_ROOT
	
	if [ ! -e "$CMD_SDK_TOOLS_DIR" ];then
		mkdir -p "$CMD_SDK_TOOLS_DIR"
		changeDirectory "$CMD_SDK_TOOLS_DIR"
		trap TrapControlC  2
		MAGIC_TRAP_INDEX=4
		getCompressFile "$CMD_SDK_TOOLS_URL" "$CMD_SDK_TOOLS_ZIP" "unzip -o -q  $CMD_SDK_TOOLS_ZIP" "MAGIC_TRAP_INDEX=5"
		mv cmdline-tools latest
	fi
}

getSDKAntSupportedTools(){
	initROOT_LAMW
	changeDirectory $ANDROID_SDK_ROOT
	SDK_TOOLS_VERSION="r25.2.5"
	SDK_TOOLS_URL="https://dl.google.com/android/repository/tools_r25.2.5-linux.zip"
	SDK_TOOLS_ZIP="tools_r25.2.5-linux.zip"
	SDK_TOOLS_DIR="$ANDROID_SDK_ROOT/tools"
	if [ ! -e "$SDK_TOOLS_DIR" ];then
		trap TrapControlC  2
		MAGIC_TRAP_INDEX=4
		getCompressFile "$SDK_TOOLS_URL" "$SDK_TOOLS_ZIP" "unzip -o -q $SDK_TOOLS_ZIP"  "MAGIC_TRAP_INDEX=5"
	fi
}

getAndroidCmdLineTools(){
	getSDKAntSupportedTools
	getAndroidSDKTools
	AntTrigger
}


runSDKManagerLicenses(){
	local sdk_manager_cmd="$CMD_SDK_TOOLS_DIR/latest/bin/sdkmanager"
	yes | $sdk_manager_cmd ${SDK_LICENSES_PARAMETERS[*]} 
	if [ $? != 0 ]; then 
		yes | $sdk_manager_cmd ${SDK_LICENSES_PARAMETERS[*]} 
		check_error_and_exit "possible network instability! Try later!"
	fi
}

runSDKManager(){
	local sdk_manager_cmd="$CMD_SDK_TOOLS_DIR/latest/bin/sdkmanager"
	if [ $FORCE_YES = 1 ]; then 
		yes | $sdk_manager_cmd $*

		if [ $? != 0 ]; then
			yes | $sdk_manager_cmd $*
			check_error_and_exit "possible network instability! Try later!"
		fi
	else
		$sdk_manager_cmd $*

		if [ $? != 0 ]; then 
			$sdk_manager_cmd $*
			check_error_and_exit "possible network instability! Try later!"
		fi
	fi
}


getAndroidAPIS(){
	
	FORCE_YES=1
	changeDirectory $ANDROID_HOME
	runSDKManagerLicenses
	
	if [ $#  = 0 ]; then 

		for((i=0;i<${#SDK_MANAGER_CMD_PARAMETERS[*]};i++));do
			echo "Please wait, downloading ${NEGRITO}${SDK_MANAGER_CMD_PARAMETERS[i]}${NORMAL}..."
			
			if [ $i = 0 ]; then 
				runSDKManager ${SDK_MANAGER_CMD_PARAMETERS[i]} # instala sdk sem intervenção humana 
			else
				FORCE_YES=0
				runSDKManager ${SDK_MANAGER_CMD_PARAMETERS[i]} 
			fi
		done
	else 
		runSDKManager $*
	fi

	unset FORCE_YES
}


resetAndroidAPIS(){
	local sdk_manager_fails=(
		"platforms"
		"platform-tools"
		"build-tools"
		"extras"
	)
	echo "${VERMELHO}Warning:${NORMAL} All Android API'S will  be unistalled!"
	echo "Only the default APIs will be reinstalled!"
	for ((i=0;i<${#sdk_manager_fails[*]};i++)); do
		local current_sdk_path="${ANDROID_SDK_ROOT}/${sdk_manager_fails[i]}"
		if [ -e $current_sdk_path ]; then
			rm -rf $current_sdk_path
		fi
	done

	setLAMWDeps
	getAndroidAPIS
	for ((i=0;i<${#sdk_manager_fails[*]};i++)); do
		local current_sdk_path="${ANDROID_SDK_ROOT}/${sdk_manager_fails[i]}"
		if [ -e $current_sdk_path ]; then
			chown $LAMW_USER:$LAMW_USER -R $current_sdk_path
		fi
		chown $LAMW_USER:$LAMW_USER -R $LAMW_USER_HOME/.android
	done

}

Repair(){
	local flag_need_repair=0 # flag de reparo 
	local flag_upgrade_lazarus=0
	local aux_path="$LAMW4LINUX_HOME/fpcsrc"
	local expected_fpc_src_path="$FPC_TRUNK_SOURCE_PATH/${FPC_TRUNK_SVNTAG}"

	getStatusInstalation 
	if [ $LAMW_INSTALL_STATUS = 1 ]; then # só executa essa funcao se o lamw tiver instalado
		local flag_old_fpc=""
		checkLAMWManagerVersion > /dev/null

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

		if [ ! -e $LAMW4_LINUX_PATH_CFG ]; then 
			setLAMWDeps; LAMW4LinuxPostConfig
		fi
	fi
}

checkLAMWManagerVersion(){
	local ret=0
	[ -e "$LAMW4LINUX_HOME/lamw-install.log" ] && for i  in ${!OLD_LAMW_INSTALL_VERSION[*]};do
		grep "^Generate LAMW_INSTALL_VERSION=${OLD_LAMW_INSTALL_VERSION[i]}$"  "$LAMW4LINUX_HOME/lamw-install.log" > /dev/null
		if [ $? = 0 ]; then 
			CURRENT_OLD_LAMW_INSTALL_INDEX=$i
			ret=1;
			break
		fi
	done

	if [  "$1"  != "" ]; then 
		newPtr ref_ret=$1
		ref_ret=$ret
	else 
		echo "$ret"
	fi
}

setOldLAMW4LinuxActions(){
	if [ $1 = 1 ]; then 
		echo "You need upgrade your LAMW4Linux!"
		export LAMW_IMPLICIT_ACTION_MODE=0
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
		return 
	else
		grep "Generate LAMW_INSTALL_VERSION=$LAMW_INSTALL_VERSION" "$lamw_install_log_path" 	> /dev/null
		
		if [ $? = 0 ]; then
			checkChangeLAMWDeps
		else
			local flag_is_old_lamw=0
			checkLAMWManagerVersion flag_is_old_lamw
			setOldLAMW4LinuxActions $flag_is_old_lamw
		fi
	fi
}

getCurrentLazarusWidget(){
	local lazarus_widget_default="gkt2"
	local current_widget_set="$lazarus_widget_default"
	if [ -e  "$ide_make_cfg_path" ]; then 
		current_widget_set="$(grep '\-dLCL.' "$ide_make_cfg_path" | sed 's/-dLCL//g')"
		[ $? != 0 ] && current_widget_set="$lazarus_widget_default"
	fi

	echo "$current_widget_set"
}

installLAMWPackages(){
	local ide_make_cfg_path="$LAMW4_LINUX_PATH_CFG/idemake.cfg"
	local error_lazbuild_msg="${VERMELHO}Error${NORMAL}: Fails on build ${NEGRITO}${LAMW_PACKAGES[i]}${NORMAL} package"
	local lamw_build_opts=(
		"--pcp=$LAMW4_LINUX_PATH_CFG"  
		"--ws=$(getCurrentLazarusWidget)"
		"--quiet" 
		"--build-ide=" 
		"--add-package"
	)

	#build ide with lamw framework 
	for((i=0;i< ${#LAMW_PACKAGES[@]};i++)); do
		echo "Please wait, buiding ${NEGRITO}`basename ${LAMW_PACKAGES[i]}`${NORMAL} ... "
		./lazbuild ${lamw_build_opts[*]} ${LAMW_PACKAGES[$i]}
		
		if [ $? != 0 ]; then 
			./lazbuild ${lamw_build_opts[*]} ${LAMW_PACKAGES[$i]}
			[ $? != 0 ] && { echo "$error_lazbuild_msg" && return ; }
		fi
	done

}
#Build lazarus ide
BuildLazarusIDE(){	
	wrapperParseFPC
	export PATH=$FPC_TRUNK_LIB_PATH:$FPC_TRUNK_EXEC_PATH:$PATH
	local error_build_lazarus_msg="${VERMELHO}Fatal error:${NORMAL}Fails in build Lazarus!!"
	local make_opts=( "clean all" "PP=${FPC_TRUNK_LIB_PATH}/ppcx64" "FPC_VERSION=$_FPC_TRUNK_VERSION" )
	
	changeDirectory $LAMW_IDE_HOME

	if [ $# = 0 ]; then 
	 	make -s  ${make_opts[*]}
	 	check_error_and_exit "$error_build_lazarus_msg" #build all IDE
	fi
	
	initLAMw4LinuxConfig
	installLAMWPackages
	strip lazarus
	strip lazbuild
	strip startlazarus
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
	getFiller
	checkLAMWManagerVersion > /dev/null
	initROOT_LAMW
	installDependences
	setLAMWDeps
	LAMWPackageManager
	checkProxyStatus
	wrapperParseFPC
	getJDK
	getAnt
	getGradle
	getAndroidCmdLineTools
	disableTrapActions
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
	changeOwnerAllLAMW
}