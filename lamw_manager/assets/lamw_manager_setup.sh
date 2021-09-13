#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="532006236"
MD5="d629230e28a5d36fee1df5bc102d83b8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23692"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Sun Sep 12 23:41:57 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\J] ¼}•À1Dd]‡Á›PætİDöof³Ğ^GÆ°ÜÓ¬ÄµÙoö™COüBm¢5K9šås6Ç”ãdÿïÀgÎªáŠ/öâ¨g”ø¡™HD®D¶©fgÄË¤®Ö:áD0:+”f‚¤yw9ÙÉ~R­N‘~½Â€A‡xænßiXö&¦o3YL¿ñ²¬µ3–HIde¶ŞWE1…Áşú@$(Œâ8Q­´ì8fÄKùlØè™š‚Õ‰¸ŠijI»ÉT|<;™d>Bì&0SóZ8E ”^ĞcÅo^ÒNĞpm@ˆğMzh0ı[ÁÌ;M…ÅÆÓbÔö…ïïÀdGÄaRåı¶P^¾›~ (CJZ/Jo«]GåyA´h	z.[ğºIà…@Ìô s~¨bm ¾YçGßGÏvş>ë/IQ(c9ªs½ûV²HÌNèW¾-cAç¯i?%µm®ºX¢Pm Æ³ºİûgØtzg³Z„Ó"ÿ9•Ø‘Û,'"E)Ûrû¸¾éB˜$úM3Ÿ5¦¯it!"¢;çôáJ&üC‚	´ËU6ÌICñY9“<Õ‹lã‰ú<gšÑĞË¨Ì³Ö¨~¯‚³E‡S\¥?€`Sµ'ÚdeŸØ!“²4üo›îÓ·ì]Ÿ®ÂÃÏ-±)Ö-R%¤ÁôK=ZƒƒÀL¹%³¤Â‰ñyW¦ìÁhWGå@›ië†Â•q;`ñ™CjİV€éÂŞËHëÁd–qºL—¥·W(öÌ“jdr!´¼¡}ÖUÌ9‘«ÿÌ»g.öDÎ„ëëÍyyüµ@şÜÒ ?óúN\dÜÈÇˆ6Ë-úY°}‘ÅÙ#e:>ƒíÅÙÑ…©\- ç^£æšÆ~«[öÊf’×aZ	…w}aHµäq~ õ\i4æ®5‹ï5_øø¦s1İ›/HEËqÙÊue¶;s%V½¦ÜŞM×úuÕÉ.0«{²A;jnÄ“DÛ³ÎkV§¾+ ì²”F,cµ]“–˜â"˜4Réö¡H÷»*œhá ' ½©U…¹;O)}ÚHa _±¸)7nß–}	'v4ğ„¢ş +š`@Ÿâ1ò3š†5ğCğø€j VDº¹Ÿû–¹/ËsÜ+d‡sUòÖu™#È²ü~‡Ò`=øÊb‰––Y©$îå¤A&”øº†ˆ³,¿7üÖ].û9¸ŒáÃ÷ÊáÌ[jäm*ÓoàIŒ„ÔvJ»¢,ÌN™'şÁ+Ï(è4 lşôM"%Ù6ñ“gbğ­o–D:±¸Õv
~c¨¾¡õŸÕ.í³â£ŠEëv‡–iSì¿»*±,à½yåŸÔZ×OîZd'¤'ªB]şß‹•÷
¾¦'ÒtjIÔŞ´Jv*ÛFoïi–ÎK~tkœ–ê2ì Ì,¯<³1ş>0UvFLÊ¶ß“ó ¢<qèæ ÖzFïÈfôsR'øw}«"‰A££Iß¸™¥P0Z@Ps‘€‘Ø=ï¯p€Ğ@^t ¢n(4ïFYú`mÂ’È	p„c¹(C¶*0„ŒUÂ1ì"•F…Z~rGÁÚç™ò‚!şAKIÕšşç@j¸™.ã3¼f+rXs´lx¦Ew×ñÇ^ùİ¥†©Ø¢Y0ıï|1esf6şs9?yÿ82&#4=_Ì÷j¼™`Vk›æÂÉ~rFôì?‘~Ëe(m<sV‚[îôµÉÇ`œ•í)Q¶;¥¹×‚êÁ°¬;û:ÿk<ƒa@¥ÓX+íÅ£ö^Yl¥‘.»n”Z. âÜùÒ±xùÚ#áªÉø¯]/Fšx1 ¡§,×Pøk$npDÇ
 ĞxÓí.£w8!.9õ”–4ï–Ûzp”*v?Œ‹•8ép“ÏF„Í±ÒÎlÑ;SL-ò¦Kö™¥”Ë‡ !ÊÌTŒáÑöï“W†’üXd6	ş+,gwœ:èv”ğk™µ©Xâôw¶.[úB;',íZJs]¥+Ï“¯Ê²R6ZóŒŒz×…±6›ÿ€.†ÙZš¸ÁiiºêIÜŸ‰¬lâ!¿º‰L»RØì!…ÑW·ş^L" dB {•ı#ÔCÃ„Vëƒà»m~áÉcZQÇÆQÅZĞÒìU;«ße¿‚‰™¿Lyœ?ùºç±(Ô1+ ˜a–|ChYÈ´"…‹ë©DC¢q2 $è©äöåa°2î«óª•òÃşÆC¾
²ù•Œ>%ˆŞÊe0jì%ÀÇ¿K€Ü1\fÛãôÅaÚàX6C l}èGŠè/usD@.éKšL7ÑÂ W˜qJ€œ'ş²[öü·äÀIşqÉhyi° C~	Ú•-›â“Ogé­9&ÛV®ãê…ÒÜ?d›=3Ä˜ÍjöÜê‘÷g¥^Óš½PÈÒõÅ–YÚ›ÜŸâGl l5Å³–Ó3%L@éóU¼s`œÅ52zÿÿŞwqÊğºøj _YÌ¯
Ã¥/7¼êø½)ô¦G3ö	&¦MS™ˆ¶Ã¥"‹ĞG×ïAô¤s°"NÊ¸°Ë0Øå
cOªË~tØzv¸üõ­¼pàlvH"¾‡¹;-·P¸mŸüˆa¨t»ĞïÆşÀT³Ùñç…Õ Ó‚ö‡
»U\ûPŠp§SK FÓ·–cõD¼´>ø‹ô­‚±™¹Y¡j\U¯¡¾“°ã&^püöĞä4Œ¹	»¡‰cˆ/G~	q6Pìß°?¦>ŞÚÍä²“ƒjğ«½V°51ó³½u>ÕË¬OÑÉšLl^'fn^ïì¨ ©m+\2³Ê6#Óc—u'XŒ}¿bèÆûº¤¼sYEkAuÁÜW©e‹”²´Cã¡»Ëæœ .ĞòmZd-NªzKWWek,UçR– Y¬9Ò[jE1¡ŸÑ‰L‚¨{o ¶ÇÜ:EoîA¬ü·’¡¥€\­´™©¨IÄ¶“I5w.\E×© Lp¢¼e´Õ aÓ|“ĞWé©“v%Ïq[ÕˆŸ;»Ì¸<F2ïO`¬|¢ÎüÿòY‚àè^¢ÄÑ“)ôÉCV†$‚‰;uUÇ¯h„sUst8µŞ×WIø	ów»×ïJ@
ıÚñÜµ-6KÒ‹.)şîÍHkÅw¦ªù%‹”!8›pñovü·Ş6%©ÛXjûõ´ï—NH@Ò—AÆÿØ˜1­ß[>¤ËòåbÓßÿØÜ*Á-8ûÀê›:’‚ğ;^îø«7¸.c·÷¯Ú7MÔÎø+J_“µÙu‰PQÀ¹qûÖÿ‚xñvW‚$Àã}Ãs;ÄÌÛQhì,)¤:xë;ãD= œ"°zYßƒû¶ûÁÖ#_×ÌÔ&E¯G™iìà6‚u‡E<iÖáA#_îuö^í)Y„ª¬©…‹uéfjïKÂÌZÕëo¹ñ­òC›&V¯X¼N!9	#¼*+oWWqêî‹\o6fË|xe³¤¡“92%•Bó£ÏË{-aÀlƒ@t*ú[µ|‹¶_bóCå9&è(Y¶ƒDÒM’Ğ±îÇGÜ‹[»™nÑ[“	9½Ò«‘±1tÈ*ş„ Ù®¬“Š§Ó™J¤~C°‰R	›mz;şg‘¿.å<£…¯Í½ÊGˆtb	ÖB}N7ÙgÉéçâ¾¡B‰A§(‘ÙTVÇ¢áÙâ¡YšëÁ‡"$ÏÌ+·dá T!·Ùæ]#d‚,“6.t(†Ä4´¥­G>ÀºÅD9Ôø>K”Ï·šw0âõÕS…—š¥lÆc?5>J‹ñ©G©"QßHÂ÷ùë
£Çè »?æ<uÃf¿Ä0@­õFbíÁS ^¨Ê`ç?èw §$Hª1e¾ıŸ¨RÏû}H±¢p^ÁIÑdË„ø˜øAó‰¯íÚóğñaòå|‰‰Søò¦õÇ^ÜØbbÒ4T/ÿ+×¸	yŞ— VÔõ
?á‹¸P,‹îÔ;°¤&È '¤{c"ìú_<9_¬ÏµÙhd|J9Ã–ŒÉ®ğìõö@X‚ğ#KÊ{yd$šÌ	|t”Ÿ·+w¼¹L#3ÉxŠsÙCy]xsqÎã7£é‡?éà‡å•;jö«j©âÇê×/
…oÅÔ„h"„D8QbGfC¶ûÈY×£ù÷oJ1ÏËqˆø‡N¡ó˜[µLf-Çæ^ÒÓ&?v¶ÉtcX2¤—]¡”€Ÿ«?¸p6W…M?Kòë›2AŒ¹ÑNwÙb™ "Ô ò® {ˆüëUªEØeäxprS#y‹DBrØ\¯!Fì~¢½€S1Ëîò6,éVõ‰ .U¤uYŒ'[±í,"­š‹j›Ÿöı '» ŞÑ³‹g¨¬W5	š¤†’:sß¬‡†xf»Q”÷®LvÅÄ°ì“F=	²)ëË‚b(—Ñ¥·|r Àÿyµ$N_ÏÏsyè;qtªQ¬ıï ûO…=©PxëÖt‘YbíT™&Zdë™^ŞVUõÆû²ˆxÆ¢	»ßÓ·€{ˆêÈK¶©q¢UuÌéêJu*Ì’úwÀ’Ë¹éV­pÑjúÀJœÔëLÛ±íÍÊj “°‡¨²¡§€‡òäû,g#ÊèKò"#Hª¿†ÔˆÛ·Âó®’±ºP¾W¤ÃÃ|³NRL‘m_.Úá¼ê›œÊ (6a*²ux*Tqwê|–n Ó’ŠñóRÉ›X‰0èÚëë=œ§ôbäë8ÎvºğvUw¥¹Û‘I¯y›µ}yş‡OÂm.(¡ã€üÇƒ-‚H²‰Œuú†íƒ±õ]÷sN¨­yòêÕİz3šÎ2¢Û>¥¯vuí&DÇæ@¬`|»½vú½ûµTÆF–Í˜lMıı–ïwÉ=.„1Ò#àøÄêšÛ|çm¨Êñ¹Õ »ñZ4À%Ó<—WôŸ‘OÕ57u>üªÌ;ÁP \²$m!	ã(kÈ8ô¨æÓşÊ)Îğ»,G*ášŠ×Ş^™©’DœÒ"¨ -îüMèJğà±«D¤L£"AœvŞ÷Ë€«™	fcx›I-f¤øà‹ù4İ¨Å„Ôõ:hÆo2;gôïä˜—ıŠšpl>m]òD:};'Õja²q8¨É1•Šïµµnœ÷¼¤fä¦Jÿzx&Øú-u£OM¦-Ô~?ì^	'¸v„®C­¼»ñÀÑ¼F±!ëiÔ"ğuÈ–È:Êl µ˜N@gğJ~ÁgÎGH{â'î0½³7:ë¹©@pï´LòiÃ8’-éËQµ{_1wŒh¢Šæ·»:`]Qi"uAE?€C%x¿ŠîÒ”KeÁ·îÃoÊ|_‚‘„u#ÆÓë/'ñîQtÄ²Ú–°^ |†tVÃ“Gq‹é)×°Eú[®8g8ò½œjñ^¨°küëø5^Í•›dÊ'<xCÊ•6)›®b*Â2€éşĞ4ÀoOÊçErƒ³xwD§äC«×K`ô±€Ç£ËÄU³
dúšAÛybU3‡>«µGs_hÙ;¶_TÄE[â/
c¦EÜÖ~ÆÈîç¿®$Âõ8€£²#{Ûš,²neÎF§µ‹b°gŠ™Û¶ú“	ºq~‚'0îYèÔLœ6n'ú¡´|ÛíŠö òY¢»ìrùèŠŒ*ÜÉL`è ö0Âÿ(ad‡÷÷"3°ÓF›ìD‹×Héh¹Ê+¿HÏîƒs×ÆŞêû¦`–Hlò…—ê¤y6[ïúÕí›}0»m¤Ï­’–¦3]Ë/§9»°WúuºBğm§hnYb¢3ó÷ÁÄ<LP“ı]e˜ÅÃ m©Î@£ú@ÆÙÇwuÇh¢¢ØÄ<a¹ÈŞÁ=.hÜç0N Ø$1Õ<zùîMv>¾&L×¥ûÆœ¼LE‘9œtÕ#Á4ú…YMüŞøäUİ?‡âúä'Â$Êdƒ1*NZ}ù?Zİ—–±É±ª/…@N¢—»'©ŞZ{”gñ”vÑ°'‹¤2bpXmø²
jûº¶¬p0O-ÕÃu¼óMmæefVä©VÅiÂ{UÖX¦K:‘	jhœœãgAØº)ê×1Óú¦µb’mïENC“U)ãÿgô?/ÅODÿ]ïÑx²c,kí‡´üoÅ¿…ù›á3¡Ñ3"9Éê^l€Ï]`"O´‡S4ñ°¬¥X¤³b—¼‡l…:šÎàüÉ9Ì‹tE@mU~^&#jDµÑ!wäµ@Fß¾‡*Ö&²öød†#1£rtÓŒM¬	LSEaÒöSNibp$ÆpFG“îop=²mwÁ]í¸&ç‹ÄğÔJª|;GI{ãmPg$ÄOõîš3fmW/+ˆ §åed£Ì‡u+rAÑ'!-i„i	–R?Fu¥&Bl3
ñìbşÇ#mØÈ…×dÿÊè¾²Ó«™ÊU=.ëÓá@ªš«¥”™0å-„ÿDJ{zèrå'ŠÑQ/SÀês³ş´…“ä»°ºÀ½ ü‰l6Ç‹Âª d„¹šÂÏ&QPdLAPFĞ-íÖK¿dë «×Iyı*v"$÷PYÈ˜‚Ñ&¸rt3ëŸ¿NdÛ%8ÈAÇ®¿ŒfØš—‘šÆòj˜TNt²²›şyÑ«ÕËFPÖ\©
Å0Ø}Õ”2êƒ</ËYC µ»@ª”Eã×J2V£Tú±ˆF{à\4œƒ¦ñ¸LÍÃû€û½Rc¢«uZÏæİókw"İ1B¸œ)L Ü^¯`˜Ìº3 -`hZL˜‰%VÓ›u@m´ûEÂ„zTÛ^Å¶>ZrÍ›Çà°æ™k¤÷BÈÎº°Ú\j#`s·„¸7Í!/XnÁwòµÓä]7« aYŸg]j;ãİ²Éo	Zú³?ô¿Ãî‘C
‘³¸öY2H +ÔTFñ–†€©€ƒÃešå¨”E=iĞdsÛcÄi=1´yŸo"üµü!Ä@NN¦“;Íµ(g $XGÁ®£HÀÈrÔQÉÔGÓjõ¦Ä^«F{UYŒJÄ®Œ7Ğ^³8òûoÁ#‘=½1ğo$Şı%…f~(ØÜ[uyDö
ZÛÊsÁºĞ¨C`G›Ú’;óeñæšªGQ´iŞ‰íÑçCoÊ;ğ‹WI'í/ÑTtc2~DN:Î,zõ[=ÒÌ'ôps–>±–#N}rŒ8Ã\»?Ò¾ÜHŒê9-KÉ±üOjuA¯.‹GAEøÑãV=@bÉÿ©ò›¶Üö-¾¹äã+İz€`Ì—ÒÜ´ŸÉ¬İğ/´»-€¡€5@á	ªŠ-;¼çIâöI g¢Ö5«Í×YˆOu@.[§¡6=ì`Ô¾DÏ1wnrwû<&G§ôUåÎ3U¯ê#gdB¬/jÜÆë ­^ÜÃÿDxÙ{áÀàÖ‹ä¼jL]Ûc¸¥3°|3‡ÉyÆÿ“æ-ÇÂé4ÊÍÌ6¥|UÜ£hˆüØu•êğrä, U]úM0Ğ•‚~>/jÛ‰ò›Õ—YÀ/xdÚ³if	9pu·¦á{4Ô¼.èoÍoúˆ¦ÌT"‹ÜÎë
İ]ôVE¶J´n¬”ç*ššR;8´Ó%æ)ÔiÅºì¾ßYd‰ÄzÙ‚ÍbØG:úÈ¨|ÍM¹ğÔ~;¸ûHA_»,¾ÚÌ€jìu,tJ«‰äyA­ª”çKØmì¶Bò8Eºò$Iî>k›r]©û,Çÿkp,¢Å½ïÒ ÁqõÜ©æƒnV•0À5 Oå”©öH» <úÛ®@„¨ßyP¥9	‡mŸÿ0ìeY©òÖ¹×[‘jêúã¸çŒò°{×¹ÉL7¾Ô‘•®¿lI ¿Ğ-æŠ/ißòP—´¶âUD¡‘‚+xz`ıÀèßĞ‘
ÆîFÜ|ê5t•õ»éøÂ¿Äª¯ŒŒ³ø‹”„!ò´ŒØºBõ?°£¶…‡8¶;5ƒúDÊÃçÒ [këP*wÙfšj×Á°5Ñ±ÈÕ B»×Vq]r›7M|P¤¼á¿j­ÑÄ¬¯´¤á®^îQ‹/SÇSU¬ÅÑ]½â·fŒ-Qb+u ¿sŠÚ‹ˆo;”ug°¨£®]›Ğ`XŒÒo-Ü)Î&pİJ2¢ÌtMC+Ü2zêùÔpxdÑ;ª kîÈ‡>HâŸÛºÉAÇwÄ”¡D8Ë	+6K˜Õ‡ç§T;³–	6v¯w»ŸòP¤ÆIöjßY±¹ıÒ×·¨!Ü$RÎšNÆö*‹¿Àğr,f¦
k¨»ÊnC¬ÅŸ-J8f•éQÓ9xVŞ`œ; _Ç6X_	İc¸'šké.zô.²ÖìÔDlmƒ¶½3ç.=o(÷tuë;Œû7±+ßô6ş²§æÊzÁÜfÄ¢ÅÀ8Ôû©å"Pàw&@GLäpûmÙ0Qã¼‚P°võHğ\f	Ø¼ K`Ó½SJÕA]H©’ò .Îß¦	²4ô>Í` Â à³,6ùéšP
(¯ÊKıá—aNApÌgBÆ‘âmE
GĞÆÇ­96ùtç¯"şï‰£ZõİyóÂJÁ!·•7ŞÖ%Ñ·İmªR?R¡Æ~n¤J¼¨"ìÇ%o]ò©W¤Áˆ=ÊãØÄ"…"Kê"÷²7GÚºŸŞüi;Ã‡ÂoÉáCæ˜àœ!ëşÛÒ„ˆb£©á”Ä!ùØ»Ò6×ÂdşE;¿º™¯8h¾Çõ^íjÖïsM+îa°àê×=ôÖÚ9”ŠÍƒõèè|İõzŸ¡˜ï3-ßÌêüÂ ŠXLøY@Y68íKß/
e[X\ºïyÄ÷ßœ‚6¬ƒYàÆâ’À]¸f›è[/%íæ"‰LO ®+÷%UÃàòk]ƒDÔÒbí#{×|óvL2çáRŞƒÚ.¹–˜tš§\à
Œ§úø†<¯×]†Ş,+×çØÿ¨>½à½ãjû¾!Ø®°ó)`İb±"«æt¾— lƒL×¯À©G7Hn0¢#ríb¼!yE ï|•®mh‚Z§	“èb¹UìWuµ5ôÅäÏæ.Åæ#c‚¨¥Æ,{€õ×§×¹æeûà[^ ‰]yí¨*’¦ßˆ¹ÙçĞÉôK˜&µj†ì3àXfËß×C­çÕsõÇ[EÆ`Th„âmJãrây0•­« µØA&VÅ’LÿH`Õ»œ6—ï°<5ß]
S®æ1ƒjœÈù3t'O[
•#¹›&:Å¥I¯ÍøŒëJ	Z!û)Ep¢y£Dû®“]ÃÕ”4Ğ'ö4iµ/¥™;½d˜9%»‡åÉ&˜a¦z8BƒE/D/u‚!?Çº??Ğgª¥?óUÌõá—Ğ0ÊÀìˆîcéŸ8‡qòì¹Ú o~;³õì0Çe˜<‹–ôqç„.™sç±šP=ZB¼“@aqÍ¼í{ÊÖÕïÍr‚Ÿ”ıxœİ¡'Ÿw¹ÅAUÊı#ŠÿMwÀ#ËèÃ«…tXõ»*l7•¥<„áŠ[/5üåû.4õ¯#²œßã,Ğ…Iœ‡ıˆ¨QQT°›	Ïn'ÂO“\“	5ù@F›_¯/&Sˆ)h4 "zûªQíšEx¶¥0ü@3ÍŞhY©¦ºº<EzACÚWùéV:ÄjzŒ ?Ï
¡ö‹GíßÁòoªª	»wb#Ş)Ûªµàäş{lİˆU'²’1¦r$G®'Ğ–‡ë·X>NG$Ö'bµƒµ¼OeşbfóÒæ/DËwªö	£«”Ø3±h«ÈA]l Ë…×*ßÍY‚À×`ÁZj-”¶<Çº²…öó™½«¿*¡2œş„lÆ¸>vdÁG[LOPf+
|PBåI G†	8ÂUuÜóa©fMIXp¶‘uä‘ëæô’Ã?èòe¨mŞ6Ö)ö½£Ö"ÿjEÂé­8^l¼ü:È@­Âñ#vGo¿÷ŸshòZßìéåzÈóRp£9ÊåmÎêGÑTúÉ¸šVñn€úıi¯•³§fä·œ‚)©÷3ÄƒBLòŞìİe9ïbxÔÒ”k`D?`yæ†Ó€ ŠÆú•­r3iŸ.0€ò;Ó¥A;ºûvÉ‡cb‘­ îˆ‘iÑ½›šD?b‡rQË„JÿàP›m{—Ëy&õVu6ÉN™E2+Ï ×ª~õbk¸2q‚os!Í·Í]Â/´áZfÊ²+£D“ÂûwzfÊQe²“Ğ@ËW•™~!LzÍö"«æœÍø®‡Ìe‡6°£bš`ö¯²¨}ˆR&D¡L¡’ê`ÒÀ
Ö0º“MrG'ªJt4ÔÈo ÈÏLçFme$
\Â•°°å? 3@hD…ë>ÁQ3¾øšM dSî@ñ¸™uÜ¨‰~%†åV6i+êhöÈ4è†¹€ç2l÷D3w?EË¥:ùdâ,a¶´ZDE°Ç¶@Èr€Ä‚}Ä–….ÕkD:ˆ'_ˆ“¿ N€—é¼Ïb‹Kg¶$6Yˆøe½D6¥Y
dˆËÕ¼hr'1W*ı™kh6	ÊY7Mi$Í;Í{ $+ªÍBÍº°Ğ8¼ÉåbxÛ2÷È…TĞôÆğúè¿¦ 	>³Î¤ü0Ë{¬ÑIgï?R¿ƒ_Jõ©Êá«‘Ô{Â…J‚â,§Ó	")H`ı9ôÎqVÙÀ 9@9­o ®ZQxYU½˜FÁa><ˆÈ^…€¾‹£÷{ŒöÊø²Ô°ÏƒhÕ)~½;˜JÖƒŞgA¼/L¯ljP«M†_s€ÌãJÃèG‡1ïÈV*gÕuJÁ£ä…¡ú€¶ÈãxøAõh¸N¿‡yØ9{>Ø6l­@suç)$qıJP„O(õi¥İKµjÔÁwíW4j:Ç4QWğ –
¸€²"İ_â–ë·3h*Jœ7Ijà‡ãe!’-pKo–ù&/hœ†®MÃµ³[cò¬©u	ÆOã±ç‹¶"8O­õRÙØ¬¶ÕS×İøqrÎC¥ìdZvp#RgCO˜ÍX	9º)o2èÂfC™&µœºË‘ (š¿S	¸e€‹‚q¤Ú@`¿)5m
TÄ—¹ÀRõ„æìÉM(¿¾á}xÈm.ÙU~{bÊHº/€ÑÃ'ŒˆØŠñ³éHş4_‚çšÛNéáFr†•É‘Áu"Sé«R7ãMĞ+Àt›Rüüÿ›¨@s•¯†FxÔ³¸U:4Õİ.ñá„ÑNxÊÖµ{pA0NLÔ…qİ6§ ˜ÁKß¾6…|³Ô2aµn®ºmAPãcwF9ƒ!rÆ ñæîœĞ¾¨õa¹ÇØ'ÆnøŸsQÓ( 
8“MşÔ£Lˆ17ÜCr²;¥ÚÍ:Ô]èN?ĞâgØ ?Äğz	vdš*>!,Æµó”+xñX‘ìqdâ rº™Y·‹õ2ÈLõÎ ÷+ùÌ²âİ;]Û°hœ>èBÃ:k^Ïê2¢sc{¼jX%d»IG¹ËŠJ¹«‡s#{§ÈeYÿÈ5ù¯º§ä¢&•²€*ÈãVÂùiˆı“nç xE´`üs]ïÎ„âÁt-Éºãs‚x‡UW˜<¬y4ş,	æ¼°>ÚÓÄ¯ÇÃ iızãóÛ#Ñ ĞWv ìŒWİK``½õPNùÏ½N„ğŞáœ‘9ñVø¹Y„UùÕqØ)n…³’ò™¨Àö“k«Å ş=?~MºòY?}®ïNÚhxçöyî!Ü6!1¶ÿ’åUĞÑÊL|íq«ô¶:÷îäZÂqMÀ/ÉËáªõ³­„éP?a¯ ÚöB-
d!3=_"î`êVKÜ®º›œ½)EeˆÅÎlC×¡‚Ä¾—µ%4ü¯ç=t~¢7€å 4NÇÕ·pû±ÓÂïW¨êaÀ)îå_gÑğŸ¼œ êO-xÍbŒå;1Çd-`[ÁÅû^û5hÍ?0‹­y,¼gí‹‘4•õ™À;–—×Ÿ‡Ql& ±6Ì÷€B•À÷ÇÚ$eDg•m™ûULERCè] —,Ì“u‘ƒI@Œû6I< #Ù×ôêdë=ÛprØ¨z_ÀL $ÚD‹3dR¤ˆP¦“¯¥Ú=4‰ëdÍÿ…×sñ/56ê‹¸Ø(ÂäĞ…³µIı¼}¾¢Ê+ÊúÌ½qà§öŸ4°Û“åÁÜ5s6(zÿ^xÈ%~çØÈ‘È¢Ê%êi7¾aPÏÒ 4İ$1´Û¨B£Ø¸†|éÀsÌ—–QC¦>ov?Á-Û¨—ã‘w*Ì˜û;F9zG^y¿2Ï*ùVı‘zòe©¯ğÿ¸(bî¹]¹šİ\/ä©SĞìa”oÛ3ÊÄ¤Á]ü°Ì÷àFxfí¬jŸİƒßz®®W†jj áƒy8#|j®“RXÄä1„vŒÅˆl†8u¥îî:„yya‹­UØVéÁÏÉ‰±gP[ğ®Ã®l¢¢şHç"•uÙCäÏÛ´Šx
\Ô¥œ£EŒgxé%æTGÈÚñ©vG*‘ÒÕ°ìN’^ÒÄŒ² CûÃ¯ 94à‰Æğ\İStø‚5˜şØ÷u‚x;°R+Ë]=@J¢}“ËÍc%»f=ÚÎƒ!XLèalô¨M	€‘ó*·åÑl4Á-íëìŒ³ì ³–$$n€Ÿuø·şÇ®¡ÃË4õÎş–äbmpQÈHä"y¶¢ÙKkÎšÄ‰J«á‘ó¢R„a?œ4!ãí7Òä¿Lòß¶oó³ ¨Ç:hC–9‹§%f{o×ï[ósæˆb†ÛŞ‰ÖŒë!¹ÒıòêŸbûeH©Võ©«–áÚõ%ÎKF›'óPˆœúIÈÎÇå|>ÀŒŒ&Ä- )ÔùØÅM…"zV4‚”—ö¤«”Ú‹7×d§+ÄW¨0…ÑN‰”ÈèÁ˜Êº‘]Ù´šÑGÖÆ‹Y‚Ó±
ñß§ÑàPjï›‹Í¨×sºëõk~O{+rEfHÊE×—6;3*tı „h—Ö>$^@ıµS¶.§uÂÖªÂİ¼—¿¶rñ:ÉGÁ‘¡z†bGõğ‚(æiç˜K$«ã
£ÃUSš7ğ·!ø·\ôä$O[†bÓÀ¬85Â¬ˆvlpì*bëº[êNWàe#†'Dó4à@’_¡üëâX†i'ü¯KÕ>¶Mmıp¥<R<Gº™½èÚ²g‚§é{ø/İkˆvd>•æ:lCVğîÛS?öc÷Î
ö¤Ökeeú{)<$ãÜ!ó°¸}L;<dO‡)¦‚ûØ_M,K ¹ÿ·ÌC!(åí¥‡üv'€ûA)ùrB¸‹S'zv-¥®U­'ÛLQ„„ğ¯vkì'£Î²|ñïìdªÉÉ*lr‚³>$å¨Ô=¯´œî¹”êĞú<Kğ-ã6s+YÄ;Y·ñk6"Ñœ^²<…Ä5(wÍı<©«õÔ„ÉĞÀKNâP¢¶*4=3F\Óô?ˆ)…0f\ìM Xö¥W“*‚i§è½™Ãµá§»—m6@ 8©ïÍvÿ¸ö^¦ÁîÊ=Toßmş©Èõ¤¨ÜÌêo[ 9”Ä£ğ]RG>>¡v™‡ÍÉ§X¹¾(«áÔ¥Ç'Js™ÈÖSW¢SHNÏÙE5”æ¶Òus3QkÓ=Rœ™³`Úè*ñ“ùÛu ñ«4ÿ§¼=Öl—BĞ4ÂS¹m4O0rÏĞ·†”_L6Xè°vš¾{Ó=_(Ë	¬2*ô
,lÁ&ÃaL’·® ˆÇ>¡s¨,=(í{…ñ×X:°SœÓf1]I«Ÿ6xè+ãûhŸ{eo‰N"á·8ÍìDg´7[tâË¢FMÑc­/‹èÑª“é¨k+\äåÕy_ß ·W„\ÀZP–wÿ?•Ué& .î½˜ov»èù›\¦qN?V	B‘JpBÙî±Õ¦Í;~¸½¦ÁÕü&‰ÕTgOR°,X·¯Ïß6Àt65ºÄAhZFòù•$ßÛ+iØ^l’Ç˜+é™)¼á“[J°Æª×i¦¬{=ähĞo\:ÍğàÎ\ƒå[„‰
1yíûh½µĞ»9°8Gím'^?Šäs{…
 _Õ	W8§¿‰÷’&üqËQ]@ÑÎ·©‡™Ü	ûQ Â„õIáq–U0ß\+Û¥…Ø«—¬øaè*›º'(Åú+·¾È¶Ú>3ç¿ù_CŸŸÎ2ã”¦yi¶©È‚bª¥
¤Qv¤+èÁ‰şÑ3/´É†ê(§mÁ½nÌ€õãÌ=ÜÍlı@^qÃò‚ÕLx°uƒ NâêÇaÓYšK±øõÂ† Ó”BÁ0¹,i¾YÓ’cÊq.½³_ˆí'd[‹V¤Cïº–‚Ú‹°ÎJõ=$¦1ës? ½@ôÑ1Œ?!5ÑtÉÊº}¨ş‰ŠªœìÄvcJf+d|K,DÆrÓH§øË5L4¨v¼ÇgÈ_*±†OÓiµ?‡Ü,+cA>ší¦fÕ‰P1ÌôP¯]ß À´*¢ğ¸êôcÖ!ÖcZ€¥Æ„ÖÏõüß¥|„…‘n˜ì?«ÎiŒóÕíÈL"´’/ò¾/ò4&ØR»A2;*Aã¦ß Ú¶¼aš6ëNhKH.ÈŞä¨´‰ŠâGŒîˆ·wØ)¥‰ûfMN	Æâ6õfªòÌP¦!Û•ÙDíñ¶¾oçlÇ'Íİá'Ã¡§1r+^D+cì‰éÂ3K.ÙÀ70~XÚÊH_Ş*g†o3ÉŸ,ÔĞ8}Õø™Mê¤Õûâ&«Ø¥`ÜÕ×[Ìg?%®ú.·én„*”M	İÙH|"¿;Àƒã•dİ3¨r:DUj$>¤XiÀl¾{Ä2„sŠ–Tşüÿ¦2ß+6âq³ÆS=ÔØ¹Àµÿ¶¦“·IY?N?%)…ÿn•®bêú®
®-É6ƒ—m…cJ3a~%¯®F|Ö÷Ğñ©¥Å¶;ì	\5î¶Æ,"$”¬·Ó_zX »0£qÎv†UÄ5B;ÑĞjM…>¥R¹îÇ; ÈCŒg5¯xûİ|AûœÂ,“·™é¾C†Çf$qÚì!0©IW,wÖs¥µ^ØPƒ‡è›ıyÒ™·Í¤:›´FBœ›)6•‘iÎ1vôU±ÃVãó¢Ÿ×2˜gköïIãEZ®¦«ó“­ ‘Â¾óüMà—'¸œá³ şİÛ‚3ØbÍ†öşsÊo2ã-<ÍBmGÇ(‹ÅY›„™ç§‚N9· zñOŒ#Øc·˜@]UbP£ù¯ŒI¹(èÖ¨±†ñVë©•	+‚–À‰‚[È&£½=‹Î-2wåUaßò.z(x™‚¤,å&3aXûˆ—ÔÁA;2w}$dœÿ‘ªî‰Û)Y
xBşùø‚Hù0åÄÄxàòIı6˜MÍRÇÊJ’R‹Ÿ8Šºà¯mş:‘©ûê,è)£<.zİqJ¸Óó„F]Ã~i„;ıkN>Ê©íÈŞl­ôùØaınÁôkæ|(dqÑ£İãÕ’pÖ(²*Çm2!7D»€‡.7J¿ÆüÖ„UÆøÖgEí†Ğ
lø“NC¶î/øy©'"xpÒŒÁ	jW‹clkhñëMvAİƒÄkt·£(3€[Ä;ôßæŒ‹óµÂcIÈŒçƒ°ÿuà@Z²•^RTµ@€ ç[v/òÌ0D#{ˆCõÅ1<¶Í:WVT¬şKD5³ÛLSßÓ³ †„¬Nj«ö„ŠÏâl¹ØHº’×ú£Ab<Oö×Å>‹p¤mzÔŸ£ş²Â>˜dÑ„ŞY*B3æzê€d™5\‚«)ĞÏï›ƒÙ–H•:ÖÕÚğ©¨ì]4]î.úüaëñ™:ê¢¸”ÅJ–›âEjBh²H¶$çFFPXí]F=½ñí®kÇAznè==(AÍà*òô¾(~4¼{Ü8/ß.ˆG<·~tsÙi³feÕ6Bª£–#R@²‡.Wœné­êS
»c_Z¥'(õIè¼€ETîƒr–<1Ğ)jnàì¼kbÕNYÃ3Ë=¯‚ï˜Ç^^·e«hE§&‚s+aÀØ,ó
ÔWÓppù/Á•Tğüf,>7œ
ˆ¨>…e®Y³Æ"fÕ
—R’;C¢È	iÂ$?‡ÎÅ‘ÿÃ‹Újîn;ZşÚµ¼•’)+­_îÍµ¾àÊ<%÷ÕÏ²è„\”_„§ø²¹)ô·tÈ/áãVÑØueÒïaÈ
Úôƒû s_‘ c8À½úÙƒv³è
¡íw	Ê3ÇH[ğ”šn&”4IÚrqœP+…‚µqY†—%í9,ØŠÔ¦ššö‹Ùàş´Ø)8%Ô¼›z`_¡k4Àñk‰Ï»­PoÿŒõ@ÄqÛÕL+½û³Ü½”úR
ŞXIÀ¤(_¼G†ŸXJ:ÒdéªCåÌ°ò	iqaÒnw>ZÓpŒUĞdù”bhÓıî¿W
iç¨˜èè{Lxx§º¶´wÌ6¢åşN¨4j¦W’İï:96¾Rf¬ãDâWmªOe!ì(œ–J &ë¬ü1­ñ¦FŸ«od¡F¹æ(3¨ºG×øŸF>$=:Aü[Ö@7/tJ™n.ı<EıFÆ™†@a¿øW›İF}†(Eµ—RZÇt›ˆ‚£/:EÀıfÇ1ñ}Ó£8’%2Ù©Õr½ÿ±ĞE›ğ'Ğ¡i$¼ºL3Ÿ*éª…–	ù$gšŸ¨9u¨–õU­U'ÕÚN·x•àqØ`‰åUÀtz¯’ûS?¸š Â3JïèFß‚fõOâ©c:î~Ñ„§>0¥ÍúÎgPTæß¦BÑCó÷ş¢d³$(
İˆJ}0xäfÉkuË&Fã Ö¸À3~aÄ^¡…É­˜íÚûÖ §¨ş—e r^g®/F€øÊˆöa¶^™b´Z¯öÃqKÑÕ}FÜ\	œÅ?”$_G¿Å-WòÀà|O¬MRËÎ°cANßm>­ŒîZÌÉõàc¶tz!!G«ELõñxÁ=’`bÇ²¼5,Œ­º¶öé/‰£Ôß1æJí‘@R›{£’V#dòËkZƒj¸ÿE% òÚ· ‹¢~=Ù*{GMk?¹`h0œg±^ò˜ò€Aê„±‡KU~2òşGCè½²fÃ®÷
?]ôCı1ë=µ÷d1äGÀ,%Å{€ŒÔ¶À);Q¤ToÑy&}HŒÂ¯°|i‘OĞ*˜m‰tsñç:9Ğ¦Ò6³ çP.ÉĞˆòÍ=O§áXMmlws—´¯ôC}!úAÜÚåWV?}9¤´\áÛ_CLšüHĞ‘ÃKİD*µ\WHãßv«é&3Çkkğr±·Ïƒg2„’ßa‡á®¾C€-Õ·vÎİ–×p«Xë$ËÈäˆÀãkW4‹´o|¥7Vqê!=œ9T`"®X	ªõŒdƒ¡œ´l<‰n¶š¦½º3âÇmi96=„#eá;sä#ÕVŞ|š“œO×¤dAT¬çûÛ“¦-s4qV´µm<¸á¥aÆVöÜ
ÆP»ğ# s”;F\-ÃR»øßsK¸Š6ÉA¼¾úøÅÕY¼Kf$SDj‚›öZlÂÔYµ`5x Wo
²§Oç]MŞG\ş³ÙóÒ=Ü‰]„şwªß<b¿N+Ù•	Û@î¹e–£#=ÅÜğ(.¾Áş"z N"Öm$y—ô´©^oZµªÆ{>td³}â\Øù7¡¡¦şÊ»ƒ4vaëàq³Á¾tí@h‡uÏis× Â>Ùhüc|L-Ædõ
Ÿ8$O{ çÎË¯ğé^$¿:l˜Tš/_OMrŞÁ8ËÒœW§§A†S¦–G#©áäï2¹–Ÿ­ûr°q‰¾£\·7Ğ*$tàåêD½]ÈWdí°r‹YµŒP´ qçFÙ@õä¤¼Á~r™¹s±¢<\=©¯àZÅ0¬^§´¶„ãjÊFóƒÚŒ8—Æ:XöesÌ*âÛ.J?üaÔ±eÙå°IƒV˜-DaÈC>‹gáLwí|Ì¸§¥a#±¦*œñåK•¼ùs)w¿tƒH›/€zÜˆyûÊÒœ¨z¦úĞ&a\»ÇL~r?šÀdtµcLá3›ëşğÀDcTx;oä…vªøÓF!Ê eRv÷‚Y–‰i,”é9õ@™X 2eÙ¹¤¤á®4ˆ¸\CŞs7N·ˆg§‰©G Õ›1a]€œLöJb'Ø^²¯°ÏÍÆ\w3 põæ`±‹Šá4ãÑKİ°Ót':`0˜#kûmª}ğ=Xh÷½CgZùÍÓw‹ô,q±1½	Æ8bûX"ÕTY¡~Éí£0í"Áğ2–¦€s£Su€4ÄêÏ6Hû5 Ã©æDïÕÁ¼àÔdçãmÎÛe¦¤ÍuØ\âÍÑú˜k÷	”&N€OZö)Éc¬»{n†zÀÒæÒ¯öGßÚëûÓ_-:`#7GÊw
¶ãĞÏDÿ:ó‚ÂÂUyôâµDÆà)ÜÿvôG.Bµ¢æI,UË-PÍ¬çÎ”ÖUÃÇ¼N…‰—ÂåLæÑw¦´®Ewwì¨ÒŠóğ¯á†K_ñ³™=¼­"Éïo$ô7lUÏkÃ)õ3ß´İßd¾ş±ÑˆÕ”ù‚Šï±@2ÖÚäÀ@{óÆ®Æƒq›úrÈª¥™˜‡‹®cíò“PÂº´š&È¿¥³dbıAœÁØŒ×Oéd,kfâøğPÄË²PPõ' í´_¬Xí7	ÈV‹væºÍXÛˆò¾xıtóœô«#¥´yÔTJåoDƒeé}ÜÜÇ-¤‡ìöQ:®²Ç§ZóA–—‘şKç±Áóƒî…"&	â]·5s±È
Í¬EmrÅTÑ,†Ú ,Q¹'ŞÍ2ì;jH°±À(Nö>³?b+‘2Ømµôn>™d3şR±¡V·Šsë¥’W§şSıLFä‹ÅÇZ ¾ÍÈ
¡*{âóí‰»°¯¤]Ì TZ%İŸ‹"èdS¸Áİƒ^¿fÈ>&šxË°ËÌÕN#UÜKzh_2VÁŞÃƒÕ½™64È)ÕNpSÑx¾Ÿ‹BñçpÛ
>k¸óë;-â0d¤üB¨#<®£kÅ©iîò²]ÿ$\>Â§¾rÊqğ„cZ¢Œ6Ù[ÙÄÂŞ.÷{3Ë¨´ª)\&HóJê
n
í÷Óæ+Å€FYŞÚ¡s/r?ÏlTCÉËgÊıc8"…3DfjMa¨œyîÔêÙ¦2§¤¡¥tBìYdEëâLŞñoê‚İ»ú5.YôN}5;dZÜ\™…ĞJÏ§EÛçE+RZ«¼À¬ÓÓåo’P±QòE@d’nG[uX¤ú£-NT/Hÿ'k±Ï­ŞŸÈGÃ)n%ö Ízò¶ş(‚ËBÜ„eäô!†Ê™VbLoºö6
¿:Ïá»FõwïxÌKe,›qşáÖ ‹ÂCèâ%i3	õ-@lákÁ°ÙXÑ¢./Ä<2}>V°‚NŸm‘•?dËöŸŸmTZ
OÁßø;™§¸i:¶1Om;WÒÔWÏ‘aKDáÇ¸*ùõÒî	mí´¢s™ÉĞµ[ûüDøÿş3#ë?·€æyàã&—”3M;m{™¹q"}Ø—‹\LKàÊ#<`Ê°NŠS›÷˜ùWØKBhñt ³U/±xš€9£ó z­ÍqÍòæù¹Ë±\©]\Èú9úM,*“¦ŸõılÓM cx ¨tÈ-“MÔDÿ,)–wüËÕ|6¸<¾Ÿ”x˜’h?CQÅß
-•™q’ØŒÕÊ•ı¡F±ÇÚÛ_qr4ÄÌMä,±¬'ñûc«?ó34&vL.¶¡ÜµDÕ[9ï—hèZÿá,¯+_]“×ºò¹‡fƒì2WŸ[áË5’Íà“õNQ¬š Ö+S˜	jñ¸.ßÆ‰öI8É‚KšA!e<#¨\˜)3ÓÂ®6—®”r¼&Ó¡/mç|Ÿ²ÁTo4«ñ”€wXº…déˆŒ5ÏÔ‡dÀJË:FŠşJ‚½z9ş¾ê¼JÚT[¹ovÇµÑ) $Û<áÔêVx`0uX n¡2s˜iéBTÙåÍ	Ê'0ì\c~õğ¼şbCHºÎH@A	$gr±«€$»†Â®àYÄ¡¾ È`Ï¦-09=gÕ¶t…jeÅ:FÛSÜ´‚ÇĞõ‰dí2bÅ…Öä™yòÛ™€[ô.¾7¤YQáªÙ&ÄÃDÆŞ¦öà¼lÒZÖ	{Š ñNEQO4xøÇO™FÅx)Ö¯–lnûÎ):bD¸QJãÜ{HÅI•ÖÕàhè·ê7 ÖXzÒMĞ|ûo¾Åzãã‘å®¡{È
í#ÃRŞ^²BZÍ&fUğN
Y,‚2ÃşİTı¨šÚ¢d3=„zçûU€ÛõàiNoÔİcòêäÁíâ§Ûİæö]Œ®a>€¢ƒÙí#û‡1ñ‹©inÛ?J¡ <´&AğK˜÷0Q÷kÄ	4ÊáİíÄ°ëäBºs$QöÜŠ°ê5@9²,ÆøëŠ¤].¯	c¡ëÚøõÖs‰•æáåQkÔ='jö3ó™+™ÛïÑYÚŞ3&¨Æó*òúŠ’oèÏìoïü©BH<6´`ëÛ’™½‰cÅz‰í¶Px²0‡¾UŒQ–sóMòè{£‰ûÖgC¬0D‹ç50l¤Êö„Ì‹²•MB´:Xà½qêÇÀ Y‡(¬ª¨<ŞÒP?œIÌ4õtkulÓ‚^0äş­$_À«ìl'zaÍíËTˆ\t¡o]ì„\hByIßÊ—•…Êc^âè=€Zû{èD›z<¶ƒÕ¥pş
’+ÓÃº—z´¢w5,hìuĞ§·«~¦	nqÛ™¿ôøOíÅêİÂæ§,}kcò‘€6«!Éÿ“eÏH1ß}'¥ñ<èPX‚š†ÎÀ Ùä„„ ¤½¬¸ø'ş?´"[äĞŞ[ê$ÍHJº8´Õ‘ºRuu@Şº‡<[y
š$_Õ!ºMgœÅ«µÔ[«€J>½Îâbˆmƒ´`éêox|h«0É_QşHR:ÊÛ÷‹àhl+–ãØ¤›üT¥-^Õb7ü4«ğëâ®n—ÓÕ”Yü‘M¾åØë}3;ó18×atÔcÅ{;FÍî/-èÖÚj ²“NÌôZQ*¬»IèHØ5Ñàš'kf·›Û®+yqw×öH4]#	^ uyô¢ç0S˜-k?ušÅ	nLóê[\í3ö£)âø†è­çÂÈ–Ë(@<	2C ÜëéÚå¹b–WÜ8|mÁ	…3a·Î>Ûğ¥³Ú¥Zÿ=Xø.~
Å‡#2ñ¿&;f¤VdÙEü¾÷Zx"¸»zd;“b¢y,ÁRÀ8bvoªâ&@6NlsÌ&Å ­T,ÕnÃåÛn2ï¥Å5(dO
}…IVî 9£g¼ÙÊ3¢ôk¸œÔ¾*ÖM{Úß…Â¥Â²-³õAiN¾åÉMÄn£óÅM]ëÓ|pÄÒ²Eˆ&pÎ§$–AIusÿ¹÷[ºG½¾§yGC*+ÖË@VNa„J$z ô3ƒ1ó5¶¢­47ÉšCpMÄ¥=‹)lWÀãìììûãmÎ’ÒQ3høzt\	¹7öãy»P¼73eo	aòİ"ß#§rKve©Èšmˆú²™ª‚³piQ(Ã‰âˆ2Ç“'h‚â¡/Kƒ:â”ä4lÔÙÅ`Áµ|4_ÄsÃ–L£?\v•nHÇÃ•Ò<?Iv¯äÖù.ç:ğ^TÌj¯|£OØ4».F3sŞĞen½ØD9óÚYt|ÖÇSşBŸöôé'¤’²[NšK×°ÿ=]ÔG	µRc„Ù<b\Òçàª»şT|ˆÏ$“µ¤&3¿ÑĞ.=¡Lá@
ÀåÄĞ!5…–cùw““JâÁm l&±õ,©
ŠŠ"©ñ¬•](¢ì|ºéº_Qâv¨ò¼îE”çôMj¬i€§Z‚Æ‰ŠZ%a±vfFÓÂ+«­'Ö`â0qn/Å~ìÚQ8ù¢K‚—ÇîÅNÀÆdÀ«Xn'¨…å³”}Î ?0eÔÖi+›+ïïb†€Ä¬zÇĞ:q59/?$,6-Qbğ_‹ n›ü“Yí1²­JF=‹{Ñ4^iİÍĞB‰¯ñ¾®#&îåyY)oŞÛG|/Ã½±úq´§ø7¯ÙÌ…ÑC«„AG*I/ÔÕ¾—›Q2€-ÁÖ+IÍô ºÙÍÊŒqSÀiïÛ„¸ÏYàÅXNªæW¦w•oéhœ%¬kg¬VO÷É‰ÔémWİ€‰çìÊ7#HpÒAqfã,šÂ|-³‰İ¥k©<(ñë{ş©$&]ÁŞª}sécÓt=IˆEA
µ?Ï¼'ÕUr°÷¥§Æ™P×¿~»?|›Ùu|šcµíK¶ë|.¡Âyõ/÷A?‹ÑÚq¿í3>Hİù=bW]¡g[Úñ¥¬„öXìÿÅ‰àô]¹ZÔéQ3Øê4£ä©l¯2GrH³ÿ[{±œ ¸#³à,iå/°Š!³³­Q­ªÙÌ”à 7LUo_ä}›Ëšğhï`ÑòÛöÖÖØñ-w€óùZhçÂFÌâ¶=N¬ƒgV#í1,§lèMhŸ¶S—gúJÔî¨ŞD	…³ œİYRO¾ QVó¾ZmÔÈ\²8è0–’ÿæ\J¿›†ä(?€WQ„ªĞè^6¹ZY-©€ÂM¦Ò6¿Å¼Q÷ö~’³+¦è#‡Ğè#|‰íãêßiæøjÅXÈöCıïóRzdòÆº¹Š#"òts8
J’N¹8–ÿ\šŸÑæÂMkÖ’eÌJgU7¿+£ŞœPL{37O¦û! AÌ[âÀÇ8’ÆqÈgË#‚ş$n;Ó)r­—æ‚G}‰çM8™j)ƒm¼VŸÆ/‰¦×~¬Ygücšï'äd6{i®@Î ´ÖÇ¨_b9@C…+¢$Šb Şë¼šÿˆ˜×PiÍ„p~Àx|üaGwÊ)6
ù"¯Ö;á;&øÃI˜j{ß›z¸v%©?TX.Ó…Ò˜ ëŸõ÷U=õ%<ˆş=éigDé{¡™
tHšD·ô¥·±26ˆ¬:Å±c@;»°zıÚ÷J%·†|˜»¹£|äÒ±BhÎCı
íÀµšìZÙÀ¬ä@Dà†8QY	Á›Bí¾YÔ›ûæwI¯›èh¯›3!ÖkÓk¦åš]Â3²€¼uæ[R	2{°ĞÀJIé°¼Ù5ÀØƒğªàÃÈÇC£ÆXx‚eÃŸßQoâ°nun7–îC»%l0«òLß	Ó"@\º­QÄë
Ô0aîcÂÍ„q6;ÇC1'æª™¿k2[Îo¹"ûf=Œ#Kà¹ìpŒL£†HWbõáÙ¤-
âƒC®˜ë! 
ßc©Şã¶Àèèÿ©y.Áå€e©X5¾øåSìŞÍ}ŞèƒÍn&Îİ€øñò£—³´x¿ œA€¦uc·aÒºCb]¼É½kµ°D±Î^0yKkeñØûÈ‡9’ı¨¹
?||œœÍläÉDèsƒƒ%²ŸÑr¶ÿ­7²ÇI>AëĞWÕÇÒ¿ßE\éæ~SàAR:Éro‰€LúÚûãˆöß¹>é,t4õ¸Àr™æ¨x-‰ÙÓ7Õ±ÃÆº*[C)¡ox&ë`1À¼²ê®ü)Û‹“ãØŠe™$Ò_ÛŠL†—>Ø"õ„ÔÒ¤ıµ ‹=z;Ÿ­õ¾ö+³Éìâ;Ï)ò0óSÏ³á¶vSL–EôCIÖÖ½öb;
H¡‰#\0®Û_Y&ÔB„‹Çu€¦º ©é×wiéo§vc¼o«ÂH;&µ
:¯ƒøº–§(tôæŒ—ÑE6CZâ>bÄ8J§Í]=7üÈ§û¥GÏ8Rô³¯}3¥r4«“ÍªJÎÃC -I3OÊL•€/Â2šólÇaê“İöø,ü`"kŒMz“x©–$ñ0›©Øsm&sÜ9,&ëœ‘’J™¤f9¥«äµ¨"7$"YWtÌÍôc"Ç4TpëÛÊîQW{	ıŠµµİE!‹X_ÜRóQohøÀ8GI÷.u%†¼·|ò¾‘LÎÈ,ºF7Ò¯WUÇ.õ—ĞqRiË©ÖKg¾·•VZF|	ã}in©ˆõÖt0Ù+,|ü¯³Y¤ “0'ˆÕ_IãPVÙwØ'zèıŞa#XcÙ•“˜íŸ£ZPÙé‘GùğÃOÓ-âó‚F†>«Ÿ´\Q/PµÀÖ-.×&(“`—ôxµXÿFÏ[É@Ë€‚Èë¾ğ´!ğh'[ĞŸºóz0î‰vcİ&¸Úè¹L´…¦—½ı0Ê±ÇŞ°Ÿ½E¦›ˆÈ¾Û“×~ú1=«@˜ÁT³ßr¾~Ù˜İ¯0;Š™KIn%W{ˆñÅÖN™Bí›.gæ­Üµ˜aFù,1+’øÀåÌ…cmÏLO7LÍö£'Àö"í»©Šf¤!ÙİìSgŞp-†Àç!æNŸü¬;~GpcbEñè	á	ôü²·]‘ŠŞ§qE¤²‘ıããvÜC'+‘Ó)iª#u·Rø7i÷Xr‘ê€1•ÖäãÆC>­‘ìE5òz ÈÁ%EêTlƒ20ë;sš×"‚„Ö)ö·û”Â7›më<nëÎÃa˜‘}CÚAºy‡Uãâ^ôÃÉÛ«Ü¥®‡›½)ÑbrÖ6Í@G!š-æn™±`–e+¨:qDyXğrØ›ªø“dvF‡I~×úæÍªÙÔËa¢³’v·šÑ´SğÍIñ
 Ì’D5§2`À3}%0ĞÖàY+8Ãô¹jÈŠ£í©pÏo"Bn³ÏÃG>ÓY4€OW1B è¼ïI`’|=ÄŒ³Oö´ÃP7öÌÈØG1±€L`®}¼·¹!æĞ)ÓW‡S]µ®Ùå<ØTù^U&9w›ü½ø—•â@Ø*«O§n!
9TÚ%«b¦;ìZJ	£*Úh;¨ˆ²ï!ê‚VŸ46ëp  ÙgtNşşG©Xjw Ì&@^:œÚ7 : òP÷á?ŠÃoíúeºMã|D«ı°ZFdü¤­ ®œÎ1Î›¢…€;—á%ùÇ]×S]‹Z±@ÆN«\:d’x¿ÂqÖ®«3æß
Ó	F²bWè0bb•ğkaGŠ4»SÕçüeıPdËˆ“zhq‚eK³øW-F1pğ–9 Ñ:çP€»õKt­ÇwÑq Ô]ö·€aÍ)GuLá–}2oê.2w;X
Âk.v%‘:zü×ouéÊtS]êµ>q#¯TI2bÎe¿oŸñ×ü0›)t­Ãü_±GAîVc;6”:skØ0‰[ëåwÏ°Ú›b@âıMnº&fˆEå¸Ö[ÙˆcD8úş4“(WôìÛ†íğ\¹oU†¾÷„£„”Ÿû<w‡şş½E•÷}u9˜óYqÎñ;ñ·[ÕB7îXÛÖØ}—‰~ÎÒ)uÉ	«­l©™›w´—=Á½Ã-c)3"(‹˜çæ_3`ÚøŞªy"ôVŒ‡oã>¢R\L¾ğ‚›î²cbÑ˜iÆ#,Àm*‹/Æº¨ÏcËÈ°krºÑÙ¾Æ§lbMÑÈífœØãŒ´0@	†cnœxQÄäÚÄ¸ª®00³KVÆ- rAñl—%v_ùM6c#Gæ&6Ş´¡Oe¬_lJ_?G€V_îùúÕ±¼˜ßĞå*¶¥€–øQ±O©}Šè™²0	‰2³dA@B¾U«îö^*ÿ¤eÕÆ§ÂŸ„t¸´,ôÈGèb
ÿ%­F1Ô‘ÿlù·57¢Z‘×VïÊªÉvV6Ëu1ìÀã½çÚ@?ùc{L½jòöJKpÜ<]
)È÷e
¿\#ücŞ;? œö/]¹S:õÃ¬™Oªr¯ÔÙ‰ÿ×Ê´ÑÒÙ‹¯D¦a®v¶L08ÔXìM]5ş½üŠ$;ùÈ$Ë@^ io«ƒ*OğEê,í¶S¸ßhÂ<±»ƒ|ÒKMO;Î)ÀªÕõ"9WÕ·®€\úeœ”¹TÉğü<«­æ8DÒK§“Ö‡Ü«¥…€(j]†ïŸË3u–}/ó$ ]ÿáÇb™q¸¥[s±|‘BÔŒœÆâİÅ½8g«ÁÎz¤>7‡ z¿‰XV’hÜ«ÓèMLÎ¡`®"e00ÊĞn^ÔZ"Óe= ^ä;sAŒÉWl_o»ã1u,5Ùµ‰B$ÃX'°XS¥>Û’w	Ù­Á˜¨¹„;2ûu˜Ô"´ë÷œcí6ºn£WÄÚYÁs$Â©y$	Î«Tó'“[YAhûRänä€‘¢M´¼‡îÒÃ ¥xà¿"¸Î–•£kzÖúı»ÁcÁ&cıĞ¹FÎI†$2œ÷õA w~?8wa$#ö£B
\útLaZILOHšğ¿ûYå|^‡R«aö•S0¨h‡w/U¶Y„É_à@ï¡İƒÏá±çFcıÅÙ4H 2ä£„éüwŠ›?¥å›Î{HÊ´¹H$~ÜŠÈöŞtæŠîïîYÛ­Š9Ë™ës^ös·—Ü@ûÏ¹F!Jídêw¾´8şÏ•Àf_Íû ìuö¿„¬·tto|BEøA:‘rz.šGä®á„Ë>º(İ©§.Faœ	ÄMç?·ššÁŸ!xDoÊxjÙ8Çù ¾F‚°tI1‚ø-€>ÌoÚj SÈA.ñSÏ‡†Ìô]}p@O­Œ%OzECcEP„ÒÑmvUÁî¸ÄD]µú8}¦cY¸Uv`gìå4â¬èXÕÁák„hTùŞò-¸’QÁ#”{I&«êwƒÜ`fô¬D¦Q,ÈbÄiûñ¡i‰Òÿi¶|¯ú¢é™ˆ ¥§dÍ‡Dn×y™¹QŸd‚×,—vlr>GKÆs\•Ó3Ær$íÆ%z
`mUÙ´¶ƒLÕ©°(15¨©S€[Ş­—Q•`Š\H^ú®‘ ]„†wE¹Èü(İlrÎ0˜5FĞY¢³*v¨]ÄåLš4…[¿xìyÃïÏ»íÇ=£\5r%FÀ&Íûç–û+¾uMªDKØÂÆUg%#C/áÚáÔëş|âeÈÕ¢y®œŞ†‹bóùÔ45D|—:Ôù}•bP¾WÒ|Îyšó&¨Ë9Ì™
¤«^9/pø“YîV:€Ÿg%-ÌûR)w*ç ĞAŸIéPEeZÕbÚ·Ø•
ANµ‘g_7,[DğûqˆÔG}ÅÓJí©°êœ¬‰m'5÷‹rt¹1¢Å…M o*úÄPè’uFUÂfÆ2è·tm‹ú…­³*!èI™
í&×şS]ïÿªŞÎ5-Ùç}âÏ·ô¹‰Ó/¥Â§c‚~°CÔú¡×,¥z×Pø^ï‘ğŞì­ÑŸhµ~p–TwşP’	&ì˜íÎƒõ0\-•B;ô‰°Rrîs¦ÈÖRvl¿‡ºJÃ^N¡VäìRf…Ú)%†€~ÓS@¸Bœ.Š#¤§áPGæ­6:7ƒÔÜ|¬L¬G€¿GåÖãUL”„éi€ ¹×;I˜ú0ôô(û¹™’R–¬æB˜Q‡sF©=âÎ€@ÓùÅX² ÚÌ¬ Á]¢â»¶ÇÌğJ•v73M§Ì]ö® _ï ipe¥¿.>gbÓ‘™ë²8¶e½4İ¤9Ui{bU­ü"{™¨XY'²ÖƒJíğ¹ÃƒlC%¾îŸ.ÔÑÈÚÃ/À¿W….·eâñJVA‰XÎ™ˆ:nÄ ¦…ØÒAÊ3líïWO‰µ¤#.É†lœ!‚Ç•ƒ˜÷L;xï
õÓTq×Gnó¹]R®1³Ü	êÊ«Ì|áJ<óó7^!®G7î÷¿ÕT«œJU¥OvV-!>rÃ“rë±®EÎ¨îK:áÙ‰×Ç+ùg/ôyDnéK«S PÅõ$èj»&Öút^S¨şø‰yev|@¬Ş-ªaPÙ`5ÎµÒsê_Ñc£l‰§tÀ(ïh@V˜t¯Ğ¶fXzÃİÍK€gµUwrèDYëIäÂŠªÖ?úíH6ƒmÃMS™Vßœs?ïìCÇXÃÔkbt°¨1ı¶»­ŒÛg7*è¡G,Ô/wGhœ;ï[YËÅÔç«ÊÅb©<¿*4|Ş\]lM\)Ö÷Î Íbİ÷j.×ïWÿ«¬k-îæè9ÒúÆEŸP°÷ŠYJ<Ú!g<cöDx!h€ƒ7ÿr^X;e'™!³, £›EÆ3#	Â3¶ÄQ«Îuô³¬aÓìˆJé ÷íWx‡[…îGq4‘^"”†j5ïXw~|Ïğµl€…$c|[‰äÉØ¿ú<Û€AÌaV_q$®‘ãoÆ¨ Ñ+š¡`däçbP­Fƒ8áòOÀ&d¬˜“Û;İîãoSdİ?¶.ÖVƒ2«6 r	ıt¼¥‡g·¤_¦¾¼RWbæ§ğàAÇ™Œ$àæûzÛÍÌÅ]ÿmÁg':ÁwÜ;#Xio¼)Q½ñ'S–ˆB>ûf¢²{PnÏÜœÎ2åg¹È¿aèrİ8“‡_ºJS4j›×MÌ¬l%´€qÓãßx®›7El	hñGO™oï¤î	İXÄòÓ´pìÎû)OpÃ¦b;ÈõWˆ33*+O¸v…~hıÒaS!Ê8©µ>[´[%ÀÿèCP¶éŒá(%\}¢,¸^)NyX\Fr*şÉ Aée„ï¸ Ã¸óbZ`*›/Åvı8ğŠ¹Ô÷¿¢£‚0¶G:”Ö._†L?=U $”EãK{ j¹;¼±«—;4İCÿ'<88™¹»˜VŒ£~ ?şE…ÙÊÓ”Ú5Ş×Y²)Á1/¢åfo½¯”¾I‡‘Vn”<ÒlvÓzâHÃÈvf ]˜€ [:IZÑ‰GbæáYR)'-6v]×8'$¬	¹×æe9?°-ü(i;#?³Ër
Å»Şv¡”ñÅë.^,r"<w§L&CuNjÅı„¥­ˆ.†õkÉàlÕtÛ±d`rAák¨òü+c´1^ÂÄâz©­ô'x’è0¸Çœ\8l“ßÅ&Hê©=¨ƒªÍåµ‰1;ø´lañÔF«XeoqäG6YÇ3´GL	r02óØ‘È‚jıuB5¦W„ÜÏ`åàl^[¨r?zµ¿@ã¦´t£Lô˜èE‚MĞ9E6&¡lÄîlnO0¶­Œ2ÉèN›PtXc^e“îä˜KÉGdÿ•‘‚şW .şñmØ0×‹ã*UŠŠ	2[Ä1nÉÛşWõ™dá"å dÚÔŸúN“|^ˆÆ2Ì¢3áGaI>£à[µètÏè^[oÎÎÛRb¡Ğ… ½Aëûníÿ|$aP„ëQ'|ß‰ø¡Ùä(ïÆ%³è¥ıE
ÙdÒÅ5¿°R‡pGªp=œ‰iÅ2úí4^Rº‰¯³HÜ¦T?ãCæqg¹œıëÁögço™ãw[&JˆzúÇÌ †’€£s“~ĞuÒ†57]È
Az–;n¡â—·ï%¡!MÕ½Ó~éU(œ  ›ØÙ£7YƒNãßØS…Ôê§ŒO§sŞkV¿.ÈËIæ‡ç¸±ÂogDúÛlîiàÔ/r†à¼Ó2%	Û­Mn¹ÛEôÁfû–Šç”7{;÷İ
Â4ƒ‚hJÃsÌ§&¥Çèñ gx‘á×^ZnR =Ñ¶YÿŞŠöµ#vÄüÑÌoó¹ó˜6H~c–ÁNn"b a~äAi530tŸí(”ÉÀt"Pga(2<òjû‰œĞŠÜÛáİéÄë?‚Ì¾ˆñÆ­õä•@,||Eöelo§òâpg6¿7vÔµ¶¬²³S3ş£É«@ùD$œº{<À‚›Â7şü  ©@ÿs@Fò³S¡—HTûSôĞ0T?zªú)yc
~Ï|ÇõüÔÌûÀû±OW%2m/uiKĞD:z®¬Â {Ï’€ñeßv y
›NáÖÙ^½fõ`î    !¡Ï&,‹“P æ¸€ÀŸQè/±Ägû    YZ