#!/bin/bash
TEST_MODULES_PATH=$(dirname $(realpath $0))
source $TEST_MODULES_PATH/tests-header
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
	ping(){
		sleep 0.2
	}
	
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