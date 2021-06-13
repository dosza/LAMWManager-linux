#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2911175301"
MD5="419674ded3066d4d1c4094ea60d63a1b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21236"
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
	echo Date of packaging: Sun Jun 13 14:34:50 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿR´] ¼}•À1Dd]‡Á›PætİDñsñ”]§øğ›ò«3®:É•è.@%£…ÎÒ`ë5ÂCŞ,±õr_ÆûßÉ+í¶à †è…QàiWAçpç>ëİŠMÂCè[øuÌ·H[o+†øf?à·èİÍ$W¿ŠAø×ŞÉà¼øÂÑHKˆ:®	3Rû-‰Nc5
°ı Xñ1ÁwÓ˜=*Ãm%zƒ­ºzìÿˆ²æuŞoÓˆa˜gú„`±bÍÛÒ“Î&!ğ’`6¶^ÿò”YzËQãŠYY˜¯x¿u¶Á4CÕ(>Ã{é)·AB/¿”ÊÜMƒ—£B-µ10¯óîŸq	S0ÄäÏùúBc+•ôÍ”Ä§ŸÂ† ¡;²O…¤æîÈ‚¢zp¼KI+kUh 5 ë<:2‚!†òéÆÙşoå\§·'s³Ú¿ìšë-Íı„~¬ÄÏ“ª=úÀ3Ö„Ê(íu±M¶ûà+W›PõZvo»Ìr­Wÿ[ @
V05bbí9©"ñafG“=‘~ÕÌĞíóÊJƒğÜùf”ì—åü’{²¼‰”‹Fß©|çU‘eğœ<MrŞ³ÂVC}á½6ïƒ˜(™Ìô™:‹2úäş#JZy	ËÄ-É;Å@ÏC¥ïSÒ{Ğ‹}`Aã?Óço¬¬,ÌmŠ2JM:5cÁ“ºŠâ¥aš°ÒH—ÓÙn–ÛóÕ…?á=œîÜmU?íY¿ˆì„êÂl)ôğ%X1W¯!7:8ãFš.¥Ü.¬vmØ°eõ(bwøw¾À|¢$öi™LãĞğ@DV|ŠÄ5f5AwRyG¤Ì¾Ø†&Ã=à÷Ìt^gWy£_}sş‚â{Š]w¹(€Ş‹­á@ş5Õ#CÛUùT0ÏO^ÅÀ¥ó˜_-ºdP3*A:˜îáêáè?}ÁİA¢:uà•ö§j±IÙnşÂ>gA™1Àó˜…£ïBbI-/u¸³Wç?Tl š+SÛ>NòQ"ôªª¼Côª+J·OÕéP@áGmEô,#ûbİÿÓL°ÀÖáÃArÆ¦œ—5p,|êº#yu?¾·ÒØG„†3FUA‰¶[¡Ö¿Ò%ìí8dhB¼»Üú`QÔaiË±B¯ß£êtpá<~%°ÿûŒmªÈşˆˆšwÁ³ ‹N>Ù~'İ|=Üâøˆ×ä0ÄD›·ç¸Ezı"%¢`ıÏ‰­²Ùë]£Ø­(0[á7AĞ¹ì¢Òñ@ë×qÓÿpôùF¶òš–€²eï6† K¡S¦îˆ±¥wßÖEBûKVôå°®¼é¶»-ÖÇzîZºø>%PƒÍ¨hù~r(J¥á»ÿ¹AÉ_{8OÉ“~Mè5zóOÖ{Ï–š~o¦‚ èZoEM¡Ï7"I4×Œ‹5ü7/ Ç	rêêx{:)Ùg—­=ÅÏ°æøme)$™ûÍf` ÛÊïòo€.£¦€èÆ(Ÿ5İ*xYö÷„ºŒ@wÁ~¾Îü¨q<ıX#¾He×öØvBF¢h¸Í!›qk="ÆÍQÇ0¹×$¾u
ŠxNv3½5-Ü­œªå4Š5_ Ê©múRßM
©—ú?Ra>²‚i2ÒáC:Zü¼J‚øôøÕœ?ša(é”¹º¹RÀoãÈ Û†…Ey+_âJÍ‚‰Gx8Œ”Ì#z”`	Û™>iÙË÷û)8=‘‡ÃÊVUN„”ÇÙß¸i/LC°<ï:fÔÌ9»É³9Û'“‚%3]‚€Ú«^V$á¾Xê…-.y™›*Ğ)h†]¶QàÙk‚¿—˜ê„Új@B£„Òä‘òqÀe‰~ÒåÅ°ÑùCŸp1j³ş={¦I®Îå5
[$í†üs„<*(&T…·Rq=ÅxÔ)\°ĞÚŸ22¤@˜OøeOINÁÀ¡- ÷ë×Ä¾MFo›ùWÚ#ƒ¶vËN³Ñ1©^Û*ºİ4d6ÙA?ÈˆóªÃÈŒş9ÿp‰D©d’›«Øµõï¥$EìË9æ¶L/JÌ¶Å(Ş>„Á.îT|²ÏğMf½îò…=æ‰ËçÒR6¼9®¾?SîÀÔC²ÕŸO€I7Ÿ†6û£°tã|ÕãAx¦“¼â{ä!s@ÉkŒ÷±©†³²ÑÕÓšë'?tè†äõŸÉ¡„æ¿ï}èiv­kzSÆ+zhaæ=I$o¶!+ÿ¢ÙãkxŠÍëQ™É%5‚•FáŒ{Íx C’U‰,(˜¡d#é^NbƒÓwßèÙk'l…3<®ïD°t‚ÄIh•ã<Ğ?éŒµ§ÓIgÑ"zE‡Ÿ÷d˜Ä‚ñ¼ì±x'¡'­+¿<¹qBEX½|Õ±mëS"33%ôFº˜5£ÁXN™Óx Ô@€Ÿ1eÇ¢XücJ¢ê&mÿ&t/…\u"9=†
¶›±’pİ5qıáu;„)}ÌëÛg@.*¢ÃûiÕTnfğ¼&ô2$mê¤ÒoŒğÏşi û‹ÂFùù¥cˆÖ~@ö+FÜ,z9ãn¡ZìïyõJ³¨}nGéŸf§pŠŠ) õwµUöa¼ÇY=!?k®drïV(ğ#çÚÙÓéĞğ:—e	¬Ù!òœ³°^˜ıÁÃ£MÆsïö2]JË©Æ×Gık±ftŞ ÉÏvb*‹b{éóËwü+…”Báv¬#°¹_«E›>Îb¢ÜR9¹Ø;¾ï‚îª§2ó¹sëñ®íƒ×ĞÕVæIPY4qÚÃ@EV÷'dƒ«¢m"à_¨¤)5#—E	cnUWIÆ¥>‹‹ÿ¶èã7Cç“°­G¾·É ”­Ù=~õ‚QÆI¥*N¨¹ğ'CP˜ ¾¶ì7%á˜Şù=ø>oRÿõ×.ğĞ¾r¸€t]í»AŒNIÕôkY˜ZHÚ!­õw¥ãîçÜ#·L®fwñ·"†¤ü~Q5]³ ]ƒüA¹¨Íá¯®1€Ü7€—¼\’½ ¦Óeá:¶o[Õı1Ê?—Ëmùƒ›¶ú5_0åï¤…#%Õô7İŠ	ÚÔÛ¤Ğ™ˆñçwï*Ğ¾#İîvB§¥°+ßğ"at|Áwß‚$Êš|Lç5–½¾è±ìú—îQ°¸Dg±VJÁ+åYZ»=à°•:%a—ı-Ø¢Äwü7'Á©$+K ¦"ÚÌZ¡nô>¯øMÓBpğ‰çÛNk½V“Ğ1è­rzS˜×€ÇpÚ!3cŒÔ2”™ˆidùø€m¼cÀ#»©*e–£INgö ïÈÓT¶Á  LeÉ
…&Ñ¼vó›|”DjQ"Õ€eŠç¿'Èÿr[o!÷àWÔİ}é0\äq­‹eòá0‡Ğ®#¢MKÓóc¢4\ñòù×Ã¾šÍ_GJzñwk,>mÎ
×oQx¼©·¶ç5÷„å1âìšZ—G¶,Ç¨ÌOÏ¾ÉÙJ0ÔxÆ.s ‘î8ÌÔÛ_~H†ÓU9ç_“ÔÖ„B\à_Ñ•r2XÀ|6^SQÍ’”MöŠBäˆ
v-7‚Ÿå3UôÜ›’òĞõ§óÊŒ{:¿—¶bîÜ!ÂQ‰36q%#)ó¡®C¿¦6ÁõlDEÇEÏÿ#Ê±e§w‡h¯£ƒ8Ü|@×d}O×6—Ov"|h%ñ)iÒWó@°#RJ
’¢ªtî|ò#$®ƒÆûè’OfnYÈ}Ùöšã	øFlCM¡Be
Â¦)…ø¤ÍKL`mûğ9‚DaÈõ/6ïætÕn(	Dz¶Ùä–ÓyÔütÀr¯×ú‰¯‚#©Û–új<²)Ìó½’áuÈŒ‡%©Ô"§	†àãpìÌÄr\º _~Öë¯èş¸}[°ËÜLFo0éşHİX!{7cg”DxMTƒ;Y¢â®FŒ9ÓwKN)õjÒ1»Öx¹µuŸá)z#xæÍìıÓryã¤I°–ùlÖEş?ğ‡à·„ ˆ HûÒ½©pÅ¢jH£‰«sùøËZ3ŠwçD¸@û÷ƒË5J4ÿµÙQRB‚ÖÍF#ğ¿Î?ÛÃÏÖ…Âo$ÑmåÊzWí§‹^èÉÀƒ]åŠ q7Äh!"¶E‰dcŠ:3§Ï¼(…Mr{¯í«V$	a……„âŒ0qëi€q	`Ú­¯
H¯Â_ëPÛİé× ïJ¼K¢¢Áä‡™·Bá‹UIµávI›2& öyz:+¥+s\Òïíl‹ñÁ»eÍ—'ÈıH·o 4î>¢ã’d«	ƒBœ@tE0*F¹;àxh]ú~[ádÉJı¸<¥ÖŒ‡óA1\¾w&"ËBykj ÿåCmåcH¿ˆ¶Yîn€S¶ßeÒ2’ZÈ	‡Š
G :§v…Lğ÷¾ıÆ³OÌÜĞãfÓ¨tjˆ˜÷7İâ6€~•%Óß–pÌ;—Y×;És~)Û£§ò—¼¶RoŠR2ìÈ¹wİ—‰¼"²A^ÄŒœÛÂñe-X6Ä›”ìôkÉ/™Ãë6>İÛ°$Ê
şE	íÜ³Í…S,vxvÜ¯w¯‡ÁüZe±j×Q"ñ ’9Tº@±ö`|¾zÜ‚ˆ‚ÒNõqWò!µ! x²|n+çqü ±´&ÁĞä&øE/§@QZ-Ò›—HàíEâ¡4ì6(Š;¶¾K¦Òì‰ 2-jtçá^²'ÒŞq5Ğ¾Ä6±¿Š”	0Xt1qc>şi“Dµ¸ìÄ
º£`Ã´­Ù|ÙPÁªh&ì›ø*îÿ¤Püáìc¶â—`•ª\ŞÛòíš‰gÓ¾Ï·û,™*SĞ¶,ÄÒïÒ2<+ÏoÊƒLåI€‡ñ`‹×QÏâqZ¥ ßÛÊN>Š/FÜ°ñÀ2'>Ó‹AıÓL¿+–(ŸËg§V®d1ƒxÅC“KÜ'ï}Pï$ZLª {‹}õÈfËeáA³Âì¡yõ1KÌ¦¨‘&o^STı˜ç#JÀ‘É§}T÷¸Ïi>§a[âğ»o§N*‰pyrÚ=Èú¹,*óÎ1Ğ<1Ä»Ja>Á/ŠU0qmï
†{ğ…7ŞiG¼ù@ï†®PDxú¾2Ifßxìx92İh,áe{¢è¸³lßÅ§&áM0ÃjÀâP6	Úñ-mö˜ì¥Œ"õmÔÔÅ£“a—¤/ãÓM(,lšŸË^DW_¤ğ”¼ƒÛ¿e-6€
¾wbM=Dkd7÷Gsòª¿üw/Í8F|Ÿë®~”'PÔğJ¥‰ˆg×TIS‹|_m·©<ÆÑmfÎÚ"È€ëulÇ{)ìµÈ–MY<»äÌáª—Ï‹ŠtHöõ¿Ë^™ ÅªÜĞm^›İÖıÿéÀğ¼MÚºçğGµt°TJ—‰ÿüÒ{Ÿj’xŞçz¼»Ù|W-ÎáçĞ¹Ï-kkşMG.çJ¬Íâ¤ğ8¹¦ÇJ-æ
µšCgŠDÒëà©±ZÓÍÍÎëül‰?ÓÈo/Z„ÿØ–79ú7 |¢9¼T"§Kk±'7½šgÙÒÁ`Ï¸4™«¯µ§|µB#_ºîhğŞ®©uDy+VAšR–`$õ'Xydzª+¼æ¶)Î7\{˜õ~|x.ÕX±­*ªa<{Ïª\jÜ±ÒkVµÌS»ºq³7	Ô3‰k§mõÚª7’›z…xû]›(ÚS“SÛÅ gdM§pE¡wq5Šù¦
<M‰BˆM÷ÅŠo­Ò.”÷C4±•t
[øğßxc¯´œ¿×a§üVªÉM§p.½f-C¹¹µRAÒÃÕÕ,AÇ ìÀ7­²âuCßç‡—»üyÔ7;Ñ@)süäÂ¢d2“ÁëêWªg–ât‡œsnì¯şìtTÉ<p}S tZ£é¨Væ‚1«‰SqãŞmVÌğˆÊü€¬±€aSĞŠ{M³z¶ Çj˜‰ËJÛæ~UxÄ…yp2âO|‰gcVÍD™S)’“½tqw,çı¾TºøÀ{¢K&ìZEÍv²µ/b`İWX@’CÎ4¹’-+"_Àü àº¼ş\Y„â´ME§T~ÿòÁT5`¯}ëæ¼Ÿntzö58ú»,<Û/óª:Fp¹²‹£My®«äOifPÚ™…G7Da
~bÉ³eÂš–o]ŸgšmxrãÛ’7‘v‘$şó²¡¾É×Æ„.FáMƒ™:ÌŠ.±TÙR£_VPPSëg²Â{ËôyçÚ2í+–´Xsn¶˜CÙAƒ®kŞäÅ·"!F¤¾øCÍõXP‹Õ9Z”i.¡‰ b·õºéª2u”a_ZT=5d¶Š“KfÅêD,Iš_ÀUrb=ÆûR±ûO~.:»Ş•@dîºÙÕœì«ĞüzÓ?kHÙk
 5û ¾ñkÛL:uÿiæÅö!¹è/›»ÿÖ“ãYK•®Ùò#Àw*â6±ƒ)åãHu
Œî¹nA²VXÀÈuãÜıf‹4ä–ê¦ëºMM2|ÔMP°bˆïœì\(Š}±7B®?»–¦Ø8ÊÀfÎÑHW§¬L¨©;”xA=¬5÷Ç»o¹äÓÙX^ëI]¹G0"DzË¶{k( 
’gv=Mcƒ„((vd3¹“Nñ5…eÅT¬âÉÀú±“BV`I¯¼)MÉì—K›Ì(.ØZ:«š¨†q°ˆçÂÕ“dœ¥5©KšjjĞ†ºá¬-øÁ’¢V"k®/éOÈuğ4I$ş-›ğ‹
bòjÚwúùrôK&mÙÀï’Ù=MËÎO;fBg'Ê€*q	.L·šÅÅSÁƒQŒ@+Yƒg’{Q,Àc21xêI†µ^¶
GsQMÈí›œT ¸ğuò½óÃ®r6Ññò¯fBÖÕÇÀåä¡ÎÑZi„=‰zß–Õ%3ÚIL¤ï1%mPÍö™»ï„˜©¡š4<4¯}k^¹¸Ç¯öR®	7²$D¦¤†LsÂÆ”›Ô²Åá:óîWdqLµ…S¿nÑFÕ40¶XWD¶åüR3Ã·'M3{àÿVAYjÀ¸Ô=D_•§!`*L¢i£~>ç£ª%;#ÒwÄ$p,ÊpÏ)RÆçÊœw‡Ÿ¢“-«‡&İ’eLêWÂ$35WXŠ8nšÿ6a~sõ›­y}û‹áşÉğ”ë»š&BP¬FAU”.ƒîÁ¯ŠÙkİĞêÌ§µU{AøÏe½[4¹ İ˜‰ö79y  ¹ÿ<ªZ9ıI±œU$dhŞ6†n¬İI˜næšŠßßø#«j§D‰.––ı1È!¢Ã¥¼ÃÕt2Î ÛÊ€!|•BŞú€ˆ:ÎµkÜƒ¤K—Ê³à±DÑ>şXp_ŸOa›ä=@×Heàä+LX>xt0*ìÎEù äºñ,²2 ÷6öæw] İÏ„„’dÌ+!a¾9€Ç])ßwèt°-/3¤ï™•³7ÃË¶FØ/ıQıã‡‚îoU³-X1˜Zµí¯É('3¬•%ÚT¥Ôìidï©º™@]Ï¥-–÷cÆâ"êÀ€½¡	A±¾oT&>şZ:ï¥bc~X›÷h</ª¶åêcHQíÇåØàZGuj†Ås¨.Y¡ËªS2PĞe=Z
ùoçÍúxiÔVµ_3ŞÀq4céü‰i÷‰=™h“NŠı$Èl™-£Ë=J\îĞ=¡=ŞÍº–Âí”n0POŸéiP°ğ«_yo½=ò3˜èÑŒµ*Õ~‰ÊÔ rÖhÔFÇ–?Ö¯££—à0}ã8°t´	¶‘\IC)5“2pÚúÕÏQÂ;§|¢+;ÛØ|ŒÛ¾?T
	Ã„@şO ]z«_ÅùŞ~eª'ÒÚd™)ñázg%]ªsÕc‘*ÛñÛ .›¥÷Î0ˆË{­½ñr|İæ^NâÚWÿ„Á7¦´|¨ö¸^<aĞYêIÏ‰ƒgç÷‹ü’‡İ+ÅûˆkÁ©»oÅë›hıp,cĞåG˜{WhœÍ$Œìc™DÂ­'Ëgõ¦¡}pC”9òç’)\zæô®håü³ë,Å°î”Æ0rF%@ív³g1ìÔW©Ãœx’“¼5nj¶²kÔƒPèÆ8^uNõ’·^‰ùâç4.Ï¢É0[oxyWÃM„”l)Oåèæ&ÓFÙë8ÂèUQX5ô ñÕ%«¤#…LØğ¼Öœ¨q»`ØÀçY¨G%§Õ×õ™!;aéhNÉ­>N<ìõˆLrÉï¦øÉ’İıFÚ8&…«‹DÕ3'(ÉŒİ,ºK’ü¤ápco-ƒĞb!ê­ "»:ed¯‘‹Ÿ¥Ø™Ïtıõ¾»˜¢¿Ê)¤J½¤1òïò©ãBòÑ¸ˆ?«øM|²l”mÍ¥±f'ämv8¶Î¼¸ÛÅé¢p“h­½†8I‹®›)qÓGë)]†¶€¿sÆØj×„ÄÖçÈˆ˜Ô4K²wÅ"ì†ßj5ÿÎú¬ÄÈ¦4sÛşõ ¼Éyİ»{¶S¦o¦<¨öìş(Ë¤Œ²/ùëÌ¾ÕØAŸ  uÓlmt·­Ã3GL‹¡¿«¹ÕŞïùä ¼v¥sÇˆ™©`çlv³­O'ò=ÕôOÁ”D=›:Ùvõ+ÈîŞ …—Q§ÀÏë<¸2 18'ó#`ŸÖ&ºDÕ¡;Jb'©W|ŒÙÏ#b§2&l·5—¹Œú«‚Üæ‹±Ş/ÌØ·5d{ŸÜ&¾äsôXBí[ñŞ#ı–öÛ`í]Fv'ëóR‰0¶„ŒX©ÎÆÙ‹H|ê«K?¯œFßàeÖa:¿<Òáİäİ±;PáÜ°€‘@Æ´4æÓò_{R.¶ØuæŠÌeµªñ{š¥ù¨6FV7ÏyºŠ2ƒpW‡_¡#¾'æ°G/3 ¸„Gâ âMÌf-6ãéıVŞŞê1,J-{„ƒŸÂI‘œ©Ùşàz“Rr±Ä¾sºv©FM5L+Ä{›¼OQçc½‰(‰sİ°RÖ-Oş&bŸĞ™`il´2ˆ½0&n3]_²á…åİpuèx³Û;H¾ğ"/’÷Ò[•š!\¦õ:dGd$tqq’°ò÷3(ê€9†V+…?'˜Ñ>ıºM‘¥Ò™ÎSÄÙ)İXÅ‹æ»ÍTÕµ 3ùuMD5|¡6Åú-…ºıt€òCJz0BÇ1ø~ëj¢éìW^d¯|[ü;¼ŒÄ©­ìÅTe-Ÿàƒà^;(q}éìÖÕ»ım:ô´ó°3ÈÂ'6ëö²ååµïŞÈD³“àŞ©ÛK¼1y[“ 9¥™5äøVŒì¢ƒM/Û€R‚¢
