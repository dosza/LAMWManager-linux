#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3576771465"
MD5="9f47444f717d424833e605c0138664b5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23572"
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
	echo Date of packaging: Fri Aug 20 03:58:24 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[Ó] ¼}•À1Dd]‡Á›PætİDöaqÿµ¦—€
ÿˆ T»LZnBŞğY•å Ù‡{Î'ëÎø@ùFã¬&GŞhp¡#Á+‰ÂÎÿ—Ælû{–¯áNÍêÊ:*‘é€4¬‘¤¿Â5²„ŞQãc>·¶T!‚oólı¥Ïìà¤¢À¯è‚‹ÿ>?S#îC,»i–k-^Ï´¹n–…JA°ˆLa±{Eµ§vñÃ¸PŸN¿@ñ4>µÖÔûÜàd‚ÆÁmù¾“(.D¾ho¼¯ş+k`—;S÷¯bIŠ…Ím÷EnílİÎ 1¥ôü9şæ}ş;û)—ÙÒGxaÖO^nãÅİH){‡›´9B ùvƒ6Ş§ àªñˆå˜ ĞE)Ë5DÚ_Şowìú¡!±öı_Ô9ˆüÜU[2LúÖÏ>Ø_4êşNAaïc?a©]K¤×ëú[Ş¨Ce´¦x@ô÷hbÊU9¾/vBiWâ|\3¼±r’°”ã	ìxŒ“¥\ğ6ó$ıó¢œJ)ºşä3C?_N“ZªCX8ú •³Š¦Iº¥Çc‚ssñ™:Mi
ªMN®İ/Éç¸Ô8I³¶øO¹,–(áä›ÍÓ”£o¹ëñKµäbt¡üAˆêCfIˆgP¶»úÔœ"i¸ĞM$&*ä²¦bâ 3£Zg“OİŠK c¥ó>ë4²´¸,¸Å=Xx1€G©'D«fê;5€Y½NŞú1Œßåİ§8™ÍNîå*Í4{wã%[¼õîÃÛ‘!K•ÑTˆpP °£Ñ#&F³ ˜7ö7É~¢&3î`B†#rÑæ?âaÀÇ!ä§“";$—™|¸¬wÍ¿Ä‚D„Ê±˜Rå‡y¿3?`2*ìÒ£2†>'áR’PÌuYuTãŠFÑÂ¾ÔyÈİúU¸ƒöó/Ø(W7…©ÜXVZ=g`v~
{{âY+Q£¯úß,o3°)ƒ™Å`u‚íìÿIv®5Ïû3;NÓÙ­7~¡¸ïœGc“JqÌg°¬ı°¸¦Ğ+eï&i¦?ˆ£~:`>ÈŒ¢ií~%†šAEMçS(øÊ ‹én†\Ç`sRş¹5¥Ø©Zÿ„%ƒÈKÃ6‹]+2¸e‡i0/
OO÷uÈ¶qó(«gãÎzy»´UN´Æ]{ßğÈ¾ÅĞeºÆnnXÒ'¸¢¹†æï0ªÃô7g¬Ç8¥Càß‰+¶ÖµÁl¬¬ ¿àf6%2 5ˆÛœ@ˆ$ëüŞ<îÉg²­6Îü!¯iGëç­öKJâ¬TÒjÏÃ™´1.ßNƒ‡ôNi¼â‰'n•U;JMRÍV_bãŠŠ¶ƒĞÎ"N+x×X}-P¥y‚NXß”¨Ëƒn%¯(s€8à>s®€2¶µ±1{xD¹î“-­ê©X(Á]*¨­ÚHGÜ±É€k£XI¥Ùô!î˜­IÍaºâÂı#æ„‰gÎÑÎp-E™2?ôë*^0øôÊvA+ìr?Åƒø`µ»§*¶ŒW`¼>¶PWÊa³ïyNX‘­Ïã`í˜^>hw©.#•FGÛÃ p´´0‚›TCÅ‡hWB‘R^ìÀ_wnÅ¡åƒUgà”Xó=ÉZ™ŠÂJÎ€øÿÍÔ(£r¤4åï¿Å0¨,EĞôÌähàeu;‡hÉ­‰÷n˜Ù¹şà·¶†YØF›mñ‰ïœ>±‚¬„Ò£ëb­HÓ®£ùn]Ö)jº?z9š¹ºaTã¢aIG¨ùWK
‹Ò‚ä<òë¨VèP¸?mnw³Æ²uéªëşC;@	BZ;•2?ûÆ¬XÂìë¨c6²İfÕÂç!Šº”ÆE)RÌÒĞ2B!hîğcE†‰ä4­üÜ‚7±Q•+›Y½ÍE¨›Ï ‰	ğó\3\Lñ£jıM!ê³+)Sœa]ËJÒ
IhíîÍ'„¾›¶Æ’-Ş´İ÷²Jc•í”µ¬sMn¦İs«·wö©v®ëÏn„cCÎ±ãÑ²-ÃÅBni¹Hëò| @.¹V()½%Ûª¡-†F"zœ™Es,j]¥ÁLáÚªÉp=Œ÷[PêBr¢öw‡örWÁ{,Ü®ÙĞ—h¯Î¼é‚Ïof¶oÒógñ›ò`¹@I¼6^~&ªØ¤ÙOÀ°ğ¥¢ÚôÉ4ĞÅæ+9˜jO¢fêv&ûÅrSõ|Ûd 0Ë›“q†X&;Œ}lö®As>ÄôôQÊ‹4óş>èèFş¾óšßıoFë™²YÔI˜ëÕ¿Bø¶¦¬ºF*p¢/Î¢/X;ÒáÔÈ‰¸eñˆ¼•–°ïcî³7/ÌéÌ‰™?Kå§ÊKAø‘¹aA5Xq Üö[Kàğ şªO¶läé¸{)1»®Ê‘"õ„™¬õ5šæ$×„avâ‘ÿ,#Öş”²™NÃäíôî?ŒA{PwA‘¯2²Å`Å€§[T¼–É¢²·‰şŸ„)¢ÊS›Ít¹ÿîUÕ¿;¡ehãÏqt1ºüó>5’pD¤Ğf†ÖIe£°0{Yc ı—’©÷·œGÌS×)/¦N0©…N$rYƒF¼ÏŞú~°µR¾»ı1áµééŞ3¹?«x±@§ˆYp]WÄA7ºUw\¾£p±ÿSZòg54ÂL‡ú=Ùaş·9Óy^ŒQÏùÕOŞkÈÄCf]ø]éù¾iËÅ|‘=¹pÉà!«ë†é›øÎ”‰t–Aõ
<ß¯°ræÃ¸?Íã¿Ìº1ZD €vfvM¨Pÿ6ZíOôÅŠŞJãJu¥2˜AÈ¬ÃrIù¼­“øYõ;­Ş¯®÷+,ÅóóÜ}©N«™À+ïİÄ "_Bk$™R­ÅKóŸ#²÷¼°ó$€Ã’_ôG—*Ç@²]:÷ÖS†šN'îbrˆ™°Í¸ÒëÚI)!‚´G±`EOŸöºÿX€L[]ÍÑ[º9¯–*\
ƒ ög“å	ºÓjü½ˆÉGÕ÷ª¾d°¹ƒëPƒğ|Ò:•é]©ßÌwˆßÄ„Şv3,ú~‰à…wj
Û&y!˜´àÌ¶ÂİFUP~/ÉhÇ¢Ë…‡ØãRdãAŠLešÍ†‹ºBºü³ÆÇ 3¶h‘D‹éç
dFP)íéÏ}.(¦ÔO¿y¥åOH"Xpä%ÍMKDİ‡›.'#ÒLÿØQôq9vt?AÙ9ˆ²'"l…0—©Ò¼™äÒİğµUüİ¿ÇLù%Öív7¬
\Ø@{ê8)á±%¿xçò’u7Zd@óÖº2Q7ø×8wîKvÖqvÕÒuö¢Ğ!ó³6éku›
}ôiü7}.añT|[9?tö<nÿndJÖ÷íÈ;ÛıÌÍ9½˜Èµ~NJ,š¡¾‚L]Óİàª@Ì¾9`¿g›ËA8™¢úd[80Gkš÷8“"å÷Ê^>A<¿g¤Ê¤Ü‡$*ù¹¤+åÕMt>½~62ÀcS&¸ÉÊèŠ0¸óß›¤xYjë¶²LÛ%Şá-‚lÓÆ€·L7W¹¨¯Ç0«°Z«I‘²Z§ü"ÿ—qİµoX‹lG]Å¶¼o,8Šz¹ÆVgÆbëÆHğ¬ü¥IU·aõJx¼ñ»â•J=nŞ…;§)á·*>#uÍKÅh`Émòj]·`Ğ¢9‘œé'v× JhóššDW;Ö~±>»€@!¡·#·#]ß@ïÕN—8&N—ğ¦š}0ÌqÜ;µ¾@ÙAA³×!¥"Š63¹©õ{E¤kaÈ=Ê×¡ÀIg(4?å´¯C2.îı(äY[}­3r,·=XB9ˆÃ@&¶ñ­7ù(v÷‚ïÚĞ%ş´®ÖÆ‚/‰ç>–`é“»¥ù6„›HmÅÃì,¼ëFC Å‰aãRØùĞ²:m7€™é€‹MC_½{Æ]_UÚ?œd!}ÃI}¡ôLñ€z ®BKqæŞdØÂ¹2©t‚°-£Úı€6cTU%v.gÂ[„Lz=ü”Ååõ~êÄ<m(2Ç1.ş¢å§î3ÎHJ¬¡Rh×œx ¾X¯…PÆ¥×IĞ„‚;(&©“:•ià4RÒXJ|L^â¿!;TG8
¸iõTOûzKfî•¸F6X¦e–DùIX€	“½lÁZÄ^áã×û‰®É¾Wá€ÕÃMÁèÔüZì=õ¥¦—í¥9gìZ4NÁ:†IÌ—~d×€˜Ëy˜¤»~y‚õÑğGôÉ4Äöv§8ÒgVhñW ?¯ãØÃOÚÈD 6¨Ñ|9¹y“Ğå’96Úk“^rj™r<Ól„ßÉ•‚Ûß4(chËùs¼ @k+¯xD ¯™óš#gzÃf	‚™u¿]U4gã€½SK\ş–_ÔbÚ7»à?ähëÁs”ãF!<Ñœ)ÍÏ	g&+Íû—17¸¡èªÉ±÷˜–‹:c\j¥ûõ;§Úÿı×{Öy¥,ğ
´»
ógÊóšH<õT"¶˜òg2ùZEÆ˜ä™øµÓğf`àXWæş¸Smÿp¡ ÒÀ[ş.5ú[ŒåŸğşÎSÖ‰²¯•®ãMíß1æ‡JÌ~M(Ã ,ˆ}P3¼\¾›²„è‘ú±4e^¼.N¡ÈÛÜ6!JŠ‡GZÈ/JÅ4Ò£-äRDh.øåÄEZSÎé£5F¨½æ^V»³ƒvQ«¦SömEÁyK ª	ãAh€ÃvMÒî(5qO€'@Áå|!SëfòŸÅàb·Ø¦³óÔçC¨1J4vŒ!4bE3šü4•8Óø}°Òkü~5]Æœ<€›)ØŸq¬ùú§pñ{¥²ìËhÙºkğ™ÛÏgÉª¸jçoUoškÆÈ¤Ç\qJ ^Ñy—Ü«ÖN#§a+×ıÓÍœô@’ŒÙâ ñ©q›Wl¯7VÎ·d7=¥ u ØĞö5K>1L˜uÿæ][™KÚ‹bÃêGëË	È›Gëé²¶şÃğGòqæ!»Ÿ.C‰»)JV¨Z~¤y)ü à)I<kP˜š¡YMzpÄ¤¼ñZ49ÖdÛºğíh+Ø8CØRw¹3ZÀØô­åz¥™õa%iõ'™îŠëu$ş¬PK£<îøyÅÎ‡a>²‚_öOfÉÓ“JOb?ˆ¼¥­!Ü¥ºÛ[†ÙÄ( (diø)KBôtºÄ8ê>~Éç1øIt»û¬õ¡ôf¼µ„,±©rép‹òÉssˆ”y²kŸİ¥Wo5ğÙiò4|9ÖêûiUòÇi@w´²çÁ¨Qækå¹-ø\áª·xµ5glôÊÍıˆ¥L³j[’ñY
”WÉ•EÓÏİù‡HğnÕ¤B	¨qœcĞ\MB¯Eş…ËésÅ”¾@)[io]şÙ…°ÿÀ¼[œg\@^Î×¯GüL)TŸàŞI>@ÁPß”Ùq­Úş¬Ôb¾C½ 0mœƒ¯6 [ÿëØÉ\(M)µŒ5cŠ	µŸ
…é»
‚˜$7æ¬Aå	ßö¸ ¦råâ} µ%ó_NŞQ¨sb}?7æ!µF¿N¯.åÍÀÒb˜3zT¥Ó‚rÅÓRÒ4gŸÆ»‡•õ8u­1€¡HeÑ,Ïó-ôqY 9qğ5äWÛZ!Vë“«!Ğx•K«F¼ß¥+ rQ˜ÒËêŠ_9lÖ:ãÓ¨d,ÔkºÀ­ŸøKœôlV7ĞR¥ê{yÜºQFq´Íß‚}§Ã¦vV!€ Cxá”3nLÇ¥¼ì>öEÎl×tr«|º’õV©(Ğ˜Ì€³æN§ÃÄ—ÿéS•œùÄÎšÜû?¢à&¼èíjL˜"úÒäZ	Õ1;]´g­"=HÙÈŠ/İXnf—ac„(Iÿ—Tñ¡|1¶@ò–xWpçÍÆâ¾º©@2ºO†»{\Y7S’ì}Qmş'Ææ!=ğôĞ¸¾sZ NgD©•ú7cOÔÛÕ5®¡ÿ¾Ÿ/vJSZÜ®flg¨±÷«Õsh†õYÓyÎb=Ğ¿Ié‹;	y= ÉªÃ(y^ó-lû5Kl–5IúeÙ(ëlÆ˜~Ì90ìñ‚Â3‚Æ÷ŒÁ!¸Ry…êÑş®ƒ”‹üd³²Aé&ØR¢?®/ƒòÔEÆnØUÔ ß°e€iß\¤8ìC+Ç`ôıQ%d)bE†¬ğÏ‚92uQñ¡~TµëQb5ªŒ˜Şş©²{õªza1,²„fr·^ŞRÓÍ-„Okö££kÒ7C§s!‘›gŸúç“ëĞîë÷eæBs 4ÑKàÖÂnpµ×_¬ ¤|ÌàZ)AQ·q<Ä~ÇŠ›@pÎ˜áŒâK’£oˆÒÒ’À_?7Fª*ji¥1i7Ù_«p›ñRñht ÂëÔ£Ø;ª‘RwÍ9˜¯f
^IÄóKE÷íĞX¢ ×¼u¤ñüEléÁ³"^"“ÜÉTòZAJ„‡ñèoŒÚHıÆ¤5¶±Å¨}[¦¾ˆqšßáÓÃV EÑ:»FPYod8³,+Æ´Õş$ÑVF`|ø¨O°A6W>8Äƒ©}WfªĞ¦•HŒFT®Œ£/h/—u®4¬ıò"M„F?0E«ùÎÌº2Z£ÊCÔ:iJL‘zehµñ¬$şôlxG3×Ÿ`’H«TW@…Ëã>‰È’9÷Y0'¨äOà„2Röí°èú½nóÊÍß:§u©cqóF/^ãu¥*(ÈC°3B
ç~9f¶9O­«â£
UÌµ¨‹ŠŸ×œÏä|Çi~€Ù©“ E"Xry9ÄëDémÕ‘nuøÙºªÖœñ&#ÔÖ‘Mñdsí¨Å[I©Ïa5\ˆörô+z{éoõÈ‹ÏD)÷ÁŸ8 ²ª„uKE­ÏA8:Ù‰‚ÅË¹†à`wåš¦<	ïƒ”WPRÂwÁêŸ¼µû.è=«ó­¿W)dŒÒä;£½ãf 8M=äA<”,!¬oQŸztmÏè%3tµ	»ËòûÙPR= 8ÉVĞkÓ*İ®eE¥ô—r«\Ä-¦Ï=Ê>IMÀÉ‘„W3^ëªÔdSÉnó[sïvw0B$ÇÂüSœÑÂ¸rØÃEĞ˜–=÷‘)ıIË‡`©6ÙÆÄV•Ù$–Ç.•šÒât)×oUA—íğâ³D¸šKrõ¼J¤*90'o‚ˆ1YŸÄâ…š7ÂŸñ1±Cõ/9¢ö{Ûığ>=£m˜Ô9âE÷~µİS§gÑ—™+_u‡C›ù+ e</µö–*Zføúä2ÔâöJ½‚qŠ¦EÑ
oš¢Å«úê-İ•¼ö±„ø.í#­c—÷_
oT³hã,œÙ n#Ô‹:x#ü.–È]Ê#UÉ;äŞ¬°A/ÖîNüÙÇr+§„_àYmºÚ,ÚŞ”Yõ\%	FíUÎó>¹4%³ĞhÄv{¨Ú¯„Fnœİ+²ÓWæpGÜ:öŒ•HqGcÍ½¦H>˜f5ZÍ¢AàÎ¸ûÄù7“a1¼\6Uø„'£q©fXĞGo˜áÇ÷*3Ê‡ãtg(æ Ò&ä™¯”aZˆ)Az?Ã'0­\Lràl8êÙ†ó—9Gn¤î\—.z­„=ÚzşX)ı{°;¾ì“KüIã®N'!-ošùÕ…®ßŞöFşã¶¡^–—Î)çßÌªù£,yFÒ§X°Ä“‘•$Ív&÷«
¨¾$¢(MËëØS±pQ
çÓîŞÉ¥!ñµq„6ÈÙªÏ5ö¬ë}İE
<x)CŞo"N¤›µÿ£M[ÉùhGÍˆZa±Ã
yap Ä€}‰q'‹UÍ€XjÆÅÑaÜ "I—`T×”)è¨f\Ãóöén,ØOeğAbücá–Y¯ç¨:êj6£Ê‡â¾ÿ”W¦H|ÓH£ûè0½Gå¨Z¹YÀ€¢‰‰äŒl¸‰p"Š˜)32•3/Q'y^r1õ’—1,[˜
³XÈmcFöáh!·^‡îÃ´.:á¢~H!b´.,ÊZsÆÂ<ˆxd›»Œ'ç°ùiHÇ¸BDTu§ƒ¸4wú„§"–>3‹‘YâıMSQ2ªºÇÓhç³ù"Ê­<‘œm,ğš>.©cõzš.u\çç¸¤NõÀ@ÛwßÒÇ/pDE…*–@ædpçŞ¶‹›ü	àïİäVŠq38‡ahB’ƒ·û©FB•@«â”8–îS†şÎ [Gü˜3&Ff0kˆí‚l‡«lH×oô¨Áãİ-‰÷³·ûN€P\"ã•şu‰·ÒïŒ²3«‘€Ãı}®o¢ó=›Ô%DÒ'Ê’0,ÿç»T×G	³><lcìuY((Ä`ìÑƒ¯CìO%–àk{KX¥<É)èÜkìÏdmU©FşÎŸÂ#s.Å¡¼&šPéw	2°ÄßbOğ<Š¯`@°PCÓ"°›cÙä
Xıùª¦Ï#¥h‘'…%„Éz·Ä pcş7õy‹ç„çş¨x	Z
ÕXœ&ÿœ¿ß±Á?ÀIî±­TÛR…˜¥£2Œ{éÅ8×FÔ'“M.Ÿ7]#¶˜
 Ç(÷÷OèIªR¨bÎ•ç¾Fo‡+§’œğsŸ%ep|ó\~a‡•CëQXÎœ/¼ß‚ï7¹&ÛÅ¯ÎQ4ıŞˆáiñf«×³aèšT÷ß°e"²b.Ø8Q9íÄ ¢–ÚTdn¸|º|·ºû‰È«FúÔÏºágQeg™Jh—ËªÒ,ØÇp·¯©ş÷~‘Ğ‰>¶ãD’1pİg‰¼ƒjÃ<Sê€îŸµ½*µ®9ş›+ÉP`¹”ı#§•Ùbº®ç'\•vØãqÌ×˜÷­¨ivÃc•¬ãâúÊ„3ßˆòÂ<;‡']wO¾d­û­“¦u(ƒëp©’PN iôoä¤)€Ò´ä€Øb^§)40Ë¤K›HË€F\÷£z*MI-É”¢š67şTsîv‹û=5´mŠÊ!iù¬ûöp<¨É´§îQ¹i%A>”ï†—ºIëyÁL$GÔÅá©1¿D¡³ÃÔFáriÓG[Z
ĞôÛ èòÇuöwLB©ÚLQå øOºÌ¯àËúE×ğ„ŸOÏOßkYWöùi$¡Ò.¿ã©÷Šºã€\@'*‡·'†PN¯ˆº”X3„DÂ~fõ²'5ma)Ö+ĞÃıBğsŒ©Úòü*Ï–—]ó»ş{¾,Y cå™3ÛÆĞëßÎÊ®˜d¦€Û˜0iÅzHLp¼?õèpk“z~ÃàÎí%Šf™+)•Ïb
O mÔ9±¢ÿZ«Ëü-ŒX1ÙW+ìX<¸èÜöòKÌR²Ôz4²pˆp%A½¬Võ”6.ûÇ>úäî»xúX¥s¸qTß‘Ó·‰ª^L-s)	Òr[LQXÌ…^*­¥› $ä»¤¿ƒ›?0à×óC€£2›ŞßiÄ_a·JtÅO²ÏŸ2çlà‚ÒÎŸÉÆÙ˜T¡4¤`.~U´$1ÊëÀµ4mYÌÜ*qğÿ@ïeÌ!nj ƒeØeÕ°¼«Æ"1ÊPD{9CÿXç±›ÃåÕ6ÅM6ßÊÓÔ‰¿U­î½†æ5‚â‰ßõ]$?G2.ô?†óÑ“«.‘°l™J‘Ÿ24+ÃšÂ¤{Î{ş¿„-2t„	“á0Ní³©wJ~A¢ÌŒ£l‹›/s¨E+²AŞ€zÆ­%"ÂĞ…ÖXçûP ›»q”9²ç^Ì¨»Ò'&R¢ü€Ïå36˜0¯„:œ‰~öÚ–H¤Çğ¸Ù‹fÑÇö¶yëŒ,ßÀ~5½Üq9¯“+\âŞÛPĞUwpæŒî$µqítN–ÊÆSèı‰,Ó,p¿k–[%.°)uŸÀ¼y¿`X©(¨PŞÙ=Î*\Ÿù€²>keÔó®›m—+DÕ+ÑğôIŠtúvŒ†ùg‘„·½oC—ğ0ŠB—¿}Ë;1Õ÷ºÙÆ%1½¥eà]5™µñÖÌÔòx|lØõ{%3©Ğ8JøæMù:(9ñIÿ[ª’nàúvmq»İÊH¤St'·Ğ7qÅÄ©ÉeÔã9MãkŠ^×[Œc(œg€n‹@öMíª}Øpu_c2¦ïT¥şˆaC\­Èè, @)¥ëd.K¦F©O[…t7ùX“ËRz70İ”· ‰KI0©,ğBy ³Ëæ¾æ›/g=[Š(¹Şx!KLˆ¾¥hkîÁ¶—/¬§OÃ?;J	xbd<$…ò.öKÙ<Œ ÅÔßeÔYi=n§ŒLáh$®S@ / ïQìªÖOGM<“n1›l¨ğì¶ôzº`…	éöÆ>(ø¦¢¦²tò°BöT×¡H8ØYH†-P±´‡øgLLo„Â­áĞ¼y&’)öƒ~Qı’4} |vz˜µ`³cßyÔ©ıBAú—4”´>èŞB¹.n	Ÿz~­IÃÙŸrÌ’l:SQÓêúë«Š—‚ ½Ò†HÅ;gšj$­©Sÿï…¢¢~>Ü¡^s¡±Nä`=Ü÷T†ù™Õ°QßÁåÀÿçBé¦†9-ÎóÁ\èúÅ!Ñjæ”P'µDş2PÜ}½z óc†Ø¡YãtØ&ÿ	ö:›¯]™C<N—u5½Õº¹Ùqi!ß Y»ÌŒ•UÃI9*Å¶ó•À.R>N‹…ĞÍ0áÔ¥gå™Y¨}€6†¿:Ÿñì*KÁ¥Êv×v—Ñ€} ”}Ùå–Y+TŒ¾{†>’¹äzĞä»¯U<‹üls!ÙD2—êb³«§ùÎÏ
ÿÿ¸ï‡~%¢š«b#ã°Ä…´uX'ì wÍV¶»T…²~g­=z2eêu¨e§wÖZ¯ XÖ‡óÑµÈ	êÎè#YZ+OÕ…ë5×¹Û«'—:Xmr “Hªn—İVõ¢—…e–°ø‚Öp2r–5"¥ıæıï"hb0(r¬±ˆŸ\Í-‰vş
`qüŸüDõsXƒ+®å™·ÄÛ§cU~n'n:]üuñQm¸ç9ÿ/£)yüª&±¼)Üq±cQî’Ï¡%X]öHµhuœ£ğ4î~e`—×]Añ¡#¼Z(€Fş.%Ú—‰oAt£6BâÔM(Xœv‡Ü’øŞ
şšêÌµàô‘šQÁºSû+QÓ³äc{—¸?‹Àlí¯`Ğ¨‚ˆ:8´’¡¨Û¨­%ÇmÈIé_¦+Ú5ıùx4}ëvCâ÷n›>õ§™±2»Û²IÑmóußIàD´áRü>QMLYI’³âŠO8©»ìÁ`Ï0¨=f«ÿWpJÇ¬Ky<•İh;Ìqéí„´D¯tƒ*şbº!uø0=i€ÚÌ5È°˜à“¬'„¨XJŸìm6Ê{–Ràá·[>Ô­ø¦–wyjäïrOp¹q]á@z±Q Ç§rn@›.h<64à>AØí
dKİSC§çñµLöG‰ ğ¼öe±d!ĞşÈu”š£>¿ğ*ôşˆ‘¶²Ü¤ø$
ÂÑró/.añÈÕwÄ›¼¬š;ˆ]É>¡ÃÆÓñïvw™Ãk£š9år»ó¶Qòé±}Å.eÆ‰ĞM#ş*¥mâç2K~Ê˜:„,’”„€˜áy i$¼T…•™·ÖV=(à„Õ•¢W_Ö rÆª^ğ£šjY„ª-ØÕ»­O•ŠAJoo@$·ÌÛ1óĞ8 =*$Gw6òT!Œ™ÔózO)¹êªõµ¢ÿ±¨^&™€…ç8ZYÕ¥ˆÂLßY,ÛŞØT¤åÊ]X:¿µ$©Dº¾Á(™ Ö0¹e°ƒ¨òÊyx9¿byº_*1¯YBÃÓâ`çüÆk¹ÿÑ÷Ş9¡3¡»{Í€4 º
 œ±»%ò	ÊÍàÉby“1mRúõJ@¡‰­aÇ×Ïúİ mmÈo‘YÌ[C)°~§Px)ç¨ã—¦0`TC²uÄæP$E5óƒW!"Ò˜YG8éÇ ! ˆ-¦ø{mHÉ¨8—…e´›ñ!ÍF¾5õ€<¢¬B“ÉÉöÎv÷éQßñÉÿuq&šÛ4EäÎty„Š-µ=µ„recpnjo–É¥Ô©ç+’âmÕ…AjŞâ®0¹¸öïºF¹áçÎZ]Dø`oÔ½›oº®9¶ŸS­O:ÿOkxmüª†£Ğâe1i!â¯_t7¯„¼Pš§Ê–íV¶T®Š± š0°]·à„i­Ş]p
