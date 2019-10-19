#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="821560106"
MD5="5c97d79c0f370778f1968745d05a1764"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="18987"
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
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
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
	echo Date of packaging: Sat Oct 19 13:59:07 -03 2019
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDUSIZE=104
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

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
‹ Û@«]ì<ÛrÛ8–y•¾MiÊvº)Úñ¥»íaÏ*¶ìh"[ZIN§'N©(’Ù¦H/²Œ÷_¶öajŸçm_óc{ ’àE;IOMM«R1	 ç†ƒÖ´g_ı·¿ï¿ßÇ¿;ßïoË£ß³İıı{Û»»»Ï¶w¶_¼ØFöŸı¿Ğg¦á8÷KàVÕÿ‹şjÚÈõ¨öõ×ÿ1ë¿³³¿ûûúÿ†ë?ò\ßW‡¡e›Ô«ù×_|ıöö¬ÿüÛË¬ÿŞ‹ƒígdû÷õÿê¿Ê7ÚĞr´¡á_—+ê×şUÊ•KÇšSÏ·LÃ¤dLİ›Àã¹¸äÙĞ%›u{j`	õ¶Ê•c7ô|zHz#‹:#Jİé,„ªrå"rC²]Û­í–+'Ğâìlk;;Ú‹í¡„ú#ÏšÕ¿¦DÉ2ºB,ŸÌ/ î˜ â€Ï­úùÏ0Ç˜ !ık€ã¸ Ä	Ëñ	C6‚áX66d=2¡L
»$–C}2v=RïÏ¿'©×»Ç¯öTRwLÏµÌß„îğ«˜4 £À Áøô?.1]2Ì%0lÃ4ˆã’Î1!>E0ŸÌ?ı·gsf KdL‡°-½|zÚ9ŞÜúHJå’iùÁ`s×«›## Fšåû!­94Ø*—F†¤¯Æp@t‡”K¥çÊå0t‚ìüPS`©Dïf.,ÆØ6&‡ŞB0°_ßú£#Ö¬e9á9·œ€ìü¸~Kê£r<œd»µíÚvÏe·5€)êÊuÌüCMóçNmìQ:3ü‘a×\o‚EĞOŒ‰¯yÔ¦€x°;Øl+&À2h5_:õş+]ÑBßÓlkˆTE;>=‹À† ¢²¡ÕFãIe·ÑjÔ{]YÚñ›F·×l_èbŠkK«J-•„êˆbïRio­)í-Ôbµ5&ïˆJI<» c62Š:qÂÜ¼Èû#”w‡T; ÇÛq±E™0-„Åõî‘CD$ÕB%X@&B™1IK×wÄzÖÄ>ıdiŠ”ÆaRh "ç‘pJ`À7Ä·¦ÃOÿ°­‘Ëú.âM‰ê¥š±š±ÅşÛ!ª¿|òùÆçƒµ}š#CŒBòò	<¡+17ö¿$»¦ó×(.·P;·×Öè©=½QQelÀ®l´J5ÕH!:Qi˜K1g)ª.ê
Æû€º6@{1c(fo[M]“–Hà…ÎM9z—PgNÀ"Ú~÷òâ5‰Õm[ÎM“ÉBñ¢¶­A+1Ø Wı˜+ûÃ•úü!…ºyÑë×[-ö—fGWªh÷ZÍ‹Ë·ƒWíó[DÿÚ ¦ç{°’æŞ›‹~ıì)²‚j2]k ;µÉ¥`v1ÓvóĞÇüD
°ÁÂ,Ä¢BG×.Q
H—+J9QâÕüp B›‹&lÒ¾8m.iĞŒ­€_\ÁL „lÂœŠòK,:Fo¤îM‘CJ£kÃ™Ğ“X‰å&ÊW‹@Jš¸\š7àÚ€6FKÉ_°Ã¶ùwlB;—ƒ~½{Öèëh«v§¯+ª‰¸`ˆ–BÚ½¸û=ä¸Ûîõ8àñ Ş|_'êñøÍiçÍ®B"æët§Í·:®L‰S¡Â¦+À„¢<%±ˆÄJ&g¯}Ù=npŠÊ’Ïº*#ÈZ5ËçØX¢’åƒ5*D\À}J2 BTĞ£•Q?ÜÍÇ¡Ğ/ãº¨ri—˜w¸'
Ëù¢2Õ½ÑõÁ^!­#ıD‘h²ó¬ÿvI³Ô«S…dy¤hx Èë™wEßÈÎ)æÍ¹w¾§¬3²#æÔùÚ’ULµc][—®ôÏ˜1º…‡ø+ÀP°[“ĞCÈ²(?–ÊY¬¶êgƒÓ6ÊOıâ¤Ûnû)Ş‘äQÆÉÅ;r<R½Eü-Ù8RƒÑh"eÁÊŸ2œ”n÷œ¬x|)=LÄ+cI £ÁJäê$»©r©G‘•:Æè6„¹j–cÒ;½ú§r)rHõã üwUV÷şáÑsJ¹%Ÿışû·û‰øŸmLoUğ>Ë™ø*5-Ğ÷_,¸<ş·wp°»›‰ÿílïÿÿû÷ÿM1ô§öÔø‚ñ?Â€ŒÓ§<®WÀñkÆ»ÔŸ¹omÊb{!`J¿FVK,›úµÚoõ£C¬Ÿ¼ÜK“Î™‰!dæYN0&½Ë—½_zıÆ¹®+¡?T¾#õ~¿ûÑ2ßPÇt½(şã›ÆÅI»ûÔ·Oº²}pp /gİö%lgv8¼Ê•³AÈß	(åá¿J5/Ä©šÚş*<“+Â1øÔ›[°šH<8	À²¾C…­Å`Šáı5´æ.rKLÒO—#-…öS2 Ë,h…ÛĞopÓP•÷qr(#C ªI@rèÌ®õÅ¡ÕM#D°¸ø‡mÿùd_+æTÉqe‹Ç£ ş`ë8ğOßÄÑ(•æéIã”[¯Èeà5‚ãÇ‹b'0z {kFà‰LEŒC¬5†–*ªOíj·İî§5Ç¼Ñf¶ óO}M@«ÕŞI¼)Öp!TÀ&BÓ‚gÓ®ù.+…'ÜëÚ°ı X+Ô^íGmæQtÎWó`‚Ø¾—Jêi˜^øoÎU†:Và³`¼	6İB{ş„6^`oğU±j*™ç-dŠhçšaB""¤²Cèey$ŠcDQùŒû[–C-ç™'6p%&z·ış€ÅÌEÊIQ­Ê5äÉ‡„QŒPÕ\*A(a©ğü ¥„™şj$2jò0fœ]ÇÄaÙØ·F#Sˆ"6vqèOÄÓê¦	¬Õ9ó·ã¹¨D™z˜ñgqü€ì3¸ì5º|#SC³æ
`Óˆ@QZ}};iÜÃKõ(&ÃbMøÿaõ¬[?i58B`­ NÓí€%ûkH_Ú†sƒ»c¹{Ñ²~>`hÀ6„8€^9¿ªJU¶"½ÇSQ
'ÍÖVZÙT-l¶6‹Ã‚$Ñ~Ç©Wå7…üô!iŸF#QS—IË¬ÀQ´:ò@Pq¨±âØx"Æìz/EÃÔx’”2KÆT›éíi`YXØ É²ÁÙ1À.˜®OĞÖ9Ìòwa}BÁ¬ĞÊg–RœÔqÿ€=Ø¿vDáf'S®´CĞ( °¢>ôCÃ³\¬
ÆgîÜJÑo¿‰lŸñ€­2µoêÕmqs»ÍU\Ç¾'áÌÇLE÷U2ûQÎ#àU†nTtú‚'µZµTÅ·)‘²†d‘‹] 1Q¡Èæ°Ş:Ò„“G¢v‹Ûs¥#÷’,¦m|6hêšàÉÜZÏŒuâ:]®BVŠ/5ÇAó„3tõ¨¹IQ(øK½{Ùôúõ—­ë'‰\¬± yzäI÷œ’ÔJšb¡¥[“šYŸª€ly]¼&5_ÙWëòàbõ´¼—(Î·f7éUIãXÑ×c¥IîÏSm.ìåëHîb²ÀNcı.Šš‹xXïÖ³@ÃÚî„éF…kË¬Û¶ÜI“2ˆpuyğèà]Qê0ª,¬SØ0ºx» œñÄnâ3ƒøX«¨TA)TšÎØ=D p¥‚ŞöaVÁÄõäÖõn|Ø^QAÑŸÛİ×½Nı¸‘À‰ÔNl,}ó†÷Õ_¤ëÁ˜^9gàQÚ4e7Îvë$&àÕ«™ŞñE?™±ôÂ*Æ¸>ıÎ@pƒÓo·[½*WÄ /N¤Cé…UÊiUi9¹–FVÜ)D‚A½ËN§İíëK˜Há+ÉøQEƒ|XİÄ?[ÑÆã¢İoş2èÁn$uöí¸5¾W}pŞ·Ê¥Ÿ‘»½Ø‹ÏZ^¢ 
`¢ğˆKÄˆJ|ŸéMÁİEê<>»Æ‡WÎ&ä•	’CRÄƒWÎbLêÖd>è³}v¸š±­á—Ï™NJ+±®1Ğ?irc6óÌy…ÍI&…)uB‚›8,Ü{Î¡,9ù¦ĞÎID3f3Ûâ	:~²M©ŒØ91¤„wÌRylM|PÎàF_Sï;/ãÖÙ|T3ÓhDÔÙú3İºîˆ§Ö”j3Šò%Î^¯ÛTkŞ¯Pê&õowÆ6‰vwÂ‹IÃ	¼û÷|­\Sª'‹¥X\iÜÑQêàŒ{_ª
ì95¼{•ïßU¶1.´·\U'¨b/UcÑ<ë‹ÌpÕ3Bs•†ƒ`ršU>ó‡½Ğ¸n(jPÈÚõ©7µÃÖÇˆ/ºŸQ½,‹˜ë10Â„¹¬:Hµİf[AoGy©9ƒ[œõ_]6 ÖLæ×ü8§pöóù±mø¾LS¬=‡ÕbÃ
è] İ©<ÿíˆ½‰‰aİ_EUß½-®³Œ¨ña¥ °8]âÑBDœc
1Œv“®¹&…NmãÏò5½Ebú:ˆuø<B§¥âLÖ§ÎQšHï:;£^pxøV}}ÒP/`*sÚ¸¨ƒî}²~ÿÙp§Á
ŞvHõ½¾Uy^¨zF­zâNa÷¬GŒcRÛ",Ú­‹48o\\šıÆy^*Œ³\Ãæ‹|{GŠÚAõ¬°ºAu;¸v§4ÂŠ)C(³¸ÃY?sğè˜D¹‘×ÔÕ&´ay‘†	|­ù÷~@§*{Q'¡eR”¡Í€ ©`•BØ—MÕĞ§^í:˜Ú5Ô#ñØqâ
9^\ÄP»›ÚR4b·Îz‡'Ü„¬"n*’´~„zzãà3cÂ"ädòôXÛ7/šì$%ÉA ,á†G²€P&Î™c>ö@âr‘r"´×x³A®mÒVTWV[Z%g
ò[’Qûv.Ìe7.ùáÈæc^Päç›«4L~ˆ±e*@V.ıjÌÈ_õõÍ$ó×ùTÃJõt€ó«y£SOğÜ
<c„ÑK²…µûÃ²%ºe¶H²ÆT¯~¬¤Æòî?Ş?
Ô€Ğè—À‹á\³ó¡9uFÀp†yÿqĞM*ÿ=şAƒ§ç€fm77‰…1Ò#øóGDt³¾ı–lm‘
iŸşîòè¿‘ëyÔ#I¯,/ïÇô¸-·´/MfZ ˆ C‚›#±5]‡²Ì@v-NÉŠs2…cËk9V ùô¶Ã­×Òmï»?Ç±p3ÇÿCíÓ)
y]çŠÎŒâÕŸ#0…1aLÁıgÜÒÅ´‘*…G{õ)‡6ÓKÃø˜à%™j´üRwŒõÜ–³Ã Ìvï—.BqŸ lVôÖÜ
îÑßà[¿Ğ¶™™ooË<®âz4Ğ_ˆ=r Î1 ˜Œ.¼îˆ8};jÁ2ÎÁ¨ƒ±†“h+ªïK³é!©#»ı™+…é÷ FxÇ8icãÑÑŒ¨©’+\}eœÉ˜c7¤Ü<TS$ÔV3ŒUÑ-ùLG˜\UŸ/vF²ĞÖ@øÀ-IÉ¡RìË,ôª‰R@E²#d99å.í-j)1fL”(Y:?0I›ñ«	«§²Ys+—ò;Hô˜ŒQª»{fÌı9ô©¢·E~"&"8!&àòxsu'Ã€µşK«ùá0:ºÅüx”­#²ª^İË&êN1üá¿J5uñœ<–OÿgÀOxÃãÚÓâÓVÆ”q $>ïë˜­18Ixò›ÅôéÉÜø`ìŒı¢Zd£j\m,˜QÅ0­$Œ‘.xSSiTñl”Ï£3$2¹µ‚kTæwBX5ú¸*«U¯aÆ tİö[Ştß4ºìp¯p0…PŠA»Û_«ıÄ
"PU'¶;„?fíÔ ‚Wæ²Û"Ö8ãÕWí^ÿõÂÓ"ŠĞ ìãĞğAçÁÅ€µP´q°‘f*çTÔ2¡J}YÓ¢i¨jèàÕ’UVÀ¦¦–(­€I…lTğâŸ\W.ÅÓØĞ®Şa×Wï5s#´ª%¤°e‰?Æ³ò¶H¼=æi3`Éy²o&É¶œN¯ˆ¯eÌf<ùÚ›Jš¯]-‹"2+oBAÁôwf,‘%rSp·ku{É±_Ú7O@ybÇ¹Æ™m
oÉ¶r¨¸1K)ÁÎƒÂÍ=_Œ%Ånm·¶“Çµ2Ê_Nr&¸ˆ„¨(ƒá9ÊĞâó·l[9m5]ÕrC[‘¬p¹UWédô…ÇŠ•+°{ÈÆŒ%%jOêoÂ¼Yu¯¶sÅÖzü§Ÿ¦~¥Ñü¥Çt°ö*,G*gs,Cò½ûçÑ©;‡UµÍH'c;qÖH¢ç’¸EN»-Ò…’À%®–¸¶R]gøJZşÖl”‘íuZÙ¦";Yköe›R_ÙÎ@K,î ¥ ^¦DòP±.-@Ã”=¥ˆ‘GÁ¥õrº/oŠÑ÷ˆŠ¥,À"¬Bòê±.³"$¡maZ¥²h"V6(Òçx_Î+#ÌòÃ­k×¾šM]1‘·g:\	_0¹48_Ê¿[€4Mñµwb)ÁÊo²ÒÈÂ„œŠPQüp˜ŒÄ¾Xä(%é8<‡Šûö—N”!Â^PdUH:-$9g”C…³M8+ÓÃ_–]]¦/:Ê ’RHÚ-LjøÒ¼SxhZ‹âó†tïÂ– Q3¹8b
€ŒöÉŸQhÉ’×¢c‹‹¬×(İÓúÇù£‰¢<	 øŒ“‹/qt‘>»HBéI\|UCf5-fuæğQº/™”Wœ÷ôó¼y) *Ò™+ö™õ-€@åü|ÁÔDj{Iº.Ã‰˜ó³àòöŸ­»8<hâ^1g‚}Ã…•e_ãğË¼*z¢¼…ÅÌÿbÑ-¼…
*3_r:&OÎÎ¥ãFõîyeD9èÄ#]Ún¡ÉY‚0ewŸ‚·u°3Wíic_iRŸ<î•^ÍW3·ÜkÆÈQ ÅPŠ>(!E.
À'µeíDKnıè>*ó¡®”£µ.)k"˜Z3ÿ`Úi,Ã?c(ÅyXvC0b“^£ßo^œõC–Ë¹ëôO¹W·Æí¸Ìò%WåŠìMî’\™gÌ²Oå 7u½Øå 6™ÛYÍV¿Ü¹+¾v¥UóŸŠÑ´	4Wl?ßô¨#û„ÃŒôQù²÷ø
®ñåoñ¥/ñ¥îğEWø–ßàû2ø²÷÷à=ä—Êdº<hÊÆªÛvOkÉoİ=±­¸}WşJ7ã‹|™”òoå•*Šm|æJÁX–¯Õ²Igõ¤ÿõ œºs™<n-Ş¯qùòiw/®^~ñ›—ë_¼d²Ÿ«ÀO¸¾²ß+RW§½à(=ã,rwN×j‘vóÑwQ×i‘qø;åËÏÁ
ìé±ÌÛÈ‡T(³ nùÔæØø$úîÏâ}Ò#sBŠ1%‹ù1ö[¡â)kŠñ{j‘ß?Qø7šÊ>†Ä¿Å—h¡¡Ëûg"OmÑnWámâ;”‹3Z*Ø•=ñ/ò¯mEŸ˜¥dxŸúâ×gğ#ıWÍ9m¶şÖ/ûíóz¿y\oµ~!<æ²Û`F%J›aA‡ÆÅ}É7ñJ•ôÙ¨Í!;ü“pŠ¾İWø]»%lÍ¡¼[ïş’ ÌÙa5©İ`—ACÌe3ã ä†Ôo½{ÖÓ7«Ï·62¸
º|{Œüÿí}[w7²î~eÿ
¸É‰-IŠ”|‰m9›¶hGÉÒ"¥q2VWKlÉ=&Ù<İMÙŠÇçïœ÷™uæ5óÇN] 4Ğ’Rlíœ2+Ùk(
U_Q1·ç¨@ŒY¯¦&¸L–ô™²Øn¿ù|)ınŸèa^¹Í?ÂèÎ`kıIğ´ö©ªúööîÏŸŸüãwprŠ¶ı¤°Éˆ@¶wM”İ5õ»RDL¡©¡úõä‰ªˆJb^´¨4IéâÒè"{ÊL|úRSE£/ÿıóçÛ…6V%ëOnmÖ*3¾Ë3"ƒ@›,˜„XYmÜ¸)/ra
ñ·Ÿ~‡ÚLå–ç¶ë.NÃ!p”-÷èğeı‘ûİ³Û˜’ }¯<íN.‚(œ ßÁ>áÔÄøvâ§»\S
¿ÇVòÇnµ³M$jJ»=¥ 5¿BÂg.%/‰foìë¢ÊX”Îû´YĞ@|ó´)»A‚S,’Ú¿ùi‰!—ˆ
\m¸vkÑ¹ÆÔö‘.j9äÆ2õÒÂÙOGPĞÑVjw”eïßcØŒ­ù:aİ®"/ğ–õù™,ØÄãÚ‰?ûÑš[YTN¥Úš_€eyáªš!_»4_	’%-Wè6Ê(Ù¨	i›WmAh¬‹…Uï“s"É¥h'T8’p®?ü©¸]:Í±d.pÌ³û¶–³¿cØ‹ÔÈO™~ÄÍòUóÉ˜(ÉÃrY2ñ&%F·ÈâIi· ˆÒ'Ÿ<°‹mQ±K'¿¿¸dü÷ÛIN“ôkQ¾ı; üÆW¡<J©7ÿ#ÃI=~çF_:üÇÂø­õÙø­õö
ÿo…ÿ· ÿï"Åÿ[o´Lü¿ûÍô¿4‚|›0 N’Åö»%vè½7şG¨eÍƒHäÁ’NŞ?„3ãÈGÙ%NÃ{ğòA/­ YÍaü9ñ;£šÙƒîM†oÀI vè/†68@×Œ¡:‘CÔá<Ào†şˆŞÅ/Èö¼çôäNÁ2l»tÃ$˜ŞZÈCzæ¤ø¸Ì°uìŠaèÇ†'ö-W|ó´ÍA‚D´4tRYÅÚ:ÖŞ=›ŞĞàHÜ ·	˜(µéŞĞÑ´i${šÒğPY"o{—Ì¢	ìFÒEü,œM†"ŒDKà#úéäÚA #ï±Äxkëöëı×İÛ4³IæÖÚù7äbà%QÁìiC¢§¥9!c-pí ÔŒ§S–B<Äô¶R‘}%£¨ª®_àn…¯zÑy,˜”@Wõ›(‰n·c?!¬å÷x1Y=E£›–°&`yÂùûN÷<”új8@5ÊrùÚšËWl¨‹Ş?èÔ‡…Ò7x‚;æÖµ¢	øÍ7"6STÏ=İÚ­ZÛÑ‡cıTE©¸M&´®´ö	¾6›ÇÍ¦ø¼–Î^zŒ)ğ(JâÅE©p@”J•¥y÷„=–2Ò[¯şK§ş—õú·O~^³AÖ™>aZ‡sÿ£ğFSXƒ³±¤#×ª´ªuåí#˜IÕN
 Áê¯œ\NÃ }*Q¬gã“şÁîÎáawÎß½ÎOXªÊF•N–9°Ç$ë. dÖW8j:S%ıÃ´ô‰È<úTÚv†dEŞÂd¼”_ôÁ‹"ï'©š‰Üœk°O´Ğ)¹ó:eĞ¦–~çn¤%™R#g¤NuïÕÌÂ¢–âdA^†àıŞşTªSÅ¤ôUŒA¤'>ÂÁ¡<{r‰Nè~„{'”J‹R`ä&ı”R8¶tô¤ÖµUk=Ñ¿õ
†•>åı×ıVmC?•=šÊe@ÖrÈRIB¿”5ÅZ/'VÊ9O
™FÈL¢x½~àúh~dÒµN#¡æÑ	*¹#
@f¡ŸdÈ{Ï™<Ğ¾õúŞ8$l'è³%ÓØ`|ÆHp*ƒê¤jCicÓ6ÑŸd5ŠÍIòsÌêlµ!¿I•†z¾rùMwd
 æ'®d+X )Ÿ¡ŞL¶À	4/S.ñ%^LZScó{éüñäZİ/Ê¶˜ U¾¥ÃiAÆgR:*Zé¢®ÆPµ÷ñRó‡$#•Í”0ëÚÕ¦ezøÛFFÛ+M‹ôGNÉBW›kŠÕfEQ•¨H"µ®AÍûÓ/E£×£ÁçÛo&B!‚í•N¦˜–q¥¥÷¿+×YjÑÕ<eZÅG@¬^&Š@8ì.ª…Ş8X#i	­X]	G)ªpª„³0a®†ê”J ¬şGÿt–xPßÔ…äª‡n…Ñc!ÏUèHG~ùĞXÎÑlB¾º°+JØß#4ããI[°ºN gß´Xø/˜ˆåñ9¤Ø*´oÇ	Ø¡N'=¬İ˜ªjõùzú?B– ¥ÚÈÿ*ú¿9ñŸá{.şïúÃ+ıß*şïUãÿ–éûtÄ^+ /O÷$¶Ã‹Îg¤àk8ÕöXáw}øğ¡q\x!ûÂ@öÆIÔ„-ÂköQíWçÚêŞ,	UÙá¤íëZkèE7¤˜ˆİƒ´=wÖ^c“×é,‚=Á¿á$ÍÊ‹ı½ƒ^÷`÷'R¼ÀKe>áCDıÙî¿¥¯/ğ;)0giŠz‹Ò`Á[®Dãõz<|¯@Äëˆ`ç'êoİó¦0bõº¿bÀğ™P™íÔ…1ˆbŸ ­ŸÅÖ–¨ß?ò‡Ñ!T«Îa³­¿Ay	[¢R½.³¯	¯ôéPÃ%á|Q)ÊHj£/Ÿ£~¥æÕká<ªEñŸçÍòÿÖæı‡ë¹ûŸö*şÓŠÿ/âÿs@İŸ *êK|Êì&ìPS†aŠ*ÓÚb°â÷Õ_üI ›DQøƒÈ™Âµãvhëo`ì€ÚyİyÕíöö·v»}i©·>ïå§ÒwÈò‘»ÀA¤TsdcÆöÎ‡Åî22×ÕKå‘­ò£e3”Ù„.Õ@œÈuÂ†“:Õ9bb¿ŸjvÇ9Œ¼éR¢pÄq¯`£ u~<ø%˜¦WúÛ?èĞÄcï<8ÅŒ;àÊşíêø¢ğt€ÖmìlB¸‡‡Ş ¯ÑàŒ».ôSÂµ“†G®r.şËÎJÚ6ŸsÔ8boĞS«½vS–šÂ¯2æq•Õ2úCE­G'uÓ« Á™%„çÉÖL«2¦ã½åft2ƒ¡åE•”oíÌ|c’ê+ÌŒÖ]“ŞğéYØi1#;\ØoŒ+8::·YËúÎ?}ÿ2„	•úÆ›QğúŒYŒn_˜š!ÒU•Z¨öéÏ]Œûışgo(-ÂLÖ>½Şïíuv?OÜô:R¿'ÅD±†O}»×Ò´“l·w;oö6e  ¾tTW2Ó,¤™‹†>‡–v;Û]ê GÀ xG»`,o+ƒ@)ıl`t­Ü4·¤¶ÙÅŒö“&É=8Ø*µ£ÿÈ@Ù  ƒ¢ âlú¦¯÷t=8ì†vNûh.ù’%#ªäàŒÊ2%¯Gİ.8ïS#Z›X¥"¹LN&5X'ˆ÷S–\—ljV-­|&ª¶ÈĞBcqíâ¢à¨×xcÃĞuYX`seAÙU Ûó£İmèQ¯³×=„Á@k¥¡hıŒ;b>ßó©»­[[·%³§¯K¹Æ3LVŞ?ïN‡¤ÜõÄ„ ¹ÉfXì=Vø15]çx2ŒÛ=›ˆ£LLèÆº
˜áÃé2Miy"ùa2ö/™™n G}˜+¥Ç+9=®@¨Y”Êjó©>—å8¦^±³*yG¡'”H|ÔØ‚¬’^”¸*jRÃ™€&y£àôrpZ–2aQ»‹Î²¼¿Œ´KW¤|Ú
»ò¦»gÖ®\à_¼Z)8XÚ;Ç"†~Û?	`ˆ¿½'…]´4Ö7Åîaÿà´{ĞvÑz„Î²VL™4àƒÚ»A*Ø2=]ÍŞs;IaD0Ø¯º¯z;‡ûŸßxÑ6ÜÇ¢ëE£ Ú­P‘IV—¬æÎÛ.QBÖ`¹Ãø\kxKïn&òU¾"4}E‡ ôƒ” e0Âôú%cì¾€]j®­iÓRışHtõrcN‹@¸i¶Ç‘È<ŞäòÃ;Öê¨„ ¸kpµ–‰¸A÷,Å¿ıMızXhµDâVÉ¸
 Ò¼ˆÙ©XYcÛ)É$÷eœp®"‰)€…¨n‘İQmSÔæLú®EŸƒ·hOÎÆ6§j¦pĞ“³ÙˆNj³	>˜¸¨”'=Œe@#íHë¡Z9WÅë%.)9ıÕÌÅ•4Ç"f
