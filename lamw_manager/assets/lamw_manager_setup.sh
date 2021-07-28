#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3433863834"
MD5="ea38389ae91e7f73751331b3b03d2ba1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23356"
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
	echo Date of packaging: Tue Jul 27 22:37:26 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZü] ¼}•À1Dd]‡Á›PætİDöo_~ç„ü_¸ç¬ösÕ1À5ó¡ÜÆ»° 2U’bcà4©­+€èIŠ‚ æ}˜Bz™İ®Ø}¢—àl›5­ÄeûNèzÙ¸!Ûè,c6 È©—5/_¯&{‹+P4Û–z9'<§ryñ­ğâ íG]TÜìîjšz†9ÖL7QNÅº´u%i2†h­àÛEºV9“Ã†äáMH
ƒiV˜±^6rÎÈd‡~n…Ê%»ÏÖ<<BÑ(Ş`»*k×üåw¹s{U¦D^EïR¼\„+HáŞkg$ZÍØ>¶å‡+Æ¸ 1›;v=Š¬¢b3×ú¤U‹LGÅèâ?Ír…€¦ìÏ×U´‹îƒÌÔŒ/îS!ª-ï‰bFüÇGZJOØÏ‹^€<ò¦`~Ğ.Â»?æoÜZ±4Y–	+‹)¥Øª9b j"7º„é/h¿"1YU…õúÁ0	˜ÏGX¯\ÅQAß=}À\«™ìT,5›± aiJ¾YxSß¥l…rg»^m•" OvÃP‚…ûû²*š[¬€-k?¥ÎwnFŠ?T°Rc÷Ëİ­ä©Á2`»æ Cf'ˆárÇÛ†|¾z8Üdä¥oâÙÿA•LCåeåÂ®h§®ø0¯«z”µ²•»°LsrLyÎëYp®xR5j¬Ç/®1_À¿OàÛ:‡wgS÷ìCåé~+œŠ½¯P‹ZCXî=‰_5>OK§Ø¯)5´¬‰¡gO¯ªn¿*÷ıÜ@JG•Ëå¶¥x¤=»†÷¿õs»ÁÈ=ñ×™Áü6ÌÒh`{õ^‚!ÄïÍ&3ñ7×°Q­t¥È…gÇ¾4ƒ>ùä$[41—šÛ$¸şrÑV;/ùß9Oß¾ík&dš,˜dp¤G\¸èjßÜˆÄ”d§Ne–H5èlÍdübÔ@×¢òF|•ÜOWÙÀ¥Ñâ¯DFH— ½6¶u»ejM…C|şT˜ô?â¿·Æˆ*fW!)@º­…	Oò,©©°Šv‹À8ŞS†¨pÎùÏk¶-Ø¹*†ë€D^éÅxQørô}ü—uM®ùóÔ`é%ù• ñ-şQaƒ6CÃô´İá)òbª€#È`›¯³0×ıåFĞĞŞÀR…¢F´»ø™§3/XÄÖÑ=+­±Ù3ö7ÎÒZüŞ7ª?‹Ÿ@ oïã¤¶âd08s'ØNG8 DlÆ²œ%à¦P^eRÑ—#±åÎ!-¾XÊ¡î½½¨¤[)tú,ø¬í±Æßth2çgß‘M¾lİĞ©ƒÉ&3ÈÅó“ıcÕ9Ötq¬ÒÎ¦w} },«ĞÈ½ÿÄ2ïK©("¡­ù¬¾¯7ghµÙg6pzqH¨Ûİü#¢÷“av¿êsİT™·äV·Ò3Kábşf@!Pƒ‡„}ÂäyüJ«Æ»D5Iy§ıS‡>“çg›0î¯‚]î7ÓÜÈñ?æÂ"jVäjü°ÇÿI]›—Ï}îÙWôpÄÓ‚Ç­O*5\+ûBAB¾§@}õˆ$£^né@·\?_åhÊ06L®“¶[=°ëNy¹Mo wì’»ˆSE.Ö÷3ñkØ’ÏÁa8²…¬üĞøü¦ß¼*Tß÷íÑ5…Q¾?¸ü³¨/Èò³ñãaVÑ1°´AXèÁ²óeÇüÙ¢„Nâ÷Œ¯¤Ï”€p?8å?±¤íyæÙ§$aÊìšëtôo{\Âæ:şç.ê'\§VVhì{¡iÔ7R£!ß‡†À"¡öc®¥JCrêÈ>íŠ¯XùCš—ı3Ò"$ÃÕËá@JLÁ›¡“&K2L,QÚİ…H\9²Àş¹ä¥ØÚ=‚ráŞo^*æ@†áÕ öh•ZŠşbx¥UB¶\—Ş‡ó‹Ü´è
*ZÒ:,•¯Àl>0hBŸFd¡P6…úsİ•§Er³b'?$ıçXNàUuTÙ!Ù² Ùe3şàN+(ò³`ËP	áB£„‚Eã(ûñiÌÆt\®òƒ›Y¤ì¤“OØ7ÿ³ÎH»”	Î¢éc•Ó¬XĞø×¨3j±XK›EËááË%6â\õªNÚĞZô 8å‘Ë"hÉ»ê"³ed©R@$ÎÉı€é.|\jÑr¥`Â<=7TÊÆÑæ†YIrßJ§W2üFìŸ]÷?¨»¾¨Du&ŠàC‘‹…ÔG~K«¶xõ¨ßg“#“òweÒĞÑj§lºKĞ²2KGYMnF\mFaÎ#&­Îë^>úyeéôÏXm†3Ic`;¨Ìt’Úè€ğ€H7{6-üh8CÇ==¦b`»¼ˆáP|Vj^Úo\¬
x³2mÌ‚á`sŠ“Ù »¤©5dLÚV}t¿,3g*f–s2ëqéÎ±4”ìæ¶ü’ ,«³+uK®&ŸİÿÜš¾ø´JñŒvúJöoÇ¾“¿şğN(^%~æÅJ“kz.?GÖXrÌøÔcä<€òj<êÈJ}oĞ9›˜kªÿGƒká›Wî½NOpùå7h#”5¥Áâ[ ²Õ4)BãIVavˆ»Ö„¬J,v@öŠÿWx ›ğW6İ%èO#QÅÜ=İ›jÃ\
€°•÷€¶°fˆnb(?Îx1×¿s]`%—˜zÜš—Éz˜m9chDÀÉşBOv›zlø¨•$,L[ÊÓJ–şÊÔs’¶Š˜d…6+ıæÅ¶ïiò­Doñ^«KcuVãÜ'W{o’CZM¹îD_+±¶ÎéjvØÿe¿µêdTÁu$&{#‰ëAŠçbøAŞhKb˜·‘€CV§ùaA¡ö¢^pšŸî]«¡½Ìv`p¨ÎÆˆ¡‹Ï4õaóãÌ5|mîh>Îøş6ôgV“¸õŞ§ &@¥ïÄßÔ¦·@×$‚§±dĞşùê=W–á–T¹Ü€€ bM”†+›äÃQƒó¬x®lF°KÁ†ú‘‰à™xA“Î‡øœçõ¶ßÒr}FğR")gSĞ
Â]	f ÷ºÎD‚RøÆ)N^=1è¬Ğ‰`#Ûë +±`bšË¸ñz}úêI]˜ğ-ô3·ÊIÒÔƒ7]—Ğ¢û7ê`Ì“¯fg	' äıt ˆ(ùã”‰ª°8oû”­í×Äˆ¤ÇZ¥ní!GOÌ{ò®iLñS=H–áÂØĞínÃ>lT]”¤ã’¢¨#-Ï?²uÄRf@yŸŞàšû®áŸ^óP=ş—yŸ³L4ÌË×š<JÜ oAó­}}F ~±Ë‘ ®vG ı6CF©R\Ò }?ŒÆ=5sšF×?d‚ñ''«ëÜ¨lC)PÛ½…Ràn¤cêD(…ÌçÊ«ŞqMö…ÉÀ?+‘ØU—×fÛê:J»ÍíŠí ÈäneòG.Ä'0åŞ!—Ş0ÅJ^Å-P¥ı´iÛÁÃú³İw¬&¸„§ˆ&\ñÍÏ¯=g°è„7ß‡Oâ»Ÿk‰ïá©õÑu—À<0áv€ûÅÿ`¦©OÓÊ^g6àWÏ=-{H“K`Ş–±‘?]u¦CwÚ**‘áR…ÀûLíÕıæµ3ËS›xsœ›=SUİ_û]ÚGï¸s"~0ô\s,~|vğcv^Ù¼9OÌìôòÔ»Wúñí³¿’Y²rö2ªŒ+<Qiõ6
OE¯k<Ó8#fHßÒx)lÓ;Ó×àK†Üà±Ñù§F^\Ïz•tzÿË†v^9sÆ`,_m(fXº¿Ÿ %Ó®ÍÁ–_LqKé÷Ğìwoà›;QâQ×Qwë:…ÿn}­W0ô~p)Ï=í±š0‰7Ï¦14d¾“ç
'?Ú‡{7¢ué»¤èleŞÎásèw|³ói(v52]‰|1E¼ÏŒØ©jøÛf‘¼”¤t™ÌâÃ†ôL£')ÔHfÅ¦Pn•"}kdïº5æ¢iã'£VíP°SS3­<#Åß6-´Ušq¤ÎÄtÔİÿ6µ>)Ì©#’HØÿ#Œ@æ®İR¼ü¸ß7-„jSf–VÙ+4-S9Gä†ŒRx+5çeUÌŸ9­ğ Œ£æhÅS¿w—ğVÇæbµ2½Ûå<º=dÛ»ë›Vc+íÜÒy3¨fŒ¹.ß[øIYù*U6Bs‹iZÖ¨Ã$šGòmŒspSw"÷£š¿Û…KEò=D{8YK±{mŒdudÒs/•7Ér¼æY$™jó/š®œí*9¹F+•BÊ	Ş`11Ğº1†¾ª;p.ãÑÖdòu¢cJŠ1©TşN€rîÄ;»øM*«uœé„ör¯C‹™+Ê-£m¢=r‹î˜Ê>U©š‰šuÔ"#ìƒ•ÆùOÓhçÉÏx¿dÛDMŠâhÎëÎV…×)„xyQŞ¨÷°Ğf]æ‘ô£ı«½AÉ±±û/<µë…Ãlşü-ğ0~@ùXE-Ç‚ıĞoV}$Ú­ÂÛ3i=°„hÚH‡¦Ñ²5TÃÕáéÏêåQ9„îpÅT¾É2)š=ç|ÎÑï0¥.şîmL’v!Úúô¦ j‡Õ­İ_KmÜXO5(CëÕøKI°+IMeJ%»3A`s‚CË¤sl¾­³¿ß¨‚Üšİò—j\{|Âİ:Â†.}ÔHtf-;’çJíd`1ŠcS66åßMVO-¹Š±QÀ]W¢úø²uxıéY²ÑÎÎ_×‰¢Ó+õ”­0‚™ŸYfJ!gZz4]LRtÍÃõTĞÈíc½1ôbtßFå¯âùı~Hÿ=³ş}ûb„
¬‚Ç|bE%Ö!Ê
ª³åĞò¾Ï¡ºô¦L¬9Œ¹ÙÄë;›ÍˆA«ó‡nÛ7F:°¹¦Ü6°3õ@½¢1I‡¶„Ï	õé{ŞM.Œ”’Ê¹Ä!ÂÙçÙÄ‚¯º%=8@b`5(nëKCé)ïİ8TUyûóu³ë0C\¦7ÎãÕw÷vúÍ‰µ®ÒìÎyô²ú‘ãÒg#(ïÜ*tE™¶™z$[R¯+¯T^\±7¥8ïOÏü$\jñŒ—ƒ¦„ºå\7Ÿ=Wjº¶%àêğ?{Dv–`³]š+MâÀ}xê×ÒL?¢£DÒ„}lwys'§|K6:BEíbœš?]ÁÚ–p>Œ(|?ŞtƒÊñ¹6ì*p…Ç˜
¾Ík$¯ß¶ëèE@_¢÷`x×3gÈ?‹£¦IAØ»ÙLH aÿ²ˆ;] –ÿgÛ9_ëVï»*Bnş3Bx¯V™³È¾ÅÀ§ç·ÇUÎ˜FıCêê6*
	°^0Š“6µpŞ6¨ÛjO™bİòÌ`Ñ í½Bù@ 	OábEÇEË:³˜lÒçv]yŠÅ-ş=Ùß§n9™Ğ,âüıÎ¨Cf<½òî¾,(Iò1…üäS†Jdè¤—ˆÌ²…ØV\¯ÏÕFÅú3ŸQøgpJ†!ô’i„Ğ÷‚$}ê?—Ì‘”«tBØ)zz	I$¥y”gÁ¶¾o^ñ ‘ üv­¨c­/NŒN·J2¬=5²¥µ´Œ‹i]ËÖo
