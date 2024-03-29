#!/usr/bin/bash

export PROGRESS_BAR_PATH="$LAMW_MANAGER_MODULES_PATH/components/bash-progress-bar.sh"

stopProgressBar(){
	kill "-${1}" $bg_pid &>/dev/null
	wait $bg_pid
}

stopAsSuccessProgressBar(){
	stopProgressBar 'SIGTERM'
}

stopProgressBarAsCancel(){
	stopProgressBar 'SIGUSR1'
}
stopProgressBarAsFail(){
	stopProgressBar 'SIGHUP'
}

startProgressBar(){
	$PROGRESS_BAR_PATH 0.2 "$sucess_filler" 1 $$ &
	bg_pid=$!
}