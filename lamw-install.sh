
#!/bin/bash
#Universidade federal de Mato Grosso
#Curso ciencia da computação
#AUTOR: Daniel Oliveira Souza <oliveira.daniel@gmail.com>
#Versao LAMW-INSTALL: 0.2.0
#Descrição: Este script configura o ambiente de desenvolvimento para o LAMW


LAMW_INSTALL_VERSION="0.2.0"
LAMW_INSTALL_WELCOME=(
	"\t\tWelcome LAMW4Linux Installer  version: $LAMW_INSTALL_VERSION\n"
	"\t\tPowerd by DanielTimelord\n"
	"\t\t<oliveira.daniel109@gmail.com>\n"
)

export DEBIAN_FRONTEND="gnome"
export URL_FPC=""
export FPC_VERSION=""
export FPC_CFG_PATH="$HOME/.fpc.cfg"
export PPC_CONFIG_PATH=$FPC_CFG_PATH
export FPC_RELEASE=""
export flag_new_ubuntu_lts=0
export FPC_LIB_PATH=""
export FPC_VERSION=""
export FPC_MKCFG_EXE=""
work_home_desktop=$(xdg-user-dir DESKTOP)
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
LAMW4LINUX_HOME="$HOME/lamw4linux"
LAMW_IDE_HOME="$LAMW4LINUX_HOME/lamw4linux" # path to link-simbolic to ide 
LAMW_WORKSPACE_HOME="$HOME/Dev/LAMWProjects"  #path to lamw_workspace
LAMW4LINUX_EXE_PATH="$LAMW_IDE_HOME/lamw4linux"
LAMW_MENU_ITEM_PATH="$HOME/.local/share/applications/lamw4linux.desktop"
GRADLE_HOME="$ANDROID_HOME/gradle-4.4.1"

GRADLE_CFG_HOME="$HOME/.gradle"
GRADE_ZIP_LNK="https://services.gradle.org/distributions/gradle-4.4.1-bin.zip"
GRADE_ZIP_FILE="gradle-4.4.1-bin.zip"
FPC_STABLE=""
LAZARUS_STABLE="lazarus_1_8_4"

FPC_ID_DEFAULT=0
FPC_CROSS_ARM_DEFAULT_PARAMETERS=('clean crossall crossinstall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMHF" SUBARCH="armv7a" INSTALL_PREFIX=/usr')
FPC_CROSS_ARM_MODE_FPCDELUXE=(clean crossall crossinstall  CPU_TARGET=arm OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=/usr)
LAZBUILD_PARAMETERS=(
	"--build-ide= --add-package $ANDROID_HOME/lazandroidmodulewizard/trunk/android_bridges/tfpandroidbridge_pack.lpk --primary-config-path=$LAMW4_LINUX_PATH_CFG  --lazarusdir=$LAMW_IDE_HOME"
	"--build-ide= --add-package $ANDROID_HOME/lazandroidmodulewizard/trunk/android_wizard/lazandroidwizardpack.lpk --primary-config-path=$LAMW4_LINUX_PATH_CFG --lazarusdir=$LAMW_IDE_HOME"
	"--build-ide= --add-package $ANDROID_HOME/lazandroidmodulewizard/trunk/ide_tools/amw_ide_tools.lpk --primary-config-path=$LAMW4_LINUX_PATH_CFG --lazarusdir=$LAMW_IDE_HOME"
)

#REGEX VARIABLES

