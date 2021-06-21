#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2417919484"
MD5="3efc8ac2be276f7ab890ab2446f300ea"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22940"
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
	echo Date of packaging: Sun Jun 20 22:41:54 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYY] ¼}•À1Dd]‡Á›PætİDñrüîMØë0ŠêC› ÊX„¤äFˆ-w¤â@8êTZIé&ã[ygìÂª:ÃàŠ:+vFÑ`»ß½åù†j¥ãœµI;¼Û,f‘‚3ŠáP¹RÄ&ÂHü·÷Rø³y	Å¿LÒïL¦5P:°ªácîŒİ<i’ØW½CH÷o~ı÷ŒQr@·´àÍÇLJVé>…D¦¿isÒâ<,kâë˜ Àû„j¤Wqù,ùÙÑaoŠİ!Îşö|,Oã‹V°\‘õêÕÍCxª'á¯œ¢ÏŸ¨	: ^İ_YÇ‚Clµöø®O Vá€Äÿ¶ë‹øÂ‰$¤ğŠ!X¾×›Zõ¾1ö[kE5óƒXèÅ+¸‰["3®2<•1±Ôq›2f™ ³ÏÖÃœü@!¬eí\u4_&QdúENÊşå‚%}ÃØ{`’s‘áù88Û²•Œ°ë+E¼LäÈsq Æ4âs š}"+vó¬Ã²©ö"Ö1"K9ŞY¼±ì]9íSPm)7BR}{jË¬fË—šï&–vã"XìÆu»N¡äËºŒ™°›|!W³C'‹C+˜tæåîöå^ôú	OŠ•Ö]|pZå;ö”SyQ$!\ıÖÑa°´-©Oc,}KN¤‡å®
