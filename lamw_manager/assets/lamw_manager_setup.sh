#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1605594340"
MD5="3edd4834985272fa90a57453410d7379"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23108"
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
	echo Date of packaging: Sat Jul 31 16:47:23 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZ] ¼}•À1Dd]‡Á›PætİDö`Û'åÛ
-ò;
í¿vÔj!ûBRJlBv‡Ëƒ³J ¶gE“Â	Ê’4ğjÂê¼pòÎ{9ƒ”$RŒïÈÁ‘ÀI·ö}±eªÄ`*ñÑ(å!è\8ËSL]BğŒT³ã–X“ÔÿY×Æ¶
=†¶|ÅkJÖÃï‡šÚƒ´¤¢RÌ'E'Ë8b_ââ¬İÌ£+¯áŠHDª'œ‹YÃßæw,Ş-c‹¦yiÈ÷oÁ¬H÷9ôa½¡ƒÜãzßd©‚|…½Ë$gıYoç¤€xTÜºpd™+hô-ˆÔ‰¯*õ,bM$¬şÓ@ß&\Ò T½½’ÚÈàLjÕwNÑÒ«¬]Y¹ïÄ¶ø]½;±öe^=$yô~.ŠFÙtØ#µ`2\,3NÂ›CRAĞª/9ĞÙƒÉª7Ş×{‹1,5"ÆWšŒâÕ©÷ñdÅšqdP(ìTšÂ8¥•Ö2èh€²îIOi	»9/‡Ì\¸E¨Ì´Ê–[ÓÒ'Jµ¥»Õ½>F¸æ®g•Ej.Zš–Ã²÷àÿÔslĞOQ5™öƒİÂä•¼ÃöÏ¨ÑAšH§8‘ëæİµ"Ã½#ğ¨~İá"ô“)°&Ÿ_¡…­¹7ÆŒAX­HŸğ{bú¨Ân_ã¸Ğ0˜gåkÒ©BÓyHàóCb¹†„©‘†ˆÂ>.ŞÅ!ïÀuü®–Ët;7”5f6ss_‰ü+¾KQü>Ùì[àİ«@²sš…×h­š@É©M€s[ª•«9Ğ?‰J<¾Ä33UœK»öı–$JUDÖìW€ë$ËãY2t€İñe Ò<g`×œéê¡¤b:ò ÍÄ˜á­yc+H;¥{;¿@ÃÙŒ¾Şª›¼Ú)ì§S¡gßùF.û	€¿øoÎ•ÉÎ4Å¢åAhÆZ
gS3 W†¾OØ³Â=kJnJÙ3q «ä!©†^”b§Âbš‡å»î5p màÉuÂ;¼÷F…“K¥Ş¢Gß
ÑÉÕè²ÆöÄ²ñÏ²È'Ï$Sš¾ˆ®†K·¢&ıJÁ–²°şˆæ€7 ’å¹äe1SßBğ¢·ú­ıVÓÀ¤@¦[³–Ë}ÍLÿâU ù¨7>V¹:[ˆpqñ“0©İN6Ì/
€) …‡.ı¯òê¶‰¼·ò‚V±ö@±>*<ğÜş[tVÅx¯óR®ùÕ6‰’vPº9S7a˜üÏADå;‚5Qö6_91æ¤œGíhËx’aÈ`¢Üß_àixR+½ìŸ¾¿<öŠs¤sO'no( øò47ªkÈB³wSFf?J69nö	tTß×¨Šÿ—1®Ñ§ò¼W#RjlÌM%8x€,deæÂyô¹wÕBê³Ëü¼éØ¹aöj¬!¡€Æ#çwÊ2H4¢óÖfÛ{ïLÑ¬l¸x>&³ÊÂwJ}KoİKT’[ag/3Ñ¼„z÷ÆX]ã~ĞCÖå©6ë,:îÈÓJuı·’3zåï÷Œ"+}˜{qWÁlá1(°ëÙgl.ãêq4–}œX?¢£<	üç	‡.‡ÇBf¸mßÃ€qúª8a‡ß6_¿K¸à-­.S@Š"nÕ¨öwö1–ó¤ßå÷ Äc¾ õáÃXˆ’‘íŸ&jWôy»ìÖÕ<jGZĞã•!cX©Œ†¼é÷†QÚĞ¸  oÚç)Ù­ßÍ—ã×gû²Zü@w1-`÷„)0<Ç’uÆ k=Q1“-Dû»11¦œX¶’ê¬rÒ”ÅjXÛY”5Ã¦%uS¦Õ•f{Æœ˜ŒÀIÉ.)o6Ú’Ã
öVoQ$ît°HÉğĞï§Dp»L#Ïµ¢åÂ—Dnjw)ÚjH›uNá¡š>É™µ«Qu;Oj§¤zõÎúÇ·Ø¾#FôóÿößšYÿğ»+Hë–t~Ñëµâî£."Å÷]I^r—»j)âyRÚ¨86ê–¶İYI?qçè@}9¡HV£F
Râiÿš[3ıÙŠ_òQô|÷‘b¯râ²}Ïf?)s‚õ¯vª{ßg¢pÀÅµ`İA>tM
Ğ—‘#Ü2ß›úøgµ‰¯OÁÍ¿mp˜Òp¾-V©Ê®/^ä$aàv@ÅŒ9)tç“ô!æ’”zj,˜2ğÇã½õWĞq†Êô{[ Z\é9ˆ·%Fj·çù©–Îş C×#PÚ×D­Ò £n{`æ¨]¤…“>'ÅÅ%‰îJ+Û×ø7hÇºÛWjÈ$¥ûò°µ/o?ÜpÒ^ÈAìèˆ¨pu¾ÇŒmÙ;¶ägŸsGxm k¿ç¿ÖVÔ­ò¡ÑºMıÒÈ±¥*Üµ º.#Ò¿å ‚~oª2<KjÌ³ï,ºÉÍÖZsZ0_8ú)÷´Úu¥Óêã˜¢@|iØÍkÜCƒS4BÈ.K‹b@qâğDÌ(2À“P¤epD@Š%öN88«` ìÑöâ×ª~Òâíé—ÃÚÀQœ§œ6,ßø…î_ı¯(6à®Œ§/#2}‰Åşö©Ô¤.Ÿ(/éCY&(«šP·»”²«åR®ˆ
œÿƒâKàØÙ¥×¼n«èÉ»e—Æ1%sÖÙÖ`[¤ú7°ıoTŞæ¬H÷±œn)Õ­X5*R™hv¶8ÔÛ:Ê¿}¼ï¨~­Àë}ï
î;HÄ%ñ2fáôß"5…\H[ô¬;Ôyx3M…ï‘ç0HY‘â6©Á5b
ÿ7áéGèô½€Tl¾–ÅØ4~»p|*pS£ãğfãYU"ø
^áÂ#Şx"ìWfÂ·ü{,hQãŒ&‡µÖ¾)aa%Ñ¸3Âš´‡r % 
&…pÜ<ö»;ºm-©Ë²yÛŞ;ıxA™³DŞˆ1–Ü+F¥*û^Ú¿şY2§Q„‚í‡¡#˜]/î¾L|)’Í[ æñø8
y¢íV×IÌ©J~¶9Á¹Û‘“á}Ôò'±£A©÷B±¡n"XJR§y…ë4Õ:³·°Ì™äL×*İ›åY)(KÛ‰åœÜyİs‚øu^·Œ—KBôã RPIüIRÃ£cªP¯Ñ)ÔF¨ ±AÇƒTxğ®£z ‡DË«Çı'ú0	Læ„Â˜å¢“xAçÎû€›hÎ²Aè¨›`@¬
çİÏ@oNd~ÜXcy»Z]¤ôµoá¬/qƒ´áÆÛLl%ŞÊêŠTøé·‘zÚıÁ"†cùofì‹%u‘¹°f3‹]¸á³;èƒ&eer„/N]=7Õ¬P!/dè§XèJğ 5<O‡÷&˜Ó2y%ïÁ!ÛÊl§îÀr'.i¼è”ÆOÜ5é¬Å†VJƒbª»EQº'ü¶:YB =@ŠÏêTRø…=]Ûä¨‹ÿOµ–ºX İğz‚!	yØ¹í§8väñçèÜK‚ÊÁb+	:ŒäÉècæ´@ñ<Dl³üüug?µ3F b´}•³Cö'[û$6®Æ^DV§‰JYÂY@U#ÉˆÍI!ŠZÆ³ÓÂÒ%yÒ5]şñÚdÌYÃŸGÇ$‰ z×“’~c~EËîk8·<ö,6äÚçEÕÜ`¢¶z8BĞc×O±^6–½;Rÿe¯ğÓeC'XµèœXØŸ³yÚÖXº†Ü‡VsÄd}D!ZŠ‡Qdß¹ü9zàµ\‹~3GÒ§7è…Y€L\8qÇC7±ˆ’ÃÔët§hs¨Cz¿™˜ê
L$QÎè¸ÿIÕ§y Aâòkï²µQÅ³÷ÃVVŞû‚ºqÄ‡8Ôv¯kØ+XòWSWù\£…õ°Wf…÷÷Ğï&æ9Ğ§ÃdìGdÒ®¦iCÒYQùô‡}‰öAt%á<r‰í™½=®±ô¬õKC'f‰ß¶ßiÂÂ9Ö•^&¶³/1XTƒ#íñ9VÎY±$¨ï‹
‰Ş”É¿ç¸Y
†Ç€Ä;­j	õN§ÔäHpôÅ6àÿìaµ;E	§N)æsm"×~rñ ç´ÁSr¼ûİ±AÒuõ`ŒaI–I °ST³L)¦Õly(İ.
½O:š¼«Š"ê.öŞ+Ñ6Ñ‘·G¤Éh.J¶`n?Â÷yòÍ+ÚB'9j¼Ia­£´G~ê®¯@DS¸l}ÊŞÜ…O^4²­Š‚Û·wßÁ¯€ŸİEì.îÿiñˆ—JÖÄR~¾â˜” ÜÅyüÂ9ª«¯VÙYˆüDOcxµw¬³d%„´`ÂÒñ§Ÿ¡­Óqr¾‡À+ğìfs®«`fÌV‡eÌ×dºB›@eáY §¤çÃòYlVÊ§Å±Û|š ºk¹sĞ6ûMĞg©»§!Ñ·"	O”|`ê²Åçm~ ó îŒçG°çyÆÒrĞTvè~ó³¯Ñ=P	¦‹uù˜8Â&
.ºuÃÄ:'. âg•ï•¸œß©Ve=iû @>ûÅ¡lÔš>½J«ù×“¨¤ßø­÷õÁ;É(q¾Fíç(¤IÌ¶r3€q¨¹£b²UæM‚©JFçª»YpÛÕ47À‘Ò„3êĞŒÉeŒá05L!ÇS[@XÌ]&[ò”ü¼°„)§ÍÉ0ù_Â„‰)Ë
ÖL=Ğ[u,bO‚Ä°N$QßÈ²47í‚âÜá	ÍÒ «\g;Êò	´$Ûoçï#{z¬hhËÄ[1`ÇĞÚ­_y·0Íº	§1­o¹ty²‡ÅéJ½’³&Mòùi;½¯“@Ú­?gèÛª|¥‡Çöàñì¿/3¿Ó·²”È)7bm±»@6¯NT
*äz¿/|Æy[¨	_T(£óZ^›¼ÚÅÌ-8+û“Xß×"ëw—¨ˆwÛVŒ'ÉA+Ö­©RAÜ.À6û‰·îT¡¡ú«”Áø494cöM8GqÕéc<ëqåÁ¹:±¾í¡î8…¥¸š^óMüHE®†jˆµ	u¡0&—Tiµlq4Lõoj;¢ä`bü^"àkôŞ÷˜™BƒãÉt²ç¡Èrær-òhÌWY€ :^/ø¡Vzß2P©¡´LUˆO½í-‰!ÚüĞ§•„|è?™hÇÖEÅ…şÔui¸"^@<ëÍÓKuBj¡RAuò/Vø\j9Öl°sğÄ¼@?ß÷Wf«jjòŒ´ì›@ée©^fB0İyøœƒ<‹"¦[ô;Mbío%ÆÇı2s%C]ŸçLîLĞHPuç…´K@ş‹ogá,â~]Ã\İÙõ®ÅæFÍnxµ^/	òœµÆF¢›äogFŞ«Š©˜w˜ÆRK¸+P
"Ê+Ğõ9c\¤{bRü(ÔÒı¯§|x›ş—M|>lYQrŞÓ¤·+ÆQíd‡ÂÏÜH`±}ñ±0bgaÊ"¸U­Áß@lRÌÑTsê¡Ú¶0&ÀÚNtzw%B5rFcˆ ä7uŸì=Ö™ÿ…fÄ‚ |nG'øCX“;ää¹š3Ig=ƒ	ê)uÃ Ïn³öaß¬‰In›P2+´~œ;¯¼€ø×pšu³¡#­@˜YùL±¥Úıàª."-ÂgX¬°åF4¸µÅÖè»?{À†4y*w×vrá@›‚@%¥;,Èï«Ùô^çX:f['‡zÎË?¢o·-‡c; ÿP†õàéõ~(=Fãy-ÕO‹@æ˜€ùecı\jˆ8°âpõB ìLF2~qÄš©ÄŒâš2wù¶-0s®T¦:Væ~`Ò3Tæ²‹æŸ¡MÁ$Äk„K>#ÖnÑXûªJ¡IÑ(©?‡¥Å@*—Èû\yÖ}+(¤÷bÇˆ¨¢_ªİÿ´_é¼Ä'»cxGÈGQĞ*Ä½T=HŞüª-'N´"\Ö!!à¶¨I·}…"¥´ñBEÌ#Xği¢I¬N›-…$ÚôôSç®¿Å	;áLİ“áæÒ5ëõÃÙ¶Ïy{^qÅP‰êD¡zDubT™€¡EU`=-N ·^XHs~Iè;‹ßJ·5dD.`öº)^Y¾Ì#2Aİp6´¯ÑU:ØÜËHî HÔN õØêwM¼ıC¯æ†äÁj|?ãæâ\ü¨Ã5‚ò*ÂWøëşQ À/Öò®D`Çîø>}Óx~—àù}´­Œ¦ØÇÙOzzEñ4Êj†9ÁF‘k’®‹ãŠ¨[8üÇ,Ò&|&4£JZÚ9agô‰>£Õ‰=€¢Y;(>jŸÄxÎî·M]Ê^c
½OçO’ï¬Õé ­,í P£Ç:+[Ô¾¸lbÔ2ğÈ¨K|uÒ<'`c':¯Rßì…ÂBjAV—ë×­†K{»m´W)ĞÒÔŞW\°OÈ—ÊŒ„ˆü¼ïüîx'ôuOÏ¿ÜéÑ(Mq16{<¬:çôOƒJ–QEúÄAcş4Æ¡}WRY!ıåæ±`±ë0”øxW„`ë0Äæ0¤V—ù6k-½b=±T$Û|8ebŸ¬î#¸Dç>ÿ˜Öİ¬œ>ÆØ\ªSö˜Şc>û+¶I×O
Sé6i˜8+ã¾‚şáQïŸ®‚WL)œ|Zc÷Ït-É1ÔïÂ‚‘)±‹Ô&
9õüT_ï·š˜İóĞòşï{‘ùÿâÁù˜‰mí×Öp~ä—Ò¥Ó¥–¶:ÈæïJ¥L˜öc/qØ´ø«º¬àL°ê2Ö—ÄK¯‰¨ñõA1Aúz¡s0†úøÅÕ0ó!ç¡pLX~Ö‰ğ<ímï(s’ˆ+Úz“záßY%ÔK¸¦1ãí¾™ d%9`GK‰§E“.vK}¾`*ñà†!ú:£- šx¬XwtPIz‰fi:¹‹ŸÆáñ®RÂw0|¹4ş™„ø3I@dqfZÂ]FcŠö¹ù³eQsúvSôyÃVÛˆü±_h@6ıì¢¡3&\j»İõl#ı¾²Àz\èõ&ÿ[^!ï=)’³É*«Õ¶@õíë#1‹$ó’ª´‘ëK1¢IÉh8feWCjòZâª“¶Nây<‡q»¿6â¥ı}–Ã’fê]–H¢…mªÍ:š' 9ƒmBğö„«L´èHal‚|¶ nÁ?:Í
M­ılip+x»·üüNîçÇµÌìûIia*Ü£[‹éÊSÔñv’Uó¨ôËYbH­®”ş×íè1”Hòk[x¾l"øm´	3!O[ u«ÔDÛ—qÂLsn¿é	.›‹‚¯Ís‘gZ@Yb‹?ÕPb•§ÊÜàŒ)@`vHÃ~„qìiÿfÍl©	ÎTN¤È[J¼}‚‡±Ğ¡ŒèÎãÃÿ{ŞOû*÷…¦aèòw}Ãl²®NKİAùc”Ïuš+Íû¤HÈ:õ„Ôä×.Ñz'¿óNÆÒî¬8/„Ü_ øxÄ@%WƒÆáïT&Ÿ~GÏŒŞÃ[g¶6LQF‹ ÜTs…|9á?ãü_½“êòŠè(ÓËŠA¦ã¬ÅÔw†ÅNî®éH:ˆ‰j†¦¶ŞsD(@À‚¢cshz22Y/İW?JÌŸ_X‡çXêSS³ßÊL«ğ¬1TĞÊ¹/>ßà]QŞÆIV`ZŞàf±cnJÓîÌ¬ÙÄÏªÙ!qa¢'bbBaæ]è¢·Ìèvù'%qh– Ræ[^„5ÁÃÕYÁXƒpI¦ıD£9SBÆ.ÒfßMW9ò6ø7‹„SÚ_T£N°
wz¸Ô×İö¿%3I2|®;¼iÚúÑ·àè„iF
Ûêò|´›=”Ë&|b½1´¬ŞØ_¢á“¾ÖÏBVÕv‹6pz7œz¿ÔçE…Ì¦¤÷ƒLÍÔ!Wë§šê¥™·ÏXæÔ©\ù?–µ"…7K?+šÊg4ò2\Nİ
é0WI|Û&._Ú_ŒÃ{LÛ"X–'Ñ® ø«Øé³ß«6á+ò.Î±×ÚlĞM*Ÿİm›ö¦şÜâ]:Ò]¹A]%Æ½õ÷gÎ¸Z0'ªşiNé[V	Ş¾ü˜§…‹Š¹›sÍb‚ßh>ûÌ2õ…xÄ¦²ÎU	Ø-r‘ƒXƒáÚ»ô«—KÅšÅAeÄ>HŠÊ Dç–Gïr4Ï0·k„-ñú†â­yF$Rm-n®<Kc¬Ç7q‹fŠám€¶T£²‰têĞÑ¸^³ò8xcä>PK4)góŒPOqŠ4µzJæáw˜UBê˜é)ËÛ”Â(ì0TáïuÙ¹øqáÆùÃ¬ VJrr…ÁYª5±2 C$*“Ş¹>Û/§ºÌ¬	"²ì¾âå[8¦œşº¦ Ïï~äÁö×äj{ÿ†£õqîŠ™´Ÿ/!mÆÇB¦¨k®¢µ&qOM¶T;ØÇv*„‘Šuñq©´ºÃH°ø(Õıò43œ ŞÒ³5ªå«ı[ë‹ u5(:2µŸDÁ§½_8t0©mÅ@½Z#ûæ…1‘ù¬_´êÿZòî®„ëÃF,³÷*&½0$ı‚5˜½ÍÄï}T*àÕ?`>ÈEQŒ¦ä…İK¨ ´x”‚]n€Å„7g7à°Ş¤ò_ ŸÙMŞ$û5k€°£=FGÍ’j¬9¢¡ÒH‚épı9rc"6,¬™FîhP™]±>´ x»ÂÓƒ—Ë
®úuHZíQğÏ®\‚àÒ€øÃ©ö¤+-¯ëì7ô»w[\ìŒ:İ7±iÛzBmD6Ç(h¸2©àc(F©¼(h>?îÑôêéo 9lxXHJ–G»iåşctÃ±]QQáæëÜ)÷dÂu4! (åš\×H·íÙú°ÄÊğû`ó¿
ºiÓ¢ë{`øS“tã8I+a{xæf’şGQ	“>uaØ°+ÓhJljĞ”D$‹viıI×]"—QªüÂ¶`–¡ÑlUæ†Éş8µ?™İ/å”ğàÊ%{J]ªhRw´IZ€¶ªòíUïFŸÒ~uÌœİEV;‘Fæd>\oéße×ğñœAÒÀÈ€&¯øa™.ä'àÙKè›ùéfŞSd7åªzwœ<İOZ“IÃ<Z¤AÎÌ¯6v9~]³mC'qšúilËş‘èÅ\a
=øQ˜„Y‘‚× «±±z¾L}“Úl<ë{¯›
Kg™¦Ğòg.®˜Ä÷[!~ÒË0ÜHîL¿ö„›*„^¡9‡ÜeÕÊã*kïÚ:«Ğ©ŸI™usº™*Ğz œ}4I¸ş Àİ\Àó”"ïMWíÈ÷²FëzêæA[Èh·ç>Rà®E|£l«Ô[ºÇ}Rúø£w$c¼Y•5äeV.ô€Ï×§Z\kÇÊ}Ë°>]ª³(ŞÕU”#d-Õ‚Ëoqr&ÂEhxTŠ*İ>¸ó¤Ÿ("¾@ ¹oÃ€—ğ¡á¯NØPºÿW§# 5V¡FÑA›Ÿ6›)\µÍœ—çÊhU@ 6ÎêU*CÈ²‡~s—µ{É)üªş€53¯ù¹yï}îİU}ÙÍ\®:x/Œ‚óİƒö´„ çp¼gÃoĞ	 ï‘Ş8ç5Ëh–!Q<oü»LÙ~hÅ`¡·w^'Úæj(%Şj‰ã­yÅ–¯¤óí¨(X’ZsE 1:POYÿ?èşŸ%©ØŸ‹¿ö=_@Ëí{ÖŠLë¬„w—‡¿šõÁÄb¢{÷—lÜ,%ş!~OğÌX…XÙvSòŠ2Mçé¤`sËÂßçû.ÂîØiŠøIC3ßQè¨føp
ÂŠàa²¥§½é$”b~éğ9±¶RXc[%[ll‡î<Óê“ä"é3à*„ŞLg›ù‰ô@ˆíŠ]+K*mB	"‘„ƒÛê¤±x”o:’A4*šlü„A0§Ş–¦n˜6¼¥q´úé¬ÿÛÉ(ªMÃÈîŸkÅF^èA?U»ìÏŒXm÷ÉŞ³£©ùw2ñ%s( Üw±½Ê§”/e?(;)UpÆM*HË¾h./¸74ÜÌ`ëÿÁÅÄ]ÒÁJ·ÀtöÎr¢`—ó_½‹#,dÌ»6}Ù8'šP¨éü®‚®áª·ßàcggFBùÈoªËÈÆRëK/xıkZÛ÷)|ÑMÀ	;b=ò·àîİ4Ó6õK‰ü2ğ)M·hSqŞ¯{N§pøEÀÙ{4bë›V‚¶9‡“¯uÆüô¤‚<SáÙ;mŞù·‹$Gƒ×0Gú&ãD.ÕªÄ³©¨kJ¼Ò /Ìì?™ù	ü
cøRI_J×#Ó	Ùƒ“¬ÉÕnz›²Wö×p<e|éâ #a±mÓIˆÂ îgB7CwyWhE_äè)óN‰®[”^k¦,"«_l_Š{¨“œ-ÊF°„	Í’ÍàiÅ¸mcšÊŞzx1¤Ğå ²~Æ?2‹ü>)²Aßİ’Ã5íÛÏ€!Ò±M•È—Ÿ¯¶{ÕÖ&+sùÜáúåP;.9Û§B*‘9Â²DpNµ{§ ¾¶@ —ÂáMˆ~µN°X ›z«l×© ,ù6ğÙ`@ãe…ŒKŒ¯¿Êd½PrZNôOo¦µÉ¶vie¹OeI½àîx´Í¤Ü8&À›ß²9§rÁïS¨¾ß¡~’y-kú	d‰?Yl«Ò.<•ù‡ o*HşcØD6
8+ê°½¿%VKËv®ò1æ‡h©j¦É AÒmªÿüÌêâû×å
Ğ¶D=€Ë†µ °¡WÌwÀ-çp=ãt¾alW˜‘M* ƒ‚ÂßÛ9b&‡—h4.»î¶ğ™S© eu bô÷ÉµTÖ¤Æ¦4l°±aC'+«MÊR¯VÒÀHp7–3@_«¸ìÔËw8¿…ß‰o‰4¤ó˜x8Ú«}ïkÓû
øâJ)}Ô“âWH ÉÔÀ)ÇÀ')°®áOÙ_U[ÆP4\Øf1Ä§")Ó"&”(k²J:Ã†Ôƒ«wÆìG ;úÓÂ\Ÿ»ç¨‚0¶–YFÿt7>d?‰”
ÎwG+`ïY£¼¢9§Ñ_LCdÎˆ9`Ï—şëÊºjBÔíª !Aà¶6–3”ÅVIöDa["×sô¢µ¥€*îJà™É5!‹4u†¦2,®Ä4é¬Ä¿JB’rMÕèjŸ]‰f4ûŠDJŸã¼Ÿ4”$’çÂÕÚém¸øİ9ˆÁéSyşı¬'üæEª6Õ{ã’1óu£ı™’/|MK×då°Å“2Ùr®€SwƒïW_	K?87ş¡³’˜S¢·¨	2p–Şf|<™ifÿlXTqÎxA/’FİÌfpĞ!•ı™
VòTŸ¹ã²ÍbN÷”ö(Öì„ò‹­¬+…5 ÷õÚ[Âì¢™c§¹áè 4Îi+[N±+¨¨[,«F!<ú{U)É2› ¾/›[J
°‹Í‡`,qFìÉw2~dF½©ßá(»—³š0£ÊÉæ,IV$ÿuñxîÔ°h<Ïqu\áŒˆ•}A²cZ¥a›œ1 ¼•+JK«¿¼íôî°‘uùŞ\¯Oåw…Å\Üµù;û¯¦“ËO†Ù¼b´N	y“$LsŒTIŠá êwßî·ûù¶FB*¢å©èå\ñ‡Ë}Erí±„„×—…¼è†c«H>Úb„iÄ‚ÖøùhçÃÊ°(ˆ!JÊÆ³·À,tb¾™ï]mB„ ¹¼O¼g‡jÿİPSÔğ5¯aI`¼Óƒ2Æµ¾\·w¦Vwyğd=Õ—Ev–ıMƒÀ³¶ĞoÕ{’Ùÿ€WzÈ´ˆ¯&™è& Qv±]·±‘$º^H$½J )7wä+l!&³m+h	6ûW‡ªeV]¹ó±Ş!óşºªâwïV¼½I¡£z)upwèï'MA5 ÷W­Ù'}Ñ+†§«¤“ç½/Qå+hÚáUá‰+å`°EØM[¤–‹1wÅx±Ù¿¥I=|š>¹R0ÇáDé¾MÍ„FP÷Rƒg9²Egc‚FZp´‰ÔOÑ²/*É³ğ&ß˜†j¡qñm( ÏƒÎöÚ-ïpF$ocóG8Q“â ›"Bpnë;:)‚ÔöÌI*T|Ì‹'òM¥<!ñaJ®ÆŸ‡`û3S¾`.×ãŠ÷Èƒ©xZöÔºZK¿‚æï9”FkÔJ}ÏxĞ0WN
eEfóÉ^ûïS?„œ=ºª4{ySU+»šÍ?&Ğ9çvçPáF‡"¾awBÎ¶$Ø§%™6;Ğ¬4\¯aÎğìĞ;<m8G—H’›™«qÑş¾TŞMËËü¸0rÆ©
Xîö™+ÛÉÿ•ï©U-½ãn,ë¾:@íå¥ö–ÌkÎ¯CÀEğ ôğwÌ”LÄ’]-ÙçÉ k—·9XË‘¡ôùIfPæ]f¬RTÙ( rbH´ºúÖ?²ÓÄ.í(,Uv 3ø 7X+Îh1¥í.'œÿtÎ)M—èsİ®T¸–İ¶€Ççã!‹¾'±šÀ„KŸkµoWğSó@&©3U™Ò§ÿ ßÆİ¬	î~Ñ`v£c	§1SJÅ·Ã{Î]+Ÿ…ÅûyŞ:å{‡:cŒpÎ†iE2>!0W_§pÑ
ËºÛËbbJ“0I1trò5 
êI «\İeÈ–9¿¢ª”1qiDÛ†»Ï½‰ªœr¿àmèZpL2=jø:¯‰™ê­J'?ƒuz]¬!²ê1Q[ˆƒRHbµË–î„•”ÚBÿ×}Ûf‹‹¼ÏhÍèÛ@šèÎ®ÍĞ
7v†„§lî8© /ÖÑk¸_Jmø§3>¹/¥ğ<XAµ[îpêq‹ß-§-ˆ]V’"1E	á¡ÚäF[:15õzTŸáoˆxlÖ,‡óére2+(Qıñ¢¿ŒÓ8ÌäÕ‹9mÄ+åÓã5¿™„òri˜Ø™`o¥XL|û©ˆš*"¶àC.¨º6ª›Ù"Q[$Í:'s7AÖTº%y>:¼Ö!ûvÜÎaù#]½ vì2TÉTZº³õ•XYØ‰ój¶l*r®‰°pq,„ıîÁrôÛI2°$ü×øMo8Ê¿‰&vãu}B6Ö/É*å`ØÚÆÚÜºDFşØÍÈQæÜm±—;l÷*6?¾îöÔcĞñ££yV&×—Á1…ÜßYË˜šQáDªk{EKõ÷¦ eı¬™R†‡¥¬Èƒ×-z¯½àû{P&vg· Ëñ>TÇÏh¤h~”%L7T‰z»ú˜]û>¨ÀH“ !ªj
J²ŒGÓØx\É˜>3øUÏ¨	Épëé/VAúë6»%ñ[)½ØªX*íÂÍ?U¤¢±œÌ9$›[şC„¯:Yà7Ú“ZîÁÌY¸ Æ2ÊO˜Oìi„Ã…¢5$w 
›­x®Ô  èã³”àHw§L,Mæu§’uiÎ•».lÁy"ãiÅ7†[^”5íÌñ÷½Ü‘zX§şÊ­œzoïïIó…D<şî«ÊÉ½>èkúW››‹.Hzb?  V€T£îS„>t–QëR¤“wNphÕèúâ@ AhÕcerŸqú×GÛLomjS—@Šş÷ª¬‚}¼Ægg0 L(Ì;‚("¥J©Ëpªõ„‹xÄnt ‚ƒ¡'DwYÒ4/»±}‹b/s‰må9 1PÌF¦h¨S^s±–ÇA\g.wä3¸™1š}(í™´†û›~Ü"Éw+Ò;ßø«2Ş±x¯dF‡øbPrJMäµV¤äTµÁò¸ÆÍ3£	 ıì“Ê†«¨÷Âf¾¡cgĞµ“¾— ê,J-Z¦â‹­LuöpP(klœ!Šnbq™PB°‹(¨Êä$ÿ.¹ÇÜì`†Q[!›Çj\¤/Òƒbbäi/cÛ6O.÷®Û9ÂÙ£Äá£Å|J„9¿£¶N=}ä«œ‡ùÃ!™cƒĞògÚ£aêı*÷[³†‰l´Šeğä;“[n<d‹ßû„ˆ]£šõñâ˜(ò ğiçp?Ğ‘Æ&ÕÓ³‡eµU†sûc‡..›hV:—«}Šr”È21#'<‹.YwÊºH7ˆJG¹sĞ(=N]ïœ»/Eº½»wìoìúú‹òñÒÎç^éãê]ÜõiãÖ­`IPĞB{9÷¶Ş´óeU°Œ‘I.£%½Ü¢ôM•Œ0™"¦45hF$k~×Ô¥Œ5}ØğÉì&xôsàQ÷ëÂ&çV.íê‹™ìî^E¶©ºÅôÕgOQûYkãô«¸3EÄª1fÑ\‚S{ˆm”1"©2ğ:ê-M MŠü| ìè#bÏ¦¥^‰(Æ‰.sYøq)Ğ¼çáÇá³¶ÃÈ8eI“-öQ¢¼ªªOSê–òÌ;½À½¡ãµ{,
zùÇPn‹G†$SÎB×9ÈN¡×g 9ûr›÷Œ­ù 7”ı²U_ã®RáJä^Ë¼„š;ßÎ7•U[P!ë½¡Éãc×]ìÿáû1 Íºà>*Ï–M¬DÅÏ™.åP@Ú§ÿ]ÉåtÖo‘Bú™`Y`Ã‹k&şá×Î‘¬pO*\ñ×(ÔÀÿÓs/H£Ì«»Î6M†¢“7’ÇÜş?>s¯—œK-?¸*=úºÁiW'õ2	±…=”2øİõb?{›„Ş·AQ’£<›ÂQ¿)$AÔmÍ5Í‰‚•êû4ºOæ1¦¥9Úà;A®)¯ICİC©‘¸v”­9\]‘Â1âêáäo uT¡ÔïN%¼˜gâVïo³>QİÔT#K[«Ïf¿UJÛ°áX`¾“a‹˜²5¾blÏ}“;¥îˆ¥LÓ¨›‘€H~Ò}¨û|êÃ»®‰‹óPa:¹$êZµ÷’š&‹m¾$è·ØP§«& Û&Í¡î3Ö®PX¹™¼$ñ^©Ooq}n÷eÎ#AjIVÛùõ=UÂ[³ü$ÌÂ
ô˜Oyv^))ëzV6æDÕE99GÍ|`òD÷4'“€¥ewRm¦e÷käfµw&‚’,¾åòÃ3Á }¬g3cĞpè®.¤=q@Ş‚iöç¼òä‡5l~„ub}Zı-3¬e]µ©ìî$Eœd£ò*7B$Ğ!%„Iì¹MüFf¦Fí5}¥Áİw’şuª]š¹Úé[§¶¬®o¾…2¥sp„y¢«‰°ˆ"GQ[nŞ@€føØÖèìäeåVA¾KœPÀ0+<)Tò5K2#ËÊöà§ô_L¤[|–·Q§"aäk›µ·)¡>ğ›‚´ŞLSî¿Š\‡è%ùŸ\B-·Û¬Ø§ó¾:²:Y3‡¯¨s’"ªªjn¸:õçšÜ‚Sbœpa]$…Py’éÖ«gÌ.À»ssÊq‘	Ç<¶Mâ÷2šÿ‚Üš2| ¦Ğ'Lù$“ÓŒ¸ÈØ6Û†ÿ¡3ÈÀ-ßjCLÇ,FR¢}4¦cá·UZ_	0Å}mœ"èyŸ†7şó[Ú,Ø®èßù^	‹ô'Å®¸á*ªÎAUÑ	¨s‚¹Ô (ip%İhxó£Nğ÷°1™(\]8»¨pà¾D“Işt™µË‚äôÌx‚†k r¥P‘,Ó=lEÒ&‘µÙ…	sã_Ùæ[ºı2SßĞu4Ğø€\s	ÓKŞ</ö&<É¿?Í–:—Kùıî¢ïÓùÏ GCÖ>•€$ñeñ³ù] ¶“Ì'|¹ûVUrÑÌÊ8ƒî_+—RşŞLW	H®¶e’~3Û‰"@9 ¸¹l¡xlT‰ã†æõwhÇ6ı¸d#ÍBÕIc;?İÙKØf‡º dˆ—Ğöxî^›øÕşŞ7Ší7PÆb”ÉDáQÑ¹n:­:E7±"Bfc®z4‘\YK®Æ	ò$Î‡»bÖğDS*fgÁS°?ÊÑ"58çú´ërëİÖ¶F
C¯¾*ê\ èÌ;Õx£xğ¤—u(lø¼¬ğÛøW»ÿAËVñëö3UafË£·G¢Ô0[á}‚E†qK=äûw<rÍ µÙ“`@}»ú^¼1ò!™Bh(ÿà`=ã60nÂ&BàDC\O+Ä“[ªˆ39â<Nz!%IxeÓåp” ê¹'èúfÕP¶ÁŠØlá¬Èª7Æ¨7±ãî½Ã>Ú,1[²¤FW	Gœ<Ù™¨¿òÉh2átş/ÌLÆá¡œrÕ¬RJB¢Ä>»86",¤
İï)íÆŒİİçs¬~ü~Ñÿğ›5Ê["ú$"û½[ûáÌ"i)¼‡PÈ”ã¾T°îsõé…ŞÌ,Ëï³ƒÅJm»‡Ö1Ÿf·®O—ÛµxêV4 ÒºIäQAĞ‘ğİVT°~TÌHƒ õ«?m%Ëöô/ñ7îÎaıÕ–ô$y­ú.øvL]†g\õ‘+a±§E `º.¹;ŞºpzÌWõÅ·zæh!ì€¢£§|ªÊ×«y¼1²•§Úİg­‹†€hÄÇ×61„„=Ò2å¬›q·,MÊo.†ÇMFk¼ï?Ğ|‰lÉòpâŸk!×Àø2RFÍ-N±aZ­.,ömä›	âÏ^öV02¥+¤ùªQÒéÑ¤D‰Çb<9vS®èâ	›G!X|æü«føà"!%e	ÿ…ÒÄo#èxˆû0üøı9â†–æ¬üš3¡…Şÿà»gÕ¬&¤H§5»%yOà5¨Ä=†y]‰û²µÈöW:AòcÆÌÀDİÌ(H¥,Ìtõm7f\9}Û¨Ù\wªÁx¼Õim­ã[^ƒëŒÊ80ÖzØ¡sš³N"ĞÒªó.¾}¿Xihm‰y…ÒTä·ĞAÄá;”C‹"õİğà?Q‹uzçºN~ÌdÈ›™¯ı6‚îÌ5ÄøDa?KšuÜmv÷nıÅWÂø·õ¯âQĞ˜]‹ğ9‚»fgÃNúAü„çğ×9x®´z¾®0$yáÉËúj`¤ÇÍ¿Z6>LœÌ^Úœ>^.|-~Í‡ßÓØ´Ó#ôÀ©_há5­	T¶&( ñ5J6{zƒ½;nú>ìûkYU,P8W~…›82Kš¨|àˆgÈ*•Ğ~è4fÇ7†HEãTÂT¼/’=k´fIÁp{ÃV/‡Ã1°2^,/rÓ,ñƒ£k¡ü00ËNáTíSşê¥ c–"†ë,ı3™nñ“NK!p³­İ’®è,#í½X2ËÛÁ\Ùg?ÙÎÅÕ‹ÛìÈ+£›»OQŠ	`±bNù3´¼(6}£¨È”•dº¹,=ë¿Za"ş«V÷Lˆ”yŒŞÏË!3,ôåò.I¯Ëœâ8q9P™@«™š¾™Ÿü>mÌƒİm¸Ä»v®T%+ªS‹c›˜IAºÇLMº£¸@ŞÕ{õ©ú)àOYFæR+âw]Á$;_0Ù§”¦å–µ¥Ü~Ç²ğtBPI­ÜÓ©ÈvÒm@Urb0ãh‚ƒ¦à¥½¦òl+ÂÚ!7(CÇO˜ÔÂ×•m=U$Ò~×C-³İDÀÎı˜ùÄaÀÃ[£¬`µÈg}a*-Ëüè¬º1®8™û®©úÕ~knĞ:N¿_ŒÕ0;xÕÙz¶­¥›? ¼†* Ãàğ…­‡á½¾‰Çø%ûØ\\êéÙ8ıwE Hï×1MÄìbáîM‚“ƒ²«UŠûìÌ§$©sÄÑëñ—ç3‘Š9§ ÉUW‚tÅİ/B°ú^¸lPÚXÜ=âf;n+Á4½Î­']Œ\~ïé¤/ı¼À—CÑüí/ƒ(hıªÙˆï2ö•!qÉQ‘áÒI=ê‘¯±Ğwİ.¿qÙ0{†™L(;Hó­£?V­¼†²ºÄçBãğàíb8M%µwĞ-x±›`UÇ°;œÚ%×İe¶Âùò	`¯+B;€!DP Z«. ’_êßAŸˆ‘bq¨Îé»š<©Ş®XSIZue’llr™“.–1By5ïeµOÏ¿D<C ş&‘…ÍYï5SˆK®«“¦4£rİ©wÈğb
Ù”»Š·;:'í¿ó27'ƒ« šqdeåç‰ùÛ4‡=¤ \»ŠÜ‚ˆ*[şgü@ËDÅÏP#ŒáB¸\ÄT”R«FÂ[®·›İ0 /¾ÅÑÎ7ˆú0C± ù·°oXòôšåS—çd&]K"åy1š^»
Éƒ¾…†×Ö‘µ¾‰qû²¡®%hYÒ“>Hğ«}`ÁB˜E:Ñ%Z¶p:v c%E ˆ³âpœswİÛŞ;õ ’ä®\À0NÉ™úÁaÔ×ƒEe5@?)Î­üvwèGÇ"ü<MúÏÊæ!0ÌIn•u·(¥:]¸«­‘(±E¨R"@[
ÄYÛ *H/ğøC j–<ôŒïÚYùúä˜~,f>ş¶;~ˆpşòosB ’`oœ8¶_\(éî¶ÙRÂûâ:â?UÁf-í±ó6ßÈMÿ ¸ğØ‰å—,ÛWˆ¹Gw¸«ºüLöT1'%W{ZĞ}éÑ~”\Á
¢Å µYŒ+w¯ß:vb$é7//}—Ùè£6`ï“Â;¢
/ñ|1“P©…=[ŸÄN^¶håÒG‡ÜO±n´•˜llğbZ¤©•y¡óN‘×Ì&Êó†U…ß8è,&"TúH¼İİÊXøI`•xÑxQ¸«ÒÓù”©?"{“1¯òSØ"ñô„"Ù>/HÚK•V‰S
%–N Âö†r2}ö Dª™Ëv…VË|‡+ıf=¯DJÒE5@şœ£•f„ßæ«Æ\ŠçEò1Â8_{aEóŸüÈ›ì¥Lş_š1$Ğ
ûN`ãË7¿Y­ãÍ·†oªŞ„úR""¨ŒLóˆƒ2õAL@*?R³8À¬ÙéW2.Ïo¦·zø=AÖÆswê³gkc„K`ĞÆÅÆ­Ú3ÍÛ3_éî°=Ó­V´ÎÆJÈúSÕ¦{]±`ÆÍ–#½évÎb=œ.”I17Ñ²úLfÓ şDa[°ŸK©b‚ÄRcáb‡àøßE`BÛålìÆx_‡xrDªŠİDÀûÏõ|VäjÏ.Ñâ,ÃÁÒ’6S~)c½vYlGÄÙ Œ•‹2 Oµ…d“ ºÄ–Ëäİ$Dê­øğ¦¡H6ÃÊêäñ7Cø0Ô*!ß_‚óÓÕ<qmçzíå¾2oñ‚ºáİ IL+œÕû”$Q.§l|[bš ‹³Å„Îé½ÿX¨Q1úD²0é ÿy‹{(ºˆ«€Îé‚¹”<ÚÏ	$R‡†ÜKdï‘ÍC³†«Ú÷£{¬UdI8®ò6;™Ù0R~/hÕî–ãÖ%ÖÁï’`s@çdk`û¸°o„&¯Ö²èCìåIÕ¾ÌNX7z4§£½ŸM®{$Ô6‹miãpy‹SùÛÅD‹â$ZÆ$—ê—R/Ç—°qd–>d3M@”Ui©®5¨ØD2ÏÎQT3O“¡tËJAnŒå }H±±Ø*ÔÑ£È´¯ÌbÓÜ»,kmúf+YÙ4®Ûü1€™2ûóıóMYôd(V;:¾¿"Dc4U«ˆÒ/6yõ@UÏ®µró&ùöS€n¦èÇY¦ñÑ+*J(T8õ½sòhI’ıºì‘ÉeıeD$dN²§!+¨Ù%µ´E_ÙŒÿÁUÈ4Æ¦Ñ.úˆ©@ÌÃ“ä/ŞßO»½—U7–IŸ©³¬O&6jŸ32u•ı\‰¡Oğ§Uë{HšâÄj~â[w‘±8´³íeænFQÛ‚Æxñ&…k!¯înOË¯õ]Ø¨œóLÄŸdC[e™Î#WN€e_oPp(¥óY{©á¹†ù2ÖH™Ç7É9ò;²fv¬¨K¹k˜ŠÈ±æ´‚s%é¹ä×»H£¹§œ18_'‰Kï„8W8ŞÖËËcT¾!ŠRyµÎ€Ÿ–«ª($‡îÙ)($¨¹ğá«©,Mãöëúé']ı¹ çÿˆFùÎñø˜)'ndìfÆ¬;øú< 5²eœ)VŠåÑŠÜ%Şe…êùÏ\ÈŸMyXùˆu%ñq„—½PkfX‰q×îÀ°P•Ñ°í‚ô¦ZuÙšÇê5'€jZ$6T¡&ÇÊÃ»Í™˜tÑÖ›¤âÎı~²31eşÓ´¼Õ…T\Zê¯	¹E*la¶ÜÒfÙíÅä‘~ÂœÔ‚I¤3˜Ü5fx€Ök0°ä§µÌíŒ¼“”ÍíÈ'U÷Ö©@ÜÚ¤‚1pÄ<oØQaÔ LjTü%“Ì1—ÀKE¡ÏyÅÑ¬®Ïo€¥WİD÷Ï/º§Â+ë;g ·¸O)‰IÀÔáóï>2wÙË%Û&VZ–ªz"K‘P­ºX³á%­üut’õÅÅ4L iyÎµ4k:­>äJw‘¤g5¶è¢Í°
ºXQ‹±:¾PÛZƒ,’ÑïØôŒÓ˜• åš’ÄLL„lòXFä˜hØx8Hn4ºğËÂçn«Å\âÄO:—Í'·C{wë»[ïÏóòlziz[~ÏŸÒf§Jp+•Ê{â01×QTÀÉøÔF˜NHstÚ!Ït¶†j‡Û¤‚+Ëc˜	ùŒƒZM|„u®³ÉÔıínüád*º¬²E­(vÆ{1§QÎú¾'Î>>Ï4ÛlÀ•AÏ¢•+‰^Px]‰:k¥«\]m:s?ŠºK‹ò±l¦(›F¿ÅÔ­×Àq?öMò–Ê”²ö÷.½	æîà“œÔãÜûÂH½¯Ğ¾‚QUÛ¿
B¬ÒBîxÆéøƒ¦ß3Ö0µŞl°È×†·vĞ&^§Ù5¶šæa`bÏËHëƒ!¦–ÛÌÇ÷E=Ka™±¤‡1YŸYàÕ$š´şyzº¯3Ä²ÒøíÁƒÌK*@‡gJ~šÍQ˜ÛÏTÃXëS½HeLÀ=rv4ûİZ#P­sRoıôÚg §N³.wò>zrF_·Šn)Îÿ$e4õ%t®&ûM7dğæĞ6%àQ«È0ÎÙ›ö×p"3¸	5 Ï«ñqp' "‡MËP’á>5êël2ô÷c¼ĞÃQl=ñ;Œ‰Ú‰X` TÛF:Ø´r›™®Ğ½kìãŸKì*	'ñÓ±3PÜäeô”_íqJ”BÌ-AŞT£©÷ÄDóf½>uÎŞùü ^W‚ì^Q`
 Öšÿ¥å‰ß)´ÓéyÕixÀ @sH„J¯…ÅK7	ĞŠ)Kû-èôña$‚™R³›ã‚ù@Y®„»0Ø¿¯¡t †ä²W»+p0L'RÊYÒÏ¨í´J¬>tézÑÜëjŠå¶ó9òOë{35Wtxğ¤9ÅfC¿úÛ•†¹M.üÈó“Eì¡¬v{›ìr°èÁÜâu§ê²Áæ:Ğ,æm5¡zz~LP(«"{<
5h¼JŞpDFC¢T2†ƒ4¹>ˆÈÊÍãQ>'°äÅ€³3|i(2å¡ñŠCDò°MTŞ¿“:v2Ş§L‘¯'JZê§üI½Åúî+*îDè…Bú©=;Ğ»ë:•œ|Ìqª‚Ÿ0ù.Oiôn¹ Ÿ õ‚Ëe^ª¬æ¦ãòråŠ¬‡™Â±5¾toÜ¶»Pù.°‘ónáƒ9³¹…¹Eä0—ª^+­º'|zÎ€”Ò—Í~„Æcú%ÉŒZc`«^zq	YÇÎ<s^¾¼îÛÇËİö„Rdç*£
à¹Š´c…Ía4ËHYE<ğ]-¿î]J‘Ø¦ò|õ*”şØßH¬y÷!J7”íNL¼ÄBÒÜÇOÜ€Ì:6=·ªÉE²X›«-4CÍì)Uª¶÷ŸU»!4Ï)FáçİõH\BTä˜ŸäÅ‰~¾Zÿ-DynÖX>²i+QQôîa¸ÎÒa°ÁĞÊ¯¶H6T„dªv…!  Äú%z”­@²od¶Ç$ûÆëk½T.óV›Ìr¬…_
f5íêd8¦‹H¡uöÇÌ2§÷ÂÍÎx@ -ş‡˜)°=kFÀÛæ-¿Ê/Ä÷gĞ¤EºBÜyœÆ9ªƒ.Ã2"ºÙ<î‘:å??Ø˜Ê·?ÇËğ»¡Ìa`ºĞrÙ¶bVrabzŸÎÓ‚GífP­×ÏáZ˜»«Å×øF8\9iûlfˆŸÕ™(mí‰Š¢o-'c@ÏÖßpMeâï¦ŸªFH×Ï5¢3º2:8ù ›™ÆÁµ°‘ê6¸—ğéfI•á}€ı Z1Q‹øÓ…võb›huÄÃëÌQÔZ•‹@¦ÎZåJà{Acšƒ·+öß'@od2õr²]õ©ğ¶=ÛÏ·.İ«¿lÖŠçÈ´SUU’£(ôôä¨-}ºIvu—„
sz¬™a@Ğ.*œ4}•T™!ºªø)7ÍşÜéüŸÁÚqê_(€ó;läş¸n¸Réè ’¥±Æ£-RQ5 /gÿ¬¹å¤l€Có„]I¾ì8‚vçz„)ºGw\€:ÓkÙ–‰‹aÌ5·åÔ©_æ¥Ä›Oíùu’n¨LvN¯„I•ºbM(	8%¸rb4ÒÊcL¦&|Î%7¬Êuúñuˆ9\¾_üôîÊ¼‡J^Ë™On8?ïbµü3ÿ|‡¢Éá¹n:Ç†XÔøp,ºèÄAL™¦¢EˆBÓ^NIpäŠ«vEƒú?¤Xh8cºf†Ú˜VìÀÄkZú¯L"]k´¡é…3[$T|@İ>Lóõö±
íŞ¨²(ÏÄnúè²×ª"şmóãT÷ â«9§4d«m/ÄÌX™€«¡p §­¼ÌÅÆK&÷t´MKÆ(@ß¼”ÎeÛÀŠüCÏ·%)wiî¹Œ¤ò›(½è•uû©İl\ø€Ës7ëcãb°Ó¥fQ8(Æñ+‹ò-»Üş·•@$…Æ9„"sÖ"ƒÒˆP³­uZ9+£d/¬d~º$7‹o"ù˜ßÕ¹
Rf°ú ¹¬¥C¨qQjß<›²¤÷Bªa)ş•C«ÑŠ•ßš~n7oÍ:–- ‚~²
¡3'¿A2,Éy”™ˆ¨‚h¦¯‹F]•îÃçÄpŒ?¶+G¯I.ˆg¶ÇçEà–D–[éLøôU5ùl‚tçsÚ½R_ÛˆOR÷œå8×úø<
ª²°¥=\ik+ìuNZÉdôgd
Á!çMpUß‹•±+iEF	²ÓUÃì˜¥´*(zöP,zü¡ˆŒíE>EûşÆká~¿¯xC ¶C{(³Gò%²pr†¤ÚıoiŠJé:q´ªYõ~šzwÙÃ|ÓÓ@ÊD¨A4aañÇï˜G?	rIàŒàÈµü;½ì2`©œÀ¡ŠÕDş§}q¤¯(©
Úô¤äÓtTìPlÕ!üŠz—®ü&‹ì9šÎ¼1èÑóI¸­gÍfÛZQöorË†Õ€F¼‰²æï#y6XK`—>ıUÌ.0+n|bNæÑjefh¡cÿÁ­í‘ŸP~Ò”Tª‰¶í(°jxûØË 'pA|‘ñôÔ¬²z[z*`X’fJ÷¸€¹©øªùT®²®ÿ³°rŸIVC&-&7ÎëÃE	ı?N‡°%R,©[‚_Õô|ˆÊCôjáwsF-½4´cMO(dƒÀ›ÇÜ®Kâ³r@y¨¯t5Hj»WsŞ›¥ÖTøÎ5ğöò½g ¤õÛ1û>¾ûYîWÁdãİåV‰\2"0À€Š]µIĞˆŞ ß=t&RŞrƒqF¥ç³k‹Ç
nf¹R­*?!8ª8ü°Ïºã|©Ù3D’€ÀÔ¤¥ŠP¦í¬@/Hb·sbÙ¸0ƒ€¢û'6=õ™„÷F6Ú²_1ß±©Máöpb2‚@KPVWüCÍe8Ù¬İ¯ıß)*±ä±ÍULĞ†©¦É«ì‡@Ál^SÇ(_£¡].½Ş/ÁJ¢¦ü«=TVğúobd†~1&x Bó=_iaØ
‘uF¥b¾?¤áì]¦è¡ejÅMKHWöø‡É<‰;òÚÅ(Í0İ×¤"ê,ÀjÓ†)s}-GÉ/$Cb”õb‚wQ¢,¸C«ùhhC2­·if»ß>¬Î^V[($(hWhg•„O*JÜpÙrHiw¥m¯ú;ºãz›Êa{¯Ai†[ÉÕÌôcdœh}=9ó©nâ¼”òy92{—øÊÜæÛ<›ü2&jWK]·¸ì=åÚ‚D+St•b÷‚ğöj»Z+wEVQí&†.ŞÃçLƒ|ùÖ»HíÕ}§ÙjŒ³&R)Ù³2·X[©k¾¸@ŒØÁPDYĞt—+¿Úœó[és|ÚX¢C F+•˜••„‰¦Ka´¨`á %Ê:ár×'Ú“@^àE½¸A H—1ô³öD*¬ÜËzöËC†ÅoÆ%¨¼H’%ğ§Ò^åÆ*ŸÖZ»:OKáĞ‹=Ft.õ¡{÷€„^*•ş$'‰âŒİ)ìb•X*ùƒÌcè-s¯(i©ôº.Œv!v¤´(Z´¼lÑ¶ßò_VGş9¬‰ ‹úgïCÿ¡cJiI æHV¾^à˜<>ÑI4á‘¶B|$QŠÃ2æC¨ÏTvlñ7Ö]¡ÅVÜ@'® •ŸÿEtÄ3R÷úº%Ø4ŸÄáKè”pî„Ç\g•pÁ©Ğ¼Yi¶'5_'mÇ‘¹Ÿ“—{óÜ'êå²µ*VÂfÖG'ºâ˜UJá<’ÖvëÚ‘P²ñ’•7an5¾©ToÉ[² u^Yöµ0aïXôôşŞµëÕì“ˆxCÉ5ø×k}ÕâúõUL0U}´µzÀRÏgkbòVmç9‰â­Ó6$–.ğš(!!Î„­$¶ …àÙt6Ñv¨Ùïş¹(krk¿R50wĞ‰›)8ãOh÷Àìªwã*“‡ããTğÑ›<]é«Úşk(¬W3š®*gN
D’#ö¾c¦ùàŸ™³gúÜ.¿T®–µª9ÿit ß5/cÎ «ô.
áö£
ÿCåÿ]½æTOu4¨íxß/h%^‰®¨ôãnº^!¯Z¡ÙGìÑşß¬=£>>ÌA>xCn”@¦‚AÉ‰QcwÔ!n«|IWÿ¹n´
o5Ö’p×Ì(8~OAE¾â®bÀ¥ÍsÇf¹6YíûSŸÀ´Ö·ùXÅ­ì>³}èã«‹9èr<Oc]qR´	JjŠ0¾§­‡|¸ºÊ¸È™²han«Ë²ldåÏ RPŒß	-ĞÙA`ø´=œ À+¼é|ùmÄ„&ï›\÷÷ï÷vò´=³1$½.»ÃíÛ¹{0pÿ«gÉğÅ_xª§ ¹c"(¼,¦ôj ]L!¼tŸ»2CÀus1ÓÜ–iW`ÍË¦U
Á¢¢È¥oRÙ,)Û0Ib£I%ahµ—N8 Z‹–©+qhz#0Qi®#Äµi´·¬Íš‘Íß8›Ï¦ÖÕ%¨
ƒ+µK?åšGœ3 eºƒ—š&Îä³:Hµ²Œ0$İ»«gUFCş²®ŠPçĞ§›­LÖPÒJ{>(Ş$Tuk›i»ª{j[lÓ”8ìó{È
5Ç]pœÙ A:rğÔaLJ»Ã:áÒg±sÆOuXµ‰=úˆ{~´º©Q†šÚíU¡CÜ¼éI4—oëL%™¿+éŸ^Y}8´¹6æ‘X9/{çë•Iyí´}ÁC7È5BÛ_^ÈÌ¾Ì{;xìiRÚØ-n)¶çBuá2+QNû1Ö^À[Sš?úŞPúı BîÁÛ›jtĞ«+ÈMnÏéwú0öDæ0ôú‘í¿ä9xU¤Dô:GN>›yoW‡ø™İ¦ ¿AU«1q¢jÚŞ²œ, ·¨<wŒ;K³`c)V9Ï8uMxX0ÖÓ¯`‚LÒ´Ğ‰„'7nû1{YCi¾è’.‡sp·Õ–0<|÷x»¨¶ûVd/5Fç#£ğCò²üPf‘xÊ–¡ªQ06ïîb•ÜŞš’FÁOÃS¨ÿL,¢±˜½`^Y	yx‘#ÑÏû§8}j 4„s:¸6*ÍãÕşK;ßù³€¼lyzØ¡%ĞÒ XÆ>Ù¸b€»ùU~hŸG»“	²¼
iàæ1óç-ûC-Ñ’,srºã'qbú–)kÕM1œa`QÍ7	j?™é‹z 4UÒÏav$pÏRy=V=OEïcC«¬uPì¸Áä'ñlmîÕ¬µGK÷¡ô}QnJ¤lµvÎh€­ÌÀŠÌx¸'za$³áX;ÖÍ²>tâ Éá†{³Æ ö r£Ğ(B}•OA!–â+÷ZhuleÊÇ¼Nü¾’d~åÈ™ÔVÜ»rÀJg¼ÓşF)_eç :uKjÏKvMˆX&g˜WşîÚ†|;?ëˆ¿7Oèä¦4¬Õ*-ş0¿ôšıÄ¢‹Ë8Wg¾€+øğ‘\ËÃŒ	¤Ü™lo“Ó¼¦Sœãô¯ü˜Wr‰	ğMõ0A‚•›°-¾í¹O÷ª.ù8%„°$­6G½#V'²ƒHüM¡’Bñ–Z‡¾àºÔÂ 2ŠIÂögThL?X^(¢C×C[K\mÖÅVÕöŒùˆ !A–¿Ë†B)oH¶Uuyq™A½­Ä!ö…™Èzç®ƒG%©Ç6#£ÅĞôz/47nrÆm‘-¦
HÚ"zro–9l/óÇ¹[à%ÆKOA<,\HñüjwÛ‘SÊ%yø~LÖatU\JBäv+¡‹èé¹¹Qh´-Ş°}¿6,Şg†`l¹$é³ğ_ñ¾CÜªÍ®Ï…}Í ØYy1Ö=}îCêÙ¨@;×¨u®/³ã„ëvIùËƒóV(¿_^üÏjjv|ƒë‚ìQÖÆ5£Š©)æOŠL¸b#ÿh2u»…¸K­ÛÄ/Û)<¹ò[øÓ_xÊîóÕé¬ÃËíFPßµò¦|Á%ö¿Îe°hò`ye²‚–g_ÊáÀe* ×?M¯¾üíÿ,nUğå\q@r›şÒ‰Ê*m'*êÁ:ú–>ÇV4É„İÖc`¢‘Ay‰Ü&÷¦J‚qìã	¾Q8Ç/Y$PFÇJ4õ•Ó4ˆæˆİÔ@³™.)2aÔ:ƒä›ÑI†.$J=¯Õ[_¶·w’¢<k¶vä¸.­Ôëã~„ŠŒd|ğân½]`õlH²ÅcD¸–¸.2Äv9%yÁxÙÃì(~ ài°7­j¼Œ»ƒs´‡ß
KĞ»ŸRí<ëv¼†`ıØÓ~ï‘Š1!ág”´ƒ rİpá„+³ÛQÜ)XÃ¥¹“ĞÅX´‚r(]KY/uÏRÈ’	Hry€³‹\\Pb~Äôš^p7óF–eØÂ¼÷.áX lb×x~ª¸Ó¬3ÒN÷JHË
m`™RKŠ'{FV2gò½!×bYá&Y4äŞùBÄ5Â3È¸? 
÷Ç‹}¼‘Iº«/PÊI•RŒ±–ûšXù*?L<¦³Î:sƒB”Éínw_äÃEtÇÎ€ëdîà0æñÅfÎ’A®3ş™§ŞÓãˆ©Ç~ÔO¶>Ö¡wš2„sX_kã£“TZ2şA¥¯j–/@½ûï‰1'DÎNÛ‡i‹ÒÂvôJõY­©Q½¯al`İ×ŒD™^já26ùğCZ°+ıÁ*Ê“¡ü!êévÁ¿ë–p¼,Ñ­—Ğ¤³Öérs®,t±8©>°×Ï…é³œÑp9DçæX*	]ë2,½î"^õN°¹àR8,êƒóI½¨piFb˜šRã &,!q|7ç7JÅëÓZŠ 3TK‘*ÒùÚLú8!ˆ)å’mÏQ¬/`Ï
Ûª“éD'Ö5:VŞ%e%¿qxA­”Âü<A—/IÀ¦z/µ*–ˆP¢¨Ãáåd`vùOVm-RÈŞ÷Û1‘8ÚÕÁ0±·Ùki¹¼“W¬ƒT’õ·ÑÃtb™=”¸×óà­ãÌÙ8nôÏj,ê9 ]ãğqû¡A¥Ë°úev~|#€ıYì†ì¦¥{æÉõÚ¶GÓÉëŸWğ`´ b0’j´p\‚ïÙ@l!Ñ5A>rßÇum(Ã ixCm+ÇÂÉaÔ	,HúP9™TÌ¹Şà¥óÖp±‰´ˆbNlÊVµ‘Rlërò-åèm6¬ÀÑ‡ùHÈ™©Ü““m±3Ÿj>s#{#`¨ƒY¦Ú0Ÿ®|g~¹¦éDå»¨y6$,ôà•Üı¾²Ü~Ør´Î¬UÀu„,¾’œ±şiâkûÕ²º›ï}/ š9K%•¤j~Šô’&:6Ø^D»ˆaÂ-—ĞÉÏ{ä ZÉáøˆœhc´(ƒGËhAÕ¦éØ¸<úxìOÏ`Î)ïéR‰©~ÀG\ë9tYO`%,¸&yì‹RˆA-h4’‘	ÒÄJ-	]YZ«“âÄÖ]ûª$ñÅh®"|Ó‚9±Œ|2Rı×‘ú¼šWİ0B´1‚À‰’­…¤·º[¸ä›PÏ^bçş^‰2x•Œ¸ÉÈEúôCĞ‘zÁ¤–å?¿%öHˆ¤G3–>%#$kJ:¹‡fÇZãvË›&¬¤  AQö÷{]N˜I?•˜r7›»v1Ë:bù6û™¾ÍúÖ@#„C¡0ò³Í*Ì¬Å`÷æhª´RœÈ™;ƒı,Å!°>»Z3O³x*“½(8…T^q0Ú–ús•´~˜nñ”¼Ë$SÕo“ƒMƒ¡zét'Íâª İQ‡\¼æ%’”¶3éZ0\p"Ê— ëšøÒ‚r÷ëègˆ}%{‰¢zzür¡á|ÓtvJMŸ¹M•b,·ZÕ…/>ARüá6‘pYàÂ>UšòE>½]ø(åoıß4@”]Ñ¹€Ûs*çN%ôù±Vœ½b;­å¥K»Ğ¥ê'°ÇØÀŞi‚«5€ğılF9‚Yp
‡'åËœ­¾â-¦ÎAbôÑh9µ;Ş‡7ë®‰…LO„®.É¦%øbO™µ'?ô@gVúï#MÛœ]×æg5Kçí”OwµYºƒ{ß=O—°:³«³xÛ±LO%’*Èú˜Ãaƒ«—W¨ù˜tëõ×œİÖp±çsWÇ'·ë\¸‚i½TÿY°Ìa3=o•ÅÃq‘ÚgDŞò¬ÒW‡qZ³Éí«×ˆ@Y/p®øQn½dšûO¦-¾__eBµüàq…Í±Û°ÅJ3µş]”åÆ€È„6®Ëé„&GûŒIšVş×»Ùonç¸Kºİ«T\¥:ùÔ6Ê;7‡¼0éİÉIËE„@£„è¬áÿ9òñˆó0[ØíÂç3ÂTDñ­·ïÔÑ (<b©ûÆğBù—™ ”–s™„™5[–/§¿Ã\«(İúpº·ÍIçÏfÎ\3†Ò!Á‚;œ2ñ¾ RàË©ƒ+'cú¾WXôÁT¼í{ØštâÓ*.y>kT~[M76vËëñ¿Ã‘pFØöÈgI%!.1Y¼ÍÄ2å¼ƒ[Òë™šœ81O¯ãîqRßÉiè.Òì÷"uv§ ¶¿~	mi2_ô¿l 4Ğt¤ì]´¶Ëã¸p±¥N.
N     ¬}ıeÚ–U ´€ÀœAı‹±Ägû    YZ