WR_GRADLE_HOME=""
WR_ANDROID_HOME=""
HOME_USER_SPLITTED_ARRAY=(${HOME//\// })
HOME_STR_SPLITTED=""
libs_android="libx11-dev libgtk2.0-dev libgdk-pixbuf2.0-dev libcairo2-dev libpango1.0-dev libxtst-dev libatk1.0-dev libghc-x11-dev freeglut3 freeglut3-dev "
prog_tools="menu fpc git subversion make build-essential zip unzip unrar android-tools-adb ant openjdk-8-jdk "
packs=()
#[[]

# searchLineinFile(FILE *fp, char * str )
#$1 is File Path
#$2 is a String to search 
#this function return 0 if not found or 1  if found
searchLineinFile(){
	flag=0
	if [ "$1" != "" ]
	then
		if [ -e "$1" ]
		then
			if [ "$2" != "" ]
			then
				line="NULL"
				#file=$1
				while read line # read a line from
				do
					if [ "$line" = "$2" ] # if current line is equal $2
					then
						flag=1
						break #break loop 
					fi
				done < "$1"
			fi
		fi
	fi
	return $flag # return value 
}
#args $1 is str
#args $2 is delimeter token 
#call this function output=($(SplitStr $str $delimiter))
splitStr(){
	str=""
	token=""
	str_spl=()
	if [ "$1" != "" ] && [ "$2" != "" ] ; then 
		str="$1"
		delimeter=$2
		case "$delimeter" in 
			"/")
			str_spl=(${str//\// })
			echo "${str_spl[@]}"
			;;
			*)
				#if [ $(echo $str | grep [a-zA-Z0-9;]) = 0 ] ; then  # if str  regex alphanumeric
					str_spl=(${str//$delimeter/ })
					echo "${str_spl[@]}"
				#fi
			;;
		esac
	fi
}
GenerateScapesStr(){
	tam=${#HOME_USER_SPLITTED_ARRAY[@]}
	str_scapes=""
	#echo "tam=$tam"
	if [ "$1" = "" ] ; then
		for ((i=0;i<tam;i++))
		do
			HOME_STR_SPLITTED=$HOME_STR_SPLITTED"\/"${HOME_USER_SPLITTED_ARRAY[i]}
		#echo ${HOME_USER_SPLITTED_ARRAY[i]}
		done
	else
		echo $1
		#str_scapes=""
		str_array=($(splitStr "$1" "/"))
		#echo ${str_array[@]}
		tam=${#str_array[@]}
		for ((i=0;i<tam;i++))
		do
			str_scapes=$str_scapes"\/"${str_array[i]}
		done
		echo "$str_scapes"
	fi
}

#unistall java not supported
unistallJavaUnsupported(){
	if [ $flag_new_ubuntu_lts = 1 ]
	then
		sudo apt-get remove --purge openjdk-9-* -y 
		sudo apt-get remove --purge openjdk-11* -y
	fi
}
#install deps
installDependences(){
	sudo apt-get update;
	sudo apt-get remove --purge  lazarus* -y
	sudo apt-get autoremove --purge -y
			#sudo apt-get install fpc
	sudo apt-get install $libs_android $prog_tools  -y --allow-unauthenticated
	if [ "$?" != "0" ]; then
		sudo apt-get install $libs_android $prog_tools  -y --allow-unauthenticated --fix-missing
	fi
}

#iniciandoparametros
initParameters(){
	if [ "$1" = "--use_proxy" ] ;then
				USE_PROXY=1
	fi

	if [ $USE_PROXY = 1 ]; then
		SDK_MANAGER_CMD_PARAMETERS=("platforms;android-21" "build-tools;21.1.2" "platforms;android-24" "build-tools;24.0.3" "platforms;android-25"  "build-tools;25.0.3" "build-tools;26.0.2" "tools" "ndk-bundle" "extras;android;m2repository" --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
		SDK_LICENSES_PARAMETERS=( --licenses --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
		export http_proxy=$PROXY_URL
		export https_proxy=$PROXY_URL
#	ActiveProxy 1
	else
		SDK_MANAGER_CMD_PARAMETERS=("platforms;android-21" "build-tools;21.1.2" "platforms;android-24" "build-tools;24.0.3" "platforms;android-25" "platforms;android-26" "build-tools;25.0.3"  "build-tools;26.0.2" "tools" "ndk-bundle" "extras;android;m2repository")			#ActiveProxy 0
		SDK_LICENSES_PARAMETERS=(--licenses )
	fi
}
#Get FPC Sources
getFPCSources(){
	changeDirectory $HOME
	mkdir -p $LAMW4LINUX_HOME/fpcsrc
	changeDirectory $LAMW4LINUX_HOME/fpcsrc
	svn checkout $URL_FPC
	if [ $? != 0 ]; then
		#sudo rm $FPC_RELEASE/.svn -r
		sudo rm -r $FPC_RELEASE
		svn checkout $URL_FPC
		if [ $? != 0 ]; then 
			sudo rm -r $FPC_RELEASE
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
}
#get Lazarus Sources
getLazarusSources(){
	changeDirectory $LAMW4LINUX_HOME
	svn co $LAZARUS_STABLE_SRC_LNK
	if [ $? != 0 ]; then  #case fails last command , try svn chekout 
		sudo rm -r $LAZARUS_STABLE
		#svn cleanup
		#changeDirectory $LAMW4LINUX_HOME
		svn co $LAZARUS_STABLE_SRC_LNK
		if [ $? != 0 ]; then 
			sudo rm -r $LAZARUS_STABLE
			echo "possible network instability! Try later!"
			exit 1
		fi
		#svn revert -R  $LAMW_SRC_LNK
	fi
}

#GET LAMW FrameWork

getLAMWFramework(){
	changeDirectory $ANDROID_HOME
	svn co $LAMW_SRC_LNK
	if [ $? != 0 ]; then #case fails last command , try svn chekout
		sudo rm -r lazandroidmodulewizard.git
		svn co $LAMW_SRC_LNK
		if [ $? != 0 ]; then 
			sudo rm -r lazandroidmodulewizard.git
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
	ln -sf $ANDROID_HOME/lazandroidmodulewizard.git $ANDROID_HOME/lazandroidmodulewizard
}

#Get Gradle and SDK Tools 
getAndroidSDKTools(){
	changeDirectory $HOME
	mkdir -p $ANDROID_SDK

	changeDirectory $ANDROID_HOME
	if [ ! -e $GRADLE_HOME ]; then
		wget -c $GRADE_ZIP_LNK
		if [ $? != 0 ] ; then
			#rm *.zip*
			wget -c $GRADE_ZIP_LNK
		fi
		unzip $GRADE_ZIP_FILE
	fi
	
	if [ -e  $GRADE_ZIP_FILE ]; then
		rm $GRADE_ZIP_FILE
	fi
	changeDirectory $ANDROID_SDK
	
	if [ ! -e tools ] ; then
		wget -c $SDK_TOOLS_URL #getting sdk 
		if [ $? != 0 ]; then 
			wget -c $SDK_TOOLS_URL
		fi
		unzip sdk-tools-linux-3859397.zip
	fi

}

getSDKAndroid(){
	changeDirectory $ANDROID_SDK/tools/bin #change directory
	yes | ./sdkmanager ${SDK_LICENSES_PARAMETERS[*]}
	if [ $? != 0 ]; then 
		yes | ./sdkmanager ${SDK_LICENSES_PARAMETERS[*]}
	fi
	./sdkmanager ${SDK_MANAGER_CMD_PARAMETERS[*]}  # instala sdk sem intervenção humana  

	if [ $? != 0 ]; then 
		./sdkmanager ${SDK_MANAGER_CMD_PARAMETERS[*]}
	fi

}
#Create SDK simbolic links

CreateSDKSimbolicLinks(){
	ln -sf "$ANDROID_HOME/sdk/ndk-bundle" "$ANDROID_HOME/ndk"
	ln -sf "$ANDROID_HOME/ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin" "$ANDROID_HOME/ndk-toolchain"
	ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-androideabi-as" "$ANDROID_HOME/ndk-toolchain/arm-linux-as"
	ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-androideabi-ld" "$ANDROID_HOME/ndk-toolchain/arm-linux-ld"

	sudo ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-androideabi-as" "/usr/bin/arm-linux-androideabi-as"
	sudo ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-ld"  "/usr/bin/arm-linux-androideabi-ld"
	sudo ln -sf $FPC_LIB_PATH/ppcrossarm /usr/bin/ppcrossarm
	sudo ln -sf /usr/bin/ppcrossarm /usr/bin/ppcarm
}

#Addd sdk to .bashrc and .profile

AddSDKPathstoProfile(){
	aux=$(tail -1 $HOME/.profile)       #tail -1 mostra a última linha do arquivo 
	if [ "$aux" != "" ] ; then   # verifica se a última linha é vazia
			sed  -i '$a\' $HOME/.profile #adiciona uma linha ao fim do arquivo
	fi


	profile_file=$HOME/.bashrc
	flag_profile_paths=0
	profile_line_path='export PATH=$PATH:$GRADLE_HOME/1-bin'
#	if [ -e $profile_file ];then 
	#	profile_data=$(cat $profile_file)
		#case "$profile_data" in 
		#	*'export PATH=$PATH:$GRADLE_HOME'*)
		#	flag_profile_paths=1
			#exit 1
		#	;;
		#esac
	#fi
	searchLineinFile "$profile_file" "$profile_line_path"
	flag_profile_paths=$?
	if [ $flag_profile_paths = 0 ] ; then 
		#echo 'export PATH=$PATH'"\":$ANDROID_HOME/ndk-toolchain\"" >> $HOME/.bashrc
		#echo 'export PATH=$PATH'"\":$GRADLE_HOME/bin\"" >> $HOME/.bashrc
		echo "export ANDROID_HOME=$ANDROID_HOME" >>  $HOME/.bashrc
		echo "export GRADLE_HOME=$GRADLE_HOME" >> $HOME/.bashrc
		echo 'export PATH=$PATH:$ANDROID_HOME/ndk-toolchain' >> $HOME/.bashrc
		echo 'export PATH=$PATH:$GRADLE_HOME/bin' >> $HOME/.bashrc
	fi

	export PATH=$PATH:$ANDROID_HOME/ndk-toolchain
	export PATH=$PATH:$GRADLE_HOME/bin
}
#to build
BuildCrossArm(){
	if [ "$1" != "" ]; then #
		changeDirectory $LAMW4LINUX_HOME/fpcsrc 
		changeDirectory $FPC_RELEASE
		case $1 in 
			0 )
				sudo make clean 
				sudo make crossall crossinstall  CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=/usr
			;;

		esac
	fi				
}

#Build lazarus ide

BuildLazarusIDE(){
	ln -sf $LAMW4LINUX_HOME/$LAZARUS_STABLE $LAMW_IDE_HOME  # link to lamw4_home directory 
	ln -sf $LAMW_IDE_HOME/lazarus $LAMW4LINUX_EXE_PATH #link  to lazarus executable
	changeDirectory $LAMW_IDE_HOME
	make clean all
		#build ide  with lamw framework 
	for((i=0;i< ${#LAZBUILD_PARAMETERS[@]};i++))
	do
		./lazbuild ${LAZBUILD_PARAMETERS[i]}
		if [ $? != 0 ]; then
			./lazbuild ${LAZBUILD_PARAMETERS[i]}
		fi
	done
}
#this  fuction create a INI file to config  all paths used in lamw framework 
LAMW4LinuxPostConfig(){
	old_lamw_workspace="$HOME/Dev/lamw_workspace"
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
		"InstructionSet=2"
		"AntPackageName=org.lamw"
		"AndroidPlatform=0"
		"AntBuildMode=debug"
		"NDK=5"
	)
	for ((i=0;i<${#LAMW_init_str[@]};i++))
	do
		if [ $i = 0 ]; then 
			echo "${LAMW_init_str[i]}" > $LAMW4_LINUX_PATH_CFG/JNIAndroidProject.ini 
		else
			echo "${LAMW_init_str[i]}" >> $LAMW4_LINUX_PATH_CFG/JNIAndroidProject.ini
		fi
	done
	AddLAMWtoStartMenu
}
#Add LAMW4Linux to menu 
AddLAMWtoStartMenu(){
	if [ ! -e ~/.local/share/applications ] ; then #create a directory of local apps launcher, if not exists 
		mkdir -p ~/.local/share/applications
	fi

	echo "[Desktop Entry]" > $LAMW_MENU_ITEM_PATH
	echo "Name=LAMW4Linux" >>  $LAMW_MENU_ITEM_PATH
	echo "Exec=$LAMW4LINUX_EXE_PATH --primary-config-path=$LAMW4_LINUX_PATH_CFG" >>$LAMW_MENU_ITEM_PATH
	echo "Icon=$LAMW_IDE_HOME/images/icons/lazarus_orange.ico" >>$LAMW_MENU_ITEM_PATH
	echo "Type=Application" >> $LAMW_MENU_ITEM_PATH
	echo "Categories=Development;IDE;" >> $LAMW_MENU_ITEM_PATH
	chmod +x $LAMW_MENU_ITEM_PATH
	cp $LAMW_MENU_ITEM_PATH "$work_home_desktop"
	#LAMW4LinuxPostConfig
	#add support the usb debug  on linux for anywhere android device 
	
	update-menus
}
#cd not a native command, is a systemcall used to exec, read more in exec man 
changeDirectory(){
	if [ "$1" != "" ] ; then
		if [ -e $1  ]; then
			cd $1
		fi
	fi 
}
#this code add support a proxy 
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
	if [ -e $FPC_LIB_PATH/ppcrossarm ]; then
		sudo rm $FPC_LIB_PATH/ppcrossarm
	fi
	
	if [ -e /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android ]; then
		sudo rm -r /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android
	fi
	if [ -e /usr/lib/fpc/$FPC_VERSION/units/arm-android ]; then
		sudo rm -r /usr/lib/fpc/$FPC_VERSION/units/arm-android
	fi
}

cleanPATHS(){
	sed -i "/export ANDROID_HOME=*/d"  $HOME/.bashrc
	sed -i "/export GRADLE_HOME=*/d" $HOME/.bashrc
	sed -i '/export PATH=$PATH:$HOME\/android\/ndk-toolchain/d'  $HOME/.bashrc #\/ is scape of /
	sed -i '/export PATH=$PATH:$HOME\/android\/gradle-4.1\/bin/d' $HOME/.bashrc
	sed -i '/export PATH=$PATH:$HOME\/android\/ndk-toolchain/d'  $HOME/.profile
	sed -i '/export PATH=$PATH:$HOME\/android\/gradle-4.1\/bin/d' $HOME/.profile	
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/ndk-toolchain/d'  $HOME/.bashrc
	sed -i '/export PATH=$PATH:$GRADLE_HOME/d'  $HOME/.bashrc
}
#this function remove old config of lamw4linux  
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
	if [ -e /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android ]; then
		sudo rm -r /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android
	fi


	if [ -e /usr/bin/arm-linux-androideabi-as ]; then
		sudo rm /usr/bin/arm-linux-androideabi-as
	fi
	if [ -e /usr/bin/arm-linux-ld ] ; then 
		sudo rm /usr/bin/arm-linux-ld
	fi

	if [ -e $FPC_CFG_PATH ]; then #remove local ppc config
		rm $FPC_CFG_PATH
	fi
	if [ -e "$work_home_desktop/lamw4linux.desktop" ]; then
		rm "$work_home_desktop/lamw4linux.desktop"
	fi
	cleanPATHS
	# sed -i '/export PATH=$PATH:$HOME\/android\/ndk-toolchain/d'  $HOME/.bashrc #\/ is scape of /
	# sed -i '/export PATH=$PATH:$HOME\/android\/gradle-4.1\/bin/d' $HOME/.bashrc
	# sed -i '/export PATH=$PATH:$HOME\/android\/ndk-toolchain/d'  $HOME/.profile
	# sed -i '/export PATH=$PATH:$HOME\/android\/gradle-4.1\/bin/d' $HOME/.profile		
}


#this function returns a version fpc 
SearchPackage(){
	index=-1
	#vetor que armazena informações sobre a intalação do pacote
	if [ "$1" != "" ]  ; then
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
			#export FPC_CFG_PATH="/etc/fpc-3.0.0.cfg"
			export FPC_RELEASE="release_3_0_0"
			export FPC_VERSION="3.0.0"
			export FPC_LIB_PATH="/usr/lib/fpc/$FPC_VERSION"
		;;
		*"3.0.4"*)
			export URL_FPC="https://svn.freepascal.org/svn/fpc/tags/release_3_0_4"
			export FPC_RELEASE="release_3_0_4"
			export FPC_VERSION="3.0.4"
			
			#export FPC_CFG_PATH="/etc/fpc-3.0.4.cfg"
			#if [ $flag_new_ubuntu_lts = 0 ] ; then
			#	if [ -e /usr/lib/fpc/$FPC_VERSION ]; then
			#	#	export FPC_LIB_PATH="/usr/lib/fpc/$FPC_VERSION"
				#fi

			#else
			
			if [ -e /usr/lib/x86_64-linux-gnu/fpc/$FPC_VERSION ]; then #case new location fpc directory 
				if [   -e /usr/lib/fpc  ]; then #para estar versão do fpc, obrigatóriamente /usr/lib/fpc dever ser um link simbólico
					 sudo rm -r /usr/lib/fpc
				fi
				sudo ln -s /usr/lib/x86_64-linux-gnu/fpc /usr/lib/fpc
				export FPC_LIB_PATH="/usr/lib/fpc/$FPC_VERSION"
			else
				if [ -e /usr/lib/fpc/$FPC_VERSION ]; then
					export FPC_LIB_PATH="/usr/lib/fpc/$FPC_VERSION"
				fi
			fi

		
		;;
	esac
	export FPC_MKCFG_EXE=$(which fpcmkcfg-$FPC_VERSION)
	if [ "$FPC_MKCFG_EXE" = "" ]; then
		export FPC_MKCFG_EXE=$(which x86_64-linux-gnu-fpcmkcfg-$FPC_VERSION)
	fi
}

enableADBtoUdev(){
	 sudo printf 'SUBSYSTEM=="usb", ATTR{idVendor}=="<VENDOR>", MODE="0666", GROUP="plugdev"\n'  | sudo tee /etc/udev/rules.d/51-android.rules
	 sudo service udev restart
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
		if [ ! -e $FPC_CFG_PATH ]; then
			$FPC_MKCFG_EXE -d basepath=/usr/lib/fpc/$FPC_VERSION -o $FPC_CFG_PATH
		fi

		#this config enable to crosscompile in fpc 
		fpc_cfg_str=(
			"#IFDEF ANDROID"
			"#IFDEF CPUARM"
			"-CpARMV7A"
			"-CfVFPV3"
			"-Xd"
			"-XParm-linux-androideabi-"
			"-Fl$ANDROID_HOME/ndk/platforms/android-$SDK_VERSION/arch-arm/usr/lib"
			"-FLlibdl.so"
			"-FD$ANDROID_HOME/ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin"
			'-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget'
			'-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget/*'
			'-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget/rtl'
			"#ENDIF"
			"#ENDIF"
		)

		if [ -e $FPC_CFG_PATH ] ; then  # se exiir /etc/fpc.cfg
			#fpc_cfg_teste=$(cat $FPC_CFG_PATH) # abre /etc/fpc.cfg
			#flag_fpc_cfg=0 # flag da sub string de configuração"
			#case "$fpc_cfg_teste" in 
			#	*"#IFDEF ANDROID"*)
			#	flag_fpc_cfg=1
			#	;;
			#esac
			searchLineinFile $FPC_CFG_PATH  "${fpc_cfg_str[0]}"
			flag_fpc_cfg=$?

			if [ $flag_fpc_cfg != 1 ]; then # caso o arquvo ainda não esteja configurado
				for ((i = 0 ; i<${#fpc_cfg_str[@]};i++)) 
				do
					#echo ${fpc_cfg_str[i]}
					echo "${fpc_cfg_str[i]}" | tee -a  $FPC_CFG_PATH
				done	
			fi
		fi
}

#write log lamw install 
writeLAMWLogInstall(){
	lamw_log_str=("Generate $LAMW_INSTALL_VERSION" "Info:\nLAMW4Linux:$LAMW4LINUX_HOME\nLAMW workspace:"  "$LAMW_WORKSPACE_HOME\nAndroid SDK:$ANDROID_HOME/sdk\n" "Android NDK:$ANDROID_HOME/ndk\nGradle:$GRADLE_HOME\n")
	NOTIFY_SEND_EXE=$(which notify-send)
	for((i=0; i<${#lamw_log_str[*]};i++)) 
	do
		if [ $i = 0 ] ; then 
			printf "${lamw_log_str[i]}" > $LAMW4LINUX_HOME/lamw-install.log
		else
			printf "${lamw_log_str[i]}" >> $LAMW4LINUX_HOME/lamw-install.log
		fi
	done
	if [ "$NOTIFY_SEND_EXE" != "" ]; then
		$NOTIFY_SEND_EXE  "Info:\nLAMW4Linux:$LAMW4LINUX_HOME\nLAMW workspace : $LAMW_WORKSPACE_HOME\nAndroid SDK:$ANDROID_HOME/sdk\nAndroid NDK:$ANDROID_HOME/ndk\nGradle:$GRADLE_HOME\nLOG:$LAMW4LINUX_HOME/lamw-install.log"
	else
		printf "Info:\nLAMW4Linux:$LAMW4LINUX_HOME\nLAMW workspace : $HOME/Dev/lamw_workspace\nAndroid SDK:$ANDROID_HOME/sdk\nAndroid NDK:$ANDROID_HOME/ndk\nGradle:$GRADLE_HOME\nLOG:$LAMW4LINUX_HOME/lamw-install.log"
	fi		

}
checkProxyStatus(){
	if [ $USE_PROXY = 1 ] ; then
		ActiveProxy 1
	else
		ActiveProxy 0
	fi
}
mainInstall(){

	installDependences
	checkProxyStatus
	configureFPC
	getAndroidSDKTools
	changeDirectory $ANDROID_SDK/tools/bin #change directory
	unistallJavaUnsupported
	getSDKAndroid
	getFPCSources
	getLAMWFramework
	getLazarusSources
	CreateSDKSimbolicLinks
	AddSDKPathstoProfile
	changeDirectory $HOME
	CleanOldCrossCompileBins
	changeDirectory $FPC_RELEASE
	BuildCrossArm $FPC_ID_DEFAULT
	BuildLazarusIDE
	changeDirectory $ANDROID_HOME
	LAMW4LinuxPostConfig
	enableADBtoUdev
	writeLAMWLogInstall
}

if  [  "$(whoami)" = "root" ] #impede que o script seja executado pelo root 
then
	echo "Error: this version  of LAMW4Linux was designed  to run without root priveleges" >&2 # >&2 is a file descriptor to /dev/stderror
	echo "Exiting ..."
	exit 1
fi
	echo "----------------------------------------------------------------------"
	printf "${LAMW_INSTALL_WELCOME[*]}"
	echo "----------------------------------------------------------------------"
	echo "Warning: Earlier versions of Lazarus (debian package) will be removed!
	LAMW-Install (Linux supported Debian 9, Ubuntu 16.04 LTS, Linux Mint 18)
	Generate LAMW4Linux to  android-sdk=$SDK_VERSION"

	#configure parameters sdk before init download and build
	initParameters $2
	GenerateScapesStr
	

#Parameters are useful for understanding script operation
case "$1" in
	"version")
	echo "LAMW4Linux  version $LAMW_INSTALL_VERSION"
	;;
	"clean")
		CleanOldConfig
	;;
	"install")
		
		mainInstall
	;;

	"clean-install")
		#initParameters $2
		CleanOldConfig
		mainInstall
	;;

	"update-lamw")
		
		checkProxyStatus;
		echo "Updating LAMW";
		getLAMWFramework;
		sleep 1;
		BuildLazarusIDE;
	;;
	"delete_paths")
		cleanPATHS
	;;
	*)
		printf "Use:\n\tbash lamw-install.sh [Options]\n\tbash lamw-install.sh clean\n\tbash lamw-install.sh install\n\tbash lamw-install.sh install --use_proxy\n\tbash lamw-install.sh clean-install\n\tbash lamw-install.sh clean-install --use_proxy\nupdate-lamw\n"
	;;
esac
#fi
