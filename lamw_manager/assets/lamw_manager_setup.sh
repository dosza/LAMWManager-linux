#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1605897572"
MD5="30af5278ad5bfa34fe51c09baed92ced"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21368"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Tue Jul 14 23:23:09 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDUSIZE=140
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 140; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
ı7zXZ  æÖ´F !   ÏXÌá·ÿS8] ¼}•ÀJFœÄÿ.»á_jçÊ7£jîòwÍ÷´fsødMŒ©Ñ…É=ä÷.»éØ›wä]²~p}ˆr~Áwiè+!K’1Ÿ,©ÓùœnÔ
ä¥æ!(u7Œò£EòàF¸>0û´9oÔ
½µ*Ê–•ÏŒ¬‡ Šï¯»üuŞûŞ×
}­òá'Lğäş)„õïDõÓ{\­é˜|Í`ØäÏˆYñhi²0ó7Ê´÷AêÁ‘-A§(ûfc1o"Í¦«1:™n„Ü;jâ¡7ò8_r·¹Å–íÅdµçëd?Ãk$8Ü <sñİŞó:/^*ÌkÆÕùD–]èëµİZÀ|CJkªFwå6}YV€šâ3„ªl.¬‰vñƒ$«Švï—¯öF<k³l7ÎÕ$ÿGXüNió^¦ën?›»ÆïÓ}u„—VNåñeİ%—–¼Ï ğE |fZpô?ŒyÕ†6m—Ò¶“í®ĞÒMúÖ.
_î6Øéª…ÃñµWßJhJüÿU¶Ç0½<h
ÖıÖ’…š‹x|¯¯C½° z££nÔŞ`º='}R|å?@ÛµñFgU‘Üƒ|rfôUBÔJÙ5¡âi”@¸tïåôd¾´şñøìOíÅı®oÈ§åî f…ÔƒÿİF³È¢Mqû±éğàârj½y‰<ŒÍ FÁ_ı
€$~ç]»¬‚è~—çĞVHü Šû±Îº+¹Œz¿önö&Eõ+wö€à2örØ–;áöã§Á¹˜yM;R·HAé‚r®4$H—ƒÂ­eĞBüœ–Ó€ÄŒšpÅÿ¥U‚@6ø“‘Cx4vŸå­~éW³€¼“¡¦³¶®iPÿ9İæ… ¸ÿÙƒ˜fl!ôì
á”Ïtdr>0İÂ¥@§•Ö×lñÖğ¨½ :NP¸•ŠÇ»€.Éic_ğC ~ƒ¬jC6xÌ|MòÃ´j,–B>t¼®#0 ×zÎ|n¿á7ÅÊ‹Î’5õ`¤÷Ã…Ä€MGá¼òìo¹¢\Û9‹00)ˆOÉÜC»e®ˆÕÓgB‘a–á,í”;Ç’ï›ˆ½ª×‘ô—ÿT@ÇqgËüµÒ[Mµ…fAéÎ¡4¶Êµv<w€IÑ½vLµ\¥R·*Í¨6j
û
ÛF@>¬XŞ„Fí<¡¦å+½?H«Y¤§‹×˜Ô	ÑÖzƒØ…ãõáê§‡Ç¡kIÚÃRÏÍ-ªËß#|›%™vrtÌ–t¿ÕÄöÒÅ›Öõyç6ƒóê5›Æ”Ñn’S¿­åßÑiJ¡X½å$:æás~ù#Å9áì¾ÈwœúPµ°ÓK0÷oQÖÜfBªtÍdEb)s·RÌt²0äÄPf×eĞô(Š?ÙÖH§aq³˜ñUZøÌAl·Ğ@¬¨9{osFğ¸"_*ĞÍ=¬H¿8íêîÃWC@¿>ƒ¡ŠÉ\ĞQ†¾ì~Ìw¼ó‰ ôª¯-’‰¡šï³Çö;Úº6uÕ ÅË¬6;°÷DD&Õ/)a¸æXc¸(şÏyÉû°”|¼ßä%Ã´svî2k"n·˜³5%¬¨ğç4Ë@¿AìE1·¨¤*8BBfØ"/(	³•¡^õ¸äÜRÿìÓP×e0Æ¢TS.DaXÊ‘5]ÎŞçÊ¶j Áë“ÊÖâë²â	[»ßÿ³ìcñPî¸s…†I5Åv &eñÿd-_Éruk¥"E~4ï w³Xnµ¡+]ïÓCô8C ªúQùD¦°šTKYşxzõtYÁ_9Z,=°„,mx.]Ó%¹|1ÕÁ;H“euFÿëœ¬9NÅQ˜S?°ñ´c®	9¨ñE†mzÑõ"gÊñ¹Õjq:?š—&$n—´\X€X±X9ÅïuO¾l·Ù–˜¾™j·0Ø}§8Ç¢—-vÓ):ë“??XËí¿Åõ`*:~X43£2TĞÆÂkI¡[òğ§çO“AÃ½’s"éÍ£xDŒHqOü˜bSÓ­¥aıue —>Npësöğ`­nÆgy…ö &¦.œ©H÷uü0Áxó¾†«ü
†,Gr$„e:|ò¤1¨e&qXX¾¡%àˆ&iÕÕÍÖg:X°i¾°,|ÏÙ=^r/˜:\A˜<Û‹2Òö‰³´à]­&¯/?aàºbUù·dˆ`îöÿ"V»ÀtjgıÀÄJ¨Š-:Ë]€mÌŞw*‰Î6øfÌlu%7,›;–ªhk7À‘xºg|Ãœxyo&$º0'Wã<hØ‰Ôz§ÜãŠôô&$‡¡ó—%ÌÕ\äçfüw˜/ßL;¦*ÉŠ—Oç/&"¨¨~£ğÀéŠ/BdıÍ<pTJ]b–˜±@›já{xrRëR‰ñ¾æN4É>lw¨†<Ê °ÛIŠ!=hª$õâ±çÙäÄO$kfğÌŒ3’“ùˆÏ#6
±0è5£º•¡6õ,ÕÒVĞÖo 	Õ9rr6•$ênKŒ¥
7©"P ›)¹¿?Æ¿ï`aóîãRg³M¬Ú²qQQ]ù¯µQ¿¬i8–²w	ì9·÷Ymñdä©©±©†Åë×‹KğmÙ½GàÙ4“Üû®ÇŒßëµJás½Mxçô-Ïç"¸Á«Ÿ@jºc³\í‡¼#«üÌ²¸Ç2ë®‘?Y^Ù¨D4«)Ì¾~Bêœ£Õ(è@€çŸ÷ì¤“t­Jé Ïü
°0+º-\cœ.;Hï’šÁK"şÛì Ÿiªâ3È‰*`£§öäıúŸT×CØ«:{CE†á ~7L¡3$zá’ †£z÷ş Z?pˆ5‚Ì
Ã¿†!Dôn‡£,ó‚ƒ¨Åg¹n¿Ò2hø*Òúsîå@oû‹ãÁÏ\üO­¸íVı§ØÀÑD†˜ªñê-mœ×ÛÛë¯î«f×@ZóºÇñoRïÉ¯2E,¦
¢	Şµ|°Æú¥ºÜ‰[‘`}]M	0ã¯»C|ä± $ X4l[•OAæs?ì,€AWähüÿ,|e`ƒ{˜ü‰Ã÷`¢åıHªt¥Ä²nqw6«"¹>‰ØŒbı•ÂèÓ­„áŞ‘:½öÊ9ˆ!ßàhÌÓ£¢©!<¡Ä¥€Õ6Â´’¬¸û×¬£Ì¬sñºáüÆ›©U¾3xj?r—§Ó$
”^s^÷<ãëÔ|­ÛKó„¶œşÙ¤‹Y·„5G[Ü×Ú¨àáUV—bÎ¼VÖPŒXï²=³¼+ykI{Dy­û@ÏYH©ÿR•o0<7øPç6w¼¶bÁVqr¼úbÜñ)T´İÜ7¿ßº¦ñÌw‚l"¡§Z"QÜeAâÚ¨<„ÚkyDQ!ø³Yî¹kâã˜²Â¸$Â#uäŸ
É6 Àÿ¡ÿp»9ki-´Z1vepÏ¦ÅnII¤z˜<)T•ô’ƒàñø®Îj”#ªñ@Ö3±8C¥Ò™¶˜ùª8Ö%ÊM¹,«õ¸ˆA$_<óûføæk»s]•ÎÓbô9c£éŞÃ J½oğƒNßM³"E/«‹½š>õ;wõÿ”ˆ“-
‡ƒy¾oÜámØŠÓ6.¸6Ké ØÚÙĞñ'­'ÉhWBGë¥û*KsZÂÉ“{éoİëj¹ŠÄ–Q6ò[\uò©&m¦»­©¼#NÿßšvBÎÅÏ#´ ©Êˆ êP'OjPSwr¬½É6¥ß†9ü×\5vº‹83uË©ëZÎ2ºLF­îï,üNZ±Õ|”¤¨ú;Ö Ñÿ©Ç$» Ú5E0y|:E½4ÎÀrbú­Şøs?mğ}óL¾ÅŞewu6.¨‚“ÉÓR~} 5:9?é]êv.İƒz{ŠÅ•PßĞV‡å¯ÓË…û<ÛU+|…¦Á F³µÄXy%aIÅ”w92,ãrÈ¯ÙíóŠËnËšÏ»Óêv_,ÒüLH]™4¨Ah¡™øYÕ‰ü_Á9AÊŒ2\ ÄJ0Ë“9Îá¸ø†93<«Ô˜<ı·i†Ríæã‹K„Œº¥„ Ù‹ôo™7ı¼€üLjw5ÌËÿü=O°•'“~&nZ¦]Å¯\ªóĞMdëP0‰¾J(&}Çtw¢‚´IôOõShS¨x6 Lám¼~ÅŒcõÿw#}Z¨Ã“1ôHñù´Q9`§!CÃ,Tœf¾ˆŞ`ş@•/¿	‚4r€)V)z!¶m1îXùíëİ>}¿è
¥ï ‘n©Æ fÀØ¨J&ù‰Îûóı{=İËD¼!İ°¨«‰à°ÏãWş”a‚s«JİG8mŞüû!Í¥)Mş’T=’µ±ò_m·.Rd±~…/SjKîıÎËôşÇ‰(u[OÈ°±×qv?¼f9°}2CpäZ‰¯6iû–eñÜ/ºlJ,±1ém.éæ<ø–ü‚0ÅQÈè”;  øwáP+…Ió‰¦p™<µû¦œ¿‰uOı­dÕ:ß…Ù3v# ãš7Œ°%˜yy·»P—óÃ”ÒO‚!hrµ©£I½“ªÛ6·™¡šeŸ£>JK}›NÊ:/0|¬\\u£OfÙ«¬¿!í¯.FÁbGÏ£•|ÄÕ1kPbïœºÛ+1°¤º ùXbñôê‘I
ÿÙY	ÄO}1ˆ/ø£I"V±®T´İ’Ci8ÆšrDYÆ	pr˜ ¬hŸ?|˜5géPòU1/ZñFpm!P³æ›Æz'«wW'"/à–}eê¹[)ÄDG”ôP)šchÿŒoi@KIf2[¹"Q]ŒwZ°äÇÒ2¼ÌEî§I×4Ã"ºí¡”ëH`/»RÊUk*´†âhŸŒ kFÔŒïèÎv~BG¢)L²xÂ¢pŞ1.–›Æ1kOÜÊŒótèÈ`îpòÿ&™´p–Á€ë	‹"ê;–‰ƒP;uø)sz¬ØHa§ÅNfï‘!f,üræ3ÖUİÍ„P˜ß‡r<¦Ïœv‰”õì¡×?Ë1ë»¹¡|,Ğàaàöb¾ŞYÒfC¢Ü	“Uºep<ø,í@IÎY>¶üñuÇ®¿Ú´Šè­€:PëÈ¿TâDï
%#›ÀI‰3wúuMv-ÒÌY÷Y[9•h@Ï#gjj¢¡±']şòß@=ŒÖÈ	>Lòò;ëÓpdß¥á[üoVÑvi³n ôCÓxÅÈÎ±:p+òĞ€RÖ¬]P©Z‡ƒ¥"ºˆ.¢½Kµ@œÖà›sìh¸~æ28±Ò5l¶F‰MufFØD¨úgÉ¦? £3$™šKvO¦jkg+HlÊ½¶OÌ¡Ã[– S»éë—“1¶±/VBO] T€£î{tÁ¤ÛLI–œ¬CWª%ò+²’|‰[`ÖĞºFàmH#ì¨„e^¤Â9ãcÛ¿İÑBê¨¡Á\˜È)Æ¨ô‘¹Ú|´ çáhkƒò"¼6j,†Ú*RÎI–•¿%”ÕYË‰˜k¹f‚İLóxbîëëŸ»§EÊÛœnµçëO=å)”Æóêût6&›aÛwEX[æ]ñ¤¢˜õ'fsçd:l×ß×°÷iyÔT¾-°¥U”x&ÓFSŒ˜îWË@.é±G\¥·UŞNîb´æ8œĞUâëƒs¨\Dz×*{uhÀ|müÑ§<µÑ‰Q©òÙ¨¤İİ9¶ímÎåaQCléGG)n’½¨=ÃL&è°‡ÍNõAE´ı „qZšËÖ&R±W§³pµË-èñŠşi
#”ÀÃxkvñd/7®ïö3$Y)]É´¹‹¾ê}C˜ÍÇ2œ½™5à
–ÿ+R#Béëf„ëxÊœ¥~I¬”OR8–«vûYÓ.À‡’—Ï;~­xPCÎrĞë=¬ƒ·eT2ÂE]°²Ë½ĞüÆ‹S”;(ïÄX^¨Gºt¤
B¥
ÆY§è> ÃãƒB»OÄå!ğ§ã?1#‚ù–y2>˜)iy½sÇ•¸]&bŠY Õ˜§–{°H¡.@LÜ²!|êCÚ/Â4ääÒ(Q1°ÌĞH#_‡iÏô"Åw,PèëìbyoÛÃ™t-7`;’L‡÷C<¸‘‡¸HZş!İÔ¼ù®G§T[håóMmœ®¢·¦¾Ã—3ÁÀVÉ	ªh=Lùš,ïöÄpgîÍ'¨ˆÖO¢‡j	“ŠWø»Å’åN_üöÿ´äà óUî‰ø§	û˜³U”¼qRÈğïÔˆÜ§ïàÃ˜OÿªV­hR3šûÛ“RzÊ#É`ˆı:ş™ /Z•Å#4qö4·¬´î›Ô	Ç3”^ÀP9¹p«XrÂªç$ÜY*4à:µ­-Å\àU­#ğË`: ††/Öæg‰ZÒœ†I›°œşÜdq:ºæTv¹W#eC»pí<Zñí\ø÷(˜zâG‹d™º­¥}]CzÏ©ô‡úcîú‚ûlŠöëë ]İÄ(lóÓ^™Âúô†Ù…V?­İqâël§Ó9ƒå6é–ÿ’T¾×o¨î02ê¢×
×cá]#cÎÕ”¡_¥wgUŠ•^ïTYÌ6‡Uß–TÌ}ØŠY¾§Hñ
7™Ğùrn§tiNÎÕû
Ò†uİÉÜ•¢7çïuºg/¨† !µŸn®ED_yV­Êù|GŸ` 8~Sx€ƒ :áü­ÒlÂ…úP´½V]
_¼
D¼ÔŒûµ€)Ë/ÖøÀ­õ´‹ìÀçP†ù&‹oÒ@JÍ‰&äî‘…éòîİ[jåÃ¹°USÇ^š•BiĞ˜>Š$Ş÷c#D¹g‰T„ƒû¿E¹?óBSi4ªêê.<Æ	"¶oò4êh_nï«kaÚÆt;VÑ²'ËLÜO† ÂuØˆ›}ÙaŞ>ÚmÚzÅ¿eà=i¥Ì£R)oz°–gÄ²lº`=¤ C¸!·±ÏæOä¸R’ÿ¼úïCC
,3¥)7_FÁ—åºáQ˜é=&l*ø5ÃYsz7.ùç œÊ¾ˆ¥ˆšÎP!8î¤Rw‰å'¦^Hº#!%Pr¨*s’	0wRJÉ£nYK§‹ÑÈ,çóôGƒ6±` ¥Pd2-Ó«äÿîœ{¼wš[ò)Ëìî1·œ8m9¡z*[½É(¿LÏs/Ê¬'¯£zNÉœF|e¬KÅ0Š„txd8_š¦ÜÇçíØ9™ÿ-¹uÀ¼œªmŸ^®Y…¢uròØ¬g	“ƒ|)‹qg}‡)2z?`Npjıì(NvË³F¿İÚJtçãñ‰_Ç¦™É•%ª§¶3@q¶RCgl=ÙšàØhÕ¤
vB¾âša*VŠ2¿´ìÿ{UM*K©öi7êj¿)¬JN»ßÒ3U*ê•$—ò°Fv&^÷è]®8e4ºça”·B¦Œ0“Ê‘Qf@núÆ8²¬Xô›ƒÌ÷mÙm Kò*Ü†NR2à Ï3‘[¤54t&ŞpLÒ3fÄ¹#JØë¼Èæh³ãĞ)e®7L\Ş¨ 8Æ˜F\Ê~Err	cì+Ä{ªÜí	s[·¸Pß=A:ò(šy7ü<ñOW*q€údR?ÕÉlmØ &](y¦ù½‚ùãømöPÏ}ßÜÙ¶©ƒVâ 0tËè|..î"¼§,ïş	²ûNÁ[Ašïms…2do‹µqhüÒùdŞİ0&o9Aœ÷nüéü ¸mÑL1ö©V¾áÑôUç;fñÍDŠox¯ñd²›K Ò``˜s\‡©Ü0ˆñºÖ÷'ìeÏo¼AKAá¹kİÃLj/ƒÈ+ÁÛÚÍ5GÌ«¨ËÚ ypO*,'ÛM¯.§Ç½íå|qXz:†ÿêÃß×z1¸Íì
MÖKB«r¬ÄfHÙcL¡…¼U!}4²¯nÃj£ß;›ñ.…=@/¥Óc¬›î‡Š„®¥¥ŠôøzîIDI}Ã¬«Ğ($Ëş¥{W
}!!A¿t"ŞãÆy9ò6¶R€‘»d#i ¸ª~h†ªæÉF+†T'~ÿq½ê ¶ùlûyƒvúPÉÎ®Üøş$M¯àÚİp¿ô/ÊÍöı¤
":¥axF{ ¹ÍR*q(§tw –J¿Fğ¢Ö¡ùPµ…c ¿Éˆ!˜?3øÛvº
CVq]Õä±ú%Éª*ßö÷W¥ùÙfJÅ©Ïjx4PË€Û /ô
ZênmŒŠ{h6¶ÄM§ÁŒ©!E½¿å±¨Á­Ñ4.3bWA~%|4h\ú™µ‰œlCæüR†UMGU¡`˜äÀLmi¾ÂšT£qÆıd™—èËx„]‹tÍ_õıÇ_‰rkFÍ!ñfz]l©ıåŞ§@9NÄ%ÈÖ³ÇÓG&R>ã˜Š3‘¡{5w·d#«•¹»O%mW	×™×ã»fbG6õø‚¯•’[¡†ÑH;ù³¢›6k$š8y/•À¤©ö¤
ìmı ‚Z'UœIL­wT°‰ïâf›y&¾	‚Sú‘íóò
†¨kÛês‘,¶Ñæâ¯ôBß’û#èk·á¯ŸÆmé1ÊH»cÆÄwş¡a¡Òäü#hÊ!a¾‹%ªËÿãåF³ÃÆc0­yLûò0é ŸÍ¬'_µÃÃ¯wWé„coû§Ôå$¾MÕhÏ3„.AóA9¹¥ewf.Iÿ¶PÆÍ>¬öôÏ¾uh %5!)†‹~8÷QêIØgbÁLr…ïú’Å]U€åj»Æ]³tZİ–şÿ
UÑq³Í(9,Ğ2º2Òîp9É­S"l§&ëÃNœ·îäşõgê’L­/±ŞM(\-¥ìÉÄ×œ…Ÿ–şÉ˜® 58ªÛ#WƒÀb;(RĞ‚	<­ñ7“æ»b EõvãÉ/?ã‚Èé­7ÆN`]zÛâ•îÁTú5ú¤€zšú8³Ä^¥ÅëEue§.´Y…Õk¼±R©+K*ëû¹È¶¦8û. ‡2çKmìeU”R "+-Æ±ÿ!]¸± ‚³üŒÓWá“ Róg¨©1TTíÉ¿JÙ5~\ôãÃI–Í¿ö=%êö­ŠÅyôÉ–ÇĞ>Å[N(i'¢á$Y×X¯6©ˆÑ¼ÇE[óM¢ò‘<dùÍØ†%ª^ı~#]ëÃ—*_¥÷È8ÑŠ_•4c€ã“Áó¡N[&àŒó(Kÿ$aĞ´+Œé”ÉX0S£ú¬¥¿ƒ*QôüwóozXµªéÇ(Ug³×.êğ†0$ñÓøñ}ÔEÓnÃ^â2¦éA™*dQäĞ=0™ì!‹åÌ(€~¾E9¦A†Ê™éâÌÂx¸ò3t ,á­Øæ¶IÍ|ÀC’ZôTuX=V]éÃšÔŞì½ î•¥ë!jF«~¬”>ÇÙ*Å¾&—Š¿ıjÉMë±
O[ÈDÇ+:ÉvZİÒ‡ÁÔÌêæÅ(/w-x¬õ½œ[ÙSÆabÿ;çx¯ûlş­CîMå…[­Û\âŞ«‹%›3à“i¡ˆa‘}-Hv›8·
ûQ`ögK"»6ÒåÏÌLª4ÌGh eÍ#¿Çˆ8wiÊwç\²ÀHàŒÖÖ¨‡_IÉ9
ãma²+gøŸ{RğláİsÚnÏöÜÛ.gºµªÿn¹îğÊğÊ±aßà†¬HË½3màá·E>Ò®J#—>dÈ—'Ë~†j²¦hµÛt€²…ª)¤’IfG•.2Oßü4U5dôÑßAï·€„îyëóQ¥¶‹p Û©›C¬%"5Kbğˆ0Ô²r`ø#æÅ…åÙª‰?š„œæ~
Ú–Ôêò	ÒR“yåÑ“t‰èI^)d:—¦4À¬:p½ıÄ¹®S÷B‡Ci%‚-Èµtc‰º“ïrÆŸ	]lt#ä‚pàğé8#Øµ¬ãö&©‘®pê}œëu¡ëI¯QÄX,Eäu×8BæøÀ–Ü¢îÔ°&an\ßÉÑÒ!;®@«é„róŒXH‘”eA:qÒ»Îßàâ)ü‹IşSõ_WC×Åûù7ûHÜcM®ê!pUé¬¶-ş~Û`pgÌÅ] §4ÈÊPĞ	:DU&Êµ:j"ÅzUúƒ,~¬UŠ÷r]? “J"ír=ÂÉµ©®›t  Ütÿ¿{#åg{#6Ş¨ÈÚmÆx•…á±z$RHÑÉ2æ£·É¿Úê}^u0î#û«¼+Ø´Áš,¶ğ<c„§+›¹·‰ ¢_ƒ­Ø°œ>*“)¤''(é¥æ÷A^Ñ.«“‚ŸQòNQæ„Ò'×gÿ"FøÖQ“^sç)Ãwu‚ÿ×ë6Ä„ÉLÛ“÷|œ8+s	æÄ³mÖĞøz¦—€YÔî­x&<£VÈ9õ¬ağNğ¾Z%{œ¼äRÙDßû7¾R!®É!&÷Š0€Ï»Ğî6¢ s İ¼z£5§Šq‰ŞâÃŒM×ÌV¤5~ªYR‹ªé@]ƒ½[ÓH¹°Fjİ|'ØÄ¦Xš/‹ˆlÆy @pyßÔSÓğD¥×zŒô%?I0¾’ï,¢å×7ÉŸDqr"x’…ÖT½ÿ~24g‰…Õ¨Y½ç_•9™¶gPi³¨âfÅZH–»Ü–z6îf+.õ|m±áøÚ÷õ8`xĞ?<î·§1ÌÂİ‘Ü¤Ô_4}ùXïêìš…Áí÷¨nä´!˜gø6GÚNÙYØ}>áE¦¨ ~I‚G¡‚Êîé;§Í›Ëø¹tÏ9L¨õ=$kİ¯MKëø-ŞgÛOkw -ÜDF¥õÏ0ÙmeˆÙ lıŞ3‹	ÔĞö„án(³oâmI?V•¶Pˆ]±ÚlŒê(K†ûìÅzÿeôvÿhcÉÊ,PÿRp†åt €‘š¸¤œÔV s“ëTz1;ïG’+–Z;M3/Í2ù¬‰BÃĞl
íOÒ…t¶¨ì€3ÿ:4ÈriÒ¹õ'ÅÃ`BGäƒ/ÁÆ¦FeÏöœÇ—!Ka3è£Ï·=Åß#Lù&¾ò­@òœx]ÄİÉYˆÂˆºòå‘—h2Eô‘P]ÓÑu“ÏñO§2_80ó\Û úröhîë³Y48@ÎÂAjlxH×–R÷>ÿr"y:’Su¬ClG½*ˆÎİ<ƒ%Üôaôƒ:Ã4Yv@UØùê±Ûêg÷õÕŒZÖ™wÏ_„$îàÊàGZ_$[vÿr\üOùUéGºËMQPÉ¤,ùÔGã-€6f…D}ÒÚ‘Áb;Ô±İÊå]­¡Ê’±îÎß^€£}ì4~ÜQ#“	 †»Sƒ«Şh›Áù}®÷£Ş‘•¸FO¢sÂßš¶œLL1z‹fãKª°Ev÷)ÔÈt1Ü©ı¾lÌ
BÀgÒ|Î(ÁíåóNÒÅ4£'S¢7zijNjÈ¼Ã‰Ì¨\äpÿ¹öôws
àùøí	Ãˆ!ùR«kiûsï tÍ½p(ŞÂßAïE©_ŒÅÄ=^µg˜“o˜;x¬~ï3éÕÑ½sCƒñé\ïšb™p»"%r“ÛÎÖ>›ÎóÚËâ•"2T+Cv§\{h»jäµÎŸ{Î¢š[Šl?Ø{§}ˆ3Éf©¹–´9uq*JÁÓ[İk?N*rN‡.v0}	 ©‰âÙ–ãó{š¯É™G„ìâ`ü›ğyúÆ9ÛÿÁM@Ç"Ï3Ôó;	…à‘‡ f	8¾ìòˆÉGlU,Äy6nŠ—?5!&ƒ½uÈÅj ù¸æª«_¦kªËSçs.Í“Á@ëX‘Òø~‡Ó©Œ#@şñP‰ÇÂKÉÀ¹GFİhàfEşòFòæ‘;mâ_!Š&<›eÿÉÌË“=”¦åÊuA4t™¨Q³Ş—%¿ØÛÆÇÛ¾GÒ¡j`øA]tv[ØÜy²ê»I4¸~<´}—µYô7-C‹éİuğ­C<; @Và;ö®[óKq€”Ûšåô@±X¨ITz 8x7}Èd»v šUØ}@‘¯şà©iÛÉl‘O~BgÊM§Ê§5nÊ~‹‡ù}?³Ï½
‚WLÓ# ”?y‹lÇß€èl­`uxíÚ7¬ÌØ›øªñÇF‡«![í‘‡Á_mywUJ¦©ïßôÊ½+››iÈà•»ĞOÎºwtd¤mÉ÷aF>xØ××†ÎTĞÂò¼XWÉMóVZÇ)Ÿõ÷Ï¢èš©÷qd®“†«2†Ê9¤ ¹—ÙèòÍÌÇËp[o—Zhq¹àÎËª8J;ˆÔ:œv¾O•úzÕY¥˜q§şÍğ8÷¯ş hmíí~šp[
èïÉçã%€Ô„EZ£¡(—mu±Ã¸Úî/7°20 ]Fù¶‹wçjYˆ¾6;¯Ü³,å×©d«s67*¼-l"9h%(î™*7ƒYObtÃècæ=mWÊ<«•¬…Ùåµ0Í~g9Ä6/„2ƒBsÅÎ‡Åu²’Óz¸Gû®‹-ÅDá¼‚YG-oûÀóËú 4c÷<x’=i† §s˜–TWÛ‡¶Œs¼h1"³©@*ó¼»şÇ1Šâ`#õ¥èÅ®¢,5nZxÊşh0ss&76G3¿3b
öaåV-á«¡Ş“ç2•…´*aÂ|M}ÓÏF·ß@d=å:KĞ™j—9ß- WÏ6 õó„å²ëÃk¶8LBº^úàö|™J3—¦›%$Ì\àöÔÍ Tù6ïï,Ë.£q®6+™‡öà£»;¢²¬‘ÏE
}v×•´1y7R;m8{«Z-âŸC¶½T°osS'^¢-ã¤-ÉØ4à$óPŞå÷¶K)³ù.BBz‹
ŒûA¼ç+vE)É_Şúl¯ª—İ1ÎZ
ÖhF_íK‰í¬lEä}¸QıÛ…}ºàŸàñÎ5Œ;i˜"i[àh.‰?ÂÒÀÂ$š¹Øªµ­ŞÉl¸ÁÙä.pË?p¬U”ÆğÂœk±¡ˆ@Ò„4%Å[Ì{ã“³úÂûg‡3—²­è‹ËƒÛ´ÒdiŸÍHÏìê¸–“ÖÑZTœ/6!Ø6}/úîG“)d3}ª‹cÑª¬„Où~¥NˆÊ«^Ğ×+X¢«,¶EÙıAÜè‰º‘l˜­;/åM’Ææ°Ûh%q˜4õóêS/5‹.ˆ7ƒËıoa~Ò¨‰Ãjâ]gA’„çˆS(‘æ,\ûİõø2:AjÀ#gò\dµãdÛZÜ•(j¯§Èu™´f$ÎÚlÿ“aRán¬}îô·‹Ô±&)æ"‡ÂxÍÀœğh±ƒáá×İ„µÔK+12:ô¥
@…„+H4o
Ï:>.ÙşWhúØnÖ]F@®µ&İ†zã¯¹ëäì^4JØøEùŞø¾„ÚH‡şòÎI˜bµ9á—„YP´;u	ÿkTEqö*'úÏgÀ±û¶Ø‡*å¡6GL'¿}åòÃ¸õ ò>ğ;lßAF-íN©SãŸœ²1gÔY»\íÕ*_™Ğ¡ìT+¾»`ú¸á'ÄY÷]÷ÿDŞÓ‘„V< Ñ,®+Üm[Nƒ_ªâŠR)œˆ1,$I'!…iSoÀL0KÃÅå†m5xpÄRºq•>Z’1Ñ©RáQ3éŒTæ%YßWæPºı£§K0OU*âÌ)æ>¤mƒ©¤VÏ›FlüÈ½Q´SÀ›§Tw.ŠUÙ¡åaƒNÈ¸:‰‹O»½ÓÛ™¦`áâÁÑƒö¢‹smñÒ¨åæ#˜>Ò
SW”YÄº¶ÊtíX(ş¬A”HÚ.¬ù¶Ÿ…ÿ”4'dó=ÂkL¦ˆ/\xGØ›ˆsqè§ÌqÍ¨¾½Î÷]fÀ™Ùàtkş<˜V°A»í­şn ó“*«¢¶óUEB^K8d’Í
Å…u^ù¼GıF‰œÿW JL-×²ş[8`Ã¬ˆ n˜ËGØdl*)>€£…¾&«'t÷óî¥ïğ®İÔıÎQİ®[µôJGõcºZµ³Çdyé#ÁqnDK«¬±Ş
`kŒyÊ½=b­`õcQz¹û™ææır¡‹>P¿'K&Ş©gÒ¬–~˜ÔåÎSe³^›²ÑÃÏ/¸3,TùÙä?ÆPÇó±JÖ³ ›bkÅõĞ»Æ.œqÕ±ŸÑ!‡Èã›f«ã(‘7ía/H—–ÆıĞÍZegJi~<åêMkÿ×O	Ì)&a±§ê?ÍáİZ•]Au7’âã®Î‘TGşWVC»Æ@‹DÆûİîeoË’6X¼İl°:¼š-#)¾<kë#Æ–Eêº½öñ¹R¾ÅüNtgH²äÖ/ÊÿûFÅV’Nd¼Ö¸èe¿…m “,©YÅÚ¸ƒŸ¬íhQÜÕÊÙ'uÉ‘Eâ yçãeŠÀI“»¤ÍŸPÆ–JKYg
Û Tœ€³  µx5ÜÏ^ÓŠ#V8œL8~	2}µ:ZÒÅÿŒ¯ı ¡µ‹ã¼1-x1Aj1¢„S>dñ¸%óÜã²†9;Š©Ÿ¼7’;›ªw%>"ñ¶ƒ<ˆ¡‚XèšÅx£t¯Qı/²yîjTùóy› ×¼¿öhÖôK/î6ÄÜ>W‘÷æÈ¾U9¢Êf+7.JCjoıÉØeÔn±Ä[Røİ/ÖrüóE›]jàø¯é›“Iü-4ja)X¯)÷fR<dZìÙ€z¾àÖPDpÂÜ›÷×å²ğ¯áG 37±¹¯•ˆaË_ç¹V‰,íÕ„ãŠoèÒŒ÷­'Àì@„ğ¦õµµ¯ÈçÅ¸¸JiÑ³¬Y V
wÜ¢	A~%×`!‰„¾dr¡c@²Ù‘D0ªÛ”` “°Í¹)ÛøøÉ|²ŒX¦Ìò§4ûv';ÂRŸp|Be^›mTfNô6¶‰€ñd{ç@°­Q#wS@Àû†¸ŒgÊ;NiWÏ†áxemh-¥qv¦äbò×+äº›æÕ„M,[ºšıºÉ]FèÈ>ÂÒj£’¹$ıªÑwİªÍYiİÛpb¯ç#µ'ã‚îó²ıö™ÁÓ†&a/ƒÓÈç#^-.ÜjØÄEyŸCäğXqÒzQ`5¶ö{œÊ±áÜãFÎr-]œë+İf¢Ì“º7¼°IdÏ—Ôn?¾í‰»£Á¼¼²{³¦§Ä„‡9ü¸ë æl›ƒ… oåĞü^d¾Õ8¢Ì€¸3VºH¬€-®³sõ«UÎ«2;¯`"ª‰ŒŠ<´çñ=
•ÌÓ?l)ô TÀyzl¿¸íê†D”B€ 3ãpkªI>T×ií
 i˜=UÁÜ©²Ähd{<)ÑşÀ¤u9Æ¼¨Sª}¬ „¿¦íO¥<ÆUíÎ¤¨LX`DKG XÎ=(w~Qïc„úe3ƒDÈGÄ´\²1p“ÛAÔë
³ï-IlÔ‡'ãÊ¶v'$áŒ äÇd ë7 	±†;)T1_\ÄÛÆÊQU§×’%[áö Q]¿9’ë˜á G)ˆ5/¼Y÷B]zâØ/5LEoŞf­n~ïÉ÷¸œ’9Ò‘¤e¿y3µD7g
=P·"L«¬’¹¯Ü‰<gIr€_Võù¦•SÓ/&iÇ½ ·¡Ò{ò!]xgœT |÷•Kcº´ôò¬¥Ô÷˜ÆXmÇàı»!"ÜZöÿ¤ûÕXiHs7@æi=¶ô”iĞe\XA²ãp5MyQYTTî¼ü¥ŠÀÙD;s±Si´(¨ªÆĞš8½ÂDªAÒ²ér}@—	‹ wqM‡Œü;‡¯x›Å~OW_ÃšQÑväv¯¶ÙRŠÂá½GÈ`hˆıw_5À5îà5¯Ã!Ç›¸¿®DôÛÛ3gtK\0Ém}´ÊŸ noÎv ŠmÏµk±u§6–ª-IVW4øéàl—¬ö¾¨šå¶9P›º½\ØÅœ[V„¸'æ(òÈv¥.ûœSü%Êÿ#õK˜ñÂ0ö“aE¼0sµ›L4Éb8/ÚyÛC¸Ñ•êæè)ÇˆƒŞ?Ô&(cÚàf<üL‘ï4…°ş|]‡µ;€iÀE ÷ï|û`ÄdÊVeTïìPÔ™F†ZÚ2ƒG</\˜Å>/F–cÉÃŠ¨ÀÿfI–Äféñ*ÙŸPÈ]À×‚İlG/™!8r	ÕEƒˆŸ¥äÿgôLF…yî•}ÓOÄzBé—BM½ÿq¼b+ôŸ” ãòÇëäõ©_cÃ Hf¸´ªSƒRhIÆİ ÌÖÕ-iŞbf* ¿ŠXÅ ì.G«¿c“GW[6T8RH/óÍÍj´©{|¤‰¬È–ƒMm60`i¡5š ¿ãŸŠšD¼ù4Ò—%´Ä5¶>ê[k…öè"Åˆ¢×¦½«ÿbõõş]8b3 Ó›áüÒŞj›„¬6xß‹ëÊ¬Åâ ªçö¿9p– C¦
Àmq,Ÿ¾G°«¯0¨‹Ï6úJË¯9ÙÇÛ“’¶.g÷¯CÅ¶õ}^›‘2Œ-î	^Æ=Jüe=Qsœ¦V7¹Ææ¿%\¿"­AÚµŒCm`–Mƒ“Ä‚iâe¿äïô]!W¦ûÅƒÉÜ®®nî3¬ó aÁ‹ä@.ájµ_?äŞQàüow á-íPŸîó5/( ÷9ÅßøÜe“_åW¨Ù±b.!ÖKÁíy ˆÈ9€aù©Oë*ñ[
œ$Õ—×cƒ1üš`uS[ÍJ†Ø¶Å	Lí« ¬F.´ûü®ÏêpDıvÉ¶¾ñ–#ìDÙúeÍná³0}UÏå½ÕêÃ@|Tymõ±á/ öšQ²ç{f’—G×«Ç´ä1ÛÓn/¿	ºˆ$Æ€ig‚–Jèí„«lÏÜ°êÌ,*’Ã‡Rê.DÊT¾uòeÍêğ+Îú¸bÆWà%6ùOxAûJğoDtŸŞG…àb3ÃÖ
¼kƒ1Î#í~ârBöß_
ÙŸèZo[ŸB ¸>uy~ _Ê4Xêl ‡4+1¿Uq>ú.éK~6Ø7F3Û!oÁ#ñ§ 3%«%’oÌâûKÖcË¾¹’’ovéıèmº~/5"!™<Erƒq°@CypìPõ û°áèÄé¿Yµ—è­ŒäŸ„*_c£{õ	ûg*Z€ˆşÅ×ùõŸ€„ºÊX:AàEä0ğ¹Ñ‚ÜëgišØ°åÈ¢I0„¦ID½Çc(B«aZŒ 0åm¹lş½Sì,6P@‹O„¢Ê=Ôi<*¸k‘=ÜÑêQın…™oÎ+[&½İèS•2"7Ï4´åWó”Áuèc‹—“¥ó6Ö}/u“™·¾ÆåİÕ–=ûšw6`oâë\mO—EGvçA»œKáiK×Ïh=·•0!ËÈ¦¸¨u™$|®ÛF#•[>Ø8÷y¨[ß¾ZşŸ®2f 
š¥4·«L6ñ¦*1ÑÄ€4áM )œs®™³á÷o´“¼âm-§=ÚÑ2‘”
ûã`Æ86y±é#^Ü*°á8“¥
®>yz—E¨¤£Ñ>¶„)\x8v!;¶#4â¯~Ê´ŠR´T «L7¨~ ”hv 51`Y›óÛÉÓ8ê&ÚŸÚ|‚±Í×†ú^â×¤ç­‚¶`„QŸ«…›²3·ºÂ«>Ñÿœ!ÍÛ¹ÏqxXÙ’|@tå»Åˆÿ$…HügT¤L…ëÛä <îbôPÇä¾T>x[°èiÌöìH~XçíSnñëW®ZßŞ~¡p@Ñ¸¥*{ıO7‘‰	®_vsÒ„4ÌÚ†ÆÀ*F­t}’¢WÔF;„°ã°H°õgĞSICKÜ0K]Èdƒ‡ö¤İä©Eº¹çŒ/úßw¯¥zZp²ß$¾ôC‰TêO^•Û 0,_LfD ë!™SµPªEúSUŒÜùz¼™«
üàxxƒ×õ·Á‹¢ôgúLãEX#!)÷¬‘XU .r'AÓ_®<Z”Àôq¹šËb)åûHºö#€é,cKTd ryŞaå£.Ä6ªY!ÖÌXwÙñmä "ş9ú»œÍíÌ\y¬äÑPENÚí›•¬	€ÛöLğ$ç±îµşùQÛA¿PªÆ ]Ã÷ å kJ‡Ëh;Nû 0+Ùèµ?tŒ^ªÇ¸ 9ı+ùßÀe´ö	nsÜP¾újõ|%µùtùí
74ØCÃâË„¶U{!l{ã$†ıtïÖøëæ6)ûõµS‚#>±Fü•²/QDTx3’pòÍüÃZÍü®ÂÇ¨¿5×q_ë‡a—Dì~Û‚âNîni%ÄH+ö1èİÁrÏØ±¸ŸR¸Aªˆêåû~¼Hz"ï¥“Bè:$NXŠğp×¼Òx>_&–Õ"“Ëw¾Ú™ˆÓ×şÒĞ‡mËµ€—•
!{‡*öJ*Ş®¿İ¤c=YCt¸â‡è3-šÙØØ`VØ«§g‘"-ö¼©ÿÏ‡£ÿşS*zv3@qµ±¿9wI™9Õ+ûi ¼QŞÆ.©À[q"†Yâ–_Ã1/",‰„†.UêÖ`q|:½S]Ø)›Štä©u´ÊŞÉ¿ŠY¼58é¥qúw@uù_…ÑjÉpõuî¼Éıcª¥sÈh®="á€zyjıdÊÁ¶?è=É¢wc ’¾eCY›İm04cq@(Jvh¶-N…Ê-¸\Ã’0Ë¼E¿ö}ô:{•£IÃE2
+q2«¾mÿË
Ñ{…­]û§Á&cÉñúì%"ÎmF
é“&fÉ‹ÆõH¯NÅMøãó©#Ú–0t‹º'Ù¨ús•Îs„vŒ·÷„…#qÀø0âx[#\Pç‘è5zõ=y´ş½óyç¢rêm‰š Y#ÑJ8]‹üÌêô*dp ¡‰~ğˆ9µ¡H.ºT¤k·iıÎoN£>A uÚÉÑÑ”i‰(hï¯:Ğ6`ûF]ÊïÜCcıyÍwÃ½ZVáá¾bRfµÄKšÔlOx5RÈÒM<¨İÚºgÄPxã¼$ï³°¢ Ç;A\}Éí…,ı (ÿ !H–¨³Å=ôrâÏj0H*û¾=l?¬Ù)w»=ÕM
5„¹¿Xğ	Ò¢&~ZçLûÿd¸I[ïuè?í&;œ­ÏHˆ6—b Y€õgÃ”^µäK$O
Ÿ$ÏgAªpwZq`Ùi_ÌƒÛ^¥3w•N081vØÇ˜#†*Zdõ?¯¼šÊrÚ‹Ñç\=¡Œq$7ŒÌ ©:˜`‹p‡,­çä7ë¿¾ˆH†‹4LÒíªÎ,‘rÇd¦Q*ˆû¼èOS¨ä¸şòvÉÙQû9™Í”>œ5ãHÊôlxet]ÿf>Õ[z–<49·HşÓ9¤ïls‰_—G·‚4—ã°
ùàÆÓê¤j¤ò¹fùT)öRö#mWº œ¸Ìå—^ÔÌ_«)s—=9ã>¶„;,'D‹e_”çŞvÂPXëK’á-Ò¿{eQ]qe
ßÚñøuôãUÆšnÛ?	v4Ã³$å™¶‘ÜäêI­²5œZ–›À+§Çue«TAİÄz$U’qàfoœÿ=ş;y<ßö]¾…à™«êÒ‡ìu\’±İÛádÄÂ`|OF_Ç4¸“³Z7 nSÒ¶üÄô¤Î4)!{k‡n¯"dûÁdnO»ˆúº}&âG9‰ö+˜Êƒè5ÛU’ÿz“lÃÍD.Ì\ºÇ5êä[xİ,v–ú" >¦ŠqÉq¯Œzd‘?j/Ûi÷³…d7AÉVŸ‹¶ft_3/·4¨í¦y´gN¯C?Ûs>‹¥R&Cï$¶”-ÿ¦ŠİŞ¹PS‚U=½YbBéÍæ–ö€—4¶VĞø}™š¶¦e(¿áµWÓÖĞPû=­§”È•6´PT=ô6¡ŠÍ]şJs°uŒ´—²BN>È6uêù£Tˆw»İHõ]MXH–Ö0œË|R#Sµ,}¥8T‚vÏ	uPoB°Ï^òC»é86o)ù‡‘Š5„ïÜnÂY=íMéÔê%Æë¨¾-<gcP"×ÿi¨1KÀ)½ÛéÃ×pQ²*Á‡k%dkÆ ´¦ğm?¸:Øhó{;¢SÍÙ[Ğ·2C‘síwÿo’sãÆ>àÜÃÎa{ 1«Ï©^FÔÇ<›ip+ìXÂñdrQÀkjÊaØö+.“|ÛÌR3i™€%`E8(O—û
)åÛbµsm„4^¶kU¡’UhêMæJŠğÃDYøäTºR¶ØÇ®cå2ô¥Î¬Åÿf»ªT÷ª¹gR S½ƒ° ŸHÕ>¦©†T½{©«ãîğdADhêdX§)'>ë#øñ·XãÊú²õ[5ÆV«jI?e·ş4c…K6JF“+c—vçİ<‘¤¾òn„´„²‘—¯Ep$|¢›úà°«{İ®–Ú2ûË‘Üdc.Ğıª§ZÃœOƒòM—ôÙ
âó#vœ­Ó¬ç–JÇïğÅè{œ¢1´s© Å¬’Eác,ûQÈ9J¢(À—ìïûÙ¯p/å·2‰P‡˜µmH3¼"ZL^iÀHú—ıòœW¥šíxÒVNŒ!À/xJm*>d™kÕºü(»8	'Îà	J§·xzE‹ˆCÄ(d“´höEŞE\Øß×œUÃß$ Ã"µÊ2˜’šğ5ÙúO)] 4à'1É¾{…±ø{^ú1o`D¹°+š[«qz
¬>Y°h9?-¿Oã4×*†<XR\|=±øı¼-e>!‹**e`JÕäŠ¹l8gßŒX@+>àxÔ¯,ê2âÜÑ´Q`‰h"–„ò9™wg%ÔAüÛÊ‘³i€—şì&ÁC’ï29– Îx3l±Î(£ó‚fÄ?'T”JY•ŞGâ'«Š3cµ‰¥¼•‰ˆÏQE~Ï,õóßFc³áÖ·Âs¾ò2İš\>VT¨Í-uQ‘÷$‘wW¥áò·ıKr Ï[üåv³ß±Lÿwa/·õÄ.T:¥Ö†±´_(Àï{Ã8œx-1A´X:˜³FÃĞ'yğW¦8X„O+ïR[­Åôˆzüs@é«§"(§aÜGµı‘ÓİÕ¿8“_[Õ†”kBv,Ò8zj±ÛX&gµKÌkø,Ä´4“…0XÂ'M¡¾ AcO„ >1Mj±!Ç”LÿH8D@Ş¨™ª%äŞh©LQQõZD˜Ú½`µ0„Nÿ‘µÆ„º}ğÍxÉ=œ±‹ì“¶ÀPšêÖYm½k)•¤ Æ[[yBŸ{u„€qo^-¯1,w"À]ÃgŒK bìş@¡†Pw9ëS‹7Ñ89I
käƒÚü¦C4ĞFGĞ¨FQ:N‹İ+ş+Ğ{ø+¿ŸW¯“¬êµ¤(Ôª¿Ì)zhÂOÅáœŠÉŞ¢ºÿ‰ˆ}s>`*İÀ Ò¯‚Wã¤RœÓ”asµázÂƒBäeiVü­Í5NSÈæ^=±úŸ.=üö2İßé¬’ÿñmW“ ÿÍÄÚB@›hÌÊìU×töö•òîn6ğğqkIê Sû-)K`6ÒLe³ÿE ìvİ˜O;)¼9!…€|Ozò,„2a‹Ó½£K^¬ŠÇävYö`Æ¼Ÿfò°ú(æ4 T×QìaBğ€„?öÖ|3'¾’I¯%„]ükWwêëP˜£¸FÛ¸eÅ9¢ı³…ÒÌuF-E¶:Ü<VµÂO¾b¡˜»VqÈ2¯†¥7İÏ‚
wO#´¹J=Eƒ­Á÷S1_¬˜Ys_äXjuÔ3a¸"èèK¦D‰‡šäìzƒ8N+§Ås­şèĞ¿¥ë=ÿ¢tm­h²Éş6ÊÅ?»X÷|›ncÌ@ë|¯£Øyˆùj»—@(îépOÕ¦œá&ÓDš–')$°º})øO±}à}%ÄS™zÕÌô¦P–©oBJ2‰­‘NĞxnÛì$š¡| ªÏkå¯}|ö¤¤I 9Ï¦0ò*Ò|5	=ÀòÒˆ7T('5µã‚TÇ{–˜@eJ#9R²Ø®ïÉf[$¾ğ£Â|}‰kJ	¥¦Ş˜ÿÛT¯ğbÇÉÖ(}ëşyoTù=(W2p­ÖLkdeŠŠäA¸öòì›ù– Xlæ#Pg¦óÅP” îÄÒT´cÚ4X^ó†Ñ€‹ù†ë@šşz”eä|é¹Õ)n&%võ'rºÈ•ñúŠœÁÖ‹­Â{@a@Ô¬Üä3Ã@zX£)\8ì´ªaÄL+éxÂóJ<ÓNğ5%÷F™œ 0Ğœ|TPYcm\T)Dƒ1ÊÇäŸ\Ä2¿K©ĞÜ*i½ü¨xïŸNTÅ:îyƒU=ş{¡Ç$9pÅŞSh~\GIj4,ª	¦`8Ä{zOòãÓæyœª7#”½µ´İI
İxdC¶³55Ã¬9õ¶1¿àè2Êûx³¨ñ-ræ¤šk”Ë÷M-©Ô6ßû(,7¹ñBöOÜgö<-ö+ÀA²3b”—›¬ôÂĞ˜iÔJ¢£Y9pã©æ¢Áõ1ÔÈ&S|zDr(;•õãÕmî<±K6Eë9ÑÉôÎÒjÉª™;»ÜÖe¥@"©«¥C†ÅÓ^¯Óèqêj’ÒÓås1Ù¡Y`õŸßG»ÓªºåÒ[€ä8Œ˜jrîƒb¨æ®i1­^§m?ÌKõ¾®ˆsnéÌ¶‰	Îæ—¥¶~ã®%êXy¬ÊVÍğUÅï"‘^km<†Äğ·ÖåHéN,gO%­áì¨‡]`TC/5;ÂsH¹iq¯ğ_¸ªÎ2²”ÓjUÑ0ööÕG²RP’ò¢Ô<IDÚÉ¹/<1`©‰Ó¥l!ÿcbîxo™ÄkbS¬¡ÄŞ 7ùù±ô½õ§pòò{-HWÛw;7¼	_yÜrK¥5ÍÄNgõ¯á]XæÑ«q, ´a ø¨^_´k$U&Âp…H^j”ÄñÓoL"%A0L»Ğ6Ïü‡£— ´æ(Tú“‰xÇÚY&¦•“†5öVíëf¨³Lâ4KéÑx^©ıç¨âJä–§†Ûb	fğyhØBí£W‰_:Ã™oNı"•ÍMû#š·æA$±ò6bê(¤¿šUhO¬øïóKÒŞ†Y¯³CóŠhÎ–gbLšæ™d”C4zÀr>ùu£³˜ZÆ2­Àw'Ø=è¼N¯^n&•ID@\Ø7É”úz–ZB„˜eGk^å±*¤´ãhQv9‚û‰¢Oc}lLÊAœ

kdRÉ†Y0ùsW'A£Z	VìJPÓ‡)`%3^Ééùw%äÃsÎË7Œp—Ùiv¿;â,“œ"7+zÆêÛbóæiô†8À§`¨ €ñí÷NÑĞ»¹Ÿ·úÑÌËyİœ \ 7Õ=øn&ˆ€LÅË+˜	?T‚s—¾Z@øÃgìnWƒ†F°fÓ5ŞÁBtær"”¯#œ5êk)üyì©¶LAZ€ÉŠR£u1¤sÆ¸…›0÷LmV<(]{n×ı¤ô«ÎÜ›¸G»‹ULK% <ê	Ø°><±.†ƒøö‰…JØï
4Ê¶	µ‹üø'€¿Î3¢»¼—eª•UìÚøìÂ~/C­P†ŸMRR\hûy`3#Ç×T¾ho{*BÖÀ±"Põ>ïÿl›!›…­ÛràÓ—)µ[Joº^,3}ãÑsø‹7ÂChªØŠ“X’QIâ‹V’o=ßcšÊÅªá©>Sô¬“ä´¬D€°©i—¢¯e, ÁDo[ØÓ]yC'ƒ2,×¸ŸkKWğÍLË+sêBğMvüSş|/äİ×K¶4—Æ(«´éH…ñKÒÈ|ŠèÇr0GüÅšÏ’Ã) Ô_TñÛÂİ²ê›
Ø#ì­I'WÄjÇˆñòJÿHcÚV’Ÿç'"¼GU¯€fÆ_cÄßAÚ¶·P‹J2ÒÑ‹ÍÀ½uäá«Ê2¢“!Ãp¬hšö…•%g¨L&„º2ù	ƒ=¹ã‚:N|ã)uÇb›RÏ°~s§’R<…Õ­^tÍ1<v,‰,C/áÌj«CåhÊ:@ƒª|åûó<ô/ìÂIÆâ%§Ò;ì|Qà×SÑ…dÒz¢¨–:l÷dn—Ù¦úõ3ÓÛ¶êŞrŸª‡¬îVÆ:D+PK‡‹«±Kw¥=08¾ş€šs`˜:ì7Yf9Á	…”>D].˜îòAğ¸ÿy7À£Jxb’gPÍè%ÈÎèwa‚Ñ´€|(Î´££DZÀ—~5¹N@gvHáõŒ-d“êÚwQ—ùP€rÓÃÛRÊĞúµ
?ê×½™·ÏwÂÊC#sræ5Mó*r‰`¢/³íƒõÑ.Õúí5>uºğàˆÄÏë½WõO]×¬- ÷`Å‹Ø_í–•CûÍÁ5å8Zßœã«¤ØT$M	{ÎCŞ7V»`Şƒãd¯œ÷šÃRÆÿ­éxL0q‹Ş(iİ¬8÷š¾İ3h!´Äsş.T- =ZM¦yRI†+RÒ|ö…ZMUÑ›bçtğBòÙ7Ñ Mü>ôl-v!S(°¿"Ôn¡GŠ•¨6j·ÃæêÒfjDÿªŠA³²·yö“cçğS©\=ÔIæ¤%ß{±=PVo¯
5¥Ì´#ğº¨–»Dë~ÙìH !gƒÖù¦
Ò$ $°SÄP 9›=Ê.ÏŒ¼,ŒÏ­A½¯õ¡6ó÷îàËëÔ
ÙM-C	‚üñ<iàïq<•_t(jøÓ4_RñõõIF<	a•ü7±•tVÆ—Ç¼°c¡tÅ—nÏ3gl_]°W‚¼ä¢ÍŞA~"1áW3Àtgî+8­éAf)©÷1k¼­ÔöÄßX\“´ø6ü2bÿ•ŸïÈ#yZæÍh«OØxßUkÔõf¦¬¥$~y·­»s€©‹ùyè\	yD¬f+mOÄN¥gÎK°¿å´İ·÷‡Œ‰öÇ.}zBrjîÌî¢ÓÙğ‹S}|„­vç³mí3ù‰½ëDÁ‰$ Ô.Çq÷)³úe2o-›LÊ=Ğõ¥Ä`ƒğB°¤ÑÃ:¬~ ^:¬dæ(mšY¤ù\HÚšiúõmÖûU>ò³ÿrAíÖÆÿéáÌæÆ|ÖH×ŠÂ[‘©¨Ò×²ºMïÑè…EpgFëMİÁlĞUÓT•ºê2†ÔzµÕâç‹ıÊjIDøCNÖ&ŠeüË©+XÌ*RŠ™ûö‡¡\áı#{ä ~Õ[¨ı>åWØ7=‹åM”—îÂm±°ê\MH¸ƒ2I2š«®ö
q²ÂÄÜş~Ğñ+?OË3f·Ü†¯y9Ğ'‡|LfC6&­R&]¿iÔüŠû ÊšûG—÷•¼“dd
>²Q÷_Š¸S$ªš¥æÄ‚´ ~¬É0çM8zò†E^.at®±
Ÿ|¥%'×/¯Sğùµ“9m™yYÂ˜¨Û—¸ZMi`x@w=$·PSÖÃ:CuSLÛ·$"Ğ>bBÜ4tª{r©x´²y`[È®¤ëŞ„aá<F˜HèIğ¥C´c†	†1d¤¯“S`ò¡:¶ó‰õğ	"onñ|èCi&Yğ¸™qYŠ#áª‹Mp5zxu€>ª/SÈT)6¨AÌ( ¦à~­C½i˜!#Ò“¯+6»f{dTğ¸üFs'®D@êsØÖzËûÅä¿I“‰Ã¨©åˆEãÈY`m€ô×8$z‚£ş¨
šU o•SÏx+¸¯½ô©}+ä w4½L áº;ÆŠÚL"Kíë0)å«#1crqrâÆ„÷V<\èVÊ•ú¤™îC=yãè–‘tŠFØeËĞDÉ›4b³=‰(;^³ÚÁO‰çR"i-ËE”…'Šƒ6M!f`Ó¢…jIUúíQŒ‡¥LŞBvÈˆI·ĞÍã2:!\øÒ^ğ¨íÛ>×mÅå´o™ı3æ—,ùşõ¡ÓŠ€×Ü›h|Ä¸.‘4‰ã¢¡Tı-Îì =Ú8R§zè‘é®˜Šb\DáÓ«
G©‘1Î×WáŞZ)Õ'“yÚ•ğ[^§yy”òğ}¦İK*ù¾MºTåˆm^kŒÍîl<4«¾é€ïì(Ï+Dİ8'e#±—!J5c—§î’°ØïeWzèíğDöƒ«Ó>Ù/ÃÅû¥ÑÿOõ×tèI°Ü">7Úã@êp ¼a4i_ÂFˆ€Îªñ_oÊ½pì¸ƒ>ĞÂİçyP;Š§4(j„a áCæ İ-‹©Ó=©“4ÙÏÁ”³¯I×8!ÒTde˜‚Şƒb#$V“Kâ!‹O¼%#Aw6dŒOÃCO`sŸÂ‘_˜çÍÔ¤£üA6KØv7Lì•æ.‘;1R—BaCƒ÷VÒqVEvRî÷räéæş->
…ÿÈô˜£áĞÿV7æÉbé È¾%íæOUašà¯l„xnv³—G”“”iäƒ*ËOuáQ{7<Œ6T}Æù‡pcdO‰è'2Ñøå˜È59ƒD‹”J*~rFÆ7sOşÑö/ÁúÔ:*Ñ aÚ‰ŸÑU11¥‚ÔOIñ³6Šò6Äêœÿ…¼Ü<ìF·ÎÂµ}ÚM$±ø"
ößp‰l3@ÙÆ¸ˆrìt%YUÄ—¢š Ø§N‹”†³iF0WÖ5’“÷—1¾–…e¿'ÃnÈ ôßÆÊ–ëÙ¶5öû@¤6\Üz2ÿôQe‘Cny¼¯Š<‚p›Â±ã`0‚¥v•ìÙ@îÚ,â9„­6_‡—ş“q×ş	e	ğãÚ¯ì[6Åu6:„ÈŸ¾Yö4óúnz÷Ç÷}ëéğó$e£@%”æuîı"Õ¹ñR´™ëäD•8* ,†°¤~ğ®.³»İª×jórÏ6M¬¹*öºçÉ9.~š•µiÿÂ<SR©À‘oñùk:GÈ¨´o:{
f<“ÅÉ%w‚Okb2-´‰â	Û±0«Ğıà²ÊgQ0O€‹ˆD¤p|1ÿZ>ö$cÄ| ®óĞVá‡î·s|Z=’L;’ÄÉÀâ‚¶9Ÿ™™;È
yt#%›‡eYÚÆÚ‹mZ
F]Òƒ­ÖZËÇÍ¥f2§.pğQìG.SBšÿğYf¹4$^ZtŸ"åÄ_…•2ÒVÍµÈ”à(o$läqx~¯«T™R#a¿Z±f<& wF;ş6ÖŒ\ŸúÍna	7ÕüéY¼?1Šco\Y˜Õ üWæ`\No´ø†˜0^øıÍ‘/v%ti†V]ø!ö\×Õ%-½üÍ´3€ªşD}Õ³†©6™O>µ‡Lí<æ›«K«,Nmƒgèó‚Zk®;³A>ğŸäÁ¬ÎôLö…!›Ú£ A,‰V¸G6IıfÚM8‘ğ“LzK  †'	¥ÿóÚ Ô¦€ğ¿ØË±Ägû    YZ