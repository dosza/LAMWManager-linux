
#!/bin/bash
#Universidade federal de Mato Grosso
#Curso ciencia da computação
#AUTOR: Daniel Oliveira Souza <oliveira.daniel@gmail.com>
#Versao LAMW-INSTALL: 0.1.2
#Descrição: Este script configura o ambiente de desenvolvimento para o LAMW

#pwd
LAMW_INSTALL_VERSION="0.1.2"
LAMW_INSTALL_WELCOME=(
	"\t\tWelcome LAMW4Linux Installer  version: $LAMW_INSTALL_VERSION\n"
	"\t\tPowerd by DanielTimelord\n"
	"\t\t<oliveira.daniel109@gmail.com>\n"
)


export DEBIAN_FRONTEND="gnome"
export URL_FPC=""
export FPC_VERSION=""
export FPC_CFG_PATH=""
export FPC_RELEASE=""
export flag_new_ubuntu_lts=0
export FPC_LIB_PATH=""
export FPC_VERSION=""
ANDROID_HOME="$HOME/android"
ANDROID_SDK="$ANDROID_HOME/sdk"
CROSS_COMPILE_URL="https://github.com/newpascal/fpcupdeluxe/releases/tag/v1.6.1e"
APT_OPT=""
PROXY_SERVER="internet.cua.ufmt.br"
PORT_SERVER=3128
PROXY_URL="http://$PROXY_SERVER:$PORT_SERVER"
USE_PROXY=0
SDK_TOOLS_URL="https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip"
SDK_VERSION="28"
SDK_MANAGER_CMD_PARAMETERS=()
SDK_LICENSES_PARAMETERS=()
LAZARUS_STABLE_SRC_LNK="https://svn.freepascal.org/svn/lazarus/tags/lazarus_1_8_4"
LAMW_SRC_LNK="https://github.com/jmpessoa/lazandroidmodulewizard.git"
LAMW4_LINUX_PATH_CFG="$HOME/.lamw4linux"
LAMW4LINUX_HOME=$HOME/lamw4linux
LAMW_IDE_HOME="$LAMW4LINUX_HOME/lamw4linux" # path to link-simbolic to ide 
LAMW_WORKSPACE_HOME="$HOME/Dev/lamw_workspace"  #path to lamw_workspace
LAMW4LINUX_EXE_PATH="$LAMW_IDE_HOME/lamw4linux"
LAMW_MENU_ITEM_PATH="$HOME/.local/share/applications/lamw4linux.desktop"
GRADLE_HOME="$ANDROID_HOME/gradle-4.1"
GRADLE_CFG_HOME="$HOME/.gradle"
GRADE_ZIP_LNK="https://services.gradle.org/distributions/gradle-4.1-bin.zip"
GRADE_ZIP_FILE="gradle-4.1-bin.zip"
FPC_STABLE=""
LAZARUS_STABLE="lazarus_1_8_4"
LAZBUILD_PARAMETERS=(
	"--build-ide= --add-package $ANDROID_HOME/lazandroidmodulewizard/trunk/android_bridges/tfpandroidbridge_pack.lpk --primary-config-path=$LAMW4_LINUX_PATH_CFG  --lazarusdir=$LAMW_IDE_HOME"
	"--build-ide= --add-package $ANDROID_HOME/lazandroidmodulewizard/trunk/android_wizard/lazandroidwizardpack.lpk --primary-config-path=$LAMW4_LINUX_PATH_CFG --lazarusdir=$LAMW_IDE_HOME"
	"--build-ide= --add-package $ANDROID_HOME/lazandroidmodulewizard/trunk/ide_tools/amw_ide_tools.lpk --primary-config-path=$LAMW4_LINUX_PATH_CFG --lazarusdir=$LAMW_IDE_HOME"
)


libs_android="libx11-dev libgtk2.0-dev libgdk-pixbuf2.0-dev libcairo2-dev libpango1.0-dev libxtst-dev libatk1.0-dev libghc-x11-dev freeglut3 freeglut3-dev "
prog_tools="menu fpc git subversion make build-essential zip unzip unrar android-tools-adb ant openjdk-8-jdk "
packs=()

