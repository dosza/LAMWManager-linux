#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1510164188"
MD5="edd06c17194cf815ed2ae7f07d538751"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="18964"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 525 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 104 KB
	echo Compression: gzip
	echo Date of packaging: Wed Oct 16 20:18:31 -03 2019
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
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
	echo OLDUSIZE=104
	echo OLDSKIP=526
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
	offset=`head -n 525 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 525 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 525 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 104 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 104; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (104 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
‹ G¥§]ì<ÛrÛ8–y•¾MiÊvº)Zñ%İö¨g[v4‘-­$»Ó§T”ÉŒ)RÃ‹l'ãı—­}˜ÚçyÛ×üØ€$xÑÅNÒSSÓªTLÀÁ¹áà€íÙ7ÿmÃïåË=ü[}¹·-ÿÏª;{{Õ—/^ìm¿|¶]İ~±³ıŒì=û~çë.!Ïİ¶ï—À­ªÿıU´‘ãRíÛ¯ÿŞcÖ¿ZİÛÿ}ıÃõ¹ç©ÃÀ´êV¼ë¯¾şû»»Ö¿
ÿvSë¿ûbçÙş}ı¿ù¯ô64mm¨{×Å’ú­¥béÂ6çÔõLC7(S`7İ"ğx¦û9E6tÈfİšêXBİ­béÈ	\ŞÈ¤öˆ’#g: ªXºDD}@¶+;•béZê¶V­j/¶«?A	õF®9óªM‰’ft…˜™é®Oœ1ñÅŸ[õ³_`¶>8Bú× Çqˆíë¦í†lÃ1-lÈşºdBm˜vI\'ğM›zdì¸¤Ş=›¿$©×»G¯÷wUR·×1ß„îğ+Ô§#_':Áøü?12ÌÅ×-İĞ‰íÎ!E0Ì?ÿ·kêsf K¤O‡°>-½<zÒ9ÚÜúD
Å‚azş`s¯•7GºO4ê4ÓóZ±©¿U,ŒtH_à€è6)
Ï•‹a`û©şXQ`¡@ïf,ÆØÒ'›Ş0°|¯V…úÃCÖ¬eÚÁ93mŸTZ¿%õôQ1N5ÆNe»²ÄsÑm`Š5åÚ÷gŞ¦ys»2v)éŞH·*;Á"è§ùúÄÓ\jQ@<Øl¶	`´š¯zÿuMÑÏÕ,sˆTI;:9Á† ¢²¡UFãIe·ÑjÔ{š²´ãËF·×lŸ×Ä×–V–Z*1ÕÅîW¤ÒîZSÚ]:%¨ÅjsLŞ•’hw?î@Æ,dub™y‘÷‡(ï6)1v !–3âb‹2a˜.‹ãŞ#‡ˆH¢„Š±€Lè„2c’”®ˆ3tÍ‰îşÈÒ(‰Ã Ğ DÎ%Á”À€oˆgN‡Ÿÿa™#‡õ] ÄÕM4c5c“ı!–MToùä³Ïjy4&GŠ¹äåxBWbnìIv%LgoP\o vn¯ÍÑ5R{z¢¢ÊØ€]Ùh•r¢‘BjDQ¤a.Åœ¦¨º¨+ïêZíÅ8°GŒ¡˜½al5uZ ¾Ø7Å,è]Bí9Sˆhûİ‹ó7$R·}l:7I$Å‹Ê¶:®D`ƒ,\ùS¦ìWêó‡êæy¯_oµØ_ššRF»¸Ûj_¼¼nŸ5Ø"z×:ø0=Ï…•”0÷.ÏûõÓ¦Èrz|¨Èt­€ìT&•œÙEL“Û}ÄCŸ²}ÈÁ{$x08D0ˆ];DÉ!]¦(9äX‰—³3À
m.št°Iûü¤¹¤@3¶~q3²	s*Š¯°è½‘º;E)Œ®u{B#%–™(_-’)iâbaªß€kÚ-%ÁntËâÜu°9ê\úõîi£_ÓA[µ;ıš¢ˆ†Øh)¤İ‹ê¹ßCºí^Í êòe¨GãË“ÎåBBæët'Í·5\™§B‰MW€	Eq(J"‰4”LÎ^û¢{Ôà•%Ÿ-tY:C´ršÏ±±D/$ËGs&(”‹8‡û”x@¹"¨ -F+£~¼›B¡_ÆuQé$Ô.ïpO–!ôEeª»£ëıİ\&ZGúsˆ"ÑdæÑYÿ9ì’d©×'
IóHŞğ@×?2ïŠ¾‘Ìšsï|WYgd‡.Õ5¨ó­%+ŸjG0:?²:¯Çïù®>cu3ğW€¡`/46'‹EQ~$•Å²X>iÕO'm”Ÿúùq·İ<öS\•äQÆÉÅ;t<½…ü-Ù8TƒáhBeÁÊŸ2œ„n÷Œ¬h|	=LÄKcI ÃÁJäêÄ»©b¡G‘•:úè6„¹j¦mĞ»ZùOÅBèò§@xïÊ¬îıÃ£ç”p)BJ>ûı÷o÷ñ?KŸŞªà}ú¦=ñTj˜ ï¿Zpyüowg'ÿÛÛ¯nÿÿû÷ÿM1ô§êÖTÿŠñ?Â€ŒÓ§<®—ÃñkÆ»Ô›9¶g-Êb{!`J€¿†VKL‹z•Êoõ£¶C¬¿òƒÎ™‰!dæš¶?&½‹W½_{ıÆY­¦ŞPùÔûıî'Ó¸¤¶á¸PüÇËÆùq»û3Ôµ5e{^N»íØÎ¬`x•+{ƒ¿âSÊÃ”jn€S5´½ª*<“
+Â1xÔ›°šH\8ñÁÒ¾C‰­Å`Šîş50çrKDÒÏ—#-¹öS2 Ë,h‰ÛĞïpÓP–÷qr(#C ªA@rèL÷¯k‹C!ª“DˆJ`qñÛşóÉ¾VÌ©’ãÊ&G4üÀÖqàùnmG£”š'Ç"l½"—×/ŠœÀğUx‚üí­>€'21±^Tšª¨>±Êİv»?@ÖlãF›YºÌ?õ4­–{ÇÑ¦XÃ…PcH˜M«â9¬@§pûcÁö|`-P»•Ÿ´™KÑ9ó5^Íƒ	bû^(l¨'ArQà¿9WZ`›¾ÇJ€ñ&ÔßxtíùÚ¸¾µÁW	Äªy¢¤·)ÂkŠ	‰ˆ4’È¡w¦é’0JŒDå1îo™65íd$ØÀ}’˜èİöû63('QDµ,×ï$F1ÒAUs©¡„¥Âó”FfúAeÔàaÌ:8»¶Ã²l±oG¦Elì¢ĞŸˆ§ÕX«ræùNÇuP‰2õ0ãÏâøÙgpÑktùF¦‚fÍÀ¦‚¢´zµí¸-p/­m„1kÂÿÊ§İúq«Ákm uš6h/,Ù_úÊÒí¤¸ØËİ‹”õ[ğC¶!ÄôŠÙUUÊò´é=šŠ’;i¶¶ÒÊ&ja‹°³Y†$	÷8ÎZY~SÈÏ?²öI45k2i’8òVG*5ROÄ˜^ï¥h˜ÏA’Pfñ˜raS²=mì!ë Y8;:ØÃñÚ:›™@ş.l¢G(˜uZyÌRŠ“:î °ûwÂ(œôdŠ¥v VÔ^ »¦C€UÁøÌ‘@)úMá7‘Í!àó0°UäA¢ö­Mİºe!nn·Ù±Šc[÷$˜à˜©ˆ!ä¾Rj?Êy¼*ğÂĞ
O_ğä±R© –*y¥3òBÖ,r1à¡$&*Ù\Ö[[šğAüHÔn~{®tä^âÅ´ôÂM<™[ó£î‘N\§ËUÈŠBñ%æ8hs®57)ª©w/zƒ^¿şªÕ`ıÄ‘‹5 K,©£3C’ZISÌµtkR3íSå-«‹×$à¢æ+»áŠa]\¬–÷ÆùÖì&¹*I+úz¬4É=àyªÅÃÃ¹½|É]L¶cØi¬ßE^sÑëİº&hXË™0İHÂpm‘•cÛ–3iòB¦ÑÃaMŞ<:x—A”8Œ*
«Ä6Œ.Ú.(§<1…[…èÌ :ÖÊ+UP
•¦=vP(\© ·}V0Q=¹uÜ¶WTPô—v÷M¯S?jÄp"õ…€S'KÏ¸á=†õçÉz0¦Wö)x”MØM†³İ:xkåTïø¼ÏXza•cTŸ|g ¸Áé·Û­^•)b€çÇÒ‰¡ôÂ*å4†²´œ‚†\OK#+î"Á ƒŞE§ÓîökK˜Há+ÉøQEƒ|PŞÄ?[áÆã¼İoü:èÁn$qöm;¾9¾W=pŞ·Š…_»İÈ‹O[^¢ 
`¢ğˆKÈˆJtŸêMÁİEâ<>»Æ‡Wö&ä•1’’ÇƒWöbŒëÖd>è³}z°š‘­á—/™NB+±®Ğ?irc6óÌy…Í‰'…)µ‚›8,ö{Î ,>ù.×ÎIDÓg3Ëä	:^¼M)Ø9Ñ¥„gÌRy,M<PÎàF_S÷/ãÖÙó=T3ÓhDÔÙú3İºîˆ§æ”j3Šò$Î^¯ÛDkŞ¯Pêõn|gÆ6±vwÌ‹IÃöİû÷|­œëSZ‹J±¸Ô¸££ÄÁ÷¾TØsª»÷*ß¿«lcœko¹ªQE^ªÆ¢y8Ö]™áªg„æ*	Áä4ª<æ»7p\ÜPT µëSwjÚºUë >¼è~FkõxYÄ\€&Ìe­TPË™a¶Õ!ôv˜…š3¹ÅiÿÍáéEjNÀdrÍs
f¿œYºçÉ4ÅÚ3X-6,ŸŞùÚÊóßÙ›˜Öù ,ªzNàh~icD+€ÅÉ—æ"â“[ˆa´›dÍÈ1(tjé÷|–oè=(Ã«ñˆøa‡Ï)tâR*^Ádrê&‰ô®ã:3êú÷oÕ7Çõ¦2§;ŸÚhàŞÇë÷Ÿ=w¬àR·Z« ÑØë[•ç…ª§ÔÇÑªÇÎvÏµñoj™C„E»•c‘gó‹A³ß8ÃK¹‚ƒq–kØ|‘ïïH^;¨åV@7¨n×Î”†X1ee– w8#Sçg.“07òšZ³ÊÄ†6,/R7€¯5ïŞóéTe/ê$0ŠÒ3´¸P} ¬R û²©xÔ­\ûS«‚z$[,N\!G‹‹*wSëQŠFìÖYïğ¤c€›5PDMAâÖP¯aï`<fLX„œŒ~‚iûæy“¤Ä9„%ÜğHÊÀÀ9sÌÇ.è@\.RŒ…¶ãx>ÏS`6È±ŒAÒŠÖ”Õ–VÉ˜‚ì–†¤Ôş‚sÙ£Kv8²ù˜çäù9ùæ*	“bd™rô¹ú«^m3Nãü0ŸjX©ş¨‚°?7ª>5ÀñÏ-ÈÕG½$KQ˜;?î+[¢[f‹ »¯OkåO¥ÄXŞıÇûR‚ºRâxÑíkv>4§ ÎÀè¶ÏÑ0ï?
ºIåŸÂÇ?hğôpÂÌ¡íæ&11Fzşˆ¨næ÷ß“­-R"-ıóßAı7r\—º$î•…À£åı”·	ã–ö¥ñLs `Bps(ö¢†cS–È®%Ğ)YqNÆ£plyMÛô%ÿáœŞv¸âZ£í}ç—H næ8àŸa¨}:ÅC!0¯+ã\á™Ñ@¼zàsø†0&Œ	R¸ÿŒ[ºˆ6R¥ğhÏ±>áĞfazI/ã¿#S—_ªâq-³åìğ(£İûµW“¡¸O 6«zknú÷èoğ­_`Y‚ÌÌ7‹¶e.Wq=ê×^ˆ=²/Î1 ˜Œ
.¼îˆ¸ÚvØ‚e Qc9&áV´¶'Í¦‡¤íö®¦ßƒtêÁã¤GG3Â¦J&4®põ•r&#İrğPMYP[N0J”E·üåarU~¾ØICkXXá·$!‡J¾/³Ğ«&JiÉåä”»¤´¨E¨Ä˜1QÂdéìÀ$mÆ¯&¬ÊBdqÌ­XÈî ÑG`2FA¨îî™1÷æĞ§ŠŞù™h˜ˆ`˜€ËãÍåjŠCjı—Vñ‚axt‹ù	ğ([GdÕZyÓ×M‹¨Õ|ø-Â¥jêà9	x,ŸÿÏòŸğ†Çµ.§3D§­Œ)£@HtŞÖ0›cp’ğä7éóÿ’¹şÑÔÙ+ú=D5ÉFY¿ÚX0£’n˜#(ĞI!Ñğ¦¦Ò¨¢Ø0G;gHdrkú×¨Ìï„°jôqUV«^ÃŒAèºí·¼é^6ºìp/w0¹PŠA»Û_«ıÄôCPU'–3„?fíT ‚Wæ¢Û"%Ö8ãå×í^ÿ€õÂÓ"òĞ ìãĞğAçÁÅ€µP´q°‘f(ç”×2¦J}YÓ¼i¨j`ãÕ’UVÀ&¦”(­€I…l”ğâŸ\W,DÓØĞ®Şa×Wï5c#´ª%$·e‰?Â³ò¶H¼=âi3`Éy²o*É¶˜L¯ˆ®eÌf<ùÚJš¯]-#2+oBAÁôwf,‘%{r“s·ku{É±_Ú7O@ybÇ™Æ©m
oÉ¶r¨¸1K)ÆÎƒÂÍ =_Œ%ÅNe§RÍâZæ/Ç9Ü„B”—Áğehñù[º­œ¶Àš®j¹¡­HV¸
İª«dŠ 2úÂcÅÒ•FØ=d}Æ’µ'õ7aŞ¬º[©^±5ãéD§©ßhôá1¬½
Ë‘ÊÙË<¤ïş¹têÌaU-#ÔÉÇ5ë¹8n‘Ñn‹t¡$p±«%®­äd×é’”¿5¥d{V–¡ÈNÖš}Y†ÔWº3ĞÒ:‹;H©€—)‘,T¤KsĞ0e@	bd…pI½œìËbô}"„bg)°ë£¬zÌ‡K­‰i››Vi%,šˆ•òôy
Ş“óÊ³<ùpëÚµofSWL$Áí©WÂçL.	Ä—òï MR|íXB°²›¬d 27!§$T?\&#‘/:Jq:Ï¡â¾ı…&GHÇ‚°™E%’L‰Ï%ÅPâl“ ÎÇÊäğ—e—„—ésSˆ¤T'’tã>„$ïä$Ö"ÿ¼!Ù»°%HÔT.˜B
 ¥}²gZ¼ä•ğØ"Å"ë5Jö´şñBöh"‡(OB¾àäâk]$Ï.b†BºF_ÕÅiM‹Y<$B”¬çK&å§Ä=yã<k^r€ò´FêŠ}j}s P9?_05‘ÚD’¬Kq"æü,¸¼ı§«Å.šø…WÌ™`ßßp`eÙ×8¼"¯Š(oa1ó¿Xtoa'‚ÊÌ—¶Á“³ÓAé¨Q½{GYQ:öH—¶[hr– LØİ§`GÇmìÌU{ÚØWšÔ'{¥WóMÇÌ-÷š1rh1”¼JH‘‹ğImY;Ä’[?ºÏœÊlG(+åh­AÊš¦æÌÛß¥VÃğÏJş@–İÙ¤×è÷›ç§½ÅÅbæ:ıSîÕ­q;.u§|ÉU¹<{“¹$Wä³ìS9ÀMm¿–oƒ2P›Ìí,§+ÈßîÜO»ÒÊÙOÅhÚšK–—mz˜‘}ÂáFú¨‹|é{|9×ø²·ø’—øwøÂ+|Ëoğ}|éû{ğğKe2]4ecÕm»§µä·îØVÜ¾+~£‡ÑE¾ÔJù·òJåÅ6¾p¥`,Ë×jÙ¤sÇ³zÒÿzPLÜ¹Œ·ï€×¸|ù´»—9W/¿úÍËõ/^2ÙˆÎUà'\_Ùï©‚«“^p˜r–r9‹;§kµHºyèƒ»¨ë´H9|Çòˆå—Î`öäØ?emäC"”™·|jsl
|~÷gñ>é‘9!ù˜âŠÅüù­‹PˆñÀ”9Åø=5É‚ïŸ(üMÅCâßâ‹µĞĞa‡ı3‘§¶h·«ğ6ÑÊÅ-%ìÊÃøù×Î¶ÂOÌR2¼O|q‚ë3ø‘şëfœ4[ëıöY½ß<ª·Z¿
sÑm0O£¦Í° Cãü²¶ä›x…RòÆlØæ€~ÈI8yßîËı®]Œ¶æPŞ­w‡æì ×n°Ë æ²Q rCê·Ş=íÕ6ËÏ·6R¸
5øöùÿÛû¶í6cÑıŠùŠÖ ±HE ’ºXå‘Ì˜¹ 2²#za‰!5€Á™P¢ß9ïÉ:yu~ìÔ¥»§{. HKÜ>	àe˜ékuuuUu]¨™»3T Ö+Ô¤©’^#SÛí7_/…ßİó =Ì+wùG­¬[kOƒgµOU5··÷~şü4øãWy‚ƒkTT`ÛOº` ‡ŒäğÔDşĞ]U¿+E°Áº ™ª_OŸª¨%¦EóZ“.n¾adO9‘±O_jª	aÌå¿ş|·ĞÆªdÿÉ£ÍÚe¦ÁwyE$h“Hø•ÕÆ›òRğÇ—&÷Ùw¨ÍTnyn«±æ‚ p€¢l¹ÇG/ëİïßÅ’¼é{åYg|Dáı(NMŒ/à$~¶Ç=¥á÷ØJşÄm¢v¶I‰šÒnO)hÍ¯Pğ¹ËMÉ‹@‚ÙØùº©2¥ë>kß<kÊiã”‹¤€…öo~ÚbÈ-¢W®İYÄAt¦1µ!°ÒE£#§€ÜZ¦^Zˆñd8ÚJmE9Pöğş=†#À8š‘®S¬ÛUŠÈ´emv%+lâImVâÏ~´êVVµS©¶f7`Y^¸ªg¨·^Z¯$’%mWè6Ê(9hi›×AAĞX«> çDâKÑN¨p%A®¿ˆü‰¸[Šæ'8N28aì¾«ùìï8ìEjä§L?âfù®ùd rò°],¼I…Ñ-²)í Pzäã“'v³-jváâæ‚Œÿ~;È	I¿ä×ßø*G.õVó„£Q8®ÇïüáğK§ÿ˜›ÿ£µö0›ÿ£µö`ÿoÿoNü¿Ë4şßZ£eÆÿ{Ğ,ˆş—fğ€ocˆ“dcûİ»ôŞÿ#ô2†á y°¥“w@AfúÈ»ÄizŞ>¨ñ¥$»¹¥NüØ(föÀ{ãAß 	ÄıÅÔ‡èš1ğÏ†Àrˆ:ÈüfàéYüoŸ‰÷œJî”,Ã¶K7L‚é­Yc@Ïœ4a ‹Û@['®„~lxbßqÅ7ÏÖ9ÉCˆ–&‚$u‘U¬­X{ï|r_À€#qO ß& Qj-\8Ò½¡£<X§•ìiJËCm‰¼í]2ÆpIñóp:ˆ0-è§“õzKomİ}}ğºs· f6ÈÜÚzş¹˜xIÀIT°:eÚÑÓÒšP±¸v‚F‹¿“”e¤P 1}¬Tä\IÁ(ªjê—xZ!À«^t%ÀUı&H¢ÛíÈO(Öò{¼˜¬¡QKØ°=Aş^éá™‡\_¨Fµ‘/_]ubùŠuÑûú°QúOğÄÜZY-BÀo¾É Ñ°™¢¶÷ôh·jëõS•ı¥â6ĞºÓÚ'øÚl4›âójŠ½ôK (JìåE©pB”J•¹y÷„3–<Ò[¯şK»ş—µú·O^µƒ¬	2}Â²°şGá'°§#?
8IGnTéÔèÊÇGa&Õ8)«¿r|9-ƒô©D¶Oz‡{»GG¿»íŸ°U¹2T*]œ,q`IÖ]@Ë¬¯p:S'½£´ô‰È<æT:v†dEŞÜb¼”_ÌÁ‹"ï
‘Ta"Ïqa•ì,tIüœI°©¥ßyiKæ€ÔÊ¥Sİ{5³±h¤ˆ,HË0x¿7€ÿµêT±(}#`iÄ©áàŸ=½B't?Â³Z¥M)0s“ƒ~Ji8¶tõ¤öµUk=Õ¿õ†•>åó÷ıVmC?•3˜Êm@ÖrÈREÄ¡_ÊHÏbm€·ÀS«dÈ”‡‘BVƒ2‹(Z¯ÂA#¸?ÂL¹–Ãed¨yt‚
ïˆàYè'²ãÙs.å:w _ß…„ã}¶äoZÌÃ€Ï8ÒHrQTma(ÍqmÖÍèO²Eæ$ø¹&u¶Úß¤JC¯Ü~`ÃÉ†
Pó‡SW’l€”‰ÏQo&G`§šU)W‹èï­©±ù½Lşd|£éU›€*ßÒ!Z±À¹äJQ+İÔÕºö>^	ˆ3RÕLF	«®^-ÓûÃß¶2Ú^YhXX Ÿ»rŠº®)R›eEU¡"Ôº5ïO¿Œ1Ş×Ä·ß„Â¶×’L6-ãJKïW®³4¢ëyÊ°ŠXİ0L€pÙ]¨z£`•¸%´bue8JQ©daŠ¹*)•‚²úı³iâAr WÍ8t¢(Œ)W} ‘üòa*°£é˜|uáT”`#¾‡ÀiÆ'ã[°»"ĞóoÖXø/ILDƒR|)·
Ûq;ôé¤ÂÚ­©ª–Ÿ¯§ÿ£È}´Tú_Eÿ7#ÿ3|ßÌëÿZKıß2ÿïuóÿ–éûtÆ^+!/£{’KÛáESRğ5œj×?¢âw}øğ¡q\z!ûÂ@õÆiÔ„#ÂköPíWçŞêŞ4	UÛá¸ãëZkèE·¤ì›»ûéxVV^c“×Ù4‚3Á¿á8ÍÊöÁşa·s¸÷)^à%°2Ÿğ!FıÙé½¥¯ÛøX³´D½Ee°á-WFãõz<x¯‚ˆ×1‚Ÿ¨¿uÏ›ÀŠÕëF¸püû}¿ •)ÊFfA;ua¬Ø'ëg±µ%ê÷ÄÏÿaLÕj ƒ8lëo_Â‘«T¯Ëê«Ù+-*1\Îõ—¢¤VpôÅkÔ¯U£Ñ¼~/\Gõ3/ÿ“Šçy»ô¿µùàÑZşo,ó?-éÿ<ú?#ÔƒÙ	 RT_0áSæ4a‡Š˜*ÒÈ¡Â0m¡#¹%z_ıÅ	’IŒ!
0r¦pí¼Úúˆ'; ¶_·_uºııƒã½NOZê­Ízù©ôİ²täPPRªsTcÂöÎŒˆbw‘
™ëê…êÈQùÑ¢ÊlB "rbÃÉjß\1qĞK5»‰ãEŞd¸”(rŞ+8(ûh÷	&iÂ•ŞÎ:5ñÈ»Î°â.'¸²»:¿(<í£u;›PÜÃ£v·×h ã®	ı”âÚIÃ#W9ÿe÷P]7ŸsÖ±7è©5^(»)[MÃ¯2æq•Õ2úCE­Ç§uÓ« Á•„çÈÖL«2&ñ¿Şr3:™şÀÇƒr€¬J
Œ·ve¾1IõfEë®AOoXzvY,Ã‘.í7Æ‰Îë¬å?{çŸ½B¥¾ñfÖ ¼~#cV'£Â¦fˆôBU¥ª}ús³Ã~ğø*‹a&kŸ^t÷Û{ŸOÆnz©ß“b¢±†Ï|{ÖÒ´“l·÷Úoö7e¢ ¾tTW: eš¦YH3|N3,íww:4AÎ€Û'FqE»`,n+R˜úÙ6À.˜Z¹inI#l³‹-ã'M’{x¸UjGÿ‘=²I úEIÅÙôM_ïé~pÙíœöÑœ“ò%›KFTÉÁ•;d6J^ÿFu»á4xŸZÑÂ°‰Uj’ÛäbRƒuŠñ~
Ó’ë–MÍª¥•ÏdÕXèX\F»¸)8ë5ŞØpèºlX`sgAÛU Û‹ãİ½˜Q·½ß9‚Á@k§!kı7Œ'b¾ßó©»­;[·«§^rç0Yyÿx¼_8r×c
ÉM6+@bï³ÂÃPÓu>O†õÃu»/ğ#ä‰‚1=Â\—BfÆğátO'´<"éÅdì%^25İ@{€+Jwr*®Q³(•ÕæS-—å8&^±³*yG¡'”H|ÔØ¯’^”¨*jRÃ©€!yÃàôr-K‰°¨İCgYŞƒ_†[ƒ­+R:m¥]yÓÙ™µ#7øïV2–¶c…Ã±È„¥ßñOXâoïÂ.Zk›bï¨w_pÙ}»h=FgY+§LšğAİÀl™Š®&ï¹“¤0#œWWİİ£ƒÏo¼hîÑñ¢a ãVQ‘‰W—¤feÀc—QBVa»Ã
ú2¸Öà>ÿÜLæ«|GºhúŠ„ #èm(AÛ`4'èõKÆ8}3şu«¹±¦CKõûSŒ@¢»—sÚ†›f{™Ç_}xçÃ^– OÎ£Ö2#nÅ}[ñoS¿Z-{ U2®
 i^ÄlÈR¬¬±í”d‘²"œk‘Ä@ÂÕ´Èî¨¶)js&}×"×Ï®ÁGŒ'gã„S5šFS8˜ÉùtH’ÚtŒÒGˆ‹ú@)éa.ZiGZµĞjÈ©¸*_ltKIôW˜)Š3*9hMLUP$²>²c»=¥¼Ù¼zª¦©EÃÊ~Â4–I'P+kş=:îÉ¦òì<:ùkc™¸O@o…ãi¨SLÏ 	æoj’Ìş*4Qœ§¡
