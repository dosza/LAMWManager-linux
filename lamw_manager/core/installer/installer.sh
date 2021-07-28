#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.1
#Date: 07/27/2021
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
		setOldAndroidSDKStatus
		export NO_GUI_OLD_SDK=1
		return 0;
	fi
}


#install deps
installDependences(){
	getCurrentDebianFrontend
	AptInstall $LIBS_ANDROID $PROG_TOOLS
		
}


getJDK(){
	checkJDKVersionStatus
	if [ $JDK_STATUS = 1 ]; then 
		[ -e "$OLD_JAVA_HOME" ] && rm -rf "$OLD_JAVA_HOME"
		changeDirectory "$ROOT_LAMW/jdk"
		[ -e "$JAVA_HOME" ] && rm -r "$JAVA_HOME"
		Wget "$JDK_URL"
		tar -zxvf "$JDK_TAR"
		mv "$JDK_FILE" "${JDK_VERSION_FOLDER}"
		[ -e "$JDK_TAR" ] && rm "$JDK_TAR"
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
		git ${git_param[@]}
		if [ $? != 0 ]; then
			git_param=(reset --hard)
			git ${git_param[@]}
			check_error_and_exit "possible network instability!! Try later!"
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
		echo "doesn't exist $FPC_LIB_PATH"
		Wget $FPC_DEB_LINK
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
				rm -rf $LAMW4LINUX_HOME/usr/local
				[ -e $LAMW4LINUX_HOME/usr/usr ] && mv $LAMW4LINUX_HOME/usr/usr/ $LAMW4LINUX_HOME/usr/local
			fi
			for i in ${!tmp_files[@]}; do  
				if [ -e ${tmp_files[i]} ]; then rm ${tmp_files[i]} ; fi
			done	
		fi
		export PPC_CONFIG_PATH=$FPC_LIB_PATH

		$FPC_MKCFG_EXE -d basepath=$FPC_LIB_PATH -o $FPC_LIB_PATH/fpc.cfg;
	fi
}

getFPCSourcesTrunk(){
	mkdir -p $FPC_TRUNK_SOURCE_PATH
	changeDirectory $FPC_TRUNK_SOURCE_PATH
	getFromSVN "$FPC_TRUNK_URL" "$FPC_TRUNK_SVNTAG"
	parseFPCTrunk
}

#get Lazarus Sources
getLazarusSources(){
	changeDirectory $LAMW4LINUX_HOME
	getFromSVN "$LAZARUS_STABLE_SRC_LNK" "$LAZARUS_STABLE"
}

#GET LAMW FrameWork
getLAMWFramework(){
	changeDirectory $ROOT_LAMW
	[  -e "$ROOT_LAMW/lazandroidmodulewizard.git" ] && [ -e "$ROOT_LAMW/lazandroidmodulewizard" ] && 
		rm -rf "$ROOT_LAMW/lazandroidmodulewizard.git" && rm -rf "$ROOT_LAMW/lazandroidmodulewizard"

	getFromGit "$LAMW_SRC_LNK" "$ROOT_LAMW/lazandroidmodulewizard"
}


AntTrigger(){
	if [ -e "$ANDROID_SDK/tools/.ant" ]; then 
		mv "$ANDROID_SDK/tools/.ant" "$ANDROID_SDK/tools/ant"
	fi
}

