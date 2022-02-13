#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="848073589"
MD5="c37b86336fddd945e19dd9e9a7a58486"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26580"
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
	echo Date of packaging: Sun Feb 13 01:32:42 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿg“] ¼}•À1Dd]‡Á›PætİDø‹~Á˜ÒY
¯œ%Ï».€&Ùğ4Ú3Ä¡ÇÏ Zà|lĞ<¤ş‚¡LÖò¦94¯xÌÚ!XY;“»hâ%Òo"pjŠ5†E]ö—û·Òäx‘d¬xÊ€›#>
ë©¥kv Ú©ı®cˆ#ò Ú)Ÿı|n`¼bÈ¹ŠVÄŠ°„úã?¾1ÚCàµØ÷×Ğìİæ¤>÷îBpfÍ¢ŠRŞQi ¬gSjÏG0¨=sÆœ"+Ag J~›£?pİbx>Œ jÃŸ8é;^jŞ§œı#V‚ŸV™¤o²2'ˆt×RAR)7qEÒ˜ïiİ²)oÛíŸ¤~Ò&X4ĞéW[ªÄ?N¬¨ğ–,°W8Æİä6Õg¾@ € ÆXÜyè4ÜWxwÒV¾‚_Úİç{¼×‰q…ìTE°çÊåDóİ3LëÊX¸)|^ü•£<TİâÍFtdVuƒUh¢ü­±|†À0'Q«¦··fÔ…ó.@L ÆQ5÷MÈXLì=aÏ-÷EWÏ¼¯…bßG¸¨HÇ÷ÈEl”J7ü©?É|!©(Ø$¸?Ø‚X[³Ôıê¤Vœìb¦B
F%R®GÌœ¾qµ0y	ñ:ÑeiÃë ¬.‰;\™/¬gUBÉ)ª£€TWÔ#qœˆ#ˆEY>’\XŞÖ×åÎyùòP2y)àš·"†.ÿ:Öó•Š
ç„…ç8‘‰Yø_óõƒìVõs5:è5Ñ98ŠLHÅñ”\ì¢f\µ‹rär¦©,¶Ã¨Ö¸uìu‚Êf§?´-ÔŠE²ÈueË)2dÅváê[xøeP,º"¬Òv)W|Nzÿª a¶2bÊö@¾w[Øœ·A€ô-aq‘Ÿ†U‘³ZGs­Üã¸hZ.“õá„KïnCÔ‹¢«iÊºY½±‹"UÓá6[½iœK“«YM h÷ú«#¿Ó“Šæ Ï½¨gØO]Nİß«­ËÉ½Õ° ˆß¤d„18è§¬7‰{‚^ÛGÈıµ¤ñœù…ûø´ÿ¨oa˜Š<ÉA‰pâß· Û0îàñÓÙíÄãƒ‘Ğ6·I”{üføüxk Åİè³(éİše2-áIRO‚¹#2„h0ƒ¹‘,ãÑãæÄ÷Jã®íĞ$$Ë¾‘ŒÅ[›6½ÇÿÓÀî2ıë°¼/ƒ{Ob ‰HŸ™ß÷"Ûqı»è<kğÄ~	‘j£¹uşSóªİšDÚÇI¼—ª*…W“;ÆÌô5˜lÌ±íşÚ³`ÛGëÊåuÓ²Ğ:Tı2t¯=0TĞ8K~À*#İÈb#š¬.©`¼tå²ÄÖŠß¯î™
'Â?Ğ¬ŞKW8oaŠ“’Rá‰´&îV@zûOğ¼¢=J<ƒt2£ç¨¤W»r rxå]K
"»üìÜe§ 
—'
QÌmYûm»ªİ¡Ç§ò¾¼{˜Ÿ“á*ÅE’Ñ¯û7ü¡–Aß[!n	Ğ*‡Á­’Ü…Ï%N¾“ìÒ¹@ÑépÙ+ ßä§‚l/>u<Pj‡êşvÛ×N(P!’‹şÅ:Ö2µZÛyôI1£˜j’qSùë.ó£\ÎKÊ…£CFw~"
Ö”ı„¾¤¦ÍíıŠ’Ğ¢dXÏF7¶ïxŞ…õQ‰ÊGP^î8Ï²‘V§Ê—®(Jª¢vX“ a›ŸêÊÍ\ÿ¡P]ïkâ’±íÊ°ÑÏY¤®õ2ápª4§»<íÇª7¾.-§}û=³Îígı1mÅ|Úû¬0?BeŞ¶‚1ÑàÔû‡fş°}ßJÅó3/™æÆiQŞpädÉÜIÅJİeşì—Á6SöæÜ.ßÚúmıu23y©U„P™k P|ëû%é™ÏÒYÇ˜bJ¶êd"SÀÄÀk|gÿ:xÓ¦ÿjÍÂìõïXğ·Â ¨"=L=ÏÜ£ŠšµòLg¼:y˜]¾Á[ı°'ÉPÌ|nM‚L‡Sîs{—­'ŞË½éÍ0ÛqÔşÊ¥\æyg^ƒıiÆÊÕÙXe.¦ec	µ¨SÄ°ÜÁ»HºÏ¢«Šµv¸‹–&‘òƒdi"6X]…·RM³ez:œáUs¼k³9wí\+*–0/s2:{oõİ×9*l32>ÈnŞ”,
ÒpqWs&U¥‹©S¦?Cê[mB©€¶¡É©;mWòÓ¼•ğH G|÷±~ù›dHdŒÃJü<×4ğ›h¼Y¡Õ ÒAGÕôÅSrÀÑŞO¶Ş¼gİ _WİçóÕ;x~Ô¯Ğÿgpca&°n@è5NÚ†ROõ^u²ALFW×ÌÍa9ìĞÊm‡hÛà»sm€Ğ|¤è¹\ Ó@§N\_¥‡?şN¥ígˆ|‚3¨c²¦‘(¦¶O¦WÚôHbÌ¦Ş¢æ`-µÒ¼	©Ÿİ¦×ä?DäZıj°LşDAŠLA6ƒ#é†sã+ùÆµ›ï¹m•†‚‡oJá³6
u§/+!LÆN—ç!‰-·Ô®Í	êi¯ßæ˜ÈâêrÙhv‡müuÀ«%o×@)ŞÁ\€íõgBÿ.‹¿ñ*ûè/…Xò|a÷Ë}¶òsVãİpòğQµ|KRhüœ,T¶’»[ºà;ŸáÁ=-¯^vI1‰Ò+·‰RT6o*]ıÂî,*ˆV¦´ùºbWşé#m€]ÕÃw±ã¸¨½ûÌ1°”â|¸s‡³”PQš<j•Îcşh1@T‡3œ»†?»¶‚’	Óã}"ñÚşËxÖ‰¤p‡DùtÍá¿a]©w±ßù	F:ÉÙTrrşÊiŞXïÚ/w90ø¨9`³©íá”‘ymù&0åz=ÃJOUl0$
B› ïŞî]y¾û6ÖÂ+6¥2À¦oe¬}Z3Çğœêé ·ÂVHHÚêu?LÓ©5¨nM7o.ïCßå»‰ ";û]G‰c~2!q˜ìÎ”I×w„t™qkèkU¡î@¡ZÓê‚Í³BEúGXâ‰äµ}®¼‡_nî1ˆòEısĞêpÛüÁœ«ƒ{O¢æ8
nÂ°E8ûÒ‚ÚsÁ–Ññê]0ß¬Æ¥“ÚôÏ\ÿÙslÈƒ¾Mõ9mAéíéj¦u.ërVIÉ¨Ğ8g¾–+x7º1•Ëv|ñ`håCíšYÒÀ"ŞŒ÷:(ê¿|;ü#ÉÚ}•¾äé_şƒ/Šäüß$Oòwš V¿àÈŞqÃnáİ:>‚æŒîÛ€Ç„³.ıAºJsEœ`ëµ˜q|ãsuÊVÏ¯ èó¡ÀÄèÜ\ş9öë›+DÛ}êÅ@u‘Øq}ŠıuûÜK	×%SÇîH¤ñ!1ó|ç‡†ƒÁÒò3Ï[Mæ¼µm,°wÚ&#nÜï5aî¤<¸u»D¹…èÈL`­
¿Õÿ˜µ>KÜÄVIŞO’)ıì¡vQçÍ~(Ï×>×B¯É¸µ¨«g¾°‹ó5tYám§Ëh–ÿéİşàQÒ¾ãV ˆ9Í9»¯6'éî[)µ>†8ú•?>/•÷Ì¬•«¾N‹Ìô~Ä}oalİÖ¬ó~Ò¤Ñ÷¸P:77lÑG Ÿ‹Hşô]Ø«}sÂœè¸ÄáFŞ  ¥O»†~ÏÇ×İ-éFïÙ`=Â-[ê—Ê—ˆ0Õ~3Ş*Æ$á<±\poô	í©Ü§‚©ê25ÚŒ‘ÏPz9YÎ_…ü£¹¹¯rØ™ç…eŠ¦âûÜ[£"dû½½ép'Ú4¿Hvš¿ZI«!k¿•ëaT&`šHÄ3â)s}pMeúXg0Ş¸À”Œ²1İÇ6Ø&-Şl^\Æ5Ã÷ê7LÔcˆpc0cQMÕŞdªöøí×|+Tñ6I7ª9 ÿëÑÈƒ¦ì —…ËNr"Y5¿ÖÙ£sÆRáû(·´ô8\#;<)Gm2˜ºçMã¹1µa`hÓ±sÕĞ4Çx’®æ±~jX@s6åér¨µ1ÉëQKit¸D9u¢åîü­Ü1å¸O†ì¯…4t§~—ôËoãáh4CrÑûiXĞøx¯-ù5…Îexış‚ËºHºüÆi#¦tli®åõü½± âÌåM'¢¦ï‚®Ùöû«ßŠ5œ§jĞå,â1U•…#­ûdŠB½Hö_±½tÅ-²¢İ{†÷Îbês~ã7ryÕ“®,#='`lá…(n1‚y*âËSkÒÕò*_ŒÔvÍŒ©½Î`Œübú¸ìô9}G¬U3şcëGD±WoÊ0LëËzpÈcÛAÈ0Ìzõ¾zè6Ç~öÀÀwDZm•ƒIeY{é‡µNU7˜½eÖ¶ˆÁï»»µ.=.:ÁZ=êi(Y	k¼!´À9I•²Ï®~” ·n™³ÔK
ê7¡|Áí¬¥‚2Iòù‘¡G­>‹ö“Ë¿âUrKüI7Áqµ”ª·ä‡š-°òeÛ¡u‘ãç!`¨U¤.94Ëû,@hŞåÑ¡*Ê½l¢xÕü÷Ãw_%<œtt4
1Äğ¶ºÎ™`ÕÎã‘hm“FRS÷¾4xTôó¹Ü¨Îƒ²uE^ ¡ÂI:’ôP!â¿LIoN)ĞÊÖÜİx¢Ğ.|ùQ¹¥ÕûvyËX¬Xô
S,ÏwÅ8é
×ÁxpŸı‡§½àx0ÄZ8Õğ|¨	Bj °²¶XåH‹IòŸ}ËM…µ¨ñ\bÆç__ŒWøğ²O"ÔØ'¨Ğ*ÙË­ğÕ§{5C¾XŸ§…Èˆ§öG†ş³k"öÖäªBŒĞY/826ì“Ú²TZDPR~#RõŸD'¡î÷	0](Z¶xìˆµÄtŒk”Íš|Ò 0•XŸ'2½âŠ½}«Ä¥6îde©Oïüj¦”!>üv|Ú7¹ó~€ìõ†÷ñÆË½^;MæßLÍ‡Ü)h\
­&×+Èv1¥İ ±È·e)d¡áÙ~×pu`À˜*\l›ğ£ªZBŸ2w­Õ3*PÄå¶Ç­ûJÜ¦»L§7ÌcØ«² ¢â÷ÑN·à½u\0•0ŒÑ—£ş¹C
1û§ü.·§fPÿõíë
çá9m=°È”3ŞAkÇØí+ŞËbĞ·ŒBìãĞ]%˜…ÚÓXsN”?n:äuÚşÖïŠÿ¸¯ÈsœElhĞxì"ÏÆe8™oâº_@„£ÛdN|ÛÊÒ1†i}x˜Ğ<˜×dÇ
L“×‡y¡û“ÕnÁ(‚¶
ÔA(%éQµö˜¿5Ù B^ßI¦ÛGÈs9É^Õ÷Lÿ`ívÍş¿ä½J8/¾ıÖÕ]Ù"TñB@Øp,*œzSëÜèò\ÍˆuÿU0NG”Ì˜ &|xœòÈaGX äÔêtÅ¼ŞUÍV¨ñØ?‡2¨µ´óß˜ÎL‰Œ²ê¿İñz#šÇ€½9A_““tåÙ­eŞıêí·ubìÄeßNŒ;ò¾P_l¦Y8™nüoÆhpra×‰$5\²:®Yä?±x·˜F@ƒ“o³7•
£¾jáÒÜîWª|Ö4~(óœ¥«³¦_Ç“OS;YÕHm\³ú–½×U™>¿_%›ü âÌ0dı¿(üõo²ÕTÕş	šŒlqeiÓwôú«3f×€qê9o©[­xñ"yZhà°•m3zpşääÿÙ
¤wl½åğÖdDVËŒd6I&6pÂ:UHìG5‹ìáp+¼	^û
Ù@ûÖtãXLâ/¢şìmdR7ÚÑ™·®Ú}g'iìÅÓJÛ+¸¨k×‚ï¦ T™†O·œf‹6BVî±ÖËgƒ2Yï7¹í‘İÌ!b½Y;šÆïr, ÎnÀUÿ(+Í?]í
Û‚k›÷' ³ñr‡²õÍ—.±››[-µ‡7Bš2ìrº®N§¥({]ƒÚ àğ¥ëNÔÍ˜%ÿ¼zÕä0Òy¶P]+ËtZom–V^àß#…¬)¯ë¦¬%&¯Èê¦=õdZë-*ëŠ:a’¡´ÑÙÄ½˜-ôøZÿÈ±÷Œ'SÚØ“û¦ÊuÂ°ŸO¢XåêF•S+Î5µc7ñ‰¸8G×“Óe^Ÿ‚UuGš´€şpÊcïõÜ„×ÿğÖÚÀ0±¯VSGæŠ+Š<ÃOÜ§©{ºó¶M7M)*õò•–¯Šœ'mß½$•‹	ÎUÔEÚÖÕ_C|×Ælh¼°a»=7ä°‰"…qHÆ„Î"ğS*UÊ–‰I¸aæÉ×ÌùêP9$l†ëÛíÜ™)İ?EÃv¡·o\q8Ò<qSRü¸á³`¾¢ŒÛ’‡]Ø"iwFÂÑoè«±5¬÷®‰v³q° æü4§—Ïä©?ı¦?Écı†æ B­A2ck™½Óìı¤ÉÎ…©:ÊE3»Eèìa¡ıdQrø¬%‰6¼—#4È[€Š%ùSj,µ €FPşíFv®t6GåqEãdn OBSƒA©k0°ôlÅÕ•OXYú²zd·h75Ÿ>UÎÓàíBû²x¢ÆìÎ¥èÈ|±é¹FjKùi˜Ll‹lâœ[n"à:0+WpxÁ±–¼éÆ¢½	@"‡³‘*“‹$~u¾TTq:Íhûø' óò:²M«×¹ä¿h~áˆ÷ÀHÊ…RÁ”¹æš ÿ9tm7>æñgQ¥Ù¶üü¤»0”‹z>köÑWü!2ÚZ,”’åXfVô5UW3KI­„ƒÛ=ûC}Lœn>œqÃæOdl°É¿ñ½¬­jæâ@ÇmY}Sps8¢½9)[F’—pÄ$wßiœÙMb54c8Ê.%cVLQb¨Ïnu‚µò}ãµ¡d²…ƒr+ş
÷b>è°N÷®Ö:Äí5­ø<Üt[& K- àœ˜§×F>*^ÎW1Œuƒ  ÙüZEh°Y’6%ÄO!~(3úY%»=T©uU¹m¤ïÕŠœVS 8ípQ•¦(ôß,àpâàx;	]íñÃÃcoÕìn…Œx|,ç¼öãZ}´<`·z£PZêZcø97Bbú`OÚC³øy ‹JÀ`-à9§¹7óµê´‘"~]öü¹s7Taû~lyëÉØµˆİ›Ã×£¼á“ûNñ ü›Şñ1è‚˜JuæB«¤¥}Jî¦µàsêOw¤Èj¹šì<ÕÛg_áarC–­T2%¤{EfûÀ±Îhë©DË±z»”´Ê{JºÛÅ™†çÕª^swB@%5<)Ó§Àä‡ŒÆÓ{Á’ñLxúc¿UÄòmÀˆ½š°¼àÑ¡‘‹Ã3‚OC‰a>3÷œ)|.ÁK~I7Âa0»½ù ¥T³•’Æñ<df>säË© ÒTB¹ì-ë4î†lİtÉø%ÉäÎ~çítñ$ŒÁ‹[sãİ¸µSòJ"ú§ßãÀØYT‰‘‹ñı³õ¦Á¿G!¤H©.—[	1{öH7r“ÖS•óçiúRº÷9„>,ş—f/§lı}"­ÛEºtÈ‘ÁWîmCğÊ¢`õ¸ày ¤‹ñMmN@8“¬@}Ä[‰‰PIJæÓû›–hÄ“Ïµ_´”`3Q»Èw—ª*^ìİ?’L_ÀeÓ4é·ˆ¢¿?‡gR†8Å¨–ø­„.&Eú1D¦l6g"®ıtÆÒŠF~¸«Ziò+æ¿ˆ¨‡a´ TøÇ7DQ£ãUAvÂÅ·$wõ0yğöY¶…s<j9Â£G‰Eõœ‡ÄR¦}3>œ‹ d;ï’Ãø»øõéàÌ”„z³i5òH÷@Ú”÷™8éA²ÑîW¨§Ú½iLt±,ªY\èR!²…›öå•IEĞÍ .äWè"'C“³×¯¹UÏ
vc_„#¦Ã´ô'sÄ«±û¨ wÄ¹|ˆòb·»W4K:sä$Z‘›øVw÷ïŸÆ`¨j&%²dT—ÁALÈ8<BD¦‘ÆùRŞ¸±×YMee®®á‚ª»Ù<öƒ¡í-j½<½SÚ_=A™ o|„%–~%1®.•Ceƒ&ÖQ¿X¼nƒ©Åœ	¸Ë8ÔÄ kLàñ¨Æéã[IÚ ¿²/ol;˜(¡føf »ˆ¿(sùGK#R’‡ë@ÚåB~9GŞoqt´uôÑ»„ƒUê­$%&D &§•ŞÌ•½ 
JÃOŸ‰ÁÄ\¯„#*nÔ2át6t5[_å:Åa¯µawÍ¾Æ“=Kj9<' ¨äé•«³<“ÊĞyÔJãÎşÑaÓ¹/ÌJïÙj;z8}•Ÿj[UˆAHÉBäÉ¯BFÀŠë Ê"¿ dãüQæQÔë§€©ÌßpTÖ_§H È«Ş3…âùc5ãy·‘3ªàStUUZª¤0õòÙûã'¦ûüÅ¹‰RxÉvßoÙÓËªò&¹{N!š¿4ô¯>é€Ÿ«ğæô¶úUjBM¤.XÍ§Zë‚·…‚ò0ˆİgXyÅOıÚ$ñ:~¨Vë”s†+ÕıdM¯òLôd{ ¸dJ@RÌû£Zèå¹Ô¼Ìê[ãíÂ£>&õbzO—;•µyEÃŒõßGdç~jA©ÂÉ¼Äd_ÑÅ, C©í·v~ŞÖË”-R®Sˆaï’´ñ»KÌ±¯}IÆ=p˜¤y³‹Ó/YaœÓØrSÀÄ¥Ì´ás"Ü	¸xÆ× ó•ÿP‚üã"2pz/'»p ”C¹*¢eÂWù°±å¶)ı0mowà}{ÓÖÅ¼u³-UâÀä
‡¯œsÈÓ•4JÁÀ+³.Ùèl½œ,ª>{'W„ÊûÎºñcjÑ¼má¡gÕÆÇ$ ñ­
üÜú©	~Ñ-&ølVJúv6lT/Ì7½Š³È}ö× Šnƒ@=PA[¡¬ñ˜¼èQñ†çÿ¼…(õ ! *¿ª£yâL98 ¼„¹å’¯¹ÿçGTÛ,!äò	›k“ NÿÿbM<#ı[¼İ×iĞƒOn¦sÁfäÖÕl•Õ+ÈÙE$¬†d‘/1î#û²pÓkğï<LÅÌghÄTX¯l±U®M>­•R8uØ™•dbo±˜ÒíÈn´¨]Ïë’ô¸~·ÍwÎøÕş•¨:è&½S84Æ3º¾<up|İñ¸uCW‹Å}?™F½å¾®‚ÃJíê˜¹Ê&'-–ÂaÄéöŠ‰´¦ó×'m€q¤¸Z­óúGBL?iI„MølKaú8apU‡(š¼]ôÆ?o³|<Üpîãmû7ÁÄt¿	Ğˆ®cêW2¡jjp±n[zFı®<Ş“}ÏÀî±	‹·Şd$Z.‘üÕáT6H°k¦5ÅKÜÕ“—<Ì÷¯-ó…æb7<ÁŞ0Àn«nH¾BÃ®¨–XèX VA©IĞB—#ÀG…¼B@ÓvèÎ¬CoI„º_KïêÆ|ã˜‡¦Ÿöáú-`Égµ÷åæ·ÿäáãaë½bhÚ¸Gã;&ŠhàÚE¡Æß«¯¢™S´Åfcåb¦ÌKkLT§ogÌ8B_®†9`‹>>bFW U¤cğúÏ¡U“§dp=ãVA²äOı?h,ÄN7"¹Òsc h²"uÁ]wògá˜Ğ°ÃV#ºg|6¿ÑZ ¸‹(İ!mÍ™$‰÷E+³Vt‡2©mÏˆÓslô¨˜ö˜İv*¶q‘iÊé2ú®t›c~À#TöŸXxÂm–¡3ëñ„C¨<Äã³kq#À¹¼6 4ÕÚğúPKÜygÃCR»Í¨_Ë¢~¾Qİkİ“[cq'„•JKØ–NÕşÚè‰ûFOˆp|<P©……¾¯¢HÆ%İ·—Ñ;íã¯µ´Ğ4np"ì*{8ú’ç<ĞW€"xY WŒS$øİ”KÃİ^h@Óä
2¬ßg¸Ù¾wùV4™ÉŠÒUÒğèOCïLOZµó(GqÄAG·'Új:œµqĞYE›vÂ˜A+ÑÕ‡sèİcˆı›J):#Ïş.lÏ¹Ìoß:TY:ä¯ZàtålÆ
—´Âå\^i]ñ–Ç¦ÿ²‡ Ä½f j=è¢yŠ‡õ
”üÀaJXÎ[¼»hˆ§…È–ğ ~L½·–'å‰Š˜Õº´ìË–»ŞìfÆ|ásEç£4RQ]¯[[wÓ™Š©¦ÂÅuuf;‡ú…Ğ—¬Ñ•âÚøHª:¯ië¦Ğ·á»£å:ZÆ„T†2Nì¶P×ñy9``¸´Ø 6Å™Ã¼æ¤/á¢8#ôÕ[2­ŸÚ¡C…#¨Ê»üq*,.Î˜—‡£(Kş0G¡#+g¼,ŸÏÕ¡¥\+Û.=İšX²³«™”³‡a ÓQrŞÔ×¯šÖ@|z.;æ¯_Âë(9ªhnsıíEÚnB®³â ×lxã=o‘Â#ûĞ[%“Ø_5Ó<VI;{yÕÉí1ÿXªıyàsñeC™ù¬u=´OÓ¼ÀF
]Ã‚,ÜÌĞõçG¹Q¶Ÿ"¡˜[\ÚtoÈª<ÀutDdè– ‡õ¨ÊĞ=–`d,Ê69â=ˆ…LŸ¬V‚€ßløôÀã¿ˆ—_ıû˜›´û¶ƒl¥½öğß+˜s»)]	|Ø]?¡ÁËs†[aè}¨ Á^™tÓK[m#2ÀÈru³70‡BÏµÉ›2NÓ†ºì”»ö4^1ÒÔãğ]“N·¾=~ñË*	3r¬s†jí¯|5³i•Ÿ(„×[ÃTğ¼õ­T’ñÒÄÔ?A58g¬PB¤b6¤1dH‡¦óñT9y˜‰ß‰’ë}¨	w{4oU–1ƒ‹u€r¬UÒşŒÃùQÚ‰û	öŸ»£Ö¶ËXİ8RTXºÍÛ-°úaÌ>²Z°şvÇ’ÈÆCÌ4×WˆS[ 	äç`ÃüèçT'‡VSAí&83¼L;ƒ)9ÙÎ¿ó"a™4¨x›ãmÄùdYPüº±zaæá¢­˜wşéÚhûsf4 Ó	6Ç—9¼íŞœkãĞ„z¿~-6j†Õ°¾Q‰é2Ávïê³F'VöIÉ/Í²ü“ŸäN˜ï†ğ¨µÆÍwËºn Q6
á÷¾Ï„$4ŒÆ|ÜÏ„,Ô¹dîÛDf»^ŒÙ“Ö9ÿ>íÒ+ït
”1?hÆÓô‰1_QİgÖñxÚ¾ÃãÒ"­î3`jÜcàËóMÑru×CŞ-’ælÎ¡b>»Ø™¼•Ô1Gk®hİ{D–|ª×eı†túĞF§¯:ªcYpÆÕí‡¶‘ØÚD¬iÏC%Ít$´ó,zP/ÔÑ2p>»¹÷ÛFÇŠÃ,İˆ‹’O²‰ìÂ·5m<^gSÿ™M¡€ééÓ”‘âñ¤ÓEF$~`~ıg	Œİ­aWnSïbÆH?ıV),!O©Û^m„J-ˆAòñ@oÉé´sw}§NÊè¾Òs)•ì_VPş]’dí$¢Ã¥µCéZHGk-æ`ŸY4.ÁFvEPø‚ò#0İ›^H]AüpíøéÇd¸¸İiş6Å Œı”=/]¡õUô‡S{èéÌb6 I_–ÄËœtƒY& ğİ"v€Py*ÃEöe²D]Ë5Í&G"²Ã{ƒ»~»šªÉùŠ§Ş÷ß×ŠÑ Úîc–XÌ-sø7Ù-UËå†VÛOÛ(î®"„?ãàtb¿t³çŠQW§·ç›©™QıÌç¿ÆŸú²WˆÚÆñ@¦-v(UÜt—n²ËşŠÅã8D†<¨éÕgIIÖô7Wò©êI­~+½9ŸÊˆ&?Gå6dM‹"ªü„Òtf™‡â“ö-)5¢ƒ]Ø¹ì`ò™ó®¥^™âœ;­#¯mèm8å€êğ¿	ñVæLå&l™çª¥Ì¦&…RŞnşátB"ƒØi±!„ş,½¹!29Ò‘¨!±AK2ÛÂ>E2d¡ÊåÍKYØçd.º?ñ„â_¿S<,¨°ŒÀô+öBZ¶#çxy«z†§¯RBWEy- <bnò*  (Ïï¹İ#ü7=˜ö3rÖñİÄ»¹<à“º-±ú?bö2®íuú§	E¸O&ĞFªTp•GÇ,ŠÛ}¯aøªõ‚jåJÕš:¡Ò--™E£1dØ5Â¿ë– íxØ³s:Åt»éÁ'3ùHMÄğïx(n?d[ aí'O×EZçÒòxà£ÍBçéîËµL„€7b£íÀ/®¹%âxEÛ”{çlox‡³afAj£Ûğoú‘3i›'Tä.^Ö®¼‰†ıÅüVíhÆ>ã_)¬CáJ²SùiŸt=”ø?úƒ«d!¢†<ß{«¨å• 5/›>;¹:ùQ]ç#^$4²6SÊò³’rÈğ}hY"YÇd¾èÚÖë$qK“ìc„g_»[^éLŒÌÿí@JğÇ5+â§qœŒÛ>DäúShÖ9£œ7ÛMm‚è5kúÛc;@¢+z?Á²²ƒ8	|”‘ËE€Î!uÓô÷v´O„ëŠÒTQ‚ó9ÀK¸d\SáXe²mëú¹+	É­pfÎ[ıi£ÄqŞUå¼ÈMï6Ê
ÎüzWb¥(
Ğ1ÒJ×K¦ÃÜ>÷4/ŸÒQˆH²ªaE¬'“Bq¨
ØÔºÄ¨ÂÛå7»h¡}Á®xeµãâËQv)8É±ÓYDzğÔ‚è'¿–"HŸb¦K©#è9/{ìê.ú½ÇÕS.™[NeÙÿBU¼FÚêäİ×1ŞGQ«`Ox–nlÖ’˜	Éi£¿y×{)Ì14@Gƒ¢TÒ."…Gæ`WJÖ¤@Ìé:{
·‘êÔ4YëöIE ´g’¡C/f¸Jï	pÿX´­ äÒuR´NYÄyèÁ‚­$…"w°íJàêClÈ›UñX¢>|/D;nèÙÄ¢=;ê¡‘7IHÛÑ«Ïk‡íä€í‹—üºÇW‘ñ«ôe¯¯™^ [dãûÛ†›İtÈ®Ñx@³çgÏsW1Áöà‰£hpyånxÖŠ×”É“0+ÜºàŠìÛFÊéYÄìÆBÁgÌôôlWù4a*Š‘ø²móº ~MBƒxÀõÃÓª‘ş¢ªP1¶Ë¸FHq«òCE}bvT–—­ùüàÜ¼İ@äÜôL Â—ñrÑ‘<®‚uò^XÎWE2íJ=Zs	ÿAU¿Äú$}t†X5İÍ\¤ 9Åhšà.Ø€â¬æıÓTØXÙú¥-ÅÈ¨ÙãJaz™Æû’6ÄBŞ;ñ>¤èiuÚ]ÊİË·üïz€Æ—r^ü¯óïÒá°å!“å[}¶°ü#jÊv<vMß.¿y8rëzeT¯WZõ‰° ã(:ª
ñÜé¾äè¨œ4ø‰i˜XeÍô(ÖÏ› &¹”Nø/¿š‚VR§Ù”A>¾»½Jv|Y*âüñÓ"É^û¥«beìòÔ¸Äš>¶tE£!´Ñx|¾¾	Ä—	}èæ¦ºÎ®Aş]>ˆ	š¤¾ 5o^øx†¬è2€Æ¨»îmÆËeŸñoƒRUw"d‡+ 0úÛëe¿Ú”ãŞö°ƒŒ=TÃÍó=×záWbÏ’y;L¢íz9—BÎ"x´œm|¤½ê¶*4tÕL/ä¢ĞxËé{xs¦r[^êv`ŸÆ9HòZX°^ÕÙÑmUÈ®ï®0FÒ ´,IúcÄP@İZ­1Rı|xSw[jBÌ"Ğ=LEKL	aø!-o P›ôôc,Î.ğÛû£é‰í_ìgb -Ê¬dˆÏµ®Ùêk®`¥. “E„ ˆ	æÉâİ­Xª·å€ëÅ6M»•½& P1]q‹åUMõF4G9°‘ˆâêŞ«ôİòz§ËsbiY%#æFRÉ`Ì$š¤£f!æÌİüœ([Sıgœ"ìÔ„á‚®GW&ºËjZöz®Å+Æå4i@¦ä¡İCÁìŒ'¥ëv½¸­0<$’’cÄú½wÈ9X?«é;.‚D<¹ù¢	yí«T¨uÎ‹³êsÄŞ×wT±tÚKƒ ‘¨œ×Å*[¡¹|ªbV¼¬w½¹+0>Üw®Hx=S˜„	2™%‘ÌÒmÚy¤V–®¬£¶™Š6™­‹-êÙÃy…çbqNjÒŠã8xøÀø™Cå8†¤“ÔÊ‡gŞ‰§U!]ÉeÔñÙŠU-iIj°ğUİ.Ö™©Ä–½¡-—şŠUndÅn~İ‰t;ĞŞ¹ÂzùÀN‡³÷b,O^ÛõIeIóKÇ¨†•’d<4‰m~Nmu“åen?—•éÓ²Dm”¡#t5·¢S/ÆYÖûç–"<º"„ÑK˜N€ñßİv_òÜŸâây´»æåu.M¾Ï|ù¥Ç<ã*Vóªƒ®¨¹FÎ• HíDF5\"úÖ<ğ–¡:-×¨Gü%4—Úó@ÑŠ=–*‘;]Ü•_©Üqp+ç‰•ş«^l€*¢ge¾ÃÃíÊBå¾ò2‹*¿rù[4Ÿ)Jş
{¯<…-§«Ÿ¯z•oaÛºô©Ş°:˜““…áFÄmuó—×OÉwä1‰v—`¢ÆaøÊÀ_%Ypíÿ=
ÿQYŸËi…D¼ø,Æ¢"Ê¸'(E!],4´FzÈİï!ø_×˜¸~(…ìÙœ<q}@Hw‡‘.Zâ¨É±é$àsş@Û_›~®x8µÔ]A€×¸éP‚w5}˜ØUé)qRëÄÆÂír¶şDw¤5æ.AIÅíÍ¹hNx£1¤Ùò2™VàĞ).´œô{ªa&ûˆÆÜ¨ZQò¡Ö2Iä=bJ¹~'×£“K×ôùVCz®GmUVÙ§€”oK†“0=—A–Ï`Eò}ú™ßÆ¿s°ª‹¬·:W¦óY$Aâ]àöùo)›¯íÉ-9C»~ U›Š‘xRiÇò „d¨{–öéojeÙË‡4o)ÓŠëôxøËL€RÈVã‚½¿Sà·8Qsÿ»5ºzÚfóHÆÏÿÎŸòOÔJ×\@%õ=¦½$Õ\;¦™=wşŒ‚€«BÂPåÇÃ/]L@†`ƒM	ú …béN A=H/‰Ñ·Xn÷©âÑ…$ˆu’Ãç%"¡uÓôNNøëİªÀ7¯“kU¯·œ¤ª^¥*aîäŸ
ZßäT—A¸¡V—Ûü˜ï^<ûi18>AKWR@Í1™ì?¤v05†á’–µ\¾n×0ğ"f’ch=<µQ6mìXr‰EëÊ•U-à¹êI*ú%meLpÒˆ‡Ñ sËé8‘Şµ­ğxb÷ÛÇÏšUlîÁÏÓ¯íĞcÓ
ÅD54©¡#Ò]ŒCWÇS‡kTùÇÏ$Z”Äïòk„–io£JíĞ«svH®M€v‡)&cS&—ÚS§Y,q›H¾rã—6şàÖkóo¬¡7Oå§†õö*«!3X&®ÑfñÓûÿ×}©¢cÏŒø.¸{‹Ë/\‚<A-›ñ„ÇFÏFÖÓ±²/Zå¶EÎZ°°°Ê¿ºXAÂA7À'd½èZğC0×\n)\Êd¬xŸ½:ªÊ}Ú‹Ç^·ÿ!b°‹øÌDpÙqâ–DI°\Wi‚ëµ}U¶44¦a+òe|YÆŠ´÷÷~F¸A¤2Uco:¬ U,ä•#"tir[ÂŠrwÅ\é»ê±VÊÃM³pQ¦Ï³C^Is<‹—¬§…oJ4yğĞÈ‚PB[æ7ú«./º¿ä¨™¾'&=Ü»Pe!Áû©Wû>goÇï@ù·£Ò?pÄ!ÀÙdğ¢ 9'~x»( 'Î0ºU(Ì_± ˜uûÛÆúÓvœ-Y5ÕOB‘;K¶êAÑ)x ^`'Rß†Ë ƒII‰ÇOñ)ÔO4l=”^•Æ0aä«.i€	¹«í:¸à;œıweNAñàTy÷†Õ`×¸)ºâV&ÆÖõ9Äß‹±Èb„JùI±#$¯3º¬9õ@I™ïQ«†³Q^ŸgG1¼›N„¦0çä`±·uE£ƒî\
Ä¯`Y&O°*	|!R°*NÜMHƒ™ìù^µváGÏs›l³Hò-,¦h$d_’Ë[:şŒÊèÑ†jí'v;æÃ–\ŒM.®Ä2>ÔGÙÊŞ¼Ú&XÙ°@åVSÎŒÉËÔ?¶Lµ” |ã˜èÙdšŠ–
»G“?ƒS~™FìS>¤è»w$ãhı£Ç…Áš“áµ‹¯Ç{'q±ğj®~2GÔÂ„Ûèäº“²ù2fNââ”÷‘×h]ÂÍ/e»VÑ|ÿğm0SÃçB¹Có>O…	3úA§ıû¢_§İ¥@÷ÅœoŸö=ÁUï§ğ§·ót»ÉİSO¡î4sè=Å kƒ9„çî†ÄÈ1Ğä!k¬Æ=Œ`é·À«G¶g¶Oö`W©SMèAhv|Æ}µN†·%ºFòPzWJ‡¦Ü/úñYx‹€l?’¾#İó`òëUQô+«vÅ‰¬ˆX
&¦Wq^{ßüÙ¬®C!JoZİQ\ö¿É”àçäÿš¼0T×¡ß©¢t³Uî‰{"oóåà‘JVœ`Ïm|“¿ìHp£VCbQ@ò;gÙòJ£Í$ÈÕY¿‰Î°Ëû¯ä ì6NÙ9i7qWÕÛüó´à¤Ñ³üã˜ +BÔ–&#fÆ­¥Õ#GWîS~~ƒOE4ı×9[QT?{èpî³­Ê8’t€„jÚe=KŠâ	x°tÖõô
Lr…’C]oÛÛÔZsD Î ÖFÛ['óÀÛ‰ıÄ+˜ œ®)LÄL§,<{<ÇB©DIk– ÜÁ¯¹|_å.ëœ¾²Ò©	:UËf¸.~Ö5<N¡æ'²ù©®Ù<¾P˜¼ARß5°¼EØ^æ½Ú¿L^şB6V~‚SO£Û^_¬H`ö­[ŠYC‹3)YT8†ò '¡í”b§,ñÇRy9rÆrá	¼Cµ\¡bÏxVP´D„Ñ¸ÒÉ“M6³jM„¤õƒêáJûèÙb˜z|Óšg22–œx‰Ôæ@`¥  Au@®D º›ßIÚo
ª²<t·öÂ÷(†ô¾¤¤ğ™3Mn°N:älâ'ü¸H"€ÁzÇ\•AD€JLõã
 P‡6æ»öğBÊ–]ÏWL÷mã
®21¥Ğv,ğ6d|(ØUµíÇÛÿ›êşs8ÂwQÿ5zœÿçÇ1Ô&ßÙÏš<oËë¶ßCĞ~<°ÎŸZDöÆ˜üş¥vö´‘kË·?:’$ÕÊ±1ÂÄÃÆ—­Ú¬ã;™¸p…+Œù¾Û2å wJneµC+J†§¦aĞ”úM¦âñğëï`¨E¨2w5w×á(á/öj£ÙşÏ.F9şÀÎ'IYY9¥o¬Ç Q>¦£¿\í¤Ì¹\0ŞZ¹ús<¿	ÔÀšCÜÃ4‚®‰XéLÜ‚ˆÊ´h¦mNÏ*K@ó2\Ün1êÿwjÏW‹ÆLUGÖÎKÂ5”
ñ¨­ömÿ»Z}ZEá¯¤”ğ‘óu„ÌöQSóİÄ¬fºè·JÈ\‡MÍnp1ÀMyŒŸ<ô´26—î?İ†':/¨ĞçX¨ë­ây‘‹g…ı}`İf‚³×èÒ
Î˜vş–ßâê/DÚ•Ìú~e‡oé×¦uv¸ÃŞÜ œ¦‚~8â÷Â/ëWßGƒÿIRÒÚÁ¿øB‹¡vC€¿{\B.ØRŒ^;ƒb¢ô¹5:ln¹ÌğSŸï÷ò¤¢d9øwîä(+iË“áb—såj`˜1ª×"Ğˆâ’ÒVK‘ÑcYç")éƒ"Ûôbq O¼ñàwÍ<è@ºM>_Bû:VHğ¹fŞĞˆœ0‚0*æ‰¸ÅÕa¶t2Ğ”å¬„ø•)=¦9(ê>×ìi´}ÊŠÿÍPµÚü·¯0³ë)ìı›¦
øÀ[÷çã
Ø5Ğ­İsĞ>x-Ä\œ£¿¹±Í®	 k¿_l5«0Å+Â¿ö¡±Ér<E˜¸j®¶"’`–‘»ãhÊ=‘Öu³™²§Ö10ï&ˆÃ>Ñ¿¦o1‚c3¢õ[P$\\‡eÀ=7)ª0š6 dô@ïÓ‡}Ï£xüù0Q·ş÷ì”¥Wó>‚É(Ã$F¹QŸ¤aøŒı½•ùÊ8>ËSr2Îß~ı©.­@\=“$Yv¤O²ƒX®ÈPOã~É»ÔÇ\ÄY>kM€Æì~•@[º·[“0"=|J"i†ıöÙFEÒé!ÖÊ4kJæFá“è[Ù>Fè÷û÷gzïD›(‚ÌN¦“=Kí;±»>áÉ»ªEƒô:ºá¤ºù'Êªp®4A$oNàvŞ}@Ûˆ™hx=5`8/¼Ov”«…1RÛUß÷Ì‰É*ãT’Úz1îÅÖ
!åm†öÚ:[.Ò´PĞ¹Ñ#ş·¶aªÎæ ÇVÔïß*o="CŠËfÛÓ”<ıÿjTÒñÊV~“…¿™å	(6b†
»*w×²ÕÎhpëè•³ÌÏBÃDäåÈjÉ[Ú{|4j™[/ïDêçáÍ’¥{KmîÖg$ƒoá4çÍgå‚yôôØ¹s­À!z(@}ëmÚ7Î[‰]„ÑŠ_”~;Å±Û³»Eı†½ÊÙT‹?v8´İn?œãí]ˆ¥‹(J˜É!)U=jlÔ=N f‘~'Îu!ßG&}Dó!Àòı½f<DíèñÇ€–©ï8'ya?ÿ<lÎÙ
®+ÔkÜ>èñ©S\×ÄGˆ<’v¦6ŒgÖ7c"Bx¸–ÉüDˆ‹Iı¯S¢N¶…!ùšÕÄ R±¿µ8VàÓ£¥Doµ8)w>Eõ™y&~{”²	<K®!Öhj¬< Ôc
Ò7DŸ’·Í`u'S\™ç*–ÒO5"X‚a*í."•„Ÿ„¸Ö?ó¦ù­b<Ã¶ y4ø3ëo„–V<|…™¸‚©ÜırÓæ¤ &àk–}‹ª{3æ®ùz^°Äœ˜A4*ì®¼'»¦q÷JIé4~ÒıÅád€È Ù ®÷t©`Yo X’ù7Dß‘•€R€IÅgÉ)ÂN‘!J÷qF:(yĞƒfu§°•¹-r®ü‘óå%XDó  kÏÜ¶Š#¯~‚œ!àà‡¶qò£^vá|õŸ<İ²-¹²VˆÌu%ƒÿÉ¢ÈŒ»*jE,&EB=Xº8Uõ˜d{FÈjB]¾¹Ö-È•AçÛ­Iû;;ü†T12AŞš}-¨„ú.BŠ± ½,ÌfX$Zöİî2,êA
Y/	@äZ–±&îdZVoª¡“jØUdjã|ˆ§.ºÄûÛ˜šwŞŒÖJ±Ï{İ¿iX½ıô¼öª9q}e5G¸NßÏW¸[²ú—gå°®é]t	0¶ÔEÇ£Y­ÜáÀÑMèƒºêlxùÛbA˜Z«(¢Šş+t”q¯´fˆ] ?1&ı3j«“’ÜÆ#[âî¼©öËÏ–iûíİŸ!×9q!Vìıu§hcoôx†öJ	Ï¤rï(w«näÜtµÅĞO4ÇI}ßu
dj	’RÚZ)°iÜ¿ pA¾:!%1x`­¨KòÓå©™Uü±pïcö}U—Z-I'CIÌ~™X*‚çîc›5ÿ€Vy²ÛÉiM1¿!§‘n>4Y×~Pû2"^u-K¤°O“Œ{*Æ+ OjIä#§tœ•›ÖÀ‹—æoÃ)®v¼*>‘Â‰Âí=~/JD+³Öc[w„ÚùÒÜÖÕ=Ú¡ñéóÏï=gùšÄ7¶Aƒ½}~ºş‘}ù–º…Ûê’4¸4ƒsî–·sW¡eñ¼0Æª.yó§ûöÓy3Oë°AÁ¿·‰»ÎlGÖ0¶|å¦—› |ş>R²w;e›'¦7ï8 kšßKÊæµ3á?gw`‰KúUA©ægC¼«ÄdÅed./>\ÅšÆ]éß¤ı§½Ü :“´Í€ÛÕøé,Œ†¨ş€Ù_Ûd]r-ØÕšŸõH«›¡aácÁÜ‡êb¼U5ŠôÎ•}ÊàFÆ4P#ò†@i\˜ÿ“(˜ÊÙ^KÊé1á¶ÛEÌÎìëjÉšxÆß©{¢§·¡åôÈ£ó|§Şìa°ÖPØRõ°Ëëÿ€Yk$8'@åĞ¶¡%İÒÎN¼}ŞZ®0“ñÑ"ZxÈÖi|/š[@œB<ºNÅöÙI
ÁïøKk&[!“›´#Ì_q¶ª,ŠwGearlîİ£‘Jù*YS¡…P»m-qšúkRŞØªÍúéÊ»>–Ô	×ßg„¨ÒN",rS¹„JØº´ô?é­uYP°S‚Û<uË>À•)®îA	¸ñ&e‰XxMK^’±a³µÚ¡2ÔXô§9Vïs¦¾TI!	áÂËÔoŠŞÛè²a”c”íyö† (~ê×ÑÉª6Pªd&âÊ#i,6á8ŠF7¸/‘˜Ÿ¨u*â›TÎàÙqC¡<ï|—ùÖn¯[}Q15SôJsÍO‹i(×¢‚nÎØœÃ®Ûqu÷iq³jY“½ªBaù­WµÈ‡=3åğ\0+‡Ös›ÆşŞlJc‘¾ ,5Áºu”áÊ¦Nzoç.A(©=L¥¹É¨¸AG¡ìû–9§½?|Ğ§À}=¢¶İp»´šs`‰¶Go m„ÕÇÏ+ƒıK} „Ü»Å-øë{øĞªüM3IP0+1Ú)§'ÏÄ¿€$ÀgÇğD÷iD$±yo…PÇÈÊ”J4µ„·=÷Z³·q07ª×ïİGÅòÖxp8¡Ö·ã‹C# uÜå€}‰~ı_L´°WÔÕZd;oÅ CCSÇu6±8òıİşOĞ’–€.MÏm#ûUì©O¨}Mè÷tŞoæbµ4L:5L•nÎ˜èô#ëØ×Š)›®‰Ñ½¤ÿØU'L·pÃ•€ÕLqr!á¢0‡Í.İ¼œ¥ùÛEy;á÷,t\> S’Ä¥sÿ¢5á¸Ëmy±yk%; ÙˆÕ$ÔîeGili>?ò¸Ët<ÊiÒJÜ
âÜc6¥|qmWÔÊü#Â•ÉZW~Š³À½M»ÃYZ"²Ğ õ5Ä¡N¦¾ÖßV²:¤1 £ÿ-'Á³I şiè÷iO=I´ nN+âOîkŞÔ ¸Ú”k,ŞÂÎE—,Œ–9.(¾ğä<Oa Á½hŒvj1ä?= ³ëòÃ»NW®JeSäSÏz„·¶ŞE¥ÇÚ¸ö.ø0e3
à4gw7ƒ¡tL)’åúŸ¸Êo’âS·&2Bê`7Ù —öÓGáUç‡ƒğB‚Úv1Çj&şöB„Ì#C#™¶u	;šëÕÚYLGóæ?;po‰_ƒŸêD©ñ‘¿Ëk¹Ä0{Ó¶Zòg‘¤N2˜“Ar"8­ow­~ÎŠ}8oáî—™=yğ7©…ËU\t˜qüæQ8¹é`bË‘“oÊ—şÇ]P.ÿh‘ITb1Lî\WˆK
¢ş+Ös-éƒ)ÉèC(oQ)¦˜ÙeQ]£h‘‰"WUÀ>)ìèåw~õâ§82ÑÄõ Pf‰«¥İ&áÑaôE)º…EWğm4zf˜Ï»©~©5^çª5ˆÇ¢ònìí~û?Û'8æ$OUuiD¦ÌÎ}şT%”^ıë–ùs„T«Ğ¸¶+13tÈ6F‹vª}ÀÃ›Û
#°‡;©p†È¾¹T™*o6nvŠ®!rãz~Ñîõğ}÷ì€øTlI‘4¿]6_<íŒWéT=Ş[]yÈëıå/[Ö6ø™±=½—-[‡D³œ,fÂ‚ÓíšĞ ÑáDv9µ2.°îê"bÛ(‡~så–|ƒEúş}@¡ÊÀPŒ<“¶€—Œ?¯;²kÒ¿:Z.t÷[÷¬B*dûVÙÜÃåğe§†ÔcR¸UÆà— „º Æà2ˆ‘»¤q€ä£MàÓ&bèY²îãTPzC E­Ä^Tì%}~»©¯ı<NÀŸû+ò÷NùÙx7ÉĞ$½ßmØ
Ómí®Ll«É­î+6Vi¤Íğ‰:‹šNVÜóEo@N­È…ÅŒ.Gü(è÷càÍúÖ±ß—ßA%;ú–—¸êÇô(XZ*_¨ÀÁ-ïÌ…¤(f c]
Şà7=—‹3ª@Iì‚ô<(í²Y»§UZÒå¼80æåÆÿD+‰Š^Móúª±¥.&‹-9Gdj]ò¸9‰J&ÁôV’õqÉXÓ|‰&C?‡ğOÓ
×Š¯&‰UA¿s«¼}ÌRMv½ÌÎ8#Ilı¯ŠÉ"Ğ«Õür›C†:Ên¼Ãùò{[bU}´1'än›Ú]ßßŠ3%`›ZewÂ	'á)ùr§˜Ëj$¶§(lô‡×ñè{E¬‘0ë':¬×r\g  „µ?³Ï13ß˜62:ßSuÜšÊµvª”mÒMÖó·7*^èé·w©nµ¡‡<oMjúêÅç¢B÷ wÔ³ïĞÃZ¹f›—úbf5°ò/³`°Ş½4ˆı/<6_ÙÖì@gÌ¨Y]¤ÑÂøÔ?Œ¦-0µIòÖU¹aÄ†"ó@9·6û“‹Áa¿Z¸NA+óZŞJÙ~š›²áağâwêtÏµµš¨ÒXS™½ä{ö·Æ54ØĞ‹ªê<@¿†!øxCùC‡}‹6wÜH½FRqªJ±æS½Şë¾ùdhôªŞÜFï¾¶™ônƒ§ğĞ"¯|›Y`?ñM!6Pm# Œ%_¾*Éºk”FÃF†ÍÅD¢•BÖ¥uÑQ³3K’¼¯YhnPù“)ºù—ÎÑál¯[*ÍEŞbá£9tÁÏaFNJUÇëNøõQl7~JÿqUy¾È^•£GU'hĞšsÑ Œ·#ôOÕî>×"â—(J7ëh	{Ÿ¼d·È¥œĞöØ›	Ø-L|	\š<Õk@T¢=6Âí °waÕ™¼“`‹ùà”FÚ™Ëk¢7ÃU•wÙÿl‡ñÏ:zıŠ˜ kq"\nâ“?õ€'Fö7öMÄ™ÕOa˜Ñkd”Üƒßh[|Ë·«×5tü )’‰ßÇ¼ø©…U
?´ÉÎ¥J¸A~ñJ³‚N7‹?”E€É	hÄ\
¨Ôúu/Ÿ®<…{WCQp(ŠÛ¤ÿ„5Ÿ‘ÒI¢µ×îˆ<Kµ ¿¦‰WöşPØ|
ÓÜ$ğ8Ñ}ª)Ê­ac˜v:ªJÅá™bÊ“…ƒöß¼AËÖÊ
™ğ?ä–'U³G÷ ˆköÈª³»¦<<4•ÜÏa¢b×9Auûøä•r^Xo¦Í×@úÇAûŒ õO?.ñƒ…‘gnÿ0nüğÊñ¡8ô‡à9Ó¢¥ñıÕ„‘@ªú¨]2Ûì×º(¢‰ÙÀ>ãƒSO{–~×½+öãE8gÄ à¸…ÇŸƒÚutô¢s]iä@A•7´¨ĞÅY{U1-1şÇóœÎOÍL;•ğyUÈµPFm ¹²}ña]n+›·OÛ$õŠWØ‰$$Æ˜ÃyáS”–ÃÍƒ12š‘9À/ S"]CsLR
'uOqªS=úzŞ&íâæa82B³o%)ªnï÷ï›œH¹– ğ9%NøBA|T5[Õ¶Åt5¹Od¹ Âæk‹`©^å(Áµk+•iI£È>Ü;¸Ö"®¡TxM6·ª¹Í–¦›ËÃ9Älı˜‘DË$‡r(™p<ûëª´è*gch@Åäû–RÉq “qŸäkÙ›'£‘z°Úœ=Ü„êTLÊ»ÁÅ@Ñ&0æªOªHp7‡Nâ…™ÃíTËï	CS’öÆVä“ö	êˆPpãQS<ÛXü T$…aŞ'ˆâ#@)=ƒsæ÷,Y•3ÉÏÛdå…ç”ıR­0T"	ıF]’t‚m/ÿàÏË6¡¶¯¼´5ÉO¹Ğ7ZÜ(é¸İG‹¥ÿ¶~4¿+åÅ2Ğ-x\	ï*·CU¹şë’5®íÏ2i+šœ£§?ƒï6¥Œ¨ÿpİ4ÒG§pz@é~°Ä}¦¨¨i›&‰Úî“Uœ·É¦Ù—b7hœ&¬²@}D½7ey!¢+]ŠHÃ««Â ·t©_çVC?sËŞ'Äúå_Àáî˜{cjì	}	ô-²Ä#á?GïS]QÎM¨vö‡=dˆù¥*AŒ=ù9û@¿ 2šÕ†o¤8¡Ì<q&éíS¬0„ÊÕ?I›¢¥âê9{|ªü|®”ĞëÃ#mæ±
rRÓÙ"Ìdó'®¬¡ÄØ{f%•ëğÀ Ã6K¾]%Ì– ¡6DÎ	†¶Bş®Çãö_…ø¹{QhğWõ¦õ~!áŠ@¬9_šÖÚëÏ¶¤[€÷^[Ã¾*CxË!‰yDËá Œµ•éš¼éjåh§Re©¸D ­ê“¢ôbÚöÄ:+<¡øHÚ“(€§Å-ÖN¶›ld3oÏ=`<aòÖ4şğ,É€i.ÀGº—şæö2£Óï”F<wéOÇPÍU¼]‡¾_$À>¤«`ëá¨k7WDE”ğå
y‹§™ C${W¸µÿ´qjJ¹;“ Øãôy¾•YÑĞ¢Â;Vèç1+·­Ll~T%Ijvxˆ>½ô@†ŒüÃ6¯nâğ‹»ù_QÓJ¤L¼4MÖ=€ÖjåEÌ$`èNŠTÀÓ~N¿¹§N_»™¼µK2:ç©‡×_Û©g!òÂÀ0]öš»%†Æ<E8š:¤éAçœß=¦,qá|,ù‡o±
›¢íw?[ØÅÇèjŸ]A8âïŒKéÌù/GIÿìkp0–Áäá¢NİÀx-oå:s(Ê÷ wA%	 "Íe ¼àÎIÍ¥C
}bl½’Ø–p­€Ô ›µ‚a«MšæZØ±í/TÚŸÁ·c·Iú8–Š¸¾%jæ£w4Ú* Œ1ã”ÎtìšBÑ.^d%åWèb((ø¬Saæ©Ìxù"ã´½'¯Ù/W½®i¬\‰ëL<"¯Quƒşª‚³ÑÈ3ü
\duó$Q^-=Ä»R-HI BîÄÇŞNİµî(ZÖÊ cÌ®K¼•;r³á!‘ró_Lüáåğ·§±®¹å¨W“?šü„–‡R³œ”¶lÊ(UEÿ?Òü)­1ÊWâ‹|šÜöÃô“p£§œZÁEÛw£:İ‹ˆåä‰İ>\‹:"“Ïî|é´ø·—=LåŞÆkO6²´Á¢öM æ‚ÙÓ!‚	¢šâlw™À«¿éÇçbí‡ó9i¡Ç”E„ş™Á!cÀÇĞ	İ!Øˆ<~—sPæ°·–ší‘‡Çb«¼ªa>c@VEå ò€e²>û,5¤H›—eÈR2r–b@²ÛÉë~Fñì—+¿Ğl„òN¥âÎv`Î"ÃvDüâ]WĞ·şˆ'ÀÑòÓ¶›rm5Ü;q•{TÓJJ‘ï,‚m;<©"j.İ#bL¸isúJDì}}Üà0jû4ÕUìşˆ'=6>eU£&µp6²Ş½‚ò4]¥—òœ€P9æ:Èw°¦9ñ§9ßIé¦¾f”ş·5)k••jÑÙÈ#ã"jİ´llÂÑæÚS,kK¸ gkxõŸ‰Ã!Á'–jî“EbÉÊI‹_-U´hbŒMg…W,/kë(Õ87üÑí	Ak‘Q" ³Oî»]tîjÇ·@ê{x>~^u§ßñ`£`ŒbÊYÕyßšE¹@çæU ‘
ğ'ÿ;ÿëæ´yİiŒÁÑsæÃm›™¥iğkRWÁ»DŠˆêİhã*œÌê¯ò;mš]>ŠÇó]šé¨Çu›*ãHsôR\"‡7)§Õ¿Mğ³vH, /Ú–©Ü
fxB©«ÕóÔÌ‰ù¡hx—€_&Bø¥x‘ìUáÕà÷y°!<Ôµ¬ »ëB­t¹R†3+P
Q$‰*a^(KÜ³1Fèz#°°™P‡íÒyÿBö®éÛà7«t™¸©¾ÁƒİˆË¢ÅĞ•ò"‡Y©óÔ©¯ºÑ²]EH4$š(3ësíšéë?,4év!²=SsO<6?¢P!áÙ‹èmEB–­“»Ÿ´w¬ffÀ-€–ü
õ>ÎbI\Åt¤zŞV÷;‚ßS†ELqğşzÎîJ{&´(ëê¾§kúa
B¢E[í™1¢öüp%ªsç]—) zß°zŒ<7IQíÍñ2'6H¡%uó¼ˆÓ£ı¦÷ Ú)ßx« Y‚®ì~åRJãİ6*ş#1—a‰õ†SM…,eb ¨
ÖİA?znd|ßÄz—w¦©s†à7Ñ4)‘3è3ØhÙÏÜÚEºêùù–~Gw°}xsúÎKåñXµ1jÑo¤¾¯ŸfrvÍºgD2„²—°º¯û´ê´¦½%Y3”ÁEª¡ èV8ˆöé*‘±ü™½d–”¾bR-r0¤|È»¹¤#5Û÷Mm7ò¶İ§"¶Q´øğï(3{Ü•¸U¼ÆsN¹‰-×g›oÖ-é5¾Îp¯[îÓÊÒÉªş(î»*”aıŞÂ	Õ’soĞåëıÏ)°3qÁ’ OgCØİFzî\uYõ²dÀ¼Ù”?W(»„Eöñú¼”I„¾Ä¬èéõˆ-BS]û÷è¡CJşšËpm_ÂEˆtŞÿ1÷b)éGÃöÁçË¤{ƒ–ê~/˜QÁ¯~÷êr³ÛT4^#D†Q§æuÜ£0ßá±üÈú.û­¿5oD&\m£¯¢®WËå 0"mI…‰€ûd"-à¼èÃSuæ+Üõ#‚[/Z×[9CJğys÷/<“&öïÔéœµ}j=ƒYöQAçô½ÕaT›1½„óêÖ\±ÁóïwÕIÄ t37»F¹w£VÍ/ı6l´5]ãvnå¤äyiª¢ğFt'¨¡øÄ 7n=šëƒê{šÏ^¥B^Ü‘âèDäjçË.l;é=€Éå‚ÏV;‘º¢Š=Ğym`Ú}£`2RÂ¼×¬€—%3(uÜ90÷;İcÜ˜6X˜tg€Õbí]åWûËnf…µ‡³¶aÒì©’]ğ¨OW‰J¦İ¬çÏ³3şxDÙ•	"0yÀ>)ì=
3 ğÓ~4¨Š¥Ãh·íñ•xã<Ù'ÏŸÓò#üìt(fEÒ+ÏÊ‰8m“\ Ü‰>n}ª?z¸Bd÷—Ó¶¬7€ùü4^+”Ù_´ã“eİZ]ş…Í@¬9§ßÁNïM—Ø„’)Ô–³ıÜ6ê¬ÙtÙ§ˆÏZqØ&ºÑ>!¥ÒµUN­|'}™ß¯[\RgH*òY±Şçq7…!÷ÎZñº±\ğD]IÉ…½Ç5±ö¨›Q6”¯Ñ I®±‰ó(@2`„›ü¢¢æí@"‹‰^§d>¶:®„/VÂµ}İ
 á°Ş‡¼y³Uò¶â±^Å·]|ŒÊ´ü0Ù«âÏØÎÄ‹e4<œ7;EDÆÅştKola[š´*Ò¹½47¨Ù·6I&1–ŠÌÎ‹+Çæ¨é@Òõ½÷ßü^ÁŠ1ò¤i	¶üØóTHKğg0­x\³ôv—NhR”1‰èxä×;äGH6!U¨àÉáÆCñêÜk‡»ÇYa‡r§Kš.|¨×Å†ü7J€L¹|ã OŠğùö±èT1wÁqÒİ5µå–(ñ“DƒmäpU¤Jæòé~ÖnA
©yüïPRâßiÂË(ù„C!xVÉç‡¥@ kOJù;8àöÙİŸŸ¢LWés êÁüÇX‹D7G°\«´hğ€T’ÌÃ´SNŞà™º1e\¨ÜŸ.“€…ö>ÂÅ‰²BEbA;½&|mDl:ÉæS£¢
9ú_¿V¾£CÍ½(px¯ç,ĞÍÌÈà6©µ”ø/e¼`·¼$±ï—£˜•Àv¼ÏÄ£$%gÃRšB'÷
%CÃš€¨s»b{»4¯°¹AşLŒnD“Î W%A¯/!3©FÇà˜„°²€cMØ»¥°iÃ­úŞX¯Ç;€pjñ>õCpÍ0GPRı¥Â)˜pµñUÒé}ıòä#ÆkÅÈ€.·7Æ–r+T3ò¨:A·*©—hĞ6ÛTñì¡5#ó9u{»áŠÔÀúØf$ÚbB³›­”àíRï4„Adp¨ŠäËÏZn%¡¾jCıCœ’Ä»0P#§ïc?ø<-ëµÌ?”†œ&Í1vølÁÕ{;ÇÿvŠ¨ğ:ÈÍâ’-`Õ¬y²cIıZËâ¯+½Ê§Ûâo×ã+‹_8ÓzÅŒ´$Õ†è#b Äø+Ø[nàÅ"àî!­kÙ½ü>ø;l5î½®s›H–±öXËœOŠªğš‡åw™’á‰Rò«;¸¤.èñ[¹~LR FÖIÖ$n©!´#´üwÁˆ¸‡<‹dó®Æ©arÇ¯ĞËO `»M] ñOŠ„Ptt/wçCÁ<GÎOVy?¤œÖ‹2õ6]+ÆWoÔ¾ëûZïğJı“MØ.æí*{VçÔõö
ó­ˆ$¶Š	G£ÔvUã{<|ï¬Ğ@_‡é<Ô…D<8¯´KM÷_œÏÆ…úş’äN–.væz¦Ca°(it
¸iu9
«¤óÓû÷› ƒ¢?¥neéWb~Çëß¾Ğ"óoˆ7}Ïã8Aq´
‘ ¤’k[ä’^Ü1äb]SÙ´#Ÿ½ê’DŒß÷­¯€ÙÍB#¨©ˆ“º;—‹}Zëå:–‹ïCaiËÌ0˜½M¾väÔ`†@§”Ï×°L“uÿ¸óø#–')Q'¿yëâœ= Öë—	D»cğ[:İDD4İ‘võüÿöĞûØÜ(üâƒ3:û›ú¥e0}"éœ¯â[ı=v«kwDú3Ààa*°×íj.ëÙÈäN˜IŸÔOÙÄÚ“D;+g_öX­m}–Lìdé¾ïëX,-"2èš\Å,ªr£6gf""ƒÌã§”³ıñh‹=÷'e;a¶–oŞÌÑ.pÇ@"õª‹2ØìÿªÏB²	µŸ%D^î‘k:‰NV’Sİ©ÓÏã-Îg5Fá¸„¥ê|l”@Úv<µD¬ä‹[®ä5èà‰–ùÆµë;c´,,ÒÿË´á°°Şaè³tM«­Â Û–ö$óõmÔï•EsDof™“?…Xv¼§+ln»2¹+º§œ¿s{ZŒº¨Üyì¢bY:gV;zø—‡@jº×ùÜ›ÆĞ L¾ÿ(ïò™ªpg¿ß~˜‹–0\ƒ).ôz+ H/N>ZbFÅ¹‡B#]tèÉR¨A*‹àÄ…L;F|zHl€¦ÅJŠ?Hk9›ßœêlQ«5ş•éöÌ}b]©ŸPóŒÛ+Êõİ‹´›vV–	*ÏÉ¡6ñÅhõU C2´àÖ«†>ì:{VÓAÔÅğæ qxîõÏ¾ÈbkâĞúµödÚÇÄAÒ¹eôòät'ó*e Iº„]:°{ñ-íŸ¯Ş•’I…íY(Cí%¨}™¬MTÍqä.5+ÙO$l™yw„È0$1¾?x­ñ0ƒ\Û6øË½jH<M5\‹ÔOÓá"UÖ!?lŠ¡ëT’²g¤‰‚cÙ¿jcƒ&_Óòº ôš¬_÷1ÏùrkÿÊ‚pŠèƒfjù¥lÉ®'Ç$RîßëZ®ù6)D”ù¼Ë¶E¢ª^ë´™şŒ8é³ÿ™ï
™s4[ÁàymÉ‰ó#ÕCÉ-çàŞƒB˜P<gyŠØXà\Öh7@—Òyè¼×ŸÍr[?Zæ%@_ÏW¤u<ç¼M1pó„X‘ÃKy_yøİ&¯dÊNAlá*ÿQŒ©qhu~Í2ÕÃK½k 1o6ÍÍ-Á@cVîë;^Ç}™0kÈşÏEG–á¦úÁMÉµæ¹5[vraeñã	heâö§µzCÍÜ–o'Û[;,’TÊ·»f[&z1ÅxTùp6RŠyçqËC5L©èBÒ]GüP§Fê†ë°Ptw’h9
lgG	j$ŸW!f”ÿD-8kê=IõkâB‡&>©1`ŠÛ-ğF”uïsk>“2şª§»ÇİxS•] ˜æºí»¾ÀjÆK0°;KTa—»Ğ½ôä@Ê,ÙC²åªÑo	ªÏ»Ùäa1r£µ[?a•ò*O‹Ê‚óX±79|ak»Ù+»êòÒ
õå×­‚`[e6 è*×vå…üÛè	êy­©s“˜îÓ“?L2ÃÂO˜„`‡ÉùìG­œäÕÀÆ_3ò|êåvò|zá¢¿^9ˆÈÃFfëC;¡ëx3Œ,]p
ÿûÛ4j7Qx—?NŞ5úÕ‰_Mß#%Iº€>òg.ûÒ¥ºBŞüÄŒäÿ¸]kc±öë\ÌæX›‰şÀöC3öœ¸y„ÛPrû¢ $5À˜ûÈF½ÏôXä3¨òßê:I‰Zn@¾œjŸpÖA7WA~
~ò!3›‰a”7»”‚¾Ì­÷”ÌĞr‰Œ™~|A›â²NJ¾-gø+mØ‹Ê¢“l-Š)Î‘ƒôèpÛÑğ7â…7?xšÚ,ÎI‰ù±"“…Ka&;FÒ¶IÇ`2kkŞSH2y†/RŒE­æFkĞzë9Iè5	7Íq¼1X¸ÚA¹'¡®¦Ç„Ÿ@Æl>œóªbkŒ2üŠ£Úˆ5ÉÌG1–6H¡òäm]¹±J™hkb¦pTbuµ®æ?x”|»±_/)ßñÜŠØÕíÖV©1¶IeoÂ¦…7rÍ[g}iû¯C?$
T›©Ş'äO“¬å€ıÒÊ ¾WYS‘Õ}²Ã<hèI³.¨øeYÇ_q‹ï<oz?˜‘7UQÿ÷Ü-5/ÿB>¤s½~—[Ş¡i |]_}ÉŸ1XF+»ŠNzG>Ì¯6!ãæ±/äÁè³¯üâgh2N¹Ÿï)
’ô¾ {9±Y4lÇÌ"‚  -0j.¡x‹Ó³? –ëğ-¦Á*;
İfšh
ByÏ­‡ëª #(#^ÇŸbéŸ‰$Ä(õÏ«6Hq ÄÓû®&Å-WN"hPÆo±¼.^ø#=ÀëÕˆ¥ıíÅ6¨Fı™¬*ÒgA•!ª'ƒlíc{$ÕCaÕO‰®:ÆukĞ0×9îc$87d,ã~?ÂV#¥‰yİlŠúnˆìFnUáhr—¸ß'3²SôXŸTûqÂˆ¢ŠPØr¶Ô—É¡ÀÑvŠOo‡ı:5EÃ-ÂTŒ‹j0&Ë+»€ëL‡¡*•±gH Ş§õı	Nb„ıA*_×•T"ëÚ¼
³Ç½"t:zÖ“M„İØl½–¼ïücâÆ‡l1zòöò{8/ú³ĞAAè†ËGp”õ<Sşâ&Ï3ºb`t
)ÕL-tlä$GHREdY*Š©°uäwàIhŸü"®…<ø ¶6’<“@öïğØWı	µW×Dş8w(%6[Ñ]½Ü6dzÜS–{Ä¿?çôzù=I4í§©B) ?Œ´ÀdúDg¶©VBŠEÅ±Š*È[Dì›S¥ùó‹n~ò:"×øEì @İ!ß…=õ….¸â#¢ô®^é‚¡¥L¥…Ô ,•K~§ÏíÊe>g+ÿÀv/»xq}*·ƒØ†?±\{ú[Ûş1®Œ,ûê(›”fŒj—O!<ã/„ÕöîğªHD‹Ô¶ê?œFÚ]Uø¥–†=¨‡hÙ¡	QĞ'ÙÂn¨0·	Gå\¥~}&ê½a¹hq$:}vôk:UÌlR°°„v)ºãlŸã}0åØpF°ìwü2Ã†‰ãÅœ6†KË?ìI%«V‚p6cĞı³“É`ó*¥²ˆãêKæOxÆ¾¯×'_^ÕñqøÓ?úŸwÓ\.¿OAÉÃsJİÌBóá±r‡ß¤+ÂáĞ¦_AîÛ¯”J9¼ı€	#;¨°’Ÿ2AùğÔÀ¬O™êiÍ=R²c×T÷¦lí6¼‹Ê)½¯dá²lûì2ªš]*,qáñE_k{$ª«ÑÍSø„Ø—1™ÚŒê&Õ$V7¢Y$)ø&” Ë§¤ùÁÃ¿’äN{h¶„i¬œËĞ+’ûÌyXr]ÉnAÙçÍr®qG}TÚ ‹ï¦ ùÏ,xòMX”I\e¡mê	Vä.[ºŸé7è>ŠæpÚˆêyk'[=$¸†0§ÑEôjûÕœq9ê bÕQŒ’ØË Í“ö›2(ë0¡Š¸L'eöê‘Jj; ŸrD j?©¶dPİXWm˜ªJ‚¦ÌÂiÂìf¦4­ëDó[	Oˆ ünR…
ƒ²ÀpUª„…ş›_¼cá<Š>Œ‚4äKİšÿc§2íæ¼!áp†ğÏ™—NÉã©)øĞMøÆ@¬±lp²2I`È¯V´…–ö¼~àYûS1<ü–Æì9~} 	»k%4Šü¦ƒá°£3oëjtº”[Èouåv•ÏåöçÌjk-éB«¹à¼²êQ6€¼‡Èèe¦ÿ²÷
ê®K:«û“¦éFk}ˆXº?QRÎˆ}ÄP,tgGËµ‹'óÆ>´ˆ×+cGö”ÃRÀiQ9_]Ó„‘¬ØT`¡ÕêxM´©\^öA…²„w¦?h|OŠŒÍ±³âœ™&`-¸;JêVïx0Âì Í¡=8<œˆ„ò³$»’Éq˜ì¦:íÃ›¾LköCFŒUNæØ!o¥½¤ôÒu?›ÔÚE9Ì­.º¯Cs*?›u>¦äEU¡à¯ò¾ùÍHÂãåÎæI´Û=jÀRı;'h¬imş?ô¡*åsİF’¼\O¬³è6`9Æ³±` U*Rt¡R*=£i¾UŞgßH¥ÿ:$Î—ı|¨aV£^]:t°^g5L~äı¼—'VœÎJ"¤£\Á&Ä³–½íJÃÏ˜:«ûwñŸ&æ³fÎ{-¢Hr:—ãì'=x} (K˜«”,ÒÂŠâÑsâç”[Û-IíÎõ\†Pù…åbiXIY¹—©®÷—zˆcÄÎ)ÆãÁâá†¨ïírï	/$:<½šåGš¼OŠ±Â“^}¢æ•1™óK›î S{ƒóÇ}ÛlŒ½ß‘Ao>Èİ<§ÀA„  (`’Íñ„Eš‰õ5µ4£‚Û'#hz´1A"ºËÔ¤TárÛÿ&ŠTßTXJ}Û’%¯áXÁ~q©Jü¡İ„m\û-cƒ‘É±0³›÷s@v¾éÏ4ï/B³ZZ:Eeè/_%Ì_ì%Œ–üç*+İøàÀ½—ÒÀß¸ü·ƒg¦ŸF«¾92{Œ1`TNt°ì­Ÿ5yz›¾ë9"èşÇò%âJñ>lMşa‘È\	ªSˆë«?†ˆ
64&µäàâSÊ ôIÎÊ«=KÈÉ8XoKÅsšM¤§€ø0°Á±‰
Hæ”Ğ9ºËõ’ÅÆ]UA}Mp5Üì"Õ4Œ8%³‚ú0”»0Ãk² K˜3úÄ·4¿Jş‘;-Î…Q\ª&"*r6ŞX‡şøWıJ¨ê§¾šoexæ“Î9sö¬àO=
XM+º9
+1GÄô¶ÙÜŠÅpp7Uí^kâ:âÁ>ÔÜê5Ú@GBEøFü_ÄÈ³cµ2¡pBpö"Ñ#R®Ì @`İ” §wLÇ™±<UiÕyñøigBÖî’±9i`e•ì¡½gô/ø‹d	ÏwçqüV:ö¸DM\Ò¢Qs”5!KV£=/Ù­êÉr‘O@Ø „µzˆš=€Ä—ÌŒZ—CŸH&TÒn"8‚–ƒ¯3z
™4zKnÑ{÷õî‘Ä4w¯ıÚóÃ¤ô OÛfìÿ9ÑFaß[R1æ·g$"rFB §>s"kĞÛ¬Š¯’Ï©Fhõ,¼‘õ±nğD!Óã2áÂ[İj&v^®´ ğˆ*3¯*0‚TGÈ×QßkŸ®>ÍœØ•¿sçò}
2ïŸ¤~|[¼Ø÷Dä3W{ï¤è2cŠ"³Ÿ£å>‚«Xö‹*]8®œ*¿
ÅRlÚÃt0‚ò¬ìŒú«xÉˆÖ ğÿ¯áØ6ÿ­b4µ„hªvñD¼w¬î'‰FBT]½2p;ùB°eEñ’†  ‹8ß—{˜ô ¯Ï€!vIf±Ägû    YZ