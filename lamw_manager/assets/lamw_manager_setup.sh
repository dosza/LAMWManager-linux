#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="499553623"
MD5="d1622e2f1d1ce92b70c3efbc270170fb"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23264"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Wed Aug  4 05:20:29 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZŸ] ¼}•À1Dd]‡Á›PætİDõåï²‡¤æ…J,?uIøÂ1'…„±-Ç[MNïudÊÆGÊ*[“Ñ€y€ÙÅOG»â+8€š?–Hr`|m–íëîbÙãPÚ€4ªÈL=ØÁ8éĞ+{¹$á¤´SÁP«€ÂÆ}ŒÇ×t(KOcšÌ{õ.jNñışuŸ’úĞë|hKõúÊ›u§¾Â¦à'ëVãô¨ÁGÜÍÖ¯»ûš3ˆ„ÌòüÌıÖ£#ó”wj$Î…€yämB:ô˜Ï ¥¸¦¸õZÅ[Aæ>‰ïB¡0%83Qı²£¥Z¢t;nì Öï\_ş÷bàÍ®RéÔ ÆÀS{½p€}*hí\Ì]ìç˜|å`Ù(bØ’Á]Î\5ær*÷¨prÉÅË×ÿè7 ŠÄæHï‹z6Ê—¶}>³ 5Šàï¶}ß´ÇKdˆ°ïo¢rI|^B¶d*Ø²/¿Ôj—øÔúğ¼|—§2^§}µ©Ğ6üé5vøãú\Í–<WÙ‰:û‚ûôu°oX†G<§NJb'j2{sUgr[„üêV¶©ò‡0•ìÓ¼·lé-Wºƒh;Z›º%ƒ-u|¶“âåô‚ê¦IÉÅ©aešJ@5Ù_ç‹Tèm[&#ĞŞ®øtå/_ÊsÅq–¿{G”ÍFÖÔ-ÆŒOü«Œ÷1~Gÿá˜¸T	.¦ë¢Úp©5<ãË"ùS¡SÂºV—¦÷ßä[ˆË™
Á]˜·-i‚¡ÖÑ‰OM|¦¢
Æ¹ZMfàu0lƒöX»İ"š‰zøÛa‹[Ö@ƒÍ-„sÍBˆÍ¤§D-=.IÖ‰Ìï¤‹VwóÁçì#xĞÌ+Üá«–Ä\¯ş­ü€rL­);“&¬Â«|mæ;?¹bÄ±gi](WÑ‚{^¥’EÂ¯e¥3úijöQ²Ï¿šÒİÔ³Âİëêµd€ñ´	[3ÄŸı HçøŒ-Ueè¡¯Í}øÑ ı~ã½wuĞs–UÀ²•Æâıëh“WÁË¶¡†JÄ]Ú”¼Â(ëµ-Ü¯Ëy…urBîÒw]ÿÁ9á¡n˜ÆÓ)0`ç¦<~BÏ¿©‹¤¬mFvßóéç÷M˜X
ÊÌ•÷eß-±z¶³iC]äı€˜K³"ÅêjÅÀêRßF[û:–¬uì«eT¯œ·‘¶.­˜Ë¡/KKªšãjAƒ¢öû)5çƒ>8,˜UYˆDhO:›×¨Ÿ›;ËÌ÷	ï×KDHã•ä$ì¸Xä€€{ğä›“eñÑîŠ½şŸ¢ˆü]ïo¦ªÅ‰à+.‘)®.¬"züñúÕø£s•}Y:5E3|å_Öš¾™®±AFÈÂHPî×&Vl;[sTM†³ûÕ„œºÿ`ßPüşÅRã¤³¡åúÎÈÓçÅªÙ} gìWçş,{œ@åƒìYÀIñÌ»B……~ômhŠ#¯º’ëğÍuEÕ´:Å_lÖ"+Ëô(”W?;Ç%¾ä„&˜sõ	±>j>AHF9vZu›•ŒL¶¯?ÜL	T…'Ü¨ïÚê~xJß!Ó™Æ—-»Zœ¼¯zqqÁgS5‹­?­é™$QŸ°‚¡~÷«
¸}pª‰‚Â>ñ#½¸·'dí(!øÈa]Ó(‡¶Îù Î©İ³¼`íŠggı•î*®p×ñÌÉ-¥ÉE,Ë2<úÙp*+ÈòÎİXş™·¨ÍO`“üHÃÅ ò[_€’Ó]zåßE£_’9ŸÍ¥YÁ­>.»¥É¢YàêK!Ş¼›íó±3¨¶ÇïÄˆÇQ3$£3k&vË¶…,d‡~ÒgQšµ¤úÁäK­	r¾‰s¶¹Pªal!—[¬„¸g];õD,ƒü
üIÎ‚Œ3h¯'è&õ¹h£JÚA9–¥M’Üœ…ÅÅ<ğÇS7/=ÃÃŸ—¡øÍßÁ·A»4¹«ò>”ä¿ „Æ`éÓ›SFÊÿ¥!åC}­¥IR˜€ŒHQ%­8ı+¶e?Š;Âø‹wÕ¬°®KU©JFğ”ÅL…!P—µ&ò(ükªÄ@eF(v4ö•O½©.ÈIÖŸ‰¸G7º+êËÛzÁO4~I¹~ÓòåçRŸtx ÔQO^ä1Rã
SÕ!íCäg1Ìö»AñK&¦ÁF˜GµO¬şFéwĞYW™x˜¦v„Nƒ7vİä·+dÅ­ªx)¼©ós"¯4‹¢ÁsÓ²Dõìòîqd¡
¢Z­³jÉ"A¯¡½B×õƒ”Æ¢ëDœğwË»‰´Ófp¨SĞ‰^’Lù‹–ëÜeÎé¹à”ù‡ÀÎÏ¥Š$MÉÒ
³
¡É¥(±oíñPP`'°²Ú‡”“y€æ&ã0½É ÿ#Ì\ÉéÈäh\Qª:«$9¼j´Ãâ”
ÑvÍˆ”¤÷pûÆm@ƒ@e]UR~bƒº½ô^ÅŒ±¥+e>}Xã“»îÑ– ë8Ú³(‡©~‹Ù1`‰åè¼DÀi#uKÙ>4N5…‹ bõ’©†4tç€®¶g! Üö~ÄDÕç(ßëË@²ïïæô’bä˜kl´O¨ìÕÂgTÁ0é€&lœšáÖŠ_ìb°G–é…Ú¬!…*®gà8ÒÄ‘Ó:Z ³de<|}¯š.Æ!ˆV’Kõ_ÔÔÛä­€ßWxS§9ß…M ÀAšÓèp	!Ğ+qşòØzâ¿üù#—²,a@YÍ×›¶Q×ËcZ^ S3*dïñOŠ…
=í(—	)(!î†‹
oàQ›+‹ï£"û‡2¯i'Z‰ŒÜ_LsÃFÚ_qÏËè--íUp”ç^Ëı	Ê`’•3ªeqŞyyËº	±9·¦µÎG(uƒö°u<¾Nªû`‘·Ü*ÁÔ•’ß„ş¥\¿ˆ@Š.ËÑ®ZìG	ÏÔŠ}FNß+_.Ä&RŠ.Ü)•ÇGé˜ñI[ä{m;™/4¸hVh¤ùÂ1}x,{åçâñ\ïÖ¹4<2n¨ÚÀOLÍ7e}{¾ÃÌGRƒÿÇxÎ¿õlóF›ª!=g½õ`ğ©Õ†%²ÑK]ÑÈ~ô	8d=ï>—[‡˜0íe¥&§xl„:rŒæÁ¥t¾¤ *ó“¾#	]h
ë¨x`¼OsØ2-)áz²AXbO-2sê;ÁªxƒnAWP=pÊKüŠét¨RÿÙ1„&qÉâ˜™¾À]H·§‚)]vvÚ¥¢}5\§x¿¦1êÈ\Ö ¾Ô®õÀo©áYŠ¡k=ÄÑ=f‚çwÍZáE¦Ov„¤âì§<gší×Vñ95M¶àË—ÔmÂÚ½ëÆO}|İ4R;Œ¾ğ˜Úˆ²ÔcVeJş-ƒÖ½Ï~x¹füá'Cc‹şpsµ@C9,	zn¬İC×Äşñ»ÈÈdP/ç[ºU÷ØõlqX¼ ˆ}° ?<U¼í×n
æñwÈ5nò¬B
´¾™;°—˜X¨>f•vMAºPEI{1 ‰±jõ;bBAØ öy‡ˆİ´n©X¶É7‰Ùıv²6\½•GZèÛjÃÎWI· KQ£z0ZQxüë¢¬ÕV>K“8Y!\FñRQãµûõTÅ j@ÑuŞ{ph¡şâza3ÏzäëÉ»‹ÏÎ:AÜuØfÆ¹Ö„Ú,•ŸE®ŸıR7<Ì x¾‰Šê“ñÌÚ&‡GÍc¥«Î•ã7M«‰úÑ¯Ì~_2[†BÂ¾_;©‚µäŠ,òWúOõfö ş¿A¦“’BÃ»%Ú(ä»SO8¦•«¤uÌğ.­ñ¸Z¼ªÕNÊ°]xÜ¿gÀì²¹Ô—˜µáb®~ÕÁcÂzc WQHfã±|„’[tPß”ÕQ›åRYkõÚáóÒ–—.Ma'¡\tÀQ¤´9‘Ñ¥óğ‡0!áÂ”O†+0Rƒ`"¦¤ãW{jj µxÈë²,“Ş¬³Ö¦ôµÖ\À…åÅë –æ°ó4§ñµ	úIå0![ >•-ÉxYÓäc¸ÊĞKm<r-’
Ù¯@EDGé’Z #’t)Oì…ÿÇÓâÚúMm×ïN*ĞS¸c„Öyş”²L{B4¨àç• Ú£+ 4à7µl•©>tŸ/„³wY´elñ‹\ğŸ>n-«<áë¸Ç1[ãJ„q2öÀÿˆŸ)’Ú?è“
ILÓE s&ıV¤ú‰Òİ¢c%(“·IVİiSË{½/Põú›ô)	7²k™kØW a}É`Üb;&{<C¤–,K"áq= Õ5bÁÔUÕöe¡ 4&ÿÎ,?ÃU-nä"¥Ã­Iä6§˜‡SˆğT}49G8Dm5¼Ä	FR`İ`] ’ƒÕÎË+ãO;j¸ ²Ûï¹ş3Ëôï»áÈ>H	'ÿ™´ƒEş°©¼[¨¡qòÙı•q£Â¡Ääûâ.ÃêAà’u·áˆu®M½Ñ0™¹[è¥1Mz%œu€±¹*ì‡pƒ÷iÓC†&á}9›Û¯BfÈ2if‡¤òr¨†_6ÿóT½±ë)+°ù&Ã:Oœ	¸Å¿^/Üøë§ÀC4ãú»•àÉ0¿Nd3~ ­„'i÷§çFdt)i[?Ç_±Ê$íYñá¹U¬‚F«²¹ÁÙØ¸Wª¯_QÏõ¤ÂaÒ{7Ñ¡	`Ë-Qí’‰G‰“Îk¹AÅ9CË­Ihj6ßId0ÕÑTXÓ·q‘Ñƒæ˜ÃòG„dCsbnrÎõÉç^'‡SÈGä1Éá¡óCY —‚0 ÉŞtleõÛ¯xi¦`Ê^¶yµ8†<¥Íî<c¦>x‹rÇz9õ²|}Ê¹Ï”s×ò··’,=È¿„T4u5H.4ÑãYƒ”ou•Ÿï¯PîŞ•m{½ÎıÏ=ù>¬´¤‡†ºÀ¨+Âe#õƒò–éÚLº€KÍíÈ÷ 2>Xşto'ø¶yuŠ,p¤[¤Á¿§”{t?ê'),d&¡œ.’íì\•´í$æfÏßG »}ÀfWÍE ~^S" !¼ëH‰C'²—BÂ¾q  ÑÇQÃ„E;ç@¯@àÚ¦ñÒµ°¿Ğ¾ƒª÷Êmù¶Ëì½£ÃôãCë¸‹‰U·¸‘jİÎ($6RaÍ¢­#ÄáSP{ujÃÉ@—Ã¾à“&èÌÉ(m&‚›HÁ¦{"~Ÿ8µ´”mµü´WÁÏ1Å	’…Ï…ÿG6ıVåqNŠ˜½åTe4ƒÔ}‹ĞL¯Òøî{Ò·ÿ„»¦gó‹à‡a>#4myfD»Ï?Şt‡&ĞQæ’FNL6õ^jd‡áTPG.Ö¶×Õ™¡:‚—Òº5(˜wIY¯™GDĞL1TubˆoµU¡É…Ì¯?Ú6Õd»$ÇûZKwıåßü4GXçÂr÷WJ.~³ŒìsÔˆfÂ3*Ö-oZ‰Éİ%2@˜=Œ’„Û¤†zw,Æ®‡½ÈÓzMg¼K#¦àÎ³ÑHşK»‰&óÙïMÎ/Û6r?ÍÔ7UÌ1¹l¦Fã<é²ö„şºfê€ç¦•Šü´Ê¿uB€TÈ)8§”“©Ášæœ=@¬ŒºàkŒ!Š@AMÔg5ÉÙŞŒ:ÑÂ•Q„é&®ÖHò$Ûdò¡IyÏ‘§bOı3pĞm]â<‚sáKÈª0é¡ä”A"0ÒUäSß£3œ!¸=È‚ dy˜ïd˜P¡&Ék‹¯3uh…ƒ¹›DÒqæIàÔTZFÍÛĞ¢yæŸÍZ!´Â~>F DöE{€E„yÎg/ËÛTÂV*jF°QœWÖë›êw’Ş¢Pû:uôu9&*Ô_¨¹H$î¼è¤ÔR<:KÔ‰sÁ\=ô2JÚ}{@-¯×@vã4IÁøÆ¤msßT‘‚ÕGú;,½İâ8m›ÏÄVİĞ†ßQÇS¹²ö‹œn}°Õ$Øİtaå>uVÏÁµy©Ğ\×?&mM¼Şoz‰bãŸ Øµó‘ªQ,0aMyø$÷ÄéM³³ZXµ[ã€K¡ÈŸø¡ÕYèÌ’ì+T.Ôõ]²&»†7Ú;ş¤S­vd©·z¥v—#èAUÆ$U½m³ª’ »¶İvï­½
è§CFî€ˆ„F³wíş¿Üi°ò½3”€Úoõ®f…>ğ³£Jp*zÃ¬€bÒãş¾Ÿ¦J?ÛeŒ{hBéTŸJ¶ıvXÁb¬§âc@ßëwéÌ×¼á¾OKˆ½iKt‰È$NØˆ€}Ò&•TW
/Ùâi7eúõYÌëNõÈTXş‚nêşG–õå/½²8¾SÁ­$JøÍ3šnìb×öÙ¤hš,tT­0°_k¾\/d6~ó¸…Ñå!ZoB‚Ã; V:ÂnìÑGu˜Á®8Ğ”çkJZô	¸ÕÉ^õá*º¢ˆï†ê#·ô× 9—_İ®¶"À¿ğ‡*GWÕ#äò;ç :Sî¢‰†à8¼WÆÙ@ Í-(>,Ó¹±PN8¶Êó¸¥Õ¿<eƒÊÜû“ó6ÈæøÛ÷ƒäa«IÑ³Ä’c,VpE-SáØ½hœfş˜{ŒL)ı°"Dì¯5:®¤Óvìã+TûİÿZ&iÚH5äZ!xñßgÅ¢ªœt3Re7g¦2Ç¶s½õ<ÒËö«ì·ˆ^È”ø˜¾•9ÄOo•g?õ¿„w°àÅSîYíHv—ç£öÆ³Y—dqxÒJA>9ÕUYü,Æ†’%šAåwò{¶-øÒ¦©”X€¸·‹‰õ1M‡º“O}è§|	›‰(M6º>±.µµ5çëŠíMš˜íio1|ËZ|t ~WºÏeª?ëtÓT—XñÍdï$÷¡áõv‡(ÛáAŞ¿bĞå¾Ì©jhoœ­¥ĞÆİºJ+F§wwrØ™×c*îNqµã¾rv‡Ê.®K·Š,LdÉâ¡Ê®}Ã1zX‚àgáíÙ÷å¨$Š~¨`³‹[ø¢M°JS,.°úÅEk$˜¿ LÃDpóz©¸\­ĞMO:¡RpŒƒÊç:qsæW~|Jaô†né¥l,ÛXª©¥0	BOYWTtbôÀZm‡F("]:.È80×É¬X_)Ÿ  Áp]q˜î`ŒÇ ®	ù—ÌsâØ’_6Rºè
.ŒşÎÃ¼Âpæ*¼Zññ4m»5xb¦q(‘[Û™|ø¥ƒ€÷ÁŒÉ	\Ò}Ei­¶ÂÛØdRm^áštª«Ë	×ËÖ	Ä]D+Âxû¶´–y›©ŠmAÂ*aPÿşnãä’ëhn5¸¥°é“ì@3ÿ2JñG¡G^L¤õ«üæÄÒàvBcóäçU–cCì?A2xëË+PT bD»BvqĞÎ‚×8hıX å<SöçøïyW±ì;İ)Ñ¸Š_"òÓÕk&Pç5äqyI:ÍÖÆ™ £ğæ×ŠDìåÂMHÑ×ŠÜ=úºûóIÀãŸi; ¯qÈi6{UPûE‚Qkå\òCL§	Q‚Ñ™ŞI»!`Ì­dRt¿NîAÌÂ˜˜±‚â¦RF²s¶d@‡=Ğ*:¨+•ĞEV>B°¤Qì¨–§±Íİ¥²”×N+)Kf\ÿV¹Ê.Aû?)Ú9˜ÁğøëZTô—‹r8XPËZ	ë^AIÚ»šú®<Å²œ·©Qai§5?ùğM±üŒo…n¯õû,ÑS–Ó+{^¢÷§3(=[ıŞdPÂ’©ªºÉÏ¡ùà–p»ÖL²[ô¥1ßÆiV>“ÛÅ0àóÃ‹±ò¾'ßâë¬¡¶‹ßT½@ôˆfº÷¨“DÆPÁ=G·páB‚|#B¤¶<|z\`J¶ ¯u‹\$ùnwXq1§p$™i“M1 ­8$ûÕ1…áíêc6È£ÕÑK~ªÄËeÕo´¯‰ÅæFu*÷5TğhìNpzó‚c–Õ†\n¶:=S;òõ&9¡ï§°šeçQ_<éº™:@{Âğ‘‘VrVQ²Qâl.n³_vü/:K!c€åu^ 2 %cÔF  }‰"áıº?¬÷>W]æfâ&^JXÂS57
äİÊVQ³*ßR;ú‚³òÈa>m•6âS;§²g@`@[º+&‘aÍ<†J7Ç£ëaÜRõVãÒû-ş@Š“hûôë Ÿ·Ê
F? à&ÂCCSÁÉ_L²ø;^„°¯©µmšéí¥÷(ÉCh¤ b0µo5ª`&zNè	
¬
½ºß¤á¬ÆÜI2k‰ğ"àè™”Ì®Ùc»f5ÔBş~|“gû¥ÙcO®Œîù['óƒ¬ÍuœÆ²¶‘n`¼¼IÚ`‰¬p×ü4{R­m¥9KòAëÙen¾DÔç¥ƒÊ=)gİ;ÇøùÙjG›ªPZ¯Ö
ÁwH<L­ûÿá\¤˜¼&NñIr_„îóˆUYÅº¦Dœsf» æ±ÁÂ7Qû4ó‰6?¡ÆßjCIGöLaëUd”ø¢šÙx4·õAÌNÂ„Q´SõŸU>„€ş¥[wôÎÂ§W—Ø
¨“àæÕşLçÀI{ÃğŞ‰\ºÏ]@S{&Å™Õ÷¸'”TrÁf6DrİÒÏ0ˆ;Œ#ÎšQ·4­ÚßÓcÆÔš« xåó[s7T±?&õFÎ¦Æú.´L±E—Ğ
¨µ=6pù0##ç@urÎ3's.:ıˆøÇÆÓ~úÓvvş6ÚKÇ¥ö2\°§×ëÅ¡Ô¯©S×Ø±,¶œ¼ášv¡şF’	pb-¨°Ò>(iN´[y#Â¨¾Ò#8{ãl9ñÑo-d¤Û1Hôœîªµ
Î[ÛNã´ÚI£l6[	‘¾ÄÛ£TĞÎÍEW¤%¯èöÙ§–¿>z£½şW¾ûwP‚§Bˆ¿s?|vjAà½'™ÇM…¼ËBi¤û”¦e#æ®‚6ˆªañu—pÇ{Å[qªùŒ×˜im
N+›İ‡P!ŠQ¯ñzˆ€Í¿¸áÂ JéÏÇ¹÷zZL~jz]Z°çg„½W	Ëf®³q¯ù[;æŠø³t‘}œ 4¸
0»¦;º,'¶ı;4x>Ÿ‹v–ò/aX‰İà¯×n]Õ1¨’BêRş9Çcï´«¦Yd¤& Üf4vÔ·:•s¨á§ZZ6ÏWíPy¾lŒ‡ Œ¹[ğWşt³r$ã ƒÛÃ¦äç16ˆ¶H	‰}Q¢Èãš´<HÄMğpŞc44ë8v>V¶¾¦RÎG>«á¥L†ïPğ¿ñğŸ;Ÿf"¬¡×“œÄûAÊ§a£Ì	ÑÃE¹#òzúuÍ1²…oë~~‘K¦:z)ç©5>mCMdŞ‘¯>­s*â¿êc4@õô'›TÓ=Fkd —_ŞíZóÊ5?,?2‚ô_vœ†CÕ
9È“Ê¡S;¢Î¡V´4='Ã¢&¤¹ã4”]-æÎ‰ª îÆñ°!g-°& j£¬(ğÇIô=£şÅX®ËÈò;zğBœ¯(ô¹œ‚{}h°B[7ï  ¸Û‚ßŸÖÃøx”®QÛ÷ı”“ÈÕÆ‡¯‘ŞÇRá~j¯!o4—3o¬”¼é8´ÙÑ(şr‘õÖHcÕ´W‰Üiàó…d›–¡Œ°¢¿B½Iqß=¦¨Gùâƒõe$âcJË»;+à1¶vÜÎn;6_æs}û×wTÆÅ7w—>VI½]™ø±]A–‚£œ‚H/mâ‹—[;ìä¸!ËÒÜ>â”Wnd;ß?Û^)Bwì°¤úvæ©„ş"Vo¼µ«QæÕk'Í=ôÕÀ¥‡¥Êq’?Úá p²K»ò‹—	›axŞ	ĞCr¥äë,áUYê•|£ËÎş:úú_hÊueã3c´0–¿îU\É®ŒıïÂ\ïİorÕùØIÅ¹YÓ¢Ê¡Ÿêè%!ÕsÃ)b»©Fİ™|U/àìqË›1éĞ”K1?9N*e%¤áĞM¢±Ô5?1˜,:ıÎ©ë¨.P„¶ºş½¿ïEç—òõ¹°–§¼ÇzF-aBï~YŸâ+×r%oİ
ÿÚ){`8
ËÓ&/¬'©gÕ¨¥WT 0xVrü±ó@Ã„&’Ä#•³’J¢=h×õ*Yıß¹^v­j4ÁZSúûÈd†:{z£$:ZZ¦ \\eù…
b"Ç‰l›îRfl¿FmY¡Ø°iî©X%0rN•®|k¨ófwT˜Â2áîO¾ÌGn½ş€‡Ib<[oFÕuó¾ş£¡n#õùG·`9“*z­S”— ‚æf%˜fµcP§V¢~`›ÿUÆîœ˜ÚŞö>ï·ôaXr‘áº×­ÍößõÊı}-Ã’×e	AïA)ÏI*L¨b“^à©1ğ¨¤¢A‹UÏuUg<½'tµbÎç/¦,Ï¤a>l)íR2İmù@,ÿbJƒñ)»Óšı‰Æ¤Ó„[±Æk¡¿\A…3h“òüÖ7Q=·õ=&,¡~Óá39Õ”Œé.5¨ˆÏÙ'„?á6 ©š²zÚÕ;¾|‰TåÛ96Ÿ Œø#.o'ÜC‡£ë¼Ãx@é3—IwùéÀäøUÁUTT›?Ş å2ÆLù0ß—F3’~¨†={œ÷À€ Õeğ‡b$ß¿Ô•ƒşÌ˜Óµ-ß w}¯üp/´®ƒ6cq‹}Ë¡@òşœ»
ÓŒƒ3zâÉç=ŸDdMÒ8H)İÓ
ÛgèÛÂ(5a_B˜àßÂr²p"é² g/hnIQñi¨95Äà'ÎUßt³IMÅ.3hØaJÎÑÏšÕ£U{JşvÎ%+DÖ½M2€ş(‚óO»3cWÅEcu!'ÿPü3YĞ;¾çh‡ş' ğCÚX((†	
vãœäI$­z¹t ³[›GBç¶¤›â[È¯6 q7ŸäkZõ
@)†÷jÜS¢9w¦>ÃİÄ®UàyªizÌ>¹£yHKòhàm<íÊîVÁ~LsE=^L4@Ğrş÷…ä(¤ó}†Ùïp7àÒ»¼Ì‚³ ÷%à#òÄP‡:d{¯İ-êŠk¿¨ƒ‚h–Rß¹~İ­²	JH‰ÌÇ<r•55±²Gà¯v˜rïáÏötÂâ¦&Œ'½™ƒÉÿû™Lc¿I¸›ÑÙöÒg¥¥>ÃÔÛŞ›øân²ÑïM¥ÙWñ
´ØŒ·K¿İö­;pÊ&·úæÜxüû%ÍhJF`ËÆ]­pÎQŠ=<“Ò‰˜ì	ÔX6¶¾í)ù|¾å-Q}˜H4é$Dş…L€Ÿ3•3;ØSÌ< ¸rVP‘*kDÅ3è5S²Û¨`Œb’úƒ{—U–çğj9éËT(¯«òj	ÛÃôŒ<f¯g¦Îıe÷»f¸9ƒL(^“îÉ–#°…«¤UR3vi•oºÒ”EßŠGÕöÖ!»ÛİZ´Óvögg—Öm,äaÍ^ƒ-êŒ¨×"$ F«3ñøĞ6kæÊĞ:ÅNá©­x&'RÙt^ÚmÖ§@š¤ıŒ¤HíRÃ·œëe³@ş^šÄešV‡®'Æ‡“&z÷k†QæºOl¾Ñ­EÃÁ˜¤CFÌIkÀ¡1!ƒß“ì n3<}Òœ© F(˜Õó=êcºßÅÇ“M4ŒÅ­löDÄ h49ìmİ¶ø¶ı8ÎH|æ2Y!±iTH[ùÙ½Rš}Öà7l¯N¿â×½]†¯*+!T±zËF"éıSÌUı^ãÌô˜´yÃL‚†‹-,‘'×rúOÓÆ!;×á3wõÿµ˜Ÿ×Õ%½xĞMi›3>ï÷XiCPZJi@üÛúGÃw%b„öf¸eÄ„Ú>¾,©¤éìù«c+8îOA¢Æ¼}Ìe@C¾S"!©("ìt¥(ÃÛ	{w®“†:ÓÄÕônU‚RíBé'Cõ‡ÅÑLI*³q	”—­n(EÀ@Ì4¬Iiı\.Z%ÎÂ‘B´z^ı'·¹Ò”ŸËKÚ4ò{åOi1”±ÓSË¹	L½ŠÛ+föÃ¤²cÉv…>—äƒGa
2^¸ïòã} 	5›„(*b7ºwa¼ÀV>œ¶±ÎÎ0îŞ"f_ïµ·ğ/G‹MT¶êFµU[DÌd†Ì¢‰lÿF˜<aÆ¥ÎD-b“óÒ^¯šÿx/XìÑf&`=È”RTÍ
HÏb”,’¿Ü¬Oüò]/ÃÅã«âœ¼\á'gYwBUAgòEú‚+7ö–şCM
¶M×çù))!d{^œëú˜p4/F7%òaBª$¶ŞeW±A1´Mÿ“&|»NúA$>xÅ°E&a *=–}“|PB»îFµ÷_íyI¢zğù{5ëÓMEV»œò€*®)ÖìüVzÿp!b†³wÛV„K¾34¨ŠDÜö– ÛÌÎ™ÅÏ[Â‡D1J·…ĞKòî$æØ`¡;š‹âÔ¹´ÀK‚Ècq[aq³yne®AÓñFìn¤o£p™ÅíSÖˆãŠ›S˜2n‚š}ÚÁ¢æ„­6°¹êH’¹yí¨¨ÏP?à%Hê¹n«éB5¼í2ªÿóŞöK·%Dw×X³ªv’ÙøP}>ÏXA;9èJÍ´¸ ææ÷Ù35ÚÚnÙ”Ÿ²`:ôo²ºD`Åâ±‘Ê€~WŞöşËâ_S©{ŠÖRÑÅ:!*l¶Ç³+}ÕøŞÊ:èGs%FR.ó²Ú?§)ïñ“Óµç\ èÌƒ]8 Ÿ^šZ	ÌØ›%ï­?)&QÁŸİx“6°˜L.TH¬ºsİÅ¯Ã<>ZxSxÙ˜dÔ!–¶1ÄÕ<Ÿ¼ÛzC#íy
i…\Üew€ÖWÂÕ9$aˆ‹¾¾rï;ÁNšTwæÁÈøCú¬”­*Œ9Hg¨« '™fJ,/˜âEË‡Ë:¾!Ÿd“Õ^:É	Zôd…¯ŸÕùO'J¬|0×`i,<Öş$,˜‹´q×$ïšÜ¹	7Ä¬ÀtéSG\K>ùÁ¹	0i0’‹†A™M·-Ï]ÖŠó›ÂÜĞú=Øı{úàùlEW1âÅnÂa\¨c‡^›/©ŒŞ‚PX¡Ot‰3ÅrÔ@RljañÄ¸ÎñÈ0s›}"Rq¾„…ŞøŒ?Cse'B7Ó5D×prñ~±`l‘Ü\FZliDhÍåv|ûL••Üÿ‚’rº’Tİp@d³ÒÎlëD7òœÇcàO‡ÛkèåĞ÷OˆiÇè°~YÙ ğ#$¡BÓş@Q~ÄŠŠRïuíúŸó7ĞÕ§ñ6Ö}>ÊC^ŞÖ¿=MúH¤ÇEõz¯Á½QÚ”J­9`‚ü’›öÈsn!÷ıUì¸7jL'fã?8½ôzRúéíD‰[„^º~>N'R±ô¤é8ád+MšWFWö]çˆUïŸ–í+Ò?Ú–Äj¼6ìO¥ƒï¼e38…3È*c4B9Ûn&X
óñõèÁÔ»–œ¦O¾bÇ¯JFªß®T˜AŠÃÖÓD?e0İHš·y¹Ÿj]C´¼+«s”œ¬³ê½ev%è8:¤Fñ¹åÆ_ô‹‘v?áàñ¡¤áç)gµ³0ÍÎà_=c°vøIrCFúY×F¾BJÅYJf´!,§¼…QÃò•Qì¯X¯’Uw-®ÛÃZÇğ%}*Ù×ğ\1E:r„N˜æ¢¦eoÿè+ó›ãDÂ†WˆîÑRË4¹ƒû»˜Ç~SúvÙøke.Š,&•6VÎÃO`ÈN³}­uÑTQ2Ú@êï.0Ï5E\x¢;c¿c¦[‚–úÜ·ßFÇùs lÏiÖÂÓ‰G¿æ->p(4íX/¬˜™ì¥ã"Ãfåe×Æ°G!ü3<„5X­Qkd‚%OÃš·õl‚Ï4Áƒf%°7Ÿ¥Îë°Çö“‚€Hûcƒp4§İˆI•åµ[eÍú‰Ep±]‘˜Úçæ“'tLŒçåq1ší¥©âÅÚÎ)"\,P¦Læ·MsdÆeE9Ûøşåƒ…ÀZ×J}:†A¡çBÛrí•{dMÿ2@kSÉ»®/½ß·f–¤Ñ_»F1€Ñ@Â/pPt"Á†/16ÉĞ¦Lg€õD´vj
_t½Ø|•ø~tÑAª·¬N‘ŞOçl(&éÈtl‰Æ?šÅÂ¥á<JmO5H®ŞÇøR®H#×õràíıÄşR9À°£‘_‹)íÑõqK•“+4WEbc÷xví8¢•ÈnÃy~YàC2Åx*Š”Ñ3œÊÑãïélÀüNö‰ÿ$"ˆOg8©krÜèŞì _Nü?˜ì°9¬“v´ì ‰•\su¿/ Ì˜’ÁÔ:•Àhğë$Kû÷–ıù¹Ğ.ªÙÜäjC¾&ƒl¥…Æµ:!¨…’”ŸÔD„42:eîÜKAÛ(Ü‡w‡Å‡‚ÄkPí#rÂ/+˜?Ä‰ÅÓ7‹±íÊğ8\™ˆTëšdŒn=u&™ë 3š÷Çˆ¬B·;Õ^Z´Wˆ„òöAì)Uäãun–Ÿyyº™Tºğï£zb’`Ç±qå(|¹çgÒH·å#½;!zL1¿ØÏ	÷I~íbdô+³¨h6FÒÙõjBZb¨PÀx%vNÍø[l¤©Óší±ï3¶Bh\ø3àpâİ~¿æzĞéRˆäÕAIİÆãA$¥•­-‹®âÂHN‘Ñ!yh<îÔÅrªëëfnVyé­„R‚$³¶™ÿù¾üÑ¯r7nS\zõÓoØCÙÙ¬±N”©¶,4}f˜D^K{¥Ş—Õ¨Z*‘§ŸËWÖH~åÇpÇâ®¸!E²S,;¸[™k•‹ŠƒØD½sDI)¨B:alè˜Ë HWOç.w›³ä¸Ğ«ck,d«2›fg$Nhgw‡Èª“_m‘ÌzML#2-ºM^di€­…ÍAãh¹Õ½ñİÅuqó_P ±rãæ=H¸±¤±rbÂÕ·GMd×Ä¹ËŠâ¤:ÃZ—)zøÒD(^êºaCæ|Éó¾A¨}ø$‰	%a7ş/–Wï34§•Ì+oX•gqY—RÂ4 lzÙƒbaÙ+oa¨
#µ2`8¨M{ªP`°8ƒğ¦Ø ÕzË–" (p|(1µTôHÖ%ìs÷¤³+À9ü8çûO{'–ŞGÜ¯eã3¹uı!$]?„èğÖóPç8fÕã‹;)We@h-àúı  sí‹§¼/ßªáßĞü½ØäZ¼î	gğ@AŸÒRÄ/ù†Ô†C®7Ã¯•Ò0ÑI©YådÄ>Ú³X™Yó¸¨C¿Î}GØ(m¼—Â7ì«²—ÌAü.mf<0*±ÓÅ'VIrÌ¹ï-(;ÒíÀvÂ
¢ÆëÙzä$soƒ(0ß>™Ï°ß‡Î‹Bœ¾G6®à™‡Û°êĞ’ìÏzˆ®—rõûÂ¢­ÉÉ[Eğq"Á¬T=TÍ†Ñ€Á©h6ÈÎ°«©^¼r4È_½ÎQ4ŞQ¼T“ç{k.aÛUmJ“ª¤•Ÿë˜\†]±)&³©—Ü,AéVºÁ´˜óV$±›/Dhõ18ªÏİ…	ĞÜ5³¸o¨xĞ…2Êë^}›È{Ïc*‡z©î¤…Â,­~ øëtÿ†ßğ0øgCBD`\©³°*£ãJ¹€áÖyøª­S]d’½¼g‡Îc!ïÍ£ÅpödwÅR™È4™8¼ä­IHûm»Æs(ê†«ó&x„Ñ.7©™8k´úûSra†ëœç#¼ÂÅ•€IeW’qKÏ­GÕÔmtî-Æ÷;lT­Uêã~øÁ5	ğYùí‰ŠC)ÓÒO“íÑíş1XäaíŞm;œbGSİ†UÃ‹ûµy1<!Äæêà5:æ[ä™#â†±hmho¶ÿ<}ÅÎuFxÌözÒàU²·Ù>–±“}¢‡Q¼®×–€š»é1€bÿ¸»k®«NV°Í#8hŠ?"”/Ø™ĞÙ&l»¿¸M×2	í¼E®7„WúÄÏÊıõ}KºŸÒbşŸTìÕ1²¿/c$œÿúú|‹%Œ
âuOQ€£ğ1fÎA9ùë3åÜQ·_X˜·İâ%Ş‹mj¤|Õ¥x¥â)›÷{.©S©&S,¹ 4fGQ|÷v¾MgênM“”Ò‰·ÌëÉ¥v2´ ÌEÓ,¢]ÈEAWFÉ|WüÔĞB^ï*ÕtßE -óï¨TW¬âƒøïËÛ¸Å?gá—¡®Sµ9•çë”E1ÇËe™µ¨à3ähá‡l‡$á¾[»j5[½oÖB?úˆà3‹V§Lû&TË8‘­QøÕ\!D¸,é=iO§FÍCikTGL(À²ëı+Åd;jlDNñ}xÅİ]£4’öÿ½ì†9Zëa»)•m…Ò®ƒ
„¸D%šiÓ¡Vÿn.ÏCÖú±$H áæØŒX ±‘Yc§ÜãYD­íHıÍU^ıG:Ğ)~êÜâ…±¥¸½ót$.ã£XD²5‹zM—Ÿæn>`o/`›iõf#°è[ÊAÚT¨?İŒ ªãbh±âQ®·E–Z“Ï  º£¢N\ Õ¦ïà4Ô~K®­r+:…^ƒ1ın.>>Âe¸gŠ²¾ª&1w0áL—ªov×¯¸yMƒÓ+ßÛ1Ày^`‡|Ñ7/²ªP§Æ”º3öÈ<ˆ<ªŠq·ØY‘™¸ŠÀ‚Iz3Æ?Nş¡K#,{°M™EÒ1KBáÙ^Z2y»ÔP@’íÀõCÊa)­Nî£R´Ü®ğÇ@›¨)Öyn"¶eÓ¾Yzp&¹çÒW)Q/®’?ßpJ-Hƒ$¸Áİjñ<i-ÛÏğ=7¥Ñç ÔPB…;êûnê2M¨Ğ)²Y+@ğÒ"YµøÜÒHBÖt&o‰OÌgÉXç•(-ÚŠRåg¬údô%$ø‹:ÀaË†ë¶¾kÈ²‹?›–-?ˆèä["kÊréÆêóqÏ”df¬ã38¤Ú¡I+ëwû#cQÃ]˜T}ö.pŒ]Ò’@¤¤Tæ˜:5õé¦'®gz‰%Ö¨7eÑ,[qolÿ«‘ÄääÏññ·áÒÕgÑ´ñôÑ9âCì@z	Æ°˜4N(-VEµ–~~eªŠ%ßiõO—C”)‚ÑÒÔÈÔ¦Y—Ïk{§A›)Êr G,Â äÒø¸G¸¬
¯²RÚc›,5ıV¹f½U7"ëÚ„:1!	¸k¯®I@C}V*+jÃ›À‡2©‡úZ$ùnƒn<¹
yÊ²Lg~äùXZ‚ñ“~8èqWV
ùÂe
Nâœß1å/æB_;Z/PÀ§kqu/ã¸@‘qCo6e$( ñ¾Æ?'qØ_Ï	`Q¾$z,çø¡U7ÆJÜâêì	£';ºÔBœàAu’fİæ†ªûå½ Aşúòn=êÖBgVŸL_SfWv"¢É#Q1ÉëÚ»ö¯#vø˜Ï"ŞÑî æçí»Åú	/Cf×Œã9PÏõ£Õ*¤ˆşZVC±=(íğ@­÷uE×'÷–ˆlŠª’ÓVGDèå]¼Ñ3&;š~+–ºoÀk‘E[ÄDóg¥aR{ÚYÏí¬ hfiÿPtx{HşÍ
Šq×›©¦lÁ»Ñ!VkJ^a7ã€»U 	W-¤ÄÉiwèxoWq„˜³„z<L¸UÆßÉ
äé#;¹ËWê„Ë¶ ¶RÊÖƒPw°…‡Bpû’„¢ÜğA„ºc ÿ¨by§ ’ÅŸÜËXşüİoN£‰ÈH-ÑµTÑáÚÒHtÓ¦ÛØÍlÏ‰—ÿù¿wJK–w‰)iOãª]NÿiSåP ›¹%ÈÚ~şƒºY6º]D°ÊN*.é¾Æ¿QîÛUÙ‹³şü¹HHn‘Ó'ŸÔ½@)‹wd€ †@ORÔ·7ÔÌØˆDxîÖ¶ê±e˜£İÑbøâç·k.Ño»p”RÍiE ƒ¥ŸŠG#G'¹]M¢E°ÛtœÅµ2¤XÖÅÄêŠAaóıG™qŞ oŠŸœx¢nÈ(×hÀ }‹  íçiZx9hcûŒi®Bkb'—s¸c¹Æ¸õü³î­WÔÉ`§sËVvªÌU¹H	kVJPÙ½sğå¯ôíX¬­g™¾T>v@îxjWü¿{¶äöEŠBxµ­¡¾lúA:mU .÷qâroGÅLÍ|l‰&ÿ;‡î¤”èÿ%|ÚH%'ˆ7§{àÏ>¦w½çCÆI‘öGæÖP\Ù0hC¢pQÕ«É´sPvWDƒÙeÎ²ù#ë×d„YÌ.G~vH×?lëêTÁSò…ü¿`T^ã{I›—êÉÖ"(ZÚ¦…•-¹ìÆ“ØËÿŠ$£~ÜípÔCæƒëĞ¸_az1±Zjÿ²TÌÀ”ªß£3±ï¹—'öv¾©è‘+ªOúºĞQÙ•nAáõB  ×1"dÇ³_€M ]Á›À]7DFÇs×Ğ »Ï“fÈâª#RUâ=¥$Ïóöâ_|î×Tòq—FÅo'ÿ›Ó×—AO"éÏ…g$ÒºxSrHÁ³¸{™—~NVÄ#œ‰Ê-Yß¶=Ûjâ`†aš<‚ééÂj$¯i#âÙï™“{ÿÀÆb­*
ZÜå0®fçÇ·²Í§{Ø3°ú*ƒIfBµ$5BÀ¤×C-¿~¼×%˜é‰-Èpct5ÁcÏÒTd—O¢Ï’xåOo¸A§×ï·ê_f®ø®4Ñ ê!üƒ ¿ğÒø	RÈ¾¸jëX>>|àĞZ—Xàøİ4½¥BËàV~-ÌCDÆÅ8„~µBĞË àg÷yÔ[ï”~tTø–ˆï @Â×ƒ>+Ğ¸ÁìÈYDtuUÛÌ"ÅôÆd³lObÏÌı!ùçŒ×ó1"éG‘‰@GDÃĞÜµÓÕ(ĞOíêíe³’Ìì
{?èëîã÷²ÎŒôè`=  É_›[‰ÀÂQùŠò÷ Ü¸½bKu}#ªÉSâYkÍ”rs6Ã]7q3I’2TÕör’bÏlCñ_gh]Æ;ó/Ÿ¶,y ¨Hxè2AÜî/NÉ‹¦ØÄ˜µŞít±×K†ˆaìÒaMXé¸«r™/á5†Ô4¥.¼}bÌÈàB„Ï¤9ÜB"ñÇÖ€KqÓ-ø±ê‰æ+Œª”yöC[D,i,[ƒ›Ç¥æıD»ÏgõŠ¿oºú<İfx›EÒ9_HÌ¢E*ìDë¨—öe“+!2Ù¤æ¤ª›î-‡o~ô*–5¹öŸjyKƒ«Ô«|1$]Š eİŠú¾$Üšİ;Pè‚Ök-£V¼Í’Šº–7ıµ?ğ|»©AƒúT]gÆu38;ŸNş6Ë
"vv¬9Ñr°\Ø­¼C³¥jÁ7Ò'W³,Ì¾’cE›ß¤–™DuÍ+6¤ŠğI$¯Ô'§HÇÂ­8 ö’&$ j¿“pÌ·™y#àSÏäò*—&hÀ5ª6îÈkĞkpA«Â±vb¢ŒÚ’(°ğÔJÖJùs«M­ÂM?XœÅkÅ¬ÅM­à]Ú€LšUn§•Ëüêèí´ih¶â…ß^SOT§ÏQN¼cõ4Ó¨)F”á3á^VV|UZ_:«ŠœÆ‘éŒ4Max*.ëHYÙøçlÑ²æmÕ	w	@ğ¿Ã}iWÿÎ¬D½š†%$ŠÒu˜‹ƒxyÊBü–Uá¤çn–2cGË¶¶*F§i\=H©Üzß®a…¬ù\èş˜³±"t€HŞRïk}¾3ü¼Ï,™¯Ğ—`ò!‚’8LÿuºM/{êØ(D”iÿKS:f\§àÆKĞÑ|­BÿÒÁ{0›6gÕˆúÉx[FR»mÊ¨e1ïššñÙR…bC†SçÖ ’Ô³EÆöãŞ™ä^¦¦öA6¿v˜Û†}lÆ}/ZT.r óÂ_jó}¹ä/)Â³·aL¯$UĞ{Ám’F^ö–Ş"5`såµ( O·lV‰¶ÿ€BÉ!û|Q×á5mX üBãr0ı>ËÉÑO©±<G]ÿ§õçá2hG¾ç!CÇK¨=<„,§ÕµÛ‚s*=êê
U&åG©Â%Á/D'åóÙ!-Ø“ímpéó·PçD‚\=o%Ôn)Cş{ì"û$Ó!;eşk¾+K¶D ú2ÙCµ4¸íŒó×ãïTLù(ç6)ˆCnI
(lË|Š;…Xò{W†¼Ş„’‹„Ô¥Ñ,±ÿMş”ù-ÏÙVƒbO-„"´Gq˜a?¿Ò!†¾ÔÊ0şŸçÖÜóä3ø.Ê,$¼)À®è°Ht}áÃê=Ğã«¾ÚrCm=Ã©4Š¾8¦wÏbZTæš!dS~ÙEwÀwÅt¦Üpg™\áˆãñ “3?r†Ïü]&IŒÇ…ë°y1‚ò¯¦HAE©ÍÏd¼Y}ªÑ8Ó†É4Ä‹ÛŠ4ÒO¦6¶ÙOÑ “Ù‹İ7&ˆ°eE
ì¾‡y»ŒBÀã!e°‹kHÄ´ÕÍ`-ëùoÊv¶®Ù²ì¦?³òœ4™f¥ÛUÊ|TÊ‡´ú1p³¹ã¹Å$Ü:Äx µ
b…ÌvW ã_°”QÏ.„ŠY½Ï.¯6'Wº°¸·«	L”ûQ!ß~*ÇòquSÄ–Ñè–7)£°4R§ùé¨©ÑêÄÜ²3ÆÖhf÷C0È{B`õŞö”ÄÌ`Ë€kÅ®!>sdZîçÕ¥ı¯ki(ZYpİ€Û'bvûß+a
úô×%¼îmôê'=SQyuIA‰hƒ°1¹æù±D~[³NÁ{°/¾p‚Eaør¹€~Byûÿ¥¬•V)‰ê®Õµ"“ænBŞüK†Dj>yOıó¤'¾õ#³|V’gÇ·GE}­·±ÕùIf‹ğ/*ÍæÀ¡‘ã#¯TW«!U5—ÁQHö¨34åğŞIøØµĞÛÖ÷¾Ä1Ğ‹m\±Îv ñ«•F¸WüXüoüæL$P£Õ²ù—oGÓyŒ!Cİ>sŸ«Nìó;ÙÔ0ƒ9a¯¾Œñ·íÌt=gcÃØ€2ÆoËÕ¾½`-“§Y_T³ÒİF9ƒZçf¯‚Îw¡9_Úß}¹	)–Ğ­err)AÜDëà/ùõç¨z7ËÇ=:ÉíòÃ¨½Ò/êŞ¬ÎnFgÕ¹Ól(Í¤®*™pÎ‹ÏŒz÷¼Ÿ^†šÂ0ooìøºÅ¹İÖKšÚ ö2ìyi™C
¶…jşØgüà_Blì–À¼‡ÿÃ¿U€wÇwQO•K3nãù¹	q_šòö½R@Ê5?,å€Kë^xNz=ÏÅ4G£§R†ô2ÎënŞ²î9V¬Í~GwÔ—¼ù[ DÇ(–ùî!<M­É„¾×´™
8 èf‘sñŠ©Œ[ØÓzİILµ˜—ôÕk„ãPÀ¡Ÿ©òŞ/Cêî¨íÃí‚E£D8®¥?Ò¸í¶ @¼šîæs–U"WR#ÂàR’äê	A>DƒF¡¡v0æWlÑÊv‰Œ.ù½°g¯†ôø’Šx—"©U2¶Ğ7–²É8óPL¨êØx:™´W'åğÍpØY8â¥lƒ—.Aë /¤Z ûN‰İ
€Ú"“³ó|ô¥Qô†ªGIrä y™+j6H;íÂÃAdËàÓêéõ¸İñ]¸ÿ)[
J¡vG¡™?¸-1g‰Ãu)¢¯QD’ÜMåZÛ*·›&dîYÉÓ#~Û¿{éØê®ng*IÁ#m|?r©êœìá)§ïœËs¶IğrÂûòÈÆÿ>¨=So%µq‡ˆvÄE{ÀƒXb=BqÕw'àé¹œØúxİÊpšÚ$—xĞ'o’xˆÃOLª*MœÛí½³ Ôô‰l˜óMV¢h||^ªĞ‘Z¥ÿõ¨KRóó7É·˜Sâh=ÁtıĞ‰î¾™Ë1!æZ2v{ÍV}(ŒÛP‰=u¤`?)±!t¥Ÿ÷ñ*u¾õğN»³Àö
“,óØrgƒh72 ğA­×'CƒLú_8€Ç46yÆöU(èªw#ÕâÛ½eÍ¼Íá°æN’*ÑƒVÇX²c0&Å	_ªy\8àÅ&–H€öw—ì¼h1>MDF½£7æzp?Z»zòsP"_hÂ	‚-–>mu-+sÄK–4¾$"Î®¯	–åıjÑä3X†UP’Øp€øæ¬_ç²eõşÿ.’Ïñ;œYı§ˆrR\Cyv´˜oØØKã“Œ±¸'_	?º½×c¿ZwÚÖÓ>øŸ”3œÔÇÓĞm4í"\ck H»Ys²ŠĞƒn»GBÇkVÁ8è3Ìš1„Â“®Rpæ·@?’ øÿH5 ¹²ÁÇİÙ	XD²Ïo¼àä±Ÿ4nı«4WùV"Sç:8ênˆyÇÕN÷ÇYí]|¶Ö§Mı³y:ç|ö\<°K²,'¥ı<§-ğÃ³wåÓ›½ßQ?d>,fŒË•ü…	Œcpí}âânÉÆ9K´äz6ş9½³d®Š´¬Zb×ukVã¸GğõÁ^*—Rr‚i±’PbOuË'ŸO§wZ¾RÀüM%-J(ó{ÉÚ®ùóÃd*v bú1ØjÂ¡¢ƒM§£¤ÔòÖz–QeùŠßì~'Ñè¤¡vçoÙOÈ6_Ù1Ü2³áÁ¹}Ë	NïÅ”'kqLP"dgj,;ñÄAÓéÔÚ–½åqM{"
*´IA±ÌRğb|qRut¼­Õ.É'Ïa¡Ö¾’E™Ê<LQA^ß1TS¶]›:¯j$^’EÕRaVõ”G!c-ÌXèÍˆ…ºÏw;õue¢.‰îí¦8ñ;a1vŠ˜C›„¼ıgRá)¶”5_„Osˆùó…ç^D‰DVá¨Ìçb‡Ç|Êrİe5ÆxÙñÓ>K®+ãsˆ­Ğ< 8=ªĞ,$"¢ítÀ¯î1jˆ¦»Ú6Ğ³ß¥kûçôb¿‹¾&—÷_~:”±tÆølbÙneœ{ßñO~46‚~FO‹€ÿ•H†Ø ò@:AªàÔ-òluµº•Î3à.ÑŸşÉW jù¢Æ'I¥/ØBĞqÀÔSVTª¸¹È¡·7‹ŞĞÚÊhõJÍ	‚g9!Ño4ê&m•ÒÂ¸‘Ş}VR£
-<9±½J Ä¸{¸W5Œ€,9ãJqåyİy	™„[_zÈÎ^£…ƒˆ­™ziJ¯ûƒ…FÄÊ§EãMÏAi›¼^§ÑîÑùª_,N°Kõ–ÓFßç¸ÃçÃ¤cšµñám÷vqL“¦A6ƒ&¹·ÓÎ']A©|fFBÜ`¿Å½RòWõÌ¦à3ê•ä;‰¬³²¢IDĞâ(ê/tRéÆì[LX³ùûö¼‹sÁ‚™Î!ó°Ù[Eğ)«şø5u;Êq*¨1ŠMŸã®M°õ³–QSúe0Œ+Añ¢sZ@>EûèöûJ?ˆ‹Pûƒ‡gõ
ìítKİ¤{™ø—]DœÎaµ°šv
@à+3ÍàíßAHF
™©
É:6qm½óÿÎªà{lÑG.…®°)£ãñ°œ–7´Àè	@öªSj'Q äzÚâÂ{f‹2pR¿ñGÿ	@¡í$RŞ.Î–¼]\Ëµğk%ÕşsgH>ÅìÚt¿<„ò®V\ı»ĞJk;™§şÊÁË9ã(Ú
­i™*â
²‰xÇÁÌ±˜Ë-d¸qkÉøÊ;¹"”JÛØEe‹«Ò[¿aŠZ,?ù÷Mƒƒ‰ìäß++)/Ò*æù;ù©ıÅW­(g9EÿÕi!òz‚Åçê»E~y±AMŒ*BºÔ9×Np<¼†‰" ±ƒÜ/aôùÀš§a‚wC»Òÿ¡Ôå²ãÒç7mV‡¹I É\»ÇWd­tì{qHE÷É0ğ±Lgr—Æw<"Y”DäÓ†¥ñŞöL…©EH™MBÃñ<ò›l9n³‘C3½$ê€‚º{¹Õ‰Dg;òf•ŠÉnÚ&U¦ÚŠÓ¨“È®ò’ë×bx“¨Ù‡÷Yíãô‡^#ª2Ü¾&	·Ú‹¹ôŸjD”¤»¤L¼ån›MĞ ³¬ŠîE¤®ªga.Â^S+Ee—ô!‰ƒål…– Ä‰ü·‹«Ş¸d7r‹–â‰îF±§‰±]`vqöÎ6Î*DsFO¾!ù9ÿöGé@©{-3ÏšÂ˜Œ©Û¸`«ü¯NÂ«êùC‰½¼Lã×®ËH	Õd=àŸó[)ÛRïT³ÙÌÚëo„ZhH·•¶¥za’b ÚzCñY>+³N…,}âBÔ©Z‡&o1ÏßÜù*úº[üôi(=˜çÎörWä«Œ'•*ÒÓàíYšÜ3´#Rk**Ô˜˜Å‡ãë¤Iõµ^®/şåè´ÌŸUí´Ûk#r€ó‹yÇ&e H¹J˜Ù×e,;¶ùäÅÔÜìQÊE%r‘Árã&érÑŸMfqÊ³€P/˜¹ÁŒÎÊl&c§f÷2T“ø3—B=±ş"#pğ–C.e<çª¼Ê;7º°ÄŸÇÍï°şXŸ¹Ğì#*Ôï)ß{xÊ*º›#À¬[i±h ®ÙÉ¥<:õHH´ À¢ë7ø®kKPé»{N;ªáYa ıµGúe=M´##EÑ$	‡K:¼MÕğ£†0KÎ(øäŠQU¼E~KõÆëÁdTA®¢çÒ>{
‰±)Çøk¤òw~›5õP“»'·ÃKÚ[m¢>T@¼ÑªaÏ)ÊÏ‹âÓÜÚÌ]wº¤Évn™R?M˜@Šğ›Ô}p»‘1 D	q#‡{âÇú~ÕêÂ~ŸÎeEó2êÅ‘KÔÌb
ëŠ= $ß±iFayÛË›aTúa´ã5CUš[p?ß†İ¡à /%âíğâSË¦ŒkÎ±}+û„/ş½ñSÁP,Aá¸MY(™'3rr^}ĞÍ¼ID
ììp™·‡%£W%ï™¤uDĞïh?|OºWH£€İc ün­ËºåÖ¥mË=w2şûÁ®š»'~î~#ª#PsÕL~4±6 nH²ûÿdmæP ¶¤Ëœ‰F«@›Å§\ƒ{HØÌ¥Ç‰7zp¼wÿ±²©0RÌ0¯Y$’uälßkBôí1–3âBıÂº“¥î;ËnûØ|”ˆÍ\lZ ßcGZØX·Ó@úëvS™(Q¡Š¾ye:úY|2j»^ÿ»‰9ƒ´oŞõ>v¢XMàÚ‰tğÿ6zo±šÈ!øÏi@¦Ìa]bÈ^
cà„¬>tˆç¿ÊUŸ5ØÂœ¹¨Ñ‰šeÄN·zÉQÊìÓ!	vtØ,
DZªyÑ:»¡†û¦[·èÇ¨OŞÇêšbá³˜ÅJ[œBĞåØU×xz›©ÏµR^cv4'ĞğOÊƒĞ‘j®xóùšvØ‡ƒ¸`êşš½ö—™[DtÀÀÏØö%ŸMªoé![ŞôHóê©t‡%/ ¥6É©”¶É­«“ˆşÉ"îz‚‹[¤aØd®TÕí	uÿMæ:YjF¼ÔeäìgTN	eŞ™Ô#Îı|viÅÁ[h3ÍĞò¦ğ%=şXºÑ€·Ğ^Ü¾ìj´™@6ÇœÍQ³ï(Õ™ÀHÎßÈì­.}ÅR¼G†”ûñüätf‡Ç ”ñÃA½ÂØ•¢R("ƒ¨Ñõ™Ğû©^í- /pÃßj$‘³jèäM72"ôÒú-–Ññqcq¨{ïãNóëXšØ…Ÿw²çú”-Xƒw‹!Âtæ>ÈŸÑÙ–V¬ŞîŸ#˜q¨ô	F”ÅŞ·0‚¨ûœêšèÍvBi­×@Y¿3fÓè	ÎÉ% ~WİYŠ’‹ãèz±N3îûÍmÛë•ÓCcš«¨¬¯ªÅ}-œéR ÚQÁÉòl—Íº…rÂP8³~È¼Í©&|gAu+¨hõ
F˜cÁ:Îx­.¾ißç’óĞ	­Zy…%éİ_Ó48[°R@8Øì_MˆQ¡ i÷ˆEFR‘;µéØ¦™vöõkş­zL*-÷ëGÏ‰Ó°¥Û]A¢%ÜßÌ2À>†Úã©‡8:ì¥ç¯¢£PeKõ/OÔ~ë”'Œi¸™®.bú=YÂØşÜ…>"_Bÿ{%İú
×!Ô”¦RÖÃê(PGÒ5bù‚ğ		°ëªêHšÁyáíœn2I9èØóıd0FøzĞÉb62ÄBŸ"Ê‚!d<•µ$ŠqL°‘`îÔjJHc9ıø_‰’J CÑT÷/íLªívÉ÷z­m¡ë¸ıJaº'D‡´và»Ğ¡OÀè^¸,åFQÿkX$Æ*E¥%¤ÛÓÉşS€P²Ã'ëesXĞÂev:`W¿\Öl´¥Ã_gj£gE#¾ã»ÇÄ<è{mÈY%â
d¡¥{ãÿÏØ¼x6Ô¤Ö$ìZ«f‹¿Oˆ$É·|ÏÄVª€¸p‰<pØR¹âk.J~Mé‰ÓC°¥VÎÆÌ‡µrV¶Hùç€X#l%-]_ÒİºÊúu[·LBùğ 0.hNn^ ÛÆÁ÷ZŠÃıı şƒî ¶òÂPxş¥çUàïiËu¼Ìî%V&ÒÌ7>[–8Fi÷ÄvğşÿëA§.|„á–—¿˜AQõ
c)x¹±ÒG[ÛÈğUâó'¾ÑÀÂm†ŸRbHBÏù‰µ˜ìáôYğWû­şº4«½ÆIäÜæåÿÓëöà˜Î·Iª²H;ƒòC¯/ğ‰=`ëNª®¦|õÖø!*óV-Ç*‰VgW±IU¨ãöı½€^'O57£DÍ¶Q—õœŸ%/Yƒ=‰è{•_,KÒ6Y²ñıî„Ë¯ê÷¿E¿ÓÌ’Ø°œvoRŒ,è™Sëy‚ÿZÇ.h1¾t¦ô†½UûÑé'é iÅ¶YI¹A?	lÇ¨×‚¥’é/ŞòáéˆÁ90õ‘<’¨V\?“-&ˆ™Í+#CSz=bKP¥¾£¼¨÷6íuıØk’6s+;B0f¸Ê·õÉîƒ ?ìKt"j‹,'p:LoÑÀ‹ñÌœÛÃÆ sË+)Âó_§OnSš"åLZPŒAdÍ!vU,#J^÷%{$ËØo£çrb«„Yğµ!ãhXhñx¶'y*I&€¡ä_ïSRì^ì~œ-
à•òfŒÑ[“5ÃZYş;ŒÔ×Ø)8úÖöT@P‡µŞ-ñ~˜°m®%%ÿ\†­&Ôˆi†¯—Á7TZ„EÜM§j3©×()y'÷µn;ü	ö)à•÷ƒÅjá‘Ê¶(ª´TmÛĞ(ü€:fæÎÚ÷ú6"ÅïÜÈM„#G<Ø´<œQ(E
¿ìÀì%Åã¯êY±ø³`¾­á+ìëäĞOÜ¯Î¯šÚŠ§FÇ0TªºW}(eO!æş°{ ıá[Ü¶nõÌV³I´½
mP—8˜®^oxŸÎÁoøt"¼à‘¿r´C17—-#@\îÿ¡ìËã’®µN®Xå*ø‚Há[NqÛŠªOğw<²3Şå—‚ eÎ}„ÎgMì½È=×ºY]€9ÌLZıúOãÜ0ÛŸ
¤oy
÷O!2Œ¤Û­Âü¡¶Ã“zø‡¿Xm-V>„T‚ŒâÕ`¿"™İqSåZ	‹ÙáÏ°»UÂw5'•%yÑPœŠ§!:Jşñì„¢?ôzµ»êÄÓyi¿¹é4í	$t”ä£jG³ÿ¤—R/›³²—Ã;ú@,´$†ÀèGŠ
V ,âà½âŸä60E·/opé$1¥"]rF4
&ŠäGPk]ş @º‰:ä!±'·²Ô·lYÒc+¦mëkÉid×	ÕĞ˜À¾¿£ULóEÓéÔtã Ì\Ø}á.«Õ<ÄÕjàÉrô	K-4£Ë—TÖK¼ÛõjÚ&+ˆ`£ø\nxëoèLşş¬Õ7AùÜBğ}šã,“»KÊÒb–‡¤L'–«Lú[6!Q’«ó,Ô¦I€Ïîj2½ g$6¡ŞîºœQL°B©HI& ÷üÏõ5L›öfXq ä¢Î%ìŠ^.sp N®æ«°HıØkÀ°Ña-¹Çºb9É,qbé|¡	ë·@,¿ÖŠÈÿçRÃo-íü]ÃFZöÁ½«å%‹K»Ú¹Û¾ß!á-6úß~Auô«a×ùcíG¤şÌ¿¹zO‘/A¤Üy/ÎÈ”½£ÿYºf´2ıÕ÷(å\ÃZOÂ³ƒD­¢¶gİ6•·„—è:f!òóSiqÙLÓªĞ&ù	gÍæâ7¡~I~5ñ&A]ÂŸ• ûŸzE6ÆÈØ¼f"Ç2š!¿¾§ °Úµ2v-kŒqve"Ä&w‡za+í™ÙbkrO€u2ääÌmê`úOÛ®Ãš'ø&¾°m<‰½Õ¢µı·4·¨J,µìi{M ïİÿ¥÷ßĞ>¦:õô= 2‚jµÕsA<äT³a†R£µ +³AÜ3P(ã”2uí˜Î·ˆí´0ìì3)‚¶Eâ(	`…a@4rô‘Ø›àc`ç,Tê”İF"rw&5câ+<ËËË•E@Õ³@:HŒÊ4•´‘øÖ¼Ø`~È™v¢J}â@¸ËÍ¾4ÓáÁÓ÷ê¯{¶+4ËzâZsÔãqéZ˜ WRNÄ§ëkúz)´æîC“›wõÊÕœ²vxÀïpµÛFÍñ†àúoQ ›È±4`üÌ&sLÙ€ ^X$]—×càÕ>YšEúFD–ÅòËäÓe¦ÛíÂ‚qsJ•:&Â9¶œ×ô‘cçêéÛt06zŞN½‹Å-|ÿŒâŸ¾&¯O/&ø4–ü¦#ÖRÁBwÕ‚tb®Vk/b†ÀHšŸe¬Fn}‚şí5CêÂ‹Õ¥D5ò’5ã¹ÙvŸOëëÕ”ç0-:W]·ùjnOUFj½“
ÌÎ5y­­c²éEò!»ÚW{º ^vk.½Í#H¶V\/à˜Å.>I]AÆ"ã$Ğgô]½~!ÖC äÿšI)QZdi&=àÈßûà¨=ìNô…÷4õ	6àå‚?p˜GCW,E»˜´‰ÆD\øb”NÓùZ‹ÙåQv\qïñSŠSÉŠˆÊZ%„#O¢úñĞ&:‹?í{WÑÌ£c,Úœk’ŸD—GÉê“_à#W @qĞ p¼VJè!0™†ïYl†Ï,şèV¼#xGœŠ2ã±-­L8?±ùÛ›AÖ“~‹î”™µ1&ö›¡iH5¨CõLØRúu)×~üÔøa·g"š# ø1½Õ¼Íh· 8¤Üä^„í­7·<XF‚ïÌ-8«SËJ*E†$~×èn°kÌ Tñ uK½ªÉE/¦ãy”ú˜§!ü(ÄAUê·ŠøÑßŠ•ËXV®ÓÒ¾­F?($æõ~%K‚!qD×<šçD¯šìà“ˆÖ1ê}H%3¨c„ğÓ©ú&S<@	KAü,'ùêe¿IıØÀ
™½0•…¹´Z…\ÜåìÀÏÅ+¸®HıHtİ¾2DnUFòáÅ•D‰Œ<rïÜD—ÄH§^
Ê	Ô&>\uïå…;§Œ¥4p³ğÏUH„?}&7ÿæaMó’	ı?qŞxû#™™f³á~ñÑÂÚ^¯Xd"kÈùJJn}Ë!V1gç:ôåÓò“oí:%¥°]û€ìcE íšdüÑJ-Ó?+³¦,ïµJÿ47´tGÚÉÍ7½·¼ş“¹jĞM‘‹û€cùï,ó8­«š–S   ŞÏÊ²ä†= »µ€Àhg±Ägû    YZ