‰¬ll·'É›«§ršZ4Ì|î'Ìc™eqğ5²VàßÃ£¾\i*Î!£“?°ö1–ûÔVØ‘BbxÉ0S‘döW¡b?U Q©¨§z“-êiÖÄÜngQŒKR)Yöhoáäöö$•Î°¥J“ìÒh,şx©äz(}ÏHÃÂmqÆJËW8·‰4æÔ‘l6üU+}õzğêhg€)Ô›óæ)g©"µgÀ\…ÕğÁƒS_æ&°‘ÁÈU‡¼\·Ú›Ì!=ØA”Ìà~ÕNè>°‚ùú$»òä³7´
Ï# ØÑÁ÷Ôd³û¢š •šn†¥Ğ¬zLíš³D0%¤u¥+$Úã6$ifGövw^ì:/g¡n£›]J<ï¹ ÃDVRÑFm\ª.#7O¥c#,:\:hûz¸³×¼éìŠØ?'ÃX:cÛçÖt*ÂÈî*NşxÊb«9-å‚KË]Š<É™Jdæü¢RÇôÊ×\o~O­¦=¸~_Å×âb×á\´½§œ]Ëk«ùø5ÿ‡¦Ÿyxé®	Ç¤) µfEÈÍïîš•H‹ô;“8;õ=ñ-c6äÊzöMÛ0–ÁrÉûwfÿa*Ç¿xóı¿6<Ø¼Ÿ¹ÿÛ¸ßŞXİÿ­îÿ®jÿ¡¯ÿZE×®u´Ü½ß‹BËY¶)¹¼©›¿)ª¿ğ8;EptŸ.ïdè Ù‘+ƒ°uœ±`è“zx«8äk«sÃktZ–İİ]Ç±Ôô¹Zlw²ˆ0R]€­µ>jÿ#øÚ¢² W"Û—(JANr>)ÉLÅ¹HvÖ%äíŸ

