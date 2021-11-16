
#!/bin/bash

testLocalRootLAMW(){
	if [ -e "$PWD/lamw_manager" ];then 
		local lamw_manager_script="$(realpath ./lamw_manager)"
	else 	
		local lamw_manager_script=$(realpath ../lamw_manager)
	fi
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