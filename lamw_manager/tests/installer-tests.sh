#!/bin/bash
TEST_MODULES_PATH=$(dirname $(realpath $0))
source $TEST_MODULES_PATH/tests-header
export ROOT_LAMW=~/LAMW


testGetStatusInstalation(){
	getStatusInstalation
	assertTrue '[There is no $LAMW_INSTALL_LOG ]' $?

	mkdir -p $LAMW4LINUX_HOME
	echo "Generate LAMW_INSTALL_VERSION=$LAMW_INSTALL_VERSION"> $LAMW_INSTALL_LOG
	getStatusInstalation
	assertFalse '[There is $LAMW_INSTALL_VERSION]' $?
}

testGetImplicitInstall(){
	rm -rf $LAMW_INSTALL_LOG
	getImplicitInstall
	assertEquals '[Implicit installer mode]' $AUTO_START_LAMW4LINUX 1

}
. $(which shunit2)