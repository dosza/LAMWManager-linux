#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1606845145"
MD5="3084ba8eb7e3027326e51c0df8220f90"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20436"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Tue Feb 25 01:25:25 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿO“] ¼}•ÀJFœÄÿ.»á_j¨Ù`-\,–åzjªÜ…“/¿Š|çsñ#”1”7²Æ;÷sÉê‹BóğM‰²û•†äå¹ÜÙ‰!´”•c¼–^"ç»+{Ù¶¨ÍÎ[Ö’ó0_Ö‘²ŸŞ'ÑßHê>Ø§çjff¼ØÿÑ8T^şL¢¾ÓõáÚ°˜^©ô9İ\Èõ"â+OZv›2eÓßó´+Æˆ\°2qçØeø{zô/Ú²;ìOÖïqª"‘2ğC DëÀ:Ñ?Å)ûì‚âJlF©S˜+EAnº47>îÖ“š.«nÌÂ^N >Rnß`C-Xwk©67øa\lu1KgsÁA“S&b8šíd`Hãzğ8*œVnH7QôÑW{ã*±m\'f @øÇ´.tÕ€·!B7ÎïW±jÆ•'Ç†ëwÄ“°+šª¤fQ……ç¥Ÿó¡9vmåXx+jN§à –™O›LK ø¤WÓ“)Òâ²şQz6‚Š.ë}GíTÌÔDDäŒ„ *RŒb¦s× z‘@{a†~‹÷ój°fÚ5>?œ9+-Ø×V¢Á¹Å§S,pHÁßQÇ+Ó÷òür-ÄTÀŸEB&»Sa%¶¢Ÿ†ä=ÕØ‡\Zqjq‹áæoj—©²)å{Ñ*·'…N9E´ìÆo¼ ”.@h6Œçø·ê½BšFşyaç?¨´‚0ÿy—u¬°œäÆıÙ• µŒÓ½mÎı¦]”ê´+W©2#E(W35ˆ«:—cov0kMY'ìˆÚRL²Æ?…ûØè’*ÎÑR{™9ÿ
q•ÅÙIî¹/1 º%:İÂRFz#µ$mpMHUüˆô°¹c›—È|Tu¤ö
Şò7ä7·µ-#Rd{Ûé¢”M@?™„îÓÿó4¼UÔÃ?Àã³V"M°=üf„LâŞ4Z(_‚9 ÃÜÄ.>ıVb«Q!lÖc=…ß¸®…iE{îál5Ÿ9£ºÅ¡‘šıXÂV
‘Ä\*÷Ú!R¨‚%Ğ„š›_×à ®ü¬.9dw$Zq¶Ø!‹ç½Ã‰#é‰~š'Q]õDô
Yóñ‚z£oFUí­½µŞ)DŒÄÃİn(ôëò«h×<¢Ú´ê3Œ<×æ6´ÖæAòÑ˜?9t~Oä1ôb$hO{T…Ğ Ú½¿ä¯Ù÷ûï>ø2ùËƒ}8£køi’qÃx!Õˆê.’eÁ=±òëÈ`¿PÛ[ı±m³‡ôpüp£j.È!sàæzÕÂgŒœ$X2Ç ˜€P·\“¨Ìëm÷>º—Í
ñô–"÷ßµ(€2¸‚„‰ÁwâXÁmY2ŞĞÜ§ŠlîÑ¡‚ÓòÓ¾6MI°'4kb³‡ÑÆ}É>…’Q¥@”a¦At«' ¿†¦X8Gt±m~DäOÃËkœÉıäuLæö+£Aÿ_‰.§å…½`2q.—eç¢ÅpB¬aĞzAÎæ8³“$—OFrŸŸëÔ63†´S~é¶Ç¤SÕËxû`UOÈÆöUT°?àÉ0Éâôèxsç:O~¿ÔV,Ôh'MÒÕå$j
Uº1bæcœ¯ºg"Ëpı×ìÔ:ÿJ§%#5T©¼Ú½°õØşöØˆ½¶²¯´Èh³Ä¡šEË½%¥8í-ï  ö„¿ï¿Í…äi£>³P úªÒÃSÉwæ·IĞıĞ¾éÖ2[ÍßÒ×Õíİ˜d·Å¬Y“n@r²äod°àƒ×¿NÁá›.Q£âÄv^±œ™æx:$K@V>\Š!¯T8ö:t#´Ş—ò~´·¤>ÖPâğüÓµ6·Mçİ‘˜w¢/=êĞ+÷5geé˜ÒZúCb§#	i†.ŸšdP¾ê›+3çÿk^Ô1Ã«\ øzptdß%Á!úVHí`pu2¶_Í¾Ä6ß¾dîÀ¾¡#†Ó¤ò*lP‡,onbbyô:Åƒ<qãc°€æÄtØyt¾­õ6°İxy]á#dwÿ±İ­’ƒâxz4ú12•_wÍkZs±>ÄÙ^ˆ ¢Só4ÓhóDW_Íè˜‹ıïÉF,¤öCy#7<–¶öºd»$ªq§ôßa)K[[Ó
Û€İ(˜\D‰g…Ë$&fí^äD&£ó[Üé¥x:âÛ†³­¼İµJ? N§v?è%HÀÑÅE¨–û·|ÜKÊ8Püdš¸ÒZ-Í3õ‹ Şç/7¥ê
.º¶sk9;`‚#‰Wòâ
'7x~ÏeAÀ¼=ÿ¯ NŞ¨o[§.k]Ÿf¿]Î%e2q‹&eø»WåEğ‘Ùóø›´
­Ó‰&»®®o$À·Ğ‚'XHÊ.ÈÎë+YáÇfò›Ç%¥„@fs!\¯KÚ1œG¬ª[„ËÅ&H~	„»ÓCŞxü0?Oóâ"™ğVR]ÍÓj5IRºäY6Õkæ¸ºæÈŸ•Y^XÃÙ&HkGÃDÊà*£^zw« )“–™¡Â¯À—(1á+[bY<õDe?ì8$ñ‚ 5€¡âVœ9ò¢]V
ÂdJPø.¹nzËH“ÉÂlÜj%SVI—İ¼<I£Å‘Ì‘…ï·÷n×5’Z9¡¤¹1éÑRjGuÙÍ¬€]{AøşJ7^^—İ£ÈS_ı¡èc ÍÍî)yO®i(ªè#Î·‡¯½g?ö°DÄşıˆ£ÅÁ˜”¿AAÙâ! —K*kÑıac7ºğöÑÏn×62¿o‚Á ï„‚N+ƒ÷®dìøÑIËÔ×UÈŠb¥,éÙªXºí)ŒïĞ–d$&æw[¬ˆ&qóØ°Ë`ey1sIxtk„h€j×Öı}ş#İèäTÊç|~\Ã0ñ½ˆ˜„~rœ¶ØI1X·
keİø½uÑµ=5æd°ı…mÒénÆ5ÂQò)†5ë¼e\¼Ìù…7QJ5¼ÿì*õLºÃ:1ÕX¿Ïu+¨£Åíõk"cVuº‘Il)P©ûFQ‘>”DĞ’S>7êIª(i@`Üx4 ­Êå™ie"Ş‘şĞ:üÆ-8‚w­‘bE@ÿ8„„‰æÿGV°€ÒÄlf¤œ¿Œ‡¦¶­Ï±)<€YızÌí=ÊZ\êğş¤EOùDçfiÙuëM—ºìãÜ`V,Ïyîä»åÚ²"¡şã;÷¼dvq©‹—|àmü›&`P£ï kVqÜæô7ÕÌ^=[çñóØú†ó,râ]ˆ¦»ÍQ8î|ùBr@fôçX•7ÚMî¼ Æå©©ƒãª^<(+)JıÒGu%·p)x´CÒ!Î¢¯<…+ĞwÙÓÀú|·åVO+¢ÿóùŒªdt1EŠ(ÜølA‘Måã»ª:ÕÜ¼\×ÓåÂMüK%ºz¯è¸GId@¤¬m,êèÏ79zºX~¸…bó¿'Ò€€eêy‹J‡›eêì%¥ß@Jşl6&„‡E›×µfS]î÷SS‚põ—27·Ë¯Îø°N ÷¬¬#!¸@{2e÷½ÿJ	Ú¹Tù»ùQ)Vü7˜3Û]â›ÒTæ<X‚Ë ¢ ºÏg„¤3”Do?%=ÙÑÀ"ZL@.Æc¶ŠÎj$W5>	¤vdšÛÌ¸Œº\¦xÍI™[‡ >P«zz}Ä¢ëº‰„py;4-=ÜU’­l×ÒñÉÊ;k¬ÌWÆíeÍŒ «4³WvAE—>©G€ë¹°ÒõÛû$C«È¹@’„5µ“Ú³©×lSŒãÏşÂ’ÑÔ–	zÍ AØøw/:!	ó‰hbN–®ôVÒ[ŠÙ¾µ¤yV¾Ù§­%æFR^ ã’k:ƒÀóè¸
÷y0]ğçì‚´H‘Vƒf»æ ío<× \ØKz¼*î­Ò±š
x¤è?[Ï°HM…YgÄ2ß©õwä¡¬~ŸÁj4rêÎ/|4<ËÉG´H:®–`„t’µ¦¤$óŸ­Ì5‹š5ÍQuß¦ì0Àbª+şÁßJDØ¯Èã94ší‹.FÆ¥ıDƒÕ?Îş‡Ï©ïk(XN*Åh
=ç?
ÁgFNF1˜úUR‰k¦Ï¾]â"şÇĞ›¿É^´–Hí#cîB¯Ab›9/6%^WƒÖèÉfĞ õ7x.›IøÎµë«çÄNê)‚d¡Ş¹l†#_r³ÇÑÍ¹~§P8‡á$õŒ¨¡œ"]ıkí|IÏ´h–íÓ|­fí£÷mÑNV¼sŠìí"R>8Î$ëË€²ô`r]I¶6Ã	Íoûq¿_¥¤2RV)¬Ôíußˆ˜<¬B¶Ïx‘	–»uîõï‡(ÌÜ??T¾ÃSïÁg'›¼Ûá¿¼ÁHÕAßĞöRtÕ"ãlè¬cÕ{KêX–§§l—&uÀjökâàS<bæ"um’$ÎÉ0_PU?`Ö˜/>F³]ueÉoñçÓÉ†ëi[]À`ñŞğıNXÔ_¯†G•ôf)7‚Á4ïWY[Ïë »0D?Óyø9È	Ff^x»ñİ=éµµ\}¡¸${îòr²eIâk¼¦ª…ƒ-‹ŞöÙ³e	Z1u¦t<şÂ-LÕzäŠòÙ~Šğ¢'|“€™2‡«dìğæG¾ïÕ¶z†ä‹…ÿÂrŒF³\Wä=“Ä–»~ö<;²I‚ÆX«ÒÊ6Ôs¥Sñ›¿Ü‚Í=É¸ûÇıÀ—rE2!Êé
 ‰VØù áî[-µ"9‰¶¦•r<GÇä„‡p9W'Õˆ÷l$~ôM©V>óâ„sU#ò?pJ#økàa1®Œß‹Eo¼)ßr-ÆIşõLE²œ,zú5¥5^èWÉœa÷uuø!°Às+ıÜÆõx=½’ \*9¨j2¢äìP“È³ß)bCc_ª%å¹q‘Q)À8V—ßŞ¥Î”ÕµíÌ*zø 
ô·	Årww±y´/º‡™\ÿOvÛUİ0¤°ÕëY:³•_4ïyö3gÔ¼ÁÏ]½J™µÙå‹÷ÇT­ğgÉzwU>{§;_ù!T• M¥âw:†Ñ†èš)tğş'$<d×®An%shlî‰VªhN´Ô/w¦tïîÛDÌ´ÍsÕÌÊ	'üu"rÜ¶‡!N+„ô¾©½’é&‘A±›Oòê‹G|ŠÏLCà¼bÉ06Zo¼ƒœ}ş_ú¾ÀÅ‚Q"zg’¼9ˆã93ñ‹ï­*¯®F°»è:,İl?Ş'¸²%*ŒLORà€sœö$%!dˆå8FÃ‘¨2ëˆ{LÎ°î6@—ıw ¹ Œ²v¨ËIvkeÄÂÏ2O\mhWƒ0$fÕ
7†º¯Ë?úŞcgH_¬rhe‡1ˆ”xE¯4àluF»-Á4É”|ßTìH²<hü?@ò'•Ì®yFp&È~µ³¸wy]¬Â–~53¸¦u{KwÏ-ïÓ$‰Æšï®¦Îî}l›O®=0ZàzºÃF®O±|/gàÜLÁ-ØŠ"kâ×¼ø«£r œûoş[´œ²şCìÄÙ€¡7
8*½¦0
r5¤âØÄ)îcMåv·ï›¿‡F-©ûlôå+uÕ½ï.iøÎÁß* qÙNe*[+İ‰šİ²Q~ÍaPg'uş¥°-6q{Öh *_ÜÁSÁda˜ú~FşrÛT w+ÍxIU¤\N}S`~ lZLŸo#ÊË­Îóâÿ…O·“Ö—Îëuö—Xñ!x~eá¿4¨;hÖÕoæ”Y'Æ‡•ğüƒ÷c°(B',Hç`ç‹ENãË\üœÙgpÁØws^}£šÌTO.£ Nƒ(X¾±³’Bä¦fOX÷hëÈ±çGv~™_Vv«âI±)È%Í;Öº):\Iz ©‡6¾üÂ£­J¦†Èë¶…ø¥©„#†ZâDŒ’¢…y„Š¤á‡VËá\åçá•k·3UŒ„‰Æª:|”XğcOi¼|‰}³e‚:P?²Q¤ØÍc‰¾ØIsp—ÿşwŸÑw÷[Ò'á§½%ÒS6œÇÜ”Ò(OW7‹)	lÊ.³ÂËŒÍzœD~ÑãŸ¢•"'	®üØs÷R 9àúØNd‰Åí<´eĞf<±Š¢3rÒ0?µgÇ”`£Ëc¯¸Sòj
wDC=ÒÙUK/Ïæ].¶ˆ¸9îÎub¯Oí!:D~ï
S
¿6ë¼QKöóù2N¥bôƒŞĞ¶†Œšô`Iğîÿ=zÌ½Ô}şô¡aÆCA©Ìµ5½€²óÄy¤æ¦t5âS€Z%˜;¬Ó[«büø$êÈÀèÈœ‚ DÀªñó^ÄUBYj’Û0H×u[dbÌöğ„ŸÛç3¤H8dOçD–å{w®˜+ØÃO°Æ¦•A×w)aEZgÎGÄn?˜2o·Ú+‚(Níß¤, uàjg	ã…=®Nß6gÉÀdì‰ÉL²³aé£FúÇŠã±Ÿ&/9ş˜Df•ÇûÏJ¾U=Ã©Ë5l¸º÷½7¤Ë¯Z^ƒsù½E¯à(./èîœjÙ“~°¨ËušKz‹‹¦@K–EYÒDszŞ@¼«½E²…	u1=CğsĞ%…ÔB¸÷e¢c:T…&Æät!3á¹ZŒM;VUo­ÚüÜÔrtA‹Â|Z!ßâ	š-“ødû<äã,Îï¯ıŸÚ/¼gîù}ÇğÜ¬ëúÀxëF+ÇX†çY¡Åâ×§­g°×=.4ƒ–üXî-¶#p+Rt–ûØõXzmV@»];GZJ Êi*ÀĞ’¶­±£ó1¬f˜ñ‘s~q|úÄX*°”AÒ¬jSLè&‰´‰ãÉÄñeKîRLá²œÛ[n¡¬ú»Y£“!æŒŸªcÛ;€ú· $là#•d†»šP¸ó­©Ê‚1Øêœqª;™³gêW	Brú[8¦ö¬>2y.m…É™™îÎÎÜÿñÎ»ı×Ém¶t[ÄŸ$µFÑ_s¢~[BêåüFÖ9l}õaFßÕIŞØ·4>$}Ê¢7Ùı¤w÷ÔKö­Æé«ô«™C;¬í¹¶Og-æù‰öT `‡âæ3ƒbÎ9`~Å£ÙüÂš°ñu$èG
à¦!w§ì-„ ûÌX÷ÒóŸ$7ŒLÅ (<Â?µ ^Z*»xlj¿Ç8Ó!œbë¸Ñ2Ì¦‚l0E¼í®wê~Ò…×İîa‘¢QÄ!âpŒ~©˜Û)>ıÊƒPĞÓ môL¾×ğ%zÑ4S|$é—y®ƒRÇÇíú¥»Ïtºì¬O/=e£œå`ú­—{åÔô%-@†IwªÕkéAñQà«fJµb{Q”r;| Õ1¤xÊØƒ~é¯t85%˜u˜ÿ§^&Â0gqßÙ9ı+LOÜ?ª|VğB•hµ½ÔßŒ²ËaŞ¡Ùjúh“CÄ+zøÂF-ş¸Ë½“à¾V¥Ju†å	†AÓp³mcÔ=¨&X5ëÌ–ğ‡Yr¤¡TZ`‡“¥Ô=Äj¥=@ÒKšlQXœ²D©æ¯
˜F&Ö	U(¬0P…:šmà%cæŒaMS«•ú@j¦9GòPpYÁ»ˆìÌ–DO=‡(I H·.4…m®ÃqŠál¹WöÒ„zÅ_›Y6ì…ä.ÿáF
µ?²°Ş_÷ìØ€\å@€×eŒ=Ï{[Y§ú$†¢ìà`j,+ú‹­ ûn½‘2úÙ¨ódSØ*Uú÷J>c¡Òü"³",a•ŠĞ¢…ï!P}Ö˜mß>#/›ÒĞïM—Åü¸£µª·ˆsèV®ób<£kyJ÷ıd
Æá\ê†àŒ23Ó`X¹ˆÒ[“ØŠô™ÌŠ05¦¦kÅTß•éZjSÎ=.[â¶Öy&Ç¯/€­œkóîS=Å´äéäÌİd©bõ”„ĞÌ»ö×gMÄ÷Â‰TåôT¨œÿÈuÂkVÿÔq­èD`‰d£àïÄ&Lu#F7‡O§›çS*.ÃUıßém­-|ü—`öZ‘0jhPe?m²b—‹²D™n”å³Ì ­H—o‹Â+9š°œınû®KÊOÓnÌ8GÅÒùè¶Š÷íõØÍQú+HºÿAŒ¨ç%s³[I‰Ÿ1Ö„ä ƒÇ¿Œ7î}6ğT»ê®–g”)¤l$Î>š/Ë»ğ¦†q<¹¨°Â6\Ib²q]ÅíHOBÎ$­_™Úø˜ÓãáÅWµ¹&ç4>Ï…áñ€æX˜_åK›şMş¤·Hn…Û â¨bÓ"3vUğ3Ôİ¦dgÃóÄ=äĞì¦;bá™hŞ§¢u¦FºO>2 „BÎ†Z*†‘›Ü— ç{áĞsÄf.ÿKÇœ‰8Òle¬-e¶#¤ä?nÌĞ~´^<$L¤ó»Ì³ {È_İÉğ]¡~´	¿;'ã sQ‘ß–[Ç›¿œyÎªğ?3íßÑº(<]üf7Ñ"„¬±
æ60^²=2µÉÛß&=‡Kâ]š†øâS»Ùüh³
Uç¿èC';Í•òy&ÿ­kwHª´£¾Ô:>XÊ”c	>2Ê.V9›M
TRå£
ÓTã\*Kp'Œ ïòd¸†íúİãæjÉï-nóß?eŠÚR¨@{{WN“ĞÀN}XøaÕÒï&à¡ÁŒjØ/Ìl-ócÄ®4e
@«Ò·Smkİj…ü¥sÜÙ¢ÏrŒ±Qø˜ë{ÔZø“Š)o˜?³0K…·Q*Âv Xgƒ
æ¤Œ|×£º(şPòØ¯…)X‰ÕÓ­ ş$’}'Dt÷bÌX,–Ük½Í‹1ç`Vf£‰9¸aˆ¿ÒÉ\Ck”-^¥t:™>d°&ãw_¨]L¯
Ì°)ÈuäW¹ì{=Ÿ¡yê„D¤» ÈÖU‹SûY¯ˆ½ã[çbL!²^ÛÊˆxMæ‘Ä|hêë)®a{5sèC§µ_ğ¡9õ®¶f`›Ô{¢@ãt/HÄ=sM7µ©˜¶nÊşµ8)O‡eS”ê&!ùg ¶óı"Z~O”GŸAû7” ír~2|'
E.j3æ¸è?³cÚåîÏlø×õ’½l	ÕéÆÎÍYHñ5X†C¨åµ¬A%ğ7²^Y[;ò{œY!Çb&y‹–s+ÍMÜ­îEOğºJš%ii¤¯"!È­öbnfêÊW€ƒzMI3îÁ\ró¨ÚŞT»{öò6+§ê…Û÷Ş¤­y·¡B4Òå¼Ó3¾b²°;*Ù…_£3C™húÜ@ËÇZGbô/²Â^Çµ@îë!Kc<õwdF—ÆÅiÒÔ	6A	ö	eh<T9İáùâ/0†Å.Ü9v#ÔÀøXÜ5w¨\WqB
;á[Ã	v*áUHM‚æDÅˆ0¥q¯|êí‡ø­ñšo}µğÍ<×³¨ÆÂ‘è~ê)Jè!ÙÖ€ŞÕiF‘¤Jûˆ„­·ço²(¾º>eJa[ „ë`(F1ÉöÂ3T™3Fµ’‹´aşªÆdJ™X]³{ålµƒA¦ŞÍæL0_¡-ãf™6±´5–›lK¦¶Ó]æ%Òıy$:³ò­»~t!ßŒ:ë|XÏğ@\ôÑl]j€=:†ÎRvJ}D!f*›!
 @ßÅz‹y+ÚmÈuÆ_"Wƒêç0j0Ô·s…P\	ìªQÜİéùÜ9ÿÅsãû-V{¢%se`3!ø<”§½}œ¤G°´º§*ü ô?f’K{Şíéûà’G~şšàÌşNÖx:²3°ƒPÍ°æß°%ìR·QÁøôå®Œ£ó–q¹ªõp|Å@Î³ŸW­ûÇ¥ğvÇ°y~=m½¥OpïtÂf†bÉï’ÖÓs~¬}bk¢ê#ø§|qØ=ê_˜4ğøWsş\¹YE2+'+š´r[./Kªxúê5Kç×[0¼¬À³¨ÑqJèA½æ‹/¸¿z:-}ïe¢P{Ì*u…÷–â¾4~Œ_„°hº9&‡šOÓƒ!g¢‹M5 «€
