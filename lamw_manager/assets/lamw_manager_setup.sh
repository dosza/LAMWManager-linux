#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3069260278"
MD5="30a4f18d59cf498a53e847c524e8ab28"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26356"
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
	echo Date of packaging: Thu Feb 10 18:34:18 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿf³] ¼}•À1Dd]‡Á›PætİDùÓf0ÛÂXPûà7Š:	`"pòV^@x‹ÛfÄMw9ü¸W9ıUw’g¶{è”ßy!ÿYê´n–ŒövHÏ7ó¸¯ÜÍ¿VUº—iÂ“Áö[%JéR×İ¨ã¤6/¡êR”:66G×¿˜¿ŞA­—‰pD !y”ãÍoµ¬ æ#'¬ÈNÊÿ«…İ¾+2fsjú²Æ?£ã'äöZPv¸	ÙTâw~sÁ£â?şÈô)LöG«K/w—¡PW6ñRlîáèO#œVÕ@Ô®’Äº{M®$»C>ÜÇ`é¦™d.ÉC3õX²”o`ïX™Âg´§„ÏÅŒöì¼á¥x¹wŠzIc€D áä`2ín=6Ê×7O’.¶ƒÁ ,÷p¥ğ# Ø¿ã‚	%IhŒÑŞœĞø§9s&d½¸–M©¯9sÉ‰¹!+šÄi(9GÆïkæ¢yEgºmÃîB+wß1Ã-$²á¹¦SrİZI*_óÇy;õ7YÑ +]k}Ì³‚c¢ÂÍÙ?3ûN¢ş>Ú%oï¾ÊÃƒ&ïpz(7âğÛ´Ê”gEÊm£;F±Y‡néÀşT—YĞšù$¿s°h‚:ë+¼yÑ§ªéS
