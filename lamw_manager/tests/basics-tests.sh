
#!/bin/bash

testLocalRootLAMW(){
	local lamw_manager_script=../lamw_manager/lamw_manager
	env LOCAL_ROOT_LAMW="" $lamw_manager_script
	assertEquals 1  $?

	env LOCAL_ROOT_LAMW=/home $lamw_manager_script
	assertEquals 1 $?


	env LOCAL_ROOT_LAMW=/media $lamw_manager_script
	assertEquals 1 $?

	env LOCAL_ROOT_LAMW=/mnt $lamw_manager_script
	assertEquals 1 $?

	env LOCAL_ROOT_LAMW=/ $lamw_manager_script
	assertEquals 1 $?
	
	env LOCAL_ROOT_LAMW=/boot $lamw_manager_script
	assertEquals 1 $?
}


. $(which shunit2 ) 