™|CÃÒ…sŒ'~Ô‹BÖ%¼°ºÓ®t8Ô]Dò©übö^¦Ô_¿TLôÒiİëp\”ˆ¯éhÑ1cñ»\ªílí',Öšppèó:B}¸ƒñ^ìœÚpóÎÑeµ™3ŒJÜ›7ô>	ÇÍùkëµ$…çÕˆ›Í>¯(¢TŸû_=kÜ×£tÚ´òàVºÄ†q¿E¤aT Em÷¼\æç·ÿšÖr£'¤®î4~ÃSnDÒ/„™Xä¥Kñ8A™"ËÜbíEo2¬å·fU%}IÅ^§¼ÅìïZaV5 øk¯Ÿ"¤AfÒ{ÑºHÀ\ø¥Q}3ÈPÖ{e˜Õ7âÿÄÏ‘½E¦¿îŒ¶ë£Ä"òwÉ¥oÉe—Á5çxÈ\¤hÜÎ8É‰ÚŸ_¶dt8%¯°½Â˜¤|ò<Ù¯ÑËµq?»Gf¤¼ XPl1&Næ±|¢5{]c„õï+M³Ÿµd+W‡û²İÖ‡Pq©•¿™±ôä–­½ûgKv|É©
àŒ@2‰Ä;®oã· FÔY=§îoG?HöxŒ–=EöQA£êJ“A€yÒ $ˆPÍ!•MŒ¸:û0N¼ÊFŞ“XSÖÍñ/¬ªÇÚªáX·ë–›8^—öd‡TYØvY[ êÍû½£¤±×vB´JÄ`ÁƒsGŸeöYÑ`¨y6Él'¼±²g!¿{ì(g,}¦RîCÔm8à-yÁûbŠ?6`Fd•Ì¬<$^bg
å÷FE¡¶ïnÜ¶ŸpÃËÊ–^“Of&T84ZX’-v¿$¥Í¿0°¼ƒ¯z0J Tk£*ïßh·úpläaD¬g}ÉáTºähò¶û)Füo=â,½l7+@ø	©º “0@MëÇôóXØ€)¨åİòØpôã¶Ö²Ëå½™<C¸yı
¥¸;İ#Píê£Èvï57§º?›ÛÎ”ğ›Ô¢Ø†¹&ŒsÓËqàŸ±MVØ)‚ğòøjÆW8jTb)«A;şd±lô	X­øfq#r)d–EåÔ9M kÒl[yµá”;š¢-Ôæ1£“Í´İdÕÔ^#–ğ™’Z[F.8¨f0 "¸‡BùÜjOÌëô¹Hÿàd¹$ıªe«—*RC¼'rJhtr¹~u.ÓÇà=¨f?÷4éfù/‚•Ê"S‹:c|¥f^Aşòá¹¯ŞA="şw€°x¡ò•ÓV»µ`!ØF£®+’UzLœõöåå
GŸ”Ñb£éj¡ôı‚!å„oU.$¼ÄÊ‘ %Œ˜©/Ï6:in’È„õ<Ÿ^#®¹Ş¸%jÎ=FŞK£[|+
ï6ÁÅ§6Z[ºò˜¶ğÿùå€n³¶¦{¦9f×î|^hSšçì‡Ê*•W÷ îÂá íµÿê‰›P®¢àº º7òî9yÁÙ†‡áA§f;šúâök:î²êÆí¹MmÇÂ"xù¨Ä½Xo®øúw²2Ï˜‚íÒ2@˜ıÕ¹D~Å«×"óa%üa^›mîv…‘6äP¹»B’U>İ³%Á¶©Ûr§¡›×wª9şïğÜÂX9$sØÒ|RÖÛçÃ…?(q1'Œ>İ)¯zç«›îÂá2à3ØÀ)_»XfÄş™¶Öî29Iµ[`àûWõ÷^dk39¥/xˆ‹M\JÔÒ—¨ÓâÁx32}cx„!Û™ÃÓR]¯fp UÉå§·­°[°Ä¦â©îÀU\]'svLŸTH‘ÿ7ğ¢"kGN¾=ÜF&`ƒAéš?ç¡ÒÖ•ÌÃ,àøW¥r’ıÛŒğXÙä-•]!Î´Êl–¡J¹RY>ü…ù†ÂºhÈ­œC¸x¡/¡M˜dıŞ²½“¿å­Ÿ=\è§|#p N`ˆ­…èÚ­±\àNA_ßg¿eÒ7Ô	¥r¢F!‚ß“s7§Ö™©(¯/CtÑ¨=B°Õx8H¬w¾0_³,7FÓæBÀ§ş²À6è¸ÄšĞ6—õP¹Iƒ5=âÆo¬×Ø>Pp G$âËBÛimÅÔ<¶Ô	¿µôvÌ÷N—Æ"0”òiIÜˆÃûİ·Ü‡A”®àÇî=bô8JÿKòx¶ÂÙ•zf€`hƒ™Å³©#q"esìRÛASÕÉ¹-ÆxDÑ¼J—×l~úCÙÊ@¨-º“r†¬¦Zi© ;(wİ)BFúoYÏ¥GÚ–å©¶5êâ¾K5ª¹,÷j‡FåD–#…ü¿;	dœÏ!X<ÔŞĞ'FZyíò%Š¬ŸØÂ Y?XÛÄ£_±msœCfÈ&n<Š‡OĞ‹>¸ô (²âLc_o #ÜGp1Tf—j¬Sø–zkÉSºe~Â@vMTÁujï©Ä<¿	ëV½Îğ%ƒ3<Q±héAs¨¢ªOAÅƒÆ´£èöWPn]áœ6/‡“ÏOMİ®§^ı˜Ñıe'N”¿g²6ÚW\NšğùÙÌ:Ù§b+àÄEŸiNÁ´bôS„¦½Æí-G{ó_›–ßÈb[Ø,^w—¡{ çëEj^/Ÿ’¬‰	Ãt¾´-ÍßÁ	¡ß'úŸñ9²c)šKÁİ^¨*Ş>¥:µbàKô5é˜ŸnÊÏ°îY®‡ ²[TY?Å•!ÕØ@vÜªMê&PÇÙzpØlçÙh ÊT‚}e4C5Kvƒ­#%É6Ù´«¿„›ê¦à®—ß¯pXAßÒtE“4ÄE ’2 xN|0·M[
]îëœŞmAFËõ¿¶æÜëãET Û¢ÛH!!Ø•œù>ùHÅ7şKŠ×‚gßÑÛºd»é¡{–÷ú%-Ø:h¾f¤iÉtÀœÈ"‡Ãº‘®«jš÷Êë-ktJ·‹5Ë†DT*^ó±d¸X‡tÚmL}Sº¥ÈWÁ`Î{ğÙ¡p.íjIé>Ó÷ªxŸµ˜$@²–<B¾[¦@Ä´óWù?ÊAŠétp#H¤ÿÖOùcDXş¦Yüz…hvc9«Ëº‰ƒ ’Æ¹É¢Fª Ëp{‚¦4	å×Êü9ì¾i–oqİWİ9CÿIŒ¨ŞuLÈ«¦œln¿qê:¤‰‘úA­–?Ì0Q¢´À&·Ôéf¹ˆ˜€'@æ,\3Üë;Ğ¢u%XbÆòçqdü}zA_+~Áe²ËÚà	›ÒÏêœ]›é9Aºì­¶Õ4Â(CİÆÎåcj¨ôy¾&-_cVÔQCË3x¬5›®¹ğîYbÃÌ	KFèäıCn—iœ	ÏË[%ÖSÿ/[;¾…Ñgmè³K•JUƒûbc¯ÜûAAF4n–0g(†¶G8€	S]N®qîÿ‘ÕæßB·òâğ¥ÉqŞ]YªÅĞm&oæ©Ü±ş\„½®Ú©¨’²Aù¿ş¡–
N4½µ÷Ï*4k;;`Ü‹ j¯ßXö6Ğ¨ã+šE/ÑœÓ _˜vî¤2/¸¤P"1= µ{ï"rı´F±Gûä@Öì¡f›ï_SÍË¾ROexâ ‹p1ĞáÆÃMjê#Ï-1ùÅùv_-‘¼²6hy3°1‘ÑÀv„IÈçå‰Ç€	¶•¥hRSËŞ%RÑ'VÍŸéŒlVÜìèß­Úë5£çÊ‡Qø#4ÀıüŒ )£ÕŞŸÖfŠÿpâ‰YhãĞÖ-Œ%¡†õq¯Á:Áî@âìªŸìüx•ÜV%;©«~ARÑÜÛ9ç’kS§¾J/ÓH£§Ïİ “nç;Í\Gx?«#–XyïØ@œÍqEXû>FŠfV¬ıQb +ÆYóê4é;Ï•z6IIÚ«Âí	–Eã™0å>§îÆ†“ÕËê•°H–šåàæ¼R‡+lìÎ²`¨m¾+¯5….êíĞôMš•Íwûˆ¦Ãu@k—H*\[·iéç‘Ó ıdé¾3¦a\…/vV[e…LO†Ò~Y³ÑB9=6åm 2mƒJî
µĞ­ˆ@Aœ‚¹PşQäœ9 Ì;ïI¦_“{±¿í„Í£İ	f?eçZvûÌöùÀIíŠVVıûSf(ãÙœ.å¢À|9ÿbü¦ŞÑújè©·ö™öHôbfÿ5gÓ{}iô_G¦Úiu0"¿ó„{@ƒaÛ1¿…¸ã‰†WÂ
£ ëZ4îÏ¤ác®DxjúS!·Şê²cé3	ë ­CYf§7[F_˜ÚÜ‰Ö„ÄÖşšR¥×ÛôÍ®uéº úv OÚ»|.?4"Bòç=ïÀeşı|c‘ ÜÊy.','”YW>È8F;ÁvNMÊC!eªZµIñ05¨Ğî æ=…A³èòÙÚ:må´º½-÷á>Bß5põ£R«árgf¢¢ø•;¿zdÙĞÊÀ1"ôÈÀk,Bolt'=°éÂ"«ïšårYïCØòÀò8äıZóÄN*Ú^‹=öƒÖÇŠ©\²Q,šq>›c^ãm?Æ$0s1j(Î¿ÓUñ¦Û_î½|ğ"+s×–TÎ‹ç÷ñ÷½%5†±½”«µ'tÓ?Ó¤
ú®›©ƒ¡GÂô°B’7ı·‹8ƒ"…JºİáÕ6Çğ¡óW„ÿ»Cš«ciÖX]¿¯£5E®™cG?Q×JR°C…—`ç¤À§E™àŒ\V»ŞFX€=æ›f äP·¶MÖÉ÷òt•:‚è–ùÈKÛ€}¡uÎ6%jÙ¶˜âˆ`iZ[€¡²Ç@ÙóÊÆhä]™«[°öKË©è9_õÙ$èÖ4älõû¥ ×$;¸ jÕb:ÿ)`;×¢Leı4Œ–;Àï/S“#'…õ—@Ñ\ô @¦OËmëÎ¼4{ÆŒ]ôi¿ÛiÇ~nnÜ£–zTRÏ¥ÚGĞúE}ÏkYË’ÊI‰uDÃ¸‚SL´§0¢õ@§–'JÖpïñº‰Jà ê”+ãÛqß@iu~-zoÎç»éèâ†èìWœ©ªÃ¢Ëû'bn)µâgáÑ€€C§R£[ü
åhÍb×¢O¡-¸_–
ŠHØ2¾§úª9ç£ßÁ
*-«Øsê*ny£Q fKF ÿ”Ö[ š~©ïå¦H.Ân§F—:€.Ÿ÷‰€CĞZ "p¬Ê£‹t*+z+M'»šÀ÷°õÜ~}2ïşX²OèøÛÌáÒpüô¦ùâ-³b+¥ü&n*<L™z‹Ù­é-ÉÙ2Vˆ?èæ—ğûG*KŒöŞñ#À[ò¾­şé»¼z›4¤<¦ïüØêç¤5—Œuy³³şvl˜±mİ µÀóÄ|Ê›]·(‘*º¨éÍ¨5Í¾•3 @ü¬J€†~<‰ZîÊI²rÈŒUœÀ£_´ƒ”°*óQ¯m9VÁ±“^) Ö²†6©+}ƒ \tL½›”(’‘Lñ‹’' ×a«uú°5•š#‡ÑİÛC„?!Ùúó}Ø8…§róêépfÑæzéÁ>õ \šö±É%µzCÌ IÌey!BÅ•<}%±>ÿXNeÉìü¾ºùú)§ı0O˜°Ê2(ŠXTVùºû½e©Ë–»{.Õáeà¡v’ùÄp¹_›<Gâı„Ãm]°ayl¹×
BmŠèmÿ"G”¶:9Ú661ãâSRiœ/æ6. ïd¨n/Tú^.ç TˆwX	Q1ª*^¨Ÿ1Œ™±rœâ=Ô›Ï½fˆsHQLÿ±kéËx¯nƒßãŒWL ¦é’]á¯í•Unx.hŸÜ$3WF2±jjVıÚIT¨I¶”`$Ÿ>ƒUåÒÉ|;A…zº#w‡—ã¯%q<”A%*‡zô-N9²2<{­Øêåhjg•É`Ñà{ŞRMÃyÄAXñ‘ŸÜ†Š>¿é¦?_ÚØö*N‰/ÑÒêæÍßçòÓB=é&(Ùİm3nPÑ(·[‘Cf¹å·Ù2ÕH‘,Êeè[›ğMÁ
©Ö¡ı'êêÜ·'xº3ù.¾š¥xmÄ´'²¬‡*¼Zµ‹ v÷uç4*R4SY,v×¹>´Lo¡eßº0TÂ¢9s:±÷Œ÷œhÄåMĞ!'|oB*:=ºÃI‡/%˜WŸy”ây?èfÚ¦×6j!È½+&Øü[*ÁSW¾«¿Øå­ú§gU¦”¼ÎR»ìqËºÏ…i~ñWW-¸uÒoD1ıÎLçÅ?i4ö”2ÓÌâc¹Æõ”ƒ:"jòrÃ[&5¶õVQü BIÙ@<{å‰F€›q>xõlŒ$Ï	Ü}½¢d ‚³$—Mpµ´ 8æšRúBùó›n,G¿KÍ)á;7jãmò¬ß›A7Ø’F´Ë­0šfşã/YSíÒRÊÍĞ"Z+×Ó ›†TWQP†7Áù´½Æ¥nÔB”#L¼ã,Ãì1%sô	rOX®+eµyH„u–
ôkJóˆ š…)İc&XÎı›Ûk×Ú—“0„éÄVş¬Š0átÅ´Bœw·³¿6ÙE¾·ñmIÍé‰	¾õ²dœ7rÑuM_ÍäÕÈêızÑó=Ğ³â‡•ıM>¾1u»ÅSš¯cı"o³#‹J9¥®ÇÊ·ó¿ÿ—öŠşÏ0“Êj1qDk7ßó}'í¤%°³\F%·­0×\¦9İ¦«$Ù¤²šĞã.WüJYë­”
*ZËESpnîæ…Ï Ujàµq¬ÏãS´ãõ/ğçDò|UTE]„‰ğŞ"ğœzGÇùÀÏ–p(6r¿,®5bè^€:Öé0§YYˆi¤7!^ì˜&_¢“NÆÑÅÛå¾qææx»ÚM¬SÛzwßZ3!,5“|É¹ŞŸXhÓZ&²?e¹2ı¼ÖgC‘…°ïšPYr<L$¤(gÍøÄ3g±j‡ë]Î, ˜ú“Œ‡B¯)JR{"A(á˜(ÅHîÃnäFa2ï‹ºp!î›œä|E…dÃóËóê4˜j’ÂÜÉš‘”&dšV°­zhk Ò[Nı¬¼‚şEBCÛ‡ZR5§|`Z$=«7¥ªµyYK‚'ût¿õ"sšZÎšÎPã‹òK!*¹>:ÌÊ|4“Í»í0ÉëO/B;)™Ãå Ğ/\­üJÖzÍUáY¿åÑ"®×Ì(PX”E1ì	y½ÈÙ·ÌjÈÜ‚ÒÜY×ÕK‰Ş1ôó‡'rşåü¸|“lTµŒ	–o^à÷w×‚®¤¨ÒØzzhVğÌ]¢ÄÕZ
fCúnM¿pôQœbÁ`8oH¾qïÊ_²ÊÉt5{«ãœÕ¸ZA§9ÜSëM[]áÖ­¨”`~CÓ›5_
/Q)ˆˆ¬‹"ÊgŠ“´3ÉèÎ%Œ Ìútx©nB•Bµ0g¯nûÿJsÚà±Çf÷*3:ù‹@BXpeÆ½±C€Şv‰Ø<ªgîäÜšï$— Ù&ñˆuLIrmÔ*·PİğÄ¨“ÉšÖÎÇ¥y.„İUÚúû›®æŒJK¾·À¼åÂÓµ˜ıÙÍı:-Eî~“ˆt™’é‡º©›‡8Öå|£+¼^¥<z’î~à€^VÛooTtíeçAñZ·_°)!ëkêxö"”kşX,8|Hd)‚|&¯³½™f!#¢'.ş—2 ‰ï…Ø³ÌïeåŠ¹Ú¼†!?ÌäÍ|nH¬!ÿ„QËÄ™fˆõ”ãŠÒ»]lÈ @(î°’`5DZb|†"ÖK?À¢¾YzS…ºÎ‹†¥ö”œÕü†ÚÉì4T¼ğØ~»Ëä‘æ…µÚÓGú%4IUµÊjBv8Rl„’şs^èyW§C´±üáfQ'AŠŒNÕ„G&yVßÏƒ8ÊÆ”í›gX4~?åÚ*Ï¬oŞ’5êò%KV¾ôlf˜ğ0l.¾­úO³º-™ÓÕÊDD†up?bßÌÌŸáÊŠÅÊ<¼?l?Sd§EQÈ~Ç ‰¡ò+ÒÅI“Ÿ€“!¶‡}_³LÕJOı&¶_˜p¸jX@`“õüG‡gh¸É^q<o­<úò>Ãz%œXÆŒ§:©¥¨2»ãaŸõÅ:Ø#ÿ
ìœ¯ïÅ´­U#à–ıT"7ìÊ5"'–­Ÿ¾~“8Ü½½i±ëf*æ/fîjüÈ9{£<Í¹^sÕziŸ–äs› ‡ÔÔ¸?Ù›tMíÑN©áŒ¹6˜ç1!ÛºYvXn»>ˆ‘}&c€“ƒXÆ0ªÌ*(ãÌúš¾>ƒ²qLĞ´Áğ¦ÖÍ¦†EAJ˜-âÅë€şnüy"iåvYNƒÀŒR³»`~½«ƒå<è8óz%¤zÈ>îë·‰
y^Á~
9±<QC‘‹§
N^Úµ\ÒÛ	ºøŸ9¦ØhŸüìÚÊa˜ï‹ÑˆîàæûûØ‚9Ë³{Äúµtn©ÊÇTh³šg9¹ıb?ÃÎË»c¡¼xîÔ9×v”<-3{¯áB4à<ë§…`“2Öj)¸…ı‚¤³m‹ÉùÒš#R4ıl‘±í77ëüçõ.ˆf7Pƒk‰_:os/l+yöC—»<Ùü¥Ov£¶ &Ç +©WG
ÎªÂÇ¦¿–Ce.Í^V‰o—×t¬ M=Sö
„§¶¶&ó­w]Ÿ¸}{—¿rm´~…)İñ}•ñL	•HÄI*fŒãÍr+1{È2@Ä)Á"¡Ó7Zi)Ò§ïCĞ«óÂTQÁüJ‘„^(1ö´˜Ìn«3–˜è·İç®F×=%6µ£åªü¥·‘î®îp¢çL’¦ÓÖVg	ˆõxö#^Ôg%#¦ÀR6à3…¸°ª¾ÚI©ËİÃv¡ûM’œÆSÍ’¦Äòœèo§›ZN„7ğ?³L_„ò6'NÒ[ñzï&I8Úè LÁnÑ!çsXôyÂ!.ş½6~Ÿà{ÜDS^}£7YìÕ±æq\Ï ï‚ò£µƒ;Ø˜ı)ûFÍè‘Y2]h´Š#®£	1şYÆLÃl¦û¼†,}03³obi[•”h
ïÀŸª=‹=÷´A2J€¦ôC1õÕ€´iôœ¹³˜yúd·¸5¢âtËf!g9k“vÓœ .ªß|ö§7øÎÒ¹×~*º²`î{”¢¤áŠÄc'pô“l£ğ6j*8C};™yy¿b™È‰FbÔ(•ì{PÿÙ9*ıR¯N¼Nù\Ÿ½¹VJÀ	ºö;?ªxú‹[ €å³ú[ı£º¬´råŠŸ›ÍçÓì"ñ¼ñ¶†îhtEÚSK€/€0C¨†’cqåı³YâÁE1ıóå)ÒĞö‡ü9Dò!Rè]®iÇH¶ù•Zç)âÈ?ò¾ñ5±+ÎÜ®µ8Dm9ÀÖŸn½áq+Eµ5Mó'ÅÁ¦á%ÎGÿë©WU…ÌŸfÂ\“÷©Æ'¢+ ×{~‡4$Dö<×ü—@¬µ¯jSØ)Ü~ ùİJôÙ¦Æ–{×Á«ún:|7vx¼ç2}N÷ÿï4ìds¢ÙàjÅ[ÖÈôæ—*^@²İ®aZHpHÏ¢`s%óš½/úŞ×y{7Ü×?ÃÔ/HMÁ¡kf1÷‘»«¢ÁõÃŠÌAæ6Õf8«-¡=ŒÉW¥ÈWİ=sÛ„:*¾Ë·ŒAŒ²±;àzÅ~¯¼@Sƒ;'½ô·á1ãÔekRğËˆ–Á¦çAI‡W5{	·ãËqŞ›6•Ì×1^šfà|åvkÈú¡72<×b€K‚bO9Æ¥¸ğ'4]ä´ç)Å&t„İHMêãÂKŸ/&˜÷İƒé9*˜Š­)¶m·ØçOn?´¹î ´,ĞNn¤+ûºœ]íéƒç¥Ú>
Ú†}"8‚§ÑÆÛImKÀœküÖq—|>i·U{ôñ*½G*Ğb¥ğâ\—f±ÊlJ ,AÒ‡~ï—“x‹KfØù'’ijŒ\„y /qªápO	òÚ¯¼á¨kL*>¨ÜE¼…˜úúbôÖ7ãiå<‚Å ñšÇÌü5ˆŞV^ş3Bíí‡V;T„+
/©;¥t¿F6¢Fsª'ÒXû{¶gV8/í›áª0Ş#)8VÇÄã§©oXÆ!ëgzÇ Ùiç˜ºŞªıãæ®nì3¸JROµtT¨f§aEÒ3‰¶;‰P„”²Ó¾Šy†Â+Y°3ïĞ1(ÔŠ#3ì[n¨%¤õh¸>ÈNWb ë»¸<Ú©ö45²rš hÑæ›æwààXq'hR BŒ5|²Ê¬9Å‘Ë•iQ…¾¿µ>ÈÿÆ\B92e¦ñƒ¦"„#š@!œí|Îó£Ş¡¸N(âDœadfz°œoXFõıg¯F±İ…l¨üõU.2{µJÇ}x)íñTx“VNi‰.<	2¶¶v¿™¹Š	¨…H¶@üuúwRß Å62±z ê	RJ˜µı/xûiÊ»AZäñÚ¢¿çÈRWÎëe£O‰ñ‚P°èæƒi5?ƒõëƒœõë¨<Ê‘}Xã”ÍRåÑM'0WKÂr >×“ñœN`ÿ“³ìËÜ·Z×W •H_¿† 4);şƒ,}/ñ8CxÑ®Š‘Î›3N‘ÿ¶O‰<Üø_)»öëş`yÚO=â]ù  ZOì9ı¾öÅ¼ÿ$Hı©Ğİüªyí)<T¬=æM#_ŒzŸ§b¿Dw0'Wfm8=Ô¬=ĞsæÔté¿0DÜVìå 	",öÂĞŞcTîOEªÎ¤¿T®–°Lë×†°;^ñt›®$íÛœb`°ß·N÷FàO?ğ~˜CÏ¥ä0İrX½ü[¯Ôš§U'm$Åb{×"\´àÆ]!à™•‚š8´$s+À¹ú¤`?«']óO+<-E‰ ›x^Csœ”{—ùa¬è‰š_NW¢¿§ˆB
ÃZğ^_W#÷p“iJ°‡¢Ê™lB—éëğ@cOnÊø–;îb[)¹’ÿ|ÂÖrÇË{9êGuJjÌïÆM_U?¶Rå‡ò £#ì‡ËNNªi…>,ÇÏšW< 7~àOî4ê pàĞ«PÛáMŠÁÚ#;ŸkúU¶ì´ÑÏ)g&_XÏöÁ5H÷úx#:¯Æ/7± ÷Ôg#ƒ;;ÃÇ—›-zh#÷Šu/Q0ÂÈŠ2Äê0
U„Vw¢¿Ó§®‘T sÙÎ>W”¥x<¯Ç$Åà2“ıMóúÑŒ×æĞèox+fÉá—ò	8ÄÏÉyO6'÷º½¢Iß«å;Ï±®Úu“hÖ¨¾ùî V…Ê©ş³şm¦ë›×š¼WæM)6TTXı.ÀŒbr²}Ø±€”0+!n(PæKg4±K&ÖØ|>^-mı“(¹èßƒ§¡F™`}rC+Q¶Q	âc‰˜;ñ:ã.àñ©Şš¦95ÑM+‘*¡İ­e¼Öû9Û3™s>­'‘Î'?Hè'“	³È-îúód^H?kHvãÖ‡ô¯(ŠPho0†z_Ÿòîí¼x¯J{ÏÑúÓ¨a2\ğVôh}¥WÚ¯x1h´'â$%[³+Î¿i®-=b»³O“æ…ÉÀ¬6_ÚÔ{‚ä¸mÍ¦ı.GÌRÌªóC"íÈ—õ<ì¦GGYy7ß0|8è¹ÇqIßæ1ö"”€#Ç¥W#¾¸½›F\XƒX	:ØâÃ€qØîJíËÆ2%éÌähA N<šX'ïï)’ÅĞº.	 X0îŒ¸¼ë©‹“Rò@¤’fÿ½‘ë­=÷íÿ¯9ùÜÚĞÉ»1 0yKŸ#:Ó¿*ZÀùvŸÚÏJ¬+Âœš™2Š•c¿ M*&f;§7¼ƒÊ)=‡U<ÜÁ†û*Ùb’"ªİ‚ÙÜ…ñ¢MÆk¼H”Uåõ#ıF•ŸìPcmJ€8¨›Qä]ğH‘6ÜqÌËèêc ¯èH¸×ïÇJ™rCÀá­~üg“{\Œïå©To®½JAÀ+°˜»Š<ÓY¶FÒHÁ0²ÎèNà›”üÏwì«	.¿+›‘n’½jù+Î_´d#.œq\ı[‰fğİ®Ç»•×ÊD:·ÃÜÜõ[g9ÂÉû˜p¤RÜTy¼Eù¶U©²şh~7¥N³D»gé24‚Ëeşõc8sÈ¼LÒ9Ü—7Á^jÙ™rß®±Ÿñó5µTÎ‡¤ŒM†ôUõ|q9ÀjÓçn{¶:êrİ;İd÷:–6ƒÃ ßNxˆ9øÍ¹oñÖ.ÏóªõæØ_.D“ê»‚M¾T!ûµJÉ"¢”µBK_~(uûÜ'û¦Eù÷¢½¶Şİ?oA¢ëÏêc™×µ	¡`LÙĞy•z«-±¥Ïe'é£°ó¥j&T¡9×®ÕàÖè»ÀŸ¾M6¦{„î›ÿ×£-BÑ¯íÕ•Œ hp Ş¿—¡˜E‚åƒ¨a&Ÿlè‹E$ò“EÓ¥”À+·;£ò¯·U“³ª›hw»t”'ßK#ÙV"Äp®–Õßäûå÷¹HÜ;Åš›]«šCÛ	d(®Å2-vªn(]NâÈh/R-›ØFå¦Q5ğp©Ù÷æíÛÑÄĞ¶MRjÒÚaêŸ!N3c!ÄVX*øÌQL‡Öwhxni… &Şs~‰N[Cå…×'vHÀ¹ú:=GÓœ7ÓÊøîËııÃ@€²Šdr¡6*o¥{8…¢•ém}ÀÎî«‘£¹Ä;º÷òzo8inÀ	‹S*ğû‚®ÖõŸKßCÖà«Ãv”öêák² °Ä}­¹Nc_ö0©'¸/ãÿ;¡ƒò¨ö*ø:Ë¨"^è)%+ªp©\Ó	z¦œñÙ¥É¾hØ9ŒÑ'¥ÕH6ãäº†_°ğ»ÌA9\İÑBÑìG¸c:µ}ªiN•“iÜááïtW7pò,èËİ:Ê$ÀZ²	1|C»¶¢ …÷Z(oSs³ {‡ä%Œ1XŠ•
›|y×”ÊÓjÍŒĞ…Ã­±ÅHò(·
1 #s2¿@êëeüolCÕíÑ¥Tã œíD®µ&µEˆúyH†Ï›
*5tªRBó¹Î ;<Fy¯GÛ~]\¼A±˜ë<Ù5}‘£Äó5º_øt bGLZÛRA¸¥­`»*„Uö‰µuš\â,7…(!Ö+-o'
·×ÅØô<nZ°Nu_áÚbwä‡ßğkç»(”cÿ­'–˜½gÕ¿Á« Z\à`SIªş™XŞ®=P¬âİ(švU	µ1óã1'YVôÔ¯øëX@6ÓwİºD2¤Q¸A%Ü½1A\½k@ûC€ceÑ;…û9šn5¬#ıê)¼%8ùP›Úè†…É?"v¶EU<å&7¾1ÀÜø`%À68åq~QÚi}¢ä¨0şşéw%Åíj¯°ˆùÒ~İmñÛ»´(ÿz ‚cã%l ¾Œ“vŒâ;êrùö›Üz{0÷Bãö·?în#Ë:véM`p”ÁãióeÎ'X°éŠ¥0½ÓNÖNO¤W›åÉYU1÷Ï}B§\íQĞ«{4Åj•ô××ş2>ÏÏwÔÀjâs4´¥ßÿcÆ¿;Œ-6PEâ3¸Ócş¦=ˆœ¶½XMŒâàµ£_@Pô8!ø¡ş/yz5pM)œÕtW2DÇ1èÒM|‹i›ü¥mÌ¼™í=*e»]’£y)èãt`ˆ,/ÂšïT½óuÖk4@Oıº¼;VãÛB½g3é…ÏíÃ±ƒ¿ş›%&aLUA_êC(.¬Y–Åä1ƒ¹ÂDÁ©÷|Åşğá…?Ş]N1Cµ]Éo6®[NŞı8‚æÚòl‡J½ø[‹Ì~EkıÙUzC 15W£Ùf,ÒŞ•!w^ÎòjB’Uœ*“ƒ(ƒÛ"¡ÌĞgˆN$Ä i¯kW.¶WíŞ»Ç“BB^o,8f»§®U(2
Êè¬FÔnb—M÷¡´~y½+	J¸a^©XL„îó§8ÇwR…® ğ–òú’É5îâ ûü~Gª+°+¡÷S*ºeÂAIX¶/Ÿß,Ş„Y§ZkĞyÇ›»™~¶Áö¨o»}ã<-3?[ (HºìVIÆşjí-[¿nÌ{ëa_aûÛª®Æùq± ç½Œ¨OU_®|…çHCÔ@GèïÌ./°şkÜÂ¶XÂ,#lyVZRS)I=JBPO„©Ê?çç.„óìpx¤ãÅÜa­ªa‚ük#ŠÚ Z Ìˆ³†Ó2ğ[²P{q»XpMr´¯à&µ`z=>Õıë°/Æ™yƒ¨`˜W¦'£˜¼é65ì¦à0òxP´Yö¢BÓqÅûÙ»>G§·,ps·Ï¯c;êu¿ğÚ-Ö–À¡ˆ‹á®1jºeÀ¶`AÓ³úœLÖ[§³jË"+ 	«ñ\L;4µliEŠqÒçT‡,w	yìé–	ÒBÃ.¨ß¤9Ç[‚=rĞ:’dÏ98(²ããrÛŞ	şæÀL.ËYna@v·W=êÊI›³¤»K#òËKtÃç–$İéêªªòÙ…ĞJ¤Dê,M–XT!£vUsV)²¢WeZ2Ïê‘÷÷v|ä›?Áè"d9:Ë®|¸Ôu·¿£ø ºä¦Ş¸ VĞ¤o©+-}¸.	9Õ>¿w-Y+d«èõåËa¶•eŠ¿¿¬\òü ¡[¼SøN¨ÛßŸVä†4]ğ¼¹Æ¯Ú¬|â3=ÁDğúaNKHæã§şšwæ71jêe‡rwŠ'¸óÚ†(·¿Ò”mIşUÈ"¯Ê+ÙÒ§e`û’.Æ–5ÙGÙ’ve-u-ul³ÂØ†Q¶CîÊ)ğÇñ‰íÂzƒµYò9?î}váüÅWdİx?B=
èI˜§²ÍR4‘:à™–À!ígaá_¢ƒk.$$`1€g…O2ºYâù6ºD<Rc¿ .ƒTv,º³¨¿:NB³QÍ( ö]´Ó¾ït…ï±øV–tìgL{/NØKÙ˜0§»¦§|L®	6iÌßşL±BK»P¬Ö!„…äèÛi»É`´"ªCR\ÆÇÌ ‡,‚x¦FÁ-:·tHTˆ²Ë²yfÔİgYòª†ÓF™•°nMç‡R…øÅÜûD*d½öXIÇåÁã8ÜÜ4ŠÕB,ª¹q·_Ÿ([ÙÒ°Š8dwE€¨’RMÔ¶‰­¯÷i$'”‡8—ÉRC·k°x¬e°LGõ®YÆìIù†:„ˆ[c‡ÿğ¢]~]:Ñ‰1}ãLœ½XñÊBy1ä?ƒ?/OH@#Ğ›¸¸lüà¸¤ƒ@÷Dmû÷Š¥Ôƒ†øõÇ©P}©Øi–èğ‡»ü¤	Ğß<ºNª­â›™K¾ ¡½MŠëÕã¤ï†æµ)Ï/ıÂ)“€|e$Ú‡IZîŸ3mİ6Æaxç¨.ObF5ñÁÒH¤©ªç@c×‹¸
!»kå—Ì‘ÔL¬Ô¿6uƒ¸ÓŞĞG®ÖØ‡h¯0p1ßÅšCZ")ÊÇO‰û-¨™Ì17»Otuşşüª®´}||òºdß=p¼‡Ò_²í#ó·br·WÜ}‰X£©>W€Ù·ãGœ×Oâ)/Œôö¸…­ø®%Ø9.Œr²Ÿ 8‹O “`BÇ*\ØÆšÔ®n¥Å™7*A6k¨¦K„Mö5âërz»a4lM{-yöìXÂ;D§İğò©@†aÂqX`¦>—ø÷0¹y€aáÃØ¢Ã’ÇİjÉŒÜ/}KÔòÓ%D;¹´ö˜ñğìW‚á(•`ª|á<6Èd>´èâe3uiÃò.BTâh1…üÂ>ğùzN´WíáàÍñB²²#ê+>0”ø¼,wÜ]Av¶ûBEÄ¤Ò|#Ÿ3ôp2h}³|¯â³Ü×¸¼
"àÂRë3²¬øÓ¡—|gX›K×§s·H˜±6Äï¡®¹u®uoéZDØTÎÇà’şË?ë8YU|·{Ÿ…sÅ¢fëY2”¼_~c 
Õj}ªí„´Íi¿h7š:~‘Lì”ÚL=“xRªÿV'‡â+¶çeô<pÒn]ùbSzGêÈÿ£ÂT¹AKÜœá€{Â §/Xö¨pÎÛ ­r#^æÒ3ayP¢ô€qØì¾qLè3RoR4SŠ¸'^Dšo[©qº“Ô±!P˜ãæß™x†xw¿Ÿ•ÿûH™Fı7á?Ê'ËC€  Ü¼$õY,¢„ ¯Ÿ€ ¢¤f±Ägû    YZ