#!/usr/bin/env bash

checkisLocalRootLAMWInvalid(){
	
	local invalid_paths_pattern=(
		'^\/'{'$',bin,boot,cdrom,dev,etc,lib{,32,64,x32},'lost\+found',proc} 
		'^\/'{root,snap,sbin,sys,var}
		"^$(GenerateScapesStr $LAMW_USER_HOME)\/snap$"
		'^\/usr\/lib\/lazarus$'
	)

	local invalid_paths=(
		/mnt  /home   $LAMW_USER_HOME /media  
		/tmp /opt /run /srv 
		/usr{,/{bin,games,include,lib,lib32,libexec,libx32,local,sbin,share,src}}
	)

	arrayMap invalid_paths_pattern pattern '
		if [[ "$LOCAL_ROOT_LAMW" =~  $pattern ]]; then
			echo "${VERMELHO}Fatal error${NORMAL}: You cannot install in ${VERMELHO}${LOCAL_ROOT_LAMW}${NORMAL} !!" &&
			exit 1
		fi'

	arrayMap invalid_paths error_path '
		if [ "$LOCAL_ROOT_LAMW" = "$error_path" ]; then
			echo "${VERMELHO}Fatal error: this a Filesystem Hierarchy Standard (FHS) folder, need a  unique subfolder!${NORMAL}"
			echo "${NEGRITO}Sample: LOCAL_ROOT_LAMW=$LOCAL_ROOT_LAMW/LAMW${NORMAL}"
			exit 1
		fi'

	[ -e "$LOCAL_ROOT_LAMW"  ] && mountpoint "$LOCAL_ROOT_LAMW" &> /dev/null
	if [ $? = 0 ]; then
		echo "${VERMELHO}Fatal error: ${LOCAL_ROOT_LAMW} is a mountpoint!! you need a subfolder!${NORMAL}"
		echo "${NEGRITO}sample: LOCAL_ROOT_LAMW=$LOCAL_ROOT_LAMW/LAMW${NORMAL}"
		exit 1
	fi
}

getRootLAMW(){
	checkisLocalRootLAMWInvalid
	if [ -e $LAMW_MANAGER_LOCAL_CONFIG_PATH ]; then
		CURRENT_LOCAL_ROOT_LAMW="$(grep "^LOCAL_ROOT_LAMW=" $LAMW_MANAGER_LOCAL_CONFIG_PATH | sed 's|LOCAL_ROOT_LAMW=||g')"
	
	if [ "$LOCAL_ROOT_LAMW" = "" ];then   
		LOCAL_ROOT_LAMW=$CURRENT_LOCAL_ROOT_LAMW
	fi				     
			

	if [ -e "$CURRENT_LOCAL_ROOT_LAMW/lamw4linux/lamw4linux.log" ] ||  [ "$CURRENT_LOCAL_ROOT_LAMW" != "$LOCAL_ROOT_LAMW" ] && 
	[ -e "$CURRENT_LOCAL_ROOT_LAMW" ] && [ ! "$(ls -v "$CURRENT_LOCAL_ROOT_LAMW")" = "" ]; then
			echo "${WARNING_COLOR}Warning: You cannot override ROOT_LAMW, before uninstall LAMW4Linux, ignoring  new LOCAL_ROOT_LAMW${NORMAL}"
			ROOT_LAMW=$CURRENT_LOCAL_ROOT_LAMW
		else
			sed  -i "s|LOCAL_ROOT_LAMW=$CURRENT_LOCAL_ROOT_LAMW|LOCAL_ROOT_LAMW=$LOCAL_ROOT_LAMW|g" $LAMW_MANAGER_LOCAL_CONFIG_PATH
			ROOT_LAMW=$LOCAL_ROOT_LAMW
		fi
	fi
}

detectNoExistsRootLAMWParent(){
	if [ "$LOCAL_ROOT_LAMW" !=  "" ]; then
		NO_EXISTENT_ROOT_LAMW_PARENT="$LOCAL_ROOT_LAMW"
		local flag=1
		while [ $flag != 0 ]; do
			local current_parent=$NO_EXISTENT_ROOT_LAMW_PARENT
				NO_EXISTENT_ROOT_LAMW_PARENT=$(dirname $NO_EXISTENT_ROOT_LAMW_PARENT)
			if [ -e $NO_EXISTENT_ROOT_LAMW_PARENT ]; then
				NO_EXISTENT_ROOT_LAMW_PARENT=$current_parent
				flag=0
			fi
		done

		export NO_EXISTENT_ROOT_LAMW_PARENT

		if [ "$NO_EXISTENT_ROOT_LAMW_PARENT" != "$LOCAL_ROOT_LAMW" ]; then
			LAMW_MANAGER_ENV+=(NO_EXISTENT_ROOT_LAMW_PARENT=$NO_EXISTENT_ROOT_LAMW_PARENT)
			grep '^NO_EXISTENT_ROOT_LAMW_PARENT' $LAMW_MANAGER_LOCAL_CONFIG_PATH >/dev/null 
			if [ $? != 0 ]; then
				echo "NO_EXISTENT_ROOT_LAMW_PARENT=$NO_EXISTENT_ROOT_LAMW_PARENT" >> $LAMW_MANAGER_LOCAL_CONFIG_PATH

			fi
		fi

	fi
}

getRootLAMWParent(){
	if [ -e $LAMW_MANAGER_LOCAL_CONFIG_PATH ]; then 
		local current_no_existent_root_parent="$(grep '^NO_EXISTENT_ROOT_LAMW_PARENT=' $LAMW_MANAGER_LOCAL_CONFIG_PATH | awk -F'=' '{ print $NF }')"
		if [ "$current_no_existent_root_parent" != "" ]; then
			export NO_EXISTENT_ROOT_LAMW_PARENT=$current_no_existent_root_parent
			LAMW_MANAGER_ENV+=(NO_EXISTENT_ROOT_LAMW_PARENT=$NO_EXISTENT_ROOT_LAMW_PARENT)
		fi
	fi

}
setRootLAMW(){
	if [ ! -e $LAMW_MANAGER_LOCAL_CONFIG_DIR ]; then 
		if [ "$LOCAL_ROOT_LAMW" = "" ] || [ "$LOCAL_ROOT_LAMW" = "$DEFAULT_ROOT_LAMW" ]; then 
			ROOT_LAMW="$DEFAULT_ROOT_LAMW"
		else

			if [ -e "$DEFAULT_ROOT_LAMW" ] && [   "$(ls -v $DEFAULT_ROOT_LAMW)" != "" ]; then 
				ROOT_LAMW=$DEFAULT_ROOT_LAMW
				return 
			fi
			checkisLocalRootLAMWInvalid
			mkdir $LAMW_MANAGER_LOCAL_CONFIG_DIR
			echo "LOCAL_ROOT_LAMW=$LOCAL_ROOT_LAMW" > $LAMW_MANAGER_LOCAL_CONFIG_PATH
			export ROOT_LAMW=$LOCAL_ROOT_LAMW
			detectNoExistsRootLAMWParent
		fi
	else
		getRootLAMW
		getRootLAMWParent
	fi
}

unsetLocalRootLAMW(){
	isVariableDeclared UNINSTALL_LAMW
	if [ $? = 0 ] &&  [ -e $LAMW_MANAGER_LOCAL_CONFIG_DIR ]; then
		rm -rf $LAMW_MANAGER_LOCAL_CONFIG_DIR	
	fi
}