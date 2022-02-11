#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3145815886"
MD5="5864ac93a819c5a28f21a11b4c674935"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26500"
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
	echo Date of packaging: Fri Feb 11 06:36:37 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿgB] ¼}•À1Dd]‡Á›PætİDø³aaxŞ€ÜÂ¨Îğ]Õ=@Íf2Çe¼)æî dÇ#»µ¦h4¹¼6ª–²ºî¥\3]Ë…â" ˆÉid\|éØÛˆ‰¹èúâD;ìªÖ{rÊ|c&&o1YÁFX}-ñ`Q1^¦Œ_Ah[˜úü!×ñ„›©SøJÌO†è«`_+â–Û…Š¨»™¦wæ™ğÜ¬"kóÅ6ÜÍ.4¤>¯„¸£
GË Y¯ş`¶‰Û+Ï¤ëvL†ÌÙ¥Êİe€ÁC=Ğ3¡†×£óYË1åÜc©ûG¯ë8aT@ŒU¬óŠ)#ì”W•‡ejÀôntä·à”,ËÈBÛõjÖ¾ntî{ädäıTÂ-p _V8à¤€E¹ø„[+&ó˜â_2˜l³äqygÆVÒä"$P}Å0Ì©Wî†SK¼8@D!ü¾èoÊ“(%ìœ!)oÿS`öB†4ÃîŠFmÙÄûç­-œmäôAª‘!¨îzš@½Å[qáškÓRFŸGW	HÄ˜cô™/œçFüÍãÒ×¨4jb¬,bq©Íÿçñ*Lşîô4?ö&D~a1ĞÖ(×q·˜>·oHñÛ0qô ÉLÅAˆ±Œê„6`GT´0©œ÷|g>w’µÙÏt•[ŠlO7…]kûk‰‰9{†¨50•¿©X*@uñ†èæ†§Ÿ¶u[”l¶KÒ…zºŞücëyGÔÒ½€½½şÑû#¼ueÑ6Æ“m08t>¯Nh5àh~†7…áyÄä«ıÙ2À1LYË»Y‘(Ş!'äÊQIL¥Ö]8„pf¸÷à‚Æ@9p*PæYA#›ªnëâÓnH÷Pğ ×ŸŒ S“\º„¨ÆŸòÀ÷t›÷¾©³W¾¥¢xªöF¨¢dL„Xè¼ş;‡.æâ„çÜ›ıµ2l#ÉŞ¢2€ /ÊÔcŒˆ™æú†á“S°£Rö‹1Õ2Jnóº¨V[‰íĞşáPœ6a‚Ìr®6<'¡qÈ²+¹
>·Ş$Xí¯ËÉûq.>Ò+ss­ßN\Æï†'ÕF¨Zû@Eˆ¸äc§Ö}¥Xc“cıOUÆÈëˆW¶ä³r¥™ÙWÃ ¹Õê®gø¹  ØjšÊb©|Š\¥Ÿ3±¦;´®.·¨)Š‘èV®b8ÒzÙmñ8W8gö	µE§(}ù¥ø2º¶Wû…­ÍV¹-“¾Û£šÃéG¢òX/¢¿R™Ìë£D~uÿk§Ó×[ùH‘ ´@>Uˆ3wˆ¿áXæc{€Áp™X)&¹ËÜ³¨Ñ‚Wù¶›…*[9Êğ	JkVìÉºAf#"9ï;ŒKsNô1[šh¶èº]ûZÖ»—‹‘Ö	À7¨Ã›ç“y³3@õæ©³`Z?¨è$ H·2Œë’¾»îåN	&ÑÑ•£nT\HgÂøÜÎ"¹“‡¢Õ OI	Ø/°ašm–•ú¶µ
wÛÂ9?f(R±*Şé[Á®	ÊË¿$×¾ßPj.ü¡rt}ßg[îf½ñrä¤9wµÈr=âlôT9D|,ïpù:m˜˜”xÀœ\©H‰d÷fDÌ–“óãóÀ¦Ìø. û†ò„)ß­áµÒÓr^CMÁ¯·;	È¼…âá³6xÂ‰ˆVåq){‘[jZ¨‹ukX@ÕfSXG®ïˆ×ÏŞ:Q75ìv¸nÌrˆÇ¿ßÅº½h1ÓÖòDÅ0BÜÈO@‚~öEr×p(~r˜P¥h£ôğ?¢€•u–˜‘
	 &?äùmERïØÕ X‹y‚råŒ@ÄüUäÈ ÆÚ>¸şı·{aHk[&s%‡t¶•Ñ"ÿù™ùüå½Ä…m2ú¦KXåŞ€nÿû¦agFN»œj¶ Ë {«ÍsV5ŠáH¬èBF¥ÈäLøâêµs,·û]IúY9ÕteyõÑŞĞî_Û3ŠÓ}«MäÛŞäcQğÙ9"‰Šı0NÈQmˆåÖ–C”¬ûElC‰‹Æ’ÔÈäkv÷gO‘Æ×ÓÙœ¶rz`ÌÖ hWç_®Iwv´”î²wGº¥8HÊÀk×vÅnÏA3Ğ5N1”/RÏ¿;~q9°
êZ<õÊ“2-ğ¾aQx¡ÌÉ²©k³Yvnu*¤T}öıâ>IM=Õ'”òı˜é0\.Û ‹ï»©}•–İë9<óB 9€ùN~¤Lûîa$‘Ü¾ëc÷Ão¡%S4•Á9wS+$!‘hêOÁ	`€u	fğ¿
–)6,¼ìú¬àÂie
 {$-¢%ÚèjNÃ°[âšö½¿‘ÃpV¼IMa$¼ÈÛğÛDš,¦»u:9¾ã–Ì„Ç¬ŞèÖo·ïİ€¬¬>®„}˜ï]É_£¢ónn.—Èì°+ND9ëp«£g‘p»phöËºÕÛáÁÀ;ïá'1Í–[fø$<~J^+C¤jG4ÒRæ1i{m¬_LŸºû¢ñ‰ÛŸ5,ø•#©é‡dkÿ.ÅSş†F×U“±v 2Aé¾ÊV>U(!Sfƒ]e—€vªÿÕ]?uVwÏ1â5´ ë ÓôÙş+F†d%w<ÉÏ ÜÃ¶–§E ?É[¾ÖÛFé6ÑŸï§là‰£şp£¿áËlİ¿à´”í ›”Çk¡¨şH‰ ]dëëÈÈ-çïùç¦M.ƒö÷zibÖ	5mŞzs¹X g!7¥qÛ4õ@ËùEœºMâCñ"„Œ«VfúûytI2…Ècw/ØS‰{ÏİÒÇ²ş‹–…pV8kĞ›…Ñj‰/ï $Ò[Ãø¨¨¨ !Rı#{G·{¾<e³y¢VS³:E`wğEj Éâšó¿‡qKï ´ÑÁf[´güJQÃ†ÓÑÔç››ë\>^µ1ß~%!×€‹GeãMÕ}¬BVĞ.ÖXÍ0Ğ‘İd•ê©…é@:O×QeMh@Åø«İ¹§€~…|1†;v‹(üÀéoçÅv·‘9ó¥CÜ­¯ß×c¡«â„àLİîZÙâ*¬Ó«œ¿os<…+çXš®'jqIúùîÕtÃDb•?Æx¸Pk>qz}éù3a‡cv–LHCÂc Î p…êˆÄ“p1·.ëmµ6Nêó³>Æîû|6‡)Ãa3ÊÀÎTù¦íğT²+xúB!ú Á¡3,ÙmN¡˜áãšh²Ÿ?­Ry¢•ˆğ3¨ùš…¬Ğõ¶áe?„lÒy	ILÄ^ÌUTór›¥LlDl‰¾˜–(w²ƒ]$·RïÉÌqm—Ió=QyÖTz•±cY‘Å%—ósµ˜k Û9¦)êÒ'V¿SæE[µÉ¶ä·ÍAŞşÀ ¯nWx~ö€%ì¤Â‡Âß´¶áiGqÚÉ?Òtî–¬Ñyô·/LÌÂ*&ƒ@%~Óí%G®hW‡©AéÊëk$¤è»m‚W•”Î6Ó˜ÏÃUùÇæ´¤‘MG&–J}Î²û¿½Ì›JÏY8Ãû@¢L¯NÇlÉ2Î¬#ßĞB‘«¡²<W'çùÜ×&‚œTrû9NäälÙ-'üàóé4ŞUê¿zhQ¼ ‡Ñáû—Ç‚b
e½ƒ·9}®œ·÷ÌÇ.E²éêĞxiA‹²'š“<œB±ÂŒ±²G}VüØYc¼á»òN“yĞıÌ2×LÅ¦ı?üélòa¬ßÃ|ÙÃÔ±’b!ÿšV~Z@Áq†O¾ß\ØıÁŸ;=²Ò‡•RŸ^õ 
ÂsO£ ³Ë Õó±¸qt\ÿO\±[˜Íæ"˜òÉ‘så|Ï®=3öR+sJ`â\HŒ{9"î,bCÃU?aQaM«ÅƒïƒÍ‚2[Ö±â$ğg½Ÿv¯€qiªş0jXk¦Ú#÷0¬f¿dÜ¨é¿¶Eßlåıœ’Œñ‚¬‘1 İ8<v‚ÅQeşÒás>/M»ü°:nº@#~ uóÖN1¾Š¡ä¤'’•…DÙßÈ$åˆ”<ü‰¢ë²‹ì’û4š½`î9Š´§ıâò‹æ‰é±DœÖ¥}4†Àá[c,sææ)pj…@ûÎ-A—Œñÿ¤nìd€8eNî>…æËe'ÀŠÅ?	´»cÛu[Ã\ÍÊH’%nùfvÖ9)ì‡ï2#Z=´f7Ø—29Ò%b\‹İu´ışÄ‰C­ßÔgÀâ¢ÊÄ€şM{MF¡ÊÛ–%ÆzU¡¢úNÂĞû—ªMèB	¤Yip1xdú.||9ÀÅ‘¡ê‚ÜOÂ"]ZOÂ:&lÑ~ş¯YQ-j` 	a!ß•¹ñâğZ³LF¦å§ùƒñÍ†±jøvÀd XÃ)|Ì1Rß´BDww£®uàÖˆd:¸ÁJ%9ÖYËàßaÏÇïîšËY:#xÕ-ÀÑ˜@G”™w!ıÙª…ôšû6x=¦]’±Í-·Xµ><öĞ4IÎÜœ]ŒãÌíç|
^®æ­ãf8Ôc9L°6<‚m¦ó¹w”Ä‡qÃ!´ú}×0ø©Êatb5™ ,ÓŠÁøêÂÏ’zÏu5ïê;_…Ñ_|]—DSQ¾Ûš‡›@‰°îèB;£ƒş?˜e—’”ûÿûõ¯2#ŠñªˆŒ™Å”aÃæzd±Ûç²lÙf¿/ûşPBÌÕè@Wƒø?Z…V€İ¸æ`{7öZ¼úWRóØì‹®$jÍÛó6¯HˆÉONŞ{«›ñá#+œ-DqŞP.ºFßÿ¹AV|S—ÑÍè7’Æã•5{B7òP
t±v{–"ŞÊ$V	:?;«­;a¡%òáB¼ÒÅìJîŒ¬!ÛÎ ĞóŠKVCq2Á3èçÂ+¶í™l€İ k3ıc¨©¾,?³?†êÜOåYöĞ^švû°VJ$qÃ’m5•‰Û™<RàÜÈyÂm9JŸìèrÇcæ*Já‹:¥¥2yg‚uµÉ¬ß`ç<H³æ¼ÀĞµ¢¨fûµnÌŒrG\­ˆq!¨40ŸÖõÁ¯‚Q6î²/¨Wæ•°¸ş3q„îÌB•k—)WÎÏÍÕ¡Cœ¼è{Z#œÜ;QÚ×—E'Ùş¿	!ª³(–0bD	p«YC)‹A"ßéı:á<ÆCïÚäËzåç2@û#àÉ5^v¾ƒ€—,ÜØ<ÂûOê“ôYE¸‚SÔCĞNÇ›À	¬Ré<X>3qrp=KÚ½:a:¶›·8µXÇ¾Ï}fåQ?§Gvœùör¶«b¯Ğ´©:H<^šÑ¹v»™LYÿÖ°³fy
–Çú,VÈ^íñ%õCó
m’_c¨RÌõD|×Ñ=¶ôë˜²´Û11ş3œßˆˆÊ-­º°èá(ÒU3P\Î¡môœ£€OIœcµÈ½“Óê÷œ‘ûÍ—Ş6E7ÅÖÔÓ,íÓj¾»—ñDLıMÅ²3d½TÇ­	zõ§P‹S±‚†4s­O3Ú‡Q`öÅèàypf¡c÷¨aÚÍNu3Ël£aÄà$«ïEì¯Ÿ£å.ƒÍö™v<y¿D³ü „Qn¼"§[Àû”Ûeyš r™Øİ$Q‚9…0N=é˜ËL­öcÖôåÔàop½¤2Á ƒ[‚ÆGhšJÎØóUÔŒöc =$0ˆ¦,K»ÏÿL`·'øRf&®©ŠÏU•é†Tü½<°”w[1*RÀmv»lEÈª™uR9
1î^Ö6º“Ù¬íò³15<f9ª‚ñ‡rJ<äIµÕ¨ñËw,4ãÛøÏCÅTıkÖ˜ôb/æö‚şGàÊíúÃ,ÈPÛPÅ|ìx+œ:õòÉ?FÃjaRŠ¹ö8ÜÊ9UÏºˆœóª¢M1’ºıPwÄ¡9ìĞmPˆŠqHVõÄeSù¯ˆÍZr¤#íDÏ[0âD±yËÿz[`oã5ï"º*%–Ü¦'¨j•µ#(*vËœ¤rò# p¤ßÖÃ2Ö“[·‰ì€éÉë©i¤é¬5·Ï˜ş ÎƒÅQä
ÆÇ	¾m «`h-Û×nT<u[\KZ'üÊ^€T	á†4¡ô1T‹(t$zjÌ8›o®Ç/‘Õ:KD—A¹è·ÜÉ¿¶oİ„œ˜1ª×?äf	zˆ,'Ë¾²Jœv›Ê½~*ÂIGˆ-õÖØ·2IBÄRjÁŞ#$Çx÷A€èqÅGNÂëŒŸ¿(àyÊw6!¶ìPĞİj|ıXóÌµùœû;¨~Ûéˆy{Â3ÉŒÕlÉš;*ÊŸà&^”İãw‰¸U-—úUöŸ:Ï¸ƒû‡_íP4`íêµ±¶50¦r+‹ƒ55	’Ùn– u•r¯`À«ğÿ;¦%hrjÁîÖ|’j­M“`+Èm·ø™M€Í5Ó'ÉĞ’_ÒŒxZd!ç™<Qšvnä—Ğ{¶ßk Ô=ò‰.,_ÚL„!|¤PÿB(©Ì?à€ÙÊ%ı@c23‡/ñ`ÈÕikÏQ¶¢øK<_»­o¢ÛIò¨
T@zy3–ÿ¢p­Ş„«OÊ5•ìÉq¸FÉ§Åg6Kå´Ãà£6Öt\š3é[¤HÍğH63³¼Qº”+¨ÃL¨çZ¤Éyƒ\öİí§ª¾¬Ù“&Ò·[K>
6¨±^¡ºÜîH¼`Xõ˜ÃÈrÏİº%XFî¶¬12—È<¬+Ñ½›bÂÊ¬˜ŠÈL†ªÒNüÕ_ÊFë.Q&º›pyŒ4®y]©Øî	ğ®È$ÍpÀtyÏP½ĞJ#İøG}¨ä°]´-†d5‚s-ıxÎ©ìÿË†ç>$Åóš’HkÊçÜ,’“‡Rö‚š&C›QD¿hq…n§*ŒuÖê>Ùra<°A‰·÷ZhH"P(šz´#ÀegÓB—üpúS“4ÕMè×Á³ªmï™Y+ °EeDí¥’ø\â'Ët#Z.¡¤å	Lp)(ª‚^Ø2!£RÑogW*=©ce·ŸJ6û,ó4)ê#C#©â{â¦·ûÎZÂö´¶/î_òµµê=±ÛK&'Á¸
¬ÔR¼õr¤‡ÔFm¢Ü¥€Ib<ŒÅ-¯¾kFß³%À+'NÈ %.ÿ‹Ô<ÖóÚâ,i9C¼O„! ã(
Ó·ëÕšÁ8g­¾IŸ3·‚ uõwÖSï“ÊŸ:)£èøãÔñô‚&Â€0¯¼eƒØ[  µ;iİ¾Z ‚cÏƒ êê$t[)s"-ğSDë‹2´ªÃ:¼€±ÀùÛ{‹{Œ’m5½ºùi*Ê½œtñy¥È}hb›•”x}”3¨Jäçx.¯Viu¾FRú¾¤ÊŠiÃI2øª•ùh¥	¶
ŸÓR¢B9Fã´÷Q¢àò5Yg¥ÒMe ÕdÿÂÁ·ƒôÛ®(sStÌSS…-m
c®ÊÌi²'Æ]QOÇÇ†u8ft"5M»Ãx+3I¨áŸ‘á5{t‹áX.öt>%cbsR[½!a¸[ógà¦©j	ó1AF¿H˜¬Ñ3c„Ó@o‡[ÍóÜbÅëìámğÛú5eböÛ]ñŸì9;ïQ›1Iäe©8ˆ‘!IEàˆÒX~´*ïŒÔ¸úüõâ_¥k1C–fi76ÄœÅP`êX}‚‚I‘| æy —É¿‚•¼ÌÓíåQæ,^7}ˆ]¤$¨àÑ> ùEâŒãÈ~w ¥tQøhŒ‹Âuï;  ÆâÊ»}:J½.½i†Dy¹ĞMÄÃ…PÜa¬hm¨|FäÆ€¨b;óCpıDÀÛ LÄ1`j¿9!‚ÖˆÌï[%û¯ĞÜ/ÿ{mÇZñÿPÃ#Iúï/æúãxîvc-äĞÍq–ÑÇ0ÕWfjÔşæ°£_q‚@¼vÁt¿|ğ*§Ç0åà'=Lgã‚tŒ´Åğ+[EC¼¥I¯ë¹£¸„dŒ­l*õ¶ŠW3™¤Ymub4Ö"ÅøJ€O·¾k&¥AG¡LÅ²›³_×'2çB?Ö©mrëÑ(±áNÿÕ:å¡i	éÏcö6à`’^äçå™Ax¦=:|†#Ã÷!Ü6³«³Œûò=ËQº@ô-(§dÕ™©‰Å«´éE}ø xEœ°~u`[ÇÊ^ŞºœæÉ¼Ï§/áç
,dòz ¡<º’öt?ápÚ…š*Já¼+ó4T<†ILZÖd¼“wÓ¬àjkã¿ë‘Ô‰>³I€5ÇncJİWÓqjkŠD{y&eA­­0+Æ–l2Ğ+V— Væöç-ÙÍ"RÅ°ÊµğOx%OØî½ù‹}‚}n,¯0S¶¼¼Ö¶&ı£è…škJ[ïÉPJ.`ä”*˜c5¼’&øPÜ¢XzÅ@ªu¢[>]ı’úš$Iş|êØµy 7¹œ?Iïß¿në‡v|Lñ½ZZæÆ—»b– 7°‡Ê&Tÿ˜ú^Š¹”ÄKn+‘1\äOÉÉÇÄ°ôÅ³ù!)–%‘…ÍÜh|®=áª„BeÌeÁ=­\åÄ¦(»ô]D-[I—¼‘nóå…Óÿìáïp»—.³„¸JÍtşD£½(Û¡Èî>YLW ùTÈ=Š-àè‹Òş	ÿ¬—hzÔÓŠTó¼³ÿèsºƒ¥âöM \j=åT+¤]Âd°d0ÙÊ5Áœ	äÄƒ+—XO™bÉpÑ6 e–
âw¼'JÃPâÑĞó†0läGv`è'Æú–¨M”k³ÌTıñ+!È‰“Ú«ÕŸª—]†O®ëòo#¦ıÒçÓLŸï³†Z†ZµxÃ¿Ìúèyšœ[Úê°Ÿ_"Ã7"Ë5!ƒS^-Nrh@ô÷àSÕ“‹Ã^©‡#H£2¢î7ÑÚ›hŠK©[ÇùgüÅşœ?œ?ĞoÁPwK	¼ƒ¼ã‡/C!(®¥ø÷¿0xfÈÕöŠ¶/åÍA
n5I ãÓ*¥ffßPá¾HM8Ê–Fmà€¦GŠ<ƒ„O˜bM¼ğ®\*e—ººöÃå]òoí˜”ÍZ˜@µ×ˆâ§ÎÕË¸Ş‚7“÷3%"|şf„W.­“°ß¨¡T[}5P‡ºB4ÿ»›šïù“¿¬Ï)~İ»XÊˆy8dêmŸe\I£ÌHM[^ÀÑ\D¡­8”®ü1½”¦7¼ãÙU¼Ï±¤±ü¥ú	Ã3›«?@Lm2=ÆÙ`”ZÊ<q&í$àÙoGßà+®ã°[û›pS‰Õ{Îr…é[âú•ÊËqñ‰ßãPÎ–êÒOA©ëùá£ûÕ•ÊÜõæÈ¢èÀ,^q?¦¿¡4/§qf¢r`÷f¹0W pú%‰!„‘é’õrHJÔÉv¼r ÏH¨$ÅuÍƒ=ñ¿}æ8¸©ª‚ô»•(\âoÅŞMê ™ tƒlX#RdÅGeë–æ’Ø »ŸÈHótù~ŠğÍ
ìƒ˜õoiäÑuãW‘oÿbW°½æeqéÂ¾ÃK”GïË=ù…“g"ÌÌÇş£kÖ»ä²:ñ”ûãT8V@ykmÎr¤Jm ; '±ê·ÛúvvœNF©_øÂ‰ƒ1»EºÊ
C=„Í¿ùNçX*k¼pïÛ“%Lîg+ ¥#Ğ±½qàŸÌ-Îo¯Ÿ›#8ñ®<
íÚuLz>âÒ8oÄ‹š=½#édÍ¿'gè†³³ëç±Â˜Ä*ûÁ{l‚˜m‡ãŠ»È¾¶Á¾~unçur ˜åËA’º‰ş¨02Õ!§»BÆ†ØLeñöH>­&ÉÖ©6çã+S+òE¿Ïµ’´cÈ4¥éØ2œEĞx¹÷ó@}ÇıêÎSğy¨ô¿Ù¹^h¹×z¾Pk\r.P ])ŸÕ3^Áü¶#öæÀµ	mÍXu_!Püwì¤äÓ2Bû…6yk^)
‚xä©Ëpê{õõ{APc?¢LìâßXYiøZ$Zš\)i -t;óg­Jğ°D'ò*nzâZ×AeÚoc>m‡ÿù-Œ	dJöÅç^"Á
ZÛP€éj²½"ÇX,ÁGdˆ	_r]ÌÙØbXXÑ,ĞÕ»d7w¡¸Ï¿e6zL¸T¦†ÂM˜èZ)\ƒ>;1M	—·S+QŸz

¼¦0s<ç­é?ûOëŞİ©¡_Ö¸÷ÍÃLä³e íñ—kK˜ÊÁèŒêÊPGPßÚUùğíó§4RÓuø	’¹¦‰¾×œIeç’Ër¬ÒIRÎÆŒ—³RFòE"zô2œ‹3kòmÒÖ3ß”‡På«ÕŠ°ËºUd¸óÑS»@ĞQbÖ—³¾Ğ£Ë»àÓ·z°Ø]’=‚ñu"NµG;@¿Avtˆ,Æs²
‡	SfE#Mš[`kñP›½Z1pšç	dJ9
×›‡+DşÁV±u—/†²oÛÚ°“9æ²qIºW9øÉòê¢¼®Aî£A–Sì¼Š¾0Åæeìß&ƒ‹¤¦®ÄÍ¶£5ş@=&7‡Øn	=ùÏC1£!Ü&õæêd¬õã†¹ÏGäs‰‚³-/s«hz|­k{N¶Gc\AÎ¹)£ù¼Ëç÷	¤6k°9dËR´å»	L£.Ni‘£êÚÓÎ+¡ÀÜ|!±¥Ìı(-Í`D¨»İoú*QFSq1Â˜†A¦öTJ2ŞøÍ&èScÑ ÜU×Á€Ûx'U=‡!T!Ê:eòl‰YĞ‚)†}ƒå’ŸQÍ‹ÁxKHo¾Â:5ÚxeTçV}¨Ò ™à*äãhƒµ£­3Y¤eEFTT–¿s dĞR³‚ß †N+Ì$ş@Á´†lÖí7°ç³Èe]ÂLÎ%Dad¼Ï¶ƒ€ûÅ/* °3Íé§¼¿ì+ÇÍc-RiÚİm¨bóècĞÂ3QÅmªº†Ê*ÔeÇXˆ…A¢¬fØ¹ÃO÷ƒğDáğ›©¿\ì“€ù¦èª„Ìô×l‹Ò•_–´öP©içáë/(“™ø×¨º°v`–QÃV%óFOh·à^^®$+04nÂ±.õJ*/¥u0BåÆ}ºúfì>?|Eq#7îØüËn.û¹Õ¯ìz••XÚ~qt¤ÿ_Î™³jW–ï¹pù¥öc`ØÒË$ò†9‘<ğìg|>F‰Bq¾^2²˜¥r¹LDú-3M3ÌüƒJ~èg&EÏAĞÛÕùÇGğ±$
† {×˜ú¾k§÷N6'1Y°ÀìÍÌaÕŞU1FÔ4ÏjÂßò¹Ü¼Zˆ8z“lø©²àéqòyìÍÆh›ò]áEÚ—?€ G<>hĞÜÁŒuÂ±6`™yUôÒ®¢Ğ+´<Ãv`¯ØÍ^5î¥·ïõT8ìü’-=	D¸ÂjÓæ‹} ¤»ë†pV!*ÅV[;^y2f$ƒÇ•²7buÉÔŠ{æàßèª¹^t#I†­ÀW_–ÍV#Ô¤ad39]Ãï-Á”—Òk?Œt|¦ª5í¦ÖVôÙŞ¦™uÓN>ÂØé¡DÆL7ËèèÚÛ¿g@]Ò]~ÁÇÏlC²-…²?Ø>Îèúá˜¼<?¹R¬÷©Hk<êr±vÿø÷º Y^õ*åôN¹²NŠ0CC4<DTæûPe°6¸bìç[úbİX…ÀH¸â¥ÛêÈïÒM§±Ï¦¬º¦¸^Õ‹VÛL¾Ü5¢S¹–Âÿr"ËUòºd{bl8C ‚;Ò•Eä(#~ÏmOT—.}ôaQåHœ(Ô½¢9H{ÛöLî=s|nx%ÿÑ$nÙ³¤ƒ)]
ÄzEµhx·ì„±kÉ"óùû9~¯Ë¹ˆ./¹Íj;ÎnZœ/Wã¾Ñ©¤ÌÒLF-9‚iÂ= kÍ4ÏCa NÈ·8pIsœÇ˜G
hÂ Ia±KB³Œì°²,o*|Âˆxrúaã(´éçn‰œ´÷R§E§ÍcîlÜRÀ¨0Ã¡ôİb‘–1ƒé›ÌÚ<®ë«OúcGHÒjh§OØŠ~ÂÀË=~.âÖ¦QÔr†ÏLsÁÀáE:ŞğT•@3Ÿ·–Şœ±Y¤1a‹Èó|Şã5vë9s“¥Îp¬$\G£ıÏ#òR·õ#nu‚"@u'’GÚó‡F…øøıN9jªâ—¬ï úf³}åµFœÀÕñ}V¯'åĞ
Ã…7F@x÷½ÊC2EÌï#.Ïa±»[ŒˆONâÉïêÈ‰Ô-.¹S¹‰İM7!•€ìúTßÙ˜Œ/‡^kÓ3íõ1Õ‹$©²"¨¦¨Ö—¼Gz˜™O×x‰(' ˜HY‡edÏ¼3ìdsg­â€RşQ‹äá\§¥Hz¬Vaåü+Ö ·F N8y‹q9´~6lb|(CóÏ;³˜¿ünê‡Ë¼”Np¸0¸ë>l$a‚èİróìUµ0ğÍJP‰Ğô³ik¤Ãşp•—RsŒ+¸}²’‚ë.YíÌA¶Úájü}D¶Ê¥¸~!z¸|(ÆQ5ŞÂŸ¡O¸W€ì,èFÜtÎ‹Ñÿ‚óøËbÌ’yÕ™ Š¥Åı[íĞ‡kSæñ‚URU©Œ(’ ´kTàW5¥Vı›²OÙ½dÎ§ğ½’õŸgĞÌpHÈnJ¥°ÇG~Ó	u·«R"	°şÛœàU6øF×ŒdGZ}y2r:¼B	Œ`¨qºş!õ–ò|=ÖRzXÃ×hö¬×fs=«Š,òhÁÛP8Üá«Ï£œ÷â‡¬-l£†Å‚6ç	K0Z‘ä‡úywîêRaù.ˆÒÃ»gœÌPön•Z¥îÆ—¢hhÌ±´7!<XšºSæ/­á%ş	n6 ¸ú3É©î‰Æ07E6Ø4Hr=S…z`R3¾ÕcNÓ½%iŞ5«ìÂ2*˜ãm½˜öÅ2ƒ!Ì€ŒÜM¥™‹Wã<[Çy®÷¼j]Â›T+«D»âĞ™§Ÿ‰ÉMä¿l¶»Z0©@Ã(?±%'ÀŞ»E¼^`óQÎ½Ÿ·T£k"m¸(äCRƒW¥{—W„eÎ<)âİ¯ky<ÙˆøéÃa0Ïß#º>­+™¢…‡õB ğ.l÷H-,ŠÑQ=9ÁZ;’r;ª<ºlI™#<–ì¹E{µ‡’f|],HÛ×qIaK]FĞ ‰"ŞÒˆ…Ÿ8B4Ûúôi¥D¥ @>ûÛ+±ˆ‹µÄå¾fÿRÈÌ%°èr¡Ì€ı-6@ÄëBù|fşSõ£aŸæ@Vyvß£©wƒÜAëó»ÄWú©øù:’ÏO^‘d L˜¨úı]é‚›®q]ô1Udfä{>\
&İSù[ößxˆeV‡ı!ñu½®VËÖ¹ŠkÆ4‹e/úÊÿæg|¾WD^;lg;:·ğKªŸ“,ê…ëİ½ï­ÅA³.lZÑ¯Ë•N 	Æßšè{ÈA`ú9ÚSÉ6x"=)‡’1õ¾op	Ö¤5c¸†&ï4UYßB½: úDæ#¸Êamæboƒ2èj}Ñ-®õ6JIŠ,~»ØÏ™E³„|<Fz»:@DÒ‚AÆGøÄ›¨Ubô@ŸÀÅá½Œ5êñ£¯,DD^ :û­Pú°Güæp`°‹Ò ÜÕírÙYß^;‰{•êbJ&İƒ>ÖÄé“ '”ƒÈNkf8|Hrˆ¬²+Ë{ /Q4†ÜùÉ5–…Ìé‰_À²—?26ä•÷Ì“S¤×ƒ )¢c5µâCîˆ#mZ©NktM›íÜïî¥SÔ‰r]gOÎwó;9ejmŠğÊÃJU| ‘Z"cŞRÌ£_ôù×·rÈFÎ—sj4÷^¿¡e¼ìjßëÄ¯8<ê—‚",	¨¿İ›w9Ü<ĞèZpì„tWİ¦S4ñ>OÇ6‚¯æ;U|`ïï/0X`?†YvVağ|àÏ¶uÜçoŸíÃ’¯§\Ø2ÊO7Şó(îğ_Â‚›¿ãÊŞO¿ÖÇõ¹ìØÈœ†F¾JD2ìé@”%Œ›/°;)ü…óto
ÉO[Ÿ¨:uĞÏ
{$ŠGè·òÍ<ä·Ww¸k¢î}ƒX;.î	}Š×a!€^ù-:t,BpıNá·ƒwKüyXx÷¬ÀšñNŸ}‰D¢
9¢/,Õ‡Œrà^H^ÔÁ9C~Ú7CÎq#p 5èO‰˜@apÁ	<Œ9õˆ«Õ7-švuöİ‰¸nëš®ñrEÁºB`KÑÿs5c[ëéB‰Ps¡Sà·=+sd¬n¶½O„Ô7ÉªL«'Úö8˜´Ş-P×•ÙUäK”íÒío^vïµfcìŸÙmäŞAéòŸ;WíüG_
ûúf
7hcÓŒ{ŞòÏÓ^n«¸f¦HƒüH(Ë íú*B& ÑÊ^âÍ¯è<"25Za*|.W'd²Ç]I „¹1Œ«Pºõé•]¦ÙTğ4“Xÿ•v&C]ÜX'À|8I´ŠÜ``0£dLı’á¡KEƒµ[˜§+;ªĞÒ™\©±{Óím–Ei²Ë‘b£¨!mšÈ|Ñp±(b¨)&â“{Áÿõr|­ ½¥^ğò:§X×€_9†`ÚÎ‰õ# Nj‡ËSÙPEZ ¸}µa8J›…1p³Yv°şU— iÖfŒš:âg39gIKír«qó=G’TŸÿ­zÑÉh9æ·º|O8”vR'£ï°ƒ:ûµ5b´PËqİê¸ÊìÏßx~0¥ã5±ß]JÃ4S‰áÌúÖ~`¬½r ò/Ò&¸ùıDb Ã÷¦
ÉÆ‹îm	aæ}háÀßOá~—ÊÔéû~U_LÁV’Şf)Ç.m‡¹Ér›xâ²¤iÌ¶™o¢ë•¸0i#²‰¡/SÎÌ@«F2°O¾ïÓtşc JFwÃ”†KsŸ€Ÿ%­ÉÆøÍ$×g1^¹½H…éò#õ8’y@²¯K °}Â`qXg¢¦'=ãZz•—¿êœü^@½[a{•)ÎY´w—ïKoXØ(â9ÄèáTSaü¼)Ş#âM£ÌãïÛÕµng|¼Ktø!ÃûÙ²0»tvÇ:&?şÉ¨*Í6tR´Ø	‹ôbO JÉ…uB“xØpŠWğ¤Vä—2êàğø¿'uÍ‹ú¯I2i©»--ëâ+1¼ïëŒÙ®œâäÒìª…àæµÏñG*¬ËÊÚÚW¿èu#oÀP½iÈ—'/Ë¨+ õU]e®W«E‹DmG¼ËÖş?+•tUR3³÷ûPrAªò‘ÁåBà•õ³ßsˆ6ÉXô+û\ù›_fğv:Aš&·Ğ;Ûvz/Ì©5
é£jöe]ƒ,à³eØÁùámkqˆ^âñGğwÙAzÎW}àaBêMÀ$Ù=„7õ+’â†FúË¾ ğûX+T”jäºÈ-Üøt%´7"’¦Ù…tŸ„úŒÆEŠÀ1³C8`ØkA!Â«ò¦BÚ¬Q4øŞZ¶sÊÈÚ$şÍİ´VÏ½}kÎ’,ZB1æ„"[˜|â‡¾ÇCÅL®hatLq‚Ù#ˆq­Çh¾’ùº„Ù^ë©]?Ûg¼ÇünbÒ,¢´ÈÆë#Rß°bé©-$ä&¦Ë«9 :ÇÓÅ¿´%û=w¶AeØşà..tpÌ«Ñ'Ö„•æò½ÀNAD)0 	-	Ñ\Î9]vPÌÄioMÅí•×
¤À'øæ}0ÄSçà”3>)
®¿§uÛğ†ÎÇL7HÕo±VI·Ìi„iÎÕÆë»PloYÜÂ_gËj†¥Ù{@‰»ô£øS1–Côãë,øpÛ/ê(Œo$€]›”İ#)GDªw4.,/8B>tI*#
W‚Ê.r…Ï±Méds<ÊÉ¸Uª\WnÜãÅ²½ÙLè©ÓŒ{£Eáş×ìó^Rò¶[ıÏ/¼n3>e-ëáI]WHlNµî¼yåwy.º=ä8ÃUPµPB¼#£­†@›ÇçÅt=6ÕZ…ÕÛƒúõò?ÓOÍzÃdò `%^Öw`†W'ô¡p6}ŞÙª“Ø¡
å@$?ƒ†e·æIzŸ «!°8+¾ Ê}ßèÍªQ±NîĞX7|ìÏÊõ2@*ş‰­Û¼µJì÷úŞ½¥ëö1 KßÇÂßl³…†õEs³Ó¶öş2;‡ç9Õé'4GauIò÷Øî™ä·yzRrÊ†C0ÇcŒh¥|?Ùi k1VYy-e}±]’{Øc£·æç©5“£h÷4]J“h‡2ÛÑ“+ËûŒÔú‰W†ÿ(YŒ·ÁûĞ°£xB”ÔU‚Ö’«–b
¢´Ştõx?" ãØbØ6Ò
ÂA_¾Fä¿ Í}èşœRDÄº«­ThOY
kãÿ¿’/ÃØ¼cHÿM¢Š¾ÚWĞ¢Ã°ò¯Öo¢Ç#Üv¯CKàí¿<0«b)D1Á©IÏÙµ Ú-0Ø¶éÓ$Šo£¯•£' Su´êM¾p÷ÅrsøF<±påqŞGná@5y'jyˆ=ƒ;ß{‡ğBÆÅU·§“2]kY°L-—ñ	eÀ£x ÉJ“–¬g$•ôëvlü:¨›ûL	í ÉÏMfª”w‹éHÄÖ	p%™æÉ¼doZNĞÊ A¥~ÑC™M[~ ïØ óò‹yšĞ:Ö½%}ğ–šxÓÈšÉ´MMš’®vˆmò€ï2Y¤l]ùI¢ßær_5”ÓÂ¤†
	õK°Ü×ÖÜ±;ïWU ­_ñÕİÜ™­Ol#½…D"Q/U¹l!&Fû:|#ê[»tÆ&ÑÀRbïÊ“¾oã¹˜„bÓ|Şöëúi3PùƒWèm™©W:|ız÷\ÿ‡ÆñhÍ,Ù«JÁ<êWÒ™JõÊl¡7ä1±ÃØå']gÈ!óùVZ£Cc*-¬‹40PQ§W\=åEùÉ~ J)…Qı©ÉŞâ¢ë­­RË iÖ*hYìv½Àb%q•„ù*hud5"fÉ¹…ŸTœªÏq)“Ö¡îïÁ$ö­p¦BWå³aêã†  ‚0¿ÚÚùŸgdşkÕÒ£Zˆk;$n2õÂò×á«ãû*ë6UîUT/Oã<rºiİ(¼¾{ú:n¼ö íø!Å‡»Ü¶ãÍ×ÿæmrWÎsk„à!ŸáñzÓ,§R{|İh«ÜÁğß—.¼r˜İ³ÿD3€O¨FĞ ğaÏeq§À«À»–Ñ4¡±ÓU'»Ew±&óİ$‚@°ˆŠóEÖ×êJì¶é’[Uqn°â¬ZùÔÚb´Á‘|?ı{TSÌ[U¶üñj^wÚß”.5iR/î¹†ò?³Iu—v€°a&²[ã“é£³pOşu:‡îQœÓO"×é3
ÑªÏ ’hAwæhÜAxˆ?£ûİIü'i U:÷UêI¢¾†>ì‘/Ní¥¨%
sB!nBı(»Dÿ†w¢jLai¶
4_¹Œ:.·Æ±@:ÉçªÿXÚq·.´(	© ¡]t”“-Êés”Î=i/ÿñc/&!b&9:¥^V¬HÒ‘Q¦`ŠçäéÏ<šó^ôéUâ+8…$«WËT¯—ØÕXj.¬.e£p3Á3ôçş¨½í‰oª‹«Yh¾GO]ØD¤ûÛ&}¬f¾ôM´qŒ“æã[êö-†0W`9L
7™0ÚvË1W '¹©^ ú2}¥gD/yD*±=RPç×‹3˜K+ƒoA[k{Ÿsä‡Ç¼7+ÊVó”/P.M%ˆ*%ZxÑ'’¯¾Â=3rº
°Ûéw)†Ø ŸTU4a“¹Rİ’{w#zs4«‚œ	æy7v‹Tr4ˆi?h8' Å°»ıÒOEÉ$8-Ø¶y #Vq´Ç-dÈF®Ûyù¼<YØU&óiQ,à!~]‡ıà/ÕªcLŸ#ÁÁuGT":{NŒåq]¤³·XTªËôúBNK]Xw|Hı³ıï.×$ùİå'¶éu_ºâb~ÆQ¤«ƒ|"Û·f×O’äı¬	ŸB×€8c*ëïn³³‹¬øU$aÊˆX¥	¾K,8ïuÁR—©y%@{èº~9O.¦zOÛ¡øiÉŞUàCÖ¼³µo°şqŒÜ¸nZH‚1 ¼9T[^}"¥ Äœwe±ºmÅÒ`‚L7U$4íã
çE=à´À|â­ 0j6!JÉ´6CS%ŸCümÔß9Ì­YB\áw‡ÊÔ ëI"â=xí'âäi‰2Jåó¢÷ímè8Ï)¡–''—ó¨Jq¡hMT•âIı+R„gèSœäÛÛº¨$ÒúÕ’Îœy9Çâ«MJ&j
õ‚Ìà/A]d4†NÜMZ|ë$wD:áà½ p~0î^IÙ+åšŒŸ ¦®ê* èğÄŞ›ÎÉÊ¼ä¼ÅI-|íu‘)à˜‰¶«eáœ`wMFKôBGâº¢)nZlD	sğûÆæ~vÙ›Ù»)†3—ğeÄ7cÀVó#7¼fæ£êoŒq]¸Ÿ›†?^©§Ü2ƒ®ÖÙaó¡ö	_
ê>Ô¦N§+@ƒBøG^–x4énÄ;]×ÀåÖ n&²¥´~¡¼´”Ì9·ä
^ *Ü<!‰@Â¥«jŸz‹­R/¹se²#Àùá™Š¶6óşÔº“L¤ä?ÖsÊØ0 xÙ#W$Uz…"ùÚ­Û‡¾’…U|7€Å!YQZP¬{‡ÑöäNÁÈyG¡ıM8’+BJòl0 W¥‹‚H‹|üfo0Ö]Tg`uÑ6½jõ Zh\XE/U^ÉjüÆ“íÑƒ=¢üÎı%~{Ø6‚Gî‡l²(îå…i/ôÄ×;‚•œŠZbŸ}FöNÂ¡¨|{ló#‹/Oé–çÀXÇº5U,2nÂ¹"(ÚVÜp4D)òšP¢&;8ám†Û¢å[WŠ6™ì¢Wú:–øn,íªªTW'púÎŸßÔ¸\ÚñÃë
]7†Œ…é©3˜<<ÑœÇÖXêo	yLcİßÈÇ×Xi™É@N9LVé‡ò¶	øS(é´ªè×´é¤,ùÍ]ó.&aAFà©1tşƒ>wqà	¤º¥Ë
Dª¡Öö©Å:£#Á?ğã`²¾oXèĞh@Xr–‰aı˜˜YA·üj±ÿóh0œgŸ"ÏWRŞÇJpÿj;áKjäS²sèá/ñjw
”*õv<t,ëÜ('M¶Š£^Õ$~XAKCi¬ôs°ÎÄ"Ntp}.6Ÿ'>Ÿ¤Dš©BKˆõSÍ{’a/Ã?:ytE=Y6¹æÌ©`Ÿmïéd…Âãæœ’1|¿´Ü†:fºÿ$±OH°xhÊôÊTC“^`,/¾ö\¦@¡é¦$SÍ¾”¬;S¸L˜>û)eøıM…â-K&Ú)6‰r8ñÉEšĞ0¢î -*TK»Àj	Ùêa*á¾"(<ß!båR%ĞL¨Ù;œú7Æ«7åì§òÛì×b—«§yÊ¤N	°ôÜW©sÛŸ}/S¼ÖZ7‡ûü·;R‡gğÔÈÇ¬ÙÈ½÷¨²$™&ÂÎxÒ5˜eŒ'vs¤õúr6‚—şá#ñ£4TgÎFlÑ´<-¦Oğ“^.Ÿ­ñÃ¹G¶Ä
®„&4WÿÑTº¿µ·•IoPÉ'Oá-¬¿ÏæÍ¥zÆ¥GÆµÁb&\¡ ˆÄÖ"6ïû+µ[(MèØËˆ‘~fßÉˆM?©HÿÇºˆâĞ‘¶}H–æÿFáË`Nx ½ÄÀ‘^¶C‘˜Ø‘l-š“&S×“ÌºL õş6°z¶4¾;¶q-}âSü^i2“æ¨˜¿Ìêay¼\âÜ‰éÇ)ï*èùµ½·g¿õ[[¬óŸr#O(;¼ç¥nq‹ãiJË (ĞGì©ønÙñ cTó=‹75Â¥çÌ†Ì/gĞG#…¼U”ÊJğ·¦#ô9“*’İÃ`ÿ‘Õı$œ@· ·OwXûÊû4â[—ûìÓªLŞä%ø"¡6Ò^„=lyÑ9Í…SÊÛ"…æØÁöujtis:µ‘	\<˜ò«CæsıªHx=#/û“Ó~¢l©yé1‹°C†
LMz*;ÿÒ„)	6cæÄ "Z¿üLéX€WŸCjb<è¾º‰ Âiah:f±®Dş“ŞC„sÄšÜx\æÕîğ~Iõ@˜=MOÒeŸîº#ò ‹ÍúÓ1‡ëİ-F¤÷Q¶€·^ ?l¡‚C?6ßoÇû\xï}f›&[~ñ×÷=ZâQ3?CO¡CšQPU’{2Ğ{ã¿Š1ŞóåT¼ĞÍo£
OvÖƒ½‡ßÚ<lèD&G ÒjÂnÃÔÓ.XÆî!¸B_®²İœ ™zYi'øÈa=6ÉåÔ9şÈí¾’Æ+„÷ª>¿¦ÃhÆQÛ‚&,Á=€Ì·¢»tV›Êä{©6E)¥Ó÷ìÒ%ËœˆŸòS»2²7$3†ï^äåóÆÉb³57#×„¼U¡®ÿr)[ rÙøØT¼œÎ’£s§QíA1m+èL3¸(œñŞœŠ1h’ÃåË°
¿#TbşHÄ†ŸÍÕ™Ğ!Å¥±É=Î/wÄØoµ]×ştü¾Qømÿïe–~c×µq˜»Ékjë¢{yÊ!Œ(¨ï¥^ˆê¸¯½K;]ƒ._I¬4“­¨!@æª¦[HDå÷Iæ€?Ğ?ë?öSÍY2:Y°œïWf-£q:8Ê[à.Ğ÷«­¶,à¬#93ºšĞéqæTkòC0báü²%Öîáàfc†)=½˜‹š49Óş¢cG— óØ3ıCi<
¾GDüÙŠœ{Òı¨€³=cMu+cŞÃÄ2‰Q”–#Ï®éiğ`z6oîMm®—ïÆ4wÊ)QX£²
>
¢£>RÇ0&!Ú(†~w:M”ÍF´ü@ùôµ}8ü:…UîK”ÁÜ¿ñ˜CZÚ8ãîğ)çCãİHñ„W`Ÿ¿o“–EŒbÅˆ¬…ü'½eõ¸ƒíZcf²ÿû	@¸¾,¸ÙŞrøí…SƒÃråXÿù®AiH*˜„R•šfb²„'NÍ£Û“ã:³9]ş« ´IqD¤•ºĞ‰•L>‘ï¾Ò<™¡wn@Ê“—É“õ¤İòª“ÊúO‰N[MD†@:~²+Pôcq4fùZ&’f8:‡Ø'ˆÁ±×¹â $CU}wÒ"0¡Ü¡ŠXf¶U#tvhTäÜ•Ô–÷ Ùæ„3fÒÚlíÚ7ñ)ÕÜ`æ­(Ş6_*ëdüö‡&ğÖ¤E:0gàÛ‹ïp¥©ÄÀÇ8Í‡ãO[ş¾´:ÁO›Lödù¬ŒÂÚ‰`‹mqı‰Àª˜ é§â¾¥§æƒƒqXl1£¾ìÔ6¢|kÃ„bSPÂbnôr6ãõÂLÈŠ~›–“h> ¿˜U“kÖÈüÔÖ6~‚HêœvÆ!àÉëÜ‘‚½Vßä‚„|7#¸9«—@z·aP	²óß*SÅC8‹Şâ¥ú’Ú\şa€‹A÷ÄÛ"áûÊ¿ÆÜ"d@ñ4º!ì€
6*“bƒ÷ Æ•gu’ŠùçXmĞ¯'òş–é¤†×.¶+‹Š¬e®‰=(°jf†Îá¨ÿËİW&|8u+º[ßÌR"	ÜØ2È&©ØûÌ(G„.pS.ğ–ÜñsÅÛX„¢b&ñÂ×æ H–r ª£®_	Ìæ9ÕçÔçê‘µP5ÏDhSë_úl¨¢Î9èë\ıAü‰rNñ¦zHÀ?¬1¹ã­xìWíùòˆœEB'<ô4	;:Í\!’|£‹×[á?Ì $7§Wvæh`:¥XeK dööP&q·€¤svíC©Ã6PPQ]}Ÿ7Z··Ôw^XÚ:GÓbàWÄ“OxA	änÌ¹–')Ì3'~C³p¬«ãÁKµ™=Ÿî‰Ë¼ö7ÈeL¬*1êUyàà­0ß”’$§úÈ9VÅFº,ûShŠL«l£7[Ñs±¿³G‚v\S‹FÌwì¿¸_‡¥MÅoZ	7<ò-2$}H›T}ÎÑ‡ùTŒk}æØn›Ôƒ‡Ö*×lö˜ÃêOD!É–‚œl¶¤ÉÑBöìo9&à•‡ïV€Mü˜„9¥{T÷%W6¾0¯EÇ:·ºôäÇéz‰Ï^e7jfQø9˜ÕjâsÓ_ì2×k…x$¯.=ÙEÕe‰¡_DüXğ)h÷Sá§Çg×™Ö»º3¬W=‰(å²0³’³­<›(.mAM9Qô¼"ÔAı]iÒ3OüjÁ¢jmF
èQ´ÓÀÏ`¾ıéG4k:¼â½Í¢t¯cÓC‹ğ¤‰°3Ù6¼~]Ã+ÒP«V¬#GÉ¼îé¯~ —Fî@p“[AÁ ÓJ<l[‹÷Í/‚$B´Ê®üÄQ¤pãòSálA	ÆÁ(6ÜŒºDˆ2èüºÇtäOƒƒ\»T,F!}2 —"±ö[p:ß,™:28fYZÑ¶‰»e5…Ã>	<XæC¬GyZÛ<°±}=æ¸œ
ÒOæßI@àpqk/TM,º—Û¯\^°VTô.’;24÷Hƒñ„‘G¹ƒ½gĞ‡„	e*—x
¿ŞÌŒCÉÍÏu·-ü,H¸Î«‘¿‘sñ†=aø”I½‰5pç/NÊ3½üæŸâÉo÷
TC@ÀíM#e=Š!©¹]†º‹¸&–ÃvÄ•ê[°@¥«JQm¥·akŠ©Ó&DB†‰7ƒ(­¾Ö…ì7«H{n¶µ1†`ıĞèoâÏŠòl—ô|µX€Ó»İú®~eµöI¾şïP%³ßÿi°–€cñÊ¼‰A¸×O×:zs¶ÿÔéûé¶¹6€$vgç¢•ÇÇ4ôÍôéÏé·¹£^Ïµ[’FL£o‡šVi²RdnšŒnIªI®*Ïê=:fà“ğË­†8Ğ”mÙ|óøüğwBˆH@³¤ èMùéÉ›{«¢7g‚å¯öJK>;Üºê±ÔİLv_Hİ‡
†JÀ ¹Q©Ì¾ü•²¶òw&Ÿ¬%<’û÷;fÎOdÀC¢±.â³¢Ø;º]ÓE+y¨ãÉñŒ3²T?ÖK±$‹ß!×¶áô¿ÅôCİdùè°0›³»lA-ÍïÙ·ic/¬¡÷æ[æ#oÍêSÔ&è0p“ğ”“‡ ù),Hà6ëÓ‹n{ºçt¥®‡ø±ÔNİeèZèf¥«`ÃóPÌËH é„¢ŸÓ8•jöf`)ÂYŞ¸¦¶?KG¶à‚Şø&ç?·<æk´·û~“Ä@ûd.»>¼Ì¡iHD¶¡˜ÆRÎ“µ,Ÿñ-VÿhãáóbT‹£”2ÏV	— ø[•ààˆÆJö¼ÌÍpWOÍ°w$Q{XbQÓŠP²\‡(Uñ¬!$À-Ì1g×’d‹Õ ¡{ú(PÈÂdZµCğ¸	b5¡»eMLğì02$‚¶İ?& äÃécÈîdOô”¶4÷lù	¿ïº¯ü¯ü­NDxÇB6«Ë%3«0–^lCÔ¬åé7kô8^4W¿9Rgv6'ä¼7.İ¦HL†èå¯õ ñ<ÁOs²ûé¤ƒ;+fF û™JuşÆL†"g¡Z4¹á’&Óóî9fóŒ÷7ZE6ıIæ›.ˆ‡,ÉKhû,è‰¯	qè‰³’¸ÄÁ¹ÒÒT²ÙöEk~ê d¥›w£Is¡/\d¸™­¨Ì¶¥¼>@À¾í¬Vî+ˆ7Ü	:ãiR„
şĞbPûK›‘ÅäœPuÊ[šXê¥§¹ kzGÇ*¸gÀsì¥„ç$Q¹h
øObd°êà‡‡^ÊúLc[­-a†8‚ÊÍ^¼–¬lÕ§9BÄğºâLäÅğ¤à0:½	TOĞ	ºeÊıC}³kÕcg£·ïR,	JC¿4)Rps`ú‹1Y s,1ßŸ½±p´ŸçVÁ›I'1›öH[££ÜâÔY™›ƒ;¡aô}ÃÿX^ƒDéJÙ^ŞêÉY`T“±Şº€O ~ä‰Ôh7à Õdûys«b¢i2 û²=Şj§o3Î_KÍ!×€Çn„Ñã;Qz> éo„@û~øµ6“fŸÕÑ?L¦”“Z4]’ÚE…¹VGév]2Yg&ŒJRÉÜÑ¢œ……9ªS1ó¸Ú]£Š<ÙóE‡Á&™¦ï‰¼m!|Œ*U½>4°‘Bé+L’Vxw~Ó¼Ù7Å{NşÊ¬×~°V‘=U/Ãné/O·…œ'+¿
oËÛ˜ß)[g4”7kxíP¬pİN[¯~³íslš™Õ#Z/iŞÒL*aQ]½õ*ïeÈD‡©m“ `Rg[•#ê7uíGÔßePà¬Vø@¼Ï]#ì@©Œ$µgmó­Ä†¥Wu—ïZ lEê²˜„Øó™—ö¡áI®ƒª¥”`øH¸1¼FJ”[ò&í®bƒ˜ëóf(éÌF)X-üe-P¿{!K“‰\ñJ½ü	Û¨åè<^q…VÒ‚Ÿ¥Ù=\õÃYâ,,fQÂğfsƒÉ~#İ}±‡cÀ¦Ë¢Õdt©›ö0ÍŞsá F‚‡ßqUú±âä…Òu0à\$XÛ	5¯cƒ»Ì¤ã†ÕÙS€?z¹Æ;øé+ø‹âèlXtãóS‹7^—¦/!íÈ™ù_"Û¶G¾pÚiÌÚµ3®Q¤@ft”$"±h<RmïNV¡»IµpÃèœ+³¥<C=õø¬.O¾FŒ„Ai¶ƒ¤_ø©Txæz¦CQ%-Õ‹ÄŒ*oìÄ¦yÄ2ŒîšÄKBÖ£_ìi§Î¯u3øƒªn}FÑ¯ËŞÒï5IF¶RàZ)U=<0m¯ş÷pv½8Ñm÷1m»v¦1æ†¥sõk¼Kt*²®OB#ŠR¾ÊíÊ¯Ñ£×1@ğ™¯ç'ÀèvÜ¥¼T§|+h’½àg]aÊ_MvÕ?8ÏPovy ¨ŞçÙ®®£Ÿ©:Wß¢¥¾YúXª%ÍĞcaD.°®"º·æ»B©PxLBƒpK‡Ï¸$ãÙî>–î"¾dú;tû=«¹¶.Ô¢èôñ€œçÕ¤!úõ:şx¨„ÍqŒıóµL“mêSã)ã¦Q¢|^b²}>P=â“È¾^ÙÄÄ;‰ößÊ®ÎöÄ’ïHõË­uªÍ¿øxúÏ7ıÌùßiÑÃ<­f!Iqø~"ªôÚ?a¶dß/ÓóI‰å9—íà-È¬iÑ?T€gC³'ëÉ˜€Næ…ÉÄş´üSÔ‡ë¬Ü ]Ğ·Êh®x±¸ûörâ4a†IçäikNß®‰a1§®à¦¦¶¹œõæ3ô¬Á"<øİ1"şmÄ? 9+Šİ£rW-¬BPÜ6¯‡Uy"”H‚Â’¼B[–)Ês‡#ûÀÿQe·.àŒßE:Bõ"ÜŒ‹¶
 ôˆ¶ºá(ştÁ™FlAÔêİü¡—™-òûâÜšYˆ¶À-2$ko÷I'òÆ
È_„ñÊï~ÛWo*ú¨ô—µò¾úàR ı£Àº j”íô[_ï…¡ÈÙ!œ„lğÏµ(1Ç¤»;936fx»éÄ=^ÔÓo ;ŠóêØFŸuÓå2ÁhU­Ç7’ÉVb¨ÙË©òyÌbh¼µSİ!„*W1Ş( ç%Å¢Û÷ÌŒ0¯q!ñˆ¿6BœvÛH§–÷¦~!«Å$ò™ÖŒ<ÖïzG–Ø,0,Ø²¥jmœ£¼~ƒ6X;À¢ıüÅ;rÄü
Ú®P“DëÍäİîé×…á.vJm±È­
ßôRæÍ0.`ø•¸êïáÛ¢„³‹§Ãí‚»—Ç!5ä#P¤K¯È×ğ®^:]ø)P‘H¼âó«ì³Pe©Ï	•Â[èW}	„ö‰ÿ¢ÇU5ŠÌÍxŒ\˜ãØÀë½#F¨ã«ú”zîXvEXítÛÁÚèÑÉA”À0”Y‚KŞ¿YÖh­õÂÍM“¨H-v÷gQÏæg@/›:z:;mîĞ»j#GĞî²õ>Q.µZä¤méiÒº”{UxJf@Õ¨;br[ó
;µ(nÏ@˜ÒôÏşpx5cï•Ÿ*X”>€‡D´‡ã& -RÖ££‚¢zŒ‰<yâÙW‘=şÅ):PäÅËúQ(YfKiKĞ8ò1ù‡G®Ìèaƒ‚‚’-Pˆ˜-òsicŸqÿm#ínvDxKgÍƒÁ2$¬=~;Â™QÃ«R(7g¶¾ÁPağ/È¨‚f;õs‘—ñè+¦§à&>
üGØsŠG£•ƒË°›[Ïa	q‰[P´wv²á@f÷åhnåÚ~ı0¥çmgõRŒ¹øÓoFˆ²t
hÒ!¼;L_Öñ½Ñœ—*‰XO]€@krÒBe¢uoÌ:DO×ßğÁ›+dÎ_5Q`Êƒ rA§™“&²±
„»1Xg8†ĞÔ&AÆfËœ>¨%°Ûg¨'Ù£³á_‹r¶€Kçûa®‰ëCİ†sT%p„×Q!z|§kÇ,Ì	±Éœ€6/Ğñ›”ódÆê‚?zğuMó•¿:¢òë~WveøÑ7 Ò£÷E·AH`ck•®ğÁç©¡ÉŸ}ÿg{†DpŸ“‚cƒ«iùt•ˆ)äJŞCNÅU³FÈëÆSèüÏèCfãDJZ¼Ö`œèù>1†a}€ıFîl•É8áòŞ¹9&¦˜¥r+…¬¾õr.R9¢M¬m…šËòÆQó ôtƒY™X­/¬¢®Œy¦’¯bwœÇgú¿ñ²æİŒ~êñ{tt		[*›QÀÌ·QÛ“+ŒÇoª™¶ˆöˆƒÄÓ)ÈıÔ•7·af$ÑÙ/	¬F³ÔUëô6%8NVÍ„4›êª	(¶Ô¤2:û0"ƒÇa5© Eö8¸Ëìt İ6æYK4Œ[ğu´!Ğ¯±[Ì¡ÜL]¿Am#Ú%jÍ`o?fÊÍZDê9)4*™ÏäÆn©í0@C|ĞO]»×Á5ÙÁ5ëªT$Qe0íœ®€S½‡áys¯ÓH°½‰–Éçİ:PœóámvXgdI}æù gOWzß! ½öºNh?Àt ±F	º¶òÄ’ö‘õ"èíUWYGH‹&£ÆLú¿µ	ñ7=àœŞ»ÏK±ßNÿ[ÉÓìZï]&k´Pw`a?Ù<{‰„ewoÙS;%ßó y5šİcl¥hd-AFêQ0!„V^æ eÁ,¶¦1	°¿ÚMhSÔ*}YG%›–7€—Xñ»Áy¤*~ˆğ”ğ
DĞæúk»­{ÉVxBQ™	ú·êë,5¦!€òÅ¤îFf‰"}ÚëùûÂ¶ LO4d`°‚^k´~´9C²,©õd¦ÿ cQZ 9ËíoŠ¢Å%-Şö-Ø^Ñí|¸vcŒ¤cI\9ûºßŞôØˆ^ÚäÕè6éºyõíµš[°2Äõê_ı›É4n¼DSn#¿œŞoÉÙ¼U;ÚÌ­ zˆ`&Î¢J]İæÂÔqW­”ã=Ò*œEŞ’|:gp]†“Ü¢ùék á€²ñ:ó=1£d
›'î¤=wÏÉbS~0£ÖP-¥ü°¸ßŞğtdŒåÿjğ~ñ³è.hª¬éç¢èaa#TièŒªùPŞ •Ïsu¸EûûéNÄ&£óÔØ^š4ÎŞ¨¢A›ßX/Òr5cXšKDåˆãpÈÎÍ‰è  `–³¶ü{ú!:…xî+T2(M÷–©øAÙ»ñ¥giZê‘JYÉ‹¯åÏXaä	 ´Ç7°.âûA"yôÖ{íUªªuNòÇQ)Ù=s8m kyy‘ÅX|ÅÕÙ0ÁY»Ê+`ÔŞiÜokx8ÌQF±NoQx±üÁ{Î¼º9%õèğè,f°dcÍ©×së]†õªKíÍâ_©ÌlæÄ?q h¹ÕñÈÈT6 d†Yqÿööp‚šÜR$jt‰
]úc'éô0ÆDéÕà†§½ÄÅ ³’¨£RàNÊl]g«v@ÛÒRÓRT“L7rxx¾Ú>£/#xÏê®fÀoÑ aeO<Có<
‹¾`ñá+H‚×…Hño  Ù™‡{VG¹¥WaíçàŞÑxÚn’!Ÿ€¡‘N¹8øº!P{åZ·jÕ÷=±b¨Y5ùÊ<¯—^…T­°D"Û7ãä±Ewrqåb[mİF¸EÓ•Up‚ûúlLê´†<cúİV¼¨¼À"åûıÙÉ×÷2üìM¬Ú©H$#{³cÙ§=¸˜,0œ)Ö5²L´uö-(0¨oyÕõÊ°Zß†ÀN¡²£ÓwĞ‘‰4İ8sêÀ¨¢däN’1ëó¯läŒ]6÷ŸºĞ¬8©t{¼×uoñ½¦ÛtYêê‡Ù!wWWûSÕ”Ï×+”,÷À£XÿEª³Ÿ—è óÅö¾şİYióE•üléf×¸Øl1xÒ«ûíZÕâ1º>¥‹“~›Ã/÷ãVR›PVsG•‘sšºø,‘rzP^p›=´l/±‹¹$³®A\ÃG?'àÁĞı¹¥9ÑğÓ±¾L½!u"/–Gñ÷õyĞqıBÒ¤”} Şî×å¤{ã—¯4ºDƒM_â“5NŞÇöÒaßµ!é$ Ö[P!¨Î¦»‰>)«M¡Rø	w'ş`Ü$ÛÜÛfsSkµ“×	Ù‰b\>@”ş›Ä:QIéÒ›±AÛ,4[ËKTK>	®.…eDyG	t©‚ k"µÂ‹æ(0×Ä: _f°bWiyº³0ÿ7ñ3ÛíŸŸ¿<Æ§W÷è•‚T¾Àzö3ã#^¹·CšÖ{”ïfŞ¹4S´ÄS÷¹õ$p{Ôr+äÉm‡)ïä s˜“æĞ k›	E7Îf$ •ë0B¥³ìw€7Ğl…fûÅ©™ì¶"İ#—r“˜ëÂ‚G,oñç¿Öğ·I4 §¢ıD'rAe“)äTö—0š8Û;Ïo<ùUîÂ,W´«óŠòÏdC|G_œü…¯1aCØò¦×	ŸSQ÷`ˆ2œ½ò»>§Ö78‡°‘ààˆ
 6š~<ÆªÒ>¨eKŸ‘VXb„ÃùŞ÷Ğßôùå‡ÑT.Ø»ßKh™(²m!-c©`aÀñ3OkJ_šÑk¤FÀ®º:t,¸= ^ÆrGMO#Üz¸ùHo6'—i³¨hÚs¨h’…‡OR5åOû¾9ËÙíİ3é“‘×gb”j¯o·û”\¾MbZî¸DııD>õÁyıÚ·è¸¼euŠ‡Ê´˜‘ãÈ…`3@Å7LA’Œ|©*Âîo±ŒC §ÕŒ,+%>Kcì)Å+,&ôÂ[0 | nà=~Ã‡‰Şó~*—t@s‹óù…'ôÆI
…ı¤oôY›Î³RŸeˆ/ĞPN‡Øø|yX
d•QMt×•·ÉÜøGæ%/BSÛñl²ùÇcm7… ŒüN‚lÆv!Íwõ†[]ì×/½#ˆYE	•;	hIı^€,ŠëËĞk{È¶ôfP:-ˆçÇµsÉÙıCİe†…r­¼İkRê:àéoÈ–<¯İçU„µªŠ®5ÜæÚkÑ[h¢3¼t:3ı¾!ÁÅîº
ú;–Tã§‚Ÿ•é¹BñKÁIOç-e†`&0ø&Ëpn§™‹Ş…9×1wwI1<ŞÈb¥(¶æWrnâ§¯»Sß¯%l)‹‰™Tïd:¾F±åŞôQ‰
~v«.­úÉø¯ú§¸IƒC÷âäm5å !Æğšoµz°}bÚ§ûkŸé®µÖ›ÊQ„€S“ïšU™}¿†ÿ5ıÅË+›„7*^ßõ
­+ë‹L@ÛœÍq·mèÍ‘ 2k)áˆãÕ:6˜m¢_Æ?“ÂjÄØ­Á¥¹ÃNø×ÉN·Ç—²õJdºÄ¤JÙbzày£ê îıŞØåãváFÖüİ-W)ÙŒˆŠËÀ’Ä‡&J?m›@sA>ç`+lÌeƒn]¼C<NÓ4^ò-Ö7¬)Šà‡Ö×õRD€>a¾ñ°+·u¿«¥ø5Éƒ½yGñéM/­‡…5fsNMÀ¯ùˆ/ÖÈ:¬“/¦4¨‹EpO‡öƒ"©ü[eŠ* ne¨™øæÆ®¬)”7)4Z§*¦?Û
éE¤;·4%ó+Zeª%\|’öw+  ›^?ÈtNæËÕØôS¢ÈdĞT"ôğä“´›§4ˆNË®cÊ!FxdŒ†Ñôœ˜UCôÈk¤/¨›Ñ UmĞ?&NSì´µ Npù=3ßôBhÏ„™èä_®2QM`ƒS¬d1Gã¨Ú*Pæøk=ªÚà@}¦½Úá³çŒ¡uÏwòİƒö“åõ.zçCàŞ`lÅ²£ÿÖşn)Ç‹ĞU/wÒÖáÌô“&RŸn!C°32¿D‡b4‚·‚­ª#ñƒzŒÁØ0WM" y+üØ[ufÓ9Ú2¨»$³è–‡Äóµ]¾ ‘C:èŒãª´¯³<£ÒUÁOwÖñÍ‡tc¡âsÏÖº8TZmZg±/€ÒàÚğâŞ«o"¿{ÙÿûŸ¡¹@ÙôÛµÉ£
ÿÜS‚«;.ÜaJW—9k½TFbòYR¿©¢¬Â:§¢r›{ÉSK{W=`EÙËGÑ<Ì¹xò€´ º1ü°à©¤ck~ã•Êø†Ã8‹îÕxÙ§,‰)3jİMà>ŸyUGJJˆ>±ÑÇ|…@ÔXó=Ì}XFa‹±Ø6¥¾ë47Â.­uÙ9´şÿ«C7‚é#«~Æ˜1Ùû¼{d`…åûÿ	mA`¨¯{¿‹SÚ yJÃ!ëìÈfåï¼]èéXĞæÈÜë…(ĞÔĞU°¨U¥ÀóÁ5¾X§Sht ©Ù†¶Úìí{Uw}qVdgô‚Ç«ı?yPÚÔ—•cö¶t¦+'kµ$}ÕŒ}œŞ×wŸZ*`UóÅiØ¯LšÈ[u ûa×&ìzK¦+!MezÕBƒ›Íwd6¶Ø£‚A[šOmZöÌxøØqEmÃ.s¦Lg©™(OÛ/¨ol&wJîHi>çˆz rÖ€·NäŠ¥†ÊÕÒÖ(J{Å"GrİR@äó	£D!@|1<«1k}¦b³ä·ª·¼æ‡y‘èå-Õ®kh¸ùOt4Œ³6Œ]’%ı®È.C6J{s$v×–³®Óº“—bC™‰ë/¼ThÜ.¸Ìıük®·ÿÄÿIıG²jı¦?‰_r]E6°#®@èÿ«>Ûõÿü)Ñk±a)Üåİ3Ã
(Şœ&È6lC
öÙ±¨¼.ÉO}Ÿ³áØø ò?Ò&3Ì±%Æå–è¯¾a§÷wğaŠ’sV(Q#¥ˆ±Ú'ä9nWjª7.òP8ŒòÛOªF’ç©bĞz3UP ¹‡i~%ËôŸÑ#m/Ğe[ Sèë”L’ôİ>,>N*ÜÄ üíÎ›ùwGã&3w;9°—¿hl¿’±MoOÏâ€yg¥—†´ø¼ƒ\F)B–{n.­§‚Ba„Rê½NTÆf§1ûïgˆ.„[.êKö®@ü&OèSGÜû¡äw¼œT{·éı¤w¬ÎCÄI1BYÅìèáACºnOİ¼K®ÚÛû:˜B®}¢H†^ş İ¤ÕèTgÅãşÂsº°h¥1·ŸûÙ[Í=k¸k’ïê1£*—­×›pD¡.—ZÑp|${IÜÎŠ¼ê$úWæ†Ü>ÏÉ/&J¢S›PÁLdé<\ÀÌéÇ+hñŠ¢µÊ¬¬I¬Ûƒº^Y-÷à•ÑïzN˜²lÏÖG¹'«Vª÷‘	†{(Sã ˆwS‰3™RZ`ôÆ€&lÁjğ(z@ÛLl#¡¿\üŒ3¹³é“‹üK”İ1;AíeFşÚ9»!«ŠF .Ñ	°-zïÊùIÕ{ø1ÎXÃ˜;´@«Â£BfßšÙÎãÃw–(€"\‰¢‘´à×"z•n†šQâšö‚Ğ¿o`õwgıô¨ƒÉh€„Y¹nøÂ×ï 7µ×ìguâ¶ù|[]rÀûÀ›¥ØU ¦>´V¿Ï,àïŠY¬ùWè÷	LÕcàt¨(ñt2òÌ¶>ÃQ
 5Bº¤ì™WGÛT!ìäã'|%xL^XO¨p#ƒº®¥g¹69îÒ>½€I7E¿¯ğ_d-K(e Öù"ŞÇÒı  Ó“0:à=Nep…W
ÿço¤„*¼'UWÊ#Z£Æ‚9¢é·]1™¯Õp2+504cg`üN³W±k¶2³ªÁS«#å„Í¶2ø«¤Èñ%ÈÿäØW&€_d]&™]™«Ã-«ÍÖ0#ÀÌdÜÆÍhÍuT½à%ô%lÛåVıôO^Iÿ§ÒãZKíÒŒ}|_½Nè¹AR’üæ¼VÄÊ	-ƒ	!¼t=+ú&²é³Ğ‘*«	ˆh0M–ãßí†ÅiÚ›Ï>Ğ]öÙyÓÅ¼ß…6"ËsÕâ
»ğ,~@\ß¡üÙ!MÌÅ…j×J8mâ­ÑSºÁ
FÔÛ½@ß&¨'r^W8™ º»û«<çá¢>/À­V±Õ`'“Ô€_<å(Ø$l'×øÏjö+Í–PúÛó;Û9ûµWhÍbÉ3C#¤®vªrğ—p éËÓ™Ã›eyv$ú`á¹¥òš“î! ÈXÃşã«\ù[0ÔM¿Ür:?W³šwqŸ¿]£tÿ^êY>>¢ê*¡:ßŒ?]”çœE™O7KiPí3/Ç–KVQôåÖ§ÕAlÏCùò¯¦íºÎ¦'¯=…@F®®_
ß/@xBaF>h–}<ü¾şYFÄO‹lªnæè¡ĞŸk)níİ`çíLÀì…ÚR˜ãö]²Ô>Œ"Gü¥§
'iĞ&×µ³ñKÓ Ï]©
R‰èâ”y%ãkô"-µ‹ÓÎ$H
»·2ã4zÜ%égï$À‰Ë’\¥Ğ€ No'ûİÿPñU¹ø<ÉPSwÒ8ß-àœç«k¦ËÅ[jVŒù‘êææ‚®p¤ïÏ§–Ş8Ê¯¬EÎv=£>R2Öêü›’[Š:›‰®õ@œ0C˜_GÊ}şk£y‰yc×ñ´Yd.õU¡{.tûkcOƒ®J“3ÆgÜâçoÏØÂ’J€®èn;óeÎïO|së‘üM]äŸ(ƒV¤œ†6•$×ø¡¸E$­J*@€¶7’ŞQ8]hªGád¸ck±o	s54Ş7¯"›z@›Ôô}ŞÕª†£L€Ï‰ôPÌ<lè{¶ÎVcÏÆ½ÕÄ‰Ïú{ñ`d0Ü%¾ˆJ/Ë!ˆâÇÂrßØ¦F w„¯£@å{[(?²èTäµFo¦¸«^ı£æYÆØ¨ÏnwjÇé·ğCÖÀ9ëYm8ŒĞKÍ[ù¿ï¥M>30óÚñùX«à‡R
Nhø<bùPÆ”NĞgğÛÙÂJïMæs>¿6:;_.¼`%§O •ñítiMòBüØ>¡s-©sz]p‚Á¿‚z9ÛÆwĞÂ¤Ô	ºÏ"u?«ÃQ´ÂY++$<Š¹;nÑãq~×Cœs•ï+Í!Ô?Jér¶úÅzÄ÷­ìª\&=øõÕ?¦˜u"^>³¼…ä†nb›ôHQ‰×ßy›/“êvR—æ¬mê=¦¯y2¿Ô IíÕp¤ŸÒ ”Xs‹RÄOÓZ }`¬²zéi±•¸ëûÏµj—ãàØøÓÃ¢$Ê!^UT†¨ôî"Æ×Œ	#ÅÜ ¤F÷Æ‰(+¶5âñÑ-¾üˆ‘Rµéò3õe   D§óÛ¢sp ŞÎ€õW›±Ägû    YZ