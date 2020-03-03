#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1602316796"
MD5="aabb12a633829712312b0071392e5229"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20680"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Mon Mar  2 22:12:17 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿP‡] ¼}•ÀJFœÄÿ.»á_j¨Ù¾o
“‘©BÍ4NBŞEOHÆßb\ı”ú©šúÈçÔí#Ñm'†ó“e‡¡›7û/O\Šãèı··lğY¾7…£;ŠÇ)¢½‰,Û»düáü:‚e!—œwh…Ş»õå(Êb»¾İßÎ?¦Rêy*ØÜc¤m@VçßBÿfHTXÁì!ÇmÑ_hTL½¼í]A‰·ˆèL|èNºRX‡1%lãyØi²}dLàµ#ĞË«&a‘¯¿¬|`–|gıàÛ¦¾ûúB¼'b¤ç{ÚìÇY.OwJ(‘$ë8gäºşÊÜu¥—«WÍ,uäw#$JÍ'Àìş¼ƒvŞKnÿù	(‹;Æõ…ïõë´ú ğÿX)™±^‹
`áùÅñÌö< ¸Ü¿tøà`3›Ã¼¨¨åŸ˜LtOò}ÆÁŒ?ç=-‡ƒÿsµúğFëb)ÖĞ£_êff] gğˆ¯ôûšº%×¯¡÷2FC­ºˆ §•&¥ÑÎPh‚óXŠS¸D0•Ó]Èé‚/BZŒi[ÚOYŒ‰Ù©!ãÜŒÍFaşXFDãPEèµõ{W¡/aïİ­éYôNÓìC¤t»\œ	Iér}œ‡±Ì;Ë·ãº0ÂÚ§AhÅŠ"¤”°Š™ñ‚LxK®Ù,ïKŸ]YÃ]œ!÷÷şÎUr«swuGp¢}77à¹Ù¯[:FÇã»Î¸Ù˜s"}£f´€Ï6Ôó‘WÕ ßa3!{¹Q]eAÊå+T¤2XèX-±xDIÀ¨Ü7‡İ‚'Uwgn¦ƒ>Ï
ÎôÜ3·%b£¨qÒ#î7%¶#ÜŞd³t¤ysT-dn/ˆíz.›(¾ˆ"Ôq²¼+AU7(Ğÿ+vkøDT2ÂÆ ³óXğ&ğ¸O7d†)ğ^HÍ°”r¥›ú®â×øğ›ÓL@¯¤1.ÅõZXvM„Ø)S™>ƒÂ*üF³2ÖØvlÍ@#Ù÷CŒvttï Â‘œ«¯´5§/OîZ…˜û|.(¦HaàñQã¨™Œéù¬¶÷vnVÙšÛ‘{ávÄB©•?k>…® 4%)2&âGTU÷›¨•®ò”N‘ÍAö6BŞ¨ÿå¿68;2ã)¤ëW‚tÑGÊ›^5x¹•,õ¿$êQ;dŒ–EÌİ0¸¡ièU/àFÀs­3–Yf¬ly(¹3E™Vq$ƒ©>|M¼°”rêª%¿‘Í])Ã+×È%&yVíÓ0T´ô¡w¾Ö•êOMâV	ŠuT'|¶~$[IØn¡G‰›glUlñ ÒÁá±V$ÒŒ™^Ã`£ĞØPX^?èÙ	
oäxgxüC(Ü—ÇŸ_ˆ¶ ÖrMzãdïMÒ[Ò\¶ì¾N§Õ«‡—“%i"ƒÍˆJ¿•E¨Ï]ƒ“\´Úogµ•=ú­Ïöˆƒ~çãõßşF›éâÿCçîb“¶66T	eæåx0”˜]V‘wÙœİ%ozZÓŞü"¬Ì…hºé×>Ÿ³Ë†M5	«¢$– ¶$¢»ÂÔ1LôİÇÜæÂI}$ çN	C‰Î²eK7 Âw\¦'òPU;¯çÙdã†v˜C)}­ä gQ}l®Fe´ÚŞd[Û”ªéÆ^)µY7¡Ùÿ•É¡×¥û8)U‚	Kx½÷6jŸÔvüê¢‚Mqáİ…?OÖTò_5ÿæ€_ã¥&_×yøZ¡®î,ÂÓ×,Ğ˜iò¾2ÎûwåàßĞäÊîæ¶DİgáH"ğškg™B×šzGßJJ›œÆ¿mˆmØ^ôÆËà¨ùNd¡Ô°R¸Çµê'3dÉ_4|Ì|¹a0¨%7C™Y½^)¢§Ú1Ş$è±`æ¢Xak©K"-9æ4[ºC‚ _-=¦³¾´kRndƒS÷Ô5›{Aµ‡#ù-¢Ë¦P_– 022hñ£¯úî(ÒúŸ¿\hˆ+.€¯¯ãíDû£¬ê1`}¿ç Œ'ŞLIß± ø)ğ+î÷ìjÒ¨$úßÈI÷ärYÛxáÃRŠµó¿Ï½ñÈYåi~µ¨gßÜ<§}­©ß‚›ö•/övìÔºˆéü'ŞŠ‘Ü÷5ÌuõµBG M¯Šl†Æ½­F4ÊXp¶¼T^¬ååÀ'göü@š)¶÷z€ˆ§htNåÅ—Š‚#Æ4ûÚºâO
Ü+•F9»xş·ÚUÓ4P5ÓöÈTßjÙ1õô"úDüµ…\l‰mg(pìØœ,Ğ†,Ù?¼(´„g«È¨ˆIJ’"Í¯ß…mä©L:ŠqØÜ„“9(j•ã¿‹œĞ9U'¹–/Ìiµ^â—x[‹ ù/ã5ïÈªu©WÍÒ¦¡tÒBâ"G¿(¹Ô4ˆ¾¦×“éß7¬4kòãs:³&íL½E“<¡RåÃÑÇô¯EÓuGŒ!îmì•Ç"Ÿh>ULŸ@ÜÊmeöCğ‚QHUÍô”¸›õÔ:,v8>Ê[RzøĞ(#Æç\:‚5Î‹5VK±¨Æï‹KÜåıòäÏùÑùl)ÊØvGºn\íh4•wlzù&Ï6=L§DG/àZ«:¸äÏ¡]JÙ;.‰4=J¨0À3œèZ¤Å;b–wYôTMÍ•ÛØü’õ…Â¬ß?à6!ÉjÔfftÿ$IÎnu4£ğèõ¤¦ç‘WÎ…Öü³²nŞëİ{Š;¾ø¯…ùñ9ö‘ú)ÃhAxÔê,‹y:‰6ë4>ˆóT¢Í¬?ªH{˜Ô,`ì2Æ)Ãch[fÈjA¤íRù¨&ÖËÍ3ñmc;Øéª†Uj‹aˆ¼¤Öşƒ7è¿ÓIb>„^ãRLøYü²i£Ûƒ ^_~}“l(U–¥ô^YŞIª ë±«ô‚‹|z=Q»f•ÜòçñŠ[Ò£F–·dLp,ŞYüÚë·å¡Š‚Ga£‚ÓˆfÈú0X(Ÿ"™_ŞH¥<e	,#èŒ£º˜V~3¨*"8°Ï¢C&YÛçZŞ2x&«+ÑW™x¡¶Û„ÍÅdÔaÓesªÊÊZ4Koş`‚öÌ­Pìpşùñ\@ÊÑ-¬ÆlV×ï‚g5û¨ÕéND%'Ò nµq©­«k³íF¡…ÈØJ6qu¨7dr´§èıèÂÂ¤a¼~rä¢ä®›¯5 BªK8àÓ
²Úpp\ï~Şåâ}üOüÀpõöYü·Ş–†í*	Î{RkŞY'“?ªzùÂÏ³{Ë×`=LWĞ ¬†s’5~-s¤Q*Ü6©ÒÀJ†êSpO7™zL•Ï³HÄ£²˜+»E5Õ“<#0BKûyÿd›NÁW¸1ûnLdèï£YLíy=ïÀ…Yõ½¶
k‰·K“÷-ÄÌ:gD”·€oQg@å+¦Á¯ŸvøŞíwíæ»‹%¼dg~—ÔVö—5¨•øÌˆßÑTeÏøÔ’îavù‡qõ§P~sÑ/ĞL²Kã\ny4ã²5XÑSòpéw;V¼"0TvùMM¿b=–Ó@æ2*$‡oB¯.\ÉuOĞ\&ÆÇê‰º)˜ 8Ãã—Ôøz²@Pó¡a€¼Î›Û!RŠÏ™æ îi"ìŠªš¦¥C/§Êm;ªÇLJ–F$Ø‚œÙÛÖ£_~¦$b¦p˜ÿBÎ±¤qœTv¾ä-ıC¨·ƒ${Urí(Ë:&ZzåØ–¦†°vgiSH—ÄXƒ#ıõu.ËcœğÑ-A	âúy´³ãf—Â&é{9P ÷ıRcÄ
€‹uäÎ¯¼ÚYOÑ1—vÏ–ğõ7ô„á#i!Ø~"úôÕşïĞÑ0ŒmóX¦$»˜ÄG]ŠŞÃò<ÆŠ°¸Ñˆ1#²6[£ş k—)ùôÎJ•¯|¦ŒLÕ•ìVRçWê´‘>8 ¶¯€ËyEÜ [ôO³_9œ Y;‹,6U™U–niI.µi,zŠR PŞe»l5Ö*ƒ3ŒNÖ£×Câ¶7.KLUñwÿŞûQƒXØöÄ5¹n¼Ó©;[©ã2=ı1rwŒ½û…ˆbR®Êí:ëÖ/U2äÅ9ˆRb2@Şœ	—\ƒóWI ªBmVÀ©›*é "=#\Äæ´†f<7è¯Š-¿dû¢-ªJûUE9ûI:quçı¦Óø†
¢È³èó*ÁzàWgh­~^ò
Væ%‘q"®/Gş¾ÿ5ÇºÖÅß*ß“àÕ`ÿ¸ÂÄ€Õªü´¬²£Zî‘½á°ß„[@ŠtÔå«ij§Õê›şó™—t<z{uc‚p‘¢]úÒOqCàşÂN¦·èNn,;T<Í°¯@¬İxvİ>6{â›f§œaò}×Ó‡rL‰Zâw€–©iÕÁS¬¿]G#õoÚÌĞˆoºçâ µkªbT¦Î©£r´»‘wÀ^Ëp´°7®èI%iÊİï,&RiŠŠ(ö!9cĞoU![#:,R!¢B¬ÊØ)—!Û'z*M­ñ§`›
ğ±´¹÷µSIÇ¬eÊĞ[š=
¸Ëf›€ƒ|S³fLb^JŠ «æ´]V·§|Ã—¸†ºó‘7|!=ÕÂ&•NƒH‰	íFa”h³Óï»Ï°Ç­ìÕØH	0ŞmÄoYp€eÏñ{›Õæ„•	İJ·¶[Ô|¬İÊºgœÆ·²×ºÒÚV'ÇÄ†÷Â.Àx‰“tõ€9Æ˜
1ñğ>´}¶dF.“Åô~4Œg±rš#óótr[KuiÎ£Œ–ó^®´õ	MÚx1ˆåR€¡®U,.ïéÂÃwÂï©Í™/DÎÙrdºj_¦¢€K/4ißÀúÀu²T57f|dÕ¶ÛİG¬[`‡]$¨<©p3d™èÑ‚*ü£¥p:Û?á&WÌ¸ñ0Q$G ”Ù»I† @q=°/·ô×0Ñ"fTÉü ì9¬ö/. û5
wú|™*,%v˜¤âßßêQÚù·ÅÜÁÖ2O±XäŒúãgÃ=§<c“Sğº¡ƒ¾‘æTüŒˆ«W”½b©à­LêAìExš\¤ÍÿYt4â_Idf¾#TI¯)€õ’G(´‡Á6jŠ‰Ia[
Ú'Åìš]r³¦´õİJJ–¤Q&êÏE«KØÑß®²	’jˆ™£Oy-ş3h@ò¹ÕLV¥F®UyyËšîr$.~Ä½•mëÜ]:“díïıBß{ÌóNP}f°Û2“”Ópy:¶}ß?ãb'û:xwç‹ÿ
`YjLDÜ”‹°î’­(Ó¯G´êÿC¸©TêÌØ—¡æ{xÓ1°52«ú#Âˆñë€B€ D”WšQc…xHŠ–˜æZbPhª6¡%5®Ls·lÇ#ÖSb(ØjTƒ6 –¦Ò¸Ç$12`ÈËÚ§ôTÓëÈMOôë*-V 9\TÜéÃZÄ€(Çƒ©ÕÿJÂ¨ÃW»ŒR»ˆZ±Úmí-ÇaºÃ*´Ü=xúyN<yÎbÀ6zü|ÜŞš°éAø²ë¬…äêk¨À°4†—#OğtI…i‡£îûø}Yë-¡-8“ß©öFxmËÄ6àØÆ‹…É‘¤=byrM„GfğcVE=1]·ER½»–·|'à¤¯P_´^?§R™¦~Ãş+@a_ÊnÁÂ&KÚy–ß£ü×âJ\ •<¶›Õ3ùó]$_<<] qêÉ¼jpÂ‘ÊöAç¼šI÷m¾óÏUSxg'å.hØ«R<W÷^)ÀÃâİ#— ;c-ækh î[×½è{õ-v¬M¡ÈÈxaú&”‚Îïi@Vííè$ìw÷ .ŒTZP«Ù–¼Ã¹4Œ9Om% ô³uÔşoäÆ„93"¡kmMO€ ç¶ô<íA÷ĞÒ×½Ê†KËÊ|Ùô¡ÙoŒg©9?Á5‹@ıW$±ü$|Jµ(Py_]w§!ÿ‘4Ü–ìI6ş<[§ºu+Ç[qP¢…\tËâ«(cFŠ'«S›fŒ}¦ŒİrOšqš]z«u¶3EÛë®®£_S
¶¤ú€ÕRò.Ö¢I :Ãb"I_ÿªânı>E®¶Pœ]»­HôràdñPŒG_^1k½î8wjTü”e-íüÇÉwXŠÙ€"Š©€z<nĞ¨İh›È$xxnÕD³¶êÌ“åZ	E¬½ö´ªŸŞô¢ñón®öœp¼ñŒnXİ‡k‚gÿkG·‚ÅÉ%ÅØ8/‘ÍãºzTâ#Æ×–~gªK-"„tm ÏcŠWJ˜é¼ÁÖï v£¯‚ãÖ"Ô% €ı	W¼¯¶œÈItñŒ@³¨ŠdÑsÈ×%ÒÑ¸Ã3½§Ì	‚Â®¦Â>ìÇöJ²7¶·õÉJ(~»ˆ…æÖÕƒÌÃ‡î°`ã”£qöçß[M('0©CÁ½Ëq¡^í?nï¡0G•,ü.¯aXÁLi7¡ãy!%÷¯_ìÊü1;À?Ì_GÓ¿|0Ş7ƒ¡b9~>›ô:«Æ£7\J$	ÑçÜºp"âKJ#1R¯´n§ÏÌŸä,Ø“%.Òæ’k{*P'êµM×îŞG­°ÁaÃ«:Ê•Å»™–œç¸~éĞ\õ9»Rşí	† |rËK“,_Ÿ
…æ£DjÈËŸX]gsÊˆú§EJáÿÇM›Q~› áó¶1”Ô˜õÊ4äÅŞWØè}x¥îUÕÉb'=3—Øä*†\¯µLî0>Ù„è£ğj+BZó¬[ZÇl\?Š4kb¹’:ç(ÂuÜ “‰ºÔÑUÌ“ïƒæÔ:½3HÃ~ÀÃ_ƒ—J™Ö!C»Ò!ªNh}^‹€Ü‘×_ŸaV_mÑ.›ş{ª½¿”>jó©'»©$Òh|:Dqôg&Œ¿2Tº$4/¼G[wpñ^
|—ÊòØÅ½^ÍÜ4ÍÙïfR+·JjÌ×3İs:Ç¾i¬óYıšÍÁÑò²ÂìW<îáé±Üİ½½74†Ñ]öB,á–cİŠk_e(ŞşY¢"4]®cº€ `ë:ööv¯‚‰‰8’ƒP¹	ÊxĞ¥jm#ìè}úå•Ë×±Ÿ6u2Dàñ®U#˜ŒœÒˆ´õ´pö¡1›}e;Ä1™IÂÆv8"Ã«ÀøÅö™¤14.ç±'º˜¸Sj¶wè‚—¬¿Uï!B—+E7ã¥²Û²¶vò4ğ*ÂŒI2»"ë—üÇ[l¶Î+ÁÀPÕGŞe”Ü_uÇö8!«$–DJ¨Íj´/j}.ş‹Ç¨Î€®? Ršµ¯V	±c¯õÏj¢¬J9™”	Çªœà» ÿĞ ¨vş˜¯3Æ	J“m7ûï‚Ê’öıÑë¦|­OùûªÕ›å*ZÒZkˆót˜¹„8(YoRväE—Ü×Î{ ”ÚÒhÉfÑ@V¡ÿ™eò`”¤â_îİ°ş	Z  ÒµK?ôz“E°™ºÎ%`¾€º¶VX.¥±fœf2æhã©õhë} M¦¢
³·C+—µfÏ­\6®2O“É†âX4!@¨ı„R;ğ†˜ë’µ¨æĞ‡<ŸÛä9Š±‡H&Ù+Šæ½eq(¯ƒ‘¶j–ùâK˜SÿU°“?`Ù¥ŠÃò§¢vAp‰Ê"Õ¬LBH¥$å}ÁÆ 4 •÷AxØÕG'â´ˆ´O%pƒØT[ˆH[po4²Ê“­Ù?x×4[ìEÈı½½0í•í?JVhÒÕ(Nf|›*üh„DÓ	G •_xVÌgq³],ê»Ë_Ø‘ŸAG£ôR4ÕÍÚ®5{î˜q=qyë\zÜ''ˆYéÖŸxE‡[YEW° ·Ş JÄ‡ØÑcŸyìOuá¾Ê³
w(SHHöÇ3xh_¼	‰¸åtX4Íæ–¾QG”XXc7p0YëËpQÙ‹é¼óÀ€ä‰şğğäú×(7Àj$`ÎF‹&Ç‰÷9K¡Xİ	 ñëL:½Ct€x§ä¤ğ‘78jÍ—¿cº¼^>YÛl y¢8„ÁÄ‚rŸwV<¨¢³‹¢{O"O£bëI&æõĞD¼fó…QãÒH,âğá·€Då4‡A^•ß1c®Š	pÍtëAbÊ,Y62Ö{`½ÉhöV|*ÅÏÜZ6Ûë¸Éç×ì)ã†è2 éf³NsşìÄù8Gp?qc¬´ãc(5ğ< |ƒâ"v~÷ğ/êz ‰	~á}>6‡Æ×ƒJ÷÷İ™=›¹ı'jˆ˜¿’~BâNåhnK/•ú€®h7n74›Ùõ0-t5¹ ä™ Lµ·°‚œ{oßÚ7æàõ‰§2k¸F)CgÕ'rk’$*¡DyM.¨“Kf´ğ4‚±nö×vÍG&`kwL'›½>âØ¦„¥sšx‰Ñh,B¸Û¥Ö‹!†áşóÊèC%­†D«6-ÃeÛ¯PAÉ<%/É™”A¦œ“¹‰¬UŸ=7÷ä¯~±½bz1Ÿ‰oş_„IÜ…‰ŸG,B†²^vùô*]B×gÒ2ú;Şš±5l§bª”M]oU‰sóLYŞ(f*§
”pÿÆÈá?t¶3W>(Ÿ'¸#AL¦–:ü€6£ Ì÷¡˜Ï“"A«Hª@)2¢»ÃõµŒeOªª$ƒ/–íœôr”nb²áÒğV”üš “¹M«èR›àö":±IÏUE¾ë2æûy­d¬Ù5›L1J¸L«Ãš¨,(½Ö¯¦°g¢k¶©ÖÛ˜.1OÈ¸}yŒó,3Î2óÒ‡{àsE§Ä“NïIûƒKm„°j‰'Ü³Ø-¸jµ·Ë´jv_»”nÂnò`Sƒ¸ÒdW×Î^TV~‘-÷jÏ¨âz‘ìª£Áê³[yß‰F…"‚Ä5„*ï”œHaØ4Û5`6Î“\OxRşæÄ|á&ŞèíN\»N-:ô~è¡¾
ÆÒ‚"¤ı”PMg`Zé<Yzÿ<L…ùëuĞaHañÁvI³@Êù—ÿÑ¸ø¼eğCx962lúF÷!«íùšlKì!@Àv"]|ÈZFÒR-ÂÀŠÛ+Îú8bŞ¯$ìpEF'hiÖ;xšù]Ğ7[ƒ(¸ğÒ]¢Ï27Ÿ0ulFÙàçdÆ´ âöyìLØ*»{æ*tÒ£œë÷dqÅh~!ñ²7¥ïma#¸»°İfÖS¼Á3i”ÇÔ¿)°¤üte	À0‚›œ'™õcuÖ°îÅ«Â&œs|ä1–ÔY6ëÜ„Àó›Q³‚,±é)âúàêÄá¡y58*ÙN«ƒJ¿»d}a›ÌÍ`|]œÿ{¨²¥Í/	‹< Ô`¦‹Ë¾§oüğŸKƒŠ@³İÍ,‚°Ë­Ü©½ÿÂÓÄPb #f.¢^.4Ûl_¦.¹DÌšå‹V–Ù3^|ÿa?É
:Îîk¦ñ×pÕ{X›ÎQ—Î—¥'O
~[=è†”œ”–ÓvÓqr“ìY€~×kßˆó{.´œvõ2$D–h¾„ÄF™"JÒyk&öµÆ¿?k¸É¬·Ùær™}.Q³!m6†™\¾Xö;ôĞ=W	ãq¼„ş8Ã8iWx”œEM~MEAEÛcn!f¡ÅÇŞîijJz"[€Õ“­¸6„8«1Ã.Wg^‰\ˆÏN6˜Ô•$¸ÅÚöÄw f[
c`M?ªƒ~Äñ+*1¹ŸøláH=Ù4"õMUÕ$÷
ÌØ+7nò{¥ç¹Yná` 'ù#¥_ÃwFÜ÷ó‰9÷ößSÎÁÇ®Ä•«G¢b¥«òÊîçÈ «g§7'Šİ*nûBzlÊ#1ßb|RûjiôGnÙd±ıÕJ!¬‚Ã@1Ğ&u÷î_ï‡úKTõ’ –ôÓµ+íCG‘[è|ÏZŠ}À0ºxÆ?Ñ ÃíoÖp0Éæ†<|µ[Ú‚óïê7	<ŸAg„püÃ}sAiB¹¸ÒÄ¹<¡•ırã”u¹1Œàh6„£GİÌÁ¤ Ÿv '|:„Ío¿OßÓ|E£åz|_ìsAH¾¹âJV0ô$›Ç)|ËÆˆ|®Y$\Ë‚AiÂ[xhëÜ7~®ó2A¼éÈ.½ûW¦ä^8]6±Zäªœ~Á¦.ÛÌ(õGïnıû“·Pkª­~Äº,eCí…çÆ˜Ú!8¶nÑ	pİ.öß±›“Ah±¾ÀV¹h•Osè†QË¹`´Ë3TÛbˆõ1¸r	ºÏ.0bì¡ñ"pÊú®ô%8ŒŸØzŞÚÒ›¢-æ¥nÂg4.ºğ’Eä|8VDŸ¼Ğ2mJ˜fï›oï	+Ä=Ìa<mïB1_a&Š•zLÜ™“C˜1&]E	n?Èæ¶vœA(¶{îÙ¶zÇ"İÔox¨n– áeÄCqü*iàªƒ”g²»ÁJù&93´¸C²—â~òÔıˆ dméN=$Š.LÑ‘H‰û:ŒKç.Ö¢èJ¿yËÎÏàşš¹ÑöCÜ‘€-£©Î-Î
ù'šH«À.ERfÆïb8$xbµøN?‚snÎ—ÎÑ:îT1:À=<¹Ì@ç9‚j)ÊŸH©İáH–Ï½½W
“ÒöçD]ïœ;µ.üô’ıB+Xö^‚£%ğĞ3)İ=‡Fx/&ªê>¢÷úµ¾zné`½Ô¤õv(#mâV4‘¯S™éÙ77³Øx@Ü „3>äà%&kÌê[Õ2ÿmèŸgµÔíøS;
°Öã—­h:{'…ìú£4Ü]ÌIoÙ™µÖËdçTÃRÂYoô f˜D‡û~˜b×ø¬2_#qUÕÕåÈdÓøÅ0èßŠWr—ãâ>Ux|B¿şâ0—WÏW¡?º96›°&Õn®#%#€âÂ8–…ŞÅ˜»L“—pñ¬ñTİ.
¸“æÀµÀ^{®ş—sË4OãŞÖgÌ¦¾{"ew1Ì;Lë›½³™ë‰Ï¡'^t[$~Y^ı~3,cš#ù»³qfè#¥öCğ©ºg¤¶’{ûxæZ·@Ì©~úi³ÚmàF‘+*aMÀYÎL+¦—»n´ÎòI%È
îB’¡¡/1wÃ€'Ã!ÓkIšÿ7BtĞ®Ë6(SíCçğ•‡×=³55KÌ¡Øªê¯nÍ+Œ„.Ôšç.#»ä5Pgi¿"°2˜çÚo²ÜµI237r¬Æêl'q<ı<œsú7&­×Ö›…\&†§ÿbéK²‡–|wb§éìëîA~ú’Í2×û4ÍD¸™jZ‹Zgø{Œ®í<óhæwúŸ!k'ÎĞaTJM†8~å™$;F€c­9Àcm.•·íËù„·HÒ´şôZK×G~„]I»4´ş™!9¿üCÑéğ¹ëı¡`œœÜ3îØp:}"9•ÊÊØh)¦‘lw=óåk3µX¶Í,õ¶ì8İŠo­c¹_‹”úua¢ä®”Ê²– hï&ß]ó@’Eãg½úsí¥Acî´ÓÚ6v,/{Ë§¨÷hÆ>	Š3u–(¾#Š±4àVïfŒË	¾ıù0§ÙGƒf§¤:?€³Ùã H™h24]è)Eƒš¨K,ÖK¡…7Wı‹À4Æ^i¡™?-ksjÚÈÈäÏi ¯¡½@”( B@@gö+Ú2:E¹6wg½T1i²çPWaâqö›µàƒèp€Ò÷ü\£çX}¸c6¨hÏÛ±YxUÌ>Ø[¸6rŒ¾Ë®Iğ¢Q!§œÂæ"nYŒo¦KşŞĞIÜ…f!:ğ….Û‡a”Óá!q›ÚºH‰¥d`ºãÂC#\‰§ªíPæ¬)nD±b©¥Aù(BËdìaf‡Ú^‰
/„ˆAÍxT!ò7ÌØfwİÓ5›š=x»òò¨=2ÊÇ}ùmwi-sM$`lİ(û¥o
r
Û¢‡VNübÕ”Î* t€3ÕÅÊ*­wyàª‘¨èÕÄ2Ä~%$×²šDA,‡4FÒçãİÎıãPİ ì
—:z¾$
˜¦ŠCbÈ
±Ÿ’w‹ıŸô•…÷¡ÊŒb¼„î1pºÏıZ¡DOÌÖ5d2ğªŒûn™pÏªÙ¼ü…IÈŒ=’åËÛô9ÌÎW’@º”µOl,Ğd„2+AvÛlê<'{Éã«ãè«§áŒjT|šIéìî"¯Ã	Ä–R¨åâÏùÕˆÔY8!JÎ~ÅìRkÖñÇ™‘dñ1îMÄ©/BõX‹F—–WP‰ïJ"©j[ k­RÎŸïWPãtxÜ+IGôƒpP7õ*qÅ²3÷j±"a1²ì¾Oú§6^‰Ş(QñôS¡B’8˜Î¨iÍËJùãĞò+ ÓNÂ;ãXÚcÀ0âM]ùÀ&øÏñ†ÈnNºÚ(UéŞ/…×'*"—1ÿ71r’7ïWØá?ÄiM{Ûó…ÀnQŞ˜À]Éhö¬a¯án<xªŞì$¢õl.^ŞÕ×ëC:sH£›œèf®¿û¤{¬ nIVVœóç4×õ*¶J‰-Í?ßİÏ*¦ğ`H|6=ÊúÃ>®ìÄ	5£ıP¬¥{{¥½8¥jeÖ…gºĞÀÿî¹ /_ƒ÷(ÙRWÄÒn>ª@‰'/‘—ëYCxX(9¸Ãö€ÚÁDh×!¬Hª³"7>´EáB¡¹³Iì›Uë”ˆ,í:[s8¿ôÇ9‰Íş&†æÙkÙSØÌªq:­†ˆù(”…"…Şr¤ŠMåä7›ú[Ö3´á®¬$=	»ÊŞÇ‹G…OŒT•H×Ø?ÆKâë9ìz;o0¹YE@¿sº}e¿#u\yÿ?fßC×¾‚Ä¡tUê*Vc©Ğ¬DƒA} ¤Sk`ÏvØLA±l{±U¬iÁ›“Ğ«	;¿ëÙÑ$i9„‘Ìì”õ_å`j¶Ö8˜©U¯!¸…1û&ëf»˜6ª’¨rNØE®š‡æœûæÒ"+DÊuúàP˜Ïªq WJîï…h³M\hÃaôŸ8gõ H®í(ƒô²€·ø¿æfÚôóm¡»UcªÙ À¬;“¶Hè@…®^¯ı@Yó=¦ß†™C@¦è³–Î”
@Ìø­Z£ ¨Š‡n2³ŒÈ¾íŸm-ı+w^Ä£ğ	—ÕĞÈb—‡]İ)–Vgáe
g…ÒôLÈ.É„°ù(ÑÏÕ@•ĞÅĞòaçh­•á~Æl?TòlŒ°ÇìÈ= •ØE¾,r{0Ë RˆÔL4kI€ÇP	–§ ÜKÌF2m¥!‰ë¨ÁB6s"Q2“â'k 2=ÚêİlÜ\	S™Ó òiº¹%ÓÓyÏ+ØÉd"ûøêvÙ5WøLâ›péĞ%½~_ßŠÕ€Ø~;nÎ@“Ü†wÒÕôqòÖAjÊ³ZOLÀÉõ€C‚4Ü8Ò›}aîºMƒNˆ—F$Ô„l™‡2x¶Ãİ¸+M™¶*WVÓ`§SH\CÔ…Í¿>‰\­ŠŒ´^·j`ôcßkÍoK¹FºŒ6Œ¬GœÀDV+Îª¶×úÃóVÈîG›D¬oßõhæj²¶9o¸|?1f\bEáÇ9-Ø”€e½i4—ë"½" ÚcX@,S0è%ËªUøÔ ÚÀ;=×I»«yaI˜=t.}Y¶©ÖnÔ_ë®)^ŠÍÉ’[ƒğUêÁØøÚxô•ƒşæ'b$5f RŞâ·S2ú¿¨¶š¼y!N˜/$ëĞ.dzœJ¼˜ÓvGd]åN“g‡GËï:£Ííó±n[Ì"W/A—
E¦”‹ãßßÍÍ[‹½³n[V"!@vIxFßZ î…M	íêj»ªuV-§+¿<ëuÕË3éeğ]Z
 ëİ!TjL'ev@ìGö3Ù§7?Òü7W#÷^± &:yÓĞ> 9—ö7¨~qyU¯‡Œ}:gC&°-Q«3(¡ïäq¯‰ÇC¢`\hÚb.9±„²Õbñr[<ÿâ³Á½V Ø®†@iqÏ¹ı@‚®Å€Ô‹Û—ô_ˆçh*¸PÌ=å¨Ùœz,óËcrÀôUvetåáãÛ$äÔ.±êÍŞ‰ƒAÓf°?©íIZK[)Å ;äkõãskÙ%ƒT¢‚&±İÖ%vâ:Ù„9­Èíaë¦µÈ9½ìVH]àôEXzÅE»iÔ!`-²è“j­§nñİŒ
Ñ!Í(£Í¦@X<G;Ëù¢¼Iâ:ÛÚÿw.vÉ®–¯“è-ü3N¬L<×\x"&|ÂynÈ†Éx}Ë¤»6Ayí=¸¢¦)bš`‚º÷R($¤úÏÀĞànCàŸ·-ıİ*xà¶úìïß)ÜÛ2pñğæ¹—˜¸á˜Ø\NÊSq;ß˜EÑo7yÒÔ”œq@=û±ç8e¸åH³«{ş1JøRh'Ê³ŒÆk8}í×ûÜæ|‰¿ûqmè;-‹]æ¾5Õ39Ç_î .öZTn®t~n³±‰0ñt·YOs\9ù“mãéö!et–¿ÑwkØ	…ç¥­;ê[¿œª˜ôÀG4däÓO¨¾Š;pTçà5A4*ã@H©¿§“;;Ä"ZÌDQÁY|µÍg‰“•ED†™ºjµCÊ¯›â5)äO…´*,Ô§yx—¼—,¼ü©¹d)or#¦L”Íè\Rİ¶6àr&P¹æ#-ÏĞñ‘ù\§pïßªû“÷hìs
O0EP	N] üÕååNX¡¶ÿ³Á{B2?åóû÷¦6Çó1—ñx‚q£şt°øÔhÔÍ‹³;ôÁŒxpóìæ6Ñ#Ş„2û.E9)¿)b#»c½F*hEææUŸµ7€·d#öm0#TRcïÈ"ÉùíÆV¥{,'sÉGÁ
Õq9px#•V"çèwh®¨ ÈqW@,¡‰¿ßÓf™ûĞi:A‹Ğl6L4àbÙkv¦|vòß èáuRvÀ"ATÍG—¤ßQ¡}şŸBŸ¨±']heªÇ2×˜8vëÏÑ„U¥\:ÿ~yé­{ŠpæÑ‡ÜG¾¾OÜ‰u£ó}{ø¸ÒHpnsaÈúô¨5Œ1¢ñø¯æ&‡—˜Ù	RÏ›{	q!-o½È^Ş‹Šû„˜ü—­oĞg)îyuÛdµ»ÃÅ±£éáH±}ËF/qBY®òFg®ßæ€Zn¢`Æ±´Ñ—K(äïn
àw»£·Š«äøï)².“´kéÍÛ€6röYL™«nb˜çêf©S­²u±\9&ú€ó³ÑPóû–,*‡÷´·$ÔGLÁG±²_ç=ÔºPÖ¤UôhV¤(îÎ4ËÈ’)u2sNJÙ)ÙQ·Ÿ©°“ü†©ÃÑ¸)”[´(äFX2ZÅ¨½ìk©>_¢Nh1úì7Á Á´‹½§Á¹µçuÑp%PQ§ñx¼“áÛñrõaîyÕãö{b‚î¡ïØïWÔëË^Ğ1ZıÚ:™xÆgÊŞ{Ï'Kş¶¼¯s¢Î
.¸5ˆ¥·…°…h	™©dpRìBœ6ãåİ*ù< ûwí>D~ÑùÖ8ƒÛœS\˜>‚ŒÍ JbåÿÊqD|ê—*ğ¼Ë«tUœoØX²ú·3ø¤éıP¥˜YÑØşÜ!áCSº;Ë
ªíUŸiˆ¦wO^èD÷È¼:©‚_*sQ­ˆ‹u¼µ$d|nE6eçCÇÇ#“ƒO.0TrV\ÑĞ ìcÁş•Ç%@=_l×u¶Ü…}‡Y%ÏÑbÍà›kÎÑ‡:LO?vƒÙŠåx^Q‘%ŠÜ][GÔË;¦ìĞ3”Ù·qf«š»6ú%g!ytX”¤QK#gêKz*aİ;[=bÇ“äIoÂÊ8šóÅ0ŸÑ´0Ì'àølî½­í‚ùêW­¥:Ã9îü%‚G
w¿"z;>;09>ñÅŒ¨]­"øNß/ÒUû"ş_û¥j	Àk
Ü×A$Q‘Ò<ŸŸòÊÖH^õàÁò J¶§™–îù Â”*l
\wy»®æª™Ì²>åKBh‹d„‹î°İ¡q1Ô=Å¢jˆ+˜¨­‡™eİ|‰!¤ø29ŸÜw¢JµÜpn%È£>i:—}{‡KD OÊâğêi:Õş„¬´ÒêóBÃHØíàø‹ä´mZq%3ó!7vÇ–8U8|¸ECğl=İı`Äûi¦Fj&B A^­
Şß-y\ÕÀÃÛ‡o\K	ˆ‚E¶k´1Odã°•=QU|Ğòp¨y
÷U/|‡Ïg¯\4ß…‚:ï§\w5Eú¥®“O[€ë¥-–Oš‘_TÎÊÕbğ&Ä«g¦¦JØMBiÁ	yó6e)Õ¸ÎíòÒ~/çô±Ÿ2Ü^%ƒÄD§mLØı—µlìåcš6V,&¡¸ã¿í6™#gšÉİ9û@÷;d‰
ÊPÓwå%—v–»ëêJd~
e£Vú‰ÃéÁ.‰	JøÜ9:À¹¿|=d>Ÿ"ZÙc÷ÊŸıŒ³²ßV(Ö5$ >d‚ÿ¹Î{Î±QÃtNJ©È.ø³Ï¦mÊ„‹ 2à&4¶ù«’OŠnM4FA@1K{„õï¼¢±®h68™pP±¹_²2¦ÌYaŸëˆVO5YìåÊ¿Ó‘ÂL+Ü#ü/PÏb…éLò±±¢g\P¹$ÿïP©>!¬~$]lÍ~)ÒV0ÿIfPHÒëòdë?5…ˆDÃ{6åƒ@êNógoßr0ó ÷>eÔzdá@PCDrg„7¹†ög™İãŞÂJÿp4ê“Ú0‡
ñ¶¿ ;W)¯¯'IS¿rT@ĞŸ=º£xÃ¢)Ñÿk<Ÿ
K’Ú­¿!HJQÔsBşCe)€äÃi¶*ÄiÃ"©·æyÇy(LÌØø§ü>0áÆßš-„-¤}H×üÏ):……v\‰àu+İÂ¥gbn°|ğ8;;•õî']Ë# `>^¯{ª«Z¼)«3›«µõ’¼[€EËB)õ«)y
¬÷ø)•è¤(±·éS¼0/Ø|{„Äù´eƒ†gØïÒàMêsHJ§‹¯^*ÔÒ ÊHázÉ…à×N¦£Úré¡ªğqnÙÊm³)[Ë»È“œ‹ÍJ­á£šİ>UI%kaEÖe‘[–+Ò>ãQo¥ k…×´ç^@¢fE­Æò…šèXïÌ]ÌŞğÀİhÅ—¥JÜX]S£Vµ¨ıØ´Gvë¾Gc…ÛD­ğ”@“ÂÀ]„ÏŸÿà£è ¨”óíI˜ñ“ãßû7øu!ÌÒu(÷Bõb'ÊÏUŞ±Ü`DFoÉët3N¸Sn¬-	œ†hwŠX»¥"‚‘7+Ğ½\ß'rƒ…ºÚîÌ %ì~Ï01J×úŠóœÑ8àßò†0–g&=wä&Ùø²•KÃø´¡Årv©wˆ Eï´2GKÒ|	};¦»2…AüØÆˆ’SázºRá%~#\œ›Ò®3NàÌ·¤ªYc]
ßÍœt_”8beƒ8tÒıÑÛy
´KivÑ@G§´M½ÔøŠyPæyJÎ®şX¶°Ea³YåÖ{¦ùPŸèúøñ­H­³«…{`/ŞÜ|$ŸÔpê%‚úş¨K~0À°p/âÒGhRÔÈ/y›¿õ<hk‰³™šzĞÈSSQ<sŠæ9abgÉãÙÃê§I‰ómS–ÇÆ$/=$7Ÿì²ÅTÊ°Ÿıè2×ÎşKû¹ÔD<&±¤„Cí@ıñnOZéAùµzÖØ¯#0 ÚD¬nŠÁ|Z=ºÄcK¤Ğboò²pÀGŞ|”4°·ı¥Üš–^¨5BÃÖ]Yæ+İOå‰¿ñæszÔò7W5àŸ
úçÇ\s’€£5j½{÷ŒÔ$~U§j‚{šç¿[¬>‰EËÕcXèútDB{êAxSƒs\¾g
V˜Æ]¾lÕèE_1:%dÏLtüLÇ³Æo'å–ÉÎ¼æ0iÓ&„k-øùûÎëkŠİä¡¯
‡ñ_
»è‹šì¡B/cğWm8è_ë¥¦á\^k‰İâú®W{µRGQ…ôêîÌà»@W.iy¡gÒ-Ğ”‰úÀ¢i7F¡Ş&ëœıŠWCıê¥á+‚§3ı°£à†Kİr,xöô”Ït®ºĞX•-£d®oå 'Mğ—o‡;]‹
)Í²$ŸÂ§&ÙĞE*Â÷Ugçîìz¥³Ÿ}®,}§¦@kgõä•½(}P¨—¢òFÙjLæEE&+–ô#_”åŒQß½]q‚hæ˜^×MµÛ¸˜œºÚ«µÒáÚÍ¿T¥c÷/A'`ÒãK b›óÖ‹Àr[‰]5C y‚/™íµô½A²^ëcM§uİ÷B»¥³Š5³êBî¦<b€M$ÖH2Bıâ5EQs.ğ“ú4Ì5PO|ó0òè±çeF±U,pÃÏ=Â4í„“Á9ª‰f„!b¹Ûr_ÕÛÎ<Ñüúïİ¹5E¶Rÿı–ú"@ Ïg‹ß&Ê´ w2,	ˆ*¢ÎaIb”5Ã*‡ŒĞÒ¤Ÿñ¯Œ‘[ji9Š“\-ËÖd$¥Í' M¢ à
°=éwÕnº°ñ5R DÜJ™á´ÈöæNwŠ²ê1©Qş3ğ_y[xò~ÊÃÑ¿´ıŞÌ…éÜ•¢¶#ÿzEÉ‹‰ < ³ö'}é
PnşîÇLtRƒùÑÅ«÷jø½Ëyû×Å×}!ª-¼zb—ñ˜ ¶=íg~]‘à?0#¦ií@S¸)(³Ä‡È¯"u#Ù®ÍFâ©jN¥Wdà_EÛ=İë}OpÂG{kjĞŞ£¥ğÅÊ©v:÷üKÂÁO YÏZ}—¯CkmNÖO	»ÍL"¶³¨iÀo1£`ë f!l Az'?ŒÄl®²ŸÜ¿xvÏ4xNqÃ£0hÓŸ?SáÖ&jß©¼)²ùíÃCí³k1±‡HÔ£ÔhV®lÀØmt» öàªù=i©NÇÔ4>O«(µhZÄXO.Xç4Oä"ª1™²Scú«û´ƒÚBÃ;&ÔU³m 6ñâåcFlÑÔšÚû½qïõMÓÕh ¥‚Ò£Şß2pÅ9|óLÈ:U¤–”ğ˜ØÌ¤PG@
%@-ğÉ7l
’Ÿh4Â¿ÿÎˆEn œ\Ò8Ó%dÌ™°†Í-(#B#ÔroÂ™DRşaåìö…pDµ[MÀGø¬[¹7H:egLV˜½¦&µ büÊ\Ow™o	fYxá›Qlšc«İYû|¿£o>ˆÄŸpÒşŸ`CŒµ‰)ijep®v}lzè€h²?“ÄÜMät‚Dø±M ±Ü¦—¸ß×ÕŞhKAµA¹G!z®èDÓRÛ"ïË­ç¨èöĞ3ÚPüÛå<õ¬ª©N4†d­eûÁ>Šı>4vİ0¦áKõovhcgï«bXCÔb­y»kÓ·´Aw£k¤<?rÿÌD%æ„q‘°vƒÌÆ³…«õ}¦÷e³XSƒé;S“…”eÀ½odQµ€ÊpY«z›[øœ¨¯ş2<c")nÃsãZÛV­17ˆ¾×~ó\ãZºŠs·>U¹gP‰¡Ü&¥©” –£‚aŞ—ç.¹Pv²# ˜[ğ–Yü8”‚Ş1˜Æš™ŸiËF´åEAeéÇà^CFŸN€÷v¦ŸB­R·}pÜ­/Wã—ºÂÕKÛ‡ò¦.? ×(Ä&¥M:0D·ãeÃù5;õWÅ(×6ªÈ&_ÀŸŞš]çŒî ÏFUø§(?5ñ…Xš×¡¶´íÑ™gmÁFSÏmgßü‡-ÂŠm”}dŸ7òŸrZÙÔò˜L+ó°+pY|MaJÊA‹0)5ïŸ/øø¤l¯CCt¬Ígn«Qiı{ÏNUôÀEåJ×m ~«Ä,v»)+ÍAóàSÁ¹n§À saÊ|“ıš% ‹~üjÄ©+öñŸó)òDXŸö“Ê 8ƒ‚ºÿ‰ÏSWUS†¸inßJkl
ÃŠŸâ<òG#¢ö^G<q;%“,Ré«m<wu„©_ BáI‘ˆñX4Ùò \V`ö\Õèİ¿öæ=m²ÍÔéÑ±T€]ğ?ÕsP_éIvƒRAç[¯áÀpÊ~±³¿õ”…ñ€<£Ã7¶¢(¶G±ÏÍ¬2S¥zÅÍc&Î}›”)Cú¸¼à`Á¾¹/•‚«8×8Rê¦!ryµG~¬ŠEt2Äy_(%ş€ÀQZy%Yì¹bšòæÅ³×dã'çïÅ¾ÆÍˆ˜„füCS¬LjıŒÄÍ«ˆ"OK¬ğ=	%™ü\nDÔšfÕ·@\§B¨u4SJfÍDJĞl¼h’pH|ÏÌ¼ôz e“üBî¢ùeš°Ô×@×½ƒ™rÜWw)¢TB´Šíñ¶Dû@Â‡ÍÁ¦ñ }O˜Ë›6K_&&†×¥½ H&{»KÓuïÓÃµ¤‹Œ§È³VÇ‚Îc‘ÊíÖ¬°ÕÜÁp³¶Oä/W½ÛnNœß€´²¹sô_7åe^qíç´6îl›5€EİFãÏ+Vé°|e’hÈKéî“˜˜ËFUáùwš*™®òSÕİ°Ç¿4G®ûP@½¯çıyì“$üìk†O·G‡¶¿R'>ÇÅ5~îgc,¢yÂAZyiâÔ“0¼®txælŒ <Q«ŠtUxxe¥LboÌ½<*…ÒY©˜ú&¥_Ò }ºqæ†õÛõ:ÛrW’Áº}x-Siâ+ß²QõÉŸ’œ3ß·Øîz4÷DN×ò¢H~=WMg¤.c¬‰*
h!œõ[!=ßÏv¢¾kó(Ÿ²¿ùRÎ©²Ñó2¶Ş™§ÊÊaÓót6]ºÂ=ADV‡Ô©q_¨T3@ŞökÌƒ»Î™‚b¼=:C^'UŞŠÈª$ƒ×k!^„A-\ ‡O=­}uetå‡)MéÏËÆØ¼!üMË&öˆl¨‹¿Vk#ù.ÍùµûŠ8Ë€o0‹~SßÄ‚Àjo—R„xg3æU‰Îãš¹Õ»l‹ mK^e#)ûT¥Û!åZ”×“g‘ìz5|ÉvwqĞ±7L ¹/¤‡EÁ”ÂÑ:ZÍî	EiJuÕS®YîÔ•WóÒM3¤cÖ¦).²²npŸaùaIYxdÃĞÊp(¿ñvÑPeº—$ë ¬Ú¨‘V&„eETG6À|%-ñ(ûŠÄÍÊ)`lIŞqoÄÈÆw!H¸zRÜpæ5f„™fÍïİ¾Îˆ¢c œ­ÚCÓ:à!†Í2fiQSŠÒ´Ù{‰%§ûŒŞx2â©¶$€vÙn¡o	¸ÃW¶#^
§]Uº1m§şÄx…ºÅÎo(–dF$Ãu—)‹†Ê`Ê_/ûã’ùÁüD³íè¥ÑÁÇÉQóNã¶(F¾³¥ £¾’•Î¿Ğ)Ç!'GcïÚš,Ó<@ò‰›ÜU¦øAÌİl‚†@yÕ>iÕìé\6ßDg¦2ì—eRÜUûhŒCŸà§³r¸omSúFÀ°»šîÓû¬…Ù…+piI†}ÿiy<3Yœı@±›Ê±šè€¦+ÂÒw"¦QjŒ.k7ñ¢L¯¾	(Tşx©úKts¹u½
~ñ‘‹¨;æÁ'‰
…?½5–¨«U¦u ,Sö.?Ÿ‚ƒÛS×™3k	‚‰H°æ{íÚOYÇ÷t-ÊCÛ†çtf\,mÕA…ÅÍIÑ~SğáÚÈ}È7ƒÕÕ(şMI£öı£‘~3”w}º(Ì:U<œñTv	k¯hî>Æqû9S^Ú^„|›yÇ RäI
	Ô§Eœ¡ñ}K(å‘şÎKô¯Ìç‡;’4ıÅÓ§²Òˆ"–{G(Ã.JO•¾½böc´¯‘à¨œ3|d-k9 C$vOL¥lWzº“­$¾ø1ÖNŞ·Õ.ø^äãüéÎ¼eQ2zŸP½+É`ÙMZW»£&ªpàËõâÔª-@HH2¦²»RJíåb'çf)MË‡•[\ÈÒÙ>ÀÕ"Î3•£A½¾Û×™s\m'Ü…¿KÃfWYÜ}wFÈÆ™PlF¡%<‚ÛÏ‡¢ãôé9õsâ-	e–1›[¢…—!}<°ë·#BæcÁ¾T0'£ÛaqA#6¤«Ü"*œaLJLÚ è“Ô|ñV
i…¢~\¼Ã£^åŠUì™{°÷ÖéAÇş—Í†-ÆÀ¸uŠÕª
‡$OÕÁdÛÆoæŞÑÉÕå¢P¶}7É¨­NàIw÷€)º2û:Û?SÔnbù~ñô*¾ºY¶ƒ’ş55‚aÊù©!/U‘¶²¾Z+ÿ^ÉÁ°«qw–®´ƒõvöĞ¤t@Ë•”ª¹Ì{{T½‰P[Q´{İˆA±zÓ¤Ç°j`Îg¶B°‰²ç¬½¼ÊâcÏÉ:?;òX©¦»(v †û0şÓº+g¶JÊäÎ—§_ùñ¡ÀÎ5Ù=NËÄ×¬'&©É³W]—ß^v{ñ²/ãÂ€oŒ$š¢–6H©©}uğ+ádŞá¿ƒÅĞ€£5©RœŞvÁßêÂò‡¢Â+¾â`Èöâş³¿?r”­Ø‹ÄS¦ùÆr`LC^‡8V]N RÚö}šáËZ+lç¿ê9Ó’Ş%ˆ’¯m™Â[@gäæKHÀúúÿÌ>Ê;èRŸkÑ=€[.L•ô‘ìÀì‹"ğûÊËÊ_^á“)b^Îvˆ:ğÑÇÔÈßĞ#°ıdÑÚäZºÍ9ªÒ«¼xjÜ =²Z‘û
Ú vöáCÌñS¹R)Ÿ÷t¼£.)FÿˆKÇgË„Åop<%ÌîV„a)‰bù„A@á|Nß^pu-†¥Ût‰€¼ö5+yöeÌ­‘­—Åè‡RT¬ç>+_ª¿Òå¡yU'ÂÊ&]©Ëÿ"…ò`óp¨©5ƒ>ƒËÿk±NÈj3Ì|½^Óäô»×²¥ØĞê6°]"¬êcÚpáÅl­ñQ¶:[Şn½¶0~ù±nÔ‰ø›€Gtwg5} æ—³)Ğ”!íó”‹Z¡w4äYŸ ZÛçÄ<–ı,cÂ[¥¡”xFrÃ:BÜc>óO5IØP‰¼´™TƒÚ¢É^(SEÎ‚¤İ°7$g‰CéÑçĞ}Œâe5ehºD‹§’lš=Z¹r;¯„»•ƒñ¹d¶Uÿ®PÁy	s	ÉRF4«AÂ¦M¦ş–VLªp¥Xk4Sƒl¥’è«5{2å0_Ã˜iÛ9‘^çÃ.eÂ¡ë„åÆZüÒ¶ûÕ£ÑäW¸¨üÃHdÑ»jî”#ÿ#™©sV4I½ÒÓ<¦ÀøÂá3>íAe_ƒ:šÈ¨½J”Ùø<b’€#„lâ‰ÑÅ¬ğt™Ì ù7á(CR`J!NşâD"Rß ÿóÌPê‹2DŞ§›L>ãÑF ï§‹ğ*gİ¯±QÂÚçn¯€Ñ£±bİ`ñŸ[¹­"âçùL0çĞ–.#\9D?il˜JÜHÑ¶¶lÏS›Tç~>ĞÜvÇŞ%øˆJŸ³^V¨†àW`å´ey{àA/öE§Ê½MµYÀnD?¹ÕŒÛÀCİOAêX1BÂØyœ9†ÿ˜ »€Éä¹êµAØóöMƒB¡¯òEciĞ2ñ– 6¿[·ÒÕfÅkG Ig­uãjø	¼CºcR<ÛÇ›ö}!6›sÇ	O‰®š~s¥‹Šß¢J¨AG‹V0ìæ{ Õ¯ğZÃ@ÜüK+wÖĞè7Z’İ>â>eP¥q%Şb;·[°—Æü·d§çÔ¡ëÿå_ÅïëıziêEçê•{ùÚvmâÑq¯D¼ŒñIEÎç$q´`p-«ïëòÛ8æVBWTòEcïÅxò¡­EÌu…‹ÕvS>Å¯ÄÓäÙÔI3}ŒÙ[®E–Êd¡X3Òö~èdæ[ì^¹vÔf2e®{rBö´öƒUù•¸|H\ƒg‰ËbtB:ãCÑb£Mwé&3;ûPZÃÛ‘¶`Í]²¿9~mH‡ÂµŸ*˜ÎÂÑğ5~³ˆôÚÏ’ˆ)	ùnŞğ[–Ù~ıÍÓ!4‡ñoé“3ßGdzÓI‹…OqÎ‘Šù…lLO&Å$¡€Q£‚*×Ø)ff¯y½LàlHú¤uËZ„4Ğ”½şCè}ˆ.©”aà£BF"î*òVj\Ìrğ8¯ U%ÔÌ Ñqª²	]q7ìNeFoñ[”úÊh’¿ù_HDğÒf-İ¦ ?äŞŸ˜ºİ–yt¤…u>n‚wN»LÊÂm¸cÇë#}e2zÃcøšõ¡‰dDô*[éÖè^™=§è»¼üˆ#5îÓ9s³XX?Q…³SßŒ*`XR¢gb$ë-9oÏ_B9géğrKŒ¿~€rC³À"rò=ÄrQÇxQó	d m1q£ˆµÂ!@`Î—èNC•—,ÕEÆOô¦ÊQEëÀsÌ<|åÿ¡S{D­Á†_æuòPüLÜh<ÒtJı4`‘\ºØ’ aÑ¹*¯ÏW÷İ¯–õÙ?$ƒÛ9à©«$—Ëï¨e>aëN Æ/µ;?EtÀúGÚ û­à$Zü<?<6ƒt˜tÄµVYïh„:™÷K9â
â]ÎV— +#»¼¸¬£Aåı	y|Ò«Pÿ4¾C	­s’]I‘˜½*ÀŸÇI¢Ó²óğàyÙ«_åÀ‘–
>ÿÔÏê~8îj¼~²Lo[ÅY×Ú<í-œ—7N¦EQ‘Ø’ùOÔZYB!iç ¨q@KfgB™	£;UDÇFµRuü³¬áQwV+C&­ùvkdŒÁ“ÂÆu¨¿å/=êÒñéË+hFù:[:0]8÷‚Œ¡È=P’¸=½e$2U’vÀ~L1†ê'Ú9"Ô|JÆ¯Ó¹ùwC ‚<ÎĞ.ãß¤­vé@œ9ˆŠi¬‰¶EDÛ´×ÅïÆéîĞßA$²UÜ4´ZÑµ¤¾ebš×€ âú_ôKTFş	Ã%Ø½<YK ¬õÉXï8¶8w³37"Ñæ}¤ó˜Gg?ºw#!ÒÒóÇ•EY(Õ—ì‹9D28Q@dÅG‰£4üW-× w,ıkjÑ/™Òáò/hú"U¨¯vÙßõàF|e#¥–YS‚õÎ Gü~fÌ‘:çoY-ÙJ{ÌS;¶­-ñg$-y‡»’êÓòE’ÙHü«ìo1Øäéí~|¥|Şì)[•I±ÛÖ•7‹²qõÙN¨³/²WàˆöAšØ¯£Jôâ?ÍY|Ö>×Šf7Š¦º(#ò8ñÑ	å–»¯ züc5ŞÒ§và„·Y-k_üL¢Â ÚR¾’€ŞnÜÃÃÜğşìzÒ¢Â_€,bD¢Õ%ÉPCÂ…ã¯LE]D –¯Õt.‚È{èzÜkòÇÑİ6¬=ãXŠdrÙÍÂ½ukã®ˆ¹€É7úVX£¥‘4©	òpö_.œiOA&‘ƒ-#W¯È'[ŠÊùU)§ğ’#ÂfbÄ¯0Ä/^ûj¯ŞÇ†Î=Öru# x¢Ï[õ9wºqujÂæZÅÔäúV^¨m˜!8H‡
¬IÎ!ÎÆÕ-‹ƒ%…Kšı’RDv‰=L>K3a0,	o-fYMRw­D3°E‡x‘¥%m¨,éˆ05ÒAT`V+¦Ş/¾Å%)û6ÅLI©'´b?€”¨8t³½WV'I€åèş‹•lgíqÖÿMôs–•ÙñI¦²æœêÛåE^¤k*.Õ‘“«`rè)y‚NTŞÁeS`şÂ†&weWg~_ÊØÑ¡»š•¥OœÃ‹™c ¡×ÅÛÀ8+bÇc ‰–Oü•Â¢ÿ=âşJ5Ê>–­MyÈğö^ˆÁ{êhÖôrã)²:¦¾N%ødMx²6g7	<Î\Ï]B“Õe5²_4µ¡ü8™¥»ï†f+öÙ%rKª0»µEŞ¥À¬¹åğõéÜ£:%æcÓ¡ˆmà­féµôµ>ŸÉ/bf7-“ßäÓ§„˜ŞyøG‘¢°o ^mAøğA}x·—p)ÆÛ+,£4=à|oáf5ş‡Y'-òÎ{ËQnƒNšØaAa†¢Ó`‡1²nk7‡ŸÑTŠJ‚ÃSjl(_=ç\¿ª'Xdc%,ÂnN‡O/{ˆ3xƒ"tî¥)W ¤]&ÃJé‘;¶{ÙGrd¨>êL•ÔÛÇ sÈ=”ˆ±DŠ
ôûeŞHÈ’,ùĞE°ß?ã+tÏ_Vz¥˜â›õpP’‘vAR,­bjzl-fŞgG(NæØéà"ŸE«-öH1éGå#	@>q    >!¸ÅRuK £¡€ ‚dw±Ägû    YZ