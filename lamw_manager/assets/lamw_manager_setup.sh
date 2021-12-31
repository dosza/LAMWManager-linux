#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="469620061"
MD5="27986b61acff0a5b9cb2d77b8d0480c1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25800"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 00:47:44 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿd†] ¼}•À1Dd]‡Á›PætİDõ#ãäÎ„Dnxéå\›s™“µ)=^ïğ…$~J'æp“±u3Eù(¦Ó£×4êôa>Jµ) «Õæœö‹b»,PÔÔïc%ÎC[Ä4•”_” ]†ÏV€ˆA4•êFÇQ¸MÊh†/Ê+2ùÜ«Ù2‹÷”ø[z÷,?±S/.ÉVÛ„œvDiE™uİ¬:&*Ì7zX´ÆmÚ/zÙˆéÆô"n®™2İşB3A-T¯º*–Hé5j1“=Ç{…ŠEÕb»¿¦WÖ§º•¨g×Dô{o€@Çë"r§XÎãŞd°ÔQŠ³í=[ßİ|“*(n«ÚGôÖ±VX$vHÄâN¾:^AâA€AëmÛ>xØI(ªÓZüCCG8šna´¯ñ3ÜzÍ[ˆ‘ëRÜ^ñzF!hŞQØîê>k‡ÏØÍiåDv¾»ä]Ş2™GÿgÜ„=°/˜OKËû“i5Nª±H™êÀX3ëuu4Fü—ÎXÉºPíÕÄjG	1Já6ª/Åú……ÑHé ½zŠ”ÀhÌ¯^g>ÖG5•‘ù:›$§Tš‹$-Ùc?®qD—rİ¸0µü3‹øÍÛLv¢áï3M«›È(˜UZÃ"ƒŠr]5»YÊWÇwˆÛ-VuA”üŠè¼\İª8«¼;„-ÖJ¶+|Ş²†””H#”púCÓ‡›‚»™¬â[XÉ1:ã{™äCÎœ—€Ó
7ÛÑÑO0õEõ_*ÀÃ”ØÓjäˆö±u*Õ CÖXH™ä;G8oÖ¨gí;(zóÑÂ¶H“‹®x ÜZ7¬õ‚*û»H‚<p4÷ëìÈk×›nö&6mjÏ(U²ÊİFês2ëMÛ+*¸0½÷,:,À‰²°Dtäk}SéfXMVÚÃN;ÚŸ’vVŠ*HèCÖ:Véx¬Æí„gÏåÎ-gŸ=úÛÑúuNYöKØ Cõm‡`
ú'/‚‘05¶ïÛöÔGÊœTwKDå§ºààOä×/ñÑ‘úãúéÅ@”™Úvñ˜ûG·Ş^¥ö²™TJáË¦9%»œáJ.9D
ãeGÜ!ÁyúEó·NĞ±Xğ|7¶Ô_DÚQÆlã¥ÑUht|CÈ‡Y÷ßÿ¯òÂ²ªÛêĞõş¬å]Ê»Íµ–=2Ê>İ)¹1ƒ9¸°¢N9[Ötç
6ÍZòğ‰îµÒâSö˜|šm*Y¹æßÙ}‹ç˜UâÒJ³Lµ¼£ÕA,¦‚u,û	É˜sÜTm,ÈpÜX;(xPèô9ğwWb;¾mKºH°ÜMI¨†P¢Ø03Õã6=„†>¤ıŸJåó†úÔ/'ß‚æ9¶£o
px$]óÜ½ó$°ÚšFW,ß"ÌyQíƒ¹ö”r9DèpäÊÙˆÆÓú
šQ€‰æÀYM5ø6×“÷Ö®â^ã¨ ˜Kwf:­6w+‡1ë[ğ­aNş¾.¨U¦1
t
İÉ½ªX ‚
2õ¢–;µ°M~ú@åâ|ı[¥î^èÍ‘+b.«\…ˆ8kºÔÒı¦f“ÀüPÛoÕOÄ\©ª2,!˜Z²Lrn¢·‹÷2Û3Ì°+0¢VâÏ¥®f
mC‹¦4™êAÈÀõvµåW	}ò¬õºq°R»ÃÁõt\ø{…kt`Ê}F|OT«O<É¶¸B¥¡.o™tŠ2îÀ$`JS cÑójÔé¼sëò¹±×m	ßÂ}¸šYå`=Ì	%qRş¼£À®I¾Çñ {Ê„œtúäÕ´ÂSäwT)qhr{«§©YéÔL%Œ Ól\,RÈ³ãôŸÿ+PÌkß ¥ıÙ»íĞºQ‰E92	$DöÖ>ÃN/§Õ°Ce"z·ÍûôBYÿèĞ7ÂR®DıwA<Øu ±å²°
~]wVW!}k{«=Ñ©šù$Ì/asLrÍkÆ}2;ˆY´4ØtªzúI¸q„Ä`¯¥yŠ:ÇFÿ>d¯ŞËúåBùWªƒc±àçmĞÌMUO|;lOİz‚Å+ÙÍ'éÿ¯ª_)’oªWôÍ·´í•!ˆ%ğ`­qıeß*‰…Úğ³¼#DtOÁçœğø°É_B„_¥W9¹¦]aìhkĞ
°©Gº¶×1w§Óş´ëÓ¬èB¸)#ÉİídnÔ:Ôòärci²±&P?_éİ½pºî—ÜM¢r‡QŒ•Çƒ¤jôği11K6f~>Å,$	¢?üşÉ!Ú“Çífzbİ;Jµ{“\ \ÓÜ¿a~Ãìê	àöKñÃÓ‚¹8ùKœf°‡˜{Z€Š½8Èsç~Ş(EÛ¾‘®ô° ½58$¹¾!z²#9§^ÑÊ&Éù±ÙTç¾ñë‹a2Ş„"F{'©d0]}D·|Wš"lĞÄÿŸÌ'¸Úh¨R%³ÚkŠí\göb‡ğ-(gk9(œä°K]ÃâƒF9aSÉlÖÅéç^°„úôÙŒÛµd²B{T¾ˆ—+_ÀZœİk›\gê5+gİÃ$g â—1ÇÏV5nu™‘PDŠcÇÇö.©p«x;™ã§ßI÷t­¬rmÄĞ
õTd*tl)±î„?¼M£å]h¹d§v/ Á‰
N§.üİKÔ87ûî§í•ËÇ*Ÿ7ÿª!@2v±X‚˜z¦xCñ‰WTŞ7í¿r%£kX	hÄi8Ë¡ºaÿš]i<2Qê ºfñùædûÿcÃE¨gÜÜFé¾‘Ñ?ğW´¥g³–zÅÑAà§¤°}	†å¢—"HJËã?4¬ç«„äõ­‚¡&·[©áÆ\‹îÇÂÖÏ»™}‘ï‡é	¸a¢!+#¸êˆi>@¾£eñWf&Ğî"xB¼E¼ş {v‡–ÎJ¤C o­Åç>OEÏñš¬KUøÃ(	”ú©„[¸˜Ø‘^ûš;ä­t»"$š„æ\”'„åşÍIdÌÙÚ(vn[a‰ĞÑt‹õbªë†Unuİ¤ãkx³¬	F^â–Ç`Á-™3èY_á»!R(-2¶ŸmÕ%ÅìM+ÒÜ…¯…—Ëeÿ}€â=
µÃª2+àiü¬ÁÔ¡àxôR’ï›„¼\à9P_¦xœôà®	JM6œk$Î€CÕYy·êÿåğuÛàü"¨Ä6¨ÜâE ªkÔ•hW=ü(Êån”Üçƒ1ëKÇé.Z}a°¾½<"Pş€Äv×,#×ùÏ./£†H+›G;ÂSÊqÁÖX0 èú^—éß…)ltäÑ¶2Ø.xtnvûeª’fJ<Â~ı3Èôëe—gİ·¸¤Èù^¿U'@ş;¨ÃF>‘-„u%jeş1HŠMåø'ÏCY p®]Õ3yûRy >âƒÑw>ƒÔÂĞìPÍûÂÄë œæ.=škšŞüÕÍí“¿io¼|1ÈŠAA“2 S Ä´ÂĞ3±©#ñ7W¸tièº˜K.>@/›llÅuh:dMBOÃÂs´øOÑ£[fÄŸ6/‡©AíÆa›ÏCs¶	Õ­ğ‹¢œ3‹ûõHZ,éPçŒVBk(mq­ºÄ ò*Øpıú?:ığRøˆ¾aHuO47Â£ò%¡C9‘?ÚqŒ•s]—²ª­€ÂèÂ²a6B…~çAÊÓÅQº´^/\s8 ]„#?8àØh!ÆÍÖï¾‰ß:¢o^v …v(°…i\ˆúã¯P9­UZYØÈÌPEx¦0\r¥ÜÇöŒç`ãpÆÔ^5Üsdé fÌTÚ:­İû/POöc—¤ó“SûP«Ãğ2eë›Ùé\âõKàä³3XA-:Mã_âê·5q,!/04pö“ÎÁFøºª2‚-’R9ÒÄk@¥¶©Õe}ÂÑ9 r¸Ícs‚‰Àµ«Ü#q¢³z—ëM×UŠqøßøÛXµG¸ô‡º¼Ñc¾î}]ë½nylO?-†„’ Ø½Œ,¼ÙßV|Pş1„wJ›§4„bhwL¬ÀÅ§: 9çÜ<(&¡½´EŠñ¸¤à)æC8#'p°ÁlÌ‚‚A+Æ ¼İ+ Sş0ˆNÍ^šhBÓQ¹~Ç‰¦·íOÕ®2¥T„(iéÖ,áT)ì’­Ù¼‰š4ŠÀ‘)Ê¨™0Vo7OøŒ”»Kÿ+ÄÏ $áß\_Qlù˜fÂ³‘OšxAúúñÌº6Z½m/9tZğ?Ú|Û‹),ƒŸr›ŞR6SrVç‚Á„?Æ§ùºå˜õêñ-¡¢Vš®ïÀä=ë®ôõÃÜ!^ö]/Ìbù@I§IÁö·OrôT§#:VàUˆ¦ÿLx/c­×YL“ıêîŸÇ¼TÍï½TÌ°òÖ†"ò¿‘¨…X,ÃÈ”t[#8„Yå{Hª„ü4¥1ö¼¹0ÄĞ­Ú<y¸!®ÓÄ'½d¾â¨;F{\ZF¨ƒü?/¥c#’ØØ:ÂPÃÛªZ¼÷Â¸•œŸ®Lôöñ¢Eqù$mãÛüO_]9=xë]|ÖÉÈC5Ş#ƒW(_“Å­iYKFfSÖCª°¬Š*µğ„œX(…)Ë6(¾êy¨~Ïğğ£Æ6­‘Şø±VêÏ­}
İLÒ´û09‰Ÿ¥IšÕd¡èVŞı&H³ëşÊÉ?–³/¬$Í+JSèàÌxjE0äŠj%Â†æµ¶ø´×ò›œ-ÎÕk	l pŞPÂÂ /†úÖŸ_ço§,Ú>ü±×¾ %ÓX!]øí†*HAï	Îïu_ĞÂ>¹ß)‘Óq^«îmI ée}œ–ÿ‡@‡¡µÀ{öã­`§,ÕH~è¿åïeÍ>#ÀUm¼tNâv˜¾
Üß±§ãNtñ·ÙOQ`P‡PTD|êUxöæR9D¶1®òÕr#ë29#ÕÃ¸TÄ"˜F¿+ÉØËHßî²7ÎC”m¾ô.^£k£/«WHĞÍo:,tôÏğ¤•º\_Íõ+¹P9U#|9U—ùqw+£oèß¤àD·€ ¿óéOÅR€ss…€ß6rZû \Kv_{T>PTÅv‰ä9Y„^@‚ª©É•¢Ù…9AymªB^-Êëí/dÙĞ<ÜL~™¾g+¿6³(†›"¥ãVè|ï‘é·wÁºÇ{YÏ–mSŒÛ„zg+Ñ€½P›ÿ6Ë¸(å÷
ıX};ÃvS‘ğ¼l0Š¬>4‚ï®ĞÖ5¼ÑwFÔ¦SŸv[fğ!Ü-è ™=Î«hf±ˆ©{*ùL3{¢›Ã_H»}½nbá9+n£½‚…'>š®“o,éÒÇu@UM¾[/EWäéSfjUÁ~¶Í,²±äWäº°LOr/
%ë@qkìxÇÀåâ\$f{İ2™ôeÅ‘ç‡•t[øej’¯’éÊ•ƒ²€Ÿ#HIø-üègÎæŒ"	º–BXÈ‘æá£
üªº(ÉÍ—K3-$8]ñb¸¶2Y÷öÎ—ş7¾átue‚JÇgjÅ”ãIÊ(ÃcèŠ-€2ßå7H'Ñ£½FkG_‰rÿT={—I—°ÛƒŠæË ]—ø”"ÙÎ	—æ´ç¦:¨ˆÚE®ïÚÅŒî]Ig): ×zS n.‚°òäÌ?Ñ†Öñ€£u††Zƒ…ç²K0™öX™õµ_gÜ¡²ÿ‰w©Ì’:¸ÅÒ‚	°Ì¾Ã“ÖÕp£¶kAçâD@mi ËÄŒM˜1§és‰P.ÍŸÁ¡z>zá8¡Aìn,ú¨‘g+\U.ãÉP¡ö@nÂÕÍ¢ıé¾å-ÓS¼swÙ´y('Cbàñ@\ä:Dó:\—Ip#UÄdg›’Gufg¿EÎcÂ»JC [ê©Y„öBPá~Ÿy™9t¿P¿¦ğù»­î™;OvÉcÏÀvÉ¹;Å|\¡hf‡|÷‡/ª3&Ãã%Û§3Y³M„ç¬€âr›«‘¿p$Ú#P1{üş–)´IÂÂ8†„û•Pá¤+qVáºR^ËëâpÒWé³«‹’ïz A ;‡EÁvk~q¥E0aGˆ’©?¹Ëõ‚ø	—18ä8ğ&yÄí"&ôÊùÄŞ8{g‡}ö•Õ¨8›[ô¶|nTE¤ÕğÎ5Æ-úÂd9í·+çğ?”Vg]–‡vmı•éÀæ„‰«áÉƒİˆŞ®Úñß¯lĞlÌpØd«ÙIÆßºHß /±Ùíˆ«Wèhy-Xñ,ŞOÏƒ±v—¥`·>û¼.‚„xW=wEÎeª–Gİ8åB”Î@egóK^ßÛß—Õ>hõïÊ[×Ww¸ºp¯Ù”wõÔû;xø Å. †A§á¾På
§Ø.« ¯ÇÈò¥²µ-çwP.ÙÛuB¬v3ÉÓ×ÊİÖèÀÛ)ØÉBe‡…ñÑÄ…§f©/A*¸ÁÚÚÊ™ƒ[dÌç«$İbƒ9èäUšfERîïª=àDS©rÒÚ'[eKK˜?øğóŒÂ0½çlO¦`‰Û´Ü!æ5×§›Ògyı¬Ğ¾ÙJkqø=0 ®©ƒÅÑ[Â¥Wö±*–HH§A…ífDÑ‰É#ÉÔÈg.ÚECçÚxÃ«Üy Í ½Ş;§øÛ
Pì–«ÏÈ^C-Ò>jšŠGuÓÆ"è §«‰ÑØpü+mÎ9ÌI$b ÿy´¼;lC@«²Å~ëlİíbfUÊ™‰7ó¥å%Ö	_ º[ ×"ß™Ø:feî¯¹û|TÔÖ4ìS(Í`–²zÿîÜ½–Ñhgnú¼g¼%HëÃÜ¡[¨"ôĞƒÔæÑf‚04­ÿj—õ1B”÷L²ú¢OJ´g‡ò%uwÕµb‘€aÅKtTX<ß»{iB€×B©¯5WîÕÆ5í¾wÍsÅİq=Qx{'w}M~G°2”Ò:ØÌIÇ÷$%õè9!–¢)î©jz‚ØÚñ«¸M4sŞHëÏøşŸ”«RG9Ö¢‘pFÿìX.EJÌD96( ¯ Íì/Fç®˜`FwÀÎ'¤qÛ6Ì‡Ğ DUVû‚ğŠ¬´íLG~~ùh p’¦„ºLİ"0£ÚÚÄæ:¡£j]#–PlÈxßS9’U@xŞ°İÜÑ”ûÏú˜^IÍ©”Ş5zc¿/¶éÌ{™Û¶vŸé¥ksïMD!€Ñ6Kò_Wcı'ÅSŸ-C’!”Ç¢Ïht}É¸ZuÑ=;õŒ´áİ¬*F––	Ìº¬ª)’	†ÿÒS¼(ë¾2ê‰#õŸ±Wëq#È"®®ùãæğ|nB}ê°Õ&1J«Ü§a®Ì¾ü:× \·±+Y§Ù#Ò
F¥'Ú3¡KÛÊH¾ˆeF«VKÎÀ»fws0¢$¿s¨Ã¥­ €ºù2jº¯ìË¼+W½€è³“v¯,#£Dõ—Ğf»+µÎ7rrÍh†¯Ë$Şìrñe0]ÄÔÀÔP¸e³fÓaÙÊ;—å×¤/ºù½Û&.7¸©ú’VDøÀ ‚0úÃÁBDÊY}5İÜElğ÷$ßÇ«ˆPÁEË1ÂvŠcğ	àUu¢ `ˆ ù<?3 @¾@Vaò­c€NˆıQÌ3§p!ò.ñàæï×–Å‚·0Š £[Q/bíŠv+.SXª:cÄ8ë®2Ë¿˜ÇÔ¼³ĞQı2Õ9DçÌ@+‹9†Ì¶’Qö’%H_ìûUd?mÄçÖCQş@SµJ“ 1oÁš&~~Ûğu.ÖşÖÀÙº§b	È€Z¡Déş¤˜‡°F+ö¤5õŒˆÅ-¥Dêl6z‘HMZ.š°o¯NûuäÅÂ¹e ÑºÔ'ó}Û+´E”ZvÓcğĞö«Éş½Õ	•eiOoÌÁ(É´ë¾ùT—©UÄGOıcç<Ü¥vx`”L"xÆº\œ´öŠö·£nqØ§i¥Y QıFJS¢æñ¡¶æ–® AÃ²ìou<Á»Û:aHOØ•TÕı	÷*l6lCìdş<“öı/hI²pƒ™oĞŠIÈt†ô´áÜÂ?ÌÌä¥WÂk±¹È8È'±Uô)¿€PZêÜ$;ŞF:ô»-G ñ`«k(#KÓ°‡¼Ò¦¼89ã]–­•¾VÃ~ó[vÂZ¶CYwñƒ$ÅÆÎÌnŒÖµzNğxj‹§ÀşmƒéˆT"ñ¡¤Q ^Xtİ²£*Û¢<Ü+ÄFVm+-"UÛ…áv¦‚éŒG¬2RIÂ¶z J¢¿qiÍ9™TØ RÌ·îc@¼Kï Ü†ã³Cìñ8„ò`9+æ««¯á«êêÆoøû¨Ú‘q­ø6aïwSI¼³.‹(n5.¸U&ÆÜÎLSthÂg²p6gÀÆKSñ(Ø…€»}sdC(jjOëwôTğ){¬Bâ<G—°ˆ$‰şpÜ4qnÜFG‘RVí¦U$>·l”çâgpíl¤¥Ò‡Ôùwá™ëÍÉ¤ümæetĞ®Hğ™}¾»$}2 }¶m¡âáİë˜õR´Ìp‘fª;"b—äyÃ–B½S•%"Ì£6X#^Ywº!‚dî!V@ùëıÅsØÛêŒiuF§;fy`¡BØÄqæEmÖL¶ï¤Î(x™$xSw'µŸ„ã…Ø°¡¿&½uåd›pl2FUœuÚ”ÛMdGe(¼Ù¥<xGtw«<ÿ`Fh•ëê\QÓ!ëŠmØ¡´İŠ¢w`–æSW>¢Â}‡—Š¨vZ/¯ĞÓdí¢²WÊ\l€¯´ûZî×’£ADlY´fø‚L{zŒØ¥¬]a£”½¤[¥¯İºÂs•e.TÂêÙI´Üñ…²$Î\‘îQø.èßusR³¾ekÉÃ–¦Óf¦gŠ´7’ÿ§ÂGFoŞ“9Â”:Äİæˆq*~–ÉCõ¢ÑL ÔpÜ é¿ÿ^Tm›/›—B<GIkûí Ğê+\%ş/x¸È	BŒ°ëÇ
rÙ8uF`Îø4ùCÈÖ¡ÜæD§yP`7¬»çøN#õ…¦¨¾$†B_eG/£€¯â]?Ø+œ1XÊÿCñ=î–û´¹–Eö§Æy•Z³2»OxØšSğ+›°×‡âÅ;¯´àK=Á E^yİîä7\óRcŸƒKüØ²¯O-Ùö4Ku>c³¤OÖ4–õK÷Ø/¯÷}áËÑÖÒ;ÆñëRíŸk ¹æÜ ^Ù(Ñ.:†wb¦2‹Í6hÉÎ·û_\œ’!óò¢ùVªø} *ˆ°ÅÁÏL5ëÌ×áªñÈ’FøıªØ„î.IÙ´ã¬„)“/^o¦7EØO³<ĞWÓó)Ê-wCÄ‹ıó C[Únff¬CÈyiqz®ï¢•Š›—Óä©DN¡ÆB*J#˜Ná,|ö:”ğW¡(Rp¹ñ), ñ11q~F&Úy:ìuzÿn¥L~1o ’–Ò­¡o:}Õ¼¦Ãê?^Ù"AŒİ¹¼Úûj†!'eÚËlÀ¿@HSsP¸%Ê™*ƒ÷¤è€³”Z;%}¾$%fĞ½ĞqAÒcB_xıº8¡Åd^¹©úğy]° ôy7 È.st%‘4“`@')ÓHÊ×(•–¼x¶­ÿn¿/éCÁiÜÁûıš|4gÊ3
ÉóSwç™ç8l¯”Ç£2‚á™*,½Ãº¥Ñ×CºØÑ¶¥ §­|«Ñ¨ şfƒ{BåÁB«6óNa±#q`í3Ô1Rqšãä Õ@AIæî|fÁuBæ¨¨yjY-Ô†ö<˜…ns¿ö½ê°Õg~».Øù^}We]H­¼ƒ_“õSCMÖ±Ñ'Ÿ®övDµL˜H|ŞlXR	'¼.^•§‹H’½kÌø}š©X×0^¨õq²[Q¦óZ[-8ŒL®Jİ«Ì9É‚a;İZ|PŠŠjîÉZa:M“rú§ƒ5Km­ó[ï;¾h[…s{ï-úİ¥ŠüŸÅ œQĞÃy09Õ­–ÂÑNìœÃnÿ¹ß¶ı–„íU²‘,æ–o¡ÌWx¹+i˜Î$‰¯¿ö5ˆÈBQüÀ‰0
~ù:h‚úŸ£jÂO˜nÑHçLkîtë@lÊõZq—å ±|¯}K¥"¡ÈÁL~]umúá+'(Ú™@”Ñ¥¸î²oT³¾ó.6J	ÄOi¾•Ş={BZ¨Š:J¦)k(óT\ş°‹„»Â
şé"¨À-1IÒÒN“(%‡†pS³¯Ús±cœ¶îø7ôâõ¥©Íß<#Õ¹uÁÏ>ªdæó„Å2„„RPÃ5#Æsµ"ü^Òƒçİ¦×¨¶Ãæ£œ“ÂEI!(n°[î·M:7 O$†	¨.XŠ<*²b\›Ü¿¼ß¢7]ù‘Ê³¡;‹Ê”åøhÓé®‰çŞlHhxõé{Eë€ÁÄîil4ã%,±6°Ñ¤À‘ñ¼3‚¦ût-‚àŠNéˆHÃ 	´Jg¬Ê„vŒ MıÚ½µ	?1Û)œ4ÛLFŠ¨D{>³´èåœjËÀ‹¶ÍY#ıno¡ò¯^Ì~½kK5Ë=üœkÌ=€z9yˆ+€ÉÀõ¤sQ„Ô¥VUJ×¤' mGÏ(½bª“4€1¼>ëW  «…qŞ*w7¾}3—àâ™ÒÆÆMsR—şœ
·)$ÂAÎ
|A‹ûDLƒHÑ…jq²Û×b+C3Åt¶©š›uİ*”ÓÙzõëê©Z ÕpyA79'6«ÎôdPÒY†b”¤X¿ñ¹ió|Ÿ(bş}şs—«¬Â0½¸ô}Œ•GÎrzÔA`Ï¯û%•WO½¾—_±ÒÌµù‘X;Üf>\T ' hÑN&KÀÁ>¡5JSycèC‚I%>ÎSƒ¶Ó7PÃ¿uèì`ï¸ß	++şÿ*~[Ò±üÂ½)‰Û‡1ğßD4ØeŒÎµÃl|¾ø§lÍIe+ä{`ĞN-?ç
=	ıâ‹ñuJf¼Î>ØğSÈõŸ:›Ğ óì’˜<ÂªPïg=¡UãÑi|B»şH ÿgh•vUçÍ£Š8åœQ ×*†}·¢7İ•†hƒCÄ“y¶ÀŒ+ÀPCpWª(C¬ã±h›8ä³#Ïd„5à5ÆŞœ¶ˆK˜–Hx-|˜¿Ô³,Mµ­¡Êğ§˜£ÓT`ÃÜ5Æ MÙu}FÃ•é¡°Ah T0HÇ¾í>~ÔËË†dA	HIß¤ô? ­*Wá{Ù¢{yşs„VèkÏh
ûËyEp•Ä¡Ô·ßğĞäĞsıëCD{eÊüƒ=ÓÖï–^ßF]¹gÍ/ôeh»ˆSS—ÅH ÿo]#¾#c*Å©ÛÅ!Ñ-ÖŞø¾Œ5… ÚåÀ(lµSªYØÊè/¥«ú¹yÎ«q$Qª?»~½¿4ú9¹Ô›éĞCL„¢Z:¹¿:–±AèhÈR2×KwFÉk,–xëÿ’©õ4<£”Eê‚¾eXöSræ<kü
9áÃæBaR
ÄÂ«Dà°ÊCPÓl
ı0/ÙÇ½KC£, *^`ûÈc²Eèö-}ÅKâl^ûPùÿÒWš­&pxï{5?)²\ÄŸKV¼í"À˜‹Ã‡èä%8RåÏñ3ÅU2U"#óµu–óBÂ¯ãÍó Â‹è‰\” Û!®Ú~I=Şí]<FG—õ˜ŸİosŒXsÙ£Œ•do¿»ıuâ	\"cŠ¬$%GHÿk­|Äëˆ?ô\F7ò“$¬¹´‡˜µ ÊÑ5¥¿ôÑq„‰ô°$ZjY4®1+p[dòÃïLû(ğ	¾aEùğÃúúëÈşºÍDííîH`Äõ`ä*MÅëGÁAı¡=Q&ÉñfMLÂ"óAÉ‡iê`_Åc¢§Ÿ
ÑŞ(–ßœy
7O“
À”¯\L@KJ&õùo¸­jö/ö/îÏEÇ‹bnµC™¬éôöO{èhÆÄç9©]~¨%{1ÖÏ¹y¦“ñDƒ{ğ¿fvN*­nöe¯ã`b¦^8ğ].¬uGˆÌÓ_¦;ƒeğí´Œ Æ´(A_Aï^5.¸K5:{bÌÑ§ ´üQ?FJ¨ö¹¼¦½Z;œEˆ4Wİ:·s÷^+[z„üJí¢…è”÷”„\KÇÙü‘s,™äª­âÍ x$­¡Ùœg à»ïvP]S9C•î=HĞ^Ò©‚º2,âUN~CŞ°|‹{WÑEÂ0?®&—Âw$ŸldqjOç^ Ë„2«"÷­®ìß=kÁÇ†ô›Ë÷ª‚Ÿß
£ÉıŠ·*×i@Ğ¤Ó{9ïâåe{¯>È#[~¬™AK¡ª¢ôé‰Rƒj†zHN¥òÜ‡³¢ë2|c±{ÖŞTĞÿ[Ü³&%.ğâ=¸’¼à“	ÔJÕÍ$\©ÀÍùŒÀñ8×­“íÖèÇu}¨lÛºf3ØwRW°“A¬M–'ìô44%¦©kk¤±0*¶…é8<—úÔôM™Œ½É Z?VñğæIx°¢ÂMWAa¢†lP¬ w)Á‘7±[ÀAµ“¦Ó¯ü+Dß}Z¢T°MÓ\ÀÂr£Î­ë“ˆÏê{)heW#ºƒh¿îGÖ)ŞÌÄ7TNÅÏğøB²çğI|O´SJ¬yE1Ë>æR—eæËC¦fi×4Ô¨Ø’¬%B Eí¢aÙŒÙÍØ
ùÍ…¯ÛyóÏò0é-™ıò˜z>: º¯‡ä6½r$İvUX ºÄ-‹uš0ÅFâÇ!nü5ïÜ¬xÓ™õÔ—dq6`_í˜Î`×¯&wÈEgv·h“¸¸šdUóïQÓ·-¦{Ü°3 %óK…6ífy›N7Æ/Tı©”J›Ã/KœLh^'şİHD“Zq¢¿}âÖ³§^Æ+ï@çÓ{\—µWkêïxŠ¦{éñJ»÷á>Úõ1)¢[€…³&šÙW[|”â–j"q“
6jÃÄ‰¯Ub&4¹kÊSvÈŒeê2ÎŞ;_ğ‹†úaHˆ`^q°×DDEiãWIõ¿,©„;C-À­’a¥¶pØnñËóÓ&ıŞşıj&Èéß´¥/®Cß\Ïª_ÀÕë^Š ÜOFê~§,:Ös!ıC'øÒtFÂ#rJ˜<°zÑlñÆ°'ûmÿl{€~ø²‘e~âëqjÑ¦‰üÎÕNp÷ºÛw¿\\l¹èoå”	Ÿd]ûno–‹D×wV®:Jï‰ÁüóHi	;„ùReÃNÛ<{¥X "l™‰şNp{æcp×ÃMõ{G5{H!wÍ¢}Ôpq¾5
Ë­@2yu’îÎ»°ª`œö¼(6âóz,d‚Pã%	·Û®ìfŒŸ†4	{tyÆ}&x2‰å½ôŒ…É˜Eé¶ÇÒ•r=Æ†*4¢zƒ¯
ÌU.ßòY€m~/æ¹€zuc‚ÌA2y4†şqŒ1Gó¨*›‰ã/í–´®;¬ İ½BW7I
)ğàœÖn#=2‘³`GÑÁ/zşƒşÆuJ;39é}¡ÌœtçŠE?˜ÏÆ EùŒ	°lK4_[ê°!‚F‚°=
'ër‚T#åö–îø$´üƒ²LNv1b{êî¬Ú–fA©b Ìv]ù©~¾f+ÿy£ìnT‚ğ[ÅcÌ·ë;±ˆ°&ğıØDF‡?îÛ•ç"ökÜHŒ¯~ıiÄ:ıÿ'â_ÄĞÓJXe†0^Uç?G  ‚X¬ñp—ˆ‹İ—_ûX@‘{Ñ7HÓ÷OzHŸÆ2@}?a'¬J¢{¨R{¾e€4Ëz[â]Æ¿Ï‡ÑI–Q„~ÉÌ¿Ùœ yKF¡uáùE}W(Rğ÷!2ç9³ÑÏTa—úYÂæ“ÔÒ+ãM!DÑí@ax1[—aë½.	w8)ÚãË“‹‡Ñ?¼YOŞÀ•=û”y0Hz	'x³¡Yõ·HÀâ±{}É~-ñeœ=¢—qV.òû…Ä£-9piÔ®Óö7‡Ï¥tgØ¥\—'êß|˜@œÚÉuü¯S»av¾ö (t­#h09ğŸG^¸‰¤Ó7A5ıPë'íBÆïØ{£9m¢Ü+XZ,iEu=ùR+bSÖğPxCµÚÅ’o<¤ÅA¹·TÕìÑ*ï¶÷Íï¢ôwYâ_Â¯©W¸Áú Ò|¥0{saŸ³“Æs_…MÆÆ#½¯õ:Õ#€w+I£Ò…y!ñ$İ|É°¼Cöşt“û¢,‘²>%ˆæı­½S¿İI€+wUqplÑqiÎtOÌ9%vª² jjÂE3 ¤çÕù\8xë¦cò0To^¸†I±ØÓQ7ãTíÜŞ9´¬ÆÍCÜ
~#+&ü¸v–ˆ®Çú“Êá£òƒße2Şùp?ı‡ğøZe²æ!„è,bÏ×—®tª÷ Š}Ô0ÉDot=Á›‚£úİéë_9½'Lğ‹W‰lo1eõ¼d‘ÿê]ıû§LJëtdq*&Ğ~Ì7÷ğş6˜M ¶¡®ø”G<£RtIÛ”Úf@	˜™Iç½¿Î•l€†!¨ İJQ WºŒ]´ñ(¬§t<Ê‚Jmë¥!ñ·eìâş«²YDÏa…ü%z=­Ùog9(ìÄŞ­·ÄÄğ1z²€ÆøËºR£³±°^şEh–ÈËü³€Ñ‡ä* °/ Oßq•$Èºª¥4µã˜2gƒ“³B/$,}_«º°¦µ/{ı‡Ÿìñ³lèö™O |ä^ˆd:/oû;Ë•¸ãcBN5Óe+8ˆb† ½×7wç¬Øé«¿>>M¿¨taHw›u¡ôõşÎ‚ñ¸·-"t¡Qí“F’äÖS"¸˜¹gİ2[ÇdàÌïŸE™L¸Ğ‡»”´!éÜ€ÌÈuµ^ı÷…ƒÕ¶o}ŠÔş.…Y·Q"ÿÂcò˜óT"Ï¯Xí ¿fk­pÀM®w³‚q%ŞÔ?Œ°Ö•dÁ“b¼ğºpp|?Se££òõ´èS€RÀ©mF‚s]dñö;ß,Bf§WBhÈnkuG¸ÖTÈQÚ¿pã°3É>Ô`Ø¡ä´#ï©,‰ŸmªØË‚;ö)Í3cı[|:i€µ7.Ø%µÂI Ùãïpñ¯…©FÅ)¹óq:š›zÂİ»FZÚ“®ë¥‰ÆÙî3f“Ö¤ï;NE‘7¯,ÏÛú4!½‚q®üš™òßÁTp´¥ÀYÛ…¢¡íu"2Ÿå%&iMè-ÒWÍ±D"‹¬Ãßv,Í^ô`Y™Ä1ÊHä7'Øo‹/±h‡Z³D¿ÊÚ:ôbbäê§ØD¶Úø_bÌ¬ÆXP¿~­Ú¯=EÖ‡GçÃ­‹ÑŒhê=‘êÿmüĞª97q„,†`ù	¤z5IĞ;şÊÈ$Ö‚\b»÷ö 1¿ÉÛŸ ÈêÔ5ï³§ğ¹˜s¯"¥2Ï*ºğQï²œ6ÁQÙ‰Û¢qÁqz‡‡µ“Ô§T’Öfâ[¼´·E¤ß-ÜÆÖ T‰ŸóÁ/êöË4£Ş¦Óh:Ê»R}±H	¹İå“Ş_ŞŞògÀñSåIBuä_ê^x'ïTàAÂhòõ±½}>¼XeÇw.·Ø,ÜWw"3¦„TÜ`z¥×?—A[1äK¿4é(ua‰Py?ÜÛôd8—j¦Ûy‡ÜáS~@•Şñ¼3Éò’/ˆÒƒx'S¿;y£•H–u¦i‡ù•ÍÕVä¾µì$áU"Œş÷·Qz¶¶²–yfSº7GTgKKÿİ„ "PJı°‹Ù_ÜúÔ5aWú˜ƒÑĞåø]ô¦Ñ÷Ãó=TË¾‚¥¸ğîÆßcíDæ¾µ\É+¢‘ÙvbÎsòú¥ui†š?Ò6.9Ñeî-í†ÖØÃÏJ@<‹ª|Á®¿A%°ÁÀjØ”©Ém»A'ÓS“ğRĞGµ,¨½†˜EUÀ,¸ö´ı8Ôæ"aİ-D¬
ÁÎÂ–YD£†ªtÅœùŠlèaLûdòépøüğ1ú¦qSñX?íj—Nş¦$Ş…‹ª†úHi@ı1—†ª ğšê
3ÿ±B@éè^0Ñ¯k,³:æÉ?—Ïhrg‚h8jt‹í9ûãÖ9ª»
/Vi§@—‹éúl­“›Ø˜å«ôóô€ì¶¿›Sæ`n 
‘)×*ïÌ@m3®RûüJrˆŞ›ØùlûÔÁ ujyu.N‚íî…-$¾/ù6“I‰ì.‘ún¦wÑ( ñ†±îÈë™ÈÄGl¨:²h8¦7+ì4*&,wŞ95·b¹]™í 58v;E¢İÁ^Æ`™ú…òğF¥pØè&¹¹Ç@™«\òû„”LòrÏªéÖZíL’‘G3|›¢.>ŒAb±ÃãéCctGôRîû°>R•½)ÂçGÊz+ĞèæğH\#=¼»ñ @ÂDTó¢¿ãŞÁ’úVØ¡9ï¤À~ÄB…Ãh—•Ø½3Åˆ\Ÿ™Úb²ÓÓÉ–ZWÍ¶ÓEU¶,\ÿˆÏİç¥s}z#Çw~ãÙ/u‰TlB8DJ¼lì|WT» 6aoòk¼¤ºHCmDï¤Ò;º"D˜B›\*Tã9SzÁºæ8Z“n¾zGıÎB3«9›cÄÂ=?Ø`µBŸççıµ$èZ|Y-^ƒCKªàP¢VwK©2­Iêf†,Á1UO•DË@wºE¡èÆÖb*ªt6q¿šBóê$j?rG`^¼ª¥“»}©Zîvd …_›`j}%›},¸‹‰W.Ş~·OÅGÀïKÑ™Æ—Œ¨Î°ÒÍC,­g4I²ÔŒ1N…vÙyePÄØ…ª'!¾Rû»¿òcÃ±TlÚóğÇ°CN»Ú® »ücW	wÇ s'_³iô›Æƒ×¹ğkhŞ½Ëº‰ç#†Zœk"ÕU®ş¥öÛÀ³&)o*oÌğ·O©!9Y û‘©÷ÆşœƒÆßRáÏ•`a³¢P–åVÃ+9Ûœˆû{«Í˜¥•¿èÕ©ŞòdÒë`Oç-pÚ¡¶ó LLìw‰øæÆöÕ[Z¡®Ó‚“¼ñ2Úß£õÁ%AÛvMÍÆ9İ63	¦Íø"€~o$Ñê¸¤C4ç°ÉY¤;o{#R´Ó»jçø³ıLVFcb¶²,ÚÊjéû½'ÃNúã©¾”Zşü,l½ŸŒ;ë¥0°ë'ŸÌ½ÀTã]Ê)Ş°&N¥wÇH{XtìİÓVŞR·Öò@ïãÎ6 ÌÏø7¯Ş«G¯ÓÆ]™Ûƒs(pø(¿ŸæB´çš[şr?Ğ.M2Û¯ŠËåSı;ÀÛòIy4HÏ–tÜòÁşô%Dü0£7yBúYÖ¯°Q©`OlQC‹¹‰Òá0J¼µ"”X‡Kün~oÏNõ.~‡ùI«ÿnY4•ËâÔƒJä„H‰ø¼T:ÉÄ6ÙĞíšB ¼p$ù0=ù*áô‰—²Û‰#ˆÜÍAØÃòÕJle‹Áõİd,øÌ¦2goT™ÀV±\ÙÛîÃ0Øí^ÂPüFYJú‡Äø×Ê+O8™E8îÕ©Ì¶;}f®´Ê<.İeÆd+Ç®×&À!®-±²Æ=x/Ë[¤ÈRGjdóâĞ=jÆ‡m‹Dß¼²·¹äRSØX Ì¡ñ/»&Á{4¨qú÷ES¿øVhQmmù¡Şö¡æD±Ê@²©²€Œ¾b«èô˜l”ÒÒå
KlXBTG•B¢ôİŞ1L“'4GFÆˆ™lTÜ»á"W ÿ•vÎW©u`õ±ÏªrÌ¦‹.ÎéšEbqúWËtMé&DÔà€‘à×U€õ‡_ÁäËÖ£[yù5eª>£;}€Ø‡Ù>æ|ÕY,¾ÆÊÑ´êĞBÈd´qœÅq^\Ë…×Em³¨üI½5z¾mãØ7Ç˜c1“hî>y³H’nş—¼ô%C@-íówë_fáÇ	Ï[»ù°ezñ—`Ò›Á
ùY&ö¸_³ @ÜÖ,¶!­¬.ÿ“‰.‚²˜$§ÃøïÚ-T0ğª_eÀæË/Jùs‘"oBšò%i½°@³­-‰j=0ˆE¶>IYh=hJ=Ğ‘@¡=|Z;V•ëõ«ÓGŠ.®„k1˜ÑÜ^ÌÇÚ•ê=F¾Lä*úã™ü
vB«¤;ùC0òØ6,IIOÈÉå7-"‚„‰z†ÇÊÈ¯¿J„6­—ÀTy.ûÂËÓKœNåUéèP3Ó}6ñ‰ÁCÑJÄâõÁVì—ˆ{‡ÏÑ”Ò0qÀS”@J•cÀ7S-VBÓ°çKè¤Yìş9§­	ôÔ)×KMLhX|Í+’7={BÏ¹m"\\~º7®)6z6Øé2vœ%oD›è½˜²ÖÁê®Ç˜I¬ä²$ûÑ·¥Î8V\3ã?Z+¾æB„Â¥/ç<‡‰Á|nÓ[8òç·ò@zpöŞä4IQ A¬Ãß©“t_ŠèÎ“÷ìúÜ©ÍÓ\bµù·Î•{½g²L%› ş›*6iæÇ¦8!ÂÌg‘Ò`>×Ik±3-„Y"?•îLÃ4ß«Œ
‘4K"õ\CğÙğø±ŸBa<4«g’Z‘¶p†gŞLşNŸ‘EôÏ¸XÄĞy6â¹ìtvªÉV~„)S‡Ù‰)qÒ¤6Ï~Ì!÷ş~¼AÎñRéÇ–ÙI©¼~”  CeÏFî§›ŸŞ•šFo½Û^•a¾»*õ‡Xa?Õwm<U-,v:šƒ-çÄ™eoéP¶¨!bÀ”M_;sH.Èß]Ø‹Xw“°{0½•KúÏï¡mEn§$-‚{¸H“3²{
ò€¾3üìù5V÷Ò-Ê×Ù,ÜÓhÒğÔ„NKæªHË•ò½CN3nnîtfÑmã>ÛL&8è ùGckwÒİY¯ÙPêu„/,J@àÚGuácÓ™!‚ÔàVÍ?İm!'°Yó¶ëòÚQ4šmğ+Ğx×+l'PrrÒï$+ª	9Êe ©:AçZ=œ,ªA«îpSÆ·>$ó9?çõ¿Ñ‡Ù1k­zEˆ<ªGy>|5dÈœWJO2İkG‘lM~zˆz6¶.gĞ\ëœ]DWÔ†xïjùñ!şƒ¼Î'Øjt`r®N>{@äp¼J~·4ş¡,åòx ‰É¶y3ï‚á&î¾Bò©—¡—1-föJk1îÕ™e}òÕa´+`:@aÉ[$˜&önİT—-$ŸÊ¿®¦°’àğÓ^£V:Æ+}Øåfv-Bïõ<R#İÎ"ùŠäxw-w¸Ú.Ë\ı3%Sq—4§zô§i)õ°X;Ç|ñ½O†è(Ğ‰B´î#×Gi2[}[ü¸2Û[åâòr¦-³öÉ[ß·ø\Ê’µîshL†¢S£öYc‘(,Gnùi5œ‰8­;M%j{l”÷:•æêGºbî32s¥;ÎïF\t—Wù¥ßµF7=ÑK‘ôÇ©ñÇñu-”d«ğº¥í6ßŒu‹©ùÎ›´&æ	23‚²]ĞRÂı51â­Sp§¹§åînyjG­XŒ×r|czç#®óåç{d­‰û¼!¦hĞ`÷:•Ãb ›ûJŸ°òüÉS@?Y<g}ŠÇ%2EB¢¦Ù€{vÂ›1êÇ>çÎ&ù}ë_Vj¼´âÛ»¼œ*D¡ş¡‘©(\“
ú¾< í“ñ-ãéø§@·¹_Ó8åË4'Şå]¿'æ"ÑF™|âIšäæ1·=°lşO¤”ÍZ–ê_TßŞËdÆ®Ğ¢Is,%éBÑÁÙQò÷’ÓT·6š5Á£¼†doNßî¾çêQ{>¾¸€|õ ¼U,c[¦ti£Úg,ŞÄÏ5ÖŞõè÷W]#+‹ÌêG6N•ÔKşMšÃY”‡ot7GÊ¢Lh)h]té*Ï,3*°@z]u‘ƒƒ—_¬tmß4x¢ÏTú–úéHb@dvn\¹•ı·}R'ã›ã~.´§V‡çq]ô‘m†™ãöƒG06°¬
$²†Œ:·8>$y<ïñ`¹…0‚”^³•+štPMP{ü£¨6£zÛ
Å¬’€ÓbE|5ÏK0…Ûà=I\R~ÈñLˆ„¼Œ0 ÔCOwDÆE;SËv·<j.©}2±Gz‚hUL¯l8¿p´#>d_`M
Ù9ûNŠÑ/< ötcíçÊ,?tËÍ&@~ìd-¥ŞïÃI1 7Ñ×ì;Å1¯ >™DËú9_*$3^˜áü¢ü¹=×P=cå	ø¯š²Í.»áØU==Oÿ5& »òM¸±®in$±›´ÑŠ×hø§9™Ïmîsùß¨¶õ´Ì(êˆ¡ùK&P«oW¸\Šÿ¹ ÓòÖôQÓ£>³Bc6’ğ§&µà•WaÎƒ1q2<Şø#:|S?t;ÙÆÙq<,#ÀÁqDÍ¹™~&¢èuéÎÁ vÂX!DïæUœÍÛ¶T$áã¢m;JR­g-3¹)ªRÙ3u©ÿal¨Ëj—ã÷UF‹a&ê@µ5*³©å,xRçÉsb
ehèr÷fG·vÃ·=ÿ·²CÔér°{ö>-ØG¦`ÆÖóéşè…6šC L(Ğ/…]ÉÃwVÂr¤ipx24u¥á-”JŠ½ãŒı»!F7|€yC^ÕäÚ†7™Ñ¶"ÛÅiÃ	Ñ­–&”HJúå©U|¿Ï"i'´ë­Î"ÆŠeµr³2‘•:ğª–ë,”ERyÆ kÒFkÓ5°ß
òÑG_SÑÏ_3ãqøÚÈ¾á#£&Ú¼¦å86å‡†á›	ã,l{ €fƒO9Ìm5D*e›Ë¤‰uÏeœ·Àd		LU†ä=X ÏÌ:U9Ø¢ğ€vªYÙH°"f.g¡¬êÕRõˆÈ³Ûxï>`_ßS™vÏ-¦zêÌv44hïq¥À+tèn[8ójD°äã€…K;/µ®eÕÚnòjigT-Å¡ÂÈ—VçvKšWc3Êÿå—  7*5šBßáú$N
A;hu-2†•`½|-¬û«}ÕrªaøoW0ßÜsCõ1dGóìE+@gñŠí­V>Ï£¹¾:E‡ıà}õĞ–E¦jÿTÄiƒ€³]ÿOÜŞ¥f_h˜M$²uáUÁ·a.¤!÷3Ñ[û wş®NÚ4&ï”ó³r¢O„˜I}®Å7ˆü&ôŞRªÕX'î¿Iò³N+ågFK%©¯öo™d&0ßÜrY¹¯'vİ2ßÆ¢<˜­ûEö§¡<,yCº[z'§¾‰ˆò¤mÔ(PÎ^S‰µê¸ ?îÏ¼Ø7í?NS½ÔM«J	Pvy7äZÛ-Âz­Ô±ïæ;3.^şiÇ‘ó¸?')Q.ker}›3¢.ÓÍe&Î– ı	#şºe§Å¾:<Ë\«kÀıj¡?UŞ6?4¤!ëNuuçõš|¡v:q±¸ÑDk@ÏÑ«€ê |­Ô¾ÙNÕí(µˆ$©UØÅ²ù;È“Ú¿}¥°˜¶€¬9"mkØ[	î7!z¾ÂøfŞ‹˜'oåBz…5\"¬3PÊw´œ2B'Œ–xÎó:T¸ñD¤íÒÕ'|o³IE]n×óOµß)²…–"¿ïâ˜PFƒùœ“&C¸
èopZ\=Ø(ãPã÷XHzÛ“åmnÍÜ–ÃÚŸcVŠKŒcï?8øU¦–ÎÅ¢"Ş±G	¨¿bsÊ©*	”ğÿNH¸øs—Øv×¿æÎ{ÙÓ·ßÁÓJ±ö§ğ¨»n7·
¡ÿËğgùôSJfu¿î’—_:ï¢ZìBBñš@w€§Åµ–â6§0TNº2s‹"˜´¥Šx„pâş[ã¼ò¿ê$K|ÿŞLÀwaRJß†2ü„Ğ?ùYáP$x®EÒ,œš|å[Ò3è¢£÷Œ¨ë¼¦<‡L üy QÊDvİ'8²¨#G¦¢qÉş˜¹Œp/ºOğ½Y|jfõÁ®Şv8È›x0şÂSÆş7äÆÓŸ ‚q¡Am[øRª/ßošswÇù9¬v#æîxP¾¦P~V(8ùÛ’>T†rî½æmÃ¶"L˜­ü9+2¹ãõğË"mşÏµxÎ+f³=½„Ù”»ÅI“bv,­:>–ÌãcÁ›À¿/| ¶ó’¬e˜"õ©¥Ú$´Æjß¥Ë6ÊoZpèâÛ„qÿ²%QĞÀ%‹ì†–±h¢'û*Fk?Ğ¹f9º+‚>7)Oá!°J‰¾Û’µh”	m\Ş4áïp™u»ÎÇ÷ÓÇ_³ó];¶8%®€dÊ&iËûÍ±7K!)ìª…Ğ/oc$~g$Ğ?–ŒÜJ¡ˆ‡…½`.öİCôÏ®*Ó€ŒøË¯f<Ã)ï,WêÔ5=ê	¶Æ—7ÉtRœÃj]:­'É;ºÇÒ“¬RÑ ¨ù%ÖÑØ!y8şWÀô@†İÙèG™ïÎ(ş%åVŠß°Ê&W
%µ:\âö6—G{ªbø3Ùb;q±™Ê7œp‘¿SÔºµl;rºûåA¦X&“… ¹Ui\«¾4‹<
f>epç¢hxùâ±Ç‘šhö?¥ÏÁ¢£àMíõ§!ÃjO:ÅnåÄì½É%¯~‹óz"ugÁ[‡¨q4“?Ÿh‡ñ`°µ¡Zä°§pª¢Ãä›ãZÊ¼nšµNÂZoä9ÿÚv$	\“RPÀA4Eúõ“•€F&È€……“UòQ;¹ÄZKÍzqãoII%’DRWggŒ·Ë3kÆ¹ÑÁºˆÖr¿¹í“»¦ŠÍ<=U
?ª?cÜ­vhf£«Ë:£wI{”ß&Ên`.Š„EOMôÏ=DŞ‘†nêPÒgÌ\”¡¢Y=®i¢^dk…gAèÍ@r÷$Œ‹Á
_£ÕË˜vİ3ì¶J~3Ã6½Õ¢FÓ2á†ÒKãDÕ
”!»8›ŠTveDb
(“uRæŠ&UƒÔ‚ø£—ê¾Ä!OìkANıÒƒæ¶™Í‚Î—†U8¾QPóõËõª[kÇ
ˆXjYMõ\t\M‘Á¤×/¢Jy·I-Áš)JÖjÙıÃ©rA0±ÿÇìß}RºNÍ8l.S±L2cµlZ„©@õ|ùíM!ï;T(,e¯ÙM—ÌJ+<ïƒî®Ÿä¤u9Â;IÚÙt§…@¡FÓb~ œH(92
ÉÚx¶ñs³¼ß×æ12ÓŸÄ‡{³¸ãgYh‹ÅuİŞÖåÁv¸Şa[¦@‚ŠØõŞ ƒ>†…Ñ	[P0RšOu2‰Hi°uBğ•ÚŸ²ÁÙ™Ş¯	</s†ÇQsÅ‡WÂ[[‡f¡|kX¢G§J ¡š¿g&u½acCX^KÂHÇbs`!Ó‰[¿JSù¿,V“/m°-˜9<j{)­óD]jl!Ãëu»E¿®vX*ÌŒ™Jğƒ,”¨}Û!?ô5Ç	t-a³6â¨É?šÀBR)Ûÿ\nºê×„)™Í4Ğpû×EDò˜ôÔcR	­'0nH)"¼1l_ àŒ¹õäİ`4çr¤ğdñ¹‚ËS$´»ÖÂ<—ncu$ü”!2c2xyÁ9ğ9WæƒgÍK~°£¢p%ó9•xR×¿ÖÌy;L†+|O#(ê¢p x¢—p2ÍXêî|¸$š±‰qª´·ÍTê½ ‚	dILÕë7o§eŠ£ù÷y‘µ-§H2ç©EO=RÀˆS#½õåá®–prÉ¬_%İ`VtÆtšŒÒ§Sùu‹Äo°eÉN5¢{•¿ÿ½#*»î>®¼çËÇaÃã“oYk(l›¹B%ÇQ—pæ·±P¶U Â¢ ƒi8¢+ÔéDƒp±ÄÔ˜ú:ï&:s_ğƒÒ`“J¼w´¥Uï²#Y
-5†´zær·èŠf’‚
($ó(sâ«ÛÙ…ˆq‹ŞO´ŸßùfÏh+}õfÆÙXŠCÿè±'²©ò$ÙiA’a°«÷g|ØÜ	¥ÔpïI^S_˜ÜÚ¿âœU†z+AøYƒjGÉc<õk©\P„#Pš±ÅÔ8™¨bĞm,´Ä|	’sÈh6ó{UÄÎ•h™˜l{¨[<ß»ÁSF)Š¨Muô`?lE6JUgeFä’M‰¿	ØJ£ BEÌL‰¶\L´¶&¦‹jpµ)° $Š¢.PÑ5M<šU¯†x{>H`b€–ğMÇÇ½xÄ„E7ş´M1ÔZ‹~ü:¡üFÔúYNË=·x&Œ<§lH¥ìÿå™ÜÏIwB}ã>Kïİú×§.b\c‘Ì%°0SÁ„ÆáÜsëñkëğ`6Âö³LyçÅh8òS•-ŒZÁ5ü£ZaYïÍ^ıÕ™’š}RE0X)É¡)«í¶­" 9FÂ(Š¡ãŠşãâ¾àC9±+:äÆ1ú-2ú` ‰è[6•vHÉºã!·M=8 ç¿•›óøQïÛaÍnƒQª÷½¾É¶v¥vˆ–Ÿ^rÈıPû	½w³¦5][ƒğ¡Yí’"Œğ¤şË4Ì,S‹1«XÄJ d]:·öå©ÎØ÷Àk.ã+˜>odS47´R~u€°dÆ›j1¯¦¼§VVÈFÀ¢¦g˜ƒ%¾jmPfÀ\‡i>á‹1ÑäØ×#[­ÖJ.~Î¤`ƒ±=»gü›‡M]ûøI!/ˆÙÍ†(¢gå½¢F´ê„ÇÛüˆö#3EmS
à'Tv¾Å³³¥ÆäÏHªˆ(¼E(R"R~JáÒAo)|Ö$aº‡‹¦œc×ùûÄWp›wÌÓ`/Ú4æšU“¥ÍÈ úôB»ÅÕ.×
½ñ ×–M?…àåÍònuåiS˜y?:xFŠÍ3QšYzŒ^!‚LÇëÿMˆ©6ã¡lÖ’E2ùñçÁÒØĞpJíO„ÅÜ‡ äí˜—Ğ;ß†ñÚÄ„÷	VSfÖ¦¦OAu
ö;­ÈÎ­&Íæ9€ô&ª~›ùĞOğ12ºÊÅ¦ÊÏo\¯¸.”Ê°a™dˆIyéúüıÈ…úLj>xŞdÓhùw ÓŞxù•P¨øÅ5@Şÿ±µÃø$[$	åÆ³ğ¼ÍSï¿¹t‡`	›/€ôFJŒchÕÖ™±%±˜,‡ıó–Ÿ#x	nämò(ìtjâ1ŒÉ™_%°´Ô¬”ãºB¢u5s{^Şg‡–=#@©ÓUdeì¸¼§:ØÍÔ
?µÜÆ’viK
ÏH"jÁ³Ï%FGà¡lãmwÚù¬{ıQgäê}N_qğ”ClŞ#
ó4DĞÈ§Öº–„/NïÚ8×–€	;µº¯?9†ízV£İ(ër	ß¤¢Ùt)ekÜhºª £ªÂFñ^¶F`mDÙÌˆæBûñTÌÉ%PE~Ê
êØ z1<ÿ9ÿ@/“‰·9c‘¾¨}5–õ½ª°îH4/ápŒ†
«õISpëRüØ³|<“ì;ü
ùz Ë=i“ªÈŞ7wóÊ±²:{„/i"ÂËîR°§bä–é.Ze¶áfsÓt†ÙŸÓ=Ašöİ~ÍEoª)%›ìãµÁ U†»K¦ê6ì§Âı4„£Àh;)³ªpyï{¯ù‘VòœÇêqtP½œzÆÒ«¸~¶˜Tvkÿäpr¦TõV¼.	sî`3ÁYÊÕò3ñë}…;ÎJëL„Šç>‰âF0b(#º ²hş
b@hÓ~4|'Ú^€3ù§÷ti5 â›„&(›ú'ÄÿP·gQˆİá>ùàsœŞ>mÙB’›Óˆ}­/^ mÆd‡ä¬ÊoŒÂ ªbBr„â_¿î”.º8ëËÏkûå’t=×µ%¼ã,U}ähˆÕçpQÆ*|~­ƒW8©1ÏuÈ>—„ïñÌ}¿a(Ø»Jü5qˆ»a¶é°ê´K›*Ó@|‚%ıª•{È{İ\˜H\+ùÒ;ßÀÖŸ~q*¾)|R ²İág•éUøèà’W´giÂô±]³’½*ÃİåÎ~#«ß_ôDs7Î{ôjÓy²‚aI’ÄÄæª|¾×®K<ˆA*B°ó ÓÚ0Î¢™ùf5!ó¾pÓÆ¹Í=1¢U{²Šp‚N¢˜ÄR#E¿„D%×"6ôqS¤ñ sºS30…2ãóæWÙ}pÍÎ‘ÇënzQ@·Ê¼Oeº}¶$ÇzàŸC~³ÉÇú³ŸşÏ{Î×®* zsñaN=m,ĞT@¾t÷®BeÆ;¸²öµc´€Õ»2¤º«èÊo ÕàEßE!Mv¯ûèş!à,ˆ +½N|`¨¤hE +Q‡K>á´£ÉCËFYÜ+[ĞØYW&æ^«ŸÒhl½¼FšŒrÅ&d Xÿ‡%ï—›L«¿]Ù{Á
‡¡˜¶¢zÉƒåŠ®š÷µ®¥<m/åârŸí iaº}±*T(….Ù™[|¸íR¬úía¨úï·È:šŠÍtñ0öMe¯Ô«Ç‹äXa	ıù˜«_Ág|¶D8Ñû¦ùVCÍ	C€Ğ¿8-1ĞêİÇæ|º+që¿~Ÿx&Hp«¡DÂ¿¶5U“T˜V¥ÃA‚âÑa7jÍ÷â~›È1ß¯«s3#=H‡j|n]­Œj/Ó~ïÀÛê+5”Ñ}P.Œ‰Ë¡~q/-£S
Ò½ÂTk¹f«çs¦D‡1Ç,È{Ò+˜uÀéa¢)9ªñxf0ß¦•˜-|ÏÖüŞR]ªp`
:²ï+D°EÃ¯Yø%®ÆIPêâº<)œµAMÏñX¢E¬aq­tÆ×´«àu£—fÀ(n6`;¥z3­Sm{-Öûç«
°zY- ¨ñøŸ2q÷¤†O1aTo3ï¡¢!°:¿éÑs<äê¾íŸ¦Í—½
Ş‚ñhnåàD`§®@A	©–µ™½Ç¥ƒ “÷Ä0åÛ
.À,Œ¹ .è·_€Ióäü`7—hé½"Šè–æSŸÑt4˜Œ®¢fÙ‡Õ-î²ÓB"^×n¿5`vazÜKè#±î§ùŸ6ÏæØ™ø—Uú|¾´Ô•Pè¼^wµÙÑ	Ü®‘^è6³'«t™S1KÚMeö3j¯:¶Ÿc:İ_Õºdâ”qö¯ïYh.JCû.üb–¸ ×€Uig’{‘Àåã¯“Q©¥Sö–•ñQı°éî €Oèğí)1_ôoï•fß%ì¦¤{2˜(·Z* E…õ(
æÆ|Òù8ì °!m[V”mj	"ËG>ç;KV•:~9¼‰…½æÅ>ÆÚ~fåZ.òƒBu²¹]C*Gm2¯½‚–Cx~/‡ÑÚ´Áå«áµr*0C¶v/!š7o…äı7¨b Ñ3=êF‚a×H*EÔ­3 tvo„†ª-‚_=b´âËøXÃ¸F
–èôY]ˆ¨Úcƒ‹½ñ&Ã)K'îõ+•¡ÆAÜìäc¡£™Db2Q±!xF=]ÿ¸j§B´>¶E½°Úõ{¸@­›æ$¹@Oº¨[1›=9¹EÚ™[Ù·p‡îŒËÍhV’‘%Ò	ÈäF¶ÉÈÏN´âe•ÛÁÚ9*}‡æÙÃÑí“å¦¯Â±ÏR¥ usë[Æ½tÅ,t¢è‘êü£Ú1DóR‘ûÖÈİPã:æAq‘Ú­õÃ½=·á4·9ÓcĞåÇrM€i	*dÁrú@˜Ö›µ»ÒóëÍÁíÔ 3Éğ?hUK•-³-ƒÇ öş¬å“OW€1äã/¤Oà9Ënç‹N‘kª©9œÚ tŠìMÌßØÍìº±7j¨/ÿrqßğ±/ãG¨s5Ü4‘ àR¢wZX›6ÜşÀÙ¦{*–·í%?….mü?İ Vàz,Šy#¦‘Ë#Dá*3ÇÛèß@á¹´Vò÷œih4 a-K'¯Öæ…|ÀÂé‡t]PD7Ã‰~ªÓ×@ZÖHeH0ñ¦·ë:…¶›/§:Ñ$Ò@PI50-çÏ¦¡n,SÂ~´±²Ôâ?H€Ã—‰t0>Am¿!A7 ËŸú6±8Û·Æó\ÅPEİLø²—“ºƒô¯ItUç ˆÄLfÇG&—=H-K_úu¿ò»Ô$lĞBİ6½Ù¦‘ø”raş(é6 ÿÁ44æ½XQh_âG·é¹ŒŠë¼eê¦…“‹i!¥ÕÏsW‡“ì`;G"ìÕD}±Vj7=›pª†íêRÛÌ lÉqY©"¤yb'•~$;:OÄ$X4#
•Ö¸ñô=ÙÊ'IŸÏÑ@w%ğòë	ó“0\À•Ï@óKºÁ$íÓô7©®u÷Àó'’zdx´ÑMJPáL)Š?õ;7‰ë+IlÕ ³i‹”º!ÕgFÒ±Ìu ö¸ZâAÃ†seâÚ…ãÚÂ×–-#õõÀRç€¼ÍŸ@»+0ZzP±åĞ‘G ªƒ?jÍ9†Ü¶%—şh_$Ï*òµ‚p‹¨å_¾VSQo»Îz…ØÙ-#Ğ2±¡4ço_ìkÏc.>*9ŒÒâÄÌB*º®Ò’åú3“ãÄ-ê	@Uò¤qÉv†-z9±y†lö}Òs©¨›3Vh*ø:ù5’Ø†”Fô0"Š÷ogËúõiÈ©?›»««tzH
Ü ×ğ.ÄòÜÑ,QPÇbJ‰$óöÙ5îÊØÛYĞÓ †~Ù8•8‘ ŒwöğùO'lë‘ÈÈ÷¤î¢wˆçµkÄ±Aºdäª“Ä¡(%kË•)‰º¦K ×^r©Ç™tÅŞÑS¬^ÏQÒØ¯Áœmç™Æ”_òôìµlS1fyôõJƒ(¯·]4°3öJ˜ÎëÀ õ6=ÎÍ(ß6; †§9`k[‚Æçd¢6œ¥'sÛ«¦ö»·LßCoAüyšZÕ?4M‡X‚VÖs›C „Ğø&Î¬JCÅ‹ûÔ<8Ú/ÅA-0àk›Cr6^­(æLyÉ…ÏwG‡³¶¾î‹+£áÅ(cÇ1“ß(bô€œ—I5m¶í½5 ÇUTä<8ı¨=a­#¸2é>×A™ÇŞû¬ı?0¶Qùÿºú:(3ãv¦ì9¶ø9€;]	pq$o¤{t$ºKø£˜APæ~í§œl³ì©.	ƒeHI/ì‡şõálqùæ!UxXe ¦a²¨Õ†cÜ@è3;lş|óf2²ÔâüÜøÜ™!x°<û!AQ—LV¶sòïûwièFJc¥›	ıpu0±İôl8­ú}SûŠzp´šm¨,Ua!ˆJ^Ò¶vÔ-çR¼&¨çyÕI©u^g®gÄ §`DP	âS[>¤İÇ[<¤¹Äm¥$O¼Yk‹;:Ê8*)ûµc…²ÊÆ6&¹<t·h @|I€;c„v)fŸª‹ÄÛ‰hXŠÔ>JË³¸V¬5Âf®°Å“ùÖõ3bÈİPíAÈJÀLİ?ÊRDmw—Eª
J­¤ñ0kÊÑjö&Œ¨uòÂ§ŞrZ1¸€~<Î;'ª¬²E×p’‹ÁT"-¸Û£uTÜ9±­×FÙüï0Jà¦ ·½Xn0ö§f…¢~JÌd‰FÓ:jøâõ­F10òOŞcÌ3¦aÜ/V²†{ûI| ß3³³ü;–Kì#œAÛütÚÖKÃ]W5vEğà–×¢¯kF<ú <Nì=Gí^ïtÑ	Åe_ˆÎ›¼ø©dg˜Œ±<ÄjêA0ôMÇ¼.¾[1c•v‘æöæ¨5?ğ¥ˆ$ñ[XN¬k¼¶éÃo´æÉ /JL˜k‚*P Ú÷Jê°äü–ÂÏ^áM” }‹•‰¼Ë2®«8¨š>ksQÙ,¾g5=èÏP[b@™¤øUZ"ŸUÍ¹’ºİiÍË×|ê_dbºE<Î6qVBÌ;÷ÓøÈélºk€ÜÓ•kõ’Ï ÀYî± îã4ö„~Jß6
±“	Xr~Xœ¢ê´ú¦ìh˜Ò™¤=ƒuÏ‡Oºlcôe""ÄÓóÛ 
‘³Êİ ú‘Ï\Š@’î„4T´èP$’6íS€b®Ó¯­ï§ZÈ
òK`…­i°QäR®Ùbîì¾—#µXX=K	ÿa—À³Äë–K :…ˆÈbê7aq¿Pi>áÑö œ:¾0 y¢‡(`ˆG•I(`2œ!5Vó¸q™ßåı’ŠÌ*Ø¹3.I1v# é±7½¼°»N«E¤ß(é&¢cê›Û&õmÒ˜Ã4Šu~ŞğK‹ã:å²™S­Äœ¿÷³²0NZ¢Ã€›,³ŞÜFÜ¾1NˆëB|O±–¹KÓl:¡ !\]`D(0-Û¡^§uÖ)¡ŞU[2]\—°cu-bË.$d™v¼õÃÌ§c›ñ‹æ×¶`RœÌÜ’2ØQg±—½-‘Ïa¦³@x%h¥qäó1œr}ºNÏO€cùæ4ÒĞ¬Dà©5ân½Ùí¼†İ~ë‡ññaÜÎ/ïEÌ¡-RØ’éK•ŒEïƒ6*o£PJŠtF¯”{EçóHôp¸öŠ‚ìpççs/¹£3GÁÕqÜ$jk÷DfÄÏğ9ñšê)Tãl´FŸ³~o®UÿùrD°Ê~ ”{ÔMùÒ,Ay›(“Ÿİ 5ñJñŒ;n–5i)”Wã5Ş2@j|Ÿú2Dô»ÌÒÊjnï¸†ëàcÅÂø¨#‡ˆ+XlªJßaB±ºfsÌ»ÿ&ÉŠY¿dõ¨ÚÇ*'!JW19}½fµã7^ìÊ×WæåˆÈ ¡@ŒŸ%&I‘ÙQ•­m'³·Í>»dQ[æ@MÈ e FÛÇvà&AİœØ)'•à‘Şçe.àoãÄ`ÉK;ÚhÍ»×vû!2Ëv-å#ÆVÍÍÂÔM`LYídàæ¥ê|Ê7˜ßYS|ãMQ5"Rq´ìÕW¤ùÂle>ñJäN’+W¨üæ.G¬Dâm‘…X“Yí_Ku—H½¢€
âVø
$µû~©N“ÖÑÕÚló—«ª¨öË¾Ÿ¡úˆ?6A6’ÛVWŞ£é)y•­RhYº³ªM•÷iñ˜šÊåP@ˆ;Yp4õü›	–]ørêI0¢'ş¢-3¥p1â$¡ègóMnÑCÎÍ}Û{p©™÷âÚ`½ßáœ•Rƒ¹ÂkgnäuÜne¿~:êì‹a,„âpÛyM6öOŞ±;³¹„•J°Õ‹ªû­´_€1ñøšÖoº=ıUˆîŠ˜¼JÙõK°Ê>¡ àÏ$=÷])X!&dÇP•Œ|1í¹Õ,äÏÏŠ¶${P™šŸêFÇŒ’Y—EåğõóÖkÊ÷P\¢j
¸¦)ôÍV'Ğ.ÆÉzÅ
Ì¢QMÈşœÇÌd:]wÅú5“•âÉ?‡ñQ{¥Nÿõ’¿şVEïáİEÉ!]åÌ¬µYrP«X/yÿ6 z¾òËø –Pİ£—wš¡íßizºèâNÙÊ¦÷LŠˆÆdlÄòKbòÍã@›Å.é¹(S_—“¨°f£¬Z}’¸‚í€¹¦³‡ìøÆ’ç°ã¢¾BÓUù`kŸoü¿àğiê¢e5šêqåÀ£˜ßLôIêTt¥­ş¥Ü¾#q4ÒÓ%B³“%#8“ RG
QÍ¢‚nB¥…f~zèx.–ĞdÓó„Úñ_¦í¨Ã‡ö!ût:©-‰×#ÑÀ¿ğA¬'ûÀ¾>¨à¸h£ÎU	Íœ°pËî?Ÿe >Q²Dz™øW>ëæø«Cİ¬w¾uõ~€\Ôô„Û!I&C©¢ŒÄ·+£àûØÎ‚îùµ Ï[ëRˆ;’ùXáï‚ŸV¼ “.ídÕCÇâ˜|ÿÆªå|‹Œ)ÖÕøÈ4Dñpè¸È%6êSÆ?óİ¹´F$úsæ”.qYè»T9™†­_ÙÈ¤ £‰û/ZµHKøeLJÿ¤![¢Ø¥=N
&€Ïp+Z½Wyœ±1e
/AHŞ‹ûV‚ıO°ÍSæTd÷ŸQƒ šHÑáªz3x‰¾"ÚIHıÒŠ¨Ø¹m\WòA4	‘b[a`¶ŠÌaó¥$]GŞãë÷\Ûª©V©Í7bƒ›Ğ1Ü+Xµ(v3Oè–\$×ÅæÜQ.Ùâ‚4Hí†î·ÒºxeÒ*XT‚ µ½0¶®\²±O\ÄƒKğø„TtyÜ¤ú¼¾ÙÅR¿7ÇYe®lÌõd…8t—õ°¼uô)+GM GÅ—~)QÔ2ÛI4N >Çÿ$^ÙSPßö/h‘IÊICNú<1eõkn_ÏÓ›²Ä`¤ÆiB„š¬Sëç–£PŒsæ„Ëò¤xÊ—øzÉ6M\_+SÚ1Géò~¼92”EÈrı:bå¥ì Tè©˜³tZ¿„{B-½¹u
kG©"%ŸvX
LÊ8;82]{”Àøûõ’üi©ˆÇà®»ê~<U­C0÷İ	g®8ËRöK·bÎÖóûD®?›#²¨ƒYäq®Æ‡í„1	É“ÒC!Y¦Í¦ü‘·¿şó„Œ€MöSé¦°·Â³w&Ks¬?[ñH!ÑÄ%Ş¼©¨öZbÛB©“SÇË°Š‡S®*nêÀ-ÆÒæsO}½9
C'Wé¸y„¥[5¡Õ‚`ó1”düÏˆbD”êÍé½æi:ó)Ddÿ¾ù±ÁxxFŸàûœ£Â)|Ï:£ú&f²·¿G…û™¹VY–Gö##e´äÜÅèŠôŞ©éøY#a1»™9ÆìSYg#Ú´àšdw¡K›X;àÉà.\*—·ş¬ë~“V¯±Q>R'ƒÙÏ¹.X!FlUŸÅõ$3úµ†M¤ĞJ¢ÉlVínÖÁr°ÌOä%0Ğ[ÿı×¸r\IÅuU CäF9­¶Ÿœ{W¿åŞè ¶¹Pºç‡7â&ÿ0™Õ¶ûòßú$¸¸¦À`½öÛáîî’ì­-Óş(/%†³İ9*´åÚÜŒƒãCxAØ¶­'§Ÿ€²‡ÑB­äIBsí´Üsa»Ø?	¾]ée7)àpİ´KáEÀüOÆ¼¢¸Ò<0`l   I.5Æ‘‰
 ¢É€_—U±Ägû    YZ