#!/bin/bash
TEST_MODULES_PATH=$(dirname $(realpath $0))
source $TEST_MODULES_PATH/tests-header
source "$LAMW_MANAGER_MODULES_PATH/settings-editor/templates/update-lamw-manager.sh"
export ROOT_LAMW=~/LAMW






test-get-lamw-manager-updates(){
	:

}

test-checkLAMWManageUpdates(){
	:
}

test-compareVersion(){
	
	compareVersion "0.6.1" ""
	assertFalse '[v2 empty]' $?

	compareVersion "0.6.1"  "0.6.1"
	assertFalse '[v1 == v2]' $?

	compareVersion "0.6.0" "0.6.1"
	assertTrue '[v1 < v2]' $?
	
	compareVersion "0.6.2" "0.6.1"
	assertFalse '[v1 > v2]' $?


}

test-trimVersion(){
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


. $(which shunit2)