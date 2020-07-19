#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.3.5
#Date: 07/14/2020
#Description:The "cross-builder.sh" is part of the core of LAMW Manager.  This script contains crosscompile compiler generation routines for ARMv7 / AARCH64- Android
#-------------------------------------------------------------------------------------------------#



#detecta a versão do fpc instalada no PC  seta as váriavies de ambiente
parseFPC(){ 	
	local dist_file=$(cat /etc/issue.net)
	case "$dist_file" in 
		*"Ubuntu 18."*)
			export flag_new_ubuntu_lts=1
		;;
		*"Linux Mint 19"*)
			export flag_new_ubuntu_lts=1
		;;
	esac
}


#this function build fpc mode	 trunk



#this function set env to FPC_TRUNK 
parseFPCTrunk(){

	export FPC_TRUNK_VERSION="3.2.0"
	export _FPC_TRUNK_VERSION=${FPC_TRUNK_VERSION%\-*}
	export FPC_INSTALL_TRUNK_ZIP="$LAMW4LINUX_HOME/usr/share/fpcsrc/${FPC_TRUNK_SVNTAG}/fpc-${FPC_TRUNK_VERSION}.x86_64-linux.tar.gz"
	export FPC_TRUNK_LIB_PATH=$LAMW4LINUX_HOME/usr/lib/fpc/${_FPC_TRUNK_VERSION}
	export FPC_TRUNK_EXEC_PATH="$LAMW4LINUX_HOME/usr/bin"
	#echo "FPC_TRUNK_VERSION=$FPC_TRUNK_VERSION"
	export FPC_CFG_PATH="$FPC_TRUNK_LIB_PATH/fpc.cfg"
	export PPC_CONFIG_PATH="$FPC_TRUNK_LIB_PATH"
	
}




#BuildFPC to Trunk
buildFPCTrunk(){
	if [ -e "$FPC_TRUNK_SOURCE_PATH" ]; then
		changeDirectory "$FPC_TRUNK_SOURCE_PATH/$FPC_TRUNK_SVNTAG"
		make clean all zipinstall "PP=$FPC_LIB_PATH/ppcx64"
		if [ $? != 0 ]; then
			echo "${VERMELHO}Fatal Error: Falls build FPC -x86_64-linux${NORMAL}" 
			exit 1
		fi
		changeDirectory "$LAMW4LINUX_HOME/usr"
		echo "$FPC_INSTALL_TRUNK_ZIP";
		tar -zxvf "$FPC_INSTALL_TRUNK_ZIP"	
		if [  -e "$FPC_INSTALL_TRUNK_ZIP" ]; then 
			rm "$FPC_INSTALL_TRUNK_ZIP"
		fi
	fi
}

#Function to build ARMv7 and AARCH64
BuildCrossAArch64(){
	changeDirectory "$LAMW4LINUX_HOME/usr/share/fpcsrc/$FPC_TRUNK_SVNTAG"
	make clean crossall crossinstall  CPU_TARGET=aarch64 OS_TARGET=android OPT="-dFPC_ARMHF" INSTALL_PREFIX=$LAMW4LINUX_HOME/usr "PP=$FPC_LIB_PATH/ppcx64"
	if [ $? != 0 ]; then 
		echo "${VERMELHO}Fatal Error: Falls to build FPC to  Android/AARCH64${NORMAL}"
		exit 1
	fi
	make clean crossall crossinstall CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=$LAMW4LINUX_HOME/usr "PP=$FPC_LIB_PATH/ppcx64"
	#make clean crossall crossinstall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMEL" CROSSOPT="-Cpaarch64 -CfVFPv4" INSTALL_PREFIX=$LAMW4LINUX_HOME/usr;read
	if [ $? != 0 ]; then 
		echo "${VERMELHO}Fatal Error: Falls to build FPC  to Android/ARMv7${NORMAL}"
		exit 1
	fi

	echo "cleaning sources..."
	make clean > /dev/null
	#CreateFPCTrunkBootStrap
}

#wrapper to configureFPC
ConfigureFPCCrossAndroid(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		configureFPCTrunk
	fi
}

#wrapper to BuilCrossArm
buildCrossAndroid(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		buildFPCTrunk
		BuildCrossAArch64 
	fi
}
#function to wrapper FPC
wrapperParseFPC(){
	parseFPC
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		parseFPCTrunk
	fi
}