$(ÍT²E3Íš˜Ûã,€qI*9Ë.-\Ü>Ó¦ÜÙ1Ti’]zƒÅ/ŸAåæ£ïnX¸-®X iù
q›@c¢d`³é¯Zé«×ıWÇ»},¡ŞØ€˜…k¤œ¥Ô™u¸
»áƒR_æØ(ÁÈ1ªy¹n­o2…ôàQ<ƒûU'¡çÀ
æ›ƒìÚÈghÆ# 4ØÖÉ÷²ÙsÑÍÂ#'h¥¡›‰a©«Ó¸fl,	e]éJ…vGxŒIÚ§9‘ıÃ½İíİ£~{ûhê6:Ù­Äxoà‚LYIYup©¾T<><•bÑáÖAÛ×£İıNÿM{÷HÄşY8ÄBŒmË­)*ÂÊRÜTœüñŒÙV-å†KÛ]ˆ
<Í™Jdp~ŞDibzçkª7{¦ÖDÓÜ|®âkQ±›P.:ŞSÊ®yˆÕ%>şGáãÿúiÌÃ›HwU8&¼H­5+B~÷V­Bš¥ß_‚ì8Ğ÷ÄwlÈµõü›uÃXÛ%Cìß™ı‡©ÿâ}ÌöÿÚ|øpóAæşoãÁúÃåıßòşïºöúú¯UtıçZW@‹İûmZÈ†´åHÉàmİüMPı…âìƒ£ûty'SÉ‰\;‹`FQç>©‡·ŠS¾¦¹Z°9¼FgeÙİİuKMŸëÅv'ËF¨`£µÖG¾¶¨-
Ğ+#Û—(JAN|>)ÉLÅ¹IvÖ%äíŸ
’Ùº²ÓLÛ±u#ÆèÍ"<vÓ^¼’¸;j4Œ"Ã®Êà(€¸Õ–†XÚU6zªÕ?W¢ •l:¦\#ùš¸êyğ1¦ÍŞBn¿¬ç’ŠÏÈRkù(z‰X †òs§Nï¦ßåÒIÈøëiˆ-Pv9Rï]$İ¥{ûº@0#ÿØ²+	¼Ú†xOqS¹Y™T=Uºû9RJÅ£§ì:”®rÆ<´ƒö¢‘÷‹?ö„Ì‰ú¯ÿó¯ÿH‡§šr£ÏÃ0S9ñÎÂÄ/²FOïP“)Ø`òşBÔ‡¢Öb³¯Ôå‹ÊHw/™0
Sı™n{¸0Â›$uXöC;Ö¯ˆ?.íES KPp2Aİo‰Ÿ
pŸü^İÑšöô„.@Ó†;	¨ßÊi b]6ªÆøâ›=•ÜzÅ¨¨Jm§íIJ…qa·éåp»ÇŠ¾¿FCöwáÚMúàŞh¬5Öî
§$$„BªNg§|ˆ†$/[:å‡Ú<æsŞP—´µ):tŞdk¸1â$õE£ ¬ïŸÂ”±Ÿø-Û,–ÜÙe‚ÊvĞàW×-ÒC‰(ÛWad¹ûB3÷X¶déÕ¢¤ü`¥èFbì'$ô¦Ã ¹º#¢+™£;¼ÆÚõ:ãË0âë»È…a	á½p=y¯Ù¼ô8“VÂçqÀÙ`b6]İ¾C¯?èá]ÚVÿœOu:xÃb*IºÀÑ7_z‡é&Çú¹Á<QTFô+œÒÕX˜Ä5Ÿ&òJ¦^ŸL£_¨|¦ßÖï”lµîE‘±Ÿü©Ûy,ÈÉãÜ›ÁP{ñ?¡‘¢®°³COH&A{ºÑÇõ¿Fş*“LÇƒ4¡*³EizS¢H²J¬ªr>D—>DFT‰3;ò–äCÀ×$•Ê=ºs¥‡´>§?$tĞ
XÇ¢6_¡Ñ=ĞI€ÅOÆ½$œLèf†=øS%CÅœ
”•.ÑL9şÔşs›ÍÖÜZZL÷.×Şâ=àmsLÖÆ	#IM·b8Ø?5NiÃ¿ZZ¿TÕ±0ğ'±#ìøèG†2ß†{O?]ìntê¨{?Fœ´Z¤gŠJÌªdh¶¾ÌÒÜìõl†ğ´LM)~3·b`=?Ô§c4˜à…*™H5aÒ¿›·æçÀ@ÖGÆñÅmĞJ|2Ğ³“©a:ó¾º#«M¢ğ‚éfCKòß1¯³fò˜_¤‡ÀÊàupeb}‰ÆÁñA(/¶£0vìëİŒûå†åTh#°¯©D’”A¡°›²3²V²Ë¦~“¦£D7÷l•ãîŞ–Î	¹ş¤¶a«JífOÆvkLÉt–ÓB+l´¦P6§Ûû¦Í›Ÿ¹:VôS+Ú`ÖÑôóUçÈVYJÜ@IÅ%«$~ğT×dû$ºÃ³[àŠüİL{AüIäéq<­óÆhH{%KXIËÒıİ×f4ªz}öÉ‡óÂªná/ÁïèA?ŸxÔzK+*dl¹rˆ®KÎä"p¬Ï‡#ª~†C_şéC«W}´£Î|Ù(Sã± šofŞk/zï'ı!´>Æ^^Ä›¼ïSl!2zÈÏ®|áæÀWnÁ•ÌS^Ğ²u®Ï^çúÌuŞÛİî¼î‘™vºm ¥tî#Ú$+G0ã®ar´•æ‘µ_Çù÷Õ›¸"p@ñ 3Æ€Ë½û÷îìMcì™U%\½òSÁˆê*‘Ïîb`ëÊ‘]ëQ¢;.i¢¨ æ§ÛFô¯Ávê§	€óLLUgûívö:í^§Ù Dâ‘Î'xn½FKºâÊ™Ø’v¾ÿdA;Íô’B´0öj@KÊÙÓM!+ªVtfã»ºYø¹v‹î,8ÎlõK@3“Ìæ3†ş!3
Ô;_ØX.ğoøuÛ¯éÊÀãE#4@¡áì\?
Èqx(¤Õhsèmz~Ñõ!a½R[¯.NŒm*ÍİªÆ>“ŠŒ›A¿×İîï½ş¡'„¨’–àÜ@øzq¢,ÑÅ}‘@7)'Ì­gw¢°gFïsÑ'ßä—dàh0L.Ş@NÖ¡ÄÚ?ÏQŒÁEôIÚZqÏ†á˜2ÊÑ”uWS}ŠÿŒ#€<Ó¡ÿ!€UPÚtKí×ÌUUÜ†a£gh2e#Dö¿ÀnjŸô{vÍ(\…Åq€•ó×ÆL¨Vª şÑ£G¢Ş½,˜y©42…˜5¯’ÒB¬qo6¨ëŒJj´¾	Í§¸&UÔ8!‚Ù's¶€Ğ~^y(šQàmÈzKT1ZmÑÏ< &ÅˆÖÓD÷¦ä_ÿˆ‚½^”é|@JMô¦'¦¨ø€ã®Ÿ	í9Éœ{©ªŞ(Æ:<¢îOŞÄÄFuUÕM j#½(ğã&¿1©·­µÆƒ:¼j$^ÔøøÁ¸d$__•t«Xët‹¬ÆÇKJscú™fÓP[o3I:ÍW&gùŠ2¿SèCÌÒyDê+Æ%Be42Æg‹1š|¹wgÁÔ¬F¾âÌ¬›•{Å«pÆ	FÑ'ÔÕ1¤\Y«M- rÈ,SF­ye1€®µŒdÆÙy’Iù,Ê»7³;¯à9´‡T@ğZhRÒ­„îƒÁğG~/&+¸{Ãu±_‚1 p4$«æ†5\˜‹XcÏ–W)ÂÿRüŸ	&"ë;­5úg
dv@aõ*1„{;„ı+E–ôŠ¨enè3×ª)ªZnåùE7_k+­7ëMf@D) Jj
m’ÅI J&9%ûÏxğ^”Ñ5>ÒŠ[H°Ìh†ÃKËìµ±ôGßÜØØxôíCtH—ûì†GÒLşCmÅÒ¤ãW×ón´ş ±Şxà²Î”Á°Á²>Æ"jæ(ÁûŞôe{<lò°/jmËQ!]{\s1$±q‰óGÌB¨tzZ‚LõÖõ±iæ¹X^¥¼ÎSã45MzÅO‘"hÍZ*‰“¹‡lb²0ÜSeİ¬½\~†åë¼Qøäæ’„¹‘*tuÑÛ}µûú„[¾fEîÓø..…çè2×ƒ±&»?w 9v¡¡›–‹Ì#?V:¥şLÅœWŞØZ©\oÀ©\ù±ø›h4 aµO%
ÈÂ%Ìêú-}Í»ÍŒÑi¹Î:Ï#çìqd™ãaè‘›ê‰+§UÒ\€Ùf¤•gYÀãRP•·IqëÙ ‘ƒØ	bÀ aØ ïİÛšs†ß ç["Âğ·¹ŞøfÏø÷8W+Êoèƒá ©hO›#Åïä€¨ã	¥Û» OqñµKqµô
Æ~o\X4g]Çä*òİS“¹¤fáÕŒeµC•½Š™ÕEîŠ{fáì%Î‚rW:3 U~½“Ix\î³mâğ|â®Im
\ì®wêŸ‡ä¸@X°9\Şr…îâÊ
yarº^9›{~%ELĞ5«"¡ÚR¾RåŒïø­«x»%½OÈjWFãª˜Ü—;«‚Á«1_a2!ŠÀÃ&<t{]Ÿd¸ƒÖlbîäf—àûyyBÎ$G¿›!ÎãÍˆ¦E6áÔÏƒŠ
°.¬[€ï-}ÙŞİ“tT“N×)¼”6om]Gß«súMe½­}sQLD{h\ îŞíqpŒ¢ì^ıN™Û:¯dxC2-Å:±OEùRQ3/JfGÒs|ÍÙ4Â„í}Œ'S…~2vÒçÌVâF;H[-ÛHÆ‘„TŞÙ2æiWÉu¿Ç‰Àb|*Â'éWQï–Npn½£Á`NŠ†vPˆ°úFg¤~mL¢ò`âºø´´°ÆİçlE”%<˜÷–Ùe	œtGé¼[ı±ïúúikxRJi5ğ)T„ÙŠÜe„³XÈÔ:şë*z™ğãØ£›³ˆ	™&ĞE¹z„40éGE–Õ”HZÙÂğÿÁÙ;4\]U3/%\À6eg—şPé8¡°lÂ‹Fº	NÓLæEÒèQv¢ò0iÅ²€"2–·H†éRà¬1²ï4 vÜæ>'ÇÌX›+TËšW3!.Dù€uÌU¶° ~©cÒê¦.Ô,C!(Dççeh#HÇšı}!€'£ a¡T¿Õl&8áÎõºr…ïÏøA—’öôÊc–»Xb†ôäwt¸õÈK
óQ_ V… ­áotÊ€xxÿ*JªQrD©1†qi·ÒŸÆ´gBhà«}PûÎI}Œì7æ¯”Iò¦Sß„Šé|!‹ÚütYÏşõüáŸ‰0|ä%°pÖælï[û€’ÀÊÃ¾÷~m’7Ùqc 9åk;ÛóO¦w|’àûıµşZÆ0ê‚µE†“†yZ•†èzcÙÌŒåšƒÙTR¥î½0öfAªé[ft;«ZÆšEŞ3ÛöN2vêÄÉ5§ ^§	óTˆÎ¦œ©O±¿&jØAHòµG­æ2ı¬@ëÎªTøâ3‡•;˜
åÈWX^o0ãâ®° i'ÂârfÒ $vŸ
µƒ3ÆG%e¨9Û½J—Éø¿4…ô[æ~~”V¡meÌ|ÇNçeûxï¨ rµG×²Àfô‚Ñi²8P‰÷Ôû¸´w^$áñÀ¿ä`:AB1"÷Â‹ÙqÄ*dj2Ÿ³ªÚó—Çô¦¶0wVãV-	8-˜0ÕºE¥$ÁSîé˜ôt.µpR„^<¼óoÆÇ!ï`qr7W+¿N.ÃRá8ÓQÌ×¾F0Ë*•Ğ}Pú²¼‘×@í·Ğ"Ì<^ŠgVr´°åÀu(vé!õ%HpÉ1;‹*Wç’eÙ(•ƒ·TÔ™ÉÌFÜXcµ™S£8ÌBiuGò¶=lz‰Xp€(ˆ|­säkœ	ÖàX!ânb¸\•gŠ£¢²Ø4Í¹«ÂÏ¥FÈÅ&K=|¸›G¶À ‹÷á ²-Ö\+Qm¥$<AY<Œ5SY=#f+j®7T+àr6¸ìVqÈÙù“æPKCî ]õ€F{±Ÿ­Ğ\€ºŸ@FB2¢%q[ÉÃÔMéœ×fPTÃS(±€×pĞ"¤Ïğßp -ˆÊÃ’TòQ’l3›÷ZÚ)o7#Üb¸SxşeÃä9Ù“/w¶å!¡NIH§ˆ¨fÔqEª=Q…™C^xè•@qäÑ;™¦j†é/>‡
¨kÖ8š*#§s¨m{€£<Äp©Ix(µ”3N§ÌÙä”E…§^î,˜eø•bşa'*Jnîh(:>ıøf[ÿ×zÔZßÌÅÿÛ\æ\Æÿ»yü¿Ùé¿t®©åşâx€V…K$‡°‘1cäm„ü£N¶ÃaùÑÈ‘ç÷pbÖîøo[O7ÖGwÕ‹ö~»ÛÙ;àWkğn#}×;~|Ç÷í|½©Ë²²µ´¸º`Ôİ¼ë[mR±M«`û/Ç{ºÍô9_UÊaÂc'zšÉhÂ\Qè´r"šrcZ_zè5'“$_)†³"›	ÅyÅÉLL_yå'¶f¡AhGf­l(«}§ÅıKèŸù¡ÿ²âîª£©:1nâ(ö­¨vÛ»;°v/v;¯:ŒpÎ­ ªcò*¦_W|%ìTøãÎ«şNû¨İßÙíö¶\Œf×Œßy‘ÿ„¾RÒQù wi¼tBæÖ¥€™—2c
Ş¡O’“ä?DŞÄŞ©u•áIqz	\lç0üàGqz%v¼qàÅÁHXyè?ù‹GUÇQ@Øé¼Øm¿î¿ìÀ²½ŞÙr/ÆÉQ½–nÂ¨SRYµŒ‹!û©TìOPlTQÉ¦jÿ;?š=äøZs)£€”}Àö÷I8äş8¸À+Q­¿w:½WöáQÿàğÈhĞ
~â’àØOgS¯1=%Ó(-j„EÙh­?v
‚«˜Í=1£-¤Ö¡]4dŒ8PºØMêgøè¶¥uó5ZŸÏl;õÀÄxN¡ÁÃF«Ñ2ß‘…ÿÌÑ÷Ì¦×óƒ²8«ÎÌà3_«¸\¨0¾ÀªÌP)=;SP^É»é)Áñ¯£‰ƒWâÏˆ~¯L.6û,\#
 $OvfÛŒ8¾eûÇÚåtö²Ù¡qÑ3Õt˜D•z,å|€™É¸­7İz‡ím«Ec”; Å“ÜÊÙ„Ğz±ª›Å37j<ñÎ|§ 9›jÏÈä–™Ë~çõq÷¨³o•/¦ÒM#Rl4Õ$ÂuŸ0„äÈWßll"‚ÊRïäcåîiÕÌyHr9]×|˜sÁD…6Pîßâƒiº&n¹³ËÊy!…-^ÌÃA—”>gé€•ª,¨G§S†º	Iêœ¶qÆ}N Âbx°ê©¢í¿åª0Äë|Ñ›ñ²O©Dc­‘Û´ñå¸qùşÄ‹h&ğH¥l&ŞEl(e¹•Ï®“'\ D™çÎ:×®Q<lXŞL¥ñ‹ózbb5tZıÇtnx”Õ‚ŠhØ@«ñ¸A% ÜÙzq8¼h$İƒ^¯ßîî«ç‘¼ËIÉ–•¨ôE‡ÈÛ><––Ñ[hÛrĞÓ¿¤ ÔuÔs`ß¿tQ@/àv4º|ä¹BñG‡İÎËİ·»B™14,_8¸…ÇÆá,_Éx
