#!/bin/bash
#Universidade federal de Mato Grosso
#Curso ciencia da computação
#AUTOR: Daniel Oliveira Souza <oliveira.daniel@gmail.com>
#Versao LAMW-INSTALL: 0.2.1
#Descrição: Este script configura o ambiente de desenvolvimento para o LAMW
#Version:0.2.1 add supporte a MIME 

#----ColorTerm
export VERDE=$'\e[1;32m'
export AMARELO=$'\e[01;33m'
export SUBLINHADO='4'
export NEGRITO=$'\e[1m'
export VERMELHO=$'\e[1;31m'
export VERMELHO_SUBLINHADO=$'\e[1;4;31m'
export AZUL=$'\e[1;34m'
export NORMAL=$'\e[0m'

#--------------------------------------------------------------------------------------

LAMW_INSTALL_VERSION="0.2.1"
LAMW_INSTALL_WELCOME=(
	"${NEGRITO}\t\tWelcome LAMW4Linux Installer  version: $LAMW_INSTALL_VERSION${NORMAL}\n"
	"\t\tPowerd by DanielTimelord\n"
	"\t\t<oliveira.daniel109@gmail.com>\n"
)

export ROOT_LAMW="$HOME/LAMW" #RAIZ DO AMBIENTE LAMW 

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
export FORCE_LAWM4INSTALL=0
work_home_desktop=$(xdg-user-dir DESKTOP)
ANDROID_HOME="$ROOT_LAMW"
ANDROID_SDK="$ANDROID_HOME/sdk"
CROSS_COMPILE_URL="https://github.com/newpascal/fpcupdeluxe/releases/tag/v1.6.1e"
APT_OPT=""
export PROXY_SERVER="internet.cua.ufmt.br"
export PORT_SERVER=3128
PROXY_URL="http://$PROXY_SERVER:$PORT_SERVER"
export USE_PROXY=0
export JAVA_PATH=""
export SDK_TOOLS_URL="https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip"
export NDK_URL="https://dl.google.com/android/repository/android-ndk-r18b-linux-x86_64.zip"
SDK_TOOLS_VERSION="r26.1.1"
SDK_VERSION="28"
SDK_MANAGER_CMD_PARAMETERS=()
SDK_MANAGER_CMD_PARAMETERS2=()
SDK_LICENSES_PARAMETERS=()
LAZARUS_STABLE_SRC_LNK="https://svn.freepascal.org/svn/lazarus/tags/lazarus_1_8_4"
LAMW_SRC_LNK="https://github.com/jmpessoa/lazandroidmodulewizard.git"
LAMW4_LINUX_PATH_CFG="$HOME/.lamw4linux"
LAMW4LINUX_HOME="$ROOT_LAMW/lamw4linux"
LAMW_IDE_HOME="$LAMW4LINUX_HOME/lamw4linux" # path to link-simbolic to ide 
LAMW_WORKSPACE_HOME="$HOME/Dev/LAMWProjects"  #path to lamw_workspace
LAMW4LINUX_EXE_PATH="$LAMW_IDE_HOME/lamw4linux"
LAMW_MENU_ITEM_PATH="$HOME/.local/share/applications/lamw4linux.desktop"
GRADLE_HOME="$ANDROID_HOME/gradle-4.4.1"
ANT_HOME="$ANDROID_HOME/apache-ant-1.10.5"
ANT_TAR_URL="http://ftp.unicamp.br/pub/apache/ant/binaries/apache-ant-1.10.5-bin.tar.xz"
ANT_TAR_FILE="apache-ant-1.10.5-bin.tar.xz"
GRADLE_CFG_HOME="$HOME/.gradle"
GRADLE_ZIP_LNK="https://services.gradle.org/distributions/gradle-4.4.1-bin.zip"
GRADLE_ZIP_FILE="gradle-4.4.1-bin.zip"
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
prog_tools="menu fpc git subversion make build-essential zip unzip unrar android-tools-adb openjdk-8-jdk "
packs=()
#[[]

export OLD_ANDROID_SDK=0


