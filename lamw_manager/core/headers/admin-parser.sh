#!/usr/bin/env bash


isRequiredAdmin(){
	[ $REQUIRED_ADMIN = 0 ]
}
CheckUserIsSudo(){
	if ! isUsersSudo $USER ; then
		export USE_PKEXEC=1
	fi
}

setLAMWManagerEnv(){
	LAMW_MANAGER_ENV=(
		LAMW_USER=$USER
		LAMW_USER_HOME=$HOME 
		ROOT_LAMW=$ROOT_LAMW
		LAMW_USER_XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP^^}
		LAMW_USER_DESKTOP_SESSION=${DESKTOP_SESSION^^}
		USE_SETUP="$USE_SETUP"
		LAMW_USER_GROUP="$LAMW_USER_GROUP"
		LAMW_MANAGER_LOCAL_CONFIG_DIR=$LAMW_MANAGER_LOCAL_CONFIG_DIR
	)
}
setDebug(){
	if [ $DEBUG = 1 ]; then 
		LAMW_MGR_CORE_ADMIN="bash -x $LAMW_MGR_CORE_ADMIN"
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
	createCoreLock
	createCrossBinLock
	setLAMWManagerEnv
	setDebug
	if [ $USE_PKEXEC = 1 ] ; then
		RunAsPolkit $*
	else
		RunAsSudo $*
	fi
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