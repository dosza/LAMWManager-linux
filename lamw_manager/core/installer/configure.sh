#!/bin/bash

declare -i X11_INDEX=11
declare -i GTK2_INDEX=265
declare -i GDK_INDEX=278
declare -i CAIRO_INDEX=292
declare -i PANGO_INDEX=326
declare -i XTST_INDEX=328
declare -i ATK_INDEX=362
declare -i FREEGLUT_INDEX=366

declare -A LIBS_DEB_EQUIVALENT=(
	['libgdk-x11-2.0.so']=libgtk2.0-dev
	['libgtk-x11-2.0.so']=libx11-dev
	['libgdk_pixbuf-2.0.so']=libgdk-pixbuf2.0-dev
	['libgdk_pixbuf_xlib-2.0.so']=libgdk-pixbuf2.0-dev
	['libcairo-gobject.so']=libcairo2-dev
	['libcairo-script-interpreter.so']=libcairo2-dev
	['libcairo.so']=libcairo2-dev
	['libpango-1.0.so']=libpango1.0-dev
	['libpangocairo-1.0.so']=libpango1.0-dev
	['libpangoft2-1.0.so']=libpango1.0-dev
	['libpangoxft-1.0.so']=libpango1.0-dev
	['libXtst.so']=libxtst-dev
	['libatk-1.0.so']=libatk1.0-dev
	['libglut.so']='freeglut3-deb.so freeglut3-dev'
)



declare -A HEADERS_EQUIVALENT_DEB=(
	[$X11_INDEX]=libx11-dev
	[$GTK2_INDEX]=libgtk2.0-dev
	[$GDK_INDEX]=libgdk-pixbuf2.0-dev
	[$CAIRO_INDEX]=libcairo2-dev
	[$PANGO_INDEX]=libpango1.0-dev
	[$XTST_INDEX]=libxtst-dev
	[$ATK_INDEX]=libatk1.0-dev
	[$FREEGLUT_INDEX]=freeglut3-dev
)



RESUL=1
SOFTWARES=(
	ld
	as
	strip
	gdb
	gcc
	make
	git
	wget 
	jq
	xmlstarlet
	unzip
	zenity
	bc
)

LIBS=(
	libgdk-x11-2.0.so
	libgtk-x11-2.0.so
	libgdk_pixbuf-2.0.so
	libgdk_pixbuf_xlib-2.0.so
	libcairo-gobject.so
	libcairo-script-interpreter.so
	libcairo.so
	libpango-1.0.so
	libpangocairo-1.0.so
	libpangoft2-1.0.so
	libpangoxft-1.0.so
	libXtst.so
	libatk-1.0.so
	libglut.so
)

HEADERS=(
	$(<$LAMW_MANAGER_MODULES_PATH/installer/headers.txt)
)

MESSAGE_INSTALL='Install on your system the package equivalent to:'


showPackageNameByIndex(){
	local -i index=$1

	if [ $index -le  $X11_INDEX ]; then 
		echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$X11_INDEX]}"
		
		elif [ $index -le $GTK2_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$GTK2_INDEX]}"
		
		elif [ $index -le $GDK_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$GDK_INDEX]}"
		
		elif [ $index -le $CAIRO_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$CAIRO_INDEX]}"
		
		elif [ $index -le $PANGO_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$PANGO_INDEX]}"
		
		elif [ $index -le $XTST_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$XTST_INDEX]}"
		
		elif [ $index -le $ATK_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$ATK_INDEX]}"
		
		elif [ $index -le $FREEGLUT_INDEX ]; then 
			echo "$MESSAGE_INSTALL: ${HEADERS_EQUIVALENT_DEB[$FREEGLUT_INDEX]}"
		fi

}

printOK(){
	printf "%s\r" "${FILLER:${#1}}${VERDE} [OK]${NORMAL}"
}
printFail(){
	printf "%s\n" "${FILLER:${#1}}${VERMELHO} [FAILS]${NORMAL}"
	echo "Please, get more info in https://github.com/dosza/LAMWManager-linux/blob/master/lamw_manager/docs/other-distros-info.md#compatible-linux-distro"
}

systemHasLibsToBuildLazarus(){
	local -i count=0
	for i in ${LIBS[@]}; do
		printf "%b" "Checking $i"
		if find /usr /lib64 -name $i &>/dev/null; then
			printOK "$i"
			((count++))
		else 
			printFail "$i"
			echo "$MESSAGE_INSTALL:" "${LIBS_DEB_EQUIVALENT[$i]}"
			exit 1
		fi
	done
	echo ""
	[ ${count} = ${#LIBS[@]} ]
}



systemHasHeadersToBuildLazarus(){
	local -i count=0
	local libs
	
	for i in ${HEADERS[@]}; do
		libs="$(basename $i)"
		printf "Checking $libs"
		if [ -e $i ]; then 
			printOK "$libs"
		else 
			printFail "$libs"
			showPackageNameByIndex "$count"
			exit 1
		fi
		((count++))
	done
	echo ""
}



systemHasToolsToRunLamwManager(){
	local -i count=0
	for i in ${SOFTWARES[@]};do
		printf "%b" "Checking $i" 
		if which $i &>/dev/null; then 
			((count++))
			printOK "$i"
		else
			printFail "$i"
			exit 1
		fi
	done
	echo ""

	[ $count = ${#SOFTWARES[@]} ]
}


CheckIfSystemNeedTerminalMitigation(){
	[ $IS_DEBIAN = 1 ] && return 
	
	local desktop_env="$LAMW_USER_DESKTOP_SESSION $LAMW_USER_XDG_CURRENT_DESKTOP"
	local gnome_regex="(GNOME)"
	local xfce_regex="(XFCE)"
	local cinnamon_regex="(X\-CINNAMON)"

	if 	[[ "$desktop_env" =~ $gnome_regex ]] ||
		[[ "$desktop_env" =~ $cinnamon_regex ]] || 
		[[ "$desktop_env" =~ $xfce_regex ]]; then 
			NEED_XFCE_MITIGATION=1
			SOFTWARES+=(xterm)
			if [ $UID != 0 ]; then 
				>"$IGNORE_XFCE_LAMW_ERROR_PATH"
			fi
	fi
}

CheckIfYourLinuxIsSupported(){
	CheckIfSystemNeedTerminalMitigation
	if systemHasToolsToRunLamwManager; then 
		if systemHasHeadersToBuildLazarus ; then
			if systemHasLibsToBuildLazarus ;then
				RESUL=0
			fi
		fi
	fi
}
