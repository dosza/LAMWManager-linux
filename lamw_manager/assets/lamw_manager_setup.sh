#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="569304672"
MD5="747e4860a583fe0d1d05bc9c6a7cb383"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23224"
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
	echo Date of packaging: Tue Jul 27 16:23:31 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZw] ¼}•À1Dd]‡Á›PætİD÷½~5œkv›;—Îó¼æê˜y[¢y{ÅşF	N_e*šÍ6ÙøífÆJğÀD"ÿWÊöèsÏylŸ2‹Úì_ßTHÏ,rêñCëçÉã(AmRÉ“]–a^_LøìŸ
ïÙoM¨}À]ôiŞ#ÏôTM¡V1ª=Å8bM}#^ ¨›°5@
§O
NÃ—3Õ:åÒHQ2ñóMÿ¸úKó©Á°¹.Y·›°±Œ¯¹EÍş`À+íÜ}dn4!¨GLãíŞy1ºüìZÖXYq™ğo6WÄ·ü3Æ9çôÔËé¦ËwV“Îó³[ZÎJ_*ê0x“U7—šyšê¤!Ôc!¨·Ğ§G|@Q›æm÷¢m]—İµ"5İãpsJh@–„L w[ãîöÉÔ¿)´8†´ß ¤}Ó/4ĞT²§C#¸Æ«=†.Åş'ÅLn°³ùÚ¥AÊ7ğ°R¤ÆKµ*WØjK(ß}ÚN$5‘[¬ÄT¬óBÆ×#ë“¬-\l„1'»Ë Üë5:	'©5m´z‹+pŒu±ºò-âA-Ã01S\•ê;¯ˆ¨Îœšô£Ø…şç#†ìŠ¶WûC/‡
¾ßå[§k?Œ¶ZŠ¦\İOğ7 ®-äÚ‚øŒ\e
>ˆzF}Ü0hå Ü
<kLËƒm[‚‡İÒZÍòärÀãåÎ—0ræ±]&á>şª·Rağª–`=F+×åqÚÁíƒ¥£õ$‚¸Ëb™äX?ØÏï£í=ü™#õä½€l?!­ÑIG)û4ì)ØÂKÉ÷±)mÖYäì¦`0ñãùõ[‘ş°`KÿÌe'LÑšğÆ_3²‘„bLĞ@aì±-W¸îúmÎDbcRÚ®hD.˜töãiç5úQB!ò•†¤å°'`t³‰m´	
‡ş-õãİ:íçCƒ¾Ëÿu³Á·=wè¶Ú æpDùÂÒPùÌ´Cjç\uz=ÈÙàH]ˆQ{€¨åZ:øˆı=p2ªÚ8¼W²$Á 8íC[î½HxB˜4¸»x“¡õÕœùçÁOBZ}€¢†K'î…ˆá]¨Ç5X;š$®ÕEñp3w4øÌ^Dş‰!cì1ı	(TáSzÿå;^ÅO%â†G!›ß 6¨Û1^o¥2Øìf”¥Ób6\HnÕŞ¼ ‡if?ÒÔ†´Dçıµ.×1?@ÎR%êÔ«/7ÈuĞó:«æV¸&1¾`iÌ¯™â=àGı&ûÒLç¾0Yçá“ï äÃk"uüÑI}åOnÖõ3Eç® S4%P áœãÎâ	Y­ß‚o/Bß°í9õîé®¡Ö<“Ï¼=5Ò„ŠLõ}Vj_P²	{P@rÅj“,È÷á´ŒBwíò ÎÑî-K7ôŸC£Ú½ŸOõè.!ĞAµÃ{8ÚOèâ;tCS§Ì!=†îeÇ¿Š»Ñ¥vÜc9Ñí¼g[¤ëÚWº{ìHçdÂ€>Sì¢š`ˆ¹ˆ´T4A˜ÇpûòyïÍñ…§]ôÕÕ ¡¾÷qE6¯õËüs'3<¢Ïz°‹™æ% ¿DÉEyÀğI•üN şè‹BÈŞÂS× JµPÉm[JOMEšhÃ»Ğ)vªªJaöö”a9R_‚±w
o°¦i@‰ÔøÒ´_X‡z Çé®ƒY†	ºLÃ»[‡†ÁÔµísj3\éªÖ¤:Kuµ¶ØYÌD€Ï§@ÜB†õÉOl7é$k*+Pï@i
ä)ÓŞÁ&{»ÎHÏ—Z’Õ¨ÕÀÁÑL˜Yvö£zevlWM¨u¬„y ˜FªNåo
'¿6Ò,F“î™Dôp82oFí5Õ|¦‰uÓuf³¯Â¤#·E;5êŸ¹0â•¹×÷®ş=ŸŠÕ¯©Tº/Hrƒ˜—–<Ç[,3 Ç0üÛäÅš€.“ğvge/Or¨pËµ°|àî|´&~bàL˜_3¹‹é{e-”˜®44š:Ö¾Y†|h×›œblQ7¶ÙkŠ6ªè)Œ›-Ë‚ã4À'/ú—ñ«huj†âŸXXçvİAoi ¦/+X1hŒÍÖ”h$ÚÜ¸úİ¾qOÑ¿e¬©®Ä:Êv>¾UşÙÿ4gæuÄÂÕ÷}A¦bÆsœ•ƒH>Ô6Ñ4oØûMkoP”ÙkàT³şùaòÎz)œ
˜şó°¾rk¬i£W³˜ˆ£SrŸ»D¶¡h“ü [®p÷4ö{1Ğ±vyâÑ‘Ù™ª«¡ÃGŠTş'¹À›©ºW—ü2!€<H3xk<EB	Xi4‚Æk+–çÃ× 1ë˜.‘64uW3wŠ_|ÉOõ§½	g™®ùì5ûGÿÒ•hä 
 ¾RĞ OríÔZÃ¸¸ÔÆ•PÇİô	<Ãsâì–q™9®£@o#Mí&SY›%€8¥Ñ—étÒi^G¹ Y|;òÔ±`š²Ç£0|k-8üXg[‹Ë,9ãÚ`s!ª"	œÓ×R{e GDŞĞV9¼.£à‚½òÿ³j…‘[gKcíª‡”Ğ‰9²Dş:£VX.Ò†P‰šÅÇµÌcn¿1^ºEÓ¤_šB‚|ÑŸ;ÿ•B3İÉ]ñÕÁñdtP¢“Ìö¥EÅĞw#“Oö›ïlsìÆtç!º MûlÁAÃ+"i(sŸ[À+uKz|g÷­©@Ôïù‰ÌQub™bÆA"èa)º Ûˆ¼Ö“â-¹?^'Š‡öÈö#íïÖãfˆ­İni·ÖµË§ßg—aú©Ãñÿ(§ûéaš«wIÄ&Ô~÷·¹rs«Ğ‚:¶<s‡g>š¨$kh©ö;1_+7t½Õvèùª@hŸ€Ö4Ìn²‚ÖöWÈà¤o>©oñ|Œ3z¨pZ%qºmÃTN¥Ö’¤ñåÍ8¸èz†_¸z°«K™z(„ÓGõ½É=>øWÓB2ŞÌº½L #§b¯şÂ$t°!ù…XOjVşk‹®8\1Ñ11RTíË–4¨Ô¹’É#Kÿyçj#“=Ü9å[÷²Î=„‰$¼­É§Ü¸°)WdÖFúĞœx4ûD÷QMI ¯[CšÕ»ó,?ø}
–ù=P:äÿ0Ä‰ÓpèvÇAÖqX5õ£Š§B£‚‚Vå)\_c=yî[>Sü|îÕãé€Û€ôc„&Í€´ïzfb*`¢Vˆ[ãÆàê,¯7÷Õº±š¾x"%UrƒVòu¤øÿìíi­ %X`)˜gqox[Ô_«:aôÎİ®ïÜ-P?Û¤aüĞÎIj$³Y¾ÃP¬#Ë«ê¯äKÑ›½º0¨×¿†4ïÑw\ùvÂ‹w/¢µ§²'÷£S«“únéÈípzCƒä‹V÷5Ä43`šÌ»$z‡Õó¬9^Ö¾.¼ŒÉ´Æìón~”Ïq¡)0úœ(›8i!Óµ$5˜ ã£4#ÕoÏÕOJP¢ìŞWs.h/¿ëé™ƒ“ŸF‹­ó);¶íÑ¾«$S® ¯j­6š1WÔ! 6ŒÀÅeärîĞÇ6êÂ|nÖavE9€ç—ÛGtÌñóó¯êµ©œG[éÂ‰@Ìòk·é¿g-ºè-ÜòŒRØq“äœ/aÒßtX¾Æ/e¹¿ÿ$Mö¶Î!Ót{Fp«ßQªy×IFFƒÏØ`óB3~æ]ÿ„+lCrŒ2»N2•„–oÚèA¶…üxxgzÂ¡½PN¸æld6¦ÍcWC5 ¥0’~ó¨‚æ×6tÔ]Ú
*Ø,9€`è>¯[JÓíñŞ¡çK½÷.FıI¯ŞËK¯¯À–)ğ?—Šâpås«¢³ªnlÊ¯ zÙ¥{v-owâhiÈ9‘YÑoºr¿´2ÆâÜ‡i‡d¢j¶‚¿–Ëö^ôê…şe¸\RÔ£-ë9–zşª“šé^È6	©ÛıŞœmÃÔ§³LQ‹£Y+Q3–üMöı-¿ògOúî*Ë+üo4ûÑKpµrt6=|äLdgkáª1ÍŞ­>x–Irï¥Rê‘ÔÔß…ˆâõÌËïea¯¯È76JrnÍb·Ê§Ø´ÕÓ±Ëmâ§Ç;Ğ²ÙùVÈİBü4Q”ê%‚,íÚåöØ‘4Áä#&?’èæ÷‰Qõ)CD@HÙË³U${f¿ÙÆ¬½d¥¾Ñ3­BE'YÔ…%iÒ¤+×¦æê}øgê)Pˆ°¾â'°ğ¤4•—Æ#KAc©âKCŠÊÄƒ‚z‹‰Ìæ?4ıIU2» VôB8ŸU–Òh«GÕ7Á‰YŒVW¿çø²ĞĞ`ñ1nK Í¾#õ.ã
İàN[Ø¼$€„¼óş‡»„0Ÿ(ïèÕw	—&íô	í`U§!Vª¤—s¥æ’ÏşËpÇùi4WÄD6sµ«aø™ÁLá‡|òIi‘6¦`Ã	…'ËcC“P½a ~«E˜u÷®Â„Eq6ğ¯Bke6³îëÛ$fâ–sê)Ò™ç¾UĞğ¶Âfó×ZŞ‘ìz=<ù•CŠ±xÂ>3{IGƒ©W8"î¤Át¦Ê”„¼Õ¡QeQâ˜?“Áüx8„»g<òÑ½µÅ5’B¡â~v:&®[Jãö±ä5¥s¶`{ æ+±JKcq?PsÍp 1A~5=ÖÔbù„ÑĞEB‡§ÖïÏÆ|g×Â~ƒ	.³iœ÷Cïxù½½FY–ZèŸn£õˆyå[l°Z·°Q@ıøó[ÁŒRë0ˆ”¨À-ó©Ää˜xœƒ\ú‰ä6” ö ]à%| ¢3‘âRRHFæZ“*¶±5h{âëh¿›(? aT×¾¨ü’
häR >‹Æ•ÜÍèwa˜£h”ä™yÁÁãSºõìı]òÿ{^6Ú‰Ç®ãOdÁL¸ L¾aH3uA˜òKİƒI*)ä$Šİ’şM›Ü•Ìl&ªŒ“Ï’’”îpOv†Æñ
…1si6œuğF~ŠW~²,JÑDš5]#O „¨¤g~/¶ïkbùÇµŒÎã21œİ Ç×ŒqO×jšDœ›Iqìä}Ê·VöÍúq‡p³ä”k2f2eÙ„ÿ3r×øË"óz®û}B <gcÄvÂ®¦Ï²8B¥âİ÷öHBÚï sb ç¼ÿ÷‘ ~ RßM³°ßWü+s¥Ê
³#ğ[áƒmLˆ‹çªQˆèŠ§5ÑÙ¦Xé
Sa€TjK2v<èÉçnÌ*Ô®:*à=qÃŞv!4J¾VÂÎôIš‡ñOÌæg'\(ı¼s‡Iê şÃ_jE,—i‰SXë—;bx¹I	®?p2Ìü8t‘kš÷aÂèÚìm­kèæş¬Šä^à[†ÁûZŞË¤ıv@zúBÍŠ·Ñ(_µœdú˜LÉ?RHAŸjÚ°‚)Ü‹7%zªA=ôC‘Wõæ:«öèäºÃuo»¦<(ú°ŸD¶„óRŸåY}ç·êŸ‘¤@ïr’@ãêqçİônmÈ¿äå”Oœ):Í¢LL¤í™c(úĞšØtĞv¶3é_ªsMbj(£}dôªŒ‚ <NÓ¨³eM«òBc? x«u¦z‡2·/H]q…õç/ÜÚi òBÍIÜ¨ø4I,¼§bã6Á$î2r²û|ÕßÛl½—‘èºEdh‡„Ÿ4XÄ%±çê2H]L=§@ÏC×L?.×ô„†z<=NYœµOÈ¶ç²ä¼¤‚e ĞÎezë¦CyÒÉo2"\İ£´à¬F’¦5Ã“Ş–™Áò'\áÒFŞá¯ÙôŸ!cûmD±‰Ë
 &"6¤ÃÏIJV¹Gÿì¾}Â*ÄÌ5i6Ğğ0±órqO§?q!”j}ÇÅÀØÉı{LN¦ƒ°…y¦08…eú÷¿ZY¶VÕ‰ÿÁb¤LÉ´ø0Cñ¦5pëm$L²ÊYŞ+÷³¯NeZõ‘×”Ù‹ô1‘¼³UùE`ğPÍ_à$‚ùÈ}7:î>Ø
äX
ÍÏ&°êR±Èá~˜å„f³‡Í§=´ÿÜ¿·›É3+MuÃD–Şa3C
áJ›†˜Ç¶Ì;aWv÷¥N&‘õ…zA5Ş¿wõi–JÕ÷#A]î°¦\˜Rf”»7şıÂ‰£vƒ‚şç®n-ÚYQ!!K+V:ˆÍôJ}ü‰J<!Ù¶÷wî\ÃÖÂĞy{q;e+>Ù–ü°ÆˆÈ~®cİ¸éW"ÏË ÛÑÄş^Äã´W%$Rë­2ä,Uíj*ŸñA}”Âİ­÷±˜÷\D€Ë¿J_/™ÿ¡½Ej’)o7)_åÑ)îÆ<¢yƒµ­á°S;ŒO†©µı7ëÜkÑòònì&’:´uÆŞÄFá_†q%6»–º#2Ö/àØ™÷ªJîIõá»8ÚË’µï{q®Ño+79fÁrŒşÄû@s6j¸Ïü¢ÿÈ Ú}w¿F’leòï‚?P!ágÅ£•6cò[ Ò¿HğÁÅ¢„i
6Òÿ@w3ö×ş%Ö–­+ä!„¢Ã½[ vş‚L ƒ?‘¸û¢2¶!şF¤îìF1jœÛÖDO]Õ¦Ø©sªï":¾aË' F¸yK @¶zh2×èd½­•{EcX¸Ôã£1¾M´ÃEüÕÚ¥–˜¹W}¼ÂZæŞ(ÉõÃ¿À„7îY\¢„•A <€ob¼9N÷ø¤]x¡«`ºtĞûd
o™`¹6Ÿ†'9<[Ù|Õ‚H«À#\8Q"Ç:yğævF Yl
"&XÄa€9\„©Ë=ÍOƒ]sçô+»$¬Ãè<).Pvşhä )æ®±àôÍÚUí0Ò¢EˆÕüñ¦$ødˆ.î–-¼hŸ}6Ä5ñˆ…såÌv«ïÉÖt¢6LúŞğ˜òá¡§EŒ Å õù· ØávÊ 9){Ò/¨e{Cõ_s2pÉ¬1 ¼`QDßqµgVšIs˜¿äıŸu'‹UïØ,b	Ğû h	'ıF»FJ)	Ó?2"Õ´rwô½RìƒËÎŒ1<…Ë|PÔÑö=QCVµ÷wÿ§-Œ,ĞÃ¿{—§vÅ‘ì9Mµ|š³knÇPá^¦U‚ë…jçæF_ÙÓŒXÕ4Û
’âA°TÄû6İôû8”ñŠ~%7KEd+£•øûf±éØ¢‡.dhX%üš8c£=nss)ƒúa‹5ù¨£+•Ò7ºï<Äë@iEY¾¨M_$høÍ˜µĞ+qÄD?¡Ç%zÃsÂï:è!ˆFzUhjä—ÿ À†Ísş­b/;é5qœİûù·kÏ|Š»çå<TÄºÑãåf8il×İs¸tlP
©ájO(¤oâSMè°—0ú8©(Wk2‚Núüg`*’ˆ­PA¤uˆÉˆU× #e:	ü¬5è’º¸›ù>bÂh(ÍDÄ~­s@“”
ÛñŒFøšOÙ;Ÿàº[İÀ2ªoI[8]iªm«0tÊB#±çìhĞºc68Øwñ.6Åò_¹¶¦ò*²3Íx‰¨n¦Û[`H 7ó‚O&Hç\ëï«ĞfÙù»0F“ÓFN…G°ÒrşéÍAÛ¬¤eà“w¤—ùBñ}"x—Ü8#Şœ¯ÈÿAÊÑ?ã«g?ïß~HÒe¬€#²4ûyb*!°t™OŸ¼c©ÕĞ|é£¢'>°;Ôym˜/à'¢Ö|H>½èG‡ê[ëóı4•ÂÓEzöŞ}ÊOntâ7›¡›[ë$([‘äyë>?uàM¹î•J2T"MÀ±Ëïœ˜y]ĞEPBv‚‚òÓ7:N´®³ëÇÙ´Ç®3¾ü¢f{Û+×¬ÚNp’âGb,&“´30„ª
5>ÄV$0¸4óÆN>Ä+ŒİTşç1cyÄ¨¬]n9 õÒá#i~p›ôgSAíÌ‡›1&ûN°ï--®Æ7º²OãÍ–^œe	í¨<‚ìÜ^'CæzÜU13‘c'öù`,¯#ªÒsãŞƒÆÍªşÍT÷=Äö$‰ß1ôà×“'~î|Eã/më‘æD7Á½ÌK®hÚ,(C¾Q!S¬ñtZ“Xö´n5·Ò°—ßÂc¬-XXÉ‘)eZSgÑ9Èn’”‘àUÔ³a+=Ú‚²ask‹xÑõı1Ê˜\˜Ï\Å{7ï»Ó}K?W_ø³+Ç¹Üñ¸mÜÆÃöŞƒ^¶{=ë(ŠSùÊ\Ö\–»é°k=©¢°É†á2ÈDCP×Ô·ğëò(Ú‰`mœÍ¿åû¹îBú}.´exãPŞi#vÇåÖ¾n'leúg“¬˜è»$Š®ñíƒ …%Çí!0šÁôÙğ˜`ğ‹ûòÓ6£2˜ç‘ñÓcê~ ªShé£N+UÑíI-s›óÿíù²’Q(ƒÜïü"m®Ñ_S&J¥8
Èv¥³AĞêî,ì
#Q+d<eÜDã¹›Çì5ñ·+·œ÷•ßÊqë ’&·-ö!¹C>–å”{Ó‰F;îO›İñuX0ğ²kç5÷i6@J¼~)Iå£‡‰eV_j”•øŠŞ<ÎĞÂĞ[)­ÄEâ¦ò*?b­²Œ]kšÚ‡”îµ¼mé,£ÔõêÁ0/÷4®yóÁMˆè÷Å1…}óŞ¨­‚'
ÍyÅ¬ZoSoÙŒDr§Vş½d¶O¡wàÜÍ²ï6î“ìOD4x$ˆ¾.kkĞÉ¦®e,„ùfÕúÙC]ÒüÑd_+ù.V~¾i–W¿ëVË
«PRe¹‚ÒWíDV™m Æ<<8ß_{ğF5BgO°ıªò˜Ñ?*Ê¥,–ôñ†¥©±S¥>ªäj„@¨ÍLâˆ©ñÕ†bË‚,oÚÛK9å'³ÄL*%ı¯¶„ßvdÓ¨\7­4L…ãï[È’îm4*×Ô\³³Ç{^¨«¼Ïäi;f{9FW§ıxŠZ0Àƒ0-Çã;šD–"ùê‰F‡ô_…š ÓìxZsşaÚ‘•3Q\hÂIÕş¾ÍÆ4ì¿q™ JŸªõµÉtíg }óIˆ[F6jÊâCğ¶u¿2xÙ;rÙ1µ—üßbe_»‘ÍœÙ‰ç¦‡œÍ=Ü~i­#×.?L¨B)ˆ7w}”:zÍŠüêl†áß#ÿá?±¿çÏzğğAµV´•ç&Q®haš›4ª‘·aBéƒ¤Ãkù3LµyµT\{ç¯àJ!7?Öu‚B²]‹Hèˆ4ví/+Š¨2ò¯h>[m"ÏkÖ›gç•`QdÖÔ/\×ä¨±‡ÚL”È3¾y[\Ï—õÜwg‚\`êşBí›JÉSSº¯EIºî?ıå+Ô\xa\¥9¢ˆªVğŠøˆ´¦íŒ“ˆ¥!vmÄ	è0pÛ®úH#5û)5PJr}Ñ
(f ‘²i€¿ `óN9VK/=xG2¶eÈ?FA2 wTøeX.tÏ†Mó¼2@K	èé?mL	$>£T]°ƒ"m9”íDœôm¬öåí¥Ö¤İÇ0Öè“ $>4À¸>——n9±Œ<±ƒ{§…ø«±ØÙşV±ÅÍë&3:(»QST÷á¢t_C§ÊÖcÅ
/ÄÂ9;3‘†t¾Ä5Â#S´C­v!Ş[%´ÚxÑB¼îÔÍ°ßÙKŸ¯®†Ò+1Æå9×lTôJ´H‘Ü‹M…"K™şGÓëEÜ`øË7™¾¢c+§|YÎs¡7Záô¨
{ÏS¢#UÊ…ØvĞL}>Ï Ó]G‘d©-óĞáÿ±³/b7_a´ÑÎ€s¦P€’?rpn¢ã1OdŞk[>qo·M|$ş¦÷È%ÔcWí;É·ıNrm`Z_FZ¼úĞwi8Äp	\MçŠTëÖ`Û¢”Õâ®SÀk5Gòã})d²ƒ(TÏŞÙv÷ãØ¹ƒ<ZÿÂ¬.¶¢§Â“¤1â,£%FwJäç›7_«šŞ¯N:s<ŸFèª')á[LR+9b ¯6ÄJmÍwÏŸ½Çü…âÜCI„ÄšK(œñÉ‡ßèOï×€mÜÒüæ`ÄX£`Y”E[¿¼ëD¨ˆSÄñ“Œ‡¿KŸ37µMçÒ3j:I<=ÃÓIãÕ‚,™2v¦~)°#—b3Û¤|œ%ÏºŒ•^I¼l¤Ì‡1(àqkÎ—öâØ¹"D5 Îöşyƒw’jykÂq,Ù"hT7g Á>!’R¨­6z›³Iæq£\æPü%ô§…7Ô¥„³»t#9`h!)Ğ?ğ4œ÷†T.pìŸ7’R5íÊ¤ zÕ$Ç›J§Ñß÷Ø¬íqµúÊğóìaw…)Z+–qüÌnÜT&3­Ê:GÆUÏ1O“pF7=/° ^1#õXan:DæÈõÏ‹CS=[Pï¹u˜BhpƒvoVjòß7±»¶DQ<ê¿V®›+·Ñ Ûxoá—Î’WŞŞá†,ğ£WNwjG'Æªß¸†.òøÃôò2‡@{mÜçòŠ˜Ğ¥×è¶+5bCEkõƒÄó²³ûBæqp'„Òã/ÿDOmMvœtµ3S|EMãüNx…¾TöküoææÔ<³Š+¼IFï‡IäGÊ—ŸÓ…+Ü0÷İ°ÊÀS¶òí”®¸Á>Üó¶Ûò&ø›âœDè\ò©Ê±È£*.JbA-ı3ÿ@n—äw‰â["[ßB5•¦,„›jz†Üoôì­fzåo™5•¦ñƒßã3zàƒ›‚Ğ1lÿ5ÉdlnGœá£´ˆ×³²¹Joóş<NkÍà¹V¸¤hğãVôÍs«ÜÍVLSdı	¯CZX©Ç=mÆ‚òbvÚ†g«Ö	.Œ¦ıú»æçúO-Šñ±‘T{{” Ü¬ÍPÙ05§Á= cïŞ¥ˆÑ,ÕÁ/•Ù×X6¦iÛa^ˆ—­GÕhÛÆ4=…PÇº¾­ƒı¼^’£§-ş}æHœÏ=£_íEù11¦ÄP“®v§çY*+ËCŠs¸$hÄ×ŠäÇ£Ãîû	ÂÔØ‰„3ÙmtAHEæÉ•Héæêµõ&‹»¿gÚv4ûŞÿE¨
7ÈH zkE-ú?"Eü€t|SA#OË‡`ò’êJtÍîà%Š¥êA™÷{æPa¦ş‚Òš?V&ÄÁú/9RÊ%Ö™©ÏÉOy"rPvqn<‹Ğ{÷âQ88i?_Ş0¼Pû“£w÷NÉ<æZ\ñ‘mğ†ÕözˆHS]±¡İv”"–Í+W<^Õ90‹B$¥³õd¢Ğşø5­i*úàDR¡;S‰Låî5ä£Qè«…X7cÈ©ŞØ`3c¨7¥ëÔhlƒŠ²è“s·w%û'|ØQ!8½·¤{àé†Kñîctš˜/ıæ‡«&)áo¹KÒ!¯î*æH±VĞT««õK}¼âşjİ×'üâü»[écaü?}J`4ıáÖ/ÅõoA
Ó/öbhÃ·r°¥ˆvnT'!8£›où8İIR*˜½P„RuõÑ¤f—¼.˜±;ÏLˆ›i#®D! Ï/¹§É4ûr_uqµ?#Ù!>¦^NŞF‘_MÙğÅ±ˆ¸8§ıè‚6ª>n~şpAARğ¡x­Zf¤ÂbŠs–ª¼?¹òÔ^e¨{6Â“úşXZ õÖw1Êîµòv+é£¯¤qfşÂ%oÖA!ÜÏ*¢NH»\õITæ)ÇÌQ‹I.3œW74ï‰në#óÑ<æÈ¯¦y46™ï;«2ÓO0~Ãé‰¥¸÷é ©Aãwİëdš"0Êë¾»r¬1÷ì|v˜ÇKxHJºı~‡‚b!ƒHÒG3q?û÷\Œâµ0‡ôáÑ8}7¨’D¨Rğ“£íY"+½Q²&ÒD6¯ŞKöÏøÊ³Ø&Â®«&'.ºñ"#ÌÔñò›î‰ô¹	pâÅ•ÍˆMº	Şë4‹ÌxgÀs‹© U†ô’yaµP_ó´®¹$'„
OÕp?L+ÓÕM
"xÎÒıÔÖ‘µt@EÂ4yÁI &[í@¨$¦EæŞ½;!ÇÉıÁ)YÀ ^T‡;
(­³ D¢¶ç¸ŠÖøQøÜz>Ër]ìÍ…k¿Õéö±x<ñ¶Ìdh8 Cp2+CÁkõ%VÚ´L!½aäp†'•åº"š:qõ¨ŞJœÇÛa¹8ÚA¤ç6=Iµ¡KQ=À<ûÑQuŒIfó>¹hÁ[FÊù2G¢O‹J{S+t¦kMÍSû;JXú[›.‰é½3¦Wú(:M«³‚ú`jÖ¤ô¯T¯Ö`ÀÄP§ cÑifã”Ê4•RPLy'Ã­
ÇÌz'#ÎèâçƒÜÈ>‘%iòQwWWZïğšÚ¸›.¥Şû}hœ‹ M>ÛØWbq{Ã!Z\÷ÆÙÅó‘ÈëF¢’VúhC¬PĞ½‚”‹I¡3Úú•oîrTaÏ½/„¦O,IBÿ{‰]Õ$JN8\3 Í3V…ùóĞ•7ü³@\oC¥!¢Í¨—Š™@ñßÓ6‹«MqÖ£§şqq#³¸±(ÎW­méÜ°å³ÅvÔ`ıŒÈRÿo/öp¿µöTN& /L Èo¶lÇf7›^ãšbb'ÁmØ±Ö—Åä+Øİ&•	t·3ãÓ­…ÇN6CÊ€4Ñ BH'|ñòj_fO–Š>—9_áã¿õÀ†.ªÎ	†BÌf«­¥ræµp‰áÒ8,šú¯àDÂoR«[0 ê§•¶;½ZtÃ¹Uè«è£Ô‹}øøm8oÑbx×÷×[£¥¨h‰©—0m)˜kÛ­‹R¢®Ü4Kv9{X É¡cÜ‰ŒkÆÓmc½Ÿebö{®¹™j„¸±©ÄõùûòÌ-Ş´ıî·oËI‹+¿T7U¡®²P‡øEpÆ§h‡³YÕôµ‹™±IÃŸÍB<Æ(eÍKLUØîwë
xÑ™L¨ó	sqşyÙ¨«5,E—SÀãlÍ‘ë=«;m×ªQ–<F¬ÿÊÏâØ‹è*šüeí)öjKû¤è#6iGÁ~²yƒÉâ?
øêãé_åbÖìN–ÇŠ••ô#mhîŠ1 !H¯ë6`OÌèâ™…=OtäÏpÈ¿ı¤¸›%»‘Òå²5e0åbXÕÎÏ›Í‹{æ±Q‹öô§´.‰¡Ömÿ†œóOyïéíÎ™ô\Ñ÷7â¸EÓĞe+ê*ŠJ¦ğÕI¨Y—’Û·ï[l^Ğğµ.ÅÆ·Ì×ó2á¤İË,7—q,T"U:s_[8Vúİ$M@XÂa`UXÜ•Ñ=÷D¾~b>æ,û·¯¦W;„ÈQÅ	Àøş4şùtıº ¦%ñN]ætŞ}ğÙ„ˆ×d{ù”D·ê¢õÉ„8ş
hğ ^+·“Ñ‹1ïš“,e…‘ùm2_|K¤HB\Ks_RoÏè©8VH —±–d²ñ¾6P‘Û´¶Ö,÷Å¨2{óa“ÒiÅ¶­…¥ŸS Fé½ó˜­l§S8
x—ÕĞÑ‡ÊˆÅi´a ³ªAq“ëcà´mK7a‘’Z?bn.ÙÌ\ĞßÎ¿…»µĞ­ı–"Îıh€"ç1cû;»cø kßo«pª:UPIãjæ‡&€	ˆ …j–~(ÈúÁep+T09HÖàòEÕwÇù/º
bœ3Èòş`pWşr‡äJWå¦Š>õj:ç¸ìlÖ×¦ª™ı4Û	‘Í†µà1»çE¦é—ÌƒSZ”·÷—hÆ;–HÅM§1¦¿¡,fFçÈíc~'ƒeñáOQ•.¹áœ?¡iÒ$(‹×¿´	ëˆõPLTklœtÉÙ>kÅ:“Nİ§Uå’uÉ¨-A¾³m&ğ“4#ËÃ3É¿PÓ
Y›u Ó1eºüâgıwå¥ò†%3•Š[è«
QoÏ™ÇeH”àhĞ:˜-BÑµ´$ËØä,VôyvåÑ0L8 ´§¡&qæ&"hå'Ÿ×ëpîÿ"ô¸î7>ˆÉ	:Väì>ä…Åï©5Aunşü•ç__Yâ%!©XH¤ùKûvı¢ìÁ$5½N6`ÏvØnöœMá##d–øÒa…ˆ©˜j5ÃnÑ(KAÖoŸ2;êRf‹v·;€¬ä1çãL–”Åia˜Eş±ÏÖû	™4CB~ı™Bm&]¸’«Üœ‰ËÉg”>”w½dWjig!ãL:c2ö¤ÏÚ‰ş>)z¥”O#=Æ ùo59§r9èÎ?©"Ÿ,DqÏƒ,+Á†WËN3¨ö«„t1;ÒÜÙ7°ø4d0›ûÆøÇ2š‘©J’Dc?Õ\îy¬ š©ÌM^FA†¹²ÑJ·“ss7ó*e…º†ÉÍ(™®²¢=·YÖM*ÆÃjì"\\ğÿ_f¬ÕiqS…ÖIX^AÚÍ¦)!ƒŞÈ’°ôgNo=È‡L±ô{èÅ#sLÚÜŠL¹iíê)¼V>Îb£yšªs¾~Ãû®Ry¯-p…xn ¬ä	mNö–ÂòŞ²zoÚUßˆ,K©;_ÈÙÏZT9%¶,I¢Ù#<İØ˜z©*ò IÔô¼ùjà“ÔÍo•&¡Pt”ÊÈ†¯{t8!ğ‡ÒV)ää áõ¦'ëCh‚KüÕù c&ÆQ;…f>˜º¨èFÔª>«Na£¡:j;ú4hºô5ëÄ©–àŞzqÁÌ>xyMÓ¬WóÉı™eÄs¹O4³®%r=2¼çàÆê9ˆûş×d6¼¦CÁh¯ŠÀX0Ÿ!1j¬G»hCQ$WVÎüÑ§£>÷‰ÔŞTJJG§ØãÇ»zRå/â÷ÄÇúË~‘ü7FÂV‰W=ÎZ+aòôšÈ9wn+•ØÖîMA×ÅèO`QIG­+ˆß®=Í*ÔÁ`[_²
wiŠeîı¬_ï+Mûn0'€¼ÓjççrÍe'¤<iJh8HØ“ø{q”R>w§ñ]†ó/ÖR>´ÍºUiÿlù“¿È“æ‡çt'²|²aö”£66oc?’qR‚H´šÚ[ŠmìWy$”F¿>‚…õ(3`eğŠy\yÍeËé1í^zjÒ]Y`ı w¢BÃ$‹À	‡7¼4•BQ±Â[Ÿà·1šewCx|Léè0ã÷å¸8¹¹$ñ½7nåó^C–Væ‰ÒâAÀ*_âÈæzÍ³söè!³íœî@Çá—ZV7İÿ-†<µE‰ı PU"‚<Å12o¡|eWşNAè`ÓÈ{œN³åW,ï2š+ã¬‚¢¤AyLPˆ«™Ù³İDÿI,TßW¡½±¶É»»A~ÇË6»Ş@k«üz…—¢§Ó÷ >+¾ÅWæ«3‚î•ïKM‡R
È?xoİÎ¬^Ù U>Ç»Æ·5¬‚=safÏĞıGŸŒcw/Oİò$4ù^_»6>÷,O>©Ğ˜Êlê€&ÒÎ£&‹l6şÁsúj*?®x)õ–cëº]&nAk‘yô•Èuj«URbÍÉYèâ;wÎ(ÕdÆ±ä’Ç¶+>®_µ¶Pµ•–iÎÜ8L…Ps‚-@{5kØf¶heŞØÎ¶ï*ñnáè	Ì-Ü‰ü9Rç™¼¾«K…(ÆìÙ"FöÓeyşItş¤7w4ÆòË<¬tw
À°Ì_÷ö†ª_\RŠ·éA‡ÅgôäEå@©³ã3V?v@Î Æ–•|‰såÖş>MïÄí›gÈxÊ‘O#v|:ıYzNËı³ÉEÇOCjP#röºMxİæêmÂõ‚Â¯$éàö›³eââg˜ß:ò”AJ|nşÓìùÊƒô5tj~a&o5k(ŠÎP¦
*Jˆğ*ù§¶M¿N'ÛM{15Ç|&[¥,Z_Ç{7,Ó_“ îkW!ç¾Õ'Å·k‡î°ÙÇ¬Tö—dÙŠŠ«
tpkáÇÌšD#E¦ŸÑ¶ÃoêKkxC½íìªq»¤{Qcº¢«¹|&O(>é\ZAÿéw©Å.¿ÖTgŸR”¬Ã¯c§Ó`F!š	ˆ~Ú€; óĞ~í(æõÅwx©‹úM0QzÓÙåb–¯õÚ768‹º‘ûëÏúx‘CçlLåT³¥oÈÑí"×Š='ú–¶jËIëÇJ©vÎy^9´Ø>'›×TíT’½"5«¤×Ù¡6‡â‘ƒW(ë¿v°4$‡4Ö¨J©æŠ90ìS«à?™Gµ¬·…Éƒ2‹ã®¿U¿•ËP¹+ ßøUó²ü,M5ÍHE[éÖ¡aÓ>}*ŒHõç5ô©"t÷6ÿDÿ­g(y!
.?<´êÎ[lÒ«<3#EI8!È@Ş3V'Ò+]ëÌ?A¤¾]²kŠnªGIµ§Õ{F¢)Yçq"ã§tğpD¢^Œ¯–ÖĞë2wP 1Dù[TÖJ$,çÓnÀpî[|Ó×ëÊ*MƒuÕú¶€©2¹›ƒcöÊ,-´¬ÙHşZö‹İñP9Ö„È.ò¶´å.ï®¦ÎFc}6pfxå›Š<$*²XL-si²	–Á¾Î¾­›@í#6µ'ÁåŞõéªnA=Do…=ü?I¬Ê6jg†}©Ş7²9jU¢Ç?ñ–[’1V¨¦yìÙ0LA{4xÈ/eNdÒqÎöŒ÷b§¥M.´PÅ*ÔüëËáe›¨ş)‚’¤…&g	tÑĞ‹©xfWÂÌ_|!´½wJ<+S¯[ÙşJŠ!÷_	ş«Õ.ÛÖ¯PR$ß‡m53İÓ—éyõˆL¬rlçIë®¢{dôx)H`S¡x09¸®¯Í¸Ş[›4SµÆö"/øüvœ31VÅ€ı›şŞÌ‚M0jziwíş
¼üo¥¬ÑSÅ!~ÁIŞÖ'¦ÿ¿÷Å>–ãş_h5åˆòQòô4ÜõÔÓ*[1´‘[ª•$à¸¦@åóš—»‹e#.ÅLB lEHŒ¦ÔŒüõRJÅP
æŒmit#vpàkîT„_Îw 8$(_Éä€ö(üïò2‡ûİ»zdóf
Dğ.>w·íÀ³=×Ááö¢ññk©²*œ/Ğ*‡dxnBöZN×’t´;Æ/À‚XnWÃ. ízh€¤b˜‚ê£ı7È&­ `àÂÙÉ?IHúïòûHìÛ½6y½{æûu›H	Q—déŠ£D]éu¡/49¦YÜTú/9W.œ ş+5*~ìæš]–'	İB Æ­~´bµ¼îxîj¡ø#¹÷(‡ÔÄAjTİ¯¹‘)¬P¶7ÿXÖêšÂ`2Jc»Ì:|''/Û“pÚÿü`5!s´’9|:væXp•‡7Uº]
;>*›j!á®<Ó3y
Ã=H)£“öeÿìé¹™9ÅÇ•w9®îÒpØÄ^äÒVÔé}<œ”¾n)vcH-}r Dş^q¿~ı0tÚˆi2×÷!õÌÖ«Î¶à4 àH*«>èÁÛ1ò¯Årÿçk]bİÀú`tà¿sŞ
0æˆĞóÖƒrrş²«v»àˆÔ`®j³9Wñ;2GÉ0qãÑ¼;#}éjÔa©¯Æ"j§lVñxıú%Z2ºöi3ÈºşÒ«2]è9lğ]¢~T¢3–nÅo°ôQH³m¥šãÿÅ j•0ÎGÜ•İÁş€±ç >Däg·“hm€^v$µ…÷]Í2$…¦‘¡v]„ à²q§®ìw1 jPõæ	õÃI.”GgõŠåäútV½Ue€H£¨Sa²ş8Ã$¤íës'Ñšõƒ*›ÜÛ®Ó&kZG..³6Ã×şWõ‘!Î¨†,\şw[Kêv[ŠÀÑ¦.ÿ|%×±6áÙGÿHğâ¾2Ô€î¡‡úáÍ‹@^rÓ,‹€d×Úï.Ù6LÕ.­Âl@—¾ù?½ÍlØÌ½K»ŸQCVAó 1×A)ÅìJo ®Q¸£úûüË”óƒ¡QÆ¶ëNÑ&ÇMÜÙ™¾œ)÷T×šŒ…¬˜ó÷A¹eYÉqQ¦#J	s•;¼(PçRUòd6A}+y5ñrëX0îİïlqy
6sÖ&ŒÖßÔS-¶q]g<ÔÛD²äI¨yãôœ`¡•ÛÑPV~È!-ä?ø?r“ÛŠœHoY;…Z¡¼˜<˜lù	]l#rˆá”£ñ,ñÒqús`ãwVXÒ"ÎîeRwà±tšCö„ÒevQe®Íh Î{÷™'(9Za‹†ğ¼ÀŒ'ûgì[LózT”Ú¸^¤¶¾ª*¦Ìuš›>Ò%ë°§(pÒàpRÖp¬4Vv2:®0~Ãİgb†º—Öíò&ËøÓsÃí‰F\“|çpo¬ÉÓbÿM©=a˜ä)§‰jĞHˆ£W!p#ó­™#£a¤C„õÊl6]Ô:J»óËÑ)ïê´ÕSmÄJ¸3Ğ1|î—ÓÀª«ÆñßZlÆ‡¸Ş\¤î,©©^İÜ¯ÕÈÆÑ^£íúØµÒ)=¹š3Šjæ}ƒ¥û<ì)'ú
îÅNæhC$m®U}ÛæZë÷GªKÃ‰RĞjRräøı°"ãSqÓz³kjï[É8·3}º•1pÉDœ4Ê`İBJ= ¢ÿÓ³<ˆjV>Ü÷Å‚É¼³„$à ruE`òìÆ•ò—‘“·d¸.n”-ÕÏ„ÃÅNjP? rj¥¤§û¶Ö]ÿ6©#’13bg›â±Soöú÷Eİ<qöÚ´%¹iğİ$¤Ç¬"z<X`4@\TßØ çŠ„a¡ì¡J™9bXó7¼®g™šm(ÒåÔn©v„S|öOfïş[ÙökÎ©¤ŸËÂ	œ@yRE€^]ùÊú%hL€Ç]ïÑ¶¦
#¢i•$3v`Ù2]Vãòí¹J¹Ï¶ØxÃ:ğwbªyßöÙEã‘uC4‰‰Áˆ[ ©ígMG6tÁ¹™Ò‚Ëm„¥•˜ùqÛxKui5Lè_+–˜«n|sÆ·‚M18öB† ÇWlçíD€f^lÜË9nšÏĞTÄ„¿Ñ<6ÅlËá†?J¢ıÚ€5Ü2@ß·²`œıvq˜€]_¢’K¹ûn¦ß—ÛÇJ,‡—>@‘Êƒoè×„aêIl<¯ŒJkn×HoûígZİ†ïàµ†YféÙd8€{ir"R·Ü~#ôSåSÌ[Œ›×GhkJ•^ıˆb±?‡¹hYz7êšÁÊÛ\/²YÃñ ÙWhí•ÜæĞ—v›DÖñ™°ô2Û ˆ¯“hÁ¦kí´,Q´ˆÑ÷‡"åkÄ ¨Ş WA§.ÂI[5òğ(Ârf0-`ŞZ†››^â%²8±sÓùé)u°…PkÜ86‚WÑ×€CÖÁƒ±&„0Ã«ĞnH< ¬kzóMC|ŞÁ&à­Ã!e°ğdâ/ô¡ì4d¶ş%æ*!¾hç¼·M ø8ŸM
ä~£\2yÑÕÙßıÀİš7½Ö¸ltGòâÿe R37Á„eÁÜÑóÚÿ<à8ºFtj•z3|ğÌñè2ÒøF=µĞ]ğ"¯lŒ­ÚïÍ	E}h¼µçÊ›†Ë"B§@ÉúÔiMˆÚf $S+«Dg§K^¦pÄ A¢±¹/‰—Ú¿B€íè¦¡açUğôrŸHm¦Vïlç4£DY“<”}ffyW7›\ÇA‹lÆø$Ï%>xŞø"ÖX¨o,ÃÒ«BÂ$’|ª¡Ë‡DÛK™=ôìNG<Òœö=ÈÛ?Pe4pE +ÂÅ¦¯’ÜP4O#¼ ×­¨´Iræ¤×b Ô'É|¯×sÖˆ…RærxÓˆø£­¾D@Ÿõ¯I·¿Ø]ôôÜ@)-{¶˜lÒıİaıNÑËğZ4ÉËÚUßzÖV7»YY¾T%Õ?w¬E˜=IeÎÇ·â-¤¸ˆŞO>Ã‹¥NºÆÆ”/Å¬Şµ"Õ9¾ßB&]Y‚Ğt›¹5Ap¥¶¿µšÒrYÅf]ÛbÖ>{=JÄ®ï+óÍV5´-UbwàéC^!~ –£š§&²û•9àé¿–©‰ÑsX\WÁî€gv=ì}EdµZèg‡ƒ¦§Bé"‰Ù¥&¢ú`sUwqz(ò‰ÑÃ>eTšê1{–Ø¢Ø[yæ¨çµ©šv^Ë¬Äô:ä9È "Qo'î½Ñ¨jó1·w–‚Vì€íÛDn÷"k:W4x¾õ$;+ÕÄx/·!–.½¯jæR1õ0İB¼Ûåô×%á2L´%¾úAïL–¾ÍæT]õPoiå Ö8‡,u$T¿¤gR'Uáå9u¼§S¶89=ÜâŞE¢İ±’ˆk%¤û¹sLÓÉtş“­!·ÏF$¥”)[:¢#ØÉı¦² ïM,Û”O@š»âğ1Ñ“)ÉŒêå]ëSÏÿ®MoQ·ñ†c³ H’¨$ 8«'ï@öpê¤;ã—ÄøšBg¹Í¯›ä]SuÑ’‡¸I•Í!¤²U9¾2æÃ‹åÓšfŠÎâgÓBÚÇ]$Á²ÇŞ¥àeVõ1É.[Ô5•r‘%´÷&,o"ÚĞIƒ¼-IfP¦İ|òÄ®Å#Àá‡ç)(Ss½ÅN–Ãæ»ø»=í=¤©û¯C0Ìíâååú·l”¤Ø‹½ğò ÿyøâBÄAÅúî¡sD)	Ô­pšis}Æ[rÍÑÉhVÙŞ_ÌéfÍ½î£FÄ± êOj½fêü	§İÎ\®/;j,êh“9¼4
èl*Xpu®$_Q÷ó(Ñí™vm'$'Ñğ|eĞŞ+ú^!(+¨å'ÂC‚Ë?É=®qAŸPÑŸ'¸±ˆB>1$âú¤õ¨9ˆ7…w”¬»ëÃÆà!¤Ë¶MXK¡>ıFWÆ8«¹¤AŒHh|¡¹µ<	£fÛ¹ñÂÖ»÷ŠŞÚôİ†cv
¡ìåË7ë}gKXš~cİM+-hŒ8–Ã…_
€kÅÈiÿÈùcÔ@ÂëÑxØL]Ò¬†sJVµÛ¡2şQ^c4À>}Åí»îr:¦ñE¦0è÷ÑZœÈ»ı©)]`Š-§®,à¾\ œ”jM/œw»˜¬?‰’²Ê^İŠÈÿàTRÌMCa´Á¬"ÖĞÙŞ¢,MJ½Ğ<àÄıq	€¥Â¿‹Ä+/»üÒ)mÜÄ„åz%Dc7NHõÿÄ>e4$óƒ<ïÉ`nT?Óª#e«7ç>
Xì”s\Ù›#î†iëß[<FR¨QÇn´Ú±¶‘éÁ
[é#·A{hÅ”)ÂGn?L7£ÙÔ:_|¡ÌudWQL.P ı_£Â.ú„û$°”ÈX>¼U&«j#f kR ‘ÌH^Û4a_àh9D{buHöa´Gï

IküjÁÈ¸[òªúp=IêË'»Úî[ÓM¬ØnQk±½´ÃĞJTö”“@) „­€Y&:£(cÑ°ø×qnêØH-ä6¬IÌı¯Ñ™_Îô–#¹‰k£Y[È=`!ô#VEäÎx#vã]|,sl¼”´©ÑÙ—6íçò>É‰½«=-_¡W'›ƒ[ÎìÅ”Ûà÷qşsÃëq0‡ç*U	ô³\v	Õ›.ë"6a\>X©m·ï¸ì4 W¹L¢Sè‘s”«=ß|B„A´ Œ`î	ã¼Ëá’7”ñ:=Gñn¿_ØÎ8†±:rN6ÆrŠsxî}IÅ&à~YX}UmneT¦ºşoCgg†µ%´~o_ŠOÂQ4¾y€ËÈL4U2âêƒÂ8	¯ëòSB‡–¼8‚)è”Ø7¶m¤ B~q‹×é5°½6¥ãi;ºÓÆFc8å‘^›ª2®ÏùÓ—y7•]qpn‘¸7ˆEíá“Â$!næ­ƒESAúıÂ1B6ŸÄ·ĞBs
„ïƒıÎšÂÿ'^KÎNd`—‚®“®,§Î@Ì¸t¾2‡ tbãş7ğÙÉ½ŸsÅ¦)&˜‰Š¾¢¤FÆÆäC¢gÓÿö£cŞF¾Ù¾©#ƒ®)¬=ÜdrˆÙ še}—Krœ®‘èÕMm~çûBƒ>‚`iÜ]¦8`Şhç¦Ü /ƒrS•³ë%4?q“wsyêÇ†k½_¶ÙzwÓŒk>ıÃ@§õo­§n¾ßâÃófxŸ”Ïí_©t=6ÿ ZF#G ¹t*Rç\ éd‹5òaªÒıaB ×c	ìŒŞ`…Üã4ŸÈ›œ7Dá[·îİç§rŸD¶©éº."áUæ¿¤Ş¶Hõ›¥–£ö`Xı‰ˆü&^ ô>gªØågW7Ğ"ˆvnXWZ/mˆ´Íuáä‘mû"yÀ§g(, ¿Ò°,ñW½GŒ’C•1×]b(”Œ<¢D¦Jëj/Œæz%ÎñˆŞëä5‹o[[÷¨lNá_”Ñõ³‘Hd>óyˆÎnïµÎV9Şà…é±[d°BP^³ëäémÂ3Òíš2Ÿİ(d¬i)§Ğ…÷bÙcy/­îmzÿÈ¥ïBçI¶;–¤U¢Ä*Œ˜7šÆCŸèÑ¨]wÏ¤8©â/5K¶*-m®;ÉGòë‚n·ÄµÈ§â=I²B0UÉI)vŠynqjL¬¸´½>„mT; X°3Ñœx`,Õ9ƒ¬§:çG~|¿œâ$j,¼AÒ­ ğ´©º„Y„[Ñr š®N‰GÁl‡—šF ;¿OVæEâÃÂDó>kòOjç§÷,'š*VÇ†Ğ[U:Î×¯h 9³äÌâ¢°S£°ßx–Õc~a†tuè›Ã˜DMN_œÊÚÄÛy^/¸éÌèËzî–1G¨@aòò©5R©X’5gŒ@çu[Pğ™#Vı ‰•ËÌW*¡ëãÒk‘NS*ùÀËò{ u÷ªì=ÕÚÍ1zõ…Íhüá0n°€İR|0qıç9!©ì:©vı"G³Cµ_6b"d[^’KòÙy«2o<;ç¤ã}Ôß6šH6ò&€SæˆdHõûàGâÔ™ÌŞIèL’H5BM¤&}·Œ¢|½z*`•¬Q°õÖŒòÖbé­–iOQ¨¢'é÷˜Â»,…>kƒÏÉUåD@Ôkõä#V·\)…}Ë½ig–gÜHY¬¹$ì,+ÍÓÛÜ{1W½“B_ÍYƒ[ˆ=mrÍiµN|³øBêj®)ŞîLâdÄsÆøDPf‡jO¢Í–bÊÙ"BèN ÷URÀ*ÀûgŒ’ËµÓì³èÌÇvü-«ƒÿ”ˆ’° ‚¨Û€Ì˜ü:îœ*{Qà…Å©=
hYqêF <°aÓÄYä:Û^şÃn:HâX…S9ÚRÙtÆ?®”‚w¡ğPÅ~¾í 6;CşP€iÌä¯ºãÄü?
’9³Ğ€‘5ù„Æ˜S¯/¦PdÜÚ/P"w…¨}ò`AÉ-Ş0¬A”ş»ï)Hş	Õ‹Å^Ÿ‰"	‘Y› l•Å»lS÷Ø|!'DtU¾!_ Ì¹{™P·”X>€A§ÇîÊ0Ìæª£¼áíOuÕú€¸SûıäŠ¶M•ôÔÁI¢=í°êWçl)L¯ïh%cJNA‚ìÄÓ™ÍA¼HúW,¨¨ä––óñ½Ÿ÷å€á„ÙéĞÓÀÔB-µsJ6½üÄWz{áğéÄN­
Ã'S¦g©P^"¥I†¼ Y˜Ú˜{øÊQ9Y‹fFÀÒW“dF1í±'k7ï¿âô/¼›øº(@^§]53,Ü,w„gñ‘¼7ücíGÊ4ÑêVE†b'o)û({òåûŸ@	ù‡Nàä’²›KğPKú'~]˜´[å ¯¾æö˜Ê6Õæ2%¿¸–lFÇZĞ;µx4<œƒ#HØœ+wğcëT¯ªÿ!¡AkqÌãúÃºá”T,Càˆ®Ó›PYíËÍmÌ0ÈïZÛ³d
®È¤ N-/ˆ[·\£MN¾æ¼:Øş#ø×%’Zp˜DI8}İ•Ê$"Œj¼6ÅëÕÆé@7Sä§sƒñ˜IÏoÊ{}*ç+E÷ö
›&êÉÖqOÿ˜íG=8²›„®”ÈDŒ=ØGì;!1mY¼mÒ½²ª§bw.&XøïÆ03¸¶Ï´åHƒÇY¥‡<2ÆQ­ZvO&aØâ£²wêê•Hœ64âçc†ëŒ±S&UA¿´Nçê@éæ«Ç2BìÖù´äµ=ù‘Ç“m•.Ö%rhd1‹?×¬ı1U\r*ÃVdqT“ÌPÔG¿
5ëiÛÙ·f­¥†+€b‘ÿ€BşuzÂÀFö×í?ñ/÷ÁŞŠFˆº@où¶³üR¼B—Í8¦;0F®­ĞPŠo‰„ŞªãÏÿ²(³™Òû¥NwÀz™&j©é~³wÑGĞWCn~˜‰JŞú„€fJî‡ŸaÂ:»÷#ØBPvû²¹:çûÏ$æµaÿŠP÷„â‰cÇj:°_ŞÈã Ïk¶È°İm9]ÅÊŸ>ğøñdï½r”¹7èáØ~^‹°K.Œ[YŞ—¸2n˜ò†ïƒûìè\} Iñœx+d·GPljĞ¯YÓ÷°ŞÍC{±aŸUJôfúN#C˜ES¹Œì°¡rBñ%ˆÜzh\a@+Zƒ´ô±¨=Âõg©åÖXÒH{©ÀqŞ[5`UçîË“v~åÁm:=k(±õwkù«HÑçûUÒ¿ñî™?”îº ¤5R
3šrF]ÏüÚSUG ¦áìWeò“¹‚Ç[ıt3ù¸ïç{ÂÂªzƒ 5VÃF †nãˆ‹táè3A‹ºhNƒ0Œ»ûÖ‚î]²ÁhşóZ—a°ñábæóÀ€åı—U9T«5İ…ì÷¥¾õ‘U7™ºz’òÊ:ã8zÛâ(ÍK'ŒH!âTUj#ZôäyÿlCÍÃ`%@„@/¯‰ÚŞ#pÑL¥B×2 ·+Y?Òûe»üi–É²
¹…åø~É¯º€Şä{ƒ
‰ñ™Æ(ãÊWXZô@Æ°²ğoK¹›9?KJ[y¡Hnú'İN>èÂ~“ó@6»QZ®E·¼Ã˜èöËdaŒœ,~¬ı×>İúAe3Šİt\K"#­ˆÊOİb+[í9À—Ó ÉàÄã#Ì_kŸU#Ì‹íQüÜ33SÓ`üü çÍ«¤z#6DøÑÀŒò˜ş\ë"|vÈ$oÅ¸6p‰RèLã¼,A‡Kx‡9£[íì)*¹MßªÛ’a·–ws ­şDeŒsî—¦;:>§søÚ×rí¿`±2¤t4…Ø¿!¼l!g–p PĞmB‰N‘Ÿƒ7¥‘«×¼<Ö?8U²/]ÿíÅ$tØ‰/¿iK‘%«jÜàõ²é´LC7Á<Jl!‚HçÎ!ß¥¨•¿™d	Ø¸K– *•ãø‘İ<"â™/,ÇKs"V—cDıÎ¨ ÙĞuú¥ÄN¸Œiw•R’«ÕĞ”³Hã¶1ƒG?„z‡Aµ4§í'>YQğíğÉ.Ş8¹>Ñ¦ÁnƒZ@0ñİm;ĞXü4[v'ÿ‹äKƒ£G
Ş¿# ÜÃG2¥:g¥©Ûg›ß¿É#Ø·•UÒxÉ„fô·iDzË"<Bï&ÃéDıé¿ÁR	›åÊJÆU]ú•P+o¡æk5âŠ ‡ùËqÊÅ)s½Ë¡ÜoÚ)ÕBÅJÉ¤Ì{P×"¬;€§~CÅÏ»µâ]—ª­^<Õ0OsõúŠbs´^¬²CÚN#º·úq¥åk=‰Ì¦Éë^EúO{xwÈ½EqUÔ&Ò÷®º¨W©Q#Ño·‚ˆ›-™_yhË}¤˜®¬ëı£ù™ŸŒá†=|nÃWŠ©IöµÍÉjœwdİNò-Å.Ö¶Y<>ŸøñC:ğª!*Äö¹æ™ÏÂ.³CJ×\‰S®À``Ò¿SÜkÕO Õ"ÒÕf²Â|Ñ=ç²I{Sãù½ş˜p•Òj]‰·ŠD¿ÚVªX~üÖû9ŒˆØ¬¦ÏÍ&1ŒnÜZdo4^k›ø½D<·m­ßá[Ğ2²ÙnvØ²P)QÜˆ8d»‘¶fôôX	µs®ÁşºâÆ°<¿’À¼Õ:ãÕfşú Fc–>+ŞJ¤—{Í‡»²èoD£ƒâS{^¹o'î–#ÌƒêÿîcšÃPÑÀ²	äy–^ÕÑ`ƒ¥øLÑ«HÓ4…È«G$	i/L•¡'õİdN¸ôúw&şûã,!ƒï§7mK!ÿ»«
dV*rNĞÀKvh§Md{×ÙQêçíÿEZ_îoÙÏšÕÚ`eİ%é„¡:Y`2ÖªKwšú>„IË >Vpç†0#„ ÉhßıÕİÖ¥nq´ê7púZméêòÌ³÷•VÅ¡{ƒ(—87l‰æ#®ûht	^õAƒ:.dÍ¬5ºnDp”Áñéò|œ‹0¿TÌøÙIPÒñ=Ğ[3”»ğ•]Ğ—Ò=Ã¹úµÆ±Ú-ŞÃ·9PAA ÚÓ"É[W¿¨õv+¿ºÓ*¤RÚ³VË·«Oo SGÓ;)×šQbø0&.r@Dz60òÜ´ àÍF$×ºJµz‘nHÂƒğÄ´È=±º~Ã` ün¢Ğğıl}ã/İ$]EY·!°øy]Y?4øqvö°Î×œ>}úù¹½İ€Ş‚íà”¤§Ï_œš®P= 1–İ3¥;ú&düZ"C9¤ıC	¡VV&ôÓ’MWä§éÃ¸X°T<DXe'ØC1iw¤Sèãø—.pÂç”¨]>]I…>Ã£Ó©'}µ	ér1¯·)xÒ,·WÖt,hnÿğğˆëìË“ü™;>K£F—é†çåcè—Ø1k;gh¨¼h;gĞ5•¤ª:uÖ^0"z‡ç€é‰ÔNA´äJbİZÛ[Ùwû`ÒÅè€$"‰¢¦}:W·§L£:ïÕ×³Øyf”VªCìƒĞ©Ô¡á	±uXƒşdİÓ2ÚTğÌ¨	…]|ß."ÃUÏK<œ~ö²	q±_à"aÛú)hè]BÎ1˜êºÜ~Ëş‡Ï$…+RuPı Ü¬½ÚÕ+¥ÀÙ×s•ètFÌıïçdè,\o~¾‰¡åÂÄ1DÔ¦NeÕn“‡x¥»z+Üoˆ«7rT0úXr™×æ
àáÊÙy;õ éù1Ø29UÁ6:‰(`}ÌıõĞ‹÷ÂB|Ãˆ“`âàˆzš‘š˜såh.±á¼%qMOq7x}	ùöE E+]–ÖÖÍ¸}¯X,üµétß‡´"“v1Òzü»¢rÃ®ãÒƒm€Ï˜ t?¼öÏÌ¹'D(¦åÂqïå)´Ş›ãA’'CA§Mò‹TÂÎ-,ßëÌ%Wó/^“®$âo¯Î«Èñ¤ÁpÜñç#‡!ûsõÚÑò–Îö%ÍPñb7m,âÏ2b`ap>;;*ÆKøŸ åÂê4i<Üj5¯ˆ•
Ùe˜]>²ÔÀÊö	dlÈ8v=Kz}¥lÙc±’êÚN†ƒ¼’ğ²‹ŞÖƒŞ—pû{ÖÓ„ØìşXRPÁR“ªLÙç=”M\×›æÒ °¼0î‹åÎ@JÔG.WÖnï+ßSmÒ"qİ‹èğmë°K¿&_f{°ĞNfïá@ ‘h¶MÚ£Éyk8ôÚšöıbĞäµˆYôš’æ•§LK©°ßSEJG@¡
˜£3*¡»/®Q¤b ÓÚÈu˜C”SxÈQ7aLğJUZ^ ú™#‚â"şz”-S34îïëZ«V!ÙIZp#A®šŸA3äÒ³yèIŸ)~õ…Ÿ;äöÂœ^­´V½\ºùã½‡õ³tù``ôÖ¥±‚–‹rW®Ÿz´2ãç qˆ¦ú¦¢/,ÔâèÖmë‰¹ø9@v>€	m.+>!Uf^æ% d4lØŸk5ÔŠZ"XĞ”*V<Õ¢\B£ù„hMvJb÷âœ§£*»mpxs¤<úQ:e¸c%J×Â3×ım±³TÄ[¢m¾s´m5Ø†I´=ìäÃGº˜UVkn5ºÑq‘ñ)¨2nfÂÜÕ¹½ºŠ~î®sS1=¨D»÷•§4<=Ï/¹2Î¨Ôu şv×$ÖK‚ërB6İŒßÈ:’ñØò¤&÷ÛqıİeÊª”9bßü»¿h\A… 3`œ,&³çãœ ÄwXaµ€*2ó™.G¶‚öÕÙ8çÊÉPO2µ“ã Y¦`G’EJ\A£ge1âJ
a šŒjÙ:=ƒl µÈ¢ g6zku‰}íÖ:§Ÿ”ÔĞ$&™BŞî=Â['Ô’H¶Î8ŸIDƒÑ§wåúZ•´OGîÌF9V¤&*…b)œ^Ëéùº4Lp³ĞŞÉ°®¦ô'„ÿÍ=›
Có4=mµ7"ù‹È Vßq²qVòí‰½8Vww¤ï)Ö«]<jóh¶ıê¾ÑFFà2_hë©Œ±9\ŒbˆVÒ'ØİïOùÀÓ~ÙuèÔ§
>s{wL‚I*òœ«ÚÛ©†³è‚]f…o
ŸÑüvDÏfc ÷Â8ª³ÛÛ(l)ëÕÏ· uşC£ªvfî\ÿ³w~â–¾ı¢³ïÂèáóĞ‡˜J5pvü>¡SÉåÁœvosï4–
Ü Hù•
j+5ê¸¦Á`¢«ßy/GC¹({şÁ.´Ç.‚Ì¶_îâ†^ô»©íÄ†Æú*?-(Sœ¥–åYáÏ5$`,Ä1!Më«ìµËK@fpıÚwëÕ=ÛVî[¥¨_Ø@”˜Y*6\á•L!y°ÌIÄ,É¼Ø^9áPdVä$ûà§”áöŠ‚9‘Â÷Ê¬Š	–'Ã°*A¦‡Bã®B‹#×dÌjz¼'³RÎ1Ï’0}™ğÆqJ“ÑlîzAßgl
3ÓÓÇ’:b8ô»¢
\ü‰_ÏïÔ,„ÒÌó_Ê£Ùlºú*V4Óì27Vsâzìÿk5±’ã-²ïLeCsx‹1æìP<Ké}ãñu,î9\#}×¼oñhy’9&ÄZæ7û–-µs ›g—ïÁ+_¥G½êó£´Ì!Mü‰âê
¬¤,h‚!—´O(òÓ§øB&»¼ƒh7]À $}ÁPíKW¼Šº{ÕBÀ"£‡öä¸½›™N¼ñÕ¶ü­•`"ø€WaßG“˜”ûîº‚9A’p^@±˜àÁr,¾éF½§+îWŠuÂ2Ûö£.|÷úVe„zØ¾èl«ÏwÕÀôòªNË£Ğ6&¢İJB-Kı™:å­|áØgö”	’v|.ÏbVzRJ'Òdt•ü}’·Eé»{ö3³Ü:»Å8u~l‹Tó)›‡E.‘â§¹»»p™c}:Û%.0;İˆç™å‰ÈIœîà~˜×ˆÎe±µ¶W=qáX¢Ìxj?çª‡˜VîfÁ!‹;Dø„A‘ÈåÒüFâ®)õĞà½ÓÍÄP@›x9ğm€ß£9ŠÊB>ì¯çØÄ†Ÿ ñ¦ÎOgÜÙÂØ§  kAO¹ëÑ] “µ€À\	—Œ±Ägû    YZ