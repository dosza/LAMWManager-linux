#!/usr/bin/env bash

setLAMWManagerEnv(){
	LAMW_MANAGER_ENV+=(
		ROOT_LAMW=$ROOT_LAMW
		LAMW_USER_GROUP=$(stat -c '%U:%G' $LAMW_MANAGER_LOCK) 
	)

	if [ "$NO_EXISTENT_ROOT_LAMW_PARENT" != "" ];then
		LAMW_MANAGER_ENV+=(
			NO_EXISTENT_ROOT_LAMW_PARENT=$NO_EXISTENT_ROOT_LAMW_PARENT
		)
	fi

	setUseLamwManagerSetup
}

#Check if $USER is a sudo member 

CheckFlags(){
	newPtr ref_flag="$1"
	local flagFind="$2"
	if [ $3 = 0 ]; then 
		if [[ "$ARGS" =~ $flagFind  ]]; then 
			export ref_flag=1
			export ARGS=${ARGS//$flagFind/} # remove todas as ocorrencias de DEBUG=1
		fi
	else 
		for i in ${!ARGS[@]}; do 
			local arg=${ARGS[$i]}
			if [[ "$arg" =~ $flagFind ]]; then 
				export export ref_flag=1
				unset ARGS[$i]
			fi
		done
	fi
}

#Check if DEBUG flag is set 
getBashCMD(){
	
	if [ $DEBUG = 1 ]; then
		LAMW_MGR_INSTALL="bash -x $LAMW_MGR_INSTALL"
	fi
}




setUseLamwManagerSetup(){
	if [ "$USE_SETUP" = "1" ];
	then 
		isSupportedPolkit
		local support_polkit=$?

		if [ $support_polkit = 0 ]; then 
			USE_PKEXEC=1
		fi

		LAMW_MANAGER_ENV+=("USE_SETUP=1")
	else
		LAMW_MANAGER_ENV+=("USE_SETUP=0")
	fi
}


isRequiredAdmin(){
	[ $REQUIRED_ADMIN = 0 ]
}
CheckUserIsSudo(){
	if ! isUsersSudo $USER ; then
		export USE_PKEXEC=1
	fi
}

createCoreLock(){
	exec 4>$LAMW_MANAGER_CORE_LOCK
	echo "" >&4
}

createCrossBinLock(){
	exec 5>$CROSSBIN_LOCK
	echo "" >&5
}

deleteCoreLock(){
	exec 4>&-
	rm $LAMW_MANAGER_CORE_LOCK
}
deleteCrossBinLock(){
	exec 5>&-
	rm $CROSSBIN_LOCK
}
RunAsAdmin(){
	IsFileBusy lamw_manager $LAMW_MANAGER_CORE_LOCK
	setLAMWManagerEnv
	createCoreLock
	createCrossBinLock
	if [ $USE_PKEXEC = 1 ] ; then
		RunAsPolkit $*
	else
		RunAsSudo $*
	fi

	[ $EXIT_STATUS  != 0 ] && exit 1
	REQUIRED_ADMIN=1
}


RunAsSudo(){
	sudo -i env ${LAMW_MANAGER_ENV[@]} $LAMW_MGR_CORE_ADMIN $*
	export EXIT_STATUS=$?
}


#Run LAMW Manager as Police Kit
RunAsPolkit(){
	isSupportedPolkit
	if [ $?  = 0 ]; then 
		LAMW_MANAGER_ENV+=(DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY)
		pkexec  env ${LAMW_MANAGER_ENV[@]} $LAMW_MGR_CORE_ADMIN $*
		export EXIT_STATUS=$?
	else
		echo $error_msg
		export EXIT_STATUS=$?
	fi
	
	[  $ENTER_TO_EXIT = 1 ] && echo "press enter to exit ..." && read
	

}


isSupportedPolkit(){
	local error_msg="${VERMELHO}Fatal error:${NORMAL} Cannot run on tty terminal!!"
	tty | grep 'pts/[0-9]'>/dev/null
}