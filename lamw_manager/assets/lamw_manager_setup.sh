#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1756486782"
MD5="d383cdbf09371df3e1058e502fa61d64"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23744"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Thu Aug  5 14:39:20 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\] ¼}•À1Dd]‡Á›PætİDõè¾„Få©¨¯êZ­ÎdÁSŸ´“¬I0'>¨8¹Ô'‡‚cÆw¹úàì!gç¿ê‰*àHÏ¬oà…P¼RÔ;)¦oOczÙ*â8Ä§–Üqíç&Ê£ôj»3B¹şÊÄÅ¸{$à:±Úì¾°­•ÎÁµµˆÇ ³ÔÚwı„ÁxrÊÌ©öZ;Ñö‡ƒ•É¶ªTMññ9+?.HÈ¤F]¹B0š•æR™‹çÅ"ZOPHdƒïîy¸E#İ‘ş1ÍZy
ï&r˜‡.-õ­QŸm~ˆïzé,‹qî]­{Y¿°°¾<ÀË‹x!;Òö²sul…ÁMÁ4šÒx^W:TCQ‹©Ÿ*î×Î¨¿‚`		9¹}Ú¸œÖŒ}“X4éªúI¥À
^ĞF£‚uáÏÀÁŠ=É‹ÂmÅ÷<‚Å+V¡ƒçª`rta·È’’Le3³käìµŒĞ‹Ò7˜¯¨#ğ†Ğ^Ó¾Jä¨—	S£&ñ»lD‘€F9»d¶¬±WÊ§Ï`O,’”öÚ…cØæõÛcÇ7š)–`;ª3[4Ö(9€Û)ŒŸ+ŒœND‰^¼IAkçuÒzE-HRq—×ú­ £Ê¸Q›£åüµ®Ú˜[±NîÃ# ¨Nõ×ÖL™™ËiãbÃIÉuÁ3¢UäâÂ»,lCÄ>úsÍGHb;*Ş•‰ºÛŸ|JôPç©k8È©æ4wÌßñV³ğ÷u2c‰ØGr®é0|b9Bßšè5ƒ,M.ôVe­	´ªP¼41DwññŒæzÇißm…\Í7Ã¾Í‘R×[E^ƒŸ3+ƒÙ]öš—iŒŸz¿,,·ª±tÙjx)Ñ5	G½d6ÍIA¯®p^RK”ØÆd{2ÁsÏÚò0¸QqåàEÄª>^tšû)d©ª„ J¹¬·0Ë½÷ÎJ[ı´h,Á¥ÏBSàCFõpÿñX”éGkiº×Rü—€f„E#_·?BÉÑµyİ1ê›©N-ÆèåT\@`o7,ŒÇ4G×j´% ·*o'8ÄD‚ÛyşÆâcMrı«0ïEŞÿ~¦9oİc~–~!ßO¨p*hG ¤Ş¢Ì” gãÀO»$Ô_ò‡ûÖÊºàÂJ 7ÃëYŸPˆĞF'(UŸ,J¼"0&üqÓ×õF²ıä>+¿¦“oB	ênôj°ËùÁ¢é-ÈÌÈS@(ğu~è®ñ>LWLD¬Zf g 	
€æaá:Ã‰FÉü­'\¯1ùı¥½Ò	sŸÿ5»é|Î1¿"AÈoOø=àaªë\ìÅ®¦Và ]ÜOŒŞ/CØ‘qşàÆxbôß¸í9zš±tx¿W?ŸREÜØ-õÂô$¦äŒƒjB½äÓØi-d÷.ëa+P‰‰ğšNäÆ'¨å]“ˆÈ ÜUcØš£@>ÑÛ)ü²>3)ÿÛÄı/W£°wZ#jkDk¢D÷Å"o§°òP‰‡?;«)§rZ[××föR„{ŸWÌ–r#õnÛ‹â•	y[ëÕÇñÒÎ«ƒœ7–%“ùæ·“´c-º„-V^¹C/3Ù@¢ALªqM2Ë˜Œn¼A»a-VÀ‡a3ljçÑå½C4(®5…Nx”´Ñ]’ÛJã-J"1¢+—AöÌä^•¡Ñ!0QV|İr}ö`EÃQOOÜn•¯ãŞ[ø©’Î{…¨ –6†Âwğ+fĞq@cbGLtş	ïÆŠİ
f ƒ–wò½šIz_+†?×·Rœo Së:&I3‘¾5ÃÅr´¸)å)j)ˆş•”Û^e\ÆãF]|Ä¾™îá7².Ê@èö ˜‚J‘\"ÊÕdÂnõñ¯OÊ¢²";‘—ïTÌ†y©ˆaş‡ĞùƒGÎêê¶/ s)]dëÜ$ñ¡ûÃ”«#BÎ-a% Ü¥ÃK°r@US®•Ÿß
ô"QeòØ‚ÍUs»âdÁ:2fãµTa¾ÏjÃ%™øÚš`ÇòFh´”Oö'Óe¹ûïËzp*Ô¿öğy%¯wÂSHÍœË‘èİ±È2‹}¸Å®ïş„¡lÂÈGx!bN45äĞq€àë"¶ÂµWÒDıöA— pî—­¯5a×Ä)TEò­…™¥,Ôwb	k¤­òvã…•„ñ­Ë)v9N­¹r"‚ÓgüÚè!Ü¨ˆ»pC_˜ŠYîõäõ›^rõ\kë1®#«ğÒlÜù\×,€ÂQê×¢hPù'<ĞÉ;xP¼O³şH³Y™ØÖ‘ËË;Mäï f½‰J<¬äÇ®	Lğ¨Š]ªÊIœ…ÈIEc,z;!t™©NßÒKM!¢½€DUƒúlÛ’ Ü1Zé©ó‰ãUo›}o¼pqœ]›Ú³r¬İ8Ğ÷®3¼x¨®ü°ày„ÙAR^KØfP‘Æ%~Û+–ked¼€Ôx»ú&Ùª¸Ó€T$Ï<7¡ÿ- şç»ëÎå³¾DÄf¹Z·% Qê8HL‘~¸ÀŸdc¹$¥Ú£8ş¼â‹`GÀûf¬³Ô¬‡`cŞxè„Ô4jsrÔg„zùíañeÜP$<!Õ·õÜ	ûEÂU¦ù¾ÆYS²ì¤7P|¨{îèÁg“[<“ğŒ—{ë«wÅö—°~'–ëxş_Ôí£ímĞÑ;ZµUPÖ@&YHİû¨åDøõ‘Q7z4xSåî0åğu
Ó;›>?Ñ_½á~éuY”ÆĞ‹³–PN–j OĞ»@WÌlá‘„zŞ¨ë+oæy‹èO‚¯ş¡ßíiB‚}²i‡˜3|Ö¼n‰ëƒktÚû„0‚e³-*¥ó”*ñ~³¦¤[=à;¸SÔã7³÷iĞ@@f?âm± Zá-ÉNI%P€²)»TC ©Ç«R°t;ò@Ö?Á]MA!‰Ÿëé‰.nk?õ¾Ñoæ1‹ø:¹Yªüª›nû—zÍÏËXÃHÄ~37À´OÜUÌ×;S©[èıáÄ‘ò–|0ül:O‚5¥dÉÓ`8ºvy®Ãñ¨¡>¬—;ºc„O>}çŒ|ÜFœŸpäüoçÉ9£ü½,à«·×ú•ûçä€„’jì©})¼‰Ç‰I0=¾°¹êÍèlå×‡Æ42{­
ÛÂãÌP^gùYöÊîŒV›Û,íLÇf=•©.éq¶EAœ%â+ôá«®³c¬kn5ÑEot2ZÒ„Ê5A\|[‹;GÌ´)İ¸Næ½‰Ø±y˜sä•t¼Tœ)õ|Ít6$³ÜX‡|7ô·øõ¤’¶³ğhiaäZî'GcˆİÊv%‡8­L¾==âÌ¨gƒeÊ~µgc—Ipdïgâ¤º„}‡jäŒ].üGÔÒ
=Hş#EjTJöR¾¼u$†©±–€Â‚ôÿ¥tGè™è§ñ2Ï9l©œ~ùx´º(Q  üIOÂXªƒQœçV%ù'ç ¥ùY3éå„ŸlßŞ\ŠqÂR Eı¯^IÁ$–`e êéKé[¹ĞI®aSsW78"Ò~‰tytvçÑ§uLİ)²ÔÇØ®ÄÜW`Pc/èt®ô]¤üô˜š¬,Xæ=+zç\o¨÷Ÿ÷]‚°›uq„ûUÒ¨ğğDF0UÑóR¨în-ˆÕ|ED«êíL0ú‚³*‘ùóş³İ
e]¥úa·ÎØ—·¾¤ 4B–Nwj¿=çöÈdà¯£ìŞ¢ï#Ò.ÄÁìA84_íÆ
ÂÕŞN(6¯ÏO+££^˜l š¿ëœ<8;äÓn‘Tw°qyb®ÂŠÂƒt½}Ìeä@‹kÆGBà›ü°Wï~£‰¡MJ¾ƒÊš—n[Ëxó%ïFØM­œ€ÏO¯YRàÚ#1õ:+ÔWe2Xh‰Ã‚­´7ÊŒÇÛd(Ïk ']H÷næ -@}²šƒii;¨«ËH”
¹8Bá·Û,£‘í}Ùÿ4¸Y¿ÛÓÕş…\ŸƒPÌ¿:³ô¦Á¼½f4˜T7s"õ‚b¼ª¤3JZí#§Z*(&äŒÓ³èU7Ê›ù¦ÊØ6Eşèñéæ=ú¤ŠÅèµƒ_k;¯«©›ôºÏcûÊÔì4´ŒbÏ»·²É5+ÍîĞ[+†)Ü’aËêI“úÈ­¨A+_„Şj<B/mè{\ƒlËÏËì)ï¡Ó.Z7ñ#š¾ù˜®’’ZeW`Æ€PÏùí¯Ùçdj«bpÀi
”ùÇ®„|dº¸Äô72gÌúdY!®ê0ì)•:_j×’£òÚ€"ªçûé|c¬‚n‘6®£îæerFà>v¦µ &ÉË U.xÌ“„ŸŞ!Eâö W¡[X3ÿq÷—æÃá‚ˆŒ´,¤
ît†²d
9;—¢YÎÁ.ÌTÏA 1÷b€ûDFî_OóB5šNèTBá{Ú[õD¸nãB°u‡©$ûğÙ5Ê‹÷¦şs17c3í‘‘ióæA?®–ç7_vÈ¿îlDz5L“ ·Ô“ïLøÉ“†Íe'·¢e=2->J~:ŒÎLûß{õ§ÃdÅŒ… ˜üüuA€…‡Ò»xB(GYÀ–Ñıäæä.äzûKå¤èH@áµLjÄ›ÎçÔÔ˜Pš>›Ã›°ÖÀ#¦«Of]¤çÒ¶›A ]–F^o["=4*JğÔó'éx<¤0Ê"4¢CnôlØ_#…Ú&vó	„C+x<à6ït×‡­is9ïåa«.ìÖíæ Qä‰¸Èâ,8%!Nd¼@ˆ|²–ï¥—@„ñ÷˜‹d±!¥¸xî–Ø–Jf¤óŸ<V0IèVû°Ú	vø)>Î^‚=ôXT{€2÷eÿKQÈÀşõ°…ª^§ $Ù+…Ë<¤msi?ÜC®¡¦©i6š;yoºî—Åì}¡Bà“¹[6jï?v‹î;üªµ„JJ·’ññ>ü‹‚4°ªšÍŞ•Í„;[‘X|Ù¦{;Â.îä¶qOì’IR	-‡{¹~Wâ}ÂZš,çµuTDO¹ÊŠ™QÀX€Û:Z¶ÏQŞy¢ AUÈ7
"}^õuæM‡`®Ú\ĞD¨‚ß’”îuÖ	•¬ß©Kz\IY.Êñr–Ë¡.9Uà r<SMQ0( 8ğÊéÄ•n{HÒa‚ O·™
Ë'±˜5] N)¿óç-‰`™,BÑ«’™·%­—%Væ—¤óáıXÜx®&™¤Õè	ë¼ıûT›•™]ø|2@-­å•f=Êˆ¬¥û$©MIˆ(Fj'†•–WCı©Ù=8£aÀÈ®Æ•j„Tó&ÏåoQw—»£ÀK)w1“5hÉÖ¡§¼B»¡)ío¡İœ
k“êÛÿEÛ±nóT]âd[\Õa„½&õ~“%¯XVåß»–u1nÀÚzk¡#$OÂ
‡ü(ï¸ŒtV3?Ù“‹cóÆ‚ğöQti¢_ó×7¸ ±Û¿¡5Öyeº´rçCÍû[ò‡Ç~02p--#¬8ğ'ÄïN°ÒB,T! ÏO×À¶H“6WƒMœì¯Æùç&¦XÎÒ–¹#.aR_!BÃK]fí¸íD«L¾¶Ì ôƒ¦‹ÊAÆkÊšF}ãæä0ò‰°äüÏ`ûÿyË´°¨$ó&òYa‰SÜ^Î¨bru[×F®nIM¢ôË€X°(NkEk8Ô.<he;89©ûÇzŸÇûOï*„•´&1¦Ô6¡ãÅaÙr˜è/B-ËJ“èô3ÏÀhP ËDq‰?ğÌ¥Û£9r\'õŞ Iâ’ÂŠÒškZŠ.ÆØ™Ì€â”÷ú¹Ñ?S¥RT|„3I€SÖœ‘ûWrÌÅöÊ²©”HòÜ÷,íZyJÆ]¾Uå/š¬”r²CVbJ†¸
 T2Õt‡çyÊë‡*Í-³ršñ¹Zºåİ …¹ÑƒƒmÒ¡Ï8åîUõu9W­€¼û²ÒVç¥6#ZJ4®E½çUªÀvıÂ=Ñ)ÆˆúêE:sb»%ßó(«p¨õ×l-4Ş7İôU=]Ë$üîÖuBc°U­ªUpáœêiIöDJ`XÄV^z¹E‘õš÷.ÄI³àšÇ%×æjídR'œ×«ô4`ÉÜ`ŞLl­•#qÑé…S‘|ìIĞ.	QĞ*ŠBÿˆv
êFCN’İ¨D±“ZE
0­6šñ¨ ÍNP Åv‡àXÏµIQ°ÄÂdÈA~ÿä8‹tşÇıÆä˜õärÀN;¼r’sôµœÊö¸æ—IølJ¯+bö›<
+Y€_‚	ÁwitíNĞd$¡€0í0†ù/Ş¯JIÎò1jLÎÆuŒ»høÊå•j'velœÉnI[[>Ñ‰¶ñ­;OÔoßb–:_ÌògbD@â•Y´åcqµ,Î!(i+X¬f•a÷MÅñ‹Õ	‘N¶rĞ`ge h›}ö4İ²ÇG¥ßßèm>aœ@5Â÷aµôĞ«‚u}’,$Ş6U5iÚŸ†(k™ÉºMìJDÛyà 9¤/  #rFØícµ•‚³½ˆ½›jn¹„Ah@RÚª­p5ıe£7ãüüİ /ájvVÆÔ³x¥€Õq¢x¶\$»ùù¿„øûì”Çiaï:t2Šè.µ…¢=7Ô¦áÛ|Jİlš•SfŸLaüÈİ
4Õü2¼]ºğÒn%qã¯İÖ[åçrš÷Æg¨¤„÷1f\Ê|›
Î·¿R^aüsf¨ó¿§…ñ7êvôæ<êêbmm|:u¡´°O­ìÙBmz²QZf>x–ûu‰…'#±.FDynÙˆwÔœÕÉ£‰ñŸë‹&	ìÓHV¼Rçfİ¼*™l­¨LPÙ¨úcBÒZˆ—ÿêî]‹cµZâ9Jœ.ŸìÊÒå|£²mp o*óñeV=òÑfl1Q€ˆÀ£„Ÿ‚nhôÄôËİo
O„“l9ò›jÓ`—¤à{šĞì«kŒH4/©ÌÎ"¹úü
í+›á¢–ö@"‘¤JÜ0Üa²IBİşšÁ¡û?¼†Ãb{H°ğÆÜë-M¾‚Üá“[ZOæÃ¼fŞ„ıéí£ap ùRL&Ñ>(B-,}d,pÄ¼±CÓŞ“£{9ŒNC¹fUæÖNN™BßŞI
­¥xxP­Ë¯•'aÜbÊu“”ËÊ$mâ=?j¶Ü¶j¡F<)¹&r –vM*Óõñá6âŒì²ŒdåÄm>ŸszÎ6Ïº«`bŞÈ‘”RpqÙòªVœaˆÇršàáÏÄ¬¥İOÛO~Ô‘â4xì8¾$ £Nœo€x¾’c°FÜ„$óG@Ô®XÃvJòú·?ª&"mly¦†<Ïğ„6OêsG9©aëÏu”PNL’KÿoB7‰ëA>!¾ù{Í(·‰•’‚lÀ“†~Ÿ©‡È–r8ğÀó÷ÿwF™¦Œ[õš¿—r¯÷¥¥0KàD×¨DÕä^ÇFœ«e´iP6ì'qò†T,qLÎÌşp#4NQ}®ø3¢mÜ¨'PÍ{:dFã:Sø‡÷–IÆ«X®*)aõ©1™Ãöiãt?ğ'[3ğƒôŒÜVwO=¾Ÿ+ytûPENj#î»&À¢µzÒke¬°¿¤h:º¢‚Á2EP›4åº/IJ‰ƒÁVCe®ÑümoºN6¥©ÌUÍ’5àík0‰‡–sq³¸„+gBĞMÜÄ˜®ñª­C”ƒ/]îlW»¡B,(mGHœ‹ëa”QòÉàIãYXé}âÈ÷äÖöŒÚÉ«6ûö#^?1.œAÍêUÄØÜ2z@	wW`Hà%;V§sÍeØø#îvãÄ“ÇøÕüJ˜TÇáÀü:pÎç~Ú)Êuº‘»R[*:®è1T¿úb±gb´Ó’ä3i¡ÈC	JèFŸx·àBbÅµnŠr0šSSN¢#úšÍQ!‹ ÛÈ	ÉæI ƒŞ]	¼¬JÖĞ²et,§A6 I9AâkpT>ÛE%¤ñtn²¤„MZç%àA%Ëv¯¹P1{® >B2üË:-Öš'4!øpg6øÕÀd4HvC½İ+ïRğNòWê#ìnÖe»#ÑÍ¯¤` êÇ…şŸVw«ä_’‹‡"ŠÉä«qi_Û\OD$Ä–O¶'ÿ¶óS>±B ±tëèSWAK}Š´€›–¯ãqŠm­$"µúGhn›GÇØñ$šÿ`õ‚E& ›ØËşZÚN¤}ùf7–›F-Ê
Eã?Øk78Û} ¤û0îö-KÂÏôÅ)¦ƒ‡Ä\>Ü@‘ŒMñK±‚¤¾näÆ/«!šøóm™–·b¯î Z|ƒ[5èPÊGrŸ ck…X6ÕWÁ_b4½Šñ%äIÅ÷	7Ğÿh¿Í1qšá¹áO%Ü´ºÄ§d²§ş.,íî¥´­Ã¸~lz3é8ÅŸ×Ì¨µyo#­É:˜¯…#	9âÅá³J³-kKG¡5òßïtŒâ²÷ïyD!Jêı<R¼	Ìîæ&b±\©Æ×$İ_n"’¯ÿyh±8q™DİÄá<ngYÓw$‹øàòæÕPGŒpt‹¾ØÜ¸iÍQç+|F¡7(LÇaâ&ä¶‰ñ“6 Æ¸Bõ”XÌ¢lÉ-µ&#erğ"õ¸V_Î—
×ì¤&UHP‹Rë®Mı¢ğ5ãÓu©{£ÿbjT–LƒUA§bûR®Fíp6èKMS#R‹¶¥§§rÃ”°ããÄ~½z“beÜx`ü»¡Ö‹s—:–Ğs¬°XÎT7"˜AÿìÇ™ét25¢ËF¾Ş0U³¾yxãÏH®ëÕæ×/ğ] °:½ç¦öâ GõC×Á)sˆ«}f	‡šÇ†’ï7&p‚šŞrYC,Ÿ£¥Kà¤x6aßKÈ^¤-3kÃà]^ù(üHC(:¸OÂğ[Tô°’u}‚ßŠcù¸&¶©UjÊXú¸úfİvUíËšLAçÛ §Ö`Ü¼{[eñ”ezözs¹]zfË/{çòÿc$Ë3˜‘”‰Ğ»Ê4‚)\sPGX ¾òì•î=s¹¥& º‹ºnıˆl4¥‚£JïÌ4MÄuü%ÚÁ‹“§Ew$l¥ÁôX¥ÙßštÜí€Á.K›I€§ÎÕ?­+ø2¸@ş<:u—‘ƒ:)OîQO0'â¾?vØË+İ,]&š‡úàKn!–X½ë•Ø\eä~9b<èˆ±^â×xaç2ÈWp¯
zf8UŠ€p´Fxh{ûé	0@x3§eÍgŸîÓãÖ©yâ¡ÜÎhôcP€F«2WÌ9Ñ¢B‡ƒ<X»†©"™Æå´3ái·Ç‘OŒ·À•èqšğGUz[¶­Ê(¬~Æh9Ë¸!»Å•ñj“cŠäUx¹=TçÜ÷—Í"­×î7ünhµdIh®~EÂ±7!=Ct—ßütHn 7[‚ç–½ ĞzPÊÚğóJ+şÖQ;4e·Ûuü ÷6/Ÿ"ˆ iƒÓVÿH×—%^ô
ÊØM0¦ö}{Ê3°Ôß§¬Ì´¤U¾	W4¬p×]P¼
\=ƒ²œ¤f&_Ú*¶6<¤u‚Ø|ò+wáâ€pç•u5sNòá»¢ úí¦¬@WşíW¢b*`‹#$KW† ¾Ö~¹‡
*pñe°y5&§BÌ*˜Öåh.c8[+õö›Ïû¼×«ş[.Kr‚odYBÙ›@9³öèfƒ¾~^m´âùdº’Ä¬&—0‘ÃÃP_sİå²mÏÿœ àŸMÊ¿İ‚^§1ÎÚ
B^ÚÜáê°‘‘êNI7†¼•Æ÷/âËÊ¤È‰®£Zí¶qÅ"Û÷,éVEÿsçCÉ§Ş$‹0Ÿİâ	
’G¶€rşM’¥´®.r"£–ˆós»ÿJÕê«+•#†Ş?sœ®O|ÈKF’HÜ°à®gª¶XJcÍY:¶t¸ zŞ!ïuıêó¾&+N»eæUoNZüÌÒbƒ¾Fxßt©NêsĞ¬YşÒÿ\Ã<Qq-q´™Ë±-rÃsÉÑã6L0—1úª+Æ°aW…GU³yá*Ë†<#?~¦¡9Eà“÷¢²‘Hzˆ8VùÔ±|ÖA>ä[»ºMÂŠ¼úYš®_ÓTH…5”ÇËâ0´?¤´ŠÀ°“F—ÿ2?	ç-¯•Yßƒ‡\¯ıãÛ·Ü”òª|›Ğ©hËˆiÑğÒÔ&‹”ìğ±¦¾¸MÒí»mİ”æGcte1py:™äyfÄÏ°6í7UÔPËàE2Æã>Œ5~K"i*tÀ†:¼±ø™Ûú˜h†ö˜šnã…Ï|CË{]íªh;İB©¦Ô±»Óºß9|Õï/ 3ˆX#ó˜$øÚ•Å5š(ÿ§V±€gz%+şŠ§‘XÆd†‡}·2mfÅ´83Bú­ª€ˆ‡|eà+‘ÃÓ[ÖŞû=˜q ğêOT(ßzÜ›âœømoÚa~Æ$
3R{U :İ?^B`"5òµãa¾yÂ›åxD$İèv íp~”¾[L8¤Ÿò“|sVçGb–|
IîœAPgº°!—÷Å¹ë—ñsdf¥HÌ‡l2#±
øÆö}Så°h¾­skµ
…YÖıñT•°îN¥áÃË*E¸%¨ÇDˆBéùVb÷º+µÒI°cPı!^Ãÿ"7†EÍ8¡ü@/%ç›ü¦?:ÛR»\õ™sw…˜-W„Ô®/üÏ#>—u¤À6<—=ƒ±;9Â5mNSñ\ıógË[Š¿f(m‘ø¾ğ‚†û¢xòã&ùW
·c©”i;ErŸ‰¿Qzº»È6º…–Û&ºW¼Rˆ¦°GçP?
4<š“áÃ…OÌå’,W
£ Ÿ/qNé…Òwúoåı÷2ãzÛkÍ÷—\ú7¼pcufEv>0ªm ‡zØ¨*õû}„u,İ~;Î~ğ­z­	N#9©y~²ÃŸ6”„£7ƒ'{ˆb'A1‘/¿Nğ27ü·6kĞy†‚ûÍê&zÿÌánğMŒ+ötºÑ•Œe †Ã¸Ge»ğÚ=ÿÒÏ»1Ì,*ÜøfŸ
¡ÜÜÍ_ú:×™3„y	ÔBZ’7X1U6UìŒxgMO­VùŒh„~Ô¹e/³K,Û•;dÃîÏÃVÅª+,`ŞX	só¾ók<iåt'øs„aÿu~LPt{hÙ5</Û‚~SG´WEÿù*ŸŸ’’Emn%aÙÑÛèğŒÚ¨f6ÔÏĞ*İ&åK{ìÉÇÑÚ^*sNà‡ó'1”ˆôª€|‚ÉÛïêp¯ôÁçï£”¿T€ôÑ±ñŠÕÙñv_ªıySùæ¬Iù¿©æÊbÑK¢f&_cnMŞTê‹é©•K£–µ"+Lëé¸ôE s1R„L4JÇB­¤0úşŒ´)äø!/ÕÜ‚IÿAñ¢¾¹ßXãÒb®ŸòD±9š¬ÑÊHş~BDƒk„ËfĞ7}Ü¼¶øÑÔ—EÜ¨êÃs7Á8A`ùøóÀ©Ø«*¨ëşé’yËÚ&u“ÜšÈ(˜L¸Œ”P³‚McoØNŸ
gÊ§³µu¢%2ŒîXxÒ3ó4@ •²oûdaI¹dÚª=ówuŸ9_Ë]ï‹r×iYZšË¼q-D¬ŞñÉƒ«4ÌìĞr~Ã	‡ï‘Ä]G½Z­W@ Ô6=Ô½hJ-À³"µğË&áh«Õœ xŸßNfIñ¹¸
¤g³F(b)…"< Û1Ç'~ãó‚ï¢Y—œ•ş_áŠïãí¢ÕÚÜEgZ’)‹ø­ÀQê lùÉĞ¡—g [aãÈ"­BŸ’”}íÊh´ïÄJze‰ÄGê­è›pØ“4“ÚyÃ²Z¤cˆÚjÔy…í,ÄŸII?è‘®Ê8Š®W™‡,ıªG:›z€¹K°(!zóYg—Oşoº’h†?„b¢s=Š\¸¯³W$Ş¿Y:ŒÜ$A]$S@µ­öéGÀäyz*¨&Ûa\ÕC¸Sÿì-"ù‹Oß!ç[\Ù@¢ºßÈÓÃ,v³şg¹—)k É»›†'öh<è™àROƒàç÷ø *×?V&5*åIºU´–Ü(+±‘ôtèY±1bíTä›%æ‚ÔEHy ø&Õ/±Ğ³I8ÚuÊf¹î-‰5àøJÏWW»;eà’Ø©‰Œ_„«™çL·ú¹´ÿzWÍ®vï	Á já‡Q¨ÓÛ4õ
õäôáÁ•¬Í–ùîŸ(•¼ÂÒ¡'J „[_"ïÏáúAéD*Ø5'7bf /ÊÈRƒ¡oñø;rùÒ±ıl-pİ¤ES‰Ùí“râ÷¿#zj|âs!ıá“¤ú„š]‡×S¨¯ëwË ÚøŠuAà€õù$³cñæ’Î»ŸúÜŒ–Š~ñÎ¨Ğ`]¥Æoœî2<Ğç[¬¯ì~~
LÉ¸ğâ³]ÎXÅ¸ha‚x3xø¶ğŞF—…•»Y®°ú%{ƒ-~Ñ©L¹à";•îÓW°ıŞŸæjÃ3‘a’È”¯.P2bs´¬I¿SGe¢A©FŠËÿt“>{·„€Ğ’´ûå=·¤“¹—Âà-°Ñ¼”A¹r­ {)™±G(ÙÅÎRÒ÷$)ˆ3‰°û¶d`æ0»)ø-8®Ä|ïbGˆ)I‰#1,ZŒû^9XUDE{4¿›M¹†NĞ¥z…¿±bC¬L|P_¥öƒ^öCrÀytrÁ-h·èâ+e´¯w•½Y´óŞU+^‹¯Š¸¢=Z£áƒ™g®X¨ö:İ£Ó$U$ÈÑ*¥2›5U©B ¾CZ9™?RÒæ§-î“Wˆ´mcAm×Ae¥i½7vÉ‡³ïÅkP¹OÅuså`cÖS¦m.o”ŞnàD)zÛ¯oi·XPÙ o•D#sMˆ6É=5“@Z‚Ëºğ-“’Ğôk,ò®æØÊ)uáûéÄ~áæ•/˜¨´Ìç0àEúgªåşÃ¼-+C˜d;C‹ÉSÆhŞë{}h`¹#­‚¢˜‘ı«å%şÁ¹Bi¤Â“ôœ×ÜÆ¼jwS9ÀâDñmE‡åäa-VÔ9„ØÈx¸*ìJÒçÃÍd~Ÿ…¹*ºNû[¾}ıÈP„7ø\ïLB6½½auì4‹ƒıF„¢­ˆÓ¹*ë?;…Ø"ÙÊSí†“Dqİ°¦P ¼ör_úóÂê'jGC‡ï·Äj[Ï¹ÒÖçC\>™o;šBúĞ¯¿ó§abG¢8H¸¬ ÄÉ-’éÈDÿù	U0‡·†a$01GX-fî~|7¶Ş×\ékçÑ@ÿ³G¯óˆ*9À¢#OĞˆÁt*”‚	„uohu;²^‡!_hÃGËZ;ŞR½zf$«ÇLAšîkXnï<—«Cûƒí¹/ >ÿ šd¦Ÿ×)G7ˆN¤‰Ù%#¾³§Ù®cNK~Üú‰ù[;O\Ë*¾S(óg…O×ıí»ç”£vô]XléÛ—Œ)²P§'w(é#Ò¹ÔÉCG#]ü´Ü)«n{Ç†Ìèzª–¯-‹l˜Şw»é¶Áiø¥oK3>MÃ‰éyO3,p"˜[Á_İ:Š$]ZŒLÆäê×eÄjõœ_¿#¢#GĞœŞTQÿŞÒ=sbG”+®3å°>x"_?#±’Tl>NŸ2ÒŒ¥Ú™³“üè3húyÿĞ5ÒZGŞ«hÃçÜAÏ‹£yQ4^®Ü<ÏÔÍ-İÔìxcñ©¨BHïÚ¶Š
>Õ."â‰/4I‹€T8U5›á'{òçYÉÙ>Ìg!J¼±Y{kvYG»æ"–³%–F<Ëëš¤>oh¤L&–¤8•x£.u:ªåıœ#Š´±rSÁ‡1GCÛX¿?j
Bùy²-U$Í*ÆÙ{JÊpãZÚ<Hót˜ êÆ0ípúK1_%e»3\ozy² PLÕõAÈææ@V)`f=ÚÌ’37:„ìàJ7q7¦.¡Ì hxJ¶»D\SápÀO²s] œnJÅ1”ùİ&€~‹[G²ì)¸¾)á¦m­]T–Ñ®|æ™Š<OÎnş:öÕ‚ø(u¢ö[¹B\íón_ì´VÓµ½gqP$g!½»Jş?"êÜ¸Ù@6"î·Ö«8Éúa]j¯J%”ª’P2——*ˆ­©Ì³5%s‚HÂ}«'_ƒÍk¯a_KH%)¥Éæ”E_]yBÿ…ñš~oKjº«­¨é·b‡ü´„JŒIİYÌØJ|ñ…,kn†š¥}Ç®m…SÁÃô²–çÁL6É»ØSî¼¿EÚ†rxŞ§ùê6Íq×ô¢˜ÉL¥ÆMı ›çâpôIIÿ¡¤–pUf–[l€ëÈôBÃÀ%íLz¡9çq„ã”1Z_L¦ºõ»æ¹(6qm‚Ch†È"ásê|~mAw3m75Üö;ëùïÑæ[‰f28&5Ã6Te{2.e&G4ùöäÒ/×…*î†¤¹!W¿ëš¿¥_-Aök …`§]OZ63-‡2k—¿M “è~Ÿœ[îÎÛ‰e™@·}¦Ù¬Ö°Ò$Ëh ¿æ±¢¶ıx¢À¨$½3gêXƒÂıKş¦‘™»ŞzU3ÿŞ‘¾ùˆÛ­çdÿ"ÀmvFÉqLo;	šé$˜üáJ'.»cLÙuw{Ç hßö»ÔËŞ+lÁaÛŞß]öONWÚH\„UĞ©Ÿ.¨×ø
ä¢‘Ú§À“5/â™;?İ"­fŞ>š’º±ÏÖkdÉ01nEÄ¾ÂÊ6l4Ş¤~qğù ³ñ²{óÊcD2?Æ‚?©[\î¿pNÿÆd¥œŠëYÔ2e”Æ),B'÷{CÓFD,ôV/+›CD>…äKÎbxÈiš•6ı³Â‚5òŠ÷9ış(4‹u›£èˆUjk»‘ÎZÈH‹´T¼´“Ş§Ñ!$ ¹ä,ËÓoáø0µkÚErJwĞŞ¯›¦1}è²»+lØ{8‡Ìnrõ´¿
ü"ÿKÿg×fßráheÕQàM+-(å›CÕ2DYş>£]IÈMECùÚ.ØÙàk“‚±§Áß&8*÷/ÿAÅtv#®ÔØt°+/ãøQÚkwEëÜàg\ª~óˆˆ&ƒã”d5»#¿
PA™¾b"FÃÑV%¤"}¾>­³å(çñTNáè4'¡ÖY‹Åû§Ø/^ÔN ùşĞã½]éHo¶â	Vuú÷‡\;ÀoL–¥êN¶H"?©ãŠ¨¤
±>À)«|‘mîDÃO‰p—ã8f¨úÅ^=ÖÒ¾ZëHR™(9€ù¢+`Û_œÖÏ,¤,RP>Dn^Ú. Ëh Xiéğ#O&±¨µ± ÅÖ÷¹¦6'ŒZRÒÃß	äy…—2¡ãòK"£m¬#Š›¨µ¥ÖÇfµtµ/:tšË4†Ø_d´pÊpºD{ó´|}¤½°×-=šz¿Õa'© ÿ·µ©:ò‡¼–¹Âù‚!ŸZAµíÄ†ÎäVd³ñ’/~)Œü!×Wnğ ~Ş$å‰8ãœ]Éì1T‘tÁMzHU5„KóÎ¶Ö5Õb‡ÌÓ_Rü‘1¡H¿Œì'¾ÜR(ÜP}Z^ZÔaŒÃk‡´ÈÑºJŒ*(… m#DBlİ¥™ä`¼64æ7š\º†d)¹)ù+DÌõ™~ikÑËS,)rwJ}½›«	Íx:çX©¥_sgè tŒ ú·øªø¨/·òòZ­õ9 ~øÀqQ¯…2àEOÎ-Á®ô‹ÀÓ¸Ò íhzµ¿—î¯´–6ÉB/!ÛcHÉ¤ğ$©6®|ÛKâmÚƒ:b'HQı™šõõî£åOFş”ƒPDš3O³»/šK»O°Æ­Oü¾¢Öõk­ù<øbşTjœv™MĞ%`.Üf±s'îµnÜ4–ÑöæøÅY+ÊK¸Å­}KÕƒÉÚaL£+sSËGŠ"sÙñBÉOÄæöäì¢p3dàww×»¢x¸ãÌÇ¾ìæ×âÁñ(!EI7î
»ğ‹øJ2º„R¥”½ÛLXº*:O–$í”¼ãK0R¿¾Ú»ãû¤é—Cí¹ŠÒÁÍjÒ'Ña(éë°“¤‰À¹Ø	@È™Ú0TÛ’ÒˆåB ¼Ü·¯wB…µÇ£¤ßÏşOqRQÚyØgğQÈ§³´]
»4íêşÛ>`xf ¼2 }
¸WÏ×…ßVÔUítˆ“ÍŸwKE!%É„ş-gtŠ!ñ¿8•MÉz°ŠFÜ„±Ihç@—³„†!Y÷ØG/Nå¡Åıœ]uC'ŠË›øƒ™¾œ½º¿y:ã¹×kş6`DÃ¥,éK¼‹Ê¢¤Ş„`ù2”6¹Oàñ%®6t¤‚_?vu×k©r‘y8Sç­¹§³ HÄ]€uÖ6û8}ÜdæÊıO¡øı)u¼ç(¬ªŠÏ$ÔÂ@'•+Ó
ò0 xp£:Ójdé(ew<›ŸBMT¹Š“Ê¡"&°sèá™°L§d=xxyF±–ØY»­…´„2Ù»ıÍ{ém”dĞøk9çelsäMÛ
õór|½ÂC7ÖiÍÏé©ÄGâùjNDûãE€kÑ°hw,Lùß’SÎ#ÇßìŸÁĞp@;Õ¥¡f<
ÏŞc I#&Ê¿ËX£9‡
¸ÁËb.#¯R ıHLÆ§¢Xg8è­â{„PÌ¨m<n5_5~¡J"1ë£Ø–8ë|(é¦ø5œtèwxàùxªºÙv$óµàĞjÁX½Aúº›‡`N@c!š¹ĞyaMŸş»÷#nç£Äı_;‚¿Mºæ­hähç¥;öÇ¨ÎîŸ#bÕõõñuĞ›MŞPtòª…sµK,¹6?™’•*7´r(imL{¦_ôP±U©d¿òE!m„;@1Î#{²sƒœi€Ä¸ÿNÛµ&èr.}ñâ{Øê‹‘áÏüñe‰èßQÂc~ğ5q·„ìÕÙNq4ÄF›}§plø„4¤å‚Ld:ÆÚöÏg.Ù4 iv­3€*á«RQ½¸m! H—ñ&ÁK»bÃ+£•`¯P,Ç'Vo*§(Û	¾E!¥¾dX üŠÍ>‘<&*p_äBëP®{mÁŠ—ÁX²‡BKjßÛÄP{÷çp731Vy~±ùöÛTm"²6ıŠAcæB|óYƒ%3*à)xĞdu}œ‰ˆ•B€Dì‘Á"zÊáËäåyQeªåS€ˆr½â‡	(«Xåuª/ÎPcFT‹(İO×„`õX|um2/€,g{áòY’à¶”1!æ'Ãİ](°3ğlBMu½£ ‘5Æû/üÓ¡ó¤jÈl¢9BŠt2&¢}}=9~Á±Æ0î0|ÿLÜçL>´ş ô-ˆ¬c6f¦É¹†+Ê-<u½à¾‚	÷ôÌò<~xÒ8d~
"w¨¸ÇO&ä]3fcé(Ià·ó<yÖC›D¥$ÿwÂñ ÑW„u+w½ñ ©zÊb®nFZ.ç$´Lxèƒ¯v¤>$×¥‡ËÜu‹$­ù{@)ç¿râ¾x,û²lÕ×¶KáÀ¸Ãä¨"µuJw¬µô®¦‰!–˜b¢DZZ›÷PˆOw¹o4RVŞqu.šâ(TÚ9£v[ç¶Ô\~çØZ+Ÿˆ×ó£@5®?º¯›Şví±İ¸}ÒøöüÍ®@m¨Ë¿%µW/	UÏK/ïº–üõfIî3tF$/„cLÄsŸúŞák’4Ç…Ÿåá¿‰–‡^6 İ¶4>F·9»ù¦46_ÑÙÎõM—t~|À~lc.pQÊ0t¢ÑïáÛâ HÛ2,âŠGãmÄ†ÛËô›q¥“‚HÜ=Ü)-ú÷İ9+mzMs.€´˜")Øöƒ0ışPÖÛÉÆ•öíÊÇR™‡å/oe-ú'ê}¶|½MDUè×}¬—mLÚõ“ç|t>9ÍK­²öÉ`öue‘>˜hg3ğ´¶şørG÷:2=ÖÊRøÀÚ¢KaÚ+éİ­Â8Ş%Qâ!cOS¬~ßÖQğ#õ¬BAòD›SÕãçÁãíèëê&¬ ¹Y@={<Fgùy}ŞÙf™5âZ‡r3ìVû?^_EzîQËxG‘£5^¨"xşnNÌ Æc0n
Ä.EJ—•¬ÿ.*6Y|õİ(@;ú-UÃ‹øš*¶X\åè ü®·G¡~âÉíDÁvPp?|W¹@âQ|{’	“bKòTğ<Ël·³qGø”:ÊÑ¹)Ş˜“A@URÎ¬‘éÒÊ9ù};©ªi±î‚˜Í" İk§˜Fyùf¤µ¥üä 9±À"øh3Ynëc¾Ÿ®ˆt—ŒüG Á2‚ÌÜ3?øö<W®¶‹Ü7½‡€aÉu<ĞíTN¡±Rš•Æî­-Ûµ°T¯ÅœxĞ(p´YÂ­šò·ğåµÕp4ë(–vŒÙàPÛ¿•xsòm^±¯­M¬ı‘!z-!å5mû²Ù3:I· ’Š"sKQë­_™$Qã·~G¾oôšy¿Aî›¾<ˆÖéÈÙåñ¼ ¿!Ù%‡YŒÃ$v¶ç±Ç:!@Düx[}ÕÔjùiÅ„4Œ…sI7=9Åû€™Tä®ô‹åe=FÌÿâuyn„AT™éŠRŸjáÛåpúJñ'˜4rŠ¹OÆ!¸xÆÖoühBI´bMµ°¡’#ÎçÚ"Ûı=9r!ºaìï¸b2=“†û'‹„x›sj|”Šò°#<ã‡¦p……å²uñò¨n®ûÁŒUáI{,_x#/¶x™™;'úNÉô”µã)|KmÈ†¹oÜ~Ôä·JñÏ:÷‘°‹r—I¹Hv)	TÏ?…}^—ì5€h´igôd®p£tA÷¢î_áLgp’¹_Œ!ÿ±ë@˜¹bPö˜…&xP¶ŒèƒVÜ>jX‡(ó4ãÎØ/Ÿ]¼«ÏZ š-ş[§oÆy¥?…g({IµäzùÁ[áiÕ^ûí-¯yì[êƒ(ùáwRb—¤äùÆœmLo¨Ìœ 	‘®¢7…¬ÑÑº·%ºßHgŞCÀ)ªÍr¡…Yñ“µL€¡Ş¢IZ×öUQvØ|5Ù)¤Jó¿÷.øŒ-ÛD°™Ğ$4ì,0×›
«±k©€ŞkjÏ{O8Xí•aWúËÍ+”¹™ŸÌ'š‡HŸ–—Z¡ñxô5·ö§4ë(l¥°¢‹‚Ì°;{×Ä"Am)¦÷$ıoN#‚õ	DraĞZb[d]dú|	ñÄ'Ñ|1 rMºü°=Ó!—ëóÀ‡bŠcÀÿh€F÷…òîmuhı¨ó#mÍØZiÕÑ&ÓeúEÓ5áNàÂ"Á¸HÉÒ¡ZIÅvìJX“›äå½Ôøu¬ÑåD«›½÷¢‘Õ|M3›7fğ½®â×]ú¢nj¹"Á~™¢)ÑzÌ”yö¬å\^/„á°ÖRÌıT¤^ö¶åsÌÈ‰üîyBïF¯AºH‡ó!©Rmş¹«LíÜ¢@‘£Ğ˜‘İi¦eŠíáF±Ó‘X‹şøğ{§&ä ŞõN…»‚@Ø* ® ßl–Ó'Ê×ú[(ò“öC¨À ’ímn)x¼|™O¨,ía—=™loÿ[ìu\iš”_çîAd¨¥út<´¾qœC>Ru ·+âÿ¢ú€Í&c;„Ow#µíË¸]á>R“fìsÉ|Ã×™ê»;Ûù.Ë§d 9ÕK©¬óá !İ+ËVhVš‹%xRHŸ	zl®Õ&ã*ãŒáùßàb­-Ø‚–¥[UÚOÍWŒ3Ò½Z’ØMAĞ™k÷­'ÿ ¼Ûø…ßÑ/ö|†YkvRnÊ£ØÖ‹=çÀê<óœ µ§»Çk>íü?çò²ÚÖëzÄö*tÎÙÛ&Ô·3rá Ÿ_˜NÀñH©ÇêLÃÆ9ğñ]åÒJÒÕúöĞ£s õGõ½Îqd£>×˜{1	Z@‹¯Ú[„ÇC<ÿ« ÏD¦¥Çå²‘ï°÷È- ;•Ò„èg®õ4qÉì\ª$nE0‡´Z¼¤qúÖ‡Òú•] ¤îŸõ£¬M%M_q¨Œ„ŠÒZ¥‹=£%¦Ó¿ÊÙœ9ËWg«5¾ôUìâYöCşâ ®)¡:w‚¹ÌÅëÚ‘ D“îwØÊTjÄû^mç!iLMCìÆ”¯pga)—ğL¬SK5â–î&´mBU*ûÌs&¸‰? §KÓş÷€‘‘"Ğ–s ÕË3#?&†äcúc‰Ï._‡ft
èe÷Äwgn\š\[‘f±œ{O¬##‹ÈtÀ»Aó×°¡Oìd¡x_^4ã!©<H²úøu¡Q†i)ózHAg@âZ¶)ˆ¨’£–Ÿga·G/
kı,^Âqñú8—Å²•.Fã„rÏdU–²a,|© ín”CÚ¿’"ñPŞábJòlÅ‡Xóÿts‹‰Wc‚G™ğğÍ5N›œ'O¾ìª•#¯1íä‚A ”ï§İP‰í
‘Eë^š_İ¡˜&¿œ’†¾¯îB:WºbØÜ'&İ%ôÄ\äÏQh¥x,CØÓ:Ó1È|rêïÌKGºôÊ©¥9¸øªƒANeÆVg¦}í’X
¤0/È®2.¼O¢‡¦Ïvio“¿HHÇa¡U8Â	û¶¦ãJ ¹Å¿ïvCÆxdl£$ÒÌ ê.% âVå‹'CèàEåC¼Üò˜èI‰:aFÿ$º"’:ç/Ğ)ATøàŠ²ïÓO¶Ätå‰ŠäÙbdöâÒ÷ulúOÀ7kjî¾ßü~C,Íî\Åò«EÑ¶rRwa¹¹œÏ\xàŠİTİn8XÏŠ0«ÌãısG¾A¥¯QuÛèPI¹ZÊt[®µ‰¯§æE…YóÙÆ“ñ.£-3yDºã’vZ½kC¹÷Rîjø¿ÂÄòU¯€‡$Å_£
í‰Êjb‹‹Ô;¯¥X·t/x‰D“õÙì„(JeS¿è |pê`N‹:Lw^EMö‚íbæˆ*QåÏúÑw/ãÜÛÖ{5LxæÑ¬kbƒ&c8‚¤†7ÊŒ¸HF÷£¶JŸÙåª&GïÔO¢¬§0ğ©Ì‰‚Ïr‰Ñ\Mê9‚ÒŸÚ&°Û‘&æYÆ¿“ å"õr‹ßñó]„AnÜ İ5X%ªNõşÅ]ß*¤XõÀ{·Ç^È|6Ïô—=O+6å%XCÕÆÙ;ËàÌåÆ{©1rÚŒäë«*A2İê::ıHãE€ßùâpaòß¤--‘xÔø©ªöä*ycI^‚H/æÂ~Š(@amc…öq#Šê½ÁAµéÔc×‡Ø/äÍo©¦íìe…-z€·¯ïü™;ª´È•©
7ÕŸöâB1¼FÆ®œˆÿ€ h3tˆ;„`z"$Üoïkg%ñmr£KºÚ>tê5ÿÊ+õkãÁBNÚTİÌ4 ê¦ùÆÙÖtÃ¢*×¾-^w×Ç%¹-D¬eÀYİvĞòÊÅ¨—m²Oû¯Æ·b^I²€uªñ÷š/ìgÿS]Ä‘¸™ı¬½¢wÖôCàÆml0	fœÂ75|‡E{j…™Hˆ¦óa2úAë==P9aêò¤éÁ·Ú›
İµ(ª…<}y–Ö@Qš"Ût&Zt=ÉmĞûXaEÕwSÕ'°kPÔˆ¡P»%µ÷OÉ¡×ÅL,‹q	%x²ÙÑq\§“ufáÍ¼Âÿ«|ÒC£.ÀF;ºeÏ"E7×tKî[ûêÚUªšñmôĞ!Ú”¼¥Êªåwãgw‹yúçÒ(—9	ş“ÂLSÔàÙÜ´œ DpK¾¯±#ÊfÂ•Eºå	=3F[êğ?±I‘½“O¤:ç"¾yœJÕkó·>)ëñ]Î¤€@B8pSÏW(î6h8%ÔŞ:‘'°—L^Ä'¦9³Ur®&?üB4 ÍK:ç¡Ôª,näËråË`º´ƒ’íTÿ9¶„¾ƒ&	r÷²ŠU¢ß\;X•šFÇ—kÌÆ_Ó‰Il¾P*LÖ€‚ÿßªğÔ¹¹7bSz†ÛI0Ç¬ĞTú;[ãx?í‡BÒ3İÉt¤!Ì*wÎUÑy'æÓx8oâùìõİ)an—wp.EÖeĞÙÄË!TÊ—Æ•)f…·’4›·B@§.,Å1‰â²?ı×ÜİÛÿ=¹€SBGŞ ş2ÆÏ¤a½¾}şˆèèsõ·­ä‡ê–ór*…‹"Fáh	4.çÄÆå ¹Qnõ˜&§Y³Òßá<„:¸p%«ïâÛHr]g2ZWıÉÕóS$ƒ‡@Ç€+m›v÷‚˜ØÀ‹Xê˜êGĞ.p:nkq»GT‰¼1±ò—ÛX½5u&˜b#Ş.‹~¸°%˜öôŠú}aş(ÿü! ±)x}%±ól°;ß%ø÷d@tcM”9Ø¸áIŒ ´ß2Ş¾Qã­8BÇ¦zsm!X‹ÙØöÅn_œe½]«¸²L î’´jÛÙL±ï»‡š\SWº•M¤à[¸‹‡æ{ñ°RßİL‘SĞ¹C'äYô™`I5$ƒö°€Ù)DºgwS::.l¾dAô<?]Œ§ò0ÍÁ"U™‹r+‘ÄÁ&šÄ?s¢â¶[ôEÚë/XyCûA:Oò®*9à+¹ˆóx†Ÿb€ÙOm”¤åïÚœ¯ôMbm‰hYñğÓÊÂh>ËlpÇ,ÕÀr]i[7\Í†çÄHÒ=„·Tx<AÚÖÿŠè¾!loSƒÑßœÆ"÷>ñ“ zc'BÙ1¯€¨4ä<æ³5á(8ƒ}”3ëë¼¨¢ô7Ÿ
š=ğ:š5 <§Ø¾şábÜ$`uáyæävH—ÁTäÜ¼>•¯}ÊõÙK-r¥©^R¨kÙàü¾È¡&±TVèYü—¬X”¦ºøóÚ£pú&Š(6ĞN"r¹úAWgÃ¶#}#{U4NÁ®4>–öãGr3%³ƒ`V¥wõ·M¯¹ãX¢K=ˆ1^Çnş~(ÿ»Ëşªp‰‹tşÙñÅ«RR“FR„®Ì6@â|9>6G.Ø÷¥vb"£°î‰>	\}åºL6æáyÎ¤¨ÉŒ]ÄÚAúD(01c¤ğÓGõ»“¶‚™ß[¾t¶îUÔ•ƒO‡ƒ„åáNiÃÃ9¨èŒ§dŸ™xæéâı•^î2Bœ6s•~fi ¥ çö¯Ş¾BÄ„ñ`~(#UAƒèíYÇïv¡%ğ…£¯â¤îVåŠ ãn1p‘p©#U(ŞÑÎófhæH#ä2Üû>&¹C*U ÕY8°©< uÙÉ_HVxÁ[s|YC–’Ê©–íˆ0WC¨‹1<C†VfL.kÚÏxÖÕDÇ|1şa*ç¡8ª§©¾©Öşö×¾­‡I)şY…ÓOñßÇĞÄú	~â—A¹ı¿£rŸº¡&û8¡²_+~ ’k&U ²7¢fwN¥-bG	#İ&k°âÈ+ü1ç Z`zä:O4÷5CºÒ©úU0~’Œ²î‘\o6-Iˆ=Ò÷oHz½Ëññ =ˆ9VGT&’²ìô¯MÆŠå3Ó_ÉŸí;·®vıìí”ØÕ+‹`Ô[ÁŞânãa­<!Ùá¢^Ùü– g*=ÿñ«©…s—¶ú›mìy÷İDÖÓasg®âjÄüÖÀt½ø>¤Tµë/ziÃ¨'WÊ×¦}xE1@Fß§Z€Ş¦šy›ÁÁ·-N²b‚ÖZu}øaznyÌÚÒòÛç^@^ŠSjšÛ™IÆ5°jV„y¿rˆÚ­	ÍJÉŞ·P‰­˜x§®c¦NMºn“æY\¨ûóü0Ï¤ÒÓauÕúq·aLo(ˆLB)E)Ú$şÀözÏİâòÇ¾3Û_ÚÛ¤"j '_½DäAfoçUf‘]$7g5C¦’õ’“YÃã8Vó½Ei«&…è‡)J=ıR¾®ZS&ƒè×êš\A;¶Šâ·Tû´$ùuâ¸Ák yk“%àpAs…<_ğ9²lß¡g™!ƒú Yb^aVsûòrYÉ[[Î ^³yˆÕïÆÒ‹Öª|g@zÉÑû¼ò:ÿş,ËãMÍ'4¥ÊÑ~ÃxÊ^úA[Á™‡6pÏ÷ö3Á“W2ázö/ŒC_:ôG³êÉº¥ıÊÙ˜Í&@8QëıLiæº©oüq‡‚"ïÏŠ±µp£„$‰éÂI¬›é–s?Î&ñÆ˜Ë~pUlBì'LĞW–Áu&UUô-9Iü>zäq%#	~Ì:-êtÉYŞæ"±[n¿¶–ÏœMÀAÌtçx–9j¼7(‡ÖS}×¼ğ ÚNûmHÎ¬©*íqÚff3=‰KÜd2Àc’t’Y.A]l	ÙÖ°uìx†!nÍ±_'óıõßÈ;·MNÿMğg†ìğ;74Xù[ãº.¼@0ƒ,5lTî©_Ÿ"oŒº£Œ9µ2 À´öF
HR2-dµzCİN€o°ÂşQ.÷Ì¥8™çcìç­ä&ÌŸm´tñ6âOï²yt¢·‰%ÖÊ'XÌTËG+Ûu.,Éüú÷qe 0A*´0aæºâ„ârWHeµ™t¿çÁÿH¾á_´\³ì4ãì‹ñ§ÁÛ&R»DúÜÿêì“å‡,$Iß±Yî´ë%„Ò›ºåçøf@Qµ÷©õÛfzÿüĞó¼áüÕ]}0Ù(r^ÈOv¨œ.˜#×(+çŠ²‚Xä’´LòëQèE´ã‘hzÆ©¨)êóÍV5ãJŠ©s:ènv×±ï	Œ–ı ÅR®1v7r30Ò"Œì’Â×W‚/Æ)ËiBü&e½’1ŠÊ.ÿá)(XO¢OÙ1ËÔ®dæ ği”faô–;POö…É|.™óqëÆ/…Ü2z[É—l¼rQæ¸&¯_á„T¨}BçZÂhÍH^­Ú†Òº…ˆ‚(!‘©áf¡4ÊÇ÷TD)ªÜÊçÚ—“_×7×)X¶Ø0ÏÉ“5iÚ6)çu
WÛ<òªªæº·*çå\¶šù¯_“êîÓ‡“=ÙÙ¬Gª‚j.ß›£|6(Ô¨Gs3ğùO]]J¬2Z¬;J¶iAá@ìäÓ´­$Á¥²2¥zœQ_PûÏû)ÛsdjÕ
 ¹q5?=ÇÌäp$è(Ñ#6y…°)áòµr8€nˆ-V*@/#bÀ|J¹M^{ã£>å€–$Rµ$>1oñs Ë!g
­´©ÀÄÙ×P\cìáÅ=YÍdO¯MŒr¸ù¦Ø‡Ô†¾Ã=ê¹±Å^’çØãUÑTˆ‹®±²»§]c=Å#L´Ê“À=‰¤?®å)]u÷k.Ãñmª –Cı ôOxµ0-ì
cı;´qoŒæ÷3¶FH,q#‡Ë$m; Dôó‘ÂkI‡Cì“9„eR¥÷ kµE0ö 5‡ÿéuçÍr•Ë00vsHŞÊ&¯*ÏyZ0mˆØC¢Àõ×9’ Ò­ÈyZ˜{|foĞˆt1MO«‡æÁ·GÏ 83ÜëĞ¦†IM'àGnf’=?ˆ/lQøØ]muM½kéh
	´îk“\ëy
6;
d°Y§5,a“‚>U»Õv§‹°{KÇÿ)±gøw„r§ÿÑúŒmøŒz×\ßGÎÕxş¨–ØÁ¹Î¢{jªÔÛŒÏ5½V¦awûä„rï«t¥O	Æz¤‚Eúb6ÑàaŞwãMÁ¥â2ñYíÍTÓÅ®1ğë{½òJàè—×+kû{+?(U¹ÆFGÌOAÚA%ÑS¸µ>ÿoYè»Êíº”SLïƒÅêı_pbcçˆ§!‚ùaœğË&yØG©¦	û[-“mÈ~†»§27›·YÙwWy€*¤dÂª¹’o÷2Y0{§„ŞpôoÖmSÃ&ŸâÂgJ€_[Wüy‰U­*íOl,BSn´”vLl“Õ£Õ¯‹*o6îÇu›o³+Ü·_‹7U¡cÑü#˜ŒV7JØDŸBüÌ>“Ä•F70„¢Š#øC~%’ˆNâ¯MÅn$#âîı–Q	áğúïZmïŸï”GíZq@A… ìí+"Ù¬Œ%&@‹RDlRÃv´•2ı–3•½_U£6P´Å¬É<±nøÍjğkã%vè^²LòĞëØ¥	­·y}|¾¹$…ƒùË0šòçĞÁ7Gi139æ/ƒÉ:FäLœIOkA>NjÿŠ“zP[yÕé1¡êÉ¨Ş¹\ß†œ&ĞØ©Îc`–9\WP±t¼fàD·Gbæ…ê$–KiõÀª4¢£´#iÑÕ™	öÕ‘M +øßj2êOä8!Ğ’QZœ‘µí¥LşKÛ'•K·VÚuM‡‡Xà¤UX—ÚÇ˜jË§ê`¼p©-'Ü%,nÿl,RÃCùPL6Òá=Ÿ~*œ FxßğÛóC®ˆŒ#é$³ên	´¾*ÆŒnhÒõ’UuÿIÃw)Nv$VÃY¬p×Â  ›¨èÒ­º•|Uïs
µTbtEŸ`pDUƒÏÕ©?Òb`±Eø•¬~ ‚*É\ÙÂ8^NMßYåœÌÁx/-!7ü˜6c½~;Ğ›™B1KñÜ
ŒÒúÏËüïªÇ_÷ı‘ŒoãêyU§+œæ³RÛ+ÜL»°LŒ†A58™e«-ÏxIİ˜İ­cú«^%ƒS`T	§ÊgåÜş|†wÑĞ¨cäAìyó‚iÿ3°ÄQ;^[tEKqb¢UŠ ŒUüUaôqNÍÑcÖğ”}÷Ë1 å×š×6¹¿`—kÛYí_^·V®­*­OÃÉ^¡¬Ú¡u.ü·{‘WQ,pXÙAFÆ—¢ˆNq3*ı@‡‹é¢µñK4YæÄsÛDM´æø1>+·ÖçKT%F@±dÌKœ5Åbcéƒ·ÂröìCÙ3‰&Ï„Qqzó+W?½öÅ™³ŸR³º˜	+"´€§@z³ Cràµ(áˆ÷zK‰íJ»™ŸÚ—B^#%‰ºbî'ÏøËâ÷é²ÍÚtêî'àG‘ZøŒ÷äi¹š$÷eyØ·'ak-1±ç“z®V™r›0¼T%ÛÓ\Â¨Ké¬è«S‰ù FJ=ÖG*ËkS ·™	1MlÊj…÷§j‰*–ËC¹²1 ¶ôÎğ0ĞåæJKZH*#Ñ …~üÄ<"&|ŞÂy;-#­ô6kù– ÒúÊ2µmšU@S¾ÅÚ7d7Ÿ6[A*Şjhö·n òP&Ğ´Joıİ~`–§­;6W—ºNÉúbRƒ%² MØ†î–M~ŸfSt¤AµËÁÊ oçãâÄ­ö­€ÉÔò¬óq4öú,©Àš2iµå£=wF%ÊìÈ°îºª€E^.g ‰^b/¬kèöV<‚´ãªT(şZûIt.àRæ/z`Õ…»Æ7)›B5•štòçR¬ZÍo$-Ø 3ÿÊ*@¤gdBG›Î«v1¬ïì‚}´vv“æ2nu§!}ŒÆ§]_oÎ¸ªŒ—&Ò&â§d$[p=8×ù¡P=Ò>#«‡À¼ª‚E¬ÄÓ]Šámƒ€ŠÙD£šGüóõÕ’ºØ
âæ‡1å˜È¡jQšİĞSGY^Hx‰
IÌÑ¾¾m‹¨%[¯ø«Õ(ôØ`è’@A‹­Ú¢^¶Ğ*Øy“-Z~Ğôr%Dp+uPnÈç…8/Ğ…Î±U”¾‘oÏ[ƒnûÿ·\Ál”KKÓT•Ô%T\#Ic¢¤)ÈF|$İ,³¦“–Ç…ä &×'—4•îPâ!Ûv Üwˆ°FœB®7`ä^ş¾Àâ§jÅÙ)!Ò*L¹§HÌ.ƒî6GÎS»Tñé÷efXVOd—	1…•ÎNBcÏ´è4'|˜9<)±yÜÏÎ/¬ÿ}èÆÌ“ÿ_rÚÛrUgqjUR*K´ÅŸHhù•ªµ{&ˆÜšX«3
%>,½K¸V8¨Û#å[¦ÁºÉèZßĞ¦ª‹?$¹*>ã&²1Y8¦ÿ±«ø·ŞêI=ûšOìØôşŠ¦Õå™z–¦v{û‡T¾ïjğ§Ç3•!8f+Ùí/Uä	D2¬ ®ÇïÁ>4è9œ×gÛza+€ğ-ŸåÑ§'T6÷ó).¦úïúOğˆv
zoêú«=Ú]†á‹šû3h»?‘v”ªO¼DƒÌZT ‡sãVĞULúrÏİÌÑ±M‡‡q19‹4l@ÌÙª•¢ŒQ» ÍoÿÙWÎÍâà$Z½&M²n×8H˜Ë¨æ	"Ÿ<ÌñÛ1÷¶,éeÓSDF"}˜yäĞËç4Nä\Ãö¦Ü§‚¬$R4^¹ ™-7Bá·Q_M-ÆŞ¾O"U{2‰]E_í$!Ö^•cÀÈ÷‘ğÂÆö )šágÂ[½Nm›˜¯Õ¥n/+ÓÁÆ¬¤Zc. Äœ®AÔİãÁy«¿=òdBAù]vƒø@w¦‡k¶ÂÂsz,á‚ŒHtğ¿„CkV Ğgdm+É˜­c#Åÿ.GÙe_o!:]°¶ÄYÛKğïÂÆK"r,ÑùK[ª}5‰¥¡%ƒÍÙšö uíifƒË#‰xeHÁu\œŞQñ@Ğjì´ƒbOıÌÏg¾O9épQ8~Òşn“Å·‚˜ÖoFğÛQ@ÖKš%s÷rŸ'‚£ãÊ5ã™«‘e-iwJ¬¬V6I;$÷	’sŠ¯— ø)\…€-6ü@Ê“C|í‡™£pÄy»‚WãR2FItÇ°›#ÜÁ¢èûå,aç„y¼<Eì—k	œf<äHº3Í§­P+êí@$øú€YÜ•ˆ(¦¨h$#`¡íKÍ«)i³7ôGR(°™_.ã7lÄ«š˜KWĞg41§„”Xİ-²2É¢ZäÃsïàˆö£ºrÆp/b{ìº§î×GgÃ(H4}P=\•cGÙ¿XŞOºU¿Áµ°»`È˜åœê+]¯î^]ş6_÷j&ÆÉYŠ¿¹˜ïş_ì`Å`ç4fß`LíƒNëànMóÕª2øw'Q¥_
¾@B¦i¦ ­ÎÉ+²ß6½)ÊìÀIÌSUŠwøØaC|[¶úË2‰`æQHĞ—%áy™m{øù7ú
c•ÑeD¦§xßéÅvuƒ‰Ù¨y5ã»ï}í¤m½ÏÈ‡rïFä
‘¶1Ee»ÊtH¯ÓåÒ§FG´fNjóU˜ĞCbXÜ›.ˆ`gëikiÕ{±‘UŸ¡½n†«ñ¢Ç(¸xàÆ‘Ä]$õÒà˜ø:§

ÙŒz¸ÙxïÃÏtEI“@VÂ*d•UYN
ğã³Çì¯NzÚ½Îøô©uÛ·OWh8–[ã:ËVÙW÷K'.iwÉ³¨O5ìb6‰7bN½)B°y7ÿ÷¨™ŒÃÕoUîd-y¤KH98	álôòäˆt=¡¹´ÌZ/$CSĞØ…×ÙW¥š.DšÌvÅ1‰ãHÈXÇ¨°¶Ğ‚AÒìü¬Ò6ö1èâ;CÅd–CjG1)%ëMWBãó9Ÿ¥ˆÃÖîz5s˜3W·1&½d¾£Q¼V€à–L]7ê ‹”š\CÓ²Èâzß¢]k‡Ba5¼Ş±ô[ftW-ºnzô¢‚‡øÊmt\4—ö²êˆáÈ+¯eS™¢7ª–ŒŞ¯DØ;ÜÒŒÃÃ(}±Qşä)$ƒwìÃ'åòà»OYŞé´•+g‹ëûdîœÔÛ¯?¤C¤RIºcf?Ä
~Ÿ¬Í&Š+“1}£zÈ¸O¯1|şĞ@ÿ—]´hâ64ªæb—¬¿èuR%7¢{±„ãuDlæk°à¬œ@ò$ø=µE~€ïqı_®ZÓÑÆÙjÑË«Ê[ï•/HÕ5Á iÿÍ²é¶WlUu¢0”ò½®ÏšRckË“İP3k+~Ò·Mg²†) Íµî´†J”­ ¾~*~n3o”{LÆ–J5Áq~1I©–»i_„Ø^àÎàµ¹£Üs~šö¬çv¿Ši˜QZ¼RØw¿Qéaß¬x5ö;y>…YË^ ;·]ôïYàáÆ|5¨;ÊáíÒE;†¡Ä6ôr€Îˆ¦äñaãôâ·Ü²X*Oå‘ŒœÏ+ì£Q÷æ‰¼!	˜]©ÜGòfh…ËÃç8‰J[HB±~ñÍfçî@ÚÉ½fœf2òˆ5’Ãn„xF¨9‹óûÂÌãDç›Ú¯²Æ˜‘~#KDöıªššÜÅ?[Inn   ª­Uµ<¡‹ ›¹€À0f4¥±Ägû    YZ