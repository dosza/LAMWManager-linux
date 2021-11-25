#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="310929576"
MD5="3d6909b0bdc14fd269e7fe3b327fd2f8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24988"
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
	echo Date of packaging: Wed Nov 24 13:35:50 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿaZ] ¼}•À1Dd]‡Á›PætİFÎ?ŠÊ®!·éCdïO®,–…á´Ş‰R”r?Âú¿E^ıôø¾o±:ˆb£/¥}‹;ËlVê³®“Ì¡çW{¬5cÀN~²vĞ¡ó.‚şû0„v_~–^[&¶Óûåm™5ğy¾Yè¡­XŠ¼ÉäŠ"—·†ò°a›RÇ
çX«¼ŒŒÊi ú?½cİ Y	‘Ï[ÙÊŞ¶?¸Ä3ú³€$©ÔÍÔ±ö</PCëg Läƒq raâ:á¬ĞIãßÈEcì<g¹OE[V€œáÀƒ”ÒDËMÁ$š¹»ßŞÀ Ñ…¹ø.Öc÷O;­Ù^ÆVìby%Ì.++:Ù7é$]ö¾©!ì¾H7Gãt–İ§û7íÄÏØ9\‚ƒW¬"ê›Å,}áƒ¢”,ªpzCWDê
-ÜÅKQÈ‰Œ‘¡š®I=N-UÏz·9LÅµèO²äÆÄ úh(qª|j>s^ )3e¤ä 0çÜ½;P‘&òeSLOçGÏ¶³—Õ¥örˆıN”É: q÷Ëu#±ş?e¶ş\
L™™+dëBj˜»Ø÷Û„à-îîû“†ÉG70ÆçzAùEmV-3¬»‰İ“¯X
¨üTû+qCOe#¢8 æ·<<¡%ääoÔÙD_X1›i@ı¹ğ 01Ô@¼zPLD¦§S­p	©PQqîø	áƒz*+¨²À¯ğÁí˜¥KÁ<ºàÜø]uQOd‘®z¸·KÀÚK­z“ié×”†áÖü•¨v¹‹E½?\­%T:3®ÀØ½1	®°`~]Â'4G¾¢„ tbCË&_¹,İÇsóÕ!yÆ£*%
F§¤‹”Mz˜=Tk¯)Şàtj¿tdµJ“Ûü’a¬û'[biP^ÚÉBwe¯	šŒ~ÌÌ„øk¯pÆuğ1÷[$=Ÿ©‚×‰õ)Ÿ^!náµ„Ò5X™}Úx‡y9[¿²˜WË¶F§“Ô“¾/ŞDÊÉÅ¸uyÃ¢¦¸J,¹ıIí.(ß±©ÀÑQô˜åpë^ŸÅ0Ë—Je˜´©™µäM}êŸ2û$·ôÑ¸ôBò	_z„aì;æ'Kñµ§ù.†ì£M†&•Ù+v­ÇI¯9u¨•¡H«&hPF;[°væáER1C·Ö}_QMñ‘óX·v‰243UÌÏ,ùÔ½èıÈ‰„˜¯5£›‹^QwiTUm¨©c	¾c–bGªëÒ1P`/RhËª¡IÂØ%eyíX€¾CöTx¸Á°ïxg‡ö^²}!çiä³—Ø›\írQŸ#§é_p—x´hj];–GiŸfT-óÚ8@OW\¸Û‹æÜJ‘ĞÔvØáÅešÒø"Âb(Âôk9ÛÙ“FDe,öF8UƒR«BÍ¶LËµ½ÏÅ+ ƒKEpı`ÌÿyW§e½)k¶ò3=vr]®#¸ï…&á›W"yHP	£H0ãF~`N%fØaÑÄOví
—K`V…l9ı¦—y53
R8‰ófÙÅH‘±×…1[hHÈÃÑ1Œ‡yÉ€õ£)Ø´÷Ø‘|ïc]ì`¢·DÄ´äGÀùóÕÁ]±şÿÁ/LÈ_:hÖ€à´Ÿ
Şyµ
J—®ÍÿsqY0|+£tkµØ.x*gsÓ³OÉ€~)°š ¬Z‘1ª™²Uı¨‚Ä*¢êaÌ¯ßõ'¼‰¸À&$ãæ¶A0”õÖ4‰2òÙ8¬sè„ñ†‰é“1¢Ğ}kğ1ú€¬«ú¾İroªúÀéKvåKUmc»°9:AÎ9Ìˆ0	 ú’óÎeu<Fÿ9h°à©`z]jD¡ìëÑ‚0ñô©êF/©Oh„ÿvÇŞı29¸Tí>`†v¬ùgäØ1Á/ÑRÏ¥ğµõçÌÜ”ª›ñHÊî1³gm‹JİLœ/I¯we¢ã»’]M"g} IÏ`å³@ó^…Pˆ+šŞá>NXòïvÆLg]Æüñá‘Ï•óm¬)¡#„°Äƒ.&Š9›7©jwn‚ »´@Öğ¨J"(x~K©[ -˜Ï=úf¼Z71cGš{•Àwk`œÁ§%%é 9që|?j¾Q¢o:±Ó¾**á+'C[5Uy%8¡n–îÈ_y“Ş[ì²­ÄaZ/GH»éq³”’j?ÂYs~Í<*?€å®Š‘ÉFç>#æ×V«KFo\µ.‚ŠéghÊ²>3ş¢öZ¹2Ñî§´ìWğ¶;©Ôp–B.Uñ‘ù ûˆÖt´ãøÂ(§f¤ÖernôË¹Â [Ÿ)PÎ#DdËz÷#Hx”`¦â,–ˆOá{ ¡Àú\Êi«Ëvî£BÄĞèƒ2=:jfYÜ^;èbÉœ™§ G\ÒÍêÁÌ-‡ò‚
QEeÖ[:¨mOy/¯¡-<ùA0EPÅ9K‘îÁWéE¯i	å’Éßª#b:—ƒ¡š?I<(@ŒX#ËÍ¿/‰'K}¶"›Š¼.í¸©3)Éeªl”Î¥!â1	!ˆ§± ²‡WàÅKfË_!ËÙü”û3é5/¿/ç„¬ëˆ_Z˜·RÊÃô“Î^Ì  z¹¦âšâü,šAêYû’‘vÖC‚Aû Nï¶¯‘ûç"I²N
XÇ\x¾wât£üó÷ãÜE=K–3
6$zß]áq€ 
œvş5P†|£Dx‚pŠµ¡•`Û\‚†b°ÆAk¹ÊË rCş$D¾˜|6Ë´ü´Œé±Óm »iÛ| xå»æ"ÏÍ–I& ¡_¯6ãK‘”¡˜01,+‰ˆED¿l Ôƒ½èïå˜ÇÚ¹ÊOŸÓÃvHL‹­³§0 ªË¬Œz/ hàbÂ¶Éô«Ræ”u"¬=D}9İT,	ÒÒéjÇdç1íaÍuİx#…WW	ãWî [Í‘÷æÑ„Z‘bÒÚi°=rå”ş“Z¡*µ=İâ(³º=
ÅS:¢\bÿÊÓ†i®·6}@§îùÿf½­¯œ›‹¢|çÌ^-âÈˆº)©X¥¶—I×løÈæ²Ñy¯+„v6óEúàßnr¨êÄs’#Ùr?+p ƒ_y‘²˜oÏLÃ“k°j—¹\}bA·,¶{4rGOì`á¼ÏÄŠ«èß	~€o­+ÄÀ¯t®Œ¬¼«Æ«œ	Y~ã¶<»ŒK ³Ts>Œx´Høu/>úûâˆ{‡aø¾l¼Ú¡—ç:œ8¡l9ù'YëšZÇq’Bú³†Ö!PUÍ-n"fÑÉ<ï…‡Û3	„f(úˆJ¥ãÿ'­GóìÅAdŸk/™ˆZÇÑk¦8‘éöİÁ”ÒÌŞÅahq'®UN âêÑWÕ1m7?¬¹ê“‰ıuìŒÔüè—¤²¤@ut·´ó
ßÃzKú.»
Èµà3÷ìŠèZR\ë®mÑñQ•KìñY–•µ)$c&U´gG¹½z¥ ®rU"€ÆG\‹rŞ¦º:›»éÒ®hø*}ˆo/ó”¬?fG4&4õ¬èë•‡*Dé8ÎÁ€Êm=§ì´^K¶‹Éõ!'(º7Àğô?]äı|ºy0bçóœzŒQùÍ¾±ÏÌ(úpî¬¬HÅ¢wòõflš&ºHÓ ·¾0 ¸ŞóµÑ–øJª@Îë`&ğ7pc%dÒ0AY}KoĞ÷´"?™$ü\Ok†; ªƒûM'È—°q)¦ †>}h!úJlšƒı¹¹èí}·(¸ìécN*KiG‡÷‰È}näjÚ;iP(5´-ZWÎÏ%%æPé‹ÔK1½Kq°©RšFú•Æ&MİÀ&ç(Î¥¦ÜïªkIq3µ¿`Â8Áú*PöĞ<Œ,€ûNpàyâ²â	õ)ÁB9¼˜ÅÎÓF;¤¨­bŒc>…,i,Š×Å¬Ş”|Eë¶QS7¦€W2´Rò¹ñ«Ì÷Ó2iÑ©ŠEKIŞpò“0&'ÈØ±â y-z´Âiê«Æ‰÷vƒu%g\¬Û yŞ÷À#ß{—dñ¸:ÊÒ¥ˆFvF‚6ÜİeÄ©O%îü“Mˆ7p[b]\ İy*0F"VbŸ.ÁÙ\Ùz2¼øE÷È“”Ï‘Ÿ˜qKË§]%˜UÊãŒg5 ’wmT²£§,Rb†ƒÔOO ù®bÍ¥ç'Ls¶DåE¯ŠD´†óa0ÙTC…Òƒ@BÁ½z¤ê‰Ägf Çtª“˜+—ßHÔ¡@Ö#DS%«.4,|DŠU#şÑÏÅ¼Î¤Éd£Ñg?™±Ûå`â[‘¶½u°€sã&i«Q¦Èpuä¤Fe"ã"'a]9ÇVw7ŞålOüêÈa"&1 X ôøËšCZ_0‘µˆæåÆ•i EÿõìhˆeV™¬8&UşfÒ¦´/.4F7/ùé«Êg®Q2Ás‚lÃº˜ÄğRİ·ÂKii…Ùó‚±\ïcyç§‚!b©ëÎ›ƒéƒ&yŠ`[ìZÖ÷#·èM/‹º"¹	gåÇÂ²ôjÉ¶î×8œ)7„Í;9s±šªPŠ¿1my(ø¸­ Ş”ÈGp³–@aiô}™·oìÔ“\û>?›?rg3ßÓ~hLI‚³Æ,Sîh°·™‹Ãı¨W®'üÀñï¨±¸Ws¶i¾|U>‡,æ
;óßûæâJñ(:ªİ&L´«ĞÑ%¸òº«‘tvîm<%Ò@x–‚¥ã ´W‹£c…s«BrAÿ„fgkFÓºôZÇg?$M®dXğdÓk÷?Ÿ#øN¹±¶†z²Ğc¹Ò*VlãÑÚhÒM©W*®‰µQãn!˜TOÿÆß÷-nçp|>ÁEİ¤Rø$IK2ì+½ñhPû“@3’­ˆöaô¹í+ì`ï¸÷Z—¹V½¥¨7„›‹á~ŞÃ.g:vÀØn,EÊÅˆÄ¬ù2¢<ÔĞªn>ÿêHu¯°Kiß´:A,»háÌJ#—Cs,'%(ëÙWÌÖºTŸ'qQ0¦{¸Ê_6±Ú/õ’ÍLˆ: ñÿ®I3#çÇTJ\Şú¦˜Ùux˜W6Ñ~ ò1› ıqP$ËÜ;”ãM¯ÊãoØÖ;¦a7ı†ÑX–Â–“ÁsÖ ù0lâıh®ü kvdíldBÜÁX‚6ş¥‹ÍÒ,Ë†ÌòíËÊã‡Æù¥!Ÿt¸ù1Æÿ¯¢mÂ&æÕ½¨!.xSúÜDW½­vıUvDpµÎü}ØG</•Øà•¾ñ^^³´ó‹±ì¶~­4ß# ]î¹y–%mO–F}Õ†°ÁR:Í´}-wô²Ì¨6¾aë¡|fÍ0Û§ ã*;»Ñ>EÜ>œ°@¾$Ç^©Q{ÑZ^í…—ïHuh¹ü‡˜Á³\,KÄX½ò\µÅÒ¾¶l^M0èkÍÓ’`V±	uÒÇ`3õ1?6(sNâÁ™*¼ÖùúGbÆpœVõ/\A‘\İ§¤)M‰~™¨™ i_ŒöÃ‰š5Çy@|KQ’­ÃdOÛ€óíÏK”á8#Ùs¤íXWD#U‹ yñìbòª]™ü
ƒ>NÜÊğ;ƒ/ŠobãÊ&NDùf¢^‚9c›¡²ü@²pÚ—2âĞ?.¨‡üAÁÄíCnÜIZhÔƒ”jdg±"@oOö9×)ùÙ“ÆèPÁŠzÇ¶Úè]ÙäÅEè6å£ÚËHøKÇøÔ¢í¥~»èÎ(ÄdzÚşƒø™ßáû[wBªß”OÒ÷†¾¿ğH !Ùa¬!V»«ğ«nåVD"ÚEÓÊW3ÔQıªÓo•¹˜Ş¯*&	b„q>æHùšVıyÍ‚LûàíTõ2?(4—†šÑ[g–‚9\±Îæ‚pçŒÄßûÆ¢ø9¦%ı —¼"¦uMFŒ¯Ø^Á;³_îæ(å¯Mè§²kM$U½ãÀ5©äõ¯R´¨ÖaCêÛ4ÊeuÍ¢b:Kwsï|Üvš¿ŒóØ’¢–y—òŸ #`‚ğËôÊ°‚	ûµE•Œä#¥ä¢„0F–ˆÊ9íL?²0t[Í`Ø¶ñ-<ğ'Æ4±ŞÑ£¾A-èİVÜƒóqcÜäë¨­6½¶bÏ|šB›!I|:ØgKZø1L—÷Ùø"âƒ2IP´öGî¾f!ŸÚùv÷•æƒà»: Ş¯\Ä¨¿A]f…ğƒ@äµmAÆ+·¾×ØÄf÷¿jï²´‹¯>¡)&Lš2(¹Öù«ÛÅƒÏ¨´QœäuáÈr¥æd@4òî‘íü
µÌÏdFq„1ÁAû±ı•cilÇqÑlËÕÌ9%£lèimQ ¥P-TÄ»tVŒÜ›˜!*
ã¸Gä&eú´<!7Ëmqª™§äÀó=ò–ÇH[°äÚ§É°í'æ¯jßózıa(kPh¥cº	êÜHÊ·Ú´¨HÜ™x¦å¥ÔTEu£-å~R:I’rSÍáõCó¸Çæ¨Ê­ğá h¥sÛs»×ÚwÁ«Päëg™CÈİ°À$Z sä¹NWX%U9‡ôßÅ²šÖ	CÈ ]ß}:"’×pA9Y4CÆ±ĞùÎ÷#,Y¤\ñœÄ€:%]f‘›¸KÙ’nêŒq¿ğ¿ÆN.¥¹Ù¡Ô<T™­X4#Kà+Æ…G§JRòb¯—„PQ”YQî‡8®ú3»H¶ÚÊ³Âüß¼¾Ò”Ìˆnbàûş’ı_Àê¿ûÙ(êiF³ a'Q>•71²ÒhùYM›P'[X;9ÿÀß¶ù€´q5†²Et]<±˜…xZ~ßß¹©Í&-¬ğıAÅrĞ ŞæM<å`'ºİ“E \BíPM¹=ıó~éÜ”og¬€ípâ²ß¥¿>;üékˆí‘©$ú‡õB5(QÍª±'ÏEp¾ØE‰Se=ö¬/ÈÛåÃ-§’r‡*Šn-tÀz]™¯»VˆÿÉ%ãÊüÊj+kñÔÜ<Q	 ‘x7Ûûh•F¿ïvS0³€Uô²‰åc¯¬_.<kĞqÁ2èDoX“ÖLhµFÍôoaÃÓ¡³7€”g˜Déï>VMô äqƒeÎÊH%Ù.Ê„¡ØRrr)<1“'Œy˜Ú,_™©éòïìq]5¤r¢µÑløÓå#®òÔ£C¿õtc?âW‘êôÚU`Ã
v3)ûùËK^:k[wD9Å§ÎQ~8Şt¬Óóí¼)Ã
X‹¶Z¦Á×Pó§Í™_ŒÇÛØ‚¥Æ0[Øx(éFûäW+j„t	êNó¬Øìª½à±Ëo~šì$ád•p,ÿ‚'œTÒ7<Ê>ñ÷MCy6—0oºPØ$òÑ®#(—Û%EÅ/<pA¢¦ûq·óa”ã *[Ò”›YÈ5šUA£Vàc¼[B¹5né+¼¿/¯¼‡t©Ã\6‹§QHÿDpŸUÍ1sIgìqÁYˆ"İeñÁ›¥®Tô¦ !,ÃïºA­˜´WI‰gT–» w®!¬<õ¦½=ÇX	Ìn‰şP ”¹Ş?¹iy•r|¾àÀwõkÚŞ?w:u.%0LHÆ¼<È°ä¾®*·4ĞK`rä§:º cÉêS¤íÎ¸¬ÇÖ¢´­ÿd!‰©á[´kª¹aFÆšº÷¤]hÔŠêÈà^±9
{oÑš¹C|ª€‡Ä1ÛXLÈ P‘”ı
Eƒ`â®ZÇ¾ú)$¿sÆ»Ş¯TbÊA†¬Áñ¦¨|­“v™H[’yÊË2‚>ˆº–^Éü¤WµÉïj«’áx2¨1ÃøêÄ*½Á`©Ô¨íù"}uËÂGí´7ÑöÃTp7Æ¾#æìÄpow7àEÏMÇò+¦WŸ$"Í®QæıÓ¿=¹ŒõÒo—LÂ…]>¼£¹Pİ¡—z#o^t?gk&ç:ÄUgÙÁ—†ü÷b ç(d#!{&Gİpvt {ÜŠ|64mÊ½ıšàüt´ @ÊâfTÁÛ
®&_,;Ö*%‘ µI7&&ÄoªÒà	¦	)¨ÁãœˆAÀ¥Ñ¶º´YÄ–q‹½É‚KÛ#İÙÅEœ­¼º!şO¢éf®“rÖüËÏØg_ıEĞ‡“2Q¬»`ÒXï8k›4ğÓ¨ÓBPxÜjö;É9Û˜)Âºc%ÏÕM¦ñè3ÏÉ'!¥·(”«Ê6’øÔ~uøŸt)=Ê„‹
™.fşƒ*ƒéIæƒÇ™"ñ]D#£/E	ásª
Aiasİ+Öûk›(p®Lù û	Ş±9Ôgk&NıjôxŞÄÊğ=˜Ï=¯—Vñmñ$;dn„$ŸéÂİÀ}ÚLb¬€ ò7è_ZÉº¿®º¨IĞšd–×˜j,kœ•,×ö©êoU—ë;W¥ü¯™úò'_#EÅíŸ¢U™ £Ò°¦ i?öß|¬‹]H‘Åf¹¸êxPpaM—ğ4v{;lş)ûÉí×Ìà‡·Õ¡jgeT53Hï"™ÔäU'kÄŠ¥c¦ØEŸ¢ï+íb;Œ›¸R­ô4ÅZ¬0‰¤ ËLÄB¬ûd²e"PÕ]lO…7pÖFòæ§¦›·æÑzÿO›4ì(]qW\dšVÔ³ØÌŠívÓ“=q]8F^‚õ„ãw?¡a›ƒt_;°l”+Ğq*À³OÄR	X{"hÆq®y^¼¿ƒÜ,,îÔ–‡øÔ-"´[ŒÈ%xPº\ØyH3&K_œA;÷ñR¦¶‡+öúVà{À¸íôväLˆ{gœQŞŒ9+$feô»¬]ŞâÓC„óì,äKxí:z„ÜŞîÊsÖlä]ÙĞÖ	³ï5aäÆ—–C
è[(;å`mª°u–‰ïØ˜ğ(¯	ô×ù‰¡³Ü½#ÿg…o~ói=ÆÂoÕæé[ F9Öª(´ãX®ŞlÌ›@û\?D…ë¿4c|i§õøZ2üæ¨mpô-«ÀÎÁÇ‚€­ršF÷ê€Íj²nïhüà$}20«<¿p«È_Dµö•y*¡	$
ªÿğç=DÔz§'hÍˆ5Ò¤YšöA¯<:•3…æl‡şpÓÌ„Rê°¬Êñè,´d–ˆö6|3"õ|aÂ&8ªÕKú`È½ôíë³İµéİ§µcè¢GX:3’W„†¹5]n½„‰ªXüÎ¢iÂ†!öèÅáBXné÷éùÖEJ…ºü"sŒuXE%îŞÌi%>n&á¾mJ®Æ9a×¥IòE!›¦ytÍN÷Ã|°&•¥3tcZÁç'Šmáßˆ^Í1šª†ÿtØï8oÒ¯“üôı±õ  å'í—Eœn/è¡ßöNf=¢K˜ã‰ís0ñšÑò@ÂF/¶µş²&]óé0Vp?‹º²á3=ÙgßMoY’Õ#|N1F%®‹-{{ŒÅp
uHèïr‹Pf.afeo·$ŠLéIªVµ#{PHu{±°0/âP-ŒñYR6óĞobª–ÃìĞî#Ÿ‡´!(•?v†áT¨¡hìcêIª°ïio“7ëóY*9º'FâuYD3ÊÃ$ësóTX„†dã¦Ka<óòK¡ç(ä+Lö!-«­`|›ó+'æÂ.Å‡`ée‰é‚}ñ¸š–µfï+sîZÆúÕ(I˜kãlE1böÅî…â"†¦ît”¯\p[æVæ´dÈ›-gÒb®E£ïé,ËÂË\ùqpš‹ß%KªüP6Z ¤Ëøñ³EÓ*9“="O_òòºMtÙŒKÄŒl—k('İ¼™ƒÍÖÎh[²Œƒ†£G¤È(Ø7²ğÆøŒÓ1—dNSæÀ×EÒBÖAû	ÔGâîxâmVŸ;v›è¨?î>æä>ŸÆÎR‚ğH“Èz´I\IÇ5£×ş£	ÉÙèî‡ÉïÆô@¶ñ³ÔÄ4@ÔŸÔÁ?}¿"í18gjŸe™İ.Ûô”'Ü“°Øÿ«­Ã‚‰‹%—¨ş2ÔÈÄS^™¾é/¢
!Ô²};ú…Ò¨o,sÁmÈ¼Ml˜}½÷»’µCLÌOm}õœ”ÔŒo`	òÅP°q/€˜wÂøı¾D‚™aÛFÒT´ÇoTú{³•´½Œj?A×+ûÊ´qÑçzH¤h Ğ’…óÒÂ~{w*s!…-ûä¹¾ÉMñ›÷>z¥—ç“‘ÑCù^Väş[LGVï×¤EYÑY¦O·±<’í	œlgvgÂé~a$á(HÂŒCn‡äÙÒ¾ÊˆÏÛª¾ó8	Î¸Dk_HkòH^ìŠœDR Fıü˜Úéü»ĞØl°ô0N#ƒ×îìwPÌø­Ö‘^ÈØoñ¿Z:|îewA¦Æ¬}†šOŸYé%N	ê'M^iÊ®-¾&ë{ô­Ñ/MÕVÿ¿Ú–eiô`]Ã^,-‚FåıUÚYŸ…6eéye(¢Æ»Wz»q#[}M–o«c>²+ÛtcÌq•9¹Û$Ú:ÛŞÀEh.‰Iá`îÄ•ƒï
óB}#SšM¼“ŠçvZ–d¡×ù)vkè¶%È‰İe:©¼-èñ¢ †UÎ
åêˆİ\ÂX÷ZØ1ìjb4ObL~Uô³VeÊÇÇ\Ö°55´ïiÛ-!t¶ßÙE_o„UyZ¸D™¸~°ˆ¶ÇÏFX¼œAPäç*àÖgÚ)Ÿ×€ÊÍ¨™ÏTYìÄ¼uìtk`<gƒR™ÊTÈLVHä³Ut^×³GßÁJ©.!ç²®(3ü$j‰SB™´+ŠSº›TÉÈùW ğğ ‹èŸÃ¤Üxù<*Û
v·;´Å»;¿Ø*üK!Q¯«‘ˆe‘ÎYû í œJŸC^sâxø¾AÕû:Ÿ¬MBŸ¿7W’ŠpcŞÒ)àG¾iäÄ8™Úˆ›×†¥¥%¤ò’Âdlëqp¹´MgDÎWªŠR,	„\u~K"´y·İVNz:¨t‘8±`Ş“šŞ>cõÎe_Ì8 3'Ë)’€“–Vs<£Ow…á9AAÅ¾æeÖæÄÂ¹¶ºó{%T¸`<“/»ÍLÑiëH;fÛ­È§àß¥¼şD‚oú|ğ±…hœÙM—§áñí ONRdiFbÁ“²ÌÚLØ:LBÚ<_¶œ šñá×¹QÕÍ­ S4š_õŸ Jfå¾d5ÖX1!^?Ë´=4;špÓˆšş¬g±”óÎïŞ÷"µÖS1gÇ>\R”e†ı>
Ì1“_5¢Á—-BqíË=Ì46VQ¬}Ô<PÀ2ªÑT0(Ê¦ÃŸ+6kbj,¶ñ´–RRû@“ï²¿…s¡ûKÜç&Ø4_eä—`¥ róï$×åt9¦˜÷Í<Y?.¹ºŒİ´0ë}c/“`/û/¸¼¸W˜ÿb'À”|g _íˆ±,7Œò4©)kşU.ûã£)cöp@¬hÛûi£P~jÁì¶úì@°Úó …S¯ß™Ú,’}scíŒbµ×ºŠ$ß‹h„ØÅêÛ›…íÁÜ‡šÆPÈA«i­Òˆ–h€ºu:V™m¢¿e[&RÌ‘‚¡éÀ3¶½÷
¯”uÔ‚e’²*@…üDZlõe¿0Î4‹FSÑ®•Ì_\PÉp€Rş“~â‰6!Ú-Ae]ŠlÒàà‡ŞŒ@f°,ÃëUi´C¢š`€ A¦Ñ«Õ’
İš–yTM[ˆ"\¬VCü«ê	I<Öƒõè+4PÕÖ¾ïÕî8³ùÜ}Ÿ›¼«µ²®ºã&©U §¯¤§¿İb[‰«İëwÏ¬ª¥ÉÈàÖI¼êÅ¾ihÆE‚
q¬Ç…w‚}<\Ø5«¬„Õ60)-Ù¢b3–lCô¶ u¯@µßşÜÛ`ãôÇ( åa3›dE•¥î6ä¹JMUÖ@ú­0²@;%b§¾í¸æ›0¾£a7 Fj¨t9Oş`ÇV ©6º€cŞQıÃ€î©•’s(_]ğ¯CF±)°5F”º/UÚt „ÈbÁ²À\2]<_`v‡‹Ôr×7í°¼ƒ”#ƒ‰û*R=§)T‹0)*’Ñ½&Ï!şG§ˆ±7|–Ö4‹Q±9¦MOßmJBŒ2,;Óa.uÁÇš>vD[F$VÕÊJÊ7| ¢Ã*Ôib.Ê$Óûûï|
2ãuC$vıs¹­w×Öy¡ÃBÔÏâ‘åwÜÖ6“½|P(’·ç!åÕˆåˆX’*Ót™„½<"Gù#òÅVÄÍîLÛ’ÔÇÒkm©2Ë$Ó)×$?Š#ZÌXr¯«ŠµÓº;[KwTyè$/'Æd·OV=P5	‹˜ÃÁ´ec£Kó’LIÄG·ßnyæ%“{,¢5¦ S;üÌÅ/j’ÁG[^Š®ß(½vÄ ŸÿiáOºÕØµ²2zYßkj˜Æw:2"£gç<mÆñæŸ4%°Ó®-q÷A„ë]34Û•.÷š6C2-BÊË]:ÒyK©Y®œT;k%¹‰4s<âC“m/C¥HÌWztR-}.Í±Ä"Èeek¢¡$KPå‹ÆXÍ»ÅÖŞGi–İ¶Ÿ?ôu+,
+Ü1€²{èºß»[ÂĞ	$çq$™ïtY…GÌàAqô²şcU1äR²u)Í{²{‹}-™BAŠ-P Û,§@²HÉX—dÇV¿G—Ä1C%¿åú84Q–ËV.i„×9¦cEZEŸµòï&•áI@ùŒ“Ğ9äÿ—]Bk3v•úsãûìÁª¸¾÷§€l1a*ÿJÅ2¯¯Ä`UTioØÈSUÀQE—›QŸò¯Êú­G³í3«?E¡èvµ—BqV¢@¥<$,™¿×p{¬âÀşâ§}İ0b4:4$é™KÓOõ EêÃ?tPâB¦‡Ø§Ì×iz!L)‰dwƒduˆ‡í¦€fûÖ+×„Ï6÷=O×—”¸F™Èä:Eç_^›Oëui‰h{ËXµü„ò{¢Õ«p˜o¹gÄ\7ñı²/¾.óµ—sì+}XQj¯úÃİ…Ğ="í›¥\‰S0%CÑ`êöÆC™·Ûü$jS‹	«ŒA–Ñ]”ørå£<•násT‚ùÔüSå\­lp’dGd—0‚ö:õ´öô¬;‚™ß6Ji-jÄ/lL,óÃwDDIøVLº ğ¶4%ú>iõNEûù4¡Ë÷·M9`áõ’¶¦J›CÑrWä"×t©ß/¢¦`W-ãQ¢°ñúp¿5õÎ¥‰@¢d¬"G /@p™´dÛ!Ç¹îuäÄâ(<µÒçååRÁÇ£µº5Lùï9?]ƒrB.©¹J%*N—»û&~ß!ëŠØ‘ü¢ñmXôŸ´\J}&c“QşÅr<…ÌuI?dÅº_#9ÿu|y}§§Ì”ºï'XÖ‚{uÌ&<ºVµ¼¢rbÒ•ÿí>? £Xqò ’eéC.òO#EÄ†<h•g_Á™åœgùÁš#é-±!¯~í–Ô|Wwd¹úRl)öëı3¹7Œr¦k-Ùÿ‹xn9‘¸ ×ƒ†UˆTz'4ÏwÜã;ó4c?»†ïnƒ[EÁ»¤jÄxëŠàİùpN!3ü˜#ÇnÇCî!Æg£ú¤ÛOæŒFà£V\WS ú»Xê»@¶Ûn…™èÎß˜kT"Ñ$0MØ¬&fx¡hñ¨ás‡ôVc ÕÔ@wçZ=Àà ®<ös/XÌk%6F’ø5oÓX©Ë9ÅÍA0¡ítâëÌ€Æ”#Ö£Å–¼Èy½º 28ÏÌ[ş":
İ"z÷î$ ¤ùö««[—¢¦íNMKÊ»qÏÎë.ıÁ ¢™şH…:Çôä× «]¨fEŸç5Ó™S–£Eûı*•-^ò£Xæ>BÊ{—˜s;£ÛQˆŞÒB¤‘Ø\MÈŸæ×Ñv!ÈZˆ›Z;–×nëYÉÓ+„_`ıøE{ÖëÎù³käC2*—ğñİÎ<tPVÀ%Jø©Ò’n¤²ã³ÎÍÈ#ˆ–òãNe]§µ%ºíåŠ!Ï•òúêS.–ËÃnªğdZs—ˆcK&|ªäÙ"Éã\É%RÖ¥ïØ8å5ù¯Pî>ÚÇ£?úÖ*¼½4£DåÿøÒM˜$î”å.*†Ò¾“¶˜L²øZÌ\DqªPR¸—VÇ?ÀE[æJØ6µ W×MŒhRÅlú Š®Qm aßJ_oh'å]Îˆ©:?(µRè•Ånv%²ÚWÕ‚ÔH¶-|) 'T¾¬¬FKŸîãÁkûŞ=-ßgN2MÖá¤xr‚à[ºoVÛ+AÛ|NMtk•šI·'<·PNÍS›şüùJÕ‚{¡¬ïP­ì­u7?şK^=ğ€s¬iÈôÄïşN²T¥Cø9Ë›¤Ãà	E¢ „T`¡Pó¢ `ÍTPK›­p_({vÕ!H?µ¢€;5±%U®qòÓ$%7ôfğ/n
2ëãè|KtÒ’ºÕk—¦oö<üz&Ã5Hª»CÂ³¨êjHUÔı²şxÃ†Š®=ì;!è<U›Ù;Ñ9Ô¥f(T˜!¥\˜2K¾‰
ÒMTØ@"%h}íŠ°­ d‡ú&vßüşâ/TşiÙ¥äó.)Š€¾W	€­ƒIÂHGO;U0åLôz­ä°ïŸ-ã¦¬şò¹‰ßÉØø²°Ä‚×:6l¼>k±à®Måhæ,™3øŞç	f…œIİ‡YŸ|û“ÆUÖŠ…2ß†¢ÿê1ÉáôÌŞ}‚Oªğ,ß"5Ò¹/¶¦5Uµ%‡ïÓ¼è„¤¸óJsëŸßAŞÕİÍ{‡o çmäœi7üRøw¤Ö€B(£LÌ?t&O$‰óQ“_(I˜R™ëá‘=ÇO­åÅÍşÑe¦Ö9³Ó F[Q¢\4]…o÷¶»ˆg¿d/ìÛ“m)QXªD×ãì +T‹¶`&±¼¹'\·²Æùw‚">NäÂ›ìŠ´À¥»ÃTúïè+j=½éYK?|öÜ•¼cnF½ßß¤§øƒ:[1™VI/ ™,jğ¹9‹³&ßŠ£82¶±!¦ç7ÄÜƒjU£ñ^Àv_hOWÖÏ1wf¦u+vİU0œ¼¥Ìük"­¹÷¼¼èûUŸé›—â„Ñ¬ÚmE½õkù(—Úâ£Ïrq¡çèFLÉa‘ñº{ ~œ@z†[“,xtGÖqğš<V‹@â[ŞˆşØÓ56<V
ÁBv5Îw»e{1M`F×P(„~ÌôEûfäÅE&ÈlFÚö–ˆs"ï¦bcˆ®‡‰ô“ãg^åøpuÖ!şk7¬fwGîH.–B‚áö“†lv;Ş(P¶rú÷÷j\¢üË æï«Hy*ßw²QgÈ#å=³
1(_=F(Ï5~BKP~q+i»æ±Õ{Ü”ôÖê¥.!_]şÃ¢(Ü'T·WÉ æÁ4ƒrŸ0AW†WÏäKjŸÚ™÷êÊuÒv<M´ĞÀ¿²8áN¼èF¶ša]ñ¸“Bxß&ücÄdñê«³à{ÆÜ?º2Øõ“‹:]*E€Û,€×Ï“éW•˜Ú“c€|îo‰­Ïvïb‘ë¤ã2Ñ˜‰·z),DÈò<—´,Çñ§˜ùömøˆ ™4‡ÄÍ¿M¡o‰KÆ2yæn:IÃ'îİØà'&N‹¿1#¥°yG¤Â”w]c²—Jå›R/
7YËdÑÌu£„GyÂ¶Vh>­ÅœZJíyñŸ½E*#áQ_Â’ÎØµ©F¨®m-Ó®6Ş[—d­:âzW±»Zñ:)HTõ:g½?D÷_‡=k1Ú>øA5BŸ5¸„äÎÓD|ÕØEš.:Ã1ZŸè}„œ63;F§’B©š’Û¿²8Àh/n7åÔ+–:¡šwÊÚÿ9Óı¿ù\ĞoÀ‰9…£x¤*
¶*µåÏ°|³Qñ*ÛkVag8ßCg˜©y¢Ê¡œ² &cy#`ÜöäKe<v×n“Q%œ.ioÚOÜ8ıÀXPY9µ•A÷™ÿúèK*qä%(Íµaâ!“§·XX¯EY°Œ˜ ô), Ø¥}Æü¢ÍAEuÌFm|<t‡sc^®Üƒ±l664£zëyağ4Õ=l¢!”hDÜ–:Ru”+Úá›1bı&åÈQ„¥EóÅ¿WÉÓ M¬:Ğ
±õ˜¹ÈĞ•ñZkÏÇØb”ëqS:Ev«ä¨ù— h!¸è½¨FOt|H¹ñCò"/=),Tüz™ØcÂü™·•GÃ¶n¯*]K[7(×ÏQÑ’¹Mj¸ÍBú9F÷iùl\YÂçS¼oì?ü§/CÜåV&u £›sXÆ'Û×L²—Ütë)ùfhIë)„A.pg“¬;-ŒôO«Ór|Ò™A—Š=m¿òwI\­çÉ^×¢j½ßtÀ6fÎ_¢ü¥¨Ïš!‚i´—kZ†" *¤öØûñ(?ŸÿÆ!Ë1ë¶§ïvCŒwã¡÷Dˆ£æ–¿¨ghnÒJ
á©ğÌ…·Ù“¶Eîè•¹8°×<*‡Š@çXGŒŒã¯(H»ß#=Ì éÚ5*2­Ë©n°yÃ¬¸Zï£·jF†bMèJl¦¬|
â]³)s—C·ÿX×ı¼›¤¸W™µ;ƒ+jHRÛÏêç±Y+â{ıËÏ8=˜j2O%õJ˜# \ùTïìŸâpŞˆ×9;iäé0.9tÁAhùæ%S}¬ì×ÄıÈ–¯¾¶ÁÅ—·õó!:ŠNàJGN{”ÃlÉâ»í0^ğ†TåJr!G‹Gö~4<3D8B×‘ıX&¾{ä]U˜å³Bİğ¶:G-Tü…µìÜ9=6 u,[Wªàší¡ãi‘„Çù ùBÚøM¶ÿô"ç“L”|\ë¬Ó…e%äŒ@µàõ‘#âÑ46C%úZ½g€Cg²J4c½¯§rù¦»IN5ª·şÉŞ©.‘ƒİ|BJÚ°#möÚ5DGcxÛçb<Cgc.ûU´à|k‚gqÂì3 "zv>Â™¬Â}ÖöƒÒ÷«±ÍƒÎ[;ä¡ò±i=u‚,èè×TÊã0Øƒ-Ú‡¹‰ZÛ«ÃÓÿÓìÒ¤Ï2-bYRëÿ5¥Úş#Æ™¸¿¿%ë,Zò‹;ÒqÛØK*´Ÿw_µÂ-¹%áH¥D}ñ8æë„Rq AŸ¸%55L0²6{Ó¥µ!\9HZãT©o–S@Y(¼Ú8i"d3%’(Sø­âSŞùwÌ©­¥Ñf&>ÚÀa!1Ÿ’ÚÇTMKÒ+ _Re»©*rwöC¯Aìô»YD-=3`ï_,L†œy“»Ü´T„âè‘ì+VLjâŸ©RBFn/KÛzó«¬ğüòiÄª{©â«U5¢hÿëJ©¢ôFyã?Ïd@	¿ñÅ–S;Ï|“²d ş—§ZÉĞ™2,7]ÀIgµé#ÄU£ïÊ5Ì"å$@$âqTUú ßÑs}¹æ¬4-€}JÎ¶»Çº6&è;‰ı‰Ù/S!¯èõåãÍ84;¢I£¶ù¯q*mg<åHbS®2štGß#íôS^&r'¿Ã&·dÊ-Íòëÿ#Ãì¬HšÑæ\hÇÌáàÜ1L±T›ÂõyfÓ‡fâmfuJO"T Ìr‚Å| F2Á^É°´6Pu‹Ùù<«=³£]ŞAj™©ço;Î„QYä)ê\ù#Í(G¶ŒlB]ÖÊ	©§¸‚›`uGmFŠ­è^¡×ü@Ïá^oœê‚çàş+¶añ$LÍÿN(¼B8ş	j‚Çñ³SÕ¹("7LœyUq0êß¢e¼F†8wa¸çõfQ¸„d–ŸnÏÒ™êx7vÎ•n)Çg°ØôõÉŞ8˜Uj6z8/­üÏ1{¹òyÒzñ@È­Hyt…Ã —µf0OÇ;lÏquÕ¶±~AÜ0€jSïèzœm˜¥Å¤œ&Ôz¥:³…ÁĞê“7Û¬)¥#ó9³?‚BêXkä+^e¿yÊ»ø@Xï8wY|U=¥¼Ê–+J½ÔãÖ™í°Æò¦Mä
½_á›y¹İ1æ]C8,ï:{¿N†VÀ±²ïìB__ü¨)³“µÑ™*Ç¾4Bğ-ZY­Ú|e>Ä•5m&e	`¡¿”„”‘•Shm†ĞÆOã×[ªäıŠ/%îh?`ªIFm) ]^†¾¾’~ËÏ%Ñ¥|EŸ¶Ÿ]ı)º¦ówÔÍ©Ušô‘hÚ 2™³0*\^
5|3qà³<åFS©ÿLù$^põŸ$AJrÄzøƒ»Ø“ûs°ÂNÖo‰6]µÚÉqòƒ¯d/œ˜¦ô^†2é:X«„ê8¦¶r¼ÔÙ¾V^ytrÜ¹PDv<ĞúwÔ¤lHøtjìäP1v,I>¹ ªñæ£šß¯­Ú×¼I¯âæßğáÂóì º}TîÉ¸Eæ+¹ "?>P’½–ÂŞbÚ…ĞˆëM5°#íhé¥ö/&÷U·1Ú9‹–"ü¨¶ı5¯µ¼^$ìDü›n‰Ví <[8mFF†æS§²DjÖ¿ñ¿83ªŒÿ˜iYK”OrœÎÏ.˜mC$ásæ€[·0â/˜-¼›Oãò)|³48z#
W ¦»CY„C0 T#ü#ÙwÿÅXy¡îQ¡óXĞŒ ._ãDjd€ÁCEÏVıp€XÈ0íÓZòO\øC.wùoÖ’üéZqšÅ ¢Ä#2©e·>äğ¬…Œ·ö×F+ätÁx5>´ëšÍ+ËÑ“; L:ÒQ¯«:uî
š~úBÑ=ÊoŠª{nÇ¾?máÒd$«†‘ÍuÊ©ÒHïƒª¤¯å e3F–x¬ZÑŠ¬µ^5õgsÄ¼G!¬55{Ÿ\O?çRm¬ÓF[ã6Mdµä…kº¤¦ÈTªÙ5ÒV¢X™xíí',–ÿŠñµ$şWHä}‘'2üXÕcP)Øø<¬‹Ü³Y\Û¼­8TCÇ©…j#d›iÇ¡ğOdñKÏV‡ù6·úÕVüœ(ÓVéÑÙş­VrGCÎ!¢ö´ë¶Š>,N’³ûO¾²v¡*A¯	?wOÍvGŸQbQuùÀç«?9İÖKÌL˜±Ç®³•iUvê™³#(4
ÄĞF|]³ñLQ;ŒåÎÓcÍ·—C›IjğñR&+$VÃ ¦h™˜o€ M¿nmÄ™ÿÓ.s3N¹(…¹à“³AR³¬(ülGæÛ¨ôJøˆèÖ‹t¹K8.s†?Ğ^“	°j%µr@«u±×œg„^€ÏÍñ¸®ÁSĞ½CîÖpcKb­½%(ƒ8]öÆlü5—ŒÃ6UoGL’£óS·Ç5;öQÎLí£+™N«@Ş¤‘ô}†¨=}ú×˜²ãb9“2¤aZK³X}ÙÕˆ ét,(E…ğûKæ¥{{÷4õà0Û ïY®:Q©¦mªª]:‚šiˆ!İS¬¯‰‡>M¯ií± GÇîw¸•ÅP¹æT¦9tÊV×¦~¹	M‚
tÄZ±RĞ7ŒÛH_#ÚÎpô?o|Ñ:™oÚâ£§ËÒ“¤LÖÀ‚LC_‘´ÿÙj‹Ÿn3axsş²V^ŒUùBÓŞaÕlaRdO©ÌÔäï‚›tË‰Cú€O'	Çë­ìJ|àawçäÊ8×N¹¶:Hè“¿BBè½Ï[MÎË*4cøvWŞX7/š«i)™}@uÖ…³wW¡›æ´}ûªdA´óíkÀít\éGÈ“µqK	Ó¶+×_¬ö§ Oì’y;MÅËGK÷ÛşÅ¥Ÿ@Ÿ–sâ?iğªí"Â|€1…ˆm6­ˆ¤–<O’øG(ÿÓù¯•?Ç[¥t©Âè5pÙ¦L0Qç“a)y[j`Dwü(>ËÌ†3*ƒ+p'Ö?j²´Õx÷)d®Â\åíïhVÊüñVêscİ‹Sš’ÆƒúË…[şˆÔ kçJ<*@†´-Õfä‘A|àƒ8 ØegdôÃtFi¡bÍÅé¡²¼|_øı»»sàsFà¼Çp*	›ZÚç¼œã[¤#ÍæºÙCyÅKéßj¯È)ó1C(Ç¶™Gq
Ç[ì&—ß¬İç)5÷guıé¼LÕS¥{èğqyQóèRê•Ã-ƒ¤sd@Ë®fÇ•#ä‘zx*3®Mqsu¶dUr1O8İ¹·Ünªİ–ï!}R~±öíwÉûN5¬å-¢zñLÛ™<[æ'+ág¹P{ÚÀ˜Šÿä› ™ä9*qlƒ+Øª ìCfn3¾0‹tÃ·QĞ€¬XzC?3+Ü×r>ÜM©()8Èô_™²ÍøhiÀíe+ÙáÃæ÷ÿËÉ+‘!Vì‚$—i%ÄS$QÚQÅ¤~_ÚŠ#t°ÿ3uÖn/†etTBl4Y3(ø¯ƒÓ/FäY4^°µÂ%Æİ»nËĞs&™ÆğV%oüOZÚ0V`ı’¬Øäİb\W
Š¥ÛÔÂ–óŠÈ†¿ ó¹~œ¨-R.ü+X‰ÂD|çH áAx¶;¯}=¼XŠ+oå#<)V®ò˜ÃáşµvŞ£îˆ]ı³ÖÓ8İ­ê‚:B«şåØÈËkZ\Hç3å[‡Kx*áfXP%‘1q^x[Í‚Q.¹äî””ÏÂí38¹Ò—pzSâ¦,ú‰~T6IÅ¾•â$sÑQ¬èıˆ]vR±g”Œ¿Q™ğ¸˜öàŠSúÂ0Úûe–~hï“t/ğZï?m"×²cÃğÚä­ÿğ¦,nÑK’¥â;õÅã™ù XYò©înòÊş©7éÓDvÆd^‹^®bÃ1#‘åá¸ g±°wW¡¶¨#2 n&«ıKƒ>ªlpÏn;Ã\)ÿW×TÁ-$ĞIİ¦ˆƒÃqc É»…2™(EÑİÊE âƒÙmDï¶IeŠ‘WA¼ ˜Ó/ÖWö&*ôÍMÑ¾#
*4!ÚMpK¿s†Ì¼’ÓkNÿ|²µê¸øEn\ÜŞ<¯ân¼{•_Û`$JÖ–jœoS\…·É©˜ûU¨v°UÛ$5£!`J¡ÎËZ›’¬½`ÏãÕÆwa‰
#›=}Ém‘°³?q^¹¬Yj/…wÒØŸ'Ç„‚Î[Ş2×Şe•¾È¥-•\×:Õ
K.KğµšVĞê^âVXÄ0\W-`4™Õfj“ñeÉ	UEO4»`ĞvªÅÑŸ…Nıƒ“¡ÅÜ7²èwÇ‡$9l{p0=‰"öB Œ7|~Sëı;l
E/öóõ9t84¡¹oè½ ˆs]Â§0ò>v›ZîOAä:TUÿ‹äô'Õç%[ijòmµÁŸùåLaLêŞùÒx‰®¶»¯GÈoDssj7Ê5´4y®`BuL¡£ß7ÿÂÔéß÷&"Y…Æ¯Éñ+[ÓW]’’vÁY³íİu;©û»,¿şÔ§$Õ32ñ“‡nê>aâ
·Àm Å,‚XŒémS„)ÌS T/¯Ù¥„×Ps/ŒÓpØ º#½Í“õñ¦_p8 +‘’ø¢ërä«¶O)ø¤euDå(ô5zF}GzTÎ®‰È’gÿƒå°@kò^»›ÔiÜ|'1T·¿ğÉ‡Î+½nº
Ixp¨Éåy¯° óæ±+vı­¥ un¬ÜÍâï¶‡úXù…KÏßuz{—’êØè’b¤‹Ô×_Ááa4†ñÑY¸<QÍ,Ó¶|p`ïXû)GéL eUn‡ÁR‡ar¸ùáC9¶,½¡¢Ğö`ˆÔ‰ñŒwUWÑVĞcoå¹eAV+“f;§êY¨œüì°ÁCb9.ï|ğaÚE-6¶'İà­ËqêLCj7_LJ;µÒç"Ü¸~wHµ{XÂì]Ë¤ñ«£Ô’œGQ(sú„2AÜ—›-ƒuZÓè2t¨.rork ÂcP¾Gqh
oÊÑ[Uvw§şÉÈmxş&Î¿¥ò¢Å'ù+2.Ï˜B«u‹YÜSùhˆú„æ[à‘Á¥¨Â5é.ì²ÈúïæUÿ÷éÂj¹ˆeÒLM<)¼:c·]mv›™4Ê»¯Z~G‚Eçqõäë¢p”i¬9¹ÛÒm>B`tÉ³õ&ÚFaÍâ‰ÑÿîOÁÜÄ8¬¼éW¼K°ñ·du´)oø³ûJæ{ƒ0tô]†fŸ+Î¢î¦/¯ŠìoZ‰mC‘­Ê%Öl§ûYœY9Ó$D©Z!Å0êG±ÚÔ³jÔ«¡öQû2VÍ”›bø]¢C˜Sá÷píp§]|„Ô3ÃîXF`ÚMóÑo¹LÀ º`¹»ÓW%ºÙ\¿‘¼y¶Òs†Gu+ªNŞ#AoÇR÷İû
d²£m,Å{j>*±¬.XÖŒ§(çOc„ç|âDpÙ ¶0ÖÏ[»õîƒš&©Ó¹Ì1ŸÃFN}ÎÕ¡ÛJ¤Ã c&Æ’ÿLE'±^NŸ/£JœÚmƒo»äÕH{ºaßæU+.ıÄ‘Ø‹ğÍÎ‚.Àá‚œÍÛA^¸ísÕã,?”õ}Ö/`ùh»];”ï	YÔÒØ³š¯)cøò˜Y-‹aşˆÎNSõ«@‰¿G!ö®ŒÃp0­*j¼ª³ÔjŒc¹J¿pjaÆm¥pûC”ö/¼™FMßv9btó‰}sÑ‚_ÙXSŸ“9¶ûÜÍÌƒÕ«nßˆUÿ×ñ”0ïZhò'ù&¾à\· ÔËâæMËšæÕU®#xKÃÿ‹ î¸Ãô”ë¼×Àñ†Æ3d%…èo¾:œùø(½DGB´œpO2, á´hìÙ:¦Akê¹¦ê£LX˜>õ «tˆ%5ŸrÜƒ˜9JÑ¢wRl¸Ú8?¼²âŞé¢_©
ĞòÁä›•÷ÍÁM$òç3œåcn{>1½BÌìÎµ»k7E0.€É˜flˆ®­î÷•K\Ïğ85®íZ©wË)) ğ˜Ó¡" µ£óñ¡&µ¢hÌwzG)9·9O_Ä´÷–Œ#0%ÚTû–‚Pü&W”{¦Şí•Nå.µgr>^+ÁÄˆ¿EEÌ.¹Úé¾Îçu¡KŞØHÚ*tüñç–ÆË›=½ow¾
RB<¬nL÷c¯<2ª®ÀÅXËûïŞŞ+÷wYj‰\z«1ÒìTµx,vRÒ”­Ó±»ˆ•ì~íÂbô¼^âf28½§È6#IÔíï²ÒäÃí¿×½˜ÿ<cëÌŞ3¶ïIm„ÊÚ­ g‰º¼@ÃFÖ«ˆï¶P7½£?ª&nõZû/WÑ‹3šJÔ÷Tù…:!_rçæL3[Gî¡‘
UìŠ0ş& ŒV_¼ ùy·:"º´b? æû&tØ¼C™¥ßÒ¹=1ö¯A¸ÂçKŒ.){ç=tÜBx8Ašîİé¼»í°UNˆ·xŸ÷A)b™ÏTíWQö“–E¥:	->cfˆ`B­„ó¬@é¨±u©Ù"€¿İ]ö³Œ'Ú²¦âŒáæìj;ÂÈZÒ)dâZ‰Od|­˜ŸFJ¢²o‘š½	×¦¢ØÍİU±İx!™A­w½´}"‘–	÷|?°ı3vgÅ$‡H|Œ,õËK	äx#™¢ºšıs\Î×‚À£À`ñÖl,%D`uïø$­Ÿ™=ÌèÀx-kZÉ4œık<Ò}\@ˆöıµL‡Hê7„È?zh«"ıÆ5c=ŞkúV™>‰!PKNÄM©
>Ú±š6ø1C1ø$ÑµsHsôàS—yoøoÜ6µGÚë /Y4cC¶p¢%0€ËuçÅy¶”¥¼™Œ–11ë‘béWI¦WÑáJÀÀñg¹Vté-[0u2„g[Ñ¤à#ôÈ×Ëà,½İ?_å´(~ˆ·’ğ–å_»-ŒùÚ¢;f]§ÔP¼TŞ‹á>.Èxn¾‹¶›YÉÛÔ»[ï«ÍŠØk&"–Y?…9}É%d&L9g¸Š=8¨S±e¿ ü»Aáê©U½ ¿/ú/~şi«ôå¶pÁÂ/£øÅñŠ¤îË8ÌÓ¢]p‹ğ}‰Rlg åZ/İ`]nàUltıªÑÎar‘ıù6#w0ı‡.§ˆÙÉójÖ àô7¸«¸E5Èf ÒGp«|-V‹Ÿ"ë@x.Õ›rTî7È‰KZØx Ïƒè·—04s…İ`n™Aş/ÈÌ‹ÃÓ¡–‹ñ`ıÃ¹f'„K‘tÒ)iÙx`'İyOVÇ	µ˜µx=ÓùJŞöJÇÊÀ\ÈR¿Ây :wéˆHQç»k‚eëd©–Ó	»cmn	u†‹gâfpR±ğ.Q¹8ı‘cüµï–YwƒrPö1¥cÃ,Œù%o6“3m=w™¶FMÔ_0g7›‘ÈvÛ1J€ï…Ò¾añ”Öm+Ø ÈŞO²LÖÖ”§ŞÛğ:/7Âœ-¬-MWú“øÜÏî/8ïAÇßª4˜™ƒW*¸„ÜÊâ¤èÛĞK´‹¯]M˜Dş\o?5ãĞN
Z†y>ıãBã=¯Z‚ÒìSe¿pû¡N/pNp¢éõåAk>š<¼!õ>èºUÎ²‹%éöÃªèÙå'YŸ–ó]ş@Àÿ>]*›oâ8õ±—{¶U$ÈËX³±hœD/«U~”ÁRëÂ#˜"4´-l¡¥°‘Ô&®1ZÄÜ?»Tš"‹Rb‰äé2±M`"~F1Q¥ßê‰Ò±0JCU`ñI]&3ù:j)é ’nh€¥Ë5˜à¤G¸Ÿ	[÷Bµq„Ñv‚UŠjÃ¯< \áZp†`÷–±kçÆ„z7ËÍr¼!V9o*(Ciìd"ˆU§Œ$—^ÈÀÄğIªó@Å û¤h€í·Ä®÷¿sœÔ¢ö­œòÒ%'÷|7WqB»‰kx¹µßmÉòh>VW£$N0Ïø¹>à4:ßØŸw`y‚s°]! E]ıy¾'z\µÏ'Ğz3«ÃJ4o¢+o>üë36­8¿”¼CnI)¯U!’¤cVÇü¾”4rÇÇÕ[òpXˆøkŠÊËiÁÄSçÜ§ğ4™®¡]n5ÏÓÔ¿_Z´/±hÀN|‚ı[ºê•2-(lX•‘¼ƒËšÀ&M‡…û-#„î5â mÙ ¤5Ö/kI³CÄÍ{a·ˆƒvYš®¶P/
=ğ=6,Yµ‡}ø¿=IÄL@ˆ =Ñ¼Æ?…Ò¨o§7ÃŠ-`$¸w›ûüÆ’Êì­mÿïYiOºâñùÉ(5è²Ï”Ÿ |PwÃMÙ1º"3…Fb×ê¹L|z—Û’é7±f§n^«Â¥Iš°6Pg–e{ù d8Æn?ñÑYwÈü‹*l‡,U¬µØ†` f]¼ßy†QZAB"išåyÿô:÷ş9}R++I“A)heS‚gİÛB’ı	Q	Êk?Xä”6ï`™òV,¢rÍµçæÀZ8KË‡®İ+¨€P]óƒÓ'öSTuZçâøvíÅ•Š°† Ò&=q²]jZ#tNÅéÃx†Rì|¿fXÍæi„ UÙ%ğñ«]êûîU1˜ßí[Ãáá¹o4_Æ¾.K@|0¯¦$«jÕ/:÷iıÊ%e3»¢¿¾E3(µ‘€ 5|ˆ9¢«/™úb½QÃ¨êÙ[wj½<W¾ÿûÖŠ¨Ÿ¼#aâfÔø ±™êğ/ÛŠò†´$anT“~È4'¤;š`×EÄB"±yb“*÷‚Í=©ëHÄµØ÷Á}3±¹…«ï¸`5AË¹|PdE[ã³S;miÊ	ViŠH!Gzeaˆ9)ôG{Rt;¸ ë$«5»ù¢9ÔÛşñ|×œm[ÿ»$æO ÿb€ğ,
©§¡Æöã{¡Qş
¸’ãFÙ õä®·z«¼´ã¾ÇøEáp/¡F‹Xh'#¬éÌÑäŞ$„½bvbwÉŞà×KïSGşïzš‘Î`åÉvßM_“8pTÚÇWMÀ:Ú8ç¥C“Ìáy©?k?‰aN’Që¾äçõç×Æ›Äu—#æ°Z·öC÷>‰ O»èOrA.OşõëX€ú¯â ÒhˆVgçÊSR}á’UvzBp¥«E´ì’»v‡‡ıXÀVC‰y	3]ô’1ò\Ûjì¯`Ôøhh¦ÙW®÷ÌaìĞ+H#Z}¯şg˜‚ÍÈ”³	¡æ Ew– „dÄİ]ø@âú‘âq1‹æÃ¶6¶îñE±²_€>VÄ']v}öÕïSAzUª O°x¨µğgÚ˜*k«®­aãzT1i¯p@ğlZ/?›ÿYhØ!ùëˆ¶Ò@G‰K©Wûû9ä!²Æ=jÅ¸œ¸UHéŸ‹Äş«F{çyª¢Ù>n'¢q©âº
û.±-*çö`®ğÔ˜˜éUøÏ|Aı¢+]´µ<•ÌÆÃÈµ©üæœ+u`g
fûøúD |•#t¶æ¼wüúşòƒnû& yHœÖâ»[äyğ9æx1[Vá3iºZñ$Rœ~“ïç¹R-_0 }Ì{¼ÔÛJ~Ú\éÒúÄÈÆetO À¸kÄmÊ5ub–fá²Xz™¡†smI5„ô<ôôEQN@:—õŠ×Lx½
^Êõ˜Ø=<Êğ»`Yòï¤Õq·<wxgB8ÉµÅèCA,[¾³40Õ„£÷¤}çÿ.S¡™^4LşböÑ ®ZÌáŠwV¤÷<¹ÍÏ½®½ˆ¡\Ü=şîĞCº" Ğ
¦hw—/ÛáË1Â?6Õ"ß4õ]El+$ÁÈH7¡ˆD´±(tüJÑ)Qrê{‘É¥ ŞqÉëÁúvÅ;i…ßi9|ş·S’!à<1šMùÈN±›@jã	Y´mG¢ö€LŠ ùJs•³Ë9(H(agÄãqåp¥;!(#1ä5˜ÄGöWı:qêæœĞ3©yR†ó&ÁJ#ª=/£	íñ—
@Xe½ØŒâp £“IÔû|°Bùä¤`c·¶¬ŒM½‡’;kƒ„¯„Ì•Ô!$™sº¼/%£ç¿Ék÷e¸e
Tš<²8Jç(ÜÕbßŠbŒô (ÆH f€sÎGÔ‹0®(lc¬¼iÉİŞìfì,z÷SÌ³V%,F0[”\¹¼(Æ%bÅ3>YÇsGÀ Të‹k†Š°ÃÒ½r…„óêûºÁ£eF:İ33ß!âXdd‘‹©TzsÛañæË¥Ğm NNljÆÍ'¿|ê<Nè@°â4%b«3¹$Íwø'æ	úÏ¤àic{ËãYàZÏyoŒRç™«a€Q¡8ç.?Ä¦N6ï£{êI/Ü&sútq£îÇìçÄ_Â aj·Ntcóv«Ø0p¡b·kpów9çHK9l&A³Ë¤½T|º$èÔ¸ñRùÍXx"¶–@(k<Ëb›™:Øc²4`Ú#¬q]âé ¿'*$‚üŠñ[ú©äeaÌ‡!âÅ0RC¤±À¸¨F®èæİq¢›UÕ‚~´øÊKÓ@ıÃî¥  ›˜¬Év?+ÉvOœÒ„.h¼âŞï?Öí®ã9ãªz¤ğq™µğ’·æ¯«X¯Ï"„U+d6DÙCÓI%À¿h'ß)ø…İfj{wÆ‚hË,Ô*¥dG
¼wáÜƒŞ2{±ƒ•‚vMŠµdPvXºk‘¼»ˆy±‰½(ßrKÁNíísB™—=qª~L\Û.(Åú{9ìV[VtKşª×åê"5ï¼³,¡ô,SôçÊnI;£Ìû8¨V÷á¾¾ŸÄ%l¥÷ç,@Üª:S`=¼<š4G3.Aç1ûAŞ¶4/³ så.·“ÃGÔ[11©
DŠ„¾îâ€!¬>O£§t‡A—ö™íºÜG,O»#‹½G*Ùí¹% äAFH5$±Â€ô´Aß›ÓœÁ®ÍK µ‚.ªu7Ğâ(İ-#kK‘ÂS,}[›uFhıyú}hÂbÉŠHÿ€Š´ı ãéÄ÷Ó
c,q^›í{Ï«~	6Ô%{	ÖåËd9—•;`µ=„Eèí³¶ß[ÑÇ>}P1m'Ûë+××Œ¶\
"—IÕ”c¬‚ê=I¿#Q0y÷£™‘¯µıæü×«´´6¦¿»äE{±¡AÆŠ¶„dN agWú-öS³aÒ’¯¤‡¾ÎÏx°À¤ø/Êw\ˆßV‹èXûI<MôXŒw[)Ïa`>·Ãw‹-)We–#5Ô ª‘™ |ö9•A¼a+x&?…áw–Øk:Æ¸ô£Y¶{2Ã«™®SÃR½¬B2Àoó\ªPà.Şü²OEOx|h‘ôËlI»lL: êÇÁ¥D;ô6*Cßş¹Ğ®ûîtBL!¹·P…’ëˆ¼YnÙ¶-UIYW›¥¢7„ZÕ³ÒóƒnÊ¹¯c£–QKˆÙZÌñt-mS³g‡¡4;2ºÀÏ$gí[12’¿ƒ¤ÕaåÓ‹Ñc¤'¥£?jëê6µÙ[‘q³Tšÿ3½ªÚŸõèß)¬KNâHÅšòEz.¼ÃœíÅStÇéÑyŞáø¾jÏùXm6G€ƒ™*R2A‡mmdåæ]¢{B6V¹‹Òªôìšpß±=ßA‚‰eIr¡´Ym ›ÿ™u©—÷)¼Y³¶°M‘ÛøÚ¶êAgà¹pí¤gwKrÁ8”]ĞƒŞd7ˆàğÕ®ºÎã< (¢Xdšmşh/O‘ÉPÊ¾~Ú›‘Yó\6ı´†î’$•¬7%Kl$$[ä•ï»ñõ›ı.ÙÙ=/uá‚hxxqãÈ?ÑÕ‘$.M³R2¿¤5‰ Âø³§]úU$8¥ØlFUÒ¼å}C¥¯!qgÊc@õxËM•LÑ‡plIğ­İ{¨ÌNOüF4øúÂÃŸåVU²å£İƒv’ü
W}'\å*g2ıºMİR rß­€9×uˆÀÇ³Y¹*YË)!B,@c¹w™Œœ3´SLö´•VûÉŒ·(B6ÌRÅ`2ÉPÂQ"Ûèzf¶AœÕvÇİ ‰?&à6'ğ›Ç¶Ô÷­Å,'úBÊ®›'éïì&Ìf™I;VöóØWkßR¼¦œğª¯xÖíBÕsbb­D¦­1ˆ¯MòFÖ
B»A€oà#PĞ¥¢§+T ‘õğ…K¦5{^Z!1¸eŸã*}OXìUa@D¯é_œ£AääŠ(e…Ñœâ’$Æôjôˆ×Ü£ÉŞÕÛüfç
†¦ŠKSk¬ë³•E„ùt’c©Fƒ[MhÄ0&‚ìÖ–uNF¥&»où©ı‰<,ÿÖŸró”b?ªwÆZï“ÃƒCõÂâ,¥¹:ïh¥c1U1 2y¹b%ìÖ˜q¬×â;) ñÄy€I‰ÊDùïñ"€)² ~}ê'õ¶ğƒ*S¡úÒHóÀËÿÖ;
-Toë0'UFÓå7dİéT÷Í‘J EWÀ"…¹¨ù‰+ğ¹aÜ”sRˆĞ#êÉudÉÇRô½=bÓ:íúßßşò°S¯Ú†&6ıÚ'b^ã¬ù“¿·ÎÓ€ëq¬“×ü¢=Ã:”2÷h­ˆÈàWw—,ÇSPĞ$u,_˜–h><5ï‡•¤Z& ¿¾""|;ë‰¤;ı³n°ÖÛ‡öKXih-¿- ½6@†É‡Š{«Y0´(‰:Ao9¸¦Áw×Ü6Òi4üá]bOÄE~aªI¬¼Š¹…cŒ0:‡aC”ù½İ?$·¹1»Hf¿TĞ"NE:G6x]·ƒÓEÇ:sİµ×êdû*¼PDF¼ÏI)¹Å`é¿Ylv•}½ö#Q:Á+½Ã÷¡éÂOênİßƒ`WŞÅ¬dÊERf=ü–‹†m’Ó&(ïÚ6Ó¢ıÛD¶uWÄ/-ÏB™Ñ³kÍ<š«…EPÉüìéYŸ”—p!xƒ¦nÚºF±n‰n±±¸î»,à,!@†»¾xÑ/7©M‚µáZ±z•×N+©0­Íñb‹¹ÛBş–^Í&-Aû_^´úÔtzµ~Ô¿Òµ|’éóKûaËd¯0óMVˆlªö_Û1„/·í´´ê_×·Hh?ã•mÅÈØÉî9= £I‡ˆãÒ[]'-Ø-áMŠoLç4éI2™l^Ú8Q|Mkx@9²8o—ëÊdÆDPÿˆÂz†/rÿMÄğ™'pº›äY§5ğº…éÔÜ–aDbÚ˜œ™,úÒE€z&ÚÛ&Ê4rˆ °· Õİè{é]ëêµqòĞÎ´ˆË~\;š,†ì2äVÃßr=Ôûİ1âqæÇ<Á(E‚l1UbW	=€xõ·nƒÃûßİ[³5ô;»A‹ÍÎ5yğ~&x)GÚÛ½Gé½¦ÙòØÜgm¼õ¢PÈÃ^p¥ãã÷<×ãôS!¥áU†ñ…ÛIwı×÷d©Š_Ô wÊYOUÕ
ÍuWÙõ¤bBv`ÚõuïmêgŒò¹î§•™€´ d™ã@2ª<u÷¾´Ìdú«¹m"øN ‘=‡F0 @É,èçr¼ìX¤e<gx­á÷Üf§-œäÒ|eôRh§mÙİòÜ‡i
`0û«H†İÎ™ƒÚ‡0¾un…e‚a¼Eßí­¡
ôqrÆL‚JBÇRì+8Ş	ta4Ü×J¤Ş«èÎ/†
úºl¾Ã‚bĞwOŒ•;¹Np®ç8ÜöCFòbt‡‡)Ì;tø /ÉÅî÷æjíÈg~kHA·¸µî ï6±Åxn-Qğö-gÀÕ4æ¨ò~µ¸fg;‰.„€ÆdERıíƒï»`W¶ıNÓáJ<Š¿#R¬w`{Ù·nw‰¥hØ¥T~|„ŸF>~‚9ƒ4©wš²@}|AìœáÊ
ÁÙ’èÎÆ/3ª”¯¼%ÌÄ6¿ées!é¼^FÉpïC8ò´œÿ‹Uä‹ş´ù›®q•üÙ ©kÈæ>ªØE¥Ş‚¯Y£3—OäØo5h¯š½KPÿi¿•`·»à½ˆÏ‚$eD¤s¼-T'eo>-6{g`Íï!.dÆBG;í¢mÑmBì§jËsP$mHß°!ú¾ô¥àI¶dÜId•p	¢Á3¾{`2†º”&	Çe£EÌÚÓá¹æl’™÷4±-Ü67C¿/ŠšˆZ‰“Ã»¢›–åùñ@V¾<0^ûÄ€“,š¤H÷{ãü'Òğ'm=ñ‰XP[™©ÓÔï¹ğ¯ÜdÇôÜm%;|RÆhF±2†«–$I¢àù‚îÎH'i}ˆ—CÒ-&T'Û¦õØ×Îa¼nc¼VXƒÇBJysSâ(Ó©®Ø"±½FxOğÒ|Ë4å…|Öë²BÑÅ^Üƒß^{¶H× ğ¹˜Ã^Ì»õíë"a…d•¦óÅQå¦¯ˆÿĞ3ò§g¸ı‡~¤•U¼Ï¦)MüSÿ¥¨ëZb(ošÀoPm¯jrƒJ/5sÿOS6ºÚ¹HG²Šœ‚¢v& £+I˜eÓQQRô7Êís¦éù‚€Pwqh·V=]*×“VÃ)Ù¨M­º¯æø·,r·Ô*r yM ‰*¶ÜÌj€¨›ˆçš5kÖk’(‰n§äDHFØnèÛ³O¹Ì•‘'‡ÙK%~a­8j¦ğ¤ürJº¬½€cï|H>U Ï
ÿ`À‡ØÆjöW¿ªj+FşËjĞ³LK›èÖñ¾•¹›0í “ìjß²EÕæ’Sq{´
BÚlät¤¶şŒú€®±T:­3ŸML:¤I†¢}ã4íŒ ùGz¬.Òaé@
ıæÜıM!ò©/x¨Ñ%6šîúr‡x-/ØVè dqÇ‰=‡n#†ü3ÀÌ;y\}TzÍö³È³£“ùÑ÷¶¸âÂ¢ÎXŞå;ˆ°…,¦9ûjÁU?ø™Š3-moˆA~İŒ×T`ëÆÅ–céœ   £1ğ,ú~ô” öÂ€Àj«\Ÿ±Ägû    YZ