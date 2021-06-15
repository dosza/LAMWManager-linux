#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3725119383"
MD5="078422cf0eb81578fe3fc00f4b0c3bd2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22272"
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
	echo Date of packaging: Mon Jun 14 22:58:31 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿVÀ] ¼}•À1Dd]‡Á›PætİDñrHdÇ‘¹åfWßVQ¹`T-)xjRıNiZ˜¦Õ‘ß_/±!bxªŠ{2ëïæQì88S´òÂw»ÖL…ôõm WšóCz%ÑA¹ÈÛñò·LİùôñO·Hß"Í‘â3‡ïÀ±'Ën©. J§´€,Õ,9ÿüöã1Nów=a¶¶Ş®ØÊøêänœ”[a1HğL›òfO«3f¹ƒ‘Š²ÊË°j„U5ëë]VIˆYÓZ —ó5…°/­´‘Ñfë¿—_ªÆÛ4è)>4gv´gP²Gè'ÛğBß ™»åiÉzP:÷)é!ƒõİtËosY¬É©¢¹QV%˜[³wù
øG2²˜[¡·×*ÀX;îÎxzı4ñ–"$ÖŞšı=	kHHª}mmJ¦ ¦YS·"XŞÑñ(z¯ÄíİÀšqQÖ¼J÷Ò]Ôé ¬” 
¶;3m‹Z†Ï'¹!V%1]%jÔ´½÷Â‘ˆ-òÒü,;ÄR³©Ò¡F	kf-'¦3Go»ƒO19$èNŒúWÊ(p¹|¿“7:®`ÏB*±»ÁDOL`—wwt®«Šİéo7µˆRH©8rIæ´Bª
¶­GV'@Èo¯TÔ¹›‡|ˆ±İo+#n+~Â§²n„¶ûŞìÏ/¯—‹àI½­W¬r0x¡É-)U/Ö
³XF L=¥uYÎ /¦íºç1å@.‘Ù¢kŞ’Á—˜¡‡XBG5›H¼NO–Ô»¬v|ÕÆÒ•³¿†ş^¯ùˆ°[¾{1ä[Ì(Ó
ë\Õm·01åŞÛ<ñË¨Ø¸²a)"0 UœN;9p=JÂu¿‹„*‘"¦P¶/ë¸é&Ÿ,—óİˆ?±-ş:èª„qô›é¸ı¸SÛ	¨r@s
÷tï“–]«q_¯0¯‘ÜÉ.W3Ô´©{ş>1é”æÍ£{ÿAxÔµÔ%?ãôvğ½|f–íôK‘ÛMÇ<¢ŞARúvr…n!byûÑóÿAÃ'-ğÆñtJ5G·½` Ïh›rNHGA_æï)z¬®´üM>ÊÜn¨n®ÿû7M6CAş—xmq%XxßøÈ7¥å,±!´ÕúÚgn¾LÒÀP%Øé%Š1PnÈöyI¥åÁ—;2Õşİºc?F‹6qí	î+S«9ÁËRğYÔüYá%²‚¼ìBe¶9zlÇ9U†ç«§÷€¡®Vic1³ĞŠÒ¯€3	²’K ÖÓ•ôBá”e-´-=Â;IJ/¬>mw1æQÍ~îUƒy½+åÌaÁL£ƒS^A¬P!NÛ8G,ßJ¹(½ûÂô
–lŠ
z9_­,§Æ~­ÿ÷¤ShßÎT/æ”ÑÌ›µˆ>áú˜½şÿ£yŞó ƒ»=|èØğzJä˜û ßÎâÕå‡áÜ”Â’E!E>D¶'ïdÄÄ4°šØşè
0sÁ¤dA%S—*Cøú¥<št#ªûì]‹˜vîG]ûö­ùL4ê]&j¬™ı@0ŞnÑ»Ñ°x
h\çpº#Óò>“”ıì¿XRV0­¡øGé°ş¸ÔäS‡šÓ—ÂãĞœN³mÿ·-vªvİQ˜eÛªf1ºe%9„…¹Eštu°üÇÓµİI¿!à«ô@¬¼ç9¯»M:×»-Wã¸?j±ç©Y>_É]âÚCÀÖ'q¡F˜~:¹áÙ”{xV¼’Òç±ñÓxáAÀDÛæNjûNCşO@DÆ¦¿k7A°ëÔÙìoûûDÎò«î.ésÌşerà!K<%ÈÍBş2‡™sÇb¬)­‹¨®R1x…Vv®—ÚiÊÈ(Î0Î•j_[ûVªŒ†Õ¬øæ“KW)vhT¶ïë»àM.Ó½¶	”Çò«-érrÆúÕÆ\Nï@Ä*%:EMùÓj;ÆZ>ÂR`¬LÇ“5úİ Ì©/w¡¯{#o?Îa’Ü®i¹âö}¤Olºâsı €å™–µÁ†}>ÿO.MoTş5rT|±U‡,ÚéÈÎZô°—1¸ÉX\5:ÿ9«X~\çlnğïë]ËU?Î`­²S…âRµÜf|
ƒiÖ·/^`š(İ‘ıäŞ#¥Øñbvƒe‡cmò4Òè}˜,3ñ„Wü^j%_š’˜Û[¯r½T%ë¨ÊO4Hª![ Nø^Qñ¿ÕÓ	iH#Ô’ÃEA1(Ä~¬=°<[õcÃæ<â
“ñ×Í
pax}  ğ+CªërçÄíŞX½Y½Cè8Ø”ÂÛ¾'Àu][Ÿ„†:7­’pğ\85Û)MtÛPÎNäL…«0w	âŸ¹½»Hwwƒ6¸DE ÑÁš9ÄguÊû›UÄˆÅùšÆhÅx‚Ûêş¾ùı\áT;¹‹âE¼æà8DÔ?å@Ÿ‹x
"·®aëŠq}A/”^4YÑç¥îö_N‹aıeIï•—ÌDÀ…ç8çkÑâ‘`êZp»Uæ¼ª9)r›#ƒ¢â:°Óx1my«ÚåÎdñ„æ>•Ñ-%O¨ı¸o[?Ç— ñ–îG>ÙÓZşĞñáóÉ«Äe\{0nø~ãÿÓgäò©©'D ä¥øöén¢ÛÅ{÷qcÚ0Ü±¹>LÍ ±}Ûn©åÕ°½ğB€~àJl!£æfmpQÅKåœÊDÏšœs)ó¬Ş:$%”(ùĞÿiR~ËnÅFãµöfUÉ%£¤ôMŞGé©t:Õó²d²%!UåIrüeL1—$\´©=0ÛeàúÖ)ÍrÖÜîÁşNÉ \Ûá'ò	òÃãùdŠ ç-ÌÇÛÒ®„úÛ°É]—Ínƒ×e, äšD©	ã›½©è„³Xç:¦¦‹wÆwÓà|j¢^®Äã_¹Şü2ÚR !1	Wß"Ïk»:è½dÿ;ÁåNù3ƒëÏ@§œ¿Tùãa§,c«q’¦
9·¸¾úä8Ÿ ŒDÚKÚgqn­(§ÀU|ñ"ew¨ÚAr†€€FñÂ4ÊŒ–¾P«ëõZZŞ‘Ï}–€’ëÉÂÀÁà(4¡¸üŠñÀ]:ÿô–\áøaöQÚ7|×*tÒ8!·¨‘{SùzÃM
P»iŠ Y`.ymA7+é&ƒ"fÇ\cN ı'Š¼Îò™Ó"ë÷$í©£gâÂø×E2½BAéÄ_|å—ƒ6ê«ı§\MJ#=ì5¥á’ıàÉ[²m¬ÎÒÈ*Şà“gñ•fHAúB]‰ºñ…s«08â/ÀçRŠD¬ï_ok?ÅÛ€CŒsáËct)È,M¡µg'<@_k—Q¢è£™y<"n®,à»UQy@ávzRCæÓµ…¿Ša†9…%ùô°¼³êÎ“Ûâ‹ˆ	Ş*ûØW5Ü÷ä[K!SíAú)sr "td¥Ö«áú8ÈUökŠ524K¡é>¹Ø(òFŒÖƒ0©ÒÂº)QQ_õ	äøñ¾ùÖ‚D?±êÅ¼Ñ©DŠí»W\œæK-Hâ)*¬ecc„îXŸRIş}?uŒ ]â³:'{8ÂKÂñÏÀÎ;«ëh„¤³„Ø’N‡m75ß…€‰ÑÍ	6›ôeo®jJg…I]Å
.º&x…Bí6BL<d 	¹Ä:oìáâşª²álì00(±q1Éb„Ç¯Ş—ô`#R¦
CÃØßtÉ3í,²†¡ô»•]ŒcTš%?·Í<
êSRæ’InŠüvr}àLß%,¸“º`òºKìaVç°¼ŸB+Â‰0D†¥^†õ´÷w[tDÕğúõ›ŠjAã—r7rbDJ /8ªÍ¦]ÚfoğÎ
&‚ U«Ò‹³æw;ë07y~òwºÙM- 5l;‘6ñŸíl…"ÃÍËàä0J1ßÎ Š 2#™	QÔ³í?Ÿ¨1ë¯”Á¨Ãï'!¹|ÚÄ¦ Q]ñ=x!E/G¦-ë(9İùbÂl&•÷f%¼¬=çvcNk°?z«V–7ÏKC&i_ éãË´ğÅñ; íE@(ğî-é}Ü&¾-¥ŸÙÈ3‡'u a•ëÜíÿF«½Çi,õŸºhÌ}<\ŸD‡B¯Çô6mgaC¡á1¢9Kcƒ¸öÒ¬ÒíßQ(P“m®ˆ™¸”µ[qÙcwÏD	äIBëİ[/ª<ÖrçVı¯<ÊXé®}œÁ4aHz+E’u&¨§˜¹*T{°²¬Ug%¤ZËT-pMñÍº„Ií6éh¾SHªx¥š\È•ÌCî'5ü¤>"–~ÀûH–Öç/·1Á•[³Aé$¦¿•±6v¿ß#•ÇÔ¯Ô]FLıÔOhæí+ïŠÀgPZF|ñÆš…"}á«;S_ƒLm-¥Âdøël{xä7|u*í[Z¨Ì¡ëiÆyËÃßU”;œÈ@´?»ÎkÃ¿Õ—ûÑæ.ıÛÂıdöªûLdà®ïË'ŠøÓ+Æ™¤;ù¯†+ûN
ÛùI;œcÃ9Ú¡ƒl.73MöÕ%¢[(&ºoÁƒÓü¡–™Dƒ@·–"Ö·†C‚Ë‘‡Š¾F¯Ü)ŠAWÑ|9'CÁ¹’“ÆÄH–ÏèÉG† øè¾D¥Ú	™ß˜­S°[RôS².¤Â4ãHã‚·Xğ%Ô'˜Ù_ ğÎ¸Ó'\…~\¡§6_PB¾¸Úú²"òC§Îùr¨®”¯‰îä°fàĞà0>XzÉt]!Rí61îtMV¡¥ïß7x
j,`ñsÛv—ò¨ën¢'#ÚËÏÍa–ø½{@ÑÁ|„ Y¸~Â•1w­_öP'[Ã8›ñ†mŠ›üBÆ~˜Oã¤ŒË…dşi@o†¤âã46CŠQ¢³~”F˜SVÛH’	®şbboÔ9…ÁÍ°X×· )Ù¹~»ß…ƒ¾İÖ†zó‰UËéî‚LÜÛ_n5è*c/ÕñµI(ó©@Ôw´HdrìGeæ†(Ÿ[à¦ğbHæ7zù<«ıú¯%Â{ïBj¶qÔ¸„³· rçÒl¹
ö¹‹OÆ¹å§œVš"ÌL6Ö*Úò†±¡ôX‘nô×D°;GlÏ¬"¡¬u`3=ÖxÍ’+
IÈyDe;>Ljo|…C¬ù¯üû£P%6ŒHÙ»d!ÊLÆƒ¼É—/ÑtI˜gº€¼ùEyî_»u*ez”ƒç“+ü£ëÓK§ıGc»¤ ÙÄƒH,3H¢š=¤ò)&Üëºõ^ì¬Éß$¿®Xu¨ÇôK½Q¸šLá·sPğmúi•‘é`x*Z“>wùP.xøÜ¸Ÿó»=lh°\Zİ˜ºÃÅÅµÖŸ‚<hd¿‹ê0ü¸”(Õãåi7’”ìĞp”  ABÿh&ĞPR#‘‡[9MÂk-EmV9{5ƒÓ’ÏœkëKKì¡]ª®8§,ÛŠÊÒRÀ¨Û'Æ–7²„™ÍzVëŠÂ!à»¡Î<±`õ™eŒ³OYâñB	÷b'<#Ÿ\ì}Î·`›A,íâÑ!®=OVÙ^á±‡}fjåŠ¨õÀşdO»=¯sšø†Û™%xÄr¿œKõg^A¦ÜlEI=ÅÛô0Ra‡sŸ*N1¡]”]b¸ˆêïC6ï^Ú¥*iò%ÙçkTi™YîÈ®áb{°K¥%ƒ˜EÁ^çcÛÏ·é#N/ˆÛ}ÍöÄuv-psšMÃxª›q>ÌVº3^§£ÔÖ[€Z ‚¨¬‰öÄ¹¢VË½¹3ë¸Nö/qÌ+*ÒSq”²mcó˜üªÎÉ”œÅÿj‘¯ñòñ÷D¾üŠy	G¹“;†¦'¿Ä´W¿GzÓi×õŒl…=n[İ¯g,àëƒà6*®¤Ú+'•'Y„¨ãËÛæx—6š ËäÜóv.³‡å=çü*#]†ŞM¾cÑí×¾6AİH$S€o¤‘™[3ß`·(DèA}´‚ûCŠÖÅÊ÷Ğ\§èÜèp@ÄÈÃİ±P4-–Ş»Œ¡êâ@ ş@f¸
Ë ¾Éz„Ó„ÕWøÚFpó¢µ@ñ£íşiU4çå›i~¥™¢^úC#;1À@á °>@f•® ½Q=”³¿¬UôœTvhõÓ'„±"Xpù%Õ(Û/Ÿ[ØVJâï']kcì<]G'KÃFoRy†ğQÖ]¿çœVú‘‰ ${ŠÂ¸XJ‘
uey³¤ŞùUƒòjdâ6	'‘p>U˜Wœsp¿ÏÇúÁÀ&_WJ÷ËN4ß£ Ñâš6?%ÕÜF6|Â~ŞŠ¡v¸”Œó©Â´eäÜÎò·ÿ‡¥öb‚©öm{S¸êˆd¿›m1ÒÚO¤âzñ“6ÿ¬>^Ë ).§Ó[É±è¯œú	æü†yÚm»¿4nÈ”ÂD´W(Ÿ Œ"¹Ü6è‰•`°ËÄ•½&Û9©Œ1Ù’Û6ü.)[:'îZl,t½ rÏwØ&úñOeªå2ÂÇäO¸2¥İ IÊyv\<ïèÃ`—YğŸË°lƒÆÚt¦Gø«šJ‘Aµx+Ñ Z’‹³{Â©—}«G¶ÇSÿ‡G‚ÃiÁ8tÙËfóß+= ª<h:ãx¬ìÏJkoC=%°!^ªbšCİG‘UU¸ØFk*J VÍç%0Å!ñç°s%FÎØ^
8½8âüWöwXŒõcÀ»>f1YH¢+ëŠ:øäÅZkTŠ¥„Í<DPkËºï¼7ßÔŸ¹«80p‹™Ìö…°£^³pzJ9s¢ÿµ	¶Ú¥ÜÎ ~YGÂÉå=U€½5ºLÇo/‰+H¿¨+Z£›‚ŠP‘ÁÃ3w*úù25*C#µT­Ğ,Ñøi‘Wôı¿ş[VbşŠ35ß1¡XdüK¸?ShH€eêì’Y1sZw—C?ˆ~ybZ­ıŞ¾•×ÿf§t¸o ¸^¶5«ó
lªô+ÆÕKÕÁkWô…ê±-µaêª£DÙê‘¶uhiŸ£Z!Ü‹ìf®Ôgâä
‚cV­S5™S£6µA†[CïÛ0óşo9ñ[·jÑw@]†›Q¤i(´•`+<f†Ü!ó˜	àkÀvÔÄiÕa bOz)ò®á¸´XB Ëà–`¡R’¸_V-a¥G…f«£?€î'QğÕS1	}å£Y§Ğsú³J“½bå¤îìd
Ò…ˆ<ÁNó„¶¨ÇàœĞ‹Å_¦)†B€:µf¿v(±jìÑıävßˆ7%Ã°8Zµ’¨õudá(vî¡¢ö–4=g/ß÷[sLÒ~°»T)û´
fRDµÚŸƒMËØ.2óÁ«
p\IGSÓ†kpÚ]˜)mï‚€ò¶Ş±HšL1>hª`:?)Œ}àZÆ¡¨„Cæ—,rÎs,/°?’IYŸì"‚,›ÊmÚôƒiça®jwÍ÷ì˜Ê]‡FäªÍ!¥{_¡÷IÓ¼ê‡¾1Çb¡ËyI/½Û¢Tôåó(qøªI{j¿ß„»¹˜;ê‰Æd4õğ=[ÔÁ	ßròhPO
˜ñ´à·3Ÿ@ıgÿ#„˜ğFÄi ]0ì—º)?ªxcjˆ3×sx#æ¤ü?œêBÕ.z`$””ö"á¬Y1ç¼-ñÀ•A1É™ÎôõI jò?×£·?@İ$kïš›‹*šÛ6ï2”â“—xãl|ìë‚$5y4S˜ú	ÔNŒ?EDÂG¡œ	æ4ºi)D9ÇiıĞ~*Á¹F½›sÏ³8°NÇç»úøš„‚É6¹	ù³¼B&¥c&)UFCP³6ÙÖRÍXÂT¿Nı^ZİF tB§Ğ.n©ÍàRÇÕÎÏ¾òh­MJxŞ& @Ÿƒ_1dO¤TuZ„qÔÅÄC¹¶©p<œÁ-pÿŞÑƒÌ€ú®H‰”8g,sş(ŒhwMõ$W£¤ Ò¨5@bZtìwCîˆ¿BéXªù R…èß‡ªZ^‹b™d
›‰Ò°8ÜLV;†.
ÑÂ×ÛËĞAÒ@Ï¯øCR	åŒ7YEô•zÍÑ÷)º•Wx†Í†ØŞÿÏìêïâoØW`…¼.òÈsfŠhzkÜÒuìˆõ­8ªN³²ä~!!ÎlN|ã$¢PÂ~Á¦lb'ôhOí‚·µ °0¢x :È†İĞÀ:VP±*˜„‚ƒDåäâŒÖİƒ|AGé/OCß”­X°l|-e1´Rm*ÏS">¦ÿ«±Œ*(ÇÃhşÔt™¡¡”möKú'PÆò¨Ñ«µ6CÛèw/Ä¤•CİK}ÆZ——2A!}ÿ;È“™Š…–9]¢._Ô—ù —XJ'7:K¨çƒ@¼aÔi«›â°õø$‰Ö<æÕmµ5Y™ŒÏqVÚ²”[¾‚Ëá2m’R›ƒ›:…z‹ÿŞAHñÂÊ^^Ú¼¢ eÔà@½ğPå°à0sG7#ÚÇÜB€^«iúé˜%Ò™Çrq¬*§Õ·P¿ì]^¿%úWÊ4„—ÖD“™‚:£ü?QïPäÔáµ+É=QkËL…W…0Rà6¸‡AZèoù<¡é0Qı9§’Q!ƒ¤öG4ˆFªv2}p¢¢¼ôËSšø7?5G!ù/“APQgB—ÍÚn‹ˆ}KÕZ)¢4L÷j“—û–F-VPc
«=xØÁu­‡¤#?.`œİıı‰TtÇ‹È”¤^p|r•ÿçŒAÊsÈC ñ$A‹ËÚ×\¯[4î1{{6¸÷'¯)SÅÁ&°IÑê|µoíÌR¨wk‚IJ¨R6€½Km2w)GÂq€oœOÿ²- o‹§¾ÿ?šysÅi¦ñ=ş×–8²R¯°'X¦KÁO­–˜S}Íœ—_ÏŞ?uÁ -pìâëd¤Ú[ÚãıÊ×³¨'‘²²ñ¬Î¦¼r.`¸+Ãü[™(YB.;pxÓy7Èfí\¡øşÜÁ[ÄüÔä{*N‘ Hë…?ÈÏµÖp­ï˜ñ(Î¤|˜6iá
0çKRFZ¸5˜ägÿ¯>›{©ßê +Ç§ÈÓEòôï…|2z£h únÄó#×‘¬‹¯w‡' ”#}¹ğ…Û»_®dè^S]ú3œ©Ò¥dN ——~›ÁRöSÎ3ÍÒ5ÙXX‚˜úÜ|ÓÔ;C²{iã<»Wøe:¸:Í—	1<à'ãç"¶™§Š›Š€q*¤”U¸âAëäk÷> +×ÑT·Ã<pÑ“c §Yİ\TØ¾!î¤pd«+æA#ƒ©ã@üuO^0ÕÉ›¥ÅÊôçÏà¸/tíĞ	ú
{†ƒl “ÕœÔäÙ|isv >üwQÂ7¨oËj›£ÎµD–‰d£^¿­‹)äò€â·(_Z(š.Æó|Cp@¢›aT™ÿßOeàÊşÑ†)(]mÌ°ÖhS~Œ¹¿Ç@›lt&&fkzàWˆø€¸È.SO©×ZÎ‰îK,S·òÖÖà‡ıf¿Šf²¬%jšˆ2°‡ŸŒY~ı¹S[ñŞµ‹d‡mĞ’Hn$u˜Æ4w¸ğ'ÿ=†ş)Nù¥—Ò€"È¬”8º3ú˜{d)?­²j-uŠ)Høø<s›­å–»xâÁ•­ z¸£{ã$jÏ–Y¸;Ä9R¢€Å9.È_»â:C4îMòŠ™Õ7ıv?t¼ê—í|è†L\š3ò±öÁjxwY˜½¦}.Ñ¨QÊœ¬×UAŞnÍôL8Ê@İ„²}ÎaO¥ˆ®ëH^.0|-— .b¥çÄZG´e±“]†2ÕÉ©­r¼*9†u£õ_f{ò=ŠUˆ•¤n‘ †–ˆÉ*ğû‚ÓJŠiGmÆ
`²Ü‡C!5ô=öÕ—/‘ò~|)_kã
Üñ²öûLÛ$Ò•P$zªÌ#á#tuzÕ´_Ãôm=ì Ïzhp{/¾î¹kñR.ÌSKw›¢k6®6¸ãbÊ3 ×'ÇSı@+±«+—•z (4t»ˆDi…ïãë”Í€~…‚½¹íR–oaÌ#Œxû«ck›àû§½K^cÍ÷û£„kd‡øaËa›—@%Àø‹†‡—´#˜¡”¦şùğZâÿÕ`'‡ì7ñ¯•×qş%Ôö_Äcïá‰¨5úpå1Æ/·öÔ»Rx›qqHòáÌSğÂ‰.TëæúIíïeC‰7ùR—İ…=±M›RşâŸëZéÍ¯Ã[úìĞeÂÛƒÃÉ‰Ó’fëf‘€†¹~¨Ô#µà¼¿4½³~ğ+¤wcŠÙjx¢é}zœòÏDtÑQdÚâÍ-‰{I­¬q_b3”ÜÙ^«c(zÖÌ;ˆn§§¯é*#<'Q$o`J £ªÑU(Dîà\X+Ãq©p_\‰Î»•Ñ–™µ™‚×ëiÜ=.’«“Éæ„ÁÆ“—Öå,UœªsœºÃaıXP¥ŒùîÀ`}ö¥l¼k\ñS~QC3­ˆMĞ­ûİ¼v}O®mT¯¼+ë÷¸pŞOVk¬Yù#îèšIV-•Íè÷ƒl2%ï"m@2‘‚.ˆÃ´“Œ2äçd'a‚ä²I3´hAŠn§ª7nÛgyó‰—ş¶#Û3Ô¸;ŸT5okS¾Ä®]îÔ¯’ä ¼‹oŒºÁiü/ fà„*õšõ-‚"Â«))Ã<ø‚n2ŠØ<ÂµŠ/[å…ıªe¿IĞ4ëµ‚­7ŒıòL¯ƒĞ%ªÃAÀcÒı8ÍôÜ*²s¼d¶Ægo	ÁmY/ÀQ½d&2gvÿª°pµ€¸Š¬èDhVà5ÍB÷OéÍPÅ÷‹±<o	&xÃıw'-dƒŸÍÈÂiZ>†*2ÈW9˜v0-"¾?1M‡4!`S)9WopZÄÆòrİ{ÍÎ³øòİ¥H‡¾™Êˆ?[¡J…=}äR"Ş©åw€v¢oÃÒ’1x—?öÔöœëø‰‚õÄ¶c^KV\pKÀœçBM¸fí€²â"A]›U¦­V’1]i]
ŸòêøõG8²6b ¾)±OVˆXJrU!JåJóø@¥2Ù@*¢•íbÆï>`³W¨¹Ç,z­¹®ÓIkÓíIö×ÄF¿\¾3µfô°áà„­ŠSfQ	¨8ısüáÚºOlV¯ap,£8Â‚@¹£É°mK©!VN—ÊÖáWĞÓuçäã1Í¯SH†S7ùíĞ"Ö!Ñ7YŸŞ’mL–hà€OIz÷ÌM¤ ¯@N'y¢ë9Œ_¶)wlõ²¦É"û@„¥	9+ï­Ó¯O«^Í½ÏÏM>İØÖÁĞÕµÂ å‚°º7åûT·‚:*IŸvÂÃ³'7³¥t#8 À‘¬@ó†}ìæ,µã N”îíô.VJv§Î$ğÒ `D5ı#%XÓ•N¨çMf–Ü5™|äÈ‚g¾Ç™ä5É=uq¿?Æ)õYóI(«S/¯A:í=]‘¥¼û¥ƒÏNùšÅÖ%RECk?C'1Gkë³´¤rht‘˜‘ -toMj±’±y2"‘‚éç=M¤¾¤¨{÷§R×ÜnkõUiÎAõZ\&Wie7‡ÑHÁYªœ¶ÏßÌn-rì¯M8<ÀqA–¼ãT¾²H`ú2Ä~:¦´OçZ=åÚæµÚœiK¹¬S`ê‰uœÀ.\âs¸ÖâÁz®†Âr¿Úş§_¦/ZöíÄ>Ù‰$qjYô²M¹ÍĞLÊ]LÜŠ©S)‹ˆáËPîxzCfY6XOB·Ç7 ´r™Á¼~€dK¤—‰z™—ËAÉÊy–fÿÌR°oÜú!eõ$².:ÄÓ“°ÂjªÔ4vCÔäUëo¸àqtqS^S³‹¯N§ Ğ|·îòY¾ß¯(ÁBkòRWiÁïéAÃ}³óx7s»€.uF²ÅŞÍ`÷Üª›‘Ã¯æÌ”ˆOeÿÌûƒp:BûiÜ)ÉFÜ_CGÿ\SÇÔè’h¼fDnÁ>º˜Àv1iWÏ)–Ğ2şk‰`$âe	¸É:maÄc!MV‚ı³l2Ô?ÉD-mÂæÉ„”ËC”IÂ£q²	]õ÷&—ö’ˆ³RoèˆÉ”yÛ…°M±«QŞ€XĞTŞ\çFÉòğD‘cÌy®ëóµ
†toÀ-Ëw¼ŠdİïÌZÉò`¨‡ÑV1†Vk‹¢à[ªı×@,³V#ÈG½°ŞzÃØ@Øk1/ş*hº«y8¤ŠŞ.iáR1”BSÎúY’+ Ó`¿UŠeö“cAúrt_Aaîé‰\Cm„¯â+öU<]Ü&½ª4N@&2ñh“•j	Î†¤›Eëâ¡öŞ¥äºMaµ¹éFÅ‰ “Œ]&ãµğ„-ARt^øŠØ0XÓâáâ|úŠÜÄåë¥¡‡ù ûš˜G{Ö<'Ÿ@–â0>´>bø_lù«m™s…5…”ĞójÃË±âÀ„şL›àå!3²i$li&?*‹ãjô6úVİe/ÖºA	Ù‘‘¼ÀFP›l9ÈÅ}½w$½	æ(Êå#oÛa0’hR¥ FDF3<ñ—D:üC¼IÊ>Ñåà¶\AJÂ|“ôàŞì]{BKT®5mIM6ÈK6ß8ömôÓ•İ ÙıöÈFLÊ2İù™:ÒüÉi@šÌ¢}õ?5d)QìËœğeÍáªcïµ¬‘=äV¢3%¶;»¿üí9¨è=´}LR¤şP[Œ×Kµ^—ŒKÖ"Vz?‘şñ•Æ>Ç­Nf·e`Ì½£Ò·’Ÿê.9o'Ö•Ökdr±3ãÄ~ş^Õ·íâ_Û|99f‹ƒå­Mh­\=¿j±ù+ÌW¼7mM¼·êm6ŒÃ]Ëf" ©J`VåÇÛ9İGR®ù¶šÜGH­Ö=C„£Ó5éÛj¥DQø™cml ?
aù€ˆEÈ\;úµ7NúKÛûfwŒÖã	×ˆè6vÖFzc§æ
¨t_,Ş4*õ¶Û
8¡ü©Œ·|ˆ¡M¿õ)‰ÈJS¡:ÚPİk* ysúÕ†®¸Ñ0ÕV…CKêz[Ï¼Ìø	î‰ °ÙÊıh:r¼!î}u÷²E[Ş‹ÚL£jmzGûÏH¶¹úÅ·ò şŞÿÚWœapYdÏ©cc¯Ş\Õ2õ@şç¤uFrÆG•²ÔÓıüÔŞé§›‚"-‘ù¨éÌ¢ş~¨ÈV>7÷iÃ	êîåRNxÊê†ÈLëN’¾)ígÙëƒGV ¶sò;-¶¤õ5kT:%fœúÚ­ğ×‚KsİÓšU-­]—¨]ÒóT9×úLn`oçes[—M‡1kú¢Ó0Häõ™TÉ´ò”jŞĞB$ ¬®i˜Õ:zâ:jˆ“o ÁJ…6ÅÜÆ»¨çê`ü?FÀÉ#ı%zL±ù}÷ï®òÏv›-!1·ûæ…g£,[êŠÉj£r)um•wÜÕ6šç05˜j†ì,	Mÿj¹e6ÌcØ)¿?§{=ÃD‡K¹÷V»Ç]F÷¦:½å5”ğã’BÈ~Yğ³ÒÍÖó-I¯Ò0ÿmÇÏ¯²É£•iªÍŸegtQXJRøÛÜ*7ïşiƒŠ¶øĞ–ÏÜ0;Zã“0÷É rúµ’kgP6t½|wó›p	|ÉŸRŸx;ü„gòn- ü \Lôréú¶Ìå\¯÷sQÍ5;™6×êtÂHˆŒ»$ñ£øæø°‘ŒÚ»DHõkvÕ$1wbûXPİŸòm¤¦<Z»áÌ¡½¾¯•òC#ÀŠ²\»Á“QÔøåÿ’ Küü}{ı.%5ûTİÑ´(3L:áÌ”Ò Ö©Ş~
öÓ&åF)/ğ-s”ØE~Làoå?ëÅ>kx±™+L£?6Üy=Gâ-|ùÌğ[ĞÇz¿"àO¹%o2á™ .ĞíW½Šu•ÉR^IXŒ¯ß6üq>û™“À¯Ø–
=ïh~¨dˆà{M¹}Ø¬IñÅË5³BOÒÛænğÖ./^QTÂğ€åX^ Ô…â»²°Óİ{®°pT–Šq2^ü[áÔ‰$\‘2øã¢ï¡`± &áédHdYrYôı´á·'•Şoãª½éG™v gª-{ØgPéFÓFµ^”KGÔ#óAÿ|30‰mñ!‡do+½QFÕV2Tnt*˜ \š ^ÓÛPŒÇrÁhF‘#=<¯´]±gŒª`Gw…›]×=>Ò¬í„½Së³1^ãì}ËæbÇ5©Ó§1±—‡æaQd	RN³òlO†š@Qx’	ñÁM’0ù};÷ÿÅ~Ù¼3ùMá£pQRc¿%Aß0?36»»¸å"…ˆPìZÛÜ_¬ïPGs}GFOêB‡“f9¥ Ÿ`OæÁ‘‹6Â°¥ÉhC
{â{ùÉ$®{iM™á•ï¹È±T~º3h³<x±1Ğpxk…fÛHBIŠ"0GºØ’›À@J#aãù$cídhÁy·|8µ?_Ác|$GO5£Sñ¢˜å˜<]§ò/ùñÏ¼z”ºğp!(†^F¤ceP2ˆÕSŸÅŞÅ¥KÑošœ‡tìNa~]€s‰=t7ã!y§^BÔd¡Ç""æWşyaS@ËÜÈC
Àn	…Æ: B3£«L‰‚}r@ªÍá?-ß¼åÙ²!9ÇCêlñ ÃV	øËës"|½ºÍVÒÏ;0w]-…+¶V‡ÍÿVS£Ó	x7•ÚEÂaH¶B†¥¢êj}Ø^™‘V¡˜ XSü¡£B½*öPSŞ»¾Ğ†<ç«t6éI™ı…µVé1*_Ğd¥›«Y³¡{h@p­á”@ˆì¤²q“Õ«]Ø.‚¤w¶d?SS¸0CÔá±$”ƒZ–Î­ŸÓ!ñ@âjFÁ!p§SïKû€NÌ»ÎŒtâÉTtƒwRoãª<³ˆyŸA®W~ÎÙ!¯ºéF<}ß^g‹:»ÌÔ`úå›Gõ
@A?Ê˜éÖ4í
MáZïUåÆ/şr)ğşzóşD~}w‚é‚\|œfZ?¡æ…@ñJÂU¥DüŒœqk;+™˜M®ˆÓ¨+d§ÑªñqoŠ”“D€-
¡™îÇ/n®Iì4ø[&ôP¬'ô™Í‚ƒ¤0t¡µ	ªË#8ÀaÎ5¢ñÈ1²¯HÁ„µ%M|—#."n¬ª1“¬'ú^EÜ¶îÕîBòÅôÈÄ^ãÚ"´§tàIá+TÄ"ŞxÂisí1d#60¾"2gáu§îå[n§·	Yt%¸qÍÏSÁåc … í~3»¢~ÌfëË¸×‹ÁFô«‚wİÉğ>$Kÿà'“º¡
¤ 
y+	BKzË„³¨àùDø.=RRuMÌj%°.N6éÛR‘ÑPC}@|¯¹’Ÿ³r-§€ó‘ÃŞO¤ò'«d³8TLJBÜFy[²íÎ¨ö0Ş~Æ5&RHé;•·æ-MâßZ™'pÄş[m/Û÷ğö4-%gGÙ«Üı‚´E6ê„õóât ¦u*I¶Fª`Xı¶çHè $1@@Ÿ¨›úô”VÀ9Q‡&?²MÄ¥_Š8‰“¨m0ş±;É-ò>}I0àú=(\˜RÿHà³¦6zÖÅ=ŒZï™hä¬&T›<àA¥Şq*†ğBqHˆû»tù;*ÆTíS{>¨ k¹%>»7ykŠwqkcŞ0»ªğÈÖd+¸¦3ô{Û™cµ$+}¦¡ë°Ã¶”RğoÏJ o
ØbÙòÌ§$z‘}¦#ö,ì+Y5½ìŸ¼?v¡xÄ†
)˜ÜÃW«_ªiÑø—¼b9ßáæôÊµŸèğàãUëº«Ê‚„#ì €w.{Fí‚I³]Wq`Õ¥ÎY€â&PHPÎF¦KĞëAÔÛcâµ­ï1råı¦¤Ãx;Ã»b%hÈÈc‚;[|™ÌßiÚl¸P8‰üÉd™ËT¼u¤~üQ÷ŸâX
dšÈ“&H×S	Ë_×Ò4EvüåàÔ;§Ü35¤oR®8UVEãwCÆsˆ!	!!ÅsÅq{/JIîÕx¼¼Ìn©´(|*'vˆçhµÅ›©ÛU´’I“KãnÂP”+&iÊÜ|sÏA}š¾{«1ü`MX¤û=Š<¢<ƒ±JÑUwl]Ò¶;»,_Rjàj>?|bŠe—{$‹ÇåÁkz§eÅ´Šß£»Èµ¬&[;´ª7±îb²@gjnJN.©ÿ4ÿ]{&Wsâ¿ÿ©êg¹!Î¶ÆØ'«_hn*ü!UåÑîÒxj¬`VÏç÷b|ÄT¢oËêÆh	„V»"9í3ÖW¡áf+½±/ ãØ«ÄĞ´£0Î²L­ö7°m+Åì=Ûœ
J k/‹QC[0¬õxb–0îLÉ·°¿äÍ©t†k[«ÿg¤ÅUUu¢_›,<‹çšêî\jc¡š´|·ƒJÆ æIËØ}Æd´‹‰W=Êİwê<@e¼ÅlÊ¢üìèè¼©½Â«“ê®À–É/&/ÊÊÍy™ıåÚè	ñ
fuoqˆ¨®^r'6ş–œ'«Áÿ*A#QOœÕŞ€¥g°m¨O>4+÷ %ı}C:ÉØõ§ûsŠ÷ğTváK9NAK.ëU€¼¼"`õ•oZd îjÕyMŸD~¨ätŸ¾ÕrQ;OiÕë£—{›ûÈ òùÅX³h¼œ´$lËìÏgP‘_ŒÆ¡FaàÉb?¯µÂQ±Ğf'A2H1ÁÎP$ujcˆ¡<_­ÁB—jÔI$Çk:‘5
v9åî¥¬:öÊGgŸÂ?srj$™shà3ÃÓ{kË·Øµ’uÃA®8uô*ê´fÿgŸJòÍmË—U¸zÙ¤\£îVhÇ÷lÒ`„Ğ”Á/pÃ´n‰’·!IwyÛpÉmåhxK¥ÌLı¬ñ®‰6à“÷ÌåpÂ¶£Îh8ª.C»\šcîGÌé0´cx  ,@p]Öş?LË*¦z…o¸‚íÂÉ9x¾g¯¿J äzİK?‰ˆnàˆÁŒ)%†–¡×õùßêS°z§S½\QkĞEK3&ÆváÙ#.-÷­ÊÃ=ãº0Ö§¼¯#£K//TéÁ\êBäL,k›ò¾5F1Ñ]wÏ®²A¸x’§&?ö˜‰f•GÍÉ;µqÏA8»@S5]Ô2l)ÒrÏYé€Æ'*=*c1
	Óë€Eî‚€ªÕH.»óŸ‹m«Ã!³®„vTa‘‰ıó&’À±œDÂCeÆCÛ“U/O©ñ‹„*&óµ XÆœÏöÒ©9Â§¹gQ™$më–[zø9A¹Q2·–5¸íx‹:p­ÈÄ,xÌüû§‘òéîüH¤ù'J¡nıºq™	«‹«Aí—è¿{nöVŒ9?†|U0E2[‚1‰¤È˜{#ö¬xµcËº3åí»e“àD˜o›#fşß­DËe.2ö¯W„6ÄaÀjCÇî#(P^bôæúÁáû×37€ŞzĞ²œ@ØO'¼)Uw¿2”¸æoTí÷ÌQjW^U? eYg(ªV˜x]˜İ0-í·	iÎób 2gÉ@ÂRÕ°¦â½-ƒòå½sR€XC“Í êK¶ÖÖU}>E"/éÂ•Ì²Àœfi;P‚Öç:‰$v¼X:™{“*hútÖGÓ<®làc¿UÑ¼3M+¬ÊhšÃ²³ÀØœ­B€ã;™<’¯€¢^Ğ›p¶ñŞæTêr~øßîÊÎ!ÒlhOÀ“„çAj%1™c[-‹çÜêà?½·ŞoƒM>·ãŸºm ¹À‡£ëKı‹K„2ğXb”UUP8ò–¸BHå˜‘´ıŞª:fèvUYæåH¯ğp)ĞJ -F)Ë+Ë*p|Hâàb°óf¬ƒg‚\.½wiŞŸSóş±FJKœ*¢Å!¸Ït2µQÚÍ³5·ÙQ<,]‡F'ÚKöm3EÈş[u•]–ø8wÿ£O­NeùáD;rPgêB¯8T¤M" _ü¹íD¸#‹kÇ/ÿMĞú&Æ}¼ïŒÑ5İO1Ğ¹İU51ãQ¬ønL'Ş/¿æ6íÍäÏïQˆí)h™v8ºƒ^qÛöğuQz"Bb¤)
ÿi¤ÓµK’¸°ü­–ı± 2L+è7Ú_K*“e‡ƒ}”(åÅ£
ê&|0ïÎ®§Ù¿Ïß80±‹ÓGÇ•©¨è£Š6²¶¢ı0™­˜œ
¬ÑÁúìÀAòtähÉfŠ»1ÛİrÏ£™¸¬ø¤ÙcÂ.?%ıh]fQS¤íT¼T‚-:$ÊêóÔF´Û>ypfqNš,şÎêÀ~\¢ä…,^…¶Ã¢ëŞ°ğ¹	Xª2JñÑ•ø*§yRíM¤‹R”íBn	s â)¾4‰¬C2dèÏ?6Á³WXéTä1›Å
a·m¿H¤ÙªöMõIÃ5ïÄ™Ú ÉÓ@çp”6—×½ÑD_ë(üQ€õ¶L£nD[düD<'¢B:! ÔĞ¥uL•²¿8&3¯¶Ø ¶Ö…	^k²p•âÀ†ñğÄ¢\œ¢>ÍZHBFÊ6XšX‹÷<ºë¤Ùo„G~É¹j-xJñ/T‹ÕYÊVñl&¸ßÂ×ˆÏmI2b»NmÍW$æÈ#Æ ĞnÌ~ƒ©K›ú¼CWuå«¹®ìÔGuíÆ­«G[¢&p+œrd³z¦ÁGó+,uXîÚÿJõ%ªdQQwj2ÙW¯£ÖT]§”ò^¬dÌ@»i‘+Pç­‘¸ÑÎ
‚•Ê 3œŠ®•İ@d;h€]	KoÆëhVSdí²µu’¶u\$ºUj¡©g¦C[S¾}U-Üµ«¬±Wí[Åg¯g)˜ZMıÈÏñ.]kÙ•ˆƒ]ç¿²FY÷tğE>»à•ŒÊ£´yTe©”Î9Ä“¥ÁÚ%4¶Ş=?ƒß,Àİ¹í÷ù6ÚúSy«]u-²õ»†wµ-ğİ 9b`¼JşvY…õòåèåLT¾.…NçgQÁYÎéâøĞÒ¹‚fw­V°Í}ÌOğNÌŞ‰Î£@Z	³WNKpõ¾ä3—İ³	®}d£:|.gp€2˜/:DùMîŠ²äÄ·ĞÈÃœ:Zb$§p¥‚Ÿ5áÃO=¤œ.Šÿå*E,‰5 ™Tl`³wc ‘€¿iÿ´bœŞRÔ„èvµ¦õ‘¨+lMÒâ¢²ù›·•áÄ¡àÁ&ß-õ0å.íßØF¸¾X juuÖ¦Q<6Ş›‹ÁÕÙùWFˆS± `Ë2ê|Sçø1ò'f˜”ÚvªY¸²8ß=»{íyTWï’§,öF"€"[™95X%·`¬"{EÙp`m„Gr‡W?AW/ÁfÜnV)Xhoh¹zgW§Ü>èMú
[±£ŸD`ìÓ!û>D¹/rÿÇŸ(¾Ds0V9Íş	{F%ÔèK3[	S%ÃY‰K nVA‰›#{çÆøDfZ÷Zæ•/ÉŞYaë½[;Ú”àïÿZ ï_sÖƒ¿xœ—ª^«}Q·§»8¹û[xÎ 6ßşè¤>2YØô¾E:…Íæ¢´Ù*²€ËG8y—ä ~„@²ÁtXèVßVí¨ÛÁ«ßÙRøÚçë\åå“vØÃá%Ì/ûáóŞ­£¢ı‚"$
|ZIä¹e1½T	In2Ÿ|H/½å2£ŒƒÏhS-ªÚØT¨,i`,™ìxyÔÒœ_&¼Ì2ìòlˆĞ ]uó~±~2AÁkæRÆ€sI¬ “GÕƒº’×–òÛçsÉ7}É±IÇ"çGZxß© {4WŠìÂ9›ÒEŸ'Á"7oØ÷†G|-švxCj^è42Ÿ!8I`A$ï\{ğÓà29õ6ÒÂ
+M§UşìG„lÀ¿vW¢Älÿ`Ì™míî{ô˜›ã;P€ºfò„VB¹*F4İÅ.xº‹Á-Ëä› 8‚Á“°Æ»7®EœîÎ‰T»¨óN‹é¤ù]Ee'ù»ƒü«qot†²”qìõíÒ¢Çihœ¬³R^ sÎı~µgÉzO¢Õk †ëÙv½Ù,ôl²möR/)¬íI6JÇ,TÁ.´$O9×%á¡‹f†ş>×ÃŒD2ââØíôRıÒd|,	¥!ÌÇ²_.ØûHşwEú,Ğü%Û±ˆè¿Ô¥Ò×½Ÿ9YĞGcÁO¥‚tÖG°ÔÁ5şx€6ëôè¯AşaxNï1‚2™ğ#«¹lîåØ9ÁK’k;–¤_xV2A»fòR*Ã¸ÏÏ½ŸÍfsHIUKï+¼ÿƒüÃ}¡ò°bÊ=J!9`Xz¾€…î°T?PÓîÇ¥¢v+j6M™szÙü¨¬i:jö[^Ï”™ğR¸ÓĞ`T(„…ÄI ‰rÕ{ó`&×ÉœIûÀâÃ`ÙZ¶wP%Ä³‘vQ—('€lgbç«dtŠÈ-Ä28ª&N©z.U;o¥]Öïú¸VZ“ø	“Î>K}4zP3ÙâLäEu+ëW‰çÊâŸ/¯ jÀC×cPœ)³R®u2	eª£ Ù’£õ+Í1Ã¸18éòGÚ®¨×@ßÖ½¾€¼n´!;nçx…lÄÏøU°+ èqú!˜—¤@¬äomÿ_ÎZÁÃQ](ÿÖAƒ:şò(òÿ¾%N×Œ'ˆKX†×õPÎ°ôÅ5ïªÚn´L5P<-—Õ?‰\'6ö˜*&?æ¸¥IËÉìÿ•.bº8-¦ÖÇÙ}ãÑr­·óƒ] ìÄä‘SkOšftbG‹ÿšî9iÔšzªs£av–o	˜jÆ>ÁÚ¾î`„¨ê<ñÕÍmpÔ éóšÔA!JÖ•ÃJÏ!¸ÎU”1êıû,ğ–pÔ&Ü$3wª³%|£Ì¥q|Ss×ua„”rŒàsÍÙ”I†ş$ zU0u¨œªòG8¢ByŸçõíÚÆê5ˆnËÑÎ '‰ı¶[…Œış2[éÜO˜šëck^%eÒ"=é¿’IßÓÀşˆ™zN‡N÷ÓÁÑ ¾Bu×õã$Ÿó€q³Şl•Y€5ø^¸U‚ì^‡È°0£¯zï×d-¨}ô‡ò­¥¦hözó‚ mûÉ«ãgÓ–r½'VÉŸH¨Wåo?¯¤nr°É¥„˜*¢5\´9n£½Ù?IQ&*Æö‘²–°ïw²;*MşŒ°8‡…pØ ÃVOÈn×‡o·¨¹IWkÂ,Ò‰ÍÄuàm¼x
pè?€
ìºô\¹‘NV³=mPÅMO )sjİã\Õ*ŒğÕ…C“N	E9Øb‹•¸3ÅÚ|[•?72ÂÛ8» ;/àÚaMÒW,qq“5z–W+I„rÔAäŸ_4;
»§í×)n˜6øÿ“Ks‡8ÆCÈVgcá«İf›L6»ƒFƒ2eè€¯>uvYÚ®°©Ü8Ù	_†ôšj®ğ0ß„6I„ŒåjÛÅ~\ŸƒmçÁ“E…‰«¸5é±ÿ-ğ,úÌ©˜Á A…Náç7¾½×iŸŸó ¾9zŸè|so+Å·¹¸‡ªù‚,˜À¹ÕJÊš»øS> bû'~n\pd3•%	DVÉç÷ÿí°µ!ô‰YÂåZªîò‘û©¸+'«)g/¯@ö"Ë;Ÿm§ÿÖÕ•t‹ûFP0È¸‚$ôFv·Ø¤™R§‹¬å{+ŸKƒ%ÅÿÔÚù#Qüy ”TËÈ[_}`Üß°L1ï$²!-ÿò)_8†g—‹ğJì2şÛtlS²/Ós ®<qPlâ‹Å #ı³FŞÂbD	Ä>ÌL°E‹ÌK(°·…Ù¶eL´ˆ•ã¬c8@;;X.$[VÍ/ÅØ­4–4¡üÎÍ(èG¸¬Jè˜ƒgÉáí­Ô:.£^ÊìF´òò£áÿŒ+èèeİ„SĞ¯7dJıy¶|B®WnïUú®ä;ñòëtØ	Gş0mìèµ¹RVıT8?Şv„<&³n@j‚&;«+h²†H|KÃªÀÑœØƒüuŸp»‚ÂìôSˆÆßÃÏÂ¾M†äê²xleºPüp+Ãññ·Ï:®´¸/œ!íœGÖ†ÎD¬œ£@&ëKvü¸ÈHòùĞÓ¢Ôq¹ä©v•"İj“t-ë”ªn’ã°2İ+çZRgÇ2{9|Û, p£ÃyÁ&Ò¿>%oıHz‰w-).,ø.†CéÊL2bŸPk¬Û€õoés9Î%fªÉ­~˜•Â3B4Ÿd¾UöJáEÓ›UÄúñÂÒ±™I‹ô¥°·iS>ı3ò+QJze¾~ÈşÎãvX‚ÓÊ‡S|–Øş8=x©gÇkAºN+DòÇ¾Ã½áª ÌÍŞEg½ßø<ä;¼»ŞÔGä!Æ ¤`ä‰”U™Ê3ÕÏãµ¹U<Ğ':ó(mä„I—îl¼~ıY,º?8ãê5Şaéá•1¹Œå#—Ì›Hì0ĞÔÇãĞûô¼X€O6Jú%ŒyÚ«?EË‹}®¯ç<÷‚KÚò‡tQvÜ£wŒËT½ºHÔÅ:»9e¶K%îj!i&sÎŒ¡w7kæRÃ¾û²t™œ+ø;@}9¡Àïå‚V¤9HÈëŒø–ğM6]ˆ]im4³óæøí·;Gì+aÖ¸¿ÁóJ§nàE‰s(×Ä%Z’K7±ør…ĞÉÑk‘Vä/à¡x€ÖL{P˜G³på®M¯Jvä 9ÒµY?4xá„Å‡	CL¨åa&àgFmÄ®ÜY_Â±Ú¥·Gäˆ®™@pˆ	©®„K|\D£—ı)r¥[Ò)¯cò¤¿ ØZ±Ì‡s{Ï7XóÖê™nö4•ön#ï•F}äÇš–oOŒÏõ”~"ZñéÌP³†jİü3x£q¼©ctù±v–Fá[ÀÃ›±bw“QCPn 0—Õan%À‘IDQK8¼2,â 9â/4lªñZZÛ5>¥²ÓMòõAˆücÂG’ğnJ­ä•m†76Œ¤Ô€.^ˆ×lŒƒÖ²‚?íR$Á¥ıÑøÔZË‚R0jşĞ"SñCB
rívúá-^\¿M(Ò`4EîªFÔ7 ‡ÈÖÖ Uÿ³Û˜éıÛú-É]]e{ã «Jô‚X/Ê	D#ÜA(?}Ï´Î‹\ó©äÜ² \ëzÔÍKÀ0|6òo+t«V	F–İ“(y©¦×údïïŞ&´:ş Ø/+r¤ÆJZèùD:¼=`¡œ3Ş[l¾3`ìJc™¬FaÏPÌ´ë„–)â\<ÍxY€c+" ø”–ÒåÎŠàŞ0oºëâ%E8¥"º2_)+h¶¬¡Ü
Š‡rçy¹mªšGg&„ÀáfPºúŸôdxSI’)„«4špı~|' øÎ.œà@Ì®fÛs¶µİæ_«ã)òG‡P¨$Øâ*ÜE×8?=ÏVŒ‡[=B—"®ş>”Ë§`ŞÈktJ¤w–Â®;ãœA™€PLsÆ“ıL•z¯VXZĞ”İ%àjPôE²)œì‘<^„êğ5f×|Ïl*+[Ø‡çáô·Ñ;K.Z£/Å™­ìù-ÊVÈñâÒå’Í½4s€kî:¡}KvîÚN£j6^…Ò/ä{şßd¡ êÆ\dş²»+G!Ë=Yñ@Ÿån0ZEzˆÿK\µ“­ Ks6o¢ú9€|4ìªa:]€NjBíêÊëïUµ"MÖ±óçèÂ¾ {2ïOl(‚e³øuZ­şvåb7´ÜªLIFğóƒô¢Ùˆg-«!*åI÷æœñ\>òk>Wƒúv	éLe'¸7ì†öAê.Í£¾ø5„ĞdmA|\qBh şv©h5ëöÖ0B¬uÁ:ÌîÒmtšL°¸c³…†à6ŒĞPl ’@]¤+İ-+ŒpøaD9Ì·68±æk*[ë}ûŠ™Î›bF]•^(F‰€bû|ª&e&+zŠÅü0÷QrÎ×'_c•@&Ğ‘$e
Ï7…Å¢È¼g¿;Œë/Á#ÎØöblÙ a•ÉıQ¨Öñ³j>%¶ÆóÒ\–ş¦ÿ£Â•®QÛµ¨G%ÿıÀïÒí*M¿ñ*“Ïs±¯™ãÚò×ı– 1w•¬Ê)•ØÕ]tãû'ƒ¾éa4N4—ß¥Qº9<ˆ!ùËx$Ÿ`…s¸Ûiğ–l†Ìw|İğ ²¨îÅ/Ú®ÕPŒ¤BØÖænW¸™è²/£ p0›#ªwTûÛ-šÚ¨ q¿@Y~ˆÃòÁ@ı€%}Ælà!Ş×>v“¶áò	á0U¯ŠpñvjLŠêû®{UÕ{5±"‰ßëq~_>]°×i™ y¨,nÄÎ.şüÿââ®r*ë<£{Ó`öóÕ-öx{ww¢Ò8úd ~–g|(¶-^$"j™œû¶Ğ]ø4Õå'¤odH÷–I4OÈ3İÉøæ
ÇG;½ì‡¶Wş ˆÛÍãqGMnåN¨—‘{ì¿Êò8Îz¸®¶IíÕæ+€åpı|g,¾îûÏb»¹Ú`·kë'qOşRW
b.±´É·×Á<Ü×¦¼•×»X8x–Kf‡}Ú$ YA1ëfÍã˜?mCŸX—F®v	iÔóA2ÆS°5{ŞÓ¼ñj’ˆ÷‹û™Ñ”>:\åIpC}ê¸À§a<”¦Á{÷WìR]GZ1…†büŒj9·Q»ÚÍÀ|áQ±Z1H³ ZN	€jçş¿]OWgX‰ö¢hÈœBË‚-Æé·³Vh¸ 
îNÑñ<2Å€’î6¡e4ŞŸ»ŸbmÈ
Ã8ß%JÂš:”IT<ä½xc=G5USƒ¾mî,cûBğÒSëóÌä¢/c±ú@s“ÉÄ¹8‘]¦öúUA¿êÇ3FŞª¢„7æLñËEå£q³©êvTî¼•§“šŸ•rÑ±Ê¯TšØ˜”÷.µâ–ï±Œ§B ±@¡ˆïşR<5ã2¡IB?Ó´u;y_ıŠLõğåÇëÄ.€/ß<{¾Yô%&K'æ¬À¥ú?·ŠİÆà)C~¡l[©¬&F Ö%M!¼oXÒm ·ô¡¬©’ÄfõBµã†[ay”gƒÄrË‰Èh¡óKô~+°tŞ—(ÖQ‡Æ“¥ØeFƒ'ÑzuùÎÖ6‘¹«!p²Ş±€*»ù[xŞ(s@dâö+ºßÊY9ãwºÈ4æùfÆŸ±Nó82—§äª®©Å×X^¡ù²Š(ÅÙ4\¡•&%ò~¦ib¿#c×—6ø­NÖIá˜À»š+Í1ÃÚ‰,‘¶UHê‰WV¯áèÍ¿“—‹2$€DZ2÷åŸû´,}¾ğ	êh°«‚,ioù7¢’#}Š~ qâŠG{•EìSíN€!ª¿)Â‘’§&¥<Âô˜o˜›dù`öÿFF>(11ûÏçµö¤ìĞ;úlœZ%¥b2#ZÜ/í1‚Ú<Õ&9”ã”îÄjkGdÕ*;<qß;Œä8ïÚ"OÔvûrjõ 7û	œ*|şhNÔ½ÇéAÑ,[Šj05~LÃBÒÿD‡ğ-j{:¦aŠ/ Šÿ%öÂ¬Ô€^³&Í~AØıPp„ñÅMø
a}‚ğpö›±»y–ÏNc’îùæ Æy¾nğ¡hhºN×€ »üæà'1ëÄÒC
Ë<ş¡ˆ·ÅõLõ¹„¯¥[JÛ{’¿œ+¼û¯Œ´Œ#ûm1Êsı¿x|#ŞÚLĞ1oÊ‡§ÀWjÑŸ¨n²…Q=+l–²ˆL23Àëo
zä<’«¿İ?x¥@…-à¹öås@Ğ˜I…å›º†jãQğQTúEÌˆ×¸´š²!'g—5²¯H)®>jÌcv3qò<í2Ò¿<Ü„~)¥jF{àeªÒÚa5–˜$½z£gİ2ïÄÉ-„ f¹‹éğø®?Îö'<‚a,k–¸7‰‹„Ğ'T©6aÃş¯9Ók&}ê<FlsP´ ğ”éZ7ş\)>-pz»{q‡ò3WêyşŞ…n\ç:‹ 0çÇ|ƒ.hÿ;h*’©  5xİ»q1É9¼è,êÇ•ğqÔ4ó.ú¼ÓÔ÷{ïÌXŸ¢ãÊ1™8 €mï®$<.5Rò0,_\¸Åê¼+1ˆÙ›õòK€†Ìó¯½–³ó×˜Ú<ì:F2¦,¶Ü<oAÎÔæ0ÓV dÓ'p3&hÓø?¼"-Ç¹úıÃHº	qşºÖ9ßpşJß Î±%iö×v÷ñòÂØ^²šêÁ¡?¯¸†lÎæ8AG†SE¦ZïÜ¨mc¯6ÿ¨bÚ¼v_[|~iÀ*LªW7+À¥BÏš,'èW²xb¾ÏMÊNóWäõ°û{ıZè
yÖ0µQ&ƒjH+
ÚŞ`¼d}Ë.Rdİ…³@~*,I~!Üu|ÁÑœÙ[°‰Oœ½N¹*Ú=“
$µô®‘¶ËÚ½AJ5½dÕ$Òâ¹v®DL	ÔM½™‰iÇÕ£	Ò™2Ã¸L¶Qj¦”²\f„sŸ?Šn1‰bûWûlÅ¢a'®yÍí…VÄÄŸx£ |»¬6JÈS"dâµ¡Ö#Ü;=%Ü¤ÊkXíï¥lĞ¿rß ½êuM,u£Áòµ<Ø8¯CÆ"Cl	+Sa}õ†œç®O\Z4Ü³ xË+Èœí†`›Ó¥¾éf*œöuHsÌ*Ù¬.K›uÄEÙvJdáøk»ş\ÿˆ4îkZgbuõ¦Õ^lAdÙ×ja‚°!¯è\r¦)y¥Úq¯KW'mG¢VªUSí?š8]©˜üM&#¼â`^s‘¿ú«9¬'ÏÜË »”Áë5ªl ¿'*˜æs©-8-ÚÂHòx)…1ƒ¢DG"qãÏØzÓXlU¨l…î;MàöGÑcCä-—‹"óhH)Ùë	 ×®*ÉôÍ\ôOüXCkxUı5MÉª¤€µûmâ7|ç@À$¿t™"4ş"Õßıú$Œ:nıæ-¾È#to+ÜDI™©¥¾†{i{‚UI)ÜmñÌ·#ÚpñÆ´œÍ”é>å9i(œ<[ær[—?˜wŞ¼–1Wm÷°¬—‹ÚÔ_
¾s# ;~ÂÔ\ùÊŒ©Ü¼V“\&¾å`AD!'ì4–î$îõcëı¼1ŸcŸtéCŒÖCbÖ± ü¥[T™µvÖÊa©,Eg™ƒªlÌù.¡å! ÔMÂXÏù×á‡GâË}ıV¯5¾7zú»*ë ÁÂz‹B°‘p\, lJa:D0ç{9xÇ89‹÷héƒÔzQŒí¸Ğ]„]Ğ	ã=½ï]|Ğ„eğ'‘ã:XaiÒ’›^l¢‰]è—’íİ	iYÁşFy0…×æÇĞ½ßõvcç­?d¼+\ï/ı>õâÃxÌhâ'9‘Ø‹ áIæy*±.²‹ĞdâÉŸĞH³şÌ«ÒÈ(tBª™—°4„j‡EÁHÜ ò@J§ûtÕ‡ÔrJõ§«Îw3•o0İ©_Tå™«•¡­ŸXòê§EUGHùÙÆ'Sö+²èÁ»-MÙÇÍÓ³¿š%‡¼‡[UšYÒ‹àÄÅÀdå‡÷oKxï¼Fß®äääˆ¥ÇqP±ÈFY&;'c\Ôœ7ãËk0ñ»vJˆäâKè7îı’pØ¼œwE=Tø#Rÿ¥CµQü&Ô÷Î©º–„ÀJ°‰Ÿ§±×ß:+QMıù›«>’Ê¡2m`Šªû%°Tì–:ûüÜÊ½Lß+Ày¾˜Öd3dZÆ!`½6 o4îWÍ%.F2¯áh×KÎ½¶¶[) zñ	-T,ä–Oƒ±§“K¸èõSipAXª»R¦¼…æ©ïK>/‡ÿ™Õ¦	'‚8ş ÛÜQWõá6)ƒza[Ø°Z©´VIDh»¯&b¸Ür9ùÄÕÔ4vD1bRµÓsûÜØßåŸ^ÒÇyş^İ>7fÇŸZ\a•w\`şÉUyÌ‚#òI¨¨¨e…7TDrüÅËtP…f³EÛí’">pÓö1J-Ğˆó¨dö$!49©èğ“Ñ(²úXĞ½ÛïóÚ«ˆZ_ïºèUIJú_š<}­Y—µ&áØ‡Ğ™t*<ğ¼‚±)xxOóYÂzî „n£Š¨>vJß$^v-Ru¦¦ú-úEœ|üİi&B’»Ú
dù”œğ}£šà©
¦h€ )ô¹Ë!NDš¡ä¾ÒÚùqÌşµnÌ·zXÉ³#`µ›+§ñ¯æiY'Z·ÓPØÏW£ÑWñU  	Bf~"1 Ü­€ğÃkHŠ±Ägû    YZ