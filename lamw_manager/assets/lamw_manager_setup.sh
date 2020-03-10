#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2321118850"
MD5="49728e1ed45caccee100b8278642c4d0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20736"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Mon Mar  9 21:10:08 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿP¿] ¼}•ÀJFœÄÿ.»á_j©*Ë¼¾hš+F¨
VE|67RÜè‡!F‚Å“Ş×„2¥İÛkárå5Zœgúìí'	N£ÆO³P&P–Írz€ÏÊ×ß!@Vl÷f×ÚÓÌ¬yö6şÌdà	@øgïÖ1 ùº aÎ`9kmXó$Î å€«øçˆ[‰w=ÊGÅÃC™¶¼¬Xs_¶¾‘+}q¤Û©L|AzY£{Ùá//GŒÁE•:-¥qìcÅ Ô´9Z×ø®×DD£…{ÇÖö*G›«Â­¤Õ_#KOiĞ1¥`h²Kï$
£áu(.²'›ÉÍ­ÊÅN6]v‘#÷‡æœÚ«‹VuâÉ©£6‰n2b¤‚ ¦¯ÿKàDaü³ã]_8DIáöû8ÜÀ%–Å‰
ö|?Eÿu~Mª Üt¾eQ?²Ön$û-‚Ê‡ú<'½£®aY149³l»ËÈ±Â”¸p^®m8Br½$‰L4ˆŞ[×!¾5´ñ^·Po­ìÔ.ùı”Ft‘vyĞšUylbi±É‘"Ñ~ãKP­m¤X /ÜK¦j@ahM¦XS”.à´ {â |ºŞ¹Áöhpu—ô“	H«G˜ ºÓ@¥]—5şRÈFü”ˆ›ñÀwĞ´¦…ÊÏYÏ±<CÈ "ßjK7Nfé’¨râùnŠú~Ä¿véĞö}­_‰Ò2•>÷ƒt>¼S-ì’í¿×‘l¢ì‰lïf×$;^Mfo2³)aZoó©LjoQÉ¬( xÇ×D‰\àÒ,ñóÈx³bB¸»~Aş£Öğú}¸ãÔG½q`„ÑHw"Jß©<ª;P|úò´ršÎ£×±EáôûJ†Q÷7j)Ñ‡½´kD_Õp€rÓ­&0¸ˆGcxp‚x´5Ô~RèÂCQÙñ#LùC>¹¼†•”S¾`ùoÇÖ¸?Ÿ7æ¢¹`âÚ<è+kØÿ_0<Ï'Û	Íz'Éıí{¸WÖ_ZÍÂ1]a&Çh$:¤™Iò‡Íµ;‘Õ4s:¹¼›|P"âñ¦A½Ó Æ™5Ë`ÅÇ¬®w‘îÖëEÅ+¤ªÿ_2Åî?>6\ò°m	Êİ¬¥ÇùE[Ç‘ShµÖ¹Bç‹\Ø…Ú&Í*R²Õpµ×çL—Àwd³ETP¦W°Ú'÷QÀc±¢éQØ|ĞŠrÜ|g‰İ-ŠûLeã¾³X®êQ\29’«Ad»½¾‰ƒú“Å_JK:=´aiv+‘)Äø†0Ğ}p™tÇ6×Ñ	ùmxt Zñdìß­g† drŠ¡²£ñPÊh&¬.ÜsÆUO¤G£b{£C‹(Ä(Sh^=$0˜ğ</szgşar+	§ú²g™0dã«—IYğä˜Ø?òbŠ‰Å,¾Ÿ¥l'<*<¡«ÀdG–¯çı&‰`˜´#?ò¨[‡:€Ğ¯Tâç–7‹%ä%£Ü¬Ÿ#Âd	ìäR˜ÄÓï»‡çĞİ‚3ÇUèÄ– ¡'#Ë>ÉOk_é“æ¢îèœöügè>Fg…¬ ©1ü/üv|ğĞW ®ÏQ§a[3CzÛ}¿êö
ºãRÄ¼0Ìºx¤·
Û>ÀA¨½Tw¬)`ÉBI–#‹›s/ğ¥š™:Ô*¸ca<C¾îw«¥ÄD(ş´Ä‚GIó|š[ÉTV>	™:÷ğv_?6ĞRùÒKãWcÎ¸Š˜©³cÄìOñÏ‹Løz†0?@T*%VÆ²ŠŸ²ğ¯€ÿ¾÷%V_l~”À¬İóâ“|%Ù)ğó²*-	p¦Ç>I´èD¼
JÕ)mOÒ:ÍŞ¯¹wd:r°7wFS~òìƒ‹¾RH,bÿİ^–”\!V¬ãq–Ä¥{ş-€Mß–ïàLX¾rxšßA˜½•qy*Pòå=‘gáÛ6;Ä\î…]‹M4İÛ[q³¶Ï­l¤ƒN)ïrbx/Yæ*f‚§"ÌCÛnşˆ‹3ç ÏıbÅn9Ô^ãüHtÏŸS‡ÙìšÙÿ˜‚5šLbyMÈŸ#J‹6#~€jN¨$^¶æ”è|öpMcÑh‡êk³AÕú<­w‡&®eÊTá2sà£ 
€ï8Ç²™oPËÌ6şzÕMZ§‡ŸE½.$BèÑëğÖ`3‰ıó”¶•ìkùËÛH£Q¨)x§vp9áŠbB@½1"AtSqñå?I”KZWìÈ/]ú·T»…¿QTùıäweı5ÇÔo˜lá>W¹x¢‘Ì0ı«’
²–šGY{ÆNİŸÖ…ßæcÁZÆâ,ÔF]‚ûJÔjÙ¶‰ÇfVõ"ú9¶ğ/£FNıáL¸ÎU.íå¯yqumÁ…‡Ff¸1†´aÊæô|ş?£pK˜twA_: î„¢O¡ÄšçÃÌ€!êÑ maWñşØxî2»óÅúnÖã{Ú@VÜI¿öÚôÿ®—”äÙŠÂìoÿ©‹Åg>Y(Ú8´_'/¿ınğôœJY]xâ„¬N+FªŞ‹q´€ú½à÷³rJ­á°ìåŒ“u(|n¯‹ÍŒ™·W\Ï_ô;ˆÏb×j×1ºuô«Ìå%%¸öÎx-g…ÃˆŞô”ƒqDº' Ë•¢Ï±^iFÖ3“u "Ûù÷$âkfıkËE‘*ßŸ.ÖkH«gC˜É£ÊÍÚhÆ’ŠÇf…kïGRŒ‘e€…z‘eêÛÅíÙsRo5VG&™õÛ e/š¥ü®¾ÈæŒ2îS?«\Ræh¥¼ÔJ\JÔÔ;ÜM-N~òáz¸,LˆÉ®)‰p#<z¿uË·£}¹²LwOú)¦ŞŞé_ 1÷•_£êvvP¡¿o–#»Üş>·`Tui´6æˆ¹hW×½ìf{-¯âšöyå|=ŞK—¥öŠI7ù€í{PZªhPÆ1ÈİÏdlÖ…¹æ¿0eå×‘6|äšyòùÜ€&;Z‰8›lsI?'W¹û}·÷PÃ®øh*è•gãÏóÙñk×ZAéz-B²Êt'iÔÓ¿@
Mc˜¶¨GÎréãsÃôEÙ’ˆ!»Nú÷:Ÿ£ñ²ûğyÔñ¤êO_Œ“7ğsà1[½V­ƒæŸY~ıØk‡Ş7¤ıÇR\Ó“Ã~Œ ZÖ—Ó©äå–)– OçÚ vØ€ı	qpŒ“å#X¶øí»†êµÕŸ› Ytjßš¼·Wr&Üa£jjKÚ©4s.„9T(%!=CLÃS§%Ø]V½ƒ{*
¡z¸c®šFØ?Mõ23÷}o¢ĞtÏ¢­TÕú ğğŞ8ÂY‰”"ü»5¯2òÑcİ1I¡€Ò¸@m—GæPFüÖ¶¬­ÔÌ¤‡İNšóØ½F°¾´,ÜÍörC	åEÈD•D¢~–jpÊ+£ Ş€9\<İå	:â: ®‚áüh~w²O«„YyÎ‰Û,ş¥"ú]Â‡¬è:áT¼m3^}aiÈsRûõùFO?Ò!É-÷ô!7
ÏÚs ÷lŠézØ?LÚ'Äûvdê&2‰Ç¿;HÙë|í³»-g<†[hiïåœÀúÔNW»‰£k!RÄ„†â^µš«Â´ªN‘Bå.uÒ9ÔÆ1D*Î7ßØZJ–_<¦´ 81×ŠN{{¡éİ>º“Ğ€Ê†wRQ~•j–èlÜ’y&1N5;TòÜ ­T/-¸r]¸<ƒ¥uªf¦õ‹gDwnëdYp~kóic¢‰«}óÁûPÑõé¦j½ÚC5K<«3P—wpïœZBí—K­½Ï.oØäPU#i°Í<ãr¸­¾Ë†í\3Øk+ëÆÙÕ$ø²ûğFå:»Ì½Yâ÷µ=ı.èlÍê®ßìAúÿóë4ğúñ4XQy*zéİ¯ãÌl#	^HÛzp§é^ê»[»´ÚxtBï„ÓÚpìt&ƒ;$š$!]j»k'—{=[| 0[ó7fzH$ÜĞVÒ5t 8ê^¼n€½˜¸èò¥‚Òqß@Ö£<AÀ²7¹Éf ğ›fD‚Eø:ğ|<Ş%±‚Íƒ‘ 4*e›5Ákº•¢Bµ”T¯&O O‚bœdê8eôŞ¿æÑ»ï-^¢,İïoqèæ¨G6]³ìşJi«=Î3»²’'©ÔšÖ¨Om“?QŒX¤dò+vêp7øX×¸#¥ ”çxñrvÈÎ°âkÀõÒ©A"<RdÄzß„îÁyy¢EøÀKL…·z/+ê‚†Ÿ#QŠ ÑV ±¼¹µ	Íä_‘ºÔ*ÕÜÅÑ!Ò}uVÜ~Kj4‹…÷S„…kêşÔË¥ğÛ-W1‘‚ıÎËÈS•¼çyÕ|"+aæÖı•Ö*ÈúóŞÔâ,~|zyœ«Ö¿Êü Šğ]$²T!ä,”uÛˆ4ªûxB×üĞW0úï×Çf7{H.¼ ÇDb…öA®·8»ƒ4´ÏèÑ	Zšã‰È£È¾S-›úH‚YS*¬ÏR8õ\Òt:±¡Í%´ÑÇi9ÃÕ%P(Ä’7+¦$ñêgï…²®­o­dê]‹@á‚jÜ›[¿+ñdĞTxXi†fNŒÉØæÊ‡~AÀ2-q¦ÅD>Z«pqç¹È—šA£€… dÄøòÕó\èËÚ¹ÊÖ¦„_}~ëÎ/,/¨7s^4é‹L#,üävğ—)8¸<¦‘HĞH(nëP¸´Më?ë­xUuİf½v´ub¢ÁósjüiI9B+ícJÈÛ‘«™ò"Û¼•¾x™ ®Ñÿ1ŠKƒß±Cxù@ôd”{ˆ ¸D"_rêòƒMöa™P*†í´Ÿu§Àİ{—víá}²8GÌ#W¾:kîÚòÇ°)GyÈz7•”^;¬*ôjÃqÚæÓŠ=¡zô.´Œù­–_ğñöÉ³7ô0¿G˜øöF0ÇêÈ[­¬I ±ˆµY?¹æ¤†2º±Ü.H¬.O2ûh&ü“E%ƒ od(×
æİŸB Í¼Aİ9œó#Ü,@nµ‹+éåÂY¬?eŞHx3´öö¥ÜìN¶ê<éâ3zÌ1T‹ïé¦¡%V¡q×¦±˜13I“&Oğ&ïñ¿ĞÊÓ^aù,Ü^·Üs :àÕç“KÒmàŸ>lÉ/ÃO­Ò‹>E…çêŞ
‘ònRè—ñNQ™Wšş_„§RøÙ}Øch 4ø˜™FÄ2õÔ½Êé¢©º5ŠGz•yÌ¼[È>Ì"5ı¬‘0¿øtSxú-ç"iÃŸæŸO¡ñÜ¯ ×Yˆ0ì,b\œ~š7+˜Heí+âŞÌ	ªbŒŞa¬yÉ?L7ÖÎöi¼Oáètmëq¤—² rCVËxÎ„ïÃ¥œâ·Ë­0gÀKu‹Ğ²SBòî°L‚ £Ë¹ÿä¢U,;ñ«‘‡4N¥½B£­P€¤ÁŠYMyó~:óo¾N°j™Šº¬069Ù +gëI¬z_˜…“nZ2èàS«–`ÄïMtôÅÍôM<ÁñR·õÚÆ~ø¢£ÎDjóS5#ğ.:íÚ=UÔ°òÄîéÁ¡ÆvêÛ[Œİ‡‹°—ÚZ§ml…Œ´–ÓV˜i#³±Ëw¤Â9~»²Át°wC†|‡]ÈŸg[ÁkØºáo–LaÊ'ìŞŒı´ç¹ªĞ<­\£şË"ELĞu^^­P„Ñ"ƒk–©¼5è@„EZ*â©qp­mJ™è4ÀAø8„k¦N*B¬ã;$%×¾™WiÅJ<;óÅÍBÒÃcŠÈ¥KóKd\å"ƒrWpšSDšÑß@H¦Ê£¿«O\Àş3kâÏÜ»™6(Ì-ãû÷åv*ª•˜]Kbééàõ²*‡ó¡`ë	m²pgƒ®PN¡ï]?@¨¡‚»‡Sªs$¢9¢W´@[ÊÏq3heƒş¬í}’6½-0yTYÀÑw=ËÑÚBkõÜ¦tPÜJz©Ù›•œ–#x)P4Ş¬‡kLA(ƒŒ_{‡zgIÜÜ¯q_àŸ¢:œôÍ|érœ÷à›Ag¿†	"¹¼V±¶İé0|OdX•©Btl’1]”Åı±íÜ§Y6ş¬ú‚](`z	
Âï"riŸşñ[áøzÑ­ùŠé —•vƒÏ‡m,±)Ñã£G;a¢_RÄ^ó¡&{Th¯ÁÙ;Çó`İ%«^nÖ‚'Í‡çvÎ}˜æĞŠÏ¤í4í]àİÅ‚fz«}R²à*Ài@qj(pÀ=PµïUû6zˆqÎu¯ÜÀuY±¢Jòx§Ğá-­)ìã•g+£MòĞ“É ÄßP6šñø>ğ÷µÁô òl~‡`'QÅŸ/õÑ à'%v3PÀ™>MXãëNáŒiht–/Íãí(BpÌ´¤nÉY˜¬«"åÎëø¥D{>şRIóÆvLO¾­;KĞİ´f==2¶4–çĞ‰qºÂğŒQÆ´;FvÃÒñ ã)‡*‘Ã½Æ-~|fµßÆ¹zétÈ¡KÊVM™ZxÜbäÀf~®RMg ®wÔZJH´›ò¡ş`„ub^Jz¹a9ÄÎrj	Š•+2øÄÖ®¸ÉëøôxUÂÜĞyZÜ´ÌÇ½Ù;i<¬ä»±ù‰‘ªu¹X²Î˜±Ôö§“ä"_¡8B•ÌPv²Â¥¥†‚<ô~/Í:âåïÍúã‘—ã¤æQ´Z¿ª‚ÆŞ^ ï>‚PÚ<“¸
óJk•l6ÊÔ‰qt]¼ç™ lÔëì˜?ïÎœªëÒ’£°YaŸ«ú¶=‹qBcB,hßIâXÇŒ¬ÇÓÚ¼šÏvPT#Q`.ÌTÀĞÆ§¡&¬†hQ7ö.WB¾ƒ·¡;nÜ~~*waÍÑ§*Â¡ë[O,Ò‰ÑM)yº˜æƒ^M‹NöÖ5zÜ!Œ,ôÌ?!]5ñ¯—j˜á\SÎò+—Çìpëõ†›N$ÄH"5uÇÂÚ‰HÙlZ¬r7Vuˆ÷óEî÷æ¦MÇäÎJ\0—îüTåDF*2ÛÿÈÄ‹iëá¾~»k¤"H°wş"*Éšs¬íìh	4Lì–d‡åãTì‰ˆûYúYæÍ¶“A
Pîq–5o÷á+{¿Ï®®S'Ô—ìğê%"pÙÒxÁ)ä)ZÁw&OİA‰±—ı8×©Îú`›!O€-Ğ\¦hÑeP÷Ò_ŠEK” ôµnÑÉ×Ú÷ÎùÅ#ş;$ñ3
"ËÂÂøH(G1ğÉ…*NúøYY	4Ó&Ôî±(É'OhÉ’íğ£©†*Øò¦¯,CÃq3û°Îµ¼©ÅÑ„ç|yÇ[†˜úŸáÎ©ß#Q§[š_gª/òé^NjF2‡ü9÷²ú}';x]¾ëËU28?4¨Í.D*ä›©LãQéˆ{£ZÅV¨£§bK˜ä^C÷²ıÀÆ¨±n³ëlÑÈ²'üİà'ò(å;ó“ è^ˆä 6ÿ ó¾£§:	oO¡¢­reÖş/Hİ„“¢uö{<AJ‹÷ä -ê¥mëÚ©FğƒœÌÅŒ´Sn{z€QUä»VTÀˆëãÜÈŞ	ÿàÅFïJ.HÑ;õµ,™‘ı9;¯Í6šQ³igš¸ª)gÖeMš“<ä#ïP:nÿìiïl¨wh0Éäàuæ:ò”A«NXL)’ÇÙà÷·ÇÄªXïò¸M®d˜ÅÅ<®„Â {ÛF5³‰ÚÜA;Šø²t
[“ÛÖ5_ªÉı¶²Ò†QıÛ@'ÆeiÎ¹k£MUpÎÌ’(Pïdô¯4¿=À§°²:P¾…p¨-WX¾[ƒ2º4¼ÈØ9Ö{^+Bt[`–c=§î)U0Q¹rXĞŸº€!Ò®eŒ•†YØ”}Èf:ºógÃ·Cÿ®_¸ì¤ïi¥ÚÉÆ¸7®Œ×}§ÿşÈI?€IòàzÿŒÍˆ#ù/ÿ¥w\	IÌQ:IN$ ¶9ª1Ä%4€dš9:vÜE¤»½ğñ—ñe¤|ËË»qfS²˜ãÛ¿uQ'.+çä’TJzÂ·şWÌ¬ä-dJ±`óÓDİ¹$fÅTÈ|NíHßšŞh?¦ ‹s`Zp!d
6MGR‡ÔfÃ¤ÒCuEü/âNK\çZ#®Á¦ùM›ÌHKù²h]ÿt	[—šr´×
Ì# {••¯B^jAÈ=˜…âB‚@Vpq¦ê×º øÏiµ”Œè{¨sôƒ,Ï¯[ëÎ4âÊ¯=¢Ì©V á’Ï~ƒ6¡;:å>’.ëÒRİ'zGµé9ÓS1ìç5®Âs‹“íÃ†3"Ümià×Ã¤’¾d¸Ô`„q
¾FáCÁFâ@C]Z,o=jğãù³›âÓowAk&²}f‹]k0¯sS€•ÚĞ|˜–)9¿˜*ÿ ‘Éá˜Â¥#ĞQ%‹#­k²¡‡ ©…—ù!3–gÃÏûX¶i5g¦{Ur„«ÖàÆåÜFÜ¦»YÇR¢-WEÛ£4Bjq62!üË>«ıTg%üBU…¬$jA)ÇI¥pÌ[oM­$ìf>ºÌÓfj‘ğÁ ³x¼#õ‚yW/vIÅiÿñ¿¾gÔ˜6`§‰àUóò½o9êèO@Èÿ$¶!K™Å7k? „ÎÅáC@b031c_éuäÅÎÍ «oï80Ü&üòq–¿ú“x„%5:ÓÿAşÓõ®'•íápÄ»_x#›Û½ö¾}@Tnã€·rğóøß¼^7ç×ƒtJÒÿ3[r"10?¦ô@c[Páã÷Ó^k‘£U½ÎKÄÀÿë·fˆÜPÆt†op£Ú5†LY³ëû¸ëäš®9Ê
Œ£ û;]Æ•ª¦ƒÕ¯Eÿàg5Ò`ùçñÒ£(Úÿfù¡œ8ax5ÿ+9e×¿÷óùÂü™ŞHò€²î˜Ì­ÃPœ!’c7rõ÷û*0˜QÚYÃRajı¨ñÏ%iúN“ß?g<Ş¯V§Ô¾fiØKÊgØ—yi9¤ñÀ½îV=ñ­<ü©ùs†NNÎ·vòñ#’XUÈk[l¼¢Ï¢'@„Œ§0àD÷<c*©×?j^ø¿w€+s=ÿ¬´Œh,¢ckªJ¶ˆï‘™2ZôòÅ)ùL  Ùív_
û)Ë/êÿ*J·w#Üî@)‘£İh¤J´_‰ª‰ädm÷0C¨T¶ß´¨Ï Å3•ab™§Oá„÷BõhæÑËá	g:òuöÚ}Zº<np_º¬Hİ¹aü\á,µ–È:‘º0Ñ˜Rg\•RÑ½-:İ…é;Ñùôè%îÚ2ìˆd5„…ƒrÇÃXç(¯s;¿/Ãâ
—¬é”ßãuu+t]Å(õØKHº”:?á¹—j‘­)œ]µ¾uı#Áâ‡*N<	V°W&¦;‘AZ`=Û´pê6œ¶m)^º_E ¢gï‰ëòÁÆ&ˆäeÉ8ô Zñ	ì`y‰½>"]ëŞÀLá#ÁYÃÍÅB$äU*Ÿ¨¯¼otEtÂ ÈŸ@sûÔü‹Xs½U?•`ö£Ó3Ÿdû¡v€¨^dQÇm¶Õ°ÀG²ïÊ
 J©ıÏ¤0èÕw„-¹vÚãdsĞÔup|uU4@W0x¼„B‘ _Eû¥wLxÇÎŠ+Euf… 7T‚¯Ó
