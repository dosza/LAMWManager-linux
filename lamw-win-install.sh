
#!/bin/bash
#Universidade federal de Mato Grosso
#Curso ciencia da computação
#AUTOR: Daniel Oliveira Souza <oliveira.daniel@gmail.com>
#Versao LAMW-INSTALL: 0.2.0
#Descrição: Este script configura o ambiente de desenvolvimento para o LAMW

#GLOBAL VARIABLES 
export WINDOWS_CMD_WRAPPERS=1
MINGW_URL="http://osdn.net/projects/mingw/downloads/68260/mingw-get-setup.exe"
WIN_PROGR="freepascal git.install svn jdk8  7zip.install ant  "
MINGW_PACKAGES="msys-wget-bin  mingw32-base-bin mingw-developer-toolkit-bin msys-base-bin msys-zip-bin "
MINGW_OPT="--reinstall"
export WIN_CURRENT_USER=""
export WIN_HOME_4_UNIX=""
export WIN_HOME="" #this path compatible with Windows
export HOME=""
if [  $WINDOWS_CMD_WRAPPERS  = 1 ]; then
	#source $WINDOWS_CMD_WRAPPERS
	#export user=$(whoami)
	echo '$env:username' > /tmp/pscommand.ps1

	/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe Set-ExecutionPolicy Bypass
	export WIN_CURRENT_USER=$(/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe  /tmp/pscommand.ps1)
	
	export WIN_HOME_4_UNIX="/c/Users/$WIN_CURRENT_USER"
	export WIN_HOME='\Users\'
	export WIN_HOME="$WIN_HOME$WIN_CURRENT_USER"
	export HOME="/home/$WIN_CURRENT_USER"
	#echo "username=$WIN_HOME_4_UNIX"
	#sleep 2
	#/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe  Get-ExecutionPolicy 
	#/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe Set-ExecutionPolicy AllSigned
	#/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe  -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('http://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
	
	#unzip wrappers to windows 
	unzip(){
		/c/Program\ Files/7-zip/7z.exe x $*
	}

fi

LAMW_INSTALL_VERSION="0.2.0"
LAMW_INSTALL_WELCOME=(
	"\t\tWelcome LAMW4Windows Installer  version: $LAMW_INSTALL_VERSION\n"
	"\t\tPowerd by DanielTimelord\n"
	"\t\t<oliveira.daniel109@gmail.com>\n"
)

export DEBIAN_FRONTEND="gnome"
export URL_FPC=""
export FPC_VERSION=""
export FPC_CFG_PATH="/c/tools/freepascal/bin/i386-win32/fpc.cfg" #"$WIN_HOME_4_UNIX/.fpc.cfg"


export PPC_CONFIG_PATH=$FPC_CFG_PATH
export FPC_RELEASE=""
export flag_new_ubuntu_lts=0
export FPC_LIB_PATH=""

export FPC_VERSION=""
export FPC_MKCFG_EXE=""
export FORCE_LAWM4INSTALL=0
#work_home_desktop=$(xdg-user-dir DESKTOP)
ANDROID_HOME="$WIN_HOME_4_UNIX/android"
ANDROID_SDK="$ANDROID_HOME/sdk"
#ANDROID_HOME for $win 

BARRA_INVERTIDA="\""
#------------ PATHS translated for windows------------------------------
WIN_ANDROID_HOME="$WIN_HOME\android"
WIN_ANDROID_SDK="$WIN_ANDROID_HOME\sdk"
WIN_LAMW4_LINUX_PATH_CFG="$WIN_HOME\.lamw4linux"
WIN_LAMW4LINUX_HOME="$WIN_HOME\lamw4linux"
WIN_LAMW_IDE_HOME="$WIN_LAMW4LINUX_HOME\lazarus_stable" # path to link-simbolic to ide 
WIN_LAMW_IDE_HOME_REAL="$WIN_LAMW_IDE_HOME$BARRA_INVERTIDA$LAZARUS_STABLE"

WIN_LAMW_WORKSPACE_HOME="$WIN_HOME\Dev\LAMWProjects"  #piath to lamw_workspacewin
WIN_LAMW4LINUX_EXE_PATH="$WIN_LAMW_IDE_HOME\lamw4linux"
WIN_LAMW_MENU_ITEM_PATH="\ProgramData\Microsoft\Windows\Start Menu\Programs\lamw4linux.lnk"
WIN_GRADLE_HOME="$WIN_ANDROID_HOME\gradle-4.4.1"
#export WIN_CFG_PATH=""
export WIN_FPC_CFG_PATH="C:\tools\freepascal\bin\i386-win32\fpc.cfg"
export WIN_FPC_LIB_PATH=""
export WIN_PPC_CONFIG_PATH=$FPC_CFG_PATH

