#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2815885634"
MD5="85fb4f932c2fb4aab5b7a6deffcb8a2e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20056"
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
	echo Date of packaging: Fri Dec  6 17:18:55 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿN] ¼}•ÀJFœÄÿ.»á_jg\`€ñiÈ!vo^¢ù:£@Iƒ& àI"%ÅS¯¯ˆ­òÌşç$—ıYıA1ìF¹\.Ü’À¶svÒîÖ5ºa: ?W¨À-Å·zXœ‚nríµ»nNâiäã¥çILÊäû×;Ñ}¡X9óÔ›– dëıqI©ÊÃ¦›Ób„-å§§0İÙsëFt*˜¬ú¾í«\:ş½ÀÎş)©oÃ"§:vW_î"Í¾]Ğ=­öå2ÙÕJííëm^?şÚ‘ì'ŠÊçM§ÑÓ©^z{xrHO~ÜÍÄ&Z™Ş¼/è™ŒRxˆËXÙ´WmŒ2y##wÎªèĞ|G;à[^­Ws²ğŸ7“YÖ|ÆÚ„‹”æ’ã~& ÚlÌ\‹ŠÛ«MÉChÈÓVV]<UÛ?®~kÖ™}×seÍµ§‡T0’ pŞÆÛ(r?‡’rÿÓĞ®i”Ù§àWµùÿyÉmXodf3.Uå¶”Z‘Ë€ ¡ä‰„†ğ6y,­¾º€}rİÍƒ¦}ÌáäQæ'\ôœïçÌVào¯ôÆøId²‡®Æ×:ïHpÄ¦7¢¾W>mRÂKX6OdĞéëÁ•™€;Wäh»=Y7ı°æŸˆ3şòxu–õ(5/
SsÎˆBÏû¹R¶€÷Å¶æ·Øê#¬lXŞÈ³ ¥ßØcÄWoã~•4“síXK¬DJM>ÑWvİ/ Ñ^ci&‹Ö'¨Îœg¥~±Hkg¾}(ë®ë€TZû(Ë‚ƒ÷Á™Ìı·¿–T‰*úÑXÁâ(“"ÛØÌ”Ñ%İÁÖÀZo÷§±±#
¦l8dP¾ûËIğœ‰0QÀtîºHĞùeNYm?âÛ!íâ™\_í
7ó‹¼®À"l£ªËìeŸÜÛ> ÷¾â’©lÂóQÕR©V8ãVÓBÇG¡]û`@‰dÃwtr2 ¿ï°˜—S¼omÑ³µ¶úÿ0E/âµ¼3Ôlm¬3±(¾.’F‡¸
,Hı‹+^$Ûöù¶¥”´uìºşé«&|ƒÖÁ4_¿SE†ú\)©/¥ª¿ÕC•$yíÉI(„Ø…DŸ/=Õª×“=Ä¡şç†"2ÈIv¬Êg•ôâP¥¤ãè¦YøµJ@uŒTV ·ƒÖ'+kMßRâßTà4·µ³ìløH÷5×Z³ş¬Z:ãŠ±†‘J]¹Ê¶òB¢…½`^ïqVwùÂ4KEœjää 7D{5ŞC–2Ş
Åî'TO¡Ò¬—[Od­ù³ñVi?·_Îå¼ãµ4–„=BnšÂ4Ø’“.xÃ¥›t	üC×ø&á†ÈSïÊ~«ÿô¯H¶<æ»5Â,eY2ƒ/¿³2õ¢ÁyíÚü(qÏ¦˜ß°¡Û=~ ÍôÖÙOçíŠqşòzi»£«Í0( “\øÿ}U_ì‡˜7hú‘•8v/)G0p}-oßi„ê¼×àüHj&v~ÿ¦hêè&ËŠ{úğ‘Qƒ´"Xxàêş$ºsİŞ+­GÖ
7X¿`©”*$ã°°@Ãmt/DlsóŞO™–¨’è°hÔş&ĞtEí1Õ ƒa×7ú/’Œöòt2×¼ñh=†Ïƒ¥ãòÚãnHU0C]0‚~Ä	ŞG¦J0‘3±`üiÁK±§ š£{ƒã&'à‡6äIÍ´S:ğ‹»µçO“*ìq8®Yà~†ü‘ĞHr¦ˆ¢©Y]yF¶1_İa½R„z;ı¾{x¢’Šv’ÉöUå‰P¼.ªƒO•Š¿SälUá”5“ûí×´ü¡ÆKúÙ	’h‘çåkıÚwÔT+ñÌlt8OÕäãIŠ§Ø™.;8[Òhb” m)²5‰Hs€ùç,Xì8ãqoîÌ>ËuXN¤]6,^ÁUbÖ) ÿbÑPHBß¹)¸«)Fd™ç&na•	jµMF=Pšmcs=†îƒ¢(§„Üë‰^Z¥ÓZıÍ˜é+À¦	#eª Vÿ˜ÈzAGB…õPé ¤;m L*â"¨„vÊt[^ÄdbHäzpÚÙ~ÍíOVå[[Ç Mo[†~·nóÆÓ¼Z½knŒ94Râ“¥0¿‹tnE%>™[û¹ü'€àÒƒÙ²a±Ìe	)	‹äáKà2èòÇ¸jê’±>ZƒîÓ›óÙ©Ü«0ZÇëuh®Œ"n‘[~i¸.B¶xãÀ0³“hÛîÜ™§Z½íÌp•«Ìà¯ƒóŞzÿa,Hî“¸Ét9òKÁšò} ç v<84ò9ğbBLÛm3şëƒ:Óª•äĞÑß‡'Ûéi‰0Ü¬à´üå¹Gxg‰íqu|àõ0cp¶<ŒB™Îd’×õ/¼õ“W“—ZŠ½‘9áÍÌ`<¦­,'Ğ¾,OË]ò›~òm•s\€&¾Àr† ¿Kâ.@o“ç¸cªËuÑ^ÈÊ‡WiZ´Q“6ƒûtƒÓY¬
Gí‹zd¤m¸…³ô4òÂ>Æ'úËáœ¿ÛD,/Jr_»$(Dé&šÅŸFQ‰DçË*šŠP-â [äg öW©ı|İ³+	½j CEm°'Î†ÂÕúé¯ ö\/©³ç÷ÇXGÁQÃb¶  —3èºK[­U¡/3pOIÏ„5ÍRıë½æÌ Ò}ûbÎ ^õ{ gcFxh|”İSVX4c¼#¨éÑÔ*=œúÅë×¼1'ì™³}ª3q#å·ëLš‰ã\…aq³Ôã°a™”cM2Bá Ú¨0­C„E§\:”ÖÔjß_øá/*éwûdmL»m¤ 8’LÇWÂzdúlš‡ƒVm‹ ô5} ¸—~k¢a
a_Gìb7¨œÛ¯şMø²ßçYÄ„ÊğÈ¸,m8YÕS§îÛsk•p@ğ¾Î&63
 ÓK<9ïSeÑ‹ß•Lcwb÷óĞ&R#²GÉã5}ßØĞÄ¿n›”OÆ``:Í,ì×ş¤Jdñ.OåzjÎ¥™>¼FK;»Ôµçm1Ô÷Ãlè>c>×YÓ*¢Ô9Âªn{ç×ÖbT
¶]´T¸7{ò£Ùo*ç$6Á†–¯ŠÙ Ó|r¨È7$«I8Q‡¯xÈDòwdåé¡¹w¼ş‰RÖ™çşïr1j¢œjd,n!ãÿô_¿~i‘Šçy^{÷Ë#ÌPº×xAU­uŞÈ	ŸãĞSˆíJ—='ÀfÇH/7ûlô}yT¿.ÀTM‰V6öIg¡JÇYºõá›¤:¡0Î†)Àê3XdÎˆ3šƒ8;Íâ…PÏ™ı·Vhµ@èÔ´*U7¸ÑBCµÿå~Âr4W1¡a¥w}×Ü…¥‚6YâCN"¶¥Q“T™¾ÌJ†2A„µàönSÑ;«ñÄY—ˆûù:Øne®>‹'³©opH)’ôÜî‚ãÛ9?|ó×õÁ”ÅÆ„°Š¬'_T™¸øX¤>ú43jäM—ş7šéç¬äë¥§¾Ÿ†ĞaÖ°vwØø¿éŸ•ó—âĞe®SÉ:+¬µÒ‰ÆÀ$/^‰÷i‡é·	Loü8^e+FGXK~kxX4

?j‹Œß½]ºÎ›÷WÛkwªöxûe‹z~ Öo„Ö|úz Õ·»¼%å%˜ªqâ­™Ó|ÔœÌãĞ{íÏ$ANÊ†ÎÌÜ(JQóï,;¯\ÔÏBL/aò÷F|Šc¤ÓıV#ŞW™d©.ì¶n&~å¡Å-Ëµ#,ù{’G9¬Bø¢\ˆ”IëÎT
'íÎŞ3#¬ÄŞ½÷„È±–n~#V0S)E¬abk6ÂI×CF(réôxÊ»6Ò.!©¯ÇVàö»9'–„Ùùw™ûÙINh)ÙuûbUfC¯”îrk,•/¦Ùª¸>¹£yOÎEúÛd–x¡üS)ö¶ö õÉ%9ÒÌhÎ'F± îøYÅÓ§›KÖ7ßiiì¹@²jîÂ¾ÂÓ‡˜8,…İqqõï|2š@Ş‡ïºÙ¿}/pâ¾˜ôyöúx7–%îÉeC’GÓ»9ŸiÉ…•…ï0ŒxƒÌÈ»¥Ğœÿ‘íÇÀ-¨ÉûÜ¯Õ-›öÓ¬ØÄVRJ)¶ü]ÕªÍš=îd6Š–Sg]jLÔƒÚ:¤»•:;šØWŞ#ºÌèº[ªo±X•ìc«³õ~ópz¶YÜcEë®àã±ËPüŒWoX¹Øõ’€w ¤g<«òi-¼oR*¢ÃÆîNÛöÃ»Pg åú1eMÈTË àT“®&ò*¹Ö«X¼vRı*$Ÿf\|Ò•¶¸YÓ•Cåù×xHÏ…z&W—÷X·Í[z­¦ğ´×”RQ3)ˆ¾š¡2ÚX˜{–ëˆ£Yÿã˜5ØZ¡\-½ëQçM”sj,zĞ8~ÉDJ9]H2-Ò	„İœ¨.Ä‘Z¾ƒmrù_ÁÇ"Z©O¹Üt¥1`ÙjÉ	eû.ıAZ	Î_®³ëj“%-k'2÷Ğ·ªê0C=Cµ)CÃºmüÖïì—§à¨5_íÑW*{NßùK>èãÁ­Ãçç‘Æ˜%fsÀ}Îlyº^şË9®Ï*¤«kÁÚØv¯R'¥&˜Ï€»È˜uœäHÇ8İEóÄŠ”+Ÿ åCú&”…qc¦8ÚG+™ãQ}R*uË/î; I˜ ÌÑÙ¢®×Y;vÕ‹ïÊG—R‰öØâ¼ÛŞ¸uk€«›Ò.ÅÌ7Ù«05]_šu¡ÜVmIá6 2iòpŠŞç]ˆüâ2rR¥ãÚ*$j/Oğb/¿Gº¯×úwZ«˜	ÒFW‚y˜RÌì =õBÊêé£«Ù‡ğª¥½2ˆò†Š.hógC(•‡`ê®dÀQ¢d´–õa¢Uş©]QîB¨¿H¼4ÕîxšË›®°ùàÏE³³ªttçD ÅFÉù†aÊp ˆp®»kİğ'ÍÌÎé–zC‡ÿ¤Š¨¬=¸¿,•O9öËiÃ¥v¥™»r_Sn¶8bÖt~Ä-õ­BĞTİÏ¬1¤R—ø¦—Ù¯÷İéK?%OøÛ¥î€\XI8œùî ËESûSÉ{¼CHÔÌ™f'‡bZ˜¯‘Í`´´ "A/* ã‘êæ³n˜¶PNÕúŒ£²oYõÍ†-¿i8³Ûc”cQÿ‚r±ävT@b#Ğô>İÜCû%“è¯…Ê'ıíÓªfŞ ˜ÆGÃm¶¬ÿÖNrM'®\•,ŞcXI›¦>(ÉùN#ôJçQï¨ÿ5OÍ—wŞ¢{µ+Øƒh»¯F•¾fY8yûÍ^’Wt£gF|oV¶J½¢ä‰r#ñ"j£ğ2dÙy—LòòÔ8’°‘OY4zfß€xzŞiüFJ¯›Ñ8L~ß¸b[üİ9Q¸4`<š¯bÃÄ¶ÙjÕ·K>P²Î…pµky-³9Â&u¨Kñ…ïf”`Èö˜.AúøQÓúĞ	GËN­¢\6o#ä.dıò[-‰|Æö¨EËÓèĞ@7ŞlCè
›^êÊ	T¨ÁH“íkôiI.hğ¸z@â¨’‡÷áûÚíY_»ø;¨`®‹ÿQÉ+ŒŠÆ{îGäÙz&Ç¼pî's›EcÛ»[áÍLÿ8…&i.{­¢“kXqtVş¼­\ŒU„™<¦IàÓ9‰2IYmÆèÿñı#µ¼à'
<2ü£XİQåj ä‰á;‚Ë$ƒøNÕ¨&íó×ùHŞŞ©¢òÓ‘Ì;¢lñIVZZp+ÿCkµgb´Ë¾Bİ5 q‚i½j|Î6‹|®ØØ!•@zM¸*Xi!}"frè=‘·(Ì 'ë‚" ;7Õÿ‘Ø_Æ sş×¨Éø'—õzî`R<kT@Í&{¬KX¸¨%Ğ°*5£l”pV½‰ÇÒ¨óâşs÷ÿ)i•àö 5, ˜ÙR¥šûÊ‚F˜²“#Y'æ1+³ŞV,ÏJ*°—õpšI®[€¼ÏJoª\=R%š‰}ÿz¡€z%E_böfSg¤RuiùV&[gÙ‚¡ÑØïşÍßıÓwd/¾9)GÿÙp.% ßÌ_ye*‡5JİÇZmä\³®ûõh\)L»{bš‹ä±‹c×n—ƒB¤3ø6³ ¡¢Z[1ms\èÌĞ3hSo×UÓ½;‹n¤}Í”šru€á$9vf¸k—ÁpµğYÕnüÄÙ­Úñ•­PôªgwhJY"B²SBÉÿ¦ü2KA÷1JğŸš"ä0ºå„Isûv‘áù“Kéwy«‰2¼5Æ¢c ø…&È²æ±éBù_Â­˜7a
Æ‰ì¹$è±A€µ\ô–U*ş1D’ë#IdË{ım=M4$#_F30^û¸DÌJ¤â£§ñğİb×-Ğ¥xläÿBe~ÿIætØ+œõÎØƒ”õõcÃÊ5ÌJÛÁdNM†¯% Íl"Oaÿwlæ,~Ê¤ZØ
h¢¯_.²&RÆóÏ§qòØwªY’ú Ç ŒnrF¡Í+5¹ŠŒ}¼DÕ?ø¢­&ğÌnhŸ‘ftóƒÙ‡âO'ù~9ß¡©kH‹}Dp•c¬ÂåœHh6é¼ŠÕƒè9ÉC‚|Q»ï¢)]UâÿÎÕ’€ªOşüÏ>7€§”“˜ÿöj"ÅsÑÓS)ŠÔ	ï•Ü˜3ƒ¹Ì -pğñ	¨)Ò_;p›‰ËñôsÑÂˆÉ6PnçU¯Éf%"–ªEÜ÷¹xOÈ${Bq
K¨>=AÑæ"éÑ«u=İrò»~Ú»B×#s¹"3„*ÚtŞp—m¹æI iš-fÂá’€| s”Ù?N©Z¼”Í&ÌF‘­] é"¦auT’Çí½ÎŞÃ÷v(§Fâzœ.NÔ÷­Lé/i1 ùËßâw}ò¡¶AÍfŞBGmÅÁ¸sÔƒ9ÒåT¼,‚`ôÃèãòp‰¯î!®bÌÄƒf#ô²rU<·Ë…CÈ#%?y*Ë·À`+5Rá¡ıíÙ†¡ÿcİÍ4ò®ûICPBÜ¡‰°ÂâŞÎ9D£şjç¨ù§”|LYˆÜPWÒŠÏèòügúY‚D…ó‘"tÕìqõöó\!qÌM,”º
ûÃÚ¹á°_¡N
ªrRŸ.à	|a‘QòÇÔßäIsjnï‡¹ù5YşäLâÒyé‰®›n´	-¤ƒ¹I93å9œ-'çĞ¿ª;`ŠwÑ„É$9)ÀÚ\+á{*µÏSèÓá;6“`õ¬¢•Ò€ÿvU‡©/œId:Ìîïd«-ü´x²Y«/_Æ~÷¿éÍç{®áãÖ*’òM¬oöãš=Í{è,Î­6õ²ÈåbKÃ>K_Á¥¢&ß•TwıŠ>t`é¢‚N<“¨Q£ $~f/PşIFà×
%NÇNï‚ğO¶8(VMò°í·®3š\µ‚¶´&•ïÅê|t9t•ïWûdffTh½!Ë'óbÉ31Ó©_#‡‰]ü yâ¯åNù-1²lr„™ì°¸êê‡MEìØqÃTóGŞTÕÅğÖ:oßçW	¤Ş‚oß›´F(œSˆGŞ‚§$ôyşYŒ÷Å£2ÖŞïHÃpO_V3d1”Ex±˜#jĞÜÓP§­_gc®©Üè"§f×ÛEUæÎŒ54×k"¨¨ı«Â¶Lú²*0ç+í#?ÑyP£<ÙAP×¥7R	»0j¸E±W‚tSSUQòÁ`Á^3½Kş[`Q÷şãcÓ¬˜oÉ%‘VŒhoâŞÙEú{!'ºú»›ûT[ƒrUY‘Ÿ}Õ…¹¨s¸»Y÷2e9ş{a¬EÕQLÔÆ*r€5m/ˆ¹š]¿çÓxÙEJì«<v‚]îEŒQ?ŒbfÁ €'¤åÌòí)jbz©bJgE¼=Í ¼ˆqöM²ğ=€Öë#
ê'Ì‚²”àú£şYØRêBÂòàfË&Œ+±¿CõfŒËyEÕÑ}r­Ú’éOÕñÂÀÓisš¹ñ’©ÅLÛúR@"¹°3ÒüÌ.D3KRodp1¼Ì6`Á íƒrÑ^"á¬Ÿ<²)A0÷%msó?Û•Hãl>Àl¨MÇ!¯Ğå6B¢;Š@OPUùË¤zQ.Qƒµ2‰ ºÙ(Ó•gÜCHDí)÷0.²C6]D±ù%ìå€Îin“SHùaØÛ&øÙ‚Âú±+“‘V†+<óÈ˜‡üì;¢³¡>ô#G¶ÕZæßª¥?ùËÉ·SíÇU¨éƒÀ! (­ÎàZ„¯e”ƒt®ûmÃUŒ¨ ”°!8¡H½·ä_³ìiy•ø¶Ş®µ¢í9ŞÁ—[ïkg4¶›‚y#ôZƒ1ø¿ŠÈÕ4I`å’Àa:tsp4›Áx—†êM¾•m²Bw Á–‘úzb¨g96;?Fú. “TŠÑÃLÏñ™ŠØymİŠkµrÅ”Ï>ªYj.ğøLæğğõe‡?LÇqSóÙE$‘¯Üy‚RÚr¾êi±J°?K' 7×ÂÏ„;‹ü·¿”NLLœK3FŠ%¯)g¦štİ@¼VÍ±óÜŠ8ª	Êˆ¶®Ó§¡C°Õµ›œo^Û£Yê„ı>Qü×ĞL)«ÒÖC¾]Mè·¹ÃëO	E€Ø	cwãp™Á~lmßÁ}is¥ê%æ„”¸Û¸×Û9ŒGıW¹(yXÕ“
DC0ÿ´I¯ÀÒÊµ…îKK—_t‘‡-ò>ğUX)¯ ²œ	Â¯1àZÊíNÑ#°’Cøı–EÁr:#æ(ãÄ³9\lM7 r&´aäR°-Ä>sIöá‡,eœXe^…Vb±6Œù“½k6¾0T¥FBõ"gÏ;äIİ,'J,YHúd'åÓÔ`¾{•?†
bXvG*İWc¸Î‹İ5aëŠœè~	Î|¿&øeK>“|:ü”Fªqá<«eU_©~ºS0`|gê¨&v¸Õ‚4i—Âo!Kï•&~Àår<°2oAî/N|ã-„9Ñ¤r øAËÍ«!{P(Æ­µõ`p¾xÚó<s}ÄUçíBm„pãÓœ¨õ L<Í6qóµÍÏ“Ñtı^’Ébf™üåzM€ĞLdFlŠà1£ÅGÚPµF¢E‚¥“•ë9ˆè(¿+‰ n8®y”®R±Ü(!Ú8©èº/^»åÃF¯ÄM”ÔÎê[„óöt›.ÚZ8lğ’ı…!µpû;ì´(€ÚİúØÍÇ»íKÂkçNşÈd’{è•˜ñîywè(âEö=÷Õ¯˜!#=°N'›túß0’øy,ı.Àô‹ª·í8œéÂ·ı¥š€Ò±vÕŒì,·[Ò„¸Ù³y—ù›ÙWŞË=ã¨{J#@\ü4Ô†Ó«çœ\ÕkÎ–YÌ‹MÖ³5fU“(à—{»•iôÀÎ2{®¥ËjrL¹—B\Y=—Åùp !ç·ç*[6Ğçö»9XaØâ¶€X«€ÑAGÛ‰7Â¦G—RË>.èš·İg_­2#¯Ø<)mtP¥ÌòB,‚»6Â|¿;OâqW}ùoJc,’.£Ü»NÏ€¸KüG¦OË‡Æ3 äßõŞ@Õó£h¼6ŒæÍ,¥½íb1İ³D¡"ôak6'^±Üm4N3ğ	"€eûÁ®”fF4†*oÊSAıèÚ´«ıÌQêÈõR:ü¯{¥nªÑËœa&pøAùè›è$^~TZ©Ù£Á’°…^¨G«Mh³…eÚ§¶Ó‰Ü5_Õ½]nìk3c‡ºi›†»"†mª€ŒÒã»æÃz‰õİ¯*	Ş9¢ÜOà‚86¯ˆSM·u8YÎü¦çÚ”×¬P'ªbü`Ãşd@Á|Jƒ­D´9K$] c£ïAä¢ë;ééiÆx,Â¹¶#üWÍu
à–¹¯¸ooôJ÷Nøˆ.ãPµÏ¬‹f”®M¥^è ¿³–ŞOnÙgÁëfCNôµPJÁ\»w›óVæ®§Ü!?txúAi§AÉƒó¸ép'“~L²Í35—N­ú†@’ñ
JØ”ÆCºàpÀx<M| Ø¯»şWÊõa”¤r¦|#ËÃSâx¿„W?ıíßå1 %DM¥VØ¹
mh½Qf¥ÛU'U˜¨¶fLÎ:w!%BZQmøxÜ}!{™òCEW”£1‚r[hF´>¸‡áÏÍhÛÊj¨ÒŞ~¯KtçŸ¼2Qt÷ö‡1«ËfÛé¥Û¥ 3 "Ó¡Bßeo)Å–Ü>—³)\cK4›XAwØ2„)’7 ²Ó8EõèB>°.ıV"¼›•Øc
`êÉgÚ!ãD±\F½½=ù]œø(»U_@Ÿ/RVŒ…½ƒ”oæÿmœyÈumÙGûGÚ‹ Ä×^ı¨ˆ¸QWëß=ßüöZkX™@´S'kŒ_—¯‹Ô¹½/³ñ¢«ÉWùxp3ó°å
áY6Q·•oaIúa¸æUôÓÑ1&Û
šİl•uÏ­zİæ‡°rÁÊ*[‘[ÛÊdÅ)BôQDÛAšq“@È½ï`<9Ïƒ¼£àœ[¿UÜÑ™½¸-K§»p’•9œ…&êkß†9½¡Íå~7šfƒénKnµÇ@g7u_§SNX0-îåBsé[€ŸNÜh»D3ÑüVåK«.í6®0•Ü« ©|¤—OÎ$üõÆqs¨—ı#ûoA°K$ÍÙ–©†ÒE—ÜNƒÜô)Ê[ jˆ%„d48{'Ñwÿ“§Íøpõ ¿*j\·:¿‹Î¼òt¢cwüÓº‹WÂ$Æ¯êÔ¶à—³ÕÏÀv$b+ïb¦ò\¤c>2_¸w1TP·éÑü Û5äqÏ¢²©%E´Ô7ábBãPÈ|5óËmŞu]ºùW[ı³¬-c\Ú>$TJ·L‰õÉîÅ8:eÿ/¤­tÑ¯×U‚°"š–Äà&ôZÓ±“KÍ<g€¨üÍHÒ'ÃÅĞ;kÅii*€Õ]Å2g;½R|zîÕE@	v$ÕP°MË"…q¤•Wèf¾µC¡½86˜	ìJ¼å>ıÍøşjÚeï>ínÂ¾I[íg÷;4ÇeâÜı¿¦õ–¿à˜ª Æe&ÄV¡ğdq¹Lçê¸¬ùïVÃv„ZUÅªNÛAˆ1°s&÷Õ£e?Î÷j>ËAM™kv»‘\áÖª`†/Rª3ÿ'É8J¸¿bƒËÍ3?ÊàG³eŸªüBøh+µ¼ê»•+[è
¿-š·sœŒóyiEÜ*¸'Y!æËÒ=7v6øœ]%F©Õ¶öó;ËMk¸µ»f×Tìş†Yã®¹HŞI#Ã¡ 6Zã×î&İ4AéI†‘ºî5U#¢â»º¾Ş=&×Ÿ’¸-‡L1©Í­ü¸Äf„¯ê®Ùcãıœ[|^«şøkvÊ#uÎıß‘{Úén·œ†l³¡~dˆ}gâ÷ĞFNì¹0ZÆ{p¯±œÛ@ğúI¹…ïEè‹±ÙÕÉ¥÷6>–µ-¦ë2O?›èR¬ï„#<d_W÷Ûp§œÚ.;ÅP Ò®z
ÇœK\…õÓ$ï³ø¤Æ{°Ô‰Şı„=|ë.râ+•r’¸îŒÂ/ç“'8`-ı¿tYÛß¹
ÿdÈŞ¿¥(M$µ„5ÁL[å­úÓÌÎ™·H	TG—ĞzVÍâ1ÄRºÃêÊı®å²VE#hÕ^hĞ’ŞDª5èO¶è‡›ş·Ò0^6ùn_^øçw@|áÎEÜHBÎø£¨¦ÏâGõêLøFX†Üz¦ùÒg¡)tS“Û82CÚĞd×ÄRæB!tØ¢v|gğ²Ö¿@ü¯G@góİ‰öŒö#6ÿ—oÄíİy$	Àí€p^Óë#Š"O$¨¾î[“#£*sÔ·
ZŠ¾¹{*KÊ§¦Ô€¶7\ŸúgTJÃ_qó«¾Æ$pÂù<@ôq<4€'QTPªpÀa
!D"B ôWdÆ”êÑ½>Ç1ü
ÿ{@Äò_góİ•äÈ˜ËxH?)™N"ç0ØñD£ÆÙpìY°àşÛÒrí.ÍA³™˜˜¢@Ğ\áÂÎ¯b&İ©BNÃ¶¼¤÷_1f8<3åZæ›mˆ47 /ã/êÖ-™
¹îu¤±5øÇXxOXOP)K3æ‚ÙS8ä!!Û•0NBŠ"‡¬*SÌ*l‚æ ô­©úFn¿^&R1Rá}?.‹à—}Nw™´=¹`zdë ÿBr¯D13»xRåQÕí,İøºº±ÌñŞÌ${yÕ]ÂH•“½äóøŠzÍ2$"	9½1¬úÀÖ«½K­wdr6™Ò=„rE}»¸(Yøİœd¤&“ñå	áÈ™šÚŸ!B9ˆj	¤wâÙÏ¤a€À^k)°šÈ#s%)M™¦Şàe±°äëTÏË¬Æİ.Í³¹:±©;ôÏ7í8ÄÜ8vzØ”$Hs»ËğG ìjÒ(«&Ç³iëF\Xö Ÿ²¸*¾¯7İ×Ã*w¦ëÀÄG“Î¦Òûıô~ŞL·ÇJ±q˜ü·À;ÖW‰†pq‡F!^¶NûŒ	.`z\cHt?†	¿|Ğ™)Eâ²ô…ßÂ7×FşSÌ	™ÿÆ”8U°†Ä£mÖ?^!0°¹tˆtW­1{±VCï§écaÏ}lš¿òT…ØìJÃÈšhJ6óõş…†	Åª{b]ÁÀ5Ä4qãjœ«xXEï–^zYñĞkl_¹…èD‘å³Óƒ+áè+ùÒ^¬NF_1ëô"ÔmÍG…yF‡d>-P\÷cµ±˜²;ıƒ¡¹ÊşSè¹\ğ´ ˜UIÙÎÆøé°´{gè¬ÉÿE(è'…b•İÕª’¢IWÚ§§ËàÎN‹Ä.–~/¿°”ş»ê4Jˆá‹[±%×™³ÀL8*òªç0Ã¥äµL }&Íbe,ßês¹ª~Ÿ!=UxBÁŸ«ÓfçIZ(”p.,š_55íë?U	ÑF†º<¬@/ˆŠ20i§ğY¤óQ]ûí„tÀ]Î*(s­ìîJÉu¸-fH—†š1V¬äÙÈc;µA[ßªµû‹j£ƒWYŸz¸¸7‘F«£ÊÏÓÿ¤@´ ÅŒ«ëfÀiº6´Q5Ğìvá"’ÒØÆŞÇè‹Xğ?‰Ú•áe0ù˜#-[US”,ìQ_£*ñy2ß/øÏ…òa‚ø<ûHºoÌW–“´
‡H0÷ßÚO	Šø9»Ô$İ/}5ï"4çê§G$è™<{¯w¼²òm¦!R›/^bNxfUÆÙã»%oÚ
ÈÚ5•šÌ% p'HL…lâ%J¹ª]r"¡“Í»zˆ•ÈK%O~5Ñ…y‘®ãAZáyØ”ëó› èÚ-«^Ç˜fæDO—÷½q¿{`#Q]jıä¨<uÄi*ğ"úlq+~~Ò¹òùòÇo`ÁşLû"‹dì"qÌÙ—òƒ3o Úá±hğÛñ3ız€( o^ E¦E²©¯Ú´B±Wa@¼LTAó¸ÇŞÉ\¹J4zoLû#¾¾Ê?¾]´ü_#8îİ¸î],øQôÎƒí™5²¨3p™lÿ@jŠÏJ ×»¹˜Ûì Û…;"JEYÌ;ì=t“QsÍ=:7ÊsÍÙv$m¤ß‰¥cóÅÒnŠWpGŸŸšmúåÔ1ƒ—tìš{ò÷DğÊëÇ,ãb7¿Nò^@‰­%»Ä7d0Wù#4şå°·²ÜÄS•Ú›·ÇÙ½ÕÍwVÿòê2„{‚ •‘—™§¶õ‹,@²j!h ˜°MÔ]*ºu,äé;×BçM¸ï¯"ûúfb×ş I‰ÙK%˜²b*Z”lo€‰„¤8‹¹$—P–hs#!¹ÔemŒ}D@J™àµµDˆK–ÃòF4Š¤5Ã~Yıt³¢ƒòC2Øû._îíd2‹¿ ÁóAÚjm7åxÓßàµŠí1„Gj­²°Õ$ç%“øs6Xºµ°Æ<®‘7ï\–{ó/•ß³¦XŒæ'Ù0i¡…õÑ}Íñ*{Şg·ÃWù-)²/×FvZtvŞú?Á«!–ıª,+}=®zß2ĞzL8G˜–#p“>áL¶ĞçLÔhñÆ­#Â~ø<²¶3`e®FGÊäöÂ£Å‰ÃDcÀ©4	/:/ååv•ê‹bA€»¬y]¥=LŠ‘<®î§ôS©|ÉAÈ(İpÖgrïÑÖR_m%]Áš:’®5cÎ=ús¼oíù¤ñÁ£'s‹›Ï½“4ùñ‘¤±6hÀ’ÒÄŒö6=ÛçåY$%˜Ñ‹ìU¥ÆËÙ–½w¶* áÜ=Ök¡‘9†®Øyuö?QëVÖúErj•CŸy$ŠLÔÃ]|Øø„I7Aæ"ÿTÿ€ZKÁ–¸j<>\—+ùÕ 4"	/‘ïº³Ï¹%º'ßbgDœåÑl;E³7ÒÇÓf*'Êu/Şÿ@Dju"Í¬ÎÏXnİ©l{L€BÉA¸9fU²XjæOƒO%læîôpµ»<KË•ó È˜ÉŠ.x•íø‹4µ×Ëìæz9™û$m®l :±?‹Ôá&ç14Á#[®”«Ü
Ê'³s’ÂØ_F~Mc¥S_Ö ë¿9Eº=ˆ½X÷û!2èN71¬[8’}\º[Ô¾w/i¥}óê„ºónºòÇWçïÚ:•¡îÚ÷Ş†é“g„}Éˆ®¢lš&^TZ¸/á‰C¬Ê—kö´¥„p(o¥¼Û#Ã"æA}uÏZ‘¢ª¿$Ä½,˜ı[Ó§Xµ[
Y¤!«İ
°ÕiÅ0æ±~?”ÛLñqGdñÒ+˜•WD´MÈ;) ÜÔ¥4éì>TQ"ßÓ“‡ĞVoñÊ²å@µîıìRMe×Êv›¸øÿó´INF`³ã>ïP‰Ù®—Ê‚ã¸Ê³¯ó›µd×e W#¼ ºÕıáëË2H[ø+6y?A‰9c+Ëx…IÃYŠĞ ‘()]€÷ÈÄ±-ícõİáåª/ ­´cÎ¶ãÕóŸÓ++J”&¾­£Æyäù$á“æÇQPsÙüÂzl,‡+JÅLûEæ;]Ğp¥´>=[lwüıxqcÏ~ˆ©S|g¢Š¶ñ²…}qxr³ŸÆÓ…\?Ê0C:˜/ÓüÖXß²ÑkS¶0hX^àåmØîYhÅjOÊF§óA% ©x	„Pû¡£ "›5®#¾6ep24Š»eÙËZ<Œ`oZâÈ?.[)v´» å›rõ±3¸£×ËŸç;ü^1ãáR]Ç#u¡q-€½ù¸Õ³.›²*ÈáªÂŸI`£Ô5üOFƒGöN1ßFùşs7F¶~n8CË†úWLôe¿ì·.8‰‚=ØÈÔµ€”ZS‹UÎ$sH0¾Ú|¥qoÖ»÷v
•vğš¬ZG4põ=ÌÆ=òSy8y}çYÁ*Õ´°½ºNÓ#A.Ü€.è#´c1çäŒõ÷”*¦ÚÌCÛ-UI£ñ	µVHÙy|€.K´ŸY¹ª¹¶DXğ9SE£Ì¯#ÕûÇıQ³òçùÅòOÀ?ı<, ×Oàµê‹çÍté<şi—ˆ+°¤1ààÒhSˆDÊıQoTjÓòì#7„ªsÅZº›sŞX¤¸LLêƒúğåØSÙ^U Ÿ‡‡R–ƒ%9!GäÑâ9…f³`å]àŞWY@jcÎn—;@……ëZÑiô‹w!‰7Qxæğ›‡8]cDëP2`6qø;€¿0´U¢];ÃçV>dQ­Bªb3L¶ÏvSş ]03`ÁgÀMªÏ-÷ÖD%…):/Œ_2¦·ÿÉ¹lÆÁJ6™t¨7âƒM*W[0}Œš¿˜x1Ê¹
¡,ÇbZöIëÙç”zğâºVvñ`†ñÁ‘.
’á¯Ã:NêFšÙ@ >†ê×
û×«{Âr¬óÿsfÀ?ó;ÖÎh˜Äo@Â	>.>Ğ£ˆRê%¯ØRı®L ©%1-®¿=›ÃüİUMFzÇïdÒ¶D„EÙĞG¥øÜ:‘åIv×ÄjgıFò’ßİz$Ç¾ÆŒn<ÏŞÓP­\ÌÔ¹\¸¿ejÌ#Åw¿W)­~HjÒC‹¡÷³Üï«”'Á÷òr‚Ìû´·;­À‘^Õ›fº ƒNa_]CSLkãåë>%Àgb“,‹Q²©ühÅ¹s¡âøUB"ÿ…ü4~Ä•o¹ÿ¼Ùvéç1íH „¡Ã_­½9_Qh°®à
ÄYø²Â·/XÏh{fzàògàpDäÃL<69Ä6OËù¸ª$•™äß…»p¹Ñåö¦” ?ºR<­$š¤/	h´¿}Òl’»-KèÒÌ	l­JKQ,êsäÆîz…}”å`m]óD8mŒS.KúN£Bk¸ÉÁÈk&ÀÿïeïHPš_¸Åf_!ñÈÙ&Sä4]%là`y„›ëÁºqSèJ?¢™ŠáËÉĞØğ;9qÇÏ‘Û;2†Ä’v½m`•«çº «(Úsj»Ä‰™+%=¼
‡ÀWˆ"ªéZyè×9ìb£ŒUœO©NÄ3çm¬	«•ÅM„8¸÷›FxÔaOËYs*›‘: In:¢S58“ñ3øš”he=.¢[mÔ2”(
,ö9U«gà‹¼~c5ÏËòy»*•=cb`)ß’*úÙ]"{rMC;ıC‰JSv?eØ«IŠT,CFÊ2B'4S}öZ»·IªïØ›ƒ0>ŞÄÌF’±u9¬²»`x¼Æºš¤ºtì.æHx+2éq,ËÒ^ùñ´Ù1;`Ô<[á,üÃ}‚î„2YÑÌÍ:™—¼)ï"—]ua0Â¦±KJåÆ!3¡'y6–´şµ\¸ôHéÛèà®u,õüN3R’æ=¦xJ<ı=ÌàEpó×º£u¶rv±rM.ÑÄÊ\¯U­¾­¨óÑ«‚YñH6pÅ6qEjá¢`Á,ïÿ“Gì¯Zo´©Š0P•#ª ñèTß›%'Mw†K,
&–ƒ~	pWq Á{+ õtÓï~†ÍWø ~jË%şDü!Ú¹’´¿æ7”Hc_.Ï‰ùÕ›Ã–É_ŸÏ­Ìn³`·§ë+nİˆ= „·¿uørèŠÜ'Q‚ğ”–’ÈÕì†Ì‚W0¥4=³gã4§ID–ÿó¨“ø|f×Ó¿kğBKšÓ.¬ï•ÖFOtpD¥oK–~ÕÌò¿—’ƒíù*,_‘Ÿ=	²H.Õá+º²k‰ÔÁíºzœ`­‘· ¦T©bÑ+ADÚò‰áØÚ ÓşÄ¨èŒ-MVè?ï9é…Hˆ˜‹ì‰ÆßgõÊ/‚{*¨+#A{«‡My}QÈÖò¬ŒG¨.ÿh	Ğ$¿ó{=./Ÿ&OÎ;2A”tJÌ_ãéDxêŞĞ•n9t#êå¾šB¾ŒIàôgÎ†¡ÍÏ×ıŒb~A?H½8´ßşâÿ‚`‘…Ïºº0™bªı(çáÚ±æµéBº,-{wÇut¥#kN…‡
àÿ²s3ß?ò«w3zÀÓé˜… sÃZ²9– e
Y-dÇÍÀ…iuÀA»“ÕÓ‰~ÑâÀ°ß2 ·ÛÿÙ½c®(¶¸J%¡†:¾s+§·¼Ú×XÇäÄºqOfØÈ$OìÑÀóªÊ‹#bt©íµ”Ğ>+a‚˜ù>¤÷fÃ}=¹Êö^è Ïi»6‚!¯Å~Ë•pûµ×½TEè¹ ÷¥(ZH:|,+×âF-È¦ãë•¯´ÉyRXKÊ¡úOwò¬:¦0YÔææ’­ñ×:NMšNUø÷åº¿t{](nÀ
zä~Kgöò´ŸßÇZÉÿÎÓÚVDî]¤ıÇ4£4^ò7ç“_ÖÎ0„†³R)'_›+ó©Œ¼¶ÌFÍ¦Ç·'ÈIU$+¨ @Cñy‘xêZ»ÿ”¯¥}JDÃ qÌÊ#Á¸ù‹
zh,Ëò×òİuİ¹+bÿŒšğŒ›bÛ'>S|"òZÊ×«:‰¤Ò¸ã½à_Ä Ö²S˜OäæÊöDSj?Æ^‡ LíRÉZ«“æ¹å¬†W¶mØaHq#{ªı¥p¼ñOD•3JoÜ-Ç¡J¬å%ª©hX/õEO¢) }›GØô¨öX.²&ç”¥½úì†6­2¼?á‘Ú3¸ˆVRÌX^>wš«â¿sV²$—Hèrè-)Ó¦¸‰Ñ¢:È=Xn<ahş¥"D’zøK¢<…_sÏ®ÎîÀÅ¶SC61R•Oh¥ÆçìAêg3¿´aõ«G‘8Ä¬‡’ÀH··%«@R´8Ô+§+ÔÈ}màç Ò%{æÈ­j#Aœj÷ëèˆ·Yªt^"ÍˆŒK¬]PãÉÕİ:Sî®)3ã	êw†K»qMíğâÔrl{}EgNW‰jåwqúI©FM(œ°U(	Úˆç=®áO­ª¥³·ØIøğÑn\Îk‹JÕß•2MÒ[bFñ)5Hİ¡òjËØ:Od‰yìòM,Íü2Òæí$=Á3Y!W£’Í}×6o‘zP_[©pÄj
D2RJRN] pòAÑ^Ô€Pèóuø	ÚUçw ÔøV¸_T¯8øæW/òVMqïNPp¬Di>¥l÷õVß20:¡‘wÆ-§ú*t]f×¢ĞN›(ºP.sÿ…J‹‹Uåºİ|q§É€_ÿ·-g&xŞ¿Âm‰ù¹sòqØêÙ¦…
î\Çh•¹$}/ì@$2ê§2åœ¿†Ntš›Ø<_B‹9§¡6U5¶šà8«¡Ë´F ²é‡f]³eçE®'ş?‘"M/a¤}á%ï°¨¸Z9Œám$ˆD^3J³äÃõ[z{KÃÍjà˜”„’…¹'æÊàş­½¤€‘BÍ'ÖE«Ğ:øç=Œ\?Lìƒ}^e#±ÎÈ÷è|-ÍjÏ¹ ú¬8H“ì `Â²6'£ndIQ	£Ô¶˜ÔZìÊ-ÃÙÙÀWĞøÛşOOL
gbßİhzõ]šÜ¡ÛxA@ÀÔ¹c^"±£Œİnoyó/òö%jÆÅ¡TÊ›í¨KÓÑ‡­¿
$Ã¢Ô?è0ñ~gåˆ4ò¬3fçY0Ì‘!¹NŸêôv²—DQ€/iZÌ}[-n>sl‹t„ÀgŠ¹é±•h¼fu4°Ç;8A3é.4®6akÓÚÊGKhËïwÓÌ¨«[®s·i*Iz²Ô˜¥{=dÙ^ğ{7 ;Çä¶v Úı¯ş™‰ìâ÷TBI+b<´àEşqqc«ßÉƒräJÛ%°ì­µo¦ÃÁ–\Ø~ïüÉµŸD£7˜è½¾ªñ‘ïÇTX¢h&c–  ioˆ!æL9V‡ˆi$}õÍå/ûŞöø%TLò§gºk×Kjı(-G­)‡;ô©Ä½¯˜¹éƒ<Aaò¯Ù×ØnİŸ8¬ğ¨Ã/´Mg5/iioÙÿ	6ñ©OøÃ¹ŞÅ‚zÊ¦Ü“âX×V‰EB;ı;„Î\>Ê\*0×yŞ¨å“³BÎÄèk«˜Ï×ã|SüãÚzdC~Í3B`§MÔÎuâÅ†Û¤¥4#‘^ixıAø¶ÀÙà‡Sw:Û“ñ‡<C*vôoÒFb¶EåŞü¾'¹ÃªRL‘=œ†kñÜy¨7ylvé6^ìÅC^Ái%øã-GXø
}—ï#;YÄ×Q@IFà|î9HP'ÎR±2åı;?{¢ØÄO³İ;;ùéN Qçè{)G-åà<9Ñö€J}ô¿÷Ö
Ÿ sí0VŠá6ÚÚ].†<áÍ˜gM”QIğJåå¾<øëcO&Î}=hË2;×
ĞÆÚpœŞÄèÒ©òj¥È„ê"DFĞjùE:
®{Ç}&şd¯%VyÙ‡å<Sf‰K(°F¦œÙ@¼í»rìb?™8“•ŞÏŞL¢cF| &(¤‚i=%ÓğÖğÍÒ1 YÃ8"­'ŒŒçáä,Ê,â°Iî;–?e“6Ò0®Ã…OñXı²üô§{äµO=¸ÑµU;€úy½õõ‚#.`qQ¹rğg]¸xMúhcÉÜeÃ»tr&&%R¤‚n(òÕÕ-iB{¹»‚skŒŸ ToúÏTÑL‰¶fK‰ÛğàMK®!Œœ|elÛB1¼®À·­y2hùlõOu<^…âQáI™¬ñèŠe—ìWÑú|>&9šŒLl°0¥ÇÉOÅgÑ#óŠĞ¦¼ò¸	vŞ3))j¡IÆ$ê‚îò|ªİtj.pŠªÚKg¥­ÆNFHÛî7rÓôÀä¬/àOÆ*Ä$÷¯!õª8š¿¡bqİ|Ï€ŸŸºPıÌ.:¨—÷ß3*P£{£g«°+sÆ~Ù9Î5PÒÉòt9ßó˜¹ Äâ×l7±{ñÃ„ ©„ÃBìçÁÇ™eéë®cƒ}İ»	32ş‹§±/˜úF²m€×DÁ-´™ùU‹?Ò®OŸ
½¯çµ¤¶™M9#-©ñ8Œd»Ùõ‹/9ºıÔËó’rğ‰#fpö¸ĞD«ĞÚX:Å¹L® ¯§Ù&²îöÁ½!¹ÎRØŒ¹º£Xİ¹H—aÍT«äÉÃœí{İ*!ÚN÷i-È¤>À“÷b7‰ÕÖ•…óÖ¸„îâÊw,Ï/MZ_62º²Å­¼}B=K6µ³–x‚^S¥0YfpêïlC"xs•¥·jØo¶—^ÕV¹™ e4)¥:•òHìÃ2§ğõTHÇ¾¹Ùß‘ jŞŠŸ‰ŒjßPWÖ" ¯.¿ÅJÄ?ñ¿¬ÑÛäó¬:Ï…–âï¾ağZ•ût”…zœ{âÙs0FÊ'û…ÍÙâ. Õá#.xÇ‰Š'š?gšÔÑÃjxp]2¾¸½,în"£”;)–¾A…ÿŞ]38ŸÈï«5·MÑ©¬Õ;/m‘u7ÊÃß¶†÷£¼ø¢Ò¤½†¥}©‚½§6şRnÄàu)/ú 3è]°Šs<ñÍ¥{Ò)µ-clº•²Ã±Ààğ;êÚ×$™Öc€(’Ùè½$0>ÇRÎ€ê~)Jƒ˜Hƒdt?/0&tÛÛ½qµ»]ë¬È”Wƒ]kpe‡É±6èyî¬´LĞdİánaº˜Şşƒ­ôµ}µŞc1â lß]ô¨å25Poï*mSWPP_×·¾ĞÜŒ]6)™KĞL•f8±Õ“¿bÜTöÑİ®Œ)X–äŞÆÆQÅÌ$ÙóÄ/';L’"£V7ÇÆwÈ9İ*“qIÅ?Ç¨0¦×úM_‘IHë6‹qI'F’½Ê3X+	‘…¹èÏ²‹ õ€õPß\dFÌ{Ub"êòö•¡ªE;é«#)ĞfbIË­`¬2!2x?IwÚ£âœOî»Ô(¾Æ¦§Ñçl(æõ‘[Jpj•rJÌôG¸OÉ_ZÓœN2#İ3I®@İ£ n¢Q¯YËğ;1rÙ{î è¤´t…š­Š©’ÖIgÏ±|§Mö|C;S‡ôò>wæ€±–‚;Œ­˜ku?Öe>_ƒ]•ğXúÌÂÚcÍ?’¤ğ|G‹I8}(eG¯\,#£®PÜ­Êú6‹e-è&¸/Ív›f»{(øe”;Y4âÖ"±£œF)¯ÊªÒJ+ÃîÖeë ¯¯ã:sÑ›·İk´™é jõ¦Az3×`oºN+ÀË}ğlz·ô‰+ğ«8Z[ƒŞãŸÑ×(9ã]àIÔÂÈ|êƒZÿå ¸°}XBíié‚–Ä5,ÔsQÎÁ]Õ6ˆ‡Røl¥^Êßfy'ÉuŞÉ>$Æ“hŒsòÖ7“şuô	£é; ÊœiÍIŒ¶×¸€UdÂGu§ö Q$5ë©lCH®Ù1ïg=ã³\;‡@,Ä˜|1
’MErs±2ÊK®E]¾—ö—WUÒ>™ÁF–¨¶è¨Rëaº"0¶ƒ‰Š‹!Ùs	^pRo=˜£4÷!W *Ç)cë…¾ª£*şCØıW™'¶,-çğn¡ÒŠ•$¥s9Ø
êKpÃÒgYS?NtÉse=şéºIp'üÂµ7Á\%`Bõw¿ÀÑ©z	êvQJI`Y‘´\EVó5“ğegûÎ#›×Õ¼Û‰®É8Ì7İ‰Ç8ÃiÈåX›eÖÆ‹tÊï0&=QÔÉ9^Ï‚‚ÍúÁ$Ñ:sÁ5\ŸWÙœ/®#Ì¡i–2K¿23Kßõ£‹şj§&¤¸ª •3­§[Ìˆ4tLnÑéB(gBƒNú™¾Zg"ZIOà±_kœsV”QCñ¤»ˆcÔš6¸»…<FfNĞ6C8‘m^øË—çµóÜáä(ÚŞà»?FÊ6İFÅ{pÊyœÑÀ·_Êño°µz‹wê‚ônñƒ¾-±D¤÷Ä«7+U`uº³†axVÖ&(ÑAtoÀY4M"±Ì³´+ÄÇÙïs'Vì/!orpEˆr—¨}‹¨+ã`‡À‘)†6¤œç*`9ÖÇ©Šñ:ÍÅ¥õÖ&ˆ˜ŸŒ¾óÏc%-»vû’È›Ÿ!ø‡©ûÅ¾ú¼2Ú¨ #Ó™KO^Óõ´]SDÁa¨¦ŠI¯~?š{äÎô’ïÇ¸G‹b_Í·•6oÚçõæ rœ/õ éKÇ)ø¨ÿëòÃ¿â÷²{èÂÖ!@†ØK½,&²¸Hï&Ä5àYfƒ Å¶qŠ&dşs:ëÚùñÍ73l93Û¥‚),à¡ßvC¥¹ë³ÙX¹“z$‡”MÉ÷»$œa¢y_¡¶d©œ?"ÁûJh Õ!Ú›—†û÷«@ÓA¦¯´¾”ùú»âYN&½å2ú¹ ì®Õ°º†‚PÚ†mLº¨ÌÊ¦È1(ïg²aËÊgD+0½¡éSwŞ'/ú-bŠbäâE T5ĞV"²øãñ¿nyò‡»lbZÄÉPô1_q¤ÿ±¼Ğe0±¥×5hFšK´ı5;5úê9$à, ‰½xrG?
åäx¨¨ß@ÿµ5\™.¤)¶æã‘É®0<<uÀ?€i‹=2(lIYî¥q9Í¬RÉ!ÄQêÿä¶·ÿ.E¥^®{ÍB=/d‰³&K:Ò]Ÿˆ
à—ÅÕ(c¸Ô1UO­ü;»ù6"ı ó]!zëg®º!½·JYawÍvë«‚çø^Î…:Y“Q­œ™{	HÅ~ªfn]à¥{Ã¤i§‰°'°Mwd?K)¬Çàœã•‡4|ÃùmÊl£ß«—Â¦Aà$K	ˆjl_Y³énjÁ¬Ìì9İ"Áo{£é5°ğeĞğÌkÕX¾÷„—tõâ*©Nº·/1İzU*‡~xÌÙğŒ¯z®­Ğ¿u‹ìßI¯$õ'‚àÈø<W!CÏiø’‚JmkÆQa<Ë¦CUMUôŒWÀ-HKßË6¬V“"ÀvÛù¿K¯#‘6£up¡¡¢#ĞĞî@ÆuEùÂŒäE
àE-jğâ} Ğ”*ÿ¼³}Ylp€Ñ„5Ğı
¥÷¤(°ıëLDY¾’¯Z«PšÛ=ÔWƒ³hI¨ÿ~;á”:?à÷ ä`V†Ö‚óúßDél’â©¢ª¾áCÌ)É}7UüNûëlúA;—³ÿÊXİ°k	(ç5zXKôäÌ¬Šs§Idş+OZT@EğÙT ña«YãcAğ¡‡_<œ»ëH
k©†EP'seåØ8¿7GªÊ°Éš5(l–O›-{r+ïÍK-º‘Ò¶+ehD“€_+¡ºcLö_Ó6£ûŞÄ}áÏ¹ÑQYÌ%{b/ëÁ£¦M>—ŸF,˜IBÆŞ¾·Ç·Èº ÌRçÊÔ“•‡¹¢'/3&µèşv,m¯e¤A‚°S·Ö,«Ûb;QcÎz¯ÒŒ%àuC4»şD¡›!Û9ZnÉg h‡÷£×Òş#›É^xŠş<Ö—ú±Ö)w#NõØœ1ÁWEŞ(i˜Ú•‡©46`»òèÔ¹Ó³fùÃ˜ø‚;·©?À6çL)ìxP…3[@ÛaèàØ¹kÈxëú#hn§à†’Y¼é˜ÁÈJÃ^E.y{Ídó)(LøÇı¹ÒjÊHÕvéuÕ9‚½'¦ˆË+7gİÃË ôö‡Œ½†ù1øŞÑ`»ò+vJ'E£İ•_‘k+ÜÍTÀá Ò•òÔ¤w³ºw*¦%;°ÆãŞ	·P5q«9Tò}å)2nÅmÇšw¨šÉ’Õ‚© å›*˜H¸Õ·ßÀÔ	Ns  ?ŒØî¾VÎ·ü0TyÓíÃ¹U‘ğuM]ØÔÙ—?Í—£í¬LíÈNïìÃšùz}¨ØÉi W’‚ŞD…kæF/áÃôù™=£Ò$]GMmÒIö%º1›
«Ú¹D`â¨HfwnøˆüÒ…ËV‹”¹k-Ä¼ Øˆ±sNƒkPÍVÜ'i2c,g8ğ¿"å5ó-6æ³pSÀVàûs€‡½7(ó%u¥AÙ’`¢^›ç7å K~C©ãeİ¶€Uâj(|‰M¸Ì¹Kµ ÍJª6MJbéQ¨™Şûš
÷GË!î«R)¨ƒ3åôu–oƒ©t°çÍGÈŠîÀ?Z4˜¡ÌDş-µ6=éãçI6T!Üt§câ¼ö÷Ë.‰BáB?~œ
İXi‚°-§¯ut|ãXx¸ÎüŠË­ËìëIK¾"B¦4Œf½;(´øUÆQIE£«zÈÜÉA›[€ÃãÌÏ~c1ğ'Ğ_ö¶~t‹ÔâËÃ«GòSÆñŸ”[ê¨xq™<…åRĞ@u)QáÆ|Kª…<õ‘ÔMÙäO÷ÄÙ·BĞÁF%yÂÎ(¼
!YRš“¦NÒ»<ç‰¨Lƒ}N™È0ŠyŸÊªÆe¼j^_¸À\à>ÉG¬_`]íRæ7ˆüVEŸœ&~¼™2…:H†?®l«ŸCIÙL
”ÚüÑG¹+K4n²&`ñÍXZñB,›à&’ÍUIÈ%ë›Óã<ááÆşÔL¤É'®oğØÂ»…,S,JÕ	ùZ$o¡ ˆ¦€\ŒY’26ˆsÑ"p694h“’P·¶Jgó»-}åN]Ó,d$	KãíNÀ±¨º’l„X“Á:§KF‘E¹øŠU8ğ^¥3Il4Ö¥´»™#+"=¿´¬`TûÆIxHÀ	ç¯ÅzÃ$á‡"/ê!ĞÆn!ÆØSŸßkß@n4Ï‚FÕmËS˜×Zw÷|Í¹/M@Ğa¨Ê£oo©5p”‹qp®*ôi<‘hN‘ì>ù$:b–ƒ	/êel±èBà¼Côôİ°Tƒö ³ê  gÇ®2½QèšR”.N#IG‡œ!yæ¸­ÃéòecßßŠŞ4Ha]‰EØAòmœÉ–´b, Lõ…=‰=à‘c–ü³“)f¿Ò+ÁùçÎ‘qusß˜§˜;èXƒAH}–ÄY—9¼;ŞòNğáİÏZYrŸzNâN%wò•Ş@j2Ùs…î¤„Cª¸N@X17OÄzmÁX¨ë¤±eè%.,[ÖÚ-‰àîß1n@ßT Ê7?Õ£wÑ¿í^WíûfÛæ`É Z91y±:·=ÉF•ŞjCqsHÎ—     ÜV_Ìõ¦ˆ ±œ€ %»Ø±Ägû    YZ