ÌÇ½Øğõ-#{Üú 9¨p‰	_Ìğa®C	h	sXsÅÑû™ºmD¢ˆ5GÅop&0Ê{Âñ|ßU«ã©Š¥!•Ä'ˆ(ÁäšÑßñDœ­ráe°Îšc0¥w‡àˆÑ‹ÚhÛFxDBšíË‚iD¬JÉ_¦Ğ6æJroÕ_]Ãlßƒ
-0îğµ^¿—K(†÷ü»~ORúfT#r¾Ûã}º³ØÑ™uB” ¶ÚÂ¸ƒ¶<ËL	=Ğ.axcsÒÂÚEf°`•ä½a^ô;A’u’¨l&ºdMG_•Wè$\Yvîúiéj„®µÕû%w º£ÉxÈµß'x5¢ªKYÀ|poº’„f…òüµË“/b„™t€Îÿ›v‘¥{ŸĞÏ‰¦P€îD¥¿Ö	ÚKÉK “ÂĞ#ºê*v5ğ–ïCŸ£Û9+áLf†¸ˆ%äGyŒÈ+û¤&Îƒ5>€ó|?®È.=5Áâ-8–ZØYDÿŠ1iE·è^J›M5q
#}¸ŞKí$Å&[•–,åßã1¿–4îîÙl½˜†xóyÎjDqÄš'´RÂbÚù|O„6L¨;¦w¦¿ª:ÿGÖÎö‰ó¸4"U˜­xs¤‰ùEy£*œÚ- inˆ´T$pAF»‰ö†/g¡™üyŒH(–ÆöNy …Ki†R”«@'5¦QKt›]Ö¬¨ÿ¤¿¡šƒhl\¦4¡èUE?®W´_ÄK©?Gı7ü3ñDŠçÓø•"6‰üh·ú  D\³¬xŠˆÓ”¦î›{–İs»ÑéáÇ¦ÒHmd‘z&>:–îğI&g³f/£™Yƒ¼û PÏ—à"Æx~ê!RLkÂU1–ú	éÑ‚CªIàÜÃâÃÏ.¡Öu}ÎGïÈÃafîhô÷Ã¿¬ÇˆJ½;Á²Æ»ÀŸ@åAÙÓ¾äİUÉ†óK%Œóœe—Œ¨‚¿ÎR¿)E ­—)ÊŠ¯h!xŠ‘Ùø³>¸Ø9OÃÁO"zÈ‘M~Á½I»!
ÊºÁìrRŠv}$·›yæÁyCeao›xCèâ@òß¼PÓ&m6dC½ğauéòÅÇSß™§ÀzòŸ†ôß‚“ØN¾dì’İvÈıµ›n “t§˜ş4Ö¿‘L[¶ÅÖşAPc?˜DÀUD¿øi•.jiçœ—~÷Prõd·‘~qåYvØ –;J5‚ş'¼hTãÙíìRÁØŸÃÀK¼Y.”æş¤ÚfÂ4¶•Ç8e#b¾ŸÉf²Zåˆ¨S³QÎgÚ‚·æùÕÍšYïÔßG}­—ÃE%¿^¶ZTp”kº}¤ÛÙò»Ì¦7³o|6v7=LBş×XÒ\ÿzßB=ıùúÏ8ût“ï5ó›JSPo}?}âş¯@¹îPòd€eŞƒd€
k±r87%€ûôÓw§à¸Ä-½aãÔ¢U”±X­“ë¯­bˆ)
)q DOuŞûkw†ğÇ‡,r	ÂBQD,†ë ùhR¹ùX›‚©€õ>nMôó½0Ú›ï¥Ú?®ájˆ—¨Šìkî-vÌY?]ôS`J1AøæÑÚÏ‡Tà#öm°£?Èãıh‹›PÎV©ÉR¿îUú. úJö¤,”¼á½ÆîIÑí·«7m€ĞOÄ5äk÷“‚¬óZx~~;ìçkÔ¢\Q7fdIŸÓŞ†».¸åû‹ó™7X^,°VÖíÎûz²N.ç.‚¦2 İOTûICß)Â†ã_bhÅßâ½‚¨ \Štm 'b¹Cèë«AìşqªtÎÔs9*öHÚ¡‡¨x·ºÀb²w7g¤ÓnÇæ÷ËòËúí.ÚÊ
ÇX¿h9Måeù^%Ÿ™E™*¾®İè¥-IŞKtö ¶œù[¸i—£L£4­Ûi¬‚ØĞöœ~ƒAe—ƒ=©¡ÿ¹g•Ó‘®ËÛÃtòŠ;`9píœH“ dø‹MçÉh­æL\IåH!ó0æŞí)…ŸxÇ¯L	<1Ö±X»5MåKVµ¤áÏkşı¹¯jtıù5ˆünúQØç‹<‡. ÆwbÔë×¸cU³zê¢šÒa/ªP’Í9Ö^ ‚ïÉ÷«iğW98Z”È?âc
À£¬ÄÌm§ÏÍp÷¿j§=¨¡Ç#(ÎS„ÆO'«:£ ¤w•ê„«âÿMïlqaLÏ¼B¬|ÆÁÛ¸RrYB	ğAÌükK38p<¿ÕıMƒŠE^¸PÑ4ãı.æ¥˜Yù[1=Ú¯\T–hÈ8†bgHˆbı9—Œ  ˆ…n¼TúL?0áhÉ­N¹@a»p#Pf½5*¥U¨Õ¾ÓÉåÄäßÿ£(YLÜÜÎcïpvĞ‡€Ÿ(6C<ƒš’™OHÿóoÊ´£ÙFº\ÀHQ
k€€İbcçb8$²€cÂéÑ”‡éLx(¡‡CÙêÀUOÚöNÛ^´ç²G¹~Ó)U¸şG QlÄÃ¦Í[	ãPW–¿¢X8®×éãAûÑIëõsÂ9¯Ln‘”µ2ËÖQşû/Ìç,}â•–:¢Ÿ3sòşb©­÷X)€vây¿ò©£ÌuXõ|v;>&ËC|Ñºl–G&…&Ğ%„¨"›:µñ.<§Tü€µ£pï¢á’jr!ì˜„€æª¬ù9šú\Iû'q&ş]ÿüXğDpqy›YßÆ-/g¢¦P—Ìlˆ°„Aîf;)†8ŞL8¿ˆ¿~©ìmò(5œ˜‘¢+Ÿ©p`+5ÎjË¤8Å(P<C[ù>ë˜dmw3şÇJjZ§¢g_3œ®Óßö€ªñI‡ŸIIÂTäg²"RQ+U´¤ïË(r3œ3Ò;´¹¨b;¿äUˆò®ş¤brŸÀ>ùYŠ QŠá,lI–¥'|±„6S;=½ç·‘ítT.&ìíëº]¡y¥k>¦n!%åhõó6·—ìuq~cG€eßh^Ë5!{ïÍ««¸¨p„–©•–	¿OĞ—Hüş" Ò³únd]tÚE+í
Ò¶È<I“P5Ä;ø0¸è‘Ç•/:QÉ¿G²š°,ÊqêKÓğÍŠG	á‰™¨·$zÙ4ÁP³@ÆT û'trG,%/ô…ú)ÆwùTAåÔA/ÀîGÕg›X[¥Y>võg;ÿğİú•fœª×êµÜQê¦„‰Õôûe²ˆí„äo’'‹?ÓDø!„³RÕaßÚ¯s]8JÌ´¤ĞSîŞ2rò^k¨aÚŞĞİ™~ı‰i\ª^U.şv“ƒ!=wÜ±-æ¥¨Â¸ ‰,	<Iís`¡pl/H¡,bıİ›?:OĞQso£‹dyº‰u×fÔ3ÒÌGU×PôÆŞg]rÆ1®ñªCÚbåëoüRŠÀ;lG"æ#NY¹&ö2W4tídâ«·4óVeeé7ÿİĞnuÄdáYlU‹í·×¯ D	]’ÂrÇé‹¯©Ù )ôâpòX²ƒ`SL_Ì?Q0ªxş‹ıT€l9vó²…õÎİ(–tÁ9FU,\˜~æ8SOh	ò«jMNXg…/¶Wøø¹2Û°õm[êÊ“çš\û'N´-Æá™º	J&{…<h­‰Nªv)YRË¶£–@P“ûÆ}²¨fÅ†Ö€¡iŞ03V¾€”"«ZŠ®µİÂ]Xé>ÖæN§6¹1¤dmøñ‹WalxÆë“-FH™VØÖ€²5£ÖXÔ¶Q?—~ÿë ²ãQ7BXPõâe®mªågÕT¢ÆÌšÚï5‘~It¹=4SpĞ#{%V;(ÏÄé2¬Á°O8GsÍŸ—,ƒ »–1éË10m!'(Jq¡7xÈĞa>m6IÉÀ¶)Î©zñ“çÿiBÍ¤ßÂå&^vO…HA£>&¥}uP¾?É*=•w*QÉ3–ìZ¡­tçş2ığ[ÿè•N\’I¸ï.fYËzÔÑD…íS¾¨ÅjMåÔö‹>˜ïŸÅrÈşÃé)Õ±úH/÷¸ÂÀl2eÿJßôV¥m}öÌÃŸm~[dÛ×
y¦i×}'û8ªòU!êËî‡¥‘aÎàÑÄXÌEìİó%Ôÿ)í£+A>cÔk¸™ÉZÃçÖáö,Ô>±’Yğ{s¡ËKÄrŒÌİpëıı®ãÜ¦ıÄ£Ÿ§£<àMQoõÖÕL|Q9xş_˜@”n=aÜ3[ï¸)¶‘ƒl$Dj^õ\ï# «ü“Y‡Åv~‹ ½÷İh«íw¤Ó®g®ê»ì@C4ì¤›îk¬ƒ½-Êö½awD½ä1g£Å³,äÌ´õ!ï7ßİÚK"06ŞÂÑGöô°ÖnçÏĞ-ñÇÌ«2*OTVvñãâ9Mª.,$»YD/e	.µ¢û¢@Æ'=•¤: (CxäĞÎrÔ¦´ƒÊTPSÍ¸rom_ø¡é4L)æÍœ£Xä­y“2˜A)Áoò§û*Ù®H¦ò„÷</«Ÿş¦
éÁb–ï¢H-!–œÏk)F=fÌ¥~ÁS¸‚q
	ûhûòò8ad¿›¡*}“é{'øå´¨+(O›P(‰·ïXF"‡j@DĞûÚõNÙP¶ÚLÀIyé*éª-µ>ü&³a ò·ü†ã ™¨óiƒVã0l`«²CƒR,ÄŒÅ…FÃˆ¬+Qc/¬Šeìs´²#.~j±¬
ıv‚º.°+t“¡¨÷[Êbd…gOÇDä‡zh{”Y‰Ô¼¢?ïd4ôf¶úù ’´µ wãUïIwE:7ÕZšx‡ŞÚ Gvo¥@éGe®şO!œOE¶"‹-Ë`ßzg½g^Æ~JhÁMlàW%cI])Åû?‰`÷¶d8:æ/-·E\ÇÍ{_ŸI…K6÷áÉDfÍ‰rqsvÅ×K¯VÊ: G¤„ ìYóuŒ6]±	Ò÷ş’×Ğ$À¯i>É«ã–îåìR¬­ûJ¹å5:&ğë²v#æ$_ŒÍ)šïbhkáå³v©vøé³ŠN…†öÖOMhå<Ú]ù*ìËñš-Q¸òñ*çÀ–&èÍñT™gp™é&µĞ#ë•‡²¸NòğD’oüæ¯R4R+§a Ş!ãõtZvhpŸíÄv@–&rÇ`K?˜híöc¼4`g·Ã÷àGm¨:ÙÎ7şy“Ár«İ&Õ$ıÅFjr¢UëÇØ„5š¯¥QM­5Ÿ`ÁÃF>d3“6Æ¶C…D”’ß5KÏ´L†çëÔ¯÷Ÿy@H'îûğÖI:RÅ¡ôä7gÛoİª¯ :2ï¥ï		áGÒ²œ7¹Vÿâ ¡Ïÿ¹ùØlã£
 `œ*{ä …ş»¼cã›W…nq/[‡rvéÖnå»-`J´5KğãGºgÖ*Ó"q¡N‘ònº„<Ph?³ŒüÆóÿëãÜÏO¸M³`¦3ê©;şÒàY =çdş³x6¥!k)~éÔ¥é¯Ö·À¼aÓà½Ï¢|ÆåªhB'4|—páL¸S3(kOG!ç—P'àj:!ösßeÆàrxÖË.,AF4íG}Ù
´¦:ˆ4{i?v®‚Apå[ŞÌ×§×Pœ^2(ÒºKë·Mi—©d¨şWµ9ûaèi[ÓsŠ‰¥`¡ÀEŒ÷ƒ÷C±cmÚ¨"	ÜP­Üaİ-È (f.f^SÉc$=yDñ´¯]Ì½G8qsŒ®\%y.œºÊÈ¸¦Ñ‘Í‹=bNeBñ@´çA‹³Îj=Æ:8½Q,ËØ1áÏ,ë˜u5sñ»]œÎıDÓqM?3(ÖÜ€/ú–”.(“èé´è†^4¼2a¡S¸'¹0(¸œ.¨ 0Z©Cİ^İeÍÅÔŠ‚{ãô+ ×húR9Şõï]Î(ü€‹l:~6 Á^a²ÔÒ»sœ$±”M÷-¼İØ§ºÃÙ\9ç±•ÄÄ
&,>×axs<ÎSJ5¹jŠñËuïìDÂ!:›Ÿè>‰3ÚÅÁ¼$n;eƒi¨lûŠ;Uç§zèĞLÎÌÈ&( }&2jZ2€ÑeAs»ZO9÷"1õÅP.âÎ­<
±râ.²iûÉ&ÀÌ7a'2Iz£	oD©–Î®”ÊŒ:`ªP#­EGg”ò\P]¡S:îÂhøc›càÖáV\ÅéKDwùFæŒs-tZ¨=ÜˆÚSâr\Ä¯š¨×sYôj[`ÍI‹d¹;qÉš^3fÀZ }g§×æñËF¨Sz€*º„àÄÇæwG˜ì¨Æ©$î¨«ã‚¼MÉa,%îd×È Š:*‡öMWN:C #-!Ñ4R¯!”/‚s¡Ÿ¾e€S*©UÆíâŒrŠw{U¡“îóôë{–›YÍbn)i&9ÛpÖ/$Š*8—Ù8\ÃÆj¼² Ê"1fª£°ƒÉêú)V¹ˆF¼ÿhjû`-•q)6—k×¯ÍuNVTøºÑÿ3pgÏ¿m’ı#sf/,›UõÊÛò×®Ê7F?4ñƒñ4bÙÁ’·óe#ëÉuÌ%éF¿*óŠ`%¿Pù‰®–‚?ŒWÊµi8|<3ºwxS <×Îü¸ §1Œ)œö6eêÏõ)`O‘ä-˜m^ãÖŞë¬¦¾ç8qnÃb3>çÚÓef$!1Èƒ$½ÌÕzzüš.@Èz‹rÂ†PÅÁ/ÊA°,Ab{õ¢ÉiŞmğÏğ&ŸU([Ğ½¿³"Ö¶Òd¨fØ’G~ºœ‘YL"÷èç·áŠ
mç›ñ"·³ü!¿Lş‰áY€N¬iñ#³Ê\$5–âD¾ü£J„«ÇóÔÏm“Rs7OéÓBş%Ä~µbD¾ÑÆ³(_è9¯7×…£ì.Ètèîî³ĞÊ}ìôHÂıq±*>AıÛ–É8µÂ"h-«^A…Âî¢€6F¼s=él«»ô áªE.çŸ{UZ?1b?wòüAør¡\¡l¿"(1® ]?İ†áÑ=î]4i>±…É”ÃFŞ
"MHdV²hãmGáÕ±òËVøû¢ÜBŠNs"Ö¡Æ·™GÊ0”géßö®PÏ-³b$Å¥,ğŒGš$œiÅC¤ÏM“îWˆæ¡)ÉÔn]Û*'N‘ oæÈ*ø¨W³EÙç×ØŒ·Á:å6¾•Z·*(¿ƒßŸƒ·n_û:M¥§VŠ'B¯ûù»½ÜP/‚N0„ÊtÁÙ•Ë¹B©”ã—g…¸;mÜ³€áˆlØ%™=|ÖÃï#ë¸Ÿ95Î¡cÊ:pZ’âùƒ¶œÑYŠ¢ÕaÔİ¾z!$Ğ^ªgóÇnâ`Ê¸7§¨¨‡
üïH¹ğ”JÇgØÕIó—Aı8•MİÍlÃÔË¹é¨ÀTWÃÊ$fÜ¥PYEHRt”Åû,ïüoÌ˜‡[a$…»ş× ––ÚÇ]!ÑuÑşñÃ¥·†Ğv
°¡vúÀ†ÔO‡^ªG¢MÀYÀt½º2¹œRé÷—È|Á’báˆt*ËÖqˆ¢¯ˆ¢Ş·åˆµU¸F4şĞ§2€¤$~Ÿf<Ø,ï!Õ†¡à’kè6öÃŠëöLvCâ>şÙù7–,Xlì¤á£’ùÑ³Ô_nAùGtÆ>BóäÎ}˜u¸?F
¼×¹[bTS#3ämğÀó2úCÅÀ*ÔU¡>õ[|XOz'&A)è¿kŠl¥ëíæ|?ı¯ú|	‚ã`½ª@ôÓğËØ‡±+´ô--2YÚBCˆ>q	e_nñòF\Eó¯Ê™&R9.³°ÑÄ·Ê?nmÄ×c*²/ª“ÎË÷ˆµ‰—©Lï<‹7Ühs>X˜l¾|bş»p {;¨L¢¦uë¤9*`wÚù¾¤Ã‚A‰ÿn•õ}şsÇë)¾&™v¾üÌÛÇAÎâ6k~<Ä´ã+ >S_#‘f÷ºô.j…lÓ£Ô÷aúG¾:¸aa¹HÖ‹Æwã‘Ù<ep([àRÇå¢	m2£™ä¸Ogé{*oCêx	¡Æi©Dş#EFÂ~lOE¿O~Å*]|ÅÃı8IQ¦ 7ã„@Âò(3ÁÜŞÎœÒF–­ŠùÙ$…	›¥*@¾ØH‰œ„¨Çk($6Q+(ßmì	sæAMò¶Ø‰Åth<[ÕK)CdRu_¤¾ÒZ¸%%c²xëH´!	UÜ¿Êğº‹d½æ4¯#ŞıÑESÔ'ƒÅÛOLš3#\Í˜Tê¿‰¢û9g¦ø›f†şy¹[Ù£¡ëÏk>gĞŒß!S\3#93şV·†ã^+ªÖ­²Ù¯¶şñ•‹áÁ>bÍÿó¢Ëc~µ¤(²A…ŞŞi‚ßqİæ¯Õr²QMÆ¢øŒd=Sk@ğ!×m	ñš4ø7M°«Ó`¬W]’Ø.o½Vêzmá,ñA›ßíQ˜cVL‘M:C¼rˆ±Œ”^ø©ÿÜu+°7»6l``¹æÆüD>T<IzËÙR=®3Ù,(Š¨w€‘Ä¿9º9w8Ğ°*†ÎHØŞ‹fÅãµşHÁ:ª'WlÆ5Ì’‚ì‚ü^^bûáoIãÌ³Û±µ%’Ó€©ép)¥â¢nÜQƒÓ¨¦ØJÖàô°f|³²Î=Üš³o¡GÁŒ~`" Æ›Öq³€ƒ*àÉN%Î˜.y!Ùµrø¹ñ¨<´òş¹\,ÁaÌ¢šã¡”îôBNÊ‹ån ~¯w¹m!ÈÈ‡¹â	3Ì³ô¬uÑ³Ì}…r‚«óì$ÿE3ğ¢L½ˆÜì¤õ–Ê¡nŠàç0ˆ\gÚ-oaËÇmã‡p^ÍÜÉï@Á.9iH [mÿÇ&å’Æ3õbã¼Á`½İŒ¨ãiğ'ÁUaHÿVS>[Ô±= €.‰·³<Ç=Á¦m9®óõQ]tÅáè8áÈá)ˆLè•&6¬d(d$Q6Ix²øEBZû9âÕZÉLëÂõ8n&As„M9o¤f–Iè(Ñ,œRøªGëÃjÜî¨,Ué0çB·¾·„ó³å=„…XÀõ‘o,ùõü7w‡õ¹ğYÃGWÿÚÜ( ñ|8ØV¸bŸóÿ¾1Kÿ9¹^0WvCŒ½Ìf7 RO-/Š9íÏEåf^òá¸ ˜ål‹MÕ-ß»õÙ”9¿µ€˜Ò`´N¤áËN±'ÿ„÷î5Áë‡Ø‡ª0M€z×.İöœ¹4ê=w¯äÁŠÑRÃôÙÊ$fÃw[3@’ ³x~~}6î‰~F)É×;Æä¶,µßİ~ÉøC t¡eIİÅ€:ºu¶°x‚GÃèdøÒÔºxEââ}{_zŒC”x^.¿hwš%wûq®¡«§Ò‹“dòïÑÅxb¶ğsëÕ¹dwPÄx+8:Ça³ª[jÎnÏË@÷‘n-LÆDŠ×o

ıÔf¢-ËB4ıR‹²±³fÀA1ˆ^ó<û3)©LØÌ)x”/"—Î=LV^oK¤¨-ƒ•´n"ÃdØ(•Òµ›‚ŸmöT|@Å$7ZÀÖ:»ÿocC¥=£ ?éï=«.Úúƒ)ÂˆšRV €ªöÉaB­¾ôÀ¡nÒÇ‡¾§ËEO¹l™ÌS ŒˆÒkFxÁx`ö}!ì¿^Ş2ïxGÕ¹…é£~õü™Ã—²Nu™pÛ®LP¤ûg¢=FSb5y™õ¯qZrk=zöéŞ²‹qI±µ¤Ş¾Û“£u›ë¬J äc–m#yĞ—JõMQ‚óìSL%ï[ğB…$c÷/¶-wİåäOÔún ,[Ûÿã¡_¿©şê åg·D%á‚T%…ÔïÙ«<Ã_·ééM@"+½ßà[kñî·r¸p2ß-ê/ÿä+–M—ün3ôaÂì6±hœl92–òO\\¾Ÿƒ¾°]¯¥ÄIVÖÎ¼Q… Óhc¯¨ì'²>e~A]DéÛ›°±´Xy#	ÿAPL¾a•E$Õ¹Lş"Õ]¦ëEäZTÙ"Ò-İÊòU´|X7¯Ñ…œâ”Mpİ¡Çşò)’2êC ½zAÓ•bN° €¤UU‚‡yg¨à+1®äŸãã#ÃÛH¾ŞŒrµÔæ“Rƒ­1;L'@ËeŸÁÑùZGŸ¤VnKüLÜ‰Ú389\öğI’ÔêÃV½ùÛ“ïVN°„ñY	Õ¥vsüó‡µˆåãeAE–öôKÂ±Â+–w¶}F×nŒ:şç£ şEß#°ög´#½¸Ãè†?#DzOX¹
Ë„ª­Y_oíJ`qŒï­$B•îQxB8à~AD<ô™Tø.šÍş–¶<x2¥Aû‰ñp5¼@1tG,hM ‰PlüáÖ˜1‚£<¤Ÿd¸àıÚnUI’w²ĞXğ½Îì²=<ö5ÄÁBÅ#™KNMäÖKú½›+D0LS›‚Ò0šÃk²v1zMïfÓßPæ/:İ·èÀ‚wŒ"_Ëq‚‰Ù¡``Ùÿìõ*ç¼”uJ­ôE¦^üxfC™âkÔ¸Ï4ld>w.Ò¤Ò5äsÿû´	¼sš½dB0éÁ]0§/ŸòÙŠRë9*ii5q!«¥‰|¹]'i3: –gH°†=SDò o’¾‡z[Ğò¡ì³Ú}™¸ &ñşk‰²lè÷ş‡û}Ÿ,ÿ%krÆ¬]aVnÑ«C•kÆkôÄ€d¸¥½¿<ìº¶Ğ£rÎ€Ùßä^è]PXRôõFllÛ£H*°tß†ãNˆ
‘²–%ÒÀ£t‘E»À“%tHH•ŒDd+fª”-×;¸à\ÚåwiK´dIj4Ğ·òİ¿Q–ÃgåÒ6Ç›ªÛ]¤Bæy! QïsM1òh.ó4DM ÿ+“b»cuÑ{oS[£J”9{ö9«a÷NW=Pú>¸Ê¤½EİLi•ÄüK	%Ö+q÷Vh:7}‚ÕÍKàzáƒ
Ä.*ı(ÜÅ?,ŒóG°®ÿÎmˆ¶^T¥ËwZ¦’­Fs·àÛy*èI„[Ï²ñ¤«—§[ÿü“r›Béİ9;r›k%Fgüİ³, T‡‘Rl”º2NW/³s€´WaÆUŒÀÍ¸Yc'$"¯“;”‡©Â	a³Ö·Oéemš|Š—¤Ó›öìÁ'X“öœ›k•ë«w–ÂÓD²ÃŞ9òvˆO]ˆIú#…AÑ/,ªíR‡ÅbµqªÇùËëØµJ2–ml ÌšK Ç®ß5»B›Œ.ï—ÉÇ‰Àa,±SçéĞ“¶³7'_l¸Tõÿ×š¶B–êU^­@NœXÁàIµ>L¼ÎvòK}SOÍ¸;Î<#©$µ£zìÖ´‡tè!Iß®2ê@ÌÊw‰ŸXÍ¨	”¡Âá£ªĞ)a¿;­ÿ¡,à@h`‡ÑBëB…<’"€”ÜÒE‡R”¬L] šúXjì#Ø§á‹…£Û¾¨=k4ßôâş^*ÿm‡òS|,öIidy,tÉEÄTÂÓZÙjÅŠœ¬5ædÃïÅ’ñ
Í~l^Åì)ÇS•m©‰©_e	|…GÓ¼y1o”¾³ÖOà©NlŠ#ú`ƒØ!ìx6¯g'Å_n± ¯ÿ¢‚Ï#Òº™è}È4‰Àe%šOß£Û«*ªÄûüŞÑÖ¦nüúíÎcCÿd“Ô»¨Å*;£âúlµÀ¾ùÛHº©`SçöZîTzåÉÊ®¥§TsÜ7uÎœWéNö1ş}…¦µpE½ÙˆœoÒ{á:X,9BêÉZâªØ\Iİ.¼Å[—6ÛDgG5{h>²6sòû`úĞ’ª+² >bŞ73=ÜEQWâÑäQÌ¬)®µò¦f‡½³¸:†m³ElŞHì¸aá±Å“I˜¡¥x½ïYr‚ï×OXƒµÙc3z¹ÿÙı£lõy‡=“.	Î,óm”y,ZÎ´éqş4uè
òœA!ÚUÙ¿PÔ& Ú'Œsur¶{ë“0èÌmj±—Ò!™{A˜áÓ ½¹qåİï4èg bŠwAÿoàÊIa³ÖO˜ÇÛöPˆ$TËÌ³ ,e”¡YV·Å¨I€Bå8¢àÎòˆKl˜ÔGhàAÆ~¥Ÿ²‚ }mu!ïªIízÎ…Ü;¢NpŠÁ®æšà³GVÙd“qšxÇİls6Ëí8‰|É›(KşG4¾qô?ĞpÉT»qŸøbF‚a¥Ç *Pì!a™GBÍªEÑÌ+:Ş\¸TíŠØÒ|ğ"¥¶pá²v7vû²m˜Î±'FQ1Àï=|×J1Sß¹½¥D@“ã'{7œQRU3šŞmóÀ»ÎJã¼H¥(;ª°kÊTÓ0©ü’¢½ŸŒÃÖI)|wL4D~Rÿ¾L»…ì-=ÄYEcEue:¸;î/¦uÇ)?C®^¹:B•ÅÀ-ƒ’ÅöÙD!ôq—°o¥íÚå_òÀã	¹ °¦-¶a¤úx³wßµÛÍN­+mnqZ0"½¥j(³Á‰èøÿTU·@pô1/ñF©ÉqäyÆOVÅF¥hÎ{	[³\…ÛOYz{•:ô¤¹E}³4jì*Ø±1-Êˆšáf¢Œå,Æ{Å‡Ù3…öÃGGŞõ¸¡¼_GolµÎïûYĞ%—ÉfÏn“¾[mW,š1 c¼M35z(Š~}|‰”ç–yÄ«Ïú9¨]2tfêqåÓscJûñp… 5-Llš5¢…§ŠbÁ}z°\í+“¬7§‡íÁ!$îÍEĞƒ‘>Û(-´Ö_3bû>¨!ÓüiêR÷‹=&Šv&lI°«ìâ‰nK(j‚8*Îù7t$ „…»ôùúFfYHIÑrO˜B‡hë÷Tò)½Ò¦&W…%!—nzÂI‡Ì8ö´Zd€¦ÍÂ1Ö&/úLÈ`8ëßî¾¬Ç8§g°¼«‹•wèŸ¼…,3~V–=„åâ	õVš£ÊÀh3>Mm­ó¹‹~Êe„lMIf’ıpìÚG	qCîM±Iï©³Ë¼‰
¤¤»H—©óO*ûCaç7©±ÁãL»(áG I\<\™òğı³jzt{m«:myC¿ƒ#âåz±©ï´Qâ|€‚:%@±'ëŠ‡£7'¶†Ë¾k$¶Y	®ÒYOŒ½îó&îé•7–dí9×@É-ËşC—b[ó¥BoàIßªÄkÆz Ü„± ƒ¥«ıcLûEÚ6ø²1yË=f¢Ğ(ŞKÕ\¤Ş*ûfêÍ+Ó#·G£Å~æşíúúÓ¯È2†X“í0NõßãèVÖñ(Ş¥›¯”Ÿ§ÄÍP:)ïD¡Ó¼ıf÷A;ØZ©>ê'–2Ø^h˜äõ–ñ5Ë€ƒ äİú¡.KIŸ7:F#™p™ÛßZDö°C1*BnãÎeÚ4òëz(åÉÔ~YH~ø“©W®¶Ü¤¡&6(ØbÒ©© ômh·7Õ"ŒHšÑ¦ì¿ró´ëìhnGv YO-Hğ‰!BÕ“è·ßx¥±œéÅÊş[ş­v°Û»Õ×ÄoÄÁùW­øæçßÙíh}	tVtoÿĞ¯T7¦6\Ø'ÿYa|4ïU)†Xù«yQËùêÍh¼+€)dŸ²íèÇ‚Öã«‹q|Ô}¿ÄaĞH±.Îi¼d@xqáÛ &²ÂXşHÃË…£=C»èjOßy‚é0âõ›™’ÃE»[)İğ{¾²Åg—ôûD¡r6SÍşˆ0!VÙq]+'‡vWzîèÚ^véÄÅÂ”üOt¥>h’lb
İô%É7‘'O‘L¨÷æ°Äj–a$äUò1Æû¡Á¥a8$dPá}Òù[?ìşXèv›gUÙsA¯(ô‰%ÂÏ­úö ê´û+tÃîPV|Ky?q9œ($¨´o_Aæ8›¥;e:"ÆÎQÄm4ŸüïÄ,v%üÃ®­]a+›R÷œ1O»”7c0"(Ë"§äŒİ»d;¸CäûØ¯wízE´8‰-bö(ÔÈ1Ë© 2áu˜¼÷Ğ—•ô5™µGÜ7„5? bW²óí F;\mh»3„kìÚg?Ûoâd—~¬†œe”ÖÖóIı˜OoK´Aháâ£d7u•æ»CW¦fø9vE~©Â-W.UÕŒ`x¬½ç-’°E9f€ÍPà:ê(Ynë…{/¾b„iGğäÔîZ`Õ×ÄÈ­ÏıâRVÈ±l ±‚v^ŸÃ) ¿©ò£pµK-MN.‹‡{xqüz—õ1.G·¿»“	Á`m|—ü¹”uÑw6gª6nÄ’Ãˆ¦ı?òı<tè®˜;¯ô‹V½:î¾JÖ5Ú–+@ş'|³£w}—u<®ü»Uÿ%GTj~/ÑgÀ™!ÁÖ€æÊ9, zVV]Q!àÁg³Gª‘óU£¬iWÕŞ‡2¢şGqÀn_û%®z#A8µ?/B'/\éóª7M¤ãŠòğ„+ú$Œ3†û²ı¢ÁÖ†Ë«ˆäa7×Ÿœ§ãÌš†ˆÄnŒå/¤p}Uæóa¶&*˜Y£öLœn2ÀHËPvF;û²â5$ì—‚N—~óÛ?[¨,àİV~È[EÑj¸é|‘ş/Æ¿},.`w+Ô:12.Ì¥ƒĞO:’?p_¿·‹Å7%cDèó	{Í‡üP—äÑ=°«4„ÍÅ¬’XÙ]j½¸Ixí™¶Ó”aı²-s`|ğ…Æ.V„Ï*Ù 7¤Š"åÓù\1¡µV>nÛ®¹äJì^rØŒùrö±:×N§AiÄÅ¾—S3ÿÌÑİJéY9E§-<9R™r]!>7^Á¬b8ÙõDÈY¾BÅü/è››…T™ )Ş¿1¤y–Ä´*q}[6(‡¡„”Ûºüñ9rµÿ¥ƒ	¹ó!šüÀ¹=`AnM¤I‚Xm1füÍ–äÚ¶•ô÷PµœïY—¦¶•sj-[Ä÷ !Xû”İt—¨ŸDH	|sN0©¾˜ß)$Ó]Ÿ ì£8Zƒ]Ë,êˆÙvHWir@?„Ï„İºÁè<©ÆUQA±?¦xœFÏqw‚+¶õ|µ›€åIÓº‡21vm7Ê%™›ÉÙ
¬[4„·¬ÀÕëz„ò`Ñ®‘ãt¾Pÿ=²§¿½X­TxípçÿZ ³ÄpJY†›ınÉéÖO MJ,Í°~TæÁXjx`’wc‹<ubÇ=ÖBG¢Ú™P^U+H†? #ñò>ZªÑŞ(=«c	şŸÿI\µÖÔµvñ)&÷Êıqr•^&wJåÍéNZ¹´…|€ıG‹­]ìjj¶µÖø^×{ §ñB{Ãg¹@½Mÿ«îá‡ºÎµ!‘ÓADq[5]—±Şé‘î®MÔÌ<D8 ¬¹Œx×cƒ£3€>ôDááišÃü™]Øiş¬wó^‡æC‰Û?6¸QÇO¿¤ÄÁØÑVê^é¸Ålv¦?«’úoò¦·À•§—Í}/ŒHé?±•¡çkd2KÊ3“÷ë¨R¦±ÌÍÄPS1 ƒ1ß7$%êIßÇZu‡,ıêŸXsš\IYí3-VÀ”Ã>‹
 WjÇŞøâ$¹>PçR¯ÂÃFQàvŒşI‰²ÄìœléÂ“|¶ ÅK‰s$Ü\—¯¬ô®ïT×9#–ÆöÒ[î%M/EûøRìÍA‹ÜNƒH8Ñ.r˜y=æ’æW~!Qy¼Á^¶a3òÿÄàpñŠz9ú5ó•›L¸oÎµVqQ?CâM*äë-0=SÈò•ò¹
{‘yœáaÇK»$…I‚Ñ´wz²ÒlşôUùƒ-ÌôK[Âä5Jµ‚Oœ†J¡OËñD©!*À /õÓ`YæVÎé;2—šn8Ë®èœAÆ”˜¹ÀmŒeÇÓ¦øl*Œ°Wó£f½\Ã1ÉĞ–Ÿ_'î_Q~ë~Í^l'Êõ×d4«ü-b+¯„.½/-¥J7&’"¿F‡æ-DÇ¶{ÎJVŒ]Ì(ÜãD?L©ÑRëåK­Ø*@jÑõ`¸Xcs¦oH?J`ÿwÓ¦'ÔV3*ÁåÆ^0¨1ŠmdÕıAU
ÿ&ƒ$}=RTò³ôÔOT/ÉY8¸„’UïZ¸D¡ƒêmt_»JÉW|áN‹Á'›hÜT}µ–Ë¿™ÚnL¡’·2S8‡#RFÔ¾CÜó‡±1â[6(Ğî%ÍŒQUÌõW÷9¹õªûbt±…ÕXİµĞ©í,P<D§>¾ÅÒ8h‡‘¢’Øü#8Ù»¹™ûS›ær‘P
ByÛş\¬ïeº¢@>®ï»2³tQ´¯e™Á%÷Š{=­@¨U‚kOvƒİò™E†Ú¶r|(­[7ÛFíÇz\jhc™70†Áè”§›*-dÏD–¹írm€Õ`Óò	àX!1V»ƒîUX‡¨75ÄüiR¶\y?OŠ+¼\?¢­¨ÌUJxÏk^öÇq_J@v»®Şo\Úú?æÑ¦ş*æ*oÜ~X`v€ßå^™&A— ÓÊÉºxs‘¶ª­sèxCúåEAÄºzSt³ãcĞ„n¦|g‡©‘Ê+1Z"6E-šs-]ñtDĞÄ¬×${‡(o[¥šÈ“ y·º=,Õ2­YÄ‚†¨°\ }µgŸ¦F¡?à×Qª s4±ïG¢‘ç¬X"jåRºÆ•ZP·Ã$ºhå“¥
"ñ Öë¸'Ùv7ÕfÇìS‚o^‘óq?²ªqx5b“#‘‚‡öôãX}D4_¾ÉÈ.ê@QÀIIYBO8§tZÜ·¬A…¨ó‚TÑ4q	Nü¡iZšv¼Ëın¹ıÙşwÁmĞ\¢m#òÊØ³õê©oïÇ%ŞN!¶séxcK½¾ÁŸ”îtĞ0DK>‰éú³Œ-(÷$L’—¿Àƒò”4lGW˜¾ğÊ–ƒè•K\y>`ëÈAb`¶<_ø¶õ¬9'ÿåà_ÁÚÙ‰ã×,8f‚›nã&ôÿ"	ñ‰lJ”¹¡8”XÚüµAo
&=	o:pW÷ğÔ?âiŠ}õ{4iRH	CqY¤y.4°Ù¤°ÒÉàWÏÂ«UÈlŞ}JvËù[	[¬ÛšŸZ»AØ8t¥RCjİß8,‹—7‚¶cfÉ>½ÖæËì’Ë:1¦ğkÒ‡<‚,¨GÍuóO§ğ`MYóç—ù›åçæ]¾»ÜNh%/ª/ñ­Ä€Ìe4m—4ôQ «¼i{¸Á%Ä`ŸÄ/”*‡fîõ©Œy”.ur¢712 ¬'%Õ„Ã=M³oI š7ßÚ‹I²v[ö“îÓ¬9V£ÒNJÓ‡³q!ñœº¨®)DáTé¦Ü§oAJïı«ÕßÅ/‚É(É×ª%ÌxOIÙsÇ²ì2r•¡K]ÜÇÉ|Ö÷ÂA1ó)ó”äAƒ®‰2-ç5ŠÍF×‘2À0€›®“d1É×ÛW#lB ÊËÀ°$R‚/NeP¢~?,Ğ•(Ø¨h&b’k<ÿêë€àƒ©A?ñ\tÜuróTS³³/uêñm<2KÆ2¾m#ô»mÏk„SÕI´ÔÃMİ@ÊØiİ&Õ/pÍœ¾¿ãŞ
$ûÀã&æ¸`?ƒ<âóØìöÒ	$n;ºÄeØH$Â'${8âò²ËUTÆQÏ™ş±¹ëaJº!ë¬l€’vyö¦roaÚ`¿Tàj»——;Ğ¨ø8¬–`¶CÎÊ‹dªÌìöÁEâ[“hÿåõ„¬IUôŠèo÷ñ3ü¯¢.†¡ŠJXîÁe¥¨°ºššöß*ç_•Æ\y]¥(ìø¤ k¹)F¨ÌÌ& +Øé¡ÚKŠ^d>ı]Áàêª  S‰‘<
Wz ï·€À†—·Š±Ägû    YZ