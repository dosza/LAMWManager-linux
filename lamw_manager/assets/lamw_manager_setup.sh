#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2949505509"
MD5="1927b64734254138d23151bac4e9c97c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23944"
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
	echo Date of packaging: Mon Dec 13 18:42:21 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]E] ¼}•À1Dd]‡Á›PætİDõ"ÛÃÎGë·³ô¤ò>¨ØEsÜq–®ã,b‹8ë&ij ğŒW+¶ëEÖá§A9,ò”œúJ>¢âÆÔ>Î¯ÊÅò’W;P”ó?5ˆRM†ê¶_Ç†YÊ ·ö±@ñæÍ>æ;lÃªˆqg¸Èœ´x,FB[DmÙ¼¤Wh‹GĞTÈ}7Æ2ê›e‰»ì'­§]êÔ¢>4ég|R3Õ8É¬-TVi­££>÷nIaÏgÙ\ı?öj2È:|P·ê¡š0`î"/¸/?ŠDıBÑ‡Œwè¢‰?³÷´“˜¥‡v‘‚ÁÊ5ó‘„ i`Ù6,„ÆC¶ŸEòĞ©Gd„x™ôh©POØ4İÏTõ¼U©òÔ12).€`l°—ùjâRv¡2ŒAWªšô[]ÕÛàÇ«zˆ¿'àS»
