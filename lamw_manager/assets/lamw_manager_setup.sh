#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3422579574"
MD5="cd8090136c0c74426b0b3df451b15040"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26012"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 22:23:58 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿeY] ¼}•À1Dd]‡Á›PætİDõ#ãìI„¿†ƒ
=£3’ëyŒƒo™ùŸ¥WãÑİR3<¼şá¿3Sg<;å†/ÈŞçû¹ŠHâËVaHöt1Gã€¢ÃN	üçoßùW‘ôBŒ¤M=^¶2w·jÁsS–­AÍ‘¡a—ñû
Kƒ m¦ºşÕ¯m½>?Èë/“&iÆš€ÿZ)¢ÿ ƒ·Ú`áEG=Ìg9´h°7°gøõğÅËIÏùa¶ÊûVcNßg	<k^^¼s¡¹{¥G¬®j0#`bæ¯«m%ì<ğ–ŞÃ1ãş¼J0ßNQÁB$¿l2PßŞS÷F5â|­ø™\+ê“¬É˜>×¥>$—Ìrk„ ExdVåù³`ê¥!•ìŒBIå?»’Á¨ y*#Ö
‰,™Ê~¦ºÅ’tf3x Ú„{çÍ¾.ÆnáæöC·j]wï‘¦Hå„2ã¯xLÏA#æ“ÃA„İQé~Ğ›ü·Ëë~t±FÍFo·ñ–óß‚ö÷šœØ’ƒñaĞè.~+NÅ¹eã—×sb©2	(?'…ÀØIé•ŒxCBĞcNôn&wİ@‰dzˆ¡Ü)ß
à‹NŠ–r±İ‚É¢>¦ß¹ĞˆÆ.PÏËj¦4óõêHÊQVÚLÃü‹Í8|™‡[gK3d5gªœÌ7ƒ°‚"ƒâK“¨ñxUÆÊŸøÛ?l5:]™µ‡w¦-#@P#òC”ÚØ9g¦xF—eK.^rğTÚ®^œ³b°u?ì¶ƒGJÁmóF±UÏb^âxÕMı€	{×ˆÑçêß–ìL¶OÏÕ	— â–„ä|c¼}Ë¼{lÈ(ÓbÛO"Ú,7á€Šíh  HsY¨NCßJĞ¬¤;ıh<^“Z+¶Ä§N^¤|W-¹O·‘–ç“¦DjsŒ~S¬_JpÌõ'%2iX4Ä 3g”›¼Ñ™ÖâğÇğ¥H4Ê#Î -®:©Æ ÁU
BîêÎ,æ’xµèz~Ñ|œırZb5ÓèĞ¾îeÌ~t5àfJ­şhNIÿœıÙLÜåˆ©ñ®5›â'e€[»X-®5™d¢¶ªØ#ÁRù<DGæÑ¤J=~.Ä›Æ8hîÈö‘t&vĞ+Ù¥‚4Í|`Ó\–š´î°2ş*ÿp^àBo¼Jåv1óŞ‚|O^M¶}ÒzYµ|İQ“õâX›(87çXRx{Ñk‘çT<ÛÒNÀ'åôÊOÿò!´¿Ï•Ó"I6àà$i)­~Z¯9ÙBD¾RU}DBRgÒÒsˆZ¬á(‹)65ğ|6}…ÄvªÃÅ6w1šRó”_t	Lææ¤zìC¼,ô™Ùö1xf.}L‡%«±İ'±ç™éŠ¶/.“ÆüŒÌ·úÿ‘ šEò÷l÷jĞ
[¸XI)Ÿ9¸~:Ê¯C/Šm@ÁeÁi”±+á¸–*ØóSy`—ó®ùè¬Ù$Æ©“
a%ÊÁ‡y²b9–.¼\üî´8y¿ªÀ€ëUñ§[øÖ…¾¹SLG'Ÿõ¸”g´Gg·SµÊµ™CiÃÁ­‡‡xO}[lTo  lº¶£Iz×Ôé¾ÃÎÑjXtÙ4ã;xÔBİãaÏu°‡l‹»f7
µVn`9””c—7ûÔÚxà¨·ÎùòŸuöxÎ.8ü}µ ü/2
¸æ¨ïÊ6Ë_–è¦	<ëËGËzôıNıüî,;lÔ'gƒü¢š`BnëQËïÉ‘F9t€ëÈj¶*ü °J{ P¸ÿ‚ç38ˆ0ĞB*X#ëÄç'‚k„I·<ps‘ª”Û=’­Yë[9~â«/r0MzÇ«>Šÿào¼0j¯ì€Xi)<°s–©Ì¦Š%¾Ô|	Œ¡˜ìQzpım™ÕjÔW;¸Rç7+&OHvÿÁ%±5@ˆ‡‚àwĞÓ9ŠÆÀœ¼ 3ym·âtâ_Ê20[­È šÓîÖÀFÇ²÷d‘¶ÏıŞ~ä£s¬XÚÓ†òÕ;»WF~±„â§ç×Iu¤½w'¶‚¦Ÿ
0WÆŞs^6Ğ˜|3„ªweZVñuÇÿYEŠÁ›”‹æO6¦ô’‚ùÉ¤\
²”k@‚,T“YÎ^8Àşóh#V¶c¬WI[×¹ªÌç¯·!ë @`"H ö<Vª“ÜH»ß¤ç¬Ãra!µ“”‘c?Ş±}Tô¶ÑÔr>Ú˜–?gGœc£æpÓcÏÂ¥<Ó¼‘ˆ£ö¥{áNÖ“g†_˜8!½"¯´ƒi¦TB¹)ùİö_Mäõ“dãÕJë{øwI½U˜Å(håñÏPĞRîËÈ§­™ÒdİÃÖq£ÊÇÒo›Ú˜W}Àú‡ fb½È$Ë¿ò™×á½3Òcë±¬{iä
ÚUç±İm=§w“¼b |™ûI=¸'ô§&Df2pı-iCaŞ.c¢^LYrR`é³BHş‰½A]§İÄ·'tÚA] ¡Å°½™˜¤Ÿ·Nª),©9t«LßÙ9ó¡/%…û’„ê³§ÙÔ|º¾N#Ó¦ÈâeŸÅ©Œ4—Vj§“Õh§¾÷íÂİU•aze3?'hĞëî+Q‹	€%İÁ7¹-qgçñ`k=¾–Ô&³OñHká~ÂGJ‚Ö]†&ß_¾¢Ï¹dE P •iÂ2“§ƒ¡ó+©÷_V­Eëî‡†‘O¬“ZFØìş¡	=½êÂ3Eÿo+1­Gƒ]N´šf–œM#rs÷K§4v.…_Šğ¸mùñ+ºu>x”1uk„›ÊLm¨
f9š’Œ¯‡^TÖ?Pæë¨¬¯İK¿všµ‹ùÁñÏLÕ‰‘¯Ùy^¿—6b1Š&~t6¯|ûÊ>ÊI®ÔlÖ0sìa`†T; Aı“í.Àvÿ­©\áa>N,Õb9õ˜ÊïîÃRxí6aüYø\Ş‡èAÅ‡ÂÃ bTq!ÊĞ
æt¾Š"ãù@•œc'¿’:ğ«dLaÎúØ‹lE‰Ês4+fàï¬
1A&&r25ŒKb³±Ì.W¹§s›·9!ï*šU.$¸_nûÉÓ¶jãÒ–óí5’yBpvTÙìh©ƒúÿU,8³ZnÇ‚ÎM‚1rÃĞ=‡yóäb€» ŸÛô^YšqÿÎ’jY‘Ì
‡‘€éß.V¢¤¤œº´—kÿÇ+Wò¥KšÔQ'F+S³²ı|ê˜#7çoæ7¸$+BÔL©–‚ã½	Œ„ÃL}Üâ¿š–È‰ÒA!µ€”»4cQ»ö-w%¦’÷$…°Ï?€Åj&t.>ªñèNÑ•­=Š‹7‰3kŞº+;è	?ŒnIqÖyzÄ|¹ÍŠìu‘@/çÿÖtø÷ZwÙ«×íºì€š#ØÊÓ	2HÆ”h(èx^Ñ¼,ñctÜMş=´§˜ØYsIõWcà”‹ac}…Å;Áhº£\/-ŞRÊ¬Cuo<+mxZ\²?æ*Í¯R§Êèš®£èrKµœ„æöºÿø.Æ¢Î¸Ÿ(ÖÚŸ"<é.¿_<¾UÿÇh4O£®ŸÛâôB!Qÿ»2fe¯wZXO²çc’Ä°+?7E®¡UA‡Ú(4àÏÀŸ0lâ(éµø3ÊÀ¸ìotLkà)xL¥ó;³Ø¸¾>hgÑF÷	q=ÿ8³>j$/ V f#°º_^³npF4ü¢ƒt6ªí91ß,Ø"àRk{0G_íöÂÈxwl\ïŠ!³Y-*­ƒŸQ[h\3ÆBy×›—ØÏ 	]WKàÇ=„P4>%q˜ŠlºæÁÜ)QÔ	áhŸÌç¥¡[˜Òû¥¿û-nw8î–_ê&°{®ÏÎúO’Ï
Ü¡	^,ïa{±=MIœ÷†<ˆ	jaƒ(“Êrÿ Õ\éÓ˜L‰ÚGa9´İZ_ğ¿ÿmˆkÛO¡Xİ1I}°ÁcıŠãûm©¡íßÍÿÏï?“İ¸=UPƒ,i-ïU9hµà-UºÏ©zv®ƒS
Œ‘&u“­N‘c’HvÔÉŸ*@ûpG/mÛTn¬^(úÍ èæ‡íbZ[Æü¿ô¾+cîÚ¯8qÔ“®„<M? zõÓäk6ŒO†t.TJÕ•cµa4p‹Ğz)°‰QBd¡ RK”{à`oxHõRZg^LåNb¥Áåæ‘¡¾W¦MŒ*’¡ÑÜ®èù€bƒâ€Úmv©wK,…2XG=¢e‡b4,•%¿x„Iã.şÂÂ%†êØ–Döó[qcäÁd9F4Û,Å2ß®9M9¸iß¤ˆŒÃq7˜rØŞÅ»Y`äÌÌË–İé¥%w™‹q€™2Şy[ïq^¥*®U­l„ lÌ²¡^$øk1,bÄsØÈ9Q@€·kÏü:k ä»}2ò"N£½º€
Ïë‘Ğ/«üèöf Ãt¼’;m£ÏUcİÿ0Än9M¾%o
^½%˜"íIë>é¸}‚Ş¶¬)³.Kíèk*Ç%pú³F€úh¹¨QUı–`@¯İËÓ)‰›ĞVjğìîù8Ë«Üí¡á®2'ÎfsÑ²ÑW+Õ¹N‰H¯%XÉ {¤€Íº¡1OLâÛŸÏ½‹ßƒşTÙ,Zs”8ºÊÆÙ@	Gwã`Feêg“ªGj§ŠÑ€XGKÄj®½n®Şİ*‰“E¼¥óæ½P‰şq7µw#¢sJšƒ`7p€èOJ^MIš…·sr³tt­®qçcõù Øê	¥?UÂ
ß…£¥"•¡R2Ù7vÛè,»—O0áfƒä¿‡?Z"|GÍ“SÚ‚õ]Ø°Ã†e§ìºïğ<ÈXG Æ‘ŞĞ <ñ9ñÂ¬ïÇøÖşp*êXãGÇ2UKáx#|cà"Í3kx,(kæ!ëÿ7ä=Àñô³bM#¤pâäM®e"4•/“TÛ%¦)SkQ:€¢²yÎò]EàRc¨JnùíõmÉ[Ò	ÿglÜp}`Ë­Í{Ş³…9¶€Wü¿´LnågW^x£‰6œt¬B„¤Ì'l†á©/»{U„&TgNf ó‹6äêèÜ©–Ğz½ı¥»kqôl‰ÿ¾£>ÛlÁ‚Åºv¸TîNN ±áGÿè3,Â·5wÇÿ T-”3Ñtn=‹Á'£]÷·æ{’ÔFW	Ô.é~Ö¦Ä\Ë]»+ÆÊ‘á[jä›‡Ê@3G]Ä£’KLÛê–l-6Lë˜ŞÏ1OLÙÉ;¬¦ª‡âçxÇ±å?[;àÙëôÿÄ×‡5½8¶Î¦Yó\ =F°ÎŞ`‡o!µFâ¡†Ì ˜™FR¡KXl‘7ÅAcÇ¿
4}D Ò²F¡½¨@Y¸´ğt´Ğvü®n¦ß¹|"3/B($$§¨¨©r¨	Ú@–Å¦ã¥Œ'êÛó½Ë e¦èxú¸lãhøP«ÈB»]iÈ¨Í;“ ÕîÄBÌê×i9æ‹Á×ÓÉBäV©‰OÏúºiÆ—JŸ€¶Tóñøã!}ŸEoÎà:(ç“Â;ÿŒZ#
öÿJ?-„6cN§õVı0ohLã'W´‡€ÚDWBÃ›'ÜÌs•mô£Ön¢£:İ  <”œ";Î
DLÓjÍ²XÒ…~»ËÀÄy¦šÚ,ëÜ:¹)}.éyå±5FœÑu;ı-u²K4Û˜ßvÓ‡Ÿe‹=×,Mc ç›&S+F0éKÑˆ¥FÄÛ&EÙÙf“Ê.;‹iÅ^îÉ”¡•#h{ã4ÙÚ$y‰!Ê6ÁA¹Fm§R~íwgà:¼u#9r BG¿gäÂ#ë”ÜHŠ‹ÓHe•¨ •~Ò]¢“º¨ßí²·ùsú`ìA[şîGY•­±’âÕIA¼²]:)Æ"<FDJÅ?<ÚM|z×p°€ÇÓ»Ø¯A<³|¹§ŞüÚàid+b4È‘fØÈ{0,<Fk`‚Óò…À+‚Ü0ĞØ~[¬1/]§wº3Á×EÓ|4²#ef´ÌmËd»±BBm·[é.³éjb²»m/¯ø'ŠîO`²Òüx›?í-ëŠÏñx·Ë¡%¼<˜à/rx¡‚»7¬UÅçÍ…ì¿³økœ&ªV-è}: ŒÓôÛE5òpÆOœÄn…éÆkÄÅıçØ//şPéôx5ÑGŸŠ×8Gë¹£™6kÄ`5zÔ;k/a/¢“dÉ«møF|×ªJ5¬*ÃU"AÁˆ'l¾,¶î½àÿÇÔ Û¨ƒÿ¯»$a|“SËRNW¹ˆjVNìßV€ó±YZÖ§¬h/k‰Ãµ6æ6BéÄvFlÍ—ç>ï¶/ÏZŒÆºÛıÁÑ‡E$Æ—ôÌ  òS—§nHKSÊgeëwßŠÏ?XĞĞ¦
Âq,
=§cø<{^æ;E½¨TA:ı6	¦·:ÊÑ%l¬&Í5«wÀØú®é‹)[w-u\!¿šäİ©|Ê±‚`9Á¸İ3K¿ÁÚ\­‰ÙÁ¦S>bªñáå).ê&Mš§]jènB¾ìï²n­|ffÔ †–dô E¹P{ñêõ¥ËJ"òO‚İì±šµ•5[ØÔ€OÕwİÏ…Ê—(IÏD›õÿ4À@óGŞ vì÷¦è5i +ë2k7Â¤_k^~+#5r6ŞâgÕÔ}CÛ‹bò,
-6
;ínUøæ•¾ª-ìAı££/Ûg«ô—Y‰]™J /ácaQ-˜-„â±8 ò]ÍºA¸[ç)}êL-væÙ¾\íê×#t¯æÖiP>ıød˜Õo;2Uê¬6¢c9YU(,^ï˜gÆrãé ]ÊÑööHñKóL®Å¥NÛıÌË&é ÃUóUT&Í‹,jÅL0!p±[ÅêÇõ¨ÊÉ¾Ñ³ÈFËG…g2=¤i‰óa|=p635æh?Èç¹4Wo…,—mÙaĞûÆFYµŞÍH}<’ÅåïÁ¢ÛÉ!'£ÜÚûñÌ—ÿù;
v‘WBñîÁ÷%ìƒ–N%,&oIG«\°ãxñKÏÍ[ˆ}§-I;Œn‚+™Z²òÇ—a°Qs·ı³LY¼7(GM­‰_äáõ°MìÃLvAûÚŠ?MgR]ÍŠ6ß‡Ë6»ß×ø½t}°`º‡D
¤<kŒİ,(K´ÆšæË“í.|™š°,æ
®ÇÿòŠ>¿¦išüÙ„*bz5d¯÷ß+t„ô)äPbf{‚èX“¾^©>§_¦lÉPKIæª‘ëĞÿw•Vìñª®RÕ2	o|‰€Ù9ñ¸€¢}ÚzšÍ5BakÓªÔ[€z€=:Î—½o*f§¹v3’I•°·š/ºì™‘@£¬J·U/ñDš-6û¡,L‹€SÚ˜Ö¦R·iŞ,B(I_µqpìÚ«óï'YŒíŒ#å ôH*ÿÀ—ÒµEı?ûşf
4y¼ñÄ™¼œ×İZº
Sl¢ø)6‘Úƒwé|¬ÈëøPåÉzİC¿XùÎx²Ğ :XÊ¼	U–ZÅóBğˆmÀ©ÄÉàPù¢{”¨Ö‚„PÄT!®eĞúó(BÒ£- şßì„7ÑÁğ„Ñş­é:—Ö»>Äo[¼ùĞf`^¤º¶®cbî“¦œ„/8TœxbÉK/‹°	f×áƒKLÒK<ÒaÍ¡c÷·+m)*P04¨Ì´ácƒJ*2bŞùJQùm®ÁëM°Fê—HrpnWÃ¢dt—^òÑ.)@T³Ï.°•q’á@Zf(¤“K 9J“Ği¡ËöİF¿sÈî iBg	hbd¤Bô?ÛæÓ™ñ‘ÈiµµeƒNq+L$âv#)c¤¯DĞğÈ™¼4'j€–^ä¿ŒL d$?s‚û „:•×	iuú›ãhÔ¦A>ó!¨4û§Æ/Ìÿ©^I£«Úİ§YçÄâ%®¯Kå¨,«Nm‘†™’ñÜuE/BHRşpÜğÛÁË|ÁE_Îıw³ïœÚ§†D”óXÿ*æ¤kSŒ™Ÿ¦ªÊ–•1ô›:ú%5/)\C¹{§íÜ¥m4I`!¯î±-?áşÿ– XÇ(²U6úĞº´ÁïñAÃ³¿ÚÎÖ]‰=ÙJÃ¬©À±ƒI«¼¢öh/ñåÑRâ)šÇJy¾Üø “À|-ºñ'¾p¼ê¢|¦Inı²CÅ}d(ÿ
J"
1˜ËR3ßG°ÚÅë°\’Ã]n$q~ =~ê—2ù!)üP–óú`åFmÄWË¶ocŞJÑ&……#Ë‡sø×x‹¹Ã©ÈPºˆağ/U1O1K[‹p¿¯ß« µ;l¸ª­İ'ux©½¸
‡¶9¡ämÏı"è©w¡MÄÅa¦ÓnJºö1TO¤ÒÍYRM“›Ô`Mİ|UƒâÔğìéî»[Ú†ĞD6¸¡·¬¬!É“û,}Õ‚{ûòÑ¸ö—ˆßÇ¢İÕQ×`sáş:Ì—ksœ$/_‹fâş¹¦ë¥@$ûæ—IĞ&œH€üºÓe”z;P}Ÿ¬úaKçz	;>¿ğÏP ¸?X3µK˜¾.4Õ ''€ÈBÁ? raï&?Ì3=‹ÄÀçé".~áÂb’ÉG„‚ÿÙßò»
Z>Œ¶æÏôæ…òWV¡Q×~Åı<R¿‚¸İĞÈ'›T˜•€åøbI¾ÍY#®F ‰šî\¿LË×ê,N_cDÄbšH½-©ú”ÜB<ÌÌÕZı®V>›c•WÃ+ZX-xuªùÆ~‹ıäB‹[8bŞ^,^M¿Œkc¾T®CaÑùÊnyV¤ÖP›‚ÍÛFrÕò?’'ŞlÆ	;–e·	EpfXÏoÆÓ¤m ¾mÌ2'wòY?µ™í©>Iƒ–Ê+‡@ƒıƒG96A’UŸyÍ¢ÃÌÁ"½hÓH#RRâàŠ÷”Ôá‹ábÆŠ"YIE0UhInö#ìéAß ªå^WHå›Ì´…`GÙ ²ô54^^œ÷ÍC~’Z£ZÏ?[SZÍ&2iÎt¯¼É[énA(öÌ7ß›*†aÌ°fÂšˆ:VŞQiûÔìú)F râ†.£[0QÍ?ór¤|‘LI)›-L"ïÌöÛRŒŸ3óy«±P¾f(ÿ[¢\2
 1`ä^«©Óÿ­nøB”?_Œ‰•@§1™˜-%ëÈŸ’İíÿãr±qp«$tcÆÂ­h‘c¼zn"˜ıëéİân]“y¹»ĞŞ\‚QqSğş)B€Şë‡h¥BüfjC"	´ãTØBz6È3=6í¸u°€m;M=Ùs¢>_ÌhĞkRJÏì­×çPj.Ö¬Ñÿ‡Jˆ¼›†W©ú³å<h‰4¹Íre¨£·¸¥Xb[ú^;¼©2„âƒv5.†*GY°8ğUËéÕŸİ½Ç‡û«ŸS±e±Z×iáüì]ZfBmÌ²5ÃAX¦¯ÂF%tjÍèïb#:zãic-(*»¹ßüaŸ_™Íì9;fMLñEsR:õìœ÷¯åŠœ=şM±7#5:Jñdò!•^â–Â–­™± uÿ(Í£Î2tŞé`‹ÕëBßVª }¾ŸŠ-™ÆBÃ.°ã¶õ	A"Íıã°!Z››aqm¡~0Ëéï ß¿d§ qX;fĞBÙÀ? ú2“iMÑ£ÛQñƒhÆ^Æ˜¹	µ†²ÁjÏ†µú+½÷m¹œ5ô¶Ü¯dOŠó2$ocÊ*W7&ÑÿN¶ñè°ĞÄÕ{ºl^I†Oëõ™ª§ëÏB.?Z.»& ;À’~JÜŸ}àx&šÔ¬¯X9û®IašïÔÊSs6¼¤´÷Cr8q™^!­ÈùGàè»–Õ£zªfsî’?’{p{õkÈäáï#_eZÕ›“X2€Vt´#ÕàìP¾L˜^ätƒï€­¨¤œ”š¨SV¯b‹’Â‚ç±Ñæ‰ÓB<3š¬è\ÀÊs¦W³‰'Áb'İK|cğ¯ô¼BûyÚ ±_İ™øLa7Òƒrd²±Ôè_‚V.0d·iäÏÍ#şÂèâ\?`XË<•ÏÍÀwìîxˆtŒ¹hê™EA@XÌX›³½«»(x™jaN©®bƒÅX‚xöMŸ-i±GøoÜoX,°™˜VK¸*UqbEü#Nb&xùèlƒ‘Ìy÷,¨^£WİôŒRh’·÷ØÏ‚åùƒénpÃkğœ&Ô›¾Â¼´uXrS¤É3İuFúÄ˜ªDOà[Y/à)ò±8…bíß9±ñıvÀB
+[Z*uB‰nØ¨Nú\	›òhæäî¹ìüõĞÄCmo>‘Jx.Oğën&q×°Q`•ZşIpÁßÀö´ÆåÑ[NÃ	ëL‡C¸Û¾W{ÙvP‘ˆÌÉû÷çJ^Ÿ
¸ Ih4¹vœçL i>åÔq	Äà"0bW¦ƒòßä+ŠJ´¦ÿ§ŸÜÂÃ =û Ò/’ç)—8 ØWOçí;;™¥öÅU·iğ´~H‹v¡&éö~¸6VôR|”‹lö2OÏ`¡€÷åÇÕQP:°o;ı·À%«\xn ‰ÑVV-mÊëEÍbúäòá}'AËntpb^òH”’Ñ‘Çñ¢ã&ÈåÀúC]O–GLYUC®œ9øø·Û5Ğ8:*ÎùV‹öÏ«3*Äe·¼¬$QÇ6ı±W:Qï2Ïû”è¬{;º»óûZ²ËX„`$<vw&ıq`<Š\šMşDÖ]™q©ÆÃ^XÕÍñ‚œZ¬W1©­BºÆ@†mò‡âêÁ kZ\ÊÇr`@Œ}²¸å¦Ìrˆke$¬‘›ï%ÛH.Y ½„yôş•ƒ‡7Mç`©÷©µgÅš™™„éÜ:´8·—æĞvåƒ¦)Ç[Í”k^¬aŒFV52¥6i×t©á”Z¶*wÛ| (T?góVı|durB®İ6	ŠOdEoæd€Z"Hoî³¼8+Oúo‚9õ>“«@9—î g‡åd!/o&~ Ò<·ı¾Ñ5,>ü˜¬¯’¬‰ÁLÌÃ-3©9¦âjEÌ‡.(g¡¢ş/ñ«laùÄ¼‘×RK’»Œ?å«K(hMÈ¼Úªl ı‰„D»ú¨h£¤{#Ô»°<Ì»(_Õ–;qŸçu§×W“ò(.º_liÜZßÎTYğíIóßÅñ§ èGC±wùª}Oé3W£ßŠLaÓú¸Å©"Vôzwf’S7Üf‹€•€¯§¯˜«1€Ş³«‰:¡ø‚È–¤ØıŒ$&Eq1˜Õ¡±Êî8Ş¯Qš1ùÎSk†+ÖĞ(|ÂÒr–1›‰>GŞÇ
»Ç&åwE×Ã8‰#Úq1pÛxã¥³a¤¹çÕrZ—¥\9‡?¯Øø·h¸çÔşÂ[ QA¶¼¡x¯1©2nxˆ§Ôv&´E\¹ˆâø²û¢ùï´·y6NH_yŸıâb5®uÁfó™`Ç¼ò*›ÎTÑA
w»º°øÛá“-é–ÊÉ¦Ò/{ƒ_ÛÁÂšLvO±Â{U³®¾P‰¢Éh[>»	å7HCĞ%Zh}:Õtd“z¢ DÑkçÅé˜`Étt¡ë¦ôL½½{‘iÊÄÌÂÖF¯šjÑ½é*Q†Égñ"‘}©ilYÇh¶è”…Ïó&Rì=ÇÈìn˜i]8« Wëãê÷F:Î¦iáœ´Ú÷ÖZ_^ìÊiâP’P:]Ô"şŒôı–Ï„/„#Vˆ‹ã?Ç2ì×µÃ¡'U£ígÕ¥‚z°nÔYtöyºIbL¿3dŸgÇy †m†¼gè	1­9I†¾@áê:UbÎ’` "Û/T|É´'n”Õ¯¹™Ò×ÎÑÔÂa?F†…–ÅpÕ¤¹%à³¡-#§KrA­şd!«^óÃúşßuj¦½Ö ã×)‘qtivÃéf‰Š¼ÂıÑ’`Èô½ø;2é¾ IX\8p0ÆÄu\áãŒ2ÓW·8V¤&ÀTXnÁ2È_Z·+QcsQôyiAªËœO„¦KÄÁBFE>Gk]™2ZÇêò îË‹‘êŸM2²Lºa³I¬QãéÒÛ‚–‰†D,¼Q¬Ö5u'UKñÉlš­:ˆBù1>Ã{C]Únª%ëÂ zJô%vÎ¢S0¥Y¬8!Mô¢ícÔÛ9üF[vÒ×GPÍs3M,è¨w9a%·>¾JdõœR:'4´„Gœ£liÈY1ìõ®ììEº=o?§ÌÒÊ•âûèÈØÒIÔ33¬ŞN"’>ZCŠôZ«‰îáÃº·}Æ.ÿ Âh“C‘é(oWíÇlRYg»ëÓ3êG@>¸8ö}Pk
$ i€ìjv0ß§´êÈ±SqÏvi’Yûàj„F¬KK¾½ù÷x¸	m¬É´Ÿx¾áûd“Pmm‘ó0pƒ Ä+‰Il¸ø±xÃM^õÂë(‹’»fÕEô½o< u'9Îß#fÖŠåÏİ0cW4Ø¥‚ælôBw;9Ieğ¢²}Ù¶Çş–º¯3°i+Øtí9ıíßi_NòLˆ;™Í±ê˜Êsçg»¾©Ï‚+?Mª©G¶\¡¢aÖ!"vŞùOçha{Ñ·jíf<·Eï]RÊ-f+µ©»§Òí‘Ê5-{/ ÅÑ¾±)‚øÈÖ`ÀmÓf²iœÏy`lGÈwè {ÚJ+š	Ô4Cáó‹Ğq’á´½gCYë<œáK•ğ‚3”şˆ@sîm!@’uŒgåaWTí=¹÷PoŸ"òÇeŒR	ŞÅÒØÂßî¹Aá˜>ÇÖ¸äìsÖøSW°àPİîÍì»%RğÆ@÷Å-éQ¬Ñ1ş)iú{2•ô˜@bs«Û&’õ*ú†€ä#/Ûæ½e‡ğvÿ‘³€Ê:€¥Ûùd‹§VLõÀ‚•Eëe3N³5¢Dò6± 18`	N~‘øÚtÃüÚkåŠV´*ï˜²b‰Q›éy„<ÅÙÆİ+SU]¤çÔìT`oõàúÇê$˜ß,½OÉMğÊÉcYêß\ÑŸkÑ#È”A˜æ57PÙÉÔ|½<ËH_ƒ’07æÅªºÌÁrÉnAóÙğ}ßÕÜ­sTŠoù½uıå¶1x@ÃÉbê´U%Æ²baİ	/+KÎÈ¨ùÈ…ÎFùèÁy˜qmÅ ”4ôğIlùJ­ĞX’§fXËïªàşùø[e aFeM¥?ák¸Ó4f>hJ3±ÀMkÈœß×H±İÀkB™-Œ[…¶ÊíÒcÊPŒ‹fb|ä2ÀÒæP€?)ö&J?tpD›b½mrêÏ/Íå¨¦¶’&Œk–Vqjn¸QœûGybóà-XãØ@Ô&;òÂ®]±†d9öcröá’P,¯êçN˜
q¹Q.¹Tg~Út4†PvÕ+iŸ\¼Õ©„/£müF«à„€5€°Şº¶,èû<V¥»Î!©Ü§ºl‡¡Ã"];zísûv Á}bZ“Z'‹L‚.HÙcÎŠ’!ïªÜpÉ]hÕï-ì…&9ğ;—øT%a‡âüuä'oy'á$íÄ:×{”:š&%«b7¹âš„Ö~öTşl,ØfıgızšøjôGô&nwØXxì TA/J¬üÔ	³ç%À<UİNÀgı+O	õIÿœ„‚AXÂ±ãØé°ÌÕ$ÚjÎïÜşP-Œt½L¡m ô¹š{}°jù…şWÚÖÿ*|ô,vœïVF´&2ø#¼xñãÑs¥yŒ:’˜H)¿Ë0ìZ5,½2î”u§Ùb 09ª5×g9)8„_kŒ%ûè:áÀDêÔ~Êó½®tX+pöRjñPØîùºšåyÍ‹ä¸1ÇŠòÉPìsÚ=ù­ZªNPó’0í˜YNè›¸H½^å]B8ß¸ã3¼ì^ò@Êx‚;Ä[ôT²rvûİ=©n_"¬{°^úOGÈšôRm?NêfbÍå>£}L¢µ‹Õ.Óc©ª
fW m}ı]ş|ÎáëgŠ!üï¥¯xÇÚjò7²{Ú©âæ£t¦axëøé-÷!Ç?	Ot«vÄóY,¼MÙHz¦¯ßM“Ì†—&m[
åÆ#%Î¼bYİåİpûn—;²¦‘.Q›5UüœS}Š°¢Š39:™ú„³¾w¤ æß AŠÓ«U©G(„°‰1”\ÚÄÀÙp	_šsQ<<ø'­úDØ__H>ÎÒ?KÎ¸«]2Öµ¸íæhŠÉ5Í*âÇ[ ¦úÖ›‰né?_ê£9÷p0©1o@¼L¹ÚËRŒ¬Š4#8Êæ½·º"Ü4Cöp"~ğÑ3ªøj·ı²æÏbNRƒH!µybt\U1Ğ[ë‘bà’LWp
Ã/tsš‚“E½ØC¹¯5Ó–µ+
1»uà{V1,’šT‡ûãc‘š©*öNnò–´RÃ6Ìì"ëü’ÿÃ¶ĞÓ\fÿ¿¨Æ*#ÒÆ5o~ù¹®í¸(2&ÒúÒê¦u8µ¹í"úïĞOÙæ&^Õîh“ Ï!|_ 8ExæY$ÒrÈ7”RzŠç¶úHİWœ®’KãÕãLD¤v¤IÔVĞ(²fã~M\Şigà6–)²üôÔOáx©¦!–€ş+f*ÌÜ_é»Ù´²ÈqšÒjh_@ë`E‚$9;å£iş´³T‰!¡e×2•ş`«u Á£´ÿTc@¾z³üqE`ßÒ°‘(Î±?”©A8»;ÖJ¸íaF<s¾ù‡}oØû3zÛ¸kÉZ+ õå`QH@Ãl¢Â‰ûnÕ´nGE(wÕúsZóc5Bå%)°Hİc÷|œı lüü‘YM–ù¬ÓÇAœŸ»Ş
*qr‹ÙPğÙàŠ–’²·òñ~cÔeÙ0U¿9Ñ¶×¡:Ry^9¤Ì²
µÎ+³kˆP`DU\?ì¿?_˜êl®£çêİÛ$.Öú´+~°ş®ÆRo¯4ú	–/!•ü‚Éã­Ï#rYMAs+°·ïğõZÿ}RÑÆæ:H0ô7Ğó…ø’À/€8¥1}Ó‡aR­ò]‡¶­öã0|ôe#¡PÑ,øÖùù•àûÜid4¹ŞÜ‚ÃÆ3æb¼²†N`¥\âÂL—ªsù§+l¡ú¯ßbN¼%bB®½É[ãB,¢õ•òÒûâ¬´Ä¹Ë2âJƒ‰±Õ °Æ/ ğSBi+g†âqãféI%ê|.ãÒqIˆ—¾s{we–j@ªBçwIéÎXŠÔC/Œ[áìé7èLĞámªÂ¯ àñet¤w U<÷èÈÖ%<’]üT]Ì]IÉñËhíVïw3S¶R&ï£íÆhV{'±	3Ljòòq‰L$…7`Œ6ôîÈšu~2×³¾^p†c™6…MQò„´Xsšó‰æ¨Hªªº‡¾²‘ÉíB_ñXÌ^“”xlö°Ü=c;Û.üĞõy·ˆ3®•İ•Œû÷S„Í] ´R+Ğ´ÑbOI~P æçnr!ş£öfª‰İI>›!(Ç$ôFT€ÎGª€A†]KBùëÙƒLcÏ×9¢Ö•ò(4;¬—¤gj2¡¹{%sMn„¤³(†øpOŒîç×9N]Ñ şb×¦:ÂŞ#X±ËS£¬
÷ÍüTLvJL	‡`*©LîÑ™ğf>øã¿ ëâÁf7¾ØşÅ”jò“Ñb]
ßwª+¾ù’û4­ÜŞJ¯DE ó›ÁI¢V“"¾ŸN‹;æ]…h#¤î<‡ÿ€Œ–®%2Z£Ù‹øôˆ›nQĞ¥òu$£‡kM)!ÎÒËµo}[Æ[ñQò9g®·ÍŞúÁÅtçc5!*B×LïÂíğ©!8r…ˆS'ò±6µõ½Ÿˆ?Àï(¶¾IA´¿¬ß}< X(¼MıĞŸ/ÓÖ5J«T„fâõpìƒŒR§>z$É3’ïñ{nñĞÃÜP[´À:Ş]¸BîÁuU—çÖÀ"ÿMR¯¥SÖN ves®ó•-Qˆî'pÊ=¯©íÓd AëïMÃ!huw’3lò¬±=¶ípÎl{›Ôè„æA7„ ¬ÀåĞ0ûut:å„!ÍxÍ6™„´³ù*ğ”¿
CÅ¿¶Ä²«VÇRW¯c°¤ºŒK÷•Ú+Ó–öb×]~›Ş­"?Ã$Ö~¾7N04N/{wÿrZ|çT[vÈ¼/!Æ´Nş…•tğÕÕ·‚›Â‘ÀéäU‡Qz~ÂxíÁ]p¦ŠàhC5‰¥Õç©·=Îø›>…ÆÊò…Eº¹(¼Y”fpÊèú»ğˆ ô;Hœ½€MPI‚Oı¹>FMbç{ÖOVG|¶‚Â !	b
ÔŒ>	äŸ¥q5*©‡ÎhºM0¤#t¾+‰€-Ûô¦•¬¦Ù.(ÍPú=oÖîğ=¼%øøFà+	³)ñiÇûoŠÈµ\Ò™Öc4ûZ}`uòD=}…eÈ}?t@·GZz%ßÀ9#Âãï&I“É.ùï¬Ç!Ëq‹1_÷	½Š #‹hwş4Ğ<›Ï¯MŞ{Âó}{$G»ßdZl+W6^ûï/’_Œßè€ç‡/;©Ô:ñÀå{àRhúñh”ïÖG¼«,ÆWÁbÀ” áØÀ¤’óeYŞå¼GsRŸç%"[LãLiÙÌ€÷‹dG`{3•Jëèª`ÿ—Èx›[ÓúÌ´.ÅIMâÖß(»ÉC¿véåi¡·9òJäÌ7¶ëW›Î¬ß•¯ü|¥kÀj7k¨¦,{haSğí™hOôÆ>0©î^>xïw%®EçÙ¶jŠŸ_”¡±“ÃÆNL®(¡›7ßd$ì)m+¥]6¢Æg—¸ÛV‰…¯ªŠ]şËÃ³t`k±—uÒÃ»s?¿EùTÈ’‡ö‘êS}@Ùz"NpIHqŸbœÉå/P?¼aŞöcô€*	‹^ WTÁ­FP}1ƒ‹X×³j€Šç¶šAÇ-k!˜Ah¢Å˜è¢5¬üJ–?EBq‰tÄVvB0‘¬_KıáŸwèıpÌ-Õ%Gü²‡!è;}2c¬UkhxS¹¨I¨=m%Ä÷\”êò/¤#äÏxı„Yùhè|zêVpàgkøú®£âŠ7KÃ‡RÍ‰‰VÛš]Ÿ•Ec”ÛJ}*Ü²yaO£Uµ³ó{ß¸Cúä\Úóé®Áî{±Ï¡` á«`·”š`q¢×d*·ëëñ¦¾·¿Œ'°·ı}|©_=ßÙÙ¡k+bÇÑ<ƒüqi_k›£ÉàÑ|•wCéÄóiÒLƒŸ[¤ß%ƒqßyE J¿:fq,gbP`+Æ;4œ,~˜@iIv_b?híĞ©>¡ø/°@âÂV¸,~m>•|¥°|dñ9=oR‹Wf<²)+cä¿1<)ÖNØ@£½>^‡Ö½d¨Ê–Ôñ,!ô¹W”M\ŸD©dgbæ0%Ÿ´<Å6*¤×Yá°·ˆ¸vÂ)¥m1àöDü$p[¨Ñ¿)BÜÙwCÁ†R:íÓ½;€LŠğ¸­túPI2q@Á:PÕÄÄ(8imı¯æQiØù£¥ªD´ËŞNNÂ	Œ!õ‡4®ºŠùµAfg&lÿ©£³8øš0ù»'òò)è^Èky[ÉFÉÕéŞBZ7Î¨á¹`É4‘nåÍ&­šR,eAÌBüñ¢W ·Z+¼¡ñ–÷d¤}AÄ _æÀªí(‚mtø€^lƒ Ù"v4pQú8‘½‘n{Ë0=-šß>[”Ù.\§0,šÛ¨lœ
>:r—ªÈ{ñm#Š}@/²lèDé$dí[äW¨€
f£«+l¦hn'2\Ú"ù§,zÇ“¬d_ ÏC¾R åÙRZ,B"Õ•ó«ÅL¶¨-UeË‰Ì¦ß÷—†R‹¥~şÜ¥TƒK&¼'îx´Ør•a“u#œfĞnPz¾b§ŒCa=Ö1òÉ²9šFU›"ü°ö’NŸúİ»’e-Õ”sã÷²¡3b¦÷†A€“ªO”pùÄµŸÒrÏ%åøvö°à¼6cƒÙ%ùwnôüÔY¿Ç_ï	Ÿv^<ÔßÆµ@Ğ…}ÎÜºØÉ” Êœš¹¿ëOÿ3Ø*²ªªú`;úï Ş
%É7±¨1ôt"Êû¸ã6Ëá=iR«¼@VhƒÍ¿	‹l`OÅj³­SÈçzj.*Ây¸×õ¿¦qÂÆåT•tc>,Õd9á³7İ¿¥±M/ï*\s@³³FÆJš‚¾‘~;®—™cœJ!™ÓEÌÌŒH†„	`è‰¢³Ö€6­m·ºˆæ'¾†œr'¤TŞ£C÷±$¥sôÕœHl‘Ã*¿ Ú05†üvúüsCs³=wt³ÍY“ú¤n Hœû/ZQO™fy±‚õÒ0æÉ¸ú«ïQÃa‹ŠNÇÄîµ~1F¼-:áü& îæİ»•ÿ©ûù‰G±İ§4Úff¼Óşu¾×“G˜×ßól_jÆ“Ñd›¢¿	š#Üˆ/E1l(OE|¶{{Fòuÿ¹Ö/wUChÜÂ¯Ç;E³ìF&…<~ğÂØƒ9J¿;Ø¯‰YÒÀ$×5ª“Tİ¼œvõ«& ëë¿¿rz@ŞåNó­‚¡ç¿÷
ğò#Sp7)~ã•uo~hêµMşà}˜9/>BZãJeµıx\øÒ]ÕÖmÛ¬XV­>öÎeèÃ3!\^œÉ&¸\ûNUÔ9¢2—óg›NÔ0‡¢vöÀ&ÂU\Ç£€YËI0`Ø°öÊ\$û_«2úY~LuÇy±·V,çêôÂ;ğ Œ5«kzÏ2­Æ€ØïìêXòr£òÂÆ‰[à´¸u(”©×ğ@õ74{à†³);r#Xí€íc•<ä´1É--/ŠÚVeí}ÓÒ¾ß˜Bş÷”ùéŠ©H"K«‹!m“èãÈñ†eûÔô€XÅêüõó2Ó€Äú•a¼ê,Ò–±QÕ¼Ñ5Á˜áüP×İå‘ßİŞZ‡$)_~ îg4VÀä½¬&°X_õXd„¾In7;¶?Â7e)- :×Q$Sïéí~­×r¶‡ÕŞ‘|+ÚëGTß$GÿM¶ˆÍ ±è1–¬`½VjÚ/T ,”}Ê´`J¹_Ä=TßÌ3§ûYÛ(5ò MŸZ=À
ãvÅ°•×ùÂ¡_Ù<ƒlƒöÌKÀV=Kb,•ÄpVÅİ¯1Šº¸Ö^0‰\'c
FĞn.ÿÛ´9‘y¾ZMDšçğ˜Ñğ)€üÊbºjšiDğÀ F´ïYÖƒc$/d"¶ök]él!ĞÖcëQ.(&éFtÍ­ióÁ¥áxtÅ¿ğ»Hé0Ÿ½À©D*áØV÷6ÕÊí{…ÂùxñèXÑ‡ä+È;7Î8 t™¯Ä¦¡];±(´Ujÿ3£0 ÆÉğUaù÷¥z%Ó•TYË—ÊÃ—ãüêÃÛËM¤¹Äg¹ôªªSĞk*² B¡•C€®yš¡ïOüõœV|Û:W‹uÎP†;ZãCíÚSç_+âõ/Æë”dº£µi¨°¡Ÿ‚@ŠŠñk¶}ÕÏk†šË|Ôıã¤8”ÛL1‹
…&5òÊı©ÅN˜­LT»ê€Í5,¨!x2eç$c9„hğ:E8ÕºùF²Táİqğ9"ŸKáuº‰ÈxJ€rP»Å»*“JĞª`–~:öâSÕ‰­;EôÛØ.ZsŸŒ67… å)G{I´)k2KKå%â#Z`8«ÄÇ9¨°É1òÂ˜„”qg5cËƒC§0„?ÎÂtùÍ¢´}|Oú¸Ëà‡Ôö— ªGtÀWd—M©O6vÎ”&r0—®–µß*](úêü¬Şçj¬y«~[Ê–³OòÙb]wŒÇ Í©;°ˆ©B|û…â¿~Pi¾7{¶jTÒoU@.¹7q%ÇMgç"Q.NÁŒ‚Âéñh@ŒĞ3Zs-ü¼ ÁS~…®IKÊi”'j‰=ƒØ,ƒ{âsˆe¾Ÿ;:â%éç‹Ú[]áÑ7ª5‹
ü§e½Äé™Ï. á‹¶[Ò£h—ÇTƒÖo§Ş³ãOg¾ü¼ZIÅEÆnĞÜ— _‚¬=#7úíè‚#1¼Äƒ¡ïåMl…­/BnªpŒ±ÌÓê .@²Š+6rû4ôwgTÎ+æO| ag¶®oĞÏkÙy¸kââJ‡ËëÍÄX„€¨
¦âÍƒ	Äö»¦£‡(ª$8¼yJ®–‘±á³ã"Š ×ûç£%Å¢ä¥-YÀ)¶ÛrÚ…¤AÀĞåYÓ ½È4ËÛ•êôc±ˆ»†)À>ªşª­¥î]Y‡)^uüJ¸Uõ2¯¨\‡°iÁIG ìµ¾Ÿ…EA¶÷[F«“èÅ•ı¤°½ËH¤…p ;×Ò³Š»VqózLsY4õ§¥²DïÅ·ã¼óÇ\Á_P†T|Ö] \Eğt¡fcæ'^FbêÂä¬Dúò’Ayn…0&RèpQ`ê3ö1Ç¡QMş[µi\1P´?wì]Ö–,4T=´Â|ú)7L$­Ğo8‘°ú»ÃóIfÒ“­‡A>sĞåE3ùŸ;5ÂÖ³²İ2ÇŒ¼PC¦öKa‘ ØÕôälçÁLrXõÇÆt~ê®ğ5°î«×¬³&‰Æ(VËjØº&ŞRÂ(JQ¤<üEõoÿBÅÌ„¨yiÔOğX¹Qö‘²İÿ9fÁBºiKJ”9ìr7ac&ÆbÜĞÉ¸*#_&Éİ–0nTjuâi%ôvÅ;4œM£1„póÏ÷º•„0ú{(ØÁŠ÷^wì¼—¶Îxe²‰@ö0nÛWm½yQQYÚ*¼p€şÂHS³Ü'ˆã`"–n«~‰nn¿÷$3ëŞqLñhöÀ¿"fëE´ë¤ÒäıÙ·Ê‡r¦YY^ç‡Á¸ˆbrQ¾s©³Ãu6
†P?õ¬_×ÚT9‘"' Çà.Şv°/!?×;êÁøŸdØ_¨­ö²ß„¡A—òAéı¸ õÄ&ş$¢òh© %n ()øÙ±Ü9‰ø#PcMğÜRà?}&=	à5ÿó!ÖøTXaÆ„Ğ1f‘náİdÜÅ¨(zµ2}$’Íì@»|s·×"^'%ùììíRØıƒÎ.OÛ˜o2M»¾qçF0¯o¤6×Š}åâÿÓ³½d_ØE’L{,D5W¶I€ùÔ4(?Õ!Êt‡€ä
ƒCü5nüã˜søÒYb†¤,½
N·Ãƒ¾`[ßBÄ€úO›èßQW(Ms÷G=µËğ‚Äxæ.±dÂ'uKDU>J¶]ß‹Œø°
Å,î|xµÔ•ğÁclP)á×ŞUâŠÿ âgP3_›(j"aåúd¯ŠŠ~ñ0WZTøÄ®€aM³°1IA“"ÉA_Ëºo]<#DÛâ>u½h“¸+Š3ì”›ØÖÿ¾1[nc.Bõu›¬wZÏÅ‡İA@`åªÜŒ¤ßY6#…Ú—/‹ùã½÷Ÿô$¥‡§ÄçŸêÒaÃıPÔ<Lƒ]iCy G/ï½WNŒ*D%Ş8
ÃşU<,JIÓ#à»Ä*jå_ Ò+§…¯iv9Éé³S3`…(3Dâ#ÁiPHQ™ª™#I®Y’‘ŞjÏ¾
.”i©ŞÄğjò GaáÄ¼üJ÷•ô÷ÑDÊ‘­áò=Ô,˜íû«­iKá˜Dç“7|+‰¤´³É,§”ı–è¢ìúƒ<_²Æš•ª©YWTŸ¢ÏŞÄl¼àSˆ˜£F°¶Åƒíc»`{Rë	;*	Ê‰Láîf-°êŸ¢\Ú‚Š» ƒS:>FÌo7O`|øáÎGä³S-ÆóóòÅ@W©Ló¨d‘[h"„n«ùV{¢¼jöóäelKo‡¹vËÿg=¹T]PbíÈH2N÷…ğÿFo«¸a’ªŒ7VªSŒ´õ.¸Øz2™[\¥½9	¯N.ñ’NüMÃ’ÅÃíò`Ã—…ÜÛêM#†ˆL²‘*S„ñrq*ê´Îwôõu·1 ´¶6x
5v#b_G¶>ªF3ß…y”p4Æjäê¡Jü0’J³eùªe%bÒ±BØ5×²)~rÖn>(¨=cÊiS€2ãïv¸jEÙ  @
¦f$Ôİš¢?RÉ55ù<úƒiù¶ºaZG=±3£Š+Y“~¢e ©rìVúfzß]®¼/R©!"'ÅÛ*2#»v4>}ÜjÛ%®
JKÖ¨Ì‰7ñ•BŞ ¶tá2ü¡±úôs[q»®Œ’Ğ(éÒâ–!´q“6ù£Í'+4¶~ö;ˆ ÿ'i6;—Yks~4Gäº’ŞÏµ3‚Şæ.¬+‘ üjxˆ	¯Œ\øaôà;¶(6IÓß÷gKü[é©».BÇËBBË	¢„ûÀIº4ÇÃç71ÀS3êø[´¦™Ç¥'ÂõÉú`°X´¾k/º9æ£©(¨äMë-°\5VÍ·‹m&¬bs‡&¢V8‡Yc™ŠVèºcÉ¼S‚ Ÿ¿.2©+©ïNf-àÈà(â&«xpäìØ×/(s¦9ÜÂË6pâç!‰sNäMV2õZ=0z¡yKŠĞ³äJ	mÜˆèƒÙ'f*2ô¼hÙ7eUú1
O÷Œ¢ª©?†REóaÚ
²õå|÷U€0p o­·ËÉ÷gÈ®'Ö"®o¼qĞµkJ/¤!”âZÒ¶$mH‡ĞBÌ ­ºl¹E´”¬ŞÎÀ/T¢»–ƒÊ>â½{âóï<90L°‹m#Ïa ^;vM‚_(€¦ë{ŞøóÓõyó‚OÁMÏÈ5¦|Ç{…Hù[|9‰¤§<kÍ?úM•Û6-nÊèd%»á©²l2{©‡qCf±Ğ8›'1C©äJÏdİ½6
ê‚X´áã|š=›xëŠ/HVÜº¹¸xÃƒzÿ	0ğâ‡ØğßZÒÌlè«×ƒºPÿ°ñô$…xÓ”Íú	x–>oAr{ŞBÃ[=IÕãÖ'ó†ZãOFÇ`” _á¯m	şä—Iı§ŒëS%Ê9é»K3'·÷>dy‰ŠtX›-Gå*ÏA„¡Ö?ş«0È ËŸá&jÉ.®¨*á`gY¥s\[¢0ĞİI˜¬p²µÈl'®‘u‚CíèÕ-ØasÔšO™a9¦Úèp†/	UèŞğÕW°Ìü3rÈÁv5_”æ]V½ª‹óŒ}»õ³Œû¢×‚p×ÓìE`ô‰Ì™ø$ç|=.äD’rWåF©Õü{\“MÑËØü•ßãV[øs•d™ÇDklµh¼-Ô¶Â]ö6[_6Ã‚áƒkõé´Òéf+/«@xı]jàæXûİ¬xÁˆ{˜F¥î  ¼&y¼™(™øçğH#„4"$p©Ï"(Ó¾u;^‘6ãºòª<‹Ì+C†)û·º˜¸ëÁORæö«ØÆ¯)dwğ¥IñEwê}4¹«*÷Æ™kúz„MÏ°åZ«j#œ7
Âº´#!šéGŞX:„Ù˜aé¨>	­Ò€G.ó›­Ò0Œd‹æ”zJç¶_£Pâv˜IPÓ­mú½|a.øş²’åå^cµbêäw½Û/°NÈ@Dà¥YÙğYG(b~1z/ïX»´‰9ÂÚj“N`wM§pr_<M~¯Íøéôàâ…™$s•ú ¤‡' 	À¬lÍgCiøï›šœÕì²&ÿø>À©íi(¥ŞE?1åTî×®Ê6å‹¾ÃÊOuËñ‡·ØoÒeAÄlµ/[À¸Öï Åa%Ú¯L¼rbse×a¡%ÃBñ2¼b­€#ı„a¢$FpLgè1%†íChòT	ˆ<¡yU(CU…¢D… 4Ş¾¨×pG-„käÿp°„+«ÚTÕè 54qü(ş¡>Y X¾ºù¨¡«Á8ÍSeÕ~;ûõˆo‚ïV7w×õ»*âwL¿ùh™ÊƒÄ½¢Ÿšp2¸77s¦pgÌnà¬AIC¦gM>^Èîğ‹Åæ‡¿[
¶ÏïÖ°ò¬+Q®tÜ”‹Bv#ÅA‚4YØÀ»’Š¹MÂ1dõÈ)cWUï+‡5‰ï@pŠ$^Ôë`ÄÈPÅ©ØÙ4ê©®VäQiH³M„”5¤„–ÒÌ7uf™TËÔ¼Bê_”—^!äÔ«3ãß«5lT'j{NãË+>¬½ş2F¼Ş¬v—Æ¤%ÑüC[ÆCB¶D¦(¼„W» ´+¹xÈ³WHÎ´ƒ^û¦ÒYÑhŸzq;ûöá¿»ÅV2ÊóÅºxvF\«ÅÌ¼Ô´}•ML[Zrtı•(fğÕ5µ%§úwš¯Ü4‡‹‘° -Ú­dÓ"4lˆ÷ÅÈuDë+2A³6"ÑU×ÈL/2y×®á„33QœQdÓ[Şk>º¹éƒ©'}$tŠ;gm"3ZÌÛ1©ˆøÂ&}E÷‡f‹8ÊV …\51êÙ(?g¾Uã½EÁ‹ëz¸Ö»êcöáÎrPaª8Œ^ÀQÅ,Hä»¨i&®le	äÅÙ#óxëoà(LáÀ£>¶½pµû¨”»¯@A0Ğ¢ùYŸô­J:†ï•:>úĞ÷N ¾ŸQÁQ½¬£æÂ³Õ°æ‰g›9Gf|)Â@·.ve]ŠV!tìiœù9CCÓmZr`y³Æ
»´”2z¯ù‡a£(Ùíh‹ò¥Ÿî²n@:\´çÏ	cì1a$…ˆ
İ#u¡	ØW(Sä-˜úíFZ‚ÖzjÅ¨ş]ç+gjyé®‚*Êtâe–À¤ô³<Bü`Ğİ$Â•R£ŠQ±Î¨©˜!Øé¡Sı*·’Ü×™ÌÄW]3¼åSF×T< Fa€;éªâbËªö^Ê¥½•ë-’g‰°oæ¶tfi¼fßÈÌXPœœ@ÁWGX‹˜Eßs?Rúß"¹§¾Ô(,92IbÙi—›ˆöÕrÖãî®ï^3±†õwg”¡ÔşF*ûj{k­™ ÚRrûô:ıÉ1(ÈÿÈÊ‰ù_a+}±1“5»CqÀG‘tî[Ç$‰˜×Öå|ÌSnGùw*tp»z4Ã˜\aÅ òBğÃ¦6xÅ¸;e¿ngå'ç1Fòò£ÿfsêÙ1ó@¬PlßÉq(wa™×ègf_–Û1BmªJè\ôÿ‡äkLV‘³ Êƒéà¦—<N©LÓü-¥§w‡Š©€bãÄ@±ã!øËFİú„üªÊlD“J …AòÛujgPhĞ‹—Š#!ò–ÆPj¶ş»bš«ãº—ı‡*µ(v P¬ã¶0Ñ…5 ;¦º!O3øDæp3ã"+/jæa3:AÎÃc¬x?Å“ä?‘Eè/³¯;ni¤¶e&9óYšäÜ|8ó†PAøŞ=,ßïv‡JGFYuñr)E¥‘±&:˜Y~ÉÚò'-½§ÃuÉ‹âºÆúG²Õ·Vh‡’•h†ëZ¾™¶º"h'¡-Ô¹H©Ìl¸x%Â’ÖC¬Ó [Ñ–}ç7¶3FWX¾‹ñĞŞ§¸v¦¨Ú»ñ* ¾#ïÅÛĞØ¹ê]Yå'U +˜”C}AE
±RéÜöË“4š”acŠ3ğÑştåí\ì”r+–Çjœ»#Î•ò)jÛzEÄÂÑı£³ô!ĞÕ)°AÔûóU,ûè¹‡üRQKáğfƒ“Õ%g±…´åÚ0µ0˜¥·±JãJ”Ù[Ş?»j$¸à`H£8…	9>Ëù6½Å À¸ áF¸rY¹³…=ÊøÌµ—·I«·3a46!ì=µÈŞàG’\Â¢¬À"à¬·ñåTï™üwÒ{	«¼¤Ä_q¨·¦¹>œ/µ|¿d‚ùp¶Ûò/V=†kp F´†Œ³°Qx–åoœi¢—üvïİAu35q¦iiZ”8ÉNmì0è9¢·\ˆ:Ø`]­@[ìÕºÍjÌ²™'ÈÃ}90àë'¥èĞø˜”‰t¬FŸ	ğ·4¾3 İG+XÏnr½íÃ›/óZ	œ«Ó¼|Ù¿îéÕCÅŞòõÑÆ½2•óç¿Ì½ŞÈ¾ê«üpWê±¸D¦nA¨a×.¿ğònpáÔÓäd8#É–‚qc
x}®ìÓ<¼•'õJÆ¸Ï©°o  óÿªG™aPë³5¥w¼İD"ÂÌˆ•º+)'D2Ÿ83¿£L&P”ôáCre‘>Ló€Æ‹ÌCÊÕ^é+eeb £ÉÌù/ˆ…DóLVÏ½ëT8¬Îc˜>Ï~ìïùxÛÚKüG—ÿæ¶m{oµçÁ~-:™Íû0 p}xÅiì›_ŞqjÆí“‹ÿÈ¡rj|Èö€/WH‘<™ ïS}„‘
ÍÿG§/Ü=¹ÿ$ö;ïûÄ¢ï~åpœrÁ Ó?¥”9RÏ;x:®¹@©Qû›óı$¾³›IÏö·<xWgÙÓ¶J1>[>	Á!™GKâÅ¡ËASã !ıV>õĞàßŠ© DéaMD\’w¸°ögê¯«‹Š(¼°n£PˆB˜‚àuí]İ´M¬8gœR[¸à‚$|¾õüû?£“òŒï#’ƒw'œ•dÙQ9å°S8"›­Ä-œà™ø±;Áv/uÅËñ¢ÛÏÄ«×„Oé[¨´´:Éò5ä3oÖ¢Ö¥rÁd/‡éõààòÿw ¶Òõšê,¬’ñ>ğ.²øçĞ¦*û¿÷şOˆ(”.ç!ï/×TbŸ[N&´¼³Ÿ)·æÜMÃ	x¡Œc|S”pÎ§{ÎsuœYBñşİ4SaoÀğŒW™¿5—ÛG÷SRxjÁós8mEõHvå…T8›(Ÿ¤ÿhdŒ¸“ïUÂU%ÅpJ¿Nüt”¿ıRó&¼Êì÷|ËÓh¾ÊĞÊfUÛœ" Úz[ÙË‰†,ûy_¡[Nƒ‚Ïqíò;ïó½dÏ2µÃÊ¢m/æÚPD3AÎ MğìØ½HÄgÜ$¬ÔËDpá½ğ†cÇ‰¹1ÁUı¥w)Gñ‰<¸İ«ªxRæõ4rÜM€q3ô1cĞéRÔ=à„›í½©©¸Ëna¿Ì6§'¶’×xRŞ@şöığGm>’/-L¹"·Œày:rp@6üòE~ÑmÌli€YßKàá£`”ÃR/î-2EÖVKì'âˆC~•D;kß´Oœ[ó#­Cj†Q^Íæf“]Bµ\Şã›/˜Ü"}+÷˜%=»Ô`2€ü:©k~×4õ[:ÛGVy¼ºaÚì-•ß1_Uısg|J]O£Ç¢Ò.Î]×:’¦óMï«€;.İ÷ÊosBğ4êŠˆ©`‘Š6õdë;X´ÁÖïv?2z^`R…E)u§S¹Œ­0!B:R˜)E>ÉT7vŞ«š}ÇÖ‚•¶¬û8» S¿ŠÂ2¸®I…–q/|Ò“nD’ø˜5½Ä®­D°?\‡g´³q¯½‡ŠzÜJß>•u úqŠ°Œ¡áÌŠ'ŠJšğÛµˆ•nçñôf“ÔY ¶HÈ™6Õõ‹?}Ñ–Ê!ÉP­gy_¡çÊTiA)¢™sI¤'9PA+Iì¢‘õN_æà03ïyÊ“/¿
šñŞ¦Ä³Ô¹ì§––Q#z-gğıºİŞ7$~°ò×À;×OvçZË(Šw„é¯g¥l°«Ë†ªÑÙ«¿E&A¤ÿ6íµVìóÀÑDi³ıjdüüîæ¼@Å…Dy¥EÒÇçÖuÅ:äıºÉG˜ø4˜Ghi…ø”÷z×MÄö—œ|W¯Ş<—R’oŠñg	ÊíÈÑbŸ%eÂÂˆn/´[®?¶’áTjQ—Oæ<Sñì1*9±â‘}¹9šwpe T—u_%=ÿ¸Íd”„,/ìüx’Ô4»;å#oÀûâÖê×^N”‡k÷}ƒ9K'íÛtèO†;m™ÙgGºÈ&†vdÌ=¹ğ¢½˜Â\EªŠ&8cÎ	?’¢)~ö–wff
ÎùåPh(˜Şgãê¦óø®ª Kú—pÃ\à¬^Š
P§:òù÷¿Å:‹Ñâ'hÈ‡•Û]$Í4İ¾mÏQí”gï„;‡3iè!rµª‡DÍÆªT†W†wç× `&B1öİÖnW\9Ïî1 oò×†½™xÀGˆ›û}êQÒÍTt†öİâYïÎ¨èr$?àŠ«Ù5|tiÊıA%ËÊAlÒ“}.F…C“ğ~—Ú=òVçWI,}/A]B«L…VUÒT\ÎwKdÜdO³%è¾«ùÜjÊÙ
è*¨í³ßºcä¯–ĞÅ
è=øP]QM|‰f3æ„|çIjÂ+ÄÁSF|,8+;_âQIRpUuEH4ö™‰AíÀ5j³.Ë3˜ÂB«‡•A›¢ú™>uÎŒz³©†Ÿl¨i`˜¨áŒør˜³³å\3äZbpù¸`®YPWóu$_g‘ÿëSPqãZ‘`å×Œè_—Ù‡}òµ€Gjş(Yxºt÷–p†½ìÃàqb¤)´ZôëØÔã¶ZÖ´ËÂ¢1¶›G×EªxA¹¯G€ã·XÄuj /¶NHˆœSH‚	ÅÿeŠÊÆ@L+mNM~_ümp‡mÎzò’áÿq#=©…Ñv5)L,ÿ‘Œ½ìlB¤b›V‚Øïó¹”ñr%Ş›ÿŞûÅ€»XEZí²núñ ¢ïô·µa¢˜ãôæ\A¨Ï*…/ğ’¾™æ³1)G‹Dçæ	­+W²l¸6¡Ÿ{Hèª®WJÛäEõùƒrƒDß–Ù >^ÌÉF£ïì©×³Î‘¢bÑ6hÒšâK­ş¬%‰G•=*ÏÎ@uóçA/ÿ†lÖß0˜>=^ı+é”{ÉÒÇmVR‰;®)anußaÓvïŞÕ)Ş_Z´bèæ‚¨”ÚËãÈ²JáEÃÕª$ğuÂ+§ûÆÙo°5r1~Ş„¼/lë­99!«&%zé\œ§fÜQ$¶­Âc2•da;ûµ¥öşÌâ8°Õß—“-ÒR6Á6ÍZA…?Öö½œ0#–‰’8bÈæ(@:µ¥uÉ­‡—CNŒ@F´ˆ@H¾]AÕ1è~Aí;ğ0Ít¦îÅº4·\¸\à/>-ÑÂ°i«YîuÇRV2d×#1ş–ü¶–,Uµq6‡ ?mÚôŸ¥2û òİÜ‹‘¦8”Ô’dDª2j?İX@Sƒß.¶ô
±Zrq¢| Ï~Î°ªAE§(e¤…O[t£Ûìõ`H’\¢f9¸`÷¦ŠH:ğuı¹Oúv>|«…Ş¼zÖQr§í>‘²ü¶ÕõÕíT%ü+îÖÿ~ëÌ7Ü™¿iÂ+>ó£•0í>qĞÚãºâ*•àÀ‰»wö]E”k0¬±I•é”ÖKÆ#Vi²ûxĞ]}üowÆpìµòŞFÄÃ|¨X_œúŒ7ª›zğ„¦ä€Â`Ÿ´³ÆÌ^{z?â$6§Ê.HÀj$.ëJ®Q_Ì¾ÏÜ
ã¦êg	TşWÔFRXÒQ?ÓÅQ…Ë·Ì˜ËİpE‹‹T\®kvm‘¹¸ª~‹&x‡ÛTkŸBWÈÔ¦ãÃé}s>2’äs:|…àUºY&$³Àv «!iƒË3iW‰ízéseæÎ zggMP×æà‡2A°):Êäáşå5IÁw6;ÑZÏD„ãv¢rõÙ¥š¾7>±B_ñö7!½û5jåp–nåyQ@m(8©Ró—O:š°…o¬²_œ†m0.YÃrëdİŠâ‘Ñ„4K–6òÒ]Wõİ¯¹_õˆfÚ˜(g.`şÂf[€'$l5PzyÙ7Š'„G_™„^ÉÎnÃ0‡ ¤l\6]á—Â½hª"N§ØCé®µç´TÍKÓ¢„&Ú¡½[{®6|ËoÖIÁÂ"p%b4/\FŸ¤X€Ë£Ô'ğ!3¬;JÓâ>Dš6Ï¯'3Åğõ©æ>"²!AÛÁ‹aš»z§­w¯ö¢¥â,âÍKC‡•H{JL9<¢ü+âíêN,P ›¶Ã£q?æ”kñ1	(d7ÙØªßë>ƒq÷€Ó‡¬5Ø©£òë_:_OşC‚k¯8Ç‚„xÃîLrlqhUâwÜ>æGÄo€õ.…å£¡s˜Êşg{ iÂ‚Ï¨â¡ä™ T¯Rê¯Ã™v€àÖ›±P4È8¼œ%Ù«¢©ñ»Ã¡»Y6ÓË`fÂBh Êå„ˆÔÑ–	v¥pŠfu«'» Qy.&¢àh‘µÒŒ9&/[ÉŒ.)¤²weKH‘}$6ˆ­¯õ¾|¶ôª:î‹5MKò î6F5z5¾;-ªåÿs›`6¸Ïq“”ô†Å.H'§òËß1¶øüĞ+¶DÊ6ë]©nwb$OEàª&cŒ-_¢õè}¥{t7Œú#P‚`¹ÈdÅW™bå3Õ1ˆGÂxã…ÆZåh¤zMJq‡~œ*ÂyZäEá#DÒ
¶§?iøŸ[ÿõH¹Xö@ôàç„t*}†eÜp­JiÚsÖñ§Ïˆ“ÛöÃÜ»9¼!OÙH™“q)+’’N z|˜Ã¼æ$ø9Ù<¬f'ô—ìÑ–cN^E0J`ÔùÑ_˜H‘2©«"şKğ¯,î‰,c1ˆÓ¶ Ò_(=B»H”ñj¢xOá×7¨mĞµÁ·µqb)DÒÖ¨ò.ÜÄAVÑÍCjğWÃåë\æ;F-°‰Šzƒ@Æ2PÄØ[ÓR“I}D8KVc`ÇémíĞ2—-¤¾b•äCvO+è³€­´¨Øz¹'ï('¿á¼øœ©œ	DÛ¤2Èeâæ#Lta"ÒÖÿ³_‘[ïğ$aVMÜ§S÷fZièF”}Ê2qß‘ëG/ñ)¼X“P¾QÖøïñÖe;`r&‡«İi”ØÛ©oì¾6­êï“ORöÃ’¬Xyû%–(ç &’‚}·k6]H÷AÁ´fyaĞ>h‚RX.Úès fà#	Ó1ıÀóÉ/RÚ´Øq_ßòåë·ßŒtÓSÕimĞÃE" ×àéÿ¹¦ßk)Ñ5?¾|¿ìÔ]~€(“İmSßÖ<ËF¡İ3^‘óÊ¨zª„Ç£Ã¢Z‹Ã­ÕÚIÂKƒ’øºÎ+òQã.! ±ŠüzÄşÌNEÓDI—ş§&r;çg¨»&AÄ5á0°‡Ë®ëÉı/[DaÈ²VbÜßY#£*½$H4ØÛ‡¬"dËæôç#[äê£”)ÔC"g.Xğ¼ÑcwÁ`ÄèË$Â²ö +.J¢v)×0å²éq“BúK—”×‹è¨WS…'’¹åA™¾áwI3“’Eƒ‘ÄSÈ˜ÌÅSCÈ0¨D´ š=¤W¦J0YÔC“®$ÿh€ÏŸä,xŠ«{Œ)XQÀZ¢äç€Â~ı®å6‡)gÂŒŒ:$Sg»@FÏªÓ:<KwRÔùÃ\9åE&°6céu§nQ­‘m°T÷èJN2,ò7”KÈ9@ıg9&»µ/aZË©K®©«3Q]|(W/|ƒÈûœÑ†§I®ø»à#E>è¸BäÆL¸n:mL$ÃÙ¡şÕv`™ıKÒvÑ„±=q{4º¬EöjO‘>™sı[èÊù)Wm6Óy=ĞÆÿ² †í¢tŠ'£‡bWA¸_Ü_nÄœbâé”JĞBıE2â$Ûv*ƒÀµ¶ZDÎL…—‰XfŞ–ûŒŞÕ¥ğ§(XlÊŞ÷¨8h™»¡Í 7ù¨ôØ`yC¸rÕìÚ½\[u—Êiaò¢-
Gçvúa
ëí"æuåğÄ"¥Jü©k õsÍªÊêU!ï8s<ó<„·-áE[	s÷«ATpü´<g¬CÔsñb2©BãqÖË5¨J5 {L¨ßÒ|òvåÕ)t*yÚ¿VÕR\eºø>AN)åñr^Ó_IpuÎ8²š&Øoó!w
£Ğ¤$œŞ.>&_„»Fö Ë,&w³
³,ÕmÄéï¿´W­D[ÏÏ[š7
2)8–%£doa²#âŒîoÑpüÚ‚¬7rèV@C/‹aÏÜ†W»¢O?g¹í1šoÌÀ@>2`©XˆeéÙ®tK9üƒy7KÁeì*Ê<UX®Ô _3_uvìÏx#Å’˜™&ÊÁ*¹u¯—®CÍáğ“á>%†Šè
gëK^M\³öVX$9pÒ‡T‰züŒß¯ôáñ¦_-lı³Sx5ÏbO–mg•¶;ö»Õºu}ß[C±ÓüOYÎízÇ‚<,›ÅTX„J+8¬mç„‘ÏİÊ·75&iF[*ÈH¨	ŸCQ"Â
jwÅc‹Ş‚ßiÜaZß‰LF]úO<†¯{.ƒQ@Ö†¼´#C Şaˆâ[iÉ¬àC%ÇÅì¡ü^ö-"D^ÇãÔOÆõyšô&=|Ğ¯6©	§[Ôúò»£Ñ© d¤ñƒ¼Ë¿é’Fza3êN &(‰åğx«)z+8…Ã+¯9JÆ~<Ö7£'ÜiPê:#4y:Siô±HbT•Õ=Ï¯;ñE:ìı°q*úpbQí{¦a†—E ¯B¾™bm¥I±÷À%Ó[ ÚVÿ¯ĞSYŒßA7ÂİIÈ«ZVeˆck;´ÄÂ^0A…¢s]b¶˜*Öì³HÉK~Ô¡d;‘9`±Æ4¨æº¼–‡¸.Ys/å0e@òÓòƒUòÛ@úÆ|tk…>ã€İ:Ï-Òí[­å»¹©“g%†“l(A×c}]ëµß œˆ„DxããÅKjú=n9„9<^&H½›|~h1 ½uÿş àKî‡N@Úç'÷vñİfà±€X§ÓIÁO8Âüy&*âª¦CÁrh0İÈ[5Å%q<Õ?–îó¥ÒFò²ñ5vùƒ@üJÓ¼Ğ%ü÷ˆñ¡$=ÒE}É˜]ûƒn™Óİ1\®1ßÍ+ô1ãŠÊ¯/Ã%)nöPbİÅGâÕŞüÃø½ÍfãÊ­ÉÊn»…«ôo¥Ÿó˜ì·ĞîqñïĞ9Õ¿ˆû–gØŞ+M¨t×‹œ+µ@Eâá1Ô„µÖw‹õdl'Ûrâ‡#¼>.¬>¹€ZÿÉ¤Z·œ"›ÎîLHÆä2sÆù2¯Ç›‹®9vE]Ù6?bÒ>ãš=îr
ÀZ!fr·ÔKı£‡¼:€Ş–œo‘íûYd÷òÛêPÊÏñŸc`8Ài$”,–„²„Û”wanœ&V›fÙl¬ëHğQ¥6@†şêÁ	Ø×˜§·=ÃàNÇv ›Óè*S£Y³À"ß‚g~*¬iv„€FçâüDv	ÖAÆÎX´="§©õÊe¡2r¢É¯¤Àd(	 .smœùŞcDÉè    k‡´KzR* õÊ€ÀÒ¼±Ägû    YZ