zön‹›VSrõ(œÊÜwĞgìèC‹ÃÍgŞôçl¿6S®õUÍø…	(÷d¾ú;HL‘£¯3º·E/!ÔÔQs‘ò¢`ª§[hg§é‡Lä$zc—õ@M±6a'\ K8İ2Ó¢œ¬ï­÷ê#öüPï‘L[êïMe—ºÍ¸Ík~3<êTnÓID´äZPî!´Yñ‘™T×0xÜŸ‰¬âÛøA”t=$ÛUj:D‘OŞ{;)ÈŞ«"V,ÇÀYåâ˜ŞQ¸D"¨1ç®ÌOÌËV\MHªşÎTêO59º4€â™FÉ…ä—ç¬Ú¾Q¿9éµQ^ø¿œÉ¾¿Zê°fMqò°Òïß0¸(Ír³æNÈ—èã=ï›c_A“¡9W¶zûÏM¿ñÍÖ´Ï«Õ"Gá†ekè¼Â^3Ôø×óÒ¾ïÚ†!òÃ:Kxç2ÓMÁo$:?%„'÷pY¯ÃóÛJ…j§H#¤R×”<ıZğqŒ¾¾)l¯"{"8¶ÎWÉªÎû5;½QÕğ‰}Ø»-ï*Ne®h;$2’PÒJ”hév©-åÖ7ÏëSĞ)Ğ‚[Ñîô°V,ãàÈã©àLË@®6ñwò‡ jŞs]À­w‚ĞZX£õ´ğ›Ønö8ˆÛ¤óÌø†RûìCŞ·v½Œ1ŞÕæìÿ”ôÊkÌí)ÔTã4md?v4u’<ú™¶Ó…­äG.£Ù6'0^gvŞÑİR2'Š>^‰R·iÚ¦[*íI2Ú0·$}îZBeÖ"êOÑÌä0Ò,¿ô¢ôºZå_¯½”Yô PòÀÊUMç¸ˆÜŒ•²®Gº9»Xíîw0GŸ±O6Ğíåa™9‡?è·E†*¾oŒ±¼ k'k˜À¶`k§ÕK!Ô¸uÆà(]I‘Ï3IAİWU~bKÎÛÂÆğ'»Ë‰ÔĞFw!BÜfƒOy¶ÉÛ't“rb…ìuºvˆ©µ¢èshOË‹%q'°4œ°Ğ*º¾EèÓ@Äø\›ÙVº ëzs[”Ï=Ğ•2ğ—´D3	ôØ6F®ÌbT’^Í‚T®Ê-uô§[	GG›ã„~Tø_ş|ãlü£›³r	,W_ÂšÄÏFD Bx¡ôCwt1DdHÂgiWk§û—„ÕÌ”ÆH5\NŞ61(á³çQ©mû~¥A½©>õ Ü÷Nõ8Ô˜ÃÆ®×Ö} Ä¿WÆ]o~.Š¾Yüó\Pæ¹ğR[ÆÒ–á¶®€#9¹‹¾À:‡gEQ!ïŒšpN­ü´ÂµıBÎqƒóQ\¤ÇË‰ÂÃCºåÌüŒB\ËÓßXã³œaNËrA4>¾\Œ¬C†c™“óÌŞñéÜæŠ	Ç|ÊŸ©¿=ç…‘RÕìÔØäöèÿ§˜¥÷&‘¿‡Ğ3y{F
¹ãDı€„;¦ìO z3Q[Ã¶ÕhÚı€+}´ßnêãÕö	óš‘˜¬©9›ù@
¯ëØQö3.Ìª"‹oØ}/LŞ‚ğÁŠçmø¥ÍAÅÖ·(RI×mşV†§j3Ø÷ƒ
›­`pìuÚÕZNmĞŸ7ÕVŸ‡QÒ†{c5ºË'¶‘'D‰É<uB©h¬·jò]BS;A\Á¼HÂLñÒ‰Ìµ$ÿi8•d"nyDšÙÌÍ0“N½„´ÌKø,u1úÿ{zê]±‘3Ä"I
Ô‰À6Ø×èö®?G»j+ãÆĞ;\Ö—øæ¦ŠíXI‰ÛdUk:vÀ.—„š·bÓQ}ó2(óp¾µØyº®sîı$|ü3Ñ“(OÖÆ¤Vá–0Náu@1ã
køùÃÁlïXÏ`_£ì à‹/½Ûc(_3Ùß¤Ú~"d6XƒYòİ:çÊîŞùJ2VÿRv“"gdx(ÔÍŸÇHÛ4Ìè-òŸñƒ\êj‘8FHª¯…
FƒRƒ4ÍÆ%ÿ·ù½ë—‘\†--g[sû•àº?à¶†>· »¿ı+rôÚ;/—¦òI‘J©3‚î©KÁ‡¸_‰—Cr!Q’ *êÇU[±‰(›p,[F¹ı[6Ãxe3¹X’¾¥ÖV©ÚDûw?7öWXHÿĞò¾Õ7ït9!Qõ@LW†Ìß?1ß¼R¹Üm£Fgev*ª}ğqÊ„;îİ„Ub%³ É5•JLh©ƒÃòl‰ ÉLÿ­¤Ÿö®Š¹„ÓÂ[ÖšÎ³Ğ £D*¦û%1À;µBrb1Õúï½s¸ı›WoWšz$ÅKÅeŞs;Ó\|•\y²Ñ<•¯Ì–œœ‹Ád3ë»×ú±söc4ï~«à½Ñ!ÓqÑtŞ9™’S’M;†Æˆ>©õ–£¦gÕÔØ-ŠŸOUù<&c”½aåİrû9öäÂ÷X<½íEê%„5½ö1­Û_HTUvJ¼Ša{(+ÇŠ`xé$ ò‘y¯P€ºê*xX¹âs>“¼F6ÿl0ô‰ºœ¿>I;³~ª.İ¾+dÃe‚šÁé³yo‡¯kTW› ñMœú`-ß"t`47BÎİÆ„’aïO˜ƒÁN‹E¶“ÍAåŒ—ÔqÛYœ›š^_ÇcGªOÒ¹©†³°›Èœümª·‹k„î(.GeÛoZ?PÉP¢ ã[çË…íÄK¼Ÿ½ZßU€½îÆ–ì—€a`€çHÑ¯¶‘1Ej‚š”ëúV3œYŸWê”lŠ€½‰IÅÓ –rãDiü® öjïîV>
¿û]ŠÄ…QÉ´úŠßqæãš–v6!
¿Ì…ÿÜcY‚d¨†úèå“— ^7ÛÛÛ¦æ8Ååâ4æ.[]st*jÚËf3r3ø@š¬µbˆÿaƒ¡~mÏÀ'åÜq|Ö’ƒé q¹,ë–f:/ñ­wpÇ¢+×22\ĞÒvG¬ğ(öŸöjêz€<ÛgôØ¿Ü3t=6i Šz!¬è¡’û& ñW@6)y„PèzÇĞ°$ÉQÿX©"±n(Da©šôVò3và
^‹
Ãé¶Õù]ÈyåâÀÏÁ› @Ü}Ïb¨Â²ñÖDqM+l²¿ìdêşöÃµm8ùğ^±ØjÖk’ã‹»mÈš!éÇ#5<£’rğd^VŞ$©@À	•Áp‡©#NÇÈ¼lA/åMi?½8ÉtwÆ¼ËşX˜Ì$şè)•[/Ş“	2èXY4•ˆå£Dù¼DgÁàı¹m_AÉPv¤õ…m6Ê<˜rL©ÏÚCù¼{Wÿ
ÍûË+±d3eJk?“²Ã<¶~‘WZUv›_JpLÉ'BŒV‚¶PX3˜(¹ø¡ÿR‹=A¯uŒİ¨®¾Í/(Ób_pP—ÚÌeg·–Ëú2‰UØGæBe$e£…zJCÂH_ÂXÙºâ¬$Hğh`
±2?‚å/O:Lj¾NÊò(i“H{ëŠ"¤bwØí©"AQUİjrM;É4-‘OÚ9ùdzNõın`/İİ…á0ô·í3rŞÿ¸ıÚ²”¾ÓÏ{±Ôõî›c©Äuá¹G¤6Z¤´|#L¹ráy$óÇĞ0¼ÎËQÃD$˜Ø,T~¾oäyiòB3T†ÿÜ9ÀzÓş´Ú(é/f’ÁèåLÁ§ës±ƒQËfD™‘:•apª¬'úMÜ°>Vó PºˆxŸp_1ß»Í²L:Ò}3°şrZ€Ë*j@òËŠ–Çys7¤#FÔUĞª{ èö‚·-ki3ZpvIƒ›2
-G|"WH½wĞ3%z4EâË[Vp5ÍY…e°™€‘×É¡/Â‘#(T|S²Sˆ-å\ğøY%ê­¬Ì‘XŒ‘âK#™	Ú‘Ú '‰ ¢ïÎ¿n²Ÿ×ZI8gI÷9ô|ëlN>€-Bî‚¨m‚wHÔŸS[tä³±Ñ_Ùş+£fÈ0Lud”1bNàüK°7Û¨Q‹hSéíõ9‘f6%–r‡û17Yï1“‰İÖLÌå>°
Ò;:‡"Éd«RqJ…éÄÃU”9wG|ÜÖi²É_ô 3Yº­6ß%û w7áí 'Á.õ<'ğ˜Àa$2jÔn©Öu©bÄ‹ì¡ïÈ”‹¼œO¦,#6s¨îˆ¿¾FT¬a¢v˜ÚpJu?ÒïÕJéºpØV¬'úPj9R÷—‚És6áIöœ¹‰È‚#‹Œ’
W½Ô	é £–"X¥˜l³Qùa®YJº/èrÖûnupç %B ŞÊ—İ~q¦¤®¡¯,wŒúlìdüªöok{w&Zº6{7&ÕK)ÜËÒKfÆÅCIc¥KHTj’çšP<Sã.V¦³ºµ™ÊÉO$'ùt§}œ(µp§m0›JkR€ËÈÄ‡ºV6Î.NéÀ¬HÏ_ğDsL Ò8bŸò¤§M!*ŸVS!±~z÷ŞÿÌTšëñP=ˆ­Í}àù¦*GÁƒ¸ùàq7*‡V1.«Ò#çMå /fú`mI¼V8ø˜òjúş¿¿Šl1U¿b×»rK&^wBS>t…‹ƒJ1Qî$(€-ûÁÊò¨z}é/Áò-®CM„PoîiÏ:§_ÈÉ~-­8h…>ş¢{)BP»=æ	˜é’/çÿîå£(ñL¥.ê‹î™±
}øÛ
<¬1‹ãH÷]éT¹ı]üT™d’ÇòË—2PÑO!Á)ãQÖˆ“Dvái™2Põ¸ãk©]Şg*B¨ÈOH¤ªû”/el Ø:?9ØXdV´G)Ì¦äìwÇÍğ;ç'nN\èïk~µ(wª¥4¾Ñ¢,Ä£1œ$¨u«™/N hÎ£‰ÎWbñó‹OS§n¥2tìoŠ5 ¶ÃTlæ#õü*Ú4k¨ÓoßÀÛŞlÃvUL­y¸šP_Dé#ÃËnÔ9×Í.ÏSr˜çöÉ¥ÁYY^œ5[ËÑ²Œ)ñ\š9xöFÌ‘²³9‘•4*
¼Ş¯BA¨G‚ÈWL-ù´„UA¾ñMÒcœ3!s:ÀÅVa€ÖÕ¿x_´$fU”Ö8/´Åd­'cØ=je5Óy¨Ê]Dw^¤Ú_T&¸–¸o6‰!sÊm=T£ÙĞSoû2²Ga0°¢À_ ²ğ)Tö—âãƒ¹=J”ã¤"x ˆ[rôŸA5¶×ÒğZŒgq‡õÇa'ğhP9Vx¬h5Q®ê_´Îh^EAv´a);Wş´°ç‡–˜d7w >ç˜Z-µGX†òõÑÇĞu«·CP¼ŠAWß+3¹` R>F^[x<ÀsàOÿå'. p^:îÿ¼¾Gt­•¨h	~z~>zoÚú¹uÛg}?Øxìa˜biÈDÚóÛÊrf«)u-­wl6ä~%ùTı¯ÿ@³T6Í0$‰»Wİğ¿ö†?49ÏqÆHWĞ¦9uûC¸ú£fŸ‰ãéƒe,o{nùì£0»O|ÕçS}Š£•Í² 0$Ğh¡š
³&ó¹û°2WôeÌ?-¨úà¡¥tPÿÉrğL¤}ûÃ ¼íËq50Ì²ÿÓk£j•é´­Æã‡êÌ×pÀ¨ŸVÈ‡Cè6`_–’´/©Š>„Ğ89GŞ0 –1cdäœm¸3Ëôç[•p.Q"ÂÅDÙ¥2xõJáJ÷[Ê¶ó}XË;½.õ»g9A‘q9Œ)\aÃòş˜‰ã¤n ’-Ç†¾`oØ³M[ÂÈ¼ş*€èN4<²Ì'(vÍ€°ÓgÒµÁè<ç¤éU2‹‚úÿ»Pí)4<ÖĞyy
Øàmû¢îÉZ3¡ 8±	H171‰ŞN…[åä¼ÆÑIce$ã=nE<# ¿R)â+qõd³ØQ# =˜|]ËÇK@|R4¾(KíäùÉ©Ÿ±]¢v›bØ”×>'2#ÇyÃ=¸º¦¨"®éIUñ[(Ó×u'û«’Ø+Jã˜ïŒNÖm¦M{9I¯pÊRìgXàóz¶¥"Ø|ÛÔ"njûİÈ«Øiéo@R['{ÙOd‡,‹Øç‚·…V	ëmJ4Aéo|ÖöK{ì¥2zWaBWæÔJŞ£¸aÑ­íaÆ‰²=o¯öôÔÉÄ¹&µ©é	SKÕQA±UPŒqİÚåÔíC6ÆŞ¿Çñµäó–Â†kqËùÄrŠ\„üÀâõ«ñ–…ÖÄU†ó‰7ÛÛ _í<Àp¯ä@+¸Íi<U<v)\¢X‡¶Ô~¢CİoÑ§¯è9o¨¼èbmTô“aÜ„
d«r=²3ê²‡ÕSC”ú¸/°q™){ŒÑÄ~5±¢™õÀğôhNòBÁµÍòŠ/V¦át~6Ã¦:ÎÊ'Ô²ÂæÈİqC#Ì¡İêÀ÷ºëÏçÏª†ş$ñËª€x¥¢'¾‘d$ö¬éƒq¬lbÅ•ßyš'&µA–Øİdâ<w–q"$Â`ßòöRzˆ7!¸Ÿ}j¸A´z‡È†âÙø¸d~7·AröÅ‰M 8íÀ""‘[!÷yà²¤€i*³D"(döí7[&„$µ†=ÄGE,o–]ˆ¥HK
1kÃ”ÿ~Kû-»¤èm®†ü)i²Çó‹Ù”ÅÜïë$³AÂÌ(jTHhg«m^Ô{©f¶íÌªJxü,™´vE“9Ñ›‹²=*­Pg¢¹y’¬§×e‰ş_Ù"õ=fñÁiÅœOdUúùn&Şp±¡$ş4
#XK`‘„±çÛ;˜ÒTš¶yÃ1…í€:kª@Áì[p=ÊoÀ´öİI)ç¤®H¤ƒ¯&Âš8Wò{Èê/üı•".ıEJv0‹'‘›‹Á¢ }ÄûÂø·ÉØ´ ¶Áµ,*¥2õ©Ó¨¡Àb="õ¹ôÅ®·Fíw×uÄEDL^üÉ<Î±'Çé	°šÉPfô’sû„,òa]EÍ;ÙW§ĞÉ³¹©úkõ™ZÄÜÓ´z|c^¾²Cjì¨‘9ü›%81x¯ó‘NmıâóD!V–ùêèÉ¢È4uˆ«MÆé£"
>o«°ä–Àt(DHn6Œê0ïÇdó$ïßlÓzu=#"uQ“::©Â¸s`DÀOdÄ«Á…+àtˆ÷nKEˆ+îèøĞŞ¥åk¨õ›VÌnUÉïfV\[Š#(
®7§’ZcA›‰ÔÍ€Tês jZ¶iî’µ3Ü§@\İğ%É9.:iN€»1Zr¡Wòâ–Ê:O Ë\,¢ñ»2×h”¿TÓÍÃAL3>µt	°Ê<¾<>Ü³`Ø
cW8ân«áÀ–úÊ×Ì“Ç³*‰ØÙÖ+|š¬×ˆR¤YdCûD(^£ ò~s	l½Ã9ceÿ8éA¸°*kªaÉ	Ä®RÎqq?<Ú£Õ+¸7¼ŠS
³è~õ†ZüZõ¡ò=$·d©­,t¤‘é–ˆìÒ!gÈÑÂûU'ÅÏ”’-®„‘‡®k’¬í“!ï’±²ÉQcrã€¶R˜Ò1Û·*ªb–AšlŒc”1Ù³,˜\õc¶Ÿ¨rFèX'®»WôGAì1yÀc~Wßd8ŸñImDpŸ¿~øFÕ±[ŠÅ£e[çûú%ı2mêÙ¯½–D¤Ã½ù¼_¶o“oHĞ»óÀŞ;À_µ·z->¥>¼7ò ™£1JËvFÂ[u½ÀèÑ”ª …Ëôl»0“3-ùióJÖõW¸4.¨ÕÇŠb©T†2"ÚË‰ÇYí¾Ø»`Ø¯¨Å¼\ŒÇ»ì™ôV‹ĞÓTAØlÚ¡LLsl¬
z¬ê^Õ‚¾Ë•gÍéBáÜ»’YCm#}¢[]e–GÁ¾D´9¶ø„
 +¡†á'ÏqÚÌ„‘ ˆ˜Â¥7ƒÚ]Ü:Şm®vËî@–Å·áÿí1ÔzMœº†¤{•İÜw¡ëï '@3õm‡Pïğˆ¢S-V4˜vzlÚ£,'Å‘ïÅO×Ôİ:n±OPÒh?A>ôÁ³{UëĞ@†I¥óT}†… µ¼è¦¬,š±»Ñğø$8Ë%½n²C)µ¬) Ş nFæ´Ğƒ	~ôß\07yosÑøD–KËÉ­ÚÛ”³‹B­Æ±¥ì}.üwÚDøXuOEøšìrÖD?qï]—µP]îp?K×ÔÓ³I‡Âà:€-ÒÇrsRCä¤cZ-@êöÙ-¦ÙÑ©»ùU¡}Áªg¬¾º?¿Ï	g)xá†dö“µºkgŸT©%Ñ$~Í#Uå™%É±HÊÀÀcë¼á]à¤»`®4@ÌÚaÀ4-ƒÙbiH­gEh¥Âjå)÷¸)·fvO ´Û/Šé$2í/òƒ¥/¶c€o3>øSœõúR
Bü§LµÕÑ7ÕÖƒCÕ/CL·•O‹½î™UÓõå?1Xts˜$ÉEíæÇ%Ú4ùutÑP^Ì$oŸ¬5 L“ÅTÎŸg¤ä'}ÍÒh`î›0„ì¶C`ÓVØáã#\EÛ\nU¾aUœ^Á»ˆNÌLÈ'_Ûp4–u~Å_õu-Ó]ÇÇ<)õ,'²ñˆ3kôõQÖ€²ÃNÙÿöÊCW;¨ë,ó‡–(ªºÙB™^ÕÃ›át:¯î¸gà¨Õw4rtx%aÆBw7q&¦jÄc/Âİb§ó¥SnY"*o¸’‚ƒl5"âÃîa><ËmXi$r–uŠûØ’+ütçwÊfÏÏ>ëÒ	M•Ãz‘˜.¤Ø$yh•Et]‘ôØ€,¢ønàìÖ $½#ã×ºf°I¤J„áµÚ+ÃAM'ÃjÑ¼K'31œWÙ‘N$\c ù7ôèò)À›¼tŠQƒKb×ï
eUË^ÜâŸãégÀÕ368ËÇwRZ£“ÅÄHÃŞ²RnYê˜H™ä"ÛpSó"J5*Lğiç¿{å“kâÛ0^ÁTÍ+4Õï"”|s$Ë6ş†›YˆG²`	Õn½ŸzÀí?H£˜_ğ?¸Ñ,üLË–7öbœ@^Ÿ3é¾I‹˜G14£r«á=Û¤Ç• `7ÃÚˆ²%ÌÃ1cA)Àãã£A™£ß1á­</¬a“k+À> ŸÏÅ}ŞdÏF½y¨È•’BpÅ&ª3#jPœ8f_³oÛâ5’[“™lò«N6Æ2Ğ ^*Ø±§SRL	á6Ï ÷}lê®¦µû]Ø{¼š¯ñUŸ[ Ehıñsaô0Y‰NŞ]éóA¨ôEı.ğA4â4ÉÙÔËÃ¿JGÆÎ®½…@xœ[;®6Y¹ø³4Ó&æ#³f^é5¤ÅÅ^îaá&/qÏcš¹ëİxqŒìkó>ùV î1˜‡	rĞ”2$@‰4JbCú#×´|/ÔÇıB6ÄsX„œNo”
èibê"ÊÄ¬k1º<şWédà­ö¼|,ºb“c± eøi™5xihp:…@´1"j_SAÈaj ëÓy*-şòYÁëG#óş„t‡E© 7£m\›¹°ç¸ûr.a}×uÇ®C	dl»Bê0©ØŠ("B&!p5r¢L3è¥ãTŸ;j¼r„ßüÁTçTƒ5è.·jûúÑö`€rÿi¯R÷ba³üS&	ÁÇœ4qîQ£f³KgßÀÖú	‹{´hˆr…JŸ¸œŞCÏAÈ0ı·VÆ5¸r«c^qÚQîĞ_¬‰]â1'R¿½²‘¡+{mÎoT»H‡éşv°sÓÇ(—>–É^tÈ”ü„*r-2!áŸÙÕã},ş€ç´¦4ÑÍ¼Ñ£šö×{â­æë$qö¦€¤|)™‡NB¨¯:YCß…+'£Œû½,dD6Üîz[‹¬c7Å:ç=ßÏ_€D\1täõ–Jp•Ô÷BtFé4à/÷*Ç»PJ[ğıªkõs×†¬±Íùã¬+R½á·é‚“6Gèğ ‚W'j…„\n_:)hÄcäs÷…Ğğ2ì§màíŞÛIğ4‰ÍÂµ¹ \âŞ:®®h)LFÖ÷ÑdÄ…ş¢¨ <}İ3,ZÖÊ.ıGzÜÏ±ÃçÓî&®®ğ¶ÖØwªÎÜÚ"›4ì/R?ÚZe=\9¾ã¦×#T7Zç?Jä*Å]æx‰İ'Í¿
¶ L¥sí<ƒÆ•‘Ã¼ğ·`LVÑKÂ5=±ëË @üvT(?h†DkÿT€=ŠyO¯°ãàZÉ}H‡T¶¢éiÔW›)	ƒ}4Jg/ììO!f;¾” ‰ş«:LVäÄïõ\äÍÓÍZSéÅÁÅŸeØ?zÿûïèmãŒÊm,º}2æMóïEç|E²_Á+¸+0mëOnóx•jM6Ğî s&jbÅãıpÑ0XÿÏhÊ‚XÚŠXE7Òš=n1¯Ş›øÌ*ëµÇ´øVøñAıAÍe5g
¼v»
lÎ7Õò‚Ş¦æ¥ó ’°¿NHÖYš+D6úç|õ¬vË-SĞˆÚ}à˜¹O¤×¾~3¬{íe
z–¦tÎ!¨³9è¾$WF°^n#‡ª’ÓixÚ<ÑëÙÜË,>æùØ'à€íÄc0h‚*o%÷"?É\x7{úùD¾ÁyÑÕÈ‚áÿ HüQÇ<G¦hbÚD%şö•íéõÂITGÎÿ†FìçÂ7È’–ÁFQÍúü°e¯§Ş„2Qï£äæJ¨15ÅøB!F-ú ÎÈ¥ìÿÜ^¸½Ö‡T¿¨{/5£Ue1Y1ù#ÖÎ#økº­ç5e#%ÊÏ×SÀl,¹KÆö9	SKõ¼ªÑšjj¼m®Ú¸¹ úiıÆ›¬7îÊıPím)ç†m·™jr¼1ÓËv§ï®P½¾y~n¨âÆ¿H™¹
"|œBH'Q§4<¡VnÅš¤á¹ ™w”œ( øÿtÜ˜xìJô )06İ#Qÿ4¶$Ô ßãò*«eÍ\±Ğ]ÁÉ¿Ñ©¤D·®½5³rdöb¿‹3‚öõÅ€›¡ ÅcR$€Ó’·®e‘46ñàkì#_çÖË	Qã=1êq#Ø İwá_¿[úşêzÚİ—»¯Q™NK/D~Ä^£)~îÿ‹ğ5‡<­édA%¹ùî aENÀlºñ°O¤ş7!Ğ|š§e0¹ß5àøŞ·,T!ævs\6ŒÙe¤M¬6¢§Dd¢¤sø·-ØçkxĞu©\ünHW)¼êÂÃÅhıº¡Î•#.Õ1>6l>ªvœ‘ÑuĞ:‚ABVH‡=‚Ed÷Û¶¢JÙMÚH[°6¢uÖ|ë–ñ¤¢¦ıõõ= "WZp *­ˆb€M­µÌ3¶„ÆÚ^SÅÄ $@ùß?^¬‰€0zŠ˜ºªcÄú˜ú7÷EúW&cq¸‘§¯”ı)ó™ö„ 6æÀÅ{)çà9A‰±¬İ*ø¦^áù„ ~%Úü@ÍÿÕÆ{CO³¨•åìÆğ·9cî–@>:Ş¾«ù³
SŸûåJäÕÎQ@b¢ÖDK®Å_¸G¶O‹Q_ÛKzhÿ›¬Æ‚%¤õÔÖ|ÜAEÆQCgò¡!Ùº/¶?	AwwÁÏ»rU}ì¯ÎÄ»¿BÅ$cé,u]²g¯­‹¸7Ù2‰¨3C1„*VÖÿ—ìˆ)ÚqÂèÖÍJİä¾ê,ğ¾”JÖRu+vÃ²}İ|·nH˜0rŸ pÕ',av®íôß'êÌ@#Î½±3¤«Æ:ï=ÅÓˆ”
†;dÂíY§Ü¦øŞ:Rø‡ÚÌd!8/¦®ğ†&ò{\µaC®\ô¦x’V'#p¶ä°ZKi•IJæ˜d‘Á'ÆX2&µGØŞS¨S—³:â©îğ
œ´¬WƒÖÚ–½¡Şaıã9Ë–;QœB8FÚ?p˜UÙ ²°—u0ÌŸ›•õ&wYÚIua»½Bo‘é–ÿ(¯ˆ¿Ú@'resxÈ®“%x\1êE|Ïk¤™tÌè®èsÿ*„?» ”+“c÷Ö)-ONİ§OXo-~bè°GfÁ½Ïîüx\ƒWñşÄŞŒ’KMlKíŠæ2¨7ÏŒRíŒ–°~ÖéG¼›V„| õ¸9M²ËÛ 0åXÈÑ3Ø\­‹RÙØÑ{ŸßdHæåndJï•À4ŸçC‚”3S•gmE yoíz	îSu6ÌåØ÷à?/ÉÙ¾‰N2˜?¬nK¶Gfê°·áª˜<c8òÚÍHÛ$2‘À˜|UC ÍçÓzd%÷Ÿe|:õb›ŸÿÀ–c`õB¬Å¹ÔI7É.ûOº‹ 
—,MN–6´üNr]†?>‰æ€áÊ¥¢¶
(şêZ4O(›b9É¯Sÿ ´åÀÔÓu0J9³Ç°R`Šñô7v)’¢0ï1•1n9Çö.jc)µ•Ñ{	T™FÎàÌFšFYIíÑK9Ì4xêê,ø“‘İ&¸¶¯<eâŞXÖFX‹âqê<´ç‹¡Şó€	Ì‡i…Ù´Zz–%{¡GNµšµ
H~P»Ú±ÔÍD¨]qÀÍbß“ußqÍÛÍ„@ÏQPØôüj7·Û&$ãé²qBîĞ#(u± æ_R&©¸~¼[‡O”x«ápä‰\ÇËÃ,ëóZ‚ğxÿg_ÄGuZ¾E¹ô}÷¨µ ¨K*À‚ƒpô^ªYò‰ê?è-
“„+øGŒÎõ€MM¦{J*s§ü-v0.†‰¥Ü(úÍâ•÷„?É*lVÜÌÌ…Q[`Œ—aq§·Qé˜-‹Ê$”IÒÁù=q†µ¾ª2õ•nä‡,pÕ@Öên¨ã€I½m˜– Ÿ¡sè±ìYó=¡‰W ëJÒŸ¬³TA¤ /fÊ5ëS°’PµóË9Iù”œw¥gîä/Á{v=.nŞ[ŒJ¤êÓµ)fÀ“¹(s_!w(¨Ø/Ô¸ÖƒÃÁ’/W¼B‰“è‰ 
W¸ùŒ?»cëö˜r£¬<ÏêK |^à|»Q¥ïÂu8úQyë¢Šº²±{"ZÁQ‘õ¿°¹Ù»?4ê¢º¼ f–ŒÆªI5zF³á†Ô2œ•…"1S-H}<W-à£VÍ…qø¸MMqPÉ•#Oi'i×NZF$ÄËï‡LÕ¾PÓ1ƒ±¦ú|Æ]çİï-ç¦‹Stw«æîğ__–ÑÏ®D8Hb“®š+5¹T—Á›ÿÙ¨÷ûÚ·£L³6c¼Î¥
6HÜ!å¼¹®\ö|§Ö’bØvpëø¥æØÀ¡ƒœ‚3µ¢6€ı©HæİÎ¦b‡Ï—0Ú»Z]<5œp;òGğQ/ÜıãóR•%æå Ûî“4X>x<kªîE«—¦wu5~îÊNL‚^îÙ\U˜—Ï£ı	²RBå¢ú¢Å ˆg„ò¦’™­/ÃŞ>Êı‡.Ó5¬”ú_{R<&Ü;ß³…‹%¶îj9·…óÁ9LYF²œ,{Ó¼Ô6 ?cª_¯é©Ñ¦£Ÿb˜Ÿ¬ù³“UÚ(È+àÖ¬g;‰$„e\¸Â×Ğ×Á¶U´˜Şì7TÅ$jKu*ÑjÎÉ[sá÷%e¿¦k?€/“C…¨‘ÿ¨ëFKéç†=ÏØóU+ÂƒÎõKKÙ$~m*‘+dJğÿÔA P™E"1 2ùÌ³·Öxß†„iA\ö{§æä§,Yì:¼èÍA[Œ(Éüà…26“h³%æ´yó	»ô
 ³_c‘èq™˜z³á|¤zÆfJöÔ=Ó¹ÿT€Z2İÌeÂJcLÌÊK^WÌækx–dóCF‰,ı¹<êµn¦(#¼ĞÍ„WEˆZDJ_ã`¢fE‹sØŒfYRİoÒDƒMŞ…KÓe0÷xà§šÕ¯|h°ˆc)%¤d7Tg™Ô+ÄàÈıı¢$ ˜b¾÷ØÅî™_c@¢Â‘}“üÜ6³mg…Ş…àN?·õ©ñle´÷ê›ÈSøCÀÚ¶|3Õ°V”pjü‘ÙL&TÈ¾¾6‘fs0¤Ü%uİ²âûe³-{ğ/u\‡sÍ3üGû'#ÁÓá}[÷zĞ>dßhÏÛÕ<¬æİÓB·3û;gÙĞÉÎ)ªeñ6Îú´Y7C½àâÊ>2mÃD‡ÊâcÊQÂ†ÎË¾å˜?x3Wë
ƒ#íæ	§Å2}É œU¸ç—Ñ4¬X
ä¹Ã¶x üĞ”½î»Fø­áõÔé ‘Ï/^l*« ‰¤ó‘äúÛ`ñ‰Ì½vRõD³ëŠÚÛ“H„€Òt¶„ÕëUÃ5ò÷ˆ<òxíï\ö;¸$ê}ˆÕ“²œnÙ=ôM0$ @ò‰jà\´>ƒKúÀHi.*ù¤øZrÌÕ¤­Vµ.Elf~<2Ö‰t­Mt²ˆÌ
R7ùÏ	»Çè°1íŠÑN–gaN6â;.¸´+Îó^|ëÖ8âS³‚h‰¦–#ëÌ›O÷»¯ğSØ÷’çÍt¸4È´–¢µšëÕ/y>¼5@³GÏcÂ@( ¡´„o”H&|ÌÆ;ÄĞ.$¢Bêu)jÍdÒ";qIà_lÑ¶²ek:2yÙƒtH§°IvfâR¯r½n5`†'äÔ[*ô|%&b İ}zA«t€üìÍ ‡sêB’!¤	d\*$ÎîòËs#$YY»oŒ¯¾.‘ÔVüaõÇe-ßÔ,$4GÄê&oğ)¡ˆïşº½f¯k5}!1x)l/§\<E…3“™Ÿˆåeüs>–úqí„Ï‡>]½1vÀn¬¯a}œ¨1.Ô5 ê[ïÔÇ”ì#d15IØ—ÆrSmµš¢rºü¦£¦OÚÇS{ŸĞ“Sçó­¬Ô¾^N…î{Ú¡ë!@¼÷3`‘ª˜«–~ñN-=ŸÕ€¬ú´àÊ×íxù¾WqüVqÈh6RÄú]4—W|o”(’[å‘ P]éĞrk‰Ì_õ¯fÆ+ß,’±Â³­‘G°—í,„ÙÖ[ÿ€dº+–”È„Æ¯â0¸’“d)´°x²YúÎ§à^;x‘¸½?ª8‚P\¿‘DÀæéŒ["±˜×áx—©:ÀÊ5ƒ2b“}[ŠÏÆUÀ…Ò÷I^w{†IQtÖHíNêØz…Ë4stç3Ó¨ÉĞßÔHèwí{a(,¸Òn¯]hÉ¡¶ë3?<N”ßâ –TIfÖ%{Ôºó……uÀ[•N-/d»8~¹ÿ*ÔªìN"ÉÂ§y»Š³t t€²9¶ï	ôYLÁ Ğ(ãŠòC²„Q)œ|é¶yÕ,EÿÃ_vıUæwp5GÊl|† ÿ± ½I8ëçtù†lkÄ;èQš”ÂÀçO©d"e,¤¢rÁKmù‚aÏÌ·4ú©(­¶øĞ0[øÂÁ_|n HÔ^äS(%Ñ3ZÃPGüóæÓ'“;ÓÈG›øÑù)/;ÿ[û™(ë°On`×Å÷Ø/êK—‚±Ü<Ğ13ÈÇràŒªJ5’f^3˜^§}ÖEá­{ßBy»TÄƒzR‡•éTƒp¾ì÷Óq¡Ã(ÇĞæñöBª?L¥kŠîœ_le‡Ÿ×ebvá¡å¸X '¢AÙâ©QRH3ÇéúSæş``T·fpz"ö¨¾0„V­˜‚h—ÖLM“ü+¥îÔÒè~b$\_Å•²Aq†ˆ‚ÃµjtÂ5ş”ûïÁVEm‹oòÄĞæöAàÒ’œŒ&ó=§Cq1#PNr°¨a#SŒûiıÙšLÊOßßlÚá[yT¸4ö¥÷Û'„W ¡wfœòÙ0ŒO÷=Í0ªâ}sªwaìrê¢¯ËÓ!Ğ9I¥+K:ú
³ÛB··6Çx‹>n5}¢¾Œ™ıû:¢bP”ÂíKv×ğ5>~;µ=ÆQ»_è£B™ùî×~{®µä‘×êœîV©]ıÏÇ3f,f¾Œ±¶³CÕó“ ²­‹À)ù¸Yş/ióeÖõ=)oP’¼ÜÆ(¥8™Éª2ävígŸ!´– 1"»
œ#/DoâA¸{ş)6¿q›¥'4ÑĞöÄ|£œ"Qåd«òùèğ‚bòšnóãÓü5Ğ,§ÑÏ+`èf4x±&òçLƒ™±®¾f}ë(Æ²JÆõ+¨WÛ'²Œø­ÆTt²áá=yWÙÃ8[«QÈCpñ}µá	 ´‡ézˆ¹şM;Éq\|û¬,¥xü_î²ÔQÀrYdËëRR‰ØBhæüZ4D_ÒåÎÓ/å£K[o¢²ÿÕ¨œ†ZC…Î1:Ãs-QZRØ|qğ6¨,ÎC{Õb(’¤ìuªíæí[Ä_‰{Ğü;SÑWûK÷T+<{>oÕÄuĞHHE€ãºXúš'ôS.òâ ÎŞœ:Y!?Ëõ	úm†W”Rái”ƒ p­ä±ß3\ÄkkÁZ.·sljívrŞ
^%ï)À"fwÅ7µçëìÈ§î6vçê3\a¥TÑïBgÛÉƒ‡FÄ›ÅØ®ƒ­ÿ)„ì¹¡eqÆº*mê×}û§Ã®>7JÂi²Äú+ÙÎUcu?­]½ËH(âPWÚàïÔöºšŠ¸ÕHl‹ù®ÉBéI•uœ™óæhÒ¾õœuºªÛêÈŠ~ÙšıuT– <=5F«]Ì|Ò %©ü‹MÈÌÀ™æ“-ßc V»'dlÑ³aHr‹eçıãH±›Š6køX‡¥íJöÑÍw–LpœVeGœ +N‚±G£¨Êó,Á•Ñî£×¥ÿÒãkì»c­c¥ª°tÙ’ÄnôìûîË;¸öfxfï‰©ò#ÿÌLÚÖ{ù	‹áHÅáj+H§;Íõ­;û¸áÊ¼:3¶gÔW¡Ñ´ñÕ9‰`  ¨t, @Şe Û¡€ .ëè±Ägû    YZ