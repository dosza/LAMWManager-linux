#!/bin/bash

#this function returns a version fpc 

#prepare upgrade
LAMWPackageManager(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then 
		old_lazarus_home=$LAMW4LINUX_HOME/${LAZARUS_OLD_STABLE[0]}
		old_lamw_ide_home="$LAMW4LINUX_HOME/lamw4linux"
		old_fpc_src="$LAMW4LINUX_HOME/fpcsrc"
		# lamw_env_str=(
		# 	'<?xml version="1.0" encoding="UTF-8"?>'
		# 	'<CONFIG>'
		# 	'  <EnvironmentOptions>'
		# 	"   <LazarusDirectory Value=\"$LAMW_IDE_HOME/\"/>"
		# 	"    <CompilerFilename Value=\"/usr/local/bin/fpc\"/>"
		# 	'  </EnvironmentOptions>'
		# 	'</CONFIG>'
		# )
		# WriterFileln "$LAMW4_LINUX_PATH_CFG/environmentoptions.xml" "lamw_env_str"
		#configure  lazarus to work with new FPC \(based in trunk)


		if [ -e  "$LAMW4_LINUX_PATH_CFG/environmentoptions.xml" ]; then
			path_splited=$(GenerateScapesStr $FPC_TRUNK_SOURCE_PATH/trunk )
			echo $path_splited
			sed -i "s/CompilerFilename Value=\"\/usr\/bin\/fpc\"/CompilerFilename Value=\"\/usr\/local\/bin\/fpc\"/g" "$LAMW4_LINUX_PATH_CFG/environmentoptions.xml"
			sed -i "s/FPCSourceDirectory Value=\"\/usr\/share\/fpcsrc\/\$(FPCVer)\"/FPCSourceDirectory Value=\"$path_splited\"/g" "$LAMW4_LINUX_PATH_CFG/environmentoptions.xml"
			#sed -i "s/${LAZARUS_OLD_STABLE[0]}/${LAZARUS_STABLE}/g" "$LAMW4_LINUX_PATH_CFG/environmentoptions.xml"
		fi



		if [ -e "$old_lamw_ide_home"  ]; then
			echo "Uninstalling  Old Lazarus ..."
			rm "$old_lamw_ide_home"  -rf

			if [ -e "$old_lazarus_home" ]; then
				rm "$old_lazarus_home" -rf
			fi
		fi
		if [ -e "$old_fpc_src" ]; then
			echo "Uninstalling Old FPC Sources ..."
			rm -rf "$old_fpc_src"
		fi


		if [ -e "$PPC_CONFIG_PATH" ]; then
			rm "$PPC_CONFIG_PATH"
		fi
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
	index=-1
	#vetor que armazena informações sobre a intalação do pacote
	if [ "$1" != "" ]  ; then
		packs=( $(dpkg -l $1) )
		
		tam=${#packs[@]}
		if  [ $tam = 0 ] ; then
			 apt-get install fpc -y
			packs=( $(dpkg -l $1) )
		fi

		for (( i = 0 ; i < ${#packs[*]};i++))
		do
			if [ "${packs[i]}" = "$1" ] ; then
				((index=i))
				((index++))
				FPC_VERSION=${packs[index]}
				#echo "${packs[index]}"
				break
			fi
		done
	fi
	return $index
}

CheckFPCSupport(){
	apt show fpc | grep 'Version: 3.0.0' 
	if [ $? = 0 ]; then
		export NEED_UPGRADE_FPC=1
	fi
}

enableUpgradeFPC(){
	cat  /etc/apt/sources.list | grep "${fpc_debian_backports[1]}"
	if [ $? != 0 ]; then
		for((i=0;i<${#fpc_debian_backports[*]};i++))
		do
			if [ $i = 0 ]; then
				echo ${fpc_debian_backports[i]} > /etc/apt/sources.list.d/fpc-backports.list
			else
				echo ${fpc_debian_backports[i]} >> /etc/apt/sources.list.d/fpc-backports.list
			fi
		done
		apt-get update
		if [ $? != 0 ] ; then
			apt-get update
			if [ $? != 0 ]; then
				echo "possible network instability! Try later!"
				exit 1
			fi
		fi
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
	if [ $flag_new_ubuntu_lts = 1 ]; then
		 apt-get remove --purge openjdk-9-* -y 
		 apt-get remove --purge openjdk-11* -y
	fi
}

#setJRE8 as default
setJava8asDefault(){
	path_java=($(dpkg -L openjdk-8-jre))
	found_path=""
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
	 apt-get update;
	if [ $FORCE_LAWM4INSTALL = 1 ]; then 
		 apt-get remove --purge  lazarus* -y
		 apt-get autoremove --purge -y
	fi
	CheckFPCSupport

	if [ $NEED_UPGRADE_FPC = 1 ]; then
		enableUpgradeFPC
		apt-get install  fpc/stretch-backports  -y --allow-unauthenticated
		if [ $? != 0 ]; then 
			apt-get install  fpc/stretch-backports  -y --allow-unauthenticated  --fix-missing
			if [ $? != 0 ]; then
				echo "possible network instability! Try later!"
				exit 1
			fi
		fi
		disableUpgradeFPC
	fi
	apt-get install $libs_android $prog_tools  -y --allow-unauthenticated
	if [ "$?" != "0" ]; then
		apt-get install $libs_android $prog_tools  -y --allow-unauthenticated --fix-missing
		if [ $? != 0 ]; then
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
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
		SDK_MANAGER_CMD_PARAMETERS=(
			"platforms;android-26" 
			"platform-tools"
			"build-tools;26.0.2" 
			"tools" 
			"ndk-bundle" 
			"extras;android;m2repository" 
			--no_https --proxy=http 
			--proxy_host=$PROXY_SERVER 
			--proxy_port=$PORT_SERVER 
		)
		SDK_MANAGER_CMD_PARAMETERS2=(
			"android-26"
			"platform-tools"
			"build-tools-26.0.2" 
			"extra-google-google_play_services"
			"extra-android-m2repository"
			"extra-google-m2repository"
			"extra-google-market_licensing"
			"extra-google-market_apk_expansion"
		)
		SDK_MANAGER_CMD_PARAMETERS2_PROXY=(
			--no_https 
			#--proxy=http 
			--proxy-host=$PROXY_SERVER 
			--proxy-port=$PORT_SERVER 
		)
		SDK_LICENSES_PARAMETERS=( --licenses --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
		export http_proxy=$PROXY_URL
		export https_proxy=$PROXY_URL
#	ActiveProxy 1
	else
		SDK_MANAGER_CMD_PARAMETERS=(
			"platforms;android-26" 
			"platform-tools"
			"build-tools;26.0.2" 
			"tools" 
			"ndk-bundle" 
			"extras;android;m2repository"
		)			#ActiveProxy 0
		SDK_MANAGER_CMD_PARAMETERS2=(
			"android-26"
			"platform-tools"
			"build-tools-26.0.2" 
			"extra-google-google_play_services"
			"extra-android-m2repository"
			"extra-google-m2repository"
			"extra-google-market_licensing"
			"extra-google-market_apk_expansion"
			)
		SDK_LICENSES_PARAMETERS=(--licenses )
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
	changeDirectory $LAMW_USER_HOME
	mkdir -p $FPC_TRUNK_SOURCE_PATH
	changeDirectory $FPC_TRUNK_SOURCE_PATH
	svn checkout $FPC_TRUNK_URL
	if [ $? != 0 ]; then
		rm -rf trunk
		svn checkout "$FPC_TRUNK_URL"
		if [ $? != 0 ]; then 
			rm -rf "trunk"
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
	parseFPCTrunk
}
#wrapper to get FPC Sources 
getWrapperFPCSources(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		echo "Warming:mode experimental Android Aarch64!"
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
	changeDirectory $ROOT_LAMW
	export git_param=("clone" "$LAMW_SRC_LNK")
	if [ -e lazandroidmodulewizard/.git ]  ; then
		changeDirectory "$ROOT_LAMW/lazandroidmodulewizard"
		export git_param=("pull")
	fi
	
	git ${git_param[*]}
	if [ $? != 0 ]; then #case fails last command , try svn chekout
		
		export git_param=("clone" "$LAMW_SRC_LNK")
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
#this function get ant 
getAnt(){
	changeDirectory $ROOT_LAMW 
	
	if [ ! -e $ANT_HOME ]; then
		magicTrapIndex=-1 # preperando o indice do arquivo/diretório a ser removido
		trap TrapControlC  2
		wget -c $ANT_TAR_URL
		if [ $? != 0 ] ; then
			ANT_TAR_URL="https://www-eu.apache.org/dist/ant/binaries/apache-ant-1.10.5-bin.tar.xz"
			wget -c $ANT_TAR_URL
			if [ $? != 0 ]; then
				echo "possible network instability! Try later!"
				exit 1
			fi
		fi
		magicTrapIndex=1
		trap TrapControlC 2
		tar -xvf "$ANT_TAR_FILE"
	fi

	if [ -e  $ANT_TAR_FILE ]; then
		rm $ANT_TAR_FILE
	fi
}
#Get Gradle and SDK Tools 
getAndroidSDKTools(){
	changeDirectory $LAMW_USER_HOME
	if  [ ! -e $LAMW_USER_HOME/.android ]; then
		mkdir $LAMW_USER_HOME/.android 
		mkdir -p $HOME/.android 
		echo "create file"
		echo "" > $LAMW_USER_HOME/.android/repositories.cfg
		echo "" > $HOME/.android/repositories.cfg
	fi 

	if [ ! -e $ROOT_LAMW ]; then
		mkdir $ROOT_LAMW
	fi
	
	changeDirectory $ROOT_LAMW
	getAnt
	
	if [ ! -e $GRADLE_HOME ]; then
		magicTrapIndex=-1 # Set arquivo a ser removido
		trap TrapControlC  2 # set armadilha para o signal2 (siginterrupt)
		wget -c $GRADLE_ZIP_LNK
		if [ $? != 0 ] ; then
			wget -c $GRADLE_ZIP_LNK
		fi
		magicTrapIndex=3
		trap TrapControlC 2
		unzip $GRADLE_ZIP_FILE
	fi
	
	if [ -e  $GRADLE_ZIP_FILE ]; then
		rm $GRADLE_ZIP_FILE
	fi
	#mode OLD SDK (24 with ant support )
	if [ $OLD_ANDROID_SDK = 0 ]; then
		mkdir -p $ANDROID_SDK
		changeDirectory $ANDROID_SDK
 
		if [ ! -e tools ] ; then
			magicTrapIndex=4
			trap TrapControlC  2
			wget -c $SDK_TOOLS_URL #getting sdk 
			if [ $? != 0 ]; then 
				wget -c $SDK_TOOLS_URL
			fi
			magicTrapIndex=5
			trap TrapControlC 2
			unzip sdk-tools-linux-4333796.zip
			rm sdk-tools-linux-4333796.zip
		fi
	else
		changeDirectory $ROOT_LAMW
		getAnt
		export SDK_TOOLS_VERSION="r25.2.5"
		export SDK_TOOLS_URL="https://dl.google.com/android/repository/tools_r25.2.5-linux.zip"
		export SDK_TOOLS_ZIP="tools_r25.2.5-linux.zip"
		if [ ! -e sdk ]; then 
			mkdir $ANDROID_SDK
		fi
		changeDirectory $ANDROID_SDK
		if [ ! -e tools ];then
			magicTrapIndex=-1
			trap TrapControlC  2
			wget -c $SDK_TOOLS_URL
			if [ $? != 0 ]; then
				wget -c $SDK_TOOLS_URL
				if [ $? != 0 ]; then
					echo "possible network instability! Try later!"
					exit 1
				fi
			fi
			magicTrapIndex=5
			trap TrapControlC 2 
			unzip $SDK_TOOLS_ZIP
			rm $SDK_TOOLS_ZIP
		fi

		changeDirectory $ANDROID_SDK
		if [ ! -e ndk-bundle ] ; then
			magicTrapIndex=-1
			trap TrapControlC 2 
			wget -c $NDK_URL
			if [ $? != 0 ]; then
				wget -c $NDK_URL
				if [ $? != 0 ]; then
					echo "possible network instability! Try later!"
					exit 1
				fi
			fi
			magicTrapIndex=7
			trap TrapControlC 2
			unzip android-ndk-r18b-linux-x86_64.zip
			trap - SIGINT  #removendo a traps
			magicTrapIndex=-1
			mv android-ndk-r18b ndk-bundle
			if [ -e android-ndk-r18b-linux-x86_64.zip ]; then 
				rm android-ndk-r18b-linux-x86_64.zip
			fi
		fi
	fi
	trap - SIGINT  #removendo a traps
	magicTrapIndex=-1
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
	if [ -e $ANDROID_SDK/tools/android  ]; then 
		changeDirectory $ANDROID_SDK/tools
		if [ $NO_GUI_OLD_SDK = 0 ]; then
			echo "before update-sdk"
			./android update sdk
		else 
			for((i=0;i<${#SDK_MANAGER_CMD_PARAMETERS2[*]};i++))
			do
				echo "Getting \"${SDK_MANAGER_CMD_PARAMETERS2[i]}\" ..."
				#read;
				echo "y" |   ./android update sdk --all --no-ui --filter ${SDK_MANAGER_CMD_PARAMETERS2[i]} ${SDK_MANAGER_CMD_PARAMETERS2_PROXY[*]}
				if [ $? != 0 ]; then
					echo "y" |   ./android update sdk --all --no-ui --filter ${SDK_MANAGER_CMD_PARAMETERS2[i]} ${SDK_MANAGER_CMD_PARAMETERS2_PROXY[*]}
					if [ $? != 0 ]; then
						echo "possible network instability! Try later!"
						exit 1
					fi
				fi	
			done 
		fi
	fi

}

RepairOldSDKAndroid(){
	SDK_MANAGER_FAILS=(
		"platforms"
		"platform-tools"
		"build-tools"
		"extras"
	)
	echo "${VERMELHO}Warning:${NORMAL} All Android API'S will  be unistalled!"
	echo "Only the default APIs will be reinstalled!"
	for ((i=0;i<${#SDK_MANAGER_FAILS[*]};i++))
	do
		current_sdk_path="${ANDROID_SDK}/${SDK_MANAGER_FAILS[i]}"
		if [ -e $current_sdk_path ]; then
			rm -rf $current_sdk_path
		fi
	done
	getOldAndroidSDK
	for ((i=0;i<${#SDK_MANAGER_FAILS[*]};i++))
	do
		current_sdk_path="${ANDROID_SDK}/${SDK_MANAGER_FAILS[i]}"
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
	flag_need_repair=0 # flag de reparo 
	getStatusInstalation 
	if [ $LAMW_INSTALL_STATUS = 1 ]; then # só executa essa funcao se o lamw tiver instalado
		flag_old_fpc=""
		fpc_exe=$(which fpc) #verifica se existe o executavel para o fpc
		fpc_arm=$(which ppcarm )
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
			flag_old_fpc=$?
			#echo "flag_old_fpc=$flag_old_fpc";read
			aux_path=""
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


		expected_fpc_src_path="${LAMW4LINUX_HOME}/fpcsrc/"
		expected_fpc_src_path="${expected_fpc_src_path}${FPC_RELEASE}"
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
	flag_need_repair=0 # flag de reparo 
	flag_upgrade_lazarus=0
	getStatusInstalation 
	if [ $LAMW_INSTALL_STATUS = 1 ]; then # só executa essa funcao se o lamw tiver instalado
		flag_old_fpc=""
		fpc_exe=$(which fpc) #verifica se existe o executavel para o fpc
		fpc_aarch=$(which ppca64)	
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
		if [ "$fpc_arm" = "" ]; then
			flag_need_repair=1  # caso o  crosscompile para arm nao exista,  sinaliza reparo
		fi

		wrapperParseFPC
		# verifica se  a versao do codigo fonte do fpc casa com a versão do sistema
		if [ -e "$LAMW4LINUX_HOME/fpcsrc" ]; then 
		
			if [ -e "$LAMW4LINUX_HOME/fpcsrc/release_3_0_4" ]; then
				aux_path="$LAMW4LINUX_HOME/fpcsrc/release_3_0_4"
			else
				"$LAMW4LINUX_HOME/fpcsrc/release_3_0_0"
			fi

			#if [ $flag_match_fpc != 0 ] ; then # caso o código fonte do fpc do LAMW4Linux não match com o do sistema, verifica se necessita fazer downgrade ou upgrade
				#configureFPC
				wrapperConfigureFPC
				if [ -e $aux_path ]; then 
					rm -rf $aux_path
					flag_need_repair=1
					#getFPCSources
					getWrapperFPCSources
				fi
			#fi
		fi

		expected_fpc_src_path="$FPC_TRUNK_SOURCE_PATH/trunk"

		if [ ! -e $expected_fpc_src_path ]; then
			#getFPCSources
			getWrapperFPCSources
			flag_need_repair=1
		fi
			
		if [ $flag_need_repair = 1 ]; then
			
			CleanOldCrossCompileBins
			#BuildCrossArm $FPC_ID_DEFAULT
			wrapperBuildFPCCross
			if [ -e "$LAMW4LINUX_HOME/${LAZARUS_OLD_STABLE[0]}" ]; then
				rm -rf "$LAMW4LINUX_HOME/${LAZARUS_OLD_STABLE[0]}"
				getLazarusSources
			fi
			BuildLazarusIDE
			#CreateSDKSimbolicLinks
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
		true;
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
			LAMWPackageManager
		fi
	else
		export OLD_ANDROID_SDK=1 #obetem por padrão o old sdk 
		export NO_GUI_OLD_SDK=1
	fi
}

mainInstall(){

	installDependences
	checkProxyStatus
	#configureFPC
	wrapperParseFPC
	getAndroidSDKTools
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