#--------------------------------------------------------------------------
CROSS_COMPILE_URL="http://github.com/newpascal/fpcupdeluxe/releases/tag/v1.6.1e"
APT_OPT=""
export PROXY_SERVER="internet.cua.ufmt.br"
export PORT_SERVER=3128
PROXY_URL="http://$PROXY_SERVER:$PORT_SERVER"
export USE_PROXY=0
export JAVA_PATH=""
export SDK_TOOLS_URL="http://dl.google.com/android/repository/sdk-tools-windows-3859397.zip" 
export NDK_URL="http://dl.google.com/android/repository/android-ndk-r16b-windows-x86_64.zip"
SDK_VERSION="28"
SDK_MANAGER_CMD_PARAMETERS=()
SDK_MANAGER_CMD_PARAMETERS2=()
SDK_LICENSES_PARAMETERS=()
LAZARUS_STABLE_SRC_LNK="http://svn.freepascal.org/svn/lazarus/tags/lazarus_1_8_4"
LAMW_SRC_LNK="http://github.com/jmpessoa/lazandroidmodulewizard.git"
LAMW4_LINUX_PATH_CFG="$WIN_HOME_4_UNIX/.lamw4linux"
LAMW4LINUX_HOME="$WIN_HOME_4_UNIX/lamw4linux"
LAMW_IDE_HOME="$LAMW4LINUX_HOME/lazarus_stable" # path to link-simbolic to ide 
LAMW_WORKSPACE_HOME="$WIN_HOME_4_UNIX/Dev/LAMWProjects"  #piath to lamw_workspace
LAMW4LINUX_EXE_PATH="$LAMW_IDE_HOME/lamw4linux"
LAMW_MENU_ITEM_PATH="$WIN_HOME_4_UNIX/.local/share/applications/lamw4linux.desktop"
GRADLE_HOME="$ANDROID_HOME/gradle-4.4.1"
#WIN_GRADLE_HOME=
GRADLE_CFG_HOME="$WIN_HOME_4_UNIX/.gradle"

GRADE_ZIP_LNK="http://services.gradle.org/distributions/gradle-4.4.1-bin.zip"
GRADE_ZIP_FILE="gradle-4.4.1-bin.zip"
FPC_STABLE=""
LAZARUS_STABLE="lazarus_1_8_4"

FPC_ID_DEFAULT=0
FPC_CROSS_ARM_DEFAULT_PARAMETERS=('clean crossall crossinstall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMHF" SUBARCH="armv7a" INSTALL_PREFIX=/usr')
FPC_CROSS_ARM_MODE_FPCDELUXE=(crossall crossinstall  CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=/usr)
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
#echo "WIN_GRADLE_HOME=$WIN_GRADLE_HOME"
#sleep 3
export OLD_ANDROID_SDK=0
#--------------Win32 functions-------------------------