wš"…*…œEş¹íÈSCÎ«6I…#47f„§Òy "=ä —qÌ.+ó©šæüİ€¦sÁ[Dv¨^£Üm¸gd"ÅPá¸&.ŞVÓ³øiºR‹cvOÜ^<~`ÖÜùJp|!Ú‹_YÜ¡¬É1ÒòõÛ<³ ÛuèV	‡Í	JzĞ-ü­Ì·¤5›¸›Dš7Ms"'BÏû)‰#[ê{İ±²ä„(n¥ä3¾¥Ï3‘HZ1xu³F† ó3¹g’Ål:!$¼6:áÎŠ´D<Úl—œyñ²qâ{¸ê=…&¢çÊeuÑ—ÿFZ¢îÍ•´¬sÑ
?hŠ}Cœ~-e÷Õe[@)î0¤C0š³hLØUŞ<6ÈSX¡¶
Œ<Ï”úô)°xDÅã’« ÂXÍ>‘Š7útÅ–«çõeÄ#æ-Á‹Êï±:nÉpşydâİÈ@mŞx…œáªÃÈUËİ¢ƒRK"gH÷?Kö½yHY&a9÷¨/Ú¿NG+×u‰Çdºâº¯§–¿?ÔŠ¯u4_S¿¿
Ã»;sj„ïÒz¡!‘àz4úŸ¨…ìRZ.0åÍ¬œŠÈ–õ¼ÛÆõÆ¯hF
‰ÄäO9ÆÏ?,t¤ˆÑÅ9ÿaäQXˆÄ4±EÇã^æ¯¨nğıtO˜ÅzXÔ@í{P”ãmì»!3»õ"Y‘mü‡w¦„Š˜3HwÿUû¾@Ê õø˜ír6+’9óçÒ­q›Q‰Zé2Ù‹òšW›Ön¼yiÆËâD4ƒ¿p>×ƒŞ’Çï^WP|»Ÿ‹²4Z0½¯yç]ª•X	vg_ô²ü?õ©›BÍÈ! —öß¼ºÒ’lù¥åfoËÙë¥yÁÁ÷½Ó½LÜ%9-òf“S*÷%÷Ñ”„µmaW›ÿÓ˜b0«ÔeHèÑ‰p¯¼AK&nÀ°-Äõ1¼B˜.³6ÓŸ«œµö
v’~÷}K½íıN3 ûä£B;µ+õ]mˆ‚µû<ú¶ãó(ş4Gµ|WÙ¤Vy&/B¬Y-q· 
 ­ÚPğô-Åo’Tª²«O·;t8D´-="ø¯šMäF¿Á!<XVG2áMV.Ÿs¿ÌÖ1‚,5w†ÓÅı<.¯Õ~+p¨ˆÌ{jiwG˜–Ôoïäüî¼	Ğ#•|áºLË²,·!¼D¸7ëiğJ ]q§Ô@BK¨`Ø²š£2?¡:±Xæ%HÄÊS*[>rNÌ•WTlëCDkNòˆQõ%ªì#’„ıHw‹ZU5­øpiK˜"e)®µš:“ªƒz¹KŞaŸèÓ#®_k<‡A£´düÚìêïY”®`¢iÎá÷Y0hn¹"ÿØ