,Êîô/ì4»i)eŒ¤;`Lfúıúwİßí»Ï£IÊĞÖ°n¥áÛIqŠ‚ïveÀ÷
 ÃË]YsH{×Vm‡E¥DOi¸af#šçti¾F(i-³ßçÄĞße“¢PB–—ÍÊ­[#ÚÓósFÏ,c!ê¸”fÅÍWWÍûã¡fóÜ©ÂX`9tA}‰.çàfwQİ©’è×YWŸ\º=ŠI–¿œ=ÍŞ$¯Œ›™3‘´ÛUë™¯°6ÿÛî£ÍÅe®¨Å§Íó6B¬ ºUjN\­ÆMª.&U¼ÇÌœ¢ÿ.À˜|Uo!PĞU(çÜ¾qVdŸvß`ç­…’˜á‡³ø‡“
¡RiÅœ•qeCjìY	ñéêºÊ ‰Óê¦§U!P÷%ç
ELVlµ"• *k	jóçŠAèÔäØá¢E±‹H;”íDÒõ°ã¥<G•¸PûÔCÚõ;;ØÛ“_+İ§Ñ;%O÷§ç”NÎds>	åV=VfG˜åfA3c‚´µ³ËÉöÔ½l“ë«±«¼µÓ"“¬»c¼2íÊ:‡Ùß,ÌLß™õ[z€´%¥HİfĞ¼W«Y%ßŒ'c¬Ø&Ÿá©H$£ú¬’»u3Š7æÙvÇTøi'³î¸n (8([Ä8ûüÏd+â šI%ş–f;AáGˆeQyÜ ÂEcâa€ .¸ßZ¿Ûç)ÆÓS SX	åı¤‡”°×Ïò«gP_u^UÓ¶†‡`fÉ¸<Èe5T½_ÍWã<ÑóoO	6áç_TÊ$’6xÇ˜ú?Ö
ÍìC~Cdä†N	j›^Äu2ºª™W³»{ò·2”¹«#%ıALàÀŠ¨¨c¥Eyá½z7Mk„¶ØuLyo€õM[—kj‹*Ç’ö©ÅœÊ•ºÇFÇ=;¢%ñÇ~¶Š­ÙÊb&º¾"†}ºÆ©+T¯Ã2ÚFÂ.²f¯|!L™£lõxã_“7R-uoÕ›¦|HO‡HQ-O%s[iµ ÒV­s—FÉ)[WA‰rÔ~÷Ô«Î—3/æ‹:ÊÅ3ŸŞÉ¼ª}DÇ¶¤?¡¶ÆÑ;ºá^<l¤Û¼SÀ=?6í®Ş^e´<³{Ogà„IbíÖÃXÖñ¥Ô_oŠF6­ÊÔê(ü[ŠG€‰‡ ñÊİ¾KeIÁaFù2×­Š]ññ#üZ}ÜŠ"p÷\Õ?†áõ¦zïNñh­äŞY÷¨Ò:'oÂ*Èî“Ì;ÔÜ±¾X%ÖI³ì›Š³‚<ê	²6_e&ÜçËå2Ô¡íqQ~Æíµ‡rn ø½5ù<<TÂP~!:âÌ¦‹36<:Q$ş|ŠÏ9€HK7-¯]üESƒ'+põMÙ·•¸ğëN‹t	%Ö?V
NeêJdÛÈÎU–
Üé;?¨bãÁ1Q-pHwG K˜~kĞíú€xµ±¶³ÌØÚ.ˆ!2!‡PÉ»¦Ê…Mæ¤Ôâ­^ØÃ³=ßu{Ğú¾*x0{ŠÒÊF/Êÿåˆãºµ¿z!fŸKÙ6¢K™™\Ú&„\÷q>§=k¿Vğ«ôÄúPşĞ$İ?ùêDÀ²s”1¼+·ûx¡/MÁ¯@'ùäÛCÔHÏÂ–sÚs¦İ‹ğ£ÏzˆU[F1PNúëy÷¿lìn’è·•ú©nµ­bÖ)p¬³ÖÑ	còÓ+ÒpäBÅö¯öüX¶²8”wƒşîeH÷ò"Š.ªSAÕä]. Ñ\kpE›Äî½héë¯%Ü¨ŠÏÌ,Ÿî¦f„%Ú6ÜA[¯!fcä§e}·¹»·P*í¥&÷ƒJ”y…ÈÏ^·™$ZÅ–Ä©õ¨%0`V55²â¨MÈÜ:«àÄò×şQgE#4t¯&8 (yr•{ÆdæÖ–İÊ©”»ŒºÛJ\!Ÿ%@õ‹¬Y5CÖ$¹è@ŠmÍ		RµNB!û®¥ú-K€»ßJ™s ú¯÷o’±ÄÍ½!›XÓG‘húÕ@±c@ajÉ%i±™¼V÷ƒbUpÊ´¦AW¯å>(ÿ¨f­õ(İ*­ºGG§İØuÃÿp~¥É]IpKr ’—ùNÂ©/ƒ]}»T¼Mâ’=™5y]mMÒáŒ…ƒbúHGœ-—šâ: äòRùüÎ‚3ı×bf§W
ÀøsôÉ:?"½ˆ,ı3:V¸¹ìQª2§Üa¿uDŒ£ñhç'sş¼4§ÂºÚÅR– Û3ö‘ÿ2Î/TªÊêÊ<ÕZÜ•Sq1	ßn_×}%Ğ¬ö¯İ±…YÊÉœò=q…éMÓ×˜‰âï#­)º˜DÁ>#Æ*¨h"#ß­ˆ$;‚®³µp¸…˜½ÍÒM&Şaã&¨H"õa%Ù/äÈâŞÏ“O¸÷X¬ÌÁ~‚HÑÕÑŠøÜ¤ÔiÍö™ÓÛu•|iTk‹eòRq*¢UrÂ`¬I1……çpç¤Ô¹oa_ôR%2µ’Ü™ã_?ì2‚şº¬g |ïWj¬ßlÙ‰{—‡ù»ØÛií‚§ù„nº×!5¢ĞIoÆ„êjxô¨…ì{té&Æ¶×P…í#ÈP«ı”#]ã»Ú}‚Š¾½øœas²í íM¦Ü»—jË@—r ÙØ\QÄq…)CgÄQß‡D
¾Ò¢çH¯õ¢_Z4ï‘’’²ÃjğQÎuÆÍÚğGJ¦êK!Cåp>¡œ\ó“ÿŒBn¡¤ákäßŒ¸£2½ÌûeaZÈºZgm§©¨£ÎNS¯njz¥‰ŸĞÁ¿© à˜ëç×¡}74TÖUø\6»%2Ÿä©`h£YXïiz2	º'H´zı,=¿‡x åğL“¥}¾Ä.ö¯/‹ ñ)fGbÒ~’À¦Qí–vÉiõ¨£­º³#ä»~tÿ?vsÌñ'’k?º!Š—?ÿrğ§Rí;Nÿq‘Èeh7ÏÍ¿Îßòªò7LÄÂÜIGÅàrÜºõ‘[›Fc&&ºgZ
fJ#ñH•mšI7şåš‰eÙÎ¡ÛØet¶(rFA ‹½s8,?„»ò—7Ó¹¬çZ9@Ôö‘ó%Rg §>Ê‡ğh+u´Ë)pdeä™?åò'•zXyh‡qxzÁ¦‹!33õvÁ‘.‡ŞJÛ«|	“f×¯~%C¬#³`¥Œ=ë¥Îƒ¥TÈ°´.¦.Ÿñ:|ª±G¡éÕêßÒrroÂN‚½uˆAÇ„åı|Î8ÊâMÚE,sS­ŠÉ'«¢!šœZŞÊºvâJä2ù¨½N¨Ì÷[•H¨ª^P~Z.z®€€vø³IÆY±¼ş¬*2'}:ĞşÛàhœ†.†$ô+BYe©+¸ìóX±yï%Ú[İX’02[ŞÂ®àróÂ‡»èóˆCÆ £öÅ«,x>Tôœî0£WB™[˜ä›Iİ˜Éo0õñxÖ©ÃÏ«àrÄ&ñm ÈNíOR™±š§ìéäŸí*/ûé8„^æs"ıS­ŠìGyÎsmYÌHR·¾‰UÂ¿5À{¬V_k|ëÃYéß%”*9|]q&ó6¤Úéı2½ÊèçÅ½Xøû¼İÎÁ9™¥}ÌkT1ËoÜÙ¶·÷}÷@8Ïº‡sUfvWZ …}–|ıöÁ5wæpaL´Ï¯™?ğøø-O/Öm±–½Dcğ»Èü$í›^[»õ>pí#e;=£,WP’ö 8¼˜Oëè0X•¿SîtWàQ¿qú=>ãßšŸ@ÉN”‹†m³¯çk " ÉµQñšø†ãLqRäôñüÄî\š¯EÄ©b¤ª¸ÿ‹Â8+Íµ#òLsêi½Šô³¸×¦®‘:Ëë32
#à…¥y°m¨¤ábüú*V30F®µHgÏXÜeäÇÉG¡­S¬»CCd¶@G-¤ğ]—ÕE8{1Çò¶ıÌn/SÊÆoı©{`0-Ra×	<Ò;ZrğF_¡b)Ç€ e™Ñv’Oj2*×¸ëä¸Hø6™1J9];J`»}±Ö‹Æw›U±”“8alh‰gÌ`¿[ÅŸ²-KØÑ2s’Ø2BÁ•|>G'Ç0”äO|$Jz¸3 ğ…2-&îãKâ;È;ôÌ¬Ä’hÈ®3ÜpEŸ§vD›âc>[;†˜Ër®Éáï–a¡Çv§í%~·8Kæâ—´€-÷¼“¢£ZÕÌØeÁMEÒ)Œ>e†à-÷“ÇN¨gÜÕ˜K!»‹ÆpW†ƒWVù‡uUhúÊâù¢Yj2¯È[Ç¨VV$`ôğ´–´4	 Ğ¨Ò/üÆÖŠ9XÜ0SñÁ¯‰áĞ_
Æäšt(ÓWú!õ«`¦x}ÜTš"Ë ¶ÂÏ;é^úz^x¨½TD¥)¹[ú
a	ÒZıZ­kğ»gdäâªf¯h¿¤Şø‡fMó…g\Á›ª8{µe,ŒAå#GöcÍH~×ïŒ7>°íª–›Y"º»Ï+¥œàâ
‡[˜oŸ´qa—®šl»~£ä§~JtJA»º×Y‰¿üŠ
SE^¿ÙÒáI¹„JİëÁ(7Ìæ}³jÒ±öôİ‡f»OømôSrZxÛŞgÕ‚˜Ä“LÏOo /´‡û¡3oİÊìæÒ&ãØÈMxì}Ì•Ù%”&}î—ú¥=1¬ˆz—ĞÍº`g¢¾+Quj!‹!j	Ohıê¥‰$£h]îÒµ Úš&ê¤À4ïî(t>hú»kº¹)„–Ó74È²L!tÀøË7…×€ÛCî­€ê|Ûø¡ãî³{†\O'>äS¨º×ŞF™œóğ¶Í_'Ï†qõt˜ö`MSP3´¡}àE`·EKVóTûzG’(ÚJ'{K	$Ô¥láËíÛØş>ÎÜµb’¼æNo\å—é"~F.4{P|zëÏ‡ëÇğ q© Šıf˜åãyÑ‰ÎØ&Ëèn€^| AÓì!€×“{Izh@	<ƒS™{…n,Å¤¶~é¥şÂ_ùgy‹Â°t=×¼5ÍÀ7óÚn8“t9©L5‹>·ÔÙâÂLr)Nß×Õî8Å•:kÕÑC2ZVà•ë‡]†waTË©ÊßApxÆ%-Py:YıXºEÀÈïİåB#Ä­™±&£nX½yb„ÍıM3ox¢¥ş×1/0ë­Ú¼N*Î²/£ôîwE@:ª.úÈáÙ'sã~jR¨TÜk˜üÙl­Û…]ÓÄÑ’‡]7Â!kù8=¶™ÕÕp…èwıµ	à:áß8ğ§;ºªÈ*[Xá,	›ĞKi²øb¿[İÚSG0ß©7ö%GO¿*E¶ë tÌõhÎöéÛ+¦cı%Û}	¦¥awkÕ|‘Bøïøl¾;ß,A~A²«ÔP¦Åp‡ö\á ´Ÿ$ûù¹à{ e‹Kç`'_¿¬%bfÇ˜N&ß¬,asGA5Ş¨ÙK@DüÎûÇé%Ë¶5Œj{uåŸ/rû¢á®ÃÜ£¤…¢‰7c^å#	Ì§
%Ìxáw•"È(µä‹fÛÍÿµ7ŸÍ®œ[!hNV-â:¥‡€'ª•ª@}µF=Óœà¸Û·œ„7|ûç¸Ç/XmÑ`ew4¥
‹ŒI³·†‹ ä£YDj¸â}“e_ùtW®NÊºO{ïi^9ïÑCÓ5Ë÷®Ê"ßÃM§§oêúHdKç0ÏqŠ$ÿÒt‰’´³‘!39…æUTÙr¾iW—äŒ4Á˜=sLÁöQeGïp¨#)yÓ`ÜØw‚·ÉfƒkUÅ0?k;y(
lP%vê©KåŒöT8d/\æÍoÀ–Ò¨»AL²R·{×Yâ0è™æ<b9bÄh|^n=­cjñs¢‘úaV”´¤÷oaMÜË"4-¡W•ƒ|?Z‰Èa“ÉyÆÚçtd¼Æp{<¨Š¤ÙBŸû·áJøà,«ˆ–@ ÇülĞôaUrfxY`¬d©î7oã&d*hâE´”Uv¨iÒÒ|¬Ôæ k‚Eæ·á6\LÖ4À7Äİîî”œzWä“À™!.z<ÌŸp]…»é)t$D•yõ„³fö…<ñx)”leûÀê‰½ó·lEŒ(>%ıÍÚâÂg;®4Ç`Ã:kšß~Â­Q
)àˆØ’f3v@2è¦HŠ
ÊúĞl*ÒcCÀÜ¢!õzRJvŠì"&8ÀŞÕ4µ„â6şiŞD©ò»ø›şP	• CŸìN·«šƒ—'k­ÖG”S¡>q§çüf,Ûı;î¢wCæ}¶*\ÖH}®ÿG2²[Ëÿc•Ú¯PõUeãßñgÒuiDoËÙÇ{ù€M›Pøªã18aæÊĞP`üåt©[*¿éxËSIÊ¾ÅúZ„8)l¸/º¼T"ÒiÄ:âƒÜ; ô#§È‘œ@"ûª[ûÜáU4ag¦ÔíF™ÙFHº8©däæ¯áœçÃâ!©Á!¼¿
 Nâù°ª^î:¡+qël¥c›3áÂÜ§Ã°}	éc|k¦% ¨¸“ÎƒO\FÃop÷
ºP5‚ªú)ŒªñV}ßüás	9-3Kx3é¥™J+ï<‘3ò§±‘òÊMÒ•ƒ¤wÉëü1 ˜´HOñ³i@wócn–D±|ag…µ®´ş4u#ø€R½¼µA›KfGĞ¿çeJ7 :âİwàŞœ°}mkï!K=Ó‹@#¾'xäÙ>¸Ä<¬ëô¦ËÖ9öÍv|í•á¼ãŞÙÜÇx	ÕéÌ%W¿ã`úŸ#*œ9é´Õ°”%Vj§‘Q,Ödè]0]—¾ÇRÒğ!4oóéÙ1pJ·ZÍ5 =m2×dĞèôåò}Ñ§1¦ Ciæ¥
©fì¨P1®mŠ…¹fÖlU»Z'}|6æ03#×¥Ymín$†û0»2yÆQ!”zÜ\`TÚ0?İIVé·‚š'™øJÅŞ|7°‹]{‹­YÕöÅty3æ‡€RFoü8ÔVä`˜’÷[%Àuæ4¾	Ÿú¶ëR‹Í©¹gÀ¨~ iVÙnÃT–›«k@ô¬Å‘µç0”ƒ»b34Šò&]”ı
ÑS¥¢Ç¥Gµ´°ux4Õãûl7R“fŸúÓºL96ªœææú>Ş¿GÈ¡4À[şHU…ø#2¿AµÊ§Æv|MRÎê.xxÌ®‰ĞÌ@ëŸ 	;g·À×²)k}í`£ç°Â1µTU:¾ÅKŒÀ ÍeM$ã~Ãöé`3¨PŞv9éWá‹ı¿-—s(† X1ñ%zpï0&P{¯#Å
JãTRáNâBê‹é*Aé!ŒHª	‡MÁğ^]2¬ÖÚàé±‚(ï}ƒí÷„—Œ¨n/#NŒÜ³]Øs‰D¸’ÀW7aC0¼ÄÁ@•u(+^K×K³cïçå&f='H nÇ|u_Õ{‘ëX˜86’¬ÓÈù'BRô‘ùUN‹}™5ÎöİÊ/3[gş¦+µ‚à9™¿ON™é—méø™häAõƒÇ^YÒóÅî&Ò/JÏ2®ÿ^¨Ã=fò}cNxsûÓ¤¦U2 4Ôª™ÕhåÕCFÏP”ã¯Ã…Har".OÍÓyHöÂNÜÛñŒ<K:şw¶?=lÃÌHõ”õ|ÌÄ;½]{M”ñnPìÃo‚8 ö 5>P nºÌq»=Fg{Ö>ZçÙ›µ¦xã†|Ú6S@8hqÆà2÷c/x™4ÈœBDÎ“Zßûj9Ø<xê¦b¯ôàÆ$îšhÛ?³2 «É'%ƒ;=ªÎ[‡© g2xv»ú‹¨²G–['‰ıM=\ƒ­	ßöväİ×dgÈv·qÃËí5xƒ,OÛÜû{ÂŸ vÑ¢*Û?¢* „cõOd¯¢”áJ¨KgÖ4`p"dz¤ƒ$.ï¶è®(v%Ôr´l–)NŒ’GSdĞúuşzúX\ÑvêQÒpXpU
oR¢€é?u¡åDfÃ8r¯¦Cn"sÏáöT«´;t(ñ/ßfŠ*¤ÄJ&I&W-øu¸›ˆ7GFDD@Êö[îu	EÁy­ø6è}VuĞsk‹MM°©G¼oÌ4Cş°ğºI‰;A[@fÒéÚb–E'½ÈâÀÆ h,#’‹Èó_?¨ v¥šåÈ„%NtÖ~²
LBr´o§Ù8¸N€z¾È
(Œ+éF#‘ëg^È
ß»tØ¾“Æ¡Ó: âüf5>a"_OuYö•7NÛf€Z*Ë5ívf`)~Îä-KĞE°í)äÍ¨İê°9“›¦nµ‰ŞSœÁæâ‚I9Ø´ŸaL“°{} ÆĞ»,n.±L_	­DWÑP›õ#J=übŠK±IÒÏ¤ü‰^ÀûUæ{±/Ô|¢Àıu¶·È,Ò†àò‚Z¶‘aeÈøKr,ç~%™P;!	F‚raĞîæ—N÷›…ÔG¦1ÁÆ2'Uõ¥ğòÚÓµR9	ª{8ÓØÉ6äıÙÀÄ=Áış+»8çBŠ§”
bÒZk½‚M3ZŠj®Ñ_4’ÎoJšıÂb%ŠËˆÁéLŞÀ.qÄ‰Ê›ihÍ8³‰K¼ÚÜ}ä	¼ŸR+5I
]çŞ¹p¡î-w°Uòl.–%Ü};tnÑX‰±Ú¤Äx/¥ÂçÃİ¼ˆ Û¤k‹=¾VÓ´P5ûAïá{µKL¼CgÙé¢®½ØdÍá‹À i£½_©öØ7eeı#K¨š2ÁR,XÖÂêN¨9'12ÏèÅò¨u¾[Ãé!„9}iËºY?åàóö[›™v:Ù?7.ˆ8qkmpi.´w§‡rßèÌf´íÎ™ûLã\‹¶nÇÎéÓÂ‘¡MOAÄ¼F¶ŠÇ¡@—.H‚Şz•ª©—¨9•ÿ{™”ºú®cë¨‚Gš^¢À‡‹ Ü©¢eBÃ™·ƒH5ÿ„Y{e´eb-hÔN…·iAr!8° jx´5»6‰c•_°XØ5¥o0±4y}·âÛ=Ì „–¨BëĞ¬JÜ‘üH‹—G ú‚	j®yß¬·©Nu«Gı­(²ÜQÂL‡dXñZnÙ¤Boşş¬‚÷«Ë
ëîIôËKwÔ´±?£ª‡¸5àçE­{¨–ÃÜÏL÷T¬QøšJdÍè#æ‡uP1rC’.b ¡>ì\²Ù/9Ä˜£Læ/c5å¸ßy±B§ÑqIXhA½OgqıÏ©nFX‰6xˆÆÁÛÖ~ZXab§ı
	é-=È5ò®mÛ¹R‚‡Ôm D°éI…ø¼»ûoÔT&«bÊä ‰÷l¿Ã¬Wèò‡’otW aÕlUÅİ#_E¡ı;v:=u1Ô½T{krlêb9ùå‚ŒçT*avtcS(3¨à6ªÕ'%}ÖïË*'û÷ChÒeè"Æ¢Ï9À,M¾¶çx¡Ud,Û&6ˆÄÃD	|,d±Ì*e¦Ò¶'MEŸ˜ƒû°¸Beşé)CEzk9=µ;}_ûy… ùñú´<°)¿_]1{Gƒ/Ùˆû3#qa@ö> Š# £•õs“ğA\Ùnr¶4¦í•ãÏ&îÊ.å%câ\ˆs ò¢Ï¸ä|0´ş/¶ßzS™¼ö&ëÜVÈòâò¹‰æ€p:‹%»5V|¿R<Ö²p;“gI?0g1Di‡}Ñœ »UŒc.ôuèëŸbª‡'ÄMä˜ùÌ0 ªíocWCu–ë>Ì´rR‘AÎudJé¢êìµÀG† &ªç²¢¬\[*DË4Lb‡ “òÏœ Jºs$ÙYyÃ¢ACÉ#€ÄLC·kWTÚŸ²£Î îÎ‰¢1°œˆ¨½-è8ê…ëxñ`‚‰/®Ğ3^‡Òş9"ğÙí=	-(œ*BL 5ŒÇÑÂüöÀÒO~Á3˜®>ü?İ¥-ÅÙÑZÅà¬åĞ¦¾•­G]¼ú°·©u€àÏ\şáêúÊòîX¡5_…€Îøüˆó»ÃÏßÆÌ¯)K8 ‚¹.$u-QÀ\BZ­™ÛÃ.¢‰3P+Â›qâ•öDc$¦¼3ôHÚ–V	Ëë!zşâgŸ¦>‡Å›‡ñï&¹eµDÙ·Ğ­7l•ZümVkwUsyàë+ğÑ3b Î‘„•É^‘ÀXò£ïu+>×0¦€¿ıŠ±O	[Îûµ„Ùj:¡9‡«7œa¦_hÃMwÃˆû•Õ*†ı9}Â±‚j²"é©’ÌÖ~WƒËóˆƒ(‚*—[˜Ïph™îŞå„…äœ ßŞÔ›TàW6~çÀÅ¤u­Æ¦	ÚK§\tx_\Ì ¾FÖFÀÀ5æ´kÃçfï†•ÂTë=K{\Ê¿Ú•RÖ7[×&cuÂ-@ù²w‘çtè”L´ÕR57•¨DTå¹çÒ)†sÒ;f%Ë[ßP+*d¼Ë­5^”B;¶"ÄZ÷AĞ4kÎ™Öñƒ)cq­…7£‚ƒqÔÁWIQ}ß^Ã\ádˆë	1Y*KùmE=×Bvâ+¥Õ!Æ<·,wÚ2Ğ´aûÖıÅ‰†8À æ«š!·˜Ó/{^=Epi…Ü†[5D òïà¾C·Q2ïµ ÑS7XÕaRĞ¡g®;ô'_ÖûIllÎË¥§C4w f•%!f ½	Ù™’ºŠÛ3ÁË»}²ÖËrÛù<jŸJ²O¹0Ù¨‹˜oÑ¶§µÑÎ<ö³ĞúÆ,àÚ¸5.ÁË~CJBíÆVû.ş!£}J»	q/Á˜øX¨¾³r8Ì+ôtq¸çtÒ=g¯Æâ«(Ò«Ó[„/ÿ;;|;÷ş›.…u©o&½	ÿCÕ!{3é»E’weš­_$¿I8Î­›r
kbÌş¸Áón2u½M$„h­]™"Z--]xå»›”jbïB1ø©Ú	ãúÊ?NluEÏ©EL`RåŠ8âï!îíÑgµ™Ê;8t_¥èAİÂÅÙQ¨wµíY(R±)*Da¸•îÊuîCz·å˜céÏmìõºI]sùC>¨ú‡ãkÔL2Ğrh8Íq)Yf· Ì%ÑŒÙ€$5rg<7;×“áíãù°¡×ĞÁC›şåš¢¶dG6ûU¼¾!	“- ğ@%•Ùİc²óAÙmRsJ_²'¹œ…0OªÈ ­iœ°Ğ%”_­¿^Ê±†­Î|,B@_2ÿ:‚4^ÚêR+Âo<ŒÒg6‚ãRtå@&2üşã ÚnBÌ#RÃX¹ô³h»Í+!ÂÖö´à!÷@·è;ëÚ¬MšD/GCõ¼,bœ×õ¸k—Ã¯u~®?t)Xö ~G^¦UìÜrÆA=De
j»‹1sìtC¥A"‰¦Æ²l´ÿÄ¿®¾eï8W„ÁEŞöã$bxp¹F¶£WÖûm:T\ŸÑ…3I«EÆ8Âhò±(c‡.jó·¦v^Ò”‘
£«lH#Y£ã`ğ$›÷¡—ÏâS:«óí×#£Fúº­ˆLdAR4å¢Å39+†¹"
ws|±{Á¸•\â¢³2O5ûøåzG÷Ä+èÉ#ÈF±ÜVÌİ3nÉDáWƒ•	mPqGlòB¸«g¢t£D:C·aö^ÍÉ…¢Ø–W/ºA†²…Ù^×ãKÂ.ò›¨Ê¿_|Ëb®)ŸFÌ^ÿv€İ·V õ§Ï”GıÒäá÷ $2ÈD9Gïı Èg‚°ø’ö5šj&Õ6&hÍƒ½ò‹í ë_«5 uºcÉ%X…4ï–7Ã·<w;|[œ•ôî­6É$äñ Œê9«×˜$MDŞ0³DÆÓ/IÊ>zúÊ%ù‰ ÈcV"^
×ÛÕ0H•"?&fpî.³9Œó©ß®¤­ ¼ÙLQ0¶ÔGXÒ£{Èğ¡hqj¿¬.G
“ûı®yrÆÎ3	³úe‹vó¿^÷IQ¦p,ø	,*˜Ç“Ş™!|V$ƒqj#g¤Áxğö"¥(&wP4%#Høoàı›Z$ÿgcºĞÄwmé9â¦ô„¸')ÜÆ´Švÿï"ıé{póÅ¢p¬eTw³K2ÿ~Î).töå0´/‘Ác`ozÒ«ªa´FêÊS”•·ûQâÓóèvAô¬q¡€¬L„²ëJyÈ`(TïËu{E4b·®€ç»ñ|cyåQ=®I³ ‡–ÇhŠßîV^*ßB€‚ëÅÒ ¾†°SZ‹âl8vÍ„¿eİ‰l[ñM M“W1.ÿ¤Q‰wÍàå[ïCÑŒşX“ĞÚúØäØÒlàÏ”âş¿/SKôb^Ú*’W¸N²8xê$Ì~=ü”Ë±ğM½ïGÛz%‰cõã_éÄR`p¯!ö®{R
Cdå•	Ö8‚¶Š§Ï iàÓşxå˜\H»>çŞwİA»ÒáUøÒ|Ä…µ:úDæ^±fåâT\/ï>Ğ æÎÂ¬@ú†*´G¶ 5X;G¯	:…O<wĞ:àä^UuÛ_uÓ”!g—å}0"¤÷ßÌtcÎ~!,»Ïû
ç	—xBWé¿Kt„J5{—kÿ€a"_£ú|'èÒ†«Ø>ÖâE¾­èºIÛ6İâ7U~ÎÅ5:ºo8Œ) ô{ÎŞßğĞêW+QQå[´½Ò`±pğ¼$Råuc†{ªIÂ]Çß+BlÜ^I‡ØS÷Ë{i‰•ÀŒË	mMZ“kÕİ¥ +İ%˜ª¥:P»L«H‚˜6”Ñw¶ŠÅ­¨ëíë­š éÁÆZøÏSâi„÷w­,S|ıä‚<š!G{Zœ%¹®Uç+ëV&`o`-Ô.…­-O‹ünÓÉ›zıp™T¦E«ıÉÁ¬©HÌ½î’•R¥ßBkr'`İ†P
ÑÛµÙLÛ	uß}ÒvoÊÊ  qO±Gò¨)$ÙÀĞÏ÷ñpçR±ğO±Q
?~5:æõ¼GPÈCÜ‚¸w5¹ËD 
í‹/¯ôŠwÅ—Äoß§YÕ¹²®Ãlea-àbTOQm³zz1x³?Sùj6–İÁ6Âw08&øh)|$D¥ÕÅÊÀ}ó¢GzÆ}!YXİcU½zïÑÂk‘tš÷‚ÁS³WÈïzšªÙ×;lß‹¥[Äö’Œ7¥ïL BRù”^X–úyn±FíôX$“ë›á€=” ÜâNEÖM£ß>ª ‘„(.¸†Ò)ªL<‹ê†2Èª»s¤>»jrW  ™ Ygÿª=¡ûMòYƒR;‚Ú•òaÓw96uÀ³,´Éì_*ò§SPyØ5D|Õ5ó/#«O5WBä“ôQÈ©'øÈ:Ç A™,¤êÉrÿò
÷|t°î"Ó›¡ÏÄqãìÂ¹¯%2˜F
ã
¢°2Äãâs±àGl;š¾¥¡‘còğ±ºpşô“¶$SÂcÀÉ‚éT\±2´„Æáº³/§ID—Ë“D†2ÛşÍ´6²Ø¤5C/â}¦n½È{ =¦í@sÑ¹EÖª«¤¦EzåÒğ›FõŒÉznò1˜³´L(hë¥jÁ£è% å•gA°ÃfHá±¾i	7D5HêJ4%Ê)ú^¾
|U}!ìğ­çŞP™	ŸUw]J‰>H8_gRcòñÅ46ùîUÛÑu™ĞÆ™[²<!¡÷ThŞ&^Ã&¬é8‘H„MwÃïÃ›·<¾¼ƒh\eÄ¼ ÛMˆ„™*¸bÜb­ÎxPŠ®×tÉ?YˆDÈ¤)H•)6Y·Ê7&^÷\ûšK{N›wièœpÄ¢°oµ×§/cPGNh*–¼ÂÚŠÒ§^ÉÜj“qN~6")¿+ìt½¾IÀ‡^Ì|€Âø{š'ÓJmğ°Y* Š–ş5Ò¿­:DÑ¿fsÍ2RBŞù©Â/ŞNFZ°»^ 1¤tİ\½ÈÕÙ©‘7[ÓvJOÓ#‚„6i6ê9µJC2‘­.­€¨á³zÖPŠ*—¾“œzXq•EY>‰Ò{DJñ\¦”µó~İœ—ógz·ıvŠ;€î¹”—‹şª-”]¥ÃN9ÉVìs˜%ö'nŒ4Í–&X+ê£r^ôk""İÔ°±Î5±»´»NX¼C­;çÓ"XPÎË%1<ï R('*F>.eƒ%¿¾è]¿G_€è§åëh¬Iáƒà·¦s$$¶ÄÔ±W!ËØÃå‰«Göä+]ØÏ¤ègÇç¤Ö%óïâÈc¹i”-¬¢`ƒ^cûe€íªV(ú4B›UÕ”`®n{…º39°ÖJãn"T´–¹ğ‚Ã7u4}Ä°ÿñCé^‰ß@ní¯·§/~W¥”"?¬Ù^T$¢wÌâ±k8ÙZâmBËñp¶NŒ^Gøb*vCP3Éù¢’•@Y¹m#¾ë
6!,#h/­"£qà>›	–…¦Ç{²ù0Œ±#Àl]mC'ÍÇÚœZc†æÚŒ%ºsÕ­‚…SMVÙ›¶èL™°+ñCÀ>£”¶×<ZÓU•é”ÜëÈñ/<)…¨T¿çánÓ5g“Ä¨ä¯Éj‰
lDZX9NÜ&„Q°Õ˜hmGjÈpßòÅÉrõé™Õ”ñôqx ²)ùÓÛ/­]‡H¡Ùúø9ªö)áŞ›¨Ô™b·©E& y¨v}'Ó¸`: —Ú¤—&’è¬½s´x<ó>OQ„	¦o!UR
4(Wä^é+…»\fO²i?V^iÚàı‰&<÷ç¬)|Û/C¿Ç‘Š8H‚ïvbv—®ˆ+fE7EÈ,l\Q³PåÍù«#ë<ÅœÅ¹ÀÅQ±'ÌÁp:¾æÉó¬oÈT»åR+»k•´8o7†KÙºBš~œ–*8ãé	<7Ÿ÷™6Ìë1[á.‘r¶oéƒAúqÆ¡W3‰)€Ë"cñ^`Oi\¹Ñš€£ÒÑ@ƒ§µe†Óó°…!˜oòÛ‚-
ª{Zô;r_¿¿¶’Y˜±ié‰›Ä\Km¨#“MÊªÍ^«N†ş­í2µP©»¨ò)ÅÍô1}l.U6EÜô†ÏœÛñÚŞº6.îárgîF¿Ú§ı¦¦(°«ñâ3•Æ|MN’ |Ú¹•¬Î°Ò./ã*’â6Ëçµ÷|V &ç«•}ˆ_a!V=M-‹¿Ø:Äy6òIğ
ä?|A~~ÏxşÀ>oÄUcÅÿ«ïÏØ'D„ÒE=4øƒTİ\á
„Œf=K,6ó#¾—m,õ”V€PAg#sÍ5ZC+¼¼m„CA]|î¼ç5ÿÔÆÏøÉ¼õ3» bœ»vlFÏ‹)åÉèáôü“L–rôMB}oŒX8ã‘É8åyï¨“ÖÉºìì˜V…÷":ÖÜ\“,¹+†Øz6âw}ÊW’„Ù©¼¹è•m¦|;]dvÏ’±H;0J„¬ô>[n2™éQfíFU¾À®Œ±Gv–½Ü}ÙmÃ4wRNÈ;å·<¹[`™šq¾¬F¨m‚X‚–ÃöîNÉê·¡ÆlûU!¤åó‰÷±®¤NElŸåÑé¹üTãXl>éáåÉ6\ÈÇP´è²‰Ä˜ë+[Ák©MæJ[(à87}N¥¾,—ÜmeÓŸ>ïƒ2Ş…í@ÍÓ:åÓ‘Jnê(Âq^¢{T)Ï=î'•£JºéyU™[´âà-Ÿ-İ(ªçA¯hÌ:ˆ¥R.Âÿì*jàd7î±Õ}Â¨P*ê¶öm>]÷o»‰™™~KÉ`d´ÓPõ^á®W§b¶,=ªêËËb÷û]ÓDÓcâ­ô×‹¬åZÏ7s„ë²ˆâ¼è]lc:“Öå³†ó>»t(Q	u9Ôw—wZ‡°+<Ê[¶ğÒ¥É+ŠÒèüÜá(oN>ó–Ná//<ıcUËÍ	înìAÄ³êªâ8¸ñıaÇ‚m¾İqKM¤b­PİLô)eåÒ/µÙä¶…
¯ëß’~ÅçÁbÄäÔ^W~&°Úï¦ëWéVYŸ( N´x·¦‘P€Í)BsœºCyÆEÌ\ê„¢`dãækzõcÿ* TÑ\Óà(½	×·Gù¢Ó\ƒC×âEeÛÒ‡,}ëar@jÕs>ÆWDQ.¸Ç†¹n$ íw…©SRB*t(Jõ‘”twDÌ;n>´ÙÔfÆo“Á!â<6ĞWõªÀŞú®Öïoİ"¹ûê-€í ».OV‡.¾¦mU)ß²üƒˆ™Ğşq/{O_ÔUd‰dX©‘U›Ğso5©Uıˆ³bû¨åtÅé‘ÌÖŸ«‹]­°.¿M›ö^7F&İ(‘*‰»<NL¥%_Dë0‘‚4Ê2ëmÛk>·Êì « Uµ*Áš¸®‘+]YÇÏ3–( |ã ë–İø•ã6³¦|÷Õ‚O¹nÃÂ_zHc³Äo®äºMcAİÄV*šyûeSä´§OÅurï„gÄ§ïÓî ©ÍÆT_çô79ÖnTüuâ/yvXY%ØòœdwvÔû¤û¬ÈdÅŒÅœÌ™ãıß?’Äˆì¤h¨IËQ:/*h.2BÛ	gåYåÑBÑÀíÕ‘Ò:z:×â¥Ï4 —õÜe8®¶™8»k¯¢”Ñn
äÆz>hr-  z’ ÿäóö9få%ÕD|KV¬XSË($‘/rp*ıGmô ©¡bÜÜ¶}¥}fMû¹ŠL%ˆ£w»Ÿ”TbZéğí}Ÿ©"#ÛË+Ä@>¡øÌrñß0t=ùKjä7“)tÕúNÒª>M€<âyÿá¬»Ğ¥Òj¹¬ fXÇö˜J­á,z„Ä/Èñ •¨79ÈÈC¿ÎPÂ™”4ïÚ—oë˜GŒ– êô/swÄQİû*dèUŞˆ _«-M…˜8{~½ZÀ8ß1äœI¬‹©ê»³ìÑ™]Ìªç®¯•y Ó–sô!Œ³É•QãıE(­jIG\¤Ô_äVÄõ ×õÏÿlª™—>®Bá–wàì<CüåViL°ÒçŒáÙËô?æğoŞkÙş¬'Âuİ°0%´=pš¦ç •¢w²sBª‘ïÎ1E_øsZ»*¬Ï3I?Â"iğˆÅeL‘ Ş›ñ›X~wÈ½Yˆ GˆuØ šù¦ö#gõÛû˜ò7ßAwĞGOFŸRp€øğ½\ôjÂâÈFS€Y¯ÀÜË±¦ò}¹éFg«I»ÀåDWyfuƒ~Ş±}F;?ñîrÔŒLô¹úu_O€ªZöâ@Ùœ|[ÚÌê¶¤Òø.4#W•
èÖG•[†7QVã7Æ*öÂ§XÍá@»ùêºßƒ7æÊğ/¹/Á„|p¹†ÕÍM|.)¹çNğG»^GR…–ô49%¦CºÕ"äû¸ŞYOO<[-,2ß«ZuaïU¼Uq ¾h”ş
ëyœ÷¤¤»‡eáƒíÏ&?"³Ï(Rµ¦×ôˆlÀş¨PewuşÍº#¦
œƒuÊfíåºnë	é®ÿC± ‹eÖbmGì*’­E3í#c5,ï‹ô	eÄ*^¦bh³ÌtÛC¼y³Öğ?}j1’ôqÈL‚áóŸü„¹e’„ô™WL^BÖ{j«ó_#—A
J¡ò» w²Ï|ˆQ8kÆ‡û$f¤ˆÓÿİ‹£ó	‹¸ÃŸ—GUv	ãÔ^L|»`İÏö¹zP%ä‘qí?=T®ô’5Š€š¼9jæ	Ò
b*fXPµke‹>tÖÅ~‹MË–tü¸ôÿ ­`=
Ñ9‚³øó ÁÒ¦°¹(#Y[%ƒnA÷ÿÓÌÆL¯±py
t,Wx’ü‡Á:i·´çØBäİõ)=šÚö´ü,7¨+$0»ÌÒŞÏóèÂ¡Jë%ı‘)ÿXÿÛ²¡½L_›?€á+ÁïÖÄBxO’½ìëÕ[«²ğim’Tàk·xñ"¯kàŸ!êÕ3™ÂúL¨¥+d½	@‹ş\ú?Ö+ùÛÆKİ»êæÀãKıĞ–SúìÆÎ#S¹Ï"¹‹8äëóú)A±‘Í9£æÏ@B•‡*RLiÍ[qıL¿8€œÂ9H®j.=ßÌ¿Ş“‡·íp*ÖCºOGı÷ovB‡´õ±?wå²w!ã ëC¿¡Hí"3ÿ/mÎÊ‡·	ÖX—0Hœ—Ã†FCË\yÎî
·ÜîJsä"¯aHÈG{‡Rûå„ïWézÇŞ.K[5eıŒç›“n¿E€ÄU·åÛ·É6ß >v¡Ëngbõ»[%ÃÂ{ş?a;·š ¿:ñ.‹šR¸ Æb­¹¨«Š2
í‚õÓ˜DÀä	ápÍÌ¿3:ª`jŸ±5£›«àâOxæêt4¦1™ÿ™sâœäè3®/ÊŸiÿÂz’?Š4QDŠ‘İ±°qwÀœòªËÆ®©šë)*È5ÁŠ¾roOÑ®Úñ'¶q=ÛÇœ^'¥Dª~•åO¼ò¦¯Ä.=ø«‚ßgbÇ3ßä÷şHÎ¤ÎÿÂÏ•¬)3¾$hÏöD
¥|ÙágxošºO	Ütq§hîîtâ œ(ª×¸±Z¶Ş÷ƒÀp{‚>^øÌµC¾ó±LYHb÷V®ê
Êl7İYÄg¿Õé†Şqvü:»¨…‘´ğyª¤•CÙ2MUô7'´AaÚ´²?È(ıéÛ÷BdM¥0ä5ÿÅÚ>îgL€ãûøvŒıñªÀA´4g4XË~ƒ
ğEN¯@Ÿ-TK®ar^‰Ñ¦¦4ãbètğ„ G‰Eà ½Ó(&!«´çÒ9ûtœpìó1”RŒ…„'“‰&¨ñaªŸjºKÕM!aœŞ‚bj°øt;²lñ{ûH)^Œ›TêÑübÖ†$>>ú¦aÖ	å$™›~îrYèÒĞeÁÛ)Ù¿§µ¯zÏ…`}(HqR0„<1ÿJŠÓ HÖ½å?û"0Ñ2®®suv«VİÆ5ÒLôEaPQBÏ´?ákÚârúU¸]™e²­ãò¹ûè”|Ôôzı¼ÁôıeûÈqJYyùl»Oğ0¾ÖAÂ}n¬c+÷8}·şåÂaÙùZ‘Tëô|Yt*™­±„Šƒ¸ˆBô©‹!VFà}©Ó$¾ÁÀ¯JøòdÏ%âwÖ
á99í*/‡Ò²(Kvû_”Ëò­ò’å!~Ø"vfV@‘Õ™¿ìcíÕÒ)æáo~ÕÏ«® ÍˆD™örÍŒ$	ö/œ},£hŒgˆ„Qo‹À|ÙåUèø×jZ*ñk4Ad`tÿjåŒYZô	w›Vğº|jeãzİı_ûgÁÑÈšòæ[â¯Â%vFúH^ìáÕî'šİ"Ë^‚ :ËN€Ë ÉùÍö›ÏŠƒƒ~INoíi;Cæá"X©r²;ÅR¡TÅû}õtİÈò˜Ï°;> pû9>|q¬Fì<Y›µ!C‡-í!ı‘.5´®5ÉÓü³!±yáÕaq­ŠÛäI„HœØ]Ïë+‡ut´pÏ‡øHÌ•¬Ø¤¯}²	ıv¶dÈ}•@4€`A4ƒ›73LA(póiéŒ¶&÷(9ˆËD_3½Ípú6$>Ë:	±3)
²ÓŠÊúI€"u1Pòğ¦Ç÷—ÌÓWÑ%,ÔÆÊz#õlME€/šSÓ{×Ö¿*]İÒĞqâNéÑ,³ø(~{h‰ÉçÈ@DÆúôn2*±ƒ‹¬BÌX" »fg{xA!24KP¿j2(­A‚ùrRä9¿¢áÇâÄ¤l=` *ú¤oO«6 2QÍ¨®åĞ~’AU~¦ÿ©dj_#•İ õÅ³Ç:©L7G‡üùÉ¦W}É"ôİ=z´nıh%ÒsøÀ1›Ië¯Ï{m©õgÅ^zd2äå9<•ú© ö¡\}jlÖ‡Ph1BPw 	!„Û0©©åxh@7‰ ™üèM´a7ÆHæ“Æ„côõäÔüÊINËU	uX¬ %ãıê‡³]nA…³8ØêıèæF
pvÃ±µ$Ö|"‡\bĞ©¶0üZîéW) _Çí§½,GSéÿ–&#5×ĞTğöˆÍ¯lÔ1oj„YjFæI104ğq5Šzpy.æõò:ö
½ÎªuÁ 2Š õ]h*ù9ÓÂL^Ô6Ã‰®aO&‚P¬'£;¹ê’şíY®Ø2÷qšÛET¬˜MGQLĞEg½AHGIŒ¦’x½]u!~rÆfÿzİ½+NÒwyí:Ø/š‡×îHšöÁÈ.KÖ'cV.ÆùwşcŠ3Rç Ã  ¡Í
ÂßO „§f&<äû Â”€X…¥×/r·fö#‹°nà×¸
©–æÀÊªÇAšgTRÊb_ŞQ»¤Ì#‚ÀÇ:^{¼¢‘qÜÚ¨ˆïI"£s¯²@“
›†ÈŸšWùË—³!L“wü¸jòXI06ïÈ¬ó†¼¦JŒn,^·E2Ì­LİooÈlEUå/›ï¡÷¶°İ¿ï(Róilæóíb¼gö6ÕÅÁ­[D)×(?“¬í±Ë¿§œbv)»°z’ì;oGG5š§Ÿ?Üäå|9vò80)tº(_=¯@¨ˆ;>l‘ôZ=k_au‘M}ÇÓÓõ¶ò¥5hvÄŒœ±.È‡5ÁL!]ªŠ,@C8u3åõé† ØvÇF+¨Ï©6Zı&
JäG<FP7´œ÷9xÆ­w. ×éñ37aØÜ›ÍÜ!ú¦uêËÜ…¶–àN[ G¸6PÁïx>ÃO“”÷fH4 îå€bÃˆ3…ëËiÇdÕIyw(0Fş¼Ïù‘`¨5È?xVŸHU¿¥ğø»ıÀuª7KÊasèg@@¯0~ù1t'ô¢õUº@îRKT¾Ğ1°éÛ<{cğ=¸I;Ñ¬×Bé¡Æ¨÷qÌºI÷÷áE§•œäÇîÄ"¶¿\›ì;îT¬{2Ê9LQ¿¹UµıÆ³˜™®87	Í¹šµ Ø°šç“Sá†Êc.¹<	,Røâ@N¤6‘†O¢h_‹Oæ7Ï[Ñ]$^ÄV6‡}—çS«Î‚¢&Udè¡Rk›YúÔZI²­#~GKO!Ûî ³<¾^Å¬B™áÒ<8qÈ°Šı·Ó‹†EœU>¤Âê8©´ÿ±a¢ôu¡¶ ?ˆ³ß¤¯eZdŞ–/Üå.+Qn)|„Ï£-”¸„ºôİ£½;—÷{ì·³
˜hÁåÌí0ÅŒt¿Ê€l\àyÁİˆ¶UÎ£“xq²n7ç~èTFà:r¤äWèâËÅpÄÖWÿ´»etÊvé·­Êß“‡<´}è-´×š­ØT
"Eïî¼Œ¦b1õ!ª‡=zØ+6›=ÏDRæ` >—”ñ%ĞØÛó¤+¶íw‡	NeÄózCì;îÑéBB9Ò ÙäG3gú÷‘m×eBû—·iÄÁ%€?Ìˆpûõıa˜Xƒø¸[ò;Õ»˜%	]¸hkĞ
@™æ0à4YZå"êVz¸¯”&”%ã+cQé²Mª85CWYŸVxœÍ^ú¨éw(æ‡=IdS4pº/çH©åı2\ÛYN8x7Q˜ˆ‚º‰‚ÆÁÒ£ªm² š(<zƒûQ'eó ïêwEiçTy‚ '¯²Ä/P1YšBBo©ıj˜4|9ğÙ®©Ù‡‚æa¥æay=îƒü„jP¶uÒÅlëæ—rUŸ"qZéí~’Ú´Ûœ¯Q.ı·ÍV»¸\oü¹¡ÛWÚ×nÚ5Ş^yÙ }[ÅÅŠğİ6m½ƒ·£XCµ’MàEøèWçKÂ¤Ì”îç¦x¯ŒÜÉaprº’oƒ˜Gzù©(ÖêH Õ’BSÑ(ú1TÿnGHÈŠ|Ml:£Ì¦‹Û/Wc4½\jJŸbkÂªÖåSAÊo6®åÀ­\®|Ù7´6,hŠ¤]D	”¡°•µ~Z$]•/Uã—ˆÑNKáù¢~x½À¡hì;¹F>QK|Î›oFêõ\³‚\wŞB.¬UÑšõğ%òÍöşñ0şŠ»ŒG¯m„AÍ.p£ç~Å

éT!š;}‰•„X•!8ÕºD|êl]+§-î“íbæQDwÑM°úb:1—õ;âEjí[JŞ›¹_õñë&²¾”!t¨­Ä=”’íFÈêÃ&äİpÕw€eÄÆr2È”-óìÌø5)TÜdU;ÊÅœäja.D*åx×§v­ne›Cñ9a·ö˜#ª´·Am½TZÿW‘–$L–B‘UœçN?§lT‰€ZTõ·{¢­ÙÄ;Ú~ık®F–•UC—éÔ¹AKµkoW#ü§k_…ä·@ OŸ5¤Ò¥é}I8ÜRN(°nQ+Şò_:7(úà­Œb¯Üa¦@ZÉĞXşAÒŠÑ«‡(Ì×"«g0-U+­—…Câ^äaëo™Ö65		‰~¾ÖpßE@$&É‘ªlÌÖ—¾6ŞÜñY<=¡é!zYuŒªë“¸yÄN+#Ë¨è\­
§ÜOf¢ÕTK†(Ìw“/Ÿ­¥-y×ÕşğÀ>éÃ:Ùz}Àü0ŞØƒZ5„/GWÖéx¨©›
TPHÉLn&½/+à»]–ÁÕÆ ®ıSooÁ]FµAÔµe[­†»Â)qòtrÑ€ÏuªVbB”ùK–F‰áI´ÑA@,·qW¼?¾ôô®Õ#ÜJ7{_>à,àköå*ÑF/mEÅÏâĞ²Œ¦ª—Q¼×¢T…Ø©	³.¹é&9R¥±WCvÌVƒô:c(^KZö:%ªmbÑıønÒ})ÜZs˜Wı“²ŸQË¡u/&m¸ÓJäwØ(ı î° ^1i›·ñ”7›ÜGä‡v¥Ä¹À¢…Q`¡ñ‘ü°?„Ş™Qut¬Ñòâê™&¾)CàJ½S™`Ìì¶ÿ43•ÌôèÚt'„êzûÁ!y†ê‡2Ò^7Û8Ö¯¬Ë½Àğà¥àC=ÃÃ­qœ8!*.x%ŠÇæ5Üc¬#÷qÆˆ7µbï¤®²h3šU]$q½­v?ëÙÒ'ÜÂ¹<ÂÌÔùÕ¥sÁy÷Ğv_]'²#´›shÜ¨e¤¸;)¥g6¢¿Ú«u*0ú© ÕÜ8sxN!ïtß]jı•-x’/l$…”|j«V¢íÑHéÖ,ñ¶Åõ~Ü°Ÿ=ÀeCM3f”w´-(fŠŞ)?=IEZ­®[”DŸ¸m.u J6> Lºğé»›®ã´®f{K.¾¶ S<Â>4‚Ì›„N¹ª!-’éûám…0Rş×D-/GgD9ıÙ…0¼z!ÎèS`èv±S7}¨F)
I •~Î;øF°2 ¸?}%Ï…¬Ğh¼wÊ{û5e¹¯!ÑSa}ßš¬ı³—îÿ‚?ì¬]Dì®WsÏÚŒ_¦ø|ho~CÈKCßœ×X3ôıc BÀ#µ‹<,«öq¼¡jíw¥»K]©V­zÃ»BË\¸ÅOó·?î'BAƒD_;ÀäxgàzÔîkœW1´ëÚkMN‡*¼{hVo>eVuĞÌ¥»ã`IşØ`Lá	¢fêººDù°ìÎ¨ËE¯…0ÁŒ°Æ–èãú\#!k{4˜£°uQ9¢LÉ×-04mKÅ1¶AYçšÌ&Ã·8í®¹Î?Ó•u_DúQèÈ@Øÿym§ÅÃ7R “U-bàèÙèdó5‘k©bl ûv?òLÏ„ß”­ùq¹¾«;ñó„²Â¹òT~k äëıãc´Û°.#kŠÃ‰ñˆ§…³»¢Şç•÷¼hT–‰¦‰W§C$äf>Ùnº¯J‰2ÀqËš²ß¢OÚ3…‡bÌŸù'ä™³Ô`àzì‚´İ±ÇjD:M‡jõ¸99§‡?Wcs—¾}Dvta¥àâÖÜ„›¾¯÷Õj6X	hÛõ)şºˆM»•Nc6"¬”U”üç Jé¹o¸j&@Ó÷ÂLÄWHÉM|Æ‘ÈûŸ·–1¢™DM‘06O¦0²§Ê:øáåw]˜ËîÎpiÀŞ"?|å§Ëè=nı ú÷°¢¹si[Œ3%0&¾1/zVğ²Ò=R¡¨]fİ¢ÅN>š¶W*mŒG…T<@ÆWíÔbj•{!÷:°µw´ÒıÕçcÚûİvW•òài˜­óN¸šœ|ĞòÔóÿss¾IÿªíYfæùøÒªu€ÕÛó§o´„u4~Wß4*s&ÓàÂéJˆlkë„×'RÃÎ†ñXkœqw¬FVñıO'Aoœë„LŸG‹A˜Å8œèùîLİ1ííœ^à~nÚZÙú×í˜Ağ¨ÀÙDn™<‹¼î@¾ix/·†1:R—Úw^2MaÈ¯D•Jf@BhUµ{šÔ«â-÷„-¡W#67òéØíOk']Æ#hãK§´jÔ@:°(½M+(mb[?k?‚¶GBİ…•ª¿p6ş¿«³K‚ÇÒ’¸Dû‰Ø[AXÿÓRn÷¥¸MòÎÆõ´/Çs²'Ã¼çìÑÃçâ{‘„ë†iéáAÜ%:øĞ³1ñ~ä¹%UÇ+mU\ÖÌÛ#²A{Ù° —»+€NFÿvf“9Æ+’¾b¢¤æVGpæçel¬„4¼áã"ŸôÖ€”Í+±b½J¯Éƒ‘¨[;ñ¬ŸoiÖ •y—ú-¶¡XÈØ7ÌÏ	»{:&#l·Ø©Vø¹AÍF-­L‚¼–W	6Œ³ìÂ=Ë4o²F*Í¯xúµÛlú-ë,QŒvpî	¯@ğµ©ØØœCÙ5ŸĞˆµ];*2L‹ˆTlDáşXè'şîT«Ãv<H«%ı§dg;Æ‘?ÇSÃèZºTW\=BòNd2Ã-æ¬h®Š İHåBÆÅEÛÃøn&‹|?ÁÛâ<ã¡ß kÏµ*ZízŠmŸµTç‚4AŞ/?….*ìd å*ESõ?^„6¶»æ”a'áEAà:1FNC^?bÄãr×Dş!EĞÅh¸"_ú¬2Í¶èÈÕP…~ƒ¨åŞÙ¹´,’mü™ª’öˆ?ùm¦ò5À~…f*7è'uü$ÊKc6rJêªÇ`Ç= ;n3kOˆ;\£´¢[xÚ^Ç˜æ´“ÄĞX#¥CÆÄvğ1"£€Ë2~„³$ÿõüæ/Ñƒ‰!ÏÛÜz3~]‡tn±\FïÛI„œy8¸Yª¹íRŞUM¡è˜]‘Éšå¢.ÒúÌšïÿŸI´¾öD2tšµnÉd©Úy öéœƒph  ­¹½j>YwI Ui‘¨…·9i&ç-ViˆU¯“løoKØÓ˜b`D¸€5–çê	§z¦AÅAqM9^^à3r ¯DÒ8r í˜àØ÷7ˆ‰1k¸ô‡-yËNÆ28m­E3z µ«FÜ¨y&è)0€ñ¤†òŠ‘ÚñFÀõ³Ø2²\©—Ö™š†Œ^?s¶hjòháy ÏJ`%‘¼£Y¦
,ö™=ÓIÿ´Úİ¤‡€·3OEU¥­zÂôSÕ‚W³›@Ç:w[ x«Ÿ‚c“Òß.e¶ÅÌ·˜:‘CìSBƒÂÎßí*à(è©ÃPæŞl*Ñ»ş§R­qwšT_á·Øï4åé²'ìğş6áy]	Öé®ïÕŞÕU†9Ê6g«‹«Z¶«bEi…³¿Ó\ËF±jÒœ/ˆi)An?¯~\i³7™åÒs
ÿÏã× GâÇ]¹-…ŒãtLüş¬©ê<a>AdUGôŸ¥˜ª7šÓÀ¬©©“=ë
ò¾"·ÆÁ-ƒ&óïJ‚Jša”Ÿà‘¢„øì ôG4èu,,…ç/!aêŠ~	ÂÛÎ;<åöÁøpdÛm‹œg¼}
œßÛ‡÷I/+jmãk/¡¢3Mƒˆ*zÓJÕµAE…ı,’(Ô%µQîM"ÂC,ğ3•úº3†¸ÁFE§.¥ÙCèmÚ´BJ‹r²eı‚=>%ÏHÀ]‡›¾¸#†)¹–†¯³}}O\ªw],Tq¨]û‹˜]†×:ß¤&t“@7Y,ïÈ'N…'8Æ"lvTn·Ö ¾´ôß)Ÿ¼\3$oSá9ñ_'Î}ãö»¸a·Xn–u9ÄPu–íQõºÖŒ0Ñ'×«D*Ó€¬}µ3º2ŞÜOÄúµ®{b‘‹ó?eë.K4àlX_ÏZKË$\=	 ×/]·YT¦8RïsìŞ©Ak‰ì*¸Ê‰ök®º¨i+Z‹3G”98
öğ õ†æÁãäd<ø.“:¸nÀÕÍZ^||PŒ–W±Ó3Z4.ÔW)™,X2zôĞYr1.Š»¸s# ËSL÷Ğ­pÂŸãß«ßŸf£‘4„PÙ„²´˜LidùuÈ¾Ú½jÄ&T–Sú7¤CpÜóoC÷°$l>xF ¶]^Ã(ïÌJà–OÎb†ouÁîRwÁ¯°ÔºVÍÛ‚^S«Ø¥B®ùØ‹T9@×Õ»øéQÎâw]Î¸@âEâ}Uf YtrM‰(ˆL¨…ˆCÓZĞ@ïa,gkõ*—’^í}â/À`seüC“‘óÒ±(mpŒ â÷ÁnNFÒ‚Å3ÁQñê•[
˜ƒAäõ‡"H#Ğz˜W¬] ôbŸCÖˆjãŞTãuîwé“ƒ5&¸û;?ï:pM¾kµjÁ ŒtÂ¥—î¥%_A;d$6(.=ìÃÔÙ}3ÀÖM\~óÂXdèxŸrı!„e,Ù¾òøÎ$…ÜJHÃ©¨PçgQ•s¡vû‹~eöWö`€…ÖdUÏ,9×2œ1ÿİ
¸nÈ-÷Ûh€\HWÛğã‹:çf~n©>¯ÒÍ¡‡®áP¥7çTÔ‹‚y¸¤ª—÷­Å”ì€Æü
Ö°?sH	ÕÚ$¾aDqıõ=öŒ“åfÓ†{SQ¹4J­»(®¡øRM&˜ÈàñRu±¢8^×®²‡àkF™®#Öİ%xÀØª·õF íéò¼\)o‰pS>oŸÌQÉ|‡'tîv†UeIAÕ¼ú Êüü4ItDeÖ®f‡ŠM+_çBS­YÃĞĞ\á	ÂÏ³ZlÑú‡Ân¯MIèÌvƒ#‘Å„÷y&Lêø),pãd%ÈSKÔïä³æ~#:ĞŒéq1zi‰ Á¹ÆÜqª`oŞV˜Ï¸íï~‡š7AĞ‚î¬¹‹9i4&ê3€–kGáÛÄá´“?Ybš»§ÊbıQ‰Âqg"ŒcEEi"‰SÁåg¬¬)ÙMØ;H**\˜ósÌFéÏ³¨ƒ2ŸªezÂ2x¿ªAs«µVëecƒRËÈş"{äZ	!jñÔ`Ê•·:ÎĞ'Š5«G? ™x{ğ²	éæÏ!`ã\’!81ç•˜Œ¬±kÖšit-.¥r4ù‰'¸Ş¨”y,¨{EÜÖGFíMŒ¿µpÛ•G11†t½-‰W]„	Ü© ßĞÓòñ ç(v™DS….DÔ»Ó‘·­Gø²VZÏòSC$lgvİÕ1 ıÒwZ³™ÈÏ¦óI:d0)¾9š^Å…P*€µ•¯ü²¼7ôškˆ[•uW]ğûÖ˜h¸«ÿ6Ûk+Míªt¥K?1$3˜îJQ‚³ 0aoBí¾ªÚ_ƒ©Æ_´æÜ{AÜ]²	k%S|¡"qÉAâ`á F¿v$ğ%İªËw=’_e‹Ş’ŒƒqYIGcØ÷/Mæ¯šFûËm^Í|óÛ÷¦w*["»q§\]!ÁVÍ÷(;1¸#Bˆèwvn5æQe÷fduÚºô÷”™,F½0#ì uÒ	›£óÂ³êÉÇ)Gí\Hş²Çôá‡â(,’´HNtç–`ñÈìéQEörT"‚u4Z·“¬O"Ö£ ÿ.Ë{–¸H²B¬•ÔµîãÓ9µ¹ìriùzó7Îô¡#úïç-L>6	˜	¾€w·I0æªP©>«e€½ÿø¸o¥éë«Ú¸'ö‹*+'è„ÀŒºyBÊëCD$`ß€ùÑÉOa&ğ1¬ôônÃ´òØÁ€wcÖ	"+ï1Æ‚£0=ÈoĞù…Ç‰ôŠ«|İí,Ã§ÿvŞÒ1#m‹™R;ÆšÿîĞA#¸”XHÌ^äJŠ°3g~Zk	@GTØû!?‡ı½ëxúpÒ~®ã%!7†ËîÊ$ü¾bÛn@£®_ÌrO²9)kõß&£~Ä8üZô×Ú‚E¡–ş)”T‰¿OrtÇÿ”\©ƒª×ò›È‰;ÿŠ!ÄßïH¾jÚ-•c×ÏåÎC…©üôv¿ó5Üä}ÙPÿåİ!ºÍê@J±b¾6(“'q`¸Qfü?•oàËÌ$qgáÖcB7%W©·Aqİv7T¸û‰Ğ}€w	9U…Ï¥+_2V¨w-zZ(\ı&È~"´£ÿ,Í÷j?:ß£:7ÄÌiWÊ/k„»ôz&ÅŞ¿%ØEqÆ9¥`(l©G¦)Vº\Õ7³ã.¯®Êõ¸ ªëâOÃ¢Tõ…BÄŠÓ~5óçdØbh¯S¤t„¾¹ñ‚Qkâ+ åUù¼<oNşğíaC$…Ê¨¡´Ô«Êhæe3AªKètûÿ4×øÌ¡nzø(­|¸ıÌ\¨­GYYl† ü Mq¨yá6JìŸgM³ıÿ+”ì†è÷)¼8Jß+Cş¿ªê¨ÍŞÖ ‡ ÑÔ~(©İä0ÚÆ?]°3to„vU ®'q™?æŒJ€;ü§.VÃB¯œ¼ğVñ¶¿q–ş¡xÖ'à^R=–.	¨E]øÁX,öa+Ùp!Ç€bßú(å’Ìëz‰4¶µ:®¥y®ä] dB‘zr’nûÌË§Õ|×îCÇJ#JèÀ”+ö©,ËõM­•rÑ_;tâœ­Èš!æ£&»7WVì@Ôd»5İÛB6…AÆ”–Ì…°Zı….'úê-aJ`À‚–‚&§*im¸·ç)­ÇaÈÛĞö£mĞ¯BàÙØI„£·¦„Oq÷ÇâO4#çìˆÂjEø¯ğÖFÿŠMvu•™¶º8×MÏĞàyr##¾[1jèÔr‹Û–„/ OéØ±=şã¬c®jwş´ùå\œÂ¦TI*zŞ2¡:j‹syº]W›­«@´@ŠEÒ*Væ¬–K§6#&şßV¶WbLì<¯ceáÓdÚ¨– &ÊM–Ïñ±ò¼¡Ö[«ÿÎß‡T¶NDîŸÔ3ÃûU?ÿ£0,¤o<oW=>àmBœ_÷Ås‚.ãŞãÉ¥Z„¶L4BHä€".Zg.‹±ÊTÇE_•uD˜Ë¾*†,xQEBûú¦"Ãû¾X¾Ê®~u'2İ ÖGªÚ¶[=(^ô'JZn…pè´hZĞ·$rË?kW{;“0ğJâœê6YÏ¿z.ëjç$5gÔî²uk•×æQbû´AÅ`&ºm‡ï‰¿õ#ä¦KCdp #“fp–ñg•ìÁ‡Tfº4±|„(ı¨ú©ºˆcfåEtâ{¾vN–4Sl•Êı{†ÅSP=?E $^«šÅšò@ã$~´Vc÷ÉëóÌ:ö±ÕÜ’ˆÀ.4¡KKNË“yĞXöIc‡7&ß³<WçQ.±Âı«Ó|Ò8é	·ÏÍ_/_‰à3ìùkz‹DVx¢Òíü~OT`'Æ,¸0(óñ­ˆ§Ó`k°e„ó­øl1Œ¸g:Š¸’ Úãœ¥âêÚˆ¢†÷®uò/Ã™ª[t g/.j„y
÷Bª›áØ¬NO1,.j‹æÙ“üÉë~œº<Dö[¿e™šïO¡Ä÷éeƒ¨vmSÂª‡f\Ø÷¼€Oø')Ãdƒòûõ3¥M¿mıÀí:}—6ÚMQ\K-İ$#š—Á+ØÊ&‰R_((@-J´SŸ³°îª’dÛÈ&0,/¹$påzæNk¸‹YgMÒĞİ     »
y=¾ÛÅ áº€ÀG2-H±Ägû    YZ