H!u_¶Áâ‘…r'š|¡yÑŠÀ§h†VŒBÔ¾ûÍŞ¬(ıüµsÃˆ‡‡ò®»T]÷©dĞ¬„-ÓÌ¯Vz÷FÛH¼…U…úÛ«d/6C®…¡ªÆÓö1µ~>!»€¼FdõÀŞ‹{b1ÿ&±…³Ë÷tE¨­@'sÊ+Ë3áÏ¾Ê$Í>3æÕ8øé™+CX[<Œ‡.eÜWøäÚÍ?Ğ?Ì¯&Ù¹,'ÿ©+æ4Äa³|5öÌ× 7ôÍ‘ÃU«:a]•Bb»¿Îª`~µ=QNÜñT]|GPµ¿ş·Ñ\;ÂªÀgõ)v!-B:Cc˜æœh*Óé~ºòa£ëq*ÒÌÕÕ^} Í(q~¿Ü¡¶¤"ZËMlÒ_
'<«_ßA¸TìÏEÌwSåŞQ—ñf*d¹à²2=›O±
ä}j–õ´öM„xî»¢¯Kˆ‚»ö¡ÀXœ£ïÁÄ°ô>È,yd6¹İìmûŠ×ŠBòßTôƒX¡òşåÆô¡Ar¡•ë5Øš¢?-TÓ'ú}­”… L{oòGrÁ$#xŸ¤g‡Ç?—ÀibMÛ“$/·ŸŞI6jÏö—A[{—Ş‡‰âmeqá`'¶‹]¬„pmb›i´Ñv8æœ¯WpÊ×áò?jo>HØÉµ·Wp~V=ˆOäw=’^üë )ÃûÃ¾ÑÃ¡
ÖkGıCæNäeu!¿`	à ó¨ <2¹¶§#0ÀØuP«¹}ØûÎ¡°=QÎ¶êråğ4ëÀødgúc6ÄQæÁ/áê&¿;ÌgYÜë§ã@éá‰L«‡zÂ·µÛ>²V&ùv[iIfe›dfù§K@.¤ïúË¥4¡Œs‰5«şÄ^ëŒ]o²ğ˜~xÆ  31¼ÙÅÄîrD	«óı?=e¬Zí%¬Ğ ªÚúäÃ^ôÆHMµ›(¢â?’Ï³kó>ˆ<Ö—¼¯H‰h0å²ùD¢›ÊùÚÁˆ#Ä(¡œ7OÛëŞëîC÷ÿ,S…7sš¥dî+?#Á¨Ç|WŠÃ—Odí(kKù…ªÆìZÎ³ar„¹ö™+¡z¿9»	«ICİ‡G¡É˜ßœÖ[Á´[Ó0¥DÄåk¯9™ÍØ–ãb`ÓN”æBÄÍËÁñKJ%¢·ˆga­Ğ?2L–¾»"£'~ÑP™‹“5 éßÇ][(B_@8§Ùß}ÏôÖš(YÏmmã¡çñÉĞ!)§¿’‰O¨d×bI.è5Ç£Xk¡Õ†!‡d6ñŞ»ñö¬ê¿¿û'˜ì4DÊ8Q~ïåp]7RáÛÆiÎÑ@r!Ÿn*UL{ï¿êG·M÷=måY¯´0”¿…f@6_{ó¨;‘uQwà;ANËìI¿VA²M—Š7(d‰Özï2äøkÁFX*—a¿¼±ªéNÆgOËZ¾7²®èsU;x'*õ,2ìá1ÄğuLbAwÕ:]J@O[*t­ŞfŒ#±
1PÙ‡İwN)Ú5ß¯cúŸ0™6rH†„"LcCş6¼Nöu…[‚¡ğjAUh¡kõ>±2y<üºS¼pLÅ‹Ğ¾íä+ØÔU‘HÜ/£3Wİ»j-Ztöø›5S³ú¯{2§F[Âq_ˆû:ˆTU•^<j­†õfbÑ•ÌT €*s£JV·İ®¾ğºà´’üş]ı^[ÓAß¨ÍYpqaø³ÄUë¡gÌ·Çs2ëmåÕ)(0Ü°uÁ¾E™ƒ®„HhBJßƒr›:”£µs/j¼ìû•DógÖº1ghFäšµ_õU®(ÍÀH1sÅã‚=ÜA6œÀ^¬·:Óä=ˆKr#F)€ÏÈêÒd¦¬fCÛL¹ˆp¼5W†Ñ.5BHw®„œŒy?âPP9¡9ê^ræmŸÆ%}ïôèQµ9heoÄ@ÓGÎÊÏÏ±Ì×p]wn~H/7n­{MOa²N·a#…Øµ_,!#™"s^sM¶vìÉ½	)ÀŞf‡âa†˜,ÛmùWÒf—è¢ôÔ³/Ø+`IZTrL[(d®”£"ÒJÅ˜ŠqÙe´ûj¶æ$‰¨‹m6ÔRıít—Gy31ÑXŒù%š¹r—hlk 
ËIÂÖr$Ôg€éü]qrXR11”­îª :#mËñLÅËö/3OjÚe­¶¼'NT+ŒÃ&†•~üm%Æ&½œ´0® ?¨;øÀ=ü¬b“B;	u˜òÒªw»°w¡P[gjøƒ·º”Ğ ‘Ø ø‘§ÊÎ¥ü¿w‡·9ùós·Š*tñ¬gˆÖà ñĞ"qŸÕ®xÚ“D·şz!c :‹x‡0PËW¹*ô½n¢ÌZíó`H9“‘G22ÖÓÑC²5Ö|	„m€\¨x ì·À“e†Ò¤c)¿RufÃ…«Egñ:ÿç£ÖFú“ˆv-NşZç°Òı[Ôò;Fûí1*6øOaï·ôJXØ7«ĞF"¸Q <¹Y¶¼(ëLi/~ìû R›û(À7æ]`lÃ<n¯5wWü-=<ÚnÛa¼­Ãö—³?·m#‹ˆÉ“ã‚É–¡–nhÈ(ë`ÏâEÉ‹ZÀèâú)wµ³LÅÊ˜lŞxPÀë›Ù§Fw:ky£Rñu;•½w{©iªÛÏYú¨Ïí¡kA+øœ2xÿ² ~ç\õ•
à•ØÜ?Û İ,ß?²‡¾z±Kğ‡ÖjÏ¯üg âÙ2ğÉcûdÖîP±Èš³¸[õ5ÖÅxEŒoOgİGT}}–sï>Œh¶úCÕ3…ı“eHg¸ùÙÂy˜H,Ò…/úë(ÿçÎYHa#dü{®¾Œi¦—«›{ä‘*Å|½†(´lÄ3V©×k¥¾õfCñİ?÷1ñ}àû‹”¤¡„õğ½¸«»/‰¾¬¼ dV=5ËVLKº€¹ tÇ¿bØ{]ÎM¼ë¹RØC®˜á›UÃ§V‚5¯Ğ_V`pÀÄB&é•œ†(ËËİê~¤6?o¶¬Ñ²û÷×eFvA‘ĞÎ¬uŸº…ekX•qÃºŠ—Ps7NhÑç¯cÖá´`Œ#Ø¼b_8¾ûoÅ 5&ì:BÎøi.KG&XLÙ­ğO±otá=´ÊË…	ÉfFÑå7qj±¼ĞÖ"ˆÿİBw³ÆW9ås~ÇWƒ¶'2`Q2Ö1ØÉ³¢ÁÚoO ß#{’‚BñààYtFéuØµòóœBâsZÑçpYÔP¤Ícr…×ç úXÛÒìïàh@Î6fp ¾±kÅè‘aVnDkÃ”äb‹2M+ßK`wä5u à…ÓO$ÚMs—Ê¢*<:¤„ Iv­ÃÜ®+Éù-{ÿGÉØL¶"ÕÖîÕŸ—¸xâ_6~Ş8{L0UGr¦¸~¾(Òí‘|¡ÿÿÎ§F”Æ›N±ÙæÖÈãªåØã:ª¤C2Ìz¢(y18ú—ıgVsÒò]ì&ÜÔ<n”ôø<ÀN$µİ¾ö\¶¨á¤ßısfr^Ó>»Z­ÏaT@â«7‘ò!¤!y£èäÈıÜ¤ìV/ùSÖÕÜMêÌa®&ï ëÚDîïâETÅ`":˜ÏQ¢´mË9jè0hz(½jw ”©Ë%›–eîF#CTwf¥RÀ„VHA÷ùF²İy~Š,Ôa-¥…©”:°™»í¥-àQHBÁ+-W“¡Œ ö#ß´
×tê‚<]¼QÑn™Z`B°QXªÑùè™‡kwMD¶:ÈøU2oî:¬’™¸H„îuö¡òï¥^8‡ô¦~m;ŞÄU+™Z³›ê2şnïÈôBoJ¦R*»¥Û¥&§X¹ÖÃçû*bd†PŠ¬ ’_Yéé›¤â¼\ÿîIE™ÅÂ94å¶uœÉŒó~CiØ-»:M‘8I=¨ckª=]‘“¸ù­k,
¹Ô!wz"ëæ­„º–Óƒè0;:añ úl~¸C?1ú–E³>—K!ªÚš«'ÿêì©Ö iŒ|ëıa–£Ş¨ğßÚÀ·Íƒ4Sz›‘Ó¿Vöñ.nÙûÏúb
şá¯Ğc[§ö;ÛÛP»6Jüïâ?ŒŸ¢Ø'+8¡å>µQÅÑ {Cß´zú]È˜=Ù“G¦QÃ61~ş$r,°ée¨'Úì}Çµœ‘Ã~‰h"ñL‹zòŠ‡E r§2pYàİj8§ËßXG2·gÈoÏ ÿpÖ‡‰RA(Y	ÛSydöí ™ÍQ¼ëSB[‘—ÅEÀŒg(y^Ò~ŸQr¤pùV„¸>àÒ}î\À!ÁBĞYCšÙ+Ü­ô”{™xsèŞ‚ØÑ6ÎpIƒg·Öü4UÇ„Á§ÓR‹Vî˜|­2ÔMRP•?ÔÅM8Ù“`Ld'Ñ”1¢WÈ³‹ÃÅîaD'¨Ôõ¡º’E¥B_vP0¯¡ÇI++ï¢hÌzïsÊ¨qCäˆ~¾©cöwKÙ=)²/
×GÖQoøí&j¥õùCÏ¶nŠ<s^!®Ş†”Ói¾¶&—Nzåc~CT›€ÇqAŸÈ©å~²[ÖïÒ¡ÎWºáÃäÄ„§£XúEæ¡fµWM”İ1ÊZ=*7qúŞ3³Â´ÒØ!W-À°’6”ÊÀ“Çì7øO¢3ÂşlI¨µ@‰”¨¸KW¡+ú4«ÛQŒ$³?XÒâ£Q?¢ıMºÆ Ôp­xdw{A<öĞyûîÏàlı¥-òĞÂ»à>t(qn&Z°É‚6:2ï¼GÚ*}×c6-‹ÏP LU>‹ŠY7ò´øx3Ùì-ÅiFbŠ£ë™‰Z%è¥¹ŠÇˆ‰ÑÛä‡½zÎ åFÂ'yd\/C{İª,”ĞÑÍ‚ÙHX‹n[ã™´)Ş|t¦3ŒpÀXMKÒ²å±I{±q½¨‰YgL‘Gsg._ Q ÒÑ<4ãğ:ò¡®`ˆs–·P1‹Nê¢³™Íš›ÄıĞWÓè«*¸/ÁØ´ie8¸‰å/t	óJK(èD!Vö³ú‚…äX™Î6é,Êwxg_‹?¯]¿Ÿó·{N:¶9Ù¸Qµ%%î€“cƒZ‚İ¶·½~"¬Á^ÁÊDè~fŞ…Dğ1b‰çû±“KŞìÔ•­SÚSı”îşãõ†:ZÙ´CÑqògjCÆ•_¶GíÀK^¤ÿùÍóR-?`Cš?³Ğ»„! ÒNmÚ¢è²ÉgwJZ	7L/æêQâRQ•Ò2¹U+mIa;âë£©:¥×èÿgş>È„Ãåä”G¦>Ë/Y`_¨šÆ<—Œ`ıÕG<7Xï wJ´Ûê$ïT“9^-:¢Æ`*`´ïLºûø.M¶Ì¬0æ®ê£j•¶U¹]yH¾å;ïØ©4#Ù.r¨Nî&»o19¹ùèœªµ´à½€[Æ›#OT7ëšJ×5<Œ+_©e¡ÔpÍ9GZİêÌ´™i7,‹úN×)É7å~4Ş¤‰(Èö~Á®¿hûºXÂpÒ†­¼B6ô©ıÂáYxĞèUmŒ}Ä,Á@“ë¹ß^°	ô½ÖP`'Q*íhê¶!j¤“
–°ŸTQ’w?”éßÈgÛ«
\­Áş•[†Œ29øç=«Ùi¡šS+×Àdpåê;x½	‰Ú#Æ«MÁ]7.ìî'CZcÔnéÒ˜9iŒfGJïŒDæÌkfi{±à­öx‚ˆD4Çä“ÉÁK#}5!dUÉÑîîp#$‡Ì|m	¸¡9¢²È	i	ÕıŒ+Ê=âï2in}"ª|ø‘1R¥°€Z'kÇ®¶a¹O•¥ŠÏ¿lrõ5è'>ª{Qp$Èº4½Ôu™­s¡@Òäç¸­q ,CÂæÿÿÏËAp<®”] ¬ã¯?ĞåG½Ñ—¤ÄÁ-¹­Á£:ìDÓÜâ{²™qYéèç@îån‘<‘tèç’»à:å0à©ÁX÷W¢8ûrõcf“ßîT-¶Ix©EˆŒŸ€üûL«úçÀÓ€Ï¬gÕŸœ}÷©¦lqáÌf1¨<"CQdš,D÷Á:ïæÎ.¡ª1(ãi¤:–ä?işE†I$R‚M4À¨
ín	PJS•eCåÁÔé[
«'±’²G~ß}ìv›ö	ÿÿı{eYÓ_XÕj)Ù^Uîkš=
uÛNÚ«Í¯îß^…ú¯§h}/<^9Š–i"ïú›é„/¨w [†ÒŞ=˜;s

­DÔ®¯Ã<.­r ¨¤ş4Hã¬!ïq‰æNT(vÄ*ªÄf½¢ız‡t‚MA×5&w˜y>—¬grkŞ )»_È¶¼:E' ?÷Y0ÚEyÑSã_q0Õa–R‘ÿFcÜl)·aázÄººßğ;µ“QÈ.§™×ûŸ±)¡J¦Z²ÓÏdI‚†Ÿì÷oVjëZzÓ<µ¤¡¼İÜA=ŞÃ,÷mk¤… "Sc]5ƒ;iÀ•X[ë0vv¥Œ„Óş$Át8`	mhèdqyrÜŞ€8É •—4}ö]æâŒ‹I´øøÍÖ‘H{C#eÕå£0¨ôÔß|7µÕ½¯$1 ÷–Fnt§æ_I•JNä‘s4¯¶B¶ò<O£ÔÿP²ı·ßãÖ¿tt•k†¨î`_†±YÎ}òı8„E(í}%­Xà¹åÍ¢PÏJÓğ'ÿo—£¶§ÿŒj×ÌØoe÷ş£©3"çâñ	†ÆøÖ­—M‡Ïk[Ó ‘wºì¤¶	×0Ï)G^Æ¹Õ…èq7È‘y¼´ö"í|LOµ ĞÅÔ¦*n	(lAA×-­$@êWRµ:ƒÑRpf<4Éºª­ Ï“k™ğƒúo>ôß `b?ö(zhƒ§·M¹—Ä]Ë•Iƒ|Áò¦ƒC¨NÏÉ~íÀ	3çQ“8i´€FíJ4‚6Ö~ÊÃ??Ö„hMbc­01®
eFÜëOU˜;¾|«yn¼â›jnM9és³ÛJÔ×9êW´ˆd¼—¿ì©g€FìXCïi©ÚpY›p’@NæùÖôƒÃ§[”ñ¼Böëûš ¥bnÉ¾½–ÃW‘hš°öÏ‡G£áéŞ)æpãY‡ö*vBX3Iqúæ–N¶$EÃ§‡™BO˜ÁóÙ›YIC[HüäGƒs¿>õeø›²W€z9¶hbƒ}8˜PjFü¥¿ğiqû¿¦cö0™hˆ·CĞ)ŸØı-¼·—ÓÍÊ[üvÂwVÜiàbÌ› ùŒşç
õ>3òE„\ñåÂNÎ¾i¬A¹Çßáå§&åÏÅœú¾óßgÀZÇàC©X"ÁÚ‘W=¨¶­Ôï§.º?ÿ‚4ıñBŒ‹³ åÛÍÒËwiag,&O^r¢dÈn@oF5vuQ†b`›·l“ÈÌb#¡w+=&ØÚ“Â˜µ†Á{PÈ‘ËFn¸Ú. ¶QA’›<¤ÏnNâ4 OĞ³—ò!pã?ºe«Õ9½ã7g¯Œ’íğ+ E˜*Y:§6’÷ĞQc³_ƒ–ZÛ©’q§·<îàio”v²h÷~7şu§Òìåhå*;@''Şx\¤˜G[twL˜Ú~â¦YAVË'îÓH'+˜¬EªC9­ælµŞ“<Wl_º93Úéş‚æ 4*ºKĞ-doPÛæâƒü¹M™›Yé²ğTš¬Ui§‰hnâthƒA(Îm0ç˜ái?oğùP¤£€	IJ’}ûÚ|rD”™Pl¬åÒF $Û—³ti9³„yhà*ò-b‹qcCuln…ãÆ6§§;.šÌiY’2!3Ñ¬›áY@~Ğ	^åƒŸšmõMøeÁ½°ßˆ+“™$*0¶B:z(KP6oÓÑ¥Ñ‘]ğ½36[tÚbgÿl„”D{ze–˜`*è¿zìè‚ƒwúi3Éş€	'j¾ÜQ-Ø»ÉwÖêp¬ÏÄZˆ"r,E±îªĞ½Ü\¯ØÚÃ<¢|ÅDï
ÔD’qº­ÎhGâùñq|ÆŠ{ßõgï†yÚngX l}É‡Îls
˜Ê/Ò
º][Fô‚Ü¬@†µí©Õ…uÛ‘E¢&«V ¬i°bâŒ'Äê52oğe?¼á…kiŸÓ®œnZqî©±4?qê ^Œp/tuÆlÎ½Ãª"äŠõ¥ÎÁeÇ^Ò’†Šl _‹ŸŠO*Xë¾kÚmı1¯Ô[ÏNÄf:·h÷Z’`BóHb°rúZ'5€Ö”Ú]>:É’ãäÀ({š¡(Ô+8#ÜÜAîÙ÷Ô†½'Í^õ1œ˜µÌyJµ´´¤`W	bh½?|õ•¤*«ÛyCÿvßH›°ÀãiÄÿ9ôVB½^­&È¦N	Ây‡ˆç0X„¦7qßa^©/·¯¾£¥Sçt&	!È‹›-ş©-Uóº¥L+æåMBƒBDeø=ÎÎÇ¹m.ºTı¡É S]S@Ñ•;Èzxg×A+\&´½z
N›D+ SU)/O6KüEÇ¡N‚â9í2œQğ¼çş³´Ö/¸Æâ‹§Zì_LÀX¢ƒDúØâ™'–ñ“A¬ƒ|¥J‚¦ZŒJËÜØªÆÃÔ7zìÏ*g¬ÀX?uİ‘PüSÓ€½}ÄôŒÎ7øÂ óÓS!#*¾]]ÅĞ½6•B0£‚uÀ`¾?S×,Û“€aMq£ß0jI„·Ë»¾ˆ²oNá(ÆĞº°^Â/w>>BıŒßÕéêIÖ>ÈåŒOdÛRf%¹Fíjä‰÷R=hBcê¬*qIıû%öıŞ”Äá0ô Lôbƒ‹ø«ZA¦T$2ÑïÌÖ7vÃÆQ×9ÌåM íŞ@giˆ^N„ğókQâF‚T
È+å’»l£ÛÃŒ[´yº×Ñ&Éá&.©~©\§©E ­÷ H‚søv¬6ç¹	éi¶Ã«ğŸíY?éñ-^KK±[”ëğHå‘ZbdõĞ£Ì5"ø?Âæ¼ŸŒ’PÏdJO¯\”™':û	'G
üZ\][Íÿ)Ò¤‰M½(íÂøÔj)RŞfĞ%`rG0ñúÎów[ŠoÇsÛ!8¥ÊÓa”ç¥ËÆm­æ5XøT`¬1~Ø0f•Ú”–S[ëéß¤F_¨}€f‹AÃu‡›¸Ññ—™AÓ«şŒ‚Ö•zrÑOÔ¥³‹\AÉe„âò’!çÈC/ò«¯	Pañ>åäx/¶ÓQ¸w”Ã{ÍÒ‡ö({éY,Ço»5b²»Iü£nO¥¸º‚’8¨©¼±iÌî¿#*ÍjolÇµ ªLpY¢¶×<­)‘§Xzø.×Oï„mwşK¸\P>óú;‘ -ø•´ÓÈ/{w8y¦½Î‡˜Ï‹]\õ¥:/¹j˜&$ãI²·rÒ…éÛŒPÅù
\Fİïç¥<À~È^Ï­¬?Óm•$.òRù4âtÜNwš¿4;—:úÀÊı	áÂùEà$€ÉĞ@ãf‘À¬V+Ş~¦êõŠ=¨#/î@ÅÔúNĞéåz£’'”½J¯ *¥M–ì¬şºÓ=&Á‰>ûkÅ0Kvªuå_ÇÕ‡ùkƒ"Òø›½T–QhÄ6“3dTLÕ¬è¶r\$ZŸèåÜŠœKèSÑ·ĞÀdm èA´I SİıÈ·lÄ yËÖ™à^rëßMó¼$D;¼y™efCü>µ"%*)Âˆğ\¹­QÚŠ;3i¶x]Çõ•õÛ/Ó¸ b)\”¬–cÀ]*è9,f:îÌ6ç
; *·fçÙÄS¢~ıYIiÔlÑÍJaküù‡3°¯Ê$¸¼w¯©y‡¿¨’1^³2ØÏµ†`‹ÇéÑíÃ˜ŠšeøÃJ~
Ttï0e¸Ğ»Ğ>Vû„b)[¶+ÒEñR¹Ãò˜Š=¨²¢")‚Îrmè°ÊØ÷†àëIµ£êÊs‰‹“B½_	Uz­± Áñ²}é»àŒİRA‹r}<m	 ÖÚ@AÏ¤ëÓÌâñ¬‡ë~…ÙM9î Hİ%ì…V®:a&Çs}.üUS¬K,š!{?‚eI£š8}=Èz÷'?zôMin¬~¿¥¤¸!V¦•å†:$=~- ©‰óWY.{Éôâ,ßˆ¤÷1ƒğÙ®Z/]¢P*F¿51«Y	›xsÃ£!êXAd3bgrGİ¹>ç”‘ŒpÖ«oïƒæ¶_Jm¤·ªäŒãg7%ÃV,r„VşEµ;”ò‹½E.ìê Å,]A;şË–QôHó2mÊtñ¢LÔè!<£<ÅQºT°Ä@úÄçüi³üŸàòNCš,ÁYw”ÙAÉ¥´[_êçAR¼O_yWQÎÂ2Àó·Š$ÇîáÈòŠ»–õ&P…ÀêÚ9ÛË3qíoHoæ^;ğ™]C‹¤|=ÓˆrtJµKpX
ŞÃÉÄä-«-øKŞ¯7Ä¯£ô•5%Ót>Ã(Hûş£bc³’2hPABjÀÅĞö²¾‰„7refEØ_«m®7WÉJ	™üO‡kTwíwÄ‹à“&•Å1@0 /uØÚ$‹óÌFª‡+EM ÁEšLÑEníü[û­—´o=" ae)©k´èYéú±¹É¢ÄöĞçÉuÆmM”ÔÜØy¾b’ÌG™Ïëçâ÷“ƒ‚%eá|ÖO«lBG¨1ØbÛ8Y´ÙÈ\„Q°-w8“×ÏY³&ä¾45àQß¢›;/:†	õ;ã¹uí¾é‚iô|ï³CmF±-:HQî²Ê¼ırEÀ0.Œ¹?‡:ˆZıˆ!Ü0”»7³2Uí#œG|YXäò;&Œ€#p#)ƒ>‡ê@µczÙ=ÇÖbcÚÍÜ¡ü¦ŒBLşlo–ôfi¡+Swp-ëˆ<»$•‘í¶Aõwpë4497æ‘B[|[²>âB&£· UŠ:.hìY"lìİW0Ø¨8‡vğ”ğ›¸ë<ŸG`.³0kh«ËUÕ*Á4¤çôkPï?4ñK?'w£µzSÙá¸»6ÅŒ=Â{ø-;Z Š£îV“à¯œÏñ7q”ÉWb“®ØÔ£íÕE„k.q±ŠôÇFÙÄ<¿SÖ~›dµb¾º3T$ÄŸhÙ{÷Zìä³îWÔüœ9†iv0ÊXÕÙ-´‘—ï~«
ä®qü
L_Ñ 
ı„üƒ‘›¯Éş°´¸Ğ
Y†ğ‰Ó#‰`EG5šî-ñ;â#óPÅ°¥ôÔ‰nö¥Sí¦%}ŠÅmEBÓáºT”´%{ª«<ÜÚyääÁûBÓ•"Ÿ|Ê²;MoŠ[=áş˜mª§qóº˜i¨™•¦rT§b­İG…rÖ/$»¯67Á¶tˆl'@ÒXFÅM|J»Ú{º©_I'÷¨¢àµ©ªD±£u'{ûÁ
eù<B:FÀÚày'¸Nu¾7ØEgô¾ôÀO—šs!ª>lñÄ@r£ZîÍ-Â2÷˜/m,è+0Úg=eZ3 3LÀíĞÏaN—hbÙâU?pÁÙŠì«*ãQéœsûĞš“Z’tT…wûÉg…Ìt8?¶à²ÿ8©¢à»Ó.ïa••ª•ßhÊ$)Ëšeöí¬w$ïw¬zÚq	’´4k³,ö™±~—ßƒŞx%•1 ‚f_í”aO\CåKTŸê°ØzhøĞw÷ä#·•<“v³@dô¡’;]â¿gLÀş¸ñ?BiJÅV˜œy™RQšO“éÏ|ááU1|]8YÓ™‹foG›?Ö O°üäé…¸:YÍØ¸E¡ "‡Ç Mu±]äßµ9
F¿b½­P–©çD±û_&¤Œp« \,<Å€I(s§#D‚´wî¨’½ÁšÌÈÓgİâ:Ş;…K<”I÷ò“¨–áí’°’VúA|ÖÌp=VG&Ÿœ¶¨…TìÇmğ«xÑ.óXv@<yÈâhî7ÓÜ^…µ©‰´RTëĞi#Ñ“ŸHL&§OáæÒ‰å¤EìòCÃn¿Á‰@>a4mi|>_°ìy´ªÀLå#%ğ²NÏ§Ó[ŒE6é”ñø}òK´t<ø‚°ÿšŸ¬æÚ9Ø”ÊóTË7‡’-ŞrRı5è+Ëˆ-UóylÃ{}Zq`i1Ñ@HX6`è$/[ö–¼:Â;n_	” Ã¸´¡a¤áÙÈÑPRŠü™›h½0ãáGieˆü½ı(ô[×Gs1¾Ä‡{MÌD´ymtuˆïØG»…½T´8—øh›ˆ‰©Åqé„ZŒ… ,ÁªÜØîr\^	¡pã@íò¸Kİäí¯R/¼‚X òˆ£’§ºíVL£X ±Ö	¦$¤MD+%,»JÜwL§­zü²¿vI5ÿ0·ZºSqŸêóİÌÅ¼M"y?Ï›ü±}@&Ï^ÕoJ+ dG­Á=-\{»ß5"«Æj0$o*{_çğ§æ‹4…6D°.şªèÓü‹¤uyÀÅ4I<+Q«%ÍŞL@f¡”C}Ş.—å¥»èÔ´ 
ÏìaœŞDjÚøS¸éÇ–Óò‘+HâÔĞ¡Oàë(AÎHN4øûN¸—ßĞü°l{]c­å–uLğˆ|@AEêŒÿ˜X'÷şê6E@«è’_+R'êéw4Š šè HÆ Ş‘G†È_{â‹¯×ı ÅÂíø¼«rO´z'v­%ãq¯}ZìW¶8yœC‘	¬20>C+æn(%´Âª©^\ÎÔZ&›,ÛÇ§ÆÍw(“uQ|p±¥Y}Î:*EßpJ\›”Ÿv¯Oˆ ÏÂnP.¯	Ï@(ùªŞß{ÛVQ«ZHÍ8œ¾R­m7°ÖfÓÇ$ÍÁ4¡ßDSÛ
©ÚYb{\nò_&æäªiß³X7_œïgÀewø§á]i‰Cô ¢,ö“Üµ•LjIƒŸ]6{ú[}HÄs8pl÷0‘*«á‡èİà´—oŞv(„vMw]ûòúfê},v\ª&yáX·¶vS…YÄäŸt	E¯ƒ‚%C17lD¢Bs]'À1KÖ@ŠXìïDáŠ£~¼a¶Gâÿp°æÑ—àô­MySÁ¬V¶²Â?œÅ­#óCçX˜;"ê×ÜªÓJGõ½o2Ê¥ìVSZ™tÏ¦²y³M mÔ\$î²­è”sé,}în}J¾/qõâq× êºB+ùÖÀa2^©Æ6)Ú>®Nİëˆ£’L¯V-•ùH›şQråƒWştõˆ-Lß\x†¶¦¢»±ÂD!=¸¹l]0ğ`§0.|S´6‡kÖ!i™W†ÓÕÜHi’EùÀ–å€˜&õŸØÖD·}õ6AÔ«˜Õ•¥CJóÔ	¾°YÒi2˜ÏMÕK8²Ü¡ŒúÜÖõ»…iŠã¨¿±?…9ß¥¯Os}ååM¦äŸüÌÃTÂ†€ÙYã'©y}¬H’¦£,ÒÜÒĞu'í«¨¿nêí#ıÜLòp!zŒÊ„ñØeH.û ù9IÁ€r.²Œ¦nV†­ñ:Ù£¹åYù)‰cëNmåep‚ƒáJ…wm'îŸá×1ï$± ö´mk%İ´rŸhV÷?<¦’7~,Üº‚Cq†>–B¶`NU§0×‡5H,‘¸öØ–/C¿íÔCTV~°–å¼TåƒµRxŸI9Ç°©€ë—µ™Àf—½JÇufİÛ;ğFpœƒ7ä`< ï91.#Ù›5ˆĞúš‘5!Áîsšt$—à—”÷¼Íky¾Æä™±+_ª¶àP_T×[ŸØÑ”ƒ9[ØVãPëö\,GÂ6¤†XîD-(HÄà*m¾œZÀñ"è"ÄNÖ2’i’iV<º£¼¯¼Tà?düÜé-GâvE†I-_%h¡ëhI‚bd®’¤ïRŸ÷N™Çš3$—Ìˆ)nrâp©Bï3È<À¤o½çpbé”ë•÷Ó
ó¦Ó´_U?Ÿ:¢mí
ÉHV'._4ı/&>{F"%¼.ÖTF‘ğ¶,~‘÷'‘‚.V6Wõ-O¬<´dş‘Î»ùMÑ£#D±Ğiß?hyBê¶áè1ƒô«¥š³§ı÷v)#¶kĞ_T+I«ÏtY¡ŠV‰ëË€¹ZáH…üjZ4X(7S<‡NŒ3»Øh£¿w•*<‡êŸš#ïŒìˆÿÎ9¸4ûì:8q2‚ßâé"wÉ0Bµó¾oÿÉ;÷UsH3kĞ€†éÛ¯nUJ™árëŸ@ãq©£2ô05Â¹şˆB`-Ä
N|mÅïês¥,}“^é*ÛùÆ~âÌVò*¿ùbÚ—Î KÜXâ4n‚Ã¸1–z_8™F¬A€ÇxÄACé Ï»Ê–@ëì€ÿÙˆwè¼±ãDôLÃª|pj]<Z}nl€ƒ÷(3¬®‘™58»ômCÕ<dw.Ì
˜†å­]²}Å=²¦Rcz¡Ÿ¾²Rä®BíJühì)Ìâ^‰éÂvt5øWtÜÚ¥qadçÿ$ñÆR>²8”ÁSãÍüˆ$®7’æ¸NÏçİ‰ËnuM¯\9ÛP/^WÛ¤ıÎ²Ê/_“ãÎ^]A¹—áñèÏ´ë(¢‹½×áèĞ'ıÔgp7SIÑÀHës¯9­ñ$~SÆWàîC³Êˆ;z{`ĞóTSu@‰ª>Æ‡w˜9(¢ÊF¤“Á"ŒB—åAeŒŠHäp:éÃ›ÔŸV(ÓÛ=Şöçª°ºö¸Y;ØîQ2×X\Y?œíKsw@gİF‡¤ªZ„üC¯È¤#ÃNGÑ²û°5yı©s9˜uİÍª`Ş !Z_DB±Ô°í\Ô?à {{2@p—ô§µ„æi¤1Ò¶(Iâ;¿ø„@ï‚À¡ÒíÓaì»¥¯5QŠ_ù¡å"æİx4Ú Û¼æ_zµ¿½ å²C¿t `oÀCÇÛ¡ìÚ8üT{yÅ à›Ït·-E½‡!5v<í‚£6¢F« iŒàÎØ\®(/ÔA¹Oª×=Ñ°U­˜‰H›3P™Ğ%XUC3['Èô(ıZùuyÌ±˜«:ØÇ+é¢ü¹!Ü†x›Æ­æp:Â„¥N£ƒk¯Wx¬û!ZT+±“Ù&™õµ—m^›  ·š‡ÑJ¹A?¼™ZpüÍFÍ²£C–7)PD3Ù•¡§ºÆtô
w­ ñ²FÜh;¨,¾Õ“"rƒ’ûúDÍi,ÏĞSwB²t®[Ñ3·D‹$gº9ıÈ“¼ó:9­ƒn0&&ÅPvïğH)
÷ U¶âFkç,v¯D7hşâÓG÷O%˜>Š«}kd”Š×
\¾îÌ0jPùôFkªP@%å	ÓºŠCO>*îxµãÚrlÒ³ŒêŒ QãT^MˆÆÊµ EcrX:TÖ³
K1y·P×—şV@üÀ6q3»vøÄY¡êmÃ/­©-“ÑŸ°÷ `Aô3»8.j¥™Ş1¯´S·¤Î…ö§"ÃÏ4ºÚ”–U#³rİ‹ü×.ºÍˆ*´7']7”‘wª>ô¿+¶/”z+*§\Å2¨Îu³¶('eE„Üq'ÓÏ6ƒç‡4«cgŒ	ÙÙ¨iĞÿîˆ”´Ë<† ¨˜¨³ûÀë$ğ@nV™X¶¹Zß@_=8ï>[†šàåUfiš–œq‘üÂPÌ@!´¸3™×ôHoîûÁğRr@ú¾>¸«%‘±Psó,’1ì}`·dœK¬s6ø	¬±•rT®Ãy ¥Ôæ¾7k€tÃº×#`ª¦j³£#¾¼K xÔø	×Ók¬=ó‰m˜mxA@A—ƒ¦Ö•ÛÕù§a^£)ŒÉŠ‘Ê;ßá	A×âÃsè0Üa`ÈãÌE¨â—¢Aæ;±¬qA!Pƒ–‘«”l;í0CíójÈI°Ò:Î\˜¢nÖ%"3­†Â¡îˆ ÀµÇ¼BÂ.01Eºqd¥Ç¹ñ# áÿº¢´©—©x)Í0¹ÂD5Y,$¿±+ ¦½ûX[yè[Š€b´Ëhú z:n•Öî¤±3ÛAjo -¥u•Ïj)Eå÷òáwïqÅ±Øø˜3e><Mªt	(®?¾C—ÚñU­á?wò2Ë¥tä‰–Ó3wvØı`(YÿI¹.v+ªƒ°ø,£`dâe¡¡F›·¢®ÆŠ¸üåFîpÖæµk²Q¨ëJE3e|K E¬"¿Ct>Aú™k££i[hš„uæG,ïe¨I\¿˜ëÛíK›¨Åpò>'TÊ9 ê¢]rŸ[5¤¼ B8ø§ÔdPu»=Jóˆ”d &¸ox >‘ÚbÿÁyqä¤bhKdµ/—f=µ¢n–„÷F!Â]¸M»¦ß8÷Ú¢vo¶æ<3éRb–80üÎÄó½påáğA™ëÁ² /îVË½aæŒ
Şæ
®„÷‚ê9Í NQ‡õÇçUŞûà`q­Ú©$T%"•¶ØO‹ñªéº.éœ2š"yG/|hBJ»rÂU PUÏ×Ì”w­	Ğ JjMÈ)íÂ…¢İğ!şŠ•Áø‚Çz¬À²È§™Ö9"¸-ú¸@tpKêîjÍµö%ò©É®!’½Ğ(û±ø6¾<H+bkHH9»Š˜UªUCoâ
â¸u_7k@¼ìI¹~Èãs2Ü•@¾/¾zG9–p}^#Lhl„ê7Ö
ã`•øGÿˆ´7Wø…¬©¸:'‡™uúDxrò‰?y·Öëš#‘AO!ªØ9¡ê"İ¢IÑò7<m€oä‡UÙ¶õlÔİŒÚi´Y<Ûz•Ş–@ìÆ•4YûÙï¸ş¬b†~éD/’íÖF#“Wë¿§6±Rü5ì9ä¬†<m*ß’¹ÚÖ‰4BÜÊ¹rJ—`3º{–È¡L+!Ë\L­¨’ıjJUôÆ³2{w2ê‰ó;Zãd‘•Àä‡òw–ï¨ßÉÔ{hYmL¿ê†4øµù*Úq©]´'²Ğ
8™ì’”™Îş[ İ4C—“Xº]›>›şòvÉ2s‚U&îØ®¯¯Z"ÒYNóµ(f†øÀ\™O'$uYŒÔC§	‹şÄîóo1ì*–ş}ÅD“*È•m7îFÊ½—k6ÉÖœÇÓ_vãùFhu§•eÿm
^<o3vÿg™+¤ÄLÖ–cÿ§ñ¨oÂ»…kUAdeÜ¼hÏ¡„à "Ak_í•`­í0kãë1dáPGQ8ÍÂ,ñ?quİıØéûO…"“¨dÄuÄUA>Î04¦™·Ÿœ<ã®¬‹À3°à7A
JmÓQ¶ì/t®êª§‰ÿ<z;EŸ§É¬*ÛGI×GŒ‚¿˜iêœÏèOÖx©I0èpD¾Ùy$á
î1?½½â—G+Ö€ì†w‡ËÃ‘¶DXó®EZ­œì·F_Ø[æU²¢9¨o¾Şúûü–}:#$6LÌ4ŒN“Ûò†ôË‰¡ó¼qÎ˜Şœ>€ÚF×ÉÚPU
kµçG€ùÀM*=ÕºE‹°úñ¸‘¿l^±ËBunjO»›;ùA|cÏÀÄ§tÄœ?INµá5:·`áãø¸»àõ©•‹„…ÈÄ·mk=MfÖŒ<á!Ê‹DZ¬Œ•†lİ<º4:(7H†¥µ´ä—ü›uÀåã,[{¨NxO…®Å,Ö¥àQìZŒGÌÓtè§Ö=2isÊ„×I²Ã‘×Î$SYRÅ³‘9ïÑÜ•AL#}n‹S!û'Ìî®¸°iÕçÔŒÆ…MCãSñ¾ëçM(f„J´\DÄª˜f2·Ä­^ëF?öŸ¬a6„Éµ«Å —$ßÄ 4lÓèîûñrM™·/åÏÕkÓ+Œ–Éª÷!$½å]9ÆËhñ'&rW¸n+ĞàÑ2€¯¾©Ã=š’—ßÂ{Ìõ~eèé¢«[ïë[ät†¾²TåˆA)ñÑ	Éj;}Şöï]gÂ‹<˜¥3|ãÙÙ€–£WÀ&¨——6J&åÁr1í6æq>İİ4M÷a9±¾!/Ân’.LXÓ¢7'HıBàÁ­)çİÜ]‚Kj”; dş 8?®"šrê(ÓÈr·6‡ÄÃ
ÓÑÆ—ÛPvÉµ°”8©“Â†–tˆÏÖC¦J#~! ¦NÔ<¥¤Ï 7QbY’ôó{Ì7nµš¡"Ëfr7”>r}Éº 0õXØ$¯gÕ¥%T ®çLWÁô„áÅ¾A×„ÕÓLhÙL—¦çÀ„];/?]„4RVŸ_(T>÷Òûÿ'¡(†%ÿOÑ®¨æ Dšdäşjè3®Y4@+¶„íù†ìbI›j+?ÁªÃ£(³\¸¨m„Ëçı—‚÷ÁË¹âMzËDáf˜çZ¨©´-±=Â.~à‹]=Ü\×ø¿Œd'2¾…Wà yL­6–ÆÛßO¢êêjrÂëUMÑzâ30Îc+ZéÈãJñb˜ãªXÍ(+“Àv-‹añjüaj~
SèØ)KH­'¿‘ˆ.—/K{¢l2ÊÜ¾ĞIíÉ/ôöØwñÄ!#—‚!Ün(şÈ
‡E©¨äş‡S¸À´¸c7ØÖ"3èJş¼ÈÅÏÈ>éíã6ŠÆšŸ>–ÏËaBÊ’9}Å»YS¨T&ÇÔ
ò/E)ÑcÙE3•¼£_2LKîóĞÉÀZı¹…uß×õşá=2­3'êASbV¼!	JÊ*uJY“s]a‹JåÕÌ6ïTs0ÌüãÅRh<C¾7{ÕXgˆû.Ş›J´cÀ[k¯L„†5Áì¦í÷¬ûsª]Ï](Ş×ìì‚xê/é4ı°Â×‘:½ßZm 0¾*p%¤Q>sãa/ÌçQÖ#4äó:ĞÊ)©¢jÚ@¡ ¼GÃj›¿/¢çY¿ŠÎ‡®.amŠ ³9Ê$ÆvT@ó€0¹×¨æÙZõ¿ ¦
(çÒ“‹}ô¸ôãâ1ËáÓú§â™ÛïÄ¬bÜ:®¾ë˜ËQæ•Ë™&Ö××3w3ìƒ5©ˆÄƒÎÒĞ¼HÃ;›Ë#N–3Ìúc‡ÀnÊLã£ßøuÇ)èM¼¤/apè~)ñüœàŒ…LÑ/õ|ÈÊ1·Ñ&-Ç(läü*„(°şèñèÊØ…èé7Ğl~rõÔĞúeäg
=r½d$àŸ94ÔQCaşÖ-ñl	â9Åˆ1úĞágã+´Æ¼6¦Œvz¯päOS‰Ç‰D‹‰5ébÎ‚TV·Èò\d¯ı|â€¦y¡_Ê|¼°¶Q×Ÿ;$Œ€)ø~k½òûú\cêÑ(p>SÆ«¥ovÑJU0gQ{µÕup‡ıŸ5e˜3LS;átZ¯hTC²Üw½È@èÄ°~ÿ}obÏò;[XÔ —.ÿÇô~C6^"dì“ÊSËşŸ³FY}@J½j³­DCgs_&k›U0P”!_v±êØ¸ıYcôiÜmùœw‘ÿ4A%3%Í]ª¤CS¯Díàë©øî”Sê™Nî±ÕG¼#§»ÜÌòÈ% C	5Á·	Ï°UZÖÆ¢f§¶¬£^Ìà,aûi Œ{!Hi–ìb„%NŸ?CUKf¥ñïü’™y·*Ñö^e?„Óæê$¢!ZíS€?o*Â#êŸ‡BEóª8ãp²Ùèã¬ìk‘5
}Añ¶	pıD7.ä)¶]dÌGQ|	|Xä V\Íuˆá†© Lkh!Á–œ´›uó­àU¨ëJ‘“ÕÃ«ÀÉËŒ>ãÂp3rŞ©È<Bë?g¡¯ô†Å3˜.‘fİ=Æ¶U[–Óò(Û§xDõÁÔê]ş€oKòzUv-¥;ârJ‡=[f,/€Ñ%ÛfÛÎBßÇ¯Aèû„)Q”Ã›-Hµ‰p_šOäÛ^2Ğ|ŠÂLIBõVÃŠïCİÜh¶Æ‰4˜¶³Õáî¡Ó4³eá$'#~~iG,†àÎf'ÁŸbx]ĞH²`)y­˜Çnê57Iåí‰cm±hıë:ı»‰Ug4w…Ï³p-Ö[eú¸î“=Vjx½™’/lŠpd§º']ŒîŸMÀ¿:İß dâ<Áèp9ØĞU%´@<…9¯èÎÑÎduö†éD{J©Ÿ« d»–»ò—§°{ğ‰WÎ8ó.ñ'ÍÔr,"ıSWPCqÆIx¢Îdµ3Y˜Šböc(i\–bîâ¶{Õ @/L1kø¶|´•í«8­³7o	[ªaƒ'mÉXÚÑRT(D …‚.¶kÎtc´Š)^Ä†î•å1O®ÇÊìf×5'²QŠDî<¿Ÿ^uH·y	ÙgL¢Š7fû©ÙìƒãÆjwçcFRù1mu ŞêÎÆÚµñlDk9„ç›Â¡úšv×(&´O9©sØIá³(‡xh@aYQ4øÃÙz­@—0³¹ænèİŒ‘¼¾7Æ˜Yö/°B`Õ$IÙút/k˜FX•…(„–n¶œ&«¼ÂK¤¼?3/Æòr]%~3œë¤¹»¨E2qLåC!káÄsN²ch½™]h#“…’²nÎSRNœÈ[qúD£ÛŠC•xÑGv ˆ
]v/ôU¸€‘I$ÉÇ6ğEûyÎôÿ	KÆH­ 5¿Ñ„‚O†•3ˆ¤úU™‹d*ƒÀéü·:ó4~.;Lê·âÅXÁº×@=
fİ˜Küez.ZãzD|N½¹[yúèç‹ƒË·%L]ÏÄn¹9çá×©a…Mìn`IP?,Læ€îı)Å´<ïµoİ³ø›vhXî×iGè]YÃPÊÇÀßüó‹ÔNü^¬má/œi6O\N0A4 –Óªt3é~l­Úù¬ØINø’àæ—r:êyTé1²ß‰ÓâF¼ØÎÅ†8Zz„æ´÷·4‹œÅ&Ë?óÄìîØN3â€'Ù”íô…¶ÇgQ¸õJaß‡¸_å™öQ€…Z‚ä¶¦î°Övß<İÀ,TWÈqí;££¿ß*Z‰ÈDÆµ¡#í“İB—3#åô¾Âãß·×Çc–Bxµ^ùÂ±ú#:•P•Ú"YÁ;$±Ãz&l=f^ríû¶8qéXÕõvš.Ñ/ÊØ,u4Õ8ß	„S¿4…òÅZOìÈs	UV‘Á/ìjh~õàÃÌÚ?¨%J7”u>`›i)í¨¶sZlXÿƒ4²£òÀõğCo3"%²«-•BŸ‘É„7~ü[Î¤Dv²¨E@rßf‰|<Õ $ ñ9h¦³Ş”³ïÚ>¨¬{ÓUš+(¬š!n"ª„$Ò+
Ï—‘À¦&¨B(]rHCqö\à¦Š¢FÕîZ8‹ZêÚ\&é–¥ƒĞˆ\Ç(ºô®çÅ4Éœ¤Ñöö®:ôÎ®ŠŸ0Â.H|/B™NÈÈÔÇÅ…ƒ†ôê:“BÛ03õö3)™Ê5ß&·ıo@¡ T”®L:Í;öu4ı1$íçÀÓxôMœiÄ€Î\ZW¯±rÏÀ n;PKR$¦Ö8y‹ËdH50=ÙC[dèÔŞ‘õÓô
(ï·Hs—ıd¦Ì£YÉ³Hì2ØÂ.N‡×7qå… ®}İ¸ËiÔÉ®Y;*MµŞ4±Ã•-š‹1Üƒc«¼Œ»°m‘š|ù[<¨šù¢?ÊHÒ8a~T;ôe®³Ğğİ>^A~U·3-¥}é3,Æµ%WÈ¨
ğ»@¶§õáÇ –»&¡&·÷Ov—EiÔå¸MHdaäìvÄoú[˜,ôÉ;)ÄÀ²]`;Æù·¯ŒÙÖš3‰é³lˆ/’ã’eóíÙ²Áñ§"ŠÇ oÆ…(6J×œ¿Óï$ÃmÈƒ]É.Äîë<Ò~0«;Ìw+kÕ‹±Šõ6Ë	]×S§&¼:x¸%åtÀéMgó™ÍíŸNr¦m@ôdïkã¶©élkA5Ş¶’ê†é@^R†‚ş&h@0_ÛëŠÙÀîx3˜ªÉ>Å>QçWğ1`FŞã¬)óç˜=zùĞ!Q»abó€Mó‚ ªH5nÿù?¤6|¿ØÍ‚ ½a3é:ÃÈ	ØÍ,J¶tÏ\á×D£—RÊÇ5T0‡ZŸê™“‘7J.ÉŞ¿O˜Çot˜a_D#œgúò›6)Àëõ…·ÓAHhöJå–Úm›£°”œQ›Ã½öb0Şø`Aé;¥LñîÆZ+-~ù+'”Ã·ºÔ’\Êñšl|Ë6F¿\²€GæoÆMÉ¤yø¥äü¸¯¹VXÎ kpÖ‚c3ğò%¢?ª‹ÉDSl¿^’p…´åD^.×5Le}úº–¶ˆ½›"XÌh˜Ù"‚Ğ5:ñ\ú¿™ì#‚xìÂv3Ø„\Ä2~™yÔĞh_ tşŠĞór}3¼T<Æz¾ÿEµvE}ŞşıÔêJ¤Ã‘K êX‹œ’úĞ»0“:è/„ü¨ù6CÖx'Õ`MPë’
MÜouc_rŸŒ“{ŞÄ¹^=úòÉŠ¸úF"•EHÖÿï…S–ú¨zÿÀ°¥a£ï´aÇ‡ó§Àß6_G"*"–Ü|5ªÏqè«”Œ# }ÏvíæÙÒñ7>F‹p“‰ÆÌ¦é,—ş:Ç‚J_¦«†ëcukûC€%¥ÈÒù%ÄVÑı¹RÎÈèÃòÄAZlpœpOÀO‰™ˆW˜À©pøm80’ıŸîs‹M%`/m|$¦ñ5;«1<KN¦I
1ôœ2†â4gY­EŠ;"¯§$´è½Ø˜Ê½5éàoD$…áRœ²Æ$ĞÁİR*ö–ÿ®Ñ£5ban3·x.pÓkÚŒôwYèMúaAe{£ÏÏCãÔ˜,6—êÏù‚soVùÎPlíêıOç2I{ƒdÒY%¥ZÈıq’ş1uõ.Èx×“©Ü_K¬ÌmÖ¡²7$s¡ô/ú)}¹„*š Î#¦DtñâĞd“Ö·…/æÚÜp³—$Ùç4·Ç¡Şyµ¶äˆA4ö¨~Hjûğ¬o/ÿj7x :<s¸-İà—²–Fc¶Õê²îXN­~]t‘5ÌS9"ÙX&eï‡Ü5sÆğ5ÿ(¹¸{~ÖDÑ¥Ï‘Ö7Â‚ØÒ‡œ 8l’HÊ3î¢Ì Dv	¾Lyºê2,ß(S˜ñ@®<àOæoË_ä'	ÕO¸?xTau…EQw¥ƒÜÅ§ƒÁ;»=*ÿ<TfñnmÒ{ÖŒB›¨ıÜ8#€@B³í ù]ø*Ï4W(¶¼!ük”lR°TX/![¢ıÔ®Ú\ûd3€ç³ú~ŒB¸$ÖŞçfPÛ-`N)?¶áM‚¾ma»U¢Ÿÿ«¶¼cl‰ØH`H¦«"pçùQ^CMMïh3¼±.£qÌê6€jjôÊx×Ú@~NÑÑ'‚·ÿ×1…ámĞŸ$Í@üøG4‚ó|œ|gØßKŠ=áy×1aõlûw~Gª7¢¢ÑEõï‹zqÚÖlYğr7¤[ğJ_Êc»Uëw=•¶šŠË¸¦¨ŸclG=I¢KBƒ2Ş®úø¾wÿhL¾×7&‡â’@™¼‹óğòƒš`V‹53İÚD¿Qü7#dşS·ñ‚èîá©»všô;z-¡_aqÌÇàÏSÉÜ§Xf<û©—Kk pº%„Ê&ú‹õ(ÑÎ¡«Ç2 Ù9#Sçwâ÷ÆC®Ğšˆ¨ïÃãlyÏó3×YÖ™–>b½ääb¢L<`¨Ey©Ì¾­ßoW/fÎŸ&f„M˜=aK•à?V¿U«œËX_*$\ÍÌWî×¥£½é–yÖn½lÕ˜p=N;R(ÀzSÌA÷K)¸OfH Q™NöhX¯!€¶–&Û´
'ß\œ*¾‚y97Û1ºĞ¯ª_z¨¹àÎ]B¹Hr÷ù£WÜrkş`ÈV`üQº$ÜŒT4Xô+ÚŒ©¹úòn£>Hè‰1"O¬"ğ?ynŒYN;øHá",kS¶ÍDgÃ¯bee¯Éq<î:}Â?T‚õÆêUoÌ‚ÏO™e©o½–è(,Ş)ŠøbVk*öt’W×æŸŸuæ(ç4L  ©}¥BHFïbyÆ¤o^Ÿ¸%˜¢XójoıÅ‚‘BêiÒ¡ŞåÕ>%®Á¾‚qİ/g¡©¨¸%½ŸÖÏÑÀÑÎ‰%àh¾%µÔKè®÷ª&Ğ&9À–Ã™“BŞ†åQã~L–e&÷.ëM\ÙœL°xÆ-XûäQüxn%qü;:&hùõï¢m“ª2	¼º0êF„`P€ÿm™Ú+vœ Ñ|E0/"(>²aE6SwVßŸÚãu.›-…ÉÀÉIvş+¦³üX{T} 
t–çu[¶Ô‹ãg6[–ó¶ß’ Ğ ŸäĞûµx?ûÏ_äfcÈºYŠş&Å%ÏÌÏ{Î« 8¬mBR´š}ID~C˜l Ÿj—æ¶h¸îÛÜeo¥2äÅK‡vpü?¢ˆ×î9¥è€İ²G½¶Œ§Æ·ß|¥ÖqáÌ‡ßäĞ+ñ’¬ã„‰®çª-3 b‚K«¨ÿ
¥Q<Ã€½Æz[—$ş'¨I+ÉšƒªõÓû¿È›Ê&Üä»p^ÆÄwÒ£ºÍ¥¥OJex_T˜¥†®9¨m{Õ?B¡Zb/œ:©6p(£‹ºúÈ&G–ü<ë¿26´!´×©•Íá¢Ğ0àf•ÉW"µéZÕ÷ÒK8ÿÚ‹Æ/¥=%ø¹ñLX?ogËªaiƒÒtr&’_DÎ’]õÿôÎí?Ä÷ò.LˆÂ<~ù…€b™ (–ü÷Zê<³ø\K£›Nõ#i@¼JÓƒJíº¯4Ö;¢MªaN¸Ày5 òğtXW
ô0¥–<[÷h@“Wqy9U‚’]¿pá‡õàIuFåsO‚ÏüãqÔÅf†	3é¶†=óÙS…Á0Â(ªf&©6·Õ_¡ÜDòÎÇ³¼,÷CWMáòÚD¡®ßDš{6^S¿«¼¶a­Iœ°X:ÑGFR¶ÑÄœ‡2Å“F¤¥Uì/iZ
¬…ºæO£Vm‘Û™†Œ€èË’EZ|ş—Pe½<ëµKã7t³§QŸr[vënKpJ&^ƒÕ®b’&5(›­v?ßDãí<Ä·ğ÷kª;í1“‰¸ ‘GPqåS;—ÙMˆmµ jHñ,Ïd·	=_Ô/Ôì“ÿ]½ÿL¿¢(T'ôZ>Íš 8zÛc¢³ù&†àô†½¡¤TŒ}ÌÍÏªe)‘ÕöüÅš±DˆŠFuESmÄÌ ”;sƒ2ÛÛ‡ôe¢‡§­9äp]0¡]Únş®b^ùs(Sn(üvè~é2ÂÙjüíÀÃzĞÄXFìóã’ªn©ÓÑ¦íR¹÷íC®%{jÂ¯._é‘r÷W¼Búëš¸YĞ†¢¯š:<(VRAz²úî%«ÔIÌT;-¾Pf“gªm¶r‘AKøw$BÖp[é ½°ŞĞMÚ/ÿ;QÙó1@éô”}šRñK»JÿåÅÜš•’„½KÁ×İú&Ÿ£å7t%®pû,Ï¸…Ñ?ÕAÿ;f,Ø]Íz'‚—eŸ‰u›.¨áæúƒ‚¥St¤[ãã*>Ìß¯•G[Æ6y¹" eÆÚZ4ìŒñ[)6s:E¯6ÔàÓœ|®7µQˆÑœ¦‚şâÚ0°ç«™kº¡‰ˆ?KVŒĞ¤74}b ï¹ò—aô÷Áê½'¼TÑ·Š•Qˆ2Ô^ ÏıH÷~¥$yÓøÙ†v5\´ÊN%wl”Z°ì
ùğ	c=m^>C^«ğœPŒO£¾îÖz|E°¡zQÌ-[DÙÖQA"¬ÄÉWMµ<›f¨|˜†äª™[DÔ2\Ö#\×‘ÆœLJ(‹y<šc2`ŞÏWÍ—#—x‚ÍÔø&!D©“çhĞŒÅW¦ò2æ9öyn–­¢X§Ï3ë5¸@;F;Ê¾TQLk¾{§X”²k,ñFv€Ş!lå¸ËRZqìOA®§îò÷c†$Œoºó=¨(_CæÂ’±£Íå¼”¡î¥Moi	G7¨˜QÀ>*ê©•DHWéÄq#¥¿Ûié rÒ™b÷>;HÄ¦$ÉÎ]ğ(r ™Zj÷ï)o¤ÌƒÒ£I<s"d·õ¿œ°ÜøÎSfoêCDP¬O8A¨Ö-2ÂûŞI¹tÖN\B¡1‹XÃØ÷şæNúêá¸dÌÔÒFœu²1’<Óä»–°¿ˆåŞ‚ŒÇV$Q„÷9³“¶è ˜VÙ#C2}M8ˆyË¥©QèG µ©{”~	~ñŒî]hg¯bN«´CóÜœ•gÕsÏ6$]9X›wª(öpöUBñ'ĞHŸ	 3‘®ÉÉF [€IÁçï–’­IØzçäîæŸcöäœ÷ÿ¸aè¸âK8Ñ˜ÔœòM.|?®©Îÿ+/mùÍÚ,7,ü¹«IF˜I»öD™à3ĞdÛù…ÙJ­…’x9¢¸áäXŒu¡Ÿr©ıFªè{J‰'àæJ}“Õ(]
+Èp]ı©B¤Aï„ı8¶ÉÛ?Jdƒ&N#º5è™{agøÉÎ™Â6€0|£š€¤áz{GPóöD[+®»êh2~°€xk‰Q(ÌÖ5=ÇŠº]á?f4Õî¯á´Á_™A8ºŒœL í®ÒÉÿbÁdHÈÀ:	™Îx+´ PoQ›W©”W»¯#šÓ}ûÓÃxŸ§áOÌí¦+.c1|Ö>‹’·AFÒı›5œ¿	cÄPÕÒXA2øËÆÛÚcãşşœEüƒ•¦2hL–À‰„Q32‡<ÃócÎI¼şãYpëK/¨äqífçSÏßVŞjä”´‚ï†pRÿÖZ™İJ¼¦îD¿Wvfp€_íNƒçúW/›µÜ>FÌù‚êFÌ£y+GÚr§xN]oêı‡sÁ#ıb–¨œÔá¤PYË >Cá4@¡1Ñ©Ğ·Î*oşš¨ùËÇòˆŸµ|Ö¥„Ö—3%îÌùPÛ !g˜CºÅG[€Šç)î;JwgéYûíé´²Yd
N¥sZD‡øÒ]åó"-d]ë2z?µ,›£†ığâX@j¾InIó_ÿUÑP8sµŞ#Â¿4ëë¬ë¾ô)”´­(EÿlL’ôQà6llWë'wÓC¹Šm4Ow8oeu«ì•#”qä%öZâ	M)šv|—õìIÛ’Nú]œ6Ÿø¥eëGñÃËØ¹cĞ¿ä£$¥ã‹Ğ[ªkn?F‰–L¸àÑÏb½ıW´$ëƒf û'ÉX®¥ğ’ÉùìbnÏ;ıÚ],¹ïµ¹IPDTâ_á3Z0é´Äti2ÍhhBâ?şO}ƒL&)¹r%4^¬•…·o}Ö|Ÿ_·İŸ$¤`J´HÍh ç5\”Û®»4(@:“KÙS…˜cM•+›ÚÂ¿óá_Üõ6öózÌÓiÕ0R~=„*NÑè}ßùÊ‹v«åŸË¥àô˜uÍìDtŠˆA•›*ÿIš¬M½ú¸9Æ‡6²LóàaÊµm„ÄL!$Ö=³4ÍØM0ÆW\Ñ{ü=zˆÁ¨Oì²€ÚËÿ?êM3ìR&âlâ·gp¢{İdí7œ6ì¯w£©eîRi-¹Iªó#½kFãÜÜm“¢cø¶/Ô!ïq²Ÿ¹Çš§¯:æGıvBUƒ±bX(é6]‹Êr'óCnÚ\„aòt9ÅÉ¬«ó­í÷ô´ĞD´ãS—•„¦$€’
'Aº÷‘RÈ—³ÄQ©®æ~NAâ.QÆÆl¨nzgŠİ†ÜÁoå bV®UQG#àR˜Ş˜ú1¨ï>T|yæ=ÑÏ‡ñçá¸¿BÕ;«æ¡’¾tOÂ*¡ìw~Rºğál$³Ö nÙš0ØÈD¥‹¾çÍ©,ĞÎ3ÉO âçù)¤ÃøüšI¨Ú[ù^ ÙƒI˜.÷†~h"Ìœ}ŸH‹º<wÏ?¥Itô>m	ñi>¬e8´Š”×÷ôG’D¨ÆÚ˜ŠXò“şƒ|„têEwT™ò#7™¼2bæ{æğÌ—>É“ë‰OWo)Á‘Ó•)¤ÁØZ˜ş[GÖ³ŞŸ·ı²×G„]â,$ÔE,İä¹uÍ‹òú6¸H¹ ËË®×?¸õ{ ~ÄpÀİlÙ7åÕ¾#œ²„™ËÎ=ñ~öŞ ÊÊ6¶3Nı,¿Q9–BÒ~q˜/8¹c-iU~îÔ¼•ı¯M	Á×¡Vq¥‰èšÎ4³"ã½3LŸ¸!õ¥•‰:Gk–$¢¢2sûÅ¨°ÓÚ/ÄåA‘È–«\9Fƒ!ú|"¤Î6S ÿ³2OA¨ç[>Ÿ' ‡=tqG`:Š†u®ŠÀyS¶çô<Nˆ5d…ÁŞH7­İë5ìN
q’S¸Fˆ¨bÚ/±L3ïÁä+	NÉ¤Ô^S®T–ÇoèiË>,x í¢‚18>ñ5¦TnôCYçö/?@»Üù%¢À’“¹Ìylñöÿâ*¯—ü¼å¶„fÇ0ÿ¿W’“P4Â ]`–c]9®ÎAÏ{/SN%A%‚\¶Š¤=;¥4ôBM^  •N¹}Åc”q’Ó0Œ®µÔËH<z09wâ+l…	t’¸|HÌíª\Ò%~>‰Ü…ï	Å"k¡Ê®å¯78FVØâWè‰÷ÕÍ ¡ŸúByBÎçt}>ÂÈ…WEŸG »Á¢nQ•ÌMG1Êoî9±‡35*c¬!•şUìÂ-:œTß³šÍV‡
\ÔäxÖoäÒW„A&Hñ6Pøÿjıs[üÂ­˜ş[»·ª¨—Hn?°°ú™«š?´
WeUS<Q{ßÍAÈNs*¶vfì>É»aŠÇyxšQÄn
y”­FIÄÅœa!ŠVªú~Ë|Šˆäíp([€†pºğÍúÁ`/^„Sáç/º‚ÙÜKD_ÛëÔ>ôsp§ŞAûf´gÿXÕıh)§‰åéAìâã<MÈ~MuD=VäÔ•ï>7+N"©ƒLoöÁeå-ÃÛÃÀ½ãqP%©XCM‘ Üià]Ğ+FÈÉêû™€?9Îš”ĞZG:ĞµŞ.„Şm%´«±UX”Ğ~~¦Ói±‘FGD"ß±ÿ2Ükw©èìŒJ2ß'ÁÀ¢y¥ĞÚR?Zz•ßLfæƒ,ÓzÜåm¯’¬±RÑ7}`ÆVDH}`’/UPùØmB^ApÇgDO’à‡ÌPcc©²d…„QBVObŸ+›û`cñÅ:tØÛÀğê½ÑÃ0Ş.ÆUâÕjûà!9^ÚšaW	ÃÎô°€rÙAû3ËiıjÅvê`"ªôoP+h®DX’#ìé¸K”«Ô¡ZÃÖËJ×ˆä}Š˜n‹úÊÛá¼±J×wÑ TÏwIÀ„DPÒ{N¾±æ™OŞ6¼Ñ\h—‰V”ßø‚d;ËnB6&H¼b™<‰¦IZ¾AÉüçĞ]Û‡ Àf@SœFº†@Î.”¾€1,¿ºœ@ÎÌàu‹2Âç4½RƒVW¸ŠÎƒlØ×KDQFĞÒFÁcÇzqßs¦é`°1L‚|èU™=<'›·n(7‰§dÖÌ•‘ÛşxŒé}/¢8ğ¶™‘`Ú¸5˜{ìJ”óëÅB"1‰ÉŞ’UöÔ°Èï%Ñø¦¼rga._ÊÇdÒbxÿ.ùh~€)'Un¡çÄ)]ÖÛseä ®YÈ	G€`„ôÇB=
Â?©@ÒSõd©R@vûÏŒ¥h³Ì¬zwÀk·İ+ıbUÎ*…(HÎ¹°ËŒØ3<N@–š÷Ã°úù ´‹¸7„ac²aeşD¸çMÅ"Ú‡ğK¨¢Ò±SXÔ6]ËEWfÔ4İçºA x¼‡¢bpÀ^šŸˆâÓ–Üš©ãVºî¸ëÚWáô¹a31ŠÕÃå)j†â É.“kÎ·èŸMúê–Æep7H¼j2ï‹¯¬Oäó¼mQCdÇäïw[wL(¡ÃÎõ®™bL®ìÆ/uœ
w¬=#áfÿ®±ÖÅ ô|llò¹Y‡“û_âäP¨IohĞ¾"ÎjÁ’¹%CûZúv<<V{!Hw²e¤ 8jÃgmxœ8@…²X}Dµ:7ÿ°ZÚ-G3è®	eL‚É'#œö“A*ÚN¨Ş|è½úmµ}
L•ò¢Šæ+´­%zRÀö1¹ÉñGàOÚ!uú¶,å°ç¿0Ù_y©Òñ2Înw‚ÃWDñÌjú:‰+]êƒL~s5ø¬Éş2rıÛû±Ö:Ñ¿Óò/â¦’æÆ„RU$=(²åŸn\;<†'o°½ˆ(²t-VˆÁm°Ë%‡(W`vC×õÜ6 Ø;÷P|©ä–œ|–qG«Û Ÿ©¸ŞŠwµÊKÊ;À\z½ûíÖ
¡9:ÿ°†äÀ[[±˜õîÏŒÃm•|v€p–ÇU1Şí€è#•IŸ,vÆ÷ş	ç…¬$»kØ×wmTŞìIº=mŸG<l}Ï†”=êœF„ÿKäŒ H¹kH80aQdîmPôhtY¡‘Í0@ÄÖ8^~ØJcr)ïS„„b…™ÕqCÛı£–VÆi¹è€ú<•Ék5qy'1[7 Ra#§†üüåKg¬yß¬²õ3ø	Idì:VNµ€‚¿']¸8ôàUYÓF2õ“T&íW€¨ÈÖúâ:Ø ^÷ªhÁ[øÕ¾@˜@ ë¡C2W; @,ûËÅÇùÛ¤‘.ïÈ ›Wøygëô¢otßqæ÷° gÜ¸ê“z{=‚Ô‘'•Á‚n!_°3Vsß¦f0×%ÌKf€EÌW¾ËdŒì…|„ƒò¼¼°jz÷ÿãVş?hÒa¾¿}HPG~³»^Ş¸#øV/Z-&w¡xs>õÎ/±[ùu¼óG†‡5LÃ=µ+˜¸1Áåµü1¸™¾äW(Åó&İÇìÈ,‚½æ/#¬4XF”êƒ^±L-åm†<Íï‹Š	»`³‘$9e5t>èV
`BZªù­}òƒt±±”F¤#¿ìU6\”yê%ËtHG«Nè«=xŸå“ƒÚOˆÅàJwìF©ÿ]¬6… tîD	XEiw.±ÒKt‡rİâ‡qÃ¸­)å@´lN_2 ±–‹ˆ®{Éî¿ó¤šì­xqxBò(İY¼j2Ô$¥>ˆ`;o@)¡}şâˆGKz‡g®Ÿ¡7'-å}â©[“e-Üe0vî÷.è‰ZÔZì 	WÊ4MRµ‰,´4µ5Y–›Ñ|;¡$XTŸ¹™ß–Rä9½PE¥P{ï.öhÃfGüÍ…Óµeb@^¾”6ê­tv´|çü/Æßõøzõf>}\
øC\×4ÍaV€ÉQ×TËfüpEêĞÔ²ÛğéTï8î±äÏº3PgŒ…~ê*J½$A<]|ûp†6Óv
YäÙÅK­xÏâjV›±Ç~&î¯0L¼Î¦€-Œ£«ø"ª³íHõÃÃ ÂùÌkÅQKé}¾ª¥ò¼¤`Æ4×rZ0çÆï€†ÉÍF`ä\—NÔp!S’‰yQ£À—mÒ©`‚æî1´“>@(~u*° ‚ûp•dâÖ1e*òÚXÚcÜI(È+Yù:è‰y^¯iTŸ´RÙ™¯÷¡ŸD}ÁE…¾?'¤ÜØ|·7u˜'%•Ã)â=pï¿
ÓóaˆáCZ1OkH¸™.BÕ3 :ˆ}rÒ‚Çµ¹ĞĞQšU‹y,µsƒDe±LÌxŞ=.m5Ú#´~Q|Š$¨Ú|Å‡m“Ê+zè'ºÙë¹üÍµuQ5¦—'¹5áÂĞáùz`¾Å üwóœRØÔb.<›~…¢é±¦S¤ı0]ÅëUT¡†¦ØKåîšhz6hgfZMãÅ£/$:”·ö3Û¹Úœ	œZX¥zg:£(Óhrão­ãTm M÷Äè²‡¢‹ôâñ@Œ­“}*¡%®w­À_(µµyšrÃïÍ*¯–¦\îN,OcS.$Q È|m6€ìašÊ^G.w*¬YùBÇ1, 7«uàîü5®Ój^#Ä€úGªü2ı—URöOu¾g@ 8¾mò&Í_¹…U‡şëísrN™
üiäFLWUmø¿¢Pdhÿ;üŒÈÒñh—TG2w~”ÛB©ı”‚`77d)^¨Iê¨ºO‘ÂiúR–òÙŞ 9­>À%?fë©i˜š7èk¿²ÁÖƒÌ$ÓLt¥´$ÑæÔÚOP	\²aıEŞÈğ^íš¤5j».(¬ı–¼Úœ±"Tò(FYÄ…¥³Êyµ…zÕ³b¥í¼ú9
Q{ÿJ|¿× âhÕì-Œ‹´’!•‰¼ªßËBOkÖ'ÀšKE—ªÃ¬‹AçÓó.GGÆÛeÓíâ£îğü²â9&'wñ1\ì²TZœŞG@˜S‘ïÿÚŸÚr‡I&W	XÒva8‚[Àa;Ñ;¢V6ıJ¹êY©èãÍèç‡×HŞŒä Ür0Ù-$˜@>ÎNµLÔ¹ÄkExô‡^½–À5o‡‰b	ÌèU¯Ê}Œ©Pï
p±,†Á	Bu–vï!e´ÀD€
4ÕÍÑS?uÅ
 xË¦E»%›…KäGE-	öEs10©}›%ôér$•9©ƒÊ•shğ©`ç±P!»ï5ë†÷¿ÿÉ‚-!µQÉQ–FLş¸O#á %G:P<‹'NûíFÂ3GöÂÅ,Ì»Ë')FÜk9 ÿZ´/‘¯¢ûèİa6ùGîè“ôÆ›Q4Æ²H¦p|{İrß'+©äBùÃó˜S²‰lÁ`ç6'Iøjµ–r6æÎ†ôÈ™Ò+á\¬«¶©ŠSÒ"—°Uù&I/ùÜ/ÙÈKT~˜¢£©Ö’ÒŞ‡Ñ Á%Äu¦çµ8ˆ8v£p±õêFJ­jºèá¢¦U™‚ëÚ­¥øŞx¤²šqƒ¡dë3ûÕâUu[›ï’xbù:R!á^¶=4sx
	şL<+R‚$=xGÿ1$àRK†qË”“ú×FêüQ½™eE!&Q[…ª•¦)Ëª‚dW4É 8g†Vámfàá¹.ü"Š“„  h<·ØÄK<+ ÏÍ€*}±Ägû    YZ