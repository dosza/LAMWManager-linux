#!/bin/bash
export ROOT_LAMW=/home/danny/LAMW
export FPC_RELEASE=trunk
export LAMW4LINUX_HOME=/home/danny

export PATH="$LAMW4LINUX_HOME/fpcsrc/fpc-3.3.1.x86_64-linux/bin:$PATH"
export AARCH64_ANDROID_TOOLS="$ROOT_LAMW/sdk/ndk-bundle/toolchains/aarch64-linux-android-4.9/prebuilt/linux-x86_64/bin"
export FPC_CROSS_AARCH_DEFAULT_PARAMETERS=('clean crossall crossinstall  CPU_TARGET=aarch64 OS_TARGET=android OPT="-dFPC_ARMHF"  INSTALL_PREFIX=/usr')
ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-as" "$AARCH64_ANDROID_TOOLS/aarch64-linux-as"
ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-android-ld" "$AARCH64_ANDROID_TOOLS/aarch64-linux-ld"
ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-as"  "/usr/bin/aarch64-linux-androideabi-as"
ln -sf "$AARCH64_ANDROID_TOOLS/aarch64-linux-ld"  "/usr/bin/aarch64-linux-androideabi-ld"

export PATH=$PATH:$AARCH64_ANDROID_TOOLS
LAMW_IDE_HOME="$ROOT_LAMW/lamw4linux/lamw4linux" 
echo $PATH
LAMW4_LINUX_PATH_CFG=/home/danny/.lamw4linux
#which aarch64-linux-as;read
LAZBUILD_PARAMETERS=(
	"--build-ide= --add-package $ROOT_LAMW/lazandroidmodulewizard/android_bridges/tfpandroidbridge_pack.lpk --primary-config-path=$LAMW4_LINUX_PATH_CFG  --lazarusdir=$LAMW_IDE_HOME"
	"--build-ide= --add-package $ROOT_LAMW/lazandroidmodulewizard/android_wizard/lazandroidwizardpack.lpk --primary-config-path=$LAMW4_LINUX_PATH_CFG --lazarusdir=$LAMW_IDE_HOME"
	"--build-ide= --add-package $ROOT_LAMW/lazandroidmodulewizard/ide_tools/amw_ide_tools.lpk --primary-config-path=$LAMW4_LINUX_PATH_CFG --lazarusdir=$LAMW_IDE_HOME"
)


changeDirectory(){
	echo "arg1=$1"
	if [ "$1" != "" ] ; then
		if [ -e $1  ]; then
			cd $1
			ls
		fi
	fi 
}
BuildCrossAArch64(){
	if [ "$1" != "" ]; then #
		changeDirectory "$LAMW4LINUX_HOME/fpcsrc"
		changeDirectory "$FPC_RELEASE"
		case $1 in 
			0)
				 make clean 
				 make ${FPC_CROSS_AARCH_DEFAULT_PARAMETERS[*]}
			;;

		esac
	fi					
}
BuildLazarusIDE(){
	
	changeDirectory "$ROOT_LAMW/lamw4linux/lazarus_1_8_4"

	if [ $# = 0 ]; then 
		make clean all
#	else 
		#printf "${AZUL}Building LAMW packages ${NORMAL}"
		#sleep 2
	fi
		#build ide  with lamw framework 
	for((i=0;i< ${#LAZBUILD_PARAMETERS[@]};i++))
	do
		#printf "running:${VERDE}${LAZBUILD_PARAMETERS[i]}\n${NORMAL}"
		./lazbuild ${LAZBUILD_PARAMETERS[i]}
		if [ $? != 0 ]; then
			./lazbuild ${LAZBUILD_PARAMETERS[i]}
		fi
	done
}
case "$1" in 
	"build")
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
		rm 
	;;
	"lamw")
		BuildLazarusIDE 1
		chown danny:danny -R $ROOT_LAMW
		chown danny:danny -R $LAMW4_LINUX_PATH_CFG
	;;


esac
