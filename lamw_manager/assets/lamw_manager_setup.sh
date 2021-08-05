#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1266634930"
MD5="4120c24c5a79112bf22d82437d9c371b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23744"
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
	echo Date of packaging: Thu Aug  5 14:23:29 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\€] ¼}•À1Dd]‡Á›PætİDõéè±ô5™­Ob‘•sBDL8³‘˜QCTrö»“=w† 9/ic°r¤³VóTÈü&îÚ m/µ¬5H×vf—…–0d}¾·ÁHC«¯º0wn+ç4Á6¶Vjc”ˆŒ/¦YäÎšßDRîÕe2Ãrğwgø¾—Ç:ºlüÏ ùrª—Ğl*.,¢lKOgâs»gdV•¬m¤ŠV}îéÑøhÿ¢2Êc#—¹0Óª‚gë³˜¯şìÇìï±¤ûè>¹k Ô	ÔÏ”õKª­ª DãQ£n‘û
¤µnã¶ËÈÊ”’ù¯M¶ër[>ü9mÖMS·•Íuw+5qE~&´úaS<éËï³ñ1	Yó;°4!jˆ‘›).èö8Nw”k¬ÄÔ½£5ã…U¥ò›½ó§XgFšµ¬>2 ë‹]¼ÔÒ‹F»kâ0@ëb	e2õgî„ëIbùøÒn,¡,™jRU€\JªpYU¼¢­İ*ß™ÙZoÆ`$†è7¢Ç‡ÁoM¹íô¶ÙÑßôô±ÒoƒCÌ¡[_KñJié:ùs^¹ñP¤ßâĞ”D¶^ïíh1Y:s ¨À¸=Û§VñäÉõ?VvK‹a¾‡@FB€ùÚA$^‘0ı¿w7RøÁ‚eg,°ÆVU×ÑY{Åª±µ#¶Ë¿·]iù»ÿyq&Ä¨|<´Êü¢ÓÑ¬ní¿º“ùb(W‰$GÚLËHÉ³ë"¢p~’J†„ÈĞÆ]´ŸÏOgMıW]„µ3AaÏòà*€ïÆæqcË?üj§.@‘WàzÿààQT†—Kpš§üq~Fğ“‚êÿ€ÖÉıÓ[9Hbşÿ]ß5f1§íïJ÷yëÒĞ“XÁHE“—[ïªIıíVÖàC°-ãPâj™ë9…¡°WA’Ø¤J5Œ¹5§9U’j¼uÆ2ß‘ìÚ©g‰0´¼ÓÑÚÖVÂ/Š£æ:R<½Ü0 ññj¹°u³0ê:ƒ‘½=A\›¸ +1G*ô¯ú7!Kê„ÿ˜ÜåÂÄ>Ù^p4±%·77‰Ç¨£q´#²4ÆülØàQ©m§¯ØØêxÂLõ:·£U·—œ
À(Á6SâÕfVÎ`İ¤eÍ‰VÈuG8¡ñ!ìræTŠı…-¿52Àô™]¬	8û'7¿Š’ŠOÜÇzèõğNDVjè-ó
!o¨¸ŠÃ“¡xÕ#3ô±"e;¬cÓ©¯m»ù7°‘LˆÔàõ«—õ¨¡PúÛzØ
W{éÛÃj¦1l‘Ör°»#ı_‰U€n0¶LÒ˜:>|ISœîFCÊ­¶:¦j2•H_öğY‡äHTŞËÖı§ïFÑBş<ó¡ºœ§ØÑ`f²Ù¶Öç¬Ê·Ï¡ğDbdf*à3-F€½î+ç]?>bé^GKA©b„—ªV¶áz€¬¤r}aŞ†ÄE¶¢eéQ`‘ZÏC"KØ“ïË¤Ü{nh˜BW@É’'SÏŞ4«Ö§*xö3QT¯/k“]-hºÍ¡‚£Ÿ)v¯ÊJE–È¡ÙeÎ³é|Şî©.Ã -Mæîª•Ùİ•Çd:g«÷“ªsÿ¬ë'„!ıºé„š-V˜H­z"QNxá4¤ßáã6{†s¸¨[MöCH]‘Áurz°Ûy­JİGàR3	`…‰µOG¿…U‚ÃfOì×fº£ÏE]Õ»56Öàöé2Ü<3#µšÎ bå_­ÕG¶ó½7ZŸ“‚@eáKíªc[å€¡ø8¦!!ÒÄzpÄ›:•GQznr¹$6ßT²VÁvö7CRİRˆñò#"GXÌÎÇ¹mbN°ÇëdG²úŒÂWÎzûûŒ)¨Q4§hé'Z‘02Z6èÁTáĞLı({;]EŞ”µ2{uÄô.PeLx›9#dÔ½;…q©vCJì=pµÆ¦T8¿qƒïyc¯²Î{:#FjèÙ›Bğú<'|eÔµäM:ĞZå@Ô:¿ƒ”9¸Ô|Î¢ôs%´¼õaQš)¢‡e’ºë=¶êœ?®ˆŞ<˜<ssë~e*ª˜r©Ğü9a. /‡ºHTk¼q;Û×©Pü$ˆù„rû2°/R3ä!Ë|ºâ#ŒAd“éÕ¯YÜÁ¶•œûĞÚoA!BÍ×ÚËè³á|À‰sÄ_–^_D,>Na$» :¼ŸÏÒL{fQqëY…œX,fÓŒ[niOMãûxãĞ—)÷½¾Rísè)
C­û&vF¿t¾­Î³gîÚª•—“Şˆ‰?SËBº”¯ÕÑ ñÅ·Q%ÖòÛ"¡ë»¤•¶b¡=ĞÌx«%sÓå‹èº¸‚]äu?`Úî¡nàæLF®(Ş	E{<a¡ r>)Aú6ª@IgÓóê½COSª“‚M‰ï©	ÜœR8ÿÌÕ½r6.E!»G€â‚¿ò„×;Sb¥|E½‚8tÔûKœÜ)GrX&ô8V˜mçó³-Ñ¢9çTP3RÜ.¼VãVD C/ˆĞ³şb_¬ãğN’éÔ=?Şaÿû'ØÌ˜3ªA&óq¼“ƒVŒ F8
‘ïxÍü‰HN„'¾ LÈ-âé¨I Ì#•Ê\}»%¨²@|İEÕ;L<rø¢d|—mIèoÊ¢å»4ë|lk¬•:‡îksÛªórŸ~¤1ä³7¢ ²¡å …¤
Çå=BºC¤XÇè©l¸){³ÖW~ÑRTŞöÕ'ş¡è#“üHÎµTä‘T|DıûNÀ†zšacì­?iÑ““U÷@ÃîÍ·¶TóÚKæTƒ˜é¯BzI,^nÃg}šÀlw´ÚêĞb>VÙŞ¢¶ÈmDyÓe®±Æ,H7%Ø†OæİÒ86Ñ¾8Hdñ,¨TwNÑ‚KF_iÖ½r‹QV›7…‚fz–ë5¦šòüş"ÉñÔzÚ»^5@8f@*åqhZ©ƒŒ?ukuáFò¶z\—§ˆwç@¨ `IÙ¬‰™4€Şšæa˜Kj°j>BõgÒ Ú´»¾±‚ˆ«µûQ‘lı¸=`šø+.»ƒÍmíM	“d€©ô[|/E¾•a8‚Âê%¼õWêY›3-H€Q«¯–õùuÿ|T"dáË¼òYxi•»pU*Õ¦àBõÓÌ­VbY$š’m\Z´®yé”MS@7à§›ùÏ¿–8ËVFì0Î-öO«ÀD…¨›3w‚šß’»ş=ÖØ jzÃódtˆÓå’TÙÎ”‘èQ Ÿ~ñÓ úÅJ;;I·Äá$Öob —´½ˆµÜŸ7â<3
y‡‡Ö}6Q±_1Lmècˆ«+„>©D¦ÓÖDUe?®^!E®wŞnãnİK¨0ùõ[Ïb²rĞ^UÌ%¨Š‚ÑBÒ!ÌºànUÿøZsw#eA"G€®‡Êæh6\ş÷ŞùÚo½0˜nÁ™\M, ¨NDÂgëu2çÁ¢>TñJjŒÛıª,}n³¸	PgÇR«0$AWÎ Ú%LØ§/MOï´à^Â>ËË„Öne=œÜwçôwñÑtìI§í´åŸGFÂ²Á-‚§¹ İb€"f!è#NÆ;^Ì¶°«æÊ
íbKBC18‘0<Å;Ábç[h\šŞ*”$éÉ(àâoöÕ­Şg-m„ãz&Qen‡uÂù•_Ë\¯j”™6
,>ZY¨'óéQc`›pT9;c'2P(7¡ßá¨o)êV¿e/Ìb(g÷ôÜE•TÒğıã•à»Ò3œ¥à‹§\ŸM>Iw²ı‚!Hœ“øÖÑuòQôÏ(eği¨ˆÒ]¾-ò¨<Ï‹g%10YÇD—y9ØaDávÃ©OG7ÖËOôĞ¬óJ„	
&ôb‰NL<ÉA`ß	ìˆÄDjwM¯,¼ ,8î'º¸N½´µ:‰Ê&ä¸×œÁÍò-õûŒš<“æU+ÓŠÓ\jŠ„zûÕ5Dz@5«ÈrkÊ“ßDõê®‘Í˜‘7…FœmÖQwq¦Ç¨<±¶ç}ÿñûGÜPLŒèg#
 „ªıé%áåJğ6dcr$`ú÷æ
F€ˆ è ic´vÙ¿miøá‘iAMWáñˆÅÖ5¾ÇN·5­Á	œ¿ÆfQÔÑÀ IY”)T€uÂQÿzCãßÆ=d£ch²'G.fe³/Ö¨z‡™ƒh‡	5kAyq'&ş˜1WBFIKõ‰*X0C<»Ÿüq‰l§—b"-€ƒJŸ{Ï?^’®¦eõf^Økû¢ Yk`.ñ!K.Æ1/‘¤ÿ¬Ü;+Ø-úË¹?‡~‡3ƒYFéO
³!~+ha§“\›ãPœæ¨µq½¹ÿÍŒ·‰†Åv1(n?“fÊ¸@y¯
ÔWYWÅ
åû$U²¨“ZµJ9éë3İ:ù‰â'òh¦ ÚçÍ\ĞøPVøë¿oVÔ9Ğµ^éké2Æ’›‡.ßIøšŞ{A$:‘Ï·+Kb“Œ¿ ÏFÍ•è#¸Á3Øi–ÍnœfQ¤]r‡âÜGd›¬ê½ããëë|h¾2ğã¨ÓÄM]aÊ×ÄÒûüëµî­šFiöb|òøº©iıa½.Š~]K6ğ!üÛ ×%{°dş-¿§ šs­@'Y†Ù…I¸8¸-úµ¶Øšøƒâ×/ùí3/	j/À¢çFoÜv€¡!d±oÒfê~Lì£´)k@`açõ"a¶|µ©wkĞ%zaf
]À@æ†¥F†–"K4A7:Û
\=”6Èü¶[å*Ñ›Ú#l„ò‘QÄBßèmú;NWR,>ÂŸV§35^3ñ„,_pÎâg¼¼ àk8S±ÓWòRA—ÿğJ6ƒZÊ´6ùí>÷JbIµˆgæÙn‘’(÷0Œu¾Î•Œ2¼ÁÌ¾
vÜš³°Ø´ØM™_,	e?M]Ä¬ˆÙK-G/¢×&YØót¹[ËñSå×4>w½eøít;lN ÛéëO¼?Yämz‘ïmM_O) 
Ò™Ÿ	|%dø+§Ñ§åfôä[óTOx÷>˜ÍÍŞ®ágÚˆİzÊ-ˆXŠN{,šz¹ªoâ/šÀ(È)âDR…ÅÈòS³|;Ã%Èã$†ãß‘Ÿ§KD—gˆ96w‰VÍ(#ªbŒ$Á¹ÔgÂûÍ&¥¤‡øEâè£É€^74ØÓÔáp”4‹rsÿ·åU<§Æü´UŒÿÆ
¹·÷8÷Ú®BJ”¯rÜ]¯‘su2ùÀğÜX‰×[o–UãR{#¸c‰ízâ¿T²ÀLÚ_§æWš’¨¢=‡æ3ÒIôx<â÷ÇTœæÒ¿6>5¢&g-®=ÁËh(à½À‘Íllj‘i™ğˆ£,¿F€ ’/÷§Ê­{´5Ô’¯¬İcs8q5yşêx¬9cÉ<º	Ê1Ròşö*µ€ƒjú“Sİ¹é†¡ı¬Ù_:°iºÀğ#š°	g˜ñ[Å Ó	¨–Œ4ÙN$òA“eõ¹İjgÕƒÆ…Íúhwv¥–®»0œŠÔRğÔ‡“Rïéİö:ïV¬Å¯,^l$óF ÛvÇNV`m@êá¦=Ä%DÏ;„eO€<hCc™³¤½pÚkn-Nƒ“0zÇûÚ*ÇËÛ`­¢!XÀµY¾Çsç-ìî²—ƒ!oÛ€âó>´['¥vï³ÎÍ°ÌUwÀ$Úÿ¯‘ĞÙF1a-‘hÜWª@šml'p\«pçã€n¢ºÎ;ÉÇhFY«©ó¾Õ`…áêå$ZÔÇ²â	Ú	}ä7SÏŠ—]îìNºèF>ÂdÑÛÎ9ÁÈ“·'ã¾²3«Ôoc”Î5ˆ¤êt[lŠx¸l¼®^õ«Ã!Åv|©¯½ºªäº¶Æ‚ìV
çW”Mè°9(ãm,ˆ¦²Ñ¦»n˜Zr·#•*8­0Y£¹”A°‰şúP”	ºƒúTßgœ?÷"ú0| ·×çƒ}¹%âù	¼“ œ%@+¦•ƒşá8KüWHmá6‹a·ö, W—œ4#„¤¦EĞÍeïR*téH®sò§•Î`šß§"›‰R½b„Ë¹Õ²‡ö³­öÀ£ı$•êĞÄŒ#~üÜ¨jT¦8hXÂ‘Öß>™Uäı–Wë	N…ó]ë#ÌÖ€ó<¥Ocˆ»É&pk>ÊÂXK¸RôJÛÅ&™·G§öøÃp³k½W4Ö}3Z¶ói»·ë¸8zò­dñ—8Ğ7 d;ëa¿‘¡BÙZgÅïhešsT
uª-?zÂH’O`ncËe3Ü"q †·qœ\ı´œÚ
–¦Á´§(AÿÇ°ÃMàP'l8îoY²ÑqqÎ×J9!pg®÷à³G<ÑzÅÙdû<ş[M¯O‚’‰5:Ë½t¢Ùo„èÀ²;`ršŞ¢$¨‰%“ÖBœHë
÷ëç‰¹†ö<mNg"ÃÒ§rr„âÙÓ9+è]pzQq5î*;6«† ÅqÕô]ËS¸Ö<wÆGšR=M±w[Ï6øç1LÆŸşœ¡Wÿ5n¼[9"XîXıqR{SâÒÑÂ…[ì©Ö19S‚¥§ ü¼ÛT&®£U¤4ízÁÑ#®Ï‰r*œBä(``ˆd‘úÓXcÿãÛqˆı"¥åyË³ÆĞ%}…VLGŒ7İšÚ4èèÖ\Ş¥!¡p‹½Šdæ¸×DÙ<	ã´´ª’ ëÇ²·YÖÀ«Oû¹nû²qğ‚BÎ„™ùF©Ì÷s|%‡zˆ}ˆ#Ò;rª_ßòd¾i*´­ô_öK *7Õ(şPu;öw›« 3ö'é–‘v\¯r'ù8„*Š»Pv9QMs¨w†ŞÌ•ÀxEoĞtŸ(vóSÆ±ËŒ‡ RgÍqgÛí˜ƒÌÿoÒ÷è™(£Wÿ×ZäNLòÒf—sÎ³ÂLØDv´(øÇ|)k úTi-•¢ñ—ß4Ëür7X/‰)€ø'8Š«¯ğû4.‹7™%”è|ëÌûWÿèºó?fäLÃ€ÆHŒ[“àİ@£G¸#`Er™Õø“<Z]ˆ#Ìä+BJhxİ0Àç¶rÁdAwû‚!À)êŞÚ^Ê]ÅO«Î[ AÊrê´œ4QHZİR–í9”°JmïZm!‘R3¥xXbeÏİÒßÑ³ÓNVT¢§Zãzú{Éf Š‰?Hÿ9şI¦÷ğ²‘[gÈG0*u,ş]ğÃS¼Î\A&BĞãß`©eßN+<êu	) |G•dŠ¢dÈK;n#2¼G¯Ìò£Š–Vt€‡Ìª¤Cú¥´W1'†ÎEÂÖ½¶õÏ|‹„½:Øg ºbBş Í7‡ZLœ+CRulÂËT ù$m|ÊàªZ)Ù×:î©~f		î¨azÕ÷,2“9G8ĞI,\' Â;z¦y“*´&"¿}Q<<]„L?›>J…:ômGË!wytó¿ªQæ¤Æ0>ììõ÷X. 
òG”vM5Şî¥a0T/¯õ*±Jª\.õ³I¨ò÷¬»¬2Õù”$ŞFÒXN1¬ª^\±c_35b
™ó¬İ®ù„ü°ëwLYŒrJ—kràª³x¯f32ÓÓ¯gõs~O&6–„JÅû@ˆCJÁ'|4í~Ë¯šÓnxáâé0@«í*ë† :²@7¨<şî?ğBÏm+
¡¢ÉÕğT'FLìn›6~ãJ°P2œòtL]QÚ>Ö?qAí¿\ î6±àj­M‚j¾2zız;SÿÉÿÍá8I,^-ë%øWÓ…GYÓŸ+'ófóÃŸ²¬ŸUı÷²ØÑÿ‹Òú-	+N;!/Ibå!E§Z~X=á¸á}ä‹Şñ/j/Ï7 s·YêGQøøgÂÊc$ªk>´}ş">\íŒ%4§5¹“bs_v¨ÎÅø{¬€Ş¹0ÛaşN1‹†š+ëa–A	Ñ#$NI¡¾êp¡?áXºw˜Ç‰}7’ğ}ÕÆú`BHÑ½î=@âTv'$Ê@)ã®­ÒÈOì¤mÂq7)9öe´¥Ö‚ÛÆºüº´Âr#³‡%ÙîS.ˆ1ÔPõ­¦çóx4š	È%,‹„<gÓ®¦w)—ˆÛKÁR¶§½Í*‚<Ÿox³e‡[Ğ0•±©ÊI5£½"ÍÂIÒ2{å¤Á€ÚÏ‘†a¦ZFl¸&Î§õ
Â­ª¦S'¾¹£¬¾K°$?Lqü:Ä#.P„ÌÒäèÃ!³ç`#ıõZÒluÜ[ô­Nm‹ašnAa°Ÿ6SWsè´á‘Idp^\ŠC³Hl(»UcĞ=ÅÍğ‰æ…Œ_S•wæûË?zú ´ÑıÚÄq÷­'Z¹™E7>›tt{j3æhª6²µ¸¾ãBõjÎ:Ş„Ş»¹(h;0cùœ¶·’E‡ãtº4eğerfÒ°6yòãÆŒd\§Ã„JÔ`›¶YEè“QÕ®UVÎ…omğ¤ö‚Â}ÙÒ"ø¹|Nïš
xò¦Ç=	ùĞ62Îº“ü‰Î­u\ÈÔHŞ_AN¯…æ	G
	¢Dfàxã&h¬İf€([‰É†EÏp1ÕÁC¡ä-G´¥-„ARY;İı>0ü!íU{14(ª[CÚ¦Ög/5ƒ;jOJöç¾nB6ö…d¢îãÀ2u^ã'=¯ò‚å|¸òwÄ,İÛùƒg€,)ë"™0KL}‡
÷O‰™[×¦“vÎ~u[Êñ¸†Qî7^›Â#¦œ6‹˜øÄyºPº“eÿa·íiòñlÒ¿>‘ğND{ÓğP+r 	gÁAtôšh„e×ÛÌ÷9–60?Šô2š‚Æ‰ CØy<oô•c¨ïœªG&Ù-xùëù[0f`èe,H±Ä¸¢Øµ­I`f¤2ı'åcŒ¡o•İûu%Ã[as%¶ÜÒNn÷õÔZâ=§î$ı³hò#·ÖÁaÂòÊ*h	è×¹í0²MgBÂsÖ<¡]ÉÚÊew«¶ç^¨ÎÍ§å^ÚT5ŒPá(Ä¦¨xB«éqÇgy?I`Û#ÈÇ¢¦|<Ô,Kb°«®EäÊkŠn*WŸ§H/4hÜ^éçÉéÉåÒ‰/¤ïÎÃµC¿ÅÀ‰-·©ßv€u§Æ¸Zç«C}¸¬›c÷|{Ò©j<Ç“Ü/¬¹2"ƒ 6øµë÷|^Î±. àÂN)…GãrR•æéæ»»×Ğº½ Aöÿ+Áƒå™Q¤FY¯q—ÌµUĞäurB>¶9ªê°	øçvJv=¥°x/VÎ‹luß,Å×uÛeâó~ S~Jx!óı,>ÆÆŠ`v1¥áD'–“µ„T·ádéËr=¿”¡u5Ñú•frBÑU½ë,ä÷‹^®‚~Y™’m“Ş (v">R­séiö‰BÉûçÜ›Öêd6#Ä	­÷@ï ®Â…%•è|sbYÑ\
İÖò%»*jåv	¢ğ:{»,µ$ë
Â³Wn"±õ‰Ç§%!½	—EkıÎ$Á¯u~J¹¢¾ª‚×H¾~Û ŞêF¡ôio±E¾ Ëæ'3«¿š×©·ÇöM(dıã-ï()ÿFùŞ”K3g6¸]İIäFíôÅI£Kà"Î.…6‹ü!1ÔŒ}óU5¡I×¾ÌH³ 2*jE|¯Âæ’PëP‡íÓ)in|C*$¼:*W@–ÛM*â	CZŠ÷G	d£şz:¶VÚ9LÆ4–ßlÖÓ=wÂ5FÒA´c_n¿-‚_zK.›ˆ‡ĞÖªxÓÎwö¥½8Yœ+[£³³«86u7_®ğ;Jâ}£@½L¤1=Š¾¾#ØXªCÔ8"Ù$=c*«…3Î­jŒ‚ËHããqğú©ãjÛ†EÏû·IÆ[]xW
Çˆd°3ádV“¬•ZúLÎ^QTdÁrÀâQz ¼?oH§|E˜~­5G™ÎüÇ’ ¡Ñ%Uk¨ùÂ¡ ]™Äl–Û!'D6(4{Åï¯Åëïâœÿ§Q‚ñí5Ç˜çÅİòôUÁw´"±¡%å]7OHœãeÈA,üß¾£½iÜàl£¨ŒéèVú):Åõ›[söÏWü´öO{ÊsPÎ‚¤haÍN“ÔÃQÑµ× b.Â;<Ÿü6€±=y¡°“Ágıº4RÖÙ4I`t]Õ#6%>Ù´L€ìÕö’J	Ï<—2•Av×¥’W?LÓ#„âÖ£„ûME„›²7dÒºCõoBfî˜–Óˆ"ãæèCÍtŠ¨\{6	İ…:á›¿v¾h„ò¾ˆ®,RÄ}f%‡–Zï‘-\ÒYCÿ&ddØÓV ÇƒÇ*ŸïÏÜåú%–{d`oÖ•e»ÍŠ%|mW¾“Û5b—ä§ÙşƒHñJ] scÉÛ¼¥?ó"5Q¦M>ó%¥-}8Üâ½7àN(Àúû?}?õ±½áC<[ šLX"Ó –3†Û|‚ØèßYØ	Š+rÜ/–òäÂ:N9­D¿& ôø¦	’D\'½ŸÄx¤¾£påŠèŒÛøqË·mà¡+íOXš0Ú¬Q»o‹ŒíFœf£a¼58A€	, Ÿ0Âïcá“#E@‰B­uàÛ'=Pí¹s¥°˜î‘µfkÏ³ÄŠ\Š/†ùe´Eª‹O/]>ë*Ì™OÂøkÁ|Ú‹ê`á ë»kYvİ´pwœËŒFB7ü¼9£Ç¨Æ 3ª;İâT¥Î}Jd÷Ò•"õ’X˜càBmÊWˆJäàzY9Ï{@ß²5ÛÆ¦œHË¥ğ3û!pïî¨èıT­.ëŒê–ës6'Lª©¼±Q±÷I~ávL*¿ÊGëW_1‰QúqVØzü^Äpì†+şr7z
4.ù±¤E&¤óxÃ}Ie&m¢¬g“¼Ÿö‹V¾a:úŠ ˆâÑô‹PcˆjÍëlŸF¼xÚíc‹ÛÆ
c¾Ï:îÁû^ìï¨°8»$ñ‹1z%Ó-_µ¨ß3i{<$…ûBé™ŠO¡­¤Tù>{j§ô%åXh¹h‰ººĞ>®€ıÂâÚÑ05•:Äélı5*ŸzØäƒávì#~KéÅàÇ›bš²õx¶Â7å¯á‡%CU•6P f¦öĞÔ8åY5–ú:ç6ş3V®À*"ôÏ’âWüG®_Ï_Ò°pl¢q·5ËpMõÆcóL¨J.·”Xù5‰Ç_Ë¶[á]û„ïàJ! Ğ%å¤æïA•š§$9wªz„_©w-ëç°;ã”l/ü3Œ“’/qô²Rßƒ£…3rm±R§æJõPã1„dw æøbÕY–g5vrZ¶Ğ5ËvÆqÔ,jóùkä©‰Ê$H¿<Gê,†éÙùvÒ»	+ø›k¬âvÒÅi0¤ê3V_Ò!,ğŸÎ%@;2Òö˜[èBud-ğÆ®Òe1'‚…°\±¯q”"ç6Š¾ĞÖ£ÅT±‘b^FeùÁšş'	ÒÏNwgZûôb+F›çŒ çãLµr9¹V¨|ŸÇ1.‘rW5¢üih‰ÿÖ8J¶?[@/  Ğ(„ên'FÌ=Ü½²áûÌM!/}ÅÑ^¿d‚Tº]qéõı\®G,±5p®LfJjQ…Ö¾ÕJ›ÿ'»ñJ¹¡”õ†Ùbâw«|Şâ#.¿›E&ÉÑª·£yf2Ş	ŸlB:çÊD*{s„^™²ãy8w~Ïx,ä˜6ÄöÌÍEgª{yµùí¥ßSÎ BØÕÇû9rrS….Œ1¥$@M<Cm(©ÅFçXõ×'®£5^“ÅÖÑ,½Å‚Ö/g™R|+\Yr:RùŒğIGvß¢CÇHªöoÀc›¤şãSPßÙ©¥¹8PH)¼Ôèúvá#>ßaÿRéRÕ^WşIîFE&Ç^İ8Ëë31øO †şkùz`>gl»-¢¢0Tó÷¤†Jİw³i…	
Ÿ%?ñåPC9ìTJe·Xw:¿ÂˆŒè[]šu‘Z;èÙ¯6±7h}ÇŸ·µƒ"ñ1ƒ€ö0oi£¹«°A1#Jµ0Ş¹j¿¢w ø–)¹«'±âAù2öÈ2°¶èJn¹YY^Ğ™á?~8,úˆP_U§2æ®4j‚:X7Zq4j˜
×XÆ_SPÅ¯¾éí ã4T ?”ÁU¬TáÏ^ú86§OP…^'ğ¯+§" Œ¢iPÎ2•ÁûC1Ûp¯ø)Ò½LÔ‹hÑË|bk
d{¨;6rcU¿PDu{š¼¶/`aÏ·îÅZ;Ô3\)³eÏçÙ"Ğvp‚â	òˆÉl`‡Ù39õsÆç†ñ”{;Ëé9'xÚöŒÂËëCÊÕÃ0YÄêÛÑ©¨p=.¿Ğ”ÿô¦P-¦2 à¹}ûĞ
ÌmÏYêƒÂÏ¬rcT~¤„•°Ù"Ûg±Z6dP^¸b#óy¨ŞfE¡ù.3ëT¸]©Ì£68/Ip—®WÙg‡×²EÍ°>
Øš… Öc(_–`ñÓ/ã¦ò9ÜßPøŸ0Ô³ |q =—w†‘Ó˜ç†x]3y;æ)ëöaqu
¶b,{¡9Û¤Ì£ÔµwƒÆ¿5„iûŸì*”2ê.‰ZÎÄvE&“´ŞZ“Í	y¡©sJ†ß°B´DÒœXZ¹ë8^*üCËúzsgìtÇÜø×ƒ±íxm˜í˜¥› NÄ¯
ÛÄ™Û™ñ­Íè„Dì–³“‰ œª¢.Má–

ß,îejâQA¢á8#¨íîÌå¸kíÉí¦ĞW4"˜WÄr#eÅªÖğúW×Ş³e(-0>/UvÌŸ>ów,$ö7‹€ÏĞ?šªŠ ²ó ÷~şV‡ƒ–íO:˜7|][¬ÚÆZÓ¬ZÇ¼‚³X){MNÃ’FÖŠ×9s€ó4R¤C&v¨IÊÄ0ßùß=8q°Ø¡'ÊR¨×÷unÅ	HN‡‰‡Ç<cq®,í¿+o"î;™gÖ]}ET'BÖûĞ¼99j9lo>YŠöm!PãY˜“5zv÷"l³„ÈÈ9ò=ñƒ”n^ã¬%Aó?}ø#ñ¸Ø.Œ™ø4C>N;—ãû…;g»™Y¶ÑŸ0µ¾dÜ|òh›{E@:á2XÕL3 ¼µ•ÌÃW_r®°F_¸•6Ã„–3Ë7’şLñÖÔì{‡û…%8Î•6÷}iTD¨²'÷Ãã´“èÂ …ÊÁÇÔÖÆ"PÎ›A_£0½•¶¹ÔúWv…üS[²—•oiëèÎ„Ò,& f jrÓ¸eD°ò3îÛ¦aYc[Co¬·rt¾vÓ3–®ŒšS}z‚YÁ–Í&˜·>ú3²I‡?½•å+ºxƒa#€µÌ™ÿ}¨Q,yV8¾3ØŒÈQ±ò¿R‹ŠıÙ¤IqšvŞƒC„®1BÕ×60<¬Æ(À¹NÙBîS<Oï"G™üANó µi,|»)ZT²‘Suµ0æ(¤/ÛúsÎ²4 8¶ÿ’×évÌ,[EŒÛ1—
·3óbÕ$K%¼SyˆÿÛ]hX]Ç{JÑF‘'28^ŒvNÕAnJ ©aº‚ñ_üIvë¼bèQÈÈŠª˜!€•Éå‹2wƒxªÌ¦ğëÄŒëYy`2&äã>¦=p¿\åD!€Eä­3:Ÿ²Æa(8Ğ÷â%ÿt{Ğ’‹­óO£{ŸÆ‘,²8J ½¦:²£ÁœfUÁóto©E»Z’È}İø%h",2"^fcRİ¶?™cn¬Ğ^mû}#J[*æ~×õ¥C„dqQÄ•ä½Q[¦Êî`<æul×È\Ìp%¥©ş;XÓ„\·Ğ‚®`O·Ü7]€#+±z$ºşˆÄ*¸ŠŠ8ö³—Nê68ä0Õ.Éğ*½}É¤¥&	¨Eç'åSí6e0îz$ó”ä–
>¼¡À¦6påÌ£´‘@×Ïş#å™YkwtÖ,ò Q²ûË»(NQÙ.¾ ùÁ«@…9úµ¬6ré¯¢k	Ôk/ƒîÀXg¸ß›b1Éè˜òë½vsôb5C3Í\Ë€±ûó	!Šÿ›4FxSOÃĞ¯/kÀşU¢ùßãşræ*¾@C’ò‰wÑ ‹À#Kt”ãê£]§tÁÃ­`:ËP3]ş	â¯¡ó´·ˆÒn÷ç¯ıì¸^Õ?Âz9ÉÔávh«64q—õ>õ¾Ëìç0·hgú4ñQÖôĞì$ÀYÅ10ÖßGĞ˜ñš¤–Ğ=ægÏ=¥³d3J4B”FôÃü–êNTÀm¾!›ô›<%\{Î`šğ†ı|º¿'-VŒ3å¶”7óç™Ì;ÏÛ7ôÀ<´¤Ãê	iUñ“N•°ÀMq†e„É–Kµ÷Jyî;5ÿÖhÁEésiÄkÏJ“wÏ­ÓïïôiM¼×ÿRš,õ@h¹ùÔhÓ¸¶è`o[+;"À…JªİšŒi¥#™óÿ!xAutóépòŸ ÍTÙ'¨c•êN¨û8F hÜâk™B¾(Ù½ ¯Ÿ‚ÀÚcC«ÁÊøYQQæ•|œéÅ„ŠÎAW[H*”kE`Ép°·È‚VÌì_Oˆ³Œinœş¾:SğGØ)—W =ØF¨óx›rsdÙ•Åå£ì„©s°)Î´§a¸G ëJÏ&U /éõoOï·¨ç÷:Û8Nu‘ÿK—)Ìµ‰!áqAıÂ0ay™íµÆGˆ$:·I>Zïx×¥í¯ƒÁşÍé?yÜAıRÓŞ§§Õ˜^UİÎu¦ú'ù‹ÄüûfQJOÙK‰Ğ¦‚Ëş)·³nw ¨¦uúÉc+†Ùrg‰~?*$Ã³)»h|ûmUri¥½·:^3Óâ–˜›¯·Ôã,‰0ÌË‘ÒCğ´–e¶»`¥ÍJõ?}³Na,˜JÍ—ê(şÂµ’ÊìÛ@^¸K‡<JØùXØ]ß®ÅÒœQÀïü4t&%ÿ¯o2$ ÆJ	¤>$¤ˆËü½PK«™=?­C¬€@táşPr*
<ÙÙ·ÒÌØÖ´@Ÿ‡•<ø~ÿm$¢1.Æ.»G	Ô™Íğ¼lROå5W%®\JO7ìr‘(¬Ö\÷íÜÄ¹»ïšóu[àµi –;dH$Š8Xüâ|,Š?M6ın‘Qå¿Wİ;L–°ÓìH?3¤Õ.øÎw¸‡œÔã¡G\FOÁŠ ãwbƒqŒ‹şt1AöÀäÒSØ[%«o²0Ãµö!ôzzÀ ê]Ok-¨fmm²…ã•øRÌÏ‘~o·pI¸¡yû“A†jÄÌv‹ıRÎg@Ik˜]kL´Ñ™M<N~ß¬O¯ñé†¶¤|ğ1˜/Ññ€üsGW$CjèÊgT¥G™ÆLÄL²™[:¿-0íé^Ğ
}Œ8°ü?{ãräÁf=æ®Èƒœ}c¨·t>‡xL		uUæl{?Šn²]Ô”îÈ×y%ú"(€=üsSd¡£Ea²är^f·eâ­õ™_Xöœøq„h¾fÚ1ªpÿ¦ Š±$±Ì¤¬ïï,ÿä¤Y¤±Ø[ğÅ8øçyŸôõDÀ;J¯ô7zA…<j·°¶šşÁk§›Ú“Ù´¾z¾¾cÁ‡ºüÏ’Š@çË8¡€ ŒV©aDs kaß!F÷Zûó1¾å§)èğfÊJâ?»	ºáGeÿ6wß…ñ*=ÉmÓâBÿÒ¾M=BRŒ[òP¹n2	²ÆiŠ7}Q}M0Êô”«¦n¼näØ•¯G2’’“ùpì æ‚Ì×ÓtOJauá:§‰9cc[ê’,_´,Ã†×ğÃ¥~~üâZÜˆ£Jf7pËw…Å‹ê‘v`®6ú`(4]ôZ½î}OÁg+Ë_­6ñˆĞO08ÌÕŠÔnöˆ|p²"E$ÎşšvP *0öF>ú$… ğv4ô& >³
!owÀÔ†…lÙ«…šqÏ)=6ßxÆˆ‘’'¶NíÃ0ı'k7”‰_ğ™ˆ•´ëËŸæ´GtoWÄ_4—wKo=¿ù„Ï3v¢ 6*öÇ†<cóómÆŸ,jæğ‹Sä¢*	¤$¯öm™Fxv·n¦éÏ1Aÿ#Ä<ŸÓ;øüÇ¢Şqvö©tU[©ÂÈÕGt–í¸¾‘È*ÒÛæ<±¹ÕøW36. ùmıÜÛ×\gà=èlü6é¤MS
˜sk5Îî„•,G›ÚŸovè´äjÓõ#¹ØzådOøƒ›BıË±$ı|Ÿ[÷*ˆËHÁkùDš ŸEx_~PˆœNUYõ&oUerØ2Õ=ÅÔî$±¥è@jd´Ì1wc
üİ*“uÅKMk,H^é4ô mt¨‚G ªÊº±L’º	¯†ñe¶óg„rR…ø5[K2?æ ½h±[¨&›·´].ÕÌ7j‡¹ÔCı×ê‚wbt{¡}i{4í¥(G³²IÊÎ•)RTg˜}t”ÚÖóSyçÉFZ%Æ‘²é¢¢½,])y"K~¿nP"C¶·²i±¨G/‡¾icô½ƒ£=¾ñ¨rÕ\N­Y‡an|Ê«—‘wFK³Šı
ãj4'ÜìõaïŒF:™nØ’—UµNÙ-Æf8[ÿBn6ˆ!óYÜ;P]CÃVe3Y´mÏ—* Ku|?£¨Å[øiC£Wzaª“ŠjÉIıRuÖ˜ìVØ°¶ºèaø÷ü`š{\•˜Œ #Wm]ã,ƒÑuü“¡ÅæXÎ•b{&v©
·è6Ù9'òo¶Ò¹ïÔ¥œ§ç—ª“JA‚^¦a)‡ƒŞ¡Â÷moÿ[a´ ºñ“¥—­Wáà¬iíğã—­\ì‡¼Û›ó6çF	³HWWqê–`÷Öˆw\JÇjÃ‰ÿÆßašãü`‰'R/Iøø63âE^L¶ËV?w`‚©İ'°-gÀ¥ZÜMÇ‹_F®0r=àF¢¦è¼ùŒÉ(¼‡':—æMIQ‚(İW+-‘ô3¿;¦/X—¼ÒÕÖ»Wi‘µ­ĞDCã­¹oÁ‹™9Sä™ÑåØ9íü6³1ŠèIRt`–_6ñË><Ì<¼Ùj,4bsGaÊÁÂ	ÛQøµµ€<K©üë¤5$Ø§¢ÚÜÙ÷¥´
“l:•Êİ Ê£I ¯k$6Pƒ}“#†Ù£×îäÅÇ¡m¾:FÕÄ¸eÓ„/ƒí˜WÂÚŒEA`€&¹´	{ş‡AdLGë£ÒA?Û æ‚ùN«PìÃ†ı¢Ølè‰õ¨Y[ŒúQX1Ñª«€>û¸ƒúC~1ñÚíĞuÈÈaif½-üpı°)!Üßï5ö¾LS¸,ñ÷¥9ICIo1Pnû×owi¬áÔÇ7İ· ö <ı“;xõÀg½õÊR(X,ığB,¥¾—E·mPfªPÈXã¿*_ƒL®•9¤#˜Xi~6$ÜÁàe1V¦s9…ôZ
÷=”Dkø»‡ÀÉÍ‘íË
Y
w ÎŒÉ™$ÏâB¸¤ E–ïrşä¸:àå¡š³á:¡p%ùËûw¶&Ãëï¤)›G\¢‡|¯íã¥¾üƒfÛD\¯R–@"ã"ìÀ†¼ïÓË
“¾9UfœéãwĞp!«Ñ	7h;M;õ-ĞGB•‰O}èÉXKBóè.ÆòÊôw\ƒßÄ¸ø>·¦'ºädBê;ä·¹o¹p¤ï,hĞ9¬+ép"ZNV,*™ùî4J”T€‰‘8uTš™~c¥‡¥dÈ¥ò ¯ÑV©½ósæ?mL Öó:Õ¯¹SnÓ9È¦IŒO@z±ÄÄ@K·gãúì:òæuÑ*a¹ÏšĞ×ri%òfÍ«3±;åsP,b1®‹IµÖ>ıIş)ÖØ™,ceNè" v¬O·$	íAêø5wíÚ.€‘1D1úå}VuÍÈ…ÜmxS03©Bïdj»Èİô T‰„Ë†ñ:M®`ÛÜÒı¢ŞãÉ}i.ÇÖ¿&Ï)W:Ëş%fÏ)TäxÜı«õÎ¾u+n÷o,í›5v°>aî÷J`Ï=«pêq…DÏ“Ğş W;cm£:İ
	ŞgÄ©Ÿ{Ç5‰ø;á[ ÛÉAãuƒDÈ–y{YğqjŠ¾ùh€¾Hv•™ó°¿ÅehS®ş%­•nÕ'±)éêü¥àò¿é¸µ“Ëv¯GÑU´P¾Š­£wíMİcÌˆ
ÊÉW@qe&Üáš:$Z«]õàÄ@.6ØÃ4D¢ÊRhºy~+«·„’”¥ÁDHˆ‰¤ü^&Tdîîü=–Be¯¡&1|]í™¨ÌKë
Ü8„œ„áó¶À_¼=ú7ˆè{´@¢NáÒ‹3º±*1´j^@J4B§ıxF©­E€(Ôµz Ÿ,÷ğ·Ì¶Ğ¼Æî‚R‡ƒmÚèLŸ ­Õàÿh+ñÜŠûûù íŒ_‘¿TMyù4ë¼ru…MõzÇhô4;rØ¨C§¦JŒ8ÂÇŸk”Úîñû7k&Ó>ÛõÈ®’l¥+/÷¥û”¼~ZûÓæx/AVÂ8 fÂ”f¨Cs6 ›'õ™R¯Üû]ä`DN9Ö›i+ëm´ñocÀå6màmä}ù‚~²9_|Á
¿Í'>ú‚#X•mPŠ«§.{6£hv‹ëù„çáÆ–f¿¥ƒåà—^ÇÀv¤MË%LB[m¡>t%dÅ`ÿ…ì¢e	¶Z\XøêÛá"ûIÇÉ¸A‰ÿ¸F–}9­ƒ1¸­5…à¥ºİ‚Ï*±¤b«+ÇR=-³ÜÈFijÄáSn‹œeÁŸªöô÷ÛîÕö–ŠªR¡Ô1Ip!•C†„Y j´UN€E·¹‘iÔ‹PwE8ë9æDÀ[qNéÖ˜ ¯V:Jå&© œ§?åŞrpH%pÇ¬@âEÖj´/
êëYûğiêšhõ"Àş}'ƒL1w)iÜı¦0ô#»6Ç]#Fdeg:ìÏ\ÃŞ¬¹EÌëúC	µBøeë³ã-ê—Ş¦B­ı,KËxµdFn¹;X°T°€ú*rñL]ØzGŸ){´g¡ÁØÃQşÕ‰$±.à€ÉB.ûî’Wå¨I½1¸å–±]‚]I7\õ8}	¬i5"Íf?Ó?§^‡W=„m¤Öc“b’ˆ½]pÉvxgNû†EÀy®d1Ş¢?T„+ë9(Ï±j%rææ[Ò<jq^ßÄG4sDÿc¤§îš½Â¸,éãØzV7Êğ~p,îd?bÇqö	 ³´™Ü‡(¦ÆÓàùKğ”›[ËòDÜ¦È–ús3°cÿÅ%
*4&à§­P›ò«ÆVß	'‚\´PõÜÚíÙöÀ1°´?ÉkB‘…{â]GF ÉÚê|·ÃÎ9Õ7…³tÊ½bÕ-uå÷7×p_f­±E×ëöxÌ]½È+İŠ
YHV¿.ËV4*#¡¿ÏºUø»K"\w½D Ü,YJ"ú)²éÕltKûöñßÎ¥/£sÕ™‹³q	SrTš4ã¶İˆFµì°y$I+÷Ì®æ[’~”ºp†z~ı…-Ã5G© ÜAŸîÔšÓ;í3:Ü³,-ªÃİ¢	>éÿÙoÜÓPÂÚ İËa‘¿æÌ¿À¨Ú?£È&:Ÿ.j¨¯Ÿz/|0çÏîY¸lRŒqìNhÎ™`MmıÎtä¾¼Œ†÷ü»ä8Î¨6åôš	Q)ÆÛ³e}ÇqmXoúem¿L-SÙré"G¼Rwn­½¢¸n¹ıb¤}’àĞMÍMÂXQÛê`'ëWfŠån	ğÄsÍ´¾ÔyOX6‰qŸûé$ä¿¬0<¤Áy7y´ĞÖîÄÃ m®!<Ün?Ğk…•£‚ÚŸ®ˆÆ^Ô§XZUÃ'D·–ù›5U'6Î¿˜2)²s|UvjI¯o^×fû…¶ÜôRıÀHé(-p5^´ÀåõA	ø“6öÔ?ÿµÁšÁ»Eõ_ç¤yˆ}zº›¦!vS³tÿ©÷É¾	
\5ğ™¶O¾¶n[;±GSÌÑdÆ‹¸Dì­\ã¤Òc&S$9ğª¹Êñ²?ßØüeÜt$€wJå['j _'@°± ‰1ÛÏ…ëŸ%vÔÒ´-!{#ù&*#ml¯z\®+*}páQ*Ÿ~¬K œz¥Ûƒ¦6ôú¢ˆ»°òPŞuò][ “ğ\KA•RP¯5½¾)È‡ÍÆ…b¹©r&AÆñ\D¤k
8‹-‹´¼WŞŞ& çõ-+\¾{
gĞ†½şÊôZó´÷HòÜ±ç³ZÃ)ìŒtÈ$ŞŠ< m¹Å™¦l¤-ò›Æ¡„VK–F=©o\Á„¹%Ì\’ßÕEânL{,°áˆ¤ÇéåÙ¹%º“ ´ì•Şwø•×Û€ô–If½:ĞEëÍÃç¸èÎ¼Œü'ö…É5k¼zş½bø&·j/ 2sÔâ©Í|+ÎŠYßBæõú¨^‚°=9Xâ#¨—Å!rÍÏìÿCT}¯ÿœz·wâ(¬‰¨Q7Ç±S¨ÌÕ”æÕ‘¾Q÷rWè^]ùÖ’‘œ.t\F	ú,¼àÓ*ßuVC0\ãô†ae•*–‚_kŞ(¤DÕƒcÃlğ{’g·KÒ{Ü»s³,÷;Œ>ÿçÕŠ4Â’´W[²¬b†·Jf©™ñ iûCñ­Ì{ÿk«*K÷|—Eª½$Òr ‰çÌ3‰ì’†DŞ¡µ†n7LqO+~ådüĞ¯™	ÑìwéÇ§7Ê€Å¡ÊÂ$V ‘n‡ªí~ˆB¢ä_ÿ0–éqÂà˜Ì¥ÆÑÓb)Ğ‚õÎ{H G9­ÚÊ‘ëwÇÍ1±SOæ<ZcæÁ6`5¸z‹ºFó‚‰éxT£7O<àÿ”F¦¥ïÁÿÄš ıg´Kkõ6£p¤K0[—ªLê‚ôt¡ëÜÆş^×Ó10ãÛñb›÷¼ö,–¼ô*²şèÌçÊ»¥>JgÆ\’1Ôtä¿+/X3¨_Em5ôxğÆºóêW¨
w³W
vwg÷yÂëfÊ®ÖÄ¼?Lr¸¦ÜÂpMœóCWß×4éhãmùĞòxBH)ÊneîKhAøÒÇ•½Oü3+ÏÓ]1<+­¾`¿»À”i‘ªiÆ•¬Q°®Ïúî|ëVJÚx  ¡-+şS‚Uá<œşİæd*é›C :ËF|EÜ¼!mºz^YQHá¹ô:!Ã ÌlvSaÔø¢$< Òpé)¼é ò›ª4gmxå’1álğ1‚ÅSÃR¦­¹—|ù©SdZ’%fqö3ÅÈ	úq¾)[X;ŠûÔÁ×·…%"ãIŒ|Ù½?šóASp®”ü÷‹›”ß’¢H~gÃš~gªf¨İº5» ÀÆYtíØ~P¶È™bppÆ©´ç©ÔùÔ¿µÈH­ÿŞCöÑ¸V•ìi3Ä‘›ğ¿Ò{	%#>f/ÿn{L@Eğ¸—N‹7“aÓ‘™y Z¡('¢ö-Á{²š`ocEÀñ6Ş›¼sıE‰gA+mÒ]ÇÏª’oÚ^<ÃÈgÄññ<Õ|‰œd³ww3}6ùğš±âÆ€TIš»”œãà™øb†‰^Â£å©a ªî-È™t¦/P–yv*kQ¤É¿ğ…øOĞ{°o‡h?€@W£í¡æH$Î]Óš¿kcjÛÃRÆŒ® q.k™mà˜‘[(¾şnÌ½3Û8ÌÔwÃ°|›íÊÛä2@°j‰Añûò›zrHÙÄ›|…ñ’ã«ñPÕ?ª‹Ş½»‚¤¾kúLŠÅtÎIÚòˆg6M‡‚y¾ÔÒh6ÚlQ==2SÉÅqåkh’œ²`Šê@ttt×ÔPÍrØ*ùS•ˆ}‹ÛsÁ£Ì¾=	“Á¿¸â@`tõ²aÿÍñk2=;ÒWÔÿ‡1HöÄ&Ö©æ¬Í³€s)Æêš O;\º›ä«o»B†Ò1=²Ò!´(A‹!šD×ÿÏÄì(Hgİ^ŒgE¾*åeÁ^©—ÛdC“‰)_ÌÑK$4‹ÚÅİ˜6làé/ÁP·b]@luIšmºÓP¬®ˆî7š	up?Öj­£…ÏRÊÓAñbwÏâ‡·¼b%åS¿É/ÕÕ6*G1M‚$‹%œŸVPÓÃ‚Åâ[Àıãö‡ŸæM˜ãÿŠç‘…˜œí¯}’oº›Ëe6>›{A
>Ÿ†ğÛ3ÿ¦1rÕâ÷¸¥(l!RßE6Rç=äúy­©_;ØŞdNn0`qfÄ¬%XáXdî`¬"Q‚C¶³¤½•W±2„0v®Y”ÁÃ -`>IïŞêÖ6ËdÍk×ÍĞzwóšÛxT&[b”–|ÿNêv'GŸá)'ÏG
_]£6¡‡øw™õã×^@ÙÃ ‹• ·B	Åõï¼'F|9õƒdr>„¼šKºÄ *@wßE¿VímQ¿	Û(‚¥ûGnq{ßºËÇJów[u¹Ï§,D-5?Ÿ(œ+ñJØ½ˆ'ìt (ï”EV7oíDtóÀœ¼¾›‘ûÇÒbâ~ştÄ6®İÓã<÷øxBÙôDñõ•ÄŠâ%üæâäá3±.ßWeº”_¯È¶¾HŸ]>å%ıƒ;%Ÿ
®^­E~ÏİUÉ=ÚÛ “öË*oä ½ûZ¥ñj§§&ô*=6DQY …+²¢hÕ‹Y8Š<×G^YŸH”ê‚9¥^=õgOÀî^t„¹ØùÊ2g/)âèî|çÇé.'Âï 2oŠ#éÁJ_ÏsØ)UªµÓyRÌIw—ïœÃÁeR7Ê¯sîYPù¥Ø í|`‘êndèVR¯ÎÅ³‘ğ¢8V[I¦½j§õoÛöPuÌmÀT;8ô/Ñg+›ì•»3ÂˆÍ–…H'¢Ú&µøá	©³4u*ÕRË&·ßC.n ùi€PôÓaöÃr©ø_	šÀ‹Õ‹ôRš
+,¬´áfÔ¹Bôæ´öšàgŞÁyPo?3wöSã‹5ªQ
]ù DÕáäËU×<M7ƒ±ŒLˆs;ŠuÔ ¶pŠšÔU÷ï»~¯Wa_ë$™zÜàb³»\œ°2\ãd.ˆˆ+‘z˜#4¿Ş²‹.‹}ùcET2¿ºP‘½Ø~ÜÓ×X|ò…K!P!SÈ­Á h¯pç’Ä9ÖšÇ+[A¡oèä¼	œæéÉcÜÙ×àÂK†¤	ÆV«İšŞ…\dÆ+LGr Ï@R†'™>IÃf»ü~ˆfW÷mNÍaLå³]jR6À*Du nxí¼¯rg5—W Â¿y=@7+hw-ÚoYkĞ_tX|Bİ·|;-£©?²ZnuÓø­ê(o\ 0ğ•CÎØE€ˆSçO0şvñ	N1™À÷j‹R+À.PÍúkûœ•«5)jÚ~£g¾züO%lx¯Ó÷bw%‚a¾;”¡9ñ]S”†SöYÒp°±ˆ÷~_Û>ıõÌh`ÖÂüb+)ãÍ¿£¸ø‚ätçd%òTœsß7ò®X$ÂHÇMJ)x¤•©ï4kÔ¦ÛØpîÄ9±P½¹c*ÏÖke¥Bzõ1$äÁ±ÿÁÆGİ¼ãƒÒWe¼c¼¯%bîe\?¥*Œ¿GAl«¡|ÚˆD{íô¤ôTD`è´+Í>ÏÚ9~T^¦n
t=Dq¤INyÛŠ’ ?'ÚüÕÜ* g3T1RËûÓi"¿eùñĞÔ”9yî·/á³‹âYì[R¯|ÌHùªò®‘.–RUJzwıÏO+Gÿnş€#¢:h¤?íÿ],ºëÕÿîÚÖyÄqunİá¯ô+ŸÀÒó›$ÿŸ¢xDŒSÓô¯L(‚!É‰]O›"ÇjìÇÉ[xŒAƒEö½<K¼ï¼)êXÜ¶¼Ò·òÓÈƒlñ>ix¤$º«b1ªa¦˜p±Ìˆ[=h‡8ºëªÑ‘7¢É{ª@ÿ-·‰¼Û}„ÌlÕ$MÎ>İF­´jç»™«Ğ]”us[I.gÍNÌ	Tj…Jà]ÿ–Ùaw,xœ»@l©•™	îÍû)19b[áå™zÔ?ÂSÁÂOY`ârâxA)AnVódˆYS³%AõÅÌybÔÙ¸ç_BœynG^T÷v§P/O¿ğÉo©ja¼|îÁeP4Ûíinœ[¡-î²–RÜñ¥ıøCÖë*HN¬¨òìiˆ§6yN.'(J‡q“Bø-Ñ0q;ôRì$Şä$‚¢;Ïâ‹Ÿ¶å‡ÚÀ|’pO¥T™1,”Å.^L x¶s°g¶÷<D@}ÙB«ì‡eŞß.ÄƒµÎM$rü- 
dT¯Òk‰b	ø\)¡Và?' ¸¶Á(à«Üå\äshõË¶Ä¨ VjÄq&¼5´ˆûE‰9\A†Ÿ 3½
•¡V{~®9iì U/“éq8ñøÖü2ğ9×%Xæ´÷a3ê¶ºö’w‡±Ë
á°Q›Å5ƒˆ/¯qÙŞS4Q#_ê²“¹4¯?äP¨s‡Û@2wbºBı0Ú“xFvÂ´<8bÈk˜ûvl¼óØÌXï[^µK±A.xXšºõ3òA“w``&¸SQ"'qÊ®…/ÛÁZK$oe†BóGâ¥ƒ§r*\°26‚C¸æŞw2pÜE%$°Áx$Ìå^ÙYL¶âİØ˜9çÜL’9eËñuÔ˜`+ÈÒà#—×k³Ã ÎU¹ ³ë/áHÂMT~.È°±ò¢ ?§#m¿Ğ&›¸”_c
÷ÉüÖ+Ú«ç6v¢ñ+ ôùøú…—9MÇMhlÏ$7è¯¹R¿ıñR)òxî½:C!GªÈ´…… ªŒ
ûµNóx\U»¾‚]N©]eWö	 ÒÊÇÑ)İHÅåPÅnNêŠ?ìÅ=röœø°«<bE†VïµÏÏ…ç ğ€¡’pvÜ°6~,vêÌ•ïóú€şÍe+5/ô¡ÇKq‚“İèÌn¢Ùa÷„ó2å_›ëg@6 K“`[ŸwÒüñGÓ•<—\›ùİº‰²ëJù3ÑU³•5s¡‹7Ê‹bAu®s7´7÷ŸvÛI²Ÿìk:µ'¬Iê!×L¯±_n_¼D<À½yI€à]–‰*3ş.Aõqg-HNT‚Tá¾EK”ûLŸ ø!›%åPšø!Ûè‹Ù
ùÆ³¢ñ!Ó‚ó™3bU`&_yzİMF]Nª=œ ±7qK!­“[å& õß3ù4îc»ªØäJ*ÎÃZÂ¹­–Ã¹™™”MMBóæaÓ÷cÛE|Ud±e…T-T°’yŒ„Oéƒ\?
æÿœzÉíoˆ9„'ŒõìòT÷”½Î1(,N-œŠ·š3aÖ‹{ĞÒÅ‚‹ğù¼æ4t¼p–Í0Aè	üÔÖäÄ![–ò“İ¸–™1ËÏ"ÆO¼èÇC;]+*8Ôÿìc±l<'‚_Î^.×~}Ş~ùÙlîrÚÕ¦4"ò §&İ\AZÊ¶¯ªïÃ¹}q§¡F	ï¬®O „µ]ë¥è°|Uù/Ã%ğmyÔ]Ã0Ä»^YŠrÛ7W^åÔ´ hUYj»„Õ•ùr®xÁ+Ix™Å$dlrş)ìco]É¹à™1t¤ü×z°¬§˜\÷NµÜæ¦dDŞŠ`:¢vÙ­A çï°ÜQwgXß¨$5*ñÓÈŞ±¹C¦êÒQA7Æ§d¹¦-º¥N"3à ÉÂší¢ô»£ª¯ªPõÏ²ÂôªçËˆuŠœ¹xô5Î’‹>u!Sé*Rê™@+zºŸü(Ìe¥ú)C£é0õ^9ÎRd·¯Î”‡ƒñÜUo?6/ØûêŠÚá
ÌÄy{Ø:Jà±Uwhä·İ¢´lQçæöã={—¶Ñ„iÇYnÍ‹ÂC¼;W-,&B÷ö³RQ×V5m#oÉG-wÖjÎ²»Os(†92›Å*ª9Üõ§×vÀ¡™õĞè(o¾>~"àÆaØN2–ajYáùäîÎç ±—øPÙ·Iú0ú¸‹ãƒa ÁãOú¥‚yÿ<œy³º|y²ÌçÃŸ’Hò©ÈDô«îædnu1ˆ¥Äµ?gµ5¼]3 bÙbäÛò"6ùÈ^Z>Í£şğÎ•ßi…ùşœB½Œœ9bÀyæôÉ7«¸ät6B`ØZ8ô½ÑN—:„ä(.¢t2E4]NsBÉP“-nf7RGá¦ï9~‰eävH¹k'|ıÙ¡ïxÓ	$ˆhWéàÏhv¯ßÍ.ˆ—ZUlüâ¹Y;P—	Ş'‚n;ŒïÅÓNø?¼ˆb‰©Y‡Ñ•}½¹•X˜³àƒgMÔÃ‚r¯Îaâ®5ª2¿ÊeÑ'¾)lÓÅU	N“+°Wø‹´%j½œVQØªìQ4‹óÏUØÔeæpva¢üÙø¬Ç/¨Ç¾ÿ~¶½9†VfOB<ªÂA¬ïÈÿîiÁUµ±ûÒ1ıïW€o«ª‘~F˜¡\·l·w#÷î*ó[§Nk!(W˜RÂqâÔ½^g’ÈcŒn)ìÂKÀãüÖ5{‹ª¹0ØTªü2å°’}YÍ¸àG`ñÇ×ZhY~¨H‘*’ÍÄ<´RÍ( %0FFò…‘Õå¸îÌ¨%—§6ñ•È»snXXÀÎï¶ag~×pPñˆ}M[¹	\AİO`RyDŠòïÔäh…/Që.X™@XF¥Døb˜*+W‡Q]ÛR?`~H2ÿM{‡ ï¯êŞR´FªäYc^*ZÑµ?pÂÀGNlÁP¯QEò·ÛÂËf?ÁZÀ>WyÚ(²Ê=’S1<uXò1şA.p=ï‰[%V¯ˆ
s>üx©¢Èrß­$àí¢‡˜¤¦ óÜL•.G$…õ@jàS4ÚÀXüE¬t¯Ô9ğ×ûËI¿{‡ZIÓŞ·RÕO‡k!½[“ªµ»Ú®Èc+´şv/&#ÿF7©Y*•;S^¡7y­ìt´«hÒ¥HÆùg>`‹:@JŠıÔ©I`c:è’¦û«Ö»ÏÖ€t:àPû#Ä$C3,åh‘3ÔÊwÓQµò$:ğ'Êß‘tÛû
º×ø!ÄÂËFôT¹C‘¸'û/=Å9Ô„š	­üî0{Z.kp©ÓeˆExWğËìˆ€¹N‚úc¦ƒnãhÌ»ÃÍîäëqK¢§Z^@†n€Œ0xÔ=¡¸±‚N¼AxÓ7•6©zÎ˜¼ÔZVêóZ$Á>üøJ÷f:px¶rûBç^J¶]Qek…>Lç†À¿†¼ywZrúz©Œ¾ÄÅg_(%:iœOÙÖn°½bãèOÏ¿êÃ¼²¿ˆÄ0ÅWpôéò|Ñâ3d¼>¶Ó’ûmŒ>)BşZMXâÑ«cI²r1šXì(¬:‡Ù™Ş¤äIQ~zaš¯’Â˜(&dñB!_Qè‚Ûq)5y¤ş-7 †ÀqF”fŠ@š¾ \Ó!¬Ìé-	ù'+Ëãb	ÒzÌEaV‚[Ò'w— Áhu\ä™  Y‡^ÔœVW{êèŸÑ#*z<ğZÏØÖóX¯|$Rk¨Kõx„æy…ƒMŠI*î¬ÃƒAî	,k'®½®B®{§ˆq@)[ñ"•­À®„’ÚQ%÷DéË Ü§Á­G“ŒOM^FŒsg
8Æt¦Œéy!XShĞC„ĞûøíèîøÊ÷ó‰O2QGÆ®)Ğî¶'N6æ•«Vï¿Íhâ›’…Ÿ.R£amqc
Rqáş>[D}K¢Ÿîè€b71î3L<®Óó¡¢…ôúş¢ëTÓÊ·šùï&osg¼F¼Uj}}+'é”YÂÍ
%»å•F0fûgk/umìÊVŒË#èıs+õ.#Ñ'¢(°ÙÅf—jß¨@i!™§…û®_ã;«)ß(&	x¸eÔ*Š- !œõ)`B.|õ;¦¦eûSĞŒgä	nå@å\–P[ÖNÓEnmN=¶<`ÔĞA:,Oš$^ÇWå4¼²ûê>’ºy¼
p­V"†DÌ­¦Ï«é•–ÚŒo[İü«l_Ñ¨ĞdŠ#vŠ;t§üÎ¹ñ+U.şö§w1ù~ÓÑµüOŸÊãÂLKY‰‘âxtReCı&µímˆ¯©‘­ w
´ëœÂ§ù«¶_ŞeK¡WµHÌ0Vs˜2–ôå}µ©}$zoşÙ/7Cø(5áEÛ}¤ì`ØÑQÍ ÊÒÜ$Í#¦ò£NRAB¿‰Ÿ(“)IïáaUÆúDl€o—Np;l\ÄWMNıeÛyíÔcQfæØ ı©ìlŸ™KZ$ÙûJq7şœ“}C7¯VÉø5³K¤»êâd–Íªê@DŞ<Oyhv-í¶$K¢•Q:"!üĞKøÓ„]ªÿ*
ºÇ#£÷ZÓã’i¾”·Ô…«ÚÄê>ş³àsPµuÑ¢_nl…ØÈÅXû×\Jø2´ä-a9¸«[nÑŸ1…«”­õ™›ÖÃ3h]QıaÙˆŒ#QÄt‹ÓÒ”t¹¡,føãºL¡°Ã8©â7ú÷¤gåãåòáÊ¼³mé¬CÙ‹×~K.k¯ˆ¡^H_÷c]Gè#À?3º |Tt¡8¤9M›|ßHl—X)åë†¤óŞDCF¬ı,Ñœe'ä¨ü‰„°Š"ä’lşî›Ò.ä?7°KrD¸±jHFNq›ºš!!uöJ…|DR.N€ôaqGÜ¢¶.½tµX¿Lw—BŒG¨3ÌÎfà>^8”Còšİ•!\ŠX’ÎIq¥1» Q²Éê&»QA‰Ì)Zæåà¼ËÁK™;º7œP·o6eàå=×\µw*UCñßÓ`c™±)Ùæ}ŞÈŠ€Y˜wAÖçû»ÉL²©}€‚–ú*—É±$à3« ½ØéY´,«	Ïz7+—?áÉgDïéÕşÑ;ÄİšoAÍeM0-¸kÏd©¤)Êç;UŸõæM‘GĞqÛM:O¢1‚b¶X@:G_Š—‹¾Çµo²²âW<+pÒ›ªã¥å)HËzêé«ª±1®A*¼eHP¼[ara“¨a«NÀ»^Ñ}{
§xÓ'*ŒÍ³JÒ[é9Cö:+¯v•'4v!*›ñ»Ce£b—¾Ç%”Z„ïÍƒí=ì‡¼È”½ä¢È œ›èŞG1ó'7àr¡†Íu¿w±3¾Îœ§Ã9õDØc³ì¸ıq°¶²G²& ¼4şß¸KÄAî˜F{$
uø¡4!(¡(ô¯Uåú?o¿øúxÚœÕÜ=	ìdÉğ¡†BÿMWYÛX˜¨úeõAÌª‚Ä¾ÀıŞrPœÂøÛëË®aËLhµ.nÏ,AË’G¦9BHO…s²'Wrµ×/1	Ñ´)›onÈè‘£—>o¸©RY¦ßÂCdïX—uâCCs3Ào¾I‡>YV¤è¤_ƒ¦’a6 çÎ09’óß¥€ã1-ä!c ÙZŠŒ¯ûyu2‹½æPá¶èA+ãP}M²Neu¬¢êğŞ€¯«‰·ƒ/²‘5p7ßfölê¯“5â=&àR=I‡Å_Nªõ×ò³U”M°½«5ÀÑwé2"nC„¿Ò™ yNÈ²F9p”¨B®£9>öÔÅŞîª¦#‰£z|ƒ½&†W@LÀV·ïPéÓ%pí‘âë¾s–JR{Œ€6Lt†µÕ“Büõâ%fÎÍ£¢VDï'Ò\£ş¨,‘×%5“F U¹qÊ÷î’êùîõµ +m^¿]U¯ÃÃYôÚÔøö-Y	Í˜S>¿óÖæv©©S­"â‹IÇ3Í|’îÉ±GKyqÓÜÌ–…•Z34ºÙ|‚.æ¨˜üÃ¬7ÖoŠ÷9~hŞU»âY§hG°ïşUÎîÃs üíJø(8·Ë"«6ÉŒÉ®ö b÷†˜ŠÌúª"/Ò÷(›•Jw7N¢[rÎ–µµ(Ó·®<í7¢NR
‚|:aäıSãş_aù”áãP†S]w#¸³>b¯Å$WÖc¸²˜Šâ•(I¯Ó+à;ì½à#@ÔêxÛâVãüëİYr$š6v¼sZeØEln	úH»42mPî†½Š´³ÉìBMÇÃølK;d§D7<1.KÃxb>ø]†õ¼)»¡pöDr° ÛíÛğıwX’üq¡MÈai'^eZÉÄYÊëšQÇ}9#é§‚şÀæZ{nÎC£Ÿ[ÉV?¹®‡'æ<’­«K	Q$ÚO¶¸`d–µİ1nú™êW6 ñâ´1…²•
F‚1ã¦æ>İjíåo0$"æêYêÖ[Íœ¢üW"˜½ñ\† ¡ÚBTjèÊN œ¹€ÀˆV1¸±Ägû    YZ