#this function get ant 
getAnt(){
	[ $OLD_ANDROID_SDK = 0 ] && return   #sem ação se ant nao é suportado
		
	changeDirectory "$ROOT_LAMW" 
	if [ ! -e "$ANT_HOME" ]; then
		MAGIC_TRAP_INDEX=0 # preperando o indice do arquivo/diretório a ser removido
		trap TrapControlC  2
		Wget $ANT_TAR_URL
		MAGIC_TRAP_INDEX=1
		tar -xvf "$ANT_TAR_FILE"
	fi

	[ -e  $ANT_TAR_FILE ] && rm $ANT_TAR_FILE
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
	[ $OLD_ANDROID_SDK = 0 ] && return 

	changeDirectory "$ANDROID_SDK"
	if [ -e  "$ANDROID_SDK/ndk-bundle" ]; then 
		for i in ${!OLD_NDK_VERSION_STR[*]}; do
			grep ${OLD_NDK_VERSION_STR[i]} "$ANDROID_SDK/ndk-bundle/source.properties" > /dev/null
			[ $? = 0 ] && rm -rf $ANDROID_SDK/ndk-bundle && break
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
		[ -e $NDK_ZIP ] && rm $NDK_ZIP

	fi
}
#Get Gradle and SDK Tools 
getAndroidSDKTools(){
	initROOT_LAMW
	changeDirectory $ROOT_LAMW

	if [ $OLD_ANDROID_SDK = 1 ]; then #mode OLD SDK (2-4 with ant support )
		SDK_TOOLS_VERSION="r25.2.5"
		SDK_TOOLS_URL="https://dl.google.com/android/repository/tools_r25.2.5-linux.zip"
		SDK_TOOLS_ZIP="tools_r25.2.5-linux.zip"
		SDK_TOOLS_DIR="$ANDROID_SDK/tools"
	fi

	changeDirectory $ANDROID_SDK
	if [ ! -e "$SDK_TOOLS_DIR" ];then
		[ $OLD_ANDROID_SDK = 0 ]  && mkdir -p "$SDK_TOOLS_DIR" && changeDirectory "$SDK_TOOLS_DIR"
		trap TrapControlC  2
		MAGIC_TRAP_INDEX=4
		Wget $SDK_TOOLS_URL
		MAGIC_TRAP_INDEX=5
		unzip -o  $SDK_TOOLS_ZIP
		[ $OLD_ANDROID_SDK = 0 ] && mv cmdline-tools latest
		rm $SDK_TOOLS_ZIP
		AntTrigger
	fi
}


