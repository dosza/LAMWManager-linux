#!/bin/bash
zenity_exec=$(which zenity)
if [ ! -e $LAMW_IDE_HOME_CFG ]; then
	zenity_message="Primary Config Path ( $LAMW_IDE_HOME_CFG ) doesn't exists!!\nRun: './lamw_manager' to fix that! "
	zenity_title="Error on start LAMW4Linux"
	[ "$zenity_exec" != "" ] &&
		$zenity_exec --title "$zenity_title" --error --width 480 --text "$zenity_message" &&
		exit 1
fi
if [ ! -e "${LAMW4LINUX_EXE_PATH}" ] && [  -e "${OLD_LAMW4LINUX_EXE_PATH}" ]; then
	zenity_message="lazarus not found, starting from lazarus.old..."
	zenity_title="Missing Lazarus"
	${zenity_exec} --title "${zenity_title}" --notification --width 480 --text "${zenity_message}"
	cp ${OLD_LAMW4LINUX_EXE_PATH} ${LAMW4LINUX_EXE_PATH}
fi
if [ ! -e "$IGNORE_XFCE_LAMW_ERROR_PATH" ] && [ "${XDG_CURRENT_DESKTOP^^}" = "XFCE" ] && [ "${DESKTOP_SESSION^^}" = "XFCE" ]; then
	export XDG_CURRENT_DESKTOP=Gnome
	export DESKTOP_SESSION=xubuntu
fi
