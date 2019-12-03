#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4124485585"
MD5="0577e61c0bd66b33ce9011d6b6b0543c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="16940"
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
	echo Uncompressed size: 100 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec  3 14:38:32 -03 2019
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
	echo OLDUSIZE=100
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
	MS_Printf "About to extract 100 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 100; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (100 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌá?ÿAé] ¼}•ÀJFœÄÿ.»á_jg\/­xÓnyúÑC@¿b1¢mwíc;€ÃXÎ¶,?g?å%½àôò#24V-X6ÑÉcÙÆİ‚RC	Úı—T,àîXÊÒWÜŒİÃõÂ¾2?1>»/nz÷‚HzKc‚¶Rì—ö¨*h²”UI7ª”i3‰˜â%( ½@pñÑCåõbSdú’–¸&µTHûBN+œÈ´!%æ´ê95.À'ß¡fÜl8DøØ ^(İ8ÜNÏ™|ä&’d|X{¡Y‘yv^)¸^˜ÁÍİdé•Èå”¥YÊRŸµŠŸ÷éÉ*œv6ƒ¬üOTÒ„Û!êf¬„OÜx8Şß”|ZÈ©#G84ˆã6Ö9M1²Æ?Uÿƒ‡+6ÁBàõ1é>÷ØË‡“4Òß‹¢¦„~’íÚ-¹	 D¢¥ßâEP#1á|¶kµ@…sOêõëy";åœr®§q¹´îİÊœwèÁ¯ïbà±Œ!Ô!ÅÃ