runSDKManagerLicenses(){
	local sdk_manager_cmd="$SDK_TOOLS_DIR/latest/bin/sdkmanager"
	yes | $sdk_manager_cmd ${SDK_LICENSES_PARAMETERS[*]} 
	if [ $? != 0 ]; then 
		yes | $sdk_manager_cmd ${SDK_LICENSES_PARAMETERS[*]} 
		check_error_and_exit "possible network instability! Try later!"
	fi
}

  runSDKManager(){
	local sdk_manager_cmd="$SDK_TOOLS_DIR/latest/bin/sdkmanager"
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

runOldSDKManager(){
	local sdk_pack="$1"
	local sdk_pack_path="$2"
	local sdk_manager_cmd="$ANDROID_SDK/tools/android"
	local sdk_cmd_extra_params=(update sdk --all --no-ui --filter $sdk_pack  ${SDK_MANAGER_CMD_PARAMETERS2_PROXY[*]})
	if [ ! -e $sdk_pack_path ]; then 
		echo "y" |  $sdk_manager_cmd ${sdk_cmd_extra_params[@]}

		if [ ! -e $sdk_pack_path ]; then 
			echo "y" |  $sdk_manager_cmd ${sdk_cmd_extra_params[@]}
			[ ! -e "$sdk_pack_path" ] && echo "possible network instability! Try later!" && exit 1
		fi
	fi
}

getSDKAndroid(){
	
	FORCE_YES=1
	changeDirectory $ANDROID_HOME
	runSDKManagerLicenses
	
	if [ $#  = 0 ]; then 

		for((i=0;i<${#SDK_MANAGER_CMD_PARAMETERS[*]};i++));do
			echo "Please wait, downloading ${NEGRITO}${SDK_MANAGER_CMD_PARAMETERS[i]}${NORMAL}\"..."
			
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

getOldAndroidSDK(){
	local sdk_manager_sdk_paths=(
		"$ANDROID_SDK/platforms/android-$ANDROID_SDK_TARGET"
		"$ANDROID_SDK/platform-tools"
		"$ANDROID_SDK/build-tools/$ANDROID_BUILD_TOOLS_TARGET"
		"$ANDROID_SDK/extras/google/google_play_services"
		$ANDROID_SDK/extras/{android,google}/m2repository
		$ANDROID_SDK/extras/google/market_{licensing,apk_expansion}
	#	"$ANDROID_SDK/build-tools/$GRADLE_MIN_BUILD_TOOLS"
	)

	if [ -e $ANDROID_SDK/tools/android  ]; then 
		changeDirectory $ANDROID_HOME
		if [ $NO_GUI_OLD_SDK = 0 ]; then
			echo "Please wait..."
			$ANDROID_SDK/tools/android  update sdk
		else 
			for((i=0;i<${#SDK_MANAGER_CMD_PARAMETERS2[*]};i++));do
				echo "Getting ${NEGRITO}${SDK_MANAGER_CMD_PARAMETERS2[i]}${NORMAL} ..."
				runOldSDKManager "${SDK_MANAGER_CMD_PARAMETERS2[i]}" "${sdk_manager_sdk_paths[i]}"
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
	getAndroidAPIS
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
		getSDKAndroid $*
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
	fi
}

setOldAndroidSDKStatus(){
	local lamw_install_log_path="$LAMW4LINUX_HOME/lamw-install.log"
	if [ -e $lamw_install_log_path ] ; then 
		#grep "OLD_ANDROID_SDK=0" "$lamw_install_log_path"  > /dev/null 
	 	OLD_ANDROID_SDK=0
	fi
}

checkLAMWManagerVersion(){
	local ret=0
	[ -e "$LAMW4LINUX_HOME/lamw-install.log" ] && for i  in ${!OLD_LAMW_INSTALL_VERSION[*]};do
		grep "^Generate LAMW_INSTALL_VERSION=${OLD_LAMW_INSTALL_VERSION[i]}"  "$LAMW4LINUX_HOME/lamw-install.log" > /dev/null
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
		setOldAndroidSDKStatus $?
		
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

#Build lazarus ide
BuildLazarusIDE(){
	
	wrapperParseFPC
	
	export PATH=$FPC_TRUNK_LIB_PATH:$FPC_TRUNK_EXEC_PATH:$PATH
	local make_opts=(
		"PP=${FPC_TRUNK_LIB_PATH}/ppcx64"
		"FPC_VERSION=$_FPC_TRUNK_VERSION"
	)

	local ide_make_cfg_path="$LAMW4_LINUX_PATH_CFG/idemake.cfg"

	[ ! -e "$LAMW_IDE_HOME" ] && ln -sf $LAMW4LINUX_HOME/$LAZARUS_STABLE $LAMW_IDE_HOME # link to lamw4_home directory  
	[ ! -e "$LAMW4LINUX_EXE_PATH" ] && ln -sf $LAMW_IDE_HOME/lazarus $LAMW4LINUX_EXE_PATH  #link  to lazarus executable

	changeDirectory $LAMW_IDE_HOME
	
	[ $# = 0 ] && make clean all  ${make_opts[*]} #build all IDE
	
	initLAMw4LinuxConfig

	if [ -e   "$ide_make_cfg_path" ]; then 
		local current_widget_set="$(grep '\-dLCL.' "$ide_make_cfg_path" | sed 's/-dLCL//g')"
		if [ "$current_widget_set" != "" ] && [ "$current_widget_set" != "gtk2" ]; then 
			current_widget_set="--ws=$current_widget_set"
		else 
			current_widget_set=""
		fi
	fi
		#build ide  with lamw framework 
	for((i=0;i< ${#LAMW_PACKAGES[@]};i++))
	do
		local lamw_build_opts=(--build-ide= --add-package ${LAMW_PACKAGES[i]} --pcp=$LAMW4_LINUX_PATH_CFG  --lazarusdir=$LAMW_IDE_HOME $current_widget_set)
		./lazbuild  ${lamw_build_opts[*]}
		if [ $? != 0 ]; then
			./lazbuild ${lamw_build_opts[*]}
			[ $? != 0 ] && { echo "${VERMELHO}Error${NORMAL}: Fails on build ${NEGRITO}${LAMW_PACKAGES[i]}${NORMAL} package" && return ; }
		fi
	done

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
	checkLAMWManagerVersion > /dev/null
	initROOT_LAMW
	installDependences
	setLAMWDeps
	checkProxyStatus
	wrapperParseFPC
	getJDK
	getAnt
	getGradle
	getAndroidSDKTools
	getNDK
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
