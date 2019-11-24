#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3703434657"
MD5="a2957e284036353635ad96c76d099d6d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20360"
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
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 08:30:41 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=128
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ áiÚ]ì<ÛvÛF’~%¾¢2G’¤nN¤ ³IÉŒ%‘KR¶3¶H4)X¸Ğ%Í¿ÌÙ‡ù€yÛWÿØVuãNP–Ø3»+>ˆDwuuuuİ»¡ºúä‹ğy¶³ƒßÍg;ìwüyÒÜÚÙİİŞİ~¶İ|Òh66·=!;O¾Â'dîòÄĞçæ¸õÿ/ıÔUK·¯&¶îèêÿKö{k{§°ÿ›»›;OHãqÿ¿ø§ú:5uª³s©ª|éOUª9æ%õ™iè%sjP_·ü<Ñ—ù.c.YoY¶-Ôßªm7ôİ#£™I%m×öBè’ª/‘ëì‘F}«¾%U;0b4jsGİl4„Êf¾é5>§DÎJ»LLF<İˆ;'ôÎ\ŸâïãÖÉ+˜ÕÉøÀ “+_÷<ê“¹ëÇpRLDÉª³sù«pR¢×´wºgGZ#~lFš\{*Ç¸˜ÉÉÑpÒ;[ÇÇÚÉ‚æ"x»?ìjrÒ~6êN/º¯»ít®îé¸;œŒû“îëŞ8mnÃ,“ƒÖè¹&£\%(j4ŒÏF ,U(Poút¸şM‘ï°Í>•Ì9yCØ·ÚàUG­×"“wû¸sT)'‡Áü£+ jU·¹çosvòé‘æ¦´šÅµÜàÂ%RÂ\ ä[3smÛuvNùÖH(Æáæ‚îø¦A™Mcj{‡¦EÙúÆ-‘*1¯ÔÀöÔ<t}æ:sà²Šøöj}XÕLØ>§³k°ïC!ö,4\bS{
›#q€3FıA;P Ufz@TÌÔ…ï†ù+YøÔÃ¢ßÛÏD5è¥ê„–Q]ûùF#x7a1•e±kJAŸûĞÒŒOëĞ«AàŸÎ'shæ7e …Ÿ‡¦chµMØáÙ¹2„º!Ç´ÈµD.§¨œ dšfÚÆu®v‹_ªš UïHÀm`1	\C2âÂû`ÆLøVO(o²²”ï¼ƒ *d>M‘48 ujŸtø²™N#ÍT*ËjXK~åZNf†N^ç€(¾]ëë¡lH ÒJw˜w*&Éà“K”²ö4Qª¬Î×ş´rÖk™ /Ì@ÌÏfÀçô.è5ê\’No48nıªÕ¢äuëlü¼?ì¡-ıM>Ÿ>ÁURËY¶"{¹0y>e¨G»Kèµz½.ïûT7¿Š]EèÌĞ	!hqı¸b¾ÒHJQG¸H®PR©’JB,©šˆÍpS,››ÂJ²­¼1"ÖÖM'¡TÂ'NV¡]7(¸O©’jb$°r$Ğù¾ur¬Ìyˆ<¿eş˜Â¤vFBÊ	Wd©’5° N>,‡oE-³±äÉãguü^80AP£\_ şßİŞ^™ÿmn>+Äÿ[Ï5ãÿ¯ñyî^¡M
ÍÙ¤=©Ò$}<Ğ<BË*¿$UÆ.‰âG>ô{nØ0vÑÆWò©¥zÄè ÿê$/…~TÌ¯¦ÿuT€`ò¹ÿ‘ü¿¹¹¹]ĞÿífóQÿÿoæÿÕ*?ïÈaï¸Kà¢¶şIkÜÃˆíWÒîŸöÎ†İ™Şä£$é†ÄÖo¸À‹¸a aÉ£0ÿæ{2…gİLbŸØ®aÎMÈI ˜a|Ü”ËeA=_XÎï=İg"ªË*Å‚ğĞ«û¡#U³C¢Ÿ(ŠmPË´ML:w®¶~AµæD÷!ÏÈÜwm0  èèV„ŒAtLç{ä<<¶§ªñ°ºéª_§¨ ¥õƒlVóVy«@>CÄÊ‘å×î0Ñë1¯¢ÌMŸÁæÌf!Ït(p¦NŞ*‡a?ğ^÷xE‘òV?
ì­ò×´ÿ¼äğoVÿo6wëÿ_sÿgXxU¦¡iÔ¯³ó¯ÿÃfo/ùÿ­Æ£ÿ¬ÿfı¿©nn­ªÿıg ¹ aæ:©áÈ ñLòoŸ,¨C}vBÓ¿ˆG­áÉå3¢’VkØ~¾»­–cø®i|%Ç.UĞY CŒ‚;ğá¿\b¸dîÍ¢4N7tâ¸dĞ&XoÔ±,wùáï¾©_š”+u{jbÁKâÒá uçŠT±Üî¡É‚É8 ÕÖ“J°ÉXHë6°<Ì°ŸÀëyaõ©|6 $ÍêòS L*˜Xşœ8ôjr€‰0^vİßçÃM'¼&'C‘æI™>“rš)[õF½‘Çs6<ÀB59ÈØ¥SŸû";ˆb¬ºë/°I.ª¾`ªO-
ˆ'[“Æ¤!g0–Éqï`2hŸk²2_µÌ)äPÕXûğ(CˆÂI«Ïæ‹"Êa÷¸Ûu5ùŞ‰_v‡£^ÿT‹–ø ²ÔZf¤œrQlÿ\Ú~Ğ’¶ï]ôbwr/ãú‡İ	hš…‚¢,œpi]I¿ÊÅ$† 4såEÍ0’ã)ÄU‡sS TŠ~pÑ¥äuì{âN}s¡ş	…@‡A/yÊà“Ğ&@ğa¦=ığOËœ¹|î
Á“ÅÏã=s“Ë!
»ñËƒ?]âr	¿W±W,à3¦ŠÖÆÿft7ƒéäªK÷uÌÎÕ¹9;GnÛ *JÛFT)—k¹A2Ñˆ,/Ÿ”c.rTY5ÕÃæzØ2®_é¥*Ïx“óîÉ¸¨B¾K+$€üôBZ†Ã$<B'‹Ó‡g§/HbÈÇ8
‹ı9Ör ¬¢mÖÊ\ƒœ€M–áj·Kmß¾UŞåPGG1ØŸ{ƒèÈtû¸wzözò¼Òå‚ÁÎuˆNayÌéÈ`½<·î¸q,™ñ®İ«:èc}ñ›\²ºDK§Oäòvy¡w%Øğh#’ëR|jUqĞSÂº¥¦<É©c¨-¯ 	<D4d€CxAeõ(€æbòâFÂ@(&<\‘°©qNË·Å)ï¹î,hzn¿´P±[¤2cİ¥
Ö6È,<z_ñ€Ó`9™ÿˆkË¤=8›Œ[Ã£îXÓÁöcMVÄ$veÒ%ı"¢"ía4€m ^>k¥=y8x¹%“XøÃîaïµ†;S\¨òåFàJ!M£–DE*é„Œ8öÏ†í®àhFÃ‹X1D­_†AÈ‡ßL/f‰<YIöŞóf×»ÜG–§s[#oA°€iÏûw‡:à"]ßwı=rhYfÿ•¬úÔnOûÃ“ÖñL„Õ2!àŠ¬RÉK_NMk¥Ú/chNSùíúr¾ª¯/eÿ2PöÌ¾ò²
.gV«‡™ZÁ®ƒDÅ{VZşì|w»TbÈJ¶;³ÛĞÏ_"ùyíx~¸$íeÔİ'P+ïg<@Š&%ÎxÔˆ£©`I©Xá¦|”_Ú&|*—ªŸ¶}HòG¶‘#9ŞsAóåöƒhn#üa›ÈC¼‰¨ +·°3IlqàºÁ(ğu+[|á…sú)EííL[æªËáqëhrØG£Ù:íû½Î$’£Â‡,NaÄã57[¬újPÃcgS»Şş9ää<</™’Ğ—ó¶$¢°š½<›a× ÍÆ¥Êˆ¢˜ôÙ…¾ Âãvº‡­³ã1|£Ô¶_Ä	»éôš_z‰Ã@R»E€Ñ›ï{w÷ÉkÍ”1‡«ìÿöõ_~Íˆ‰› L¡†	®ì+ß_ÿİŞÙÜ,Öÿwv›Çúïÿßú¯¥_E·lı¬ÿ’ä¸7–HüëÁCÊ<×aæÔ¢¼¶ËâAoîb£*c¯••ğºZ½ş•îˆ;:Øêî™A/¹‹ ÄóM'˜“µÑÙÁè×Ñ¸{¢irÈ¦ò÷¤5oMã%u×¿ƒæŸ^vO;ıáÏĞwÒït5¹±»»GÃş$í. ¯üÖY#ä¯P*
¿!Ş§õC\ª¡î4•(È©ó&¤Qÿ¯|" ñyÉ, g1+úş*ßŠe4İÿKh^º(-	K?ü#[c{ ÿ[r€÷yÀªğß`ÎQËfáÙì*_é!ŠA@£¨§çÚêâ˜âæ¢*Ş*‡/^¼‹$by°”=o0E…2Y<L ıŸ°À×Ö‘&¹Ú;„µ“ÈcËÙ6F!|MI8?F1±xzmÄ? Î°£ÚW´›TŸšJÔ}hÕ†ışx‚¯:Æ…êYz ªa35‚Vj£NRØPq›À³'Fs¿«Î\Ş5v
¸×µ ï‚ØZ-'j»ş£êùC¯@İ"£J0•Êšræ·ş\
ƒ¢†0Şb¹ ÁÚ'PŸ~Æ?°ÖÄ.ÒõåÂïIJk®Q$QPOª YxÙôI|z€U!DÅ¸n›5¼4[À‰@FˆŞ4Şñ >/<Q‰ºQg’z{-ÛƒF3-‡“™æ\h.(.l1¡Æ‚ÂÓ÷zªÇ†(r·  u$Îr¢Ì=¦O&r†:™¤0UF[†6 c;ğ]4´Ü„ˆx¢%:¢â—Âñ¦µH•êè ı™”]l< µ˜i"*Ñ§­Åõ6^GÄ¿{µ£a«sÜÈAäÖ€_=l^ şï/!=°tçw"¾Ÿ!%š@~øA<à	(0’–w[®eY g“¥DïM–Îw;³×¹^ñš)æ”ñ›Q¶€tjµì“L~ş™•ûG“á¦–e-Gòe»“%Š’”µÏÄXÜï{Ñp#_‚$gäRšJaòL¶^”—üuĞ5B$_<qAépÇ)#OÊ…`@‡QŒû×è|WD- ìã~¤å#Uû!Xš÷zÜ²P÷M—€¨‚kºtgnHòèÈúğ1¬lH¢jÖ¿r¨ß²,Ä-¼=?†së&º*¬ †Xúª…l3RV¨&°1WNäøD%d"J!È.4"Âšfxlé¿E.ÃvK®Ìßt?òvbµ½NÄ`xüskx6Â
»ÂÇIûJ*’©"œ9k–™¦T÷Ëz=/ëŒÖ²¢—)ªòGyTÜ =ñúc´¸B7!†˜ƒŞø”ï	à;0 1ñúº©5öÍŸj·ÕsŞ<}w·o~÷İ0ıØ¡Aè•3ßİe,Ş˜Â½ô'Q†Ëc£ê.ˆ=ÅÊ•oxûsÁ%2¹·.ñvÄtì.z¢1ã2ĞßDÎZËFnŸ\YB”;ä‘"‹ &å*”&œ|$.”½L*ÙÉ¡QY+¯ÔË=gîîáÊ¢4ˆqĞ^±L˜ô“+×¿`>£s_õ‡/FwS¸¨öGÀÑfÍ3.ÄŒqÿi¾ÌÙ[ç¼¼Es–‹ãìwö^­VhŸÓgxg„1éÏ?s=Çışñ(…Zjâ€§Ìy\æwf/Ô2›ñPØˆÌÆdFQ$&“ÑÙ`Ğµ{DI;ÉeSA“¸W[Ç¯èÀˆğ´?îş:A˜˜;?vÜÀœß@Šë j¯PĞı$°*–ŠsoƒğÉÑ«^‘ÊÉéya6¾Ü¡vÂJ.†o{dPt¦HöH™¾uVË_Ú÷@Ùƒ9ûG{çDbç£¬ù÷,'gSÅÕçè_±¸·ì: ‚&é²0ã´©Œ¬±9pù;b'Ğ–ÖÁE^|»QuÏ³’{øI¤Xñ¼0Ÿ}\Ø@ÂÀB$sNıïñ}XfÌjXÀĞÎØ0ˆ(ŞÃ'ëÛ¦MUOÔXF¶6mn´˜7gÛÊ.×ãQxjäßtD3éâËïD~#Ÿê6ÕÒ-‘w`ÎŠ]„¨v¯é,w:(ò;E	¶uÿFY—Â“—ò8€O¢J#!^§Áel[	A½ºµ<L«WMèb<ÒòC6q}úêĞÈÇ©o›nis4L4İxTk¥û±¡’²àñ…ŠC-×ÃTû0Ûş2Df8‡È8¿Ø?:ë¯Ípq_ø\Sè½:i[:cEvŸÀvr²z¨×Š¸Ó¶ÏŸ¢…cİ÷ ÃŠx©¿¼Ït°"ÈÊ`s¾Å§¥ˆ„H•6b	ä"ß3s
“ZúXåz¶Æ`š¨uîÄ:C‡>¥Ñ#8µ}Áı<“Ş@FíA6z³·÷ZyÑé*§°”KÚ½(ä]ºÿ9
0,ä/u+¤Z˜Æ_+â®§‚oµJÇÅ×vµX'.ğí™)‹\[‰ÓšœtOÏ&½q÷$.
”êæÂçÖ“ï®IÙ8èöJ;`ô9\ˆ'îèÅ¸?àç» ¤Ã™º¨&ût¼§sN-¯¾p\›ò»ºr­²P[áÊ"4ŠÚ3µ„…P`ìRA´­„è×ÏÛª£¡IhKÕIØìdsCıÚ¶>ÉEŸ~éX¢$ä(’¡›ÓÑŸ`ãÙÁ{0îmxÒUq¶™¸ƒŞi'Séé0á÷_Dµe`é“‡ñsl :P"¥J;pY N3‘¼k“¼»Õä»dyÉceâÏïP
øIín™œ¬—¹,(ˆÊ½Zf™ÄÄ• ‹ö^¿Ôãè–iëé5Í÷—¶ŠJí¶?èşrT`¿SÀ@8ïE·ˆ[É§2·~Ø•7rós%Ëq[ Û$“9ÒŞüä‰Uè}œÑ)%.‚éÎ9?¸¤`éH<^w’'Iå¤’¶ßÆ?¿Uá×SÀ§²ÄÄB×>|ı„ K!‡%¤JõÿpE$ÿÿ>IçÎ%¹µÛ<õ…,7]u	 LAK.ö³É-ŞZão$P›|äˆD”R/øş›d"Sz5ÎJs,¥İW‰Æ¬Ì
à/@0ş?ô˜i-´ÄÇ“è‘Ah‘ÏáÒRÀıæ†	‡2Ql|Šı¹Ğxf”‡a˜à |Q-‚L—±µ¥Üu ÎŒşè×‘–=g¡¸¶˜·K3¸Á°Dä¡eElæ!\’ßùÂh mFÉvdq@ğ,uÜÂl">ˆY´F<‚_!9ß>u.âœVÛÉ¬f„¬İûïÜ)îªc¯¹8­­}r…$*/•:Å¿«‰f(„Ÿ‰ğ®eÎ±ñE^q¶VhàL©E“‹‡ß:“·øîìªğ¥­bcô¬eN%åòègeNäÖÈŸCîG»´šœVˆ­w<r|½y™°Œy/(||)+‘¥w6¥ÊrRŠQW7
úu}#şcÑ%Ì©`|¶ôOP>›1Œ¹õ7µÎÂi|P‡gÕğ3ëIQ`µÚz ›QšåğD|ª1”íbõbœÿm OøÇùÿ´÷mÍmYšóÊú©¦Ij€ ©K“‚z(’Ùæ- Òv·é@"Un[P’ÕÚ¿3±û2û0¯í?¶ç’™•Y•€4¥vÏ’¶
yÏ“·“'ÏùN`>mëW5š”Zº¢_÷à¸’É®ßù²%ıú¿ÅuğKĞ[rJÖ´ZÎWzT
úQ1Ó…cà¿†F«ôC›Ò\giê‰,ŞGÓ·¨ì§JÆÈW(¶òz‹®}üJ„Úß²Ñwcœà*†Û§Kå¿Š¦Ši¬T®ãØ3Pƒ£
Ü^Ù˜³ö(QEÀ¾—¿9îœnS-üî*ÓŞ¬~æaáŒ…_Ë3Õú~aŸ\9SªìÎËêêF¥2¡1ˆE•i­®Û«Be.˜¤rm”ĞüÏŒóVt7Vkç?bÕç?Õú«¹D‹rbCœ9µ&÷+|=–J”¯XUuVÜÌ(LªC…^Méê˜0'”Sò%ŞxHD¡>ßáEtŒç™…nF*ãfu³Z—çàÆ[‰Ñšô­dG¤l$ó‘f2ƒ‹TZï•ø2ŸÈâÓÂŒæá¦‹Z%¹7¶I¯;N‘|H×_ü{5œ½aŸ?	ş;èÇŒ ?xxJâïë¤7®Nû—üİ./Ó_³‰üÆëe#õğvn|ùï7XîBZ ô¿j0JX'€ÿÿsÊß(ÅéÁtšùY“Ÿ9µµåšXŸi],­dj|ê$ı1W=yÇ%Ä=Ù2Np5À‚¹ªN¦üÕ=ä8¸è^÷’€¾CÕí·ØGõïË¢kÿhÊ}ü9d
ÂyŒOYéğ]ğd+"ÊÀ'Ê×øşú}ú•C¡¬ÌYùõ31!ô¥"gSı!‹ŸB< '°s½ßlà×¤NèßY6”_4KøaAğ—uîşd:ÈT±ƒv1Ò¤À™'¸º¯Ó/™t:1($Å£¦’ç“ñ)³¤„^Dı‘Ìê¬…gÍñÜÒKYÜ¦ŸY0¬6“f¤âŒ¾ô)EFœ°#èL¥ÅÈBb`_V</Õá`Fmÿ.Š‡¸ûëdóšj”uQÎÕÚå‰su78·Up‹.*]”Îkj©``j·ªïŠ®d•­jıœFjüÊİ‘õ_¬õ²ü•›T°ô(Ì/ÔÔ.™WÈç¬©DCúŠ›ÀGôš!Ò:•ÑœËD
€ œ†}óxÖ×iãĞÿ“âæ%RúvJ8íy}7Ãˆp„[\™6îÖSÌÖn¤J~·Q\e4:U¶1®·œK±"IFÆ-¿§9Û°X-YÉ‹ákiSªRm”»Œ<'>wç·ˆ‰:PvÛŠV'MÍp!)ª2d(–çøòó¼PIÆ/r¤ÆÇb 9y_,›^.¸xØO¦IÓîÑOo}pbÍ+¨,³™Ü¥¼ÈL„Hù¬©%TÄ¬ÿ£Ÿ*5Jeæ§‰ÎŞ·„É€PÅ„Ğx~€ÁÆ»Äº¼M4ç]+$ìğrâ²Tç;_|Æ&Ü¨dÅ’ïãêR¨CİÇÑ•¼ùX²Q:M.f£>k¤!€ö¡n©ÎÏßz–N/7¤ß]ùEDZJ/ıÎŠ0ß ûŒs°“.ÍİÜx+yy‘êÜÈüÁµDÊÁo<¯–<Ho9€Ãh’<Ù
v17A,£°„…,ƒ=”•ÊÜvŸòĞpÍ ûHÍå‹ÓOF$É½Ì%¦vP±óŠYáCB ÒÑ+(µóuZ§§ûGo:Å)=/gò{Û¡%,}2ö­sÌ~»qŞàÇ35M	º¥5„£©+»·’OµFçl9!ş&»÷“Úy­œ‡.©Õ®ğş[$ù¬;îÉ|Ú{#Ó$·e’Ã0)o—d›%YVIÊ(i¾MÒİ˜$e-’à÷LŞ÷ê|®ù«‹ì‡n—“íˆn™WÚy_È†J›&eĞĞ[5GÊuû#m™?Vó:ílÏâNÿóM Ï²"K?×M•”›“İÎšÌaFvçVdË‘ÑÚ0ÀµCoróò¥]ÎjæíÕé§Ô¸3Ì£sf‘àv¹È¥ÜªAÙ:ˆ_º}?æV~k”n·ıSş¤ülJl„CŒsÛì˜æ‰Â))¾ı¹£n¬±p:j¾oGC”ä…‘(ÀsŞi¼pF€Ër$cz¶Hu¬²îLÂX¦9µ¥W±†F	«M°VÆ¤c¼­uŸfàyïZ?“—|ÓAWëè»æT¶•’m×§òl“HÔT*q¡Ç¹eBºÈƒ=oï¶ÿ’¬®ír‹Õ”ÈËÒ ¯7Wz	”}­üp}5A^u|	HDÅ¬Z{{` ¦œœnTà2Yà’`f±óùRú­^Fh»²Ê?,˜ê[z‹¡Dı1çXQp­ŸtBºfD²xB"/è¯«ß+.Ú`
€téÔ¯U•ÄûÎ¢Ò$¥İ¥ÑâUÊŒBú(«"„Ñ—ûéóªSg¨`ÊcÌZe¦ÊsqFÜ,PÇ&á{–Çåte•¶~8º¶ØöÕçBceÇæ×«>Ü zã>l2Mÿìôuå™ÿ§ÔËç¼ùÇÊóÖè:ŠÇ#TÁ?&0„bàü}~Àµ¥øi¬1~î×Ş‡a`WjR9M‰ÍOHøÂ—eI"‘oC]VÑ•f~^s´‘¢×d_LM·,äÖèTñ
Ó‚Ç\0‹—P.^N·Ø40ø®Ö‘¦|n`ı¬+L›d2€âúlÅZ^SÖ‡|®Kàœ0ÎgÜö	Úu haÓÙ˜ŸÉ‚Á;/¯Á¸|ÆëşÊº rVJõùXj
¾ªò5
ó`.Òêğ….`³¸€‚Cƒš°uÓ8ğL},¬ô˜í‹‘9E…çx*7†«…“şÛI¯‹ç<×WxÈ:¤z)NjÅkè“19‡Å³dâ-JŒJî©i· ˆÒ!ó—ü`[§b—Nşxq+Ñò7“œ&é—¢|ãw@ùÍ/BydeïÙş1ş?l—³_Óÿ_}ãIıiÎÿ×½ÿï{ü·…øo×)şÛFµnã¿9Ğß,7_#†6™f±İˆ}v6áéœ.iq »¹º‚;ö d^Ú½/”ƒÓ
’Õ|%Œ·Ò›ƒã—»â»İö>t¸ÚWãÁ8F[å¥ú»V{¯Õ,¯‡?Öw6ÃUí2üp·İ:8æ¨ˆÛLã:g/ñùfw£·tğQëM{ÿTf©§É¬®Æ×µÊ¤d[VÂİ¿è¶ÒpFš•Í„`/yµ@›rGÖïƒ®‰‰Gÿ
vİ\í‡½°¢—Eé‡Š!õæU¯ÔëÓ|ÄˆŒZ•ËGÒñ5röPÌÉİoØ{„Ïï}1D€ÀhDAˆ(¼"tj+OŞFl•~K·b-Ì“¾`_ÖÚãKyàx­Ÿû¢?Ã.ş/şğ¼‘è¾Œ	ˆDV^»F”‡—“GµcÅC÷ë­\Çn“HÍ…  Át`³^šåT–È+Mgñøi°9úb‹ºÀ úéåÚä!Ú±ÁÍÕ£ã£Öªƒf6Éür#CÏ¤{¡ÁìäªDŒ¥9!c9òmÚ±·ºĞ>(X¯E1*+²¯$·&?ßôóù$x)ˆ¯Á¤ºªßDIò²ãèw¨ÎQ¢¹eÓ¶ØåškåµrQx(ã •µÁõu/‘Q¬)ŠæS0[¨Pú‚äÁškë®	ø‡?dˆh€xQY<÷tkÉ“ºöâ£B•ûœ¿Æ„Ö•–?Ág­v^«‰Ïë&½LRb@É±Ì
{”Y)1Ÿ,6±Ç’ëş1¨ü²[ùëFå;?­Û¨c@È…ia®Â"L`Î†ˆ“À£™mUÚÕºâö*£j'y a©kî¦GÃ ­TIs´:'û§§­½în»½û,Ue£J'»9˜¯şP²zà—Ó™*éœ¦u 9I&.%Ğ§Âæ°Y Ë&“º]Ò¤úÄqğ'©š‰ÜœëéO´Ğ)¹ó:eĞ¦œ~s7Ò’Ì©‘3R§O:¥ÌÂ¢–âdÁ½áıƒ>ü'¨T¯„IéS3D—¡“ ÁMÿâ#Zü‡äÑJ¥E)Ğ–‡&^)>Ùf:zÒüëj–ë;ú·^Á°¢ÒP>­pİ7Ë›:Töh*—-XË–M%u\0…”50ÏZ/+å˜w2Œ™Díõ:ÁõÑüÈ¤«{œF"®£ı˜òj/è'iRãÙs)o´tî@½a0„4w“¿il˜ÃVî™rP½TfÀµãØ4LH.YÚæ$ù¹Şêl	5Ç˜Z6r¾rù‘È`ë§€AÿzáËm ¹õÑÊØ>•æeÊå²-€´¦$ğ÷ÒùóÑ­ºïÊ¶˜ %~üÅiAš(—’;*œZé¢.%Puğá£0æqF*›É(aÖõ›MËôYú·ŒÖëšéœâ…n6×ÔV›eEU"Gj½®›ÏòwE£·£ÁçÛo&‚ÒõF7“MËX!SüïÊê˜Zt3#cƒVÉ«=OpØ}¸Ãh¸%TºÇ±gU¸œ‡p¢ éX]ö	¥og³i õMÂÁ˜‘ML7éñDŞ¬ŞÓ‘ğúäò$ÈĞ=3(j]Ã_…Éù¨×-XßÕj§Ğ‹?4€\øº3Ñ.Ô—rˆ19¡“;™öC¬Óöšòù%ÿ“júwïûw±üïñf}3+ÿÛ„À{ùß½ÿß;õÿ+Íiå,_ÒÑÃ+åë×rå+Òú)Äœ0{¿’gßÒ.(àšMĞ¬0$0,‰#;rc¿E‚Ÿ3èYÀ­wñY¾éFMíÄÒ|ô÷9øØ÷<ë„ËÕeËÄ2vE8âxĞR@IMvWY•øRA3d¸×Š6[ÙêàwM‚ğKÑ#×¹ò'GqÄ)ÛÙ´[eôÁLÂ=0Yß•<	%Ùı´;–~½øÏ""Øeiº¥UåìÛÌú¨ı¸\)YP\!Ôé(ã2úĞò¯ãÑŠnk ª%n¦b‰ê˜*]Mï@ÊßÒº|"Ú¢GMñ÷‰–+\=}M‹¤4[RİÓ8ÂH–ÅH#2‰ìùæ®z÷èta½˜f~¥2EşnáU8íLƒé,a4d²ÖK7¶›·©¨Ğ³áÿ§g’ k¹1û"Í…«®§QGÇİ7gû¼âeŒ“ì(¦ÖrPÃ­'74H]bÌ8ä^¸<şW
!aCı÷_ÿ/¬Ïd|#7ÕAjÀ2	zpuİ!ÒKùµi®‰òZòîJT¢\_ëæ>/Åuì‡Eu'	!ïL‘+İ=&Ó
‰SG“
ÂÃÌ©Êœ¸©'SOW[0…|å˜‡.fMû*DÓ¦#2âûú­î{+v·*L9ùI±2Q¼ôô[@²A=PbİWoÃŞ»]ü >8”h„éi¨aÈìD€÷’·ã÷¬h¹{pÚjíî×Ò^Šô>£™rt¾*r8V­C[1ëı¨YX£5éŞm ¬öõ=f,Ùd'u@kŠû•¶’Ë—.ŠI„óÊIŒ›b5Z­½îÙ	nk-rW_O½¿FÄ^xĞ÷Úñ$ıyï[!;+¸÷2ô™I‚9­
×òYş¯;Àív»êÏ¬§NuQı>ˆáü¾Ú6|vªæ>SÏÚ	·0ì?³„NyNQ¯?Ğî:	ù[oi6&g³¬N;ŠFlêuÆ¦rÎEG&Ù…@¿kZœTÑP<Wâòr÷¨û& ¢VuPw«À¹l^ŸÑYAµO¾¿/`#Å>p Ï^µ³µaWÕnÅæá9GÉ}M§,ô©,9ª	ºyE;¸Q8%4ZÚ/¢A4ıø@œÆBbÆx/Ñ¯³qG?JVççò40Øğù8½¨]8™0<ÙyQíÓê@tã.vû‡PÃÛ´¬îCå¶t6Šø`@ÌN{bz*q=ÏF:œ­6ÑŒÀEóæô(èB$A$úäÛæ×Æjâdæ-n;ÆÌ5—ÜÊL^¶8ÂÇARwÓ$J)g‚5©T&³ø*Ôk÷•‡pà‰Å	ëõ‡t2Êİ&	§n·	’2]³ÁÔÃ  Å³ Ùã¯D	éÒ*˜¾íâ(á£Ùæş‡ëZó™ñSd^¾B¥Ø¸pëÒ›WåJ¥÷¾iŠ2ózòQù}„¯ÉôìC¥¾|Ö<äûˆ„4Ÿ,æ¹¤¶Gjİ¶€J"L~>êLÇ“	îRe¥tòµ?í
¤•oÀ¼#şy÷»]¶ìğËi2]»,@BM«%ÖI`ì1šXÖ¥;/o<(+G5Š™ê‡“Ä“?öBœ£ì#É8§a§7Óá¤¹ZƒÿãªÆË"´¸›Ø[Ù>³éö°ûıá–ä|³Wÿã_s2“ÚğPè%À¡JÌ€¿µ×'ĞClõ*{¦k‚•")‘òv~ödûgw$ÉÜf¦c÷¯¨go2¤;òÉà=ö¤Ò“öiBº(¥Öu^ğAWÂKr®ÄÚ„%:Š£É
ç½T_ÑH]Ïç6‚·áV§–yn)’ÛŠ1¦æ2,×d6Ÿ\È¼‰w™(“¬V¶JÌ6æ½“9ÃXä¬Üfoõ‘e3çC–'òò—"\µÜ!)ğÜ¨ÀÆ1¿¯ÌF°, À)ĞÀÙ¸RÈŞAé¸2/£•a„®é¯¾w³’ãläáãb«=×Ö“ívù`ÿeG]Â	Šõ•¦\·hÏQ÷ueŞ`ÈÛçŸøJ½á;ØƒÅÍºãVåÆ°ho1‚åA´Wı$X$ÏÚÌ9™šhõ€-ìNãqB†f'üîm™7ßMë%ÓÒ€ª ?Œ.¡ÍÚÏºòt>ë´º„¿ËºzÊ Ñ@æwb“Â£nM6ËYû ©1|Ûev}«XŠL±ç#»4æ&4*5¢ì¿juZÆöîaîÀæZ¥2ˆzá(a“îí¾iµ»¯÷¬”ht¦ñv4ş!sêî¶ß´NÙKJJ;ŒoCôü{Gç{y¶ m¯­üœ>¸'Áö®Ó8ĞMØ6àF7NĞ–øc¾	âv¸dVÅFsó:ÜàÏëçânVv“úR¹¯¡ü§e~ìJGÔ\$§RmÉuØ*dAl¿§]tåÇ•"˜¼ë’ú²v$gõk>Yy9éõ9ŸŠ‰ş#°9SŸš°Gã.ù·!ô{XŠMüåÿæb©¬®üJv †Ï-¹!·’5ö×¬»½ÊZ­•9HæVG½¥U“t«Òª¯p‹ÆQ@~QL?QH ’¼Êáµ™B˜ÛÑ‰#oôoÂ©ùZ„ymÆÛ{cËxÍx É?áJˆĞş=dP+£ÍìkQp–xÚvë µÛiÕªä 50„âhTpuWPÌ”sÇ0±µS«”¢N+SAÒÙİMÑ( ª~µÊZ²úYúùv‰ş<:Î-õN˜Ç‹Ä¤>"^Ù³\ á¿çèÌl¿!š7\Ip‡ã>"ë@©ê
À^ùxÜeôjz~Ğµşµ¥–(6^½…ËT-\ªÆ:“‚<?[~L;m¸p}[ «ìÂù2ˆèÂ1™*cñˆ®ºrRĞœH'P¦5yæT¾pöä‹¼£uX‚Õ>^#k‹ş‘ˆÄòZ9$3ä4Wz‚ˆæšßÀÍÖWPd_ĞlbŞM·Ôf‰	U)úã÷£ÁîQ¤’ËÂ3™yòAŸ	G½|V?GãËX,éN{éÔÔ>“Ví+pL„é­GÎ,—k 9D“Ù`€#ÂW,¿üIÇ#«Q0ï—ŸöüâºÔ´˜/)1ŞÇÓ§OE¥}]@#Sb-œËhQ&uËw’ªx•Ş®Q7i•OİÉø³·;šÆÑ•­K•ÑÈJQo*›7–£Q*Ö!Ş4Ú<¼.NèŠ¨bŒ&ŒRk˜[iuéZ«…ÕZµêm4c:H…Ñ”[ õ\›‡M…Ôƒ@Íd(aŒQ#9™!CËˆpæCóœÂ&$‹¯½š2ŸÃİ7û¯NÛ»'ûG{­š¢$Pû.ŒQô!Æ0­úÀÂzÍ5to<ıõ?ãhŒ†Àb <¢†!.L¾`‚j†ñxğJ”[há.¶ .±’G/|±4’± }’¾ÿ¾ÎªÁ$€}‡Ü’â‹>cè*·Æ‘pßVÊŸ¯êòÌü\”ÕiW?üBCXĞ°//BÌ½î¤]ƒ,Î€şp})‡Ûˆv®~æ<V¬ÍĞZQóÍ> İ¼“±-›3ÈtX<‰¢ÔÁé/µñ—š%Ì8%5¡~4x°ÿIXÑÕ(4Ä|D# j<›L×Í9%Ûô×ı'#eL«â,®1Ù,“Ùè—hb•¢)kH&>3(®Ü<.G{ß.·]d^?[‘ÑÏºÎ[F­L(ø˜eµ©¹G)²©­Røä¦NAs³M…w9ŠfcorfŸ¸Q˜›ëÚ'MúÕ·ˆ§‹¦#¶f“JVı7ûG§p¦ğ%îçÀ¸$_:jë‘£^,eo6Â#(KXc 9YSv(>c‰–ä"3¼=‘E+ÎûS<{åqª\ŸR˜Ô9Œ¦Æ5g?[†Õ)Ñ]RPÍk-ö
ˆ§±Tí0EP$Ø%ù¬RÇóãÆãj£úØw%²µş ÊÒÓ*°×
¸–Êa™åèÊò7´
Ãí,hßô‹3dÖ¹ØÌ¡Lå/F™;GW+IZ65B1å'ÛÖœ‚E¯e–f6ÃW_ ‹·¹B­‘’Ç@6,eËÉIï>­ó<*ğ9pƒ£t¢¯z+Ãvê*"üÙ®8sÄĞÅú{7/é‹>êÙ–sÄîY§\ùÉ ÄÛîû š>Ò	ÔR8÷e·
Š‹	Lj1™’ª¸LB€`¥pÙŞ
ˆûÍ“/ogX–(šè|µ¹EÍËè{ÜTÕÂĞ´P:ÿÂ0:½Yûæ÷ø÷ØWÓ¯çãA?=ÄÑ´½+ßÅoÔÑRMÌ5î@“/xetf3­xã®6ïı1—‘ßUk|’Õœ‘äÃ™Kz¹çÇ9UXiÅ¢ÄÙ—Ë%3ä2‹©Uøª¹’¥w‰XJnñÜwx½ßØ6Â¹·^„—c2§#õ>é$~e^[8)NHS²²ì.Ûpš¦s[Ş0ˆ7š&šWí¬Ú~k¥Äş:ğkedä2åOÎ•C¶Œ®Wº¼ÈÎÉ²-ºÍ­DÀFªè“’‡UZèy³2‹H‘µ'ÅÂÎÍOÁo¸òà\FûíßÄym¼¥Š¥£§”ôRe½¥['¬÷Œv8	¢öØÛ”ßcIºQPYB9#U}HXoAYÚh†ÔªAš'ˆİñv²¿Ú+*¼]À²”ºãa;ÎeÉŠW*Tc„³@8T–¿”%£î™ëaé‘n¢g1:İĞÓ¿é£ÌL¯ªÏ™eÅEI·Iz?Ë’1u¤[}6åX/{ş~»ó~dh l§Ÿ¢Ò.ìæÂ|î•_k}Úí÷û´˜§c¡üÎâÕX;mE¬zÓµnÈK’¬[†ù$›²\”kÌÔŞfãƒ°ß)Š$É„%×Çù:	b„åpY<j3'‡å¢}+É¯ÿ©€/D˜$d5ĞHR>&uÖ•9{`Lj´ı%=CéJl"GÔ{‹¿×EÉ!Ô,_V|”l[¡×BUƒó“˜@ªÊª$šğ—%mxy]yå8†=Å`³X_r+ù8cu¡¦`Vxe9}`G#Šlº,Sõ]GWKt]¤îql\Ds$)¾‡pï	ü\0ˆ~	äSõ–rÎ|ü…"Lik¥M*ô6iw/çâ·ØF›õ{¬{Š?#rBé+º¸‚¹5±£7´‚ S ¡L(dœ˜CB©Aıô‚j•`ÖPáìÏ±2ÊòRËQ;Æü•2UÚ‰xjAc9@’lY|:Ä½_ÿ3ß[øÇğ®J³}LaM!Ì?²¨8
azÂ• v…àØğO
Úb<ÓHó­Ø%’8 »ÙİèndÌÚÓ®.™[” 9ic˜Vè`7kËV¦-7lÌ–º¢êÚêçúÈ0sFµó²±mlt"]Ù«Êö1oÀÂ‚ĞÑ)Îi~G¢ó+§éäÂĞÛ8ê/õÈ0cDhN"CßÏŠÀşâ¬ÎˆÏlè"W$1!Ê`Û™^/9C€ëLhªJfÒÎÄõš&şPk:£‡U@]¦ íîÌH“=Iğ¿b÷È++/‘½¦ˆ]¥×|ŠT1Ğ	¤Ú×ş©?9¥R†,»{/§ã³~xM‚b´ÁÅQ<_1÷1HMrßÂXteŠSZ†g³tË˜` Èã¦XÄHÚş4Wl‡nÌuÕoÌviåF¨ X£8³‡Û,˜èË;ñşÛs‚È}X¼à“­õ•ß/˜aÊ°i+æ7ƒsV2ËlœÜ <'v·Ü•¥U¨V‰ï|¾6%wÏ
$VÎ»ÉŞ^x´İÅf]p8ÏÛ¿K7pY(¥ƒXJêÍeœ˜S†“go.ĞPavO²¶qªaç8jæzH¼ƒçKœ¶/PÙãâ~Cmï’<}à3ıN/Ğæ`Ss}KD½Ô¢?ö),šJ’ÜğhYÅ	Ü‘Å9Úğ+§¦u¹ì¦`|”Rê‚iù¦* vÌIßL]¡KtF˜Må2Oö_íŸvw_¢–Üáñ^®à¥ öè p<óåZ©9 Ø¿ÀÍ
·u½a)—7õX» Æy$¥ñE;±€h8nû1îÏcD¬#q˜‘ÕVµ’G”C";rûZ+ååf)¤¤sü­"œóˆ‡j†¶”·„Ô«CTèv¬çJ¨_¼q¾¥JõO¢0aïÈ¦îµd~ıØ;ÅŠ]óâú„·$É2ôúìƒhdm.¶n‹!«´c¦ÔË² 9&ƒÕzé_VT’A–j…¡Ø´T ã¹ø´RFëìŠÌN(#ˆ£ ÍmÈÇšİ «ËE˜|›[pœYÃ(ªèĞ[p&îö±èq%™O¤”z‘á ¼†ÁÉ›äNìy
­éşt2N¦¯¤WÚÜî:¾ïİ¹ı“ø«L*ÊáñÿöôñãügüŞÊù«7îñŸïñŸoŠÿ\äï­çDqæé>Õ(Î’ãA|5#oU˜øËmÃ¢¢z]cÖ…ìÕ‹¸Ö‡{s­ƒnß*\[…€1dÙãQÚ;®h¯qAü•P¡ùX=ß¦íY[ZÖös‡×b<™ÂYñêøğ¤İ:9øyŒ‚HÇb`÷ûãö^çGú|…ßt+Äœ…)*Œğ‡£m>Ğg‚Ø3†ºY¥‡hÃ ÿ­Á$Bkw©vC,´BÈZñ5e$VRyP¾ı´õ³h6Eå¡øÉĞn7:„şÀ€WÀ×W¾Gål\+™J5æ¥ò$	ŠÊkQDRa†/Ÿ£r£ÕÚÍká<ª9û?ğ6„5'_ÿ¿±ñt£Ãÿßº÷ÿy¿ÿß1şÿéÛ §3}I Î“Ä:1®ñZìpòu\~¦÷<Bı£5®¼iÁ…8ôôÖ§`Œm«×¢H—'•L}œ˜ûˆ¸Œâdú@Ø±RÃ6G}n²§Å¢¦¬{öµ’‡×ø,B·Ûÿ•^ªıuOß:ä«ŠqÙfÍR{wÿ¯bïXì¾Üo¶x<%Œà
Y=S\aZ…“vç4å¸ô‡½7İ½İÓ]´ê4Ù‘}ò6ˆÃmÃ§=ädF¤ï9å[>ÍşLä÷­ƒWH‹5o†^ºkılOZ§`Ìî’>=ŸŒß‡1áì£(ˆã,â(bâ—€Rzë·€%v“ªû|úP+ÿ‘’aÀá­Šú“êÆ–88íä"e#Xµáf2D:C©th‚"¹„ ~İ>†Ir´×ô¯Fè<AEK0|Ğ2°²5E­Pùæl„:c›f–ƒı—=t‰ò¿E	të‡V&<‡Ü½z9é­š)\øÚ”
˜§_Ò”9´Oh,°hßÒƒŒoOO`Y~è_!»WPL$ƒ×½İ“ÓîñÉ©Ñ8Í';‹Q8­öfAuv9œSœ&5°Ò6ëgqÍ,nÛPòrxošÊ@«Nv[›1Ø$Ú1ö•­ÍÍÍ§|Âf`Jn™Úh¢¹ÚÆ…ÉXp6ãú³3×ÍÚ¢F„h”ûY6îÃ³'İ'[¹¶‘-Ûm3kÆyE »í´Ü{R­Wë¾—1«›KÓIÌÆ3(‚Ã[÷æbÇÍVĞ^œÈ	º¥¶-‰º‘ÕU4};» qúy8	/	æ¢–˜Lî~81ñ])ŒUM?9™¦Vb§ëîïµTª9¾w _>™‚€w•D
1 }mrY¸ú;°[X%­Ü¯éÔ<‰Ç?‡½)š£”t±È# ¨3™½Ğìla
3Ùjq¾/‡­£³îşiëĞJï>õjÁÀHã!1Šªƒñn:†é$IôŒÚªÖ7ğ@´Ãå‹fs•£W=Ã8ß¢üÉ§aö;óÃ:0€š~K{jêš8nÕsâ3 *œ¢wĞ`âÀJ¾iÖ!• )Œç—{"U™˜¾×níP©¼IXõTã0èÂ$Ê@J(e%ËÒ”Š£‹OŠ#F=¥'" \Á²9ñ¸•Ãêã$¶@©Ò½¬ºQ}’núÊ“Ÿ>±Û9kµój­ûY”Ø~
ÏĞ	Œ„ÊûãD¬VWéu­ûHŒ/àç9ü¾@WÅ"Ã=…•Ñûq€I=7n–AÕëQõ2ÃI yDTªÉ¦Ö¦ÁURË6F<ëÎÉ1äÀà£”ÅËÜ yÆ×“T”JİGå•ˆÑT4nHÍM+ aÔ»Ï0Åº£$=’X"&•„TB½ú¬J9W<ÏVØ Æ„ZÙ>îtº»íCÍ¼™GÍ*¡å²š6¾îÓ‡†r~ur&›¨¶}ÜÑ¿ä“ 1a•>1~íÃo^û¢söU`­ÇÃë§//Òn½Şÿ¡‰·‹U¸AMÃôÎÆ-İ6§[ª}íº³ÑŸzëW*l4çT°úıÊ„ß¢ã=)Æ©{7Ï+Ø9§—Ä!],ª:˜¼#œÌhÄ+üfYa ®ó%–rÚ OÜ´5ÿ®š,¦©8àVş’íE/zÒîQúÔ£_¿«6^öz
ßİ»'&0¥vëMëñİn{wç}ßîZl…!–p‚èÚE;`çä`ÿô´µ¦½|jùí‰µóZM|^ç„Ó4=È8-ÑÅ‡z½Ò¯ß»¸š¾ƒÍJÿ|}¸˜]½ ŠÇõÖÈÕ¸Æ~˜&SõLß1Wo{UWƒÙt3ı¢pßK1Ï›ş0ÍıP$³‹k–Ô‰ağ.<¼ÀQ# y0öÀ³QÄBİAøşô/ÄüGÈPû[÷\~h)	öP#4 >YSû*äÓöhS“éó@ú¨A"?à5Äh<ª`}YXÍEî¨@Ø¤üñ'Ï+TŒr«Ïèë°Ë‹]&Ò­ItºSìûİıÓfÍæè™f|)õ—˜Y‡}	›|DÿèÛ,±Ÿ#Îáòz>Í†¥‚§‚yK~J-<I ¹×úüãx’‰â
ÒÌg	§c·•ü'M`×›V1÷Oê(° MûJÃï¿ÿ—ª%ß'n¶ù”UXc®öl¤ÍZQ+EÊâşş‹«3ÅŠê;‹ŸÑ½R/£j/•jŠX#T”s£Ù0¤S«2¸¢Ê¯Ñ{¬ØõÅ­¡'»ù”†Ö0S×&¸Ô¨%Ëç'Á¢ZÚôzh	'x?•ÀÅU¨Y3SPçu:¡Ó1=·×·—Ñ‚iØA'q˜†gÿ°øÌ" m+qÌke;³V²m¹•g,<÷£ª^ßwNÔò±UG¾lµ³‹5	ğÍ–f®%K¼çÂ%y£ZR­«ÊPR(;6:¥}9O±]7wıïÿ%^~Ô†ß8½åx±‘Äû€ü2aø,¡×‰vIñHDò±'J„¶‡Ğ)ÛÑ¬üB!Aô(jÿı?Äş%¦Bï4úhf§Eˆï)X©¹ÜIËMõŒåÕy<¯"w…úxÀ†:ò×iØ—08Bªè½Å7«\¤8N±apU¶ª¬MâOeôø–Ê	QQğ6"”ÎsçìO^ñMšÙîÜÉs‰,ûv]äë‰İÍE]4/ª®I«_ñ¤.Äx.ãÿ·ËNÒèöª¦§Dj\”Ö° ÚJ
ĞõĞEŒzo‘Õ> “½‰í\aîW+x(áÈÖ­WÅ±†ÑTÓé5YŠ•5V¾ ²®júFÛÓ–ƒj6e#óP?(Í®’ìQ&uãÜ4WO«$ƒ,pÀ¹ú,u LX½nqˆ\8?ñåÄ—[Õ-Ë¯Û,åi6µ!ã#iåcÚ•Ì§,åZŒrê9Aú¯—0Âê(œÂâbA±–‘·­šT1ı×Æ½ÕÁ¿Á°ÿdşÎİˆ-’‹‘Ù(^Âºäü¶RïR~dµa]ı‡´‹¸5´5«ÈÁWşw£ÿiÙV|]ıOÔüiäô?áŸ{ıŸ{ıŸùú?·V 2¦úít€X—>‘C×á`<AåN®£x<¢oT1%Õ“¯¢ïÉïjò.÷gôĞ‰¬ÃÆ¼ÈO…qÿšİ~ö<Şj•«W6K—Ğ_&zJ*	êĞâˆ,“GqÛñ²¨/	ƒ©%•°ÏíËæ%&¥’²B¯ÔµØáãN
e?õ<Ò4ƒ¥Åx³¿D“¦+Ñ2×²ı[¡pqÃà*êuCUcˆç¢´!t(‰,WVJu
É<ƒAÒ†ÎpåB”6)Ôj5¤İÊBûAØc
“Šğû‰ş­u ô©éµÌÏö,Vê¦µª´‡Ó»ÛQÛµúÆi¿´‹°Á©ü²™ÑÏÃüQL‡jµ*ì´ÒHYTâk;Æ€P%M¸ÃM‘=Ôë1Ì£ÔXÆ4©’ñUÒ\+£Wc#r(]%‡æ\Ã)-ƒÍY®Ü%Mu¼t¤x‰òö™­ ² $'ÅNm„d§P‘ÀË˜Q7Ó‰ù.ì’æ÷šs\Şp¶*ÈÄLĞ—dÊ\äí-ÕØ.*d»¬0$Œö“í³rÒ4qTQŸk“IïÃ	cÃ!us Jµn€³Û¾ìçËu0•ä2o›qq$ì2D‰T@”ÎÆV÷íxh ¾VdÔ9,Û}³)¦‚OWvØG¨ÜN'!.ĞÂ)áv§*0ı†Z¶ô ¥ŒxÇÍA#-2R š4Bïye*¶•mé¤Ãˆå$£J¦Ö:E×æ—Ktrn­[”ıÂÓE"—!š‹î¼dv½<S¬ÔZ<Oõ{ºí>LşíÚ9bé!‚{€˜y°=,¥ó²¶†-|Æïdjw±ÛC8YÖµñ°ª,P-w©lDåãÃD[:Œ¨)T‘w<…×•6³–¸4‡4ùáŒĞÉFğëÿé]1…c=&Ãå80­ÂÜ/¤N¼–ÚûšìØƒs‘)<x
.…xñ‡†Æ0Â¢P6™J:åÆŠaµÌ—Åi ´÷¦„*'±EŠóQN*†ÕuÎ=æi –‹´NÑtáäalèÇÛTV ‡;.‘nÓCR‘NUdKC·=²øB?åúñK$!0õıDâì“U;†?áÇ»ñàFñ ä¥üBDÓ¥Òş¤m«=”ÅNjYŸí XÜÃÔ	mW
Âv~­ê¶ßº“"=±EÎ<|G÷ï›¨îü†Ì´¨1,Ã[¿NIóä“1èÈ}e…ÍµŠ91Q~l¶´;¸›{jÈ§ããRÀÇSÈÿÕz’©Ê­a›™RH»jêè]ªÄƒ øĞ‘;×š|¾–Zë.ê£õ}ÌãÙ›ßÅÑBÄKí'p:üíoê×Ó´’mm8ü~‹ŒsğM™ˆŸ,O¦x,Sà¦K`œ<Ë¹(7DyK”Ÿdı’qwìÄØá)Œ‘N/˜„Ig£XÉ(2ˆéér6 ›ÿl„÷ßi0"¿Rr0FGa¸yä-üGĞ@_ùü[jBéTl¡ğuÌ6Ãvv€Uğõ[&Õ¤Áˆ!r/1•Ó|ïÆÌ.@²Å€dr@æ`©[Pê%ïé-ÓŞ\o_$1Â+ÔQì§ñ^ITrõT3p®fqìvº` Åd÷RçfZ¸›:·S¹g×w`MÂİ"µåâ² ²˜ÓfzO1´Ì¢“0gôôo­„Ì©È‘=ya‹ÕÉ‘—ELzkqy#ò¿h/t'Xáö4»ñÌËà’9İ™f÷Et‰Å"!#ücÛK+tÁÂ»\~Q¡e•„š6o‰Äá­ıh®>(ÿ	!÷/%p^!HÒu0€6Mé;ñå+OBØ—!§$%•ïà+õªÏŒ‚¤:%ª[øë"¿Ç¢Ší“BNÃ‡öF¬¹üı4vğÀàse1»­0ù¡Ü0	zŞïÿ£?î%µ/ZÇüüË¼ÿÔëOş‹x|ÿşóµÆöÚïiüŸn5îÇÿ+¿©¶õ5Çsc3‹ÿ°µYzÿşûUÆÿÜÇGÎ	j×ãµÅÂ©~cC<>>«ŠİÙ•¨?ó™ÃİÍ'Q¥Òİñ*ô½jçq´{Øòl•Àst:Î(©R–ÎşÑñIg¿ãÙ­¹ˆ=³ÿx~ù’eFç—íŸè'¿ğ³ƒ¿1‡ğ2À)®DÎ4\.¥ÉdAãò³7À¡eÕ·,İªóÊ9³„ùf­ğô¦e+œ´H©+@»½VçU{ŸëYæş¨ª¨Ò¢{|4ˆŞ…b÷äô"ñª”Õ¢|¤½Yœ†e(-cL›ÊÌ©ÎŠ–%(íÇC2Òß³svl¨¤¯—¡—œ½
·ï)±¤¾—!¥+:9´ÈT·¦ÁqÒY@®ùºÃf^I\AU‘Ò.ÉË1ØLf¦-Ğô6óğx«…\Îioë‹Ü<åíAd*oÁX,¯ÈfÏPIùŸşö·e‚Ÿ„jRVˆ—Æö¨®‘¸X7X…ã­…B¥J0uM*»«C¸²Œ&°œÖ¼äÄYÂ3!Ã°áNÎ°
Áè£ ‹z)ùÍ,Ñ5|Wxş½ñ®†ˆß*™úun=ÔÀ½
¶k]!XYmq¦´[+óQÇ °ãí³ê‰áÆcÌP³2N›‰b€º‡IIÈ+ĞÄæ‘H\ì£€2)Pj:Ç"Aÿp£ÕvvúÍqÛËâw¬õ) ;îÖÿííx
WÂZ¼¯{Ş¿ÜÿıÿÿHüŸò{-LªÃşWÄÿÚØÚØz’ãÿîñ¿¾’şŸdÕæy ĞÒ"ñHéXC{ĞÏŸd.Æ³©…ïÅeLIOá`I§ºêy×¤˜üÀ^Ø‡aüH^jû?Ÿ¼ğV'Óx<ºzqÔú¾³ı¼&Aøl ÿ_y>ˆ^¨SôNQD^y^ƒ@GêËpĞNƒ-˜‘Ò#:ã=˜Š9!s}3bŸ½ú³ÊTê™Ö3Ûây8|a!íÁ>›T“·Ïkc5ËxHG®-ı’ºqïaÇİ91Ó¿ÑQÎ§»ql«f ø‘*TR5³Jt¥ú2x#`O:ê)@¬ájŞ&¾áxş¼÷m½¾ş@f~^#
+ú¿Şÿ¡µW0 „Fö,’}Ü¾œô†ïPÉ€
GºH=í%^G€†ê‰š<Wº3Q_™ÂÖóuZ"ÙEQ³W¼ç5˜<<»0»ÚÀ0ˆN8™ÒÏŠfÙ¼^Sé¬}`R)W\Q«ÿñ³]}@)Õ¢	¹eM$‹CUn6Eã™++i‘‘`;3Õ_k'Èæ‚ÒNH€s¹|“{€™§C…Á–Pjœ¦ÀiÑ—œĞl©š4ˆÄ‰¤X-æ´¸ÁÄË@AĞ®Ò·f«#Z<Ş#‡@©¬ `é³ôÎhİÑ[(³F­X7ÛÇ#òZÏ@M”THë£&Îœ„â]QNıvÛ‡×Okr¼o–jsä3'^ÃŒàKÕ«ƒ}qˆş‚®Â$»¿!İ­w¦¿œtLÍ?ÛÚüÓšÑ7ŸHm¢³9Ğ®q¦Ôm~°bÆŞî‚ø#ğÌÜŸ®¹°#t|„íÔ˜	KO…3~g¤6‰l¨-û»	|W³0í²Äİ…‹¸àçRø‰>$Xì-èûïÙHŸb² ´1U±ÃØ®ĞëµÅC«"Î=Ÿüßœÿ‡%{×\ÿòüÿæÓ§ş¿Ñxz/ÿı*şat‘LvÌÿ›,èZ}…!øù<ùÿ[÷
%^&£ÈÔÿğ¡ç=|ˆbdøÂ­XÉ?ŸÄ¡ş!ÿlñÌ1³*£F…ğ	ğğ¡</®(ƒÆ]Iò6µO³ÜMïÓ?¥1R—FÍ­íÖùDšS‹\æÑò`7#³qêĞÏ÷ÆT*(ÁºK@ùj¾[™á2dİöˆÉ¿»”gàÄÕü¸êƒÆ.qÅ#'„%1ÿ>C%9I–¯!;øfšaûÜ‚23eôÂ­y‘ÔHeóE8¦¦Â)Ø•äšÃœf_Hš2J”_(Ëë3ßïßt·î' ³kJ4otÌ !	ëÓ(ù,&@ùCÊÚMÑ¯v°z7˜·‘ŞúAØDéşA"ùÅôSª‹2cJ‚;~pO¹Ó¨ˆ²‹Hh=Yõd~îÂş«÷lÅ7&òÍ:äK‡|êXôÖÁ5â¶JïP©l‘¸\Ü_l$ÿ?B"î7gRA!ï^ğÿ§YıÇˆ¾çÿ¿ŠüÿxJ«†Nåÿ9crT”ˆ’’|\Ä/+	mJ/¾!wÃ0äõx9ÆïQ¤Ci‘,¶-(
Äôã$lúû¾R#Ì	
…ì+ÖˆÓĞ6
ë(AÉ6ìÏñ6/xİ¼ØÕZ§¥^K·œŠ–†Ô.ã¸ûB™q­İÚİ;lÁ´÷_¨mƒô.÷¼¼ 5ÿñåeÔ‹ ˆ©â½%”•—wÓ
sur[gÔ”	ˆ2,Rb‘QMH9ÿË şóÖ¹g£
az²´ÿ™Ø5İe«Q®$áæá(B.J„î¿«<«ÀÿµÙ‡U$ŠOX´Ø!ÃÍeËFÑªÄ¿ÿ—øûXÅ‘èI¶Yô8DqøúÄ€‡AOĞã8èAMÈÊ.“ä#ú6OT:$ˆîÄ$"zE4—¢(ÚÆÜûÓÕÄ:Ò“ñ \’	‰¸ôx“ĞšOLö¸Vôƒ‰Á7mS7P(¡½6&Qü§#eŒøü££%zznÔõª1¤½zB…ä¥¸à¸O P$b¢è™úÀ’ §…œ’Xµ(5·P¯â^?àşïşïşïşïşïşïşïşïşïşïŸğïÿ}ù’ h 