ÅÖ#À‰’¦õ¯§Zg@Lˆ‹°º3šá#=5®Ÿ¡›šÑŸ×¹ûƒÒÁÊ3ßD÷>ÏÂ‚¥›¿ë ×î`ë0WÓŒ?Æı%ŸG¥à`hàÒ”åäáŠå;Ô|ÈE9Fü´hïº¸‰ähı‹	€Ï%ß”İ§¦sUñL5ZİìBÚÖ—Öoj!ü5=2òs±>Ä¥@„ÈEâ1‰§¾ì’GÍìX†m3´ı&ÏEgü¨úZùG€Áâ¨¿gêÇeÜ#_nå®œ‡s¹æf’b«ĞFkÉQJA¬ªä¸3¡ë@Ÿ&|bÖÊ* â÷€€ º6ÿ/Ç»FĞs7ßô†„Tæ*HWë}™‚AlÃü¨şÙ#4påI_8/é¹<?õÜ’ñM[éKÈ…Ü(ÙÙ©ï6Ç¤cŸjü[ü×i@aô®ğøkuá‡á¹9ÁşÒN°L<'Ÿ¶áòµ5?úK£YF#Rœ×¨Î§{^m‹ƒ5¯çè©í«¶ƒX`jÊ{gYğ÷:õ²oà$Š—IğQŒJvôö$…šŠõÿ,	?‚Ç*¬b‡YŒ±TøÀTéai)=Î³Tß
(åw.šè[4EÆ;îú8€à×òáÕü¡îœüÙ#$ƒDVÛH<áû"›„ÅšBëˆ	GóÓH…ét®}ñ‘}4>²Ş€6½Ç#9¥#(İ6ÃPè‘êÅrô¨’yı¸\,Ë+¢’h†om˜õÃóûá´\LS¾÷N¿v
à¼Ê¥Ç,vä%¯ç
‹w¾Q| r¥õ‰—ŠÏf›Ì)k¢¹*8Ø^d˜»N›Ì$·ıËæL:ã`{§ƒYaEİÅ$2¥ÎWYó©â„wæ{©§ ‰‘Ïfw{YÆúç;#İ,-mB¨Œ§ªŠè‘†IüôÄs®ätÂ|¨§ıQ–§m_ƒüÊ%B”Œ0;¡©ù3vkŸ ø$Ù'nıñr¼´yf8'Z/0W`c»3£…d’[¯ûÔí¸-Ë£åÊ<OŠàÜğ¤6•*ÇjÅfCÊğ]÷GíüÁVóàpi¶."SÓ+93ôñß©J©:©(š¸†gĞQrÓJLÖ#iØ*U[ }OÏg~^)ñ€e)k$P¢`£~ÿ¤É×Èe2;ê‚Ê§á Ï7g•²ßÃ€ù¶'x}UŠ-9Ü™lw)1âêw)MÅ04*·“	‘~ÃÆØ.áÛ™3)ŠÀ›=òÊrŠ”ÎQ¯Œ 6St¦QğWK`æÃA)Ù~§J-ÒYPëçHKÒ¶ÓšöÑşXÛOç-™ÅV)êÍfÿ;®ë‡–oOäÑ°ùü6øvÔlÊO€CòÌÓr@G¶ã
×|İ5 ˆÍÂRò’>ÿ­ORY¤œYÂ7mÃÄgã7?¥„fkùhNÆa”Ü"[Õ÷Ğô„Èä_6°¶Yô
³Æè2ÍŒa‡W”Èœº¸á†¸túlJÛŞ^Ëx®—/VcÚgÏîpÓU•‚„V«Ç‰í·à³’*Í™m?'ËÉv`Ç‚0nÄüÿ)¹/Rãto¦¾ã5Zš†Èh•{Ø¾uÃÁ#À-Ò¥ÅıeûDîkH#7$k´úitêb‚»°ûI€j›lpC¸ åÑ‹zÆøOü×îÁ ì#®D	`!£sÍ¾Š'‡è«¯o/LrİuìïŒèÊUúuë[ ğ¡…V×€®ÓºÜÏN‚³¦kH©Ä>E¸7Oe<ü8 í|Ø<_8¬B¸\€¯¶ û™™•E qn›îóry•áR¥RNûÛ’p–Oæ»t¨nS:é1în¢é°›gg„©ß»ŒuÔú»¤4!‡O.1yqÂ¨2ô½]dn•'VÄ)Ş™¡l9i¬<«ã<µ•IÃÖC"  {z²étËœgI^òtéÕ›#:êy5½RKÖ¹ÉEC¸ÑgÖØ™àR³üşÒërİ¢ôªsm¢2úxm¬I``¿¦“ÊË€ÊU§”Ê˜’‘Øz Àeœ²8:ÉMQ>Òö‘a€¥ÚOôNºQ!ı?ƒÑƒ½ÃAmêíñ?¨qËÅ¢ØQÙgV"x¿,xâ7>[™»¬À&}~¾‚ı”ZN÷ô'WjÒQ<ï6N	ÓsaÇ¿ˆíî„A0–pnˆ‰R±ˆ7êš¿{˜êÙxHûëòMä¼«¾N×B‚Sf½g¼\$î÷ëàj~íÚHë¤<®)ÏG5 Æä>Ä‘çÈ†Rïõ=†Ú,Ô©wG–ÁW@íµÇN·Ò¢Ö™¬FX› s	$î»íÓIŒVg:±.äTï/edò= ï†…‹eå²oœc5fÌ•õŞ7vNŸ¨Îd©N9 vQÖ79¯‘¿^ò&"s0%;×òB•R“‰y¹óäf…¿&íçi)Ø°6q4Îi—°ğr9ÇaÓ@†Ğbˆ¯ĞWsLÅÏÈ—Š«mÕFx¨(š®°Á ¼Vª“
ÄV•i\„3ï‹äÃZWnºù¢¡zÜŠ:½tH3äãGôÜ/ñHÑN!”Å˜àŸ¼í1‰_ˆ 5mA_¥÷Û†ñØšMcÙø›ÒÃ"Ä'
ôkÀĞÃ@Á›Ğ)\­ïYï­Í¨ ô·ª¿¼¨1¤I
:üOÕƒ;:—È_ˆ»®`íõÍ³%ûm¢e*ô¨	 [É7DôNåØÍ‡b¼õh"SßŞ°µ=©Ù,¸Ñ7\4?ÓÙà³¸"Fz¥ÓÏLıo7Ï.©½ä¶›ƒH¿<gõ,ÿ`WÈ
°¬	GÅ8ÈÀxKÜİ07á'ÔëO©à>$ÃTÜûÉyŠ©ÒD¸Ä2¹Î³bAq’móÓ³m-åùô|Aùç&ëÛ¹LÃH\¸²ÄXÿbĞrÔ»g€ü0¥L,Ô¨8[öøŒv3vcÆµó‡OÕ€iO›¨'#|èSeTÛ2<ú2l«.›[Ú£µ±‡ØÂEÄ¦­nK¶ÕãO¥6q´MÛáK—271CÎÛèÛ†O0E÷^ÉjzğÏ.µ0\§üÔp3GÂ¶8‘BÊcŸ	m/æ~>·¼]$ÓNôñ/E–P¨FÙ­wú¿Ø¤d'QŠ§>"ŒÊR§< ¼G,#Dù¤÷8`ÍXƒ.õ{{½Wò§Ô]¡Ö—Ã^@â)™ç;ä, ”Óøç5gDÉ
ê»‚„ØLğråì‰¶BZï©’"ÖU¾•:uñZ~™‹oÌç¹Ju N]Ç‘(Çı“ò\sŞ†Sê~Ãå^‘ÒåU'ï!iŸc.s‡HÏ€ÌLÇ-)‡„8_ìQó|s¸:^¾Zh“oHKÊĞ¶1kf(`etÅĞı{ì±`”süzFÅ³yÔíÄ3¿NĞkB¶S1
¥ÎVaNå¬5v™&¸JoUpîo¨¸ıÓùô•²NÖ%‰ÄR¢·g(±ékƒ]ß¾ÆE¨éä÷óÁÆQ’œí[<p·’¹°Ã€Ş˜q/)‹ÅpÙj[Öb2†BÇ/ïxá„a‡èüÍ!3e¹Û½ÂÇ‚Á'£ *Ñïq}o;w9§8BgñRûöí.£9rd`;SäÎ!Ñ#ªõŞíİ‡ò\iùİÆ…[¬ÁÑÛ V;Æ¦’(Py,5ä‘vµ<\:×Ë¥ıÜ³9û’fp7s±/ˆÎÙkÓ°a¹Ôš¦ZD,§Õf¢Êiäµ–÷y"·PqÒ Í™ƒœPÀ‡»ÄóWÇ?º<z«mï@wóÛW<ÿë>ˆÏ­|Ü¸/©:‹œA(¡€×ş,'V,‚…†¦Dü7zbà~’N— ˆ'¸Ñ™L-Õ+ˆ	~¨¬¿pÏ§WHŒÌš¾î‹`›š5ÃF“íqÖGÄÒÎß½v­„ZgG¼Ö¥Jí#‰ŞÕ$4÷øYÒù¨†\ñ–œueˆR`ÓGËŠ)ïùGKª¯Æ'¤÷\ û§ªNò/A
;»×Rùˆ†5Û£÷DWø„‹°¡o¿ò^Lşî´í•‰ØİÈÈ#¤2³_xö¡•¶a›Î6Ú*ØO­×ÎLh¨}+«°8œ7j"†/ÿN+j#¹ÊAà]0Úè9±¨+2ì]wxuœ0 ìá\ƒ»yR†]`°¸ÊÚï×‡ê=ju|pÊ%¼òG&Fsf(O¯¶Uåö÷¯ÕùögÑ¯ÓÇHÓ;wÃ‰ƒ¨ßÿ‡Z‚1'š^\îğsù†˜e>aû Ş=J'ù‰­CÎ9ŠĞ"`Ÿ›§Ä¢«rÒûïwf× ˜—AfT9^ÑÕé6:oĞ$ŞSÅ¶¯ÙYß[õit½ª&á}q7¼n~ÇØğÿ‘/@¸AÏŠ41
ôdGŸY#T$S÷J ˆ™£Ô$&jh:Î@}şó¸"}Ww3QöÇ%ÀÇÌ‡¶Î@UIÿ6Ee Ôİ¬sÅxK×§\i …Pìw€V©µ6 —òà3ÕÔ+q°ç¨y(Ç‘}ñWœ¶;ÅûYo|< ‰ÛŠŸK$Z¢]ƒ·ò‘DNÆÃfuõŒ8Å²`uä$4ãNØnQßÚ"ww^a‘ ‚û×ÿrä±6î:XÓ8d°ª»"~d_Âõ2¢ƒ]F¨—3U††H˜×j²[>èF‘oß2KØè8óìşN¦cOÅ-G¦gœOiD- ãP*éü)"+ò&«âºÇŒ7,¬®äzV…’U×|îÇ¬ØÅ›0dÅ'póì¥0ç$‰ïE‹VºîÇ%ó!Œ ŞÇ-/eWÓ¿´“EYš½õY;VÓ#Ì<†¿vFúKñˆU'<ïÅ¾#K°,ÅØùÒ|%™Å¦Ïş{ƒÕ<ÌöØ1Gçˆ8K¯ê¿Ş‘½z|4cèäó?äú4öÃ²=Ò®Z?bŞŠÚë„¾g¯ØøŒ½IßÉ¡÷Y¯<ßâÑ6Ñdµæ~ãWƒŞC3•â‚~«¤9š0Ç±Š&2DÆvhîQ^A2¯0p]ğcujıÊé9\Í”EñÈ5[Zœù¨yÜÃkäî„©½àˆ´b^qŞØmVïN#l‡o4;UúøÔ6NÚÇ¤ú¾ĞT¡1ïB“µ¯”šéĞ,1´SpB
Û.·üY;u´*@f.¥§¥Vü“0Ğ*Âu†7N-$TÂDĞjI‚æ@›]éX<Uû{òÉ¯îƒ­øÓÈßÚª‘P‹Vë@¨Ì4Ëı›‘Fq\À%^lB˜Ê³÷øï!?3Bs¯A
:ŞLw¶Y¸F¸ÀH™í‰ÿ#Î¿?õnN2Ğd¤Ès†á³‰g*˜‚Åw¥}ã¢—\Ã,ÒcğtĞî’ÒêÌµiã•”#l‚UVŞ`ßÀ0£D¡‡¯€™÷ï½ıÉZ:æRşRMC cİ´nÔX[[İÔ2ú±Ø‰©ÊéÉzW“›kXŒ“&Ç-²ìzºDÿTAk½àÉÔÛ+éWºhK<u‹Ä³¤%K‡ˆœò}şO©Ôàß¹hğ>gæ‹y*9u—ÍËM£`³)a;á,·¼¥ño¼i‰o"‚E„·iMlŸÙ ÃUv©;¡w&Ì[Á
vıÂº<GQÙM2AÄEá;"V}s(À— Æ'ğOË+û¨ú3Ñø°IİM¬8GT‹µÊhm‡ŒŒjºLeˆUl_õÚÓá¥L˜5ôGÏìåü·kö;ƒ%ô»µğùĞë/vTúw„šã¹Ş³ÍWµ*ã«LéäœÙ-·±N›àW®‡©Çméé1îQ˜u0Ÿ¶Î„tã‚=6±ã–«İÓĞ— §ğx÷(7¥›u´†“Jñğ&bÒ¬V€µR€, ²#é²¬/ÇfıCëÿWZÀÎËŒD…í 3l(9uûn­¨¨¿Î_¢¾ÃİØjËo{ŞJ(W‹!øƒ$Ûu‚ÿôv‰}á\Í>+d{Ñ¯Z­7£œVù–6ılÊÛÄˆd•øÎ°Ğ•½"´Ëh°p6ø#¹¼®‡;£k’j¨ıwÁŸAû©Í ^bÓèì °ß&}>¼w+)Uzğ·èEBÑôoÛk†T	s™Ú Ü!’ió×5ßµ”ñàÌT†Z‡ãGWÚp(#„âa2XŸY@©î\ I¤\|Û…ts£lqrRE¥„$ş¨ s]ÎaØË¶je¼õíÆİÕÄ´ék¹¾WkÔğ'XhL]$Oaé\M´‘“çË¡ÔHÂWöMÍİ]Ì)ÒäìVÛŒ=Ëâ[ò¬€ÂÉÔ¨qç»iÚÒW

ĞÇCÎ•˜¡„kLç¸‘QŸ­É ‰wZ.æ/î@åÂ\@=€±òÈzêát¬l‡ìKK§Hy3êŒ¤Ø’³ÿæ¹Í¥3šoI=¶‰‚İ\ÃÃ¸S‡Ô´ÈÚ«R1¥ƒpÜ@ÒÆYÚ!jkîÄì é:G»
á˜!I5ORt"04á­éŞK˜í›]\—VS¹ü^ßÎ<}+€)\°|5ŠÒ|ÅÑIx°mº‡CŒMÖ‚–ÏŞM°Ä9›Ô¸ÚyÈÇßf>F¤:êßZ:ÀFà3©à[)mAêœ,„0òÈÇĞZü>x Ã—ª¯mtK1`¯RIšqÛ&$3Q¢líû›Òß³›Q‘íÂ„ŞSâ6™»Âí¾Á¤u@‹<H29ŒİÒæ1´…Ş‘Ç©gbPµ}#"+° PPD: åùÎ;ó°aıû9ÈAÊ¬†,ğ¿’“%¨ºäc& UıOlTrËÏidöÈc36œ õ4üß•.Û;í.ØŒ>ÉlE/Õ?Z‘ÆÆqpN½üaÔ%l‚ö!^¬¨ÊŞ#€µô:éÖyvi)øàKIÇW4ê+Şk7ŒU’@µa gÌóŒY©‘~™ğ`NÃº?Vw 4sİAæ‘%6©¬Å”	®®œÔ ªYhn¹Š¢ê¾îBãîe®vbª"#ØI©ÔJš5œYI^
Y_ÿõ'±KF+0Ÿè·”YºÒëèáJ##—'Ó¯‹êÇJ’yWO"õ$mˆeö<›BÑÖ5Šz”òøJú¹Bl²÷Õ`¼IOºı‹¬g8·BjÇ*­39” ¦!ûk‹Uğb8Õl»u¬+yæ»âÙ‹»¶I6éìy ñXFlcío,ú8|Käfä¹\¨}/T¥‰Lyi.¤Ùô€(Êú&Ò1Â{ŒXÃîèÏÑ¢ù¸ñäÓ´\†„‡oì:æÆ©©¨f‡"Öu/9+•69,€ŒæŠ:#­=¢ ådxV§H›ÌíƒÓôh´ù¦sr*Ì¥aêT}AòKÅ¾[IU‰ÍÅ½ä5Õã°&£K¿çğFXOG8ypÉëqäŠû¿fO<66ÿZ~‡‘
(o”¨i>|µœWBEŒ¦¢©J1Ï§îÏr€(è\¹˜w›ÌĞaNp}¼¡R«S‰GpJIåi«Ş];ï¤¼%–÷õEÏÌÑWo¾i˜ã¹ª‰ö@Û°íNîä$P7&4/½+Ôå”èY¯ø¨ítÍµÖ2ˆRR¬ÿy'Åé›ùBÆRñ>’”tc+#w",Ïòß½ïÈùMİoÀEÍ7µAÄdõË«·g*™	Ùú8]SQÙîÃŞä²D¶Ñ)=Xsÿ
ryUrûÕˆ9ø¿E†Zb´Ÿ"2öş69v‚ªX{Õ" ÏUÕ;}±N#É3ïôõL.79ŒKMùş•M\ó|OüÑk,Q=s­%|´©¼›Ã‹ôªm0Áp‚‚ß&¼•^Êeçòj‰šé'¡FS ¾²"uÃ¬™P=¹ÂÓ9'çW5:ïåçvq5*kÛæÄ:¢…i‘S"#ÏH.ı]L»Zş™xÂD;şNéÿPG±+*ØÒ+6pÖbRzÁB¿ül-œÄ¿wåÒ÷*©—l™ØœŸS²(±
.ğ^‚D1C–£~àØIÚ”ĞŸœ1°E±½ö±b¸Ô!Œ8†$º`µ°p9Sá€Ü°b5Z†M¥w+Æ—[Ôõ¦YNïjŒîı¤
âqFojƒLšp Ó¬bjW[#_CÆõu~l=d/úfs°£·6KğÂõ‹j g#3l¹é·#$,ÀCòCõ\jù*ºVQ=t?%¯¹î£r^Py9Òâ> ‰”N˜ìg'ÊÒ°Õ¶[ª;éÂS¡C¶ÂN‚¤ÿÉ=GsÑËYuN°N ;Mı>ÖU¦‘¸ØÏëáşWU™€!Æ”
ƒP9‚¤£UM×èpÌ€ÒıØó®®ßñÈT6û¾š«!/|şåBÓObEWƒG†ìŠhßßæŒ­GUà'vXqÕ-áÁšIŸ0ßıªF0H\¾)
3¨#¡Ïlµ/å¥ -.$]%#¹\AºÇæ'è«‹„	9{)±Öq8ÒiõKâøñ´¿5¡‹I.•7;å#{©£ÂnUFÎo‰5éSF	ï„±ôæ‹òyar=‰&Z3°÷#?ú4AU>ı ©Va#Ge¤#Ï²Zkşfø“èkşD.šzÃàŸÆtÃÂŸÓ	±i g µÌ+òòIí]&2^™ûe+£Mv¸4—^_ÿşµã¢ÂÀSš_û¡çƒ2¦”M¦m¿<¬øbœşŸl_Ø+áâ –±å™ºîf
lÃ|6J±êÃHyĞşİa<èôe‰'Ï¸MGêŞòèØëé‡Ñ Ğá
øƒ×ÜEÇFö‘×¡øÂE§áĞm¢nïã—'	€î"öCÄÄ@®ã2à¤y´zæÇùu´`S o$”vÑrÕ†Ä¨tD¶ ­(cĞ´ØJ¸nvO˜fÒÈì„Á3«à+Q&x¶Íú!C-âÅfñ|¯m•M>+•¬(³¾ùÖÅi€?ÇÎ‹¦5 Ûõá›®DÒQ@óNÆ^%K©ıİAßUŠ¨ŞÍÉ&í¯vê.ïPÛVCiÌ8âÒ+`J¶¬ÑïÔ|‘ÓNbC¸cd‚^Ó¼@²Şmj™ıs:=ª-©öGqi"—]±ã»ŸşPz7B:•:#³Da>
ãÄË1ípõ%NM×x°®»lF`'õÆI^y(QÕ>‰¸fı„Ï„Räˆ¥BI
³©œ·uã§¨/ .]X¨é%ùĞô ¾Œ
5†¨ü×¤ÈlA°x¥ÔhH÷H7$–
Âdîƒ3²^PŒX»Ò¶Œó¢¶~Àw¤üdù®À^GÔ;Ã^ÿŒEdA-Œ@ºÇÆ/ıZAò!¨£d÷^¬)ãã¨­kçTzhÇbŞh«¾šRE<¹†ôB¢áwc1èÒëúÅ‘ÑSF¨lÙC"³®¡xVã5|g1{o#ë¬ù`»§ÊËf6ŸËã,$)hÏƒ½OøxVI’ï¦Ã­;ú›&0P ÚØë;@8
G.Ø6ÛÖısphœfõ3Ïrã.ß“`U4Pë½{u%ö»o¹	¶··¬æ].EY#<ï†Ÿyv4õjØò¤¶ˆûg‡åÕsâ<]Iôq!ôÅ LÂú™„²ôûK±3Ğ´w¾h®Òéi²í"j¯Ü£´úÂº©‰Q†HèæEvÔÒ!Ü~š"Hô_XîtÓ{ğ¸FVà¥(¢.ç®Œó_2îÈú”Ñäjk}–h¶OMÊrî7±QLÇ'Ÿ´ƒ¥:a12¦õc‹=xúü{Å^³Â]ı~Uä+•zÊOœH]oÜ‰›©XûY€¿¡bõRZ¹„1äšë¦«·Î;xÈœ0¥îLğÆ#r–QvB,4.ÁÄÓª–ÒA}=×l~ %u™Ó: i@ÿ¶ı,g-¸–E¨rµÊ:Z]>¢ÅÃ"¾§ÁØl8oå!×ù[ûÕüU¦{WÓ.u¬ğ¸X£¬¤ÈHsJEIüZâÉ,_Êç-¨P
¿‰ QßCı®œ\
*±¾’Â.)æ:L¹CëÎW¬HüÇbİ£¶»¢Ñ ’¡nïßÀ¼ßÜÎ‚k_†Àuör! ÅN¾~ÚÀ‚|¨Ã w”èÇá´SûÂÑ[Ü‰££hÜí2£©qÌiÙ)_V‰,D9ÕOØÿ4Êî£¹vÏóÙé4ÑÏ„«qt¯ùQgs™+KoQ ¹„€$||µ= z…µIh}\eƒªù¬E8óv&F…§–‘€?&¢y™õ‘q©¢zK¸Ó5ò;*>ç£=‹ı}émL I.ç%ï‹85¡Ú¦zrGı“47éıZ¿é1N3élù{ß®ğ¯P>CN¦âïDär?À*!à))@©¬v1ñë¤Å?8å¾¾«f¦éörÉúé¥’ ë v}Lù!r8”téŒ<õt½¯&Š&^äÉ<• °ãj7½ ;u‰>ÆI(’*Ö˜XHŸAM*à|ÆşJ‹ÕD%`ŸçšxW
Ãç—.%{*¤“ÉYw_>=êE=Ld;zì?·
_<‘}Zc"š\d*qà!‰]‘®#Ê°•E/-ª¡[’èR3ğçî¡I‘BÔ'tM;êŠBÓŒA£e–1öwƒ¬ÓÕ§Z?!gW;&Š¸0×HôAÎ(bE
Ï÷'uF"€ÚÁ~'H4Å®bw' ô~&—_¸µëQ˜	º–Ø¸R›v^¿Kæ?÷HÑÀŒ…wŸÓëxÁY±¿Œµ„yYÅÄMhû?]-Á½èí	S†zŞDÖˆ~‘×ø¤Î™×=nT¹ñ<¾¨ZÇ¼Û D¥ujøgnO—jyœ,*0¹3ìÂOû5˜ƒ­¡6:ÂÈŞş 8ó4|BD¬¡~r…”ŒÌò›&Iz´¬~àÌnÁMZËG‹èÅíğmşÕ8­îg		æí[E·’¯”{ZÆ
ÄxÄJßøôgß):(™–âÎ ×…O/óWy’>$·À6§}I@~ä—xŠ¨H¸¦bw_Û3©Ee5R$vŞ˜O_·ôDcâ‡³çVúèRg5%*T\|¥Š"<Íiì-ëb?TĞ_Ç…6Ä=ò¯u ¤ŒVFEk›/LîEh2ÿ ã*§ãT»Pw7ïöÄ•­÷ÅñmÎ oİy†ÿS$¼¬Øˆf‹®hfmÈ¸"hreêwf ŞÃ·Š×ÄfÇËÈuV“ÕúÍHsMu §|Î0Ïâå!q­ëoì[†ëwZê•-/‹®ø*Kü4Ğ^hR`ìœ©ŞÌ>vùt5[„ ‡=Ş®8|àñÜ&Kß%MñT4ÿ5Zqíác÷œp{DP‘ ­Àò ıØ"À¤·!·¿ïûp½Q§4ÈSfÁ=d^C‰X¶Kk"E¼;Y¸Æ¿±8i›[¯cfÂsö˜åİ¬ûGõ4yq±ÑB]hm„h M)pÊÕN¡Cåª9É_4Œòåø«ÊÑêÆ,4jÂ_æy[Ó1Ÿ[7Ö§Éš¡ç­ØV¸õM\ï8EjBd6½êİYnx5mÅ0óï×5V9®i¶¹ŠEÙ†+Á\[k:…a*«8j8Së2úhDsGP‹dó%§m0göŸ>œ™â¾ƒ„’©ôNHÑ©º‡©œºÙhéÈık-[
xã>H'NÛšyÛ¸÷ìd.àãQçŸÎÙÁkÒköàíIã€ò1–‘Iğ%xPkÚ±~{[Ö2Ã‚ã` Ëû(¥(Û·¸MÑ’˜[ê63ˆç¿`ißÙ³È
XÅ €H†%1~ë5í{öˆ#.&±g•:u‰õgó¹—ı‰´bıæÁ—¹¶+“‚*£.Ë4bÂåè¦Z ¥×œa¼õ8ÏF°ô?-ÒDlºğá¶´@¼öö˜Óáê(U_aÄ¬#UGiÅvPVE‘"©(ÿ ")ÒicùÕ„ğ0¡OZ—‚ä¥ñü»¿ÉixÕ'íĞÃé-ÁI¾€`m#º-âÇÀÛq|Áp9MåªZƒ£:$ûL1¯¿2?Tg­­mOì²ß:¯ÈA™e¨w)€{Iœ9¥ÓÍ®Î×¥¾,Q/woÆŒï­„5]´ŞÅù0ğ;›Öi‹÷£ÚšqZ1ÿ^ŒO§•œœ€ ãû†»U‚a³ûñvÍŒÃĞÆğş£l :×	7–ªV!]9ªã=²|†p}¥)`¯aäø!‹ç¯šş‚¼?é_p¯Ü³|üËMHİ*Ú,‹ÒÂõ»Ôššôù=•§ó‚ä\¨C?‰Ü¹ÈŠ5d“0:_Ş D¹õœ°S6PoV{²ŞÀ…`ÿõJZ1¦iš9Ò ã±ò›(qDFÓ4gæOÛEâs€Œ¸rYCŞ%‘sDù°c·à”’Ì+ÓómÑÄë‹CÈ¥£¥Â_q’‡·º¤ÙÅçUAÁ\ÄÓßs‡
¯*L/hFÄ‰”â‹î·œÒf•B¢ÌUgÄ‘*A†¤ o[úD6>ˆP¿ìulêĞuì©#Ìò³•ƒ)×ıÅºšXíØ¾™Ÿjö=XüéwÍ~Ñfu.Tè.œÀ6˜oÍPü¾§…Ó¤>%O'xˆ“Tôó`[÷Ìñ“˜èÒ¸…Z…üõ3DëÛF8ÅêÉâ©H<Z2¤ƒ'ı3ı.K”z‡@Lø›ä]°Ğc÷ùÊbÌfÍP•ZÀ2×i¼â7_Q»ûõ"´_5
†vÜø(ìíÕ£M/úÍoUıD<ğ„È%ê6!ç€TÇL~a­)Uï-Á$Å¨˜vÛKP}–^ı
ÁºE sÅdÔOağÈ
ÿß_…)O²a”ù|Ú<UÉ¨ó´L£w±ÃBè˜)|jG
æ¦¬Äìì¸ZŞ^Ö–@ç1¸®¥ú½H_À`1ô€„³ƒ=d"3¢”1•\‰¾°1HëâÌ¶„*"lBR}Œ¹ëšŸs¤£\d…äJñ öš\#aÓÏõÔ®³È§Ş¥D’İpB6i[¹e,Wä®Òû‘`pé˜V˜ö¡ò™Ã.JTÿè$»»®b;ş~dlO±‚#æŞA*¨Q÷P›p.:iF?ÁĞ&Şr÷KzÊ=M€ßOúb¯1¯8½×	,8bG¿tYMÉ÷Ûş1lJg«×VìÃañ6­»e™(Çş÷7Ù1Ú¼=ñ¢Y¢ºöÅ›Ê!İHù`X+ÎŞõ×=¬£üfçf‰w¡v „
Sg0¬,Ø½°üJ)Ü«lÉe³lR«îûS”É’Õ¹$¸ĞÏ_]³Oš¤Ù*¹lZˆğ,—ío¯S€˜O×n‚h=0™ø7ˆíx+æ1šUY#°ıØ‘|äâË'&N=m]Š»`ú¦[ZxÄÌ´ÍÅÏ^¸„~OñL4Òé„Mßëuô„7Èy•Í£åYts9n
\4M<¾R>ûh©³íê;ğ¾ªÓG6ªæ€zYÄÌ´ ı,w‡˜bûÒ—aJ¦¯Ãª~;xâÛŠ¬½¨zN+(´{e,ä£ªm Y¡5nÙ9åøí[ßĞs2µ'àA¨c•rODYA÷?²œOQäQäÀ{l E³ò>V\¹VOËŞÎ6‚Ğ- h}Pâ• #‹±Ób“ÑÄñA@‚tp8M¹w »0aí¯ÓÉiçh\î±DYıó(4cCöĞà„¡ÖÃ\™ïÈËWØUëmÕ‡¾‡î.×s7&/¹æ=?	ï'šj€É†ñ„SÌÈ½‚Qœ¬íÃğ]Ã¼‹>‚¡í•O«t	øW›JÃdL¢9CGÄçÆF4ñMbÑşÃ;©l<eÜÖ`ÜBê_[ÎÛÚr8#LÚN¥Ø½‡ÈpUõ7»ù¢œ_ŠŸùM4W´­¶’\WæÀYæ½¬ Gş³è¦tá|ƒ"š>]Ÿ¿A^ß›ŸûÒÑødÔÓÑº‚Êø8²(B Îß|T×¹™õL3FñúZVeà¾g¼3PÈ…=$ûÂßXLêu°i¢%˜Çl{oÄN²Ó±±y™²yãĞSuAúà=‚àaeÌ¿ş¥ü…7Li#i2T>ˆ½³4h|oX%øaÏ‹ëZ{Ø/¬ñæ#èy(ÓÑr{åŠ‹`"´­äA!¹1*ÒB*)—¥ŸÉË®Zê0\ìQr§8¾E·yVM‘åCí¾Á½FK¬}e·¶#ç<RCB¿bªQl6ğÿÈš’ôuÃ¿P´ƒõÃÃ«(åQˆs7U¡n¤ò¬<c{ıÔøR®Z5f}ä9ÍŞ4ÀâìãŸEôQ¨mcÚg`İ5”µ[û¿ßÄˆ;P|Á‰‹k†œ!bD0GÔ†&İPË^4¤Èp‚=æ”¼ŸÆZ4æk$XÆî:”ª(y/î¤'çP“4Ã½‡e}±z¥šèÌ\AêN!áqµ8Ì?˜¤ópJµÌÍX­P£X Å_LŞGÑo¼ôµşRZ¾)I£Eu¹2X‹…\”yûÀf0ŸoæÃn#±½2…Ìˆ¼ úEGÕÔ;hf¬(îğ¦ŸÎÄ×t™¼AµìËV¼NÂs½™ÌïüHH©©t´<=É°3ÙŸYÕ&ƒ©I#ßğë§ÆpücÆ1Xhºöu‹•UB´…l\ÆYCfO°ÇTŞé’®	ZÃ#áærzËQ¤˜3›§†Hö`}®ëXë¿yÀòOĞB2P„N5ieàÖIM$t*>M1+y0ë—_Û‚=¿9˜ DñXkCr<½kO¤_nï¨îÑñİßœ|/éA
/«Î¾BÈU¬t¦Ä—Áß‡KçÂ{‰ZVpùƒB ÂmµŞx­s€äÒ)¾™»Îf8 —E|7p5…|]nô¨uƒ$¸VïJ¬¤é†7nî”–_»?‘¿AK"©|‰j:ü²ÆøI¡on!+ŠYê¸5 }Ó<ç÷£f!aÙ˜ëØ¡²ÖÁ2ZØ)cbâÙÉc€÷#·Í‹íWYaeé=4Wá!æ·§2·¶ŸáÕyFÀÀjÅ0)+	O8Óë£Ş¶ÙÉÄ–¯	éo«ıU(¸3vˆ4¡Q°¬Y$‡Gôê7‡ÆÉÈ£dq !§x,şÛ¡ì)‚^SÑåtş’I—¼Ş³Ü/Q>ã2qçıhàÆ¼}!Ëå–]ô3KŸâ¯HeX„µ³šô.À¸+Ò.®c7èƒ{¾¾‰·˜£Ÿi†ÃûPyÏjª\»Kõ²Äˆ9
ØÓ­Š§°ÚB±—/™ë{÷;wÀh¨@B˜ ï02w‹ZÊx¿—T~ŸâÄ^¸Û0Œvùa"M¨œ¿”8#¹6umÅ±r•Ş{á®!J,Ì
mTÂ˜a‚K±³&X5PyYü°!{ZÕÇ”­æp³>3#¨Ãv±»Ó†ÆEb¹¸}9¨ƒWÓ¸yºA˜d\‚Ş}lmò{ïY¾ÄPüÅØï„Ño£x¤6£NœË%ú² ­U¼Œ—;ÜøæŒÍo8\°X;düÚ³¤,Åƒ‚ZÔ}UˆZƒY©×^®¢I¼e$ˆŸcµEdÃÀ|÷Ë;ÎLxlåbÜ‡µÈ*¡çV_å"Â‹z<mâp†~Ìş
¡Ñö')¬«ĞøÆÄ¸èEe¾qis¸æ€5†î˜!r?i‚:òÅe¸Û¾EãÃK0³ˆ/âXHŠE9órßLk„ï"–—vZÈéuñg)ìğ¸»ÖÍ'¹¿J#jzáì+m¢/Í»»M'Ò­¦d5¸4£é÷$xo\[ÓC$wƒæXGIu£ŠS4¸	„ÙÀèL‡IC‚<,ÁÁÇ‡ŸE'ÎÏh©€û½.{àêüâ5›öİ¢>'_,ÌkÆI*€}zƒo£ql`rç–1ŸŠ•;!|b»úP4`÷S˜ÃP¡Qéi$óø`ngd1[îÕHâ,°>ÈÀ›Ã±*‹ôÓı×†ï‰İóJ×X¢”Ó7g¶è7bcQ*}ş£šæê)t3èZÅºiïŠˆçR¼E¶'Ğêå;©™;9ï´åËË$p1Ï—Ó5\6¥÷Ë£€|õy
€òŞšgH¾ş£5YİÓveô#¯ßê»E¨šxcƒÃ< ¼œ–<UÊq¿B‹õõ‹à6ÛƒXXËÕµ0 M®sLİ!ûdweŒaæäàèŒ,]&øš÷üİÿoËéŞ³#··òEÔ°G~¾#fÉd e¾¶9_ö¤ÿµ²~şÔş‘¢¿YÈ½ê G®ùŠI2¾S î×î¥öwŸ.T¤I:ÀÑşµ—–“ÅÂ¯~=üFçÄÓL)(z~#:^Ìùî%‹¶|MYFÿ8ê¨1Åó•èŠ}D½»©àèœg=,} ñ˜¼l'Ò²ÕAbà-97ÃàË> ÉË@Ûîı;ş<ìjÄ*ª\ÎÛ„Qgò|<«º’aDÚX|H¦	rÁû†sm‘Şæİéä¤’j
ê‘®¡“àŒ‡y¾ûª&BöÌ¼Ì2%µ^A£ìÚÃ1©¯"b¹ŸU›óV9ÄZ%â‚—HÑrqR29#TÀİ­\…ç®6g,ù0ì[Sûá
X”æõ¦•“V´+—(–b“ÙPU—”+UÆIğìİf²Ï¢e’MõzW–¶œ¤ï~<ŠŞ\ŠRu&è‰'ö-eRÈı®É_â*J•Gª~	\}PÏ¸å¬}§İRŞ„U(s2÷”§.mı®T05‹ƒ¿:î[;şô¯6YÈ¾UmÆÇ¹Õ)#bfûò}¶|MæW«°İ
õ«HY”QUbéƒ,ÄaudTqë‡9©½n/Œ#«>c®Ğ%
]=Ù5¼d$£#á±¢_›–œ,B¸»†O%§”Z¬Å´YñÕÕÊ%:ş¢Cp–4) øçùq½=S·›üÖÇåõUIõ¼çOl¬H!ÇY–\ŸkÀK4sn.ÙÆ:µ.µºš¼³æåDß„cY[_qÔJÕi{«èÕ‘ĞZá7Ú“l†áXş$Çñƒ€Íê25‹”G_Y¬ê|ÍĞVäî2ñí\Ü4ØUáÌÔéó4å­q¤×o ı&"şM@B('VçZ`#¾s-¢Äé”‰¦ƒøªÇY}+İòb.ßbĞ¹•ş†my
(	©R-õ›¢ÙĞÛğdÛ.XBHPY\£€G
ßàôàÏ¬¶ê›§ìoƒêŠQ—É/Nãÿ[DF2†¨Û¬µ]¨qlâ¿ÿU•Q)˜`d9ç!0^Ú7ÀO0­z…g~&¤®QàóV(7á¬å^Ö­‘ºu 5ŒîfÈX`;g¼õDc›‰ú¤Ö–)ƒ=®&t‘NVâÊˆ(©hCÀõû,R7
®Ó—Ë×™Ò¶}÷ƒ'^é£Öã¯uN&Û~ e»„-Rüìô•·
ŒÍJıÂP@L(±õ‰:ÀŞKu`#²ıP,Ñ_Wï¿ ^ìÅ§Ã/Èõë’DaÂñÌP{Í¾'fDI¦™½\sG¨‚)¼us·Œïé©€Ñ¯0ŞÓˆN6¿VÃêUiÃè…¢æ=§
6¤>Çˆ¯·
¨ğ{Xì¨Ä4¢¼áÉTkû–TF"UÜm›Rq •WoTÔS)ÌCâ9ïüÍÌ9¤DŒ6¤>0DíëĞñÇ§Û]¹ğS£ÕÁÆ¸:8s´ı,©N5 r7: ³GU Hó°5xŠnÁm>Øÿ’Ò¡¨TïŒêø~u“PàÏ¤;ÜÏwçqHUŒÇSÙ^9v!ÙÈ¡_B-Í‹ûãO«üèg¨0£™PÎÄ«µ_Ö¢„»<*âaİÿQ%VámÆÑ€êş~¢í1Ùüò¼ı3aQâÜ°Şì”>M!^Î‚÷Ô€¨ä“°Ş‘[z)MTßyl£ÚóŞ^†BS‰ãM¢ıÎôIóÌ"¸¤Ú“ÔÿT·¼ä˜¤Å#ÛÀBy BtÜægvHı†k´”~a"Õ•¨ì	K?Ê&†ƒÚñ¬Jd›g$ú¡j*[&"çÿ'Õ*³7¢o$%UÉÌ›z)šühPic¦âbĞğßöì®ÃĞ ùÏ¬{Î¯©|Ö˜dğ§TâÉ7›U“_ynµpû¦™¨)¡× +Fdq-¨at+ÖçkÌJÖ×gp{¡ÏÉmŠx)¥Y>Z  öÓtQ¡n£‹¢R®%”Fã¥bù–¨°.Ñ‹Ròf¬—˜Sá’´~Q§ñ°™ Xƒ©E»Dµ Ó¹‚>8Ìœ0cI&ªï¼rgõ5¬aúH¥ÜM·’Á.í)Ûèâv²U[fÊ=½¼)çp	¬ßá²¥lGØG±4zJ=ôÈ£Î¸Æß`òIå@[ÅÌCo{iöòÖÆ.o,ŸiTæ=Ñ¿ˆ;,á±˜:×•Öâ”Šı´3!Éİ3åP/çÍ¹ù¶Á ÇÔ ã£—&ä&db ä¨¤Zâ:u­l+E½"ö—f7mÁ-–
ªe¸RöñÁ{ş“ «’OPPZÚ†v¥jÓlùøJÀ·dË=+øb–3Éö{ÑR2¬!Ò]9nKÌ§q/ÑmóCsá«Ék~¬$)H…l8üäS2Fñ“m0t´Ê Fø(p #±Š4îQ	ªNâáÀÛÔİ#‡eÏ0T˜(üáïi¶b»fU9ÀTÅˆşhD2ªÏ“¦,aì9y/…İs;ÇV’'n—&êiY ×n$ÔÅı©
 “ç\nq,†ÅœÜñŸCÕ$ÖÃôâË^RS0Öô:ò’‡%2Ï.‡pÑ­$@q2E(òôuxAf°+ĞÀ/ğÄñæ>ò«76(ª’gÜ]Lİ™õ¤NœÓÃ¡tµ³?v>Túş–	îë5a¡¹.ãT0 ¢÷~í8êw‚êáL4*¥™_âîÜã›2jØÿäÖ	[_’ğcÅÒ!òîIiäÉY§¹*ã÷¤ÒåñS¶ä˜6àèwhJkñgÖ`kÁPIì¸ü×z½sZì/²g¼<áäGJÆ8ÿÖùå‰´lí»4&K›ŸH½rìİÈ³Š{sÒgº1ÅÿBæ&úüy6ö9uºøà[ù}–¼ùm’ÀQÊ¤ˆ³§§ªS«PŞÌÊ~u|A‡™Üòƒí £¤^Çà‰dÏÇL[KÉ:§¢üÚJf·s>¬|ñ² sØYÈşjÖÖ·RªÈ +@ÒüO—ĞÆ»ŒU &ìb:B÷ğgqIhÿœdqTLá¹ëŸîÎˆ«ª÷´Ié¸õS[¸u5ïJü(ÅJzjÇ;˜õœƒÔlhˆ-–C%‚›hä ÙššOÃÑ·²‚É1kUÅ$«ß Ô‰.–\\êûËœ.c«ßwÎ‚Åßé`“B´°oÀnIÅCá°.ïV’	É¡²ÑÎ-?&1¡“Yş©‹.v„s¥5LC’©A!­N.dû@Z^©d¿pyˆ·o…´ŸL…“èJ\éC® û=Ôº/îœ;sô ¥¶¤‹½2‹ªñ~ŠIF™Í8	î¥}5vŸå8Œ~UÔZDê÷Î¦àÛ`Aä®Òss9ğí
­Â!£‰¥0Æp^Ô¾+J}5fE„€xßºòUüYınµÊB¡«nĞ“Áİ]Œ ?Æk•5*éª¤­MñëqG@UïeÎšŒ‹DÙá)å~Ğ@ûe~±º™)”Ém¹±äôQ«bpeêk;ÅgÛÔ™/!MbİvÑD 99¡pò¨Eïsç lF²hõ÷ R°Ä’Çd$”N¶\Á¸Èøb÷81}ª -;•©3Š¡œİèÇSŸpŠ‚‡·hé!Î0¿º¨Ò“²Ï&ŠFk`6ŒÑˆ`(&=¢ÚÕV	ã÷öëŒocØ‚÷ÀÇWÕ•(ˆ÷Õ°?1ãèeSèåvÓë¸© xo:óÏ(nQì¢nÙûÆásìY˜¤=\½W‡İ€>tõæã-®{Î9"(·˜K {ë€é +e—y¸?±ªÛf”íƒ7 ÁQdw%o¡¼T¾h‘1û
g…OÑØŞm˜³Lr9V„½•İ,AûÊúƒ´“eã¶ıÇŸUÂ<s"(mOú0”rÆ1#ßDT‡Ú½Éê^ÓÔüEÊ0…Ìªı9÷úç÷¾ÚÛo¬.á:“SŞ0B^ÇOŒ¬HÃºOÙº®WE6Rc˜Y>‘²úë·
¿ãöeÔ·–~ÿÅ”=úgy¾–_ØY‹eï÷‘÷8²Ñ-ã‡]V­5Ù<›³†»¥ÎÈÜß"“6f«M®‚º?¨Ï~°ëíµÊ`F? SeÊÖæØéPÛš(Ã‡¯!BRó¤z°?£„^
KÔú@®/Ó«/Êñ;É™¸€5cZ¢t7êTÑè2aÈKVî4o¼>%†ÎÓ—çÒâ…]„6ƒ0"å›®!r€‹-ÿÙA.Ç¼©/ë›f¦ö'çÂ;ï÷{PBĞ+©ñ»,o@cå³Ô şeŒY&òO¹Õä¾½Ï?„Ö†A¦™

ÜPo=
ıôÜ(‹òƒœnİ×{ã¿6MÚûıÿ:ËIˆ¨öŒğÿr|7Be_EñvëxkŞb7j¸"=¬7=Ë:H§3Ç]/qöÙ9­¿ÏÎvı+Ri7†?ÛìÉ0ê%ø×”ÿş`AĞi-‚Ï#Ù‡»?Sc£ùV3B4G»@ü ™ÔUàc=¹/ØÁ1tÍ¥6Ğ{~æº‰§h»kÔ0:KÑ™¾„oœ_Z×ƒŞnÛQc¡—ÎÀ}®B¸\t·TË'd¸P'•ç{ã¼â-ÃXñÚı–—$´F¼fË%šTIœB¨çsÒC<ÒWgn^èŞÍÖÁÖÌù¨pÑös¬6!}zLq{¶ìô¼tŠáz¥£»éÇ–
Sõ}Ş•‹Ãba?ÿhbeş^d%\FR	¬hŠEÖàJ~‹CÔªJô—ªÉ°7(*ĞOƒ£ï!Zµæà¨n©z9Vx@—£ï–²Âùêâôƒ‘¦KËæn_ìjN$+í:¤ä¾:jâ<O„ÜXlæ¶3–‚±ÀÊ{Õ÷œgt"HL6=mi	Z•TTRÈÒ}Aä·{Š‰ïféq¬
¶«€Ê²§€üìHÛ†[O]ñ´ÕŞâ:íæµËürc€døÒÁD¿Û[ß}ö˜XÛíGQñ{k²îf…V£m=yq¾$pÏ·Û:rÕp¨ ´»D;|ğ·±iãõ"%t(ÿ<ñ[¸È‘°ã@µÏ8k'ÌcÌûßÕ¶-¹×„él®Š½&õ 0H!,4…ÃÍœú¹5RN ²âŞÀA    
÷ğ ÿÑŠ …„€€ÅW.Û±Ägû    YZ