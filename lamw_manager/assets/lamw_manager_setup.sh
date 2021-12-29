#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2434408727"
MD5="4b9be8dd63f21505c772efd35d8f6979"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25672"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Wed Dec 29 01:20:59 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿd] ¼}•À1Dd]‡Á›PætİDõ#á‡Mæ€şçˆ…€ò–mjÎ÷/¤"N2œ½^—Z:¡Šy¶4˜¼ÄtpÄæ.¨MÂeZ3·ñ&b1Q{”dÖĞÑŒşÍùà®=]Ÿ’xËÛÙbXb^ 5/ÏNÿuUeôŒ­+h	ëô: FQ€zvWx³ÿ¦¤çr‰JŒN•ƒÁÉO¬~ÉÁOTûEQÅú&ßĞâ¿SºB‚†j©ä£1I®}[½]ïËx‹ia­ÿ\`•!p·ûÇ =¨‚¥;Éy˜šİòî¾%pšI%ikmöpZE@’Ü0Aƒ–Oüd¢‹1Ö<Vß™Å¿ª{7ÖÇİÉŸ#•º-x†…‹Â™ÚG½ß^P€oû@Ja¼í“4ytı‰ä%H2R7¸Ÿ’y¥AÆ¥Í8#hM]ó^ÅÏK(k—u¼pÏÒj)—Æ
ï3>“`¼ÎiìJœ´4N9^@¥–Á!W4Wàç,‰`œä&x­/•P]ÑÓŠÂ-aùìóàğv§d
{"ØúH`Î×-®m%³W„˜iÖÖÓğÌøÁ6òË|È-êI¦?È6Q2C8¬“û6JÇ .IªÈiL“ŞsNÑù£°ÔwäõoÏsHj<k…ÅØ úü?êqÇÒ_Ï_¼JKÈ!4p”€egÌìİÕùäyÄ+êö Ó@>´‚“ë6ïĞcı…ÿß¨	`¤ÕĞXùhV"º•	4G{Å1õBÅ
Õ¸ëLâÑ™êÍW…Àãâ±¢Á€õŸê\†av	ZÅaue_a¸>)m÷dÚ eğ8;7ü'„x?ì¤÷Êæ¥'ªÀqSãÉy„Ñ`@0íƒ•´jy|ÅÌm=NgBPo^è8"wÆ^Ôcª˜ÊÆÒéF o%Wƒ˜îÕú_Ÿ|ç„¤y^ú4¼š(€~ãCAzn*v4½lf&BÇNàÈ«RcîvêÖMBhIqÒ—Öì]gNÌTò­³cä\±mLNàTÑ6ühãÕghMå?-|††ÖÀ³§:Ş	ÏK|XöœK½1˜sT^eás‰·• uFó^¶„º²shusTB~EÆ‰yt€<Ô<’öCeákù[A¾ƒã"ŞRóxáò;_Â\w…å}Y1Èö©©‹.Şák˜Ò7¡ñÄ˜ÅØ™"dÁËã
úËğ°/Y”Ä9.ˆúU&ex¸`|ŞG5åJÄ
ŠçØLtæ3À/.4û‰ÉĞ§ìïe¥´* .pİ/À‹&æ¦"<Ş¨Œ óªÌñ^Ä–—)¬Ê¡,ä‰ótfS&«ÚU]*ï6‡–^ò=»õÉõœâAÜ,“ÑÑT¼×·9PµÓRR»æiÑØç#òşmòvpRÏ»_İY ²vÉL*·ù¶ u×u0Ó×©G\rÖøVè |x„Ä¥*[0?în©İÚíÿ‰GÙ’Às¿¹1-	ñğ%ë´oäS:©2­“#ŒşŠô ã¯ú¹û“¢á!üêŠjØ4Õ@[„¹€sÊ"ëC=o«i.SATÂÅõcİ¾§„<qãäî‡#…œe/ä n–7aÄ ı€Hèï èÖóñ1=é0=xu«”Æ1BxN4-|}x1u£n!·é°L›AÊÑOÌ^§ÍĞõ°¸É?ùÌ©²…‚¶Ü®ßŒx{fö
ß¹B(†òèñğÄÆ}BUªC„Şnò¦£ºÛŞL~*S]£4“7dN‚_Qğ›_§Âãi5
n±šî/İşg!HÁ+“ŠZXVÈ`Íqíwø&?j—î\öÕÙw „N_âJâÈæìéÑ[%Â,qÿûæµ‡]mRRwˆõÄ°I‘rf÷^óÙ«NzÕü§hVøéõ/u-}¾±:
}ª•?W‡ËfhŸş—g›#©.lo•i(aà“Ú¾àxôàQ÷2¹$&£uF¨­ğ¼”Ö¡#}KÅM¶Éíˆ†2mOò›†hæıÉ¨U"Y·[ˆºµšu©?;Ÿ‘—ïğŠs¾S‹=eğs­‰£,6•ó†•EÂÊêSy9yDF(õ8£FÜÅı²L,tpšg¬­˜&IKI´'‰!J‰ih jê=¥gUmYBg|F3§ßL„²ÄÑW*IcPUıÔÿ¨‰h whÑ2§‰ €(µ¤<âVëİÒ×ÖÑ9}Sú†(°<ÒpcSøTbÓ}§Ù€äé5ëd\“Ã{ÅØ{vÈßgÍÊ}©&oìÒªäŠ>V¦Ê”ĞÎ˜Pô¥®x°ÎåÅí†y*HˆÃ° Ô'Óv¤<>Œ_Ïõ®}«p™§ÉInğëÔ“,Óå»s÷Z²‚–¼²)ÁŒdÉÈİ¨o9§M—ôlã}"ì	C@à‚ÉŞ¬_ñP©»À_Ç%Ìh~8t"¢M*_&XŠÇ9"¤áKàú
ş§n…`á2Ò¾·iÙ"[p|n}a¤í$×†åõTù_Ûy¥Š™×”adš[íÿÓÏÑ¤ä/˜n>ÏQ…e0¾ç³×»#:ıo
Cy@Î
cÈQR¡Ï£ú±EJºˆaPõÆ¾Û¹‘F	ü[‚3ÍæX) B—…e¾ÛOØ[:xdÔ£3`î²÷÷ÅyœÕåk8Ij—q`ÔcÚL(Œ:
5ì;W7 —p™}‡¬Õ 
«xlG(ÑeHí5L[¿ËÊO%ı+X×Ÿ×’X™SèMııloù– 0›e¤¡ê®4¢e)™ DÑP°g·Ÿ5áz
â+ş^İóÙ'.ú¶-t5ZSÍÑ/\ˆ«ËA|ÂÖ3âVd`¹­˜z%ø0jßb†ÚÜÇQéEĞX G2N“•–A—Ã–İ3HÁ\¿Ÿšş0	V3•ª	ãOè”PöFöôéd>¯Æ0»3dZ78İä‡ç]¢¢=±ËÛä’³…˜„&	Hlåë¾”âÚG£®Æ3ñ‚?dñ‡–"¡ÊÜÑƒÇé$ğ+é'ıS”[• ?’)ò
‘ØªX£CôètæIqª8İÑëñè¥3şÜíUñtyhŒ€Æ—Ë¬^íÉŞ²IRHZÃçl¯û<CÄˆ²°šGGÆ´Î3ßûµÚAå›ÅE,R¬(ÃZæ¦)ÎÑ†¤œŞ%Cá¹óŞmÉA@çĞYÈ…xRÕqi'RûV™@NÖóõœ<M™\HCR@á² ×¬è,²p‹“!ÆÆ·>Ğ<A®Œ1‡@Yˆtøv$¸C3°˜´^qŞĞ>Ì–ÔÇLxƒ\Ï¬v#PH€†%5…9ÃYÁàÛ·+|¨Ø†yhçSÛîşŞÊ@z—ÍcĞqšØÌ¶wr®!=]6ÑÛÌñÂr{ø=¹O^f®cød?GZ°HËqòX*…i€€É5×-"çtüµ[)ÑŒ(©(rûóüÌVŸ‰ÅÌî´Oçï ?`‚I–Y“˜–·ìZ]h9 ˜s¦*Ô=3f’+EÈİ³RóVÅ}ª÷Cot€#eÃ¼Œìï£/i {Sí‹«„	¯€>±Õ}·t¹İ ÁY0ãXşoçJÏÑ Mî8Nš*SBÖ=A§»¦À&ÁéÜ&N­¸BÏDsÚÅ>˜³S¢Œóû„]¨€§vhS„­z	ÈÁ«Œ¸€ £w6;ª±šÅ‘¦E,#òjN„ŒRˆ"‘YâD6ŒN9cŸ!ZÚp^ØÖwÌ’3ş1¡aÿTBAÄmİíÕ=ö‰!Ò¼¡<‹7Nx´@"ìÇ B†¹»Vgƒ•?•Â¯O/3`‹~Ã”Ú5B·ôıéÑ¿äí}°<í|Î`Hİ«dNù9˜+;£±ÉdÃ—N'èÇ.Î©+Š -´™…¸˜c7åõm” <l•iŒD_“m ¢f’ç)Å›0I­;t<ÿ}Ò É<'\˜mO¬Ê=GÕ}¾¥DÅY#k’ñæ˜¨÷ãÍ]gRöÌ¯9î÷ã/†¸¼Ú…Äq|j0Òö}(ò~	ßn$Ş»0İè·TD*Ë
{è¹2ù`6GAM’ÒšéNäóf~8ì|6.]ÎÅÚ«ŒáîM±_]Öü¯62!Ü@ÜŠ§Ôv+[›ñx:€6d?rÀ~ÑUuj0‰µ‡À¤|Ms³ÿâİƒö™ş^uª½‡óy3‰£n•[®îmˆ‹ì­û²äØ8PÅôû×“3V…VëÿL|©úˆuŠ”ÏnRHĞ£-$İE>½¯?P¡»½íKÔÉ{?É¹|Ç‰×Ø†	«¥Ú4^c¾­äQ±ÖjçVÂUJ"¯cÇƒUŠ¶X,¯07~Î±Ÿ†HÏñúØY°FŸhİÙ®·?¶W¥¯ëôĞÖ)¦‡÷ıï†²š«Hã¦8'Ú_UP0cÛ¦œ¼RÕ,3N“Ÿùö`•ÜëYµGy³shïÍH³G¨W|úÒkÚ¿Ñe’è(»ÚØŒ4UöÈc¹tÖ3p]A2{„õ«9Ñ]Rßin¬:JjSë+Â„„Ó<2€i¦r™³=š'{h®Š%¯\Ã¯Ã*ì÷åèup•ºC~†Bh€Ğç‚³äêÿ`’VÌ§ÈÆœËk.…iÙs˜”‡f˜ïŸÄÖÏ 1Î‹wA2O¤ÂFÔË§B;.Ãz"’øvıaıÊ¡Äqã"amŒNäE¿´&üòMge¾¼ø…y‡grËıú[¡ĞŒÚ"ßUè•eõ$óÏ=,‚1‰ÓúÙoG/HQ¥<®H'İ{~Ã3Ò0
2•„VWZèömNö7‚¡,³û¶$wYw7´¢>_"»-MÌ¿HÆ¹ÁÍ	÷†éq4lkî?çce6‰ÚîrªÃ	sw,åµGæ’ª%í}@QÔÒ^–
qDBGÁOuv-rÄ‰	XÂßtÛ’EªóÂNÖt<VçÄj©Û7œ“Ğ…z`í· –Ü7ê›[R¯ráqŠ©vßĞ,‘©àú¾Øc¯`„5b4ã¨OrŒeÀa¬Ù. eoAJún¾ü³Ì–<nCş¼û¯åI\ó…8zL ›,Í7!¼¶Ç(/TĞ°;çå‰KİÚ˜_$ÛµBâëó0~óX´¹Ì[|ÿÖ™zAÓÕÎdÀ
ÁãÅ,_WŠ¡¯Ñxô´|‹½vÉ; ÈXc<†LT,dØÅ•@Ã	bf² ÔF¹‡Fÿ°Ïìz8,Ü‰&†¸ª
äZHùãñõF¤f&:h›ÃU÷û]µ¸tm˜’f­%Ù`?~çşÜv]Æ†S®1¡H³¾oFÄ—•÷›ùÌhh#kPõã•Léü"‘†I ¿ß¢­&€\Û'ÔíÊVƒş¾İ’‰é_‡èÆBÁ<çÙ&÷QS`LœPöœÑVÑ~Ia±´¤K Œ²	“ÈN¼(¬mxÕ½«;QUû‹=€kO’òPŞß™˜ÙÄ£5ñ9x´øN%õqªì¡Ş¹Ø‡†*³$ˆ\Åôœ`´ı¬”ÑµR Ois_œß£>`–¨¡³¿ìmó&mŠ—&6ÇÓÏ¬¦©.¾2ş* ^ñ(b^@10‚Ö'9Ì¼ùôªs E¶'ŒÁıÈ_•€¬Òùªåİ%ÀÅg`¶Ø» 8b¤Ä3fî´Q¬0àP|kÅx:p+xÿMší¨Õÿè%I4uešñå"ôÎbáŞS]Éû¥Èéï|a¸§#˜UãŒ6Ï3ôrØëyJt-|;¦æ¯ş<ÄÃÄa4O½MÖøGô&¥l‡*Ì¤»N9êojÈˆå¦™“Ad=‹X‹ôA²ÔÒRÅİlYIOÿ5mÓa3s5J$ÍV/¿UÀ©{xÜBÇB&[à‚ªr	H}D•Ø¨ãgtR™à{°f·„Í©pQÂpêc
3X²e	ÛG'VŠ0‚¢aÌÇmÏ„¹6 !ÓÜ±Y9g³ùkšB+b¿:¿—\ëñõn7ÈŞ(“ŠªŠâÜ'Ş†¡èì*§£¶ õ8¶†¸óâ–‚Á-Ôà8¨2^TµyØÄ…`–]È¢ò‡iG´ÍÖ)LÿV9Yd¾[=:±²ŠoeH’õâYW@—Æq—,±XÁ[5‘¢ÙŒF(p¿¨s²“òÇ&ÍÍ×! ãÙCÚx/[O6ê1€Æ64›Cè¾Õ-îÁÜ‚[ßPÈİÿô À€´w)ôä˜-dÍ/­	š‡ÒÀÉg¬0?7ë1mğÄµê_šh«æË˜½:caFÈÖúiçÙÅ$yÕHhk¢C&¼ó•Foª¦¥ë:Áë‘R£ïˆÂcò½šå‡kò¯BAütµBÍXº˜³^ŞåÛŒ¬Å$‹6+í&àÌİ¾£ïÃÖ İA*­Š©Ü&ğzı*¹L®kúYŒJŸa	Sù¡ÖŠL/‰ƒë¥_ñúşÇx‰É‚5²CrR7Àºß¼(l€&JX½]ûóÃ
Ççy&=•Êí¸LôyÇ$ùD}Ş;dP¬K^2Ûd‰Këámía(fÚµ´ì¬Ø3È
Ö‹yK"“ù
Cö
¨‹¯_sF^Ñıö+fø‡´C[i8rg@_vkÌ'D ÈKlWşpŠ;Ã³«xIÃÍÉÆGÛ®'\c^®2ÂŸ–A[ú ~(r p˜ÔÓÙCÚu„`sFí¡ş‚¹›”Iİ"~ücq§İŸóÖ
=¸Î~!àG‡òS’·M˜vİÉ—ëÈÄÜó.î³F½=+«Aw=}TA„•Séßzä¡ÙãÌ€í¤"Ü2OJSw¿Õ˜pÔ$×Ñl£,|Ø¹ôÂ~^3¹HY%‡©›{K’
Ö$2m üI—¸Õ.¬«ú±÷xÖ0™{=F£}õF7¼œN0L&q¸šË)_ÂfeË€ú¥~¿úA‹ô>  Ã×«RïÔ6—@dÀlÑ¾ÁiJã\æÕÒ—$‘ø9mh?@Pú+šØÔ™‚ ÷¾Ş’¥T)§MÒ|Í’¤a«©”’b•³¦võŸjAKÏlŠušDğV¿{sÍ˜î¹ÅŞïv]\$‡* |>ê³D-@‰+ëìIæCnØ÷¾­šKzÃ‹ó
 {İ†+¶^)l<Å$ &@.Ke_æ{²ÙT»•8í_Ó¼õ„ài–ÆuŞJ©TÈvšO‘öŠ¡ï„WÙ&'üĞÌé´_ç‰»ÈñY?Ûú±B`f%¨ıúBÑ¥ZÿuËÎÌ²ú½CÈŒåâÍ‡¾ ÉÁàu1’ß¾ú‡^C”åuê!pa”Ÿüõ½Í¡Ø¢ÈÙ¥e—uS„¾RÌÍøÑÁ^ôºÛÄg«ïÓæ,*˜E—W­KtXşÕØH2é~¡("¦]TÔ?0·$C+²• ËÙ+ø¼¨ÜN¢(FXğ”.Ÿe¿AÆv'n¿31	ŸÓSLÿ×Cé³7f§âì¹Ïë…¾KCo¥v©ñî|µ1­Fš.q­^Z¢š˜¼%ó6è9t°À5…`4OCkŸõs)øÃƒ>9mc>»ñ÷RYÉDyÊjTS¸Ç÷E"Œ„z†…æ×”´Ù[[ áŞZI÷…Ä«~pvj15 sòzlHÃånÀy'Ş»æå¹NGÑ®òé2=ëQÎ}K0—ÜM¶,‹ßñÃıHÅe®ÍHƒlqÕ(ƒ`	ÿƒ”ëN¾eV‹3dVæg’ ¥¹Põì8xÆÖ¤]Ã8üvj¤r$~MiÂ †¡ı¬á>l}té…ÂøWw´Î©v»K.%t‰7$wŞyq[á›¦àl4ªÅ "ÿf Êü|«±Á‘¨ºy«Ì¬dníàˆíº	@E/•çm©ıNÊd§Ò3šÛíTİ'#qh‚°$†í'Øˆš>åSÎhÈ3±åíôoUº–çk#±Ú$	WãŒ*íKşMJ]öÔkÓ~7.K>ık¬WçNÏiôK2UÅrİ¸…³ê?e§·k‚m™„ÕÛ2H0İgä/·Ú7sâêã	WÙyUÙyx÷k÷?hæìn¾š€r=FœS6Ç¿ô)¦*y¼İIÚæì­)ŒFó/éwš*Ûí;*nöQˆöpÕèr…«±j_L0
wğõInC–?\z!¡?[Î³Ç¢¹“0ß‹XõÀ²N!*‡sÊ§á®2~ò"ö n‡[m,hµ–éş¡óÈ.Ã¸5/DÃym]7çôü1e¦TRE>ùÏXh"Ğ<1€xAÔhKÔš6maEìç æ±2˜ıª'ÏêŞUq´"Íÿ6©:JÆoçkĞÌR“äDË<Ù¢4s7d\…åFúÒ‚«Š—bÎK¤¤‡¨­óÇu‚‰rb/(šX@ï¸ö•SÆÈÈv•CLËNQÜêı{$åpgƒ&A!¬[›b@S‘ÛCøEP´k°¾ğùzË¸IÀ•…e†¿“ ÁàÖ‘/nwdòèN=é¨â}—Øšêy¥D­“Ñ=';m¤â³<’÷}Øßu:HûƒÖŞHv4ÈtY9øù aç¤~ÏYâ{è¨Öœn–íL_‘ãÆ¾ft„ŸÁñÖêÌÙ÷DL5îìµ€(kÉö°"Ôq×…<Ò4ª…mj¬tšákyIú»R GaçÔnŞİçgmCìÌé Œ —@sFUˆ>ğšÁ³½Æ£ñôp';HÒâì¿K?Û@•­›Ÿa;]¨â¯ëlÕcìæ"“/È°÷8;s¦¢[æZ†l|6¯
’¤Û$÷äÁÂõ'=„££ğ½!Aa^P‘u úG¦7İó9¬2•ú”@#?óĞ¾½6µ{Œñ_NÃ·}Wxœ†âÅõ`ÜmƒK+µp/c@’sÈ:E{Š­”Jh?i¨U/Fm$G´Ã_
ÖàøèÀJİ NâG½øƒ!=\9XWÒ'6"ÉãTÎÀÓ'¢póS¤¯˜É¸f™Ã>r$Â<ôåïã°`·õqz¬_öO&ßxpq >zü²ô{ŠĞ¾Ÿ‚^Ël[ë©Ì>Óæ$°÷"~âØÓ›xû áò>­Œ°wÛDßÂ+C‡<ûŸÌCÎuk¶°íÇÏ(ØÔª!î‰{˜¿»¬¾<äiK|Ø±;èLú†Ùxé1YKŸõéÆ¶9İºìuû$®¿ÄhÒ#ê!­šÿÍCâ:ˆÏr-Ÿs”,-‡Iæ© øí¾"À`ö²¹öSè·sÙææÄ±™¹€×Ö‘ÉÒº¬Fî,©)½/ÕÄm
¿Ò,~öÁNLå“ÁÉ•tLN;HÛo; `¹JR’WãJšERŞ¤oÊfù~3 z˜sØ‹ İd-ŠÑ:xCG·çÁ0­é•×ª
 ½9T—¦|µ›2JÅ
éLCœBÆÅ(×ô2ã•ñD®l,·*xÆNÑZêXß¢æ[iÁ3o5ãÎ2]ÔÄfö¼NUNİÌW½ñ²V?’<ı:H°Á‘¬T8×ÃÏİ¸v¬ÍhÿònËÛ×2(8"`IosJÃí¹tÑÄ!]Ób¸ñëMœ»£wQ«…qnÌÍ^_jfşºVŠ÷rI˜çy‰j/É2²LS¾9È&[©4î¿Mj#ÌôË©_'XÙÏ“İLŞ^é9D~È $e·}ƒeZÂ~^INÆÅõJÇùÆDšÚ,8+¿¥Ré¿ÿÅ„†ì¦3> 	{˜ˆ¥{£·é‚U²´!U‡#Ø›5¾Ï
·ìe‚N”hFşƒ
Sü«]8Œ{‹Ş‰¡\†òí?sÔ:ÄI¢®9b&˜Òß‡pšÜK7u¬0ËQ¨™·'ó'á6MLËdãƒÂ®ÓD½a"A.t¦Lé.í\¿q(›–^¨¡eƒ,â—¦­îE9I©WNR2Ë#¨WºO9Fó8ÅL{ó~`h&öuõusÍTä^=§ùÀåSLºg•yİ0ã!E(‘ûÀ¿"óõÙ’q`á…šY÷ÆQ"”-(F¾(‘9{Ë9lb“bòò}¼-!¢ÎœÈç«P–Gø@ìp™üm Û³+
Î.s^HöLOäñYÿyçx•^ÑÜ¶ØËîÉf“ª›—´ •6p7í3t¨ú¸ »›X%@eKXû;¾¶7¿NşÖM†q‘{´d”š¢_¼€B³¬¶7UmD2‘Kîg&ÇÔ5fYãé¥”Ê´O_Ü!@ä±q;Å¯¨“‰C‰ÎLÚXÚ	)£ÿ+®·½Ä€):u•üªŞTÿK0c€ªı	İlLè	†W~!÷DKì?G=»¹ßÈbXÉûGÿ‡RÌŠ"`šw..ÌcÔÑRÏ!ëb>oÉš—ßg÷´§£.è¿e%
¢ïG‡M›“Ş'ŸASU¢±?'„3ƒaœ±xõíŒÂ(ôÇ×Iæ
dŠ¨ŞÃö)bML‰‘6¤ÈöıNï—KãJ&©NhMÛğúM·÷ÜK‘Iˆ9Ê \×’°°áÚ™!Ï	Ç¾¹şXŞ–1”mZnE=û…¼u8ùöÜñÿş–Nú@m¾8%š9¼¯×@æ2-åÔÑ‘Y=N–°ÍIÿwœÆ¹hîgW
ªƒ\k\[Í¿&05Á¨ø¨…zçè`“›Ñ£ÀÀÍãÜÅgæãµ–‡àVz^Ö¹}KçIBŠí}_KK±æŒ^ø¯%¯”æ¬Ÿ·òJÒÓ‹oh^;Š@}8€\µr¤wvO%$'ØÄşoš—æn¬gÃ•nJ‹Àşï#WÕÓ_M¸ŒÇy3yNã±ÚAZ ºò7Y”VíÚÊÇÍ™êşù£ÎúØÿ>Ns7®	àMÏm­:øÕóvØâÅõ[ß{œ›òLcçÚ¡?æûÊ]®Kœ(OY)u/Uv`ÌÂóÛÆÎ’ƒ7º®$/™'oM	×öL{6I—Qõ*o¾­àèû^´A®«‹æXÙ]c§ùDQ˜Gp
¥şa„¢ÊªsFõ™WşÙ>~Br]™Ç²0½t³) LóÓ
Nï¾Cã–|¯jÃ-«GÚ§ÅÕÃÅAa ş·Y¾eÎ{ğ·.4ÓPd‡‡Ú¥«A±yÈ/|=ÎÔ™ş@n´ğ±Ó,yH–ÑB·-
%àÄ ³Ğ„lM_kÃõ Õ.
!J'h®ìwv‘:îOÓC<Ô—Æiáˆ­áÚàAÁÆµµD¢Â™qÉqÂåíMc8àø¹å4ÅE¹?ªİ6Âr[<ÿºJfäa‹JbğLŸ=â’ŠTwU_•öëæ1šÃoF–9R+Ø•úäÛ ÃÅÍ1¾ÒŞã/)ÚéxÌ¨êÁ!-]òH½
‘ô¸q×h²£Š"f[¿ØyÃÂíT-ˆ=÷G¡EÅJZèrg^°;nê‘=taµzvÇLËğv¹jaøñ+üW¡ªÍUcŞA05ßÉú® y“¢—T¡a²HÇ”KCâe\âµºû…Á¸V˜¬qĞ²9Ã%fÆİ)}æåiš&0D0TÄ¥;s·+F›GTQ¥aµ¹ı³tpndÙ<Qp¨ö>ı†Ş.:7ûâãı¨#>ÈÛF!µ×È°yUm‹¿)Ó¶+VKüÕìÈ|”¯x»>;ŞhU;(tû»1½í`f°w¸¯>rQ£;³ÕZá(R]rJç~iUùíÒ
.3dş‚Í<¸®/AªE=J3¤Dş0±S´§ß’¶ªj1Óıh°fO¹ó½úÒ_ÑÙs{gY•ºq0Æ Û÷#/\˜?¿¾K³¡o”l­¸z»oâ2£À;äF|2"«ÅX[tâã>pT¤Áó–÷Òÿ°•ıVÖvÒ(÷íaÙ©¡ö2I4zlÉWÌ	Î75vöª¤º—zèèÍâ¬Á£ØÅ«şµŒŒbæ¨íÚG£…ı/eÆd‘şØ®m+lƒ_GC ù4Ä±V¢ßŠ¦æ&)Ÿº7…ˆ)sF­páx€IÓu][08YwÃ’~“ ­Ë™pDbaº©0¼Œ`T[Ø*¡–€W<W!ô÷BTÌ×Í­|Ï»uéìPWGÜîÄø½U@±¯İ9Š;HDIÆqKÈàÙH¬VoçÂdñú‚¶jï<ô)|;Hî"®óf1aÇëo__&ë¸ec»‘4ŸgŞuÑE§ŠZó§a½OÙ…¤î¡Æù¯ÛÄ©Ç7ÚHK«$ßË=XõöÅÆÊ ®J|IeÃ¹.ügÔ¼ÆF[*Õ3ƒ´á-Yïˆ+ÅôØ®…ÂM®Ù)äÙÓgBğ}ıÀ^kİÛ£õ×-ÏsİŠÁLàs1Nğ\ìÌ4ƒr”—W®¿Ë?ËéÊ½Ø_9;áà&'í$ÏM§kn!¦ÜKãÙR‰30Üş-iFĞGòs©jCª”mw<;ÔÖ [tµ0Õ€|”…axM½r—›ıŞpnĞnôÑ’8xôQ¤öv¢'æ¬¿Èğ]ªd\~Å @W·NÓ@ò»pWêÕÓZ~¾+vĞÌ\/*gÆ™*€§…ÄöŞv«²uÜÕ®åg~:S¯Téí™¨Ñ’è8DıS‚›„<T­:8¥{ ÏY«ó.ä—<í}×áèUÙo‚pIÆ´Ó¥7ÆÙ„ûŸÜPDeW|Vq¸S<<e Ò,ãÓš!.vs=X|‘qTê-ÊÓéT’.\©~µ2¶e×¢ Õñï:€×S¢l+:ˆuÑx‡…«ÅvÖ?0Ó«ŞÇVêN©DĞÎ?!¦I×jj§H¯@^Ò¿nÉœOrlÌùû ¸ín1gg“cŒµ@‡ùvàkj©²ç€?ø£>t<?¶Gdõ ÂR¨>:\è}ª_9di’^.”Ct:Õoç¬€Y¸ï;½`K¾ÜôVf›äÄd‘ä»óÿ >N¯ıºM<|,–t=Ö.ßŸŞ¦4‹iÈóKÉ3RÌË#ÊW Bé…a+ b¤ÊtÿÁ%Dhğ²§¢ï¶üv¡’'Šá&©š„ÏÄ*Y‹ÎËÅñqF±-~û´Hlé‡Ó:Ú9Å3ñ[2MG³%Câ˜ök¬ÓÑ~^¤‡'m&ÂÛõMØ†DQ­H8öC`yØè1_Ä¿ËLÌZuäm²D“AÂîÔ@v‡ÁP)t*I7	wÈ#¥³ÂÇ„É-û)ø)²¢yñ÷Ü'ó&™²ÙğÓúê>¯bşÀ"rmF‘ô!)<q×\[ æ®çw¤o·0û2İ&üØƒ¡dçCÀ°%`‡gêÀ°a&PÊËÜ.½²Z……m%‰Á,<vŸ@w÷Õß7ó5—¼¿Ç{¾»~÷£­R\;»²­,šuYÉpŞJœrìõ€o‹¦F·]m¼¶Ìy¼š\MM”ş†‘›†›(ILÛ1(CäÅd…áÊû©é¹_¢hÍÅ€ztµo†â
WrÀzh<q•Á;¶]œˆÙ‚&>8°Şëã0ùQ}#aé‡ÿ&):a~˜K|•eê|âz“R[ËK¹ñ6aÚ²\ıà³C\ù+iÃÒ}fîtÏh	
ƒ?¨©Ñ„rÍüÈËùH–®;šøvWlE8øÏ ^Aá¢Á%Cyo“Ú?¯ß÷ÑŞÙJ@Òì ”˜èYşûvºŞğPĞòõ®/ÇœvIg´‰4ó,â‚Zí–'‹4ıÄæ½57e+E	>b¿¤[ŸâxX)qç´$ü¡ĞşO‡mp‘Bÿ¨–hHQ¤î¿i¾H¶­[ÒŠ÷sfo$™1¢rA£
r¸ƒ\}ø›â’¦Âf 4ì.êRëAÀœÙ›ÛL§`Ld1w^Uê˜œäİ"µ?ãIÉdş?œèY «ki£æ4 íõ°Y 7Ç"<)zİ‚$üâC—
M# €ò0:§ÉáÓPÓÖjŠ§ÆMÊáºñ³â5%õ3ò³g›-ŠîŸÖ"LâX¹Y˜ºL¬¡?Ø
íàk÷ÁĞTh•şÄu§çÁ’`™É¸—7a»uÃ#Xe÷•ÎÛ~T#,ş¥#ˆt7ÑDŒ™bN¦q|¼şØYÓ‡ç?uq˜¬6oÑlÿ5Ã /m}Í`B…³“L#uTg-’‡Õ¡ı7ÛSæ“èTP¦ª‡{{yX-¸3²:ÓóÕŸtqöpGmg3ÅÓ›ÿí
â÷ø_´U™ÉÁ ³õ×~_ØT\„'Xe7¤–„—­lÓSKjŠ·¤ïÒŒ›Å|¸ƒ»¶Fmpaßî/Ôm¥qYŠlpÑÎ,ÿá4#$ùçÊ§Sõaa?“‚]Ñ»Èkıæ¹á°ÚËF@X=Læ \ÜƒÑ«ª"=USiow
-ˆèO0ã0ñÜq ñ™e~NµUzSzÕB‚Q}Şï!ŒĞP;H|Cáá‘Ç•ìF{WÉ,}äÌVO¤Mü¡şøÙN¥c½+ÛHucE)kÆÚh w~›ºó:‚ËæH@ç„H
Lä§jª4D©*ôI1äüİÃ@#úI.´”f£×£©‡*J`^¿*¨/
Áeı—£0ÄÜtd’œßv¯{d¸±eÊbÅƒ9G[LğáhCª]ËnY](Ÿ‰Ğøş—¤!-\-€¯Yø²œB¢^OT„ı×$ÀkD•:ñ±2{w¹€‹–O~4èå–;“FvÂmİpí6Ç­#ë\Cñ'5!r—sÂs5‚+òjë¬*{LÉ¹ÖÏV?!şÍF6Êì~<ûO¬;á‚·œ2¤~ë=!ÑÃû¿M™9öøcÍ:ÏZomœ_îgƒä1åY	¼•YS«0KFÁØsD3dÚäÅócŠå«ê¦25c4Æ­!ØB¥qÊP¦;xTı¡ “ïYBÇ'1rÆ¼¡ÍîJ”¹÷Ã³.M\_—JÑ€_{¡ÁÓÿtÀ:ÉÂGòB¹cÈWÁ5†m¸pòòû-0Ó‚3rì»ÅN]qc;”[oR1‚mÇA©";NœCë¡-qUĞ”‰Ù‰ÙÊ¼ÙÖşîµ* @u¸O¹J·Yynóğñ‰×‘SCÛÁ§^¼Ö–ú:@ÑGdyËŸnNÃsÇÉ§ÿùÈ=UQ–­Ø¨/<=ä´…lkkB ‚ê?&k—tí×ÅÍ‡Ç½ßÒb·™zÂç`C3ûÜ¬rÅp¸dÎ@ïJ"7¨i\æV Û‘ClÔt|æ‘=×B†³ãº³;¯i¿$×Pk° jÀÃ|ù]¼¼ ±Ì¶É%ÉÇ¥Jì‘ò({ÈíZúÎ‘&Q;s.„”¤©Ië¹ÙÄÅq°2«eVq½õgtçµ°Mò¯LV¬KšS^IûÁç_†u^3Q§×Fô«‚Ù¬Klg)f‘Ö8œiÎ±0ì„½:í·åƒ|ÖzvªèA…~øêÔ¶Åı¸õ°ï„‡3ZûŞİ®P	˜‡¾¶à>ĞïFâÓÊë~’CçG” läéö	Jb»á	ƒ“û’4nÉÆ«aøû¤ˆ}Z5ò6PÓN^nöRÜnäÕôAHÒ4b;3jÂ}Å»+¯ğ"Qe*Q¨{‚ÉXx÷WÄ»€Eâh·Õ<¯iğv[èÜæz*8]kşñÕlOk¹$5/Öo{ø„üÚvª-oëáÖ÷p“ø“ieº.‰nÊÈ¤§Îş,s¬6ë• äü£!nÆG$áòŞ‰Yt›2W œ]G™Ñ›‹Å‹4.¿n8·çw|ó›ÇæÍ´üA>ÙZ‰­Æ²ü×Ûİu<Qh7¨ô¶ÃcÜÍØÌPã¾º6ş
–dò•5<Õ]¾|““[ıû70Á<÷}ÄØwÿ©koØHÃŠŠ|geúRÈ'§Æ1ı¿g×RA‚xJñÀG?zˆíû¬A²m"xµOá4Ÿ§Q7¶@Ux1—¦ªÌÌyjùÉ|Ç_Ñ‡Ío+«}fI{Å&=w–ñ
"]N_Å¾h2³ÉÌ »§Ú‘TCWFÈ>K~·Œ­±?•É*¬	93ö~=µa]èĞË€ÉB¸|êïò¨Øüú<;>x¼JlUâ¯¿^v~®š÷|úJ¯0kı¦pĞ{\²:
”M½¹‹‡7ôH`¾]|ï„û±,oßÅ78ä¿£ü‰Æ›Íİ£@Õ.FùÅƒ3+MÛŠ!4ÿqÕşu»@Û*n0‰Ì‰ÍŠú?Ä}?±c2õQm¾ÚÂãIöÚ`‹ãeñ»PÍQûõ@÷ÉL›&ÃÎy‚Sú Û•…8:Eı—²yÕ)3Õ1´T)Xlä®‚®Šü‹G0Aºp÷ê‹Âï¥^ `o›6Rfn‹VOïFê°É˜ôä*vÆÒ»‡ •<eõEZ{B›'õIZØ"Aù±r$¯äÙåI]V:G€Á^Af}7Vóxz¨ñçŞªZ%äèıVĞ½¿°8:Ú+Âƒtšì>ˆ­“GËâ$öÉm~CÏ‰*àeÜ„ÈşY«hüÅXBº1Â×4ƒ*ŠšSø)4øFÙ5:êìE ¾gL!Õ-–;•ÃZÅ¡½älÆ‘UÎ²¶ÊiµÂ8é$²¾Œˆ%"ªC4¡Ğz€bpÙ¶ô!ğ;ø<††ƒÛ¦ÔL W&Å–¨Æ8DzHĞ¹\¶›‡{ö«!¹Û•è‹¤k‘´z)Cû*-şá9û±aÈ°®%Âùy_Ö¯<‹¬XßÒá½Nı‡nüŸİìFËYÁ¥Ä ¿E[»ÇTc_îßÚVÖÖfRëºÈ÷eàÂK$µµØø0 ûôåJV{j¢W¼Ìa:rŞ×ˆ­ñefaĞ¾v¸Ê¤ŠI @¼SŞ›xœ$7Ê¢âG¢JßÑÎ]õAJÏÕbü²’½X‚ğH€ËcÔ™˜"bZìL‘¯‡=8™÷mrO˜9@N†Æ64?ñ
b¶hù”Ÿ*CáÅ\i'e ğ[æ¸„ZRD"5Æ˜‰,Öı¥’ÙMâçWlzéï•c
µb6*¼"÷É©=»œ^Ä/.Ù­¢¨ä¹·üØ¸ Ï”«4q…¨5¦·kŞÓ'6.ÛJ¾s‡Hzâ·pØ&~0@ßşêØ2âŒJ×›„ş¢eúöZ§ÒÇœ0Ú:õèÌ¦È2+Ø:PÛ&p#øE›$tR»uı‰$ØÈ7÷¹ğ‚S¦ê
¤”u¬â ç¢¶YÖäïˆËé—yåc5½W!zåƒåËÉÜÖ6¤ı[m&
Pa2©>f
Õküs„–Héı.ğ)é~iÈÂ™=æè8
‰â!¡6æ"ØHÜ$²
ÅB	¡ˆÂ²$Ø©¾ç³;‡#W½‹Ÿl¦w&ªDv‰ôÇÿÓ2Óï^îoX)ÖE•xŸ4R|°j‰ş08áFÈµñ£µ\¢Ğ nV#3Ëf,î£1Ğm#e'6u ÕˆPÿ’¿±_39µuyÄÜ¶3Á¢.ái÷=·(FÔlUÏöæ`?8G9ŸŒ¸æ®2®n´.LAÜºZ ”!Ÿ×DD,—Ä@¡>Şªˆ¯wº= §ÿã»ax¢kÍMıh75n*«l­råú&m;±FÆ„)	ç¹m	¸K­ºËWE”tı»dœt‘-ÿMî`ŞôxÈsw*r¡-aø{MíS™¡e­ñõHŠõZëwßïİÁ'jL:ßi­'eÖ 7¡39šß%ş¬í(:&6¢S@1	Ô¨ƒûèjFñO±¿}#jiÏ«õ:ŠEŞŠ7|d2¼iœÏNwkÒUÇ.JJ1Õ÷Äª»Hœ¢}i…ªëú´süì4Éİn¦º1X=
‹EaÎ4ÙÄ;r³¬™‡5U%÷ğÉêvÆ‘dø¬W‘g~¼•®«-ùÛVÕç»/v»ır<Ør“gÓSˆt{ˆë–ÔäRûq ÑÏ ‚­ÊË4Uú-ÁƒÀÃŸ»Şõc>i‡Ÿ|Ô›r¹ÎûïÍÏ˜?Æ
Z´äÄpÑT]İAäÚÜ#C AqÍÈî17îÙZ‰•®N/S®ËÇØ|ÄS;‘ù0+¼Ë`EOì•w¡xc”^]OÌÜí¶À_QaEF†6±Òç\7Ÿ›_é%ÇŞ>M›RÄÅˆÄ±¡ÍÙ†	¢bÿ’Uv¸ëÀ§ÿ1Ö«yCcÜíªÁ”ôÑöÔîUXÏ6¨o>â)´k™û˜‘èkş4©„‚scÍ+*üNLY#‰k°oÀ:M£ÏG–Ndx ò]¹ß«¢ŒáÄ’WıA_ç»AC²5ïq1Nú:qÖÕö†ŠE´™q+ë%%cú6I³ã s•–Eë|ÉıM:œ¸¡ÏÀÛî¬d«!¼MÂ´úâúDvø=-şö>×Fwí'bwy±­YnŸ"
ƒ×lû=ÿTİXp©rxg)
¿ÏÍ*…q_ó—ÙÖø?È!PÀmb]ÕÕzóXg·ÿ•RMëWœCnXÖh¢+áêÆì§ŒMè‹W*­b}{ÅZV…FÈ„‰/C"[Ñ0¸§vèaèïÿ
¯ÉãK÷Ö_E]o‘Ï< 42ëOm<Û*¾I8ôê„kKş·Jíñ&¹'êŒŒúu…WÂäÎq«&€óhù	ëª{8J ¦šÅiTg6Š;q¹JG w¾² %&.=^…OI
Ó,o]¨6"'â­€AómvGˆ4›ex•ä|lÓü'ÑAè.‹D"6Êæ%›3ã7µò;8W]"Ø·×ÌyÔI<;é£,^>šÛh“QO,µƒIª~|:TÛ’Ïñ°lã´
£“»fŒWq¡[9ŞDÀ~¬–ëõ.	§™‘'‰0[\“c˜ØPJ:Ó²Öl˜+³îğ>ØX?ü4„»U8_Ù
·úœ¦WÏ×ïZX[M¶txŸø-ÄÆÒTä–B`v`NØÄÉ(ô¬sCíÚ ·ëèlD|™WÀÆHØzRó§]İøĞ_¦R8Z—'QCò´lî,g
wr)ÈÚ˜…4€Oº†æ`F*™‘’ó‡Mpä|ï2Ş0Vê’cf‡I¦Ÿ/Ö‹WœöÚŞÁ;ÎÍŠ4wîµMzêc½M zÃù©ãBz§§rXúHƒûZS+càr£‹Ç_{H•—ì"‡ãAì"üc`Ï¥úGa 7Ì5g¢D ÙGÎáÆÈwîß‹ÈŸ,wK ¼sf•İP¯œÔYäŒ¨5¸?1ìlX	4´ò~?±êG/lCÆå^¡C«ë·w¾#õìî)x³@×&ÇháI(Z eœÏZ‡Š{¸Õez­E¤ó	çe·ìZgSp-ø5nÆú;ˆTà‚°çø*“Dà„ÜªaÚ1nÙå~U~ğ<Ct8ß’w¯¡Ï·&ØØqA»Å¼Ÿ¨t§èü
”'Péq¥7Ìµiôs¨»³¯¡uúHWHB¸É¹s"åë@Ú¤/î1c×µ-÷wššŒqB¨9²0ÆÔ}	ÈÚñÁ6ñ»ŒÌmÄâbNu}°Œˆa”XÆp¯¢ R&Ë©¿1/s¸¹#¹Ä7Ş
Î¶Ó·ÙZh3®mÉäx©°C?qÄê}p=“[t¢­§?hVà±™CplÛÉ‹»Jˆ¶™Ş3ô[k	É‡»O?¾Í·ÒWĞH`*k#û×uÃR½ÿá[‰€ªz, ®æ+Œct™ˆ2£ÿƒö(]ïù	3¥]¼6¶‘-3k4Ò$œªâ<”‰\ÿ-‡vo‘$6ÖÖ'2ö$ÃÇ—:¾ö;Ë–}O¤Ñ\Äm6Atê^F^z± {³­µ·µCB.{yÔ	9´~àtñ¤ÜnCè0üw¤7®÷“6fzëÄKÀÄªÓ*9*¶$ió¬Ñ[@ÇÔ5oQ¼œîÍ •Ó/MÈ&9Å)ù¼C:}-ìy+%¹ã
£ã:8¤ êÌ–ÑMÅïZàw¼°'íu	í‹ÂŠ?7HäuƒbÇg ¬šZ¡V†µé£0N¸+Ì9ğÖ©™EğQ`jHpÍ‰×VÄ†3òcÁŞp³¯UUX¸9¨&ƒDcfğ
ıèu2oDA.QœÃ#H34Úù³nT
öâØÛˆ;rôú©'ZĞ¶+®Á×à†ô!Õ¶èà›İB~-{¼O@.¨O çùgÆU®ş…Ø­†µ™|”¸ã™‡ÄeùØùf~ iÓ|õ½µRL­b-Ö¹ˆÇÆı3P»6ÜD:ìLF»1»p#ö>5ŒKóšcæ0x´Ò ¾H^]­¹¨Lë_7Y*5|ç÷R@ZåÒĞ¸Óo{@¥Ø²–øÚ»Ö¶¶³‚©Ï
ğAnª#î¸â*buæ²_¯°{ñÉøAg-îP}Ç%äÄŠÅ…fåsÏ½ Åú5¸ê$WK‹Áï€Ù{ñ4_i¬q-ññbôß}Ë\Èº¸&Ö“9zê‡[^5"Ô¤=±ä°ğ\necg“gÜ8ş¤©i×«d˜Òê!&û¸¾õò9-I[Ñ|tY]* "ıè†ıq¼zÁ³aÓœUWÅŞ>ì[½>R*¢nbå¸ÛÓ”EV‚5 iTmŸ4~øKuµ' œì©VrbJ++¸[~<¶şu \"¢f_Îı	§bƒ[iĞ3ûx6PQ+±jMõ¡vèyr¶˜ãÓDĞ£ö®²
G×uŒ‰çÁ,1µ@Aº<w÷5ÎN:¸éDÏEM
aÎÕ<ÄÎÔÑ<%×§‘Åéêì-VùÜ3T¢zÅì‹ñáËÀ ÅŸsÅĞ,ÇTæ®l^ÆèNú¶
9 ¼·\5(9@ ¹V‘hà˜Æ/Š¯Æ:`}€İ4F¬Kí-–8<'â(ƒğæ·xx;¿÷³8Fˆ&Ã&T"ò¾4½âÃMáÇ6BÁİSeÔgÒCÎ|7_O|Š:J`´k%3]{5}äƒ0½C&IØ~BHâJÆŞ œ Â$ê«|jp’ªˆ\iÚ|"˜éŸ{€¾kœŒ•²©D¤Æ—ƒu‚®ÍUöO
Ö 4Õ%RdÎœ¸ `	sgBGaEÉ"r+Tü5â£‚_×$¸$İÆz«ô¢ØiW$³ıóÓ9œh`ŠjfÅx¬úÌ‹È+‰“ká>¾o¥ÎÃ CœX>ítïäd¶˜Ÿ‰Yƒ_LÔ¥¯»Ã|Í|°	Ï`‰4:ş±¼Bø»‡(±¨x”Ò@_¿¨$4hÑ3Åb¡,/ök—Ácæ¬º±ğn?M0¥«›	ïpa3ôFSQÚm;@ŞópşÔ•?‹%óèd/¡UŠiŒ‡Åqu¸ÿ¨¡†şà¸\£Å´	°„ï÷ş?\(˜ûÈÀf	–Ç!‡»#1÷ğ¹„tD‚4—¦=pŞ|yM¯VNOE´\µTö_"ÆçÑ›8!7F7}uö»3¬²}>™•	ÿw1…òR0µV©
<ì|Urk½ğ¦û‚`›rF<ìÆˆœà³©°y¿‡hYHĞƒBšø1ÄKp:‡½€÷™ÄÆs¼3ªX!HşßmëãÀCR1Ñgx*@ïıŞöe.™@N«G“½Ç-Qp9P`ÓZ§kì°lm–—ÁöR]Å{ReÉ¾‰DÍØ‘ö¦R	àœ·íb'WÜâ>MG^¼yŸK‡µŸ¸¡9ÄAÎŞnªëVR˜Ù–T”œ…rÈ»’ZH}~0Fø)Á·Ò~ ŒZU±€Õ»ná$¥¬Â«ôâ¶/Õô,Ajò½˜A9ÉRÚ%ljLYu3ß£¶µÏ6Åex»¯^P,qa¼¥ ~uüaóı›ÜsTŒ¤!‰¡±¸„÷£•Nö•¨Ò›\¦Öâ*şX-ö ØÍ´¾OÁÂÂú!~Ó&Çk¯ğ¬İ^iQ’½Û=cÃ—²ñrˆ†WÙ†@Å)…‡Ÿ<:Œª¿ã­o’öp»×ğ.u•çï%éıkıËmÄ²^®*˜ªÊÑ0O­Ø@ŠL§E['n€ix8K¹‰s™cıÃ„3úE=à9Æ4ıÅ€J˜fÖº°;×-ı·gÜJ¥ÍĞÊ–çkáÇJ‡oAÆÒo™¶Å&v0»ÖÅçfş±B7V¼íÆŞg(‰tàdR^³ŒVVŞÜÛŸqûV§†=3`?A®¤Šglx(HÓÑ°ı|VÈÊ€¬9õıô×;™²íÁ–i¼L†º×p§¢W°Ó,ø‡şL=üXJ+D"Ï{iûe]µ?R\°	§Ğ4v±û¥²Í@MçL…Nx‡ÖŸæu0æ‹«öÆ Ê}Şo×6Íá&ÿ08¡xkJĞAäMc!bE=İ0sRÜB½¾ÜFÄÎ‚é{Ñ‡š‰û4 4N×/ªB9¶ó&Õİ91Z«-{P²óO|KSË‘µ"”~&Y¿Uµ]û>Ò3‘†á•—‰ıš<~ÖeI9iÜ³gF6İ²½¸›\’ÛÏ	 eÏ—GèD‰…û‹rKg¢~„pj=ÃŠ{ÑW'+` Óí)mÆA‰H‹}ãí6íå:$'Åß>R"®­?i£š§äÄy4âÈÃY€™lô¸¨u‰øL¸Uµ“|¯.CNë³­ø®ªŸş	®‹½bjüş5bêW‘®ætA²A)óÅ0 ¼ëí~‹ÅB!°-j¯"€ÆfßËŞ:o#Ó×hfı™]vu³I…«[e¬A…ƒ¡Û°LM†B¢ ŸSÀ$‘Rûa—i)Ø¬_Í9Iqw¿\UA]/@}o3èYCùij|cpÖ^.9dÉ­L¨á»LG©a×¨è*1÷»µÔ«/eşü¤&BÄÀqæ^¨7è`DiÌ?ò‚L‘ÕÙ¦aİœ}ø9Nîhğ¥ÿöÉÜRßMUj’N9+i<Äalm÷]»YÑ^rÈ»°«êÚmÛ¾+÷SŒ•şHu™£H"ÑwÃYîˆöÚ*ÌVCùÕµ­ÄÃ&ŞƒáÊ		1…údoº(@¢öå[oJœI¨­¡j¥OSàè?¯Ÿ4v°1ÀµX#|db¶ÿ©çÙ›-şëuRáßÀ’ÿ`zUÁTôQí·÷ÆÑ¢¢0/¿¨Ú›Ì¥—fb{zvò®ªËûû7’`FñÀ%Q³·&#.ZÚ£)‚ëÇDGZAÌ¢QÈâëšŠ€!ÏByûBúú!”¹-9c–wbu&âÿìøò¸{Sn˜ƒééh¶-ö Ej‘çÿóÇÜ¦©Q½šy˜ÁSgÎg°Òdº—%i6¦äu¡ùIûîz¯òy$¥·©6ëÄcH¨Húè0(ùíg4o„¸‘’ ˜[swİà¹¬]˜ÿN€‚NÖá	%Ñáhş?»éîqÜ\´<BnBÊX—i©BÆ´»&Ò_Ö?â÷ş:˜‰ÂËqéû©(†ÖZ,Ç}äÅôJÔµ„Èò„V-V•Q)š EÈg9—ä°
YxQ¬kĞRõ<'à¢ùQ°K=pÿú·B´æf‘8Òİ¡F@W+õ!u+FN<}ç*C‰½u*+!$ÑÏ«1áô2¤-+â
™X¢`Á5b¡ÏN§"± >{ø%Q6Ú€pzú¤LÚpa	à–M\pšÎ¤C¹XYÔ0ğ	0S¹8Ùìş¶æNü	=×­è!¯ãfYnÌı<â^6µ
¯Ò (Ræ¯w†Õ¼qkë÷€FxX¾~Ç”&GçöèñC˜dIÆ6'õ(1jêP¶Aaøiƒ-PğCEu$<*½1YÃ€#q	ƒ‚À¼Í`Åã×€Ç­EÃ$m‡ÙHÈåùA®iü+u4EgõŸÍš°Ì¶~ş©Ë,º{o‡
© W4°70|Œ/œÎ;aÂ·—m,ãZ
LöëXlZ³VKqB9<^&{#°_,KßúŞïUkÁ6K„O¢²cqìÉñmoÂÃ_iÄ?G	QAˆ›œ'	ü$q&½Ùg ˆ}¸æ—ösæä×ñT…+á²BB94®1ÛÆ‚ä(èş›“ö9Jæ¥Xìé9Ï]¤w…<íY‹&€õm¬X«_”oÆ¤Ä_jÔf²;IJó¨€[÷Õw¼İÚ—À˜İch;csåv)ïEµu\HAz.ªÚüÇÑîêS	·‰CÃK+o'KL“u!å¿İù¼0ùó{ô”ô·0üø,±GiğBfªÖwOïå€ì˜"w/b>èÂŞ³‡Zcx³ã€%‰cf`IY=¢ÀÜN+‹UJK|`õ Š—TòÉè×©‚˜RûøÁ1n‚ªØ,‡3z3—Ñ5@?6—q‘}6?Š&ó˜Êòq8ƒ$ATiZ¦§Dš©<¶X¨*˜Êë©š£È‚él@ZUE€Ç–“Eû#’Í…Õ·vÙÃélÁËPåLÈVÜD+ ¸£S/Ô¶Ğgññ—ıV‘Ë‡?¶™~px:_˜´½ŸÄşê£ŸØ*m.ÒçáÇ=ğ¶Iî@Ú‘ZB$ïh*İÀ³r«‘[:b°ÿÏ·™¼µ† ËYû&pĞæòÇê³äÊ¤¤ô\!ªÍ¸,İO‹BH¢¤õkëÕRül8Ñ–ß‘ŠÙã Šq¼ù5q2ÍX4I¢õ€óì¿?2ÂIğ”Pt-Z—ŒàÓ—{A®ïöbéV7´e®fK—87’ô}ë÷ IÄ‹K+¶­:qq4ÇÕA)uƒ’Ä»İBï÷*‹}â˜jMâ;³,Wè¬~¿³'¡†\(+­U§S[.Â0?Ÿ©ç¢JŠ%— ‡ÆbŠdfüª}8­›Eí±Ù=äŒYÙìq²FC_k‡ E7›¥k€L‚ÑoAßõ
Lã81}µYbÊ Ï'M¶¦d !ªÿtZMOEÄg4î³HEÀ¤¡çÃÔùöKí»[bËnˆÿWåèPÕôÉôL„”Ã}c>¦`Ô?şmhƒu7ùQàa¸ÌÊgú>³®ÆXGpwğ{‡sÖ«%³'²TŸ®+¶Kä Yl¤Æwø5Ez=³°cõSÌ¸&uÊÂÓå#w£y3³µ°¶d—:šËºJF"±Ã9ŠÈ¥±°D½È»œ¶3‘`A­õ¹.ZıŞ~ºÖ†Ën2ÌhZ¶2ÖÈ­û-ÚPHİ¼zZ®jëW©Ä'Ÿ/¸JrÂuHÆ–
¶csäÍ)ôQSÃÙx!Uç¼EøÿÉòƒ•€FŞwE»£•¹¿å‡ùÙIşĞM„C}½ß©‡!Õ-ô?w;³®KúŸ>}ŠØË¶$”¶½¼Ë½L%¢tdÁAeo;+Sù6¶‡RêKº<ø2‹ñúâBòE5ÁîÔ®*¦'ÃÇõÑuZçœØB\ØÀu†¦ì|ƒâ%í®:Pï™NiúÜ Òw$ñ¥™Å—|¹<¼a'ÀÇÎ›pƒ]¾Ÿâ×ÀŠ6²Ö‚‹sâŠèû¡«A¼f+ŠÈMõ;4Çû9¾%×;pËªÃv¿÷ b6™\ŠU®ññøR«ˆùåeflI!ğ¶t¼{Ùôí4:@>#¾°ï-0J2Ä;á6î,$SÖ2i8*d0÷G³$}»F{ !>³H±úJ\¾‡Æ´Íõ€6J@Ì:n¬Êõœ»¦Ğ[<Oj¬]±¹‡’	C«~9ì_—•s¥iíÔÅ©ıÚ{åm[fvUÜWËÃ(29¶gûè‹#p”œ¡¼8©h°¡lIv<ÂáÍËQkÌ¡É6bp¶ÿIÛÂZÇĞiÚYÆlF±%–ò½o¬­%dÜÈø=@{>Úº-5Ê©É”µ©¶ŠfCeŸR¹Zèâ^Bƒ8bµ~£f¯ÑÏq#ü)„h–£KìİóKó‡ûù‡Ï
Ÿñ—TºŞ,YßŒn"¬÷09›(10æ	?/ÃjÿQ¦·äã­[ ÁLûO€§&cu^’ âİd½ê²éT$½ms!ĞòJPpª‘˜0½&if8¤ê¡­ªãËfiù÷ôP"Ç¯h_š‚-?,b#eg?­¤t-¥Q!ô^.î8ì—±İèâX‘ü´*îşæ*ü{ø™ zÿíŞhB~Î{¬yÊQ¾»GªÌSåµ+šÙšÁC›ßÊOàçµ/íwfõ{H¹Æ4Àä¨ªTÌ·GË%R´”†Ş0‰WºZMBn˜ñİúÁBECÕ]Ø°"ağ¥Õl½ĞõPæ 7ïú‹o5 -Kı™øéš`ÎN;äæhJÌÊ§ç„ŠÚ6°H4ë¬s9â…ğØŒ´yHsªh9Ê„B4Ãí Ç÷+fßÏL&;§¦çúÙ_Äó«h<?{ÿáÔcrÄöõS‹ó‚è	V\›²TXá·E’Ò[¹#â/İœ$mùë@òIßéî'µµeXK'Î4Éâm	ö´‘V¿"ã}y4§™š­•Çoëœm¿UÑ _ü©Ğ®æFD•hğrfá¶åtö¦W“¸ŞáıŒ ˜J	]¯cæÂ·Â9d–/1 šOÈnÿDduÒùxØJoÑ™¦ZvÑ¾_¤,lÄ†E*MÕP&4sTLëæB@öéòå(1şJˆ¡kB>ßÃ4\.’6g.°-‡±­.w™ğñcâF]† ·cĞÂö\QÛ©¿©Û‡á,{:&=.°ûàL‡±ê_?^ĞJb¤^0™n¯W­õ+¾ZoGû¯ÆÍ4;1mt‰²XRùuêøš1$¢Æë :KÏŠ~ÇO=2pO—-hC‡8E¥V`hNû*¦x©B‡ì@<>L+gf»§^W«}T aœyˆ²mÉÖª)fO%ı0R:àñW¯/¾}ô»²ŒŞpfè„Ç¨º¾å"ev+İÑ{¢ŒşeM7*0ÛP¦¯ëââ@Óz_šğr·)–c¨Í)XÁhıÀrğYÓÒÓH›äC#W¾Ğv Ğ
&T<.RWÅ#s6É9dµò”ÚéSè ÷;Û	¢ÊšŒ©‰±ñŸñPÆ[ 	L8Q*:ŞÖ{O˜ÈÑ&Ÿ‹múy¨°ù2ñsvÖü,e,d§y$‚¦[NV	™v‹µÒ=
c’×§»ÔÇ7†KQ›£„$ÉAzp–Á§f4÷ÔXÔÉ¡³Ô\´ÃŒdbÖÌh¦/œGŸ*AÒõõ_áĞâ YVMñvÂeí½ˆ°W{GLÛÔy`Ä]&^E÷ÅçT-ÒÖo&é†·vÃÍÁŠ 0U41Ø‘ù3ó‚úYÅÕÎïô+@gzb-­6âEJ`›b¦Oy>¢{èÄı7ñ’û7Ğ;õ³"Vwxû"×dè^ıìÛŞ-Æ¿ŸG6cKü
T=g<H™ÏØÒM§#ì†gæÄ`¾F…–Æ_h¹\’¶÷ÀN_šŞx]fò O›Ó¸ÿolmŠÍ§fÁ>M6cøÈBVAÕHõwÚ †0N¾È:å˜ÎC†ßUÕLf+÷šoæxÑËÓ¥±»DªL
>§T ıñ?Š>ì½¾{|í¶k±Àq8¯\h×¨ÔŸdi«ïSà…³÷[ºG«±·ÀvKî’4ı¼õ×  x ¤>IŠµ¼fƒ¦7Üã»Æg©ºšÎpíåæÎ¡¬O³ı¹7øà[—Û4ˆÔ; »ÀI÷™ˆ ã/©£F÷p¦SOÇ8¢5eøà¥W®™Èdp$€¡³@}íªIÃ>îíş‘‡ÈÎ’Üå?ƒ*}˜=TUPä[è'×k™1™ÜèÏV•@Jº…Tã8”¸PD·^áİÒğ¥i×‹ÅOŠ9çø
«±1é^LN/Qß$_Ï¶Ø"Ë{îvöÎú!Â÷‰îàygæ¦ğ)G½³?iÅSuÕI—©S´B‚,÷4~-`‹~nò)ƒ"FÉ³vxûÒäR~ÒÉÑPĞKæNÅMÔu€qîøW`„ÅgÍvËú°â=¦–¬um¸­×!©ıä’ô²uFNi1Ü¾Oôâ\ê¨Æ×-ÁÂæy«ê6ÓÎôkn‚‡¡KÁlëR˜ßŒ¾çz,Ìğ#Åè]f‰í`lƒàLtvNÚ4g†ş«¥@"ò×+\ØÊ¿2¶"áY"²åà¯\º“Uı»8Ön†ìÏ2es×¬‘;~ëùnâ£‰­3^ªÔá\àª0Ş‚BÿDÛ¶‚Æ¹2då%pvğÍY°6nD?áæøQ(Í±[†SĞ7¢ùŸê£½»=}İŒ¯îqÎZÛ„&Ôœ<°¢ 5QÃ×Ã#ì¹ÿO*<ş·¾Ju›[Ÿ¬BÅ&÷µäÙ‡áw,Ëçf6ÓæÈé´ã†¨f…¨¢–9ëóXaÇ_µöP¸`4ëÓàƒ§…3‚6Ïëå¬HMJåT/@ĞÊS)„@R×Ê.VL`h²˜sÎ’ˆ­8¤„vÈ˜$¶zÏ~Cm—r:“S—Ï(||³•w\Tñ‹q5’ë¯¦_÷Y4,²Ó­§º) 4÷Š5æñjÄY  óÎ>Oüß¬`F6W9³È:ñ—È†VÓWc©ë7¾;}l™ÉTäØãÔw ³D1©„[ç-‰TLy+rßÄŞ¡GR^ˆ7²¤xª×ÊºÅÈğvÊ¾8N8¤ó©5iOàIˆc&k"±ÆUŒ}$ƒ.Ù·Ó@÷8œX?9­òty’Ÿh+^5À¯©`&8£“—]ğñğÀê{¯çƒTÀˆŞéF'¡¿ê3Ã™Õ”¹¯"$í¨ûğñÃ’gÀ<Z§(ú1ì¾1Ñ$)¢8ÏÛÁ0Ëb%œEÌ»@4sYáäÌ7¼Ë`Ä»gğm÷ñì® É.Á¨;h,]û»8WÒEKåYÒÙ–)ôÜ3Ú‚]Ü¼<·2â­_Ã´	a"¥‡ÛÉP¯v9ŠšäDØ¾LoÖ²ÛR?Aß`R¸zxV©%¢Pp+÷Ü¸Pr?-å¢eµÇÇvK_²‰G©¥q£ùÈ»)¿Ö„Œè›úxÑqk4îêé&Ä4›'¹î±‘›Ç¹¯_Òî8¹§0#îÍã¨OKîÏü˜Nìñ¤€ï1îGmı¾í¿Vâ<7Šíß¯'Y©p$€dÎ€Ög³¯ÌdñÔ@ÂìC­íÔëÌN¹˜—°sè¡ß&=]$rCs}ñËxbu™úq6ešÙœñÊÛzè]4ªM~Võ=½%Œ¸œâKANrp÷l¢SB±§jÄ/§òß·üĞ©o:I¯,¯°·í<ÌáÎ¢¦Ó	7ò
«nïu5z©uÅƒc×)ã•ñgªs^“šæŸû˜s[nÒ¥nø-&«ïüİ¦ù?´œ˜PEŞ+µHÅR¢QDi£Ë/„B+Şv’ùùŸbm!Ú0¸.şíÍ{û;?ÙÒ}RÿI‹¡2cEUCy Üu§”¹gH˜9ä}ƒ&°@s°-ïºïÇÄ Q³¦×pÁÏíz»lüR[K=sGğ´ËúëøşÒ¨˜Lp„&Å¿¤œf§V3<¶oiƒÜ(ôÀùÑâQ+–ÂŠ„ÌËş¼úñ-C©~íñLåGF6?è±õÓãq‡Aæ‹L‚•éW×úF¦Œ°.ú;{¹ò7g P,0¦ô„Ú—ìÑº˜¤oÆ7Ë v¶¢›©Ù 8-w9¡ â¬&WG:*Ô¶ “HC½
€Ş(£”­o+P´€‡uò½Q…È”Â—ïÓÒİœuI)åÇ¿¤½‰*@êÍõ ×‰ì‹„cp×Ü¨H¿ŒCO¨¼È¬ÓŸpgÔ—£·	Pv¡Ë eÑ™ÇÀª1	'Áx#*T.÷ÉŒa Ù¹2›ù´£s$†œÇÌlN	®}‡Ã¡FŒmi3c¯…ÀF3ùyXJÜÊÖéÖ.Éùª•VØlUc8‡óuÓh´5œ6§c•½rº]İoPQTİæÚ½0Ø”Ùş¸âËÒËìD˜-/£=6£ıĞ™g	åóê€D–k*ìñò;ş¦«Ìµ{¥cåL±J-YrÜ´`¤“Z½ªu¢ë1jrxÓc‚@'O4_şt¼C]ŞÂ–é£ëbÉF@ïª9åê>…8ãá|”/S(‚ÉÍä¦jbg[³$uˆnÚÎ;Öş»K'¹Û^<¢Rx•Êå‹C"ÈØP6kÑüÇğD5yS@PûÆ9M‡U[Cù…{ñš‹“Û‡K/q]*ÓÉ%Ô[-è,ø:ËwÖ€1k¬äÖÎa×Şnô7¼µW#]ZKÿhò2÷AáİøÓ*`©?VG;T»+%v‰Üá”GxD°Î6/Ö!å-Yú¯õë€kÕOA	í²Ê4;f€ı‰mé £wœŒáÓóu8w©šAßGã¡ğ1l¸g¬Î¡ÚŞxğıùSdnaÈöÁè’\[ÊÁAé²ÔßÉçªRö,x¦ë«âuÇBüÕç%ƒÑ±…øJÛ¬º¶?æé£^b‚1‹MÓ¼†AÈ“K‹l%ïX'z4˜õ½G®ˆß–¯+ä|š8İÇ'àå`êŒˆßFnG	(4ôœgÃ°QÜdä…ËRÍ¬¶ÑÅx1>Yv±šÌİ¤48b"¨Ç›´WóÂî˜‹r$§íJ[$sÂj¨YˆÕE8ù„MX!§ŞOÎ€}YÅ]¯ÔL)éz!ÇxÒ¢Õai¹€?Fùn"}ùk»Šğ-4“y¨Ú]ËúŒ¼0ƒ[¹Ø¡R¡ƒ©j`dÑMn3^ßã«<ªÚQº;¾M¬£Ey{$÷iƒÂ>ŞÛ´Ÿ¼-åü·Û>1R^ái¼¯ağ/ŒG)§8µŸÃÏs+Ï]œY¬U>­ğTh_õsGvPnåÍ°“»«Aj³›ß±SÊREµ@k Qào wÿD©ğeàñæ¯yuŞ¥Ÿ$€}²©ê¹œ}Ÿ+Lk¯ã!’‹¦œæ5ü”Ì…	yç‘cÈ¤Ânƒ†ñTq-<L.bØ®‹p2 ÅïH kµˆµa±ƒD\àÁËUürWp5rÜ{¤‰6…O„œo±‘KlVÕpœÆÃ'±ÜÚ#¶Ü<­«ã.Èş)	…«18²³¯c3Œ²Å½ˆOØ£&$l(e_+Ş éqŸ§sËU|’6C½À¼®İ«ŞM·›¢w²¥5Z­²´>…p©{v£ÓâÁ½ß=à5m5Öi“İ¡H/ÎíEäh4üê¬¥ÛYg*®¶Q&©–êQÖädù'±e¡‡¡#ä ¢Y(iXr/°\Ñ •\î‡lUı*5¼¹İÒİÏ>såAü€×ÿx‚çÜ &²X@||#H´	ƒÖc#æ¾æ¿g²ü(‚[IïRa÷T«¸V€Y‰º§üq—f‰JëÍ½‹­ªÜ™†¬Õ2Cãie·rŒÜŞˆOTÓÏâ?ö€¹ÙL Î“¸g•n9÷«m¸yS€™Ü¥É–@ §<Á0‡/Ùœß¨ËÈŠfÜ¡8UJ=ã3Á19CÊ6TXkÚ!ŞG%†ÅPi*·ó.°®Ã®Ï+Ñ§OÍ—óDIàk`LÀ`$M‰B°Í¥ÜÑCŠ«FCùœò¥ˆ.s¯¬6ÉpÙ‡ônx ØH%û+iæ>†Çá[z@¦†
8kY¤ô©™cşóKP§'¶‡$˜9èóL9uTÒo ¬Aø˜BìĞl{NÙõ‚;Õí•9TÿW¥uïköª:ümœW¹î(ñv¬Áıº
®c×Fµ^’V·²ÉØ`ƒX€²!™-Tò†Ä…¢:îÑ÷ú÷[±sìêØ’à £îGÿ1Â"1/}²g¹Ñ–{şíÌÍ›‘ò›·€•öÏ×K_~ÖÊVË|…^„{Ç\#B|v)N'Qèxçß×èø¼'›…ÑBl7 s˜iYŠÎÉLb¥Ùé’øk 0IŒşp´ïz„RÅ¢ÌÇ‰'ßb P”Ùªİ‰Ë%+ÉúnÉë%·ò9»¿—UBNÌ”ÿP·Á2°¾}‹üÊK;Ÿ	à•é½ÉvÊĞ˜98hÌ$âaÀİ„ë†[8N©ŠŒ‡ÔÊÌ7‘ğÏmË³k/İ³UZ†ÉPÓOGid´U‹õi9»É'®™ïtœ[Ê~ÎVz—µ6˜”ú¦|ğ@”µì€?¥»Åû & *á*1S	¼÷ı¾Eš,[ö-ÆU‚m`ä#¡*¨yo-Ôµ&äy"ınÒh\<´®[{Çpß`=w¶WOh™^¢ö„’0C¦ ¦¦1@hV*k	ìÅoÔrµë†êæ;İõŒ†fVEÏãM©Pç"5,0÷ˆì§à×(XbówŠñ=VÉÏİ)%İ.ÀI@¢æ;$Çb(*–Á
Í€™ «kƒWef§=—Şyø
	N¼YQÄKfò¬jöĞDî•Æa…‡´Æ«k¸ËÛÈ÷SÊ­«/s0ªŠaÊë·rú¼ò™í“°÷êD ‰R@ÃÜHs'ğ²¦EÔµî'¢ır5÷kpZÂ§vvÊ+83»'&GW–7›*;dê,Ÿ&½umÈìÎıà«qc˜¸° ‰œz_‘b¡!„¥òQFõ3ñ«*ãyˆ–'U÷YşSqQ^Tı§ŒòT„Ğ{Ë›å‡Æ?€ĞÈú3I¬0AüWÄÈÃk<®ç#Övé“7[=1\À&{³ü®J1ºUÈé"75Ÿ«GŸ¿ÔÅö×äezKhlîèKøğtl…8ÈJİ:K‰“ËÆ5Hu6j…Wuºñ§¬Û»!îg¬1,/bZ~ÁÚàDïTÕr”ßW˜ùw`Çø/¨Á°œ<@ïÓ2àÎ“6´g‘( îuûc‡E^™ŠnoÁìk£ë%5+Ğ`änvjÑe¬Êó¸Â›ÑñlZı3H7A¬zˆËßÛ>Ô–èĞpÏ Ÿ?Uÿ|ŒÃ|óÆûîûKM´ìÀÉš'<ÍÖĞÆyG:šÍu-wªøXqíáqŠx\¿†‹9¬ŞÏÙàò[EWŸ×¢t¬×ˆzâDš3­´_{ÒÑ¹0\oB"í¢c|¦Ù¾G;iš	ÅKÜ£æÁ…ø”¿İ'­­`Î´&hù&ãDºü¢ğT¡
p"Ùv# "§ÿ¬·öf4ÚFnk2:„¨é6åò¥ˆ¦M WU;'ığe£«   <0â€0 £È€Jj«£±Ägû    YZ