#!/usr/bin/env bash

runLamw4Linux(){
	~/.local/bin/startlamw4linux &>/dev/null &
	sleep 0.01
}
autoStartLAMW4Linux(){
	local sucess_filler="starting ${NEGRITO}LAMW4Linux IDE${NORMAL}"
	if [ $EXIT_STATUS = 0 ] && [ "${XDG_CURRENT_DESKTOP^^}" != "XFCE" ] && 
		[ $AUTO_START_LAMW4LINUX = 1 ] && [ -e $LAMW_INSTALL_LOG ];then
		startProgressBar
		runLamw4Linux
		stopAsSuccessProgressBar
	fi
}

runAvdManager(){
	"$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/avdmanager" $@
}
