#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3636277470"
MD5="2d88448cb918336f5d17d0e0e5e733ce"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22976"
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
	echo Date of packaging: Tue Jun 22 21:37:19 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿY}] ¼}•À1Dd]‡Á›PætİDñr…8jYGË0¿BZSíh¨@Wy|©Û<%ûğ;Å¶TàÑOÓ­¿Ö~ïğTíª ÁøÓ¾GÅ™XvDªsG7 úç«³b‚‚ª\åƒãÇ–iµ¾.B™ÑêM÷QA0à’Rñ\>ƒùQ{eç§à7ùØ´[•¨“ñïŠëVµánRƒ¾uürX™”Y®ºèEÿrE‘{ºëÔ¦;¦)T[ÇÅQ`Û‰Ç^Ö
éµGŒX¦a}‚ûä[Fí±g›‹”¿¨ıçEÀ`]»Œ]Ÿ³˜l;¾‚¾]ô¿u8ìcOÌx¥!ÇİoæÒ
ûQöU,|ÔBïé|<uñ÷$FÛæ¥u ®zRÛéLb²ÕH{NÑNd‚ÎÀµTC¬¥ûî¶>ï‰`:ºTvÚ˜úG¸Vò+bFÛÂÏtMãøè\3àn#.}¼÷9&ĞƒhÊÅöŸnnìSšIœÑ:Õ/f)Îy"%¸>?.áE¨¯=îƒJùRCÃ„İçH±µ$È‹<ê5şâÙÏ<›»Û¼ìî¸şÓı|Õœ’
Ö¨?‡ù(à›Rşn	ÙÕwŠÇT»_JÌƒ¸U&!.¦”xF*Î#ëäÔ%'’Æ Üwp0xí©¯É…k9Èë9ô#ÓõQĞšZ‘/©VjKE@îú¹V½Ï‰[o¹OĞÁÇá;\¹Ç33à:}KiçVhU&fÀhÑß@SxSgº¼åX~,„³Ä{¥ -/”­«n²TË©ºtø
{f…EĞ‰s;îš
A¯ì/xÊÃÕpû[ÏQJE.E{f—€oF}zş"Ú.jkßRõªğ˜"û)Ì^±5³¦¼3æ¤èïc
„ RrB©qïøä¹kvD¤¦i7»xë¤ìY3ß{Z¬˜É0¨Ô`ˆïä¥fpu	ç e&Ù§¤OÁ°G•]òíù‹äuG&.õ^,”ˆquP»šÏT4TßÚq®Çóí3™!xèöbKB²‹Ç˜Í á½27"?„ FwÍŸx¤õp#®£¿.Ç¶mx^wıo|%„ğ>IéX/Q÷.+GX,Ë¾F=Í
),aœÊĞyËR L÷Ì•tèz‚6ˆéŒŠj"öÎK¬×q"'?|^0ºáhàÄèëNóøÏC	j.š„4qÎX¬Çµ4a¼ùšø‚²c"gÙ·ı÷} I\F˜a Ú¤¿ˆãâÁÃpÑ”	¶tÅf5ShôQ=æËËáÜ<èWQÊCĞ™T0G4Èyíq¯;ufò_Şè3 ]Ñ
_²Ñ®MÓkIØzCN®Uh—­µÒ©®!»`Øf•™éèÇôtöÅá¹ÉC!èòK°¿AÊ
ĞX“øQm»Mwc±:xp\4´m¶ßhÂÓ¦ú£R€Rª.>bË>lÊ– ó¯ˆ+”4DÜ= _5QIµ`‚™ëbvdÈ]î75ÿF]¡Ìİ}®ø™şĞ[š½ÔÙmĞİ¡Î¡e¢ºÂ‰/X–Z*ÚXÂni±¬†Ì"«qĞ0ÉNŞÎõÖVğUØP;*ïH·Ã9ËÅçıX&FÏYxt„³.”©ÑÒf¯»zü„ÆId¿}®ñ7x3bò… Øàïuf)VÍrôÊe	)Ş‰}z>®ÜH³äu»ìÄÁìÙ+ò}aó>Œ^ÚüI¸&tÎ‰q²§é€	Ëi,<šÉ¬{™ŠXZ'	-<›¼0c9°ïö¹ šjÖbZK7ğ³`uJC«`6n9ñm¨¦|½ê”p^CH‚éP_ã—Æ¸Çeğ¤è¤O·Xëi±7‘yéËÆ.«a´²BÅ%VìÊRÈ
ëBŒ¶P>®ûÜ4ğèÖûöóC’xKRÿØ3Åñ>ÑUIêš
"Àòb$;m8†Oİ!r¾£¦j˜ÙÖ¿gè’N,bıäÂƒ?õt§ı³˜ğ*ë—_óâ¢=©)ê½êÜuÖ•¥0S:.È¸.0:áâB¦Œ¼	øàD¯¬º:3½8‚¶ly«Pø'ÆıŞ±Jåo8´<Øá:T°‰êSÇ&:ÚJD„F¦¿s5·¥åËŒVÂA©²‚m£UbB?&í·»Å^k4i@R )}G¾ñ£h1°’/yÌj¡[Nƒ±¹¢NûƒbÔ³”ü½ë>ƒúæmzö+CæMˆ˜tgÇ‡3ÄHzàê[Ğş,şM»@–+Gg # 2 Ã;Ğãj¯;©¡Bóí8Ø^J|êçób†{¨›¯çGÕoßmŒ@›ÃH!%i1Í]ûøOÓäIÕ™Lcı?£‹U–§4ÖfMÕÒlgÒÎÓxiq*ÄÎÔŸCgT|]Ö.¶É @ÏÕÒ–á¹l¸[°·½,¶Z;&C¿°Ç!û/e¸Sİà¦Di¡®VøÃ50°P}Fz­áò7éÊú4c„89ÀıÏóß§Ñ¶m‹ù¥*š49Í6ªémNØ¾¸	õ)‡–8¾±Õh–(5òÎT'6ÙŸGÅ] .³ƒŞSßä=ìèéiBÎò#“*²mo9h>TJ™ÿ2l©{<Æ+9sËŠ¸N!¤¡?q`?‡TCš^>ôşr’+©O”çli¸T{gH
5CúÌlYšäÖŸ=b5Ì[¾.JcÒÃsfp]¢\ÖD)aœÓÏh©,Ş ‘ÄĞ«Ì^>f71	Â	ÁgYÓî±´bó¢U:ŸÀyîU¡GV‚ÿ‚~+.¾J‡BÖ7òÉÒ>W¦QñyV$Ö½^¯Ìç8#€3 'WÉ†d¤ÂË*Ã“÷Ö=<šü|)P•‚©Ê¸:€\fıº©JóB%ú†p*ù*+Ù6d‡îĞOJâ¶ßğ¤uÏBáşYPw¹ĞÖ'6ü5³‚·Íù¹#B…W%3°ıÛçO”]ŒêÑŠøµ®)]ä)@ÊÌªfr¼Â¹Û‹ÿÔv]äåÓjfõşU—îàÍ9fÓ‡²°‡t"[l«h-˜ºäÅ7R©ÙAû¬Úû¨¢r"“$Yğµò>Bs°óëtgõœ:‚Bi#>·)£÷‚<—™Zº—öG7åÆtác©Y6xå˜®÷r)ƒ²û/7;k¥Øû"¿$·™ gF•£Ú!O­Œ´‘]Še9‚ Å±ıaİs7=Ê6—ãiÁ|×ÖÉ
Ü¿63°ßÖ_#Y±V<sAÆ°æÖ'Ë†'
ƒ¢	+ÔË—U²—İzç\'æ^VûJ+Zl%H¼.*à$FÂ2à˜¹QHµÛlOß›¤—ÄãQs3]²´?íÁZ³öæ î±æ½`¾!|ÇÙ%ì Ü$`Ÿå çå7.şIÇ3¬×Sc¥àiƒV››J6ƒ3˜d´ç™S¸k¢C¨|çv5éjÉõõ\yøı-H¦jübÓHk£°WÌ¼Õ²î5ÿÓ[B`ÚœÅ¯ƒàñ
DÿziĞDĞ¯MY¶„>íRz¯›?¶¿—¸¢Èè„JŸ‹ùşkz³³+ß8J®@Ğ*$¨zÂåñâz½@4şoEÚü¾¤$~.ÙI›B}Äbî"¬¸ûl*Ã>/ÓwiÅáBm©€Ÿì²Ì)L'›VŞè`œ‘ò2¹oÑÊİ¦}ÍV¶Ø->•J?'w}y”–3K„'T¸›•iAÊr7Í‹İWµùÉ[’&q¿o£*÷± ±iÆ'‰édmDÿhœÉ“Št¯9÷€6; ˆİw«‘øıëæ¸^Õ4àÕ»“ÜÇ‘ó”ÚsyG¿@oş1¾ï!iæ:ë6}8	ƒü ö‘ku'Áà‡JüÍàp@ØğìğÊÚì#ö‹¢bü–ÂÛÿˆ¯õL/§›Éõe»±‹|–‡uA*Ù€Óªá,’ãĞ¨Hr+Gß÷ÿéµR¢û7¼Æhxdğ
³ö|³Å'¹	M÷D#••DÑ}VoH~ÑQ ÏD¹‡§òìaS´vï,¢MÇáêN×2£¨‚
ÖR@¾”Bµ÷d-Øy—n°JÃj~]rô‰Şmüç·™!ÊCÁ?{±b9¸%QtıËqB¥õsÚ+w×NÀùÕË#JSKû|X’M$Rµq:²ñ!”[÷®?Éqç‹ŸVĞ
B3’RŠI­;íIÓÿú´á¿xkRƒ¤Q¹2°m~¸ @ê‘wë&z¤E\—qÆX}î/N&ıå¼ôM¬½2ÄOc'º¶Òì‚Ç¡Şİh>˜)(üìøeË.|Ïqê´¯!H0 ´³_eŞÜDşÇZ)DD-êVğÅÙZ¤.°¿+îûıiå[‰d®iÙ¿ÈbÿÕ aµ’Z™l‘Bq”vÅ­J;?kXÕ›§ŠÏI›ño8+ík“ë7|	/V&x‡é8Á{¿ºº?¡Ü#~\àdBÑ§óÂÄøŒwF¤A+qyş³Ø&2_î#q¦‡ßypä¡ò`½íª¯OıZĞ›b³SÇø^ÿÉoiÒƒõs!Õ$WWO8Z+
àÙá™‚¯`ÊÍ¡İß5R)_É°,‚c ëš¸öÔ‘®SqXT¦ršú_GF¡$w‹zpÕå00GLCG1ò›*œº	(:èÒ–VzWj-àDgí$Gh{8[BvW{ñé³3w¼Î}âeNj¶<İôºûÌ—¡Qp€ËkÈ~` ZÛQ €Ç!AKWçê×‚\ÆÜæXV3È…@†,jê„2"Œvğ@ÌzÙá/»ÏãgJj¹xïK" Q¼>ša*Ì4)U—ĞgÁ^<êHøş××Á{»‘L´ •L'Â[;Ë87}©A›O>£$9‘¾c«#Û–˜\´† ’94Ûõ<EûFtŒ4%¾~ĞÌå’èªwİ§-—w£qŒiÑÿÖíuxİïóC‘áèI¯^‚œh£JhoiWÙİ²atñaip¿‚‹3ÆÇ~{^{)ÿÕ¦ï»Ô“yñ“°=Ê?,€eÀ¥_"ƒ ’±¼í	)<ÃÇÒ~oØ8_ûxÑ—úğ->.aXq³ ĞšjSçq1„ì5K•YG"Ñû{Eæc2æ˜À7B¯íÇ´BK')H¾õaÏ¤s%éD¿g™_X%%Ñ¿ğgwÍÄD×¡ ë>º­Ãääš² Ç/RıŞ”"ŸûàvÊT‡ÿİå{gø§‹®›ip´.“ª¶{$;w‹«l€"yÕ<È×»‡¯)Î©û9ïnÛÛ*é7˜9@æ÷FîmH/’Ã>o²ÂPÚ¢»‘Mwú§ı{9v7…©gEŸÊk](!.óqEox_Uò@xî†fƒ›ƒèNJ;á»+îĞxnëê-¡05XÂÖAx‰º¿\ñÙT´2 «Ü4çeÓÖı“R«=Sñşr;õ¯ïÿ5e^¾ê.¹È@Œ÷„»k­¾×-8I}¡/äÍÙt7mÀzû2dÉß—¡UöÒÑNï‘¶šÉk:e_´·aJÀµÙ ş&EcİHÌ°Û6÷ÚåÍÅå5ßvNÄB¯Éâo¥u‘5­î…±•{t„ˆÆñxfcJÎÖ²Ë¤Î 8¿–
¦Ô€Q× DÀ¤f˜H—‚b‘ÁÅ§g<ªd0ÃöO¬)Ë+›R÷ÇÚÖ±FîOú€î¿ÖØıJyT‡Lù‡•]v‹ÍVøöpùĞstdÜ1ü{ö+c(gŒ€by_IŸüç¥é²ãYÿWg,i-˜mnj¸™ŠwïÓ‰*¹Òš¹S[á#®ó5SıĞˆ‹EÑ‰Eü•ışgïı^÷v·µè$TP
w9ôj¬Æÿ ó+\©8}Ô¡h+˜©Ï	†h—ÓõŞpÚ[¼°¡`­§ÿ°‚\2»˜ ¼5"ná}yøÔ^Bårş)Plºèàê´£Í%y"šsØı–YÜí1ØšßAÔÇ¬c•»‘z TªW	Õˆ­y„m?LnB<ÉËö»;İóI5Y§ôo~·S×¨°ßÙšm¤ô]jàˆ¼›%jpt1 ;Ö‚#7ékƒ”Õi®¡´¢;ı×µc»°ÜT_]:kúâz|h‡Î®õø0¹è“ÇL³³ñPŠÔø«Ó5LS]+=úú}@J°~nS¢¸¢‘º˜ÙÉò]”Z[‰t—LĞ6‰v®<:yRö°Q˜Á‹b¸#Aø°±4Şæ7Ï†M%š­íhM_ç&kájÛª—Í¬ÉG¦'ùcjâæœ._Ï‚²Û]4¥ÉB9W›yèB~ñë@z^Äœ¡Ôcïîú­-mÂˆ~&ıbg¨Íş):¹*ò.ÆP«%][/‰sop¯oÎtYg­E$Óöe×"±…ÃjQ0¤<dX…}‚;ï­á¬á‹ÒÄ!p.Š™rIBK’hµn)Òo9ÊûœoÜVU\‡eı"äyĞuúH×nŒLµû3[fe}	FÔ¹Ní™%ñººÑ2Ï3!HxÂ%‘xÑ.ÓUG*¨â*UqjFî…Î*Ü¸9œUÉx?iğ|Á{B£¨ÅtôELù”2í¸6jíã¤Á°jı•ÿPmÄ*Îô%öÜo?ÌCqhÇÎ nW|¢yEµõxdÑ0”g" $ïˆSqûçv[´æD{ ë
kÉ^ÊH8ÀÆÚÂiH>œB_ğÜpT9ôE¡ÿ‡©"O*%!¶f 
…?}!sÅë+ÙcÔ@>~I<ÑYªEÃiØÌ¢O9Şæ•fëO¿”©
¢V;YlSOÚJ/ØT•BHùÿùEqÊ6z÷šş[P0¸Öµv¤¿Ñ&wa½³8ßf+yğè*de-®áìexÇ”Çªv›³ñ2ï"Ò¸Ñ«c—n*;É@¹×¸™,Ğ6ÏåÖ"8w7Û¦Ê&Gîû‘¿`~mí2Ø™öß¾1ãBûèìú‘Y‘¡g6,fıîßÅŸÑñEİ…n>åĞa¬P	è±!LÌÕŞh°/.İ;eRé¶˜êŒ)÷J¿Ä’ì™U»,oYézTÉ
z3#L³7;À í,6M`µ‹$ÊgRéË×ûdŒÑÌøÆïGC¤ˆ¤IÓQ§h™åmƒ,]K}ÿ‡wÆˆò’š<·NJ¸U\~~Æ °¦:'C}z~l_]ÉS©Y×Ş9
'&~hÄ¤ÜmÕ“ûÕ3"†\s¤à?¢ğßá¦öò‚ÉEmp}jd¿»5‰jDSõ’şÈ´%}k¯k1¢|T\Õû8 Yû&"©ëtÁî½ƒâCVˆ”œ·Ä?½	” Îßâ²N.‚ŒèËĞ=cá?àº^1D«
ÁµZñ¸%ê¤¹(®ÿ¢/À†TÜ„ÑOÊ@0iöÙdˆ3Z²*Úˆ¥èu¦‹?$¦4™õÉQ¼AÁ–*ığÎÌƒ<ïlº+V4I†š¾@ç+~{DûWÎ$-ôÛ|½Çë`º)æ´-i$½§£#Œ&Û7+w¨³ã“$tg*Æ"& I\—äÔï4C¡ÌúK¶û"Úé¥¤péh/Lî*!f	âaÃ–~^ ø…ÆsYâEíŒ1Ù”Uy'º0yzÛ»¿µÉÕŸï]Ìe®|D½|JÀÓ=`ï´b{ãLfN±‰¯´e~—å[§m®ë®Î™jn—¸–…mwÉÒ–ê*ûm^:Tqÿ¾í¬<Túüë^~3—>CB6ó¶ãå£@k¢ÆÄNK¼Rîô‡B²íü¸qe•à›ÓÙØ¸übÃñ©h“èEex¡>/v‘/4•ñ˜PÀIÛ·m# Aº•ĞŒ\X0I!øl—~âå%=tÉÜ(2àZzŞ7Õ'xOƒè¡lÑşÒòª­¨§‘€Yw+ÁHmËÙÁ<Dõ§iñ™Šbj²UÑ°Ï'Pğ/n8ÿÒëúïb{âäu+w¶÷9hè‹ ëø¶Ÿßx0O&ªVqKLF¢&I‡„C'—RÆõVÎ¢ç	™óB –{^şÏrxp˜Ÿ´? ³¿uì°Eı	©xTøE}6” î€iÙ;'¥¾«CQ“ÔŠ·6:+Gæİ¯$óÿ»Ùe/‡ÒH#®Yfšş¾)¨—=âàİp¯Ñ#_SBo|diƒÆg>ÓÂ·|@<*B¢Ê¼ñœÖâsØd?/eo°èÁ
9ãì¡yÍÚO&Æ¼¤KA´(ŠŠ ºIà¿pIÆG4§üî¸‚¶Ï,¤aq§SP·á:Éf£²3X”ÜáÕ2I`yq¸#ÈÆ†«¾˜4Xàà€¶4ãr­—ª˜7[fLÇ$›µP%ÒÉhÂŠU	<š_U°ëı+Ó¡søk,hjŠ}­ÈA÷š¥À‘VIú¢%-v×¸ˆ.õÄÌhŞqQów®½çC²7÷ÉO›Áõç±ë6ò(Ç¨“MÃ„˜Ìc?ÁÍS¢æ2×>n1|5 c´ªğŞyŞÊ,µ:àj¼9ˆ¨’®wÓ–Ç†šÎf_¾Ò2Öü°ÍjC/,²Á` € ßUpçoyíş°¤FÜºsÜE¸2;‚W¿ïoâF9èuh.4Óh4ê2-<à¾çé#g"kÛ¢¡Ï|´sàC@"¸`^çdo"´¬’h‡ËHñ °1ÌÄnGÄN­u÷SÅR=]VTùq•ÄÉbd•¤7·¼›Ÿø¡M–GK­¾ë¾uÀU¦~zÈ$<Á 9Wn‰DİçŞ¶çõ€©×E	Å%·®¨Ì7²²^ç|áÅÉ¿QçÒb‚ê»t°0/QÕxpUÑzkÑÃu¿¿À1©İnqıièìÎ	^|È-aËªüÆüÚdK¨˜QÈÍ$VM§~2´éê;wJõª ‰MŸ‡=&KİÏÀMÚg;­ñq¢¿‚² 0)]ì’n¢bœÓqŠ×“)‘»{Ó‹o§+şƒ[ê™;¦Tg‘[d9×og÷Œ¤DoTÊ_Û‘õ;¿-P×õòÌU†c«Ğ0ƒØ7ŸVDc˜`9ùÀáÌ­Î	OÔyåÙ¸k «U]zñ›Øqj&`‡'/(¸U¿!íÉR5NĞÒÌ2üa 4Ááë‘8Ù–ÒX­P3İe/ú‰_ê‚øsõA2?:!"¤~@·³qĞ÷Qèé#óÃ‡f¡©TÁd\v¢a}Wg¥Î4ñpŞ-wÌb€­ebLC•Ò“Q‰¥xb×jH·ÒSäĞ¤õö ÿ¦œ©W^@QÍIorúê§­Ú’Áğ2-ğ(é»8/™¾ˆ“;­,£Ø¡*š­Áç™3MqâœÚô…€£è÷uè{ç™D€ÚÎ	«¨ñ¤l3²“•ùLCSÑ¸	Xæ¡h…è`ßk¹È(ÍC3]SÑ×‰A’p¢"f?hù¶«¬&æÚì|ònşMjåç,»8
q£,;â2ä_¤B8¡ŸNÀ3 çe5nŠ±ûù.ÿÀWÅ-0òBğglƒ(øåè5‚1½èÙöÂFàgeÙñF·O†
-îëñ´v–2^+f"$€¥‰¦“Ür¤‰LT»"ÇĞÎÂ®t(Èåç"Q— —™sĞá±„\EŠZåHjÜ5VÊZ_ÆıSÆ–G Æî:A¬Ëğú|BKJÎ›Œmª‚ÑMë¡¢ğÖ«1&¿Na”,D[|’R@¨îñ¾Ó®(z¥_¬L¢2Â£Ags±„©,s-ÊéåÛªÂÁÉf•á}
(	|®Ol^HlFEh"A¥ÒŒĞş{A™l½©	² IùFt¼R„a» }BjÊØ‘á¡:ßó	:¥â«…|óxe_mmÆ
‡o*§Ã=í 
NZ£¢”\²Ë’{ ¤ÊŒ<ltTZÄqb1
º/ëA<ÖF™ P‚š;”…PçN¾%.K#¸#U€´·’ÜO°Ù§Ñ'ßên…ÊjI{6Ó÷m±k×šÀÚG&Æ;h‹8tÇ¯¯^öÙeû>@2u,„€¥?"¥Qö·:V…¬DkV¤ë43£r/ùŸ"ÕX¤_ğns‚<¡&'izä7Ísµ>¢­Ó(Ã<w)‰™	!0®—3 ç´Ê4Şîº«lyøŠå:)5$Ô÷x^«,]«•¥'°¥Q”¬o ÉÆèø?ëP¾ó6Æ¦íÊq‘‹"œÎ3¹üáƒû/l·Ò8'ûæo‡#9s˜6•îù¯±J.²,ŠpÈ”I/œÜt’è†¦‡?òõ:©k]×¸ê~QÈ¨ê`e]òö,ë±õPM$
,`ÅZqß×I†œpİ{28_>Ş1)I\Z–uCµgW,lÎÃüóÓ±²ğ3³Š¿ëÄ–f]²‚ÃÿÎtõlŞeëî;GÊcwŠhµ-çËºæ­Û,]v—-è—šßW&‚±ù=ÃÍåÒ=­å„ô`p¢Áú­oAÂKb5)Ş€5-$Šg–PÍ<ë¨€ÉµüíNä1…p@ñ‡Ê~ g9—6¯K6•5M4¤İ”–8T>QUœØ6 §$šóX\‹×¸ByÊk»^†¿Ê®Ğšk®jœ[RÏ”K›ìÔ„‘ÊHLŸ‹ÊÉÊI"
Éì«R„ø¢D™³mŸù‡ïãÑMÒì«ZâÌPäÓ¾IÏ¢·àfM¨D‘ÖÓQv•ÛßH'‚’¸Uàğá½N ‰OTŒxá³‡¸Í“~x‚á‹h
Ò0ßW\³Íÿ/ŒP_¦…»âZÚêãú6~®Cßñª CòŞj‹bÄg%Ôí;kZ™©Å)nµÊ±·–<(²¹?]G+5+OŞEïĞ$Æ5 ìŞE§”ïó­º^3#ğxo!1¨áTEOà‘3`u­+˜ĞÏÔå	Ûz	‡²fæ“ºRE÷ÅñbŠƒ¥"ÛæG°Mw>=Ñ_kw¯~¤ä10©Š3+‚4¥ÆµÂ‚EpQn«Wc5H+S«\ŸË«­J›ïb@Wß,Áğ6ø«Ù%¶ÀÛç
ºi{ÚŠÃ/éV—AT¸0Xõ,t>Ó¶h€ŠbH­ôWÍúqP8Ø×µ§Ç-î!¡/IÂLq°DP;ÆTÃõÌ_¦¾e—	é”Â?fØøÌ“’0£ùH&ñöL|cÈ¥dÃÏñ<â½L|½ä´"?
¤u®¦")~¦«²Ãøü_€ú¡‘MŞ·¼‡n,u(Ñ£ùŠCr@Z²şû–öQÄ5øÆŒ1¯U6—§:R½øQ@ß‘3ŠY’İr¾7}¥¶vnîHED‘jªX¾œ»½à°­¢àJ?½Äˆ"‹	•³9E?öV€FìSã÷n²ÓÇF|G^G=sÌÇC~ÂìÖ†ÃŸVï³zãlˆCZ&Œ¤HäÓ"B,{`1æ¿7râz—’öÜárp‚W§æ"àÁwsK¯ƒƒÃlòT¨1(š¾J–(T™ŞÓ¨2şË³¤„ùÑ=Ä5Ø¨Àb‡6¾YZph…é²+ëŸu0ĞÕ–?LBÔÕ÷ä@û3	áWÃãWÁõÛ`€zwDÀEö~Lv½hPF˜»l¥,"‹…¸úiq^õN)qÆŒ 4Uß¡Š3O?iÆìl¢†rW›O Låø+®¶æW‰ëö‚íôœÈİx~>…u#³é©ofÒ€¥ÕkŠmÒà„OÙ/À f·Œ\ÚŞ¡êå£w´KåÜpğ—ƒ\érŞ´·|>®‘;5ß³·¢¤!…QŸŸ¼æü'x¨J¬úÒİâ{+YD„ãs˜ç”ÜìşÕÿü—o²ò;‹8Ì@»Á–ÎT°W¤5ú¸q>005sıqíÜœÉìVZØÜ`:8=>¿$ÅÍœ·HYI‚z¡òv½iJã£"Jø l+øQ†òš´iŞRö"o—eô¥’~9ôSïµ„ßC„}ÂüUm¦A ¹ò!³{PšfF
KpÆvåj‡×ŠUÓ@úìÓIÿ?Gú"yZ>>JèÈN/õ+ş·uıe¾láÎBîe”·fäwŒF«‰™È”Gq¤àdW¥ãæ£˜ğ¡¼íw¿}ĞŞš©ä‘áÏg¥¹ÙÒî6ö¬”|Ë•åCÛ/]åÔSÜŸfÍˆÌîÓ¸æ PØõœ¤Lé\ŸU„ªv,€ÆŸ:ş$;÷å5¡|E–Â¸Ê÷ƒñŸn6èiÑNÿUF• ˜wŒ‹wsœ"½lå¥oä`>®Ê=¸BÎlhi‚Ú¸qóß×ç³åØÂø±Q>ü7|ç]F]d/®¡n¸E=¥&ò”êŠ« Şf64$Ã¹¶®¢×Ôñ©‡Ã¥¯¾©h{“ù6	,c.30ˆ("88cÄ 8‹ı_6¡hjÏ¢¨Nd¨a†ÙUßÏ§ôƒDè—Va©ùS·ˆL"wúµÁtr…UL¨BŞì¢r¤iÉga=Å3*À†N0:éås¾õÒ«$l~…W'ubqi¯–’&Ì*á(1Î¦ª.‚½{ÆèØ¾µ¹ÚÊ)ÇÌãY’
¬‡o>ôÄÚ};˜îÊ<ÇF`‡aşÊ{G¿ÿyv0ƒºÈÏ‡ÌXúFÕWzpÃòË‡ãÃ¦ìÁyÅ5ñG™;¯§a#iFW‚z{Õ ÇaìogQdİ¡bYÆ±‰¿wíy7T”½GğföÛ›ZŒ°«gß–™/Aşí:]R(â>¯ƒ:wARj	‹r›í„ÓrTQõ.“»=Æß¸ÃîĞ/{ğcà1eµZ×¡ÖOoÁ€õˆÚGXö^%B‘J¸ä9ÂGÀù„;qN*yN¨ÈæfÕé
¢^k0’’€è <.Fƒ{ÜCù^vdÅóÊÎËDzrrì¦+,’cí­N}š™j¯Rrâ¿Z–ô6^ä®ë”	o£)tàŠÄÜªß&;®³¦}È‚ìC¯¦ˆSçu|Â´ÙòÎòñUê_‚“EC«¤ú’æ[	ßœ½¹mq·P@ikÏ‡z&ûbÌQ±x¿ì½}•Œ|Fi5˜ëv¸
çû*aŠâ!«Á¯\1N®s¶+%á×^–Ó
€=æ§Íú›t2hˆ CZ…@a«X Ôl“‚²İE|ozxrÎğõÀwß¤¿£ùêÇêó`*Eµ¤ßNyå?W

¨³
tæím‰Wª‹xŞcN	ïÀÄ—Ä‡ƒ23=6Íí]¡ŸsÜ¶ÿÎá¾<»'|äÒ-‹Ş ƒ,™%ÙÂŞZ²3Ø]Q£ËI˜î—³œrb~şW[Ñ2¤iæÿ }q;†•Ë¬O‘÷Ş«eú	íåhÁı¤f’³‰[8`†¦İ*lÈÛ@é{?BÅzsmôÒø¹Øâ%Ã„ÑW#Èãá‚[ú£(ï¼
…dJÚKá1
ÄŞp¿ºvˆÒßt‰2Œ€ÑY2¼kr|\Rğ¢j$ÅléhqÖ\æQ-ü¼.äK‚¢á§°|M9X ä/Z…‰`_æàG0a„DÙT<’ƒ:¶9ü«üái6t}Ğ×ô§‡ì¢^ôRRº¦ûÅÜâ›îµ_HŠ´8I ° oÎî3‹“?ˆ“™Û[hıµî„N£ïx‹îD¡<ÊÈFô˜âp?Ç§““ÿIƒì-&p2ß3ƒ’ƒï:ë;´Ü
¢UpjûvÚ¶›æ#]J¶úép~{n)ÎoPÕ•¤5©ë4¤
%³}ã(Í$UY´Öà7	.©17ÀA~²â˜9­%Ä(ZÔüNé•-‡®e¬—zEÃ®;l74œ‰îu`ù:üõ{%ü8SæŒ›X*Ó[÷…ä¢ÆÇ6;ª(	.1™µµò -T¿y*ÀåÇ£¥ÌÃ³¸ÍÊ´AÓ<c»d£húMt
R°2Ñ±·ñQ¼exy+ì†¥º…B<ñšF’[Ab¯çéşöú0Û0÷LjõÌëM{<ıÜ{»·X-|³j„Å×CàBZ‰’ª¯‹U0ó’1JÓ(‡™†·€«ì~¤Iáá''Ù½ôp©Ç¡ËêYÄš,IÌQ7©¤ıKé†°~¹Ò¿³^À/b,*ƒV}eCÏœ­´»ı²ÀÜß«DÎ'k
1‡mûÊÙÜ’) ¼“ï¨ŒÒÀí›VP*Ü)gWùœ:À™ŠO^úŸ¦5êÆàÆ¥^Q¯õµM%˜Ğµn[0•Ìqæ…[ƒ¹gàhğÛAf¦ÒWªHTˆNoAkY "'ÎQßÒ¼jCéµ>€1SÂ3uŸœı©J2Äqı®ßJÈ–Z-‰Aç‘ú w+LõÏ
ú»ü-'q¡V†1¨†ı*MÿqE–'NØ‰ği•ÂO–îMç]şyµ¡¥F÷Ââœâê—ª¨AetÏÉË*¡ÓĞ»fZG¬‰ë=ÎÚAëú3Sú}jÄüÙ<[íİ…/§ü(Ãºå¬Í°däI÷&ºŞËI:ıë·Æd+ğïÀc¬’ƒ£,4&u¹r!×w›†j2õnæ·$1ÕNÍz•2À²8kôv€öU¢ı®Ïí¯]0ÆdÃX#ã\\Ÿ0z–V¤!ÿÛÏh Â±+ÛìGçV\¡¯Ä,	)tb÷–¥Ñ'zûëÄ©‹¾7|§ÆèEçª³«\‘zLyò¢+u—™®Š†¬×ß~Ê¼™%Hñg< ú]–?(^lqí¤Ã¸G€³ãÜRß859¬ÃvL.Ä’……e¯ª^
@êĞşBèO@m¯)tt´Œâ èÄ TŠ©E±ß˜©ßŠ¤fĞÒÕÚŒÒüïÙR„¿pø!6°R*2
ã#¬ œİ +<\šZ/ÈÜÜªëçÚyÎ«ä8I*V»/dæá/ÒÇå#Ù±&!¹ê(Î†GO ø¬^“¾¸p’	óÁ6¿Ş¦¢;ÿÉçGZ©°¨Â"üÂZ)“˜År³w¢@Ûµ9Qà+„û¨½ÛCi/ÇGğ‡¼y#1Š£ ËDŠêrU¢2	$!N‘ñrmÖ;—eı¦xeß#4œ¨zÍ(( ñüC
g-T]^'¬Û¢¹"k@X;/åf–òÚ0í¬<\WR>óL‡ÿüY³- ‡µ2jcPèğü½ÒÖBªÎÏ©¯W…‰–|ƒÁ4ETã’¶úé-—<UFÆù<İTü¸ıÏkZè˜	%ğeÜcEğ\S3V½›ò»ÿQÄĞwiiZ<=»’©Ÿ8Ñ4ÕËÀE{qRğºHTù›mŒ|mWŠ–Ñ(|ä¨L1­€©ù<ùğ~ÔtH00S—€ê¿Z#@µ«•ÇTıÍ‡K²ÔÆ¿R<¥ÍÑ¹+©íd@ë 8-ÕÆ¶æ¿,éE¶‘™[‰âÉ€ÑF!$5û|2ê ŠÒåk£| fóY7˜ÜÍo½Ş#4'ïĞç¿«
XD5]dƒ»%$.çŸüù·`ÙBœ™—F+@V‡ÃY]şãÌy‚ı†<jsé8è=(cKQ#?ÇUn½ö÷K‘~²Á‡9Õ|ìMò3ë4™ÁñÙPÔ’LI;Y%‰ô×uÃÚçî©HH–Ø  àpGoó©îáb€_Ô£jrœ÷¹·Úµ;ÖùşD¢#d=‡QJäÔ³Ÿ¥¸üö¬>Å{¤çæKÂ?JI-UXSb’·‡Ú 3U¤ÙÏÑ`™ÿ &ÂZûØWVïÊ[~5³KšÉtJR˜9`óš†õVÿWßË Íha¾t+<2XÉCzÒØ»ì4G-ïdrâºqÂĞ‰j’v8”/9Ûz¾-ÑSml±íI·mi¬¡rc– Ú‘
Œçà½@Å‘1¶ ½i°ûKPL.º5ŸşV	LöÈä‚\¬ådÓŞ?òÕËú 2x6¯©¶•
>ùÉ¡Ş%Ì”ut'Ò…‡îIú¨¬"ÇRçÁ×Æ'4}šp6yÁ5ª4©é®%…w
VÍWTg$”yNA;f½=aè‡g®»FÃ‘WsbÙëR5e·ËGj¥K«×Xı¿”}¥Ô5—WÜ±ı‚©Ó«d©mml'–P-ä¦Ü®ÄR:—ñÍTƒ5§›RcÊ™f¡¡GŸà}ôF·}œûZñ{pñŸñş|Sâ×Q]^ş©q)SN3Koz(gÖ]ì=w5Á¹!	Sâü¡ó,ôÀ-÷ƒa`ŸŞZŠŒ¨¢Û˜(‡-ÜŞIşg=tlÂ)%aó©ŸîúŞlxü„³Uñ$Ói
\±^|ß“ÅxI‰›¢óÁÇ‘gûgz´¢39PÀ«HÙæĞä-
èegÖÑ¨òƒìÖ¼bÇaÂ“ĞÙgõñP~¨ş™†œ/¢#¹Æpx™¥íiåÊí÷ÚÇ§¯P#kK}Bdy¿Š3ûÿì•á±Jáã¬F{ìñ¿{²=È”§bhNAÙ³ïYÆ.öÛAQX5ª3U’“®…lı×ÇÛ3ÂşEVÿ>˜¡ÛògÇv§ÄmïWÚÜÛé±ô|6{Äút„7œJ âR—[Ø4‡¨¥ĞkÖÑ×o„æµ‹$O%ší3å¿&=<©üÛÂÄôõ»#^×É»NxiJÚ…Oœâ·î“ÀÕŒºÂ€n;\ÍÙ´G* YvÎ)Ö‡¨Gw¹LµD/(5Î™Ó/-wÇõ¸CHx£Şşä=YD&ÂV­¼cxÊ<ôMİ%õ5šlOİáÉ{İÔ =puQË’#¶Ly8rë¥¢í—™­HÄ%»òİVC7f¹MTVJÙ<	ì¶5PH*O|­zyWÿ
hŞ!ì%–´¦„ÄD¶ëSÈ¿kmôjèÄ²7ö\@ÿ¿êœš¯èK¡ĞN¢.×Î¡`«>«°fS~OR>·]ëÉİ½N>qïQÅûsCR´w‰ó™ûÒ2e~„ç„]öÌ'zQ=¤…—Ó¿ğåà¿­$_ôÏıjÑ‡áÀì§ûsô#aVFmG}H*k$niIm¤7N¬¨Ê>äé³`^İ¿ï{İâ¦ âzƒ	‚‘hG>zfnı”ÊˆıÊÍæ)„ˆ>¬ÔsÂ¸I[$Ğfwñ¶MÈR%ùn?£Ø¹bE%ÃÇ7ÓßÛ¦?Cøóï/Rp—]õWá&€|îĞ³nï¢R1‹Ş&Æ1×^éJYú òŸvÂÆ4Ÿu«€ÎNøÖúxµ5E@Kæ•]$é(í
‡|÷ÿì±İ±q’Q²añÛ‚eJ²ìM‰ÑÄuQŞ¨ìúié´r¬(–İ¤Î.’î^ÒP±‚-všá[!\³¢«¥ˆ[4ûÔAxéÔÜk×e·÷Äé)áéCÓÆ ’´œÙ°îoA=òE£R)> gCşÊÁÚÅØÇT)í¹-Pä<çÃu£Æ]ÂV"²šÊŸÛ,—ÿKºT(RŞ„dá¢ÄÂó¨Y›’+XNvk.¼Kk¸Õ¼ç5t«9?ê†¹€î\qƒÎ{Ä³T (ŞÁRmµ“Û÷ Ó÷å)ÁÀ;&¹Û§à9Ó³»úä‰pÕÎ‹w¡Ì†qğÉŠÎõ"9ìÌçãõ<,cqâzMèÀï>y¶²ñƒH-&CvÂÏ¢q„.œ¸¾z³HÍú"qâ?Dl6B6°EÒC/£š|Ó6¿bÈÇ¶¢zÙéÊ®˜µ¢IŸ”Ša³ñ_Bhê©ÜW¤THîs^óÃ,G¿PVL-H£0-BÅMÔAYÄé£yààíá„Ì˜¾«¯=Ò¢ °Æ¥JônÉ“ó¶>Àu5`//MqBïš“)ús5P7LARî)•C²úÀ§:ğá{ÔÍÂD¼á÷ûløÛ‹¤#CH]µèãÖq°¨. tÑì3ËÙø{}ªçàü?ğ­~'…µ*ıÎüÉ¶a0yT*ù7,h„ı´ƒ,Ï‘¯´[í	÷/J¬µ¢Ÿ­•öÁ•àf6ˆ@ík)Âc7,
ËK*ª8ï­gf~“bÎNÆÇígÎ†Ôœâl Á,—-9Óc¿RwUä¥a(ëB#&©$©ÖQÍ¯óÎ1_Åtnñ^o@Ìj¿±Kñoƒx‡Ä,ª_V(_ÿyoı–1´R*(s÷`aöæ/?Wu)ØBıü spk¯øè=io²åæ²3`à¼ü€Ég…n‹T–·lYº_aéÍe§˜ŞcÙ`ú˜A’0—1°ÙŞzñ»_@ÂtÍ˜³È©Óä~llLF+…u]>Ë¦,©)w1zõØšØN#É•á¨"iŠL—NJNÎôÿË0FZ±'ÏbÓ¹¨A,Ê}»Æé<L\diÁm8x0€€†œ€‘Îİ\Ë[»4-³:ƒãEå»•Š¸PİÛ/{C5Ôr
“îÓj!=û4Û™ƒÜø&éÒğÙ’Êb‰©IA§ãGÔnéUYµ‰FÙ?óõ¬›9â‡ìwp779¸¾ÊiÅ¦iœ°x»áR·‚ÄV¿2„v$ù§2ã\F"a.œŞõ™Ğ£²	–§ø¸Ï—¬A_Ã¤®Í5nË;Ä±&×CW	·ä¥zÇä	< ¦ÊU¿&®¿å¹4õ_{”mÑï¸L0v§ˆ%–©nŸ¸¢®<V0»6XT0wQKŸB=¼ıfêTÑ¤Z—ub(ÂÚå@sôx–¨Î«EüÃÎÀlzdY+ñàäy{µw·¶€¼?ä”_òßX–t8î Y(ÚÄ-Î¢•æµÀí­é*LHÉüÙÍRª7'­á¹ ¨¬Ô
L8âj:ñí`9\ÇÎ¤®ØÍZïê a?Q‹YDÑL¸Tf6•¤Åˆ#ª8†?¥·`‚şùĞÃe?¶ÕŠëBçğå™_tB=uÕZøl_—ÿÉ„öDò´²At<=–±jÁ¯:õRU!ÑÂëL„²W„6Xnb/${Ö}.ÒHüûø"]Ó
Qd’ãá¹”>‚‰¬­ÅºlØÏÊ&f:>oúe¶!0hŠ_ğÜûÊ‹>æÏğ8ºúU«ƒN¢tmß3‡åq!‹Ê,JB“N¥Ñ´nšgÙ9¿ #sÈn”|K/2¯‰sß³2’Ïp¦·¢>gÂÒÏšôè²ÂÚ;[ÜâÌ~¬–X¹cù´<ëfZcÜ‹`¿­¬*Ñ0€¼G:Ò.†ÃaÉV¸´©F
èW&ò»ia_Æc¢ËµSl?±¡áÉvÂ•\­ºıB«V*vûd",3¾sÂáç@T!â=Âƒ’¨s•q¬*Ô`C'Ö.<I(ÊªE$'l"?Œã4Ê0?ìØªÌ£+ë—Ï|DÔŠ0¤%g/`Çvª»ŠÈp3@apŸ¼*øOúE›#òNÈ\¹B[ì¨ÀùÍDb¥&üÎ ¬IsïK˜äñïZ­Ú¦0A åüì3	ŒÕËV2)­qãaÕ‹ûNù8µ[Aƒ7â4Uh¤rv)ğ‰­yo_éÏï|ŒEzÌm$ü¬¦ø²µÊ´Œ*K‰Ö9ğaë`<Pµ¯C)?å8/NF¥ëç–L¢…âÛ“ ĞQÎ[m¡8º®RAé[¬#9–BY= [%\Ù
nëmZ´ ÇÁåš‘Ò`¡u=Û"i.ÉVwÑcÒ“€ÑèWsc`Àšm†BŸ@wTş0æŸë4ÂqSSa\r3“OzC6;)¤é®ˆRZÃíék£%!ÿ·ÉTn7Ü>[ßáÙlÔôö{6xÔúx^›ã£¡ÀÁğÃø´)‹CfĞvya€[)ïx_Ãi{6º²”ívmNİ¨W[ÖßraiRàÛŒ†¼ ş…o~ëEù‚İ¸@ßØİ“’£À"›QûŠp,.–ÈTİ¶
oÏöE‘P=ºIOIÑÈ¶#“>ı„k&)%e |Nc|ù×X’ÕËÌ®“Ğãk‹dœGCã#³–'ìâO›A‚HGÍh‰±+”s†©ËO„õÛ‡¢
‘7ÊEÖSÔ'jÔ/²[İÏ Ùúqº!	™®á¿ƒ¡?
Üš2+XëßÖÉÖ‡=iSW'šÌ¸Á~V!Y«ò¿P…&¹¢XÎ:‡—^¾~Š¼ÙuÉŞGëú¼ĞOÍx-îG¸Á$¢U@/=7:;NÔ€«şS¥Ø+³¾Ä#l7•û$Öÿì—ÜªTÊı-ù †#Ó{ÿí9_Vø…*Í–áÙğ'ı"ìJ‰µÏ¼Ø4ÎR ş+J½õ*+J¨h]ÿÇÎT¢yÑûDùM–Ã`NÄŒóTĞaÈ±Wê~"çsC>s”rXÊ€b¥ IıÉÌÌ7ÎÈ*¿(ï3Êóî€.Yc`¯4úº&ı©£Ù¤»,||FÛ®›Rº¦Â§Á4æëàêZÈ+›É£÷bˆñPÅòö¼8áµM¯u/şáézEØ§¬3$Z
0ßÑ^=ÌsÇ¾¤ ^W¢€İ<À3³ÔP×…âÇ.èÌäÊŸí
zäÌnÍ65ËÉ8pÙ.që]ÖM¬û% lŠ)ßTafı‘µùÉÙ(äç ¦Ğa®D’VŠøS}¾¸î¬×È×À~ñ)ùÜ÷Œzügiµ*Qí€W‡„÷®2ö1ıĞû˜ºì–+IPº×kg(Â—2èët8Cò/¢¬ìäèáI6m-÷ jöAÈQ…²Ñi!³E$=_Nª†(òGbsÓ\˜…¢¦ôöX¿’ŞiÏdWL€ği’,§‰ÍÀ´M¸-uüx¬ë!ª	CŒ·
LÓ1 N\§âş]•å$Ù•ÿ(œÒ.Èü†W†Ãs{eüÇ‹eÃ¬‡×ihaş9jÏñbv¢ëó#Êó¼®KxGûCDÓºR#ûĞêıWø9>ü x”5€™‰]e”Z9Êw^2Ñx} HOà
Ÿãwíg"l‚OÑS¤¤¯V}-KgGîAŸâëW÷ ˆi%J‹¥…~FáßD¿½àş{9Bz
{@@©ˆR|!ß‘fD1làsPö8 ³è—Üç›ÎĞàz)BYrÚ¢û˜ı?Ò¿z´œÓò4èë3Y¦&E¼–İï:W±¼ı&±ÍíºµI5¸àÑ-CïóÈp%zÒöÜ6z_	 Ê}ÓÇ€É"¦F×iªÃÛ7ø8E0RÀø!o0xËP°È†È¿ë8Ôp‘ı’•CÖóSI‡W·XªÁËj=„Àã²¹:•3T"â8-¥ÎíZ3c:^~…•{ï? ^óßXˆAû–NzÖNè<pc«‚!ÔCN7P30ÁqÏ=ØòËÂ¾Í… pæ_KîÏPxiª/:y°9ÕazûU“IÀÄ…'—!F=8ñ/ˆŒ÷¥X»û[¦'ªÆ)ÃéÛ
6óë'b¦§4^å…‡‡Ç øjíCO&,äÚq&‹:GH´2“EŠñ˜Â‡%;RRßM..Qêå®‰Ü¾¢àm‡Äk’îÆ™Ês*rê%9ñÿsw{Ï­ĞøK9s`mO_˜ÄÇs+WIÛúÀñzB’ş|Ìıf)ü÷İ È®ñ<húNVåÍ³½moæ·Ãı!½±¼UÊ¦zÊ æÔçÈˆÌø‡»zˆ/V¦Ñ™î¼i>ïıÇ(Çé±d¼`jÒúUâaÄ6'VßG“şìxlv_d¾™Ü¸fYÏıã_Š¼Ø§˜TKs4]KºßÍ[¸\o	ºD¶øøq$°—R=Œÿ±˜1Ñ7‚ˆ¶á×P:’y9â×.Ù&ÒÑu€„9ºÊ!¤¼Ÿes«³‘+ÂPÉÌ%wì“9}ŸM#ARG‡˜©Ò {”µÏ{àÙ6T8ªf°O%É`Å»/iŞq!ÜË… ÷GÍï#¨¹‹›xF?Î. ?4îƒA`ü„¬r;‚¿(ê…n\³ÿ²åXYb§ À¶lã’Y&HX•&OUÏì‘ŒÚjèE®‡ñÈøÙ YÀ2L—ÖşáuÏŞAs?H¨ø…ÇÕºñÕğ°ıÿ²B½g­B{ZŒ§ŒçY9sU§¾ø9¦`1ÆyaÊçğ²Ô n×Àv¢[)Ÿ: ÉP3â’ã‡ûx6fÀ3ûEå ó°üdÍp1&gU”³!oiîc_–%Áÿ–²¹EÜL€6Ò­ïHÍxÜÚ}ƒàÇ/ÿ£ûdÓÑãX,¨Ì'¸G˜d$GÙ'üßÎd»P’«÷¨õ2á?-´1ˆò®1‡š[hK½	æ¿V)f….QÃú9î‹^APĞD'sÜÅdk¾FR¸xZ¢F"Û§‘–¼Šní i“Ñ½DÈV<Kë[½>¾V¢ùôd­ÒãTÌ¾6ìf¢Ë)ÌĞŞ¥Ş9»15sØÂ±ä M­ÜYâ'¡Ğ\ÅhØÍ¶I¾„RòÊ¤|8èò£ègÙT¼};6nğWÀÎt=mçy×^²Ûœ+Xqæs:Ï<§¿œ—
ÍÔıŠ¦ó>ªß%Í|„,qy{Ç€jÇÈF™’
a©!†’É ìÏ-ŸÂL?¦ÿ¤ê‰Y_reRYü˜Ú)vİkõ^óÉ#H–âMÅZxÂ’‰û6$to2g¼Š÷¥X	2ğ~¼ëš”ë½Œ„®*şéıl2šÑba«­“(—$×Š>Dó2´.‚L[Ç¥è’5f©_ãĞÜY^ÊL Çäó¹©%ÜkzKg$¹'–cí\eŒ>äÆaıBğ›ãÌÈ0&!µé3 øbå¹†/\QXöBD­¶[Ò B©ğÕRRŸ‡g'&@ÊÁQ‡%™E9mréÙ#ÅæƒOÌË ““·Ü‰	âÿüv%%àBf´KÑş\S‹Ú—É¶¿´¬ïßZôÿÚÄ[›üf@Ê÷¿	ÔOÏ³éıWô¯*« ûÇ6¶ˆrlŠ¦V\Ç¯z†ö¡hwŒÀÕ$y%J¥É,)“õoçáªj:H››?”ı-nmvµÙ5ŠaÏF Zå’ÅöeÎ‹³nn`v‰åÆ$ÄÖ™²3ûh¢zj‘8dÔàF-VÛ“Fé‡õÍ pW^™£p	ƒàó“½›åãa5Sˆ{%;ŸHÓ0¼™òòæ°†)+“İ¹]4Ãç«n"bÌ’[gƒşe¯r	¶ÑÏâ¥ª[4£,Û˜ê$RC˜†ábµ²ÂHVpÍÀca>MiĞÁ²77:l¥sA›¸nSö¿ëümŞnïàtº25Ñğ–|à9ÄÒpqUësuvÁnó"<D\àÕíÓßÙÒ’YÄä•Ÿg3	ck¨õÛ|zÀKâœÀhµƒ6¤¬0ÿ¾7+x)š¼vßåÍ‚LİJº§¶¯êiJM2^7Oo*{ßÚôpĞäÕ´UÙVÎÁ™> ‚…Gä¾ù$œ—úëù« ¼‘å\œ²å¸=¶†~Ğ¬Öbds‚Óz‰›.ç¶J*)¾ï¼%iU«|§S2B˜€iU‘_HŠb*Ds´ÚT È{—;á•¡ âç	ş"–“fÖ²ã‚”"üïNHo®™¨òŸMábMÖ­ŸüŒßI+×õ«¥ L›9¶½Î‚'Ø'Kpà@"‰µ¯¥§Â-¬>)-oÁÕCj`qv«<å­ŠkUç‡S/ûÈƒAxI`™±›ï%÷4M„Şi.oè¥P.‘Ş—ÎÚ¤=Şg¦±³P¹IK÷}w°6ôcŠtÊÑâ°µ„éDûÑs·Ôb<H.$Årã¶»W° ûì0Ÿ ƒ‘Z¿2¿ŸöõÆas-x²¾ZËáçç[°Ü6÷S‡‘v°ùR]3óÄI÷ ·S`Ş|7×_›0ƒ¨kÚ Ê`ş£{Şü÷W§2EÊ‡K%Ü²ƒN\>p]ˆ›¡VàÅ*j´¼ìû	’í‡Ù546BU¬™˜` Ì©¯¯5f÷¡û¶UI'ÜÃÓ<¥ù.ö¾Âi†ùşD¼§([ß/Q6Ş8 Å7.ÎğÒ°0w $wSìÑø¨7CÃŸòMJ‚=ô@]MÚÙ9äët(	¾–¬?±p›¦o~,W/ß=ï¨	P4¡
q'Ú[áû÷zÒ-&‰-ˆ+³©ÜgÁÏhòÒë3Y¾·#cfõÄL|!û!Ü½gÙ8>ÄmàêßgÔ1/l
 €‹4”°Œ“-u–¥kVŞO½À‘êóŒõqì¶‰(	âÁĞPşÜ*¶æ”ºè¬1]“)f"QógB’œË'E[˜OrdUØ¸ŠrüwãßûfdŠùêv¯Ïí„¬¦©{}û¶’š ¤…ŞÁ—$‰îf /Ñ¿1‹‘ñã”>Ş‹ÇG6¦zÖŞjõÑd«/—¤Ä×å_tíA	päôÓ/¦¯ï”ªÎ6×,ò	Y½·†2m!õë2Áîà.ô#PÙBzûg:¢¡"a%Vm€rc¤Á©9º;÷K``!°4ëK&|c"t1 6 £/ÎŒ·-pÖÿ5^;Ú¹~êöˆ‡|Şû}ôo÷<[Wt‰¹¤®ªMºJ:tYÄ^({¢<æÃÿV|ĞA,™X\Ú²Õ€xi-LÓq#|h— €A•ãnÒ°G–“| TšÙ©YÚ­š<ÚÏ^\¨»|·MûrêUn’lÑ}¥®ÙBƒÍ™¡)««Ğ­Ò²§Lî$söÎc¦$^öı­¥`®zÚzEös_hANÙ&<=ÚÄı?ª=–Á\nnZV’Ü1}©vªX5w›épäF‚†OÛ1ò¼?–­ı’ì½éw+_Ü¿ü;V/Æ¨‚õÈ´„=šFê×‘Ÿ—yp™ÕdtÏ¾ã‡ Å½Po¤	¡ÍÌ’©NùhW#RJ\ÅY¨v`´êÄ4N£õóU•­ÃCTeW³w¨Gk±ré4ú–ğvŸŞÌNª£y`$ç¬8Á	Î›H„àwë¸ºµ÷‘?ùÅPF’_¨n™hWŸÍKPh8BÎäùcTŞÌ+ºtb‹ŞÉ8ƒÊæş¿0 Õñÿú}BòÏSÜXïşHÿÙ¢?V11k‰oÖêÊ­È)oß#qæÜu÷r0be*ne2˜}ãğŞÇJxkûÛxõHÓ:¸*xÑÑ+ÿ®ˆÚdr¦w/ñáïL(AÛ—¤˜(× )è×N?æ!Œ/“'„ìƒÍP šÛÎUØ({(2ØtiÒÆ<ùËv¿BD¿ô¦Øµ<S)ƒ¬}­ËuäLamƒÇ¹'ÚÍô*&m˜*Ñ€¬œlMD6§´×œ#¯w®
Ï›Ícœı®_Éa>¢Ív?qÚÚ#¼¸äÑQ®ÖÇÔÛ,+Ó)y©œ‰´u·—ƒ†¹¥ì•qdRÎ­¬hNïK¡_`#>*ˆêf½ı¤V!ci¥o°"ş8û6Ğp©QBÀÔİ9İ¬öljF.™mUÀz›K½¿õ½0˜¿Ö§ı8Õµ`.à¹‹¡	:O×¶÷‡ĞÌåµãÔ	Ã¹;€íM´&Ì¹^ÎĞH/ÿÃQë?W&Ø]ågW6„faÓ[Á$ƒ~84ˆ.ö& &s”ça||r	C?üêÓn|—å'Kh×¬óÉ\™?÷Z‹§ˆ»C`UŞ«Î;ˆ½ËZL¡^ >^ş‡‰uoãAE²”\†Uğ×³0eıù;Û·T9€£3QœŒ¤Y8Gä9ÎÌtÎ8qmÿ$q;fo’Q‘	m+’Ú§eêÖı•ÀòÓ´HÒİó@İ–®"(|®àñ½ÁKZÙK 7¿½7GNtpùâ×\æºnãÊk†1Zßk‰{ûGê!23Ê+‹¾
šBœ‰+?ê»hæXŸPy[Ad¾Y„lZ@³6óHcüôp|Ì~§µÕenôé¤~Ë¹hÑˆ1*½îªşIô}ÏÕPc4àq¶¾S(#^{ß˜ı±åÂ\ZÕp	xò!í¶>¡Š1uZxO/õ‚åÅ‘GX7Â„ „SqÇå¥ğùe›/¶L5ª]›Äã†_æÎ–»àkVÄ–WÃÜŞÃXfÎìÂ¦äğu¦¥Ÿ‹š´ıï;ƒa ½ÉQğ“\ıƒ­œ=@æøonvšã>;øf%µÕ2ó>©P_— ·ÓUğ¤İiÒ…Ùx°ªY‡SuµóÓß.Q%ìuğ4›Ãæ‰ÛÙ¿‘ÉAh÷ô¬ÔúÕ‘QË,x?¼tĞ½|dõ»‚zr¿DnkTËÏÔZ¤œïÔÈ5ÕG3/ÇsÁ3ó¾Êa½À¨M²›º“NåÙ|Áıa°¬C•\}´sµº<¢Ú@ĞßO¤<im€MÎ£Q-DÃP¼ˆ%“©/ŞCnh ÿ6+^­y¿9¹="Ï.À9“xP\p§ã}¦SÇEDÎË¨Ä[Är^DÚëZâø£€:‰ıê%­ñÏ –‡.Upÿ_œù”í:~¬àWuĞñø,7#cîıÀ.Nœ„(†:^$Ì«ùß¡cÙ5$ÈwÖÙƒi‘ÏQïw,æÂfD¶^ó€^æ	fÔÚt?âØZª?7ÊŒLŠÁÙ€Ü™«jŞs}ig/è÷©’Rı0J¡W*%àËĞo|‡ÉÒl—WC5^|uª¬5öM»¦{Swûádù2µnÿÚßLÖ†Ê:–a‘ğrĞñåa¥!tH[Z¥qkÒ'#$&9ö²U›Å‘ùªĞéDÚ0—l F0¸Õ%Pm$–ş–í›Åø;D®§ Z"+Ûa‡ÚX¾%ï×åÛŒÅŞğ­€"‘db||5³Tyóı=Àô5`TC‘aõí™°VgÖG©4tn~eCIª²~ÈX5lL…ûTd (Ctq¥¬q¦±(tµÇ%}‡t
B‰R77‰B©lsŸÑ’#XÌƒ%¹š	¯:á<V»e!ôu>ãÑĞèÛe8›(Nü‡E×Ÿ(búx'Sñj-SÒÌ(¶íDcÊÅ¹PPô¨ûxyQ!© ïÂ}¹mê#%³$<eø²ˆcŒ*:'ˆ›^èÄ´Ù:âa˜+ÕXoÉ]8‹&4ç|¬=_Na’ª¡æ)aÈZÏ=ÀJ¯?3‘hÎ4×÷D45=G1¦ •#JA½ó®¾Â‘]§Q>ÔdÌÄ'Ë^ú7«³Š°( ÿ±í‹İLVHœ©èÓ¨÷òzl¯‚ËÍŒu.rNéŞ¿UÀ[È®¥°0Ğ¬Eñ¨…M™šÿ jûM²ã¦¤6†ç~ôt^Ú$fT³úD}Å ÄšÎÕìßù*)-Äöè!…ñô3ûØ”¾Jó’RØß–1-zİ£“‹ó´bÇaLü íÈiBHz\îÌZıâh¼e¶Ë±­šów÷ÊŸV¡	)¡1£Î»™ğÙ=÷±Œ9´µ“>SâäI¶F¯kpP1fî'xš,[8Ú1ß{ck_
²¯æ	.0˜Uw¹¹%',i\ˆ$0ßË¿˜#“ÖşUjĞĞÁœ÷l{}äÒ)Æ¹Ğ_–nµmŞ…Ñ¸|°·È`7t½3¤¿4{×Ò¿ˆÍÈÏ#íãĞäÔf¾šÔ¹ğ’B÷w
ÅÀ>Ë¦6.wu-Úøõğ1‚Õ‰™up%qm”€ôvê~Ó‡@>Š¯ÁQ°†ûV…rÙö,şwyÄáV[3´
—ˆZŞòÃÂ§D%¤t	L„§ü‰y—,…ÄÌå *èÊÌ_æÀ¯£ƒ‰#éÃâq
—Jäb	g{aÅ•·TÇñ„ïŞÅ°;¤cæKç€~ÙÍÌó„ª†c!¾¹5‰Å¶4›KXVnCGKé­ØëU@-æ^D€ô{7bdw8¤Ÿ	¹2‹›Ïwr|Ãıvî©ùøË_·/?×èÇ=e=ñL"Hfµìö¯ÚM&<ÀÆ;±?jĞs¬Ò¯PùlWğgFZü#§n—á°—í{§p;îI¨-¿ºäôq””ç©ÃEAéäG]áŸ-aa7)Oì¦Økg~·Ğ­yKƒ£YäƒEP$lø3ˆ‘VSy=Ñ&I<W$¾[6Ê]f„éƒQ™Òçlzß°0‘-¾Ù‘NµŸïûÅ@ÊÏÜÛŞÙ@›Şé¬OØ!ğ	Åd%í™;¬i·¯8ˆĞ»İ«“ÛÏnãÙÎ¤5İÂ˜LH*2/ÒöÔ½Ã7ŠuPªÃII–¶“èyoİ»1ÔĞVWç	wØít…¨Ap3U[w	}è‘‚=ø–jVJ-¸ïN²SâVÅŠ9Ó³­hT…hclİä7°h&„uâcÖp=°m«H9­èû9«º/6<Ô-Ğ'UQ ±Y?'*ò^èYbıÎ$É¢@ÆŠN|ÛA^È¥+K'\Ü•[ñRÊ‰=&•&–­÷©ÏgPßw<ÉƒñH„ÓÖ±fG†Yfo¦ıëÎmBn e’2µöö³^Ë{Úñ¦şûã„ù.Pnb»?McbbHßµ?£¬ø“p(ÂKAîõFî‡¡—6ÄŒÃıÔ …úöthA%À‘¡¦f¹]:¯¦É]Ö6Õogkä:¼Hİq’šÃøCÅ)•Œ[ñÓŒ9"Á|÷ípÇìƒiê}¤I“2KPUËC•]ÂüÙ<Òqy ??¬,;êşxÒ_5²£Z¡ˆ®ñ6Åñ[B”ÿˆéØ¯õ/¾w…áÀ›ügw¤z/Ç†?¹ø¤mİAD6°t¦I®ØG:8äÂ˜N¯Á–(ü‹şSIí~l{÷¿¯œÈä—£AEÅ˜{ÜÍJ¢Ón×Æ7çh~gyRø$|EÙ,$²è*V!vÈ~ˆÎ©?ZuŒí9x§…#„io"|¦S$ŒÉkı¿¥)àşŸJĞÖõ2 $j¨ ğı[Ä™±¦@ƒ¨o!şìÂ³*ğ×Ør†¤A:û]! = ß
@é•|Ç‹ê~®Èq»†RúƒÁÙ†È®Ç'aˆ·dC¯Ñ†-AFP%Q½Ü=š‡è¶È³ôq¢çó‰’Ó×9¿¼#ky`w0œÕ.ñÏŸúq0ÔØg^[‘#ÜS/èÅ’K@\ µÔ óŒ_ ‰~°é¼AõÂe”w£ehTn³Ê@âlm8|p@†£Ö¶h¶ÚÎ C§Î¨ê%Cå[{ˆxµùàï¶÷>eTşäú€L‹Ì­¿^‰q}GƒçÄá\=kQ='ß8Œ¹vêN;°ï¬Ño2t¿“¢ØÑx²Ê4dÔaäIÏÀ ©í;¬{§vÍ“€gHWS´„
È&¹0˜+€fa è]QøÜgrüÜÓÄÉnr.-MñÀF5#5N#à½áâÑ˜‰ÌJÅI/[[€Yë<±·Şë&hÆBÙŞòì¾LG:Sàg'İŞ_ Év#á©îºuÿ~•æÂÈ|6°ôÜ¡³Jt(Ì¥la¶$)ôd{gúª–°¥Ì³u³"wÂÀcğTo<U Û½]`<X7TG){J¸}‚ÿI¼ş%$á‹>å”‹Òãû	M±Ôò,]>{È’;ËR  ñ”±á¯ó›İQ‘·ˆ÷•	é\ÇB|JX–Ü}Ö•¬ÇqøC¬zøë_ ½8}}Ù~ïY–|u}nÍ(¶}AkÊ¯o     QÅ‘¦NDJe ™³€ÀšßL¢±Ägû    YZ