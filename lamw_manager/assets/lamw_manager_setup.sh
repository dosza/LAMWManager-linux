#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4122994014"
MD5="dcd93ba75aeabe29329bd29979102d21"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23972"
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
	echo Date of packaging: Tue Dec 21 13:11:01 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]d] ¼}•À1Dd]‡Á›PætİDõ#Ü±®¤3k`æ„¡ëı5&/ Ì¼øCİ7Ãl@¿×YÈ `Â|¶((#9ò}Iã
š”Ô¡„÷c¯²úÒ>+ñ³>v.Enqùmõ áşÛ¡à“	øëk¬ÅA85¿¹Çówî0#UO=ÃNÄíjş._ô	–6_YWA»X99Ì|ÌªÑñ‘.åR¾KÊ)ü¯lCõåĞ'ò†`ÀÏ¶l üÊ+¡µÃ’1øèšM;m«íÉ§Ô‹ƒ$F]öÌ†7e_ËŸª©D»B~D‹Û¾K ÍºÒMœ5%NfÜ¹m˜ï '8`Ê»¹Dwe¶<a²W˜""©ÂÈP]®ˆrŞGV7„Šô‡V	#%Nş5hO†#	³‡˜ö“Qµg¸”—›ló=Şı²W(¬¸­+ÖKqMY!8ÕvÄ “”?-û [ŠâÃ“˜©¹TÏÔ<‘u†»Kñ¦–h{3g¯õ%)aæ*€î¸’³äáiÙÇ¥Úê–­¢I„¹ü(ît{~KÙÍ¡§-ÑZ/§ê!f·É¢°ùÂ`±{ìÂ‘YyŞ‚uÛ,“éğ‚å0¤LuK&	Î4Û´.Ä8Àå	z8RUÈç-¤@©›£ìAˆˆÈÈ…f «¥a–¬l4l " áÌÚäå“M5£z†Ğü‚xˆIfÚ%4’–eñ!#®ü¡Luû«åíi#»cpÁ§\ îjnR`$‘Ìa¬2ääí‡‘ ÙD?™ŒYRŸıÙb°Î%ˆï™S¿û‚ÏŞ«ë×ìàÌßÓ4x s8¼yÛ´4ÿ©TèîÛ|Ê*¤?…¤ÑfÓ€ãÛA6=0©4ù÷º®ÅÍîÅ^QK¿=38²ÇV<*xèÃÎ%¥ß[kUYt»˜
MüæÉ8ü…²Zô
jâ@rÙNˆ1Öi#…ü'­>ò@¿ "gı.—ÇT•h-Mn™ì=3¾J¹!Êô^Î ”îqï‘(X°)N¹<4Àf‚ıİ£Ñ­À 7ìÅy…˜ı‚3)–jŸ¹8H6°º‹ÕFÂ…èQÖÖÿŠd‹´€:–ú¹’75fŠ©Z8[uòçC[Fóí¼2_öGñÃ0Qs‹ñkyÜÀy9qºÅ…KÌ,ƒ««:2/Ô¡)HëY7aæÇšåãŞ¨c[fŠÇÅài¹l,îÔµAHüdb¿lYÒˆÛ|ôğ†1?dU~FSK%º^_6_<®¸Æ¾8V›ªè²'Ë*ÜeËZ
g<yÆ^_P¸‰½ªåCbhbä–ƒAq](Æ;£´ôÿz E ½×nÏHìsX‚ú`˜`øÔ”‹
¬¤V«rã€™A¶:ÊlÀ+™°ÙÖk'GÊ5(“€·‘yå”–Ìª:2¹Vwë2 €%ğN×Í¢÷3¤2djp‘/¬qğ#{ñœ³Z¨¹i¯Ú‚”Vhw9&éÈƒ’·J9Ïlw¨ÿ²@¡õˆFMÔ¤W8ú²xÑ¬N¨å Æã*‘Ôø+;oç;P&4û€1m±³S†åÛ<`m0(¨ëRw×¨0dÚ¸G¦)ÿü4¡c¬¥q5á&Ô[éÏ^’ïCc6ÕçéPƒtós¶Œà¿Áz2~Î8ÃAYç×ÒCt"Í‰8ù0š\\V‰³<¿OØÃ³©
lf“sx“(xLÕ1Ø5G+f`¥”!ô
» „–šÿ’wkå0À ÏÜµ›°´i¸·V¾à™$Ù“ÎŞ‰w™ÀñĞe¬RPY‡äÓ·ÇãelE§ğûtŒ›m´÷0Ğ®ëı)±„½ë¶*B8—„U¯ƒ£ ;µ$.ŞÿÃRßCÎg\ã•_(ß¨iEI±;÷!ì³p¾²]?x¡Kø‘¨.·d{	#`15ó ¿åIÊ	¹F}}-ÛÀ
©İ5n˜èş7\9`ªÛ¨G½İÛõyÒ3Z^\Wœìİ?Š:Ó£û«ª©«•sÅü]ÏS«5ö—Ãé9;b4øJ ¨Ù»`È±ş]Oë.Bå9ÛF†<3…:KÎ˜kßXÄñ‘ôíÔ¯èTö+¼´{ä?„Ìl…¼ÅøÀ]¶{ı¨â¤=½~æ²”Á˜°! ¹(PW?¡éT]êŒùÂñFH¥{xaôšùEˆ‚u¶š'Ù[õÇÂC›Ù7á«˜jÏmè	©-­ômEMB1)Ã›ŒA(!]{'áªĞo©D«»·ÊÒi´O @´²ËZ‹äj}Wù&Ó@ø¤å„p<„*ı+1ôøƒ_9WR§ßÎd rz¬öŞH<›„ÓÕ{xí?ïp ¼Öò
åg6×-`>h7ß¾É".Ï¦ãlQˆ¸äˆÿ™G5„“ø`Z ÷ŸÙÄ~7*a®ı¤ÜÎàêâúı	•"ıDfhAÈœÁ{•®Zj“ÇÙÌ¯V©ì£ps™™in²RMÒ°OšYm•¨gÖBÊ¨/˜d¢çMdöG–{qÕ~îğØl¬	e!N³û¯-ÀÔèK¾xAoNºårzµaäØx·
úø‚%Ç¬â—c2’ü7µŸú&8È®º1ƒÈ˜á¶ŠÛ
êı;19¶Z(øò¬rS¾\CB#7Q—«ëİ´qoDÜ§Õ¬<“Y³óqJkNÉX¸	E²…s§¯ö°D\'İê{ár¾µØÂÏe›p…#j­ÙŠÌóNBë}ºhUŞ3áÛLè÷ÑÌh?˜ıy•¶ç²H£)YNù”¶–LŞ~×h{…ê˜oÖ^ã¶²=KNĞæƒÙ<ú±zÛ«ëZÛ“Ú 2 â5y¼BŞuV‘ËÄìê¿<Ö\ÜîÕá€Æ å1”“æGÈJ×¯!  %"­œ4O€óZø:ìrµ!@ÎŒ~„‚Áe8¿<cmÊ¯(×g0I[– ‹Á ørW7R%¦”:ÎfZô«Ì‹X\¦×Õ³AÛ«mK_Ä4C/ä2¦ú-·zC<ÇhrŠMü¥Õ”c­³IXXı”	İv‘j“Ş/»ˆå¼Š~C'rÔŞ—öv’RÏ0ÏE€a=`%C}ÿX2Ó3šrÙyQÇ¹`F©­6‘¥a¤¤´î	ÓDñ]ópØáù	~8‡ç—ÅòŠ‹¯Üg§åì'¤j @À¬`fTÍ*¶¾ƒÒrÀ¾ù¾TXÈ*j ĞÃÀW¼8ã9ŸnZ*öºJ~êd™mˆÏØ
h ³ŸlÃ0¯¥7Í"XÂ3YFÇjÁxUˆu„€Cˆ•ä]çvÉaFŞ·Ù˜¬İçÜúcjV8»†ÛîÖÖ|š•<x=Ö^ÌM69BâWoáA3œÛõE:7ÿ`ß#x€w<¤³ ‚ËMRZ†BÖw*V:PÚÓëMërz»¤¨lchè¼SÏ­O dS‰’,öø9Óè&Ç(ñ0ŠWÏĞ0uø.ñ_3Io\™w¸öáRl´ìTÑSDÉêÒÿÎqğÿMÇ9¨ZDçÄÌ—"ìÀ™òl«\e@„#ƒÅ‹‘Á9œX+âh=g0ªäÜÁ$¤_k>“	ü«ÿsÊÚ2Ÿí v„¡™Ò­Ì•Z‚‡¨5Mbzl)¼Ç.4ÕƒÆµoX-ÓÏ@$Ç®€aÍéÍ"‹Ë\.1xĞa«ã9Ê‡`o‡#+wo¼dÑe·˜esı˜Şéq®ª+òşÃ8Å·ü)Yø|ÜnŠÍ‡í¹{ğFüX-CH1R×òÿ“{æ	%`Eh¶ĞkÖ¿¯Cø"Ù]ÇVås5@]Ë,p~ÆjÉ†>Xi¦À¦6XJrúÛ|Àú×wƒ ü†KXğÏ§>5D@ENäÙ©4 İc—vÅŠu¯Ÿ(Qñ``ŸËäK~„²JÈ»¢Ùƒ-^$\d¨¯èQj­?‘rC5Œfõ@«¬Î¦ ê¨°og¬“4çxÜX|Tˆâw p'7kİ½oúí41]ƒÇ	@Â-Dp”mX#^Èö‚¨îşŒ¯"Õ!j9áZ°§¡‡ÜĞ$OAa’ØÚ‹Û·wlnñâeÁå¯3µ…ûÜb‡Ê´'*»Èáé`»3Í´<”ØbçTY…ª,%9æ+‡I»z£kôK·;‘Çûê§áIøÏKÏÇ‘<]²¿ØO›;ìSÇWşµn¦3u¿@ı’‰ìæaOş1ÔËúÈûŸÆÄ¬;#hx¦8¥»(éI„T"f<ãb9Ê{Œ§ôDJ§¹„­Öce?µö.~ŒÀ¢_ú3Ê>iV¿N&¶`®ns<*ãÌÒ~	(¸¢ „ø‘z+Jç®:7zÓñåá#?sÇA×¡a^B	úéŸÅš€U
}ÛKójÕJ¾Cà•õ8Š(À"9ZÛâ$%¹AŸ¢ÉìœÅ‰}ØüQ¼»5õi·x%ÁÖ¶ÔlC”ù…ûŒY7fÏOÅ¶:·İßjä-yë	è¼Á.Eşw¶ÑÚòæE÷µåbè„EU&w7‹!|FwevŠ,7À
ıÈŠìê4yÏ{‡ÕÁ³ÿ˜N cŞ@€ÙCŸã)VÜT{–;âm›tğÈüyXè]Beü3‘­ŒCˆ‹Aº×ß»ÎíJËŠ[a¶T®Ü°Ê›Õ©®=ô”kÁ»]_ÕrVXğ5©‰C
;ŸÿÜ~25j±™M÷g)¢!°P~bcûN…Î»/åS.+İ·š¬¼¢¸´î÷A«>'¶ä?¥FÅaid
wA QÒh¶íuÛ`mÚM"[pwQ³fÕ“uRÆÀà¶2±:PÑ·Â?`ı§?™+Ş·6<†¡DbŠ>è@Ÿ®îYéñd086y®\­Şy\u>ğÿ»şK4î;,+b|òENÚAµš•JQÙ
V¡›ñÀ[÷‘ƒMŒ¹hø4•, l„v»âv‡(âêG4á„~2Y•O)Æ£ß)uÆ¨¨“x9ø>%‰æ¿k¶İ°E8²Åoó#ëĞ¢X3Å.8òôíÒ!bÓÈL ³ä‰{jLÓîTÆFª9ëG‡à½´¸öûÂ¼Q_(ö½­[OXs:å$Í4coY¦¬™
c1Í ^äç-Şÿñá:qBÇì·¥˜)‰&åcø­ÒFñ¶¬Ï+œY˜ÿ\†~OWíàáZ«P'´tóB»°_&­ê­»!}‹ß@)Qe5fMÄu¥Æ Çe‰CË·7ßğ÷p1­Ú ¹	9¤ıW<hŸ>¯»‚iáIäÙe¾7^`²jX¾|«V¦È÷õ‘0[²ç¶=åóÊÈÖ1½
Ãáèé„Ôeu8ıd´§ fòú?(Ÿ-æ!¯Êô«9Yû¸Âeêe¾mˆ·>~ª_	é¡/Ò ]3‰¸¿:«ªQC¨T´ˆyÖ„‰çkyp˜®e\ã˜xHÜ;GxøƒEˆqî­_²…²©Ï…;´möxÀ‘ùM„«Ioù×ÂüPhäâ„RÍC‚m÷T½„ºß¼8·-wL·7ı~n	¢‹±yÅÙ|…/÷@ ğş(³ùQñ‚éæğ‘w®o»‘‡Yµ½_œéÉêHoBÑÿÇ&åãº/‘èÎ[=sÎYÍÑŞ²
<¸'W›~„¦rôjãÃñ  .•ö¿jº13ñrN†ªİç\v.Ô¨²ôŠ1Ë‘h<õM¿mpxàW†ó(»$#õdPBí|8+j…›ûìn¨íã,‹u¿¨Yişã¬8×ÔOòm@Â?Áb‘ô»¿Ëœ©…jÑ^”¾okĞü%€=¿qº‰/.ÊÏd€”Î†ápÛÊ M-¢I«á+-:-M[ç«l¿Ô¿àà'àÊh’†;:µvã
µ‘~­"€¬¡-|;7ÿq.ÈaN“èv?ò:=rçTÁûÄªZë3jD¢;w½úåhä…;WWãù
Ã2ÂÏC2ØrOàõÖs–º¯¹“CùÄd‡VQ‡ªæ²bgMkä´¡Òæ(™£¢Ù@Kx‚µ¡ÔN„¤¾Ò÷×.ó"¶èÚÉ»ÏÅŸÈ™<ØB¡ésV›…0ä©M&_ÄÁWzSé‚s
Á§qŒ;¶ÑL?v"ªÙã“›˜áeHEœŞ[
"ü“ÕDV0,qU• -Íi0ÄÏõ:ÕNJÏ(qo ø)NUêAmŸÄóWa!Ï'™µ/p¥Õ qp®Ã†3è•¶o\!öüª­;“jy‚»è!køCo†"&ÔN}IEĞU½š\ÅŠ„¤ù°`­¾ò4&Ê¯B°•5Hq¯ç6›%ùĞVD±GÈ5ïqvÛñ¦Ê_å&Wj"{“š+ëIf”¾cvå>ÖÜìïšœo*ÈŠ¬ˆg™ğ««åE\Îˆ6*ªˆ™ÄP-òÃ=ÀÆq»¹Ímó*,şErrq¿×nÍ¿Wå7¿ºü‘ŠB…—Hš9ÕÁ‹}ÓO‰l¢8l«O«öâ¨8‡È½e$Ìu±ï«–it‡ÿĞà¶úmN¦uõ–ÂÓ„°9Ôß©qüœv6G™øÇÁ2I‘;§?¾_|7()O ÿsÈãîÓWL¡6 Ï¾"ZšmS¤†IìÀœİûh‡Ş&Esœtª|TLëÙƒRÊèèŞÑ=<QÕÆõñ>nGx2~ÔæÊÆñ±$Ôr4úc#Õ–âKÅ¾ÇoÍ9ì|BÚã‡´sŒú?3UIœ¯£‰Éç¸ük\_ ¿(Vï?×u?eÊB^&„"İ<Ÿ˜¬&Š?¯°ù;ï&ƒŒe£$‚Ö¡Û‹´îÛ™.\ÄXgšÙû 	Ş[Ãï:NáibáB¡„š‘^iaZ,-ÿ»ï©n=ËÄÜ²OÃÉ“Épû›5óü¬¡Ú ‘f¨Ó€_-¾:>ˆª0–şiV”iªX	s™}»j‚-³k˜º4ñDÕd“Œ£óÕp7§3iÛ|ZJ~zWB†qØ×@5Ï+C-_‚Øh‡ÒÜÛO^q•g=ƒV¦cD¯İ9œá\$ÒR¡I¾ª)ÂšÆUÌK5Ó„ê0"™Á|Ü˜fñ7áIt+¶Š€›‡ĞËñ/“ïD›ƒzºS­jW‚Oà©ìu•‡Î›Ø‹ùGüÄ‘ĞF *Y¤pÜ]W=¢ZïÅf¸XÀÄ»ç¡PGÙVÕÆ~&ûy^Üë-µwú­´Úì@9÷æQ‰-Ú›^ˆxÇöBÀRn¼ Âj~ˆÆØ ÷ê‚4&ı^	j–LÆªöMû%İÂE5»öóC-½;‹ÇœN__£Ú*9'ï;p’ñ²%–·\eP¬ÛÖæÈt]ƒƒ¬çÖ\
óÿù%jÕõÉª˜Š8 u<I,Ïá5T‘ä……Ÿí‘âX„>£GÓ·{>tW»_cÄEÙY¹õ…Æ®YÅşÑf2Ñ´›×å¿«K›4ËC4ëäl‚ıÖ<c9Õ]7C¿*'A[ŒÓÄK£*éÂ"%„0`¬ßæ˜T„ÒêÖr@sİ7ÂMWP·nÙø-z~Ò³»LO2¤âG‹kíWvmª³¿)Kî¬&5ıøÔş¿)•´F>	1o ì†‚‹Á7L¨»î*Ï¬Òj¡OÏ¿?1LãHYør ”Dû„µ#}dhŞk«˜PEã ÿv¥#ôÈú×Ÿw¦ºjB»£ ‚æÆuµz¸	>ÄøRÂ‚›¢!(ÌT1¼#^CïÜ¾hVsí‹÷DåOjU…‰5KsÊ2Ù¼ÒûÚĞn\ ¬}4
qıã§IML“3¹äÉ~WukçÉ@`Y%W9æ©IK=ûDVHŒoC/,ğğşèº—Å^u=r,+Cã´è„YÄXÛÂpĞ
oÆun"¹ °É@¹ğ¾ğ—£ŒÕ$e€Y>2ñ\áÕgÑwŸûÑ	Å}G î&7Z-2Š31¹ósµ;Ú‘$b$Ä2/†I½bÔVÖz
öÒoÄñSÍkÙÒÁè$õœëq]´?(> oÑ˜¤&wA÷c$^€G³İöë;-H®ƒcØÁuæ‘êíGº¨,lÏÌ	ÛqÀ{ZæIôèmÃŒÔb×„ËÑŸĞ7óË"
téaÄíazÿnÆbå¾	õ¦u´6IÿÅ†oÂÂ&ØõNZ°ó(®uğ}y”Ò§ÏˆÇŒwneaïÿû<íju
€"ÔFwƒH%äEë˜”X›‹øİ~ J·MxX9¶^Æ6?¡?j'óLp-­LàL[=Õd@òø‡¤¸ºseùæŞyMçÏÛ{j8g¤1µBõ8¢Æ³6ÚƒÍü1$xµ,Z.ùknÛ¬2»ÂWæƒ’­s¡©É5®3SÆ€_¶½9%j9ŸF:`çİ)Â0†wo›ó%Ã90TÄ
WútL04…Ş”jP(ul&¢k[ŞG¤êË„¦ie_3£ÁÌE~.è¸P”2jñ9È³Eí	’F ØúyÉ˜"P×ëE¶Şxƒñrã-kÚP¶yd<ªÕìüPdĞ„åŸüêOÇbeÙ$R ÁëÅı^{Ó*ÒªôõDüêßë°ñ&Ío­i9‡™%ò®.ÂÅà€©1+G‰dÎ‚G%®ˆÕ04ëŠĞ@ñ—o*½Ÿş<½#\{M*¦ˆ¾3il‹‘·©ùº­,Ò#–ñ
6
–bİ>ö¨ùÄÕIÁÿøúÏ(jşÃ=—–Úı½d¦@SXv@g‘òÓÕ5ßd¶3«Š† ¶‰±õ¼˜WI„;´®Ğbã‡n‡z¨Q‚x"¤Ø®]ˆ`ö'AÅ|Šˆ\ÀcgÅJeCÓœ
MyöäÂTû;	ø&ww*uGÄ&ß%Ş—/€oõîˆ†æ¾mjÁİÏWm„øşÛ\ï®«CĞ$üE#önÑçr5¬‹Ø¤¼-Y–¡îÔ›“+íUôúúì”„D~ÕæğÑ\_òÎ¼øoÇ˜Ìã‡|â|ê•š¸Ü@gYqŒ%¨!–f Q˜¢Ì‘ag¸1µy[ã¹½k"Œ+«K5IrÊÊä_¹ßêÀl(ğaí•OÒ^ø`Õÿ¹s\ŸJ¬t{Ñ¨^2˜¨{–iú.7äy9{`ó›ªìßH¯æQ§µFÃ¯ÓGİ8 ±`ƒà9|±ÜPYdÃ¦Õ{P ö\3lşîoİÂ K¬ÚĞC~‡ø½±‘ºË¢¬†RëAáƒËóIéMĞQ=F$ù öµ€®j éµÔpŞ“&èÑUní8EÚÒûH{{Ç9K3YB“H0®çwBd$¾ı·)aY7®ÀÇr~‹|–R¾»”¥åú K¨õšºD*NFÃ9´ÓaĞg..<:¶+v‘};…^\<õ#ªO.ÊÄWœ/oÒ:¤ì TEñ‘jôQb¸èo‡„{HÆÔ}¾ü	úu6Â(™Íµ‘I8—Ó¬‘Ël¤¹¬ÒÏ­£?ş·ÿ_® ÚGHßêÃ’ÎJÑÑËI>ÊHr+†åbÖ€>"j6òÖ†Õÿy¦‡(€’S¶*æ¬+•Œğ«î÷&"–HpÅÀÁV¤ÊÇ_S•1>dõOu³AÃUË8ë«zôş+OûÇ2xÓ¯N@Î:
kÚı¯õC_§&«ÿ.©+­B"{ù‚:|K‹—şé']7_—s½êt
Á76ø“å¸*7O»RíC4ü¤½7wI&¦a*€ñS”(²§m¥0ÒØõÓ]èw"×x†NÊàÕ\GÆšÕR,©”ÉÃØi¾‘Z}µ…ÄÃƒ=r$.Sµ
¾°á+A2ù¼*çø'BõÂË/Í‡œ’4§xû^g‹wÈĞ³ášÃ\ŒàLGÍãF(<ôxÂî¥àÆ“’İsÄJä ó¬ü&ï/~¨Üi@çà#ÛÓ¤]MH5ª‡	|†[«şÑµ°çY:ßvŠÖlWóÂ"ê_ x`LF0ÍN¶Zæ¥—êˆu…NƒîY‰\ZôIz)ãa,^å}d²ÕEu„Uü5OïZ@Î_½D?©˜M<©¤ÈX×Û¸jf^]¸¬4¿:‚9@vˆ§P$éYñj+ÉÙÍõ”ßí9“ß'BÅ…m^Û*{ "@â¾Õ	#ş8Á÷ê¸¹Ø,	Kş®è(®,ØÒY|Ò IA§ğÏ&+,JÍ|ç¤èáìp‚¹ç½.ûUĞhD”Y—í¹CaıèÛÈkW;\»pğ8¦Iz}÷æ®rg‡ûƒ÷£‘O¬»`î²].PQ¢¨T#ß»TJ1T°lƒüÇfWHéİpJšXbë	 ±X$joì•nE±BË•@ší÷@æTù#ÁêehÅ''µ>tY^
XùYcæú/§2ğšÛü[èÿß·/ˆ"+â6)¥#‹kë/,‚}69ı”,Û—’Å»6ˆ®GÀ´Ü[G> +Òtt…Fö³ÌHLôÑN§Œl­´|a²ıl§nj<rï½Ê½¬DÇ_åLë»—ÔÃnÑã«[aF5k´ÿ[[Î2y¤òø÷>˜ê±05¡øzS]|ÌY0f¨åQôÕ¬eİÒpö)©æwá>’•Ã!Dl£3rZ;|œIDó¸`~Uè0¿=j¥A7ç,õsc‘ôbÜLç¥û·r-dnŸé\‚Ø…µ-1¦·&<ĞTb1-5ÑUí]ÛÉ€Ñ£kÍÒœ9÷ÛìÂİ?dÏ„+Ğu·m—şÌ fFFÎE"&#Éá<Õm@S¶…yöËW¤‰ÑÏa|F²ºÑùë¤ğ6GÄÌX*Œ ¦ƒE@å·±êiØ…E‚t;}ÍQ}ñ«[â 8ªù¬Fæ© ãeÈgº±ÚÊ•§e¹™ƒøñô¹ËjGÎµj„­"ÂFÔ‚#ÛöŸ®°LnîÌÉÊ'jq‹Œ†`hê5ıAlS9TµjÈ×êËê]Ú}âB8\N@†Èió3%US5mŠ@“ùÏz³˜"‚àLFy^·$°_xîîÏ“8[CÆí£ösz²sO$‡°Ÿ$œÙ|œQš<ÔŠnwª´ÔÊµÄèa_º³ZÍ¸\Tı¥÷=DXÕ$Ğ¡Y_JCgTìJ+ãîÁ5gÌ9*T£q	$¸h64d‡j #a¿ù&“»USM'OíX5}¬)ß†„(Ç8¤Nó”|Î	ú3}õøäE1,B2Ö^õØaÏÿ	L¿t]eyqÄøqiãNFÄ,™ S'zw<¼äZb¢¦ƒÎFR#y¦N„XÍªrƒU‹áÂXËìŞç^-Fè9Æb4ıL†‹‰H /Yò$ª4nO^:–›0$h½®ï¦îÆªS6dËğ-µ6l‰ÜÙŸ{„˜Š…H6ğıª²Qlˆ¢ ıp¬…†;Õ­<} 
q#¤
ºx™jr@o÷,4#ŸÑ4•xÙ«‘1[V\ìJ«A9t§4·ğ!ÆĞX	ám¨OLĞÁ.&€Ó‘66¯cMÊº‡•7*ãx‹Gjeé,Rz{‘©
{.àr‰TÊÁ®ÓÕ¿mû<Ã¿­Ú„µ‚ å½*»¨¤s=peJˆ§ÄÏf@^‘T%»›>òd¾şd*QÅÕ|+³UQW¤$l¯¿R2¯2ã5qÁ©ƒ€]ĞrÕCíÇC:µ0BÅá\(¢‰æ¥Ÿm 9?±›™“¯ˆ¿È•µàH€s\Ocğ•m‡SŒZ«§y>Ê³¦(IOÂº!4<qzC¦MÌşJ#şà“£¶	áT‹H²ııH0]Èä@V…*±®Šµìç_RŒjsˆ‚QŒÈÔŞüQˆœ7%y&><(Ğ$e¯Û>‚Äj*6À­¸I7Ïªx@ %uEÄxz_öA¿Íéé‘¬[ˆzÛ:ğNF˜ÎôÕ-ÿíhĞ¢8|6¡oÁéĞÿ–„&&Uõ\)h–H7âk,-GB~0èGİ´ûƒ­Ø‡·Ï3a*WŠ‰Á(@y!¹àlOÈB‘ÃôJ"9qÓle7æ±ÔdãÄ³˜É"]Ÿ#;uDğÍ£TİˆB0ò œTv{Ş"kJÂ±ÒÛQD¤‚«h÷Íı\RTÊ(ÊXew0¡Ò¾…q`¤å'tÿŸ½§q{<ÆË>®ğCı$u3 ½ö€tFªRñ„­·&®èÉË=×%¦o}Îü±ŞËôÊ¡ë­h-ª·[ugeaë[ĞM’–Á-("¸È8úå ÂÜOŞmd$ı¶¢Ç®áP ‘ãŠçÿM±½6N6­†BŠzÎï©,"ëš])¤ä³lh]v“¾³O­]j½š.År'DëX‘ê>£xaFˆ_Gó8ÚN37G¶”*èBN<{ÕÓ0¢nND›ŠØJTr6°h~pòŠÅ¿œúNô¨Ï8³y€AWİë+¿8Ë†!Ë#V4xÓÏ@:TÌó}¾oDı@vmÚôõNm1——JÇ[–ÃÇ‰şš>^$èqDÑ=@¤r´6:¢’e•¦ÏÂn-WƒVB`û¤QL^»ĞV ]qŠP±9Ï1€œ":±Ú2Ÿ9»±?!ò0¦ı‘†€íCÉuP5EO°¥'ş²¿Fä¾«ØÜ§’^§GÈ£-Ò™v1Ïe–xæ‘^ÿYÕÆ¶—%+ë\¤6‡dQ¢œXÇyË¼¸Cd%CtìŒá³¬2@"ÅïS´¬~¹(~Ù½â5«Ô¬<]‹Upóİm¦ BXOz_0cñ$©.~%QxÕ:ò“Nû3 HĞ«¼öš"`—tFÌvwÖéJífe›cN¶2uä+½c%X‰°°–İÈN¸~äXßĞUéİÔ»Tâ˜m®/WI`OÉP…khŞé"ñôğã¹ßïE’:iqñx„h¶(LA]ä&b$Zÿ›àœcÑıMGg1›—	‘ê[šò¬å“gù;z,.[ßà¯å—íLx£šyâ¹kg¯3AL²Q%ÛáêÒ$øD¸  £·g{G™1x­Tu¬fl¤õy kœ‹J„ Ç×ÌFæš#HCxVÂœù/fß€|é;JÇ|u˜7ö—ÒZT»fö\ˆjŸÅÓ*ágî1¦×„ñ50»”XKŠ[äƒ¢ƒüsYÁ…D_÷åãç(Tè!Šäü©¿qnÊ^®8ÕhCïr	Ü¶KÎ…­ìÀ…Ë¯òr§aI4ÀFÂZ\ñ#+…Óó/À8(š»&úuÉÉ„—ím?æXrcƒYÍ\áĞu%` /ÖŒP:×KÑ<{p¥¨µT†SÚZ›¥±äD<l©À«Cİ“î^[µ‚¸KW”ğÛê6µ®zkhÎ'‡/ÕÜÔƒèòuV&…œéSõä<{K4ÂşMÎáCÉøìd„Õ*T	r9N)>ŸßÅÚA»Ô+ƒjşß05qŸ[à Zf ÆgÒÛ2ìµnSÀ6ö”ñ}µ\Ğ#á«w=k;'=ş:wçÂ¤;!_ÕîÒ(bRìiNÏq•jpŸp/jÍ‰ØMg:˜M‰¼]ù"adø}:E?Vè†õ_V,QP`€xo‰lAsòœ1‚C¼ìémËeò’Åƒ-wÙ¤Óåw±P	6¾O©b°Å0™ùOæa„äe|_k;¥×ŞuœQ.Õ‚b†0ëZ¼i˜wèœ.VJÀÎ³D‡¨ŞÖ³£«á¦˜¶öx¦|„g#gI«¦^OiAI]İ¡òRèRMØN£Pßú¥.àŠLÚäû†–‘+Â£éo}=3~”AÆ)	av4¶*¼cUïêW	±ş‘×ç·¿FôH$Ô¢r˜*»‹;»%AC¬ÏÍ)ñ€õ×`E·8g×Ëf¿eŠù‹g ‡b_TIUÆDá´&â=†İ4_Ä[\3}ª®*!¿íj#[k˜tcYıó˜+³vçÙüLg¨Ù¹Á„2QúĞ€¯£Å~@ıÙ™ºUD†Í^°@^š§ÎøåÅ_ TôŞu. –`Å"GÈåGÌQ-IcÎÎÃÈ§"+NmÀÚÆûş¤²¥ÿ¿<§eÒÅ*Ò';ø¡ÚÉ“—Ÿæå\~5)ßLŸ™F•ÍÄĞar]wPL3‚^seXöö…åXíÈ–¨ßåtòÔìÒvÎù]ÕoÜÏ‡äm«UF÷¢pó2qÒ8¬¶d¨›÷ë¿ŠÖ›õ>`k/Şß{ëÓæúš“¦Ô¿ L…hØÖÙQ8ñÏ•Ê	ÇÕ¸Z«@…~z÷ÚÑ¼Åéiô ù ?júXET×ŸCgï6ˆázà·<ú´?’VCò€ƒ_3€ïˆKáƒ¸\–t¨9oª¤ıŠ©À|(}ùÀÔÕé›Œpµ$¬yĞ¤o`Šúvˆ—t~YğÜ+ÍDŸGZ*y#Re BÍıÊ&+3ådühÓBkÍúÓØµô‘Õ^‹ø¡Œ8#Ç6÷&az[¶ÊëİÆCj-kÉCF *®°ù‘¨Á¾:Ş¨8Q¬&MâdÔº>0Z‚–%¢8GE]|YZíß*R<gÑF‹Öu2N¿^¼Ã¥K0ÛÁVô»{œñc\yWnê´st¬LşEÎÈÛÖe‘t%_â9[Æ1qIËÖ‚`(U¡9m,Uãb±àÚÇœ6$E˜$¼&“$âÛµÎ;ûOğdìÙıx~ƒqÙ¤ÙÅ–Ö]ÖKÍ`Bò°Êhe' åÍ çˆk™}Hpº·@ô„äÃÅ'£ E}Ühs¼Öf·àêS@
 RM¦¯¦ô*›+;ñ{¼Eß´ñøıxÏş ÑŸR-åßyqá´Óbºs¨ÿl şÃEëÉè‡ÈH$z*œŸTd“Ê uÉƒ$wP©k°Òâ{¦¯¥˜íõØÍÁµ|×ê)Ë€ÙÖ¸tá«Æá•È-r…ÚZ‡`c™ù°¬âš‡Ó\Ñf'¹-¢Ì 80ünû)#Ş+E(ÜF•	·°6ÙcD‘£âæ,\£ìñJ³Š-ÔH§V˜Hß­[ZòeeÏ#ğphaRf`ÓÏza)Ê~ü9ú˜ŞVt•Ø~3ºİó«.¡ş*ÔãZ
˜«EõñÛëIT¤aVh2yŞSªÍI79à¡ïLV§i¤	*Áé]½è‘.h©dÆ*”¶öPdOØ~¨æ¸øU^­šöc¦™¯¬¼ñ€ H¥¢“^ °W Ö­‡7óÓ~äì¿ÁJ8â›²>†(ïnhîŞQV„/ ÛœtÃÅJÁ<»¡Xšú·Ù6
Uìš´aRêl€T?-ÍÓµtÁŠFîÕÿ(ğ9¹ûùÆï|5Â³Ê™Ê×øD›-zƒ{!ùUÚÜ‘°b‚GšJ¼ÿı©ÉxŸolù¢´’h¸Y{{•"cPd£ê¤åŸ8sdGNHg=E•Hc¿¸«
> õõ8'ÃÑÄŠÆ©YşïWö)ã…°¢å`G'W,ş±:éB:ôs™nOH¼]–¨sŠ<2<ŸÜ«š@Ô-¯¦­Ÿ¹\YçTëFq`;–EM­¡]>	.W‘ï[$ŸFûR™}CdaX0G×¡\Ñ²]BÕ.ÁAÅoƒ¡/ƒW‰«uT©Ÿ£æ‚6ÙÄ$×mŒ„ÄØé±³I“`yÿ1ú}#Ö3µ¦~‚@æÀ–ƒ‹­£g	Âˆš°3}tL2¬ ¦ËOõ©e»(Èø»¢¨VEË:òğS'~£+®šQ~‚:5qNäœÈ"6İ>FıyúçÙN±Ì¼—aîC`{.D´³°ƒGëTÁíq!4>©QöÍSjÓ)Ö\åêùl®Ûì#JtkÏ~:É!Ğ6¦ÆµwôäÉ:gP|ú-
Û©Ğ’søa
¯®·G¹‡¯—¦srÅcÉÎ¢XLŒÛeU&¯É«ÌW£»¨5ƒ«ÂHä˜×%ÄS¤§)ß…ÄëÑ%ì ÉĞ‚Jtï¸Uqœ”e|Ï+J&95æY¦)Ù^Í¶Ëó0~Iì‡˜ÄØ@N®xP×
¢Z‹eÕî}&|wéw¬O‹İâß „œğ„ÆÑ ¼Ù6[*‡dV¯Iû¡=ÊÄMBIßü,30Œñ%kÉöÊÀärÍ­y'¨°V3fÏVÔP¬®Íf3éEŒ»Ë­ø†È0ëÜD_a@ÌtŠı`qkŠ/fjŸÁ6Z½š¾R$’·Yª‹‚tğj¬V´¢…¢d7dn$
Í‰%Œl1¢ÈïîÓ'Ùó\ıSÚŞşƒBøÔ8jëò¨5ÛyX²Å[·7©v¶´ºTTßÂÄê3ua.íËT2òÚ€æ»»ª¯;mãq şß
j y94€foAÎÎß‹gJÑğ¢0{Ò¯?A[g®µÅıµjÆ³ˆë:äKØ…a÷v#W„kûÄq
Ê¶*éen;
íŸl¤¼¶+ßoyhëàÄ¯v\‡9øZM Ze&DUcJüy¤ÉáƒÁûv—IãmõÒÿ{PÚ“kÉ
õ×Å½Æ¶ögëW­ÌS ¬q)Y×Ó³AZ÷îëgÎíDÚˆqÜªAÖ°jI]Ìq ¼ÁÂ#eàoTqŠe¨ğ@HUdó¢Î†
şI§X9{¡”é;™Qwyb9O¸»†Aî|°c¹ŒGJıº›ApİAì,)œĞ¸á ´¨¹9aÅ/Ä¿Ãôi¤5ü
TGŒKJ³“yJt(v³†2  1	ÅûßòM¾‘#›Z^ûR[¢ÍŸBA¦ï¢yÈ(æR”õ òÊ£ƒ©äj”Ÿw‰4fQúfÕºôMÎ? 9õhùĞ¶‰­İa×¬ìŒ‚±œF:v™Fı*ú’¯!İNgu"¡í½Q¹ïë<Eh_@–ï•!%Á™ltAßà×‰AÚßñšƒí[¾¯=¶ó‡tÏnş°Ó`‹X®ñ‚F¦óÙî¦€ÇKí_tşSï_Xû†íå²Ô81ë}}ŒŒKŠJhLÃèŠ (B®=)È$Âì¹\  š7Ü¶RÔâıùòƒuZxn2úq5÷¤‰ùÓÑŞium¹^¥‘Û÷İ£Bé±ƒ«4'Ô5tÔƒ-oöR¶Ù?Bd+•¾îî·Bkc§¼J<—FPâñ8#-ôÂ‚øSò¸ÔaÅ¶ş|ÕøåU	¦JZğ,1È¤™ñ@Ñ°D‘×Ÿ‰TlÛd˜`ÜˆM£a‹Š‚–Ê·§ù®§¤*Y$~€xzÚ+mì´wóWóœ¸pvºÄ—¼ÀÈÚ°ÉÏ	@ö²¥ÌRˆDœË\XÓ½Y¹,ğı)~VÚ½GÊ­#à•û	Uº×şLE|
FFU„¡JhÊê¡ TÙcî(õ"¬—ŞérÀLÆxh×İ:ñ—*Ì‰I±‰{îñÒ=ç×ßĞ~X°ñ¬9¤Ş§Ú`mFÇÓ§Ê©rU
(Š”Ê;Ÿ75>£ñgaFŞéƒè?C’‘ÔXáºÕYuÈÃHØÑ=0§Â¨u¯h^\Ñ…à?[ÀUªƒÊÉIÃÀé"¡SĞğ—°5à'Ä2tåBeu|¥)Cá·8s”ß–‹ù
ì~íÁp1vhmBSƒåğ„Ñ¹Íá19ˆÒ”³hWKˆçLt0†É~Uâ”Ú0T¾ÀŠÅqù®ÔÕùí´ô×|šíù8£7£½µ¨•‡¨‘–_|‘>Ä²x>S‚2èé¥¯qm÷‹zä6t»?ªQBÆj)D„·òµ51XLäê÷7zÍ·-Ç_" k#¢ÌßJEBİ¬"#z½Ø<„´9Y÷m:
¬ëÍ¨€¢#¸Îéî¯Mk<~…¿$aŞWÉÓ5ì@9G©éëuº 2J9ğÊVe…FŒ#ƒÏO†Ÿğ˜i¢/9!I±¬;ïÔ\éşÍYÁ»¢•›ôoØÌ”BÎ@RqA/¨!s½—MH¥G"ÑËª_®YXgØı¯ cö9‚ÕÜF¡Jûş"&.uûÎøIñÕjÒòŸì§¥ãsà79NÙT´‹í?PPü!
'¢¤`è>´Mé/›-î	˜<º=ihìøy=ËŠk‡ÖBZ¤l3ÌÇ”’€Äx¤M	VÈÀIÂ"¾j¢~³Ëi¯‚œ¥‹—`)Q­Ş¦`J_y‡L·ûA$ÅØY©9Ñ¥©Íºš*±fúÈ#_Ö;ŞÃë¬–hå±ó™Ö°İ®¤ñÙX³Mâç;!ÈpŸfTô•—¶Eš÷çÚ™¯t¼¸Pª´^şsÏ8ÄùšWñ·æâXNš9 +E]í\#š*1cIQëæ¯ƒB{—ÒF¬$
ÊíßzÄõ¿å¶b’¡Ó(06²Ñw_dy^+ÎÕÍ	ÙØØ	¡©İÇa·^P4T>S˜×‡~aœ‹È“œ(Ëx?cA¦B†˜!È{õbU£7ò9RfîûÛUEç-n.˜J`›aÆg ™‹‚gAÒ@ı2a`åUÊºø‹+™ãj÷AigÂû—N¸¤®¡ü93$m¿ŠÚ‹À1y´²»r¯9ãó’xTİÖ3«WOtYï4Ïtçq! ºt(Ì"¬í$æFXQ´"ÒBıÊhDĞñõxşE4³ñìW^šv´QuÂmåÕ‡&w…%~à6_ÆÚİç½rÙ©³eCØå³æúéùb»…²?è'jÃL’ÖkˆhúMfô¾2ãF¾ñbX#PeI,œ?lc¬ìÊù×‰¾dú«8Šfkø³yn’0#ü¹n€Ç**{(Álˆ©Œ¨oá<ò@Bã³V¨+¢ªÜ¯½Jœáw¢{'{.fºé(äºdÌyéJldZ£+÷Ø(ÜÀ³ÃÅ‚Ã±ÏåšTDÏÃF›|RM31æpí °¡bğM2í?çíÈæò`m2‘-yØCç2$°ã+èüi,&+çMÌè‡b"sH7tË‘xåŠšPğ·`¶:9ˆC·\BúÒïlá	g?ïâ[×ïséè¼¡Ó>
¥Æ÷Ÿ¾ŞÍæeY:_`æ?†ãÿh;ıà†&K^´¬Ò†+µÀâ‹µ8¶¥O à¢{jş˜9§°›Œ÷-°UÃ­§ ]÷Ö92°ê«v¾ëİÑ¾70S„pK,îyëöá›ÊŞxæètò*~”@DH>»ª*ˆ%³¹²yÙídaG¾ÜëJU;‹Ë˜kFÚ^èG*y:ÒİæS½7@e¬ë5“,›§NÙ°KOÙe§Ò:¥o)`&ã%ÿj{Üß%Û¤À= a~j£>•Tvdşyg‚©—Èn·¼›rs	Š4EXo’I‰[~+¦=kÍFJV©Ğ»®…±a]Ê	vm=ŒcDÜ Àãô5á˜ÇAŸÁùÍH)ÂĞºÃ)>F´
_bcxÒôîë”Sßİ¸½„"‚×ºª¢Š
myBÍÑ'Œ7=L?Oßnÿ£¢˜âXó˜†ü·ªg4ÃşÎo,T.2€ ¼X]Iâ.ljTøP6±öÌÂÇGAë£ùœÔâTu®˜Ñ\ö.FŠÃ?xW”¥ÍM eP§êÌíUĞ	e$Uß$•&Ú’iš° daJº¨ 0ú ’e\¬áfıÔƒg`Ä]ÎŠ¼®	©Ù°K E*‰;‰^ û^o™s}Dö¯RèRÆƒ¬]şşéAÊjuq‚R˜–zP¤¯ç’¨çTnDë9•,:÷ï=O©ÖîÌ[‘dà¼ÖÒHa=H†’.æ`{£í» Z½İ;ùÖÅƒÆ]‚HºB¥§ËH=CµÉğİ q6ê':O~aÜ:>öšÏâ°°—Y_Í÷#ß³Ö£
î ´ê=$>låˆ'›Õ"\ÿ£(†!ù¢jogÅıô.öBÉ Lu±š÷$’„«Îš™ê_l˜bÃÏKì£¢ñ~& –Ütœ°…
Ğ}4âvÛ1†P'ìzª pz‚z0³TthğMuáCÎÒ<aQÔĞ,ºkHÊ»ˆ’ù$±£ÀñõërA)™5Ï6M7¨L¾–Šë-«2ºXd.ˆF™~gÂŠFºŞM¬&Éuè?7ç(
“hÓ÷ï“ÿ†¯œR¥ÿâPF+‡õL}ï”¥àx÷úœ©.ÎÊ3\[³µˆ€éô"diR,¼ÉUÔZ‰ñâ÷ïE·ägT”—;çñ&¡àdúÓš¼Ë„aÉ!ıîNáS™ºHÕ•˜º ú	HÄ0¸Üë‹?µBpAÀÂW/"7¢ö‘†L}rWNbŠ¼ëÌÀ×;´è»×Ğ5êù `wá’ÁÚ0Îó×ª“|ÊŸA«ÚAR[kw±qËt†Voß³¦ ’§íNMépÂ~ç…JV4#ÄÇ&/är‰ Ä¼¨"›(Ìà—Î
T&€‹Ç­>ˆ›öÓ‹Ä‹OFü :¼ø’ØIªñ`VòÒèÎãfAÛ‹Şb‰]>6C~øú-?%¹ o‡Ø>1B7Ê@c?_±üéMº È	sUôAît7(_«³k=uõ‚—­\òZU65ÆÍ[’6ˆ)ó›´(ö2uîªTá!PµVo3 hëQÖÔ¶.7‹ë»Ÿ¤—T5Õ¢(4>ó7h-„+×ş¾aa-»%;ñ¶7šbH'‹CÈşÀğDÕF"Êw“.fdbfšßpÌ²ªl'€%DÅèŞ6û<İÚE(@êZ¿½Š :Éw"L\Oâ,4¿)é_™Ús§/’ôpı‡¡¥ÿdi^ É.ÂP;c7IàÎyqn«,—Éd¡­Œ³Ï¼·':©_¨Á†-£@â-õ²0úÿ¹QØÈ‡_dÃæéÆãZ\êua¢8¹-ÚEŠGœa ºR Ÿ€$Z2]~?_È¡”x?İw›TŠñOQª)ÌD:ìÏO5Šİ¿4)ØZb¿ŠÊ¶_f^eŠ;Tmâİ“š„#Öù÷Ö: SÚ¬ÚyOóY¡Ì}>ùI(:¶>1Ûw²dAMĞRd\ä4ÆX:(ç#—ÊŞ~cËà+XËñèWñ0äÏÁ|¤¸Éâ|­œ!WöÎ"UTC3wqèƒ™×ˆ‰¾GÎAİñÀÑŠ¥¬|Á/VŞèÿô¥åiv½Zë·IEŞÏ ›‚Tg.»óÙÙ/Qî²™!>Ç3Cş ´–æ3­`V>QUu’^‹-2/T4Ùª1#W‹$)š¸:¯„r¬":Èsä=#±c©ı¡nDÙÃÿ»$.àÚ°Òæ…B[w‰äo/TCë¼ÎÅ¦c:'NX€Û`¯™!35ÓĞ¬
’¦\ãFKÿ	ùéâV”ª(GŞ\óõ£å”nŒÛğII›IìB’áıb$ø{Ò¿îq	îO+urÕdéÂ@™¶»[änö(R#§ôŞ›ô¤}ÆµÛ½$Ğ@U!„/Fæ–Fk$$e;İÔÜb\@¯$›!›ùî$ëÀøÃùˆ5‚çó‡†ß[óIY“áA¡~ÕŸKùØ¾†¶­-®JBj|œÄı«©û0rUèËÅVƒÿæE)=*á$õi}{ù¨Ê3×{2PÖf®NénÊf¦Šánİp¯R*t&	kWz¼fVÂÙrngª-}MïÕÈ‡TQÇÆ(8î;ã™Z9SĞô\ÌZ¦1©&"O?ª <L¼3ùÛÙ‡à+4ÀÑg‚r*ş¨2øÃ’Áih,\Cm BŞ†µ+ñ8B?ßø÷"ëPq…µâjDv¥¾!'iŠæqµ#¢õñÊŠêê·TÛf>mwK eÃÇ‡¯¢Ká%]+‹áôNxÈwİÄHßHëGôAtøp÷ë^ÑQêÏº}D¦;8±ù1lØÔmÁÆ\3U›.ìßOKôm€ŠP8[pûXÙ1•¯?~afèæPQÍ¥›Kë3×°Fªµù½²«ZŒjxÌR½ë3Â­‰c&xÒeµbeW[)-Oûmô²FùmqÏßƒ‡ bùÔ¢dôS¿ëá’næ#ß¬­>Øg—¾ßú…O©ou¹{§“°n§…ÛãàcÛMö3ñû·…FàztIë˜Dç4\(>´ŠpìªÇw¨¬×uPrÒ²²>åV+àÅpæ¥Ô¶{¶&T¢’—ö¢}º¾bµÈ,,—öÓÅ§ä«ÙÒ—={­‡dÑ¶´‹İl¾ÃE{¢åÕÓÔ…M¨íåD”²ˆ­¢üû©f7û#íz.4‚ Ğ,&És¶âGY¼Ñ% µ}kã…³yòg~Daäè6õÎÍ×ƒ³”m%¬Æ\l–}>ZhÌ20‰ßwÉ‹®8ä;X eÈ€oŒ.µ“’gõÈ»¾µB=(›8‡ìş×¹©^yÓ“@JIQÁr{XZ¸7»š}_´J&Û¹ÆŒ§?qŒQXq–^¾°•°„Àï½Í§¬jÆö­ÛßZá	\YŠ|El8¿ÏÒˆE•ï;@Ü¸9úqs¸=÷ÿ—@ïí4·)Ø-V»•¬`©$j şÏ,SÆ]ºKI—/Mª´5ßÛ>¢†t)=l—ÔÃAI	¦M| ş»É4}|´£(d%3ê	ª•ó=™­¡w–{²mŸiÙ“'y¥¬uµ@ŞnjÁ;«KÆ~FTXDÆwÊx+èÄbè€Ãê½wÌoÅ×åôrq|š•ÌŞ…t€ùÜkfôh†Dhs³fX%Y°î³ó}:R,eñ~b|‚´3ñ²ö"às	ÒxÓ–•£ióÊÈ` +R?'PÄ¿şÑAËI"°5üw9+¿˜<
…Z·€å¬B²ÜÒ ë:[qøÔP^îq’…šäèåC„·aô™lxÄô„ÕïÀ?(B;UbGÒ•¤|6ÏØtNyËö[ÇÖ°«ÉÅ»,s’\"¸Ê9uClqòà»¬Q$¶1uÈŸ…Uì¹ÀoPMEøîJè‡ö¹ƒœï“A)	L^y*=6>ç-¬‰Fã·*7’TĞT…>&Êrt}¡ëGÈƒué£BÍï»H)jiJøûdEd´g0O5%—‰?‰êòL„ƒk³$Ö|ªÚršhêf…|‰fh¶XË¸şİw@Ën5ûG„ä5IéëåâËäzbİ«Ê×(g,ÌQjt\›H’–—¶Mµ·Ç+*äÌ>QÈ@sD˜ñ_øÙe”Š4åè­xÒ<£@Î,0lé2ßlş/6ÆdãÿÁåÌ*ˆÆÁn¾7~KGq[¯-e÷­^ @TÑnd.ŞŒaÑ/Óã‹Qÿ&Ğì˜K{AÑvÅÌ‚­‘ªî5«5´™ „‹U\–ıd¬p“¯›0‘¾=ˆÀwg­ïÛb•j®8›U*TXÌğ;<.u†¬}7*ñK\˜dÎÔ¡q¿æà9uÏBsH–Vª+Ò0.ÑËŠ»û¦ëF«Öí‹ŞkzÈò„Ú¢¶D
¯è£V+(ºçPEe³ °ùÜ©ó±èW¨íÕ8eµØó?öDd+g5¢:ıî#.C²ÄÛ¥‘_Ş€5<ià(Û)-J˜¥–Uf“€’ìÑR^ÖéÀOòˆë¿oç 6C8›kg'cä…¿ş^E››§)/‚/-ø{3e”¯ÀØÿÏ8©BüîùCà®@æ®7ü^Åf¥N`}ö–÷†–ê¢.ˆ‡„ï‘‡0õë.wŞYTÒâÄZ‚Qƒ¬¹M÷×>aî:P°¤I#†À\•r‘$éÓ W7ù=hpE-İ#½òŸ¦İ‰öéÍÀ¾Ò5³­ì†‹¬Ü¯ÜD±s'!;³×[á‡ŸîO ê°ƒÊùÂù2Yv¥A|¶ÃPı£mùEãNÕ!@yM3e“§
¨\°¦“ädµ‹øtmà	Â±šÂ÷¶+~‘rR0­œÇ’uÅ–İ¹¬8ÍÛ
ÊqÁt%„†0p{9i³ÅGÁkä¾tT•²å0ñÌ®Z‚¦¿„*§‚+Ê{°B’Šö•t9v§Jø¦2ãf°Aq‰«oµÃ0äÛƒÿC}ñn‡ù ¸gC†
ÿ5À¥`ÿ”:|€bûÇnH` |:æ‰».c•D±qù•©á¥R¶Thw¸Ä]ÓŞœeY\o†cNÂ“H¯'—l%†7JÂm5¶/ÖwÓ—,dÇ×¸;x2Gy±O_áf±à‡¦aŸñçMå^réîŒ÷ü'‰å$øÃ]Æ˜R˜':çÖÉZ8úˆè_K»|sÂİg"1w8hPËO=G4Õpuy×ü³,@zå†•€ñn¤oÿ2EŞÅ|±7ÿÚ@¿mÊÎ×ëF~¬E¬Èû"f†iéßµIÃ»YŸ:GñkÊ³>•jT:Ä‘“[?v«èd&p¿­ÜËˆÏõ°¢Ef;ÏT6«02§ÉuÁØã:8‰Z,üs˜Ò²’<õ%¼š.‡9sˆ3-,Ò‚”3‡÷ã‰ª]0OuzòèöéaR
'¡.
±äç„D?6ğŸ¦K´x/Q)~Şü‹QéH{È:M“Ïu¥„ÇsÅ•HS‡>m¸Õö%œ¤ß?^ëUX¥®çz¯œùÉÛ‚<0´ßQ(Ö®ä¥J;|®šOˆé?ŸvIğ-^üzHÃ#—÷Ô~ÜrınqLÿ	‚yîet›á6ğ8ÔÂ«ßŞö`ß<£Lú—Ÿ:6HİW×®ÎÉ$•Íg¾·û|E4­Òà•Y4S¨µ9í¸Îe«¸âLZÒ‹Jü ÿbœx€*×ÙTY]hb>zc‰ÛØRßÙãDHç ÀTŒ½«—Åœa”ûşÃZÉ¾j•»Õ9£`vçJ,(${ç{Tú‡³(£&9¼º‡‰ 'ÒºF€’¬¨²ŞB‘¿ß“k]ˆÓ}Cn)	²· ÙÍ(zÓ*ˆÃ°J&|`+İ|š-†/Â=ßS¥nÌÿı;¡gå†UÔÄ¥VËÈ±-THVó9qMU’Ìõz†ñ>úã$¼†ñ" ]¡k*ß~ÊqµâÙGŠ«N6?iEáx‘Û2õ1$#(qV¦4=yßÕoj)6µİ?¿<šDrë}9Aœalˆå?î%^şTŸ	U¼0ƒ<èXår„×ª¤Šc§€ÉDüÚ5§¸ŒRŸB¼êr±Jf(õ®Øæ’–~ h£0/eË²3Š8¢&x|D.â3Õİ8µN9ÆªÔ¤VÂ^Ë½ˆ$‘àÊ/ªÂ+Œ]Ç;O'¬•òy÷Ö@.ËÙ/,¶çQ÷	ÄñNá™$6ä—Ä7äuÎRnpÃ;í«¸4ÀóÎrPÚ&ù¸Ş—©¬-ó/ÙD}'í‡‰aß¾$O„nzè¼²Û{ƒÛuuøØTOF~ŒÓHGSŞîŠ÷,~²Ø’)h°[rp³Ãµ]`NYó‹a ı0œ8ÊM®ÌoÒ†¢Ÿ÷å¹Š5¸,|½Gô)sí=mFÛ‡cİÚƒú=QâU®ô$7ú1;O–è SË8¯ìë¨·ìjD ­Ô~-²/‡e³"A§ï¶~÷>$ÇGÌ"ÂÁÃ9€[¬bLàåLçuì“ÈğN§0ö}EŒã½[ìYVO5XªIäÚ†{À™Û¾[	ÏM§mq´nk;ºÆ1¾: ¡ ç¹BŞŞtûM]!ˆçUˆ€8X¢&¹«£O¢Åİˆ4_„Ì O,WJF¦}¹éX3oˆ “'ä@ë0Uşõ™…ıİÆNŸãDOd Ã|45 Åô¦I0TGŸİs4|O4–M’š‡¼rmÃ²]³K_`£yùGô 7D vMJ\†íı·çPç°Ë}^ğf-ò™-#HTŒ>şÁá%³­à÷ğffYèæ`R¨^3û¯p£E~ZN¥®ş^=)kX‡$ŒĞì]¾4şuj:™UCà–lhCÜCfÀWCjWàÑ«Xkş‡FÁÑîY\~ñÅu÷-G<šÙG^¨İ—ŠùF¦ã§Çï?ãùàÖRÇK#%jİ‰šËl4½äj¡êeĞsß:ûQb;Ä;‰Ïñ<ôø«Ïn™ ³şMvÙšZà4çû¤ªaÑ…¨ôvÛ(åîÿÙë–³–ŸÑ*®|-»4° £x‡ú$)ñË¦ó°¦t%iëã_³µƒPp%'Ñ³Z`!Å	fBÃè³¿Y˜ÓùŒÏ&˜SÜDÖõ­5CàY¾†6,Ò´8¬ˆ8ğbw×/ep¤u N”|jÖöùÍU™Ï ×·ÓYêi™´g¢G¡n **ÆW?\´ß(VÛBŸˆ gA.úEgŒ\[/”Øôêö8õt[Æ¹øIÜõ„ÆV›ğZ¹rxóò:ß¢0u½óLŞT#ß•»“/`ŠëÈôA‚
"É»ĞÄG(Ê,‘kxŸ¬¢ Vµóñı£í¿Ï–eiÁ[šs÷İG¤³P¨Z¨Úca°; 2m„€âæUöî´A±1jÅµ¾J<fVQk¤´	ÈÒä…5K^ ›Ä|?",më¥Ï1¤¤¤@ÜWÏ+²œ‡d\dZ¨ÆSéq%:ˆÀhm{|,9OëŸ)bšÍ ™½¢	q©
+ÔCä)¨^ídÌ?&Î>î±ıçÊmUıçàÈCYÉ¾pM=\\º›^W’Ãûj‰j‰|ÿGwËßÏäL"ÿ›†²È¿tÊ\ÁvªÈ5‡AÒ¤ò§Å‘½üHò^G]hÏù¯­Ò ™á†{5 €€R¤kŞ/ZiëĞ®B404»Îı- ÒÆ¤´ˆ‘Ö4ÀÀÜÄ¢‚2•–àf]tÀµ4;Ü$x·c¦-­-nº0/rö¹"kVĞƒ1VøZ}Ge·Évñ’z6¸V—±ş¾‰Âu©Åc˜ÿ$n/ËIÿ¢7!lÁÌ\ñÿÀÚü}Ä¶/û	d°¸Ü'•hrÎ¢¤ÙÄöæyê¢¿i)‘§çùÌ(÷ŠÑyWNÄùÚı)öU¯84B<"7TGú“ËÛ®Rd#ĞU#ıÁŸL®Ï)Erú1W–‘*SúŞ0µñ"Î7Lİ¬Û è7é:¬'fI½òêc'¿à¸z‰&Ìÿb³;ÉB†Ãú$R2µÃs®Î³§¤ôYeã)Õ¨wÀ[4Å(ğ^“ºœãIH®´Şˆ ıÉ§Š
DğFb&L)Ğ¶k±áhÑøãÄ¢Û#ä×Ây-ÈÃnÕ ÊÿphÍã>@ÉP-§YõÛnãÔE¨Óåæ-`Sâ9¶áhc¥c[“	¥N¢mw¯ö—B&&;JĞ9iOZñvÌÍrıÑ<ÎÎ¦ÏËÑ—…Ÿsu#÷¾#w^Ï¸À)ºzq4ªİ@Àeïm Ú/á‚5'NÉ×K†ºWqw²X-¢kÚ–êê¨/‘eL·æù>íJé{|ÙÔ}ë8ËJ«ã¾Ë7{Ğ´Ú|ÒÌòIĞa4bœ=ùıÅ>$TéÌ;wJè]£ç©…5 SÕHÂ €^„9	ùÁ'6Œ±Şu¹©ê9
€Tfü}úœÜY‡Š‚q½p' ¹nƒá jm_j^×Î”ŸšV®Ş„÷â‰5^ÌiÛCKOFGcÓ#õ|úzã*õ›ˆŒnşc×Uú‹–&a(üRÊje…ºî¬«crs×x_è)_ø€Ï\SÓHüëŠ¿A°ãQF—: pØZ…|4 h·;3|ç4b†Ég÷¤ŞÂc¯SìÃûÎ
Ó[Dü]ŸO¦fì7–ırQàvß2÷¾¹Ğ–M»Ò“J×?H#¢<xwĞg|ø$ÿò§¾»ß±¸
Æ{ÎalëøT×«I“Ô0Éï“ÕÅ‚S¨¡ãƒIWœ¼fDòzÑÒPásJ° ²Q€;’V.vV¾0¾¡ìÖø)û™SS’¼ Š3…Â¦Á-IQ®.ˆi“çÆÊ`İ÷ `<Õ§Ë2½™cN
EÍsÍ§xd¥Ú²®@ø)Hq'‹MQPz
‰ßMïvcœ{i¡ká~·1e…£ûÈ¾YÌ;öí ˆk“ºpr¬´xŞ°Uïvı¼/ªËIT‘ï!–`ÓçrKÉïÛèÃN×ÙÙT˜Õ›Ó÷¼hmB;Q›|Èµ“öe+;G*QrDº{3æówŠ¢ÃÎ>wadCra80]7?›=‘ø=8C._ªtƒÖS~‡ª5Yå‘‡¬Ú¶3v~aËµ4jĞ?.ªÆÑ8Ôui2¹.'³Ğz3“ò2wC-Œ²¬Ãi#µˆß_’¼´çgjM‘9Tgûƒ±`GŠœ|÷f «W£Y(ûÏà œÎ¸§´˜&'¤©kÊı€I³¹ÚÖ¤w'ğ¨ÍrİãJ´4“{±„¨Î0ëüùŠ,/PdHÿ;’ù.Ä9WLCğmª*º˜GâÛ;jLM'm# 2„O’:Cô:ş÷7¬Åg¯•ÑNİåPÆÊIìé™b…º®Wo})\RU`OÍ¥üqÛë¹1²ıu‚Øn™ÒPÛİÎò¿fQ“Y·cTŸÇ	g·ùm‘q½†xhnbAßh™6°O˜f¥ÍÂ³]·Ìâúq'Zqh˜öÆı²ÈäFÌÆ›/¾²Öé¤T Ú»á™­“°©}ñ¥¢/+tõƒƒEäp-'G5
¬I¿ŠCˆğZ<ÛJ<Ÿl¢…2°j²ôrï:¥e3Ã€
ş'¡¥íàüÅL%eBĞ^êvNÉ¦pŒA@ŞŸÕ­*sºô9ÃswM-£»€(ÌÂ2û?2.¿Dû(>ÅıeÄïXofO©[?à6 '­ò…A$Ï¼y—ñ÷ä*¥ÜßÀFzœÃº)	È“ 7¸Ñ?n7¾~Á{ş:Ê"<ß“2L½Wâë3_,Wbì»ŞkT¨õ§©¥hF«Ï‡tqH«¤[3Å÷ˆªÀY¹
U±©€ÖDµ->ïø3„|2Ô} !PVM7>,švÖ¬t2æ-EÊ”9­d×"ñíJá+¿ç2‘¾
¦F\£Rxù°N³n¥ND#z)/§³ÌG°kËn½$)Çìüjà‡ ş ~A2ù»‡£ú±÷0¿ÃgšÜÔ´ÄÆüå¥ã3:ôy/¹şÚÚ§,j‘zócşp„Ğ°äÀì1–ŸLG_BD+–Ã‰—.A=*)C« Øªõì¹÷ÃB
!‹b›#%Üº×ûÙ0•w‰&¦”õİ~¼[öÜåES¼r©dBŸ°'	g¼ !ÿ@ŞJË›ª~ŞúqJÆø÷o½TÎÈû: iÿí`Ç§hòªkD:eéµ•İs¼:3ª¹±‹…ñÇè»t]aÉ?3Ê¡ÓÚCŒŞ3q(Ñ´Úˆ»<Ü´ô_8 ©*£'2 ƒò'.I3µYOŒİ&iù°•‚	¥œuÍ Ğ¡ãUª9›ï©ö§[„dzDYµªD‰5.,ß	 3‹/ª++¡øïÈ9k8JKÇ€G/ï›`‘nBQÄ¸7PHÎùì­xöÁå*©9íÿÓ¡^ß¯(İHÀå³GbøZËõ{0kÆ„˜|°0—×~ÚV‹êA •î9- Ußg:@;{Ö÷n0Wr$UÿæÎÖûŠöºÜ5#¯SOò÷A(wÊZ¢Èø3ÁÑàær.—<ğ’T=@e§Ä·0ìB§z¸¶m’BiÛúë½·x6¼†ˆÙwi&K¾ÜZO%á…™Èv`÷iEÁ8Š­cBóMq1@7€Š—?>3Cß €m†˜wË¿Ü¶ın¾¨ÎYp™’èîÂô1D7 Î¡w¤(= êìPÍ¬cnÅ8©®,ËgyòT#1Ù[õƒ6¹”ùş³–ï-8æ\ ]óV °’u).½¾È—›*ß-9;C’}Şkà4,İ·IÿÙœ›y‘K)dE&Î¬Ènê#õI í§kTÍMË¨*'I½Âôú®lZ-_€Uì"ùMó{À+Ğœ>s8ÚUÚ‹ršêO V«³/{s¿6«ğÃ0Y¥­ƒ9)3Z`QÍtÕ…OYûJä½àµÒT>P‰§£x/	D¸÷;8@¸‘¦A„Ë=C­ŞHË{¬£òÇyÃ¸Py†—ĞÜ‹¯ ñh´ FK2Ë«ÌJ?U	â±(
ÀFàÚ˜_û¢¦äóÒ!Úî’Ó¿ØŠ¢1KLüÑ£Q?Ïâ±ŸÙŸZ«}?ï'KC&’‰faŸAx&RÔÎ›¤^+lÕ¬Íú‹‡=%W’çó0Ñ½¬°hËöDˆÍuBo}Vx0xøúbà|Ö·´¿`©{ŞÖñİ~âI_>]t \¢®Gİñü“w–ŸQ7ñJÚuêßFu¨ßq`Ù€ƒº3¤gáÕğ Î
ç&SËÁ]ó|ÅÓZnõ	ñŒdáYÌbŞáÅÉç^õ5¥ªünP~Ç(©VDr²A©•RVHíH[Lìb´ûr„OæD£±—ƒÌÔB’‡×uÔ”c;Áâ‡ÅÃZu€–â‚^¨Æ+Ó,½Ç#!‘oV¹Í\o0ô[lÜ£¼‡ÃÕ3±¦-Ã™·	&4e¡E0ø¦k°ZQ“]œ‹éU@½	@µ™ÿ(Ó?ÕqK–´ø‰€.ƒşï2ì¶Şˆ8VİÁ §óå¨ùÁxîN©[2ŸXüT@±&DÇ;Œ¤\€«k©"Õá„¢“A?_P&×ĞÙŞ©AİûV/~7H/À39ì¡Ÿ•evïfKHòÙ™b½ÎÓ"nKÅ ˜cP4«è{á®]ÎÂXÒèWƒôz£ÙM©Be)!Ô™½
h+ÆxŞ!+¤<9îô€×@ù~m»ş	‰ƒÇz~É ÓW&4*XìúíŞó#ÚêKÙä”:àıÔ©¶_4 kûdúéİ)MîT‘š0 ÓK;‹´ñjXÂİ³Ÿ–v4NÆFpQ»+Ù0~=@Z\ç²Ÿ5ò¿oğ•ôŠP9ÉRPGcÄBÕê³—ëNïºMú¬ö%AÒ÷Jr®¤§9¿æÔšÈrÑBhYiMmå6*ßöhM{Ÿ%ïA&—¤Î*Í‹V“L  ×Û
`ï­Å €»€ÀÇå¶±Ägû    YZ