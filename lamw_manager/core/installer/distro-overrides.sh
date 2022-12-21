#!/bin/bash

checkIfDistroIsLikeDebian(){
	local like_ubuntu_debian_pattern='(^ubuntu\sdebian$)'
	for distro in "${DEBIAN_FAMILY_ID[@]}";do

		if 	[ "$ID" = "$distro" ] || 
			[ "$ID_LIKE" = "ubuntu" ] || 
			[ "$ID_LIKE" = "debian" ] ||
			[[ "$ID_LIKE" =~ $like_ubuntu_debian_pattern ]]; then
				IS_DEBIAN=1
			break
		fi
	done
}


installDebianDependencies(){
	[ $IS_DEBIAN = 0 ] && return 
	getCurrentDebianFrontend
	checkNeedXfceMitigation
	AptInstall $LIBS_ANDROID $PROG_TOOLS
}
