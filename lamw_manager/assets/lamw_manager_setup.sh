#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2168952115"
MD5="0ea66062ab6049f6d8eca11a551955a8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25512"
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
	echo Date of packaging: Sun Dec 12 10:44:43 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌâÿcg] ¼}•À1Dd]‡Á›PætİDõ"Úâ'ÑÂÓ7¼3É$Örñ)ä°fº‘?zÌÂF> |Ğ˜BK4òô®úúû\Ÿ2G5Óãw™MAx<àµÂJ7$ÍgŒ{©PGzEél‘şªÀéó5,"`LâçÊ…GãÛP§İ]:ãİû]:J—òÏ »Ì6' k1chŞ”å®t	ÿ*Àòt|¥ŸªK“!Ã†2~Së"¿b®2£î}:NÂo„Úñ´Ågâ%ÌaSÔ+1Õˆ€îT^:aäØ×°@m_·<Ü«ıâF³…—48z5À&u8§ùîÁ»†ãÀ> âØÀ…ƒ0_º@‚ 5½HµĞ•ÀùBy„_×4%šü’o17Å‚]y5Îp½¬Öİîàr5B¬l×'¿fV¶Ù³ªserI¦¶2nşüŠ‹7c* Îy›uôÍDDÙ_W<ÜÍ>u*¨J.1ÖÛİÜ8†ö~ãSdvpŠƒx,…ıU×w‡'Á»^¦E¦0ı–U~daş5)-:È5ä¤^R®‰UP†Õ÷+ÛvC°XÛ´F–³ı0œ¨oÏ§­éœ!^ıë~£8 Œ’ 1äûMP ÀQã=¼ÖG„æûÚ1š+Õ÷e‰ı’»$+ü5ê¶
ÃC0{¾ävçn®enğâ«wY{çoW.“¢Q˜V‚—|rùT|¤›,Ù9£F«”jœÌ¨¥^EL’¶Óş+)ã»2ÎXpMµ€2{¥pÅ<©"ByyEø+¨E*?<ö¼ç™¶m=h]Hµ¸×œª ]¬py]qí.ş	·0D,²QÍ¾¢şÛPäş“["úvÒ&j*0Ùıëúœ Eğ>ûĞ:O˜–It,Õe-²òùüÍè[4ØÁ¯|ËÕ2CÕßÿ´¦é2¥Çy`”N£=ÊD³Ş á4İAÈóNûíoÍÿ®€»ÎU}ÃºÃ~©|üp¶¹¤h‰À-B¥D‚ÚååˆkD&Ì˜n¬aCtÛÊÃ)ÿÆû5½xCeK«c„J;l¼«M£‡LV0F’éq¹ñ1î!‹$<ãª•^Ñ—ª^”Úb@}ª[ã©NI³~Vcm…$”<Z¹ò (ÓºÁßÇâcpq°KåxíéyK‰ùÇŠĞ9ùÕ!‹®©TFµ¥ŒF­à7Ä³§@Ya"ZOYf<é±·,İ7 Ôß!0ñt,€U‡tƒv>-@éÉ ÛÑ¾ ²Âô3Õ/„ºĞg_øšŠW–@å~bkÜ2¨¥)u6&0‹üè±­gkpªo ’¾YwÑ3£“8ÁµC9¾–T„ég
á 1„@sIXÂÒÏë»òçÄ]{¸38‰ÌÍékîÃ»Ìg›3:ôü%ÎFâik5U¦¸»zAÕ‚Bb™G"{,ÿú7íÉ€/J”“mÖIà¦WTfŞÚ”Ü:Œğ°ƒIß_¾ªïÉG
•½œ2òUúĞiáäšWˆU'Cj Æ‘`Wê%q‘r‹šI)«ÄÚI›+Iv<Í?EN¬¦r!û’{ªbr[;=Â¾zò©ÈóX…Z¦İ=!°kò]N…àeN}„ ÃÌ[zÎë<’ä^fÅ’—’?J–	ùa9ãR£8¬ÉÂÔâP!jU³2TºdÓÅ®A€4ìëECÖ%°•'YøÇÚ·}ÛBüôĞ•·Æ¸Õe¥h$tĞ!…±²Ì–l BaË‡ì©±ºÌ}èåi ƒNP6Ä³U· ¼çç¨Êòäe½Du	à®%ïäÌƒ-´ïìÈv]­Ñ%a0Z˜+Jk¢twÖ‹@jWd®Ùq‡4M ãP$`E8Ü©MÖu5Uù*êw^2ÒAWÛµ#?~ •[û^|¢”€ÎBĞx£e±8;(ïvQ‡°”ŒĞ•ÙErØÏù!ºdÖæ‚uÆú/©!î'\ş¸ÌÙ†ÔÅa@¾¹ÔÚcÇæ¸ü¾4…Ø1ãÅ!-š%êh•—B^3@e­’ğm@ø½:ø+fÌÑR°ĞCã)nÀwZ=sÖÑffVÜh“Áüæ¥Ÿ4ƒÁ„¤ôºxOT	ïxôš3¶#ÙúhföÚ\§ÌM1v&öÑr|Zšs„T*‘ú¢ĞöÅIKWgfÊRqÍ(pšÇà¯°P&²‹ÜÑEA¾y¢äMœæûa¸ªLËøGàîôƒ¿¼ñBt¯×0æ-ğ&’+–ÛÂJÂDÇUí.L²-A`k6'êp«y]šfWÉRcc>…DÒ©¼°ë7„¾×‘5qS„åŞHO9Å¿Tÿ}­zŠÌ.\ô«™0®q‰æë³OÁ«µ¶Áã£çÓG
N1&4¾¦^×QèÒkÆë]ª˜ñh•&…ZQåšæÊ®pì_IÅµn!¥õø¿ä|±óÈåØÀIÿ${ÈÔÊ·p$r•Y×é&››ÊÒİTˆ±ÎG{b Âz¥âÉS°ê $^w±9zÈÇˆÌÑqO Ûgâğí{#"ªf%¡IPÅW|Ùn
"JÉ.SÑØÿ˜oG'ä4ûòY:ƒİszˆ6DÇKªÎ7Ú]™Ì½}WÒ¦&P‡FÀºb&ôı°ïÈùÆƒ>†éG²²ëšÒ17é¯d§ö’9®üÜH{]¦L½b²&Ø¾?íıkÆÁ
î2\B¸Fg*¤cY^AO•[ƒ0Aó·Ifº|W%6Áışš.Ü_K¾Úù)Öe¥x£nÕöÎ/Bıß)sd´p&6fâÉõ”uïMIl; ¶ŞÊ¶¥WyÖÕù0`†ì¯)."§æ-·;K³±cúaÍ}Ğ7kùWb
\ek¸ÕŞ5ŒınµrX=s@Ëé`—ŞÒ>t¹JçÏ×I	–A‚ràfİ1şWc‡>ÿ‹zÈ^hÇa_ÛxD"Y´à©¸ˆ°ÖNçÒ2Ä[„ƒàg	5‹ÕÃ¨3¥ıîeˆÊ•N½òİDÓö
Óx–Ş£¦}ST`ó¥õÑëe%ÙóÙ?LFêÂ€VÚÅ×õœé[î"Â|9E %'è±½ÕwÍb=çÇ§‘¬UŠvD¢ÏƒsĞÏ‰óãwf¯1…ö0=Ã	s÷ù´ÇxsÖ².¥2v!4v-;2J+ròsµùcï5ü‰İ?‡Íí¬İmÖC¾ŒRÿ&¤˜¡Ùæ=d6²”4F¦C'µhÁnKjl•˜PÒñ}Û?¼ş·cŞˆ*hi"éĞ&MÂ™#J(ÚÜ}h‚ºİ¨Y_£ÍbŒ•TÒ¤±½4ï¶Û*Wú¹oFÆ'§¾øwÍ`,l6*v__7Èé'®`ˆ
¤…¶ç*––€©aªÊÚÉïË+ÓˆùÑ×ş×ß£”¸,ï©"Z+$ú€á¼d$ %sÿ„®\±³¨ „R®šWS×Jo!¥3™¼ˆÄHQÕOÜBÉÙør#§šê¸®ê¾-K™g¤. ÍÄ¾ ÃöBÀ¨FÇQH¥6ï»&#øo%’s`Lu?Ênßş…À%ÿ©ÛëüÃFğVËÆsSXqwm™Zşò51[ÍJ‘>	élÅW«ËÔú‘©V^¼&·+şD^ZŸ
”ìM–X"÷ËÂÁ¡	?dóà³êµøÊW–Oì<fÎsïJt¥ms†Æ¥Ê§³šf÷ùn4¡zHQE˜Lá—ÒnìèØõYWvEĞ?ü‚Ş_%ë	á&ù³½¯b¿ÔjU®ıû&œ­ì…å 6,tÒK–y›ß‰flù9J¾_wÌÂùv²f†oN¬êïys¼Z–öÒÃR· ÃÚe
’(¯û*tB$b«”×£:z;¦©ƒ*‹+âË)ĞA3¶z1÷Ö¬¾;±gû),ÀeÈáHgkQWw £)ÜöƒàĞn&²‰ÈıDıgb¿Ï‡¶G7t'd†Zt%­“CÅÁåÜšÛËŸ»ÄÃ04çñ@QmÇ²”Ôß’áêòv.ƒÂQ†ç@M¦¯Çääu´Íù™–úäfGÒWBÇ¬-0aOú‚bOù/“U…ÄñĞ,¢ æË}“ùGßÈÁÏ`~{y"Ôƒ²7œ2ÿzÇ>ÁÒïÍÑ$ç‰åêØ&¤'9u76{²ÕA=_ĞoÄÑ­1TCÅ­ù4Œ§ÛP6Í¼½÷#A°ö@B•)öLHõNyYóïğ@GÅ†X¨*¡¡V4[ÖDÓ¾Mì	ÍJHUîO=Á©NW@Ş‚ˆŸëô}nøg<½;#Ÿi¶Œ;s9,Ñc(.7L§¢Ç‹)x'öhC%â<²á¢~Š÷×qúh±MÍÔ¸j¦¬Ÿ…>şaHB…©¸#Ó6:,äp«®ki	ÈnXèağSÄö¬.Oı5Ö³dÿ_İò>A©=š)İ’ß¼itÍ±@nİR=ûG=P<·É¶ãT¯–N~»µ£¦(}K­™pXxüJp®Îªn¤:á›h·^d³¹sõV  ââs•gğu,fÜÇpğ-V««c~zB™B¥wyIÁÃ1w›(ù™.ğ‡¾îÎ;Ğ¤ao×%ˆW.Ô IT_4ã·"ğ..@Ûø½M({À¢
üó¨×úJÀ¤Eå¹Ëe`\oËÂ^YÕ!ĞÙÕ^B|^ŒĞ¶èñş˜rw×î¶\û9BX{ÊÛŸÀBÅùb¨v–ñ«
p1#¸=± 
ĞèË³~
:åÂGvY¥ÈMôğN5»ëºİç¢|ƒdÏ(,_Ë±±ïÖ¨WTRÜPø‹J¿ê¾°8RcrŒ2.¤xæÂ% bq K–2,—u˜nÉlà‚ÿHåJpÇM·wO©l-¿W1])}“‚¦ëKÈ<åÌösf^:È©¸€Y:œèÈ¡“Ğ
6®0Œ®q©½ømo¦dØÒQ>lo¤±¹~ÃZÙãTÏØ”-^£NöL2™p¿E*“¨H™çŠ%§ù“õˆJ`Võã	Fı¢j¤üÒöˆãkn £1^g7ƒ”è£İ·›½şZW‚)úZ
ò¿ƒÒÖÔUõjq0}
ç˜¡?iño€*L*Scn8¸d:h™ßhHtI ˜üv„­§~×àÈø8¬ÁjÒ|~Q»2jrÈô5äğĞF‹®_·vì„§ºHíG YwK‡6é=¨N·k¦×ÿ¦‘’ã<D¨ZxÆğddtÑ:8ñiÊ%™!#Ö	+ëÍ mŞj°Ì†oœ§5†¦F/Pwê‘0Ê¹‘ VĞƒ»ÏÆØT]£Ò3«>KqxNÕÑÒ!ö§.Ğ1-ï<€Çl$\Q}ÌŒvçkÍ»ŞØlX­uk@¶?Ì¥L(î®KSì|­7
Vÿ®ê1®–°ÔŒtMŒq %öO¦ËOÜ"oĞâÙwş¯Qb‡ôã’üïôY×£­–ôÈcid¡A¹çfï¢ÎÁ3m°AÖ @4 3ÂøTØÀÍ5¯Tÿ}Go°`ĞİªLZ8Ë'e±ı§ÃMõÄÄ‰å8T×4—]ß:®Ù ønS]æ
|*ê	lÛ‡“-Vıƒ| yºª\¬A^5Ê.¥óÀÆåî±ÕZõ	Íõ¹Ïo}Â‚³ÈM$ åâ Ş¸èy¼Z,º›ñ¥7M<ŠÌ†sIDÏ%öÿºU—°ŞÀ#†Èd]¨!*µÎìç99 ğ¤æñ'“IPóGB¦Ï˜$5Ò|#(¥>u”GÒIŠáü+©,|A×Ñm‡¤ˆËR'2ìjWsœq¦1İ‹ÏØË€úß¦©°6™u;°ÓiŒíÙNe¢Ô%³,Ø_OyèuÒ¡á)LblMA”u0ìî[7ÂıÔ›Ò£TeN>ï!ïğxa~Ïö+æÖÌÅ³QIºJùõöíˆ7^š¸^ôîQ¹OJ4õ˜•ë?b“6«©Ît,ñÙr*Ñ!êŠ´{çUZ¢qÖ¸Yàno}»ÊfÄF<J'Lô3W¾íjˆHD®âë¶«üç(¦nAÒ«¹Ó‘ŠÜ¬ßæmÈN¥0N¨ïv»pØòòxâ¹øß6ØÍüÈ—ÁA¡4ïáx<t—Œv]s6²ıpP({4@´pãî°Õ{ùÙ¢C¦ğ]#­a}Î=û6l·àFTÎÅAé^ö|¶Ä\9•)Àc|¬ ×&-âU¶º‰•DÖï[ÿ¥Ú šnSœ¿}Ó³”ªåÎ£º`D‚“%(ÎòYvæzCws)ä³¼&6’p°íÙâ€êïÌu¯‰’û3	êK‘|"éÜç\®ÌÂú‚I¶…¬ÔMèv=Ï7­y«UdÕútä›.$£òÜó¢rÚ!`e_jNS*°â‘]è…÷ÈÄ{Û³…€	ƒà=­*Qç5Şbhë\fãVP1 {Ïj'ƒl8ºò„Òúqµ¾áÛ¼İ€të|Ò*³  ¡÷€ô­ºİîú;r§ò8åÎw<æË7?´“ª·”ôr,˜Z,äSNšğg4ÉlbîxBî	ºd`ÄñİOèêŠ ‹q:ó b=
«&<á¨3Ã»ó¦2{j·%¢+”âj/Y8À$‘€¾äèìzŒd|o+±WvÕ¼*wc²ˆ3–¾?Ù!NBæ­Æ·T`HhËdhApm ¹nm=›d¡|1ë_Ù.æ„²À¨2H¦Û‰M@¤Ì9œõÇ¦¥(­Š¾É½‚¯Øò ¯Ùu§!Ùâaõœ2˜Øg1^¯?êìh©İ;Ñä JĞJz p¶ÆÍà&FÂ7äß¥ˆ-ã¤9:XTMt¹<äC…Ør	ß)±COmõ{ÔWĞ`IŸè[*}NúUÊÔ¿ÓÀ°²‘ãõÂª,—t½’9—<bV7f€²|Ù‡»=yÎušmÔîL¢;.¼ã©>SĞõºVõd{¦ËŞ4€ë"×å).·ã¿ƒ×-Åa‰^è•5?¶Õüîl»Æ]1é-´òÖ!<ú%VÿèfôCeÀi 4JöUœ
]jûjè Â!µ`¢o9SºO.ıAŒÄfÕÅzµHÛ§)ÔñÄym8œË…ZF›î…–ÓÀ·AÄó˜^DĞ9DıOş{ÅŠ•’ÌÎu¡üĞå¢=á”&P·Û»+µ={iõÓqÂ3£t:‘M Y%¥GeÁ¿§x”<ƒ¹“¤Oì¡¦³?"i|T¼İŒúdÁ9‡ÊS–=’-öS¢ì'74@DÛã¥³t™)n±W‹2Étë
¥rğİK¼ç~Kf“ØŠÉ"’©;÷f.—@f3›ón_‰œPRúi ËÑ/Ëæ,ö€<ŞàÂ¼¨©B›{‰;]ÿQÌw,'ªØSË§‘F‡‡”xOÌØÀä¶n—‘°ğ%Ó¨ç/9(ËT_ÍÖW–Æ–´sÃŞN(<ÎDŞ:¢ ¢fÒtôˆ’*uˆ²’—òà†§K¾ôzs`‰È×Á/ù^#·6Éa 3UÂ	ö˜c.º™•,áaî7IîS ¹4¹ŠŒ7YÁ‡Zïok©§Á­}Øİe'ô—H£…j2–Ú0ZWtÒÔ©ùS½Õd*ÃF‘Çcp¶±ÉN4@Š+æ'œv¾Ã¼¬#H]¶É¡ŠâYŒsVÈ““L<^…´·Í¶´?m¯1aK–)Rs¢!H’×¦C;Ê:R'—¢lu?x]Ã†Ó9{ÆÅ½¸BŒÈ"ö}JŠgYà:JO"rúÉ¤ ®£;èõôÖ‘&a£ãßQØˆ†^9ËÚÇ»ŸÑåù'®¤&ü¶³É!…í'Ú‹4„m¬Şü`­[’®yØ×»±7fƒ ‰œ‘?Ú#[Ñ›u3µœ]µp“^xW”vá|Øh¶,t“›"Ì‰,Åg¡ÓÊÈ\šˆŸeÕ]ÎZNhuêÕR½7ªƒÙ4Ë»‹hHå,¦_ğ|öì.ù¥ èŞj›fsø¨mş''oˆşæ%€äkÜ¼°…Ö¤°ÏF¦-–(H¨\älC–öú×>L=Ãä[ ZË3)2ÿÆµ±TŒğâV»"µ†®ë• õ‘ õøÄ)ÿÏoãôØ•Àß™)%—%Ì‚ËElu$Ÿ»8ó&Ú©¹¯=šv †M}³ï®Ebu	£0†»ñIµ~ŞB(0†jª´3Ø›±B¤=XZ*	˜iu+)ÙƒÈ·‚Jb	Ü…[ •ç$Ú&IÔªÃÏ^D®µ†_ ,NfKp­|Æ8i7ç5ZºëİÂûôæùÃ­Ãñì1ËàVàÎ\ùaÓNÜmMlñM/eà‹|š>U5.ÉŞ İÜdÅµ2çúpÿäa/ø¿F6spÌtXcÚ‹…˜Q­Àl¿G§	k†2ŠÇÁœÆá‡ò7è<3OºšÒí*¹…å
•Ícó:¡«p¾f?rYr—>RÄPÔ™¦CY˜'Î˜²òà’QÅáÕÕ¦V›à_Î3ñSÌHÆ?]\åË+-Úçr¬Å?ÃjS*Åj2jÕŞSVq@&%|À¯ÿê£–&^×Ó=h*™p½à:İø´„o½GVÏ_-~†4
ÆéoØ_îe{Ş5K ÂÎ1Üú=ˆå[ìöÇHìm½L1é³"¢^øBN«¹´¸ú9§°_¢¦½›¬*öŠEZÔKX Œ3õ‘õúÜ@|Ç(Ô©|!/u1Ëe4±*üFŸ~Aˆúß­‹õö‘Ø«w‚àı[ğs Ád·Z˜ñòÀ•Û­š5Ñóz¾44øQ¬>h[Õšfº=’S3póôÚí¯¶ÃŠÙ‚TsÒyx{W‰l?&D$i4ìèKı9kªêcY$Ñ."À=²†´ïó!FqçLŸ£z¢šÛ	Øy?!q¥O–Ûóv<¸…™1>%Ã¼–¨n˜b¿)ÈÑZØ"¤‚Xò˜$TFˆ[”ëY†òÃZwöD92WßôÒç¼ÙnñÊëy]ŒƒÖ­*  >Êò'ı.2Ï\I}ÈIÈ"_Ú¼
ùmŠü-ñ¦tD®©¨KV1ÒÈ	¸²÷ü{6¿?œ9hŞ”H9Ì¸ZxNÿ8ûğìnNÑağûC·d?=bga<¿¿Ì/yaß¨¨®\"ü†] (Ù¤j…°Œ4Í»¯U«	Í»¹#¢T°(&&ù¿äÃüf½c³ç™Èˆi‡‘mÅ'Å¢Õ¬¡sŸ:&Y€©jŒ(¡‚/Öhr[èº3”öáñì>òÑC·Â{# n‚âqdKcœÄV|{§ãB?kuÀê€ioäD2,q&	ˆÕU‰j
¾ædOÿÙ Â>¬ğº¦~´šÚ:uøÜjHÉÙ»5´††´÷…i¥[.5%btQ;¨Ô»ÏçbÉó=­ìÄC‹b—¤Á%ÆQ88È3 +Ë?Sñ")úcvNNGê¡¬Ü³		lªPH‰±WN§Ğ ¥İZWlr;‚c_hÖûß¯@)nqwÜƒ]Ûqgğ©y…QT»>Ò}ê³pBükµ6~B#ñ^
Å‹¨ÊİMÛyòqy»òrØîÄ1ü  †§ÖËÿ®u%\vàp¡-„”ğä`hÖL‹ûÇ¿ƒÜò)]<Ë {Ô•Ê8¼Ú¸äÇ“iZ£™^¤_œîBunşúcT ÿŠñ×˜)(Ä¯orõH±tØ: oâş·oÿ…ä*Nİ#Dõ°ù¢ÚÉ{éBÁ´ğşÜj—?ôVW#@¬ÁV7hĞ—‹Ig©3QÜÀ&âV*öjÁëYÒÏÍQWnb£Ö|¥±H‚Ğ÷_kæ¢ı…Ez¹p
4s$Å›`úVd¤äÎ3q ş®ü8Ãï†–'”À!Ú3ÅÒ¨û¡m"ğĞ­O—¸a] mçùÁ²2ú¦y“I¨l"XRêâÀÁË–	ˆŸòİ—	ò¹@³9è?Ó]	©'•¨áPòébgrf+å÷1¢ó˜Îô‘4Õ#¼d©ÅàdˆCmh-8µ;	`e]ÚİÒ',¸¦vhìñ…7Å8,Ğ6Ï´”/)#“ĞoÀÌA¸´Xícõ<¦Õsüä­Æâ-pÃ0£,1$nh˜ºè*–d¹Ÿ_ ÷:œ™®4®,E(*qõßò}²N¾I€àkâr¹‹ğ¾Ö…—íXM®$)ïqKHtA}cn¸W&.„‡¨ƒ‘PY6ùñµK}¤ğn¾Ì¼sVé£6+`…›Ú9¢Üâ^ø³TT¦Œ !BeÕŠè~˜ÂBëda¸úìuæ‹±Ç|Ä,Ì ƒÚÉ»`/p(ÿ”LË!Fæj,Ø/
Bq3`P‡åàyÈ¥$
n3é ê>ñp‰Ülş)0}	*täÀN™(y#òF«tÑ8'Jœ§iëˆ“6]-ô?sâ^ê­VŸõkk÷¯E¶#Ù÷f©NG-ÉÃqpëµã¾có·¢ 4‘üÄ…<V1#˜\i:&îuúì»J'˜Ûòú\¬Î!/ÛŠßãgë{İuUrÜL"¶KÑÂÄêïOruÿ¦]TmIxeF:Í°oÓg	·í÷r³ÛÄH*N°ş1ßÉ&½qdâ¬á–ai7 /ÁK–´³øı¯‘ÀçìÛ=(]<išzP"Ã|%ŠÜ÷¶=M|ø±xò?§Ö"kA±³¤İºË$iH‚İ€%x²ì¡¯,Î^¨$ãO?½ÌÖìËçÖÑ·‡´ö8kgÂV&i´V<Û~ /KÓq„kQCïo¸!ø¾V°ş˜>b‘M¬@‰kMşíØ#˜CôÉĞÉ«cä7.Î&yãĞİİ1ê€g”ì•·u'Í/«Â§†±Z×ê.Ùdm¾İşÂ)›%$É*¢k=ä&†˜ï‰sšD!öü\¿‘ø{hÃ/ôkF-jövÕú§®´¶Ùİ™a6ÁsOÍÃNH&‘Ã{˜¢ªq‘(TÅ~Z‚úø¿y
 ®K‘d…²õú³°´¢èM‡:Ÿ?%­`+^Ñ–“¾òóy:ÿŞO‹æ›öX;€¸Od£Ïw¿ÊjgšÑ~ç‚'
 a~µ7>ş¯Aà­¥`¢\®€ÕıiuUá5Ö`û¦9Î0-“_×bÃ¸^Â\œ%…‰AºÀİ†ÙjÜïDI3ÃÁbl™İ‹ø”`ãm§Âö+|.Œ0¹¾İÑ7·V ãĞhÛHe€AüuÇŸ^A( ùkâ”§%€ui-§@Ígeæ]k‘G4ªÃÙ¿R?°*é´	‘‰ú ·ŒHÊ*³ù]&Ñv1r:u[tšaJ(ãƒ'|OˆØo«Ş'V=5u˜`1†à1´ô
`× ë£IÒ5¥èpKe,–C?ÆX¸¥
íû»…0´Ú:¨	‰îÙ”†‹>µqH©©ß=w‹ËWSÇ÷#ÛÙø£ÔÕË¬İ–v9ÉÆd!Eíq]+1p¨´%&”cãĞñŞéìÁÒ£‚t¾Rñ|Ğfq*^™BEĞr/J=c±ùŠiWÓ[M{bE<8~§”?wç{×Ç¥ êÆ"‹ù{Á2¿’X6ä®âœÇ?/Aù|kÏ^'áÀÔäÇ”ØRj²1wYpâÎ ØÌaËpäâqæ–q¤OGå¸6›ç»‡ßÍ—À~ö¤ßæùt+3Â×ıÍÏgo>÷¢NñØ…Ì_¬C>• Øô‰‚Øg×rÇT³B€<zÀ_†vğ—	+%Vš½òvÜkwŞ’@şcÕO£ÓaóŒ[.y€%ŞÙøô¿¾;ús<¯“u=ŸzœT¨ø„Û-yĞ3š˜ïE^v­6?ÎÖLÜ’z),[Ê#%|Í•7ö|qû~Ş ©+ÄÌ
Á–íÍÃ
Ü½xĞø‰ı,S=Dğ=2j2¾ùf›dä½à½+ŞÛ"·œ†a"ä´1À^‹©cÕjÉn©ºÅä1S07Ô;­5>qœfk´Òìjß†(ƒ˜+Şcéñö Ñ4Mƒu¥xsŠµ¢/FIté4®òSdõ ×'9W\ƒÓ´Ø ÁÅ<¢‰8¼eÈg˜áß(è¨9RV	&}Óİ›İ²÷3§ñ7k€İyS™Õ }ó)´Âû)ÂŒwÍ’è#ÜHc-4¥À T“Â¯«İ»ıO·9‹Ê„kHRş
?ÆI?™ˆÜ±ğÚ©ŠT·Î$¿N¦ŒØj§„TÛ~ìNPjD¤Qcª^½•ìõÜì3ÕC!ù^W(ë³{§~_f2EÑYà÷İ!]êUseÒœO‰ªI‹•/^uÙR«{3†µ7ë?ª^7„(˜©À|äaPd6{pv¨<X4®hœÕ	)Íµö î\§Á÷;&1šWHúşkG¥Urn¢22™Üb—¼–Sçá¾ßnLÑšLÙİ³ÂĞåGg¥fÖèlI¾uº-Tzi‰áì>‘Wöç&>â"~¶õpëIj\÷Ä—¬ıne.äaRÿ@o„®±ëì£Æˆ˜6PA™WGGƒ’'vj:-ÿCôT|Ôæ0¦X 52­{ĞslíÖşm"ñÕáO“±”³n9Ÿ5©Q™Â:Eìİ0åI2?h5gĞŸ‚çÆ_X7—ºêıP'¶L¾aOl|ÄE½¿ºp—æoÓ•r‹íï¼şŸs–·âÂÒIìÍÆ'uèwŠ†İ&ŞDrê4Úfê÷‰òñh± B0JÛíÌ^›%^b°“˜e–ª¨%•¼Z`v¶]1ÆGú¨O×S"èhÍKw¡ÒácÌF<,Æ?XV8²„¬ëgÈÚ§‡+³~=”¥dj‡-ÿô]wÅË/'¢"{Å7ñDVÖ)ò£Ñùİ€İşï<+ŸpÍ¬IaMÅéHëQÇk
òy(UU•¹‰±Aå2L<”5l£é’û$ã£½ 3f\`ıpÿËr¤PZµ	ò„rğ¶Ñ!|~K2€íKgÂs¥½ĞÈ"òÊ}I*wlQÈËö‹p"–I¯Ÿ°ƒ`Í€Ê#â°ÙÏøÄL×Dïo”ÀÃÎ[şGÂ–ÖnÙcÀëO»„‹Ms+§FN¿¨ß.ïh\DËÙ3Ï*Áü²â¥øıygzQNïG8Ë±ºES¾º×ßÔ¢™P>ƒ´ –ïfóˆÌlµº*cuì¾û¼`H'ĞRñ$I
wğ¬n(€Ê#óÇ
â²ñù¼?ëœ€„@™ä–"óKToãe{’Îu§HñÁDùJ3H¼ó9vcúCE$wÌAn|@c³†~T((é/<Œ“!z›qİNÍRn2§ŠVÚoIftTİÉš²ñĞKª(şï3Å"ºJCˆ™¬_nrZ‚¡Ñ®3ÀlMÁæRÿs•°Epš–C¦=Ñ¨*ËÊ‡jW>çñ‘º˜ø¯¥„u·(İù·]˜\1µõàÀB1+^N\ w#3%‚·N9êõá)FìØĞÛìDRÁÁ¶4ëÎs{ú3i ·¦~£ûşçA­¼˜˜&¹Ò’  Û«-s¹)á^ˆ «êQ!ºV¶“úkÿNJŸ ntŞXD»^FÀÁP¾â¦BÔõóò&Ø˜/ÎO4…=ÂX3ˆ"ãÈíB(ø¨ùZŠoPwïX„Õ:s2µÑhÎÅ›HH?ÁÓÒÚ®¨ÛNïˆ@òÔ\d…ƒm¿úwe}t<Ä}QàÖš±NšO‚Jê:ÎË\M"­£rÖa£&…L.t6ëšÒ2£Ÿ±EáİÆ`ÙŠF_oÁDeĞİïhÍ€4ÜúW!÷}b¡V1¾ë!z²g`ÔXô6aVã“ô'(–Ât/L€GB÷¯V’×å-DFdPz*ğ6Õ¬1xÏ?(—¥ñÚL]Š®ÁF-*+>Ä5`×p9Æ~úÀ’rK?I|ûçÃq%#…R»wo<wIã­zàÃw+ZDHH²k©‹hÃS-›'K«£Uù‰âTÔHØ›~‰öÛ:’­àßQ»ë.ó1ëÄx!Ûê,¤*”²ûH@bì…¢\Ÿ.ûÏ6t²OAûù–ÀÑòG"TÃeq)uñjµhNI×)yÎ%ÿò{ŒtLÑ•ˆÆ…“DKeÙô.MÿİĞêX€îáZè.“0¹ïwŒrÆoÒá™ë™Ûò½l1Â»1CÄÜuö•Ù´›}vØ¶Q&BÌ€ÜÓ§@4KYÖ$Ğæru<2°ƒ]ìg;õ©u“;àre¼¥ä”Ry·»5ûy^Öğ¬:æB³Úgn?ÛÈVÂ¨ªÛÆ8o”NÀ8)È:ÃMã^¹ïóUkœ·¾/ÁEã”û»²fî²¾Bğ—U%£ŒAu²â mÑÌ?~ŞS/Æ©Ê”ùõÉ·?_Aê¤Ã~­›^¨`vYw€n^äCSÊÜ¦~‘´óD1¨²ú|2º‡Ej8/95¿ÜxVùĞÇˆòüßsÈÁÖhHÑ%ãÃ÷ Ãô*ìpşŠ÷(¤Oâ:,“ılB,æõÈÈç-Ù†wÅÀ¦Ä¶éD$ˆ$º¹
;ämSŞ„¹
<Í»)5‹ÍÊt€hİÀLû‚İvÆŒş 48+Prºc*•)ã×Ñfw)õË[:LüŒu·•Î{¬<;i@CˆYè)»#0ÌÇ­üs}†Â>M© µç¹µ¤ &8˜)>ùÑ‰R‰ÎÅOİx>€%J/‡PRD239e»†8LZøÍÀ00¸ÓG&íiâ:ÿÍÈ¹¨Ş,üîŒ—ÖL.’µÑRòD¾»Ñz“'qT<R<ÃŞ·¾9ÕÙé]
´#ÓĞÛöã#ªj4¨i¡}1[’ ·Y÷›ã'YM)aQÚ*À¡)$I”ÄcôØFÛi
»Û„ú6ã9x[²æ€{¥¶¡¢ˆZ>ñÈ4¿‚œÎô*-
ùŒ×‹Bwğ~å»‚ÿf%á¾uÙ…¨2PÑÆÑáz¢‡xšüdÏkò­ğœü6(ú™º3wgıHöIä~±\¬ø®ÛÕá3D}ÚtÛ¦ñÉö¨eÈÇµHt‹4`\ô–H÷»bïüÓZÑÅşj91¼¤Eº*#ì×wxùot	3jğ¾û·npG¾‘¯¤SzĞ¿êÎñü~À¨	.~®ôÏ×õ‰´İ&D+¢¤l·ºÇ8=Ş%Ä:ÿ†å¥Çğ
kĞ²Û.“˜Rî¤Gèøƒ®MzÓ·ƒoeÎLÁ$eCH,ÖÎ;Ç¥½¶©m>DÉ¼³€Ù#Ú}‘÷Mß[OÒQ0ô†»ŠZtmÒ)Ôí„uú¥4›ÎO°”×˜¢V4‡‰Ã=æ,gnw:ªÖ£ío»¹Õë³ßfAÖÄ÷e¢¼7äšh¸L¦î˜xB¯caØÙB±â3Éz&ZªkçHş²ÇIÔ6kÓXÍâM´S	h·]¤zÜ#Ó)xåXª~©üã	7Tû¡†½÷/CšÑ¯½J~`A¢ÅK"‰°€H%¾/F‚©ãÜ‡;šË…(è¿qöie´ŞÍGÑcìz¹¸#Z`,	L+’|ÏÆÂ1ÌùäéP¿“Nmv\÷U¹óo¡Ít?ßª²ÙñC¬P"ì,ğ±iˆz•B/îUíÍ—Çİ:=_ú„X5\¸5Z£ß¹.èM˜!ÂM{ÇÓ²?î¨ĞÂJ¼­SC5QlºTA‹¦DêØAEl9*¥vpÇª±óì®GV´uuTí´4úşÖÚò[ s“‹†`Û–
†Çî&9Á–XÚ”D€UX.m´‰HæÆ¤'°ÃÏşÀ=‰õ”ÁZŸÈ 6Hü©2ŒsjÔoÒÏ¹˜¡%1N@jëÚJgğ˜ïŠQ#Ç_.ó¾B,A7Á—ò'7ÍŠY±Xÿ$Rt_pmûÌd‹ö˜¡Cø]Én#¥\¿8ı­Æ< dşïEI|×XD2ãÖ±2“İÍ^…j?æ¼>åÅ82P+vÎÿ°™EPÅw…œ,zyT…Óf%ä÷‡{Kıkhò~·ÏX´^Ïõîe&PÎÔEı½ãº^áAÃZÛı|Š,/Á~GS.Ó¬’;ß×vıû3çÜà¥pı5”^¢­3_…·Áªä:ÕaÏÉÕØ‚ÖËåÈÙÿ'9<Ù‰rOüŸ¤Wrb³×²şdËgŠ£ÿ&—0/2<ñ¤°m{2ß/$;Şò%VwıçìŸÑ ôŸ)G7¯ı×­ëj´X	¾9?ê{9¢rª{¦d$3Ç'5	[«ºs‘½o‘wvr~å§Şõ]òóyÚÉ°¢ŞìÎÛ¥…ä%b‡@ÔãúIğóJºÏõ‚oüÀü£ømnó ğâÍ5¥eU­›† WE:˜?‹‚z£±²F'Š»b“4"Uæ#%9›åÔÏˆ·‡x¼6à¾Øş#e"B5ğ\ˆ˜½H€QÔÂÈ„Ó›W¤iÜÛÚŠ¢knzãúfÔ@ÑXwNE×+`ˆQk8æVK$Ë7†ÀI	Gá¿G‡‘ –ÚHŸhtt×¾ÎœÉB+Fîk´ÀË]1p–Ö¬}å•&=Œ)$±RÓTrcd?YJZl…"“{‘q¿Œ[‹Øı?›Ò÷¡¨.TÀúRâğãËqŒõ5	³LÂó0è+¢=Ï¬u	)B·"†Uë†`Î¾‡:Øˆ_f¹Øhkkmî÷ê»oˆ@ K˜`³©}Ø…Lôsû•^ÜÇ”[änõã‚]ñ;õ"Ë‰Ğ³¾zwBÕË'İìÃ9×Á²î `×W­ëT…Gæ™Bîàí”vˆSäpAÔ‡têå*1|®‘‡ü?/‡ˆ÷™UñöMHó$ñûä›»‘EiÚI“Ñ¿j“ş'm!àÖ£(¯,|ø²{6†ˆùr=ˆ^ô~eà¦e_ÔØ¨6¯ôÔ!·,)d°8Ã :è`f›"ä€û'»Õ§òFUJd}~Ê¬Id˜±Y€/óÖYçôØs3i“)QD6l«¢[×%¿¡V¼˜	ãWä*=÷I.¡T7“‘ÜfOA/8G~.Şë¸‚‚ë‡ë&¡vŒ1Z†	Ç¹İNÊc	ğÇJil@¯ÉËQÓ²7àÆ]’[+¸&fü?à{† Æ•qÈGÚ›Ş#ô¢ÒúÊgÇv¥ò<³ÜÀcùpP’cs |ŒLp½ÏiïÛ°…!R½ŠJì@`Œj„\âÅÇx¹„ø“Ö®ËÁîŞÂRùôÒCu¹nÚEÉèò°ÑŸ8U5¤Cø¡`ƒÛ7Èò7@Y¿@j×_8Ñ ×¾·çA0yamÀÃ¡bOc(^š»nµ‘¾™£ıŸçOR0üå9‰Âe;SÎK3âgòcoÛAH€æ-ªòcÔDr4Æ„¾Ú¯v(¬¤ê,©sM>!à•Â<æ>¥ş{x‘Cq¢JŒŸÚÅÂhN¸îÿÍ	txu6//£(Z|zcZ¥¶ËW(›üş’SÈµ ÅKLœŒ“Şx<¼Şk0èU¼ƒÌ°n.“‹õÚé†ÕÒ‰
–Å5wµSÓû VÉŞ’²:ÏºcÔX¯Õy•>*İ•¢2FÏLVdíÛö\õZ¸’û"	¿ Vz Ë._­xÿÚXè÷bMàƒ…ä¬ŞÚ´Tjl8˜.Á¤;›@qÿÀÂå÷°´4Èm->ÿ*6,»ÈÇ|ı‚ƒİÀdªL„.rÕÒÖŠjË8æ•2{$)É‘£Û¢ª\g¼Â7éî¡ë†a2™iÖ·åŠQ5Ò,/®96B€xMa*Ò˜p},=Ï¾fÍ;±˜’©,'¡ÖÍÏ'ô‡‡ˆ?
Õ˜»û¨Ö•ãè¢Ğhy‘·éƒBÃ\»×ËïF,_F­ã"U˜"´Çe›J£ËuMÅÍ$DyiÛ¹ËdÓŠM7ëk®ÇkïØ`Sm0mÇB°*ämí
gò%?a//`|Ó•\Zß;xj¤îYÇLáfŞÔ¶ã;mêíÈ
Œ9d¥§î	nƒ¶lk¸ÙÑó%³ ·…Oc¬Ø”}IÕÇYXïƒ.~Wˆ°&Ï˜Æ*?š(ÎĞ ü·Õ$!lÒR:†Ø¨eY
EÔîgŠË…­„#õÒn‘ÌE'“@>â±ô…êµyå¤ÌéœS™÷š†QL^ZêEïØ›-ÿy¨éµ=!ÁxkB‰µ·Ñ«™ş±ÿK~nVäÖäÔh\>•øó÷OµhŒ9|¸dt«¨g+Pİ×îşq«Ê!ì‹Ö:)¢AÈúÛ]í_10ÈŒÇ].¯©à¬”f*Ñ6P;t,¾N‹ª\EŠ¿Š2œë QÊùÛé†)&]ºÓbLºÚñº€³„¶;«Ùğ2Å½Â‹ˆÕ¼’ÕR·E_º‰vñ4ôßƒ­:°‘//ôX/ÜúÀÎş»E0*_
Î¶¯Éº_ğ³€;em?´Ğ¾YKË!õ¥°×¾^ÛôReïx3*4\á­GÇÂî3*¬ùL´¹âlÆ¨ìíKàî¸rÆnI9‡Í~ód‚ªîF¤…ã’¶Ë9 a^A ¼æM%¡9~8bíìA¸šb‚`z•ìÅN¥JUÈˆÍùïI-‡úb’ÁÇNVù#`è˜›Šš2$¸:ò“zGÉ::Á^¨®ù‚ƒ9lÅm2‘»O¥ü¦5õ½‘hÑ.7.nqZæÁ”-UŠ&TÏşˆ	ŸÒ+‚(ñ¿a'ç…'=grj0›*Ô¿TÀ;¬ü@uc¾ú¾^¶_Ît[†²j°ß\óCÛ`lª¦XÙ4ÑPÅ+ kİ¿XˆS©€Ì Ú¬ô[©dÖµïn¦:‡ÉÛÿ—åá¥,Ÿ9:İäè$Éş³N
3œŒ¶õd¬3ˆfzÍFlßéişı7ó/±Åƒ±QËF¶&êa;‚>?¢.ş&­èİ$äëùÉ¬®‰W-©Úbá °Õ}€OZHOd5-2;UÉH#J„°33İö0ÚG”Pş•ç€9MzdfÊ‹V ymÄsŸ° âT>)öÕÅÓ” ƒ»YÊ>2%½~ƒ¿­ğ„Öb„Dÿ2ã½AÔß¡Ím~å?D~c©F®Eîù*™XúŒÇ½(¡-¢šR2”}KÏûUNY(Ü÷_Ó‡5B"ü=o(`å6¸ØÚ«¤3$¸IíN°…1{bº±v`íe‡’*s‚<HæJ”÷#<'úïMĞŠ öZ©Qã-s+££âùk:Q‡ì¶÷ÅÆ5W˜,ñÒcÆpE¢Ë“ã1RIxœ"°£‚¿± º×–7¼ŒÛZç‰>ø*ö)ıŒºŸAà"£=Ä˜e“à¼t‹ñfmyáfÄ‚ø#˜n¹8èÍæ»8½‰à“°‹ÍT¿Òæ]ô­‚f'„‚às]ÛÊO¡•˜Ê¬U*ç9Oö"àŞL°€t?†|~‰wp‚%“/£efîw&–ccµ7RWº©ğ:nPö4ä­”
4v,V™ÈIúU)~ùc‘·EÖœp¾³İ|sG7£¹Ü½\>9„«ÔIy?üoÛ’k{a_FA—!}H’í'£×øƒÅÃo¸û b’©&ñ–g—wş¦¾ÎöŞ›£%Ó9CFÁNR¸÷*EÑÈ˜m<S ÆgSËµ•gÒû²0pÁeOë~>ò=–È?ôSbßâ›ü&†ëQÊV—òih£ø×†5On®ş3xG¤(]õòOn;4ëIê~}Ş~ÓÎû:¡÷w]¹£¥v-Ü*†z}1÷#*aÜ)Ñ*(J'TJtõ')D£È!ÿáy(%œQ—ã$Š'hjWÀc|Ã˜å]z ­pó1…iÚ@ìtZ¼ôöøšÄNn2ÛSmdzl…cY×Xû»·‚Ài`ˆÿb%>·½SúÊ2~Ïì–5³ÆIÙ|u—5.JH9¶uïì€Q·Ü\>­'‚N8Úè[9õA:DD’«tí?Çœèƒ#şL"ÍH	]öB:“Ãœ:î$Ÿæ"Â?š†õ´Oëù÷â|ş² Û¹"t©c	õLjgÚÑ¤©[/©8tù	Â0vøÌSÉÏ@¸“Ôk®:*
©[ˆşBg0®ä(‡£úy$„aË›šbNtiDË¡y–ã3ÿcª86Í‚âu£R+92Òï·"ÊbV‘aª}Q%ß÷×±ZéAàaß×ÖPí¿fN'dëGJçÖì÷j‡Ö¢O.Exˆ˜ÁY&-ôÁ¯!zkGÛ×ğõñÜ3HÖƒ†ì%¹Ê@¼vl”ÒeHy2ßSõÒñÑEİªG±~@è‹°Ìëñ4kèd%´:w
^
U}U»ÍXs0|£¸ŞY~@6Œ³Í–†é¾DM?2ák«y*È
W¨&ÙE@Yy~QçªmŠ¬ { †øˆÛXï¯Ìº:æeO>XñÇMˆ7Ê baôVÃ›¾ NxâøäEã£‡îç£Tÿ®·¼ÇÊa5:Ï˜¥ä•ˆûjpò-]£º`÷\B;Àq@·Ñ¤…v3 ºì`´»é»¦vò ıiÇ^.!yOÜÑ?ÜƒÂ1lND:>šd ¨ø5ÃùNS•®9ZF·¼ŠíõA’COÿW"Æ±{×¯;O¦,›v<oÕ‹Erm/Åç·$¼†G&èçµ„/Ğ`NêÕ¾ıãG:CwùUà½{8¼V #†âmØ0«g5júV“—úÔ9c¨§Şs‚³©iSè“£[±oß•Æ/vİ—İÂëósbËîŸ`’i$¬ß¶¶ÜbHAª!¾]ª0ah©Ô8˜õuÁ9â‚nÈ%ù×“Ä œ™OúJòZÎidà°‡ÛC¢¶M^w	²’@À<Ë*ãÛüaĞ+hHS×}%Y5oAâï^÷aË2ú}ApÍÛ2ãAfSÒoR•‹èˆâ ĞdÂ6ªÄŒ	3V·ÀÜnY¹}o¼SÍ˜a¾¹˜ƒ3^çƒëÈvÍ&?®Msä(eê%fÏ1@'?Înep¤à:IĞ‡;ìDãGÓ‚§¾V¹]tˆèŒ¬å¨€‰=°òÎ²èÍúé6àxëß+îßİve€/eÉSÊ®~dÊİQbåó^W¹ad~¾J35üN¾ˆılïĞ÷]†IÔ(rëCÓiW¯gÕQl6^¡ÜYşí±ÈyáÄF¼ó–J¹Ä¥eÂyµ5Kš|ı†éáOîp¢ÉIÁÅep¨ˆµ&ŠíÂiµß¢ZàŠqŒUÿvœgÂb¨ÜÉSáo÷®"E¤‡?¨xXŒFÎÉåôõ9é¼\–‘›‰O á„>*õ^æ)èœéIØ€²§ÕìÄù¾k©§+ONizPÛa•csmĞ\±D›û€³Cå ` İP©¯/£˜åùª›×sPUÁƒÊ«õ¯M‡õ,SÉ0&•¨YEgJ‚ÖÀ¨À-’ê—s£½ø«çî•ÄJÚYi(Î …6)Ş>GÅ×¶šFËlK–Æ?Ä’sw˜×m•_ÔírLO34ã‰@Œ`Ìå†t$áZ—„¬Öh6§2ÕŒ·:_~/ Şî–YmgüĞ.‡cŞ6`³)WéLæ‘ªşërÍŸ@¿´Wï6åş’E61úÈXô¦¸óŸğ-üÇò¥¼Xuàë±Ó3ˆ?÷ÉóNïò–HŒ ß¾ã‘õSjì2œĞx!>uºÈ”ã>…Ä“°ZzÏÉ(BNjÿ6„Ñÿ¶‹Ö¸®í$• Í®1ÏzpïÔÒˆ;Æ®t²(YsÚ1ãá¨áÿŞGêí—+@­‰f£Ò(j>m kî¥ÜçùóHp†+OtŒ‹Ó?ÅÏŒ\i(jYK½@­ÁF©mî5ùI—7Ìê¹êlc™ƒÔÆ¤#0c§U¯õêNÙbAIõğ$¯ô{yÜozgò±ôsšÓ{%ùÇS°ZÂ’QzÍL”ô.8ĞYò©…,ızÒ†›àYš[È9G‰nÃ{—gSñ!{-\09½ó“HĞŒ=Ö»a’zıUã%@uNKïÿøzüŸAş#â’&@»ÛîMx€ƒfŠ¢2Kâ}huxÙEî/NØ"àÍë±ÆÜ8s5.–íê´)šz‹§H¹Kåj3±±É{b	Œ> JuôÑ
ïs™ggËåˆè}„ü÷O6ÏÿŠ>û¤iùÃ“·Ä{³}íÊ¸dÁ>Û“îrbà€©ò2o»Ê”“èıXÍÑVØOg˜!a.N;i	¦°‹E²N·ôÂV¹Çu‹kwGš„ùÈ‹‰íØ×ıîö’Ãay&´§°4-—9Y&ó]	Ö`-Ì5TØÿ³¤h1Jº6°#]-Ñ QßÃ”Õ³…>Kß•jÜ<ØÌŞCŒ#¾Î?B%÷)µºPªä—€u|¸ÏEr¦›Q)²Øí×'şVqX"œí˜ß§ƒsñ1·²äãM.”XˆW[*BÏ5œ'5=e³a:qw,0Æw†Gÿyü-ƒ«bøñTÉxí¢uÉò²ÛuÀM
™½=¥×±¤›x=ÜNQÓS¬Dº»°õÿ ?&Ê…}v 2gƒÕ*Çwâ‘µä7Éä‚¬½ıÖIjêM¤Ù: ½jŞİÑº—^9åâv|ógt«£Y1T×Í¢j<áZ8!”;ÊÜl1¶qæ_„`È|å[ªÛVûB²Pkâ¨Û×óUÑOMª«²¬Çß×9®^Ú=»j›©cN*xÇ©ÿ±Q²MŸ9^£,á¼ËÂ´\¿Ó^ŞhÂê¯‰“6l›¾UM]Ç™É2™gô¥…[ÄtÄ=ÊÓû 0¤¤µ?#}¿·UDBEàÏqÙ…à>'õ	™ø>^cM}}í+
m¿")©½á(‹£`‹°Vù¶,ûã¯~$—ïcµ˜æ¡îõhvgPŒÅä$	ï,È›»àú¤DùğFömm’^‡1úRµà-ôâBÉº-ã¬RŞSë¯Øs„Keˆ¥c`®€	,“¥JrŒLĞz_áRÜßvæú­y(ë‡wş0H	B]RÑı•§bc~6ö–±w7*ê4İŞñ¤G¶´ø+ ——Çgág;³Â2œ*İƒ< @sš5:Efúİ–B§äLª­J]j9øP&÷Ö	¦…‰Y„ÅIÏ¬,"İø%WÚ·-C„ıy<ÑcU‹Æ¼FŒÑğÅÊ¸ô<–â*›«¸—íç7µò•O_ùÅÅ0ÃAÒj&CÚã\ó#r¿¹ás‰ 1Ï"3{ÿ a,üÏ7W •§pô™…$Ç÷¼½c"ªW÷‰LŞã¯Äf'Ùµ‚U‹Yµ|7u©ŞŸij¢.ëÍãH›<£AÑ%ºş	¢{L¾²"oÀYqœf_ö#[æìÑ’á†#êYGq;°ı¼ñlÓnÛûoŒ™È:ï4¹’
Ü
'] yÅ—˜Kú‰Ş rÉ*•Ş.Ñ ß*BlP’ù[eDhİ·–é¤=ír¢ğš©jöO+bu:oÁò»3x° ”~Ó0Fà‚ŞóãÉ{U’ª5ÜÇÛ'×ï!µviÆÅ<ÎHE‡%„…O§{F›ş]ˆ°rúœíQÉ°¢OZ8®ÙƒéD#ojj»Q¢¨UÿnÈ‡ì¢Ï2¾’¤Ÿ>€ÄÚ[‘ÊÈTrÂ,©Ò½*•éùó±{¯—(Ïqõh1`±,
»¸’ĞæßÈR?—?I­GÕ"F÷……kbÂA~ó!lÑ½â]cRüØgK¸QÇÎ7¼ŒtÀÖıß~ªuémkéß~¡¡…ÖÎ	¨‘Ó*ÙCêÁéğºŠ1Uè×æë±Ï6k±QúÈYi—º™;ÅákáÏLMõ^{.Å¹å¿Ó~OÕPMcËã[¨ÍÓîßAêS>….÷ÛÿÚşEú!Ï3P{”A¤orİÎO]‰=æ;YÄôó÷ª{)™†G¬ìàµ~R¦us/¤úÜ^{‰Ó§iQ(„Ì»ãîsƒÆ&'¾.Vh÷ñ%B@>9gŸõw%#p6? âkë¨-e÷%1†/_ëdÉ%R ò78&0AÃ&¹¹Ûğ"ÎŒîµ
Ã„Dwc_…8,'‹‚ÿ¼H­Æ5D<&¤G¿Æ9Ëª7¶›gÀãŒ¿	®˜¾¨“ÎÜ¾ÃMÖ~wN[¯¯İÈ,Û›!ŞæKà3ÊŸôÆÑøş-†õé¬îÔıcÀÄ2ø±“È?^4èãV³´>â¿°—Ì;ü"OµØŠ­IÆ¤pãâ·˜«eòd¿Ïmº«Ü—²JI(îé•Ïéh•ª>)µÒ]E 85ûvUÎovc$Eå”ĞŞi€A¦j•¾›Fb’°ĞT¸ºaÔÕÙŞ¨°ï…Çší…JTş»‹á4Ofû•+Lë°¹¸ï">M˜“:0¾tÿ]âGDÎÀÕ‚(ß®ômŞ¡–çfèß§Ãs<ÿbbæ«*†„ƒØ"d<›ky(Y?Ëí]’ËÜ_‰!!äw°]?‚ğÖı	C˜£U‡.íÌIŞ…Éí˜2ã*•¥İØƒYÇDÔªdÿ¾¯#SKÃú£rx™ª‘ÿC_–&&ñş•eÜ<•n›tºÁ*Z›“?…‰Rû+oĞTGïº‹«{È!ù`P#krÜ‡j÷´á ­5ë×˜«vÇ7ÖÃ5ğéRO[	/†ŠÜc&ã–Kd0ğh‹†ÔR8ÖÀœe5îĞÜ~Ã	UàLúÜùŠªÿSç›ıí³÷¤&ÿÀ: 4ŸSÎGÅ¢²³˜¹o~–EŒí_iŒ€™+×¸©‰j¯8ĞcÁÛÊñCõ«DŠİoLè}ñî]¶ÖóÕnĞF
âÃM8I=òİÛ=v;G’èÓ¸R+Eq·çæ`ÆEuæk›^í«µ“pVIÂ˜È…¾a:^§ËÊøVdªñ2aİiJ‡¨±è˜|besé6×û*ßsèØ!?¥ìBDQqt‚¯”L±Íh¤­UoQ‘éáØø¬”™ıT}Ëú¾İ¯Ï4:
8ªÓ[5x:R6[ıÀíæ\Wû‹ƒqU¹ôí—‡ìc©|Kj>pcÙÆ´ÑÂ]¨÷‚ĞŸë’˜~‡‘äóŒë“%•O—šÃÔf_…şùá: ÓCıÃ>dK3œ)¶rª§`nºE)8òC%Ò· dˆÇxäÅ]x¦·¬šó;qZ¶Ë o6ÄIwhg‰tâj&ˆºq²Ñ>ßJk}kñÌÓ‰£(Äá‚‰´Y>=®_İ;#Ãğø†%wVnÜæ€>E¡—\8iÑo77±Rß#±„B¹€¶^ŠQÇ8'·úó-nÖpJş"÷ÀdšL­7Ôˆ&Röu–)~D¶²ƒfƒÉc ƒ‚[ÔómÒ ºn€"&AQ¢áí2p
êYN—¼$#Š°À~ˆ¦fûTqÛ h«ğ·t¼ËÎëE¯œt¬Ô;jqTã²Šq¢¥ºwÒC¶ı!x“aağÚ\ÿÂôh¸†‘ hV£›Yj\‹PÏê—NQç\Y#n!BŸl;á­¯eç¡(P$Ô©wq3±>È.äDæ ŞÏR³ĞóŒA·‰^úì qï Š­²9U©Fâ„T‹IÜï¦l)S9hÃ±QÇ…›o¦z¾iåƒ~nqóÉZÏåÕrrSzû+Qm90·kZ.gˆèÊá=ÇRêŠoû]ìı ¨.pPÀÛt”H›BÿsŸô‰£úÜ›=»ËÍkz&¤„ñ™Û!8
³ DÔoj —GıÙR™€"a×pbŠ0¢3—tp%lÂ ”#ÛÚµ~E®Ò:Ûòi¿•Á”?OØng˜Vcş?B™ƒôûú—9.	ƒ%Ó»´L¡YûPp@îÌ¾ gŞ8 ­>BW¬¤xd6p-jm;SwÊÚ}­¬D ùgcı`	Éeá—¹)ÃËíRSºL¦x÷oŞXhS'«*6q.šf`pÑ—µôëª¼\ä—Ô|TöòChå2RËµªwÏ­ÕÍq )ò	RpÀs á‡µfœÃ³¶ï—$cö³Ki¦hg¾Ï3ÁÒZš÷ÈõÕm%3*Knä’ šĞ"¯|Ñ3J35f=Î¶å“@’A3ÀX„,_ºTNûbåózĞË,hg4õ/¡!>>0ÔÀ~=‰ÒÇš‡p»)ãè“æ8ë•Ìè>Æ0 é>Àê}=·óÔh©p|†Ëä¸7Şn›#H§s×8Åÿ_±_gj/I M©¯y"E«¦+½“cµ%xÂ¥¯Ï@ Š;;ã]ON¢3öiø”0ÏÒ¬Ÿ†ÉÖ;m½§
©>ÂŸ•0=h69+!¶/pòSfµªt„Nrİ>i1ÁĞïAúª ÑÖæI 7¬4‚wzœCI‰é1dÅ[J’•GÚÀ;“—mGGÅ‘¨ôÍ½>˜@© (™Óè5ôn&b¥^©H«’c¦5å†Ù’'²Fè>äã*À_E½•õbxØ—'@~4Rrèòà˜p…¦öÿí¶âíï-Gğ‹ÆÂÂ%m_/–½ŸTzàë¾L-Œ4CcZÆcÜê#
8dªÊƒÂ˜,Î;¢ÏÚİ»~[/‚íS›Ö5õWçÙ³çŸ#íè;	“ˆ‹Ñ7gß£ô4¨-$|ß^ıÏ-c•¤^XLˆh{5°ÀÙœŒÚ£Š½Ã±‰ÿúJ™”èZdÿNvc@s{m3|)B½	#¯[æ1óÿp¦^6ÎÈáó&ÛˆùÍ‚26Â6àõÌ£AWi/GLamût^&ZÛ—ıPÇŸ7E eíâ–í:°vû³».£˜+Ú#6íjeÅÒÙ%iLÍ¸]ğ,>@ƒ ÆÑ9(ĞŒ¦`±¿Ó2DŠØJ8  ç+fu""ø C”c
vlæ¤K³
]`]ã†W»FÑ9 d€îòAmmª[Íé×ƒ-ÌGZˆ~æâfÈ®^p±×õfXmŒø^c®Z, …÷MÍ¶Å‹ºHÔ§˜İûT
¢>F¥B|ÀUìúr4®¬á‹bj€~O„ò“îNìµVûÊœ)é>şfñ›¦Ía€şº:P’ã·Äî¾Š—–HĞÒ$†ï¤‹a>IìCêÓˆõÖèB£/Üe“Ú•ûRÉ {òÄˆJÉ°ÓfŞh©ü¾=c¿•¨›¯\*3B€ó³¬Z(©°«h!ûÊ2h·úR Æß'w5LÕ·úÄÌ¾›$ª³ı±Ş6H%±w¨õ£!7	Çş=O»ê¬õûeáÛ!’µWŠÑd]úıÒ>Ò¢E¨xJY¢‚Ì¾§/øäİÜÍMb€K½°5İï±."ún/P¯ÿœm+$˜úWÊzŸ6)šDšÚÆe7ìc‰:Ég5¯¢³18ƒz–¡¾òj\¬_÷æãñ?Ú²g,y­amè0ƒ	¦¼8²ìş‘tsSğŞÑ%¶‘:ÃiCÓ(˜SY< œnH6cÜXfáº—8‘êé¨YÖ7aËÕ:t9øNQ¶
0èMhÕ5òş†nÌÇé&KJ8ne`Ê'Ø0yqı—ËvËLJuu“©gûê¹y…@SÅì‘Ùi£è¥"«t¦A®eá Ï&L„º½Ø^[¹LîPĞƒÌ	İE²
èJId¯ƒÆ(`Ö³5G60}î6Ç!Ú9ö&Š–‰é—¨*ßYœcÉ05Ä•3;Ñ§fÙE/KÚËÒáÖ¤ÆfGÓ=ä{8Ûö¼®”¡µZOãÃyC%1Ê/`¼Ä3JOçótĞÏ^P—&K”'LapJÂ4xC´[/wOı#ŞÿO??Sš¹üÕo=H§3#»û0@4úÃo$Ÿ—×Àâ hÓˆqêƒMÑ6Á>J4õ; lôÜ/íÊìên°”oÌvbĞ3Å¶¶QvàÆç»’ÿ64ˆíS8’
?°T¯¸èE¹ê»FïZ™Q @o{7<K²ûH¶ù!@äŠÎæ@©l&MöfQûI¾Ğå—ü;O¸E5„ÜyT¾»=0†,¤á|{$£7‹1%Ÿ¾Ä·$pY#G3¼ ê™ĞXßpî—*·’î¬·¶xç²ÌG&Iğ
ŒÃ}Ë·J†ÿ7ÖøÏãÀ'×sÅƒ¥Ìk„|axhœ®®ÌS·ì=ÑJÜmíiƒ|²3]¡#ø­º&ı<>+yl4Ò_lw‡~TÁ“ÿ‰t®»réEÿš`q·vp¥’zIN¡o+ß¾û–ŸEí-Â>”ŸësbC2?¼^]/â­;á”ºævñÈ¤jú]†Šƒ/wH4ùp„!ÿA–{TòwÛ
rß”éo•µ±¡½ÔÇXtUÑÎ>q²	=&‰¬M"©oeÑç‹R'´vÌ›fÂV‡©`µõ#ïß?v±Òª—
ƒ(¾
 a+BYÓÄı#·ˆ~[[QÕ{]½Óæ.Ê(s÷é¶Òdìñ07çé2¹ârÑU#€È`yŠF©IµÕPâ8•e‡}8Øq)qß?›e[’0ghD·pÚ5í	„¢£í)<FÜÈ¥
9$¨¤îU+€A,KÙ$x)eÑ†¿ ¯ÅA•¡o°¨Ú×Vüò´»%5«TµDŸŞËŒ½|)géìt”EÌ1kÄPy»ÛÒzîÇr{­ÍÆ¡V<U¶c+6ë´j?Y+?˜ä1¡j_9[Ya¹èÉt)õËŒ|¬£ˆŞQä_ssâàOï­XÓ½şjéb¦å&Kl¤j²ÓİÖø6NÔav¡‚n †»`*Fç›Å%Àı«iuÉ­dçÍqøaèö/ÿÎ­„…ÕZ°2µN†¯¬ÉaºR „³©¢3!rô²¥*yé€Í·ª§Û5Gìº¶€ØÈº× Wg0À;}Ó8f<„vº£ë²+fö¦¼^q»Ÿ£3ÕòşNúÛ‡ˆ!şaÙõAÊñ»ók÷‘&ª6håe]„•³X¦ÄUŞCB€L?{L­Ãà…õRÚ•ŞˆdÄa‡¢Ğ‹4™ß‚Y)yÅÀğ2ò1ûÁû¸ÜLÃsôø¸Íl­ÁnÏuÏ÷Yûj€®7Q•UÙT¾¤‹x¶\,ezÓû<2ùV  ÀØAıAwk)Fq«Ï.Ï«Yc?:¹ÃF¬­ÆÖ:ß4„‘G¶€ä.wújÖì<×rİŞæÎ›±X©¢{.Õ6ĞÓ#™êLÉEÎ¯
cV=:"gfÌJdíX®ü„i¯£Ë}Oò``ÛÆ)å’Lj<¼$Zwš8³Òı±W»Fàå‡œÛ…Šöaä+5ò%EÍéØâ>%IÇ¯ã†¶ékª\¬U‚ŞŠA³rø¾³¯&'vhâUX	Cš~çD¦
'Õ‘17³D¸À…¢*ğŸ;´/Ûâ«İmm–Í|åŒ‰{6øY<E²ŸÁ©ÕhØúÍn“§%ñáäú,Y„½0‘„ŞÁ?
îBÌ«ªÀ*Ç°só&¥Şš
-3»ß2F°¹©?“'Š7ÙŠÔ±{ M#ídRI‰"k¡IöíA,áH¨¬ÒÏĞõ+—%ğ„ĞF”Ï†¦zxÌ$QY<ï+ÌĞ»H55on²ª€9ÖïzfŸ•>ç=T)ı£#…··h±øÑ¥êé_7ãè‚&3uÈ¸}ÇİBra|7OÖöè·¹·Ò\ÛâVÑÀà0KuR!öLH)W "6Æ¶é„%~0ÈdµÃU
¿šÍÖŠBrChÍŒ“ş	,qvGm{öÁ† ÈG¤+çvVóh| òİ8c ]ä±¾ßÒØ±è†õÙØNëV^Q Î`dªë à”óv¥öH¿¯©p?]É°7mº¾Õú€)…öZŠ{»Ògzº@”r2»¸¿!p¨>sngM›Ñ°*sôoY+úOÓ×<b™úZ*ì4´1'á0Ù1ŞÎ¥~ª¸3HİÉx>c¦=ÀN³@uHúQ”‚ÚåI‡–£"Ï{ÍÖS†J ¼ƒæƒß†óm6‚—(?b	Iv"OaŸÜìlëŸ†øÁgt/	Í2mÄêÿ·7ÌÇ,íÅ{É›<wœ¦®RƒäG¢Ô#ÈÙ#|Òª&oZ˜NAL;~90És^ç—ÌÕÄ®/íÔD}MwH‚Ì5”›yÏ¹—ÉvPŒ#MÌÅÕû<õˆÚRJßÚJ»o»£©Có¼­A=ÓŸšá;UŸ)w1¤Â4›¡œ¾VëFªÏI¾‰L¹A{ø¬½£!XåÒ]©RÂ/)ÚõšüTÉ¶[æU>ˆ—n
õ>™WLAR'³¾‹>ÖòæxÃSKÙ&¢®©có>›ªyfèp+ŞjyÖó¼æ;ëÕë;ã—ük0RÒ«Õ_ç¹¢ 
ıÛöåFéƒœq¨ÿ¦¥gW‚°‰|"í§”ÂD’§ÑµqÑ<Ëbçj}í^„9jì‡†HFÍ:=ŞÆ¢ğ"ñõDıYIEm™uñ½L&&¢FU0ÌwÏX*h–ğ=–'Pl]˜´’+)|{ÿÚŠ$İeãGûaç‰2o½‘¤Õo–ÆÎ½ú$Tqc7klêNƒ±¦JSØ æÔèH¾I¬¹ÔØ	Ï„Lj˜pqÜşl8©3Åß`ƒ¾{áhNÊŠÜ/$™X=’ì~Ÿ .mÇeœÏÂJ;9ÍuÒ|Døszú’:Ø@7ü×¦z®Ê"_ Ö§5åÌ.ç¶¥ìï¤t¶®3¸{ŠfVâÿ(Î,ø5)ªÇº€^²½QX%3oP‹!y„ºı1U†¹dÁÚzY!A¼ÿE„æ‚ºnø|’î „ˆß­a×TÃ€ÃŸ¹4Á²§m<_Wô¼¾¸¤`R9û¥C5õc¶;õş4¥ê'„æÀ‹:Ò`…ÎÖLˆÎ•åZ$vpJæs—ˆm0ƒ—lç:ãé]š,ï^ÔC²’–ñçÃPxëõg&cÅgÂoíøÄ«BnÚ2½xwx]îH¯ÂŞTé´§‘òÒ ÓºpïUE~½1GÿP}œ¾ÜµV¼LÊ‡:wWzD§ÏÙİ¶e Göª?v&¾bË¼™
ÓÕä Ÿóìw5k_–TlEÔ\I_ìocFı§„ÉU@ô8³sÿu“œ!ÚĞœ_·>u³µ±"K²}=Ù‡Ú{Oä˜½È—¬/ÃÊPüúòšñ´ùÈPÀ(À³Ç`KÃCMeáùõ3ø%Šó»šÌ–ª½	jÚú&E2?¹ˆ >—âÈ!íâU›R'e¹bV*‘õ¶f¢&—ùÜjİhi‡ø7r®Ã—áØsÇ¾Ef·Û{ğ¼ó•,¾'¦ğÄŒ¨÷Ş©«Ú=}¿İÚßÖE™f(Vû¶½
FµTv¨æ£­¢x}Ãz³ wg(½4Ëh¡>Æ—!2ñ-ºH­,ç—¯Y>É’‘LÏpìÆ!¡¼V\ıUæÙ:Z¯UÙ œUg$Ú6K¨Ö¯fÂ-ÀE±€f&ùD×MõÄDNr*ÒËa#½i‚^Ø€Ï§®q>èx›ƒ£¢}ÉÕ7-ñ]¾é‰iEúP{Ò‡Ìk¬qoÆş¢÷jZsÇgÖÿ¤8ÌÍ\4ÉW  ¿Ÿ#OŞ ıxpÓod~8gíØÙ‡¦ƒVtÛÈpÙĞ œ¦›åiÖRWä}%üá>qX‰{ ;_Ôa˜ş¥¢Œfönü‘œ]¥¾Ùëââû=Èe?¡JlÏ¼5r(Uüœ¥ä}U¨¡0Ôf2öÀs´G›numƒ¾ ø:)ŒK`ac¶i…ù…Ú/ºg#ZBëL_À,wŒ ›
˜ƒkŞTüö¨¶ù­ñÊtùª¨mšü,}ŞMê5ŸMQQ€;ìGÄ%¼‚ñëÕõ¦c‰g§¿/õŒœì2ĞYcdè—pŸÍ/VP×ïX•/Íuf8fMCO>øpG< $¾3EÜï¼ [=|Qğ‹…ÕíŒ4(Öµ{ ”¡…óQ5µØ›c†è­¦çˆ×@ôS¿™è\\#Y«v*„Páòa%‚dvG1Ä€PæS3*w²,:ˆÂI˜w×ßšDÏ!lj…›²Oßë“vÍÍ`à“¥Ç+Q¹Yí^\ ,PJvªƒ+ÍrË­:ß·µ!vÚš+Q‡lÉS¯!oÌv}©uEd¤áÏ¤ğ•Ú‘"HEÙ=Ú`×4Æô&¦ò¿XÙCì½ÖòûÒ–¼j³õ"YM;5ˆ
p¥GéY…k")]P§ZŠËØ“şB©—ñÊÅ¶½[¸½.WF`½fº¨t‰»ÛåT{Ë"ìÑUê¯AKË­ù'†V$QFhRYP|ì\ÊBW¶d¢H\Sô¬xJVĞßk®.¨!óŒÿĞ/ı-e»ª(ÒíìçL”UŒïö{	xÂn‡´C5Í’–NÉ% ö¤3säåÒ÷=VÑèr ¹»„â_8²¢U'L^_èZHm`yÀ±º’—+n€ ûeñÉêJD@fµ5"ëQôÒà'îõsDC'M¹Ú=x)Í—Åc—‹Ï&ˆfó…¶ vİß‹âc•Q'´xî*ƒ´=ÔÏ
ß‹E¡+ÕÙUŸÑ#4¥hGlàpg¤\·Ú;²w›ì4–©£ÂÜ¡„z7L&Ÿ  éÎÿB6ìçgäøÉÓóBµM¶1ÎÒh^:Oö*ošû–%n 9?3¶›æûôØ*'†×âŸ¿$¼÷"òõô~Ê9õ`yeıùFƒXµ"Ğà±VMvØÅGˆ.‰Ñ{µb/ôÓ0Iœ¬©P«Ş»ñ‹R„jES•}¤(ğñó+$ÉÎo º±œÒSŠÅÊJ‡ägBKq$ÓøƒU«@ŠXË8òF³„MË`A¦7o\[İÓĞ   FÍUšF‡y ƒÇ€­øW&±Ägû    YZ