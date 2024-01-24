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

testGetNodeAttrXML(){
	local xml_f="$HOME/test-nde.xml"
	local xml_s='<?xml version="1.0" encoding="UTF-8"?>\n<root>\n\t<message>Hello World</message>\n</root>'
	local message_node='//root/message'

	printf "%b" "$xml_s" > $xml_f
	local message_value=$(getNodeAttrXML $message_node $xml_f)

	assertEquals '[Get existent node]' "$message_value" "Hello World"
	local message_value=$(getNodeAttrXML '/root/message/@value' $xml_f)
	assertEquals '[Get no existent node]' "$message_value" ""
}

testUpdateNodeAttrXML(){
	
	local -A xml_node_attr=(['root']='/root/message/@value')
	local -A xml_node_attr_value=(['root']='make clean all')
	local xml_f="$HOME/test-nde.xml"
	local xml_s='<?xml version="1.0" encoding="UTF-8"?>\n<root>\n\t<message value="Hello World"></message>\n</root>'
	local message_node='//root/message/@value'
	
	printf "%b" "$xml_s" > $xml_f
	updateNodeAttrXML xml_node_attr  xml_node_attr_value $xml_f
	
	local message_value=$(getNodeAttrXML $message_node $xml_f)
	assertEquals '[Get node after update]' "$message_value" "make clean all"
}


. $(which shunit2)
rm -rf $HOME