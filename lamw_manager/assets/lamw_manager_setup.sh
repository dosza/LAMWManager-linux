#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1755091843"
MD5="38e0f59de8820cd0b61df6e2b0bf15a5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20449"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 18:52:54 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=124
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ ¶ûÚ]ì<ívÛ6²ù+>J©'qZŠ–í8­]v¯"ËêéJr’n’£C‰Ì˜"¹)ÛõzßeÏı±°»3 ?@Š²´Éîİkı°D`0æ ëú£/şY‡ÏógÏğ»ñüÙºü|56Ÿmo?{¶­7Ö7 ›<{ô>Í€G–éºW·ÀİÕÿôS×s~1š›®9£Á¿dÿ·6·öc{sûYØÿ/ş©~£mW›ìL©j_úSUª§®½ ³-Ó¢dJ-˜ŸÇfè‘ƒÀcÌ#OšÎÜÄ¬)Õ–ŒîÁÄ¦î„’–7÷#èRª¯‘çîõúf}S©îÁˆÒX×ÏôõÆĞBÙ$°ı¡†g”¨²´«ÄfÄ7ƒxSBïÄ(ş>j¿†é9PÏ L Á&¹Lß§™zQq×!ÍvA”œ:;S¿
'zé{@û^ûÅé±<6ûC­=U“\Ìèø ?êœ†Í£#c‰dAs¼Õí·5m?´G½Ãö›v+›«}2l÷GÃî¨ı¦3Ìš[0ËèEsğÒPQ®R5†§ Vª¨·:	½àªÈwØæ€*ö”¼%ì[­÷zO¯×¢’÷»¸s®R)'‡Áü£+ jë«:®sÏßæìäÓ¢Lme5‹k¹Á%„+¤„¹ È·fâÍç«±3Ê·FA1vß0t'°-ÊhÒ¹¿o;”=Y»&J%á•Î}=]Ÿxîx…¬"Á|5È.¬ê&lÑÉ9Œ5Ø÷¾{Y™Óù6Gá §Œ6€v @©LÌè4œè³À‹|òW2¨/†Å¿¶Ÿ‰nÑ…îFS]ûùÆ ëÉnÂb*Ëb×P*‚:>÷¾cÎŸÖ¥½0 ¦ĞÌo¨ 
?÷m×2j°Ã“3duCMhQk	ˆZNQ9Aé4¬ë\í¿t=E«ß*€ÏÅ$ô,xÈˆ;€³á7X=¡¼éÊ2¾ó‚¨ù4E™Ñğ¨Sëx/[)àÒÈ4¡²¬†µô7Ñ.Õt¶~äæuˆâÛõÄ¢S3rÂ5@šÙóNÍ&>µD)kOS¥’u¾ö§•³ö<Çm8´C1#<ŸÛ!ŸÓ?§—tB¨» {Aï¨ù«Q‹7ÍÓáËn¿3„¶ì7ù|úWI-gÙŠìåÂä”1 
ì.¡—vHêõººPÓJ9ü:q‘;A'„ ÅõãŠùJc)Eá"¹BI•J&	‰djR Vâ¦X67…•t[ycLìÜ´İ”RŸ8Y†zŞ÷¼°à>•J¦‰±Àª±@çû$êÔD™óy~«ü1ƒÉìŒ‚”®ÈJE6° N>,‡oEMÚXòèá³:ş/ÚîŒ ©U/Ã/ÿoom­Ìÿ66âÿ-h|ˆÿ¿Æç¥w6)b4g“v”Jƒt}ğ|<@›ñMV~E©=Ç|è÷Ü°aìbºŒ¯äSK1 ò-ˆÑşõq^
ı ˜_Mÿë¨ áèrÿü¿±±±UÔh{ĞÿÿÈü¿Z%Ã—Ùïµ	|CÔÖ=n;±ıJZİ“ıÎÁi¿½GÆWù(	Fz™›WÜÆ@àE¼(„0ÇæQXpõ=Ã³éB&	±O@æeOmÈI ˜a|Ü˜Çca=_XÎï}3`"ª“•bAxä×ƒÈUªò8Â'š&F[Ô±ç6†…Œ&“;×¹yNu¦ÄfÏÈ4ğæ`@Ğ5ƒè˜NwÈYúlG×“auÛÓ¿NQAÉêrVóN{§A>CÄÊ‘å—¾é2Ñ™	¯¢Lí€ÁæL&Ït(p¦NŞi‡a?ğŞôyESòV?ì¬ò×´ÿ¼äğoVÿol¬?Ôÿ¿æşO°ğª#Û±hPgg_1şo4[Kş³ñàÿêÿŸYÿoè›«êÿEA¿ç@.H˜xnhBêC82ˆF|ÛÁü; 3êÒ€‡$€ÅvÁ/âQA³¼xNtÒlö[/··4Òt­À³­¯äØ•ªEC:	MˆQp>şG,LıIœÆ™–I\ôZë&–åÿØæÂ¦¼XiÎÇ6¼ í÷ZXw®(Ç›àÚ,MFíIZ	¶‹hİ¥á–‡òS8`=/¬>UOÇ‘F¤ñC]}
€iËŸ#—^Œ"0rBÆË®»»|Ø‘íF—äb(Òøñş#)3'JJN##c³¾^_Ïã9í`¡†šDdláÖ§…È¢§î3lÒ‹zhÎ˜P‡âÑæh}´®J˜ Ëè¨óbÔk_ª±@wì1äPU	¬µ€!Dã¤Õ'ÓYe¿}ÔnÚ†zëÄ¯ÚıA§{bÄK¼YzM©f\G[ —¶îµ¤­[—½Ø€$Ë¸üa{šæ  h37ZZWZà¯rq ‰!(Í\yQ3¬ôx
ñÇÕáÜ•aÁ€\t)yûxãÀ™áÇ‚FaPÀaÑOÍ	|N˜=ü§cO<>w…àÉä†ñ©Í¿ˆãİ¾øåÁŸ.I¹„ß«Ø+ğSÅkã%İ•0¢º´ß´Áì\œÙ“3äöüTE“±­Å•rµ–¤ƒ¨êòÙI9æ"GµUSİo®û-ÑáúE‘^©òŒ7=OàŒ‹*ä»´BBÈOÏ•e8<AÂ#p²8İ°zrHRC>ÄQXìÏ±–ÉŠ¶Q_×ÆàÔl´W»^jûööô&‡:>Š‰ÁşÜéÅG¦[G“Ó7£—İã6vfBt
ËcH‡„yğêdØ<¸áÆ±dÆ›º¼WuĞÇúì7µdu© –NŸÊåõòBoJ°áÑF,×¥ø Ô"ªâ §„uKMy’3ÇP[^{ˆxH‡ğ‚ÊêQ ÍÅ
äÅ‹…	€PLx¸¢¼À¦Æ9Í`.NyÏLwF³sû¥…Šİ"%’uW*XÛ °ğè}ÅNƒådş#©-“Vït4löÚCÃØíU³Ø>RIwö‹ˆŠ´úİÁ@ ¶|€zõ¼I´ÖôÕ~ïÕ¦JáëõÛû7îLEp¡Ê—3€+…2[R©dw$qìö[mÁQIÃ‹X1D¯ŸÄ äÃo¶Ÿ°Díõ„¬¤{ïû“Ëmî#ËÎÓ¹­‡‹× XÀ´—İ›}p‘vxÁÙ´LÚMVŸÚõI·Ü<ºQ‰°Z6\±U*Yb‰à«é±i­TûU-Ğij¿].¦+¡*Éú2ö/Égö—Up9³Zİ—hD¸•ì².4ƒÉÙöV©>ÜÇ•l·´Û÷Ğ“Ï_"ùyíx¹¿$íeÔİ&P+ïgÜCŠ&%Éxô˜£™`)™Xá¦ÜÉŒ/m>•KÕOÛ>$ù­ÃEäHNö\Ğ¼ØºÍñm„?l¹cH6då¶`æ0-^x^8ÓçÊ–\ dx¡ÁEB*q{Kj“®ºì5Fû]4šÍ“½~·³7Šå¨pçAÆ)Œx²æfKT_¢5<qv	5‰KàíŸCNÎƒÀó’!)}9oKb
«òå‘„X‰]½,W*ŠbÒ3'çæŒ
»×Şoá¥¶u˜$ì¶kÑK~é%	Iíok¼ïıÍ'¯5P&~¨²ÿÛ×ù5#&n‚0Z6¸²?¬|{ıwk{¹şÿl»ñpÿûÿqıw¥_ÍtææXÿ%ép->o,‘ø{Öƒû”ùËì±Cym—#ÄƒŞÜÅF]<&^'.+áuµzıëp»¤XÀÀğÛ¡gÎaMB©Æ•,“ßµ¤êx>?hÿFÁ!ınw8ÂşÌ	~ƒx-q	ƒ½C9¸˜Ÿf¢ù9 îøèt8¿Ÿ‰—EÔROâ¡Ì«L+Ó@oM®‚Òê{wÙÆ{”ÓYF	Â)¹}~\I¢’ŸùîùºCêš 6Í½¡wjÑç&!~`»á”<œ¾ü:¶CØXı4‡Ãşµm½¢®å7ĞüÓ«öÉ^·ÿ3ôw÷Ú†ºVúİÓ¡úN4¼ê;÷1!…RQŒğs¡øYú³†SZçMH£Á¯á" 	x3Š'Åx¬Ê5„biÓşÙ58óÿë÷ŒI–‚’Û¢’ª,~reDÎxóÕ7¢Y¬õÍğÌX]°Ô¼<B@TårRº$IÄò V>²EÕ8]<Œ`ëG iÆ¤I­vöaí$ÖUnƒBjÑ”¦(Écœ§ˆ§7Vòb¿y\Œw“šc[‹»÷Zª´ºkë¾c†`®æL¡µèd²x·IŒ	{4GğÛrêÌãqã^wèyäÂïèåDmÕÔı€¢
uÑ-ªqY¬Ry¬íGù­?aäõLã- –3>şäúÓÏ„Îc±K t}µğ{MQ²:xAIlI4oˆƒINt„E¨T×#Û¥¶‹™809“„èíú{h%â…§\q7êLzR“{0ëkdGdb‚‹šŠ†ç~¨± ğôƒ™é±%šd¸ç¸q5%¡O%ªDJHZ¬«ÕMËëÎ±Ğë:?nBÄ|Ñ-7%ÁD‘›@-fÆzH•è3'5P^ÛÅ¿;µƒ~sï¨-ƒÈ=~u\°y!Ä$‰èÇtÏq'’w$Râ	ÔûÄÃ ^@Êòn«5™ªôœ.%~—¥°t¾ÛÒ^çzÅ«+¤˜ç'o«ÄŞé4jòx±Ÿ	Y¹y47™µÉ8ÊvG&Š–”ÇŸ‰±¸ß·¢áF¾IÎÈe4•Â&äÕ…6xQ™ k„­&¾ä1‚ÒåS<Ç”
Á€	£÷¯ñ™»Ì 8À÷0ø1£W\ŒRíF`i>˜IÄ"3°=¢
®iáM¼ˆä/5’'cÀÇ°2³¦ˆJf÷Â¥AÓqÒHOz®s_ßÖC"}ÕB VVrG°1nìøDuj$ÊSÈ.4"ÂšJ<vÌßb—1÷,K.ìßÌ övbµ½˜Áğøçfÿt€/y¼8jcœRVR‘NãÌY3išRİ/ëMõ¼¬3^ËŠ^N¤¨«wò¨0Âs^_CŒWè&ä%qB"’DõxwßK(ÈS<±õ]û§ÚuUbÎÛ§ïovíï¾[r£Ÿ84½d0ûı`ñFIw²ŸDë/+î öËZâÜ—Èô]…·#¦#oÖ’Ë@;kCÜ>¹Tµ„(wğ¦ÄALÊU(M9õ@\òz™.¤ye­üôDí¸So÷TåZŒƒvŠ¥Û´Ÿ\xÁ9óÍ	™ûºÛ?@8ÜÎàâz,G+›+f‹“ş“|?˜³wîxy‡æ,ÇÙ=ÚIY›Q+4ˆ‰O†ÙŠ¥ŞcLûóÏCÏa·{4È –š8àÉtF*=ğNù2HMÚÔ˜‡ÂFH#¢XLFƒÓ^¯Û·ˆ’*v’Ë¦†&q§ö¿Ö #Â×(ÂA2ó¹w¯A¬ÔøÅºXÂÔô®ÂIwØÙÿu4€pSÜ ø¦p… Aà#Dì{‹|‰ÎL¸È)¯wîjÙÊúî)W0g÷`çn^¤6<ÎˆÏrröR\5Oş‹{çò—oÁfóØ ¢c’-³É9u#‚Q36‡'ïÚŠ%—[\‰nú¾“¾÷FÕ	?Áäz°o0„‘ƒ(åŒßãûÇ.D±°åK9÷X8¥{R<·çT÷E}€•Ö]î=ZÌ›³Ûeç¡çó;3ào÷D3iãË#ïEî¢˜sjd[¢¦¦Ş»Qm_ÒIîè´Pänš<7ƒ+MdTOLÊ}<Ÿ<C•E9¼ƒËØrR‚:tYy8˜V¯ÛĞÅxDläĞÕ¡‘Ò`n»¦cLMĞ0ÑtåS£™í[Ì†HÊŒÇ†TÜ…Ùv—!¤áBq0<Ü=8í ¯ípqWØ}\Sä¿>n9&cEvÃvr²Bzê—š¸C¸ËŸâ…c½ Ãšø'
å}¶‹•AV ›ó--E$Dª´Ëçù‰gQ˜Ô1¯Ä*éØ‹¢¶¼Ûë@í”Æà°vwvóLzÙ²™æÕÎÎíp¯­ÀR´}RşŞÍûlÿş{bÈÇ^™ND:0?¾ÑÄİZßòjµ=_“68Ç·•ÆlµÛ·ONGaû8IøKu
óÜ3ÙÉw—¤ltû¥0ú.Ä£½öàpØíñótÒáMlSTï:Mß‹:£_Ÿ¹Şœò»¥¦r­³+Ò¹Æ´Yd[µgì¡…À*Ø¥ä¹A_?çNMJ[¦NÂf§›‹ê—sç“,Qœ-ñÙá—‰åGBî"³9ı	ö7™¼ãŞ†×/!g©;èœtx¢”Æ~ßHT€Q–5yˆ>À¢%J¦´=…âÄ^ŠÒ=Çåİ­¡Şí’Õ%Q4”©?ËŸ
ÁäÚ>¢Z&Gö2‹R€²€¨Ü«åa–ILX	²„aÌ…™D®Ìx’]‹ı°˜ëØ©Õ®»½öÉ/ıÆÅó„ûÁ:×Ì¹1)ù´AöæÛêZn~î T5iÍ¹‰b´·ÿ9`z@'tL‰‡`¦{Æş
–$ãM7(yrVE*Yûuòó[~=ÌIšJl,bíÂ×O8°òS²¶FªäÈüøO”8À@òÿ§lî\[»ÎS_È`³U— "À´ä|WN\ñ– „ÎÉÇ¢L"xÁ÷OÑ¤ä„^ô„³ÆË¤Cïuª1+3>øŒÿÿÂ=fÆE”¤ä?Š„&¡û.-Ü¿`Ş—rHêŒcãìÏ…ÆË0ƒ<+À„/ÀÕ!ºDˆm,å¥=q~`u¿ùA„àÚš`Şvx…a‰È#Ç‰ÙÌC¸4w„%ĞĞØˆé0>¤â€àYê¸…r’İ‹PŒõd¿²s¾|ê8š%ùªñLZÍ Y¸÷ß¹SÜU'
]rqzüø“«ÉPu©Œ)ş=P<C!üL…÷±to GÔWk…Î”Z<¹xø¡3y‡ï*¯ÌºĞ:6ÖAÁZæTR-~VÆáD-a*ùr;‚Ü%á\à´jDbÕ¸ãQ“ëäË„IæM¼r÷RV"ËîÈ*•å¤£
®nôëòJü‡¨Ì©a|¶ôOµP>1L¸õ7½Î¢qr‡çĞğSö¤(°ÿÛŞ·uµ‘$î+õ)Ò%M^KB_,ÏÈFv3ÍíHĞîã£SHT[Ri«J`Úíı:ÿ³û2söaö±û‹mDä¥2«²$AcOÏ,:ÇFÊû%2322âÍòJâCV©ÛÓ¯2ş)ÉT£%ÛÀãüú‡	ĞÚÕ\xú³µz1#¢TòõrÇ”L8ø†—-é×ÿÅ.½ŸŞÉSBp¬å²w²\Ğ£’7úà±©*Äÿi­RhÒR€KJ'8Èì*H.Œ²›*u#W\¡ØÊô]çà”	u¾'$©öÆXÀUtÊ$’i¬TÎ‡á)ì¨1S…Ş^Ñ˜ãÎ.+QEÀ¾—¿=èmR-üÛV¦½Y1ü	‡p2`.ÜZnp0SmàöÉ–3•Ö¬¬¶nT*Ó1ß£2'­Ñus•@¨ÈD*ÖF	Í-õ8gIuc¹vò«>y_,çÍË‰±æTšó¯ğuó@(­¾âjp¨sEÙŒ‚ª<TèE”®1ç„rJÕ¤Aè€(ÔÕ€€Ñ¼¨‘¾öÔ"²ĞÍHf\¯®Wëâœ€\{ÑZ“¾ƒl±”ä|¤Lã"¥•A%:Ë'2øÆ´0­y¸é¢ÆHîılÒï%£‰$Ò5ÂÓa¯†Ó¢?ğ/ÃÿG,Á|8IâïË¸V“Áÿ>ÎÎÒ_Ó‰ø×ËF0îãWØ¹ñUĞàrzá§ÿªŞ8æïıüÿ#_üF)Nn Iæg5ŠäA¨/¾¡I›ö5M£Šƒ¥'ÚW•dòª'x	Q_´Œ'8ŸaÁœW'	ÿªâGäö.û±Gß}Ùíì£ü;Á²èÚ?NxŒÃ±HA8,ü¡öUT:úà=Ùhdà+Ê×øWøëôT
e5€fÅ·‰	¡o2rš¨/¢øÉĞÇz;×Õz¿Mş„şNÓ‘øFTÂ¿"~ƒ€Ë:ïş$	'â,öÚëc£RJãê¾L¿‰¤ÉD1R<Ú‰´px‘´¯"K:ğWşi0Ò ’£±ğÏ-½”Åmº™ÃUbÒ¬PŠQ—>/å¯Èh–¶©´¹Ø—%ÇIõ38#·›¶ÄCÜı‹u²yu	Ê:/çrmbÄ‰¼œ˜ê¸E•ÎJ'5•°;µ[ÕwNW²ÊFµ~B³ 5~åîˆ‡ø/ÖzQşÒM*XxfªkÌ*äsV¥W O…Ãä&ğQ'½f°ô„Netçò‘à ğ Ïêz L,º}BÜ¼@ÊáÀL	§½'®ïzq –pƒ+ĞÓfÃí:ˆÙÚµTñoâ6Š«ÌJ•mŒí­'§ R¬$’Qn±Ëï)BP«$+y1|-mJU¢µrçÄçöüÆ`¢~“d·ZVIS³gHŠj
™Ës|y:/T€qËŸ,©ñÀ1@|ÀM/\4ê…“$nºÀ=ºé­N¬Y•E6»¹ã±È)•áâ/4€Š˜õõS…¦"I ØüiÍ	¡¡	#vxDtEø.kï?ìñm¢9ëZ!`—¥úÜùâ36øZ%K†|ÏT…Bıè^çâæcÈFé49\ÛË÷TÃH-¦ xöÖ³pz±!ıîÊ/¤…tÎï¬mòm°ÏX';îíææ[ÊË‹4LgFæ®RãyµàAzË	“øÉ†?4‹¹Ùb…%ÌeÌ©Ì¨Kæ°ıÌ‡†Ìc …'(NL;<\$÷,—˜ÚAÅÎ*f‰•fXÉ¯Û>:ÚÙÓ-Né89ëÛØ-`Å“±'aÒcÙóÆ<®EJP9=¨Á'¶ìÎR>Õ
³ålû™!wïÆµ“Z9S«ãı·4ŒóY·ì%’áş´÷FfGv«#‹ÑQŞæÈ492,¤ÁÑl{£»17ÊZÁï©¸ïk£ó¹æ.Ï³º]Nn#tË¼ÂVÈùBöQÊì(3šNª>S¶+Øoœ)hËì¹šÕik{æwúß ÃB,ıºª«¤ÜØTìv–b±;·[Ü@ŒÖ†f&z›/í‚ª9o/O?©¢a­”E‚ÛÅr —r«:†ƒEë ~éöı˜-Xù­=˜SºÙöOù“ò³.±a1Îm³cV ‰S|û³GİX+b.9*Ğ~ßF(ÉóV€Ÿ!¼9`8q/Ë‘œ†ôl=êXe¼œ€Ms*+®bVc­ã›­J¸Z?¸Ï÷®…ñú1yÉÕ¢µ÷¿oÎ@Á[*™6{2Ï&‰Du¥ZŸ]&¤ŠÜİÆğN«ó×´`ytm–ÓX¬¦D^­†õ¸¹¬ÕK ø+å‡«Ë™òbä
 (*fÙØÛ@r‚Ü¨ÀE²À%AÏbæó¥ã·| ëÒ2ÿaÈÀdßÒ[%„<Ç’„Çı¤Ò5#mÀyAwUş^²¦P	H—NşÚÚ’QI|ß™Wši{iôñAEGÆ>})Ë"˜Ö—?¿ÿ¼lÕ*X…â3V™®ò\œ7Ô1"¼âò¸œ®¬ÔÖ÷Ç—Û¾üüO¨q,mÔÜzuÍ…@?À&Ót^W¹zA½|Î"ÿ±ô¼=¾¢pŒ*ø~Sœ¿Ïwym)^×?qkáÈ¯ÌMM(§Iñ¯ş¾pEYB„HÃ7öF¾*«hÏJ3?¯YÚHQÏk¢/º¦[vŒÄÖhUñòÓ‚C^0=/ \¼˜n±I40ù¶Ö‘¦|nbİ¬…*M<Bqn¡Z^‘–…]|®‹áœĞÎgÜö	Jw• aÓY›É€<)¯À¼|ïG«îÒ*£r–JõÙj
®¬ò5
ó`\Òêp™*`½¸€‚Cƒš°qÓXğc],¬ô˜Û#sŠ
1Öù”n#—‰şÛI¯‹'œÖ—58Î§|)kÅkè“FÈÎÃâY0ñ%F%	;iš-€Aé’ùK~O0‹­S±'<¿Aô79é—ùÆï`ä×¿ÈÈ#+[µºœıšşÿêÇë9ÿ_÷ş¿ïñßæâ¿]¦øokÕº‰ÿfA3Ü|9ŒF’Åv{Àv¸°1ó?
ç\piˆ<Xmäê
î|CŸ»ğRî=øòA¹,­ QÍ×ÁxsJov^¶vÙ÷­Îµwyµ¯Âa¡É§ôRı}»³İn–—Oüwõ­õÆhY¹ßkuÚ»<jâÖÓ¸îñK8ˆ¿mmcô†
Şo¿éì‰,õ4¹’UÕXâzF™”lÃHØúÛñ®*`#çH³¢™ìÄÀà1Ôq'wdƒ7àÚ;ô—qÇĞÍåßÄ*pyá1H1¤n»ì”ú¢ÉÈRz±|$_“aaŸÕÉÜıúıGø<`#Æ„8€ÌÉ B§¶ÛämÄT17t ÖÀ×0îËZy\àRØîë'.„~¬Ùi?pÙ7Ï9€n:‡rES~¸B7ú‡g“Gµ5ÙCÄd°ŞÊuì6‰Ñ||¸™)Q9•ÅòÊHÉ4Ãy+ÈÏÂéxÀÂˆÕÑO'×ò¨pNÜ\Ş?Øo/[ÆÌ2·ÜÈÇĞ³]€óÁ½Ğ`vrU"À¬Òœ±¸¦‡
åØ[^05\ÏBœK¢¯$G%?ßôóÏcğ’ÇŒ%Œ«üM#I}î8úª”ˆ¶Ì±„­v¹æJy¥‹§:òµeœ ²ò/¸ºêÄ"Šk.¢9PJß y‚æÊª ¿ù&3ˆ`•ÅiOµ–<©+/>2TºÏYrk| U¥åOğµV;©ÕØçU‚^¤À[81DäXf‰{”Y*q¾M<´aøÎ«üÔªüm­òÇ­÷«&ÂŒ?äÂ´0çşGæ'°§#´Ûç³™mUÚÙºâö l'y áRÀÜÍƒ¦AXM’&i¿twwÚÛ½V§Óú+–*f†²ÑD¥““İôWh(Y>8r¦JºGiÍr.˜dèSas¸š:—gÎM&t„‰ôÁ‹"ï‰TR"ïÒÂ*AúÓX¨”¼ós:¥M9ıÎ»‘–¤7HÎœ–:}b(eµ‰÷2„÷÷ğQ©N	“ÒW6Î]†N¼7ıÓk´@÷É£%”J‹’¡,MR,¬õtö„9ÖÕ,×·Ôoµ‚aE¥¡ü´Âuß,¯«PÑ3S±hÁ¶U2©åÂÃT¤¨„KÆøØ2R†|çáD!²ÁéIä^¯á a¼>¢LººÃÓÄu´g’^íı$Í^<{ÎÄ‹Î¨×÷F°CÂq‚æWâ7ÍÓc‡y€{˜T'Ïhpí87şIT#·91ü¼¾Õ™S£k}zåå,ƒ­ŸØüáÔÛ
@rÔ(2-0}*ÍÊ”Ëej´ÃĞê’©ßKçOÆ·ê¾-Ûü(ñÇH$ÒŒ8ÜQ!i¥‹ºCÕŞÇk¦ÑqF2›Î(aÖÕ›‘eúLúÛfFé15ÆĞÏ9ÉİŒÖäV›eEe"Gj¼öêÏÄw5Zo77¤·ß<VøĞİt6-cKñ¿++XjÑÍŒ^µ±Ša°:a˜ÈÂiwÑAZè‚Uâ–P	ç«.ÀåÜ‡/CyÙ'DL¼Mê›øÃ£hjcÂã‰¸Y]Ñ‘ìíäò$šÉğ=s Î(¸„)?÷ã“q®[°¾«Õ*’Ğ‹o0\ø?İ™h9DHNFèä“uš^Sp?÷muÔsêˆä0œçş &Ö…ûÏº`áOWTª™÷Y¥çãù¾¾†ËÊ*Tè¹²%-ô,#Ú9A8¨²6ö!ıôÓ ˜§ëì(ºfˆ^=p-÷VN¸_¼œÆ×™c-7$iÒ³e(eãŒw…ş|ù†à>á,qK\ú½ö^fÅtK½ºÀY=C!-Î”±ÆóoêB/”6²3û8½õ‚„	”ë\Ui	ëª›Ğ#ŸaMtHÌYã‘&…3–XäÇ©÷ù©¨™RY©\©@Şğª2{S,9A…}°šMÜB†•³àce Ç£s|Y…è
RŒ´H(?Ä±yø‹=çO|ÇYÓÉ|nní'6€¸dåïˆÿ“ı¿ˆa¾{ßß‹øYodı¯?Ş¸÷ÿ}ïÿûnıónAå:zy%}}®¼EAÊáË@s–¢©|%ÏŞ¥Iä£‚*›NĞÌÕ'p6d$:rc¿eŒ\47¸­÷PM¤iÇ´MíÓ|ô.õ-9¸V‚ë8‡›«Ë”‰gìÜpØÁpÀ„Z“§'YVØÊªDg*$sKĞÀhCÈá-÷]}@øË*G®såO–â¨X¶³i9¦8Zëƒ„÷@¿ú.å‡P»;gì„_?ş®l"Z˜e©qK«ÊÙ[êõQû-™¹R² Q¹B,(RÂ)01-ÿ:²Öø¥¡Ã¿Íä5[¼„-C*%P¥Ë©$Ïth=´ùD5ŸÔˆ¸O5\a+òÕ-”p¤¹eo‘œ†€L´dY“È$“È¤7{Õ­ı£¹õbšÙ•ŠyÙ0¿Àv/™Æœ¯%ëÑtc»é|ëªª©ş?:îÒ’[ÒeŸ¥²Ğèõ4jÿ ÷æx‡¯x#Å¤[òFc8CÒ´ ¹ã£
ä)q$C¼ÃzÑÈûÉ‡‹³ ³ıõ¿~ı?°Jãğ4Âk8Ê«†©YÕÄë‡‰o“$¤¢ò¤Ô\aå•ÁäÃ9« g]_e«ún/„öÜçÒŸ%[$@ŒúÃI 2Œ:"U´hFU:ùr GÆ‘Uµ„äJWP$iš"& JÈ€Kyäo)õY2ĞâeaÒ­TŠ¸•‰âP½f€DäS %Æ9~uá÷?´IüõÁÑDóLÄı’è¡tâ"¼bqàÖîQ»³ß:Úù¾­|c©‡ÿ¦êe–ƒX³(<iŠ´Y§[ÍÂ*ú×º¸†ˆOØ9TEšN°d³°Ô­)îXÚJ^¾ğdQ<NH\r4ó·^]«®™ƒÁæŒÆ~»½İ;>Ä®§S³:‚>²mÿ4ğ ïkµƒ‰?şËöwLt–ñŞ‹ĞgúÌh5“«Ï*ğ:tæn¦±ËöùÌŠV¤Ìê­ÁQ~¾©¹ï•Í}&5\bŞBğˆMc:ğyŠzıòÜK ôjw3áb›e°{Ô•cÄ­9³)}ÂÑéI&KĞïÇÓ«ˆa¾\}âòr§µß{	€€j]T+t…NU[kÕò’•SØS±<Ğe®­6W“-pä‚œË²¹©”…îÕo#aHEÉç ˆ-#,ÒÅÇ@_`£äãéYíÒãX(˜	Ãc ÎÓê€Vo÷ø×Ş ãğj¸HËê=”Œ§ã€Ÿ'k¦#ãröx¬Â¹A1:b¸h^ M½ì“±°¹Túõ¿¼PN†nqÛÑ(W_>b+Ó!¢¹1¾sN	-½7Lâ,^ª ·S©L¦Ñ¹¯Öî+áÔcóÖëéx»Mì'é´Ÿ18ŸyÓaâ`Å3/Şæ!_i$„'5/¹èá,áû/?·wõı+òW• ôyRĞh~›Ja›á0W¥l´Äp_WœÀiŠ2gû„~ÉU€Š%¤âB¥®ĞQìäU@r¢'ƒ.Éí‘Z‡e³`ò“q7	'Ü…öØÅŸ´+V¨ƒğñ/­ï[ÜèÈ-§ÉTí¢ ‚B¾¸Ys"djbY•¢)mil½¦["ü#9%ÉRüIìˆÛ>>¢¡$Î8EâÎ–’Ñ¤¹\ƒÿqYãÅ‘NÚî²“ÙË¶Ô¡M’€İÖÛ½ÁgÅ 9nf†œ5CıĞ†‡L­ÎÊ$Ş¸\s‘ğj^eoÆte0R¤ :ÂzÃÌÏ=Všy¶$™›AÈ´ş†6 :[º%é†Ÿki*yc—s]%M" ¨:õ·H²Cãk.È$«•u´|?”Õõ À¯fOm˜Y*³[f9„ÕsBkåä¨³ÇØ™l<—c#K­òîÎË®¼§zìn›rcl|Ü_üÓJ²%¬"Ç bÄWlĞ‡q":ıÈO¢0&ë¯Cş8ÖÌ³Íºñœk¨UĞIE `Í·m±/wÛ=Åå
‹Ò*Pƒşåå*&ÅôE£l–ãÎnSë66ËÜ×¬ÜL3ÅŒÍÒø>*U#eU3ÔÈ»;¯ÚûİvF·ÓÚkÃå ¯Š•Ê0èûã˜6ÏqØ#„£ĞÄ_òG/t¬¢rÆtéÄZ÷Zû­7íNïÕŞ¶Vñ;XçmÂÿ¾é4ÆıÍÅõå®J¶À9;3‹nšZárU¿—¹geÎ´‘ÀRqiY»åÔæJĞ!†rzo¦hÏftl‰çæ?Ñ™(+Ræ2|ÑåöÌŒóÌŒ³¼¤º [BDAïãş„
ehfv³‚ËC‰0JqÛé´wÛ­n»V%uT`r§Ö¢Q÷Ò^Añs|A9wôLoŒvŠ”¨Õ Ï2 éÌî¦‰ˆ 
FU	T³Fnvü\³DwÖ8Î,õ.F3yD~2	ı åÛç&•3ø·<:Cí7>Z\¢0
B¥øŒ¦t‡×â†ÚÔôü¤+Õ`#J.Ql¼|¦Ñ–©š»Tµu&‚àî»àÃö¿+0îÉöÌ†èí.N¤{Ä¨FÑDJ@™:$ñÌ¨|.õä‹¼£uXzÓ>â/’¯‘á@W24ÄòZúnÒ®ç:^ˆæŠÛoéJg¢/¨Ñ?‹×,u8OUÂ­îj<u#miXö2Ïé	ÂË|ÎâYİÜŸElA¯Â§¦öéş0dû
|¸`zCòÇÅ¨OÑd:âŒpË/RñšFM–ò'{~/D³ï %ğôéSVé\Œ‘şP7o,¬Ëh^&ialªâUz»Fİ¤UâzÇ*…“£(87Ÿù3ÏTÙKıMeEÚrÔJ%|/ÄK2ø¶£Ëâ„¶ˆªÇµôøÀÈ·™•V®µZX­Q«ÚF3VmtÍ'tØÂPÏcı°‰ıs¨4%Œ½•eã)2´<Kø˜±C¸LG¯p•C5ıy¯õfy’Öaog»ıCs•ª†ø^IYˆoŒp½Ò”nkè6ùõè$U{#.¸	¨ibäçMP&
‡¯Ãû$y`ZÁ¢çª®“ñğ~/ÏDs15šº™ı“±&gDiÌ&wfç´mH1İ“Ø¬Ak°R—?¹jôB£B¨m	½Ö‚á…ÇÓÁ´çcoØ`+ğîÑ~M'ÉªCÑ¤¿í
¾!×¼¦OÇ?#±}3ñ™q´åæC¹¿ıİb[¨Õôn:ÂZäQI0ˆEu0¨¹š?póı¬PH)7j}?Hñdsg<P¯?å&ì‰•BLÍ9¶–¯[ö§öì)`v˜D™¬Âº;ovö`·á¢T\çÃ¸ØV>ª¿K,g{–ï>”ÆŒÎ«ÓOÔ•:­òZ -¶¦ˆk;_ÌdŠ‡$w„;³Øl¥A
ãd:m…ÏXı‹„%ºé@
ªy¥QÙàşµp³/Q$;’Æğ9‡õnÔx\mT»¶DJ¤†.kÃêyı*p_e³TÆwÍO¤(#ğUaÎ­%Ãğ7İâD»¹¡ÑA§l*FPïú¹ùÛP$mtØ–ôqJ¿FÄŞ”KÙm›‚D‚ì»~şl?ó¥t©Ësgé®Í?³*‚H¸n$°†3„iÅïğ7/©ğõø.AS™q†ğ0‹[Í+?úxK¸ò‚ä‘ºÉákÙ‰+ºUP\€`3Bo°È°p¨ŠË$£n®çÅ CnŠÎPØX8Su1Å²XÑ«<g	oQsúĞh{ç¿ÕC¿öÒ¯Ôø˜fGv³öÍîñï±¯º_ÏÃAº½k"	h{O4¾‡ßÉµÀÎ××¸°X‹FñMûÈ-ÌFøøq>œËòÈšŠxy¼³+PTö?ÂÆ×ø/şô ¶ëúb®;v	òİšK£FzÌ«ÂHËæ%ö¢~Òã+è*~ÁŞäC UPÓjÎh	sog_°,ì±íÆE‹8w{W›©sÉ¬ë©’z<½Ñ'ÄK³ÚÂ“"5ê×ÑE·Ø†ÕÔ”·å‰ESÃO³J mUéc/•8<~[Æ™Ëlù“uÙ–$G UË\Ü†fdHYÕækD`°‹ÊñI‡‡[‰Ñk]e0´C6·s³SğW(qjÎÜ¢~7MœÕÆÛm¤ÆV*7Sõ÷,X’*Ìwü‰D°Áfx¦üK"A¾¹ªıÔÕiÛ¤¶Ö]Í‹ûÇè”:³J1UM:†¬5Ôw–»ÀhCšÊK0€çeŒ‡×d•#´¢0OÌ³@È—–<”%£²‘ëaãnH§‚º+òoB´Uõ9³¬xQÂ-‡ÚÏ²…dLè™Mc8nÊ…¿ßîÀÄ\µgÓÍô+«t
»97_;°ÔèMœZƒÁ€s2é×oŒÊ) b_ĞC˜qq\X´a\1ôw¬ìä%‚Xcº× ô½ˆ¢HøFØP¤×‰¡™½Í‚Aé*[,ÌË*‹ı‡4dg~“ê_ß#ñbHäÏ¤yš§5OØò²¦8%6Ñ¦>è_àïUVÒı	Å Ë_úC)Ş‚ÄFAèKÄÁŸéò,´ZDU.Ë!ve‡6¼¼¾›tLÀ=`³<X_b+ğ9²fFuR’`Vii15&K#Š¬»Ä‘õj]G(ìºÎR÷¦sR"óŞ?b˜9oüä	“õ–rÎ"Ü¹B5¡0­Œ#´ô cv/çB²ØæŠ+E—O‚yrí‘Â[Ÿm…cîHUşa@ĞéÄH$æ.1æˆP'P­® Z)*Ôôw¾dYå?i^×ÍıWÊT)'µ©¬á`Cd05ËÓ)îÿú|oáæ½¨}ä%°¦pô?2FqìyÂ} vï'ØğOŠt,œ*ËĞÙVi':òIĞ[ï­õÖ2fjiWÌÍJĞœ´1œ–h?7kËF¦-7lÌ†¼ŸªÚµêgbVg˜9­ÚYÙŠØ6ú#]Z˜«ÊôalœÀÌ0TÑ)na~G¢ó+§b³%TÛ8*}ôÉß$·ùTœDf|?ËvçgµF|æJ³bE"M¯¬éÕ’Ó0Ü­	u½*ÁLÚÓé8=Iìn1¹¦3Ê+£ËGĞt§£¥É$ø¯ØıæÒÒKd¯)¢%•Á€Oï²*Ğ•ÙÙ&‘"§'Rÿ¶µı2	ş¥C$>Îânx.”dSMâƒ«±‹.5ˆK‹ğl†Be*XäÑÍc$MmK¦Ã ÎuÕoÌviiÅF(Mª	s4³‡ªÏ!ôÅAçÿxN¹ƒ|²±ºô{à3L¶3mÅìfğÜ_ƒ•Ì2[§oP»[îÊPÅ’«Äµ>¨ê‡’½g×hºÉŞ^x´İÅf]p8ÏÚ¿Ks7pQ(¥ƒXJêÌd¬kšQg&p@avG°¦æeª–d9jfzàºƒçKœ¦¯9Ñíâ~CÙ’8}àkú8½—ëê®ˆôSãx|ùØ¡° ãuS ƒEU%„õm·`Í¯.¡Y‰ä²ë‚ñĞ©‹Å›*•Mpu3µ….Ğ¦7•—±w¸»ójç¨×zueôö¶Ûp/y°G{1ƒã™_®Å‘š~ü+Ü¬p‘×+vKI»¼É—Ú95®ÍBV
O}Ø‰DÃq;ˆp†ÄaZVúÄR	HL‰èÈík-¬”/·‘Œ
7õ64°>4“/jBÔ€~p¬§%éë¢ıçœœì9™;	¹ÂıåJ&"ÈP+¡°}”í•
L‘3QÊHmÒGV‚!„2¼(ğP‘ B=òc¼ığ²i–:«ÒEíÌs6îÖ Û‰0ÿq
QêŒƒ.sÌ9§šõ Í+³T÷ÒEtÆÉ+áš/wÊØÎ˜ÿL ¾/‹ÿW%˜,”5ı/âÿçéãÇøø}#çÿ§±~ÿwÿwSü¿"?}+Š'÷D¡ø‰2EI­:ÀômJ¾«««êepé…\×²WO£Ú îYµ.ºı©ğÚ*d,ÊÇhoXQ^ƒ¼è+¡rä;ùÜ—¶ge•)ñIØ•Iä_2„Q…}ÿ`ï°Ó>Üı+yHßa`ïíAg»û¾¾Âït‹Àœ…)*ÖE W`|&ˆ é&UàÂjÓâoÅó&Ú×
5b¹4#h‚Sˆ.)#±Ò£#ğyŸ ­ŸY³É*Ù{M?Wëúƒ18>°ò«±ep•ªTDvM¥€¤ÿ1p>«¼fECÊôğÅsTn”£Z»y-<¬gÆşO\ø°&£ø+ã¿6õµÇ9ü×Ç÷şßî÷ÿ;Æ=ºğÑ)kJébÀZOãÄ¸D8Óøë¸|Kåd„ôBk\zS‰«x)J/ğÁAÓÎyí¡I¯€¼¿–wXÄ¸×÷vDqò€™8aB#	6Çıƒ£×hı¿¿N~•´w&ÁÙ5ìÕãÁª£D3Mî«¨½ZJ@rÿeítÏşŸ©ˆÇ]uÔ-Aˆê5İn*Uê´vşÆ¶XkïåN{ÿ¨Í'Ë‘7\^%«£ßuûLRüB3+½Ûı°ı¦·İ:j¡]F·©¹ïİÔñò€œÊŒé:V¡‰KK$ù¶½û
ÇbÅYú>ı>›”m•¶˜4QrO’“ä0¼ò#²üİöÆ?dCXéAä¡±÷O¥tVŞ.êRİ'ÉC¹÷GJ†Ç„ÄÅêOªkl÷¨›‹x–àïå{@îi¥Ò¡	rÈ8ÜëÎÉşvÓ=#Â®Œ°
øJ¢¡(ª5BÅC¦jÁk®éY”3ûEÊßûÅš¸ÎÌğ¦ãòÙ¤¿¬§°!/R*à°~ZVc‘Ç‚Ö#÷‘äì~wtpëòãà™²¨‚Ø"xÕAùÍÁá¶N‰rhnˆ!ãÃ¸k–3¢ú^ÿÂ§H|¡A4-¿êØ€n\²ûIµ?õªÓ³Qœ¹'«f½ŞxæXoôâ6Ü'‡·£fQƒSÉnkş[×®ä–<•õõõ§|Â-z¤°-5uCË£µS“1„kFõg§z®›µEªÔ	%I+÷³hÜÇgOzO6rm#³¤ÛfVæh³Š ßj„õ¤Z¯Ö]'c!5sL»ú`6¹j%äíš@3™È¼M R]Ã=V$µ+Ä7—O1Ù2ïÉU§,IÃJZU­B¥Ş»5Ë\‚9Õ_]ówk–Mææ™ğ[jSH?¹º°¬}+cé`ÖQdI0³›êçlcÙ«Ìëõ¡Â—NÅjâ¡Évdûi1;2k²Q k¢aöhÆPê€éŞp$ÓSÚ~M|àÆ½™€$§Ç9î„øú–çËªºw€Ì;PÓÂ0Óõv¶Û2ÕhèïÃp…€€•XH¹1 =ò²ğ4ëÂñg”¨µrÛ¿$6ğ0
ôû	Zì”T±È£¬=x}_ïœÉÒhq¾/{íıãŞÎQ{ÏHogãàìÃgBÒ‰µ¢ªÀ1HBØ¿ÄÔª-l£Z§İÇï¾Íe½ìhvğÆÈŸÓ	l·Öü°ñ¢)¾ª¬¥=5UM<nÙÑ RúÇyÕ›à	 ²5DE$¼ˆÂ=
z	‹(© {¶ŠÏHY…k{õãO®£CÀÑqÓ¬¹˜W‚adÈì„Tåƒé:vk—J{¿^O5ò½¡*L€ ¤%÷Q–©(8r¢˜3cÔS:é2ÆÿÀæ.šùG1­.±w”p=ÉF7]éµÂMÌœµÚIµÖûÌJ|ÿÂ'F½  I8c¶\]¦7ÈŞ#ÂÏø}ŠZY0†dPª“†I;$“6ª—ãêYäûòiP!¨&šZK¼ó¸–m.ÌxÖ‰…eÊ¡®öÏÎæüÉ3.„:Yê4#¯ÊAçã†Ğo5z@½÷S¬ZJR3‰%âdRIø…J¨WŸU)ç’ã˜j-À	S+;İn¯ÕÙS·ûX&xL®Ì:ôE*D°W‡Ç’BåöÅMI;.ºTTt“éì}ûÚE—ô¨ k=]>õ\&/§‡öëšx]^^uJZÓ0½µq·ã-Ô¾‚öÀ¸ó#8ÃšU*üÄ†sª‰¦jƒAeÂ_ìçC	IN½wƒsØ9“³‰â!=,ª:œ| ÜÊ x†ë
4¯p°cÛùrzA6pÇkšÇš{WM?ÓT<àVş’íEßAÂ:Tx¢_¿«6õ‡Š´ï½»L`Kö›öìûVgw®ã¼íô¶ÂÅCÚAE®ÅÑ%;í‰ÒS|Ş©9=œ/-ÁéÇz½2ğ/ß;=O>Àf¥~ÁÅc|<i}/ˆÂ†ükä<¬§±“8‘ß½äƒs~Ñ¯ÈšğÜ8N“õô…»NŠ.ÜtGşxŠÀz,^rù4y|Æ§8jô¤èâapTŒé8ò"&¯œs÷§ìş‘ÓM¨ûRYul>h)1ÆÏ¢2œ»Ê„Ãï¯‰ô9$f†º;$è^ƒÃqûëŠÂ*hTsGÂ&ıîİ{Ç)T³+)ù‹ÍwO&Ò®ou´$ö¶µ7{Ç†LSä&d-Ài'ÛšçíâÁQˆŒËûøl üïH#Ä|ûŞiPÙ¨ş±6‰|$‡¥Rä‰$ÏLª)v‘Ø·mhf§{'ÂhQöíºÈÏJ³›óº¨sMsÎìå¯xhKîY²2ş¿Y¶j¡6iJÍ©=@^hl ÑÎe[Hı4òÆp_}?ø;ş:r}¹Âì2eW †æ‘p¹}U«Ù94­ËÄ]VPä ƒˆ¦›o{ÖÍò³ålÔ.ì|õº±{ğSˆ¿gä®¶Õ”®šÛÍQ6µvÿ£›ìc:ôt¹½ú§œjŠH9ï¦Æ¯ıhÔİ‚`ökBÿí5z˜€¿ŞhğdşÂ®®Åİ™Èğ
èº=Ú¨Ô{”·aà"–ÿ%­Aõ|ŞšFÚšeÜİ+ÿŠp(¤m	µ].}5Ïg,¾'ŞÇMşBdjUœ$!üË†¥Ocï<‚„Œß§Àô®ºİşü.œd¢xiæãŠS±›ò…*M`Ö›V1ó#Ğ«ZÄ¤ÎlàÇ¿üSÖ’ïo¶®‘SXc®Ît¬ĞPÏU¼şò÷ùÕiÚ=Eõ…ìÇiœ(­jªöL*»²‚hÃçzDË€t’Íò.½`ˆÏğèkX°Õù­!Í£Ù#­áv\!OP£,Ÿk6ÕÒ!%(#F£ ¾(®BRÍTúóœÕè„JÇÇsse~ëqÍ!Ã.:8ÃtPZ.‹Ï,Òßf|­lfÖJ¶-,·ò´…g×SËñÛƒî‘–ZèŒ©èıã½—íNv±ÆªNÁÒÌµdµ48+Öªõ'Õº¬ßEÇÆ'ã´/ûa‚u¨ºy×ù'{y­ğN¼Å|qÛÀ+|
aø4&%•‰r*òˆBg%ˆ™‚FĞ„C¦„ˆ¦r*ähÿòw¶s†© ›7Dû×k=;-BTÁJõåNzó²gp<Ş«Qÿ»ë¶8_Wÿ»¾şøi^ÿ’ßëÿİëÿÍÖÿ»µ Fê·Óäf-±€¨²:'sÒ*û*úŞü…Q<ïlï’¾ Ş[×fE~*ŒûCvWxøÙqøÅBú°e3t‰İE2 ;‚p\‰Q‡gd‘<ò˜ŠÍ@}‰9ø^\ñøê¾h^’0pù¬¨Ğ)õYÌA7Å‹OGÇÏÍ`¯qÔŞŸ‚IÓäè9iT9"‘0x‘#ï<è÷´WdjPë¬´ÆT(	p—–Ju
É<
BÒ†ÎqÒ+­S¨ÑrH»‘Å‚„°Ç&ô€à÷õ[©ö@èSBŒSNªs½#ŸÕ•ºnã,pàÆÚø¨ó>@«ƒ´çï²…˜ fnYÏêæá!)È¢Z­23­0ng•èÒŒÑpwI#¶ÁaÊÈDñuô”Ú¯éVj":›+etii"JbDİ­dÑà>–ÒrBÃ¯ô“-ã…/¹3l”k±ëµèı‘å¨tv­ã¶:Üü	!ªV8«>êfJœüY€¬(ĞÅ®‹!¦t¬%¡BQ„­ƒ|›ËË»6‹
Ù,Kì­ıd3ï6u<YÔçÚdÒÿøD ™0Z½œR­j0ó¦£óÁÅ0^Y%>Ë[Rgü	1³V"¥©Å²Ñ»G$6Áù3fiEFÁÅÀ|Ğ›¢«¼pÂ°e‡½„šÁÛÁÓ	$‘Ó¡/GÂî¥MV »N4`é…E\ÓQ
ŒÛƒ˜;nP,ü´œ½â+SZ•.•hk'M!ÿN—¼Tâ`¬SôkkyËE·ÆºÅäO¼`Ÿå23!ÁÌ®–§æ:
ÃDi˜ *ÂL |G‘×“>â{ˆµ(àï=Æ¯¹NÖüZÃPÈ8zLí¯Z}„¡áwşº2:×C¥¡
rÄ."Ô¯
¼ªsÿ¨±$¡Šl¦^Õ©q›òkøTGM,E>‘?œÖzøğ~ıß@O8à#2y<›/öÙÑù!usà§ÊÙ™èÛ†“1M<H¯Ãûâ›†B¿Â¢ğzŸ
ÄÖJ2ÔµÅ)x	´üòB˜dlŒÑÉ¸gB
«:g³ÔÌËEªåÚ|Ú.ò &è‘å½.H‘ƒ«Éé1)‡NVd
R$k÷>²ıDÇ¼êAÅ>°÷ƒ˜1âÌ³UyCÖ?æšáğ¿“–!qÊ£t<ôsP•J;”Dpl ([)&C¶ƒl~SŸo´aIğãÙ]4z¨Ú~ëN²ôÌ–H(9Ì†-Õ¿cl¢4½u·8Øªj€aî‚¹uJš>ƒ‹—–¸áf1/ÆÊáÆEwsC3˜t~lV6x¹_ Zg?Ş)F³$µKµ½h ¥¿KÇ´@ÄÎµ"ô…&Êª†ÀŒ:zms8õæ÷q´sÒcû	œ?ÿ,=M(×†Åù1ÛÊxH^‰¸äÕàúDŠÇ"î`ª°høcfå+o°ò“¬0Ş31v…9¦Û÷&~ÜM"TŒ+iEzÉhÏ¦C’LÇxN¼1¹Ó2„½rá~ä‡÷uîïŞÓ@.ö"(•Š[:)Ô0›¶V"ÃÖ0®z šâ±Dö%&sêOF˜Ùe·5ÊNLÈ~„ß²äµeš›ëí‹$Vx‰:ŠıÔDş4J¶*ÎÖÓ,–’ÙN[4Œ¡ì^jİLwSëv*öìú–æ‹Ù[$·\\4,:ÙÌÀ}*%šw¦tF¯gÆJÈœŠü 2‰¶X•|¹Yú!õ•†Å»“ûE{¡:ÁŸ o?f7¦¼¢Å'€Fif_äL—¸`Äç¾!°í¥%ºbám®¿¨ƒĞ²JLM›µD"?A“^¢Õå?¡³†SÄ—ûç¯uéa£„MS8*|ùÊÎÊS%•oá+µõªÎŒ‚¤*%¾Xº«,¿Ç¢– í“LáCs#V\şÎ;Šy ñŠ¹²8»-½9@¹~ìõßÇûÏ ìÇµ/ZÇüüdŞêbïß¾ÖüÃq^û=ÍÿÓÇë÷óÿ•ç_×wøšó¿¾¶^Ï¾ÿ®¯¯İ¿ÿ~•ù?qñ‘s‚vxY10†ªGßš Ï˜‹Ïª¬5=gõg.#T	¸±¹Ä)ÊT#º1û®Sí~Ëö[{mÇÔ¥9QI“0£İEYº;û‡İ®c¶æ4r4$Ìşîäì%—œuŞÓO8tágcæd€“l‰¬ix¹”&“q#ß _V”Uİ­T«N*'œÌ‡pÖĞOïWF°v1ÂIıŠºc·İî¾êìPcÉu|”ç÷a0æ?ƒ>k=Â¹@ä²^²êGÔ£7¢aR=Ó¦²rª³¢$RmhÌUØ[î*Æ×ÉŒü<šjW”XŒ¾“JÆ–Trh‘®§H“cg¹f+İéyÅà2ªŠ´İHNÁz2cÊ0mŠ¤‡Ïç‰œPÈõ—œÚ£º¾ÍÒzºÖ#ÇËa3)TŒüûŸ~'¼g²I±_!Û#»FBàJu2ï**té¨kBƒÎ¶X-*t•ETèYó%ÇcNqĞ†m Èr†£à¯Öyof‰®pÒÿC?œÂ…ñ~+¿Ê[5ğŞ@›Öµ.ìŒ¶XSš­ù¨cØuv¸ê‰æöeèMQ­?J›‰Â º‡II´ËĞØè‹\ğšA™(T#£?¸~Ñj;>úö ãd¡yVĞ{õ?_„	\‡hû¿ê8ÿíşóÿ‡şñÒOšWGƒ¯ˆÿ·¶±¶ñ$Çÿİãÿ}%ı?È®Ãé€¡ŠrìÒ±†
ö.#~Š`NÃiÂÆş;ó½„ôáğ>æzªsIŠyÀlû}têGéå¡™ÆóÉgéyœDáøüÅ~ûmwóyMü‚ğéş_z>^ÈStNQ=z^ƒ@GÆ:pĞ&ŒÃNè‘Â±<G¾Ğ#$sBÀzÄ>v¦}”¤zÔ3¥gÆ6ÙsôÂ@Ú„=|:©ÆÏkc4K{@G®mãé ¬Á6pÜc=ıë)åüt×bÕ4OR‚Š«zVœV_CoìIW> °\Í›Ä7Lüñ_¶¿«×WˆÌÏk4Ârü_ïüĞŞ.˜ B
$EpÁ>nMú£¨\@…ã¸«¤ÜH¼>ÂÊ‡iòtjÏD}å#l<Z§%’A5{Éy^âáÔÕ êê ÃÀºş$!cÏŠ¨lV/5R:îìê£”«®?È¨ÕÿxjF×0PJu­ˆ 7B28T	_ÄÏl‰¸r)ç3E¥§ú+ú&@	¤NBœ{8bä"Pìz.1[B©‘LÓ¡ïA¦ØRI4‰Ä‰¤¨5:YÜ€ğ2 ´«ê‚ÁÄêÈá'£`ä"Fª+ Xúìxçg´®Íè­'ŠY¡V¬êíã3òZYnBM””	Ó×]>832 ~E:luö.ŸÖÄ|ß,ÔfÉ§^Cà—ªW»;lıKûqvÃq7^7øø2 ëdj7ÕQvSEßœ$p´iœõ‰¶Í3¥îğgjÆ¦Ü;¢]ÏÌûóÀFk0C{Ş5l§%,L
Çüu‘Ú24‰\“_6ìï:¦eÍ€«Ìn.âŒ?ÚšOğ1Æbo1^°ÿÕ)&
@ã,;
Ğzú½t‘Eu42j¡Á¹ç“ÿÃùX²wÍõ/Îÿ¯?}šáÿëõ{ùïWù<|øÍø4léÿë,èJ}•2MğËòyòÿ÷
)^$#ËÔÿğ¡ã<|ˆbdø†[±°.}>‰|õC|LñÌ1³,£F…ğàáC)x_Q¿(’ämrŸær7µO¿Oc„.šYÛ­ó±4§¹jÍÑ¢ÅÁ®Gfãä¡Ÿï® TP‚&	´—€òÕ|·2Ó¥ÉºÍŸ»”gàÄÕü¸ìƒÆÎ§¸â™cÌ˜¿ÍŒ’ ’ÅkÈN¾¦@Ø>³ ¥,bö^X AyKôT6_T€…4¥!~Ä¾¨$ó43ÄøLÀÉHQ~¡,Ÿ­P¾!Ş¿énÅìO z×¤h^ë˜6„$¬O£Ä³@š å);j6E½˜Áòİ`ÖFzëf"K÷ÉÏ?ùè »(2¦CpÇïv’ëò1*ÙyCh<YõdvîÂşË;µâä›?tˆ—ñÔ1ï­ƒ×ˆÛ*½w@¥¢EVŸìşb#øÿıq>ã

yïğ:0‡ÿo¬=Íê<n<©ßóÿ_GşĞê£©‡SùLıˆ•Å¬$%§Ñ‰}“£R‹o„çİÈ÷ùz<‡Ãğ
E
”ˆÒ`Û‚b °pÈ’ë‰ßtw\)¤8@|2â˜­§¡,VºŠğ¸7<÷ØEäŸY‘Ëùb—k–z-İr*JR;†§p÷…2£Z§İÚŞkÙ»/ä6ÇƒÔ.÷¼æ½ åşğì,èPÄuªnoå_ååİ´ÂlÜTÕÈx42\¤ÄEF5&äü/½úÏ·Îm­YO.íÆZ:"Òh5Ê•ê<E(ĞE‰ğƒ•gø_{E¢hñ‹»d°¹hÙèa\–øË?Ù/7Š=&Ñ“h/²è‘,:Xˆ÷½ ‘×‡š ‘‘]'ñ5ú*×OT:$hÜˆ‰Yğ(ˆ–‚ ØÄÜ;Érléq8D³–xS"&.=Ş4„bÁcı®UFxo¢ñÍZÛäTJ¨I¯…$ÊºBÆˆÏo@]%ÑS´QW«F“ö*‚òÉpÁÑ€@-‘€Š¢Ô†=-äˆÄªE©yÅùÊîõî?÷ŸûÏıçşsÿ¹ÿÜî?÷ŸûÏıçßìóÿ »ö[ê h 