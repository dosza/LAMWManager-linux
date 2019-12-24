#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1631288042"
MD5="87a268071591443fd4e8aa190ed7f30e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20356"
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
	echo Date of packaging: Tue Dec 24 15:15:26 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿOC] ¼}•ÀJFœÄÿ.»á_jØ {—`ÕC»ç·¥¯¥ÁmS¤HäZH;ÚÏí9ğ«¸ê¶ÓH9ÊÑZûŒLl€åïM´=\ ‡/Í&¤ ØQfYÂ<²+pDµÒ&5è6`®Èth;,¦­F¬·t³Îä§”¸Y¬uƒwRÚ÷*5)¢Õ>è·ólşyHB»ÓªA;w[[²…bàô§NÃÜ.`§¡Ójƒ“ûíê£õNHÖŒN©jK£3¥hÈ;t¡™ŸóŠ»ÁºİgÁÊÆnWèa´ÃPcîVaSÄ'Uæ•õmĞ(¹2vDAî±ğíqÉb«"9'
P^O¶ÈPö[(
F ªd¨÷!tFE¤ôï~ö4±‚¨Ñ’÷[™ÄıD‘e½Qu‹¼üö_8,\ÅÙd/ƒï 	|ìty8Oê iÎ˜š™éV
Ï‹¶´dFFÚÙ½ÅS<(+=Î™tŞg€ÎVx!ÿiÔ†ó‘˜ ôµ-\~lÀCC<ì€’agAlìØÓ¼?D‘6²ša^Ü‹6¯6î\[¬%õS¶åÜ–Å ¤£ù½ıŸÊ9RôŒ^œ–±Éõˆ=‡Gİ1(1Úšz^#–•f×g7s‚_a(*êÊxhÊªXZ2Ä6ag_.5‘…-à­51\¸ÅÓ.îÃÂ¿1¥°qYùÆ
ÃÖ6:„t»]rGl>%¹Ø»ÖàN¤g¸Ü1lx¥Ş©l‰J!ÇJ%©‚I¡Ô-mpdTÔìcù = ®’şd4±æñ¼¡s«äAgHôzrpù™ †Û)Qé¢ÕŒ9l.i‹Wƒÿüd¬}7µÿ!enĞ£m$J-ó´FÂ ×!šÛ>«ØnÓ›R­kjÿ[¸¬c¥åĞ'»©cş7¼f•Ñß;EN‹¶t†ï _lˆşI¤±‘`¡ü¸ìÿGnŸ;?ÉßQ·ÔZrdH?Ï–j†–B
Á×eRoä£&8=ç¦.µ Â»ØÍ#dü±*;6“5¿ŞŠ¤ë£k°°v·äB#{oÎ<Yø`ÇËb‘¼Íÿz ğµ™OûyG”.%ûRj/é2šæãÓ™Å÷Ÿ­X“¬ìÇ+säwàôn©Ói}ûÂZ1á¬ƒ`Òì <8Ù7õ	kÂÃåÍH}pßXÆbš3H™ñÖ¥Æ“â†á^9,ğ0ìeOX‘Ÿ=¾é—Üõãúİ@ûŠ%Ú
|¯>FtL`+ş/bb¿ÿ	 C`S~Á^„â4”‘R2l°>•&u-ÇÓãI0U|&÷z§=õ#v´|[Úq›h”\zó?Ÿ6ûx
¼¯ïm®ºÙŞ®Ô‡òn‚Ü@ÍÙIFCE¢Ü¸ƒ¥NgÛ…sbŒäx²xM[nØĞØ˜
6§‚ÁjŠØÿrJl*û15<´{ôñ¢ ÿ;K„*<Æô_hÈºìäÂ´&æÁL)Fˆ]·uJLÎQ7ĞÔ“gïıòCèAı#Ãy…&e"yZØP¬ƒ\¸ğy5¥£:ÉÊœP¨J¦‚÷	¡¸\á™‹(ƒò„Z£û¡¤N®hX>ŠÖŞGå”?_¥ÍĞ¤Æ=ê‚Ÿw´ë~!İ÷êµS;3’U– x±…êŒwÌTº"[ysjªÿ´àOî™`ìk:6 t¶2‚@ĞÒzeb®ö»…(	ãé‰9“W¢•‰=Eˆ½§ÚU|-4ªæ¶Å‰ôÀ‡›Ä‚¯~qš¥íºLH]kg¬ºù¥—âğWZ–•F’fUaÂu’ŒŠÃ6…Ğ†p-rç‰¨f_s/(c 7§Ïà¾¹\
4ig0Ô_ÎxÌ¾Ğç°êX<ÚŞ@	9¯À6-‹ÉğZ"E`V0t%b<!lµÒ¨å@ÔO#ëYt„Pù{Dåa¾Op%…Ê³ã–m]v¸%:y™™¦¹ëÉ"SË¯?†zJÀ×P›<ÃHºïüS¸Ô¸MNlî¼x²!!Õ/={ÌÉP¶–P£ÂÊDÊ²£%93ş|:úK";E’*7s@¦…¹é8X™ì²šıv!Uop'¬…şõ³¿;÷>––ŸŞVš#İõrçsS”¾KŸŠÀºZ¸æ°/Ãó¶ŠÉÂ2hW uLÄ©œæÕty¯cˆà–’FÍ›TîÑKPC¶}’ÜH(ŞxSF wsş[vMÁB!/—e7?@˜e¥´!Í»„z.®ôPIë/•O¶Ú†ò¦°]Wµ.§Ùà8ë+QÁg¦àº~R{•ÖÑÙj´´Lñ€<eFnÈ9ëÀ™„8ş,ƒèCXµó^20&Îp  D[X™‰R	d¡×:nrY×ızùÊ®) fúË“¢|,‰¿ˆÄ¡©»Æ”HUÇ?"¹$Ã:u
¥X6"˜æØãæmœ{ßaë¦ô™Æ¬ß‘2.óVu>Ÿ$®8|Ê²·ÅvùVo½”½Ú0TëhP¼ÃÚHÔšĞOípkGy¢G˜È˜@ vOö|ÔŒ«¬ ó<Lë=rÃiV ƒ¶şÂófëÁíÙŞw:àªÏº]bĞ½’}ïs1r9<¦ÃI¿’í¹V+m ØàòHˆíî¦LHˆQ¼eèÎ÷à\X3kcNaûe\à|‰xÓ]ßtÈ{«VÚª'Npÿa*|²Ÿeä1€0ßè] ĞãœÏJÔ†÷°ÓĞIW˜œ1±˜<œoÙ°İw8JıÃ{¾ÚÈœ4×;œ$jë@şn„±fµg|QNÂ(À¶Ûf#?¦HÏˆŞó±èLMü(<ÚªxÒ²@ä¸ËÎÅ"ü—¨byG mm Á:¸ş”ÎoØ“?ıã¼å:JS¹ÑÌü©{_ëh‰e#êûŞÈî5l"zkí.w¥ƒè;Qûg2×ê®5#iùwÃpš5i‚şF¼è†PQm´É]2Bó·xÜÒ(Â«oŒÜy†5u¤ÏÇ-AìË–H=ÕøUÂ€ıÿÉˆ±6ZgÕ6l «’gNğÇtï‡òuÒT:¢Û~ÒxìË398¿P¼Å2øgÎıEl©µ6³G›ÜK×NN“ä÷ZÁIú†#Lˆ²l•£* 	xÀŞY+JÁÏß|Çh Á?!q~ÛÂà	Äıó<‘?Æ,dk=µƒ’xTãøj^0A|&üéÿ.!m·%"3Š}Í’	D0ÏÖp±Ü»Vdšáûƒ&Ì§*C¦qçº<gïÄ1W©öÏm¡ıüõäÿ+ıuêB“úõüòİi.u‚¹ÅÌ(Ã¤Õµ¾åçì­¡!m€´sQ!ŸK] §Çó]à4i_É7Ê~Èå¢ãËÆˆXAâ)––ëå˜Š±Ë£¾©†k’·#ğ[å·,Yµmˆ‚5Œ_<.€(¼ğ³¥âxº­~F¦ı4U5ëÆq~ºú?!”á?t„õÔ¥D@Óß„³êH÷¯ø¤bèF¼ˆ¬çÃj5Õ~ĞE§ºÑg”ÄáÆû·08¥,é8|¤€=‰½Ëä¬ˆä;KİÜ;
²İH÷U$^¬8D!·„	İÀŸú¦¡×u0FÿãÂÕÎ\ó´ê5q“s÷×nsĞ“çÆX†~‹nïÕvñ”¶ı<—Ê0¨RŸˆ–İ"‡ô·öZ¸Ó5˜PÏq&œ­%¾>m?5:½+ˆ„ÚkĞ\—ó•õÔ—ô†eÀ®2é"ùÁå#SG²=ªM®iºÎ³@›¬w ¢€ºf¤	,ó¶‡ã<…2½"¼Å³/ÚŞz¯‰myITÜ/—HŠ3Šza&Š¸¶’{ºßÚKÉ ò%†ÉøÏQ¿/!ÚThÂ–TpÏˆµ€Ü ›,ïdcµ94Úà¡'¤Ó5«Ê"®³yÕœœ2É¤JzØr\3+‹pÇ¸äİ¶u¹¦¡²½RÒ/"_ _+±?xé“b2î>"n¿}’_¶pc;ĞÉF¿EğÓ‡&@6}z`’ÇÜü5£ÚÔ]Ëÿ¢ÀC™ˆV´Åïæ	Q¡œ3g¦Sœî9¤eû…ı‡æ²å±³ˆç\'Â»ÑÇØ92& ™—œ ö¡²û±H°ífù¿‚‘ËUºh@¬k¨† NNQ°˜%b€¶ãçÇ8Ì°›ïeİ……¸ İÌ± œqñLà÷İ°ÓpÈ˜ùL^]_V†=ZÊú/Ø*b!|j)º·hd®ÿÜ@Û¨ª¦Pk™”İ¦†,<é‰Æ 2 ¨P–±Š!è$ßEŠ`DÜD ‡â(òvK"l<,ª³™Šô_Ò„=¾¼ö´NÉµM5g8õ¥Öb%{ßoÜïõ(WÌ˜€š:_òµoXéÂ`İ'œõ0Rsv³usûçÓâ¼IU“F¶°Ô<Oà\Ò F,Ú±p¿ÿÉ).Ã}µ>•D¿·Ûçä‘¤­åBñjï¥ãg¦»¶›ÈõÂ¯^ÒT³‡À²yHC<%·4Ì‘øä(êxPİƒ¡tcè5cÅöª5Q™	Iéyƒ>É\òe}S¬íˆö%<µ€ƒ ¯á=í››< öQ'@I<´w!CïÍ/(Ñ£çØ¢£µËs¤•Nó°³Ë{itsĞæ æ¾téh¯Â]ëò¸÷~ƒi’w-®8ôn]¤3\{“‹"üÒícLÅjš1^ª´öq‘Ì•ËÆ+#S;şï7K[½Û¹³cáÎPÃå\s8"šcÈí¤“ßb·ØcŒ/)=Ç•yLÊ›y¥’1‘ÊQ”Å7«,Ô39}Êê”`
\ó‘!ĞÀI§«€yY•mMÇàÌíŠï—{?y-Ô  ^ynÅ?>R!²°Å?YH@&™¥Ÿ.ÎÌÚ¦ö//x·p8gup`:*$(ˆ­ èOô½™úïÿ[ûê1© —5-Õãæd,@ÍîÄÖå]%IŞÄlªfÀ^Ší¬™ñtŸÅ½ïÊzrƒ†.ª gÛZRÓÒ’ bï°s”İyC52’NóÃ¬/öêZÙïqğ(àëeMh>ŠÿÀÒ.>Ï«ò×»v0è(²³A¢™Â¶…šümQTĞ‘“ö± 1œ(éBïíë–‡­O@¬jÉìpB"ù§ú“×¡MûzTqË¦|i<]¯&zòç%4«xÈÇ‘Êmy»2‘ä+«Ö\³m8-µ&@ŒŸçáô…•âİ-‘ß¶[•|¯ÊÉ¨®6÷*\a`öã| r¢D=ŠBÂ$ÑPæò"–İ«Ì¼T
xPh@ÊxıKNÔç¸¡µØ$š§p¡¸ûcş— º&“CçËã ¯a!0÷ğ=9äuxze^ıgZíPèwã1ø°à¸‚›d`£·Üp}Œ÷ûX6X¤€1®WF›'©‹-oÊ¿£›F’æb&90–RÂwçïø¥ ëÌi­¼IüPÿ…2|®©¡m_ÑCÉ…Í‘ä¡6e$~icw“@‡à>¸ö÷;5L`©ŒÁğF<ÀƒD…›ĞF#^ƒı%´àjŒ²„%S=ÙŠƒ:&	-ouçñÔ‡Qsu®ƒäaJîI“ş‹ÕÜ<¬ø’¦ş_Yƒu1€íâ7à&¼l~Ş"ˆ›fg¢k-Õ°ä;°×‰c©?lLÆI=eN °ª¡
äW~ÓDfÚex6+Xã²Œ(5Íyÿ,qBŠ ìjuÇ “™¯È9Ôk\Á	‚”Òqß"`Ó }jm^*¨Ÿçõ s=N<x2” l®D7©á’‘)¾qc[çGüuøRYáÛ˜Û†ïÉª›Ëú»³pƒò(aÌ)È®ıovü‚é×lã7n»CPïs$S<ÈIp(­¤Ì˜P–‘T«-Šïõ’\ól¼Ùº~7w54lŞ”¤µ–Â›C['‚Ûå¡È”çhMäsÜŸÀø‡-9"_dVTíá^;µ,>ˆªJéİŒriÄaÖªßÊLà
cğ‹ï
QøJ€›'
­wOòlåDNëÔ‡1éÂÿ	àp‚ÀÂÙ]Ü:HI¡ØûÑÅ#÷V‘Œ»NÃ‰ÕêÀäp:«­…«§“p¡lWÓt0ã‡¾,…Ùµ†FšFâÏœâ~UîçÁßüé ]å|nK	ÍºúœÓâ LÌ‡¯¤ur,ÏÍØÕ:‰Í'"¨ÍÉ¾Ši¬EôÑ.´ûwÙÊM3¸k—"Ñ
)›ÜòuVÙxCN0Õ­¸÷j€•eInşàèï‰Ÿq)‰Wûô†ÒŠ‚Ë Ñ^âªÊ[®Âï—œ?‹ş¶lC3˜‰¶4)o»>¥ÍÂ6ß<R »Ûì¼ƒ¼F*Ê¯ÛıÍğÃ	jÎş¿+ÕU¬(ÌË	VgW2ˆjG×ê4^ØÉ¥ëÂ®šÁìõ”Jµ¤ÈÇäš¿UğîÈP3§Ë–‚ˆÂ,Â|±OÍÖaüxĞ…É÷Ç6>IË/ÿ°
øÁ„oOI„—µrgQ—øjl½îclÀ=?üOœ‰¶.Áhd/cûÒËü^äìêÙõÖn}Š}:Šá%Ï CW‡€¾Ô:A,wHÂŒx£Ò§¸‡è7º‰Oh'^¬)âò½Úì“£ZmËĞæYØQ³— ¦2åTêgœB] wfå_ŠE…D†›1ß‰‚"4C?ö|¿¶Yš†õ7eY„úŠö‘Îd1À÷‡™+¥Ne3¯fl‘£>è…wâíñò¥/ûŠ6¸BßÓBïÚ@³&Èìª°ç©œŸ÷A[àdËñ÷AaÔàaû»¤1±=½õÁ%tvaP"Ú‘«“Ü³µÍ×3§_…&ì”Öù¶†9`)ŞÁVŒéÍlv_¨uy°[$hawãÉ/=S	GM9n‚«íêKïÏ›õùˆD‚~(Ë¡,/,ˆü2³ê^ô9Qû—KâTTòã'@…¶,-MW‚šÏß¨ÊŠ,’&QÙwl5"Ûö¬ÕpV(êËĞ`Ğ›Gå¹>¢›°XTş 9Ò Ì|@Æe¥"™†óà à/TÅëméMZÓœÖÇÃüc‰UvÚ=
Ç¤š[
i1ùŸ/Ë±ãUxHæ[[	aèlD%)wñÄ?zxÑÎŸ¬ìœ)N},×Ã’o¿åœHØ|{›ÜC)KMp¹)Î£ªÎ-2/<ÍíÉDø.LuD&‘òo°ş$£Ï®:· DÛœónç“ *f?¤gÁÂ)brt!Ôå·A>Ã3Ìß9‹{];Ü.cĞ"İØmĞÂ‹sÉíü–Qƒ¾Ëc|IK*´øGÚ™Ş¾„ù‘è.g2?U©IÖaÆÓ`ÿÀMOÖ6WõY‚G,íÃ>‡y©‹ÜÖ2“}'f˜‘ƒœ·mí.E¿-YSmÌ=Íÿç]
ÇU2|´”E“ê\ Ÿ<CB=híR¶dtäşãbŞ Öìõ/‘†«·mh¥oTjÒ9áhõ§²‰©±r]ıñu	\‚¹º({:3¡›×†oã*Õ7ÌßnˆÛÒı¬@?Ğ‡ï¤Å î@÷/èíY½§‰gNLí¶¥¾-TƒÕŠCcÖ<JCÇn—uÓ	¨”M˜2ğ§yq¢Ui.—Şœ"”P<±ó-3Ô%tË¾T©÷a²‰`Õ£”€fwÂ®±Û€V4àYæ2³<ôí]pî»ÈƒìnİÆ«\—ÒöûT¯ÈEh%êù¨ºR1]ÛÌªò¤PÇ|è€8½,±…jü0Â£üëNštNü~–Fé±GØ Å.ŸüÀá3í«¿ëv$ÿÆ/±A«`×ĞTã#Í½ÑÕhÃªÅÑ ˜½!æÈKbM)êW…³pEbqù´çC¨$IÂ™_v%–Z^t†Ü›.Gıó®ıO%Š¦;ùx„•¾Z­…
˜q¨('$«˜ÉÇt0ÖG_ycŒû1Ì`9l@xeiCó(çÀŒ"g;¶Rù:ªş¥wn8ğìmº„©4_e–<ái¯´c·RŸªóŒkl¡-şøÍ©yPÿ•°D—kz×)­ÙN¤­S^ÏAMj>¬ù…öUYÁc;æ^^[&zº Ï ‚7$L—Ey{¸B¨=ÎëOĞEdt\ìôe•Ï@Å^¾G#8qù$shNLmÎÛÿû<%ş'Vqwêìšî7Î
:Š¬%ı1“©¼Îf¿z˜«Áªfë¼Ö3¼•ÜOÊ§¼´fu– ¹€	—ÑÍ
@Š;ù­´>Ÿg…»;¶Upcí¬kb0FiVŠc–ƒçt¥ç`±YéƒıÔJ7S êèm;ı-ú ‚ã×Ò»g8¢OşI#éûT‰÷LÇâ:9
í!ä³]f€uK·ÌéïqtèÎÌèúË½•mløDzÅü_®‡Ë‰BÃ»¶ø*_ÔÜ¨5éfáÄš,€Îï¬äüšùïÑfÖ0©)!Ijè­A¦{Ş¡†îÆ~Y ›+Vë=Eïì4…2W}c±Ë2¼nHû´oë3ÚxÃ÷³gó º_×ò!EòKã­ôœ¬J†àîîVŠGÚLúeW;Hü;Ç‡æ?y?b ÓDûD9¤øá³o>öÜ;,Ã­Z­ŸéŒ¦Irı[¯·(B»ñÔx+Ğšbè™š¼Ä`İCrğì5÷}ò›¥ÿ™¨ââ®WEIìğ­æødçßFK!Û&3õcìcS°ª§ıç ÒÒlü.şw·xC-Ëõ«È”©ÅÄ¥VÃ.YîQaÖñ]5µ.·ÛNÎ|+EQy÷ê
*	”M81Õ<QŒü$UDxı€pöï5eÚÇj~ğI2"‚ûÆn5s+ò9ôCãÁ¦ë©Oşş:ZNyÈğÃ¬Rexzq¯ÛÑÖGÑ%{{:%œFmG,f'’lùÍ¹øŸ+¦¯ÙIÖVbĞIE•î "ÅU–f4Œ#æÎ¶Ã[‚ŠT÷fQE(éfEXŒE\Pp	gº}X‡Ì’Dƒ À–±.t8ïU4AšÄX‹ø!Ø2–äiC)SšÕ‹aÁT¸ÿN…u»Åìğç1àF4ºúk`Áê¬ã<Ş£OVp÷Üaz*ïÈhlEVRš	ÃÁ"âİ$Wµ›åj6n”î©€:°Ï˜©2°ä™Æhÿøu^¿u qñx¿wb€ï}™n|0(%ª+
 ¸ªßîĞkæßÑ]\½Z€‘¼ıbùh.BÕ»ÒÔthOïœøw…¯l+V7«ÊAé4t6Õ›©Nº gø¸­aU^÷ÔC¯&)J‘ÖÁ¹ä{]×Êt™£æiæã!1:tóØˆK÷Sæ½Mkú'”tùït³r{6Ö‹¦D 5Óµ"]KÍÇy©
