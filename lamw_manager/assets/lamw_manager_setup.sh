#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="261012361"
MD5="0c4cf7b59ee8690ba44954c9b09466fd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23596"
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
	echo Date of packaging: Fri Aug 20 00:05:29 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[ë] ¼}•À1Dd]‡Á›PætİDöaqı°ğbú	˜a¿ÿdÉâ«¢”Ö)2H)ÑåUd¹/’#‡l`?Ÿ±gÆEc7FŒH	k¼Q9YlYtY	£øhl5¶W´Ñº5Óªd!¯ÿY4vßÏ¿¿z!®¹«|ÒÓÆwì»®•ÀôÕsø?Àó˜ñ•íÇ@ÒCn…ê”jêÀ¡„=fòƒÿÜmœtERƒˆ=YGBYõVÊfäÎ/÷wÍÍÌÆÖŞÜp? ü?iıı=r&óÅ§ ½¤æ{Æ£&¡à‰j8æWš½˜lãœ‘ğŒ‹QnhP;¸+İú;¤T70ñù´ÚÔ¨½SàZù“å“àMºÔ­tÿbÓôû`2'ÎR-»Cİ7œGÆ0	z®<Ç¦'¸¿%k¤v¢4Æ)+í¤¹{Ù®‰'µ1åLî¯Ê!ü¾õw»¼ë*.¡ (üJ¾bÛñ í8Bk7x)F?mãV²ÏeblÛ›~ıÕ¬ò¨‘/m“bju¶‰uÌdõÁˆ¾5Ğ¬ó}gœÜõ„KHÀ\eıj !imÈf½ ½ö«³ıÀa
