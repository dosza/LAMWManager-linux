#!/bin/bash
if [ -e "$PWD/lamw_manager" ];then 
	lamw_manager_script="$(realpath ./lamw_manager)"
else 	
	lamw_manager_script=$(realpath ../lamw_manager)	
fi

export HOME=$(mktemp -dt  danny.XXXXXXXXXXX)

LAMW_MANAGER_MODULES_PATH=$(dirname $lamw_manager_script)/core
source "$LAMW_MANAGER_MODULES_PATH/headers/common-shell.sh"
source "$LAMW_MANAGER_MODULES_PATH/headers/lamw_manager_headers"
source "$LAMW_MANAGER_MODULES_PATH/headers/admin-parser.sh"
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/root-lamw-settings-editor.sh"
source "$LAMW_MANAGER_MODULES_PATH/headers/lamw4linux_env.sh"
source "$LAMW_MANAGER_MODULES_PATH/headers/lamw_headers"
source "$LAMW_MANAGER_MODULES_PATH/headers/parser.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/services.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/distro-overrides.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/configure.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/installer.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/preinstall.sh"
source "$LAMW_MANAGER_MODULES_PATH/installer/postinstall.sh"
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/lamw-settings-editor.sh"
source "$LAMW_MANAGER_MODULES_PATH/cross-builder/cross-builder.sh"
source "$LAMW_MANAGER_MODULES_PATH/components/progress-bar.sh"

testCheckisLocalRootLAMWInvalid(){
	export LOCAL_ROOT_LAMW=/home 
	ret=$(checkisLocalRootLAMWInvalid)
	assertEquals 1 $?
	export LOCAL_ROOT_LAMW=/media 
	ret=$(checkisLocalRootLAMWInvalid)
	assertEquals 1 $?

	export LOCAL_ROOT_LAMW=/mnt 
	ret=$(checkisLocalRootLAMWInvalid)
	assertEquals 1 $?

	export LOCAL_ROOT_LAMW=/ 
	ret=$(checkisLocalRootLAMWInvalid)
	assertEquals 1 $?

	export LOCAL_ROOT_LAMW=/boot 
	ret=$(checkisLocalRootLAMWInvalid)
	assertEquals 1 $?
}
. $(which shunit2 ) 
rm -rf $HOME