2(”ëœƒ·víOƒºL…6ß^ÉıSàñ/€4$çùˆŸô±©Æpò"@#/ºª³®ÎÁ(‹NŒB(qø¦-› »_jÈògZŠÜhÀ_s¼¤]›Ëíôëw5Æó³¡Fã{ÿËh@µÛyÕùQü¹İİE’Ñsœ7İ¾uºøÄáşe*×;ÜÛ=:êìÀ†é¶Ãª}"º×<i6ÅçU.Ø;JËam36$şàôc«Uø—À©œ^$ïBé_À=N‚§Ósãá™Dáºú{ä"l¥o?&q¢¾{É{ãÍÅ»³ºê	Ï†‹á4ÙH¿Ñs×ICUn¹#<¥{YŒ›OOU¦=ÊËKü Æ¯¹ıâØ‘o:¼HûÄ1÷ëNÍ ¸ƒ÷B\€•–Ñ»W¢ÍDSªB&UL#9ãõ‰O…RìØÄMY>­o8ƒNp*Æá¸“wecu4°ûBÅ~ûög-¢æ/£Š¯,´üT">ó²øöFçşÙZGƒbL¾ƒ
6¾3rt®l|5N¼OXòn4MÍ	ÈH'IöY*ï¿õ(ÂHüsjïNz Îç·á$óŠ;H+ÇĞœ~ûDIşi»ß´‹™•?–Ôh4=àë3à2ı§ê$?%µ™ã±´Ã\İéXÛøãeÔzüú÷ùİ©Ëú;
Å_§q¢oô¨Û4ò
…#@5*zO@9µ;½K/¢zóLÁÎ]?JØ7Ğ0™&®ıhP¶Ï	ËzébËc"F)KºC”w¡Fç÷œ5˜„.Çğ|²2ô¸‹æ`aCîc9h-÷›Ïì¨xÀ[åINfEä6±ï„yW¨4°énüş wd”æ$°éë×Çû/:İì^½ÑdèÃÎÌÄBÜâ®A0[k´6Zª3Ô,É‰1c—šËë0Á>ÌÁ0õ_ÿ)^\i/Do+kÜÂ…ãsÌÖ´Mgåï‹@Ş%±Ğ3ğ4aGš}lN•ûÛà‚ö¯»çX
ÓÑ¢òÊ¬N›µØØ©¹İéÒWÍŒØ	'ï³]–SaMŸ(l¨Ó³vfôÈÍÔM|şÎŞá•È×#©T’G­ï t~ÛœD>Îº?Uj¡Ì]¢‘ÊÌ¤w|ˆ>ñ}†Ùí}%µlûfSdQÅæ¼)š‚é‘éî-ÊLJ F©·†ÿ>©‚F¿Ô(åRëÍ¼êÚ
ï8W3€áİO#o|öÙîà#0Ü(Xç+Öló»e8¿ìüØÙ.kX¥n¦é‘J0eèšo€ÌW·\cìéËùDo­?Î¾Ìû7£NhÙ†î­Ø¹wëîú#,v÷.#‹>ÿµüüói4áYÜüª} •Ç£Jì?è“±ÿhµ<ü/ñ`iÿq[ëìTc4øŠë_nÿ³¶¹ñèQfı××.óŞÊçŞ½oÆ§ñä©ù¯É`¯´Vù¡@ƒÑ^ˆÖc‘¯“ÿ×ºv‡Ö€/¾ğ©(2ıß»ç8÷î½	¾=›<w¤óX.ıC~lÙ@¨oI˜VuMjş<ÇNz»¯{»½ùÙbHéKìüí³8‰ÂñÅsÖŒ<kÊŸ?§o€gƒ7½ôÕÌŞn\O¤5µÔiÇx-%dóeöKÏE³1u%-B[q(ºæ§•Y®No»»K0°WL~,DYJ‡&ƒÎİïAˆ:<ºH‚y’Fh\óî¡¬oYì#­ƒÖ„`ñTBİÖu”m%¡í“RY¼áP»jŒ`\ùÊ`ÀŠ©CÈ@I"Éâ=dß,³­U.¦òivCLYD½RÚ …yÅÆ2¥ ¦Rø+ÏJ[*Âa.ó§œ–,M½.Õd„2JQfjÊ†¡)«%˜Ï‰^Ù,x+±îç¿ıí­lägkj±Ï9MŒ‰ $½JúŠu:F”MôëÌP”†'óXjxfÒ]O}]nTQ¤ôãÅñ«­Ö|øÇ¼ÇÕeÅä2IAcpå¼ñ• Ã\Óğ<şv°T³gátœ`Z?•O~µåz£2ÈÎ¡Ô—Ñ–,ÉìÚ¥ó—Í–`+–HºËv¶†7şĞ›¢Œ¥ğ@K{àH{ù3Ø"xõC!`’Wz£ÇRí‰=õÃ1÷ˆdõøèûƒ.t*GThº'œ¥ü§ùÿ¯'Ş@ş{´ÑZÊ·¼şæN¿ÍõßXƒÅ¶×scm)ÿİÎúŸ¸Èè l&0ø•%Õ4¾·%ªÇÂ5Ä@WH‹lá“3Ê{®Óè}/Ppsì3èd†`†U”æØ£9^,#Zœ¿`Væä¼û3ı”ìşÆÂÉ	OùB…e$‹„e2U„<şJ«j]ê¤~Â'dş	sÇÖó”GµÜõœ®ùh* ;C&r¾¤üc‹?ØÆo~p ¾N^Bú’+iæ–Ğw2 ¢¢‹gE\œB87P™#}u%pu•‘1ŒbÖ’aÙ2iÂ¨Ãëy¢jÍfİ®[2Ã*ÌìíWÈü«!)–Ç£¦F¬5>Œ¾|ü5=U=NM1¡›õÆì;£5o9ÍŠÃ ä3Ãæ¿iôĞÏ:xR¸×3m¥°¤=ZÅ-ãÄ7v®Ï3ûËLñ˜wñÃN–^Ğƒ~Øoı÷»0yÁëW%güÅÿ‡€4èÈƒò\\Æçá¼˜£ÿ__{”åÿ¬o<Zò·âÿ+"3´ô¢ëÿ¯©ùHcQuH/Ryv=GC¥8ãK§	Í­‘ï3í91—8ÆV µ@¶öäYšÆÂ¡H®&ş–»ëÂÏÊ³ağœbÍ’İ„°ÜÄ
ëò¤‹Å*Š1/9Ágxùç…nALå‘#Q¿™ÒVWÃš§Ãğdh3jv;íı ½û\©9ø‘Ör<kzÏá@#ŸsLT>„Qëˆ
gM˜‰œº(£Ä…9Mí°¢I>Ñ5d<‚µtLn~¢)vØäó…ÃüùŒØ1šQ0<'şøO;?<mÓòî@YyÁQaDËVZF¯ZM¾Œ|ÿ,4D/¡l­uU‹¿şSüúw«Ùc{.äx‘E|dQÑNr@¨ïğ?ˆ¼3è	
YÕå¹_a<&óD§‘àÀ›X÷ƒ€p)‚'X{7¹[*½8bÄ³xK".UoI÷p­‚Mõ'ğê…7ğ&†ŞÜ›t”S¹^ôf8Ä]!ÿô¸&Z¢!bÈŸæ®ié]óRÍ¤å“Ÿ*p¨Ñ€Û€HÀ@Ñ˜zÇÄT£JZZšG(õkbÉü{ÿ*ªçïK[Ì9ÿ7Ös÷ÿ›Ëø·uş[Gz—ñ@r(ğ©†tØd£‘TœbŞ±ÿAœû^2âI$ötz!Èè­á8—™CÔÅÁYúÑ}2#pĞ“YI*_wŞôŒ‹Ê³éPQ¨]LÌ4˜áAáQoúüOÄ3ôÜ”´ú WM' eÏšğÊ$uù†H<ü-š8%ÁšemCˆ#Å	Æ}HG`ÈM §š@Ò´×aÚİæTò'pœ¢ş¬lş/wìì”  M^¦¢=¦Øfo•lwíé²b­oo gŒË­4ÖLP(59)š/lÕ‰ÊV Ö¢@I2_'[0š¥~ÂÀ`ãğ±!By6â(ºö¾º¯MëôHÒ5äe*+¬ÜÃv­/‘:/Æ‘S_eIxZ’ŒÓ(¡ûÀB! &vGq‹©ñÎCî u‡4°YxçW´e¬èšY¡Q¬šãã1ÿ:Òny3£Æª«øéíîşå£¦\ïëÕƒŞ
ê™ˆ·n±Ö¤íÛŞÛûÊõÂ-ŒîË„¿DÒs¦#]í8baôõQ¡Mp6ºh©t—²«¡	÷€_ÉùÜ)Â…5X¡}ïJ´ÖLX9	1„Ñ¬A{òË¦ R'¥ŒÖÃÆš\{± ½i=Î·=MPJ¤È ğ?Æfo ¯à£8kR. ËcùvÄ$L&lò”vÉÀıfşï«]û-zÿÌŞÃ¬ıçÃÖƒ%ÿw+üßNü·4ü›Äö„£K4’îK]>Qª•ñ;÷v‚À¥á¦_¥Î¸íî+tfºçZŞ¹û¯ºÊ}w+7ds¶øöA×ôŞ¡ JÄ*§}a\²nÿè ßùq÷(}¼¾F/Ú½ï·\Ä+İ–J‡9§{,3wXæÈwÒ Ğ‡ovšµì\ŒhÏÅÃÇjĞ?t-,Q[+{ñÉúı‹NŞû,02\9ˆkVå‚;1Å>™‚´4È©„ãzüÎ§¥q‡Â8çÀ£#4A9Nã$Ï”—f/+¤BÔV)”;º/Ö(x4á}<„À¥$ãPãØvã<çÌ¯ÏOÎšQ8¨ä0TM%Š¡Ö¬pÄeÙ2óx§èrœyŞxæ Ê&˜Eş¼@¿årÒ‚—Áx°U[×ùÑps¸j,nMq‹GT< İM+}F›®ö	ÿ4›ºÙægQåÜöÈğ†1!,qt,€ï@öÔ½fîô‚%T$?°U0@öØOÛû;FŒn.g‡ãÎïÃšş.ê]İ^R[›EËµ"oÂW(ÒNW˜^Öa´çìÊÚ=½«ÌM_û®´×CŒ…å‹‚„{„ßïƒ„úœ¼Çt
Â_ŠİŞá^û§­šü"~ä{Íİ#x–~7Ÿ7^³H[¼œD$ŒX`dâ„)^$¦‰”)V$„ß¨³b:&Gi,š?Î˜f*±”bD"J–nÒ¤Û$3Xš<m]-+=”ƒ¥èj¤¦š†µã>ï†a’9?Jº%Âº¡íwÆè\µ™í6¼]ú™–IéŒC†´‘ŠIa4|˜-EÍXX±äóËùÿ©Dú_Q şÿQ)ÿßZÏÅŞl­­/ùÿKş¿ZGßïö¦ğˆöÁ~ûh	öO‚•jÇİÎŞcYDj†S1ò®ß×>MØ~DW÷Å)üFÓ¾j…ÊóÂ7ÉXïÔÃ0N¹°Ğş~‚!õ#R1§YvªfyÀ‹zküa0
²¿ÁP”eÅşğ\ÛIı&GC	ˆ‹ápôÏŸu§­ª5‚°y;B…“Ê&Sƒö^MÌûN3G«ôÓ°ß¨R8eàs83)êõzCœÔVÃ÷ {oBrVİÉÆ!º¾¤Ê·IÿU"lR©ûƒFò1ù
ôÆıßÚúzöşoãÑÃµ%ı¿Ï÷hĞš·íyâTZd–ÁúIè–5¶S9
…¹è>ñµê²ÅÁ,îù
28F—VÅK/7æò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³üü†Ïÿó_LÎ h 