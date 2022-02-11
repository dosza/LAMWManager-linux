#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1088877909"
MD5="67bdf55c621580edb1cb5bed705785b9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26484"
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
	echo Date of packaging: Fri Feb 11 03:52:42 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿg4] ¼}•À1Dd]‡Á›PætİDø¨,¨ú-Ç¹áC¬ÔœS,ÅÉ¨?ÚjwX8–º”U»i$Fkt³]æ¡h0Äl`™°¬ø«˜‡H7/¹÷qÖ+²–ÀÚ?yŞ-zÚ®üh¬Îé³2'_ê‘âµ òƒ"“u–dì<£fBB¥iø‡¦1Væ±PJ”x Îî1<5äÜÇ³äì¯0¢ tf)éõFæPúM£*Ş·Ê}N{-}˜ÿ\²˜T§‰A)I+ÓÛğë….Dé*X×c`sDë~€Çâ¹„´ı.¡›ûú…A­ÁFg:ü»İ’¶¯IéöWp“ÉİT¯ÊKp6·&6<yIo
GíY³¾7ò”
m;Å¨bÁëØ9ƒJùFÛ  —~©êÚhº’x@ş Dûú‹º¡W½ Ã1`ôfV°j£öU3e˜ƒşàŞİ‚gÂ°\6(ê¿gVwN¨äRÇu'y†¬çmÉÓ´BûÂÀl]¤ÂÙ™ÜHƒ†1+»¨Ï	||6ó	VmakÕô)ï²-ìC]wP ÀAA¤ê;ÖéğÍ½û%*	¬šñâ?Ç—G}Ò‡3q0ĞÕ”DTÿ» ”â}ëÔu.Î—õ}÷
•aê úèeÅé¤Ú’ÀàŒ²Dœ‡¶”NÛĞô€D²­õÒ·„ãŞ;­x˜‡g.JpOPŠù'ªJAÓ;ì&1kl>h>ƒı ÏøŞ,ÈŞÍ’]
ÂÔ¶äë0Ÿcı(,
%}¨:é#<“Ô˜0Y@ßúOîX™HÖR»5F7rÖ\_g˜Â’cˆÅáSè¸$z6@Xøù%ˆLÏ_TMöê\p˜Ô‰ŒdÜ<÷ØQÁ8éqïZmH]{Ü²c6A¥ÕÊ“ª7Õ8…ğx=m ùCÃ…-[ë´nÜczßeÈf3ºÔ™Oİ®Gbg&s7Ø`Õ¥[mŒiQ“Ê§,>…és¬U*,! : ZBãZöİqÛ8ÎŸ€ºFB	ÓÑ„=Ås›~¤H(«têã)zäŠ×?ûäB j*»øÆ…-³¹…g­pH-ªÔrù±.“6iUa¨ì3£Çüğø¥s¿+&!Tó·
cD€Ë§~Æ—Ìq< í„}J3g…“fÏÖà#*Õ‰ÔXU¨NB-ş´òì·–-FIQ3,Ïº¼Ço¬\–­çÙÎïaWùkc¼$òMñ¯€pidEhè¦ëïı€ì3?v)½S'(š<ƒáı­CüA˜°h^"Ş¨õÔ¸bĞW«éùÉï+Å´ê\„^ÜÎ0Ñè2÷öAsû%³ƒsUÀĞ}ÙpàX3•MGn‚ã6F’dôÄÉ€S ~tTaÙF¼}r¯è³R·9æÆ–¬°Û±'ú#‚DØA¨¬a•™²	0o)[BÔ[fáÍ7ÿ$”l¾õ¡“2[eü£Òwå[›À‹xJÊşQ[¦±O¦O
«ªè;4èIbó<I’£O‘`CE7qÜóï-€4Ú05&õ°³¦4L¹y€Šâı·ÏoÂ‰&ò`–ş ŠÉ`@qz9è1â	ô„
óÓÎj¦à•=wûFk.µñÌû¬ãh-”ù½1Õš)` Š÷RãZÎ©V}>ªe¥ä…²ÌE{´víb9/SÓ‡Ğ‚Z-$“åqîöãnÆo).púÌr!gÂ ³/=ve`$|ìßÁ¥Ìèsã2‹oQÏ»èé+É/i§ÌĞ½u<wñD›XÜDÈŞnéMªo—Ícm54äOÔïŸÎØlXÌÛ mH›ıRÓ#}Q MLn+ÈÇr·CJ`°šP>èÒ“AË 1VjÏ\X,$Äë‘QfóßeoIµé®¼{ÂC¬ãâdõS¯‡ã^ŒÚUZ<[¹|’ˆwPj+ƒ,–3Ü÷óñç¼Õ÷¹ˆI‘¿›ÿÊºäÇN‘@Ö©aİ/b,¦¿ˆÓF-°¹÷ÎÅâ{O~Ñ…‹5~Aeè¤ªÈı½ËWí:5¹Nˆ)•°Rùë3‚'‹˜¹|ı)».ÊpCzÙˆ›ç¸C:>±"‡\ Ÿ—õ5ÏÁòVè©°ª$œC¶_Z¹èbíÎ@5ø¸ò¡Vi|¹ÂŸNFYğ`‹¶ÙêU+ÑãÚc kBHÌÏû71P9µç¾Š¡€>Í¬MŸŒ¯%%ëiÎ—ÖØy$Ó4_'êp§”ç^ÒÒaÜÅ52Tä7âwQÜ²K‚X
Hü*ôõŒßÇ£ÜU¼ŞøšŒjvÀ™¶(æ"ĞÄ) ûï†¶a&'ÚÄR-pèZšœØ{mv°N•âëwNr•sÕÅåœ¬)r#ıh‚¨öL‘ÒÇiázoœ8Èá¶ÆX…KlÊ–æ±™Ï›íÒGõ82)—d¡í„^Š[EîtM‡V®¾¯2RDÉEvİÖ_ÈÌKùå>g¶ÃŞ¬O¡~¢§Ï¥M\€d¡Kƒ®Jxß•[ÛoÈyÔÑäƒ|]ìššìyü•¾¢~lıº#±o ïŒ~Ÿnÿ‰NËZ˜õñN$)ï¤ušî|«|'jº~u;.ùé/æÌà¦ÓUUéÏÍnÂ¾4ÍÕ Ş«Âßì:‘@ãÊÃÚÁ[õù±™’‰ˆLÆÁ”î„h^A-iïÛ•_êœ ¿krÓÎSÂŸĞÒ0Ï»Òôb lÅ`«_º†˜ƒ½ÇØ³'ls4÷FßºnIvLa :˜&÷ÙNZhZçö}Gş+4èõ)’v¶U3µ\x›H6¥ı'*®íÛoıÛñ#îNGj¿¸d<¥nˆâ­‘3¢ıMY¿[õ‘±üPDäŠ“9Kşİyş[#é5ã¸C zc¬zZT±r¥å(E†Û¹±Ö»‘_YREµ<uÈâsáÑ&¨(Ÿ›æÑ¹Ò¢íXƒ7WshüÅ»1©û‚Ñî=]æ u?ëE›*fÉ¯aB‘÷ÑYXJ€Ìóu·&äËs¯Ëı%aÈÒ!Ç@!"Yt%Ó%¯^­6‡([mâé‰û$mÑP‚OëB2gç1|É¿Dt(	 åáZ Î=4S)&C#c{Šdbùë‘ºôb?p=¬ÌGı¹ *È~‘6Ö/Ğ©]{xÚ$÷b°§,{ÌP›¨r¶Øƒ‡ûPñ7ØqïŸ åş-½Ú.âç MÑP§>àÇaİ3í5U1ûÜNM¥4‹àù%tahB\‚=Ÿñn Â‘¥ZÏ­MÖp¹TÅGwC"flEgjî)’_;KÈ-ì‚:ÍüÌ¯Öªè€o¤lö¤À3­B­;Ä†=»D…ñ›=hwºÿ GšößŠJïÖ“ÿ<—
¬z K€dÙŠSQŞˆÂG›o·Ê}Iùa´¸_GOí:(0Ó¾¥Obmõù7)A4j<Iì(Â¿¿ıXRÔÀÓ’øƒp6ºª_`A–ª%Ê6SÚÆõªX‘‘)´© €‹ş(ƒÄks»CmaÛMõ‚k¶9Ó2Hô…¨oKU^RI¶'ûö$rqFh`À¤C ¿-Ç\>û1£M²n~´F©V‰bR#,+›<ï'…lã0¬\o0’²v:¬²½Ö	€˜ôH"Še„,Pı'PWAâ šxB+ï½Y«“1—Pºpª‡õğŠfƒ=ĞPõ¢Š>ÌªGÉ}Ã3åiª@m &Âõ“‹¨ƒÎààˆUù-4½îoò˜Ü	ïPí¥®¯‘7¶–>&Îi"”re¬
TÓÁ'ÔÇøGÂ,uéˆ€œÁ„¶GêËF˜À/h+Mà×VµúF $\úmÓÊÄ¾=pNq) s}å}¾ŸŒg|bÅÔ§²(ÛñosbÀ¹ù/4ãFŒ#ß)Œ ó˜¢&ò©ÁÌm÷¤ƒı&Ã"7Å ‹£h“áà(*`æñœ„ÓŸşó÷Ñ¨8&ƒ­ê÷ÕèÛŞró²¯€3dUç¸€ÊÁ"<WYÀŒqÏ	ûÀ¼ra›AtÇ/__åËC4W–g¤‘4]|+îª
Í
‹“Óh&’½Û´XĞ’b-şgr¬Ñ@$ñâw´6¹¶zİ‡‘š´oİRç?vfó|àğ3ÓáâÿÇF8+™¶|Fb<}ø^æÀcÇTD>%™0°}‘=tu×Î0‹üË!u³„ôôÜi»J+0a;3Vvë?Úg—İô^3‹ 6âõæ(Dí=„7Ç@Uä7£~bÓÖ½ú½lp!íÔÚ9#‚`¾¹@-&ØeÕwt)L*™äF#X÷£_ê\jÜ'ÃÈ“»"ËÉ^[Ä¹â3w­Á^À#”*ú¥8øò¬%@óµ–ó´Íøï:Û¾$¥RæDÌ¡q}´–ßvÅ;ÜĞ‘3²ä)ƒ0Wá?ı’Xı/ÁçÍBÑHyùå|è¶áV†¿i®ñÜs;†é£Ï«û¨‹S™_L.¢	rÎ›>V-Ücü’$f	AIk-`ÕƒYPÌî‚Sn\ôÙ—çóræÜ2Ò'ÏĞÏÛ4çø¨½’ÛÈÃ%Ú#Ò¬"ÆÙŸÈFCuŠÀwÌ*üXĞ*ÓÚUJÆ¸!î9ó"¢5'¯ Ä­¼âı6ùşÄcXöƒdÏ\*©:<Pz†¹Á¼E“ÅıtĞ„ò=0É¹XAG«ÚÃºÛp¯§%4&ê`Ñ$•i–6?‹:íğÄÕC&‚G®ÜÂøİşU{iE^Y½“r˜Ó‹e8”s¦%¦¶f’¾ÍåÙ´«e.Çû³_&!s
_˜–İÚÈR®©ÏÎiÜ$08­û—I‘ıRU	,¸íÒ”-„[S­{*Î
å]·&ÉràA€¾õ»Œ,ÄáÖ«~äç{ôµgD„ÜÓ¡aØx^Œ?óÈHŒö!ˆg?bcJI°
>«ÉóÀ€>¾¥¡À%Øú­€SZp+`4Rææ·&'¬àPáFòg»ğ•ƒŠ“I'CD‚µ?¿2
˜Œ²k^Ê	.8viqÏÎØF»ó‘ÑAsĞ¢Öî™b<¯@Ö'J`²“?u±WÆƒ-ŠI8H¢ƒbÇ ĞŸÓ§§ê™Õ^ëÊÉJ½¹®ng\ªÙ=q]kçkkîÒÜ—ï„˜Ìİ0O·U×êD*æs¦ó„¾S£–ÃÊ„t§™kÂ3;ƒ9è ìL^¡3°şé|~h‰5©¼6 {¡ÑéDÇå®ä¿BLó°k#;@âÁMïÊåá5ÙÃ",Sx„¬ƒ1Z	ÅÇKö¼ƒİ~¬r0d'¯şeNr†Ã/§ü9§iRÛhçzÅ'¯
ÀÌâ»ïQüuAcTy·ñ
ÀÇ©ˆÖ… a‹‡TgwOïJ8çCŒ}@Aœ7Øeğ§vMÇ¢ Óq³dèLÁ¦²º˜ã9ë×ÛÏD›YùQHP ³Sí‡É“’År,œ¤f¦›MGq&Î ¡;à‡–Ìêì+š~º„ok×ÊÁy?›ÊŞEªv>Ñ÷å§L„O±Ûò?Š0ˆ$É	D}Ê~îèãü÷Å/[¶:,sØA ‘¢á*Ë )8ÈÍ ’¾‘¡¸ş~î·!ÍìßÇò¯:Ó@Ø™@¾s¾¯v%O^˜ÍïF–„Œ-†v>|‡Lí.1Ìn
À“¡Ë–É<ı2ÚiÚœÕ8ç­‹Õ@p.*Gñ=8ŞmÅœâ17ärøÓ=	gÂ´7_Y¬<›ÅI©ŒmÕÿ²Ğ8oxLŞ ˜õÖIÄ}´Õİ–Å“õí¬•ÏSOk§íÓúÅéWÑ{¼¦ÍHŒ¾Èš";e,Pú¯Ç¾&ddú^6	7uŠBÍÇ14ì8„öÊ¦îN‘ïókÏe¥Ì¹Æ¡1$|€ê	œäv5á3çÁ—¯}‚øì¾–“t"%UO¢n6TYGâÎoq1WÀ8rYÿ­\¹V@³u+ e£ğ7«‰˜0ñAŞàÂ¯¨„•X¬êğ:VñĞEÿñ¦¥‚Q·CÛ‹ãûh™Uù syyí¶j ,i„÷éÄOo(H».E™›êqÖ	nêÂm÷>ÀZºA2@í±KúzÖ{…«t7e¶©hÛÍ…Ÿƒ"&˜p|ºY¯aÚİ¡¯”ÉÉÄ¨Ÿo/8¸Ï¨v_š¸˜ZˆeíE‚#kv“—n#óÃKå.CõgC#±‡˜i${^ûÒ˜íù 
VîÇ0[ µÏq¡Iv{ÿ‡”æ¥ƒA™N	r½¢p™yKé¿;Oé×–¾[Ü5²L$—è.mØœÌßøåa³6ºÓ‘æM%€Ú‡éĞªD¨Ùe°sYÛäEz¥OšÓCóä§C+¥ŞİØc¾œ‹à6¤ ë‚vªVéäÉ–s¯+B†jw¿ØWËøçúÆ‹v%?æìˆßÉéÚ'Ù”@ÚqMGßŒ‰\>TmbœVùaû¤8O,]Bjˆ,İçÎV»2–#%5‰éŠáªÀ(ÉT~>HlfôŸT ıÁ–;»¼2ÈLÈsƒOöóà=Ë	ü¿gpˆLTúì€/ 49»™:åâşHş"–Ì)M®+WÒ©b_õOE«‰¯%¹4ïL•#ÔT´¤5QÔYÂ²ñ¥ZñÈĞJ>êJB¹ğÜÌ9ªÔÑ…æ¦kìJØÒ«Gı?.Bñ®‹®œ¸Î€¸iô7ÏÓEşãºX¡ŸZğ+,&:æƒÇ­ô$rB]±)]~4„––ú$Ä‡©¥È˜s(»‘|M¤Î¢Á’÷FwÈlUàp4Ï¯T[àIÄ‘ş;“\îNİ¾±A˜mCªºTü@9™ºO³ñ8XŸ­| S	WKM@ĞÆæA¾À¹µùOp0íRgDs%¤y\¥ cëù1BzÚ]¡3o)Ö0ÚNª0ÂÎ(u`PÂˆF ì@-‡í;4¯EîJ*IHŸsHI“±·z=É|Æé×ˆµ	nq­@)k¢1U„ÂûÚjXÖ
€yíXk|ˆ[-òã˜òX»‡ß°æ(¦ËÇÙ´j„×ÇVÖ"*BRªO¼vÑ`13(ÒrÂ'Ø­YÀÍ½Ô´Ü”hçgßln‘î	G;!SOHât6Ò;Qó°®ß¢ÆšêÊ#M`
AYĞ÷Ÿ¢\k˜Rˆy À®„âÆr¬u¨ìØ-c·ÛŠÙ\´ï×Äy5áı©é}aæ‘0ELucP'ÒÛô!¨ó·’‡ÒˆÆ?âÜâ`òªq*$‘ú”‚%ï¼qn˜Æo¦È$W¢ûâÄèêµêç¸{PK­
Ïi×Î>Kü„¾²6EAPqÍ	ÓFY:å\Q¬ÈĞgÃƒÇŞ7”¯yâüø@ÊÏsúî2Ç°^´m¾âË¸b@%™CVi,Ád!³%Ø€…ğ7så6ƒ•¡êil­¬Fr—ë´¹n)Mb¹åJòÁÃ^ËÕk€¹úO‘îÊx•YüúàìÊÿà6J¿™šÜŸ¯"öÕk)ş2PZ–#ÔJÓh€IĞ0¥®üEí2ü2«—åkä
õÃé{‡óåflˆ”ÏV‰•Âë“'x‰ˆß D:õt¨¿¹|ø±à~g\+o½77¿Ğjˆ«ıÁÙmÂwÆß+%ıVÔYDñÒ~ÓÖ(
¯šâÄÀ M6}0J`í„y¯b¬¶¿]v¦ôQì,2Œ¹“ƒÓ>èÖ0Ò›À4 ì	ô„â¢Íz‡¨C£‹ãC=Ñ³Î;Uä¤_f]”™¾óŒÛVú@êãëØEFFÄBı;¡€ıù×ÈFZWHĞ–Ÿ îæè„çu[[MYì%X±º{ÑúÃ¼ş€¹u°P!F†İ=³)Më·ôîéqèÄúNôãæ“8š+‰µ]#†¬vá$OÅdxü"Uú/<á÷á:)N|>°Ş3Ä_EWÒ3W[‰Ë!šk§ØÒÈ*‡ÿ^qyU;púg‡¿ìĞ jï½ADpš}jÉ"‡ã|‰2½n~×s°ß¹’Ô“3ÿø‰T”DîE‚¢@¾1÷aDœl‚/…°D›É³H1tj§úà#—×Gu	ÚúŞ*¯C3áï6’œ7ı'ìÕ%N^UÃ>‰c:ñ)‚FP9
#øià§±¢ëC›â®àcÀ„½E>]ë…°Í­+K·ëSãéXÀjé¡2>iŞ ½AşÑÊÂşÑ(wux¾K8§Ş±PkBH?ÅÃXÀ»Òózÿl*]Gdì¼VŠ‰öuï-',i¾¢+¾ÀĞe+V*1%¶­xeuz¶Z ·óo…yÉÕÕ ­f:áĞ:*)Q„ìÃsDsÛ¡`~@	!^Säéæïî
ây¹|s¡›L¸8QQ#$Ÿ*Ê[^ş<ÄF¬à!‡|¬<ğ¶Ÿı±\=xı8#ßu
zátó2¨-Ò%ã»ğÇŠ•5»02T@¦AF—0İ×0İÉÁŠíÈŒ™mLçü@nš]¢0§úQ”Ã¦@²|Uã‰è©«Aa¿[‹M×²DçŠúšT ¸±Vë»*>2·Ô+¡¦ƒä„<÷\C$Ï}œöËèÓjlœú°¯kü‡D`sé"ó‡M6ÇC¥£ÛÇí 0$áŞcÛlÅµ7N;ç¾–ŒE?ö¾Ô:I–,.¡ëªÕ|æqbwŸÚ`·[ßÉÔ½*Ùä"B>eÔ“å$Œ¨¢úİ—…q'J
Fƒ8[*îÁ§MG¨R[Ëƒ"+øœÆ”!{øsqE†Ù‚^«âwÆÎÒX…}]Ş?%¤åCú«oÎÄµ/	ÕòÑTÓàa¢€Á&kB¼ÅOäÇˆwÄ†úÕ¸jÓ}Z½ÿ—ïŠ¢ÀÃ×Ñ£c÷G¨İú-/ÿé¶FJ5Ì£5EŠ	P8¨‹»òÓö¬ñkuß{¶3õK(Å‘!‹ÏÓÚûà·‘±Ÿ±=¥b1,%pt}¡æ
¥'\Õc8ECĞÓ7Å#áÿ“:<ñ98	'sW”Y¿£Nµ%/£
,zGºä)•AF"S6+[¤œ%´q¶?w¼Àé“’[¬Õ[#VÆxVB1ÆÔÈË9<ëÓ×˜³ÈÂÄç+MÙõÑCÂ¡ŒLbßº4Ã	9Õ‰Õ…üÌœqÔš>ÿlúXëó„àSµ&ı§d	¬TÏl	Üıâ>‹Dğ?eˆ0ÜQËúîĞîÆÜ…§µ9œµzåHjQl&àÙkl¢u>Ûáè’«±æŞõÂRÑëd5ìÙ‘‘ŒùR ¢š®ı‰î	C5Qåd? SaÆàC˜qw»OJÒ€†;ö8/‹›"8 ´Ê®­ó2Ö&†6î•v)ŠÛ9,š.ñy@ı-G7Ã,u}“GMÅâÃ^T¿…»nõ¬ÃqMş”0$ñ¨YKÂŞéLJÒ>C·şb’<>-6¿{A”şG1$YË¨½>-·ËŞä±àÉˆ¢kò•—«ÂWiÁºœ¯±¿¢VCy¿(xLşk¸ûÀ“„PÅ¿n´•‡Œ¾İ½a¶±¨ eQPYÚãCÚZ4£ıx0ï×éYâsûr¹øÁu,À	³ı¥áòšè{iÜkÒ€=cÁ¯s=}yÌ3ÏÁˆ«,³9Jîä	×¹¹.í2|àmˆÊ"a’(¯ˆã8u.¦f§Ê¶â])l=À&€M’îÅâŠÖZv8{¢·&¬¡Öúª#¬$•µâ{Öû?‰Ï.¼½°øamĞ»ÜÂLx#…äc§~ ¿‚É·U ¾l‡*‡l#ãÃü‡X<¥õÍO-½Ë+“f1öQ‡ğ·Ìì^îÂ¶<dY^•Ì
ØÜ§)ğ@¸’pñü8§~'ûÍŞº¤^¤}#ÙÎA Ø=Vø®^ğM£«ÎpX¤gZÃÿo7¤ßZ[òê¯‘¤–4N>);lg‰ªC¡õtÎÁ7G;ÜŠôbWÕ±Á_I¾ú?ÓË(¸cl•`wŸ²&{ş#0Ø­æùÑˆ=ˆê³Ü?â¡J%:0¨şü·ÊwåÖ§1¾Ù­›¡“OOÈ¿‹ 9¡ ³×À6“®ÀˆÛä'ù“y®«°ÈIÔ¨8˜f+Jti3q@ÍaAáš˜¯‡¡z"˜È*°DG95ÇR¬!Ìß[UˆüÑKV.n"mN‡óÖ¨[§Á9¿PÎ[,ûP°~+¥÷jüBE·HûĞÆ½½zŠ½cÀc<qKûm5ËÍûùéıJÅvÉİ5éù¦'¦	Ñ8p!¬68_j¬ÔİÁU‰Òêµ58YÃ†}}¿Bw2fâ•íäñ=kXşGÛşÃU¬¤ÆaºÉõÇiÃÓ¡gt¼¹ñgóNÖ`ÃÎ«½9Oˆs1etîõÆ>¾õ‚¸HÜz{—@õŸ“T|"°™>m‡ÚAbÜËèì®)<3ú.ìvÃAéÖ¤}¤Lt÷EÎ4Á0qií•Êª‹_\s\	¸ÇÔàv‚s[Á2+ ctùÂg3–·ÕØRØ©wuƒÄœĞ3Ãaú]g¼¢$ùÃÅ(%cß€ŞO¶~k+¤}jç4ŞÌüäâÍ‡”\Öv’Oû®À'xÚÊ6/°]|ö
†êwzÚ9á£‘ly‡JçN@Şº‘¿9(‡ƒi¹TÔÎ™D|c TËÁ ò#Ë\iuÎé›4üëÀ-D‡lÃ»\«9é´£K<¦Ghh«(Æîp{ ê©~xGˆ'Èê‘iµ?S,Pçb;Ÿ_Qµ=;7‚„ <K£š7¡#úhÉ<{ò’´å.ç\Á¡µ”œà‘…Jgå‰CØëÏ+Éß¤ü)îÜÑ‚ÊÊ»ê·£~…X¤rº~amü»–aØà.nÈşÓ‚5÷:ÚŠIëƒ®yV¸0$^eÓ[Ê•œ§ı¡k›~ıZMG„ŒR7rs|1»wDó…Îa¾	Or¢Ux#ßOS—ä“×ßioOìƒóßZ¡SåTÖ§½æ¦SUßˆû'î?-ºso7¸ïçÉŸÖ¬T¬›õë~å5Åş†êãŸÉ Š£‘(½ÛÊ2jÑ×„ìX¸PºK	s*Iíôş•ƒ½°xåA/ÌñÇÑÊEªœà‡¸-©­Ùw¨¯0Ny°Ï}«rÛ3 eÍ5ÉdåÒÊåzõßƒÍ2ÁK§@ÜÍz2ŒfÚï×'›˜Ñ¦ğ¾ˆTõg/@§ÚX–¬];(¯7º5ˆ„‚¾Ï[ Ö™KÛ;`~4v:¶Ø©¥A¤·U„Ê©Ñ×+èm…	Ì
‡S³H¨_rqçq=ònØ<ìU—¾AÇµlÉ²¸Œõ ã¾r€÷mbŞ­’Øîs×%oòiaYyXN#y}Œx3Œ!…¢œó‹òû2uFá¬Ô?–-PhÖ*ºİÎäõ‡¿PCÁ¾^iEdÎÎLVÂÿ{‘Ñ½›m)6£Ì{ê·8ÿ |67x‘8Ÿõp=µ¥ì7™'¬şúÊ´ïÛlŒ¤ÆLZÚÿÂà°T„õµÁğµú¦Nûû?!ÃŸò“áüZ ½ïà{†W1ØÎx×Œä'ºLÂ˜:İ°m¥`á‘åÛÀì÷û(B1jÁ%€lø°1ì7	 3L#q3C'Š:Ô…fisJÎ£êÌÉ’½´$%$AË÷·{Guxµ­Ëm|ÊãÔm=yE‚£°k“û¸şVxïÃš…Üƒæ· ½ËŠµµ^ƒ6ñlñ4˜XÑ°œ'^ ·ıü-Û€³êÔ¬ö„ÉìÂ™¡š(fÒİèÑX•9@MvÇb'Í‹Y™Ë‡wÏ…üÍüŒ½Ü±¿ùx(õ§è
ì¡:“lYß¹g&pè}‰ºJ†‹kOKĞ‡3}):§P|';åò‚ÑWz9ÊôÚ1|bÛt=®\ƒ×¾Ó«>ç^Œ¹…Då ¹¾T* E³‡ÍŞñ´³[ML˜äèÿRßÑ"ìês'ä¾†3ªô™7?óov­ÕÊ¥…Ü´TRC<p¢©gÆÁ7«!şé8ƒƒH_Q¶¤÷LìŸó^€oÔ<Şæ§KáwÍ ’C+Ø:Şˆ 5 Ğ…kÊÕ Åläz¾"a8‡S2ª½ÉsÙjã¤v›r^Ææ»Øz*ë'ÍRy7ó`¼Z­aÜé>WÇ¦‡w¼ñØëíÎ¢#?ÊS¦ê–gZ¾&'[®á¯½Ï¤ù &îú‰NóâKí%Y,q«‚{§1¡Üœì +O©÷%ÆçyÜËgG_ÄÓ|ÙúRì¨f*ì|ìşÿ3^'‘rµ‡>œÁÆ¶Bİ×9VàL‡(Ï<Ø.µyÏ-…¯Á.¼ÎŸ¼‚·íØı¥—w4ü+nS¿¹–.¢eÙ$Äú5N§Ş©AğR8Á^±[p…äOÏdÒ¤ÍBŞ0ÛT‡T æi(DÌÈ÷ ‚p¤Z<fª$'úEş|[§ÿ¢74Ïİ%æQÆg Éfó¼äk,V¨²—‘@¯ù`6Iœ÷ƒò…P:ifšÉgX²¼ ²dúìo—äBéè~Ø/ïŒ2ró->Øf­†H36Öu1L¹nı)°,Lz»- jZr(I•:5ÛÚ	œ7ƒéÔ»1¨ÊNürÓò¢÷éÌe0ÛW¨Ğ«¥ùõšBhsOêØª®‘›å]yæ}@/Ç†9à¬-•şìsNyH„r.áq`OY¸¶6B(¡Àˆ¨a.†Ù †÷¸JM›à[ùÂƒK6†ÑëIqZ^&õÑFm`a#g&¬µABğ *ØÉáK{§, ¢ ¶…ß²†ƒJçO?&¼AíêÒà“œ ûˆ{^¾õßüÁ6’—@Å&À_ó×[ìiúC¯…®¥d	yŒŞ}Ä»_š‰gg9ù-D,Ë¹•S»•Á(XÂ6DÌfòò£a »Ïc.!f`((QĞĞwƒw"+WÀÅ&®³[˜î£Û<ÔïïÌ<^$?6¨#ÉXhUê„Ë:™‘¡&Ë={¾«ÿö©'×:>IoÕÔ(†„Ô×‡„ÓfoB˜8Ó›ª#E±ìÖ=¥İfÆ=,³­P&Ìİ¯íÓs£ÓëÏÿPë…¿Èªƒİìõ…öMİé®ƒ|Xè@0ñze=òhAßqˆ|bƒ=Ïƒ‡Ü¤Ö„1ûÅjĞÏĞ}ÍÑèSñU=w-ZøªPÚÔÊïBcŞjŠ°“£•Uz|ÅWoàşÕRè­Q´?Å°ÅT;CÉa½ù’ƒ{Ã1ã¦…5ñ¾‚"E[uç¥ÓFlmí/˜q!ôÜ={H9ùê86ã$Jğªè'l¨Èå,7;È¯1év©·åˆÈ	ßÒa™#2“ÿ¶1]g‚íÆÖNe›ì„æhèƒ»Ä.±è¢µ&g #Æ¨J =„Z—ÔÜmÓ-lFCó&§õÂkšrkÓµF\Á^ÔèÚç®l½z)½¯µ)«f"ŸÈşq¢W¡ß·y¯Ÿ^øëÄr	İP¾II]€ıQsxå®Ú(ScIdŒ³ZŒ@Á{4Œìüµ)šñ¨~‹eİ\gMê‚KPvu	‘0ö3Š.‚$GO×G[ÚqŞîqzf«ØBÖğÎ@cÁ\Ùi—‘·–ş°.øQlM4û®s›]#šô£~šSù<¨Ï€%qÒ!7Ä™ŒúÍÛøïÑ®ÅjuY<F°x7Ğ­{p‘LÿĞ'Öê%*kl)\#íd<ñbÔ½Ñ8‘æÓñÅñèzç:-vCFFçSÛ8&C-Â>1t!/ö‚Úw’Ôş‹®Ê£ß¡ÍGAÄãÂñA=_|lcîèóFU'vôb!«[ )ôfs¦IĞ«Ï“æ>×½ à1ş€İìMñ} ¾ú{·²4L*oç=k9ñÆ*²wJLqÀnœÑZNEEÀø`"Hˆ µÑÿLÒyÓO‰ÂzôÅ/œEç(‰YLØQqJÖzÁ¢Å/w{zğ}Lt]¸~}ÓbeïôÆ²i5MÎôÔw®"ş{ÿ‚fYd€8okª¨'q¨±Ä(ÔÄ«Éz¦µ‰²K¢şm«u…@]9:Pºè!Ÿ¼Ù)ÀÊ”Şáù¸fà¥@ºøÎëMóÚL€À%­ Xƒ@Ï(İl~2‘×ôH‘ÖY58ÚE"Uû £	ªæg²j$\f_ğ4Z+P@«Ârûõ`e€±¾,˜åŒÖ€QóÇ@ÃäDŠM¥›“Ş×æŠ¨“_üÊ?ÿ"×Uy»%/;ZFúÚB½Á`´D#p7—F®@rÄj“‚ş{Àj¯‘‹%€Ù@{¸Êş­?ì‹l·r‹¸â¯‚æ„MWÂ5F¦¯wÍÂ¦ò*­Ğ?öWÀÂgÂ_Uã¤ûÕ›-rÁ|uÿw‡ÒQe¬Ñİ‰H~«Õñ >«d³ÚÎ™IäÌ¾*×^oÈ*L‚¿KÁdĞÃì	àC¸A1jáÕ‡ÌÌ[!·Å"ÂµaÊ‚Ù†“ŒÆà%ù2á[Fmé„•-³%´AÚw¡üyî;Ü—ç¨’Yì{‰”ÿÀNƒ$.ôzŞ¨‹t)M„;O¢‹îåÕŠ„Ñ‘”ÿ„jD§ÊĞ¡€æ>30¬‹XT®ÃÚµ¥ÓË™R&P*}‰Š:oS3*ª²OH1¾Œ›HÈ—ğ•[ĞƒôŠEÂlú
Œ2Â~¾Åx:!ÒŸë˜~#ï-‘!@,Ê§–<Ğ\»ìvÁ™t8ÒVf¦Ã«´À#H™±4hvz»¡´†¼ÜÁç’hn,A|ÿåìeôCÔÔJîÅ;¿Ã‰¬7£6©Õ½Ñ­'2¡V¾Æ¢bBŞÇ‘^Õèå¢xÌşä~-ÆÍ5©İË°û˜hµ¯«‹û£ÌG¸×ïR¬¾íb73£aU˜ÍuÖz˜6ÖmİÛa}ÀÀDfºÅÓ†±ùJ¹^½™” Û˜±›ÔâÎÄ}
a@ùâé5á$çÅ_h‚~ğ‚y²Îx^Ñ]U”_¦’rëÖá­’ãiNiÁuÿ—]•1ZêÒéLÉê5.`{ÆìÆ
l‰B<sõòMA)¤/j  dúz@ºde´oÖkÀñâT‹ Ù¢n!Îz–®€w4Ö)¦tÂßÌûRåJúÛÀqñX>ÙÜQ/U¤DTS¹w¦’½ÅÚ†v|p$"…Ğí˜°ó2üéiÿò…§«¦ºQqAXõMOâñ‚	€&T*a¸É­ bû…$A0§“bÒşK˜ FóÚ'EµuA†¯€%8 ¤›gï ÙZ¤Ì0¶—ŠšòaÍ5L«Ï[İmª BC€Q3>å˜F‹®_3} ›—´]ı©Rt\‡¸u “¡çå`eÃÃJ%\–Bm;pÉ{,,ÌtWH)ÌÂ¢Õ¼tôñpí&øDq´áN‡G¹>ä`|Â:şî>Õù‘ÊaëVB%“ˆ¸û‚Á™ÄK˜±´üîË¯¡–ı áÈÀà›ƒÜıÂGÜÏ… 0úl-ÀŸ4LcªFÊ±¡¿*Ú6_)#nY¢rT‰èaâXpëÃkÁ å'šÄ}Ş>/=Ä‘Øq„ì±hã•şAXÑÜ‹û8ğ›#òv¸k‰#böŒKS2@NE<0êê½D%õÄñİ%°ıiJ¼õkõáM¯£ûRÂrç~¡NuÅÑtùn
¿õÕègşÎcÉTÜ¢ºáJiL½¶çhÿ_Ë¨(ñ5˜¸Ú³ïç]^éá´o °,%,¤³j°Ä.øÂO-<Â“áøÆ ‹2ËoÒÜóÒËà¶(±‡o‰'CJÉtê“28ö"¥´vµQÚmàlÂâ4@´‹MùúÑ8ƒ Q<÷æ¢‹–Y­Œ_²õ„€ÿñX¸ºÂ)Ú´(†Eİ	QõçhÇ'Ä¥²Në.5IÅ&L}â¿â§u
=Î–mcıc º—Æs›8^]<ºbqO€DHD¼\„@¥ e½ÈÂL×ª¨]¹ò¬Dæá¿e
r
×º^e[¸Y_Î¸ |bªBlcñoÄŒ.Üm³@}»Ô_=$å÷ú·€ğ,ëÓD÷@gì`J‡@…nØ°SI„ı¾÷(_€Ş“¨¨ZI&ëHl#æxK}C—…¦¡Òxüñ èÈCGÍ\—–ÁÛÇ”V£-¤6ûÊìËA­ãqãıÈÆßB¼gõáVSôÇƒ;?m˜&Fˆ‚<É¸ô>¾k
$©Ö
 »'¢’š“V‡™¸axYÙ¤¬úıöHOdAĞ,²=ØDÂÈï€yP‚Ç‹>{‹VZÜÁÓæê)é³ÎÖ BÂR
ÈÃjÇâ¢Ò|²êÈ`SGÓTKqx	'HÎ‹F¬=¶8G³µ³¥z”ï?ÕA 0¹¦‚tC;Á¿cïF”ğ¤è%Dáåtöçö T´öp±9ÜP[ˆeùï&ñŸŠæJm ¥­üâ_ Z[<&3D/­F?)&ÙÕOÅ˜	ei#T™r@³-FSÊ‹ÇòuK9×íİØK^}¹ÉoÒÅö«¹NSå(ò+x¸Ú·-ïMv‡ÇZbî¯ö›•İqæ9g§æóÓÉí=fcĞ;»Šj„HWœ ·E>p	»ÎÊu.é;|Vrù: +ãL#ÎHùÒ8›CGfûØ,ÚäõoÈI;3é£€7²:;RüâÚ{\ĞòæÜ
h!ºÄcø›`nz­A‘‘ÉánYí4‹jã[ùIâáƒí)t[Íhvã½²¨sÿW¼Øz³­aO1õ™2ÖıYá„-M—32ê$LKEÆŒöQéïoŠ¡Ã³¾<‚f ÌtğR´šgŠÅ=7Ì±«ıçı²	M‹¾AqÍ-Bğ,úaÎ¶MémÚ(nW¯é¾¦{ÊóZÎr»eÅš9î ¹·˜Ìs%ˆÑ7F©€‘—_”ÚO0Ô’µ*SşL¢†Ç^ík°¬M	÷ø6Š´auMƒçK³ç‚KKáàs&é®šEš‹„ú(^©ßG şØßm¾Sœzd§Üõï–KÆZD!¶²`Œ'çK*m^kÆòßÑ+tÌ—3È¢hÅà³Õ-™öz¢è„0¦ÂĞ-pıò˜ƒI™tCH+kÅfí8—O-  •.î»¢B ‹âì<}|× pğ.~¾Ì
¼3N¦èL+ñ9On±H®f9Ø†¶3³Ù?+ñÃ†?L¥5Ú„U“CY¬³3½}‰\2¢µŸoÊVáëS>Éq·q>¨p¸İ™Eù“™fâ™ÌÏ8áí@=ï“ª€éÊßÛ#Ç³_Û±ÔàQôm¡Lt´™…¢µÃˆºêj7øT‰Du£”Ø&Nğî
{øúô^»WÓuÁ¹Q5¿Œò¦N0ûLŸ óŞÑí˜5
t´ï1fd¡á±„èÆ"s$Ÿs$c
xÁU¿®ş•‘h6Ì*â- œP.€Zg¡oñOtËÇ«ğÑÖ!Æp¬}Š˜Ú‹¹ÂÈ(õ›á*G§œZë›€¸Geq=ËíöòVô_/X/5[ú® V–±[zSAÉ×ŸŞ×ßvÈ^)yw-êPvì@‚\€îû $Yc€!ˆæÌí <2ÀK#¿ÿY}À´‹kâ²$÷b;cI
pu´…CšÈ™ĞÇp´êMòö7Ô¼24g.ømÁéESÓÌ£6í,bô3V‡
 ¹/ãÈ*ó¥\¶Ş5ƒğ/Ãå…Ñ¼È‘K~®]¡%¹ë¹^ì-\ªõ</¹0á½w0é šû“¯rf9G|4Ïw¥G‡mIÂ#¢ğ
¢7 r¬Ü"¿Ù¿…UB>L¡›õû|ìĞ²y‘I5È¯ª¢d‘¨•Ù2¤œœo~š[İÄÅí	ë/‡\\ñµ‹ÎÖ†×s‘Sáêl”¨ŞFü×¤P‰–;±§ˆëe}¶Î8êÅ÷†’<.Ë­€O~b`İCHğ¸P„X\ÑèÊo/OI¢`ÚUƒ®ÃÑƒ™2d’eíkT©/òÂ“’EÿoÌ°){ØíË´çêì~ŒZe ¢ì:²ş=Xa´OÂ­y€%{9%µ¨(Ÿ›LæG°fyÜlsÂ¢×Üò˜LM«¥zŠ»ÙœDt¨¥,7/¹”OÕLÔ†¸¢MÇ[ör™“ûCÅyhı<Ïß'ÕaüUS@µŠü)ğBKnk"Ğ]28-¤ôäpÕ¼<ƒŒ`…|=ÜÂ2Ô$Ãd}C©D¢…W@êPOO?ÉlÊƒ -ÙkêÇşœBTÌÇÊä¿Ê`OÁÎh ßix aÀt®\¹
Dî«ç_d]]\˜£Ã[$'œç|òMöTD=:9i3é9ãğsÒÙn•¥G¦y<ª¨0Çæ5Ìm°B?–±†âRp1’Îìu…µĞB k1ûH!0_6¥<¯o×@*†?Y“S'®ÎËOA?dµñÓ7ëáJk¥kp ßGÌWùL “èAªób‰­9Óôı‚…ã×^Ä®²È‚Á.‚ç¶ù,"ŠóÓ6e¿¨İTÆ"oÓruvfQsß˜¬~œaÀùßêÄrg<Õ–İï¼AØ[Ü%{‹ cŞd1ë‚ŸÃ¢nŸ“®G¤ tÅ”¹¤C­
÷–¯,Ï–v=ŞıU¼ğ);ßØFùı•fÑB $&HœNØu¢¤OÊÊÃ¡óx‘ÀM•YõÒ‰uğ•òâĞŒ"n˜Ä¾…Ê˜¼È<»šXï#«X2}U…ÆÉFÃ¨ö¤ğ‹P=¥#i…%¨ WÀ|Óë3¤Íi $Xë±WûÛ¢I!'ûşYX«S.¢=j‡zZÈ+Å	+NJ
i“"gznµ(5cW¸ôå÷'Î—”÷Íe6V5W1oSÕ¾¦ot‹`¥—GÖEğ8ö—¬&ÿ
´J!¤)°ÿ(µ7æ…¶«@ÅÖ`Æ42ÔeõBNÑÕ¢‚Ò{µ‘Aæ?Ûöğ†qÏvûoëvtj)¨]7ôYàóv©)FkØ9Fó6…d¿|ù)eL¬=Ü@wõZ s±Ôl,öGšî@s«V£¥Ù‡¶ûáÄy™ŠQd4÷QäeÊÏŸã‡ÍM9APm±Àl‰µ €%BA—Ë»pĞ¢Â†—íó—OÎö=/*$…ÇE	I1JÇ²uÖh”(Úq5Îöœë/Ÿ˜‹­[ÇûGq dUœLÕkÿ¼•ÅÃÇ“_ItÅ°sõµ•¢	îg}°¡I•›¿ºX“Ç0ò"8dt´JÄåğ¦àn´ŞD(awÉÏ:•œ'a¸CİƒPƒ–j¨±+7c$÷&Ïù\¢Jù1*öT“çsĞS¯G
VãMeYN¡¯‰"Ót*y²Êª†¬_4j?,e‡gó¯*©Ø!Àä9Z¿kdÅŒl*«ÁO¨©˜3å¤ÒÍ!úÿ=OL á6¤ƒuxv‚ªx‡_ù£êV|üñ\_@I:Ã4-¶* #Z¢å3;•	Û?5 årİª	ÈÜ±·rvM»Ùánb—R¹ô(ñ-Şî¦=K…)†ˆ-ªCm•7(4KÊğyŞ÷Îlû´Å)ö ?ˆLt¿„¡3b³¸Â:<5
¹#Fñ"4¾Q{vHÁ¨1}şhùŠ1Ù‰Thsjã@çÖÙ•‡^/ÍÔ]&9ëß"šbR‡–Jî­ÅÉú…NM­mêÊmÈºIêÏE˜4i	üWï>&¹=—ı\„ÅJ+øZj(²Yª»*½Ó|0>‡©3-Éä"¹Ô$jÌÌì—ô‹ÇyA‘Ú‚	Îö-E“OA–fNÅt1†N'$D¬Æ	‡…HV‚•ˆ€Øı\ˆg´ù$ŠY²¡ªjG£@~’ÒO?ìãR­àVíp ®~º©~Æf0&.š}øqêo?š)ùq¶2\f4,çTÙgf6ÏÛ/s3œ~ıÉaå=°Z¶O w1ÚCd;™9‚Wq!ánh¥İğßècˆ0Ï³@2øñú1[%ò’ì1×6’e|×OÍAD\S”ZŠr¡v±™r€@ƒ]™ºõ•ÏO5°‡ñ†õ7	‹z?„iH€B/æ"ZC»O¹QàøV/Å9¾b¢ªÀ
Êïb[õ‡L uîœ[â~Ï1¦×T¼ğx4ÀŞ"!Xå{må-(ßKbÙ(÷°Š½æk
MpşßyeYYŸ+‡„¼ ×TnÑÚõeßµ¨É"ïBë¦·aŞnÚĞ²‚ùÒc8µTq3æ‹>@õ^êq;HœáÃüşÔx‘#ª@¢ƒÖ6ÈdËğ½=	ï=6Ş|nhÒØp¿g¡U™+öõØÛœæÀ:Ñ‹²´:ŞØê_`‹RÛí¿Q#½Gø9ĞÆ‘q”îÊíÿËŞ„ôÙŒç—·MÒ¦“ÍF6ş[g@‰ø ’wŠ
„ïq°…Ày	Okgİ¦lúÄïÛ8fµj¹@nõ y$âİ[‰iÇíÔåÀS){Ï æ9mÈ(Øa¢2Â+:v‚^Ò3\Ã„‰ézRŠü9CI?ÌÙiVî9'tÇÊ’àÕ˜á']¦?;ñ²›¯qsb/–
Ù¥`
/`í#ê@.øŠuF°ï‘pƒvÄµu0éÛ¼sË¨›jçÑÑFûß’–,2¿ïV[6&dIÍ@ÎöKpğí	5¹Vwwá¢ñ¬(,ØfÁpá$Ğô18¤ˆÁ€•Çò<Ä0«'—ß%[ÿ³Éõ?Ä’Ğ+• S›ß@6xü±Xvz&ÊàNä¢ŒN 7è"~FÑˆî„N‚ón½D76Î»ßÃ9½Ä…¢Äğp2Æ'ƒCˆ1zŠÿ³ÍÕ~Y.Ğ~º%B*ıaI“jÓ!sC²å¡HÁ0¬Ugß¿Sô€îJÅ!?—	k¬f§!|æuak¢ÿ¨)»¦8/¿@dÂ‰„1TkV€Ç.[ÁâF\¿rÂ>7ëŠ¸Ÿñb”ºı#)nÊcØäS]=¦üÚÈ§9Á¢ßrÜÙÅ²b—;tãÑH÷Áòë1rwgİ’-$wÅZeˆZoüév{P•QrÌ|ÁÕ0¯–‘G'+†KNö¢(ÅHÅTRÄäDLpPğuD~6¯€{PørÖÄñQFÎ\´ş1´L¤M¹ş¨»!/;qOÜÂbW¯«g
òTbƒXI4£îolÿ”õ¹µ$a¼÷È'Z·Üš•O‚/Yn@~F>ÊBr=÷ĞËæ¢ã:c,2Á·n5L™+Á³5rì0·+¼Ê:=çB«ªÌ[oæêmŒEGl—ƒ‚}ê	£aâì8Ó.b(7lª:ÚR®Ñ¿™ÈåÕg_C\ö@p¿VÑ@§GºzÑæçfMÑD·Òâ9í»nTÅ•A*	’åûŠºé“º"µüŠÙeK’
Ó+/­ìòLÈ¼ã48‚zaë_à´\Û^<  0¢$H'rçmÚ[LkªÉX2èO/>§™èƒTÊšWF»$'.×½ÒTˆˆ
H‰õÊ@ªr°RÊ)”{›~S¹†¸’¼+–ñwßºB\ş+c
şgn@ög¼ûé¥gÁ/\»nmÕ‰¹øeôƒ”*ÄVó½£Ê¦=J÷ÛºÔf£‹]×§=Iy§ŞmšçQ’ñ$ıO:Ú±Ñb¯µ ì\T?NÅGSdó%LrWQ–”ªò=‚ÂAŠ‹MMG°©Ï›êÊi½ÿÀJ	&äNµF.×W¢Ş¦GöĞÃp6Ç`f’½p¤wE‡$~$G‹©¶áƒáHä*;#Æ|®3TÆã¦ì(sÓtÅ‘ií‘1GO>ğèµH{.Ar±•šËî 	Ü>Ç<QÂ;Ió$ 0›ì’uSìäuOo¡­…¡Uf+Tø2—zEf‘‚÷öõ…Ò¦Â “´Oµ8°±!Mfp–”X½ğPÄÉƒı3ùá«£„NP‰4ñ E1òËÏ©Ü£ÓÔÁ8)ÎêZóÂ«7bUğ<|¯ë§4{…X*çStœÒ£füÑIØAVTdÎÃJhè0çã‡d¿ÁTXöbFı¾VJÂuGqy‚#£™ÑŠştf*œ¹³åbıÛ²héxÅ÷"ßó˜ğà“	şWÕzöÖl	Èá7™q¯@csĞŞV/².ªÀLˆg¸1ÍIŒùåi„ÛÅí$¹CCüQÛ¬èÁ¾M=cNîövŞ?¸óŞæPóI¡nö™´?7Ï¨Ááø¥ìJEpúD=j „œ.TĞO7J†çã –0ó=ºÜ]‹rÑÑĞè0¯’ÒšßéÃ ÊŒ±Ñ$ô Ü(•p&9ÉéF¸°a¾›/’}œæH xb·ıô „¾sn¶Wİˆ&AtVøÖ|¡Ô­¯c+ÈÄWvZJ0ÄÖŞN9™É^–áPz-sÌ3Rë†}ôs ˆdyAÆìï‹Ö©á<OÑTŞ¦.K‹ü/?ÅXeıU¼šÄf^z43àĞËS¸d¬…JFekô†Ïhî¹€=éå¢ÂôÉšãö6˜rŠ™«;?¨óûjÂ_•ÉR(„N×Ò+ŒçØ¿(Cî"J¹N®±eÑÕßhEJèúşhc5‡ã ğÆ¡l“dh=ú×K%ĞÀ¦G¼¥ş®RFzıiÑ„a#'Ù²S´å
‘R<'ÀÀ½[“Í
rÒiéÃvMdï£¬¸=¡H~ª£Ñlºg¢e&Ïî”í;".~ü~ôL•ä¢ªh‘ o@xŒö©tïÂp—Õ~u¾ºeGaGÂ‡Í!ü…nª-ÛÕ@VH¥Xsê
ØIïËE,eŠŸ¹8%àsUÊŸœyWèQ¥-yÓcxÒ²…2¹xeÑ“mè[äµßV—oX.½ı^*zÕR»ñlÈÓ{£{|¶Ğë
£§ñÔfİxzÓî¾A~3¾™QÄq0~?ùÅH86Ş)>kºÓ
HøÁ¶.³e Îú§dş^·6ê6ZA©[.3N­16&t+–6©-e’·$ä™,³v,Ô)>N@HÎÂõÊª°`,-ß¨»¬YñMÇ	=„wE.YLx$¨4›bGj¶Ø%¬Y Óç’Zİ& ‹×)¿æ[O„cµUÕ±O“sWÏÉÍš«pÖŠ=ã³ÉÈß:`í¢Ízß4Hˆ<µç¤¹†Ò½şŞíÏÈØá½½¸ƒDF‰“iíQl›ärD4Œunñ¡æ‘.øLíPó41zN0;¥û¸Á&Ù j/Í$\¥ÍÔ\¨×P_xáØ°qÉ²„(ÛÎ%ˆ·r³¤½4î1üº–08CBà
¢Ÿgê
slŠíf29©n¢_A”÷ú·¾2ÊrJœË;¸ ?ˆPI\©Şvot3=d‡åÁÀ=§“ºBÙ?²‰çÅû’X:´’5à)À† ºN4ˆŒâï'é‚`S†´÷?§+€&ˆí$'»nù•¥?Äññÿ¥nÁ245ø°ğ´_ğÕ.ÉÜ–óĞôuˆ@¹UğfQ€E(9%©fBµleÑ9Á…ßP=Íİ¹Ôqµ±µù£¼cG'©–I¯!‡‰ıdóÿ8ße]º˜PÙØÕÏÊm ®¶s–ĞçSñÇ¼«Şª¿÷UPjt0„
œšå&YÃ=/Êöá<æ[£Ü#1¬oph×´Ş3®Z!{=…à­jªß®Í© ßyíøô´uƒH²ÕƒmPó7Ìhç‚vq6‡bm›3¬7!Rç!Eª2$¨sñô09Èä}¬‰m¹ ¦gdÅf—T¬Ìt$Ü.»ö)*©`óşS°÷pÃ =Òjş‹ã•­]e;—5Ì(ÁÌ80ë¹•v¬\Û³§ÊAû%Â'}5\;Şõ:Ò/-!p¬³"à·ë¢&@g{t|İSBĞBô$Bw;¯­r®³&â€\áòj¡ÔæÃ¾“&£ )ü„UDŞ"ĞrÛ!‹ô|¯/} ©%EDCšÔ:I3~u È‰yŞL{¯¨[J{Ú6oÛÄÂ(üó1&
‚ùô…šËÌêmË£êë»½ø¸¸ØØŠ˜™ªÎeİ¯uK\)šõšPÉ„/&„ó0Z:²©ôEøùš-I-˜k
ç)"Csİ¡¼³S‡ôá'….>úÿ–˜ÏOö şLú9¸ó'í-º‰Oê;k_¶´Êx^Æ	ç^Şo‚F—]h;é°ÿ`«¾ùÌûâàö}Éïé¼’Dz{Èƒş
5ôş.îÏ}Ë1†¹¨Ú2ğ´›B'ZHõ$«*áTwñX_CúºgÎäÿwáó?‰Ê¨²ğ(<K5˜,cî\Û¸Õxàà™ì‹gÃ8±ñJÀ>qCãâà®äô‹YaHğ¼“ßÔ*<“í…§.€çpEeØÍ!@0­<—B]*†[0ç°A¬ÀvˆtKh­VPw›\>Ë©›×ú{´Ò´øQ¤«èˆôäşÖ­£Á&3íÂåHF¦dAksÜÔš	ÿ”RLÔöÜåñéß0¡bfi¿ ƒu=×Ãë!x?+Gö‘r”a>¹1+¬lË†¬:u¶’©k®¤nÑ}*ïØÚJ`=º—ÆÏ¼j³31DÅ‘Elé¡ì—&ÓG&eké´#:XàŞ%ßsi5P\™“ˆ‰¤!UƒÎõ|¯Z±Ãı*§v§ÜMiÑŒ½O`ì è6[ËöDµ/Å~¹}­'ÜåÊ`"Ò¶.z“0<ıñôA&†Vá|¬L¬ÀP
z¼HÃB”`•ç»,Ï¿Ò,UÓß¢=úNp™§€÷˜ëİ¦¶«Ô©Åö4q7Ò–«èàô+‘%8¾{ùŞõÇ®O3É“g0UŸ™>@‚î|C@"
£Z§‡ÉW»ø¹´ŠB	ÛX]jÙlM
åpúÈóHĞxw9ûïµïÅÕÏÿùw ggh”|Ãéù~2ş3äÉ.4Õi_{zLªsz³÷8Ã×q#[øN¶ÀÉ·ÅÙ;¼štùŒ'&Å³ÂŠ¡Íê_ñ‹„ñu¹N¦Ï¿÷^Pš–,,xË>Íâ42ßøE+-)6
Í#?‘_w‹Š¢ä óöD„ÃgŒÕœK6wıç,ü¨ZÍx>ƒU
Û¬€Í–7bH¤eh;šÕ•TNÍuE ëõŠ}Vwœ,QÄÅßÇÃÄó}É«è§Ë•¦òhµ¯eÓÛÎ9ßXÌâú¾W6½0'ÑrºhY”ÚKÍZ1=fP+ÿŠŸ‰6çMã#¯Ay}Ïh!pP‘âQ—ÏÃ-‚ğ?‘Iz¡üv¢t›¨qNIUíäƒ›Üˆt3£›Œ7›íä“şp×a9Ñ½„¯oh#gÌ2ß÷Šb†Y^»ãj]&5\Ÿ£†lÿ£ßE:–uØ@ÉÒµ{Õƒ46‡²Ñ©ô¢¸2ëGpà Z•»(l©UÙ]Ş˜®ü²ß¶Jî·ì[›Á}æŞİ‡ôá*´ZĞš®<löA7i1Ê{:yËš´”V-ª“3ĞU®¾†£^şıß\x‘å¡×û¦û³ÓôÖ«ÚÈ ÑÄÛSx:Àæø¼FGè_5Ê}ŞÛŠ^5àñIöæô úLZ'¸Ñ™Èj%:	Ğgv‰¶`YÖI~NìRÜŸ¯X› Üüü¬Ï·Bİ&äã·›—_GMÍ5?CQ¦˜S›Î2dz¬}¨ÌÔ¨J	Æ>r¬ ×Ê}ªAX@rlÙÜ!gÁ??Tüj/t+¼é,ÅvÄeÇ+ã9¿Á.èÅÖ¥Æ¬CLr:¦ˆ¾”Áœ•~¬m'Œ¹öx[ÓnÅÍé½u¿å„ ^õ.:FIÄ6ø³ßˆ}Ì]rŸ5ªŒîˆÕX±lQ)/Üß•ƒåŞä8	YçŒTÅùµ·¿Â1º˜´µE<*öÀu¥ŞIäÑsZÄ4Buh=£¬OŠŸ•´!9ójŠ-á¥04]ë'jGTµ“ëeo”ÒÜêdHê+°f3Iêú;«5Rj*©P}E‚a´:×¿KñN%»—} ¿Áş‚cœıdXæ÷êÁf”;èì¿ğ¨ÇU¯oßYÅTí)nl¦>÷ ¡Œgõjƒ]:VX…3s#“T£™0È¨oÔê·€i[†!Hu“AHæ9v²¥õ¦]#6ÆúîªšĞ‰?^ZR`–'yåî÷Í‰ Ûël%©ë¢c½Ó*kòßOæ¥ÕÃ"Í´qêå›[Méò×0|âs©ê1Õ|6_	6'Ò\.–ïœ¥â,Z@6\$çÅ•òüü*9ìõáÃx /Z¼ùŞ[ìOÕâ+Æqn;g× Ş¶¸!^çR}²Ä–€ôİ›˜ÕÄ °#*L´º>ôB¶šÑ©ğ&#ê¬BóO†×ÑLÕö\2hpÙ…4eúnº¥{C¡¨¸ŠÉ`Ìx\°ŞNVÄMw·¢VKi£*Ì!N^M[Ë•¯p^;D[ÆTáoĞ«©M±LHÑ–6ĞP­Aö/ÎÛ]´Ièf'Ğü	¯Hç[´.È&?|£².k@N„Èno,T(Wµ%Ô?L¾DçÊ tsì|u÷ ä)»V~Dö¹ç…}+ †';l§Ù?4¬ŸĞTš‡à±†¼yw)}.ù†Û*˜B¬Û…uÁ>úŒè²úëß˜´®
²ÛëB€4¸áô6¥Ówxz}ÿ™OZ¤İ‰„úŒâ¶ò¿o²«DM;¨	~‹.²Hšh‘ï‘U¶WùC³BøÆå­µ,d¬‡oèÌ×àŒLäàÜÊİoÑëí‚`É¾)`ªb“^üfêv‚¡†¢˜1õÄXŸ[”@n·ës[y©„»@#yÃÑüeqq$ºñ-™%ÀBù¶Úò&Rdá‹[ ¹ÂzuZ#ö,¶aÈÌöG˜K+äM…Ç¿ä3şç*U™«ûæ'
lP%Ìèš)oep.º&A™41+=vÑÄ)I£ááçT
2`+š€­o¢…ûÑ+Û‘zfâŒÃ$Ê>‹¿Ñ`ğÃ´0Ç»tØÁxfvL³}ò‘´	İ#UÒóA†ú>®¦Ÿe©çêşà¥÷Õ
ÌÃŸĞ»ŞNXğÍ<˜í}æäÕúœÕWAD €èÄ¨3¬mÜª¥UãêvÜ¤Ni‹Fû½
UŞãàì^ş H­ä74Z‰ÈŠ#ğé¡Ó¼ƒqÁô6ü(Møë2áİÃHò†
¤iKíÇG„ Ï5å2q›Ş±VœÀêXâKŞxU‰rïƒüF¹îb™ïº~•V3J…B› jñ˜—§dªğAÈî‚lp;ò{‚B•Æ*u*ÂªáÑzÃ4-]ÿÌûp$ššA,Æs3í/ä%¿Õ3[n¨RÛí~µ°]†š8IùhuBš(©7êÂ¯^cî•Ÿ@šÔÂr[;¾Ûk…pjH·ŠrJrƒB{S«Ëóc•|!:i4¦I÷òˆ4ûi 3ª;³æÙ|à.ĞGğˆ‰YÁŒ ÛµU™ÊÁ;#'³B;šB¿`ñÚ”gÌ…qW(ŒıÄÊ¦IĞG{} ò´ûœûC¤s˜ó¸MBlÕ{nÔ“g²ÎûË‡—ˆ€¢à¬°ˆ[ÊÀBİÂÛ™3óÕ}á*kâvÒÈÉWÅµdÿ€3ÿZ:E1"@x}ÿ}bf=™ )¼h`à¥TR	e¦*EÄÂF*™~§yRø#œ_í1r]œ¨70d¬Bõª?Ú®(˜ˆîRx4b¸XéñÁîüãXkhâ£ÇD±ğöƒMèöc|G¯”6–Ï‰§<>!º'œ…W¬Ío™ÊUAH"DÍcœ
ñ‹>ä•^J†6RüB—!Êl¦í	I´“2ï»ñ•}Ìdìr#ª_#™ù¢€…şe¿Z¶«ma² É~¦õİ«­Hcš™ùé¢HGc[nÒÇ322b”úîëÊ1-•Ã_<&ŠÃ.ç{¯{ü¥ı_´¿IB÷ÚW è˜Šµwùk.`6ÿÿÊ±´ü{µŞß?ÁK,iƒÔQ_Û²œ­äœFØÒÿ]êW»¿­C|¥Í6ÏiÅÂÁÑ—Jº!~!JJÅ JçëèöØ8æŸŠ#i•Kºô
ÿvï:d±‚õ9•à=ròÒŠèO¨@îÃïpƒš1 õ]ÿ§¦!nïŸNy¼ú“ÓkNÍÌJ3e«ÙÈ¼V½PÒ>RƒyÍÑ¡SšŸ‡ºÖ½›lÊæ¾ƒøŠ3±åQgwñ¢âò*`XîšëHW¢¨ıÎôÈ‹<mI‚ÃW6H1»Ê<Ñ‘W*gşUX—ëk3ÀÒˆ>:©¡á=Uœ7’Œ§y¾åvÉèKöe@@lVşz†9Ï›§—Ò}×ß‡8Æi!¸ÉW
ªeò@mK71&r=ıCÖúÇ1óš¶×s:€ƒùx$Ïh[5óÛ´wLüïd\Ï«¶£Zl#IC–?XûFÇ|‚·ÿz”Päc“±ÂNâ}â´ÄçGÅW"½6§¢¹%ß¼ƒŒH:„Ñ2ó²À*q—Jÿ8a‹°ØZi€8œ e}Àìj<¼Ã˜u¥9´[ÃŒ ‡'r 4œIpGÁ<àÔ•s†%ÕPv&™ˆ<óéš „}Ë‡FpÖóÖl†ÇK'óJA‘Áa^Ãõµ¦[mNo¥8u'Îì”ŸI,®Uù(¨ë	ƒ¦¤/½=â0fĞFGsåóğceøµÚúØsøgÉ¡†G›Û„gBLªÊœ­1†Ş›RõÄIö’ßwÙÁÅ¾K¡zøÑ6Šñ]×ãĞÓË/ÇÃ\²ğuY¢¹‘@œMGö|
a+_ÜôÛw)±!´+P3œ¤!h4æo/á–ñœ-‰à)?{ª,ù0rÔ^)>Ş^¤Úsn¹üudÙ‘©‹g*¿eJ¦ÂÖË İä‘7Ä	'dj"ZæÂ1™òĞ¥Ü*åÜ›jï>Z2¯|Î»{¥?.—ÙQ{‰U4åƒNG³ö¬QFÕ†}÷ ˜$ğcwwÒù>2`.qµ=Íş5»<.V\ukgÛ™ôİğ‡}W1Lºí°\Ì¨	B01K[Fj•ÜŒ#PVù<^©´CzP°Áé”‚^ĞÄª›r¹ OİÜf&B_Uuù°Ğ\÷´wbJ;ÈozÑ¨«™ó:^ÆÏÇÀ8…lŞñÚ+øO†µö¡::YÛ7TÖ¹u‰79o»l!ã)„ÀÇûÌN©9¤céäìïW<‡tîbmEuâ³Äq}Y=ª6“Ç¼çœ¶¹<Œù¶F&KQ`/˜6ì†ıfQh¯âŠ:JÓ{
çî–"£0İ	vI¢³ûã‚í±Èe([¯Gç<Ò“O,ÚÍl¨â6q…:pÁaÇ³à®Ñ@læü¬¢£ÒÜmÏ	-›¾oÏÍÂø°­ÆŞ~}QäïsÉu]Q$µ8ËW±v½MÔ’O -«$Ô «nİßtïvíšp<xê""k(ã?gH&Ê"‰Ÿz½pÈ•å—Ş‚—âCÚŞØo¯ŠÖXÙùôÍûK<ç™OØË`´Õrı>š–òÈ-b ƒƒî7p‚½÷û¥y—‹Ğş™ø6ÉÎ%áÅ°ÔÇ7^W6´÷ƒÛ€'êÁ*·M‹'Ê&]?§„B¿Ïï·‚5 ^‹9ê£MªûÕYÅ\WJSÖëßÇ:c—tÑ5–ÿĞ~)a’cq±ª)`\©/¢Û›~â1îòª½Î4èÑáñ4á‰±î(ó0ø7FŸñP>­¶ê‘ÄK»ÄÕØ‰Ÿ]Œ¨DÕ’æ54ÚÌŠÛÒXNï–VÒ+Ë_X¹¦^»ÜZ7Q $ÕqZŒ;3`f¦ÊmGSÍ˜ òË¾)½Õêr”öbäÜíÖäŠ;ù´¢r™õáŸÙÀX©Ğ¦*øp;3S8J÷Xu¼ºû*’ê¢Ê
sEšeâ@Æx…Š–™
œaÈ®¾w“¤bÿœİl.Ç¸qÇÁr¼ÂöF,¶5ÎÛ¶Ob&‰ıºmsÕjçıkU8­|”õ6>±«)dÀX™£ÆÃBíÖZiî·+fÿÜÄQIósO@8I’¤·èâ#6º&Ëò—g’2YüLz¸ƒg~­\hàDaV£ª’
:PVóIŠQQ®éR€ôøJ‹@Şê—Pun¤ñ€+iÿ—»(¬³"ÃÃçVrœßØÖe*„gº	5*,Òæ\DüÓ*Ã>Åºÿ\uT½¿D˜Ü#0ï—Kº¥…qEZ¦é¾iº.œN*X‚nîxÂ9ö5,¶šÚö,”Màóä›Û¹;…:P»Ãø­úĞYooK¾}]„X3ñŒMe)°D±x“nö×õ¦ºµ‚ûêT|¬ĞhóÇ’`êiR¦¨ş®-"Xkaq_#AÄ£$âd"Şİkëğˆè*H‘
M°åæİnn3”Es„Gî±¯­$ï¡ZfF!.IáAş
3H¿~Ë(‹An2ÿÒ2X^!ßÒå{}·ÛDü<(G=òA,‚ZCí»¤=UüòÕšæ€‡urß÷Z‘5,D¦NEÌÎ~™çÍ­m(¤—ë€óùÑ<À@ô{6VrÁ®×œ@WÿìhXŸ}¬ÊJù¹Úô‡uUÚpGşjDÒ¨Üº“šV›«Ãk5Su|á?Gk+$ÃŠµImZ2İXwûæçj3£y¿ê&ñ=çË“¾"hë„¬(WjcÜjRôtnªîŠËfÜ¨urùuZc³Á…ÃZúßÉä0z1Õp‡E¯8"äcÙÒ£cA²C`Q…“ÖÀ8Øe^ª˜”Ç%B¿¬cKEXàô­
_ºÇ%¦ÖlñÖnÁ)RÎ2 ·d-ü.8Ã²±B1=½ ±¨Ô‚ÊpşØƒHF¥6 ‹dÚÛ›§Kúí`Âÿ}ncÃÛ@¶6wg}˜I¯Ô¼}Ğ‚Õ«Í†óÉ|oZÛx°P„¼²kqn¯şşkåÂİrågºP“€Â„Ál?
‰
buê¼ç› rG„ØHÌ¢Q„+#!Z­İ~GkÇóå¯àî>õ²ÄHğ‡C4´ş:Ö¥™Â“r98Œ‚|¿Î1ØÔ{×ª
öéD Æ:7#†šà~¸ë¿©Æ|¹=™ZQÎUòXHú‘¯ïı‚ÕCùÙ¸Â>¤£DY‰cg®™±É4¡/Hœ»p9Ñk¨1yäAæ2¥¯G”@õOı&¯”»—ré(#Ÿ”Š²oGÌˆM¯7µˆY¶†|ïò‡Iyºi%Û8âMlô?©îA·w rÿ±"¦”oîˆi^ÎÏ°ø›º{ü‚)9ï¬P¥‚,ÜÜ—JTIÕÚÄ*‡İïĞj9k>ĞúZšGMˆRj+ï½c‹±²Ç‰WEw¼€¹]2Q™©È Äs¿ù[Ğª¸M]Ø¬üAKÅå»¬æNÃ?…Aß±d9(¬²ˆ-@ü£l:T†8Õ€Õ–÷AÁÆÌ¯çY'°!'Û†P®ş£ÑğoĞ·‡C@+•(%â8u¹UÏáè¢šhe³ÆÓªú"ÍR\ +Éöxœ	 ¸lŠS	3©7r1ÿø7¡
U¿²Û]RwD>/–Ê®éâ{ĞÎìõ»Í©$ø½y˜”ÔùòÇù¥¸Q°ºéG¡û¨ágQ‘‘Õğ	´ñbz^XRm]™i¯¼N/›:2Á[oŒøxá¼ğ˜èº§¡ŞÉ·y­{–7J3‹yÖ¯v¯Ó¡ĞÈj>#(† ø ßÉK<~S(¤=«6ºÃÓ­„şÑzùÆ¡û6}Ù1m<‚nH…x¼˜tÛLd|HMªëL3U†,n^ğÊ/®Úx;fS¦ èjš÷·zJr½ ?)éö¶ÿ)t»Ç™•´ğn·<£%Ã…‡²ë7×½ŞÛïâî'’ÄÍWÜdaR}ñ¾
Xõÿhêºœáv°JÌŸ¥Œ]Hi—vY¾Aİñ„h“´ÛŠ%Lë¨Å²1wájÊ§¥Wq dØC?‹óNÖûœÁ½‹ˆV™J+ÿZnÛ³-à~O¯(ş$~z
Ÿ@Âän•µÀu(÷ø»Y¸ëàÛM³_~º¿¿ä„SÊCöef™ğ%•7“-Vëgı$>a%Ã« . ”r¡A&™*ÃŒe(ä‚İˆÍñYeJ èn2z	&-ü“Y‰ÁÖ›E;YËŒó¡Ñe13C&ôÉ6ª ÖøL%.W=|[¶g÷®Iæºé±W·}ÃTŠ®òÆ|Ù;À×£a/3O[MQ·HöW!ŞĞ8»å(Käœ³¡Ÿ˜Ú=záñø5/ĞïÁS.Ë(—áFê†¬éH”È£<[`½GXĞHMI²°Ñn85i[	¥ÃÖ‰+Ï„ÔjDzš' ùÛ¬¾ú_ÅŒ¦»DŸLÿÕT[,LÍ”1IÖ¯îÿ(ˆI¯ôwÇxñ$Ø®73‘÷l•]xÈµ.Ú,"]óÑe6
	ƒùIè™Õ-+È—½èhPî,ÃEîı·™j@w¹îÒ2¢Yfİ`É<d£IYÇè-pö]™+ƒ@ÒtÌO6&¤,_„«ÎÜ!¾Fq¡À ûP\Ou¬¸:ë¡[òß.Ûú=”ÓQ	Í.¶e´¯Âùç%u?‹¤º!v½ºİUoñ»´§#4Î€qBgµ?< ã¿–	ŞÊI<
ÿe*†-_ùÏG\°Á÷=¦.#,
3 »,Óº»¬”¹ï7V3ûTXÂ6±b!¯‚ç‰/œj·*¼é)H×Rjf{ÂÏ=Ô¸iI_ì(€;7%8Ü?ËÊçâ9¾ûK‚8£½GF‚ı˜9ÿèé6MÿØM$ş¯+‰gÎrQ×0NÓ28ìµWÉrŠï³Jî¥ÚTÅbÄğ¦‘v‚éN“¶ìº×ÜSN¢&ØncK7Ô@ŞÀ¨Y”å
µqµ¹J$]ïcõhç/ç‰Ó!••ûØ¶5öğ³ ã¼[›Ôñ>Ò …Òğ¦“ºÙ´|—íºsXÇšk}™80*¶
`õ#VÍÄ'›o¶µP@;ôw´@Ñà‘ù8 2š1çFÑa¿.rC¾øüB½ñš³§”5d8ô×¡Æí¤cˆ‚Û¤§išNU[A¥ÃÅš^dº`;Ÿ<nL±•M ~O¬yáÒT‰M£Á®_Ÿ@³­B³§¾$Íƒ\È5˜}	öñ©®—J Ì§%3c™êy·,åØ«(ğ¹bßôÏÀ BÀ+V*]µ@®}¡4Jø,ĞñkKƒc¼"¹O9ÛûøŠ?ëÕ˜ƒ”d¦zjUÊuÖ8Ó&¦ğ6´Ä‰#uÁüˆV) ‘ :ı@n%u{·[ÓN Ç0>G7#ë<B{íT«¶›ÔÂy…<øúĞÇo\}±P÷I­IoÅ®«Qb¹_––ÔkLˆ¥Ll#í[÷ãØöz½³ª‹xœ¼²'3K#UEæÁ%ù>î…ü(Æ) z23ÆŸa(’]fA^8a6Fi1Btzá’†_Sx¬	ğƒ€Ü V¡Sr¸–À’´­H·l#P²‘vT÷ÈÔ1½ØÈÉHå	ö/Ğ–øĞJªøÂZ2¤ÍÖókşgÉ6É;ÁÖ'ŒËÏ7I•^±\‚O÷Z_<æ–'UWÕè	t}–fSªf>\uE˜.®&y£O*öF]‰Šs+juğQî_>$DœÉ;¹†Ö2ZF ü?O–±ı¤ó¶~6pŒÕ°ÈÏàû Tµ´
ÑHé1"ieÜGE¼Üp&hZ&°ÉHÇ„vNR¹ĞÂ’gß5oŸå£×Æº|C\9jÅ_˜s7h¡&›Ëšl£3sì$"×dÜÖ…WQşÁÿ[ˆàâ ÔHÎ&[*Æåèìë•ÆJş”0³‰’şÓÛJ¿wÍš±(eDåô‡Õ’eµ°Zğ“ck5Õ]Jî¯Š’t³±HGX´i	íqh?+Ìv¿ˆÊn WfOúª6û–K™&™Ãşòå?òÙn>Œ)šúÏ˜äÖÇß2×+»»³ßví8Şİ¸[®,SÅ7ê;ŸVF%ÕU)bX¦g‚èş¢gŒŠy?¶"­Y¼í|(Í,{5X’I S¼¬¸•Åıèí|?›Ú®Ù3^v—ÆÉÙ‹s(4P‡)T5¬JàŠıL­8u€eü«ÛJYá¾ˆ4ˆ
h¬(±(bòÏ üáß2ˆO ĞÎ€…à]¡±Ägû    YZ