#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.0.3
#Date: 07/29/2021
#Description:The "cross-builder.sh" is part of the core of LAMW Manager.  This script contains crosscompile compiler generation routines for ARMv7 / AARCH64- Android
#-------------------------------------------------------------------------------------------------#

#this function set env to FPC_TRUNK 
parseFPCTrunk(){
	_FPC_TRUNK_VERSION=${FPC_TRUNK_VERSION%\-*}
	FPC_INSTALL_TRUNK_ZIP="$LAMW4LINUX_HOME/usr/share/fpcsrc/${FPC_TRUNK_SVNTAG}/fpc-${FPC_TRUNK_VERSION}.x86_64-linux.tar.gz"
	FPC_TRUNK_LIB_PATH=$LAMW4LINUX_HOME/usr/lib/fpc/${_FPC_TRUNK_VERSION}
	FPC_TRUNK_EXEC_PATH="$LAMW4LINUX_HOME/usr/bin"
	FPC_CFG_PATH="$FPC_TRUNK_LIB_PATH/fpc.cfg"
	export PPC_CONFIG_PATH="$FPC_TRUNK_LIB_PATH"
	
}




#BuildFPC to Trunk
buildFPCTrunk(){
	if [ -e "$FPC_TRUNK_SOURCE_PATH" ]; then
		changeDirectory "$FPC_TRUNK_SOURCE_PATH/$FPC_TRUNK_SVNTAG"
		make clean all zipinstall "PP=$FPC_LIB_PATH/ppcx64"
		check_error_and_exit "${VERMELHO}Fatal Error: Falls build FPC to x86_64-linux${NORMAL}" 
		changeDirectory "$LAMW4LINUX_HOME/usr"
		echo "$FPC_INSTALL_TRUNK_ZIP";
		tar -zxvf "$FPC_INSTALL_TRUNK_ZIP"	
		[  -e "$FPC_INSTALL_TRUNK_ZIP" ] && rm "$FPC_INSTALL_TRUNK_ZIP"
	fi
}

#Function to build ARMv7 and AARCH64
BuildCrossAArch64(){
	changeDirectory "$LAMW4LINUX_HOME/usr/share/fpcsrc/$FPC_TRUNK_SVNTAG"
	make clean crossall crossinstall  CPU_TARGET=aarch64 OS_TARGET=android OPT="-dFPC_ARMHF" INSTALL_PREFIX=$LAMW4LINUX_HOME/usr "PP=$FPC_LIB_PATH/ppcx64"
	check_error_and_exit "${VERMELHO}Fatal Error: Falls to build FPC to  Android/AARCH64${NORMAL}"
	make clean crossall crossinstall CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=$LAMW4LINUX_HOME/usr "PP=$FPC_LIB_PATH/ppcx64"
	check_error_and_exit "${VERMELHO}Fatal Error: Falls to build FPC  to Android/ARMv7${NORMAL}"

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
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		parseFPCTrunk
	fi
}

