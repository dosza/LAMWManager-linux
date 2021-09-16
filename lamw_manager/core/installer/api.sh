#!/bin/bash
getLAMWDep(){
	if [ "$1" = "" ]; then
		echo 'Need object arg!'
		exit 1;
	fi

	if [ "$(which jq)" = "" ]; then
		return
	fi
	echo "$LAMW_DEPENDENCIES" | jq  "$1" | sed 's/"//g'
}

setAndroidSDKCMDParameters(){
	SDK_MANAGER_CMD_PARAMETERS=(
		"platforms;android-$ANDROID_SDK_TARGET" 
		"platform-tools"
		"build-tools;$ANDROID_BUILD_TOOLS_TARGET"
		"ndk-bundle" 
		"extras;android;m2repository"
		#"build-tools;$GRADLE_MIN_BUILD_TOOLS"
	)

	if [ $USE_PROXY = 1 ]; then
		SDK_LICENSES_PARAMETERS=( --licenses --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
		SDK_MANAGER_CMD_PARAMETERS+=("--no_https --proxy=http" "--proxy_host=$PROXY_SERVER" "--proxy_port=$PORT_SERVER")
	fi
}
parseJSONString(){
	echo "$1" | jq "${@:2}"  | sed 's/"//g'
}

setJDKDeps(){
	local jdk_filters_query=(".[] | select(.binary.os==\"linux\")|select(.binary.architecture==\"x64\")|select(.binary.image_type==\"jdk\")|map(.)")
	JDK_JSON="$(Wget -O- -q  "$API_JDK_URL" | jq "${jdk_filters_query[@]}")"
	JDK_URL="`parseJSONString "$JDK_JSON" ".[0].package.link"`"
	JDK_TAR="`parseJSONString "$JDK_JSON" ".[0].package.name"`"
	JDK_FILE="jdk-`parseJSONString "$JDK_JSON" ".[3].openjdk_version"`"
	JAVA_VERSION="11.0.`parseJSONString "$JDK_JSON" ".[3].security"`"
	JDK_TAR="`parseJSONString "$JDK_JSON" ".[0].package.name"`"
}

checkJDKVersionStatus(){
	setJDKDeps
	JDK_STATUS=0
	local java_release_path="$JAVA_HOME/release"
	[ ! -e $JAVA_HOME ] || ( [ -e $java_release_path ]  && ! grep $JAVA_VERSION  $java_release_path > /dev/null ) && JDK_STATUS=1
}

setLAMWDeps(){

	[  "$LAMW_DEPENDENCIES" = "" ] && LAMW_DEPENDENCIES="$(Wget -O- -q  "$LAMW_PACKAGE_URL" )"
	ANDROID_SDK_TARGET=$(getLAMWDep '.dependencies.android.platform')
	ANDROID_BUILD_TOOLS_TARGET=$(getLAMWDep '.dependencies.android.buildTools')
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

	if [ ! -e "$GRADLE_HOME" ] ||  [ ! -e "$ANDROID_SDK_ROOT/platforms/android-$ANDROID_SDK_TARGET" ] || [ ! -e "$ANDROID_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS_TARGET" ] ; then
		need_update_lamw_deps=1
	fi

	echo "$need_update_lamw_deps"

}
