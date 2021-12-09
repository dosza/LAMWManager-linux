#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1808185758"
MD5="ebb38758c2a18e05fd4e8c2deea711b8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25024"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Thu Dec  9 01:02:06 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿa}] ¼}•À1Dd]‡Á›PætİDõ!T…Y½pÎå`Î˜Jc¯êª˜|0ÅÇç:8˜‘…{©o%€Òx^ñj:äÙÇ”ê™Ö¦xKgVÃQ÷‡9‰\ÑŠ¬$)oŒ<°½+Qêc{ã8ĞìY¯«$œ|4‰C†‡4 ¹<F‡}P¬DPE¿¬ìu×ò›:ü“b3Oš(¥)U«éÎÀ¨v<ªàûòy‡tóô «G7<MIŒÈI°ùNúx9ÅÆæJÜÎ‡¢‚ª²àŠIY/ö+ş•2Ï‘!~(‚õîÊAíü}Ù¢ïØôÄ$µV‡Ó™tPÏ8Öµ7ËÚ©†ŞÑ©?vZNuáşqxiüuÜ½c~ÔÒX`‘¦ºßú@k´deÿó¨õV£®ÕÑ@ñ=³B+ş/VXpw½àòÇğÎ^i€×£!ÊK¾å”vB-îU³àÕÊ¡Çbô>)áï<ü5¨>†æş™Á5Ä]üÓ¿õ‡{¼*)AŞ°2(Í¤É¥Ë¬˜º=’hw÷|Wige7ıÅÍ6Œ¹Q®:·;®mĞnÆ>gV5dŞ€¦›‰ñ@Ô@”1KõSÕò5r­³åê%Ê­á#_ÆÒW®Ñ¦$µşãì³ SI‘¡Ê®O°I´¥]è\f«#ªü_ö·ƒn²ÀĞL€~Ò õº ÑÒxüeÙA…³=2–s–qæŸŸaà	=33›ÛÒşáX¢[Gƒîê.yHŠ\UæhZr®Å£šA¨:3í×ÏıÚ^²¹Ù×ë,¹Å&´azZ¥Ï ¨ªø3KVÒJšÎZêLÿ…Ô‰»J~ü3À:sËôÓ°'¸ôÆtMÓTæı/ÈM7dJÁL¬]|qOrÚù±!êÂBa‹¿‡ô„¹—,BõĞRssŞ—uô‡z]sÒ…:oR†ÉÕ “-JÚßJü¿“0Ê¤ï029ÛTÇİ¶’µdPë))ë ûĞ{‡ªÊfÜÅw)±šŞa¡R% Ê¦¶æ¤å#£-óA¢¸Pÿ\‡‡îuœıùÈ'½=c`m!Ew€i`Õ­E};¢äÉ)M:7Qcá–F…Do·Š8ú÷pYuZêåzGôÙàÒmÀWÑèÁ_’´_Ìh§eævÑñV²@†ÿ˜±Xó:·å¼T+—Õ±ËjÔÔr
T&´Ç Ï¥*-Ùd)LJúûºùmˆ“!­Ñ°s2.Jµ®:ÖëgGÖ©ö‡_ûVÖR,i‹lñHá!&æ©Ô‘¬@´ši¦‚§íC6Ó2ç/Zb=:T‰ÌÉJ1Ú£®åe…Áhµ3­0nmq4M	ãTrç5¨ñçTIÌ¼MÎ¯.}|Ømçƒ¹›#Àº}jfR±[K>tŒªÔ|”jşùpcşøõ©ïéºe°ÃÍ/¸7¹Ò]ö±½@G8|m¦;àt…Å'÷Ô§×®ö$¢jı€Û¥é.íÕÍƒËşPÉÃªº>z¶ãÿø– g‘ûÄÌñšq,*òğÍE,"<Y=¥¬+t=‹¡ahJôj‰\lÎÏ¨dl¹!#·ú˜2›ö§‰F0eÃñ^çky3Ïwí…©ÖÚŠµM¾ÃÇ^´ óÁ`ƒDbÔœ×:^!£+”ob1Ó—2%d¡
ÅÔ(ÑÕ­Ue{ÙjÜeQ?¨_­gÔ ÿe÷‡úe£o{û8ò4'ÎñÅ¦X>zîùîÍÜiyÌàÀ•u9Œª‚YçµÀ¸3—ËREš„tıÿöPb&“Û÷šˆNÿ£ğ¡±øVj>=)ô˜ëı_5Å‚6Ú‡¦÷Ğ³u«rÕ°3ïçÀÑ‚¶ª%é²šñp^¯oÊô—6ğˆİ7—áçhê,íšk»ï²"™;®Ï]lí¼E¶U¯"…MÅÀ“ºˆuo£Õ‡8Yrinl«]/„­˜ì6‡È’:§ìè,‘ çÄÊe–£K»7Æ°…8—î{fÎ¸vÕ,V›—Ò÷C­¿óºÉÎ·7Ë3|øs£@}­u®6ØdwªØ+4å¶CR{ØJËvEÛHS.­“<÷)øÍ$O›ÉÂ—Ë÷|êhJœ³¨ÿ¹g·È[ëŒq>¿²¢D§	Îš˜q]™¥Ó0K	 iq©¹Ù<rÄSdJ®×Ò¹†;ØX]2/ )8Kù^ÍÛctù€ÁáŒœ6Ì”Çå­:*üçu¬3Î[z’?c=Zì–{ÎH“g| •Ê:*qÃ7ğD¿†¡ãÿc|o^ä°Œ~ÁÑËV1B­¥(HÌÅwvˆ)Ï(ÍûÛàß#a ë©¶TWxhÁp
hÆ$§¾ÀÙÑØûY›£Œmõ8&¼‡z¼¯¨z21wíÈ‘t4§ùZâÑYGåü´ğaı|`®ÍÊ¤$13¡üÏÏ$ã' Rø.¼ÇW¦|ÊÏÅ±üd‡19uˆ@ÍTëa‹ùqÒªÏRƒŸ Ú6…ğş¦›ïlòšVKQ¼1e;k«î_È5\R²ì8éÚ‚é½:‹·^î[cÙâbi1àXá«ÌãŞVEl(ŠâfHEÄnWíBNıòr+å>\74›+¢TÛÛü	ÔÜß­ÄV¶Ì«*–¦{M~¤b¸9àQèıÔ!ø2‚ÿ¶ñ^NÀPiOÆ±&mmCR®R6ê”Fˆcsšx !íÖz÷+Qt)íÅw@‡Ã}·z<İß
²®.S×q\XÎ¤ˆuLy2>ğ-¡ü”*uÈ¤r>•a°·ı":šğ‡İS(ııLqŞfo6†¼%ó‘Mf½ñq‚—»(dXP›Ûî	÷g‹ÇX‚º¶ìcic´©’9éÑÕ1"2Dì‡“úÒ…u.Tv˜¼â˜ÍØÛÆ½„«1—†‘IeáŠÑ P_Ro¥İé•ÏGßŒ­L”plnJ[ìÉ¾âA7,aŞª© m¯#ñ#R
+”y ~”HCÇ'iß)G0—3ji%İ³‡ù²ÛcÂßÖ[·.Áu„X,lW"Ç|pK*œ ¸òŠ'cĞGªš2»¸?œ#â½eÕøìı€\Á(¾J§êóOÙœ2§àÇ©@’t‡ÑµÍkşakŠƒFR´¸í0ÍáÖºÅ¶MEgŞ^ÿø´	ÈR'ı*–«`Q©ıîÔÊßuAQAíoWHz
‹ÈPÉ±Ew&&zÄƒÇªÑOŞğ¹Úİğ^=ÆP\,®n8=mûµĞyÅ¿íYZK¨åØ*|eg…)	S=Ûf)Ÿª:a–[î|•ñåÒ\Sø½f“†æí1VÌ	å2_LÑéğür\ïìóÁ½}ÀÿW$FG_‡ªÇK×~g™*óõı˜Y×’tP*™h-2ÌŞñûznÄŒÒgQÆ¡ß†ªIöµ_´¿À6u]Cæ³7ëÀk¬‰¥Û9Åv’çRÔ/3ÌM«g%ìµD»áûª\“Ç„¯2&‡¿È*ÁVx¸ı ŒÙÄËò´ŠÇü”I©m~r€«~3R"„Ê†ù9 îqĞ?X=‡]Ù|#«œ4SÈ)éŒêáºhxŠtÂÉµ0Sß~(øñ³™ÂDzäkV¿T£Ê“¶‡$*y	Ï ¸^PÚĞ•ß#ğÎ²‘–µ!M~Î]ğ–#÷¥†j²Ö:"V‘æŸıE~yE"Ãµ5ı'Ô@š°!í³Â^+¤¦@RÚÒ0C£÷yéšÈÒæ;î+™ãù
j¾ÕÆe52^°7€š’`ê_‰'·EGåÕÔçç«k	vÖU%^¨Ô®Šxoo0Ú¾ öñ±6;=å€dÏåxrCöXĞêîÃAgÉfœŠ8²Z4A$¦–nóˆ ü	¯ÃKEJĞù"úá$Å!®—¬¤«6h®®F…YÆØx-_ï.BĞ‡Nñbâ>×£¥2fÙYª¸»Šàï€ßi¥¹âGíV0ŒLšŸûŒÉü‘x$~J0èl^ô~ú¸·[të±(É9ßXÛ$Èš‘µş‚öşÇŠÅ7şİMoĞ¤à~ZÃÑTG€”.ÏM ä¯îóæøø{’;Cê?vÒôG¢ jC…ˆlnÂâÂLšòT}õ“)\Õ^S…bÑÙû“Ã…ÙèÊõÁÁµvÖŒ=j5ƒ¶§?{=I,ôKßÅ™YÂÔM	6÷e@-{eØU	+%öøEZWZ…‰Ï¥ HgÍV6…K‘à„÷É#Ø—<slŠ[WdZóP,a³s÷ßŒãR¼}”ÉRDŸñÑõÏòÒX‰ U€ÄZÕ	’Ìû@0¹fõ;—]İ7%÷‹C}»i Õs?4>8¡lL#@±É¢"iuc¸+Væ†¯B&ßĞn½:UÅ'óÉã!£‘yŒV•å(VÚ/ŸdÜ£„ÛYg»@©¸ßØ¾ş*|*™SÄ86ØzÁ„èÄ«T:læñ5Û`ÅÓQÅšTmOŒËpĞn|•ôéöCr»gA!è³bÌ™İòÿWpÎÛi+¦¶:³„~ªù{)‚i %eˆ}F¸ÜÑm¶(Ü§6>dÕ¹Xgg‘cŠt^üSÛëĞÀùæÙí×„şÎ´&NAŒ]¹5ø¼§şãE.°vkúÕğ¯—lñFúM4<|~¯h+d$›À£“ÊVÕİá¢¬akU,
Jb´°êS~ƒÁ[ÏÄ‹æüÑüšêğu”ºX¥!ÿ{B(Ç^áé›kù0â‘ÅËšâÿÀ­sy±+ìˆˆCÌ
8]Báe¥ã†m¹ìt ˆp®éZH%")“ÈhÇ3]#&Ñ¥5vÈ¶çã}ˆ’¿[ş{Ï¡(Ê58ÌÜÑSo™ùÏJBU
…Ó‘‰¾ĞŠW"µ†Ş½À‰:3õqcOsd•’øHÎä_-…Åã0Ã|[1xw–à Ç60((©¡“íáİyº¢¸rˆ@{N	Ì‹“vå½2:ÈZÏfÓ!¹ÇÛKıÏª |Óe†·vüÉ7’Õøêå3C™úëvj†e~¿3óÍğúã¢ŠzsŸ‡üsv–0jKçu¼Øö]ÉT®XÑÏDÙ]uˆËã$É`‚•-@«çG‹É¿µåÎUìô€¿ÿû7ˆ6Y»CÅï°»H·i~Òúlëz/(Äâ4ï4¸ŠTe…ˆtŒ*+İ-sø.ƒŞo9ÜO+Ë]À×ÀUò,ëÃ,™€6ˆ1‚ƒuôN
ºY_Ô‘Ğ’»§wà›èÀü”€«6<°°=® ÄĞ>Çò2g?€u6·cÚğÍğ]Î4ÔKWÓ{æ—wáAP£±NY|íÏ‘õ )$Ê³âk-¬şíE¢Ñ¥#b°²`Xu‹˜8}Áµ|1ßâ…ö‘JdÆf©ßÒÆ=Ìi¥+mFô.xó·š-íJäÕ«èµ½Ö
16r†G4w¦×¶ÖÔÒQëºïX$ÙSXY&Ÿ(W…E?6“u?¸“YÌ8¯¼Ğ	TŠï:{Ä8ôzU‰×ôfxğ má[ö2úÕyÎïV3-cÂœä¯yYızã'}3İº9Ê&ÅĞ^ı¬è],kw[[s26Î+Èa.eƒ¯„9HİN®Šé]Òü{É â®h¼´zÊ5x!Aêèª&o6c¨Â³ıjpç~­ë6íİÒ{<Êù™4|ÿ¼¦‰˜à®lŸî,7àº¼*aÛŸŠCoG´eŞ$ey~=¸ÿVû°>‚XfFâ´Iœy££pTú˜Ëœ!HTæ½µÅçC>¾ro×c(­ĞòÂHÈ|93iDÍï“ç£Ä¼8J@—í`gaT7ºèÜ‘Ğ2V0Ğ[ƒR!Â“¢Ùxÿsc·SbycäÉˆáê2æGø•*ÂŠŸ$júdRÙİf7Ó3¿NºõŞ»,nâanm|uPÈ*C9¡ÚòM¿O4ÆS˜¸µy—•ó¦ôuA«áW³9Îœp2ˆÓ1µßdï ‰ÁJeºM ²0|a×òjşdhdXş 7Çëıö{D1[ˆ¢|ª8X\…n€±O”˜D64Ä;_ÁÒz_}ÜDêLû¹ô\åÉ SXøD®9©L5 ÃèÚÑ
¸í©ƒ¾TPÒ…A¶ ü‚¶C^âg1Eöã~îÙÿê¾H|ŸPróIÈ§«È§Pu²§P>W ò9—¡i>†@rM¶	ÎJş©ç/á¿‘UzÎ:ùø7?nŸ¡Ìpœiö$È.QTÁÂË¤%× ZBW×E={j3É¦Æ@`¶ó.8 &fu‚‹'6½–šôŠµ¨ÚÎ0#|Â|š(6µ¹q$<NJkU·EP²tâë‡]o	Û¹0S†Çø¶¡b¾¯ïb€&§"ë×/¿Q¶ŸÁ1|œ>}¥X”+¼zYsçm© ¶BKğWÒôÔöâ‰ió7/2ù»E"gå?¦èÒO€›øIáÒ^˜ùÀÇßæ£Ö2—¯ò}O?:ÌÃ­å¢FÁ£({•ü,5„s^ ÆgºIşÈQ<l@‰œ$XLiH‚fÔ7augÃ‘¢”gÑ¿é|£äw_fDÆÖ›MIõ#X§&©Ğƒ‰Oƒ²;Pßğ>òSôG™îv=3!Ã«¡\M Œ[C…fFDlAñ½ÈLGlTŞÏ0.Uï‡AIªƒ† éûÄNÙtT"?$‰ò•L9üA rÜjš}á®<ã¦Z?2ÿy”[C3™*ßÀÌÁU.®w7Òˆ2.´{~'Æs+dø²R‹ú°Í.×DÌ	åçLå6m=÷ivøİLÍ:<×qü
s<3J‰–˜¢·;*úŠ±Ğ0ğb9vøÊjïm®aAd)%46&. ™-’~Õöó” ËÊŒ/iËGÜ¸h¢Ñk&£(ºúë"ƒ°Ü±D<©Ãä˜I~•}4+ö¦möËv"Õ³D²:™¢àä¹ü´‘TøĞŞ[m”ÚÅ0ÍM¡ı§^ŸáeÛíh_É5¢ïZö:œ(Ü mzÜ³Xğ°Ajc"
iµ#Aìw®ŒŸñ{
!åy¸<ÛÍÔóH¾CªM¬
F!ïa¦EHŠ$]QM°gƒ·Ã.=îZ¼…973Š$bşÕÿ½8ágTËø—=/ˆºŸ¤Jš’;â#ÌÁ?+²1—ÿ±ê5À¼SzïİŞĞÑQu½ßà#ÍÁ0ÚQñpsL§îjNïĞG|Lè<¹ä1J£Ê)™2!ÖÂ/{ü¼°ó—+p9FÈŸÕ¦£¿£|”rR~¨«ÊÈq6X½'Q¦À“Ü(˜¦>÷ |N>¤.ÁºkdÅGn-aq_FÉ°á—Éº‹Ğ¶ïàEº1è©¥bşR§z”ô•äµ#ã¤üx8œB};¹²¬@ÑDÖÛ*¼‘îò£)à—Y€¼Rcvá”ÿœÏöÜNöÂº`¨Aê?\™¡î“Ò{Şšf7BlzİÙxX11¬å“JLÌA-TÀì;cİ_wä(REaöwb·4¥#LNĞ^`J1Æ³%=±¬ä¯°å±Şù3À#‰	ÎY,6³r$Œ‹Ó-¼i!«ãµQGO>¤yZ¥«bïíÍ{¢ü±(İ¡¨èÔu´xûzÍpànm‹é¿s7(Êtâ=ÓxMnD-ëÉ^ßÀ—r—‰ÌS¾†S¿1öìm_i²Åöş9¸m$&‚
E™BúçMÏN•fû+ñÄ)XáTì£ÚPœÃSh¸KÇÙL’İÕPŞšæ×°/ë)u”àâCyW6éL)Ñ?®`£"¤%ı¤A%»¸ŞLÏNd³ûş’5<Ó$ÇHQ	Ã¥<kÙñıªå½s©SzÀˆ”ô^:ÙxcºÏÚ–ÖklíâÀl¥ŒYN1RzõÛ„œ?£#û‹ÈUwHè°ÕÀwÈ©ozØR­§™ØZ	¬€cU«šf•d‡ /Ã<ôšCSEUByèêXësÒÚàÒ£âRûÜ˜ÚKe2F4®
"èÀFAìï¾IÍ¹z¡µ¦!šq2¼±Aóª*5–vE´Œ+Å'§?48DÃ¤16?õ0„š×‚x5:ÆJº)*°XÂçÎ~ ¸æêg|Ş$ğÉßköÔEx.2•`¥ĞeóØ‰‹àcß„/¦ß‘íâ›3T[çl²Ëì¹Y6Š7Œirè=c@æàâ‚Œ4ù[æ
Ğ%G@¯7,Ñ'ÿ~åNx ?1K
{+£G-áã‰v¾šÈ8‚Ì;ÁŠá;<ßÜªDŸ[ÅP¾›gÁ›Záì­Ú­U×B(K8[)°è‰bY‘ˆ¢@è‹¦ö÷r—»WÒ°ò<H#)à3“Ï‹²?”#äLxÃˆ2‰Øn/ä—NÊÛå0À°’l&3Š G;;íĞ¹%(íLtäodm™]Ùø?Äf.àN^YÁ^V	«ÙÎ†VºË%Ê¼îY2lp¶¸tBÒ,ğK°I½ì]dšŞd/ô™Ÿ‹åçS¢Ü ª‚áÔğuê_º$vY€ßŸBû.[ƒ·²`ë·-1m’ú‹ô“ ÅM$¢QY»Ä]Oêv‚ïaöY_XÎï±J7/°´œ‰’BÃ°
$áêò+S,µÍéÇvÜààœu«ËA gÌÿPM3Ãµ4ıv‰ólÉíCR¾/VŠõ¬Ï3äÅ§ö$…Ïu[Ñ~!¾Lw’Ó Hà‹ó·VsÁ=¨Ş&Â/Òp“‚#csï<ó¡áı†Åş`áÍÎx¾ÉäÎÜ3etWÈ6Jo‰Å\^á¢œØĞ·‚¶DÔÉNï…<K:Ùi6Û2heóØJ´\‘Î+f±¾g¡Š£õ7øJØ=OË%xÅ•0	Í…–¢0Ô¹ûÌ§= Á0«a8‚ÙÎ|! È¶:Û}¾è„¦4|…êz’2^u«”.cTZqz…BõÊşqí"ÿe©ÕááÇE¹&–®zj®rïÿ\Ê1Où¸%ÿ´ÍœH×ôğo×ŠH)7¸àĞÇ;‡fd¸»òåTTÆ#­)ë÷Ê¨58¤‘ëØß
ÕšRQçk‚I²¿ÎK~
×ßOŞ`HŠ¤~$92ÇfNßBÌœ€u¬÷:`Ä3lÈş˜I*|wÚmGwìè¦^G
"½m	«ÒÎûPb"‡„¿‘ÜÛ×Œ¶úØ*ñk`¾Y^ˆ?Í_{om]ãç/ÿFØ ’¥M‰Ì¨şéÓôµÄJ´æíD5%©bï&¼÷c-©êÛÿIReıÜób…ı[à©Ö]GŠ5ÈQ5è¨J×İFs€±=AÁO¸òe
W¤œFÉ{ê\ĞB;fÃ]Şş.…2Ršiÿÿy‰~¯J
ğÊ{ß]1Òd‚²¾ı™™ôc»ÍƒíòO'q‰j4ıô´ŸÜ95² B_œ÷Ós	®—ó‚¸KÜ%Í‡ßÖò)ŸOU5Ğƒ[ûÃêd“Ášg3}cËXsœ¿™/<(<ör¦š7ˆî•§c÷¯ú¶rÕ`Å!…£d0c­J%«áômÛ‚Mj[nÊ›˜H[R ì>~ÉŒ˜!>ŒÌ>?&qÄ42Ó<Â:?¾‡B¯Â˜¢öÈºáF×4Pøè0KËº9Q²\]®˜RÀpH.=CWÓÁitÿóÃ£»ào 4D=ŒÒÇ™Æ[Àµ†ÿt®'E4Ê³ŒşrV ¿WT mªË~@àµwt,ŸDGC&Š ÁmäT}¥àÙÊXÒícÂ¡œkòË`5Ó¾=mr±¶c3ºµ¡ªx®¬I)xLÂ/5v©ˆ™Ëg1Š+ßQµâk_Ã¢yRlÖª¨ P«Ù'‘ ’–Îì]œĞ=¨’¡ÃìEÑ¿GÎMŞÒ L~ºk\ºÂ0eíû1 wv!˜œPGzö!XQŒUk»…´~ƒªÿùQN€ö+^cû`sí.r»£½ÜLYÓİÿ«™¦ [ïË±]Ew½_ãqh×Ja§KÂ’ÑSZÿ,àÙèH•Y«Î¿Šd¼&ÂN~—U]
Ç°ö…4æ°;İÄ©N™DŒ]´3ŞYÇ¡…†ër@…õaS‰4,°#3¡ï5Yÿ>CÏ ®"÷]GÆ6ßD¸c5=$ª^À€FçâÔã#,×^àæ%–	 ¶6&.XëtV€Ãm¤Z'ƒ®ÒQÎ=ÚÙ²hWC•ëOšGƒÉŸ…Mœ¥#dÍlE€ØÊì1é‡lÚ¿$“¾”ø<üƒJÕnšè¨qøâ‰@: MæíuŒ„:?‘-à=ëN SávÖ‹XO‘`øcw¡­J ªâá£âèG^s9œfõ•ØYm[æ¦)Dg=ˆÕ–<î!›½‡¥<XÁbÎ\ÿ‰§#û â„”eÄ
IïŞ”)«oúÂR|»'6+9óØİ:G[E4ÄLJ$Û?5à ›”£Šõ…úšş‹4¿©[¯‘è$©6‚üçÌà6®†Òœ.'ºÀA-I}[Î-^À‡DšÊÀ÷sQ¿*J†ığá4œ]Â@ad`1ÁÆ	Í®à&6™I8›ª?úS+˜Ü¨‚4jŒÛı¡¨‹ezdˆ‹¥„ëú"z±h[Æe½M,/óÀa¨èú¥.cÕIY-•íDğ”ˆDé@—Qı_­^Ã×”( JÑŸÌ«Ä„¥‚…ŠÆ‘ÚCM[¢ŠÆÛ4-Œô€Mwî„LïÅ~i†/ˆ³ğ)ø›8£c:)ãH:Şƒš†<À·—´Zx+aàÉ‚£ûÌX¿‡AGÍ¯$ÒÍÚã—MĞÜ3ƒB8#ÖD»™B`›ş­úBìÀvºR*AªnMnÎÕ¡Vhq³Tø‰tÛ„%k1]}‘¹)ò[±“ŠN¿K¤xˆ1¸‰“½É*Må(°3fözà;Ê¼qJåÅî¨¨©RúäE_i1é¹¥Í!Ò%caROĞ‚ê7ĞP5<é^'˜ÌaŸ—á•Õ°ù²Èæ.Æ*”˜ıA„–‡S˜2^ÕìwvöbWUZß)'í¯1õHÈ=°l7ù5.tÕÓ)[ìšh’FíQŸ›’‹š•mØÏƒ«8´ül/nG¦bá%G“Šw"µÂÚQìAùNÆXVÎj¸NğKo(fMæ¯¼ç¾Ë*adÃX”ëKÔ‰v=€çRq@ĞJYcÌKF	ÔÜkÇæ ’ÎCÌaÖï+³§1¤õ_éç\sˆc}¬Éãû&·œÆğÂçÎ£$Û£7Û ÂTw+mAÍŠcaRótojFŠÇDlEwE“ù-EôÙ5kA)<4µ|s;÷¶£]|UêÔuÙ†…3ó®ôÄ½R–¶€¨lS…+L—ëßf^8FòHz^I¦„¸Î:œ7aÀuäÜ‘dL'Sü2DôÅr7c±Ù óEÓ=Óõ8½S*¥ŒÆî´Ó7"ÁaÁO£ªQªŠĞ¹“m#ˆ5Bê|S óŞæ¾Œß¬ÅÍ†µ ¥5ï‹]À#_ş¨¥Şü\ŒcÅuÅQ](ÊU‘x[<ÛÃ*çÖáGjè£8^ûÂÒ9ŠÍL.C$÷‰U8]º¹fÄ=LäÊóéÏ–K'lDx‹¶õ[fÓ!„?±(²aşqËçs‹üˆìk¾8/r&:¬JÑJ_(İv5ø»Ä»ú’ ûÅ“ÜØü÷*ú¯ Lwiò#Ö)KøÇîC-œ¤qvÛ”§&È9=<„ÖÃJq¢óNN3w™Ì>‡¶·ğ{@àÿ#œu".+ú!Ö*İûùM“Ó7}‡ˆ¾Åôgˆä§#aµ>‰º©Âã„õrâä·K­^ÙvÆµkÅÊŒ©­3Ø ¢PÁaIƒ<[”e	aç5*çöÅ;¤ÒëË±iñ}ÓÔì“õ<ş˜¨¦‡€ùE“‚¡2?«ë77bZ¢Øi)‚ƒçò7ë\R.#Ä½¬<Áğ#RÙc—òÑ.R4ûÎ qEƒL³ì’2|}Ã¾ç‘ó^+Iw:i÷—Œ×‚Wh¢ú( e^OÂw¯•º spİÊ€¢š…½¡ö‡¤GC‡Ù÷ğZ'’8Tá>qñ£¹§ƒÁç÷KÁ~	Q§ˆqZ:~J<Äçæö?·ùyW¾_!$·…( Pé:EåfØŸõ"b:ÍQz±ÕRz•$dùĞ"Ö>™ç2˜½]êí¦58,Ïz~ølg˜‡°¦Š0aÔ–@.>®S*=@`[â¡!ß(_´ÎYÀ×§a*æ|“ˆÜåO—Røweô°İµzn@Eqí‘èJ<)]a†¡ó!ä™&ÿ×~À6é®4ïoç«Ík)œÇ~OàÅèÑ(–·d:DLÇr-l#¢£RüdBğÚÈL İ—a÷]kÚlVşb?OâáAœı·`¿wîœîèËY\Œı5>³ÕBR èL»™*X^ñ>+,æVO¬_{0™	© ¶&öº—¿sy~à*K‹óÓ3%8º)ce=©‚t’Ğ™“ˆ—öˆÀLÄKÄ“çVŞ·wïnËzæ€Ÿ:áÌÓ²€"®üÿ()x{/T2µhe¡Ë_ÇèTƒnqgD6Û³ÄöşwØS—ñÍùÃ¡	ÜuÉÌRÈ…å:ñiæ]ŒßËÙ)nrƒèá($ §1m$t–“[ÂŞÔWÎÄöÉ‰¸LLx"‰å]÷<Â„;ªj
±/éÈ ÷×*W=Ïğ†Üª1J:z:÷—âmRä‹³D³ÿîóË;
­§>ò¡jò»¨Jıcµk®A…Ÿ'îó3"v´C-Ò¬kRpj(/´ãn¥ü9LØ8\8ñõ^ø$¬Ÿ>lp[Ù×‘á™
üókÄ%Ó‡4ìKH9©ñqhöjp@×ÓÚ•‰«P!ì]½j»tÇ×ÌÔøiâÒqçğD±ß”5ÊŠ …ML¯yoM‚NFËÍ“º<‚ŞÊòdÀ‹CäLÕï¶“¸¹x(^n•½w‰İ0ııB»ºSüUô ’Dé¹($˜”bİ^ºÎtÄ*şÛô—8ø rÏ«œŞ¹IŠ¨lĞ±uyãğ^ì;%èô ·ÜÆÅé¶:Ttx»Ÿ•3@ûëşœ™öµn“®ºüz<ûƒj&¥^<)8qòÕ-:’ÅÅd›íò–4®M€·æà$°ÔÁ¤/Úøÿ‚Ù‡TáÄ”ó(ĞÏ%±õlÖ·hí+-ë„h•P5ë%ü‹´5V4;Ö.á××=HÍiüÊÓº-ÿ7ÆĞõ=O™Òf˜¹(±¾‹shE›ÍşÙ@>M\ÇîÛH#8H=?@ö'yíãDìHÿ¹)8`Sw3¾s©it›®Ş„ a¥5ÚÔiÌÙˆÂÕˆ°8½$¤O	¤ËÆ‰D­•=;?·:±K­Î\K#÷—-smexÖÖ',[`í#– |Ô·g³çz±JÅ`a%´õeòOiŠï!mI/à¡²Ê—Èô¨0bíO‚"±ŸÏ/³wMØä Ò‚Ç¥¤vjpêcUşl+'¾úH‡08îµN5ãäâuÅa[Šò\è‚Ú´*î Ö9‚«
p÷“Y]œê]q¾ò|­+§–µŠ9ÀZ¾‚ˆ'òú'ŞìˆØòs
rœÀˆ^Ò]<AŸn™LM;İ,>bÔïÕ¢8£ƒÈûAb›Ç¹ dNÚ¼D¤ñ¼Á5’¬‰>ÆEX/NVÙúúíÑÃ”:æ,‰ÕD‡ëù|ª+ •|KÉò[¢»3ƒA»–-îñÏ8Û=ĞÒÃàèw èŠ×ŠÏ‘y
İàB¶G§°I†	%øîÒBíñóÙ¸È”wDYŞÊºA –Ô€ş1â…¶¾~êr›µ`ÊöŒ†óıEºÛHÄ~pt+0. G¸6é#FR@ŒŒËP–Qô¯Üë˜"À*!~•8¤Š‘EØÛç—ŒL…i;µÄ[e‹‰óÑĞ®C.hÀ"Õñ
úåQ_k5zPº¬®ápË’~˜uE'|J™ÀŞ
VÛæFñ?ˆÃs ¿9PÑ‘·¼"C8·Ûôm|Ê=-•[Œ¿í¦²j¶ŒiZB‚(’–Çóú¹ƒà½„ÂDbÂ11ß&Øy •,)•ó¾'s%²ly£ïÉ4#áë;aCg¸8%áÿ©&×=á7t‚Jûc<Î§¶ ôâµÆ?5Ä‰^ç4É‚¤:clÖØi-Ã-f¸I«°Òğß ĞÑ&ŞË=¢•Šı5~hŸ¸¢bd¤ıc£Ø‰*¶à6ÆêLs¥`i0ï¦—g À‡F`öTõñ¬Ğ’å—)vê#nŞ%ËF2€Ú8ÚSWNe¯e à†ÙØo“G=œI˜øPÿ„…ùv+†(¡Úüş¨ÃÜÉv‰>úÊ!Ï<dR2Dë_7Ô;¦$WQ´\ıOik°z06¨Ë9âpGlÒïÖ#ÀñÙ–†MÖb^˜OI6òB-òdò“bÃ¿‡lX±¢wJ‰+¤%>ÿûö¢W_j'2ô¤÷~]bìÿ²uZÙäÇ¢íØ¾;}ó¹P†__ˆR3…$›¶¦æ¤œ³ÿ’øaokTëXÜš¿æ	şÔu€Ée-*F—0L…÷2<¶•ÀvÅkªö©$À£¬Msi˜Zq(¨«ü‹î“µIÖ/./Ò&WBÛ4z‘häDDI¿DI#Vo=QS•[w%4ÓNN–xÎÀÃ±Ìâüp!xuzˆ¦ï­‡˜nã
&>´~/S.ó
ÇÊPÅÙ=Wuíå ö‡É”­«úŒ[n¤¨‹‹†Ëg^À¿ÒºüÅìæ4»ùç!:<«YVB	]C’uHH•ouhÂq
©qÃ¼”å4fÊ´"6)Áé’â·î În	0d°$h;ï“avßx§àÜ Œ‰ix‰FŒ1‚d»Cúæ‚h.`w²·±ü¿İƒB1ËË£í&0,ù„ õÏÓptŞj¬sRHà…j÷Œ;tQysæ`ÿhzìLD§ş×Ê-rû¶«ÏlÓ<¢•õIH}ƒ µ¾¯ºè®ÎvíßÌ«dn©Aí=™v’»|EH:'õºê!½^Vıu¡¾„Ùé±*î€£¼ÕQúi‰9Í€$
°;Ó-'¶CX»öşäüÖ;$C—à›A#´®+Gå†äR:B{ğàw‰½…Ca¬tÕAŞÍ`Éƒ÷ÂPQ‘n¶ó˜dY²ğQWú|ú-N­Ğ8ù/¤CÊŠ"×À÷bqqZ
	(÷¿S+mO§w©îdè¬şè/o‹¼”êİ?„yÂh¥G~ø#­ÙdœÚgpÉ§¬he.´8¢&n$	öœÑ3C¡Ã 5ËV(A5“'–²™TÏŠ† º<Hì¥ˆ¸t$C–ÆÌôĞ®ÎÙÈ„‚25	•–y6Äv•—ŒÃœy\Ÿ­š-i‚ ƒ)6¯V0µÒİêÇ¦ûÇjNP¨´Î°\ç+H‰¬L;7 µ¤6º&:ÑC»áË0Ïd™ó-Ş=r&Ü2:³mÚÊpK‚G€I©¤Àğ//†\¢Š1Ó
:ã¸.¬¿ˆ™Èn0ÖøÍo‹nÁ2Õü „Ñé‘¹{ø¯‹¥ÆÒ­ê¡­v·~Œ´é®&ædê›½fcœÖ'!j ÕâŠzW£ù‹›
ãdı'F”·DãÌÑ13€R³IÎ¹ ö!1l¹;í÷–’gI@ü)ßYh&¬FU\Cwš”aŒ˜wÈSï“}
§ÍT—À~ í®ç9¸×*«öÛ%_|ıAëÇèŞÄT0‚#/î¬jãä!²¬K‰>ËÒì«ƒ‚z§¡wU§ÛùªÉ* ‡´Ñ]³«?Ö*^sòì¨3&Šx á€ûµ-˜º`éá*P"HE€‹Ì0æœ*cå^™4¨ƒ­ ¦´îÆ%´;|:Æi#OA:Ñ&ªYñ…˜ßm‡ˆØ±àö¡w	-5Ò	ë€0G6Ø-HÓÕiÿc®!ÛÈc<å÷ÌÒí{@›Çî¦­D’45¹g®
!ß·1í4X½fUA±çÓv=(@;÷àÿàŸ,ğöm†9·ªw"°ŞÏ·…5áß®Õâ(€„XYä½o‚ˆŸ“R¹Õ¶IÅ	ÀğĞ„æ¦ìw£è:§ê½†÷vµsDp§qèü
–V¨xìœÏj¯ÃpÁê$¤â ËèÌı`±ÌîÌ¢;Ne9ûØÙsEt'qhTó'ò“¥ŒŠ_Ûéš€«ºÛâÌ­w$gPJ­™‹_‰>T~ˆ—ğ³	ºº#é8/Š½TPrCYFš…wÔÖ¸Zqğ`/÷åÈ¦Éèğ0;²Ü*æ–4Ãá4ÆšqêªK&™Öp‡ĞùŸÉs¸í­‚#üAûN$øY;0ÚøÀĞƒ·ÁxLynE”dNoçNØ§ãû$Â±‚‚Í÷ûlN‹ÊvÀ¼c›#ãpBšQlˆ‡îyQxT½)0y,Ô^kN´µ}¬¢´•ğ“É–†•ŒWgŠ¨â&N›¡	ŒwS»ÈOLÕ÷˜±/›ÕàòK?¹ñe³íÂØxä*nÛ—h	×“J¬’Ãë;2Úøé:ÍL7«ÚÅ"?¼±şHºûjıà:÷:ÇÂ[¥fÌ‘áN~²vd®¥şå.2Úéµ?Ğ÷ˆ¡fúY‹Œîe¹Ü=)âæš³¥=Âœ@òÍâ÷¿¨™‡:Ùœ™RÎë¥¸Âµ¤Ï¹Ê­
W­"-å-!&fS,<]]îß>‰Èl†78•™{€ooQâPÚ‚Ã×ƒòÇÿ_ûó±u«{êß˜¤‡§“@àÚ/YÏEüuèLºÒ©0Äkõ¤{Á
uŸWÎ3iÁ/ƒè‘+¥á¥Øcs@@¤9{u!™·ÔPbíËÚtüàov+ÄAaÇ-ÿ%XèåtP#HÏ–ş)'LË¤ªíp@ôæÍ£¯Ô_çæÔ.4!4zMDDÁk[DÒP6`Ü,ßhà¢ ¿Qv¨àcFˆeø:$Pº*+±ÜC•PX Ø4¥ÓÚ½&ƒH7ù5#ı.æB¨·Øè-úê9;>æY±‚ò§8çIûÒ|lê†½±f›/Ëÿ»‹‰N ÓsR“WúJQ&fzçÍ÷t½ˆÆÍ–êˆ³æ¯şæÛ‡å2ö“ÏjZÖïèÙ®]BL;éÎ·]öy§x´Ü’#1GÑ-µ G"3
nıM”5V8dƒ’ “˜}¾»°õ{¬‰D¦³Qp»,æ©hHÊW•Á¤&¯tôdÇ«×ì«a1'«Ğ¦$:ëZ¥ş\	Kƒ¥‹fAĞ5üølºü›ñvú$|D-µ	åİ¡(s>:ë‘SŒëdtp}®>së²a.F8ãÑ©nÉxØJ?dİoÊ*á”ô^:+lU
zd%¡§Ş©İ«À§0èuô(Á#T" &É£øÒõÒ1¶©å)&M$'ÆA`nóBö r®&Œ‡?õD-,7æš]¿3ma.J?ÀíÇPKÎC·ÃSÊ°»w<µ”c`®æ.Å–Éy{	½_k¨k"uïw'‚WU?)^AGŒ"Ï€çù‘¤©Ã=ZE^H%W\8!W.
„ŞlZĞ2¾E°(º|jíf€(½VYWjéVdƒö|nã*&áVõïW02µJT¨û¤C*]`WÀ‰-ùûøY-˜Vªª$¾üğZè°ÀîTÚëNbƒŞ05Ø'Æ®³¡+l’òÉ¡NŞPª.ú”Ùé,¹@Ù L§ÃšVi„_Vs=Ç}QT‹şYé)W²›;F‚ß3¢ú à¯[#Øÿ"C\­¥¶‘¿†Ë±ÈQøó¯Ë>®>Dœ	ãB>À&¦M¬xß’zÜ"Úvk-¼3ş°JœKĞÚô.WK<9¶Kï€‡}OxND :ÆÑ³ïCŒÜyÉ ì?ÜO™äàôQQ<~¦[ı½ EÂZ¬ŞtŒRê°%İKÄá>à ŠÄ¾Ï1º¥CX¶¦­\Tê˜“G|ÄP»ÓÅ¿Õ²@N›ó”Âçó£	l`šf%PSn—·#·‚ŞnB»¢XÂÑÅ¯¦†ËúL-Úf™:'ñ§‰‹#àÏÅí;0K…Ô-.‡•÷[Š×–‚»«Pc»Š=‘½D¼µzı×íãüÓ‰)[§Ö7iÑ~êb²ˆ}U]º,w5Õî©¬ÿ»şÿ¸x"ğ,}ˆ}é<æ?»¤DÓaß¾ÜÙ&)§¦ñ²£ÿø€×ÎEë sö½bøœö—Y 0¾LqÔŠ¦æ´q:h‚#­Â¦µ L€ğÎOsO`u³	{no Wl*Á`¢RzAİ°f.Xt´¸‰LÜ´’Üøù‘%¸^i¹ŒˆÀM Š‚Pr,+)
ıÂé±'Ià¢o‰j`™Áš’¤ù=ó´0!ø;Øz´^pŒV}íEÜ£–tË]òkCàòÉñCbğFã#mıñş6•q3··Ÿœ[q#¬P Âğúë‡Æ*_h8kB×HN06}$¶—´ 1à™ûñäÑ·OÜ‡r.ü6ÅŞÆT³ö„àÌÀD9‚À†G×Ç¿Los°©ÙÜ²0#½ÂVô»îlÆÚBÈÜM…ˆs ²~ŞÏ¸Ø4D¹„D!ã×Ó!gx£`ã	í¸ï¯	™L{ÄîúZVĞ9	gî&Pë$úT»-Y|t¡¢–0·0A[™–˜şl²€«§_6şv†AĞÇT1hò™a²\³”'y7¹k6ÖàÕmoŞ¼Èç¨g¸Áì´Ê.	Å²ß¼$²€´Â—V 3É0[•'³ør}a,Èd43˜s>+®ö ÿcüÖJFä…R½ªÚ‘wXº¾jZI<Ú1[yRÓüü¢W¸ª]"Î„rÄX`kWzöšû¬âùqTæ	óq@±oL.‹ãK8˜;¼^ÖY’Q!á6x¿ª²Ã•è%{ŞrY¶gM`
òLº¦J ™-sëgÃ£9‘b§Ö¨Ş´xª¼ç¶øí+OÖ!”X&LvÂñÇ]’Uï ÷Éú «B|t”Ó¹íñE=¹>Šİa›Õ¡²ßgLªáF1ô]†MRµ6mR /7å¦˜aX'bß´<o©Ì”xŞØ®Îİëòô®»ffœ‚a~@¢›æp¥º œğt<™skwJ±i1Ó.5“¶j4¤®ÆÕzExİõÊPW}•(,TB4á•A?P'R;:•ëÊÖÃÕ­ã+aTXêü’½êpÜHŞ–İ%>›' èáÕâ‘è6¡¯f ƒ]ÇåŠvó€À€¶eG&õîIŸ8À¡8e›p§:…ÿY¨¹÷BÊä 3Ìo:E¼ë0¯û!á4£¸M¡I¨ŞƒxÏYSô»f'î	ô0\}İÇ(KB²;€R‘@z˜.Ôk®½¡¯¸uÁë°ı8”hæÎ‰·9ä–¡$µğP|pµö#`·Ëh±­G®³ÄmŸ‡gÂ z`'xBÔÑĞYxÏğa¹âÀZ$kÊ
ˆg JtÉÏ›z¿¥£he£¶•’qııœã‚˜Ì'}°Ê‘üWT8ĞÄƒšàW`Bƒ»À^´°´~ÔÕÈf“ì>T÷dADòä±İ|„ß@¤d<x˜¨½#!¹wç•ç¶+¦"JWÉ·<ÔùL»#œx{‡nhjÓn}]ô³V;áˆ/¾Ğ#ÍÃÏ¶Ve€ÙÜOç¡$‚îûóbÚæUòìjÃhS{"[&R®(˜èa‡I§œ‹Áe¬ºÑEíeã[g	æÑjìP²¯3‰µQÒä‡
í‰|NAŠ; pìzŠ=V½¡ÆY´Áaõ+¹B´¯Ö²ÎqÛ4˜¬‰OÈŞt=ö~¥˜"2½P¦²ˆ'Æ:p“Ç	Só,q…_®EË“ñe]†€¯×Ûaåµ—:Ÿ ÙÌÜ¶ƒB`Ì3¶şÚ4m]Õv„RI£òHV‹Æ½TÄ 0m¿ê¿Ç»A0ñÒˆoç
 »!ü6Ífm*êòp’(KdavımæÃş4ÁÜÓlÛÄc\%¦Åx¬®`—•;	dª±L\ƒpq5<T“Õ|°ßÜ%[ØC\¶{u<Yo
}³®U†ÆGÿ7×q}$æ4#òÚr|Ó6ÓßcØş-Ÿò±ÌÄ1§<F!AlãB”;şq!ğ	LÂ5x`D£Mìır”tØwª‹˜Å±Àë:í7g›æôn÷,`Ì—vBFâ‘E²—ã]›rn ğP)¨¨QşØÂ¿Uyg5õÚÜfÑÄõTR£Ì
}ˆ‘)]´>0mİæ¢(ªx]BU»­z~	j*ù/”¼}uô¦SøµàÖ¾”
ùIšB¼Çè‹W¿'{)etgU•lJ^YŠ-‰B'[W$nk½’ïó~¯€”W«=ˆF¾ã7Y^L»ÀÏ¾ûô
‰:ßÆıèCw÷‰`_t)ÛÜ‘© °\¬fzó¼gåC \2.>´£|`Ao$­$øbŠ-Uî¹^’‚qU¡øút($!˜ê„oKgÁ/¯¯%ÍP&0ÙqşÄÖ~öš+¾µKŒsnö[µj‰	[9G)V"ĞÀ_¿’l&ÎãâzúæıšcòsÂJ“+æÁ°Óö·nÀ›ÿïJ»ğ¹aj7ñbñÒ;[×‹8Ó_®–s¤/H?R9‡HŸ~D|=¶²>Á‘£Fš.vyG¸_X[P‚øÕ¸¡*ıüıÁ4wØšñ„™LÓ²qà4Èl¯!²ı*« ª&trÿüs2ÒF‚İîÒ‘:è}Z0aáêfÁ8q}ÛšïèÖ«a-™Gµé¤ìLFJ‰ŠÉ¨Ÿ£2
ïå»"Ÿøò_0Cj³)ù)²•ºÊ¹åŞªZÁˆŒMÂ.fF3©§à7è{.÷+X#„"BşÈ^m÷ªÑìÒÜ»³z —MN›_|ônêˆŞ:£A»@‚6!ÂK£§ïîŒÔA¸0s®P^¤]¸B¡X¸-,2Û†{)_à{³ò³Æï±şúX;¢!*Í'²oO9pÉ›³’ª›“áNË" 	¦tà¿[¾Dd¤¢óp'0Y^Àˆe‰ú¼¸´Á’ú\Û¦¢ƒí¹¨xO¶F6Ä&¤dQ0o¡­wbĞ‹/€Q3ª^E³¡œJäyã†ö(¶~+´: ‘û±úñô‰Ä+´j±ŞÖÛĞ
jjD6(œú81§HíğûõLrËëÂéšŒÚr1g8¤'Û"}*¡¾Ù/VRåTpïäª#Ñºr¿³uÆ‘¼ï¤X†
{×T@‹=ÂH[ŞÛ¼?1;H«êG¦ê'4¥ÉPàü5Š^GÙ$JíË<	âå?Ó:tâãÔ~uuÚ
ÍØÈ¸›üSLªÃyû½nîg Ì­°ğt C²D1ñ3;Èµ4¸™ôõŒ¾’¢¬nxÏHQVœ¡3j¥õÏ6ÒåÍMœ›Ğ›Í’
;X?ˆô<cÊ¯dxfbè‡”¯ÂòÃVô!ºO(||ï«£İÔïñóéi· 1/RğmŒf˜¹)DQ„çÛe¸TKG!sŸİÍ8A>ti¡7OıÍ?^xj[Ôª½öi¼%1Iéî”oz—µJË½A®[}â»SºÖÿ–¡ß±ßëhRog¶›}iÎlÁ+F2AÓ 7‘\¼Œ•ÖŸßˆ­Gçô¨†)Úœ­%}Ã‘Ú‘ˆU è**SHë80ä³É^[^×ú¹^d¤ÊÙáÌĞ
µ)Úa+w”™Ôç“ËÔwXŒË 8fÑ"Ş¶§–å|&²º,[ZŸĞx¢çÍJ>½ ÿ.ÌSÉQìs5DgkšånBT“H3ÄáfëA~ÙªgÀ9Â‰ª#ı¶@íE™òQı•šË×¿ @àjóø¡wu–
÷š…ö—\¢	VÃ¶…Ğ"œ{.<@È5±él±2uz;ÚîbÛ4@D6uåÚ}
2iÎ?®m|ßŸOäB»¼šXaQ>í£b)eõcB‚è•8à•Öáß25Ğ~4ÁÃõLcÌÈ}Wb˜pü7¯³SŒë‚f¢ü®VƒÓf7±Êı”"Ô3dNª5¯Úä<	¼–«cºvRØàeâá9ñ)—¼LúÊ®Ğp6Àè…°+á©oõ	¬©jZKÃ¼ìM`-`*TS¢
@§Ø¶† 7­»@¨sH{]ãÉàÔa~êD<ÌRt,ÒåNÎ$'›û5÷+Ùô ¿iƒÎD:Pà+ixnl9—ç§xÆ]æB«çsŞ…A’ªî{h¬’]M›yĞiipñsMÚ:tÄGé²]—
>Ø·22ºİ¬ÖÆË>× ™­Já˜¹,ˆ„Ìış§×
 eñó¶–#™¿¬÷,VùÈ$2SD7ËÃµ¢\kQÜDƒ…‹.‰@1¸Ï ¼\ñ†¼%ÕQšíÆcÒK[ÊÀ»9äÑ0O¸ HÛ&Š˜ê¨:J_;ü¾¼~“‰k©0Hçı˜~Ú[FkÊs<ïÍf`„øöqò+³ıRÚ
€üî‰¿‹b9Á&’¡ÏÕ¤¾aø¾€ {.?DuNúşÀy`{é9[LXaÜ(·E5%Vã_MÌSÅ•K¾®\
£ü¤÷ıU0ÔÊıŒ¸RŸĞ’ƒ½òG%„O·âì,kd­ËşÁÄãŠ‚ìi‰Yî‹ØGÖù‚yÀÔ±©q^Ş™êÚ»7µ/Î:Àil¼QÀÍÇõù/êJ0»@ÇŒ”şªá!z£Aôt,S,æ~Õr£ ªeO2¤®q¢ªÂJw^ãxõÿÒl="^ØÉ=|_Yˆ
4–ÍÎ†Åü¶ÆSğé] Ìø_¼t¢œÎ5ÿVíš‹˜›¸K´ÕÔÁš ²¶-~,´Õm—;“GÃ®^$ß«=Cdìó÷ø^ñUÜÉÙıáS§Vt¥ÎƒôK5ã ÇéàŞ=`ve€œue ‡IØşx»ªaawT/ëïÉd?Â³ö¥ìqîÕŸ""zr­äy×ìmû®„şJŒVú­Ö.É¯8’ÏÂù¾êÄ‡"Çz§.ŠI>»AûIì8y£}¨œD Ï×«ğjß•§øn€Cñ,õƒPáŒ	†Sîã¶¨Ù”ÂÇ4ä¸p&¸JJˆxæ¬Eß!Æ½-^@-1¿9 œxÛÀ@ +Ôf™½ÃT²b3ä¤ğ°Y ­÷ƒ}jËù`1}¹¢ÿÑ<ÉsÖB/I¾Dìd0`ÏÊ»o…ÏS	>´4âlP€ºÒG`RÅÁØ{0Ûbh|ôûŸ“—« 2ZiÀÔ €”$ñ=¢àÊ›"YÊyæ=3îg›İ–´íZÇ¤i¹tîÁe/å®]ñ¬AR€¿1;ò©ƒ˜ZsfZšÍéSXcŞ»ñ³OÚòX§S¯äËŠ™”ñ=óòu|’+yüqÈÂ_ÃbĞ›.Ç‚ÛÖÖ]—J^i‘€®'¥\i<µ	ÿyn…!ç®Ìkéî¾ÃdZ@ÃÃ%eİ•Ò[QUÍÊFL¿alÖğ©Àüq±APô³0§­´¹íß
ÿMN2ù¥ÿæ½›0N)Gebw~üVp0@&ªã¿kAUÉ~-4Ì×/"ø„G¨¦ª½[Œ(~>@ú¤¥›û«Ë»FÛ{5¿¥¯>ÉŞ:Ö¦N‘!•É©òŒŸü«)ÿè@ÔãA†¾y¼][®P`ï'äBÑBé›ìÊÙÆ¼šò©ûä;‚dUìåeù,n¥Gt&PàzÂÚÑëÙ‰%ÜUmrïñ &Êq:‡k5&ê„: –Z¹!Š‰GÔsÇº#áßœ×yOn2©øZH‹Úéƒ‰­¡Œ,pf]eíÙ')€ß›,XŸùÓXõ»÷ŒCc82 ”¢3XQcËš\¯ÆâĞ$óäZneN}ªÂ:'‡s®SfŠ$‘Ã™6MZZ†Mš]~ÀÅˆWª3L†íèM´[ñ 9’÷ŠòıÍ8vÒ ì²z
Îäªç©ÒF4áˆáš Ë-±x·sE-˜óÛ¨Ú—„äÓ“ÊªNËğñhL¬CicÒÿ‚™Tc§ÇŞàğ@Cl;’õNûkÏÛ³+{T*Bn÷šxqÄT)íºSô…r·¦œ¶#Dá¯ßk#¼$ìq´§0bŞ«ÏÊÖ¢urr˜Şç°0ºÜ1ƒ‰|l©]B·UR˜/B(Z­ÜsÌÖ>FÃÓ¨ÎYü«ÑjÄŞ¨_Uóïû©ğ¢¢m’7ç	]G[vÚ“jj€£9†ıİşO|ÍÙ]ÒŞÒºCbùÍ
+xş/¨Ú§®îbMQ÷çAñfş²Iwœ³zkŸCxà½¦vv‹x²ÒLâ¥Œ™µ¹c//Q³ıÇ%Z˜~Àƒo^Ö  g¡Ïoy©‚0éccÕh®xœ7î¡ë Ú‹‡û·Vğ³árüH¹îL–¶hŞÀ&¥;yvZÍÌ(ÍÏUÙ"Sšzçü-´Û,ÅåïŒkª6cJ`¨ÌÚøÀ£1åx&Ä©`ÑË/ú"Ò+¿¡S¥aêô©Ø¬6?Ç  “¶”Ÿ»Òf¢x½~õØsƒE.Dv¥œ}  Ã=£ëÛí@|Äœ¼tÀ	f ã2ÛDI'.|¢Øû§:‡>Ş©8Oyy-S‡o01õL×!Ğ–,rw—ĞÊ®c…é¬–ÊD9øÆ¨è&ÙùÆV/'EWÅ&ÂéP«^ØpÄKœUßÕo¥EZ ˜ÙÉúœ¹©M‘¡q|ƒÕec†óÛã›{“–Jİ³–XĞû•a3N[oª+	æ»6Vê„yGDN+M’6öÔ¨²ìÁcï$¦NšÛÌhæfÜúÙX@®b	˜×²pæ•¼5h—ÈPÍòÕ<+XF“$³¾Ie-O–k4”Y¦õ8,xº`]
Ø·§MÕE^Ÿ*vÁ£[‚kKí}ãeT8û¾c0iè.êFd¬~˜¦Ës^nhˆ	„„[5}o&âyûJH¿eO¡İG¨ã‘Í.ŒN	nQXgJˆ¥ˆHPüÜ`Â,/•âm?
vt#Gå#ÊŠyØ€ æ_?ƒ(ÊwA•šÚ¥´1Á÷,ñl8Ü:QØ%’9eF”6ĞÒ'²†>¡¾XÜç-’Y¢~¤(“­%Ğç°"¦¡ø¨u´R÷PÂ¤LŒÑ|{¥ß°ş|ˆbJ <‰šµòöö–WÄˆ{Rñ0’;ÍG§Õ œw0U—|™,QNAPpPÚcŠ	òö~¹Íê¼ÔàÏ1<{ãK‚^H@Kï ‡£eÁá:×¤õê ØpâØ³y…€Ãp]Š¢;Ÿ~w)Œp_w‰j¢ï+ø0JÇÔU«t8Nt|ç|h8DlŒêÁ+EŞAYØ}¿Úö×Î»Gx?¸IWÙ!>Hw.Ø¥À¥^«£}@§Ì\DÌª„?7Ô«¸êKkÊ%î§ñËRvKÆCÈ7=®.Œ«¨İ)’€ô‘o/½|o¯™=ôß·$µµ’ÃÏSÖ”:—PÀIqÙ\ŒYÎ‰%à;ìu÷®,Á€»g|}æKº;zíß Ja²|ï$“ì¦zÍi‘q¦™}@µCG.ÃÚær©w×œa;7"å#wéu`Á-qé^’¡¶y
‡kˆÄ_ÉAœƒa„~Åo’øxo‰üÀ`8½™2çÒö˜Á"‘)øûÏšC÷y&ê„…ª.ÿóšÈ¥Oz¨Rõ‚cbŸöâ	»êÚb½‘ç¬±xÎÛ‚}Ô™xZu…àDÍ6×›×48M[p•gqÆó›txt·"úéİAnáVc.}‹gX†{ yŸKpÒ¬ÏÔ]júÜiÅà Ùˆ¶#ù¤9»‘5 +ÄN.†¿;î¼´¨6ºXƒu’˜â}fnZŞŒ¯Põì£µ?véh¼‘td`K)ür‘÷Ã+ßJ–BN]RµÆ>,maæ*"r¢é²YºÔ:$»&ğè,”D‘ÂµvÊÓĞş¬4V6ø=‡‹1ŠÜDë¶qcØ=éÄ'ûDá›®í¼Ë5¶ç3d>|ˆÏ¬ÈĞô]üÿ‹0qàÜŸwz÷\‹Îc!kNÛ/u4uÃÉZ³»YP¹‡¡Û(ól^B[î”uŞ´fæÙßü’)â¿ê†Ä™ßdv31z`š8S·R4FlşP’Øé-Ïë[êeûùÈ™Ü{ëdÿON“€ºOú\îÍvaôñaHš#T“™zp
¼/¥6»V¬O¨”HI¢yh¾Şâ—Ï[ùÿh4R´Ş°ÏŠà4Ìn„ˆ_ÿ;Äk´r ìBàkˆÓ2Jyxc‹Çí3üï†ó²ïÎq¿Lál±ğ‹8éöÖİ±N»Ù°ÔæĞVs.÷!uÅåÕ3?¸?ß:áy)§Xöè1<„.ßò(£ÒV§pNÿH{9Á²ùÓJŸıZJµÖcéKú‘Q0
†£ÖëaÈA·’Ë÷!º“±©¡¼ZDŒ+IGÌG³Mdjá1qf$›…%l.¥«lø‹¯Då¹fÚäÚÙujiáÆ¶R#÷
Øõ53‰G}m†£¿å§×lfQs>v¹ÔÜÀÔ0ÅDù¬æÊ>ü-÷øk!†<ƒ_ÔhìöÃö_œ
¶5ôextRƒA> o±ÅuêÏ#W–T#‰â Ì‚	86LMSw‹ï÷şš2JÃÍõõ¬ÓJ° øúİí&Şš‹¼qªµqÖ„öa’W(;Æ˜E…\sş†·téÙ$ãğ.äáÛ›§$m2%çKiº)</İ8BªGZ “gÒ4\•=Â
\»óJW¹Ôqá&[i½6¬~ƒÃ*şWZÕĞ§B!$MZv.q%Òµ&ğt6R îûô—.Ö7³gƒq2ÕşGŸñ=%}Ú\^·J ^ÍÙnúâO¼zŸõÍ5~y¶Æu ê)ì!Nw¯™D=ª†¥zÖ¿d¿Më!ıÇgvcœôÄ3ˆœÎ‹9%Í¡€9ĞT™ó%æš)v4
$I—«ÃZtšá¢Æ¯†+ŒÛZÌMwÔ‚[¹pÙÃäÕ+p°
jüæ{Œ4¬SÈ«˜r;İsÓÛÇTÓ·zÅùïNMVÔZD+Œ›åóaúyZGÂ+õÄêN¶ß3õ?æ×P:Bšs_ ïeEÖr‚=ˆGğïi®€‘E°«áˆ‚Â×m:5^q¿W«û€:ÖaÎFÜ­KAHQDkaDÍ££Ãšu[ó ü Ù×2+‹/{^Oq4ÔeR±–\‚§1PUê¼½yv
çãïé"¦¾²ÇÒÉ9)›?¹ô	D¥@~Ë~På"iûú_*[ù€ßWkĞgÙ£î•Sc(ª#¬ÉÓ!ìBqÛ™È(l€ş‚
ëjål…d¦*‘Œkpô/5gº>BçbæÒ¾cèç$Õt ®Í=ÉmÑÈÅ²–Š"„/ğ‘¼\Üq›Å+<İòß#L1te}`J*{¤V7áë‡*³_5Tş«>°‡v?ÀîxVdá^§ŸÂ“üTÖùxÑ˜@=Âñ¯8íW¨:3†W©";ñ‹ª5Å]5ˆ¼´J/12›HÜ‘™§Îÿ'8F ©m¯:oy
Iv‘™%Oô4EÆiª]©/EÇ–áå½'ØOC»Íc²ı#ãÕaA/S,SeƒAç›)w6”K0Ì¹¯ı3”(Gq7…ƒ×İñX½+Ş*¸¥G:'mùÓwòf}>|+¤ñ`õO¨½ãÍp¼ŠŒ›”ê×Oé‚?çu¼İ„ºjUÿ)qî Pe!7°£'ï¡9Cj.ªrVr=³ı³4·¡·e aDÌÅl£Û‹®ˆ¨ÌD«ûïßlúˆšM}µc¢4}YÃyá0¤9i¯M˜õÈL!ô>¾)ÈOy'W <e°/TŸ‘©_ˆåAzø¯}!´ôòÖ[Ë¬¢ì<yMÄ¥|¥f³ßö±\`Oocj/gv_¿Ä,rÆnˆŸäÍêhÇ»´k±*!=$á¹õ-›
*¸¹–ĞEwÆ)É?\C÷DkëLÃ<Ä‘ê¿È/¬”’C«¬ìæ2ò•Q@Æ³êãNÜ}iÜ^1ûĞŒ<oŠ¡åˆWÓ‰«QEé5ÁlÕA¤0ÙÛûúbÛ„¤dco˜I6 ¹­kËÆIüH2€³}L¬c…zE¥Ú2H»z&f~7MF¨zIÃóğè‹«èöo´%±¹÷[9É’­™M¥³ÇàQç$ğRfÑ¢µ8œ>ˆaöĞ6_pÇa±¥æí@{¶ûa€u¥¬Çˆ÷=6ûúìôg“óz	M½¬Õ§WªIí¼L`Ûx×mÂ¼
	ì%ÌÒc×ÏØøı]SŞ²Û
èüÃ\Î¥KÔÆ}yŒÄjŒŒƒØfè²Î^s€.'§Ötıb6WÕ±”#úûÎÏ¹àW=¸qdGÂÚôjƒ:ıçş|z,Æ«Ğ#dqÑvló›E¥.?íIÆ9;QÆÕè'¼®m'‚à,ŒÀxSäE4ÍpÉ²í^¦Dµ’ûå¬ FºÉÈg™½ô¬¤ßmr÷@‡$¿j}ç†ÍÊ	ı`¤>¥Mİz'«~0u;›”öZ}”qF–.fDüJj) €oä.C(MîæšÌŒ:ôï\äAÛ{–æÅ‘Ûƒ8áßwEqfGbs÷‘¯<2 o8“ÆFƒ¸¾B+ßÎ¬ğò)¿Ñü|ô#{¢GÏ„ o*ÎÎ÷ÁĞW¡×åò`æ®dÆ=ÄRäÜ}j1=³’Í…Û@‚¬?sØççB4Ulå‚
4+9>7İÀˆXŸœ¼œâ™Îç•¨-?ğ—ÕÏC/”X°»ÙEZxwöñGaWXWükyÂâëO.‹Kß:B`ç­yƒ¢İäueo‘­#yW»˜ê©i$l0¾û8vŒ 
:¼…š2}WoJ2Ó[`jÚn€J†s`_QĞJ9¿ù–»øzÃ™7MÌ]xeÜu8a$İN5Óâ{8/ÈÚ‰âqíœÉS¹/Ç±Nu€"~QSr\Ñ+É-Ï:W¥ó -â„dˆ ÇˆĞšìb—(lôÈKÓfûËÉEÆV‡Dû”]Ô–co G{åõ§ÎÖşıB3Û>áA—@äÄ—‡s©ö4€gYéüĞ!¤à¸@Ê½i9,eNA¨ãŠ'²RrCPğ0Ö›Tb«eñK	Êïû_Î™ q;ëÄq‰ÒšÃL¨ÕiÙ²2.BJí¸B;_>d`„/j†“şú¨ÿúP(ğóœ.i˜RXzÓ0é)5›W–€a§¢'0ñÁ'×41]ÏµDğA˜1ò0ZJNpq¡Ä!(ƒÚ¹„¤OŸ˜ÿª;ò5zØ—?ÎÖ¥œ‹º‹[‚QT`\º·n~­èßÒ¸pÎ¡¢ ;uÌR~3ò	f½iµL¦œ @tZÂªç ¦Oî#¡Â÷í°ÌÊ@_q¶–Å·IÉ˜ò°¼„•Üd“¿R;€cÂgj§.4ùØy×Ş) ˜\Q›oÏ7èPµ˜toZÚÙõ(—Æ÷x«l†«eX µ\qÒ­~9ëS vÕ÷İéûÛn(³/İi÷hš%ë¨ŒjXåZ°cXüë%şÃ$2¡²”vÏ>3{£±[hÍ¶ixz‡Ó»8eÙ_ˆ|À6Jµ: ÓÒa´¥¤çãqt!šêŸïWÕõ“¢Š:åì
WMa—ÂÕVş{¦"Şv>!$d1¾üDáıƒå…T“rbµÕúÂÉÿàF¾}u†»²§Ã4_¤	ŸP˜¦€°=]ƒ2¤à»;õj=Öı ºÌq-bŞëÎ°L®ßÊ×$&Æ\¢¢‡÷_Z¸+£ÄF{5ÃlšGbÎpJx„…Ùœià^š"ÊØÀ,ÿp5ä{§²Ö@á’tÛ¸
-¶”+\ìÖ$qr‡%:ØòëV³£íSÏØø¦¾4Ê²æ¢{ÊŠâ“³–F}—)p~¦nI÷{ÖSa›±š—Š&I…U5 B©»ó¢&3‰T i®uúØ‹Ï@×ôv…êóÎÉ[âétW
¸­ˆàt&ºñ|GÑ0“¶AKÙÖ÷}U×TnêZO¾	cdı	¸Òì–GÜ“7ˆ!I!Ê*¹<~_…Õ­ŒGıgÊ¦˜ˆíÛi_ĞSEı¢¾ÑËgôŸß7©ÛnJ¤ÜßÌ÷ömiüŒD7i:üÃŞ=´ìf:*wğû¥PS´ßj­ïYŒ# §:üÿ‘<êl‚‹ Ò(;Ø]¬Ó™;gôÏ4úùi]ábw~r—ãÓz$Ì7rÕå¿ÃItbµüŒ69˜òÿNêSÉ=FKµ`mñ`ª
HşÚòack/¹õš ½¦r§6<\¾ó:{;â)TÈåÿ“7ÊúEB£†Ñ>#¢ŠZ eİL)1+;‡ñLH¶2^ÊËu`±ĞcX›únÉ%ÓkÂÊ·ÖhP»MzHÁl6'£46ßDNc>Ÿi¼æUÆzÀµØ¸ı6i	î—åP^£{6´£f¯e2å‡î!tÚ[5Ì´³“ÉÜÏ÷}×§ç2b[7äÄ@Òû|a)¹ºèÍj»y~‰eÍzşÃtj0«†P÷µ(§ôxœÍöè¦BØ¿×†¤)®ØšK—ÿÑ!ƒ^P ÑLÂØóï`&­KE}ßÕt =Zñca|«­Ì¼Z¥FÃ¶IÜóYŸ$Š“›sÀò¦>»‘×i–|+½-^“K<›Í†‹ğ†(‚Äƒc^ìû•¥cÈ~ĞƒÌ”ı‘sò×¶À‘–¤Ë©¥­Ëç Ÿ¨ p£b˜¤¡PpÕ#ì†r·¡_8¨áñ¦^¹éD”Ûpz›1ƒËYŠ`s¸$¢¦iFè’—ËC‹
ˆ‘Kà±XLºL lTÊˆ‡š]#HCuìŸg¨+ÈXtsGüáKfZ¯7\İ0	µ¶ŞÃÆ ³<5q¿$"c¬„–ïèÒ8›f"¯ş5‰ùüútw“;¬tU€Ö„¬'>yÅ”hÇ‚¡LõJ`Å$­ßïX²3¦Hcî®~”íŒä‡^mRyKsŞ4GÖŒÁ Xë›Ç«¬ó?öçÑYØ¸—¸ŠëKõ¯†1vãê$;€ø79]ÀÖàW,§¼0 ‰ŠZ°©Qø‡w›C\ÈG•Ö‡·|UŸélfOHÄñ‘æ%<m)d’ÊŠìÕˆ¡+“·V@¡B=ˆ_#Üír˜Q{×À®µ­æõ<Z‰§a` '0V+'©}˜å{W0é1Ù¤ÕÌ!œ4Â•Ü-»@B…øå;¸N– ëÃsı.®ÀÄ×=·®ª¹§Rë4¶Û9ï?Ğ?‚…ËÆJŞvLÜ“‡«GõÕÍ+Ö@£@ï*—')Vk,%ÔÂ‡¨ *ŸÓ„ú›ßóäË:wº~¾³]`Á”pñ8ª?„3hÁ™0Ç[PÂëî‡s‚ù¡5…:ŸS 5­ÚğBFıjy‡g£jG³x¡3Ğ‘Z\?ùšDùÑ¤ó ª’U¸ƒE×¡'tXÆ£ùÛMå°8ÛÔö)ú^åÄ2ñı[ÁÆKª”j{iü¢MÍæğs{¢/Èêm°/Bæ×‹>,záQ²1x)ò>mIL1e!CÄ[œÓ\®ü‹‚>×Rüæq£	…óc(j˜óª§Gš¥'÷­]Õ\Æz$['Á<åşTS€P¢®ça6]†a’”$!DØ–Ö£ÑÁ4&0ıÒµ»öj@¾u¸GÕ£Îè¿ ES+
í+ã0ìAJo±PC4&íšûî†€o‹_â"y\9â_Ús´‡‰_Ä¡ğ†}¶H ë¹VÏ1Èj¦¸S	S£!K¿Çğ	-jB	/~‚_‹4…¨óòµÏc›q‹BÒŒW]¼â¡|õù+„K{Î*æ#‚
Ş<wsYŸY:a\¹–¯¦‚ØA!¸Ä+Aã§®Í¥€+Ön½e£ÄèáoäXp‘ÍÀQfô*Œç¾C§wZŞ*GlşÉ
ÚƒS°\TÃTÔZ
Ë¸ÔDúA	«.l¬Ó®2@ÙÏŸt©r¶äŒ      Ù£0ê¹ ™Ã€ÀU?[±Ägû    YZ