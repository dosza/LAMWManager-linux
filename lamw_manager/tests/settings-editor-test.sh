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

testInitLAMw4LinuxConfig(){
	
	local env_opts_node="//CONFIG/EnvironmentOptions"
	local lazarus_env_cfg_path="$LAMW_IDE_HOME_CFG/environmentoptions.xml"
	
	mkdir -p $LAMW_IDE_HOME/tools/install/
	echo "echo $LAZARUS_STABLE_VERSION" >$LAMW_IDE_HOME/tools/install/get_lazarus_version.sh
	chmod +x $LAMW_IDE_HOME/tools/install/get_lazarus_version.sh
	rm -rf $lazarus_env_cfg_path &>/dev/null
	
	initLAMw4LinuxConfig
	assertEquals "[Create default $lazarus_env_cfg_path]" "$LAZARUS_STABLE_VERSION" "$( getNodeAttrXML "$env_opts_node/Version/@Lazarus"  $lazarus_env_cfg_path)"
	
	sed -i "s/$LAZARUS_STABLE_VERSION/2.0.6/g" $lazarus_env_cfg_path
	initLAMw4LinuxConfig
	assertEquals '[Update lazarus version node]' "$LAZARUS_STABLE_VERSION" "$( getNodeAttrXML $env_opts_node/Version/@Lazarus  $lazarus_env_cfg_path)"
	
	sed -i "/FppkgConfigFile/d" $lazarus_env_cfg_path
	initLAMw4LinuxConfig
	grep 'FppkgConfigFile' $lazarus_env_cfg_path -q
	assertTrue '[Insert FppkgConfigFile node]' $?

}

. $(which shunit2)
rm -rf $HOME