checkForceLAMW4LinuxInstall(){
	args=($*)
	for((i=0;i<${#args[*]};i++))
	do
		if [ "${args[i]}" = "--force" ]; then
			#printf "Warning: This application theres power binary deb"
			
			sleep 2
			export FORCE_LAWM4INSTALL=1
			break
		fi
	done
}
#setJRE8 as default
setJava8asDefault(){
	path_java=($(dpkg -L openjdk-8-jre))

i=0
found_path=""
while [ $i -lt ${#path_java[@]} ]
do
	wi=${path_java[$i]}
	#printf "$wi\n"
	case "$wi" in
		*"jre"*)
		#printf "found: i=$i $wi\n"
		#found_path=$w8asDefault
		if [ -e $wi/bin/java ]; then
			#printf "found: i=$i $wi\nStopping search ...\n"
			found_path=$wi
			export JAVA_PATH="$found_path/bin/java"
			sudo update-alternatives --set java $JAVA_PATH
			break;
		fi
	esac
	((i++))
done


}
# searchLineinFile(FILE *fp, char * str )
#$1 is File Path
#$2 is a String to search 
#this function return 0 if not found or 1  if found
searchLineinFile(){
	flag=0
	if [ "$1" != "" ];then
		if [ -e "$1" ];then
			if [ "$2" != "" ];then
				line="NULL"
				#file=$1
				while read line # read a line from
				do
					if [ "$line" = "$2" ];then # if current line is equal $2
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
	if [ $FORCE_LAWM4INSTALL = 1 ]; then 
		sudo apt-get remove --purge  lazarus* -y
		sudo apt-get autoremove --purge -y
	fi
			#sudo apt-get install fpc
	sudo apt-get install $libs_android $prog_tools  -y --allow-unauthenticated
	if [ "$?" != "0" ]; then
		sudo apt-get install $libs_android $prog_tools  -y --allow-unauthenticated --fix-missing
	fi
}

#iniciandoparametros
initParameters(){
	if [ $# = 1 ]; then  
		if [ "$1" = "--use_proxy" ] ;then
					USE_PROXY=1
		fi
	else
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
		SDK_MANAGER_CMD_PARAMETERS2=("ndk-bundle" "extras;android;m2repository" --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
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
		SDK_MANAGER_CMD_PARAMETERS2=("ndk-bundle" "extras;android;m2repository")
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

getAnt(){
	changeDirectory $ANDROID_HOME 
	if [ ! -e $ANT_HOME ]; then
		wget -c $ANT_TAR_URL
		if [ $? != 0 ] ; then
			#rm *.zip*
			ANT_TAR_URL="https://www-eu.apache.org/dist//ant/binaries/apache-ant-1.10.5-bin.tar.xz"
			wget -c $ANT_TAR_URL
		fi
		#echo "$PWD"
		#sleep 3
		tar -xvf "$ANT_TAR_FILE"
	fi

	if [ -e  $ANT_TAR_FILE ]; then
		rm $ANT_TAR_FILE
	fi
}
#Get Gradle and SDK Tools 
getAndroidSDKTools(){
	changeDirectory $HOME
	#fix warming to sdkmanager 
	if  [ ! -e $HOME/.android ]; then
		mkdir $HOME/.android 
		echo "" > $HOME/.android/repositories.cfg
	fi 

	if [ ! -e $ANDROID_HOME ]; then
		mkdir $ANDROID_HOME
	fi
	
	changeDirectory $ANDROID_HOME
	getAnt
	if [ ! -e $GRADLE_HOME ]; then
		wget -c $GRADLE_ZIP_LNK
		if [ $? != 0 ] ; then
			#rm *.zip*
			wget -c $GRADLE_ZIP_LNK
		fi
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
			wget -c $SDK_TOOLS_URL #getting sdk 
			if [ $? != 0 ]; then 
				wget -c $SDK_TOOLS_URL
			fi
			unzip sdk-tools-linux-4333796.zip
			rm sdk-tools-linux-4333796.zip
		fi
	else
		changeDirectory $ANDROID_HOME
		getAnt
		export SDK_TOOLS_VERSION="r25.2.5"
		export SDK_TOOLS_URL="https://dl.google.com/android/repository/tools_r25.2.5-linux.zip"
		if [ ! -e sdk ]; then 
			mkdir $ANDROID_SDK
			changeDirectory $ANDROID_SDK
			wget -c $SDK_TOOLS_URL
			if [ $? != 0 ]; then
				wget -c $SDK_TOOLS_URL
			fi
			#tar -zxvf android-sdk_r24.4.1-linux.tgz 
			unzip tools_r25.2.5-linux.zip
			rm tools_r25.2.5-linux.zip
		fi

		changeDirectory $ANDROID_SDK
		if [ ! -e ndk-bundle ] ; then 
			wget -c $NDK_URL
			if [ $? != 0 ]; then
				wget -c $NDK_URL
			fi
			unzip android-ndk-r18b-linux-x86_64.zip
			mv android-ndk-r18b ndk-bundle
			if [ -e android-ndk-r18b-linux-x86_64.zip ]; then 
				rm android-ndk-r18b-linux-x86_64.zip
			fi
		fi
	fi



}

getSDKAndroid(){
	changeDirectory $ANDROID_SDK/tools/bin #change directory
	yes | ./sdkmanager ${SDK_LICENSES_PARAMETERS[*]}
	if [ $? != 0 ]; then 
		yes | ./sdkmanager ${SDK_LICENSES_PARAMETERS[*]}
	fi
	for((i=0;i<${#SDK_MANAGER_CMD_PARAMETERS[*]};i++))
	do
		echo "getting ${SDK_MANAGER_CMD_PARAMETERS[i]}"
		./sdkmanager ${SDK_MANAGER_CMD_PARAMETERS[i]}  # instala sdk sem intervenção humana  

		if [ $? != 0 ]; then 
			./sdkmanager ${SDK_MANAGER_CMD_PARAMETERS[i]}
		fi
	done

}

getOldAndroidSDK(){
	if [ -e $ANDROID_SDK/tools/android  ]; then 
		changeDirectory $ANDROID_SDK/tools
		echo "before update-sdk"
		./android update sdk
		#echo "--> After update sdk tools to 25.2.5"
		#changeDirectory $ANDROID_SDK/tools
		#./android update sdk
	fi

}
#Create SDK simbolic links

CreateSDKSimbolicLinks(){
	#if [ $OLD_ANDROID_SDK = 0 ]; then 
	ln -sf "$ANDROID_HOME/sdk/ndk-bundle" "$ANDROID_HOME/ndk"
	#fi
	ln -sf "$ANDROID_HOME/ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin" "$ANDROID_HOME/ndk-toolchain"
	ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-androideabi-as" "$ANDROID_HOME/ndk-toolchain/arm-linux-as"
	ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-androideabi-ld" "$ANDROID_HOME/ndk-toolchain/arm-linux-ld"

	sudo ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-androideabi-as" "/usr/bin/arm-linux-androideabi-as"
	sudo ln -sf "$ANDROID_HOME/ndk-toolchain/arm-linux-ld"  "/usr/bin/arm-linux-androideabi-ld"
	sudo ln -sf $FPC_LIB_PATH/ppcrossarm /usr/bin/ppcrossarm
	sudo ln -sf /usr/bin/ppcrossarm /usr/bin/ppcarm

	#if [ $OLD_ANDROID_SDK=0 ]; then 
	#CORRIGE TEMPORARIAMENTE BUG GRADLE TO MIPSEL
		ln -sf "$ANDROID_HOME/sdk/ndk-bundle/toolchains/arm-linux-androideabi-4.9" "$ANDROID_HOME/sdk/ndk-bundle/toolchains/mips64el-linux-android-4.9"
		ln -sf "$ANDROID_HOME/sdk/ndk-bundle/toolchains/arm-linux-androideabi-4.9" "$ANDROID_HOME/sdk/ndk-bundle/toolchains/mipsel-linux-android-4.9"
	#fi

}

#Addd sdk to .bashrc and .profile

AddSDKPathstoProfile(){
	aux=$(tail -1 $HOME/.profile)       #tail -1 mostra a última linha do arquivo 
	if [ "$aux" != "" ] ; then   # verifica se a última linha é vazia
			sed  -i '$a\' $HOME/.profile #adiciona uma linha ao fim do arquivo
	fi


	profile_file=$HOME/.bashrc
	flag_profile_paths=0
	profile_line_path='export PATH=$PATH:$GRADLE_HOME/bin'

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
WrappergetAndroidSDK(){
	if [ $OLD_ANDROID_SDK = 0 ]; then
		getSDKAndroid
	else
		getOldAndroidSDK
	fi

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
	ant_path=$ANT_HOME/bin
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
		"PathToJavaTemplates=$ROOT_LAMW/lazandroidmodulewizard/trunk/java"
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
	)
	for ((i=0;i<${#LAMW_init_str[@]};i++))
	do
		if [ $i = 0 ]; then 
			echo "${LAMW_init_str[i]}" > $LAMW4_LINUX_PATH_CFG/JNIAndroidProject.ini 
		else
			echo "${LAMW_init_str[i]}" >> $LAMW4_LINUX_PATH_CFG/JNIAndroidProject.ini
		fi
	done

	echo  "$LAMW4LINUX_EXE_PATH --primary-config-path=$LAMW4_LINUX_PATH_CFG" > "$LAMW_IDE_HOME/start_laz4lamw.sh"
	if [ -e  $LAMW_IDE_HOME/start_laz4lamw.sh ]; then
		chmod +x $LAMW_IDE_HOME/start_laz4lamw.sh
	fi

	AddLAMWtoStartMenu
}
#Add LAMW4Linux to menu 
AddLAMWtoStartMenu(){
	if [ ! -e ~/.local/share/applications ] ; then #create a directory of local apps launcher, if not exists 
		mkdir -p ~/.local/share/applications
	fi
	if [ ! -e ~/.local/share/mime/packages ]; then
		mkdir -p ~/.local/share/mime/packages
	fi
	
	lamw_desktop_file_str=(
		"[Desktop Entry]"  
		"Name=LAMW4Linux"   
		"Exec=$LAMW4LINUX_EXE_PATH --primary-config-path=$LAMW4_LINUX_PATH_CFG" 
		"Icon=$LAMW_IDE_HOME/images/icons/lazarus_orange.ico" 
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
	for ((i=0;i<${#lamw_desktop_file_str[*]};i++))
	do
		if [ $i = 0 ]; then
			echo ${lamw_desktop_file_str[i]} > $LAMW_MENU_ITEM_PATH
		else
			echo ${lamw_desktop_file_str[i]} >> $LAMW_MENU_ITEM_PATH
		fi
	done
	chmod +x $LAMW_MENU_ITEM_PATH
	cp $LAMW_MENU_ITEM_PATH "$work_home_desktop"
	#mime association: ref https://help.gnome.org/admin/system-admin-guide/stable/mime-types-custom-user.html.en
	cp $LAMW_IDE_HOME/install/lazarus-mime.xml ~/.local/share/mime/packages
	update-mime-database   ~/.local/share/mime/
	update-desktop-database ~/.local/share/applications
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
	echo "Uninstall LAMW4Linux IDE ..."
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
	if [ -e ~/.local/share/mime/packages/lazarus-mime.xml ]; then
		rm ~/.local/share/mime/packages/lazarus-mime.xml
		update-mime-database   ~/.local/share/mime/
		update-desktop-database ~/.local/share/applications
		update-menus
	fi
	if  [  -e $HOME/.android ]; then
		rm -r  $HOME/.android 
	fi 
	cleanPATHS
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
			searchLineinFile $FPC_CFG_PATH  "${fpc_cfg_str[0]}"
			flag_fpc_cfg=$?

			if [ $flag_fpc_cfg != 1 ]; then # caso o arquvo ainda não esteja configurado
				for ((i = 0 ; i<${#fpc_cfg_str[@]};i++)) 
				do
					echo "${fpc_cfg_str[i]}" | tee -a  $FPC_CFG_PATH
				done	
			fi
		fi
}

#write log lamw install 
writeLAMWLogInstall(){

	lamw_log_str=(
		"Generate LAMW_INSTALL_VERSION=$LAMW_INSTALL_VERSION\n" 
		"Info:\nLAMW4Linux:$LAMW4LINUX_HOME\nLAMW workspace:"  
		"$LAMW_WORKSPACE_HOME\nAndroid SDK:$ANDROID_HOME/sdk\n" 
		"Android NDK:$ANDROID_HOME/ndk\nGradle:$GRADLE_HOME\n"
		"OLD_ANDROID_SDK=$OLD_ANDROID_SDK\n"
		)

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
	#unistallJavaUnsupported
	setJava8asDefault
	#getSDKAndroid
	WrappergetAndroidSDK
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
	echo "LAMW-Install (Linux supported Debian 9, Ubuntu 16.04 LTS, Linux Mint 18)
	Generate LAMW4Linux to android-sdk=$SDK_VERSION"
	if [ $FORCE_LAWM4INSTALL = 1 ]; then
		echo "${NEGRITO}Warning: Earlier versions of Lazarus (debian package) will be removed!${NORMAL}"
	else
		echo "${NEGRITO}Warning:${NORMAL}${NEGRITO}This application not  is compatible with lazarus (debian package)${NORMAL}"
		echo "use ${NEGRITO}--force${NORMAL} parameter remove anywhere lazarus (debian package)"
		sleep 1
	fi
	#configure parameters sdk before init download and build

	#Checa se necessario habilitar remocao forcada
	checkForceLAMW4LinuxInstall $*
#else

	if [ $# = 6 ] || [ $# = 7 ]; then
		if [ "$2" = "--use_proxy" ] ;then 
			if [ "$3" = "--server" ]; then
				if [ "$5" = "--port" ] ;then
					initParameters $2 $4 $6
				fi
			fi
		fi
	else
		initParameters $2
	fi
	GenerateScapesStr
	

#Parameters are useful for understanding script operation
case "$1" in
	"version")
	echo "LAMW4Linux  version $LAMW_INSTALL_VERSION"
	;;
	"uninstall")
		CleanOldConfig
	;;
	"install")
		
		mainInstall
	;;

	"install-oldsdk")
		printf "${NEGRITO}Mode SDKTOOLS=24 with ant support${NORMAL}\n"
		export OLD_ANDROID_SDK=1

		mainInstall
	;;

	"reinstall")
		#initParameters $2
		CleanOldConfig
		mainInstall
	;;
	"reinstall-oldsdk")
		printf "Please wait ...\n"
		sleep 2
		CleanOldConfig
		printf "Mode SDKTOOLS=24 with ant support "
		export OLD_ANDROID_SDK=1

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
		lamw_opts=(
			"Usage:\n\tbash lamw-install.sh ${VERDE}[Options]${NORMAL}\n"
			"\tbash lamw-install.sh ${VERDE}uninstall${NORMAL}\n"
			"\tbash lamw-install.sh ${VERDE}reinstall-oldsdk${NORMAL}\n"
			"\tbash lamw-install.sh ${VERDE}install${NORMAL}\n"
			"\tbash laww-install.sh ${VERDE}install${NORMAL} --force\n"
			"\tbash lamw-install.sh ${VERDE}install${NORMAL} --use_proxy\n"
			"\tbash laww-install.sh ${VERDE}install-oldsdk${NORMAL}\n"
			"----------------------------------------------\n"
			"${NEGRITO}\tProxy Options:${NORMAL}\n"
			"\tbash lamw-install.sh install --use_proxy --server ${NEGRITO}[HOST]${NORMAL} --port ${NEGRITO}[NUMBER]${NORMAL}\n"
			"sample:\n\tbash lamw-install.sh install --use_proxy --server 10.0.16.1 --port 3128\n"
			"-----------------------------------------------\n"
			"\tbash lamw-install.sh ${VERDE}reinstall${NORMAL}\n"
			"\tbash lamw-install.sh ${VERDE}reinstall${NORMAL} --force\n"
			"\tbash lamw-install.sh ${VERDE}reinstall${NORMAL} --use_proxy\n"
			"\tbash lamw-install.sh ${VERDE}update-lamw${NORMAL}\n"
			)
		printf "${lamw_opts[*]}"
	;;
esac
#fi
#printf "Finish!!\n"