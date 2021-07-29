#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1048981788"
MD5="a612c2a0bc6a86f3d03cd45d8acbc7b6"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22492"
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
	echo Date of packaging: Thu Jul 29 16:15:25 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿWš] ¼}•À1Dd]‡Á›PætİD÷º r<S0wG¦B©U:P8
Ø™Mş‡IF(|‘Â'SÍ;¯Y ]ŸY„¿ù'å5uæ^:RøæÌ´ê"µê$ NF)ííSÌDP ÿœ‡(#¤Ía¶˜|Œã&½§¦•hn¿HQ-O(ïÊ¾ıB&] )²ß6Is„ö±ßÇFI¦LÊß ¶’Š¡hføÜ¶Ï·01Å DŞG8[âø¨§ùù>¼ö_ÊáÕ²ÿ—É3ÆÇ óÙ³Á¿=j|½M÷Ø5½Ğ9İZÙ’¬®–|†9ç;†ß:°_	Ú!âˆ9ÃÖwÛê¡KğxcàşD‚D¾R)‘²~a»!Ì³´m&š]£•+«¤Âp³ÌÈóÖÄ0“öÕ®™Ú­ßj&³ú©¥zì¬ŠÍùrÔ\©z®Åòåg%íÀ$\ïaY"ÏÑ¥Q<â"²ù¼ø¿Bn}#4­üMn;Ÿ3£¸¹µ;HájNERx¹Jâ€³––t0SèÈÖ÷·ªù²~ HÖúÅ¾ÔZ°mşÔá)O,q"ÂŒ(<ösNR]ƒû:¯ŠB:Èûoµ•Ï²t6š“Ç'vÆAÏc€=büê·wjÁ‰1Yq,}¨±³ËÍ½ıM.û¡GÖ¼°Ë*„˜HãhéÉÀ2¯Ìş²Ø0Åswç¨º#[~ Aå¸f¼€½vyî~Îép-ˆPNX¯ÖçyºÖÎ7lãïÔ§–ñ6}¢ŒD5‡Fb
ë\wdOoÏnt0­[©¨r6^jñ\éºJ•ZPç›üf…¡ë€xÏTô%RO2ÂÉ¡Óşdù©¼ûê^Ğ|†~”7&tYŠ5’]a2'!+vçÁ«A°Å„N.½qÓ‡‡Ø®\ö vz"jQcšÁrÕN;·’o¼ªIY¹q‚<å»væ¡c_[áœ?d(z‰lÂÈ]å€ùØ›‘z¸~Wáñ¢ÿH•gËŠNø0¯ÕÚwäêéı9_ü—¹oÖ²ßj7KS%ó¨Œ’& &áHOUÔ8füèÓ|®Š"øä>±ÊI‡çeƒU+`ô%‚¨YÑ79ée3´ZqL¸¾n˜¨zU>”Lô‹®Å˜ˆï‡Ø]&›FAö ‘YÓ3×Şª8¨Ìë yBh0óyBœ–ä]êãgÍŠïP@‰z(7l •‹>âMu¢TŞT)8vaØäªá, Ó b>55‡ş¤‰í¥´ªÁ‰›ÑW Q†Ø&ÍªS.á:C ÜúÙ ³i‰¢¨Ö Ô‹!¤Ñ· 8ÁmƒeIv™ÆfˆÕB*æ]3Çë˜“CJ¯ÿ²Î¶-øPQhk×d§0s6-‡—~úS1`O'÷vf9DnMšÁj@®Åß‹û{V5¨g³µqxÃZ¤-Îì¹€‚Ú-W¤!—gPÑÑî˜:wØİYâd×:a>ù¶ÍõKü;¿\£Kî³Ü@î¤bÖhDı‡E]m]S=Ší•Ít‚Æöz«k^é˜ŸIö%r	ŞÑëWúåöö{èq‰§|yÒ£¡ŒõÛ¡O¡œ@À,éqmÍ¯¿¿sQõ6W«h))8N¼±¼â”}0c¨d¢ÛTÀ'Á)\ÖŞÀnï‹M€öC¹ït«sdã¯ö¬3¯”üW+3ÆNü-k“,´)“şpÑpŞ.\.ªşû_­}‹õÖŠ Ä&ÄH|®jÏF¢NëÖSÓ»7j¬NŒ Ã]KÂñu
Îı¨wqgsí÷ß®6æ[ş¥±q©OøG/­_bbØ1´*ÒPpÅ5á5 åZ3„NÍ`?_ã”gÁ{¨6K,6¸æğiÉ ö×;“9&ZÙP%§á‚i0Ç¼S8!$“gæ~]FùïÛ4™æ”­æÒ†ı„JBöÎZo~1frç×™i·!l3Æ8(ı‰éOº‘lôÊm/m}ÂFÇˆµT ¸ ìzè+ïŒªË®ô'µ²ª‘dúÛfOQçè§Ì"»]³V»ƒFÂ`’áÛë®8ã!ToL;‚M3§ëÌ;ƒs)zHßé‹@=jÇ:Ój~'_÷Õ=;¸ÕHYHãÇJ:µü^“|@ì»LĞ~@p±d#ĞŸ¡èœ#ÒûRä·İDV·#€Y×—¹€? Ÿ<Â9Š,¶ÛnRÙûBŞ÷AL&ÕO+ZÚözÚˆ*˜:®Şâ#WõÙ{7>ÕÔ$ÃcwŒá4GÚèbUÿ„¥½˜ñ±•¤ùí	»Ú‘8‚“âéa„ZŠBV#½GÆÖƒ¥\gº |%îVòÊÅáù[Nr7tûRØÑèç^“~;ŠÊÜ¶
ô–rhrŸ"¢2Ô}Áì8û=ıoeyˆÆ¾Â Á6ˆ<*‰W6w
Çcná«ÆÚ>İ>Œ+5ˆKÛ§hxjèä!Õ«”÷l.uå´£Šó$ˆi­bK.ÕŞZˆ(ŒÑÂ*ò>xÒFeWÙ-dG ÷DJ´“Óæ$ãë“ ßVrf$ƒõƒÇ‘¥¦Ò¥æÃ&Ôå07¸ÔY1³t
¿¬Ã²ZcÒp71ØŒ€[Ãÿ¿ê£¥õt5?è¬	t¨€?ºp·E\ÅÍDĞtÚ©.Ò¢ò†ş aMÔÅ×ø¾şû¿FP§NÙÿ0ÉìÓüC:unvŸ2õõ‹½.«•á~¾ŒN›İˆÚåà~åŠu’ƒw²Ä·B2£Ért½[!bË<ê}§u°æeó·%’‘Ùº¶ƒ§é>îŞâÁ®h¾f '!†7õÅĞ*÷=WÌ#X†_»ó¨õ~à.=2N8Ş»’í”ÿ¬Ã£¯Ï/~¤Şe³`9½ŸãüĞ		š1®OU¢ñw=Mè÷dxÄÅÉ¨Ê™Áã’v>ıåN*tül|Ú^&õÀ6sbkVb‰Ü·´æ9§ç”À]~„ô+y4™SF0+±ÿe„Òı•(Mµ‘IIıT**İ.0Em–G[Ø]¦¡‰œÚpºÚy+ÄKÀÉEİRÓœ¬wÜ°‰ SÕ·p*MòJµVÊó#ÓëÙdæÎjGÇ<û®M"³²% VîVÛS`É¡ÔÊCĞ*2„È\ãóxXIıV/5ã'f¼b²×ª¼ :ÎäÙ!æ× 3kw‰ú,A‰²ØÉN(G‚ŞëaG„øvÉ9ç@Ä¦†úêóˆ¨ãÓÖ-#sIDW¸Ç!/s	0¤î¤ßÈâÒù,c€&ÇXûnJÜ“Ş«²:*…–s®¥ô…µ#âÅEûÃá“*ÖH’í´Z#RyÜÏJi¶¿™©uæ’pì~–b4Oê%t[¿4R‰êÇâ¯ûb¹5rª–‘|65óÎÌÆ"®5®)üŸ¨Ø
D¼'/š?{İ®,Æ%³Ä¬z³-ÿÈ ¥Ò¶•÷‰ûD	Ì`¸·ö:t.1ræÄRg ¶¹A'ïv´È€.¤¡ÂÎßvz°(±xQâ¸™µrŒÜe×Îõ*l‹è°‚Ä`kÉ7:£‰ß\FÀÔÌƒÿ6ÿèĞ¬ûGŸ.Á#ÇıPÓ¥Ôâ—"º©²éÉÎ¬‹U@$¶Ï2+‰ÖÓnû,)½şiÄÒiËœ,K‡UÜIò_å@¾Ó®ëVæ…¿½Œ®ï•SÃÀ…;‰NCÒÑ,¾ÀÇüµ¿p9
%.”ÌåºI-Oƒï¢–kÄb¨=<Ö•úW~ug´ õl,e¬`'·œò¼WÏCëËI
î¯AÇ3êy±íÂ0¤‰]DÔNj–½NY…KX¡	ÊU@á›Ëı&«4ŸÎjH‚¬P­d«yÆ•~Ë#;yY£¤Qµw§Ğd¥ŞhP<j0•ÍÙˆ§ÌMˆü£«ƒEá/ìõ““‹š;º08{º×¿¨xşğæõXâŞ „	?Ufì&—K>WœâRv@å¹™fö2;›x¶²vŒÀà÷ß4í®ÉÅ6ËxŸc`<ôHAZEYßşDŸ¯-ö+&ÀR	··=øÎwÂ|¼X½˜v0-§ŞeÇÕÓ4ëN‰®­Ş"6şîD¼nWƒ¼y¡é­äÇu6yjùC~VqNÁù7Å-á˜‹ø¹¡=àkÊ“wF¼_T¶´ÓpëØ¹Ó!=nııúÈÔF¦\ŒCâA«áï¤`Û?npÏ¤\/V¿îŒf4úåŠÄ¹ÊÁ@.KB×l…«vl™lhŒ¹
³M‰‰å‡@Z‰ˆqœ‡Â]p”hnüÉ<²ä-öK÷«}¹ôCöÔ“/æ·'é0²pÜ‘Q²;ı	Z2¨¯Ï èà@p³~½”Ö;I¯}Ö=9/ûO¶¡]4‰€ˆ~÷³b&NGNÔFG¼¡t"ûJÍ®î~—bPkœòö».Ç§ƒòJpZ‹VuÂ6â_ .‹†õ¹AºA¤–ÿßó;²Ed]yÒ¤`Ö—Ä6‡™Ë‹XŞÙ:\H,¢}eû»J	Ì?&-¦ '¤òÒËoŒûà–ÿxút C4¡§•i›§G¾^°¸~ızN8+äb7÷jæN÷‹¦»ƒøô^`5Wm`÷ZjËsÒ×ÒîyVJÓ-€«È„ÌKuÒÉè1Ÿ¤BxŸlÆfMª‰=Ùéİ’²fB:`WO
‹Ü”Í$R—T2¼Æ4 #æ¡lypKaSã=1l–jâædxÌ*gRÉo¡„ñÁÎT#º-™Úl¨U…ÌŠ¦F,!;»'CÔ9¶pò'˜AõÿÂa!9æv$“¾‘Ìù[˜Ì†“Iô_ÖB*Teñ9c·¥;D¾²•5‹Šàïwïê×Z™ô6uM¨ª?Ó×||¼Èxş‘˜Øş§İÂÛ6*ïØš½¾™hÕDûàF“®ÿyQÔŞ+??Kûp¯Ù”ªú©‚¡?8<2kÑÑ10ÅCSw6Û› ëÖ›Ò.Ë¡‘‰ƒ’ÃLÿâ®È`}”˜ }ñ¨ôPq/#ÿ 	t8çœíp.e?]d«Lšâ|Ø‰¤2	·›èÁãRÓú@ûsA¦2r‰ÆJŞË©ó¨èôşpI²¸7åù[Yh½g¹~ü´™(p² 2Bæö£ÿ5şf°E©¾P¥¿[oé›iËİA?qWÈ(w Şa6@ßÿ\û?É‘Ù¸ÃßF7Ï¡Úº-è·„†ÅÅ-d?ñ?Ÿ/LÌĞl”I	“íâus–‹ëztù+ŠìPéÂ—ÇTá©ç¥Öw³?ƒ?è4Zá«–vr¼YD¹t§`uğz¿¾—>FÚeãIf§ıå šR	 )=é'’ ‚D‚‘=u1Ü¦ŞÀ#<*óÒN*Zè–¨­œĞL«ƒº:£8È]ÃC@ÛÅ‹ Šf|hÎiSÆÅÌ”œR41ÉìEŠ§¸Ñ¤Ú"x¦KÿXšÆ¤¹’	A†
ì¨ÌA’&ç;¹ÈH»ı®LşØHIôq›½ÅDyaNJÉyibNóÊâí|ºd´èKöË)Z³ö‹ş¯tÔÕã UĞÁjœ/æöıN0¶áù6vä¾f–kbrêë›®{@ÛÅÜ³5ÁÛNV9¼ï¶( \ÿøt¦Œn÷ùtÃx •5U/ËÎ4A^{×‚N²V¡qğ ÁœÆrgğÜ¸ÿ­!ÿ¦]†èÒÊLVÏ;^(æßXÃŠÂfé¸Qrö²®z÷p¤yîãuŒ¤ü¤mU}Æ5»ï§‡ ”8÷‹³ï'DşÉQ‚i Qg:ñ¬&„ßü}y[¡Òê“½,®_½²yÑ¢R›^à2jvNjº-I2/´È
S
ÏÄ¶ÉĞ–ĞpçõÌaQ­_ßÙøOè‰ Ôà_¦(FK)FL`Ô¨…O CŞİGÒN-$›¢tÒ(÷ªßÃi:€çGfí†'ÊÛ³¸tóRº¸d½YLbœXŸ®®?ŠP7’º½qÒm„îâDh£—~ßá¹wUøê¾.ş\4èªİ{'›6og/ãZÖÒÿë]#ÇÑ£PPJ/}“X–ŠÜÍÇcˆ›ûÿÕyè¢†© g¸½¥çŠRäNäIâ‡ç´tI›îåŒ70°ŠST„fØ[şs½dGËSÒC
GãŸƒöüÚÎñ|f­Éÿ—”êPáÄñCLªàİìÆËJB‚¶“2ö4ÓB#b	s0E|g
€F`ş®-‘$Ña÷¢OÈ£„ËvŒÙ:BêŠû‡.Uy–oƒhmáû¾«àsyæı÷2g]Ié¥¤Éšƒ”3Üzz±G´«Nå•éşß­â$icõmúZ 1¿·ô=iSè¥bB¢¯TµQC¼¶B úÚ e˜ˆ"êÑø\cÀakŠyÆ‹úu,šKpƒJôb@¥!
­®şiö=˜‰uï‚‹™PoÕà¼£|?–üËÆ·â?B^Ûcä!™dd0ş¤€Ó<)Â{ònşe\Î¥ÿ×Â€Š¨:ˆ;­¯¨{aÒ˜‚K*W[Ç€ˆ,ôy[m0Şãû£±–ô¡ş»ÅzõAî%µû÷_>"Á½‡™Í²µ4âs#íÂïÌ( EÌëŒß7¦b9„û€ºZ9Âïj¨©4 vâ.x9KRö™•$ÛÌÜ™Œ¾éêjk/BÙşîˆÇ‚I*üŠÙVØ:#\˜¡
 26pJàJÔNIˆ¯ç Áñ~šE->ÎØr„rfİB3,Ì¿#õ×OÇ/_ÇªóŒá*MW/Ñ¢ã"ù¡í‹á¾
ß£|ÁÃw<Š‹oæ…9ë6şê»\ÛHè{;tøİu³¸Ò†ïhÏñÙo¼¾T†!¨TæS›Ör/Gæg“Â½ƒ 
Ó½™NVJÖ
øu/èÉŒ“º	?ù®ùˆs%Ö±¯×:l! õ†®~ıäÍîe[!½Ò4€5ic-©œ~XqCÜtHô=æü$‰¤İXÑ‘(‹d³ˆ%Y›ŸÁu¨!¥6´Éj¯rñGF.³\t?” v‹w§ìp„ŠÃ˜3­4GĞÎõ?Uº«¯àeh˜Õ™)àE(îšØ“ë´öß¶HìğJ­‘jÚwQ…'AÆ1ø¸&3ktáDœ€pØ ‹ÏCÀeÌ ş)Çn±Â^ùÚÕ±PÓ——{Ìµ€|TÅHJCrs€ıüi+wÔiu ŞÕÀ‚ÆI†8a¹8İ³º[óıÇHJÇ°‘c?ıŞô-ûËÓöâşÃäumƒan ÇÊ?£]–œyÊ†è"tDr\ìNÀ¯Ú©ñÄuë“Á,¢¸p7¾?íçÁ¾ºß¡ÜŒ“º˜%fâm;4ûGlUùœYe:<J$®€!Eı˜ûßsŸùkXaãR’^¹!§#.T'Ú8ºe-¯Ì¿ZP¼¢+§ Q 
 g*d vìj­ÑP!>ˆ_8õèK«EÑ©±eÁ„-
….Ûê‹4%0ÓUªK±`2Á–og^¥Uè·eÌÉ'Õ{âaãÇ1´nôüF²TÃĞ{r$s_ö½/®‘İjXA	Ûá`ÄçŸeî=–,~9µFËúê­rÈê%`=Šİßct	¥Ûû‡Ò„Bw.	ˆÜÔœ¬åëúø¥•ü¼7äb²¦ü6şÑäÌœè\úî×¹öĞA­—©-'1a.ĞÚZÒ¸Ä`È–A´M,b$’qgµã‰(‡ÍJÖÌˆ8g§I@ÈG•†üĞ®o…HI%Ù‘Op¦qÙä°’ãvuRwÔ	à>FörÅáX³–Î‹$àz¡ÒÄ€Ÿ‰uê ˆšÊÚXKuq¾nÕ“Ú‹ß÷^€Xş|N5ò œCÂ¦òÃİÖ9HîP'óG¹Ø¦vªÊfÂYûº(uŒ/ŒÔÃ”‡Æu¯;DiEš…Vê Ÿá6Ùé¿â#HÑ%š¶ Ù0œ`›QÍ‚#	Emñ²}´ĞïœĞ7ú¡™şÃÑ¡¡F†á­wX‘KÕb.áäD¡K¬ËH¯dÜ™`<=Ašwß–›K‡	¢ü }xà!
ş²<˜Çâ]ŸšÎéş<„9œàHçC|z€a‰4J2^jblY—n±=ïxZm¶[ëŠÛ±Îq9ØI‘.ÿÜUæ8å
Š£pHÓqÓğ
ğ†¼>¤èo/´®3Eˆªšz¯ñ”GWB•×Ÿ\XãÂ+³	à8€ù2Z”İnšÿ -³û’ì”ß\¶*ïÜ¢Ug­·YF´ä\³\¢Ó+İ :<·fB|b>Fø™qk:ş'úÔ?á5\hÔ(¦’\1£GˆŸ;±R©œKËËQ¥Ş¹¡şbÊ@ßÄßK¬€»)ƒAê‰á|FèÍçyÅ¹Ë[mP;®emõ:ÊÒÏ©MƒğõğVZ«/ôWˆ
ò»SˆËVkÓ~–35›(ı [•”É¬Îø±Û»äÆ©27ö˜ëÖ”‰uñõJˆ*6äõ™ËDT5§¿å“/>4ÑÉUšLvknŠ8?;h§¿/ÃV“¤˜í™t½È"ÍÊ!›7ÀÅ¸A*Åïş`¢ çOà»I¶ò·e«YÁóG0Õ–¦6Æ8Kİ0v¹Nó6ŸärÏo”V—Ğúğ±NêúÏK poÂ¢Ø™5p}’£ØLÅ«5/9|gJlŠäòğÔRZO@<:?/ÜW‚ÆsÖÜx§d¾Ñ‰ŠÅg¸¤!İ‹ÅÓSnÂ.…hdÈÇú©ñ—À*×óÄk±©0U=3)ßÂö ¯óÔ’&ñp|^(R{†/03`óÒ–‹¾µYW)6%uyƒÓ›ë¾çcuG¢— «Îšñt!I(6
ÙÅ€D1!Ç°UÎ#i|ú¡ƒ”¯}|¾~š ë7¬.ÚóO½Ã…£Bm“òY
%NómÍ:ªô%-haĞQ+H$Ø£’ø$×m\6w(gŸ~ iˆ™D{òÛQœ¨Ûåïó§éÓ(yä•~<XâÉÆ@4¤©şf™@”¯3ÕLŠ¡OA«À‚äs;Ù4É1wC³ñ–g›¯ô–qf©ôrlªò	°LYKäl\Š5KFèØHôÌY×!0l°µ¶Uü‚ôtR‘¨>vS±¼ ¬ëB¢M‰,Q¿7qH×¼ŠšG<	›Bú­åx’A‘«åIAb»|¯ì·ÃªG™È£ÅßƒrşÍÆ§G7¶Këxé¡³xã£y«›ÜÓÛ'0Ø§ulÒ‰yÚà‚oN¸‘î-Ì³håK* ¢(>§¹ fÍPâónlÜ5Åïc÷pàßÄ8rÇ·"Àäˆ€9{še¸lˆ‰ğ@~Ë"ªát÷.@s»ïsr‹ÖX”š ‹×I"Öh0)œ\ûí,8:Í8@˜‡§¿’§ÜÙÏeÇğ:Ò‚o^|.;h6 'I'C@`«QVrÇşrF>éìü:3K_îíeÅb¹Î S'Ì²ğîÓ5ˆ¥µİ¦Ğ•»¥ K¯ÖæNÜèbÓ\à½/«{ú¥Q‘óÑ®:§ÕÙ’Üª„k8V•ÕgÙ y	R¤"¨JÚ%ûZÚãf{½•qQVÊÇ eS|³Ä]TUòùö%ET"{şà¬“Éø Ğ­ÓÜøA£_N÷œ†ËjVq;ÿpù_í)øatÊ¿>„X§,¼3‚z=?	r!ç$ZŞ‰(Çİ’»£eìÎEQ`óÛ©*’Ê|Çh.w;œµœ»$v´TdIr*’W4¿Ú‘]…
SÈáöW=ê{ûZ±Ç8´üÅÍ¼V¼E}ˆBíX–Ò1VĞµ€–¿êïƒrM¾?Ñ#:ê3|E0$;æõS¼S¦ØÈü‹ÎÒ#ÕVáòiWâÃœïŒ¬ìœåÊÄÛ­ÏöÇ?«U€ÿÏÛ§¹rÕv@[K®Â-«U(¤(”˜ÿÂğ)F0´İè–8HìA@t
Y_'ê;³ùœOëDh¶B¤Î=q¸’Dè¿whÈ²ÒM¿¥¤±…EY6;Í.˜îOôíáÉœ;’3VŞ	Ú”Ätıª}GPºšXå8àOKíEõ6@Q™Î‡àµS„xw-Ëçb!Úáö%Kï@r€ûßaê8­€+U›'Í”éN¼Ëøpô@œ6³eÖÏ½pUâaè£B3)lL»L©ír6è§Ï½ÅË-YNî UYTÿ¦éüBËãFEÖÜq¬Êt­ÊWxOO‘úÅ5[jæ“–&şw­w\ë¨YÕP6z¹îkÎdŠCXZ>Aèf;•_œí+%ÜçOøÿŒp¹7í$RèbZ¤ƒÊ:F÷¦Œ{/6Ùü=ï0‘¹h§·v‰(IÁëHt]?8QŸúQ“çÌœlï³1ıí™½â½(%Ñ¢H9ãü  ¨¹Ù‘ û©±öd1î„fÓb‘^M<cÌÄûÕiÕñ£¹¡ÑéAñŠ;Ñgäp¸~$¦,¨po¿é>o›Œß^Ån¼Ü(%	3°”ß›È‰\TîgÚÁT±õ|¤­çA‡fìí!øô©#,ü"•7î|Ò€v¸}F0ŒÒ²:6	£ÏZåˆÊÚû¿ªdMwPğ.X,KÈ©9ÏEI7ùvx3ùVlBTsIGŞ¢9iZB÷Óæ¹¶,A`W«°[‚78	"ŸN:ò¶ùDÚŠdµ(ÂGX­÷ôYPøä9ƒO1R”ï–u‘×q× å[É‘!¿eAò÷.¿×¯3‰%ë}Xt^’·˜ş—QÕd\Ÿ}l&ã°˜×ËµªvN=PŠ[Öí¶ Şµ(rè´´çùÑ:Ã‘=l¤¹M_’Z`5ÓÃ]ƒÍHlŠyĞŞúVòı§‹½Önh¿³òñªìq‹O GïÿäîœÃ	Ì¹˜_ğËPN²ßºÑİÁQ´k«#uM‹ó-/|[rq+œÖ}F¯œ€$^½;r5ó§;r+¢Û˜ß×¦}á“ùûK84T&_çX0¼N°jféRo[<™#M§»š¨C˜Ÿû²ö:Ş¶è¿»ouŠ6è2ÒÉª÷ø…›/š[*şˆŒ3¯€Ç^>1±Åo]ïâø™Q'µá·s?9*|Bù 	ÑRØtí²}eQ¥>ßé¨¢wLBß³Ğ++—Ôã&Ö3‡ NZÊîH–n	šQß#"‹…ãÿIßweùøûNÏ‡^Qƒ´Aó^Di&WwT¦˜éª€úx¢ù%ğ!&.UçÀTèæJà ZlĞéw!É¬vaù£²P¼|•ŒAyvùFİó½¤i\Â¦–WïÚ)Ñoßgtà0ìT¹@REç/XB›®J´t^ ëİæ®ZöïQï['üĞŠĞX!¥'¤šE*µC”i4¤d= ’ö¦áàÂ%ÚÿVjÆèÓ»ã‚ÙWşãwyÏÃÜq—†A~p!Ê©Ìƒ÷j
ı;ãô¤nõ¼ÄµhK Üµ&ı«²@UKdŒÎ@ªÊ#ˆ;š^ÚåÕUŸ¥ŸÇÚÑ‚(IĞÔùÜh.;´[G Oÿ÷Ìä‰4WtÉBç¢»ÏÿwV÷`”ıùv"sRå	* ôi3/úœHíb©û)Ù1‡r6 „=±©á½ÊD=`ŞGMGà4M<-#œ‰)r ¢­æËÂmÿâ]İŞC	ÅGãÆş`M®­•yÈ¢J±Ÿ×ù÷ğuåjş4&„(pa^fªQ´è†>éµöMHe±×¸}”w™Í…“Ëî{ùClÏdˆ'"…F?å4Ì ïlGK­zöÎî{¬ãWÚãjZHûM§1ï*_–8&—£‚»^¤ŸØÆ<šsÑ÷6sùbn(©€gv#ãôÎ“­-^³·Ë¯Å7ÉÒñSş†aú|ß{ªŒœ ¶ÌåvFN¢ˆtˆ:Ëõp¥%å»v¸L@ÏõşĞ¾‘
aÄµû	ÙJ˜½ËÃVx£Ç5viläxo¬ì,¤y•i¨%Y±¾%ÆíÌîUˆF›Ce´Œg§ò¿¦mkƒÑ.Â’W‰C¤ˆæt@êøÁkŒù¾’|ç{®Fê(”ŠæN‚Ó·‚Ë÷Ñz*ûƒİn×ªßxgKx\çsŸÍ©)>H`ÚèFY¢aş2è!àBœŞƒ|fôÄÊFÜ=hNÈè’7x÷°÷Ş‰¨:XpÄ×(Ï<WİØ]„Ô`§‰´H ©‚¬?qÒŸœ\eSÉÔ¹ˆõpÔ~÷éèñìF½›sHÚ||øıü ÍŞG*7TÑ1.¸v÷€hp5NÈß#ÜÚ“^œ7~[‘N¶I{G€º‰*š¦˜k<ÂğCö–×Šà÷UĞ0z,Ş’@‰¹Lvî¾ñZãyÿ\(=ª`’•ØÀmS­P¤™7u MÏiŸæ©^åq‘árÖ†é^Şƒ™ê½û:d­´ô&‡
ˆQXİá¾Ç?ˆ–Õv˜| …³£WÛ5©¥7äß_Ñ‰¸\xîyš­Î>øJSe;n™³h'[…?‹æõ ·±„ñ“n¸PóKa~L#ˆè›á†šVØ÷jíâ•Ğ;Íü‹·MgZn4øt]*+|x›o½ä|(½I¿]¤Ë¸/•:)s„7»$sÔaÛtçë_’-18Iõ~ úˆHŠ¤ÃÓìeqp(Š¸àÉ‰l§ĞDò¿úƒÖÈE¥]ç)U›¡ŞË‡)QQ¹tä	Õ%²¡Bœ>ü`5Êæ|p©l¤¢€6Î¬jKpàâånÿÍ±6áMØëŞ1¤¸]ë±!ôC¹jSÔC§"ù¹,¼y6{Pğˆ]ÙıR”ê%PxÔ´_T‚|>ä<]«,V ’k‚ø¼‹‡6®ë°r~[q5Ÿ[…a]$ĞÔ#¬'Ï0 ó:ÜÂ–jhB®Ú}Çx jrBtGcï¹
†	JñŞ˜ş>VDLŸc°Ø¯%@¯œzñ:f‹RÙÔ×Ñ(½yñHH[ÁrAçõ°\†–¿QP®½?ÆKé?_ns³T›;“2ùíïƒÒ¦¿Ô/l^ óçèTÇÉu1Âb²Úö¬æNöôÂ^ŞÂ¦jIívÀC ÈPÆĞâŠÃ*9È…¯Ö”üb‹ÕÏB%ì¯Xí 4Rä%«YML Şbæ„Os+Î—\i	1¨üõ–tô›6LˆßB—
5tGªëTBA_U=#´<ŞyyÀ&Ÿ\š$ÏHFy­Ìö~ĞC”²‡¼SQbÀ;»‹
áÏqß~¦ÉE°OÍD3L²ÎZ/1oí¿FMF6S
ıcÕH°^äî¯é¸NC’5º.şÁ„"äÚxTwxÚùù5ÆÂŒË0#¡']f¤ë¡ÌÌ[Xış-GK§q*¥Ø°É†ÑÊN»b®˜½i.,K ;&oİlîµ[@7£’*¡>:¡Á'O–/qÊ)i@<Fµ^´[tânÀY¯—=;‚	[p-×­Ò¥¤NxİáçÄ3ûÛˆt®¦'mG×aÒØ ‘îÏm¶ÊvãŒ˜ıÁm6¨€¶ŠlÔ'ãõ:d•«îçy¿í=/mIø»XYßß˜‡Xœ~Øy\
Š²^ğ-¸ÏÁ§Dù:{ÊRçr0\6Q/.ı
Ò48Ä$w$ÖÔ6™PŸ‚¨Ñ*uUÂ±ã¢7Vº*máBîà‡‡ÅÑ
ÃÛ(Yßp´k\-Í>cwçD¶¤ë 0Èà#İìëÂ=«	,™¥hŞ¢Ãä¤Óóå4Â#xİ“{&"3ÚT¢u¶`o	Î ~x§«â¥3*£ƒİa“E§;l*Poûcäní›LÏÙßV»HC´ğ¦ÕNğÍšøı¾™ÕÇ+üzrê~tÅÇPTu?›×º¹×û}×Ãò1±êëRÉp~*ìpLˆJæx½¶šƒµ~O{I)‰2òş×ç˜ƒ¸c¤´´‘7	eXÂ<X;á¹Û^FÊ¬àlœ-ÀásÔÀÉ‡.³‡³ø¦$•¤ÑIåëù£Z\{˜uTMgÄWôHdÃ÷æÖ!¾ûã‘ŒÍŸ†Cz2õÀr9ğ¥¦BpÔÔ˜îXŸÒ¥»x†§˜ /üÓ–iõşYÂ9é·â›8N>R²G…v’9Ì´d³îÉzú¶q­b32?Wßë‚ÿ·ÓP»·O‡_ÍÏ£Ñ«mOœ/‰ECÆùT'GZù‰ºä–ÀñgÔ ‰¶ú/¸İ¹•ÑWŞDR¥i†SmNM]£²|.¨ïúøUØ˜œÈ£sEw Ño4ÅFm·*éwĞF§Zkæ!|ÃeqŞ"s°õ`¾Ì~îNy!V‚=å+™êëf¬ÆZÈè²‰Ä7©¢¾Wm˜ÏøH!c‚j
	ó%ùÂşUE'ÃNFÕ+ıa«
«utı^âê,Éiûõœ•Ÿ?õŒ™Ïä#ñ= Î!ÃÂ¢å8|CYÂ¡’â×Òò/Í1<´2Øm‡+‹Šmò=ÔïéŠw|lvA¸˜ëhÜ›I4·4lé¶¯
®or~(N´	— ùªã9¾|€8ÄuİgÙV-l—¬dbWybA¼Ûmp2f

wPã$RúáÚpî¶ş6”á•ƒ,¡…>iËú_“íöÖf)e®é±=EGã}‘A,cú©£¶ã3á_•}S-;5eAU«b#Ö';ÚxQFÚaéÅ~…âÑ;Du^n¾›aQ,Ô”¢ o!<0Û)@[q uK™†”Ï«€I­(jWPIèñÖ)ÿ;;t¼ÉÌ@`ğthœô3#up©Î_c½=&Å±rçD~[Hg@ vÃCÉ »\´û Ñ!içG’o,xÃFì«ø*û}îˆnIµ*ZDÇOÕ1®È	<¤ñí£æF?.³-rAŒLÎeæX÷İ.á ,¸_ä"Š•gìF	ÄŸB%˜„ĞØ§ np±Êf]wÈyùZ!:Ê˜O¥pmÛVjÚZ…še”Ã­¹/jQ7ê±´q²Ğõˆrqğ½šò‘¦¨ªc]GEn¡`÷’I¹ñQj±B7–ŠcUŒmºµJSãdÉAé€üG—{¨ù™xÔÇ&‹1ìÂçİÚÌÄîë²[ıétCµƒ‰ßÕÄ¯h{Cr®°ÿlJ@¢kÏ
ø—a2*p(+ÆáÃ{[ƒ´ğ1â$‚‰¬ñKì¬Í·È!ª+˜ğHs„Á?Q5j™ÅVŸÛèÑæ+2½ôuT3 o·q—üë6Ù}“€©=xºÖŸËoñ§GFÖ®S{d3¬d)‡îŞÁE)s2©ö.=¦Q½³úı } Ëk¶båSiÆ@âšÌüÚÈ“6÷!Æ¨C!34;ér4Çùb
:“¨ê6µwG34ÆG—µ¹rD)·–íÓf3§ÄQµÿ\)¨´İ$ójßÍÈÒO ~İƒğœjxö¢dXG/3«ê§úö\€1•­ú½p×Ş-R!µÕÚ˜4WŒ5 Ìw—¸ëx»NTù’úQ#*D¨šù¬IÂ„qmyp!X°CìaœÈ³ ğÇ[F°È# ¬oìQÂ¢¡àô­ëò€)ñ¸õ¹´î?L
ÑÚ)WDñTãò²‡,ßâº8÷ÔV<A€v“ĞßŠ»ù¦Â©H:WU‘7¡âaeñÚ­ƒÏ-âfù±Wãì©àê8’rMP8–Jp¥½ßû&X9„d?Õhƒ|ÚÁŒ÷Ø#Ê¨ed¶_ñ˜?oÔ×Û³“ÅéàÊz>È,K2  «_´ôû Uƒ‹«TÜv…šc6/˜ƒBR¸¶_}pä¦Ä¤¦ô›-/ÃELlü¡Öğ’ù¯€±>ş4’xío!õ~C;y"ônvæXFô³Jkî'Kğ—«ÉõT°²Gûh~;<šEZÇDò%›ŸˆTÇ…Œ¼'©¯Ê£\€1q<—%[æS’ºíÎ•NcÕúwN6+‚Pwˆˆtl$…y±V=à‘åÜêöÓdÃ3ÉÍ“£UgÓ=½ÑãĞ|&³§}j×ß
ÀY8#€OğùHËĞ¶Ôe}áIãŸ5^'AÒl¢Ş™ú<ÚËÍvâˆ¾A^e"SÀ);nJbá›=[0T¹»ï³WD?¤¶¥C·úÏİ]ÚRßığ¥Ú]pm²ÁšæEhn[±¯ “‡ }…Ãæµ‘ì‚I,øsúb×8ÕøèQ|‡9w¥BSæ;.B^`Î:Æ	±CrwÇ‚“¢Á”çI“ '‘¶„^Uü3E \¥nFF(~†ÄÚ§K%T+ `rÿŠ½ËúÅKÃ­ü4ä	TQu³eö¼-Ëâ2’4“l©¥>>y#Ô]¤}[Tu¾:ñ9lWÅû•OH3ëD@í_b~§,˜´>Ø…Ênb‰’:(ë3È¤l»,ÚØSÏRv(÷Å3ˆ€—igH½ïI©ıô—´Mt9´ïÊ%_ªlí\¢?~ IQº‚Ñ<$Ã;6¯šF´]ì¨â©†:Ü„ŞWÄš—¦æÜğàŞÆÀšÀb[1Äğ !ŞDŞ(‹‰”Cˆõ"ĞLjÖQß™û¯| Jò>Š.zàxÃ­CÿCÎûç3hòcH¸âàò<:‡s ùğ_!oËS%ü[ô7à0ëgèqÒ	g¿ÇN¨fÜ½kßŠÚ^ØC°ƒanø¼VÚ}ÌãñiÆÛA²Ì(‡¯VWöû¢˜-bb:h™º—üÓôì«4HëøÚô‘Dúr£»º¢‘Ï]÷XŠ8$õÙ»±$¿Â›¾Õ?¢'B»ÁÁp°ïèQk	=©-¢(P'OXZÑ#0ÏUü’«q6Ìëƒ)&ÛÉ>\°Â— î‘PÀ|Éù ğ˜H…À%úÏÍ¨ôÈ¾h;Ì­ÈuZg!G’‡”ÃÎªbG²bÿ,HgÒ‘dÈÒõE}WeW§ôÃ¶—í„a"‰‚úÿ’áUcŒ–İwµDÃ×U¶ñ~ºnÑ½‘—wù»ˆyo)ü‚ØGÌ'£j§ádæÓyéQßs‡æv=Ã<]şÅUÇ
@µĞ„ÓÄ’¹k:â@7!—Y?-’
ì9©W…9Q€®&x»œC½9*MÂLw´¾?YGâŞ¯äáÀiİ„¯¢ùI|Õ5>>9lS¥_<…Ü$„.‡BrÂ&YÑ Ö–Uèš•×U\‡ÅC¡·yô4 v‡›MÂ¶³0f	G»e8›ÊP½alZ’ùïµc	ĞĞjœ~z=ØÜthâ£»:f¡hK½pè“,ç5wPğÑ'‹îgÇ2IÎ,újp•Æ¶Aå;x,}Tğ(`nÒa]`F7Á†}7¶¾-gS8ÓÌ¾Xv%b0”ğè$ÛMSC7‹`x/ ê¼ÇÁ´pªRü¨şR±ïwj¨ÈÄòPªò(jÒ‘ËHÀ	W9ñM€Ê‹˜ó[¥IÜGæc ]	2ºØqs—z¹?œbÖšbqéì[d}—çÕ™á,F¿üvNMXGÃ­¯B4¾ò>'m½‚-ï‰¯§ôÆs.­üPRğKğİ<.ÀÔ¦•8”àùpé[è‡Ç?Mëî7oÃmEÍ¥/¡¤©†/<8‘ÚøjÌ`ôPëa4K½ ¸.*¡Å‚†U¸]jÑ:ípÎÿ¥^ƒœ×_Ü¾+ ïa§³î_ß!§@¸t‚Bx>™³õHLY#Ô˜Ó9w}6›+ì: /Ó}'H·Í|(`7ëiÚùGGBGºSvx·Z'›Ö~_x O‰u3PéoÍ¤Ô¶1^!¡!x—‚š½»Õ‰3®“.õ±…õ<v¢»#˜L0]*ìG,h³/p„ßúı¥»@×3Q)?ş®Òræª Ë×ÂOè¦/0éuÏ},UÕ­
Ş«¬ĞŸ¾Ú±«#pZû{ÿÏ®Hœ¿ ›gHÀ2áÀ-ËDà¶Ë­-âz˜îqMôİš};M»7SiÀÓÀÍ·ÛÃ\_aÃ„§õ¯6 |Ò…ø~ç¥ù·C²ÿ5_P–<D—Mo'Ğ¸ãOZ\]ıXeÒŞO/©.ñ™ÿ<0Eã2$Dæq]TÃUq^Ëõ¿öÄ03ÖßëúôLt&»¼	¸¶Ï…]4D§.D $^!Ïy0€cˆ4à’Š+~odŸ6;ëÚÖa•Ÿ7›:ş¢a.B³ìRGˆ÷•Òê»Ôğ}-[¬úÆò"GCÌ¢[‰§Î}½&áÊıôÊw[¡i‘é@²Øj+«yÇëß¬‚”ÚÎLÅk{p<1é›‚æP¡ÓÛÄ}å!„T44fº™Ïbo¡fùX!2‰Fñ¿¹=Šb áFvÖìXa-€sÂS±}‹"ëĞû A¥d•È8ª#„8©3“Ç"lÍ#]gömÖY¨Ni‡r+e9µø(ı2qMİ”õÌÿKGg&kÚc8CóCËYŒÕâ^lù+àr£½ö „\!:[˜œ¤®!»yŠ‡®»o"Rí4ôŸÅn2@“Í/Ö”ş0|}w$ô—œõÃ}l[yLÆÒDhUášmÿúé…1Ş]Êı¤À\j%„yh@À©§VöB’ül)óÚll_ånëD[ÂPäÇ=Å’6§­¿aï?'Y|Œ©Pègª$vi »}VxT ¨×P[ıP+¨Ã{ñú†U˜QìW•ózÅqˆüÍŸzØS÷SÜ—ÿMdŒNe‰Ì4àZ©q %ª>ÍÅvXîÙZ_›/Txz9¹&¦Ãvõá_<Q#í1œ‘%Lç‘w…ÍÈ$LÍœş7è\3|føıŸÃŒëš®~5ÆŠJAÓ+ñô½Û'›cóÿ®Ô›é·ñŞã´’ë"@kÑ_½ŠiUw‚š„íMV×›úŒ—•ÂŒ“wF‡;P|ì^¼H£¡®Dç$À›}q’Á}e×9wÀÖ`¹¿æJİ¢Ó&˜I=õ•V%çt>°4õ«Èı?CêñÅ¸]7OåC²£=¹ñ¡i§u-è¢hİî:kG<sƒ§3âCÍñ¿bÑñWË§^’Èà(²Ø­.nÕ-‹Füªe3¡Ê›Q‰l“ÛÖwÿÄ2áˆğZıØã}Š]*\;óÆïp,ÎzÆDEv·ªtÜINTÀÂFñ·IW¬F69ToÅçºmÂˆøà•³òıà•å„éá´#™…Jè"¹cã»Ån6%+\2c w$£ìâìa›èEoéDGïR;¾¢Ë2RÀEö‚KNĞüµ¾ŸÁŒ¦û¹t%m¥—ìP°Xf²œË“²¯4ŞhmVSdï1$Ã*HÖ°Rß†]ó>dLO²©È…$”å’”Q!Ra|ßMc'ŞfwK™5øV}&qCÂ|{¥öN«¤}$‚H1\³Š³xLÂŒÆ«õ{ğ1ëK#‰ñÚiĞu¦ÒYÿq®¬Tv¶ú’­ï(‹¨N+q%b< çOñ$?¹ÉUÆ™|4„g†1 ˜Ú%á‚–üĞ/)’ß1Õ“ƒe?Ô¨áu©E™aÎG×#í++®MZª4òLIÈKªøX/­s(˜İLsbm²KÈåRÔ}¸vÿ)à¬¬½án¢E»^ÁÃ‰ÿV®÷şµÂ‘C}×¬0F²´ş²#LÄ3(]½L<ê5„[¯èÉişGÿOõxï•)”Ô¡‹U•Ú=ZMËœ¸|Ä{×ç]–Ù˜Änzë~¶‡§m„ö}}€1EÉÛÉ¦°Ï¸‡’Ê,±Œà`ÿß7áßˆòC,şÒDˆ}ßÇ0°k¦à‡l7-ê!é»ÍŞ8dŞí}L^¬s¤0Tİ]‘¹ê¢[ö$¸EïK=BBµ†ÿ‚îŠÌo–PãÍ”–©¦•ùÿoçúºäÿRÏ-Ç-’ÕTò­2Øì¹®¨µw³Q€ü%–MCiè4¹aH¥·2ô¶³óø æ£[ûÜ#¶ƒ)·ù£İd\ €~lÎ› ŞÏ-6Ë×ã™¨¦2ÆÁC¬¼&¾4^”9íÙÿøö/q`	æ(í´©º©Ku°Dh•f>‡·?bp´ûåEüZ‹¯a¾É‰XÕM€ƒ¹«'à¢ÓŸoDçÂˆAeŠaÕ8p¶À[êC ­W“©<`TÉ*5ƒñ©G¥0„U3ò®Å([òóÎµ8ÖvrG/:ş¶xB™… ÚXhñp‘º{ŞO\y.ãKæökà0wşÉêôØP~íòxµrÉ–jyŸI'æFVR]FÍvˆ5µQê½¢[ºÑ¶8&ºlÈV	+kŒ°‚¦[-´L´[/#h£*J¹›±Dk©~.Vi+å÷²ü'ŞĞÜ&Wß_ñÜj¨7°ûbN^Äı#±Šåã'¡Í»ëÊîÉ`).rÖŞãi·n÷ÄG¹ZTÿÄ×Td{8	ÌçØÒf3.êÛZD_)•¯.4zÑGĞ«zF(=°krqF­ıÄ²ìcŞcY¶é0æWÙ‡gxy8é´Ër“§ôZ¹ÖTÄ?eÄê8¦¿Ößù>Ç0ø£õU¢Áæ³šVÙ{wß›şÜL>jc7Ô¨côÙlÎŠò­ˆè^ ê2‡[9ÕVÙñA×ß9Á­|ƒ¹ù¥²¦Õ|Œ½ËX±ìp‚À,ô‡8¬ààXÎG÷a½à/FJF®>à7Q»B‘'3|s2xØM'„=evÈÀ¶/Æı…/ÆI¹‡ÿ¾ÖÃzÍû(ƒä]ãM_²—+I¼-ªsÂÍ¦MUø#‡Şnwğ\4lLÀ?VY÷]<8}°óæµ<[¾ûÈŞoïnvüÚ_hE×Ği²<(?ÃB jÖ-¯7ö‘Ô§â³- ï-Š€€}+Ñoæ2ç­§RtR¯÷m;T;Z+˜pììb¤Ãµ¾ƒûyèş´ûÌŒ?äô_#:5ÂVR³ô"í}*Xbåï÷>Ï	~h¥Ó¹ˆzˆ8¬ş#$¾HÂ9Bˆq7óõ81 ÖÁÎµ¦Jws¼“.É$0™\J"ÅÜ'bŸpD¸õŠ,Šd´idh]¬şú_;Œˆ·A4e‹"m¸Éú\Ÿ.3v„™R´ÒP[W>}d2”‚9AÑ†“¹|®cSNòÖù˜ñs·Ã;Q—äİ­ö±)ÎéæNJfåöV»¹Ğ]Õ1Øfj_[T>¥¹jµ(Z@M&A§sC¨ ãÁ‡vŠc_Z–T3Ú\Ù÷q›gçM­ÍĞapfå	~µnµÏduÆ^H^‹bG—¬eíl^&ƒ¼ÙM/Fà6RÕ’`U¼3êWdë¶âH< ÷Îg®3İt– M½(
9äIâª,ÌŒ›ÀÿZ‰‘¡î±µÚêzí,i¿´"°øóØzç3ôÙØß)]å´òıˆüAæ™Ñfõñ{L¥3Ã÷q‡Ó‹©ÈñDB<	Jœ½)‰ûk1 c™<">Ç’õë)uÙ³0ï^­Á Bƒw–İ'“÷Cµ-ûlgşËêÌü·ã†q¬³·¢j³BöÜG~×Ş¯v Ø“’ë1»aëğYŠÆ¹ìŞÁúK>¸—X”‹—¹£ë’¨zDè–wYS4ı
¸â_Y—ˆR"”’íì¦µ*eÒ¥¿Ğ×Kn~Ç[,ãš¼º‰Şî­i>|…úØ×ôĞJİcŞdxï¨*wå^ğ§}sJ¾Œ„8şNÖ‰è/Ë†Áø?à-£æ–6bìâ×®Ì¿á®†4R5U/7ÁVù£3èXè6»·Ç»\¡Òñ'iû§9\ÿ±GÃ0³£„ç×
-§¸Ÿ›øCw‘ ã‹š‚hTÁ²¬q4ÑKPã!Å_¸dèšg–{T-¬¸Š©>gMÃ!N3µ¦Våø¥îÜyÀ+ÇÒa á¾¤šÖ‡»}İ"i^©ôßUÖÆ2>µ1Õ<à\¸ß5£’Jwİ'¸½ë@ıÜŒxÃk=ıS§úP`àvÔÄÿ§ë{—å©¬4XÏ%ª»Í÷Ÿÿ#Û”‹É0K0š»qÁí.f)Çg/Ã”=«mv	2ö}2ßMZ³uL’=ãuUY^µ|ã¶{ßAğFÓ·Ù`- !ÌªçÚîyÛëñ~ßÒ§j¯[æ>Cˆ^SÆv­R?æzñq[;A‹8ÀRÏ¤o ¢‹ãDÒkù¬hwè´z®uEß[4wÑ:StœÄ HcRXğü—.ê‘ÿ€£è' lÉ r»‘şĞĞh$)=cédÒNT‡sçkD›§Á›Ì¹¯ä‡š\óşuAbA+VıI.´ß¢«©„¾w‰J¶1Ó˜®İÕ³†ÖMù¾/B6(n{€)»Lu!`J§¯¹Ççai^YÉIÛ¾	f.ŒS©& e;_»«×F”«¸Ï\ÜßIàÊBmá9wtÜ2Å²cw£d˜ ò,N4af,5K»“PÉûó@¥~Œ­£}İlŒ\(QÎù+õÆ‹—‰n2HËGØÉÉ9­Mø;‰c§‘ît/“W])ş@˜%«4Måhxª½Šë¨Ğ³Ç-G't£,a*¾ªUM4p,>P@:af>;|&û*PDÑ©ÜA)Š)u£Á¢Cè.ómï„öîÅƒh5pÜKeX˜İãx¿ŞÇÁœÑPå0%)Öÿmïİ'«eî7$µC¹BF€ˆëû7²Ü>;Vşol‚Ü¦£+‰uy\H©Øø—q“1Üí7Hõ5@ç
=d²¿Ülr¿®I»8Qş
í§RêxXËA-«î\6”Û>i ôE?Àèb×Ë_X=Û·u]Üë›-\ª"˜—ÙPJøHnòş€¬s›ô$mÅbBÚşõgRêúç’Ëì™Nœ&¶ Úq›ç[„q­wfz5¹OGtc;S”½ 8E/’øi0>õ¥à:¥ï»øëÎ{l ÓÙ¼æøQkiVA@H€àığù…¼É±œPÚú\{2BiªZìÀ•âD3Š^KÙ;»ïDjÖÓğWıGˆä‘˜ÌC‡I‡oÛC
>F‹ç6“-Û…µŞNH…‘­8IMZ¢AŸÙOÚ4æ¢¯¯y§c)•Xj®úÕ.©<0‰ÄõT(™5¤3¡»´€KB:»vBıĞ+‚'lÒ	ö´k‚fi[%ƒî`ÑM8é£\óL÷ı‘’Íú§/ìîkh÷Ë¥I\P/ıvÒÂ0zOêècTa”GëBÇe¶»: ı€OÜ`µ³Â3»bçüD# e˜~¢ã7Şô)e³eDmnN98<$4xÁ'~†ñno•–£B˜ò´¾o8i3¶Os¨X‡Kûy¦6Ÿvÿ™‡L¡"emÛKÍÚÜ§ğX\…ÜíæšÙ¬Oczl(ßåjš}€)7±éuÛA‚ËÂk¤•¬î¤êOAjMgıcŠ•Å–õ|ºqNÿ~»´o—İ§àt=á„Ôº°ÀI
ÙşÙ¬ø,w¨—3½ê¦¡bÌÒùp&‘„xP×ŞÛG(UuAÀ×(%É„ì‰võÙJà9n¸Öoš/ê®B «;‰Ššülš˜à{6ß®¬]¿®ª0‹KlnIâÄoÜ9‘]O£ÒNLÆ;ÆÇëiI7îp¥Ê£tM$óÖÂ¢±±²oİ„½—Ê¥éÃ‰9 QÂî7LÉ†á2ûŸ•ªA˜Â¹Ù$ˆ–D%Ê‘ÇcÃöCñ#‚¿ñÁÿ.‰Ú•;“ÚÔax–@Åì]óæ¥kì	i»:E»z_ƒÅ1Ï5ÇrrrZ'WZø ×È«Ztf\‚ƒ©ÕŸZâ0aÊ²$°=c¶Œ ÖH
:ŠÆ@eã¡nûX"ç›HıœŠ™ËEÕ^7¬eÖƒ¦;õµ@'Òø¡+ÎÜò’üj:ô»¡™‘1…Ûğ·Şk•dSUš8ÈÂ±ú~¤kkYA²A`en"H¶÷óUóàê˜j0Ï~İC€b×òšæÆ‘ºX˜½&Î¢á?Pûh$ˆ$k>FE¦ı%ÀbêHèì©úÉ…kSóàŞŒ	bÒ™Á$öß eöÒ‰ó‚FıX~u…›™–å_ã\>Ù@æ´ÿT…Rîÿ7?ç“®È-×#I„b?!‚&‹ŠCò”ğv}îf®JÓÏ 0D·t¸üˆb	O‡{+Àñe†X~”_Ù©+ş)\	áŠàÑÒ]î\ïÒ˜W‹¨HËPë6Be¥/dÃKè>sçM»#áryUx‚Îş‘ÿP–*TÌ%F…¸şïG —†î#-ØÂ”•gW?i|ë
6oÂq÷µöñ(Dììƒş^„İ‘!¡Ü%9mg};¼`it"Ê¢·^.“Â"«%âÌÃ&©¶û?ìnÀÏD&PF5íA8ÄïFÚ¦ Gİ)öN*Â&×L®«Qçì4Š±÷ò›â>|2–pf•ÃÈm)& =ú$è…hÊ–wzïqi–’%ğ·Å«7KÄNækÙ°¹¡e¦j	ÑW¨ˆuKÇ+)óõUÜeRhôtöÔhìó\R¿vŒOÿ!?ØÇoèÿ8•§¦şE¡!-’ÍróûR'MÏO\’³V½¡sM€ªX£3¾-âƒWZÅÚJ€AÚ*ÑT)™FÈ©lŒÊã¨$ûZŸÜR~ğĞÆ“«‹–R#x{Ku¼¶•Wğiudê—ÎÙãõí•‹1ÈoO,Íì&íìŠ"¯UAY[Fòğ&_/Ò«5Ä§C_7†ôVEù#Ø@|™W…s¿¢D<Íá£åşœÖ*¶"ãD\ogE)xp´VÉÚD¶ÉèkãÏ·kİÉm¹8	bù÷›CÕgÅ¨WÙT2ˆÁ»êeøÈy‘kö9DÍå(~"˜§£¦\öTÑªØ54ñ™P—ìÚjbö—bj«ãÃşÕ"ï*ÊI•Š%ÕwÜä—¬ÛviqÖµ"<¶7¸5’ˆù{1mÒ3± .„…¦ Œ	´±œzaë±í´A°hˆq¼¾œÔHšPã½‚d)«ŒŞù”«|ŞÔÄÚó<P¤hò§P’Õ‚·¦$kS]MfdBìè6e±|0¯·™”§ÕÑhÊCÔ~ØÒÔÆ¢É-ñ$ ³¢Şiïo\òÜŸˆà@Ü ÑOrâˆ… Fˆ¤ğÚJ‚Ï>Ür„P“"À3‘7†Š±èøé¨%#ıeÆˆô<Èïk_ÄËpaµÏõ7¾-2Ÿµd½pê9}x•ŞÊÕ]bX(É¯`^n^š*çª…ÌŸ~¯§²Ûõ™Á61şİšäÒjG7­wX¢©Ê]©~·ÌrÿíåÓãY&åy7Zs€ÊV–˜N-7óŸSï¾›ûXÏH'·b©¾!Şşc˜Uge:„ÂÇò2hÜe÷²(K€¦ûèÎ|nı:at~Ïß:°2iİÀŠc¹jª!X}.XÃXLÛ&äå—Ï,itz–‰Ì­1”#ˆfßjC±A]mÂµ°µnÕWi,mã–­	l “cóşå5|VĞ–@
\ót	¶#?²1Æ»}Z‘Œorç33ğ-Í-[ŒOüüqÊé	9’Ù½xU«UøkÉÿI%ç7À¢Ñ/ÍK	£‡¸
&¶à)uåÖ«c*o¨/,©Qû' 7w3ÈTY12FÎiÏeH*kZ&¼ë¬£Íö“Î?N¨é¡Í‹óPaÃÙ	1šø Ùd™â™úËWwõlb´–²r1ä`mL½9+ÍV'DCwm¯L„ZXå¹$®¯ßs&-ïd> Õö›œÃ—0&íut¥r›ª¡9#£Q±7@nŠ%áE¾,)Æ¢Ê<Ïb!<È?*ŸŒ†WoÀù?´±¸_ÿ}yŒ½†ïCp`*æ'«ÂÅb¬¨»ËtÅ–„›˜z‡ÄŠq>JøAËOª®1!8¶áÚÈAr†öƒåè´õöWg>XfäMW”İmÇUŠï-üäÍ«¿âs_nMJâ¯dF÷²Õz;¼ÊqğXuó6â~g×\W²h,9ÈÃ@Õû$p2$#¯Mu×şÓÍ|çÜÄ5—ø”o3RbÌ'nîÒWS(jş,˜bëş¦ßîÙç²iA_«øŒÙÂf77è£°å–¦-øGëO£Ü¹uuùTS'ÂğÄdºED|é«âá
ÙŸSÏşİL µØ{ás»FÑpÛKuå¡T¹Öõ@ªFãØ¥7¾ÅH¬ÅŞ83ğ§·>Aš[y
4È÷vç·ÿáASóƒ³šE
Ç=÷ØsåêïãĞï?/yÔøEîXŒş¯¼ãñ½N4Œ á0
Ä-œ¨­ÎÀÛİº‹;ÍvN†²õ¸›€—_¦	ª,Ì‰š<®İA×3È@äJ5İ²´=šZ&Òªd/YJép¡Ôø½ÕhrE5¢ú®“6r´FÆa‚è9MA_÷e­»L¹õ5ts=€H×ú‰*¤¬ç:DŸoß€&•#mQ)®Ãq¡>éx ˆĞ/zyYK”>>³.ÑlÅÈ8r1çïhËlû9Œp—¬yšı=Øÿ5]ö¢mb}4#ş]ÉmsyZß]Ñoğv
:€#ÓÕ	‹ª¥7ê„$ğ2V~»Aî×İ¤¬kM‘¥¡%N7³êß‡”Ò~Mç’SgÔTì‚HóÅÿıÃ[|—ÔêâX‹Q*¬Ãª%@U®nß"İM¨Ş¹æRÈÎ©n%;2á—mÛS<ª§-
Ÿíø‚± ØØ5|?áiñs{ºèäèl€W¥ÌºIŸéÇ„¦ˆ×^¡ÁR9ãu\Ì®!aF2ød´pš@ãvu;ÃtÁâ‰:*<*v—P÷W/*ª>laË§Ñ&•éËÕ’sÇ¨›–²SËƒùD…•èS®—Ÿ¯z“l; i5œ¤é>RÖû8ß(L¼?Ñî>&V‡J/I³ìí°İ>häğ|ÕÛ\şÄwù…f¢~·Óã²ıd!›ÙÈ0j…öÍš?µn;ze ÌTd™Ê¯ş{4ãÂ)­áÍ”fjv¢OÄçÃŞ¬s°<Œ/:ku7+“ú?¢E•Z‚UKøôL>˜£&âãK÷ó÷)‚kßoÄÙ,mÁ3ßÙ 'Î¸
)9Ş™c8Ãº@£…µ&r›ÃEu)I!³‹ï:¡ĞX1¢KíØyæ¿æÍİ†ˆ8{zaT«pE™©6Éì&z…Ğ-­Z"ÆÇË‚_  €·ñ1ĞI—yxEÁÒI«¥Kz`1¥Öı¯Ú¸6{Ş á÷]]¥ö:xA¬Ö–?Â.«Qw§E¦®v?vÚß’VÇ!šHôN]¨íÃåˆÓºKNd5JßÒ‹C@%Äşcq#°¶FÂ•v—®è9¶3ª>Æ7Ü.niôb^‰±›Çó¨B‰tSëè2¾´f>Å™©‘|Mâ%GŒ
7…Ô¤„b
 1QrD¿'\ÒñÙ•{áûxÈ»ë¦dXXöİcfZ‡Å8eÓ¸s‡9®•ÕÀt…»i	,8x{U9©UqkHÉ{æ|ôœõüZƒÄË+˜º²çawõ´´B	>­_½	‚…O‹	UFN
î©…lkµTŞóIaÛ~¡+bøQ‰e$\çÂğÔàIqRÉ;‡ò½1ğ€Ñúmì<ÆŞWJÈë³ V–H¼™!ÁBŒD~\Rİ(F!â2M¯ñÁŸêâO—× èæ
<Mª¸±š¯™î}ëÕ.½UúÉ©[ÕC´ô Á—ÅTL5ı•?FÀ ÔâµHŒ‚9­Ğ¢¤§gsÆ¦1Ò[G‚Š(™Ş‚ye¶m‡¹ªg›>Õ®Ïeà™£C¯#ç«•Ó7eš²±åŞ³u:2re¢ıT¾‹=¤Ğí‰H¡¹çe¶È©±=vØÓ#åçŞ?•Tıf‹o4GHèûĞ‰)se?>XÄvŞi|ş/Rn¾†5QóTk,èx”)àíİÊ	
TÄ;œ–CMK)òp_¸¾Íz­÷>÷ø{zLÔøå•Â"„Ô=2ÀòRİT¯w¯&z`a’zİÉÒåÃËÔšŠmò ,…G§âdz—(¢Ÿinö£^nÑ,Ë½"4HÌ¨lÌŞßµ¯9%Ì)ÿ›ÅóÑI[¤zIËvø¶ùë°$oK»s‡Ø¿x5 @°tûcÇšÄıÒPkÙÏÄbFòŠw†6'£S²P…íZÊS,Rl~?S<‰g®'ÊpHÔª¤b/[SÑ@4&å+«ÔF¿óÁÄ1×L¦†?Å5'¡n/íTi³ÔÿY¥¡D9È8z¶zQRr7&‰nå	½ÙAîQå#Û{™™­i«•'±é´‰«Z±†!`àò“…ÂÉ² 	5fÑÄQ<õB„ÂíÉóÎøæµƒ$Çõ* €·Í×œ:°\ı±6ŒäÕ¢uXÖKšu‡¤÷šƒˆí¬…÷qÇ©¶ªheÈÙi»ydú’~Z‹UJ´™>ãÛ_Uã%yàj'QÇCc´5·^gÏ"„’ÀàÃ[ütÛ92RmàŸæ>ÆbËöÔI&L«÷&¼`‚ëÍë[(£Ø¨º^Ä¾8À\ª…˜ô÷2Š1±*xÖšY ËUÊµŠó@JİÍ7Åh«»Õ%Z§æô¦Yz±Úåîñ>æ^wäúî+LòÎ§?`>Yş¶TJ[Ÿ‚ãåtíêy´¨9.–ÈZ£…ÄN.Ï+fãŸ
#ê¾½à¨œwÌÆŸÃ=âÔ¨è»y¬°¥
º³/İ_µÏí³³Që455ci,XŒâ—Ñ~úpö­»ÜÎ€O2ñŒRé(ÆQ0a^­PC Ï™¸ÖpVèŠ3ÔrßñRñGú††
m\ÿû
CUx'r“¶‘"hQAoP®M&Ó7Úıú>ÙİzE¥À.¤7…„Pûè?ËkÄ» ]S¶¬"a+[âTKy=á.
»ˆKÏæuÜŒ«.†ğ\/r0Nã¯.Y£
`h¯"¢GwùÈéÍN"W”    f!Ñl'[7 ¶¯€ğŸçY±Ägû    YZ