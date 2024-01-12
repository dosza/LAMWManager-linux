#!/usr/bin/env bash

GetLocalJavaHome(){
	local lamw4linux_env="$LAMW4LINUX_HOME/etc/environment"
	if [ -e $lamw4linux_env ]; then
		LOCAL_JAVA_HOME=$(grep '^export JAVA_HOME' "$lamw4linux_env" | sed 's|export JAVA_HOME=||g')
	fi	
}
StopGradleDaemon(){
	
	if [ ! -e "$LAMW_INSTALL_LOG" ] ; then
		return 
	fi
	
	local gradle_version="$(grep '^GRADLE_VERSION' $LAMW_INSTALL_LOG |
		 	sed 's/GRADLE_VERSION=//g')"

	local sucess_filler="stopping Gradle Daemons"

	local gradle_path="$ROOT_LAMW/gradle-$gradle_version"
		

	if [ "$gradle_path" = "" ]|| [ ! -e "$gradle_path" ]; then 
		return 
	fi
	
	GetLocalJavaHome
	
	if ! ps  -e -o command | grep "^${LOCAL_JAVA_HOME}.*$ROOT_LAMW/gradle" -q ; then
		return
	fi
			
	echo "${sucess_filler^} ..."
	startProgressBar
	
	if env JAVA_HOME=$LOCAL_JAVA_HOME $gradle_path/bin/gradle --stop -q &>/dev/null; then
		stopAsSuccessProgressBar
	else
		stopProgressBarAsFail
	fi

}