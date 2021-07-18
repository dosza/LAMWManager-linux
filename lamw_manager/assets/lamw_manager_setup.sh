#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1364632743"
MD5="c89fb047e414becd04d427cb7cfef494"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22604"
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
	echo Date of packaging: Sun Jul 18 03:00:51 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿX	] ¼}•À1Dd]‡Á›PætİFĞ¯Sğucíq†ÿæE×™Ÿ'±”9Ü$¬Wq–$PûòÛó9]×¯â†æøHÍ~Ë×Òàù§kêU›Ëú£dZÇşÛ¬¹íØà@Î¼ĞÍÇÙşšû¯Ì•mçHÓôÌÓæeÌ6ÂÛÔrƒRsŒÚ¬"À´<Q'*ŠwÖŠt¥_Ã›Pm>Qê'k‰…m¥ 7d: Íœºn
+Kmª_Fæ›£3zz
AäqC±à}s·FÊ§q½Z:…¾U1]ÍqÛñç§3}äêñ—T%7»j{%ÖpÀÃ÷ Lx½>80O9™Ô]¶cß”O;¨]xÄ«3%r¼9†º&©Iœ"ˆÁ6NwÒéÕ1f³·½eËo%ß‚9‡½™j"´Ó[ºÇ[ÂO#1d/®j2ä ¨wÜV·ĞR‘Rj¨z´O—j×Yª¨á•Ç¯x‰iÖ3²Rÿ˜w˜(¶(¸Uô%é"'ÌRNˆ\§pØ«Dü¿,nÁœ<•H^³÷Õ@hÖ„ -c¸"ùÁ“·€íhÙKg³é-T®X¿ãÓòFa_	@¸;ó¥Âê²y‹N½\ ¶‡ûŠhÑè³uÁ®GĞK¦)øàDË€?ln	R®“ãD¢êçâ!R)CˆV+\ Ó¸TáØêV3ÆUœ''Rífïš!ğ¸Š”$¨	â²š­ˆ:ÍÅ`×¾dmiÉ!âs
ìë–ñ¿}Ã“Úí-K¶Ò[”ä×:e	Ë#/HÆÒ”ËÊ»Œje ïÃÛŸGBnIÄß€„ÿúæHamãN;}¿rÌ¨²rgæLüÈµQq¼9¡%jtCõHëMç‚ğØ®ïVºØ´
ˆİÙÓsíµ=<èqˆ¦@¹¢¦p[3¼W	ÑêYoÕ–‡h,‡M/Hbaê{/‡ã±­ƒísDÔúB@#¥ã²UPÏv?…|Öø¯N4­¥ÿhy¥F¯ë°ÍOÎLŠçêJÓó91S÷ß&’Ê^Õš×ZC×‰˜Öåì&$Ï‘nLrg-Ù/çŞjU“‹çS×ıª»J‰¾`?.:WG°«ƒ~¡ı@ @ÄÙNæ	­}êÿ=¶£çí•íÙK];ì‘·ıàDpì\öMëËS;G{¹7–Şî·µHùHù›¶J^òŠ“;Şé‹Ü£x=s	+™?)ÛW ¬ßx;Î×Ê¤Ä¢g%0;ÙSÃ_·r[]oC§s$ÖJFQ¼ş¼bÜ³7TEcåC9¢Ú½ğ*SÚÖ7¸ºlsÔªh½¡³üd)Œ¢`; eüöu2ÆŒR.NÄ@4@ÊüÂ›P©Ó-a?à†|¥<5`­û|V?Ó+JØ$_êº÷<n=‚©·<u·h:4$dñàº$·~ÉFp<ø§ÌŞøÇÖ+Ò˜)>>'>P•ÎFÛø­R6­;Qè-µ©d§Õôà¡º÷eo–ÖÍµWˆ&×\^ÙÏ÷™H»3çaA%QÁÉ Òs€ŒãÑ†„£ÙÖ„c½N6ÛŞJ‚GB$1ëôıke¬J%zòˆB`Óv“şÉ©õ`··B‰ŠÍ~§üF:‰m3F}zI#ğFŸ‹Uûè%!ì!h<½i'R| şùÕ’‚Ä=¦H‰òSÙ:­*àà
‚7^¢šAO/¹NŸ~\,Jl§¿Á‡êL¦²“dãÇ)µ‡3r¿i˜«ğ%á)¼Yå€¨‚k°O-DË–®?7{&µf\­ıßª*a¶†^ì¼ÌtgˆŞm(¿ˆâaÇU/ØrÀ¨PY»K©–« çiÆ-?ÈíìGß«©]–ìŠRRôûV¹€Š÷rpä¾İ™41§8È®å#b¯j¤)„O§.ê„?‹•Ê3R×ˆx†W$.Ğ©WÌ^€¸Òw•,”8H«¨cp0ÑRkóyLvk:–Vvkàã9…j‹±K’ 63bM˜téªÕ¤ı×ÈZ­°t»Å{'ñPû’ŞiÃåé·M/<v÷¿¤áX?aÎé¸i6ÜómA!iÖòêLsÓ¨ÊÊnÌïè$âò·Œ‡–PîVÆ@N‡´ßöœãAfOÿê&Û­&WÅéÀ[Ÿ	²8ÂAnE6CŒ§:8´Íªœ(…ûÍ4dÅé[ÚÌğ«e¤ò»ÉË1>s7,ÃM$ˆØHRSxì€a1.`©û…yñP¨8Äå,Y{/¼Jnµ|×P°„”¢À»Dş>Ö2@*(‹YñädJ³«)ˆ~¡ÿñÍ#¾qõh“ûÎ"22rq,“Hø‚€©m8pùüfèÕ¾"­šËIÊWæÈ—"Òxœk9·×xŒÇƒ½Ì‹¸pU†d`¹Y—`’¹¥tÓ ©(c‘ƒÕj%â·3uX+V\òß™ÿÎm9á2ö¨©¢œ¤ÇŠî^ŒP]P[Î®4İã(‰Â#¾
Ukhqã|°Vçù€™2QAøV>1Ycx÷ñÜ^şn0äÌ£„šÌß(…—&	óáü¿©âÅÈ»Æ.;T3¥=¼çÁ{‡è%ã•÷ìm¾³lIˆı§Û
Q‡®ªJä;Ê…~…â`¦1‹ËBíÔaİ•2¯ Z:FÓv¶¹O¤Oíöy
äD>R·É1½mj8T.zİ6PNÇ¤ÁúØóî@Ÿƒêõñ#1'&´åkI­ì'ıÅëŒÚõ'}JT]ßı«`í¼íÄ¨~—µ˜`ŞL"z	§Ô!ÏRã¡<e=e¬Ê9²9v+Z±-ˆ™ĞÓôp-gÜŒ]¨…l8öÓØ>	yİ-Ó‰,‘¤åbÎà§úïìáŒèœºúŞ[`$š¢Ê¹·ıI%ÉÅ`|¦?Y®ßóLÓ@möÅ^-ÉúÚ/P[[P}Ã×Œµ™ó8ƒ-ï” HíM¾5íÓ±¼:Á³Òª†.P€Ô¸îúÓê%ñgùöÇUi7á(´—o¾Z²ôZdÎ…e6€ƒ’÷N‹KQ<ÃÃ§*Š!wu’c·Ô¼ˆK¢ÒÉƒ†Ä
S,ñ´[Ç İGáË¸vÂ5úÃŸ:†Äwm÷ÔÊbkÜjÀ GÅªúørdwJ¸{£]'ap>úéU‘®°á°óoWNb
YºlDrû9Z	Ë324ñŒß¨«ì­§¤N@WÒµõS±ôçÛ[ôa:ëy8ÜI›&,d} ™w7"7Ôİ¦^e±[0Ÿ"˜ç–zC¥]`êüªœEDù¯³İÒ~¢”‘K’lqN|P1ÛÀÍÿiùèN²Gi¤à//z_9È®Eşw¿6
IÜöô“¯*b`Zr9›L¹AIOçX$ÜÓá(Úkš\mdæyñ=¸õ°«…“†¤ïH,ªT’ü “®ü•§£Cà“š”Ÿøáé¦,8†cãƒ:ïq-^F~ùùk;}UŒÊ!Édêc¯»Û…Œfw«œ|<,Ìù–k¯5;¾/7/ø‡Ë?øËmãèÈàûs™¥ùò/“è²U"ÉbÈî6-ÇÈ‰9f@ºêÅ¥…Êmë]Î9ğtÑC¹Ã8¸öêRwtl,×uôÊexÄ¤|¸®!äÊ¯\»næ-ã]¨¼ÒæX·\é{tƒ»Gyp<Ví|qGi¢"“Übj{äZÉ‡o· ÅwGiİÌÅ±ôQ„—
Q«D:QÏ×ÏYÃÖUÿD76/«NIØ%äû¡2+#÷5Û²ĞÚGOK‘ã¤£»šŠùíñ›VØ ,%G¹¤XŠØ¡eúÜ­&±²F}±f™„Õ5^ÖFNÎü¦8Õúj—Œ¢` ¦å†jŞ§ÿaƒçƒ¥¡ü|OD8ìÕL&Şy\XğvÜö¥È*¹Á$½‘ÈÖ}\™.¹èV÷xƒàÊÌÎR²‘…•ànvç&éƒïBï„¥¦ıõªöXİYıê®¾Zˆğác‘æp8£e¶gø*ü6ãĞÒ»§yRhkuQ­$#KZ{æÀÄéä…8Ë½îËjTc•©Æ§Ï²9ä~Äª’P|Â”C;R™ˆ>n°ZpòÕŠ½ÛÀâ-/°+¶¤EŸİä©=Ê#£t
B ›^wUŞ‰më]Ğ*Ë†÷˜kÓÿV^æîÀ\í
9áë`ƒËëšKÏU´¼‘ì	"õxÅ1Ê3ÄåÎØÎ@é’nG^âæÇï«¿û¨ÂkOƒ=’Y'’ñ²Y³jÍ[ŠúQàGbVW|Î¨b$/İœNH²¢³*B´@š%2&ónÀÎÂÚ	A¯/e†Ò%ì€’ı‘á™­Æ¤*B\¹2ÈmÕ."‹q6Ë=ŒŞ©9wÅşe­ÓÌM½-c sj£:74«;HUËwOt¶oÜÆÊ«Æ¥zNŞ0ºÕ‹x|gáj2™Ì0N	N"¹ƒğİé½1¼°9ºuvÏ\4…¬ùß§´c³A‚0j0¹“›AÈºeod7 ÕŠ©#ö¯ÂÕÇŒ˜ïÌŸ„G¹xX÷¾¦í¬{ÇSP2ª®éÊ:mæí‰!¯Ë	èhx =ÿá÷`É‡¬×Œ‘Câ¹G«Pl	=øùûÙ×ÅË6uQåˆf]HôCP]Æ:‰‚çENÅ|Œ©í…ÖB?TsÕvŸì°ŸŠ¾[„ûF¤À`ÛëŒüqf"»1“„G\üĞZ|ıî¼½7O¹rádëtyo”üqÇĞ¼ÊDlF5Õİe`òeàÑyîéS¶fSdÀ]+ªí+1t—tÏa“D¨Šñ„‡İÊV±Š3`¬p‹4#j±e¨Ñ¤Š†{a]Â!zøO– TË°t>oYº€Jíè¬˜MÃ˜w¦áÒÊcî„ö•ÿ[Æëš`ß±?í.¬}ÃdÌx»Æ#ÚmQŞL›¶ã=CëMrGŠhñkÍ6€TmvdÔª,6”È57q'£3/}ÒlÏè^P¯ÊNø¨eLÔ.(>Æ(´Ä¹“°á^+JÃäD%¤lÚ1‚;w¶ÿÂ?G³ñª"Öoî°0]KÙh„tıÆÿÒÑCá×2Dâ >vkëcïQl¿tİb'ÕëØ£ôÁ¸ êßAÌîò½Ù7†ıÔq€İİ•±øj½½sdç–ƒôñ‚8 ,8ó—
±EğhÜZÑÇV	{¼ (RÏ÷Bık	Í&ğ¼¥ûaŠWŞULúğ‚×êeHòš}J?g*–ş÷$D¿î¿=Ö`9}ób!cÃá–ºUÅ|“o	Ó=n@øQ.((„9åuy¶ue´öÎ;B˜_44wÆ}ºÙÙšîWW\Ã~#áü˜±úÈÌ{ìx.~ÒêL«˜¢§ç…ëèôt†lyÁ|Ë§ÚK¢×")‘t²·Ÿ	Wï8JZ}¤†*>(â÷4eù:®ÈI–HyXº~¯ïÏiIj¤2Ü‡S¬“‡=Ø7ìJQS†ş„©%–¹OyW4¦õq~9Q0ed·wÃ%àr§OÑâãÒw™•t-xìg&*ò,‘ìw¦jÀ	1ÖÒŒ ëskÊ<û½u'ËºáneûSéwf^¶¶ùGëv>ñ­%»>"şS"ìÖÙjŞDl¹Zn JÆŸEÛ2:Y8¯ë%ì‚‡«	Ú˜äŒN°V)œå­›EXšÈ¬a? Îßhe=Cšî0|aÅØ¥y¸ j_—(G”GA?£i¨ù'ßä‘/yéwkŠmìL4…ßÅjxx¹¡> Hó`nr§×¾L} W’ºgyGÎ_u{™»WÁG‡U°Ú¬´ˆß3œ·#RR°1ˆ”÷ÂHÊ²¨²èÇ¬‰&ğ$ü·ÁmWş£°â©Rç·Qû}ZØ¹4[?*Âÿšñ¡¿Àlr;¤Í«#pUW0ÒÏ:Îûğ"7IĞë–dbYa­ƒ Px3û­¬K\Šq Q9‰}„™Jõ“|!GùğQL—Kökc<˜Â$Êsÿu 3X[®TâÚtˆò
{ö_5¯a—oÎ†ÿCàî‹õĞ²n¨f[rÁlÃ§UÓÇº½«a£ èĞ[$İ+‘>÷YÜ‰ğ‰|…*qfF:†­¿†÷¾?¡(éB#Î‰±şœ0 ß?ãhß·Äûm±	ØT!4]  )ş&#oF“!×ƒ™‹£JâÙ_
£{ÌgŸNˆ_‰öøñ¨¦¢’nÔ¥\ª~÷t>ˆ‚º9âÃ Õ§o©ş‘¬!šÌşyp¥;Ì¬Ü¡ôğ+i¹úğ'² W¯Ö$¦Kd9 Çg9Â=Òîfe«4&Má•ÕFrwa}¤0ÉºP&Ü<š¤ÅôâÄÕîU:ù«©‰ûi{èµuÉı$ğ“° P*„‡ÂC³¬»İ°0µâ†&Á»ëª|*R!icQş¨º}ÏOõÔD»7ğû™ıN‚¬D>jÓËä¨kú õåĞA[2ò‡ŒIZ%î¬#Ëú6B¶NMy×?ÍªÖ¬¢Ó¶Q•¹mW&|‚ál"ò×cè[b¹"ÉÇšH¸ÑCHúá&.°Â§œÉãR‰¿4i>‚Wüû¢ƒ“mé…3×´i5ŸQ“!HLËiãmpJLƒß‚`›{²]€@Hˆ#¡(pÂ8><¨Ïg°º¥ ’Ü£È@Œ6ÉiùD^âHÁ¯„äPŠ˜f(wº‚òÍå…'#ŸU©/d0WäQ@‘+‘CàA¥TÁ­\oo‡šğÒ‰šjğ¬ÕTDñûû1q€#Ø5¬“\Gˆ" ª-jm¸ùS\0Œ¶ÄŠò¹n¾¬6^A•â…Dér^M;–C!µƒAı
Ú"`’‹ÒŞ7Sü¬”ÙÉ7ÍB.uÄ´k§mßn7®BI‘~N¯æ³DãÏ7íbƒ±0àé_ô…8¼Å£ØOÈ‚uüŒ*Ø©/Èğ>r3ñ¤½QtrIFo˜5šÎÔç…p;Ô*£Onµ*ºÙä¡o±ò—YU•H#ÜÓ}WvT¥¯sÜ¦À	È¬M·3ÃÚĞ–_Cµ´PğW€Å*q¢ò¸ârÈPá¬ü7iqÇÑSÚ·Ôó«¢è™š»8~"ª¡H¬5uZÖN†­	™0†Êp.Ô$¥ÍÕ’şœôzº•³¡˜â&½Às¾fÇêøÃH¶ã§VV.ú–÷§åm@"Ã"sŞ®Y±t„løŸ=nIwAãi¦E«½ûÿ,‘¤èÂÃ_pPSo6úß\âá–Ê){LÜFVÚùtaˆU2Mo„£–U3¼DW”,&õbVú@dH¬–2tWÛ*X)íš £›jz%c*0ƒO¨6Ñ†(jŞğÈ§ÛEûéÉş•×\…’¼äÿÈ»ã
ÛÑ}‡\¸o‡Pc%mºkµV¯h+£€Öƒ<DOfÑPGÿòÙ¬ïŒÏô<E%÷Ï/XgT]hšŞ—¡é<¡Bƒ¼nü´İ§7Åve²âæ×Bã›ÕŠfÎzdâ¸´•Aãçü0
ÆÉ"Øş£½£M_aú6ØÆŠÚ4ÄŒË9Páòí€€µ§q/tº·;­“·Ìû>6¶h\/N]>Kúr•1ØOMy$l÷²€”^¤:Ÿúg êŒX05l6ÌƒnË®Ol”WNZWLóíZ>2pÏDÜã¡£r«‡›©@7›Õ	ùÉ¨''hû½ğÚËâ/b!ÖÍ†°áÏ‡\èŠZ(7ZÃcLÆ§ácˆåëš¯ïIA«µ°39B™fÌàÛ(ëÚ<q	8N:¨­Xj,?UÖè–ªÙÒ»¡¯¤ ·Jä³Ë…ÀÔZğÎÚy—“ª£)EÇ,?ô›Æ(	y2¼‡2bÂON[³(ÄáîÒrÛ›2ÖCÉ	‹Âğº×|¼‰cÜ1õ¹ÃHö­_õ%ßI×¨UàEÛc=ùıËqÍ¥ğ†T$ÌÓˆ(RÕaJSşyò<4“å=>9ËáÓ¯9ß½Ú¥V¸ÙÁF¦_ö‡úÖ¬Òm4ë;¬¤cTahóFçkAğ›>ÉÍîÙ?¯*t} w¼)"ùñÛ®Z«hO·âvÆj(^B\B}b4S ù)À‘â&íĞ’Rş!g%ŸÜ¤ôàˆhÕ ğPÌó Î†åÛì„††‘ô9G-wÏ}(¼‚±â^¼)útªà“ĞˆÑÖ»Æ.&ĞUZõ¾ù}[ğ{³gÕ×êÍÄ]ÊĞO½9êç4	s	ˆéƒ*²¤pM?g3ˆß¦‰œ£f»Ë3	äwîØùã(bn‰Îÿtê1ßø%M®àXXµ^í±^"%ƒö/¼•Œ=Äô–ÑÏ2º›ôò˜î=e™É=eÌÙÚ—³¬4/lÉ@‰©Ã¦ÇfÔoL[–jï’`NIí«M¬’fåô¯"»ÒĞ_ù~8¼ÚÕ¨‚ÅäPÉûŒC÷"Ş…*~£0T—h²ïï·º3%L©dÊ¶ŞôX€>*ÎQ
ŠdÊg<U;vÚ×ğ.÷ùŞíne]M‚fÕ4Bï[œlÒ!¦OÚ°HçÓêT3ÑJÇƒRuÆ®‚ºé·ã'SuÕz°aóéøQ4uÿ"}}_'¼Çs‹F+¯ş!Ûsõ½pÅèé•¤Í†–˜á¼ë£ö|Ô1üÔ¡½·ÁF&ò Q¶=-9¿@w™“uvV³xğfÂˆÙ¬FoªÛÑæávú«ì"¡9.«]K£û@\o“ÁSœÚdš’“"ƒ_Yócªh'jà’öãè’š<õ05 ÿjT!ÇVÕË.4ª¨f“pLò’Ê»'ıd‡ü§ÁJ®N{Ùµí£xš²Îâˆ5.õº á >8£ÎÔº99òÙÑ&)İ^‘s›pUp]ÉŒ<Î=é¹Ïœ^£G¿}0,>Àë½À»/ø&ññIRĞ´¨á«°PS8]½ànÈ½œì•&Õtl„ĞŞ€œbï`ô;Æ,ß7øJ¸àC è±ÅeÃ}M0K&¿Rº¬H_ïÛVI¯]°›4¢ÿ[Èì÷7¬© rV)öxuêÕÀ›v™æprØ¾'š‚0¯¨¦ İØ¢ÊœŒX×P³2ğ‹ÀWcó—%ß<Gá ‰×²kˆèûZ×Î×¼]»ğü\ŸqlàÜ¿†z(··uDç<Z,œ~ ÊÎ!]×02kŸ×Ã£*£ØÁGàB»tùËt¡–Û²õX:6pjuÜe©É¾¶“>‹$E³†P™1TŞ|‘Khy’¥Y †ö–Ş)¨Jø£lÒ­Ù‰œ
³l8âÔ^ÇMÕPM"Ú}£7¤Âa¤¥]7…–Q-¾ÓqÒ¿Oè{Å¼^øšgÃ•@à”{°ŠÑë´@ágòöPg/e4‚†š0‹BÔö¸qoãX·/>ıX×Ê5Æ[4—¡‰ÚH¬w€B €à"Zı†KÖÁU ,p£Ö]Ûş»,$=ê,2q+Ö˜™=øDãØ=2[á*Kdˆá»hT]\ıÖ×¦F	Z§Ø«Ğ×&&Âb!`‹pû(øhW6	JˆÃËÄ¸2,‚…¤ïÛœäškŠÅM*Ó-¼%8¯– P;ğ½¢ÖÓL ƒmJ1r²s78â@>LM®Ô½‹™R]¤FÒj‰~õkÎB'Ò´ğavÑ£ÍÔ“8“O¯Ñã“Á›iùìƒNÑWlDö=8²Å	^CbviWw…şˆ^ĞMõY­·Ï|@œ¿}ü”D 2„lÊf€£ŠÂ;Rr®6Ì#¿^¥ğÈå.`Ã’1¸ôÀªú|9Ğ6Ör±S¾¥Ï±ÁL±“°zU.*­øíóÎÜ•ÚFÜmğ”‚Æ—UÛ¦”ç¯ÔÏÛ¸v‘èræÛ û€÷¬Ï­°:¦©*¯Ê˜È
áÒ›ÂÅ¶°í£Ûš¦pÃ~¬|ò~eí…µgL’Ø·©œ´%ée@šT°XÁ5(ª+Pş1ŸÕòª}êÎvØxËÌ/†,"07FmÎÒÊ“áKfcAï×SäÖ#SÑ{súGÔÔÙ5kş$CSÏHÂ¿ç3ërSV,KŞ ñMÌm’Î
q×
ŠÙÌ*^Œ\ºß9x°uïLê’„•ŠCõ†í/óvŒŒŒ6é/ö
òî3'¼\æJ«™ÓÑ(S#T@¨Âˆ+4ÁâHmÿ˜NÖe,ñ·³cJĞ9E–ø««œìiöñDrşîÓµ}heêNÌY›İj.øL‹íÓŒÍe6¥Ò€+ûkFÁ@0egÖ°{^Ïª_Lø'WÑ’õ€æÇ…RÇ}\aòó•şÅQÃ¸ß2CæV?['B¡ÛÃ˜½DÔ×=ö-Aş"‹ªY,EÚ(Ê¯7€şèè ®æ¬5ûqØì+gq;&9Ÿô·Šÿ. Dsoµ¤˜¥•‚ÿônÒpL¾¡e<œ>ñ­·ø¥ğ*ÏŸ0µcòÜ».DßùÏ¦Æ‡ äÀ¥,:D–¿è4È°0‘;4jWN›<VËıXœ½ÿíknÛŒo±º<AìQµ‚uM¯ùùåĞgtFq³oïôB[ˆäA‹.ØÀñÈ1{l@–C–a©`ü 1÷›ñÀÏfxâ©,2ÅÙsÄ=ûŞ"o±ÎÛ®F{5cÈ+]è±)-T6÷p³ÑJ›ªÒ©Šï÷!¥(>únI&{”7s¾ƒ÷'“‡Æ ·öS—S2,˜¶µî ĞÊÓ`!õ´¼ÈÖ£õW\ô¯³8ßdoıtO®P€I|^f¨Uùs4Ôd.VˆÀß4˜¾}{I|ÒÀÃÎ§l2?Iwpö]FØÎÃ4¦˜ñÉ‚àß¡Îù«ğÿjñ˜°(APÌvwx~õX*Öï¿v¥ömVšZTá'„´ïô_$}è~’)müß!dzOvÂİ?ˆ˜´3Ã÷¾ÿÒÓ{|ZZîÙ¸-/X…wD†İUˆæ[Ç²bŞ)¥fr£&GÒ©óŸ‰ÖV@Ï³Ói£âs}’+î£I­ÁNáÌÃÄl7pc³U«‚‘’)Ü0ÆGäO?QæwfËX—Ä}«Ejíèå°DJÓÏKÕo®V’åÍè{N8íwìsX·^ğ<½¤¶\I¸wø'Œ†+Hß.ƒ¸½Û•€¸ç5‰­l~!$•n> v*úç§ÒÍĞÍ¹B‹|YöÑ´r_½u~Ì”·3Æˆ)Â»„¬XôctGôÀ€ƒØù¹Tö=kšmaOŠıˆ"0ŒØJ%¯®{R`wPPŒÏìí´|úÀ6ÒV¿Ò µ”,ÇşëQp{´©áätd÷ˆä©g–ÀbÂHşJú¿šÕ|ĞŒZ©9VröYv
Á˜39ã,££¿¸x5û^ú¹ŸôDÈ!	½HˆÚ, }	ç´“ ¤šî%LD!ˆ“¿y¢¿©mæşÈ¨Å~rÇ¿I0:·½ËbÉCf7jæ5³?İ½.¡øÚÙ›8ÄLÏ©'lW-¨É’çñ	‡fœÜŞ4?O¼CüÏ3$ó¦ÿÑV~UÇ#çÿí™@õ¡&‡”XEÁ¼¹)‰¹”ÉOtYÇ¿çS-Íñ¨ÿ¯ø3Üxm«–ºJ1³³Ğïş—L¶±ÑÁÒdõò¨ãìCás çÈi¾Š^9‹ï—aµz3ğ:^¡èüÍùW_aéŠ ÛiÙF…‰I T3Ãüı]B[16@’ñæ¾µ<Eã,ğ\í”×¨BÔ¾ù·T²¨`¢æÃ-‚Q f‹&Óê*ÜY2Iòø:ò/iİ›C.ÎX²øíX2Uøc69we@ÈX•Ÿ_[|§9{ˆ/Aóšªü"`›7>·œ!R:æ¦2=+e°È4šÓiÈã"me÷Ç gZ¨íşŸ¾j†oØ—y›ÁDÔ[k1üóõN„°¿ÖvÄ‰,wMù¡EàßáÕÈ4İì¬_=áƒu3ÈyÊœC$.³Ñs–%^Ú6º`:Å-ÓÔeÃµK¸PGë=Ì0±4P)­r·~j ‘Ò¸’‘ü"NşæcÚrËódÊg¸‡°î7ĞíX-jç:ğ¯8†ô#ádšZ
×º ÏN´Õ‰ÍÉ™½éÏ W2Ş "LbuaBk1§8ú’i+ú›ó’/Í`Ã#ÏhO›«'WbYÁ.Ñ’_ßgm(¾V<³™Äù1ÀCñÊQ$Ö¨›àaMé#'œùË‚ç›l³ê0g/È‰|]Á—¢œ$ã•Û§ôÀ"7ÁĞ®_zô>^Ò‹O×	­åå µjÒôTW(iê:o
<È¶
±ŞE•ç2²uñ½á"#ŠBeIåëkö8Ä±»:¡6.ÛL%c_~”/ğxZ2ó¶°ó1æ LP!¸MÛ)Wq¡˜\XRNøyZ3í‘Œ¸’îïœÄSãè¥RÇ>œR©pá	a…EéÒsÃ¢,P[dş_O·µ«Ä×Òu*²¦ñÆ¾¢à"·ªÓ j©^Y®rzé/ƒà‡ëàörX)ÄŞÜ&xöÏW–®¢ëì,xeİ-²÷”Ó5»W9nàCıÙ³wtä¸$—iÑNèæÂÔÖiû¹tà°¯Ê)Ÿ¿tømÙÑ‘¡$s|´¤¢’±Ğ¹v&ÍEá2ÆÌşÁ&êêİÂ³‹áõ#wÆŠ®Ëk‘q´«?$ø]ã
6"(ÅüKXp:_.~Â'Š/Ó„s¡´ƒ§	—4,\GLùçU¢àXZ\6he6iòÕá¤èkç†¢LóÓŒ‚ªè›¤]Jİ{ÎÖ·ºÛi#'0hõsV7^š›o]¡êøğ„VÌ¼Å0Oå”dºtBTÆ~æpw7qÛÑ*vª™¢ÉtªléñÄË‰N°—#dÊv¿{ÍzıTƒÂ¯wûæÈ©êïõÔk¶À	êÆcµVåi€|Ô¿ôçG£Tä ®şòWŒA©ùJĞP´’'¨ê^³&2ïD˜>¦¸väCÎá;37ä¨=üİ©çÒŒ}Æfh9¾ú‰i4µÍ]ã™¶°‹nÂË&çM0(qN,ê´hïğ›â‡	ÄÛÃ‚îÄ4›ª´+oÿ/Çy«Lî´±¢c_¡)®N*3™‡;1áĞop‚‚¸öÛW`×ä<2mõ…€ºbÈóH)òëviş¨p‹j´OÃ¯.ÿ¥ÂAD¹àÊgh´f`C+®0É½`Ë\~¿ì§Ä¥ê¤±ÚÄ§ ÓÕ-0SñÅ$ƒËÅS×ÛÕ2í‘:'%lb«ÓS,_"îúG WY‰·ûÏô›CÀÚSI%X´ÿ7<Ï4ç…Ûl>Û¸„í68rúğóâÁÔƒ­£o%*ûíü2Y³>¦Ò ®VgÂu'²¤øÑâŒŒš9xCi5Ã9¶WVVzÇ5ªÙ&[‡ízcMvFC\úŠöëTj¿ë
^ã-ôˆã¯ìc…gdÿX~5±ë~Ï@FRò·ø8µÑ©B®°<s ÒjYG}«´ùeÉSı•
ãéQ›ªt{İŞì=&„fN½oáL º'—ÒUø\"øì)|5´z|…®éOJ@ihÜŠÖ$lb«( ß’2ÁónãeiøÜ!dÄ,Júì
¹¥V²ğ?\pâÖ	HÛ€fª‹¡u!j5% ÈŞ¬g‰€Só¬K"Ï¾ÏTbĞdI"•6sßJœx?»`ÙÉ°£ç¬g®t‰»ò†#Ô!ö~B:ÌuğBq
]IÀ‡Y‹Y¼1NpT¥³<¿X²ğ4§ß¤ëœCƒ‹p‡q÷Q1ÜğúÂU>+ïÃ=s”¡ˆx8¨±JI(·g-´º—µ¡êg?bqĞù1H¢ƒ]5˜ˆŸ;[­Í2“à9É‚¡fPÇóû`ˆÖ‡jf¼ºƒ?ßCŠDÈVÖÉ{ƒÃcşØJt~1V&Ç€@}qË¬=}µ øSÎT6k‹Œs|M HmSr%?øáÜ/Vc°Özv³:Û‰Bø(«NNê
%}ìÇççA¡QËÚüViË,g`ÇßÆ
Òd„ä´÷ ò\v&ÌëÊ„Kº³ íqiô†FCÒç¿óŒFñn&¥Ñ”É‘xéÚÖ|j-_nM7ã±osßåÿµ‰Ğ#ÃOfïÃAnŠ“ñU$­ ¥
ìÆ¥'YıùÿqÚ”ê"*U^¬‚êi+ñ7 Ï¤ï5A>Në "E¶P¯‡(ì_Ÿº¥=AvÒÓ	ÛwÁ@ÿø€»·êg¹v÷÷Bn”9ÁòŒs2–¡åş…—o,mŞmÚáÉ°}â82¼ iøıOªÂAëO!¸ù;IK”Î(&cpï5mÅ&ñ¼¢Ğwî¦Ûú)šÖ¡ôŞyŸ ˜]ÙWğyw
*½ ‘†p&”üÛ*°Òİ_V\t“¶Kæ-?Ò$ÿPéã˜‰¹&×˜;„îf,ôå’éæ°±$Fİû0I¥X&Bá‡
âØnŠ}Ç1åJ¾âËª«{jê¾ÿµã¸•ÍT§J±Z°²—Aq¡²7AçY¥PËOu5ÄbQ3`& İ7­ƒMIŸ‰pÃıOö`ê'ù2Lˆ€ë3Ï:8·ğí%Ÿ.19¢¬õhŒš¬s?|kÕ?óFÀ	ÿ¨½)e—vk¨MŞ&‡(^'/±ÁÜ e<Dˆ&å.ÅãŞSÔÒ3ğùFÔ_tU…ÍMÀQ¡°úEÀvÙöÔÆëøş‹”ëÆ’ğ`›s‡Ğˆ¢mu°4¸ıJ)AvkIÊ‹@È/WuõÔ7‰&´åÍ¸·8Ü^ä àƒQBHéË€õ% gÇÇişeÕcÍePÌáHÀˆ×Cº(ìşîõµAèoH3) Q*§È'çz½èC781ëï*˜R~˜h˜°R«æ)>:ª8ŸIR›¿şªî°Á+‘DNz<å¬z—tj~…0¤S¬6;³†csÌ&Íñ—Wÿc³O€“9\zˆâWÏ©JXÄÏ)ráüËÒ‰ÊbZ|R¿ÈÜz6‹õáû#	f©Í™lÏlå)|.EÆ®’†Š›Şša(Hƒ‘…‰¿D"?åkÅk	Êú¥¡–¾sXC7«gÄP“]Ì4Íi‘­D§¤«´jÃ¨< 2”`_ÿØäŸ™5Š¬öáÄŒç4«ú%X¹:aãWHf5œÛ˜ßmD[2¡ ĞÓ·Ö¯ÉÿŞáñqÃìôsmt5šÒ¢“‚M&…—¥…Ó†Í?=£ñê¦×Qû(+±õæ;zè• `è§QnŠ;VìqÿÛ‘¸b.Ì'¨¹
Äş\í:	¨4püQ|aGÀê´YøhğŸMû¯êÉé%ê2aÙëî9ÙLıL”qÔ´u>YrÖkAÂh,z­Ñß]€‰"/K3³i&Æ?*Pßpİ¦»#s|]Z‘MÑ´¢AĞîºˆİı¾»·*C ıæ;şhø–(å±QÓá	=Z‡ç!Õùjiİ,¶UÚFftX—MWL®ÇÉ0
g¹Èà÷–&¢n‡xGÌí"z|ëÈ2Ç9ú:ù–›oäñ¹š(„©i×ã[„QVW=ÙM>óş"f| Ü{ŞÍİ?6@±GŸúT¯z{Y»	°ÃŠ+g¥Š—Ï7²P„dv;ğ¤"0QôR¤<k˜p…´~`½C¶îpëhrKR´ä4‡ğá/ÆÁ«›%“r|PMd•ª@GÖš[Û˜E)^pÊª¾S¬»îydÿØ§Æ6_:+ó>Õ3†û{mª¹QTCŸBÀXô‡¬æš>‰’k53{p¯³›oÇèí#t¿¨ÿô8DÛ‡`tp/-ÀH÷Ù5=n„Uî6o@¦ÿìŸçsŸ)ØF¦ 2: òú3Ú±‡Qßı£¬R‹
Dî‡ÖœÃèàŒ~cgAm­ıÅ;ïµÊßCõÂGRgtá€uL:@JS ‹¹­èÛPÉ¿@Âı\_Rğ@WHs«ğG’be©˜0İªş6êwşÙæyøïú}À¦ÿ'c¢Ïì×–8öfµ¥°¤@è-CB;iI¨¡O­ÌëşÙè¬™|YÇ	rŸ _ú¨'*Ûı>«Ç6İ!kÿz“-n°‹)b­#°ãuÄŠ7_vèÕOÏÆá©+vÙËÃàlz–Óé ÿ‹r¬pÿUĞ4ÇİŒÑáSĞ;mê‡ıšÉKvÕw5±îÑ»&ıÀ¨œèò°WOYtxykô\75å­€ÙEBçlœµÚŸi Éä¸7L…æû"º…ß«Ä+Š•`Põ…‚as/×6'ëÃ"ƒ‘'(_5›¤‰Fc¡‹šøÀ¸bİv>6Dñï¤^#v 7Ô['©W×AäÂÕÚ›Hè¹/œZ?‡º6˜¢©HõOT‰Œ'ö²(†Q¯á*ˆ9˜*s3lš±Å‡8¶§)v(Ô*ûŞ÷Â¬5|©/Úî2Tr5}•Áş:5ÿx‘s˜%İ]ÎEf›Á?‹Vú?´§ÅŸd7=0µ‚º.²+c$åÚ% ü]}Ç5‰¿Ôİ[ó#»¿Ê31!Å‹¿0§	vÎ†.Bw7ÜúíOdèugkSN&,¨a·GÌ¯±lhüsRqI™¥I
áï{\®£¹íJıÛ`ø¸(QHù°%9ÕZ–Yj(fEëù±ÄN£d{.ë2;Ñ@(ÎÀBKm«óğİñ‡¿[Qx%5úÒšØFİ`.äuTüb=Š	ÂÊÌğAÚ ?z“ªrÈ¾%sY+	ğÆ«¾¸rŠ_‹ùÒxÂ] ?féAk?XV´ĞçeĞ%gÌ­ÅÜıÄ-JÊÀ°åüÚ§ªq¼Ğq¥¼¥ñ…˜p¿•”·$eËoÇÈLÂ[›¿XÆŞu]ŠG†v i·ÿ²s^îÆ•Es^>[!u+à™¾dQxø„+“m«åÈhŠù¼Ëìv}¡^}ãÁÓ´óZâ¿ÄrĞü.Ø4İYğ£·=D“YàÙË"§×1ù‡€‘QtÖ{×ü1—]ÉŞ)¥*RÏ!B™xãşç|İA5mÊç·šUaÒ3EÓ¿–¤íŞúîÜ>ïKtE_í$%Zâ‹y¤İª"u¨ÉôĞR­È²Rí-›LË´Bnm¡~Qj²#"	Ÿ	hLQZEO*âÛ:Ÿ·My™2âT–7²¥ç­·–H’Ê?¸*E‡Ñ½%‚yºã"á‘ğ±Á(âSÙY©ï|èU-ñŠ=&¯W{İÆ¥­h«ÃñÍ/Á*fû["Í.o	"@¦GE;mBªÊ%L°åˆòVştÑßSL¼0‰
è&Ï¤çÿ×Q×Áfªæ©&¡Š¡'I-£ÍîüÆÏÄj#"t¾÷âñŞv`î„†*µ°˜ğ´7ûŠËp…c€ßâwµœ#VhOBî4‚ñàßƒDe¡JûÅšİE‡úl1ùÉøGLCÇ€9T{µ§“FºãŸE	*ˆú)äRÃ„q	ĞZvæÿí5æN{JÈ%Áİ9}¸g]>…¸@¥¡N&Cï«¶Ùu6å¼92Ïwå¹ÛZ1.w7<Úîæ…jÆ¿ôøÚg–sRTdÛş5hGk½‘Q-yß¹H–Y!=:qîc(6E÷7ìÙ‘ ¢~m+IÍqGP‡ºµ ‰®ßô‰Á[Ö]¢j”‡lÌğ™Ù½mßÙ8*u¨¾MJñDñµ—gdù»]èŒV3Ø5‘„ó„vç}AjS`ã1$Æ=•Ì³–óŠÁéíƒ{W®#ÑÆîu³ãİXÖˆ·Î/ü°„ÜÆò´Sşù¥
“½h'P£+³iBj?ïÆÓòÑ´Û¸+_,/29MÜ25Îcñ#VºøÈ}|Ô·ˆ<Àƒ˜ÛbâZÄiôğ-¹BËƒH(Ç_à"Èæ­bc{ªù4º¼4İpcÅ÷HÙIg¾DIÑa#y‘âË,µ…ø9TŒ<ÅãXIûÉ4+ë^–”ş¹+%q·ØZêgİc¦ZdêÚnššT×]¤—Dm«C÷·ömáj-¨"3%¹PÂüS“”š±2'ºÅËÁù•1b:¢²„Â{(Î˜IÊÕq_§ÙGy,¯Ïà:Ô] ´ÖØc3|mõ¥x®SÍÒ‰ßËÀbıH~fÿáÂ%ş2îƒ2^Yg|†`	ı‡¢XšÁÌ,ŒQQº½ÀªÁÏ"%;³k±Èün:Ä±@#[åÊ·cm±Q+€ U_Ä#lL‚/“ì'Ï®™‚4Ü1ŞÂUÃ]&Jzú:EqÊé÷Ïë^ÎÎõP›
kFu3­ÏJºdêd±›ˆ¤ô«óT¨Ì@I³EË–í×+ÃÛœJš“µJè1|ŸhŞW¡¤Ñ¹ïê;aÒ@Í%,EæšËxş±GT†8—¯5ˆ¤:U&Û]:¡#;Â£Àˆ×˜xD0/‡V>-2ç—ÇüpWşûÌ…]sÆõÍxÿZ²ê
8,¯„"(• Æ5tÀ¡šÂ&—Ñâôš‰£h¤™ô·scRæ.ÌğÖ4íôç	2äÈÁñ hyÆvPyü© ¼(q
Mğå®×Å,¿Ç§7ßş£¼_†$”Ö­ymÁ]Ye²Â]ÈÀ ‚{z1bşÍ‡mrgÿÄv½¦NKÍ¥dª¥“1«Êz\z¼O
<Ù
våòWÓÿ:—IxÙ”è/aZI­ Ög!_~¾ÀÀÔw¡e4un© pÙ§ÊŠŒÄ§ö6DKó!	¢nÂœ¸²Eßæµîùô;˜æ“µÊLYPB5DôŞ÷‹Áu.÷uK„Æ]XşÑl6æŒÚñ‚r!¸2R´û>Õ:<?ìÕ§ğñäUVÌĞ¡#Kk‰ˆîêáªc&FFÊ\Ûá‰À4Œ±$­pé†‡z­EûÁ×7öin'‹Èbsbİ;h™-‹sàM½I¢£&ÄUŒ¾Û˜šg“/’ÎÖ¨¯¸û
pÁ3µ©œB8L’õØ>aÀğC÷7âQŞËYIÙÃÙ%Fâ»ãØ¦)òiŠÚrG¼	TSe?é>¸ y/1åÉT¿ˆlÊñ¾ür›]WrÏcØŠ‰Æ‹q‘5¯:Ã	^ıtÎÈ;`æ+ê¢2¯Ê\ñô}"ï\‡Mß8©ævàKIŞk˜IÕ°ÌñüŒ¿=µå@Ê.¡©¨EféªºŒ)CWİ@ÇBÆHR#h»7ÇK–aßÄŠvoöRuJN	¦8yZ’Pø¦ešF8•CJôÑµ¾òå¼ÔAí]«O™DÆ‰FÒIXÛn6ZáLÁ“5Šˆîñº2jãbí:Î'‡R{î¬$µÒVğÈuºœŠ‡&èsâ yH…àã8ÅÚ¿7ô <ÓùÛ°ùTŸÓÑÍÕ%¾	K0ˆÈ_¨O2­®°>¿ à†KµÒ­¡£	G´70÷ä¾®G¯Ôuc+§`X6§BŠ#qû’óÒÛ~l
x¡ç±ìb}Ì‡°ôk¤ÒÎœ&úén›S»´>Í€ü#›p
:väAª·Ê‡%¦8Ó›¦ê^6¸'8éQ´êÚ@ÚgQÚ/VO OŞŠ.‰q|eçëZé‰Dhrg°4º´‘‘jw¬' €&z[6s|ßQ\—”$q¦4ÙÍ%Ÿ%+37Ç»}ØâÈõb*Uã[_8I‰ A¸gˆø[%µuO]Ú‚Ÿ¿±âw{;÷BQùÊ|Ìªø/÷Ûî‘Ï»V·rÂÚ£vÓxs" /sÊ{-Q3»úüzÔiÃ÷‰˜§îo:³œ'ú»>±$ûb
ı[e_›‹¡ÚÂfF±2n—CŠñSá¡İ'¥)G/C°AkvÄ¹z¤!éşr1U­\,‡A˜Ÿëšgº`_R³¶@‰V£EFó/é‘~áO)H3ŞÂïr›wZ!°®Vˆz2ÖxòÃL éOıŠLÛÚ˜25–C*Ñ$n>îaïMbòİôŸú~aĞáYÀÅ–9åÕ¿ñÛ E² (D•Wî1‚gà×g"?zÓøÈ~¼Ìß¡óGÎü:«ŞZ)_ˆƒf”•1»`éO•Ûzn‹ÍU¸uËá×Dbg»³!î{£úĞr—ÄGÿÇËÂ¦>)ÓÅ,=LRŒÃ(jÑ)’Îªïe˜×·tjÀ:`ëü¥ÑÈ&Qèa0À@y¢ŸÛ)±!-À|Ş“eÉD‹“	{FØ}PÕ­œ¡ã·¿¦ÓfZøa¡âLP,C°˜ ÉLîhù«µTZGë ë-qoY’EOv	ß¥ÉµØú^œgd5(ï+k2Œ±T¡3ÈèŸ®z# ¹¼½•FlWáw3Çìª€(s#f~úÄ€Bw=¢~ƒ<˜µ´7@åDë©Ïn­¶†Oş"¯7ùÒ±ÒÏÿLº…¶uLR~œà
" yF2âÀRÍ""Í¯ÉˆpVÈW©+v·pûÀ )+9	Æ¤€:;owríIF¤u®-oûÏÿ,àÖ¨ßõƒõğH+F">£²Pz_çgÃ>É`')²öZ)	±˜)/„^‘½#›|¦şÁËú¾%^Ÿ( ‚R
:Šä-*l«±À$ùĞ_4=LÔDXsÉÈ½v{VmÁtÅœA:¨òŞöÉÔÆ¥ŞmNÊ‘*¬ğ¦:¥§C—Fè°[¶¤À9u=Ñƒä‘^4åLø¸2ƒOûıG|á¡¯d,Œõ{ìwübşè×J5Ú;(ÖW½r#ÿş­ÅœÙQ½Şñ¡P^Î4;ëASğ®rR’ŸMÇ¬ÄÌ¡xávºñ1äİÙÊ±àøn‹4†Ã¸î¬,­”¨½eL8İ5-´z—;¢tò¬<‡…rm)Ÿ[SãáJü¸›+¿\
°ëò\±¹İ“-ô#lEf}Î…âœlaàÅ®—Xëñ N(ˆgïL„w»\ÑÜõFÙíU…¶ÛªFAË{X1	}û$/'Ñ'÷‰ÔW¨ò²£€ÕRóWcK¢ \áÆºSf%.·¯‡JvHv{ÃUòNú|!C¶”h¦Kz+ıRşÅeÙyW\ø+ˆ²lîÕ¦×ÿÂ£·_HÄ;±ëİµœ5AôÂ#;Ó
 ?pµf{ÄéÖ) ”F˜œr5×ËWŒğÙv­Õ§MYmç“™ıƒ>Ä®‚yeøq7Ó9î0V'GĞJk­‘º½ F¯~²ä(óœÇı¹Í‡×ˆZş…&&ÉÛ-ån,üµã"q”EQ´íŞHÅ„¹‹‰_kãújc7mX"‰m¯·y“X&ouÈ7Íä‚{Ë†:‹?àˆ±ô´ÒwõƒÔğr‡„„²—Û%ƒ³§™õcæ]éã°ÊØT°p'²\äïUë¸zĞv¾Aø5ÎG¢@yŞà3Ö²#b«üé~“b¿²Âè×<‘SÜPğ†ajìÔL„;°ÚuëZVÅ“À€8ìıEºC#…ÊA§—z•¶/A0ğ{/Úôì3Ø)õY g:,J:øßˆ‡:|½B3M<3²¯Á­Ìk!¨¸²0^ìéRXt
 )‚óÃ¹™¹¶ª¸,1g(Ì$iH6ùã»Äƒ!·5øÛHÌIUñUQ'-@€°0'øb;‰$i“ ¡·â‹—ƒzdÜ³:6âÇC]e¶Ã3,Öµ2èò=Óû+ê¨œ5io5€«€Ş<I/ ¯ŠJXj-â&2¢Ê@ê¤Q{ˆæ7¸¥Óa?ih„áâqúg’ÁÕÛ$i;NàÆexÈ¥-Ñû)Ç4<
W•iG¹í2è.Ï¿#:ôÁÿyy/Ï­ç´c*9ô’ø¨ø#~Óµäs	™mãCQ;ØÚ¸|E%x	Í¡ğ©›wbË¢ï²‰[N"S	åÏ5}›ª¬éœ-ySÕÌ—øéz„Nªğ6îò8¡	+Ğ1à5œqaBÕz Ü+|;§“ĞuvÄÌ¯L? 5’Gv’ôå…H¬*CpRJ]Ê¼\ÚßÖ*©&YyGƒóïúlPÓšïeØL0có×²Ô=PMÒiMÌ5'1X¼¸Ç‘:"¿?8>«D‘bËR¨¯Ï³B,qÌº+\‘j1¤ ŞusòşE|Ö«áßØiœ½Õ¸U³"e¿òY˜P£‘(aÉbx%Šy~­Í¸^û¼Óìˆ;-hñŸwk_´âñvè‹5²FÓûÌ³·ğ)ì~÷wCl"%%Ô¼ãhgÂ¥|j"Éâu¯WEƒ`æÚûX4¹Aë!Š&õ¬Lı#$l×Í[Ÿµ2ÂEÃq«¬ÜÒé@tzçİà©øïâÅ¤Í¤
’Ğá¦ëìüÖpJPbYå	¹ƒ3”k•œ“ÎmÊ+ÂsæÓşi ğ³'Ì+V^’BËx/ğ…±É¸:é+Àß¯qÆ™H€>®•éT€+í¿Ä'ë‚Ğ¯_äÀÆÿ[›|ïŒOù’Kó³Ÿ§LÒñq¾$.].EK¨œ£wÒàa¡œ„sDú|¶œN»ÅfŸÿ
/å$Æ‘~¸O/â‰g±9]Q?$’ßÜûÕİ!Ş¢ÏqWLÑW"—­áşü`éC(ß©d¬¨ÒÒÖ¦µÁÒÌ5±mX[0m=Öc|Ò¦Öq È&?õjŠˆƒû¿$Á2o=­?¢V*?Få¥.31»%‹¶¦ì<ˆ9¿vÓ(ŠT˜hÇ² A6ßÚÔ¹¿)6Ÿ	¿ Ğİ$»ÊÅÌÆ/¥Ğ—$$,¾ˆşM)fÊ µw•¹q	O ÕŒoNv5„éèÇ>Şz©Œ õê0"wL…Ä~Á,LèX‘Š59{*{9éìû1º_bºì2Òr_j^’K£Ú¸íûú¡òĞµê¦€}V[À¸ÃĞåJ6ÆïìÃ.Uş.©$cÁrş¼KêÆ¿ºßGG}”±	1JŞôÈòì°WC=X`¦=³N»º»[È$¼G¯!Y¹{´¦A\´ˆêÌ×o—<@İ‘Sr£ëÕ".h¥>…,ÁB&IæÆ}ÀídŠ!@k„¥n©ş«YPXĞ	²=ºkÓ•$ùıš=³Àwnz1!‚èj´\Á=ÎoHûı¯:¨£¦ö}óæÌ§¨TŸ
š°4
 ¤Öó3ê¢æ~:›e,öpş^½©·Üû¯7Ûyá…çDÆô›•8M9ï\bÍÊq+•FÃÈøºŒŸè®-/yµ?ñ–Ú;«æ/N+FÙx‡p@ó4A]V&øÕªs)xÃ‰v›‚Hè«'|™Rû·÷i8„k"¢Ö.Øùæ)<)ÿ…S>‡§š¡øÏç©¤¶^YFÊo‚OÉC­Ã`YĞFş¬ Ş;›ˆ_jMÃr
zÛıÙ¾‹h#ğauÆ&}]Zåˆ,ÂgaMúû§Hî„eµb!Màu8ZE9—ÒÕ®V¦O™J›Š˜óá2ñÆw!ğµ¤ëĞŠÀ_ÛŒ’¦ÿéw%àí)»(‘ëq%5Yí™B#³œYmhÿigwWúX@òXğ“Ššüİ1u¡Jx®ø\P ŸçâØáÙ‹RRn&~=P’&V^»M>K½)úfİ
¬‰_"„Gân1fP«¾ğ>?ÿ|¬Å³¦Ô‡-£EµŞäØ/„>Ä¢•ƒB‡ğ’czø^LÁ-D^ÔÔïl^TL@¾­¨1¢Ã^w7bÔ¿R‡Œ,1ã(xóZl4‡ùÇ™Z¯`®î#F=ìë&ä†Ít¨íTz£¨â9†¨‚è©~[‡‚t¤…ÊÎİBo‘€Ë p5ú±¶qbòÏ‡¯7è>ò>{Ts»=æÆïY09‰®Ô«v^V@7ò‚©4¶¹HÈ…°§Y°Ù“—*J;ÉÇíøA˜Ñ;‚“"ò*QQ‚‰Ø8˜7(ÇbÇ†Qúl5 «Œ‹.qOsA© ¥ ä¿rĞ¡wÚ p¶ñ÷¾„^Bt‰Úv„bàµ¿-‘‹ŸwÈ›ôÌ¾kÅ¡`hÉ^Zœ -	(Z™œ£Ô0!ˆ…m‘*Æn×Ô‘CUÁ™‚¥eƒö[óÜZ­Î·iœÃ$4ˆ*ûFÚX¾»Ï£ LÆz!Miú®H½bÜ ÛòÆ–kæ8uÒ@Â…ÎV¦oE˜â_ƒ:­ç&YğjèiD˜	^Å·=ºè˜SÆOD$ÆİÄnÒÎEOìSqtF[Ş=Qõ·évîJ\| *æR*¸%ÿbßÈ$Rº
j?¢¡_e¶ÃŠ·+fAÆì ‚¦¯ôOrUUò82˜3ê5àkƒW{¢á¢u	éØ0[…‚iø%ìì!½&ÀW1ˆÃ».&Ø)ÓùaŠşw2Ìqe¦·MÈšVË=jÒ’êÀ€•wgaÎÆIåŸÇª½ØKüÚ­ŠÑŸM›]üQZQ®Ëîş<ûÀq`£HØÍmhú«>GÊ)XšÈ{÷ä;ÅehU3isˆìu•ÍÉ¤–gçmßÅÍCcŒ¢I±¶eœsyU¯ı£¯±x*J¢Ïú‘£NŠu"ÂP4å"Îùzc6î´HLBİù´©wÙ­UåtŸ ×³â?ÒÄãš0ò¤q6AVA¢†Qğ†e
Prÿd6<éˆşC£Z?˜q–@ĞpKí&"+H²Ïhá£êÚÍI G"YxEtbc·ÒŒg¤Î¬¡,Öäáæ<õ^/'íˆ<õ3Š5ªÓ.ÉØ>RDhh¼‹¨¶fÈ½ø|ş,a$JQxî¤Â÷õb$-%'[Q.ÌKB]Wß+oh½Ìâüâ¬GF¨’$ÃêÇş6(‹èÿ¡ßšJÊ{³@ÙA%P™İTÂëÎ·IÄ{ó¶”Û&è'I`*¾‡qAû¦ñ@G{¼cáKÎ×F*šÚš»Üíp©l£e¡“"X+WÕ­zŒ‹q[ñ¾N%?§ÖaxM‘GÙ°ì“(¼~9ï)Î;]êŒ­¹'Ê~ˆš¨,gËhª§‘¨Xà¥Õ³—!ÙßÇ›oŠR
áÀ‹k(0šÌa¦NY¼Ì{òñÍ—óS¤È{‘e-²ÕMY°Â³ò\F@r×ğCŞ3góşVFÙ¾ÿ^àfc	^1ÜÅ‹¬tG;O¾ca€_‰/sğ!¯rÃ±– òúª‚†ˆû™]¸î¨A±Ûzt¨k™¬´!­/ëÆ‡÷!Ùk+Ê‘œ!8Êµ“·Ü­±iÍi#Ã÷µË^¤<~bB5ÂáÏ¿6U·PçZ‹]üa$Zş%G>>‹h¨÷E,QD¢H"çu6wY‹'ÖÁû	WŸf2’âRÚböóÕJ6ÏsãD¡!&#ó'k"&üĞú²Û4^¶¡>KÌ,¸¨€?“Éˆ}dÅ1d[ÍzZ!ê5{õ­Êm#!Oç¡î…r³~Y§y jx}œîóÚÇÈÈİN cŒğJ—¡Z0cÒ¾ıçaé¨£€K’p¼H¸;ŸEÕ/ŠÎ€³|ğæ˜[Ñá‡O¤öáşñyp´õT['õ¢˜¾tŒ¼ë‚·P¼?WÌ_ÔŠÎ0$nev6";9åœJV|<ËJ¨òvpD•»õ¥æƒ?ps¿€0‡™êÔ2ºÚnÅô0_*JŠM9	h©Š#Ñû!}g³ñg(¶¤ñÿæ³×.~à6ìÀ…&YmÛòHn8Ü˜‰SmÁUs9[Òî{Ï¸Û¶¢axY­/Gƒê
ôCµ’i³İ93+JuıÖPn$%P<Ä¦$@ =ÜGyKÅ(§€låtç¨Ÿ‚EVeŠüíx«‚ÏgK”-‘yİñÒÆ%V÷XHŒî`OçS«¸îùt‚•ùê#÷Ë{®²p—üñ‰ ~7¼*gâà•ØC’ñçâªåV8tYÈS[?µ~ºWáU§±}ƒC¿Ÿlq=mŸqHı:JóôÀ#ÜwIˆ·ó†äh-ö°@èp½Ã §a¶@ïËG`€;5÷Ñ!¦ÙMÀ°Î£XOô!
(üºP-Gİ½¡¦0–ô9FÍ:;>_B@ÆºvÔ÷`DÅ şK6U^ÑV«€ù“G’¯[Õ]$O?¶qÔ.HÊUæ}*6«~®…d™€ŠÊÙÀÚ yraXÏ$”il›¯Œàrè^Of0pş–PØT{£ÉÅ¶ÇüëÏö®&+@Çz"Rş'KEt± ¶ƒÀz†»|5·ì;“—ÜrµLöãëSùt‹ë¤%ƒ$üÚæoN|á¡ÇÜU1\PLÇU4·ä“ü²0ÄBTqíç®ErU]Ÿµ¥ ÎVÄ‹şË'Òj;€‹t+gÌ<Pëü¨*YŞxù1à¥#Û‚	ì¥Ãp»±yßÌü‘%Â¹h°”mäTS1FÈ<[÷ƒ™q?,ÇÃuøOV)£—+–P=ç0;úÆ–«¶´ìà3½fƒñ>1Dbì¿Ğ0“×ì,†ÄÔepŠE÷º8ÀÊ"èõ¾œt*Ø›~‰ÆYÀ;I‹º²iÓÏ“¹ş-èŞ…|ñpÙê*rÿÂÌÿ$°lgóQp€“H1Wm^K¥Èõ›qyºJ_¬ÌbQ¤CJ¤^,A{òÈŠâ89š VèßEC,œ«÷[UØö¿ÜíÍZ©ôIbÙñÚšûª8?æ4™`aGåä! %œ˜|·ô›ŸõË¤ƒ¼†Öâs" HÅæëğı*îìƒ|LL%s§\š\7¸Îu3Q¥–ë´5NœfJfÑòö™€ğ‡š<°›'Äf®¯=vTÈ¬?×c$İšñqw´ˆE| K<F E?Ö]„Osl®ŒEÔHĞf-VCmJÃ9éÒSMWõ±´şpUãr“W"ìºÖ5LeİƒşÀ·pzœ˜U¥cß³dŸY†]â«ˆpÚ–æ
¥ÙÁMĞj™«0›RÕŸ[’+4?ªôO´Ãpm¥ çêÕúä\I[Ù½ÖV-«´åğ PR>* MZ——C&›¡a]È×˜:¼°æK‚•§ôÎá|:J²º.ŒšúÇ†"¶•L­…{éHE²…Şw1/J¨Yç§¥gZÂ†,M³æYiøĞQ<hõ«Â²
ƒİSMxˆúıºiëgT=ÀfÙS¸z&ºcYÆgş¯j¹b!7*Óî®²3ÑPQæV1ÚAÚ“âeñ¸ö](¼#pr&|0(€*ãbÂ´Tku”~¥.ÃF’~pÊo`ú¾åf“ƒÕğ‡?Çƒ½Ïä:£â¦gA«*î™6Iø“Ã,'§l-ÿóáRá„¬ıESõw‡ 7e¶dç35~ÿ’#eü˜‘ŞuNõ3ãµs6ëWÖ·+ˆCåTç'åNÓ:qhåWuê{'¡X²¦úA@è…1[”¦[•¤>O¡Ab*ElQ§Ì«­F[…ıFŒìŸğÆ{Ê´a;8X–/e[gGYãEGÂÅ®q¡­…ÿ/Ÿ0×wªÚš1å4¥õNì¢`üÉí.è¢œ«l!dxÚöô~ù¸¹r6a¢ñ>c+ZI™$,¤
7k+¨˜]áÂP¨ÑŸŞh¨HHïÚ‡,îñà“ PPÎ™iƒp:;(ÎÉy7,zÿøg_A\1Sø£|³,Œ,gº ?PÓBGÑÂ/¤(t0†Î Ø©Æ Êbßq
òrˆäœG^0R=Ù#™2· ¨•Q•M¿w0"~v$Áy¢ÉT‹Ñ}|GX½ŞUÂ|F™ºí¾{¯Ë4YÍ£bZØØ
ÖÚ¬=ŒØOã±z{i;¾ôÎ½t[‘2è¨!hö£áÜB´8ãn;ŒÖ3{ÿt÷\,i«9öÿİ#nÀÑ‘&˜|æ¥ƒ>«TÌj®u88Ğ³
)ñÇ´ì’Cä¸­7õma‹F=;/¨sç/u÷Óæ´lù?ƒ äRGwÏ~x'ïª <ĞXy¤Ö¸D"¦Ì,˜–ÃjípÕâ×"–ÖŸ5“ˆ¬çÊÚœØ»l¥á;$¶Ğ˜kL[ëÏ™	sFz\J=(ÕğŞ r1]ÂoÚ&1àû½ÓF¶	ıx
¥P²œ½ÂÓ=Ü÷"÷ÜUˆ‡ö®	‹í$©Gœ:}ÔVFSHy¿¸ÎÇÂİ˜àZ$¥ÖÖ«“·²@ºˆ>õ.Í—Ö8j’ÿ×7ÔëÚ’<3îÎBn"¿:ş3+ÛÓÙ¯&Ä¨hcµ5F‰<ğUÚ·‰#ÿŠÕâE3t`®¾2Å@`ùx‹Œí¢RÇI8 –KÓĞØÚüRwAìQHdİ]ıK8kÉ­dm„ù¯YUˆ=ÿ°`!H`³dºÆUá18
™+&B.)ÙéZw¶Jwv‡Wºé®ã€ +sÛQaEbÒ”>à×ÅÇÒŸnğ@«Ú?+’>‰_&÷ „¤o G6}öº±³Ş9æq/¬UF‚éN?šZñœ­˜a€^ô”˜§Ğ«½fªÃüõzı’¿!ÄÉQüäZà|d,®ñÖ\XhÚ+[¡©2¢Eâ³EØ£ĞÃYú”–µ¾?®gg¿‚¯øóäÀRCØ¢øÕÙ/û8æ¼Ùñê¡Ÿ©a8^wÖK¹ìæG@gW~bõ@Ç ÿ&\„ÏºJxbà(Üèqp7>” IJ†£B7È•UeÜì¢ø ¸{ú0›ùüäôG«F-ä%Y”YF%ççö—’&²îîÓJØDÛ®
«K È…cÉë8WÒYÌk}ÍQ¢dwH›Q3ÓvåYµ:m²’A}WÇbE¦ñ-#SÅ¦ï§"'ª!9;‡ÌÅß‚ëL›®
flÔE¦/ş®NbÓZÊCJİ,¢Q+Œ*bõ±]x„`›¥·âÛJÌ`fÜÖ(d“<‡@‚Î®+³‚¹LÙ{+b] Z öüŠ‡f~£¸ÔÅ™º›ïà„jÖ¡t£el=’ûB¾ıõâx“ «¶=xZC­uüÉ3.u±æ9öĞÂIÓ`òP6„oôú,ˆµıæwd.ü“îÀ«J igÅ²ã‚³§ ‹íhñØ:äVY
İRRĞ¥‡EÃ„{wh]¡/lé?†¡¡8õU-±iGcsÃb4Ê~§ÌÔ¢˜oğ¯€A¬Š@[İœö]á‹ÛÜvë1÷“Ÿ;’ˆ1ÁÌ6¹ğ@yÕš§&İ–9iâ°ÒDÕ»©¦¹É,     Õ`DôÂãÙ ¥°€ğùd>±Ägû    YZ