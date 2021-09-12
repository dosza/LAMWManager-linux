#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3426184144"
MD5="a6325450a58887093e167d956acc4bc3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23224"
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
	echo Date of packaging: Sun Sep 12 18:54:30 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿZw] ¼}•À1Dd]‡Á›PætİD÷G§R¿KCDd+[úÚÁ4A(EJ®K
|z<ü"ÂîÄÖ/ŒñcÅæÊª&z†=Æ!'Lf[û±KT.½ê¬C,)”L¬6ÑZí×dÈåš¥«çñŞ,®íª|Èlÿr ÆÏ*ıáù\ãtM²%¤ %R¡ãz°µ8Øñ©V3ù;ıò¸Ò¸×ÛÀ…¤Üq©‚âÍÏ	q¦#Q´Äì-M7ÿñúw­Jámù%qÉHóS.¶ õ©Ÿ/'6ôu•ñs-ÁR«±@©À”CT^$†‹K.şüó|¯ô¿mÕM›Ÿ\3¿&_ëzÂò·ËIxM›LÿÒÚ»¯)ÜxqËoéù’… ŸÛD¾ŸmÔ–f]Z+óXãgC©_!u8Ä÷.öÁÒ$?¢Ô–äÃ-€"ß™w(¬×é2Làà±Yr¾ÌY÷3mP5Î‹Rı¹¤ÀÈÈäWó+eIsIìù Kg²h12(Ï+ş2ëÕ=ø*=aDä'kyœÈÙŞĞj¹ÿ> 8ó\]¢‚2>!fè¤d70,ÄNø–ÄÊ›ÛùÄ*K`d-'·Axø)ÂN¹'µñÑ³pV‹X&†Læ3=´êºávxöñåópÿdkş]ÏDg.Hı"´1ıéŒ G\”Òš=ı^.¬C)Gm‘]E]
¢V`•…\ßK…Î¾˜u¾—Š:6WDaÔ'4‘xÛ;Ÿô$bPû;Mäëw­ÑuABÏ5É…!—sÓ&¼ƒƒmÕ*æææg­ä*i¾éã¦ÉŞ0zˆ;¯Fgr@—ÈÁy_÷%°Tã^òÇæÛæÿ7¿¦oÆ¦ÒÉàEmò'§F
¹$ú|æ«T\( },!§_à¿?D‹–Ñ¶b°:é1Vló’‚™uú÷&µûFdá!¨5,ş©ïÖÙTúã÷Ö˜Qó?Ò³ 'w$Vİ5J ³,¼ âµ(ñ0bcÊÄ±ÇMP0|ÑÅ—ö×Òùù€5w0Y³¾LQ¡Øg[¼¯ò­×|3	»Ã*s»¨[72û.ñ["RÑ!=ãG*XEÕœ$#ÁÊéD‰m¸YÆ3»Rªl"·$µ%â„ëÔS®ai×†İÒşû¤ƒpŠ=ÊÍ0ˆJ*eà,³Ë¢€&l|Ú)s"aea‚MÃùãh´È–nË3¯ O–ÙD=	Šæöô—ş±´~]í¤ş$äTØNñyÔEÆbÏ‹S¼˜è–ÁòLj|*ºØÿD¡'ğéÕ¤â:îsSJÜën©S.w†I”O<1DV´ÖÜ€ÔG-¶‡—‚«6èÚ‘İ_§Ãtq0œ²)f“jæÖüÃ•¬Íâsç—»M®¤\OM,à{t±¹»ôƒH™ªBİ{GÈ^‘ïD…!ãª•Š´ô’4í+k•G²À3®ÏÄÃŸÌÕìz‚áÇ?	KÁö¬QYNÚ°%SŞ‰Ÿ¢Z¿lqÛ“úñHÑºbuÎ~UF}Z}'ş¤"õd¾)IÁ!u¼¯ÿíè_è«Â{&/ÜÆ»{è«üğ£%İÑèV~ÉPº§ïn…§`}…0§å¢gCxâG–ˆÌ±w&PïêM¸=şCpMV(ÀÇDˆÿõ 
Ç+êEôÊB2úyĞ<µ—pºMíYüï·‘EM`ØhŒ2sƒÎxÆ•!ÀË°7ş¤pØDrsA‰Ü}ÔÔr´UÌ…R¯Çe®05B¾Ò[UôõÇ‘"&ó»)ÄªĞbaò¹‘iYæÔal¤×%]à¨l”ÙYºÏ¹VÚ	9Ë”±(£ÇØRÁ¹P²@fÆ5© >ŒŠ6­$G=|”Ë(VU[+A…º°¬h‘±Â)äÇ	²ß-è¿–LàÌ^Ã5i;è¾Éh nH¿˜B—ÚkŸ¾?oğ.†C›µÊ]ŞWB¥ó1_ÈRUü†ù‹»ı`ÓløÍ5BbÊpµGÄ‘Z^ §.É× 2qéó°¡{QÑ|Ñ¦Óı @uèà*ZYá\O¹a,|I½m³D-t;Û´ºù¤	ê¸<‹ı–C;¼MQİ|¬½—wP–j†ßV…_¿ÿîñ7M«‡Ø¼ù£j^OdÕµ–‡y…å,0İ–½qrä4î5•o«}ëŞ*Ñ
	\€XBåªÉâÛ…ò±gşói‰f+R9¼V9Äà{‰_ƒİdõPMİuèÌœj©K›‘R/†ÅÕp¡Y=Ó’Öêğ(è³íÿ(—”¦Óë?CV1\oŸ	­Õ9,¶€So:º	zè ®W<ˆÍ½¯¹1`Âì…1Tú’7#ŸB5gì$Xµ{)X´DkcÓìÑĞz„S•p3×A,C_ËÀ@øú¬lq€c¼¤÷{fòÂ“‹6	'"o—ë	,8?J/õ‰r•P>Á†ïTîB¹pV3ê`k-N»ĞW—¶c¦%ˆ’Ó_øVŞi¾¨a+Ñ‰0Ä†MPª¦Óı¥5^qbø÷µ[;`§î1:|ÑÖ¥`Di¸W”$QÖ*ü”jiÄùß²šÆÂñkØpæmšQïGÜg“Eh´õ4µMhrG{Şªœïø=Àe®ğ×H‹Õ¾ÆeF}<årµÓ0JvÓ>¾¼şèÚ«4°ê9\Tš@ûŠ9k„€´ã	ÉœYZ„{“Ğò¢ãÉæÓe$µd¼êÉHQ ³\¦ÿìN%—bõÎ}GIb}\f^yÊ#~}|äcn¯Lç,Õ€î&&<²	Gv43°ò+Â2YEìv×¶#õ•~ÉÏ‰òÂ›úó ¿f5ÈÊÕ55ÛøqO±w-XG8Ğ‘	€	Ë'0ªL÷V’]bæÄ\ïõŞÄij·û×u‰EÊ<<zsÔ×‚Æu+!5}šİ?-?ómöŒ=â	•öóÅæ1Q/E÷tÂ©1U]¶Ÿ­ª®ı÷Ü ÃúTãUÿrš¤îøCê€”tüv>´¼÷ÀÜç‚¬­ *ĞœD
ë0ëŞU$#¨PbÉaÀ"wwñ'ñ‡Ë“ÒêÑu$pÜÕO©_6@-$º <5Œ»<Ìi;‡k¥kôüJ¶P•{ò´CôÒóéíSt‚ï"M6 Ø®„Eˆ Á¯-XmÂÉ‹ññvŸ®Ü)>¦r}bß ó+šXH1õ½ìŒí“QÁa¸K$9L “HxU$ÅÀ²*¤;NOKwïTŠŸÎ ÉÅŞ¯NÎÍÄ=em¢êJ™Ó³üĞ¸õ†¶Mû=/şöâ±Ø¢ª(°ÇkæÑıJöœášêµk“ÔOe]j9%Ö‹h1ªë"£éıxÙüÍŠ‰¬r#³@ä²¦—Aù5)RÌ¿
­g©³FğÿÜôSÊ`«g>ö’´"†Fräœ?“¤…‘XÆGº!†$$yk:JÃ-B
ˆi8UMjõ”Qİ6%]ÂœI18	˜/6IoßåM‚Ü:
Ì5Î6Z
O£vÚ©ó¹ğhê^(hÆµ_š·3,lO(ğr·¯AÉÄ¤äDVö@f•zqõú—gÛ×·`ç¶åX^çV¦fÜjÚ»­ÄXÉ¢’Ô§ÉécƒffÆÏB_Y$:BI0òA}à(Ï°¬inÙ­ù¶1y•-RFó¥#eZN»šÑWd™òå!DŞ°!`o^ÎÄq“Ñn¡#‹3]¬¾ğ)Uª˜J/{ïñ¦ è¦H{~_PšB(ƒş&¡”ÆãSŠ‹üà&h’³àúèŞSÉofÊœµJi¹‡êŸy„ÅQè§Æß/¥è05¡üıÏe¡ {ƒŒq°°H¢=õ&ZIöÈ}‘0J”&Œı)"¡)¶¹°àf›‘+,j;Ñ¥úƒĞr™56¼a˜É²d'•'½ô…ô´íû}}¼{•Hí†Êc%^ò³Á?iÙU%+Yë%2øÄD•"~W¢ ˜ì%c_–R&®¾F¥Vè;¤R,×=Éí<"ëÁô%Â	ğ§1ƒş…ÊòNª{—¼ÄÛ!¿)ÃîËí&ƒ“'záî ¢÷º(«U•“ÊeÑÆ
­§àöuGÙdx[Øï4¹Wú/ Ä4wä`imc|_›l»l‹)Í+?Òf‘/´ìÖR=[T¹êÕXã%çqTÊWËc!ÏvÖsJj-Ìq¶Äsÿ:w­_‹”lĞVıŠÿ7‡µéæI)5e8²§ö'	¯hÕ°°Æ{yĞ˜·êÛcÒışÌ<Œ§ÿO³ğ®ã÷ñjÊûåyúÌ…É?­ºŞE pÑzô÷l[~^.»ÒEyM F mò”òyÏ«øÿº’*wÚxòñ½ñòzûç´í¤µ³Í‰Šâ_Õ“Kí{‚úŠğDdV~ùT¼ŒKÁ[Iä°s1F¿İV¸Îá‰1éW‰îqá4&V‚¬ $nzèF4¿
iJ¢].+‡0j&ˆÇeyX´C£ÈäŒ’‰NŠ[»bïÿ\§åÅi€
ëb­dÕm÷)ÂëñTnBfŒ÷Qİ„Ä•Îù¨ÚZÌßPæ!¶^U7íË»K¸ÿ+Zö‘›äC{ê°'‡óëé•ÑÑJåŞú.·ê¥æƒ%³´YP«šO"MÎ[LZ'Es:i`rV²qN—¯ú¾|ßkçH6d­òl1j»8o¡@œüøNÌd±ÿĞxœ]Ë@¤GÅIµ19‰¸ñ^Á2ìG¤Û¯ò›ßÕËÈ@‡>jBóôÑs…›Ëm8:@¡›šÕÀ–¯tYƒê”+ó%f£%üŸj¼‡"'çøD5áVüí0~’óî+a"ùLÃÛ\&’Ø_k¾.Óò_JT‰g7‡hUHæÚ…ß€ÅÅkÜ¸[ú—²1[}¨˜VÜ×Exò#`Ô+¢Ë‚P¨È aT¿y²Ë¨Ï
iŒzƒ±"Jü)…AšÌ9Aİˆéd]{Ø/¢ú˜øh=ùcÈÓ_£#nóÊÇ ã|ıyò€ Ø ¬ŸAìD˜±
ª¢İÀ1‹Ä¦¥*öKÒWÌ†J£,1uäšóıÍCzÑâĞPWi¤İ‰k´ÉË½²\Zò
/{à!¿Ëi”apĞ¹WvnEt¹YƒûêvTm^h<¸·në^è^¼±»µŠä÷ÊÕ‚è
}´<èUaŞvÿ4ÃÑ~ŞÄÌUÒ1 6ŞSfr{n)Öß¸²®ı?MJ¹’ˆ^»r™õ¥¸†äãÈŞşÙx7I3ùáµyS_¢EH³çî£öH`W˜ ûÿ.M*uÖIşƒŠÇv·±ë’=L‚Õ4ä‘zŞÍÌÕ9"iÍãO©vFµBçVo–yHËYêÙÔË˜qSqOXğ'îYÌ¨ÏZ•è/¸£ƒİ,Îmá»ØõHW0D
ê?çM{-aşÍ†ÚD×sü£2ÊªlÙÔ Nv1Yº½±çR ÏS÷EÍ·G€¨ï+‰ò“5CJR-Éá¦Ö,ÏºÁ_\>´SĞçÜL7ê\Ó” òïå¯3,‘ÆUò=WûD£ ¯ãĞ¡œçT<t® Z©àmDƒgÍqá´ÅX`²Ağ)õj_Ôª¢(ö·9@ÖC‚ºnn
tĞL"w:Î¤>. G¿ºõ.Šİò?}µ˜³4rH¨SÅ™*Å7İæ|bwîô>ÃhJrÔ8R(]7óÃRŸ÷èÏj›!Ò0|	Áá±c|ãíêğ+|ø¤N‹5GUÊHKàió“Ş›fÂ™X\ŒãëÀ{¶¯ Õ=§Ç2§îSÚz|¾ÆÓOp«¶¹…£{™¬?	CÙqbtÇDò×µzòL~ª”‡'-<œV÷Q#ó
@}ĞEÌ… Iğ§¹û,uôŸâw†íaË©`¯¾´ÃNÊlôI‚—ƒİÌn˜ê{ÂšTë8LOí £¶öÖ"é™«	.™ÚÄÃ‘:}ŞyÖ-‹ô/•Fó	¡v
Ùlë~t²şT!æcm.£‹yV:»µèˆ¾¼€ôÓn¢§[%#[[5Í_Û0†«y]Y——{EÀïÉLŒ;ÆÄü;4ti?Ç«L¤lÊ0Ææ?y2¥¡–iº\5Ñü>v-€¼-Â>}iåífÉßj¡)ôØµ™"Š07ë±2h·1dAÆ4b¦‡]-O¯}l8UÏ­zäãß£ L™g©êSÏ[x-ìd‹0yÛ!qö½?Ñş®0éN±;œË¦·‚rÊ½Ù=‚O¾¡É-gßk¾Ù^¶´z„q'S=¾fQrAh]—g³A½¶bàüN\%Lòñî`vBù9wî‰jåœih]Í;¥Â¬À[Æëƒèe£º<”ödÕ€0;;à^±cãÖÚÇQ¸`—‹ª4Ç¨+®B¨O01Ì4&Â¯®ö=´Îø5ÚÇ‘¯ë…ÙjËãÒ¸Vw‹ÚZ¾„³ô=c7|[U¢b³éR•–Zdiıºg@D‘AKs6PLÏùk9’ĞÙ+A>xäôæ<ŒÂ×ŒÀ^·T}«6,‡Õ7l¶7ø}ûem“'øßÈ²84¤f"€däsf7ÊÆÜÙè»ÙØ(œHÇ¶+~”á«Ë³ÔÄ\V=MßEÈDj|”¾c°Óá¾–‡o©‘½½ÑB’ªñ#“°§ccnDìŸU1ŸàË3m1©«QC«¯Zp6jljÆÈ·wvD•Öè×ò¸"ï+Á_t7“`A—:âÙœ¦Ëq„Ÿ(GÓejŒx”âœ¥¢ğ&À<ÄbcùJ‘ìÜ‹çÃ~fåçãß…ÁıWR‘/ŸÁ´êr{åj’øµ&bô)`‰¡V~1ß‘öÇ×»ˆRaŒäùÂ˜Òt¹ª¯#¥…
9«_¯=_O_iğu¦Â/y7·sq¥/l9Ë£ßU®“{@·ßQüµT×2qÄnûœ9Kït6ó™İÁc.Xüeõ­L9	_ÇV.ğnpû`¾è"½eg˜¶nQeğÕgºoöŒâCõSÛã¸èq\‹Ã°’‚ƒ¡ê0™Àw‡¡If·6êÓ^ë !€Aï ı­g?¸¶%‰ø·í[ó®3|ú9+x·àßJŸ}Íj¬T]L—­¼˜nrc0Tøì>aÙ·rE<,6G\‘û3²½;ã°›F‹(bHnÈ¢î®v†KR2KG;İÓ|xä.¹H(ÓYOl‰üYrãJå.}€¥åøMv–ºcw}1º2ª»‰Ú}™İ‘İ_•š”‰Z”˜Ï´|aTc`ÄC5ròµ7WŒ­ãf–ªu°û­N"Üÿg¢ˆõ­YÃ4mz1Ko°|‰‡W¶»?UQvÒ6tS¤Ub‚
MCmR©Èi±ÍĞ‚y2KØrGØ«ıî°œ¦ÀvÌc)ss2Ú˜óÍê{™FÔçİN”’¬¸‚¢Ş@o.Õ7@ëßƒ#yç×C4ğÜLNTIÇ¾e=İÜu`A=Š1¡­È[7»¦!^Àå`N5’°m†V?{ÑÇ£ê<+>!JSÅrR òZ<6®nn]ÛÙ%æŒPô½]§„ü8ú;í­ŠF‹ó{RgY`ˆ¶Å%—âùş}!Ûåe5>ƒ×ÔóP¥ûŠø2{¬(ÑÃËÄ‰²ÁÏ ³JÑø ‹´€$½F)}øàâˆ9mø®ôª–XôíDºVÀ¶òQìİ(à!/ªî•$v@3íõ˜¹NQn3O fåoãBj¾œĞèS	\,×Q×*hÖil©(œw‚² ’(Ğ–]ÉV5G–èüÕ‚œÄ.¨©Ão‡~¬á¯H´	k_3¦H¡§¸Ò—jYaZüåNö¾X¸e“şu´ÑÍ›•H¥TÜ‘`Ä!İtÒß¿ÄßÉ{¨2Án+šâœŞ¸ò«ò´¢º	¤“Óê»²v>C×‡£r{Ş
œ"¡â ‡Úhö?OÀbJ(¯6Yêàù3ÏÌŞĞyñ§†„:ìôãod<•İÕAİ•3¯¼ÆQ½Ù
â ÙQ‘ò–Uàv÷Oøirï„n‰TA¿kÿEŒÃÖ¬§Ø*IËøê;¬‚jíÍ_R$Ô;°A„F‚¨›BòÓ¿mJ`qP‡XmZÑsSO§Ø£A2OíåÛ; ĞßsùVš”	µ†Æw´ç|áµë0®85Ìôª‡z1—ô„øfï•u„`Nor8™Wo@ vŞç*ŠT ue™ˆ;QÑ´[ê5#×Ä ×†%Bšœ”IàhkßÔÕmºRãZ]9aı‡ŸŒAn†´ìÒç=ÊGrA»ZUˆ¹•Ñ™æoX\Iæ}Ú€bh;e[0
è™tkOS–n¶ƒt€µÛ=!Õ\˜fø²Ì7şõu¬ÃïDMe‹ÕAS§]Õ¸Gp¾%^ûiÌj't0˜U=ì{+@†&HÛ‹¯–Oä
õ#ĞÉo¤;»Å^çMh5rüyÈ†1g’gZñ˜„°®cTV~©Ë!q—%¨Yš¦‘…É+“Rd»IA@ŸÜ‡Hè@}¡†ÓÃüåÁi)x2‘‹sƒÍ.PûÔ-SÈÂè@…Zôv â¢Y¶½£ÂS÷ÛÏ³i“p˜02­Y6ˆ"äÊë]4¢5„„Já_Ó½—~>0u¦K>Ü»üİKÒš?¡Î«#!€MÊNÙã ğ¿C—ñmşŞ°¢Ë*z¼ˆsø‚!¨ÕßÃ’!FIŸ±³ y&n
ÓWV––w5	ÛÇºKÕõÑ`/Ì°Ää£¬?•‰àôÇÓÖ—\S_ô&/îìÌAl(çíƒÇ>/oìİ»G÷çí´ìÈZ&%¯'ìjX\´NÃ‰|g;˜Í·ÀØÁ.9©¦:ŠLÖ‡Ív(}bñ•7Nƒş¹€’¤±$yuà¡'îæ¸mŠšûû¨×fË§X9Î¨yµ<î¡j¬ò÷%ùa58ëÔüèçÇmO) ‚àË¬×Ò‰hl…ZÊ‡ÄzÇÆÜ©_Ë•FÑÃsÜ,ÏíÜ\	L7wç¶™³g4è%Öù¡	$a„ïz™Æ\¨ıßsT›]Ú6u{¢"€ğnøªİ%9Hn¸Ä¯[óÒ×É©#&3uö’şÖª›ë÷²6ÙÁŠ|añ,k}T/IŠûiğxeÛÇ^AO°Ä|ñù>yT‰dIúK÷o°Ü[áòÙÛeøj#»}†ôS·…mx¤åZ˜å€çJì´c€[6Å¥]qê&ãHÚlåI´×Ğêà5h>—êèy+ãV8¤ÍdBÉ­D¦*°ÜÑ¿Ç.¯Vø­ïBPLûØ«ŠÚ]rWŠ µù€òéùãg,#wÑFvn×«5³ÀÆlŠÓı½ù¸Ri7¡™ÌàÇ21¾.$ş¨˜n—DXÑ•Ğy ¦ß•ÈÌ7!HgúT·‰ÿÎº$‰³—Á¼`òûŞÅZê5zêeº<õáŠËüøÔB¡Œwf¼ ª(,6 ¤r¡~ ,b"Hfb ^À÷æ±¸”˜½!O2»0TË
QM™–÷@ÙæÂ‰~;y"T­IšÏÃï%ˆ!›ƒ#=0'Æ›ƒ|pc_ozì“{o¨¯HcöíËş¾pÃdl[Òí`ni‘Áf9°•zº›f^¦æ7;Ôn
e~
ÄXÂ™4c¿¤k4hBğÌú­Rõv¶OÛ¹Ğc†tƒ™êƒˆÌ‘â5ühµ¥[´¿]~+½D ÁÎó+7O'Ëìe{öœ.$ÕÂ9F!‰ÑÈÄ7ñ\÷küï…–òß`dÂãÇÁ@)8VFÓq
 ¢˜+”/4Ÿ’c»#y¹A3z–ÛÀWùq0éC´Év>÷t5”‘AlÆŠèôsÿZ§Õİ ÁpÜû!näğLKOnñ*¥L’«CX3åİñDT®ß·â¯‹<ôş‡/6H9!F¿tÊUş§<Îc)w©ÖàÆUÛ0à¸pòäéğpt/`uIÿ~[so÷,LÊ¬ce,ø{=;a_Ïù ¯_©Şxs³¬ &‹p¬’¢£rgşª	×nrí”íÈn—}Õ7ëp?´^Ïe =F~e^Âátwjâ¡/¿SÌRzb$Ğ\ş"j\]h>*³é‰`)¾~
‹İÚ-Í†z®DÒE|Ûè.ÂB¨d ¾¡ËwZµl	Y†J¨I4 §uPyÇå×àÓ˜\P¾ÂéJ‚+wÜ„‡	A»\àTÉ–á7Óy¬¬wæ"K8 Z…<Ésb÷_²$Ò$1¶ãyH+M½çĞ‰b—c±|A:ºš¼Q8å	ÁRGÿOƒ‰ÛjQÉr¹Æü§¦>æêõ÷:©dE8xòmÏ¹‚d¡çë%#)Sà;J— †ŸD¶DqP²ÆÛ‰{ïÍ¾;˜4$!Tİw,Fg»ÁÕü€„PË/ú˜ Äuñ`ûDŸïºmÁN0Á NÚÀ/Ş¨æî÷†ó½=IÎeòµ¹]Í	ó®<?!®í—Ò-§qã¿ö Š6 `8O±À÷}L*.¸£¡É©æÛ›§ôÎo–´²ÏzùôÅLe¶ô(ê×õ\½ú§´*¦WIµØc'z¸¸ÕÏãŒR8ïÍÙRÁ·+ÖÔ€=îUÉÊ<‹T®
OÁKKÎ·Ó=û·Ú¢ZŞ3(õšìŸ„ç~ ÎFiëHEOEü{E’œT ˆ¾¤PñÉcøw˜í·¹Çä‡<‘@@7Õ\¡}$oj«;Í³¬]ÔRZß‘¿$¤»OäåÃõdJ™ªT#TíC§v×Ü¾©ı×æô ÉH&Ÿc6^7"6›LXEÈˆğ€‘1ÈCËĞV‚æÙzêŒ¾¸H÷Öï3`ú§
ø%–ØÖÔÅÛMHY€¦lZWv¦1àP¢ØmÍY×õ´BËoîs¹"©§03¦–"½b*‚EtYHŞ`²ÂHZ,«	r¸	vá¬Q?ˆ±Éã	¸ü†¶ó")ßıAüÊ}q—$‹¥Æ™İ4tµ ÁšŠæŸå]{î+Æ¡rºçcû²:ôş‰ä½Zægşæp‚ß¶ÚÀ`fÌ£3Ò86}~qtºX²òC3Üevïë>Gaƒ;|L—”´÷Ô&+ó]Âi¦LÍp-Ğ½3•ÀµËÊZ+ñj†·/ÿÔÇ?Ÿ Ré‘äç‹–®ÈæfZşC¿;+3½{C&+± C8ı9óA@.¸¹
‰gè±•·›‡.Â[‰#Ü·"èSn§{ßÎ§š†2š¨š	Å¯„FĞáĞØŞ2ŞË!‰C&U1.|¢fH\ˆ!:‹ˆUÊˆ+qæ:<?şl€ ~…6…¬ÇÊ‡Px¾™DR·—àî¢B£¥…¿À0G24‹ı´~Ãêé°y ¾U<.XÙ÷ô\¡Æ AÕ1Ôn†wd*^Øç¹x¶Ô·'°^25Õ¹çÃHõíï¡ïxö–>å¿ü®™êaşıkÊÜ£íäÅlŠ~ˆ¢
2cû(==™guÁ’ğé;-¶½G›Tç´Ô ˜`„}Õ&ú¸.şXTŸ„7Dgä%E¼‘“EØTYOyîÁ?±Ğ£ÕÙUÀ£XQüÕî-å4HÀyMVª|DœaY] ]R2DÓ®À:µÙ›À»q/[7lµíàn–«ùn??ÍäIr’¬ZÂÉen*ïfÒ/XFñZ ™TÄ&‘¼(Qvt”	Øl›¦S6ã |©6ˆ© x?çğ›Ö5V!mÖîõ­+=ÉkÕØGc&:ğZ‰DVıKéÓş=47Z¿¬²»Èø¦Ì0[ûæòYÆú¨ºïš˜záK‚Û2ÖÎ€5Ñ^tö\Íâ];ƒ™²$—~²x=”¸¾j+ú˜¤õßBhÅ=‹‡-õ}Qäw¸Ï‡à^²K[ïúmº‚t—œoÉ~¼E¾í©‰.£OJ_¤M…ğv¬|¾ÁkO™Òqİ¤ÃÓGU:dzë«ND öÆ.ˆ/ÄU)ü`ØìaVìÀ‘óD¬ØÇ@aZK™€bC•\°	Ÿ˜ãÕçgZ”)•V8Ö|;\¼XßA%À,ˆ4ç?´ˆƒEÌ@­}½çÙ]YYáÁ|–Ä>ğëGØÍ¡Ñ¼’0ùj{#›]xÖåPw#ˆGŞq9=¶8ñÚÒc¨I1¡š g@İõŠRƒÕ1„FQ´ÿoœÎ=Æ•+/Ó^†¬œ“ÇI/2n…ñH€ÇÚû5Y‰ĞW©ÓÓÔ—]JpÉ”ı÷m©,K´xSo¦Fì(›Œq?"ig0"N¸­TûßÒánÎ3Yìq=÷öm“ñÒ¸eÒSÊôN+‰_»™WK…ÂÀ´óér—ø
6ÛywaL“ÄL#‘u™s¯c§9ÀQ<>|	­ÖÜ>n]`‹bÿı
ÃñÑò_›é,¬´r tĞVßâÓS¥Õ¢@úÄS_ïÕ×§Li,~D¤€*…öÅÎÈ.ÕbÓx0~I5ñêò4-ÌxÎ©o;``ÄU8§ù­İsX,İ®RPE|v-¨CUÁ1‰±ñŒ†Š{Ôı õñMÅïaùlP]ŒÜô¬á³5rÙ‡A%Xi5ÃBó3õK“}L[µÕ0MİIS¹×d‰¨ƒˆ´?0ÇÖJRª¹ÓÏ¬fÂu¦òá¼~1¾N]'ô¶%Ãó>T_‡÷yb£±~dNò‰¶%=|E<àét#š’Aá³»¶¿ÚXJ2Mª°®Qƒ0§¾¹àÌñ¾—tÀ{>›îªûeÃ€‹„Š$ÏYıõO÷a@OV,-'f©ğq4+ÎqÊİKçÎÉ§†zû”$øZÖÛğ$B8½u™µš«CÔ éÜÈiøÏ
ğNî5.zcØÃı7Öe_)Á³¾U=Ó@¢°ƒ|T²0<1¹üÆM¶'Y â]édÿkd-ê»Ôè¼[ÒñkÀ)ÏüµwµìÄ¯_	VÃÉ ²·ô#6÷¬ê2Ír3›6€›ƒT—ƒ[6–ù;…öò(Çøÿœ›ıX¯-z©ÏÃĞäˆ‰UñFØ¨õ9-ü4„—'ohí÷ÉÙìŒß¢)ú…‡o³Ûş÷%#¬YÚ}%€R+Ìˆû‰”öZ¡~×pA~ÀCáœO¹øŠú¿ıs6f,ù

z™6ÌáXq¤ô5—¾F*°)YùLÊ‚”©b7ïéy‚âQ¶åµŞÏŞ©
‚¯Ö—iµYDoş7rI‡±›PL$÷œPEfSKnqÂ=à]µuÇ3Òá…ÍåºNÙã
ÈçìÍ½É`óoÖœúQ f¦Yñ¬IÍÄËb…†é?‰Éi³
Vzvòş5<t7ÙtÒqòM_â;J«0ş(Îì¨®ÔB¸7ºÈÊş7şt¥›Ü,«Y§—œ«@æ¼İöo‚ÕŠŠ|}˜“â}px×®êòH¡ÔS7…KWâº4ÜFTI«ĞØÒ]\s|çCGy"!Ïeø>Ïkhˆ/[kÃõÂœ1³»ˆ¼<Ğbş@Ú„o­®öKÂ´Úd06ª±áÔ2ç Í–“ÇÓšmeì²×á\±îbµŠàMĞKdÌXŞÏrê­nÚ$¤q	¾”Ü%C¦šê?
`3ëÎ8YgAâ\¶àŠWJã`½‘V“åHd  @‘)a.Á`FCŸß£‚÷÷„ÎK%’äÔ¹ìÏãF„"‹*v*º”5ÁKğst}PÉMBmNYJ%=Î¢›ŠGCÌ%G5­‰ßPXqhnjæ½¤ğÄGE–ªŸâ7ãw-çR¹ù_7c`¤Â§Kå(ãCšgKJãsß… )¶’µ¹™oaooNÄ§ÇÑÉìe
-o7äs’ú©Q~ıë§:ÁàvóíM6¢JbíÉXê[ö¢’œˆä¾	·A£Ş2g·tîº¹i€¡A&³(*@ÈƒL¹Âk°uóµÚ5˜Şw;5 °¸|'”ünÇ­XE#ëŒ·ÌgSÇocçB“RÃs¾P‹‘YîEü˜!wRæâÓs§”K{¨Ó«·ÅN2T	9î&åáEˆ?
Zw*Lğ« ü¸Óê}Ú­¼š®o&©Cy°¸¼ñ+´Û¥]/Dzº©ØÂØÖdsš©7^h	êúmRÄİHËH%ª¡€M@T3’ÆÉu ¶1Ï{9–¼kÓ¥ám’^^é~–
]wAà§Q ¡*£pi¨óèõ¸÷]SŠX„¦Ó‡Ã¦í D
ï\½båØÑye8ÍaÙÊªÁBüØšO­mèP‡t®¶ŞyLİ(ÚgZëÀ_Ò›¸ñï_S\^XlíIşEè‡'É$ˆ¼Ô ©WGÄ%1H$`Ì?µT™ÃºG?²ˆÚ§Íc–„"¢¨«ù¹ò÷äÁn¾V‰//‚|m¾&Á *C½s›ø‚Ød|H	Iô¢&ù.oùPœRßûêå´¤ù1=,ÂV¼;sí­¢åÿ¾G¼òdãµ©K{ÓÅÜ‡NeĞ,Á^Ú&ç÷Û¥ÿfÈïúXv.)²¹
+¿†[™Ù:ò÷E·)~X×G
Åñ†Ãør(?_BÖ3Şœœ¢ŠÖÚ¬” íÆ2Ã¤3´¹]›g·]Œ;÷©ÂeL–:7w}¾BA$sO´Vò‹’@xÑ’²±¿Îk¬Ì 
:nâØrÂí»Óh—ÑœxOKñùM›€
G¨Qr¹ ]‘ì¢–êÇbj´±`Üàè¤Y;!şP8İêr‹ÃcØŠ“½ñ#“,7˜=%`sFvËc›'¥<¸Í–øcx—ÈbPë[#ÆÅJîÇ}¥ûŒ3ßŠ>‹>\KÿòK<k•ŒØdVªòà*İÌ@‚rè³pŒ6qhh{`”.ş±OÆãjq¸şm3$XÏ9Vµ.…Aúƒ¤=9ËÓŠ.ıœ.Ø©¸{@T›ZZãŸUôÓÑğÈÉ,ŞÂQ{0Ì_ûM­°€²bep[½Å^bOúõ ?’ÌhÙè´7;7ÿ†Û¹8^*Èı ¹OˆøiFl´p+fSlŞÈñMúÿ½cßğc¿Ì] ã3`!önRÇÄQ¦ix§ ¨^×µæ°Ìc<×·jéç›v<›‡„ãçH§Œ¡&XJæAlŠî0Ã±ÏŒVü¥mœŠs¸‚Ë‚8Êm#‡>=µMó(”¬sP±*M˜°U:ü’:ÍÏ`Ùz¸?ÿÅÓòYV¨b8ÇWi¡„´×Šçï­cw ’6‡2vâ>
nµ¡ª¾ ×+¾3a¸›ò¸ÂÿI ×KØìÑ:-ÃêÑ OşípD°øÜÂP?-†Ê¶XÆÎa6ÍôÅ½Ã3•jªoãô{ÒŠ•ª)ƒÖ~1¢?¤?w$Dújœ6ıÌÁ wÑ,n4ß,F"'#—‹i, Sˆı˜rùç-áÆ‡Ynÿ!FŠwwTüÚmNxüÕ£¦c)çÑi—kÎ»êIìº¸²&òTmSÚ‹ú s¹:k2(v•`Ã&¼†şğ¬y½V¢1ÙÂ>ôœ–8V|©(Øš|©})m_@ğÄBÉE½§ˆ»Ç‡bì“—`œJS@ ‹hà#D¿WR‰§Ÿ•"@Qâ–œ@£R,Ë
Éz pè‚Ÿ¯¿—Há,8-'H©Æª”ª²†:¿¬!],l-X 4óP#Â<€ÆIi¤¶Ê'v[>Ô‹>sêøbÄ>34İ‹ß¼ìxû-.ĞåP$½[5}±(c^b	ıpó?|§µ/{9"H,îjéŠ¡†ÔsS>N«Hlø	<c¢“Âõt‘ßæF63Iqvç<lÂ{¨pÂÙ~=|ÚDR‡ø™|ú5òÃeƒeK„Èñb·Fù-õ`ÜBŒËIH°¤•Üìê-‚q!Ç !ôºcø¬€PŞ½
ÊUÔ±;ï1{ºõX^?ú»|maóL‘y-g$dÌÊ¸I]ÔÖPìõËÒM+í1³X´kÊÖ¥!m+®S:ŠB·âo4
œaù<ÁoGæ‰ø†•h†[O¶IÆ W”Û7’MAx#âÎäßÑòøĞA¶ey¸òÈ£*ˆ3Q¾
ÎÏ©±$9ÿ'ŸU×÷Ÿşhê©w—ğ,@)ƒÔ#r¡õh,Lì¡Ã¬ÅÆÿÙïÓ¢Şc>Û=!6«ÎŸÓp|3§+DNÑPÓ(ÊáãÉ·
@»ëÜ”Ûázœ5üı—ºIˆ™fX'§¼”Vb.õ68šG`ßNhÃ‹‚éÉ-ŞjjŠ÷$/¨æ'§×ùšu²‰ºH‘&İŒ7©Ô}^õ·uxwQåtP®5e ´ıµİÚR°ìºNŸPmy7¬«İ|uËŒ¸^ûÌ &½ùÑsf<0;4æ½#j”dôßN)+IŞ¦Gd¶g}ÀúèâU—q&8"\}×NéÆÉ(^‚œDş6¬»µ¹Bğm>íŠÛp]L öÌàtuïQÄëü2]-è%¶7(“ÊŠ±½.Â'‚Âkø*ÁR¢Ù@¶ĞúXÌsNá<knw	ÇßG Ïák‚y)ªä}Fzm_M¨Š»f‰hQ• ×«0¡áâ
Ûûœ›¨#>ßÁÛ;(ı.[ô‹Y\æşûà‡1ÍçèÁŸ‚+†õ—2=Ñ”D÷øÑ dšËH!I¢´Ìí1áo—7cë¤ô#İ«†‹ÿ™Ægd­î]~Ïp?]êYõAå‘2œ;^YÙƒ)‚R*ÙGà}ğ9 —ÀTÓƒÓu+(×ÎššeVÎ_%nYú2Cs{X¡ØR½V|'y»}9¸İÃm¬BÏšÆ%Î•¡ˆÃiŸŒü±È‡˜ˆ#]õó¼à:6?õrj™]k¤NÌà‘¤cÄI˜×Ö<\És¨ËbŠÅ´QfE-ü<—PQ_$ÙXsBë‰åGÓa»\\Sûştqi‰¥ğ]›×4ºsÓ¢ /ÙsŒ#"®"ÿÏ?¡L%º€e&òGm‘õ˜ôğ¿E°EÇ=)×ğ@àr¬FîP!©š@«ynÒ¡%AA—ÁÆZıı0|ö/`;?xîhİ¨ãC¹õjšüzÊÉ†sğËeÉŠT*º¢°LaÂŒÓ±)?ÎgëµZ£Æ‰˜"Áp
úıpR& Ÿ4."û˜ó3®Ó‹oŒŠåô00{1,s>WšùİF•¿âÓí;ÉåJU~½ái	±?ÈA}k'µh—a“E›3w€n!ÛM¢[ç¯ı'§²m†Ù—İÀ1”@®$wSI;Jí CÊ¦<æD"íãÌí›'ˆ¼óu{†ÒåĞ#
ğjÍùšeŒÜæqd({Ìv¿cŸ]fZÏuŞ6VW»ÍqgÏ£¹R£ ½O=”Éq7O6ƒÀø‚’Å1(eôaä‘aàíÌ.`°Ò^M|<,9ëîrrV<ûÓÀ±ãŠßKŒ‚§6µ-˜¬àÊŞUímE>;Á>‹/2œÊ¿ÖZÂ:ËÁ«#ŒÿgÏõå¾ì¤Û ¡Í£üÑÆqD‡€hR–^l'›2AşdU²ŸôƒvªÉúš;Ãöø}	.Ô¼ØK&R™s9œœ‡p«Ó‡ì»/Zya˜Î5«rÿoLö8¼*Ö§qq(Ë7z¸tÀuTŞaÓ… Og-IQ`Åšş^ı˜%
°+èÁPãQCPA¼Ä\˜sæ‘:,Ù3Ñ°Óf4ZÑ,µ”$J˜hûßŞZ§Y<_	r@€s€ÿ€ÃqÀZ@Ğ…îqáC;AªÏÆ»ÙeoA’Eï|icåÛo,ò’‹ej‚&ãƒ‘Ğ}(a% r>âÜ`ÒÕ%x>Bp×ã³Øë‰¡rçá…$¯'-VO;ğçıä_7«`áGıßYÿ8bu®…å`k)Èà#Ôb¤½òÌÑÅÉ kš=^ò-*'~ KÀa[ıº«9»í\¸¾|B6T}?7”Ék¶9ô9Æ°ZOHà.å=ëD34½¡æã[ß	¶”ããÛB%Š BÚC¹ŸÆşb“v¾öË®Ø\ì®]ºĞ“¼¥#D”]=ğÚñ+óX½¡¥L6@@Á>zôJÓt¹9÷ÁgŠ˜Ã¡ùµ5µ:6. çÛ°«»§¹¯“¶;n'8É•mÍP3†ê
‘¾ZÉ{C
	 Óº©ø«<(¤cGg6­3£ó÷×fÉ©„èMe‚fİ7®S@ûDî6Õ¬IlèIaÚû»cPWW¯ÜCZßf<Áï¦ñ€ô¼ß:#&ËIW³ê ‹¹7âxæ{›ƒS:=BV2ÍœÖ#Ñ3,	+[ü¸Tñ-¸Ÿ+{£sjÜTzhÒ]PQæôf† ]çd‡D‹'¸Áºš¬%|¡!¹º=ár‰o(~Ü|G“µ¤Åà.E÷Úx¯Ê–÷ÌCÄÀI³öå¨Aä,·ã¥°²½Ûß¾›Öƒ²O0ğ4Ÿ·äÎ
‹[Š½Ÿck*	Íş¤h'4{o¼,Îmƒ’LèÏ¢ÚQÜÎ-±9Ú“ıÏ&óaªs~Ce#-ªjdB–'£¬Ë\òOÉII2~añHªê½HÁğ’L2ì	d¿¬òI&1%u€d¤Óìd5E¶Ü#à °4»x)	Ğ¹?é)Ì°ùÛÎ,Ö]Ï–2Ö%q‹ù)Ö´‘FÁ>NW+ò!Gß¶¥Ì\•À€`; ´LUÍáÊ”¸?-ò‡Ä@§â5œpıµ‚ZcŞİuµ”îU¡IìîïãJe¾Ï•Æ"6a£	+'=O´Y‡	ËKİó«0·i@„àIËiæj«l"T¹qqÊ­<ÛÂ©›º&	Ş(U1Æ ãîvnYù÷K‰<„U[t¹»;Ñ…?«zÖ?îòÄ8ŸÌO™à˜ùÈ’!)
	‚	¶JzHbi‰™Â,6ß¼ƒğĞ- U¼ÿœ—¬IĞŒ`2Hœ¾B8‹7ĞuÌÉËÔ‹£ \	KmøJ0æŞjnÅ‰.1°Å‡'JØ*	ã¦ÖatÏg$"rU†DDêÒÃí3¬OS@ünÂ1(|ÎÆê§SU@ÑœHBÙ	*OrÄÇ@aÜ6_¨<‰N=@ù¢¼¥NJòÔ¹şKñµ
ŞŠöøzÈd4IìÜD˜[\{i)¬y%p‹h(ş:é›'¿„ h3¨c!¥Ô(ÕTæ881•_WìbÓz79 {Šñ²E]ôÒóîÕG¯2ß…VKSÄ`;‰›ñnS¯¹RkjŞìA»¶>ãi'Ø¿ÿ)˜BÕèÙ¡åüµH%A
ï9Íøaÿ-Ò¦#¦)g'«˜j£¦ÁôÈKšŞ™²”¸×	#ûÑª0%-¡š4Š²¸7%µéÍe¨b‡|–t}2NÎâˆµNTå…rúç*°üÑV—!Ì“,°Ÿ®`ß¡‹O;§bİUùœõGI)ã²Oû>¡lĞ)éM|¸~‡7Öî§d5Ë@f„ÑÇ@* ~XìG>AoœPDßÊüaô¶šÈ=.@
åFbÂÄËÆíKácjÓ‹ô;cşë¿9%‚Õ±çàhÎ±‰Ø<Õ˜#Ú¦Sı%æñb;Z7©¼}°§ÙQf3Ü¥W-ûØL”W-û~Aµ6ù—ö&²:¬¾*ãK1­h@]A&vt'ÜqùÀ®o‘*Å@@UÉ:1ØëRê©›?-FF/÷¼¿í È ğ}~ÓâŠhÉ"Güô¸d¦ÍëÜ+Ô‹~òÓSJkëÜ*Ê©sB¾HWíÓ‹‰Qw¥ZnJÈ†š½{°%hÅ8À³Õ>A( »ÍÖß4S#CÑÆø3¸êÃäeW(á[()¡Ş·%FFÚP¬éÜ¨¬ÆÅ9'»´·ôüÇ€¬7= ?ÄÑ{øÕ&ñè FÛø?l“ú UQ"5!²^W“RÿvaH\Ö™¡ùØ?Æ_FÏS`¥A]Ú©kZ]¤ñâYã£nBé¤Ş×…:øğ?RÃ>øƒ+û¨’ŒåN9…Z¬ÄN7U“®C.C	›	ÙLg2òîÕµ¢ød1fÉ†¼ÎÌ?„¨Rõ fšÃ?û­ ¼Kı~¨Ğ9~ªT®^TòÏµ§·uğóŠóZ2W<‹Â‰JAÌ·cZºĞYX+gEè.Z!›¬ç$¿s8Œ„ZĞê•ò óg²ŒX6zèÈ=vEUº²ª€yüÃÅ¦v§ÂÙ¹—ôb[ô(ÒL¢_±[àğ`OOùò­™»—eê„t]vğİöoh."½†Ó¬êÎ p#î+L°Ö%=ïµ4À!^-l‹è$â+lƒíX:ÂÂ·şh{â¬Å!§â9·†s¼
rÑS‚ûf€ŞZÀb]—)‡ÚòŠ’Å3Ï€ïÜ­	³óŠ‘á›y7^R‰x-gPÙÇ3t¿1rŒ=»dFóT£oïUíl§¤Ô¨×sàKW¹;(/fÕûX*ö_¦ÓÊ¶ÕëÇHlq(*wˆnÎ `Yµ1Œ«C)ªà×o-)•s[´]†tÁÕ‰ø=mî(‡ºã¬"¨àkX@Öğùr¬_À-³ävCÁZ6İ°  é+u©‘8ßş¾~†€K¯pßõ(vÏ]I»ÙpãÀ4â.ï…WŠftG_ó=’#Á‰QŸ}b˜MWG7øw’•Ğ`QŞ1ÑsGJ•ş=Z§Ä­æ¡q¥
ŠË+ÜÃnqFWFÆ—ú…`	¹Q¶„ÒSN¶G­ÁÇk Â¹zXÊäWlXÀéûyÁr>;öÍæ_)3×?Å§	|V¸æ##(âû—v[/.áŠJŒ§”ùWM™Ï
ı#r§ÜíŒn ò/-âe€yĞı/CQ jô s¤%dBh
š n|(<qmÕ1`»D5¾Iîs‚	Tõò<!Ğ¸®‹_©C‘Uz·C˜ítÅgaUH®J ¡l‚¦½f;ñëµùK!*TSòOy	îVÓ©;çÉg•h9ÓÃ”±­¦VRxWA¬E¿KÈ‚'•@u0ô3¤18³™tá€=9«/—~ˆ±Û¿¹ÕîIVßúı-/¥ğ€ Œ¡DP^îI<N?ö»Ó^Šj³1;ïKI§›²¤&}å£ŞöL¨ÎÑÉ3´õNyÎ•O­ğ+‰ºÆğ‹[—qÎ‡‘9Ğ£Ç†Ä.<¤~,§…Çı_¯w!ŸìM¹&JĞÎ‡q«aífE“¦4Øm™ìØ^ÃÏdH© ğ˜V‰û
E‚ÓÑ¦ŞI^t•€ŸìÒÆ¼­8v³İ‰[˜­Ç¢4ÚÒCMáBF7ƒ¨Ş¸ºÒi{ÛÀÀ¼KPUj8	>5Jz²Í}°S`øÓ}åĞ¯ˆ«È`°ì<«.Ã¥ïªƒË’·bÖ¦"nÈ”­ú~¿«?]è 'ßPäô.şyã°nEÕÃM€Cş£Pã§Ï´úÆ‚CÇ6À…ÛX«‘–¥d‡°Ã‰¢‡-ı¬í¯ãwªÿ–>“SJ_løÿì›\j÷J7å¯úÅô?óGïÆÈ7¯G¡›XtÅkª³ì´ØëuÏšÍŸğaœ„©Ä;ÜĞÃÑäwH£$–²ÁñÈéUU‰5ÕˆzO³[Î$€¾æa÷ÇI$Éúyû\1Ğ=uú î#µc”OªUåZ¸†AÇë2&K
Ì^nÿhD5Èşİ‹*<½Âß¦k›•øËĞõú¦VÂf÷ÊÈ-›U§úyG#¢Ö˜x…V¥Ç™’È/uXÆ(“E>ÌåùPŠ² nı_G¾•Cª¹H H“\.eÖ°¸Å%Ù›Ğ§¹!¿ïõ“ Ï¢’P~x´ÂDá&ò›‹”ÿé :a|6–Aª	¶‰'Ûù\:ßøW#–2ÃÛÛDFïà\gJ¼X6ixì‡ä²¶kĞàÓÖä6ø:“@³YÖ––Èh»E`ÊoÕ7DZó™u¡4¨£†%«§3ü¹/x.ÎtI>÷Ñ_<&¡ë?äåx2òÄFô¿Ï]ÈaÍğ›L°vzm³20ä:CÀ­ğÚ@Dü¡©_c_¦Î§v=Äsdê—¯@)$î½} Lzw|£Bª•5ÿî_»c5 È€±ûïDØ.ÇDôj«3=3”Ç[Y­fŸI;XóÁëmp³Ë@Šh†V=¤`®pÄ©J”ã{Ò·§İ±Ş÷Òxß	uî›ÚÕHÇy(Ö¯ıñ8ÂÃß³Å°Â<ådöj>Ã"˜V;fDÑ9¤vØ`xjøn‰ÁiÜ”È
˜Â*XÊºQğz‰‡¤cSµÄts‚yYG—/ö÷ÑĞ…ápÓ‹Ç¶üHvM:>Å‡w9‡8nÅR?‚3Y›M¸ºoDÜ¨ÃÖÙóœ6äú_ÇöÊ£TtàŸGæNÊæö´ÈşË^½¿»íXwTMR=¹Ã‡‡+şä
ËÊ:²Éä¾Zønµbã•ì·¾=Ï±¶»eTÁÁ²»9âı	¨éõqª‘Ê{4^hik×L[Ûcæ -<.=CÎ(éLÂìÏ´¥[¨š!h Àİ'‘hºn…†¼Cê•{ÚwDœ‡¢«n˜y  öu×SÈÛú;‰¨4LÄJ9•"G,“®)§„ğ:Õgå'ÕmÃ;¼[N'ÆŸ‘Í*$N]Jì_ïfb±_3Ñ‘k-ıH¡öUt-wNÁ!Ë÷r^nİr°'¾â~ÅZm€¥z¾óƒñh•%;1ßóŞ=Ø¥pô_Û2JgäìT¶bÏ,8ÑhD¡J„ıú¶¿Ì‘N’K*´†  /•§¥½J2‘Dò÷Äƒm^Æ
´‹å™ßPUaÁÿÌ…I\–TÍ1NFùÇIâ»`è"CÑÓå¹(ÕE¿CÌT£	÷½A6ŞNA!}„ñ€gr±Ôùj¡¨ ÙÏ„åÆ|5‰J8¨Õ ·4˜K- ˜şwü/a0œ"¶‘p

¬W–ææO½x\E¨{¬FàÒ)^Jì\vŒÉ-·¨œ¥ş´QèÀªd*¯ıäÇç–Æ´B÷Û/F¦çqfÃnaéjA‹;órcŞ¯‰YÌè¡9¹kïCÜsPÿ¶ô´×!eÕ»üšÄãí^Õ\ÄDíÍõÌ÷›i¢ø!IoÉˆBÕ¦O¼ö.ÆpâSëªå9YÖ0ìrgI3Í¦S‚Ÿ0zEÏf'Çƒº¨rpµÄös£wĞ‘ié´¸>&£lº¯QÒ)pgj– „|£šj!ˆ¶Ã|ú›D8µjšA6M%/`—àN)O™B.½t ïyUë´S“ÇÒÌS“˜5Goƒì -v/‰¯ğ`P*cŠ@¢YÈÂcÈ¡T­DoŞˆ}j†ùÓŒ¤e.Ä­5ÎŒñ¾66¨ùì
‡:»IÍùòGäUC†¾ßúšÖ½+*Ie9YCP|*¬nÎõuPbGê ôc»BfvdÆ“‚;Ú-„î}N
.Mİ_ò.Zõs"Gÿ!€}äìÏm3¬¿ãä~ıÛ‘£y°º²SñÍÙõ]™&9zÆËFú›œbßÆr"E·¤‰§Ü[€Š94Y2jùeÖdøÓT‚ßÄí§&çÁcuó1ñ)bÎáÜNG=³®*øÔDóCFCLÈÓø­ãb˜;ê‡mz5Sîfğg„rF¥æ:2FNÓaj|`"îø®ñ’2);‹G×ü×ùXt®Ù ¸5+"~Ls}¡©WJ˜V^&Áâù ãÇ”y»ÕÀß°4Ç¢'ô­	½+5aÙ} [Éwæ†!ú¤Ûı5(¨ãÆbÈXv\ügM\O¾1ªëè£³j`äJÛüFr‰°—VKÊÔ?¤n¬Qú‹„5Ğ“ ©>èöq÷nÓê·~º×.2‹®Üe©¤`2 )³Ğ.ÖŞÉQ wíSg=âùñ‰†ô¯ı àŠË§R´¬÷>w2ÌNT±#‘!û ,uÔw‹ÿâ}°´EöµyÆºÉú*ànå‚$f‹êõÆıj÷U²-Í´&Ú6uKV¥Ä81<ˆbÿ ø’.Ÿ[äÿ»Ê›&oj¾Ã!¹ãe.ÎöÄ³
  /½‘)imLÆÑêS5‘é‘™®Âµ|¼oèÎ=Î¢4
V
mq:M.š©óçCm¿ÖB‡²a¹'4‰¼¡xx"5Õ ¸ÂKÿÕPKFãÑäâÿ&Ôä
eD$µ˜*Q·=§(¶Î2d­ É½öñU9Ş ®ÑA‚;ê]
¨Uó¯³lÀé+'£$J2>w}ËàŒ,%6œáäãjîf´/N »ùè+Ña·Fv±='£äU‚§?dÓ¤¤X™–£¡;PÒ×ª²’6yÿÉõË¿ ƒA/9~‘€ĞíXşU°¡7“_ğÁ1=mØŸ§Œì¾ù3m@û(İf}ÚÓäyé“aX2AƒëçqÕıIoÜ¾FópÏñw¢Ë¡4>D­«ÿäqŠ-TÃÌ¬cI8etßMpË)©yH¹’&nMçïI•Óæ¼ÒÕ4vZ­á\Ó•¼0§¢úr>;¡Ğ‡yS¾š;î¥ù‰åÃŞ:ŸôíÈ>ôEø©77šBh+xğé·Æ_½e—(„f>îÛùàZˆù¦x>úr[5€§£çÀ@ÎZdiÙSª&âÌÈvú’@©Ç—­ñÊõKe0«ê¯G/‚!¹…í¿CİYœ0jç%¸Ë%SqwÁ»2°òô`9U[êtÜõ¯ÇO,)İ$ˆ}ª±]í£¨5-¾Êò]Ê®şÍË
EQ>ö×¿ùô	iÌ9Êµd9EÒ§PÇ-6RÍü¼|Y5·©ñšºÜ]|Ï÷®CÙ×%…×.µI|æeŒ¿XÀy]´ªÁÉÀDå2m"|¼Œbœ9‰ıø@à$Ù9|v™\sìXiÉò°4º •Ö
‡şhØû—AbÚ{ô×,~ÓNÔ¢¸Ñşğê^kKÆ—£0/B¥u³Ï ”
ÇØ#İÂqT§=YWº$ã5›zç
ç!Qßô­ V!ƒ:t%³aB¡Q·X%¨½<—ıÁÍ8Du™OĞû¬:~…¨ÛNGí•É!é>ò „Œ»ĞòÆÉÆ"5AEñp`Å<­òØnË’`ƒìjt÷LÄ52ÎA©“R_¶Âô.T×‡&Äïj¸Ä®M–Ğ©|8DÜÖUïşùşÂ]ÏœõÿãÛ&k/:µìK–¨5¡Šw‰Ü >‰NU®#a*¯ê(¼3J©~ ¬½äšt•XÇ¥ŸçÂK¹×Zø:L$ Ìjşûè8L=ˆ47Qºî­B(—6HïÑ¥gSğŞ@µÍ#‘6ëàkE‚>ÃË¢ß;ë	÷ôÔ@Òê„§exâ	ØŒëÛd×íåˆKå‘Ò.0«0¸::+µ´‹¦=ø
ÜVxlpX®Ö5"ñƒ=J&`¹¿¼*]WAú³ü¤+>eç¤’¸£Ÿaû¯.)î‚>şZ­ÕJú[PóóYäúUíõd]‹¾£9d)úbµzÕp0ı×gÛş%}hv¡?wŠ¥x:¼EV©ò‘™™4èz—–>F2LAˆlPbn>•y!ËÿõÌ"Işj)næ$fK«µG…Oñ(î`ĞƒĞ(auáË”ÂæQ[h S¾½™z8ÅûEhôÆü¿v„¤fHĞœ@ä4Ö~k`Ö€}}Û‹H²ıK·×‹%W‡[Jı6Œ1óß t;V‹=ú&­Js™âÕ„9É0T‘=6ílß#Ğk†JÉy×Á‰o¹?ıñu!»óT³»yQ%ÉxÎsÀİ[õ^j6„}“TÙMâ‚e0X.À¾ óHÅXºıw_ ö'©-"úÉÜjåd½İ¸’(ºàµ ×O<ÎbšÇJ*IŒ½±­Ù“€WØ«ïtKª]4<Ú„Mö\oG¿õm7_&şÓ¿˜E(—§„q"ĞÀ™:Âì2ºĞn¤î^R(¬ÜVbË½1ƒ“lÊ±÷t×Qè/é·09Ëø-uèÙß»¶/±	–)k(‹¼T=]ú»…i¯:é·»YËÃw˜èl“}b^Ÿ
8v¿ãe¶cÜı
ßÁºÏøƒ 3Œ?æY# _/B§ï¹Æ©jîY¨LšÀD™@ô*l©YLÓ¬¬4š`nóËŠ›#3^éÅœ’¸ÃÕâr”{ŞÚ”ÆãÍ¿p!®ü4¢b$DJr]'ê&M6_Nç?èÌBª€ü¾ùÑ©Pøú vÛ9G‘#öVpÂwÇz¦.â/¡Æfg(¸Ú¬ÍÜ\®÷b9ZÊÕÌıuSêÔåoÃYDla´‚×³±—ù3›ğ;e<ªzÒW}Ï?udêx-üÉJ™REòøs×äïÉN”`	¿süûNæ¬Èƒ¬ÒĞªD
“•b	Âí<~Iæ¶ ßï½ğ]×{pt
Î1B²ãÖ/Ë½Å]¼Ãˆˆ<¿şWTf„4¬İÿÂ…Î½œM\ªAFy"sV×1±ß¦¼Îô?Úé/î»	Êƒzb‹è‘m¦›à2Zá›‰€SB‘¾T"^/…v¯¤yçûéñğo]¿T'Š›‘JU‚2×9!”¦b'÷xÆÜpx7S¢v›°‘	‚§s×Òª¡õ^ñèuÿ×çÔQû rX2
hvÖÓlbu—¯N*–¢©ø˜ıˆ(AÁ	F8Ë3ÀÒñU¢h³•.R!B	5ùó,û†eøåèp_5áh²àHİ71İ	Ï¡>zıõªî)Btœ·«®ù ‹‡vTf§\ï«¦ñ!/%0"…ù<Y=|/İ½«û1¾i‘ÿ÷Ö<•d½¾ßº›L{èŒ Ï˜¯rè]ã‘We®óÛôê­È©œAw‚±¯“HyÛ…Õ¥nŞÖ.P–ÇHÒ‚ÆÓ¬H"ñöst*êÖG2øZ=^–‘œs y‘y?„İ¨*U&²sDÄéñõûeAÑÅˆ7Ís¯,[kÿ4
p‰»`¾8àùA¹ÍÄ¯ìX'ííë³Â¥ÛÚ‡KBe
wÌ?}›”î¿?ú/¿É@ë€]—Q\)ü·ÏÖQõL¢N^Øùá¯ÜxùMä`i„vhŒ~‹’e¶û¤6Ö!s{=’(çÌhÁÀuI ñ!áØHuïj›´­Œ•-©ÍM¢ÉÏEGÂ•¼‘ÒÊ1uŠcò~^50»èªÏÛÔ¼%L¤~™"Y­Í›v÷°Ë;:KÊ¼× '_$"p¬Ì{´©ÚÂÄ¥,¸Ê¼CëÅı¤Ëu^k0ã4'b%ÎÉp'ñuÕ†æ¯ßÊ2µ.B…š„¾úï\ÄÌŸ‚Î†½scªYZdî…[›XºAİŒ/´Û¥Î¡CË‰û&Ë•Şq‘®×Ja·4:ˆ)²Ã• ºÀÒ¼ ÔYx"³V™MéİzöôF»{‚~&7ÕºûãïöE•ÂØ•¢28,2	´ƒ2ˆ…Nz(Ì“à›]<“iqDŒHqfvòĞò¼Gæh&‚÷àÈKÁµÌ
U)ÇòË"Ş¿×E¾¯2òõîJı‹gF8ı£¬ˆ«)"e5¨Á¶ä¬˜Õ#Zâ NÏ¾×/üH"°C ]ÄçĞK©ùq7Ûmø#D›íO'³ú·•Røêj
§Ü€ eõLn©®—ö‹á$lıµp^ŒJRü@wÿß’ºÕbHœM‘Ò¤ò¹Lcƒé…€›Öı‹^r5À«ÇÌ¼44wéø?FÅd²ªIƒ„k"3ÈŒ÷…ñEK÷,ó×1‚?®§øò{ò›¯ËûJUmÖG›[g×;TolÏ_M[Z#’É ‰ÈW£”;Á ¼iyµİõï7şÌ:ûısÉ¾Ü[î/Ì-ÑÈ[ĞLû= ÷6ı“‹£èl‡†°ø`\òŞ{ùS!²Ö¼Á—ÿ°²)$îÛ^ö+ù2 Å.7}rŞEµİ4Y¨°6°e¼CÙã%ó7ĞVexm¡-s*¯‘¸*lø‹É
{¶˜Á±¹=÷RG´ÊWø–t=íÓZÄX¶È¶µ8UÆ¥’ê¿…|jd"&6™0â†Š.Á.*\€Ù×Öuá¹]jxñ“Î«¦e[n`ŞO„ô–o €RªbùåoWä…k0ï|¯×­x¿…ŒmI˜Æ0î÷ÈhÜ‰ûXÖf£aB£¨àó¿²<¿ÿÌB`¢¹Cv
òÿ‹ÈîEº,¿q¥ç-é#ç.³âJïgö¯
¥¡±´cråëT=&Á´õSÏ”ÑŞGí™AŠüšÀ?ËvŠèédÂ _ÿ¶Î+6æì«Œ!Aş¥u™ (Ôf4ÀÖ	¹ÚPÕwŸÜ+Õ-Ş>±ušÔâFdÆñ¿Òì¿S6Œ2½B|PiuñéÁK¡Ô,fF (xvh8lå60äu˜iÜNçYO‰ÛYü’›ö–!ŠE
“'¾c6Š^uş×®÷#2b>2]Ô–Ã*o}¾3Iï-¾Í0Bº×ñš'?n&qXÛÖÀ~š·í$¢ò9g(§é°:·2ªÕ•Åİ42V8#`jL«â`xºeád­ô.A^"*áÄÂa,*§qÆŠæ4Ş3¦mvÑ6kÏ~ÅF“rÿ–ùíÿµÜ²WÜõÖohûªòdâ|UnY÷Ö_D“«üâpäêÿÒ¿§#!şV2°äQí ?İ¤X¬ü;¿¿`à™ÿÄß³´†“\W’
dk•ı}sÒ¦İcê´é,×¬ıíªÏ.1[T²€n¯ÁHáœS>ñ=†š›Q,ïZ¶Dæ>ßğ
mò7¬°O@Æ÷ÑK;êL¸„a´
ëŠkÀDî÷ÀOAÖÈÆIjº¶ËàOƒäé~£ azsj²šÔà×È-Æî‚ËM,ï¬ó-§ß«ŒˆÎøêL4^“ªs”ÕÁ.‰ópå&J)iÚ¬a»ÙˆåT—-E(\·–¤6æË¼$î#ƒ>°".s…¤Mà!$p*ï€mÚ¬ĞN¨ã¤GÊË‘} ƒ9>m_3µRÃ~Xİü4)İèÕ<Jß­º‡³š?èQ‚õı÷ùŠ½nx©xW© ¬Êß*PßÔÇ7ŞWÁñ«	-=HûG¦oíI0xTdÁÆ-1ÇêĞ;§I¿9Ü£Ü0Å!¼·H¶Án€X0ú_êgc7I£+¬ùíy>xTáº2bv !è\‰=3RñÁ¾1£
ìXWºEåpãE½ô›$}ëş@"È'=„ôÎ;O‡sy#åfo”ıÔ9˜ç“:mÜ™ˆÇÁ»u6+ †Œ—¤{mˆ˜6£áâÉ÷²³¿„Íèñ‚ÛSj2S^W–ƒaßñ-Vt$#b¶m‡¯úÿ'eú¬ƒdGÓ6-ú±;\Î=„G#Ò>Iß*Æ3m|2(¯Crî9[ø~]¯¸³_¸†²uKÕ’Š-ÍQbKˆ”Öè®é™Ó¯Bß±¼]ÃËĞ?‚ÅüFx¼šßè®TƒxÔôL8Øx-g¡íº ˆ4¾¿v€³º!ÒY]6zP]nBmiFİdÍîç:æ§2bGÒ2\ªî\ò	şGÂ˜ùonæ³ĞxyÍc7SÕØSÓ´K™KCvÀöŒÑæ±ø«‡U/2Ùïì-I{çQ¦ gi7<…É˜´uKo|Ä¢@câ§V²ªvª1æƒ>Ù|ÉTE¶ÀB¤İFÂkŞ< W¤âq„¶­/ªŒgB}!]“GµX¯~kCj£u¸0~jÏ6ú}”ë¥İx€œãîux"]FEEƒ³Ã%Ó\y=¡h¬r‰Í«öI…Ïf½5~ÏtR4’¯áÂmíxõU.‡6xów¬àcı'U¶ä<†›D%Ob+Ø7?VhôRlEõÁ ÑL~ˆ<¦ì´<y–èRúb¹ˆR   
¦¼/Ÿœ “µ€ğ9Ö$±Ägû    YZ