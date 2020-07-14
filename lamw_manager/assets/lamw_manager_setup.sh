#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4009224776"
MD5="b1412c0e8a4dd23bddb40f8952a231b8"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21300"
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
	echo Date of packaging: Tue Jul 14 17:56:08 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿRô] ¼}•ÀJFœÄÿ.»á_jçÊ7¢-iĞğÊÏ8Ò>óHãoêÕşÔw¿%^kféÑsÂÇØ\í¨šŠæ¸mXK…øUa¿¹›
ø¨J¥‹¶eñ²5eŞÈ¡=ï¿Q²Ru`‚öŒKMãÀXÇu
jëz£{Ês›Í.lÏğ“Ø4&Ú7û¢œêùşÙáˆóö¡™Z_&Ú9Œ¸ˆ›Í
üÉv1«·û?×¦c7úĞ;ÀŠÖÌCºfşàìâ;”ÄÛÇ%!
yØgõ/‰ˆïÄQ›ˆ4ÂŠ½0s)pË°)‰ˆËbÍRk[­Pºí«Ã¿¨k/ì(«ëåÍPñ»ô+X·;À§¹“ÏMu“ä/‚è¨7î*y{¬peûÚæõºf×æ¹“árª#ş*M ú¨ic‚6š’ÛÇ‚ºp?>SS::–r0Ti±6P™ …
ì;ç$&å…êg„¼ü;e(]1½Êõù=üĞïPäg•bÚUâ”õå	 øÁY¸`î‘Î,˜VFiÑI—Îñ(@‘ÑŸõDâœ¯*6gĞzŞæ1cÉ-ÿ¢7,-V_ ­şyt^„TÄ'>*Dq©È>ªABßİ?¢;/ú· ›şs~¹5_ä\ÿÇvØª6h«°
¾ú†¯øîÈk-É‘ ²ß]¹<‘ë‘_™)5Ñ©ÕçX.'@!{ÿKºù4ğÛF*V€x”4ş3Hf¾ñ8A§?65ø˜~*âò'dÛq‘•@®í¼6°™¾gææ}û$GÜ{º‡mÏue.Õ—©sò"V¦‹˜-<ì¥ÌhaP&¤˜.>ïaVS]èøF¨WÓñ^ˆåşÇ¼0ıŞ.~îôìõYOÜ5T‚Íp,z-š»cŸ¶Èù#7?k!xDD#ëS7xıÂBæ9ådh[†‹/ÒáØUQUÒ7Är©şXX²H”-}ÛÀtÔáøÁüúÃÌ¨‡nXHúçÔÍ[³ïÏ.^ä#wÿ’Y‰kÖÔvŸÌİxÉæ@ËzG Û{Ñ'GÎŸ„wÀ¥±ÎèkRšãšbù!e¬G8{ĞÇàígB&ÿËxSCO/*Ò1¢²~öpŠ2ğùŸÔ¾*¼¾ÛŠÕl4ıKü*…9¥‹ ²ƒ?Åi UÚf¯aÊ¬–e&jLm¿C7¯Ì1QWÇH2Ç7Ğ2Í£_)°ß^tÿ…¦ĞWÙëLæ]¼} Z/Ó@Ò?”xÌò~„¥Z¹ŞZ0¥T3KH¨†»Ïñ“§&ñ—ˆ™ÄUîëãI‘Áİ·Ÿ¶¯ÆË3ÜÕ“öuÎï+øQÛi„ÖXÿ›in®cl6†Œ÷`#Xf±Ê”»±ÓwİØ¤™ìZ@'Êoßt5zo>çÊZ¿ş›Ïáh=Á04öGİ®Ìs'5É*­U»BÍÓ¦ÄÜ"UÖ¢±…`ËÚñYABO¶ANoá±D††Yör™é VgÄo8å¨äéÍÏá¨"áoÙÂµhô1QTÒŒ&y¥Š™¯`7‹-»ğ#fúçàMÑn[ˆ\×¡Øjs™+§Yá°ÁŠVƒtÚ=µÁëRÿ4q4-»¥?±ù¸Œø¨,r¯nÆÖĞvYlæÊ(ÁÚ¨é‹·5}‹¢Ñ»o}PâIš/İ«°f\§åÀ¥†Uå>«TÃWâ³îÓŠ´QRoãh 9¦ºğ}O§UEØÔ×¨ µÅ5óÒ¬œÚ¨z€OúëŞ3[ƒª¦°Ãzƒ°f)Æ;—/p}Lx¡€ µ€‚øÂÏy©¤º¨(İR]UGåJÔÒ…ˆ«R™àˆ[”iz±Øl-_š/6õİ.¾³¨ğØ¶·ÓÃŒBU¹É—JTÜëT¿U,Ï¯ë•ßåD•¹½4DØëÇúˆŒdÓØ)è£ÜŠŸèO÷jıQ­7P¶å·‰e6.œCë¾Ù…a¶MÁëÎ?€jÖ>éµW®€#£Ñªö«‚³­iè¤iaéKÊË6ß‘ÚÔ>U5`HaSOåy“7ïtj'ßlÈÎp0ê `MjÓ}‘“©Nÿgé‰Ùl× ú S¿q0ûªÙ°­Zu36®sÏiŠÕGáàœÂ4=8ï²¡r=a“pj&Î¬Ün¯Ù0÷Î
EÙ‡³—×gî©Œ°pø­Ù>h2%âæë9jvASSÕ·û†ˆª"j5T§…®1¿–ElŒÌ¸ÍRìô,=üEZM$@E¾Ç`¹Ü˜h/',ÕeRêË7Ö…XÏ€Äw“€(œ¢ÿ+ŞPİ¾¤b0U–:›mYÌ°t,ù	¿¼Â¤ì§¢Î§M¼Î6Jíj=qïë¹bËüŒ|ÕO¸æ^íç!Ü¸9ˆ0(ié›{&`+á‹İt)¨Ø`c
\61‡ÇŒ¯M«ql›|Lq¯i!jı¬QNã®&zÚäê<\ßSjé¯×gˆöúGO]‚®´ã†YAµ Cs—ùs®FQq9ËCNº€Cğú~	—Ñ‡}Z–»î?»—:IâhÆ]èı“¬Í‰ÿÃ‰üD#`7¿ã#˜EŸ&|±Ûö&ê±ÏöåtSùŒûBYè×ÎÀFëÃ”b£X3m’êTÁ+îvg™HY}'óvŸ´`{eş×–ehÚ?ìòMÀê~=Ò¯VïC/"î”âPÙmªò¯ƒÃw×+qú^löóŒyå¯ÙUë¥IOØ3o¡T´àÔ™D}áÇÃïèA	®Â
U°®™Z3×¦H°ÃÅ)©wmùõõ†MIIL+à¸Ía£ñÂÿ·óyÃ0Íuzpmã²^?5ïV\%¿öÎJ	9í+zjßAµL)ÂL—ê6(Q} İà•ôxZTyâ¼¤6ò!¶—g¤íœìüàÆ‹’ŒRX)‘*	&4ç÷Ëóú]·WÖ§ßb{ÍW×!êG©v¡©`£@mAõS»­{Rê,n²(u|ÚôÖğ0²…„ÆÅ‹áNéÇOM çë›†Òtğ~bDèÊR8‚õR‚¾Şû`Šÿ¯%Ì¾_±£8¤I7mĞ$#xÿì¢Â·ü•Î·&/–é0 ‹¾Úó®H"0R<ºº K…b.-Ö›„˜ÁÅiâlKÀÙì¸ÎÄeruu{”î‰/Ä â™io
^•çbM\ûJ0Ë?:U¿²ö¨Ê\FİŠ*`ªNUÄÄ€J9³İ¹›sr:£MÜô_³µ]¤¡zj£JÈhê28o«ö‰›y¶AVÜ$
È‰©eDH³úıõÚ#Ú"¨­áaÍ'ıH?»ÀĞ€Bz³ÔÓ |8¬L¬nØ†ÔìÀËwÉ"§ğSªÍ‡”èg
Ü@c… =O{$4Öa~4rä‘áiÿ:{øAa€å¤qM£ƒ/Tmè?Œ_7‹#è0²¿äıHCƒÖş[€T–fÿë;9Ô–»ƒÍL		æM™)İJ›‡´,KÇ¼&¡‚;*Ã0»al†^}»UëÑÍ›ëãÖäb“A½ØeYñ bÜ´Hâej‡ßi}Mf+9']4¨óü/ «Ü-IòòºG×·Fu3ÔÆèÁœY˜í‹”X(Âä3ÜˆCq‰¶Ú!k/ìŸ‰ÖÚ‚Ì‰Ò¿-ßw‘[œq3®‚(@AXì¤?ÉÔJ*
ß§EÅ·3êÛÑn¨à£„K%ZĞ'©³p†mE~NM7œ“ÀÖˆj. ê5=Jƒ²'‘ôvb{svùa|x eH×‚ZÜf\ğrL»ÁN¤æ¿äVa’´‡€"èòæfaÔ•J³4UxİÊ¹ï „ešÑ*3Ä‚<m‹Wf²ÿ¬µü×áƒ$FqqÓà{(·l-¼‹‚Å
ì…àô¦!¦LUGAuEÓ;¦§2¤XZ‚–¬ïÙÂÇÚO ˆa.	†E;“!ó×›LHOÉj©NCÍ™çÖ>šƒbÂ¬èÑ¢ÿªšq¸tË /3/ƒ «"¡zI‘²ËZ$üÇJNú*Ì‰ìÙP  Zk-Å/9éygf§,nÃ)kãEÇ:”aºÕ«ĞæåAõÔïi1=wpİ-)N#óäXâæ7-“2¿2]?3_ÆW•º7òv÷‹!}º™BóÃøc	|o>Q@™vcù^~\6|İQÕ2Ò3Ş|Á'c#k¦‹Şö£æÔ†„"9EúkÓÙƒ?U{°ÔfW>XİN ò'P(Ÿu{Á-i¢(*AŒ¨ˆå,%WSuî…k@{Ü9_N-Ø]”Mlz`ÑãX¡àè tVìwÎoí¼²™íÈ¨gß¦ŞHRUCÈ¡oÜ²ë›A4£%¦0%ÜÍ“<ÂÙ¦6HÕNS®ÿš¢	rğ?ğ^q0'··¯•~ó¨\ˆK­?©µüØØÑzWıx.¼¶dˆ±ˆf3¦îLñÈHdC—7“Àå<ÆªzéìjmŠì@Vå lpÑˆ&Á\¢Ù,Ã’k;GÆœ_nb².¢Êƒã#ÄUw[C‰+ÂUé=¯æŠbG¦ˆ8È0·R¤£UÂL°¤‹?\¯ğ¨«oîJnÃãp/1¿HôóG¥î½è[ñ'u	ò¶àzîqJ|—Yß3á^Ú*ìˆÕí6TåõÀ×fÑÿqD
°Œ»{ˆİ¹~Åì½†ŒCy!¼şÍ½ö°ğ‘ÕjËœu—[c˜ÑlQÖO râJw¿ÜÔ­	·°£ ô#é¡úˆn%ä ôÎ¶ü ÓĞßçÃ8tÛ¿÷vñ»9b cµÍ|ËÊÙ0ˆjåd®2d´ºŸ!qÓc×¦ËQ	wØ‡L ¹ÖùD Ë¯0êeAçÙœê*ïÖdqµûähôÜ£‘QÂ®³ÙD’µSı¬ÎsS»j•uaO±_{9;"±LLß(ö½Wñ ;$ÎV\œ&ít4	ZV…j-%ağ$“5 ø“."¢§Í`1ŒB³:5D!½FŸºÎæ³›„_Ä¢ş)ÀSeD³É©ÏøÈ,½ı =„¶£%TöÚ¯æ9†AP‹dz-ØÒ½<¡…ìsİïO{‹šÏDN9ü:!Å¿¶²ê(²øQ|®b_×±Œ./â²I®ïŸÀFÓ³l ‰ø‘ÃZ•âvf˜Ùz À:†-	;áD=y©ñ+z²Òléªy×±°©Í 8µhrv>Œà?*+MôªPŞ 8@F@9=Jª¢ÔA’ÿŞ5è–Qf&«s¤‡µ0	ğ'ÎØ¨~û´svÚ›5¤ÂPŒ²àĞ+âŠĞÂŞñ/¡Ñhªí?0(IkGE¶åş3¹dnvjÆì|¤àk­’ƒDèäÖÓËE>†³Br®Añ~N+#nİDî”íñiêÏÖz:à®ğwt×‹[böhi?Â¤|ª.ñUt‹ñ»–èv€¾<òjäN0>Ò‰~}İlÇ}äO¹3‚µÍÊçıÌ¿‰0`«Ñ˜kÂ[XùşvF–A|<zÜ d*Ss5#ûÕªûùW±ÖÆ‘Ò˜·I¡;×[[ š¥åÚMÒç%M»e¨ò=Ú1·şJuÏ¯»/X{KD‡µkåFj÷ìhYB¯«ÍI5€+¤ç \–
Í×,Eu;ÎıBBTœÔÆ]n}ˆ<ğÍdãZ6L %©•£†ø4¯çôÑ:€êô¦Ùv@+‰¡ê4`¦‰Ò÷›PÊÀ.üşQşçÖ÷şxvt…ö²¨ÿI5R)F¥t»e»ìè ™—ılÃ—˜¢ª©üüpÖE-¶Aãì»o®=O"zf-—Em;ˆ;²ë&j6vƒ„¹GŸ:Ò’Qº7%µºT2›Rİ¯4r¾¤¤\ˆş‘¯Ò«øêCw£ù!\ÜUâ…Dy#‘Oß…ÇŒSw@z.Î¹†&«B²—í Ø*šA¨è9 »m·wc.#.0*{+•	ßåÖØb“Aªœ¤¨³¥>ò-\iü7ñ6 S±Ï?—@ÜëşÇà#
 Q$j\™D,şÀ“ÿ°Ş°…hs•@ò6‡ŸœIJbìr7.}xëK£¥Rùh´6ÉÄü™A‡üƒòäæ_uûÙ½z®,öC'R™¥k-ß"€I ñ¶(ï’¨RğVnîÃIQßZ#ã$/`‡ÔnAfñ¯
”$(SI•&På]ú?=æT‹¼¨¢°?¡7)ÊÒ¼? ª6İÙy.ĞTƒD+?ûåÂrtê—Z&	óéŠÖŠâ–hW¦ª¸MV¸p¢cR	Û†Wô¡ä_`®“@ŞÖÉeo‰rJìäÂ[‹–×ˆ‘Úº=’Ù¯YÌÁ#O'ëh’½û V¼Nf…Õ‹øp©Êk=¿ÿ‹)R)ÌæGŒh
¾È¹m3§#ĞjëCaû°Gu¥]7R?¦Làâ%ûmcY,Áüüµ]åÇtbr¦Ğ"	*<8äşpZAãŸ–ÍêR¦+ŸâEZ' ò”õ´—ÑÏkØìiÎÃˆÏkûè ÷îÄ?®Ô7‰(¯ÑàÓb'E*2<ûĞ•„¦³ìaŸşˆÕªú1‡#(7Z¥QT2$úaÃF¨¡­Æk8i8ÏíRN'OÁ¨Ù²¹Ã
¬(†ÜÄd(ˆõÃ¼g XÑ¬˜…šz­)Óä lÖ0ñZ&ŒX@ƒnXëÓè%tçøÊB4Ü7»(\qöôöPhÎÓf!F„9cÌS7òí‚¹¡ôA¯Î©Á/Ïd@‡¸Û„Îr,Óã¢bJİ)÷ë(	0—Ï¦úÇÜ>Ép”öıc’¬o-Ü×¿ààĞºü89UR¡*øF<8¸>c®ëÏI ¼8«6¤ m"`ß6Â•t¢ ÒU¬mÛ@…5 )ÊÀwNÓÍÎ)bïLi—Î“K*—YTÉBíÆv§ŞÌ´ìÚ,'G5œ ÎÁ"89ÔİCH›ÏHwi¹eƒÿL97äAD%6v¢×ïñşÇ{ã–­¡Êèonö¸Â•zlÍ«SÊúæ¥j?i€-9ÙsÉ‹ şYÏ­<u\|Wá	«L.ouúÎL×èò	:CèkQ*ó^g—i3c.‡ºÛ…’°•&½”"ˆ›Ë>Ø÷#²	€“–dEƒ”õE`Ãé"|…\c|
ùV"«Œ[ä9Øíæıv,¶<¡»Ï@¨šYeëA
rÒçØ—C~4ŒOÙ/üìÉc9’@ù‚OZ]ÙÙm\¢è_%À·2°@ÏJpˆOËwŞ»%óY5¹ÏûpêôÆyoş†`¯q¡Lôı~,ÄD|˜KäÏZûÉÆLÚ­ªÁzã/È.,k®ƒ¯i±û¹åtçÃ$ğÔO¼<BÄø©.‡Ï­ˆV	¢¢Ì\W;ë-šÙÖtõ5éVÎÈü¹û¼ı§¸D\wÆ…=ÈöÏ~n†ËÚ
FåxÑg6esc!Ú\…«s4n0Æş?‚›ÔĞ]› ÚZJ7úÅÜWåÄ*c@(Ú•¡·aÔ¸ˆ]%‘ø ˆº€äTèNépZñİÕ
,ı’Æñi“âüÂÏÄ¥L(šF†ÁZB¤ıL·’]ˆ˜YT™PÑû„³7·È
QŞù5à¯T]eñİç­š/1‘¶
ø˜X1~—íC3µs3º!±äîµÁ'ih>Ó@ø4³cÂùåDğØi¬uIş6Í8B¸à³×ÂWàRÖAèÄˆãñö='¨×z™q²|Ök ®5WX„X oõ|ÿãH…¢AÚe¦i»¯#¨#“OøäÓºß†¬‘*ÕiOBRÚŞŸÃ £Î©ôˆã'’,kÈ¡N¯‘I–•®Bu¿,ä ğ
 IqòßOx‡²ı"¦ÅÔ¬ÊFÇäV•Õ—„À.U:0KaşüX{ }'¦y[CñfL@.v{ÑŠ	XF‘\í`v-QlCQÃdÅ¶X+”`@£zcCŠé+2áP9/õv ı¨-ªYd÷ÿ–.ncÃƒ’å‹ô”q‰âsÔlÓ¡’ÄP˜Áù~—ÎoL`D/Wó–Ó3­º~I°€½b¦à^P`¯nÄŒÚL)
"=Í²ä´Æi'.qélshoÜO,&Ñ—ÔÇÊL‘õ¹¢•wZNü±dªî¦NàÙÃL ĞĞ_D¯-¤Ââ‚ßUJi
Êòå—ô—`a˜÷²b>DxH\ÛB‡:¤:Vdoe:ˆî5.	ñı¬ô}ùy†' °_¼€x+½©ßmYØ-¢Ô¤|6©b‹ïºçÚdV/çÎHI,—¢_kİÈbÓèÑjé•œZt!õÈÄ}ÚÓès¥ıËÚÚ‡½ı°ZÅ m•6 ÃeÙ<&)£}39¹edŒšŞ%,<µÔ-Íí±¹!ş/;h·–”Èóœ%	éûbÑÆB<@ m®Á»e•Ùd‰b^MOÜA¦ølÉ\I9§}Ö;7—Çæ,yR_±ö´7*¼R¤¿ÀfÏ«¤ëä:z8Smğ ÔæOŸ"v«Ìix†”ó›¾g–ùö@·ñxA5
P>m®ç‘Ké+Á]Ã7ıñ#ÎNÒ}IõfÕvÔsLâTHÕ?ÏdÖ¶Ä5.©V\×v>ƒ%?Dï¥I™¦“uf†òTĞx$f“¹\@Çç¡OÎñ›Õ5ûÅºö:$ãóæ¦&\kÇò4©Ÿ(nwLÈÄ•Dš7€}'€¼;Í2jWsÛºdUr¯²FbràI<iWk½÷òÓR^ÒìÈùº?-Ü|SD@¬.ñV6‚]¾‰8AË	ãŠÁ`§>U÷ëê”F‚&˜¶I!×Õ}ìMVé&{ÃŠ¶'1"1á£Í	[à·÷¯5Í©u¢¼ÆÒ;+GÆ¬ä-şAnvìøJ2‡4bÍ¦‘ÇâÈHˆÙüCVsÅ'üAqe&Z#5°VÂİì¥]vÌv>ób”¹4$}VX;i,½ñ­ó½Ráa60÷ÉvKİöAEã­mÁQc7ğE~ËOT7ù$Z]—(S[YU×Ì ãÅ…]6ÒÔ®M÷#¾4õcØıP ¨Œ€~Ó)"ÍUiÊ§;E¹äsğ$@R°n ¾™õÚ6‚%’û;Äôxlågo#²NşÁ‡•Ïİñ»DÊ ßhı¯ş8áobÃ›l“°âxëàUØ7ÇtğĞ§ÚÜßÀêOp7*ªÍŒ4)“ì‡ÏÏ\0.gÜ³
…Æé–+O{dnE™üÕúÌğ´",ŠöñTcG"v¸".Äu¥ÊPÎH¦©ùD•£ÿ9Ë/ôŸV+9V×vjû‘Á°RYö“›–Ä†UìpÖpEV=Á¦Ü¥Òit)sUå£Ûaˆ¤©îÜ[C >x¶éf~y„/lI‚9²Ğ¡_WĞq2¬áƒÔT"T¯pˆßYÍ¤ĞvÀìÀÀg"¾Ü t…†OØîé%“ï€ª½Ë2çØ¹‚@z¥+Kë¤ê½K¼ëp‹%=¢šœ¢¡×nÑnÆÔG‰ÀÑùIÛBeÉ7ÁÖÛCü#,–ˆâ~ïÃôòC€Ô–Ÿ.§çôuÇş¿+ ‰~Ïªd…_æ3ĞIpæi?İbH\´ÕqüÉX>ñfÒ&®n¯À.<ys*×X[v,*F)LÀÏmğš}çÔÖ&•[­**×÷€Áv¡G†:[áì%*‚ü£m†ãÂdcëAjÖc ë-^fòŒ6¤*b‚0¡¾ëâ‹h;¸ãæZÜ¨Ü­c`mş%¤Şå{wFìxî ÄX	-Zƒ	ÿjßd`\a€0å.=›MƒÆEÂPí„ãó#tAFƒp2—BEïäİ‰I8®`6¾Rº„É+­ìd4oø«‰²£Ši§@7ÒKÁ$ïz-)ôg-}Î§¢‹à º­
ÀpˆªgV6mø—?İŠûDüh"xá´)4†Õtšä$'¬—›©Ğ¡¦=Ú|¥g]ÖªŞKmŞr“z£Iï_ÿÙàÑ«NM™Áë[Rs@(%Ş9­Ñ59~GuHìæ~E]ƒ¥É©s0rA“c€ù[€˜o°ÉUJòÈqWèûTÅ5W¬å.Hy?aA§ÂÚg¾6èA!Û*«®ÑTïá%¨9‚yŒàÖ¶l9×o-Ù¶Ş¼~Ğ!¥iD)º¸ìº²ÑmÌûåƒxlÑZgë+€*thüL%
¢ò˜_`ã%FëÓÎĞÆœØñz?×Èp#9Ó9ÆJu{ƒú³Î2°ÿ—p¨ÈjMY”™Úbÿ²!o™Œ
Íµ»¼¤¹‡[+Û<Œ‹z†%£ìüOjÁµ‹®¬À¦õ	ìéS'=	t$ÎØ·ƒ?rXãúÿvpÈazFù9’¥÷í±Ş—ÈI»¬Û
ƒ-*ß®º
˜í0-óiº±³sõäÀ/>Ç×t6nƒëç™övD¯ëê`E½¤7äêŞ¬ºzÕ?| 0~·h-,âD4?#Œ„;‰|ëFıW‘•“Wàcf'1½ö]†ü÷ôİß¹iH®,è8+¶›.#\¼Ì ¨šU²›qƒ¸±8£{ù0a¿’"aRÚsU'î°hJó¾£BÛÖ‹­7´ùUÊÕŠ¼,‡i/øŒ‰§‚*~=¤ß\xñCÒ]í£Le¨kĞFÂå«ÄÓT ”J}İ°/>ù?ı‘ñÜJM sŸbl‡&é>Şe‘'&®hÖº»qİ²Æ™¥%9QË¥•D®‹¿ù«ÏÌ±ybÃuçe·ØN©é›–# Ä÷
™@ÃT9-caÁÕc_¯nèì²®“8êğg»8!Ê a§Aá6±MHQz‹–p¶ßû^~ì¨yÇs´­yÈ–¼s¹=fxz½?‚„%û„¾‡´»³ÔÙ¥h×o,™à*KË°&óƒ§T0ùÌöˆÜkã°—æX:½¿zÛd†ş¿QÁH_€ÔªÄ6†G˜X–OØCÛ5;Q/5ı÷ÁhFÑ…rVí•G…9l5Lyğ…7/X²g¥_ÔÀ4— Ò=lz¿Z¿VPşAêø„²S²ÕÀK…?ıøl_l'Ø2=|ƒ™C“Vtí•Pk7pÖ‰ñgšƒ"³ëÏ«,ƒÿÇCoÀU }õ]şIPgIæ(Êú%<ş4ÂÀª¡Pâ¾¾ Š#¢NùR^÷â‹½z#^²QrÑ4ÕiãMª ë¥ÅhFê¾F <jØ¤¿}°¢
Ú×µPMÁ+$’>:o^µåh½Å;Ü7Ô[=?øËÇmö%“¸T†êŸìˆ!–}ÿrZ‡ Z¥k›e®*ÁTıœDeVƒš¿`zÎ›ÍÊo¢CÕ·<÷=œ}¥¤Åë­ïõñI»PÈ"Å¨@ÄIŸpœ¿1ŸZ ùjß¾`÷‹á{3s¡è‚ş‰©=¯8 ÒwÂv~ Øi¬µ¡Z|gÁ]¯¿iÂN‹[yJ#øÕIıÏ¬çò¯×­ÚoF7<:#éQOï˜uËÑå#£‹sÓZq¥f°Ûmú’ÀĞ‚—ğASıjß ‚vğØ³êËšFÔÏ78;H'¡]¡Pbq¶¾…œ*°ø÷³c$MôSï,b]—ÄáÒhWtçÆ!@Ò´”­³ï¾$,²æ2Ï‹™.·æTÀã‰Ùñ­C8+ˆzO I°-°Ğ—T¹HÒÍøûgõØ5š,ÇÁÜùDªIQìÃ¬“Ï“­»ß9s¹Ä•¨oÚN³	ÚğßXşO¬\KQcÜ“~CéaÏ•Üz	QóL5ş«ŒFvËWÚî³{ôÃ®§£díšDõı—Ï»åˆ’	Â\ëÿ·ĞĞ^n{<¹´“»Éa¾\Ò§ µIyA¬‡n‰½&Şı“}2_şwÉ¹Ë€zØ[ì~8àŒS"3)—iü˜¥»Ïa :ı%©@$ğ´Ù¬@î‰èµÒ³şæcÕî_Ùô?{Óo–İß†0ncáËœL¸@ş–İÃFÄİ3!6¢R&ÊÄCÑ­2z‡o
”šy¤•~?ıBÒh’U4“ŒIt ;eIË"ºkBeäÊRÛÖĞ%2óÊ"˜pˆ•ıhU‘—Òå³˜5‡„çÍ·~Ç¼ª‘R[›ÇÒ±£qà/İ@î…vs¾{Vz G ˜¥åÂœyŒœ?—÷9c×-2^·ŸmOzN™?î¼ÅgƒŠ’áP‹£³œÆº¯‘ÀXìjÈûÚÂ­¼ŠbI9ë'9…ÄË¾÷UJU>kÿd;ròØÄÈ«÷şÂ‰K_/ÎÔ&Ú&ÚÒD€V4Eåñ¢:ø«;šóq¢-O_ #oÅ7ÓÓÚƒmQFÉ°aºuÊKx¿6Í?&…¡¾ø”“}VÅ_w¥¿Uz™}·ÔxQ=~ˆè°]÷h ÅK!´—y#œ¥U^¦®òØB ù 
„á¾Tş…ƒLçÄ*wÄÀPK ¢ZF·N]Ìü"°,(âhÉ=¥¢_H)é×lw‹%óô™vƒÄàV1ˆãKs˜LT+ĞówÄˆÂ5ûKCìfà ˜å¶ 2ààJ íTnË?ùlÙiIãÚJÖ‡—Ki à;Q¿ïºvŠ~Y`_†ŞÕmÂ¸ëÈÕ6…încæ=ÅÛ}Ë¨#˜±Ëº_* ~ĞĞÓpz¨0¼o³ò	 !]çka¡{âŸ-1¾ÆÈ¤3P¥’?rEq`ÂáØú B†dX#ô‹Ã8ƒÌ+0èmpQÔß™Â^S‘QÆHÓæÍ¦G½ÍrV§&Ç¹ÑÆ7ñÆvófáj?’ÃG‚;øò³á˜ó#…	ıQŞh@ ¹wD—¬o/§F§Eé9eÉİ5ü#®2ûÿ‡ß‡P2Á³²©~8»8Ğ¾…/Õ±m#/Â-?ÁkCìÀl°96i8e“’–n\‰GüYÛ(Ëœ/Œ…Õy]v|Fü˜O™aê?'âcËû¾çfæåYïA>S@^'·'½Êê 'à1£„®<]oz±Ùs•S,³’"™BÖ›î¢îP0Mg•¿@9vã-v¿Ê_«‰1ÚzSkEê
Á!´Ê¹0Í2O‚•>‘àÕ„İØ¨ñO²Kà#Ÿ0ª­7 ¾1	‰ÿÇ[šöä ğ›¡š"ûEºu{=´ÒC¬Á£Bt’J¡x>BRršé~Í:„)¿ ªò÷:GoæönQ|:ÎÓŞk i<ŸØ3)„aÃ·¤`ÚCŠÖ´qL 6(2¶ì13ÌQØòFÚØ"—_$Ã·“é(5j
¾´ñ±M€€²»Cz30ïzœâ 2%Eÿ«ïp)†ò‡Ò±mÑ€[k°E°´6üí†î¹p9ä³5îš2î¶:ßîîä¡„s­Æ’ÕÎpSúÿa÷ıöA¯é.éOœOğ6Kj{CEF†x@£›Şµ`AÍ«Ì»t^*üu	­(#>YáM?]}LyÈıêÕc€ŸãøçL“»ª…×TMDÈˆ)õÒ%ÓYê¯Å¿ûä¯â›ôI@{|„vÖ½Ã†~eQì*buÇiâ«G”Àát#¦V.ÍT)â{mu% Û°™äšif’„Üôz´n5NÇ¶ûT%Êì¡.ëø<åæ“3»”j“Æ ÀKÈ	jî¿X4ÆbR²ãbqÀjQÿÒJ&7ß»)VÁæS\‘Ä‚'MiI^Ş»e-öÚb·bq_p¸êDº{0ñ’Û‹ÂÎ¢©Çag¸ù\‡€8“)$WçKkG³jyr‡ÊGTáHŸAõH^d¾¾²ÙÈ¡[<ÆF)É^±4åªš/ozå¡S÷Š™mê.#;	İT
¬q÷ÑÃa	ôş$jü”µáä’TLŞf½–O½Q{ÕÖ¦öwÆ´’*àL´}!ŠìY3ç9–±¡zKÀ¯yó\ùø¸ ËÇË,_¤Qª…–­(1a„DøÉ¥ş“ñØê%·F@ü‚˜±_Sa°ëB”ó]ş`.Ô4x »àò\6˜zêX¯LÏ®úb†À‰(ßJ¢˜¨ëØ=îInË°áñ»I¬c;FWSÊå #ãX{+5şhàï
ÁMÜgbÕüçU<¢9=Æ!Gx©°7wH_aò?çL:¬È/«§~ğæT	©ĞĞ5kbA/^Öùo™º¤ t .ç„-Ì;éo¤+u°–ß)š0_|AF2Á<F„‡=+LJU Tê¸dâî;‹áRÏ^¿®x;´;Üôª¦ö²‚=Ôræ…Òa^ƒúƒ9•‹©©’å|æ8òYmÉ¦ñ¹ëÅw­Ãê¬İV)¬M{	fâXZÒ›0æ-'š"8 Aíò´Û¹R@bï…öy~lã4¿¦‚l¥/Ù‘½6ygì6"Ew¸Ãmx"â´ù:*ïõ—ÖIp`ôîÜh¦
^ôD³Éim7ø&?1„]¤
=¢EÖ©¬
êû¤Ø<ÉÑÄ%‚ÿ¡£ØG|ÙHPßòÈ¼–'ŠŞé«Õ¯ÈÄd™~ÔË¹îà­“òBJ£çoâª¹¯Çÿ^è¡Ô4qUŠÀ†¤8ŸFøuBcÛVk÷°®‚kÇb>ÜäŠ~‹U¸D*l€ÿ&J?‹“Ç'·•®cÑ„¶ ;´3¥`}ı¬ŞšçZĞÎª-bÖèLJ
5^`±œ˜c*ÁSñ} [ì¹Ç3*
§\ıO‘NNÒ›HÏ˜\j^!JŸ?T.€€âYõloQ3<#÷’zXhHÕ§†vâN<ÿ¡xÔ7gÍ'•1î´ş>ïâ{õ9¶Ä¼ñ àP/pĞmUW=®ªVeTs,Æfv¤^´k½™mª\‚è•ı„ñ¡¸Œ| V÷Y%Úéêy‘rnr8è×ãÔLø Á5Úíh°Ç6ÎFIÑéã1)áD=MÃz#ÙÑ€n3Q±ÊCşT<QÖj#Å“B` ´&M¡LÍ	??pîó~Ÿ˜tŒ†<£|½fŠ—©ß/#j>)^ËÙp‚º0á‘+™&¤½¶ö"œç*`ú)N¦¸Á3Mö×]Y?%`#³•=´–ÅÆ‚ÊÅL'4cË¨²9B^íTö%íì27ğjùFÄÓØg±:í“©ÄíFQeşE²F¹_˜ã§áÆBğhò•U™7›íä,ôEà¤Msº…;‘"¥­uâ¦L”ë
vÁ:/6?©©ØjLjT	ÙèÒˆ!=N‰hur8åÍ×–Hf°p¯$È ªRÙÈsÕ¡Õ&ßu¢=5®÷E®2ZXô|}#½ù©fó oé¨Qb‰Ô0«6)2¶bøRÿıÌ°³£@šC4ûò‰€Ï¯‹ƒ2=&v«È×‰VnHé„à´híò<çáÍË¦B	ÊÁä³Ú±/8‡¨‹ñ‘¬Èï¦Û¬*¥Æ7Ñ²£¢À
¿yçgmÁ ëÇS?ÕD ,ò¹¼Dj/;!­GkEÎå,²mdôXGIxajé—Úu7ş––¹	½f(üÖMbzAÜwï¥‹QÈ†øqODˆë^h
\„“zwĞüÍ<àê é•sˆc˜àkÍùh.…Ríá`iVöÖ?”eDƒ“ÜUé:ù3«ú&—*Ç:ÚÙ¬"7”‰è7}†N~wE]MüÅÁ¯.SPG@ŸıP›çí7n±šÄas¶!)¯Vshè qÇ0âujª>—É8}•A!pºw+EK¾gzö±+5ğÚE•ì-³&L¥O+J‹ï ‡nû-ı
4À¢jÛüQ+x=uûEï©LâÅ°@÷|Q¶/–úe@i7·4­g:ÿ€0¤á÷°÷í/"Üñõ%Éá– ;’µ†²èñß£ÒNíJm Ô¼h¢,›IxpPQÌs1ˆwœ]B'™mNfXº6e–ä ÅÂÑHé[VÏV+ĞkXuY£ØzP‚ßAô€^4èÂíî Nïp,ámçTÒ³$¥ì({‰AYyè{/RU 6Q
‚½ÿã“A|ãá	è@:/#swotiŒ\Ú‘HvØ®fDYá?9"î%?Dæ»éúì6·,'MËiÄ\µÓÕ;İaå,¾3
×IeÈ|'	jë'ºæ/]	Œ-{)E„u„ƒXb«!Îh„Øùò[°‹ş”ı¡6ÅXÊójŸâ<ÊŞê¯ğÆ¨À!Z¡ã>ˆxG&¡jÊ‚Ï‹_î^œ‘‡Àûù–ñ-¶‚FG+Œrj”–”Ÿß/Š×‡ßeÃ†Ì´
	}½Šİ¼w	·û¨¼8âùf=ú€:ô\W¯>TûÓ6§•\w„
M¶ÅlU˜‚¿»Í°÷™ä‚sßœf°Bç`ï”C‡Gˆj×LŒ¯Mï?ö¯S{æ4cš¢h‡Ãv«ÁÕ€›.áüÑ2Z (}x7)-3!YS?Aëåìøz>Øïò½NÚ©ƒˆÚ0·âd ^mÎKtœ_7Róı`8±µ!…İ-³Wn=~a\|4ñã9	¯` æÆ™şş¶ £¤~
dç¾}{Ò3õ‹à{¼p­è¡FM…C}×Ş™`|4fŒ-’õ*t'Øİ²ŠÑšWæ
ùg$ãóª$…QSVHWY@Ÿ¹[!€*xÇAs²{‘U/h¾LÁéäd
¡KjÑOø †@Àúƒ]\g@.tâñÌjïr¦Ğ%á<+†õ¼àKP?ÓjÚ™ã>ˆ[m-ºòJöûÏ]óN™z/ÔŞšªtwwûÍî€·‹²Â€1ÕÂe!iû*¤T.¿Œ­*¶úKP‰¿ç°Î…2V«ì&Ó­Ëü*Dƒ(ÏfM)
PÀtª§ÊqE,ËÉçƒ	¢”}Êvàø#E“8n£A.¿õ= ¢©OÊÜÑ£ÎÆ‘p:ú­!|'¨µ,œ(\ÁFT7@-ºá5Ğ—Ÿ_s…TxKò˜Q~ï‰şŞé	'”¨ÍU uÉ–.«­]HÊáf-N ÿÍ›ÌÏŒŠ»‰s)\UVE
0Ú¿*ú¦úæÚà¨-ò÷ïi«U¥‘›"ı·Œà24mÉÜeú#Ï¨ûÜRvAg:+[ù~Í^³f~AÚû>çT¿ÏÛßİééÕ,P©™íÀ{Š¼É##+ÕÍÆ‘ºÂújÇ–3	{ƒ¼Ï!oìˆ³,X¾nò€vŸá$êké¼¼ÌEe”“IÍóT,l /$óÆÊ§ ğî	1Ø ‡Ñª ¤#Igï•w2Ê3Rø‹Ô{ÿó(~cg¥¶¥zé0Š¢şÙÆQ¹–<‚Y?nÅÑŞqŒº|2 èHXÀ\1û¹×…˜çI¡êe »ê? µŒ,ì÷|%˜K¦ÈÓ¶°¼%²ü¥¹6yğªÕGéßŸÃeIÛªCgEà·lØ¡;ºnØÛ1Ò'¼ñˆ?ˆrˆtÜOëAÿ:š›oãé»©ù¿YC¬NÁîKÓ&[WlÌÍá~çú.ÓdùÒ¼dŠÓ+~Ğ¤¥Uù^ãÛ­ñ¨Ú€YZ+ØË¯÷ÏÕ9m¬’VÉëuØç¢ùNS¡©	—¾°”Ì}d\‰^Ë’ïñâ–õ~:šç"oX¥,y’~¯øò´Ó°Ë¸Ÿ¬0s ¦3j4ÌÔ´Üzñ¶õcIÿÉìğ¢İr4ïeğÌ‡»ñ§'ÙÃ 8Sã,Úm3%¦‰c<ª‹¢9xõ¹Gˆ~àNXŞ·c›½™ÎŞb4ÊÄİ'’(ì7[<xzÚA¹fÒ#\àÉ[jÍmæ8môõWß/‘ô†¶eª¾t¯Gµ-Ó¼ÎP…)Û±õÛ†báW[ßaS_U¦–ÍN{½©“=°÷ ®pA®oK¬çìÅ=V^ ¯bÜ7£û•ÄmR )ZTjréïQá™tX÷ÅÏ°ißVnéÙmÙ¢\Ákk˜îŸ½“º##Ññ~L:Ğê‰!ª£¢ÈñZgÿgîQğ•dµ%š%„âê`ûGú9@øFrL¹…TĞl¦Ùµ+zZÒ<¬&Ïq4€îi©Ì¾Bfö[FŠMqpÖÇ”„wÜ¿ÍS<—&ÉÏ_âæSQ‡ñ¯kô{/ñ†ßşÁ†Ğ3(A˜–)jØN•IÌXÃ¢y‹Ïrø›nÿ)À
†™êşdl8WãLóÃ`’óK=Ú¨›i0+È  :ú°A¾„—–Í)¾cSO<~'Çz{Ş!{5‰1=`4¤w *p0™‹_>øpG¢Ü×Zôç*òY6l7Ê‘˜ÛôNù„^–I£˜0H±à}âíğ;jR3Ç‡­¤÷‹Ú[šy €¼ÈQô@á¸²œOæBè¦ P»ƒNhÆPùBÜa ²oµ¶„@•˜•Z?åa¯fKbÃI'ş!£=58ìİRŒí¯èW‰ˆèÌê~·<¼Ğr(Ø¶{€xµÍ†²Cõc†e`©²™<FP¦»á}rjø|&€›)5Gjğ‚OÚ–Ş=°…Å’ùhK¿­á-ô[p—É’wßø KÊÁ!Ä½½$ºŒ%¡C·'N_‚Æ:±¸qkdO/gI‚ÚéœNCKr<©À=ü8ª¢+.Zå¶ØšÚv<H¬ÂUp§1Årà£g´iE
™?¸"ls¿òå’ã¢g *‹ 
;wEvàÙûº ÑceĞ¨~ÕGc—].|U•g–Ã)àwø^’@r®?ÿ²ff#W‡9“0²“ªŒ2^‡ƒäüw¶¾ê$b¾ô}'Gx¹fÚ’@æ­ùZÁHÒ;ŒG–µoLcO‚Uw§OdI+eï3D5¹Scï¶!íìİú…-JŠ¼ŸÔp#E•ıNá@g(kˆ² ç¾½Ş‚úŞû÷'è­û!Ğ¹ÆÁ^ÁßZ’Ât¢ÇLdCl®hôş3†´|¦í§S!¯f‘`ŸĞ›’‰ò}Oos6dÃ*á’ôÙç‘–®ùü}ôh|‚©P/LT&-ğÉs†é^n`Ç…²|	•²#~ÓÁyV±¾æ¤M&c‰B»ÊÚ`¨÷E~-G6
Š ï9ËyE ÷aK“‘j\2£?²w0”…ííŸëï\Õ”Y;Æá!åö0ÁBz¬)ªA<@höÄıï.iÉÍ4!z¹^3M/6.;Ã¿åN®ÕÚwÎ(Qcö3È*ÒN	†?%ûyôÙŸ™0N®¢)JOJ¾öÚ7cã ?[drT}1m5ş AíÂnœŸ[!÷‘ûMBÔZ{£k‡êŠ;
L¡ dC´ápa
RÛ{Û¬À¤gn¼ÿ¬êøZ7[[!ŞÑëõı«÷ŸŠÉÁÁJ­'Á0ú3J|ĞéªJâğÒ~ÔşúÅL¬>‡L	ıNR®*i&îÑø;M±?ï·prFGv;„µ£ª é4mœjğ`å_b}›üÏdúí5é'o›•åF¸àÎ.DîS(<Z`ªooÑ¥×ÇrOs(—£>WŒ
æ™@=d§ö…üÖî‰X%_;˜„‹.‘±Ö^ŒR®l*é±{·æÜ¹ıÀ‡Å™Z¸,÷PÊI>¦r×‰Zãÿì}- ç€V7GÌ¥–ÚêÕYDØl¸zùŠ¬=w.”ç°0_!`•h0S²¶&ºşUy[4oë F÷ùåw™µnÉÉxíÿÆ`Œ¿\£Øt44FÔ/¬2ÇÅ™­ù»Ü’;ğşk(.)ñÁ{äMôJL;eÁŒº"Ø)	 UÌ5¶qqñ‰‘ÿœ?åÅ0ß©#Æsî÷i6»Ó2ùJşô…­hy@ÁJ|¼$iJü‚˜¶ñv$U÷<Ÿ±ĞÌJ bPævß~N”J×YÅ”­‹}ôíi†ìĞİ8$ïUc–]yiİÈ6$OwD_nÎï3}rÆ°¨Zç`©,LÆÀş˜Q®	{õñê#r`§U>9>ØÙ@%uÍ¸ÂÒéÇl®l›F¶k“z÷&ÃMk‘Ày(ä‰Ä–Ìûwd™§„Äº†æWÛäX›NI\¤¿øğ‹JÉs.D|Ao¼:vPQÉÚ5É%ÔççjŞÈø‹(é7|ßiÆ><èz¶;¢ :fÔ5§]ÆfºŞWÿ7Ò?hUµ	zœÔJ²¯r«iÃ{áú¿¼=Øh‹“e€Ğq4U-†l/>!X ‡İã†,¡ŠU£¼yw+‹ŠU1uÚş]¬ëTù&Aƒá§l= “Ã;İsæ_ÉV9I®SwÚ€”ğšgÏ-éY%ÓE¥â¶£)É6ƒB9	«÷miŞ @1ÃiSø ïPP¯I´â^wŞ^.nñû¾µh(‹)+n«º@>JŒˆsŸ,t¨SgÖàÀPhXÌP„È‘,†ı2¨™"´·,Ğ]ÛŠèÅ³İß]n2/®wXv)°—ä NÉ5ŸƒĞbï_„À–}Ù0Îâ
`Ÿ¯ !…"¹©·İ÷³};ÀBÜÕş'UÇ¤dRvİ×ÁX÷ˆÍ™¿€oÇ(€}îdä;JŞc™Ş®(	8İ–(r=/mz=èhÂ“Â¬‹ÍR“#‚º¿är³A@°FtËï´ù–·jHİ’Ì§{
v¢‡¤GPÜ:[]™Jû£Ì”m!
ÛÙä?ù8¹útoŒ³¬TÒÀÚĞ ş[uÚø}ÌŞ[1&G._ ZºU÷"¹]u6T©‚áÅĞŞ»ŞµÇ{œŠ¾Ô4u»Üä0jWû#RüD/‡*Şù‚-N˜JÈÀ%ß‹tÅ¶ğÖo-çD(ÿgJ4ŒG"~ÙÀìL¶ÜgÈ_v/Å–2ªdc/Âì ´y¾'÷MI±•â–s×<q¼ÙÙ¾áñ}ÇAÜSèJİ´´ó¾ºFp·n*ƒ"¡%o:$c'ÉR©#ª-'Ñ–Î/ÎRÙ-ûPù\Uj@Fÿ Û0ö1 „uQ(Ù§×gÄ¬Hl1ØPƒ¶f#ˆ>ÜP‰'ŒÁÀµŞÏ`-5é–&¦{h<hœ{«ãWÜî§-1É¡•pRÄntãKdO¦^!Ä*Có,¹x¾Ş<Ø?ÑL@öªz%èÖ—…<p™v_0œc9L‘îÏíBÌ¶ªp®y¶ŞÈt	şƒc•o¡a9©€bNdmèä¡¨ş¬Ãú“Ad#xL×\oæè.åûĞç"àû½¾İêªNW²àçİÁH‘èÆá•-½W
ûåúc·–M[5Æ¡QV×lÆ›%c§3DÓO[é¿³:ŸğPPJ(áwùy–†¢8'ÿš	l!¨‹w02§–G‚“Ç²nzu¤ÃÕŸGiçe9NÆa¤qÒ³	¤…qNàrŞ9,Ê¼èdi$`()|`ÒQšùÎ¯û÷ípw)©nQ|Åf<áñGv½(Ï;«´é@46j"bæKqÊb®Zn¬¼Ê½ŒÏ )æÚq\Ëí‰·à’Â»¼ci› 2/Mk–£¸ÅWÅg*ãWIª_”-—²¾¥¼uàB]tÌxû[bEŸ,ÜWš=˜¾HêXS©RT*”cjwã.×N@%L¸F,ÎïÚBıÊ¶lĞøÄ™³K—ShNLPY]œªT<¡©ãè"û[[¥D%^ğO‘LiªôEìÅñé =	CÙ[“2‡ã_}2Ge¨ü=ßzu!ëu³ÿwœf·'EZo<°n£fW>?ğağß¿?ÚÙ°¹6¢àWpgûŸ{ˆëc„éh—7ÿÖYè}üs[8L½¹)Öo°§jXpNšFåù]¬¹@´ù70©ãæÍb]÷x{ZÖH¢û!ØÒ¦M|bİòO]qÀÿ0÷CyŠ•}4ÅçÑÊˆÁØòoqkõ†Ëé_şK—8u¯ ã·;<lyÌ“‡ôr¥s±F?^<&:qù­€ãRkÕYyè½,Ğç#éÙ€e2BLöİ—Z·4Ib–”ÙÙm	7SeH™İû©m^V	¡FX™<z¹ZØ"¡QŸ½üÔlÎÛ°"l‚Œt(œewŞlõ]¬Që7(%cŠJº]ÙÍñ”øÌnÂsïŒ}g_¸>ËĞæ<ÀŒÚòNÖ¸F–‰¤~I÷¦­æ,
Ş×úøå)lšDx³•à»m¨;]sô–8Ùo§Tz:<2Ÿğé2‚wrï[÷äÊ ‘b^ìeMyÏºc±(Ò¢á^MòÍşBÉDÃUÅ…qlJxY”Ù:1ÅƒÂAcÆT8A|®vN°n2÷ö?÷­PàfŞ»Gh·¢\DuQXÂI+Y=§Ip{-¡ó³ÿŞÍğOŒ	o“şÏ‘˜|Â¥ïQÙù*şNÀU£‚ìşcĞTó>¬?¦»VFáéÃç½jåiåˆê«àùå›Š>Ÿõwı*2ô®ıt+Ê‚±ÉßÒÂ$?²ÄÓè~¥Á œÈ(¿EZòbığ”S~°^(+fæ“e%O<Ã~VÊ½-	¥$ì|Eú‹dá“‹öâøšš™ÍE+«úÆl—éãúAç‹Å±+¨¬¬”ŸKÒÒ4!=í2Õº
¸~ø(#õLîõ­®§8àTğêS•übÃ	;É¡±¤bS«dYq:„£4Ìş±JÏ‹€#²¨½ÀŒ¶J¼öwÛ„§¦N‰ßj§clv§ì¯Ä¶òí•§ÜˆRh}ì´°ĞÚ'¥
CÖŞC9×¯Ší¾Pv^Ó;Éıñ½°Dò~e˜×ÄıÓ`˜îÈ9è ‰~¥N\“) ïŸáÂõ Cm>>Öb·) éËÍƒMQåŸéÌWp¸º˜áÕ„¼g½4
Ø³”áÒ¨®ØB±æ´= î‘÷13Q¦Læ·R'yÃŸk³e¸¹À‚ÀÎÂƒ ÚF9²_«ÈÍ0“íîˆg86§h,®—ŸÉ&xæfçÆ¬éhjÉ÷A8lR:kâzùÛ^·˜NE;?m­u$U4Ì2ŠºãxfîËxÙ©¤»µÍâ„#pï‹c%2|8Ğ‡-Pš+~ù¿ş—_V ÆnÓ¾MãŒiß‰ol*ëªaqa†áˆA~®cfµŒjÒ" İ8…¼l½óÊE’â¿K†L&•&]C¯ÓQ—[0*²ÜßşÄcôş÷.x÷X"¦Ò†Úzª´+rQİ$%À,sAğ!àH,êBTÕöôJ‰’ô]ílK"ÁO“%‹´Ûƒh9¹à•Ğt¶Of`ªû‡uë¥ˆÀòküØ‚‚X7€<ğ^
ªùDeyÔqß‘ó­0PBÙ“¬ùüĞ]{çP–Rcu†BlÎ×ğ+â5Œ©òÔİP¦Ï™ulù3+óqCù–â¨æƒB{¦$w\Pá±Ã‰+ ş¶>ëYë£Ÿå§¼šõ0{¦?œ!§TcM‰×â—cú–o"(VÌÔ›ŸA=&^E
9[ÆÏë“İnûÀìÔ‘ Ò Ã:¤iŠNGYšàûíéÏLT±õ¥mùvxÕëG¡ğÖ«ášù„T–—8¹•?34¬ahé£CwŠ ´ÃúËµÒÕ?Æ¨3ÿ“dQÂ5êX Ú*¶åè3Í±b!›ÿˆ
CkÕğ…*Ö¶;Î ù¯8Š Ï3ßİ±yÜ/7`D6í¥¿µÿ7›ºŞn¦‚õáÎ½_•í•A=[áD!+È„Ä÷@WI£ûXıv=ùô©TX€¯FljÜ¸G„2;y@‰ƒ¤ĞU‚oJÒòq¦µe$|ºe8®ÒP¢™Ïü|/¹ÓË“–mñQâ·ğ¦s,<]v7rËy´Ü¸Êµx2FWë¦Â0İÿo÷½ïÊ*Šxw@gÛFºöÄQ±9?<öY 7%’à	ü‚¯7_gX@D«o,bæA{ÈÙ,wÓsĞjw§1V¡/Æ3ó.lÿ´$©„mÇ)=#Œ¿7óìTÛkÔ-Çq¨{IhR Eö>1/ 
€E´>Ô\(0ÅjVeÍuŞ6†`k,>Óƒ<#³;£Ğ2¡?lx*(_ÎH9¬U.³f±X|Â"gÑ*poP¦ìyJ”Y§ğfr&)H¦LjU‰QË,£Â1E…wŞ;Oe–©!5_ovåì§pÑ`q,Š7üát¯"ö ¹)wëlMIµÛ÷ÒØâSEØáV„]s83·Ô´A”TÉFò»ÖŸ0ÓãQ‡³¨FèÈÅ¾Í“Nşo!N)¼ô£“İ…Ûº5ëqøŸ’ÂÊHE5ö‰”æßeº¦¦(«ñAVoÔ(š€i=w<Œ#7YÛ–9çeƒ÷pMVLº´3éšÚ$®Ï’ò¬ÿÕÒ:ùùa‹V\@ß”Â¼z–>ù?Åò
ëDû³®¤­ØÊÙ8Ø–ynıS(†ùåEæ`f½[ÌƒMJOÏÔêgöŸ²F»	£¦ÏÈoË:ê†îÊÁÂE›ûñ¤>İ‹Ôºújî0²>™÷ûV„Ÿƒ–î¾ä'´ßiZó  ‰Ï‘„øÆ¬©} İÑ·¶•KEMl›…Ûc«kÄ0AuZ)ú!Ê„‘	İ±H­%½QA²àÀ«òŒ{Eç%ŞLBœà‡/¿Anæc³ô%)I_L¥Ô; ¡:}nù4D‚yÊm>­N»imE@… ƒ¬tJ‚j	b.Û=¢mqNÍU\ÜÖ3í±ğN¹—MñxÉÃ-¢Šì4¡¸KÂVvò@I—º´ïÍmpwı>VÇ™ï¡Ÿ_SºÌÂlÆ>I28@móM×ìº	°:'””Îq;†ö©(.CY.‡’nfìziĞªS÷h÷ÉYL–õºfçöM˜ÙXŸÙrhÌg´:Õ¬}XäQ”¤Ë¨wùñmEÍv°fÍˆ8šâl~p™­à?ÆÈ«aQuèw$­•ñëê¿Òæj<%8®å´Ş…Ñ9?.ô”Aõ/LĞ…,rP4ÍY?‹jÂS‡+yŒÆğø9Û””öÊ[p¤Ú¾ƒğš¹0ìUà­¶L%ø|Q*ÜjúyXÖŸÌèÕ¦˜Óy¡Úóó¨"Mî„æWì¶B„¶a¼´spÿE<Vÿ/ÈSÚ7éÌ·È6£‘XÂ6°€´Kl¦­€›&ì‡q5·xu´O_=L$)6Dp®”*¨#ˆ7u¢‚o¿,WÀü	¤Y‘ÚDä9=“y×ÙJu)…¡dÿÀ;ôƒşˆĞîP©Ì$$.éiØíMƒR’ÎÖp£´5˜ ‘ÀeµÄS9æŠ¹§ªZâ7_Í¯¿Ã
ÍÁP—(·~XÌA=pbp¤“¦•™vŞ¢Á@İ—9­ıÔƒQúO2ÀB	İÂ*0Mù™[9¾$£Û\tI%TP°_–YÒ–68Ğ7!íOfŸaÍ gäØü„Á)İu+ZøàÅÀÅölÍ“WÓd¾È&ø6	­Âû¡c|.NÑE€3Ç?¾<ôS«ùC§áğ×§€ht{ënm……BÏ{Ò`¼ÖG}¸
’>*sù<AcºA!Å¡¼¹ Ä7¬hÇA+ZQ¼»2™Ä~ÏS±SZ·*·±°Kª©ÓÃÌL«Oİı»EtF4‹ØûèÆ-*Àş
j3
4=âº3*P Sğ¯¹õ Ú*Ğ;.’ÅŒ u@vìq+ÿ)öõ*˜Ã\£ÏZ·—îzÕAzÂ}Uùr¡X‹ÉÇ¶7°7o^´‰"•Õœl+Î’‘R>¦Z/Áíáñ
§!Öê¾!mË{È¸c8
KıÌË;äË7Q¯1€0Åwız>Hî’ÅßO¨FÁkÖ\ëå‹:·İ\¢¤Ñz¹0Cv¦¼-‚ß³>Š×9“”uúK7Jw6ãû|™V¬À0·XSÓ=8QìV×ZƒR[b@"µa~ˆŸå†âU¬j!d¶yËe[ıØÍ~I>C‘Wã­wà“aº&¾µc•W­Ü\.Ò?}çõİû8gN$z¯½'T#È¢´¯KÍŞõÓZ]³i6å†“ú5óá.Ÿà—Ú>ú€´
—òâóäö–U:š}™úp‹°Ò$ ïO¾ã¨Ä¥«ÄİTßÊ„3löŠC3ti0[¼_ªé´‚]’/±­ùõ6ê›Ä/¨DÕ¢+vLéš[®`•H¥úã¡
`LWïH;]¬$ñO¡Ã¼%Õ
d†×´wH&Wì¨ı°‘æ)Âè¤œîö¨a8H®YÀ"Yí{è*ª´Èèöa•¾·®¦½ÒV’0ÄnU¿ÀÆh¢glÒ‹òh}ªF¼çE¢èŸ&}µYô­È§<hÁ×ÎğÚ|ëTœ0ïH’raÎy®55Şœp~ò^ûmÖvk¯Reê‘jòô"T§JÂ§æ†§ ÂÍ÷Vî^2›˜o½øI”;‡(´SÔI/ùSÇ¹›t†ÕRC7ÑwÒH&¢1ÀWLmX³&§Œ¿H ,!H¾xo¬Gc+ò\e_‘ªÜßq1]éğY’w¤¯Ë´0]˜ğ·ßà3Î|İ"Ä}¢ºˆÒa,^{k
†Dƒ÷Œ%%4ŸØVRËyD{c¤[ÍØ“§öÇ²²> D_$†?=oÌ.EÜ<¨‡'^—t‡ùp`©jyk×6|¼bj¹	s;¨É «&shL7ª%÷ìã\#{oHš?…aÅvÊº9®<3µé/8§SŒË·Åo¯SÉyóœûîo•IëVµ–#îá+Ú—ûàœR¢0“˜ºé
Õ	¦è£6ÚÍOa ½¤†5øÌNêüb|U¶ş+;¥PÌ¸gÆ”HöÏöéàB‰	³Ô4W!ßÀ± Št£JM‡-‡uúÅ«óMA€¶…Z«K²ãaX Wdş¾4ôcÓQDØ¦\f€¬‚o¶şF2šïÑC¤: 0º¨Eokp“À•K—†ÿ(s&i–0Y»ğFGS0sêT€]®èQ?†İcÀ\ÑÑÀ#¾ÒOÈ)ã#îzñ‘dg:ÿ0÷ª|è£T`è°ä’‘WUö“v'¹1äv¦õè‘õÏĞo©@ş›ì¢{Ú^ f[4ÆTØ3O*fÌ$¡:
eÿ0ei™E^~h)÷Àû»‹B£>™¬cÚùÍšQ¡‡§Á¹öj4oë¡»ò~qÓ.3 ¸ñ_D9Œ¶&´æåò½]…¹d2ÆWbÓ?;—oCÿôªKLÊ(•V*rßd×´ºÿ¾ÎoaötÅÌŠÁù½Ïö­åP-¶ƒêaà„|Hz2Á±IÖM‹Ë5¶âÒÀ4Kşô÷ùÕä$ÜRÈÑ0å¿•p`>4½Ë—ƒr4föü0€¹Œ¨è‡ŒÖëœ›¬mÁÆg–Eß' Ú&D?˜›@u3l3œ]Ş˜”áã?ëyÌaVuÂÍ`ı‡Ğô R©¨c~}æe³¨'fUµ8újÜçFÅû˜Êé„¨œé¼|ÈÛŒ‹ıWÃõòŠ‹äMËprg5JiË^w7‹Tú@ic«]xë7&9S^Ç±Á@®q–üÎÛ>  Dp©Â u¹¦ ¦€ğÅ…±Ägû    YZ