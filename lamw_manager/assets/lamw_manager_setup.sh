#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3626998301"
MD5="1203f0e7b8235e8207b4850a2216a54c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25540"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Sun Dec 12 10:54:48 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿc‚] ¼}•À1Dd]‡Á›PætİDõ"Úâ=©‰ı« ½Vä§K¼tÃ±¸Ônó~EïdÎõ8ô™èƒˆ—Ô3¸Ã¬Ğ&TTu¬ñ†ü¢¾•¾^&ß~&”,b(¨ 90Ü[ê¸n$«‘7õ~ïôÍ†šòlİYygËÇÄa_lÆa¨æ»	PNĞtØ<Û×/âØø÷­Çv{„E23Çx`»²R¿Ã½61˜zñ¼aO”‰Ÿ4ÕŞä$wôz¨)vîEXÚ´WhñmXÊäJ8D‘Dğ«r'“ÒÖtş:Ä\Y!õ”ƒu{Úî{â‡ïîõ¦òïÂ›°-&‰5: ñZeH÷Í"¦™%‹5¯gÇ*ÑœgÃ1²rË-_D¾å˜$æ¹w®Ü±9ETbíL¨ÔŠ•w·›ıÎ Şuá¹Î•B×úßµ¹ ;úŠÏI8ó·ïËöè>ÍX;ÜOn‹¯`V?>Ó¹L-¤ö>ó*é7’,ÂÙEâ¥Q¼,ö‚Æj–­¶ìJ:ùrc@2^œ=6ùH]Qqtc[7‡fŠ™WèÂHèqF³I}k×ƒ}í¯Úl™;v»G\Áµ%hTƒ&a&ÄÇ&$Lé×ƒ£9ç×¦RÑ7èGV«NºEMû<<tËçìÕ>#¡–É=Ó_ivÛé/‹vlƒè~÷Ù.Ø^wO µÃ9‡â8İœ•Ñš2àMÈÆ¬¥’° 6ÕT¥Òíİ¾6j%ÖºÆEİ_„M5ò%8§sş²5?…m/šóI#ÌwÅbdF/BI´ø;>¾>¤<ºmÃ–íŞšš:ÿuœ“Şà‹ØôòƒnÚœÇŞŠÂùğ%•í³Ç|1à–Abd¬ÄòK÷‹õ¨ ËN¢]UÆñY—ªP+$¦XäU†ĞKaõà\ú•_â¨#<+àŠÄÔ;Ô÷e’DÖB¦İ/¿³qÓ»já¯û¸e‘MîøÔmÿ3¤|ØìÃƒR?Êµ4)*â]mÁæ(]Ò1íã¾ÍÉ¬TY</Ú»QššüZ= ^2‚ş e%‘n‰ÈWöeiXF¶æ§k£ÀWx5LN¤:†­ñK(ËVW¸³‹¡úù({JÁ“‹@®E¡¥'è”zm²*z•Ñ¯“
~´Ü™§}˜'©zÍ3©CèîÌñU.ó,õ‚Üc¥‹ÃCœÀç;½JJÎBî"à|ÔÒmØÿşrjuÁøÍßò:'å='^ôÛî±
¿“û!5x»EšÎÙìV0î!s"ã>,‰Œuû4(Òw‹ô*bÙ¼¾iÃ3&@C#‚x¾½¡vr<¿õ¨Øˆ€·Ñ‹‹%>nıÔö½ 9Ì[˜[•ù»·^‚Í?Há¼TwK|í?` ™5 óm~ WØä¯| "AÖˆÍni E‘=OÏ|F5:ø†ÌïÛ5¤«ó=‰v¦NT µ"M¥ŠW;¤^/YêTÌ†(à§ı6˜ˆuÛ„SFC÷Úç]F-¦
¢Z³î­Ù9Ş7g¨‚ÿl‰®‰¨…Kü÷´¤ƒÇ ³±ZHÅ›Ïm³ƒ_@oNs ¿Z_`("î•»œwEÀL¬]`K¹¢¥4NmO6‡­ÂU÷3,×C¸Ä£òFÉq–fabª}Ğp NjR¾€Ç0ªäOÀS*5<‰_G^Á¾›Ôì08ÃºÎÍªë}°Œ.P›&0qÎß’Ş]í
±©D ò¯eys»yä—æ¶iNÛ$bÜ&"Ñ•í1ºÛ®hêûÏÖWKØùëòÁß–Qúú¼<úÂ§yêØ˜•½JVÇl2ö/Š |WÍ›jÃt’û5\à¶^|q¾Exõê‘µ´ô8³ÁÄš‰»âjÕÉš¶.g¬?fñh‘~9êMÇšs´À/”@+ÄÜ:œl€ãS¿µ¹³É| ZdLùÍƒf"i*±q]	yÆ?ìó~»¤{Š¨å¢L¾¶ğõ5±špzmŒ÷MN€'
ó‘17âU¤°ÍÉ:Š§ŞCuæÀ¢À€tóúeaöG6Î0µ1¢èEçÛ§Ç‚+.ø™
]ƒub]2,fZôe¶î‹ÛÙËŞêM‹;fÔÂŸ k6é§f¨'Zî5Ä¥¯Wò»ĞşšµP±2İ'şK 5-|4“|œ#7Ùõ9î ‹Ö¬ÇğU3ìş3W±L'—5Â£åö"*2QÇ¥:]Ø2Kâ»*?G}µVÒmÈKg´¨è2Œ/4Ü8pS––ÄÌ¡ÚÆEKØò^†X¼”ÆF¯½¶ğR`=™„1CA÷CÓYº¬ï†™–¨1ÌM?0MŸ]°"GÙS
ˆ1«T§ sÏl%G}»ŒG­$KÀ#ª”!oÎ1]Päôg :Ef”PŒ¨GãdRj^]%Á(œ
	¦v‹+$—MûË½T*ñr?® ›#uÊ€PÑ¬ªmœS[K Ñæ8ù­ şØ`ÂUØÊV8ÉeJËÜ’£ÚW+™:ñ[¸H=V3ÁàZºÁãáz¤ĞïV!ÍÖ‚AXŠæ›OÂ˜æˆÆr‡	êø\¨²~‡afAUBt{Fd®’;¬bÇüU˜èˆ¿i'SIsGÒe¼„‰şrõKS@îéKr"ãÃP§™z"cç¦ÛâGDÿG¸Îñ¾ÿ#%xÄd¹¼Ò]gçdà& ŸõÅÉş¥†Qz±´t¬|@c¶aÖ…Ÿ› ä,”’Û<¹ìHFA†?Ÿ¶JDÿ ¦ÖÃ›t„QËP0N‚~oº_T)½Ğ§9ˆ´_…§\kHv5šÃF¡°”Ç¥ClßX†'¢ùÁ]b—ê–ĞÍ¹ÀtÙ—³í)ª%?_ÉPÓ¹4³ ½¸)rO2U:ò¢e¨!6O?*ÔBRE(RÄ…‹„\NuÿÏpVIì>/šÄ­Ï2¯7”ñâMTI³1¦ÚÀåÌ40—×òEC$´°–|IæuÄ;BÛ®¸2j ìŞÊcQïM„M-Ù--P ğ­àÒküŞMkö)ğ›"™ÖÒâ ğ6ûcİ°úCÓÅ:÷ûÅ¨ Yú ‹RÙ=§oPæâıîPtÈ6ÿ,Ïò—€ğÔBŸ¸ƒŞgø‰*A›,ÊËó2ê[9:ã‹ĞÿkI~¡œë‚xR;·ò`cE³ãV›”×w†C‘P¡OZøáÀíÙ±ıÉ1)ÁTnKĞšÜĞ,G©€x~…ÄÜ2/åóTÍ/|[Ï6+Ğój‘³Rîp§Õ(õ†·•ŒCàCÍ†1ÂİåØ"®KcVñ{¸Ã«L"Chj›gÈèDP±)ú¦ÈYëÒg¦Ö‰OP Np¹íNéœ]ê_”Y¸H.Í€± ¦M<ç*æA]¼–.Eé¸©ÎŠÄDDW4DA<SM—ğaÙYFcŞ	oW	[ï^0îBÆùû*=^âñƒ?Iò­°»7½ãåA Işæk½!äb©?ôÈŞµïbD³ÿø0š©y7ìCÅívñ!œS$®"9>ÊNælåJÌd2ÂüQüØÏ”ñk‚d¶ı7¦¶:Å=} Àœ¤BÅò5ˆ>9t(U­w z1r¥]”9“pÓÉ ù)Q¦}Íİ•=ï2*B)›% ÀuOÛ¹ÒxíSÔ~ÇM~ÿşWôfÎû÷8c 6ùŞµûêA"ÃË‚s£måßQ©ïçúeså·]hù3½°6¤vT@¤ñ¶€àb{ù5ÇÀîƒ×Î¨¬u
