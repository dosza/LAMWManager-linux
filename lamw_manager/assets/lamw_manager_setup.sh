#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3146838850"
MD5="c79fa6ff5fea03f3351b987b0a1ec165"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26628"
keep="y"
nooverwrite="n"
quiet="n"
accept="n"
nodiskspace="n"
export_conf="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

if test -d /usr/xpg4/bin; then
    PATH=/usr/xpg4/bin:$PATH
    export PATH
fi

if test -d /usr/sfw/bin; then
    PATH=$PATH:/usr/sfw/bin
    export PATH
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt" | more
    if test x"$accept" != xy; then
      while true
      do
        MS_Printf "Please type y to accept, n otherwise: "
        read yn
        if test x"$yn" = xn; then
          keep=n
          eval $finish; exit 1
          break;
        elif test x"$yn" = xy; then
          break;
        fi
      done
    fi
  fi
}

MS_diskspace()
{
	(
	df -kP "$1" | tail -1 | awk '{ if ($4 ~ /%/) {print $3} else {print $4} }'
	)
}

MS_dd()
{
    blocks=`expr $3 / 1024`
    bytes=`expr $3 % 1024`
    dd if="$1" ibs=$2 skip=1 obs=1024 conv=sync 2> /dev/null | \
    { test $blocks -gt 0 && dd ibs=1024 obs=1024 count=$blocks ; \
      test $bytes  -gt 0 && dd ibs=1 obs=1024 count=$bytes ; } 2> /dev/null
}

MS_dd_Progress()
{
    if test x"$noprogress" = xy; then
        MS_dd $@
        return $?
    fi
    file="$1"
    offset=$2
    length=$3
    pos=0
    bsize=4194304
    while test $bsize -gt $length; do
        bsize=`expr $bsize / 4`
    done
    blocks=`expr $length / $bsize`
    bytes=`expr $length % $bsize`
    (
        dd ibs=$offset skip=1 2>/dev/null
        pos=`expr $pos \+ $bsize`
        MS_Printf "     0%% " 1>&2
        if test $blocks -gt 0; then
            while test $pos -le $length; do
                dd bs=$bsize count=1 2>/dev/null
                pcent=`expr $length / 100`
                pcent=`expr $pos / $pcent`
                if test $pcent -lt 100; then
                    MS_Printf "\b\b\b\b\b\b\b" 1>&2
                    if test $pcent -lt 10; then
                        MS_Printf "    $pcent%% " 1>&2
                    else
                        MS_Printf "   $pcent%% " 1>&2
                    fi
                fi
                pos=`expr $pos \+ $bsize`
            done
        fi
        if test $bytes -gt 0; then
            dd bs=$bytes count=1 2>/dev/null
        fi
        MS_Printf "\b\b\b\b\b\b\b" 1>&2
        MS_Printf " 100%%  " 1>&2
    ) < "$file"
}

MS_Help()
{
    cat << EOH >&2
${helpheader}Makeself version 2.4.0
 1) Getting help or info about $0 :
  $0 --help   Print this message
  $0 --info   Print embedded info : title, default target directory, embedded script ...
  $0 --lsm    Print embedded lsm entry (or no LSM)
  $0 --list   Print the list of files in the archive
  $0 --check  Checks integrity of the archive

 2) Running $0 :
  $0 [options] [--] [additional arguments to embedded script]
  with following options (in that order)
  --confirm             Ask before running embedded script
  --quiet		Do not print anything except error messages
  --accept              Accept the license
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --nodiskspace         Do not check for available disk space
  --target dir          Extract directly to a target directory (absolute or relative)
                        This directory may undergo recursive chown (see --nochown).
  --tar arg1 [arg2 ...] Access the contents of the archive through the tar command
  --                    Following arguments will be passed to the embedded script
EOH
}

