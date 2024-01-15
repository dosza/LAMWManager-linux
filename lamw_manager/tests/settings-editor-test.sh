#!/bin/bash

TEST_MODULES_PATH=$(dirname $(realpath $0))
source $TEST_MODULES_PATH/tests-header

testInitLAMWUserConfig(){
	initLAMWUserConfig
	ls -la $HOME/.android &>/dev/null
	assertTrue $?
}


testInitRootLAMW(){
	initROOT_LAMW
	ls -ls $ROOT_LAMW &>/dev/null
	assertTrue $?
}

testCreateLazarusEnvCfgFile(){
	local lazarus_env_cfg_path="$LAMW_IDE_HOME_CFG/environmentoptions.xml"
	createLazarusEnvCfgFile
	ls -la $lazarus_env_cfg_path &>/dev/null
	assertTrue $?
}

testAddLAMWtoStartMenu(){
	initROOT_LAMW
	mkdir $LAMW_IDE_HOME/install -p
	cd $LAMW_IDE_HOME/install
	wget -qc "https://raw.githubusercontent.com/alrieckert/lazarus/master/install/lazarus.desktop"
	wget -qc "https://raw.githubusercontent.com/alrieckert/lazarus/master/install/lazarus-mime.xml" 
	cd ..
	AddLAMWtoStartMenu

	ls -la $LAMW_MENU_ITEM_PATH &>/dev/null
	assertTrue $?
}
. $(which shunit2)
rm -rf $HOME