#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1783368359"
MD5="1ee2341b480aa38ad557b13adcac16f1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21392"
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
	echo Compression: gzip
	echo Date of packaging: Wed Nov 27 20:45:06 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ ‚
ß]ì<ívÛ6²ù+>J©ÇqZŠògZ»ì^E–5¶¥+ÉIºI%B2cŠä¤l×ë}—=÷Ç>À>B^ìÎ ü )ÊvÒ&»woôÃÁ`0˜o€®ë>û§Ÿ§;;ø½ñt§!'ŸG[;»Ow;›ÍGÆææÎ#²óè|"š!,Óu¯ï€»¯ÿÿè§®;æür47]sFƒÉşoomïöswcëi|İÿÏş©~£mW›ì\©jŸûSUªg®½ ³-Ó¢dJ-˜Ÿ'fè‘£ÀcÌ#›ÎÜÄ¬+Õ–Œî‘ÁÄ¦î„’–7÷#èRª/‘çî‘F}«¾¥T`ÄÙhè;úfcãGh¡lØ~ˆPÃsJTYÚUb3â›AH¼)	¡wâ7O^Áô¨N†ç &Ğà “\¦ïÓ€L½€¨8†ëf» JN«_„“
½ò= ı ıììÈh$ÍşÑÀPkOÔ¤3:9ê:§ƒaóøØX"YĞ\ouûmCMÛÏíQïEûu»•ÍÕ>¶û£awÔ~İfÍ-˜eô¬9xn¨(W)
„Ã³ +Õ#
ÔÛ„^p]ä;ls@{JŞö­Ö{u ×ŠkQÉ»}Ü9W©”“Ã`~‡ÑµÆª›Üó·9;ùä–(S[YÍâZnp	á
©a. ò­™xó¹çjìœò­QPŒÂ7Ìİ	l‹2š†tîÚe×oˆRIx¥‡s_ÏC×';^!«H0_²«º…	[çtrA cö½/ÄE–Gæt>†ÍQ8À£A‡ (P*3$:'ú,ğ"Ÿü•Ìê‹añoíg¢[t¡»‘ãÄT×şD¾1H#ÙMXLeYì6”Š Ï}è˜3Æ§uée/H@§£)4ó7T …Ÿ‡¶kµMØáÉ¹2„º¡&´¨µD-§¨œ tš¬ë\í¿t=E«ß’*€ÏÅ$ô,xÈˆ;€³á7X=¡¼éÊ2¾ó‚¨ù4E™Ñğ¨Sëä€/[)à²‘iBeYkéo¢]©élıÈÍëÅ·ë±E§fä„ë
€4³æšM$|j‰RÖ¤J%ë|íO+gíyÚğÂÅŒğ|a‡|Nÿ‚^Ñ	¡î‚t½ãæ¯F-şA^7Ï†Ï»ıÎÚ²ßäÓé\%µœe+²—“PÆ€*pD°»„^Ù!©×ëê~@M+åğ«ÄUDî‚×+æ+¥u„‹ä
%U*™$$b©IX‰›bÙÜVÒmå1±sÓvSJ|âduêyßóÂ‚ûT*™&Æ«Æï“¨SeÎCäù­òÇ&³3
RN¸"+ÙÂ8ù°¾5icÉ£¯ŸÕñ?xáĞvgd qpH­zx~†øw{{eş·¹ù´ÿo=İyú5şÿŸçŞ%Ú¤ˆÑœMÚS*¤ëƒçãÚŒGh²ò+Jeè‘8~äC¿ç†cÓµ`|%ŸZŠ‘oAŒğ¯NğRè¯ŠùÅô¿
>#÷ïÉÿ767·ú¿İxúUÿÿ3óÿj•Ÿwä°sÜ&ğQ[÷¤9ì`Äö+iuO;Ggıö_ç£$éEdn^sñ¢Â›GaÁõ÷dÏ¦™$Ä>™{–=µ!'`†ñqcJ…õ|Y`9¿÷Í€‰¨NVŠá‘_"W©ÊCâŸhšmQÇÛ2
˜Lî\çæeÔ™3˜EH<#ÓÀ›ƒ@×tbd¢c:İ#çaè³=]O†ÕmOÿ2E%«ÈYÍ[í­ù+G–_ù¦ËxD{n&L`¼Š2µ›3™D<Ó¡À™:y«†ıÀ{ÓçuMÉ[ı8°ûj•¿¤ıç%‡³úÿÆÆÎ×úÿ—Üÿ	^µqd;êìüÆÿ°ÙÛKşs÷«ÿÿZÿÿÄúÿ†¾¹µªş_ôä‚„‰ç†&¤>„#ƒhÄ·È¿2£.xØAQlü"4û'‹§D'Íf¿õ|w[#M×
<ÛúB]©Z4¤“Ğ„wàÃÿxÄòÈÔŸÄiœi™ÄõH¯E°ŞhbYnñáïm.lÊ‹•æ|lcÁKáÒa¯…uçŠRq¼	î¡ÍÂÑ8`Ô§•`›±ˆÖ]®cy˜a!?…ÖóÂêõl¹aD6~¨«O 0­`bùsäÒËQÄFNÈxÙuŸ;¶İèŠœ@E6~|øHÊÌ‰’’³‘‘±UoÔy<gıã,ÔP“ˆŒ-Üú4 ÙAãÔ½`†M:pQÍÓêP@<Ú5FUÂXFÇg£^søÜPõˆºcq ‡ªJ`­Ã£y '­>™ÎŠ(ûíãvsĞ6Ô;'~Ùî:İS#^âƒÈÒkÒH5ã:¢Øş¹´ı %mß¹$èÅîô$YÆÕ»#Ğ4E›¹ÑÒºÒ•‹HAiæÊ‹ša¥ÇSˆ?®ç¦@¨üà¢KÉëØ÷ÄöÌ?ü4
3€‹.xÊhN€àÂìùøÃ?{âñ¹+On´ 7Œ÷LmşE—hìîÅ/şx9HjÈ%ü^Å^±€O˜*^ÿ+é®„éäªKûuÌÎå¹=9GnÏ/@U4Ûz\)Wk¹A*1ˆª.Ÿ”c.rT[5ÕÃæzØ2®_é•*ÏxÓóîÉ¸¨B¾K+$„üôBY†Ã$<B'‹Óûg§/HjÈ‡8
‹ı9Ör YÑ6ëm®AMÁFËpµ›¥¶oßjOns¨ã£˜ìÏ^|dº}Ü9={=zŞ=isÁ`ç&D§°<€tH˜/O‡Í£[nKf¼­Ë{U}¬Ï~SKV—
béô©\Ş,/ô¶mÄr]ŠB- ¢*zJX·Ô”'9sµå ¡±‡ˆ‡ôp/¨¬Ğ\¬@^¼X˜ Å„‡+Ê3ljaœÓæâ”÷Ütg4;·_Z¨Ø-R)Yw¥‚µ2ŞW<à4XNæ?’Ú2iõÎFÃfÿ¨=4L°€İŞĞP5q‰íc•ti¿ˆ¨H«ß`Ë¨—O›DkM_ö^n©$¾^¿}ØymàÎTª|¹1¸R(ã¸%U‘Jv'AÇîY¿Õ•4¼ÈCôZQ°ÑøIB>üfû	KÔ^OÈJº÷¾?¹Úå>²ì<Ûq¸x‚L{Ş½=4iì‘C@Ë¤ı×dõ©İœvû'Íã[•«eCÀ[¥’%–¾š›ÖJµ_ÅĞ¦öÛÕbºª’¬/cÿ2|f_yY—3«ÕCé€V°A„ë QIÀ.ëB3˜œïn—êÃCYÉvK»ı =0ùü%’Ÿ×ç‡KÒ^Fİ]µò~Æä©hR’ŒG9š	–’‰nÊ½ÌøÜ6ác¹Tı¸íC’ïÙ:\DädÏÍ‹íÑßFøÃ6‘;†dQAVnafÓØâ™ç…ƒ00}®lÉ:@†ìY ¤··¤6éªËáqóhtØE£Ù<=èw;£X
wdœÂˆ'!kn¶Dõ%jPÃg—P“¸Şş)ää<</™’Ò—ó¶$¦°*_Iˆ•ØÕË²q¥2 (&=sraÎ¨ğ¸íÃæÙñ¾Qj[/’„İv-zÅ/½$a ©İ ÀàM÷½»ıèµæÊ„Ã_«ìÿöõ_~Íˆ‰› L£–®ì+ß]ÿİŞ]®ÿïì<ızÿûÿqıw¥_ÍtææXÿ%ép->o,‘øÖƒû”ùËì±Cym—#ÄƒŞÜÅF]<&^'.+áuµzıËp»¤XÀÀğÛ¡gÎaMB©Æ•,“ßµ¤êx>?hÿFÁ!ınw8ÂşÌ	~ƒx-q	ƒƒrp1¿ ÌDós Ü'ğÑép~?/=Š¨¥ÄC™W˜V¦Şš\¥Ô÷î²÷(§³Œ$„Sr÷ü¸’<D%?óıót‡Ô5AlšÏBïÌ¢ÎMBüÀvÃ)Yœ=ü:¶OCØXı4‡Ãşm½¤®å·ĞüÓËöéA·ÿ3ôtÚ†ÚØİİ…‡£~÷¬g¨¾Í ¯úÖ]#ä¯²Q*ŠñŞq"?KßÙĞbJë¼	i`4Xà5\$/c†@ñ¤U¹†P,mšÁ_"{á¡§bşárİó1ÉRPrWTR•ÅO®ŒÈo¾úF4‹€•£¾«–š—Gˆª\N*B—Ä"‰ØCÀÊg@¶¨§«‡lı4ÍxŒ4©ÕÎ!¬Ä¡Êm @H-šÒ%yŒóñôÚJ~@ì7ë‘ñnRslkq÷¡SK•Vw­İwÌÌÕœé1´VL¯ã6i€1aO‚æ~[Ny¼!n<(à=Ï\ò½œ¨íúºP4B¡.ºE•!.‹U*kÚa”ßø³F^À1Şb9£áÚGĞŸ|Â˜ tÖÄ.ÒuÕÂïuEÉêàQ$±-$UĞ,¼!F$9Ñ¡Ra\7m—Ú.^d.àÀäL¢7w<ÑJÄO¹ânÔ™ô¤&÷`Ö·‘Q‰	.Vh.(.lû¡Æ‚ÂÓ÷f¦Ç–8xhB’áZHœãÆÕ”„>•¨u*!i±>®V7-¬:ÇB¯xèü¸	ğEK|lX´Ü”E^l2 µ˜"*Ñg¬%5P^ÛÅ¿{µ£~óà¸-ƒÈ­¿:.Ø¼b’¿Dô™cº¸É;)ñêÃGâa /
 ey·ÕšÌUzN—¿ËRX:ßmi¯s½âÕRÌó“·UboŒt5ù	¼ØÏ„¬Ü‡<‰›†ÌZäe»#‚EKÊÚ'b,î÷h¸‘/A’3rM¥°…	yu¡^”G`&èša«‰/yŒ ‡t¹ãÏ±'e„B0`Â(Æık|æ.3 ğ=~Ìè£T»Xš÷fÒ±Èl€¨‚kZx/"ùKäñğ1¬Ì¬+¢’Ù½tiĞtœ4ÒG£ë\Ç×·5ÄH_µPˆ•ƒÜlÌ¥;>Q‰ò²ˆ°¦ó·ØeÌ=Â’Kû73ˆ½Xmç f0<ş¹Ù?àKÏÛÂ'…”•T¤SÅ8sÖLš¦T÷ËzS=/ëŒ×²¢—)*Ãê½<*†ğœ—Ã×Ñ£Åº	y	Fœˆ$Q=ŞİÀ÷’ 
ò”Çm£±oÿT»©JÌyóäİí¾ıİwëÀ@nô‡¡—f¿»•,Ş(	á^ö“hıå±qÅÄbYë2°C¼‘;ã™¾K ğvÄtìÍ:¢QrèobgmÈ‘ÛG—ª–åŞ”Ø"ˆI¹Ê ¥i §‰K>B/ÓÓ…ô ¯¬•Ÿ¨wêíáª¢\‹qĞ^±t›ö“K/¸`¾9¡1s_uû/·3¸¸KÀÑÊæŠYbÆ¤ÿ4ßæì­{^Ş¡9ËÅqvFRÖfÔ
bâÓa¶béwÆÓşü3ÁĞsØí2¨¥&xz ‘J¼S¾R“65æ¡°ÒÆÈF#‡(“Ñà¬×ëö‡Æ¢¤Šä²©¡IÜ«=Æ¯uèÀˆğŠp†LÅÂ|îİk+5~±.–05½«pÚv Ü7¾)\!(Bø{ëŞ!_¢3.²GÊÄë­»Z¶²¾ÊÌÙ=Ú»Ÿ©3âß³œœ½WÍS ÅâŞºüå[°Ù<6€è˜dËÂlrNİˆ`ÔŒÍ¡ÇßÉ;¶bÉåW¢›¾ï¤ï=¤Q`uÂdğ¹Ş#ìa`ä J9§Á÷øş±Qd,,dùRÎC'NéÏí9Õ}Q`¥u—óæì¶EÙEèù<ÂÎø›ÑLÚøòÈ;‘»¨§æœÙ–¨©©·'Å.ÂGTÛWt’;z-¹›¦ÏÍàZ•Æ“rÏ'ÏPeQ¯Áà2¶” Î]V&‚Õë6t1Eytuhäã†4˜Û®éS4L4]ûÔhfû³¡’2ã±ƒ!Õ÷a¶ıei8‡G_ìu€×ö¸¸/ì>®)ò_´“±"»O`;9Y!½
õ+MÜ!ÜçOñÂ€±Ş{aMü…ò>ÛÅJ‡ +€Íù–€–""UÚˆå‹|ÏÄ³(Lê˜×b•/è5Ø‹¢¶¼ßë@”Æà°öwöóLzÙ²™æõŞŞkíÅA[;…¥,hû*¤ü½›wÙşı÷ Ä7¼4ˆu`|­‰»µ¾åÔj¾&m$:qo+Ùj·5:iŸ:ÃöI’ğ—êæ¹ç²“ï®HÙ8èöK;`ô9\ˆGíÁ‹a·ÇÏÓA
H‡7±MQ½è4}/êœ:~}æzsÊï–šÈµÎ®YHçĞf‘mQÔ±#,„«`—"çZI|ı<œ;u44)m™:	›n.b¨_Í²Dq¶Äg‡_&–	y ŠthÌælôGØßdvğŒ{^¿„TTœ¤î sÚá‰RvOø}#QI FYXÖä!ú4 ˆ”(™Òö<Š{)J÷k”w·†z¿KV—<FÑP¦ş,*P“kûˆj™ÙË,JÊ¢r¯–‡Y&1u`%È†½7f¹2ãqv-öıb®c§V»éöÚ§¿@ôÏo50î{ëB3çÄ¤äãÙ[?ìªë¹ù¹ƒRÕ¤-4ç$Š9ÒŞüä€Uè}œĞ1%‚™î9/ø/(X:’Œ7İP äÉAZ©dí7ÉÏouøõ0'i*±±ˆµ_?áÀRÈOÉú:©’cóÃ?<Qâ ÉÿŸJ@²¹s	lí&O}!ƒÍV]ˆ cĞ’‹}9qÅ[‚ü:'÷ˆ2‰àß<E“"SzÙÎJs,“½W©Æ¬Ìøà/@0şÿô˜÷Q’’ÿ(~dš„Vìs¸´pÿ‚y_Ê!©3O±?/Ãò0¬ >_TK„@ê!¶±”—öÄùÕü:0ä3:€kk‚y[Øá5†%"?Œ'f3áÒÜ-–p@Cc3N¤ÃøŠ‚g©ãÊIv/>@1É~eç|?øÔq4KòUcGZÍ Y¸÷ß¹SÜU'
]qqZ[ûèêG2T]*cŠÏP?Sá]“îàñˆºâÊq­ĞÀ™R‹'¿3t&oñ]å•YwZÇÆ:è!XËœJªåÑÏÊ8œ¨%¬Q%ŸCîF»$œœVH¬w<jr|™0É¼‰Bî_ÊJdÙY¥²œ”bTÁÕ‚~]]‹ÿµ€95ŒÏ–ş©ÊçFAnıM¯ÿo{_÷ÕF’ì¹¯Ô_‘.é6àµ$$ğÇ€å¹Ø`7Ó8ºgÆôÑ)¤W[Réª$0íöş/û´göåÎÙ‡»İÿØÆGfVfU–$hìé»+c#UåwFFFFFü"™œ«K8¼‡†¯æNŠÛ,¯Œƒ¨'*uwúUÁŸ’JÕQ³2Îoÿ§7zB¿š÷ym­oÌˆ(µ~EßÜÁv% ŞáeKúíŠ«àç( {2””k¹œ-ô¨t£<ÄDÄ õVéK4å)ÀšÒ!²¸ÆïŒ²Ÿu£T\¡·•÷ĞcXtÇ‡EĞñ÷„$õÂİg¸Š¡€Ãã“¹ò_Fc%4V*—½øxZÌTá·W6æôx_”¨"ßËß¶N6©¾àvƒioW_á°ò'æÂ¯å3Õº~aŸ\9ÓQÙ–ÕÕJe2@çkTf¤µºn¯x*s‘ÊµQBwKó·¤»±\;{‡UŸıXë.çÍÊ‰qæÔ–ó¯ğvóP­¾b3ØÔÙP6c ª6º¥£cÂ’PÎ¨š,¨G}Ú 
m5àAÿÔÈŞÀ¸j‘Yèd¤2®W×«u¹OÀnÜƒ­IïA¶D*F²i&3¤HåeP]äYrcZ˜Ñ<dºh1’»?vÚãşP’éñùOÀ«a·èô»ü¥—àß^wÄˆ%øƒg€I_%¸:î^ğ÷ntq‘şšåw<^6¢A¿çÆ[ınƒõ.tÃOÿUƒAÂ÷ıüÿO£PşF-NN ãÌÏê(ù‰¡u¼ü†.mÆ×4.–V26¾ê$İ˜«~àFÙ2Np9ìÁ‚¹¬ÇüM9äQpŞ¾ê$}U·ßcÕß!–EÇşÁ˜ûøSd
ÂaùöŒ¯²Òş‡àÉFD#_Q¿Æ_áoĞíÒWPù)”Õ š•ß~"!„¾©—“±ş"‹öBÜ ‡À¹®×ømØ‡ôwÒôå7¢şŠ0,øëÜıá8Ê?ªØ› ƒ]õ‰(RF	®î«ô›L:#CŠ[;‘/Ò“ñUfIş:<º=Drc´Eã¹¥—Š¸M?³`Ø$&ÍI£}èRùŠœféÁ– =•#+‰A|Yò¼Ô>ƒÅş]Ö‘ûÛdóš&”uVÎåÚÃˆ3u68³ÍE•.Jg5U°;µ;ÕwIG²ÊFµ~F³ 5~åîÈ‹ø/ÖzYşÒm*˜{¦jZL+äsÖ¤W¢OÅ½®’&ğR'=fˆt‡Nutûr‘`Ça×Üõñ@º 9lû¤ºy”½®vû@ßÍg$8[R™6ûÜmƒ˜­İH•ü.i£¸ÊÜĞèTÙÆ¸îzr*ÅF"ã·ş^HjÃbµf%¯†¯¥M©JE´Qî<*ğœúÜßL´o²¹½–uÒÔí’¢™BfÄò_Î`üò'GjÜp,“wÅ¼éå‚õÛñpœ4}ıôÔ;Ö´‚Ê2›)]ÊƒÜéÀDä”×Êpğ—@EÂú?ûªÂ0‘$l¾š@wÄÀ@hhBÄH<~/Zòù>>6îà}¯Íl¢9íX!açS—¥öÜùâ3>øF%K–~÷4…Bûèv<Š.åÉÇÒÒnr>tÙÚËßê†‘YLÁãé¬gîô’!ıáÊ/¤¹lÎï­cò]€Ï8';iíææ[éË‹,L§¾Ìo\s¤ìıÎıjÎôØ†É“°gs»Ä2
K˜)2ØS™1—Ì-`÷!7ØÛ@
OPœ˜8<9\&÷"—˜ÚAÅN+f‰7	FGS¼Îçkíœì¼i§ô¼œ‹õ]ü‚æğâÉøOqéqpã¼3gZ‘TNjcWvo)Ÿj…öÙrö…øE tï'µ³Z9S«]âù·ÔKòY·Ü%’ãş´÷VnGn¯#‡ÓQŞçÈv9²<”ÃÑt£ûq7ÊzÁï‰<ï£ó¹æ/Ïòº[Nöºc^é+ä}!ÿ(ív”™@Ã&Õœ)×ìwÎ´eú\Më´³=³;ıŸ <ËC,ıºjš¤ÜÚUìnb±{÷›ßAŒÖ†f¦zSš—7í’ªY¶W»Ÿ2ÑÎNÊ"Åí|9PJ¹S½î¼u¼t÷~LW¬üŞÌ(İnû§üNùÙÔØ‡ç®Ù1+Ğ‰Â…)>ı¹_İÚ*b&9jĞ>oG}Ôä…‘(ÀÏÑ€¼0FÜËJ$ç1][¥9VÙ/'aCÓœÚ‹«ØB£„Õ&X+c 2¾Ùª‚«³€ûÌ»æÆëÇä%ßˆ¶{ğ}s

ŞRÉöÙSy6I%j•¸ĞúÜ:!]äş>?Ş>ş[Z°Úº6Ëé[¬¦DQ­z]}¹¹lÔK ø+å‡«Ë™ÅÈ— PTÌ²ÅÛ@r’Ü¨Ày²À!ÁÌb;æó¥ã·|¡ëÒ2ÿ°t`ªoé)†ucÎ±¤àq?é„tÌˆdp‡DYĞ_U¿—\cƒ)t²¥S¿¶¶TETóY¥É‘v—FßTvdÒ—²*B}ù×?/;m†
V¡ÜÆ¬Ufš<gDf6F@„×¬ËÙÊ*kıppe‰íËÏÿŒÇÊGÍ¯W×|8tâ.0™¦zòºòÌÿóêås^ˆücéùîà*Å4Á?$ğ“„ŞÀşû|ŸkKñêØbüÌ¯½ûa`njÒ8M©Í¯ğ…/Ë’*D¾AĞuYE<+Íü¼æh#½z^“}1-İ²c$Y£ÓÄ+L¹`V=Ïa\<Ÿm±M40ù®Ö‘¥|nbı¬‡*M2ìAq]öP-¯(ÏÂ^×%°Oû3²}‚Ò]%À_`:kÓ3Y°ƒgå˜—ïÃÑª¿´*¨œ¥R}z–™‚¯j†|Â|—´:|¡X/. `Ó &¤lÜ¶üX+=fßaNÑ Æ9Ÿ*lär!ÑŸa;évñŒi}Ù€ãÌ qª›â¤V¼†>Äâ<,9oPb4’p“¦İ”¹¿äy‚]lŠ;ùãÙ­`Ñß=äD¤_jä€‘_ÿ"#¢lÕrökÆÿ«¯76êÙøõµEüşÛ,ü·«ÿm­Z·ñßèoV˜¯ÃhŒ³ØnÄ‡ˆğ£Î‡†Q «B]Á™¯r/Şƒ—êeiÉj¾Æ›Wz³ør{_|¿}¼‡Ní-®öUÜ‹Gèò©¢T¿{¼³Û,/Ÿ…ïê[ëş²şvûxwÿ_­Á»õô]ëô%lÄßnïàëıø`÷ÍñŞ‰ÌRO“+ Y]ã]Û*“’mX	·ÿ~º¯ØHŸ3Ò¬l&<Ş>:iï¾ú®…¢“_»
Ør£;üp‰[^¯¥Oƒ!ê“qb¿ê÷!½Ä#f’Ïª¬\ŒĞñgĞõ½U/yÒ¥@{Š…Öm½ÎL‰GG¥n.wÃNd0Q“S©Ó%ºÄ€œ9U´ÌG2À690vğúÜî(¬pØy„×Î]ÑG Âh@oPxäéÔGœ¢šØ¦ì–M¼µp<º‚cfëÈ¬İ€m¥~æ‹n&†?ø_|ó¼‘—àv¨¿´õ”+¤9xx1|$Ğ*T<DÜAëº\Çn“*İdàAƒÇİYi5QY"oô4Œ°¯KGõ‹x2èŠx$êÑO/×ŠÜ°Qğ¸¹|px°»ì3{Èür#ÿ†®#œvƒÙ)$ŠÍJsBÆräÛ‘0t qu5b]°=‡Ú —d_I_KñÄéçîû8à¥`t™JWõ›F’"† úš1”ˆ¶ì±Ü´¹R^i¡ô€òs'¨¬ã®­ËWl!‰nC@-T(}ƒ'({4WV]øÍ7™A4€©¨,¦=İZŠØ®£©§*L¬Kh]iù|­ÕÎj5ñyÕ„º—)ğ´O‚°YâÈ5K%–å…öXJ›ï‚ÊÏÛ•¿¯Uş´õãª¤ã¹0-ÌÃeøQ½!¬ÁIñx6³­J; ZWÜ>BTí¤H'¬mÌph¤w&Yl‘•Mëhïädw§½}|¼ı7,UÎe£‰J''ËÌÛn(Y]lKr¦JZ'iÍrîãĞ§Âæ°9<ëMg&“6MÒ•úŒFÁ©¢DîÒÂ*… ±Ğ)¹ó3:eŒM9ıÎİHK2¤fÎH^e”2‹ZŠÄ‚¼Ã]ø'¨T¯„Ié«èƒŠ¡I‡A‚Lÿü=İCŠœ	¥Ò¢hËC×¦sk==éö„u5Ëõ-ı[¯`XQéSŞ˜pİ7Ëëú©ìŒ©\´`-.•Ôq°ú¥¬”XÖˆx	lY)cæ<L2Ì™Dñzı6Áõ}dÒÕ=N#‘İÑo*1qˆI?É‚÷y’£}êƒ>pHØNĞÍKş¦¹A ||Æpp¾’“ê¥j ç¦aÂLÉj›“ÃÏ0«³5³üÆ´.‘ôÊåG"ƒáŸåüË¹/Ù
@úÚ¨š”-°c7MË”Ëe[ÎÃĞš°?JçÏwê¾+Ûì(ñ¥'’Y`\Hé¨´ÒE]J êàã0è‡$#•Í”0ëêíÈ2½ı}3£í™„kègÎœ’…nGkŠÕfEQ•È%‘Z·Êæuô}€ÑÆ»Á-éíw‚¦ôV'SLËxßÒû?”·-µèvÎµÆX%§0XÇq<V„Óîc ¶8èG«$-¡±9Î=›HDıa;
kÆJ©@È›x:›Œ¨oöbFë4°Ìddy²ºFŒOöëïRh•Ñd@¾Ùœ>GÑLùe˜œvá¸ë»Z­"	½ø¦Ã…ÿÓ™‰¸PWê;b
fB;w2î†X§9øe86VG=HSÁ~v]8vy6Ô_e\CReÎŞ•
L\ˆûûúb%à[QÖi B¯(T•+iaÙÎ!FÚAÓ¸A8&€²ƒ?@xºy NF7Q2F|Ç¹•Øù÷İMú‚"ÍG&(k2F˜AØát bëÆy8Š;a’ÄÉ#A¬hAÜ’à2ìy eıößqGhEƒÑ!‡Ó„‡\êå$¹Éğ©µÜD¤I§LÇ–er'Aººö–Ø­¼[ûQ½ï't¾~¤sˆH ˜S``¦ä'Ï¿©‹R8ø·	*éb{XP‡X(ÉF¥Š=Ó±Ø#¨H¸§í‡ Sü„r=––°Uõ-*Qt“@…©5çgt`g©{÷E ‹¸ÿØÕƒ1”Ä¹R¹â„×ñue2&Ø¢1º"„İÕlâ6,ÈP¹ˆ>VúÆrºÔ6\ó”V;>Ò(LôD%Ù…cL*¶½üIk´p
¼%xXÁÅÀ.éoåäQ~ˆ3&ËY${ı33×5sEÏÌmüÄsKNqÿ~n9€¤?aVb~ôy<è«Äÿ‘4qÿ±ßçˆÿóøi#ÿgıqıÉâşgÿıÎñß»âÿø&•Ïèç•Šõn…r—é€?]#Xa~ò•"»—†£”aŸ@7çÀù$’•ìÈ­ãÖ	6‡È ùEİ°fBM7¦qê·šæ£{éQÇ‘ƒ­R|Ï³N¹ºì»ŠŒŸ#Î€8ìu…4kJŒ ÏWY•Ñ…‚ŠÉœŞ44ú2<´Caß¬Óxä:Wşä(N‚Êe;›–c_}0“pL•ÄR~å°û3ÆîPÆud»køÑÄ.K[ZUÎßÖ¬ÚïğÈÍ•’	Ëâ@“Ay@4Khù×ñÈƒ_&üß,@fë,‹9r(£ªt9ÕMå%$£‡®˜¸ö•ñ‚ğ¹V(tM¾¦‡4{véÏÈÆH–Å±Il2‰lzsW½}p2³^L3½R™"¯sQDÃÖ8O–°É{8el·oÓTY!õÃÿ'§-º™ÓúdRÂˆ4C¿¾:8l¿9İã/ß(õõ–:iZÁ°+P|U<%F²ÄÃc0ê?‡<úšï·ÿñÛÿ†UšÄç#T ±—ºÕñaÈ¥áIU<I«¹"Ê+x«-*p¨¯ŠU“ÛËË¹õ¯ê€$@œæ…i†2§
tD« hÕ”ªLòe OÁHŸºÚBòU(0R›5mE%dÄÚ7õ[iã–¬hª0V,E\Ë¼â¨oj3@2êŠ–ã¿zv>ì’Zêƒ­‰æ™.îæ¹šÇ%lş½½²{|°}²÷ı®‹¦¹ş¦æe‘ƒ×s»FÔÙ€kÍÂ*-Ú7º·†h_Ø14C›±dSªpÔ­)îXÚJ._F1ÉŒ“÷ñ5–-ø­W×ªkö`ˆ£q°»»Ó>=Bî¶‹;S³>Šğ<
 ïkµÃa8øËÎwBvVpïåÓgæLiµPp»Ï*ğ:´ßn¦o—İó™Uw)=âÁ¶ñËM#t³jî3eİ”pÃî#1Ih³çõúµ™hÎfC7ËêÁşIK{ ² ©âÒÎIîjhHÃXêI­mÒÛÄOL!/÷¶Ú/ L¯…&¥~¡"0cfí¬ ÚE9²rüûÀ}á»jS—µİ(qtBíTóWcÒpÿù8½p˜&uÃój—qÍÛüµİÅwx5
5¼OËj?T¢'ƒˆ™/¢õÚsï©wˆè{:ĞÏÙ_ã:	¤Ë@6ƒ ‘‘èRÄªßşG«¹É®lƒ8L
•ÜÂDàf_C¼Ş}»7N²p´r‘pF•Êp2ºõòøSå!l*bvÂzı!í>rA'áø/Ç»ÏéÙ/‚Ioìá#ŠgA²ÃO¾ÒHÈ@uÁø}g	¯½™ıï›,b®j-$™1¥˜Ü|XIQ±a¯Ô¥*·‚È– j×lpiŠ2KUÒ¬æ:B{2‡ñ¡R_Åhií:"µ Ñ“%¦–¢ÖÁ~Ô,G˜ülĞÇÃ!²i´Å÷ÒŞ)í
¤•V0Ìtş²ıı6ûtùå4™®] Af(€ÛÎ%0÷¨Ô¦&–u)†MÕ–!5&5Z§¬$–n8L<ùc'Ä»CT3$™˜SËjÜ6—kğ?.k<—ÑfÖJñ—é\½¿ıÃÛ)SfÕ9Ù`ŠŠ5CìPåC¡I…,SešYœ@O©Õ‰ì9“p+E
G$}aìüÿË²?t%ÉœgûïèQc
y[ò’”n›x§HS©ó‡<êf”æÎ’Qœ[æy
uA·lUàáÃùşñBŒ2ÉjåhË¨ÙÙcíí~/CÍ`ø5#hiNš^2l4»;{èœ­/$Ò,·‹ $›İ%ËrÉ;‹€:Êû{/[ê|D¨½oØÿ8•„1	ñÄ–K5êÀNØõ¿GqB^uGü¤ÁÌÚºu}m™½U0øG› uí»|ÉN[»mfMåmi@*³q€~“b%£AU6Ëéñ~S76ËÃWqÑL±g»4f ê¶DuP·03ûˆØ°¿÷j÷ µÛ‚Ñ;Ş~»‚7Á*•^Ô		qÍAÜ¦8*„²£ĞÄ_êG; ­_å°¡é0‡µ¾İ>Ø~³{Ü~õvÇ¨ø¬ø‚6á2ı±é4ÆÿİÅõå¾JvÀd{S‹nHšZáÄºßËlÓZ™‚ßm%pT\Z6Çn9õe“tˆO™Ş›)Š¶ı:q¼gÑòM86„¨ƒÑnH¼èr<1”4%¯.(Â•Ñå;ÈĞ@¢Íl·*8?”ûÙÊñîşîvk·V%xz4†Š¯ÑÖÔ]A±ùAA9÷d–`vŠ³”¨ÓÑÑ1 éìî¦‰ˆ 
FU+*³Î”~vü|»DÚ8N-õ^îšm()Š?J¨¨7¾´©\àÀÿÀ¯3Ô~K@	eæÀ§õ~ÜEp(5Âë!,U˜Ámv€§¦ç']›B[¯ÔÅÆ«ëc™ÊG3—ª±Î$AP`a+Lfë$²ƒï
ô‚#_Q£&cå×"‰1T#‰‚h"% LŠx¦T>“zòEŞ—yĞ›İ¾é{†è¡!†'¯UL,ã¼pa@xÑ\ñ;=}„Cö=¦É’¥cå©JU¯½D3²‡eá7³‚É l¿%çÌŸÕÏñÅHÌ­yîÔÔ>3Îˆj_AlLoi´³ã8_Í)Nz=œ–±°üò'ıŞ0«ÉRŞüdÏûñ\d1ıŒQbÈ‰§OŸŠÊñUÁ™`³ÆÂ¹ŒfeRÛÎ¡*^¥wkÔmZ%O¬÷±]À²ßŒOFÑ¥}}¹şÉïo«$2–£Q*á¦!Û8ƒÜ¿*NèzQØ>FİdM­´:w­ÕÂj­Z5Íxñ‘Úb0¦Í†zê››Mö…¼ôB#a(aÄhx™LP eP2óRa
‡ğ…‰
âë@uæåìÛí7{(“lµ÷vvÿÚ\%&á¤"Æ»;8^FÆ5Œ±;şí£(F«}2H7QÓÈ/¢mÉ(î½Ï“¬üÀœlK=Wuœ@öûxu!›‹©ÑÅÒÏğOa½µ8ë•!lrØ5·¬`°!sÄÌmÓ­!J-²AeSğ¹F…ĞğÆtÚzïúÓ]‚^C¬À8G‡£Ñd8^Õc(›ô÷½#)7äƒÇôÉàçhh%Öƒabæ}f]¹y(v¾›¢3šbµÚq×í có\v²1¯m5×ˆ³nßMª+£6ùAŠÓ›Ûã‰€Ò÷æ=nnÂ8)¤!ôœckaÍ,¹2?Mg“Ád¹RáÕ;ÅÅ4;{° ¥°: w0YN¶ûFùj¡VWDkïÍŞÁ	p/VÒ"ß¾1ŞÕyôæIîƒH6'È]%ÃTñé“Ú «tÊ
g3+ÑiRPÍ+ÊÇC†+¯‘Hÿ£€ ç¤èÓ×ëş¨ñ¸Ú¨>ö]‰´ZÃùv{ÕË8¾ì…U i(1NHï†w•¶,Ñ	«0ŸÎ’aø›~q¢¿ÜĞƒ`R'#>Š9wnş64YZv%}œÒ¦ÕÉ_²ÏR‘Ä`5H’ƒ›sç÷çó¥WJ—†ƒ÷–nàèû‹¨"ÀvŸíA¼›¢+¾§¾}IEê†{ælC¿)
À,¦7W~ÔQÒ¿¢ñ#}Ã«®3_v« ¸x¤M]‘cáP—IèÒ²	”ˆhÆÂ‚Ñû	–%Lë´œ8~—šÓ[BÇLİi®ŒÙJMÜ„áûv»öMïñ±¯WXÏ‡½nÊŞµ´½-ßÆï¡[Æ0×¸ÌÙxrß›İ¿0ÅHòï)ğ.¿¬é/O÷ö%ÂlaÁáG`œIY¼üÓ†ÚnÚ§$çÄ'8|g.µôé~0«
+­˜•8}Çm¾ E=o†`ø¡MÈ/h‰4c´¤˜øvïÀ°,$´ëÅêAK’›ÉŞ5³±í…“±‡1™Ó»Ğ¼4­-œ©Ñ<RÎËbN÷XnËĞE÷ÈOÓJ ¶ªm•—JŒ•ß–zIæ@Zşä\6dAÈè¼z™ËÍ”©( Û|ƒˆ	¸¨ŸtxØÏŒnÜ*“H Ú/ˆ™›‚o’ÔE÷4õ‡iâ´6Ş‘Z¬T1Sı÷"ZR÷ÂRä‡Ã ƒÍÈLyKj=f®šŸúæ/ƒMkİgÜbäŒ_ªìIµ^jº'mğÄvÏ¸8Ú[n Ğ½_Yo…]ì8—u8èİÇŠ4iÂ<	g£Py¹P–ŒF®‡9‰G†hŒğ^“z`¬ªÏ™eÅEÉ%šŸeÉ˜õÓY1›Æ
j•İÿ¸İ‰¹WŸ›éWQ9.ìæÌ|¡ÒTLYÙîv»´˜Ç±P1ñÄ¨&"^]fYÇ¹ÕÖÃ¼‹ÊNYéË5fšO±ù_Ømè)ĞÏª‹ô:FhŒã²î×¶¼+}û°*’ßş¡œïEˆŞÂ¨gHE<» Oe%7ÄAÍ“~.digX}A‰MÄˆ:ïñ÷ª(™ „¼€åËŠ¯ÂRQAb« Œ¦
b`l:<KËY•/r(cÙ¡#†—7VSA8J6+€õ%YAÈ¨£»GE‚YS£¥ùL(n°.HÕktaÂçèºHCSØñohÌqHQÌ½$sA/ú9$¦ê-åiø3cÒ X;?èRÆî^.¼f±?6X‡C ƒB_m!¡Œ£„‚9ú2¡tI0û„”æoÕ*uŸa» 80•ce”ÿlD¤·ß˜¿R¡JğMmX­à#2ƒ”	D6úHç·ä{ŒÈ†Díı`k
GÀìù#k!‚4D°(.‚Ÿ	àŒİH@yMN÷Ø’Ú£tíõöZ{-ãÂ•vuÎÜ¢ÍIÃ’°B(º][62m¹ec6ÔùT×nT?Ï;#ÌÕNËV$¶ÑîÃ^Uv|gk–~b-æ9í_9—Ÿfãh¸Ñ¡Xœì©%‰Ìø~VìÏÎê|ñ™M`åŠ$!D¹%9Óë%gàÛ;š¶QR˜t§3±…Æ‰¿%ÔšÎ Œ. jÈH“İIğ_qhÒ¥¥—(^Ó‹meĞrŠ¼[Õ	¤½ËŞÙ}„Q6²Û;/Çñi7¼òˆà¢qˆ³¸_JCÖÔÚ÷ğz@DWV¾¥yd6Ë¨†ÇC»ÑE»³I;–İ’L‰¥®ú­Å.#­d„Êİ˜pR3<¼Ğ‰{¡ÏÈïı?/	¢ôaÉ‚O6V—ş²`F(Ãv¦­˜ŞÎı5DÉ¬°U°[pƒò’ØıJW–9•Z%¾óRÔÜ”Ü=+ØØ*é6¼½pk»f]°9Oãß¥™\Jéà-%õ¦Š@N|…5#Àª7Õ©¾0»'EÛz25-rl5S£“İÃó%v;Ÿìqp¿¥™kIî>ğ5ı’^
âËM“UÄÑ:©ã8Ş|ìÑ³ÈBğº“sÿ¼æÒ;5ëÓ¿æÏ6y0<=rÙMÅøØ€4üÉüMU`Ğ6p>™ºÎÑa6•Ëx{´¿÷jï¤½ıêÊh¿=ÜÙ…#x) $¶g>\Ë-5Vù78Y!QÇ+qKÉ8¼©›Ú5®MBQŠÏCàÄŒÄtGÈŸcDg!u˜‘ÕÌ°”GÉ‘S";r÷Z+ååÖ¢Eá¶İ†k7$›ú#ôÑ`ÉÈËîƒ¹êè/‘ÈG–Ù=;@İ]©ÀOØs	¥ŒFĞ¥]%"(#E»S°4zGy‹‹07'÷–å`ÄY³k(ªˆóÎ`ÌÛ]l'†HÆñ‘T•NÙÈ2Û˜W°k97ÈÜ¶1Í¼.]$Gq2~%Ãæv×òùøoU‚IB}Z/ü"ñ>~\€ÿ†ß7òñÖøoü·Ûâ¿Åûé8QÜ˜ÜÇÅMî)^gÕÁæbS™©]__W¯¢« f{2È^=Õºp–¨µ0ìO…k«|¥,;T ½qEG
F_	‘ÏÔ•VÚ•U¡U	"Ø†W1?÷¾=:Ş=ÚÿEò€—¨¢Â‡íwZïèë+üN’2æ,LQah	\ñ¢ïºaSC)š÷Ê¿• Fè*MH¬0œuÉßtEi{UA–ùmı,šMQy(~4ìHaœƒKu*?à…,¶•ŠÌÎĞDìFÅuŠÊkQ4¤Â|>Ê­rTk·¯…ó¨z¦ğ*à}kr”|eüÏFıéÆ“şçÆãÿ_ğÿ;ã®»ğ?OŞ‡”5¥ô91@;‰µc\¡”ÒYòuB¾¥º ‚"¡5®¢œ$U<¤‡T…4`X ¼ĞõTBÑß¨sbÏ›|D\D£dü@ØXQÒê˜ãÁáÉŞkôR?ØÁ ¿Z£9ˆÇÑÅM‘ÒW=­~hr˜¬¢ö)é ÉÃ+Ô'ÓYò¿¥jÕÓ’²TGöìÒS:ŞŞû»Ø9Ûo_îíœìòdyêÇ8²zæ9Ïô#$³¸/4³*ºİ_wŞ´w¶O¶Ñ÷ Õ4Â÷nxùAÎ,Äxé{NÅ€OK$óò‡İıW8>¦™cú}¶)Û©Q°i¢äŸÏÆGñu8"Õ`…=qØƒ•tJş9 ”ŞªÇ-`UGëèˆê>?”°k¢døà” ¢DıIumCìŸ´r/e_ğğ[ wxé|J¥CÔK€°×Ç‡@$;Mÿr€«êµtÿÇ› IO¨õT^ÖO WÍ53‹f?Oùo¿CÕ®3ûy×oùbØY6S¸Ğ÷(HX?/ë±È#AkAûHr¶¾;9<‚uù±{‰BÙ¨‚òñ*Åb<<:1ZgA›ød>ÇÕÎ$¨N.úcÓ¤èÉz½ñÌs@§˜ÅmZ ^¸E³.¥“İÕx ›ø±;Iec}}ıéŸ°[‰Òø¤>Sèş²v®ßd<ªš£ú³s3×íÚ¢ìº§c”ûY6îã³'í'¹¶‘oÌ]3kŸ¨iE€PîôzR­Wë¾—qÓ™:¦-s0Ï|Mªycö&ĞLæeŞ0©®!”IİVÙÍåÆSL¶Ì=™ç²ê¢î ;«ÓÊ"¨mL·¦ÙìÏajšŸnM3ÌÇÜœ	¿¥mô“mVUí[s{»"sö©İlP?§{$Lï\eVç¨^:§ŸN¤Ú‘í§UÄô—Y¿‚Y?»GS†ÒDHyÃe4~?9'ÆğSˆ¡g‚©È
¤L”û-rB¼ÊNU¾=sÑ´ìtí½]•j
$<zLã%%ÈøğàC%‘ªX|€¡ù¸,ÜnZ°?Y%­Ü	¯HN;Å?…1º”t±(º¢B8Ğìlš
`Ğjq¾/owNÛ{'»o­ôn9«ñ®ŠŒ£¨*ˆ´Æ1ğ/9µš…mTëÄ}ìçòò±¹Ì¯—=Ã¡ÚùKÒâ»uæÆ‹>İº²:–öÔz¨kâwËákÒ—ƒ\†aHkˆ?Š.ıxR„ƒN˜Ôø%,¢q©³U|®@Ê*œ««ö=Ó×¶ÛfÍÄ¬ô£Ää&¤*¦ïïnïS©’÷›õTGaĞÓ…Ioòt O‘eé‘Eç&Š3F=¥.ãErè¼9QÀ“Óê#[À9éæ	ûÙ“ìë¦¯Â
øém¸³V;«ÖÚŸE‰ùŞs!*¹Ä™Çîi¹ºLaíG">‡Ÿgğû#›Šh G¼1F½
1Xj€I=7¶1ªWƒêÅ(‡äéÑ Â£šljm\&µlsaÆ³QSoµsqiIÏ·H	A mšÒ¨y{ÚïÔ7¤‘¥õ a>¨·ŸaŠUGIz&±DœL*	¿P	õê³*å\ò<Û¶$ajåña«ÕŞ>~«¦ô±L¡–Ø¢/âé‹º•¯N•ü„Ö‡ZšRÎD$õWºtÔ8~ûíkcÆ£• ¬õQÿêiàuz<:Ş}½÷×&g—W½’Ñ4LïlÜÜmc ­¹ÚWĞwŞ‚3¢Y¥Â;6ìSMô—êv+C¾6I£$õöù(ê^ç_å#~ÒÆ¢ª½á@Œ@f¸©ğÍn…ár]û7*Ò%ÙÀ!¬iokş}5YşLSñƒ;5øK¶ƒ»HEê…~ı¡ÚxÑéi0¾·ï0Ap,ï¾Ùı«ø~ûx¹GËó~8n[b…O,u<*ŠÉ±Ì‰'ªëùhà¸÷¸¯°µDçëõJ7¼yïürü˜•şaôñ|ra<ìÑ(n¨_°F.ãzúöã8«ïÁøƒñæò}§¢jÂ}ã²7¯§ßè¹ï¥0´M¿&ˆĞ&’Éù+E?ø
^¨1 `ĞÊÀĞ“Á(	ud`É=è‹KøGÑ*¡v±ê¹€ç‰”Ã¹½K^Ï><RÉaÃ¿×dúd/†>&d1ˆì¯/« gÇ=Lúİ»=¯Ğ†Émé¢õ/®à*™—n£Ÿ“= ±¶÷àdï¹àQŠb9¬¥JØíT[ó²]Òı`@Ó‡sç=êõAşíKe„œï08*Õ?Õ†£I±úS-	ÊÄªa¡låZ§GHâÛ]hæqë^´Å²ì»u‘÷J»›³ºhJM3öìå¯¸i+éE²2ş¿Yvn¡IcJÍ©Qz^«k!šÎ[qû|à¼|?ú¥¾\an¥/¿+ĞóK8Ü¾*~kÛ7‘¥äYVYñç «ü¦Ÿo{6XÈò³åì«}à|õºÅ=xâ‡ÜÑv£º:ÂU›İœdSç?:É>¦MÏT¬+ìxÊ©§ˆ,È.`jÂê ­³AŸ-½&´ş¥±F7ğ7èwŸlÀ_àêÆÛ¢3yÿàİÆØ4•z›ò#)bùŸÒ´çÖ4ÒÖ,#w¯ü3> ¡9H|!mGYûkg,¹Œƒ›|…c›=œcø—}–Ş]½[0ù1õ®§‹ÏİÏïâaæWf>Å¨Íúí¦ºBJØõ¦ULı(d|ºVC·ì®2ìŒÂä×ÿPµäûÄÍ6Mf
kÌÕq<hH4Æ”×y¿şûìêó›¢úNbñÓ$kÓ^ªöBYdŠÂ	Ãût„l€tJÌ
®‚¨‡÷ä˜D°ÕÙ­!Ó é#­á;®á¨Qs–Ï¦GEµ“•’	Ğ ÂQ¢/W¡¨f¢.NëtB§ãñÜ\™İz\F3È°…Q¨0Ï~°øÌ" #cqÈke3³V²m¹•g,<·ñ–^ß¶NŒÔÒ¨K¿>8}ûr÷8»X“ m›`iæZ2‡İìkÕú“j]U†w²cƒ³AÚ—ƒxŒuèº¹ë¿ş‡xy£A7¼å|±ƒÚu@Qiğù$!+’¡NñHDÒ¨$J„Æç€§cÆíˆÒã\¡ğt¨ÑşõßÅŞ¦ÂPô=tÂ¼1³Ó"D»¬Ô\îdÜ­zÛãLû_ËßàëÚÿÖ×?ÍÛÿ®7ö_û¯ö_w6 3Hın6`lÚŸHgğg21&«¢¯bïËXòæNÑ§ûtÇ¢µi/?¾û—,WxøÙóXnU¸å®l–-©?O„M•m¨qFæÉc…ò·U0Í½“JØÅKİyóÒ–Õ²B¯Ô¶ú‡­×zìy&Fh_Š‘I†MtTzøç”åìåíÏEöƒË¨ÓF`Rh@B‹ÒšĞOI?¸´TªÓ“Ì$m˜ÏÏYˆÒ:=µZi7²xwğì1=“f&ğû‰ş­-GàéSBÅÒAjs½£˜µ•ºéÇ)}§á@Ôî†hóÜE«ó´çï²…ØÀM~ÙÌêˆˆMo€,ªÕª°ÓJ^Q]ÙolQ²ˆl0¹i½RÓÓKºÓ.“æJcîÙ¨yø"‡`UrXp‚˜DiˆÍŠå©âäª÷2æÕ6Êwø.:ì¾È;N»5±)=vòŒŠ7÷^Æ³‰º™ç‡°M +èp~§ÒbO@+@ğ¤ëê ³¹¼:e³¨Í²ÂW0ÚO~ÁşÑQÓÄ,PE}®‡O$ˆŠÔÎ)y(Õª‡mªÛú|ËA³7•ä"ï-š‰{"ì2D‰l.”‘Ä…‘Oa	v\G+2ö–_»ÙÓ¢‚	Ã•x	5ƒÛÁé$ZÂy/T#á&¥*0C¼YĞ®¤À—§@T2"{sÇ(„2~Ú BïÁk^™Ê³n©D¬QãšÎéÖZ§xÓqUˆ!8­u‹ç“Ÿ¹`ÒÎä2DSaçÌ®—§ÀvÇc}mÖ“;¼@Ç¸¡èıONB|‚OQ^ÖÕğÏ¤Kıo¶;µÁGÊºv¬5Ÿ*GÔH."­{fÄÌ–$T‘Š³â@Ùfæ—'F!‘?ìÖF"~û_İ€€Æ°ÁÈ­wÌˆ¯-<´DÍ<ê L²CbvÄmxğ À{ì‹oá‹ÂÓcz•¬;=(ëS%.$z§]èÑó£¨`‘dlÑÙ`ö*„MÕuNİî>\Ï§Ë›?ïäo»8®ƒ²a¼³Ü6İ&ÕĞ©ŠìsºíñÜG¾$Tß7‰$ñ¾›AÒ€½·ê¨ ú'|_÷ş+±‘ CŞ&½qÕt©Ä¡´Ó·çzØJıÎ³³{˜Æ¦"†¥ ^§wÑê¡nû;)Ò=[¡=äüÖ·tÿN±‰ÊõÒßb@IË³Ÿe¤á×)i~øäŒ º´Ä{Å²˜(?[:—ÜÏ	İ ÒùqyYà>äj½y"§8´Št4—ÚF½==ø,Ğ‘œkEŞKC‡UeMÀºó˜zó|}…¼tÛ~ûÃ/¿¨_OÓJÁµáÒ*¶2‘\×e"VìYRŸLñX¦@¦K`9+n¬(7DyC”ŸdÃqwìÄØá)V'†Ik<B»«’Qd0"àÅ¤G:€É OÂã`@!¤!ÆèAÈ<‘»Î¹}9
l.‚Ò©ØÓE#7 şÒöµ‘¶¶@Xğµ¶™jÒ¨$¹—˜ÊiŞH`f\×Öl¸.9!SÆ- qÇ’÷4Ë´™ëİ‹$Qx‰:Šı44Ê4J®jÎÕÓ,^ŒİNW•,/u2ÓBnêd§’g×·PFÂİ"ÅrqYĞ°˜d3Û¦xeÖN˜Ò]ÎX+!³+òFd/°Xü-J³vBÖGÿ‹öBw‚o˜î>f·¦¼j—÷Ü 4»/j¦K¬	ÿÛ^Z¢#æZğ‹:-«$Ô´iKdÑ¥“hõAùÏHzƒğ!„®‚0J`š2 ÚËWx/CN9”T¾C®4Ö«Ş3
’ê”x!æ¯Š<ÅKhâ“B’áC›k)o ¢À"²b®,·b=”&AÇû#èÿ«µnÜIj_´ø/øÉÜÿÔë\<^Üÿ|­ù· $€_M†Õ~÷ëà?¬5ÖO3óÿxıñÿáëÜÿÙ@-œzÏ{>|á-ámÙó°ÿÂAÉûç5xC×ÒÎ“½‹
¹¾uHA;ŒT³'V´{–º«_%e¾è0ïÉ*tîó@¼…©eêñ°‚jû/ÔçµàEUoFó‚N'‘€”Ú7ÙLœö‘8ŸŒ	áyGŞÁå‹JåyM~E•X„{YĞ«zÏk0<ŞîG²EÀ-ıÂÅ(î‹‡ÎV=ôšÍ&î(|!¼“XDÓLƒ6½%Õ¼ı”I ñùèÅ¬2µm*Y8LC!]îs”^Ôá'üy^ƒ*¦´*-ùqä¾y‚ Ñ÷dã-«"•Û¶.J+Á’æ75¢zfõ ?®Sº¢_Qø¬@H<i—”¾ZI’ÉæÜMPÅW*úÈ7*eI}íÑĞ.Ô‚¥´Í(VÚS€¦/Løjì‹l¨¾À˜aì“,ƒÌÄï°yÁµ	«Ëû/‹Ï­ö˜Ë/'ŞAş{º¾¶ÿ¾òü›‹úkÎÿúÚz=kÿµ¾¶ÿ¾ÎüŸù¸çÑ••Æ\õä[[p{&|4«Û“KQæBjÀ_Ú£Uª>iŒ/Cß«¶¾Ûow=ÛTóL'ÇãaÊÒÚ;8<jíµ<»5ç#Ï@ÁÃìïÎ.^òMÑÙÅñôİğ³…¿1‡ğ2Ày®DÎ4\.¥ÉdAÜ Ó7ÍzaV­[Õ­:«œñv—Âª!ëy*Yu¤õœ¬{©+0v;»­WÇ{ÔXÏíIVWbv/ptãG½èì£G'p.¹²2yÖºõ‘6zc!ËPr¦MïÊ©ÎŠ¾AP;ô[ò†?;$5T¯—/!õyBÊ×”X¾—J!–trh‘iO“ãg@–¦Ût›yåà
ªŠŒ©é›É¬)Ã´øfÏ35¡ë/9«z­¾&éö"SÒ¥ãëx5l6…Ê‘ÿñ—_ŞÉ?
Õ$%ab{T×HÒÄl³­£PIO¥©6uMh»«ÃB»2…¶$k^râ4aŠƒFÈgØ
kB"q‚Á Üyß›Y¢+EÅ¸éÄ“ÁX‰Vå­rë¡îT°é\ë
ÁÔj‹3¥İZ™:[Ş›¡­zÁ½ÆFi3ñ2  îaRºÚèËúH$.{b;?”è#8—'H!¼ÚNO¾=<ö²Ğl+]zĞÛõ}ûphBh™Uo!Aÿ%ÿwzĞJGûŞŸòoıßF^ş{üdc!ÿ}ıß+ú §·OØ¾_£Kbî“MXÕ#x’5j Æ 0ŒĞY6OË	MmwŞË 
'2+Àâ*zÑ‹œ¶Ï@·bV¥8aHÖRYÑà
±Î0	ğÂÅy!vâëA/º¨)di…<ùõ»‡QiOÑ½„¥…Ü$| NxM$$®¿³ ìÉóİ›8§V½ˆÑ>İHs88Iá¨±0Y¹3ÉBIs†ç5œ•éZM6•O6ï¨ÆÌVûÏS]´ÄÖèı1t”s5õÊÇŒò‡Ò3ÎÕï…ñöÍ0¹ßİæş¿ñxc-§ÿYøÿıSîÿ™zÀ&®-? <§TœÇtev-.Â`Lşp¸¬Ï'—‚ğ"ªwEy PÄWaÿjh<y$È5 èQ­øƒİZ›æ®0A162µJ`•"¬®ÜãøÁAÀB64_rè#ÁØŠæ¥Ÿ h<óÅÚ»v'ºÈ¤Îé]XlÎ¸µšÕíŠ•ñ($Ã C¿¯j“#T³!ÆN2éÆ"èÂÖLÇµÄÌ}_ÛCO0Ş$‘§Z¿ÅĞ½# ŸÇPÇa’rÌJ‰ñLPÏS#ú^Üù ØÔ}Õ¬—MÔY`BàZ‰e¢”|…¿QŞe:œˆ¿ÀÕë¢et5¹Á`‰	mCH/ä™™ï˜Ñ'Ò€0FØr‹@(ÁÁ¥é¯ıštÜÌR^ó°ğ.kìi¤ì2b`pÙU3«ÏH]‰oÔñ>@ép ûyûî£S¨¯$«¦õ×{İİ) [ÂØ§½FI–0 ıè–A»2’“â½>é)“ş¨oÜ™¨L˜–¹Z"yúS³—äå5­Ë¬Ëã:ü×
‡c^ÏŠç´^+ğôxß¥\uÛ“KÜ}ëº@ÂƒRªkEëxÃ"GK·§p…Eã™+»µÑş/$ÚLõ7Œ\7€£<­ÀgY$¦ òoMAšó´Hc(t(5’§–ÆµX¨O8‰¤ÃIádM²¸áeĞ*‰w-ê‚ÁÄê(7“Ó<ŒT‡‰>;Şù­3zç	…bV¨#ây­!• &J*$&Õ>Î”­"9Â]=­Éù¾]>¨Í‘Ï$¼†ù‚ÕÑ¯ö÷Ä[dg—a’İÙ••Ò<ş’HŸ
ÉÇZH¶(úö$£MãlN´k®§«IÊ–û²?\´°3ô6¸õ5ƒæ&…S¶Ë¦6Æ±ŠÖÔ—|İŒQ³=dw{ùØÜ•¤¢	{‡ñş{:Ğ›¿,€Îòm?BX³KŒáLPg£¾UÎûßû–úç—ÿ×Ÿfíÿ'‹ûß¯òyøğ›Áy2Ü2ÿ7¨•ú*?ÆÅ¯ÈçÉÿo‰¯êJxŒ"SÿÃ‡÷ğ!^#Ã7d(J@çtĞÈ¾™rÍ¬ÊàÃ>ó±‡ÕÅóìŠ2ÑØŠ^Ò}›–ÏéŞMs›Ó7ò.}5µ¶;çiN}åj4Çx­U+éËì;µuå{c«Îœ%7îğ~5ß­ÌtwİöŒÉÏ}Şg.Àioş=Wàªò2v6ÅÏœÖù™Q’D2ÙÉ7Ó\¶O-(C)ó ªhÑEè,½›/*ÀAš
ç­àÆ¾¨$sš)×øB¢ãÉ(…pá]¾X- |ëzÿ¶ÜJ¸M Ì®)°Ñ1c3*aiP Î4E[Ø•İÀ4Fzga¢Hù]ÉÏ?et º(3¦CpÏön’kñì¬!´LŠz2=waÿ•Eƒ›ZÑÆùö†ÒÒAš:Ì²uà‘­’½T*[äŒI'VRşa 1¢ÎgRA%ïWôÿyš“ÿ7¯/äÿ¯£ÿ?Óê£©‡]ùß&áˆU'¢¤Îï|q‡¸$–D¥_÷»~òz¼ˆ{½øÆ#(-’¥é»Ç¸'Æ7Ã°éïùê¨}ˆğ—¤îV±B’†F&X…DÉ8ì"o¸Óó^|.íjÇ»Û;owìıŠÍñ£ôB™l	ğ"êDPÄMêno©”_åµ¶´Â\ÜÔõÈ42¬aÅGMÈ ™/ƒúÏ¬sÇ(F¢ïıQÍ.¶ÍæCÙjÔ(³‡RK¢^ó§î‡Ê³
üŸ‚=Ä#!Kª×ıLÚzİJlÕÚ´#Ö¦µØlÎ†\;ºÄ_ÿ]üú«ØSÒ¶È&	²ß@yMº$­‡A·ÛÃQĞš ‘•]î=|an¿´£Ğ$EtS=Š""¼(Š61÷Şx9±öÿ$î!F2„ù“³œî…GRËë‰)+ˆ«^İ`hÙFÛÔqU¡Oj
©±åŒüÓ’j5¼«*ji%–&¤º^b4‰i§Õ]”¡ºo0EòÀÒ§jQM³!ÅxA{Ô%ÜL´Íˆ¬RÃnQ!'¤,JÍı’[¸ğ¾Ey>5+ÒD2Õ›ƒÓš\õµTç|L—ú„bEÇ<:Q„¢;•}“ÆGµîà
 Ã‘„ÉæÔŒ¡¢fÔX-Œ™ñ‹ 2Ça(j¾s,ÁŞ“*r¯j·ë†¾šƒÄ—ÃqÃ‰p[Ö3{Vnr™Gıy+4Æya ¹ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹ÏâóŸôóÃ+»  