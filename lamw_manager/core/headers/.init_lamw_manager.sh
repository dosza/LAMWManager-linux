#!/bin/bash
#-------------------------------------------------------------------------------------------------#
#Universidade federal de Mato Grosso (Alma Mater)
#Course: Science Computer
#Version: 0.4.1
#Date: 07/27/2021
#Description: The ".init_lamw_manager.sh" is part of the core of LAMW Manager. This script check conditions to init LAMW Manager
#-------------------------------------------------------------------------------------------------#

# Verifica condicoes de inicializacao
if [ ! -e "$LAMW_MANAGER_LOCK" ]; then
	printf "${VERMELHO}Fatal Error: you need run lamw_manager first! ${NORMAL}\n"
	exit 1
fi

ps ax | grep $PPID | grep 'lamw_manager' > /dev/null
if [ $? != 0 ]; then
	echo "${VERMELHO}Fatal Error: you need run lamw_manager first! ${NORMAL}"
	exit 1
fi


checkisLocalRootLAMWInvalid(){
	local invalid_paths=(
		/bin /boot /dev   /lib64  /lib /lib32 /libx32   /proc  /sbin  /sys /var
		/etc  /lost+found   /cdrom /snap
		/ /mnt    /home   $LAMW_USER_HOME /media  /root /tmp /opt /run /srv /usr{,/{bin,games,include,lib,lib32,libexec,libx32,local,sbin,share,src}}
	)

	for ((i = 0 ; i < ${#invalid_paths[*]};i++))
	do
	 
		if [ $i -lt 15 ]; then
			echo "$LOCAL_ROOT_LAMW" | grep "^${invalid_paths[i]}" >/dev/null
			if [ $? = 0 ]; then 
				echo "${VERMELHO}Fatal error: $LOCAL_ROOT_LAMW is a Filesystem Hierarchy Standard (FHS) folder!$NORMAL"
				echo "${NEGRITO}You cannot install here!${NORMAL}"
				exit 1
			fi
		else 
			if [ "$LOCAL_ROOT_LAMW" = "${invalid_paths[i]}" ]; then
				echo "${VERMELHO}Fatal error: this a Filesystem Hierarchy Standard (FHS) folder, need a  unique subfolder!$NORMAL"
				echo "${NEGRITO}Sample: LOCAL_ROOT_LAMW=$LOCAL_ROOT_LAMW/LAMW${NORMAL}"
				exit 1;
			fi
		fi
	done

	[ -e "$LOCAL_ROOT_LAMW"  ] && mountpoint "$LOCAL_ROOT_LAMW" &> /dev/null
	if [ $? = 0 ]; then
		echo "${VERMELHO}Fatal error: ${LOCAL_ROOT_LAMW} is a mountpoint!! you need a subfolder!${NORMAL}"
		echo "${NEGRITO}sample: LOCAL_ROOT_LAMW=$LOCAL_ROOT_LAMW/LAMW${NORMAL}"
		exit 1
	fi


}
SET_ROOT_LAMW(){
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
			ROOT_LAMW=$LOCAL_ROOT_LAMW
		fi
	else
		checkisLocalRootLAMWInvalid
		if [ -e $LAMW_MANAGER_LOCAL_CONFIG_PATH ]; then
			CURRENT_LOCAL_ROOT_LAMW="$(grep "^LOCAL_ROOT_LAMW=" $LAMW_MANAGER_LOCAL_CONFIG_PATH | sed 's|LOCAL_ROOT_LAMW=||g')"
		
		if [ "$LOCAL_ROOT_LAMW" = "" ];then   
			LOCAL_ROOT_LAMW=$CURRENT_LOCAL_ROOT_LAMW
		fi				     
				

		if [ -e "$CURRENT_LOCAL_ROOT_LAMW/lamw4linux/lamw4linux.log" ] ||  [ "$CURRENT_LOCAL_ROOT_LAMW" != "$LOCAL_ROOT_LAMW" ] && [ -e "$CURRENT_LOCAL_ROOT_LAMW" ] && [ ! "$(ls -v "$CURRENT_LOCAL_ROOT_LAMW")" = "" ]; then
				echo "${VERMELHO}Error: You cannot override ROOT_LAMW, before uninstall LAMW4Linux$NORMAL"
				echo "${NEGRITO} Ignoring  new LOCAL_ROOT_LAMW${NORMAL}"
				ROOT_LAMW=$CURRENT_LOCAL_ROOT_LAMW
			else
				sed  -i "s|LOCAL_ROOT_LAMW=$CURRENT_LOCAL_ROOT_LAMW|LOCAL_ROOT_LAMW=$LOCAL_ROOT_LAMW|g" $LAMW_MANAGER_LOCAL_CONFIG_PATH
				ROOT_LAMW=$LOCAL_ROOT_LAMW
			fi
		fi

	fi
}

unsetLocalRootLAMW(){
	isVariabelDeclared UNINSTALL_LAMW
	if [ $? = 0 ] &&  [ -e $LAMW_MANAGER_LOCAL_CONFIG_DIR ]; then
		rm -rf $LAMW_MANAGER_LOCAL_CONFIG_DIR	
	fi
}