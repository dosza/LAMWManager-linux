if [ -e "$PWD/lamw_manager" ];then 
	lamw_manager_script="$(realpath ./lamw_manager)"
else 	
	lamw_manager_script=$(realpath ../lamw_manager)	
fi

export HOME=$(mktemp -dt  danny.XXXXXXXXXXX)

LAMW_MANAGER_MODULES_PATH=$(dirname $lamw_manager_script)/core
source "$LAMW_MANAGER_MODULES_PATH/headers/.index"
source "$LAMW_MANAGER_MODULES_PATH/headers/common-shell.sh"
source "$LAMW_MANAGER_MODULES_PATH/headers/.init_lamw_manager.sh"
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

export ROOT_LAMW=~/LAMW
echo $HOME
testfindProxyOpt(){
	ARGS=()
	findUseProxyOpt
	assertEquals '-1' $INDEX_FOUND_USE_PROXY

	ARGS=( --update-lamw --use_proxy --server 10.0.16.1 --port 3128)
	findUseProxyOpt
	assertEquals 1 $INDEX_FOUND_USE_PROXY

}

testParseProxyOpt(){
	ARGS=( --update-lamw --use_proxy --server 10.0.16.1 --port 3128)
	INDEX_FOUND_USE_PROXY=1
	
	parseProxyOpt
	assertEquals ${ARGS[@]} '--update-lamw'
	ARGS=( --update-lamw --use_proxy --server)
	ret=$(parseProxyOpt)
	
	assertEquals "${VERMELHO}Error:${NORMAL}missing ${NEGRITO}--port${NORMAL}" "$ret"

	ARGS=(--update-lamw --use-proxy --gradle)
	ret=$(parseProxyOpt)
	assertEquals "${VERMELHO}Error:${NORMAL}missing ${NEGRITO}--server${NORMAL}" "$ret"
}


testTestConnectionInternetOnDemand(){
	ARGS=()
	testConnectionInternetOnDemand
	assertTrue '[Implicit Action]' $?

	ARGS=('help')
	testConnectionInternetOnDemand
	assertTrue '[No requires internet]' $?
}

testParseFlags(){
	ARGS=('NOBLINK=1')
	parseFlags
	assertEquals $NOBLINK 1

	ARGS=(PKEXEC=1)
	parseFlags
	assertEquals $USE_PKEXEC 1
	USE_PKEXEC=0
	ARGS=("")
	parseFlags
	assertEquals $USE_PKEXEC 0
}

testParseMinimalOpt(){
	ARGS=()
	parseMinimalOpt
	assertEquals "${ARGS[*]}" ""
	ARGS=('--minimal')
	parseMinimalOpt
	assertEquals "${ARGS[*]}" ""
}

rm -rf $HOME
. $(which shunit2 ) 