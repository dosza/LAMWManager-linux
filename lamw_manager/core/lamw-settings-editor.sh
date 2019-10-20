#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (mater-alma)
#Course: Science Computer
#Version: 0.3.3
#Date: 10/11/2019
#Description: The "lamw-manager-settings-editor.sh" is part of the core of LAMW Manager. Responsible for managing LAMW Manager / LAMW configuration files..
#-------------------------------------------------------------------------------------------------#

enableADBtoUdev(){
	  printf 'SUBSYSTEM=="usb", ATTR{idVendor}=="<VENDOR>", MODE="0666", GROUP="plugdev"\n'  |  tee /etc/udev/rules.d/51-android.rules
	  service udev restart
}
configureFPC(){
	# parte do arquivo de configuração do fpc, 
	SearchPackage fpc
		index=$?
		parseFPC ${packs[$index]}
	#	if [ ! -e $FPC_CFG_PATH ]; then
			$FPC_MKCFG_EXE -d basepath=/usr/lib/fpc/$FPC_VERSION -o $FPC_CFG_PATH
		#fi

		#this config enable to crosscompile in fpc 
		fpc_cfg_str=(
			"#IFDEF ANDROID"
			"#IFDEF CPUARM"
			"-CpARMV7A"
			"-CfVFPV3"
			"-Xd"
			"-XParm-linux-androideabi-"
			"-Fl$ROOT_LAMW/ndk/platforms/android-$SDK_VERSION/arch-arm/usr/lib"
			"-FLlibdl.so"
			
			"-FD$ROOT_LAMW/ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin"
			'-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget'
			'-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget/*'
			'-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget/rtl'
			"#ENDIF"
			"#ENDIF"
		)

		if [ -e $FPC_CFG_PATH ] ; then  # se exiir /etc/fpc.cfg
			searchLineinFile $FPC_CFG_PATH  "${fpc_cfg_str[0]}"
			flag_fpc_cfg=$?

			if [ $flag_fpc_cfg != 1 ]; then # caso o arquvo ainda não esteja configurado
				AppendFileln "$FPC_CFG_PATH" "fpc_cfg_str"  
			fi
		fi
}


AddSDKPathstoProfile(){
	profile_file=$LAMW_USER_HOME/.bashrc
	flag_profile_paths=0
	profile_line_path='export PATH=$PATH:$GRADLE_HOME/bin'

	InsertUniqueBlankLine "$LAMW_USER_HOME/.profile"
	InsertUniqueBlankLine "$LAMW_USER_HOME/.bashrc"
	cleanPATHS
	searchLineinFile "$profile_file" "$profile_line_path"
	flag_profile_paths=$?

	if [ $flag_profile_paths = 0 ] ; then 
		echo "export ANDROID_HOME=$ANDROID_HOME" >>  $LAMW_USER_HOME/.bashrc
		echo "export GRADLE_HOME=$GRADLE_HOME" >> $LAMW_USER_HOME/.bashrc
		echo 'export PATH=$PATH:$ANDROID_HOME/ndk-toolchain' >> $LAMW_USER_HOME/.bashrc
		echo 'export PATH=$PATH:$GRADLE_HOME/bin' >> $LAMW_USER_HOME/.bashrc
	fi

	export PATH=$PATH:$ROOT_LAMW/ndk-toolchain
	export PATH=$PATH:$GRADLE_HOME/bin
}

