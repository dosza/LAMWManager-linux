#!/bin/bash
TEST_MODULES_PATH=$(dirname $(realpath $0))
source $TEST_MODULES_PATH/tests-header
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/templates/update-lamw-manager.sh" &>/dev/null
export ROOT_LAMW=~/LAMW






testCheckLAMWManageUpdates(){
	initROOT_LAMW
	
	wget(){ echo '' ; }
	echo "Generate LAMW_INSTALL_VERSION=0.6.2"> $LAMW_INSTALL_LOG
	checkLAMWManageUpdates 1
	
	assertFalse '[v2 empty]' $?

	wget(){ echo '{ "tag_name": "0.6.2" } ' ; }
	checkLAMWManageUpdates 1
	assertFalse '[v1 == v2]' $?
	
	echo "Generate LAMW_INSTALL_VERSION=0.6.0"> $LAMW_INSTALL_LOG
	checkLAMWManageUpdates 1
	assertTrue '[v1 < v2]' $?


	wget(){ echo '{ "tag_name": "0.6.1" } ' ; }
	echo "Generate LAMW_INSTALL_VERSION=0.6.2"> $LAMW_INSTALL_LOG
	checkLAMWManageUpdates 1
	assertFalse '[v1 > v2]' $?

	#test user notification
	rm -f /tmp/.update-lamw-manager* &>/dev/null
	echo "Generate LAMW_INSTALL_VERSION=0.6.0"> $LAMW_INSTALL_LOG
	checkLAMWManageUpdates 0
	assertTrue '[v1 < v2 and with a unique user notification]' $?

	echo "Generate LAMW_INSTALL_VERSION=0.6.0"> $LAMW_INSTALL_LOG
	checkLAMWManageUpdates 0
	assertTrue '[v1 < v2 and without user notification]' $?


}

testIsOutdatedVersion(){

	isOutdatedVersion "0.6.1" ""
	assertFalse '[v2 empty]' $?

	isOutdatedVersion "0.6.1"  "0.6.1"
	assertFalse '[v1 == v2]' $?

	isOutdatedVersion "0.6.0" "0.6.1"
	assertTrue '[v1 < v2]' $?
	
	isOutdatedVersion "0.6.2" "0.6.1"
	assertFalse '[v1 > v2]' $?


}

testTrimVersion(){
	local v1=()
	local v2=()
	local v1_str=""
	local v2_str=""
	local rv_limit=4

	trimVersion "0.6.1" "0.6.2"
	assertEquals '[Trim 3 digits]' "06100" "$v1_str"
	
	trimVersion "0.4.0.6" "0.6.2"
	assertEquals '[Trim 4 digits (4 digit less then 10)]' "04060" "$v1_str"

	trimVersion "0.4.0.10" "0.6.2"
	assertEquals '[Trim 4 digits ]' "04010" "$v1_str"

	trimVersion "0.3.3-r1" "0.6.2"
	assertEquals '[Trim 4 digits -r ]' "03310" "$v1_str"

	trimVersion "0.2.1-R1" "0.6.2"
	assertEquals '[Trim 4 digits -R ]' "02110" "$v1_str"

	trimVersion "0.6.1" "0.4.1.7"
	assertEquals '[Trim v2 4 digits less then 10]' "04170" "$v2_str"

	trimVersion "0.2.1" "0.5.3-r1"
	assertEquals '[Trim v2 4 digits -r ]' "05310" "$v2_str"

}


testGetLamwManagerUpdates(){

	checkLAMWManageUpdates(){ return 1; }
	getLamwManagerUpdates
	assertFalse '[No action is required]' $?

	checkLAMWManageUpdates(){ return 0; }
	wget(){ echo ; }
	getLamwManagerUpdates
	assertFalse '[lamw_manager_setup = '']' $?

	wget(){ 
		echo '{"assets": [ { "tag_name" : "0.6.2","browser_download_url": "https://localhost/lamw_manager_setup.sh" } ]}' 
		echo 'exit 0' > /tmp/lamw_manager_setup.sh
	}
	

	echo n | getLamwManagerUpdates
	assertFalse '[no run setup ]' $?

	echo y | getLamwManagerUpdates
	assertTrue '[run setup ]' $?

	wget(){ return 	1; }
	echo y | getLamwManagerUpdates
	assertFalse '[wget failed ]' $?
	


}



. $(which shunit2)