MS_Check()
{
    OLD_PATH="$PATH"
    PATH=${GUESS_MD5_PATH:-"$OLD_PATH:/bin:/usr/bin:/sbin:/usr/local/ssl/bin:/usr/local/bin:/opt/openssl/bin"}
	MD5_ARG=""
    MD5_PATH=`exec <&- 2>&-; which md5sum || command -v md5sum || type md5sum`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which md5 || command -v md5 || type md5`
    test -x "$MD5_PATH" || MD5_PATH=`exec <&- 2>&-; which digest || command -v digest || type digest`
    PATH="$OLD_PATH"

    SHA_PATH=`exec <&- 2>&-; which shasum || command -v shasum || type shasum`
    test -x "$SHA_PATH" || SHA_PATH=`exec <&- 2>&-; which sha256sum || command -v sha256sum || type sha256sum`

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 592 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
		if test -x "$SHA_PATH"; then
			if test x"`basename $SHA_PATH`" = xshasum; then
				SHA_ARG="-a 256"
			fi
			sha=`echo $SHA | cut -d" " -f$i`
			if test x"$sha" = x0000000000000000000000000000000000000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded SHA256 checksum." >&2
			else
				shasum=`MS_dd_Progress "$1" $offset $s | eval "$SHA_PATH $SHA_ARG" | cut -b-64`;
				if test x"$shasum" != x"$sha"; then
					echo "Error in SHA256 checksums: $shasum is different from $sha" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " SHA256 checksums are OK." >&2
				fi
				crc="0000000000";
			fi
		fi
		if test -x "$MD5_PATH"; then
			if test x"`basename $MD5_PATH`" = xdigest; then
				MD5_ARG="-a md5"
			fi
			md5=`echo $MD5 | cut -d" " -f$i`
			if test x"$md5" = x00000000000000000000000000000000; then
				test x"$verb" = xy && echo " $1 does not contain an embedded MD5 checksum." >&2
			else
				md5sum=`MS_dd_Progress "$1" $offset $s | eval "$MD5_PATH $MD5_ARG" | cut -b-32`;
				if test x"$md5sum" != x"$md5"; then
					echo "Error in MD5 checksums: $md5sum is different from $md5" >&2
					exit 2
				else
					test x"$verb" = xy && MS_Printf " MD5 checksums are OK." >&2
				fi
				crc="0000000000"; verb=n
			fi
		fi
		if test x"$crc" = x0000000000; then
			test x"$verb" = xy && echo " $1 does not contain a CRC checksum." >&2
		else
			sum1=`MS_dd_Progress "$1" $offset $s | CMD_ENV=xpg4 cksum | awk '{print $1}'`
			if test x"$sum1" = x"$crc"; then
				test x"$verb" = xy && MS_Printf " CRC checksums are OK." >&2
			else
				echo "Error in checksums: $sum1 is different from $crc" >&2
				exit 2;
			fi
		fi
		i=`expr $i + 1`
		offset=`expr $offset + $s`
    done
    if test x"$quiet" = xn; then
		echo " All good."
    fi
}

UnTAR()
{
    if test x"$quiet" = xn; then
		tar $1vf -  2>&1 || { echo " ... Extraction failed." > /dev/tty; kill -15 $$; }
    else
		tar $1f -  2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    fi
}

finish=true
xterm_loop=
noprogress=n
nox11=n
copy=copy
ownership=y
verbose=n

initargs="$@"

while true
do
    case "$1" in
    -h | --help)
	MS_Help
	exit 0
	;;
    -q | --quiet)
	quiet=y
	noprogress=y
	shift
	;;
	--accept)
	accept=y
	shift
	;;
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Mon Mar  7 19:12:32 -03 2022
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--xz\" \\
    \"--copy\" \\
    \"--target\" \\
    \"$HOME/lamw_manager\" \\
    \"/tmp/lamw_manager_build\" \\
    \"lamw_manager_setup.sh\" \\
    \"LAMW Manager Setup\" \\
    \"./.start_lamw_manager\""
	if test x"$script" != x; then
	    echo Script run after extraction:
	    echo "    " $script $scriptargs
	fi
	if test x"" = xcopy; then
		echo "Archive will copy itself to a temporary location"
	fi
	if test x"n" = xy; then
		echo "Root permissions required for extraction"
	fi
	if test x"y" = xy; then
	    echo "directory $targetdir is permanent"
	else
	    echo "$targetdir will be removed after extraction"
	fi
	exit 0
	;;
    --dumpconf)
	echo LABEL=\"$label\"
	echo SCRIPT=\"$script\"
	echo SCRIPTARGS=\"$scriptargs\"
	echo archdirname=\"$HOME/lamw_manager\"
	echo KEEP=y
	echo NOOVERWRITE=n
	echo COMPRESS=xz
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=160
	echo OLDSKIP=593
	exit 0
	;;
    --lsm)
cat << EOLSM
No LSM.
EOLSM
	exit 0
	;;
    --list)
	echo Target directory: $targetdir
	offset=`head -n 592 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 592 "$0" | wc -c | tr -d " "`
	arg1="$2"
    if ! shift 2; then MS_Help; exit 1; fi
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | tar "$arg1" - "$@"
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
    --check)
	MS_Check "$0" y
	exit 0
	;;
    --confirm)
	verbose=y
	shift
	;;
	--noexec)
	script=""
	shift
	;;
    --keep)
	keep=y
	shift
	;;
    --target)
	keep=y
	targetdir="${2:-.}"
    if ! shift 2; then MS_Help; exit 1; fi
	;;
    --noprogress)
	noprogress=y
	shift
	;;
    --nox11)
	nox11=y
	shift
	;;
    --nochown)
	ownership=n
	shift
	;;
    --nodiskspace)
	nodiskspace=y
	shift
	;;
    --xwin)
	if test "n" = n; then
		finish="echo Press Return to close this window...; read junk"
	fi
	xterm_loop=1
	shift
	;;
    --phase2)
	copy=phase2
	shift
	;;
    --)
	shift
	break ;;
    -*)
	echo Unrecognized flag : "$1" >&2
	MS_Help
	exit 1
	;;
    *)
	break ;;
    esac
done

if test x"$quiet" = xy -a x"$verbose" = xy; then
	echo Cannot be verbose and quiet at the same time. >&2
	exit 1
fi

if test x"n" = xy -a `id -u` -ne 0; then
	echo "Administrative privileges required for this archive (use su or sudo)" >&2
	exit 1	
fi

if test x"$copy" \!= xphase2; then
    MS_PrintLicense
fi

case "$copy" in
copy)
    tmpdir="$TMPROOT"/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
    mkdir "$tmpdir" || {
	echo "Could not create temporary directory $tmpdir" >&2
	exit 1
    }
    SCRIPT_COPY="$tmpdir/makeself"
    echo "Copying to a temporary location..." >&2
    cp "$0" "$SCRIPT_COPY"
    chmod +x "$SCRIPT_COPY"
    cd "$TMPROOT"
    exec "$SCRIPT_COPY" --phase2 -- $initargs
    ;;
phase2)
    finish="$finish ; rm -rf `dirname $0`"
    ;;
esac

if test x"$nox11" = xn; then
    if tty -s; then                 # Do we have a terminal?
	:
    else
        if test x"$DISPLAY" != x -a x"$xterm_loop" = x; then  # No, but do we have X?
            if xset q > /dev/null 2>&1; then # Check for valid DISPLAY variable
                GUESS_XTERMS="xterm gnome-terminal rxvt dtterm eterm Eterm xfce4-terminal lxterminal kvt konsole aterm terminology"
                for a in $GUESS_XTERMS; do
                    if type $a >/dev/null 2>&1; then
                        XTERM=$a
                        break
                    fi
                done
                chmod a+x $0 || echo Please add execution rights on $0
                if test `echo "$0" | cut -c1` = "/"; then # Spawn a terminal!
                    exec $XTERM -title "$label" -e "$0" --xwin "$initargs"
                else
                    exec $XTERM -title "$label" -e "./$0" --xwin "$initargs"
                fi
            fi
        fi
    fi
fi

if test x"$targetdir" = x.; then
    tmpdir="."
else
    if test x"$keep" = xy; then
	if test x"$nooverwrite" = xy && test -d "$targetdir"; then
            echo "Target directory $targetdir already exists, aborting." >&2
            exit 1
	fi
	if test x"$quiet" = xn; then
	    echo "Creating directory $targetdir" >&2
	fi
	tmpdir="$targetdir"
	dashp="-p"
    else
	tmpdir="$TMPROOT/selfgz$$$RANDOM"
	dashp=""
    fi
    mkdir $dashp "$tmpdir" || {
	echo 'Cannot create target directory' $tmpdir >&2
	echo 'You should try option --target dir' >&2
	eval $finish
	exit 1
    }
fi

location="`pwd`"
if test x"$SETUP_NOCHECK" != x1; then
    MS_Check "$0"
fi
offset=`head -n 592 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
	
    # Decrypting with openssl will ask for password,
    # the prompt needs to start on new line
	if test x"n" = xy; then
	    echo
	fi
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf "$tmpdir"; eval $finish; exit 15' 1 2 3 15
fi

if test x"$nodiskspace" = xn; then
    leftspace=`MS_diskspace "$tmpdir"`
    if test -n "$leftspace"; then
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
            echo "Use --nodiskspace option to skip this check and proceed anyway" >&2
            if test x"$keep" = xn; then
                echo "Consider setting TMPDIR to a directory with more free space."
            fi
            eval $finish; exit 1
        fi
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
		fi
    else
		echo >&2
		echo "Unable to decompress $0" >&2
		eval $finish; exit 1
    fi
    offset=`expr $offset + $s`
done
if test x"$quiet" = xn; then
	echo
fi

cd "$tmpdir"
res=0
if test x"$script" != x; then
    if test x"$export_conf" = x"y"; then
        MS_BUNDLE="$0"
        MS_LABEL="$label"
        MS_SCRIPT="$script"
        MS_SCRIPTARGS="$scriptargs"
        MS_ARCHDIRNAME="$archdirname"
        MS_KEEP="$KEEP"
        MS_NOOVERWRITE="$NOOVERWRITE"
        MS_COMPRESS="$COMPRESS"
        export MS_BUNDLE MS_LABEL MS_SCRIPT MS_SCRIPTARGS
        export MS_ARCHDIRNAME MS_KEEP MS_NOOVERWRITE MS_COMPRESS
    fi

    if test x"$verbose" = x"y"; then
		MS_Printf "OK to execute: $script $scriptargs $* ? [Y/n] "
		read yn
		if test x"$yn" = x -o x"$yn" = xy -o x"$yn" = xY; then
			eval "\"$script\" $scriptargs \"\$@\""; res=$?;
		fi
    else
		eval "\"$script\" $scriptargs \"\$@\""; res=$?
    fi
    if test "$res" -ne 0; then
		test x"$verbose" = xy && echo "The program '$script' returned an error code ($res)" >&2
    fi
fi
if test x"$keep" = xn; then
    cd "$TMPROOT"
    /bin/rm -rf "$tmpdir"
fi
eval $finish; exit $res
ı7zXZ  æÖ´F !   ÏXÌâÿgÁ] ¼}•À1Dd]‡Á›PætİDø”/«M`û
h åÆ•j¾¯¢~¹Û¯›!`ñÎsšçìGS¤ÅYPşĞn7ämùş6x('G‡:igˆ—÷ë~â;ÓÒ©ë…·)â‡n]ğ­Õ®ÅÏ~›¨*~Ø€)j(ƒ›ù£³&}¹¥¨h`Måjmæ›ÇĞ£‹«jP˜bÊH|øôï½îPµ8IÂ"éš$Ş¼Xœ>Û©	‚ÃÖ°ì’)<<ŞêcYÄ¼ X_ xşĞYf9ËÀÂT|ŒBH4tê	äÜÈÙ×:Ñ4Ÿ:¬Pâ…3¯â¯`EPû­àeà™‰†üå6JÏÊüó‘eiE'½lL5úâ3ÙêŒg‘t(¥iÛäQÔRødØ×ôÔŸ–”X›C¥¥Ôwà,ÊÁ¥<¾şË+şâß˜|5p™XU°}¿/‹+ a‘J8ıÎ´S^œ!zïté‚şuoåİìùóİÄ7í©ˆ	ñfLb[Gvä4¢c²S4ı,Ğ•&¯¢“7Ø
ùX»H(nğDXj¼hN.R'?lŞ#ÃµªYËH_oá‚ˆ'ÚÛ.˜Åé«âcõuEªehp]‡÷Ëaf±/^Ø‹"n›êÃïÌ2¡ÖÙ„4¨^T¹°eÀË¦.»¼œ~ŒãpYác^© üü&wa¾éÉn`ÔD9â€¢ÂŸ2.Éç31'½RÌPM	¼_ª	À=¯;AÊ“^ĞÓ¤
®óãº›Í)h`ô/¢6«×cšP=¡­Åûuúr<¸‘«î£kB¿Š3’-Ô××ÜdåÆ{dç“Zu¸I,R7_}ú1GãöˆÜÒly±£DÁõ¾
¤ôû&Mz+¨¼Åd>6b·¸#ó2ìÛ*­dÿ^QL%˜_«‘üËb_á]CB[¸5¬E5€àéeğQì¾ÆÍ·”*"åT¦¹¨o3]AUíHÛç§'¤\%ö(®ëªªa‰™u‡	G'Eßµ_vÛ ç~0ğÔv3ÿ…Ñ¢F¨¿·au×••'¢Ÿ^ğríÅ˜H4&p½÷d;Ÿä°¢;€5í¤)eæœ·ËØ`Íæá©ÃòÌgü…\|³A k˜‘WÙ›ÙL~Í‹‹Ç(¿ÍâG.V»DI”Y[ƒèJÕ^êË§Ô¨ëcĞiü‹¤¼_>Öë–§ÖÑ³édx¥IW/S\·ÚŒÍ…"üúqÏcÕ¡Ù×x—ïéı°b£8‹È×Â£_ é!Ì²»?o‡±çÃªÓáĞõÀ/éĞ¨Š­a¹Æ`w&¶×Ê§ùiíwì$†£.ê6;˜SIêºO†ÓÜd#ê²%OAÊÁe!K³>‚•šôÆá3aLÿvÌ–u`DM0BMÄ©²î·lá3ü*ÚñöjëÌÛávlÏ“®bO
ê)ªØòOnµ‰¡Œ}ù®bˆÏ—3´»¥£b©İBø2t%™›;¶’Ì© ì8©Z¾Şuæ«È¶0ù{±ğlécw@èTÙ‡JÇ µA÷3sZÿ…îH©Õ™r,à¤*|¶6XVì;RB@0ùÏ¤eš„_×Oe"@h&›á>Ó=¬!W[É‰³9²€»µxÅo]ªMx'°eªº•°’÷Ó¡;ƒ­³…<ò#E.·äKU{»û.­àhë|¦©mg¡j¹Ëì4hóš¨vÜC,±Õó—)O,¤"ˆã|l§Ü#IÜ¦õÚ‰ñ“?€“ng*°×ÿ†«X=­øÃgÂ8¥ÔPÀRŞ½ÓN™i¢‹OØµY µv«î’X¢1¸™ºCõ>BÜ(« FGÿv¹°RÂr
(ë (ü“*05zâH/œïüñVµÔ†!Ú	êµU”yÈğ=Ã´÷L×2Np"¤³k·àÎñÌ!-ëŠ(·‘êÎŒßf+hê1ŒÚ5nšr)GÖ}L%ËÖÂL„ïÛrÛ›¬‰ÈLo’Ïk„n†p¯”h¿ >¥ìšŸ´f&0J‰èyv
İ»©’ªÛš^é÷ÏM4yUc„Ö‚¢[Ò]
	åBÂ©K<®X²Â™ç„ô`\İÙŞIV4ì˜À“¢gp·¯-m·yˆ°„kuùzpq€øßö“çÕoåÆpÄ–ğ¼+§eŸŠÆZiİ÷=M‘æP<¸go9úVEZÁ&A˜%¿zqÅ¾ßÕİ
ßòÛW&[@½~¿ãØ@Ìúî½˜‹¹tPÆôíHÔù5b9?Œ7*€ÉXÕVeï6(—88ä"¡óäOMV’V¸(ä¥^ÆÚŠíÁgœXjuŞÕ9Û;óãWÍ>ÛzÌß3Ëñ‡"ŒàÎê¬ïÈz¼Øé¤ÄB¥÷âñœD[ÚFM (çŠ´è^IìsPù™äÿ:7Ğ/ä×¡(Ê‹ÿ•t:‡öo2€ÜgÚëVJbÄ%&NœH&¥)Mí@<hÉhOg² Åk+IÀ~C¼+@	‰‘^%M ™íÂ\ug£táJø‰Š†«5E/KÌY.brûáXê½:Él©Å­¼¯òOq2š—4zünŸ¼8ÎşT.ìQcÉèƒ²"c¥âı@"%UCóˆ	@K’ÌÄz¸9RëšZÏö zÖb½˜m§.ÙtÑl,³o|f~l<¹¬XYş‚ZËYQd&ƒf"ñ1C¨®Ù\‘X~zwm{±ùÀ¢k¤…ËÊ`€š…x±;=/ÙµúJn<D–®
şÒH-C8&Õ”_ä4J–b®¶;Ë\2¹ûvöÂÊÌ‘WdÌÊ!šãJ	¡şõÚğIÁÈƒˆğ}öZLw¿BÑvÀ3á%€³y—W9‚ãbş„ïîZ^“ã¯+A
ÒÏÉ	“Şåõœó¹]ƒ„ß^š–é¿•"ÂĞgâ	5UlLì5âê#PçÅ=<á©^“/Å„°¡üº˜Q†«ºîd…$Ê;î58ÇƒÖ]aÍåşâ18/A™¸Êh$"/’c,åz<¢ñšê±qüïCxXÛå[uÿ‚	/fÑØgGã~]mÊÚÚcfbÉïZ›qé'÷Hl¢K|SƒæO%SIø‡<ˆ­¹z ƒ„ïøWnqĞñê•–·z2OêûgîL•:E9/W§oÒ÷ƒ#*£8½·3HÎ¥ûØI©îîT V¯y"µïJçnë4³7ãK4±‰šªScz§çk3­oğˆøˆ¶eé’ÂÊœRU«D5|µÙı,„!R¢ÈË«€¸DR-^h¨øyİ”Şsï uzDÁ´Œ)Ï¤ Åtø³ Şƒ£˜;K*ä`K…­ªÛ&~ĞÂ¦JÇG†ãkYÊÓú¥ˆä˜ûµ¡ÂŞ·'ƒ•‚âæZPn=#{(M4ÖŠæştê×L²rˆ™£:ëDP·”iqs¡/JÚé•ã=<Ü>´Ş[}h%"d˜¡(bE6çfŒğ;–ìCJİ]µ—Ú«šj4ªˆù7†ü#0×b T@ CQ8Ç£ÛúO>´;kÑö³ö¨$p=O³cÊİ<²Ş÷S%0,5ÑRwğÈ5å'¢gcáò,ÏC '
ş½K’³†yÔKÖ¼€! …Šm`Æurpş6£Íí/+0!³¢†¸a¡_÷ñÚÈue
ÓÇõ6†]Îd… qW´R4¡6t(„Û+˜;|àğñ¢{~šy6;‰/	d Ğ¢‘`åõ"üQ>ñÔ,×§†å±˜Ü‹–ñp)Ì2²œAÚà»ËŸ€ˆBhÁÎ[ÔmïÿqYâì}ô•ÿ‹hå‘ƒTï®e
É•}Ù¥J Piü’’ĞcÆ•ˆßìµZQ_Ó0ã„²´µ¤=qçîçº]Òf—§cø”3?›$æ!A³¢Â= Ñ¥­ôq¬1!—iîö…gFè½ ”gYW~«Z+˜<—V}ßsÀ°i‡³SÌÉ®Nc4İh}ĞIƒe<^Â[WJ&ò­Jz™áh¥ÃûcÉ¼e…™9[Z¬}^¹Jú}Ê#e˜Êãşd¥³cûmù‘èÈó*_?W+T`õF"ˆ5aôÁOjºZ#¹tÃÒÎ©“s
&îäòDn6{_¶Qµ?ºlò›”Êosv®ReªsL7dì<,„MeĞüY¯ñSÀğƒh%‰\lÖ~€aø Å–Yª=÷ñX±Ö^‰Æ8¯ÙùÛjBAÖ)ZÀcñ¼¬ö;İ«Ê/¨¡¿Ü+ |k¤ÀĞâ?íˆPEÏ‹D¢ØymA],I¸!iŠUàÀµX•pÏ‚Nàr†¢d+.bèäRü.ú†ìæäK*n(ËY]¢ãæ¢w†‚Vi&9
(l«r>‚îe8ÜLépïİ5‘ºp¾…ìÆ¸ÈsdZ4,Ì"õ)“Ÿ„¿³Õ¬šRöùÇÛ– U¾ô¸Çå÷ S™’ )ôE%.¦D$õ¾÷ŠöşÑ­ãåÀÈã}²Ëœÿ†»^!GŸ&6n1ª+Ùv’½f!«&ô,1üş ™P¼/]à$êb\wvœÃµìaı·Â¶ù-Èy!³ÇU*á¹iÜĞóÀKE\O“øó4cÄ;$Œò>)%ùe™K#µ~=bé8o‡((¢*^16“|9£dyaIã´ƒpÖy]/¦PG©Kß'^+}s‹ìµ‡5ùÆ7cá£×qÜŸhÀAøR(¦4ÛO?a¸2Å’®ã¥õÍIgÒøèŠ+òÎ¸û ¼ê§yÓœhœDæ…ÁJAŞLÁ;³c‚ÜiÂrÓ•Gµòé‚ØFvPŞTåëËğN‹Gk’ªd‘.u\y¬¨WÉ\è‘ÄN-ÅÓ›ƒidª;´†È!o´¥'ø9?¹î#ª<c¨xƒBÏbÏÊ¹£o+¾d0Íıg^¹’¤Â"b¿›¬Èq›ù£µŸSğÖ9^Ü˜çePØJCæÑª»yäÒ} RÌØÿ˜ºr<š4 ¸
87”°3àÍğÇJ4°˜S*^8DÜ9XoïÉ|Ï¬Q‹“¿0j"•fãuĞ {7‡­?šx½ÅsşVNÃi¡öqá„ôBìu%ÄlJvµzŞâ
çSw¹®bi8\¾ßÂl™Ï)ú1œ$[4R‚œÈ†w0jñ*ùqæ„N˜°!V5J>èjÏ™X–Qô±ösóÕ€,àu$.>;¸©¤¯²~Z(Ù<ËÁÂÑ:Oô:n«ŸÑaÖ¿È9—Èì¶€ X²"ÿ°Kv_¢á@x5®±Â˜ Hó€`+ ªr½_xxÅôô‡µÜ>z¬£fq¼ÓI> €…î–HüÁ­lı‘wOx„¨áVßyÀ*Á;Üc­5Š@âû«ÿèÒ`•‚r+„ƒ`,:~Öğ7ïôÂH`´yf$M·Âç“îY¹¿r¶ùA4¼¨HzØNØ5ŠØÏøQØ˜š:Éh}aÒL‡zƒAßüÍ¿+ëïñPIùØ¯ùW\ªGGxÆSâˆOù«¦;]b‡“|§Vä¾1R‘¿q‹JOFåÙ®Ï	Ìİæ3§43aÄFŒª %Ôşßƒ1U÷Ø0«sYÈ?)gk®¦&ÃÓ‡ÜDUX@¿Mk‡ :_A¼:;iæ}ºãÈh¶¡ñœ£›š—]u’mj£×H³İ£'jœ
¸fĞc"½iªWUY!2™`,IeB]ÜKÇ–¼‰|k¢6H˜¹²¶—%á_:Äæ¡tí„°_È¤k¶”)Ù{ÕÔp)s7r½ìû‡ØPÏÉ¯©Ú6ÿ„OÅ%îIéè&Ò}O”ŠyœÍÑï,Ç·yZ5w„!GfŒW’˜•ÌÑF®íüJå9Ó·­	Ù)ÛÆ¬‚£²EUa'½.,üaGĞŒ‡D½g4¨÷ÎÂº÷Ì8¶tèİ‚ÌÒ¥K/dš	–˜Ç!mpBp!3'/È%OYb¤ L–Š‡z¯øcuÖ€Ò1F††4NéL‘<-ÌrÊ$¨{ò1ñê#Œû]ºlÕi-DåP°‡‚ryˆÀªíŒmÎ(o\ÜfEAã°Vi£‰I>ôB.3‚4U¦læ¬ü»nØhéüOY¸ªâ’A
ˆúÊ£§ZuêÕj\u?úQ5W'uAõI;hRëZE¤mÑVó6lyì]ˆG½İe–VŒ:ÂJ(º‡ª /¢’²Ü¹tQ\ÂÊÆ¯n–Ô*ücí‰X¯Oørğ‚0•÷?—TëUÍRÂF'¢Öõ¤ÓÎÓÊ‡Wş®—[*0×öÃpŸı47% –¦gÁÕg\ÛJ;öƒJÕ†œq;Z3I…WhÚ¨¯Ê¹ï±ÖBoE²—Î;$	+élœXƒìÇe—k©–×øı>@î’ó/‰—08ÜI“Å¡Ğ9ğáĞÇ
%tVÍ ŞHk•Õä¿µŠüúÇ|´€Bc}ÔoÊÏüãƒ×µşË|o¼ÕùMÙ9‘*4,íî¬ÓhˆÓ“*¦5WUQô'¸£8‡…ƒK—ÉêtÒôyõgÚªÒ
¶J!=±]_¥N68ñÓ¿>Ä	ÌÇ!0Øeµÿ‚x•*t¾ qí$íßJ]r§œD¥)”Ç3Z}ˆ’Öœìı0Á›òn3äÊºH­vÇÿ¾3+G“"w3ü}öl*Eı¡r=`‹6€¢UÒ4ÓYUç¡›.ç–4]m´r:÷…6JúÕ\m¯
”eœıÕy^'ú2dıü8İ–Ö$Ş8ËÑ0öÒ€)ªìéŸÕªä#ø­
1pKİ¾Ñt>_í!éàu€@üRÁ‡	²÷ä‹6bÔc{Oª›ƒ\–“„,ÉÄ,XOç$½‘*¶^…£“:nÿ]‚dX¯ÜQØ³*€Lyg
Ì«G!ÿçşåå'á›‡4Áˆ„k²íáíu¦ÅádÅHÁGä¤$À“‚õœÓBe`Àéş¨úuºÇ»Çc³dº',9×šyÙwıµÆ÷Or–¨ûçïL=ÅèšÖ¥û õ$!ñ‘‹ªÚá™&EV]Gb3´úv>£òxŞeÔœQu.D¤~5tÈPCHk§Ä	õ“Î?,î¯*ÓV]¾VØg”9åê…6Ô_¾`ƒ’`¡5!¢&Uşš7¯Ø”f·Ù‡„l¨í,C;ÿynÎi FÚ³T&­Ğn9Ad\ö”ªùß€Ø«o–VôY<=fòƒ†91ˆÓ¦ïb 8|ÍÓc\Ô¿’ƒ—”KîfhñŠte
ÁGÁ®â¥R Ö¹+É’=~<UÆËÄ4C‚Ûã‡ã'Pİ[pÃ¸¬x¬“Ìt´•Šê§¨M†Øm÷yñ7JŠÃşhb‹h_²-Æ%ùz²Ü*—Èã>C›$?F*¬¡]üÈ*œÃÃÜp§Ê¶ë“Yív«B÷†ìsƒÂX—Htaü…‹+½Úağ­WØ
®oâ¨»<SÖâIƒU©Dàd4é)D™Íïş•¯ş8–H„ÌŸ?{ÚàÇu~Z
ÛÑ”Xm%^ù­>A—€^Œõı>
´åCÓŞ½j,%l4Z¦hnMZÚ»±M¦Ï¯r¨’EÅ4İ×iyd¯¹÷çh ‰K]šºäkº*ì=òPäï|~È,œ4(ËÑã¨¸ì÷Y9 Á4~)D¬ÙO}¾ºT5Ş9Í$¨	bE¸'©¬µp!åÖ÷ğù<ïpK	­è«IÕ],É>½là¹3Æ—~”‰òJ £DĞÕ-rìSˆ¿öÀ“?4–°^uÃï$acN{°~\n—Qö*º©‰:ëõ½[fcl[Èú-Ş1ü¼Ñ„œq¶8»§¢³vÎ5r“è˜kïŠ-ù!ÍÎ4²™B M€fñÏN©ÕÕ^^ı„;‘ôã-GL>’ÁÉğHÑWï&·˜\=À@·f©¢†by+çªM×é0æhŸ‰Ê)®5;5[b2[©poTS¤Š Åá¾¶#ÌVr¶B¹®¬qŒ[Â¶êfL©W§]ZDyÙÉ”ú³–½J*s</Pi/:„Ü5üN'Ğà”ÙÌ3ãÄòØ“0"ŒQî^Xâ÷o-¬ÍÙùçbè%(yD^Š½ñçÊó«Ö°Q'ñÙTó[º¨¯ápGbVîÉŞ¡SÒŠl5»éæJ1f—™cIL%eŠTóRÈÜe,¯j_¶<<º6X¤Æô‰¢<×gvİ'{É{0f˜õ¨ğ6&f³tùåß½u¨$`. Qš“nç@¤ÀØ¼¯²ÑtP¹Ü»òÛl±àõf¥ì6#t?­>½Åhd+$ÊGDË_S?ÆÂµ¢¯ µÉ.=	¶(utš¶_G_o.ü,‹Ír|(›~£½ªœXI’nÓ¢ ±4õh¿~
Ü¯ÃÏäºŒw4÷»"ÖÏ±ÜºRÒbiw%ÒøM%ÎËªÜ= ´¶óÑu W­¼Îo€ïúù@(Àµ¤¹Çà)ezj_"\µ.^&U“ÄÅ™E÷¹B€ÎõÖëde¬•H”N‚,ÀØÖ¿Í‰ß’Sö	.$C<¯BÕt@U˜ËŞÌ+P6è­Tïiºïc§ôÇ!ÈMX>kŠ±•	Èşê¦Z-çôÿsZOvÕ½`(t?K8Œr½®:Oôh{},¤^Âó	ñÀÜÓÑ¹şª©‚ $Øœ×ÎKYbâ~Fr§=…0«µÊbP{aí«ÉÅó³,ã÷cŸ%XNX£04œ1X*P›bn¥Ø)O>ö·ö;y,_¢÷Ó	@=T' GĞ¬³cÌXø:Õ{9O…ôt3hò%xéÍ cõºù×æo¥›„Ç„ßjSŠ¨äG$è~JØçUÁZZcŠë=cÕõjuF~E¯OÈ '9Æœ’üÿ8öN¯EjÉ„@‹Ø)4çìõğEô¥¯Ú)£Õ:öÿÅ·ß´g6ÇÆX'‰@&Ø<œ§”<CcÚU7¤şÊ’Ò¢£p–Ù*ôl3g¿—ùsL)»V„ıÃxmñD"9 Ş!¦Ì»Æ<õ	×A^ï÷˜äºcÜûXò=%ÑÀ°%—¯PĞ ”‘„l¨2Í[-Õ|F<ZZ=^¸¶¶fç«í_İT*c8°`^5ıù/'OŞYK¾ˆƒ'}Å“h×1QŸ¿™ÿdùÍ¾€gÒ>…jñë­áŸZ’¡‡,"P¨mpIs…`³°G±ÎÔ`ÍVdª=eóœ¨]‘šk_Ví¥"®|}½ü‡Û´Ê,Bx4¨]×F-Q§Zø~áØ2Âàı~(HŞY‡bJwå‚%è¦™Û1§FğsÃ¾²Àş¹>OC@²1|ÙRÕë»QGAÓmmF5Oƒebî[¡aŞC˜]6Ä€«Y
ÃôĞ›^´fÚ‰ÙŠ ÷RXğ\…ÍhF8[šAìnÜ´m/¦%±¡¯¥\õ]y¤k×Dhò€tõ+»Ô·:ùt˜™[ì0]¸Ğ·§[ê=õà[¬\Ha8ÛmÑ€ş ¯aw÷×ñên´èrpésh¬ƒ°ÚŞ¹Íö®º¶s±ñ¼ºÖ_ELğ(¾¥“"€èH«"~~ €Ç²&mïå«	•Åtİ´SL+R‚(C;dÿ6¯ÜN½­öÜŒ~É¶	6µs»ÅB~œ[¢±Ò-™Óe™¢Pì¿êÈö†ÎõÒ)|cÁf|‡x˜ğ™Áv=5B;„1ÓWø¾²Í@g»
f•Š Ğ3Hwô‚›¦Ç`Ä÷0è
&ç¿hileo²X5¥7„9(²ÜëÅk°,Æa¯“\h:FÁÀ_5ğÄô’´f¯$µ%¨\‘ÕÓq˜</ı•$³eÇÏÆZô)æš&†âB”€İ£Ùƒ> ìTÏ`¼¥…	6ŞÓ*±YÍ‹+D’ï°ë+ÏB†úò~Øé|Nµ;ÖJ­)Ñ K!ZvÚ[+U]3IÓ¡3l€íh¬=}×•GÿØS˜0{z{5`Óq¼yã~c²:!	èË©Ñ]í3VšJ+‡òó;ĞT>YAÓ(~|»?¥k¶_d÷­!t;ærøå¢›g–¿()¸HÄ?õ¤Ë†î§•—.»`XcY1.w/;ÏEiæ6‚|8eÎ ™ML/¬:rL««f@ı+ÕÑZPúŠFmk¬ÌªÒÿààÀ¢>ŞÒ#‹Æˆø‡ß€r^½u«)ËUÍ«¦€}gpç3tKËa>gN¶}‡È×r$#Z›êöV>ñ¾$èûïv«¼ìÀ>Y³Cµ¯3gN€àÏ#ÁfXFM«š‹UÈ Bñz9Áñ;®9'’í;FJ-Ñ™dúŒFrê˜¹¿{Ş
”æF“üèëú‡$@ğ~§wóP…pÊÜ:Ø0ŸÜµİ0ïk)+ÑWx[Â\‚àx7ØáÚK1n˜Ç7Ü•–†úÂØg?©Ê|ı–Mù’Tû4ªï¡ŞqGdñˆ°€·…%¥x5ªˆ[Ÿ"…ˆëR7Å­Ûk3m~êÇàvI~İöØ¿[_{í2I`„ãŞ4l_ëÃºÊÕ˜RAãÈ¿ˆ&2z†Êc˜
ãq›,Q³IÌ…¾ßÌÁhRa
t™D;
ŠÛIºıB`o%Î;4|»¥/»%!“E@Û‹Zöà‰>ÄØrSˆ¯÷_şjÅŸŠRWT·§XlŒ å£©KóÌİ‰œ"\;>	§ïŒ|7ÄQë(o%&RhÔ_˜}E2SÁ|Ha6ø6Æt.ÔãúÂà	Ş!ÃL5FWaè37¢vlÒwû8íbè[,â­Ç ¶ßõõıÙìŸŞD¤È„¿7«áíe¥™wµÀ0²4\qf4òlz#zRd‘eù×lÒb›‹Û¼Ï0P)Wø&ÑüaÆ”ƒ#MwG³çõà[‚Èûz£xnŒ¿I`j•¢¸Z/©Ğ_«ú¢–°Hv*û{ÁšC=|mh¶›
"ëvEŸoéÔ’¹a0Ü¸Yuœk)Ty–E‚¶äĞx§r«|3ûÂ˜ÑÂrMöˆ<axı¸D‚©;ô¾IUÚÇÎè?&ƒWUPv»OiıiN6êß3–œsö¶Õ„¦üÅ¹İñĞ^Uİ;¹y·# åÛíGÂıDgÛÿ€?Jœ
@c]7ªr©.
X}{î„A;ŠèÖ]é}÷·24ñTü´“işÀ9­B×ÍœPß{©±X%2 #·ÜQ–	!õm¶­Õø%‡%á´hP×}ª©fá¿Ãú;@76’ß¶Y½«oœ¾÷¦Z±ÍÜŠx4ïZÃ¯T)›Ùç¥S%ğˆHl2ÊÎV9VUX*ÜõÅPçu‹¥SdTíº¶Î—	¤’’uVv"H
4~*5’›V„X”qª¨A^BÌğ%ÕhiBbÚrq¸•´°7Ø­mÍIŒpäàqì°¶¢(ÏßÒü}˜ÕÏäìâİeº%4CÎåqU¢UB´'x¹æ×»ÂHê­t]à´QºãÖr"”Ó²®}oğˆ°~–4<$Vé(õ°x}Bn#8 z<Jø¸Ña9X9—÷º½H`lÍúE^ô®õé]m°2…t
Pa¥KÄ½3Ucş¸Æ«!sS~°J ÒÈèuá.Cº•¢İÀ…cyœYŒkxo ¢iÖüÛ% 5	)æô%ßÒ"
sAÆåVúÒO„Š¼V¬¢Ñ*f²ÔĞ8mçyÿ‡p?Qç«Ë¼T0}ÓJyê|¦Óîˆmèº‰e’º”Mieû÷F,¹ÌÉª Lß›2qÁÆµlÁ½C%³WşŒ4VøÃğÄİğãTª,1Ú}mølk>sè0ìUÊ²0ğyw%QøÛiÕÂÄ×õã‡XÿØsäc³0w„rŠ²å¶ˆÀ%T:…x°R£—PEkÇoÑªØ6®udqS¨¯Ê÷Áp[ŠäzÎ{+š¢×CğcÒ1Şá= 	Ğ²q¼òœ÷Ì¥¬Ğ#û§l®@!ĞšX\…øäÒø†¿Ô½5^¸CÉ`­V,œÂÿú«ıÉ^KŸ¦ÆJÏ¤-xŠÎ›Öì±_«Ì‚‹j_uÇd,ÙÇ,ôÌª¤†gcHŠ;t²KN¢HZİ ²ô+jBÒãQvæ/¡ùÌ5>yKç¶É>?nŠ5‹7ú#Ç‰ğ¸®7vh
ƒ–•eœ1È]ë¢^r´OßPgÎ)¢¨§§ó|ï‘u:ä^$fCX¼¦QSú­œÿqª)CC˜'¾)ù‘ÏzOJğ7¥çP§GC{nì|N—§v›ÊÎ‡í5`¹äL„Õè èñGñ¯oäFiÚñ[É6…,$_ãÿüˆNİi `!oìR$™ªHì¹ö­Š˜k¬iZp= Ï_æ›RçÏ ^d¢-ÓÓ/s R"×š—ÿöH|#Q©|p›HN7à’¡<´âJ\R	fĞİÔbÒÓ¸šË!0h,V5ÜÉÚ¡/äwÏéÖ!ÈÕgò¢µoZD!lû¨Ì4?‚ãuõÈ>ö{Í§b{¨£Şºî/¾·¦%7üĞl>¾Ç°"=Ú-€±mÛÔÿx%1YT¡¾K·ºËÖ›ÄáQi,Î‰n	ê­˜îšzÓ6õŒ×İï+¨ÌöÕÆÀÜ¦BS·ŠôQ^è^Ø‘mÆBòöêóK°êÜë.¡«ÏÙE‚¯ËM+g%Åã0™qõš†¿ ZãÊ±¾èi@°1¸‡Ãf£(Æíİ‰`U÷i½rk—âK$l‡·4¢·Å­!ÈFšÊ+9ìc‘¶Yd†¶FƒÀÃÅSÁ¿ ìAÒ"IO¸ä@yÔq:ùƒmßm§øJŞ&©sCÉ>™#aƒîGı7®ïO“Çóp`ùà\ïm­ßÕM.qkÏ¦‰aZ(Æúª1/‹}ÙşbØ(0éô]iÉDF+š”Òi+­zğ|[Cµ/ái„¤ª®=³»$ÕM²bxÀ5«‰ƒp9yP>Æº¶8ıl’0µë0³•à|§¥ì÷Ô)Ø!÷bŸoÒ²fàfDúVH•;ër›øúâûoíù©Õà®ßwâë404ÜNĞLÆÌEt8K¶¯i5×ÙIù™»ƒ„6ÈÉ °bDF{•dÙOïœêòv\”—o£Láºò@ÙfCÊ'pwçÇy™ÑÒÊR<*ñ.Ï-õ‚“>¦}…‚İÌVLZ¸FxÕ¸éÜ–nS3‹ÿvDí{²JÅs‹ ¯3AíE0ÆĞ“½„õ!*œ´É”k^¨>X3 øÊO1œËÉğ)ROÚW‰thóü@}nˆ‹`ÎFó“–*³¬nÑ>vk•¤<´¥u¡ãC	mÈI>êuXa+,şpG¶öæsev«$¨½y4>+}¤²¢Dâ¸A¬®×Ü»¬´Ùkh,Ù§ùEs/š~»â¥?¨õ–d`DbÌ:Îcá´1œ;åÃ¸¾	@x‡Y(*~«HëÜøáÿÊÌCŸpµZ’Rı?/®%UÙQlßî¥
ßO%c iÚ¨Õ}¿%¢ÊDù»iË©É/4)`Å'iŞã$óùı¡Ù 3
qĞêiÒzî¥É$°
5J^˜ŒŠÅ–„¢çtÍ¡|tŠfeÌ­*°Në>`¸Ú?}Æü=CÂê0Ò¶¢:P‚¢Ü©ÓÕ#RU—G¥P› ÀÁ$œÍÄO(ÅÍæ2Š_+)ê66Q UZY»ùwÌVÑJ>ÀÍT(1•«ó!Ş8aáşß»ª¯o•†mø9t ‰@ë…øÅÒ2;§¶qÊV€½³ÉäV¯DB@ªw¼XÕ­Zd0y a¸!ó( ß¦"»|Pô‡F¥©§;0j¸€´4Ö{8I"ÆÆVR¢ß Q’ÿ?8‹š–’¾ì;R/hd%mÔ‘ÚÀbjú0gœò'øíLšªı‹3ùî·‰¿ÚĞã˜‰İnÄN¹˜g^D
½‚ªAoò”;Èv?,w8Ó;ByOì8Äı .İ]ê<YRê>YaötÄÉµ³OàiÏ8èËzW:/Š¹­‚ÌşóÉÖÊ÷`&=#‡¸ÜÁªò$g¾Õ$êí$èÇ«òÉfv¼”K”¨²İŠrnğ=	Huİ)ã„¡
NÕç}Èùë'Ú–±‘‚Ñèü€C˜ãßâ/A	/å¢#T¦Ï¢x6'
ä`tğ–™[>W¸“Š‹V[çûoÜİ‰* -Ãx?‰4æëğ_á7ª-«z¾{EB%©XÈ&Jkß¿ˆ„ÓÇF b@Ÿ	yÓî@ÍŸö%ß®W‘Ò¿–£29]ı€ì”N”÷ëäƒ«Ç^›5O&ñ+ñ:/îê›|J0ÕÍ»ÇÑS¿«BpÑ·~&Ô™ı?Wè2h?bDWŞ6!ˆsà›	8*ZÍK™–™;º}·s.èôv‹“¼«’Á¤¸bk[×Ú€rXñıZ¥ŞŸç…³Âe{Ô¦é|EŸJ)ü`Æôù[*ã³¼$š4ë.ÄğìÔí›†êÏ^ÚW‡óÿ\’²³NGßåá½‰¨» ®¾Û/ş‹Ó¦ñÜÆgÕıÕ+DÆÒwæıu¿ã7bØ¹é9õ9‘^fÀ©"	­q¹9âL•W`)¨D±Pìf*aª Òã™IBæI@L
ÔşÏÉu)KN–õ©0tí¾Ô˜W¬tu@x&Í®ûGĞ¸¶ÈC-q¶µ¥#(.?0+éOVn÷YÈRµç‹})1jhïfË¸¡ô¹[D¼°ñQ½7ŞÙ–DüÇüÈÆ­5]¤W<)Øe\’=~Ñke4&TÀÊcR&Ãìùı)¹ÎMQMçã9ƒ—g½˜Ø©‰.z¨ñ+ÖNû&'jl ÃºÊ§¯y­Å
ÖİRXÉ¦â¾4&…´`ÙUu™;İ±%×Â>àÅ¸'½¥èEœˆ{Å™ÇºÉ‰§65Å:†ÓLtR–À™ßdjÜñ±(KšBáú«j—4îì@úĞwMÍ1¦¼Úò‡sÂdñè=±Ò°›¥\IbÕetô#snà1È,[ª¼Ú‚Õ)©œ®îwn^ºòñH–dº¶võèÜ)ö'Êá$¢ŒÇ6¡_’’.Šs_/‰ú_şğ·â–å²fYğ`¿ÚxÕ¯ÀyğŸ?µ%™–Md€ÑYòíıT–mS	došìÖDîRˆÇ÷³jµ¡7yø6Ã£—NiRjÀUXØî@ÒU¯ï	*yXW¾½L•GyŞcyo:Ñúdöçªş»LŞa*k+cr]£ÏÚ!ÏC5O£2ÍÙG qX÷–£’nÊï"4éiÓåD[ğ©`ú¾¾„ÎßbâqÊ7|uŸ›å0;hrOÅvg3®"ÒYXòÏ#f¦ß†„&U4èš7<ÜHõÁÛ¶ÏI¡ªÏÁŒÇRuH›¡½Úÿ¹PöuğîØ c! V¸×ËH2î¦²m,$§[Ã	¹ú'–~ÀV¬ñøœX,:ÀâùÙvX(Ur	 ¸Cøg?rwÀê+)'i´Ùò¸¬Ã“z¨Ÿˆ,ß®oÔ} ñåĞ~€Ô¥Xc\"Hv$Â?ÖIê! _7®81rÌ~WQcØ»59UMÔ÷)BX7ÆµU$™S5º°;rGiWHëAI5êS®¬‹13†XOú¤Wí;Ôœ¼×•„­Wuo¾Š$»wİcuéî[?)¼(>öÄHïXyoË¨MZ)Äê9È4</Å$“‡XB×WBß§R`'kC·ò!ñ-fã8ı›Ÿ Õ"Ÿ*úyõÎ2àÀ	Á¿t*b€¥è™èÁ‰kk~æ~3§(èşH]Jaçì:m9ÅÁš]k6"Vãˆã:E%SÉºü!ªO®n[!±)7?&®xPgã3°p\aÆÇ3»Ğ•^*t´ÔòB'NBßì\/*Uü#M”«E%¶¶¯ÿš¥¶ó„ƒ7fÆE?ì?¯7—*ÃÛ&—\ìá
qš‰2ãÜ™BY¶|as¥®ßLÍ^XÇ›ïÂëQ—¦ÿ“