…›ÉRëw5¿ß\àF×´YP¡üwë	äƒaSÀd1m›ÃrÀ…Å™Ğ_«Ô<õ¬d”îa-•ÅQ‘«ouœôÄ&Ò œÆmjøò åü0ü•ç#©ö£h·îèIìjiád\ºßÑn_ƒ'äEGMp:5†ÂcöÖ„.0ìË;MV«¡­Wšñ
¸ÅJSO‚×ˆÄ‚ˆ®TÇ¸0¨ö·^ˆá{Ìi<wIô:O{æ®¨½g¶­4¾‡\(©¶(aMıkN“1±ÇÿõUDf6$ (“‰Û†Öäå;ASo¨NğÌ('ÛĞñjóö:µá©›q–:µU0§_‡%)Õ€Ä“^°2QsñX.ÇŸqwu–+ƒT`‹å†Çª l®Cd“ï‹L"P/-«¸¤2™ß9|¹¤µ8ŠÜ?öõĞŒ†ŠÙ˜ŸÒÍ‚~å€k;géïÊ<M¯.À.°/W[ƒ³ã´Gt›ˆ¦ ïQğv¡ÀÁü¶hÛ8Çç´• 
K×,\n Ş†óZ™œF|ğÇÊ1qgí±z Œ3j)èÎ^İun1Ûhb_%Ë6[¯˜ÁµZœ†5$&XtqÔ¡üğÒšÄ’' Æ‡¼Ò+ãeÄ3èÃ¿aƒS¦Ü•…÷ƒE·åBëSÚáÇŸQ.ÀhNÇUËÜIñõàšá™ù«»ígW3&ÊÉÖÉÙ¤	}x«ÌòJ?ÜÃ[´áºÌ§ØœÆE&n‹ˆx±¼ÊE7só‰W˜ƒrÒn»çÖqQ¦â×{úÓÂ?ÇïÑ{ÕU‘T³B¥>ndkGúâ‚vïØi:—à9gÑ"¸ÍL§E3ï'MaäH;	£K÷ñ<	:Ó¢¢pè0ß× àñÕÓHyZñó! ‡UŠ£96	I{\…{ŞK_F¸ÂŸÕí2®gÀHèŞ¦ÏÅÌ¿ã‹|XÙTä°r>b·v!““Yó’Gß‡èÃ¤EînïO´¡E¨ÛĞÖ«ÕÎ0­§t—îÊOF\Î ¯+~$püÛÈÅ$íçfRÊÉ+OågÎä°­~gU¸çó”F~-!3¢ QC{|#j7«k¨“œ	B]Ã\®ióöZ2x„Ù7F–ú®Ï¨D„=w¨›@?Ô§Vlé¨gïUÜài,íW®äó:ğŸ%eâš:qPkdø?;«Ğ±VøÀ)ş¬¸dnm©İ½4tãrŠ> Âš?î¾Ø¦´	5û÷°†ÖÌfÚHÓb\şÊ—ÍÈcñÛØŸP$‹1Íâ¢v¸„¬€†[ ƒ&ÃAªwïTZgúHà¿Ş33€jjl©£?`ÒQ.­£ †q›ÅDµlÃ¥èiõLCoÑr0b4@£Pb‚Z›FG¸y¯,)èñwùĞ’ÌqÂ%4dãƒ£$Şø1gƒ€ôS†Õ£NFCã÷8ÊYÌy_Àu½~Ø’ŒEŒ*O„ĞgxŒ¢9v®w€´Gt`›Y-.L=‡Êÿ²)P%f,¼[^³Qšá¨XĞ" @b	¹éå°ÙbXÔë´4ÒÅšÅæ´°viÄSï¡ïÃ0Ê¼í[‚©“Î4OçX[9TÅ¯d»ñÅ~-ÅsÀºóˆáA¨îVİ·ye‘¡Ü6_µøÖ5MdR4IU€ó2]6¾uùÛÁÄŞmÂü‹H¬êÑ|9Ê'°õAÔPÏôk-2”œ¯½‚´®£Ö’OUNl­¿Õ>.°®m2Ktš#]-Ï/‹õĞñ¸m}mCå!›ÉØç*?À;qç7@¢-Ì'o˜ƒ4Ea)5í3—í<¦1K®¶&{XxFì¡Ç[å 9…š5m“×H_È!ã×$õõ‰ ş~Ç­dˆ@ÛJMD[£ˆï5}^ßÊD/•S?>¨®ÔìÇ7Ì?S€Ö`&So”mşÚü`v,ûd:è)aãŞ0#]Tğ8Ï$»›Ì˜ÕÖL£'è÷œ7zax1¹IØ\Ş»CĞ|ÂmWuymõ|tåÂœ”K¯jÊñÖ-«rUïÔØ 8OÃ©p4lÒh^h©Ö(’;(Nu[ç§ïX Ğ¼§[ñs·¯3Ş>™ƒ"Mõ'İJÜãFÿ¦Ò9°|¤á^™ ŒKb@°ª²¦¶VÉñ‘»ÓÆï´¹†r"«÷Pg¥¿k²Œ!_˜–›[Ü& şCÌMl}QÑrØ-Ø(Ò³4ö"~³qİÈ.£çéå¿ÎNışjøqbÖt^‡HFìôÁ$d¶©—ë]q¥˜øØ»|²K¥jO-»ê å¨ê—PMoínLAàAO ŞÇZ
º»fÍìƒî-•R#o¦4RÇÙªPÉ¯tÆ€L+j¥uÇÖoz†àwRìnÏÜMC	¯0Y*ö-1­o\B§•…d’Q#œ–L^…#ÕW@ñiËøbÍqe´5eã£‹ÀùO§!C\i¾=;ï´âAlÜ 9–İ;‡w…fêÚyKœ´Í6nJìòŸä=}æ”á=Î-ŒóÑÕÁPi&Ïıó#•hãLC²»Á¹&Rc~ı'D
;2eF°ÀÀƒÉfß8ÕûË¢ÈÖ	&=¢ıÔs°Zÿ.&Ï§»aÏ-s8…H11)ƒæ2Îvï7åmíEüj¿DØû·Ó”{„æ/ıßâ»A5©|/¤ú[»à!"T
ü__	å+ƒêšl
7Ã)ƒ‡C¬b Lü0nÛ¸¼r„y$ Ä(¡·%ZfXªÿ^MbN|sçWìVk+$ôYçíò¯“o¾©bêrİÔ‘¼¬>Ú®trçh° 5<±öiâbi•79/ÍGˆÂOÜ˜g¢Sz°­XÁÇ®œèOáñ†wÓ¦×~ĞøğÒMÖş¸Æ„-X¹¢GººRtÙcZ|yÁğQ÷¨şaO6iõpƒ”QU?1Æ<+ë+pGÈzhnÿı¿< T¤\Şp^Î
g¹Åƒwğ%LRÁ÷”¡O!˜4éª†/–ôÙ|§
èS!C[œ/<¼~¸ÑÁŒ8âÌö© äµk|©mÀÎ¯xQıXıIĞŠï‘‚¼cc‡ê©ÆGÉVtÚaeXó E Ÿ*€˜§¼QøŞÇSü¢ZcûAè×¨Á•­ŠMÿìr!÷8<™(ºß,Üa˜‡'ÿ¼ÏR˜QkÂûI«C3÷ˆè,ÚNYj›šÕà‘šÉ!Œ^°İÙP>íOæÄ˜l¦®×µ¤4ys¢ù 'k”o{ÁÍS›È©ÇsÔpÕ'åÒMˆĞWÖ[Æ:è1ób+}¿úbØÈ¢5[;7\×fŸXÛ_Em«‚Ír€}šit™¸k!> jdf×= Š‡§bAA¬_çF¾)rFo›Áå*b†îÑF1Åş1oZ#3ñû–“ŸÅV×$¹2¼sroFÈ‰s°àÉnõ‰†élÖã)˜@2kvÔ›,<Õ…(¼Ó8Ô4ë(x²vwñ9…Äé‘H­XË&Áí:Ã5ÈaÙd&[f›ÉnüÈÈòj<qßWM@Çt—óÚ´7±q×íu0M—QòçÜâä°(ÖÃKZª³èv‡·©è«Çí3%Jµ¶ƒéˆ	½æÓ õÉ½ÁMÍ¬¢
í±bølàçâ"¦†„ÈûxÉmÒñnØÛy^øã*NíSÄx·Ü5ÎÉ-üèhÎ°#äHoeé¯O«mÕêÍY5¤«))½ÊzkİˆÎ‚Õİ±Ó°‹ˆ„V/ñ-JÀ„
$
G¡7û0GUš™ä‘gX®ƒ•¥Z¡Ã# 5#t‡S}
rUuÍşj”Œtš¶ÿ„Qgnbq`uŞÑ4ßÉ«#ÓÂRÜÛ7iëª#·ˆñôô|¢'+C¼ƒçeÄÒ7¸h(;ÙØĞ
ùÿÅØe»A‚3Ï—Ñ›ç¼cşü3ó×¹ÉUì_ı>æ*«n¢Qãı@ÍOæ	4I¸óƒuz¬rêi¸M¤Ù8î}¸¾†xŞK¼Ä°ßH2Ş€ÅÆT•w"<•7©KÁû¨a3d¤Nõ--÷¸Ô?ô†y\CİlYå¼,Éµ·ùü·8[W4À&ˆ#2Œó¶öæåUe3á_ÜÕ‡¢—A­1à¿ÑñÄkVœ€2Q÷xƒCÄÜ™n[· »±¨Y*¿Ô$ÒiJ¨A&#N”l¡r‹ò}¡š¬ípüİ¡aS?‘ÇA…ÉÕİZ9S[ğ`LrÙàø¤˜îÆåš9˜â]-óUš¦¯óºíXÊ:îÜ²šÀµÓ;%‰\@bôƒÚ«®Õğÿã"%V¶÷~	ÀÁv¡öWydˆOs0«ÒÙ¼BS†ª(±›S‘3b¸”ÎF’ÏBoZ­ ÌMÅÉ¬-7£Eƒo>Ú8uğeÍBâÖéĞ?oF€?Òk^ƒÖÓv¶ğ¨PÉ¯4 Ócûrºğê˜S79«Œ©tiêPÌz vºeYÔÉ]}š„d,ê‰r=MÓÅîÌ%6l|µÁ>ªö|«õdñÖ7$tB:İqº›â•›˜´”}™†q5á::e;ø†R0v#á‚œÜÍV†Á´SQs;\
³Ü^£^IÉĞäZÄ¯VMùÙèæÿ¶ò!d7åÖ5×ğT™é«°\)0-H‚¦!-3 BÓ°‘àkˆ7ŒX4(bî€qµv“<P“66ë~x‘t?¼nÏ‹š+ØLÂ‹­?ÛçN¬šX¿¾é|ƒZ1Õ½“Ğëğ!Š²ºÓšM¼Zn·{ë«¼ì 2ÈTóş¼ ¦¼NŸ (è	šÎ¤îFÁ‚şçr†…i1°ÈW*Ílü‘_$Õ ™»)Y©ÊK‡dM,<aôËÃ®œ©˜ğX{ã2WN¸'æµtÛÒ¦a]†ğJk~èb.¹ õ.@Pã?–EybşGú±Ô³İ¿9.)&	\Ë¿v#'úº‚òL˜oé(ŞÇİ¹½»¬ÎèuOúÆy_‰T¡`ğ7•	f/ÈªUÉâÿfåè£Œ-Ñì‡Nùe0€1ğİ¨=şw¨^¡4Ñƒ€k/±Ë]ù,¿8ŞÑ™œMıŒÁtïë–(\n+J™”í¼×xª‘t!r wq"Bú	ŠjìV!ÆÜ¦¾XÄR½g¯€‹1·õ˜åŸ¸— ³mëæ'Kø0ckCœGåJ÷r
pg¾\=}#$\ˆyÕ¿$¡œA<J4È<â`®û©GúËæû²1Œ£,¸²™¦¸ÿAˆ±œ‹›iı-Ÿ÷q‰ÎÁ>î¡¦êáĞ˜ÖP9	ÇÆR@Ú"*ÉÔRc:>Š°&’¥¯‹ç`ş7P€N¶I³ĞÛFAóbùdÜ4}*^ã¸YŒLd¹¬43o•©à_±A*±‹£•8¹üÿˆ§½ç	’ÿq@ŒÙÚ`h
‰?®/.¹¸$ªÂibÛsñjÖ×od×eEÑó¿¢4¥¥G}úv
™´*±VBÖ¹é*×ƒÄ÷OÆTM#zÀfÂÜ›Ñ`q0çÜîEèF„„Å¡fĞGå*În·øiE^¨œ¯Î/«İ 2j—Ù§)äò.ØHË_¾ÙùíàfÀ($VI¼A^¾‡%diÅcg©ãú¹ç¿Bö‚+ùIÎµûA#J˜VÇã&‰vş'Ï­*Ó£hÒŒ ïzff?Ğ“‚îS¥×]ÃHDÉT'ÿ„€ˆÜÄ/4ÿÚrTE´»0åìŒÕÃíµ+Âe.<î.û nv‡¥H›÷œym”8ê@W\V ÏÌ¸TôÕÂ×jX±áÔù\›<×è‘’ùƒßşÁäÛCİ[‡ë·èjaªì½gGwÚ/~è˜'ãPÙú­´0‘*cÖiÕ4üÔt:É~á«[{^MÌ7Ó'Ê¨9À9Œ@5Xò8šíÑ½ÎáÎÔ^˜¯¿Ô3…à±.÷ÉqdbÙáÔ£ƒY“¦8Ÿ >X¶>@ÖÇ1À¥4ù† ºüĞ{ĞFÁ´C§½º4îÂ}ÇÂ“a4+‰Q!B€df[ü¶°ŒÜ-_§eG€ZSü¢SHP-úº`K–­òÓğ64şıÑj+ş+HÕpáƒ¢EÛ»/ï))O-ÄÏÒÚïèŞU
xª¸ãG…7ÆådÓ6ê!…U²=?SDÇ²½1×KR¯ˆúø¡€ƒş7Í×_å*¾Kà£w>â$g°v².bˆ$4'O÷Yèó‘m;0âKìWŒ©ñã–?û¥N„®K›
àÓIQTç3)"@ëÔF=³öåÀYã½~¶èš[¥¡SÿaAÛ¹8l`­©còKwê©€µú£Ï2_VhåÅ­ü…/Z$ŠÅÌ»Uäˆaå¬ªåºJÜV4Yâ‡‚©ùVƒä	W¯l^Ğ¹UŞV‘5ƒ´¯°? #©ó_^×ßZ!ñÈ%ÙÃÑ ¡s¤y;šÑB#¡ ÿí–şFv¨&C‚ÒÃ+àÉy-ä„éä-;Y ûºA»Kùb‘âY™¤&Ë‹¬¾R¾!0RuÙ™%¿€™y[É
1é×ê2wPÆ1wÃf¼„ààˆ­Aêºàcu¾[„+¡û¼¬cu¼e@²ñG©é’°?ÌîÀ,XKt‚Dw
e½¸*7¥o÷ti5sm‘$Ÿ‚9w¡À2¾Ú Tù¿å1ğ6±¡Óè£™QûpŸò³ŒÓYÉ¨VwrÎ|ª’Irf>ˆ…0¿‡PÔÃ.ŞÅ‹m7¾¡/­‘n³£á x¶†'13Ü¨â|ğÈæë}3\~cOKû…ˆCà‹İcËÇê<Ì½ó¨“aW{PÄ s©ÿØw Ö"\#Æ”†ÇÆŸ€e<m…T\–q´–x¼·™cy}IËÅÿEnö¯OœG6”×¬ãã~…šîvÄÑê<¤æÑ%]ä^>]X‡
p42¯³j†»A(;ÿ«ŸEÂ€¹.b!Ğ¸Äzà!’)~Sê«¶”7¢\Ì|çMòèéaßzU_×ZMTgØq¼õ-'HĞE3Ö8ë•ÙçL½%Æ5è<'æ/ç¢#Ë1ÓîÚ¥;©$²=”Û¸4ËÚ?`••’•:ó»@ÆÔÅ T©›À–bùV‘f\>‚È_9ê^‚0¶®ïl)hô1iËıæOt32%^¿k']] Ä=r]rÈF´“H „Î×¿OAÃ“E"æÅ¶ä|ò¬Oú{tÀSŒÖëÕ–®Fÿk„sh4$Á»iŒ?ü/x³ÅcÓ	âZ;ä¹8+°6±¯ÓBJ?§‰¨jşwƒé³1Ïú›øÙú¦ù5ZÒySÀ”»“|+Y½ æ˜?·(yÕ—œ°öŒÊ/KæuªaŸ‚âï•Bx[|­A>è(º¶Á%ÌrÉåÔtÌ^ì1ª=¡oqš¿B.Ö%îÇ¾7xê’™ì¡nbÚ­Çñ%×ºá"ƒ¿±wy„~˜(jöí_«bÒ,‹åê®Ş°rËïò¬2m¯;&êİxª£qã³`Y q5K«÷Ÿê^®Z\ĞH+8–ßí¼A¼Q¤‰Éñ™µÌ)° ;ÄÊï«ˆÂÕ&÷Üå‚rb.G:¯k?YÎ	wD¬š\KIÅéx˜.
†§Š®³¢q\íùyGì¬øZê»gĞÁv…'Ëz<HU€·İ–œv¬I¬~Eüå]+âŸŠ=*q‚u^¤w½{ÖÖÌ;y¸ùõpVıTŒ0$(cÈû†·7°şè^]4ˆª¸É±*ümRÀ6t4*m´˜è@Ö½«â|é7½8hmÎI#ÀèCåBQ¾Ô>)và«—ßÇH8ØÔ«°«Ã”iW§:´¯4šŸÁ]ÆÒRù]óf|ıÀòD Î&>—Úùü%Â2ÚóªçsjÚáK‡S(k™•,_X£6Ç¼×ÜlİE©õÅåêşæz›¸áAû­;ıœã)w;Ì™•`)ai~"ŞDÇŞĞÃ«‹p#ÕunéåS6o2´tÅe€KsôØvÜ‚ŸIIJ˜eYæ°cqY'öìÄ;*™Ş·Y³ùb„æ]6Ùe¸Õlvs­ [H\ıcAc4ƒªCj6 ZÚè˜’Ç†B;0`¦¤·ğÚëÑ»˜zŒ³”JS®…¼0'Pıd†°ÍQì
Ê{Ä}î¼£e!^ Ÿ–Ï
mbG!X¥÷#‰ü/´Í•/Á†ÃR‚¤C÷ÃŠW›¼/P÷?‚KÔˆİ˜îZså˜¨\§8QÀLı\ï´eaº7¿.OoHeÓz•qòšóÛD ÷::`ıĞp±îwƒeÊYZç?#OpJx'4îÜ¬é1‘ù6Äb¶ƒ¬Â3‚zÎJÀ˜²Ú¶ÆüPÅ	çû&œèõmŒçÄµf'Ìêú¿G§Ú%Ã…yä-¿›Z7Íds«kƒ±ÚrOyWqIÒ4@Ì¢_Õ8DÆ*/gYs_		áx â0$8.[Ç™3
òqB8J§‹êr0±QO²h^Gëçã6‰§P@ö0“îbó÷8„OC7²…ÕGK&Åéašc)7]:\ÆJã}»íàçı¨ÿä˜w²ŸSz‘ºHø¬?Š¹÷ÿ;&?Ş>T	Œ‰|¶ô@ÿ`^|hä©¥¢Æ²ÅWÂì½qÊø½?’|õxFNnÆ5õA@X¸Y®_ákXgµßñ?‡Çdtô"²9…fõ±ºô1N­/A%Æ‡­P*öK’ S:aW­PRŒæ¼Ç~ú</aCh¤ùx@`/ã¤ü$WÙ6âmÇâÔÍË¾`‹4an"1–à³¼Ø¼°m— ş.X¥o]¿& A2 hÍ¯t@q^vOrşwË¤W¬…¦éqÚïÖz÷U2ºw0¯J¶O]„`è½õÛ)'œH%¡¦åFŸ9„x‘D¢Ñe6KO>:ÌH wè'f+±í4[©‡‰.Utù
l¸s6âu²u8Ê&ô¡
u0jB+ãgµ½ğş±:M¡¯*Ù¦Çd;N]µ•ÇÔs¶®%œ"³ü(xH%úø}HØRW„¿ L…,¢¤ÁNNãKÃæZu?¤ëşPÂ5R	Â¥*øN¹#éÂæñ=§5K»ÅìB7äşSäô˜ååD5uôhİ>©æ¥N:Ç£«ûVû°…¥ª›îÉÂ­Í[bI’‰dùi“”0ê˜}yæºÑ-fÆ:	nbEïğ{-ŒQv½î™™OˆÔÊÈ43  krH^ÜŞƒmg–ü0Ç\ Ì¥ªÛ*ÈÅa]shÎQ†jÎOÀ£4PÜŒTÇ"·&ìx‡˜uë„ê49|ÓsÖâ¸“‚eë»z¬ÿ…©§¶[jPö }¼n2¦Ø°—Êÿ]ÕV—¬úŒ|ÎzŸè=}¶ºRïw9½}óšZ7"ÅsÊ^U&l¤B¸‘T ÜQ ŒßÂ8Ó	ØÉ¨}Ô¢eï”mÏ[1šÙïÉ)@ÁşO\zC{Æ%‰Îu‰êa‹éuşóø4œ‘>ª}ój)Ç=üV2h÷ˆ•ÑÒèÇçÉzÀe÷2k~Îşôv˜÷{\"!¤”Qçç}Ê ?k`ŸÎßä%s’ÈkVqDJâSk©tKˆ²!2×YS‰RJÑšxçn´Rgo"qŞIİâ2Q¨¦óuh’Ó§{‘ÏüHÅĞ2Rëğ½¯p! p³sïõÓ ã(DĞÕ)£Eê$ƒÀ¨«Nƒ;òEŞ€A·Q™Î`nKÕ©Şv~FDì4€Ú¬‚RÅ`ÍeÜà}ïDL°pªoİEp¬¢©TÉè'êö—½›‰ş N«	æ53•¡%x®]søø)Ÿa`èéòS›òAoa~N9†¾–å–P–“–“V-aVv=›xŒ~E=©‡|KÇAŞuìM
ö&u}¤Sâ¼ê Fég{'šÚÂ8s7ÇØ=è/°b¯~÷sL`R¤¡ò ŠC\ûî8há¶VÑ¢/È®Y¯Ú>÷¡tU9m_¸{cD@'ù¤ûS)0‰æSî!³á©º[k®²vŒC!ØìzÊ˜]Âáæ˜˜•óWßrO<Ù×‘p;È¶®vÅŠRqàŒªÏ­à¦iJ‘¼Ï’ˆ[¼I%l÷¬¬í­´óƒ›”G‹¶L—¡hôD¬AÇ)âÅ)ô#2v`Õ_«ÍgûX†N6€/¨îál@1yŸûÁÛZBôĞ˜oI@´¡éÆ,’x\bÑ«…Ît,ûJ>8õïâ×RYÀï
©4°ßL
Î%m×´ùşKpÂå©$ŸŠ½a3Ÿüvò²[·2¦))	ÿ\·ÚŸ°‰¨ók@û;ÓİU-›Öø‚ÿ±O?áª@ÚÊè&œMÊ»§<ç¶)±Q¶Wßl½Bc–é»q–È7¸ô[¶th¬Kw‡83,½Gt6´±WöğµŸdfrÒØB…8à 
HÎh«Î”WíÊ¡şwzî±~şT¾î•š®¦ &Y¸HÃ­U‡#ëxvÑŒ'&ÉŸ`g •BÏÔÚ„ÕDÀ'twÆ<fHÂA8í°o«3ZBíŞO\ğøºa¾hOÄÏ„Ô½QdY; ¹èy6ª½·Zº`Ç+U+·Î¨""UÉr%¦¡'.;++sJà•±«²JßfÉCq^á2LníV<4Òã•Ux¶z«b€$Š]¿+@Bhmyü,P;¬R/ô” ‰hèxß|1G9",×cÓZ¦Ñ‚zw*94^/z™Få
:ÈÚcN×÷ÂLp1cƒ¶1|‘²ANK3DïS˜¹Å\¤èçßÅ‚}ö(©,¯M/ÊçnÈ¯Eøé³-%0‚œÊK×ŒOƒ'‘'ÉX‹i@›´1$¥çS‰à¡C÷}ªtÚ]Ü±¾ÛæGá²Å Â³9$LS¢§.Ò‰ø½3îküû¾¢‘ò®‘v?à¹¤¦¤2ê+~ˆ
¥SÀ¼Çsx1‰/Ğ$šB™PXÎáÄ'YÊ¨“ñÈs[Óí{ö(<¹Æu€ğO®!yHÈƒ¦”ûÁºTq3¬¿¦™):¯Do¼óM¼š6ìÁ‹J°2¨»©Ò¹kîş è¤~ôÕIÛé‹^Ú¥4ˆK	ª|á]'‘gF¥ÿË-­dåÍócTs r §ÊN7úr¼—PX”ãxcF@.ã%8±,sä{ .'‘aßÎèp,@"[F:Õ„:â°œù¥fëõÑ¼xÀš²
Çºñ¤'mYĞÒ›Å×Â|VPüOşu<ZpaVİ¡‚=oJ~8)¯’Œ~µ^*•±kÅüÄWq<¥ÚãÕWC—ÀÚ¥5šöá­ìf"luäóeš„'ô;ËZoJüè?C"T¬\%†ÚÀ·0YLïn‘Á«§FSŸîü	ÄqßØ}.Ù3&º÷Ü,‘sÜ=e@¿$ƒ×äI“Z^:ÿ%K$M»Ğ¸,Ô‡æ¥Òï‹ÁÃã¨ï@e“,@øSš€ãqRõ»¯|Ñòj1Ëøù{ÁèL¤æ*@^<ÚÌ¨¤D=u¼>–­x»í²Fê>.º…$ÚÆ|pßÚ uáZ;MûueŞŒJûN
rÊ£»(ïRwÍÚÒÌ<L,)Zäû2Bÿ…Ë]×DÍ)A³Q©ñ/Pğeû5šwgùê$×¦Å­ô•GKÛÌVêˆ„¾E3Ò`åÍqBí?²’À¾´ôîpq›J…gÂ¨ğ`™çDTéznÆE…3m6|{#Aj¶ÃX;±ó£„ÙiköG‚ŞF->òÿnhr=óv
${È„–’¡Ö™Ëïf{{[cûw¨îˆƒ-PNEÙCØ²şèY»ÜL¥28ƒnFSDÌä•¦H[{Zÿ˜d…ĞÖ9¡·óM8pöPÍ?šd»R÷Xïú¬yz> .$s8à#oT•ØÅˆ¹Jö·á£lH´¨¼6¥…s‚g¨l,}xŸãoÒì-¸¶ôSÀ»ÊŠz›««äMWÌzl=½ƒEÎ)iw/Vğ
îÇñÌüt˜júaáİÂaÜi‡ß$œŞÙP’ËLI"4z,rŞ¥Á,»Ë52[o|seü«8·Ên¥j§ÔGĞ¯¾Ã[2x1ŞnyªY0vQı	,¦WêÏŸºÎš,”Ü—éä¶e4!–xê\¯9í”¶¶Î[ÀÇpŸºQ£ ş‚¦ÏÌVRØÆJ—ÒbA¾ˆ½¾|”dëUwlT Uù'!Šo'6ÙE0ğ‘b[}‚\'‡ÉÒv÷y˜åY„+¾
ò¢`HL:¤Ÿ“éÏ¼cFVuû­]ÓéöZşLñvÎ ^=j]sÎßo½Æ;AiÛKa¤T<B7xƒ¥öMÄğåc SË¨™6âĞm†w¡¿îÖTLr8Nj³âïŞg^CıW+†Ê&ºÜáŠ³½ª‹gõÓï^„^J™Q„8s à­Õ.5¤>R×ŸĞáA:°T/}ahâ˜Ò3l1n»â/°…I%'^ãLğ½ÉÎxêÜ»ç8çş¾şeè^İIm#®b/ßP"5GzN{Å+¡›»Â8·…ƒq¯&‡}ü.|¦06ôè¡Ê7ŒÂ¢¨/ÙŞÍ$@íĞl—C(ßAIvÀnÈŠ8¡V.œCÏh¹SÂ":y¯¿‹ùt0eC~¼»ÀO è18Û‡HŸ£p²óÌü‰¶ÿJ
ŸL#²“ì´Õ,+ı ëâNv–¾59|›¹)UƒvëNº½›¯
Åœ©™ù&®ŒùU®íû-ztq9†ê"CÁdêM©ƒ—§“ùñ!ênQèŸ@¾#Ï8´?ÂşU ~³-‡RÜ”[Pı*«²D‹Õ|¹tqé+GŠ3{¯èo[<\ãkÔ”sÁòméáƒñ+B—˜qŸl€×ëÓø%ØYv_itÎõ8à£H3Àõmá«éÌåî+ëÁ•³ùù”ã„(.µ¹2œiß¶«^IL— ‘=³mmëô·"M+n&á¿bĞ3ç^kco¨Ü_İ±v§¾İ×²íÏÕ›)^­ûÖ••ºÇ•Pi¯BEª­
ŞHQª-Á×ğšˆ<x{VÚÃÀÜ½Òm EÒp"ïéé¢—&ÖÎ Ê¤³P&±é7º¿ôÿ‹umf?¹W½m¼[¬^€)^Ø„´X5ŞÍ\¢VûŒã4Á´‡ÈˆÒŸ1(†Ö}di‚eP±p›¸mŸ¶¼ä.#ëİ}U— Ía§Ü…rÊB¶pm£IDzá”À5Ğ=4¹êo÷lOÇÃà&€|L vp	Âú!lmNºÒÙ}Wl¯y°aƒ+u—éßÑ‡›Ö¸&¸&(ÓÙZşCn²ÿñĞï»É?ô…SEıÿ¿Óîÿ‘è7=çàÅF¦f…{Šõ ¥Ÿ×

´Æ°ïIN×]¨Ñ¡Â°‡’‹ØâA=ëZKƒåKfø‚ƒ<ƒÉÛXêâÚ÷šÔje¥Ğ·é³7¢×<X)’ï½Bh3#~²ûE…Ö%5å¡ÁxÕ•¨ú#äŸJÓgş02ë%cíÆšCŒÆGÿ,pÎDCZæ’õo{(@$+3wKÙ²ùƒ³…ì»qV—äŞ¡ÆĞIØ’ïİ{óÜ‹wáET5ZK…Œÿ6³=˜^[×°ïc;6=q ™¦ıŞ·†ú4©Ô)ÜÃ»†<â×6æV@0:`Ÿhqæƒòf¿»¨.QÒÛ&jF pwâş-n3´(–íåP«•XÒê„˜VÍĞÃ_ø•mÑÖÙ	@r–şc9Ğîutj^–ßâ˜}æ$¢Ï`ñŸĞ0Â²¬?ÿ»¸ÁË„¢È•åA£91‰7Ç·úXƒQ±{º‘Õ7ˆ˜qÈCüFéÆg–kPæõ{ššìãÛ£ƒ{é¶xŸg~ŸÓ™„îdéFuOA.¢b¼æ-T:àH¾~ôg©©]Ñ\×ZvÙ«ŸmºrÖ£ôÖªŠêPÒ*Éí÷Êì1ªÎÀ*Ğ¤­ğ†Êû}\R1ü>›ZX3½óå ¤Àlë¦¾wyÍ5rjJJæ³ì)Ë¥LÀİ¼Aµµk‡aÒ)…³!pnòWó6µ°ËsTÎtòkW²¨Œë-[ç	çêôP¾CACåâíO_´êÙ¼„E9{ÒÉŒÇxEØ•ŸßÁĞ ¯ş9Å4•AlÍ.nhNîÈ/rt°œÙ¹}h«·ıˆj+ŒÌìª‘è{$Öİ½˜;Ûwˆû?<yUØÄ®ÃĞ.Mç†d6¼hûÂ‹®}.­0‡‰¹w+Æ·$%¶>_y‚OÍ¶TAu•nlo}XkÛ"˜L—gë¯m ½í?öŠÎùR²W<©çrtÂƒKEªì ì;¬ÆÄ ·åt>yU‡úô-"¨	Ôô§€:Sa´	£”uØßşNî'¦yX–×¡/óO²ÃÆ5évV¡PnTXÃ–@quŞhBHÁ°µ\ªıYÿYÜ9¨Áµ|çp$Ì&N	›J6¸Å_$EÖv…X‚0JØÔòÇÃ%ç®S™Èe2å¹R\.IîiäœÇxÎ•Â–3A]W¦å1=ëî`2öU˜&ø¯j¤r!¿¶Àõ h©Çj&=k¶{16!}oùÂXé‹W’üvÆ¦™›n¹™>L¨Ë2ƒŠxï`
&¬´»5İ]»^3³Ñırl¦?Ô®@L[¤>óœnAm(r?¶3k¬±«èÖµÿ	õŒ²Úº½ŠPbñGY\r0°›”°~olZ‹âcÔ\n4ä
†X¯k˜Y¶¡*ß¬ëÅ€±: ŸUL;ƒõlºH¹ÙŠJš¼¸‰OÚ3OíøLİRÄ%• ˆ³RµÙ°d(x<ÿwFLTv.véjJÃM¡Û¢È
ˆşód[ñVÙ7ğ¶m»w4—á‚½¨#¹2ÿÜ¾íÕÖIaóğ*|²V‘äx¾ª%š#:àŸM‹ÁûE[:c<Ğ“bê†úŠ€×èı 51í¤ñÒùŸ¦•G‰<Š‰¶î}ƒ/Ov­jD±rë•™²@Të>¨ëú–i‰ü~³7
(Š~9<EFúT³8!­4@¿Ú:¡ßğUè^Imïa›è4”‰©¡‰ˆ&£³f$ö‘ê©Çh¾Ï×HXX4OõªGÎ³CprúÌË¤¥IzÏb…Ñ·¸à""Å„µ%L{zUñ\¾˜™és6¹D¾€v —,]A†U|ëµòÿ~µ£aZY&äÌLÏ•ˆÌ½Zş Ô5ihµâ—,l¯¤VQ'sîp
ı&Ïş¨bØ´Ú¦O†J÷)Ï¶¢‹`¿¢o+Óón·ÒÀ&+ÔGˆƒ…ŞƒÑÙ«IÙt'4p÷ÈÊ}T—h¾F~£šL@Ë“cj¶¦ÍP¶ï4eÉ÷>–,ge"±ğíCİşv°OÆl:<Ü–	öÑ¾`‘îaÀA»—²ª˜RwvéŸ	Ò°D…—ïC ÷ÿ6kÈø¤p£¶÷2×Ğcî‚êIäš³Hã²I«m¶Èõ^Ü±}ŠïßútµÄ:¢«1èóšKV€‡úKU™ÿñÇƒ1%™­ÿËqÏ#é35>Ò|r9¯IÉ†×y‡_ÔÊ ƒ„ò§cœê±[şïE0ˆö]
İçòZûÚZ\OQ„y®“Pæ`®kx‚#l)E•~R¿3·u™öôu}v®Mécõ7ÅFú«¶—6¿MJºá¡4C7ş˜ì•ö¸¯Ì›ßâ7X®¦qz×0ºÖÃÑ¹>ò|Ì›È³„pÒxÚ!<tZ¿€h1O$3¹ÀtÿºFÎpB¡@ÙSE{`!„>Ûvh°°>‰`"‡b²‡Ì‹²H¦Oñ™­Â˜Pæ]°–¹(t[@·¸ÏSçn¿ıøòùïı_kû­Å­¶>ÕkÍz19¶]o’Ù–LñÃÚ‰ä·%x…*.mÇJùœHî7H`s“bÉmFEjz÷›JÁ¬3#³Jãå4 ƒqRÁ5_ Ö°AYÉ#—¿*†lÜM&ƒ¾§réú¿ÃÃ2¬J
3‹À@Å%3½`êAĞ‘C)ä”|€"é5g$ÏŠ8¶’İñC…_uàQ Í>‚.ä›½¹P¸øÓtqd€à¬î\~ùgğKÖf ÑvlÔª_0ÌxªÈ:¿h¥Nà‰Àïø*Xı¨$"¨‹×"%!lvj¾uy7÷/¸°`Z[çlÀU;E%AÄÕÌ39ÿ`ÜŸ Åìy,|Ë6‘A4ÊÀ;„°@dïIT?‡˜ÅÁ-ftßg¤¾·GPš\z!zQºã.á¨bLŒUÖO^ŒÆ¡ÿ˜YÂpê–T®êû0g£ô_=fz#+d|¤'Ñ>~
Êjíû©ZøğûDbcIssä'-W<aVPd;ÚÖßyøÉ$ƒlQÉ\`e…Èü ¡RE˜Û8Î¤‰àú’3·vÉ[ı$¸9í0xgzö%çQ^Må™ék ?†Û¡ÆF£óF…À¯<¦¹ÊÂOåPÖ%Kr@&²£ôªb–sK›}2^¤ã#½r!FñıÛ^Y!™ÓH[şú‰ZÉ+ÀE<QÖe–í÷÷fp®ÒÅ +’Ÿğ»$œ"ÿ\XÕ¢«@²<Ä#7G\§Q`4z0,fùÂØZ~<x„ÓG:æ PËšaÅW=R3o"ó+ª'> ¿Ì~½0w|å-4ÏÆu…Í·Òçå²¡™©”xî<şËK›gS4ËÑ(;*_¦*W'ºYãóêÕ­ä)
·ÉˆÄÈµò—ˆ •İåtVjYeÓK‘Q®MİŞÄÔ’­Xtª¯ÚSÃ!xÆiÿ«GôyÛ4‡ ü*b§·'.ÎN "#ßBÆûéî^«Î
¿Ì]´ŠÉB’w^½Vö×#p‡e}¥Äõ“Ì×½Ü„‘Y+¼‘~¥	³æ–,§n‘=ªv¸?}¢¤ú•şª´
È,­&ágÉg8|Ò—üõª:‹v4KË³E‘úû7÷ÂæfĞtŒ€°ÎîËĞA!Iè¬VüÕë^[«5di/j{3Ç91B£‘›Ô˜g ß4™ÅóF¯ß"Pº®i•äÂ½»²•uö¿Ñ´Å‘üxV÷0xÀP²ıÙµ P`ÿY›ğ7BüX$rcQäfgPZĞÍjU‹Óò#&Û<‘"8@'Kn”×Çå˜;tÆ3Ó|üÓ .‰™SYÖŠğ?½_§î‰³Ş½—õšz´'“—ÉîûÊŒü	}ô¢yˆ;{‰fkvL0ğbÊ&Ë)$Jq¾İ3.Šs{¨ã˜ƒ%Ó¡oC,ºŠàåAxÿuÎ·êÔ:ñ¬ ¨¸±°Ã³¹¦ ægşœ¶¢.ÜÎ‡ÔºêÛêTŸn~+¨ŠšûîØõä%ÅqÓ›…›¯~ 2q(Ôzšºu¾«ƒm4c2G¿	Ì´õ¬´l’PÇ$A1fKòX•0-bÍˆÈ:¸kl¬«(”A˜—á³!ã’DöX÷H¤¬âá»ó0@C"ç\Êêî¤<R^æüï€S€«¶¾¾¥Öä–’ƒù†üˆxÆæ#ú5¢ üÊ¸+ÓÌ”Y‚(í+Ê<g>£¬“×àeµn•]	¯-ïEÁ½Ÿó,Ab0Û?ƒ	ÁÃ“‚g¥êÛ88(Sõ-i2â@kZŸ¸ÍC¤t³Gë­»¼Ò@ÜÅ›rGuü~	ŸZØµ‚²UĞF¨Ì‘BM'|R'rí?úaï3Ù‡G„¯óÒè
=+–Çüƒÿo„Á7ªı´7üÜÿföı@ ¹Ti+Ó}ŞïqİİşuK6’îŒëMäÚ	·8Ä”·˜V’ß²DD§©neéÕå!øì{ŒÖÿêÈ¼¬½ŞW&oŸUšlL€™f:Áz&îõ´RC—åÍÎFzxq˜³Üšº_é˜Às³#²Â|Y´è¹1‰zÕK9Âlzü4ŸQ†ÅjY£nY¼œînP£Üt™|Ìƒ…á´
¯±n/eöR>Úİx˜•%\º‰âCpHv{$ÁÏà;¤OË~ˆÑ¼"Ù6ÍÜLÆÏâXÇRÎ1¶jş6½ãtšèQš%ïè÷Â)+
	ˆ rƒû›·³J)&¶§	OÅš	¼%Fÿ«~‹ëòxT-.Wp¤¢}Ù¨ì~[Nfâò]Ë(:[ŠOmô{•†`”…%YŞ2Ñ7,ÅF&ê“Ş{W]Q§ÃÍOë\4Y«O5ù¤`­@Zó²{øNPâi:^›ª¹J>¢=™vÄ$IÆWÊ½KiqpÂ¾ÅğbKğóaåŸ&ËLrµıÚošdÆ"YxÉcz\ûè_ñ¢õÜ¤K‰¦SŞhâx“ğ»uåhxş¯‰2y—<€¥’|Vgä&^V&4õ_º‡^B¯oI)yÊ^àì¬å/`
=‡EV9!]âã‘½ŠÌpºaO'F
çqhÉm¢†½ ~‰P¹‘ØìSæE¸ú™jÆ+­bùëW9%S†åY° ƒ“ç,všì˜Ä÷×Ûü9'´¹\Ÿë-*³¹MUcóœàÙU¦EßÅÆÒÒz^ytR\€ù–ƒ+Æ;H™ıû­m‰ÆsÏñ¼‹ÇŞÃ trNRV:ğó¦Jæ'^¯M§E´ŒÔ	¬9úzJR/äµ}ihd’¡u?ùí‰|ŞÍ9{#
ô—Ô;ÊÁ›Å¨°Âl;¢ùmï®2$#PËPó	óMğ6Óv øJW`ê3¡ Ÿš~âZNÓ@ÓiÏßw¸G®:Ê(R´åÓ¶)yÙ‡x	 îÔvã	e%ÎØª“ˆñz“x!Eò¬_{úëp†œ›ä¯«ÍÙ?ÿÏÚí±Yú@™d…/…¬:˜Â]œ§(¡ìg†»Ï\€`+ÇÕu¶?k.&š¼H~0û´OdU'Ş=ô{‚Ì	ì+¬u½Ï}…F[[¹§!Éò‹ªYx Ádgf/¹«dWûô@ÿÂä¨iùÇ±ƒnİÄuº]¸šøäO€T­kß¦«‰.Œù“–Òs¥¿}WÏPUäzk1ÀÆw»ÛKpaÃ”<Ûm>Sé:ŒÆÅÎ³d]Çš¦×fÚ
 ç³&ÊÛ|l¸$/î“ïİ›=Î…ØKä]Ù<Ñú´VòÙà—\ywQ2ˆ-nEy©ÙÑ¯®H¯¬sH@Xeì®¬€íåR¬.0¯Ëj‰ú².Ÿq†T‚£z^íS˜ è¨,Õò‹­üXÿ…I&’Qà~Ã5Ú5ÓSİ"k‚T+Päà¸gD}Ÿô(?ü@v“õ¢zˆåCàE¼®”3[ÃûAØÍ„ç~‰ZU®{ğu¼@ĞÑE!Ú‚Iîƒñ‰"r#XX²³™ÄøİßÄ¯4øê÷¹é¤e›Êj4_œ ıç[á¥¶½ö4å)|ºnÄ®ŞSWHİv´ºrD¸+5-8ÉSÅÖ'ïOÙLfm%–ƒ\^ÄZöUF:x©É›Ò0+°Š\ì1ëV@DmÇı˜âÚPÓ¾Q²cœ5Ê]{e—I®ƒ}2oÎ`¬]ˆ}3H’m¤l^Mo·KÔ„à®cqš53”¢M:C!«I ©W‘q ’1#ÃÕ~R¨‘Wşác>¨â–áÂüËU³†/KFCZÀóàğö&­.¹OlVmZI¦­œ¸°Ô9âxó55Fš¶"Vç—dtµñH®ìıÄ,´ ˆÿ©É5Ç 7q„’­•Áé*ÚÒöùòä#iÕV=v£_6ÁÆ¶»¦ÉD_z³FŞ#¸ ƒv`k¿şQ	CıãT‘IË¢\;‘·8›Ä5è9Ìİ•xÀ#{ŒºwÃÅcPÙI/µQ>˜-`¬ÀÌ˜Í}:z61JjGq#@SH/^êXTº#½Î½Ë•ÅA|Càsû¸
¹!“W“[LYî–Û¦¸‹ØÍÁmà/*j½iÄÛ½2»¦. û(³÷ƒÃ†Ô«“ådMe˜‹İçºõŸfŠüÁÍ3j¯08J	0ñìÊæ'®¸ŒÓ+MÈHšØ!ôh<Ê¸FÌüÛvÁñ¥âú|€TEõRE_ !Hë¶N\\·ÇHÜÄ€°ø<Û×ò&Â}¸…]Œ?pR;¤sÇ&KFÚş _V±8“‘šTö>îü·¨ïË}}/n5œÍÚBLÍ* ÿ“^%şE‹¹Nu‹âæzcY¾¹š°¾NU¨½–ö²è/—IYD§å~Ó,/2¿.økŸ˜í×°Xj7y}çíZin›ı`ãˆ¿³V¹Y"„>³Mş„âÒHK!xÿÇˆ‘‰]3j(&·Ã§–èg‚şÑHÆ#wö%ŒV-W¼ÒVÀ›¤0gÜ :IL²Z#ËâğYï¢Ò”y?åÒÌœsü·7å*à…9à‘4ÛVi„)#œ½XÖOoƒ[<T]gEKZys$Ë<O÷½’šÛ;®‘»ë\Ãi†dÀ¬DÚÛóÂğ¹)”*M¶9i›%>>LŠ¨·J>Ì¦cøŸfìj L±¢™w¢8#fºHçè‚.¡ÿYçŠËˆ	|5!/Ìg;ôÜÈäùÈÕÁ^ı§9ÑTCzrğÂÙşğ$}Ÿvî(Ö±{(„ø1æÁÿbEMMĞ`OçÕÉ«z¸så<×±DˆW?¹\ûÈ¥Ú`ŠçŒY³4Cªü®áuQ˜¤ğˆ²~+p¯L1Z\¯-—ÌeHÈ×¬ˆdwúC8vÎÈKÂMÄÍßVÂMtŸTf£B´ˆŒ–İäøz{ü;9]uÆ‡
n ÃF“M !r¢é‘ÏY$ƒŠÜu4Şl¨8JT· (7ÁˆNá\ëøô{Àå,AÕÈÆåŒ,†æm¤4XëâM5YÛf*™²f¤JøŠkë‡1ş³fÙq	‘ ùt@ÿÔŒÒl#ú|Ö}U2ÄÀ›Ô°\…áZapê€ßwe¯™õˆwµøC±¹h˜ 4­ô-t|1~¸H'5Å]ÁAèš¡OşÃŞõ3Iª'4ìÇ‘ôC9è ?‡¾yõ
ˆûö&T;nF×MXñs}öÂ.1£C@X_wã­§—å{òA“êÙÇ­`µjRëUló3hàñíÓN£Bï ğ1?BåÕ™¨zœñ¬„§Ÿ¯TMì¼·'‹%˜ñ£‡¤Ô½ü
Ñÿxé’Š9¼\¤À+!/a\¨lº½	d™·èÃùÄ:ŠÒˆ%öõøÆğÁÓI™ŒÏhs5ÀÌòÏ›²˜ñ¯½‹Uë`÷M´ÅtÚÂÔ_ã†êà9I«yàç~ÉsïXC^õ®Ö¶x`%/¹‰sÎàIcsRs=	".4*c™Df”e>x÷Nütá"¨Íqn@'éÍ¿…dúÚ«¬Ñ4?kFÊHråˆDó7©Y»6ÌW§ùá&7	U%:Z7 zhÂ(¨mÖµXÜ}L-‰ùq!åXùXƒ k"KoÆİ@­Ìtû‚ªVz»°áG¶XOê|âÌØÜâfõ‰F[^å6pı	sIfóÆRfşÅB°72ò^³¢¥%–Êg5bÃHÛF{\ÆdFÕ[
5ĞÊè\K†3ˆ=L¢¥]‡¸}]
-õ¿İmÁó%Dt©I ¹Äô­äï°vnà»üàf>-gÀ'DHZ{î¦°rÕ5Ÿlg\ÓL_Áy™7FŸYYìí“¯ÕÔz¦á…iÑ<B­%Â¨{yÇ]'#jEJî¿ †¥ãXÔ?[7¸òËYY—×Å‚êOV`«?‘İèÚ#Ûg{£tb4S4M¸nCeÿ@ˆ¦dàfÜW¬˜ÆİŒ=„ZÀ5Èå)¥C[}Œ¦ÂÓk‰6<_»+9>~‘ä”,¯ÁvRÚ†a“Ø.+±«°üj/n’iöé8¥…Aåÿƒ&L’¾0M‹ñëH<è'ö(Ì\óS7;T;ÔˆZænÃ ÍÈ[wJ$öuÚ§o'—E[£oz8‚*Iı×œ(ÜAf4‹õ5)e
ë™ä]×l‹Âƒ??ÛZ,ÀÕé°iK±-™½]–àÿjNÀŒ#zQáúıM;‰ÁÒújÅºîMÎu³us0›šEÂvš‘µÎ3ˆğ8{·ÅrÊQSÂMÛåA³2J}fK‹ÎÅæ–ˆTÿÛc4aEëÓÎ€)˜™K'Ç ,­¤d["‚[ê-üZ¬`v¬r{¬’ÈÙ[e0 OC¯âó‹Gb´Èç–v´:lM¼ºø5&TÀešê•{hea#“‹À
€uç¿b{K½l´İ XõP¯“2şàÌŞ21…Ïp–<ï3Ö„U
Ã"Âú#lŠy~Ì²W!o‚4«up#ÊŸòÙ‚!6h8U©*7¬§
$…Ôt DpƒrÈLK¥Ì]uî‘s¸ªNòO%¹İÑK¼'J–ØSú{	9¾Í6‹©+á e–ª"‡ŞYôè\Êp4>ÔèA›áÄ©t÷ßÍı‡Å;t€ù}¼ÚÜçšêŠ	¿Ü°Ô‚“¼%DÜ˜)¼^<ày[Œşò$Ï}ò¾MHŸzq-u‡@ªŞ³;=YÆ¨%HôË	0ûb[Ã>À‡r4–W"ñˆs‚ãîHàS¦<†)¬|£ûØ'áâü¡—Õv»¸oîÙ{7„¤ÆïÈW! qÒÊÀzn©aÆüûX‘š¬Óx[w¿Ğî·EƒÓ^TgjïÁŸrU<ú,T,<­u{†#>V¬N”¦é¹u™dXì
 ²GÕ³´íùÈx,ë§ßÄ¥Ó÷CØIñ@—ºÏUel'iµíU;dg†]ê£y¬1YÒ'6æ9"×»=Ÿù¸ô‡.WbJ;ğ O%‘3ŒKB>
0ÆUµ¤.› ş
&Üss9)?èËTX>1‰k²ÖÜõFáòo-…¹ı—ÒpÜşlíµgÒYüÜß”oìH$-“ß‡bş‹µ¾t`Š¶&‡¹Î€YmXhÑ’!™›Xåo!% ÙW èü‘&5nÎÿìy£/j_cgeWæİ³¢P„‘ù÷¯öt4›šU‘×b S?6ÍèY×ƒSê¨À rĞ-jéƒ‰MaÈ}œ%:jèøs”Ù‹YÌ†Ú7˜šæ`NØçËÅ÷´!µ˜G˜
¨1¨öšÅÛçØô8–Ğò!Z-½}­›Ğ0*,Şî¿h8åœ…5½]_‰éíjÂ«ë”ä¹{êg1—¨·hvtÅ9\ùü^.¿ü½ê,+< àÈ®Uà½Êõ.aµ¾HĞõÙhª9úsÒ:‡ æŸg	›'ÂLdñ)ÿØ4U(‡#'
Ûœ•È'à6l‚’&ÊĞ±UnWïQÊøÓŸraÇ¸¥×µæÊY`Ÿ‘¶—0{úÈ—µIÛèVşÜc_çİ;÷£Æq%;íç#'-?œµrE¦)Dº¸[”}nÀÑãs½Ü‰ÏÂO…$³;ğz¹£ZW?[Ök²ó ~ÒÙÃÔƒúmêÜA¿°ÃaÖ½• ùòŞsIY¨¾2Æ<£ø3ã¶”š ˆi(if®iÍÓ˜.Ï¼|·ÿ]GåXÃ•h;ÂÎÇ¥wômÏQx9êêøvOœXıAsxñùC_çĞE9>œ¹>ú|ÇÃ%şw"Š¡GÓÖÙfİî¾"ÙaèÂƒƒ­Ø.~.8ªKkAºÊcQM»ÿÓPÜ¥ÀpL©é±ûkŠ9V{G_2•2J0LœA<ïí¨……ä°;ûR¸„5²X”
—ò—e~‡hY{a 
e¹ÍGƒŒcb‘ìqğÈıÒÇ¯»•¢â{KÇæ¦Ÿ~dºuŒé—8IåÁnp
YÚàqø§t¤4fE~kF7t˜‰\(ş(^Ğ›`?o_®ÒµU[œ8õÃ'5[q)M±H!•M-Kg{ÚRlSkút¹¯L7fSÃJ6‡©i «"ÆG×8"N[ŸP…%k·‚•Ûƒ¾ÑM×CŠ3gW¹“9±{Ñ?õj]b”ê¬Şg`b^ƒA‹k9Ç¡hS/¥àæË°£zÆ…%ñ$?osH3•ù-
)ˆŸˆ—2ğM¸r¦jk/ÛÏXQ¢k6ı"Íª
N$>ã‰’Ì&VËz ¢|Y s„êÚÕ£ìI‰ÇQ7ÊŸ)¹#N“MIˆOxäÂb¸«¨Y­<=ÜU•§:ÀŠ7—Íä«
<z‹şæS)è&'š¾šĞø‹ù$.÷mıB UÙœQ‹Uky%xÎb”Ãcø.7~O^Ë~ÏÑÂU°©Ö",êŸ«ş
+}§ÜYû`Ó*œ›‘Fg÷
7¡èPÛ¬äı"Ñ~õ<ß/c@éê.@ÚMÉfåG’™2Ø{z›è,k67dæt2v”6\
FÓ|¹!iXàSVzÍ%ó¬‚Df—ñ¬Scšøº1ü6wÉlêÃ¶cÑ:İ³‹	/ââçòºÍtDjuüN¾øšÍª5a_(¶:×ëÓ}¥×Ï.M`f-Shí©â½:YoÃ,~cĞêİâC×LÈòïÉã„*¤§rŸ¤÷øfÔğ>ëĞS¬§¥zN¿iˆ—Ê-hc¥ş!°‹çM¾|*˜AÿŠhó}
§¶ÌŞºª•5G#÷ƒBîk
8•Í²9İ^C"< °¢×µÃ²ŠmááÙı.Ëú—£x©}`PÀ|ª¿PgØ¢3ñL 	ĞŞiëxË@aïèä=Ëœ#T¾u	¼	H'k<Q“†µZh-ÎîÁAtUøxO€Öz2—v Î·ôW vĞ–Ö\p;Ö†kÖÛİ‰RqK÷Sîå–‚pQ4Z«†ÊÍsx‰öÒ¸¹²sœêŒåÜwÙ<ŠßPs¯9ŞŸ¡ßûˆ4Ñ=mkn­Gà­¬ç[/M:òŞÕ™d:»Wnç&óÖ@j­Œ¸Q½#Ó.º)pÍ LÊNqqœ¯Í¸arº[wÓ]ÇzÒLTKÖ0ykl¿®¢F5"\­ÜÕsÚ•<©dñø``8_ğ^ :‰è+é§#×º€»Ø(1şÿŠìF ªÛçFİĞo¥  àpà$¥ÙF¥2/ç ”]äß°1Ş5®FÃÌú"–„¸-@ByŞ×78èŞŞ—
][µº®“ÀÈ]e‰Š¹T©§SĞÄ?E‰0™tn“ãäù$;DA’òÌ"fG…†>RÏÂJåqzyŠÚôâ¹	íÿPÔ*)!‘=Ë•bªŒ‰û±ÜÁhÙ
Csû½İ§Ög‚Bı¨ÜË-ÂÄN®,¥RDĞ96g†ŞŞµŞE}qW» ³ª à)Yïó+qI‘R„]^‰¿ìÕ¤U¡A9È¦¶–¯«ÜÊk¿§ôÂ¥×¶†z)ÍÕ
Æ	°¥9€kRü©MrÏk¾^äŠ‡O,ÄÏŠNò Ø¥Ò¹t:r†FeFa‡PaÑ9€„)¨€K*¹æïÑÀ[ØíÙ]O"‡£ä¬ºÀDöˆ?°hÔ²,eS± ëĞĞKÄªÖÒèåú†°¦ßË€3•ÀPD³qÔ4$è«E^¥:î5C«Ôr¡\ºZG;¿ÚA½ÓcÓ‚ßšäZ[Aºiwä×­Ó®tN’§šše*Ö…nŠN!®†İ<Ü¡÷Ï<*â:K4ÓVå®]ÍÖ­½5$Û8­‘¨ÇÖVfùåØ&Ø‰áAÁ«øê÷1\u¾SU\3Ä:K5}¼B.Ì~[^ÍE¹u`ã@âÎi7>BdL«ç»h›Îù‘uü©FkúuT³BÕGŒ2IÖpE/N¬ÂÔ°<ÇqòLÓ @¹¿é¹&kA¼C¸®„¸mc7C40¢—w9<¬ÇuX[y~Jv©{IOæÖï·á)…		®~ÑXë-B,ÛCc¬ vÑ>BİpöÑ’ÊaĞñ˜}¹ÀËy¦^†Şà%¼¦Äl›m?µëõv{«› 6ÅËI#fÖç˜uù¯)©Gê9ç4ANJ©/8ª[vÑ8³?T	ZÁ½DşZÆÀÛŒËtKñŒ$g{5ñ5•Ãİÿ{»˜”¨9ôµ¬Á'ÜêEÃÿ•²>[—9·–kìÅÕY>’õğr	 xsí{İËAÎ½İÏ#,Q_uFÓ‚˜{]Û46Z0Üü.‚'ûÖdo/„+IX%ik¤½U­UŞí?èè1§­xP/‚APxüçu+ŠpÁIÚ9•¦Ñû4]	ëÑvlZ›ŞP)tª-k!ŞuÌ~6¶VvÏfBü]‰Ÿ]y7ƒ¿Ù\¾+mEÿƒf/11e3¬Œ¥¡.·òï%‹á·,ú]Ğïûph¶`ån³sûæÌåéÍT*KË«z3¸ÄMÎ¼|•MhòY
?9Ñï8#t…‚ä…„I°²³»ÈÃ¸Å) ßxO£OF$K%NŸ¦—Œ:oG2ÙZõW5“Â½Ü­ŸH DuAû¿ßºõ¡|úŒİtú§Ôôîh%ğaö¥(³×Y÷d„¡\8[îp„ÇÏÔükèzSïÕßêåu+‚üzvÈlCsû°Ë0##šn„¡šZ®*_u3ĞQ}´t8}X>[íg
ˆ5ÀÍ3›Oaw³‘äoÃ¹öäñxÓ…edñm‘(f÷ùŸIÎÃ”_/rTì>OŞêY–Y-¯˜	»W»âdì>\5hœ§øãæûèıÿ [uoÈfnım››¦Ìö5™î¸\"ö-c.j¬uœÛé‹k;âòëüwaúcnÃyğ/EúÏI?Œ÷ËÈ©‚ÈvnÍ­8€æYÂc³/´kÌ÷r\wè´‡Q“ =ÿH´ß3ˆML—v2÷ƒ¹ö$}‡”­['cøó0—øğôŞU†	ÛÑòÛÖ‹ÔÕ†Óñ0óıud8*zòèøË"ÜCî¤#\Íë÷Š0šq%#Ğru$VI>JÛçÀÙ[=Ÿ&–Rù2$)¤lĞY¯ßóíRèÅì«ŒœÃ+¬¢ÃK÷?µ„|QPÆ“]¸–{²ÈÜƒÎÔ:‰Â9åšj¥Ûl ÙJş_‡NuÌ®J”-™şã@ƒûâI`­çÎe"›!ƒŞ#bR^Á¡‘ ûø`u›7u$>csH jjß›xI3ì¸Ìù.Wqò„;ù%xS=¬ŞÏÚ‘‹¶Üÿæ¼Ïï•´¹2Ş—mM´³WííuÚz™Âzè{Jæ{Ş×Š‡PÈeĞ9%P«	Ì‚6Š¹:Ô¢‘™®`½\‹ı6tX-Ù•öŒ	eùÊƒT…BÛC}Éìyq/CuœM õWõ¯Âqs°n	^Vud£c¹…ò°9ã÷ãhëÅ7_cZê2«¾‚MÓw”h~‡¡{Ğµè(RT0Pù™ ğÌ4;ÙA ğe†Ç[:Qö1ª\§°éÆìAÃ3ŸGKè¥Ô—Û«yZœ´ÓøŞF`ì‘}§ŠÖ¤²ê4„ˆÕ0‹ó½yHïµR|šP˜¬/vB/ä;™mŞÑŞ‚¢Í P÷Ôœ­V€6/ÿ€	*^r›ÇÅOæï˜Mb¸\Ó"ƒ†³°ä…ÆVø®Ô/mf‰úõ>£
Ç¨iiçIæfåY	à)?îÿ¿V9ój‚NØ h“n;Ë³?Eñó”¤ıS<´.ê˜ı…|.óHî¹Yü:¿Í­L:Ÿ¢×Á!UızÚ.uIt±%ÆuXáëk‡c=é1ãjU$J¯ÈĞ_°ÕÛ	îô#YäÅò88¦|ı ¼cY’Jä(«ÏøVãJËÕ4ÛAk†dbóÙìÊkUêÛ·†‰ ÁºqÚª÷y¯¦ã†ÖØæcXÚ\ŸÎ»ì¿—•ãnŞì©PÎÎ/Š”£’	ÚÓvØK,ï¨Ÿ3 àp
ï¤É1µ±&‡qïuD<º†¹söór²©A±Áñæ›îÍ—&!;ŸË­*¶AÅ@¡ç™…èı_ØÇ‰µ™ÿM#¼"²7=’¾k+¨å}3*	‚ñY¥ ™&‚T€¨‰®û¾ÇŠ\…¡¥Évø½>æûà=C
’ÓI¹|]©ŒeÁsS©-Shn1BaXW&’™>¨úàÕ¤/Ù˜Ñ›*1{ÚJ’w®.wÀ¬|–‚Z(…ÎÓKçätEÂıŒ¨b5Dê¶Ë÷uBÊòoHvG¨?½  b–õ²©·…ê¨£èPº ]%)•–[FÆ’oˆ_ÒÒÓ•òãSú†Mó€½Ã£8bQn×Øam­ôoşµW”9ù¿{úª¯	Ô–ƒ\›–mÍ¤½J•]åY8 Zsû­Òô…í„‰¶K«tâĞ8¹F–&qGkìRÕq$&RcŞMØ2İ"Oç-×’¦“a#ı±šÜRÂJˆ¹Ÿ’Ü>JÚ'‡­>Ê);5¢rR~MOË;£úV‡Ûü&úœÈ6
PôÔ|¸v¥FĞD‚ZÂ39¸‡ÿÄtnşÈ¿…Ô¶ñ ÜÅs¯.š“Èì!ÁE ºÆ™¸	ÌÊ?eML™†éLôºÚJ¬ºÅ/Ë·S'ãdEõ,»¦÷úö†ÊcØ¬@tøñKIâ$s,à•¬ÒÒ—Şr—v³§kåÑœ(ôS$¸1„èÙªPÿ"FÛ‰ˆ	Á[H¶iæ%Øø=daWhÙŸ0,ÏŒâš·ŠÏÁûlkªla”PfhôÅè‚˜üq{Çî*xƒCÙKèU//ÌøL\§»××‚C$„ğñ´3Eö<ö#õxŠÊƒ×D©ÇT:oßí¿B•}"ND²«ÚWúÀ!Bê‹7øN™Œ0fÂô¹ 2+Uè/–yfÏøĞœøòÊ¨ŸpŸ—!±*¾2ª—tÚ˜´†LV±•™#óÙiA•¦¦~0i
¶6‰ß4bØ>ÊkïÍ§öçÑÅ²6uĞY­ş—Ì½“(°ˆTò‹»ß±ˆE¾óÜ.#6s†…êĞ7b¿¢?‘Y¶maO£‚`°¢B–"O¬åº1veÊ@> ÃJ=„”8‹ğŸÎ¯Òô~(1å1Ô¾û_ßÒXúT{ŸÚ®¤§J=É©!i>æƒ{Ò(Ğì÷‰ô‚%ìN~ßˆÌĞC„x%™öÖ‡Åá:¦N¤d   ›Ö¥‚3 Ç€èé™±Ägû    YZ