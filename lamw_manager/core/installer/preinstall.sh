GetLocalJavaHome(){
	local lamw4linux_env="$LAMW4LINUX_HOME/etc/environment"
	if [ -e $lamw4linux_env ]; then
		export JAVA_HOME=$(grep '^export JAVA_HOME' "$lamw4linux_env" | sed 's|export JAVA_HOME=||g')
	fi	
}
StopGradleDaemon(){
	local sucess_filler="stopping Gradle Daemons"

	if [ -e "$LAMW_INSTALL_LOG" ] ; then
		local gradle_version="$(grep '^GRADLE_VERSION' $LAMW_INSTALL_LOG |
		 	sed 's/GRADLE_VERSION=//g'
		)"

		local gradle_path="$ROOT_LAMW/gradle-$gradle_version"
		GetLocalJavaHome
		LAMW_INSTALL_LOG_CHANGES['INITIAL']=$gradle_version
	fi

	if [ "$gradle_path" != "" ] && [ -e "$gradle_path" ]; then 
		
		if ps  -e -o command | grep "^${JAVA_HOME}.*$ROOT_LAMW/gradle" -q ; then
			
			echo "${sucess_filler^} ..."
			startProgressBar
			
			if $gradle_path/bin/gradle --stop -q &>/dev/null; then
				stopAsSuccessProgressBar
			else
				stopProgressBarAsFail
			fi

		fi
	fi
}