#!/bin/bash

TEST_MODULES_PATH=$(dirname $(realpath $0))
source $TEST_MODULES_PATH/tests-header

testInitLAMWUserConfig(){
	initLAMWUserConfig
	ls -la $HOME/.android &>/dev/null
	assertTrue $?
}

. $(which shunit2)
rm -rf $HOME