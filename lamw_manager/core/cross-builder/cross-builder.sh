#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.5.2
#Date: 12/06/2022
#Description:The "cross-builder.sh" is part of the core of LAMW Manager.  This script contains crosscompile compiler generation routines for ARMv7 / AARCH64- Android
#-------------------------------------------------------------------------------------------------#

#this function set env to FPC_TRUNK 
parseFPCTrunk(){
	_FPC_TRUNK_VERSION=${FPC_TRUNK_VERSION%\-*}
	FPC_TRUNK_LIB_PATH=$LAMW4LINUX_HOME/usr/lib/fpc/${_FPC_TRUNK_VERSION}
	FPC_TRUNK_EXEC_PATH="$LAMW4LINUX_HOME/usr/bin"
	FPC_CFG_PATH="$FPC_TRUNK_LIB_PATH/fpc.cfg"
	FPPKG_TRUNK_CFG_PATH="$FPC_TRUNK_LIB_PATH/fppkg.cfg"
	export PPC_CONFIG_PATH="$FPC_TRUNK_LIB_PATH"
	
}

BuildFPC(){
	
	local pp="$FPC_LIB_PATH/ppcx64"
	local install_prefix="$LAMW4LINUX_HOME/usr"

	case $1 in
		0)
			make -s  clean all install INSTALL_PREFIX=$install_prefix "PP=$pp";;

		1)
			make -s  clean crossall crossinstall CPU_TARGET=aarch64 OS_TARGET=android OPT="-dFPC_ARMHF"\
				INSTALL_PREFIX=$install_prefix "PP=$pp" ;;
		2)
			make -s  clean crossall crossinstall CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android\
				CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=$install_prefix "PP=$pp";;
		3) 
			make -s  clean crossall crossinstall CPU_TARGET=x86_64 OS_TARGET=android "PP=$pp"\
				 INSTALL_PREFIX=$install_prefix OPT="-Cfsse3" CROSSOPT="-Cfsse3" ;;
		4)
			make -s  clean crossall crossinstall CPU_TARGET=i386 OS_TARGET=android "PP=$pp"\
				INSTALL_PREFIX=$install_prefix OPT="-Cfsse3" CROSSOPT="-Cfsse3" ;;
		*) 
			check_error_and_exit "${VERMELHO}Fatal Error:${NORMAL}Invalid CrossOpts";;
	esac
}

buildCurrentFPC(){
	local error_build_msg="${VERMELHO}Fatal Error:${NORMAL} Falls to build FPC to ${build_aarch[$i]}"
	local build_msg="Please wait, starting build FPC to ${NEGRITO}${build_aarch[i]}${NORMAL}.............."
	local sucess_filler="$(getCurrentSucessFiller 0 ${build_aarch[i]})"
	printf "%s" "$build_msg"
	BuildFPC $i > /dev/null
	if [ $? != 0 ]; then 
		printf  "%s\n" "${FILLER:${#sucess_filler}}${VERMELHO} [FALLS]${NORMAL}"
		printf "%s" "$build_msg"
		BuildFPC $i
		check_error_and_exit ${error_build_msg[i]}
	fi

	printf  "%s\n" "${FILLER:${#sucess_filler}}${VERDE} [OK]${NORMAL}"
}

getMaxBuildArchs(){
	if [ $LAMW_MINIMAL_INSTALL = 0 ]; then
		echo ${#build_aarch[*]}
	else
		echo $MIN_LAMW_ARCHS
	fi
}
#Function to build ARMv7 and AARCH64
buildCrossAndroid(){
	local build_aarch=( "x86_64/Linux" {AARCH64,ARMv7,x86_64,i386}/Android)
	local max_archs=$(getMaxBuildArchs)
	changeDirectory "$LAMW4LINUX_HOME/usr/share/fpcsrc/$FPC_TRUNK_SVNTAG"
	
	for ((i=0;i<$max_archs;i++)) do 
		buildCurrentFPC
	done

	local sucess_filler="$(getCurrentSucessFiller 2 android/Linux)"
	printf "Please wait, cleaning FPC Sources to ${NEGRITO}Linux/Android${NORMAL}......................."	
	make -s  clean > /dev/null 2>&1
	printf  "%s\n" "${FILLER:${#sucess_filler}}${VERDE} [OK]${NORMAL}"
}