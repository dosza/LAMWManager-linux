#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.3.3
#Date: 11/12/2019
#Description:The "cross-builder.sh" is part of the core of LAMW Manager.  This script contains crosscompile compiler generation routines for ARMv7 / AARCH64- Android
#-------------------------------------------------------------------------------------------------#



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
					  rm -r /usr/lib/fpc
				fi
				 ln -s /usr/lib/x86_64-linux-gnu/fpc /usr/lib/fpc
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


#this function build fpc mode	 trunk



#this function set env to FPC_TRUNK 
parseFPCTrunk(){

	export FPC_TRUNK_VERSION="3.2.0-beta"
	export _FPC_TRUNK_VERSION=${FPC_TRUNK_VERSION%\-*}
	export FPC_INSTALL_TRUNK_ZIP="$LAMW4LINUX_HOME/usr/share/fpcsrc/${FPC_TRUNK_SVNTAG}/fpc-${FPC_TRUNK_VERSION}.x86_64-linux.tar.gz"
	export FPC_TRUNK_LIB_PATH=$LAMW4LINUX_HOME/usr/lib/fpc/${_FPC_TRUNK_VERSION}
	export FPC_TRUNK_EXEC_PATH="$LAMW4LINUX_HOME/usr/bin"
	#echo "FPC_TRUNK_VERSION=$FPC_TRUNK_VERSION"
	export FPC_CFG_PATH="$FPC_TRUNK_LIB_PATH/fpc.cfg"
	export PPC_CONFIG_PATH="$FPC_TRUNK_LIB_PATH"
	
}



#to build FPC to ARMv7
BuildCrossArm(){
	changeDirectory $LAMW4LINUX_HOME/fpcsrc 
	changeDirectory $FPC_RELEASE
	make clean 
	make crossall crossinstall  CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=/usr		
}


#BuildFPC to Trunk
buildFPCTrunk(){
	if [ -e "$FPC_TRUNK_SOURCE_PATH" ]; then
		echo "$PATH"
		changeDirectory "$FPC_TRUNK_SOURCE_PATH/$FPC_TRUNK_SVNTAG"
		make clean all zipinstall
		changeDirectory "$LAMW4LINUX_HOME/usr"
		echo "$FPC_INSTALL_TRUNK_ZIP";
		tar -zxvf "$FPC_INSTALL_TRUNK_ZIP" 	
	fi
}

#Function to build ARMv7 and AARCH64
BuildCrossAArch64(){
	changeDirectory "$LAMW4LINUX_HOME/usr/share/fpcsrc/$FPC_TRUNK_SVNTAG"
	make clean crossall crossinstall  CPU_TARGET=aarch64 OS_TARGET=android OPT="-dFPC_ARMHF"  INSTALL_PREFIX=$LAMW4LINUX_HOME/usr
	#make clean crossall crossinstall  CPU_TARGET=arm OS_TARGET=android OPT="-dFPC_ARMEL" CROSSOPT="-Cpaarch64 -CfVFPv4" INSTALL_PREFIX=$LAMW4LINUX_HOME/usr;read
	make clean crossall crossinstall CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=$LAMW4LINUX_HOME/usr
	CreateFPCTrunkBootStrap
}

#wrapper to configureFPC
wrapperConfigureFPC(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		configureFPCTrunk
	else
		configureFPC
	fi
}

#wrapper to BuilCrossArm
wrapperBuildFPCCross(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		buildFPCTrunk
		BuildCrossAArch64 
	else
		BuildCrossArm 
	fi
}
#function to wrapper FPC
wrapperParseFPC(){
	SearchPackage fpc
	index=$?
	parseFPC ${packs[$index]}
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		parseFPCTrunk
	fi
}