¶yÅ‘Î; ŸÆµä{S‹^T{¬–ˆø oxQÅlJ¯éTığ•Ï{^ …IQŸøÚÙ4®5Y}Œ8Ğpš•0Xû¦ûôY—šUú²›?–Æîö]šµì
Ş6[€—ºÍ°w®Y2úÄ¥‡ï³}á)mgıos¹µDÊ¾+¼úœìù­ì®èS4ˆ~Ì'LrR‰d	×)Èas!‡OUt¿c7˜l+­3ƒ|*'…$ãÁ¸v3Íì÷O7pzF…MÒ	&‹[°â€ ^ »W¤Me‘åmxöS‡÷(¨u ?`ÉÔ«Íj«]Ú?O,;f¡0 3OaÌ lÛàA’fFÜK)³ÙóbzK”K?ë ğV,E—I)ë c¯*´’l§®M8jì:Ä	gÚGÁ³Ïµ’6TÖîÒ¸\š•»qêN˜%S§w]•R®RQ¯¦İÌ6À}EøseÒKdÊ@ÀròhAÖl)ÉæâØ6ÈyÜ—pü¸UoöÖ)¹ô!]œQz5ÔÊyÅ­E2Ê ¥ˆ7Éıcïk’á«"! Òçƒ:„æ`hÃßÿß«õ0À¹xQr¸ìD‹ZQqŞC\nÊ@P‚‡yA¥ËƒWCåÇN˜­à=»\SÄòf¾Á…¥« xâà¿µáŞ^(–Y!ş?0d'"W›¹×\Vï@ÂÀHÙâA÷‘MAnŸ<ÎdÉƒ‚1‰æˆZ2¡Ë\¼¼QÕ‚ö¦Pf1eA}ç'’â#´ææ¢2LSeåc¯Y°Àøµ~7Í†ù¨l}û{Ó)t¨5¬ˆ?S«ÆNÑU‹«G§®êJ¨Îü°Åó~(!Aıv¸£ûoÀã²ŠÍ¥ÏIİDm 4ºÊmm9mz€ÓŒMr,W+«ÿ¿±-1“×c±tåÃ%FçİJé#¸Õw™ã±xXÙwŞoKù¼Nvß°2H‹lñ’0³N§¼UK}j¹Û£‰Rkóô[mŠ-²·š-Æç„=Ë›O(§$‹»€®eVß,ÀÄU–m^‰<*B¿j%½hL¼²ü>ŠqÓœ¬á…VˆJ³AİØô¦k×'½îGÒGBùØ”,‡àå¥š€[‰ÆM_y‹Ô‹øh5¨ÀÂ¶\áu1ÛõıÏË«iñv†««fb¸nàèpÏ–($7Ùpâ­ Cdn…À®uÕóF2˜âvY¶cËE¥'Õë"È†(¥¸¹*GÌ7SÁ£z7­EÁÒË¹z;ät¢Ü»)'Àä²R+ñp»" Á˜³ìs4J!H¹¹B6İBX ÷P;‹=üK`†=Ös›M†m¢Ä{,€ö,(©ŒˆWê =@ÇüÔE*FØn
²;šuëZ"œh4ôÒe²ƒ©†XaZ–İ/ºÆ*ïğÀÍ.\y8ò‚»û˜ÍˆÉã7Ñ"×¢gç—cÉ†¬¹Õï%JsŠm©(Ëûk@µ#ÿ”ñWÅÁÅJ8nd.U·H@è´¿L ­×"ñóyXÊñ)i[	0’:5¤;’@s%MV(ŠÅ®Ppãa~àuÈ±)MàG5Kd¿&zà§ğë
•ã<øà_]¹éáã™‡¬7UøeŸK]!(lˆ§Gş·ˆ–pM$eOpcOŸC¾#Qƒ±„éğ×Î‹}5§M³HU•6ÌÀR:i,T†qÊ—êvŒşY¿ÛŞr‹[l™–í'Z+@ÀéZ'³¥<z!)½& ö+üó^npùİÅ³WÒ§¼8ÅÔ(t„ÍÌÒ_Ê°¡K6V“Lc©=âOB·+Ôt¿‡!Åhgp8ÁZ¡Cä“æ«<ÃŠ)Ûš@¸`’|Ê¬ÇIğF­v‹å
§>mF~ˆ+4ªÂE/Şô˜ª¬÷SÕsåE £2Ğòšv©T¢H(Zk?Œ3Gnò_‹«ŸãŞå-ëó´vÊ>¼³³2ÏãÒ•Zp)gîc‘Ù
äE½FÚo/°4ñGú•Rç™#° ….ù­5?ÄzˆƒzÈçH„;ó|€¦Ì˜YùÅßĞ½‚sz™~hsäªqº™Ù '1œ!ÊŸuş¡¿¶áå'ÖÒê)´6Æ [&î¡*6¦°¤²öé8ºj5ÇšrN˜CBt¬ íû"‡XÆKèñ)ÂzüX;¦ÿœ'Äøå–ÉóÏ´b_FL•Sehß,N­Ö±èÓÎÂ©^á—8Æ-"Û[ï®’û[ffa…Có‚2ú$Î`^€— Ü6\ÄÕ›½~ Ï_úx´~s5Šø»1ÜRÁÍ#eÚÃ¢óå8r„È@"ÿQªÏĞŞQ= Ë‹äjÈÖ‰cûtºË²N'r²r=\®l¹şÁÂÉ*Aô^±‹¤NÆê?^@Ü,ÏĞÄ^İè”);–Å»…¦`Íz­÷óNŒyÊŸµa¨ÎÒ5f;7HxêmÜÉ:‡OGcûşÖ ô}~zpu ¢dJ†ZÿIJ¢"ÕÓmİÌÔ¿çäÖp-_¯Z’§3¢
œh$ù_â[şÂ÷l0ùÌ¼P³¸ÓÍL9ä®PÅ$¿‹v–õH _~â¸<»´y[İ˜û	Çştr¯de§€’Æ5Ê|Ë¼Ä3Ò³ÇV¹8+»¼ÚeúöLòœ¯!>tÑb(”jüv:[Qš–Ş_Q²Ä©êå\!l~.ìHCUúC)4}Çó.G¨!,SJA•‚7‰X¾â	kl¶OZfT*TH‘².?tR
‚©6µ#ŒŠsÔ¡jwÍ‚^”Ú,şëˆ²¶:^y{¹»:Ûü<;”ã»@ SksâE¢>*"Â;	³„éµ'¶´p…;ûş{?‹¥ÕàÚ^?¸Ÿ}‚~.ÛnësN÷‡@î8Ë_Şò™ƒbÑŞÿsÅ¦@á>çhñ»â1?>å¦q2Ò0]	íYë–?·o1âÀÌ”ĞÍùÁHâBİMv´}.S˜ªşTî&©¸±¯]~ü#S{i T"äÎ¨ª›)¿Ë>‡ i›oiqƒ-ßÌŸS]@©QKë†M
i7U@ÇšQ–ûoİùV\Úš`Å
Œ
"¦jw¼Û£@[Ñè¡´Ì=S~…4J¯WÛB†İ ƒğ•²Â–j1W5É!1öÒPÛŸ¢ùöY¬Æ½{òÖMË§µL… á=Z3óp}wÜ±>óÏÔù¨W=Ë`mâ›7æÔ¦Î•Ó§xn_aoıL’ÚG…6=ÃB†àšUwÏÎ} ³K3…
±`„loÎ Ó¤9[qlÚÓ×ÿ:6cK5ï‡EAÂwê}Bå,86dz÷(ÛWa* íêÿ÷ên\
¥9’Í¸;Îú!Uœ¼Õ7œkòÑ”´åd>3÷¡å¹òÏÊBÑÀAeFüA@’Õq x‹ğ^ƒ’zÅîyôŸ7åW±D·ëY÷T!ü}ñÁ˜M jæéÈÏw§º]Ñœw^›ZNHI6„ä…`å¨öXÇşDÒôï¼Ïÿ²@¶µ_¸È¦X4!?¬—õSÙ"1]œÍ•J™?Å òO$ıÂzzÔ|~]Ÿ¨‘8“K–p,÷I”\ĞÀ†L-VÕ¨Fz43 Ç5âÕ}uMèËoÓæë­»ñÑ`Rcf¡¯Ëı¿°ù>ú—ñ{ûŠƒ…UìAöª^®ÒŠ’UïøP<1RÖAû¦Hüú.5@:‡
ÍÈğÇŒxHõ…´Su“w¸@$ÕÑ€/g¯ì×´š)8àQ]iªFº2˜’F|9øøRCl`ŸÓåÉİDèuméĞL\]F’m91û..ït3º²ö›"A¨ÒHtk%áŸb¿E„çè¯à£>N{0àÇ'¿Fş‘†|4VÎú„ªÇŠõÕô¬–oI?öÔ÷wƒf|¤ƒ,Í¹cÛ°öÑà
Äèà¾X±“±ÊHçObU%åoœZ&S.h’ôtaçÎELÀèúÙ=”«/ı¬Lë‹İEA.f9÷³"åa0­U
 cwEËO~wóã;‹Ú¤ß4ÍH0¢_V È%oV“À¯û‡Ğ$Å	Å¤`ãTKô+qçÓŞ—Ú+e@2r2ìİ;¥øÑcãé”.Å…)yF-ñŠq—Ü¶¨!!+Ú—üáI©ı¾S>Â½ ªí'õü-mõß>vGğŞ˜ò´ºßgÄõÃõóå÷DíŸ 7>aåÁ?…J£w­	@KGex",±ËÂéjöô$Ü.1mÿNI¿xª\4›¦úÚtäã‹ŒAUÌ©@|v‹´ô%ôRâ’f‘SÂQVß¤ñmn‘ª-’&äÆ|–h5>£”%µ£¬Îs®uÄñ¸ñÚ=–oÔ«â4‘ï)‰Èh¤oW‰7õëH"@gé’”SP°óN%4+®Ÿ¶ıù‰…9·>…aõØÄJåfIèVsHoxN-ÇHg÷ê(.‚ì,»õ#±³|òzÙ<¬"‰€ÕOì6S.i7e`¼v²ÑD òMPŸ¨A{™h[";bê‚r¶«’rèb$[Vš&ûPncß0ÆÑ"#”}¯º5jgÜB²|Ä5Ë;¿&NhÅkÈK\É1Ü„İê—;«·Ûk¯xt>–G<äÌªflËÑIÚ%¨‹ö!ª`v:İü;ûaPöj¨Û(3}9	Ééİù/Ï‡®É»5<”·Ÿ-~øS<rı	ä{¸:ñÿ¬ı·çßpöjÇÁãó”›7j{ë!‘(£ÂÆïVZÚyÚ.®İøN2n|ƒ¢vä0W\Záû©ñ§D…Oêà¥ßpqğOCŸT^&vEtƒ©8¬Êôç-ãÓxãc„h0örod—P•>£ô›Ùdìûspû 
tœB'Ha»ÿ»t‘W–rò¸¶-K0«™¥÷Ce€O–kÃ—ôôÎ›å1“Ó¹.eÇb<íÊµDŒ‚‰Î}q:tgëoéhÿóˆ•+–p52j–úš:lü»‚÷›®ä\øøË•$v‡mMeÜĞeruWòÓ0ÑEa<"¦`‹‘¿¥înYgcş×	3ƒSß—WT§ECÇ…ÖtÅ®+4ı
hÓêz2!fWrRLp•8"øC·oàzßIÏ9Ê~û›Á»õŞ©Ù¨ÇÍ
AğşŠlî ôÉÛÀ3u«öœt¬üõ³_îåoáŒˆ3Ùº$AÂ²¶×„>µK,è$İ5‡	¡ÈöéÑØ¥y¨÷Q3œ¿åÜ°L³#ÉmÛàé%©c¥ojlf{€éÇ+2¡„>U®ÍŞ$R}/“uD÷ÜÀ·°šW™ğŒ¤”bÆÄåH¾So“ûIRHvy€jJ|.Üu†ùõZ€Kßuï„wúÙÅ´-&¬érÎdzà¡ïiwÜÉæ+ì;JP«áLaÖÖ¡—›µ9M˜dö[@YC.êñß3èÕxz}äˆáe@ª§@¤äâØá¤¸™ˆá¯GˆõóˆX½’»ªdÌ¤T†x×Ó1c‚Â,Şäcİãó¸ÚˆØ}xúG
ü„smHiÊ2YÖ¼8|ÕÅ¾ÑIÙ;›üÙCĞ{y‹ÇH÷ê£àCŒâÓ…º«ySêNõÉh»×t™S"~@¢$)¥­Øn¨´~ŒSKÇâ·yßş, ²ôÊûR™W•57Œâ¬Òfå€ãúFy\“=Ïåœ½6È¬‡Œÿ„`wVC£II1|Ù š“ 5¡ÒÀÜ°'ònQ5Üå-Õ;†Hªú6ÒšíUM^<\ml÷¡úò{­ËŒV­%€,Ægœ¾:Õ ‘$ª@•©Ö¹ñ°L2EwÄq˜ï~‡mÉ/ÊßØŒ"yh~fş¯…™fïÃ‘ÕyÉµ†¸·-•3#òÉVåf¿¥VĞÍğp°ä²å´¾‚d%ÜÑ)KÈ©óg}T´¶VKÃ"ªëÛ¶-H0ö@dw^mSi?ÛÏÅl"Ãp_:o»F÷¬êj¥îwß0Lé2o--G Ä¬}@5ÿ¦³€ºœ~ÆM½»8=*êÕL ˜p¿À®üöWÕçè…Ò˜;©^ndİv-XŒ%Ò&}j‚E¹+ä4šnÒÜ–É:>jñÕläƒ¾Q]Ãg“—#µ¶ŸVBÏSÇ„®2¦¶.ë ^Ñ¿Ì·7›¢•yJ¬zŸÅŒ]ó¹»rÔê@L¬™BğüPæ"c¼á–üû×Ÿ~r¬#aÿY»@µÒmñK)Ã×Ë-¤ÖÅ#£KÛ[G™Ix„zî0°¸ù–Mà9ÿäÛŸ©Bâ‘¿Úb$ÿ”§Òîu’áAUW6À!î¡h~Øš¡‰#»Æ>Ñ,¯FJ{~)PIã5`; ¢´–¥BIÇ&·­dŒ¢ú'wğ«5¦Y(Fâı·)‚¬†ß~NtôŠ^ìî^X¥“:±¢œ@­·ùÎaâï…“¿—§×‚›¿NÀÓˆWqæ¨Å·-h™¡Şx/µV“¥²›,ÌÛ;§	ÒwÖÔø†Ì:ä"üPN9Z¤ƒv¬Û) Üzñs‰¬òömCaü§RP*l!†M´9˜’Ï"]ò•ñ¥İŒŸò@]¢*($ÒRJg˜qsrV÷ğkT³œı {ï£Pî,”Ì/ƒ½¾k‘ml‡BÀ½ø±¯Ñœ¼è–·a¼Å/;²é…xì]İyš¸ÊèÀG™£â&è(¶x"ñ†ı]öLç¹·r¾f[Jô/÷ÅH<}|é@ï5:OíD{…•…gùÒÚo"}Ìû@Â>Ò0³0a¼dâíÿ§Šó*ÕR„)ÃQ‚mí!ÿV'>käTZÌ¼ºGdXBb(£ZÙï'Væ!=Dÿ_J8nq‹DMYUÒµ£oƒ¦üø	øXúQ>¿yl+S\Gˆ!/P nŒbo»«z:«ë 39.±”%ãú”¼ÓNìh	Ùğ=ŒÓçjcİP¼%wNA&V'ëAìNlÅõôÛ7ROHíg¯&Ó±8“Tj«†—w)eÚZ@dhÔËgD6ÌTÈñ]Š %¯ĞèÄaeÑ”·EŒñjìÿ²XóÌ†áãŠ×¥A»ÒÓ”ÿœCØçB ‘İÀ±ÉWCìÏ¦±~×ïP­2û]mïè¬	Ó½°£l	Ş—³Á-\hÓA‹Îè“ü<G‚óµ“Q–¼¶—C»Ä‹V­´/á2µˆõìäÌH$÷“â÷-sa¬Ì;s…%$=Pñk· B÷y,ç!1%æ‹/ætJj3,sfL@Ã»§Š<EEöìIô÷ê"ŞÚrf0qí	èSÃ[¦¼š%–2ë}lĞT=´±½	•‰D4ä:¯-OVÜ¸K2+[õ„r<6@ò6ñáÍé©§Õz„¯ºä.C¼vPÄl#İq ‹ÛÙ_Rè©YÒ9$i¦Õ»¿Ğú^Ë‹uØÑĞBùt¿·’D«éÂP]•Aç+._ÁæÌyÄ:³pYÍ ˜
­{çÕåª	xóZé6$3¢á|lÂÛÒ“ÄŠujAt•õz9Æàùrö5<ñ¦p ãÏ[Â‹¸˜ ÖïÀLğÆSC¬¹Ç€ñy&•ôcÉ·GëÑ"PÚCé˜Uzg3üõ×‚Bô_ÊìÜE_§#Şn£!¬’ËÉ¯i-¤'Øº™éˆ`º’Ï³È-æÌ/‹‡¶YÒ¢$§^ï£©›Ë#¾)â´æDèyÕ¿Š®A&'‡ªó¥ëPsõ=N[.Â¾h»Øíf–¹C/öÑbêcTgç•¿«úÂĞƒà ı§5‚.ÿ}riïY	 €ù+i¡¤ÔŠ`¼—Ìh)ø¥ ~c?aù*ë>év_7[çu]ş4ªj)ˆŒcH]Ö#Ï‘(	ô¯hÕfú\Ï¡¯½cX:ÇMÇqrz(ï Á+³'*{ÅÉÇÁó<&åUgúz´ø±Vë¨Ğ{é‹!ÏŒÿ+I¡T,@ëÒr `‡ûÇ¸¥$%—%Ä›Xí)D¨¡Ÿ‘Ã{õ^îzš<äFœÔ`ù6'òtHv\h±#Ø)–1;~62½Ë•]µx§ÉCRRÚøn?Å4ÉIĞ)\0D‚cHµqşcáèGŸ¬(ˆpØáê(Á'½ËèjàcZ¦«¸Õ]şÉçŸ-¨?v	şÙRQÃÂÍŠ›]í·õ´¡Kvã…1‰Zº³€(¹TD†´xìøU<„I§{ÛÀ¶™ñè—€û½ ù/¥%l5;‘•É™(]ryº¦-+9öáH[ÕK.n" ï]2¿Ø¢<>k‡f'ÎòÏ±d²ÕcjU¾É¾aôk±;Eêh§$·İ!iÚ1Ç•I˜îçº.÷µ=¨	ƒ Á]ÌVªg:ªZd¼‡Â‡¥×4;Ôfy,ôÅF²“â<%<W†õ«A{iñ}$\¹×¥cúœÈ%‹:¬IGÙ6„¢í‚Ú RD,ÿ1 º=Q^ä‡³;öÿkô`Ë¤AQV¹X¹{ñÒh—©LXŸFîüi.À>æ??–¥C­_Ê‹»Ã£>xLÿ Şù4 Sf¸še9ß†XªFó$j•Ğ†Ó¹IgÿãÆ@ ¼/íB¨!y*%q»|Íj"Ò$ ZÄÍéJò“\ƒ¢¡¬í×Xè\9ÆİÈDßíx/!¾S5²qNE“uçµ^ÄtNølåa*…àÃßÇ%f:¢©&±Ô]I‡xåğ¥r‹*]~>w†ÕÄU°wö4è¹ÛáaôTò*TÒ«l«Õ­­"TÜ#Lt>1ğxÓ¤ÑØÉºkiq³µÁ%şi›g)fC°¬İm†}Y˜|Z‹	ºLÊ:#‹u=
D‹øù6=s¦óÎËYeÊ§šæÄPÁé'Á@'#µ2TÄ›Ëwîy‚"C	¯«KF_² BŞ»~Zt²Ğp5ïŠ†·?$Si„0½ĞN€4Ş·
gKLš½'R³#ßP¿>Şş5å1 XâTFşŒ–§Ê¤ËåÜÓÙ\ÓYŒÖôô]‰pŒhV÷G<)k:u¦ÒŠ‚D4åËâ·©«õª¨ıJ}×@7òL·ÿ½ƒğ‘NøQÍXÔèè“Åb\Ã÷@våZÚ
ÒŸš;jVE]"Ã.  +[Erd[@ƒëéWú!µÎˆ¾I=†rv˜N¢©4³1š[¤õĞ<ã_A„¾>¸CÓìŞÌ®™‰Dkš§PÁóJqÁO@p8ÈäÜÁXÏP‹ÜeÉi£xÑE/·ë“ı»¸ø§õğº¾ñèH2ÕJÓb_*¦à&«nËûäêöÏ*¤Å#gş
dª‰¦¬Yñ=?*åî”ƒ’dÃøcó vF]³Õ`„@m{÷dLˆz¥.ÕG³JÌvÚyu£$A@8Ó8ç6 ú|"úMHîp¡Õ&È+õIöÆÜîĞ…^fàoJmrB¥	Æ9Ö.¯ìÅ"2LÕÃ#õ_%Ò™"pKºtœ_cJ
¦££qû_€å8ª½§(9ün’ÏÉÏÚ0Zß@ÎN°A§Ò5·”¥EÎéµ É¬ßàN+SÏj&#ˆ‘UJ·ˆ-ŒêØœ®o/¡¹èı*ÎêñIĞVßªTô÷¯S™–‰:ƒ)rŒUİnVœ¦úÕìùÇC®Ê¼.&bÃJ}ò±¦X·Ôbƒë18Ê™¦á2½y‡Í‡¤{Œ²Dº‰Ú·,6…ÅÏ¿6CMM[ñŒÖ¬àu €¦®æç".EŞn
áVï6'ÑQEYƒ+Ô—<s›ò:ÂÉWS€6ñ±W“w%CUÇ<[¸ä²{g¯×ø£H Ô
4ÎÛÚ6´ZêªTS1Ä7?º…~ºÀ—±NVyu,ÌëÍx­ÙtíôR—rgÕêñÒÚUî=p0¦\2 $€€äñ§¬×¯~'”3ùpzĞ•¼‚ê»±~v³óÍŸİ9p;KG¦<œz²"dıSöØÛcxBd‚§íè²Ã´jÄò±6ˆcJS_*Ş fvÙÈUoÑ²åWdòW¨o°Æ)U8IrX Ô¯\µ¸/¤¨~#léIpÆùa÷®ôÖxç5;Ó'Ñ»øË#gøÄœÓG5·Bi0Ğu£+ºš—5xÔ;×pÖqÅ^i†Ëï\t#—PƒÄ[(ĞõÀ‹çµGˆ#)x(±ª©p]Ï[½ÁµêÂ~“ùHføífÿ‚4=Ö4ÉSö-Évl…F¢ù•ü#nÊæy!ıÂƒ¿è8—Š;éa&ŒÑ[ü–ü9t\~ÓºC&Òn><Ç<ÑLÚ¸Ù¦«5cêçÓèA«‡·e,8F ‘,,NÂÂú¨Lã5ÍØ'y¶åÛÀV ùp`Ş&§ôğÛ“ƒiy9JÚŞòİ/yKÒù®&Ğ±€LèBÃù’×B}®{¾?Ò¢<İ¤ÙªZÊÈèšÄxrW-Uo«îËÏ5<i˜_ÁïP¶”ŸÖ"Ï˜ôB·À5a‡L9â:`Âä;Y·\)5o‰—?…S™Ÿæ…r€Eİ77Âr#Ì#U ±ğck-lär†âÌÚfÃñ»¤è®#É² Š³O$V–#½&¹«¤²çß
ÀC·pç*Ä§BÛ•ïq»X­2¶…NÜæî²ªH¼•Ô³Cøé×%x—“×ä¶^y‡iˆãÖëdìşõ\j°Íoªá…+»+8q4,jôx³;\ô‹…Ÿ©·³Çq–Ô¨b‹ÜiÚ‰—¨{¹°Jÿ*DÌ*·¸ˆpiwGİ5+Î#oèˆ:2ùoÚsãÿÖŸ‹!·ÛÒ¡I>ÑÜlÚyS'ô¶©Û©ñdZªW|"5¾£û†r¯{¦Ã& NsÄÕ‘Y ¾ş« ünd'	ÂÏO’…qÀ‰g¶mÏÕ
-Ñ.à7zYgí5Ã•êK5¼¾Œ.ğ9EA¢MÜ+î¯¨gæ`m·ÜaˆÑJ¡Û5šıÈNbßæH‰bÌˆk±¤èW˜çYÙ†Éà øêÿÀ*³©~£‡É:Îj÷¹€Ä|©šß‚s¥ïÀ½£?qOÕP]ş¤òö…Î:R—¤çGgçìÁÙLYoÓîáû?0î.Šµ¥4ÕÔd©ìåÉhFÕùOÃà°¢=ş®úOçz—vÏnò] FbºÔ°yÁğ†‚Øp/¨§ÎJ¿ÙÏXØiU$Jì6ù:Xâ™_	èéf†ä“ÀÔĞ„ö#€“=sŸÙĞA[’÷Ùo=gç(ë‚ÛqÏwĞ Ï§F”ïmä„%é úÚlzK<Şú»ıêè‰ı¬+Ïµ²Á{ûïi,¤ÜOíK§Òp@yüôV)oKåY@äŒ\ûï¹äœ§f» 8ffÎÛ¥_8‹Ø’†ˆÛPEqÕúL0œR-Ó	@H	ĞiÀı ìca^ËêzÒOb–¡>4ö÷~°šXBD]šÇY‰/!X
CJ~ÅŒ¥ü¨}?Q‚Åù}`¾“'oyÕ]0Ÿ­“s¨}šd¿IÔÖ•›´„FîHÜñ^Ó¬‰ú*WóNvzµÔudü­ç÷ şáç#ê¿içµNÓ‚ÛG5-<¤"Ë*ª0V ~Ò\pÙPğ@Ö¡V¬øœ®d$€zíé(µ[é¼ñ±ûÁ8¹}Dít[Tk<kò@«’Âu¦Ã¿ëÄÂ\ræ§_4„öãC 
«Ïª÷çş,ÈŠt HÅûWR)2k¹ZH…KÒÛb{7§=Ÿ<ÓuVó´5KÃodûûš'"gm<>5©¬{Öks{TM±õ*]¥Ä¦ç^¼§­m²°FØ¢d”é‡„,¥'8vlÍøğ6qƒ±¦7Îè)®ADæsí«ü:—û›uõØîÃâZ¬ä´…¬¢CØÁ'©Pq4Ã	àSùå¶Fuš>n á„u@­­1Òÿş¬våôK0À2ìëò‡ú¦Ç(âï¤]h£Q|¥SyæOº›¯“Äçë1â[»~è‹	d/Ã¸kÈ#(¥R†xÂ"¨ë£UOš§÷”×)¢×İqS‰ïÂU²YÔ'Œ1ì§‚	ªYvE³¢©™Ü7äå§z¶lEş£ïãC9N¨1PŒ‹ätœó+ö¸ê$ç¯¬AF9¾%Í0}ÈÖÆÄtG™ÁV¬ w&²n|Xké‚İ–p½y¶#>TPÉE›ÇrÙ,5O¡+öN[ˆ•$Ã’lÅ4>G<3×ıCşÎ“¥T~k(Z k­n~4Cj—»	0´“ÌAº.éx‰À“dÉ©BŒŒfW™0òGØ.JÛÅ\PŒ3ÚcƒKÛ+­Âìk¬Úö´äC\Ør¿/M)8“stâœ‘@¡•Û—˜6§«ôÚ§V
BsÀ3Í› ‚*ïJLÇXĞĞL=c…ú¯*¾Àú“°0+«¹4àFÑ…-]0ŞNŠâÅ’ÉÁwa©jOè¼–?7“F„>?9TŸs"Öğ—÷Oõ}M035©æ&aÓç ¢)û¨c(âÚg"†ş¶‰Ê²º ‰0hşZÄ¦ÆÏÆİcRe;SCcE=ÓW¢Pm{ÎhÆÈ':©9+A¥ù—®„Ü±¡˜':T9»¦òFüÔˆ1Wø+W¦?·`u¥gøH—#‘ûúP:Zä^¶”	jn8D’—1Š~ìù6MŞ8¾úvt	€‹OC“ÃÛ–Ì:o¹Tö’É &ÊÓ×µ²Pìe© *È½gUÖ«át8ˆl¶‡“Ùî¢ìzË£°%ß”0U¡™9)9#¥v=}k9T{˜½´:ó¿úÁÏfıípİÄYÌZ…Î,OğV‡·ûJU†ã{¸ŠÔ×Û3ğŞİ.Be'NµËcÅ5àÑáüV„u¨BiZ}6N êĞkZ>	÷PzÆ[Ë;Rjp+Ş“±°z¬Ò“†„ÄtAÖ>¥eg„™=P—I8Î˜1ãSé¼ÙÄéåLæÿA¬åã#÷}k“mc¦˜wÿ°O‹—·•­&Zn ìº íL
]¯‡¨@“*½‘Rc±Éêä¥æSkæÄd¸°ú.¿±ÇA.)Ïµè<ûÑü/Îuk±9sCqÍú•èœßÆÇÍR0ëe w·-
jxƒòÌ™n)çu+×¥¾KÈKÒÁ'µúİ³QTÕŒ ”<öô;×Å÷,@=9ğı/¸g{Ø‚J´ïëœ3ú’Ç¢ Ø-¾ÃªMë5zÑ"Út¸1G*1Øt™ÕDn~9À….2<Üc½v8Q  hÕ ;•¯T`(äñci¶3Æı“èU¨ÎÏ¦1AH¿x³JÁ1`…äv©ÈR*^³…- ²®†Í©ù<ü}¸\@åMaˆİ'º.SU}Æ İ=Ù«Ñ%mdgLkÈ1µu˜{7HA+·c¿ãŞbé»?İÿ/@Í÷)Dƒ%tA»­ZŠ{Œ¦Wa´2è¤Çˆäù8³F¤#´C”Æ9+cxä©Ša5ôIÜ‹‚”±[°/t‡Õc„ŠãÌµíµ;Ö1ÿ>¬^³û7XES™×¥œQVÇˆ0Î•ÍHw—µƒ%$´ËÖËá|™ˆw’ºk®¸êG H=áÅ¦“”%­ªó]ÒTD‚™±?ñùÿBÇÀŞ/Ş(Ò-È¾öF° V›•V'ótTÁĞ,›ÔB2ÓÜmF?« òPÑ!ùù®ÚLU¤'õ{õC˜ùiF+ø22üĞrq›è/aÁ£ÔùçFhık=ìˆáÚA
ËÍ†‰R?×6b`V‹à#4	¦PÇœÙMgóÜŠ”ªÂ¦5Ê(ÎÒÅlÉ˜5µ#bw×ô[.6˜{(’»+ÀÑîï<­uOHVÄµT…8FÚFâ—”‚µäÑÓë&_» éÎ¶Ÿ60òåZÂµ¥ĞEZ•x%Êb
çM¸E‹Y¼“ÒQÜ¹¹=åÎÆd´êùÓ³ù˜´Æ(rPvòDDxG2™sş[|„²ˆ'±<b×ş–`GøÖ›jÖ3u2)¤İ¦\1­ˆé´ÛşÊ‹d¥¹kæÉ¤9i¶Ú£»`‰ıàVÂË9*ÏïÂÙa¶V€ÃvøÀ¡øÛŸÔÓ‰ógBi¨]a°r‹B|#¾/­•Ñ¢)Ç’£0ÎHåu¯z­‰¿Èé‡ı£ÊºMj…(J‚.åğŞª2î­Ó…AÃ¥3fßS›õ@şXå­òV¦º9ºå§÷i këXÔ…CåYñxz77ü»H¾èj«¶Å¸ëedºpJaÛÌ|¡·›Bt¥câ^T'’—j©LÕG’ü-S}[KH‘?>ËIŒˆ§ûL9`ú-†:3w®`¦×š¬Ä)±‡rãâu· B¤rÁvà 	v#-Šğ<ø‚#\¯ÅY2ï7ŒåÍTLÅ‡¢Fgúø$÷ã0‚ÊÉ"]íÛ6Lô¨Â”[Ù%…6#vx,õÈMEÊÃPóEO(7ÒuE d›fæ~÷b3IvNoç€ÿ`¶Ù‚F`ššÚ¸ş :üH?0?ÚÙ¢ ÜúÍ®Fv&rˆŞdPÀD–ÂõáÂ $ZÔ•Éi3¹"±çÔR=¨Ò¿g£Ö‹Oeøš8SM…§K%±KIÆ(Ó‡¸Ãj}ÿwª,ôõÅ²ò¥KgF¡y/ëÑytÚâĞî1|hİ€.'É;c.Uƒ y`k\EÍ‘Z{5ˆÆM½}à/‰©Ä²ÈIøÒÙ´$*ı"Û¥bæ:`²¶âŠ°'+y¶~8× wXäÃùèØèì3Îó|wdöîBHèÏr?„tÙ^
õùd½.Á:{ülŠÓ”òp‰8§÷ÍX|_ªÕ–·ÖxœsÎmëï;ñÚÉÃƒÓô¼…Š2_~¸§Ğ.¨÷+î-İLï+-ô‚W	5¦NŒYÌ/d£+ ĞšÕYÙônø!ö“Q~ùO,UÓjVØ‘ñ…[Z§¿²ı£Õş®¼èÇÊ9<K{R™ŞÄÕm0Ê	·rÓ4®À5ÅhË¾`wÖÈ4Ín©Añzí8|Ö
'dñ±;É‰`	ù¹¢è¦“es¶7èPp,¯›İg–Šmb¿,ÖûÖ>Â Ú©íadÚ†¥è·¬~8ú–!7Çge
öñ¡üáäŠFV±c}’ÄÊf˜Q^U‚ù!]_ì¥–¿¡ÌÊ€²hÜÈ©Ë„c_‹”A[O1Ñ•nŞ¦HÉ„½ï“µMä°û§´pœª½oAMzÎx®²åü	„GG¤:~ÚÎÒe×ÒzIª7SúşôL¶•ø$rO
¡ÑÏ1Í¤8U±öFp«Œ+ã4<ÿÔº•J“[;PGì8Gí—#ÆÜp+p´›i0l}öÓğ0Ş|ˆVÍâkÊğí¤v­ßÆİx`{…ïƒô¸XÆÍwÄ}sobÍØç‘‚gÕ¤_iŒØ!JİÕô´íÌ U\¢ú:+ğ**ôÓ2T·à2ê¥c3NôEhör[nîñÜG»Fzc„=Bµu˜µèåå­_§Ò6ór«µíE²×§veê¦?@é¢?tİ‹:{å¸Ö/fßòb¶Ğòå™ïê ¢0âóŞ¨S&}J™ÄÊƒR¬ª¦E.Ø«=“ns§dzD2edãì}H»4(ŸRdµ1²@•‘ß¿WØ„]ğˆ÷°L)Û6H7ôÉ6¤ ”sÍqh—æf	®ÖX	ªR_°TJºVÖ¶\$LOëIyïÓ÷è³4 –›OûÑ3Íl-IişŠYrú1óJHÙ´p¦ÅÂæP¢ïP¦CCèŠ/ÂjšØÔó®¨Ö€xÉüURuŠb`pÛ×²ÅÏ­ö,Ëx›3Ï†°5âÌ·±¡‚ó¬pŞIlºY9;Ã=…™=pØ“{`5´¯Wo´¨DU4C0•Ü·™,;í´˜Æt¿cy:äKÒç€Çüë±è´ş€T6ä>¦$¡³É‘ä,œ»hÒšX ¼¼HdzÔD«×ÄK¦b#‰aso|ƒ
-5òáI'—êÜ#şÖí%X}iQÕ`¿ãDcçÑuØg	’½üÕXXäğ³áùˆ.vë¥
‡
1Í­7p¦ÓËÖ[ëÈ>óÕö€ö€Äf ¯ºÊpÉãÂ:oÃ„TX„«OJÌ["#{ïPÑç…e‡J¾!pU]şåöç8YRìqK=gfVíÆ²±ÜÈİ´£€OÊÚÅ”şˆó‚Àˆ~XÀúá5
’İ«t?R3!Dğ`T£7\ÿ”r-‚Çx€S®İ€–ö&Ï=kØ/#^…eÁËÇd3uŞFÒªÆÒèê9²jáöÒæ÷3à´>UÌ¯¥WG–ŠD=ÊÛïèp)SÚ—7ˆ‹ÿ%l- ÿZËÀËô.e‰-f5É¹éø¥¸dæÀìş!Ö› ’7€î¿,˜¼+ÏéAWÅéÏDa†.^B3^0R>#…õú~@ÿiĞ¼²Á§|Ê¯Ûº[´Á£A^×íıp}ÈíßA€æF§èšœäû‚RT'^§õÆ†%°ë¨òŸ
#L½øò{PğÃF(T³ñÁy¡ú <ÿ´Şpóê!Ãó8­µï1¯İ»ÿÄ7ìÍVVMÔvÑšXp"7àF­¼¥_:Né)ø…4y1-¦ú13Äæ€§rtw|¸€V%&A!—õŠ]ŠheôAi?¼šj•2Ñ“†úh‚á×Äó¤"¤òä§²w´ï‘æXS€`Ç¹ò!CˆhN÷Ò€VØœİA"ÃM©xÍ£œ;) ?^åÑòËĞ²HeuèÙ<½F«ßW\…o5¨oxœÛÒZú´IÜ@‡åÄñKç`hQ ú%QqÔ>¹¸	\s^ ïPpƒ€)0‘½¥áçlq!ºê«œE¸Á·Ï}İªìEÖG¦Æ
PgSo§¹[ŠıˆcÍ¨âäãe°’=“ˆRàG Qz³r6ë™¬Kÿ¥^KşÔä   ¿Rï¶è=C ß€ o†æP±Ägû    YZ