winMKLinkDir(){
	if [ $# = 2 ]; then
		#getWinEnvPaths "TEMP"
		echo "LinkDir:target=$1 link=$2"
		rm  /tmp/winMKLink.bat
		win_temp_path=$(getWinEnvPaths "HOMEDRIVE")
		win_temp_path="$win_temp_path/tools/msys64/tmp/winMKLink.bat"
		echo "mklink /J $2 $1" > /tmp/winMKLink.bat 
		winCallfromPS $win_temp_path
		rm  /tmp/winMKLink.bat 
	fi
}
winMKLink(){
	if [ $# = 2 ]; then
		echo "Link: target=$1 link=$2"
		
		win_temp_path=$(getWinEnvPaths "HOMEDRIVE")
		win_temp_path="$win_temp_path/tools/msys64/tmp/winMKLink.bat"
		aspas="\""
		#echo   "s2=$aspas$2$aspas s1=$aspas$1$aspas"
		echo "mklink  $aspas$2$aspas $aspas$1$aspas" > /tmp/winMKLink.bat 
		#read
		winCallfromPS $win_temp_path
		rm  /tmp/winMKLink.bat
	fi
}
getAndroidSDKToolsW32(){
	changeDirectory $WIN_HOME_4_UNIX
	if [ ! -e ANDROID_HOME ]; then
		mkdir $ANDROID_HOME
	fi
	
	changeDirectory $ANDROID_HOME
	if [ ! -e $GRADLE_HOME ]; then
		wget -c $GRADE_ZIP_LNK
		if [ $? != 0 ] ; then
			#rm *.zip*
			wget -c $GRADE_ZIP_LNK
		fi
		#echo "$PWD"
		#sleep 3
		unzip "$GRADE_ZIP_FILE"
	fi
	
	if [ -e  $GRADE_ZIP_FILE ]; then
		rm $GRADE_ZIP_FILE
	fi
	#mkdir
	#changeDirectory $ANDROID_SDK
	if [ ! -e sdk ] ; then
		mkdir sdk
	fi
		changeDirectory sdk
		if [ ! -e tools ]; then  
			wget -c $SDK_TOOLS_URL #getting sdk 
			if [ $? != 0 ]; then 
				wget -c $SDK_TOOLS_URL
			fi
			unzip "sdk-tools-windows-3859397.zip"
		fi
		
		#mv "sdk-tools-windows-3859397" "tools"

		if [ -e  "sdk-tools-windows-3859397.zip" ]; then
			rm  "sdk-tools-windows-3859397.zip"
		fi
	#fi
}
#Get Gradle and SDK Tools
getOldAndroidSDKToolsW32(){
	changeDirectory $WIN_HOME_4_UNIX
	if [ ! -e ANDROID_HOME ]; then
		mkdir $ANDROID_HOME
	fi
	
	changeDirectory $ANDROID_HOME
	if [ ! -e $GRADLE_HOME ]; then
		wget -c $GRADE_ZIP_LNK
		if [ $? != 0 ] ; then
			#rm *.zip*
			wget -c $GRADE_ZIP_LNK
		fi
		#echo "$PWD"
		#sleep 3
		unzip "$GRADE_ZIP_FILE"
	fi
	
	if [ -e  $GRADE_ZIP_FILE ]; then
		rm $GRADE_ZIP_FILE
	fi
	#mkdir
	#changeDirectory $ANDROID_SDK
	if [ ! -e sdk ] ; then
		mkdir sdk
		changeDirectory sdk
		export SDK_TOOLS_URL="http://dl.google.com/android/installer_r24.0.2-windows.exe" 
		wget -c $SDK_TOOLS_URL #getting sdk 
		if [ $? != 0 ]; then 
			wget -c $SDK_TOOLS_URL
		fi
		./installer_r24.0.2-windows.exe
	fi

	if [ ! -e ndk ]; then
		wget -c $NDK_URL
		if [ $? != 0 ]; then 
			wget -c $NDK_URL
		fi
		unzip android-ndk-r16b-windows-x86_64.zip
		mv android-ndk-r16b ndk
		if [ -e android-ndk-r16b-windows-x86_64.zip ]; then
			rm android-ndk-r16b-windows-x86_64.zip
		fi
	fi


}

makeFromPS(){
	path_make="$1"
	ps_make="$1\psmake.ps1"
	bat_make="$1\batmake.bat"
	args=($*)
	printf "%s" "make " > $bat_make
	#for((i=1;i<$#;i++))
	#do
	#	printf " \"%s\" " "${args[i]}" >> $bat_make
#done
	printf "%s\n" 'crossall crossinstall  CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=/usr' >> $bat_make
	echo "cd $1" > $ps_make
	echo "$bat_make" >> $ps_make

	/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe Set-ExecutionPolicy Bypass
	/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe  $ps_make
	rm $ps_make $bat_make
}
winCallfromPS(){
	echo "$*" > /tmp/pscommand.ps1
	/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe Set-ExecutionPolicy Bypass
	/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe  /tmp/pscommand.ps1
}
winCallfromPS1(){
	args=($*)
	installer_cmd="$ANDROID_SDK/tools/bin/sdk-install.bat"
	win_installer_cmd="$WIN_ANDROID_SDK\tools\bin\sdk-install.bat"
	rm /tmp/pscommand.ps1
	rm $installer_cmd

	#echo "cd $WIN_ANDROID_SDK\tools\bin" >> /tmp/sdk-install.sh
	#echo "$*" > /tmp/pscommand.ps1

	#for((i=0;i < $#;i++));
	#do
			#echo ${args[i]}
			#printf ' "' >> /tmp/pscommand.ps1
			printf " \"%s\" \"%s\""  "${args[0]}"  "${args[1]}" >> $installer_cmd
			#
		
			#printf '" ' >> /tmp/pscommand.ps1
	#done
	winCallfromPS "$win_installer_cmd"
	#/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe Set-ExecutionPolicy Bypass
	#/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe  /tmp/pscommand.ps1
}
getWinEnvPaths(){
	command='$env:'
	command="$command$1"
	echo "$command" > /tmp/pscommand.ps1
	/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe Set-ExecutionPolicy Bypass
	/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe  /tmp/pscommand.ps1
}
updateWinPATHS(){
	cmd_paths='\ProgramData\chocolatey\bin\RefreshEnv'
	winCallfromPS "$cmd_paths"
	new_cmd_path='echo $PATH' 
	echo "$new_cmd_path" > /tmp/update-win-path.sh
	if [ $? !=  0 ]; then
		echo "not write"
		exit 1
	fi
	new_path=$(bash /tmp/update-win-path.sh)
	#echo "NEW_PATH=$new_path"
	#read 
	export PATH=$new_path
}

#----------------------------------------------------------------------------------------------------------------------------
checkForceLAMW4LinuxInstall(){
	args=($*)
	for((i=0;i<${#args[*]};i++))
	do
		if [ "${args[i]}" = "--force" ]; then
			#printf "Warning: This application theres power binary deb"
			
			#sleep 2
			export FORCE_LAWM4INSTALL=1
			break
		fi
	done
}
#setJRE8 as default
setJava8asDefault(){
	#path_java=($(dpkg -L openjdk-8-jre))
	path_java=($(splitStr "$PATH" ":" ))
	i=0
	found_path=""
	while [ $i -lt ${#path_java[@]} ]
	do
	wi=${path_java[$i]}
	#printf "$wi\n"
	case "$wi" in
		*"jdk"*)
		#printf "found: i=$i $wi\n"
		#found_path=$w8asDefault
		if [ -e $wi/bin/java ]; then
			#printf "found: i=$i $wi\nStopping search ...\n"
			found_path=$wi
			export JAVA_PATH="$found_path/bin/java"
			#fJupdate-alternatives --set java $JAVA_PATH
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
			HOME_STR_SPLITTED=$WIN_HOME_4_UNIX_STR_SPLITTED"\/"${HOME_USER_SPLITTED_ARRAY[i]}
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
		apt-get remove --purge openjdk-9-* -y 
		apt-get remove --purge openjdk-11* -y
	fi
}
installDependences(){
	if [ $WINDOWS_CMD_WRAPPERS = 1 ]; then 

		echo "trying get mingw ..."
		#sleep 2
		changeDirectory $WIN_HOME_4_UNIX
	#	wget $MINGW_URL
		#./mingw-get-setup.exe 
		#/c/Mingw/bin/mingw-get.exe update
		#/c/Mingw/bin/mingw-get.exe install $MINGW_PACKAGES $MINGW_OPT
		choco install $WIN_PROGR -y
		updateWinPATHS
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
		SDK_MANAGER_CMD_PARAMETERS=("platforms;android-26" "build-tools;26.0.2" "tools" "ndk-bundle" "extras;android;m2repository" --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
		SDK_MANAGER_CMD_PARAMETERS2=("ndk-bundle" "extras;android;m2repository" --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
		SDK_LICENSES_PARAMETERS=( --licenses --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
		export http_proxy=$PROXY_URL
		export https_proxy=$PROXY_URL
#	ActiveProxy 1
	else
		SDK_MANAGER_CMD_PARAMETERS=("platforms;android-26" "build-tools;26.0.2" "tools" "ndk-bundle" "extras;android;m2repository")			#ActiveProxy 0
		SDK_MANAGER_CMD_PARAMETERS2=("ndk-bundle" "extras;android;m2repository")
		SDK_LICENSES_PARAMETERS=(--licenses )
	fi
}
#Get FPC Sources
getFPCSources(){
	changeDirectory $WIN_HOME_4_UNIX
	mkdir -p $LAMW4LINUX_HOME/fpcsrc
	changeDirectory $LAMW4LINUX_HOME/fpcsrc
	svn checkout "$URL_FPC"
	if [ $? != 0 ]; then
		#rm $FPC_RELEASE/.svn -r
		rm -r $FPC_RELEASE
		svn checkout $URL_FPC
		if [ $? != 0 ]; then 
			rm -r $FPC_RELEASE
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
		rm -r $LAZARUS_STABLE
		#svn cleanup
		#changeDirectory $LAMW4LINUX_HOME
		svn co $LAZARUS_STABLE_SRC_LNK
		if [ $? != 0 ]; then 
			rm -r $LAZARUS_STABLE
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
		rm -r lazandroidmodulewizard.git
		svn co $LAMW_SRC_LNK
		if [ $? != 0 ]; then 
			rm -r lazandroidmodulewizard.git
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
	
}



getSDKAndroid(){
	changeDirectory $ANDROID_SDK/tools/bin #change directory
	letter_home_driver=$(getWinEnvPaths "HOMEDRIVE" )
	yes |  winCallfromPS1 "$letter_home_driver$WIN_ANDROID_SDK\tools\bin\sdkmanager.bat" ${SDK_LICENSES_PARAMETERS[*]}
	if [ $? != 0 ]; then 
			yes | winCallfromPS1 "$letter_home_driver$WIN_ANDROID_SDK\tools\bin\sdkmanager.bat" ${SDK_LICENSES_PARAMETERS[i]}
	fi

	for((i=0;i<${#SDK_MANAGER_CMD_PARAMETERS[*]};i++))
	do
		
		winCallfromPS1 "$letter_home_driver$WIN_ANDROID_SDK\tools\bin\sdkmanager.bat" ${SDK_MANAGER_CMD_PARAMETERS[i]}  # instala sdk sem intervenção humana  

		if [ $? != 0 ]; then 
			winCallfromPS1 "$letter_home_driver$WIN_ANDROID_SDK\tools\bin\sdkmanager.bat" ${SDK_MANAGER_CMD_PARAMETERS[i]}
		fi
		#winCallfromPS1 "$letter_home_driver$WIN_ANDROID_SDK\tools\bin\sdkmanager.bat" "ndk-bundle"

		#if [ $? != 0 ]; then 
		#	winCallfromPS1 "$letter_home_driver$WIN_ANDROID_SDK\tools\bin\sdkmanager.bat" "ndk-bundle"
		#fi

	done

}

getOldAndroidSDK(){

	if [ -e $ANDROID_SDK/tools/android.bat  ]; then 
		changeDirectory $ANDROID_SDK/tools
		winCallfromPS "$WIN_ANDROID_SDK\tools\android.bat" "update" "sdk "
		#./android update sdk
		echo "--> After update sdk tools to 24.1.1"
		changeDirectory $ANDROID_SDK/tools
		#./android update sdk
		winCallfromPS "$WIN_ANDROID_SDK\tools\android.bat" "update" "sdk"

		#echo "please wait ..."
		#read 
	fi

}
#Create SDK simbolic links

CreateSDKSimbolicLinks(){
	letter_home_driver=$(getWinEnvPaths "HOMEDRIVE" )
	echo "DRIVER ROOT : $letter_home_driver"
	if [ $OLD_ANDROID_SDK = 0 ]; then 
			winMKLinkDir "$letter_home_driver$WIN_ANDROID_HOME\sdk\ndk-bundle" "$letter_home_driver$WIN_ANDROID_HOME\ndk"
	fi

	letter_home_driver=$(getWinEnvPaths "HOMEDRIVE" )
	winMKLinkDir "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9\prebuilt\windows-x86_64\bin" "$WIN_ANDROID_HOME\ndk-toolchain"
	winMKLink "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9\prebuilt\windows-x86_64\bin\arm-linux-androideabi-as.exe" "$letter_home_driver$WIN_ANDROID_HOME\ndk-toolchain\arm-linux-as.exe"
	winMKLink "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9\prebuilt\windows-x86_64\bin\arm-linux-androideabi-ld.exe" "$letter_home_driver$WIN_ANDROID_HOME\ndk-toolchain\arm-linux-ld.exe"

	winMKLink "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9\prebuilt\windows-x86_64\bin\arm-linux-androideabi-as.exe" "C:\tools\msys64\usr\bin\arm-linux-androideabi-as"
	winMKLink "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9\prebuilt\windows-x86_64\bin\arm-linux-ld.exe"  "C:\tools\msys64\usr\bin\arm-linux-androideabi-ld.exe" #"/usr/bin/arm-linux-androideabi-ld"
	winMKLink "$letter_home_driver$WIN_FPC_LIB_PATH\ppcrossarm.exe" "C:\tools\msys64\usr\bin\ppcrossarm.exe"
	winMKLink  "C:\tools\msys64\usr\bin\ppcrossarm.exe"   "C:\tools\msys64\usr\bin\ppcarm.exe"

	if [ $OLD_ANDROID_SDK=0 ]; then 
	#CORRIGE TEMPORARIAMENTE BUG GRADLE TO MIPSEL
		winMKLink "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9\prebuilt\windows-x86_64\bin\arm-linux-androideabi-4.9.exe" "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9\prebuilt\windows-x86_64\bin\mips64el-linux-android-4.9.exe"
		winMKLink "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9\prebuilt\windows-x86_64\bin\arm-linux-androideabi-4.9.exe" "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9\prebuilt\windows-x86_64\bin\mipsel-linux-android-4.9.exe"
		winMKLinkDir "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9" "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\mipsel-linux-android-4.9"
		winMKLinkDir "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9" "$letter_home_driver$WIN_ANDROID_HOME\ndk\toolchains\mips64el-linux-android-4.9"
	fi

	winMKLinkDir "$letter_home_driver$WIN_ANDROID_HOME\lazandroidmodulewizard.git" "$letter_home_driver$WIN_ANDROID_HOME\lazandroidmodulewizard"
	bar='\'
	aux_path="$WIN_LAMW4LINUX_HOME$bar$LAZARUS_STABLE"
	echo "aux_path=$aux_path"
	#read
	winMKLinkDir "$aux_path" "$WIN_LAMW_IDE_HOME"  # link to lamw4_home directory 
	winMKLink "$WIN_LAMW_IDE_HOME\lazarus" "$WIN_LAMW4LINUX_EXE_PATH" #link  to lazarus executable

#	echo "press enter to exit function \"CreateSDKSimbolicLinks\""
#	read

}

#Addd sdk to .bashrc and .profile

AddSDKPathstoProfile(){
	aux=$(tail -1 $WIN_HOME_4_UNIX/.profile)       #tail -1 mostra a última linha do arquivo 
	if [ "$aux" != "" ] ; then   # verifica se a última linha é vazia
			sed  -i '$a\' $WIN_HOME_4_UNIX/.profile #adiciona uma linha ao fim do arquivo
	fi


	profile_file=$WIN_HOME_4_UNIX/.bashrc
	flag_profile_paths=0
	profile_line_path='export PATH=$PATH:$GRADLE_HOME/1-bin'
	searchLineinFile "$profile_file" "$profile_line_path"
	flag_profile_paths=$?
	if [ $flag_profile_paths = 0 ] ; then 
		#echo 'export PATH=$PATH'"\":$ANDROID_HOME/ndk-toolchain\"" >> $WIN_HOME_4_UNIX/.bashrc
		#echo 'export PATH=$PATH'"\":$GRADLE_HOME/bin\"" >> $WIN_HOME_4_UNIX/.bashrc
		echo "export ANDROID_HOME=$ANDROID_HOME" >>  $WIN_HOME_4_UNIX/.bashrc
		echo "export GRADLE_HOME=$GRADLE_HOME" >> $WIN_HOME_4_UNIX/.bashrc
		echo 'export PATH=$PATH:$ANDROID_HOME/ndk-toolchain' >> $WIN_HOME_4_UNIX/.bashrc
		echo 'export PATH=$PATH:$GRADLE_HOME/bin' >> $WIN_HOME_4_UNIX/.bashrc
	fi

	export PATH=$PATH:$ANDROID_HOME/ndk-toolchain
	export PATH=$PATH:$GRADLE_HOME/bin
}


WrappergetAndroidSDK(){
	if [ $WINDOWS_CMD_WRAPPERS = 1 ]; then 
		if [ $OLD_ANDROID_SDK =  0 ]; then
			getSDKAndroid
		else
			getOldAndroidSDK
		fi
	fi
}
WrappergetAndroidSDKTools(){
	if [ $WINDOWS_CMD_WRAPPERS = 1 ]; then
		if [ $OLD_ANDROID_SDK = 0 ]; then
			getAndroidSDKToolsW32
		else
			getOldAndroidSDKToolsW32
		fi
	fi 
	#if [ $OLD_ANDROID_SDK = 0 ]; then
	#	getSDKAndroid
	#else
	#	getOldAndroidSDK
	#fi

}
#to build
BuildCrossArm(){
	if [ "$1" != "" ]; then #
		changeDirectory $LAMW4LINUX_HOME/fpcsrc 
		changeDirectory $FPC_RELEASE
		bar='/'
		case $1 in 
			0 )
				make clean
			#	str="$WIN_LAMW4LINUX_HOME\fpcsrc"
			#	bar='\'
			#	str="$str$bar$FPC_RELEASE"
			#	echo "str=$str"
				#read
			#	makeFromPS "$str" ${FPC_CROSS_ARM_MODE_FPCDELUXE[*]}
				# 777  -Rv $LAMW4LINUX_HOME/fpcsrc$bar$FPC_RELEASE
				make crossall crossinstall  CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=/c/tools/freepascal
				#echo "press enter to exit BuildCrossArm" ; read
			;;

		esac
	fi				
}

#Build lazarus ide

BuildLazarusIDE(){
	
	letter_home_driver=$(getWinEnvPaths "HOMEDRIVE" )
	changeDirectory $LAMW_IDE_HOME
	build_win_cmd="generate-lazarus.bat"
	bar='\'
	WIN_LAZBUILD_PARAMETERS=(
		"--build-ide= --add-package \"$letter_home_driver$WIN_ANDROID_HOME\lazandroidmodulewizard.git\trunk\android_bridges\tfpandroidbridge_pack.lpk\" --primary-config-path=$letter_home_driver$WIN_LAMW4_LINUX_PATH_CFG  --lazarusdir=$letter_home_driver$WIN_LAMW_IDE_HOME"
		"--build-ide= --add-package \"$letter_home_driver$WIN_ANDROID_HOME\lazandroidmodulewizard.git\trunk\android_wizard\lazandroidwizardpack.lpk\" --primary-config-path=$letter_home_driver$WIN_LAMW4_LINUX_PATH_CFG --lazarusdir=$letter_home_driver$WIN_LAMW_IDE_HOME"
		"--build-ide= --add-package \"$letter_home_driver$WIN_ANDROID_HOME\lazandroidmodulewizard.git\trunk\ide_tools\amw_ide_tools.lpk\" --primary-config-path=$letter_home_driver$WIN_LAMW4_LINUX_PATH_CFG --lazarusdir=$letter_home_driver$WIN_LAMW_IDE_HOME"
	)
	#make clean all
	echo "cd $letter_home_driver$WIN_LAMW_IDE_HOME_REAL" > $build_win_cmd
	echo "make clean all" >> $build_win_cmd
		#build ide  with lamw framework 
	for((i=0;i< ${#WIN_LAZBUILD_PARAMETERS[@]};i++))
	do
		#./lazbuild ${LAZBUILD_PARAMETERS[i]}
		echo "lazbuild ${WIN_LAZBUILD_PARAMETERS[i]}" >> $build_win_cmd
		#echo "lazbuild $letter_home_driver${WIN_LAZBUILD_PARAMETERS[i]}" >> $build_win_cmd
		#if [ $? != 0 ]; then
		#	./lazbuild ${LAZBUILD_PARAMETERS[i]}
	#	fi
	done
	winCallfromPS "$letter_home_driver$WIN_LAMW_IDE_HOME$bar$build_win_cmd"

	echo  "lazarus --primary-config-path=$letter_home_driver$WIN_LAMW4_LINUX_PATH_CFG" > start_laz4lamw.bat
}
#Esta função imprime o valor de uma váriavel de ambiente do MS Windows 
#this  fuction create a INI file to config  all paths used in lamw framework 
LAMW4LinuxPostConfig(){
	old_lamw_workspace="$WIN_HOME_4_UNIX/Dev/lamw_workspace"
	if [ ! -e $LAMW4_LINUX_PATH_CFG ] ; then
		mkdir $LAMW4_LINUX_PATH_CFG
	fi

	if [ -e $old_lamw_workspace ]; then
		mv $old_lamw_workspace $LAMW_WORKSPACE_HOME
	fi
	if [ ! -e $LAMW_WORKSPACE_HOME ] ; then
		mkdir -p $LAMW_WORKSPACE_HOME
	fi

	#java_versions=("/usr/lib/jvm/java-8-openjdk-amd64"  "/usr/lib/jvm/java-8-oracle"  "/usr/lib/jvm/java-8-openjdk-i386")
	java_path=$(getWinEnvPaths "JAVA_HOME" )
	tam=${#java_versions[@]} #tam recebe o tamanho do vetor 
	ant_path=$(getWinEnvPaths "ANT_HOME" )
	letter_home_driver=$(getWinEnvPaths "HOMEDRIVE" )


# contem o arquivo de configuração do lamw
	LAMW_init_str=(
		"[NewProject]"
		"PathToWorkspace=$letter_home_driver$WIN_LAMW_WORKSPACE_HOME"
		"PathToJavaTemplates=$letter_home_driver$WIN_HOME\android\lazandroidmodulewizard\trunk\java"
		"PathToJavaJDK=$java_path"
		"PathToAndroidNDK=$letter_home_driver$WIN_HOME\android\ndk"
		"PathToAndroidSDK=$letter_home_driver$WIN_HOME\android\sdk"
		"PathToAntBin=$ant_path"
		"PathToGradle=$letter_home_driver$WIN_GRADLE_HOME"
		"PrebuildOSYS=windows-x86_64"
		"MainActivity=App"
		"FullProjectName="
		"InstructionSet=2"
		"AntPackageName=org.lamw"
		"AndroidPlatform=0"
		"AntBuildMode=debug"
		"NDK=5"
	)
	echo "${LAMW_init_str[*]}"
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
	letter_home_driver=$(getWinEnvPaths "HOMEDRIVE" )
	# echo "[Desktop Entry]" > $LAMW_MENU_ITEM_PATH
	# echo "Name=LAMW4Linux" >>  $LAMW_MENU_ITEM_PATH
	# echo "Exec=$LAMW4LINUX_EXE_PATH --primary-config-path=$LAMW4_LINUX_PATH_CFG" >>$LAMW_MENU_ITEM_PATH
	# echo "Icon=$LAMW_IDE_HOME/images/icons/lazarus_orange.ico" >>$LAMW_MENU_ITEM_PATH
	# echo "Type=Application" >> $LAMW_MENU_ITEM_PATH
	# echo "Categories=Development;IDE;" >> $LAMW_MENU_ITEM_PATH
	# chmod +x $LAMW_MENU_ITEM_PATH
	# cp $LAMW_MENU_ITEM_PATH "$work_home_desktop"
	#LAMW4LinuxPostConfig
	#add support the usb debug  on linux for anywhere android device 
	
#	update-menus

	#lamw_shortcut_target="$letter_home_driver$WIN_LAMW4LINUX_EXE_PATH"
	#lamw_shortcut_link="$letter_home_driver$BARRA_INVERTIDA$WIN_LAMW_IDE_HOME/start_laz4LAMW"
	#short_cmd_args=()
	#shortcut -f -t "$lamw_shortcut_target" -n "$lamw_shortcut_link"
	#lamw_shortcut_link="%userprofile%"\start menu\programs\"
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
		rm $FPC_LIB_PATH/ppcrossarm
	fi
	
	if [ -e /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android ]; then
		rm -r /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android
	fi
	if [ -e /usr/lib/fpc/$FPC_VERSION/units/arm-android ]; then
		rm -r /usr/lib/fpc/$FPC_VERSION/units/arm-android
	fi
}

cleanPATHS(){
	sed -i "/export ANDROID_HOME=*/d"  $WIN_HOME_4_UNIX/.bashrc
	sed -i "/export GRADLE_HOME=*/d" $WIN_HOME_4_UNIX/.bashrc
	sed -i '/export PATH=$PATH:$WIN_HOME_4_UNIX\/android\/ndk-toolchain/d'  $WIN_HOME_4_UNIX/.bashrc #\/ is scape of /
	sed -i '/export PATH=$PATH:$WIN_HOME_4_UNIX\/android\/gradle-4.1\/bin/d' $WIN_HOME_4_UNIX/.bashrc
	sed -i '/export PATH=$PATH:$WIN_HOME_4_UNIX\/android\/ndk-toolchain/d'  $WIN_HOME_4_UNIX/.profile
	sed -i '/export PATH=$PATH:$WIN_HOME_4_UNIX\/android\/gradle-4.1\/bin/d' $WIN_HOME_4_UNIX/.profile	
	sed -i '/export PATH=$PATH:$ANDROID_HOME\/ndk-toolchain/d'  $WIN_HOME_4_UNIX/.bashrc
	sed -i '/export PATH=$PATH:$GRADLE_HOME/d'  $WIN_HOME_4_UNIX/.bashrc
}
#this function remove old config of lamw4linux  
CleanOldConfig(){

	if [ $WINDOWS_CMD_WRAPPERS = 1 ]; then
		if [ -e $ANDROID_HOME/sdk/unistall.exe ]; then
			$ANDROID_HOME/sdk/unistall.exe
		fi
		if [ -e $WIN_HOME_4_UNIX/mingw-get-setup.exe ]; then
			rm $WIN_HOME_4_UNIX/mingw-get-setup.exe
		fi
	fi
	if [ -e /usr/bin/arm-linux-androideabi-as.exe ]; then
		rm /usr/bin/arm-linux-androideabi-as.exe
	fi
	if [ -e /usr/bin/arm-linux-ld.exe ] ; then 
		rm /usr/bin/arm-linux-ld.exe
	fi

	if [ -e $WIN_HOME_4_UNIX/laz4ndroid ]; then
		rm  -r $WIN_HOME_4_UNIX/laz4ndroid
	fi
	if [ -e $WIN_HOME_4_UNIX/.laz4android ] ; then
		rm -r $WIN_HOME_4_UNIX/.laz4android
	fi
	if [ -e $LAMW4LINUX_HOME ] ; then
		rm $LAMW4LINUX_HOME -rv
	fi

	if [ -e $LAMW4_LINUX_PATH_CFG ]; then  rm -r $LAMW4_LINUX_PATH_CFG; fi

	if [ -e $ANDROID_HOME ] ; then
		rm -r $ANDROID_HOME  
	fi


	if [ -e $WIN_HOME_4_UNIX/.local/share/applications/laz4android.desktop ];then
		rm $WIN_HOME_4_UNIX/.local/share/applications/laz4android.desktop
	fi

	if [ -e $LAMW_MENU_ITEM_PATH ]; then
		rm $LAMW_MENU_ITEM_PATH
	fi

	if [ -e $GRADLE_CFG_HOME ]; then
		rm -r $GRADLE_CFG_HOME
	fi

	if [ -e usr/bin/arm-embedded-as ] ; then    
		rm usr/bin/arm-embedded-as
	fi
	if [ -e  /usr/bin/arm-linux-androideabi-ld ]; then
		 rm /usr/bin/arm-linux-androideabi-ld
	fi
	if [ -e /usr/bin/arm-embedded-ld  ]; then
		/usr/bin/arm-embedded-ld           
	fi 
	if [ -e /usr/bin/arm-linux-as ] ; then 
	 	rm  /usr/bin/arm-linux-as
	fi
	if [ -e /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android ]; then
		rm -r /usr/lib/fpc/$FPC_VERSION/fpmkinst/arm-android
	fi

	if [ -e $FPC_CFG_PATH ]; then #remove local ppc config
		rm $FPC_CFG_PATH
	fi
	if [ -e "$work_home_desktop/lamw4linux.desktop" ]; then
		rm "$work_home_desktop/lamw4linux.desktop"
	fi
	cleanPATHS
	# sed -i '/export PATH=$PATH:$WIN_HOME_4_UNIX\/android\/ndk-toolchain/d'  $WIN_HOME_4_UNIX/.bashrc #\/ is scape of /
	# sed -i '/export PATH=$PATH:$WIN_HOME_4_UNIX\/android\/gradle-4.1\/bin/d' $WIN_HOME_4_UNIX/.bashrc
	# sed -i '/export PATH=$PATH:$WIN_HOME_4_UNIX\/android\/ndk-toolchain/d'  $WIN_HOME_4_UNIX/.profile
	# sed -i '/export PATH=$PATH:$WIN_HOME_4_UNIX\/android\/gradle-4.1\/bin/d' $WIN_HOME_4_UNIX/.profile		
}


#this function returns a version fpc 
SearchPackage(){
	index=-1
	#vetor que armazena informações sobre a intalação do pacote
	if [ "$1" != "" ]  ; then
		packs=($(choco list $1 --local-only))
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

	
	# dist_file=$(cat /etc/issue.net)
	# case "$dist_file" in 
	# 	*"Ubuntu 18."*)
	# 		export flag_new_ubuntu_lts=1
	# 	;;
	# 	*"Linux Mint 19"*)
	# 		export flag_new_ubuntu_lts=1
	# 	;;
	# esac

	case "$1" in 
		*"3.0.0"*)
			export URL_FPC="http://svn.freepascal.org/svn/fpc/tags/release_3_0_0"
			#export FPC_LIB_PATH="/usr/lib/fpc"
			#export FPC_CFG_PATH="/etc/fpc-3.0.0.cfg"
			export FPC_RELEASE="release_3_0_0"
			export FPC_VERSION="3.0.0"
			#export FPC_LIB_PATH="/usr/lib/fpc/$FPC_VERSION"
		;;
		*"3.0.4"*)
			export URL_FPC="http://svn.freepascal.org/svn/fpc/tags/release_3_0_4"
			export FPC_RELEASE="release_3_0_4"
			export FPC_VERSION="3.0.4"
		;;
	esac


	#export FPC_MKCFG_EXE=$(which fpcmkcfg-$FPC_VERSION)
	export FPC_LIB_PATH="/c/tools/freepascal"
	export WIN_FPC_LIB_PATH='\tools\freepascal'
	export FPC_MKCFG_EXE=$(which fpcmkcfg.exe)
	
}

enableADBtoUdev(){
	 printf 'SUBSYSTEM=="usb", ATTR{idVendor}=="<VENDOR>", MODE="0666", GROUP="plugdev"\n'  | tee /etc/udev/rules.d/51-android.rules
	 service udev restart
}
configureFPC(){
	if [ "$(whoami)" = "root" ];then
		packs=()
		ANDROID_HOME=$1
		SearchPackage freepascal
		index=$?
		parseFPC ${packs[$index]}
	fi
	# parte do arquivo de configuração do fpc, 
		SearchPackage freepascal
		index=$?
		parseFPC ${packs[$index]}
		
}
enableCrossCompile(){
if [ ! -e $FPC_CFG_PATH ]; then
		$FPC_MKCFG_EXE -d basepath=/c/tools/freepascal -o $FPC_CFG_PATH
		fi

		#this config enable to crosscompile in fpc 
		fpc_cfg_str=(
			"#IFDEF ANDROID"
			"#IFDEF CPUARM"
			"-CpARMV7A"
			"-CfVFPV3"
			"-Xd"
			"-XParm-linux-androideabi-"
			"-Fl$WIN_ANDROID_HOME\ndk\platforms\android-$SDK_VERSION\arch-arm\usr\lib"
			"-FLlibdl.so"
			"-FD$WIN_ANDROID_HOME\ndk\toolchains\arm-linux-androideabi-4.9\prebuilt\linux-x86_64\bin"
			'-FuC:\tools\freepascal\units\$fpctarget' #-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget
			'-FuC:\tools\freepascal\units\$fpctarget*' #'-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget*'
			'-FuC:\tools\freepascal\units\$fpctarget\rtl' #'-Fu/usr/lib/fpc/$fpcversion/units/$fpctarget/rtl'
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
		printf "Info:\nLAMW4Linux:$LAMW4LINUX_HOME\nLAMW workspace : $WIN_HOME_4_UNIX/Dev/lamw_workspace\nAndroid SDK:$ANDROID_HOME/sdk\nAndroid NDK:$ANDROID_HOME/ndk\nGradle:$GRADLE_HOME\nLOG:$LAMW4LINUX_HOME/lamw-install.log"
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


	

	#getWinEnvPaths "TEMP"
	#sleep 5
	installDependences
	checkProxyStatus
	configureFPC
	#getAndroidSDKToolsW32
	WrappergetAndroidSDKTools
	changeDirectory $ANDROID_SDK/tools/bin #change directory
	#unistallJavaUnsupported
	#setJava8asDefault
	#getSDKAndroid
	WrappergetAndroidSDK
	getFPCSources
	getLAMWFramework
	getLazarusSources
	CreateSDKSimbolicLinks
	#read
	AddSDKPathstoProfile
	changeDirectory $WIN_HOME_4_UNIX
	CleanOldCrossCompileBins
	changeDirectory $FPC_RELEASE
	BuildCrossArm $FPC_ID_DEFAULT
	enableCrossCompile
	BuildLazarusIDE
	changeDirectory $ANDROID_HOME
	LAMW4LinuxPostConfig
	enableADBtoUdev
	writeLAMWLogInstall
	rm /tmp/*.bat
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
	Generate LAMW4Linux to  android-sdk=$SDK_VERSION"
	if [ $FORCE_LAWM4INSTALL = 1 ]; then
		echo "Warning: Earlier versions of Lazarus (debian package) will be removed!"
	else
		echo "This application not  is compatible with lazarus (debian package)"
		echo "use --force parameter remove anywhere lazarus (debian package)"
		#sleep 1
	fi
	#configure parameters sdk before init download and build

	#Checa se necessario habilitar remocao forcada
	checkForceLAMW4LinuxInstall $*
#else
	echo "LAMW4LinuxInstall  manager recomen"
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
	"clean")
		CleanOldConfig
	;;
	"install")
		
		mainInstall
	;;

	"install=sdk24")
		printf "Mode SDKTOOLS=24 with ant support "
		export OLD_ANDROID_SDK=1

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
		#sleep 1;
		BuildLazarusIDE;
	;;

	"mkcrossarm")
		configureFPC 
		changeDirectory $FPC_RELEASE
		BuildCrossArm $FPC_ID_DEFAULT
	;;
	"delete_paths")
		cleanPATHS
	;;
	"update-config")
		LAMW4LinuxPostConfig
	;;
	"update-links")
		CreateSDKSimbolicLinks
	;;
	*)
		lamw_opts=(
			"Usage:\n\tbash lamw-install.sh [Options]\n"
			"\tbash lamw-install.sh clean\n"
			"\tbash lamw-install.sh install\n"
			"\tbash lawmw-install.sh install --force"
			"\tbash lamw-install.sh install --use_proxy\n"
			"\tbash lawmw-install.sh install=sdk24"
			"----------------------------------------------\n"
			"\tbash lamw-install.sh install --use_proxy --server [HOST] --port [NUMBER] \n"
			"sample:\n\tbash lamw-install.sh install --use_proxy --server 10.0.16.1 --port 3128\n"
			"-----------------------------------------------\n"
			"\tbash lamw-install.sh clean-install\n"
			"\tbash lamw-install.sh clean-install --force\n"
			"\tbash lamw-install.sh clean-install --use_proxy\n"
			"\tbash lamw-install.sh update-lamw\n"
			)
		printf "${lamw_opts[*]}"
	;;
	
esac
#fi
#/c/tools/freepascal/bin/i386-Win32/fpcmkcfg.exe
