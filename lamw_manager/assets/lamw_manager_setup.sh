#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3713781597"
MD5="d718bec3ec53f6ef82f0baf424342dd1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26628"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Sat Feb 19 15:23:27 -03 2022
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿgÁ] ¼}•À1Dd]‡Á›PætİDø¨ UÉF«9´Îèç‹´ß@Ê¤ïÜ±QÎŠïí÷SâŒ•¤"™­ãšŞ„:øñ‹&Xìqî .ÀHY×ÚŒ«Ù†q¡ÒÙÃ99G=¤1Çr!Ú ¸˜²Âú%Gƒ©CÛÉÆ¥`ENebà1–ªòhÙqM&L5QšiI/Óp½ynSÚ&-ïBa•.ÙµaÓ†Oıäá×	Q«~Úì[ÁKğ¢Z…ßV¡QªY±ìíEñXÓ…)à¹q$RÎ£üÔ1Óë.€ùIaÃÓãñe³Jw×œ`Z°­…Õ >–ºšo{1şÃ³
ûå„‘t0ƒS†Oˆ›Ò¼f”&ÏŞdıèÜâÇ©ùÈ¼¾±«ñÙDaù9ê¯¢3ÏñŸª€px~“ï~ıGÖl2¼n>õ‹,	2.'R"Á•>í¸:OW=7jvŸ÷-œ«­>{ßSY0&¢ÍÇMuyuƒ ûœ¤[âMµ£º~ÈtŞbzü3¹,h§ºY@P´ü¼JUÿ2)ä‚NÚXu¾å$Ğ±ÊuŸøwH‘ò•ZÕq*ƒx]ÚHéÅÈ4çEëqÔÑ%±@›æê·ÁÂ²Æ)ER’\]±w<,‚ „åPáˆ¼cÅb>÷ÿÀŞëCÊò>óÀ|Ê§í‹Òv‡qlAáóùi3 ¢ÒÕüXW•OãQ4ÿ}Ykî†šU İ)gOo•[üisZÖ'•ìC…ğ-/ªyãôtƒkÌ¹ÄbAH†ôŒ¨Ì9Ïß[d—%°¾ŸğÊíñ$ÃD¦™ÁHñflSUq7 kúy-#g"Çrøj0úÑRmUBghDgDü¹
úÈ€ÇÃÅ]é!R–€ ÖÚo3:R*¨v|ë¼9ôjçiŒ‡‘2ÁF†¡çÉ‰ÂÏ,YT÷€ˆ õXLeƒy¼ú!OW*[ß Ío%01.ÎiÖ½¼?%ãÇ¦Ÿf¥L¬°×İAÃ«³<qŸúÎ-‰:{ÿÚ>ı6° [Ù™¹6Š­…ypøtNSÉ®‘ÿ»j‘â”ãEeªğ¦òwéø¦İ´êGJmö&CfÕ’7ıü—ÿÉ‰b]iİk‹ï ^Às—Àß¹-ßL±mìçø¢ol:ıíË€«½E¹*Ù)`²îÊVMõä©$Ö<'°*‰SºôÃß„“zTIóAâhV|Àò>Æ³rë)zvTÍ7©a/Ycx¿AJcœNÑáİÌO‡ˆÈqhÜxQÄ8Ó¿îB?/	FùÂşo°¥@¾zŒt‚õÓ'-ß‰HÄ"“dûqª%Ü3h›4eÔd€Q¤:Æ‘ù+ > Ôš”=™º«ç|‡#Pº
êŠxw¤åv¥Âi™×Ù(Û‚!»¤8OWvæqñ)©TæÍ<³¥Ö0­v†‘eH\™ÈqCXtSM,Àæa¯,¸D+!UßÍğQÄ;Õl;¬_	>7*ÏW5«M7ŒQöL¡w9Q<'STz$Í©Ú:Æ6Nî:şk‘Ît±Q¨o:“Å‹D_næ
¸1‡.Ô~DİµDñÛWP‡ÏG1¨€Ô#…TÉ€G*>9š·YflıéAÙÓ‡ÔĞ÷(ù#œÆ@_/œİ5¤$‘M‚åø(àÈ|Ã"ù†ôÊ~'%İÕz`İ-ıÑ‰4¬€¦!…J¸¸ÂP?wWEi{è8ñïƒ:/‚²G½ş—’}Ê¿f£»?CùånÄwcD¢ûÀ® šÚaUS„yæ9ä“â–ƒêgêjEâJvhßQ«¦V4K‡aÀ,»9"=€n~ıæ%Úå¸¡ŒËe@İ†1f½â5ŸÑf\G'(ÿ+¿ì”,›^Ï¸êãÕòÈz6$ıÆwY±÷]‚vû|ËSwğ¸ê^DÛVÜÅ5dÚ”ÄÓiöüõ_éJÒº¨:O¨—ò§…*®jô:Sj½>¯ƒº‡-r1-æ¶ƒú1«åX jşP¶5ÿ®cÎ[JÎòcBFÜ~Ñ(ÖlI.&®ı
äQ½ßÊ1`·ídÛbõïh²†Åê€{ÇxØÿ
Iº™¡˜•-ë7>V˜0ï`D'j¿ÉQYwTQ…g¡Ë¹°Zó/k‚Š'¡ÄàŠªã§¹®N‘ĞÙ<oé[îøká;Ä¤ó0l8¿ixRJÖ¨1Ü•ò'U/”qFÓ"`”m£ ½ ˜Ä¶?Zˆyiõ[Ê®İÈz~SŸíQŠ³?Ù!A!jHÏg¥ªÀ6óšû¥ÊÉ¿k—RU„Ğj3hìÿçsw3£:z‰™xìî04Lµpç%²„ŸtXğ¶V·ıÉŞ´—ZØ #`»ˆ¿u0ÒË‘•9 {0äxKJÈâ‰Üûš‹—ÄSĞEğ® 7‰ëïºyP1öYe?`%ÜVw+MÜxíüälàr{£ÕŞs9âôŠnñç"”q#çëÕ«Hın/§¦­ÖèÀJ^·½@ÓÇ7íê+÷¢Ü °Ôõ³s®²¥AÿIÕÿYšğr >¸bù¿
„ˆÜ1A,ÔÙµJ&§İóş[rü
\N¬VU¤vm¡¡gøÃDı/Ô/ûÖ)ÆŒ»¸vPÕeâ¿A5Uã×›_éÍHŒ‘HM^CÕ¼y³Ç7Éò™ıû¶ëƒLIzîûó ¹\OâHµÌæ
Pr Èİìôì­Šûmx˜²›ô¾q†€ŠÄw
Ã­ÙiVwÈu—`Ó;şü?NTX$>¾È×0Ø0%ñŒø“®÷S÷9rí­ß»ÊbVX/èÿ˜˜î¨FgQ¾¬áz…ád±ÎÁybK|í_‘IäºnxÖëR‘ñÓ˜W&oé~éwVàieò˜¬İô´Î Æxà$ —lÉLwHæ©hMÚ)üÜAm~“â‰EcÑ	åuE>e´NmJ3"¶¨ú;é~Á"©9µ‡‹b¶(„L³ã®[ï`Í™ë:Ûâ•ŸÓò2a ‘F[“LûZ…™¸€†›åYgtºa}ñ,©­øß¦)0.]RÜ@4_2È	üY6²ÇSZ3rtPKbà­ƒYWXƒ2¦ç/¾ÄŠ"@ƒÒsÛq'}’…?Ñ—OŒ®¦óQ^LÖŠÅ4åjüÑxg¤Ê8UÿË‰VL{fK:'ö‰˜!kŠ†<_c8`S÷ƒ’Zw¯ğËf«Îœ[ìõájøq;TÄM	áMn#%´Òœòp&--=¸¢&%*‰Ë!
½ÂFG”çøñad6i;ÖšˆT…„Ê`˜%ÔmŸéé®ÚÒc'™g¢¸Áÿ/:ŒnSPßôÓÒ!.É`:å/ àÒùà6ÍOÉë[	äQì›ÂØ³˜cfh¼=Y€÷p|ïÂ}QOÏÅ8îÌŞpc±BşÎ¤¨¾óúUÜ
½aÕ?dLâ=Ázİ]t³8NïÔõyHlÎ˜Ø‰3³¸dÛ½Ç˜ıÁü:«"2J™«ÈLø™(Sdí%½à é¾1ÁlUØPRÜ˜h[ÀQD&|£ˆè0`*ñaQUxA(õuÀBYœÑÂgEmé>«5°?·zàçèµŸ®ÏÌ!ZŠğzSØ‚<ÿI){ÌzÈ]ŒNñwæJÚ¿'Ñ¿ğİí-uÕãêm.Oá‰º£ú™Õv5h˜va”&z)#*]¾·!NÇ»}=c’uRˆÍ<ÒÎQ©ò3fÈÉòTÂ—ïN—­ Ès@9Íê€}&¥Ü/ƒ„¹ı2É,E¼öÈ-¦{Û}×sC€bÁ$;ıb-ÃûÃGzÊ0Iîİ¯£ÿ)èü®¶Û²Ñ}ï;.¦´}PÙĞƒ€¬ ıå`«å‹üv­-Ğµş1İ¼éZZà/yŒºğ Cv]I·’»æ™âdğM-)¿Yˆº¨t
¬Y|ı¹’ÓÔ¿æä.é©ãBÙ#ƒI¼©RJãÒTÈJ©ßƒ¦Ş ~4§¶Úbº*	¶=Nã½´Í)®±xŒm£UQõÏØÒ¦Æw"©VR–ãCûûSÂáÿQÒ”³òÅòT™³¬:H]ƒOˆ)“r_?¨|¦.Vñ5¦»ËÚ±É²—NñĞñG‹ÚˆÑ™®.„$ƒ­<Vlˆ›¸ÌşOêÖİ™´Ç¯1—{d‹Ü…ƒu
S+¦ÜL«İnk=T¬ğ]¨7o	Ád´§¯¸Š5«4ò˜;Zû@áã1şõ’\Ãˆ¾ªã ±õ+µloä°ûw´ ×o"
Máª^ŒŠIÏ’ê–» ¡ƒW¡°©&ërœ2üñyğœOœğ§¬âs/…UY|>6‡ÓKo_ì2ÛoT¯'vFòGô¹œã©ƒíã}z:#"ê0¹r{>˜W»/¶iq¾Ú9ÎG•/öa‚«xÉ5ë“bÇÄn•|ÎnÂ)ŒŠñ³0à,TõKC£¦ßãèfb?|:Ô¦-èg#»êéÚOšØã{D­M@;)âÒF€QÒë¢÷‹‚q©qRxNİÅQ²èƒtVbÑ¤PªOq[¼YI¥¼˜°@{îh¿ÜJï®tÒö·ÓıÔ+A¤.–ZN}£‹Àc¶œÁ½˜ükN¾+ø)êÁ*¡RÊpwh«ôXóQä¥ÌÒÉ9ÄÓW~±dWYz0üjJÆ†— ûœ/Îæ‚oÔ¡ÎŞ>j#j—áå¯Dæ%
lÒ1uchÈ•|X-wªwù¦”˜ŠÁ‰køZ´ú3 =÷»’iúpßm\óê§¾Ë7Rİä’ÒVäËÎÀKá¤=MFXp(w’ïšR#şXB•X{®„\ “Pµ±)xâğ='¤òÄ*Ü”šK•sÃ£Sc·%‡Ñâz‹,Ê»Ï»À÷×$oî{gãñw(·Í*ÍÔèí±ã¸by'ZÄ¶kó’èú9@&h Ü=„èøĞ”:eu&³"ö{^æhlf¹øêĞ:ÖÕùÁ…ø‹ïBÂ #Ö³¥BÃq´p™còâiŸbn}¢é;S
«àÉ&ªZ‹Òúh?09Éğ–>Å3m†ê@ÖÚ‰bÜÎrå¦~1F`{Í¬nKl,„áŸì/<ÜZf,€èÓñ¥äëCæ•MCû°ùd¡™qO·¾(ª`ÓA)ö²h2Kş?&{œÁwÃp(IoÕ}eEzº]H—°½vşØ/WçKÅ‘âZéV|@$}Ì–¸ÈÜ-tnªû¢‚&™Œ]û€çG«óÀ¼ùm¤,%µÉWŸé8ÎºMİ6ŞÓ†öîwx4"+‚ë6è|ı«.ëU#Ô1À8­ƒ‰)jÊÖûûc‰Gö@…÷¼ˆUiÿƒ—ìQ°ıÉzv‘Zwÿ"½ÈÆ´å·yåkxS1¯ÍÎQİ>.K
¯VÇ4âK²s§ÍSYa”ÎW›Z‡”N3.›6ÕÆí–G30û°†•ä™xîjñ!ë¸•8]BÇ¬¯õy>?³öx¿`–N7ˆs$Q4oáèëœ+×kõÀ{]ÍB  ®/16ö÷zÊ›æ5>ï(x‡D3üèFX _[‹3µ,S‚V$üH˜­NëÅµy[YEçÏÂQú!Ö”ß§¦Wj‚rW¢LîßÈçáG36<®`¹'G÷Diµc”ŞD©]}'×–,Íÿ"&O­Ëš½ÓÚCb.<Eœ0wBdéH‡°ct\`œ›bt|wŸö=ç_÷îF5NüÊçºôTºp)Ü¡ÜÕI+cäõŸSIŞ££ˆ5EÿÅ!İŸ¢H©7\€>”<7ÄÇé£ÊôŠz¼¯ašºE'Ã«%Ïi ÁË¼àcXˆ2ŸYqèS.ñÜĞ‹TŸAmÍÏìá‹‰p€‹nîÍdxı^T LTHQì]\÷HàP=1kôÖ†pYÚ¬ªË‚‘úî•Üµ7(’m‹HªZVaÜ[€
Y ä;qQêÜ{>Ë*>ÁœÏajc¹×vÌ`êFôÏÔ‡môFó‡n·ØeĞÔ¨FhEC‘F"ß‹',Â0@Nq­zzPºæû:äÿCX«â]…=i£ şŞòL%«øp(ªÑëÓ2+„:³ê¶K­ª£›¡Çò¤™ÀV&ğó­šVBi«–	›èp ™mc$ â-ç÷JĞ7ÒÏJ=:cíÙ,‹ìÕœ”³WğG	f©ããB_QÚı4|;Ñº!=§öQ/Ğ×ÂĞQKöšû
|æm×ªx²{ßZ}×¬Q°
šaoa˜–siî‚	¤µeıÖÛ¥Ì£h¿ç„“¸	t™ñ¸UÉBËãá!èy3—À®–c§<hY±º·q4aQ8½ùä²'”¿'İpçˆG(g”r³Úm)ÆéV­Ü­_#KëB,ãçŒ@BÇµ‹MĞÉáßŞS‚n„{çÉJŞ'q•2>şaËnƒâËgvMW¤±¼+?öTÂ,çB S­=ĞDÄm’µ‚'›© ˆ4nà´0b'àvJnH»Y º<d*v‚8×Xæ<"Ç|ç%(»IsDfâ_q+
À#P¿oÁDTúN«àh²ñ•Â
NVõñDl#iË`{ñÏ¼î6blì¾OùÏÇ;Gp•-éÇ:q5ó6Ò ƒåÂ8/â¥€‰ 1ÆÈ&lÃÑPè¯Š»ùq ¥ÄgØ4KZ· ¸×‘íôş†`Ùó’îN+ƒC Ó®LK{RYLÇ½¾?ÿ_ÜQ/*»‘\şFx`šiRµÛ0T:b¾¬İ_˜¸úŒíQzê¨ÂLŠİ*ÿ§—“ÿ¿]
Õ‘ò!Jhn•hŸş¤ËQ5^K]‡óèz?ËNÿğZ<%3‚>©¸A}ŞÊ4¦˜¦'Z+J~¾<‚ËáóİE nÛ÷—ÍÍh¼÷6H1Œ~)ïtãƒtÊ' ‚g#=ğ«·Ï8f£Ûf¶ò²áâ2´ï±»£„ğâgÙ­*(Qi+ÄóqëáZ[©öWÕÅ¨Åvü‡¥ÿX®6nÈ°U¦r’\ÜE€x— K‰°Mš]ı”ë.y@}é	âËƒ=Ği0jØÂâÑÔFâıÌ–!Æ*û‘Ÿô"bë1Ìc¹TŒVÃˆ ç‰—~ÓrRÜ‚‹•oQÖŞ5œ‹¾)•,5qC¤£(»õt‹¢fÔÚaåĞ®,³‡.º<*tI¶ø¬öªKd¶¿ÌäÄW0=('Ë™ S„M2¡¾T2‘åJª×=S¹ŒT7oxÔò…²Oãc×+®®E™Ì†ióÊMH$÷lBMÙ„Œ ¾s
›r Õ«mfq{•Q!Èÿ-)¡~À-½æĞÈ3ƒ§–Òs±qk5cÙEéYB"©$¯¯tSuÒYí)Çl¨˜fË«¨á˜ºÍ²A¾µã’áÙÄ^œDLFêéF”6MÛ¹OÂz£«J–×Y©ÎJ†/Iø=yp†’»qpYu€…•.I½-÷_Xåñª…o¦=ß­,’úcG²OÑ´{BÓÛÔmL[]–B'âhŠ×Ä¸~ã¡ÏŸèø1®[}ÜoÿİP+ò˜uÎú8	Â—êP[ÿ2@fãmØéG‚Å¯ìÛŞÕ9æTÖ?ËO“@QÉÑå>
wt »·Cëx5ˆš:F¶É›VÉÇPñİŠ°%¹<®Û`T¯¥jX+
·6ùáCı.…¢u‰‡ÖyœĞ7u#Wòi#[³*¦7şİp,(ÊÄñój9@v. ş÷d(å ½P­2ÈÎûõœ€ÅƒæÅRBƒ£•´qSÖ j‚À‹Å§¥a>aÏÌ~w¬OçD…üWI,]3C÷ÚÿÑÁİM‘´`‚ÙJ‰»ÑA·_Ÿ¬˜¥,ˆúàœ_×!Õ¦+üWâ¥?ˆ^&Îö9ÌÄğ—€P…Nî$ƒ_Âø“àù†:"Æ bÄ4çÍ[Pû¯ƒ¶™Ìôüè0É´z€BV ŒSY’ãŒaéî÷šàVÀ‚ÛG=SÓ-nñ©oĞ/àZµ7§‹¼hÇ
9¯È¶OÅ(ÏÄ:²İÖ²†Z×1(h‰ºpSá‡ZP†™ŸwYáC;Hjî¸/jì÷&3{ï7½ª!(¬Íˆ?İ%ßn¨9æR†ô†Š%l
6Åh½®+$wå$6Ûb!eşæ¸Hég U,&‹³ÔÛ†ñ¸Y‘­ØWwÓA¥]WYÌ9ìÄÏ~Ä³O2ÈÄ|Şà>ÆqW-^bgY’Øû[è÷¢dxœ²q!X@–=ïP¢æ$ÿ+ô7H}–;ñ¡ô–Ï¨eQvPIÎRLy¨„Æ¬ß>
P–5ºûUæëÂnœ2ôô€ÁûÍ#˜é‚£2ƒ¢y~Ğ^w§Bü{;“u*ÁWxI*TxÆLéÀMi"‘ãqÃ¿»ôMûX-‡%°»Ç£ˆùº¾Îüµ©¬[Ù„IÛ{çÊ\ƒcuivœë%•À
«8p“ì²…†ÕpÎÛõV{#~0ıüÁˆãiT™€VÎ(R|ˆttÒ‡•.(åÖ¯ò»{Šñ(Ë‡‡5Y/hv<:Dúã³Æƒù†øZ…XzÁœÍecæñ>=dÎ.–xì´áÜ<ø¡§’Oë^«.î\´VYòĞ*ˆÁ‰(„ı +…‡rQa4Œ»Ñ:ááŸùL¯ëèfg¥ém1úšĞ©>ÉˆÙ>aå‚Öû›2uò°ƒÖ—º8Ó2>FÍkRÁÓ±&Zù¶×eOjÒ—A|^[#ßq€òÚ#!:Ïg"Ğ²‚sÛof¸íQ‹\‹QÔ†‚
cîÇ`¿çŞÁN‰öS
¡ê<KPàŞøm”/h¾Íhã½Á)ò%lo¹xÍËÜ	z¯[ãHp·â–üy¤XõğFş™i%ˆŠ\=1ãë®÷à¶Z$0\D«ÁPA8FƒKÓàäÆ^rv@#òYõ\ÿ‰½~¾óÄ×ˆ6ù»²­qñ«…GùåaWtM¬’ºHàÛñ_¸^_à°Ÿ\û#¹;µÙæGŠ² z=òd¾y¿ïüÖD‰A&kôŸ1¾%Ÿ×ƒ·á¡ 8Ÿ_»ÊÙ”!`”fhéw#âviBŒvåàpÎÆÒÖD`y_×B¬>VnÖ&i'6şäÏ"SIÖşÈ
Á¢É3ólÊfY‡¹6®!ÏC?­Çˆû¥™ùh­-‹Aj³{¾¢<şÆ°Ø©MF[Ãı¶YÄ–í™	I+€}—àé´gëaõOò<Cg?M³Á*ÚÓâÏäIW¶:ÿÏ¹bİ•Qe½]ŠÂh¿SU59L=~yé/±­…„[9J­ ôé.\Í÷|Èt; ÿ(%i€rÌf¯*#ÜgØ¤‡QW°e´fü§-u¤øzÁÿ>{DxŞ™–µg]®RÌßTõöŞ¹2\™y3yksèL“Vk;NåHªyÒisûÃhwÈÀ .vÏ|±ê¸VÚó§•^á¾êÕ…½ÂóRG“,€J »:x†2ÎÎãcşq-	dçÄEñ7YèK’sæQHùçÕt‹ÍrèC
³öæq§x<>×U§¥h©6¼©gsh­¶R_€¤Qc¦ñl<‘%ê¸¥›{6]R@n&ÓzDf;FÏMÒ	.r 2²\gsªğ1“ĞcEsHó‹½>0pv:”d¿ìRz

K§nsì˜P'¡¨ÕœøĞ¶ibN:ÅeµJÉ§q«Dá)v «¦öÑĞÕŞĞc,›8ööå”„•[”Ÿó0±)È8Qå*nÔO)–VØıZ˜ÉÔ]Ğ§œÊ-¼m1o\*Br•0×”#Û‰ªV;İ†óîä˜D‘Š°Îp?µpÖ$%íÓ(íYé6Z{…ü ³—ÜsáG.'mà|Ë¤Øayb‡Â‹çZn.Ö<eœÊ|0íë‡¼ı@‡îÖs½›~?ºÄ˜eCc¶ÄÖïeı°ªş˜•‹W“„õZÀ¸2ğ×ÜD¿,«Sù´½¸àœ8ÿT{b'MÍÆçRGmOµ?“;èÈ¹»ä—"ü9ã€”¢ğ`i
œ´İˆy†6Fv\¤€TF/ÜXÁÅ9	ÆŒë~­ùuÎãSá¤4ÓBkE%»Şf^ße³ãèÊñÇ^«¶*µJÓ»(bÍÁfÌŞ
u©KÌÜ-dK»Ù—J^>ê‘ú®½¨­x	…¦ïÒÈ=C‹Jk3/-lXfh~Å¿S7"Ë%}FIB­êÒÎ‘•6Bâx§ ÷üL†QÂÒ7B#„vTE@<ï9½/Éérx\p^@lÚlC;é‡ô%tõH½`S.™xXó#œì3ÒĞãNÔ4"4[ü†Œ'¡ ?iô³„W‰`Á€/9˜!©·(A\ú¬@P0r€€LË"Äs)©?ŠL¢F«ñ_cÄÓ÷"X“H„‰3$ˆš?n“(ÕQëÍÇÑc;ï¤^73îÉCb|ğ@|ç‹ª|şÔ[»éÙÆ7³ÆådVC5lœ“¦ŸµÿSüI²ç,QPª„Ê1‚Ó/w(N4K¾ÍUešr.j Âœq€JbŸs.jÛI[ş ˜ú±Z¬#s\Ë€_òò}…Íq©v'Cn÷p9çuòq­2½&½æZ¡•5<”÷¸=[WÌ pYvT.}ãjmï4 .â~OùÛ|Í—È`wl#¾ÍyóA“Uw"v¿1Ë‡ Eàêñä*ó;ã¨÷µE?]ª…ôpKcD}İ¶•F
V	°achˆ#î³õŒ ‹7—lï©s-g¼Ş²Ó+Y(nÏÚ!†‰÷G¾vš‹‰–€CHmBmmH•rZ¿^n"Õë™‹Ğ¤­Ş­³/Üšôõ.ß¸ÀOˆÀlÜğ¯Ò÷‚æ™y©0›º CÉ¡b'Ô±±¸iŠo;…üû ¶10ğ<Ã§p!j”à…L6´BéŒp]<#¤sæÜÓOù±7 cõ0R«rÄşY~ë®õşšTBúáÀ¹[>šøÚ„Ğ75ËuæR~»@~pNç’®\àevôœï”»Şô“‘	’ïœ™RÑ,ğê¥!á?ø,,üî¶Êç£I"LÇ $G¨’;áZúRàòGºÙ·j!\…äê&êû<˜Ãßiª*qfÈ®->9êÌ¥J™ÎrKßòuÎ“Õ¼°ŒòKU
$°‘6_“>¾‡Z“—zÎ	úf¯˜…:MŞz;Ë Yó\DĞÂ~¡Øµ³ù3?`9	Ùœ[^kcÅ‹"!ÿÙ²e¤‘hÛ8ÚŠMò0Ú4¥‰àú wv™wBLØ_µ=(Ô¥%ª9;ö¤‘dßêLài‘.{IIƒp¿(ƒ”1ƒ/ïxaØ]O!\ ¿9Ë«‰:¤ s!€é
`Åçş’Ó£zRJ‘çB¾m³1SÉP£¡kUêµW ï¢¼+¤©ùsú½(>»¶¸…!X€)á^Œu?íßG3”n"tu?^ñ8±bë›1¾edGIÃ%ïçÕ¬§Áb!Ê:HU¨:·±Ú ÛeXL!)ÔÅÀ®$=¼ÇúXd>e›3ËÂøŸŒFàxè„ûs¿h5ˆ#?{¤atM‘X½Œõ}™/ªzÿzBşã†2®ÂûsmsêÆRü¼qjÍÉ¢u³á8¾«ïŸ¢;4Qôm™´ªİsb×Ö¦Ó1á¼pŞ·ô?µˆ!hê(Çò¢cçFÅsÆ/“²y+B]Ó´tšô’Ş@tÂÊ†ıñİ¾0C–ÀªæÖş˜Áñiù‚»ì}Û?’™·"“Ÿ¶>hiN&¸s<œ9ÚFŞ”C‡Ö¾9+,v«z_3ÆZ{s›¹9İ’F¼Á»?€¬hCªşÉûÿÊO2€3ŠºgpK™cÌ5Š¼½;2oË âÅ‹M™I–Rüé{â?¤È1¨õ¡¨fA&°urEìî%“°Z’‰½MAG’tÙvÚè"_D_±~RÁÅ–aı«+\¿]ÅÔùèfÑÔ4Ìƒ‡³Ãc"dÿXrùvZ²uzV×£€Ñ7paiU]×ò¶èzÀÙ…Sæ¼Àrõ;O9ú£—ì=£ğAãkÅÍĞP‚4HSa-¦6¼hXÅ!«}F oö	Q;F¡[c>‚ï[¡"|gª#È¯w:Gwñ¢øˆ<¤&—dıÃz&»VÊĞ*Y¾ú¸_™c}BÓYÅ“ß&àøš¥£ûŞ›R»'Ás3§işœ˜s,h‘NĞeô\!íPC¯@P´_ò~J]sÙ×:AVû§_Ø#¶=V[ÛÇÂÜN„2ŠûÎõŞL9ÕÿØñä0»Ùï/ïK1D&¡‡CŞ	HÍÚåÈİ Şpªµ%Ê@m“ÖòŒv’¡µ×„¥_ºKs†ÑfB3áûe•‰Vİµ²_ÆÑT9ÃR}7é¹¾& àGù“‹ôõ.ÃµEÅëÌe¯"pqØw2ëw0i›uNÓdHJR[ıGCÛÈ€ÇĞı¡VeH®®)˜Â—6&WŸZæ¡]V–˜ÈYŸnp%ñVÊ‹eLÉáéeV~Kn †Yü1-ÔŞC¦Ó+WÜ Â¬5ªš2	ÃÕáşÔ¿DìwÃœ‰/â~UšıZPš2¶u‚n!1¦¹aµTôO^ãhLâ(˜®&Wb„ùxÏMÈVi]è ‚}›´}ôó—6etÿ.j•°Ş¡¦½–U©0?˜/ƒ“WtéM¥)ÿqXıkoû³%KšV—¿°œ/ùÆkª0ªöò¸<­rÚ*hkH	÷ÏËñ5Šg€l)Ñ	„óŠå£¿TÄÙ›étsôx”¹Ô‘;w`İùœ³(7ß7½kœµ²àÎ8²×êV·Së	‘ÍÙb¡³¤MøwR™ œSûY†¾Ûy'ìÆU°ZŸmìÀwÀaÅ¢Áó•Õe5JUYkHÌ¯0.¨Xq@éa1Æç¬g'‰cF
Vb¡Ï8ïÜO>šÃÓèó½ğò;áLË,ï£®¯})Aæ=cP”ÿ¢Zÿz¹¦ò÷=hKÒŞk"ñMÔR÷mñ˜7I.I×y_d¼‘ğ^…¥-ßú†µß¯^“£õ>*G{<RøıĞ¾¬’¼V¶y¤*à‚Xëkà®{
l}„N»ÇM‡#´ˆQÑîCšfĞs~rcMÆÛÒó
OÜ_rú¤SI,¶o¸®[„éşÙü³Á¨·ÃéİT/5_’aØÓ`}4Lè‰âP7øfòğw‚ÏÕ°l½§¿ƒ‘g}~RŸ@•} ›ª£}Ô!Tÿø’Xé1“Û,¾Ö2œ<;lg–èâño@Ü$-ÊŸ«{2ÂCÃ¸CAT[X-.ÓcÆxæÖã»Láà”BnøÄQï›L:ˆ ×ŸÌ€ë$¼1âl4–ñÔuœc‰k-ä.Zõƒ¯ØèùJî°€yéMpc˜r7\HAB€3]€°¢Æ' L§ê4_s£¸ãû$Ù}••3c=}9„Lû9-£[»Ÿ<°sØÇöå5z0Á(Uã… ‰D‹r²ÈçÇQ‡Ú>WJ”à>#@n›6_ ›%?&£>@ çN/Æÿ¶†ƒE9Ã˜QUí­G¼ş»yL®lÀàµŞîf¢ĞkU™X1Aù.Rè:(b<ä
0(gC±R_Q"‹Óƒ‚†³”Yy€Jšëésx_¢íÁOÕv=ÁVÛèvš¼R~Ì•]¹ÖÖÉ	ÅáÄ×E¼KÈMLD×µ-	V¤Ò†Pwş ÷E 8à¸_şä};_›Ìğ3‡|M¦øncOUpû@ü}G¶&=oû™aİÇüìV3èõ	JZë?©áílz¨Îàpê÷à=_€c=BÂzª‡(F)@ßÜùª¸×(À y•’ıomÀøY >ü*¼Œ)²õ9'”…ü(~10Eiè³“Eì!1ıáÕjW¥ßôŸõµµÍÙÅ¤´úo1w*è-Êëû1Â}>ä5²ã¡éã.˜Í¤Ç(™ºØü.Î­uş¶ww¹p×ÌWª×„Íº,ošHùWÊú~¯'äšÅÊ³Wõã?Wè¿üB7Şú´ÓÉctO#TÈÌ6ÂbÕ¦ZÂC|éRö¥gUÁ%í¿Lsd…LìşÈqÏ¨NSZS)×¾ÛSÖ¨‘HX]«TA0¶ª)ÓÔŒA.ù¥6_Ú@Û½¨¶ê3íyÀİa0ø­DùäLcú ²0“ÿƒ›1÷dæ
Óã,8Í ĞE]tµ¡X,1rù‘+[ıC!/Ü´Ç¡Ù*ò.êòŞGlº<2ÎÄ6zB=œÂµ1É¼sï«+q!„Ib{zĞK4ÒjWQÒ¿ê‹\U±‘5M)sôm&=N)ô(—¡Õ9É×rµ[jC’ffò:‹0ï"`®õãí|òÖşŸÚÓŒö×_-ÑX¶Há2´`1™…üUÌH^å‰Us‡©“Ég‰×Úã¼BË[‡Un¾ùØßÃë9ı3Ñ¬Ürä‰!–ü+jv‚Ü:<äa¼¦yùš›µpc"j ¨ÅÒËû´ÿO€ıŸÖÙQ©I'¶ú²Åí%&}Z©ÛE-M9]»SYT¯Ø4ª€DLÕp'€x6è‚fæ‰œ3¥8–²wÍ¦û–œåš‘j£Ø¢êM—'!’ÒBÅ;S«°s±[«éÎ¹;›@à€[èÁú eL¹å‹\R
ç„µ<#O+¦“0ç«`zØÙg™wÛZ5ÃYG()ìæ7œ(]SPùúÄ¨AL
·«ì³à`µäâ·G³”Äl«ü[-¸yÓC)7^‚%ç?ÔeFt3XñØ·šñŒ‘¿Aäİ„!Âa•\DSvÀ]à!¾^qÈE§˜ 2I8Ïæ°A«™Ò¸ 1âî>„
‘W©¢âÍÌ–7sNT 2ÏÈ.Wbÿƒ‘fïá]…+RU<Äs×‘¨Ef,+
Kw’D,ß
sätl[	é:ZŞÃmÇ÷hm½.Ù0u79Ø†å¦ajfÌ‡eÙT(¼Ë%g*«ö…×ò§„/ÈdO'ÚÇZ+ğ’H_&İrP?º–Í¹Œ@ÌCXYŒ·9ğîw3JØ"S,‘º WÚ²ŒŸ(ğ¥ÄËëd$¹dÙ5³ÕÆãÀiı+FW,(QÛ«“7Á›nrKn¼Ü&÷_uÒš\²(U…»nÊM¿Â bLíœO³âîi,
@d\aïß ‘fşüxqƒÏ;lû*vD Ş¥ü4+ mÒÌ&+ÔŒº¡Ï=ç~q7dÚ[3òÅ¹5Tq¾åœĞöŒuaŒL ö7Nµì=]SLñ·½¸×5İ@6'âA	VÃäİœ)ñè·Yuã…:Nìñ(Xdoµ§m;¯âG5ÉeR†ÈvÂ´P·_³ñ[šZ¬ˆ–ÀŠªŒ%¨í@6ÍŞÆ‰ìjÇİCVÒ)ïŸ7}“?„ó1š"#]Hã“|Ë\ôts5	Ddõ_Ø?ßç`Ò‘ícQAÓ*Ücê\|¨®c”­£c¾!OHÄv¹Q%+qd7Ù@ÙŒUB–}dZŞúk¼HW—"áó9—G¸éÕbïsÌ+Æ=ş MMl¼,ø¾×û¦Ø’¿XàŠD£)Åp?ıÆ‘³¿”Ü@°ğøxëˆ‚›¬“%uNå…ş‰ÑËİİ—ÿí/æÛÃ1úÍa×ïÍ¯wÍ)<cZ2¥Øwh3úøNÅ°}RÆ™'ıçÓf'yÜÛ†í“UñŠˆdnq_:Q½ìşM<Éöú“"(°NT-Ë{h?‡DLPŞN¿÷Ów»¸ê¶›A!İéÇıZÛiFŸŠPıÚû9À\`9˜É½¸à›ù%åú€Lì[a<6¶ĞT‹t>°µFÓyïâ©Äµà-®iş±½¸­ıŒœPk·ŒÏß&^ıV-ä¦lAJ–¢ŒW”Š6
Éd™üPsŒÃø³áæ˜e44]¹ôMBõN Ì5@L—Rxôëqç—TŞ!/®ÙVÑ!ı»_¦Z/š‡
ÎÑ)ÜYm†¶LY{˜>+†â<ÒÙ«#:±>Ğü´nm‹,ô²Ğ$ [éş3u³¡“2ôf›ÇïwNÃ«i”2uô:É]´>‚¿ …(Ôg›È¿İ¾-Ş—hy3¡D,bsëò«aêa'#/Ï;bõ"¿ú3¥"¹§Qé$ÒNÃ|Y<,¶·	S©H©z(Kô¨_p¶èw!hFÅRÙÙ•ıĞF³•ûàœ¨”¢!XÑÉuÂÇ}Ë!Êì1ÓU¥p¦DÍ1óÛfL["7üê$¬¿€IäVn!•Ø+ÆEû5A>jQí^ âá%-8I´|È>dÛ* Yµˆ´z¯„™u3Ó7÷¿y ‚ÆÕ|X-w\K9È—`OwØÙ‘ìuŠJ‚W…)ÂÍ¡WÒü7æí…Ç‚¯ËÜØ°xÜ*j+Ï<¾ø›³ÈÍpã°DEİùv†B‚Ñ"—1Ü¦áÀí§ìi&3ı©»Ù-=[­ÁU1Gü2BU\HuâæÁ²'zºYêëDt'NØu]—¾'ŞùÏ¹?£|C·QìËIR1Ş[§OS€-?&aÊ¢¬¥vâ/vJ˜¢–µš/ˆûÓˆÏ3‘fÚó¼ªT£²'|ôKö–é/ÒÛNëï]^E‚ß:ù£m¨L‹%ÅŞO›,èÀ­/J¸/™,»K4nÍk`1Æ4[Fæw-(øÓ®˜ŞH!I¸º¿×¥ØĞBP}±rÜ7áÊóË'f9åÄ#ÂõLh‡BV%Fçiâ¶qƒÚÊËx´Á(€<ğTã”(š÷ë7é8÷9Ş¢/Ñ¤
ÕqôÔ%ÿŒ®nç”+ßs¿ø™Ë¨ËâÕèQóİğÛ£VK%6ÕÊv´Z;†NeÄ]Zgˆÿ{İ¼Ç,ùÇJüXè»é¹î°äÓM	b%`¬şñ+FîeGlêXßb “Jİ°¿ÚH#½Ûƒr¼4Z*y„ş…ºÛ
MúR×ô[TMš‹sùu¿M[› ì¼—˜Ø%Mã¹ÜeMé´KwÀP*£’Åf=é“6ÅQ¸‚šN¡¾|{jwt2„Ø…måRi¼Ş9+K v2¼uN/#ÜbÒüØ¢=e¤úÀJ1²'ıØ«òğíÆÌNãAÊô“dl î´ÓğƒBŠjêx<=>§¥Ök·"ŠmÖÍ=·Ã´´ª-Ê$lĞo›Â™ih1=A1å§eÌè^î°Å0av-@|‰Ä¬šI:şÅV=âßØËîĞ%ˆê_ ó+öÖêpá~Üš^ ‘.:“n~sW&äıcÖ}N%ŞQ^oüÔlÎâõš9Æ„úÄŠdİú¦ˆZğÕƒ¦èİæà:¶_ÊK`ûñÉ=Rr&fö?ØæëHß¿ªÂ'VÖ`ÉÑ(>ÏÊ®¦¨–¼Ô¯×bĞj)ºŒM¡•å-6¦U+<‘>@W.Îeğ¼¬sê¥Ÿ­¯Ò`ê¢	™!9C®PvŒS#«E¹ŠÇÎı5Võ_¬iL³ ƒr‹şÈ±CU‡~Lë¼]K…d•?FºkÕÿÚ\¨·¯ÔKº©˜	f7ÅïÄ„7‹ıÄ¿ºH2‡^/Ø«×d#ÎÆ´ãp!YíçDlÙoz·X”j½z¥Ô3E†£
˜ØJfÂ²wj¤ßHC$ö¯°÷PÈë¸E5`&¾å¬Ä'¶¸õ½Ê]RğcIÄ‚I£üO1T–®Ò¦¿d.âvµMŸrò=²yËçoH_-3; ÷;ºL¼Ùd½êòb©¦PÓ1Ia¦f(#ş†ÕxaCÔhğw¹Ñ1Î%n#p˜7òšµƒoPòS]Ø"78jïÉ‡´Ã›¤²xš@ùÄeÒAMkˆê£·„^^L#èäFÎ˜Ç ØÁ”	iB:RÓ‡×ë}º©ê*_6Y×?C£¿(qîsÒ	_Àü¸„–ó)c<0«y±ÂRo¯&±2¼°N©Lìûãò|OÚE)R±¼ÍÏñôä\kkféÑeA•¤“ûS°S±QòÖP:ôÈ³&O¢PW·ÉàîCo>»Åê˜5ì	Ğø-Ù¾¦NØöısÕ=-NóY ö€ÀŞÂšä:!Ëûëïby§õxC¹ÄBÔŠ}G»¸<yû“Ã7oŸû
2Ãäã-o87WÇõt°¸®Ïsê±U^û6Œ¨råPhÔˆ&œ¿°Õ'úÜIER»C%5Lmƒ_} ïºo`ŞÛñĞ?Z&_¹¢xrX@¤‘ºé{Qgoˆc÷¹¸{}¯d«,Àºß	ı9¢ã°¤nÍ†"NAb¤ğm÷ã}«¡{Áa h,¼`0&{Q5 ã«Ï|N´P*R±VJZk>Lm[yH+¬Ü7 ¿cS8BÄ¦çùªqüÜ(¾nïñÄ]şœ|±TÇ‹Gõ?«Àecò¸E©NÎ!G¿B¤ Àî×b¡ãCî¼[Ê´s‰aoğ^£´MŒÌÑ‚1»¼«¸Ú<7Œ7Z-¹€!î÷]R¢è*^áw •"šÊ×ıRíaÈ±ÀõYƒ<<¿Ÿ×Œ±ÔŒ¤Õı.ßYo6ßó€ùæg+«´ûòO¨áJ±{GåÅ§q™öìæzá­TsèpÌ.KO¬°é"›‚Î9 ¨ÙË=ÿq¢Öv§S£F;Óòd¬h®A¾Ş;ªÕo- éô–cÅø'ƒKMm¶ë3ÿÂqşClïM™î’‚ñ˜'Qˆdƒ’JU1Ì073â‹#ÏmßETçl®GXwŠ¤}G‚²°Ò·#ÒŠ)7š„‹öJ«ŠÒÈã‚%ã±îñĞ"J×(oúbEıüãÜ±e‰-ŒÏ„FºQ‚ÚMí“¾8\'­¦Œ„qÅ´ƒ.—†L€£¹{‚š‚JÔ~k©T\Üôï·ÛG—*0¬û:§¨_c»ÓDòfjE{s°8‹ÉŒô‡*³ƒ¼Oz‡”£áe7qè„Y=¯A„²HÀFú°Ìú!–¹?¹&Ë„@Ò)¾RXM~±UUß_o}R—–À	F[o\•ÃÜ¯K+0O&¦ ñ%Ò%¬.uëëWLR›Ö65y=8,Í’ƒp1×nû,ˆ­Ó;«Üntİ*5ZU’Z$‹É‡Pù3_ƒU/tuäùŒ…ÿ4¶%}%&¯Úø×T¼ğ	Ôê²óİ˜_¤)şZ^C[²——DğRÁãıİ³R)×‹zk¢à;ÈRÔ[fª4Ámdy÷Z¦¾B`\˜ÎM	@€Ö®D\tÃO]ê3ˆ½»)ö!úh|ˆo
D×bE£°w¶ª2QEtG½«u‚®Âñ!_B‚¢8‡$•*äíÌ%æÕ°.oO=/.|I§c„„ÅÉeÌ#ÿ_xGş£F-Q@sq £±¶İß¾Š^í’À†tQ)–º¿ñ¿(}—%ê&Ç±µJf:P\Ww•Ã˜K‹¾»)
HBë¨ã‡ ë07È¿Bi_ÄSöÎŸã¿”“k>h?)¼ŠŸøÃE¹YRÂ’=u6R&_“¿·¿$,€daæ9Ğ.ç}·‘iJg@}À×!Dõº#Dc„ò7L/‘×u~3,uü»¬äîpNuKÎ’nUŸ£‰Ê! Ğ±)ïÆ½2Ù?2ºğ ´ÒUşÛéHğGŒ¼œ³k`\DIB ,=
7™]ÄæCñ`®Ì$¿¶_únaÎl I§=HU@õßœ-dxä"3ó¯ø.²½¦Q:üÖ2â²f$=ÆÇ»u6ò¿ŞÕfÑ¦VBĞ™î’Åæ²ºÃp|İz®Q6İçç~¾ÚÖÏà‚»åúfœv÷: pJ­Y9ÜDhY¶æ(~i×CÏ/mrj SGdı¿àÅ¦gÁî½¢´àÆX-“¡úYİÊ„ËÈ§?l–W;Ç«MÓÚ^­Æµ¥ûZ  @N./45(¯ËP]è†B–O)6Sâå>ö•`W—yiĞOœà¢%ê¯a©hğ…ßQöÀŒcÎwÒ¢ûĞ‘œ!óà°µ€”‚F%;O“B+oîMğØ“¿¥oE¥¸6úÌ`¹ÇíXŒzòùØ×bÕâMéÜ¡k…ˆjâˆdm¦isáğ®»G{õ™±QMcxß•ÅR¦BPsù!—Vn3lÄcœ4Óu&;VÂ@åÄÒ’0Sy¬º?Àw1” Óq´}’äÏ(‡z[>t<$!…Ë|ÏIB¤DBüÄeñ©ŒX5ñÈ×S‰± «š™ê›÷hÀ.‰÷Û$ÂSXöÊòˆbLÜCV>xÖaLÔ-.ô­øDwUÛOË½LB‚] 2ÒfØìéz4 K¤›äg“<— 9?¯ÅdèL›3i"ø£Í—Ğª¢t
ª	‹7ÑxX†\ÃÆƒÀ›¦•CiE¥}nÆ)Éœ6‚_ZZ àÓhú½íauäg”Çawx³{/º9‹©QÆã‰ô\õá’bş—¿”¥›Ë~êüğ3²h‘;ÊV¸§‰ÿxdù¬«Ás)N®¢p³Õò'79
ùä¹<qİaL{ÒàZ$PDI¤´0b”AUSˆÒ`od±¾{{ƒ&z5Z|Y±¬T)bÉ‹m;«–èÜŒh)„ÂÌÀ>b*Şi¿™I«MörL(™  Ã›†  hÍ4ü™ùŞ%ö<Qm`õ¶§ |êvÄ¼·C!ÇÅU2±†ıŸÑ™ˆ&òHÏ„@¿H{BÕÕ‚<¸íš¡Ò]HTšÔëW³Ñ%Æ83œæ#¦¡V¹®nQòíŞÒÖÄ¯¥SäõÓ¡®ôdõ{ªPº{=2ÓÈíÁĞ§ìCG@é4²°&&PÿİÜudió&¬2&¸™¤»Ş¢Ä§<£K¡Tw!^G`z¥ÚÁ˜¾	|§³wˆ/ÿC=‚‚&PN–‘>ÇQ*&î¿Äır%r€à”/Ï^6ÀO]×‚u˜ÿÑdyä3†A*²çÁQˆµ|£F¥èqˆÚõÎ?ˆÛÌy¥o”êqÑï
³@[PTëÓÆ jÅ&–®qJâîwUÚ–@é°‚&Qş°± $Ã#â={~.Hd~3O[SßmS§ÿôEvY¸Í·¥ó¼¹n•Nf¹“~“&İÆ›æRà¤G¹—[»GqÎjãI!‹pÕQ¸c½^ÜQÅrµ+s×»"&š/Y‰÷El°-ª©ÃÁ«Ô`3gÛ•CùP6@2	fÁWzµ­ÔŒ¤°ØÖöZšM§-@ù@sòÎúBöLÅ:”íh"r1¸…Ó~+—º¨ú…ôxrÎ…“ª¦¬By™Ü8ú·Nç0ñdœE÷w-r
U E’õ!¨ë%…JRğ ·²Ğ)j-«‚-ü]+şy¢P©Ö½ÎEw!·×+Œ6¤²
”’ı9tF9¼>1¹²qçK"é#Êá²ÁOŒ_NŠ¯ù¢ìÃ¿ãUtİßiæVÕ^gùÃ'Í/bß}°õƒO;•r¾àşQîÃÆŸ$´ŸÒ›kÑ,PŞ“Ôú†CÀ&rl’¨¾dˆÃÆóòäˆu"¶¬}˜éÀBÃ^ãW'ÒkE‰¶¨İ6¥ä1‘Ë¡4”°Ş½³ŞI;ŒR»'¢0cPtíŠ#	šT8Z=ÛğÎü>N¹Å.”Ã´‰x¶6ü]øëÎQfÉøó©XÌI&+´´kŠ¨»DñKêxïd¢JB‡\c:çõö•‡èV±ıÁVéåŸ«©¦Å/¡óše’‚|˜TLaCâ	‹ëw&=(ÍT1%ü ĞLMÛ«d˜ÚC?ş ÇT¹¼¿Õñ¹«~y\9cØÃHİÏÓ‚¨!ş'7§İ¬G\Û.ïN‡ÖVÏ˜:8p¹„-|m^ìõon²ËGU|«4‹aiªã+T‡ÃØXì<P2èèÏ‘§*A¹M³™€MğÎO×é  ¾Ÿ<xy{èÌWà
%Ie”fH®uÑÑ5ìĞŒ¬\QŸŠš£3Æ†«\-0¯f†é~b÷GõjNHZu3Ñúƒ´è•²še€óEÉJš_şç@uã$ù H¼š“\}o¿ı±€,7ôe"Ú@­Üö:‡Nò±Şï>óãÚ¢ùĞ³CÂˆ7¡“4·ô@åé4*01í[‹Œl¬Õ¿ q_.k ¸*“	 ¢
–dL
}lù»`
ÓjÆ~ †¹%o3)|0_¹Ò4AÄu— h”®MÏƒàü´U…¢Âˆ¢x°Ø
ÈLğíÏ{Xu ¢”åëwİN›ñ™´}-Gö7”(“®Ê~½Ä4uıÁ’^•Ÿ¬Ü²N$5×Ldèv×ÂØ¤œt/fMöq Ò°yÔ¤È“r%!šƒ*ô¯ôËï¡ÈH+–½Râ8"y lØ›ÅÚ— ¥âùhoH¬ÿ¯}€µCR%®õ¸ë­g>xG|’YÚĞ$Z)¢vEÍ>Ø§ScŸÇÉ,Ğ0Ë£HåûÉ'cäà!/º©F¿"¬“ŒY2g	(ˆç4 ¡Ğ¢z•M²>wÏ“3¾Œ–0­#Ç­9DºN­ ñús#«pñ®,üÛ	„ôORü|Iğ?ı,IÕ·`["‰[¤x2‰e“¨-(+h¬mã1\ŞKÆ²ò•5™[§9}4q'$/PÙ=8¹7m’-•ÍÈJurŠë~°§#«*}V¡fIÊ]‰°‚V2ã‚ïÇğÀˆ‹QÊÜŒU%ªWºqÉ®Šynhk˜\4˜Ş™éŒTÕáosŸeõÑòh2=o÷ÚéN  Yì¨<‹8Ñ‘(ƒ{~—E „İå<j?+&ş$¨lêh5gİ^rv›ZWZ!œÂ„1l B4 q$oœû ¾‚Ú|¡|X@]Èù5³SoÇh‘å¡Ô	üg¬÷²ö(¨/!îAF+p‰nŸöáøgÕ YÜ+°¬#¤5²‚¯Xš@!¡¨dCïGğÕe]ï·ô} ¹ibˆ¿pjÓa,mş²l¨[$²×.)%ÅÌèáÙeÅ“Óïòq“¸‚ñğ÷ãò†2wÚ‘»€;t¤İ¨vr£Ğ:—2¼”>ºbJ c^ñ~Â5!š)ö80·{7‡Š+1›I"~	µ	ˆåîBNÏTÖÿQàÇŸû c/ªL)ëIZItÑê¾/8!şÕØ4Tò¯ëJÎK; ZLmüpõBßÈŠZ×9³™}î'®Ê3úò¦T4wã5\wF÷xŸ†‚,Ó	Î“zët»‚Éu©[M 1Ÿ¥@ÌÕ³¯v†|è\nwÍ'š“ß’3™$qø÷L"F(\Õ€j=©…Å3vü};¿Ç
XXˆÅRÑk%Ò1H	8ÏvmàèºÇ§z¨ÕûÌóCŒáÚÒ$#q˜bØİ£µgØÓÄ86
A±«\ÜŸñÒøvˆ(Õ0ê„HEûWò'O?Éoş7´R¶C0lÊéfËnw‘@RóÊ–öT€÷O€)¥üÙ{x-;‹<Uõ#ç¸şÎÿ‰y§ù€c†2›ùª#zÆF‡6îÔ6şG\%õ!š–Øxïg–Ãt¶0ÿº@”ŠÜrD'ğÔ®¯6E*·œœRÍEyµjû\'˜¶ŠáÎÒ…zc§«tÙUÖÙ0Æ¡å©¹)|âUxºINĞŸHã|÷…U§È£g…Ş™jm™¢][’Îôåp#3º“`˜ÙW­¶×…A[Ğ0³Äs÷õêÍV—š±Äû×­3ş´Ñ·
1ğñ(_Ts»ù.§„fÂóñ)ğgH…VDæÇ.†&6DcƒŠ½Ø“™Õå'Ãê8±åKˆt×Ãë3.ì"ôÁÖo–_ö`’Ù%ñ02ğ»3G8œœÿ„åo,eÔËSù·*¢Ğ‘––çAí
‡”ÊŠÕŠê–-©gi¨7‡[úÓ¥[hÁ7å‹}ÃáfîcâhšÄ¤”+N‰\Éå¼M°d	rdP5DÂİ Ì8|İ8¬ÊØ’XÃuå
v•‚AšÆ¤Ó›Öñ¯K€YEüû'´½séy›`D´¯›Ğ:ÁñÄ¥ò¦˜-­j’éÍµÃİaHMÓOÕué‰éÏĞ}Çõ Vß„è˜À‡r‘i‹èüTJÎS@0.˜ÛSt{ï½ûûä&ö$ÇUPj GÏ†LêÉ1tàG¡Tô!¡*Œ¹IY€Ÿ˜d,!‘û*—Û[`®IÉË&v‹¢!ÓšRùú¡}|†Øš[eÈ±“’ÂtBçÓÔÁˆãr+ÜÙªÃÎ±[+c9£&?¶\flB…(“·B&h™§¯¯Ø£!è,i=©©	W@³Íb‡v¥WéİbShŒğ’Y…ŠfíñÇp²¢êhªT¼T*Ë?	0¬3-n”MpŞõü	.Õş?óÎõW£µ8U ± ­Fyµ$Î'!e€¡-Çõ‚êÊî.³¹”—ëï‰Sq51æEÜLQq[÷W‰°8è¦l!ÆÂ{C¨½ Y§8ÙaqÅ¡è^|&¿uzÀ¹QU˜£&aÇæè ØåA
‘ª›ïOø®G½¾P³Œ•RÌØïatî}ïTb^Çş0’ªÇÒ™Y‚éšaëL²ù†Û`oh`GéÑ?bÌ¡C±Ê

İ­â1"sŒRrœHœ.âÁzí)á\
Ú7¹z¤+çu?ñÙÿ—Ç:^Ä7‹Ô©úìŸĞÇ#·¤X½Cë¾ßÆ´¿oş^ôİøøFé·Öt<ƒ91€r£B>x™©3 mGpõ%tyªàİÇÖ2:j®J‹âÀËÖÈM{‚Ín›ãŠçhÚ ÿá‹648¹U{3ç-âÃ;E\Ğ"oìgä‡ô|!ù(
±E5O~¾5ïD–>¢^Ÿë	Áû‰5á7âµ,_'«àæò›IÌw&µ9Cq"˜?ËRó¾J&Æ ¿z©–D6ğQµO‡½Ro^°¢çb,@<^€f†j6=F'‘ú‰êÔ†3†w+,Ú<ÊBœß$W¢Ü]vNBÒn1Ó<ÆÛœÂ¢İ>æ\oZÖ^K–ÀÑøĞ¤ÆĞï{s»ü%¢VËü%Q¯S¤¢!3ÿ€ß#ñ:'û€ÉÊ…qB¤JÏÁğåÛA}¿B–J¢‰¬±L?Å<Õ®î² è„f/5ïøğd¢ê§|ds°Î{ƒÛKº±“ƒcÁ?@²!¬iÿ<ÛmøÃ’kÌĞä.ú²t D•{Qñßû…p™©ŒÂóTííE_Ù[AÈZyÏgß ‘Hä¨½Y€E%S Œgt	›|·İt—lƒÔE–"ìí‡v7G†¯˜õóå £•À‰ù\51M}²=okG°G—áO%‡µç"şõû•`ôˆøÎÓÉBæ™— sæ´b/ıÏó
sz$ŞáªO¡«ÎKÔeoDï Ê7ÂKK ‘¥ğÂó•P‡GÔÒaÇ¾®•ÿÌmA”Nÿ“›ù5a{Åëj	@VÈÈÕ$ÖwºŸ …\X±¡ª®®o¶º"üÚÇE™a¯0?àĞXïà\·áµ·¼|\ú„Ög¤úÕ$
ŠJ³»´jz¼¶`¿æ ËI-Bfl(;cÏÿãŞµÄ$mÁ¤ç±š î·qiúÆ`y;2ô<v<¥‰ïZ±‘ñR>¡=Í³.X’e&RçÖZuåÌCÀW-9d›%.® ñ4½M‘u]s£µ(‚©$ÛâiÿëtgÒic"K3à)ököé20„ëqÓ)!ŞcÆœ_SL·İ)&t[„­7¨O~lj^ÚF·L˜'=ìÆf¬·§o­»öñ¸²®wïe9\ækÜ„ƒµ[ûíğ4²rI@àöy’şó¢½Qş¸-æñ÷
;Z’rbJÇ‡HºkMßP¬´Æòò§àP`ş#P§I1jN6æYÍá¾ËóŞaP<®;H“ÎÁ„|I6~î%güùÇÎ‡–Ù‡g…sûšGÉ¾]8Lm“ø$D ûÁkKóĞi éf+êzfğ
×9ñâh’\ŠMO	fµäb9Œ?ÄÎÒÎî?šıg*xÔŠø¸O‘cÚı<”rØÜ(ÚÖ6t* ÊurŞ#*ØBJÎÑ·ŠÉ¤ÆÉIíñO[ˆÃ˜¾Õ‡lÏ%­¬fšÍ‘Im'Üœ±ù5x*Ä~è5™Ï#j¹¼İ‰év„)z–¼G¡,ìü·stÜT _ü7ÈØxg¤»zÑäX¬›)yZñìÑdÛ³t†ZTÆãğézİ\Z:ö~©ó8Æß?§OxÆéie…2·CÍ´4TîÕW‹ÑG£q“ ŞU@²B¦ášAÉµ¸_9ˆ½^Ú°'èˆæn°ly2*CôçÂÔú%êÇÊ](ø6—áW“Á÷}®>Œt3Ä9PHÆUºOå¥k/i1³úï„xh4öş«\=¾Øwåæ¤,¯şóAÖr»d¬Q™}·V9yæ¥±³âˆ)3ÀñS	Äº‹ß
’ak^’ut‡ÂlPWÙI4³RSjí¿Ö”#8±C­Œ¹r,Ø³í9`Ãé32¤¿×H®®*Óæõ(Ò]•¤Í *³_“1-ˆà¹'µ_´˜#2†_»û÷¸¼¸è]õ…®YİãN‚RİK›‘%èbx m»wÍ:á­Å¹p Ôú3À°+R2¿0BÛÊØÚNœô
ıR®¢~ß¤œèÑF²šı“~êAWwĞªŒs²ùÅºlW,oK(ßİ‡TŸ6¼àNfÉ3ºë%JüÎ%RÅ(úy¢4)ø¡KªëtçŒëo¼c£««­¾ÓÆ=oPw}‚]‚eòPK‰V—°P_f¿d*¶H
V]Jı;.œdÆ_‰ Bzü+79&4²üúˆ>7·ó{™Jô" |DƒiL»i!¢àl4N˜a®Ÿy/LÃĞaÜ„r§æ2½™ôŠ¹¥$TÒrV\¬Ñƒ%ú!4Ù	ëÜÉ4u¤áŒ@Ö;üŠÁOü(3ş!îÌÕ‹cwfVÍ™ó–'8:ÊÔ	…†KÚ÷ğ˜–ˆ„T_w£‹fMzTİ¼šbf6Y4¹‚SF‹²şø¯aÛ(D®FvVÈ¼O”ó3±»ÔG÷;É.:’ş#——tXÌÎ2cmPÇÅï\c\Å®Ò¨|nm{a
“I~¸UKÔEäCğÕM‰ù* MlXÎ†Boó’I»šnKVÎ£§;/xBùŠhººÄ¤æÎä5aVoA©cG¶°wUÁ<¢›Ğ¥.%ï‡¥©¬YIaŞoÓyùZÌ{=yÔfØÈ·!Çvd¾úä˜~­µmùAÙ 9\áz»=|>;®®Z*Bm'ƒºŠ"ü	X’(yVš@8H‰Ò”º í“;e¢Ë3*6hH/ÓÔÕª{÷ƒ’¢>î(Åå:oÎnYeS¹cÜ_/Ò·€˜ÆçîTwˆsVÁâÔªM?:µLõ3ì)C~Å‹ô	;‚¹T¬ŒA)8œô4e1>‘ ±"
'¬»2²N“pv8
©êEEYÁoÛdáæ“pßw§eP’§Ê‹°ŠPÇåù½¸Øá¸ò¹ªn P'OÊx{?W2=¡mó@aEò(Ge³h{íXÅ‰b œî1×¼`Á	|»ë'LßïÓ÷Z>|Á\¯ş”	1³+;kÍO1&Š·iÜ¯!1b?!–”cÍQ¹İuæ`z¨Ñ©¼Ñ«#?{ñá! llÊöÔl/)HºÕ#6íáRnOËâuÌ÷†@FÆóÈ¡‰Lö0çÑ"Yµ¾À.å!¯
œ 8–RH):'+ÚØ?¢Á9²«ÑÃe%9E'èå6ŸÏ‹5ŸnI¶Ê§Í2³>pøêÀÑÆKÁ]´N!T'#û4‚ã ®˜”åù¦ñ¡Åğ:hŠÕì…Uh¿®±;ÜôÌ›nŠa Õ~Hä’¿Ê…ğ3á¡$IË*ËRœßÏ5±»†ß™¸in™ÕÒxaÃï=-MüĞÊÀ“$œª³ğË€ÍÒ‘ê ù2Wu¾>ÕZ»í£q,V]úœÂšÑÿßiŒzZ„Ç|%'TQ‹å¶Çµv´}Œ.Í_–´ƒá6@"Y]DHÌzâÇt©äºEb’¸ E. $÷¦IşH¬Vë€J\Ş"_°[£2NÂˆf_&œ³Ts‹vßèBæ_¶ñf³™z-Õ¬Íˆ{9¢˜}0Dhg¨©dÑ•á„IRHÜÎ;ÊærçùêRŒ^QŠÑåºl$Yõ÷¾‡9ùVZ/]òƒºoŞïU/û–eØ€¦İ…áÓ.ÚX Ã+¥Qhî¥H¬®ˆ·7"©ı!C«óPÈú$0UË|U™]šèAtíğÛH!kœ‚äa;-X]y>ÒN9¾—zÀZ%IŠ2\®eÑş—BÊ‘ˆ6!I¦—DAÉê§å¹Ñù¾ÓÜ< óœP¿¶Ì3(…
Œ™sx«»Y–ŸLÍÒ$iŸéùÓN[ecÊ%2AÈ•—Öhq©iÄV¤nˆÒÍÊÇJ!ÁR3›-ÚÕÄˆS‡œñ¢O™nµ#l£!Ó¨½şğ‹bPªDÍ‹¸q†aäŸ™Eq·‚#Ù3šS ˜„Lş†Á‹íRé6’‡òÉeäûcÛaÁÕ'7!A*ü’xb-g‚i<9s¢éxâß¦ó9-ø
Ø¯)ûÒÑn_X¤.`êÂ¢¸¤˜¢TDA²"tœ YNÍ¬À‚ôlMœ6QP<P@—ªÓĞ€ÇÇjÀ¤İaaÁú¹x"wÜ“©²×‘÷fäùÆVp]¯ŒÛ`¥2~£¦*[¤år¼´‡#²P3ÀÈ”©Xš{7D#!ğ£ˆ§ğğsøQ§iäœÛ¬¦qš¸€9gÄûëD{™
¾ÆD€ö~É¬‘×\ÄyÊD‹}wrßJV&ß`/ØÁ_‡’ĞşCœĞo÷¾$–‘¿ÃIvät§øÓ¥ÚbÄ3’7Š‘Óo²
wDcSVœÀ¡‘7&¿;hn¹öD6²ïf§(·<"e
-*ò°|‡ÙJ_NÓèï0y¯æ‰tÚh%34[Šªªãå¦õE{9ºüØäbi%k%¸2zÙïn–iè	ó7tË¿[4 Á;=CgÓ&Øˆ´·Xu¼­½½cµ9şöÕ„´úT@×ÚIx¬¶j—3¥ºZİ±èNMãé?¡j(öÿ£)ô·v?¤€K”>GìæÅÏn™àÉºÎ‡ƒ—´‘Æ
”V°Ò›ÿ2‹—)ã÷0G>fÁFÓïä3ºğâ9	×í¬8ğrÈ¥ã-è±ä/ƒ:KâŒ@½‹&6-µ­suöŒn—3» }]²jRGhâx<n¦†µfÒÄáælö?ÄfZıÂÀR³(3ñê¨+æ«Bf‚Yë¸şÖËoÂjë»ù—Z8Pg¹Ü9ö†@æ•2?|b‘>>…,ÕÙ;—ï9T}ËÅˆZ?@¦b¦+n-F™	§µâŞú£mïEœ0ºn ~!ã®ÍèC„Vq¯0–Ô™*MX®Ì¡òÌpÃ™İ:Æ#tC”È‹V­rÁ„¯ÆP×°‚¥ıÍ£Y€UêÆ¾¡ŞºèÒàjØ@Î\ñº3¥8TXÓ,©CU<¸úó‡œŞ˜Î[‘½”6g5Ò5`ï˜À­³­c İ·ûıƒäd#N¨$•µÛÚ¼Ç
1j$Q·‚±YG-Q%–mRRÕ~€?]¬Í4dH‡½Jv‰ÚŠz]‡v$¿x±°HèÓn3Âkœë„@ã¿9†ŠÌøÂÛ•Â+ÕÙFp_|HÂà€œo4&tpêmV^hÇ?h=‰ß­_RëÔÀİnA3U=äµµR%Q#n¥+­„‹Ôó{OÜã	ØüŞqİ€˜ÚrÉ{”Ö„>cÓP‰€|•â’¯0-xÚN&äçŞÓ,%İ2·ËíœaHa‘@i!Ü£°¯Ôâ|„	¦4zèöBjlMZmÖ;ÉtG‘9ÒJîÀ1¶KØ0ËŞR&‰£MŸ!ñ=œW=.`V)±ãD“Ö{yv„y%’·§)£æúˆõ)bÜNXîPUó¢Î¹Â ûÏçÄù>TÙãü/~ÕÓ›!*_‰T*ø³9 3N=ôÍ£	E‰jˆ7°S3_ĞşcÌB4ŸÜ­ã$bßZ¯şVrXrbrĞ…„™<úÃw P _
¿6s4»QÁŞeGæQ>k2¸:wSÍrâRä¡ÏÈÙÑO`<0aĞÄ°ÑÂŒî5}Hˆ”/@Ù\Û™yfIÙl×8`‹°ê,–‹!ìÄxò'EìÃõX-@Û~qËìÑS
åÖÖ{X÷Ñ:Ë×¥è­Z=eÂ ¼‡c,”AÌr	À¶…Å1CXGh©à5FË€8#‘êìm· æIã¶‘ş³zL:ä<8Ó¥v5×ëSÚ\Œ<N  V^ÜÅÑs£ÖôÔV¥šL]ˆÂ¥ıcou++#€V–3)-qÃÈûµ@mb1g
û\4¨¤ÂØ<Æ–É±y%êo…î£¾ÀWcÀ^÷üBˆ†ãß¿#j;ÚsêqóõN¡z,ÿ;`ôÀ$Ïr¼¼Ù]Êw„v”CÀOdç’ê-Àj
Ïr?ˆÄ¶SŞ=v8VÖ¨èÖïXã…>3ğëªg§»fb+bÿãø:ûSÒqJŸÂ«Š	,¯`ÔAcq5°¬2wâkTÂ0 ‰9‹²µ°Ä3Myş²^+—İ®%ª}1‚Q÷ê,“­[¡·¨²•õª¯×‹Ê24P†¯ØÅæL$£7‡\Öõ!E£öáÕ•|yÑ tƒ¾pùÖ<ñ¡-Ê<ñgŠØº)¼©	\%©ÒgæÃKY¦ìºmn®Äk5îuô€‰¹›@•—³0IghíÁTÙÄ™õXV¿Èú»_ø!Û- ®ğ(ı¶ïYù¨T˜AFD¬7Ø:H0	ûÆf¬AFÕ«À$HiN’ ÷ƒ(ÁÖ¥­‚¤nèo—{Ü/½DÑ³§–¸|PÛ¿78ñ˜úÆš`E~	Qaˆ˜I¢qûçØ1«±œbeÿÜƒ¶UàT=€¥3 ›Œ{·Œµc±JÂ¦A½ùL×d¿>€³WŒû=ª´
REQ\öt²ŸPÜ¬_töPJ¼ »¨‹n–Ih-Çg×á/´¡}"FÏÇ‘s=Å5gŸ»”ààZ¥,MKy	]z*#=i-D“ì7šäÇª)" ù
fPøéÈj(§¸KÇ‹ŞÎ`äyK±Î±ûj–ØÃ™%hëUXÖk~i$*< ¿9ŸFrãNM¹&±{:î¶}£¥¦×ŸiW7p¿§ˆÃØ¶†B:½#º'/}á†ğ`äğ«€§êÑç‡ôÃÉö‹â•¦xQÍ—ìTUñå3ÜĞ–4]và¯œ¨ú‘´£Øİl¹›5şŠ«é‹îÄèß¸2ƒlƒ«‘®y+Ù‡?$TòmÔ¼Ì5ÂÛĞgı‡£$2†jb¨}ÓA¥h‡ÌÖÜ»”%ı;c
‹/µ½‚À«!˜"üªl±6íáZ%vä“1põ>6ˆ‹+¨Eä®9&±¿)í`NÄĞm’	R)Ê€¥ü¼$ÏƒÄ4uro«ø	¶=ÒÑ>åkk9<ş#*( ÖÃQµğ9	äî©š5',‡‡òü¯˜¿§æ®6ÂN–¢áÓú¬4"Fş2”As¥ÃMÆ ½¸êZVû¤½ÏxÊøOòàùTÁ*ÆgÁ²‡Õáí·İN;±Z`3´ÏbÎT$†ü¿<·€G'ŞÄÈï5\g/gU¹ Œ‹P¨~. 'çüß“á}NM|?)`D’&°Ö	b›Ôwö&æĞÄŒñl«”ú§:4I!^9‡ Š¬4©„é”²SM»§ĞÔ€	`gÊ\¥kuéñ¹äN®KÆ(%MôU½9<q¼Çô¤e‡:[ÿÑwMÌ±ªİE³Ö ûË U¿ù§CÆÈ/¨AŠ’zöÔÏ> j¿DI¼fø›í7×>¶Lÿñ:çşù«¥„!Åx˜íµ=¤r0šØÎ‰™bk—/ù–ÖêTL'¬FšÿÆF­\ùC^M_º‘A5F_>¾`Û"l‰>-˜Á}ä~èÒ%HŸÎbõøæ{ï¾7×¦–àZÆh­ZWè{›8½X²Ô:$2s1…bƒ˜¶÷w˜ï DÂÆl‚²Nnº˜n LZîPÿ ¼v5Œ
¹œÓä¥n¦ÎºIÿßEš !ãÌlû7C*dPR‘7íú;ß{Å+‘G #¹»­T°É#(òY%zÔëhuòçuuP¤>¤îÌX±gúĞü­`2 ){<e:ıM,²m¨§µ KyP_ô/U¡ÖeœŸK$…4@r~öhe!$½¦(¸W¶Wo´v{·8Lu‘$ÊM ş¤]Êµ¸ÀÁ¨šÚşª]d|ek£<ƒx1ğE(¦?È£Ë'µ—ê¬~›1ÊñíİzÎĞ­ qnøìõ(^œ|‚³ŠfåÖë"‹•!|¿*µxëşjNóchØ7ú¦ë,D~?Ö£ô˜âØ=gÑ¬Sa3ì` P‰¾xnß8Ãåv•@­Lv˜.¦pô;­‘„vëºv.Ş¡Œ¸­8˜ÖÆ2:»ûUŒ¿“oóaªŒ,K›_•Ü>õ:|º¹„?ÓYÒfÅ¡:¥¥¦s²¶Ö¦Yı<nÀQt®MP¤”ÔëS¡ıR°\ã¿/6×©õÈ=ÅJeÑZ…7ZbÂ+1cñÚ’‡  "ÀdıÄRÃ¤BêÛoDg•İ…¯49 †«®æÍ¹¨Íğ™™T m9È«[	aÎP¨pC~Ò1|æ-…ìâñÙ»ô<¬=9|<—s_?•¶›İ‘¦­¶¨…8¯óâo9¡oFIö_	ÈªÒ¾c+Ş˜SDy+#}¤î@™Eí{A Ì¼yEw£@Š!N+NY„ÁÜcj,q‘ßzS›KQOÇ™KŞÃğîËÉÁüb‰¬ˆ¦Æ“×tĞ³Ü ‰¹]ºévëp’Æ‰É7=Ñ¬D€í¡¶ İÕ)h"ÄÍl·¯y50Ñ§Ô°®ƒ›SÇj×)â.„›ÍF!÷Ål%¤ÊWN…$%#+‡éJ;XCaâ©FÇX2n……8K[JºC+ã¦ßÍÁ#]ŞiüÊLëûñˆ‡0U)—ª1ãåªÈşº8Ó–°3Øi¿,É_gÚD`İ-“^èÊ„Ä±­w®&–ßßÔ-¤D1.~0bº²v´ÈîÕzf½ÀW¦®ÛîE°ÛÌŒ_|}dòÙ0­Ì·/£]K+5Q1Š‰˜£¯óïÄâ¡B¦Mu¹¶Oız1zØÈÇáİ]ËÌè&¹a¡ˆdVÉ,ÑtB4o3Û¿kbh¨À.	†Õ¦Ó'X ´Šb<ßk-Éqv¡ş)é=” ÿO1Í)²uÜõ™ƒÌÔ¹´–óŸüÅÈ®¡Q ©îtº‰ÄDqëôG¸^Æ‡ê‹ÊĞ |*}¬Ô6²ƒÿv™šufÔ/õñDúhÔ¥ö|øVÖG^ÚƒlØ¹yÒ=yÌ·yD…«
zæ2KWÃ€J)JõOÛ¢3¸¸ò‰ÿÿõ nÍ®ëÅyDo_ŸËU—%É‰Úì–‹Ã¿‡*êkÍ„%jX;Ê‘}6¥ª¦E¯’	ˆS7ŸÛÜÎ}ªK¬˜€	yÛ¥g.$RšqÉ«¬}±æ¢ß_'ÃşÚ@·³°ËV‰§xólÃQ<Ã¹ÇH"®:Vi„*K˜äs7×ú8 o“Aºj«{ Z;ilºg”DİJ^œ'õaÖ™-).«Àp?ğØ©œ€Èe€ˆRçÜUiØ¸¢ùÿvÇ@ùXµã¯ıîQE¬0|ÀYÀşÉ*³èUş&¹ÈDÙf“àÅĞD^¦	„øÀÒ~Wëİ^_ğêMé†&-Yn.à³d2bMµwÕÖîb¤tP™T‚šÍ/~ÿùH§”9çß-·¶ÊR+7Ñøv§»ä—§3m”cêß-O›¤¯éÄ_!=Ê’ç˜ñ7ëlT5ú–|½Áéƒ¤ƒÎç.2¸¤•Õƒ;¾hÅ~ŠŒeU+ÕK	w§â¢     Çó‰„Ÿhë İÏ€ëÚ£ ±Ägû    YZ