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
	assertEquals '[Implicit actions mode ]' $AUTO_START_LAMW4LINUX 1

	echo "Generate LAMW_INSTALL_VERSION=$LAMW_INSTALL_VERSION"> $LAMW_INSTALL_LOG
	#simulate needUpdate deps
	isUpdateLAMWDeps(){
		return 0;
	}

	getImplicitInstall
	assertEquals '[Implicit actions mode ]' $LAMW_IMPLICIT_ACTION_MODE 1

	isUpdateLAMWDeps(){
		return 1
	}

	getImplicitInstall
	assertEquals '[Implicit actions mode Need Upgrade ]' $LAMW_IMPLICIT_ACTION_MODE 0

	echo "Generate LAMW_INSTALL_VERSION=0.5.9"> $LAMW_INSTALL_LOG
	getImplicitInstall
	assertEquals '[Implicit actions mode Need upgrade to latest lamw_manager ]' $LAMW_IMPLICIT_ACTION_MODE 0

	echo "Generate LAMW_INSTALL_VERSION=0.8.0"> $LAMW_INSTALL_LOG
	ret=$(getImplicitInstall)
	expected_message="${VERMELHO}Your LAMW development environment was generated by a newer version of LAMW Manager!${NORMAL}"
	assertEquals '[Generate by newer LAMW Manager]' "$expected_message" "$ret"
}

. $(which shunit2)