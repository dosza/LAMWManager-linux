#!/usr/bin/env bash
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
		"extras;google;"{google_play_services,market_apk_expansion,market_licensing}
	)

	if [ $USE_PROXY = 1 ]; then
		SDK_LICENSES_PARAMETERS=( --licenses --no_https --proxy=http --proxy_host=$PROXY_SERVER --proxy_port=$PORT_SERVER )
		SDK_MANAGER_CMD_PARAMETERS+=("--no_https --proxy=http" "--proxy_host=$PROXY_SERVER" "--proxy_port=$PORT_SERVER")
	fi
}
parseJSONString(){
	echo "$1" | jq "${@:2}"  | sed 's/"//g'
}


setCheckSum(){
	newPtr ref_sum=$1
	local type_sum="${ref_sum['checksum_type']}"
	ref_sum[$type_sum]="$2"
}
setJDKDeps(){
	local jdk_filters_query=(".[] | select(.binary.os==\"linux\")|select(.binary.architecture==\"x64\")|select(.binary.image_type==\"jdk\")|map(.)")
	JDK_JSON="$(Wget -O- -q  "$API_JDK_URL" | jq "${jdk_filters_query[@]}")"
	JDK_URL="`parseJSONString "$JDK_JSON" ".[0].package.link"`"
	JDK_TAR="`parseJSONString "$JDK_JSON" ".[0].package.name"`"
	JDK_FILE="`parseJSONString "$JDK_JSON" ".[2]"`"
	JAVA_VERSION="11.0.`parseJSONString "$JDK_JSON" ".[4].security"`"
	JDK_TAR="`parseJSONString "$JDK_JSON" ".[0].package.name"`"
	setCheckSum JDK_SUM `parseJSONString  "$JDK_JSON" ".[0].package.checksum"` 
}

setLAMWPackages(){
	isVariableDeclared LAMW_PACKAGES
	[ $? = 0 ] && return 

	local lamw_pkgs_json="$(echo "$LAMW_PACKAGE_JSON" | jq '. |{packages:.packages}')"
	local max_lamw_pcks=$(parseJSONString "$lamw_pkgs_json" '.packages | length')
	for((i = 0 ; i < ${max_lamw_pcks};i++)); do 
		LAMW_PACKAGES[$i]="${LAMW_FRAMEWORK_HOME}/$(parseJSONString "$lamw_pkgs_json" ".packages[$i]")"
	done
}

checkJDKVersionStatus(){
	setJDKDeps
	JDK_STATUS=0
	local java_release_path="$JAVA_HOME/release"
	[ ! -e $JAVA_HOME ] || ( [ -e $java_release_path ]  && 
		! grep $JAVA_VERSION  $java_release_path > /dev/null ) && JDK_STATUS=1
}

getLAMWPackageJSON(){
	local error_package_json_msg="Error: Unable to get ${NEGRITO}LAMW package.json${NORMAL}"
if [  "$LAMW_PACKAGE_JSON" = "" ]; then 
	LAMW_PACKAGE_JSON="$(Wget -O- -q  "$LAMW_PACKAGE_URL" )"
	
	[  "$LAMW_PACKAGE_JSON" = "" ] && check_error_and_exit "$error_package_json_msg"
	LAMW_PACKAGE_JSON=$(echo $LAMW_PACKAGE_JSON | jq '.| {packages:.packages,dependencies:.dependencies}')
fi
}

setLAMWDepsJSON(){
	LAMW_DEPENDENCIES=$( echo $LAMW_PACKAGE_JSON | jq '. |{ dependencies:.dependencies}' )
}

setGradleCheckSum(){
	local sum=$(Wget '-qO-' $GRADLE_ZIP_SUM_URL)
	[ "$sum" = "" ] && echo 'Cannot get Gradle Checksum !!' 1>&2
	setCheckSum GRADLE_ZIP_SUM "$sum"
}
setLAMWDeps(){
	[ "$LAMW_PACKAGE_JSON" != "" ] && return 
	getLAMWPackageJSON
	setLAMWDepsJSON
	ANDROID_SDK_TARGET=$(getLAMWDep '.dependencies.android.platform')
	ANDROID_BUILD_TOOLS_TARGET=$(getLAMWDep '.dependencies.android.buildTools')
	GRADLE_VERSION=$(getLAMWDep '.dependencies.gradle')
	GRADLE_HOME="$ROOT_LAMW/gradle-${GRADLE_VERSION}"
	GRADLE_ZIP_LNK="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip"
	GRADLE_ZIP_SUM_URL="https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip.sha256"
	GRADLE_ZIP_FILE="gradle-${GRADLE_VERSION}-bin.zip"
	setGradleCheckSum
	setAndroidSDKCMDParameters
	setLAMWPackages
}


updateLAMWDeps(){


	local need_update_lamw_deps=0
	setLAMWDeps

	if [ ! -e "$GRADLE_HOME" ] ||  [ ! -e "$ANDROID_SDK_ROOT/platforms/android-$ANDROID_SDK_TARGET" ] || [ ! -e "$ANDROID_SDK_ROOT/build-tools/$ANDROID_BUILD_TOOLS_TARGET" ] ; then
		need_update_lamw_deps=1
	fi

	echo "$need_update_lamw_deps"

}
