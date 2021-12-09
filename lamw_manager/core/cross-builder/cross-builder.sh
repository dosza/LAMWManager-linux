#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.3
#Date: 12/09/2021
#Description:The "cross-builder.sh" is part of the core of LAMW Manager.  This script contains crosscompile compiler generation routines for ARMv7 / AARCH64- Android
#-------------------------------------------------------------------------------------------------#

#this function set env to FPC_TRUNK 
parseFPCTrunk(){
	_FPC_TRUNK_VERSION=${FPC_TRUNK_VERSION%\-*}
	FPC_INSTALL_TRUNK_ZIP="$LAMW4LINUX_HOME/usr/share/fpcsrc/${FPC_TRUNK_SVNTAG}/fpc-${FPC_TRUNK_VERSION}.x86_64-linux.tar.gz"
	FPC_TRUNK_LIB_PATH=$LAMW4LINUX_HOME/usr/lib/fpc/${_FPC_TRUNK_VERSION}
	FPC_TRUNK_EXEC_PATH="$LAMW4LINUX_HOME/usr/bin"
	FPC_CFG_PATH="$FPC_TRUNK_LIB_PATH/fpc.cfg"
	FPPKG_TRUNK_CFG_PATH="$FPC_TRUNK_LIB_PATH/fppkg.cfg"
	export PPC_CONFIG_PATH="$FPC_TRUNK_LIB_PATH"
	
}




#BuildFPC to Trunk
buildFPCTrunk(){
	if [ -e "$FPC_TRUNK_SOURCE_PATH" ]; then
		local build_msg="Please wait, starting build FPC to ${NEGRITO}x86_64/Linux${NORMAL} ..."
		local succes_msg="Build to FPC ${NEGRITO}x86_64/Linux${NORMAL}"
		changeDirectory "$FPC_TRUNK_SOURCE_PATH/$FPC_TRUNK_SVNTAG"
		printf "%s\n" "$build_msg"
		make -s  clean all install  INSTALL_PREFIX=$LAMW4LINUX_HOME/usr "PP=$FPC_LIB_PATH/ppcx64"
		check_error_and_exit "${VERMELHO}Fatal Error: Falls build FPC to x86_64-linux${NORMAL}" 
		printf  "%s\n\n" "${succes_msg}${FILLER:${#succes_msg}}${VERDE} [OK]${NORMAL}"

	fi
}


BuildCrossAll(){
	case $1 in
	0)
		make -s  clean crossall crossinstall  CPU_TARGET=aarch64 OS_TARGET=android OPT="-dFPC_ARMHF"\
			INSTALL_PREFIX=$LAMW4LINUX_HOME/usr "PP=$FPC_LIB_PATH/ppcx64" ;;
	1)
		make -s  clean crossall crossinstall CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3"\
			 INSTALL_PREFIX=$LAMW4LINUX_HOME/usr "PP=$FPC_LIB_PATH/ppcx64";;
	2) 
		make -s  clean crossall crossinstall CPU_TARGET=x86_64 OS_TARGET=android "PP=$FPC_LIB_PATH/ppcx64"\
			 INSTALL_PREFIX=$LAMW4LINUX_HOME/usr OPT="-Cfsse3" CROSSOPT="-Cfsse3" ;;
	3)
		make -s  clean crossall crossinstall CPU_TARGET=i386 CPU_TARGET=i386 OS_TARGET=android "PP=$FPC_LIB_PATH/ppcx64"\
			INSTALL_PREFIX=$LAMW4LINUX_HOME/usr OPT="-Cfsse3" CROSSOPT="-Cfsse3" ;;
	*) 
		check_error_and_exit "${VERMELHO}Fatal Error:${NORMAL}Invalid CrossOpts";;
	esac
}

#Function to build ARMv7 and AARCH64
BuildCrossAArch64(){
	changeDirectory "$LAMW4LINUX_HOME/usr/share/fpcsrc/$FPC_TRUNK_SVNTAG"
	
	local build_aarch=( AARCH64 ARMv7 x86_64 i386)

	for i in ${!build_aarch[*]}; do 
		local error_build_msg="${VERMELHO}Fatal Error:${NORMAL} Falls to build FPC to Android/${build_aarch[$i]}"
		local build_msg="Please wait, starting build FPC to ${NEGRITO}${build_aarch[i]}/Android${NORMAL}..."
		local succes_msg="Build to FPC ${NEGRITO}${build_aarch[i]}/Android${NORMAL}"
		printf "%s\n" "$build_msg"
		BuildCrossAll $i 
		check_error_and_exit ${error_build_msg[i]}
		printf  "%s\n\n" "${succes_msg}${FILLER:${#succes_msg}}${VERDE} [OK]${NORMAL}"
	done

	echo "cleaning sources..."
	make -s  clean > /dev/null
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

