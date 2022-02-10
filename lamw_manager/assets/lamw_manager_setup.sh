#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2111547938"
MD5="51000bdf1ae2b36a243327ae0016d1a8"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Thu Feb 10 16:59:30 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿeY] ¼}•À1Dd]‡Á›PætİDùÓf*ú[º»»¤n”|µÉ(Qv°IòÍo¤; ³ÁzuØÖœ5úßÖ‹³ê­}12Ltñˆ"~\Ì»¨è‡¾-D“W7àº+W@¾+kï’—Ii]._gİP‚û
•ç³¸Õœáèë 
gØ,üødi™«/ÒOr¶M‹P8®)ÎjÌ8«jğĞÏ±PŞ…F(Â*k½÷»rDy^·´® µÑÔ8àáÚUj&Ö_-å¼ÙÏô&iñÔM0Ò/¢—l5ƒi@#OÛ;®.îzgC6Fšá´Ã÷k÷¢Üñ/işà%Ş£YêöÅ¡‘×øîq«…]KÊØâ”ùCÉ»Âî§­ùÔ¯cX'‚B8¹‚*L=Œ´±2¡.zØ÷âöª§Û°7[ıQ•=:Ì;~à·Cš@ºä44Çw8T®Pq‘‡Ş_8Ì¤âvŠ°5Ú@¾]à;SF“®8éÌíÔ5Ìâ ËLŒM²_Éèäî¾äu{¤]öÂ*=ƒÅJÌğæÆ‡¼¨DñçŞÉh`3¨O¨'K`HàöÜQğjQÁDR™×¸)­£Õõ<ôÌ±½!ù
Ã”|f´x»ğKXV$à$ä‚ØğSåF­5˜:Ëª'˜„†Gçh'±K]F!ç‰Ö…*õ@®%jÌ}±£§%Q¡ùR¯Â¯š¹İÚ<îù’œì£åÓ¤;\LÎ6mí¿ )Áh¼Utsör6K¹7/š¡4°ÑYxr^£ƒumÙÉ´y’<îÓy\Ú`Äy,8Z]UCö­cÁç`1å&1”¨şc…©µ¹“ZWdŸ;HZ‘²ÎÜG9ç3ƒåxö_OÕPA¦w$¯I±)ÊúPXûŠSÔŸ¥g‰W–æZŠ'Ö™û8¿zùïeeb–®:öWÉÏš8¤n-ß5ã©Ã\y:ş@Š^³øò‡Y`#~n y†¿!GdX«Æc?şêP‚ıÌN´XÖúUÓã`BŒÌá–WC=µ;]C©PeÅƒöÌJŒÖtSp˜·pƒY9Pì£³€¡q“§³¡¶¡ÊC+Æ{Ù›÷#g0LÏDEö­ã§Ä‡¥ë®’Ğµn£Â‰MbÙPYo+‘7ÍÂ²ÑwºÒè'¤Yü¶¿&¶€sÜá §ô3(hÈüÕ•_3HÄÎRsÂQÙFƒÈ°ºTÚ®Ø³—qs<µ¿¿%có+.Ü—UM½Ÿ…™K£×-•×ÏMNÌ¸yª96Qæ˜å
´´ù$.¸ĞªÎ{è«µ–øßD^Ç•,û•Ä16êÃr’KÀt®›æ¤²Ïn¤¸œüÛ¸òª–v]fáÌ?|V1b‹—E—àÇ™&@ş”‡úKù‹c0ÒmváAaÊÜæ§2¿2=™J¤-*—R<OÌğ-ÈÜrìø¸7Ù-¹°ìĞ®<½Œ¹t‰±bş1n¡‰ì—›Ø’-§Î©gø¦lgÑë«å+Ã0Ñkt~y¶öw˜ÛD â‰UZÜ…™k•³’ÚzĞÊ±—sù'ÅZ–mt!çE¬¾„gâ_¡¹¸yYvBªÓ~#Æ0œ(§Ø=şÂ¹ŸB„ÂõåØ\u&;Õ÷K–`o]MÛãí8 Êç˜´‹q{je¸`ÂâzU„4ËÇjbÎpÏ‡Ş´ŸR_öQ÷™I–:µ”ÖâÁMiXZÜW WßüÅĞ¥ûÀ‹}’ò~%½æã*3]3G¶ pãÇbÔè$`¼0†SXĞŒ@‡±îÃW/_ë±îkÎşw»hùGK?¸È5º÷tı~íàÍ“>º"±Fpã¬n<¤Ë—şÓš¸ŞuÓË'VA%¦øÎy­ô£oî=8æEš2ş éöØ?mßš!ÿº¨ux²ë¶ ¥ºS6 Õ·_¡j="=Ó„Å­>Ï¯1õ	…]ŒU¦ö9NRñÜ;ˆW]{ÃŠ^BàX¤«Ì[¹Dëª±Ş&Y›ü[ºw27ãÿ=¶5dñ‹²ÜÉúuØ^ÑÃŠÀıÛzE5*a˜Ë=ïé5)|w'OÎ&V†&tÊµ/Ô¢ `‘“ú„¶gY¯ÀAóÔƒqC9„/ØkÑaış)	™q«</×ƒ’@A	%-Æ3ÄRmú@uÎY¹Ø=ñ”8¾4Å'oü×.I€6ò[@fDéşc[äèÀıÏN° Îš6òÊ%ú=;SËˆ’oÓš	ó½aFáÄå§‰§"Ã/à£“ğÈ–i#|ŠÊ©X°„™®1«»+„qó7"Ñ»S CËóq´yæH+İÔîü¸¼ÿ Ò©b;<@½çèÿk·úë”–üˆÑA’u¯±–¡'÷(3:6ÇÅœ; S³ ;è2ÀCOÌy&B@Ÿã´^ŠPC˜-ı:Œqı|œ&”–~a„.²aÌ¸ÎíLzt^±òKñpS£w­ ]ç3µÌ­…Óa‚2aÀ¢âŞÊ?m9yS¼r„Á_
ÚñM“ä¹ÔKN)b…_T‘ß#\ò'³L·æÚ½É2Ø‘•Ù®Y­B˜ÇpAõòÑ°6É`Ç²äm…õ2ï?¾˜,é]k# ‰•  ½ßYGˆvÌJ—ö!è²Uƒ›¦İ eÔºü»R|ñç‡ŸÂ!åËlâºó´xçµß#æ4¡ª¹Yr©lk]‹1ÃXŸ™`˜Çª[ãohü@sRx‹‘Â•“8Éìa9òÄêáybKöé6¬OVLcM¥[Š’¹L˜ì›Î¹›MƒiƒëËÒ£T%İ…C{S‡Ş0€–—£´",QVï§§¹êhDšAs}\P†ØvÆDÃ`r1—d¢ÉÍ`ÜUã×z!aj)ËI IğÜ¯É+õ+ÛLgeÑ”±‚õ’‰Æ&wCÕhkfgV Ÿrë|»À‚
äÕëf)êÂ¾]èŸê ŞRWWA;oî¬qß‰l™óRøË•m§»É%é±×:{Ğ-Ÿã(j5ÒT³êUˆã¢;–cüî2s‰À^UQ!kVÀ©¸üMPQÃ¸wåüïaÚs—	KU²™C“†GDBR
¦CÕa ˆCøÚ‚Væ3r™KQ7î¬§ßÕ·éY¥ëÄgÔÍ?`5ÉßM7í'îu ±vÉÃf”!õ„X$éA\L»'ü>ÕN~ä1êJáòKn¯}â~Oh¶‡äi&å~>A<wúBÊÎïgg~ç|ÁkÏ9wôû =»„Æ«!¤â¹]¦Q·d
vÿ†®Ş—s('Jø¡<”°¤Ø¸µºQï8h=ÓTªãõh+ÃçæÜî$:Ê¶?	İ·¼$ğoÆ6æÄœÅ·îD§`G†Å!åú<²œ-İˆ¹¨:~sÀF,ºKÈÙ¨e¤}‰\‚ïdK:3½qÇÔ–Y•qW*ÁÍ?½ÑKœ b£f\ú›¿e7ûNê£aÜ…2wfy†h>­ê?·‘¥kó+õkØûæï.‰yÉ”pì½–c¨U\_XÀ™”bq¸Ò![=ßsÂ,™Oş’F„ğ.A8`":pôf	(‰=9sj$2ß:^Ùërï!£Ù¤‘ğ„z‹]´/ÉJ˜µ={sÕo\5ĞE¼ÊôËå=ƒ'8ïF;.m¿­Óı-:Å¶·ö­¬º,@uç`ûx
èy%Ôş^~ØJÈx'œ¤z”w4¨&™S¤ƒ¡‹NsivèO»’Ñ¶©¤ÇÔÖïí¡õãEfæÅ^¹`JÉ½Æ@GºÆ;²-®O;tœ´ •¿j—’à}pÀdìÚp#¬ıSB’ãS$±#¿vSùÊ¯”æ²È–Ì›Â1t7BÉyÚná1«¶E$‘VYŠáóqØ–i„øj:ZÌò¼²µåªKşk<g„5©1	4ò^‹ñÛißÓå\;m¹!¨¹>ÉmP?	hB#2¿ûóêfÆY˜cúFnjÕ§*À²ıi}.ƒ9©ùŸ ØX93 obñäğ±âç$mŞö5-O©»Œ†¡•¬Eaè°\:ÁV£Ê&€½€0‰4xœGŠò4'%!
¼lëh\ÄRìšJGMµÑëı«¢… Uw¾¯úÇ!¥ğ“4>İĞıÜ³ò4bõ¯å?J¬  é.Í6©"½ırAÅ*•1
„#]¼\)qPüõT‹_:$9c%åAaáå8*7œöÃ6˜Ï^üçêÕÖTÃÆÃ®òmtr±{kˆˆ—×{n&_‡üI/ ‰˜çÓ¼„å·~ûÎ3xIòÜXäjD;«ÑÌh gñ…ªa“Ô
6ÇÛFÊK
KæÎ|Ó[W¹$"~íĞV£§ü~7‘Dş&^ğµ¿úèôÒıÖÅ4¿‘Úİ‚ÚãõÏG?æÑı]3©Û(:zÀa
¿»‰¢Hd%¤ ¨à,¯¥„#mÍI±ğA~*I{÷¦†d™Ô2ıš÷¥ålDÉÄ¬ßQ..›Ç¸nE°µÅĞ¤95";fætWâDÚÄ÷¼Æd¸`:«±Óx™C™eƒÓ!ÑÆìe6` ›dQCTPLğ$Exƒ\»YÌú­)”¨g"#|_„IÍ"«”¼k:BW?ñüáôWÃ³”œÒ‘²ÇGg0¨¬¦¥;¼–¦
Z0<xuÁ®9iE»ZHí©?éukğ#ß6}¼Z½e·P ¯ş™ßHªÆ9´WùtVİÕµƒB@êLêmİå»r¥Süî"Esá€+yˆ…¢ád&¥ ,ÀĞ9"ĞBñ(ñÕp¸†ğÇ,ü„üAü`ıÉÃÔ(›Ñ¤`©åô{-ñÏb-à7•Jxò@ºÃ:…6Ö6y†ï,4Ë¨‡æg˜æpQ“ÔQf:ß*~PÑXÖ€—ë×úÖ÷.½İ÷£ÀÒ*ô>:{ª£ Kû‘ÛtüY¡1mì?uĞÆ$]a0ÿĞÓ +HÍ·w¡yo¨ÃêOï$^š!Ü[Ä¯ç/1Üğƒ8²T|[³(ş@&«<ı	N˜7>®ÂV~~™÷Hœ¾Ré\qc‚hz
ˆøW{(;uHÓ>ntŸcúît6ûdª@lä¹)£íQòèbÜF	ş"}ÂÖâgßÏR5DÄU²¬G®‡i”IpêW Z]PÒûi‡ÀÓ!.§–mGŸÛ{„?F4?Èú])¶*Æì¸“õƒ÷&sH‘¨õ“7ÜROeüW#;"Îêë˜»˜1P)=ÙŠç)QXw¸„ÓC”vc¶Ş«îZ=WÏ±ü¬D7Ì¢´âåÖö=ëÄÒÇZÏÏ-Fr<¿í©Ó'ğ¿*Ñq!¡8İ¤§f%ŒÆsø2+–iÉ?›ƒòÎm?×4‰6¦¿©C)IˆuaVÄ§£ßuŸçæ âÿ.¢ÔQ$d}ƒ‰±«VbØGÃİ”wÚö…âpRúøûc©Â¦À.Ñ—k{]âš´\'ğQëĞ÷\UÉ.p²ğ±…âÃ)ÔÏºî¨5ƒ;3¾Ã6ZW¯†¢SLæùÙgè"cüAnwKÎÀÖX–”ñ‚ãğ>ù_: -ÕèĞÖ‚×6ámú§V‚ÿP…-ÔgHm;7vI+?@’@¢w)¸pv?ÉöOwtW3Üº´{ÿØú?[E>‹‡è“’¡Æj„Õ¦óŒû¡<ŒGò‚[¿W4¤fÙO¾nA_’àv¬³K­•{]3³××àÃDöŠpº³²gGZ@Ø$âĞ™E\xBgê<¼7(šº|İ[ÌR#§
‰ËQ¹î¤fnšÛµXRâO+¾D·à:‰^A´ì%É€‹¨w.M (,-y«ÍÎ…™:Ô%ÁM;$‚­ËÕ`é
u
´·¾:Ú6âÓXÛˆBlÎBY qÉĞc~AZ="?oÕ68dİË†JPˆ¤l`›ÛE¤c£07e êJ{Ğ×EÉ‡L<|Azª#p•·ó)"¼JÙ¯g< iU)‰ªí½é¢l» q´¥¶ia	£ø´R’° cxıº±µÚÀ¢.P+ã§Ç„m¦%Ê›rr;¯¢ŸöéXò©gª©ï~ğA²ÚáŒæl«WWá 'ql&.BWF_åÇ('q‡°Áò8hnZ°ÒäAp·4é6œõŠúLg6ÇèA]ç­‡ÿ™Kİ’6 í¼èeBZúÕ°tR´İR0¬ã–]GGË@jzoêréÕ>¯[JÖú*)…Éç×ğ¥ÎØzÄŞRR¼ó§hÖâû—_]„97‘oß`ŒÓÚÇºioØäİÁ½[r¶ß=àu2R—oúDôÙ‹1)&{zÏRš2”Ê¥úõf÷şBÛön­¥ XVÕÎ×’^İ/H®À(K6£~Ä%dMH6 .D_A“+Œ´ï¯7<1Âc÷‹m[åÀGœö¥«G© %í‘­y­™u7Àjø:…4#8Ÿ	Oê—rz!2È©Ç™TŞì>¦â((ş–^(’¯YJ%
³E™ñ— ’‰J=PÜHuyş9B½:D"T¤æÊk}?“­Eg-´tßÔz}dİÔ&ôj;iß1êë›Ü§/fÒı&£„ÿ^;ºİDºà!ˆqcª”ùi–‹½jÜ”	Mğ]p¨$´bROµWJÙÀ=ì¢Hxé_ø†WP¹&öèD RSiFç&d:1Èî2g¼0xÇR˜Ï—Q ¸»äıòÁ²4[Y­)×ë·Ò|¼w†@l9CÅ’?ÁDå­UŸ^La¿vÓùr¦æ‹ú&£éèlusX¡Æ@ùR|i¶Ğ¶	Ôeİîa4ğµ~¼Ş0Åwfa¦ï@şG¿˜Ë¹Âö©Ä«î"÷3˜<Lí‡)wñ Ğ‚ü:tt ‘€>½@úÈËĞÛy ¯øhXÅ)TB=P•İ‡Ûm_ŠîëŒô\pÃE€¨x
ñ€õlP9<n¤‹u¥ø–'ç‚ıÈ¹CÄgpˆÒJx	bŠoÄ(2ëèÏq¡mÉŞaÏPtÙá•ÉQ¹•…™!HDé(›ãFÍ¶õÀ)”	ÙÒ]U¬A¹\¿û¬	ÚÇ¶,1BÇ‡FØ.rvÇÜOd¥ÍœæÄ’ Î•ÎÆÑp<œå¤$’<fõ>ï˜#û%H.6ä¹øÓH”Pº4×üReˆ7•Í'ëj¥RV\yî$Un+p1ğrİİWç:–ì÷’–^ Ü&ğ±åƒ³Qvì…Ï*¦(e;:.±·@¤«_B¦h'y&œ@½ ğ÷ãØ)„rªc!‡zN¬Ö-¤@}Ïwù£+›»mG&x×8ád·íÂİ¾u´KÌ½
_ã™®g7ƒÇÇë·KQqıÖmÿÊïÏÌÚ'
ÿşá>¿(ı¬Hš”ÿ¢å>ÍÍ ¿·d“´°S6€¹±†ŞÙpØ†‚N‘ƒrö¤+“ÚW9îÂChùZXó+¥,³…ØŒ¥Ÿ2tKeWVl‚ı Sycİ ÷‚k‹“x†vá&§·»˜¸H½)­‚ŞCsÛ«z¯ ½¹^ªUuÔ/]JÎô°¢à[á\CŸVçæBÍ jõ™KY¿j[‹¤ôûêNC@•cÿü~á{©èO$ÇR¸Ü·¡\9ÌŠëãæşWB9‚`î†í8] ³@ŒgMfôöÜU¹\ô
ğ»Ìr¸¤ƒà:’€€+Şä\yÈ¯F†º4¤^ı1fûëqPü×6OûŠ£=PV™bè/îCÄş”vcX•zvêäR‰0`0ê1e >)™ÏnŞvÑ©“æª'ËúìÃG$:|Yí³s%¶R“Æ…[ø”9ïGcôäZ¬mb)ïû¹:Õ”ëÌÅø½AÂ¨˜~­ ¢·É›çìXÓçÿ7v²a52ß"ş‰ÍĞÏnÎ›WAxéÀ˜bÈ!ÆğÂ/r Plô„—¨ Š<=ƒôí,ò°)ËÑ`hŠ…¯n¹pE­aMÏƒ»©­eMÃ‹a‰•Òé»¯[y ÏaÛ‘QÛ|çPt•WŞT‚Ö´k\hW_eÀ©RŒäÿ­n˜ßZ·züt9‹Qd!š}Ïmm8Ê(Şb“İ¨ïäµ•Œo90ªslG’X¦^êĞØõÜÖàø.Ñ?NñŠîÎ¬ÑCB›„*˜<ëÚÉÍ8ãØ—ŞU5Ò´ÚÉÜDÂjî:í×{–	œ‚÷5§æÜÓçgs±ö;Î„Tz—í• 	¼çßĞ= é+ƒTènö+âa^¥sdáİ°^¦_û)ª²Š¸]Áí8!Í9V?Ëj¤U?00M¢÷'ÅRÏ†Í¦
RI/ÁWAÆÅ/’Ì°ıZØS˜[_$pFø½Ï.‚ur˜ |ÌLH<§ùp³©âõô
PV €š&íİböÉÚ÷E&b°–æ¾§ùlf¥yµîÓ¿¸L|_Ä¹ø4bWó\~±äÑólĞ”C³pãé,Ğñ‘<j½_
Ù£å°¡=óü,T‹›pšnÃ	YÅ/A]<»çv3Ou©æR«Zbo:\Æß’6æFë«Õ»b"_è+­\7Òd5K#«ã§Yƒ»Ó‰=ÿÒFûuê«€^,0W¡®ó3ŸóSTô'€4öÑ‹I¼PŞVô<Ñ¢¡­”Ûê”rõœNöLŞzî45>¯,Ó‘2Dx!wÉÎéYúj +Ûãİ¨•nŒ†ì±e$2Ìğ ™ïœÂ/È½İ—Š<­×¾m[i¨Ã¡pÃQ-ñ†:‹¦Ñ}Æãë²ïê£\7©A+º;;éPß³2Ú»WÕ:ñ™÷é…<h—yzHJÎ[xâ•±XŸˆ 8cAY¬GéãŠLåÇêê—ş¦«¶¢XIğfr¨“I	<ÿß4L1Kõ#ÇŒ$Ã•NáÀî¥æ™™ˆ).*˜á,°¡µ¤ø~Uéâr¯¿pˆ$e—Zæ€éğßÉT"ø2¾Ç1ú·>i2Ï´i‹ıg¿Ò2Üñ¯ìN<í—¶Û`]aß?‘ÀÕsê¦+ıŒgŞ!î	Dı åå~%Z·xwˆX¦Q(¥9übÌ¨›Î–l†ÔşgÖÛ k*Ky:!Àùûèåï;‹.MÍ­iUÈ0o‹VbjwÙşï!À,ùyŸòU¿\Ç[¦Fi¦Ác ÂuNT‘{š’ m dYëßËÚìÍ+Ab¸†Ík÷h‡ŸÇ	pÚD«s‘.EzzÇêU7qºãíÉBwAõêµ@%èbèXÊÎZç&¨íƒ•?~.ˆƒ}\ËX²j—3Ërìé¾'µeq)BëÑçâN"zË-ûg´"„ğ`!š“aì”Ñme{¼Œ®6‰ı 'å •Õ×&Ì^š‹4,ÁªWM2X+M0¼E0š ‡ÄäïpjĞ&†ÒÆ©.àê(]3'¯óÊ‡àğ9¡l_©õœ%éÈ\ov½—ÂÄP’ùıø_ğ:\l2“°  Éë™AöÆˆ$ÆŒNÃ“™áÀÀû (Çiqo:X[ ñ›Rµì[µÉ@t@ùïç˜Wø™“Ş¦0>0@[Æ°éR
³e3ÕÆg$¾T·~OîÁ4Ê73¨sßiz0ÍHë#»K¬‡;ÓâZzkïä0eÅpsÇ¡q”‘¡¡2T+“½`ÏvO±õùlŒ~÷dƒ|·äöˆG|-	éá•PZ`©C¤5Z…sÉfCõR&Çª …¡ŞÀîàV#`cİ†‘àÓ$<¹;(“5›¨3s-uV¢†ˆô+Cæ¶#sæœ$ìÍ/5Œ5~Á©·… 9£4ƒ†5¬ÙW×Ûqçj·ZoD%’@´tß	k§Ç×Ï›³¢˜¾Şä'ØJæŸÄãH<Ş·Í»SŠ‰!„rÜ°|9¦,N1qAŸß–_É Êé¸êïcmô_RbHSŞpîrİsij]	T%’Ù(¿ŠVí íŞrXó~YŸ‹Èö¸NSÌÇ–ÕP™ji'Bjtª®(ˆ@y¨9µ oW¤,ml”º’Îô¨
iqóIŠ½}D2¼®ÃÔ\í±û!Æì w\ÂŠ¹Ú•À
]¾É|'¤Z‡±hæ…ñï¦Ò1´•6½…	FÒ¯
ÕÌ_ĞH¿¢°cÂÜİ|Fvı8²¡tˆ±»bgMhÕ„ÜŞ4a½16Óuô×âí²Z*ò”W*ªxù#t¡mBVitr®"0•eI¹.]Ê6r,=TŠdŸvdéÜ*|zB6ĞM6#6-8¡T¹4O‡¶d{ßO¼Ñfå¦'àÅ€¬û˜H¦äV·=f~òÒ'ˆä ‘­ë¡~zpy÷oÁµò=>ûBİä‡«]Í§{g<ï³§3èõë¯ñuçgiTE9_‰&ˆaCÆr–k¸kc@Š}ğÎa‚©AÏ²`œùÛÒ .wÔ ªò¸¾†ÍŞ„LÙJxC]“$e÷Ü{ÂÇZl®Äsyi}ß™k”ñÛúÊÙ:Û3T} 3b›åîèh¥iá¥(„–0óØUGŸã‚Ò€j9Şd¿°	Ñ$ÒˆÓJô%¢ÅAõmWÀ\(¸€ÏñMöYÔáÍ¬
ÿ/2ê$rŒfI%Ì÷§
‚›¯ß–ƒ|“è^'P¶Š¡XÖû%Òy’•2Ò4ËPÍ4—H)ÚQ§:Ç½%ÃŠµ*kL”R­-q§ÉÍ”U	n¯O³o»ÏÒ$8.Y@„oŒ×ŸÌÖ»¼Åü¹Ğ˜ˆZ'3 óF~ØÊş¥NÀV§c“²5%äÑÒKØ4zö™¥÷ÕÀ`Êƒ¥|bß

k´T-»ÖŠ†Ò&‘|ƒ©"NÌ ô¨ö$´‰*^ø	K—?wâ¸õBÅ|¦Nb)ìl‘U˜Yr—V
¥ìàÄÎ¸²¢tñw;}éŞ”¹@vse°•÷0šNZå…şYßÚğ˜I±ûPp@ß6k2	ÿ˜ğf¨Ñ‡‹í…zbõ’V•Uœì¾æ¤äãÃ¯d¹åjôlëüŠ§Jğ]j/oûnÌŸ³ö	ß
ÆˆµiK@–?—¦H+øK¶¼àÓ©:"¿áÚ³5».Ò[‚™µ-*	Ì¨=ÄBå°W1JëÎ&yäãIz´û-·Y©FhÃáÇ¸÷HÃDîÒº53½µ!Ày'Û ²Ü¦f~ş#(Š_ô X–!k:™”nP4¼Oğ<½ÔúW{9}†8­á÷SpKƒî[Bw"ËÄC“Ğ÷6„O Œ_¢&mİ$ã™¨¯ÖR[“Ä‹,'RÁùå=Xæäÿ‡ÑµuÆ ¦ìLó©Ø÷Æ	QË•(ˆå>·€¥»8[d9Î)Ña@ğ		Ïn-Iã¦˜	,Òà®MèT\dÌÉZçQö)4b°‡¦ƒ=yöˆ÷ÜÕŒé 7OéÕ¿X0,½ß+P{U@×#Ú‰QR	vé’lAIgÜ¸&4½“+qİM¥›õ–(‘kŸ˜ÒÇ±òéV qëŞìÇ§s¥=f4Ø6jšâµõPÛœ©Qû %¾÷ÁÆÅfÙ¡ìoü±×z(ê~»Û¢OBrY'J–òj‚Şkÿ&_”œ‘%Hæ\&éïöYy#c8?4"×µ¼v,ÅuÌ|<.qÍÈ:pÕ‰”y)ûŠşë§•‹j\Ó£ZKĞí¨ßZ–Ü§”ˆQÔÓŸj`§x!»HIÄ‡«EÈĞÉ,£˜…DFVÚßb×sÕqMUZşÒ­úrÀ–’éék°gßnz?³øª,ñp±Í7¾‘sÒeò<ºÃúW0XÊ^óO7G½/û˜ÏÎzæ‡<#3ìS©Y`†ÄæqÖ˜t­Ó
³3Ÿ°kx&:±¤P.ûĞJ4Ì‡•–J5¾[>èÃ6(ÛhÛQ\Ai¥tÊî®}xèşfwµÇĞ³Nx²XZøŠr8êN8OÍÓçÔÀuÏ‰Üâ¹›C´ïè2‚K½s©QIô8–ŸÂùL¦ıZE’]¨ˆJVªŸ<„’×$²Ş«¤€tÑo n}ùü¥Ïx{Œ‚úu…Ç„c`)ÚaÄ†	€ÌªÛşØß¦¤Öê'›²'“2§pwòşÇÈƒ¼vJEIpG xâßD&êI2ıïAWJ4N¶½ºÚ`? •Ë|ÉdGÏÎJ`UÍ¨Sà@õûïÍ‡ªt…ıİ†wVd3™YüªÀ®âav´ÓıHc­"“Ö¯PÒ¶¯‰ ˆŸ¿Ğ·<~óÎ‹©+µ‡K›ÅÌ>>çn¡©Ñ-cúûÕ1×Ñá²n¬ß;uätxßõ®¦>îã¼	«ş
Æ`œ±-Ú_4»sæŸƒXvR0æ1P²Á®£õÆd¯¾›—s°›ŸX2ºÕ?GÃª-°J o>C¸®Ë’åò©ı
ç—Û`¶×~ª2ÖÀıá@)ŠÖiê‘!í-ikv>/ĞÆ¸
	ö<†Ö®^ÑdQÀÙòÖ¹¼ít‰×áüÊL•·Ål3ÁYØ–Â	½=Ÿ¼wwç±‚“—?fnğ’QÂhüjJT^æUuªğõH¸'m¬Ädf’zWä àJ¢áİ­*zT#5ÜSƒ];Õ!¶u;ÓáXC7»Öè—BmŠ‰‡åíLxQ¥
u„Ñ¡ÎN=µÍ„}õ 7\O<×Vl‡Å!Ô{ë¹D„‰i^Kb£ÂÉ#r{ôöåÒãÚûÊRµ÷&ÙÚÅ.,@ã"–ã÷4JĞ+ò…Óo’Qä¨˜©f)ïˆ#v'`Õƒ lgóŸĞOã40”è†Çz¶*pØjT°9†æNa~ï#AÙC1ĞËOè¥ŞPOJ‰àc´wtM/êÆ!l14Ñy2§ÄKÒÏ9Œ£ãŠA&èƒÃıeh˜?z™ ï‚ë/ÛCq×}Æ)Nò:4}8æÙ0k‰Å&	²Áü«–fpg-bgnËü–L·A1ø8èÆ¼^‹èLê¯dƒÒtñÔƒMlD¾÷TÓ\OOÈø¸DĞ?[5™L2òèíÈ˜-–Z“ÜpÜ+*îŸ#Ú23.âüx“h*áJù6‹W—bá#ôáÙ uÛg³İyÎR
&§ä{7ØiŒßu;n‰Aë7an§ï&æ^,Gåó~Œ9­9|I· Í×ê”¹B®P¾J+uÿ”íldğ?šÅP7ûiš»ÙxHJC‡œ$ZŸX†&êoáœ»Ğ×Ñµªã\˜Ñ#¸»Cõç(Ó• UxiJ·¯ª%%RO>Ş¤cVœÚ_İüöØK3rËr¥-R1dœh$ÖâTÍDŠnİ»3hòufIEqDçegÁ·“÷N,*ü?³şÙüP“;ôS CWlÍ°º PÓNE— B(Ôôµñê6‰øÁî?S>¨Ço'ì±ıœµßÃİçŒ8ªZúé!Õ¤wî‹”h"ÆçÍíFÅ”²Ç…ÔS£Ï³ës×È7XnZñ@Nd•KF®ÑW¿ÿ¯o6ÙH:ü_(ÊÚ,dÓÆ:gkzÒ¿af1Ó(¡Kvp,½’Q{_àI…ä–&Š§aŞœA+YêÏÛĞV¤â¥Úm¢Ú«ÎÜ;éÏ¦9Šf³ª»—ÌÄºøôIzç€.=VI¬í­ÔL-¸J‘¼Äd©3­A›Öh?#¶Ãÿªn¿$ï<ÖT«j“¼¹Í öùÖ0âËŒöô=¥ïD5MÀŠ{›tÁOzşaˆ‹Éå6ß¨²('mÄÈï·‰èŒØ^QûòIÌ·®¼Ï	oi)U¬,Codiÿ¹—¼fTE7İj<á†OurÉ&ºİ,`!,›­¶EÇİ•ÌO³,@ÑóCUÕš£èÎĞãúƒrJ·,Lşn;}mJ²"á@Ö±ª”hºÌMºhƒ¶ÚKÆ‚^›¨ƒ|ûÍ×‘ûu{f#½kŸxZÂ*Kô}YğÂ‹l‹ˆù@¶’cÆ‡&EôU¢;p}€Ô.‹£”ÏÑYab0o˜ì×KısKıªõbğ‹Ú}QVıls,cÚ¢¢ÈÑ;áò™š.oyRf¬¢"zSmy™GÀ­H	nßÌ£AbM:ô ÛÃ±A÷¨w2…~RÎ^g—Úû ±š	+== '™şŠ7Õ#Õ&¬íÛÀLïà
	AVL:%=‹‘ã­C`ÖKìŸ¦S÷—Œ”&=¡:ùL6çÛ§$¦fÌ(™4!¸ZGí6Üy¢W†éà¯mNrëø¤ˆ¤dhBÎ½ Ş–ÍÚzCi¤¤ŒäID”ü°J¿6¦uüå/.yP³¬SØëDÖªµvC¨
¼&ŒxsìP1sÿMÑk
^d•3Q—§ùx÷×7x.Wv!K8ªÛ/£¥†;Ò—BG‘i—¯NÕaÊ³ÙÑ2¨ßS¼X?ï1€qs	z‹¯ğ›ÈåÜ{vâÓ™ÊÓ™¢öP]hªÎÕ_0ã{­$§ÛØGòæ »¢Yšj<Et0"ÒÌi~ùà~Æ8ÊxnMqöB×z&÷>šŞbQû˜ ¹)SQèE;CSS£ÖÏP3PK±çCb†¹ĞêÀ’~VˆF­ŞªPˆ@÷;"×?>eetá8„ªÆÆ†MÎ2İCİzø«I…ê°@‹0®}³—?[à¢æ¶@¾—y 5tõˆù”‚3ß9Ø.¹ÕŒ>´KUôõ†¦erãR—©ü¨ŠI;¡ÂİŸ˜CW¹ôDq1â@ó‚©¥Â=omHÜSˆ’Æ…Geanlw§ôšæ…OÏüÓãò¢îÕi¡ĞGÁ	kƒ¦ø‹˜-—¨Ÿˆ¨F8m'üÍé'šAŒÔ¡v80¶ØI/æç©«{~ça~7ÖE0Í™\–úXSgÇ,‹“]F¸léæ³R‚íÖÀ)!<o²†³\aĞÆàöË}r¹£ìû¿pÀ×ª ‚»”€MCóV .˜˜¥œn·\Ñô'R,OÛ@Ğ´†ƒüP¡sQíàº£2Ó#ÊãAØƒ ò İ™µšı³$BÍ&
e³*üæŞ.ñnsµühh 	ˆ›œl©‹r‹§A  éUoÃè«ÄÜl (Êçpå…ï$ûOi’Ú%7–ù’ÁÅƒH„|2f9kcY^4¯µe_n«0ì€F\¸Ç"ÓGi4˜µ“C¯úÔ5 ‰şt]2(Ö,·”òïS;F±û ãİœ\%Â:²ù›-F· NñìŸ¹÷kôĞáğ?÷*ô¦†ÇÚ>HÃ]½ãÕÚeDãG]¢~u¨D€~»©õLƒºÆûÖ±í—ûØ¤‹Q%d¥­¡Ñi¡1Ó¤axì?Ô|:F-,>M Í/’ ÿ=†,©#Z´n®4/¸">?jÄ©÷+èiÉ:# MøÚ†b¯®öÎ1ÿ.>ÂõŒ‚:?43€)Õ?l¶p­Ä¾J±Rì°ÖãıuıÏ!¼ï¯ŠÏ}ö­Q	‘‚³WU)_êÖXƒÔo‘<¡­¥ü¿/j3½_~´pau¶Ì·DÍB«Æ+¢Ú0mt õmI±%«ÉAÑY†Óm ”uç‘sH€ù]còÁ†"jˆ‹ï’”ğ¦Dˆ\#Ú+m şÙÃ	ú=ëg2Ô¨#¤«²Õó›Z•g8öiróÁ¼ˆÕê0¨–³]İ‹öÍ4†õúŠ/÷[LUN‰(5™Ø—ßI4"œ2mm*~O:6Dßp"ì§Ôõ¨|RóÍ™¡ÜlÌ?g:¹òáäMò?!–ÌgïØõ¿~$n5íİ‚~nª…Ú¬b £¥1ÖAùê¥´ÏŞ¿‹)|«Áô¿ç!ÇLëícUå(”ÜWªz¸	U´âN²¥ëÚÇlµf9?1`)úÀ’{û^ ¸C/SÁ¥hà=Å%öÒOïê®mğîuTKÓ9%+X5u%u‹¨eíºû#´àŞÑäPMIkò	!íÕßz–‡Vù÷²®#L¼Êê>«Ç%Uqsg™cîtÁ~?bf`×·kn\ÛmÀ	²¥šô i©õtzÉ)|HÍÖõYxJ3RğÀ(„axœU]AU·4m¬ò\¤°]÷¹Eë$'¤Ã¢h¼Ğ²§ÄÉ‚j"½âL§³PŞ–r€1Á ŞÉº.°ÊÒã³eîáhªe¸¬ˆå‘‘ \­±Ğ~0@ —4É0¡[Ë@ßÂA€«
CKö×+YšÊš¯%Loä@£oœ¸ë_‰ün‡¹=@T€Q7Ò{"ïÕ½ûcò6ô€­®CMuH2ò—qmÏJÔ`BÕ5äuş8xlä©GeD&y¬€·˜c%œOli›¸³9ã-›	L2 A%ü´¥l¿‚	§íÒGV¦SwRÓ£:´¯4r$^¢òØPl’‰å½jšh3æ²ê“oº¹>ÙıSepŸœ·pK2„ÆçÓ‹U;è£µÏâ4-|p¤»ôF¦«~Ğˆ‘gê¶éY§'xõW9%ú4 ‘Ôõz%¸gãa‡Ó?¶5…ƒ¸öéà–s¿9 ¦‹·–»ùæ|Ô§=Iišïyé9ç„¥Û[n€ÁñŒáQ«Ìÿ'‚§ÙlH€Y¨Æ‹jØ÷ˆ¥ºÌÓóÍÎªmAúuÉÑ´O†eŞ‰ïJE—˜» }ùŸİÀá´ ÎføÊ&áÏqÎ´-`Î´O1Î£ÖüæòÊÃöò¿RÜNıÌbŒR7Æ.îü—V$ôWı"—,½ığ!~ †Cãÿg»¼Ì]nWÉZ[ÎfWy‹+ç˜–Añ.5¨Ò´İXQ¦sihy£Šp}|4<™Jà[ó©±_¸ŒÆQèí
%eÚÍ¡ù'İúvÃdÑ‚g¢9t©ŞÜOÃÆ·jÊ 7g±v°é~„0¥Y+Œé©Ü–GZªÁGTSŞ9K ıïMl µu˜¬#¾*Ô«nÅCÀB·~ŞG€Û²ÌTÜb^ÀÎ/ô*°(uÿËp¨à7kÈ²µ/ôYš_N‰[8•~fÎ`™¸´•bg(â´d|Å1Ä»˜Å®²n³ÒÖôT8™*IFà¸N®}ö„fß÷âoa…1äÔè"U&ah¥İ&Ã*FE÷§ ĞÙqkÿ#$|µÅƒÏîÍ¡d™ˆ}^uN=j¸k"¹b3½Q»Õü+şØf‡ah·ˆ1Ô¾E²”s*EòÒN?#÷éÜ+ˆ~åÈA%Vïü3G5˜r>¨á¸ì³¶;H¹KCx“!Ã"ğZà.öî’_œô±³9„©Òvã Ş«m—sÇ Õ ¸ñqôu‡Çı ú‘ÿQÓn$å€Ã­Á|‰¸/³àO·ø+pWúF’WÃÔİ˜Âõ0+`¤ÙM¢İS9œa‚ÔÈÁŠ£JŞ€w|oØ×šæçi`©‡‡ÓÆÂà1+šßŠ‡R×\2»=®Ù0…Èy§÷aPíÎ/Ø§5ûy©8Í×÷OAı¾0îŒ‚EEÆzÔÔJ>ƒ,8wÉÔÔÂTİç§“qŒÔ»/ÚÔŠJ7táƒ`îâiÍëCì‘Ë¹5B……ZçØTˆBÜ6ÓÚ6\ì¤oêó^}	4~IxCÑ­Xmtè½½oKùú@ØØÇ‹š‚€ÑPX/^°ÆmÈ´¾AÊEŞdÛıTêÙüı Lñ5
á.%s—Ş‚€úûØ%şú÷GkQöØLºÂ¡¼×—'×çİ.Ìb¿éút{s„AY>Pù]lx(èµğeÍ±‚+bPüûÍıéë=Yl”eéûün,9ÃÉÛÓîd¹çôÿàºz„»A˜ÅKêˆı>Ù•„š&ö¤‰Ò5&)ø²E´­¥8…Úw`¬qY·ÈßŸ“ÀMıÂd^ÉŞ0mç¹"_"¾Æ—úz}x¹¹%Á;²¤–9òæ[ã6»WCİ}\YœÄ0qí‘•z›ÄöçÚ+=]QA‘ôììocâG¦ı¡ú­^S­ÆµÓì($wv}Y´jVÉ’!ØÇÎ	X3æ«¯µ_Î» q2âÛbz{Ç×‹Ú1Íjí©µ¡Àİ#¬dí	M‹yu—­Cu‰x˜áD`c ‡A-¼€ÿp
}„FÅëôyĞ7µ‘P-0½wrj«;úã¯J›.éd'„äéoyƒÍ0C™9æÙ@ ¢şÜÃFéç–7d£û6ˆ:atÎ/8©ëè½@i7“¸"F7–V½&ÉAµk›v;„oÿa˜îéímğ
;ÚÀzô{¼á@S­³\h¿ &"Äßøy[Yc~s¥çr1q“*FpŠ'šã“^xÀ÷öÕŞôíÅM¥³|””ªÚêz`-çá*øv[ß&¾GûX©.tà‰øfbâóì{Ô–TIÌË+Ãï„ûÀÁ->ÈÔfÍïâÌç®4µİø…ı*h|9+ÕDt@`Éşä).å‚u&˜v1°*/¶yÃßà‡MíKPÂ_¨Ù"ë³ÿöí4g²AïúK–$ò]Ë¥QXTƒ7å	À¦CšõyÛŠ Ş}:ş&§¦,<¤¼ÁhæQ™}Şóz®VşW*ÔŒ‰õ?’±")O¢X)„j0>x*xV|ŠWœìp¼l1>N¦zTŞØÜL-¬›{Èeª·çÕ"'Òg½Ù½Œp)ZnL‘@!¼q*ï³	8y×¿ÔA&–z¿N³Şä¥º‰)•½zªCii…şCòìVKL8Ào²›yŠv8Ñ£Lª³…¤y¡†§üu'(İ†Ô)‡Ù{é»„£›˜˜Mi!:êéí¤¶ÏÇıÙ$—B¨¤Ç¨!—ğÂŸU#2'd…mŸª‚³iBnqiææ‚&R!/|‘hÑÖ9¸Âá‚2Ñî)¥“ T‡ˆígN‡c!¥Û³Ö¯¤²,t_¯{¢g¤ËA.8ÖãÑuhÎ#Ì†f<˜vÊ_\àÒ®|õä‹©¹ZÔ@•8%¡»g§—{İ¹Á-éA%}zGTvõ3JÒ¨ÿçÜüÍ¨Hsp[”Rùñ—ãñ
…M8’¤Uø!uk¢3ÃÁ,+ <â€y¢5!çf˜c»şGi1ıs^ÀÚÓs¾³29cxŒÿ–cóİ{d›ÇÓtÂ|«Cñ_V‹6E>¢?û<u@´2L™wwõ0A¨ûF4jw°ã8Æœ?4­Zë‡Tj²›ŞÒO­¨¾wÑNCa¬XŒ7$=4)ƒÛ)°ÌP„UœÖ"PÇŒÆ5‘®şåÏÄ|„÷{<¸Ø]2Ób• ½ÛÌ¸	¢ÛöLY¾FŸÒ–‡” v¬›LŞ•ÍÃ‡d¤.4^n¤ôÈftÊŸ{³XãRŒ­
‘Ä7ŠŒœÀ×j	ÜmŸÓĞÓ+öC><êNtæ0=,„½ñ®*X€ÍÖP3ûb-W ÎĞ§5ö.­q!£I[.³úAƒi=èd²qäœ!»öè6.Å
Ï¤a$hOkænÿğ§÷äI|ØÙ°|¯ny(N±€dö@¶ÁId¨Èãl= à]ˆ2{Öfú™Ÿ,P*§ç¼Ø„Bß>¤»“«ç†ï±6n¿şÕ49ÕÌœæØ™¼<*@‹ÃLlÒzéõ·û~)7­'s	T¾òÁK+¼EXS²Û`¨-È…e/A›S3‘aÁÕ%)ïÉ«Ï=uæÃÜXNÛ¦À³èÔ¾#:ˆ%Ç¦-&…ˆn*†™˜W ·™êLà-÷ôâót6,t©„/¾r?á–™Ã@<4İ;zè?1((g­c¸ULR µi¾ÇÌnMPÚƒë©1±ÕF8Ë DÂË„L¡´^µMªGg½"fVC.A%‹.y Dâ¤É}TáÅ‡Ñ93Cìõö0<¨*AT²M œö¬´ä7ı oJ©Ç«¡®ŞP!2¤ÆI¦IO)µ06˜¡’SôMfÓkx7Âù;»Ù©†0‹K¤€„›ÿ}PPÆN[SÄE`í|`Ru´\8³	q­dªz:¬/Û³ÈŒ×ı|Ú6oIò²â¿¦õùÜ§‰gš‚'"+&–º·vÌŸ)9cá†¤î»UŠ-œ Âä*ÚEÖ©4ƒ«örM7½šÙ±ëÓÓõw?²œ$GfíPºPâÁ¢‚×qQFÀò_$ê_1YÍ÷ğÒ®»P*wë’›0ÖÑË3äµÅß|–¾áğ¥’"éô úA'³êEUí~•¡zAäš½¬r‡xüWÊFìf]–‰xX5.ºø{Iaõ”sKÎL‚oî°T®Ho¹ Åú€cà¬ŞÁíö_*ÈwİgEsFûWuâÏ¬0a’·>—Ó•çI„òòµíŞù’S•%ÏlQ^£vB;Ä5mm:ÍÉySk•¤ã@%_á« „^¯û'¢}²Ô®ìİ#úâ#†Í6˜ÇY•§(ŒĞ¬–»-©êlZtŠdÑÍËB_yè1jXÁvÅî½tÃÍàbÏ“}ˆiéİÌmÕª 2	œrÇ7¾ù_c·“¦ûdb	W›0OjÛïî€{§­3#fxPìÃ«áÙÌò>Ö5÷J']¤¾äõÃÿ0öÃˆ(Q &ÛÃÕ×V¦¶îå!ƒì7=cÏ¼'iß=;\ÁG«šhÈ¶¦Ó¯ıòšûékV§¯¬«æss»M»³ú`yí-v¼œG²jşìª†ˆ½ 	¤¸¤eqx°ÒËÓÊaDR•ÖPX‹]—[+¼C¬XÉ*=_CHÃë9˜í|Ãöwña‰ƒ\h¹JÓ:™Fß½­ä¡‡4Î¶>P
Š«·Íö‡“õY÷sèY©ï/4Û†ÖFQÎ ¢œ®>C«5¥ÿª†mÍĞåöœ¸­%³¸[,ÖÆîC]süÍ¡üvcì^@ÜáçOD=Õ«¡{ƒSdt_–{§ßçÖZùwrP
¦ßÄØËÊ¨>ƒ•…™Ùê’gp€™l[·ä¯ñö«½W#bX>ĞT²YÎ”øÃ–y%z:±$æÔö~¹>Bñ‰ğóiÕê¹~è~ 8&â€ <H£Ğ»Ë™İÕok³¸?ëw®,l;u6şx¯ƒXÔä*e’}c³åFpvœ™äE~û‡l|İìàŒQĞş‚¸1‡S·ÆC}× µ\gÒ¤å+şÕe‚¶óñn[„6\»_¹ÿ<oµs‹ªì™
«oƒ×›$ìñ-…%Àæ6İÖ;É!,Ïd))øœì:ø$a„›ÏqâĞÌC‚–HÓÑYlo“M$nıëà¹hÀ™ ½’íVüI/ú·Ñ/Ì­ ©•D t´XÒugğ¹$wåI²Áï·Ÿ¦o8É‘4FC¢Û$µÆ)×{ùA2ª`­c¸›Í
ß×C4u¢ŸT@¿ş[`M @GébÉwñ8$¦4?Åªø£[b}ğ¤ÙIÒ©İ¾§ †í‡eK$ÿ2ÛT=ôq×¡¶D¢¬F¯ÅÉÄ¸Y;² ±ÛênWª|±Ñ, êÉL0…°`ĞÚ!n¥T›ôÑíhmŸäÕ¾«™b£BßÃZÆ€ZùïÙàó™‚UpA/·6X¡cgúÿÈ^ÉÈù&§‡ *æ9
…E	‰ç ú›†¯JİÔ9”ç…’>nÚ±‚ø
Ò`ªßW:MêI9±iQ±-üÓ·XŠğ‡Ï˜%ÀŞCKn´„F¯)fYFü·~/ãÅ·&àå‚yßÔş‡„øç˜ÛqŞ…š™ıÿ\1%›ö´Ş”ÔÍx†3¸şMåNZgœƒ…Ÿ@Œ(ByÄ"İ)ï+A»…Ø%é#GãÆ5BŒ?ƒQ¦{ ÓäÛ Ïİu¯ ş ôqk@£—f')±òÎÍÙÃ‡bÒN9Ì“
Ñdˆ;$ç§1^‡Ä¿ùëbÁ,ı¿™Èë.€ÌÆÓz
œÉ]Ï¨U.Ç–bo’^ÒÍc´>ôB¥fŸPxÕp£ø=E9}°½itã’Öø¦µ&]¤Ñs5~A°Š8yy€b©¼7ÒÌm4>·™¼R/1 vDôWe+v‡®ÌjS=È’RWÀå+…Ãk…îøY¯gò¯ö¡ãİä}ÉµfœH·ğâf‡¹·l‘(AvR[xa’É7|dò"«ŒÏpã™½îıU2ğµºòÎ”ªÃ2~ªü•+{v¨ĞËGDç[‘>b@KXşûµ"ÕE<‡	Ék¢:ª9Tm
°È«”<3Å¹¸Ù5yïÈŒ!ÿ7à&Üêº¯¸œ·ön§¹˜ù¹BdC+ümB2ÓCİXfÇÓì¦~
j%³MOim;¨Ê`·(wÆdˆä€9¹
CCû„0ÿÙiÙš¢¨ª¨nÇ(kú_ÓMì¥o"jb|.²›»:Ç'™ÎÄ5OC±eµÇu’v5Ì(T³^í,jñÎĞ˜šIçc}’µŠ€1¾KM
\RI[G€†<»—qn.",ï
†×Eg¡Eñ©ñêİ£",AÒfÒöm“É§¹Š ±EÑˆK<+9XSåŒÀi:À•›*ğq¬åÉFé¶ª•†÷Ø§M/vñßElgÎûˆ&W®lèu7yiëÎPA|y0m5²LÊÆ¨ã\÷œ	ª›¾gÒêÏÁ*âO ÷ŸŞ™ÖuÖ(jh^”%£Ÿ¹äOÁòÇÒÛ¸(´9—&>lË÷*ƒª\âwĞo%3ÑŸÛˆ“CÅ*mı¨ßZ_ƒ^Ÿ«S[Xwä¥Å {‰U—ªŸÈC²¿lãP‰oğ.f a†PÆŒõa†«¨¡…DUõñDöX«šÖ¢ËoÙwá	áv]CÀxÄsÎèoOŞ°“û2›ö¶éãÕ'íü‘X÷‘DÁè ¼SîQ2Ÿÿ§QèH¹¦cUşR@MæŠ‰Ğ+í#·ëHÆr¤ó«YDUğı§zÙ³tµœF-Yp¿?i›„1:¾‡M‚ãrßth«Õ–È–×Ÿ™z¿aïÿ"›§¾(·¬~Îş°ğ¢ğ_Ü¥Ã$èI
¨V –Ë‹*ê ğ
`¤j3|¹õ—$¿I¨ÑYîbè´êĞæKß	ø Ãõu ôñ-ÏKöÄ£jöã™~:K—H(P‘ó@]£åëôŠqÓCPªLş0Æ“¥‰Ac„üÚrêŒ/£FK³¹…·ø
ê±ÿÖÌ$nÉ¯#Bœ n¾~Êmƒjßí“áÚİló!Mä9µ¢°ˆnár ÿp®Ğæé:X>ÓÛÒ"Sf*àî°0ë~óE
ÃöÅÓ£	»À4ó¾EO¸î¿£¥q$š'˜‘ãğÁîÆÆ°tÁzDªF
¶Ğ$ÆAf¨³f`ÈÖæ11­ÿºÔ4´^=eh“Üóˆß:¯Ùiø®'/<vğÌXÓ>—9îÎº :µ äëRŒƒĞIÇ:oM%å«±KkQ?w¡ûÉr”7‡OW ¡òµñšF[=S½å‘q	Û
\¼uxg¸¦ÛÈ¾k§ä$g€ŒŠ™›ğ+|ßKM…ÒøÔ/LX™¡Æ>§ÊMsFfy­¿QRıä#ã€$äXŒ¿5Šç=Å¬«Zj‹´­ñ[ıéÄÁ{Y£w~y2n­ñj¥®ó+F­Á‰€ÖÛ«¥ùI
‘©Íó”Ü¸APR‹4’U,b·Âu Ï¾5+jy1Ç°U×+¬Ì"’Ñ’Y„d×QØQb’•S«õX9h[°†vqÛïÜôà«{û¬ºC¥ÁÄbOŞ‰¹ÈKĞWl´Q‘«ê™ç„?ùráêƒ?+Éº‹Ò3°äÕƒ•À­c%B[Š'˜R¯ôbjDZ„ q¿ª¶âN³±™
"X²Ø¶6ÈïmÚoŞ:Şô4ø·LâŸ²ôãZ‘¬O9qslÏ=Şœ²o”ç[D£Ë<gÖÏ9LÓ&–p>ƒÂªŞ1C,¦j¥±ª\Š©÷b­ZÍ0ñ€"K_Ÿ;$RõìM~6)d¢Ä×`
¾ğ>#pw\OŠË~Æ!!ß,¢ I«"b`øæÿ¾ò×Ş‘“<ÿ¶N¡`yÛË@¾ÛÚcrå´˜ç
£å/}#$ı$Ôº“ÁÛnV èúÔà·‰oJ(M	= C^íPª	Ñ˜Áş5÷Cú	kùÆ/á‹RóÌ‚-ÚÉL7×YX˜JDFc;&c½"å\ëŞ+¥şG26X<D¶ìóyUš,°×«šŞZr:´oÌflyÔÛSáó„=ÇQµy¢8Õrå ÇÂSz]IÏ2b)js{¨¬zøØ6Ò†ßğ*‡E¼c„@·–ı¹{OãßMzC‹¬™8°p!–Oòº•tRª*ÜÇÛş¾¡ò&†‡ÈÌ%ô	å1”ŒÅ"3NÛÓi˜üßM©×l#¾û³1nåµõŞŒÁ<¶Zš»á˜ıùÍÔ™’¼øÕ¨ÀV<ÒÀ<k›Œ°¾_¬æ–¢5ëJ¢÷w¹Ñ#‚³¨5Ö–ŒaŒO&ùGvIÙ«ÓLRÃ`h	GÎ¬÷Pã°Ö ,“¶Ã‡%H3,½šBûÊÙ[ĞN!­1fë‡„*A'Œ¯	uÌHÛÏŒÜzŠR¾Ù½ë^{œÉ#¥p/o ƒsõ>w§ÎÅ®ÓLx”»Æ0‡ËñCz@9ğêRIeøÆ+FB|Z¥İR9ío=ª%’ÊU6O£–Š\øGåŞ™?J’>1{>Y§ßÍÖhÂ*‡›§ĞÇÔÅÄf.4MW#ºÍKÎÖÂÚ3iö8›\n®P¾52ÌQ6;âİ8îØVŞÚïØ<W0œœúšß şÃÀcí·ÿË vzÃ41ÚŠ¾¶Fı×´“•Ÿº8‹ùÿD`+éíşƒq‡sº‘«CæDÈ€¤Ü>¼]Óò|6NãzN@†nvV:†cá6â¿£C¶ÖŒI'˜væt˜„…ì0­5²üÁïMã`õTo¸%©Bµ5|FG’oAfÙËï0µ „ ı'*Óæ³?™+qx‘¿šA«”šÇÔìø2ı;Vq2ú„TjëãD6œJ¸¡zïyS*½¤&4ÌÒèkzçP~§¥`/h´%Â­ÅPÑÓVƒÒæ´½0MÔ[ºjˆa İcFK]æw#@µÙÁM£MÅx¨<Ë­ğD1+(ÙrùªûØ8lÊx–©XoÊÑ Ãyî©l?†Yû³€I‘^ãñ äº…^÷ÏîP9!ú]wÄCß©Eb‚Z³Ñ–LÌöRqÂ<3øzã ôÔyø0ğÌ7BºµºÉR²ãw£ $iÜ¿¾‡ĞÂÄ¦"Ÿ0+ì'K =VŸ“Yú¬²å*‚‡\k§¨:xÎV”>pó¿s¡B“&–Áú²H¹/8Åš¿@ÊÇŸì¿ÜYæ“ïdÚ&ñüST¼ĞLê<Ì,Ü1£m\‡Tš#—©F‹K–§IÚjÆw©g‚ÑÖËßÚ¯¨wøx†óÕ(Qîú‚‰u¾–¾^¦à(!êËRA1ë†rANs3…kêàuñrÈáEÎ}&iÄ%å6ĞH.®TeY¥I$%C»¶,™ŒĞš]î–)•‡cŸ ì]7ÿ’ÏXPcºDÁ3[;¬¼#ÅF£CˆşävæªÌÏCíşşmi@O†(É%%£¼É,MÒU#RT®d:Æûtbıü[éïˆxœ¹ŞP™yÈº øjNBâ ÆŞÈÇ¡œ9/Cn…:ôyV¯VÆL_)j&”ğW`Ïöµ‘½ÿŞ¸*7@8_{=bS€Å_|)ïƒ4CÙ<‘vZ8Hôúß—w¦ŸšGOãóÛ Q{Å9ã©š,Æ-<+Îj¬Â§Ç:˜=ßn\`€,#Y…X hBiCÀS,´ş‹6‹ka‹K&Œî«Ò,z6‹%ÿÉ—“	–{ ¶2èö8ÔG!N€
§ø[#kYwMw¦@„¤j±‰F6ğ@TG»W7ë7	Iâ›Öç¦Œ Œ¾ê3 ş=i½`®›ªºTBqÃes*_—yÈ&­ÁtU¡2Ye}	a·äñôÀ€Yiçî6´^®Íß±í’©ŠÚºâä}[ã0³–k×ïÄÉ|½ ÇçkĞ ‹Ş·°[šD
v' ÃÏ·ºRÇÒX»÷ù¯'	 8Öƒ­K~Äã£ r¶iè¼Ïm*í*”öŸIQÀXE}6~8Í{ƒ~“¢Û¼‘q62¾‹€cnAŸy5IE0•?¬Fö35ûĞ.yûğF$ 1_Ú#{­êÆCEiUE „k3Ö®à';*—…\m\#o”Ç	Ñ£,óÈRòı†áyÊ0>Â×Òƒÿ,LÊ.œ
H¦f—‹düÕ‡Ê"ÑE¿/MHß94ROÇ2P¬„*·2C«,¹ŸyU‘rÁ@ŠÒß£‚Ê(Ò~šlX•¼¹Û²Ş=¢”µŸĞ™JNBá¹ä,ÌêÕ-¥Shr†)úHa«
¾XÌu+hÎ%øGa*Â5²‡şa'™ÖÂ \#‘jî[,Mp]Ec¤ÿÏÅ¬ùGó÷²tÁ~'x¡bOrF,i9Qof’ĞÔÊPÙ[ºAHGFißÜÃŠÕ‘Şy&°",Æm÷Kwçk»=ë£zá¯¹§áÕfÓ5Xªİüµ4yC¿’SEEÈv«1mKµÒ_:•5+„†gÜÔ©9ç0ŸæÏ©«êº7Ï“eªù,ûmb¶m£8e{G8£ÜQ?¨[—¥yâİ&$mXÊ‹äQòl¦\É`ñlB
äep³#@gïZÕ:ÎUH[Ó-GB]ƒwA§PşcªPå¿¦'¸kJ\şŞVHbœ‡Êud€¥h Œñ>É ‘¡”˜!ˆ(£L‡‰P£Qê:#rõs˜£ë7³ŠBs:„÷kİ×&Ğ±÷{	òïá>ã%GR9¬4F«äE·ŒÃš|ænM%¸öª8dàIèÓóœ©µûfş*•Ûe„Å½w2¬ íAnŠØ-5I%¸MÏ`<Lİ'›/ÜIAı'A5”T™™d"v¼³‹]Œ"ÁÜs¡Î¡Å‹­KT+\î`,î£k–®–‚Ù‡Ñ¬¾Åf`O-r‹:¢i&ÛU¸Îhúè¦b?ñ]-xŠ2hd­^§±‹çõ6¹¶ûôP j¾œí°ÂÀ®ø+fˆÌ%E9ÎÜQùà,¿Ü¸a±¼R¦9·-HK6Ôñ:à”ÆkwcêÊšÉßœÚî¨8ûÙT º		³îŞõI¯ÌæÄo‰Şx‰ÿ7 yOKù!‰Vù.@Á”g[œü
°òØÒ•d˜0lĞ(òÚò7×ÎÆ$ÍbVì£ÿqÍ¥ ¯·ÎuÇIèM…?4&ÿÁö4­ÈâQ.N‹ÁBâ¤R óe»"•µİ½êCA(–çT=m»İeI`©‹/”½s, 1[ÍZ}–.ÁÄÅqsÿ ¯µJuVì Lvuy†QÎÀ§úò«ˆÄû”|'‡Ÿ`ŸPúKÇ#ü˜½ŠF!h«$ Û<| Vì	÷€¯Ybç› (ÌôŒ6™i¿²Û,…(F«±5A:o0’Á|hûú´ª.aãºW.t¡ş/EØµ¨a
ıı Ò¿‘‰Ê"B"HŒnôZ°\O¬zÄe*ï¤v§8¬½òÄh´ ¯Lø¬:ä•ù\IƒûŠ°„Ñ’œdœgå¶)•NÚ„6ÎÓF} –àÈ6/…™0…ç”Ì(;ù9²í¢‹€ˆ²Û 2<>Ã<Øêu2{\2(N“‘%FÖ'"¿[³aÈ# «Nã›òÒ¯Œ”–›Ë´á%Ã#÷O„!vtôœĞ1A|±Sâó{ŠğwšÏ®nœ=µ5 ÙD¢Ğ³alëoÔnÏµÔÏ³„èõ“\—~w¸?û(ºä«ÇòİSÎŞbááùzo÷å¦¹ÉX\à@:
Aæøén¼¬íò×½×	m|WÆ²AYæñô»7â`›‡zÇœSÙõ2ÇBgwhgRÚ¶fjÕD =Õòîé$eÜ®mAbUÖBş™âÙ’—E—iç±â[Ù"æÿÊ&å•}t"4¨‚I›ÑzF=0ÙåJn>·è’8Í5«$Åá¥ªÇ?ù¸ºLğå¡‹Ÿ¿ÛAŠ+jê.‡•­¤Ki(qZc?ØßÉç†Hæu^RŸ¬ÏÓ%áHÔÎ¥z|¶‰æy:õ«jÇî©ÒÇoa˜pÆMk!ËÕÎ†ö"›>VÉ£¾¬5![Ba—ÚM¢äÊâ3êÖ¸}Ùƒa¸Pò¿»hœ/Æõ¨x¶‚¹ÿÄ¨=!¯g¤H¾á63Ó÷[*é#yUJ9Å`¯½¤È~ş)ëÙö°Èr]™h¬
§Ó7õD x9.›©27E	´#è’fB^ø ¦.÷Ÿ5B´’'Õ[ß	ë Œœ™&yÃÌò…áíÒWÒ©¹¤ä¬kı´ãJü7ÖòÕá‚Ø&`—İéà`ä²ÿ:p×0öO~:ÍàC‰#„ap0hE\ÓxY¤‰åÙ â†ñDÓªT–3£u2F»Ú¸ç^ö½ÁŞ¢·şFe€Hfo ìã§IL*üùWH¥÷//©ä×VÓ¹Ğ˜‚†»È’ë(Ú3ş¹¾ºñ²µìM.¸£V¯åz31©ÙLUm½`i¡ém[¯?Ö™¢<È-‰ ;P„zv`v*ƒ¿j½e¢“‚ÒæÃ(%Ãc.ñÖ êıX+ bÊÄ©ÏÇô!]„˜>Éßäñ:ªRÎùE¢2”-¹åÛ¯™ÈTXµVP}ñb»XÚ)8r¼6şI®†‰°…wh°šÍáTÍ-A>/âAJ¿˜­kuK±É*…qœy«Ü?g§°€ÑM °,"j[¨53¢©26]P5Sğ‡k¶h o~*â8"%TÅ3SóK<Ù¹&”¤©’éì•
Ë¯Ï¾…zìùêX`=ï@opI/8ë7s¼ùÓ’§ÍÓV’Bü±FºYãëî…{ÊS=ôHTÒ>á.³Ï³ğzz^JÑº=.ÎpÒ~Œ„õÑGõDŞ|¥»àÛf	¤™Õ?ôëˆ–˜rwÓ>Ös?Å¡÷ÀãEúé½4¾ŞÀ xÍ½¦3 B·¹àAŒ±ß…â%­ñt5ãC/Pnü’C†÷S+ñÖ?«ªù{ üC­aÊµK1c£İ §İw'µº¥c›x±Â×ò¢´ğŒm‹˜±‘òy—+'îŞÅN&ÙûÖÆ—
-{²ºMæÅ@ºé6„ÊÆ±úvˆ?Æı6‹KˆjÜ,^ğQ‹^ÃÙ'‡^iG/Ÿq²
>yeÈb-öÿp™ÎÔhôpÛìÍÎ•gÃ80á¶Øá.-ÊtÄT˜á×£,0ÏåÀ¸‡q7´˜~Íy.İİ~RîsòeŸüÿ£ºÔ¶Ÿ¦Ÿèã52”õIl·V»
•]emÀ@œÛCm}Lj”^z…uÈŒè´G'Nö¯^ôun¿qÖÊºó„M–ÒÜï°wÉJ‘¤K¬×âhÑ¸¨ª@·3š9[ÁÌ»‡d‘'W­­†¿(Uiöİ÷sO<Ì+W6|
¾˜ñGàH·àïV†~ÕXXşše9í‘3‘÷³c:O/Ù;†!îR,P­Z¼ÙŒóß”[ªJßT½B-§»dÎÀ­¹¦A¼lÕí¸"¨ o\Ói4õ’PyšXğ&RŸšV}I7X…«Í5…ŠîëH»î©¢xhó½"h{}úåaíÅ’Õö’ZNÔ	ª7´]†ôµ„ê†Ä“¥Vnº)‹¿1³$1Fşƒ±w !ï^@uë›ë™·ñqï`S€õTøæ‡ÑE~«y·n=â+¯‚]­Â3š£1 ò`T
e†¯ğ3·,áX7XÂFaïäxĞ\á#a¸CfOØ#Î?œ«§rQ+!&ìğ5oÄˆ8êI,'"È±­&Ñˆ¡øt“N@(ØÁ©¹€îr!¯³w,*<y”şªÉª*`s³bè;tcn*?`o‰öÎ.ûë ¤üêH63±~,<#Ô;¹štİX$˜ì^Y1v=|
	;X v@õîly‚ÖG€t¤”¨üP‚S‘DsËU¿ÿ*QK¬‚L=&V56PÍy÷o Æ ø53úP°Ş¯bF·B»ª–Ñi®×yIg°O¸c®ò}…é†ñµ\ê©Ïrİõ³š7óìĞw×x)é¨ w@\¢³h?Œ<
d’S ·Õû1A ÙÚË™?¯Yÿ>«İ‚HBw3ËÉvÁ}nvÏ~4İù:´Œá~ë‰p)kƒQ îÆòõØ-á¤-?·•šg¿9™`Ëı·¦t³+ü@@õ$Õ+cänL]j–›Wm¨tn¨yh=—¸EpD"èÇcS–Ö± ÿ3ª§^õÑ^Ä	8y0[,/Ã5'v·YsWo;Ñüşm4s–Qd›)©qY»İEÙN"kÒbæÿnÁÀúyÿê$b¦o…
:WĞ9À­G5F+$®r½–ÜËø;ì-AÿªZıªÁXU]>B¾{HÚµ‡o³ÿÔ‰†.E®MJKïs¢rR~Ãı)R£ÁvŒç8vlTK¿‹hı«¬øÈ8c^Vaœ1qÙÁ\'K4š¶µºZÂ÷5î”˜­M¶G“‹ùò¾ lŠÂSpÓ‡oRseƒ(EÅ%â.B’e*]}óÕÅk¸qa0Ù²û ï
ª;Û™|D;û[½Y³ë[åó`Œ	aRFII8$Æ%‚2µ±¹qüå-#‰6ŸÚ<#U<NW¡¹·şrİƒšt5Or5ã´ÎÀ’ÿªu3a£N˜¨¦·k¸T—M§àTIR”Vcè #^ş pâ˜CØY¶5ŞÔƒ‹Ü"Z]ÃÄ`v´gûÏ†ÏnD˜†Qc¨XÚÚ]Ğ“ÄüÔ”à:Ò]>†ÒZœŞ'×,pÌÿ7‘r
ê;>¼jIÂÉ”<ACö3ıg‘ªt°;!Ïõeçôh«ˆÔòÜÜKñ¶´&Øğ´P"\ìÏÓî5ÕÚém­[{ùCÈjuÛænSÉ¸j§ò…êd Ÿ91ƒë(æn!¤SºÍ½İQ4Àî‚çÄ¥ué’ÔBG/éÑSEÍĞ#…îdM)gi™îÍ£¥sy¦ÊWÓ¾Ä<V_Ød‘‘ü\yP¹Nö’ü+KÜ¿2Æ^mu¯K‹‚ˆ´ >ïŞák‰&ôÀ¡[6ÜğË¶@#ze¡ê·p%1VwU³íßKW¬-¢…3”DáMB÷X0]n­¬ù¦|‡ hÁ¥“õûšnPş¿MÆ8Hd½ıÆhÉ–Ÿ£7ĞÔ%‰„ÁnÓ¬…áq %8ŞÈsUBXMx‹U]¹Wßñ¸Jª|*JU³Z_"4lŠ:ê1rÉÓ5üÏş=x2ğ=ìZ-‚Ûdâ¹È*HfšØã`‡?f¤Ğ?=²7Ò†VÑ­|B“’àb–bóÀÆÒŠ*_¨[P†×æ}’œte‰Î}XL°Óıåµ]k¶èüÏ~yji„£Är˜ÈwkQ¨:„QuÂ¾)ÂÅ¹aÏãOQäœ|fT«™å$eÈ7 BÒB NZ†‚0-6èo?Cb¦ÓáVJl­ïÀ) «¯ùópš]İõ‹9¸V\7ªe/º÷"Ş¶<Ò ŒÂk,tˆÄò]¯‚GI;Ï"!À{îb­ƒ4…Ñ¯¼”¹½­@{üQK¨Ûí>ƒD®I7(·Å6ËÚ·öM±Ğ“ò®ÊØ(©ÚÇœd/S‚Cˆf¶ß(ƒşÙ*©•‚DÆHíÿ0‹P„P«´wı\y0~adµ@½ e²şw ²øc±TõÈ¦ÕÇÔ©Ù©Õ§’$aû¥®”z›"óˆ¡§^vë.¹ëØ>Zb8'lÃÀ˜²ışr´äBîú!qùƒ±Ï”‘SbÌ°˜/zr Èx^ÿ."!¦\¦cÿ¤úvB°á¾‰î_7Oïkz%k]ö“ŸÌ›pW3bª[á=“Åo…8‘6$²ˆµXûcÔÃàÃĞé}~ğÍw¹ìôAcP1QZ¬Dní³°õ¾zaY˜_R‹<’Äÿ‘v¾‚;.ì,ayx²WSê)¹ì·âM™Øû×Î@º(s‹ĞW	xÏ U³OVgæ6ãËÌ{[Änmb÷ñ?qğÇ“™yœÌ°:Û·cŸ ×B-}æoGG^¦.S¼5úg©¢gm`ô;Şµî$îõªê}ôüá ¿ã;2?‰n`áğÌë†qÛp;]Üdcòré†LÚbµ>ô!Ç9z¼ÓI`é²vR“å&ÏhZ9Í§)4!ßm)5©ì©»pÔpÔ~t‰3gI~’á™_†’šuh¼+9ö‰œw&¦MÅÑ,!æ‹ÏÔÕ(îD”àû‚ŞŸ]6!7EB¶6ıaî¢IÙ†U)L”ï¬}¥5+@VÅdYÛä611éëàtÈ^lC#«e,qÛzæà”âµ{û¸ĞGjĞ€Ş™¿ÉùPGj­­¯Ö'·ç2,É ó‘Ğó¶quÄªyk,D©
j0öMI•XV~s½1†ÉÄdèâ?O1Õ+LS‰¥}»æW,q€}e1Ğ)½ÖŞCIdDûÚˆphVË?”­z}Qr°úëµŠ>÷¶U‰ü&ä>ùª‚ }*ÀóÂ¾¥›{jóxî[G”ÇÛwa<ÊB« ={ã>zøo%‹vä[ocÑao4d9²Œ‘`ô·šÇ¹ =3{O“#à6ˆn…\¹ë®³ÜïÎIü»òˆ³g ĞÊ¡ÿ„9¦*·»‰ã†“Ûl`æWÊNBf<Ÿ„À;º+0jÀ,Õ¨ö}áMZœÊï—IRÁ³{“m‡óHìt*ÀUøÙQÏ†íˆ_'!>Ke¬€qúh¡•?µRİtEÎº­ûHÄU^^ûbÆV¨şr[KJTA²[%I^–kåÙB¨a¥OäÂåõ”7şäñNşEËŸEL†ësÎnîĞ¹Fˆ8lÆ1Œnu&@d²Ö—¾oá.¡pY¯T^åÁ0ù‚Ğ(Õ»ıîĞ¨WqÕU|Wğ	GgâÖYöƒs¦+fÎOŒôUC¼Öì>ìQGNF[•09=é,¥_nLˆF¢ÚøÛ’ÔÿRq¾/"¡4è]<Uìä”iÇÆüé«Ô¤IƒJ”øÌáÁW4ü#Õ6Æ^£„ŒˆG•ÿÍ…îfÀhËBÏ¾`ÍE°Û“}¾†2±~tU‰=ÅBKb“à(· wqWv‰T‰~°ÎKßŒ@¶K*Q-…Ô»*~™Ğ“ƒƒö87şF!´úã3-¬ô×Ğ<ZyáçÀŞÄCfÿ*¶I¸(‡ãsf/³ÅZ5“ùEÏ§qGôÕYÜyó4AÃÃ)øŸÜS×9Pde+Ş‹‰}ä]AíF?Øãia@4/Y¼Ö=û"Ó;ú9EªGÒ¢©“¤     ù­´d[…– õÊ€ÀÒ¼±Ägû    YZ