®Ë$ÅX0‘çJ+y}‰ÁÍ"îW¢ PÍ5Ô`éWuır˜Üq«Üï1É%¼Ã©a’G¨ŒsTæ+o7Ìß1&'±rÎ¨ò©KéBş¿í»-ËÁXÏŒE©ºÿ‹HUæ²	ĞÊŸıæVåwïåö{Œ¥¦4ymM"Ô´9©xë«x–fŞK¥3^"0Äãğ^#p'á©Å Q¤"C"0YÕ;|œRC~ÃúX¶ò‘B3ÚìYLçÿ6ÇO,ú%uŠÏšÆ·ÿn´½ÂEû¤kä`¢ø:¶[ÃGkhŞÓ¾¢df¥íYP"PL]Ja&Ş)±£K>§P§›Ş½!s•Ñ¢¦)²~RÕÙ®Ö1F¦<\².©Œ_Ì?ğ	‡„Z¹¼u)–¿Æ+æùè5²s1x§,ô˜rØhÉÇX§«\š¤³®ÃéSDLó¦I…Û&ëğzSÒı®/^"À`@¬ÀÜÂ¡Éö­Ú 9z4J9ëˆ„JUµ‘1¼ÚN‰3^¶1LÔıqÃ=}ïŸÂoô{„#ÎÉ0¦twyÙ¡/…ÓNĞ¶m¡ì‹·ß
RpVÜyºšğW(_ÿ%K:1>ùôLo!|4âjÖõdÓïÇ	ÖËê†°÷|xø0H|1cSA5w:ıœ;³ÜØÍ™à¹Me‹´¯œ`®Rf¹xb2wcRmJ–Kà.€ 9~:ét«9×üÿé3ˆp–kºZÄ\âÂ^NCçû ›åŞÚb~ÚVéév€o²în=_iu˜hÔŸiÃ3Û¢5X¢yÅ<º¥§: ¾â#}d„ÓÜB¦(î»µà!YG4¤áA€zÊVé~&-Ù
 Wœr-âıNHp“aŠµÈÙ¢ª™Í6ŠPÿÁ*“5Árs`¹ÕÿâŒ†« 7 P†c'kÎ´S! 8Xí'a<Éu+"?äçG¾LXè“ajËšíÃÈêa h^àOC·„ÅÂr§Ï(¡@f¶/Zú,¡¾õ3®gÉv>¾kN!À<=<bôÁáâƒäE¡¤$¡.K$n˜J åÁıG
u—èûÙMGqÖ!¶Ó—zÏu)‹0 áº¹oàİxí¦jÌêàŒ4½jô9Y ‰mÇDáÄeK2şæ_x…R¿L4aâÃ¢+9È÷JÏE	+¹DÒTkhªCY&ßG‚t,gxrJ<BÒ#½ÉÖsS3ü)îç˜!rı_ó(ÊÎ‘.ÂÓvºÛ˜âæ¬ƒ¡£‰¨©Et³Zî‹m“%-×9ÿšk‡<:jçÛ%ºŞÎÓ±‘¾âĞ?ckjp”]»œù €É!3$»Œ`*tyƒUÔ>[‡¡zû»®q6EOÕ³!‹åé¤…={Aâ— ×™¥xn³êOØ(q©Kº•(géê{±Ó[ìĞrH=vËW/×C¿}UŠAe- Ü›Æ™^ecËY³ ­Pu‡Vá"½ëÀljm‰eÙ‹Ğ4Û!ğº¾fk¨	Úî¸*é•ûäÀnæØödx€,LªGX©o $ÎÙ(ğØ`t£·úy@„QoY¦6;E  ²bŸß¯„Wp’Òó¡p‰6‰dY¤‚šz Ò/ÊÜ(hç¼ı¼µe@‹e5“ÌµDÎ¾ã×%÷'`…”Ojèyxíğ“`r‘áµôüµUÑŠ}ÒYùfæ°vÊN¦%ÎåÌYs*(H…EÊçF$OÚ/Û)Ö„¾ß#·>‹¯P×µı¼õ¼xõ%ĞùõË1cÄbxMF¶ÿä\ŒŒ—å×ODUÂ
PË×L<8™P]uI^¬@ªƒT©KÔéHHg©[d9']Ã¾Û~+Á¶£âp}ı#'ñ/Mùğf%Š~–1 NÚ%úe!¡;Â„kÿ”«°Û©¼ø€#-ØñUñK#|üwJCŠ½µùş2#Y­´áÇÜL…S“ÆéY’ëhàù¯XvP¡zŒ{jô1Ñ,“ƒ¤`×à`¢Ô›Ø¦ëúŠŒn{ñ(B¿@F­r5¤sÃ¢9A‰wpE2|/†fÉˆWğr[X|‹í2L¸X|«÷›üÿPôƒî”
:säújìmgáÒT±KÛÏÇ‰½FšKX‡¶†°»÷m_ÒÍæi©£gòx¶‘Á>ôj¾Iâ†GÅb©nbÀ•“9sÛè¸â½ÑhBvÅÃÍêŸbSÌ€+RÙ®•ÿäÜŠJhı¾/{óƒÁ‡y”=LÙ<®®äC6}/ >QÌº¢ËãªW/5€
yŸGŞ
'éQ^mXw»ºÜ”Ñ æç”¶z¤YNœ;OGS®šá'ªp¶»öÁ˜s cm=fàì{Ø©Û9"ÑãØ#%.¼ÑiŸM~è2wø-ÊŞğ;³µ¹®vé.ô'ÀïÑrÎk«ÛË;Äi©e¼ œşQ[	·	éœ¸?Ú5~1è»ÅÌ4L|út7ùÆFSÒ~ü»qyh‰gš®ËqVvË“ÁôÔ¾¦È&$$Šâè.óCå‰¶)(âr©J“ŒY²3ešˆ[z¯MZqîJtim]¢¨›ùîk8•Í×:F«˜YÖ
;’¿‘wÖÂïÖˆçD¼¡ƒÈÊM M›—enÌŞ&Z¶íÿmÈ>¼b£8 ê6Aó¥’]ê²6y`]çÿL GÇ€iEş}¿×¯C<Eœ¡ÂLø²8‹Å"í=xgÖ€5ĞåOÊÍÚ“µdwÜíÕ¿ôú)û¨r#a
ñ$ÜÅ÷}Éx4K(/i^ÂúÈBş`úÎ£QX•±62ü˜Ó¨AŸ¯8©~Ã-ÓrĞ•¥€=´7wò‡„Lèp³ëKñh<#ÌÌÁşiíÎ‡ÏõWZJR¦	ıwmĞq¬^3·Åb*Û†=y– ˆb†ºò%ÌÙğz£ ½ÏÒy3¡\@)KÓğg¿x±»Åælq‘P)¿Îî+z«¼"Ì=ú®‚c–Û™ƒ¯ÍÓVœ•È"%ÃÚ–œÄÙ’‡®¥¢\¥G*‘°È¿í|^açØf1ÛÃhLE@ñEÊ¼sÉ®İ-ı|.pÉ^?HËXİ™ßg¶\Â•æ³+µ…p#Ë6eé¿kà¯h¾jy'­âˆÜ^­4™y}Š×(jıÔL³™MB×÷;xïùÑÄ±)cbáWh™C	ågrœ½„;¥O¾¯xöÖpÅ›¤õhád?DÚ#‘,ş^ÑÀ¹É,şmS,çJ{±ƒ·ø¹€=‘iàéİÍ¥Uğûü«xL]F>İ•ê‹Ş£9KÛUŞ`i|8RÈ;™W]Œ2ã	‰A6Bƒb37fyy„vs©èfÚ±°Ú=Ïè<gÅ‹ÑtÉ×Zh†#¹`Qï‰KIr,A;E§,d[…eceeZ>Ëé£«¯MaşÀvó¶@£«_fÁœ5î&`Uó’S_µâŞ¹<.€÷Ş¯™òlh·IœØ24ù­GSˆ}k4°÷ÙÔÈ®6‰Ebõ‚åâ´’Ùiñ×‹ŒÅ˜1Ì’0OU8‘¯ãœîÙÚvÒX^[ËN¹×q-f>òßŠ¤9é†l‘®ˆ-Ã¡ï›=…j¼S€ktšĞŠ8†Ôì¼ùñxÄØ/„¥Ç”Ü ™}vïU5û+Ãğl‚0`{Æc¶İ £$»xš†5è!¥qúÃxÏ¼™p¸ìm½‡[j'±IpOál ¿Â<ïÇ¹ı%üh&­û”G€
F`4ØŒ:Jì‡)3°gŞ‰óDXµfŞ¼ZÓÚcÑœ6Ò¼í—ï×WŞ–àåüÅ{8äñpòAÉã
é°Qœõ4u×/T‚A4¨B|Ë5À¸R‚\FĞ’_Vı9¾ÉR·¡ŒÆ­”?ÍÇxbÛÄ±;Zãêa‰}®†hÒ\aÈ>f¶é$¹îˆŠLÇ¢»ÄP ÷°—ÖÖÊ.ÁML¯~ÕÇd,Ëõ"å‹üQN(İäSì0•NÕ à8ÊCùÄœø)Š6òúØëK'ÙUNï­ü%G¹ÒŒ‚:=LEhòÅòëRğ²İ.C¬}¥Q¡PDsšM@C±×fÒZÎ·Qaê¯‹îu¯. ¡/Ÿœà~ÄÍ=§Eÿ" ´ŞÎgûJkÚËbø“8Eëk_›ÙkC.Ñ,{ÉĞ™xX;äËÄ5Ñ®é4¼'œ“~öFXl‚ª‰q²ÒP„¤+0Y¸ˆbúwz~]Nt3†¿$ÔÅ0£røØnO	’(K[~W=›Ÿú §ÓãúŸ±”Kñõ¾=ÄÌû:äùúá(ª+ÓÁ„?f
ğùµ§îÄ¡œ_
˜=¶YüO{ÊÍÂüw†ÃGzœÙÍ(LÉ‚Ò_Ie¤øhÅìGş¤¡|(wh7‡kL²y}s’£ŠË"YìDÉr˜]³½‰][k++¹÷!$a)‘\Ê`@Ã²jB}Ü½#š9HÈ©ÀÛ¼¦ÑZõ‡€•ÛsJh‡™ç|ÒÒ°òqSÜEÊú|.4^$V!|§PÍ~Â€…Pi[W,ó2²Î¼+REôğÏwø-aûòîf'NbCc˜\¶´:ºG&”XÈ‰Ø”jÍ½šù‰ÖŒ8Ê2cÊô{")Bàè€Ëğş-›ÄÇS0Ş¾à¨ØûŞ³Øí¹şV*ws]Öl´_ ñÃÖL­|{$Ôë„t»ª¦äÁ¶X uj1TÜOùIìÂŠM {İïì¬+<¡Yøüâ×ëK–Ö·Õ#@NCú#Ø—şO¬ş4Ğ‚˜MŞuşHÇ®Éã•ˆyqGùà/Â¨húA“±ó*½ºbâÒ§hÅûTû¯•¬®×šx?¤{›Õc311òúŞÜDx›RƒaU6Ÿ6÷Lµ%q£jP®Ï)GãÄKÚ†xáÎ~¦à„Óù»½ÇGk5ôşøÄ{ª`Ø¥büH-ƒexooicâŠ\Zïœå!Õ™Ü5?¸X7Aèşp"%¿“ºë“4´œ<ÚxFƒ§,w5B˜59×[¢GW¢¹ÌßDOp—è#àU%ß«(Ä%¾ì£¿•½´ë#/~±k¤şŒ
P(3K[ş$uŞdÍù¿`jÀ-ÀË•	C‚£ˆİËêÙM1ó8.ÙÕ_:§…-‚®ªtl«¦ªØòÒ 
Èïº•Ş—síÂÀÒCæìõNşäÁ	PYK¸¥ãMıvÓ®Åıõ_¶ıØ’¦Eeäã¼¶éØ²r ?•pÃ“ñwêéx `¬õ.¬ÔuìÒc)MJÜÛ3ĞíØ†òê=š7ÚÕ£­šI‡·0î 0^…ûbQN©yÄ¬ï÷“R…‹õ¾Ê§©Wub>õŠ´³x{ñ}´¬ØX±Q°t}zÊR‰œCGkíxU!Ğ|Öcf¦ "ì1%¨Ò×âs¡¦ÏúöjÅÌ¿ğOå–«ğÌì÷£õ§=—Aİ‚ïw\r©«Qâ´™´[»şw`¨yƒ´~ÄFuJÍÂ‹“ÊP{›r_a]M¹Şï§“W\S$ÁÍÅ"¶¥§•şi¤hsx¦ãíQŞ&Vxz—.Ö=o´Ğ!ymP‹Ş[*”¡¾ã´´ÄÂãín Lœùo©²lUÂ‹ğ_:wÍ$†ŠÌ+÷½r"ûH´c¤Íuö+îÏ0‹“…œ·hÓ”f_ŒêöamìÌ%©®˜7-Aå|ô¹;ÍyyşüX®êÕƒÍq!ákq6ğ‘ƒôú ÚmW3Tù¿¥!#¾Ùx„´¬¢y‡Fœ×,>qîÛ†%·•ë
Ü%à,=Ç}N›²“ÿÄø½‡¸¦åOSák½ÜTŠ#íÃ5Aãç‚ı¡›nz6BÈ¬™Ø¦nÌ­=ÿÚ6IQöäM"O%O’à‰X&%Jàk$'ÊşWJÜÇ´ñÄĞúôÌB„Î®š2‡át‹ „}uŸƒ±s™‚çVpÚä|ş2b÷â¨„ûqº« ûĞMå'‡	ƒëŠZg-ôZ¶«½W‰îÙt8'i˜’d¼V	"~$2>"çWB½ )%I—1áL8Òá1È-÷Š‰Ù¾|šzÉ]Öµ„˜QBûA$Kì&ıÑ0n5qæ˜‡Ue+¶êÃøœtŞ-ÿFo‹òwõCÆ¿»Jöy¨‰ÿ‡Óûw¨ÅÛkì¾µ1j·ÛÈ#™HÙÈÊl›ÜPMn+”¦Ï|¢šˆ¡¸ú¿5½³ƒv÷ yºg
§Åò„²–VØ/Ÿ8+š¯aÏb¦&Mé5ñ'l»—Ÿ›«ÉJvËÒ—GÓRInÏº¢ş4*hå›¦|ñlvw#gÍ<\qôBõr“•pBêˆ6$
’µ¤–w9µ˜ˆ.Ùg)^qú¹©ƒ['æ*°1`”oheÍJßÅ¨`ÁiÒ–Ír†b3]-0÷Îo×ÃÈ•]£òš}i9\A…%¸±ÇtÌ…-jå?Î¿ÅT¤¯¨Ï	+,-iAKÄn6Û±€{òfıN×í÷+µó‚Ÿoó&Š+¡ SStNÄyt	èPcî±š™l%ÛÆÙrÄjîg¯"ş(Qìlšr›±Ü•ÿÿ¶„5Pëî5ØÔ®š—Ä£}©_2[PKÿÄ§·Ù´0pØåë|!.¦¶êÅè¨kÁÌYÛ><êóq+òŒ×øïiQŠ÷¦GÍ"W:ïÎS+šºÄ&ÀUpÌt5SSş€1½Â+¤ÂİD…(½©æR¶ğŞOZˆájà4imyGyèÒŸµ"Ê[Vã%j¦ÊÖÇükwWkCEa@ƒUF¼Ñ‡‹Ëã‰ïÛgïÛg+ïÊ;É‚€I„ósF
×mø »(œ…|3NĞMÂÓAóékÎXeŠuÆ¤°T$[ç³ıM$I÷¢=ØªŞù@Eüø[ğØwõŞ¾4JWU¶†ï_ÊÒ®H\ Ú=¤˜Y
Â·ºI—°Kî¶Ì®kDÌEüP¬å‚òÚ9œ¸%E‹ùÒêlK*^@¬ãÁvò„óL¨*ˆ1ö9Ï–L¡N¢ZOøG|äOÏTEv
EåóxkUcPñA±VPÂNLG#š¦â¾VÚàoåî—İÌˆæ¥ß®9êÇò+6Y&v‡óMF˜ƒøv0$±€Ìà(;£fĞ¸Ë¹ÎbÎr€³u‡fzÁw'µÀ‹.hç ƒƒŠ8SuÚ=(>'ÍsG6£mW†èü¡ş‡¿•U±u:0ûçQÇ’äı©ŒøZ;æÕÉL×1tÓ÷â:aD¸vÉ©r¥áÉúïi¾åŸBÖµ w¦„¢b9£Ó-2:‡‰›yıÚóS]OÑé9¢&H:\¥_
 
æ \{˜&šãJÎø+ŒH¦à„şò`DÖ_o^{Âwâ=½õ”Å‘p‰,äS„–=¢iücL¥îflX-]j^¸À9iª‹.*ËÆr…cŸ¸}×6ËRf¸00‰và¯¶«R“g°Üšn/{t&ïàXÎ-§üÅ«_T$ç†	¸ÓïŠ.vàl£÷$à ğÈT5°B‹Ü¬(*,q¤WU%LkÙI÷œ¸±«èÓ`ó»ÉIò/Ï5×5ê-ğš(öÄ{]D@ZŞ7|.u–Bí˜”q•S#Š¯IËÙ³H¸Å>Pü@ù&lB7Z:s»ºW‘<Ø~)Ö…4e~ÕÖø¦ìÁ%üTƒ%ƒ,æÛf»ÆT\°D½3ğOÆÈ±<ßPEºÔ€»ì{SÕv7Lë6zlÙSª!åFòkµ9@X€ŸOXäWœÕjğÁŞ9ªM–Ùø	%öÚ‹NXÜÅdk`0ÇÚ”è¢&æ7•Uõ…Øºp_x‰_îH‡©/(¤êö»•Ísdæº‰@®S¬mïUj·E˜YŸ‚(¡¨¹sx+5uºÀNuQo1ø8Aïty*¢“ÌÍƒ:¨%Ûÿ0„EÈ|z|Ü[æÁúYêı½qŒÄîM©^*P^™P/	"µ$~\ï$š²—¤’„Ö„	‘el—ùGQšœÒ0Xo÷µUY‡fmNÙE":'lv­¢d£á¾¬R ¤ËÕŒ{êÔÛ¢F²$QèT¿÷éõKëŞŒfO¾ÚçœpzÅ¸IôÑÚ®Fr·…Êkx	Z#˜˜¶˜Å ¦V]‰¨c€wTg~F{‡‹=çâ;‘©3¢yOôW74
µ1‡AÇöHc”¤“k.ø­Á*¥¢“ºşÍª¯Ÿ'¥êæµ(cà;1Õ²@õ\SRÂäO%˜§…)ÚE$ùù^GIÈC´Ö…©	Íæä?ò†cÆ›½)K‚9™¦VUáÄ^J@PİüXÖø=Xø·äÚÉ¶<@Î©\$¦ğÕ\d÷¾Ô&Š]²ÌâbìÈï¦Ş'®HèÜã­¥$#ÈÈkzÈ ™l‚WÙãA²g½.-oiåp(²m‚YßImÆñtªìPo
ZÑÃ)À„Æ‡ì+ñCCúªBJ&5¦álw/•C¸LâÂgEàóØ¸sm÷Òó¤.Ì{v¬§
Á´ğ¶EÄoÄ[o.jü«|Xç¶w%XˆqqaEœ*3‰|5UÜ±…ÕÖè­İ©i§qŠ&³Õ{ñúî€â*ivËoVj
P~¾úĞ§÷ÿ]éW_ôÛµô%š;Ò@»¡Ç9koà¦¢Ùûçø:`€µËXğİÇ¯¯Ù—(FEó¤MÎĞNyŸ’eJ´…n#Èˆ·I:…8=½•ØŒ–Ø¹¨ñÓ`%Wc“Ò[Œ"eEÓ?Gj¶[&$Sm‡‘ƒ„yÿ¥.f¯ùK‡~!Ù]ªq‰mb;û—-!‹é
_Ñ[k÷:j ¼qÛ—áš¢YAWl|8ÅˆÔâq‘H3%3iZ—éÍÿ&¤CIp%¨ú¢D¿x½yb¬Ï¿§»½)‚D}É#È*â]ø)<ı…ZéåIj`©5N]@+v”‹ r}á„”#\B7Òê#¿‘Ã¦ß2
&h¸»<C+â–­ã‡uVú˜¯UöeîòÔ5Ô¶ÿ%T‰iƒuQÀF[òß¾$k„±İõûe´Íœã#áÜ‡>n¯Ç/§5Æ¤kŞ2a6ç.n…º„‰Zšˆ²h³ü,‰“£ªë¡¥9`e\íÑŞLç–€ÅjOg"•;,Á°¤‰šFşì Ì|\EØ!íQ~^¨q†1Ëeª/Şƒ"á»½y<Öª!ÿ,ĞwORİU^¡Ñú9¿ÚpÇÚõ°i½Dh]Æk1S–ĞTÖ–J0Sƒ®²ÛTÖBtñÎFbgEş‘æô™éü¦>Z±«ZŞ¸¡$¨d6í6è%çdú*ç^R%û•1vÇúy£–ËÄ1q81uıZ¹Áš5¯OBÅâ‡-ö&FÖÍ½5¢1ˆJ"äêj/q¯–ïŠd^[ µa*Ô‰c	z‰ºä=	]ä®àxLÊD~Çä…ƒŞ:<  q.ºïšK8kü©–m¸÷!0 A:IBÆÔüõİ(U&Â>ĞÕ7Ì}ErÙó›¦çr­]Û÷Ó[dƒ–¸ gÌ†Ï@ÙÕxâŞËÔ÷Í’×ÿïtma§ÜÌ}yÔäX/‚7È,ªÓh'iØlê1Ã>ßØ&çALì‡J—=¶–üïİ2Êˆ­KZ4Yú¢4ê4j†·Ì[h¶sÒ
k-İ³‘CÇ"?Çsê$ÿá; ;ë‹wˆ`•ÿš~ìMD	–8%a*¨’è”áÇ±²%®.±¼¨0PŞ¦}6.ˆ^Á‹!°üFLŠ$ø™5Âxõ·[é¥ÏHZNDƒ¦çŞb?·Ş3¹7Ğs×·R¯õèì0¹ Ì—Ê¼Ë+9/CZ„¦­Æª-On›Î!{Š¿ji÷:¸˜.¾³Ä÷Å¹icšyaüÖú2ñõSµIİx²!7kÊg¡(—u‰MNz=¯şcIPì¾d9Í/ŠfÇX`ø·´kËñGpÄÈ5ÙFc¤®´*Ò»Í ”Ş¬}í¤ø§’wúÀ¡ı^š„ÔlËçİã3è°lIã„DŒIXjs/,ª7	:ğH§IVÌ«ßªo? 9SÅO1¼SÖxÈÏI¦´ªÿñ\Oï±şÖ9¸åm´\VL1’8¹¤¯í^45Öœp¸vüÕÁÎ‡¨
`
7ªL–MÎÿï·Ù6K	m× ïVõ‘Şí{aÕÊz¶½~º6´bH
6;ï÷·àu0»:è¶Ìö®0ÆY-¶ì‘{òGx/ÕF¿¨ŒˆÚ€¹Å4³p#r!ˆ@ä??@°„,=5 ‰Øv‰õ²±@Å;Ğîıgƒ’„.jeZND )”äSãJ4ğlé&2g·Gf™#¼L¸ŠşDKXƒMC?eb²¦õhi?tI4:š|ëj!2£X]µ¢ÑQ33ªlÏLhè€:Û-È`iî^ø}¯İÿ3¶Ûi93gÈµ"ÙúVØÃqC+hªiñæ½“«ârÎ?Q°Ğ¡rÃü­ş#.;«s„§;œ*A·i8šUî5@µw¦æpëˆ­fÇ^T@§&‹¨ˆo«Ğeu÷Ú=¬ì‡ğ
hvpC[H‰	 ú Ç9_ö~ÒåÌ$zXH9tšÙ*:SBPï+„Hİ ZæL`m-8b„!İ²—ši†úKéèÃ‘s”%w~¯c— Bı‘Ô&F¹ƒ5c4Î‰FÑVl¼&8T‹Ìp(}Di°Ë%>`İbÉŒ÷pu±ƒí9Úœ	m´S»¸LÜååCKÙãWÔšÊ°U@‰)WV£1¡°e'¼ÇÙä:Ä>²uÆA÷2¡€.³°“™¦òQ'ƒ!<Óh3eÒ­jœºî†e8³BpjÉâ$GL*×× Râs2Ãœ0´w~ì4Ó9Ì?aÑk‹bÎÍON¾SÕ¬ƒ+%Wæ	:2½Õ-İ>’ 	LETiY¼;]Åıå…,šö¯yt:õ]„q©\3¤‰tqŞO™½‚Ø!ÉYÿÊ²7¢¶xÓ‚Qp«ş¯ZD75ø£MŞ·ÙÍ¡ÇZ›&…Ê†è‹<óccóÜ¾wó•it¨¯&[Ô)|]ˆ½`VìÉX»zu*3°&;âWFš*Iñ oê•S±:	¼wÚ±Ôtt8sb0œØ'Ï!Ô);ş6wÜÊ5nÃ©ãóÓ^ÇÌ†|Ãf]ó¾°	É\#Ñ2lH5³®#´t×üu÷B?ÕşJj—¸Şï\æ>{Çû!}¤ÅÀ 7›9¥ÄH¥~×•½Ÿ•4©àşršx_ãû¹'H\†Qì¹CÏ¡ÑädH\w¯A
™R0ãÚ˜!`1wa ÄÅ¶×âS\(A(Œ%º—FOS ’?nğèùRó®`®Ï”'â®êOÒĞapıt²pÔÃU¤jà–h¬„¨œ¢ÚÅ^«§F VÜ£Ş<÷ÙÂàü\ú|:éI9ÓYT;'6  ÇOºÖhƒÑS-^p^EñçÌl~˜	ëm‚Ö¼±##üÑ’EUXcÚ³ˆ„£ÄzÄìb£XßõpÁ+L[º,ò¸Ä…ŒÒ HÚ†¢x–¾›OñÍ¿«Ç]z-EV˜Êñ§§BÔúØ¯\¹=#â¾şA_«ğZí ÒaG±™	ÖjÀq«¡*‘ÛÏé	İëêÅ–ö/Yk|ôŞ®Ú7ø´sÅÃŞjÕÈe—€xäöVã£?øTóŠ’[ÍšÑ¼ÅøÏè”‚™€–õ/!›CÿdQÔ5?Xâ ½Ñ±ƒê¾æ_8æ˜ÚK÷½2b)ƒ:ˆæÇwª© ,+$4>ìv„zúæpT÷l[É×ÀŒÖÿ‘í¾WoñB¥äâÄZË
ÊD¢KÈI¤¯ëSñGg‹û)È¯Óıø\!zRäwNÁf€®,úâæ¥=J9À/´~r½‰tvçÙÁùştAg²Q{/*Mö†~¶
?Ò½åög"&qäh¢©¥êSßAó?ú@âÙ‚ÕC <\#Ñ^–W,îÏóŞ¡«¬yŸ¢ó~ù"Ø²+"ŞÛ'ÑóÉô»È ZÔÉ#ï^.\ºs»:ñ©£Äyµ(”IGLºãšÍU-r´KwVk åƒ°Š2‰ûºÎÁ¢ø‡5ÃüÙ×UõF/Y«>Jw¡NõÓ(ÉÉåıc•fj* „	¡	o9*Èi™D‘a„î‹FŠÌIv75çøîäÚ¤¹´öQlƒÄ0°²ƒÎŸ£ğ­ºAßø7‘DÆ‘Ë¦X‰Kóù[( Á±ŸÌ¢Õ‡¿Ğù¼[Lµ±v\i+şW–Á"ü…jbìæ!.‹ÈEÒ;:Ë‰8[¸íş,]ƒ^„>ÿ­›4Âİ²vEÂ•º¿X½RÙ¥~Ëë÷:VüSDÁå+7úµ	f°øMiû
ø
[Ö<V:åsnñ>SmØ¿úƒ÷ÒãÑG4rHú|Ìğtáz¡6®Y2ÿÂy¡ˆ‹Ç!bc„ßd£IÅÍšÃ°ëRmï­í]3Ø…Í‡Ø•Œ¸š§ÃŞ´·ƒ Ê´jräŞ£OM4Åó+ÃµhÉ[{)¨ËÚñ×!’Ìkî_Æ­s€qÌ×EâuÙZ}€|±İ;
ªEF;¸Dëqu¯?èøR,ƒÙbÔu&vNÍ^hÙÒÁmçõÑ”s[<å:\K]iì§£ìá0+NJÙ>á¨€”&Á5¥õ£át;… ç*¡ÕYEEC_Ë÷‘aG¸œ'.»Fù¤‰,TNf ö^ŞL~XYöd»Šä¯Üy‚’Vó©Ş‡qÑÕù"øŞ9ê‹ˆ6“ÕëTsÉÖK¡‡´y÷©é§´í}òÜŠ\¨¾]ÜÙêÆÌk®ÈÜœT÷ïøR‡¯D€Ÿ~oû«°f%ú61ÀÆVí|˜P4/6U¬®{œ†<WÛ€É¢ùÂ<èe)Ç6‚SÆÃ	Æëu"Ñº°‡~TÖümëÅ ³K4pşºÃ3z¨Êæ¯*Ç/\1Q9:ïd¶K¹ÇäÌÁÿš`òù¹#f]ˆùøGí!±‡Ğ.è†ÎM¯œı/"$h`{Œ\öÓ/Š•†•úí]ËŒø*jdArs±yÊT«>ÿTĞÒ,«[Ç_ù¤æAùôlbtmÍc1€õF«øÄh@M{vã’—¼ÍÊ(šœÎ1'F†¯àÒõ·7çÆª/PO™üR¦CdSa±7ËS¤WÑHm1‰Shåßš%åøs~ŞŸ8•¬Š³„	Ïx¶’»¸ïEğ‘ÖóTîû8/¥mÑ?ãÑ8‘Øº‚
¼êÑ)&‡¯RãÍIòŒı"R•£¾Y×ÇZ¦r;še¬"|ÈÆ¸‘ûi˜/H|«¶³‰ohrÍGcî|^)â.M#ÿÌŞ¹ÎëLs8•á|oI6M.½!$É°ª,OİÇÃsÜÑ~ï®ûbc¿Q@7p-	¿øG=A:ÏÇ{ï—ÉäT	"v	 ; €ş¤L0á™$Sg!<Ëü’^€ÁŞà,¨g•ö#Ì4jã"àl‚Ná¿²Âü÷«İZ±n6M‚<Ú€ÉBúDáÌ/ŠĞ“†$îÛòŸqÌRÜıYƒ¢ã†¸ÒZÚlMµºŠ®G(bgƒfbar¬(½Ù'²àÂ5óòäòè5=jò	¹¾%Øãïn[”b1¡ZM”úúpO%µí„£’§##·@„´±95Q÷¬$º‡!Rg0	ªFíÙå=–XÊX?~W(zu¼ÖHä2»Ë=3nr06Œ ²/ã¾LQ»}÷3Bíğºr+ÿWM‘‘JFYæË;]T«ˆşÄCŞYLó†:‰²ySéd¤Ò%˜¦2¸"ÏôVÿD
>ÜŒô5ÄÎ{ƒè
½ƒ›Â\o*µåu%}…YßÏ›Ğä>åGœ†+9>ër}ªwì‚ôÜ;›¾ßÑU¾Zs/û£V.¿@S)ëŒ$™É¡y2†ß/—3ù#@Õ:,ë‹)À2pª±.psW.Ğ§’@Á¤p:œg\Ë5ædrÕÁÇî´!!»|†/jHğÃ¿©»§ø M5	Ò†XÆOÌ8¹nW´	¾ÃŞâ]k|³{¯
ßï>šmà	k ±wªÌ¸ÄĞS«wãÆ¼Î„Tû4æçëWË£)`)p¢éäåvÚmò·TµmJHŞ¶r¥<ÀÔ“¢jó-Ÿöèo¡_
Æ½5çé¼+9Ë¢°[u%Æ{r=WTöíÎz‰Ê3Ã7gdÜbgÓ°á×çjmÊÅÄ$,Æûû-Â$æÓÌ(¶yÕĞöU9Ş.jÀ‰4íÕ!ù²ÿ£qZ¯CAk¡¦Ù,Ó…e¤ÂĞsˆâNèdEÓ›×Q¾‹ÏÉt~HúâFï°Äâ×På²ÉûF}®ü¡%Û‘‰ö1«ÍøÓ¿£Ù(œ‚çpuÜÖ~7FñÚQ*»‡Tk Õ)À#r9³ñM(¼éHx ©ğëÌ”ëÅµ‚ş5cnÏĞäªOYë8×’Hmï¬CêÂxšü—ü«íÕ×ÌÎ»O¹h®âˆ˜æÕØ#U;U`²D4;u9>`éÛAÆ3tóÓÎuRÌÖŞêGC±¯„Jå6‚öƒ/]·<Ÿ€¹Üù%”bŞ¨ê:›l£¢AÚ{	@tåH>óØˆ£.ïr¬yï	N…S÷>mXÖ–ñà{P÷'Ã.°NV•ÈR2w~“]“|€BÒ±æ¨;‚¸›×¡€>İ°5è÷ß4ÿ—oq(ûytb,İâıĞä9jß)ãRrÄídOÒñ»íÄOÇDš½a	«$PWŞb£˜×$ Å°Ríòç›–ªÿôSÊ¹ÒÈ†&ïzç—jhÓí^ã;Y;œ£,À Úße¡‹·?w@`‰¡šÜ|±u
¬U¸R­ıl×uPÊ5]îgÙttÑ*UKV˜YuñÉJ€3mìR#“U y
ó6<ºÉŞ#S‹l‘,ğ,K4 ÿ8Ö¤Ü§ª9O¥éƒ¾¨ »æ¯ôŞv€© ¼²¨|–»Ä®še`Ù:ª0‘‡÷®OµÓ+°¢Dí˜$ÍAc¶iá‚«$ğ³7©nrš?a“ŠÍÿ2ªì
9|U3
˜dOÃíè7ş
Px¬µÛµ¬÷$dDğ/×ò& ¤¢*µli¯EIİ½¹Ìƒ—?™ØÀŠ?}$™6ÕWMc€BhRÊ÷°?N¿Lı1ëLìœzHDÉ™wº|1›Ğ4ÆQŸN«ßákuV(>ÁICXºÀ$SöŒb 
u®Ñ3dA¢$ÌB’ûÚ•Ã.˜ËX¥VøIEï[lã+“òĞ$+¨®¯‰g“â»ê­“‰iMùëf±q[~r›F­º/1pÃ°:#}­†&èôÙsÄv·nÏéÄBÓï;Á/;Ÿ†f5…Ø‰‰nµë´o?®x:ó€tÆãÖ¾äFY¢¾ı‹³˜ö¤.ôí¥­„­:2¬Xí4¤WÉ\Ç²ÆQªÚ.hNZDO9Ç	-”s^g40w·˜sÁ+;_a›‰ã‹·Î:©ò¤w™˜şì•t¥ö49æx~$ó½Ç´¢¿™Hş2«ÅÈßç;:O°Wâí|éêtIë}XÏ&êMU¿:´ÿº[çä»§<KëĞ‹Á£~¶¤lÄ®»)'‘7¨L´±^ıfh’÷ÖzKÔ^2Åè`bu|]G=ŒÎ@Ú?¼Eí=WÛ…Qçô@†PC˜á{G§³À\µhÂqÍ©jåáQ^:¥¼tÊ—âDõu(ê
ÔØ8,=uN£œÅò¼Õ/€}N‹–óõQŠ7é)(døˆ†´%€!Z]Æñµ´½°~tBİó÷hÂ²CÜ “Î›‚û£äÔ„ÛrÑšµRutAöEšTÍ§vëÛ"÷g™áÙÎWæûŞïÕÖX]qŸm{¸5PËŠ‰ã§ù“:nIğ¨Kêï($t·€Ò©àF<1Ã Á‡ine)½{^ıœÙ¡9ìd©€µG$?—Ukv:¨ºO˜.p”ÈÓëí 	…Íú·g-³Ô8~>iiPÎUe¦CÌfq›¶!§ŸâDjqr/®ç”PÄË=b}½f
#×!ÃB$+Hø–\YµY½{cç¸qOV°'>“ÑÿËÕ­ÛË“+8Ít`o#ª¤ŸÙC…7UlÕµ¸lk÷å-µ™(³F×«"\®ÉGgë¬æäÇxÒ±0œáú¹ŞÔÉ< NW¢=ÚW‹ë€á¸ş	K(ê2“<ùĞKõ„%'öQøÔºÖO²İ€íçºøÄ#'lÿĞN{Í®ÃSFbÀr9C	ëÂÖ1Î]ôt(ÈoÑBH7¤¢£Ùæ­¦ÑqIª49÷ã³u?/ØHÅ”+¦UÈk<j5“ÔÿowÅËÔÊŞiP›‰İW&¯°
;K7÷Š¨gZMúê©ZrX©Wœ¤jsó‚êŠC=[9 ²Òîˆ¯/¾%T‹†eŞØy²›‘ ±xDÎD/:G‡é+ú¨/y]CmïÄ‘^È nùÃ4ÓL,W›ÀEÎ:ÍçöƒRZpµ-¾qôæ§+_ëíwªW?Ãª¯bC×©=áL ”0\£RÈ†Ä÷ÊuAì#
å‚¦†E®İI/wˆæğ ù~¸ˆ$ı×¹µ6ÇêöşjLcƒV!ç¾`³/@'%ülÃ"$+ş£ƒğö"=™Ì$uêsíøÄ;@4µr1®k=óóÌ›m<¨ÙÑ9	±ùº.„!ÛözÅ2Ü‰&ÄP#S¦,„n•â°³	»º<Y	J€IêTğ,ÒÙ¨GŸ¿ƒ‰ššOÌlWkîßfï‘±KJúº1j°S…Å/ìŒñşÌFOÄEZõ~ŠEØ`
Ám„İf3iËI||Ä¤üŞ©ÕÉè)z2Q]íDiêıİ:¨í3YÁ,úfwX`–{<¢
àäÿ`L¦~sºÆ$£“•BÕÅ"9•¹€¿ü´hccEÈŞl6³à»JÏç)Ô*@„TÇkÛ‰»¦å8¦ë‡PaLyÔàORIXl´-–Ueä± q¼æÚIËÿ[´Ğ!b_§ /9_y‚şëŞ€’ÎA¸YBfŒ“ıI_¢ ¾ÀœØ1,lÖ³mö^¹±½D•§95pàÎ05yZ¦ğåHÎ †·¯nQäl#³%”kÙnË÷q!<"b)H²®e[Nvf±ìèJ&^`şç#Q(b õ)ß	BMÈò®	(`ïáÈefk›CßñÖo“g‹Ò—¤ü×EA^ÌğÿÍœÃ¯ógÀ‘$45ÿì¯dù¬=êÁ›¼º9,¦ò¤¿€Ö½–d,`¤¯ª@Ô¤„;)øä1(ééÔaF$j­|;a5Z\3V¶<£R#Ê²Ó¾'p²EFšÙqŠîqJ¥É#aÜ2Ä+0òú8$j›‰5£¤Bå¢Ÿ$œY…Œó§–6Œ»Æ áJf—çxÌuÈŞüÒ€£@÷Ø] Ñ	÷·ó§W†ıªoAƒÓ}©¼İûuı¢r“k‡·qiÙ<æOüİAA³øõ·Iåàû¶Æ—(b:ÉßJ7"û‘ Á[Ø‰p†›$1Å„n:ğĞÜ‚­ò,’¥äÉwªÃçÓÖXvíôÊ}m{¥e1—_<‘ËföªHÏÇY»[$øŠˆÕ0g‚X¡'Â.…Ï±pŒç|wÿˆÎ<oÔG4È<bSO^ëhÃ¡lY›Âl/©æ%eC®Ã9™³ç*üé—–Ø¯Lî­.DÉyq¢Ü¤úUÁº$9Š.Ö.ğ5Šƒôí»1pÇw7ši#eİHU¥€œuÔ5Í$GérE«´F.8©ã‚h<7jQ{Œ<t şß¡cïÊh8¼ˆ}2múªlÌ«¢ä¢5üpûzHÎI—|ÂiT±4|)xİ^“%Æ„Ò$UjèmÔ,Á‹b,lÀÔèœÛu‚L>}M½R¾]ƒ"İJ©#ÆàseZâ¾¸[$¤1ù©x%ıüdTÃİØSpŞk·ş F
j3‚""¬67Ñ™dŸáRôŒ÷³QÈÍ§JUrJLİNÒo	>N+noñ¨$ÛFdñ'C¢6ü¥d³«L£Á#¯ÿáv&S½·ƒ™r¦×Ÿ²$¯
ßtq±s,nèõr–?ü9B€€…Ãş ÍP”Ú$£¶EoÓ¯ŸK–'=Õ0ŒüØë–Îùù±|Vª]¼Æ‘\¶¨na">—#fÎ`éRãÄv?Ü.uC$–Û%º{Xo±Ào­'Uİæ¤HXÌîe»í‰[İ2œgÀ_û‡#_ŞŠÒÓ¿ëÎú5€ñ7õ÷ÄGS¡wtZ÷ü,bà)9r˜²"C¯rÉLXs÷d¥"«”ï¾ï±şĞ xÙYÅ#ºıß9ØÍ|¯šÅO%™÷Ôë¢Ê°,¦D³j§u`EóLdé'µäéj‰%¹T ½xâŒVĞÉ¾¢ò+º,½à¾\¢=,•ÒÓbn×ã—Mç§W¾ÿU_IUÛ˜ù‚óæ’ÑîŞr³Ø”]QæœûbBF<h>ÄÖä¥!:D«•*¤E´ÛQáN˜ğ†)°ä"¥èËªçhÁ@Ñ–½DF'«`”q9!ƒ2
0;ÄM¿sÖFÜ‘MW“ïƒA½~cOùáY²vWÔZ VoM	±~f5ãGÜÍ“Áòo–&GvrÍ½1•µâ+ÀÆ]ø$|µ>tT–ŸÃùŠ¡V©ƒt”Šİ;Õw/˜ğ]aÿ¼+èÛä.í4áiÖDû¨Ã°i×)Íql›Á(n,ù¦‰,Î˜10kÌ¯Í,ó„`ôØ%úŞ:D# Ë–ÏŠ]„„öØ
ŸšIˆ9már—]ê`ª¤8 õ{!õ5EİÿÌ0ş·áñŸÖM†ŞÄDİ;kÅI=;ÓŞO­¿Ú¾p”ƒTˆâXûèV
<á‚c*«mj™×ölıÄ¥Ã›‡×<©¾~€‚G1 “ìSSŠ ¤~6ı[ƒÓr"Ô~øm:ÇJÁ¸uİÂÆÑïã}7€w×èóM ¸Ä)®('«üWX ¿±ş²^4»ı|!=6×}fYÄ¯£¢;<´M­|¼5LáOÄŒöot"¯»ªrÙ<œå ÑÆÙÙ3ªiÍY[räÉª™;¯u Oˆœjº² ğ
Ç>–O‡1SÆi'`2İ¤ÅÑ!XôM˜¨&‹—G½.( xp²#:Òì›òjÖ÷ñ¶Gâ!äA; &²K›~Gë1×HzJŒ0HC=qJ—ÑRÌ,IÂïÚa­ÑAÓmÚt^?©9ğò«ÀÏJn6bjmŠë±÷9ÁÇÑUM¯ühR™Pª»˜¥Ù¢IÚ Ó@sa,	|uR1Ê¯NÜ¨¸z è7kØÇ§ƒ–O¨àô÷^qg¦Cûç¬¶¯{ù%İôÜghiãÜu´š œ¡ÂÔ—%ä/ÛŒ8­’lÜt.n†s(Aá–Ä_¨ˆ
aRzVKÛá›ñù	wÙ6>F÷¼Kn\¼vi ± 4ïuÛp<° |a#.R‘_„&Öóá
Ö6\ve“›eQ˜t “¼F±ƒÌ\áP+”u?™Üø•ÆYÂ¥ÁQ„ú»ĞRóæÿ<{É¥öÔ™ŒH8,v¼–0p!…"§fT-ö&Uk½A®9ûGro›¨Û7ñÎU]æobUÜ†æŞ‚ÕìwìWû˜ñÅŠ/UVÏ¬áÁ1m›İİ9/ÂÆKŞû3á!DÀù·`òĞô‹Tñ‹²IªXÏßd ™6÷êW6üé‰ãŞç;öEä„{ªŸğ×‡A?¨VTüŒ>YŸsT[6Ï¹›¡Bôµfç°Wc_KÛ€F‘¼"ìø÷ƒ…ddÊ^V Yú_6¼·§Šõh¥.a½~} D"5©›V0éşnƒyóNz8u¡hc‘× G„ÏéÇ£úwŠöx5 éTÈ‡¸ €ÇK å6È@Íºƒa˜»£ÁøÎ‰Õ\OÉ4H—qÖ"©Ô(ñ4ÙµéyUBóŒ/<ŠÉ€=ö >Ä©ŠÈØ)À5P6|/§%$@dü)û»È3œ|©§(Û‘)”G5¨@ÉĞÖEz·Åo¿Ze†„´ıJ«g­øbXİs£-„NøG?»P¹FÈt/zq…6š–gkâ·VWp˜ø--ÿ•T%‡'ˆAa¿÷şDOkxp˜ÌÍ4#rhºÍJåà›èbtîMyÊ¿Û˜dj=9dëÖÖ¸³
é1o^8Ç½«_LG6EîÁÄŠ7ŒıïîV¿+F€Êê
#<ŸË[«
ÇcÀ	‚1~ÈSä†a~•õë–#Ô½75´È™ĞºczxAœl°£ÖÄİî!)†*ÔùS

´ÎÁ9¶¼DG‚4iÌêXØ|,µ^ˆ¾Rîy,ü˜Ê«ª‡à’2%Ø_ˆ”ó1e.ßìÔünDı€gËÔM™º<ÛˆÖªå¸nàA¾æY~–²¯ÒŠø‚¼zlC¤ˆA+9çû…ı…2©˜:ÍµVĞ/}Ğ¼|ë=ƒğ×'ğ%Ø–˜Ñìâ¸ö^v¸¥`¡^NËëCWbO+wWôE:Ÿ<x_Jéx_ rÓzjSYËøµUÖâõÒÑ3j¹ÜşQ©õzçÑ®“ùC»u•LõhægYSÍìÍQùµ]¢+2ff·`£ó4™X ò´Â¼P«Ë 	ò»&ã{²PâMê+ãŸ+{‚©ª°’ı°ÈŸü2¹
Ói‡U¸ÖÔÉ›.åÌÿ]=ßGK‡T’B]1åÂà™Æ>
ìàBb‰C92-Ç"²ƒ¨÷Öª^*|şûr|V[ŸzLsJ“vK¶È=ƒcò\ßb`†2@Mä_kFu&
©‹ĞŒye/×iîÎŠÚlQ.¬î‡™	sgñ 	"wŞkş§™ÉTµ±äL¼`P“şYÿ6¡O.W‹;@R+õÎn{Ğö‘¸½¦Ü”’¾ÿÅwtX!±¯CğZô¨¹˜Õ~ÓšD<zbMô‚R‚¼2ZD¢ŞóÉ«±¸gµræ<?ü^RšéVÃÈ4/$Õ)?FjrÁ“9‡¾Ùxyâœ¦àÔĞAw'ì%S4‰„XFÆÊ$FØ[rïì² –›Ly¦"°’”:TËÙç÷{~Ş’‰Uì“¸¦îMYº¼túHázüR¸Á*jlÉõ[}‚’Q$èe†¶­­ˆÊÁhÁ™íš/g^YÙlB¸­˜{§iá¬o´ôŠ ]å¸Æ!®…úGme]àŠ¼±m(P©¨a¡ÍĞÙ4Ÿi³Ğúæ²^!“¶%3úëµHœÍk©fÃ;“oğ²éöÓ£N.Ë‹ª¦ß!vrĞA³èoœs|àÃwÓ"’!’‹>ê˜]Ö¬ñH~6Õ­œÅÙ™äB…ËÛeA–?1í•9R,ß.~ÈBb£¹½LF6‹/¢¿>3ë]tËÍâÎ±}4‘&®çšNn¡@ÚßoÑUÌ¯Íš»g?nş¸¾ùùãR6ÁÉ××ÙkÍQ¨íÇSøgÈ¶İŸv¿TnLKÛhZ@‚ÏÔ+Y•	lx´Nã‚º"·Ş†Ò_ÊlSD:İÁøàšõ³ˆŠÍÑ Z…†É²ÖÜ¾ªƒo]›úòàR%U  ¯í¢L°Õ&¬ùö2vŞM=Úù;aö€£0ş?XšóRÃÉ	`P[T^Î®ö•[¿şÜz­|¤ÔAÕÒ&?ú…ŒIŒ‹çµé²®­Â; {^Bµ¨ ö¦c€Ié{=
OÊú.lğPîTÇ>µ{"Şš÷3…˜’è_Ë4l`!;ä’N¾3}E;Âª:ó=ÿŸ iä7á4eæe
e¾E«„în…>‰©L2nH'W¬ìê~÷ÁÅ­nnøi'ÛÏ,*7=ü¿µÃJ9mJª §4Ü`b‰Õzµ(PØ¼u«ô÷'ç!»›Ÿ6’¨ªœAÛú ç%¦"Ÿ«—kºYÚG¯ï%éjÈ*:5—ÊeZ‹àfõ1Èö¾ñ”„ŠÔ‡âvÎ;QÚ"»lòğÑîo†Ø¹7b:ˆ» ‘ù…[<=æŞL±	æ†PŸ–Ç±‘©Íî»9CI6Qµõá;E»¦ªëL?Mÿîïá¹	Ã)†íâ¶.7_™ã³Å‡¢1øìÄ¬54o 7ô+D²’W«Ğø”Ûk}Æ9˜°0Ï"<2oÏ1¾x,´ í7KşË“PY&¬„`P°†PİÃG…tØQÕ8Ù}€ÒYıÙÀô6+Û1vYˆNKÿ„f[)a¨]ÃûúÂ“­¡HË¢c<|0&5>Ş@“HVğAH`ªóĞMí_Mò“ÛÍÚiFB"MKvFƒ{ŞLş »JJ „m-9gaS€#ÀK¿TF
"âÔüì35Fñæ( Ÿß5Œ,âîM?ÖL©è^¢Ğ%épÁæ=¼!]LªM°½İåH8|w°jÊô^ZùLòßsQIàªÔ¦Ãê`ş¹d'­¢¾õy.®eà/) °‰|ù±’ìá|‹bõI¸K¡Í ñJdÔ7³…C8ÇŞã(Åã‹•‰™<­©—z<îìt_j”JZ¨ÊhüÌ”…Ï$Ñ1%SPŠ<Ü<!ç`È¹'U†MÎ×´Ùğ’œç  U2¢)`¤ó/pçc«<¤†%9F—·ÈíÑs—­k;˜‹b.#äª'x6ˆÀÄ¥v&ğB[‘Y¿âà«„û7tªH;í”Íyü³k¹ÀJÇ†IüâĞğ_.&ëy‚ÿG@²À9¶!Ê­!Ç)Œ°Z˜3aî#´_ON‚¥õ–¢
Ô9]@y½2Òı—äOGƒ³ÂIæ†.6*" éĞDj\]0’=—36tƒœ—l>£ÏbÕŸé1½îß`®ÈÜ>|ó¹}J½TŒÅO~|ÔV¿KfèóªÅ„¤<¨M*öx ‰¯¶}(F2:Î'-º´öm]…¨bóÈñ¹ê1«xø+}ßõÔkyRĞ=T #7d»XÓØ;‘WâºpÛÔ…nÍò¡Á&t=©¯ƒ¼^q13İ»„Eˆ QÙ…pÀFó¡ìW`’khÓB%FLzÑõ€9v8;f·hH~ÔYÂÔ•±ˆkË„sìç:zƒ$ø´ú%ñ¾Wé™Cíhb…¢»Q™/C?qpT¼“³^A§&yÚïæ˜hƒVôñŒ6WzòEaózÄyúX	Fœ…J¨¤Oöâ¼qºïbSÛ- –K6”‡‘
»ûLªu“0ÏØÆ·–¬lêÉ_ñÊåÕE¦;7o¹^`ö/Xˆ$ôäó½Ì]Üj¢²ná+$äùĞ ¯äì·İÔ›\†È xQë¶}‹dvÈEÆT&ÁÌÅ­š·í9œXzoç`t°³÷µDáñÎì:ÉÀ†™xsdòV…¤ıˆ˜&rßúnq2QÜèê>{ïkzøòfNñBláá9²†U—„§Y(ŒRG\!q4Á‰Wi(²OúxíÃ$\ñ)½,ËÚ¿VgLb®ı¿¸á–)Ç€¡â"öİ8ª‚g¦ò‘¨›ñVCDZºõ`NøËæM\á¤,0‘¢=°ØÒÛR )³ØChşHøİ;rŸJÅ}ğ^UdÆ”Ò0”NƒÌQ^\H/pz‚“[È³¾VğË='ˆ«@Â¨)¨J/1RÒkÃÒŞÅ™=®uëWğ³–;–Öª€‘}¦¡H{ÁÀÒ¿›i>P>KD\3®â g=GóK%³¥‚»õ;°­ğ¸ØhĞø+D/ã‘"Øì¦<ã:å'©ñØÑu²çŞêBëÎÌ(İ­RöuMóF>Æg:Ñ{*ô0øå ²ß€}ÜrÆœ7mÖS6NÂ7f¾-f¹7oñ‡Z¢j„Röm}Dû.QÍbÈ¢›;›f¬”0Éïw ]gØÄ¥f¼¹Ö6Î‡Š6¸˜iËB]cfÒÜ¢&¤s­ğŠèÙ©-t   õş¢Y‰C-=Ğk$^E°	Ç°ñ°$âï‹Yşâî`IN-š 92œçğDB%*F1{şT$.øq•} ØI3KDóaq İ¨‘ùËA™[Ã[–¦P·ŒÕúxÚÌáß&-F†+î=
îêG‚ßWø1o"êu#ún6¼²QHÓRŒX UÂtJBÑÆBÇÀC}»Wr!Xs&!¥.µ~G6hR¾ŒŞıŠ$ØROšî<ôè$Q4O½s²¥İ ı÷ÏG~bÆ™(Õ¼¦ğp›1˜-æ¾XÉ±À”ö±e·T§vóğèD²ÛQ€ FÑÑøu/šÿö‘›İµşÕ_OÜè5ÁröÅ,¦L³¬K”ôÍF~^ı¢^î«a­˜$·wZ€· %öRG9fGs¬ÌåC	J6ÇÚiø“{3îËÊaUlmŠj×ÛåÕ¤ˆEÆ»V¡ÊrNŒ»‚o¸a•¯ÇÂö 4>¥Õ?»ËM¨+ç×}@‰‰ÀšBnUR3¤
™VwæÙEÌ/€Rààâ1àäÔWfßZAS#È×ù6ï¢‚&'ÄîåY¹4¿Ùİ¿‚C FqAAWâäÑH2î†²Yïi°ÑêŠSqtÌÔ•n"Èp¥Á¥mªQº©i”é®"jĞ	ê üTD,&JÄÆ8Ø¸`t‘ißBğ>kÿ‚pò¿«õİQ2mùU“ïFõ}Y¯¡g(§@hß(õ§A=`ºĞVo"áY%D÷ş’£©9‚,Ö
dÒSÒ½ùD§«¦£ğ)F Ø¾kØ•œÅÇ^~
ãb–ÂYÁ'”µ²)CS]~è` †¸è4(“K×rö²[ÖÏkşN‘p©Ü!X¨şóè˜ğ†É>É€­æŠÙ%4%%Áé±ÈªĞ|×òÑB·û&˜#Y•¯-c Í£W`ÚqNP.*]ùÿ@	Jw„[õ›îÜ”@ÙOºî.á´åÖY=cIÙ2æên;ò©6˜'ÜìêÁü/p5dâJK ùµıõ ã$KÇx¤ì¡ôO ((Æ¸Š?MÚS'°
lVóÂ6Á¶õmd[‹²JåáÓ•’iÇ÷.ĞTV%AA½·W{K|â4ª2¨li¢QsÂ"ê“¨h€ó³Şn„+BQ¡
´¯Ç¸•3W¹m[n6ë••ZâHÍHXPò‡·¥<³y±“¾ÊºÙ!Diå¾¯zÕõKè|¹@mUVÁ÷5ŠnÌÕ3a“LÑ*Ø«yP¹õZò(üLøLòû4|îPïÆ_|G Ÿ0Èq/ªÿĞ…ßULíL­áËş¿İÛÌx“†Åû[‡’êÇAÅê5P"†€ªİ»’ÜÕ5yÍ@ÿß ã¶PîJ8‘BZpüªä_‰„ıJpˆ«§ìpn†…"ÑLÚvg‚cK73¡¥äa
ŸŠ•&ó²¼9RãÂëŸ¯\Uf´úï!»(éó|¥GÏaX¼c¼õıÁ€¼‹°Ôr‘"Z'à(`&„`zıÆ¯6#^kº¦¡ã‚¯…ğñaáÂ•E3Ï“ôZÊbEP%@ éÒ>U­jf<ğcùèkuÊ¹(02°Šg~E±ˆÃÊIU:ê=çÏœÈÂ|>_l@kZˆÂ¸78áâõ¦÷’7z W†ë89z‰SæÜAàƒ2´Q]:*nÕ8D¹öUõğ•—ŸRçÚÛ¤`4¥<©nr§s­hòb'ñvKƒæ ¨s¥ÙOj‡
¤o×ºğh˜€¼ˆìÿCˆ+ˆwh äß4æüTuSÉ° ÕÎ’à2jNÎ4-„×`	cÈpµˆäZ‡ ñì‡í~DŠ¿´ŒB§-L×•ÎfæhÍÓjÔ“fÌ×¨Ÿ£Æ ÿKWI>ÇşÒÆÚTéÜeä×/ºy7º€®«* •ÈäMC¯EÎ·3EÑNşÎ9£²kÜ¥é'‘H‘ì8å¯`W$¤ªC÷sPÕ‘×VF\“}•Ä7éÌş0™àhÇcViÑyjRV·]>Ü0«ø»Aâ‹cx”IYŠ\ì.1âŠ D»¥vß©L›’?Ÿ¸@İâ€íh2¾üsjU”<™_¡;É,·_Zèëv\„°¤ùËù]ÜW0ãÃ+êóu~>~'ä±¿å^vÊÌ=f*Øñ‚ıÌú±¸ƒ€¬ÜœH‚æİU÷±ë;a¹X?ãAI%Xf xÚK1ÊIcë\¹µ-Œ~®ŞÕø\Ë=
"™ÕÉ@V(IÚKA!ØpQô*ºÂ\°kÅy70V+í8kÏÍµ'		æaÜÖM¾0-¶zQ£CS&ßr ]©1ÃrY“3ûöHà-_Ê9|c–	Òe;•šWª›ıL{8wÛ	íÿ«I•ÅL†á¸:íg‹{¸©Şc_}†vÃ‘ğèèÎËšÎ!Ä™xşã`ûµ¨¹*B‹øP3½Ù °4øÌ\½”íZÏXx™ìñZ´HsiymÂÊãê?N½[šjì{ì€ó­DA,IeëÀtaàÂY/	‘ãƒmTd¶Z‰y²³gª—ı9gQ”ËÑŒSËº<rğ>¹ìğä‚™õØë¾@8WUDª¼oe¾øÁøU8ç¹"Ùü´«`ËÜ1\D”
^K5ê,5fŒµºø#¦GÌ“ YÚÉMÑ‰)YQHùğÔ*Àƒ¼-Š(‡YSgN£W
Kñ«2xÔ6"–Pã@õ“]®<“•¦>ı•Çpeº¿°5}ƒ­Ö›¾´wH'#]Ğ!=Ñê‘L«EóÎéÁğs‘…çãŸiœœö‹IQGE·ô4¿‹¢aÚ’Õ&dº;÷¨â}L55Û
t…J·[‡ù??O*ÆÉ1hÆøşI³ÊŠ*zbÊií}vñí|ù³<5Go¡Uë²Mi’À^U8ôwôº5”a	¥{‚øä¼Œ­—æ‡»^OrÅé}»N°¯H6´„OzTú§7ú´Š´íö||¢Ê×óÏ0û’›Ùñ.Øƒt#ğ'iòW&÷ğ™â2#C²5©@G.‚÷à\VÏ‰Õ´F®´^t<‡i«¯yrŒ}¡ÊĞ_ÍiI‰*tê+'0}uóˆj˜Û¦vÌ+D›p† nSÿAhÓ£sŠåÀAiæ€ûŒŒ•Ğç‡GX¾©U@*‰$Õdujx?nœdqqÂÅ(Qhôc]}X	¼)öJúæ>*µÁG¬¹h¸=ÙGá`Í[üán\FÅiİæÚ"5±Eg6‚#r1j6¡_öNIÀÒ†ŞHóÄq"şánÛ#a¯‚ş1±)	S¬RŒé×›Ôü¢K+Ú½DÒİ¹ŠcNğb2×D®êtÌÈÄltoç7æhÄQZ¯ğtÂŒ¥ÉUñPôÂxÄ¼=ã/"ñj)ô¸¨çà07z “Fix]÷ğ 5eÉVfÁ+yV+Õ>ÈÕ²¯bMôµ`V´ºÁÒQï !6eşÙ¤š•	è2j±$ı¹¾TÈßµ‚İ9zX*+ô°ªƒ„J­©.9Ì»ıkƒ§çnV¶V–Iü*1È¯Ğ¡¿Qö©`È%(-$:Öòl)ÿ²Ï;S»PR&:»yJ9jUp|à…&È‹Õ\'‰ØNñgöü†pqfœ7ÔN…·©ˆm¿Ìá°dËÁPPİ9¦n‰>¬>¹ætvGÂLò¦üÔ!‘HfÊâĞÉ‡ùÌ©ÈÇø*ïz¹KèŠß‡iz¾ØÆÜ“].^åhœ¸Şç*|ç&gÍ(]IÛ=…Îr4ì8´sTšÖ<4êÖ4ìà¯³p¼ğ …âE~<É»ªi!..©…R¥)Î _h“Ñ“}±ĞIÎø!QÕáø˜7•UÏë@¿\§]¾9>2ÎB|¡ÿá¿èD"oñ¹|/‘ƒ{j9/¨Ãùe%šÔÊÚşÚX¬gX_ü?…¤üüwô¼”€÷µ iì×Gå»TÎíãË¡d#Àöá ?†Ñ”Jğ¢Ÿóv(ïNË´7¶¨`Ÿ&éYºû¬sïf!õ.›±Â[¾eıªÎÕ˜ı} )qèK•%Àü‘3ëäß¨šÊ;ß¿6f\²›ı{[˜,×X|?Ãægø)­­hpÃÜ>^"\§Õyu\¾–t:å‘_	ÖON³²,++^éÛÖZâ’ø¤:~ğ×ãü:b®…•ƒúG»ò9óÌŠ³G&UÍ†°ß›p¹ÂlF@H¢Ç¨Ü"JXB=Sœ’Ä³9¾@­HÚ„|Ä«UiäíBU¹â“Ôl›q^â\H¥¥iXŒ£ûP(†’C²¢¿ñi@R—ôÚ–g^’£rº™U©œˆsùxi\â6CÕÅÊƒäÈfgÇÙ¸Ï²Â\ë Ø†Ô–‚
ÔU0`öˆ{Å1â¦ê-2é·ËÂ^¬Î„Ğ­>*¤XÖ%r'šêNzj«Ìå«_<Ä+E‹t13;÷¶™„•/ú¥öD%èÉ$É¦¬bc³T'õßµXªp÷ã>$¦_(j&){’°êÔ.ˆ2Ñgz”˜D€ı&Â£6Äw¸§×)…¶Î´A„uÕÔº°ŒvhCvrs7X ¢»ÊG
ı¬“·ŒÌ=ÙEôøôó[¯Q*·ÒO ñı¤Õ-µ!Ü©Ó•h1g›tæğÁcÉ‰µêà®ÊÅƒ³;ê{’ââÛ–d‰ üYyR·ró_ÜH‚ì*{ÊÆ0f39Îğë«Wl ImjPá1GFg—m®–ÕÓĞÂÓl±dÅœ_áKŸ<œq'ƒnß561ÍyzC¤÷m²
‹ş>AJÓË‚+ğæº„2Ÿy|ˆÈçã’ûOÚ	7aÊ•°7#„…ˆ‹ÚÔ1ıG€İº`Ê kwÜùıÑôVòáµøËù<ÀAõôX§¢ÔUóqG"î?^İV¤€Íÿíê	*[×dh±·áİzOÁÃ/ª)D"ª8P;±%œàó*°¶=ÖˆôT³o¡?«,hûEÁvıH¢K¶Ô»‘u%Àãç&!²Uê¥5ØåªŞYÜFÔ;Ö´²R–òk$Aôî+æĞ’'ˆi_$´Èy
eµ¸ìHˆ/pKë	ezçæíıĞìJ§²J8gĞÜ'§‘¨·nÇÕ]•}^Ï§pXó|Z7uá1İÍ¶—˜O›xÖñˆ5“7ÜºR‘¡úYfDh·l:¤hg`8)doP$ÙZö½N¸S0&åi{-ZËªâh~i²w Gã
8WùSxÿÓÑÆ‘Ù|?_ B¤B.­–;û¦e¾Rps]b´*ïİõ´QàÏ?7Õªh€ÿ¨ıÜ­Î!sjÚÓœ>´«°/yŞ_Ù«ø$Uß’€Z&0-ëç6¡g;jğ¢ÚhDÎ„òw¸ó?Ğ:}¹>×{£}á¦p>9€¾°Ïú)KeX({ESÎÎ-Úy ´Êê_‚eºŞX¼FåQ+ëÈ¬`áæÅ·¿$·Q=$èßĞ¸	Ôá{âá¦wØdpÑhÌô]á¹xŸËÂ”`8"g0À?ş‘¹ú\Me7ùÈ}¨8pİGô6Êş47_ÊÄ×§î€¶¬ó   ùÈ/Çå·Ô ‡¸€À`@ì±Ägû    YZ