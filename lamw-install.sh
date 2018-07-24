
#!/bin/bash
#Universidade federal de Mato Grosso
#Curso ciencia da computação
#AUTOR: Daniel Oliveira Souza <oliveira.daniel@gmail.com>
#Versao PST: 0.0.3
#Descrição: Este script configura o ambiente de desenvolvimento para o LAMW

pwd 
export DEBIAN_FRONTEND="gnome"
APT_OPT=""
PROXY_SERVER="internet.cua.ufmt.br"
PORT_SERVER=3128
PROXY_URL="http://$PROXY_SERVER:$PORT_SERVER"
USE_PROXY=0
SDK_MANAGER_CMD_PARAMETERS=()
CROSS_COMPILE_URL="https://github.com/newpascal/fpcupdeluxe/releases/tag/v1.6.1e"
export URL_FPC=""
export FPC_VERSION=""
export FPC_CFG_PATH=""
export FPC_RELEASE=""
export flag_new_ubuntu_lts=0
#echo "arq=$0"
sleep 3

export FPC_VERSION=""

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


LAZANDROID_HOME=$HOME/LazarusAndroid
ANDROID_HOME="$HOME/android"
ANDROID_SDK="$ANDROID_HOME/sdk"
FPC_STABLE=""
LAZARUS_STABLE=""
export FPC_LIB_PATH=""
libs_android="libx11-dev libgtk2.0-dev libgdk-pixbuf2.0-dev libcairo2-dev libpango1.0-dev libxtst-dev libatk1.0-dev libghc-x11-dev freeglut3 freeglut3-dev "
prog_tools=" git subversion make build-essential zip unzip unrar android-tools-adb ant openjdk-8-jdk "
packs=()


