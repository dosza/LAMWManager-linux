#!/bin/bash


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
	if [ -e "$FPC_TRUNK_SOURCE_PATH/trunk" ]; then
		changeDirectory "$FPC_TRUNK_SOURCE_PATH/trunk"
		export FPC_TRUNK_VERSION=$(cat Makefile.fpc | grep 'version=' | sed 's/version=//g') #descover trunk version
	else
		export FPC_TRUNK_VERSION="3.3.1"
	fi
	export FPC_INSTALL_TRUNK_ZIP="$LAMW4LINUX_HOME/usr/share/fpcsrc/trunk/fpc-${FPC_TRUNK_VERSION}.x86_64-linux.tar.gz"
	export FPC_TRUNK_LIB_PATH=/usr/local/lib/fpc/${FPC_TRUNK_VERSION}
	export FPC_TRUNK_EXEC_PATH="/usr/local/bin"
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
		changeDirectory "$FPC_TRUNK_SOURCE_PATH/trunk"
		make clean
		make all zipinstall
		changeDirectory "/usr/local"
		echo "$FPC_INSTALL_TRUNK_ZIP";
		tar -zxvf "$FPC_INSTALL_TRUNK_ZIP" 	
	fi
}

#Function to build ARMv7 and AARCH64
BuildCrossAArch64(){
	changeDirectory "$LAMW4LINUX_HOME/usr/share/fpcsrc/trunk"
	make clean 
	make clean crossall crossinstall  CPU_TARGET=aarch64 OS_TARGET=android OPT="-dFPC_ARMHF"  INSTALL_PREFIX=/usr/local
	make clean
	make crossall crossinstall CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=/usr/local
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

