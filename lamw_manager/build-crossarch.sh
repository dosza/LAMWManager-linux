#!/bin/bash

#import this lib in lamw-install.sh 

export AARCH64_ANDROID_TOOLS="$ROOT_LAMW/sdk/ndk-bundle/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin"
export FPC_CROSS_AARCH_DEFAULT_PARAMETERS=('clean crossall crossinstall  CPU_TARGET=aarch64 OS_TARGET=android OPT="-dFPC_ARMHF"  INSTALL_PREFIX=/usr')
export PATH=$PATH:$AARCH64_ANDROID_TOOLS
export FLAG_FORCE_ANDROID_AARCH64=1
export FPC_TRUNK_RELEASE=""
export FPC_TRUNK_URL="https://svn.freepascal.org/svn/fpc/tags/trunk"
export FPC_TRUNK_VERSION=""
export FPC_TRUNK_LIB_PATH=""
export FPC_TRUNK_EXEC_PATH=""


createSimbolicLinksAndroidAARCH64(){
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-as" "$AARCH64_ANDROID_TOOLS/aarch64-linux-as"
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-ld" "$AARCH64_ANDROID_TOOLS/aarch64-linux-ld"
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-as"  "/usr/bin/aarch64-linux-androideabi-as"
	ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-ld"  "/usr/bin/aarch64-linux-androideabi-ld"
}


getFPCSoucesTrunk(){
	changeDirectory $LAMW_USER_HOME
	mkdir -p $LAMW4LINUX_HOME/fpcsrc
	changeDirectory $LAMW4LINUX_HOME/fpcsrc
	svn checkout $FPC_TRUNK_URL
	if [ $? != 0 ]; then
		rm -rf trunk
		svn checkout "$FPC_TRUNK_URL"
		if [ $? != 0 ]; then 
			rm -rf "trunk"
			echo "possible network instability! Try later!"
			exit 1
		fi
	fi
}
#wrapper to get FPC Sources 
getWrapperFPCSouces(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		echo "Warming:mode experimental Android Aarch64!"
		getFPCTrunk
	else
		getFPCSources
	fi
}
#this function build fpc mode trunk



#this function set env to FPC_TRUNK 
parseFPCTrunk(){
	if [ -e "$LAMW4LINUX_HOME/fpcsrc/trunk" ]; then
		changeDirectory "$LAMW4LINUX_HOME/fpcsrc/trunk"
		export FPC_TRUNK_VERSION=$(cat MakeFile.fpc | grep version | sed 's/version=//g') #descover trunk version
		export FPC_INSTALL_TRUNK_ZIP="$LAMW4LINUX_HOME/fpcsrc/trunk/fpc.x86_64-linux.tar.gz"
		export FPC_TRUNK_LIB_PATH=$ROOT_LAMW/lamw4linux/fpc/${FPC_TRUNK_VERSION}
		export FPC_TRUNK_EXEC_PATH="$ROOT_LAMW/lamw4linux/fpc/${FPC_TRUNK_VERSION}/bin"
		export PATH=$FPC_TRUNK_LIB_PATH:$PATH
		export FPC_MKCFG_EXE=$FPC_TRUNK_EXEC_PATH/fpcmkcfg
	fi
}

wrapperParseFPC(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		parseFPCTrunk
	else
		parseFPC
	fi
}
buildFPCTrunk(){
	if [ -e "$LAMW4LINUX_HOME/fpcsrc/trunk" ]; then
		changeDirectory "$LAMW4LINUX_HOME/fpcsrc"
		changeDirectory "trunk"
		#export FPC_TRUNK_VERSION=$(cat MakeFile.fpc | grep version | sed 's/version=//g') #descover trunk versin
		make clean
		make all zipinstall
		changeDirectory "$ROOT_LAMW/lamw4linux"
		mkdir -p "$ROOT_LAMW/lamw4linux/fpc"
		changeDirectory "$ROOT_LAMW/lamw4linux/fpc"
		tar -zxvf "$FPC_INSTALL_TRUNK_ZIP"
	fi
}
configureFPCTrunk(){
	# parte do arquivo de configuração do fpc, 
	#	if [ ! -e $FPC_CFG_PATH ]; then
	parseFPCTrunk
	$FPC_MKCFG_EXE -d basepath=$FPC_TRUNK_LIB_PATH -o $FPC_CFG_PATH

	#this config enable to crosscompile in fpc 
	fpc_cfg_str=(
		"#IFDEF ANDROID"
		"#IFDEF CPUARM"
		"-CpARMV7A"
		"-CfVFPV3"
		"-Xd"
		"-XParm-linux-androideabi-"
		"-Fl$ROOT_LAMW/ndk/platforms/android-$SDK_VERSION/arch-arm/usr/lib"
		"-FLlibdl.so"
		
		"-FD$ROOT_LAMW/ndk/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin"
		"-Fu${FPC_TRUNK_LIB_PATH}/"'$fpcversion/units/$fpctarget'
		"-Fu${FPC_TRUNK_LIB_PATH}/"'$fpcversion/units/$fpctarget/*'
		"-Fu${FPC_TRUNK_LIB_PATH}/"'$fpcversion/units/$fpctarget/rtl'
		"#ENDIF"

		"IFDEF CPUAARCH64"
		"-Xd"
		"-XPaarch64-linux-android-"
		"-Fl$ROOT_LAMW/ndk/platforms/android-$SDK_VERSION/arch-arm64/usr/lib"
		"-FLlibdl.so"
		"-FD$ROOT_LAMW/ndk/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin"
		"-Fu${FPC_TRUNK_LIB_PATH}/"'$fpcversion/units/$fpctarget'
		"-Fu${FPC_TRUNK_LIB_PATH}/"'$fpcversion/units/$fpctarget/*'
		"-Fu${FPC_TRUNK_LIB_PATH}/"'$fpcversion/units/$fpctarget/rtl'
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

wrapperConfigureFPC(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		configureFPCTrunk
	else
		configureFPC
	fi
}


BuildCrossAArch64(){
	changeDirectory "$LAMW4LINUX_HOME/fpcsrc/trunk"
	make clean 
	make ${FPC_CROSS_AARCH_DEFAULT_PARAMETERS[*]}
}
wrapperBuildFPCCross(){
	if [ $FLAG_FORCE_ANDROID_AARCH64 = 1 ]; then
		buildFPCTrunk
		BuildCrossAArch64 0
		BuildCrossArm 0
	else
		BuildCrossArm 0 
	fi
}
case "$1" in 
	"build")
		getFPCTrunk
		buildFPCTrunk
		BuildCrossAArch64 0
		chown danny:danny -R $ROOT_LAMW
		ln -sf /usr/lib/fpc/3.3.1/ppcrossa64 /usr/bin/ppcrossa64
		ln -sf /usr/bin/ppcrossa64 /usr/bin/ppca64
	;;
	"clean")
		rm "/usr/bin/aarch64-linux-androideabi-as"
		rm "/usr/bin/aarch64-linux-androideabi-ld"
		rm -rf /usr/lib/fpc/3.3.1/ppcrossa64
		rm /usr/bin/ppca64
		rm -rfv /usr/lib/fpc/3.3.1
		rm -rfv /home/danny/fpcsrc

	;;
	"lamw")
		BuildLazarusIDE 1
		chown danny:danny -R $ROOT_LAMW
		chown danny:danny -R $LAMW4_LINUX_PATH_CFG
	;;
	*)
		echo "no actions to CrossArm";
		wrapperConfigureFPC
	;;
esac
