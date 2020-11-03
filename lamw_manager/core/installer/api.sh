#!/bin/bash
getLAMWDep(){
	if [ "$1" = "" ]; then
		echo 'Need object arg!'
		exit 1;
	fi

	if [ "$(which jq)" = "" ]; then
		return
	fi

	if [  "$LAMW_DEPENDENCIES" = "" ] ; then
		LAMW_DEPENDENCIES=$(Wget -O- -q  "$LAMW_PACKAGE_URL" )
	fi
	echo "$LAMW_DEPENDENCIES" | jq  "$1" | sed 's/"//g'
}

setAndroidSDKCMDParameters(){
	SDK_MANAGER_CMD_PARAMETERS=(
		"platforms;android-$ANDROID_SDK_TARGET" 
		"platform-tools"
		"build-tools;$ANDROID_BUILD_TOOLS_TARGET" 
		"tools" 
		"ndk-bundle" 
		"extras;android;m2repository"
		"build-tools;$GRADLE_MIN_BUILD_TOOLS"
	)

	SDK_MANAGER_CMD_PARAMETERS2=(
		"android-$ANDROID_SDK_TARGET"
		"platform-tools"
		"build-tools-$ANDROID_BUILD_TOOLS_TARGET" 
		"extra-google-google_play_services"
		"extra-android-m2repository"
		"extra-google-m2repository"
		"extra-google-market_licensing"
		"extra-google-market_apk_expansion"
		"build-tools-$GRADLE_MIN_BUILD_TOOLS"
	)

	if [ $USE_PROXY = 1 ]; then
		SDK_LICENSES_PARAMETERS=( --licenses --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
		SDK_MANAGER_CMD_PARAMETERS[${#SDK_LICENSES_PARAMETERS[*]}]="--no_https --proxy=http"
		SDK_MANAGER_CMD_PARAMETERS[${#SDK_LICENSES_PARAMETERS[*]}]="--proxy_host=$PROXY_SERVER"
		SDK_MANAGER_CMD_PARAMETERS[${#SDK_LICENSES_PARAMETERS[*]}]="--proxy_port=$PORT_SERVER" 

		SDK_MANAGER_CMD_PARAMETERS2_PROXY=(
			'--no_https' 
			"--proxy-host=$PROXY_SERVER" 
			"--proxy-port=$PORT_SERVER" #'--proxy=http'
		)
	fi
}
setLAMWDeps(){

	export ANDROID_SDK_TARGET=$(getLAMWDep '.dependencies.android.platform')
	export ANDROID_BUILD_TOOLS_TARGET=$(getLAMWDep '.dependencies.android.buildTools')

	GRADLE_VERSION=$(getLAMWDep '.dependencies.gradle')
	GRADLE_HOME="$ROOT_LAMW/gradle-${GRADLE_VERSION}"
	GRADLE_ZIP_LNK="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
	GRADLE_ZIP_FILE="gradle-${GRADLE_VERSION}-bin.zip"
	setAndroidSDKCMDParameters


	#printf "%b" "$ANDROID_SDK_TARGET\n$ANDROID_BUILD_TOOLS_TARGET\n$GRADLE_VERSION\n${SDK_MANAGER_CMD_PARAMETERS[*]}\n"
}


updateLAMWDeps(){


	local need_update_lamw_deps=0
	setLAMWDeps

	if [ ! -e "$GRADLE_HOME" ] ||  [ ! -e "$ANDROID_SDK/platforms/android-$ANDROID_SDK_TARGET" ] || [ ! -e "$ANDROID_SDK/build-tools/$ANDROID_BUILD_TOOLS_TARGET" ] ; then
		need_update_lamw_deps=1
	fi

	echo "$need_update_lamw_deps"

}