SearchPackage(){
	index=0
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
					export FPC_LIB_PATH="/usr/lib/x86_64-linux-gnu/fpc/$FPC_VERSION"
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
	fpc_cfg_str=(
			"#IFDEF ANDROID"
			"#IFDEF CPUARM"
			"-XParm-linux-androideabi-"
			"-Fl$ANDROID_HOME/ndk/platforms/android-21/arch-arm/usr/lib"
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
				echo ${fpc_cfg_str[i]}
				echo "${fpc_cfg_str[i]}" >> $FPC_CFG_PATH
			done	
		fi
	fi
}

case "$1" in
	"cfg-fpc")
		if [ "$(whoami)" = "root" ]
		then
			echo "executando em mode root"
			configureFPC $2
		fi
	;;
	"clean")
	sudo rm $LAZANDROID_HOME -r
	sudo rm $ANDROID_HOME  -r
	sudo rm /usr/src/fpcsrc -r
	;;
	"install")
			if [ "$2" = "--use_proxy" ] ;then
				USE_PROXY=1
			fi

			if [ $USE_PROXY = 1 ]; then
			SDK_MANAGER_CMD_PARAMETERS=("platforms;android-25" "build-tools;25.0.3" "tools" "ndk-bundle" "extras;android;m2repository" --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
			export http_proxy=$PROXY_URL
			export https_proxy=$PROXY_URL
		#	ActiveProxy 1
		else
			SDK_MANAGER_CMD_PARAMETERS=("platforms;android-25" "build-tools;25.0.3" "tools" "ndk-bundle" "extras;android;m2repository")
			#ActiveProxy 0
		fi
			sudo apt update;

		SearchPackage fpc
		index=$?
		parseFPC ${packs[$index]}
		fpc_cfg_str=(
			"#IFDEF ANDROID"
			"#IFDEF CPUARM"
			"-XParm-linux-androideabi-"
			"-Fl$ANDROID_HOME/ndk/platforms/android-21/arch-arm/usr/lib"
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
				echo ${fpc_cfg_str[i]}
				sudo echo "${fpc_cfg_str[i]}" | sudo tee -a  $FPC_CFG_PATH
			done	
		fi
	fi


		sudo apt install $libs_android $prog_tools  -y --allow-unauthenticated
		if [ "$?" != "0" ]; then
			sudo apt install $libs_android $prog_tools  -y --allow-unauthenticated --fix-missing
		fi
		if [ $USE_PROXY = 1 ] ; then
			ActiveProxy 1
		else
			ActiveProxy 0
		fi
		mkdir -p $ANDROID_SDK

		changeDirectory $ANDROID_HOME
		wget "https://services.gradle.org/distributions/gradle-4.1-bin.zip"
		unzip "gradle-4.1-bin.zip"
		rm "gradle-4.1-bin.zip"
		changeDirectory $ANDROID_SDK
		#echo "pwd=$PWD"
		#ls -la 
		wget "https://dl.google.com/android/repository/sdk-tools-linux-3859397.zip" #getting sdk 
		unzip sdk-tools-linux-3859397.zip
		rm sdk-tools-linux-3859397.zip

		changeDirectory $ANDROID_SDK/tools/bin #change directory
		#Install SDK packages and NDK
		#./sdkmanager "platforms;android-25" "build-tools;25.0.3" "tools" "ndk-bundle" "extras;android;m2repository"
		#$SDK_MANAGER_CMD
		ls
		sudo apt-get remove --purge openjdk-9-* -y 
		sudo apt-get remove --purge openjdk-11* -y
		./sdkmanager ${SDK_MANAGER_CMD_PARAMETERS[*]}

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


		profile_file=$HOME/.profile
		flag_profile_paths=0

		if [ -e $profile_file ];then 
			profile_data=$(cat $profile_file)
			case "$profile_data" in 
				*'export PATH=$PATH:$HOME/android/'*)
				flag_profile_paths=1ndk-bundle
				#exit 1
				;;
			esac
		fi

		if [ $flag_profile_paths = 0 ] ; then 
			echo 'export PATH=$PATH:$HOME/android/ndk-toolchain' >> $HOME/.profile
			echo 'export PATH=$PATH:$HOME/android/gradle-4.1/bin' >> $HOME/.profile
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
		changeDirectory /usr/src
		sudo svn checkout $URL_FPC
		sudo mv $FPC_RELEASE fpcsrc
		changeDirectory fpcsrc
		#sudo make clean crossall OS_TARGET=android CPU_TARGET=arm
		#sudo make clean crossall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMEL" CROSSOPT="-CpARMv6 -CfSoft"
		#sudo make crossinstall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMEL" CROSSOPT="-CpARMv6 -CfSoft" INSTALL_PREFIX=/usr
		
		#make install TARGET=linux PREFIX_INSTALL=/usr
		if [ $flag_new_ubuntu_lts = 0 ]
		then
			sudo make clean crossall crossinstall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMHF" SUBARCH="armv7a" INSTALL_PREFIX=/usr		
		else
			# sudo make clean build  install OS_TARGET=linux INSTALL_PREFIX=/usr
			sudo make clean crossall crossinstall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMHF" SUBARCH="armv7a" INSTALL_PREFIX=/tmp/usr
			sudo cp /tmp/usr/
		fi

		sudo ln -sf $FPC_LIB_PATH/ppcrossarm /usr/bin/ppcrossarm
		sudo ln -sf /usr/bin/ppcrossarm /usr/bin/ppcarm
		#fi

		#sudo bash -x $0 cfg-fpc $ANDROID_HOME
		#firefox $CROSS_COMPILE_URL
		changeDirectory $HOME
		mkdir -p LazarusAndroid
		changeDirectory $LAZANDROID_HOME
		svn co https://svn.freepascal.org/svn/lazarus/tags/lazarus_1_8_4
		ln -sf $LAZANDROID_HOME/lazarus_1_8_4 $HOME/LazarusAndroid/lazarus
		changeDirectory $HOME/LazarusAndroid/lazarus
		make clean all
		changeDirectory $ANDROID_HOME
		svn co https://github.com/jmpessoa/lazandroidmodulewizard.git
		ln -sf $ANDROID_HOME/lazandroidmodulewizard.git $ANDROID_HOME/lazandroidmodulewizard
		if [ ! -e ~/.local/share/applications ] ; then
			mkdir ~/.local/share/applications
		fi
		echo "[Desktop Entry]" > ~/.local/share/applications/laz4android.desktop
		echo "Name=laz4android" >>  ~/.local/share/applications/laz4android.desktop
		echo "Exec=$HOME/LazarusAndroid/lazarus/lazarus --primary-config-path=$HOME/.laz4android" >> ~/.local/share/applications/laz4android.desktop
		echo "Icon=$HOME/LazarusAndroid/lazarus_1_8_4/images/icons/lazarus_orange.ico" >> ~/.local/share/applications/laz4android.desktop
		echo "Type=Application" >> ~/.local/share/applications/laz4android.desktop
		echo "Categories=Development;IDE;" >> ~/.local/share/applications/laz4android.desktop
		chmod +x ~/.local/share/applications/laz4android.desktop
		sudo printf 'SUBSYSTEM=="usb", ATTR{idVendor}=="<VENDOR>", MODE="0666", GROUP="plugdev"\n'  | sudo tee /etc/udev/rules.d/51-android.rules
	;;
	*)
		printf "Use:\n\tbash lamw-install.sh clean\n\tbash lamw-install.sh install\n\tbash lamw-install.sh install --use_proxy\n"
	;;
	
esac