’Ñº²İLË±u#FëÍ$ÜvÓ^¼’'$¸»€jH4D‘aWe‹p n•¥)–V•EOµê£öçR”’Ç”+¤ ^—Q=>Æ´Ø[(mà—v.¨øœ(µ–¢—ˆ%r(?wªôvê8ğ]Şq íaHBÆ_OS¼(i²Ë‘zï¢Ó]º¶¯JùÇ>»ÒW{Àì)®{nV&UO”î¾O”’Aqëé»©«1í ½hìıâO<!c¢şëÿüëÿÂ¤Ã“M¹Ñça”âTN½Ó0ñ‹¬ÑÓûÔ‚Æd
6œ¾?õ‘¨µØì+uù¢4ÒİKŒÂP¦ÛŒğ¦IFC‡}GhÇú%ÉÇ¥µh¤c	
&¨ë-ñSé“ß«;ZÓ¦ğ4¢aÀNê·r¨X—ª0¾øfOA¥·^ñTÔ¥¶ÓŠö$¥Ä8°/èåàEŸ;|†ìïÂD µšôÆ½ÑXo¬ßN	$„šTİîöàè ºÈ^¶tÈ†Ú<â}ŞP•´´	*o²µFÜq’ú¢(+Ç'Ğe¬'~Ë6‹%wvP™Â
CÜâêºDz(‘ˆ²µ!qÕ,âYî¾ĞŒ=–MYzµ(9ÿD)º‘˜ø	úh¦£ ¹¼%£K‘£[<ÆÚõ:ãË0â
ë»È¥iğ^:Ÿ¼×l^xÉ3áó¸	äl0I1š®¢îß¡×Ôğ.-kpWö§:›¼`1”$]àè›/G½Ãp“GıÜ•ı
gt56%qFÍ§ƒ¼’©×§³èÜ*é·õ»À'Ä)[­»ÄQä…gì'êu	rò8óf£ÄÁGĞÔG^¼ÍO¨¥¨+`ïĞ’YĞ®.ôQı¯‘¿FÆ$³É0¨ÊbQŞ”8’,‡«ªX§Oñ¥±•¢ÆÂ¼%ùğ5I¥r×…ê\é!­÷é:h¬mQ›¯Pë¨$ÀäÇ“~N§t3Ãü©’¡bvÒJ—hæêü¹Ãfkn-M¦k—ÈkoDxxÛ“µqÂ“¤¦K1ìŸ»´á_-­_ªj[úÓØ‘?¶}ô#Ã3ß†{M?YîntŞÔQ÷~<qÒdh‘I*gV%Ã³õ`–çf¯g3Œ×àeªëÈñ›¹•(pö×Ö£ğC}6–A	^¨’‰TS&ÿ»~éh~d} cœœß­äØ'=Û™†3¨;²Ú4
ÏÙ˜n>µ¤lğË:ë¦ŒùEjÈ¬Œ^× WëƒX\0	N‰Cy±…±c_ïfÜ/7,§BŒÀ¾¦6&’äÚ…-Ø”˜µ’]6õ›4%º¹g³õv·tLÈöãÚ†­*µ‹=Ø¥1'ÓQN­d4±ÑšBÙœ¾Ø3m†ØüÌÕXÑO4V´!¬£éç«î¡+¬´¸$’ŠKVIüà‰ÎÉöIt‡g—Àù»ö‚ø“ÈÓíx2nƒğÆhH{)SX•IËÒ½×f}Ôªz}È‡óÂ¨ná/ÁïèÁ xÔz+*$¶\9EÛ’¤ó¹ë‹éH¤ªŸ‡áùÈ—Pêå í(‚S_ÊÉT{,‚æ‹YôÚ‹ŞûÉ`¥Op—'ñ¦ï„-DFùŞ•ÜúÊ%x'3Ä´lœëóÇ¹>wœww^t_÷ÉL;]60¥˜´ïO´9“¬|‚wÍX³£­4¬ı:Î¿¯–ØÄı»0«ğ ÂƒÌ®ÖîW\»ó±fÖÔáê•Ÿ˜
FTWidDŞ»‹€u¬+G»Ö§¢Dw\RDQBŒN·èÿ^ƒå4H ç…˜ªöÛëîv;ın³AÄ#OğÌz–tÅ”±%å|!ùÉ¢vé%¥h!öjAKÒÙİM#+¡ªVtfñ]İ,ı\»Dwç–ú%¨™	fó¡ÈŒõÎçö,Hø7ü:3Û¯èÊÀãEc4@£á¬\?
Èqx$¤Õè0ô65=?èz“°^©%ŠW'Æ2•.UcÉ	ŠŒ›Á ß{1Ø}ıCñœ¢JZ‚3/€ÃÇÈ‹e‰.î‰ª‘“‚æ„¹ôìJÔì™SûÂé“/òKd`k0L.Ş@NÖ¡˜ÄÚ?ÏQ‚Áyè8´uÇ=…Š(GLSvÔ]Kõqxüç9“g6ò?0ªC
›n)Â³õš±ªŠË0lôÌMgl„ÈşXMí“~Ï®…£°ü`åüUˆ1—ª•*À?|øPÔ{%3/•Q¦pf-Ê¤ô…+Ÿ¸×kÔUZ%5Z_‚…æC\“*j’ÃìL’K@hO?F„WŠ&
¼íYo‰*â Õöı< ÁCR´&º7%ÿúG„èõ¢LçRj¢_ 0=1…@ÀlwıThÏI–ÜKUõF2Ö	Hğˆº?kxS&6j¬›¨ªn9PéE7ù%HˆI½Õh­7î×áU#ñ¢ÆÇ_ˆÆ%-ùúz¬¡[…ÄjÓ-ˆ/(ÌégšCm½Íé4_™’å+ŠüNĞ‡¥óÔW<—h*£‘1>[NĞäË½[K†f5âGf5Ä¬Ü+…S0Š>¡®~ˆre¥6õ	 &‡Œ2eäZ”t­d3ÎöËàÌÊçñP^½™Õix/X }äÀk©%HA·º£wù½ LVp>ñFmq¾˜ÀÑlš¬™Öpa.	Œ5[¥hşo”ÎÿÙä—`*²¾ÓÚAQOÿL‚Ì
(Ì^%pw›fÿ"Kz%
Ô27ô™kÕtªZnåùA7_k+7ëM
fHD! JjJm:‹Ó8™@á”ì?ãá{QÆ×xK+.!İÀ2­¹_ÜjY,£×ÆÒ}sccãá·Ğ!]nìóSIsåµx”H“¶_]Ï»Qû~£İ¸ï%²ö”á¨Ág}Ä"jæ8Á%ûŞdyÜlò°/*&Û–;'C:ö8:æ`HbÏ%1oBL§'%“©Şºúlš»/–g)Ïs­ÍÔØMM“eç§H'hÍ*9'sÙÄdiº§Êºyk¹ŒüÜ<MË×Û?,Ox#ñÿÉ.d	‘*t	uÑßyµóú·|ÍŠÒ§'ğ]\JÏñE®c<LqaCrâşRM7-=–éG¾¬tJı™Š%¯¼7 ˆµp¤t)Ş€S¹ôcñ7Ñh aµO%
È9‡KèÕÕKúšw›£ÓruÏ#çìqÎ2&£Ğ#7ÕcWv«¤¸ £ÍH+Ï2ÀãRR•—I¸õl€H›Aì	`0aØ ïİËZ°‡_£æbÂğ·¹Zûæ÷ø÷ØWe‚ôşh˜©hM›-Åïä€¨ñ„Òå]§¸øÚ¥8[zc¿7.,šó®crùî©ÉRR³ğjFˆ²\J Ê^ÅÌ«"wÅ=7qögÉ¹+9Ô*¿ŞÉ<.÷Ù6çğbæ®Ym
\ì®wâŸ…ä¸@X°8\^r…îâÊ
yivÚ.DÎæš_É£èšW±Pm)_©rÄwüV‰Õ&¼]’^'dµ+Ñ¸*¦ôåÎË`HÃªÍ—LAˆ"ò°	İ^×gî 5›XØ¹ù)ø~^îsÙÑï¦‰óÚx=¦i±MÅ8õß³ ¢ Ö…uPàïã¥/;;»’jÖé:…—Òæ­­ëè{u¿©¬·µbÅDtFÆÒÁÎí>ƒ£ :Š²{õ‡Øe.k2º”ğ†dZŠybOEùRQ3.JfERsrÍé,Â€íD“¡B?+ésf)q!ÒVË’q$!•w6¹ÛU²[İï±#0&†ŠğqúUÔ{¥\˜¯Dçh“bˆĞNC‚k `tJê×Æ4
)î	î ‹OKkÜ}ÎWDY‡óŞ2;,“®(wk0ñıá€¡Ÿ¶ÖA&¥VCŸĞ "ŒPä.#œå Pëø¯(ô2áÇ±G7F™&ĞE¹z4!¨aÒŠ,«),”²…ğÿÁé;4\]U3.\À2eeşHé8!±,Â‹ÆºÓLæEÒèQV¢â0aÅ²„"6–·H†îpÖÅwj+H.sŸƒcf¬ÍÕTËšW–3!.hDyƒ5æ*[XP½F×1hõ]ª—¡ÑyÊ±C™ÚHÒ‰§zOÉ$LN(Uo5	N¸½®\aãı?èRÒî^9¦a‰±‹uÌ°ƒ^Àùn=ò’ÂxÔç0«B8­áotÊ‚xxÿ*Jª§ä˜BcŒâÒj¥?iÏ"„ĞÄWë ö“úÙoÌ_©äÍ>¦¾	ÓùB&µ5øé°şëùÂŸ‰føØK`a¯ÍŞŞ³(7ñaJ‚(ëŞû–9¼Éä”¯í|Ï?Ş9òé?Ø¬Ö3®€iW—Ì-ªĞœ´1,Óª0DWkËf¦-WlÌ¦:UêÚ±7BMgÄ2£ÚyÙÊ0Ö,òšya¯$cå¨Jì#¹–Ôë4 bÑŞ”3õ)ö×D;’|íQ«åƒe?+Òºó2¾øÌ0£rå‘P¡ù
Óëf\Ü&4íâ¤@XœÎ”Äî¡VpÆø¨„¢L5§b»Wé4Ùÿ×@SÈ¿eìççÀi50½è(c>;¶»/;G»‡È!T]Ë‚˜ÑÆ'!œÅK¼§ÒØÇ¥³ı<	†şƒé	aDî†çóqÄ*dj²X³ª˜Úó‡Çô¦¶fî¼Â­\’pú`ÂRTë
b¥’O¹§cĞÓ…ÜÂuJ'ôòqà39eK’{°¹Vù=Hr‘
Û™¶b~38÷M‚YQ©„ïsƒòrÔ—•,\µÜB‹0s{)îYÉÖÂ–WáØ¥›Ô—`Á%Ûì<®\]È–e¡”ŞRRg®0Sˆ¸±Îj3S£f¡4»#7yÛ6½D,Ø@E¾Ö>ò5ökCp,ˆ¸ë.Wåâ(”C6›¥1wü\j„6Yê¡èäAà®l Ë€{H8€, Åºkª­”À”áa¬›Êê9˜¬¨¹ZS-Àå,¸ìV1äìâÎ³©¥{p€®zÀ£½Xãg«4P÷œ‘¨ƒ’¸„¥dÃÔMé‚×ç‘PTÃ8±€×°Ñ#äÏğßh¨-ˆÊaI*y”$ÛŒçúµ–VÊËÍ€ûÃîîY˜<'»óåö¶¼!$ä)4pŠd€jFW¤ÚUè9”áE‡^	„#Ş	(4U3Bñ>TÀ]³ÆñPT;]Àm;ClåÂ¥&áÔRÎÙ2{“S²îz¹½`áW:óÂ8Q(¹¹­¡hcøüõñÿÌ<7Œÿ×zØjoæğÿ6VñWø×Çÿ›şKÇšºVì/Æ´b(\ ;„…Œ#oò*yÂèĞÆÜo`»‡³vûØÛz²ÑßV/:{^wwŸ_­Ã»ô]ÿè9Èßw¶ñõ¦~,deiiruÁ¨«)x7°Ê¤d›VÂÎ_vu›és¾ª”Í„ÇNzèi&ã)KE!LŸ(¢•;0ÑT+ j}é¡×œ’|©ŒŠlLgA'·2˜¾òÊvl-BÃ¡…µ²¦¬9ö$÷/ ~–‡şw*Š»kŞ¤êÄ¸‰#ì[Qíuvş"¶÷aìït_vyÂ9v8·‚¬)«˜~]d\ñ•f§À·_¶;‡ÁöN¯¿å"š]3~çEşcúJAGåƒÜ¤ñÒu
…[— ÿ2/eÄ¼C7€“ãä?BÙÄ^©uáqqx{¸XÎAøÁ†âäRl{“À‰ı°° òĞò:k£ˆ°İ}¾Óy=xÙÛ‡a{½½åOÉQ½–nÂ¨SRQµŒ‹!û©TìO ¨@F6²¨`SK•¿÷»?š5ÄøZwP(#@ÊÌö÷I8…Éıqx+Q­¿·»ı÷ÖœÎÁá`ÿàĞ(Ğ?qÉNpâ'Ó™×˜“ÆI”&5`Q6ZíGN¸ŠYÜcm!¥°†vÑ”1p t²ëÕÏñĞeKëæ+”º8,Yvê+€ñœB'‚V£e¾#ÿ¹­ï›E·ñƒ2œ‰5g.øÂÜ×
÷ƒâ¬É•Ò³3%åy¼›ÿ:ú 0x%şŒè÷ÊìbsÀ‡kœ¨É³İ†	c›9oÙş±v:½l>4.z&¢š£ÁQ¥Ës>ÀÈd\Ö›ıŞıƒÎ«D£•ÛpŠ§s+GBëÅª.÷4\¨ñÔ;õ‚àlª<#’[¦/{İ×GƒÃî•¾˜K7HH±QTC²×1|Â,“#_}³±‰T¦ÒóN>VîVÎœ‡$§ÓyÍ‡9LThçş->˜¦kâ–;?­ìrØâÁl0tJés–6XÙ¨Ê„ºÅQp2cª›”¤ÊigÜÇ`*L†; «>‘+ÚÎğ[®‚!nóEoÆË>åõFşunÑÆ“ÆYäûS/†	D=G*”`3ñÎcC)Ë¥|v,peœ;k_»BòØ°¼™Jñ‹ózb5uZƒGtn‘d”µ‚ŒšhX@«ñ¨A%İÙzqØ¼¨%½ı~Ğéí©ç“¼ÍAÉ–•¨ôECä½88’–Ñ[hÛ²ß×¿¤ mÔuÔs`ß¿tñ8€^˜ÛÑøâ¡ç
%ôº/w~ÜB9î6ÊŒ¦aúÂÆ-İ6†³Xª}%í)ˆ HT®sŞ:pØ-´?ë2Úboxµ%N@Æ?ÖœMå#~2À¢£é{B€
Æ^tYg]Á(‹vD!”sä¦-›!»_ªÉògšŠ\«Á_³½Ò.Í%d;ıú]µñìt¤§€ñ}ğå‰	< Úë¾êş(şÜéí Ëè;Î›ŞÀÚG]|báşe.×?Øİ9<ìnÃ‚éu@Âª}"¾×<n6Åç5NØ?LÓanpò±ÕªıTNÎ“÷À¡ô/§ÁÇ“Ù™ñğÔ¢°­~Á9[éÛIœ¨ï^òŞxsşî´®jÂ½á|4K6ÒoôÜuR¨Ê-wìOft/‹¸ñìDEÚ£ø°<Ä "~%œ»Ñ/ùf“È‹´OK¿ŞğÄÅ¾â|¢´Dï^sŠ ›‰§T…ª˜"9ãõ‰O…<¤ØØÄM™>VŠ7A'8“pRÇÎ»²°:Ø}¡c¿}û³>¢æ/£Š¯,ôù©">ó²øöFÇşÙj£A1ßAß9:V6¾œ$ŞÇÇ|òn4MÍ1œ‘“ì³ô¼ÿÖ#„‘øçÔŞô@ÛİÏoÃiæWf>Š¡8ıö±:ù§	ìzÓ*æ~TüXR? Ñô¯wNAÊüõŸª’|—¸ÕfŒÇÒ
sUôfmã—5RëñëßWg„Z,«ï0Å‰¾Ñ£jÓ0Êw Õ¨è=éÔêô.¼`„êQŒ3+wmqk(`ß|BCkdDhè¸öG F-Y>,«¥‡I,‰OYÒ¢¼
5it|Ïyİ€NètLÏÇw·WÑ‚YØGÈ}L¥å^bñ™5ÀˆŠû¼Tç´`v[DnáëNÈ»B…MWã÷ûıC#5M_¿>Ú{Şíe×jì§#Vf®%ÖÄ-®fëÖƒFKU†š%Ù±	FìR}y&X‡#ºşë?ÅóKíƒÓÛŠ÷Á#¸p|Ñz·é¨¼ñ=È»„ Úa&ìH¢Í‰rŞRÔşõïbçSa¸áZT^šÙi¢+5—;]úª‘8áä}¶Ëb*¬ëİjwà¨=r3uS'Ÿ¿Ówx%çë±T*É­Ö÷N8t~ÛœF>îÎİŸ*µğÌ]¢‘ÊÌ¤t€>ñ}šÙë%µ,ûz]ä£ŠİÍE]4¦L·oğÌ¤Àxê­á¿k…¤Ñí/µJå‡Ôz3¯º¶àjŞı$ò&§ïPì>‚À½ë\aÅšm~W¢ç—İ»/ÊßV©[…az¤Lºæ óÕ-×h{ºÂr>Ñ[íGÙ—yÿfÔÉ/ÛĞµ;÷nİn?Äd·oà2²èó_«Ïÿ7ŸFsÆÍ¯ZZy<¼¿Äşƒ>ûVëşÆ‰û+û›§ãáWÿrûŸõÍ‡3ãßn?XÅÿ¼‘Ïİ»ßLNâéó_SÀ¾ÓZã‡jDgv.ZD>Oş_ëÚJ¹øÜ_&£ÈÔ÷®ãÜ½ûd$øötúÌ‘§˜§ réòcŸ„ú–„™Ãª.£I…ÀŸgXIçõşA§¿¸"ûRú+û4N¢prşŒ5#O›òçÏéÙàM?}5·¶kçiN}ê4šc¼–'dóeöŸ‹zcê.JJ0mÅ%àÑ5ß­Ìpmwû/z;D{ÄäÇš‚x–Ò0Ã ¤3èÜ½QğQ‡÷p’`œ¤1Wgy÷„PÖ·|ì#­ƒÖ„`òTBÕÖ5Ê¶:¡í‘RY¼a¨]ÕKÌ¸ò‘ƒƒ+B¤!C%9I–¯!;øfšZåb*Ÿæ”™)Ë¨WJ´æE^ãAxÃ˜¦´€‚©©>ÅÊ³Ò’Šæ0§ùSNK–†^—j2š2JQfjÊF¡)k%3Ÿ-=²Y>ğVÎºŸÿö··²Ÿ­®Å>Ç41:fô*é+Öé	ğl¢_gš¢4<™ÇRÃ3—‘èzêËèzt¡’ˆ"åÏ^mµÓï(æ5®º(3¦$ —IÁ‘ó&—‚{pLÃ³,ùï°ƒ¥òœ=g“Ãú©xòk%S®Ï4*£ì"J}-ÉÒÌÏ]ÚYlÉl…Är’î°­á?òfxÆRz ¥½Gt¤5‚ò,¼ú!Hèä¥€Úè±T»E"FOıpÂ5"[=:ü~¿•Êšî	guşÓòÿ×;^ãü÷°ı`uş»áñ7WúMÿÆúF+3ş›ğluş»‘ñ?vQĞÁ³™@ğ+ëTÓ8üŞ>Q=®qt…´È.	9ãÌaÏuıïÜ{:s0Ã,êæØ­9Y,s´:>{Î¢ÌñYïgú)Åü9„“;<å¦‘"¦Édrû+ÍªEtİªãú1ïù',[ÏSÕzlH?Ösºæ£® íŒ3‘ó%Ï?öñËø‡l¨¤¯“¡—¾äê4óKê;R
QÑÉ³GœB:ƒ4PYpú0òJâ
ª*sÆ0’YC†iËNFÏc5 kÎÁaŞíºufX#‚Y{ù
ÿªIJ¤Æö¨®‘h¤ /Ÿ£|MO•D]SBhÁb½¶øÎÓš—œÅ¡ò¶áËßÔz¨{<.\ëJ˜¶ÚR˜Òn­’–±c(;W‹Yüe¡xLÌ«äa'+ßÒƒA8hı÷»0{Áë×œ•dü%ÿ‡0iĞ‘Ïsq=˜œ…_ğ:`ş¿½ş0+ÿİool®ä¿ñÿû	±zÑóÿ×Ì|ä‚±¨:¤©<=‰¡¡Rœñ¥ÓŒfŒÛÖØ÷™÷œ…K±•#(-¥=~Ú„b °p$’Ë©¿åî¸ğ³òt<#¬Y²›–{ƒ¸CÛºÜéb±‰bŒKLğ©'ŞEşY¡[s9Åäè¨ßLy«ÂÕğ£æÉ(<³”5{İÎö^¦½ûL©9ø‘Ör<mzÏ`“@#Ÿ3T>‚VkD…ÆÓ&ôDv]”APbDaÓC+¬¨“uFM(C%‘›ŸhŠm6ù|îÅĞŞ#¶bT!LÏ©?ùÓöDÇ´¼Û—­†AV^g°FhÙÁJËè5«È—‘ï…†è'Tâ’e£µ®*ñ×Š_ÿn{„°çB¶EÔÈGí$‡$€úŞwğıÈ;…š ‘•]î›ñ%â1™;:mˆD÷ ŞÄ"¸4—‚ xŒ¹w’Û±¥Ò‹Ã"ÅS9p©zKº‡k|lª?AnT/¼¡75ôæFÛÔAG9•ëAo†#\òOŸs¢%NùÓ\5-½j^j£™tBùä§
j4$Çö (0QôL½eÎT£
Zšš[(õkb%ü{íÿ
Õs‚ïK[,Øÿ76Öïçô?íşÇíÿÖ–Şãy ˆ9|Aª!{¢a4–J€ŒÑ;ñ?ˆ3ßKfÀ<‰ÅÌÎ½5ç‚9D]ìŸ&á‰İ#3­1Y´¬òu÷Mß¸Ø¨<‡ÚÁÀLÃÙ)nÕ¦÷oñX<õÇÏÌ“Ö ÎU³i#~÷´	oLN×A(s'5]èÏ0¾Ñp;òôØâŒ3:^ó‰Û8Ê‘úÑRøşĞlr¦Ù$u¾ïµ0²’?…àµheTx¹ócw»„ò5	!˜µU²Õufç(µ¾½µJi¬›¤PÊrU´hj)PTÌÑ~T”ˆà’dÔN¶c4Sı„ğ`“ğ	#Bù7’!c{OİÚ¦yútŞ5NÍ”Gº1‚w­5‘š/1tPN=–Í¹Â¸Ôd\GiÒ­)ÄÄê½˜*ï<”q€R§°UƒP¥w~D[Æˆ^{@¡˜;ÔŠ5³}<"†Pç¤BZ/ï2qæd x¬ºBQïôö.6åx_-ÔVÏœxmKÀ&ß‹İ±‡€®ç~œ]êH÷ŒıÒ_NÒv¦î#=í>bÍè«O	¤6ÑÙè¢q¦Ô=Š±†v$5îÔ<–ı¹U4Öa„ö¼KÑZ7fÂÒSáˆC±PChÍ:”'¿l
`uò¬ÑzĞX—c/öà7­GYâvf		¾ÁÄ±ØkĞ+ø(&š¡Ëè
Y¾1¦S6ŠÆyN»ã~ƒü÷Õ®ı–½ÿÛÜØÌÊí­ÖJş»ùï?ÿ-…“³ığot‰&Á IŠt5|¢T+èéŞ\
7uô*uÆíô^¡3Ó]×òÎİ{ÕSî»[¹&s›³É_ì÷LïUú}fÒº—¬78ÜtÜ9L¿@_£çş÷[.Î+]¦J‡9¦{
–™¡;sä;) ôÁ›íf-Ûí¹¸ù˜ê'@×Âµõ²Ÿ¬ß°øäİÏ‘áÊI\³24Ü‰	ûTdÒĞ Œ‚‡“w>ƒÓx$lÄ9úã)ŠÆğ^¤‘üæ@åÔ/è¥I0Bm•ÜÑ{±FØÑ4íé°4æ#ŒC	àÌ´÷á9~Ep<?9mGálªbÃP6'†J³ĞˆË‚eæ§ÆÏe˜ù‘wSµp$<H0ˆüÙ /ö€ø-—c¼&Ã­Z[‡GÃµáª¶¸5•Ä-nQqƒt5­ô­¹Ú'üÓlêb›ŸE•CÛ£8ÄÆX„0Â°± ¾×S×š•,İé_k"÷•‚øØÏa9½ØÛ6 º9Æ_†5ı]Ô?ºº6¼£¶Ö4Š†ë¼_s I'azY„Q[°(kwõ¢2×|í»ÒZ
Ë?	×¿ß	Õ9}Ñ„?¹Û;ıƒİÎO[5ùEüÈ×š;‡ğ,ı.®ß>‰6^³8[–¼C±@d	.£DÊ+’ÂoÔV1›Ÿ4&Íö{L=•³” "qJ–,R‚K–3AMƒt™dkP“»-áØÕ°ÒCÙXP-%”jjÖNŒë¼†Ifût*éJ”Ö•Ú~g´ÎU‹ÙNaÓÛ¥Ÿiš”Ï8dWAÙ©˜,:@Í‡îĞPÔŒ+1üß eÈà+HşX*ÿ·Ú9üçMH¿’ÿÿ-åÿjU~¿ÓL'à/píı½ÎárìŸ«Ózİm¼Ç²¸$ägbì]
¾!©}–°1üˆ.ï‰ø¦?|Õ:‡ç…o’1ß‰/Faœ4r°Ğù~Šú‘†T´5ËÑlâTÍ,r‡õ:çú£`$dƒPeŠbt¦mŒ¤f“ÑPáÄ…Å°;úg…ºÓVÙAØ¼™C…“L©í½š÷z$Wá§a<E¾Q%8et82)ìêõzC×fÃ÷@{oJç¬º“Å!Æ¾âÊ7ÉÿU lR¦ûÃFò1ù
üÎıßz»õÿİ@uÑŠÿßÀç{4hÍÛö<v*-2Ëàú9Ğ-kl§r
¹è	¶êšÅÁ(îù28¢K«ä…©WsõY}VŸÕgõY}VŸÕgõY}VŸÕgõY}VŸÕgõY}VŸÕgõY}~ÃçÿË-R( h 