wêJç¤VËZ%CÔŒ¢]ÊçäÅK˜ôæ&„M‰]W+tÉ·Êœˆ†ƒHğ¾@ÒÃs:WVNBñü”ıø¿˜5èù=Wa¤:wï²ìPğÊÅyy”N°"ÁM‡½€ù@öƒü6xp€äDÔrOR™€à¶wf#*Å;»<¡K&$³ÿ‡Fí˜|+ §ÿR…\±?¼ÀÏÅMOä±óÊq‰!¼ÑYõ¨ bwY9|ğr ´›`è¬±†À­÷¶eºAğŞ(¯É.ó²º#yÕ®ë·XJg0¯Sº‡öœ¯–oç $ƒÆ¬ü3n,·ªj—ø7ª‡%ØÈ²[nmØ³²¤¥l–¬S‚ù•qì<yí¥  Ø+ê4B¯s1ª²ìÛ°‡…É¿—YI8îO¤JyQ½í2Êæ7ÆçhP“Œ“{«Fü‰ÛFô+ÒÒ¨Îje¸×_2È†×iĞBÙ·¾¨€”;wèrıB}(M³T¨Óñ¾Q8yÁ$–öJt1ÉÖÄŒgş:¹ÿ{­ »ã¯=Š£pÂìFeÁ3SÔ¦ivÄ… 'oÛşOÁ6Û0G+Á˜vğ¬5ŞŸ—ML=×Êq6ë"ùL${œê-è#ãıËEİ<!êøVqhË¹‚u—É÷ÌpÑ2:CYî”-ê‡HA@İ¤ —8ä‡µ°šÔP`s¯wú.ä\Iç‚¾ì8¾èéfÎ';ï%à;&Ô„õ¬˜vX5î.é–ØEcäŠ€¾¨+†ÛŸk.óğË¤5]Àz  “8BŞ±ÍÉ÷¥£áÙ¸œb‚'—/Ì#IÜ¿Îó.etƒ×…6Ó$OrnÙ»Et2i=+9-‹³Ó ‹¥Ü±ÈBÑµ#'©šïs„H*Ã]òØ¯¡İ”œ«ÿgk¼˜Ø€ntß;¬¢‘Tjó¾TïÎH«º6–™?„£kº}A/Ã^9·™'§±}‡5a+LAÜÍ}’ÉñÕ¦p¬<fÆÖeVIL‚¡ø3«'sN½Šö†L¼3ó ³±]óñ£-H¼Ä}ÈÊü$1ÜkË0ãC\€J¢ yää$ïkœ„Â*ª†[uÙ«D/Ñ7VÎª
y¬­ö$ŸËùäV^\0D˜ƒH ÉgÙÅà4,À÷€ŒR@4ŸÉt‰ï&h‚(V‹\fáUA}KÀ÷z•Á–ëÕ¸FÊÑ8&–¤r±õ&Š¹°=Ç»9f#ô\ßÇ[”ôÈ „‹Üj÷İS¸>@÷yWJ^KÂ¤/ĞXCÆy²ïÆƒõYß> ’``õ“íUYİà ‡çÇæµ	!ûY"oğYªù—UÂ¯ÿÏĞå¢õùyeV>¡{¬]·eŞóN´•â¤&Ïæè’ã•>hÕÕ€Dô3“Ô'À¼ê©dO’Ã“E­]\ îWƒ=úåv-BU‡Zu’$ êºj„å3pn7ºyNÑ¼†ö·›< e*BŒæ¦?HUİJ ?ËÒM7Õg!uÇÈş±ôÈÑ‹«-™:ÆACyŒ+´xWÄU˜–_\ Å%@/š…PpÍEüÙ>”ÅÌÛâ‚oŸI>’ºÎ\B­î÷7æôÖkI=rû‘³æ~uÅ¨…Ò­uø!Ş–g¾egñ÷®<—8örâ¨ıi(˜×¼A¹œ zÃ@Dc*ĞaÖ‡"îèòB‰ ^ùÖ%‘à¶^Œéæ ûJôo,ĞÔ3S}WP!#$UÔÿĞ6¿ÿüÛ¬<mØdf #ü!¶¶BaõDÁúcBf{W`r’êÜøˆŠÜıËïÀôrNV@¯µfÇ\¯PlƒS’5*6r
#ğ¨mw»/æ9|·¥ÜİRšÎb p[Al¤S¬±j±@]eY—E?`eg³e’øûS´ÉpõÊjN÷öı5Ÿ¦o”ÁÅ¹rá¸W,MªY;‹Â»c[J.9tSÎà³5)7|'ßecµZ|ÚÍz;ÂlİÂDŸw‘Ñ„á¢Â¯¶-c!›µ	Ñ€l3‡ıâz±;•¿ÆRİnPÄÊ©	Šõcq§Ö	¯CZ o?ÖhÖrş„ÚNâÈm±HÁå5¿ÂŞ^2lºQ¥M€]×¾ëaâJÀæ–d\°ı¿„Ç"ÑGyÁÚô¼c3$.pmJ5¨3‰+M=ò	
;¡[jgÜ¥@¼yô5 z'káé‚¤Vû_%>6$L—ØXä œ›­˜&ÆmÔ{ ù‚[lÎæ	±Ò ş-4=í¯úÆµIxQ”Â-¹­0IœíRÿ£´¸Ö€Q ^¼äŸ&Gä·jÎÙü¬#,“CNeö‡İx¦\ÍÉ
Ÿ¾ÅÆ¨Øl”±œÅ<uÖ¹VP½«¾"(Û¾ùïóë¹ÎùˆœµsŞ±ëqd²VXË‘|Ë6=qGõ!£å¨(Í ÉQ¡ÏõÚ•¥m>êèÜo#ašÔ1º:N Øşd^áÙ˜2?R'n<Äß5şÛn:&‰|Ø<M9XiÛô:4 aÅtŸ;JÌ’Ä§/Ó65ç½ÓÑ*æj[~t}ƒƒşlè~æ°&µAf³*©õò89£¥ßƒİa`B™‚èUuh@‘ò;şÈ£ğ†¥ç+r;6w^—ãRP*ş½›Ô,ªWo½]Ç*çàûŞ ³
lĞê C}‚E-Ïq¤K&{š°Y¹+¦îè´Uo³¤ÔúkM¥n5:£@‹bü“[Í<4jÍíSÜ8ä©†Or³êiÇ`rÜRk;ø¹é$_çøsIúsÜl7s8Aàqt.JAgO1–ö^ÅøPPM¤IşùO©QåCÌ[¬ÂĞó\Hß“Îœ«VY#¼0ù(Û—{õ{Rú*-´0Ñµj=ÿ5@<sqµà§B—«ÔK_îoıdü|5”¯åëŸ©.Ñy`ê0æ˜cn1jçØìª—u;ÇŠı¦â¦3#¬á¹¶WËß—şŸT£IJD&®;Şä•KÖ B:ˆmq¡×rR^9·mk^ÿBu„…Pt•Üá"¡D]S±_ªP)%ãZº)_±€û nÚÀ“WfúÓ‡Ô+Å’ ‰'Á¶ÄˆÉíÏ¸ÒÖ4gi(üş	¥†>9â¹²“XÓáì—0:‡¼6sÕãDå@ÅJ™Ø^"‹8äÛO/ù©ó¤êp\pÁ½€e¶ÏÅl¤C´l‹Ç.(Y«7Å4tYí©ÆÁ;ÄŞóvú.#EˆæÅiúŠPØn|QLd²åØLD®¦ÒæîxN å]™¹?ÖSšùÁe"Hº¹Š½.œõNŸºN­³HpˆëwÆŸ\©¦^¸O~0qƒòj‡v\òw£ÿÁs¾ŒVªŸ9Sbµ
?+Aö˜´nìµ™B‘zHWÖÉÃÍägçÏPa^ólzÈo)•HG$»¢I,î~m@wyPµyÁMo¸&ÚGŞp;¾‹´ã/ìë¥cş¡Õ>B^›Ï(ÔªÍ´hÌš®TñYœ3´>_(&-í! |NY«$Òxbò, ïØ›‰µÅõV`jƒt.nøÓø*¦yí`¡ûÕä Y°…ÁpBpÑùìùå'o¤Zaä—ÜH~4Üó†VM‚6§¥Ö=[nÙW(±£x|b)Ü®sçĞ¨ÄßL»‘3¥Pƒƒ¿D+—ƒÄ”ğH<ø/Üd‡¯,È«;nª¥ø"‚WfhQ¸¥ÁÉrà­¡”·ä\sµ"ßxÍ+NÓdŸÉFéQˆ=çä±Â~ö8”îêä™'î4=å/À‘·¸$ø!zõ}´üŞ±æ0fQ—ªx¨–J@1Ñ³ˆj¹±y÷Z³\k;Ï+fô“‰ÀQ¼îĞÕ>ù)¯cBGãÏ±ªsËj™Ù6LC¾ªÈšAå»ù¯÷Ho©}4ĞÚ6—XêAx0ØL¦¹é¡e’A¹¼ëÕÜqî%{`_¢0üMëÜòKíei5X~Û=Y‚‹•–ÕnìÜDt××üœ½ïWÃ·êÃ¤¨Ìq…0>«¸*$Š¹VÈûŞGg³®*©…‰ºJ­cb¯íóc:¢-DS‹?…YFkË¯h±{HöBa Òy˜¢†*h®iéA|,­i>«œkNn†Å-kÒÃ6çrÜ8ìæ<9™x£¸ÙOæ—¥õ‡4d6Îš7¦·iLo¶¸SùÛÓQ¥G>ƒGªxwö3ìŸ˜­!$w+:?²!Tğãııõßi¿êNpôøÄ—èQx€g~-3ÊßX…³³É_yaŞÏÛ®ÓıƒÕ_¡ıÂ¼PÈŠØU6:•{ü¿´i;	Ôı pj{—XªƒoS0“ŞrË§¼BpÌP¾È©¿-m²'ü'‘]e¢>}ûZ…4:Rèk ÈY¦	UÀS~·Š¿ê-Í?*½XtÅ)gB‰ºéİĞNu‹ÎWgjĞ©é4|[““$ÔµQøªô›eX’¹n†kF˜WĞ3˜Å¸èĞ°fâ•tˆø2Ş$M<4ufÏj‚d	ñ¸ÊZÔÕrú+Ÿ/†ª&aËŠàûGË¿²ÂeÁá^ë|,â…Ú…*ÅS¥GÎ«Q4å4fõÒ=÷\RàJL=T¶6‘Û±Wå9ec‹B8†ñƒ[•ÙÏ¾Wj0£qcğõqä¥Ç\ç•¬é‡–uãàƒ×a’8
ÉVB<\÷^ø›ÓúÂ›dçÓT±x4*:GØ_øê`–™HÙcÖ[ÀøÍå[äş¬œÃ9( +¯†Q\ˆ¢{*ƒü"è ÷¯†¿­¤<£®J×é1n­¨ IAé¹‰½œØZ£qäBKà·S~Ú5Ÿş‹Õß¾tõ¥½_«òÔAõã.±ÇÇD×ç¶¹ÜxÊÁ?‡T%]iJJ]O— ıæ™õ’rW~göKN9,¹L¾LnJ:7·Q6-¡˜_¥é×¥¶«Šÿe;ja»è Ÿ{Qï2øw&K¾ßÔˆ>J(è#–•ş‹@$§ƒuVÙÓ3Èg\}É#ŠD¯¡À ×AT¤thƒñcOY—€×NÆré¡½4ƒ/3ÍvAqÙH°ÀCB¿ªgìdfI…ÒHCáşŠ”7Sfº“9¤”:Fƒn}òƒÉxşH ç¡ÊSÑ¥¦†p‡H:S2ËïÚ‘–¦â¼Vó2ş<a³¶_c
¿eÉšÀ¼Ö\ıÔ:æ>(g_-P|W4€\…2FëızÌe]W¼	Kn	K§ca§á¥dgD¡á7£ŸÙñ¯ê¹|ÎDŒ{¢$‘wsÏïw®›_	HäAıœ=G¡ªK›å¶Ş¹(øA¨¦ØªÖBŒUTâúŞè¨¬m†áùÔˆwît§ŞHÑ¡?}ªØÕ+<¬¬ä“ıò/ƒ’‰1ôí%iÁÎ§E&Nè[|`bpéÒ±AlÎğ>±ŸÂâ6Ä°¥twA>Õs]ïnåúåŒ*,Øí=]ŒÕÛ„°{ï‘ ‡Ö¢ÁõÇ]Æ ;¶aÑ=ŞÑ-N­øqÒ@]­ìEî[î|4±-yáöF†éÓ‹@À¦&¾’HmCü¢w#O&&]–ï®²K¶ÆêNòÆ{¦Lƒ’İ¦Âç7äùBö}aéqÔF«|\OlÆï•±Wø"ÿÚ‚S¶7÷Œ
0¼o¥ğ7ŸÆsšiSt;Xñyş´¾š_W¶‘7és^F*ŒÑ¯¨pJ!•»§L	ab"V°ÿÃø÷oz÷z¸ÀîiFÑ­j3¡qŠáüZõ¸
ß97@~,nAu0,1sß¦€zµò‚ìP°“İÁ{znˆ¤b&çPOƒ¦ƒĞHÏ`»¼×è´ª`HDHÍ5¬¸€ø¹ÓG~;
Òb¼4oÛÈV‹‡ö‡ŠÔÏ«¹Üb§múhÂ¿ìÿR³¥P8q	]¥çÿKªxj‰”7‚Û[ƒt4ÿí›ˆûš‹ù‘;«#ØÕº«W<ÓKĞçÈ8Ì3ÔÈ,¢xf:¤*lÙ†‹<ñ*Yí…åF-¾@ìòğ€{WæîûU–ö=Eø¾øtÉÜ4"§’k ğÉ,“ fCE!Õ¼ùtrh~«ÂmÃò
ItHWõë%Œ·ÚÄìŸŠş»¹Õ´*)R˜
¥|õoÑÀ‡³Uyå{]@`3¥/%š9ÊA~‘\K-¥Ú—UnPğI9ÿFíqñp½Ş…Ü>nîá[u«˜j¤fGá±E=šÏ­Í^ÄUUÚ‡øV×#ï'ù0ÙF[‹ıš±©øhey@vÄ×÷ÂÀŠf¨ÿ|¿õİc¸²~<[ª	ğ R’PbN…hƒD]Ä%Ğ#LWeÃ š¹u+í?%xƒäïE:Õv(?Ì#|—¨rx»ˆ7¥ ºœçYŞèå"è 0>ˆü…§Ûğš‘}g£°÷V=U<ay¤gä,'U=±q´ ôˆ@¬÷ù+8%@æñ­Ñ¤]Ù‘‚ßŸ:vh’úœ€¿¡ğ6¸yxL'"–×$¿8ğ~ğúˆâdÔÜKö:Û¯Z¥hÿ9ÁvT"1ªï`•×ŸsìtN0Ğ¹ë„Ä{Zù áö¡½’èz¿a¬$…3‡ş+Şw	ìÎ¸3`“‹‘‰Õ‘	=m
Xñ§~$eÈ¯vFÃ…‚Ôº	ŞMBúØ^±¯Í4¦«èŠlN“à—«=­…_wf)wVmÛAj‰®İVSß»@Á'8â÷#nñ@tal¥ş= Ã±N«™LêÙb]Ä"Ç{‡òĞàĞ@äÿŞËÈ—Œ7¡vcE–`TAy¯m­H+loºŸéöAé‹E4t½*±[us5jÜ <õÂÌòß#×±oÍ2F«
ÆQ0˜N«l~:`…g°Ë@˜¸­¤KP"}~!"N¸—T±\hï\ hh»%Òêp#®öç0©ê²şÖl¨¨zş5
x.üJw®‰Bw²|f;¨²dVY]²ÑoøLœL0Aé”ìãH6 J¯§GDÂh¥túæİa‡Šié!¤ò{ı †Ra…\+¸¥¡Åi3³ìÙåÀ5atÚ#«ùPŸÛƒÜØN­ëÒÉfµ.S{L^(¨9t'ò}l/Í Ùa¢Ù5[J6Â^C‰í^3—?ü¸E¼5O/—E…FıQÓfÀdÕôºê*!sbó´q+ ülD·H"Mn¦®AV†ò§‡¾K¡ú3áµ	ñZÍæ,,_ivF~Q(3Èºx€6d‡¶Qò5	ã®»áşŞ³-‚7ùÃïú§I5MŸLòèİ°É¥1Ä]0Š’5=íJßÙ*3 ÈÜz+8KAİcóLÄ†TâóÛ>–*S$ãprô_)ÎC üú•ğu´P°Ím|Ğul¤õ¡= ]¬¦{Q±Òîõ_ïÓ~ÆËÇT4·ÅV½_ıf/z³õÈÄMÈ=Àağ`iÉ¸ín}!ü"›x±0GØZöŸ*ÜcéB–!ë¤áĞrøÍP»FÃ‡Îò†ú CÖëÆÓW÷†ààÏÄŠ{9IĞî³i¾A ìE[S¢”l¶¾XèBÒ†Ô±ÿtëOgSôÙi“—¢
0%®”µ¬ŞQkh‹OTØ&ÕÏ¯ùáË)”.×¬™Jüyµs(oy J8Øqı¼–Ù!F¥›Ë¹|öJj'QteW6âúYàmÊù©,E,$AV wJ¾ªyâ…˜¡
-dë½é3[­6â~5dãD¤¡ĞöJØ.{bá°³`óÂA¼õ¯Ÿë
ÙÄ'ÒY¶M¨R·-.•Õş€VkÄ0ôE9ÃçqO±sûìÇ÷Âfk—”ãX[UË-N!”j¿en¸\T ›gàÇ	Èf¶QzQ–©¿ä®±Ãçs`ve)r“ñâæb‘D7i±xâ$£ƒfZåÏ£7Är&EQëDğ÷Ú!ÓˆWP 1ÀrĞm¼?]$÷âÎË´õàtş‡P9T¬:óGr=²ìQ¢NìÊ.PæËzLÀè;›«?–Ñj†gUG¥![p«Q±nëavj{.í^G#SïlL‡~±=n`:&cÛ¸JvI >R©^}Ec˜Ü­Îæm.·)#ÀgïübÕ}ÖÓ×yÃ±ÔÀ‹ÅÅ.GpA Í0·Åókbs6²Äo
ö¡~›İ <Æ|£O)™6–7¾ò|õè¤ê_n*äWô=”k º}œh[kt|´ÍFÿ~Gñ|ô¸VÚíkŒ5Ÿ1Y4ºÊ°ÁNú85jÎ>î{
?6u®uá×øä’26g_+u½zî‘I¥F>§Qÿˆ[9Ğû6üPf,»î“ñ9G»°ãËwñ‘>ziøìÉ£Ô-„\`ƒ \vôèBëúw|C%“¡Éq—Šñ¤²ô`©ƒ½®yHSªĞ/U^è»ádBål¨Q«4ú#ÌJR‹Ê­%&\EAÄ©à:œ.z]ä¢0R:ü&ÎÚØ‹9×/«À€aC*× Mûz
ØÌäÏ1\şÙ`ğË"$-"ØÑV9ğÔ@ªâ©A\9u‰lMyŸ_Ûµâd¾Û©ÃÜh?Dw‘•ïßÀ‹Û3XÂ¢à9.K,F˜mÂfğ¤{2á6„Òß„,ÎšÓÈŸ`«¿Àüé£¯î¨Xñ2Ô—+‡Å#-f:\4vÂ1¾º n¤¿FgÉ~1 òí˜ XÎv>###eïÚÓÒkß¾šÖ5Z¼Öñ[“Œ·áDè·I»W>q$®\>b°;£5@*MùïµFÎÂ¿éÅ…ÚÁÔüiÔ/2Sá06·üâî¯ÇMHè”…¼&"Å,E…ğçºÑY:4ûFŞ›Ğ¼ÛZB²ÈpKF/«?”5•)Hh‘5ú»İMh±@[@×V<ïÉv\Ô×1Ï“¥¸:mĞ"T-©ƒORÑÇBDìn}.`6.é¤Ãn^:]Û|…%D™C¾ÎıÛßºoêãPx“$fq!£“…å•„Í^vÂáåÜ™İ×DJĞ©6â–tíÔTËy¶Ô•F¨½ü„ó+/qEøñí À êu±²¯îßÒ¦~åe4r©fM.âø{©5êòSI¶ïMí2ˆn[)d£Ìmği`ªYbM“~VÕê‘¢DóÊiÔGá‘§{(rú|DU¨ğ×ô&4Uöõ‹õi{2º1h)›Çñ*¬ R¡rxQş˜DLÀ­ûˆôÖ½\¬ëƒõûfâ¿ôo Ü8ÊšB˜Í“Í™­ ã€[³Œb#§cÌ†…¦1)hhC#ánÃÆD¦bKoˆªîXmÂâÔæ$pçQ;3Ş‘iı«ù&`>.ˆlH‹bH~|‰[Õ‹úÌ¨ô‹!˜ª ¤ò±Èu-ŒÉ_×tPh÷Èí]¦,XöìÅ•1Ïã^HÑzç2ø+ê‡­(ÿˆî	K”ÅÕ‘…ÖpìÂß¹ãjÚ„€ûİv¤šcÔÛc(éŠSÊİ¢ÂĞ›$À`Ùîüd•ÑÖ¼
¤ã/±5úEõ>±s[‹±_pqâşF‹Ù¨ËÀé$¥¼©j¶ñ×uÇ2oF
=~-¨Š¿V²q3İšâG¬-ÅQ´LßZÕ×Í±¥$º,¸,;åúc2îSëµßÈ0°y¿ë‡Y˜iÊò[²G‹8'ôî(ûQ†ƒe}ïf€«Et÷CÕu…‰ü|ˆ8Çrºb„ä^ÎC×«öNº-¼`¢zğ±E.¿KÜÉ‘µf„¿‡K§!CärÚ|D2!Ó—{ SÊ©w-(¤­$‘ıU³âê¿nTC¸ëF”¥ºİÚÉèÚÿ±&÷_sTèòËÙÑqd?ÔFºÈ‡B-Î®#Í{>‡„l¨—WßDa|Y¬‹ùÉ•?¬Uñ ˆhq,ƒ†2°§ŠeEúdƒ¬¥mğ<Äª¥ç­ç×¼üS6ù È"\ÁÑ&I‰e^M )å ©`ü3Ÿ‡ë+Íg0óV¶¯….¦¨ØÓìE>¹‚¦PZ¥„GêËg×u‰)HV"“?À'‹ÔNûp½‹JPÅ#Ñ$¬™4‹œ!Ò¤aÑ=¨"•f÷fP9òåï<ïSFK'Bí}Õ€T¢éßŸ–b5¿¶â 8IÍ5Rİ–ã\C²lÔ¢rËï§ƒöİ»°ì%8‹h„–1á„ıêbÄìÜ˜ŠÃİÿæ"¡AŒªœ‡–±\¯X®éŞ/4N¦—1«g¢mß}±â¯œ«:df/?êe\*`Îë]ÈG)Sò«"D;œí á|YÂøesÎóÂ*‰QbÙkìCaµÀwİıM­‹‰Æ®ƒÜª¾Ş•&`ÉJsù‡0¢Œó‘÷Nˆi†ğÏ…0ãyó°8ª;Ö~œ!â{Î*3šËÏö{ç8^A8\hÕ½âÑ5×¶ãL­lL˜L>m©xÃ€zy’f°šÍDëOGæÑêFó½™¬6ïB“î)%áéüŒÅ3Ä·ûŒÎÈzUyú•Sõ8pĞÌë>šÛöxõ"âOè™–¾"êYAVº¡•O}˜¡Ûœı4çdBÙÈüÕZ¯&0ÎÒ|^àRÎ‘ÉWfPqÒñgbezTST°›‹‚”êN¸ğEZÇ&xÅZx2ïA’Ê;ÚèÖRÙ¡¦Ì_»`Œ¨ Àß
Iô'š‡ÿK=¶ôÂ©æoÜÛÉùşŒéıŸ$å{çÒ›ïWïÉhş(œË%ui\òHA@1Ö¶Vh<à
lZ™C…ÄvŠ)¤ÌHŞ%Å©)o¬‚7|F¦çP’Ü#cÁÒÑD·RÕi ®J(
ŠˆºóËk#ãÀğ¾«³Wğ.XHËÓUp„û s²uè#Ör×ãêûÔ¥&í¬ê0 fôá{ûgîÅ›Š×!"9õéÄº›€«TVZÅO´€úëöMW®NõÛ
+÷™¾\÷À°(¸ÖéëïÉ2²6şÂF|‰¢Ç&fbÕ^ò0¢ŒÙ] `Ÿ;pˆ‰–`Ùz'€®ôêJ€Ø%í{Ó¸›´x>ù­/âe.¶’s0,%øU6»-àå	åóÕs‹eoÌŒ—›Vß[|¦ÇæÛêËŞÚÊD`®ˆæ¯¶ü\è¦›–òÆS%Z<\Œêš»÷íœY,Eé.«ÅÜ<-UB`í}¤#à{¬
Ÿ²¤++ Ò¸ÿşÏÕæ>[Ãö–OH‚ª-Ál”Õá—hÕc‡$Œ¾|rƒÓî’<k1p{j8Õì¡¶=ğ’ŞÛ¡¶Ê×Íü_iÊÚyêUŒŞû«tH°(1ÇüBöÛÀÈ‡\şf¼D™5*éËÀq”îÅ}=²9¢¼VœªPºkds@Óšü#óÆßÂ #&R$³JşÒQ`»Ëà®HAsNóZ£ßš™ÚkkS5Ìä˜:!æzôMç,v}x­Kôî,›A£6TN‰‰-Âı~½å…ÙîÄÁgÖÓ\ødÅ SôçÚr".µÔ†ï?äOó˜Ók"ÉPÓì,aÃùE5pQÚ8_˜ôNêéç½­â¯e:T¨™¤q8tldåM±ÉŒ¾Êúi1b[j6°~g;£kyg>hr÷:ü-nkzL~#X²vÉûŞ…{*\È @'FdÎ¾€•»l/x}Å6'vM¼‚ç­0&lQÇê=îŸçdkNƒYi<‹|¬lp}ÙB=	°¼½ëš¿ô3æÍ‡ŠœõÚ¹5e÷¸f´u¯"´·ŸòĞf09û»Š1¹÷Ö¥Ë¨Ã¨D;=AîMö¨7æ£a<ò%Š7ü iÅ¦åÆNÅ¥T–%y—'~Í­sà±Å`P²êî<9<¥şRóR] :>%º¹Ç `ªŸBM"$<ãGÓ"˜dQ—sÂ—ˆÒêßƒÃOÀk¦*Z-šÒ²ô©al<b`/
¼ä" -	›“Ä›>k"&FñT÷-|ÌûÖbW¾2œ«¬©95ßĞ'ærÖ ±eã1fÎ<´İv»ë¼÷(ŠBbFşü…¬¸ˆ/;¬nİzI§[£¦ÄùÂ$p}L\É,“òfú}èŒ?$’Æ6ØƒÁ:Ú¦CÒ9L65€|%8¹(}S ÌŞKüãÊZ€ ÿÈu×T¤şô‡pi¬¬Ô>ËÌŒÚŸç³D˜2g‰Â@À÷ÖT4¹‡s¦¡ìı¡g|a]'úvjbÃÖ_œÛÙÈ@¹ñë©«x˜#ÿ@ïw¼¹¸Eu>t	 “ñåGpµ=8ÂZç²©òóYD­L¶¤,İ?k¨[©;Âçî0ˆŞÏ2—U·û+3WM¥9XËC[@E9bva@u“¢ &#½Kı¬|«ã¹O(`şÚŸ0ĞÙÕYo¶ÿ?Û†ëë7cç-@hGĞù´ 7¤ ò&›vB(»a¤Zœ¥ËhÎQCí´hKäz*(¥‡¢-O9aú–ÆÕB]¯ŒLm	x<)É­‚Á}•…0¼Ş*m5TÕ¼ÒÉ5»QrK°ºÁ¢ş”R¸Ğ|Ãi2y§ŠaıX†T‘Ra¸<C®ã¨ÊY5ŒÅ³¼«Y}ûËIG>g7¼™ªeÕ&otH—ºoºşæVl¤K»š2EC«‡RÜëú6ë‰¶Ö‚JeÊjNÜ¢ÿ§¢Ÿ	‡Ôzä(¨qo>Zä¥€QãHFkP!Î,<…MÍ‰TÈ¾A8Â)}—“:/7ÓÄúytÛŞ*Íq›×!ˆÁ(t’š?Si«m6£¸aê|ÊOAÇÒ/Z¿²>N*œÇLö¯áƒ;jç§}ëzî¾î’îm—œEóŠıŠD˜ÚJoìè°g[ôùè@#e£¿˜éµ¾X=úJcw\3©c?ÔŸâHƒ_ÂâH­$œ^•/ìPå®<úÈŞ;F)íO¸bÎ*ÉƒöZlŒ]Ìx.ÒBf€B˜4c´A!ää›ùE+Åªé~eÀMhÉ´?üš=:7ìÀq¥pJ½Ÿê+»®cÕ7¯;!û:Êgt__‚Ñc	‡Á«(uÛ»× l\.©™Gd$ÀTÄOÂñ-ÚÌu ‘4 •ÀDa*Ê!
[FM<†Û	ém ò¬ªk´Øö•uY’Á,’aúñ…é÷¶PÃa÷LCT©Šv-š¤ŞÂ,7‚WJvÆCAÓîtw!ŸïŞH89Ï‚³æ$I¯¥Ÿ{&‰j‚ß£qS¦ş™Z°Ê[ß×¨h¤Òš8EÊ1ÃmããND9Á“ş¬yó³>vX˜O¥²<ÚÑXãÕšâçlV{eU¿ƒØ’ó›/,Gc—·ã#‚üV®<Aèaø\öû7W†A:à6IæoñBiR2Dë$5öi”™ùøÓ¤3C;¢h>O=İÎÍšÀ†-}Dn7EQ«("´ “;¦wßÔ;´\µŠ{ÖÜ/ˆ‡€W¯e[¯u®8|Ä‡hßŠ†íyfoM˜õšû¾³ü¡&%®Lf” Ğh
‚0j@¦Q;†£	Óf¯E¶¯Ğ«í&9UíÆpgCéø
Ş&åQ¾ıo\1¾Å/·Ø:G32‹Õ×òaÆ|iwß^‡l¯²‰˜•5sy÷–’­^ÂRØ”÷9øy:†’´lZ¿È4ş"ÃïÏ0ÀL¹°ÑÆ°ü9xñz]ù.v%ÊP½İp5ìEns´€š5š
bü*2¦‡:Ö’ŸßAFt”F¶ø5_VLi@;‚®Ü¨ÍãTÃ€Í…îuP<Â_JrfÂï¿&(ÕÂ‰,OXÔ$LIì(S§ÂX†>¾0ZøQ¬z!öğ$péµ”™z¸²§»&­"§+w·“	j6>²‰	1U–u[q(Rhtù=óŞçŸ™7àGuşfôˆ¿+*5¨;FÀU$ÉjT>‡)V_”Åó?CV‚ÊŠB“N‰‚¨äÅ3¢qöï­© ªV¨Øåƒj^ò[½Öu’ŸÃİ%‰‰ÕO[–B²r?íPcJ›®îJ=£rÕ0÷µºSw…ä¢õM¼a0dˆ)â¨	(Diw†I,
\-ø…=ºŒÀßø
Q,7¢a'‘Tâ©j¸ñä=HŠ­;ùoü£ñÔtEÔŞa§tıq0³>•ÜÀÈÄGífØøÛ“YàNÙwŞ']t’”p¢}OìSQú±ò.3€H pe¡ZÄH;Òƒş(ƒ|ùX  “Æè‚+¢`Î
Ûjà2|¾}“Ş1é"C ½ø`;³tÃ¤[—M)ÿ7±)»ëWÌ¼1jIÖG\ÈhG*W’2Ã4tÌÚ—¬qg•{aK‚È¿éÕãáü¨˜GÊ£e»‹5İ¶^³¯“R‡+;óâÙy™ŒƒÿDÂ@JÊ‹Ø1ÚıbŞ¬şXÖ‰Œl/Í’â2%d&ZüøoİşXÓYŠ†6•Hí°_®åÈ®|Ø2x|i—O’`!§v/P²4:Èµ/hÕ‘ŒZ) \Ì€5¼%°5>{5@  oã“H{‘`¿õâÜšRØ8#ÂNN‚ÂØøÚÌwxŸ±¦•'§¨8¢qäÿûK*AÏZnrXÔ(½U›7A¡co‘e¨ù¬tÉ*GÖjşZ×’'úvø4á}tG0qCrm¼·Bõà3İ˜¢Òı-}{9qDa¯†B,u7éåñnß/|ç/ûáG–pùÉ_keÒMP—ŠOëµ¨Z„´n©•C÷¢ŸÒCVTkzçe©j)7t„aªŞ3²\(ö3c	³ÇKÙ
¾^OáŠË°d™@wÓ¾ô82Œ¾Œ÷ù—–ÅœÅªJe¨“M}¨½n³ôÅŒf]âû‘_ŞqĞSÀY#W|hş¨úGÆßèZİSD´\ñsRLÔ.å¾Ö’ Ÿ&/ùÜ|@A™*$ÇúòC¢óê¬µg»6h>«0oÑÙB	~Ê%“¸p¶kÙ©…+­ú œŞCD)xèÄ¢¯v¬=ÚTáW¤é0%¬ƒåySn|pş‚â:H
wÁ³<½x~›¯·€jzP^‘uB]Áµˆu-y°FÆ[Ÿ&µl¢ÏMÚªUì_Jy˜ıàÑ«‘¯„wSw±	ÍÒ‘ÏİGóôìyBú¬éÏ@ 9vk0t—6’ææ^šcHHÓ@gæ’;×YÛ:)ğ¼	5²RÈ .¹#½^Ñ%ã)G%·Šä3X¥Aåñ¿73¼eéÅ–`+7ÇoÕ+ì5ØE¦'B¶à;„Ã¤Š”"J$2œZ›×iÊ«4TãıÛ‹J`]Ì¡ËŸ-9l{? rğÌ ïœƒò‚á¦üµŸ›?äÍ0w‡»–KÑéŞşŞ&kÉÃ²JÊºü®4O­•v¸==¥Î…!:×(â#§îvNñÇ€Ÿ"®UÃ¸¯&Õ.ËÆÁ÷"ƒVQšpÕÌC~X2Ú=òHæx#ËK#²æ1ü(Š4Cê=ˆ}ĞıI!ÒÇâHl[,È\W„^ïéãj¤ÒÍÉo•Ñ•»½‹¶¾–Ús3ºÚƒxwc5ŒUxI{œ0;¸—İbú¸ÕÔıwPYÀš¹çŸ`ö•‰q÷é‰u“&;\ã•øÿùÉ"Ú4ÁZ†Cù¸-ËÛµ"ö¤€¾Y·5‰‚¶a@Šdv*ñÀŠf÷NÁÔnö\ÜN¦´’xoÉ£bp¨%]8Ë¶’>_ñïdç&t}óİ°<ˆİ³çù¯ _³í4 qÃ½K¯=O	ÿm"Sİ—5áú8î).ĞRÅÄrv÷²˜28¥çš¾Æß),yêA^Rëg}5OO>¬vBè»RqşQÇò ÖÃä‰b *«pàpiÅı~à<ˆÌÿhƒSúÿ³‹é~%¦ÂößÃ¡À×.Ë0µh•ÿÌ:Íÿå>>—Ÿ“Ä]ô{<ÏÛ•R)lj©øq’íwÆ­\,4µ«àë¡$v†÷iÉì«u,¤KÀMéròEåâf%§7NH}Ëk¿N|ìÖ\7„RíÛI¤˜Uš“Ç†‚“/-.ü®I¼Äİ÷œ§İ<q¸ÓNbkï°Xì¹3å°&yJJ¹FîƒªŸ'Î¬Ç±í`­ Ì[OS¥Õ—ÜÏJOñ•PËîH—oXyİ !µ½É<u…òµG»D|˜‚Äï	…â½wÍ£Ó[8h+,6ÅjâL]»–ªA"š@!ŸÇÏ¼É_9hˆ—L"<=§æŞN^ÒÇ›EÉ‰å^ãi@V‘aã9QÒm»P¯dÌá-ã7cÀÌˆt°wÂ…A'všÌ&º–—U8{¯q¬l8¤Ë]QDíªe¬Š—ñ‘§õä±'†®
)Ğ‘”›ãªß.ôë—æ†p
ë'Jö„m«‰™šMóôµO‚TV’»Ÿîl#~,J	BUÃÁZ&’…qÊñde‹(½ ıƒYÖ„9Û—•Øƒ­Ğ*ş$ç–‡Yõ`Íäš*›Ì¶ï›°6š•:øXE±Ï@2RîHQ3×¢As\q¶ÕeÅ³JÊækn÷2	L7®ñoóğ
îtt«¬ş›ÄÜÀñ£q@ã8»@=<Dz‹¤	]Vôñóˆ5 I;Y×İ4]ÏÒ:#3˜Aaéº÷‡†%C~‰Xuƒr.k¹9Ù§÷ØM
ÆzÑ\a¡–W\æ¿¡ »‰]N¢-Úaúæ<
§”¥Ú†O]qõë‘°†Ã¨kNã<×şOfãìŒ•Ø®åñŸò‹üÎ ¤;´)	áÍ=Şğ §^!Céûu)ï„ƒ1à‰8< j«p(ïŸ`4Z5m@ |©3fãeVÿ¹Qpj#“^Ñ0¡©Ëè—m ÛÅ²9ŠŞ,ªph´,ªf;¾
ÒÔjj®°ë/)2xòóÇ¿_­4œÇóÖÎµ¹çß÷åMØ=(uaƒPğJ1;vörÈìz>xàãÓAá¤Ùmğj-®ì—³-Ş6 észA€y‚RÜ)¨»²èM8»rLgBğÛ"^oÙá“ÈÆñoÍR”´Ú+æúÏ¾GW½B"*‹èø‹£<¿7É$"Aóˆ@\)=ûó¼gDv‹Àã·Ì|èıóõÙä².¯Å§b#g=àîÍ\ª[:[ $’)ÄB9-Œ4U?\€S¨Ô`FµBPİ¾È¥¡ĞÅ?²ùùh¶êZ,¦oc™»fÚ|-(ßqW\!³´Ê!vsl^C>Q•û ˆéM+¹¼ğÌ£¶Êr–âùHLSÆ‡ğ3|3+:¨!Ÿğİ0%sì;N<ÈÊŞÌ²,\xUƒÔP÷øXF¹„çç93ùQÆArØäõù3}ğşE)`¦/7½Øç\h:Óúım6?‘Üzm…7Ü\NÖ¥ÍM™åŠÊ‰ÏXe&½-—N¸(GWšÜh€Ø}ÁŒıQ¾1‘(u?üªQ¤_/t)ÎuØÄ«üéô@9R§ñƒ×óÙtÑ™9fS‘EêÚ3~ç),èëT-ş„Ç\D¢vŞa½âÛÛĞ‘Õ…ô¯¾÷)ßÃ²ø³hà9G‘~µ´Í:ÑÊìk_g•ËKØGIÔ·ıšuu®Ë)åRõ¸(Ü,/Z«]‘€í™ú4çŠ¾
-ä#esîTÎp(/m€ÉÖí‚°¢¤ÍSü›³JÅ=„ªäù7ı,QIDÉw(Ò¤ ¸+R%,ì?p¼ïtÔŞ·a¦%Ç©¬mA W<YØ€²”.4äÑÌyˆPéÄOŞo%ÆÁ¤Š6ÉË¢œC#Ñ¨SF¡l§áûô”îiÎôê8§µÎrÏ=ßzô×kRV >Ğyú-°ø¸Æ³kmi{¡óşq«¼ÿ}"sCBôë!º|M2pì5«ª6:ã
WİáMc}MètbŠp	ZŠÿ£çÉ’o²ßW©W%îˆ^qådN³}ô}ö~ê·iŸƒyŸ áJ;&¥Ôv\%>[¬¦Eª_²ÄÑ1—H·pLŠÁàØÚ%šÖ-ò¯›è
‡ÀSF½²{x[L»+Z¨\(¨E¼^ûn¿”AèåÆÍâ FÁ—Ók£ìtH„ÿSÕ³KÄÙm|1¾§xÇä'šó{—at©»ÿãº4
êÔUššñ…K¾ÑÇ)ºa	‘WÑ2øYDIıÄO³¼yIœò”é¯µD•K.–pfÄ`­%¤—“_LÄ]7¡	ô8ÖåûÂ}ITÕ”»ıêët3¦x?İ$Úó'x.ù/®zïQLEu&™şØOÏX‘øqt÷¦‚¶ìó-m;—>«Û¹ÀƒÛ½'¥Éß_xrŒJ|qÖ<ÖÙµèêÈe?4™=F[Œ¬|hµ×©Š §†4fÙ\‚CŞy­Oøo\40cĞJ@'–X7=‡§š˜b†õ±Ó$¨3ª#«¹/ËyPLò;µõ:æfÂQÓÙkÍ~6•†xÖÖšñµ`úÑJğÔIühÄ•79Õ"Ëè²pa!XY8ÓA¸Y.æ&ƒè`h®,½šö¶s_ès¢ñ
ÁÊÁîÈ.*u]R÷UŞ/æV7ÓÒ	;‘ÁcR£i,½×ê&Nı¦Ì3ı]ÈJMk4*¼¦ B3Í*‰œş+ÒSh*a|ÏBäx 8nkX¬ãİüºÒ}j!²d)šr_¾ ‰KSñ²ŸfóìñŒ
×ß3ƒo‡úL…IøøæD“òĞMMš'WÈÂK2ÀÌù•if°+ñ×ùM¨0—hÄà"*ı>=ü¬¡"˜ƒi¸_÷&ƒ×?x’îÊÿñ@;áv/2Ş_2¢È<CD‚–‰îõì_`Á¤K<)7)©*»G¹¤ÛYoÆÇÅúÿ‰JXOÎ?ƒj–‡«˜Ñ“c;¸>ªô>?Ï«jBçB‘ôzú±ÅTÆ?Ú) İ_1óìšñÑ¨JZ+Ñ~x‰#Ÿ»ËnædL7-AlÒª“NÇ{í‹GP‚‡~¦&F‚Ìz«ø*Nt5£;\¶˜Ü°Dêw×õÃNW:DòhPk\¥¾>â§<V<*Îbıà›Íó"_Üâ¡E[êÅÑïP~Ñ¨İ¥ŞC/iÕCŸá’›ï³Q1° êïÎ¿§d‰è|Ç5¯#;Î`mš"V¯R¸¤çÙXnp¥º%v°îÈ½óšnŒbH‘ºêˆ.zlêj/ƒˆ‘‡ü*QàÚÁl§§,‚vÓÏYC¿Ğîãr*#¶©wjJYú˜†Ó7*ù’í;cœæ	Šãº jhø_`A–üEâì¿Á†uªdäìtŒ:«€Œ¤ˆ3*SÌRRYÎe…§I‚a!:%A.gi7¹-Æíb“\‰ÿ€5à-J	 õpQ®:ÆşD/µİ‘HÈóZö±âéÁzxŠl›2à‹ÃÃºHPNz˜šzÕ¯¯äZRôër’YõYàS:N ßË¦P’òĞVÍ¯nÎå¡Í>ŞÌORPİĞ0Rãã.Œ?²M¹nqû2Lçt~(¶‰¥½õh¨h¯N±ıdë’Z5ŒĞöAQmq…õ§Ü~6V]ì!pãteZäG9‹¥Õˆ	ècx¶„€Äa{M¿8‰£>¬NÓ‡‹dÍwc§‡NŸÇ9Å3Ôlçi=ÚO‰SOˆWÓóµa+£v¤Cıéf÷S_Ñ¤=p°Û,Œn™½ÄsLİ-X«íL“i#¼ÁØ_ĞQÁcóüZlÒnLs¡ÄÉ­Ñ'ªAÑKÂj7çP"º“7A¸iŠŠT]Y™´¦›øô~Zó	ÜI0ß#öt0çš¾„Ç²t–Œ¾KŸ¤zûb?Â}u@Aßø×!ş«òi8j³iüëet«j{—ÿ£M$pÉí¬£Áøõ-\sµ¹Cº«€ğõv
ÚÌ¢A{nfà¦Ä–N[:ìYI48fk5Ã;Ú8}’h ¶fëË¥®	ôE7­ÿ1€QÉb`SOÔ.÷6WjŒô~æIÎlóÔ³M5®!€× e	825}íÀ£~®d—m¼òş–¥LLCôËrÜ±Ô‡0!¶<¾)®_ud€á·‚Á™ÙNÇ0~1÷­ .¨Š©~P-1L^d8@øg\~ĞÔœo^<Õ8½_äÄk‚®¸L‡|À‚şÑ‘bwgèĞú~Ñ}Ø;a‰‚æ@2[G¡Ô³¡,”ÌYm š‘tÕ(ÇLââ'¼óZÌÙÙİ×±Ÿï„˜á”ÄÁçU\±†‚· ªŞıeôùËØë%òi-7”rÛhn”ÑqÄ¿i/şŸQèºÓ¿¤œh8„›qÓTÉØáGÖKŠÿ$!‰#«]ƒ<ÛáßTW¤âØ´RáJO’Â9;«É<Ó‡0L3µvö‚1Ú8d9{ÑÁƒÍıKœMïúÎ“Óª|H%¶ÎaZŒ¹'-xŞzÉ['M[¬@Ôs+b4d;>t3Ø6z¢+µ{bSÄ¨VšîÕ‚I;\k¨
××+ö¼µñ¤[îœ‰¬|s­tMÒEÅ¼†‡àaä…¤§‡)ëéÍA.Z.H ƒŒØ6ãb°@?/—E›M,w©Ÿ)¿ò1“d8Ñ!û÷¯|`˜GUÆ^4AßÜ¢­çˆ¥•OykÄ“FÑ”vR›”ö{ãA	¤©ü7Ë%­Œ/G”‹š…‘t~¾ÆK²~ª2MF×2¦¡¶úÅAWöÛ#2L‡(Èš'Ç­1 0âëæ=×³Åğk]H¬N@‹G(-Híd`m[^°Z‘^°ZäÏbÉ!±˜k¡Æ«dzv¡Âké2µ_aç)N¾9œ[-ü+gÔå‹´êİ•C¥ô\IEèæ™©¬9’¬å%sL/÷½á÷M'zÍİsÛkùji76‡¡ÅşÖ¨Œb˜S÷Ã
Î»â:ƒËHÍ"¹¯?â1^šg˜ä;”?ŸpÏ¨ğ-7Ô<ò%ª†<1İ±âê¥Š|À8Ñ-çµ± Ş
X”¯}Ú7,MËåÌËò¢PŸÅRCUÖM®ÉJŠùCáëòşP{}Š©º-×¯M	d?Á“†t¥‡/Ñ°^ÒçF"1ÏuGx­1pP;Ù#8ÇšîÖ şú€i~È?QÜ¢ş~¼ïÆg­Å$:Ù¾‚‰ìZ€ò æìO¹…A“{ì‹ŒX.áŒ\n»ïÓE“ºûç$Œ÷ğ—AğzîW­„pÏ,&—^0Ø£äøÿU3‡_¨ö¨‡9/¡¡"èNr
`ïÎ­»3iœÅpéÉ>m&œµŒ¬Tòonñ›úSôÕ(°’º‰|¶² TÛØÍµÑKPnÌ8|8#oëÈüë;™Æz9daøë¹LhÓkCÊÄ˜É Äˆúï¾ƒ•ühÓtŒ7x½töùXà„±"^˜ÌT<òQ¹ò”ÍNçÓÿ	›2ë®ğSüE‘¡cú‚2yWä4İ¬Áò®o¤òWqï;Ä_ò|“‹.ºˆ‰QzÇ‰‚¾fÅÓÎzä;?×e8	²Å@ßx^`¸~÷Æ»¶1}ŠcF‹ß².Ş•¨î\¾8KJŠLbğb€yaH<i0˜ƒŞv>rx¸-.€£ç@
¤¦zE5@QO{ƒ¯îĞ(]b½Yc2¶/¼ÇVº÷Ø^é2uflšæv6ŞÑUáHÁQøoÇh_}cxS›é7š31u«px»¬>ÿrî–áÿ–KÏN×P&§níœCRàm=ˆ‘2¬‹«.`e Û°Ì.dÿ
êcêèÖa£ş-ÃÄdïİnùN¹*îdA¢ü5¹ÜÙ”Aºa’¿şß›íu×$dRõ–nÈlk(ŠYzÆırñİ­Z{‹èc.EşÎ˜j­,­`–ÛÇ=
˜±y!])×K£)‚íV‰®3—’q›æè›İãì¯t…#ú¿QÌ?mëMV vïL¡5‡r@1±ŠlÔªïy*çXÌã
r"y[+šğ~]À[´±÷0Ç-RÔ¦x;OX[İrÏj~¸uÙÉYßFw9äNa5[mJÔ´i˜’Ì²4¸“ Î¬©ÿ	yßÜqwM?³Ço×«³À
v/)<’GÁ%ûä!¾Öµ„yyLOÑZïYY”Q¾ˆjœÎÏÅÂZ/H{ön×ôŞ6‚9Êf¦HÆSÈô».ƒB¡^Aµä :ÕÁç´”`ÓÏtN'd«×£ èˆ 'òNPÄQ&´UÜ5=õ
°¹zoŸ/Şµ1WÜrù˜Ö£PÛ.³TèTAó‹Iá¿ÑÎÍ—{ «ï°Äù-¢†céü©i®9éÄ¿Ì‘Ö’LT.ÅÌ%J¨o3 ±ùHá¤L^¨år+-tÚIã©œ#LéøúêbÍ1 ·şNmÃWm¾@òÑnë¤@ÓmÜ4c~Tö95Ÿ@Ó÷¦ßúÅ]×‰‹ZÒŠ›2‚á(ñX”Ş¨w’»ÊÈ¥F7)è	§º‹3¿_D¿I¤ªr8lz¹ó€šM1ÜÈj6
Sƒüøz$öH{øqTŠ|lËs®”. ?á¦˜õ©İ‘7*~«gpÙ¿<ÀZ4òU‹	Ş¬–jşW+!Çè*áßñšÀZëş#D„£”JŠ ºúŸ¤ùkH­-O•¨”˜güÀf°(æg}F­9ÈøÛm¯°s§¡#“" ìÓ xbOX?aÍë²‚Ì%uºÇ‡Tš_ŒûšzÍ¨|«té»[hÊ(\g1ìâ ĞJ‹S6zÒ¿ĞÆd›¬¦d›iÏIOlîa4–İ^ —ŠÃ5fŒ[§R•×Ùğæ{R"èqç[WÜŸ~åIş.Ú‚]’µB£*:¦?Àr€TÊ~ØFĞC’ğrÁcû†TŠuÊÅå7¨k‡Vÿ‘lÖBR¶.qŸlolì”ÛHMkõ`4¸_®ÈŒB«ì¡-{´¤ë„˜ô>wE	„öz°êÏÓM_eHÑşyRşÈ»¤Ë“TÅ4¬³K
Bkƒ Te˜¡?aÈyG³ëôœ°]JX@ˆi$U"AÚ¤šh–!Ù’áÄìÑ;şÏ½uéJmy€«eÀVä¦>áus×Æ×£IùÕºËY$5£É£@¸ÊÍ¥X‹Gb!‚ç+I…ü¹§Ÿm ®v_§l„(†BöD­…/j‹$• Ûñ\)=7¶KŞkâŒ›f£ Ô Á¯Ç¸sgÅóZ;¸ÜnråZÚ`&Âñ'‘NÎ¨ŸæıàZ-W%9×ï„+g¶p$Éğ2ë“ÙªG~Å
¤òñ8­gŒQëÌù5XrQa‹û#¾â ÜCBƒ	GªÑ$LóSû^ò½»»5¾Ã–U$äDæíaD…™CGÉª4‘äüKØ¾~Üà–j`è§à7ã/ar˜´ÚnøÛäZ%˜!è ŠcFÍ®ë'_[t¸àê7ãö",ëö(YÎ5$Aşß‘›®!p”ƒÃóvQ@»­ãgOí¶[½ü×ø'†ñ eC-JÀ3÷òÉ=¯å›ÕMI•¡C89 £T<Qm.È¡RqåÙÌŒë1’Fa µ´Z¤d¥	YŞ”U´eY\¡#Ñ¾şÇ®êrÎGƒOY3ı¶¸Ÿ@/àÄóåÓõ†Ç+ôœèÉ‹¯éÙåÑh;®¨©A,Ì<o˜Z‚Ç$÷K“<ˆjy¹À=È†Sƒ²mŠ+ĞÑq—Uğ-¿¾	³ùõ«^zƒ!ùlùY=µ\{í>u: &x–5vp¹œç”å07ïu«É^^£æ.›šZl÷	ÈŸ»Ï÷i¼rEãÆNìÒåôo£šcßõÆÎÒÛEÓçñˆ*üò²ÊÂŒmÔéF¢Ë—2Më;²•,,œ	¢Õ‹?Šî»ÑvÌ°Ac”=¬†-¡¡«†¡¢â;¼â°-¾èŸq!°YÎ=Ò«ûò„†_2_Z6ƒgDÌi\ëèqîÄ†Qÿã^/…‰1Œá3bük|®¡œÿ—4-NPĞ"ä´sè÷à—d90€‹Üf1ÉzÄ:œW+°ôúéÚ_'°¶¤b¢Yş£¤ÍØPGDšï/Øtg›”3Ê$OdßÕkÚó'5º«	"z¿Œ„t˜^õ¶suÚÊzšuÈ2éĞ¾Aş.Á•-=O™•ª6VvGZÏrX/_p‡Àà*Â^Pí8×»úêğ:¯DÁºÈFnıÉŒ”P!Ä¡jv#/5\XuŸR(vÍôÓrUo­ ¿âcƒœ½÷bM‚ò¼óÏTÛlš3ˆ¿šVÁ¢+V:®® Q×ü{¯­ÄÉ4 }mRJg£Ö†ör3|ÔÀ™ñ¡½6á…W=„ÿáè«îL%?ƒ³Í(.«¿[¡)ÿ´
rtæ„+Ê:¿ÖØAÖ&‰/­z»G*eÿ¸†_5°«¿q`¬÷õ’
ñ.¤ìœºÙŸuAHh°@ú¸p¾¿­øè¬İj‰ØóâİÓ?·›
²üïµØ‡ü^’æ µâdBÃjıÉbeª‹ìÁºgßÿa,0õi)¬‰Ûí@Ÿœ=zäŒC~c7\y‰¸ò½q^“•\—É…?• Çô|¼uäDHÎæ+hÀ¡jˆÚ˜U1Z!®iÀOB‰%_Ç¡—Æ•–‚Îä
B·H,^öÅåpc Î™;Ê¼ŒùŞUñ^RªŠdhe ıƒ!™>´çg(ŞG)=d^Œôó)º,¸â¯_EûY7w<¶(óL5,B|È7½D&Â÷gõ#òñ¨Ã·G÷)Æ¢Â·R
nxå’ø—LûŠƒB$jV¸§x3v˜Dj“¥gÛKùBœeèeŸ²œ^™Oò·^H×]RÍì•®u°ÔŠ/®rÚ6M†¡¹ª²ÛÆ…B^§I¯ÒŒCYÍ~QàJòs^ßB•˜0Xğ,Ğt†ûYå9v>ì9©?*İÑä7¼ÿ@„%M
ìùÔÅ‹~N{<\Rá³=v4[Ô;cvvßš ÕöCü¸àÑÉp¾¦uxÂ?.M—]µGáX²pG *ë›_ŠnXÕ2o÷ ¶‰’Íq‡¹S \a}>¦É`˜xd_Üe[*eê@eq…NuÇÁ#»ÙĞ’´Évä‡SåMV^md'±SŸüRü”‰ ÕĞwS»¡áâ¯4rU÷Ñ$&Qµ,Ä¶ü6u¬m¡d3…ÂzÑB‡˜r	q¢†ŒûÎÃV„áaƒGG<o¯+˜æ‚ÛŸ­õSû?°uš  öüj=ª?ôñ4¥˜‹M øv†$' ‰8ßËñœúß¥Ö³ëtÇ@ “Ù– =rÛKÓĞ%fÂ»·ø¢ì*º	{ƒ¹¯ëî±,q’‘´tl¦‡iRÅT•r;‚YJL”È°U¦ ª‚>j”}µÎÃ^-Æ©™fH™áEG®ªÒ³ÙÔ´#] .‘——#êÓ¤»›5Tÿ„imâWwÈÅv;æ	O˜oölëÂvÇÆÃˆù*·P¹³/™ßÆ»¨uqGAÓÃö(5º%°²çlo)ìúŠ 3„S:jôœÆÒ :¡²»ògóèÎJ³`h–m—‚ì‰«© ±ŒÕ¿Z¸«ÑAyª°r’»»Ç<—ş×=Å¼±êS?Ÿ¾‘SsÃD•Au?¸vŞnb‹ùû©†pÚMÑ…Ë·ÌT5Ó7–°z.ïÒÆ6{X×,ÎÛßW·ÏòÓ8ôÈûL7Š)¯$³Ç*S„¼7Sê”I,–ë´Ÿl«fÉÔòq°rGw}‡qİ­Zú“™¶ié‡ò 
…ˆ¬ß…à\OFÖê”ÄN#;O§DúùbC¼Cÿ1lÀÙ~ÑÏªuu®Nİ6¥÷Ã–Ç ~uçîOEßÿì{èói«˜R–7½&7V
$~"'ÿ°P%‘7­=A{kè¨T(ÀDÂã^Â\åø:Å?şVndaÍç<y@Fop	üô¶$Yf_/è:z±§)B«ßšLLH=\É²Æõ'ÉcßEÔæ6ÁX¦ßlW<¢¥í,k#–"Ï±ÕæKÑÖ‰½>Î ƒ¢Qß†Ş1Íòí°tQ«´N7ÿÙ;#Ì|ùWõÍl÷ÉâLt(vïa9æÂŒ9cg% Cs¿Üî°Ú‘Á¢s]ß_)Ûb±cƒ¡ië)—<Ù/úñÆ%ˆSô“€Öp¯=jkô¼İ!.„A)íÍjÀ%ySM^…i’Uwû³vÔU„RGÛ÷Ù‡±^C¦>Ğnq¹º<`‚çÖÒêR=ˆóªµƒ-uqş…IÄæ©¿ÕÎŞ¹\·»{9Û­††cì¢?3ÙÅ¦ÉÙÅÜcÅz— ù»JÌD™Ü…µ£2@Zü¤ÌÚ	•8YáU[S°mî?ÁXÈ?Æšº"&æjUKW¯;`znK¤Ğfì‹éÆ	tQm¨‚ªN1W§¥¿.F’Ÿ™.DsE–mSB‘·ŞÁy^|`íNŞæ¯ı™ôòõ BD¥©ş4ØX’Äåš´mv8ó5Yñ×gË—x÷ıFuRÊàùõ$5s ßR•SoÈù,X3	éU©=¾~ß¤ŠÄd–u™Ï>?×Pö7CºÛ9b²•.ÓgıÓ!¸{«^Œ!n˜¶¾q&Wc\zø§0÷–s¶™c8ÂE4ua:¿p~£,ŠU}C¼*•¸…ßlËB£LvVY¢_FÕ·Z­’4RòãZ#HîŒ0ñã\½k×¿¶«yŠdfUÒØhhÔ–	Ş09èˆ–=íşš˜‘Œ|4{W‡…šãbxt=É‹!Öû‰xóæK…”]Z\Ñ¥¹{Û+®jXâ£—äM´t?^2f…É‹ ùGN«Ûì+"p“­ ø¹ÆÛiÕ÷'åŞY7o^›¦‡u÷® xÍXı qeOh‰¦5ËT^øeïn*Ş×—T>Ğ¸¨§1µgÚ¼ÄK¿UÜ¼[UT;{ª†\÷á 7ÇbzOŠAjL45öMØZƒÅ•÷I±aÄ„„AªáqU¬È)¹âœ=tiXÖèŸ;²ŠØzã)Ì:¿™fz–ægG†k]¯z[…á•?ÅİdeSœ»_–m=Xø.b’-ŞnÕpN©¢B¡ğôşıšìxjœ¤äØs¬lûb×];kOC\M]L‹ÃÂ°B=æö3ZÛ ñÆ }«,pØ˜¾2ÑÉ>. "A‘êèv!KÍ½!‹ìõ]“Ö•OOÄ:7ê7£ 3$±¿üì«vË!‡X¯ {‰À¼VÙ,¹Xì|ÑÄÏi§„ÔNõ(5»›Ü:¤)A9í ;¡F–«P·‹~ŸÔz’Q‰Dš"uÑTî7çvÉ–ÖÏòNndÕğ7†#Ó÷ò9°á–‹¤¡ç	9{ïÈÇ¼u«ïÆ)Z-‘?Æ?E(Ÿ|g6ØÑí~„»aFâ‡kUHõ´'UÀ˜c/D…arxıÏ¹RJŸÖRú`¨cVGşÄñ÷Õ„0“È–¸\Éƒ‚ƒ[ÿX sIV
4~VB`ecZ‡˜.9Ü^DŞÈ{ñ/TºÉ/^ÍûsDJ¨‘LÕRJÄ_!è'Œ™ÊÌ¥}!Rd„Á¥ ×Õ4=Î-sğnMTCa÷Ô›1øæ…ÌÇ|Áùµõg1Š ²KpÇĞs„ëîwºõ¤Œ=k§‚5Àâ*÷œòB˜Ì¾¶Ù€õ¡ ÑlŒ·Uå"Y¾ÿØdşÑö ]ú­Õˆ1ƒAQŠ¡O°ƒ÷nä"ÈÄîøŸsR%UÕrXZÑ²h]ìá¾ª~ÒÒLA‰¯FZ„^8ì.skÚFzŞŸºûßX‘º’¨Ë}}®„Ì¦æøv<å½x+p°†yeŠ>eN¾õ<}óÊ»pfãáu¯m€íŒ””4£ÇGsq…¡ÌÂPı,¤‡¦uyDˆ"*èp³ì©[š¼òDçP r£i”éYR¨gû{æõ‚‚~gjŠ¯‰åMÎšà×ipB‹¹àYb¤à¾d×”Ï;dŠ³ó\µ }”Õ~W'.$ïøRİ^òŸ„Yğê!ÛAÃy2£ øÀ0”…Zßu½M]í—6*>í—½<©ëÏWÁ×hóS‹í­vÇ°Ü2ê*?—§Æ-Î¥àÕ#«kõ»ÔÏ=:~^D±~¬ŒıÛxŒÏ>3ibwRóK5¹¹b_¦‰ş¾yDqx•˜^(°5é7…`x=jÈò]¾±~ô¹Jç!Hñ^Á¾ä‡y£ò70QnÅÊ^TVÒ±óÍ}¼ı5@İ•ãÉÃMŸ¸ãó`“gE0‚,^àR¾^D'¸Pë¨E„JÜ=6¢…À»½M‘…¢â¬%PCC©Û›—.C¬A>x†ÏÆÿˆÑqLÕx¨s h[ íË2tğ‹do1è2ù#-€AÂ«-ô_D˜;Ï•ªTå9ººhhš®Z]ó å=éY ÃO¡¦/©=@®9ñ<oQ®ëş÷Ü%Ò¿!É<P-’Y}´k=âÇ‹»-ã)¦(D9ô¤@ØDR7S*Ÿ}8åÙ`{éWWD/âßxï%õ®pa@0Iƒ×¬ä´9QqÎ04‘ékI4)¢6|ûzŠ
È¾d"~ı˜tjÎ/×=¤Ğ§Ç´Â…[6C $ÜTyä¤[rI×î(2ŞÙüêL‘äq…ñc¯wÀnw3C0JBº‹N­i `÷ô‚zDM²êİîF˜äzœ-îaGÍÚÉ¥ŒK¯ïaáµöcg?ˆwJOÁÙX0´YªRü·2„<ÛZ¨®Ú½;2™–w+zæÕT‰úl¼'áİ@Êş4/V½Õ€ûj[ø:7nØ¸ÿ«qüºS”ƒš=}V 
×¬+G<ã¸yiã[ÖÃA:     Œn+nav£ õ²€À9à±Ägû    YZ