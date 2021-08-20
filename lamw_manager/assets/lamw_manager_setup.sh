#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4209186877"
MD5="f6b0ef291422c06af850dbf72474f35f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23564"
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
	echo Date of packaging: Fri Aug 20 04:17:08 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[Ë] ¼}•À1Dd]‡Á›PætİDöaqÿµÿ‰-¥¾oİ—M V‡)ŸõI'±9Û™·nJ”öš e~İØ±ÙLï=t”*~¦n„$TìöIrÒT¿kàg·7PÑ÷¼ó€äàŠŠ‰¾º
C²Œßq'W§—H¦J0£7sÔ-¹œÊ×PH;|j8İ¥/Õä‚ Öñÿ&;Ş”Ou8¥¹ĞCY{’É%ÈêKù¿ú’s2š_sB†İƒŞè[¼E([Îãòª‚îĞ2B•»¯%Öá>¡åªN±¥u)ü¡D™ÕÆŠ0‚åØ8\1q$Æ‹´`´ãÒîk…¡zí¿\â š—Ö›fGÙ5wÕ²‘EphÈõ¢Ğ-,€Êä6p	²Ô+çj9ÅJ¹`aµ˜½ˆ?S†ÁjõO7lÒbó }q{™Æ§["ÉÚÖ|>ÊíÃyƒùÈï¹09×qïf†zåß8ÌåCáì·ŞÃ’&w>ted}ÆKÆ¯¯¥œ”Ïá*âd:Û£pèÆê¥ƒNéª(Œë-˜Ğ[m—TgƒPŸš#’°õºÅ¼aöì^ù½ıS6EÛÛáõ‡¹š}­¯¾lèJ%Õ^:GâC¬yLÚ!èU!²vñ§:Êâ–3 ¾/ÑW¦4“U™†¹àYÀ¶ä4xDÀçø…©×p«İË›¡¹@X%QIî…d=9½^\ŒKpÙ÷©xmt„BÀ4}:@'Œ3‘ÃÿXµìxbS¬¡m´Mk¦©#ğ¢DFésô2$~£ùàY
û—‚ã¢­Œªv#…½¹uÕE}JĞÑ{$yê…ö&§ö¥u]ÃfæÀÎí>¯® µ¥u;ÇJİ€=U÷`OõéRMMe¹|€Éã·2ÿ˜'ªİT¶S	-Ys^ÍÑş·0î4sòZİ€¾Ò|E¶³®\çÉÔf³(xìÿÂ…†O-ØGxú‘UàÒúJª‰G"ŠÒU
a3\æ@Ç#MÂÔ¤ƒËX:Íî\UXLì:_LÇáQ˜lp_hà¤6y1sÇíáC*§ãdåG—ŠÎ1‚÷hÖÕÎ>½!‰=Ïº,¯šş†Íj]œ&=ƒ\BÜ¨6oˆïÃ¤vÁ‚|jÜÎµsùç¿CwèFêá°’8^Çá£ê½Í	Û/Ä×Ë¿Æœ¡‚[!#‹Î–¨«)ÆDBÍ0CS±ñèëñÃ13‘•nõ|pÚnæCÄ¾º |ƒåäÃîïEnîÊş™`şöå^’qJu•Ÿ^ ¾,“‰Ÿ–=c¡¿ìlêlKÎ±İ,TĞp‰D&Jyòïnµ2­lHó¹«eˆ¢©­¸hˆUş8>†…,N
~)‡¬ÑÊy9İ\JEÛğı7¸¯wyÓŸH[§ÒR[éƒDÿ‡	Ö\ã™k…Ø²'œZÅUbˆó%û2Äàİ?æÂßšrÛ"1|5ñæcÆ!«Z||â ÿŞ"¹À:ÄŞ¥Ä|SVõ´aï$_a´f%¥$Øàğ©ê¾)“Ìsô\mQ_\·TQ|÷3ƒµâ_å|ëy²›ÁÙ¼-Å¤Ø Z¾â˜Òú‰ß~_†¹V“áì’ïÀô6ÌÌİÚuZf íwS7©ÈÒÏÉ=éa‰œ-}ÕÂŒåÉÿ¡u‰sÿäšT„¶CB(A¸¬I)*­åº…ğ;¡ÅØšcHæÚĞp‡İè-ùĞ³n4§Ä¹5¦„É˜pÒŸÇ0‰’áğ?è±e÷°â<ï}3TÔ@öª:)ïñs—Üöéó^2²Ÿnœt®¿8ÖÍÓÜ®·[#«I>–[FBì{z¼l×LäŠ£#÷ï4ÂQ,X,âôÀ$ƒa¯÷‡ù€›²"…-Rfô‘ÜŸçRÃ‚7‘öXˆñ(WŠPèÅåÔ*+r¿
ën%NƒÒC >ØElLÃ& íU%"-…ƒ§®ü'9¹èõÚ}	ôÅ©%RMÆŞµD1wc'Òæ³¥M‡Y$]ÚU øùÎ´‘:|ªB
ÆÂ­‘s(Vñ¬ÁLF÷Òµ^©Ô­œÃljĞv’W-ÄP9Éã}½v·cí;q(k\‘dÄ”T¼èeŠ¢•Ç}ı°ïrôÎÃü4ÅÙáÆñITFŠpPíYu©j·p-Ôœ†Æe9ÉŸì†ôG(an±ûÿşm7Ç“ù·§q *Ô£]´ÁpYTÂÓÊ±À|…£7‚+¢/5öà¢‚¾×ˆ °Ÿo,›Ok1
å8àó¨§Hm7ìÈ;<Ù¹Èë=„p!Í¦ëªe¾íãrÄ0‹—ÓYooa]
ßx½[ÀX©‘)XÓ…+ízZ36Â\nq¹o†V¯÷co{¹İ1µ6-Ó<,!^]]QZÅƒ7ï¶®ÃÚXƒ¦&\½ÈíïÛêúúí_®Ôëc“ıpT!â—'õP#â‡²L.í)Ï&ÕM{Xx‚‡äŠ3;İßœ;r5u–`ÙHœqŸh…ˆ²ZÖZHM8˜ Poû×?„I¸µtüßE©‡¦wR·¡z`ds±³Ğµ,HyIëüÌdyêÀXd/¿„t
¦‚…Ãg+JAß&e7`ôÛó(LÇÔo'@¯Zû),õÆTY=j‘¹ŠÛÕJ07}QÏH°í9¬VÁÑ4Zå!X´-Ó R[/+°Ä>´ZİŠèE‰iOä;Íç'ìŠèoCí=4Ë¡>üeZÆûĞØìŸ$wˆ}PÔÊˆÛ¡çBÀòW/ÒX}UBœ¤ŸË.Î”œ3WI¶ó{$1Oò r‚ñ£a>n–1 7ú1lì7ÅÀ”C)|a}âí²¼¶½>×³YTë§>7Óõõˆ ó¶>ÇóÌx šÂ$"Ù&z>ÓæS5¤Ù½§üc|ÜÖò}Üiï3æ‰Š]—åæÍf@¦§çh&¸$â¿t…ü"ãvPsĞˆ
İñÎrÃ¡ğ–EÓr~$O—Â1ôŸ0_bÈ¯6(V9‹ªgŒ;çè2a×ŒZ3ŸÁõ¹w{}Uß=„ÎÌQ´U(ªñ.JÅ«ˆX´èBu…|ôxšIÁ"€ïj®¦7f‚Zş‘ñÄfÜşR pÜ_¹ä6•§­I?f"GvDOj¨JÎ…3‚CÍ1}³€o(©IHrŞöóOİüwÊ şz$âæ\Æ^×§u´â1çÍ¨e?€sp;íç½µq¥¯k™¾…êå,cßÙÒ6ğÍeç¼™:çRó]z*ÎØìíTËÆõ~~L°‰î€ÃŸ¡¡ò&ÑÌ)xè0$æ²ÒŒ6.³Ø®ˆlŠz gı1õÏ]ÙÀü–÷ÍŸK$ÎÆCÑ‹R{—Qƒ¶¸ÆDöÚ·øVŸjé¬û¨]jd¹QÔ<wp–ÊÇvC©&ó/îÄ­)î2|9û³Ü&jf%Ïù ¶”¥ä”µÔ1NP•µ© å~ñÔº'}92 ¥ÀD]‡ù§Î`Kúİo®&¤¨6c…±:1|W"i®\ë‚n7»Ã'š…ç‚ı`ÕĞ†¯ÕLZÊX¬ç}iç¶§nr§·òp›;£MpÒâjO\–«iUæ8±¦Îğ*¦ÖŸ¯d$OŞ§5}fÅCô@ŸÁÇ®6d¥pøK>UMØ™Şlu”,b‰^¸Á©Eù‡EI¸/fx¤€vñÏÀ%øQÂ5[xÏé¥”gŠ>w³´ü>A3ŸürmN*}ÆÇÆÏš—VN£÷ÎÕ±Ååo)»»&@Jê0k°¦i
9ï^ğ.ô/~|×.Ö&£û¾‘JZ&Ù{7;øøæ—¹”w3€ª©w£‹xVÖ0`’˜¼}40=ÿÉ¾F³^0¤b²Äšd¾H•áŠš9Ñ`\m^o…]¶çœò­œÕŸÛ¦Yéºcö±{îTÙöpcñ9œ¡f9@Àu–^kJX`œyv¸ôî¾âL$~e•„ÀÜ…]oúÈ¦rÒ1¬]%Ï¨—*)œN(7ßàÌ€…m!ê
Öjÿ$s¿Ê4”¶û¡¸°øw(¢¡»fÉÚ»l'=µ &/¾\·",-œ¯M€ûŸ¸S\D…{v«UÅÊÅ,%]—Ïakì¯BÉ`cÛğI¡¨Ã­MñVKƒœË5[‡ÀÒìlíßœº2¸*â¯=‘DdÙu·†
VbC—bGµFç1EùñæéI‚ÑÒ¨czÎØËÛÏ`rÅ¿Rô…+~ØïVÕ^ÚƒŠÁ¬˜)ÂÏ½é¼&Pg…o`_¸Ìã†½ z0ö[A°g¨ÈœÏ .:jäcŞÍ×0¡­öØ.î@­n‡2Sy–=J³¢ÄÎ)ÃkIö»¢­‘ØR2hA»¸²IŠ£º¸C wd[ØÛÜ)ËŠn-ö„¸Úë‰Hvï¡²•ÿÉÕ‘ŞD˜EEs˜f!røK†Õú\l5qº ¸=Vn/ôüãñ@>æá”1ß:?#İÄ}5œ&4¹µë(EÔî.Z˜{ö2%ò654Æ!Ê0ŞR8ŞTæU/´©‹YA(ACKşôì™~µô9g[ùE5ÛğÈ@¿ÿ—*Ov<=J’ÒCŞOí[dµ—ï‹Òá€X¨^î1ß'-áqŸDä` õ^)sœ|9'JÉ}€wÄ¥(1ŠVí¸RTamÉ¨¯ÿ“ÕYéH^àg±fïßCb&=}ç9ëaXb]›ƒÄâÇ‡ÏB`¹ûÔ´«Ÿr%ä¸^‰³ĞùbÕnêš[ëÓ×êqgık9ÒÑæ»)pVšWØwúÀ÷|İ&)ª¿³À|t»Y?%3î‘º¡ÜÚ^j9³¡ğié>û‹=âËvOÏg_ûĞ¾Gâf–Ôà$Ò")}€²…§ã¶¹9OÄÚK·\.mdDnRZŞ‚8±ğêË—ÁlİSŒùêßH; „òhwS­çËN{"Óãhq¾ŸFrû*È•¶¶ŠA)³³€ºŠã¶nF.tÍ\ü5 Ö‹†o®aõh+À}·ğSÏÙsÖ¬nK©oÒÆ˜_S°öœãMh“ïrCâŠÚÖ	jW	'Í*å»—2ß{¿P½ÿã¤ó°Œ¶‰¶ßóÆ€}ıµVìx‚(i¿`r[9¬¸üúY…}“¥İÖ@-E7tÖyœ#=IßvÏIñŞºÅ'%æ; ğÆ•®H|P5ÊJ3JTº8íÙn’ÔbàŠ	„±ÒiQ¨ï=n™6oÒÉYt¦´‘ÁÕÎo8v€cğË(_óÒÿ¸òÍˆRĞ¿©¨]-õ{?å”€ÚãÓê±C\şJUhò*//F¶T)B@±—•ª­7ßìq€ I[;ë«ÙJê2 8>+°íUİÔÆ©ò“Â¦IàeBÅÙ”WŒ_Şóó™óÃìÊ|á*$¹k•ÏâÓ¡¯¹nÿ¹Í0æ¯º"¯İµ\û«í3)‡V—u$hQî&¾g1\§öçÃ”xË£VóSAÎ¨ë^ulËÏÁwÇ·#¸ìí5ÍËÏ'a"±‰#ªš£İŸfî´,?væ¨fä´®ê‘?½Hüô ß²Ÿy×Á*­€Hnµ6›ÏØv¿úŸò*w `ééğ‚ÇĞ¿R&±ŠìXºÁß ­Ğy›{éì;å"Ó™eª©ÛR_	GÌ/yYÎbÄ¬Œ†X"ûgœi’@<ÂáS­ô¹ğ¨”g|Ô½6ó¹İj˜Ğ®Ş)ú*NYJãÁzlImÉ¨şÎ/VÅp}õÍÆ>»dœ€Á&˜­éÈÈ
º?®+ø¼1uIÎğlÎ+B²Ò„‹ğÌK–øMåûåJö$$¬E_zˆ»À.—#·ÉÈF†’z#ıùÍ~nã –­av<™ Ô`,<|;ó-ÈR°¤ÓÇŸğd^ÇyïhEíbNf6UŸL©´~‡:÷ _ùÌİ0¸	(ukyŞµcİÑĞÙ?ZÀ°¡gh'w¶r÷[6“Û»*½–XM¯‘Í-Zíï˜ãò’ò´;‘ááäo|ïÖG7£z]ÒZÄÉœä¢ CHõ7ß',ŞÊ*¦QdÑbÒ!¦ªN¸”öBDö\–£I/v¤å÷„¼İ¦jƒ«Qš¾+"3Ïûñ-<Œ1—ÄÉ·µ¼û?»±;eB‘e²5@©Z^<eğÀu›hŠ)ªêO#¶ú^Ép+aã&JN~}_$_;ŸŠ!.¶â\{é@(fH%‰í*")7\‚²v+Ù€‰,õ\É7›‚D	Uí.$³§‚ú$	ô÷K|¡_)%İ2t÷~NáTN–iJöøNGÊN¤Ğ~*:D¨9{ ÎşRè^—‰Ö”ˆì%˜d$Ñ^ìumC`×­årŠYt²Ç@%¶ì†(¡†”OEıó°³r<<®W.ê¨À‘Sßi;ic¨œƒy!-tÉâ–ly%ï3¹i«ğ]=5ÀÂñ‘@4qôZ2.)ıíÌN$… o£\™¤37³$EÛ¬Dü3ü­ä¿¬Y‰çåÉŒ¢¿1-çN>N%n²(Ç¼JatíÎOhß†äÍ]]Gš´|µÌâŸnQ.+‰‚£S§=ÀZlä3°Ï"«T»GÙb"Áâ]ĞkĞÂL¯È,,qş©­U„_¨}‹âê,Å^,ïñr?ßì4ï@
[µqn­¤dÒx>.†B¹!Cşiœ4™·=:(˜Vá0çÈ°_«c¾u+DéMM´?] ¿"ø$¥P$ğí˜”Ş’Ø¬-&mÜxpÏPuÿJF†``3ı¼ô
Éúı™Z3›çÖ–p™]n£‘¾*
|. ,Qv¿^@¿Ö<lâ±Î£7§¤ğu›;n)/·¯ñC™¥Å¯v×5ì(qÕ™Ä!oÍëÙ,Ó]8¨ÒÀÇŸum¸÷Å^ñƒÊº<¯ùÅ¡ÁÁ×ŞÎî˜àmgè™¯»KƒöN¾!ôG•sî+dğéÚü¼¾Ÿ)ÀÀìÁ˜j0§…Itx…í¯8nÅì‹3d«¤JâR¥é1û(˜½?¹òuå½×­¸¨Ş°Xæ`ÿø¡7Qù/•ÅÒ¯ÙóïÆEæª“Ô ş¼b–/œmjÒQTÍSn° b}ÑÂñJÙ®C¸
‰È|°Cì)b7)ÉÀld,áìÊrL›p¹]NA5‡¢Å1>)Ş­B/–]€ĞÏ¸PàfJ€zÖÕƒ´!I†‡»´„B÷õêN'0(UúÏ	Ã†:ùÿõÌ2hô¢şÿ$ˆL2™hû4)ÕcáÖà?H<FĞ?­ÎîFó ã¼nâÓ»OÎ%V!\ÀGM»Ã›æXA’âå)ĞîUâğŠÉñ½cBáÔğğ}°IÒ°bdC #ÊJan_€÷Ş§€‡ÁR‚…_Ää>X™ Õ¢¯j{-wïºwÇeìŸçŸV)Åj¿èæ…yäa|%Ï#8À™9¦†´¨m¿x/‰<@LHR5¨dàWåR îƒÙ;åJ1í\ØÜY^’4‰eî1	®ÎõğÁy}•\.xbc½°ÇĞW‹Æ†bğl©Ø˜ÌÉrëè².AÍA£IÏGÑ™qÑ¨é½BÊwüÁøäÎU`¨¯dœ=‹ô*O\Sæ• ªÄ]ƒÌDz–1¯™È ’lü¹êõ[T´R@_6ä{%0§ÍpÌ©ort|ÊvÑóš±·ëïC–zCe¯	B<ëÙ Éğ4ôtûõQ¤èûµGtË<ª#õ9•š¼ËZGàûß%"CıÉr€Õ9÷Ç‰aã/¥Õ„c6Ş€İc:To“ƒµ^ßŸ¹·ø=,uğ%sòá‰Fğé^¾A(È¢º8o>©K{ÕàLDx-I|RR"Å±à(­B›µĞÉCz$7ìi4ÊQıÑ»!bñöÌ=Wî$İ2Ôıdù±	¿%F˜ú&ÜèçƒïPü0°:s¼ĞïnıqøÁ§¯/°®dN¼²Ùy3ŠıÏ$H²ãì\Uªƒ,à«,© '\@÷ËR}¶íƒnÈé]å+«ğæØŞğ†%h]tÈP5G,´éI¬<ÿ< ¨‰t2Æ3å”
˜Bë"°®òĞ

\Püƒ½3rwñVyJD[dælÎµ` û$}“LÄÁfk$„lÎ˜l89…¯Ê«uFdE	0·VñÏ_€Ö¢±Tş÷Û@í®›]Rôø”IÜî9=g½]z*Üõà¡™óZ/ÆF‘ŒÈŞıN…\€õôÄF}q¦i[§J×;}Í3ĞCûï$¡Šƒi4Ä—
ÊËz´SğßÂ÷1^wÑ–mÿ?ojá\âúEş[Ïnyëz´p˜/I£³–Tp!Ÿau¬é½ï$ôÿZ 2æ{è°GëòÇ€UËåZÈòÀt¡zt¼é#":F,'LÉ‘¶Â<®ÁÁAÈr©	L=€ûÇòå€ŞfÖ¶~ê6!ˆ×lê& ‰_Ë¦¯<+“YL¶8<Ó¢Õ÷.¾âzïOÇ2÷ƒÄ}£„«_Æ% H?•K'QÄ:UGÒ!j‘›&¦JfLL`}×#ÈhÙñ%Š}i]Dšw²aß|!k<z`xFÍı#¬V±]Ôb	¼âß#)øXcÃãß¤òìël;e[ctug5'ÑÏ‡:H¨ñ‘&_]:~ŞêÁ²G¸éÉm®2 Ù†Z2†ÇÁ #n®×úxOkÊö®¢•‡ôIı¥•“ÿ3/]éÔSèd‰9yz8Ç“ "õ(àÖæjƒ][¨šœ$Ü-F5¢(Æ3û¾ñ°šğàİâyU5	ã.¦‘Å¶w¾´Àë…¿»eAÔÔ}±œÏµ[İÙâßÚºƒèŠ«£º®½ÌK1Hm»íïÄ  ëbjìë a„ÜÑ¸•s«Š`,ÑÑ:/îˆMÖÖ€XKÚ7—†yÉFÈ*P2İ¯Á[ÛrÀ’7‚“Ña’É§ÔM™íÛú—ŒëKm‰Ä@'ÇÓÊø­<Ä®o„7İ ù@â™:mK‰.s˜³úÌ¾kPéÛ…œ¯^'‡ëMå²at|ç¢I^àõÚ#·jåõşfş\&¨Ÿ¹T{ÍV#Úâ¡É‹ö¶'“Û €c¢;ÍŸƒÃû¦îÔª§OH¿Î¤®v©‰wP{fEÁÔ_„#Óë`Å¦D}İR„¿Yæ‰ó>XIÛå|ÄJ‰À5_S¿sPãÙŞ6¶½Å®‹ª¶VK:,¥ªöé‡/Œ4¿8zøÑ¥ŒÒnÇa)‡ÿã4«å ıo*ÏÕ®ÛÅzÈ÷\ı–Õõ¹I Û¶Ğ+w?œ]
Ù÷ö¼„{Jq‚`ÑÁ‹ş2Èª’a?q÷Ë±va	ö²
¨2¿å=×Bõü3¹üötI]æ0¬nú0›Qf-GˆW\Ò(Âï ñCH‰K—ó/%Uº¦LŒ•¤ÀÓø;–s9(ËúÎ¢'kº‹	CI­	­_+>—¿Åø_×ŒÖg°µx^F7$ÃC-…€•*µ-œ­S¡×j|üÁÃ¦÷h1ù|úp%±úÑ•Û‚cL·*•°ØÃí§úÿéäàú ön¯ºò˜NDsÙõ+gC•–"#ÅÓ?
2GRÑ"h…ípÅ¿°.Ó	T"Ïåtáï”“¬ºŞÇ›æÀºl`rÇ'>¢1~'dÔ¬¯&§âµ7™¿ºvÚ$ ä¦s_Ìx£Î)ÍÏd=i°cÚ˜‚‡Fhì‡W±(¥K’…ÄˆÚ¹ù—¸í¦‡X IRDo‹ SAÏ¤ÄC<õó{–¥Hà9’>¶5hÉg‰âzªò~hãza õä¥†5Â(X1‹RÍ´ÑÖ7iƒ®Ãôé1{IR×à{ÒHé™ÚäötK§òSÂGÖÓÚv…j„Œ¸_•=Bôß“G&w~VÀÇĞj—àf}(/#‹•æ=„•?&`‰[D.Ï%÷Ç0Mˆ¡zùàó![5mıfçuô¸îŠäÁnüÔØlS3×9ñ$n´NwÃi²aVs^wy~\=Fª³ÄÏıoóü™ÀŞ#yà„…—õ~’şú˜>CÈº¬wb–©#/ı	ä‚(NÄÓÇı1ıa¤¸D(êJP É áÇºÛê”®_¿bS2§*Ösˆæ¹õ}2¥¬5•˜í&0	r­,á&hÕLƒ1ßükœ©Å"Kc‡½Z¥f,E33FÆ¥—¢­¸a£¤ËÍ«à×ğÃ!óys—0à¾´Œ’õ´Á—D'¶»ù¿FXmËÁÊ`ÜèÿÓs¤Wn‹LPw©bÅÍ;.Ê´Ñ{‘š|‰JR*¿L$/™€<Úß‹ËCñ9½<g!È‡ÿI5+F1mPîĞÄ„ÄGIÆÁ(W·^#”&= ÛVçak¼£Î+jïykyHkËjir×½–öÿ¢dBH·^é>ÏqXÁÒe±2©·Nx«ñ˜@œ Òa†#ÖA96‰‡+=ü'm
<ê.¨ò–)õ×Ÿj [ˆõ½wst‚C¼«}¿s[hN×ıxì\ ŞšÓL	)ÓğÜºjÒ1.O½
œZ6˜FsÒÎâÀß~HEi«Ò2¼skoŠ	ÛX5jÄø›ĞTÛÌãìu‚ğTÙ¨s/†8|2ğg'-<~”üÜˆgp×½ÏÍ>w¯Úƒˆ:Ëï«	Ì¥ßïş(ì5éúHõ¯³a›k½)Œá&zu?¾>ıãe¤œÓH“×éB:}¨Ğm!×h)[&0ì!f#´BÑ#õ—ÚÉ^¡?ûNöúic5GmWÄµÒ„è”Åº½Œ¶Îßä/ùğÍ†Åi™·´ˆ%ì*¿oº=Ò¬{ÚØf>™wï*Ú¥QFrC}L@AƒcòPÎâ¦«Ôc	ÍUCÙƒ2êÒ‘äø0OÊOÓl—î>’ÇvA C}0éœQÔ&¬¼ÿş1Ğş–e˜<-Ú•ÏMBÂ´2Dòˆç
«BÿI«B£ÊĞPæÎ.Å_À8/õ¢LVéèØs‹ÏhK1Ô­ç—]éü×{p.zÊaD¨piÒ0O;½5ä–‚\7cÄPL’Ò]ı'N©®”`ë¢`oÎñÒ£D±·ğI=-.9Û¡KZ˜†ÂVYO?a]7»kÇË©Û5¿¯æ=…WÄUYc•~£ˆqDF°[à4Û|~WÛqñIÙÆÚI\p™Ëˆ©
kİT Ì%ÀD‚{ÜPé2/eYr°™ö~Öá„«JÖI°xÖ·èé¸š@"íHĞQ8ÑŠ$¤ ‘bT‡¾Á6¥µ‹p'Kèä¶tqF<eUö#£.nêCÛ•GÕ¸¡Y·UÊİ4…GĞO>^›„Šè?95Ğ×˜U­:jÃàÀxYZ¬ªxî’ÚpÈh@7é_x&ûºrOX$¨ˆÒµÃ…µª¦]CèÊg>ŞİÄ*¯XÀ,}¿fÛßx—rêÜ6ğQôj‘7kâØ|Ç ÊéŞ8§¬_¹Ë	ïGdÉ.~¬Da06)¶‡¸:è·­ŒÈu€ ´ƒ„{…m¬6Ü%³èôN–ÍŒ·ÿ'ê4…dlvEöÀ.;Zñ1ÖÁ¤ËFò“‡$Šqª<«eƒ#-ø¥ ÆÂ~İÇÌÿ@ª”ñJØ{Wƒ€ÅE:Ã¤J5çßÄ‰êË ZÅæÁáé c9)T#øn™ø»¸ıÉ'ùÂù[(Ö’í¶F`Tª‚©EÏxıìÕq´Ã:öG¢›Ä›’§¨íF$ßÁÆÄğ!àã™Ò^ású+àâ0÷øãİ èhÕ‚èDf!ªÂM4H¬„‚ùÏÙÀ¦™l®#û«Acòä£„ *ìÁrÅ[”Q8İ’FÃ“òa®.Ãun‡­&˜…ô8?èV–›m¶v*¹8ñ¾J¹çhVr¥RäÂl~±‘Ÿ¸˜>ÏmRB×3ÙÂ•wâ‹´§ˆï6İax:Ã#C¥ßÜH¼$ªVù4ï=³×<»ÿrèƒo‡“˜
Æ2à ní2^X)¸ë{GÒ¢@¾¿—‹g’Æ(Àä‰´Ô=<Òû
v;Ó|ë#ÔR£ ³×å®›ŞU[’&á£{R•‹2³ İa±b ç¥ÂùÔçDÎ)?å…7ò¯ÉÔ+é¬»Ä"¬L2R9vEŞ:oRGMlÄCHvŠYÁY¤ÈƒBZ´f@ê.ƒw™[v´«RöıÅÖ‹ÄJ†Wí›XKçïL/™bY Š*Ã'ø%iï:}Xù]º +¡_‡	YFŠ°k·ï
kë^XóÀ 	Lxt=	PPh³ÍÇ	İ÷ñ¸<”}—5Ä	È2åÀ€01§ŒÊä~gú€öl–KE¼xá­†‚cPˆè®ï¬Øx6Ó:?p´&S­rèÛš:@Æ.E>Õ“°»Â‚‹ÜW]¯9wûÔz€’³QHDSTÉÙÛêv×¶²a/
zcoù
£İ‚m<€D"èã=ĞEs„èmF?1±Ô$‚ˆ‰\6Æzr2:,ÓjøÛKÿ¦“¹Û@e-ƒé`”¾–UFnR…İîn¢¾»{ ¢c_HÜõ]/>`½Æ~tùòs×>°6Eæ˜Eá×cİÍea.yP24Ò¾¢dıòÿœ#³öú§}oôu÷gœ„`ZËe kxh¿†˜6ßâ›€{œU»Y§<új¨Œh.šca‘b8.¯€ºpj¬pik² ƒdkìíívéØ>ÑŸ‹Ğ‡òu|I>\{Å–Á¸a@¹Z7™-#”¥ _»¿ëÁÍ6òâ*ÛàV¿¿[šürAËQB*‡á=‘î[ÉBğ| ïêéµË?1{²´5º¨Z¨úì~í®éJyWŸóÑ${Ã«ãŒÓz-Š…ÆéRËİÁ%òÜNÊ6ƒXL ª´ _Áy{T“åm/-éuúÉ2ñÁNÒŞS;Mä«ŞCmÕms¥ŒÛ+éÙQh]HK¯dJ-’ê#l >¡Eü°¯ñì
®y
¡}ˆÊÌÁ?§zŒà)–0Ñõ}3d¯ ç9Cc}l­èŞ`}ûZÊf,ì}‡7³ö½fB&‰ˆZ½NP6›Gˆ¿ÿ”›svá1œ;|~ÊBŸ0"#pqa¡n~ã€Gç7z9xÇz"K¨Åu)U¸ÆÆ7^¬ g£ƒ¨pfQš]ÅE>ÂŒ»U&Œı>XÙ.á>‡Ë
Î¦4Oíùı(=¸LÅ¢-I¡’
±Æ$©£Ñ¿©£´á$}ñx€Êw˜9şö¼<W¾€ÖÅ·RTvÕÙ¬IKy×J!å?-ö
Šııàºq¯¬"wÃ“Ä‰CÒÖÀ°- Î—£fhŸ‹	#‚§8Şİ˜gÎ»—×”»DŒÏX¶äıïáß‰¢7V_r•5Ë—ü•pßş®ÁEg!\7Šä‹™,¼'äÅ/ñÛĞà*…ÚÜÇÊ‰¬aìz<õ…Wr`ıUÂZLõ½K©{&{GéIK-s¶¡'øéQ ¾™ØA».É¹‰HxÎt³m&êÎ®ÕÑĞ•¿‰è§öø´×Ø ÷§r‹åAŒ®îf¯½Ã3’C(ÎiW93˜ZûÄˆówC‹´à°ÇÊZEöªy1_®«pªëòqÄÍš¨B ırÛ,/E›T÷©ëÂÙf|8º˜e-´lbğiÏtLêÙAÀŒ‘™;>EÜˆKQÒ%3S¡AG×¤¶b“‚ä¯M[õ]@3`l¯›R·|®Ìˆø(²¡Øá,8êØºsü"o‚Y‰¸şüÏ¬–9Ç+ËR:kµ>Âß'§ìm½Æc—ùÙe½†¤µ­!ÄCÕîxÊ­ÑO¦o—wÇM°2qµE·ÖÀ(:ŒªKYXæ§'‰óús|Œ’:PÒG•Øeı]0ÍĞ³“
ÂàTâe“ôéz—ØÏ¾Ş¾:?¢*İd$¦»ßš7­³©?DÖ $ghG#fjµåÔ%öœuF¦kÀ±`€MlfbÔ"Ğ´°(0Û¥92£®0_èéâÈ©†Ëæ‰5zå6tiwİ(këÍPı?ä„yQkùáï6ã¡ämeuöÁÌòéíõª9E™Àe);«^#3òÍ»0_éàAX¡«ã{Œ•<RU¬f¡Å
ro=ò à¬ã'O;M¾e¬F¤§XŠ_ıKuşóÛH(&áËÂşe»é©‹TÚ9hŞ9ï|¼%‚kœÖnË¸dÌ~¢‰öË%)o4æ—ƒ'P« =<Â˜	…6ï’ÓÙƒ—HĞ[š3—	·ÆÏOÚŸùÎ»$À¤ÿ]àFY*	á¤»XÌÍÒ’Xácà`ìgv†Ö|Ê©Á¤ã
uŠrâe#uEq®«‚–
ÎôŞ-Şb†!™yT2÷WñJ,Úè
¸FîcK/±ë{Ã¼mİèñğ8ş‹‘>*Ş|Q®kbe)ş~fìR\bÅ“áÆ²º[QÜ“qjÖ–Hÿé"Ñë²„w¼î{ ~Yğ8–ßC%ïe¼S±£ù‚†NlÍA‰Ö^‹óĞÖÄ-‡YÙÂnƒàW}v’	aÊ7nzµ¢dnÌ	ëìŒçÓCê×"†7Ë*‡oi²æê‚¡˜È äÛØùŞÖ¡™eOb¯£î–%}¼x’Oñ%{D8h’Ù!g¥øş'@ ·¸…~û'İÂª¤}Ó†…¬oÊQÛÉ°`ò‚¸vë4V¨lŠè!™Ùg¶rµ®÷V6ç¦«‰ağğ¶`İ®re+eÜï·rı×ôä§Oáİª³k†ô?#İçáö_ˆL>¡l‚”ü´¤f‡¡"3:øÔ—k,çvı)ş¾~&û†¤ m$¯jŸ%$˜j×Ş2P @7­á&£Ù8ÿ|—MæÅğ„Ê“$Yg#â·òµÇ°–òvù¹G­¢x'4ò©– ĞüoáÀ‘,ˆ<~5©®ñ¶,ë(}é€Iè
›Ò±Œ™ñ`uŠ¬:°W€½L	ˆQìÎÖÚw”ä—ƒ$µÒÃêâ®±6’xàşé9y&˜^|+ÚWÛvòâøšÛû¬›ÆÅ7äZÄÏ½câãræ}8|xâ>z˜j×ĞÁ»Ô½À®wä­\§œª_ÌO+á²®ªï»}¬„ù3ViÒõÏï«Œãº›³ƒôÕ÷d…·vÓs¤¡6’DñıõÙV9™Éù-è3p"¬§_ì`gMl£gW’´”œkw‘-`]g!wÿ—Úøe‡ôÒaÇ™l–çÛ  ğbß‘ä³Øk…÷Ñj'‰Ô’&Ùşò4#¯‘Ë&Ì+ß%Ş
>ãÊÆKKÀEÍT–‡Ş¬ê•d™ß"™Ê·1k¿BÆiòEú´I>1€;€:w3‚éÖ6È[ §)sÀOÃ×3ñù¯gjQà7`ì>CÚ¾pÎ‰´úïú¿ƒ~«Âj1è÷J«G[Óˆ*›ÇEŒÏz`uF	c‚~¥·ƒB!T#ËGÏÒa‡s3òÂk|AŠ‰[˜jv¸¼×aıë›D‰i+‘d-‰ÎE÷*8fA s÷¡¼¶@¢w©¨
İ@fCÎ£HnõEP¦dU¾™¥hâq»Ñ`åMË`ò²2…T²NwSR\r&VEísîå¼räÅƒŞTÿĞ‰Ö†/3xäc§Pëˆ°#FL¼©ÎPüõbÒ4÷{¾ÊÌ]Ë…B[Åf–·5‰¯|ş·¾^Î¥m¬^ÒpL¡ÔÿB>€ËÆ 9ç%1
Fæ`àĞüWÅ“§$t÷†a›ˆĞOìüÏà*•²S-¬ò˜IkÊÏ-441áy„Ò‘ÆÆ³}ëëëDOut9éoBl»aG¦²ÌÄÁÎ;Vz;¥g`q’BD×™ŸMËG)cì‚Øp“ñr+€X<ª‰¤«å]„ãÌØ8xÒzÉ4SùÄ%bişÎQ{§KqIé!ÂesëOHü¬m¯*õ—õNñg® \æÙ2Æhº‹éŞ2®,9®:Ã¸×c“‹?²šã&m^öwW~5ŞIçéTRÎİ@æA!YèG,ßll3éî·…Hîw¹Á…ªC¿±cƒËLûûQ™£Ùs‡ëUÑR¶yÎğóÈ2c¥lßÌØ°F›üí0_ìşHöv†Ó}ºã iıˆ÷°}†ÚèĞãh{cmqºkèü.ç~a!‘³œ‚’Usel¥FOL¨ffB3»ãâÏÓÂ-ÜÚ RFÀe/õ£c+v^ •¾/5êø‡ÏiaªÙ$¡™Ù’ŠJ5Sš¢¾“GÑm‘Lô´$±P­‰¦ÿ¼ç5Œk›${R7Ò5üx.a*`Ë¶ø7ç=œpš¤¤”"¯2÷J’ëñéhúĞÛããıwÚ{«.aÖDI>ò>È[ïª5çc·95ßø¡*¡„;ì0éùl$²Yäùn7ojÕl³jtúòN|v7DĞÿMí|AnÛ©Îs/};X'5ÙWĞT2,Oú™)qX©xÖ+&G¢cèØ+SãÄ¥›õ¢Ga+bÆ€ÌŒsÇE¨‡Ô ıSÒo_t!?ıÍ¯±ÙR¼ÒnsÓt"»#  ÏF {¶A…Ù6.çÄ†€+›„Å?CQ ¡o[ÌÂR@†½s`]ªÉû‡%`Ól—‡®–ïb:UÓ¼h÷Ğ(ƒaß,©aJ¾¹Qv­¡Ğ®BbÇûª†5kQîa­áX“ Á2ƒœîeQzZT¿ŞŞq2“‘ÿíˆ{¨F#ô%”¤éQfŠ?•iœ[…™kh¿Ö—âSt?ŸVMØÅiy^T7?@GÈ’ï1"j,§¥¿åÀ‰yˆÁvFNS`}3=˜Ùûşv +Á°7`cÿˆ.¼xĞ,=-Xät3bS&¸ı€j¢†\Uº“hÎî­€u)40-¸áü_u
1:û’@1OÏÜ©»jmC¤`V[ÈÏPÅYµ€Ò\†@¶ªPª ’´…"zÈxTÑµ¼=oM	¬h'ĞƒA\I8É¡î2d‘9)ò)sN1¶*&Hâ¢ëÓ‡u1ıWtÔ Z¼…VË GªLÌ¯^ñ'#¯=ÛºÕe’@ğéïF1MŞJ1cÜ	bø£%”?	Ş¢kzˆ~n€”â§ñşh^…Í,Œ¤ÇœÃ×¡æ'\JìAÎ†ª·Ğ\­Ã6éÀ»6ü‚S\LÍÜ(ƒÕ¤èù\Ö=¿›g}ˆjf¬¤z [6i=êi¤ÆUd)Êñoìİ:„¥4);ÆÍü€€¹ë-•³şvá€W	Ë1ƒ4(Ç¬:ê_Sß
ğ5sì°bGx;`uåäËü`µÕ©£B˜îX¼?t¨ÛÌO=ûé¨A¿è%¶:Z©ç“¾Œ:æ	F9}O3'Y(úÒCd¿Añ¡”!²“EÆ¬zÂ­¤„RUİı—»Ü°Â—qùğçm±¨£|ñ×Ä6t mN£ğÈ†É¤-)Ú00 ‘,¹µ}s^F¡úOô×·F<‰ /ÿipA÷4ÜT¿@Ç-6AKü1½»°8Õì¾lí•iäŸÉáŸiƒ„ÊĞÙ¨¸¿.‘tƒÕvbÈ„ @¾ƒé@’ñ×
ËL’—…GÍèãPğ·2–(Ïí&İuÀf	Û QË‚4
'3‹o*Gp5Š¨ˆÚ|p=ê—û¹ÀOÊcßf¡ò$gªN	3*²è…m³«m@ó $rğB´ÂM×æÉµSÒÅ¿ÚxI~öÊw2Kyˆ‘Çöw/­ÛW%şÜw¦ş¸!ÕjÔàY0|÷Úméı… ‡b%Df>+!GiX0“{Í[¼ ¸§ª%L)j”ŞÕÇZ¶8ÅZƒkip§k_å„…Âª²Ç³8´İóâ³©ŠN». "€ÛĞ¹uß¨Bä¨H™,™‹k©|ëìŞ±#âÃ®xşöË%ìÏRÎ:XµöAír£nVíN´«	­¯×*å”lÇí2O3„ª©Š²‹NÍäJ…>s_ßŒr÷€Æ¬-'d±ß‰u_YäËh£Ğö‹íí*&z[É?U¾GL­‚š¾\>Ä°Üñ4hùĞÍ$
±şMF*B]8Îf&³æÌ~Ñ_J‘c­kê²n´Êáiñ/bÏ(QœÍˆ-9™G°ÇØe
Ş"#íZ¡ÅéÌEÙ{çœÚ<à_Ÿaèá¾ EèÑ$9SÌdéÑ	Áõªì]¡ÆD2şúO°cşvÑŸpgœHÓ'|Y³3<¹*•u„ÒW­iæØœ|É‘ÜtĞÄ˜ƒÄ¤‚~‚ä
`6ÏÆÙa©Ì¢õ¸Ò,¶n‘•õv6	R.ÇC Á5Dšò,~œ)j*ÿaÂ¢9æÀ1C_/´dº6Y($æõ5Ÿ¯djğŒ÷>µœ™ãÜqA˜Ø +´‹#,q¬íöQ­º
Ò»*&ò{reÉô‰¯ µ$—bÛÑüÃÜ"Ç¥¬•AJ¥=æÔ$YÉÛäO³]Ÿ¾3EÁ!-³‚Q`M¨ØÔ‚–ƒ–!zªåÙ€Í¡8~ªP>ÀºbZ‚jÖèuG€›	'­™¼oÀ_€a.ôÏ!ìÇP£¸³+qİı.”ˆ6t¤ÀM@¶8³ŞııATÒ¶é¹ÿ”	áº:TôÒœîQèğ…‹MŞ/g­å`wãYôÅ[2ı©fŸ‹wQ_${aW6+˜ò·»l÷‘ä9:Ç@6¹\ÀØ=ü1µTV$ú¼ËãøBgND‘2Ñ{®Uõ–ù|s™÷•ô«£yÂN}ÿ1ò)›)ëu:([·Ù!ß“ádü&°š+EÌĞB‹hğ¾n~²êİÂ)!mg·ñÇf’ª×A£eùæğàîÀ0¸ÉV@ø#rÁ†ÍQÊGTü;XƒNŒ+îg:¯ÊÈª_@Xæ`h×÷pGÍ‰Ä½Í¦&ô‚K\ò8_×å›†hÍ—Å9–£pÏ/|Û¿ŒâB8—"h¤¹hÛ5Î)•ÄŠİŒÜKŠ†û9Läi±ZT+lájNÕ´èU¬à^Æ&r)VŞ~›l43¶`İâ°×«Â  µ´TR_Å¯ÍZ¿yğoÕÑ	ìm¾ã-ûàå 6|Ôæu1Â0gWhĞ kt‹°|òz¤ÓmrB>ï×Yµ…Iç S¶Ã‰´rÌ¯NÀQªŒ'w	2TJ—±ÒZCñ†*¸·únå@²!x¯T§¯ë®¯É3m7]	‰VÕÄË«íº‘±]ïXwbàQœ*¬$y¦N–YÌŒ
êu\y{¶‚¥ç³J±µbionŸ¦Gifo¿‡s¶³Ã~Ú¶PÀ¥-¾i‹‹›=5(Œ ;ˆA­Æ .¿M‚¥ğs–j:²3HºNT£
 	WwªyU§
A?ªIK°åâ#èã^ërìÚk¼G¶y çı:ì(Cü“ÎŠñç·3+>¨>ñvd’e“íOòInæÔœf¹Z–W:—#K¡FÑ¼ÑP>EÚw¶—Ê6$7¨Úİ%ì~Byë.Á#Gøå‚İ]ì“•ò²ã«7*‘ÃÖ3Uz¯VZ§víÀ{c2ë¬SrÅÿÅW4id-Âíù¨­mX»³ˆÁNöi3×N3ı•aûE{¯	7/.º0ÔQŒ©|-¤Ê5aC¾ ™Ö”Ø08„íO¿ê%Í=œRÀ4”ÊZ0÷î€
éDÕhÓšÌªRÀë‚6çóª™¸;bx"¢*óå)ÀÕ|8…}ØÒ‘q‡A] ±-‘`s§¤İ²©bd?‹³Î'±|ÇÅÕOÑÊ/’ûÃ48·‘¡ÂSi"SÃ.ÊÄÂˆÙ~3	Axjg1%ø6#îºX¸¸Ò×©Ì#uF¬Nç«^Š}¾D«"çªÅ/,®^¼»ä:ÛrGÔ=WR­K±-Ö«Ø_ÒÈî<ÊVu˜ü³1¾RNñG}\ùõ³Â;æ×øğû©tº`Dë Ç<ûyßó*ı;Ör€ã¤­!E³§`ÃÁƒã—ß6í«¾©PzªÍå^®`f¬‡QÍ¢yş§æ2´¢ÿ¨×.%,sÃ‹Ø(·³w€~5X‹ìùÉ?µˆÀº´ªÊ…ìøP+nT´±JZ"Ó‰h¬‘ö·íŠcBJğ
LÑ"Ì
ß‹Ô¹–[UØ}•Ğùçµ¿w”r|Ù|œÁwûúšiKßG§2¤:jXŒQ»cYİ|ó*şK¿A¦Ñì;jı[ØSªBÌæ/¾İ±o×3æ2nÏí-ü=D
‡(¹ÄïIƒpİn=”Ğ3s·²5L·æÓ‡’×ÂõŞ«Ï:Ë{P£ËÄº_r¿^õ‰¯d/S-¨Ø {›åŠ'|ëÀ€uıè-PàçÄÓÔyÈÇÊ³Ì­ØÑó¬$^~Å>&ÊB*rÅ©hİjÔ:LİğñK9l=$7üò¬• Qc9ÊĞÖZ(Š•
è÷IÈØ³­“!—fßÓ¼^nzkİ‹~,´Î#“Nbi\XVé€óJ“¹µ—Æ4<‰eMît¢9î¡¨…#2~µn1Ü¶{ĞºÀ; Ë™M=ß53g`Å£}ÇQ…E‡]Àú‹’ôÊçchmbp[Z¡ÏËE	À/9Ë›ü<^õËœ±İ,9ï–ø6UÒ ÔÇYZ¤	6H‹—5mva%krj$µ€sÚ'`Tš-Nu'«{®ê>x‚P¸­p–6›HÜß¯1AÔN	aYfN¤1n…vÅ#gîŞzyäñòv1·•zV¯Ğº:Ş—a`FBdlïİ·íQZğÖŞy©	Šëu‘¢@ƒÀxSîOlø•IğKë`Q°Š½ÅR_OŞÅäT_mùgg´át6xkˆ’IX=ÜYÀ®SŒ7Ğ<q\ÔóõÙ=çÓ|BÉ¶sê rÕÊ–Şõ]ÙÒ¹&$<7Â 5„êb+ÊƒØ ë"¸ã€=kñ.7tj4Ùvª­g‡‡òRåAJˆQş,¡Aâ7L3,ë%"–·a*˜.tõÎ'.a¦Ê–-vÕXµä-]İsûHn>ãJ¾ñ‚±£±Êm–o£DR&=j©ükÉZqñ™Ö­ÇÄş?ª1’#)©‹a'“ÜÇ,yÜÈ¼¦Ú‚E„Êb72˜`ú›!ôf$É$\'T„B¦Ë®~˜sóƒYÃğ$zù‹»Ÿy]®f´Sº…r¥y}îşÿFä,éƒk6©Sßº¿@{£œY¶ÃrihqŞ»‡"ÇC÷&‰cª¢€¤½ca©›$àŸ¸5&»¿Av¥,5í‹¸>Vë3_®`#ìËJSÖ?´»®içihGÇ$É±@ÿtT½—ç±¼T;>}Ÿqê†Ş`e0^üª'y'ÍÏöÌ+·zĞÅn‡Ê÷ø5s!£K$Ö[pTÃ·M6\·¿¯<áü9*=än64ãDªîSoú‡ÿvß¶(<OºÿÙÔCc³TÉ2*5@i;ñ kÀ“‡ÄTÅã›¿°îKv•Ü¿n?îk°Ø¶‹Á¸œYÓDîëï"ÕŞVû¢×÷ÉÊ„6‰b	põ‚°Ã±õ_¯q6³#·¬ı‘ÆÕ©D3ŒÚ7â™²óıúHìdNR®
¶i@x/”ÎCkËdÓù s@‹¿œ«P•”KA¤§<šRç‹ìƒˆ.‹$¯x"MJ´åàÂ¡ÜµˆÊ/VÍõQIg`ìôpÑ]/uòã4-ÛÚ¡9^iŸrÀ)'û©d–€¸Aˆsq~òÃ_½RŞû=¤):IëšoÔ‘"îh,Weòû`Ò3XÇîˆ)OpNEŒMEe†ôÎO¯îørl=‘{ßêe†³*Q–1NäŠO¿ş%éæ!6e
Üp3fSMÁ†r!ÙË3gÇ5h—‡õ®üÒßDÉ="é¨}ı‘p8ı3ø’4²CDíwqŠ +–ŞH3èÆ†À4B,ù´‰‘YaóOGòÕ°k¦Ú‹|b,¹ĞÈ)~&;f2¢]OnëZÁcÃVqŸ«ù··‚}0¬œË·/Ù2‰^LY”ri&Š€­k7¹ƒm¡ŒÚ&,[r^špWßeå6pŒµA«ŠYDozXİÜe_x¶†ñ¦åâ˜ŸtNŸŒ¿!w»“Éjÿ Õ¬LAXµIü&“uÓ!JG\Y¤í5Ã )±FµåÛÍ‘Ñó3ã"(As÷"äEÍƒ3ˆè'‹rÏ6µ³İaÀ%$t¼jÕ½5vİjeƒ+V»®`íënß—-ŞT’KEËY‡‚å ø®?»3I.kŠ…EÂ/¤0b
@›ÉTú«İœclt
î +Ë‰«Lø¼2?ĞÔ'b¸Ø¡ZlÖ‚Q+ŸMµÍÒ[µF[d7Üş¢mòør¡ „¤”®úæÄ
û7«G/Hí|jxMÊBğ÷cXoÆmQ •AGƒØ‘/ETL®
_­Á/'€eúÃR@­á”€ŠN’e2DroGĞFlH”¥˜Ä^>z³×ck=ÇĞûgBW4KØê¦lPRŸ¾®µ“ ÌÁæÖÒÆ#Ó
(ÕŒÂua¸Øåu®‰^$È#o—ò¶ôçÌlªH½)5Sğ7w7Ô }u®o'Î¦ÙK^¹¾ùîÂÑ¬šÿ®ÆU:§ÒcI¥Z
fVnÇµ	¸êvy›ø”'_G,èáâ¼Ó…_ÔhÛk@<ë\kı´a‘ëaø4kGOo¾üãÅ)Ì(İØ‚ õ/.áPw
ŠÅk;w™å~ú7í. p¤ë8Âä®³Í±búS*]éŞNğFØ‚\X· í"õ¨3ÁL‚÷]&r§usqÛ."«qàõ}÷Œ“ï¬ïbî#í)ßiªGŞ4¾>	ÉKµô*b‰Û0ÊøyWÚqƒp{ĞÃÙ³àiU|¼?³ğ×®‹¨ZtgÆïÌöS²@&y—xfC9)¥_ç«kÊêwÄ…Õß„:òñ7®pÉı~c¨áÆ€M°ÚÛÁ9=ÎZ<ä5<Tğ,«)XüĞ~ÊñÖ¯†½yª“òÄÊø)°DçÜ£…UâÏ0
Îßæ!—¯ iD‡E`LïúùREQO¬8CpX¡õXkÅÁ¯Â5ë’íÍÛÕ…N†±ìäQ(hŸq_ËşiÊ‹ä–a²Ç×vMôW™‹§¯–“úKNÉ+`ºõÀŒ›şçC1ékó“ÊöSJ©¡õ5w•~_&nôÃ˜5A¢ã2»2ß%5*`¾KÃ´F+¶F)¡øïğñÍ7†ƒ¿ùI<TU°é?(Ûûeúh@é‡y¢ ZÌË!û:ÒF›ÛÃ…/|b~m¾v¼õÉ¿BPH:7Bùş«Å²ßÄVò„*¿ÍÁ3l	6CUr$m™”:«BùeésflD¬ÅŒó4œw;7AK6†ä˜ªıå½‘ÑiãÛ[ƒù?ÙWâÖOúB–Ê°¢Êë(<ÄpıÛ°ŸÂ/®R¯¨‡rGu!ãû_'ÍLRœ&şÄ9¬î2
Mb	YLğ÷šã¼¿{*û`ì›%tä
^ShŠbñıªëş§'IŞáÆ ®¶¦ËJ]›¹™oJ@«AıÌO³˜-`©F÷)T_Ñ’Ğr:‚és&ôò{náû /ó¨Öt9ïgŒÙÉoXĞNº@è¢ïWÍBxönHFXÏ“Êİ!ÀNÃHÖoĞóÛnì>ºùÖ,FV)ŞÏ€¾.áºtŠ)«L7ºœsb´<òo_Ôšs{ûÌßÁäÛk`t]q úı›¬7áŸ	–í¹èœÒ…2·‘¯³SQuÊè.e³DjdáD¼—ü©:…-øó„äz…¼
vL†x´f(Àó‚çÜÅ¹¹Ô´.KŞ°ˆ³àx”²ÄH.Ê‘İñÊö©¾Ç‹àcq•Òó0ç!¹|bÚ¨ıeWQjæo´*Ï4ºNH,O I‡!£ l´Fæ'ZÚE3µ¨©]Ã/q«hCÚ[$eQ¼PVŸ¼X× tH%\÷Í~c¨¿Ù³Ï­Lf*åK}
{bĞ$Çü%	ß¤nÁ#ÎÙA?m²à5[|ªïŞ9;`íŒ‚ÌíW/‘S…wÈ†¢UxêLkìÍ¬1 ¬eoõvBû}‰ A*˜g©övWú)6R©a ğñŒ^®G9T`Y^c)Z'¶^Bÿz¬O¤ù$u·ezA6É/(AW ¤|p]AC l\Ä&ÓÎÓ=Êv	”µOÖFÈ;ãËÚÃh»1!Œˆ:¢Ş¶›Ÿ‹¶mŒ'›ÊtdîÅe¼¥ùYb9÷¯õóŠÇŸ1Ñf¸ıK[ƒ¾T¡¤ë.âTÁÚ¾^ÌŒĞL¨ÁóY—N³·õ;.ºfÉø¼(—á KÏÔ`8/2™.‹äŸà†\"S[·1
MÒ1G«ì#%¯%°‘^h{Ïm"**£ÅÅó¶šsmOrÂ( 0ùŠSÁx-!%ë9ÚBUV“Ä†µ®÷ßõm«mí÷©»ö#ÔÛœÚ©HŒ%¨¢õJW€¼‹ãÉù/;Kq;ÊWÂóáù— Ñ[½új2;O V.'Ÿò,J0N½;–ke¹Ø”]şaE|ú2t0ĞX¾DõSm“»Pmš‚-r <îÂj ÔˆüÎË+ñ0Šş‘ù§†å«[¼ÎA=™³¸ÆXupĞJ¯Dà°‹SÊûrf'Áé’[öo,;±;F@ù<³õ¸İ¢Û‰Ä8±€ç'9HïFV·Yñàİ°¨€ÓÛ",©¥ä§İëÎ0øş$eÇö­v*™ÓãÅÌóÃ[’\x“nz;dp0SD…Œ– *|; ®`‚kOÆV¼@»ÉU”k# 4H¦.ÎRÄğçÏªÑ@k4_úªÈLË¢N1@SßK[cSÆ÷.ÄNÏ5åG^µğ³nÙß‰i(y¯úı÷©Ê “¡&Pïü`ûcKÚÁ²×E¨¿„£”‘ }4ô,²5`,”Óøg<»¦'½iN•76ØÃ¼h¼—Š–ü†öß¸£Â˜Z”–‡ eyT­:Í•$ñèvrËÊ9ÆŸşÛ^J†‹ÜÆÜ¢³h>c¡‰9GABW*]!,Ôà:<»øˆwé®×ø…ƒBˆ2BLGfGcÙu‹¡£Æôm…gVÇ¢8dÀä‹[Æ>Ü;æF=°ÒıËóAãÇ¬S,LK	ÏQâÑUÀ‚p¤œê´Ÿ <‰8g”z_yñÂQ“‰ÎÄ;íM¾~ëµz;Y•oÄúõP“Då#U~2æË7ÃÍÍ·{{_5)‰®Uş
á\pL‚(D9cÏ …ü‘õ˜ó 5ô|Å}™†Ç´ø%~n'·A,ÚáAeMÆıi«ÉJMNšôÆÎ{²¿ËÎ³ö®ŞPëµs¹†PÑtï‚&P‘ÓKbó#å“æh ˜ ·¸GRrBZI["Ñ‘Hh¢ëXæo¨ñÙ £ôôKHUú´z)öae?%–%H^4$Ö°Áj/º'¶—EærÅl+®á–$ ÔF»Nû™éæ4È%ŒÀÚqbM2%–·âÂ[¬¯ƒé®£…ÄÚ² ™¨¼¼®à=÷~İ;P(èSÀ_eMòæ¤˜ÔÁ0î›b‘áÚ'v:Ãá*2IgIƒ òš÷ÍÑEàáÑm”ùµQŞõæa„›ÀUâ,F +Æã¬^hùóQ—cêWçöû#úsäjŠ4Ş’î=«À¿t×\¥Wí\u»{ùÕ}fö¦”…à³jyğ3"›Bú‰å Ä)*£˜‘9säSSÑy§ø=3ZğÈI¨àÂAĞ¸èDÉ^b-ùÖœó0aHä.~WÉ’ú² 1¯ˆÂ‹˜Çñ“Üù¸lÎøs–9Ç±Ø]Ô‰1ú$©E¨YŞ1œj¼K‡°¦Õg«(x0ÑÆÒ;3áÄipÛf.úî‰p#‰ÀèııàËìíŒ´×ıÂ¥ã–,µå,Uk.µd•<`IÉ”Y½ÚÍ[ÿ²È-ï—§¡õì˜EfÉV«s'<#®tLÏÆĞÅkœQ~Ë`iÿgÕ E®k`yL­Ğ~`fV-9Å²O'¼úÕ†Æ7Më	s[ó.•ÊÇ«Íd3Í¬òMN„ÆÃR€9ñ|^Tâ]¯GFuğ"\x¥I4A5}V»øSqBˆ'Ó~y·& ‹Ä•H€ˆ,˜:Î«üp²Ş%@Ho+wl0D›}–®H«[Ÿ„M:YƒmÒ‹ôs ¢şêîMTNBÓ¸‘v·ÂıÀâÌS®˜²în÷­uîùy…‰oeòG8uQ,±_â }éØ<¿nRí¸!·>Öê~h²òİ÷
“Ü?§mØwÒMEjÑü:Âãw™S†ùC8”Ò‘’)İ³“»Ä‹¸ÅÆ"'zë×úÇ=ˆ
[«m†xŞtSŸgg¦&§ ö%ì›Tû«H rEP_'8[A#x¼Üô+µ®u`2|¡?õ.æSŞu¾¿¹Ê_6ûâ[1¤ˆ§qa×£&;¥õeL‘|Î<½Ü:|Ï‡KiR¬@¾-ë[LÕQ]$Y ^hwá±îkR8.øø"Í?l¥MàG™:³¸±Hß-)î]ŞK&Uy"´z—À’øÌìkšü&ˆ’14>^ê6J<^–Ö,}oß07Ó¥|¾ñFL˜²”dÛòX¸ Öí–hö
‹ËPoj…rqÜóƒÿ‘!¡Ê¹~’bºsöÄÿµ$É~›®JŞ11ÈåV§å%Qy¥…\gÆe`Mp­Èğëi»¯ö‰æu“,™jœX×$~:ƒïºVÜ<ä¨æcÁŸ¼^¡ZÛMƒ€X¹;ì!§&4…	™ÏeDZ8‹WUîpÚ1y¼¥?nï—bJ8päs@EºO´ô[«Î]òºû` Nj+³¡x:;:Gå{k`-L/lªƒÛü÷MW¶][$î­_ïIn±o«Vâ1"íîjÄÜ¬œ®›_/cÂ¶ä=–cX -ıê‡w–è²†óĞïn–F_=)ıy÷Óã8yB_İ_‰`ÚAG|ıf¬ s™Ò\0ÍÚoIï¸¬ã“}Ò†]`á}§ñœá $|ÜzJ¢°ˆŸï*öİT´‘’ÓÕv¿WÇ@‹¦$Ãîs&"07¯Ñ`€U.]cf+’ãóbâÀÄB[¿ XşÚó4ÙîC_LoŸ|R?İš—jºáßWíÀá.ÛRv³İü	Ë8æ³x\ğÙ(éÛÎ<’»Y1UPF´Vx ¨mêÑCé1e 229%[>€8UÇZî)º‘ËE šò,ÉÜ'œÈáF2SVUß7Ñ°lPÛé—
ó‰ï¤õ.ƒK9Ğ»-Ñ¹|•Ÿ ĞFûÙøPèÅ]‘TLŞq.ìõ‡â„Î;R†×„‘7±-Åvâ˜Íı#ìêWßğ±Ä‚º5—´×j ’§ÖBz³®÷ûLŒM˜ÚI`ÚÀ}dØ“ 9Ñ¶ItQ€Ir9fÓ´ Mˆ‰ÊŸ%Cò®Îñò±Gràä&s«UçGÛÊ'TÖ»àœ`<Ÿ~AU°”½*C€8Ä‘cQWÜEİô(Šp!iéà–d¯ŠlYŸV|Jû¡£ô¨Ñ‡sW_„¨ì?Š63c™m&`v«\Sëò§Y¦gëmÆ‘¿ãúeÏ3¨ê@úg
º[ÍJSÅ"ÇåaÙ%ŒˆJ©>„À‡àIç‰•“#u/6'Ğİ´¢n¨»7‘åİíôìA+‡‘~:Å:HŒ%éÁø
{m÷–pa{Ï!ÍjpàK.±j»>­ÁêÇ§\íByst¯˜Ñ <7ô8Æ\Ç\ü‘İşãIå	?ä.ü„\l7Ë:q@{9Ï–´ıIı€šyš¡ €ét+Wˆm|HĞµ\HÃ†˜ğY<-á„$Æœ,/çZË»ÿE@«²Úh¢Ô×øUk£Z·
¿
Y">úgècF"=Î¹ÅNôtÌ€8`Œ‡ˆ—œ¿s …Ë•¿ÇÍó_°å:ÂWÒDÒ`ıÉ‹C°5YZ2”û¹¨ }W±Ccæ_uÄŒ¡M¡^g'?;ìh#øƒ áá"½mJK0Sf±¬wéu‘Ş&5’\5*K ş±|HtU(ñ,ÉVF^qæ={}6¬ÂRò¾TZÈÅW‡Ò·½¨İ!Ÿ3 »¡¾‡}ˆØ†Ûø€û}‘lë*Ÿá¤hó ÎÄ™şŸtcs9ö”‡ş'©ïÑ)®2–O•GÅ±9È9'«Sş_t²FÄ)3³{J		ao8Ú£`×öÒ¢ª¾FfâHvÑéYv¨û½¶Çªše2¬ùj®L`ä~ßªş²±@°òr‘™”XDR°!À}Èä ?—"ûŠÏ†T„«?¸	T¹Hdm3I“`–İÍ;‹>¤liÆ‚VaÛ;QÁĞ>şOÙ‹|ºÀÔì¦Ş¹İ/èû•ÿ…jØ§%øşÖ¶y½“{¬¬Gâ…7™Oá?*OKªÙWe´VMJf ‡ã¼ ul¼Üİ2¿/øÓJ»V–".v¾³şƒa÷ì‰y‡¤Ì*WçcÛÀŞb`Y¼.¢ cö½…ñ¦YR÷“İVŒ÷0ÓWû}¡ù¸ö)£zl[3ñ--¬‰(×Ta®Ks§ä¼ab†dvå¼¡/¶§Ç%rÀîäZŸtÖÇËÌÊ³u
Ä<Qœåª’†zÀ>vŞŒ§ÚÅo°Y…‚$yv3ˆ 
7S)Û–<g¤V_†zYŸx8ïøşu£é–S¹Ì1GÌÁ…YßØ¨«‡´µ€p0´ø
íÜs`–@¡P$ªH‚6©%g‚õX-S?x}q<Ñ8õz£\zŠNºK]+’‡[Ä¢À ñÒù›Òw!^è¼;Ï>5ŠzbØe§IBfV½Kçrøñx«d¨ÌŸôdy"ª²†ÈÖ¾Ít½]_³­h‚>sä=·ö†Z`»«ñ¥®şñŒ™•àL·ÕÚeÊäè2şá©oVvvùç6:ƒô#ÒØw5¡5ğâíÇ–@'İt[k4£ÂYd)€êPy.Ñ6wƒZ_¤¬úá}˜@’Ààıü±Yêy0º˜‘`QŒ¯¹ïĞ®o•õ4üóñcóWş\¶w>h}ßéz‚!E±Ã¾"¢Ş^=O±fDì¶”Âö–Gïµª¨Ê&g×8a†&õeb¡I
[ ‹È	èM"š`÷}óh«Öƒ L©N%:QÕÜ ûW4’–ËQsOşÔÉä07™~E{Á˜›\Ù›º©ıÿ:.ìŒ\(¡¿åœO®èÁÖíù©§ƒJƒd.¢S%ğ«n:Ø%\ÚS­ë_tÜéÅïYº²»Ç¢RÅ¶È„?ìæû¬%Ú°Ô•¶3æªe ùwoÄåXÎŒ:Á°@¼ÿáı¯×-u3«K&uùg¼r‘àŠÛİñÆŸñŠ“ŒcïÑÏú>Ù@¬¥>şDPÊ9jS0@[[¸¹«Ìì¯–¢Îè&gï]r…¼K+Ãu%ì£Í°h}ñì¿Î°Œ¿\.AÆ®ù›:õ4HÊ÷"ä¨D¢ ÿß˜Ï509÷ø:wÊXájŞDgØYlwDñTS¼Ùuv›æp)ê‰`N‚(ÓIÂH'“pì‡5¼Ì)÷pmÉ.Ï3qà°Ä3w>ãBÜ'+FÖnæ®"Ø7*d”8ğüõÛiá6Oë9_‡%¿‡LYWN'ï–Å@€b—K>Ik}¾O¿µéT(N	Y¡ŸÕ‘	A¶ÄÒbùÚÉ¨m¾”óÚÍ£'sà¾Ì‰ê5OYÌ€ƒ{ÕğBÑB=·;–BØÒwéb²ŞÜ
Q2Ö•Móß-I¦€úDøÀŒÌekÈ÷!v&g¹é0x]Ò¤jÜ™àYï
´hfƒ–Ä#-r$¨z=gæÙüôá;í	6N½526ú+ê,"«•RI´Œ•ÿîQEì*•ÃcN]'işÍi®9óX÷…GÂT0 §Š%'ñòwú7z-}™N•ësjBrQ@ŞŒL>'+—‰Èàl	M×Àİóc–Ã„E©TBºÕV¦Á l*Ïf­J$<v,¹ğ—5CÑÍ'|ÉÍ«£1ôWX¿àå£qí¼èã¢Şk€[@“£/—÷±õïn”,Óx¹JâæÎ¼

Á¶O‰Â   †ıIñ’€† ç·€Àëäf±Ägû    YZ