LAMW4LinuxPostConfig(){
	if [ ! -e $LAMW4_LINUX_PATH_CFG ] ; then
		mkdir LAMW4_LINUX_PATH_CFG
	fi

	if [ ! -e $LAMW_WORKSPACE_HOME ] ; then
		mkdir -p $LAMW_WORKSPACE_HOME
	fi
	java_versions=("/usr/lib/jvm/java-8-openjdk-amd64"  "/usr/lib/jvm/java-8-oracle"  "/usr/lib/jvm/java-8-openjdk-i386")
	java_path=""
	tam=${#java_versions[@]} #tam recebe o tamanho do vetor 
	ant_path=$(which ant)
	ant_path=${ant_path%/ant*} #
	i=0 #Inicializando o contador 
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
		"PathToJavaTemplates=$HOME/android/lazandroidmodulewizard.git/trunk/java"
		"PathToJavaJDK=$java_path"
		"PathToAndroidNDK=$HOME/android/ndk"
		"PathToAndroidSDK=$HOME/android/sdk"
		"PathToAntBin=$ant_path"
		"PathToGradle=$GRADLE_HOME"
		"PrebuildOSYS=linux-x86_64"
		"MainActivity=App"
		"FullProjectName="
		"InstructionSet=1"
		"AntPackageName=org.lamw"
		"AndroidPlatform=0"
		"AntBuildMode=debug"
		"NDK=5"
	)
	for ((i=0;i<${#LAMW_init_str[@]};i++))
	do
		if [ $i = 0 ]; then 
			echo ${LAMW_init_str[i]} > $LAMW4_LINUX_PATH_CFG/JNIAndroidProject.ini 
		else
			echo ${LAMW_init_str[i]} >> $LAMW4_LINUX_PATH_CFG/JNIAndroidProject.ini
		fi
	done
}
changeDirectory(){
	if [ "$1" != "" ] ; then
		if [ -e $1  ]; then
			cd $1
		fi
	fi 
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


CleanOldConfig(){
	if [ -e $HOME/laz4ndroid ]; then
		sudo rm  -r $HOME/laz4ndroid
	fi
	if [ -e $HOME/.laz4android ] ; then
		rm -r $HOME/.laz4android
	fi
	if [ -e $LAMW4LINUX_HOME ] ; then
		sudo rm $LAMW4LINUX_HOME -r
	fi

	if [ -e $LAMW4_LINUX_PATH_CFG ]; then  rm -r $LAMW4_LINUX_PATH_CFG; fi

	if [ -e $ANDROID_HOME ] ; then
		sudo rm $ANDROID_HOME  -r
	fi


	if [ -e $HOME/.local/share/applications/laz4android.desktop ];then
		rm $HOME/.local/share/applications/laz4android.desktop
	fi

	if [ -e $LAMW_MENU_ITEM_PATH ]; then
		rm $LAMW_MENU_ITEM_PATH
	fi

	if [ -e $GRADLE_CFG_HOME ]; then
		rm -r $GRADLE_CFG_HOME
	fi
	if [ -e /usr/lib/fpc ] ; then
		sudo rm /usr/lib/fpc -r 
		sudo rm /etc/fpc* 
	fi
	if [ -e /usr/local/lib/fpc ]; then
		sudo rm /usr/local/lib/fpc -r 
	fi
	if [ /usr/bin/ppcrossarm ]; then
		sudo rm /usr/bin/ppc* 
	fi
	if [  /usr/bin/fpc ]; then
		sudo rm /usr/bin/fpc* 
	fi
	if [ -e usr/bin/arm-embedded-as ] ; then    
		sudo rm usr/bin/arm-embedded-as
	fi
	if [ -e  /usr/bin/arm-linux-androideabi-ld ]; then
		 sudo rm /usr/bin/arm-linux-androideabi-ld
	fi
	if [ -e /usr/bin/arm-embedded-ld  ]; then
		sudo /usr/bin/arm-embedded-ld           
	fi 
	if [ -e /usr/bin/arm-linux-as ] ; then 
	 	sudo rm  /usr/bin/arm-linux-as
	fi


	if [ -e /usr/bin/arm-linux-androideabi-as ]; then
		sudo rm /usr/bin/arm-linux-androideabi-as
	fi
	if [ -e /usr/bin/arm-linux-ld ] ; then 
		sudo rm /usr/bin/arm-linux-ld
	fi
	sed -i '/export PATH=$PATH:$HOME\/android\/ndk-toolchain/d'  $HOME/.bashrc #\/ is scape of /
	sed -i '/export PATH=$PATH:$HOME\/android\/gradle-4.1\/bin/d' $HOME/.bashrc
	sed -i '/export PATH=$PATH:$HOME\/android\/ndk-toolchain/d'  $HOME/.profile
	sed -i '/export PATH=$PATH:$HOME\/android\/gradle-4.1\/bin/d' $HOME/.profile		
}
SearchPackage(){
	index=-1
	#vetor que armazena informações sobre a intalação do pacote
	if [ $1 != "" ]  ; then
		packs=( $(dpkg -l $1) )
		
		tam=${#packs[@]}
		if  [ $tam = 0 ] ; then
			sudo apt-get install fpc -y
			packs=( $(dpkg -l $1) )
		fi

		for (( i = 0 ; i < ${#packs[*]};i++))
		do
			if [ "${packs[i]}" = "$1" ] ; then
				((index=i))
				((index++))
				FPC_VERSION=${packs[index]}
				echo "${packs[index]}"
				break
			fi
		done
	fi
	return $index
}
#detecta a versão do fpc instalada no PC  seta as váriavies de ambiente
parseFPC(){ 

	
	dist_file=$(cat /etc/issue.net)
	case "$dist_file" in 
		*"Ubuntu 18."*)
			export flag_new_ubuntu_lts=1
		;;
		*"Linux Mint 19"*)
			export flag_new_ubuntu_lts=1
		;;
	esac

	case "$1" in 
		*"3.0.0"*)
			export URL_FPC="https://svn.freepascal.org/svn/fpc/tags/release_3_0_0"
			export FPC_LIB_PATH="/usr/lib/fpc"
			export FPC_CFG_PATH="/etc/fpc-3.0.0.cfg"
			export FPC_RELEASE="release_3_0_0"
			export FPC_VERSION="3.0.0"
			export FPC_LIB_PATH="/usr/lib/fpc/$FPC_VERSION"
		;;
		*"3.0.4"*)
			export FPC_VERSION="3.0.4"
			export URL_FPC="https://svn.freepascal.org/svn/fpc/tags/release_3_0_4"
			export FPC_CFG_PATH="/etc/fpc-3.0.4.cfg"
			if [ $flag_new_ubuntu_lts = 0 ] ; then
				if [ -e /usr/lib/fpc/$FPC_VERSION ]; then
					export FPC_LIB_PATH="/usr/lib/fpc/$FPC_VERSION"
				fi

			else
				if [ -e /usr/lib/x86_64-linux-gnu/fpc/$FPC_VERSION ]; then
					sudo ln -s /usr/lib/x86_64-linux-gnu/fpc /usr/lib/fpc 
					export FPC_LIB_PATH="/usr/lib/fpc/$FPC_VERSION"
				fi
			fi

			export FPC_RELEASE="release_3_0_4"
		;;
	esac
}

configureFPC(){
	if [ "$(whoami)" = "root" ];then
		packs=()
		ANDROID_HOME=$1
		SearchPackage fpc
		index=$?
		parseFPC ${packs[$index]}
	fi
	# parte do arquivo de configuração do fpc, 
	SearchPackage fpc
		index=$?
		parseFPC ${packs[$index]}
		fpc_cfg_str=(
			"#IFDEF ANDROID"
			"#IFDEF CPUARM"
			"-XParm-linux-androideabi-"
			"-Fl$ANDROID_HOME/ndk/platforms/android-$SDK_VERSION/arch-arm/usr/lib"
			"-FD$ANDROID_HOME/ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin"
			'-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget'
			'-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget/*'
			'-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget/rtl'
			"#ENDIF"
			"#ENDIF"
		)

		if [ -e $FPC_CFG_PATH ] ; then  # se exiir /etc/fpc.cfg
			fpc_cfg_teste=$(cat $FPC_CFG_PATH) # abre /etc/fpc.cfg
			flag_fpc_cfg=0 # flag da sub string de configuração"
			case "$fpc_cfg_teste" in 
				*"#IFDEF ANDROID"*)
				flag_fpc_cfg=1
				;;
			esac

			if [ $flag_fpc_cfg != 1 ]; then # caso o arquvo ainda não esteja configurado
				for ((i = 0 ; i<${#fpc_cfg_str[@]};i++)) 
				do
					#echo ${fpc_cfg_str[i]}
					sudo echo "${fpc_cfg_str[i]}" | sudo tee -a  $FPC_CFG_PATH
				done	
			fi
		fi
}

mainInstall(){
	if [ "$1" = "--use_proxy" ] ;then
				USE_PROXY=1
			fi

			if [ $USE_PROXY = 1 ]; then
				SDK_MANAGER_CMD_PARAMETERS=("platforms;android-25" "build-tools;25.0.3" "tools" "ndk-bundle" "extras;android;m2repository" --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
				SDK_LICENSES_PARAMETERS=( --licenses --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
				export http_proxy=$PROXY_URL
				export https_proxy=$PROXY_URL
		#	ActiveProxy 1
			else
				SDK_MANAGER_CMD_PARAMETERS=("platforms;android-25" "build-tools;25.0.3" "tools" "ndk-bundle" "extras;android;m2repository")			#ActiveProxy 0
				SDK_LICENSES_PARAMETERS=(--licenses )
			fi
			sudo apt update;
			sudo apt-get remove --purge fpc* -y
			sudo apt-get remove --purge  lazarus* -y
			sudo apt-get autoremove --purge -y
			#sudo apt-get install fpc




		sudo apt-get install $libs_android $prog_tools  -y --allow-unauthenticated
		if [ "$?" != "0" ]; then
			sudo apt-get install $libs_android $prog_tools  -y --allow-unauthenticated --fix-missing
		fi

		configureFPC
		if [ $USE_PROXY = 1 ] ; then
			ActiveProxy 1
		else
			ActiveProxy 0
		fi
		mkdir -p $ANDROID_SDK

		changeDirectory $ANDROID_HOME
		if [ ! -e $GRADLE_HOME ]; then
			wget $GRADE_ZIP_LNK
			if [ $? != 0 ] ; then
				rm *.zip*
				wget $GRADE_ZIP_LNK
			fi
			unzip $GRADE_ZIP_FILE
		fi
		
		if [ -e  $GRADE_ZIP_FILE ]; then
			rm $GRADE_ZIP_FILE
		fi
		changeDirectory $ANDROID_SDK
		#echo "pwd=$PWD"1
		#ls -la 
		if [ ! -e tools ] ; then
			wget $SDK_TOOLS_URL #getting sdk 
			if [ $? != 0 ]; then 
				wget $SDK_TOOLS_URL
			fi
			unzip sdk-tools-linux-3859397.zip
		fi
		
		#rm sdk-tools-linux-3859397.zip

		changeDirectory $ANDROID_SDK/tools/bin #change directory
		#sed -i 's/exec "$JAVACMD" "$@"/yes | exec "$JAVACMD" "$@"/g' sdkmanager #modifica o sdkmanager adicionando pipe para aceitar a licença
		#Install SDK packages and NDK
		#./sdkmanager "platforms;android-25" "build-tools;25.0.3" "tools" "ndk-bundle" "extras;android;m2repository"
		#$SDK_MANAGER_CMD
		#ls
		
		if [ $flag_new_ubuntu_lts = 1 ]
		then
			sudo apt-get remove --purge openjdk-9-* -y 
			sudo apt-get remove --purge openjdk-11* -y
		fi
		yes | ./sdkmanager ${SDK_LICENSES_PARAMETERS[*]}
		./sdkmanager ${SDK_MANAGER_CMD_PARAMETERS[*]}  # instala sdk sem intervenção humana  
		#sed -i 's/yes | exec "$JAVACMD" "$@"/exec "$JAVACMD" "$@"/g' sdkmanager # restaura o estado anterior do arquivo

		ln -sf "$ANDROID_HOME/sdk/ndk-bundle" "$ANDROID_HOME/ndk"
		ln -sf "$ANDROID_HOME/ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin" "$ANDROID_HOME/ndk-toolchain"
		ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-androideabi-as" "$ANDROID_HOME/ndk-toolchain/arm-linux-as"
		ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-androideabi-ld" "$ANDROID_HOME/ndk-toolchain/arm-linux-ld"

		sudo ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-androideabi-as" "/usr/bin/arm-linux-androideabi-as"
		sudo ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-ld"  "/usr/bin/arm-linux-androideabi-ld"

		aux=$(tail -1 $HOME/.profile)       #tail -1 mostra a última linha do arquivo 
		if [ "$aux" != "" ] ; then   # verifica se a última linha é vazia
				sed  -i '$a\' $HOME/.profile #adiciona uma linha ao fim do arquivo
		fi


		profile_file=$HOME/.bashrc
		flag_profile_paths=0

		if [ -e $profile_file ];then 
			profile_data=$(cat $profile_file)
			case "$profile_data" in 
				*'export PATH=$PATH:$HOME/android/'*)
				flag_profile_paths=1
				#exit 1
				;;
			esac
		fi

		if [ $flag_profile_paths = 0 ] ; then 
			echo 'export PATH=$PATH:$HOME/android/ndk-toolchain' >> $HOME/.bashrc
			echo 'export PATH=$PATH:$HOME/android/gradle-4.1/bin' >> $HOME/.bashrc
		fi

		export PATH=$PATH:$HOME/android/ndk-toolchain
		export PATH=$PATH:$HOME/android/gradle-4.1/bin
		#get fpdlux
		changeDirectory $HOME
		#codigo para obter o crosscompile
		# wget https://github.com/newpascal/fpcupdeluxe/releases/tag/v1.6.1e
		# fpcupdeluxe_lnk=($( cat v1.6.1e  | grep x86 | grep linux | sed "s/<a href=\"//g" | sed "s/\"//g")) # processa o arquivo removendo < a href= e = do arquivo 
		# i=0
		# while [ $i -lt ${#fpcupdeluxe_lnk[*]} ]
		# do
		# 	echo "i=$i=${fpcupdeluxe_lnk[i]}"
		# 	((i++))
		# done
		# cros_lk=$CROSS_COMPILE_URL${fpcupdeluxe_lnk[0]}
		# echo "$cros_lk"
		# wget $cros_lk


		#make manual cross comp+i+l+e+
		changeDirectory $HOME
		mkdir -p $LAMW4LINUX_HOME
		mkdir -p $LAMW4LINUX_HOME/fpcsrc
		changeDirectory $LAMW4LINUX_HOME/fpcsrc
		svn checkout $URL_FPC
		if [ $? != 0 ]; then
			svn checkout $URL_FPC
		fi
		#mv $FPC_RELEASE fpcsrc
		changeDirectory $FPC_RELEASE
		#sudo make clean crossall OS_TARGET=android CPU_TARGET=arm
		#sudo make clean crossall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMEL" CROSSOPT="-CpARMv6 -CfSoft"
		#sudo make crossinstall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMEL" CROSSOPT="-CpARMv6 -CfSoft" INSTALL_PREFIX=/usr
		
		#make install TARGET=linux PREFIX_INSTALL=/usr
		#if [ $flag_new_ubuntu_lts = 0 ]
		#then
			sudo make clean crossall crossinstall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMHF" SUBARCH="armv7a" INSTALL_PREFIX=/usr		
		#else
			# sudo make clean build  install OS_TARGET=linux INSTALL_PREFIX=/usr
			#sudo make clean crossall crossinstall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMHF" SUBARCH="armv7a" INSTALL_PREFIX=/usr
			#sudo cp /tmp/usr/
		#fi

		sudo ln -sf $FPC_LIB_PATH/ppcrossarm /usr/bin/ppcrossarm
		sudo ln -sf /usr/bin/ppcrossarm /usr/bin/ppcarm
		#fi

		#sudo bash -x $0 cfg-fpc $ANDROID_HOME
		#firefox $CROSS_COMPILE_URL
		changeDirectory $ANDROID_HOME
		svn co $LAMW_SRC_LNK
		ln -sf $ANDROID_HOME/lazandroidmodulewizard.git $ANDROID_HOME/lazandroidmodulewizard

		changeDirectory $LAMW4LINUX_HOME
		svn co $LAZARUS_STABLE_SRC_LNK
		ln -sf $LAMW4LINUX_HOME/$LAZARUS_STABLE $LAMW_IDE_HOME  # link to lamw4_home directory 
		ln -sf $LAMW_IDE_HOME/lazarus $LAMW4LINUX_EXE_PATH #link  to lazarus executable
		changeDirectory $LAMW_IDE_HOME
		make clean all

		#build ide 
		for((i=0;i< ${#LAZBUILD_PARAMETERS[@]};i++))
		do
			./lazbuild ${LAZBUILD_PARAMETERS[i]}
			if [ $? != 0 ]; then
				./lazbuild ${LAZBUILD_PARAMETERS[i]}
			fi
		done

		changeDirectory $ANDROID_HOME
		#svn co https://github.com/jmpessoa/lazandroidmodulewizard.git
		#ln -sf $ANDROID_HOME/lazandroidmodulewizard.git $ANDROID_HOME/lazandroidmodulewizard
		if [ ! -e ~/.local/share/applications ] ; then
			mkdir ~/.local/share/applications
		fi
		echo "[Desktop Entry]" > $LAMW_MENU_ITEM_PATH
		echo "Name=LAMW4Linux" >>  $LAMW_MENU_ITEM_PATH
		echo "Exec=$LAMW4LINUX_EXE_PATH --primary-config-path=$LAMW4_LINUX_PATH_CFG" >>$LAMW_MENU_ITEM_PATH
		echo "Icon=$LAMW_IDE_HOME/images/icons/lazarus_orange.ico" >>$LAMW_MENU_ITEM_PATH
		echo "Type=Application" >> $LAMW_MENU_ITEM_PATH
		echo "Categories=Development;IDE;" >> $LAMW_MENU_ITEM_PATH
		chmod +x $LAMW_MENU_ITEM_PATH
		LAMW4LinuxPostConfig
		sudo printf 'SUBSYSTEM=="usb", ATTR{idVendor}=="<VENDOR>", MODE="0666", GROUP="plugdev"\n'  | sudo tee /etc/udev/rules.d/51-android.rules
		sudo service udev restart
		update-menus
		lamw_log_str=("Info:\nLAMW4Linux:$LAMW4LINUX_HOME\nLAMW workspace:"  "$HOME/Dev/lamw_workspace\nAndroid SDK:$ANDROID_HOME/sdk\n" "Android NDK:$ANDROID_HOME/ndk\nGradle:$GRADLE_HOME\n")
		for((i=0; i<${#lamw_log_str[*]};i++)) 
		do
			if [ $i = 0 ] ; then 
				printf "${lamw_log_str[i]}" > $LAMW4LINUX_HOME/lamw-install.log
			else
				printf "${lamw_log_str[i]}" >> $LAMW4LINUX_HOME/lamw-install.log
			fi
		done
		zenity --info --text "Info:\nLAMW4Linux:$LAMW4LINUX_HOME\nLAMW workspace : $HOME/Dev/lamw_workspace\nAndroid SDK:$ANDROID_HOME/sdk\nAndroid NDK:$ANDROID_HOME/ndk\nGradle:$GRADLE_HOME\nLOG:$LAMW4LINUX_HOME/lamw-install.log"


}
echo "----------------------------------------------------------------------"
printf "${LAMW_INSTALL_WELCOME[*]}"
echo "----------------------------------------------------------------------"
echo "Warning: Earlier versions of FPC and Lazarus (debian package) will be removed!
LAMW-Install (Linux supported Debian 9, Ubuntu 16.04 LTS, Linux Mint 18)
Generate LAMW4Linux to  android-sdk=$SDK_VERSION"

case "$1" in

	"clean")
		CleanOldConfig
	;;
	"install")
		mainInstall $2	
	;;

	"clean-install")
		CleanOldConfig
		mainInstall $2
	;;
		# "cfg-fpc")
	# 	if [ "$(whoami)" = "root" ]
	# 	then
	# 		echo "executando em mode root"
	# 		configureFPC $2
	# 	fi
	# ;;
	*)
		printf "Use:\n\tbash lamw-install.sh clean\n\tbash lamw-install.sh install\n\tbash lamw-install.sh install --use_proxy\n\tbash lamw-install.sh clean-install\n\tbash lamw-install.sh clean-install --use_proxy\n"
	;;
	
esac