c¶BñÏ‰ÿñ 9%z…)÷rÕ|q´ªXÂ÷RZI2xë)ÕÕjÊbC(A¾DÀøt–`TƒR!0CÌ=;î(Ş‘˜¾=_7 ;¢Í’-¤“–àĞ£„r¡2uW€+nemß³¼8§È3)(ñ»@S/ËOåšBÄ`]LPl´ÔËç¸nfh‹Aû+òsµğõŒ°pš{¸]n:³³ˆ‹Æç7Ö8É“
—ªÀ¢P\eD†µÕèİ¬fBxëÀv¨J—Ä×˜ÓÕv$¢T"Æ+hù·ıØ]ÅñŠÑD§éMöQ«‘°4ùÄşéƒ×™–c|²š¾nP¾“()£W¹Íwt)zõËQRÙ9 §Õo¥
è…=–ôiáØqˆ(§â@½´ØÉwH£eúÄ92Kâé7~|&šú·‰ßÊemÇåq-ĞÙv+óñ; ¹«ê‡~Z@ÖÚ¾ü«(\×dŠb‚²N‚¼7|6…áUäc/ááòÄ7í¿}Ç1|Ú¯ZcÏ@ş[IeKÍ"ÉŸâûœ5õ…¦Šõ]Z4‚ü>ŞâÉ¬ÁİèoTâì|M›”ÿV‡ô6¸§¿g¸¡˜t+ZğÉkŸëŸş’G,®†–;w€õˆïµíÌ|[ÑOŞ ¨£Ny?¤+NœÚß5HZv$òÍxÈçoŒÕ‘ì8Õ	ã¸™¡[uø¡[ß{…²««ÒKËš3(~Ôº´²ĞÈ=‰/å"ç9'OùÏSQ/Q¿Sí‚3‹>ãáW¯Û
":‹~í%­êîH–ôb¡–=:'¢0ÌÕ^Šİ²»g´‚ÿÌ¹šıxÅ ¾¼¾ñÙ»Oi•M¶dÌ7SâTbk­f%c†ÂS/Â0„vIŸî%~²=ğÉtªñÃ#4¹í)R±İ„³Oó—Óèƒˆ€:ş ¼åöáIïj]`X£4}¯›âO§XÄX?ŠšdÿÔ›—5=ø¯ÃìßV~’Óy…MJ´7¾QƒKÀC¾^ …&!Î >¤xnÈœˆiTÌ¤ãã,XLTİ¶4È•]£s¨±–Šâ0Ä8”E¤@ë	ĞÆæ`ÃÙ‡¬õ©™	U¡,„27¯ ´½f—ÉíáÔú ‘§µ^.Ê.ıa¡6Kp¼½1ákº¯5¶%HbNå	¸Š¸\ÌÂæØ*·!dOò9:)“=#&6Pª£71
ßªWalÓ°^ÍdPËÀ’÷³øš­U"Ÿ¶¤Şñ¨‰u7ö(Ïıõœ$ÓY£çw"ÿéÔ¸Ü^´7U®÷œd¶†ºU>$¤dšÛ!BmŞ¯¿Î
à«S±Û¸L»Q~C28M0+4~ë¨jf?í&YSÓa’òêÈ&zÊX&bS\Ê«KKÁ Ó¥Ñ´÷cÃ ^æ.{…Í¾ñ
-È6)YcÅ,Q²‹„nÍeÄÂ£cıNBÃğ9¤Ü	Ùï‹œª=ÑÁLá®ò®cœS¤H÷WĞ*fkëËÀÏËÛM¢²l%©ş’òÕUÉ‚ ©
È„ ŠaZ·$³Á/ƒ<xûáÀ	‰õßb½÷'6x¥N¯£Q,îĞ|”îKÀÏST!9´ f
=7b©L)(‘ëQ…pµôccµ¸Å÷BPÂ-0œ¯I» ‚0ÙW¹1áÌ—Ôu ³Z¡YYÕl=QÁvîFÛÂ+™s$^óèå×˜)›bçå¾i½Œ'Q‰8¢ï­¨¹|c:JÏPìô®}ÓB]¹+P„(]1é§|ŒÆC[¸UƒuHsÖ!ø—ˆØÌYácawŞ•Vù3 ^‚[°A‘.ı;¼?á„ö(É ¢ƒÏj´%®•Ö/ë17…µÜ=øüz“ß»	b£Ò‡~ÑÌ)4{~ÁàL ]H_t
>ÚRŒs¢S“¨Ø:Ôe¸ÙÔœ’›*?ÅôC¯ã94ÃË÷…º_”ÂƒÈ‡›Èìì#ÜæÊœº¸‚‰*½2X¸ú’²Iı[û[GQ×l Ö6YÚrÜÓàç8A±;½S>Ñl¿¢‰şh0µ4;iÇ³RèåKn§­?NÛî ¼¨$"¼Wï?'ã¼h¸-V}|ïHŸ³Ú7£êwÀóªÛw	ÇøhaĞ£ÊÓ+ÇÉ[ø~>Ì;+‡üûó"ÎÈóã[ˆO¡fˆ\å ş8œÒI¨£Åzü+‹em4Åj<Ş!•vV’ŒâD¡¹W«ß…ˆ‰äC¨oâÉ†pU¸I–äa6¥„Å’“ÇÑ¥éĞ¨õ5QL8”¼’-Ç,,fˆ‡#%üÙ»¾œ­vG¡$ßëd®Gê¤9ƒæ\tí±á¦®áz½ÑwctQ…Ã-íy EBlËÁ›è&Ûn˜uö"6U½`¸µƒáĞ0-yààrˆgà& [øõı¿¬mê-hœ*dNÍLÃß™¦Êœ%DÑb7<+š|<Ë‘|:«Ã–œÕ²¹-Ï)ÖÎñV‰XYlGnsJ”0á?püšS¢¦º¼óráıÆ£’µ\!ÀE3Úr €Æ<Û³¯ËĞ¸%¹SN„¨Z
‹ScÆ@	#k¾[\“LêxìÇôyÔL*5*îí›Â“D<@â×-´î˜ã´ÉWÅëE'YxC ¦.9Å&{‹[’ˆJŠJTCbÎÕkºoµóX¿C~ş>¬DºÒfÔmÁãqè$êàÃ
¿ŸsîfN?Ò‰X«8b|Õû
ºk½Sİ9Eà.ù<Œ”pÜ¨_q—´¤±èÿf+Y'ó²³ÄIªu± œ¸®İü1âé!2„Î°²wú»-ÿê–8-¿Ù`Ağ±2¼ïçı-pŞŸºÂã&#È '}I¶q/Y ëRO:—”âkÆÙÅÔ„£p´9Ñû6“u½€ÜÀù'ä°Y2¢aÂ¢ÓO¾Ç*® x3Õ¡ÖˆÒ:t¾4ËÍËÄ­ûƒÉ®Òª>šùçGÍ>ê}OFÊ$H÷ƒ^{ŒûûndÀøeÎX/sEÉYæ¿]
Ìc‰”AÌnÁ æ=Bƒ
‘Î€á%AŠ'£\!Ô0Wzó¹!ãFÙ~³òFc?³5ãÁsúÈk™ûÓ>›hñÓäb]r%”*]&”ıßö¯“ş&ˆï9aì¸Fê.ßĞ„ü›^-–…åB~ñÿıV‘®Såğ¿—|Ú¨¿höŠJ™Zˆ½ôšX
7š¦í±Œò¥Y¸‚MéÃ@.ó?rD@·b–¨£‡W 
s!$‰©r£.ğ@QH±ó‘ÄÈÍîÜ÷ATxc¹GÂ„¶Â´ù@ÿî!jD0FadBŸc§e‡[ƒ\›å·C
NFÍ¨–<`ªÑR˜5ŸN%†vÀvÃbY3¼,SLRıü)Rµ”Ùût°i£6 R#aÅ¡;ĞE òpkZ)Õè§Í}Â|<4¤"ôğ‰c
ñÏñÈäQqwŠ÷MñsU™Õµ¾Î•ãÖâDÊÙ>6[U«SÍDÎx4Ÿ»ªâÖ¡bÊÏt™¶p…çô˜
B»Ü½¬LÖÄš˜®ßDuÇëËJ‰yE<)®I27…xOÇı_©8íé%ìQİ>³&7i,Òõ7ç§[©D®­›êíÈK3ß.y•ˆ^ÅCªÔñÊª.§gÎ7jË…8Ñ]#¬­»ŞH1½p%{¹Á0ÇùÄVòÌÜçÿ’ëÅ5l¤çÛ&gaØ^°L¡¶qÙ°¨û½ŞXÚ¬ê?-¼5L¦:Ó¬C‹º•ƒK“A H°k¸{‚ˆàKö]‡­ã†F£æ~æ)6Œ›«a}Ë~ ×ÜZıGAI>Ñ½ø½êïw5-Ge¢›‹&Â˜•û—"x¸@âœÿpˆ¢\ŒâZ©íy,b²l¯×¹sj-k¨-L?D{¹ïUáFT®+×q÷.‘öıâ*ÏUkxDe»™7×eğ?<:"èçÖÕ!›˜4Tf8 ˆy˜3%aÜØX7ÓzÄ$¸;BmÆÏá‘Îú‘AÀ®HmŠ´µª<xÊØàBñ‚úßy¶.LÒH/y–š~¼u‹œÖœİŸ-5^^­l!&ŒA_™Ú¢_Ü"=vcßS5wæm
grJ3c¾#ıÖ†pö‹x¼¿êœd;ìåuÿ£•kj|ReÙ>ß‰€
²1¯ÔÚ³(­)ÃûÀºœì†~qWÀFşÉşÙúŸÓÄ‘S‹Ù…à´@XÚÜ'cEwƒ†xy‰4ó­h±ÊAÌM‘yå—é=6‰Ê¼´“€äÈ•ûÌhí²û(ö‘µ4ÿ…Ä€¨(‡ßúW°:aò™~E»å®q´F|	ÒJ‘j‰'¼^‰íÌBÿ@K3`,|Õøx}µ	²G_#ÿ•¯Ë¯òG†dlÓwH0¤qù{öPÃäúãò<u”ß¢qXM¡kÄœ½±A,K(†öúZkP¨f”ò[„uç pŒfm§¢Ÿt™>„?,Î”uİNÎ·âŒóCvŞÜ>>kc¥ ¾Cñ›„y™8‹è›22}•(É…g÷·¹abĞ^î<3²s7·_â,ÇKmÂvêìîz=¸{» I²-ââuÑK:?ê¯jA‚wi\QÉ9Z +zm!óƒz‘`ë“t°‰¿%akª•ÂK… äÍYÒÃ5}Ø9[×»Uç’ÌŒy{íaÔkÅIB*Ñôµ|kõ‚sIİºŠ°ä)¯=D¦4³IØÍ^IÔPÇ7E(ƒ¤6£S†Œ4© y à®Ì/…ºØ¬¡¶^:njıEæ˜-!fIñªVT>„Ğ Ù<Ò~µy¼Ü#j_&tíud]Wd•4å#*\”¥ !™F¡àîw)&„HÉ¸O¥´«ÏØùò¡SoÃ”¡‰Km>$úî£ƒìµ÷™I9âù…ƒÚ„,=mËE¸šµã.|‚)¦_Òö†=V·7©\Fpö_Ò»óìD³­Ö"rbgy¬õğBÈÑõ³\Wõ[&[ÚsSÁa„oR¿LÿrÏŞç†YGZ4é+ÆÃ[s3äZHE¡\t
l8=SO“ˆPƒ«qhÂŸ ÆºuœıY˜, ã¹uÖ”Ì*¨ù>ñ¤Okè†_~sn¬:vC[sŞ¿7u	%eîhKÁ£7(¨Y^,J"#¡‰ftBâF—$@ÎÔlc`›ù²µ¼íı<J…èş¡0²·kJ·‚Bïı¦È>`·x±¬ÛúSÉ­nØó­Û‘èV¥Éy© {‚äTÎš5ğK%¯D&æÙIXß.‚Ö	üy|dqÇ‘—%<àÿúî'äâ—*	-}\k¡â´Z!=kšûó±a!¨§ï¢²úëh 8‚Ê@Da%ö…Ë—/èß-Ñ¦éü·™~ºş°tØ¬ÏÇ$JSª\?ãé¿#š¹GzåÔ·ùÕÈ.¦_f5úwìÈZY1ÉSãHæa4¨ôEÄ±€¨¤Mæu¨?Èİ¬¶×«a¿¾°Ü¨ÚOZ³ûvpb”b”àØ/ö	m‰@”ÑÖqÑ¬öÍN¡&±Ï’Ë÷ó®ƒ¯:¾yìJ¸«â¶©µ™¤ ¬âL¶BuoÑ0Æì•„%îF­‘’¹VjX-JckULZ…|8ò‘S¶«ò–™ş>xš,êqL¿¯SDå¥&*Ô	íT«ÀŒ-ÆÕØx5r¯·æĞ¨x?I·kó·ËÁ©#8Ú¾¯L›·2N.xïîÀÅ­”àµ´IğS÷vu3PS[e8	0º€¼TwÆ £'@”ŒşV%*úš8®ßÎ—bşWÏÜYRKÅ
ïçˆ wµsTÔ‘3µ?²¸ş
åÓàYFë”E	:N›YNîœºµîh‚êcFk5¯D'J‹ş³8vµ†HŸá³0éI%V¶ÜVÔç¬Üğ´r¼ùB¨ù¨Yu+b‰oÔ­0ûCúàœxÃ‰ôDÛÕjòôüı¬¦8Õõ€#¸ß
?ÂUŸË—i®i„ã÷j@WÅ®ıÖ–¹tØ 6ì^­u0¿Ì“ğ÷{H2ä‚ôLXÜ+ßŒÛÑÅÃ–v•neŒ_İnÄÍÕ7±—d	.ÕDRr.Ma[õ…h+ŸBoüNôêŞ…
ôhì–Xú\È8Bı)Rk»¼åÇË[¤ÔHÎIˆb0#ş·û?×Ûü¸ÑC£?${9:*ú(ûìüõ„4‹p‚rK‚ÓT½uoQiÕµÎ±3Í‡69Í¾¨“f`€¿ÂDzOäõËˆí¶Ä F
Çq\ipQk =rG¶Š»Ì	‹‘5#8Á·Äæ]+Ïî‰GØ+ûA‰İhJ  ã»ÛÕÿïŸ±!;ÍÎ¢#ı&:¢gŠ ámÃĞ‘´é»“ülWŒÇŞ=S;­ )XÑfñìµ» ˆî©~nØŸ
FŒä˜õõ9ê4úSŠ'‡©{ş°Q÷3Ô9~+'Kü¢îEœŞ-¬4[Sí®©@TA)±Ì¾äÅ+µn	ˆğİÊ¡ÌŞ/uÌ„*>ĞÃn‡‹oXcÉ’3$&’YÔ#¤©øYIBâ^‹?G`ÇµU÷k+b?È®Ë-:ow±L¬øJ@K­¹pª«C‹[µO$‚lØ´AjÓ¦ã¥Ëà÷
eZK¨¤ÂÖÎrÌ8HZBLÇLåŞÄfünZ^~BÖ–pğ1^.Ü³mAË¸1jö²ûx
têp7`¢Qÿ>™kaéG˜³ØÁ^89>»èBü`ƒÒúŠ2b¬ÿSÙ(ümœ»~”Â ÖÕHÉ,(ƒáÊª|`÷?e¯ÊÙh:ÇÅ6ıÙÉôˆè€Ì—ûfU•_zIêCiÂeš_İ7˜KŒ/IyàÕ½ ÷Lw4ØßC¥—:Ù€Ã€å4¡
ySy{¾§ªí=O]şÅhd~õµÌüá 1³ S<Hşºµ›(èàJ±Õ¤O¥<ã?kÔÒ7‚õÙ	©ÊAŠ1˜.á22¾ìÚ#9ô'"°
4Ú;à¢DÀ2CÃ¯Gz>ò&²‹Ğ¯ßŸ1†Cë‚çÙ™Š` ,X|˜o•ò¨½©îïñHù«Œ ËÍI>¬@õaÓ]à¬æï'X/©©½»4¤v„ßc}c»7Pd•/aÇè÷°—wéy4hlÃÿ4+I+»b®h·Ş`|gÖüÔ\zl”ŞZÎékyp‘ÁmÌC“aÀ?G=½ïŞšªwùãê¦Z¬0—/´yßŒõ°vÊ…„q…"p®ìfÏ~»èÖìhæ›ÈàL’ö'Í*ä\¡8IcVØLxõRKÔ-<j	Ö`b¿\pˆîÜ-VBf,øÍF„†Ú4AÄ¥İjâĞ·kiXŞ>—}eOw“1ÃOèuıÏùˆ.s^Ï÷eE.¹’!_0{4å|ä›ï‰V“p3[ÙW‰?Æ…míDÙE.†ösOYQ0£<³Di7ÎîIö•UÊªb4Fı£D§øšğÇåé·[8OMPôNCAs?ŒZ¼øpm¬g³„Ç¯à5„}_«z|ªâc\U5ûwcö!JŸä§û›€´¡É #Daê¿%ÏŸuÚ9ê
„¥²O3‘ÕI*k¥ùà»™#S¡Ù	íìóÕW2Aİ&‡Èÿ;š¤içé“äÀ6-tµúR+—(Şéå¤^ÎE¿â4©¾•-V€û£¤_ÔS¢[êÆG¦«7âZO†šwp¨Ô³Å×5lTT K]8Îq¾ 6BCÀ%ã\}Ò™ğœ
šË€Œ©ƒŒqHìa„E°õÇoèšÉ@¡'SQlUg;•à5SwIĞGJ™Î õo,îPÇ¢Ğ-£­ÏZvI¤#¯àß	f„3À]}½JÓ;©íÀ/®Jer€~’[uúÖ=öêÑB·ÕàØ PYâài£.½+^¼†\öMQd"8óü\E }¿vb»(±œ=ÉÇfçÂ|ß°h‚3ïÜÕ][şÌæ¦¥{Mrîç™qu&®§»Dï}J;EfÃZÌ£`Z4T3øŒüH	$—õÇ'fÑ]):€a5|
ª2ìpº:8Ø¾lhµ>ìšAU×f†ÇÎ§PËÅ×o_ .9sjZ«ßS¯ö¥A®k­³y›r^wñFRÁh@+ˆq›Á¼|d­Sé_îh-²ğüw±YVBŸRñNEê°M,Ã· l `£áè;øN-eczaÅobb;.MSÆ£[­õ;œmÖEÑ=f}¹«íŸIÄK™D²å¸{+‰<3XÑ,š‰©Ÿ(ETŠ½¿‘ië³±AdñOsz~q$HÕ(/ô0ÚGÉîEÒ÷:BN™èÚÖª„¾*ò*Í®o¹×Uk1êM­¹Ö² àØgOxÛØÖ¡ŸG#`…ÏßÌŞ¹<€¾ğÖÔüÚŸ6¨¦˜‡ô9„?ªó–øÌµÌY¡«&t›­÷[lmRŠaÊ.½› â›±UdÅÉD‡[ğÂò7œ¹üœ%c(2¶öLºˆŞÕËYM¼ g&-ÅÉ³x!+òŸJ% ÄÚµB!²kø•ìı0Š€eÒa¼@?ó!_k+zâƒœL)¯Ï¾hI?/
êÙ‚yG¬î_µrFıwn_†›¦É ¦m“ï÷[ù(œŒãŞ,{ïå^üÈã7b£Zœ
ùY´±ŠKB#©&÷˜×:[©2g™i¥ğ¼r`NÀ]¨û[-é}8Uç…Äb"/šØWY(˜é1T¨­S.‰Š;ôÁ@ÙC=h1z xÃÑ!{÷¯“½Y'æ­J£ÁíøuNíğî©:¿b{¾›0ºX²P<Èa‚)b”S•ÒMwòÏ~#}ÊÒW¢ØË,	ç-Yã5í¼³«Æ(>ªÇTklN>Di"éUhå ÜwèæåÙ×xĞƒÕÖ«Š@‚ˆı“é=¼¤€j¿”|â+Ö	ájÀN5Ï¼ë ÜRxh'èh	_¸ÊXF.ú!˜ü–¿Ÿ¥æ¤Qùºy†şóÈ¹bn®ñòEÂ›^ªDÛ«tñôh{¨ûƒó`ÖÀ2)D—¥¢)Z ’ı"^mz,q"\ÅÈ›`4)'»d—³‡¬ÒtÛè^û[Ra‰—rHøæŒuóN’PeîÓÅ£æ¼ÙWbüú³oƒƒ üzF·Ñ,{’ílªÄXöÁ—<=-ÖìÜœæòm;Kâ€Ñ—ÆQãôe›¤¥_§-Ém755zŠ{B
×@_0Ä‘ —Õ6h‘S¼IgÈb6@À"†¡;OÓéÁèÓ6:°7Gx‡TdßE 3Œ^'ôm›Çz‡°~]F®_pH#]@¾CIFV‘QùÛ¸pçfbQÁ]ÄaGÊ¡ÿNP[iQãhèï·¨Á¤z÷­/ïé†úq»/‚•…©‘Ìş'H—–‹mÓg"èÏ…¥qQ0n†•x:QzÌ¡,óİ‘ıç;Y7* CGOm•wuóF9Ëá~DE¦…‘ÁÈzXœµêÓÖ„qTÍå·xÂWâ¬c„G§)«‰“ªª;÷MWÁú*ÿ ÷ç?¾cÓöŠñÃaŸ —-2é¸Èñ°`O˜`·¶ƒèwâ,VŸom<…ÚGÚ†_>†×Üvq…`gºX¡Vr96{õüü(&âšW_Óı6Ë¸K7ƒ‡Ò3É/„(=
ßüèêå!=í£o‚¿ŠU’ïÒmn!”°™B’kş…0À¯Tá&†ÆHV…qù‡A15qrgCVûø›«ÖvÒu“ŒYéúÏİ52rô}ô j-s¢!ÒHë €q/pÓ@sÚÕáŠÓ¿Íõ`5a…Næa¶H=æöF‹EI[¬õo-¢_s»QCmŸQÕ¿¢ı"ƒµuzS¨ß¥¹“Gí·–.ğå'xûò¤5C\Äíj›Ğ
…vØ¯mØÔŠXåÈX”Âİb½3¹?§G1t}Ç‰Ö»«8Âå×2taaÛOR`nÈ¦úÏï²eİˆ¢óÚödÁÊ$¾Õ€ğ %¶İ~CÔL_%!g÷¹ ı3)êL+ïMbÌb¾„Âuå"ëöšDp¨S¨^S«à.µfp»ÿ è›‘Qæ|>/åÍL¢Êw×†Àk[ƒ"ˆ¾êTsÈSä¶à1w’ÌóSş«S‘§+tN*CLj{Uğ‹’–# LÃcEIhÔ)ÑóM2\ÓXï°œQ·}ë´«²|àËqçÓ‡#ŞÙä Óaw·öÂ†:½Dñ^ˆWH`?ÿWÓTè¾ Ó!_ÆzòRş˜^D%JZ˜|¢ÇÃÃê<eÏz•-›õo
xå²TnÜ°J.–„4vHáwe¯ºóéUúö·Ó#U™#…Kc›<" æ†¨¸l:@;ƒŒİ@ìš’®É-fm×$Òv˜†8Êm6çïqTyf±ó˜;Î6¼LğT–JÇì&œ†‹…nqrÚTã˜N!T³Ã~\UH py¿ËÃø8¦+\ Ë’j¿§GÛ
Â'ÿ‡gñPJĞÆK(†Ğ²÷ÎUv—ÓÙWİÜûiÑ³dH”ç<“œ´âõÂ‚AãR©aÉ® ´××Š¡°‚²î*:’>üğ{ì¦*ƒçç¿ˆRÓ{îŞ 1ñıL	 Á<Šâuäè†÷ÉT[7	ÏP£¨NK3º.vWqˆg	İÜeƒ'	ØqŸÎ§ë)·2‘wûmep©èÊ¥îYü…ÍÎûÉƒ¢@¨C	Aù/º|âîIvoBxqG­A)`´5¤Èaf¨MÒLÂÂ½3‰©Ûß=Lâ5ò$“Ÿ*;Áï3áØè†dc{W­¹!h1¾`bØÆ‰# ”šè˜¾ow¸~¿Öf7«æ)/Pñ¯óò	1Œt±¥,ºÓßÊHü'á¿¹w!›sÙ‡û+ô¤˜
>2Av˜öèöÅ.­$÷‰½¨„‚d å~¥uÜåĞc¡ŸpSWl¸»4Z¡iÏ‡5å¤GÀ_~¾NÎë*œş+AV¥‰ªoÛŞ, ›}Ãq­oèÈ6¬õùæxƒ/	ÆËF)’È”PlšD5¦‘9Ò	¯åøìÉ¾Mã®:$êB»ƒrŒ°&U°Ä7RE‚ª}H¸Šycäï¢Æt4 ÛîÃe›æ`MuúvìÒ…µÌÉŠ¼ìä“:âW/?CæœŠÿ}÷“nNz>@wš¡<±ÛÎ‡&¡éEÜğÛ–Ë
¤ñŞë³0”¹eÆòĞSb5†°euN`™=ã¼”¤3¡gçE•\e9óÀQàfì"¶Şzï½şFµ;°/³;\\­X: W[4û…ƒ([¨˜ŸgÁ‚_3YÄàä4­˜_İ¹Ú0çÊ!÷X¸Â¥j.Œ#D·ÓüıcŞ^%ÏFfñ¨ĞÓ5ÉÛ3çiâ<Äù;Kº†Äü‚ÀÂ@æÁuFÅW˜Ğ;£œJ7JˆŒ%¯Õğ,úÕ*Çsö!ª¤ê-{ùO<(PâbŞF}¡“¹>ŒvEpA­ Ím!e“¤ky•'ZY¾	î‚ÿ§Á×†Õ¡Zµ× üé…®¾2®U ggÒ£¾sù+)—œ
ı‚ş¶Èò.a?<¢±,*Û~wj2Í¾0p:sÜ“’ßÍšZls¢Í’î®œ’–\“;DŒÉ5WûFGÄ¢U€ŞkñóøúÊZoO%@€öº½“¯ªƒ&ú…qÂ  l±BÖ“¥\ŠÇù§işñàæß6*›YòÑY5öòoXĞcörÍJwĞRNşñ ètÅyÑJ!ÂòÊSê¸”›´°®åon9§‰BØ]cPz0ÒG–1k˜l•‰-İT(=Gd·Ôp¿Ş8.ÛD–îq¡LB·Ò­¦ºÇ×D}ôyjc³H,,ÙsÅŞÙ\Wé È5åÌòô=Xúx™æÍ1Ôò•œOzäìÃ2G™p²çßµ&3´—¨]eè
ğQ™g¨È‹EÕÆÇH!w€îqC¯(¶çÙ"4Œ´ ÕıÏ¥	£:©—•‰·ÿ0$c1ü?­­*Áô[#v&Ÿ¡šâ…ÏñÙ´ÃU¼$Cş*Õc1‘¾Qü“1ÖŸ¹yí‰óÁë¸Æf@*T pi•øª,@w¨°ôR5œŒ 	åUp~á–*4Î3`1lfOz8KD´ÀÛ¼¨²uJBØµ*ï ,*G^¦»İ?G81Ç·ÿšhMÜrrKweÓ‰É§=©5²=nª~í¼ïı†V…,óà"Ò—Pj¬jBBí§•¢6ğÕBåîåÑW:…—ˆ/XË‘õ"GŒVÅ›ÃåªßóH3œ,|ÜzóeåèŸ3– õlØ:ñÛYRšÉ½sˆxe·ö}2u #
€€§’J‘/ –ê*aÒ“&·„íaVUÅ6·ù uL,çÌ–ˆ¡Fh‡Æ7ô>½9ğ+¤NØÌ+éÃQ¦‰âY–ºÜ,$ÜìœuóehwN‘‰*ä)®cDºq§†ˆ×ÀáÿÕ¥+–L m9İÉK‚k\¯âÿ¥bŠulâ9±Úˆ•vz»2wü]év;áÄMšLüz|IØ¶Eÿ|•§_Ò‘—ƒ›õÎÔBœ¯Iùò'F+4øä§Àı›kîHúy0SràšÚ¸@g\³’õë†#¢
|é°»æ‚ûÙúÄ  wÙw‚ãOÆòÉšw£!jÿ¹®j«ËÂ®=üx(‚š¢Ñ(Ï-|¤ÓZÛ@/sp@LïùˆºÅáúƒ=r&]hğöİF–ÛM3 n¨‡Pv^'Ïûx<Uú*µ!½Æâ¦'l¨}öŞ›Øø|L&aQñ9¯öê#b§Õš$6ÒùqA×M&¹ïŠıÆO”&—q$4£äÊ¯#½'ìŒ:–ÖŒ¨G²_páÚàğî“±ÅÀ0õ†Ò`pÁ»†MtËG7­`O¤Pûî0š°e©ëŒzŸ{Â’jB!ñĞ‹›©Õ-\C4^şaÃ–ÙÀp„‹Ëø]v«
»"ôVj„¿=9VE5RÅÕ1·¯ÛNoª…6”
ÔÀÜ½à KUô"·#ÚÃıÕÿ¤ £tÉUpbœÈ|{•ĞîiÀå¿Je9'Qkec²|²”bXğİÖ„F|ê4ÑøYuoŞú»†>3ğwò•B(±V¢\³O´4¼ï‹Áªk²ç’±×ˆ£yüõIÕŠ£™R´„Œ’tO#ôË¶½ğß@€më|Ù_fJ oFa¹65KeÅS©rş;Â÷7hî	Ñù[–cäã€ “zVùßKŒ“`±·ì¸(|sócÔ¯HŠaº-%û–JÆ4áUl£Ò;ÄÙşùƒÜY‡HRûª"èÏ.EXFÁd˜C
éÎ»úE‹Å1­š‹¼#ùbg©jØÁ=Rn+Q'@:³&¹¢*Û¬§$ãà9	Og'wÒæM_ïœÉm_º¶k7•}ÈõC?êK"o™*İ7Õ!g¿ºégQ¶ÀøÆI¨$‘ÔË@6ƒX²SçË…7w+ñ‚\a|=Âµô·:’à!=»¿)ïïÈ°9¨°L{àm‚ùö{üdvı~ŠÆ3®ƒ6FaÄ„*Ìu”(TÕˆÛA--™xÂPáÍY¹ôU¡#³û_•‡¸^dûSGp–-Î/ŸÔ|"sç/¤ÎX¤İşdBt$¨ÀöÇµY©Ïy‡õ  )Ômˆ¥¿ÖáÊg¹æù	†1y‹½[ú¡€PûïéœG9Oç3G½Ø³#zl¶% ª“Ü“ÏşL¿ŸPê ©¬ÆïÙL}‡ä’ÁLAö4–¢}9Gø=şĞë±ˆPœíª8ùµ‹‡õÄv6]94M¶>ZMÍ™Yg1üÔD–àÕGı¯¾Xs«½zTÉ? ¦šµŸko"tÄ¹@¹ñVéšÖCğXä{è³cßrö»n÷zíüÇzGQ·Z{Í°í3LêAú¯F[L½?ù9&ÖûrizıÙC©vA×®Y1Ì½n‚?½ágËiº2Ä-„ˆè2êGğ=´ñGAß2 _œˆiW”èº¡]a¿»Ãä5*Ûõ¦èô~a÷\xªŸbdê…à÷Gè#´ù–Àä¨à˜Y6mûZóiq¤h™óØW õğ-Qî€s B¹9ÉÀ `‰$ÚË¾qí’~šğæáB¹¯²¬zhß!Bn)^ëš»è¡7K;ïçlì® Lİ©…÷”«ú2Æ*ûÉ,K‘D=4İgîTÂáljz¢
¢DŠÿ,M7­½N­!ck…›&rrÊŞphlj?–ÖFmd?É‰äŒ«
á—K<·y–{j÷£-PªE- Š?^±wÑp¥šÕ\ïÚ"uŒ@úõš.ßKV˜İŠÀ/Ğœ^ìÔIìwáÓ7/TTnóu¡}ÑÑêx$©0J9<Äÿii‚™zo´Ša­+X€#l{ Ô‡g8zŠ#û¨étb=&.5P¢H¿¿Ë€ë÷<%²o`/×GöœyÌÒ·|…™#™õ½TÌ!ÓÄ5ò¥Á}†Py¹‘†wŠ=jøÒ?sı‘î }:YÒ¬°m¸²“Æ8Ÿ¸ä-“˜
}Mï!ÅuI{ğMòá³ÅÍB¢ÿ··É=[Ôt\ÃWjïÿ;9ş
îñSsÀGfğâì3š
·b¿ûätyD±¥…§`ô{Ob\]Ğ›¬
ï^wWEŒéU'B™0l‚˜OƒÛ(Zk¦T\×3êÁÍx`Z£Çïom[¾vïñT’F<=¸4×†^:—é¢Š[ÖvI[ïBˆZG2 )ÉıI†q>æ'æ~³³¬€Öd,€¯Mk!–'‹À)ôuºòG”cmß}Ì¬œñ]c1.hÉzÓüÿ©½1%»MvA¹»…ÄË|äƒxg–­1Š4G*b<ğƒZÑ!Á4oÕá´¡VsöõUÊıbëmL‰®¥}D÷İ{#uI³hNp]Yêè²¯Ìæä
¼7v!¡“ÒÚ„i‚V–‚¶U¨ÖF&Ë4åL ­ú¹°;¨œö)$AaS’´¤Í”8y4‰Ëb@T ı…òHç±“e\-ùı¹	Mq¢³!İÛy¬'c4çÂşÜî?vÓÙÄŒ¿ ¡ûéø79óñ:¦Yİ`X®%Äxôš	–€¨£2EL¬ÄeÂãø“p•k*0a»Í9ZîG9òcx4ƒòë1MØ:ÒšéR‚m›uÆ¯)â‚~îòî2º:TÓ¥^øuvèH÷#\¿jaöã,Íì×Ğ”jîƒÃCá¡¤Çğçdêºo=º¹\:?	,Õpt1ğ­ÛÕ‚„;Ö}Ïàµ\Á@~¡vwCKG,È-šƒ-'Qbù\u€}(2Â5GåsèõBuår¸Éƒ†up®¾òPş8R`ó³1Åê3OzŠ«Jô…ğMäµJ¸æá[&6¯Ì³®ÆVòª×°ôÙ›‹ ëÑT›ØBu«†<7x”önÇ´Æ±îøŸÃŸµ„Ê«}@ù¤aã^âüFƒåPxyÏæÏ˜s•('Éœ0¡ı”ÑhÂÿGKâû¢‰rÆëÓ˜rÑØE9ğO¸÷t¬Qø»@ßÕ›Yã‡<™|}t÷G¹”¯éø}9hÓ0OFWKd‘ôıŒè¥À(Ôj6{ÕÿPMİÈ*=t²=¼¤ ÔÔ!¾*‡éŸ)¼p¯^¢RôT×…B*üşİ^ê¯]8²¸ÅK¿6òNM†åãF@NyƒJ²¯cßŞW¼£¾,óM,)>”“Í	Şİ2ïe;m¸µM––ˆH,änƒy.å¯$â]ô…õ×Á1bJ
„¿Á¬ÒyfùşÊXı~RœDcŸ·45SéÇ·A‘v„ñl2©ª51>“ş|á1Â‰M‘Gº4èK$£e¹ìX9,’3uÎúáş2€˜ XR‰Bä¢Ö[m`xB¥@V¯ÀDItw› `{¨ğ
)æã"ü®è†zzÙ¡ÔJ·T÷r¬¿~nÔ¥Ü¿Ù G9(©d‡†ugÙš:pèªù­‹\HãHQÌ3Ej”gƒ„Ä#Èeª0£3@Àfü+‹gÂŸÒa!ü|Œ\ŠFkg4G½£ÂSYÛâVbæ%6º;ì?5Ó+ùÀX;B©|F5|kÆ]BB§tëøs¨$ëŠùd _¿t)iNè‰ÿı;Ö_}XĞtñÄ”ğÓÜÁpè„ùÒ¼’²•T>ÍÁ¯Ô×øãA?/«C^›£"Š'XA«¶)Ø¼‚Ú¬mÁñ]àıì(å$dğÙ&–œeœä·y)ç]ï“®œğø¿â(âà¹;ƒx·H„øÕ©óÑ\^]0…eE-Ì¥ŒôBÕ’-®õ1$q!^ ±c¬ø›1~H9Ï¶j¾¾!Hä«ıvó9Iõ÷ôr›c©›³c0†¡ñ„¥BS"ı0EœşCÔ2ÅÑ!Æ&iI{)ÿW‚¹ÉìÚC| _Ò˜À::z<Kg3+ÀI•ü'Øi~ÂAµd¦-éš|ûlÖ?Y,Íô_ŒğÀ‰4“²ŒáÚ½Âb:¸?™õDØ.ÄC		¨S@Õ¢ |f<„ dŞ)èÂşU}NSÃÛŸ¨<9]Åæ³ÀÌ¶àĞª'=ê’ïÄ]ÑR;¾ºœbÎ0`yÓA@sAk*¢£ä{))‚sè_°&!UşÎÚÛå ‹šçŞXŠÜå„¶Q@¯¶ ƒõ¢bG´’ÇA‹Îx9lîiB
DqQ[Nh³«
Ù±0›àOSğ|¼÷f <rË©ûa£¸„t‰®uØV‰Ó™e ğo7¸B_æm¢_u§zwK<?l½U½½şÿ¶ªUnÜO`gCŒÎ”‡EÊé²#Ï×2Ô]@ÒŒM,­}t
¬‡Ä)}‘¼ÀÛ| “E?ygìˆèé‰(¸öçW…fóvG¼àb‚†mƒçœ"æRS@¼	d*Gº®KÖ5„ÕÑÙ@·JvYĞÕï÷™rÜÌ%Á\©SÚS_¯MôıÿÊÆùål$ÚUUK!*BÍ²føLNÖ…«qEØ‹†Õ¨?O^ÿŞâœ­Æ|S× 9*¤gy÷¤ÒNn}ğV6›¡ €aQu®nø$8İ%ÜÙz¤T4ÚØ(£ß\¼|UZ©Š…º¾åú“¦(~¤Î k­ÔGÆ°³Œk:@šñÛDÄåh‡ Ôˆæ”A¾0_‰˜m­µe\ÿd>¾s×lóŸŞş¥vè.B¦mõÃ¯6«“~=±´ª¶ô=óG±Ù^ï"@Ç‰èº•Èb|s¼öªiœ´²y«Eó^$Zfú4r_zğµÈñäT ¼aK2!U®cfó‰»Îvp96:=—±—j.á5Z¿óÄ¶î%şÃîTÙ\PFº,U‡<fFÆR±9TÌ'µœÓ¼Oô’óbôIã¸–|›¹¿S­+ĞZe‚½Ò¢Ş˜‡p¼yÊ_•ÉíÖ¿~êÓ‚tkP·ĞôÉ„‡ubäøoÍÔ0ÓsLÇœÛ‘wE½WX'v¶­VÀ|A%¨|½y)¹óôåÕğq¡ñ¾Ãl9U–^3b*™0Á q]–ŠÉ¬¢Ë>Y›qıC¨Âjéó¶jäÉ=f1ï+²K$1¤Rd
×PâŒ_t;œ´m¼ûú—º/ZŒ!FŸ)<'ÿÒI5Ærløçİü¬E‹9„æ¡û%ÍÔZë½¢"Apcâ¼:9ó¡<z¶mÕe«œ¨+MŸlİ½³„DhŸWIEZà%÷0ßklâMr³aFNÒ3İæ#8åš†ŞÇìÅàÓî¿Ş‡±ñ×%o0§ˆS”Õ ?O¨ÈÌW,‡Á}³&ìíqµ[‹öŞÒ£o
á!ÓÜ·3‡°; Bÿ°›Y9Ë­4’tz÷¿¡».H‹Ôş˜â…mw| tˆ)‹Aczƒ Ğ¥€ğyàúÍ±Ägû    YZ