#Esta funcao altera todos o dono de todos arquivos e  pastas do ambiente LAMW de root para o $LAMW_USER_HOME
#Ou seja para o usuario que invocou o lamw_manager (bootstrap)
changeOwnerAllLAMW(){
	#case only update-lamw
	if [ $# = 1 ]; then
		echo "Restoring directories ..."
		#sleep 2
		if [ -e $LAMW4_LINUX_PATH_CFG ]; then
			chown $LAMW_USER:$LAMW_USER -R $LAMW4_LINUX_PATH_CFG
		fi

		if [ -e $ROOT_LAMW/lazandroidmodulewizard ]; then 
			chown $LAMW_USER:$LAMW_USER -R $ROOT_LAMW/lazandroidmodulewizard
		fi
		if [ -e $LAMW_IDE_HOME ];then
			chown $LAMW_USER:$LAMW_USER -R $LAMW4LINUX_HOME/$LAZARUS_STABLE
		fi 
	else
		echo "Restoring directories ..."
		if [ -e $ROOT_LAMW ]; then
			chown  -R $LAMW_USER:$LAMW_USER $ROOT_LAMW 
		fi
		if  [ -e $FPC_CFG_PATH ]; then 
			chown $LAMW_USER:$LAMW_USER $FPC_CFG_PATH
		fi
		if [ -e $LAMW_USER_HOME/.profile ];then
			chown $LAMW_USER:$LAMW_USER $LAMW_USER_HOME/.profile
		fi
		if [ -e $LAMW_USER_HOME/.bashrc ]; then
			chown $LAMW_USER:$LAMW_USER $LAMW_USER_HOME/.bashrc
		fi
		if [ -e $LAMW_USER_HOME/.android ]; then
			chown $LAMW_USER:$LAMW_USER  -R $LAMW_USER_HOME/.android
		fi
		if [ -e $LAMW_USER_HOME ]; then
			chown $LAMW_USER:$LAMW_USER -R $LAMW_USER_HOME/.local/share
		fi
		if [ -e $LAMW4_LINUX_PATH_CFG ]; then
			chown $LAMW_USER:$LAMW_USER -R $LAMW4_LINUX_PATH_CFG
		fi
		if [ -e $LAMW_USER_HOME/Dev ]; then
			chown $LAMW_USER:$LAMW_USER -R  $LAMW_USER_HOME/Dev
		fi
	fi
}
#write log lamw install 
writeLAMWLogInstall(){
	fpc_version=$FPC_VERSION
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		fpc_version=$FPC_TRUNK_VERSION

	fi

	lamw_log_str=(
		"Generate LAMW_INSTALL_VERSION=$LAMW_INSTALL_VERSION" 
		"Info:"
		"LAMW4Linux:$LAMW4LINUX_HOME"
		"LAMW workspace:$LAMW_WORKSPACE_HOME"
		"Android SDK:$ROOT_LAMW/sdk" 
		"Android NDK:$ROOT_LAMW/ndk\nGradle:$GRADLE_HOME"
		"OLD_ANDROID_SDK=$OLD_ANDROID_SDK"
		"ANT_VERSION=$ANT_VERSION"
		"GRADLE_VERSION=$GRADLE_VERSION"
		"SDK_TOOLS_VERSION=$SDK_TOOLS_VERSION"
		"NDK_VERSION=$NDK_VERSION"
		"FPC_VERSION=$fpc_version"
		"LAZARUS_VERSION=$LAZARUS_STABLE_VERSION"
		"AARCH64_SUPPORT=$FLAG_FORCE_ANDROID_AARCH64"
		"Install-date:$(date)"
		)

	NOTIFY_SEND_EXE=$(which notify-send)
	WriterFileln "$LAMW4LINUX_HOME/lamw-install.log" "lamw_log_str"
	if [ "$NOTIFY_SEND_EXE" != "" ]; then
		$NOTIFY_SEND_EXE  "Info:\nLAMW4Linux:$LAMW4LINUX_HOME\nLAMW workspace : $LAMW_WORKSPACE_HOME\nAndroid SDK:$ROOT_LAMW/sdk\nAndroid NDK:$ROOT_LAMW/ndk\nGradle:$GRADLE_HOME\nLOG:$LAMW4LINUX_HOME/lamw-install.log"
	else
		printf "Info:\nLAMW4Linux:$LAMW4LINUX_HOME\nLAMW workspace : $LAMW_USER_HOME/Dev/lamw_workspace\nAndroid SDK:$ROOT_LAMW/sdk\nAndroid NDK:$ROOT_LAMW/ndk\nGradle:$GRADLE_HOME\nLOG:$LAMW4LINUX_HOME/lamw-install.log"
	fi		

}

#Add LAMW4Linux to menu 
AddLAMWtoStartMenu(){
	if [ ! -e $LAMW_USER_HOME/.local/share/applications ] ; then #create a directory of local apps launcher, if not exists 
		mkdir -p $LAMW_USER_HOME/.local/share/applications
	fi
	if [ ! -e $LAMW_USER_HOME/.local/share/mime/packages ]; then
		mkdir -p $LAMW_USER_HOME/.local/share/mime/packages
	fi
	
	lamw_desktop_file_str=(
		"[Desktop Entry]"  
		"Name=LAMW4Linux"   
		#Exec=$LAMW4LINUX_EXE_PATH --primary-config-path=$LAMW4_LINUX_PATH_CFG" 
		"Exec=$LAMW_IDE_HOME/startlamw4linux"
		"Icon=$LAMW_IDE_HOME/images/icons/lazarus_orange.ico"
		"Terminal=false"
		"Type=Application"  
		"Categories=Development;IDE;"  
		"Categories=Application;IDE;Development;GTK;GUIDesigner;"
		"StartupWMClass=LAMW4Linux"
		"MimeType=text/x-pascal;text/lazarus-project-source;text/lazarus-project-information;text/lazarus-form;text/lazarus-resource;text/lazarus-package;text/lazarus-package-link;text/lazarus-code-inlay;"
		"Keywords=editor;Pascal;IDE;FreePascal;fpc;Design;Designer;"
		"[Property::X-KDE-NativeExtension]"
		"Type=QString"
		"Value=.pas"
		"X-Ubuntu-Gettext-Domain=desktop_kdelibs"
	)

	WriterFileln "$LAMW_MENU_ITEM_PATH" "lamw_desktop_file_str"
	chmod +x $LAMW_MENU_ITEM_PATH
	cp $LAMW_MENU_ITEM_PATH "$work_home_desktop"
	#mime association: ref https://help.gnome.org/admin/system-admin-guide/stable/mime-types-custom-user.html.en
	cp $LAMW_IDE_HOME/install/lazarus-mime.xml $LAMW_USER_HOME/.local/share/mime/packages
	update-mime-database   $LAMW_USER_HOME/.local/share/mime/
	update-desktop-database $LAMW_USER_HOME/.local/share/applications
	update-menus
}

#this  fuction create a INI file to config  all paths used in lamw framework 
LAMW4LinuxPostConfig(){
	old_lamw_workspace="$LAMW_USER_HOME/Dev/lamw_workspace"
	if [ ! -e $LAMW4_LINUX_PATH_CFG ] ; then
		mkdir $LAMW4_LINUX_PATH_CFG
	fi

	if [ -e $old_lamw_workspace ]; then
		mv $old_lamw_workspace $LAMW_WORKSPACE_HOME
	fi
	if [ ! -e $LAMW_WORKSPACE_HOME ] ; then
		mkdir -p $LAMW_WORKSPACE_HOME
	fi

	java_versions=("/usr/lib/jvm/java-8-openjdk-amd64"  "/usr/lib/jvm/java-8-oracle"  "/usr/lib/jvm/java-8-openjdk-i386")
	java_path=""
	tam=${#java_versions[@]} #tam recebe o tamanho do vetor 
	ant_path=$ANT_HOME/bin
	ant_path=${ant_path%/ant*} #
	for (( i = 0; i < tam ; i++ )) # Laço para percorrer o vetor 
	do
		if [ -e ${java_versions[i]} ]; then
			java_path=${java_versions[i]}
			break;
		fi
	done



# contem o arquivo de configuração do lamw
	LAMW_init_str=(
		"[NewProject]"
		"PathToWorkspace=$LAMW_WORKSPACE_HOME"
		"PathToJavaTemplates=$ROOT_LAMW/lazandroidmodulewizard/android_wizard/smartdesigner/java"
		"PathToJavaJDK=$java_path"
		"PathToAndroidNDK=$ROOT_LAMW/ndk"
		"PathToAndroidSDK=$ROOT_LAMW/sdk"
		"PathToAntBin=$ant_path"
		"PathToGradle=$GRADLE_HOME"
		"PrebuildOSYS=linux-x86_64"
		"MainActivity=App"
		"FullProjectName="
		"InstructionSet=2"
		"AntPackageName=org.lamw"
		"AndroidPlatform=0"
		"AntBuildMode=debug"
		"NDK=5"
		"PathToSmartDesigner=$ROOT_LAMW/lazandroidmodulewizard/android_wizard/smartdesigner"

	)
	aux_str=''
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		aux_str="export PATH=$PATH"
	fi
	startlamw4linux_str=(
		'#!/bin/bash'
		"export PPC_CONFIG_PATH=$PPC_CONFIG_PATH"
		"$aux_str"
		"$LAMW4LINUX_EXE_PATH --primary-config-path=$LAMW4_LINUX_PATH_CFG \$*"
	)

	WriterFileln "$LAMW4_LINUX_PATH_CFG/LAMW.ini" "LAMW_init_str"
	WriterFileln "$LAMW_IDE_HOME/startlamw4linux" "startlamw4linux_str"

	if [ -e  $LAMW_IDE_HOME/startlamw4linux ]; then
		chmod +x $LAMW_IDE_HOME/startlamw4linux
		if [ ! -e "/usr/bin/startlamw4linux" ]; then
			ln -s "$LAMW_IDE_HOME/startlamw4linux" "/usr/bin/startlamw4linux"
		fi
	fi

	AddLAMWtoStartMenu
}

ActiveProxy(){
	svn --help > /dev/null
	if  [ $1 = 1 ]; then
		if [ -e ~/.subversion/servers ] ; then
			aux=$(tail -1 ~/.subversion/servers)       #tail -1 mostra a última linha do arquivo 
			if [ "$aux" != "" ] ; then   # verifica se a última linha é vazia
				sed  -i '$a\' ~/.subversion/servers #adiciona uma linha ao fim do arquivo
			fi
			#echo "write proxy with svn"
			echo "http-proxy-host=$PROXY_SERVER" >> ~/.subversion/servers
			echo "http-proxy-port=$PORT_SERVER" >> ~/.subversion/servers
			git config --global core.gitproxy $PROXY_URL #"http://$HOST:$PORTA"
			git config --global http.gitproxy $PROXY_URL #"http://$HOST:$PORTA"
		fi

	else
		sed -i "/http-proxy-host=$HOST/d" ~/.subversion/servers
		sed -i "/http-proxy-port=$PORTA/d" ~/.subversion/servers
		git config --global --unset core.gitproxy
		git config --global --unset http.gitproxy
		if [ -e ~/.gitconfig ] ;then
		#cat ~/.gitconfig
			sed -i '/\[core\]/d' ~/.gitconfig
			#cat ~/.gitconfig
			sed -i '/\[http\]/d' ~/.gitconfig
		fi
	fi
}
CleanOldCrossCompileBins(){
	wrapperParseFPC
	if [ -e $FPC_LIB_PATH/ppcrossarm ]; then
		 rm $FPC_LIB_PATH/ppcrossarm
	fi
	
	if [ -e /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android ]; then
		 rm -r /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android
	fi
	if [ -e /usr/lib/fpc/$FPC_VERSION/units/arm-android ]; then
		 rm -r /usr/lib/fpc/$FPC_VERSION/units/arm-android
	fi


	if [  -e /usr/local/bin/fpc ]; then
		fpc_tmp_files=("bin2obj" "chmcmd" "chmls" "cldrparser" "compileserver" "cvsco.tdf" "cvsdiff.tdf" "cvsup.tdf" "data2inc" "delp" "fd2pascal" "fp" "fp.ans" "fpc" "fpcjres" "fpclasschart" "fpclasschart.rsj" "fpcmake" "fpcmkcfg" "fpcmkcfg.rsj" "fpcres" "fpcsubst" "fpcsubst.rsj" "fpdoc" "fppkg" "fprcp" "fp.rsj" "gplprog.pt" "gplunit.pt" "grab_vcsa" "grep.tdf" "h2pas" "h2paspp" "instantfpc" "json2pas" "makeskel" "makeskel.rsj" "mka64ins" "mkarmins" "mkinsadd" "mkx86ins" "pas2fpm" "pas2jni" "pas2js" "pas2ut" "pas2ut.rsj" "plex" "postw32" "ppdep" "ppudump" "ppufiles" "ppumove" "program.pt" "ptop" "ptop.rsj" "pyacc" "rmcvsdir" "rstconv" "rstconv.rsj" "tpgrep.tdf" "unihelper" "unitdiff" "unitdiff.rsj" "unit.pt" "webidl2pas")
		for((i=0;i<${#fpc_tmp_files[*]};i++)); do
			local aux="/usr/local/${fpc_tmp_files[i]}"
			if [ -e $aux ]; then  rm $aux ; fi
		done
	fi
	
	if [  -e /usr/local/lib/fpc/3.3.1 ]; then
		rm -rf /usr/local/lib/fpc/3.3.1
	fi
}

	

cleanPATHS(){
	sed -i "/export ANDROID_HOME=*/d"  $LAMW_USER_HOME/.bashrc
	sed -i "/export GRADLE_HOME=*/d" $LAMW_USER_HOME/.bashrc
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/android\/ndk-toolchain/d'  $LAMW_USER_HOME/.bashrc #\/ is scape of /
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/android\/gradle-4.1\/bin/d' $LAMW_USER_HOME/.bashrc
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/android\/ndk-toolchain/d'  $LAMW_USER_HOME/.profile
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/android\/gradle-4.1\/bin/d' $LAMW_USER_HOME/.profile	
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/ndk-toolchain/d'  $LAMW_USER_HOME/.bashrc
	sed -i '/export PATH=$PATH:$GRADLE_HOME/d'  $LAMW_USER_HOME/.bashrc
}
#this function remove old config of lamw4linux  
CleanOldConfig(){
	wrapperParseFPC
	CleanOldCrossCompileBins

	if [ -e "/usr/bin/aarch64-linux-androideabi-as" ]; then
		rm "/usr/bin/aarch64-linux-androideabi-as"
	fi

	if [ -e "/usr/bin/aarch64-linux-androideabi-ld" ] ; then
		rm "/usr/bin/aarch64-linux-androideabi-ld"
	fi

	if  [ -e "/usr/bin/ppca64"  ]; then 
		rm  -rf "/usr/bin/ppca64" 
	fi
	if  [ -e "/usr/bin/ppcrossa64" ]; then
		rm  -rf "/usr/bin/ppcrossa64"
	fi
	if [ -e "/usr/bin/ppcarm"   ]; then
		rm  -rf "/usr/bin/ppcarm"
	fi	
	if [ -e "/usr/bin/ppcrossarm"  ]; then
		rm -rf "/usr/bin/ppcrossarm" 
	fi

	if [ -e  /usr/bin/arm-linux-androideabi-ld ]; then
		  rm /usr/bin/arm-linux-androideabi-ld
	fi

	if [ -e /usr/bin/arm-linux-as ] ; then 
	 	 rm  /usr/bin/arm-linux-as
	fi
	if [ -e /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android ]; then
		 rm -r /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android
	fi


	if [ -e /usr/bin/arm-linux-androideabi-as ]; then
		 rm /usr/bin/arm-linux-androideabi-as
	fi
	if [ -e /usr/bin/arm-linux-ld ] ; then 
		 rm /usr/bin/arm-linux-ld
	fi

	if [  -e "/usr/bin/startlamw4linux" ]; then
		rm "/usr/bin/startlamw4linux"
	fi

	if [ -e $FPC_CFG_PATH ]; then #remove local ppc config
		rm $FPC_CFG_PATH
	fi

		echo "Uninstall LAMW4Linux IDE ..."
	# if [ -e $LAMW4LINUX_HOME ] ; then
	# 	 rm $LAMW4LINUX_HOME -rf
	# fi

	if [ -e $LAMW4_LINUX_PATH_CFG ]; then  rm -r $LAMW4_LINUX_PATH_CFG; fi

	if [ -e $ROOT_LAMW ] ; then
		 rm $ROOT_LAMW  -rf
	fi


	if [ -e $LAMW_MENU_ITEM_PATH ]; then
		rm $LAMW_MENU_ITEM_PATH
	fi

	if [ -e $GRADLE_CFG_HOME ]; then
		rm -r $GRADLE_CFG_HOME
	fi
	if [ -e "$work_home_desktop/lamw4linux.desktop" ]; then
		rm "$work_home_desktop/lamw4linux.desktop"
	fi
	if [ -e $LAMW_USER_HOME/.local/share/mime/packages/lazarus-mime.xml ]; then
		rm $LAMW_USER_HOME/.local/share/mime/packages/lazarus-mime.xml
		update-mime-database   $LAMW_USER_HOME/.local/share/mime/
		update-desktop-database $LAMW_USER_HOME/.local/share/applications
		update-menus
	fi


	if  [  -e $LAMW_USER_HOME/.android ]; then
		rm -r  $LAMW_USER_HOME/.android 
	fi

	if [ -e /root/.android ]; then 
		rm -r /root/.android
	fi
	cleanPATHS

	if [ -e $FPC_TRUNK_LIB_PATH ]; then
		rm -rf $FPC_TRUNK_LIB_PATH
	fi

	if [ -e $FPC_TRUNK_EXEC_PATH ]; then
		rm $FPC_TRUNK_EXEC_PATH/fpc* 
	fi

	if [ -e /root/.fpc.cfg ]; then
		rm /root/.fpc.cfg
	fi
	if [ -e $OLD_FPC_CFG_PATH ]; then
		rm $OLD_FPC_CFG_PATH
	fi
	
}

#Create SDK simbolic links
CreateSDKSimbolicLinks(){
	ln -sf "$ROOT_LAMW/sdk/ndk-bundle" "$ROOT_LAMW/ndk"
	ln -sf "$ARM_ANDROID_TOOLS" "$ROOT_LAMW/ndk-toolchain"
	ln -sf "$ARM_ANDROID_TOOLS/arm-linux-androideabi-as" "$ROOT_LAMW/ndk-toolchain/arm-linux-as"
	ln -sf "$ARM_ANDROID_TOOLS/arm-linux-androideabi-ld" "$ROOT_LAMW/ndk-toolchain/arm-linux-ld"
	ln -sf "$ARM_ANDROID_TOOLS/arm-linux-androideabi-as" "/usr/bin/arm-linux-androideabi-as"
	ln -sf "$ARM_ANDROID_TOOLS/arm-linux-androideabi-ld" "/usr/bin/arm-linux-androideabi-ld"
	ln -sf "$ARM_ANDROID_TOOLS/arm-linux-androideabi-as" "/usr/bin/arm-linux-androideabi-as"
	if [  $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then 
		ln -sf $FPC_TRUNK_LIB_PATH/ppcrossarm /usr/bin/ppcrossarm
		ln -sf $FPC_TRUNK_LIB_PATH/ppcrossarm /usr/bin/ppcarm
	else
		ln -sf $FPC_LIB_PATH/ppcrossarm /usr/bin/ppcrossarm
		ln -sf /usr/bin/ppcrossarm /usr/bin/ppcarm
	fi
	ln -sf "$ROOT_LAMW/sdk/ndk-bundle/toolchains/arm-linux-androideabi-4.9" "$ROOT_LAMW/sdk/ndk-bundle/toolchains/mips64el-linux-android-4.9"
	ln -sf "$ROOT_LAMW/sdk/ndk-bundle/toolchains/arm-linux-androideabi-4.9" "$ROOT_LAMW/sdk/ndk-bundle/toolchains/mipsel-linux-android-4.9"
}
#--------------------------AARCH64 SETTINGS--------------------------

configureFPCTrunk(){
	# parte do arquivo de configuração do fpc, 
	#	if [ ! -e $FPC_CFG_PATH ]; then
	parseFPCTrunk
	$FPC_MKCFG_EXE -d basepath=$FPC_TRUNK_LIB_PATH -o $FPC_CFG_PATH


	fpc_trunk_parent=$FPC_TRUNK_LIB_PATH
	fpc_trunk_parent=$(echo $fpc_trunk_parent | sed "s/\/$_FPC_TRUNK_VERSION//g")
	#ls $fpc_trunk_parent;echo $fpc_trunk_parent;read;

	#this config enable to crosscompile in fpc 
	fpc_cfg_str=(
		"#IFDEF ANDROID"
		"#IFDEF CPUARM"
		"-CpARMV7A"
		"-CfVFPV3"
		"-Xd"
		"-XParm-linux-androideabi-"
		"-Fl$ROOT_LAMW/ndk/platforms/android-$SDK_VERSION/arch-arm/usr/lib"
		"-FLlibdl.so"
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget'
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget/*'
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget/rtl'
		
		"-FD$ROOT_LAMW/ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin"
		"#ENDIF"

		"#IFDEF CPUAARCH64"
		"-Xd"
		"-XPaarch64-linux-android-"
		"-Fl$ROOT_LAMW/ndk/platforms/android-$SDK_VERSION/arch-arm64/usr/lib"
		"-FLlibdl.so"
		"-FD$ROOT_LAMW/ndk/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin"
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget'
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget/*'
		"-Fu${fpc_trunk_parent}/"'$fpcversion/units/$fpctarget/rtl'
	
		"#ENDIF"
		"#ENDIF"
	)

	if [ -e $FPC_CFG_PATH ] ; then  # se exiir /etc/fpc.cfg
		searchLineinFile $FPC_CFG_PATH  "${fpc_cfg_str[0]}"
		flag_fpc_cfg=$?

		if [ $flag_fpc_cfg != 1 ]; then # caso o arquvo ainda não esteja configurado
			AppendFileln "$FPC_CFG_PATH" "fpc_cfg_str"		
		fi
	fi
}



CreateSimbolicLinksAndroidAARCH64(){
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-as" "$AARCH64_ANDROID_TOOLS/aarch64-linux-as"
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-ld" "$AARCH64_ANDROID_TOOLS/aarch64-linux-ld"
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-as" "/usr/bin/aarch64-linux-android-as"
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-ld" "/usr/bin/aarch64-linux-android-ld"
	ln -sf "${FPC_TRUNK_LIB_PATH}/ppcrossa64" /usr/bin/ppcrossa64
	ln -sf "${FPC_TRUNK_LIB_PATH}/ppcrossa64" /usr/bin/ppca64
}

wrapperCreateSDKSimbolicLinks(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		CreateSDKSimbolicLinks
		CreateSimbolicLinksAndroidAARCH64
	else
		CreateSDKSimbolicLinks
	fi
}

#echo "importei lamw-settings-editor.sh";read

CreateFPCTrunkBootStrap(){

	fpc_trunk_boostrap_path="$FPC_TRUNK_EXEC_PATH/fpc"
	fpc_bootstrap_str=(
		'#!/bin/bash'
		"#Bootsrap(to FPC Trunk) generate by LAMW Manager"
		"#### THIS FILE IS AUTOMATICALLY CONFIGURED"
		#"export LAMW_ENV=$LAMW4LINUX_HOME/usr/bin"
		#'export PATH=$LAMW_ENV:$PATH'
		"export FPC_TRUNK_LIB_PATH=$FPC_TRUNK_LIB_PATH"
		#'export LD_LIBRARY=$LAMW_ENV/usr/lib:$LD_LIBRARY'
		#sudo ldconfig
		'export FPC_ARGS=($*)'
		'export FPC_EXEC="ppcx64"'
		#'if [ -e $FPC_TRUNK_LIB_PATH/ppcrossa64 ]; then'
		'if [ -e $FPC_TRUNK_LIB_PATH/ppcrossarm ]; then'
		'	export PATH=$FPC_TRUNK_LIB_PATH:$PATH'
		'fi'

		''
		'for((i=0;i<${#FPC_ARGS[*]};i++))'
		'do'

		'		case "${FPC_ARGS[i]}" in'
		'			"-Parm")'
		'				export FPC_EXEC="ppcarm"'
		'				break'
		'			;;'

		'			"-Paarch64")'
		'				export FPC_EXEC="ppca64"'
		'				break'
		'			;;'
		'		esac'
		'done'
		'$FPC_EXEC ${FPC_ARGS[@]}'
	)

	WriterFileln "$fpc_trunk_boostrap_path" "fpc_bootstrap_str"
	chmod +x "$fpc_trunk_boostrap_path"
}

initLAMw4LinuxConfig(){
	lazarus_env_cfg_str=(
	'<?xml version="1.0" encoding="UTF-8"?>'
	'<CONFIG>'
	'	<EnvironmentOptions>'
	"		<LazarusDirectory Value=\"/home/danny/LAMW/lamw4linux/lamw4linux/\"/>"
	"		<CompilerFilename Value=\"$FPC_TRUNK_EXEC_PATH/fpc\"/>"
	"	</EnvironmentOptions>"
	"</CONFIG>"
	)
	lazarus_env_cfg_path="$LAMW4_LINUX_PATH_CFG/environmentoptions.xml"

	if [ ! -e $LAMW4_LINUX_PATH_CFG ]; then
		mkdir $LAMW4_LINUX_PATH_CFG
		WriterFileln  "$lazarus_env_cfg_path" "lazarus_env_cfg_str"
	else
		fpc_splited=(
			$(GenerateScapesStr "/usr/bin/fpc"					)				 		#0
			$(GenerateScapesStr "/usr/share/fpcsrc/\$(FPCVer)"	) 						#1
			$(GenerateScapesStr "/usr/local/bin/fpc"			)						#2
			$(GenerateScapesStr "$FPC_TRUNK_SOURCE_PATH/trunk" 	)						#3
			$(GenerateScapesStr "$LAMW4LINUX_HOME/usr/bin/fpc" 	)						#4
			$(GenerateScapesStr "$FPC_TRUNK_SOURCE_PATH/${FPC_TRUNK_SVNTAG}")			#5
		)
		
		cat $lazarus_env_cfg_path | grep 'CompilerFilename Value=\"\/usr\/bin\/fpc\"'
		if [ $? = 0 ]; then
			sed -i "s/CompilerFilename Value=\"${fpc_splited[0]}\"/CompilerFilename Value=\"${fpc_splited[4]}\"/g" "$lazarus_env_cfg_path"
			sed -i "s/FPCSourceDirectory Value=\"${fpc_splited[1]}\"/FPCSourceDirectory Value=\"${fpc_splited[5]}\"/g" "$lazarus_env_cfg_path"
		fi
		cat $lazarus_env_cfg_path | grep 'CompilerFilename Value=\"\/usr\/local\/bin\/fpc\"'
		if [ $? = 0 ]; then
			sed -i "s/CompilerFilename Value=\"${fpc_splited[2]}\"/CompilerFilename Value=\"${fpc_splited[4]}\"/g" "$lazarus_env_cfg_path"
			sed -i "s/FPCSourceDirectory Value=\"${fpc_splited[3]}\"/FPCSourceDirectory Value=\"${fpc_splited[5]}\"/g" "$lazarus_env_cfg_path"
		fi
	fi
}