3ëh¤f³'Ş¦[dô‘å´üVoÍŒ¢Ç#$
¡ô/ó€üü~JpL/B|Ü ¨SùVªFSA.¤şÏÿ·CÀW`ª&®ÄÍŠw.ø†'­XáWı¼ùñ—á“›¡'bBh„ı3%^…?U;áAIÚùä}Á‡¯¾¼bTf5¬/)IÂU­çİ˜L”~½lµÃ„–äO[º¼ïãï»—¼yKãPÓğŒ{.Û‰ú	jÒø¶\Öµúj6:¹:!¢¾E”lïègŒôşáoàIP<…üd¸$“c³‘ı6k†´3ıŠÑ–ÅTBK€UMûeHû½NŸµ´gT«:Í‹70àO¿Ä™Ñ”Ö¡Íßg
.gÆoM¢‚8»‰SRÇvHµ—3±‹
ÍehèªÍ3}/B¾™ °c^w™Ì´¬œ„e¸U$ù?’X]T1jZR9ä@š¡r > ğõ,¥7Np±(3HÚİÿS¡ˆùÁ{F¿m–´İ
«ÛV_{“y:]"õ}Ò•@æ:°GqWqİœè?#- öìEÆÍ);ÍÓ?yu®-C D8º—3^ıPSòÈÔãÙµ&½Ä£`ˆ¸Ë~½t¯^ƒÒvYÿ‡K<¨yG÷âêQ®¼Wœõ‹äÌÂnö|Ÿ­oâè¦u,Kxım+N…8‘S.r½­¬¢ˆ~°Ÿ#*HÏ.n_Aºì—rÅElN õëİ”Cƒ¯ğZ½şõ‘ÅÕŸYÃ³£ÿ-•ÌŸ[1ú{ŒB·²íÉYõ²À£n/·O•¯ôg9p†R¬õ…µ…+uá)«qÈri{…•DÖ“^ş]ğÎ>Ïü¶*lÉr§‡¦¥ÎXüa,®ğÜ±´sâ ‰Û¥@)˜]ÂpœôìM“L&X	ĞKÊ¶„-pŠXDQgÿaãlís»¨É/RèıåK­…ìL=ä´´ã¿v­ì*)Œ–˜Ì<uà+ak¶Gâ²¡¥*Ié¾HI™•jdÃ'¼{_)o2½ÔrÒGßÊ´<!è–Ğş¼Ç¤F%íæ‰ın 0©­•‰´Î
2`É×¼Ì7Ssë¬íÓÁ»$ú³÷±º*†è´g±À)›Ø¬OV¥‡òó¤E„ÖNV°àÅ*ÍtÛfş]¥}l¿_Ã(]ùÅÿ½]p|*Şÿ~DO|“d‰óë±Ğ¼Ê$$”_s³ÕÇ3O®RoÜÿş¬rk{ÙŠ?Ÿúr;²Ÿû©ÍÄÙ?eôı-4Ì65RÑº	ØXÄ8üö¦7áÄ‘u>ÄÛªåõnWfz7•gq21¡!£ÁÖˆçç2öa9‰©1ı¼ôœ*¿–@{xUL_Í,ø=D›ıQ]NæCkÂ¬6Å²ñ-&¢nmğrjVQÅ\îóû‹[Ã`ƒ*—]±V¼Ã™]Ö£ qà®áTâ×Ya!‰àF¢˜#a¹U‡Ü=;T+èÉq„ºL¨<\–Y•¯æš2úe2bfÕörhÈôLátr>ËÅÈë1ÔgÇßsCu/÷úaİr¾òıÚèìŠ-©.·üØ.‹€N¡K•¯¡š«O›¨,Òã‘ªT·´p"õ†Àï‰f~ÙÒO—õ}ˆ—­·Ú­²-aÎïşeÌBRd~Œq]¾<8Z­Å¸0HCV«îŒì|U_Fk™yvé/¶äPªÔæƒr2’:å£æç ƒ…>ÑC­óÚÈ½xµíéº=ã« xì$Õ°?!Ô©$ùÂCÊí¾¶6rê!*Å¤ÈğAìv(EL"’å!RóÍÛ¥QhÍ@v¨îá¥+zÉ#»fc¤í;`r ÍUƒV\³çÅmwÕXü‚[áBæJB8ú¡Ÿ7„]ù×Š\„è:Ÿyãş}Qÿ™Ùñµ‚Ég´8Ã/¿z^÷)åƒjJ
”ÓóÙ×E˜Df<âRÍÛS:]'ˆà®JW+5—÷_)Pêv5áÍ÷³‡êÒûDebyó;6yø®6í2ÀùBSÖúçÛ—QËAÜè‹¤ÃF„xvp”)ª¥Ü}`XŞ³¬tˆ’µ
JÇàç šòâC§O,"õÛó„’`„€® Á {ÅR4gáU.é+ŒÅ©;Ó5ûœ§æ‚]qøÔµ¬ï¿Ü=·;ÙõŠ– Ü‚ßê ‡æV‰PªÒİoÇ¯äßi>—Ì6œ·Veio	á9õBt‰ö s)’ïF’hW.	¶`E°÷¢/bÁ*Å²¨„€që¶•úŒ÷ó¡=P~›ƒ8È'4_ ˆğhefşwJAş¹í~£İ˜R*Ÿ?nïñ|©E]š
âN„­|—p‡¨6ğJÊÛNı^xd‰·/9®u$‰F"q–¶ş¿qºSGôhòuı‹­²k|—`–é:â~Ñ®¯AUŸm¾ô¾u¡÷ñWº¦×Áœ½wÑgõh
Í®Ã~"·ƒ!dÜº*Uv¨š—Á’–òQüdiæò˜r]Kêãß¶&s¥ÇF3"œÒÛ²>JşãîygÕÖojÍË€i6
á®{¾ôæáÖ¶i5Â3°uÊV#[s¿M§Šâ.vß°¢lv^÷HÎ•Ótì7­Pê‹K4QzM}ï‰Uß©óõÍo@Ü—ÄjU¯×a]Ö}òİˆŒÉµ
0]4&J¾%¤sĞlÈ¬J´yH¼^Õº4ó¡eèD†ğóŞ#=Uš²2”Ò«˜«ï0æşk¨\Nç‰8Ô>ãóŠøiÀekß}Õ^).dÏC•×^Yq£O~&©ÉJV‘ºÉÜÑ»œË§èñBEÆ˜D4\•á..w<”’ÎÁ¸ ùƒ»2R.)G53ª×Cšî×oÙ¿FQô’
Ë¦¢”:¬Œa¨+½ÕØşu«`Ü}Ö‚ç$;â:EI#RáyRŠåø=X™ˆ^‡'‰Ñ’URß¯¹È¥=†‡9f™ö%Ã®‹’k¤¥Xİ²š°ó«`b?“(Älx«EE—İzº9®­d…2&úi7a…ãRk/øî‘o×As£¥¾şÜÓqåoUá˜W[m EÔ5Åı$&§sEnw[ĞMÓU2ëÈül'{- Ph>(“};ã1‘'ÊÄ/ã¯Ğe*|ğÃ/_Ï$Ò“mzknµj"TÔ*
gS˜–bãÀ¬jvŸğ“×gXÒ Ä&êH4àË§Ö(ä‡¢8ö†zí2$ß‰¥·‡¹İn0İ3sxIŒ™¯	Rö)´ÑNİ†T;Ñ].óÙ\öM0'g->DC‡+R»Vw·iW_°?Ê¾.?F¬ÀP’ GG&ĞD­¼D4ÿ$÷’bÿ®D¤ä,jlÏ$n¤ïãoø‡¥xãù±p;°aÃ$ÍØĞŒnÀQ¤Úqa›Yï7di=vîß¯CÖÁ&«TSÌcş·a¾›–±=‰D‰- jRrÔÈ3Ìô›·0@Ê ~Ïûd-H1lÅçx#»Rô~˜Ó:€Á9¦ZZ€Ó³éÚDÉÏî´=¬®àœÔ¬Éâÿ¥ÛÎDlé¹¤G¶:ã¦ğGÕÈØÇ ›ıÆq<"ºá˜j›§İ#!„®6Zo$ˆû«YÜí«µô7® ği~«á°„Êv|²£?Qnê~2
|˜ûã“Çn³~ë¨3Ø¬&+Ù5ÀX¤…ÆZ6 œü.ÛYÆÌIÜjî	Õ1úqÎ,K«ææåö1Yil ^?±y$¹­Ÿ2®J³(ES æ !­e
{ÔÆ.Í˜k±›×>j’]/^yF[Ô!Y¨^FwGÿõ´ä·*‚ÊÃ:ªNë;ÔÍø®‹¯İ_ƒÅÄGÖıÀ-³Û¸ŞnşïLõ\"ILçö\m/‹‹Ş{ééï•a5X¢,B>>qÁtW¸¼VL/Ş_h³~üQ]\á}å—4#£­f"K›Ü‹ñËx¹âóËóÒ _àÒæØŞGòvG\²+Û®Š‚"CÌ•iì¤]ƒÜÇş6U’ÛàÊg°Y®ëVÖ|Ñ†¢È+¨–í ‹/•š§TÈı1Û5H^ÊËÒÈèˆùd4•#èÄz~óÊªáÄcñ¹eÑîÄì€Ó:v¼ _×5Vi,G8MB@	şã°¢¢hDVwc:|H3O^5ˆ8yäğÛpÍÇ‘ºîºµiÄ¹L€;—¢¯ÔG%Lºk{yZ¯3æ…î¥Qš®g»î¢¬+œÂš^r/c¹Îgàê¨sºE†6šy£)J)Ş€GÊU!â€ìÀ!nŸEo…Û,n´}eõíÃFĞXøˆ#)¸ù£°Ô#³xfQ¶½T‡ƒö‰©±­ò·i&±–B:ŞÁ2ÏútÏÊö‚Ù>Z3$=•t»qÒŒãsQ…e¬€#šñè×NpŸ»xB6ªû?ûòøÂf†ücşù•_=ÿ’%¨•éÛö»±æJL†¥Z¨Ù¾°š¡WhJu¼´³mM\I_Ç«Øk‹,4ä”ûDuz®é7-Ãh)qÛ»;Íd†
ŒÀP½İ[±?%2³`-÷ºôŞ¶LRã'P•»qÉ(’¾ ™
I‡ï†G©ŒÆR»×Ï7~<Ú¢9Ït˜¥ÑI‰î2˜'Ò•^¥Xaaá½z÷B‡=ª;$ÄYUİHVq´c>3ê¤T5ª(£Ê/¤onè_¬\¶q¸IY9BHg˜Ævş“!2Z|‰ÜÆóI™òF¢¸æ'|)(â›ËwîºÊ¶[È-¾ïµ8)F²G6Fğ°³¹ä<ñcgîÍ,[I?PÎDÜøn’gUâVã|13ĞI@0-¨Q˜œw6fëÈ-Zqj¬À
tÆ‰5œĞB[©m›é@¥‘Ig„•¬ö¹jV½ÒÅ^‘EÙO¬^•¦© =ã›ÔÉ‚ê…N5¿‘òßùYîÎª²-_ë5PãñyN½[]Ö!);‡ŠoÌôl1—<8Õ?7—¹„¥š¾)Û3·s?#À€¶ÛÉ38 ß`ş…¤Š0ËË9Q-.N«?9ù¼‚b¥ZJÈ‰O]ëğºKi‘z·ï’Ó"µAßd7óŞQ¶fÓa;¯\Ko×uéTs™IÃGk‰
QŸ:f±¿6ä›Á}X)ˆ:(Pp±ÆÖõ(+@Dá‰ Õÿ}Šìl.Ô{UÃ£İk¿j˜ Dû±6Qıú£7k-Åúå°ùMş`
‰ÃLèÂ‰“®Y5G'ËP ö,X’âÓr¨·uö3gs/E¨e)^ë»¦>ãè&ÈLç£Ó4ë·…|8’Ë½!WåO½f‰wŞìGØå¬ÎäÕ@Ïóâ¤p	sK¢óÑö¦‰Ş"FYôv@®Šé™âÔ|˜®3ÒÅ‹X÷/ê	­ßÛc`‘ÜEÿ,ŞHéN|JW]«7ŸŒ°QdUÌP¡€ÜQ»Aêçê±ğ²nXBS0»Ì(%ÆMpíN!†mU›µ‹O¶Š ¥ë«çxúËk”éÊ~kK—‘,ÁÓ C›{«½ãaLzm–ï™ıŠR~NèÑ´ª%˜P—LÙKğ¦Îö 0WcÍSÜşÑƒäæ Ó3Á=\Y´¸$ïıV‹xúC5é¶9i‡èW€Ğ10fùö™ht_(Ë]v8Ïõç›%	Éâm3<¨-Z‹hŠÉZb²éÿNHˆ–†±Æ†ã’>PA°­œiŠÅA‡}.S¹ :*á_R/BÚ0Aì~ª;'›…Ó×ÑØ‘&eZÔ›<æ·q¨B{‘Õ4ª“uú
>}°á´ı‰,Ş}Îpêf®GŞ¶Æ(YÎ«áXâ+W(e)ö÷Ÿ$'ÄÏop]ŞĞşhªK­ˆ‘š˜Ş²[M~nŸo>‚¹P¦aªğ‘|îJÍy&¸éå&‹Üõˆr§•—ÔBOdú8‘û)«²±Ë@>Ûª?²Ÿ¯°µk±óXÕ'9‰~ó¨”dgÜÏ¥Àp“³>d’üôCÚüµw¢49&{é*ñÖJíûË)Ä¿Ş #»«ŠÑrÇ’Ñ½Ú&£g®’Š¤9÷ÿ\o¬$tò.b‹-î¶Nqp¶Ï±Ì×Ü¢­\†{¥7±msÉrÊ5³$4ÓQ N^º¿ì-ß=ÌälÑYm¤¤r¹Ú¬²2„hÙ©%×AHÕĞ°ÌAMxœâ*€™Ú$ê•¨£!¶É=–øOªMFÖİ[0ËBÙ¬´Ê6©‰çgŞñ2ÉKVìéÌ¹KëV|ÑZ>QÛş°AÒ†mcÀì½³Ï!±ÔlrEè´i?J¬¶/’bYæ&M/B>	?£¹ÌTñœ¯í™&ïëvn™™ËÛ…‰Òöø…ƒFP ¶£I²10Jÿ€û—İÕÕ'òñÄŒéÿ·™·O|„Êû«A_Ç¤¼pWÀ…‘9é3-=™—Ç¥V9¨£%!L¼®ñáµ>%{ ¤èßA{ïX›u¾zMt$‰|£O*RÉ=ÉÃÕ¥4aáÀlÎ&É¥Zóí/šÄÙ‚šÿè©pXá!»ïÙ›@~«náfˆPãj%d£²òr6ul	ÇÑ+¼Ag'!öïİ¨b-_¹Ö"œFùúÅœÜ›ÔÓºF3#£‚ˆ6_“Ká|=âêØÀµˆÈ,|¢•–ç,Ç+Æá¹ä{ß#s³HÄl”óÁ~Aô6ïV^Ç÷Hsö ¢ô=#$«/–Kì^>’¾ÇdP' w(§Ûû¥®z‚Â“ú èœ[ƒ£•Bdg”|Õ™0OBTÜR-Z%g18â(¸{€PµgP©³ê'òFMàÇÔ.õäó2ä$ZÀ§Ğy]D»»`yÌÏÓ¤|p›JOâëPVE$%†›f%šÌh bVWÀ;'Q€T‹¾ 7OÛÛ	öş#âwß|³5Ş#îoUî¦çdIı¾ğĞ½JªåÌ#8RŒ‰™=úng™­Ÿ“Í©z-Ó‡½Ü)Ryk¼­…¸W(Ä[ \Œxèú‚Â³úç”‹(î¢ÓÑÓÓÃãDr›`!:dT1Û+»»ùã<×:GVŞğ[
å‰®?éâÀ±‰eãîW¶væÚ^	¹fÁ#x²²>¤Mß!Ü‰èl¢;¥U­ÃUx”İy­ßríGdœ3v"hª?Õ…tñ.³e’ÏŒÙ¾m¿´É :[~mz)TˆjbWu–qêPÌi?«5í:ñ.»š^	¥!bìº««)ÕÇD2Fş» ø—zõÉRaŒÄG•t  š;·¢-)ÕMÒ ƒ7&mèµ£¦ö¶›[6›€‰òÇÎaÒM\©tÏ{.°‡²VÅó­ñuèÖ¢×Æ²èŞğ9Ÿû²Éj—ŸŒCi¥¯Á¹j‰‰Ãøå¿‘cP™¾$÷p,),¦uB0»ïaôAW˜XWĞSQÇ?9{…—˜’ÿPÂ›·ï!GÀĞ‚¾!éÌ[)F"¸à	WwÜbI‹u%‘æAİ>ø\ã+YE³ŒÄM¶Ôº–Ğ¶;ÑB-Æÿn_‹ôÜÜŒüöhK¤z~n˜Ša›ï´ô÷Â„i:’ÿù€á£SİT›³cHÛhJèG +ÉTîO±µà˜‹›¡$¢”à €¾¯‘åŠ“ïÌdãUqä“xæÓ‰²’FR.‘É`ùäç‹W-anYb}.şŒÑ¥íÅ³D†Ê<g˜¶GiFÅ°ÄW®§„¬ZY©‚I¥G(ÏY†KvÄÊÿÇ9àlö MŸÑÿšDvAÒ‡é;L‹L&ÅA£‡b°Zi“)ãÈ*,c“¶s0@•Èm˜¸€?“o!Hšb@…ÏsÉ{øcÔ¶xéñÈ>BïØ"€µX~Æ]}„@åä-æşÖ0±ür[F0„Çä|,ySTİ;R”À—jÆÈì…¼Ò-0ç¦­2ä¹ôe›eiúU˜0ªPô¡º¢ÁQyÊ‚ ZlÛh¨	Ù(˜‰¹?pq=”§pÓ‘4n€šùÍà¥¡<Ä„!>¦U†p,tA6ó,ÖJoµøf9|Rò½:ÊÄDW…TEåyf+T	S{ĞPw\D›½ád†hæu$èÂ{7Ë’ >¯¿µ£VÅ—ü¨RF’Y·Â«+ÅÿIªˆİÆ,|ñWÔÒ•9à >şè®$ÿùÌCXª¸t]E¡^k=€¨šoRFÀo/|®]…Ê·w§IÅÕ$üçÌ/£avÅ
ºÀ;+u”&Àh;QNH½BY¤ãü²Ôáyd™QksÊ÷>ó0À©Éòùòÿc¸ß‚òL©´Çh†€ ôªÇ¶ÇÚ–Æ“‡>M_,GÒ”ïß³³ãë„Ş6t"Xql
7	òi2ê TğŞ·iìØòk‚Ù¼Õ÷!?5şÎäé<À05ÊŒ°qñG€‰üÏÄQ»ï_'hÔ¸dª.ú
ğœå…Ğ,™3éÏZ`iŠ“š«îºéÄ–÷±FO(CœÕw£ÁÿËW
,ç~üˆs’%³ïfå
*´ZëÂ;|”}ˆÍ/¶&$§ğO$«¹á'0VYøAá³èhÜ9~ªT¾Nx5·…‘@{±.]¿ykô«x“§Í¯=™ÈA_rkÌ%€7q‘š°;şùâû¬ÉtMa‡ı Ií%” Q&)Q2‚NğÚ}˜V,äüaeT„ù…ClÍKãì‹¤Õ_í€ÁC‰36Üÿ”ğŠ<	,ìÔˆDRMİ¹8ò÷ä1—$×(Å€ä9ËX…9_”¢©~åÃ B7ì<¨QÈílÁ	ğ?h1ÕÑ•¨ñ7‚
Ğ„oÖÅíàş“lª·5K<™FbâÚ'J¾Ûş‹“èÖËåú:pïU—¢úšá´NĞ Ì™ÜmXÓ×hlÙœS9¾¹»¸x¨ñÓLÆÇ²+Ëa§}	xsÔ'°
­^ÿº3zƒOœ~ªáÎÏÑævÄkçÖ"¾vuİgPIÌş€Yr¡]oõÒrh‘Ïj°™½-×·z®Un÷Ï¨åBH¾s§l"‚ÒÌõ]zñúpdZ…»p×CQ÷ãfåW;’oRg(p= ßÒÉğÁÕHz,èQ¥Á
¦-ĞgÊ£üê],ÌË|m<¸Û’Êh@.º±BG0yÜ6ÕÜN¦ØKë
>Ø”Õæ½Çf~Ë±XtP¼œª;m£°õšÕ`î#'……/@‡(kPœó2‚€=&sRt×?wgöiıM2÷q+î#7ĞÓøe:#†eÔ5F¸™‘˜,2œp%É5LÊ±y(C»Å
ºËúáİ@K.œEFÚE*’@’{¡Y¸¿k<q-[:©-uàfÄ |ØdÈi³¾%£nç“.G+˜HqFƒ•©ÇmgÌäHe¿’gY¹%n%m2!â”4¦g5‹b:–›Ã3`òoö¨äéÆ‚Y'êÈ¶g’4—snëUÊSLIn £ƒàjşï¾FJ;é.VÏaÌ(–×P2µYïçÉü{1á{ŠŸB8j¨›áòLœ.ú`.†ûB‰æ ‘S,õşÀšÊƒĞµú:^+LuW8t/³—Ÿ©N™óèñylı›û’´¢ºøj~jŸÕk_ˆû#p—˜öéŠùu7½(q›êR“üaˆ@³&—£=ˆfxãôX›5ó`ØØNAõÚ^k¦Á°¹z0ûT®€›¾Ş)ÒI|Òsj}à+LĞÜÍ©&i	w4SzPRY} N×È› c7šuœ£Zçà$¯»y”4Ë#©Î;á_ÔúòJ8‰ödúUòªOe^ğfl`ËÈ´Î/HÓ°—…¯˜ô}â‡l:‹ÈÂÆd|=òo±_û•Œõ¾fÆ{Ïw{]8Š]Ò%9xJ›ü¶»^3³iåñÌô¤1¸?Ço¾šiïÁ€İ¯µ!Ú®ÑXáĞ˜3·sæø ]R´Gc7èH…¶²Ky½_9UôyXy}!Ë4ë°ï#»ç
y:ß„ñ©óGÛô•‹ën÷èE›}÷©Z Òé/6ÿ3önğ[P%axëj}í+0í¸S„˜6İ• ½¸s0	7š‚j¿¹EÈ3N¦8ŒÊe¼fK»[i”vª½!ïÆ‚Å¡6RV…îŒ
©l?öï:Í^™€ Ç[.*4+w±âÄälI>íd©Îâ@hVŸÛ;l@%Âe:,F˜õbtal 1ı.ô¿N™Tà<îö%cë(4KgÖó¢óú´˜ãTÌ>Dn&rFQøè÷Ñé
ş²é­»ü¤~Ÿıç®)Íÿï–~oüğ»–=Ò—r÷`bÜ=­=´sCÈLÚ·CÇv&NTê§§è'lÌıõd¿Æ‡ÑÚAû8ZÅBF½€„ '_<àµÑ¯.”k>œUNûğŠı]¹^¶ŒâÕÌmÎsd‰Õ™>{¡Ï$sçO™h¸}?ôİâÉ›, 	t#d,nüï¬DÜc,èuCÖ¢ãB%­à«mt»l‚áQõp˜^dÍèÏ —*hl×†è.@ğ%9­E¥¥]ø¬ÿ¼¥$…HşAøy‚f¼IDDß|+ŸöiÚ‰V/IäÜs;¹ÁL®£¬$Îº±háAwÎ;Ìyl”Oªµ’~–Àj@ò†H"æWÛ,E:û5‘æî`ÖL1‰d¸o9¯j²0V½„÷Œ~ÍIüYŸ—–Ë9Å&>"åXˆä'THf?MsøqUĞ2vœÄk—Ú¦Keç Ûz2üF(ÚçoÎK¼Gc‘œ#êƒEÔ“:fÍ¾¤û|$9tÜ¬ôÿ%›)„ëû²ø»•@Ó36šü'"'$š{Çşï·Òƒ2Œ˜_+öò
%`YªTcPz’d¹€%’vÿ*¿"åE«Cd:é³±²Ó±øápfÖMëTl ³m5c‹Ô¹ƒ’Ue:é S¤ğÖ
<şaİ€[ÍA6 ÂšÔ—5F(E>p"ñôş––“Gêİ±$^‹çñÔL-ø†ŒOP§á¸ÿŸJ±Ûê(ötzSË“4yK021óHmfx‰nSÄüeãH‡V4'©")Ãå–»”èSŠ:Wsşlq¥‘p¬9dıMf	Òá /ZùNåHµY§÷…a\’!’ûßşôÆõt§}wE’œÕ?—7c¦¢xC¢²È—=s³¶¡?yAÔÌ^Á²Z`Ä¯¼6Ã1ä}|fh%+l´på6=¨èJí	ÒíVr(®ñ’Uµ…6•\#làûvšÇª9-;³¯ùXÕUã]eËHŞ7´Ò>ê×½»ÕCÅxNşrÏŠøÓä{½Š0¼Ò„'¨§ñS_£ò‰7‡ŞÁ)%ºÛbªzO–VrÍç¶b›¿¦Ã	ãj6½{Á_éà?d„ÛñÔxÒY—¯ÉpÖÄmša j~"y8 ó°eh¦Çå,­ï [µeåÔe¯SÃ’Â©ş!–ÒÀ„åÀÑxh-	¨ïTe!3&•³QÒ•%¯gPóôÅ¶=Şï3ckXM7	
(ı)¨BRhf) RĞÏŸ{ÿM¼ôòp`T²©Ë œÛtV$•Vg†1óKtG‚ĞyiÈ½e.´ğ¢E|÷”ÿ\İ]€f±Å-]®s}†›¡œ ÚÔ«ÔÕ‡X¯—,,ğTàc‘V'›¹¹–¡€œ3ë	o ¾ˆ¸á?"W”¸ãåÆeABş€·¥Ó|Ãv{Ğ:È«'³ıˆ(É/~Ù?L€tÅş«:-q ‡Ï'ƒ[şñ—ŒEĞöèì­[Æ5Á™Ktğ‘rÉ-3AôÈ {ëZNØ–LuNò¢³$/8"º6\À“úÿ»3^Ï¸Y…“ËwÛ
²9ÙO^& ­Mğ·F¯Ã™±ï¤‹n¦Ñ»°ÿA.“—`¶ûËÃ~İ2Á…fÍ@[œ0IÅöæiH†fçVú¢à+Fñé&')®Úw|¸ØÌ“Ö(±9Ÿr„ã—Œ¨
Ñ
Ğ~×²vñc‘¥YR1EğÀÃ<Lé`3´§ßÖlBÃ§i|£U«à¤Ü”q–p°#P¦¹³’]@n³j””â¹ù5JÃeµO¢Ò°IÅ¬¾ ­àùÀ~g@5|œô:qØÌt¢œˆ"õ=J™qJ¾õ´º9(H©ï‰Ê/w‰¼%Q«$IK´ô†Jnà1ÚxµâæPngªsU/L¯ıülIÀŠ½’`r$­¿g*$<G˜˜3ÜÁ²Ù_ÿ vø—p²^²òSŸÆÛË÷60hµ€±”`ñº`t=iÇ¥±A§gæŒSŞãëA–‚v»W±Âòùh³&¬¶òŒºJŸÚrW¾¦IãıY®&ûºKÄWËN‚í’Â-13İLFõ:4Õ$ÇO°,«qhgÒ¤TÒ¬ËC_œÍê‡dMá?½òËnœ«Ş!-†lÚ+m¬\?Gtæ² .U+ 9Å»RUäÖC@‚HÙ’T8¦ù5‡P²‡>bŠ[	eƒ–BÍ$Ø¼	ËB&æP\B† MEJ¢ıŞš±_Ÿ¥¦t(BíoiU6O§mÄ²¿vò@“JwÜ ""Ëe½ªùX9)| gíŒ/@±1©dßí­úIH¯ĞUÒA¥÷.K¯Şê¸åŒ2ƒqßnBSV£¹$òöH9™<{´±¨w0l½a÷ÃõÚ¦†ŞXE{j¨))à²0ÈtÃ94†æé)ˆ2À3óúú6£ ¥¹ÏÙ¡ÚI«ù1îŞÓ°Ñ"³Ü›eUìO¼Å°ã|±d´ 7Ø¦¿1a¸#Ë§o³\)MmQ cghJÂ¤âµ›¹’CWaCË×†/JGÁaÉÆÎç±8‚›¡på†3†ùü¾	~ÇptáOÓÑÀ÷`+Xwõë
DFßj€—<Z¯‰ĞK„$Ş ¸è‰¬ğÅóB¼|&OÎÙŒş–ó«¸üï'%ş yéğG+y—ëakÓ	Ïèô\½‡EŞò$nËoòİ›’
ëÆÛ`’ÍÒÖÔ»lÑ§3™ğÊ`A‹~î³RGñ4>^îíù%:O5“¨ñî-!†Ãz§×gwèeYãÇ7Ï¹?ÇAîºK(4¢ÿ)òá6`È<6${FzÁ Rf®Q ò”eôxPbÃØÏi§§±2aYAiÊhÅÌ‡·B(¬;Õì[âwÙP–ŞÆZ+ùŸ4ßı§c÷È¡‚şˆ^$zXyÇ6.õêkäÒ³›—M.¢)•”ÒŒÇ+lù~
¸èPo½räTkg¹Fu•v&²f¨µvVæŠ1N~²‡'4»£¬ 5WÑ ¥Ù>S\–š.sù‘¾T»_å}¼Ù!¡‹ÑŸ+ÁVm™fÍğ§Â”ÀK¿‚¢ŞGÜ'q aVİŞ”š°Ñİÿş¯ï«rÄ3noğ‚9][»°€ÚÈñ½WÖîêbA.vr²ö;xKÏ„’[ş‹?$ˆ92¤V|!h³a<ÄÁ§„È¬íF äJÜ å{D»F	0^»ISfrœNm…¨MvE}upuÑÙ3;á_Ÿü…yLÍ_¥!T¿Æ‹)ñÒ÷Ús'×4<«ÿØŸ„âQ[?vm±Ö-'”N|#HÆ!€Š¥ÿ•1_Gƒ¬Ö6B…y¶FzW£Ú¸îS{h©¥ôªªôŞ@óÛÃ§àÏ®Q_ˆU¶ƒ¾ŞånFZò}ÿªC´;ÁbYËaO°9LxŠzşûxMÎ¡©>ØÕu¶õ?(´±!rA2ƒ–ğ[/WÈIó,"EÙ¼MÃû/ †ŒÊÜ^º§şüg/uûå9ÆrÑ—|ğ–§‘]f„ÛŠnëšseÈvJoÿ²ì¢"ó‚cEGp|zâNvñ¾cS¨ø.W(€^ºmp¿Ûögíµ÷²à9`¼	
ñV”)3éƒé½Ö~ºˆ{nê£>>awm~8šïfØ¡Ëì–õ#sÃ_ó¦Ë¾vìJçœŠçMÌ%ÀgĞ?÷´ T·a²mŠéqa¢©²”Dwo` ç,8„;€œ¯–cÅô®{é	ÑÎ§!p‹Zœ·
à»™CÒV‡İ„wNÀè õaÓ+4‹²£†?]!<€ğÊ®5ÎãxúEÓk.6ƒ%Ì6Eø¹åğ©“U¨ ªfA7¦'ËÉ<û[‘Vu3GéjôÛæú
62„òIâu—[=©› Ã›g›¥Æğ ¼l¥Šüb`pà
DĞ#G9ÒÂGG\izçpšÚm‹Õ£ì§çFMÏûsNK„‚ËìiİÈy2ÑÅø*c¨+´÷Ft‡—‘‹şBĞ–º¦¼²ÒÏÕ ôs°´<¦[1”ôíxKvP
YásXœ‚2Œ}]_56íª¤Ê€Ó)3%å/MõgM=¨,W‰[Æë#“„}$°œ9³Ûó…³Mğ£Äd¼=›"˜	iÇëDÃ¹æğ"p×IØ^ÓtkS"ê¬‚c¦WH00Ãû¨Ù©í	e´8Îÿ ƒ]I|’~†¢âªİîãÇÄOìg~KôŒ{ä‡IİxW’Ô›I°Áw–Å-rzzÈÏÂVÌ9HzÓ¯£³îîxV#‚I‡oÀØÒ°<"²¿»×Ü4ƒq™…”Å_“'¬¹¢ãÍtÿˆÈš*¬åÍÑ``q(H"T«çXâ¥øùš.ÀàÄ_/QlgƒöìÚ,*ÍÍõ_K+ŠÜ)~Pş/ Ú–kW§9áò½0™}4›Œ!%…6‘|7‘LøE÷ãQÊgªÌµsôÏ_qş RTJ"„ŒŸf&1¸Àb hëÌQ£ióŠìPÓ?7Óß4;În;vlqãjXÕntò<)Éáı«…€]¹ È¡ƒ4SÉ8¯;‚
Dx©›ğŒ€¡f¿ğ:Qÿ¾…Õ"‚’YÄK¡2Un‡êc½ş'¼Ì#0Å`ïÙ™zü*ŸxIĞç6,mLèÙ’wX‹Ó	#É7Ìİ]Ã 3öÆñQQÅHşÇûá'H _]aâÇ]››)ö¼ıIŒS¢‘“‰,#‹ƒ`QŠbî-ÑÜ¯ÔNôÙœ3(Çûû¤6×¹…”ÛãG&È“jÕî—ì©¦¼·ûíïw½Á»“éù¥ÕêÆ=µÓ³zwõœÊ7¾c\¾d½ÄwFrÁc=¤Í^Yn‡ˆïÈ@£jb	/=SF-Á"pb7WŞnŒü´lo»Š•£mÄ^ø*¢º/9´g$Ü~\î}¿>ûÑ’Ãaå´¼m’dui'û+oŒû6·±Nnv›¼ÈÑÆ¼©º\óŸuµóÒVñ¹]f“ëçúø`14ÕIˆ)4‡\|z¾§ä›+0ªz¥	Ûìüà j(
àÆÅ{Á¸:S@HDÜ+$ìŸSaánj”Wü:øÍµ”Ú?ªrP–M¦kE£Õ¨Š-Êm¯àe@|\6Ú°"ª;½q\ìÅLùÜİğ„Awëƒdmr1'ÛñÃĞÏ²k‚zÇç¤Î)?oÏ™å˜Y9¤ü¾º¸uËôTæÿÜØ3&K•%¾EÈÇ‘:ZET!jéâíø2Š—ëÔl¾"D2ß_ca±Áâ~)Ù?__´'Àü×êªå¤ùñkRÓ—šáÖ–òûå)ÃZœSÔõ
9Ğ(D
R×¹È¸#<B+0ákª*-7Í×}­+İ¼íô|tñ
¦ğuILS:æ^·Ò€xßÊšã©Ç¿1ÑŸ1ÍQ7NŸ=å«eGDgôÖ;ñÏVJ´“á%‹+ÌÑîˆ€ÈïK¢IÚ-:Ğf£Í¯•ˆôV gÆTFP9g²E#ò€®,076fJ,©§äËîîp®ò™¹_î@J¹Ö•¾)³´³‰Ò8îW°™/%ôx|#s¾âSO3Ô»û'£À½Ä€”a'qfTìî)Q PH=Ñ\o•@°ÇfëÔ*Š/ÅÉß–x§‰d…ÒÁéÆx©Ã\õ˜ÿn\!€ƒ³<+âññ¶-0‹î\˜:„½8P”ÈQŸÕj©æá¤z
¹cãv~F÷RÎë'ËÍ¿R×y[–Æš•`"vª³­ã^§_î’vÄÕÁHéîÌh`î«ı³_İ¤Îœëï©¡×é"ø;Ü~[˜Xîu\MBô
”T*Ì¤p5.˜tøH5 HDü‚¡L1ÜZo3†*Ş$Î&²»Àyºz´2å&9L†…9àÉ—­—€¸ç©Ø’àà¾¯ñ¶rı´?Ä†*ãÿá·øÿˆEÃ°dåàÄÿj­7!®‹¶a#Üü”*M7Dá7¸¥	*¯bê%²ôõSN	FÊå34ûÌSI¬X»üÙuù"z»hÆmçMúÏ¶Œ¶FÒ·Š¿õ“!¤¦ÚïÆº6uëw±•©h.•8exKğëQËœ	ˆ§_0Qİıà¯©*-áUÅ“Prh[;)O ÌH¶“îóÌ„`yŞT}¯ğÒˆìD€ı	É+¬õz R	VÜ…µn@÷œw9#†Eù¬wL\XLQ½w@¦Ü—ËG$óÎŞ>¡%†”U¬ä»Ÿ=`AïNş`¼Q1N¯œ­¯C“É^Aw9—-¬õùÅà‚
ã©Æ¥µâ‹"yÚóõu¯·@æí´cD^d÷yÓæt<z/—ƒ3Aíù†+ºM£®DùÉ}÷:IO*ÿ£`j§—¤éjû/¢QO1”†¦İ™Ï>6VC ğ.Éæ¥R
ö“óÛÑU#.üVÒF…6»7WQu„Àß­ºÉûËA/²b,Šs‹{H¹ UT÷£ÛÑ‡`ä5(˜î¹}­Q?ºC[˜º©2L›~«Ş)œÀÕ
Œ¢Pø/ß½ª9¼$uQLÕH Ö'ŸKí›‰’i) ğã2Ã5%#`Â}¹ná?˜Û‘tuˆgqøWı¯±7<'£6,—×Ÿå$€tTr`Š§ZE‹0Á)…»İ7@û±Ë™yHØ¢Ú©ÃÑß”ï¤aÌQEƒˆ^ë¼ÙÔd©Ÿ)4{;‡$²#È÷}4ÂX¿:÷›­{ÕqÈ§'ĞGIšuÜ{´Y3ÆŸÑÄuÉ\ÿ]—öñ ¦ñjĞi¸„lz¹mjEs-Ü[Üµ”+¯í;Š#FÖ&ı‰ù¶¸‹a€vA{8Ôuf‡vf’,rğHº7çk”ŒtÁğ}Õy€"Bh8Ë9·Æ¢ì×›Yf°Îc%fu¶¬şŒ¶&ı{à‚ı¥µ_×»F"ÃƒjvxÄ±½±†Í\u„²¿ ¹+i"¿§]¸¯¤+Vòiå s_/,N	À	û2ô=¨ëÏ¬	ŠÈ.lÒâÔaÔî˜¾AÖ»|½ğå$ÍÀ¸ÏùÑƒ\¦5@g7¨™÷ nñÛôGÃ4vúú›İX®ÇMµÀ%@¡„æÀxˆÁµ(øòÃ¯šiÆG¦.Áîâ‹¾xáÁĞ7ŸÌëB˜L İüánRß¾š®bE\ôÆzìøv‘ë}üeP®Ö[H-wpá¨4úd=Ş>HoLbeÔ¸+ü·¹[ª3-¿Ûîpéä…Gi®kŠz‡FX´Á³e×ˆp 
‰ÅÎK+5‹Ùvô6ÿX³H=ƒ›ş“ qÄœLtïJx»â>ÍÃBcnO9BÙõYµ“¶²®GTÑ%ia°£@ÛS
=h²ò*qØ–0å~-iZ ÓÁ“HÜa´:ñ‹ M»ùz}¾À(ğåítÁg¿4.¦dËŞÛ"í+Ì4 J]ÅØ0Ú!õ—¦,Ô,e[eÕ‰I0 Ì¢f­Nd?k¦˜ ªo Œ–ñ8¦0çïïmsãîc4@šÑ@QÀñ+lÛ P-nY1vü~·Ü¾È¨ÆÃÛ AN†§3`ÕÕfp½€ËØ›Ä€=¾¨Óÿ­¯üi…sÌ÷Jp‡„İååwˆ)Q™CEí¹ãëŒÿÇ«Gøû½µí–¹ok#H‡-‹W2U`;¼.I´@¹lÃBŞ ±•ş½«ñK]‹s î1ªR(óÆ¡ö”İ0<Ö“ÒG[	æ\.ã~ı–áÎşÅÇñ~ÓgşÍØhã	š>9¹wœ,:2­º\ÌŸ¡ÜKi±P?¤Ô&&	“;"Uùö­ñrĞ‘0ÑïŞv9ãü@ÕúÖİÑŒ3¸„@K‡ÈÜ¸äVº,‘Ë#Z>ã^ü]mÊèN6Í;     uÆ1Ld‰ İÏ€ëÚ£ ±Ägû    YZ