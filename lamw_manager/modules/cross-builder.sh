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


#this function build fpc mode trunk



#this function set env to FPC_TRUNK 
parseFPCTrunk(){
	if [ -e "$LAMW4LINUX_HOME/fpcsrc/trunk" ]; then
		changeDirectory "$LAMW4LINUX_HOME/fpcsrc/trunk"
		export FPC_TRUNK_VERSION=$(cat Makefile.fpc | grep 'version=' | sed 's/version=//g') #descover trunk version
		
	else
		export FPC_TRUNK_VERSION="3.3.1"
	fi
	export FPC_INSTALL_TRUNK_ZIP="$LAMW4LINUX_HOME/fpcsrc/trunk/fpc-${FPC_TRUNK_VERSION}.x86_64-linux.tar.gz"
	export FPC_TRUNK_LIB_PATH=$ROOT_LAMW/lamw4linux/usr/lib/fpc/${FPC_TRUNK_VERSION}
	export FPC_TRUNK_EXEC_PATH="$ROOT_LAMW/lamw4linux/usr/bin"
	export PATH=$FPC_TRUNK_EXEC_PATH:$PATH
	#export FPC_MKCFG_EXE=$FPC_TRUNK_EXEC_PATH/fpcmkcfg

}



#to build
BuildCrossArm(){
	changeDirectory $LAMW4LINUX_HOME/fpcsrc 
	changeDirectory $FPC_RELEASE
	make clean 
	make crossall crossinstall  CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=/usr		
}

buildFPCTrunk(){
	if [ -e "$LAMW4LINUX_HOME/fpcsrc/trunk" ]; then
		changeDirectory "$LAMW4LINUX_HOME/fpcsrc"
		changeDirectory "trunk"
		#export FPC_TRUNK_VERSION=$(cat MakeFile.fpc | grep version | sed 's/version=//g') #descover trunk versin
		make clean
		make all zipinstall
		changeDirectory "$ROOT_LAMW/lamw4linux"
		mkdir -p "$ROOT_LAMW/lamw4linux/usr/"
		changeDirectory "$ROOT_LAMW/lamw4linux/usr"
		echo "$FPC_INSTALL_TRUNK_ZIP";
		tar -zxvf "$FPC_INSTALL_TRUNK_ZIP" 
	fi
}

BuildCrossAArch64(){
	changeDirectory "$LAMW4LINUX_HOME/fpcsrc/trunk"
	make clean 
	make clean crossall crossinstall  CPU_TARGET=aarch64 OS_TARGET=android OPT="-dFPC_ARMHF"  INSTALL_PREFIX=$ROOT_LAMW/lamw4linux/usr
	make clean
	make crossall crossinstall CPU_TARGET=arm OPT="-dFPC_ARMEL" OS_TARGET=android CROSSOPT="-CpARMV7A -CfVFPV3" INSTALL_PREFIX=$ROOT_LAMW/lamw4linux/usr		
}

wrapperConfigureFPC(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		configureFPCTrunk
	else
		configureFPC
	fi
}



wrapperBuildFPCCross(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		buildFPCTrunk
		BuildCrossAArch64 
	else
		BuildCrossArm 
	fi
}
wrapperParseFPC(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		parseFPCTrunk
	else
		parseFPC
	fi
}
# case "$1" in 
# 	"build")
# 		getFPCTrunk
# 		buildFPCTrunk
# 		BuildCrossAArch64 0
# 		chown danny:danny -R $ROOT_LAMW
# 		ln -sf /usr/lib/fpc/3.3.1/ppcrossa64 /usr/bin/ppcrossa64
# 		ln -sf /usr/bin/ppcrossa64 /usr/bin/ppca64
# 	;;
# 	"clean")
# 		rm "/usr/bin/aarch64-linux-androideabi-as"
# 		rm "/usr/bin/aarch64-linux-androideabi-ld"
# 		rm -rf /usr/lib/fpc/3.3.1/ppcrossa64
# 		rm /usr/bin/ppca64
# 		rm -rfv /usr/lib/fpc/3.3.1
# 		rm -rfv /home/danny/fpcsrc

# 	;;
# 	"lamw")
# 		BuildLazarusIDE 1
# 		chown danny:danny -R $ROOT_LAMW
# 		chown danny:danny -R $LAMW4_LINUX_PATH_CFG
# 	;;
# 	*)
# 		echo "no actions to CrossArm";
# 		wrapperConfigureFPC
# 	;;
# esac
