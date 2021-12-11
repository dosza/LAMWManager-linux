#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1235800735"
MD5="b97af7cf6fcf2e2dcba71e59d03d3f63"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25220"
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
	echo Date of packaging: Sat Dec 11 00:19:23 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿbC] ¼}•À1Dd]‡Á›PætİDõ"ÚwíîÛaz›ÖÌ2û^‡[M–Eàw2¤M<àÍ>âIÌ†Åûé­,	¿*¤$¯Ø˜S 9ówõó’F³fûï ïğgpÆŸa<Ø¨uGÄĞ™b&-$>ä²hÆçı®FôüÔ„’´ˆŸNÈÅ²V"ñêNÓ¤ª3M0ñ‘G4ç´FŒûŸ1¦»°(k±¹"ÆíI:#g‘ìÔóNõ !h!ËüÕÂt7«•ÇQôS]bÜÃî¶İG?U‡=€¬w˜à÷4÷Á€%f—Ù[=~„fÕ[Ä¶ùŒ’t¿±ëş­PıÂ›Ö×ÜÇ×zW—Šö“=³=iªà^PQÉ‹@@×ˆi2r´ÚÌaŠ©„ ÎËVåëK•È¼ÿu¹\F’‡‚øæwQÏ•¡è”ÆK&_¨%CÉ¿vÀÊÀ˜§t¶CÙãI¢HÜLÆKHÅu3H
•šD°nQ8É±ÓJšl7"O‘P/£ô=£ÜW ù¹»ößtù’ŒœC©¢‚Èy’¨€m „¾Õ¼¢R?FÄÁ”ÜàäÓJ±Òzqcqº‚÷†=*8<çO^ÜÖ‘sœ¹Ú/:1İßËw¦=ÜĞêˆ,fìÊ¬[ó”Ôöe…’÷1Ş,UŒnUz`î¾Ì_³Ç®ë±4÷/n^ªÀh8
c`fŸÏÂ—á´?_QXÆtù?‚ÛUĞ³Ş¬<Ôßâ°ì¥ügÿ\wªÌÙxĞÜ
lA$œ_Æß·H‘$ƒõnî0šS‘ZqÅ‹Ãt3ÏL÷Ùh˜>Œy.#|©aS}úŸÛ˜±
H8uàxì‡V÷ÿÊ¦=}pò}MÆ÷cËğØ–µ¼Ç1°àw:P¬ M¨;µ€Áú|.Â‘|Š‰:Ÿ§@NõE+¤9dLhÆGÅEâºÇ›µğÚî#kV¯:DËÀşSúÓ$[k˜”d}–Pü¼¼NSğŞu£~TÇE2xv”¯¦hº›üÎ8ó.i>—ªønù&Â<3Ù%4)šeå*E*/&)|º9+,f¨NW<È„Rğ‡SÅâ?qÅmû"Æ¸U2ß3O+ø­ÒpU°à¯Á(öpşŠpVnIV„iÅ”‘…—„ÔÁ¶P4l»„~Ù½{Æò>ÛÖ_&¦FğSı^³2úëHş]QÂ"Ú'an^³Kl„:àçcĞ”püÉXÈÎ$—íQGì8l)“y)"nMú9ôJìß|ìæ_\î-¡Çö 3 ¿/€ÓÆ=%Ax–ş'h9áÚÂRğ,HZ75#'Ô{ZöaÔt½¹\Ã2ÿowE›¸›ãm–%éÁrh+¾å¦şA¦İô<Éd†\êJšù»vYó„?¼2‹C~ÿğŸZÀg‰ï
AÖm2ñ_Ï’!VÿÚ—¿“Æ?ÇZÒ'ú‚Ë‰°0ÅÒ"ï Ğ+½µ,òlm-Iöø?¯É€Õ×â¯Ÿôê…Và*ñ3ı¬“„…ğğß«D*_+‰ïd¯¥Õˆ×FÆ+Ÿ—òh8>±N¿d	q4¢eÁ«£AäÂøN­@¡	Ÿ<OQã\m(EøÜ´[,®èÜÛz”^Uh	³÷ÉˆÕNİ‹5àª(ÎnÔBŞ*íA‹ªcÎOPîEIûsI.k{	.Õ‚Æº©¤ ÷û%n…Ä,®uKiwØ][`Ö±WKú¾9*«ûÎ"SÌZ»Pnş¬U‘Tå-´ƒC¼÷ò´™ÆâûtEr[Ì[¬Vëä¯92‚ñEIú2a7×lªA=¦Ñ6RD9sÈLôö·¥ìĞ)8iR¥¸íe¥’UMƒ ×Ü»"pıDêÇéñƒd=o—ïê¿ÕsvÔa4Z§^úgàŠî§‹(÷Ûƒ¹¤e.¾Á#º£†õ0´'•|È›¨òœäçÿÃ¸ß¾;˜ö%»¯6EgŠÔø×ƒÎf0[âú¢ÄÅÙ‚vÖÒChÀğšH„,ŸŠî^û`ç4·häíĞÎ±ûÕ÷iá0Ñ8^E¹Q´qwÊL³Şú \ j—`¢Ã;%í$ûú«¥¡{÷Çm!Äà\Î[TÈ0‡µQÊ*fîhÊr>¥LÆ”‰w¶¥`ÀU˜Í(ÎÖaß±?^É[¡Ù¬NáÃÁòjŸÓhŒ“@ŞËS8~ŠÎ%ñ=™‡§¼2xµÜºåÍçf 5¢Üş¸&µ¥ˆÅàÖ§H<å¤æ@ê¬›ÿîÂ¾\*«Ù×ªqXtƒ‰<{•$ÿÓ¥ÈáöMN*‹•I/}1¶û ÉÔ€'åK4€µ²òbÅEüÕv1
(¹TßºuX	íå‰ûT¾¢İ>Q€#GXrTpnu›Ş
äÊÔ7šæszááÇÇWb'4‹SŒÌwÅ¼ÜĞ#$ÃäDÇ£ı 7ìgºx´3Ë1 
"¸8¡Œr´^ZĞ‰FÁ»ŒpB.$1EïNŸº97F· ÅS•Í –YÈ‡¥G‰ƒ¡jï[¢GÇ¹ÅÒÙZ7<=c5©Õc#›"ÜEå@¹ŠU6l”‰hP Üşvé¬}õšß1¿
ã™ÓM1]¼‚ÁË³Ä¿oÀãHG§[(QåL  Ñ3X€ì8!%Ô	¾Dœ“‚<ŞÕwÒ`Û7‰f1Ëb—\ë“V›,T\œ(üPä3úTíêhÉ,Joƒ;X9¯YQÆ~Ïø¨\jc¤]+¡„ÎŸÇ±‰Gh(ùzŒÅËi‰]€Ò¯wú¿¬4ç§r_I,¶úö¡…Ïv?Dµä¥ç(×‘nìíiî¢İ—×v	?İö ä>Èâ²CRÀ²í20¹Šìö‹œ*Åºî‡\˜[FôÃ™¾n™Œ¦Û(ã{EŞÚÉiàâ]àÀ’ajqD -tâd<²Ì±¹¨‹õ÷í“<¹«"›kåWS/ådïo=eÕ·¨œ
¤;7_ª£QúS>:Œ¦“+f*<ÀG‡¦Ø[}”Pò§9cà’ÅôÇÿƒcş^‹(™ ãÛbFúNŞê³så×ºÚóxzj±JøtÃ[oÀ¸…Şo‘ˆSËâÎ¹æÒ}A9ÌYÕ¶ÀhÖ…ŠâïlÕ‘ÇÂù-ù‡!ÖP äÜ"²P˜·1RÜd×êş:@ô=ß›–G	kìñ"Ìÿ @Û1 óÔo8ª]"<ˆ;¡òDdi€‡¹@d\ a_¡.fí+õçW'ªYâ”©ÀïîwIä8E3ö	gbá¼(èßbÊõ3¿êß, îz¾œQ·!nÔl@
İ¨	ƒSGtå1¥1›ùíQ¸›
NO„õ¨ã¬¸ñrg³ !«ŒsG¹ ™ªûß€Ğœà‰®­4}æX- ¦“){ò@1;İ7[=¾ŠÃ‰¸µ(b×Ù¶°™Õš-M§´uMœ­\ÄèXö‹ç™Ìö€Ø
!”5¤x=ì ¹?…ãĞ¹¿°ô„÷¦
_ÆÕ =ıyU3CÙN:‡xzoÕ4tŞ3VÎxö1‘lÍÓà¿*€ŠñE,ÀÉÖµ^~K
ã3KbQJ´»¿_`ĞGı\ñÛ&Áà5Áâ™pò
ÓõÀGö<£Nƒ‰ ıBg]é×È4’ÙLç@é¬§Øíœ?æÀ©S­‘·w±\zËˆçm·€%…â1<ß|RÒE4öÀÿ.f:O<!xD4GÜİ[«?óİ zôÚÍöuh/jË³ÿÑ‘ësöz~JpÕLàÁ&C?´Ëu¶¿4>{Ûï¬‰™Wxrosö§–m»L‘ôÇ>o^r8_Õàš÷eBóz5ŞĞ‚?{_âcQQ3—€85Z­ó
wáŸtL¹ñf*=¶hyšÕÁ*üp¸ë¤Œ{ÿ­ÏşùK÷"«×jCÏÜùŠ lÎX}R‚ŠUç*¼Øyè}8SV’°E; Q”÷ù½´+wÖåªµÛ–™Ş &Lv+yü;ìÒeâèÕ…È³G4µ~Ô÷—¬™•ÁƒØìÍoeÃ]º ¶X"àÓ¯5©éR9ï Ø½7x¾r¾ıgûötµ¤˜Šşåÿti£Fñã"Ü¥‰¤!uzq^óZ;Éô#ë°
¹®ÆBĞãò¬K¾ª9®j³¶Ew‚uÏ¢=\h;s¶î˜…½;Ï¹‡T3ıÍ%û­Š7E—àL-ŸìJôjıÓz†>;{0^qÃ ·”¡ı§gY—h3í?Jå/’ÙE÷ $ó–ƒÓ‰rLƒJ~’öÀAâäîQ€dª¬”¨öíÒ[È}{ã"İønÄfH²ïÈ‚¶Tö«%9Ü	ÈŒzÆ/áú=ìohm¯£"xÕûrä\ÎkdZıBvÊuŸÔÏ§BënÀ{n'àÃÃÖŠª'p€Qx”Jo¼³²Ê JØWu×êYº/	xºU¬”$ê§BÉ+~êºéø5S–lvA0U¼yV$²ÌL‹äHáåĞÔxlMê¬´ Ûb_åÜwÜïxÿø7ñÆ8iXKçŒC*ÁvN:u×-Õùb Ó9hç%ÌIºØã*‚DôƒnGyYÄq î'¿xB¬êõd0tpÛÍòDuÉ§©ÛP ìäÇ¸L¶QAõë<ÊªÂˆO½©\Ó oÑÜ™
¯1->Pš(AD© ø­E\'ó%§ÔBEa_^~&¿UõœQz^l^>G¤&³`€×$¾; Ât1knfqÿ¾ïD»PÇ4©¤ZJòÍl(­hh®—4Nhû¨hNÁhõ²Z$šÒKàr\ã/0ìßï_±şî	-káNŒê¿-£S½İü^GŸv"°ù´ó&şg)·óF‹ ôhÃ!¯¢¡GxØÖØŒ2æ—„BNèï„»CˆÙï¼ÎAÔpÒ¨Î†”êH’’…RÖ@uŒ©A …)(ßGg[R\TceÜµ”íp/ÒE÷1lêšašÄrı ôú´ö¿rÂÉİÙß¸‡@·w^lUÍV(Œ
×!<ZËjÛ¬Šw÷Jùxãµz¶©‡19,J¼YV5a½°LTîoô)g’°kœ„§ªq-­'i´Œ+jp´‰ùŠ¨ù]/6œÄòª¬˜^ RX:åÙó—BWÈõ%t8şmŠŠuß>ŞšˆPÚåDuÄRö7o¦Ån=;-_³½Á’”©'DïÓAõ+p9ìÜ…_’Òõ€+i²‰#4Rï4e-be=Uí`pL8ÎrÈ‚-Ã8(êA9›“yaSÁTnÂâ†:»yóÄjnmk5Ë3ˆ•Üí:<jA«€ ık’«Œ<©¼\F0™EC¶S5ÊÿŞ4…é^ÿñÎPF¨,èEÜ*Z·_!YôìI" ~zAìe@ë ^\wyjHè›|Ê7'Úù1[Q:y˜u~û=˜F=•(÷6t. êêJÕ­äX/t (_˜íî›æateı'DÅşt•QëğØŠÂĞX~»¯…[§™‹ÿğ“» ÈZ9ÚÍ* Ÿ•_Ê®zëÕJÏ0³µĞšJ\àhSZI(|£!Ó(c²K¯üg¬nœ‰G•óÂPö²;Î[õä„^tšhõ¬÷äƒm˜Çl¨‡/.ìÖ”°^(GNEéØŠªv”ëˆ*ÕrÑí2¬ôÉr…šÑ¥]Áõ¬¢É?÷rş‹S‚ù Dçóœ™æËB³/±Vş	X‡¿ú è7
ásö›_Š!b¥
‘Pv=”›ö&xmS‘t¡eT9Õ¤Û•Lëµó—ñx­Yë—Ğ8]¯Ú¹®VfÛÚ5-ºQŒ¸/»Uº¡8G-Ãz›š‰NòVu©æ¶´0¼§´7l;×nG¯)êà3¾–
É’9óùÛz©xù'õˆãk¥™ÿ2è/sg¦¹¥_2¸öß'Ş˜ßòkh'Neš»Í3@o˜‹	¢¿$SÃÕÎ‡/²NRt8u!|R¶.ÿÊÕ<´Àm­tbPµTÙFlËÌ¨/?è”qË†eğ5ğsALuÎå4UœÈ>:÷UP“gtó3Ë—úº(şí¼´}‘½eƒßi4õ_ÙåY§×-OûÓ#ªxâœg QIKKE„¯„äÇ´r5\S+_s8°~ÄK¬-ŞbŸCe@™Ñ–İŞâ¢„äğÊši=o0tÔÑD_jEå
sB>b³¢_%ŞôĞ±ÁLNğÌş};âÍWîİ §SïSP¿„ûºÔ	!ód¥Ë.°ı,íİ:ºš^Ämİ¸'ÃÙ¹â¤ñL?Åëùå€xßOà7HlŞ*}ó—ñxİÿN”×¯¯ê€°X>Zpow¥h-%©‡Å‘rrN0Ë[ˆÕ¢ñ2FD²'ï×sÓ&.N™dJÕ_0š´¾Ùª‚„©ú|Ø“‰ıD ¼ÿ¯Ç™è[Ã(›ùkØô½Æ3?Û–12PÃ'­$gÚÖ_qøáª–®?:	ò4nåd«-Œ~u5'oß¿¬lnRÒ_¡°Y@€,AÔç"â´…\áqE³ÙÅò¯Ùùö/y;(Ò‰bÿ:M–=NÓµïğ‘2Q¾S3!Aq+îIşÃš{sQ%ãÂ.¶ûàÈg‘+üõ³sÆ¢ğY¡*}¦àø9K®ÉIgTíš5û·ù–`(Å’üy0º,úP¦‰÷çéZeüãVj[h”$ÎúC%RfìTÓbÁ¶+ZyñãL¨§°`Q>jÛ(ÇÅ>ØC	dV·Pioe óQá«zYÍy/ø!%$ÄV8vjİ‹¦ÍtŸºâf³TI¶¯¬	ã×?9ãSØ=f–eƒgğ¢©jéØ‚íS\i‡z‰Jîz*SÍL	gÑ¾!ÃÉìßïxC½ pñolgñ£Èoın˜}g¬êá¸#Ã,.ÉÄ½ÖşêÕËò…ÚtÎCÛë+`kÆd‰p¦+B¼aG­ö4-`ç£¥RÀÓ5è´.N«MgŠSº‚ÃQûÄ<ğ2	Vôœ-êÍ‚Æ*¨”š©—ü‰ÆC´!ÇûÀ¶á¨óäò!r2’òée Ê²LÅwu§…ûØ±u2ÂÑÉŠÒÑKÑ÷Á}›xßÓddØa…ä*}€ÈÍ¿/0±t¦o!tÛ!å j²­VvMÔE‡Ù„HG‰Ä¡ò`˜;’’¿C+ÈB.A’áM2<2ïŒQ®èo6ï¹¨:©‹UD—¿›x=Ï&F™'îÚ'}âJŸ%"/Ş
ŒT­/–5NØ“6qìt*¬Èw$6Oø‡ûñß3Ü§Õ3Â‰ÜØÄ6ı”±Ä`~Ïäı’ëvß~€Ğ%²E=DÍ4qÿµe’ïÜ¼ˆĞ­µ7œò”fwyí¡¾‘g™½ùkøKP=²wD@¦QÓç›:Û"7tìM˜Gë%/°v^ù^¯…&
´ ¼=N¢ïÒ³üJ¸›ç-İ'Å»œ+0~:ÿˆÍIJ·v›–|
‡uÕÉ÷òtjcCÏcêâh«Cƒ6zwœJç÷¢Ø:§¸÷:[ènî|öR(<×`èÑyÛÑ°?™À•	ğKÆ°hÀ—‚J®i&x‹+4§23\mìõí©À€ç©Í²8pšN/=Õª%¸¤¼ü÷)UÛo«†b6²^)rm*)õôïá6nQ¶““)H¥!nü7‹2|5K~¸i)wQ½-}amÂ—©ÕuAO¨S
îÊëKLÿV'õ7ÛaªZ>ƒÇÏh†æŒĞ |®E5y÷ÿ<‚Uào‰£õîGCv{}÷ç ˆ0ÚQ(IÙÛİQñ‰Bkã6ÖXË†&ÊÚ;·o\‡ø)¤âö°Qºª‡§xmá«Wb<øeşº¥ƒ„‰a;yMo¹$¹E:Tşú·cĞ‡¨Ûå%‚æÕõËW‹*Ğá}_…p	†õiíÓ}ióù¬ƒG@6o“èùSÛ*—³©u•Ù2iãßä&ØŸ$ı^*¦ŸÜ}iOœ»¾ˆÖØûÙ±ßM`Fâ$	ç3W:Åw‹­b@a&Pk sMò”’¯½ŸÂrb†K|Lbó©¯•usáşç ]ŞÑŒ$»şeah	Œdß†xS³åÌDsEÀw'»Ÿ‡ …8…2 K®DŠÈ™ø@6ô›é<#ØdÎ6ÁN+I_høÜö¼g«ršÑ]DGğ1’@¶-0qıÂlç—½qì‡VÒÛ-¼E§P¬Îúh…ã[´Ğš¡f·¹Ô‡ƒnLmma¬±y9^½ÚM®ö*l§¹à¨™YRØlºRÆu³Èh˜_Ê³œ1ø_³ıàÅ+uÑ*’,eãÙ¤UÙÕ_™LÖù:j¢em[*i{Áşj°‹*ü°çä &b^c³åÇĞçÿæ8@;lbt+É{"º(<Ï—Ã \Î›³µ)èpP=:
éSc¼,½«ËŒz¬É¡ÓëA}dş{…œhH	["X©Ğ§_ò§Kcz«3æL.ù–¢ø7±Ç*Œ'	Ò©€yó­h†ËÊ²üˆGN…æÉö:õ÷Ùsmm:;:{Ö½ßâüÔ°ÈZtÔ)4®îñ Êæ@4ñäÊ=7];A¸ô_MäÁàPVÍ1K7}iˆ –f¡Û‰ß2Ñ3^¯WíÆR]a¡úIÊC)£HÜÀ$¥ 
ûÙ’¸¹¹Bf»]C°mFİ±YÀÅ,çÒ¤Ì:ÿGô'`-nUUõÉ¶ãl‚Q ÆãŞm—µVk7i2FG‹ˆ3\˜7æŒv„ŒM&RÖkE©»80	O(îo=1ïnı$0ãó;\fXCÁUWB-‹Í]}Ç|¬ĞwÍNìûPaf½~DŸ8ßXÏûÑİ&]{ÎUÑëÀĞÚ:•è'ü'^©Àÿ¸M«ÊW’ÌsÎ.fí2¬Á–¢]0pP¤z»#bÃF5ı>kR³gµÜ?ŞÂ>=w4Hª@ßæÚ™½D¡—o•Ib±?OªêÃØHJ.z†=ÓÓ‰Q¨‹ÿí¶ª;\Ì¿B¦eìR}\/–µ´Í	„é™_‚Ïu,'x_CûX™y[i´Ù#qQD—Ò9hèÙCäâj>º[~³~,İººKC­S±&¯!zÙøÅ»¿h=UÒP‰ S±(ßñ(SÕÛÿó-èï(¾á[ÚÉÓ‰_®V
™ªk+„ãAË¦+ÖÏİ“…ûL¹0x”‡Æ›"!Zç¡™ÆëóŞ;Çê$“r9u_PlG£]öÆŞ-€òø5yÍEw•?ÁøÔDŠPè&Bñ©ÀX¤Û¥åqyÀ³ù 	±'§D	=²#{Ã÷Åß‡ğ>ßSrÈ»n¦’]A:¥d”8œm@BAdhÒhR\ôåp„‹j‰!r%Ó#^ã›´¿Ë’«eÄõá)6ìšó¬'·5àAZ3}IkúîQ[WÚ„ˆN†0S…¨Ô¶]Ä<{í&f6I2Ôşè4ÅÅc*“—|€¾“Îé§kw’Zû7íß Äé{>œ ÈyÙÚx8RT¥…±è¦•¹°íï	æ‡WÕ~šù(4ìºgJÀ¡IĞEè!™‹&@/ë¸…ü_?—·všü™ñ"-rùñÂ•FıJÑÚŠf–˜ùHq4Ê{S„ ,Yš?cæ50GŸŒÈÃm˜¨&ñc‹?e«ŸsX#ÙN™<åãÑÎU3lwÊÒ«„fø½¬RuøÆáû¾h+¹Ì¼ÎüWŒ0S°EÂxÈå	[©¿Óü¡zÙÌk[u­q_ëR5¡ÛqqBßQ‘Æ!ÒdÜ0]<Ä
v.~À^N¦Û(IhäKÀ8Ci:7Œ¼x™Ë£|¨"ò®a%'9/ “g6*ô~	ªüàÄW±ª‰V{b«ØÆËŠ–‰ôRTiH°0²=8·ÊRÊ#=€M–u>İvŒÑ1=‚2«óUB»;!‹§hzX›bhâiH	ÿ¢cş§P²«È]£ÿÅe{Ê¶ªÆÜ3u¹ß)í³ lßúV7‹;/_WîÄkÌA[C}–äcÛÕÛ“§eO·L‚×ôk|°_ÈçÀlK¢¥q¬Ğd¡E7ĞfíŸJ­#U«ĞVçí"€Ug>¦"Îi¢Nèø<µAÎ3>“ä|ów¿‚q®v:)l(U?×T-|/1ÉÖ«{-§ŒGó2`vª\t¥0G‰H >ı‰Oêe(Tç¥ŞoÃ_òtÌnÖD Å“ ÕòHğB:ş|Ğ.àıW9 ½$Ÿ'ƒZW-,Vr®QëYL&N+&Aí­±töŸ²?çJ‚Çõøk¹Ó½³?9rëDN=ÀÌ¤¾ŞŸrüT®â¢É¡éüœç×{Êù({¢­Éi})w6¾I±I¿÷ë”±ê‘¾ÎDDÜ’ûeó"Á{oGß©æd«~I$Ö KP“Â(Ùf¡À±%SDÕ¥Eâ²púbï¹«@-MxN"’¸Àá(’™¢Õ‘qù8àHUO{•vR­Âuj)q_pú¿«Á6V¶u|Sæ©A³$o¨³‘’ş˜7ËËgÉ=ÇÍ_˜˜	€‹¢=9Z;eØqÃöñåFE÷[DYt
»À‘%ó3kxÇĞ?hxe˜ˆ®IÁB²°_I£:¼o¿÷Ã¶ú;û XìOD½ÄjU“E³¤YN«/Ï‰‘øª=ñ¾Ç«H¤çßúH)Ë±ÆzÆ	ºò®·Ù^ £òVô³5E”•<	?ìòÔŸ_2€™Vİ#BøÂO²şãèÀBEá4ÈApWÁ¼ã€h%"Ä^Z……ãOrí£U…Ñò¢¥;Ñ4PÎ~ßÛµ[ß>»Ÿúå¡Aü­—“˜Î=¯EÓ¼¦•wG‹¥Ë0x&­ş†È° ŸŞ‡ÒA3åsLüÊöŸ`ÆU*­yu£
#AH.~õ%¿¡íSªÌ'uğüğÃsÓs®ü×SãokÛ V†uÄ· ÷a²â!mn-Ìã©¤¸­êÀw×ö¼Õ˜5GV Ù×Æ>„3}ß* öùüÄöußpà§İq6ïB3ÜJ÷&>ú9}ß@¢Š• 6ı““)4‰€›Q…‡˜Ë?ühâ¦ıŞ£˜%Å®7ø.€¬ÂÂÖchs €ˆl<ËØŒó ,’Ê?Æ9âÕ»–Äh×ãwºjËa\…í«ÓEZ¡_ø?ÏTáìBúrÆeÁ½1sŞ©üYHãdûºhÓI§iáÖopIä{z }o-ù¾b#KµvŒt8©Ô]M®rOÑÿhm9NŠÌ‘z%û´¸yH·}Ã@$³şEßë ë€=^Ä]ŸË*	6K"—ê±2ï12™µº¾¼'@¼Í92c‚…İ†5š×ßİü±
¦óè¿YG71Ğ×­"ö5ÔÀµĞùjr]®·+°$JcJXD×5¤{4¿¿o¡%~ózÈIiK¦ÚáïçĞØuQ“‹l(.b 5OÙ¢êŸ!ƒ€odgyGŞÊJşÎ»ªÃ×LØ üo7t§şMhrgÕ–5ZZÒL[ğ™áê–­àŒ‚À‹lŒÊ.6Åk›‹8Úñ~ß{Ô+O-²¿‰r[YX³ŠÎ§h´¬è]yÅ‰âMf@öU!ºJ§-ƒõxÙ‚¼—`¨Òƒ·¾ 5åÇĞÅ Ÿ½"VÄ4¯¯ÂË9! 'ìF=”ù4T¦şé:uC‚¹É¼ŠÉ.G~:Ø]lĞgFêP¥ÒXT*HŸW¼—E“z+g˜™xhÄN{¨s±^$‚o6d(‹-‡rİ[—éaÍİÙ {¢Q%®ŠÅE2R`µcçlm%ewãV@Œ¼&dCDlÃÒ?-$Xº-¼B&½ èÆ÷ßk’^0ê@„¬Á;İk ƒAgæ1ç9÷îÄèÒl&óëëƒCkèkYIA]¤2hkË<f™\é [Â=w;2¦Š¡db,xY#uøh[Â+ÀÃoê˜ù‚O<%uÇä·ê¯† Yí5î8G:Öh'û~L'_=ó§’KF¡Ùæ 7g$äj`ÑâÍr×%5_tj#ı¿6‰–°xÔ)_6F>%F]rTn¹÷ˆ}n•ÏÀ¶¿ C‚oX8¢‘²¢=mĞ]ÏÿKhT¼˜)ÿrøÕ±ÕtÑôØ9¾aGÅæ%KVS ¦´_›z](1ĞÁ†ÉQ)ër’—c¿j¿KFT©ãux:·5¯^‰	¿WŒPòÉÿ×R (Á†š |Hg}–é‚EÀğ±İí24“
ÌeµIÃH—P—€_xz[«"ÂsïËŸ€ò–nZ÷lªzœ°,Á…4½ÒQ_=£d F'ŸE’ß ò8À½§‡k€¯‡Ä¡c„Å-õĞ8Ğoë	K¼˜v¨E&aU‘Úî4päveË-êÿ†‘Ö&É7-•e^Ğ¹3¡Bı¾ Ó`Sšt/ÌíÜ+ÍŠ•+1%Ãb<³Nıj5ÃfQ†ªŠ¶|É"¡­Pïÿ\ÁæÕ&vt2Ígª¯õHc$÷ºU½ÏÛ+]Jyì2B÷¡h§ßÑ€<ç‚œ!aûñóÍ|C=K9¯Üz K2èsşò†pGÔ!º-PÚô “6#Àt9Éq5%şƒ‹KJó8vI×í]S±OÃ?K¦»ÓÅ=)W…÷f¾öò€3&ú‘ Îğı1
@sÖàs›;úBfø`zÔ£¤ØVùc³tÛÊQ¹ó²àî¨*À²»&;uóêÕÌBõÎo	ˆ{Â…d30¯…	r]È çw¨vÀğô[ä×®üÃù™Él®7PL‚f[['ÚXM1Õ±s9æªš¿ a[Fã3CeÊ‘#«ÃhUÒd|òL™1\€­õ«É|‰B!0îÿ'ÛlXİ$Zcü1úqoø…Æ[08ÍÁ
áÚ,”º?{l?4×iÚu`’O<ôë#+ v1KÀ¦ò¹ÓË{ŠÃJC&'ù™Pü¨tJNÍ5+ê+âE)~f—JĞ«Z0÷lRGÙ ÷¦àÛôæß[·±™vXa•óL±aM524T"'¸‡ÕÖQœÄ|bÀ‡œl!s‚ÊpåÛ"ü‘"¥7ÁE‘ZF®LÎf§¾ƒH¾cœÊNû„ı@‡µa“€‡KøÈV…&=„"Y‹Ÿ$rCIW£Dùn›„zÖé/Ÿk@–ÊûEµ‘›¢a÷mº1è!‰–, ®„uÖ-`AçÄ#¯µNsrê¤p;û¹İ÷¢.¾ïä yî­çÏ4M3ûBË¹!â†¤ ¯LmA†2 csµ†N	ÃTbİMQ²43ˆ@Y«7ÛÙ\Œ“jcJ6WîO3ç	ÚÂä¢I6c{_àå]š<ç=È:²órN³ŒÍã-‘}\&o8(€_nœD›R}Ë ¤M<–Oúò>ı’%üÃ´öD‚œI0¿Z ¢š¤¸©¢¾§$ğpá<Å>ofÿº©Ò¿êîmÀ=XvxŸÌˆÖ z4™j%Èä¬¬¤^üòR-d9? —gş ÿ„Î]8gÉ"ìa„<B³5Gô?¹Ší
ßG‡şIøi¤“µö\öuä¢¢‹N)Ò‚¢¯&›kŒá7“‡<«Èin†¤»0çˆW/¬ X]'ÎÜğûã¶ìı25wÄºê§]ß„ÚŸî¡7”ÇÃíÄÌÃÙpİ&Ü¢ŒĞ]S\héÉlÅ†TEÌvš×Â
Ø?ICeÏrç+ù|—FR6#‡½ƒº¯/¾¼™÷«éZ"
¶¬„òm2›!J6é†ÈÑ:¯ÜÙlš fŠ*§ğn¡}ÊO„èô­	‚ŞÒTnÆ	ÇáÿüH§–ã–¤7¼åaKMŞq(æäü]@Õßùí™ÅJè“,)Œ®3 >²!0;óP‰êš§c*SîŸj£Ii†R¸u„Şd=T4oU%v\ûD\MM™|pÑÔÇØŒ[qm]uMÖ‰Z_1+w¹ÈT»ÛLèc±£^€ñ%¼ÌN÷G0¦Ó¨_ÜX9h(¾MX®ãHg¾³&ŒJ’°Æš‘ºù¦˜Š™à€}”Øü÷Ø“¢¸ísù¡B´áhH˜fÏÔÄGıı„aOrXøÏ//jĞ›¡Æ2#»Bg'†ô¢
Š$–[äUcŸ"œÎ\a¼¾Š{ï" äFZ£¢o©”kæƒÚ8×Â|ÿ34{‡®!_×Š{•¸ì´Hº7\cÖp¬;[VÑ^<Õ¾*X ê>^-¾#•nÏ¯/{¹Ş+Ó	î.Qß0Y’õ:@í¯uúÄl*©7¯³`‘¤=Ñsµv^UıÑ\É>û¿ä­Ò—‹ºæ­H–³Õ"»_CÔæ»û¹S{ë÷ûù˜~ÎØPSRŞ!¾
L;Ïç¼¤rµ*!mF“ó…”®Âøš±$Ç[V ê9r#ùsqAê$Ò!¿¯VìÔe£Ì¾;h‘‡-ü”T/™ÉWs3Qé¬ ü	ítåû/± ¾úØ¦îŞÖÆÙafÀ;Õ{eÁ§t‰ñÏÅ€÷ÃõG¶DDbl¤›–&Ø†¨`Dó™ë¿$ÜdÎÎs‹o´yÑ\­™lÂÜa4bìˆMáDŠg	ÉÄç´®Ø™‚ªÔùíÙéLÄ¯¨»ƒv)Wömú¾Æ¦tò©%Fq¶ng>¾àÜĞ¾¦?q¸LíWKyîG8€$FİpÎÙ}-)–ªVÃüÃÖ‚»ìşÇİ;ŠÚ4È¸š•»ÿ7”Oß¬rBŸ¨Ãkÿfİ‘ı9Òu‘¡›¿ —t²3ÉÅÈ!¸“•czg©Ië
8‰âï5ú›ù®j!€DåŸ™%ŸŸÒ—âïMÇ÷„0ı‚ö¿q¹´à¤ƒ6ö']ìŞ]mTo;+ˆ¨‡Oç/ígÉüöv‡+q€®UF®bŒ~±ıÒßòø5
 §Ç"Ë¡Ó
Ìy¸OÉépz0™¦‡á’}1Ğ
ÜŸPŞ¯0×‚¼`OÆ¹öÁEƒË¦Î6VÓ^[Êuñg*€ü_yfúòÀF½²7’©
”ùíLPHÒvÿ8Î{ê‡B¿®ˆ&&Iäş8Ê85àåI'£ÛĞÄ$$DUú•/º&<>-$uBÛ¢ñ¨¤w¼§ÀôÕô‘]›«\æ!5ŠÎØíA¡2YŒ4/èÇ°{Ú]}º‰»şT²B”´ğê9ğÕ zBo‹DøPØÆg‡z,£_eß9P~ ôèdÎ]«%"^ø¿I&4“ˆ-EÛñ6öéÊG•<Ã¥¸Ğœã½[Í@ËØõI#çNàZÉ¤ÆÏÜÀuU¦=´'İ¯İ¸ê^aql];8ëÑ`èÑ¯Ë’ö¢LXoûWo,+UÁË²tåTfwJé`çªMááÀ–‹Ö.Åô‹S"¬tmPåš‚¨ëXƒ+š®ò½¦£	!T`ärîŸà
pÀô1ZŞ¾Çá,n²K-‡"@#8ûÆiÕuù´¢9J£†î}§@àêÔ6ÎCaöF²÷ª¸™ë»ÔgÅ[(«ù_¬s£û£d;dŠê·`îÉÑ°~µ œL²´Ìªª£½¡¯9xQoÚˆs—UŸ»Aığ…‰JÿGi²ÿ—çIÊGz	êó‘JÜD7‚¼ò@Fã:Kß`×4¬»å¶vù‘¹x­-v£ƒó2p}~<…ZW)[EyØ,˜2xq±‹€c1JQ)½Ü,/fğŞå2í,•‘Ñ¼ğ!£zíuÖh¨f¿9>™ÁóÇÔ ROÄ¶ß2äŞµDŠP¬ÂıË¾±ª´Åe®kõ½¼–­È ÄÌkìÀÇrnA-'–¥[Ş¯)§îÆ˜¤ö$ğ“ÃÒÜé”myñ8ÕQËƒî§ƒü»TèV²˜:èÜhØhY©% ¦.0Ëß”ôìø SßœÕr=&şn€4[MçLBûv­¨b0ïúª«•ŞÂ{ºOw‚w^8Ğó4	ÁGrĞ?¼EôÖRbXïıd†Ø ³n_b—õ_vŒÊIU8ê@¹º–édg¾xbA÷êoA‰à{ãÎƒ\¬7¸£¾€Á±ñz´ByçÑƒç Ñ8Êæ³ûÁæPÉ]hdR9/ªø¯o}óËDøÉŒ,ÒMèÚ?
˜î‡¢xÕ¯*àq#Õí®/üƒa¨…f¸I~¾Õ†›îc‰C.ÅLvQ—q¾kzÓv2 Zşn@²lÿ¹elò¬9ø‰G2Éz¦ƒò>MäGùñÔ e•ÒüŸóij8€·MOš=wGÛ¶×†S¯İxQÌY`Şùr[Ã3›x&—âIÎµò¢ÂŞpKë{‡õÄÕõØm3½·gÅ.*Â4—T¡ó¯Nle\ò’ÅÖ,Ñ#4øMR•‡í)4ß‘Íûƒ¯-¾½"k¥ıGÚë—ÆMT#ˆ+\Å	ó¢
µËÑêhåÚ¯H%ô¥r…E£4vaäDØÿUtZ©¾fâeoĞğˆ‚ºNŠÑ¬qÕ´¬f[T[Íáb÷ä$ÎÈàœ!hV•~œš«èrƒ²‘B-%²ù£XªHøÔ»v; =üĞI{ğè!•&“Í
8Ûˆ~ÖjúŒŠ$´ŒQÿ{iÈPy…d-È5"VÒ`Ü_âdŸ_}ÅzµŸä1@fOà Ğ(<ùë~[>ÿ ò…šÇ3wRBíØş”Ü.šw)ñ­@'ãò$W®Á¦\]F¼ßÂFc‚,q‹fÿY’W"J„GºšÉO×è'"£2Ó= ûC‰ağÕXR2õ,²qğo½øŠ¼y1’ß9Øk›ÿà¯éš„JØãTg$¢WæÑÄ7l'ìš›ãŠšSc”v–¢JÚ"İr,~:úVÚâPåVÀÈàhÄÏaVVQæKßt¾¦az35`HÖÚa¢Zi€@Ø'IáéÎ{ÏÄƒ£µDÜ9€àBS
&€E6—Å±DûÛw¾WéÍ«õVNGà…$.¸ûï|3y‰i¤êƒŸL`—·BMèœÿ'áéL©Ëù 3TìêG$2ªŞAºFëáÏÜV'Ğz¦¥vqµ·*hFIÃ¸¢^(¢Í‘ d?+øb1¡KÒ¡¼~±=ßÆcğHÊ<•r| òZTy'›â!†;µ¤•¶â¤©6y_ª»d¯mìLÃPU×¥õØMˆÜèìkŸ½
¯×ÕËü»¬‹é¨JØem–bıZ¬ı%„@ï‡½¢Ä
ÌOo¼ÆÕzá`é4r¼Üg•qº8#ä%lŞ-½­CëIOÙZÉÿÌË2-Y*Ìía ‰$ Î¦bŞ¹5¿P&®44·,küº¬xùÒZöq<Õ`Y;Ê:÷$/çù?|¦àtp€é†]s>â5ÿ±R^Û{ÄfÇ]â3,ğ°xc
ºò}¹¬® ìÎœaïhA)Öl“3Ø½Â%’Ú)J¨Ô`hE~qÛ	íc¥TS„¸§qÃ®c¤F‹uÇÑ3ˆ°S"½¿p«y«.^D«Ìa”Ò\§|Â?)sbÉì½&IgugëMåH [‚›ª>ÛÉJÿ¨§:E$NJQu_üš^ÙH]jö°‡—QKN«Ô·m*#W0ª0ctœÁ425c9SA˜K±‚ª:ì­ı;wó2±(ğÌ³3p™`oU.ÇâşRBÏî[Çd¬#6ÔD
ÕM¬ÇÂhñè¸ö'½uƒçUIƒ+º¶‚€üM˜â _şxTuKxåê3_Ğ,ğï ğÁ¯à‚¶÷—èlG¬Èı‡Òv£Ä•·BÈ'šËõ¸C˜wìë\EğZeÌLÇ›W¼(Î¸+ŸRÇ¼¤£Ì!tÂŞX¯RïñÒ9Å¸“„Ï¦¼³@€Úº[“G°ºYD(7µÁ]<H*Ï.áÆãL ôoc).Ã{ÒL`QÂåÛ${î0
ÔrèyÚÚ;û½†l¹j-]8Ä/~´yŞÉÂÔğ_v°¯<qn1U´)x®å:x}ê¬<d¼Vq«ÿÙ0÷óSwyw¬Æå6A§ e$`'
¬ûÃ&õÄ’B5ş—ŒÌ™Äzkc	to9Vk4u§94m‘–ËÕ™ÀÈ'Š“:êpÌ©4,‹"\z}í<†¤t‡Ú÷¨¸¹guİQ‘QE«Š"Ú@r—¤ÅÛ~M>q¾Ğ‘Í­t„„,çX£×r
¹›Oå'ÓuÉËàìúå5µ£=;á1)üohİg$PÃ¦zñš¤ó¶'ãíSªœƒùLr m+×s]l€™G­»gŒû`œ÷É3h@¶Ä(¬	ÌPÉ)Íl‘™±°^’©2ÍÓæ#D¾ô›¡ãÈqÖëù+w³Œh´¢1 ¥OâHä’pl¼Cmù±ó²´u…,@Lq]ix«³*8AŸQ¸4=b"ò²}Iàş¥iÍ:Ÿäw‹²ÿ¯Vá_³Ò¶b§Aø)µm´†¼rd<ÚªİŒ‹+{^ÆÙñq®/¹°Ûâd‘­ÛÜ6ôïÂ‘ún^ÙëDc·'C|üj|ƒ¨ÎÃ\=ğ}é…¢E+"OùçûAïÖ±‹øº9ßƒş¾¾HtûbÔ+¾^ç£Ë’¥”¡¼m}_½€‘m†
ûQ%/øÁ›ÏIŸj êT‹Wˆ@›vÍÕpÿ”¾+0 Û¢d•0&·Tw ˜ï»ÂşRU%ZU#%C»ú¡…¨¥z¤š.è›ıY¶»Bgß¡$Éˆä[1 k Jq#S(hò¡·9*ãùwVCa»cR¼±,Íí°xh-ÖOWiÒU~¹q$×éà#{ÖMnĞmZq§Ëeòõ`õMô_jñŸ„ñ¾ê<lÁıP4‰8‡‹¥æ™ÔìÙß|K“¿Î`¸¹‚¼­/¾T‘÷jû2yEëÈqÈ°Må˜tä7<-ŠäÑNŒáøhCR¯/¦øÑ ™-/+¬ñbÆO+U€q”K¤ŸÔÁ*¬ËJn´i´œ1¹¤äBù
€X¦_gB>V>@¾;Ñ1ÆX»9$íÅŒ£kø¼œò]ÄÓE©•šdˆ¡G¬ri÷´Ë»tÃ¿&MÅz™ÔûänĞH¤¢Ÿ»`V¿Qü@b¬[^€¦ÇoÁ –ÅlcW3m­~«×ËÕîÌ’õ.pÀÚLØš˜5'LJŸ}fT­YiseQ¦@ïÛ°ßğº$±¨K¿ÓCi™«Kê™ooe©¦Œà¯PÇv-‚’Wò)İÄâœÿ8_}™ÖÃf‰%t3Ó@)zª†hPâ8Epl‚DbİÊÊ_]1ãz× #?Åfï,(0¬s¶{0²
š<ÇıEªÉ†Ê…2àå;»³µª°BŒÙ¦Á5Ğ¨H!‰XØZoEÚ$I&kz*påÕP>ÙrÏ ?=—ÏI
ye=£ö	xrnk_­bò1cİcâÈäúú8òÎTLY[¤Äz!¼ÄZp~îÁÚp‹ 1“ıÏ+°ïÈ<h7‰f®¡©s{ãã4sÛ¹ti„º©yhMÆ³?Ï•è.ÓÈRšœ`®Q.U˜¼ø9áöõN&óG¾!ª®,Èué¯îİÉ¦xıÌáE$ù·e:ïFf{ãÎ®CÈ­Ñùê&IëIPLÔóÏ˜[˜)VÆ/I[Ÿºî‘€Ÿ®îÜ©­Á¢R•…k³)ãSNÅ«™PV’ò&^êøø»ûöè±Ó±Îäûå¬Ü‡¼ùm/¡üÂ¤1hœÖï:âÕ-j]¶Ë'ÊT’%¤Êİ.Gfÿ-\ş¡¥´‰(9.zŠû&º®v…‚
>€#n*Ì‚§ÄÇ0äÀ˜U^ÑÔ-OCìsµ¦Hv—q"RGÂÔYE92º.„&;?¾Ö¤-ĞK"½Çî8’Lëù‹Ï@“™Ù”Dò{—¡AÎı-Adzs/Bú{.Ïõã¹4!£]¾¿x	_WwW y»¼$<¡9êè¡Ğ¿%,¸¡ıñ¤éh¡5ı×qı0ù0sñ­¯°vçõHægZšázêv  €öÿø‡õ
Ö¾»şPÑâJ&«´ì
_uaÑ7¯ÓÎæùB£#òÈK‚‰6"bq4àéfÇØÿ÷Oæôû¸±MŸ|dr[’øs(&üò—Öqg¯ÍÏå·Añì·0?è©xé“Ëæ_“õ¥­ïLZÔl¾–BÛtğ)Šô3ñRLö:‡x)<à
5İB:„ÒZV÷^J˜ñŞÈˆJûˆ5ƒ…Ğ-ô	ßëOÜuÁ¢µƒÍ'‚¥P†šÔ½İLZrdº[Yz±(z…±Iô‰Ûç]çr·åš¸z}!„zœ–;£Ç;ªû¨y¹>6PvÁ&¸òÚèg.|æ 'D §÷îé¥“ã¶õvÕ‘ß
¹T=Õî]EGøQR?û…ßÃñ]­úCBas›Qf‹v\VbÉ†:º˜ß,âº×vYù{ÇİÙYãEîÅ÷‹q7{½ÉÓ\-:ì ˜šñ~İÂ¼Z½**=7
'‚Ò_UÌ™‰X‡Ê1g-Ì6Ö7ò¬;œ/ ×Çi/<XU:èjéĞKAkµÙÍ³JêW¾‹ÛŸe®eÎ–ñgJS¯LiÉªÍõ:Y¾P%yà0¨·>ÑHêlj$ßïùB‘H]dÒÖ>5]qÀLPÓâg@²Lp3å‹ç;èh»ùË
"M2ÔWœÄ‰Éã”şqü·—Ğb+^¿ãw%]À#ÿ7®Š±©Í‘ò¤ğ\’°Ckm´£2½3/CY<¦šGÃ™Y(©œŞ6DH*Ú€àaTÚ­˜ö°h±dµô›ó•8H|âğ]4×EÆrÿ·Ÿ[æim—{rß g;¼½Äö;ÅmHmË\¸ç÷‘ì¥["$§Ä2ŒÒù=}§dX€E9ï
Ìİôz«;Ìò6!óÒŞ¢7Àt©SEAøx1:ÿLRm6…gín ôØİ®æ‘F”İ„bíIØıİLòøÇ¿i°* lyCı½ƒ¨œ•kg'ÖnUèú6õ¦@éfæÌšF¦d±Ñ-Ó•ØM…uµ252“HT.@	B»q•İş´ğl'îú"¾e}Ì³W%;«a·¡Ë…\g©á¡[»ÈïÑšfg½¾z]“ttg€Ö[jMëmqõ!½Pµ
Go„Ä,;üåñà0Ø*¸ˆâ—k6Ää2’S(SR²À|d°gàôiğÁşk1mjşŞ&K§Væ %¹j§IÆ|T‡b¥ !`ãz ÁÈX™¸‚™ıASú“‚åÕÕ?¤ô÷·ÖŞûµUjâIhNOÕ‰eşs\aY~Öù\˜™¾…h7®”jE`ÎÜ{›/àzwí
Ëğkíò&:²|èªûbÊNüôp©û6"|Û°
Ÿ@J&ÏÕ7â¾ÃõuBcnfš6£ùïŞz¹?0¢ûÆÄ&Á3ezh)”hûQğ¾m[:Øfi¥|…N+u:H~3Iò Ÿ°´Ù‰)®›ÂS ÃoïY?óºl™ÿçù3.XÕq+?úèNÇÄ»ÖŞÂ.5}‡ İcÂº3”—¹à°¹.>Èl¸ëxv‚¡«UuØcdO
Ø­¬ò('	[ó5ì
c7	¡ÔŞá˜È¦­bè;c~xNº1ªŒfá?Ux¹% Ã6¢±>Êä„lìÛTFäÚGi_ş‚Õæ±D«Ä-ôìÖ´rEãã$ZH9YÜ~ÌO-Ş„{–‡ÕOç+mò)ÛœĞóæqV5sĞ¦¹EUñìQ¬sk5w®/¹6*Eò¾Á°á@Ï¾.é	¶÷9¸”kÇdÚÓ´!ÏŞp3‰
üæ/pSËœñfæÇAˆ¾‚	ƒ|¼rííV‚.ñm×D’9'|™NIŒ9uny˜»ñm‘ìSPú™¤¡£Ìº~ŞæTRœ>œëˆ2ËÃ
ñ’Íg±Ö—vˆõ-ØYç'Ô8ç†9Ìî²d=Ó-Ã@Ü+6Î|xØŒŞaNÚ5‘>ğ~©¶lö+æéÒy˜CÊ"—k£@æä^	Õ½=òL§æö	Ã,–bn©ƒÛ!ê!Î( ¥g1R	X#ƒD™ì±h¬kdípDF5¶FÇÒuó­ssÎ_0uQ©©³£×+“¬1BUrÒvÌÎV<c>´yêe›%ï¾àt'Y»ôRP+y–9d”…õ2í9{éZ:(ãÒÁ%»Õ@7Í3‰;XtŒ®§Tº…A(KOåş”m Å1äMœ×Ş›pª‹=€)>Ã%z¤Ia×â*|ßm[›‡60ƒ)|÷ m;ëN–JoyM³Â¨îá3·`‡ÕÓyn72"D˜¿ÛgwØ#ı*ÑwQ$ÕîÏ¥G[Ï8áÆR-–l>n¯è	ş¬íQ­±n«'ˆ`£‰°#E•mRVÿG[y£<ş÷ B¥“õ2Áà}†$Â knéÕ‹H(ßƒà(7U½ah£·‰O™cM_ïóVIf_”œaW»Bıâø
è@
öØoÛcZ>æ †w’#ò¶ûINê¬;öàÈóì(Ä”"^nn’›/ «éÒbìÂmz¬AÎáCYšá4ë–¹É–tz—¿p^’^ÊOšÅ0QÓdæmg¿Ïo!	§šøûLMšû„\æzoú-¶µúŒøìàC…q·¶áÃ7ŸÜîz¤9e³ğÃ»„ˆÅÀØFÃ°ÊKÆM–Ò‡•ÓënyŠmÇË`‚>=‹Ï´­4ñÃa¨† ïäaæ‘q_ìwëEØ£Å¼ÇaÖ\ä}p\fá'\ö
ÅÁşLuTÄäv#¬¹5JCá9û0³vˆøÖi°ì7.&)°L¡Rñz®Ôô5oÔ>±ÁÕ«hÀ*ğôP#’ïé!MßËİ•ãÛ
×|¨ÄRn3<h!Ğút¤oŠqR=ş£UØõ¾ÆpÀâØ[2÷Tí®•Ûm¿]pÂ×¢ Îçà¦zä»6<¼é›_Ó4±™±iÀ?}Oö%Jsq›Ì$GµŒz`{I’]\3$	û'YğÊ%ğVì¶'ùúö‚ñOfH•j“Î­™]E¸G”“Já³q3Ã´½÷Ïå±@	$iûÄ]ê}xh”¸-Ùÿ?>Íî(zNÁ>2tûqY~»ÇóSÑ%ßDÉ‚GÈÚV.Ÿ
ª}9³¡Wğ(Ká@ê¨ãaÃiÔUó•a}ßTq‹şéelV æmÉ…¨ÌO_>àc¸Â¨MâÎÊI×£{çÒ=ı<‡”&Æ¢§E
D–'íoÅRnIâHcÑò-Û!€AêÜËæºXkĞĞÚl´dWöÅ"øÉf7õÖ*`Ò¾æøD	ÅñÁ~B•dv—|qÑöï<AÖ.46ë4”‚å,rĞÖˆW„·áÒİìêà•QØÈÃöB$à^³·ƒgLGK‚±Dòx¬ë¶"bÊ‚¸sï¹ßh‡ÄXÆËîÛÈQrƒ%grˆMÏ’!øìe\7M	e–œOú¡,c;Û;¯ĞDiÃ{–bQÇHšÙÈîïÃæRÁÁ¢b•:$%Ü3²­HŒZª£…y¥É™ ­Ò¼¼`ahŠC¿á¶g5õ)x
¶æÎ/t/å¤d@ä/û0üäÄ…ÊVŸl#y÷éw«’¦ò’Ü‰	Ñ§U"zËékî‡@Vñ~¼xÂï„ê/‡ äÅ‡äB¾D£“8Æb¼ôšyFş,Î7í‚ÙÖìûªJàIú¢ îùœ@1ö˜{¶ƒåµéøè; mÅš.
R*N'¬áàÜËyÁl˜]×İägG%f+â½0øëìrrª;wx×;«0p}z,Of.¤üÌs×‚È
\ßG#Ş†YäˆÏ×M=…6'ºF‚5|ú™E¾æ<¡ôÛğB%›{Làd
E
%pûnc¤’ºózÆë´èÅğª‰Åø’ÛÂÑL©º…g·†hÃtßÚ²gÍªØW÷ºgĞ{@ß;(šû‰ø’‹òQßè5ÄGıÊvÕ(5‡ˆ Ï	  J²ìèlÕÄs]¥j·ÊCT@…Á¯_=¤ñåˆ;2Y}H?7=Ì×Û#ûzhác˜´wA¾¾>«/º$‹b§z‘ÌöpqĞ^¶¸ßAUì¯ÆQ»¼¾ÂµVŸëIAÆ2ühXÎQY¿æËCéË½ÑXĞĞü.Qœ"+ş[™ß1HqÕøá%×VÉ¾+{Ê…TËCš¿×‘©ùêöírÑHXj}“(õİMıßqIt€ô½AæUâ^dmãhkÂaDBş,iôöŸP!ÏÏª(ÖºÚ‹N²²*+”Û£ÎT–ú“„+*²æS‰,˜@U’a¥nÇ)ó$]rÌqôÍtÊ¡†(‡)ÀL‹@?ØÀÙ§dÆØ|:ÒÊßÅQ•³ŞÁºäuÊDİ ïº+1*S¨¨"jº­ò0Qëyì“ašëúº p^2NÂ\Î•h‰¡ø¢†/îF+–ì+Æ¹‹4¨apÔš°wÒ%-rôÀ®geÙZ;7Öv¿€,ûÚÇ©TÂ­€öú0kÿ¿o¥7Ö3ËËïGQmá9Â¯1Æ&­tú“‘V‚Á,³)½®b=?>òÅ×Uvèåú±2La†a«ÊÈ×>Ïš‚Ü¡_™f=ƒ®'¦ì©‡Øˆdk³¨/Õ2 Ô-Ü·Şö=Nhm¦êáĞ.0	f„86ñ]øIÌô°Ù}¤(ÀŸû<Õ/ßUoã}˜aQ}fËó†¤¡VæŒrŞ±—<Î«÷B‹Hûœ·#í[cüÛş¸ôXf,àJÄFşE±’pŸØ&Ä`!Õßhg!¢ÙöËr÷ëæÔâU¢ŠyìÖÖñ	9…¡XTßz-İ¸J
¢MHi“sZ–T{l¯=e—Â ·ÂÌñø'Ü•7^JÜj.Ë»ÌÙÎu2ìšÒ «¢¬¹w›	ƒ¢İôsÙ§[÷ÚN
»}µÜ<¥ıÍ´µoQ‹xŠ>íï)?c@Æ[¦pîm„+šwåexäª–r9.Üdº>\£—gHU»¥ûs¾dS¡ çàœîı£]ôˆmğj-4Aæ0Çã^#§ø–€uly[éQ!<òx½™=1–6=vlA¼1äqs6z ÆOo‚ÜèşÒò1Ù ¢)^l>Î@ĞÓ¦õ+ÔŞœÿ']02[ËXıÛ›‹E[*}~êŸ¡æ…ûÒß²:¾ı
Fß1­qG`1ûş7g¸’Fœ,Xé‘T|ÛgC$i}Æ^zuòªà¥)Ôİ}—8ÇÅÿPÃae›ÌC²Ş\t_T‚l•ä=Y@í!€¨pĞu˜‚w&Îˆ”\[‘°á¹úXf0ßzÅŞ›ì7š;Á>”O—aD¬AÀnäÎ$¦
ˆìVR¦¤ò`-«Èˆƒ|­Ä‘ÿ0Õ¼˜fŠ¦©ê¼Tèß£æŞjr«“”ÁŒ×ó‘àôrÁ&Y2±iÂúnğğ‰ÆiÊw™ {³ÿ3[ƒ(u‘åçvÄ
#ƒÂ)i,Iel°ÕÒ#[¬í<d,4 v¶š I9!ºQH¬cXDµ@ş:QU¹’çNØä°­¼,™€¥Bk+wZ°ŠR^ç0ÿ¬*p[|‘˜‹jm(H£Â÷´¬È+<ZğB.ÎRç<Üo¹şP{ÿò¤
vyÔãˆ
<75˜Ÿºc*äÓ¢g“Úoºà¤rÓ=9‚.Ò¡§ßM ØÍ4nµ7i/EE ÈÂqÔ”lPeb9TA­€‰`N‹)z] Q¬u4|¢ù8ç­à÷¾·Ú;"EÛŞ$øÊ=Ø3Ç•‹PÂüpe¼,ç­âz/’çk	iu/‚ÌqQF1‰à$ÌšŒ*“"k{ä†^ªç$ït8´ÑYao~Úc)U÷ãÃ¹§¼hID®ÚÂÖlÑÈio¸JŸ·[lhÑ0¥)G$œüò¢ù¿¢ùu¯"¥yx“Æ99¤E¼kÔ•Ô^;ãnÓ3 ı&M­š—ŞòpßÁMOËğ…—p>œn¬P9™½_‘çá³‹˜h¿“‡Zßg¨T6ìq|Hî.ËãÖÏnhyß¾Ê«g•ñK½2 ¯i6Â+ŠÂîóG0ÍJ{ßq9º”ñ¹Á/…§æhd—”V½ò¦§Ú~SAğ£hŸ†¬³tÆ1òY!'ò¦g”kæƒŸíË¥¨{±o1¿~ß1öK†Éà¾å^cğÁîUPéèg=–Òix5wšÚuÍ8¨ñxRg|İ<D^ Ñ 
[êÆ8à¼”¨L½Dk —3 Eéøî˜T¯üòbÕNJI.9”.N¯ª	gùM‡”ÂEñõ k¦t²zXRúÌ:ÿ™ó ò/Ççå}Qòhe3Ù×¾eÓ}ò	©âÏÇğºC/£IÇK|"ö t:Ğ:…:!1¶"ÑtÈ_ÄjA%D7$÷òuš02‰—Z¨äÙ';Ìõ~~éŞPÃ;Òğ
ÛU©Ÿ‚Cdxg°{Ô’¹åN±*ÍîçÈiMi­Ç`cÖş„
ÉX*&ác_8@úòC<r&ºèšPŸú{Äã¬S.)›ê8'~õ.öè±¯¸<ïÀ›T€éC§V[Š7É¾-n1
Í:H¬`s"£˜ßø(nµ9ÃlŸü2ÊİÏòóÇ5jÀÃÎßÃ¸¸äĞ€æÈÚ²`pt,™d˜ãrß$¥j§5{h”¬;™ƒçc•®½u<l*×ùvI4¼ƒäyº€™õyÛ	ıg­°1]¬¡¦šb±ïDâí,6vNâ
$ûÕÖ&s»|F‚«Œ˜±`üo•x¯ÙaKbíW~±³šWõÍ„#¤.Y‚¬ìcmE"—gáéƒOÒÕ†‰XêG‡és6†æZ âŸªÈŞ4m­iJU°°ö–FAå<õ°Û~H%­B±d>SÒúcCPrÅ7¦ûDôAùb^r’—tƒõèMkŠ™"Ê7Çù!m^Pçóá&Mäj5ö\*™ Ghç¢O
X(ÕğHè[W#Ÿ7ìNÎaeÙSÀ3œªu;¯‡Ñš½ó]¾IWd*Tİhl›E·EÿÍã+•‰ÂÍLùSË/ª‚ö5¯X€Ú
æ—¦ø;M´KÕ¹×œGxZÆï÷ BS$ü¸j‰kˆx(ã´ÇÅùnb1Ş#GzáÒHd¨%ë†„øİ‚!˜ÔÁtQ„³w5~µgéN8u©lÜú”v…xèñ.f‹§î™21ŒÌ«å_C0‘ÊÍ1@¬e‰A§öºn‘¹f’¦mèÑ\ÚÅ¨Eì…œ-çèDŞ‹ï·3i¤Ts+BÛ„¾ãw¥Ç"Ğ0Òè)n½ß”å	q®@ı¢påbç-¥±VxvKZhdb«Øà×V¾ ñ¶¶¤bBt„fïÑ²·Ôüwå6±5¹ÂB@£ûğ¼ *Bp4PÁ{±ëô€”ä]O`­²ë²ÎE:CKß«HQ‹ î¨†d|‹aÆK±l&U6¼üXçh¢Œß#ç|ïWëdµéê®ƒçN·_ Dà”9è2ì è¤m†K€xÖ<§ZîNóCÄ˜Å<¥ârW–í
N*Ú¦À"»øt´ÇHO×Ï(¬¨…÷:ú{Âs´É&“Åõ‚kîÄ}–xuØp`!ß‹ı hÈÇww®‡Éq²ª7‚a–Ô‹p®L‹À‘°Ğ¶éÖõ[²Ú—Ò„á(*ãzÉ¥ÂXY—»+ŞVNÉ É©¬¥nA¤ö6±š¶şÕ> ’[Ú†¹ù¦gcÁ(Îƒz`Í…UpıiEŸÌA5X(Ûéäãij½úHnNJgÁ)koo]¯0¦$u†AZØ}%"[ ÷w!Ï^q}w@|ÔÔ³€å%´ÓçÍJ$TWzdl*eÒÃªfÍ?²t²¯_Rª¾sZN[S¶K^Ùÿ`Ï£«8ü÷u]É€#^ÕØVeíÿ0×ğ™Şú¢mHˆÉ,Ú-…È‰†—sÀJP#ÆÀ¸#æöAGà´ºiÉ8Õ\ÙúL¢ıÈ	İä‰Ï7°æ…RÁq“°Ş"T9ÿAı°„zñ"k@ş¢éÔå£5ìW¸ùB"mæ2Üİ0a01ØæY@QÇ€R‰TlF®kã'â§¨˜æÁzº;5,ˆ¦ŒüîL{cIñ.Å·U·`üQ;wİ“<8!œ åÆC¼³ª¶^Â
Ìıµ}Ùkü™‡¯%ÁÇĞ çª~u®`tŠöÛº &íËv®*lÒÓõ*˜FÍiL[Õ×Âõ•ŞI£å†©Â®±	SûL|Îf”—ŞÙ¦¢¦¹ËW)	<öúI£iÕbı£—o½Ú8Pœœ
â^äó–=ã¿/±8‚dkÙìgND@èÙPÒ>–ë=0éÕøÃÃ¬€üüêøJÏ½ÈøÓ!
„°Ä¢ÕÒô*P¯x;É ÎÇdÖŸv©H<š¶`©ª4[kÔ¬&¹MAr½àD¼ÕI¶±ÅésİpmÛ º»(9 ?%ØQNQd™vÜâ¹º'PdšäWpW¶=CfCyÁ–y>§ZqVRó–u úÿÁÛgC@÷	‰Ñ¨©õ1oBû“ïVğãá?œİ|-İã¡ñ¤Z²¦Üiiı²+&6õiôjå‹Û"Ë­\Ş÷•­€12ø1nªĞšØá¸Èü&I—E´ÚD8·çÓc¦F5„Ù•‡GM`áËánrÌ¬ÁUµ 
ôÅÈt±š9•nZøqÌªI„8İU±jş¬(ÁÇúáäö.Ö¥ZûäzLRmØ·ºNzämQïâØÜ0r÷Õ=[Ÿ£GÛ¯äÚxÔH[DUş9İƒˆf’ŒÆ­x¶FÓ¬ÆÎŸ‘9{ó-k.'9OÊ¢k¬Ù´ùu×ÄÜ¢k_“ß´2@Û[ğgb‡R¼ÌI4Rƒ
|;* L×Õ‡ôş±ÀMÃcÈ”×Ê ã*«t®—G(1$¯vğÄûè<¡ö4‚óI!ÒÁ_ìéS’¾>‚AÄNY€ST3p8`şĞ3ãËK$uz¦·Jóà§Ì}/é*~óõV2ÒCw£}lÛ˜“©:X„SàsOÙyª{AèW(g9åİôú£\ç`pÀ#ÀŞ›ê¶;ùR{fæä4GU>eÃ‹Ììc`}c¥¾Ù&}Ö¤5Æ#L…+Yñ	¢ŠŸÎ”ì™ò'…¿AÓ­ğy;Üèo¡Ü†A[6te6ª´–şÅ´œ o¼ã[ºç':ŠN÷²ñôQúôQLæÏFN1g/¨óùeÕ®2<ˆÜ7¢ã:'Lm˜>x‰KFC
çØÌ:i;B[ü¤ E
b`²¸1ì‘óæÔÙk[u¾ÆïÍRDœÛ–Og
<Jğ²²à„±Ğº3ÀÔÃR`˜	Áï˜A†ÏØ »4ø÷×!û¶TùÚÜw0!ÏXY‘·ï¯àOµHŠYq`àz(¶ÁqƒB¤÷eG•HPŸ\b“…Ûà{ı!P¥ò ıØºoâ|`i¡™´ÿñmªåtA6*F5üí¯cçÁşCğıÑšú#Nğ—™É»îÕ¬{é ù;–ÑãõËUqYà3¸bÊ!!MÎ`_‡° f´ı¥ú³ *ƒödñ†Èª¾óeH°‹µª­léÎĞ“”B½å­£	7µúÉRCEŸûÛTï3Rö¶—`¶G¤ı]„HÜË3Áî 6fcÆî´TrêS™|˜ŠÚ™Lº¥+;8 äµÔ1aMB])öàğ¹.ówó$õˆcI±, !HÍ AıTØÑä4’XÍ¿1U$šê Ä™×G¯!HŒ–şŸ¸¢›g|Aù¿RÆ~N§]ïMÌmMŒ:(#u6”CL[ëToù}¹¤ĞoŠ9î%ıÂ
pK¥Ã•¹ €4M€#×ürùızR­Ÿ…lôª‰íwÚ+ùŒsXy G…"¾[Ã¤kàvşa2Qeîà‚‚_8ÅÒ
VYî	B¬ò€@×f^ù¤yknÁÚNY¤nPŒ;'P™˜—já“Ë‡º¼¸7Oí‘"5"§éÁPO |ü*ë5!üt|ÏæÂ¾7,!÷ã!iäœ_;íÂDØåÔ“»;Àè:è¿|ËìCoû'kä–Ã.~‡¸fV˜XÂA‰6~-ŠÎCÜÚ	Åœ*•Àiës{úŠ«Mh
˜_ÿŞ”Á€’é7l.Ø#Ó^M¡T¾¼|¹•U“1=âê%<ø¦ãg¯˜ÿ&©ûdÛ',îvw·¼kœ6=—Ã„L òFb¢%W…§—#‘şJÕä=IÜ{ôöºK£šÍ<ÏÂ‘ÁÎ
Y#ÛörD*¹Œğ{•æ ‚*wGªàpÌ­+'Ø…$oòS¹×1¶c’ıÃh¸¥^ ºï)•£múÔcHd¥ˆŸdÀ±}çˆˆú‘ùıçyş¨íˆ¦;YT5rÈd§á«À‚/eETÉNK•Ší,æN½jüô°5J)‘a‚c`nåÌ¥ŞÑ¨¦ËèÌ9£)+'|IHÒµq¦Ôæı|ÁuF%Ø@«³jÓçõ€xÖª1S8>š­Óè9ˆˆ–r ®ı¾
.ôì¢q>‚ÙÆiÕ=˜ñ¶Íå·‰Çš5¡Yk~[Y‚Úç  ÓoI>Œë/cù´2ü>ê—ì1•şŸ)‹©è%h¿Âğ4*_ßNÎÉÚÆ˜1±T¥$yVÖEDÑuÑaşnéƒêÂ\úÌ¥2<¿gÀRé»P°aeìˆ´MjiÍP²vùMÅ­+¥Ú.¹ÕQ8[ÍÃšZğ’†8“"2ì?Ú8El2u^(ÇúÈŸt*_UC…Ëëx]7”;ëß³e.xmL@ )ïlÔÍ»ì®T(=Ïæ=…Œìu¢~Ÿz Nj¯­=êvÿ?CW1<‘´ í½ºJie(=+33ù9Àîå*K¿ºZp!Ba¢Î—çŸ«3‰\Ies9MÎJ—Æƒ$¦š#ˆT„Xè¼¯9ókÃ¤¢Z0³.=¡¬Üã= ßİÑzûö™€Hú»”ªK óãÕó‰²Q,ÌGƒVåsûeHOÑŞbM»Ÿy&¶ÊCàÃ!ü•ÏGlã~j@e|ëİM23Z,ûöB«c¿¢æ%‹Q>á¡IíZØÍ'.İ1æ™_»Z@?B¼â¨ÆZÅİ &“’	o÷üŠY8©½º[¬üR°-ú6@l«²:äº­:?÷-giÁ·ËıQH‡D+Œ¤l¡»“8w§{Ã¾°jóÅÂèŸòv¶ß_gPA±“z‘LôÕîœå ÷G;fØÎë"W—[ÿ\,Râ±Iˆ6g@”1…œË÷W–N+7Õx›ˆ&·Ô¤‡éÎÇ~"¢d°G-,ôpĞV·)Têtèwª ifg)àÅÕÏ%á­§GVm§—vï8Üœ7µƒö/*¨EAÀšGÑzá ®(`CbHÁìñiäèx.Š;Zì&ƒlÏN&L÷øö2¸Öx¨èËò‹U[ülûÕ@ùp÷Í¼3~¨HG•ï`ŸğX.À/Š‰21h	Ú¥?ykl,(¢6C”#	ª*°¹ˆ8­â
M »Q%‘)×tˆê'~ÓÌ_µn£ e|›F“WÃşuŒ
~¡¦»ºközL¡2¹_oƒjØl“ªCU´Ü&°ì6´‘5^ëuÃ£suûúöLXÉÉ’¬¾e­wäéäKØØ8…Ñ1bÓ/£åXÅx‚ÚFR—G&ë°dÏêÀaéËËÑşIGîYÕJxÑ-‰’ì¤$mGªë²™#G 	pş7¯>‚œÍ¬ËÎëXrÂÓ‰¦ÉÍ‰Ñ‚€sÜı»&×îT]t€s¾‹áaF kK'ü¼hìºz³´³£Æ$XÂÅ›5BêM¿»)«h×„¸½Şu¾YÏèç{ƒÑô@,(:ò@¬üëk>ÚÃ\>Ë8‰4=ì¥î/Æg^ë‡X–t±«yZp3ˆÍÃÍßÚ£ÁøPø¯SÛ>$¾Ğ5‡Š³<·GHğjåÚ¯IbÍRAæ™Ÿ¢>Ï~Ó#àŠõP6±Fª‚sÏw©Ø‚~ù”µŠ¨r*ëÌá¶²#é¥¶:#İ[ÀÉ˜p)¹§.mıp[A>­ĞF•éè•åLK¼áxÇœm«?°Y’pÈÈwzÀ$L¸»=-è6«Î›Ğé®'âÍ,íT@ÿĞK$ƒÆ]0:H7ZrëªŒœ*‘-æO±Ğ¬]†æıH:}¿ß¯]KK«¤sœ¾o”/Àüb½tÅ—“ø,K;ĞŸš ¤ºc)3ÖótBTì¦Áü6’Ì¡ëÊn¹ó¢4r   ùËôâ*„4 ßÄ€À4
¿0±Ägû    YZ