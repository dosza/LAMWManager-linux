#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1076325429"
MD5="53cd55411db1e25ab44a7e3cbcbba775"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22944"
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
	echo Date of packaging: Tue Jul 27 12:29:05 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿY]] ¼}•À1Dd]‡Á›PætİD÷½ub
Cr‹ÕOKùˆ-03l`vhØ¸IO)†0EÈø»ß\a(o'Ä¾$·=1+ÿ»¸ü«$Û«_ó—Ê§õ	ğÕ‡ºf·:ì‘ji÷ı½4­’PBd‰à&õß?¬=`L0[xW1×ju$øéØ-ÿ–	Œâ¯ŒŞ¥‰®©Ã˜²ŒI²sĞh8¹ŞV <È{9bÄ–w¯aîÒ¯†xïßDëùó2Â}pnÎRâ‘ÿÚ(hNkî¶fPB¿éŸ ¢\Æ»æ8NP^jÉ©Öc/4é¶’µu9Mßªá¡7Ğ¨gòä@BW²}>ıºçÄiá7¨“Ğaú•¿ïVä±49yôï|÷ƒoŒä—'XUqyWgéªŸS~~Œ~ÈÉîÉĞA{)âê€ôĞ(W("	IB=Û‘x|GXî‚´öº}»î®8ã	7ùKÿñÏ¯ü‰øÂÃzk7rNõRJÑ«‰P0XyÁ[^mÕ4°é¬Ï­¦øfàĞøeãMÔÏ£“‡ĞÁ{íO–Mê&üüĞ¢$bş.‡[tùd#;ÆÎy=Ú–rÚ? òÒÓš[)Óî¤%S®pll H—JÏ\ÕOşWVUÄ»iÈå°´èU}@´ÅyÕÜO[î¬DSQÜ²w/²]€¤³ÏÑ©¡Î¥‚œİ$(ìA›·0lÑëÛsÄ7¸©[n¨L÷ò¯âúA–<Un+ÉÎçŸ[[[FâLêz&ôõïÎåC{-?U#K•Xéóà—æ4jéUq˜ˆ™»çÉJTSu=ĞÖRWçËğm:]l›M¿½ÔÃúñÀÒ\Ÿ“¢0(#ŠÄ>¤ä –elßŞK7ROøå}¬Á8$¾½b…ö‡CVâ”Nò³ÔD·BH‹ŠœºŸhŸs
!¤QÎó]1åÙP¸ƒz¯U‘¼,fÓAÉ(ÈŸbìÀÜö—0°Çâ"U4¾´ØÄ3ñªûàÖÏúÒe˜àzŞ‡šÜ’ö¦Üÿ£ nìjRŒÚ'0yYK²ÄP÷©Œã!“î^vå©ævÕzêáØO 7¹x¾RlÒçdXúíŞ•yÿŠ5E±‘GÓ¾×	<hÏ(¸¬4”±aÇñÌÁ‘8ŸÿHË$Ä#zƒ*ì‚òªØ¼w—miFÔ®uÇÛT·ÆœÊ¼½X|%ƒî¯v7p±ëô £HØV>ÚéÉø]¡|»ÃĞî¶:äDı8)8Hs®sçA©\ÜàÓyÑû=\&õîk„‰‹C9Qx¿pÅİ­iÂ%x ÛZ|Ò€j•'M:´õùPq¶gº!Ù’¤2›Æ›G3k=ï):hÎN%ÑKHNùÌÜMÀr!	kÅÊ ø0œŠ!ğİıÛPÕĞŞ¦kÒèxŒ9¡|ì
éyŠšû?ØËØ=$ƒ±Pu"	ÖÛ™Ş
n'„_‚7ªÜjS8ÈÁ°ïŒCiìWw—î7sÃ "`Ù£÷âr?ìÿ™°ó©!Œ„ò»øÃ$.:J!8Eáçd‹ ÄVsÉ[ñí”HŠeŞy±ã+ï“öÍAÈ\ˆö«±œÌ£ßäc/8WÛ[ó8Sy;Û@¨[ïPI[Î; Şıo„Y_ÜhDR@´´’‡*
Ìm`Ù†‹ì1õ˜¨ºx/æ5øı5E."6Ó_0€EN.5<â),áó°üí0Ã$ÅµâX3DQ¤¡X²ç	œ!5“ÒL<³–áíò¹€–Gâ¶G$U¼=t{ ….j±	9«õãÕOFw,î¼X›PÔ'Dø=»óÜ2<BZşPéœ1Â%¶á[­Øz¬ˆ¾
’<Ö„F^/tÇ—°s<ßÎĞÇ1Í6i¥?;@?ıƒ–iş­
>½¬‹OU#¬‹şt‘¹€üd!X*Ì TVS¥³+,›é=hpk€~?¤ì®µİvÛî¥ ¯ÙIƒ*´_´†vˆÒ"$WªÂõÛä<›æÏ³¥t`©.$±å£/€‘t­¤¹¼õT—Ftt‚}ßü)|b¶-vâ¡Ÿè˜nÇÁ¦rµŸÍbé,‹&zô(h\pP!ªc-ªR#²!×ê¢ğm§s<¯Ğv<î¢)"ÙB¾>]ºNÊÁBƒU6¶-@ªem»ìa0Û;dnv=\òŸ³3XõyiUÆwXüŸøŠÂ |éÔÏ<­”*IƒpÎÊ !öĞğZôİy…Kjy«/ıŠû¹.„šôEûõ”¸‰ãJ#Êı¤`Z•úr«ŠÖ3(Æà2‰çº1Ñî-j«{øSQâÂdå½ş(ÖAhtÁz—rºàÕøà7GŞK¼M·Ù°( /¬‘†İv:ÆScA°xh8’|¼úØÔ1øª'¦÷‡u#ôØ?ç+’Ò0Q[º5êÆÙôÀŞz%V‘üqq{³G©XuøbaVr½§$hš?™¨êmlgI#ØB—Ÿ£şm£…a;Wäş3+†‹äğ–;£YHİÅ¢·I¸¦¾+:AÓ$ĞÎ¼©ü§ãŸÊ°§o} ³ö~³ï€FÆŒD”Òeù^¼Gû0Šï±ÔŸºÓÈî:Àp;Û+¤JùÁuèJó™İŒß[ÇCõıË}pô×æwxX¥ä3ıHİ‘›&P~wIŠ(#¶˜ÑÖQÏ÷cê…ÓÙ=d5ö÷‚
1İL§1Ü³êE”P”şÊƒŒ:X§ü$Ç—êm˜‚™ĞªÛÿ’Ü‰= ^’×*…pƒûHj^½’qîN[Ì$à&ĞÛv˜ ± 
Æ¼ıYlÓ>F÷Ö¬6'r#ÅŸˆúğ9Ù!êX’¸¨Ä%Å!:‡Ó¥›¡fªõv–‚§o“y©š‹Â ¤ë¯ïqÛÛƒİ‹´}—¡6M<å"ãÒB+ÚwbB=ûıê<Š³òŞ_¬²tÃ_F½0=ëlib¿Å@ bÔ*Ù/•¢@màfyş`^®µÌF(zĞq‚±3ïu˜¸ü©Ô¹WI©2],O~¤Öjt1U“Ã-ê7Ü;7¾•YÀqGŒ¨Ka"‹nŒŒfTòĞVÀËok†‡:¹É&G'Š×ÅÑÄé—¯FÑÖùçvrØ¾tAíÔ(2Åáe;J´ÚîåÚÇm!ŞÓ‘hh–%©Œ zì¾ºNÅ¥†Ó[zá­õbÜá¡PšrE${§E‹ 5æQöcñ0½üµì*À®.¹ÖÑ—†Á'C“Ê&J~ õN¶³ØÇúô7yŸ6·3ğ¢UZV¦ÍOĞm–zè-Á÷‰ Şvñµ¹j[¤>(°‚)YÜ ¼U»\ŠS–&¶@SÇ¹aÄìd‡[	n=ÏG Aà	ÊıĞíp¸^ 8š©S‡©’×':_÷gP&×Ëº%ÚŞ›håÆâĞ©{Bf ¬z&J^uÎ#ÙêaE€£Á®Yú}p›BóšôÇ¨£2@©î½$ËùÉ%‘qê*á%jÀì®öıÕ©öAô;¬4_JåqCÑH(ª®¤Ã†BB›JÇ£·Bl¹zjæîİ­ŠhJC><éîÚ#´RÄyPpƒ{Ö`…-ÂE-ßéÛétòï ¾Ãøk_â ÃñÍR­-ËĞ ®T˜µ#Å¦¸=ğ¸#"ĞÅó›€7\¢Èà¶Õ/ÃÙèWÿßò÷ûGP‹ıN¯ÔîÂgCv·&mªÅy£ièÉ9İkishe[‚Š£%~¹ÿlÀ=ó3Âi6vÃz£ Óûô¨¶mñ÷.TJ'”§İt›u¢’ÂR K»öÙŞ“?.—‘Êî+p¡‡>ìÄşìòó[ú>×~­º–çøÎÃ¡ÓÇ xŞSeà¶VÔåtV%Àáj› ¢òu,¼™ÑûïÆ3î8oDßôĞø†)©ÈÚ(ÔõÍr½FË‚¤M¶°'x.¹‚‚µÆù¯¬Æ’º÷˜%ËMŸéòr2GşÛõÌòû[vè]·Ìú$ÀMC­ÙàÓı1Gw ±Ø»#ì X ï8ğo_Ei]Æ+ÚxNìn|œ]„¡ø‚%…€n‚#ÀRØ~ÆMqäéK¦à§aÅŸ(@¦‹C:=Â!jûaƒc’ÆÑonZJä %Ëú_d¤×úÀP*3Øèâã^JŞ{×t5¨)9
 ÂjĞªS‰‹i­V…m­Ãêÿ õ´(u'„ú	™j¾0¿Ìï†ö!Bó=&+9€ò­0R;ÂŸR×ùùW!ÔæJvgü‡6›4çxÖ4<‘¶´©ÃÑ|1æÜ¾ ]òÕòZ©ÓĞJDîºÅÉ%4dK îaÍYÆÊS¡a"L¨{}Í°^ÈÚ®˜Ÿà_7àL—6ö*z#€T©'d7g$…½”G«8ÙÑ6Ôú°’Ä“ÁX7~†·~²ó¥	.M„~cÀğ1%Û¯yU¾«fİKãY[Å…Í—î$±hCñá£%&ïi³´sÕiö`:üÙXd‰õLüŒ;"âjÔWjªHÄ¡¼‘GÃIZvkswª³o‡ö˜nFaå¾ï°‰üâ%-xôÌºœTm=auèYKo[¦ØF %ÒVŞnRAÇ¯QTy»S¤}Í¿@ P†OÏû±2ı‡ûGÈ@¢ŒõüŞ­Uè‰`~–¢¼î%nx&%òÌµ‡ØÍŒx[QÈÜkƒÈ¨
âÆŞª8$]‰ä`© ğ˜G™‘åøÙı×òdTX–Àd˜)1o&Õş‰E¦Á[?îgêz/‰­î[‘;k…Ã$ô!ÚÀ¡XÎ	È0ÿíTìr¸·Àm.ì´qZ¤eQ§ÿ•h†àÍrŠ‚o®ˆSğúá¬‘Œ×»ŸÆJÁŞòx\|ãlí)#…3eãK÷›¡]Õ¸ŸÜ°NÅu²bû(²˜
Bn†R}õ(2WéÉáÉo810Çûº-@‹HˆÊG:Ä‡	4œö†ú«g¯£väc.±‚˜ƒ©?DÙ—XgBß½§}­á·H¹pq£tæjY6Ó#}0ñ»HIë¬’§knX)»	’ë&J`İ÷•ü´(±†~ıg}j ^‰¾f°F4‰Hİ‹Ë×„Á"]Ù½¶Êhkç}Õ„$ÓV=ÃË"èiIPÛ¼ÌĞrİ|Ïìÿ+©·7hWä®áG[@B4È¦·ŞLÀ—IöMC`jÁ’kL‡Â’;ª¡ )C£UÄõwtÎğ¨ó'–7¤(á•sØM¬âq8	Ç’8!HğÃP—›éy0“ìVÂÓüwhãHn¿È…­€‘3êZ$åëÓ?4•mâœÏ·û÷Ø-d¼™5´¢0Vƒ˜ùÅ„EÎéà¼çŒõŠ2¡Gãêâ®Éøçâ±·»Ğ ËÇs›·Øòo'±ÛÅ¢*Ùˆ•J¼€›äÈøY."‘N»I‘øá/²À*áÚÉX‹–)”@;W	®èA%‡ÌöµÜÚÙ ] Ò®A²2†a…ìé•êÙªdŠEë±Ñ óèLü*†ãÁMçW	J'ñÚÎ1üj%­Üë´°izo°h9béƒaºæM€uÔ­5û©Î w`Ùç­Ùÿ.0¹£G
/ÎBoê{ömØÀ«›ºFÁÑR×JÅ¡?+XêİT|Şù¸„ä¨UP;
CJ¢Õ!uw}÷ê¦D; Œ$§Âf¢À$˜ Ï¯ó¦‹Ç’§Ç)à|,Œ½Åğá-ía©éx!ÑÔşƒÑ4¼7>oJr´­ˆT[h_µ¾
C»r
W†ã«„ŸˆyÚ€™OpQ>‚¥[È®ÉU[65zwãgª²½˜¢túú>ĞÚƒd¬£øö{Ú¢Á#Ò-k°âŸÓ-ÈL$X—Í|-”Œ½§Y“Æ<šn`,a!Òn›S^ò[G¾”] -©:à+iHÅ¶=nÔeëı”œÚ“g´qE˜7éhšQ“róüóî}ş†dv fi|Yxe¬L(W@wã£ÚtTŞÎÀ‚[uãj	Ş/—¸%ÄÿU#•KIè_ßP¨±®-}A_@¨Ş1>¢c~¤¥j|ÿxI„ºC \ñÛÙŞrÛ!ùÏ¤:Ä©ÜçÜ‰3p“lòkİ9U—'Ñœfï†"’~jãõB%I¡ÀG¹´z'PXqš,¹{¿\7ÂF°®éôµä)„RÍ``?PŞåVŸ_Š³¥nÇÕüEptQëÑ‘ã¬¯0ì¨-B÷)PT®<ß)œpD˜Ç<<ğ¦ëh¬0§’¬' ßèˆÉ[N†ÀXÖ8%Yš#eş´:hk<,Ê§cõ.“ÊÔÆLNOµnq½)™ÆŠ?Œ5xÍíà14&Ês‹ÊI¥·ğ;3oÜüÊá Ì
«r*i×(—x[ÿ1ãÆÉ<TqhdiN»ÂŞÏnô¡_“îA»¤U¨;Ï«éûûF67I¤X/g>t/h_|2Mtæ¶ªšãRÊ Ë‰ëøÉ"D	-A+¦ƒèeê e¨‚I„ â X=—#ò*¶ÛSòû“.[êGìó'¦÷r>ê+*ú·&^¢¼‘cÆÛÂ¨ÉƒãÃş¥ßçl¥ÒàR‹çĞç,ºÏ0¿^ú„kò"3Él9ì–fÖ’GGºBïAÒõĞ,²3‘Jâš Ş {< @Z<1ÿ}ÑÄÙrÕ½ÅÂ77Í^èFıNA=¥J®¥û£nÙ6À®~%m†¯ní@7šŠeŸ›XówøHå’²~zt£×pI©µrÄë%À²ÓÆ~VÕ ç*¾ó˜]²‘œÜ´v;úr¦¡¢[ŸrV½LÚT	Ğ‰	“{8ÂÌ×³äJ>ÍÒJ7»ox”‘ÃéäX‘xš«´jD‘â°EøÌ¿×<mZ\KbÄsA¨n 0$;8E´´&‹ìzé+ÊéÆ-Õ°,ß­bôe ˜?¬@ê½ÔkÖñuÂ€‚lš,RéVø'ëÅ„úöVŒÖ"`XDÁC8)U¾„vî¥ñZ7¥Îáøˆ T„(sÕ;ş ÎCHIß2TÇgwÚfsÛ14ğ×üpŠïÕÇÀ®´’\}×"<Z”¼°ÊÒI;ş€eé¿ÌáKï)úªè|wIô­øæ†±á‘	Æ¨²u¾&5ísc
İSZóç‹” Ø¡ÈĞ‡dÌ1Ë“QëH¬5fŒİÒ?qu¥…=çÌÜ9j'ĞñÚ‡ˆ¾"ú p4šgu×&?zÍû¸$’ÂÈl®[f',[9€Ú¯
Ó{IKÕ¶28À˜¤ˆ.%`·Üí%±aô|ÑÁÛDVƒp@Ö}g°oW@ÇzÄª‚°}O‰±çwÑÕ˜Œ6Ízµö„áú©ŠQxS¿h&!í€hÀ;ì .ıO|¤2(ºÓ¦T–ì™G…4Š‡eåKÂKYª…òºf”˜ĞmŒH(à»i=ôºîĞVÿ¹¯xc)éÈ¡˜O¶óâİæ¡T¥ãÄÖÉf¼­)1¯Vèã¿8¯ÖbJ—„B¶³–Q÷£\ƒ3Şá½‰y’ˆêŒ^ëÛeÁ×Sc­›1ói'Áš…ª	Ù§öªnTµóÊ:>6qì 9ÁRí¿øW¤5t€P=;lgV°¯…¤Šºè™ª°á~šÔpÉ)jL>à pî C×·g>¦†áp–¬èVÄèRGì¥é‰LF^œÔäÕ¬bôfgÈæk·ÃÁ{ó‰[Ë¥qS7dEzÛèn^¬½ü}-Âx‘E³şrìº´"ò¤z‘.İ[ŠÄÌûà-ræ¡5,º˜B…/ŠÑïÙ»–ğûÙ*ü(i™Ñôš´34uî ĞÅ2ûóìîH¢öb²F›Áˆ6pYŒ[é¹pÒÔ¸Aê‹2¾†îcR'±¢—÷À(QR'C)şé9ãî.Nİƒ(’–==‡»7²|Rò¶œ"æ¶~P¡>²©° N~Y1b![\Ëãßãw‚µÍ’Æ•“ç‡9ãÊëcOc¦¨ö¡EÚKv"¸÷òe{å”L”²Ú·EfÜçş<OğŸà{¯ö•ìæÙC[—¬ŒñQÑ9Í[c‘ŠúÎf»&ï‹R“8§ø)g‚‡Á¢ıPo¤z's$HÉ™|§¶EaŒóTé´ŒÔ‚™ÜYõ­!|	Wo;Ì:C’úoTì>’x‘*]I^	,½cí'çz{ıÀò‚µ÷|Úgpƒ³rÒ	é£+é­FÅyÇP¿áŠc°‘Ëe="¹ÑëšR=oÙI ÃR"lN‰ÊŒ´É¯$7b†	‡§FEÿdÛğ¨uó`ìFufÍ—·ÊEú)ı.x'ò-y!½±`­dE|n•Â8AÓ-É„T‡/Q§a”a¸¤Ø!G.RõK.Ô•€ôûõ¹©¤_Í·…w@Aà"şğ˜lAÔœÈ°s„ã²Ì„ËI$]ŠÌç(š²ô£>€ŸŸ%·ĞŠiöŞÚk—gb­ºŸlƒïŒ(I;ï¤cxyKyh‡·>Şªê]ÄŠH` bPøŒb4|÷ >ôEˆBØ9&Ÿ	G¶Å_fÛu&W# À¯»æqãİøÇô“eo¥ 
•]]xêQøVrÕÃŒ÷‰xöÈ€0hãüiîÇaKå‘‘”I¬D9{6çöérzËŠÍã×¯iyÔkR›â³÷ö˜¸›X³HBLÕ,5GdàT^}®lv µòŠ’î›lª~TAù‹ÈæÃê,Š³<‘ªY·£®Q( GÉîÈ(È;U €÷	2ŒcLü×õ+©¡0¡€.èQÒ8Ä•°D–e„æ·6™Zß`?—5S’lâ%X@œWúƒ>h±pgË¥r6(ŒeÀEÚ|›‰¯vÃ•ß„Ò'¦èExL“ƒ¨´Ğ]`+7ÀÅŒÍÃÀç4?hr‹ôó/w¢Dw	LsÃ2|B€‹†Àk:¶ÕŒEpä69Wı*#–Íu“Rl°N“g½ÊÏÓfsí—¦«]s$/~ƒ¦#…rÙ@ÔB–_
wôòrôW|&8ói\+ÆøŠæD±èWPüo/”¨Èwù K<w~gÍ	*ÒËj©¹S ›ªB³‘ºÂÀm
ú{˜+Ç–ú”Ï‰n¸ì¹à‡èãËí6©X†¤Ü%´Ü
Rµ+œ¼íOÍ¸8¦æŸÉ*_(!$•vG:\>§Ê”nK©ìhé«á‡K	•¹üËÿLøÜ‰¡õF·JŒİ43¶® ywÁ	åFÖZÒÜÖ;J•îV:LgÏ%‚ÇÙRªQ´×sXè@eƒ†æ˜7ÛÉÈ¥6åL`'úba-rŞâ=f”¹5+ŠV·íAfŞª1&~úí‘Ûj'dZt{­b-çú¢ŸÇÜ¸íØÚéİ–’Ëçâáó˜qUš(î^€"™O¬¿n1©çš29>Ø5Í‘TÂÙªóvHyºiXnõìÕ)V;“¿ıøÿwšÙ`°˜)àXªä”¤sQcã²	Ux¬ô¸Äñÿ6_?A•¤`¯ÃL_a€´`+
ìî®«Y¥©éşµ,Ùt0zğË…
ü©DŠRPÉBÀİ×Z¨[«;&9Î1Ê°¶ì—´æ5x‹ËŸIÓé³h÷Ë$bñ“ÌrŠ7.¡7À„ÂA6Ñ©<~ÿæşMqÙğ±çz8İÜŞC;wr¬€Ÿ†¯Hİ„.ªcNñ<pZó\	’ÔbæT»©”¦WŠ³8ßĞ‡ÿ:/*‚Ü“­Ó)iÊá_.ıgCÌ³ {MdpãÁ,d£Ê…ŠªŞz
kÔ6³Täq‰ÿ28ïQ5Ñô‡XÈlX±v12Ö¬º˜ãÖ÷rr,:İÎ÷ôåà†ËUjF“ØP[5Äš`§j·ìPmçf•À'0€p<}Å®€Z<ÒBX-C:ørãe·wğF–Ğè ›·ƒæ©E!SdaÄ†	ÿ‹Gô^…¡ò¼JÇìÕq˜~şôˆ›³@©6Ši¬æ2ø¦â†»ğíI-a§Ùä9¨XaA&{²ã82Ÿ?w}ê‡šõí¶™ŠØpC¹½9Å¯Ìˆğç°‡´[0BgQĞír¯Ê{I’hŒYG»Ãäñ5†ÂkØÌ:SØ¶ìBŞáWMv-å6Ó·(ÆĞRÿ^í· ş&5Á¶‡¼OTÌ®)¶*šd ë‰1\Ÿğ¯~ı–~’ŸÚLºc`ëÆû–H¹g¤=FöÍœhUSÌoŠ« ¤YğE€_³†–s84œ]cì,b5¸R®èqv®—˜NYÃ<Ê+UPGÅI |¼‘úÚeñ’•ı›Ôz&>ƒ©C)¯«Dr‹çĞD;´–oÀušŞæ@hÁ¶şÎ½Çm™&«.Zw=˜!1â¸­oí›Ú‹š¥~²eQ/Kë#ĞÂ¾S­ëë¥ºnèât"Të×3x×4¯¾jeP-(ÉÒsøà@ßÚ=!]2îèa(¦¶ş¶MöÒ6L€lIâ‡\`‰MĞ³v”/§ŞQlÅ’!û¿@èà‹î)ŞKX›YÄ”æîuúØ"¿/‚–àBX¯¤¶ôÒvHÜhzÚŠ×>İ»Z™®/Zµ&8âÊ¡‹2mîÔ`ëMÇB`œa‰
‹]3@¹Í~‡ò!»Ë|pNXË˜êgáWãcŸ«Ëç•ûš|áï5…vÄäÖëŸ›Ş¾¦ø¼ª{cñmâõÙ£X?-Šêë¬ÑMÒ®-[Ó…Ò´“BxÔòÎçÏGÇÇ”œ"Ğô´ j-•IƒB„ÍÑô·˜G’ =¨"x“.0¥º\¨‹s²£»&´_#1|TX’gT½1î'%)z1˜¼L–Áÿ2÷×ã¥¼XÒ¸
Ğ}÷4¶`e‚ˆîb¸¹ú7-Jñi˜äöéXï†Ÿpæ>Z×Œsãà-–cEx“^W’¼í.öïºì+†ÇÔp·s
‰:aÇñ%ÉÑx|ÎcÍ@ˆëÌ„BozÆ½ÍDåÏÎÒM'ÔÍò•iÂœÕÖÖİ®µÙV.§©jÆXÜ‰Œçlİcy€š‰„¯„|ûº)ıƒ¢(iFE 0KÖNí¿»İ³’]š´S‡éÚÆ¼zd¼$¦ùr 6Dş'JA†Üür0ù\ˆ@|_×„íy§[ ®ÛW{Å8 TâOVèáº	÷ßüú(Ëğ™ü¦0'óm‡í©ÁXqtèU²f›2638LI(eÉ4©Óyil50ÎÏ­,Xj@b¨^Ñá{±:İú-”öÑÂVC]Ûé¢K°Ùy  Ç¿2ùsFæ77Pî’³?Â_I*¿ˆ'oQ–I¤É· š†PPŞ£UD€d  bË÷†X.KözËVîE?»·*Õ×u;¿˜¼Rz[öñµ›˜"‚cÂŸÛÏÑdô6;è¬EYR‘”€—Û{igé½&Îî/‚
rÇäàÑsB+bsÂJâ‹›¡¹iîÑp[Rø¦)@cç‰%ıjâGIÏPã¨rDO_¯´,»½.-»3iŒ¤û›kÚã³9L2S–,º|K‚@uT¹i]ã_ãg‹7ôÁt`4ÓÁ‰ª[,4ƒ*0a•‘UâË´Æî»¼‘­G	J}›cR0jŠøKj9k{dÒ~×ÏS†4›îˆdûñ€nræG¼ŒzºR£&D4«Ş]D7]ç¬ûE°b=#5U z8w“f]Ï˜cØt•àTMqL††pë¾†la¥–G/)âÍŸ7±ÄhâàœŠrá$¿©Uí—`Ìâ€êá:Qì´ûg¥:u½ÙÙZö˜¥Q’ÿ ZòÀ^Å's®»š¡3©Ş…MÂR>KŸ„eÿS[åÍs‹p¼Óc;8-ÖÉ;0f‰“ÚŒ2ëã™ƒ^°¡‘	ƒ¹äÊ×‹˜ıdÚ'îØÏ›I;iš”˜^ş£ês1j[öCwL¬æşµ¼ÇhX#¬Ks¸Î²+ş÷ç£œ%bİ·Jb²ãJñÆŒú›ö¢LÊ&”M2á»Ë¯”¶4Mt¼~}&xzK†õ ­Ñ½ÄÓb?gµ³ÜsL,Ûn„Q("´¾¹>7¢zl™&°ı<õªÈäo¡§Ê—îÔd‘Mv£/6¦éÒ{âİˆÇïÆÔªşv°ñğ}K¼bäå§Âüé¸ëŠ:ªâ‘Å…³ì©“Ú·\e¦Jƒ`¥£h7¦fcËuWnác[¦üœõ©Ä”³²
*)¡vx} ¶>[ÀGIFP´ö©<ïe![mÛ(\‡üUÎ<¢¨O-õ6¤7c¹b_ÀÚ<ƒæ±Ö$¾R«õ?` ÉiüÀ¥"QjLa­üh,Ï6Ù,{~àƒšù™#•‡NZ–|);mìÅÏLÚÍ)á6×"È›7áÎVã‰´Áá=Æ2ìgı37º4¾qšâ>õ²=‡pÍ·i¾s}'u€”l’ßB]a8##9Ê?v3iú±4pMV­-®ywãDwõ¾†KÂ¾†æ ´g¦ô›äfµëAX•ÿ¡jÔ¿Ü	¡hÓøL:úÍ;¶‡T…¶Wìöù<±½iYb£+é½!hÂõ=MAcÂêâÒ­í¹M~¦ºÒWºÜÄ"ĞÊ“À„,t0¿‹eÉmÿ2ÊbÌ1¾m±œ×Œ
SîÚvyMÏíÅ 2ªúköv¡vI+d/zÆ¶ÓÉz'Së®¦˜¬™TMæ¨ŒÛ8³öºˆ¬›.¬Á¸Æ
¬†ëí‡äx{'ûCH—©I
·ãE.îbŸó‡æ=°:*œªEFö>‘„0ò>¯`w»e‘É´ÖH×Å­<>$b:ül³˜?úVnâ;iG<Ä’#½¶øbÁ'§IıÏ»YŸë,uéÛğÏ¥„‡ëÁcüÓĞ’€€ íÁ.fÊrÜ,ôW‰?ËûXMÛ}şe4şŒ7^	8ÔZ{èÑHˆÕ÷50‰C|d­º:”ñAà%zßÉ33Äb}FK…0Š£=™?¹L_À¦šù…’aAêH†1’&¦’$ªƒ"ß\Dšü‰mv:ˆÌŞsgşh+ÒôY¸Nt^ÚĞÁö‘¶­gK ×6ğ¸³'!,M‰Ñã||™7wë}O<²qwöàıcçcJ5ÏJÖ&$Z¯2k-ûøË‰Ô5€¿¾Ê_ÿiÅ®	Ä«ÚˆRıÏ_i*cš@n`¶!9œE|{à`ĞO¡_qïáãÙ¢p{À?lö~mos›fgŞÂ§\æfT%‚bíB«…:9àó‚jï½•
ÁÀ.şÂ®TÍP<i +»mMZ(§ä–¸â‰?ñ¼\Bs@°5û Ïd‰.ÊïµÊœl¨N÷Sp¦–GIR¬ºËÜU¡Tn=U¢\ÍpPûyg=9¾„o¤LúP;æ³õ–¯¸ ã*™ñÉ¾å¹;šµîGãÒŸ£*¹§§×ç#ç9ĞI?²ühêN×†ºÒûà¦Çªûôë¾[àµÚİr+â2$=Ö%çâùßÍŠvØRÔééO`û<j±aË»Vt_WY³Ú–›»ß±s5A3Ål¨/’}Ï½,! éâº,›ï1­§Cë Jšr¼“¾òÂ©Ê½@rÏiQu1®F¶ì™®Lf¸Œ)VìE?']‹*UÈm¥¸¬wÙÙ:Î:Ïuû+]4NÁ/?c}X¯Ğ$ÄœŒ9ÙØ¹šuˆÔœ-s3z—¯» R€ãäO$¦ 0!ˆñ6ìw¥uÃŸl n×½Jîüÿeƒ&W€Á*ï¨"8;-WK¤™qZˆŞô} [»GšœïÌviÑU¾{PS¸±ÊÄ®ŞHşm’1CU*¹l|á!¯Úì¬RdŸ—Â-¨*ÕöêØñÎö.)±¯k³+.>“B™¹€@…õ¸ûÉršc"å6!úi¢Ğ>ôYäïSŸ{O…'é ÿ_›ÔZ-	‘Š)l%lÿ$3 `7:Ó=fêõeSzKîÍ¤†~Š÷øÿçÃ`#İŠïuÛ&ÁFxÛĞy?˜°T’L§ëé0UnU¼€a+û\&ÖQÏ*éIo;øø‘ySü"n›@ëÓ–ó^Ÿ¾n¢I\^eâåôGÃ‹‚šÇ?š‘Ğg«\T%9j¸Ó±¹Sšaúóãß±*§ì@³#ÆÒ0'6ïrY îĞ°×›'xÉYx;b¦;ï.m¼¯@N¦^ÒÚRŒ©é¸_,ˆ²ÒGÏ jà	Q¸yÂ¿Qô5ĞôÕjÀ…3óÊ)u¶|êÎYMmßÿvzë3ßO}¼íßC¥6{êıwódâå‰|	†ÑQN©Ş#”2P}PËÊŠ8(&vÄŞŠÖÆ)aó‰([1!ÑèˆŠ-"mxZ:õ6Ë²¯õ‹Wò¦bjdf´‡â~É­ò¼	í×¢ ˜£%Cª_qšë]QkÎnöğa‘®qBä™’ÀªÑR™üµİ±~¤0Z0KÇÿd8š¬0}³NÄNSsîø‰¾“õXIebâE™°^cÈ¥B†*¶GG&§Ø…m;,RáErˆ8BŸªİİŞ²:mÛô}§Á…=”ù@umŠSïg‹i+­Ê_	DîÛ,9ùR3]|ì›Ä È²_c?Ÿì‰á£ş‡q $xW&Š™•È¸ª„8Í.8S1%ô¢.†üDºkğCÿèÉúÃÏ±Â”ş?z®³¼'ÆõbmaÈ‚ëÇJ$÷\Ÿh³°íZÔ˜³507ÿÉ0÷ÙÅ¯)Y@êèÌ°Ô‹+;jaşÒ±©Ó	€ş‡Pò‹uĞ(¼
¼n¶Šc³»§Å‘SÉÇåpÿ‘TÁñ^zä±¾hQDÀV^şn³»¢ÄÀ|â¢Fm—í¡åÀVòÆ
%+ïÓUMîu÷^	ÔaÒLâ1‡~È'	øz.v…_-?ebˆj¿Ïo[‡îåÛÑ`dV¸èØ['µ‡éVÖ¥.9RªVü¶›{;«—+)ƒó5†OhP;ï?ñjãÉÉ·„ºÛıM¸;=ø KéEˆBÉæPô¥Ñƒ*›º÷ÀpC=>sNj×PD²P\”ûÀT÷ËŠÉk›ÛØqö5¢7ıaÈ}œırŠó
vĞB]1roE·#”q‚m¼ğ‰§”pš·?W[İz.>:Œâ*ÇáÖvÉ D½¬I¤ úr·õõÌ_H0`áùåz_­€–‡‚-vÉONˆãCò¿zKş=ZµY,q kPªÁŒ‹8o¬)¢³mï–
\BŒõ™¹l ÀŸÕ»1è®„MÅÓ–?ü
·Õ«îÙ“›¯5æd—s4vH^;Ä¯oµŸiÊeuŞ÷"ágÃ´™ÿh—o8¢g‡*µñºóy71ÃÅçÑhcS™K³Ç8£’]TšÌâó}—«®Ø¿ùpÑÌ–Òõ´tb§†B0 İÄmóŞÜ_ xÜbó{JåJÍn9	~^nÛ­AÇi|I÷›¡î¸ÅÓ·1ÔV±‰3§¦‰°|m’œ“ª
Fé®~«-qò»ŒZ1pQˆÅ†[&½Ü¾+±òf†V–¢ÒR²ü«ş¾«´É¹[€_•äŞtğ¿‰ïÖéDÉIâ<)L¶ÜòÇØ¶>¿ê™hGiîëS–
±)ÅËR]©®„±Å\Ìw÷uÒ‰4ÙÒQ`vNsÑê…ÈŸÒƒ*Õ˜¿#ú@‡q‹“›…Ü¯ª«%qOš»û}•m6¬]õ‚§	©LÉxR·Æøë3nÇ*d¨í}°‡Ì8ü’„qX¨-@B|Ct)ÑÃTâŞá»¨½šT®ÔÜ°Îû\àë¯Ì7O/Kw¶
ûpéöáæ’:ÈƒıÖ 'Ú+[TtˆÅâíUx×|éÙ¬™=çßå€«¡x±AóÿŠ»é‹-}8-“œ6àå>`<©Z>.T£)»á_ïˆ‹ˆÈLWĞÑ0 §ºµüÄw¿mc6Eî6´æÓäå.äÃìã™îWßæ‘âÍâJ>l…‡Æeå ª#F4	ÃLçw¼B8R‡O¸; ‚Ä©@/î¯	Ë(pò0Pñ`Îÿ	qÃyãŸmšÎ&Y9†
’ÙŠä“Y&¿üƒ!¸rŸ—_Ö›Ás*èëÍ&C‰|†ncá°úsçÙƒÖJ2ĞO)ÇFåjOQÕl{ŒÒ6‹Û`Ãîâœ8ä_•íp‘–©I¥ñ
 · |<3²©úù Ûfqég(ŠğæGF†Óá¶?>Û)\—Ø˜[½4‚I‹„µï&31Y,h€VtFbuÜ$ì»çT»KšÜ>6áŒÏÓ\Í••>-©zĞLÔ8 µJë2ÛUµ ‰¢u~NP_Şî;öÜ˜ŸL)k(øYï¶”‹ĞnH˜©*‚+Ç+RwÈç–ts„‰Ÿ×.B;ˆìÖÊD§µ¶Óa

¥î*à9¤ÏT-å¡vü°kA%Ú‹C_I:1‚¼ı\Eùïˆ4İıÛÜn¸aw9ğDj	Ì
C‚‘L‡[Òì0
fz3ó±‡ˆ (n]ÿ‘Í…’OğÃ12Í€i"Lµ£¸G£è¶ªÆvıZì˜”İL\qm.ËB
å*‡§•ÖJåŒäà›_*qÇWi5 ë¡iòò:%ŸNâvBr¦r)z­ş'›˜ ‰ÓıE-sçgşg×`EÛŠ‚–‡ù‰ªdåR	¨{™"sTÿÒâ©zòi
G;Í}Õ¯´Á
‹ÿò)ëÎİ&œÈ=ûÎ5¤¾!x¿e™;v¢ÇFá¥÷°LÈÛó©ûÄ(GL$^ˆt±VËšuÔœìtã~òsW¾ò#Oe½÷ôÕ‚AÀ…æq²¨f	aîœ†BäöN’C¾Cå	2ÈáYÕZÀë›[+­_ûHt6YİÿzZ‡ŠœıOU …r†§âZ]
Óå•Y¸Ñ?Àúê¡A»´/ô™×öİo&2t=]Œš/ø‡G– ypÇ•\£Ğ½›ĞäªÜ_,2xAR I1Bí‡Ô¾-M|î&m¸±ØÛú`!OèœQ»Co›ü8 È?ŠİFì­]Nàşêéó£"Z@”ƒ'´%0Ì¨©‚ûv¸‘À-à¦«/ŞlıÏŒ5»Æâx§áf¯DG}K"ˆ"4R.ôÑİ%¶»’(á¾A³~Q‰vô’ˆì’7^`^8X}:fëÃº[ZEˆ#f½†•š®".ì•œÜJwcN`	§6e¦0qZß¤.ÿ%¾ 0Wî¸ºúfxV#ª“ç­u-Îù©üo±u^×¨1’·®¥4ç€"ãÜ&M„<Àãÿ®×Ö\¨"Oşÿ·–ïË„¤î†:ÿƒ"…NN)/"şcÃüÙ a¸…ò‹²\çeA„zÅº¦3^)õÙm³z%jí;‘ó¶|•//`sâûAº­` IU¸çhuOw³
wí;½8`ØI¨Æçí’dıŒ©š,6À›+ÌÀFF¼3hû=\7&Uº §Ã#ğ¥° ãË2ğs‚§K"Åè¡Ú[™=r)@H@üù‘	P”h}XLz>?0ßˆÈ=(¿±°lÇ¨·	õ·<ÚÑ¡RÃ¨ïšuš"ó|ÍÃßÒâ"ÿóºÆYn	aDùË#ÅöƒÅÕÃb$!|hjT› )|pé#Şd8GIí†ĞM‚äÈ~›å#E ë{ƒºûÀ±>ºßwÏ¤ûfd¢ÚŸrˆXÏ%49ZEı	*Ğ{½Ğ¦ª!<ÒÿHÿÒ½rµRîL"éÜø;ì˜ÆÔMÏ±ÖfîàÑK`&°·ä’è/ıHä  İ!Öşå‹qÅ*Şø~k´BcÿŞ¯ú:uTr2bç„÷Ó½ıÆW3… [·\‘J:G~È!İ¾û¬aàÛ™ÅoíEJº'ûAÉŒÒ+ÕÇ„F	ŠYõöìşØ{n³	z·P£r¶-+ÿ:‘+˜‘£6‚›ÀèàÎ[U÷¹uKÚŠjçX‹…­ØİŸşÁÚ~¢' Fê¸í¦Å¼é"Ú³¯N½Ñú£Ê¯L
ÆÔQ¼÷;( Ìj£ôù^÷Û‹<Ä]Ú\qÌE2ğ¥Ã›{—ë
¶A0“Ë-7Xî¾Ç6ŸyÓ½ÄB-gMrª ‰?v)#ÛşìPiâ)ovß¦-¨ŞXõi€©¶·ø¬AÄ­·íI½)/ÑªÌ·†6®=…?İ#ƒ}i4>.äñƒE­ µ[;`(zxâ½“i
õĞ°/My,n ä&¸§"ÁTOù\ïİDØe Æ$2X~bÀ#†äßËÔzıÀ8*“)Ìo¥ŸÕ¾©)‰ÕÙ°Bz²Ì"|:ˆb/N£ó°¤¬“¯}%me^ÄaÙÎÇ:zò°,Äğ×XšÖ°C °ë|Œ¨?Ô(\Óÿk°33  lR~IxŒÀ—#¸WĞÌ†ÙÚ"OC—çÃñà<Í®yøx‚OÃ³uîF¡€x‡ÓÑNj3æÉx˜áYP? ÁL¥½sÛà‡“T7³†‘z³¥öáêêÆG±g½9¡í¥†K’ì%”¦OQ|Vªmuè™fo²rˆ¤!–@#NlJ~ÌNqË´¥°!%?Qè·A<<­ÚOaü¿éJA9¢‘Ÿ•\êîÖ¾—6	š~q;JÓ–y]8ƒ‘§…:9Â¸rÜ€Ñ_°Ğg!B ~&ãè-¥ŞL¶åİÃ0F;+W„¡Ï?~±6¸PìlÓÒÎ§x`*YpıÂ@ÛSÏÂéTJ©<…ª"çÖöjçv@6–ò¬£2ü¤p‘©’©üÔVÊ;0İDÈáxª¼òò8îY'p=¡$‘²ı	I5"bµL¤Ä»¬q°)˜÷G¯|ˆ&UZ»Ê±˜¤ïæ×‹Ûl„1JúW@oïIaGeU&!>êoœY‚òml$aNE‡Ç‹³Ã'£ü'kO¡†z¡lÓ-?N²mEOËOîßL"Â‰¤^™!ÿEŒi!COî^A0yì¿”,æn¯ıüü·l¥ËI±:â$zTB‘Õ¤ÏXJL6}‰qÀ×BÈ¥¡ñ‹uÜ'7Ñ•}©wòòcg‡0õ9 3aç©kÜİ†’Å³aHúƒÁŒU ú\GŠvóÒ"µAHò\.œÏ,'@+¡å)ß¡š$·sZp&Óù¯”?LLıÅÜa'Óã²–ùŞ w+ƒpÀûH“!J«ZÒ‚fS½ J{‚µà<Vu.Üb`æ£¹k±‡ñ¹¾æ:0®%°"ûA+hÀ›$FïäÁw sÍ‘Š&# ˆ¥¨÷¹÷«ŠÎÓ®àÍ9›¸´äál¤L4£²ÅP™•2ùßá«_Ñù<h«º7˜—ßò
‰SÆ ±ÊÄ«è}óR… e˜Ç„“±„b5Âòø³±,åéÄğùƒûÑ÷(G/¨²A»¿Ë¾y£„:˜Á[[S.TØ»pG}ú1Ÿ—ŞVZPj;}±äÔfC¸_:ˆóL; œªçÑşä6Ğ ¥ËzÖ=uç'Ne™¥‘˜^x*)Ë¸—u5 øÄ’BC–’è)¢ëœ>ÚH”‚W$JÄ°>th›)ñ½§K2øPŠï Õ(!(ç{Í}=Â€•Nóz'u|RÕj zÑi- ûUEôñÙòy3µ¼©®²YåşK“1R“5PõØkÈ.}IÇ'Àî‰i›«U—bç-7¢å|)5SGºA—ÓPú¡]Œø½¯µ{
7 ıs‹µñAUœ/í¥ŞE ìºi÷Jíß~ë¿»ïğËŒÃT(wè‡?i¨»ëµÈã@:mN#ÈDBâFKøE,U(–ò›²åË†²À‡#@N>3ôrŒˆA†uMIp‹ó1¢é1ŞÅ)Éü#-ªù_sü±õÎ¯•·`êY( †‰‹­‡e2/•ó±4Bw‰ğù‘FíÅg°B”ö	šİzWé=n*ıw¨@|ì-ªŸQ1ÖÇD¡ç3ê|¨~ÎQieòBˆ(°ƒ”¬ØF­Ûu•	‡×‹·Úôé=}`¢J|¯~[*È^¼5¿?|ì<¦|Yqµ@·OÄ—ßD+¬Xºğ™K{â¼x#Îq43ãzVí¼O8WíAºº æ
™ÒÅ1SAdLı¢³âl“yîWÆ:P@Ìp†]µs‡:V×±Ù1ğÌü‰,‡Y$İ¸‹ „‹@ 0QQ{rF˜\<uœítA¥×]ÿI	ú¥9ô””¯˜‰Æ²GŠıáçe½÷ÃÚÏ^qõÅÉs_Ü¯ AŒ½Ká·®V®Q8¡©«5ÃcåMxk•#;õóº+(tÔü2…¬æØÓËRc«„"²”@Ê´Œ~nª-GÇëÖ¥ˆÙ ×ò/1²îZÙ˜ƒÓÊÌÃıi»}İ/GVLğˆ™"tømÉ¤{Ü—¼ªÜ°İÍ-“´&´0ĞçÂïÎvØã^~5¨~k¸œcªâü…2Õ¹Øöß*}íø€d–¶ÑNß÷M…¼ıÒQJ%½‹è¾L“wªÚ¿äÈìNC½0¹g•K›³ºæ[`ßÒ)šŸÚ¾‡Ÿ¡ìÌå°htXÖ ×?æ_fRV<-ë­Ûø8Ö±<·D§Ö¹êZM$q¶rîG2¿z¢ÏÀ4D+½s™_¿›Új]ÚÄĞ
ì#áÅøš—|ÅÎÊ9%íËúAMZ*ü²µüéqÎ¦i_­hYgY×´Ğ®‘7(VÁ’Šª9obS$:“CljÕ+½ãKK5}a5Â<ŞŒjT.«_¤Íƒ/±¤ƒPã,÷’v‘ À~ª%İ³¢˜çŠ××bÜÂ£LXGÔ¢ƒÎ:Õ<nR# 0‚÷°ç}~Š2·Qƒ] K/9É7rxv·R€w]nøä:acşÚEËGTˆ˜Æ¨I£}¤ÏÅT#&_ñD‡,e¦ÀÅ­ÈşÆ>Àæl¨°ÒMºsFäQú}¸?¼(ùİQ‰t.NëÁôoÁ¨ÄëÍŠ4š #U-6Ê9Rf)á1‡#Çkq7³áÊCœ¼[«¯qxCm·–÷AÈÃ*@:+ßóPbmĞÇN2–Õ>Æ}}¢œï2´²Jçs·ê·Š$k´YıdÓPš*F¶I}’¦©?Ü„~Tm=]=·‹ãôµ{ÑH‡$3V]o$ß¹Gôú+âTªvZx¦üÙGI‚Œ:KVkãÆ&ôC,|aÁÖ–.î-ĞÂ)Z´;ß©œí©ÈÇƒÀ^Ùşo¡À|õdÇšğPê‡7õ¼İe“EÓóClî,¡"uTaŠg‘ü CShOğú”ˆÀ‰ÂµwÍİ&É‘àSŸozêø-ú¿qıJÄß3}¹–†@œ`8çwX©Î®R-(mägŞïXÜ÷Šê¶îTºèFÎÈ±¦ê@m. O@Š«B)Q&¦›üÍã…hëzÇ¡†:¯Êà%ä ¹Eu–Å¶KWòß6ìe	ÃĞVÀ˜“;¯AÃ‚Ò¢eæj	È	:¿ÓÉc0%[fˆãİBOö‚[‹Çaïö?_&|2?eğÇ>¬‡¶ìÛÚõuÙÂ¦ûÅÍâ÷Ù²î(×%½5h’Øú%~Êu¸tØŞ:Ep±É¶á%‹ Rå+Ğóùôî2ÊVşVbgzÜ>ìôÁ”ÕÓ¡W_ÌßÊÅFôãJf7²ñ|öÁ@ßï)·p¯SÏP1•V¼)£CJñµuò%`ğ*"{§55üéı@çäÖNkì0LkuÈÎò9‰“’w@#Ÿ$”¡ÂbNœãFó‚ÊJ¢ÏX<i	óî"2¤Ğ#Ÿ¸6
ôÚ¸l~.!èÄÎ:÷áø~&ˆ‰ÁıK$iÌ¨Z¦-µÂ2¯É“êa$œGÅH²Ñy†Š¢1•ùnoÍA$.in…§÷ÎIı_©ïØÙì¹5ÃTÒ³×¬ô¢·Ï–İˆn®~cdÚĞ€è‡Oèö„Àµ´‹PyE…3»©~Ú=K±“`åEÔh;ÍmwR^ÛaHô%]›DëO½œÜüAjÏw«7áœ/Œ<ºˆV#FÿqVD/¬q(VnO±Ç<úWhb5|ú¹kt†TVÊ¢s­Ü•çK.Ó%Ú9«5–[¹‚`ğX ×X!«\¢Ëq¶†‚M \ÃÜW+‡Q|é=àÄşÄÅº‹ƒ4j6ú½)üg!˜§=søÆF9Ğï›Úâğ ÎQr=Âã‡Æ¡çÈ„	ëI|˜R
HÙåXÅkR$qeZ²øÓçš˜!—Ÿxìá=˜b¿64xÁhşmç´Çú" l2ÿÂ†wHXReD¨®iL£a+Ú§^sÒŠ6XdKld³ÜàİzäI!)%ïæqIb,«}·fJÙV¬:ñ½Wv<‰4ÿoYsÛÈ­*‘ä)Ä÷—Ş8rr¾;y–ïm®~*¬¤ŒÌ3N~&pˆ
¯	`õ’µmî¶ˆ.éâRè’´PÂ«—¨Ğ1ƒì~A>`fIÉ½3ÈxÆ°³±‡‡Ÿ>¢­Hy@áX/ÚÇ¡ùK®ÕĞÖËé°%ı/”´Şk~‡¡”í%r<¤É°ÔÉŞOµ#‹ªqeÊ]·H¼ÿ<¼É×Ÿ"v}Ú©8>œÁy_ÆÖ×—2.µYT„ß”µ;1ô†j{Ÿfë^‚3NlìUåîİÆÆ­2E4<'à#‡,º5éÚ7oğëHİ»·ZåÑÂí©æj´ÍjH´¹¥Øj¢5¡±v±	©YföFı:‡tx‰ú\ú…G©Üšİ“ÒºX|@5íwâ} Dşf˜C´L´W|øP e>lE¸ÛÖ‰ÿ7×-Fúh )ı{µ‚Íw>ªÊ{”ãËzÊ¹ ı”GŠÄ/Üá*ÄW™‘®H‘ğøßÅòV°€ªîuÙ½ÔYÌkX—ÌğRş‘^şPŸ«dÄõ9$6e³Œ½†ùEJ-ºWg¨‹·,ŸÉ¸®í”ˆœ†S®5³Û]î/hŞ«¬;Ëöö_¦šlwìL„‚d…£Àµ‹Ş%› Ñt©Ô{gk›cü»b,
2ÎFÏ÷î<’—¿¤©Ìîe‡O¤‡`Zû®•œš³Òû3²İâÈ8¡åUÆuûÂ|Šu  6ğSĞÌIGi$ğb7‰<×LRlÀ†H¨”9€i]xBg7x&ıíüè”<€%H&‹S 	!µÆÍ~Õ|\Š_0	Êe­ÅZrdâ@›€B¡¸M’5§%ò/•éwœWWBŒû˜¸”ƒˆôÅ Ùµ§Ë©r‡²Ã›¿¯¸g¢ÒĞNhqü"ñŞ½’SŒÇÒeœ 	ç^8£ÒÍWK=¬©FP¯ì´õc Ï^Ÿr¸€_œhNNÿ,ºµÔÑŸ‘üÖ£ËÍØO“¢íhŠ‰YÁ§ÿ€Û±KË²F¼÷À2#±?z÷ş4=Ñ›Ù\bqû¿yœ´ÎiÑLm.^ıV&µl†%ç&'&m›š_Yœ…%ŸA §w£µ¼)b!¿¼,i(˜9L•Y—Pd„¬ÉÔb˜p a~&23=)¶EŞ€EÎNn{ `Ù‹Ãä:´Şpæ#­]íïøc¬åÀİ…—‘ÚX‹ÔòœçaaÃÎ0²–zmitÈ©MÓÍL©PhJBÂ‹&ÎAÉóJE“…%KåÉÚ4+pØë£Øò3™RíXv-`V†ã…Oeş%M,¿ŒÅ8Š²÷r¶„S¯mcº›óCĞ¨ w•d†'¢ÚYTÕrÂ6ÛéUcXÁí|ÃEl*“îa_ª?NanÔJfKƒØ_)´Q(»ììÆm•?"nnü‹©\åÇúÜ’eôE]Lş½†ë±AÂŞ3cä†! gÓ*ÜM“,Ü:y3..—‹©{¹,Ò—ìX4†™|)[ß¿yÛFQ„çM›|ß‹òÉº÷˜§YóæD»ğ_Id˜{>Æz1·§·ÍCwC”şŸZëOMeèdEPÖîë(fÕ(o¥7!jçœOs¦şË¡bğhl› ¬Ã™Bä‘Àò¼ÛÜÄùjBÿf9Vt:À¾ğ‚[øàÂÅèÑæ–E!ÚzÎESh¶Æ’­qeÛºYóFy+Sgyy÷#Màj <ãí{ÚÒ¥ã™|4§…É#DÅV8šïg]Æp¬zQhE:‰ºççyT’M¾SR’Û¼¥¤Ë3FR”ƒõJfŸ»ü~ùkŸ¸‡ bÑf0«r f
òv2	Ôï…ÀìÇÆ2“ G¢¬$BXpiËHğG£7jèX°Ç¡m±s/:iñ§‘N+²Ó5zã^¸—#X1ú E@#dÅ2‰7M6ööêuW«uß`<eËE‚—+]ºÒ¯É’³³eAAèµ»ÅÒzéN›R“¡¬ö—ß¬˜Ö–bCA¬ (Ï£”ã ÊºQİùñŒŞ ô+s©•~¡¢º‹ì¨ıHÀ9a¾ª2tKßiºÕâm;åRa>}+}D
QòS/h¿©ˆ+gØãÅkş×k9‰+ªğ‹u°Qµùšp)9/lØ†İpAÜyªËe {ÙÈã)³’ˆj!|)â‹pt®¿Ø3™ş]FÿIípŒ´§"‘Ÿ<Y!õ÷–ÖiÆœCdl ÖŒ^bø>ğ–U>‡ÁpF¡¿NM#µi_Ó‚¤ˆšŒ¾LÑ¶s/š†…0˜ü%´ù¸!qy?l]T/:o«hIğøõ!§ş>áëóJ3ueëU:€3¶\˜¬Ã²SÊ6ÇôÛ“…´º·Û6éúQM¢HGÒß0È{ô#	¼E(B¶	ÙÇxÏYâıCWj0Iëí¸Q0`:;º	]Cöè•l½Í”›ìßÉˆ0ü(kÄk"0V'¥ÙTFq¢jÕŸØjV+Ëá —~Qm ytDuş
@}ÊŸuÚ=ÓI'iıÖÏú¶ÄÅ»ïã¹3ëúWódhW+IFx)l>êÖüYUªÂÉ‚‚ÂŒÑš˜_Ôğoö”ç<!¥O5ÿÄıZ9„·¨ãxQ’Qİüc	ãømÑ5ÛY,*4EÇ¥ æ¿Ô“ØÈí$‘sO33v´:‰Èh×àÃØ9Ï¸m2Âü‚Ol²F§Á…î7kºØÓÉe Dâ”~Yoo•XáÀ-úN¿<
U¾ÆPù&…'oÚHáÆ£yã–“LµpEŒ`'ÛQ˜ÖXÆTˆ·×@z¥o¸ZãPçi)0sÑø‹Oâñ`×´¢™ï¹Lˆ‘²O
‘Òiì±QxQå€›Q¦—lê#o xÑ†±­ÏÒÈÔj‰Ğ ãŞôKëÖ7Znœu§ù¡Ïg(‘¾`û¥o TÌD-igåª„ ‰v¾š V6Dû½?à 2ñº\šä²ı¼çuĞ\¡nñ"îy·ÒV¾wÚğ”Õü¢16|5qiœÃ¾4á?”áVÄF*¶İM±<ÆÆmpÉöÃÌ™©C‰ÿh† ÅÜˆÃ[Q9+£q6>ámËíX¸•ñıŒÈVâ'Wàzå»Ï•¦Lb[4n¶WFv>B¢ÃÒµo·®Ş€Ï˜c¥Ó)G{¯€&l×ŠØyI'¸ØMWë6gVı¢µ*ˆQrS²¤nèÅ ù¯$VôùÊk9÷qõ»òĞE¦Ú7?£¤‡\˜Øc-ñ›¼¯*®ÖàJµµñ$ÆI~d KQºJŒÎ°g8Ò¶È­cY&XL»ê’…ºJ y

7µ-¡éç¹è]:â£Ô€I'¹?Dk•4™5K(Ì&„¶7Œê²¬Ô{¯ÌnÚÑa2Dİƒ<ÉÄÙnëy‡(¤êê‡wÁ),’ÏG´¹©QN/{™wBÉZmwMïçOƒê£xÁD‰ğ0 ‘eÔüû·Íğ‹¿ô—õ+Å•­NX°ïUÒèZ2ı=÷äSÒ¶“(¬)«”£‰R³ûş²YëôÒ1Ì…ü ³J¼áWÖe¿Å–Ÿœ°Íß#û9vÀprÿÍ ˜ªšq¿uËé‹—n`z”¢‰±H¼¨h&'˜Vqá»ğŞ?cS‰îfd¯|C‚ĞzÈ–‹¯™îVIîA™¿Y¼Èˆ©×„Êß§šÏd–ós?EY´Ã…\eå¨ F’(›<Q‘¡Äòöÿ’ç_±†áqÂ½{F³@„0I]Xº0ƒİı[V¥­&@AˆÌcah?\úJĞ^êDù¿³X$;A$‚ØğJÕu¡¾!˜48Ğ„Ç6¢lmõ±owíˆRÛ) ç“Q|9½©šñ`e%*-Uj’¥ÔW=/KSSE0…½©:kİØw“!kå#Ù®ú›Ã~I_Æİ&OgŞW<+¥U)Cƒ7»ò «˜¬àÚô¦<&ìÈc [ÿ.‚Â­ø”à uZÃÛSş€İÙÇ‹„ÍTŞQB¦vĞ¨öÊàÃö‰,Œ D3P«[ğŞv¢‰™/ìşüì8´¥e>s8	ŠÚnø'äšÆw„¹Ú”Q®çE1Ø-B½´m¼jŠ–İ×«r3¤İÙÍKrhÊƒºZ"scp¾P°$ÙiyİÈÏ¯O®ò]«a("öêË¢ÕÉØ•:qëÿ5¶y”iÙ
óÛèk!X&£’û—ÊS¡˜IÉ~ùYñSËä—wñe÷àò1€$§¿F#¥Oë†ÃÛ™æÂgJÊ~kT#î²İ¬1_¹INËäUğ¡6ÕÒMúĞ*öÿjDb^ù/ÎSÃ›ü£?ö/X”ÛT\oŞ©¼òíÆøô+‡‘¬o›‡© ÛÕ“ä]Ñõ„°ÿw¨ˆD
ˆºe=p?ş”Gİ±õ^i\ı{úîG^“¼÷Tô:éctPÀEÍş	tm@^@\ß[åå0‹—`ç`hØ°ŒBà—¶Û¦š[l<%ÆI¥À†İÅ ¨"vB÷Iş^hG%²t]¼Ú9ûGÙQ²ÃMÃ¶@Poğ5{']Xwàğ$¢!óŠ¬÷ŞÍıq	¤¸|rä÷DÖhö„×”|ŒNP,fÄŒØ	pS™Ë#5š•¦„œçš£ŠaüNK.î²JsSI¯Št­¬âc‘¼WbÜÏï¬S"üîÖ¢r¦Ÿñ8×î%m’úÃü“Å—d´m| aà#ª"ñ<o´¹Öjå#OEù[5¦´+É•´Ü–½,n8œ>_}çNö†¯é}³ñ¨O™fô§0Ù©cï9%ºú[¥æhÖOg÷±6¿kL¾(ú¡Ìâ@’$3	8.QÒ—8ˆ®rôŞG3iÙ%°MQáçH(¹4ôèÑAæA[Bı-–“ÛŞ%À"ouë¿O¬8]6èdFœ€×®ø¾‡«a”ÿ eÄŠ”¤k¯>û|FãPîq«ÍÚÄú'¸\7‰ø¤Èß×BÊ¤²İ€‹hmcÌë¤ğ§?ç£—kŞ3pj¸idè¾¸¸@ÊR¾°	~Œ÷ZV£éëG7Ä)	Iüoc©FúD<q\gªE¥^"«|ü¶e°¢,îàš–‡ÄŠ4X—»?•µ¤iaêú6i9ª:Ç§½|•l½Us2á1'*˜Õ8›W<¢|d&wHíÔèÒ€w}“k<‚¼ÀTA"¥.)/ŞÃ_ğÔÃòœÅø»èß•*"È›²&Çh@øˆÚ³tƒBPbÛY®Nc—6¥Œø°ĞôdQÎ›¢kÏ"?¬V \AÊI©ı}Léyj©ÔÍd;&çl|VráªK0”PäŸê<1‡©î^ì}¹qš›‰M!1hÁgM:ÃíÕĞ°gY@–$³Zbó€ÙH§itâèU]Óf@*zz"ô(‹µVZÁjlÚ*@DÙÖboŒz &p$MÒšñ¤¢ñ†£iÁ–›"6şh?<•Ï-kcèS<gCXÜUtôKéÂÒ‡º“Z•+ãS—eÈDóYŠ\ØºŒŒÂÑPÿ;VLòƒ®Cz„.Í/Ñy ú-åÈÍf­ä¿ÅÑ^ûİuâ¿·¯vš!ÎmK¸ôpûóĞ·åı±“ñYüÌw#EÄÇ(ùù"OcÜ‘Z¦¬nİhábQ/>!a~ù!.¸ÌD1wUj¤Ów7eà‰†Müj“_àü¦ãİ¶Uë»\âÁB³ŠmòRš’dÚ0ÓJÿú¹°‘”÷"ÎËÔ·»tÕëxQÊ¾´îEs¹rËÅù®‘³ÖP·şîo`äÎw‘J•7áŸ
é×YğDã¸ä;.l_K+$j¹ZrÎuÅxôÈ;²f†Šš	;ˆ$/¦ãl‹¶ôÊ'½í;ç,‘ğéÃY8§³ğO  å©9ûXC'^¥!àœ¸î/d›»²ıxÀx¹¶ş>Ï:Ëkøn¥ù\QH¥˜ûë&Y¿›2•–vÚ?ø’E_‹²Œˆ#Ñc¹MFâ©'‡/ír©#üS-®üb.Í‚Fü?J9]xK—İrã»JnIOå’°âlßÀHÒÍÅõº¡}	îl}i$/ú¤#ªo‹1%WCÚlZm©-¦ÀbpIÄì)*†¯Å¼Ù!pñ8Ø)*ééĞë'çŠşQ¬k£Ÿ%ø±Õ/¨Ïr/­_ê1–•rû_¥ÂàÆÛo¤ûñ!sšeòìÈ29˜ê“ğÜÄiŒ\âù‚Ëiëæ¥M3S0€ÚYŸ-A[3%‘šl.òî‘Áõ,¤«_ïŠù8¿d|ØÔ'ä1ÒM·k_ÿ²ùp,ãş<v|Ò!P[¹P5¬Ê
rnu_y=™’âÄÚ[9œş`·LÃm°53§@\I|ê8AÏı’ßò­^NpÊ¨µÎÀ Ç.ÌÏõ>ueÙ^g8}Ó-(d]3Ôø`UâÊyÂ‚·qŞÒæVœ/´bº¶ŸÚY cu»ÂÉüŸš¢—Ã'¿_SÓRa·ÅgÔª‚uôùb ;Šv	mÚ7ª£¨x—¡÷XÄ2˜t`êzÏa~hÄw_¾Jf&†XVrºê˜›ü'/–íòØ‘Ş„
„‘àMhèÜ±Q¡/(v©ßÔ€^òÎ´¨0ûñy§
qAÅ¢]Ÿ¼œÎï"ßné:ÜB=²ÿ£ı†­’Êsì¢ÿşä·V*G¯#üwQ¯P$hyA±qi­áëĞx<uûòL~Îv€|¸‘ì{æ”3âÏ5‚ÛÇ­r$°ıÇîL³/£°íK¶²Ö%d–Ô³€ÿÛr*g<M#^ä–]Kä-²Ø>—ˆ9)Wœ8µ-±@ËÌæËÿ×Ÿ¸ñ³TL8×58ïˆÖ-ÿ›tRM©„RÔÌãö÷wéW~%úÈ«Sx‡ƒÓEDii-s¦Õw´6B¹mìF½ Ç¨BN:½– ÌÅ{³mËeÒÅWèIuÃqz^£{SyÖÿ‘¾ZŠßLéÉ3h½†ßén#g”Šu›óï¯¿&a‹Î$ÔE„^}\›pĞ§Ç6<     ó-ÁBÚ Óã ù²€ğÿ™?±Ägû    YZ