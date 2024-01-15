#!/bin/bash
TEST_MODULES_PATH=$(dirname $(realpath $0))
source $TEST_MODULES_PATH/tests-header

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