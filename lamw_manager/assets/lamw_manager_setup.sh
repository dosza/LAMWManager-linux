#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3628286903"
MD5="3500344965af508ed4ef6a032bf8b664"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23928"
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
	echo Date of packaging: Thu Sep 30 18:39:34 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]7] ¼}•À1Dd]‡Á›PætİDõ|‚$[E†EÁsÛ¤±lÓUúr•×o6·{³ëø­êÈ›Ô\£Èú½%ò·£çèJ¨Øjpñªd¥r	Ïrš6ŞkAşÊãIqØ*aŞwò¼'R­Ã5É&ä´ÍøİT
‹oY]?ì’º3à“RÒø3‰¶C·[Ùl.¯ÙšåĞø°–ú;ù¦ÊáLË¬±Ÿ“0u–ø 0QÚœâ5˜¿›ıC—òÃÆE$7ğLEİ±nÅì€2Ä|*Ué¿&T—ó~Œ’œ‡vu?«µ\óë³yÑ\tò¦`LjR?H1&±bØ$åLïgÎ5·ÿ˜æ¨yˆµÏçĞhA4–º«»•Ñeí6´ümcA!¨n7!ˆ%4=S¶jh¥¦Ó’µá»­³©¾“X×‹x`F¥>üi´Š]Y€#ªÀ‚CJÔÙw€‹Û‡YRöxdj)w¯Áejr¥uc”(”=? sË"mÁ¯ışíÍg]µ|”sD±(±Ÿ»®OÆÂ«C—(îçn‡ŠüóÜW]¢xxû6Z'5ù¾*2Ê¨*=ßÈwH:õ'Ñ;;ŠÅäŸìÅ9æKÜ€sÖLIğ*ê[¸Tq¬vØÖÇöíÈU7p”MÓ~}ŞÇ!±>%§-w±ôÔ>?n!¡SàIä/ò—R.x*ú#³(RÏDtÀpNU^xÎˆNc*Í;pĞ™‚–e¬Ô O /‹œå@èG5»–¥CÑWÑÇ|°[;tu†`èaLµ´Uñá\vj'Ì»æ‘˜‰¯µ*Ğ<W~§ªåÓ2	opA`æ¤1Œç&AÕtIW3h¬fÙùç»Ö÷º¤Ìd!òi<˜TÌŸ«ò~#ğBg¡cÃç01kQçp&ÀŒƒ;ØK¢†ÚÛx+´Á·¬_V>¡ªŸªÎzó9mm2ïRŠˆm×íá$A\Éƒ4he,™piâ1íó¡Æ2òZ¿ØÇ¡#!¹~ŠKNŠrhàoôşË{ÂØì±öjH¬…o¼&ÅtWGQv,‰|H.—}/©B2¬Ûı­ö'+€5¹—åÏ¢'ò³—äSm–øÁRŠ7bzcñåX2”.çs¶WÂZÆÿ€ÍÓª¶‹3{}IgÁhF ç¨÷¡	ğ)ÒVÏ7[óHtw_ûX‰XÊÿ)w7‡1ÎÔÖ†Ï‘îq(Œºêç™ƒë¹a_ä«şU™k	’x{­§ÿª½R î(u#”j!^¦ï/”‡Æ©ğŠäu0Tİó}Ñ‹<dÙ?Vã£Cvg‡iFkl,c-2’Ó›°ÒHLÀhs½:	(Úäé» ^È,~Lw‰nÚ™sşb‡O§ÃûírıC‡ß~9ß~Ğ9dàX?œKà&Cïñ›ŸÎÖ.\æí6ôe_O(½Ó{ç]8>èxƒ¥ÄL|ÿLòg7pSZ¾±§ÿHnÛã–„)¯U!368\İ¯2®½·2Ë á•§ÂœDÀ|Óõır<w3¸sÔAÛ
ĞÆçVò³ÖâÔĞÃ$-$¹¶ÍûV8<B1óˆZ4ºB+õÎ¹{mel§\ñ&pdêëÜ‚z®Bxdï[J8Jv`¥ú
ÈOnÚînIÑÛi^,ßÄè#P4¸˜^–©¹ØG·Ç9œÛ¸P‡/ĞVvÁë¼Ã§ &¨‡9#Ë,ÒŞfär æ¨"DŠÀOÉı,Ö{^çYÉ·k¨Õ»è±òğšF€¾:=fnpyO´EsÁ/›î£§ôC¬Lù-Li-³ìD?–>÷Iñ÷rœÛYøOi¿Fy1–
Ó×÷M Õ4yQ“äÅ=–š“Ô®óìµíD%y7Ã…ÉéD6–|yö%˜“àVuM‡s7]¦xiNq²E­ÓÔÊŸqrõãq™ğ¿÷ÔÔ®TÂÄƒm÷B­c)ºøhƒ5½š1İãşdy@U~‰ÙJQ¨òş7Ò
›ãµ¢©_´´)Œ®ÙŞÀ²±éˆ¾Õ8 Zß¦g~`»qÑmR]€…‡¡nÂç>_ššíkÀ®gÈ$²8o¾ç‡¸nX|I¢"çì:äİãs>x‹m|®î,i-µ
ñò²Ò5W@-…ûâƒ².êÿ¹ÏqÓÎßÆw‰^½—"l¼}Ôeùê¤zJ ñ/.;²*£Ü3ìÍ\œÚnú©àQaØÉ:×(Z
û~Ù¸#¡·s¾K^øÇ²à
¦„{cÛ O~]A=9ş3ñğÚ	Ç1P 0wÃK­û‚˜cS ït˜Ô
7ñÒrŒ¯‘ûÌÆ¹;ˆjUåƒïH•nkSçë
^8§8nqÚ5½º­+•u+äè`Y©ê«!¢À˜ô¤#Ïú\Wí¯¡Z¢«|OÆB›©€¼œŸ7Ûá‹İHväñ·üe¶âz${aàmJ®z£šÕP‚9\õ€UóÙÛú&±2ºTº7Ù®Ní›[àÆE
üí»Ó•—€Næ`L7søVÒ>ÎcË5Ã‚ÍÅ-ÁŞ"è?©«û.©ş8¿ îccèSxl%ã/{²hE} Döˆ¡DErE}‡òkÃ\,šƒ¹bïGÅ@Ï[<(Z““Áy7F„¯%sÔÅªb‹.˜ÃÑî‹š45¢6Wù'©ŠËZ^0#{zånˆ î2§İb§C£PŠpÍØeíd)¼T«‹²hÎó˜&TèûO8Ô£ğÒ˜Ğ¹"|›sÑÔ›‰;_Ÿ„âG%:Y*@ÅWÄ­åq§Ê’bÃ<O—¥åz÷ÙÎ4“Ä´lL€‡ˆm²xÙ;s|C¥¯Êü*§, üY4«ák#LÕq…ì‹Şf”ğ8‡1­xÑ‡^Ç·˜ú—.[)zöX¾­>‹grĞ}!hfán÷ ƒTĞÅ*“MFQÙ…ÔĞ•7–ú‘!”¸±b¯ºEL¼ePåyä|ªExØİT1+§WG°¸ E»Ó `m¦=*”~ªÀü¤Tô²,°öOK»ïZyeı7Ò‘‡œÊË ‹İ(9È‘=üŒR¿€…¨ôBbëiÿ|æ½Øé	ı‚—Ê$gaÚ wOzEa-âşm"‘éî™zÁ-U]4Ñ ¾ÿšóbÃrx1¢OT"$ePé+¾A¤ç·ñÙ”`ÓQ¿7ÂˆF„yìíecM—6½Û­øG¼³‘Q¥ùrçlR¾ÑKûp*Å&åÆh	½ŸSqû{¸)1ôíÀÄ×=9Ãaã…§ÿ_Èh€|0M%§(ìØ$3"³é]ìƒ	›d²~ÛmËü­½Ê?Úsş£i:¾6¦wi›´4²–uAIÜšJøÂB@cğSmµÕÜ9sMö»6c›ø>49ñÁfJ‹h°Ö8bN·£ÿ¿I•ƒ[x‰"@3ŒÖŒ ÃAÔh¨ßÊgÎ˜Şc.˜è.a…™ŞycÒĞŠÏpc®å™°kbÓ#f¦#+Zİ³Çw4SËuA\›1ÿq>‹E]Ö|dÇZ óÅ$yÉÒ>trîIOÒÛ`‡?íÈİépº2ß}$Ûˆø3Á¤Xß &›\¾Şt°Ò°†Æ‹K¸mIÃƒÛ³*e°Ìéğ¶!CTù{DoI¾-ä€¥p6£B˜3„¹İúµ¡Àşi˜‡BT#øSÏŠ, CûD)Ÿ)íáa.b[e<Ÿw,ô¸éEI:F¶NÚ»SãS¢ÁU7=ë*.©h% /¾„‹NÏ-¦èFy ú}5šy04›ÀÊQæ³;S[`óËn~çBôœdiKc*#îòïIİ?bñŞeLn²ÿ‡j=ò'YjQ£UˆöŞ(o:OŒ`™ĞSãm#±‚%@ÈKÂÔjHÙãÓğ‚æêæææjà½±©œ-—á±o &c’ò·	ûïB|d4GÈêbìim[vCşd%ùşeäUû&åÏÃ¨‘;]=Ş¿óÛ*yÚ˜ÛA%Fìy¹8­N¹¼”Ï²çúfŒ¦/ÅÄŞÉÛ¸^ pÒáåûÈ³½¯#ñÕ¢¡Ë{µ–‰P&¯@²=JÜp•P’	|›zª¹4ı([9±Œ	HÆ.fF2‡ÓÒ‘À–kÑîp%Ü­3NOV´>0ü*àˆÓrKjX}6ÖÖ¬Õå×Ù5ë.¦ 9A4
*STÀ±ZŸîÃ‘¼<W'ÊU7îŒÊw+ò¾ õ¥|'D¹±¶õH¥¿”qmÔCrj:ƒKë	Ø~M[¬Ï«€Äô*VwÆŞ—AX.#mÜ4¶_gg%»×è›ÇŠr™CŸ…4Æ!„{Õìƒ¯½[;~_(Ú4‹ğ˜!óÄÆ][Ù*^h oj{^>ãn)½Ú«u3íû>i>«H·‘LìÛçyBÅ~(y&çr^WƒÄ¼&úcu1SdêÈÉÖ¥÷Zå+*{ÏÖÅ†‘µ=0¶Ã¬&Çiğ½›èyöÀ’KydUÈ¹ë}@
Æ¼_Ñ”§j*Öæ€¥ŠÛØ‡¯W}‘¤ŞÖ¡ŒÏïº} 5’®³½^ıãY¤­	²Ü¦½dîTH¿Š~ãpL4LWÍ%Øğ{BÏ¢‚¯—¦í³¢ã
äD|È³Ç„ÕÛ–?©<R/ÒL²y",åuÕŒÆ=ÍNç×ÒBoå€û3j(rP€$‘7ßj1¾ÛúÓ	€ÁHv¥×‡¡)Õ€ûTĞ¸¨äãË£FÄu¶~‹"¢O«@Kø‡ƒv^GºÊQ¦:J•Gb)øÔ1
¨É³ä¥btÄÏâÓ+ìKzæh>j\ü!Ê×R"dÏ·™æL£ª ÁM/l³[Ù”o%EÙf@‰‘”éªeÄº/h(R&xéNÑ”»gàğ•‡GJ%ƒ8ê´9­æİIWıXŒ{ØtMü´z€ô|]}ÔÄ>^K£×1Abÿ]Ä;ÅxTQ¤gµXºŠtXmŒî °¤ócË™š©Ê‡	¿=Â'{	%†ujó€Ô0N4&Sj¹Ñ¸rä¤‰m#Ÿ|ùÖFz&ùÌá¦7"œ@éŠÇEú@Œûi¨’‰¦ü×;‰igµhñ4šğàáoR9ªí™—€I˜À‹?<…e ¢›§æø^Î%'/wÓyÅ)ˆ(ÄP€[Téâ€||]–‰x‘Em(*Pšjí|Dç7¬ıS_0=é×İ¢y(H}y”E	¦WÔ5oD¥ßõ+Âì…v&8õ9y,>Ğ2¥!³”m9Üf€€•¹¿{=˜ÿ§¢¹™õ\Œî@¹Ÿa
òµaÏ3ŞC”F¾İkD…p($2&èèÿú–'Dİ¦Ø[‰^ÑêAÁ>93 Â®%½ Î7Ò‘…q‰´½”‹÷å£]uÄV¹tWkÈä0:§2yzFà_s @Æp²½}˜¸qĞ3xÈreøí°¢Õédş½üvÅHïä"ä _{ëÇ.ÆKÈ.¼¹=4ñYôMû6ŸëyüDe¶İˆêz½,Á¶H¦è Vğ!60×j&Ÿî,Õ}ç)¡Jû4Tuxt·xŞ–\w¢ö˜¹ÅÛMkÛá5üPH Â_û«'t¡¿Ù<†™Ï§Tmf[1ÚäQ>ı¼ÅÇr	{¨sáÎê´Dş0îFy)§‹ª=çù¸ã0ƒæš›H”À¢ŸşC@ÓbÚÜ¹÷\x´Xz
óÉğ>YÀ®6+Ñnô<PZ×L(­Ù1îø,0•k5§Š Yl·¶(ËHß©C½‹İ3¶’Çı+=†á8Õ¶-H{Aõÿ=Ü[ÚÔY^Üuô¨Ñ™bNí€‰Ì^QF§À|höëÈGùttå½ì6—,±“!QûîöµûLIø>4c….)O¶ñgœôè¤h-S sMqç Â4"ù‰ñ²b®R™±Siâñ÷ÓÀ1s•¢˜†,¡[0DpA03ZEòŸ§â›ïÔıy«?åÉ®2‰EÊ?`Î2GYråÈ¤Ñ‘lûóY¯İü×‹|Éìİ´U
Á_é”>;ÙfdA"SKÊiğw‡8ƒßÃõ¾…ÌƒMWÂ8	ßnŠ€âøaá­SC`Zİ×äùá¯Iå¬É¨Y–©c³¤éO\§[T'à:¸ÓÒ_ßTNâŸôòùËa¼_-$øÎĞÙ³kÊ}‹ÉŸ‡üxËÌÕ+§3.!6µI¢Ş<Ø7$Bò\ü©×)ô}MÿÓ}Úİ‹âã^ÉlÄÄ˜gÅú8ÁÜn·¸³Qm+j'ÑÛM¨;çU2ÙMê9ñiWÛ¢ä–”8¼èïåØªÖgcRP¾‹!‰§è¯òZUŠ©Óä8›_æª!@¨yÜ«³Ğµ?Ê)D>É‰I¶W©¶tM~Ïè<¥é´cÀŞ~¶|3!ã³º€Â¹÷Jº­F2¤âêš¯]rêEÓN‰õø“×p¿ÔsÀ"«Lç}|ÔĞä…£‰íH>4O‡úlÃ£•	½Rê`¼™øÄKMDZds-NLH}¦Kó,bDvËê2÷N^âú)çO]Ü'h‰Õ2íºâ}>ùuÍıˆ¤ßÏÛ‹³ÑFl
`ó§y´jSĞ·‚ŠöSª§qzÌ5b‹Lºü|Í=ö|Jİß-v"ƒ©§–"œ?÷8=)Çû’·#JW•€cqÿô{ÿîuºl&SÍÓWk´„ì4S|áMQYÀ¯ª¼»Eü“Ã¦ MÎ!ÖzâŞ1hH)à6R¢îÌAD=%wï·­31©¤õ~¥+9}®Ï}y7Z*}\˜(€÷r=ñ?±&-Öw˜¾Ü£Or^ïşQ¥ıâ4hù—–’1±¼•Øş[€ËT®É¨ı…öÂŸ›À3íğ‘­We8P	òA'é5æF'~L^ñŞò°¹ºX…R^±• LAãª2Ò£ë÷‚ÇùqèÃ€Û’×f•ù`ıYğ­Â
.2&æ"Ä_“rîÓ İéêÂ—àl‰„Pc!ä6m?>Ã¬œò9ô„ñB
Év}Š‰ÖŒˆä£Ám{gêQèùf°ÆjrÛlª×N},Ú‘ƒ"uäU™ş`LjáT’<l¿ÜŠÑĞ¸ïåµD$ /ñ
	«$ĞÎô>¯QR—Å}iìC®XŠïÈ_ªªÇ@¬ÉÏp™aÆï•}O7qZ›÷:	¤x§5ÈæzCã$ÉfÀ‡†Y|$
^”¿o‰£Û¡7«=¦]˜öS}k;™rmÄ>Ã"ßq¹6f2Ó˜A.Â94f*?	r6_È„¹‘İkYª»Ã¥ÂºgsiæG±~¹«HµZ?ã­4`½·ç«	…|S²¥.ê¦ÌæÓÄdkåĞQ©UuşëkšöVz=
<Äoi—ßneŠ«ƒš<Êà&çûœÎìîÛI[öNøB÷ÍÏêuüÄò†'*ñû¶¨ŞD¸Ê$Ój\Èİ âpzÒ”S¨wIÁ è(x¹“(¡,Rfû2¯®Ü8hRjA‡¸'pÊ¬D±bF“J«U¢£ò!À®È^IF.h•ˆÏ¹(Å¶ÿIÛşø£^ºÖıMÓ˜ªõšß÷s7VÆ†/ÛlÃ¶+‹KêÙ‡Ù4&
¤ S7?íÀ2€ÿ>÷lß_%#Ïh¿šWÙ±²	¸ÑêÄödİùÜ4|vWRp},ŸíßùxÌ×ê×@.|¦~r!zd_ä…ã¸D8u :”6¬¿3@coŸÔ(;ÏlÃ¼G
Å¸£ô¬-ªï"ó 6f˜îâìnr¯XV3‹ğ·¢ûtûKêx·¶Hh¨'ú­º*Ær„İ¨ŠVâÍÛ#^ƒîJÂ™2Ùê+…Edá
=t`šİıGêÕ‹ø'3áX1ªcdA¹GÒ3ßºš zË#çÒacHšF_ü…éLòËİÎ¥MŸ?˜“q¼H§ÂíŞ&âõËRoÿ¡[=1*Œı6ö]ÿ±û›¢Y!Oì0ı§i~°"DC»ø¢ÁWNr;¦wjø†]SWÏ™ƒb–ænB¤ˆw]1ô!w+VgÊ#MPu‘â•nYšñ¼ª‰¦EkÛ§ºY´o7eq>]ø~è)ğÊf¿P’8ó×ZÿŒì{íĞc™¦ _Ë¤İæà^Ÿeü°Ğ-‘uw¹½ |ô­H€K’!àK.Fb¹S³Ë‘4Ø<…ÕcXáG‰Ë(O„º*=4·0š™yHAÖé…jÏBz^]·Lß‚
&ƒºÉekßnÚA^æEÀl:aLËøQ©¤¨Ç6ƒœhÃ¥o_¼2éL®Nq¯r;â#ˆeIJ,”VÓ¾Ù(âü$Hş³ÿ‹Úãæ]úqcÏ±h¹(àíŸÕA—7ú5º3rô#÷%†š-¼»ó] Ä‘2ŞŸC)Œñ°>X¬VZÖ?ÀQnGõ©YŒÒ|7—ÂyÕÃ÷ÆñGär=È±­˜ql} ÆÛˆÎ}K®”OšÈ†{¶…éx°Ä]öÑaSw_%äïâ°Ï¨ÄşièÒˆÊsŞ#/ï?â”ÉùüÍö‰HÚ¸Ó:´? şÇwJêŸ
4(÷àŞ
ën4zšk¹lkĞ…ÁRŞ…¤WmÖ”ˆ<79C0bo}ğ$o½p|¢:eâ¬Ôf<›sŒÄ*$:…ñşòeiñÔ?  ó¨rwèÒñ®f˜¿#öäQ ú»6k:ÿå‘Í˜ÕîŸlW±Àf”$›rmc]h<;i…f²Ÿ4¥ª.z‰½E® øÎÇ&l©	!Íš÷a±«Cïú“q[«ø#}­€şÛ®ûëP ¬	”± şš²Ò.Üü&ÚŞ÷ÇnX?rkÉA×ünqH|ŠÒîuÚPpóŞ™æÁ“ÖguÁMªnåYÚXk`Ä@´ÚvÇÅÚo›j‡|mÉ£A×ŠE[)æŞÁt¶åëÄ†O_B‰“	ÿ,›!f0Ú™Ì'çÚ2ÂÔ£Ğ(áò²fá•6Œæ®ú†â
èŠDãZé_ËÒ_Üıw"Æ+dVıÿRGGo#<HT2ôÉ¤Ê
©À§À3J\‘ã=mı¸A=&>›‰Nv¼¶w7€èkHs"²cÅæÑ,A¼4#7ëÉ¾îåıvr9°{IÏ-æ6ÉÀzª°!ø~yÑ<ôxUá ²<Šî$QIÏæèÿ„SßŠ³
ĞD5¶÷TWpê×Ç„Õ€„´õrÕºëf³……3BÖã
?œWŒİ£²]C9,|‹2ÃÅ§yE“sVH;‡ƒDÕ« Œè‚èê?FTİU~\7¼ê•’.;çüáà‡…ÉF9dMÓƒiûB²YBÏÙlÔZÀx; I Y!üÂá£C–F…ë†Ñ¤jP<¦	v¢ülkDä1åİì£ŞD×5€<bj„?z‘FøcãA¥ë>Dİyñ‰f”v€fı•r{mVjf¢"Ñg#ºæâ…Öéf³8Á |ÑæpİÕya¨s­ú\òEŒ¯¶?v±‘;	SëÅG^`\×îvÆíúØªûBqt´«±ƒqWáœ#k¶ö§¿b[Hc#”¢o ¿î¾O†™PÎ>&…Lÿ‘»ëzû‚3qrhÚ¿â¾•tÖ¬ı3É'õV¢­°n³¯w8‡4@Œ„‚|RªV¯YæÇìŠŠXº(-Ïìë|±PäšÅ”ŞQ’jöøà±gã©p¸g¡¸ulğ×¡* :¹E©™XhË6••\ùÅÑÙOĞsÉÕR[®-wÚöôıŸôƒÆF€o`zcqöéşüRZ§Ò3(9ra›d¯ø?èyBi»Â-‚"ò*†EÍãx»µR¾İ+ÌÀK<¿É¸mî¶A4-7bÔÎç+•4=ME‰Õ«Æ•İÇ÷%	ù€½‹áÅUeã$»9#ä_ÓÉo
¹üÈ@£8%ÿ‚	GÖ>ç;İÕù£÷i£ÚmEçô¿Á#VhÏnÂ€2ÎÍ¸¬+¦^æ«-b~Z¯9ÛŸi¶RÎ(¾+´T¸éê‡áÄ
ÎÀçAÚlŸp5ÑÍÙmµä7[a»‹¨ß/1çc±×@~-uwÿ ^ÌËôÔVàyıc–‰¶Í[Å—Nçì@X8K¿ôn›ã>Ë©°¡)ö°%*U3Ö=iZL«ÖË$!àˆîR¯c:ÃCî1"QÁ‰û¹å(:E”ökr˜‹Mú/æJ”¿lØ»ŒQÉ¸-SÃf! éAQ^àrv_«O	~4}T<ws#¾H”Ú):ıp#—}¬ÓÎkÅJ·•3LJÑmOçˆïªÄ¾ª¯½vZ~ÜÅæ¨3<"…RI`áÿ¤ğ,÷(ÔD]TwéW*!™ µ\ù_×Pá”¢İÿ¥-xå	¶âeC
—5J‰ñw¶'kj¼ôt*V›eXŸ»dûÅly]¹ÅuBE³˜v12íÓ{…˜o‚ÔœÀ(B7_§²“0§yV
ZÉ—F´êCknĞxx‹İ‚ch FCš„àŸv›?2+¸‰:#¦ŠUƒoÕ¨¿€h‘¼—|=XÉ`¯ÔØ—åEĞÍZ4¢©ü`$lÛ€¼M=À±QMşDÈœª/TU¹S…NP`~¿J£b+x™†öí¾gh/NğÛõƒû÷Ÿhjgr!QÆŸ•D|`sc"¼r§è$™4VÖ«Í°üÃÛuº½ˆ8ÃìŞcq¼(–9ñRYâ­Bó&úKÎR`Q˜	›‹ÁßèâFzÓôã£b„ùV=L6>Ÿµdêšy´å~'_W¶?èl8R˜zêbâ†í×ûVâ-¤œ…1F”*«p
â¤¼A±šÙeT(¯Aøuƒ¿åÇµ¯ÅÀB’—è%æõ‚Ù
,ÔD×¾Ê–r½ÇZöš¸¯Ûü~†›´ uYãSSÁXh-˜ap4ÖÃH¡1¼ ¶GŞÖ‰Ôm©ş‰ôC°ÙùñïTüİ;ÔÄ¦ZMp¸:y)°w/Ü5ç4´ZcByU!›4;[ûË³ø
‰±DŞ~a¨ÃÔ2Üª*FÙßzqcsÈó; BšµèÈ7§—²¸?Ø›xşs‰÷ìFÔú3dWïÎì° ø;äó©Ü¥½6¡xê®çÇˆ.­&ŠáŒàƒ“­æ,4EfHÜÀµ†½  ø%mÆÛ€^¢9>éèš˜dSmñdÒ>ƒm ³ôÈ¦;„!,*„^”Š>ºq7ãu÷W‰èlocÜÖA®¼
£?X©tŞµ?
bX	~åí@kÂŒ JÏ!]é’5/$h•£j{–µ)ÍÎyM-U}ç•Ì›ĞÏ:xJ¡ì"¿ßˆâ×Æ.
×óWËtôh…»¼¸4P‡¼!Zı©ÙÁŸfW;·tx®gT¥Yâ× ¥†ÉyªG‚³¶Ú[ 	s *áÇ,¾pİŒì£ñÄÄëu’éßs6ãi•o\å#íªÿ¥Ì¢O6N&ı[v¡1¦ª¹ßé­Ñ„ÍéB¨ï»x¡N=“Y7ÁªhBËúiô<Ìæ@Á{…à‘R0äñ8b«€\iïtÁ²´>ÜMúÅ@0Õp>½CL´_Îí·f\'ôäÓëÑ}xäÔ]¯]8³¡öãUís}©ßgD‘{4‘sd%BuŒ‡A«7EuŒ›eL
Àz–¯N“,ûjïYŠ¬cÇ¼L]äØùmN™Bóä¢4ãqLÅÅÇXÀÁ÷Xó,’Ë
fµ$¨&*B¤³¢NY0ælaŞg÷Ş7ÀŠ*(–:Ä%u »ãA„_ûç%–Cy½EdÏõğ)V­;ûæõe6~)>çsuÊ¬xÆ‹ÉaË™ÁovŒXº=P§(è†H8r(“{÷?¼÷¶°t©öü€°ó¬˜•R˜6i\ßÀ‰V]óá73Ú4ß°ìWøİ¡àÂ7lW'Rë–6;V»á›6GÑë“.‰°dÜ>®_İ3£ëB¨ü×6ß—T‡§Ö„M¯£¸¢ë¯Šå¸ñÄ”µ-i§ã×yDp×áz÷ ÍâWJõæwÜji.ÜuÄÄTÁLE–¬0@¬İ;›ù§s"â›Y‰S¿5õ~şÄû|œ€‰5‘°€éåHA­cëP¸ SÅ——aŞNXwŠã/-{L¨bóS%ËC™ëra*.¤í ù!D!ÙÂy
óœp_)Ê7ùû¡"óî·ûo}Í‚µj™|Œª‡<k1Ğ5ÂUÃ÷tô(ÔoÑ÷EPâÖé|5iÆÛ¾ßßí#•êTµòxİ~€nşÊlÓò[+â»%¨,ÕÀï£vÌ¿¤ÃíUÀ´}¥>H]Ú£Wá BVDëeÜ'ö–`°’TMAÙßLPD®Ñ^?·›×1~¡æÏµ>–,A3Yõ½v°·„7l_€o2jÚ+îD#bªİ8å¦,½ü×ùş¥p±®‰¢)ÜW›4î´	ænÑ´ÙÕÕ}e ÿÿ¶ÎÔÁM¢ü¯—jk´·Éê€<÷òÎ(è]’‹qè?ã:M›G°ô±¿Ù/’ã…i‰	Ñ{Ã‘¶åeÔoÃœ]6»C·9ö%ŞÃ¼¹z8ô³¶9šüüb4u]ÄÈ/‰˜Ø‰ÃŸ^à|œœ£ÎÜâî/8;äP1Óy¾º'ûıJgÇEı1v,íÆŞ"ƒŠ@GáLhPµqüw„íıÛ¹á¢Ù0Ä_£@Ğî…¿8é'm¸÷p‘Š¡ê•æQ±F§ó¯c1ø™}×Ó¦UãÎî8X©Û¢®1wü‚ÇC—ÿ£'™ Š¥©¹\Á¶ü?ÖT1Sgµƒÿ\W7O“¯^>§lŠÚÅ²b×p·NŠÕ1±ÙgFçøß1R‡9÷'kŠgLóÂíù,a:ïôa¦%öGÔnj8U¨ÄÛ92czÅƒK°Àa±/ ª( Ûb^góc	Ia2'Hy9|÷yKÌùÓDDE=UOğ^D›cÌÁ¦HTÿ0“<İÄ»8Ø9-•4i-ZÛ|Å:a½Ö´Êé^QJÛ¥LoèÛ»¶^»—(æ$ií3@·Ô°õ3Z™@o‡h~"éë{«ËÏ>¶Gğl¦Šêß‘«{XKlJY‹Ù Ô\8Ø#‚q¤fê¹¿b'_énòôGLo~B&è36Áâ+RzgÈ¥ƒÙZçnÙT¦ÉİÒÈoO:’Gö¯iY÷É%Øˆ–¥ó½#³.¼Äo’P;;5Ì17„Ô"™²`<g”9ü!CşµvCÁ`jÄÛÊĞ¡ñ­sÊS
9ÊU¶´PE fÆºB¿€ä®\|¤qnŠZ"—.­ª’§c?œ{16N P‹,6Û‰à‘B,ó%o$vĞÈ¦/İE…·b.\“=Jò§”¢“??™€³LáŒKiffDÏua–+©ü9âxe|ÇC™yGÙò²ñà(`H¸T\h§v,•&e- ­i£i•Öpµ âï@Œü)%µ >ä×|É—HN¡úÂƒí%9“PêYµ]è#ºpæ_‚ì¨¯Wí¯t—Á>+WtÎ«º…AK}sB+Ô}1oÚ¡è>IRå.–eæªålƒkæÅ€G
€ÙäÎÈ00C†“eEs
¬`©œ%Öğ_×UÆ'ª‹¯á#6“=0—:E)Ç¤S+Â´@Üã­ûâİ9‡•c/•Šç/~eaàiúyWî‡•æjnİ;h£`an]³m-{0U–W8J+OÄğRÈÒV²™n€I Û-;ñ}–¬¼üÈ¨Æe&‡¼!Ô¢Ë AG{/,¬JÓÔœ¡èî(YÉ M¿£›İëÇ‚ga•ç<kÙ1–âri‚åVl”jÚ6óJ¼MXÿ\ËNïYt~,4¸Sò¬âLFò>y/Ò€#–Ej‹I±wIâëÇ¾6FìIğğª„ò™?Ú{‚
ôø†ÛÁ¤á<ñŸ=²CfÚ
679ß€†Õ³F&A+.7ËÕM¼ê%
­ïò¤4‚	fNı4¬®r|ló$ÉÕ<ñÑ=³Ëª<›¯õÊn§+¯[Ò˜¹ùGœ¾»˜ó(‰ªD«ôÀ‘l±a€§ºå%¹xDŞ-q	ùFaÆ
l@êCÃ§…sP•Ø%d× `öæ»w]b~”ª]ÂXºB‡úÏcÍöÌïª­IL3\?ˆ5_Xòöuóó›p`àT·¬ÂÙ˜t¯m‹z6\™¥8¦•ÉÃáÆ«ÅÑÓ©Í¦È#NZvèÛÊ<Ì„ª{\Ôí-¢º¸µiğH‡Ì€\-S™i³X	¹‘àLÔ½¹:ÉB$½KO11bM°~²§œ”'K¸a£%lCèÿâ{ö–—N¯Ğ¼wœ³UÕLaÌ¯<trÛ¼¬Wr#NØ)Z×°Ÿ`LÎñUÙtûl?`AƒÓµ#VÓø*ü½ÒÔÎÄ¢zñNÒHó‘Ñ2É~ÚDÖÛŸ™ßìƒ>Ş¤²]‡>²"fríŠüË}]´ô˜6ç'ì[‚t§¿J)‰w_¨TM¢)„´“™ÀN-Ú%Õ8M ‘ŠjŒw¥cÙ•·â¯ÉÊk<fQ¼ +£×Ùœ%/¥Ú_ÑÅxXuªü¿=€ò¾4Oœ$0¸2+iâ´“u•øÜ\øh.•a@óëHTl‡Š6V!qğV:ªß5q6¸/f£ ÚØ¥³ª¤ñè{¤’’µz·MÀŒ!şßÑëÉl+‰åĞÃ\¹FM{ú‚ùi¬ly¯„¨jú7g¨÷¼ÎwàW!§ı!ÙŒWù:¾Pü‡x+e”æ:PFÓ~·ım’2Bèoöxâl‹>0/¾ÅF× T¨:äÀ´Áş¬xNf°‹ÔÌ¡Çş6·‡õ}¹iñ`í<H÷ñqŠ(Ô•¬‡rC
<b¶OXfÛ®v(™\#Í³ô$>.~JÀÙ'…}IUWúOW·Ãäõõï·“È`ç{Tñ¸ !¾Äºßçã;ï5Î‡…Sö€S7|”ÄIŠ$Û,Rèº‚ÊJì'¹†ˆ‡Ó“?úlâW®I:‹âò…Xxs¤e£'AiÇsáŒ<g9!æãywgÏVòì­µàìÇÿÂMg<Ô•îFòåºAìyê¨¶ŠšĞ÷U‘	WlBµA¢ı0?«ˆH²u~ßßá×T¨Ùwxªj0®ra;Š¶ÃcjH–Ò:ó¨s¶ƒøÀšŞ°§¬Ñk2<j¸cüæˆ)ÙmÕ¼ƒµı²°äàÖ¦Î_+Å‚äŸuì‹Ûo@ú¬)“.× ÒáM‡¬Ïùf/Px~ş¤t)KU,:~¡ëŒ
F˜­e­µZß ™±8¿ÿ‡C3}^nsÂ·ÆWšô[yxi2ğ¢½‚’ÖÇwĞX•A5Æ ®bx§öO ‰¬ü|æñòGbˆãß«Şµş^mÕ×íÈ¾.ÆØİ'ß­¬÷X'æÃ ÇŸº&¡–á‰hÅ(–ôÕU¸aÀUEç»”V`L{èı{J1°àrÚ}7'Â7áB¾ÜÏ@kmi%$âõ<Q®Ù©cÔQä×¤ÍI7ø½TC >ş×çˆÜ‹Ô˜ .Š{Ï}ÌàõŠ®ÑĞŞ¡øn’åšà½¦jkVˆä”ü¸5˜Z"x¸E9Â¤:Æÿö XCN²a8eùÿÊ:jÀöxt{:äÿÏÿÇ<ÒÈ¨;q'- ½ş~Š”Ú´ùl—ŞÆ‘]Í£´èñcA¿uÄ×ÅhÅh,Ãğ©Ñ$Êëğ>wé#`Œ_k+C?ğ¤÷KŒöÍ¾Ë´8-ƒÇÃW•tB× "*#5–]¼×eîøxäğ†Ê[ù~Òr&Ù\­åËd}\+ùBËü¸-Ut^[Ô´ø°ï½Eãr‡š¿§—&ıä±¾¯$Ù¶®(ïnú“hšó#Ïo«»œ)—Ş]7!÷ÅkCé›Î’Z4³ø–ÚÒÚ¿ú\é½0µ­]‰û{3«%br¿ÌÿI—~”¿Éi<ıê¯WÊ1\l`âÚéö'»	¤9ŞóÖ5š9Z×³8Ïn‡wŸJ* Õw®gF-0’wˆı”µÆ×“”¶5vQ¥±Ésæí‘İìD)!ö QB'§PJ]+Á/´ÈÁÂhöHÒrıPX’Øcû	>Âs*¾Z0	Š;b™8IøÆ—LÆ~ÚÓ“æãË$1ùŒlòïê =ÃYiwø'UÆü=êx–gêüüº*`™“‘ıZ{3Š¶•—ø Z¹=&Š”^Ä®‹ÉğàaÅtb?A’¾"ã©_óQOäqcª( şbpU’í€ ¤ySùo)g§ >Ûv È0‹ËŞØ”+>KG½ÊTKÚ¾3Ä{‹ûëU—0²f@o¶°#ñŸ	~À)š´–£Påóí)«)RÊ¹LÜèÈº/%µ\-æà1{£Û¿d ­á%â§«v;»ºÎ)¦Î©¼„ jù÷GÍæºlûUy§ËmaJ^ŠÔBìÅZY
İ.+vq¼(ÂímĞ‘èÄÎÓÊY‡(`b°'Çc““zîgiÏ·–àXÈtØÖ×4CÈµŸjy|Ÿ|ğDs>É^¼5Ú©Q¶¿|SeQlƒğ\abŞ$Ür¡7»Ù¼Ç4c5=†)F‡ZÇÏ9±f{º[œ š9ºÍ½@~X>ŠÇ12hì€àÖ¢IŞãÌB9A!ĞôBëÚÕÁh5Ö×D§—ÜŸ~I‡åÏ‡¸Í@ªÑnwş÷ÇöK·Ç›ß‘ùô¦>ìƒôË"_’œ•—s>>Óª“¢çUzU4ÆdBwÕØ6qWgË†ÛšûNåïS· ²ÀúqËX†™‹fçŒKhÆÅBëŠLìî7’—Œ”¶fFAÏÖ§U,lx8P³sUı6Şée?¹Ä4wæ–_±M—¨š†ôÍ2mJ_ßÙ%NPŞŒÖÛ¸0˜ì)@EíëµÜ*l?ê·>˜õ%ÃE	Óe8sü|v‚Œÿâµk,Šf7'¨ùu°»3?F(ü¹£tM0×£LÿùRë‰?­kXo'~È?°ü®
‰›~·21¿ù·3.Û&¤;S¯p€ÓÚ^ıta"ñKLg“Y“mFç`ãß¢gÊ6/¸Ö‰:yu 4d±šW	ğŞ§¨•\„$i¦Œñ?â†óc¯ºÓgí¼ó’hœ»=¯W¶LÌæÈG\˜ô/~ w]©KC_¨wH¨nO•aµ4nö,™ â†3ö©µ¥(V!–I}`v,²­<$Ó¤ŒYŸ­~ôËnwÓÍ¡ı‡˜7PûdAnØ¤{ÕıÜŒ-ESVH+îòÿYZF×çÇäh•´×­ësNßÅv•à“ÇÊ:½eû5É;TKë+é²`è„ÿ¥…næx—r}ëé5ÊLGvüCİAë§}Â7Ì ˜¾Àt¼\ƒÒï{­ZÈûœã¶"k*S÷h‡<R¥§ÙjĞY"'Rph)Şò†*íJÛaîÚ5Áılàßw“D}HÕ6Ö"ô-uJ°KùÅ&ñ:j}UEmk\a)!q-jK:İ[÷Û·ëÚİÀ_$«’­Ù\Æ~@Rºú¾WÜ=”<X$5‹ÃXL›Ú¦hÒ\¼¥{Ñ+Ö™Â1;y¤Î8´²GIoÊ©å)Û®®˜µü—8ˆÃ—zqğæ{ùÚm;b'¯@J´‘D½¥‹*ë*¯W{CÀë(Ëİ`ÑÆŞ:£şÀN~œGÅmÖóbNsœhÊP–kîÄ+hnƒ•75ß‰,j4Q³jĞ¥Æ ½+¥©_¤ôıÄ—n
çˆÔ¶ô7Îõ£…fŞßvlŠ’A*mß6Š„¾`vWsûnMP™ÄO‡.?ã¢M!±jö£0Á-ÒÀåÎÍ?¼»ó?
¬üFV&­Ûü£4Ï„)8®¥ƒJ¬Â¯<ÚƒSg_˜4›IˆĞÃ±˜e°Wh¡YÃf½{Ì	X*sK¤Jñ0|ùW.Üõsœ[dÄ¦ixæøHL¼ş.vi#H=¾º¼k•h Z2´‰UB‡=ÈeBşkL·‹w'•ûó²Ğƒ>%mOv&;‚—J…º~¨`ñ¿=ÊÆ.0=<6åcš	0t•—ã;_+!œ!&»è2¡HUJó¤*[èÃ©¨ø ø@k3Nw‘äNWê¿“‰£}
c‘øšâ±i|˜²(Işkõ5„¶ò¡KlÛ[/Û¬U”®çg	ÚÂyR³- ñxkC_Ô³ëQ"–4÷ÔØWc)°û`ĞÙ±m>SØ¥sYµ·9Û >¼óÇ`î(ĞyáFİKxzk:emZ¼œnÅsğ«ÙE¦}Ù¤78 ÕDµ¨ä?×^ñK^Q‹úH^ºÖ—)¸Æ¿¹œgtèû?¶Ò*R ¦ĞéëÖ9¯È'ïÍ£ˆ³%Š"t„qó…Œu\"4B;è¥=’°íÀ;u	‘ı räW»VuÌĞœ	«õ"»ÛâñÕ«èYÆDß{Dí¨Ö%œ­Í)È‰Ì?#6¼‡tkz7 £}šq.[Ìğ–Î-!P£J
a²äEÁb†&¼:ˆbàš Kºèy‰ WU-È3>Lq´–iµƒ§^ÖI”g-MÉo\Ğjş¹î¨ÏN4Án20 v†sàÄœ•>ë>ñåESã¸LV)o(dNÓo…<F.¸í5oäÿÙzë¿¯·6ŒìH»˜{ê2ëÙÑÊîÏ¿hçßºOúOë §ÇN øZÒ›ÚµFÊxeıô˜Í-ÙˆÛïªÒJ ÄÀGç/’c€ßlìßOucqeUŸOƒÔ'æ÷‹s6à*|²PRÌáÍäŞ;ñÖ8=/Tñé¤9“ß<[ntL•‚ğeVä;QCWıSPš-âİÑ¥¿º,J°•·÷˜ç‹ ôØ®—	ÒŸ²·áëçwÌã0;:gÁ¢¼UÖ¼uÛrí§?aÊ8Ó¡öz}?ùKyJ'òé]“B:„Ï{f¢
Uc ­;Û\²¬aSvš3Ã±~=Œá_#IAº8Ò«Z[@XÛSßå2;1n„`>¤Èµü/¿ÓZ~\€*Í›tGitx*ğë §à¾ò*¼õë?Šİ$‚’s÷ş…†Sæ%üÚËØ'ÅöïâÖO3‘È»¬¼0ßƒ$8¯ b!óû1nëmã…ÿÚÙíĞFò"zóâÎÃİ0ß˜òÒ×2ÇëLk¯4· %eíTd†¡£©ïêE‡Ğ@+SçÏ	´Ëš”ˆ‹';ş&¸ú£¹<ª R»&Æ¸¼çkÍÃû'İLÛyïó^MmøîÔÆcu†˜1˜è£PÈ¦¸Br@È]6YûÑ#Ã½G¥µÂĞí0É¦DÛÖ»‘«ÊşbVYÁ¹]¥ì²C\÷`W(Û¾Ráztˆ5¯Fvú=Bğ7SĞ»àœ†‰>”‡¾mø»B^-²ö¥÷%U’½w‰Âìg©XEMo xÏó›†.A©Òv.\Çy²ĞR…w‡w:¥ê•y_jññÀĞ>K!
h'¡ü.¿ÆÌ6/+hÚt‘àÊáïõòëÉ„›-o×¯Èÿ‘ûú¬äyƒˆÜ.»»7Òy.Æ)}úö¯Hıd"È–MM>à³mÒTæY½wâæ]{£-ªöÄaşÌº0e#=8k t‹tx|ñL±ñÁÄ„ª%wzX´a…~n©ÒóA¡ª¨îó+Où(D¥F]6ĞˆJrôê{s„/[càÿœĞh¯ß?ïU¼û;‰.Z1ÛS,¦ÄÃŸS,NÛEèÿH›ñ f6mP“†xİ(ÁFrÚ‰¦¤@ ÃÊMq®~¢yZ›4”©¡ÀXØƒ2ÿÇ—&0çÊGŠ ÔaG §ïP*üy1ÖşÌ{¡\ÔR mtì6/éeƒá6‰÷!ºU…qÃÁ¨¯ë	QpSš³¦¥S&^Îö®È}s‘“
³#_W?Í]àqä3…6øy- ¨ç¥ƒ–û®±¿nOŞ'ÒAFİfÒ×òC^ÈšŒ<Ó…çiâzei… kiÖÛjg£—s8|ŞÓ.—mĞ BRÙ®²ÍÂµ²lCŠ–1£-RsÁxAÖõ¹×Ì/û”4ğ9nOrñÓ¸°.Do­n5‡+`Yšò\ gÔoçq$©SjÆ-„™ßV´-áXF-ğr­F
{µp}V}âM‰¤ë;b&s4iªy|ñÕàÁ…çz¨nÎÇ(xÓ¾ÃxJßéÏÇ*-åšÉe†"«ó<HŸĞKsg·ÊyÁxn:!êÙ+j&I´vŸS’jtºê{™0A4¨ë^­GÅ†‰ö5‡~¼-ûÂKÑ¨ÄËÅË]JŸ`´çfewvU/·ÏvÏxI¾7{éH¿²Øz í6VæQtß±[d&°í%6«æ18RºD’Ão4W–ç-äUå>Ç	Q#l­òwÅ!4Í£‹…#¹øüÌ…0ßÓÌkôĞ0Ï¥%*¥DnÓ•‰ë¸ MaÌÍ¯=•Ò½&¾:Ù¤™ÿzºçg5·¹îr]×ºÆİ¦ç½õ~ª›]ÊlCù-¦ƒÔ{Cªü7Tû¡2,+ÿ·vfXàPÖ‚M?X3lrè$'Ë9º³ò–¢W¨¨–üæ	­Ò}J8Yºªz	H—íÊ±³:›x Y\ËÚkÖtQÜDUíù
W † }Ü~ˆOÔóôjvG²š!µ¥LÍ¯¦o@…¸D—Ù’<ˆ).üGÀ
ŸµQ¹byÌ1V Õ-Ñı}· Àqi	·ô¨¶ú…¨£êfbäFã†ÆëFœZlGMğÜ^¸©…ì1f;‚QŸİÆF§x¶j®›TÔµÊˆl¼v‡½®z¨‹ñ«‚é7grõê˜½Á„nTÚ,-Q¡Iªßç«wæÂîÚ×Â;µâ§˜%ËÄ‡äğsC.©X ™aÿH]‚T„í·`PÇ†«R@Åaktı‘RDåé^2Á©»]~AN­‚t/±Û±ˆ†oˆ¶Hùy¬M_?‹ù®Sc\‘èäm"œ
ì¬ÄO›ëSkv;…¾t8‰»*è¬ÎÛiU9÷¥¹0`lÔWY­µÒÆÿkÙ]$éª£r“ñw¼Şc9°æ$ÑÄ ?1’ıN†‘tÔ›€Ò¼[³ıpN‚%/ëìÊÔ'i}_'ñL÷JğìútGxTéêe´JêÑûş2À¹GßˆÖ¾:	-Îà%~¡dÖ6‡·ë2˜­ŒrÚer´jl…­‰…^×£ˆµÊ=6©)wtP³fäŒ}5--ş:à²¸§8a2sı¢¡ïÇ«)‡'Cæó"{‘ÿÎT„€ÏÚ°‹aÄ_gv~S`©„¶ü¡  qµŸëó©5{³Yİç8¥e~1ç@¥,Åó®Ã¿rãQmÎÆÆª¬&Çl»Uî³lj„ùM¹æO[ZQ/õ©ãÙ¦iÖß× yU~°lì¤HiP²İ5ëËŒU øU¸éú|æ¢Ê%Liƒöqÿ]ÂüìòÓb1ô{³ƒxù}“äıçØ›<L™%>´˜ßš6û.¸+O$!!œ¿QUz…1˜”jß\ªø·×ƒ:«Û³ØpÑÕù™Mß ~ Ór¢.IA_„ÌL1)sÓÂ^BİÁq©#gÀ½Bj¥ôÉâù¸
ÛÈ)J“J’6µşp¥?ÕlÒR¬¦NÚíĞ§İ å­¼f×§ı}Á„‹bÒf‰4D_cõ×€a´KíÕ(-XÅÖÆèR™¥xŸÀÙ}ô˜²L„İYfÑ:-Ëó‡a|€ãE˜Ò=îÃö·íõËºÏÔ&·Ş×;ÓhœEÇ¿ğZlï°PP²Ó´ş„äİá†Äy9Şß½!g™Ì8‚â²{Â7eyÕG1»¡«
÷K® ÜÌô’ÎHÇùdêZ­KNƒ-ç]¸+»æYB,
¿ÈMà÷tŞÉäéŠÌöXŠşDAùèú{“Ë—ë»ú§±VîÿpsÙ2È”9VÿRçO÷¬<aÃ>66“'kÎ^ñ¢¯©Ì—$-Ç©˜ıkb.>H‰Jùr¦j'ã·E§îêy|(yßŸò”öS¯‚°ÍRsD/L¦w]6ü/lt!ë/hÁ/âîû(ïİc‚Xô|AÇòªáğW@RZ÷|ÙeGH«.HÍ#PzÂ@<íÆc$Á“›§l‚úQªµæ™^ù9ŞWÂcŞ™×3¢¥ÎŸÓ|!nb:XW1	s_µUiîà–O©÷YQ¸(ÕÅØKwÆa`‰ˆB$kğwGD…f}]çSS‰«¢ÇEşmĞ<p|g-;¥'îån<¤ö)«·ÖQgËZn?\¾òF”èº°MT&Õ´¹ŸÑ;¿»MØ·˜@ ]ÙªÇ3ØÖÛgBS/}Lq¶Wû>^3IKÉ×vìRÁfåÉ üàÁ8z¡é¬˜¶P=…9ßíõ‘z/3Ü	÷^…Í,ôL†Ú6ØIçõ™>š’ù~”€ n;	‡4>Q¼„ X¶?ÿºËRÆA˜¼ó¹*ú/Å­dDèt,02Joˆ$_U%Æø^ö·ıÓ \Ì¥2¸˜-îŞbU{jv)õõÙzB÷äàS
®<ë@(@bıêwVù³<^vâådöûW|W|§İú)RÈ9èÍÛúøëògÀ—ïİæd@İë]}ëÁ]‹mâ¿Z4ÿYY‘İ]&DÙĞ€L_ÀIl't|AŒğmqL6R¸­Ï«•Ç·2Úu‡>ÿ÷ÉÒº\#O²“ìKşşÈÛº*äº®‹¹§áå.Ÿv˜ŸÌ»q`+ğ}‡g°úûæ§ôG½4ö±ısÒ.cÚ÷g¯N­È‰i¾ı³¹aW<4BgE¡ùzQÜeú+áuŞ=mı½ŠsˆD™'X7(ƒ¤ŠÇ²¤Í<n³•‚]ìÒ5ÿ†‡H¶ E×GÏ:"yba„Î!?}®Fû§74{ÉSë‰kfT>}m%•8ÁTiÙâO]O<CEá{†1RÁoüP›¼7|QTB#àöÂ¤»‰ŠFµ
™‘è®Ü*?M*ğ¤!ÜP8.0šøŠÏÅ8©/Z®ôùˆ†;å9¤êêKBAÅ'¿©,úXÀt'è&ºíø6‘í®±}´t’Â>bÆëA»ÖÅe–_‘ûFƒ_Ñ+]äƒ©xl néÖe	³B´œ2‘÷§Ó•(%u™!r^,I/A\,zZ½ü´võ3^ÌãCuò•„DÕQŠCù6(jİú]ƒ¸Ry¿äw9GºÃ/€|ÜÓ!šAß(?w>Xó°7î÷Áb&ß›n±§;°pS@qĞy9c^=ç¹AıjPR)¥je‚Ú›Yß'_$&Rx½d*¬vnûjı´¤ãRµ’wáÿÑ$›Ø;´õúk;nVBw³òı&…ªÀÛ£ÁŠ ÚoêJh’ï
ígS0[	pš
7+t“¢A¼¨f3#åï ¦á8Aî¢ÁQÒÈïÙ?ä[´}§‹jåÈ†Æ’%÷ã+ç °yTS!!¸U!"ß’Ì†BdRbÜNI©\dÍAb£	f+Ò­Ş“ûKUxm6´Sı­É²$¸§§©~3ß«š*ˆBøŸ¡>\¡i_Ği'§;LÉe:ª#g¨9}ªëmæ}nˆ±“3o›	ıIO¹ù+3SÑäyó@^1Ó9>oËE£q¿ÍWoT_a&â™¿Æ;I±VRl¤ÎYq­—‰÷U
£æ²¨ÉNLdPäiĞÄTrŒ²Š{…Ÿtûj"˜K¸$âàEP–ïQFšI©†CiÕÑ›^C{§æ”Z±ãñ¼İ,Y‹£²>?Çk!È(çÍ…i6¯Õïñ,7ëªS$Û.¥{…^“Xä<w(åÎ›UpØ‚fÄ±‹A]‡ÀëêçÔÅ§©œúR¿ó9gÙ0\YOÉy¿ë:*CóG7Ñ ¥óh¯ÒÆ18b²{¹KÑ
¾6iÆÆy…»œTA¾ñ;²¹Éhœ–dj>Í=zÅı"ùMNó!ŒÆe-—<8©¸ôÛxG³*ğï} Y7şÅ§£şBšî6·¡,9nbtXşT Æ«ÁÔå}2õ0_¢ä©d§@/S•…Õ"ÅÛ#$0ÄÒr×‚\•n7“—!”'Q	ƒ )è€œÌ3‡àê÷©9ŞØb%çß©i™Òwí?Æû4\´^ØØô_Án- J‘rlÉZ èmïMæ8†Øœ-nsº}ûiÂA>j"™Ş¾˜#Â°>áG¹u,€i}ÊIÎ/1\Êó![LÌzô¯Ané¬»—m§İµ¼.åXÒaÏÔ,”©\’?&ë¦tíÒL0HwA›b5K7R%,D½crP¡0–áT˜F¢tåÆ„ÂSÀó/Ì5ínıG*_:^ÒÀœ“¦3†³U7¸•c–ïóOÌ>&úòi[¦ÌVüì¤3 A—ÔÊ­qû	ø”mas¾tjD²ÜÆ¤Ér[¥üçæSOâZÚeñò:
 )À,25Í—USQ\³ø®ş‚ÊúéºÍ¦´´Ã+­¶ì¿9dY‹ï×,]·Ì®Õ(ñŞnHøu¿—T˜ZeÂä8Õ^ÃdFbgb¹·¶„ûj‚_	Ñx¢F&ˆ"hŒ§9Sm•ïÚ~ÕB+«6(»·¨á,l!b |ü-‘Vu!6Ò“XfHW Zâ3›•?Óœb¦Cwîõ0QèFj—8O‹M°ÀÊêsÿ¤ÖM3&V.w1ö9™¡ûåZËgûj¿àQ€KKÖÂJ7D²§â9›œX7srhÄáµ‚ÈÄd[#Œˆ¯“´›Ùÿ FpaöYA{Ï54µ3Äl¥0?Î,1?
doP•´rLØjÚÂ64÷á¯Á,4Ò<±ß¶à†>­Fy‡Òµ#q¬Vòëzv/"IP›‚4`¢Fx}CÀ’ïš	©-ƒıòv‘ Ù^ üÈiUü;~›'0Ÿâ°óªœ%°Ğ¤X›Í·2ÌÓÇDÈO$v°Ç+TjË¥@<#“k?«›Aæ’S²îËÂ³å±rÕ^ÃïW)Š@µõ}…–à‹JÁøìLâ7ÈËïJî‰ 0üäpd=ç³İá¨²XÚfãÙ65Æ0º¥äîOÃ4ºÉ˜¸Ü‘Û¿ÊúëBè=Œöô…Ñãê.ØEñ<£3–¾¯k®ÓgĞf§«%ÃåWbm°HLÿ\×“\•ã‘9x/I¡¯;Á†ñ^·ºPçÉy”nØ?Ïó•¹ËáËÃM^6J¶jˆ¦Õ	nU<+>¿“}åàNáï…‘ùõHÆ…¾Êæ&ŒlÚˆÙ=õ?¼nDß]0ğ¬¢h@ÎÏXdØŸF°$ºä›Ï #ç¶‡Yğêjòı|,vi	å‚UiÓ/±v"î¡$ì†ëÄMkÊÃŒ/£Û?¯†B¡$_öı¨2tuBk“ßŸPl˜W1q—	şFd”“¢ƒÖø×Ú‘J’Uòa‹&¬ÔŸÙ®¿¸Ğl{¾X¥cSÆ¤vâÑy-)¯E˜W+ôê…Â¨ rEQ
}Ğ5Ñ‰ŒKÄ³ü÷¬ÿ@i¸åè‘AP×év+şjŠ³ô÷v27òí¶e+÷bÊP~n±Pzt~ø÷qr“ÇÂRº×û£ ˜ûPÇİÍñH}±å¥êcKUğIY³šŠ'~y“²äº)îí!ÿL|ï0§äJsbL–Qw"cµJ Î*tI"Àš™ÈP(àÛ9*êòÄ¨˜¤üz¿áÜ}íxwšmåSA6‚dòSC@Ù²ÖQ7O©ÁçÛÑô\¯‹;%5CÅÍÌ d‡"ê²T*É*(°†kmdÿôü­ë)Ä;®3ct"‡ÑG Wı}¢ÆLµ²¹çFL]ÊXH„”»áQ©Ylúszg/»®î19¸÷Â˜É^ˆi¦§ıÿt´HêÃ´á½QyDá*_ò*±d‹U˜¨C'äÁ«)j'ì0\’ü[Å%aÏ,eâ6äwƒa%/ÌùDÄÅ—gÙËŞ·B†ÁÖw…óÜàçå‡pÓŞTSŒN²xã:;*4(7³Š~2²#t»ˆ< ˆÜµ®E¶diÍ®^—nÄÎÎ÷÷˜üo¹rı¹œ®œúïp¥ƒTŒß
A2{\D"¦ıg´ŸŠDõCj¤
çÒ„Eè/@_ëõâB½•ƒ_£:’n&ùI½¨r%é[Áïÿ¡wy…‹*èHîÓû;Ü›Şéi±]‹O\‘5|7‰RôTßÖˆ—|v Uœ¬Eù'•©¶3	Q·İª{3˜u^S…İğhÙıÈ‡z‚5ÊÎƒ[VÑ*&²/b—óÙ±¿¡5¼àé<¸Äµdt\ë‹[`I*8J¯	[&PnAkúdøQ:?tÑÕwÔH÷Îº8q…2HÑÕÖ
K´üşÂ#‰¯vƒu¿æš0Û;²ë,G?ÉŒÜí;o(+ŠcšŞÎ…›&jÄ|9+o+èŒƒ†µ0ƒãh'~ÏÍ]ë¦Î5`Ã-F »,Á,ïÁ4!údûĞ†8OK[0±D– ız„hi3ò¹]xÎq\N´v`"lc,.Eù‡œaÎ’0yx¿Ö¢ch\g70nĞ+Ï˜Ê€…n1È¾aMˆ÷_mFzğsŞªÇˆ—lq\yˆ†F­pÀH¼êŒ\šY¥CM&v[C
B4‡#qÇh…ÅkÀÙ˜LŒ‰àO…<³Í?…ŸŒÍï»¾Ä˜ÉÕšğ4•x¼ˆØæz·-Sùã
¦ò±…ÕÍ@ÅUæ<;LØOÄ§Tí¥~Û¯9zR@rï?ËœÚ-Y}vÿr™S9$ ˆƒ²©ÎÉÁzD[N¬X]úª.ÔÀËpzé¡x€§6d>X3ìZÆl.‹eéÁjİR~„ÍT)«Ò#Šş½§îµ%w9°á{«š´@jx{O 22àòX‡ñk”ÎC|Šßjíğ\ğYÉ¡ƒˆ–ü %±ö)È“Ñ½Ù5E—¥B°Ä·ã‰TºªkìãØÈ>[@¡ñtİÛ‹)•"_ºÊìbÓt=‰qC·}|è+{@šV GÁÕu$eÖ"üËØ·Õ¨ï+^†iUHÃÎ—e”É„«ïª®ëjšÒ@0?S]fc‚?9la[bQTxİ.ïEVOG£“BIàÀ’¦>—êI2šÕÍ¼#µ
?&'n› ©ò‚s85¸Â7‡&æŸi ‚–œ™Â˜Ì¿èöÕÑ¨…í±Kƒ&Î} ƒ »ôÈ¹ÿµ/…öî ]Í7lé4},ÀİÿZo+ÿ…X
Ùõ	ÎÀ§=”ÅvYê·y‹›Jc /‰¤­ÑÃ¢ùHÂ°¨fA\1R? :¤ôğNa`ÒñjšmÕZõ¸údïg5 ıëMgˆ
Øc‘á¨V‚ÿ=á ¬Ş†U„’JÎ= }Q™Ä‘ÏFs9ùŸ'×’ŸTvs;pó]¬'š%@¼|TÏ´ISe¡,]¥Œpƒ‹@,L*•Æ°çx‹mèÁRâ,qÜOÆr:¿–æKõnƒ>WE¸™âÆ>YAT•jÔŒ“„‡ë»¸ä:^ÔiZÍı˜Ò/ıæ¤\PY¥É6ä(½oúe!Í²¶ ©ù.q,*á9Ÿçi2	®°® V¨É#Í't~ôÚ±I *MDmskÑ1 ‡púı¯šÇ*
‚oÜ'†6éCjvÛş„Så3ÏÓ7ä2¸ö8G”Á™WÃæÀŠé»ËäĞ‰>ï§ñ Ëu®“$âĞ`sLp àû3zy0Öøº­[«•ÎÎC†ì,ÑÁúÆÓ‘<µêqpo“£µÇÔqIƒo 0(ÎVsE³$[PèÜG\¨™N¯ \ş”Eq#@«`QÈ¬ü18:+ë’R2Q609Ü2)ê£®ÀRÄİïÖ °›Æ{s¹Æ®N¨£Šö•×ûÖ'‰T ›y0Ë®¯áıÛ®d–^¾¤€0æ@“KŠ GzTå§ŞJ™ş%¾j0e	@“ƒĞ÷gñI%UÑ0ùÀåXÖ=
ŠùŠÙ}¬—^y€×”Jg]„öv6Fsmıª{x¾rŒhísl †İRÂê¡Şœ¥J¿\®ã0!ğìÀÃ'Ş›z‡ËVÔíò4P½"Š¶ü#íÇA—*4¥7#Rg‡//áğK¸¼5.Ü´êïFæ‡'º÷
–Z)•]¸¸úâ/ÍB©ˆ‡dÛúBàºå~Ğ0„0Qİïtà7³ıì|í[³“°ªµ(ÑjãÒèõ pğN$ÔÎTâô=œE¨è’ePF­m‡Ûôl¬&‚ííD”ÙYQ
R&‚[¼×U4‚Ø(xaK2Ùğõß‡^D›Ş¤ó‚Ú(]ceXYÕ» ‘k_v‡Ç3Ÿç¼˜»šn„a¦Î‹Wöào90³í±?/LàÆ€×mÖWQ/ö9³Ú’,@±k‘'–›d¡ôË„™N¿.èÈT«ÌgoYE{¦JjôES‰—åœ¶S:M§ê¥*ÜëÜR×îfô>2ÚÜÊ8I"¿ŞÌËáÚùC›©—zbZY@¦­`ç)ú¾õ±ÃH§¨Û0™©ê½:#vë‚d%	¯Fpß
¿³9ÂÌHu˜QqinæYü²W®í5K•NM€" ÍæíTï¦Ép™ƒç?#(SÁáy×~ÇàÂ&–%w÷€XãsQï@ÛJŞ3ß€#›¨…HÂ³Mc©Ú4#˜(ÕCZ¾Ì+¤#ƒá?>Ò|¦¥m‰giæ
ŠmnH2¿½?K“ß*¤I4äû8ŸEåî~oôã éråeÖI­{™7²°ÛÄ‚¬™©È)‰M2süù›<:ôdÖì.ÿıjkèì;ËeTÚĞ×Ğ°y2äÓ]°U8Ğá­•Ê¾Ø²€*7Úh=‰1pJÍó ‚´›è—M)—s!b—.Ğ]Aä³‹%ÚJïYş‘=¢»8·İy¾n¯7g6ÕewÖd¾vnÎ»¿JxÕÑK1Ä,ë£ç;òË³%e Ç]§pÿ¼<Q™u÷¾ä¡}zo„s¿ª‚éxIğpİÓÆ†À¶<oĞT"dÈ‡´µŒ¼d»Š€/ï…aa8ÓÔ5?‰F›F¼rÎfD³ÁQk6ñsšY”ˆ>9+¢eš¶¬çèê,Àƒ½%™Z[L‘ïê…évEIòäE.(= Zr“£ƒ`®i¨ÌèÏ:È•ŞØìË}†®·Œ§ÇŒ$3.T†›½…qTb³–#¤;Ø©ôHFÛĞXì¶—¨9N?‡|(—Æ6Yòe£ÇÑ<‡L	#mT­T•çÀ¶çˆ Ã ½âöš}='j‰ÜÇ_Åû3^"ËèŒÏrŞ÷ã›£&ğ.Oˆñ#I¥¢+¹ÊùáâÉ˜»ßœ>,±êú´5„Â¦Y%FyÈÁ¹_ è¼h¥w£í‘HÕp]µ0Ç°e¼w=ßİâNàe9XYˆ¬áKvF*c˜ù¡×/"XêàœfÉ‚¿Újd›/Q3Ù/’’‹pÁƒövÍêÚÂYÚ ¢à†˜£ÔåÖcmj4ñÎl.B›‹—a>+^#%˜Ğ !E;dËöå O_ßärbùÌÀª#sè-¿»ÿÈó:ëYÎ
óWE¯DgÂ½0/+ ióÁ)T²«¬ RßÅ-äĞù–»ƒLí~YŠÙo¢Ÿ{t«µ|:”ŞsŞúÑä9»\qÂ®¶²£A<î)ëòNTÇ>ó°¸K˜ôsÊit¼®ÚE†ª j¦Ì[*’Y®:Û¸Kë±Ö0 ¨ÃÏ–ûaµµôâjÉÎ}^ÉöÌuRşÕU‚€»âû51D ª­è´Œ}ÂtŸ½ÉÔ·ìP­ù¹$<£¶ã}-Ö	ßxşb[›ñê¯]f3b'İÚ\¹¿Ì¸p
igEo÷æuÎù›Xğ>y	#J±Qıü¤°¶)·ìXMğ•Y\­‚*kğrà‚ó›8+K¸bnây	<2uJ
æ)£?ËÆ‡^ƒª[á;÷çä»CÀAÒ–]‘_7eËÅbÿ«ĞŸiO'1lpøµvåFµZíöö¢Àµ4‹ç ˜„™ÚÁ™W`~K¹/hÇ,¨[0:C7Aa$ŒT'r	AQPSôåz^ù)ñìS% é‰ON6Ù¢ÓÖ²ïk”Ì¾~Š/ŠšwRµN~%éç¶„‘ÔĞ†ª_$9«ÃKKé»§ ıóBL†îÙóX±ÑıûMÊD¸}C>İt®É˜¼µ~„ıZï¬„Àz¡‰][›SR×ÆƒKñBˆwäùHˆøÌ@ÓŸÂçk¾–à­sÂ0¾ób8ƒ=Ü×%šÖÍFşh¨ì¤ÙÀé­¤”o½ÿº`%á(E| hO•xFSàÜÀúËüDvT	(òps÷O¢ö—c]”Ë:•d Ê·Á2|uI¦lŸJ½%^ÒËÈlŞ/<lâĞú"âÇàâŞÕJ	±øØç¼=Š¸Æ%Ğ hzˆn˜vÎ“a'æo7(ªd;ô×cÈÈGUÌ‘/y_HŸw¼¯{‘¬-âÜŒZ½mŸ$ ùœaÔ\EY½ßJ~f©`í¨áëw3=9Ã:¦v½N[˜|   lV0ˆ‘Üú Óº€Àá”Ÿ±Ägû    YZ