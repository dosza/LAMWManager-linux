#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1335344665"
MD5="60cf54a8ce9aa355e36e8a5b62964267"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20453"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 18:42:55 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=124
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ _ùÚ]ì<ívÛ6²ù+>J©'qZŠ–¿ÒÚe÷*²ì¨±-]INÒMrt(’S$— e»^ï»ì¹?ööòbwàHQ¶“6Ù½{­–ƒÁ|t]ôÅ?ëğy¶½ßgÛëòwòyÔØÜŞÙÙ~¶µ½ùìÑzc}ckëÙ~ô>Í€G–éºW·ÀİÕÿôS×s~1š›®9£Á¿dÿ·6·¶û¿±³¹ñˆ¬?ìÿÿT¿ÑÇ¶«Mv¦Tµ/ı©*ÕS×^Ğ€Ù–iQ2¥L‡ÀÏc3ôÈaà1æ‘'MgnbÖ”jË‹FwÉ`bSwBIË›ût)ÕWˆÈswÉz}³¾©T÷aÄ.i¬ëm}c½ñ#´P6	l?D¨á%ª,í*±ñÍ $Ş”„Ğ;ñŠ¿šÇ¯azT'Ã3 hp€I.Ó÷i@¦^@TÃuH³]%§ÎÎÔ¯ÂI…^úĞ¾ß~~zh¬'ÍşáÀPkOÕ¤3:>ì:'ƒaóèÈX"YĞ\ouûmCMÛOíQïeûM»•ÍÕ>¶û£awÔ~ÓfÍ-˜eô¼9xa¨(W)
„ÃÓ +ÕC
ÔÛ„^pUä;ls@{JŞö­Ö{½¯×ŠkQÉû=Ü9W©”“Ã`~‡ÑµõU×¹çosvòéQ¦¶²šÅµÜàÂRÂ\ ä[3ñæsÏÕØå[£ ;„o˜ºØe
4éÜ?°Ê¬]¥’ğJç¾‡®O<w
¼BV‘`¾dVu¶Îèäœ Æì{_ˆ=‹,Ìé|›£p€SFƒ@;P T&fHtNôYàE>ù+™ÔÃâßÛÏD·èBw#Ç‰©®ı‰|cõd7a1•e±k(AŸûÀ1gŒOëÒ‹^€NGShæ7T …Ÿ¶kµØáÉ™2„º¡&´¨µD-§¨œ tšFÖÆu®v_º¢ÕoHÀçÀbz–	<dÄƒÀŒÙğ¬PŞteßyATÈ|š¢ÌhøÔ©u¼Ï—-ÈpidšPYVÃZú›h—j:[?ró:DñízbÑ©9áš Íl‡y§f	ŸZ¢”µ§©RÉ:_ûÓÊY{cƒ6¼´C1#<ŸÛ!ŸÓ?§—tB¨» ûAï¨ù«Q‹7ÍÓá‹n¿3„¶ì7ù|úWI-gÙŠìåÂä”1 
ì.¡—vHêõººPÓJ9ü:q‘;A'„ ÅõãŠùJc)Eá"¹BI•J&	‰djR Vâ¦X67…•t[ycLìÜ´İ”RŸ8Y†zŞ÷¼°à>•J¦‰±Àª±@çû$êÔD™óy~«ü1ƒÉìŒ‚”®ÈJE6° N>,‡oEMÚXòèá³:ş/ÚîŒ ©U/Ã/ÿï@B·*ÿÛØxVˆÿ7Ÿ=Ûyˆÿ¿Æç…w6)b4g“v•Jƒt}ğ|<@›ñMV~E©=Ç|è÷Ü°aìbºŒ¯äSK1 ò-ˆÑşõq^
ı ˜_Mÿë¨ áèrÿü¿±±±UĞÿ­FãAÿÿ3óÿj•_tä sÔ&ğQ[÷¸9ì`Äö+iuO:‡§ıö>_å£$éEdn^qñ¢Â›GaÁÕ÷dÏ¦™$Ä>™{–=µ!'`†ñqcJ…õ|Y`9¿÷Í€‰¨NVŠá‘_"W©ÊCâŸhšmQÇÛ2
˜Lî\çæ9eÔ™3˜EH<#ÓÀ›ƒ@×tbd¢c:İ%gaè³]]O†ÕmOÿ:E%«ÈYÍ;íù+G–_ú¦ËxD{f&L`¼Š2µ›3™D<Ó¡À™:y§†ıÀ{ÓçuMÉ[ı8°{°Ê_Óşó’Ã¿Yı¿ÑxöPÿÿšû?ÁÂ«6lÇ¢A}Åø6{kÉÿo®?øÿ‡úÿgÖÿúÆæªúQĞïy&šú¢ßvp ÿÈŒº4àa	 D±]ğ‹xTĞì/4›ıÖ‹-4]+ğlë+9v¥jÑNBbÜÿãË#S§q¦e×#½Áz£‰e¹ÅÇ¿¶¹°)/Všó±/…H½Ö+JÅñ&¸‡6GSà€Q{’V‚mÆ"Zwi¸†åa†…üXÏ«OÕÓqä†iüPWŸ`ZÁÄòçÈ¥£ˆŒœñ²ëŞvd»Ñ%9†Š4~¼ÿHÊÌ‰’’ÓÈÈØ¬¯××óxNûG#X¨¡&[¸õi@!²ƒ(Æ©{Á›tà¢š3¦Ô¡€x´9Z­«&À2:ê<õšÃ†ªG,Ğ{Œ9TUk&`ÈC Ñ8iõÉtVDÙoµ›ƒ¶¡Ş:ñ«vĞéñïE–^“Fª×ÅÖÈ¥­{-iëÖ%A/v§' É2.Ø¦9((ÚÌ–Ö•ø«\@bJ3W^Ô+=Büqu87BeX0à‡ ]J^Ç¾'Ş8°gføñŸ Q˜pXtÁS†€DsŸfÏÇÿéØÏ]!xr£¹a¼gjó/â¸Dc·/~yğ§ËARC.á÷*öŠ|ÆTñÚø_Iw%LÇ/Q]ÚoÚ`v.ÎìÉr{~ª¢ÉØÖâJ¹ZËR‰ATuùì¤s‘£Úª©î7×ı–èpı¢H¯TyÆ›'pOÆEò]Z!!ä§çÊ2 á
8YœnØ?=yIRC>ÄQXìÏ±–ÉŠ¶Q_×ÆàÔl´W»^jûööô&‡:>Š‰ÁşÜéÅG¦[G“Ó7£İã6vfBt
ËcH‡„yğêdØ<¼áÆ±dÆ›º¼WuĞÇúì7µdu© –NŸÊåõòBoJ°áÑF,×¥ø Ô"ªâ §„uKMy’3ÇP[^{ˆxH‡ğ‚ÊêQ ÍÅ
äÅ‹…	€PLx¸¢<Ç¦Æ9Í`.NyÏLwF³sû¥…Šİ"%’uW*XÛ °ğè}ÅNƒådş#©-“Vït4löÛCÃØíU³Ø>RIwö‹ˆŠ´úİÁ@ ¶|€zõ¬I´ÖôÕAïÕ¦JáëõÛ7îLEp¡Ê—3€+…2[R©dw$qìö[mÁQIÃ‹X1D¯ŸÄ äÃo¶Ÿ°Díõ„¬¤{ïû“Ëî#ËÎÓ¹­‡‹× XÀ´İ›p‘vxÁ.9 ´LÚMVŸÚõI·Ü<ºQ‰°Z6\±U*Yb‰à«é±i­TûU-Ğij¿].¦+¡*Éú2ö/Égö—Up9³Z=hD¸•ì².4ƒÉÙÎV©>ÜÇ•l·´Û÷Ğ“Ï_"ùyíxq°$íeÔİ&P+ïgÜCŠ&%Éxô˜£™`)™Xá¦ÜÉŒ/m>•KÕOÛ>$ù­ÃEäHNö\Ğ¼ØºÍñm„?l¹cH6då¶`æ0-{^8ÓçÊ–\ dx¡ÁEB*q{Kj“®º5G]4šÍ“ı~·³?Šå¨pçAÆ)Œx²æfKT_¢5<qv	5‰KàíŸCNÎƒÀó’!)}9oKb
«òå‘„X‰]½,W*ŠbÒ3'çæŒ
»ß>há¥¶õ2IØm×¢—üÒK’Ú5ŞÖxßû›O^k. L8üPeÿ·¯ÿòkFLÜaµlpeXøöúïÖÎrı{§ñpÿûÿqıw¥_ÍtææXÿ%ép->o,‘ø{Öƒû”ùËì±Cym—#ÄƒŞÜÅF]<&^'.+áuµzıëp»¤XÀÀğÛ¡gÎaMB©Æ•,“ßµ¤êx>?hÿFÁ!ınw8ÂşÌ	~ƒx-q	ƒı—rp1?ÌDós Ü'ğÑép~?/=Š¨¥ÄC™W˜V¦Şš\¥Ô÷î²÷(§³Œ$„Srûü¸’<D%?óİót‡Ô5AlšûÏCïÔ¢ÎMBüÀvÃ)y<8}>øu0l†±±ú=i‡ıkÛzE]Ën ù§Wí“ınÿgè;îî·u}ggûİÓ¡úN4¼ê;÷1!…RQŒğs¡øYúvC‹)­ó&¤Ñ`×p¼ŒÅ“b<VåB±´i‰ì…‡œŠùÇÈuÏ{Æ$KAÉmQIU?¹2"g¼ùêÑ,Vúfxf¬.Xj^! ªr9©]‹$by +ŸÙ¢jœ®F°õ#Ğ4ã	Ò¤V;°vk„*·A‚ !µhJS”ä1ÎSÄÓ+ù±ß<®GÆ»IÍ±­ÅİN-UZİµÎuß1C0Ws¦ÇĞZt2Y¼Û¤Æ„=	š#øm9uæñ†¸q¿€;ô<raÈwôr¢¶ê?ê~@Ñ…ºèU†¸,V©<Ö¢üÖÀŸ…0òz&ˆñËòıégŒ	Bç±Ø%PºÎZø½¦(Y¼ Š$¶…¤
š…7ÄÁˆ$':Â"T*ŒëÆ‘íRÛÅ‹Ì˜œIBôvı=O´ñÂS®¸u&=©É=˜õ5²#
21ÁÅ
ÍÅ…Ãs?ÔXPxúÁÌôØMH2\‰sÜ¸š’Ğ§U¢N%$-ÖÇÕê¦e€õ@çXèõ7!b¾h‰‹–ƒ’`¢È‹M 3c½ˆ¤Jô“(¯íâßİÚa¿¹ÔÈAä¿:.Ø¼b’¿Dô¹cºç¸É;)ñêıGâa /
 ey·ÕšÌUzN—¿ËRX:ßmi¯s½âÕRÌó“·UboŒt5ù	¼ØÏ„¬Ü‡<‰›†ÌZäe»#‚EKÊãÏÄXÜï[Ñp#_‚$gä2šJaòêB¼(ÀLĞ5ÂV_òAérÇ)cOÊ…`À„QŒû×øÌ]f à{ü˜Ñ+.F©v#°4Ì¤?b‘ØQ×´ğ&^Dò—É“1àcX™YSD%³{áÒ é8i¤'F=×¹Š¯okˆ!‘¾j¡++¹#Ø˜7v|¢:5å)daM%;æo±Ë˜{„%öof{;±ÚÎ~Ì`xüs³:À—<µ…1N
)+©H§Šqæ¬™4M©î—õ¦z^Ö¯eE/'RT†Õ;yTá9/‡¯¡?F‹+tòŒ8!I¢z¼»ï%ä)OØÆúıSíº*1çíÓ÷7{öwß­¹ÑO„^2˜ışF°x£$„»ÙO¢õ—ÇÆw{Še­‹ÀñFîŒKdú.ÂÛÓ‘7ëˆFÉe ¿‰µ!GnŸ\ªZB”;xSb‹ &å*”¦œz(.ù½LOÒƒ¼²V~z¢vÜ©·‹{ªŠr-ÆA»ÅÒmÚO.¼àœùæ„ÆÌ}İí¿@8ÜÎàâz,G+›+f‹“ş“|?˜³wî!xy‡æ,ÇÙ=ÚIY›Q+4ˆ‰O†ÙŠ¥ŞcLûóÏCÏa·{4È –š8àÉ¾tF*=ğNù2HMÚÔ˜‡ÂFH#¢XLFƒÓ^¯Û·ˆ’*v’Ë¦†&q·ö¿Ö #Â×(ÂA2ó¹w¯A¬ÔøÅºXÂÔô®ÂIwØ9øu4€pSÜ ø¦p… Aà#Dì{‹|‰ÎL¸È.)¯wîjÙÊúî)W0g÷p÷n^¤6<ÎˆÏrröR\5Oş‹{çò—oÁfóØ ¢c’-³É9u#‚Q36‡'ïÚŠ%—[\‰nú¾“¾÷FÕ	?Áäz°o0„‘ƒ(åŒßãûÇ.D±°åK9÷X8¥{R<·çT÷E}€•Ö]î=ZÌ›³Ûeç¡çó;3ào÷E3iãË#ïEî¢˜sjd[¢¦¦Ş»Qm_ÒIîè´Pänš<7ƒ+MdTOLÊ}<Ÿ<C•E9¼ƒËØrR‚:tYy8˜V¯ÛĞÅxDläĞÕ¡‘Ò`n»¦cLMĞ0ÑtåS£™í[Ì†HÊŒÇ†TÜƒÙö–!¤áBq8|¹wxÚ^Û3àâ°û¸¦È}ÜrLÆŠì>†íäd…ô2Ô/5q‡p?ÅÆz@†5ñOÊûl+‚¬ 6ç[ZŠHˆTi#–7Îó=Ï¢0©c^‰U¾¤W`k,fˆÚò^O¬9tP?‚ÃÚÜÙË3é-dË>dšW»»o´—ûmí–² íËò÷nŞgû÷ßƒC>ŞğÊt"jÔiüñ&îÖjø–/P«í{øš´‘èÄ9¾­4f«İÖè¸}r:êÛÇIÂ_ªS˜çAÈN¾»$eã Û/í€iĞçp!í·/‡İ?O)  ŞÄ6Eõ> Óô½¨3êøõ™ëÍ)¿[jZ ×:»b!küA›E¶EQ{Æ°Z¬‚]Š @k$ñõ³pîÔÑĞ¤´eê$lvº¹ˆ¡~9w>ÉÅÙŸ~™X~$ä(Ò¡1›³ÑŸ`“ÙÁ{0îmxıRQqºƒÎI‡'JÙi<á÷D%eaY“‡èÓ l :P¢dJÛóX(Nì¥(İs¬QŞİêİ.Y]òEC™ú³ü©@L®í#ªerd/³((ˆÊ½Zf™ÄÔ• KöÁ\˜IäÊŒ'ÙµØ‹¹ZíºÛkŸüÑo\<¿ÑÀ@¸¬sÍœ[“’Odoş°£®åæçJU“¶Ğœ(æH{û_V¡ôqBÇ”xfºg¼à¿ `éH2ŞtC’'iU¤’µ_'?¿Õá×SÀœ¤©ÄÆ"Ö|ı„ K!?%kk¤JÌÿğD‰$ÿ*ÉæÎ%°µë<õ…6[u	 ŒAKÎ÷äÄo	ò7@èœÜqü!Ê$‚|ÿñMŠ@NèEO8+aÌ±L:ô^§³2ã€¿ Áøÿ/ĞcfÜYDIJş£ø‘AhZ±ÏáÒRÀıæ})‡¤Î86>Áş\h¼3ÈÃ°Lø|Q-©K„ØÆR^ÚçVwğëÀÏDè ®­	æma‡W–ˆü0rœ˜Í<„Ks·@XÂ8‘ãC*¥[('Ù½ø ÅXOFğ+;ÇàûÁ§£Y’¯ÛÒjÈêÄ½ÿÎâ®:Q°è’‹ÓãÇŸ\ıH†ªKeLñïâ
ág*¼¥{x<¢®¸r\+4p¦ÔâÉÅÃïÉ;|WyeÖ]€Ö±±zÖ2§’jyô³2'j	kTÉçÛä.	ç§U#«Æš\'_&L2oâ…»—²YvGV©,'¥Upu£ _—Wâ?D-`Nã³¥ª…òÙ(ˆaÂ­¿éuö¿í}[sG–æ¼²~Eª€1I­  uiQP%B2Û¼@Úİm:E H•…ÛV”hYûw&öa_fbfÛlÏ%3+³* iZíî!"$y¿œÌ<yòœïÌÎÕ#¾CÃWó$E‚m–×¦A4•º;ıºàOI¥Q²<Î/ÿo0zB»šwùl­_Ìˆ(µ|E¿ÜÁq% ¾áeKúå‹«à§( w2ä”kµœ­ô¨ô£b¦	ÆÀVéG4e)À’Ò	²øMß	e?UêF®¸B±•wĞcXtí£?£L¨ı-!I½t7ÆY ®b(à¨}²TşËhª˜ÆJår0>‡=5fªÁí•9mï‹Uì{ùë£ÎÉsª…¸]Å`Ú›ÃO8,<ÂÉ€¹ğk¹ÁÁLµ¾_Ø'WÎtTvæeuu£R™ĞøÆ•i­®Û«Be. R¹6JhniÆy+º«µ³ï±ê³jıÕ\¢E9±!ÎœZsş5¾nI¥Õ×¬‡:+ÊfTÕ¡B/¢tuL˜Ê)U“u<¤¢PW†ïñ¢FúÆS‹ÌB7#•q³ºY­ËspãÄhMú²-R6’ùH3™ÁE*+ƒJ|‘OdñiaFópÓE‘ÜûÙ¤×'j|H×Ÿÿ{5œ½aŸ¿ü;èÇŒX‚?x˜$ñ÷UÒW§ışŞ..Ò_³‰ü×ËF4êáWØ¹ñU¿ß`¹½ğÓÕ`”ğ{?ÿÿcÊß(ÅéÁtšùY“9µãå74i3¾¦itq°´’©ñU'é¹êÉ{.!îÉ–q‚ËÉ Ìeu2å¨Ê!ÄÁy÷ª—ô=Tİ~‡}T'X]ûGSîãÉx$SËûp`|••ßO¶"øŠò5ş
ƒ~Ÿ¾ƒÊ¡PVhV~û‘˜ú¦"gSıE?„x@O`çú°ÙÀo“~8¡¿³şl(¿•ğW„aÁo0pYçîO¦ã‰ü£Š½zØÅxHD”'¸º¯Òo2étbŒ)íDZ8¼HOÆW™%øáyÔĞ ’£µğ,Ï-½”Åmú™Ã*1iÖH*ÅèK_òWd4KÛ‚ÎTZŒ,$öeÅóRıf`ÔöïÒ–xˆ»±A6¯©"AYå\­-PŒ8Swƒ3[·è¢ÒEé¬F ¢
v§v«ú.éJVÙªÖÏh Æ/Üùÿ›µ^–¿r“
–…ù…šš#ó
ùœUé•èSãA_qø¨“^3DzB§2º‚sy€Èp „Ó°oÏúz Mº}RÜ¼DÊAßN	§} ¯ïfq p‹+0ÓfÃİ:ˆÙÚTÉ¯â6Š«ÌN•mŒë­'§ R¬$’QnqËï)BR«%+y1|-mJU
¢r—çÄçîüÖ`¢~“ä¶ZÖIS³gHŠj
™Ës|y:/T€ñËŸ©ñÀ±@NŞË¦—.vÇ“iÒô{ôÓ[œXó
*Ël&w)/r§#‘S>+ÃÅ_j 1ëï§
CE’@°ùiÍ	¡¡	#ñ8":2|ƒwˆty›hÎ»VH˜çåÄe©>w¾øŒ¾QÉŠ%ßÇ3U¡P?º;£Kyó±d£tšœÏF}Ö6CÀòİ0R‹)¿õ,^nH¿»ò‹i)ó;+Â˜|W ì3ÎÉNºD»¹ùVòò"Ó¹‘ùƒk‰”ƒ_y^-yŞr‡Ñ$y²ìbn6ƒXFa	Y{*3ê’¹ì>3ä¡á¢ ûHá	ŠÓO$É½È%¦vP±óŠYáCB ÒÑ«3µóuZ''{‡o;Å)=/gb}» %¬x2öÄsLz»qŞ˜Ç3µH	*§5„£©+»·’OµFçl9!~ÈİûIí¬VÎCÅÔj—xÿ-’|Ömw‰d¸¿í½‘Ù‘ÛêÈat”·9²M,‹#ep4ßŞènÌ²ÖFğ{&ïûÆè|®ù«‹lƒn—“m„n™WÚ
y¿‘}”6;ÊL ¡“jÎ”ë
ö+g
Ú2®æuÚÙÅşÇ# Ï²K¿®›*)76»¥˜ÃDìÎ-Ä–7£µa€™)†ŞäæåK»¤jæíÕé§T´3Ì£“²Hp»\äRnUÇ ¿lÄ/İ¾ó+¿¶J·Ûş)R~6%6Â!Æ¹mvÌ
t¢paŠoî¨kE,$GÃ÷íhˆ’¼0øÒW †Ãˆ{Yä|LÏÖ©UvÀËIØĞ4§¶â*ÖĞ(aµ	ÖÊ€Œo¶®àjÃ,à>ï]Kãõcò’o:Dk~Ûœƒ‚·R²möTç$5•J\h}n™.rÃÛ;í¿¤«£ëy9ÅjJäÕjĞ×›«F½‚¿V~¸¾š‰ /F¾€¢bV­½½@0 $'É
\&\Ì,¶áa>_:~«Ú¸®¬òK¦ú–Şb(QÌ9V<î'®‘lÈúëê÷Škl0…N@ºtê×ö¶ªˆJâ}gQir¤İ¥Ñ7Ä•…ô¥¬ŠF_şí‡Ï«N¡‚U(1k•™*ÏÅq³@# Â,ËéÊ*mıpte±í«/şˆÇÊFÍ¯W7|¸ôÆ}ØdšşéÉ›Ê3ÿ/©—/x!ò•­ÑUG¨‚Dà'	ÅÀùûbŸkKñêXcüÌ¯½ÃÁÜÔ¤ršÿš_!áK_–%Eˆ4|£`ê²Šö¬4ó‹š£õ¢&ûbjºeÇHnN¯0-xÌ³èy	åâåt‹m¢Éwµ4åsëg-Tl’É Šë³…jyMYvğ¹.sÂ8ŸqÛ'(İuü…Mgc~&vğ¬¼óòm¯û+ë‚ÊY)Õç`©)øªfÈ×(ÌW€qI«Ãº€Íâ
jBZÀÖM[àÀõ±°Òc¶Fæbœó©ÜF®ı¶“^Ï˜ÖW8Î§z)NjÅkè“AÈÎÃâY2ñ%F%	7iÚ-€AéùK~O°‹­S±K'¼¸Œ ú«‡œˆô·ùÆï`ä7“‘GV¶êt9û%ıÿÕ[7sş¿îıßã¿-Ä»Jñß6ªuÿÍşf¹ù1ŒÆ4‹íö@ì±°‘?Jç\piˆXmäê
î|ƒ]xi÷¼|P.K+HVóe0Ş¼ÒÛı£W;ûâÛöµw¸Ú×ãÁ8F“Oå¥úÛV{·Õ,¯…ß×·7ÃUí2ü`§İÚ?â¨ˆÛLã:§¯à şzg£·tğaëm{ïDf©§É¬®Æ×µÊ¤d[VÂ¿îë¶ÒpFš•Í„`/y@wrGÖïƒ®-‰G;†n®öÃŞ Ø QËÇôÃÅºíªWêõ‰1"#KåÅò‘t|M†…=|V's8r÷öásp_ 0Qâ 
/ƒÚn“·[ÅÜÒ5€X_£/Ø—µö¸ÀRØîëg¾èÃÄ°Ó~à‹¯^4r İtåŠ¶üpnô/&jkŠ‡ˆ(`½•ëØm1¢ù
4xØÌ”¨œÊye¤é,Áy+È/Æ³Q_ŒcQD?½\;pxÈ£6Â9Apsõğè°µê3{Èür#CÏvÎ{¡ÁìäªD‚Y¥9!c9òmÚ±·º`>(XÏBœ+²¯$G%?ßôó
ÏcğR_&‚‡ÆUı¦‘$!;~ê%¢-{,ak]®¹V^ëà©|m'¨¬ı®¯{‰ŒbÍE4çj¡Bé„ OĞ\[wàW_eÑ Œ¢²˜ötkÉ“ºöâ£B•ûœ¿Æ­+-‚¯µÚY­&>¯›ô2ŞÂ‰!"Ç2+ìQf¥Ä|›|hÃK.ğû òÓNå¯•?lÿ°n#\ÁøC.Lóp~Á`kp6D»}Íl«Ò¨Ö· U;É	Ks7ši5IšT¤ıÒ9Şß;9iívwÚí¿`©rf(MT:9ÙÍÁ|…†’Õƒ³$gª¤s’ÖÑ,ç‚€I†>6‡ÕÔY¹0™Ô5’&Ğ‡ ƒk$RE‰Ü¤…u‚ô§±Ğ)¹ó:eŒM9ıÎİHK2¤fÎH>1”2‹ZŠÄ‚{Âû}ø'¨T¯„Ié«gˆ.C'A‚›şù5Z ‡äÑJ¥E)Ğ–‡&G)Öf:{Ò	ëj–ëÛú·^Á°¢ÒP>­pİ7Ë›:TöÆT.Z°–m•Jê¸ğ)k á’µ"^ÛVÊ1ï<L2Ì™Díõ:Áõ}dÒÕ=N#×ÑIyµô“4{ñì¹7,:w Ş0Â	Ç	š_Éß47Laó ÷9©^*1àÚqn&ü“¬Fmsrø¹Şêl‰)Ç˜Z’^¹üHd°õS ›=÷å¶‚õ%ŠelŸJó2årÙí0´¦dê÷Òù³Ñ­ºïÊ¶x Jü‰dAš’;*$­tQ—¨:øx-ú!ÎHe3%Ìº~3²LŸIİÌh=#¡ÇÂú…3§x¡›ÑšÚj³¬¨JäâH­×^ó™ø®FÀhãíÆà†ôö«Á	z£‚É¦e¬b)şweK-º™Ñ«1VÉ)V{<ªÂi÷ÑAÚ8FëÄ-¡8Î=«.Àå<„/Çê²Oˆ˜x;›M¨oÆŒ¢i`ŒI'òfõ®ˆdoß'—'ñlD†·èqœ8ãè
¦ü2LÎF-¸nÁú®V«HB/¿jÀpáÿtg¢]¨/åcr2B'w2í‡X§í5wğËpj¬zÎA‘¦‚ó<ì'Äº°Oñ¬~bø I•šyOT*0q!ï›ˆa€±¢¬Ó@…^‘)WÒBÏ2²ô€ƒ*k£pJÀ1¤Ÿ~ótı@œÄ×Ñ+â¾ãŞÊ$€ûÅ«YrÙ16rC’&30Û–R6ŞÉèqWêÏ—?aîŞ
[âÒïT†aB·ÔïpV/DÈÈc2e¢ñâ«ºÔåQÂ†Cvá§ï‚hJÊuVÕ_YÁºê6ôÈgØC§&$æ¼ñH“ÂK,“Ôû|†Tô€L$©¬U®T ïøCe6
fXòöÃşz6q2T.¢•a„.ñe¢+H1Ê"¡üÇJæá1–{ÎyÇÙ0É|anã'6€\qòÀwDÿÌş_ä0ß½ïïeü¿l6²ş¿7oŞûÿ¾÷ÿ}·ş¿¥y·¤ò%½¼V¾¾-WŞ² íğ¥o8K1Ô¾gïÒ$QAUÌ&hæ8›D2’¹±ß2ÁWÍnë]Tiº1mS»Å4½KÆ=GÖJğ=ÏâpsuÙ2ñŒÎ€8ô…Tkêô$Ë
WY•øBA…dn	
mØqß5„_Vi<r+r'AÅ²MË±ÅÑFÌ$Üóê»’B9ìş‚±;’~ıø]Ù>D´°ËÒã–V•³·4ë£ö;,2s¥dA¢r…8P¤¤S`:Zşud­ñKÃ„[Èk=·S±D¥”@•®¦2<ÓaôĞåÕ~zĞ#^à>Õr…­É×´PÂ‘fËŞ"9™É²8&)I&‘MoîªwOÖ‹iæW*Säe;Àü?Ø™ÓYÂ|-Y¦ÛMçÛTUUHíğÿÉi‡^€´Ü’.û"Í…F¯§Q‡Gİ·§{¼âeŒ“n«åÉĞdÇGÈSb$C¼Ãñ0ø)„‹³³ıåßù¿°J“ñyŒ×p”WR³ªIĞOC—$!%'¥æš(¯õ'ï/E8ëúºX7w{)´gŸKÿ¦Øj$qb4^H‘aÔÑ©‚ Esª2É—#=êjÉW® H<Ó´"DL@”4KyÔo%õY±ĞâUaÊ­TŠ¸•‰â¨_3@"ê)ã¿~öŞ·HüõÁÑDóLÄó’ tâİøƒ¨‚U€wöOZíÃ“½o[Ú7–Şq˜øŸ«¡^9ˆ5‡Â“¡H›uºÕ,¬Ò¢£‹ˆø„CU¤ÙK69GĞšâ¥­äò¥'‹âqBâR£¡™¿ÍêFuÃ±`4[­İîé1îp-<šõÔtôQì†çQ }ß¨MÂÑŸv¿²³‚{/CŸ™C0§ÕBA®>«ÀÿétÒ™û<]uÏgV´¢dVß1å—Ï÷½ª¹Ï”†KÂ-ûÄ,¡ŸSÔë´ç^¥×»›Û,«€ı“#¶B<efSù„£Ó“L– ß5ÆÓNªˆa¾\}b
yµ·sØ}€€jT+ô…NU[gÕ>ò’•sØS±èßU›oÈ¹ 'Ärln:e¡{õÛHRCFòÙÇ«£tù10Øğù8½¨]Œ…‚™0<ê<¯öiu ğv—¿vû‡o„PÃ»´¬îCåÁx6Šøt@8Y›0=‡³§#ÎÅèxHà¢y	4=
ú°O&A$úäRé—ÆŠp2t‹ÛA¹æò‘[™	ÍÆpøÎ9#´ôî`šdñR%%H¼Je2‹/C½vÿPy§Xœ°^HÇ£Üm’pú§vë™ óE0L=‚¡x$»ò…FBzR¦ïº8KøşËçö¾¹Åáº ’>O
Í·©¶s]ÁF+g‰ğõ!‚8MQf¶Oê—|ˆP±„ôB|¨Ô—Ú!šü‘Ü‚èÉâ£Kj{¤ÖÁaÙ,G˜ülÔ™'Ü¥öì¥âOÚH+ÕAxGüÓÎ·;ltä—ÓdºvY€DA!_¬D–ÀÜ£™šXÖ¥ÊEÛ[oè–HÿH^I±Tıp’xòÇnˆh(I2N‘ØÙÒt8i®Öà\Öxq¤“¶³êeö²m}h“$`ç»ƒ-ÉgÅ 9nfœ5CıĞ†‡B¯fU’`\®½H8c«WÙ›1]¬)€´Ş°ó³Ç*K3Ï•$s³!™¿¢ˆÉ–nËçCz‡ás-M¥nLòrnª¤) ]§ùIvh¼æ¢L²ZÙÔAË÷C[]ßÉ 2è~Í0{zÃÌ2P™İ2Ë!xh$¬Ÿ#Z+wX G=öäÎäâ¹<Yu”÷÷^uÔ=Ğcß²lÊ9°ñq-ğO«È–°Š<‹Š9ˆWlÔƒ±?Ftúa8Ç	YóOàX3Ï6›Ös®¥VA']‚€µß¶å¾tÚiu	—•U ıËå:&ÅôE£l–Óö~Së6—Ù×¬ÚL3ÅìÒxUª‘ªƒº…ê@dı½×­ÃN«£ÛŞ9hÁå ¯Š•Ê ê…£„6ÏÑ¸Kş>F¡‰¿ÔnéXGå0ŒéÒ‰µìî¼mµ»¯vŠ¿‡u^Ğ&\ñ?4ı‚Æø¿ºØ¢¾ÜUÉ8gonÑISkì)W÷{•u<+sp¦­ŠK«æØ­¦6W’1”é½™¢=ÛÑ‰#9Ì·áÔd¢¬H›Ëğ¢Ëí™ç™gyIuA®„ˆ‚ŞÃı	ÊĞÌ.íf—‡a”â¶Óní·v:­Z•`ÔQ9@¨ÚˆFİKwÅÏñåÜÑ3½5Ú)P:¢Nƒ<Ç€¤³»›&"(U-PÍıùÙñóíıyã8·Ô»ÍäùÉ$ô”o_ÚT.pà¿ãèµßø@i!°Da8î#	”á30˜ÊŞjSÓó“®Uƒ­(µD±ñê™ÆX¦2háR5Ö™$r€k¹sì´;ü¦@v"Ø“íEĞÛ]2Uvâ‘˜B5’(ˆ&RÊÔ¡ˆgNå©'_ä­ÃÒÛÖ	¿H¾A†]ÉĞCÈå»É¸6\Fèx"šk~o ¼¥¯œEÈ¾ Fÿ<^³Ôfª„[İ‡Ñ`¬iKÃ²ğŒENO^Şâs–ÏêçÆø"Kz^:5µÏô‡¡ÚWàÃÓ[’÷ì8.×@sŠ&³Á g„y,,¿üIÇ5YÊ[ìù<^Š,æßAJğôéSQi_Œ‘ùP·h,œËhQ&eaìªâUz»Fİ¤UòzÇ*…¦'qti?óg©²—ú›ÊŠŒåh”Jø^ˆ6ÍàÛ¯Šº"ªkéñÀ¨·¹•V—®µZX­U«ŞF3VmtÍMé°…¡;Ææa“„C!çPiJcT–MfÈĞ2x–ùğ1g‡ğ…‰^ák‡jæ#òÁÎÛ=äIv»{‡»­?77DI jHã•TŒñ®W†Òm}ÁNùOtª½1n"j‚˜ ùÔ‰Çƒ×Bà}’EØ€“¶dÑsU×Éøx¿W²¹˜MıÌş)¬X›³¢f“İƒ¹yc2GÌô$6oĞ¢Ô!ÅOV^jTµmJ¯µıhğ.`çt0íÑå(4Ä|{tÇ³Ét]¡lÒ_÷%ßk^Óg£Ÿ¢‰•X†9ˆ™øÌ8ºróPî~³EgÆjµıƒÛ°–y”
bYj®áÜ~?+RªÚÜR<ÙÜO”Æ›D¹	{â¤†Ğs­å5ãÊşÔ=¥Ì“¨’UDgïíŞá	ì6,JÅuŒK\å£zù»Ärv÷`ùBiÂê¼>ıd]Ù¡3Ú Î %ÚâjŠ¼¶ób&S<$¹Ü™åf«|R“é(š+|Îê_æ ,ÑMRPÍkÊû×ÂÍZ¾D‘ìHÃçÖûqãqµQ}ì»i‘º¬íª—ãñå ¬÷¥P6k@ÅãÁâ®ùDêÊò¯
sî,†¿ég ÚÍ1&eS1Ò€¢x×ÏÍß–&i«Ã®¤Súµº ÷¦lXÊÎÛ$’äàŞõógûy„œ/¥K]{+×pmşYTDzÈº‘ÀÎ¦¿Ãß¼¤Â×ã»`meÆ9ÂÃ,n5W~<ñ–ğ!ˆ¦ôM_ËÎ|Ù­‚â"›‘zƒEÖ€…CU\&u³—€l¹):Caca¦êİËE¯òÌŞ¢æô¡ÑõÎ«‡~ã¥_«ñ	Ãìfí›ßãßc_M+^ÏGƒ~º½"	h{W6¾‹ßÉµÄÎ7×¸°ØˆFñmëÄ/ÌFøøI>œËrdMG¼:İÛ—(ª…‡aãLj¼ÅË?]¨íº‹¾Ø€ëN|‚|wæR§Á°‘‹ª°ÒŠE‰ƒø}8íòã
ºŠ_2C0yß%hÔ´Z0Z’Å<Ø;4,{ìºƒ±hÑânïz³±u.…sc=/Æ¤OoôÒ	ñÊ¼¶pR¤Fó:ºìÛpššr[Ş2H,š~šWm«Z{¥Äxğømed.³åOÎeCZ’Œ@«—¹¼ÍÉ²ºÍ×ˆ> `Uã“[‰Ñk]e	´C±°sóSğ+”<5çnQ¿›&Îkãí6Rk+U›©ş{­(• a	Ûá$ˆbØ`3<S~ƒ%‘ o®z?õÍ_Æ6i¬uŸ±yq¿`ŒN¥3«õSÕD©c(vÆ#ÂñŞjmBSy¥ ö±ã\ÖÑhpMV9R+
ó$œrÄ¡²ä¡,•\stC:‹Ô]“z`¬ªÏ™eÅEI·z?Ë’1] {f6å¸){ş~»óad<›>O¿ŠJ»°›ó¸K^ÑÄi§ßïÓb…òkˆ7Fí±/è!Ìº8.-Ú°®æ;VvrÈA®1S‹5Ã~7¦(¾6TéuÄhfï²`ĞºÊKû²*’_şS²‹0IHõ¯xqLäÏ”yZ`5OÚò²¡8%6Ñ¦>ê½Ãßë¢dûŠ–/+¾
J¼‰­‚Ğ+–*ˆÁŸéò,µZdU¾È!ve‡6¼¼¾›rLÀ°Y¬/¹„Œ¬™QT$˜UcZYNÉÑˆâ›.qT½F×
{‰®‹Ôı‚íã…Æ‡…ÈÜûGB 3¢ŸIbªŞRÎY„¿P¨&¦µq„ñƒtìîå\HÛ\±R„uI±ñ$D@ ×± ¼õ%ĞÖxÄ„PåNeBiî’ a	uÕê
ªU¢BCïA°ó%ÇÊ(ÿÑğºnÇ˜¿R¦J;©MÕ`-2ƒ­YNqï—ÿÌ÷şŞûˆÚ‡ÁÖ€ÙóGÖ(B O¸À®ü› ŞáI‘NŒgÚ2t¾UšÄ‰C’t7»İŒ™ZÚÕ%s‹4'msÂ
íçfmÙÊ´å†ÙR÷S]»Qı\Ìê3gT;/[ÛF”K{UÙ>Œ­XXf‚::Å-ÌïHt~åÔC\¶„zG¥ù›d›OÍIdÆ÷³`qVgÄgVš•+’˜ezåL¯—œáîLhêUIfÒÎÄé™&ş¶Pk:£¼R0º<‚¶;#Mö$ÁÅî7WV^!{M;Jøù.«H]™½]Ò)rz¢ôowv_MÇ§ığÊ#‚‹¦!ÎâşøR*É¦šÄGFa,ºÒ .-Ã³Y
9<ÚT°È£›XÄHÚşÚVl‡AÌuÕoÌviåF¨Lª	s4³‡ª/ ôåAç½zN¹‹|²µ¾ò{à3L¶3mÅüfpî/ÁJf™­‚Ó‚”çÄî–»²T±Ô*ñªæ¡äîYÁÄM7ÙÛ¶»Ø¬çyûwiá.¥tKI½¹,CbÃp"êÍ(ÌîIÖÀÖ¼LÕ’GÍ\\wpâü§‡íkNöÀ¸¸ßPE¶$Oøš~N/Äå`Sİ±â£^j/{åq¼n
`°¬ª„´¾Íâlø‹Õ%+‘\vS0>!uñ±|S°²Î o¦®Ğ%:#Ì¦rÇû{¯÷Nº;¯O ŒîÁÑn®à¥ öè p<óåZ©9àÇ¿ÀÍ
·u½×°”ŒË›z©]PãÆ¼!¥ñy;±€h8nû1îÏcD !q˜‘Õ>±’G’S";rûZ+åå6¢‘Eá¶Ş†Ö‡fòåO;Çu$¡<çiIúúÇhÿÁœ“—='s'!+ìÑ_V2‘A–Z	…¢l¯T`Šì¹˜‰RFbè’>Š!”ÄQ€ŠôäX ê‘ã"ÌÃË}¤96ê¬J7U´3/Ø¸wúØN„ùO¦ãc)JsĞe9¯àTs ¹ceê^ºˆÇÉôµtÍ—;e\gÌ?'Pßo‹ÿW%˜,”5ÂßÄÿÏÓÇğÿğûVÎÿOıé=şß=şßMñÿŠüıôœ(~LîSâ'OÈ%µêÓwñ\©ğ}øğ¡z]cÖµƒìÕó¸Ö‡{V­ƒn*\[…l‚eÙãQÚ;®h¯AAü…PùN=÷¥íY[Z|Òve‡WaTaß?:8n·÷ÿBC ÅwØıî¨½Ûù¾¾Æït‹Àœ…)*ë"‡+0>D0t“*paGµiù·“ík¥š±\†4Á)ÄW”‘XåÑø¼OĞÖÏ¢Ù•‡âC?×èúƒ1¸>°ò>VcËà*U©ÈìM¥”ÿ9p¡¨¼EC*ÌğåsTn”£Z»y-œGÕ3gÿ§Ş…°&ãäã¿6õÇ9ü×Ç÷şßî÷ÿ;Æ=y¢SÖ”Ò—Ä€u$Ö‰q…>p¦É—qù–ÊÉé…Ö¸ò¦’TñR”^à‚ƒ¡ó&@“^	y­î°ˆqoî#â"Š“éaã„I$ØNöŞ õÿá.:ùÕÒŞÑx]\Ã^=ê¯{Z4Ódw\Eí5R’p ’‡W(k§{öÿJE<şº§o	RToè°©T©½³÷W±{$v^íµOZ<Yºár¬y6í3Ieğ7šYåİîÏ»o»»;';h—Ñiî{Ÿx9 §2cDúShâÓÉD~×Úc±æ­ }HŸ~ŸmÊvJ[lš(ùgÓ³éñøC“åïn0ŠÂ8ÀJâ ½
(¥·îqXÔ9>¦ºÏ¦%äŞ(œ—¨?©nl‰ı“N.âY6‚ßË€Ü!ÒJ¥CÔKp¸7í# ’Ãİ¦9B„]-ağ•Ä@QÔ#j…Ê‡L#Ô)ÖÜ0³hgöË”ğŠ5qÙá9LÇÕ‹IoÕLáB^¤TÀaı´ªÇ"­Fî"1ÈÙùæäèÖåÇş%2eq±dğº‡ò›£ãlåĞÜj96B*Æ‡qß-gEõ‚Ş»"ñ…Ñ´düºçºñÉ2`N«½YP]§À™ëq2±j6ëgñÆ,î¹…[âåğvô,Ğ`:ÙmÍ`‹aíJ¶ä©lmnn>ıÃ¶èQÂ¶ÔÔ-6ÎuLÆ®×Ÿ›¹nÖ¥R?"”$£ÜÏ²qŸ=é>ÙÊµÌ’n›Y›£Í+x~§Ö“j½Z÷½Œ…ÔÜ1í˜ƒÙxæë•·#hÍd"ó6XHu÷X™Ô­ß\m<Åd«Ü“(<ë^!X’•´>¯,Z…Z½w{¹„ğª¿¦æïö<›ÌÍ™ğ[jSH?Y]XÕ¾±t°ë(²$˜ÛÍõs¾1ÈüÎUuúPá¥SqšxèDªÙ~ZEÌÌšl$ÈšhØ=š3”& Cº7\FÓw³sÚ~NBàÆƒ¹€$§•Ç9î„øú–çËª¦w€Ì;PÓÂ°Óu÷v[*ÕhèïÃp…€€÷•DJ¹1 =rYxšuàø³J4Z¹^x{S´Ø)éb‘3FY{2	z¡Ù8“<¤Õâ|_Z‡§İ½“Ö•ŞÍÆÁÙ‡Ï„¤’EUc~?Ãş%§Voa[Õ:í>v¸|÷m®rôªgØÁ[#I$°İ:óÃÆ‹¦øº²:–öÔ
Ô5qÜªg@¤ô%ój0ÁAdkˆ‹Hx…{õ	‹hZAölŸ+²
×öêÇŸ|Ï„€£ã¦Ys±¨=ÂÈ¹	©Êƒé{íÖÎ>•*÷~³j]˜HJí)²,=Rqt>c¢X0cÔS:é2ÆÿÀæ.›ùG9­>±…w”p=ÉF7}åµÂOìœµÚYµÖı,J¼á#‚ŞKPĞé¸?NÄju•Ş »Äø~ÁïstĞ*¢Ü §Q z0i˜ÔsC2£z5ª^Äa8	 Ï€‚j²©µip™Ô²Í…Ï:±pL90ÔÕŞÅ¥Åœß yÆÃ…T'KfäU9è¼ScÜú­V@Ã¨wŸaŠuGIz&±DœL*	¿P	õê³*å\ñ<[­8ajeû¨Óéî´ômÄä>V	“•ÙQ‚¾(…ñúøTñO¨Ü~¤¹)eÇE—ŠJŸn2íƒ¯ßøè’4`­ÇÃ«§/Ôåô¸İz³÷ç&^—W×½’Ñ4LïlÜÒmcÜ³¥ÚWĞw>‚3¬Y¥Â'6œSM4Uë÷+~±_%¤8õîyõ/açœ^Ld‡t±¨ê`òp+#à®+üh^a°c×ùrzI6pÇkÚÇšWM–?ÓTp«ÿ–íEßAÒ:Tz¢_¿«6^ôšŒïİ»L`KíÖÛÖŸÅ·;í=Ü=:÷]»k±>†XÒ6*r-.ÙiOTâóNÍñì1à|áh‰Î?Öë•~xüŞùåô=lVú\<&ÑÇóÙ…Ø¢xÜP¿`\ëiìÇi2Ußƒé{#æò]¯¢jÂsãr0›n¦ß(Ü÷Rtá¦?G3ÖÉìüŠåÓb¼O/pÔèI1ÄÃ`TŒÙ(b¡®Ì¹ısq	ÿÈé&ÔÀ¾TÖ=—OÚFJ‚Áø…FT&ƒsB…rØàı5™>‡Ä,Pw‡İÀkˆÑxTÁşú²°
ÕÜQ°IÿıW¨>æV2Òò—ïL¤[ßêdHì»=¸Ù{.dš"7!© N;ÕÖ<o—ôßˆBd\Ş{‡ÏÀÿ¥0BÎwœG•­êj“8DAqX*%A¸@ò,”šbçôÉ@|İ‚f¶;w"Œ–eß®‹|VÚİ\ÔE“kZpf¯~ÁC[qgÈ’•ñÿçeçĞèöj“¦ÔœÚä…ÆíB¶ÔÏã`÷Ø÷£°ão"×—+Ì-Sæ¸14GÂåöuq¬açĞt:.“wYe@‘/€"š~¾íY?4«ÏV³Qû°óÕëÖîÁ§¿gä®¶[Õ-”®ÛÛÍI6µqÿ£›ìc:ôL¹½ú§œzŠH9ï¦&¬Â)Ğ:ôİ‚`ökRÿí_ô0ƒaÿÉü…]İˆ-º3‘áĞ]t{´U©w)?nÃÀE¬ş]ZƒêùÜšFÚšUÜİ+p(¤m2¾j»,}5Ï3–\¦ÁÇçüBdkUœMÇğ/–>}$dòC
l@ïª»­Ïß'™(® Í|š@q:ö¹z¡JØõ¦UÌı(‡ôj‡ñ}¥3…ÉßşKÕ’ï7ÛÔÈ)¬1WG{6Òh¨ç*_ÿö‹«3´{Šê;‹gÉTkUSµJÙU¬D>×#Z¤SlVpD|†G_À‚­/niÍih8Øq<AZ²|Öl*ª¥MJP&6F‚G	|Q\…¢š™òç9¯Ğ	ÇóùÚâÖã2Z@†tp†é ´\$ŸY¤¿-x­<Ï¬•l[DnåÏ­¦—ã×G#µÔÓÑ‡§¯ZíìbMT‚¥™kÉjipVlTëOªuU¾5ÊÎFi_ÇS¬C×Í]ÿÛ‰W×ïÉ[ÎÛ~È§†ÏRR™h§"D$uV¢Dhh2dÊÑTÎ Rÿí¿ı‡Ø»ÀT- ıëµ™!ª…`¥ær'½yÕ38ïÕ¨ÿÑõ¿-[œ/«ÿ]ß|ü´‘ÓÿŞº×ÿ¾×ÿ[¤ÿwk@ƒÔo§Èf-‰„¨r:'sÒ*û"úŞüÂ(ŸÆvO÷I_ ï­ó"?ÆıkvWxøÙóøb¡ü¸²YºÄş2ĞÁxTIP‡gd™<ê˜Š—Í@}I|/©„}|u_6/IX>++ôJ]KsÔIñâ§gâçf°×µ÷§hÒ´y%úENUÎ†($.r\F½.‚öjLj]”6„%îÊJ©N!™GAHÚ0Ã']ˆÒ&…Z-‡´[Y,H{LaR~?Ñ¿µj„>%Ä8í¤:×;òY]©›6ÎW n¬İ~ˆ:ï}´:H{ş}¶ÔÌ/›Yı<<$Å YT«Ua§•Æí¢_Ù1î.iÄ6¦ŒLßŒRû5Ó
RBMÄ—Is­Œ.-mDIŒÈ¡»•¼ÀÇRZ)´üø*?Ù*^ú’»ÀFù»^‡ŞY*g×&n«ÇæB
PµÂËXõQ7Sâ|vÉdMƒ€.op]1ebmh	Š"\äm./ïz^TÈó²Â1ÚO6óşñqÓÄóPE}®M&½O$À£ÕÍIá(Õº3o;*°\,ãåÁHT’‹¼%uÆŸ°Ë%RŠQZ,[İwã¡‰MpşB8Z‘Qp±0Ì¦˜*/L®ì°—P3¸œN"‰œB5n/mªÓu¢{L/,òšR`ÜäÜ±A±ôK8ŠĞrö¯LeUºR¢­4…ÿ.y©ÄÁZ§è×Öñ–‹n­u‹ÈŸ¸`Ÿå2Ds!Á—Ì®—§á:§ZÃÀvAPví;Š¼ô?@¬E	¾æzYókC!ãè1µ¿Úé!ßùëÚèÜU†V(È‘»ˆT¿*ğªÎşQŠ„*R²©pŞ²ÁfÖ—&âˆÎê ı{¿üŸ~@'S8Şc2x—'öÑÑé!ñtsĞ§ÚÕ™ìØ…sM<H]¯Ã	ûò«†Æ¾Â¢ğrŸŠ
äÆÊ1ô¥—Åip	´û
¦„/+‰ØŠ³QN*ÖuÎ=æ)™—‹ËÙtá\äá/lÈ#Çk]"V/’ÓCRªÈ£(Æo}dù‰nyõs HB`îû‰ÄØ'«ö…
ŒÂÏ™ãÁÿ Câ´?éd"â .•ö'‡à¹ P¶SD†lÅâ¦ßh»RĞÇó»hõP·ıÖé‰­pPrˆÛº§ØDexëo3Ôª…i€aŞBøuJš>ƒ~‹WVØl³˜å‡ÀnKÓ¢»¹¡L:?.<…üß Zo/Ş)B³"½Kµ‚x¡ß¤Z rçZ“úReİÀ_F½¾±yL½ù]-Å¼ôĞ~§ÃÏ?«_OÓJ¶µáp},¶3ş‘7e"–»Z<ŸLñX¦ÀL—ÀøŠ–7fQnˆò–(?É:ãîØ‰±+ÂSØ4^0	“Î4Fµ¸’Qd“„öb6 	Àl„÷ài0"gR‚0FŸ\¸yÒİ}½İûrÈÁŞR¥S±“Æ,Añ²mi%3lo«àëÇ ªIã}Cä^b*§ù`„™]@vÛ‹ìä„ÌÁà· øKŞÓ[¦½¹Ş¾Hb„W¨£ØOCàO£äê©fà\=Í")Ùít5À@Êî¥ÎÍ´p7un§rÏ®o;@¾„»EjËÅeAÃb’ÍÔ§bH¢E'aJgôvf­„Ì©È‘M¼°ÅêäÈË"Ì)¯4¾üß´ºü xû1»1åeğìJ³û¢fºÄb‘=C`ÛK+tÁÂ»\~Q¡e•„š6o‰Äáz‰V”ÿˆ®Î]r^"¸ÖU0€6Mé¦ğÕkOº>(CN9”T¾ƒ¯4Ö«>3
’ê”ø^é¯‹ü‹:´O
I†íXsù{#h4ì(
*äÁ+æÊbv[ùr€rÃ$èy¿—÷Ÿş¸—Ô~Ó:àÿà'óşS¯?İúñøşıçKÍ?èµßÓü?Å÷¿ûùÿ¢óoê;|ÉùßÜØ¬gß7[÷ï¿_dşÏ||äœ ^W,Œ¡êÉ×6$È3áã³ªØ™]Šú3_ªÜÙ|âUª!İ/Cß«v¾‡;-ÏÖ¥9ÓI§ãŒveéìwö:İšóØ3P0û÷g¯XVtvÑş~Â±?;øs/œäJäLÃåRšLÄ8}œYQV}»Ò­:«œ1+˜aæĞ
OoXV°q!±ÂIıŠºc·Ûê¼nïQc=Éu|´ç÷A4bÏŸÑûPìŸ<Â¹@ä²!^‘²êGô£7‹Ñ°¥‡iSY9ÕYÑ2¥6t@æ*â;ö€•ãëeÆKH^HMµ”X¾—J!Vtrh‘©§H“ãg¹æ+İ™yåà
ªŠ´İHNÁf2kÊ0mŠ¤™‡çóLM(äúSNíQ_àæi="Së‘ŒÅñjØl
•#ÿÃÏ?/ü T“’°B<4¶GuÄ,ÀJu*o+*ué¨kRƒÎµX*t•eTè$Yó’§	S4B†aòŸœ§á(£kA†õRâ›Y¢kì @ùègp%D¼_ÉÌ¯së¡îTğÜ¹Ö‚ÕgJ»µ2u;Ş«n_ÁÕúã´™(¨{˜”„»‰Á¯”IRE0	úƒ­¶Ó“¯Ú^šg­Oİq·şoïÆS¸
ĞöİóşåşóßCÿø?å'-LªÃşÄÿÛØÚØz’ãÿîñÿ¾şŸd×f:¨¢œx¤ôF¬¡†½‹FˆŸ"™€óñl*FáqSÒ‡ÃSø˜C2è©zŞ)æ?°öÂáy?¤—‡f/&/½•É4._¶¾ë<Q“¿ |6€ÿW^¢—ê=„SA^Ô PÅ‘±´SÁ°f¤t,ÏÈf„bN¸ÀŒØÃç®ş¬‡²Ô€z¦õÌÄsñ"¾´6aŸMªÉ»5ˆ±še< #W6É¬V8îÎ‰™şÍŒr>İcƒX5Á“” ’ª™U§Õ7Á{ÒQO bWósâ&áèO»ßÔëëdæ5a5şoöşÜÚ-˜ B
$EpÉ>>¿˜ô†ïQ¹€
Çq‘VI¹‘x}„1TOÓäéÔ‰úÊ#l=[§%’A5{Å{Qâaêj uµap2%ÏŠ¨l^/R:mï›£”«®?È¨ÕÿpjF×0PJu£ˆ ·,B²8T_$Ï\‰X9‹”ócQ™©ş‚¾	@Æ@J+!Î}<ä"Pîf1[B©‘LÓ¢ïA¡ÙRE4‰Ä‰¤¨5&YÜ€ğ2 ´«ô-ê‚ÁÄêÈá“Ñ;`äâFª+ Xúìxçg´nÌè­'ŠY£V¬›íãy£-7¡&J*¤éë>Îœ¨_QN wÚWOkr¾o–jsä3	¯aFğ¥êõş8@ÿR—a’İßpÜ­÷ItLí¦ÚÚnÊ¢è›“6³9Ñ®y¦Ôm~¨bÆŞƒøxfîÏ-lÀ×°”°4)œòû"µq,Ğ$rC}Ù°¿›˜–5®2;¸;pülCŠ>ÑÇ‹½ÅxÁş{:Ò§˜, ³Tì0BëéKôÒEÕñĞª…çOş'çÿaÉŞ5×¿<ÿ¿ùôi†ÿolnÜË¿ÈçáÃ¯FçÉdÛüßdA×êë(Á¯ÈçÉÿoİ+”Hx™Œ"SÿÃ‡÷ğ!Š‘ánÅÒºôÅ$õù±Å3sÄÌªŒÂ'ÀÃ‡Jğ¼¸¢Q$ÉÛÔ>Ír7½OÿÆH1\5·¶[çiN-r5šcDËƒİŒÌÆ©C?ßSE¨ Cè.å«ùne¦ËuÛ3&?w)ÿÎÀ‰«ù5"pÕ)Œ]LqÅ3'„%1ÿ.3J’H–¯!;ùfšaûÜ‚2”²ŒÙ{a]ä-ÑSÙ|QÒT†øû¢’\4Ìiæˆñ…„/ ’Q¢üBY¾X/ |K¼ÓİJ¸Ÿ Ì®)Ñ¼Ñ1cIXŸFÉg4ÊRvÔnŠ~-°ƒÕ»Á¼ôÖÂD‘î$’_<~êÑAuQfL‡àßÜ$×á1*ÙECh=Yõd~îÂş«7µâòÍ:äK‡|êXôÖÁ5â¶JïP©l‘Ó'¸¿ØHş‰ˆş8ŸI…¼wxXÀÿ76fõ?7?¾çÿ¿ŒüÿhJ«¦Nåÿ9crT–ˆ’’|œÇ/@&	mJ/¾!wÃ0äõx1ÆP¤Ci‘,¶-(
Äôz6ı=_	)Ÿ„…Â‚8kÄihÛ„u®"Â>î/ñ./œÈå¼ØÕZ§¥^K·œŠ–†ÔÎãs¸ûB™q­İÚÙ=hÙû/Õ6ÇAz—{Q^’zÿøâ"êEPÄuªpo	å_çåİ´Â\|®3ê‘	hdX¤Ä"£šrşWAıç­s×(FÂãÉÒşgbÇDD:’­F¹’D‡£º(ş±ÿ¾ò¬ÿks«H-³h±C›Ë–ÆU‰û/ñ·ÿ°Š=%Ñ“l/²èqˆ,:Xõ‰ƒ> GqĞƒš ‘•]'É5ú*7OT:$hÜ#ˆIDô(Šˆ–¢(z¹÷¦«‰u¤'ã¶$˜9qéñ&¡!4˜ìp­*"èƒo6Ú¦n 
PBOzmL¢<ù§#eŒøü„ÑÑ=Mu½ji¯&¨ğ ÷	Ô"‚‰xP4¥>°$èi!'$V-JÍ-”ç«¸×¸ÿÜî?÷ŸûÏıçşsÿ¹ÿÜî?÷Ÿ°ÏÿØÁ9c h 