¥|î	ÿA†V6äŠñjÚ;_¯´]Ù»ôu‹ÜgÛHf†Ş§ö±82¶ãªÅaĞkÒŸtï•:Œº¿šÌ?dAıQO³?ÄŒ½FTnì÷š	3q¼$š9¹Tğ&FÃLÜöp|âB¢+	bã¦®Ç2ï\wœ<Ÿ &Ğ«!Bû–¥G`Ø:ó´ ¤‰ö	§±]¨%
©ÃQé
'­Üî6pÿğ^x—ß‡F¢N#^1ö`u6ŞN“¬áôâOvjusWS@4¨\á„‹&6H“¢Ö'0LqÆ1òyzÔJÔÀŒWtÚèÁG½æŠåI\"3Ê¨}¨çÕ©€<?Šd JÎ ya×ğb^Ì ™=-n9C•-ZÏÃqœqğ"sMqk)£€6¯<vÅF¹oˆ”?Ãõª´Ó~o-)&1á˜¡¤p¯ûë¹ğ»c5ÂªF©WéùˆŒ12æÌÅÚ4S6¬à‡šGSO‡Q¥:šM¹ ¸şJÅÕ‡YEÅºİ´+ùºIÕK¾­Á™¢Ù`PlaÁ0ÛèŒí-G3V$â6®Û­p6`»,2¥óÌïa{è¤Šè¿¿îxª7ÂSU;”³a’Èf$õá‡„ƒµøÇEú!Âİ›9¨ıNË›ÁR»n³îm½æõ°àÓXzµYÆŞ qhÆû?ş-ÙÍc]X_uhÏ6ƒ$gêrjÌ&¤ªæÆ­.‘Ád8+í$}ZØX¶Ëî»—ÂègºöJ,¤¯‰DËÑ¥1²‘ÍàÒ[h¿-ï¨êV:pÆ¾‚ólçÚv+lÃô£àM1ï%HòéM-·sœ;V©;óVhƒ òB„>á:E„¶‚ËïÉ“Ú¼Ö³í(»gê@¶G¯ÄNÜ”­¨_É;ÖAw(–îÉ¨Gjäi{ë*±‘;'–¾¶ôo(Ì©­ê÷´«ŞÇÉâjéÚŞ	„Ğ›9I]‰t@êaLìõ¹hG¸/İ,î*gI>bö–_TAõU(Ö`¸"BGÌm |’Ä)7ÈCE«5õHK‘DŠaø=°»åŞ÷·K î±ë Úÿê†üËƒŒ³ïÃDòkhÀ7Ö‡
R¯ax23ÈAàŠ'Ù¹88ø÷›-Ï%¯)OöËd†piùA%şqàıˆe*Qáÿ”¥0äÂ3/ÛR:Ôú{‡ZOÄMØ“6Ù­vD(‰]éı¡œ+ã«³Èÿnâ_äĞù“^(±/K÷=(fx@´ÇW%ïoiBui)ĞÂ-ºÄ@&@¬¥P%™$'¿§'ñof+µ˜€Å÷z9'|2ÑE [=  ğ ,†!–“ıæ
“˜øârò+AæLùÊÊw=“{”B6îÃ3Òš$Aµ	½Xä‡g—L[†	ÄPÛšY3//ÛË×]ËÇq%æC}Xœf‰š$¿Nò‚MõàP@T¡ OC¤’/oË‡ªŞ[	%5íF€Xà¦PdĞmBèï¸[V´5ĞY;:à´ÇõËäµÃ|{€7ÓSÊ\úovyq|}ù?¨¼wï¾k~ôCMÂQ<Ùá µPÁçQ 4£n0‡q^ã}í°#_Ëñ±­‹9ßÀRò2
Ü—œöÇJÚ#i@6ÅÁgKbfüëoB0ÃBxU3áà%X2*çñk¢«‡Õ¢"ıÊ]-zP ó;¯²ÃQ`*wùd!S4®£=
±å
«¹ú?FHfÛÓì&‡ˆjìX¤Ñf¶„ÅW*rÃ‘)îñVF™@Ó›u™Ë–YÚ¸S[E¦¤¢È÷$İuRÓQĞ;ˆèöã*_«¯6:œƒu7Îé7iğË<¼ì /™Ûg¥uC·Á[Qj|_RÕ[$Òêö`?óÿ§üåª*ÚÕº_†Y¬ ­ºwıkçQ…]Ğ¤¨ØªÈ”©*'³ˆ²ÚIsÃôXÆEB?lå8KÑjz*æbèYJ2­Sf"ÄÂéºN-Ü0Ge%¾×Í úZ¢P.Àê¬şj=ÊĞ´
^y†U±ì?·Ñóê±2“Í–Êù¶4±eQÌã­ 3ìÈ¹êÜR|l°¬ív%6/àqüUñ5fŠ˜Ál(Æ¸™‘ dÏ­òïÛ™¥ »Á5hy]Ük•‹İ4ãÙZ1£ƒñpB(‚ºªê,Æè¡„kŞ8Ö÷,İ6Qf¦¯Y1re˜Üç}óîõÕrÜ¦Y}}Ñ…Ÿ ®ádb…¥¶ëló½ÍÃ„k5Ì}¶uå1IàÿÃı5#$[*Äo4‰›
~¸h
,O´S<KY"2mf,v|%—AİäÙY º7™4Ofœ7\ùòæN~ş‰Ü1Œš¥"Œàäà‘è½rì‚üºÁ¹e›Ñ\š;^² ¥ŒÅE7·
†I°0eSHoW62AL]Gƒ³#¹±		şQ[{bœ„âşn‹R°šøÒÓÂå(`ošÏéÕUÎAõ9i²y"”•÷ôv=¤XJ‰m¨Tg ?‹+Ä“¢ânDâJ«:3®úZi¾ù3é›~«fgÙN{ÂšÛ¼”#_çÀ<œ h ÊÕ µ¸\Œy#ÍÖ€?—\Óõ7ÔÈ“^l TägµûÕŠ#>ß÷Ú@ş Ò“©ıf3Irª.K lúƒb1÷‰—?Õã^Î¸ûò•«èB0]e#:Ò*t«¦ªÉá £§VÚö•§æ&HÏ4Wÿ?Éz"£öÿ^›ëä• Ğ0îÚ…=DNNvBÄÅ{]‰|ÂQgˆêšãD~Ï³+–U0ÇÇ¸ÁÍ´@vßÒŠg[¤ÇdV›>Y¶tÏCZ*}60-Dª—SÁŒ6®¤@m):ìù- œ8½)<±¤ŸYBšúë=<Y%Å°7Em¤q®ã?Ê=ô2|Öä²Øób¯emüå¶‡§	µZ L1?î™xxD7ºb‚éİ®ô>t¹w¬“LÓL.»¶öÕŠ‰E·]‘Û©Tü¦'rrˆ?µFIDª!,5¤ë¶Ê·k ZH@‚©³¥Dı¦ºÉ:Åkß¼Øü£Òù™ÔV……ÕÜZ	Ô'Cø½QâWŠDÜdïØ<¹Ê’×sgÅJ‘"ià ÅŸ³{"Ü 2œrGé€)0¼à’¬¬õÚşg;ÓÕ÷"kşû\®@´CßäpüÙOÓ.‰QòÜX‘Ÿ†Ÿ üÜwJx<U{zJ;ÎĞ;Ô½À³ø\
Ê^Ç3RÅÃ$1eÖw§}UÊáÊ5îBåh?TïAº=—‘qxéè(sòkMø*V`‹x	ZºÁdã¹b÷äJ½$)}<Çù«ˆÂòÓro¾í6mIÔ\€Øá«-˜ş¨ŒÏ¨D\£7ó9+ÌİU Ï"f~û5.?À¨]zÚİ&3şÌ¯îT¤Ÿµ[µÆõÎ¼S-o]ñ¢œ‘V~e#ğççŞ5õA‘“Fàœ5¾òp«`-¾y6™º¯{±í˜y÷tØ+¡åì«rØæ3{ÈÓV)õ-Êˆö•zÆÍ¤CÊd` ëşœ×
@?ÍğÑ"-ø’	½ï‘…õ\O#vÖ]%Wã¬VúïF%·Z­|o{ÜKAÜyGqÔWÓ}Î±Œ/İõŞÙ¼:)¬}Èq¦v§‰mÁÚ!Ø×ë_W*¡¼0ÁhH¥€vQŸ}wí~Y£]”ğÒ»­,$™`ú©|Ï¡bæĞ…‘ú¤”ıCºÅ¸+®ó!R˜ğBC=W»j6AÊŸˆÂ˜ã*=/ã0;ûÃŒC2ÄI?&ëk—¦7EÚcy13y^æ•• O÷ş”˜°UyK;“fAXŞ*6îp½6ã{	+é0ì¤ğníµŸ«ÅÑ½ß dËmÔœ‹ Úà¥ğ9,N–&cÉ, {P–!F4’­lÕVna¹GÚDl˜V·%®üÅ„^©}İ‘O±Q	'¶3œyšYgé"ÛÊİÓ94ü×c©Í‚°2%œå
Ë?ÚX3…º?±‹.e«ÌP½ãg$™İë¬ÕUuäğ©"=Ø¿G:i½ÿÎ4ñf\DNJ‹ ~uÖÒO¼ËvZ—ÆØL'iá†¢øØaÈkï¶ÎÌ’g©&·ì†UQÍñ}£†¶AÕ¯	X<À{Ã¤MRòÕô×a8Ÿù‹Â« Y$¼ßşHÀÙi°(geşf3$¶¼F»­5¥6Ï0Ì»¡ø åheà_
æ9P˜'òù‹Š9gÂ.ø1é0ÚŠ‡0±N 5)ó'·¸ÇÈ’Ad(ïgVşAûÎ=ğVey}-qn{)Y%÷—eÀuĞEùzÌ1[¡x„†-'3iüx8#˜•oA0ÃZ«Äc® OºñÙsğJd>ã¢˜z}³€Ò0òOâ	ÔŸÌƒD°hâ‘îâ¾Æ¯®ºò‰Õ'‡ñx·¥²,0œû£…ø¬1ÈoÜWP¾QU¼ÚÂçO¥ÏÚív1–BX
hctÁ.¬$+Âıë§÷¹8=:(ïD»š5ÁhAñı”Ày?ó®ZĞPš£.2qBô4
ñûi.™Z¿¬^"»æiÏ×ù#¿šÉB½±N¯*ñ:C1Ç`õz°³m5s¤€Wsb‡h`Ä 3ÉŞÄôm‚ÓŒ‹ƒ9"pÑØ†tuµ$¡6¾*¹4J¼xŞÆJÛ²”¾Û¼æwµ†ÈvxÖ\.•ä2Jé»˜ßÚ	¶ÌÙ·O¸dzŠ^®,vTİàIÆèènB¥¶kÑb<Xkì(©,ÿUî”<’¨:hæéş—zØ‹†L´X]ÄG3âÊìŠ—.9{šcü¨6ÂHU…¢Lm>X´%úI|…èûX±Mg2^¤ ¯·kÒ¯:üèî¨KIÙ4"ào»bƒ’}Ó»µËşÛ„°@Ñ™é´»<Rnø nf¦İÎ(w3ŒwN X˜?}BÍKK{î˜&òj9¡Ëæxy×“÷.#0Y%‘Úm’T´IY®HK…á:SóÈÑ–«æåéÄN–0àùPømmÔ)Éñ²ªÊj:|N u·VC w1i"kl­L’½KúlŸ¾»œ!b"çí:”BÖ$—E«»SÀˆ?m¡Cü4L@v}è²DõË×C®–x™†@
6.üšz¡—‚¹—"G]9D¯'ÿ:Aav84ÂÒjávÌ/Èò³gÂ¯“BéT½XhüIO\uŞ+=?İ²»/N¶
&§îµ‚ÑvÃaÿŠFJÓÁ	p¼5ÀÎİş¨=­ş£­ÿ–»çGHgÀQö>]YïÂhz04èIgq6³e3ë—«^ÖªhsX Ğ˜Nğåîcô ’ÿ­iÁ—ÒÚô§ t{¸ƒÙÕ§¶ãr	V7»oæ’$ºıŸV3øÉ€İ6rtÓéÖf‰¨[šª¿‹xxƒíiÎÌRf6—ÜZpÃ'@ZŞ€äâ«`ZyO­M†¡^ÒNvxá~Jİ§’}P~˜§Ñp]ÆıN?âíåÄñzjOÉ^Å@ËöÏóŠ<€çRêãÂ”Ô)O÷wŠ­İÀ˜D{GÆ*yUá¤Ïvi˜¥	Ïè!£xHÒQÈ–ÜWûÊ_¶ÁåÁÒc’Bï„‡á‹Şè‘š´Ÿ
‡¹İg«>Ø—9sb¡¥G`íİ¹(/DCM'¤£¨€ß¢98®…„#Å€Ÿä#hu¾Zt»1’–·e§i6!RK"lêÕœÉ	NNùÒ%zŒÎQˆ|Äÿ?ûù©9¼°>Î|\nxÄHIûyaĞº˜ê	-"#¥ )íl©ÓÔk‡jÇOÄĞğï“Iâ•Ö‘‘ïÜQÚ_Cèiï”æÙJi=ÃÀ4şrf½2£Ù¬of˜Ô@ôE¨fF¤„W}Z£¿‰n§ViİöQMÂãhü}Ì2ÇƒÄ¨M2AÜ]6 ŒAãß»øğ‡1Ükw{†\ñÀ¡p#îùk2(İ…’ÏæÎ Q)¹vĞRß§sFçN"‹—1x+'kd
Ó°ÂSòùªúR¿ŞR8Ø^ĞÕ×B¨üƒÑ"Æ­b”ÂUï.šò§æ¼°ôW’<£}Š1ÑNÚ,ôÖq{`_ó ’`½´˜ıG¼¼™7\è Éòœı¬i&7Î¢Ÿ6ßªG­.’º >¦½†pá—£Í]ÿÈÆ³#±š>FD¥v¢1²	™”•\¨€³"âÍì
Ñ¹g É¾iô[”^Ém4¢ã	ë!;‡+>Øìƒü`J@=Êåßö=j%5¡aêÔ–y;
~+z«`cñ|÷ZÌ/T$*;…œ
ÓÌg/ß-ÜËRÖeBVÄ)SÈ«˜şj¸*3›1Ò2E&št‘}›ğ@º P7¬í¸d¥c#üÓò$(BàÂ&ºòÑ4FŸ¶h$x˜5ÈFÚ„ğë›J…K7­ÌZõymM»›&5m~Ö«õÄ¿^QWpù_'ïNõ§	*ÑåpÔÖX¦½øù¹íüšTRz>e+VûTd`\,õWg‰ÕuÃ0á:i×¨ƒò[¼#ª_à§fòAºü2!JséÚŠ!)À1EÄP ,	§5³Ÿ¼âq%uÄì­çìd¿©áu{¡µ3<aİ¿.¦>ùàóLñ·,à¡eîu·í¯’Y¿Zºœb=™9c5&Í·_i¡Å_-vnÃ¬ E')h¨Y.L2CrT)r3r§\™zèÇx«ZSoğï<ƒTa©­·sØØëøÑŸ,NvRÖñ³!´lmdÁDÏ_¹CxÅG5Æû o¯k37¹â3Ÿ3ÑiÚov6#zèã]¼ª„C¨_íéë˜¢NËZÊOh#É+*Ë8µşÈ:»mÆbg¢Ášïxêƒ~&îßd{wÚñ÷ \ùÌï˜
uw„ZÓm=Mİíëı×1ùHí¹öÎDŸ™qÿ !VAÔòdEøüMleUZ$} c¿­ÍÕ-–ñ4óRäìøâ©MäK9Ø¸d ³y–<ôü?SKkÒ2Í×o"…Š›=´Œ3b;ÑÊÓ3¦i¡%TÚ&6qS—÷Í€ªï¸¡RLCãó~¼%¿ä¶ÁQIÈX±*²ÈM#ŠEœ—#ıt|9íBší#6YÚİ/7ª‡lNÁPòXÖb.“Z©=˜©5Ğ¬4_<î¸„³> °c!Œİ$¤d~µ6[’vÈtAıÿÈ…Ç”‡.ã?Ú,2PñÅõ Wƒ¬ƒŸ[m4ã-‰#ªîûß¾êŸ}i]YôJçb<[±=.jBø¼9”ºŸyBIÇd#ôÏ ï]˜õƒğ¶íç£ Ğ$1ûtÛæº²ÌÂÌ®C‘/•9V’Ûu™èR	CMøWuğ¼© ‰3ïØg¨£KßÜVë2K`)‹V„õÊw"üÄĞuz+•ƒÑ"G˜­ÈñÖ*¡M ¼J/©sLø¡%RíÛZØ—ûİ·u:¿Äİœ>Tİ|ãÀ¾80©¥Ê™—ö“äq<*v_Z´'éããÅ6ãÙÿ˜Á=e9 dqpú?PbÏÎ¢bÂ ¬×T‰7L ¿¬„mÃeŒscà¥?Ä¢Ôx»Î.­8å QwWşî‘dÇåÌ¤ZwÜÔ±Ÿ©sb†¤@…ìá =ú Gßä1 1H˜õ< ®.î€M,Æüà2:ıà„Uº´¿Ÿ¨”ÿ(qã+m„Áò+³7áÔìR]ÙŞŠï@’pÒ:wÎX35&÷Š— 	õ_‡œá$“Àqú¹ŞôÚŒ7_XĞVö:ßŸïbê¨éYµˆ·ç¶f}	íENú ò“IÌw6`BP›ıMÜx­~‹6Eq4<–Ğ$ÛEUÇ‰U¿	×ëÃÓiÓ‚¸±şhwÌÛÍ²×g¹K±ëEıµèÂËUe‡ıYñ#¡ïêğ^¿L>1Ğó»¢´İ.ÓÙ\J.à»ùó‘Å1&¬!%Ê§ë2¼|íµ]xÉj£¢£$½ßÜiMäE¢­¬ÈcÒyÓ€½ˆ!ó‰W<àš¨Œù mToöÔ•á4z¸ÆõÜÒ.Í®Ôò}òyÄ |ì°‰
ºzk:¿0SŒ©MŒÚ±¾öMÈƒ£9;{tÌB_e_ó¿¿±òìcåÑº ‘ñ?¬î¨‘úK÷½.0Xé×Şÿóğã›á=É˜‚c)äîiˆ«92uZæµ´ ßòD˜ó_ÕXcJmÄí™Ğú­›22„üÇ/!CÚÖ×ÎZúÇÇ®ÑYDë… .Ù¯°Ú½ÜGXÌo©¤—Q Aie«Ô­êTşØíuo´æyç6ÖUÓ/î%W#ÎàİéŒæê™Y¡†ÙZkfı8€¶*XO
Ö‘,KuĞšÇóÖş<aøÀã…{N5t»#©óP‘ÉLJÉ[«6:|ËµIŞ´œ]`Ø[»Aj¡‘Öêà§šÛÈJÖQÂÓòc@Ä­
+tÏG	8ô—}}âIF3áâí¼„Ì'=?ßEö/K”İSõˆätBS¦’ø1ö
Gº%K}‡ß?D~6;j‹·QZHÑü Ş¾>s†$AíkÃÿÆ¹Ä`áîí…%Q!¼IIâ.Ò.z‹¨7¡'½¤6š>×[|\SNö16r‘¸·6Ò9gÖ£Q†ØÈmÓt°úÉsÔ­o~È%ò¨ş†,¾ÁGé—‡¹^¥ 45]­ø£=ùnÏºækF¦{(ì'ShôKÄl£7ß¦ e²æ#„ê×¼Û_M›'Í|qÈ]K`^[jdÎ/z¬ @EåŒšÒÇĞç#‰†¹N«C"{©‹!‘/ï€3ú¿GMvÚ€œmß]
à`í":+ÇBÜ|¥§ºr‚ƒ©VSÚ¬¡FÈ¿˜
ê:»´ÌÊÀYg›I\‘f[Áæyşé¤İiì‚EÊ˜aªØ,Ó‰8©H5ÕqIk¦Û¢/»•®º‡Ü]‹›’‚æ)İ}q^Ó¦lWßYË€uG¯®º9lR–tæz’ÍÁ“Z~†4yeO7A›¶2ŒÔ›i'Ã:W-amÓ@šr¾Êm¿E­Ñí¢´ô0$ÙH8Ç§#“h
°îár‹µ‹¸[qÍö,oŠ<ƒ<$=Fo)Ãùöøœ¥F³*('ûÑ R ¥®LôUûì|{GpËTOÓ]Ï~]¸8.·)$ıÖÚ­½…—G/ç	¨ÀåD1S8EzS_ah¿«i‚µc
İâPwäE)6{n®‚ê`9b5Ü'Œ£.«,e}5!"ã"lí‘àr]B¸‘xÎ¹²-v!Á	:MU•¤F{{EwÈm&èiôşŞ¯"I^g‘ØA¦>Ü`ò.dPî]u„’kÿ6ÄnBZù–iÅaµÌ÷Æ´ØË'è¤wÖL±Éüğ:f^˜êóÒ{0s@[-–Şy·ı—ªòŸŸã×oà'_?ÜÌ2ÑØİå¡Sf<îW­ÿ«Àîè1êQÈiôç
ƒ3KËGjM…=É'g7¬Y‰’ ¿Õ‘ú´CJ×¾ôÇ×óšpğ-Á·u¾_çñsË;«V<Îë€‰´}´ƒ>
`”¬ËN÷ÀÆí§n@[Uøk‰zGœÁñ›jg:}FS.W#Z·#²#ôPİ	d>yÖøÏÉ¼ÍYÇ˜õßNş9Quâ·†ÉÜ@	ª¹›®;.h=ú¥YîÒínùñÌºËcqW{Îa‘`‡7/\Ïâé³TØwâ47îHı#p?öuÄüÚhÍ¨=ş×OõAæ$‚±Ît†k,¡R5UR¢ K£¶’<Ãnï(vRÿs˜¢ÿÒÊ’Ô<£øŠÙ±ˆB^õu\×HĞY^Àz¤¤¶	G&
Âñ˜Ìç>v+KI» kUJªOe»Ø-áû6k‚FÇÿw‹×Rº]}ÃŸÊ…ÉdH¶Ër>aM¦ãY«±»=ju^’:”DÃÔ—ı»İ&Ó´³“„e®l°î
ãæÅûg& öpÔ>%êĞà[Š$‚ø{eÆI¨Ät ÔßXaa{øwY¸¿ës–õIèØNæcİ{æ%´“úùæ&3ÎÕ&™Ÿæ³ŠÿïİÜ©µØŸƒFííàÊ#jf š OgÓ¡~éD ™Ëw‘èİ¡è5œç€`Å|®`³ïGDÈ;÷Lô»ç§ÌŞ÷SEº¸ND¯¶ğò—¢ƒ…vSÁE^8–Ö)*©•â”îr„dä°Éˆeã ôüwô$[-}²èd¯5Şò«(µ4ûÌ`³)Ój[SE”+&P[x9ÃY*YK¥Ë÷M~×&]•Ø°S¢ï&À~¦¯îÇâ‡xqØ¼°Ë×ÊÎ:WDÁ9ÒzË‚SFÏşÎk/g(>\ËJhÖ&lMåPªİÇ‚IÍÚÖ‹ò¢€)q–UÊÛ¯àŞ€2çc}ğ.XR)œZJXşï’şÂLL‚éŸø¾KM‘µğéß6üãi›å_›&||Şı<z|îD]1Åê;ÌAìw® oùZ.OXõ‰Ü74Ş³fcÅÊSŒÏF›r<Ş(£”>)ùúğY¡wô´Íïüs„_ µ®(Óïş&.Ëª×Ó¡9)Õeı H@rİŠFVAŠÇKÚúşôÓ)"åj{İÜuuIh3»rBÉ“LıAÍìY‰ÛÃÅ™!î^©}é=ÅÏWâ%8µqDïnğ›×;ÂÏÿ'MY+w2›#µéx[-Öf©_z×7±Ë=Å=.Ñj#fo¼µÿj¿oş@â¹ÑD¸ìT‹GA\“ËBÈ_© i‹DjÀØMœSVÓ[/«õ$N<]D™"²êƒ,Ó¼÷)á´›ÚfKêˆ…œ`$/°Û?hD@¶õzá¶´b/¨Àí´>Ÿò(z¬ç¢ÒÖ§‘×ëó—„/¶ÇøîÈˆdaè_İ”a2(-ĞŞ\ÏzŒßIºc¢5NÑ\†Ñ'Ş_S^±½ßK<É¸X³İQ‡ïú(")úó2—´Ah* Ìo2PËù•õhç‰¹ô¬…ï–FiBoÚğ’¤>MºèÌs£—ã+š£±èìuruï5’cìşıüY¶¡`ñïº…ŞaÅàl\lÖòğ~ŠQÊ¾ã©cemßºçøS7‰1ËÑˆ§::ÏõØØl4¿ÏzÈ1ÜkhOÒÃ?ãƒ¯ j6ol/ºéN<8c]Q-ûèö©>Ã3É”µÙ}³…Ê—7ÂÚwÊ·p@‚ÿNı¹Í<Î¢ám£:….Û`8‚{-eÎS9Dmp¾K$×3zthİƒï°c£€x_1Éá´ßğıHm¥¶®<îË£šñÓ Ò‰V„¨Ë»ÍpÃ6¿Jwå>ô!L¯g¡GˆÌØX¿Îû¢­*ŞŒ'4…‘˜¶;vĞËòit‚Ò«Î9Kì.½½°?kGm!1Yfñ$hÔkmbcËóÎÈD•k•‚lŒ9¯ä\_†Ş˜©üœhßæf.Ï—¯TØÅÛÛNª~35ë…UÀ-Àåf"/:¤¬<àf¦¿°û]ş0—Ë!E&YÊ1Æˆ˜7Ë§ÎğITÅTESv+—Z!M‡f±ón™Š¶ßşY‹aÀTİ¨l‚-$¤8i{ZƒæäŒ¤¿Ç]Çío…:Y›,'Êö¢>ÏAºë¼†Œš
Ü”ÏşFK–°€ÇÅ°Ùmd¯ºõæ`¹£jâG¡ù§šÎe2*S\©æA{&Ü´Êpç/W;î=R¨äªŠNXï±Ïy®aß^+€Ìîrş¥û#İèhŞŠ¯ı(–ß]Š%sz€jï2ª.úzDí6óíâJAüğå’Ç4œ&S‡¸${DĞ]§svİ*ÍeØºóL,‚ÚjlÌ]ÛĞ­¹ ×01‰6ÔSx\ÇÄ÷ÃCğ`Ğšæ–Ä¿2{) ue‹õª<kOtV!	m_'¢f¼Í‡-Ä_º“­(,a/ú@ÈÆğdïõôXäïN´ÉUŠ>^†ºâÙëíŸK>îO*®|Y<µûVçÕÊ„Ñ(9Ëy éŠƒµÇíu8¾1Ò4ºxáóëâişŒH:mBœıY1<‚–
óªü6 "ÄTgÍÍTœ¾w-N×½SÛğeıT‰Ã›ÖIX÷2
L˜ƒrÎ
Â?ÚĞÀ¶¥âğ¼F %C2Wr=–”7“@fR È$¦¹şÈx—/4ôè·"kÎ#‰óôŠ%YA%©VJõ$Óh6)è+K‰ŠÆGæH	ÕÁ°ïå¼×î|ÓDõ§ëåû‚ ˜™¿u‚¼	 J×àÂÛÉ®ÙkÊVÂ¿f\l~³æ×ºÅŒ«»Ï¬¾® Ş:Ğ76NNŸu…ğYWTûAcÌÇ¦«û"€Œ°x>]µ5Uâ±eeÒGs+ÌÑ=ûé Oş3Ì’ã‘ôES5]şjĞ¹^vbÜÉ‰îG‹SH uÚT»îœwüPôÛ,\Y®
[Ì:b¶}Şİ³åe¾qº.(öƒO9¢NJ”ÔgházÇÓğÄBX¤&%jçü+Qş¯9ĞäYW¤="NÂvÿïªwcK–Nê÷Rê§»ŸáÈFìkc=Q˜•Û_–i)ÍZt)D!K©ê¨e&"?^¸“ÖX‹œ·˜áyÑ’o¸a‡vsÒv¼5.Æ1Ş—¾Mµğs-ç©ãlgMºWAK°Ğ¯·Ó”Ç
WFèäì(°o»l"Ïúdˆ!B}ÖûÑšó’R?ÅMEOŒothŠH£E°ÌVÔè	õK0i|]hğ‹L¶'†N”´C-W7&ªÔtu„9-Š‰Z{m²ñ8ÔP™
Õ*B{c5(Îİø7ÃoÒ¡h´¾¢a«ˆVhåÖ@ÆÜÿ£0®–Lóó›Ğ#ìYú‚ig8Æ›ñSHŸ¹£o¢j?Yk¡êİè0·UåœckzÎÑûí~_{'¡Q¸­Dè•~ÓeÍdŸ(;YŸ»¨Úš¥üs°(çah¹w6Ëÿ¿‚‹I|‡Â	"UÄ›\ÈÆ)Ø†~FzğvŠâµnØh}“h"Ót#¿½£mV—ıl˜pú3&ÖØ`>q÷Ü1$KI™—Ÿno›B ›5t·ÏàÎyÅ`v%)”eUµ™éT’æÿÜ«$“zÚ”È)«¾Qü%G}öœ¶§LƒS
ÆJ¬)V“ØÖ"y‘Î³Phnu$ø®ìœ$Öƒ %(âïZ·†.2jõóıj„J³nI”‰uÑé¯,XnH•†J_‹]$Bgf$VGh
²÷»ÔŒ¸}“ê¸eÂjF<İûŒ©‡3±>oyVM#4êdfL"÷]ëIÆ¸²T+Ù›Iøâ_¤Ã™ô^&\<ê~P(‹L¢ÚxÜj+“¨^æûhnGn‘F¹V—Úkå·BÎ;$ì­Şb ¬—‹äšnN³’«Ôg¾n½ÄyÄ§ÀI³€ÌÈ’5œ[xl¹G¡2lää 2zÙf®·a=ñµp_†…öé2>®f°….«‰wÊ›ÜP¶ñæÀ»¸„ŒÜÒdœé'Êæ°‚‚ÇŸ{Ê——ı~ûŞœ®%€5rÚÅ øúºÃ¿GÀòñ^o[nŞĞV³ÈÂò­ö ëvj
è†u>Ã TóéÜ§Ùòª.´…ğëj	 |ÍZë KOtÔïÛğõ‹ÒíV5Îx±¥0ZÒ`:5,ƒÕùq¤àí'qRj|6;ò@QïË :A“ É=]ŠŞŠø¦SµVzµ×lõ5„:ZèûPÜöÂù-Øg)‹W$™ï3Ì¡ÑŠÚöµiTÔ6@‡Ï±ÈaV;„ª"ßú®½Bİ.lfú§Ÿ[r4º’+Sé±=aWAC
y`êÑËº}1ä])ÿª7pŒ(İ¼ÂSûv¡
£Æ·±1ó5|Eæo~úXéWW´ğ7ûqs™ŸyèL¥îàäßÙ?+ä†ä-¾1òL}o9¢Y^sùc¼ÅÕ etÌ9s(îôÎ²wP8VÔÒaf²W‰µıX“˜:¼ÿ%Ø¡pœ\'u´öò7ÎãiL*S™ÌwÍõ¿z«Ö9Ë'ø,vŞ•úDÎmÙwDå€hå°­ò›Ñn	 è¸üËõóøA~F1è«6P ™™£Ö>ôrmÌİ$>ˆ<B¤C
ğ)Ê2¹oG¹8ÂUÊfiHqLcòT ÚÏô";Ç v¿0-zC0]}ªïğÚ}¤ÕÎğw±Éñ»õãe$Ü-4¨FT“0`ï)/ºàÖŸgµêüFN9¶İ°.ç–QTÉÚ^XûYFeyì­¢…yõœDzoS9¸¦,ÁŞ3l[½3Ò ’è=ü¹µ FPÈ`­)ÂµF57Û;;æXÛS²:™>:Êã.0$¥ÎuS™PŸ2™•¦œïÅÉjİAL˜'á§
í›S1÷»µE+˜Ÿ˜üÜS“Ä}Œèq¹¬Ê­JÄ89IÄì‚¹7_‡‚|C¦©µĞİ}ŠÄÂLH°ö
ëAş'´•°QÎ5 CkuPNI£jÕáâ¤î)vÀ2=­ª˜Y‰úä¥Ú¸_Qì‘Ñùm0g]{Ê¶Ÿøé9%Oš½a¨Ö,Ô#ÒÖ)ö•›X¡'úúp´Ê¬Öøû(W¿Î•ÛS
šWÇòüğöB<Të½zÄ`èèM	ìàÇ&€nû½kFÎ0J”;OÕä÷ÈZ^kÄ¸¥î ÑÕ@GQn>ÊÛ4OB¢ªq¤yŒÑX¾Íz¹4s°³Õ"Suö’ğ†•îĞî:ÑóşÉ±ñôº‘‘RB
Tßœ§íù´?AïÑÂ“‡šÅd*ë™¤râô,]´5Ôã4åü¾¹_Ğ©~a&-ØØkëÌnÅ†öKƒEo[¼AºW®Ü†à˜•qdiÔbÖ´áx!wÇıÆ‘«hV#=µxÔ+>œz´ı›J.+nT.ƒŠ´q[† –Èå¿é ’8LİMûFQphÆƒ¸Jæprj‹|¹@Ÿ9‚b)Ù`SV¸@Tş/ü·Š–r-!RÈdì9Ú¾lR87ÌÃô§B|ŠRÿåjlŞh5ãw;œÈ1!×~ëQ˜Ÿå¿u”,©t03Â¸ı—Mâ‹A–rë$Ä#ú€‹‚kRÂ$÷Ü(±œ­¤3H !kÓ‹Sğ44i¨vªƒ éD‚Ñ¡È—ÏIÕ—òÊÙ®$ ?,ªtC”†FdP1,ìS¯¶ÌN19A/bG •âã¯H,22Ä¶'y§ae•6r ^w¤1•0ìkxÃOúÁ€4Ø†ZÛYFİAÁ6Q,fzçq"©=jÁí€LÏP_ü6àï˜GÖ9ÓÀìGx¼@Ú®­ì_±«À”9`‘+X¨§sÀæg5PÖ©óƒHv‚“]’Lö!äêBè‰Ä^6m…JVŠ… &A±¼±˜UŸBJÙ€*ú‘·ÚëŸ6”SHL)Ğœ’sŸÄ†“HÍ¾×^ìd…9RJ¸s
¬Œ½ôÚ`–Ö§“?“¾æ£_Ü%Ş£å ¦âÆa÷p÷MÈ7_‰æ_Ã‚LÃÛ7~“ÅØ˜²uŠŠàk»ÑzÙ@`h—C%_ö“yFŒQ8ÌÚÊ&‹¦{ÛÖ'Ö+‹6âå[¦‚&\µª–s^¦ÆFñ‚ü0¿ª¼=ssÂü9íPíÈÓ\Y”Å0şõ’0ï6T‹øó·iMBg&´?L°-G:¥Qî~;dp°êQ¥Şs<µ$S#z`ãM3ÍËégµ'U,'7Ñ18v9P¤eI}X12€	\eî§E@°¼Æ.¸Ñ˜bÁkë˜²$|\µá/Ü¯i ¹oHdÙWJm©
e|š¿«âg#1Ík{³ä6Âÿ[8àP"Cç·ôP’-¤ßW©^™öJWc¸n»Ú‚;î5‚R×âš/&ØNE{§âù¶•(!6õnPVõ
¤ùdJêfã˜ªÅÜÀFıŸıv¹±ô\¢‰›Ü2Æ’ÿ&¤¼Ûj¹`dC©Ï°Òáğ±F $!«ÕxÎ¶dÊo?h˜’¼¥=Ê¥n›m\Æî/ı5wurm9j!²njğô-ëÒiååÉ;kŸcµÕ
d™U.Á¹˜Wz£l*ó5ïı¤wŒâ¾ŠşwB^ ÷á×µ?.Õ¿îìşŸ¤[£İ \ÈaÊÒÏ7€ÃûZHŠ=C±LÛÔvåiÉúÿæÃE¼ÎŒ$’µl}‹?LË1|e+Ó¹Jeu4µ‘[îh™J¸øG öã6cçQÔÿá#ÉƒõM¿ÓÍ–O­LEÉàŠ%åí{„œËY·¾Ñ·q
Y–6Fú4İÉÓ³w0E¼DH[ùz?2Ä›$LìI‰Ÿj'ZTfúZ¿ÍÚ1êuˆÀïYb)XB(™8]('oN‡«Cáf…“>ÿ!”(Ü¦lú-¸òŒßyB_ƒæƒmYcğÑ“‹´¶c•şSÍ˜ÃW™[¦j½qîImaÎ;™9à‡Ú(uù6–İFéê»Tøq©ĞÛéİ}75ÉÒ¥NHG‚²T'(¿¥Ô.sZ´™—£zzC„İŠ»àãÄRn’÷‚PŞÇíú7„ü´§~lé~±«W‹5ëxbÃxa`ïzé”xY‚Ç¶æ	%gÒ	]ôë¤wkïûL_~ã–qÓŞj`ò’á[•Ñ‰ıl‰5o|´¨9-¥aqÒğÎÌÜcŸÛ­m… Ú-`ößsÜá.CÏ—>%-¯p}™Ùµ¸NY^¶aø‚I˜hçöëÿEs	ÉÌ*É0ñ&óSÿ¢”ÉF(ªı6Õï¶q[¸oÅİ`?lÄSÙ˜%|ñ–@EÍò{M:ES™+ËU%±—ƒ……¬XÖ{õ…‚åo-‘ìÄ¥—PÏ¸C,åîà u¦L"4Êœ„G”]›™±=™„îHˆíİ§İ×<‰};8E—#ª‚ ®ÔAp"#è~*ÍT©7 ÛÔ;¼P*$Í—°wuÒl9ÎÅ$UÑgp8± t“™‹*¨Õä‚6xM¥èZPºèŒV^Ş`Vó¯9lÅ
K3ğoU¾€AjÊ+k¼hmø;‡SD‹;+©–¯ğú4†"-ÈØ}¦Ä¹	§ôJÑ±£#P™`¤3ğÆ²–mŞîNjŠUêï‡eÛñ›]
şù„/”|xóÚ\ˆY²§:Eo°èéø¯*œY¼»ØĞ|62?¡[ÚvÄ ;½í\–ß¾dwnê#ìô4‡×¤Ùdœ^/šèG“Ê¸XÒ<óUe×Õ¬Ÿü@)1+|zÅ…”Ã­P„M~ÛèqïóÙé¦ª~gŒI@õÁ¿¡m3Y;WáÉB»qD†a×R³ŸLÎ›üPğO_'-j:v€[ÇMĞÑ+>xÉTiÅ®q¾÷$–L`‚¢¬D)hq.C8¶M%ğîböO£ÆºUN’%r‡°_×•’õ BJöh,	¢ÖË}•6Ñc+ßµDSÛHv ›E£›W)Vk¨%F*İŸÂ`7åèÜ3¾ÈúÀÙQ‰ğŠöØãüÔ$-¿¹Q„¿Ø_Üq5·6BE@¤­×.‚hUº·ùP·-ÃÉÄm [ı{úßóåÕ¼·QØy˜÷ G(µÈúşßh’c‘¡¬ KhæR|Õ¾Ó™AV)‘i¥{Ç¿9Ö«¯çzúÌzÜü‰lÒ¢«dIM8ãÒê•ÚÎõè?TsV0+œå±f—$°„(ĞµVœ/ª¯)ì¸èØÕõ½y“¡ĞëiëgPÁ`ÔO‘Ûª? aèL[mU¸°?§ŞËvÍ¨Ğl¦IlÛzúzDe]µÖ’ªüÂ‹|3QL>AªTKISc0?;Uí_ ã³²=ˆ+ì¦ÛŸfg•ÇzŒ[–0@ó‡Ğ± &¦ÿó%Á.l‹ÛåVI‘r«ÔçP±ìk‰Ìí#[½l/ÁÏápñg®Vêj?ëü8âğ”ÊJ¤¤Î õ"¬;BÜÓ÷®Œì³_?õ WÆ*‘¨íj|n%ÿ«µÚŸ(óÓË¯Æ·"(^—èÅâösº‚ÌŸ™à!˜9Kv„UçêÏ‘Ø×´eĞ,ˆ‘WvdÄ‘ä®=(ÚO¶ğ°P”IV–nG·ıu$
‚4Ù´»ˆWqæ‹YWÒûCxêG>ø'ş86¶º\g‘£*}ıc«;ª×:šĞk!á°&LÖ?|¾õ.bjË_iè}’ø®6ºë3¹h*O¡,Ş»P"
ÿæ)VJ´_kú]ŠYNÃ¿^´j–DĞ¥¨„÷–DLÃ7$·•2Bôe³ıvÔÓ·)°ìDA†(úö‰$‡¨Ï0†_’ˆ@î€§²[¶0¯ˆlŸ{w}¾glùaŸö,{		èO$ı²µì¼ÿñUVTFÀ{pBx.ù™ÜÖè¨Y~Nü,·Z‘ü+F´“Ú·aë)ì‘ş¼ûà>…O£§eyÚºtVÓMNK£ÜF«âÚÉÌAÑ›Àie–¬§>b(w~åE#8ôÒ9İi…C<V<ÚÄdÀÔp[#\	*õÁö‘¥ÉVlŞ’µVÉ*#b:ÉiÌ5\’ã%ŞÉ±~F13Q±æ`æ1š4	ªØò¤‡\1¤îYJ—êCÆÖY çuæë8|&Ğ”Xí˜^%Ş4÷Á6ØRhaŠH>$jóAzc·o^—§›‡V¶ğt¤¯mÃ\BU_6Uù[½]´¡Ä›æ­®A?‘›¡½a&¥,N×aG®.õjt·€â<š SàåÀ	d–ß¦¥Ì”ğÔy‡Ë•uŸÆCy	Òıı?½dZùKŸqMÖØx(âç»¢}ƒ}{ùq5Nz
õ^~D|­[gÍ)[z}oá)è©¸…v×aÿš¿óXM¸-Â6¯>¿(Z(­ }—·gê3â8ùAé¿K¡ÑÇ§Vóóc~wé¯“s ÚÂ¢ˆ'¼ïn—šÈ¦.Ü ¦zIr!¥LˆßhŸl«öÌ×¶äöŞÉ½|Àıóµcü¼(iş)äoµWI³\»¢¡WI¬å`èã¹ gØ9¢†ÜZ-Ã-– °MóóCBëñ×M®2E»ÃıÂmL…?ñ
kíU;÷aüå$Ø>å¦Œ‘qWªÚ]SbÚ+ÁŸ÷„Æ¿Ğ¼]$²Õ<aw‹ªúİ+â7&äüÈ"l2÷¼Ò-<a.ƒˆÄ>2èP~=Õ}½ÍMòaøåÏ`£€oùvüšÈ¤À½KÔŸL!Å¾İg–Qa>Ë»,PUÜlÇ¦-Bvİï!ºhâI¤İœÓ xHš¤ÑÙ#¡3Ú…ÍÙZÏÑ‰|f;Í|µD#Ãf®‚S{/:)°É1­.$Æm›G_ïÿ¡â˜ĞM¦h‡>	vÎnùì-¨>ë°¨=¾2ğ ¹ÒLq!F”v{òaìù[>C£¿†U2Ğ·ñåºæOï#‹M°ş“ĞLàiÜ7ù™¥®w<Âd¼¶ó!œÍ§‰a(_º’–8F»ÙºšaÇ•kÿÕ%T—‰”[F™
`uÉ»¶G¸acyqœ‹÷Ó²Š]²ü¢rgÊ›ôîÌGßbÜ‹B=xˆRû úFù$Å‹úñö‹£©ÎÚ[œpÜP‹””öÏ‹ì:ûÁÑ«]¨íî|Ñ=µéĞ2Ç˜"ZØe½G>›[Ë«…‡ûU¿x|úÅX¦Ã÷G8+–5¾Ä»wà1:’]ªÜ6~ü9¦Ñ,@ÀØHüŠ³?Ş¿<¥ùx=ƒòì¡æÙĞYİ2ŠW”ãrQ,vœ'•ˆméğ>õyÆ÷5³	âäEï“^S§kæ[Ÿh¯y#•WaTp,HRÈ@F.`Äíø¿"x¡}‹¾‡û×{D¯\ó®ŒtëıÛë†ÎmDû&:”yj œá8vc9
3-3ù]>ª¨*ë6'ß5Âc„İòğqÊçÚrxÄ…Z0„õ\İP]¤WÏ–ôæ|F
–gã˜Ìš,°Ô¦ãÁgo³¸1`Ñ”F±|´á&5±|Û½’èŸû¨Åª®IxeÛWı ÄVÖ¥ìz†kÌaD|ŠP3?«iŒ¯5zîÃHä={¸¶9{©:n„œ÷é#jÉ¹ jDçz @ª´Î“µô,íŸÚ5(éÅnùéc—èu8.)q·é—°Xë©Dz—×û=Ÿ‚v>±Jj–õzğ€g|V©Rß€ëBÔ»îä%Ğè§³°ì§ ]§Aù®]6VN ÷Ë
€ÍşatÌÖÑO£]öÃç²“4MWGúºï1Ê@e»t¦Zôã•¾Mjqä$¥W[=Ÿ"æJ'zŒY´¥ˆs¤”+—"OSæWtqb¿äAòFËÙëjñÖY6×Šu†Şû>2á»ü2xè/áFËW‹ĞXQĞÔêwëãİSÙ¯Û±Œ@üé´ßî‘!Ÿ »'Óïå‰ó¢I£/1ÚI}W4¯ğñÁD4®ª÷7¡ŸÜ÷?|DY«abT‰»y±ú$*àÍsëB+ ÒÔãÂêEeáN‚h^B@§©jpW¬Š÷ïw€/6®˜áï?ƒ×»Ì„ÓYÜŞµN±eTŞ¸‡2Iƒ¤‹T¿· ı{¼OJè‰8ø.4cÕ4˜Pgb§*|†z)Á´urÈf_åÅàûAşáq œuR¨;QLÇ¢AËîñ´Éÿ¯z|~;{ÁM/¢ÆnJ<N(…¦#ä÷FéL˜û0ğïúüCKšÊ^T5/è°Ù(à7Û‹³‹ŞR§UZm‘‡õBÏØÁ"~hbÏù8¼ {¡m˜ğ`HÄ ·Ìì?oßc^sÌv¾"YŞh>LjÔÉøŠş<@µŞ¦U¨>}Ä²™Ôt_UA¸.’Fs¶—MŒ§D6Ï¢	&±ûæBÑğ\L;šJí6Áá<2-ˆW½~oå2uxeïz%‚
xkTË¼xUğ‰9jµ0‘ÁÍëğì²Ğ\L–AoT›}3èÄW¸'(>úíY¯ñ’«fwÚ,ØfïÓ›ğiĞ:ıf 2/³C¿8™d‹ª™9–^˜â/á.ÉÊ RøŒjVËy¥UàKöı7€8~Wû8ö¡iQ›ç= S(Wx¨?ÖöÍÄa4“à‚­XuIû/xœ£ï2Éd­Ø‹ìX‚Xz·1•&ŸÍuß:c‘]œø€
æìêƒŞübv9°Â­ë½	á¥*V4**ş-€áp½f(–n[º?ÿ¢AÉ¿|;4/PAßÆÈòÍ5Ãeˆ4šzÙ…*Û'ÍÉ”ü¶ui@ã¯= û­{±V=T^=v®kÕÄ1Ûù`O×ì£(Ò]êâœ•Á(ÓC`×WË6^¾‰æUáÆİaåb¤W[Ÿ¥Ñï¡í]è±¤47Æ±Ô½şfGñØ–Òç[ñ˜³Á™¶™ı60Í™cUC…gFtÍàÔù‡Ä½›¯KÙ¢Ç'T'wÅ Fã$Ö]–>·ùÑÔ.#óÔ¦µo¢D@í+®ê·J‘RéBo¦Êºû2bşé‹v5ôìĞ>cY^G³‰ U÷ ¨À4¨ªØ½BQŞmK&rèBÆ]9DÌğˆ'¥2F2ÊŠÅ‘¸/W|Ùôò…½kãûóU¡÷¬;L3ƒ½©{‘èÔ©Ÿ#gÇrJÃß"ÅLyÛe±Ñ’Mÿ¦ˆ²¶´kwuÇÇ	²ê±‚0v>?vÜ}_?¬àÖ—şBâcV–)ùÙ×~Î)ñ`tmz`úu•Ò3â§HìÆ‚®ş W~ôÄÑ	ú ICµö¹u-`ò‰*Ÿ„ªÈºàïõØ¥;„ƒ
RA{ÄœGm NÓæÚ¸àá²BA 6Ş°˜Ú~1Æ¢¨	Ë3_ä$¬è§[5Å³F{Ê~9p¼ï43Ê]ˆ0ı<‰]îÔ-½˜àîh)y†|œ‘=ôK¢Y^“| oºÿq®|EeÅ€Ğú
Ë1ÕĞHMX8×q‚Ñ§@%ÖãhÏµÆi\¨N’of½å™ŞmH²p_Ò«ËåğPc´ÎL3³’æùÉ€`+ÛÒœÅ¾v ¦Ø>l[áó:?5°´Ó9ùÇĞÆ]Cd(Ö‘Á«Ê¼
K=À¬Æ›¸åµ †AòVº+*û¡+ÖIÓs«u(„˜Ûƒ[Ó÷ÌfËÙ•µÀjÄ}«ú¯½bÑÿ+0ŞhøU1^Ñê!HÂjÑ=Ñ,Æhû Óù×ÿYã›t¾ †´¹*"„‚”P„8Ò¬Š}z{ %ˆÍÆYØ}ÙÏ£5…½ßÒ(¸M»[Ü·„Şm¿F™h|+Øö%pu\ëHÔaR¾Z%Ò¡™aÇ¥?XÄ¬ÉâÎÌã Ò·w¿µô«+4~=8—îšÀZSİ6ğaÔeµ´¥ÂP•5>ú•‡XäS+¤Ş¾,èóÂ5™ø”ÂC„ÜLógÓ€ïÕmrÑ” ‡ÿÇ£òíì¸WÜ½$@Ïjg<V²hkRV9€^Şaa3¯	Îj82#‹Á^ÿwÎq6ã»İ5ûW}uˆÛ,†8•ÏÏ±­’T!]ü|ƒ¡#GÜá 9<0V«³"1lá.Ç°hv16 Ø
†mËu,-"Ò…x¹ÿÀ®!¢¥ÅIJ´UæHHìéåVœ¤Îo«ÿ(Ë«ut³Ã6–&ww0wbj< 0Øk‡iø’ÅçÂØÊÎy”?ş«¿†÷0íJyzİs>\|)I‹Ø1DWÖ m*TÄIçáoœ>çÄk‘.)fô¡?éíÇ³ÈmËJƒ^—Ô&¨pàÄÅÓ’ë{Ê”yjëDà¼wöŸLs»2
¢Ä8u„x!uª=Vä^2xb—Ë—ê¶n×»T­“BYÎÛ•Yµç„Ö±±ÂãìáßğŒl…ëAÓc¾Ó	`Ë$ =ëu‡ÓY'˜E Æ¾<ï2M ˜¶€ÀOƒğ¡±Ägû    YZ