#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3240029480"
MD5="3dec1bdaf73c96fe4fd5d3363f94df45"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19780"
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
	echo Uncompressed size: 132 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec  3 01:15:26 -03 2019
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
	echo OLDUSIZE=132
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿM] ¼}•ÀJFœÄÿ.»á_jgqÀÏ¥Á-®	­‰İÑÖBü‹Qkí­¥ÿz:ÕğÚ†zTÑøÛHÉÊİT·š-ç¾o˜šİ+à„ih­|ÎDÆ«ùê+÷åØüAbîho äí—I]k¢å“2ÿ¿ÿôšênX#è}‹¹z<#çY×ÒGP58¯4vÛÜF+|Š5°É;u·ĞîÆÒç8Ååá‰mŒ)ñÿ£ÒïZ?êN?i…ÂœÔ–îrô	`°d²c¦ü,û¸´¤E»²Ø®›û1w×VN‚Té>ÒW
z[.å¦jU’æºƒd4*ARcMj©F`Š™¸Š$@w{ô# ËD2÷3ÉŞ6wrÊ‡fu™sì·2»ı+İ(Qæ½Ù…YâÓş'e©!m5f ¢„ü¦ø5HÀÌ…,s;ßünÇ{dÉS.„-fõé™¾f9Z]ùwë3H*î½•Ş·]üÃr*#ÄÕTØ¤IÎ†ÊëXÈ`•æ¹Z* ÀÄ¸¬c²EÛ£|P•bŠ¤AşîrNm%$ÚéA,â0öBÙ“<}»5˜ÿW6â×1“oNÁÏí9ËÊL‡GÍ84‘5-Ï{Ğcï½f8­Tş«‘ ˆ@Äú€bzmoföã^²Œvà÷‹'‘¶4P%c$tBxÑœWˆ5\zâáñr®Ø9«ÌÈoßG´aiØ„5œÙñ|kƒÒS](úˆïQİiğü˜ô%·ZLU06ÀZ=ğöì(®ğ*crŞ)àÊeQ@{F­Ø&ºj›©7ZßGJƒøÊïIß˜ÑcjqV9á+›^n$àmmºÓŠ$>ı`‹$‚cÔµíÄFªÍ’²ç$­™ãÉ\
OG
®`c–ß„³Bìuy’Ù&aİAÎ<÷ÖÊfNŒÓltı‘`®à¦lß›W37$¸ë¿üÈ‘»[+~#ŞPo±p0|uÁnVØ‚Ï&'¡*²ÕÄËˆã	X8# 6‚"³°[ñéGœ)$EÔŞÚ¾†Ç@æÂ}è´±Hòó0ËWNî}€Ğ€IÌ(¶’ß\ÿÜŸÜ	òY$%‰ä€ÅâAèš×së9AªÆ‡¸bê–Ç#+Şl•Á­n¼.&¦¼\K2ÛA\L!ŒÆÔ“\L—†r.ÅÍîû"Eí»'aåòf6Ë;	k HN’˜{İOçç<¼Â¢ofØİÕ]V™×É¾ ï_ÅŒÎ;G«–ÆIõ.òŒÃø`Ï}<$L]â8M“aPáù$†‰;óÃ,V§.?bM+ı½0×î¶ÙôW„QÀÆg{ÎDhò§©fí<œúb¬ÂÁ«—ê4›,û–ß–eB'ƒ Â3è¾[Ñ€ËÒeæ~m*oôØÂiaÿJ¸:§ŠD’œÚÔÌN´Jx&ÿ±«¶Â!ñN•+•,–d²)gÅ+8÷¦…ğá1	*óÂ™ˆêÅ·v	uüy–¥]í‡­yÉ­k:Èï¾}Hség;®$Ñ»Ï²[v®Yé½!â!Ø½-”#§Wàı ‹ãìÚµÑz+ä?	r»ŞÙ{‰ó|gï|"éÊÃ-Ï¿…ö"`d kÓ¼ı,«°_Û`+K5u(™‚µ-#îÍÎr2 O(b>éÍà]~Z\gVJMâŸÏtÛìñ-]ü¦œD±q®L»7×U›ˆ*ø
µÂ½ƒµç²îR¾uï2FµY¦¯­p-ó…ĞÒÒœş1¯À‹kÈòI×9KhÌ<ıŒˆŸC^­ÒB–’™»¦]4ñéäí¬/Mjqƒf—u¥’ŒÙÁ#é^Õÿ€]èÈó•Sñ÷£È–y4µ?F‹6 êªJ'Ã¥ÔÅhAr±\ã„²†§´õÅ{éøWÁêkúó>…	lW»‹¡¸H‹J)H/ªšKJsZæ´à9ú%‡’ ãKOúxsg‹
&ñ 5›Ô•‰°DP&:²yn]÷şıè9tËFÅ‰@o\£šÌêÇ:›ØEº!Y5B[7OûóW/ß:ùû¼!ˆ%úwÚ˜ƒ¢óºä8ú×‚sÜoÑÃºŠSãäyt’¶<_eGTğ§úNd¸b–½ùEW´Y²Šq”¯¹ac·Ú÷½&+*‰&İj¸Új&Ä¸	òÅ
²h½-sh€ì Ú-İ¨ÙpwëşÚ<x’·© <vñ<ÎuıuĞx+]Ú}×³{_Ëvêó#ÇÄŞŸÍ·’JÆÈ!øCÎÕÄ‹/õ\6F\^)š~:ºÚ*Ã )'6IÁô>ò:Ö»b•}Ä^şñİ-Dsù•d?â? „†-EË³R‡®œL=›å'øJ­ûsUĞé$õuXö¸z1a«nQM¯É™Õ2†¥Òàş¦ËìÌIˆ_{^é¶;R–c†çiøßQñ²`¬›C·^\"f cDºâİ052Xgö…æ®äÈˆÚW/n¡ÊÉ6N¬@f¥Uj“!£‚2ŠY‹VCÍp%PÖ
ybé®Lg”º«©Ô‡í7øM,7£#¾¡'WıÏãâŸ]òtÒ;{ÑÉg‚wÕfÍÓ3|ñş»RÔ˜5İr\ZhA=ÂmÏßL˜fUßC7éñR¼ÿÚhZÜ¢[ıZÒ*Ówı"W³C°; ÂË"n†zçØtW¼³lCjÁãwûË>@]÷Îà†º<ë×éï¼‘Bxù3YxÉg
;ôÓüÈ^¼Ğûº‡ï4£’Y‡X[o õ…îmxÍÔÏñ•Z;1˜×Ù~§4œô$E¯8‰$˜=§>zğãT{”BoŞIBíY©.9ÏÎc…Š:›²ô®O;÷L×ĞjÆ½)Âû«~§‹êw
#PTWÊGøBqÛùŒ®ü¯/s†|‹–ò8Éqº.šèğöŞÕ*µËU‡š[s2Ë •|£y™óGkäu‚<ƒpûÿA.Wï´ùªûy*‹*ş’ÓÈ
-Âµô~MI²>ÀÛe[1›P¿F¡dNî]É¦0Cèîéî¿¦Q¬jüàÂM Ó÷‰º#.ËE‘ÌE:ÈâmäûËZ¼‘´²!˜úÛ;İƒzGYáADêŠ#ªßô%Öùaz‹¸î‚öq‰³§y¯¸&IVüæx]8×äE¯¿õWÈIÏ>Ÿñ1PåêOSÊx—ØEt²Òû¯»6Nù¯Î¸+á#äC	šÊ˜}èM¡-İ³¨Ò’Ãû«}Áø›á:nõ™€-Ñ]ú÷È4<³¨ßÑ‡ëD¶$;2œÙ! ‹¿v=±,%tì éZb’Ö¬µÛìÑÑ²8ÜPJH@NÔş®Ü,iÈr9•
ÅuÀ>·õòÓuµ[İJ™|¸]²Ï­f™®åˆ.ã ·¨ô…ºî/ænh]î–/ mÕ­ğìğgşÀáŞ‚ÙïRæœ¨Â6).M2ºüÉ_QîlC<Úh6ÖVÄêÜ†+*Ê†ôñÖ·`BÄod6”§RµÂcæòRy#Ë¿§Õ·Ã–¨µÁÿf¾0[ §v¸|/E)Wpå!’†bµ˜wK¾ÕÙ_‚ÊšE¥İH«£Jç7g’I4çQèmÇÑ¶	tqirXZÕâYÁ®ùPdË>ÈŒ!ÕTŸ²¬~ŸC$ô‡£Fi7¬»Ö¥x´*Ïî”8oP†œ£"¥p3)QŒ#t÷²?ú¡2ü£Ös–1ÇAŞ,:Ç#åƒ®Cæ:¯cR¬»šòù˜fö™–RDMQK`—$„&v/ÀÉ‰$;Åˆõ›á9qäyşëCÉŞ²f›É,Ğ­ßkkà?]v#¼ı}—!×°Ó>ò{ËhBûä¹}pª×â/„YºÉ~Tƒ^&™öùÒÍ‰­İ‰Ë-6:Søµ ş«kVÎQÎ˜ÒÏxw8N(¤JÆ»öÍö^U¦íZ@Ù¦iŠ6¤Zà™ìK­\Ô:`D0±ó ˆaÑzb´öÂêï‰»O‰yRú=¬&»-¦ì£›œF­;Pıa•[ïVÅş-+ß’:¾oôŒÌ•ì&Ìˆ~¨ƒbÜóæÆŠxwäña¬øRooy-gË^H=GÂ.ç°lúœ-ºÆ[l´?•¼.8ˆ¶*ŠµñnKÈçûfeF"ñè\¨®8õ{>—ŒfwÊ #k$3åÏøÀ‰Ch}v`®€0†š]††&=JÖ@QÒÀŒè„Ûî‚ÑÇøluÛ¬½<¡õ&¨Ä
ToAkëÜFe˜M%h}™P†>³RíË^³.±ZAà,¯³Ö“(\ÔÏ"kp7[YëYÅk°ŠşŒ!Ä½<‡·©0Ò'€XŒå?ñy]"”f¡zóºş†õk­±zå‡q50)Ä>ÊV”)*.mv,Uë1ö8I&b¨åˆúåÚM}|!+d#‚z¡!»å¥¯s¿Õô£ÊXgªád™3õßµÓâæ´(>`íT)o,=éğ¢aü3p£l÷¬o¹3\Ó°y©ôÜiğÈùÖ®`ç«eZ‰cŞQ(ÅGÌø¢7vé{KŠcS…%‡·àŞÓ‘<|ÑLã‹¹Á¹=éÃXÏÍ‘Eê<‘˜×E©Œ/}å`•ğµ’¶Ÿ0™]'³iqÚ”Ü¤Ò× $‚ìëO&Ñ·ˆ­;ÀÕØìÀ9º7•‚ÓïÉ:Ÿ=¡á¤KN¥Óš¦KhåkJWy	k;7"Ëçä{@}fåLúp¢]‹PAàÖ½õk=à3«©ùm™*^@pY™,ì†W!ØLŸ5Vr´+à\fWµ³£Š[¾¦Â±üØ˜&)ÔwCJƒp€M 8—AºA#SkÕÿ€¿¸VŸ[°/å‹Ô¯È°M.DäëâÄ»‡ú`6Iöap8	íäC	l‰IÂr?ë0g…ôR?/h¨/èyıŠœ›‹y‚W[~Ò£ASâ¥
aP[´8nšI·‚+àLzì.Ğ¨,SöÆ^Ë…49Kr3¶9•º~¶ßÌ-‰!!„¾‚¬(Ğ‡ÜÓ^¼ƒ{´T[-Şpa(iYÍ<ñæª?©Ïg%lŸm0ób	¾+?;¡	xT3cTí6†g
ÜàÎ{5Ï‘‡ÌªŠîX+(¢Ïmú<`%×0TÆòákUJjäù²€G~½)±ƒÈ·ÄÚÃÕ'Œ0¨=”j®˜LğY:<¤üĞeÜÍî
:Ã
;ùÌëUÀ(™[N[LL?üñYñ»aÖó¨£z¾HIçv ~òVáú0|ˆ÷ıİùÚX`òÑÒÛÁTôê¿jMh×û'=r”öÚ
EGgh»ë–k..í½YE[rzƒì1¤òÔ¤¸¬^¬B-À,×kM‹TdwÛ¥2L]^Kæ-Fw±ê¯gN¥Ç„û?õSÜ¤ a¤‰û²÷jŠêî.öÓ˜I4üfL¹¸—\&:”b;ŞS'µq£² µåz‘…-Fd(_¯€Fò¨ıÎrx™Tác˜·nŠ~ä¶€fÌïÂ)5 26«K«}ÏáÈé(~F³–åR[4“aÌŞù)A”·4#+GDÜkmlT«®A7ş]bË«ìzv‹ªDE†à´ÃÃš“Y—/QÖ¨úQx5ÀÙ?ì«À¥Kè¡vOÇ|–Õè\€ñ`ÊrRğ7­~Ó†È‰o¶¯Ã1Jî8öe…Û5+{û2œË¿ıÍbdüÔ®rEŒ#[~¨œU˜ÏƒT+6“ãU_…Ï!p/¢¤'Ü.DRiş7¦%ç%­ß Îæ*—şù™tŞÜr‚ÓFq5‰$N1$§›¾#(şÛõt¼sp?ãaB@™lÀl€_)	Äö·åºÉrƒ!¬ÉÆÆ\‰TúFZ/kÚƒ[17–:m[–ò²Ñsë´”mo]VòÄhÕe¾o‘'³è±0%œÌ6æY”\/!Ù»ŸlƒWŒ¾\Û_<ú_sàz|lùn -Ù“£OExgÄ†a§fW—hk'„
îE‡"†p¶ŞAÃ¶U6ƒk¹",No„í™SvğC²
ãï¡ÜdÅù_î¢T `šƒ]ÆEPF*nÓâ¸©}l¼¼Êÿ²—ó×äæTF¤cÉw×6·E´~&½íÙº2d¥¼/¿½¯:2²s¿nêÂúøP 	÷£ÈÈš×ĞHç{!áÙº?	®1`ì¢áeòMÓ¤øØE-“¹–£91
á¥iy¹„>!±?ÀoN¢ tECY/ SæN8”Êä:ñ–²7²˜~»³Ùb?ğWâiêV¤@ÇõƒõGıR‡ER5J)eÖ{ŒÍDzI*Ë„ìM¼ÕËmÖ2\>#½å;´§"¼…ÍTSnÚH·õ±Ä^‹¦=\‡ú˜[¬ˆw¹ÂÁöwB"#ÚĞÁ&Xğ>ø&BÃ3:Ú§óêtõ˜æ¢`M¥ª\†q±Î¯"CŠRACÛ`şÛ¼:>xjåæ6Í¶Õ:Ô-7w.ú…Óş®±lÊzÈbx§Üù{.ÛOFù¦Ö½H™jç[¤ì®ñ–Ú±ÅYd¼l_’(ÍÆU='ÊÌ$Ôk8|oë¨v×ï:Ù>Wá±gˆÈùF}aßş“]JsùlÓ_äÌƒU4’âË_+ĞXtÆ¥ \û»,LRä°4áêØ Bl·şjñ¡ÀRyDÃnV…øşü[ådü#È)ˆñŞƒÙ³éˆe˜ZTk ‰&åL”âjV¶¡µĞy}$ãL[;(±i°¦€µ`	*PpuÚöƒw=zÕ¡^}%GÊÁ°˜x© $Z]ú¬ÅĞôúRhI ®Ã¨ñ…ÿÇ–Tõ5Tà)ÖüùÖËiÄIMXb$ L4ä^G»‰ô¨)ÕşPØ¿¡†¯²Ù.TèHŞgp.§ÂK÷z¿8íb½è	üpµ1L.æÀ6K…78#„%­"fZl;¿½¶g¸ó3Y&ˆk'æçkÊ†õ@•$ëÑ\[*x9Ô`K&_»üma:âRŠ¼e £[üŒUPœês†9§g2Ï@ú¿µc¼ÂßcWÁ”ùwP4nü¶£¦ŠÙ.İÊ`ëz::zæë@`'Ä?ˆÒ |ƒÁ)r¬I	%õ²$Ôcµ—ã?vg¦kıNGjd%¡–3G½}^¥%i‡\ûB]ÄûöI9Ø_g×)†4›¸98A>8a6è‹¼b¢Ü1®ı7†Ut*·RğP¥$I^B5×[;³-‘ GÒ¬/j‡2¤ÀD%¸šGˆyT5ŠÄÈx;”gdĞwÈªI'í»ÂÈ¶NX®¨(¸›!lGÄ“I+íoYP9b³¶¬éÕ…}G¨½ÿw«jçíÕ†ıdÖ½ÉU›hdZÂ|‹)İf¶å<¡,Â‹˜yŸ*ú
ş•%R]6«sùˆ6_“ÿ­»Ü.pn"Q<öPšQ<F<o|‘cÿ§Ãcù»¡Äìlû2©PpVtjÊñ#4Oµ7ìGÑqøis-[ë
öc»Î«›½ni’ÇáÑa^‘¶\`#Ğ}»jY}H”—o{·Ñ:ù±Ú#õD|„ûög—ïÊ[]ë™8^wA©db«Ğ)ÑUb¹;©“ Õò8§â´…~y:š6ûJ£¢G%Ñ°»Q³¯øåLñ˜ŞæGú¸W¯‘{vlqDRôåÕˆkÒ$Ù£Öfã¦Çj%ı“.ô¦Ê‹’ÙTŠ¢îŒáEÉ†\dØŸ»1iÔzBÊ^¾#§B6ˆMíÈ„rÅY7rÅ+Ÿ¶ma;²X9Árk¶šw¬óŠ‘õº´5O„Ïé
”N|%'ìÓºŸ¶ô‡¥#»
Cğ>€‹–òÚŸšŸ×”s¾Ç°˜5N°N‰õJ0ì?bŸ^oª/¡ßZ†“ææàÊQ?9n
yKÙ^¿ZW}ƒ"KªËsÛ+RæwŠK–Š²ÖÍ4²÷_Lğ—|3Â—ŸŠµ†H8ïµşeÁ
¡wT&'+{ê¨"]qVZÜåú¯æ&6ÕÏÆ+µµg8
½X§uØ§üæéZfiUP‹‡2önèÜ)Yv*¼ ƒ${dİ†a·8õşöÃÈ»	‰•a¬ˆmœ®k¼Ôa|ñZ-ï‘,u÷ùW„`q·9ƒíÃÀÂÃ4eêÁ71©Ş.Ë‰ÆÙ‹ ğúèö`Ù!À]%¼ğWÑab±ğwÜ(b( ã /}òÕš˜§4|xêhó¡OiÃ1Ô×¢Šm?$¦lù•(5™uÃëXş]ÏâãêøÌêx‰–a›u‚§5ÙFbA0ˆ‘=wñ®„Š­ÒÒ…òz»ª~ù	ÒÈà¢¨á½œuc¾ÚÙ`ŞisÇšGgÔï qÆ» Èv¶5¿âˆbœIGcXíy3®¸°ç–è2d'#¸îÀõÇ»NyI>z"ÅÏÆOÖ>]p êH„µLQL+š¥¸‚W ]‹ÅÉáCĞ1ÃúÁÖÊØÂ.I¬ÈĞ>£ÍÈğŞãÚIbzšÛqIı,ü‡B'³ßAr‚8öÓÉµ¨†,ŠPf¨~‘
•’@ÏeqW³vŸ8KÄq¿»²fbâV6f/KªÈáä|r×Ù‡Ëå´, ŸI(Fs=wFšq²q“–ÎR£«_mŠ›¡¾§d²ŸBE÷Ø¶çYèŒGÆ‚†m¤-üz…•8†pjº4Ëoªa¢ ™[…ó›…“•#Yğ0fj9ìaWJ—éş—âZÎC9¨ÛERˆşå&¶sc·j[’PÂUËx¯øŠkˆ‰J HARÏœ°'0-ôãñ1˜¦®“’Şîº‹ôX£ˆqÿšáâ4ä5€¼è°AhÛêÖÊâ–Ömmè‰Rb@VÇ80—ßñ†x¹#ZC¤EQ¢ääGá÷,Ÿˆ’E,×3W–sç¸\Ú\&¬tÕÉq‹ğ¬%`gbLâóÛ*ãÌ|µºK<·ß±ó§õ=—óóéÛú’’«§f}@¯4HuÖCE}3¡%:cEº¸ğsZØ×öeÊj>½¶Ği™Œ½"d•Ìî?!vëÈÑÎç@:Ÿq.İ/ÅæÀLy&É®Ôµ€b:ü8ˆ9ö%ù…µO~?‘‘îÛå³\'Ûpè6b7æÚ{0_9›c,ÏOOu@Ï§·¨ïÕ‹wŞÎšq¬mwšR‰Œâ“:"£ø±àš€<<¤p’¢#hıLRóTÁtT}à§lïx-JpN/¼Zî7ğöîé>ÜşÑ¸!c¹çg­ğùÙ¥àg’.â³»¢…€ÿÅ¾ÃèÎ%”¡x{Š¥]Îíè"8@ı6Ğ5D0s¶İ~ß”P{_Ø½¹5!I¹ÊôüN$b÷ª³ŠÜß/Óœm……•üö™§ác®ŞØ™1Bu#ÍÖøF‡½tzğ\mætnØÑ™xÌâÂØo‹^æ­+ÏÓÛò[T-L³Øàf$Á×Ù˜ï‘Ó’“ôxñsœÓâ¦¯Ø2á\»øïş!)¯ê£ã…¨FeààáÑQÂY‘íX[Öli\#— 4mŸÍ«?ËÌÊG*¡ÅÖ{MyyÓ¯›Û}jµÏ×pU´­¿Ùê„çqSS¿Uo6GAÔ<†+rX¶çå£ùhM÷3*˜qQwÌÕ­¿Ø±ÍL[.CV3ïÀÂêĞ1®U¹y¬µı›cùgEç¯¼Ÿ3gÇÀÄ­qåée£kÅŸíğ±¶í)ìÒ‰®ú}|æp‡¶vP§Üƒ‘2†­”Â=¢Í*Ş‰*3·pó­ï¦2T³|q…ótÖU¬Ş½9û1 Aû\®Ÿ\ÒP“Õ‚ó·)ÇA‘k7C÷åÆ“øbÍÔeÍü+óíK—j0TİËİcW:+AQAá
Lû¬Oè¶ZßE[´7ÄVÈÖŠ_EÊ‚pU+üŸª…w‘¶ÈuÄµ3YP¾ˆGYÎ0Ë8A—ŞqXø†3à¡At.¨.I•<³º ={>Ş6+ş+÷x¯,öÜßğe[üä¦Í¶ø`3®ã4ªC¾…OáKƒZö+ÉázUûŒ1’yP“>‹†ƒµz‚Eàr¢ƒ¨©O¿ÿuHA”ú'4’¾¸68B¸	U½²Sx´7‚Ew’Ä[D0/aÖ2ŠİgT0r±
P”î××ªivcôFì|vëŠèø¾NAåˆ‡«sd-ƒ’0'•·˜J±×BÜ´øí†ÖÍWiÈ>¸káÕæ¿&}+á5Éê±¡²Ø™F‰³lºI ³ØÏ™±²§KßPÖ¤óA}¿‘,á¼R–êé€@
Ò#l{€–Ob‡®¼“‰ßäzv`G<é ìæ,ğŞ_>0E®ÈŞ‹Îä[]*íâ¶”%1FvKxæ¥z#oG™4¿íkè_£Vc2»âÖÙºAˆ²¨§¡*>.²*‹ôç4&“tUöıO’€G.å­³vƒ²®çóò7U"Š¡ªœØThWy¸¿¯ş§Z	Ø1Q+5W2AéO–gÍòÄAnŠ>+Ow¡A³è«™­¾ı².œj ‚æÊhOÚäæ[‚ÚŸS¦ÄÙÈ0 îò Œ¢R¸/ÈFC˜İè°ÅÕ¹+ôÈ7£4iëîB¸p¯»»ŸÉàFs²¥ÚI¦»›…id(ÛC/–Ú~ÉìRåe%aÈz
ß÷t›áèÙFÃ>Fã^z“õ¸K¶İ*×‡Í3üMğ²ã÷«°e¿AĞÓKC´Şµ.Ü·“LBÖŒ×TDpx°‹¯Ş[ÈO··~zpìDÁlJ¢:'ëíKmg8T+¹?Xûñ–vî mœó&S‘È¢ ”¦õÚCä§ôæÍZÕÄqñw‘µ½å4×°Ÿ((ÚHnWƒåy6ªLÙ“ì¨šD|Ût$Â1+e;™ÁFî7"~ÎQ^®ñÉ~î&­Keÿù‘Ô[Ñp@¬HL‰ÀO–LÎ™t²(;ï ¥-ØÊ¬*âµfTÙMèÌà¿0æÂš&œ:H6p@ KÒ{¥Ëòº|j‘[;ˆK¥s©†ÛC¿˜éu’‰êî®>öe\²É™‡†â	ÿ—xym‘Nè‰Ëpı–sÛN´üÅk{y•jhÙÏÚ|pµL2!ºì0êü÷Zz¸ŸêÌğd0Um)•ÂL[Dnh™Ó€1ÃZ}¥^gxş“§Óš¾'ñ4²Z@§¶Ô+ë—”z€À-û4ö>ÕêjzüDqK»€ ’XNB4Ê{.¼ô0÷¥…#ö@ UÚŠişC×ïAJ(¨ÑËá[/Á_LË;_°@ä4í}wÓší,Â…yî:|°H(6eŞ»8ÃÁÜ¸Ã¹‰àş³şÕN[‡^oÅ¯Yoä%F¼ëYı¸‹«A^q¬İálÒ‘B»É·3–x•àŞ´ÑÒóÀG:n 6Î²"ú5ùauát¬Ì*ƒš¥ÅÈ%şïO““"¢p–„gœXÄX?[h×’ÿ‰‡ƒ‹?2~ 8d.áæ×“d)ÅqVoóX|¾µH¤a‡kgrÒØËıHD
4v‹u"”ÇRmœübËÔ¥öÀ#ıS†Ã¯ş<>
¦QœnÍİû£
Ÿ'ˆÊ×œúw¹éØ1Òâ«—º†t<Î}<Ú_Ò!ÒbLğƒ)Á9>”À>b¹
D„£Å‹sdÒ’`Q/!ûiİ÷şR£œ1;Â³¿“ìrìíÊ„äÿU0!À	#5;\†^óäaøqs›a¤8[ˆÙUú÷êİ,îµz\8ûr¥KÆk¤TKGcV=<í•ìşâ^ôÚ(/ÚàóÑOÂèÜ2Ûˆ)nús;ân¢’-vî¾"ô8ğÌv¤ÃøK’~•¦¨‘ÅÃnaN&Ë·ŒáÜVöÑ‰5•5¶
‹)ül‰
,²çzê„ÂWE¡†cÈ8²Îé†°R¤6–DòSOşÒ¸–6¹J]G4u^VrNwÈ,/«!¦sQ‘Ğ–¿úvçîõ° ”ˆ×şyXã©«Wƒ»¥AQÿO]ß9¸õ~ï„Ö^>şÅñ¤9Vïó¦ªË¦ğşÈÏXÎ"â’+‰è&+ßN/Èƒø¬Øfbx›.ã-Íı–GºP‹Õ+X¸oÑ¼fìıY\x#ÎÂÿR•=h¸î›R/©1[‹5ÏëÂ£ÇÛD!‡"l&İ\ÒC¸'¡™XKÚÍË†:ù.«dû’2f^v×w´†
©¹Á@ãXã¦¸‘¯íÇ(b±ã¢UpM«›ÛG¼c3>{eo£´¹î¯ı;º/#Iyil”¬q»xÎÑsg£S’«n˜yÔë|5¢Î´·%L|<‹D<Ë‹å»IGÂW,Œà7ZëH¿“ú},fIc@l~ÄhyŠ–Àû§ÉÚ×
.é“=:w™¬¶D-êÅÇM#yİ5SÏ“H°\¼ú­.‚ØE”ß½’ÑU„¾ëv(œç"¯äS’ŞéÑÌx
7§Åâ=–ª€ËÏé•šzzAĞ£ŞPNşzI…µ4«¬^”2§µû@£§¤€¬‹k]¬0<jµ¢ˆ#ñ(…•4EÆ¡ Ò2D®E[ˆà‰èZ\ŠEŒØÑh€ß`ÇRÑ/9‚‚ÜŸg}7ğ&ğ?|`é/ŸÑŸÛy½ïÒKTN¦ºËHr@/@MÉ.À­”û;Åî¾dë¯6ßVdµóé¨IßZHú²Qa)Á5¡^C5øİTúÎ‰7©zàşßLúÁãY
Ï>bx¹‡ÛT­»¢"»_IC†#Nú¸ˆä4•¼RX«V)9"‰Ñ#öF1ĞqğpOÕ;)"P…‘|á"ßˆ0®œämÚ@ó<‰	âgd…¨³ÌXç°Û‘0ÕÀ­y% ı¿ÚÇIøË[Ãşæmˆ×¼UÕËÙíß`HÛİ6°¾[hïOÍ½Ò Ö¢¹½5fUÒæ"æè`E}ğİ™ÂÁØGOrƒÒ|Ã|Röª”8ˆq´ÔòW„—4²h7œ²Ûk‡Àà²ÿàøò§REhÙgUÚ_–w¥{Àïx×N×€ÿ¾¬`š‘tlúZ9âÏD8ÕÍ°¼‡xtNa9ÜÒØZI'¥ÉÂŸ¬Eì$~jSån ù: qd2ó`ÔKdQ-q2§n­$µıóZ?†\ng±1à<.û^Ø²1öDç0ùŠr¯DE&]^Õa—§µÆ}Omk9_²X­K£Œh
¿)5ÑƒÖİ-|ÒJutuXŸÅj<èÿh¾™¼ÿ–•ô0¸…Æ-1TşR–mÎ@:ÓaS!Î¹ÈÍ‰iûŞ¤Aà»vf±õJ;şäƒÕÀr!f©t”™QTLZ_Q»©í\e²~rÔÈßó·ÿ^³tÎ[î‡
ÜüÙNáëè¬Á€ò¤(×k–P±©‡ıy˜­æ‚vEsñ¡ë€×³˜Õc,ùÀü/Z~o±›_‘<ûìuò
¡ÉñWšïîs$ åÀ ¸s„yKÙ1¤U5 â=²“dùµ‹Föú¸¬°»L7æÄò›¼f{œºªšÆu£UY–ÉÊ+í¹(§3°[2‚ï!XU‚VÜLƒ…rÁ}ıãÌ°Ñù;:‹¼–6/j¢Ø~ó0š.èGÊ	>x+æóR°üZOl	õ¾böueEOˆ[Ş\P
‡ÿuÍ=MÍ'QgjpfŒ|ôã0\–S—EU—^sRùPšG‹¹ğ
Öâ%#]åŠêæ’«Ôï$“FŞ<Ã¼ùŠ	Õ Fppˆ¦›M{½pCà"h·FÂY ¸¦ZæPy ¿ÛÃ	ñÇa¦¡á89¼&§ƒÅV1Ø2xãàMÜ\â•>ö!«ªBA ÷¬É8"<ó­Ğû¯¼_A‚4Añ¿†ÊQØ~r ô{øGòĞg””Ój1¿|¼ægÈ3[oq2œv´X¨^´ãŸNŒ'ÊoPÖ¬q„8ÑŠOºÍK«-2›>µ\ÕSD„$sCwÅ|JQ—3é˜-tê@½:¯µM3òğx]•ò€÷ À$(Z¨PŞ›áÅLODïli“(÷QxåÔŞYµ€%;ói?ß2aÀ’†0ş³@pã\ÜT’ÔÌ™ıœ.T!?–#|ÉÑ½z:2ßlpéÓ3®ıÍZ¼(öóÔ§Rø
l?”Æ”fÀ¡úŸÆ½\ŸTL®VşuİÄVÂÑı”°`–Ó.é½¶˜m0´VŒ…iÇ½›Í$Ğ|%©ÙíQ+Øk‰º–G*Ö¨EO uğ&Àc\\àÓßè¹õf%w¦«7ì
#W_ùI—Ì]B ÈJYÅšFæ7ã’Y´L](ó'ÓÎKN5Î`ÓıP<CV¡’U„a›:²—¡*]¨`»¹è&›Ó1”}•\~F3©²DæÜkl6T¥Ízt8ïãI¤=*,Iqï<H<ğâê€]‹€‹T£«œˆÈ ÔŸ^¹t RlÁÕˆµâUgr¯ùîÕòX³¸9!Oy€ŠAµıÂTˆÏ>ù·æ.mD?ÛÅŒƒce¯G'{@“ğmõYóÌ ³!g³b€†“šç(ls“oßí
#£Ì1ğ;ãñ½Ú¢A÷™ß#b>25ÕŞéiô„Q]š ÷äÒ~q N}¿$TõÃMœø¡¶§ùÈ^ùBK\Æ.ã*Ó3V†‚`ô7Tùº‹i—l‘Š˜¼…%mûÏå4êm6>Äß4qse[åB9
"»O£m¬PÎX)¾Å¬Ğ©Ü”,×¨@ªÁWËA)ßŞòp;«árm/²0nŸ¬?:ú$ Ì¦÷€ˆA­Ğµ£œíŸ¦*® çdsì€ÙYuZĞÀ+_04Xtûù[âºÎ\ÕÆÛ$ªä…~¨—ıñ”0wy€jˆT,”=4!¢¢³é[½nµ(wl%î6®ö3ƒk~vM+Èã0Æå£n]Èá,Õ«°ÆëqLê~'Tqa”;D¿E
HV+¡Mh›r¹[¹@ô¥7»«%§K¾BR0NÂÙëzè˜JÛÑé¤[†ªÊ‰"r×vX~»Á¢üÍ97‚Î%çİ1OşÍWm ±nSt`Za3.j+”"ú÷ëÀŠ·”Eî­ûn’ÑÆÿZ bíÌu÷‡¢äµü©W#1:Ÿ;S;Üc­—Z|ô\‰õ_İ•×ÒOV-KxÆ¹>f§Q»FÅü5ég”~VªÄ,}ıFg³:gÁ¿gX4ƒ|ü½y0KmR#–iyWğfº)y&9X"ëò-7¶ Fö[)ë1Ãºj=KÌèxpo»b5´á[™uˆ½\ğ’QÈ»©ùì^$NîÑIivªŒJÏÓE( »ÂÑ·#3Mr›ßy::©F}¹û®ÉrWÌş†_Ã"ŒjŸi|Ø1Øly4	Î¶¾€=‘Ş‘'açRîâŞÛõo/äT’=EòÅ©Ø"ö|Í™(£¤zî<U†Uë·Ø­H^i j~D¶É‚L:4:k¡ÈL õañíˆ6üª,fL£
ORÖ¤z=/ÿê:áÈå÷8Dn‚šÁhfWö-¸ìõ{/÷é¿‹ÁĞ
rÂ›,ãÔq:éÅçbÎAäD&‹õˆ=ô³W!SpHOO´ö¶ªeÉ²²X±åvëûˆ£^©â}ñİ#*w†eÓMt–ø`†¥¹¹G’Ï
?Iâ–°CóşÖí9S¾÷njİÅË‚3ù´îACÒÿµ±®:µ [s‹–ìşÆÕëD¨æÛˆS˜$øn[ô±O™¹”»Í™~ê¦}{QÆ´<M"f¤›MõxŠ©»G)¦9şÅãğ”Ü=­K^n>†¯ò„.À^¸¾\Ş‡mp:AFq,ºm[S*=Ã3ï54Ål±õE¦Ì…EjçKEúe˜¢\ĞèãTšç'#D9®`á ŞŒ²1E];8n	Êäóµ…¸ˆé‚T¨´Â9ÿHí/e¸ø€KÛ’‘»Poü
®ÖÚ«§Yİñ)8-9ôÃ€öøzóOq,?*>
AFÙ[ÍõA(»Ğæ®·×Æi*"Àá¸¦Ø ’c¶Èï¦&šé¼Ş&L£Ó}DÃ…ÀÖÇåÏÖŒ‡Û‚ú»FsÕïÄÈÂñ98ÆiX#YH–{è÷M]#G€\8%ÓÏÉ_·¼ßü»¯·QÍcfhÅùO‡“ÑÈ
îS˜±Ò=48QUÃmGb—î|Iı± ÕÔ§>‚©>Pöª&‹DO¿P¥²»U€|€ü˜lúê¸:$‹xLov[ b{´úJÖhï3KÄ‰B;‚ØØ¨Şdä	&Ñ63„‰ `ü¯`?=™Ay'KFè
12–|nÑ¿Ã:6ÔŒÓ¥GÛøèÕmN&AÕP*¥¦|›ÒIÖ@? *·[öâˆtbD	ÈaŞq:UkpV…¡J ªœé¬i`¾ÕoyğR¾üë¨M6RX)¼Mï› ä¥/Ó¿©x×“şãbcˆÁ»Š^Oˆ{²dàù=ÆÍLhâµS[à®ª2İ¸˜æñÜ:Yş[TÄAb$#E¢µ%™Á· Ÿ‹5|%æp!9ÑY7Ø1ŠâÀIU¿4LúäÃ¨=1;{6“¿$Ræë®ğ ŒñÀƒes¼GL&Q®Ì×ÛÛ«İíFŠÒ–9¶÷,š	ÿY€íÊU#3îg§$¯;Je¬ôïe©[´4Š"²È€a8´Ûr*ÂA*pššÃ”@M#C.ˆ]†DØï¾]á$:?b8½zeÓXê^šó2‚;¨¥¼aˆ*¾èCnÍeîï(	ç’Zƒ•?:z*ÊÈãgíôùtO-Îb†Õ–’x—ÚƒXší¹©ç§Œ8µƒ—¼¸/À–£ÚIR‚L3à¸°:„%'«¤È%~1ÂoÎÏæÚ9^‡7|]G@!F_ŸCkÙ(Jb·‹ÃBÍÑ=çfµp„+K¯X°UKØXŒÀ¼s‡äE³;s]ÀXŠU›(g]_¢¡®µöâf¡!™áÈ©èF¬ú°—'Ì.Â½¶§ƒõÕË‡ÿLÌÃ[¬5_,ìœCU}]÷2â@ª¸ÒCËbÑ»Å´‘ˆïj›M^G.øxG{ÕşºkÜôÍ
yQİ$óX×g–KÅA¦A–cãxñrÚ H‘lvŸSÜ±…Ÿø¨iåä'å#äé¬·*‚‡9®{ °bÜ•1´³×3ÑR„bĞ IÆ§ĞÒ=d œÑ¸ø¡MâûZ&ëw¿´ö¢¡TØá&{f¯<Ob/—Ê2µ-<8ìåmŸt¤µb\x(;÷Ô˜—]V¸`N¿åğæ–…l1¶Ç‡JJa=|–d¿ç'?îäfü$^í&MWJ+)ì¤{dó?x$Hgpèå'@Ù.Pf•èjßùWq†.ÄÅ+¬  &«÷â¡^ &~ò ¸àÜß"fÿHLR9[	–Î ˜lOD½şc)˜*HLë>ËX@'×m§I'9‘	]~ƒ»ÊŞÖCOdşÜüØê°ó^&lö`,„ÎT–$±)f™I\Şr_Ô-¤w'2€áE¬ Âô‡úœ*öhü]¤~•¶à?G‡WGlà	ñÕ"ˆ¶;t’âksÂËƒï%c÷&Å;ìO‹W=LÍ¡šüM”Z³Rg§@3!Ànu}õ²W4“ó×3gkm	ŒÂ™,}ÌÌrµWì•¦ b&+’M„v>C„”&OBÒşù{Ó{¨=ÕÄ÷E¬øÚÇ¥Ú¨u®ÂYş›CTŞ>i2Ùp‚ÁoâKNRGoÍÒ*éê„XP‚Tpy
(-Å}.°½I˜ûm˜;_–?!F&d¼Âo(!ß<Ij”Æ¶~<}`Á^ÃÕˆ7‹ŠÜ!®e@·!im¨+äT©ó¿*²›ò²MÕé+ğ49—ÛZË
ïl„ŞŸ'
H+uòòÕéP}‚ÚXX½e#r´ÊË–®,?zhÓÜ{-	c_Î"0 äö*8Ç¤æ^›¿%'û{°÷Â-£«|»@PZoó½ùˆâÛL[;Jšp®şMÎ+#Ëê„ uëŒÍ¥¨³ê_Í4ß$U
Èb£µ	RÊÈ“ÂH’¾`Å¿"ÿBE¾¸ğ¹‚ÙmòäîÍAT,6Æêø2OoTOÛ[•›kİ’7ÀÙ·•{¿º£•âÀTØâ=ü¹½˜ˆ‚­ 	ÕœÚŒ‘XÀ¶õQ“+|‹Ì8ĞĞ”?ş`'¼Ş‰=×üv™(A÷"V*’±l3bíQø	„!Jõ*-ìiqMšYY{À¯DOaì¦ÍîÁ{ĞÒµ¶78#ß)Â†—§ÎêºW¦åHf&*‹K9·¦Å„";{v
’áî1Ë!S`"£‰µÄN>1fÛJœqÊ¯ñ^· ÍiCïa*æ+$ƒõÀ0dÚCMurÂ%˜ÄÿÔhÑá
¬ş¬ÿ÷g;GÜOŞğÂ—î‰zJ·öÇ/ú‚Œ†},öÏ“¥İãF0öÂ¡’¿e÷5åJJŸà {%— ¼Y:æú«Jö´ÿ_‹æmGO=]f·tÃ*Î¹uÔ…u;É'½˜ëÂrµM­ÇC«]Vá6Ò¯Éé¯stàC$KËÔãÇğ`O_UÎ_d†Š8ç'‚Ó_ı}Ö3‹NÛbF6Œd™EƒqnëØ‰[–q%¥¾3H‡áĞ2«
à@zŞh.¾e8ø)ªy/s€ÃâK“da½>••¾îö2ß‹$Š÷¿a`GBÁ­Úm¹¨NóYoPï”y¡:Ñ1#Û(
õN”YméŠ®<“˜¤ò]²‘­ØnBÎ?¨@ëw`“#»>Í¨œÖå=9P–­Ÿ<ëşˆ€š0ÚîfƒÊù %åÕŸF:­RtnªF¸Cõ‚º|…Kb@PS¯à³‰„	qÁ„ç‡KÛ¹¡¢m?¥@JÎa›>‹Ñ‹aaû@´H×òâT 2@®tİÖlÊUs¿‘øëjƒö49»U(PLT2‹Æ°rã`»¤%¶@d!‰¯ì»ı!Rcñİ…UíA ˜­Úm§É—È1çÛR·"ëPÜ.CÀ²-ìÓkú›·I†b›âÿCªY¢ÄXb>·]RÆ6Vï=±áÄ"ÃM‘0¢:€çLTÈoÎ?ß4ÁfùC·ÄN‘IİæàgYD€qusM÷Ûœ›¿$ˆ7¨›H~vSN\ÚŒC%†h$FÃu£,e…Q™ñüJ¡áí	âŒ;²÷î¥Á5…÷ÆšïìÂ¿j|ah)ÑÆhÓÜ3oä@Ñk`89Ä*‘K×¹¹AªU¢IÛäøæd‚5‚½êG¨¦¢¿
|T“KãÜÖı‡J!máSûµ„*³xË‰=¥˜¤¬¾Ö˜@eÙ†?3 9õIÇ›«Ï¯şûY©áü¢›~µ¢!Š˜Íºëpà5°Í+¤İÔ¹(¶xqBN3»vˆæÉcõ¸ó’-G›‚ *ÔTíÔD–Ag Nâ(÷ÊAJÁz¬aÃ)ËQCcS©­Í,ş2`#¸ª÷å€GâÁab†yuA’©áMÛAİ)ëHN.ÎÊÜÛeóÚ)Zv™ù­'{6‘MLmnÄMbéf2³Í5féCô-pÚP$ïÒ^?gñ'â€a‡tÛê)İ«GFRÛ§Èá š:Â£¸•ìqÙs÷ìËáà›Ş5=)ÙøèŞØEÃ%1Âé‡Œ%×a&İMÊŒ¶•
 µäÄòÜ™Ø5,S;€®8C7§¦çA¶Â&i´˜•Jüîô{À¥ŞäÈÎr÷&kZöûÈt*!Šß¢òr‘s ¤.@"á—uÂÑ@Cì_3¤`SC;Ğ;\Ùë‚2u·÷İ&Á~”Ğ¾¬è¼û8â]é¹¯I]ÒÌ¡ İbƒğûÁµ¤ş%˜ºöR^Ù†]H”Tà–ä™CË`> qÛç'·½:U˜;ß¤‚ +cJš¢§+ºÕ†ÊÛñ.O0­É—QLí¦?Éd}gÛJ;ÍlìL+Œ¸Ûë!ß'%ç'­Hà%¹Î.o³]½5v¦ÿÎE :ajğğ	 ±5uµ{ (xÜ˜,íÜÖ_8&§ëMçû *jYGˆİ-²íEDÌå e“xf`ÄKHíÖ„¡?å/m2B)š¸¼üÂ%l2§À3 ıšâ’ãşx§ëİ.tJß…1Wï.<6ÚĞ2öF¢-fRS¯4FôêÂaËò ¡k‘CL¤Õ¦€TèÚUèUåqLÿ>£n\ÜîÉşÖu~äÖK´ü‹ƒ¶èˆ	/„¯I¡/#ø­ïhÛké	a;³ŞìuŒª4—§/ç²a0S›Âl–6^²ë;¼»÷iÂ ñC4u·ˆüM,„ÎË3Lİ?CÛÔM£æä»ë¡+SF³¤Y[`äˆâù1-J%–ËßÀ4ğ‚P´Î(g€ˆOØnrDrXqv³>•´Ôô¡Û‚ÙA$İçî»”5Ê2h,›7ªÖûÌ™%Ú Ò§èğ#Şh“`0†ê3ìÁÉ´"aşÑ…ÏÕÖùo~‰G¡~“¥’´÷—Æ‰¤¶ß‡—¯è5obæqı-Ü7z_?Õˆi`u k‡,ß<$;ŞíbáèŸª/İ¡š¹PşhñÅ7ŠñùfW½ˆ¿÷ıùXŞ‘‹’U
ˆ–”=ÄùèA5_…é¤…¹¡1~>í¾¹ìLP-Hëô”öDCÔóò¸¼Í„ï›ïGÃÔprK3÷gâ/T”{ş³J2Ì…—DHîÜ¡æ›ÎbáîVºPf‡f&P:‹›¹5Òº@åce£É67,:wI"15\Î¦í¹jdUaq©3»6…¯µÔæº)ÉqšAT4uúTPğÚ­·Œ\m|§;ãÂYFW6mŒ²ŒDŸIÈ€u°x§Ş]<Á©¯òô¢Åj›Ôµùg’¾—Tûò½_;¥Lc*.Ù¡%9¹ôİ@¶¦FxÀúCşIà,·?h7'ë€€bËH©ìL”²vÀ…óE_ €7ÖØºq”GıIÊ>¥¹KU?yXŞmœJ@S¨ÛÈ0ÿ³D’_E+ôİŸuö³5Ãoø 92ïñµºUXı‚ÉæMór‰$ä—£Ì5ƒ¿ÎÔ¬ Ÿ_kñ©ş^èÜìäì¶ëÈäj,‘l€ğ¶Kıİ)Ö°aä­â°^+“ÕÖ_•p»[Õ¾¥˜[?$È%ˆ±¶}¥>Ù#Æ3¿X³vèuå=H„ÍkRM
D%¾YªN×º¼öyÒŠ–(¨?2ÜC«©îİš"wƒãËº‰|J‰KĞ–pën¢[¥ñ†ønM2
£Ì€D³ óP÷‰¢àÂ–Ë‚è[cşÓÅ—ì8ª ÀÓÒAÁ9‘C»	·<[Ş­ğóf³øR¶‚%„^%:'7˜ÑÍY`„>¬HŞdnÂj³ès¥,RÔhXÂ×lşÃZE§¨¸4NŸâĞZë—p6ğû¯ yçW\È4!çJªğ³M¤d²EnÉ^del)=úXÓC¹ßPg1ÀÖ8£6X”é<:e@¸J
‚ÅuÚç‡@92²CÚï&3¡¦¿®ŠÇ54°*Ç 8™øàgBşçb¢°·r§û%ú‘ïÁŒz¬;¹,é¬ŒÇ$–ŸùAØ¬|PEd<Ë w¯J[°0SĞƒ©%_
Çk‚×@qZ5Ó:¦ô«ìòY˜ƒÅfoJ<Ãêm¾ß‚$­i®ğKw5»#Ğí‚Ÿé.!»
m¿,köÀüÙ„2b÷.u
eëGkEbÔæ4…šœş…ãD£…\Ò¼i<Ácq19·îÙ#g‘éXÙ!MV>V©µ%(Ós w¯¦¾ÛTWŸj3IE±
ğ—á¼­}D»’¤õxâ*/ã,É|=&É}S>{šaO`ã¬N	[¢:\r Wû*…8Â½kx™çÔ’a ‹[°øãIc
ªcHÃx‚_Û¦â¨q=)§ÖÉLÑÑˆò¹ÜrşMXì¿ëÔ¹!_l¾Ó’GÙ1]ÏÆ†éç•xÇ°1h@ÉŸ\}Q_nJĞ3NÛDÄí‘2±4Ğ”	´Ènûw)ï–ó#ìş4Rœ_Ì¸¯<v`@ëÍ÷´üöúË~zì«n¶Í:Ãë'\™zK~o—Ï»v_û.¾´±‹®Ö¾á Êíêåo¡¼¡cĞR:^ğ!<}eÿ€ğT»{:Ÿ‹œ—ıjsòÜ*ªüq"ı¢+*WÔÆk£Hm%+óu%
.#ºY>j¿lÜc—PÆRq÷E¤ç}gJBorøĞ<uš›6h”Ì‘N)gš~ÒhxŸëaº«If“vè$æš •q7)Ÿ¸P=ÙE‡ïzä!Z ½ôÍç?`o_b@Ë4î‡À´İ‰…¾©|ÕA¥µŠCÃ¼3¸úT©`Ü[ĞI*°ö3äwë¥’%÷“¸] '4ºâFªˆÆ¤äˆ.­œ'0exÉ4Ä£¹¬×ŠU\?¶Kö½õôÿï{"Y³S2[hÒx÷¤‹[ÏBÃı’Å3àqx]ÎĞ!Ô‹°!™%dqín§ÚD)àr*¢kÔ¼Öb‹Õ3VÇ ½,Ğ!:ïG×±÷6 ,¿‘Œ?ººpÈÚ{5õë\3=ôd±=o±å6k/	•J‡•¦ÓÙàSwã°ı®#K/u0ó˜è>Ğ/‘eÍykc§eÜÏl$ÃÙN’&~”—]C´Ñ£åÖl¦üÀâx•?öùC8ÕOeS:RäÑW/×gvöÛäÃ^hqAqéşHv2õ¾nşı'1nı@¢¶™/!  Û…‹Ä¢Y³Úhm7’î§Õ“Á}WµOúµÓ8*ÊCjÅëĞá	8Ïù!
æ³´w.o§¤!pOh9ßk˜3Ó»§Û¦_€.éÒ¼o+è3‹±k’•Ït†+#w¥êN²;Ä8¢—"ğãY«¼§µ—û
…èi'e‘çÊG=*ÒÌm«tQU@5>:­<:vwÿTy™:dîó|†ĞÈJßvúÕ‹v å†•0ÍÒ
C+Âgß
²MT—ÿóa¨OkO4Oìı­Lns×ÄµÎ*¹™±9Ã/G?dÁ^LŸ‘µ%€·W#…óâv .Y0€ùÎ/'ôôág%û:™òkõNz"¬×BÃåIÁ=yÄ¦x×ÁøTÃº¿ğú¸Xh©ğ~ O-AÒ‚N¥ğ%úòŠê,jÒ ğ¦}{Udş[z×3Â²İ¸-@‹’ş®1ºNÁ€É“Äˆõ{Â¬/ú®ü’ßï›gÆQØŒriôí&“xSª)tK|Æ!ø„XıFƒ‹q7û'“"Òùeu£t! ãT*,ÿXÀ±ç„×ªĞİäÄ­¿ŞvTuºŸ™Úş$jÖa;ğZÏ>]Ğ7=ˆĞ#¹0€’ElñÇ¯‰<Åx*÷aCpñÕ1¾r÷	eœ3”Ã ÀD.ÂU•b\Çz`›µ·6YEõXrSŠ•$©äÊ—NäwÃEş…–R¶•â Âñ€„+«8PÔNTá÷Vë:•B†[gê•Ã)äöAíËí
o–Ò¥U÷uS¾ws¯«vW…ğ¬…yªèû‰Xì‡Ê°øéÕÃ	º8˜jN¾˜§xµ,µW·‘P‡ËÈ¦…á™s:°L]°vX®®²v˜*#»Ş¯p‹¾{ ×›œR´‡à«Gw;øâlâËÖ6Úl¿¬fOÕ:™J¶ó¨juC#ç†&ÿ½È±}e¸dVlÃ€Ôõ_Z?é>˜ı™\–_À•J€¿½“äœéûJ[*H¤#ÉÇSİTÂXÅ’$ì/»E&ê<»ˆÊÛW\äLY<E1æÇ¥Ó!2ôğÿp§èŸ"#ÎÕ#"êÛ¬°U—XTLt4]ü,üô¯n£2Å8ËúîPµUZà`ù4©e.ÜJ*CóHÍıªvóæ8±æyu"¨oBg™?è‡­b6fTã8*š;-§Ù L¬lcö±á\¶ãƒâ™r{7©V>æÜŞEuA9#FBàtxµ[¤ÒøjãZ+æôº-}[šB§
m/Õ;}æäÿ‰=¯H+Ö:›êt¥æo¹dƒ;1½e;Ô¿Œû<VÓ‡XËñ²\Eép_ˆÑ×Q¹ÄB:VÚÖ’`Övë†‡2½¢e³¨X9»,íÁÅôÒ 9PíÑü%_ĞøA—óı¥¸ş¹pg¶‚ ı„f¹ŒèiD`’ï2ö_à^v¥›O`M³3¶-RÚ‡ï+®üÍnŠb±ƒõçh–Ç“õùÂW©FáÂÎ	»XZŞÏxÌ‰é,F†~ÎĞ´ìˆàèóî&Y{ÀØn¯ì0Õô€ViË$8du	—ÀS3d_BÔ>fÒ” ô4Hm¶e"¹iæíV×Q˜cöÛä¹Ê^›ès½ĞØw&ìzSÉTQ¥x™ tË
H¸ıƒRÅVŞq+§Å¶öM“Ëj€(²¿å‹—¢£e0àÑN-Š!á/fEÅ¤C•*o‘¶ÏÏ¶aµ«X:ØƒÛ¨‘ùÏK,³pÛ¿ØMÏŸ‰<,0RaË/ş"çüyˆ®Âÿğ5€8Ì£Â/ùß&ŸµÄºŞ###À|ié…óhdñ®µ_"aÃRcĞûZX	ĞYt·³}V¡)dÁg¸RkxÑFIIn I}'%OfVc xøuümƒR¬(Hrş Rˆ³°Er(+Q+Æw\‡=[ ›÷jÈgÉx
±—ôE‰±›OHáëñ§®“½:›R@4¿|îKqgWşÿ†\œóJYO_Ïoî(ğ7~Y=oùh¾Oÿ¬slÎ­$‘ºiÅ@ú­á°ß3¢â²s¾»e†OÙ{w’/†[[û.…;DÅChƒ2Ó™ªçÆ	aÚ•ø$ãÙŸÁ'+Ë@ééJğ¾Ø|ì‰è-UğU+ƒñ,å5°Ë|8¢ôö/L¦'}ÙN";i±VNõÆ†&VX%y)Àª³ëJJF¦´xA+eØDzQÊ{ÂÎ3ËÙ±êß[sv@Ä™øí”ókRÊï—>´Fš¢d‚ë ´ò:&E¶¿£HY ¥9Â›¿ŠÒVæ<"h–…0hVEÓıO}Ï<)at}(câ´ 	b+Ç˜û¿d»w/{²0‹ÄkÚğ“Ê¥ÁäêPbÚƒDP&Dà±wÆMƒ—›wôOÔ=	ñ7BoU†JîPÃ¥GdæŠ«¯¯QpŠN€ag\z|tó¨Ò?—®w2nï%»–ŠÔuë ™mÕJÀ÷;>¡·}Øæ˜ØÉQ¹¢:èT6œáÜ]ş$ÌÖöÁbä‘uèD™˜·ô[¬Ø¬š.¶ûˆ   ¢)~SM Ÿš€ Ã*>ª±Ägû    YZ