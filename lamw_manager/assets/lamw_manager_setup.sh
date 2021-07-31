#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3891988386"
MD5="68419a8fce3206ce84d1d4d1ff40eb0a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23440"
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
	echo Date of packaging: Sat Jul 31 15:37:05 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[P] ¼}•À1Dd]‡Á›PætİDö`Û* W‚·†àÃÖç•¹ ˜â™Q¿V‰Ù¥¢±‘Âş]öÅ8€ùtvjù3Jp]ºoµ¯šÛ0Ú®„À”EN`…Ö¸±.=&º¢Mqè©¢VIæ1€YÚ¯ü­Õ(´wæGä’Übb•®¦¦ÇVdªı–¨^e:Ş</‹0D9Dø¨Ùı\P:~Q¯é»«İI¿fšqTÊQ„kùA!+Æ™`aF™á$ÛB1™M]7dHm®ìàîÔÿ¢ÓyPıÅ‹îG3Ó#œŒXc¨İHpH,Òè\õGè~8êú%c©À8Š13”—–§(	áSjiî{E \‰Ï‰Ú‘B‚(Ç{üBËy$„ÊlÊ„NçÒGÇRéöˆ]xÍvCrĞgq©ÿÅb	óddfçÎ&DÁÀàq.ç˜tàø¹Ææ I²t-k€«Çò‚ø_ Jm’¨™Á§Ó¼@¡ƒÖé¿^‘”íşÇÇ(a'é$í‚Up®J±BUC‘çbË2Âpü>W–P¯QiáŒ(>~¿iË“ÚaAû	RÑ£´v¶SüÛ(.HFs®aI’á.<úYÌØïÛıPÉ_=kğX°< ¼zòİ
²§šÂ5Ò¦ÔiGîüç CôÑ
ç[´C4²ó-ÒPã;Mí9Ñ{l-£gqb8¡ïNÄü#ì9ê¯¼œé¢I¢û*s¤.ÁM4&©GÄÛö§Ê/‚ı¬6íŠyJÕy>÷Éè%¦X¹kÆ÷…ú·v‹=/ ®›LÄsHÍ‚²uÜ!èÓ„s…¤Fâ¸n‘y)şŠáÍÆÛÔ…gƒ ·ÙëŞcwÖúÔÃÄp;"¡«‡/!I#–ªg*·Ç‘F@qİÚb|º\Şóºa°‚Kg!"ÓÀ$$TŒ‰VÔNï¸&Ù	AxÆM-Bµõöd|zrÜÇÖ©	ÆB¡òM6Ë5Aˆ0vÉ5à ºœ*—©júZB²ıï—^‚ |©‰’C>lUäË¿ 9sEf’ÉİÈÉ•pòË‹p£Ü–îÔœ8…Óóƒ@	©DçG×ä4Ğ'ROP¡¥‘ú”CTÔàE|Yœ¼Õ6+ÛÂ‚½gı>á­¾lNõrpcëçşZ0èQÁÖ¥æÍì=â8	‹’‰Rj$7÷MfÚ6š¹®~*X›¬M³9Ò¼î34@AñĞ¹5ÁZ²<ÿ+Æ8Œ `¯Š\ê™‚×U%.öôæÿÃÛ@Íb¶ÏLÁ{”œŒî-Œpx8ú0›Úœ>›^Øœ]" fïîOÓNgãa6MwÅûGÄ¼;ÅÀÇ³Ë¡uPÖ(¸…TêÆú¡±R—Cº{Sª|'ã²ñöüÔŸ•'ìM`Æ*•mWKùl;¡‰ƒ’ïc#¹Îéˆ‹ÅDÑCIÜ½Ï¾sÈ–R(¨©nŒ—ŠÁÚeÚUüÁÍFè©”^ó9ctõ?Bs®OÔpkqŸ©ú³˜iŠµ~¬~"/ˆÔ°÷Ñòì X‘-&-ıê	´¸Å‰‹ÒÒwrî.Œ`Î8¾Ç±àq!¼Qgı:¦ú|cñ+¦6l¹OOw¿Lô
Û„NçºôàéU¹>¿ô¦€É¦PG:¢Z­\r½Ô°½MƒèBá?™Û=B´>	}‡m¥Êmy½Ñî±à‹;‰p
mäÛåvQ¶MËû¼âÅ°nZóË…"¡A¦<ejÂEq¾>O¥€sî7Ä×Å"f$FíJÂI~­gâdt»ˆÊz:VáznñG-$ª¨rs"q¹°Õ­¨] û½´y[î)û³šr1$¡ªn)—‚b¥‰˜~ ½P–m¥(Sƒ¬Ú)¡;ğV±³Ñ'^6FtSÕª¯ƒ¬û¦õ4b‰÷Ë¤åÿLXˆ8~Úk±Á×¿˜ ¤<"éÚ}ÁÀ…?àM‹—3Ñe½î@ß”ÁşL™³/†§%«ãĞ°ÌÕD?Y×ˆ¼¸V Æ‘B-ZÉ‚n ıÙ«2z»/«ÿŸÛ¦§¾Bjaİõ €-Y¥LNÓİø	÷6aRrÔp`Ë:Û¸ˆ&²¤Qr	¾$"g¥ÂßEzWgœÀÎpÂ¾c °ÆÚr#¥e¢„õŒ”Í.»>@Ç^N)C6ãjĞíMè]9BD,ä8òÆç›(İ*&¯ºŒfïb73hŒ¡¢»üy}¥Ù­ÓBÑFÃ4ï×Q6^EûûNÛã½ïpÉÙmŸV Îû¾Ê·2İ”ùïû£bíXµAJ%i‰QvÑíÈàOëÕÆ6£©8ÆÛìª ³°YC’-Ä[úqıqå‰n-x–:°¾Úë*Í³|l}`¹ûJ¶Ïú|-r||lä.[Æˆa± Œeÿláî¦’€éd;¶.GcfdÚ>aÎ‹²@ÒØ8ÄdX¼SÄc<Q
ö¶îÚˆG^9Áëı¨®…åKçœƒ¢½.©×['4£°ô~^wá–4ÑU5 ­o-Z'¥BáÈd-L“m3[&	~î÷Ç¥H66	: F£µ{
MT¶ï á6«Ì×uáçÊQ\ƒø„Ñ~¤9ÚìÀhÚ(bº}EVÒîvOe½³ù¤+èòÂ§81[ÿ2_w§¢LÙüé YÙ ‘ígp~–UÕ@&yË•Ì³¹‹w™^‹]mx®]Ğ2\.ã¤'9‘£ƒ!Û>?½ÁˆT²/ÆXøj }íî ØÌ!P¾»(.†ê¬¸šÛÜoD¨ñAÇhyÉşË¡ĞF¾»Ûr{4KÊÊÓ`'óù?½³â`D?mñ“µß<Mn¯]Ú‘ŠˆÇPúhD…³»°¿4N[pˆ/]`ˆ Ë7Aµäø±¯±±]µ®èô}Û»Ñ·ã# BGoj"Í0µ×áå­ŸNà0]_µ'CLom·)r+×póÍ¿/î×£¿Ğ3–è›ÊäUÂ“ØXİË¹w°:€…Àbª¡uÇ%'©:¿‘b/Uà9ùëË3"7qxÈÿ3cÛ9ğ‹³O­0	à©yLŒ Y?qj¦z³(|´L›Ë«%^||>ñ™‹òn;0CÔÅë¨["ÌSúE‹<.—Š&¯Ñ'â~¶Ç7¿)Éap³~2|´,p™åÓ'7rÄ¯Y»—&¿·sìnŒ8™ƒÊn_¬jğÈ”Ãâ<6Ïş)è«ne<qèßôe¿]Üìñ¦m&1¾³öŠÆÃTÇ4õd wÈGÎhz§ÈÂ
ë»°‰š(Z¿ÆzèË›Æ±Ş“`ƒíİnƒJ+¤–ô°ˆ$‡Ç5¶à=Dô´ZP¿\çü-¢YvM#¬¿µµe:eğ¨eu_h#°ôÔşU™™¸%‡ÔĞğx™ÁóĞ`³N¾™Û/{(­¤:áp¿j=Ù©Èõ
]ûqª„£;WÈ\î‘à˜d‰İb3s™&¤hkSc=ëÂ]p¤aøÉ’cõ—Èj1†Ê’ú¯…&dş9¹I‰½ˆxaéûñg¯;ÏÎ0òvÊÚDÁTWË‡ád_ŒpFƒÀ eRFÌ(W|øçl0 à?ß¨R[)Ñ\‹È ×V¾¦¹â²_ÍèÏ4O :.§´y‹MvMû µî|»"Ã¤Pg/;™U]2Û:é­Ñõ:wÚ|%öı”åA„\3ã ÇæèŒAØ«eËrlÂ
‡ôçt…fÅ'o~UşZ3+m4§+ 3’çëæüFu:¥4 }=ƒÅV™½&½ô¨cP(Î< ÉLÍ>´2™i’cômB‡tËÿÜÙ6w’\8ƒNº0ëDı!¦êÁe>®iÑX	2é¡í[Â.İœEöÿG7K: gÁ¨â€V˜ïw÷y©‰ba€Ãì‘y;¨6Ğæçµ‚<ë=¥L6Çq¸>ğ£ª%ˆ‚ Ë@ê`vdİ„;Íwo1áş`lª*ñ|=‚Î¿!K·vÕñ×RAJ`§¡‘Ó×CoeiSXØ#­[SCVÏf³ĞõÀesei9›«¼uYdœí8n{?ıÖÿâLÜ^Sm(Èë,=/êÕU­:15†•§İÊ[Át ÿXQ–ùÉ&g„ª•1^z¬Iª7óä®	 ¸GC]ï|2ÜDEıOÁáT°y¹ÌÑÀÉ,O/"vÎÅñNjÅœû<ÙÜ&HÑw´’5WR «—@ëMÔaUƒe8VB=İoë‘yx†òñĞsİ÷:·ÛO¢³YZ‘F•Rø•,ü¾›¶\“’$Ÿğ¦æô;òh]qDI7ZpÅóïS"pnØv]i›k%îí¤Úo3¤+°£nÀLáN¤6jôÑV¤+÷ÒB
ßn¬àˆ_›ò6½ÕáoŞR(¥DÃWN·ÜÑ¿Æ8Mbw"ªzÌ=«äİòoìï ÇÏCâi5ÌQU©%–º4"¢È¡©,|å…lÖMõ\wôÉ?5…¦»…GSTÁã{J0R ıË×™/B8§õŒß:r+D‡e\¸Ğø£ş­Ë“l$XÜ’ ãı!êã2Ê¥¹Ra§»¬yœÃÇo¨~}jtèîT&.Œ)óESó@¤£­/ÇäGNôOe^¶‚8ØÓf-ËÉ(ÖÌ’ãMÏƒ9šÓg\Ñwaõ=`hòõh¾]ŸGQÜ‰ıù* ¹ ò­3^æGµ½IV¥‚ˆLG2ä óÎ¡˜Ş”	…›i=˜Æ¯Ğ‡?ü­ÆŠÒàîÌñìÓv—UóÃ˜
â(¯¬?ÅÊ8£.;¨ÛupK}3‰3ó‡ŠİîİÅZ·Ø`ÿš(Ó¶c|SßmÒ9
·…¿é0—â­h¶šÊW³ÉAbıj±Õúi\šd!–r;y hs¹e÷4ÑÑ¬q!;ô[D
>V<
c+Üİøø´~Ş¦±g$+édrSÅÚùT¤¯Ó;Ôœ¨u ‘WïëKã-¶ÿa:c=•şßZŒá±ãÌÁ»é,I‘ÁaÇİÿoE…}¯ğÅ£$Nªy^N¼,ŠJ¤.¨­0ö°ùÉÚn#ŠIí‚®ëÜÌ‚j_æœè¸­B&¤ã$´T,…læù=÷¶œhóHdÕUÛvxÛˆ*úauÎëø¡ş”¿5]öó{ÿÕî7	ì.C ÀOÙô!¢P¤µ®p,9!p«M”B,ß('‹ÁRvµó»bÆóÕ´—¿«Ğ\R0õ`^(mÚÏø¸td™÷5©~Ó-7tÕ1†ğÙ+J,’š{‹1	¿Ô×DÌ£/Ö¥¨'…£÷=ŠOß	«ªpÙ…» í”Ÿ{ì—[«¢-lÈ‘ñï]£ò²CùZM¯†Lm“]¬Î)ÑÎFruu¼ñ˜uPÚHOsæËº6È7Â£	À&gúze-°(‘v®JM”ïWh9'q-Fzg|¥è8ö„ûÄ/Ö6£µäŠfÉ} +Î¤ÿ@.4¦“¡DåÊU$– ”pÜÿ_(RæóÕg™N\ÃÂ+Nş¸©±ê_ÁmM_všâ¶ÿ™ÍMEu4^(-ë5e‘ŠNCÄsğàEıÇˆyçúUÛrŞç¥
uZæ’âeozSiÙÁBÓcÓT¹hó:kfÎ’ÿúüºEÕ¬VØvï4æ×½ê`³vñZ±1=jfİ¶Ù'zÂ?íÈÖ‰Ë™8‘8·
»fš>á	áøĞ˜¦Î”¦2ĞqEñÿÇ†tÚ¦§x½-×õäRs¿z”.XÕì#¼¡£›DÑÅâ/gúOÁS‰ıf·Îš³÷ğ¸^¡áZ÷é‘îpà¬Wwá¹ #Eº¹(Y¡X[hÀÕ¥Á¬U¶[b#¾Ï·İ^ô‘ñıøä5Â¼}9iWÛcO¿Ì±DAúëã„ÙÅi¬.€YğY‰Â$Öh^C×Á“äg¢ÛàB‚Ïw]G‡7>©õHÅ.:Ò™ß¦9ğy±‹´ƒu4æñ=™«1cVrAwEÓ=ğëÉ¼‡rò^èã!'ÛÏ‚˜Î È¾¥ïün+’ƒ•ÿûìÅEñ[ ™)KÃ´•Ñ‹JŠÅè’k¡,³FDNÑÈ×ÙÛ@¢íÛx 6pFæ×ºª‚Û¯’›w1˜°•hÁ+1E­'cÒ,›ãÄ×¬Ì~ŠîkVCPÅÆÒÛ¹€»Qö|®Wé÷Fˆ®”Ëp2#QMØèŠØénˆMå€ÑçäFÅFAÇaÆ‹ßkjPuRO”lÇ.I‡wÜBDıÿlÀ™ÔÎ÷áªàj†3‚Í$z‚:ÿâ}îÕè)ÇĞ§xõ¯Ÿ|Şr’”—&5†?©ÎMÍ÷Ğe®q§7¾Õ¤†£%j@ŒÚã°T£Î¾VC¤9,;•Ù:pÙÍƒzé’r¼š.	±cÁR;¹¥”¼@Êƒõ+s~ó|«^ ¨®Jw*+¶ºõPœñ¤¾äª á’	
¼:Û0eùÈğnÖlF¸£7=0±x4ñ}Sãñ? Œ
fİCY)x¢p‹qÈ:„d"Ú~–‹°+v å}xUSOX†	?•y×Ã`áÙ7’6lH™€óªìöë›Ç"}÷˜B=šÑÈÛdb‡åªZÖëïùäZl!PË ãaITCP@ø›šÜñ3Ë&Ã²™»`KBnñ9yÑ’àWej5r,Ö²]˜e®ïp÷#BÅ±urAìˆ´e‚£™[+†–ò<œ>qñQ/¡vÈåß¹¥‹qi÷¢v©£ø‘
†ˆL,båOôunå
_9ŒFÆuê=rP§i.òıÁ Î<r«ı:ÚªªsˆEz0VgµN Ak7o¢ç%m[ÙxsíŞ3æqXfèÑÎ74œI]¾í{'ºâ‘(ÏiˆĞ0®HMœ{ ñ{«)íxª˜)lô¹GêñK.Z¼®’4„‰¥-ÿ˜"n‰ñÈb¢@J(h¾,šz¤ó8#†l»ª¯/mG) Rè½`“åìIê‰Šª©å eb)°™õÇìA0Ò±V”»Ğ-±F.›ÊÁ?_d‹¾_A¢Š³nãºŠKVÏxÕ¿l
¦†Üv`èd‘Å§ó‰Xåg£§´½óÚjÑÏ¶jäëo§8-^4¿øåF‘Ü¿2=Ô%·•ùçC&}w"ûç§I5Ñ·²Üå‰¸¯mÊNû´:7i]ÁgÊ…À¾¼ç²¢²ü|Ü|Œ/ó:ĞË¯e\¨§‰®]àÍ·v\ÓÙøÀÖ;[ZMêº,»æ ¡sÍf—ù.'äñO+ãutòÛz•BEí›ÌÓ¶Ö$R\nwş}€:ÆÕVSNŠïÕœó5\€Yè3Ñ&ŞôaÆ1!Ôø°Õ6wÖñ¦âÉŠ¿Ø$‹Ø á±Æ1Ó¼Å'„°µ‡€9›s•Q›ĞÏºÙ¾
˜–<“#ÛT¼ÂªÜÉÎ9nª8û²¦‹;ÓåJ:ËÁäê°æø ú!¿e(î{ô•´İÆX~Œïò…gí7³Ó÷!èSÂi¼¥òš×ñ‰e§ÔO('Våğu#>3i›Z˜ƒ?e@Ç±±ıKS„ót/¦îìdkVÅ™b…oÕİ¬Šx++º„haÉaËÃ“D./<9qk)´lÈ‘RÉ5€ÀlÉ²cëğ£²1…>—‰PÙ\‡‡­¤‹lS­OŸº"íôö!ÂiX#ùê~U”°+¢=^ğ£sºˆaOÙÇ•ƒĞ½g0Ïğ'ù:è2_‹”kdÆÙ­ T¹<²’)6Ó©‚ïõøõLZ–+_ÒÚuÜU–q“§ŒĞ«$=h0rÜÛ	,„*N®EÚŒL;:wù)[Å2j$£#X`]ªZ!DÎï_ß»¬*<ÇO›8gP{YtŠåS…\¨âôgŒÃj„Ï‹‹îáûä-ßcuÎ¹Ât£(­a$âÂ6r¥Çæq¨Ÿ‰Öõ‚ø|Ï.ªvÒôúÀà°1†2àáÇJ`æĞü
Eã%ù	„•[ZJ-ƒï¨ó¸CG?jó%×ÕâqE€Ú†ç€@äÑ5*õ}0×£„§QÉ0LN.©Ş—ğ ü×tĞÉ(¯cñ)T„ı×ÆIMd[¨Ù€}|ˆôÒgãx†Ì«šíµëâ³õyšÕ4Ø¢£ô¤¢röEÜfˆQè™õ¬EÌ¯€®§dÇÉâ	"˜ÜS.ªàšéÂîs³ƒrú–m½Ç
@%ašàïÌH¾¼õ´K|¬ƒˆà$Sz1Ùy{õÁ”—OoèÉ¥ÊŸQ³¼ÂP¿§Ôp+ şLèÊ»ŒŸX—¢ÅFä‚òÙl²¤RJ»İ/]Š¯¨şïÒzé¿Á“‚@@{U@Ğwã»ÍªÈVñ$Ôoñ!íâ*µÓ¤GÉ4Œì<c=Ùe/gË¿ˆîG™á0“ûR¡[:•fÏßÈÆçC0[ûdÃù/qıÑ½¨¬Á=¾)ÆCáÙ{,Ì×_8ıÅ·Ï<ÀàAth'2t6ñ¡­\Æ+{®ê¸¼e@Õ™XF>Ò\X…'îE%;Hä!ï†‘DúåS•Ât¾¢ã‰w1Â0¸’ÅoZÆ-şï´ÀUn—8“§ŠxÅËøÀ¢‡v*ï N³eºGJëœ³ÊÆÚA<ó"yÃAYõ\µƒêÚÜ~ão%okTÁ‘d!L§	¦JE@ï;’5¡bÙ~«4n	ùÚ’ñd› u±v#S
:llÁ²X³Uª¯³tàwş {-Á!‘¢™ÏgéñCr–(³œùyıµ­*wv²óıö\LXÈå¦^¾ÏÁÕwì¬Ù¤X|hÒ’óDƒÆë:yÉ{2ã0ú®4ù=¾Y¬e1WkœW›a’(_5¸¼ÜÌ‡yÒŒÍôÓÕ€y7ófc·¥à?ònJ›ÁĞ'eÓlÀ}¿NŒŠ[“‹õ³’ï™¦,°×'œ¶x­£<ƒ›Â w¬ã7=ÊïA!µt‰­°,‡Úğ»¨Y.£ÒıEÔe$)è^6ŒÏz¥è½4Ïü\í/'=Rò¦¡Jæe³Z‰ÇvKÂ™~(¾[f.Û.	ãµ7ßrÏc#ÚÒø ÌùãJ¥¾¤£ãİ¢¥èf¸z®|[÷¹ªÓyİLºÜ6‰Í:?¸ë ş6ÉØÇÁ-ËıÌªÚ”7Lìÿ"d!Õ@öÜX)‡|å¢+âË–Ëtíàº-¡O F»26(
¡›7áœ›ÅëÊÄJ¯ü¢ÇÆ®¨OŒÿéù¸œŠ2ã*Y4óÉ!•ğ¼­ÌøNÀ—IÌ0Íb¥æÁr.s'0²¾õtÅÃ<Ë?\6è _8ş¸Ø’K‚HÀÚŠşOséÄ¢áhJJù)õ…ENÚ$*ˆ6¸+®ĞÕåÌÚèkd9—“œyÀ!·»DSõñŞJøÖƒ˜í¾ªi*ãÜmÇä•|ú^ˆ>.óTêÎ¸¥¼`"‰´õ|Á¡÷™à’â]Á Åğ6ÅhĞÏXFş2 îí¬R*c 	´ İù:™Wı¸‹Í«+K9¶ÿï9R}zjÃTy•êXÓK·€óìt¤a†fÂö£c{„O‡Cc–§šCo3±.ˆ?U<±<Uß¥†ÊL!ÁÁLo‰ÿ<˜¡*¦nf§ÈRYhá¢0¡l4ùÔ'¡Ñªİ	_[C]ëÖJ„çY¦ÖTºïHŠøk©ûpQÆ¾ä8÷ÁÜ…Áâ+)Pj–f«'U²<tÕ½ğé’•wïœ™Ú8Ôµ]¸ù¹ÛXëiìÌãY¤¤Á8`Õ>Î8GÃ1pD}~Ç“ıœ5ávzûÊI4c’-²M°G&±®t«Ğ‹ NŸ}7p©SsyÅÙ‰¼&=)J„Ù—ô4ÆÙî!$Cyğ
¨rìñïí&5ş$s/u¦ùºiÉ)!MoæÊ-Ãdé_ÚçĞÊ>©¼MÈ{£Ñu5’>b¸8Hñæ-.ÅQn)Ï¦÷Ó«É1ËÈå±€‘Ú(Š”
füW2äÁ­^ TtËÒƒ$	÷(¬	rWˆ‡Ş¶ÿKcB²/JvvøÅ?ªü$MuŞÔ1F{àŠ`(Œáê¢ê6etïyOÔ‘W„Lİ¼ûÊg ]'ZğÉN¥÷ø‘Âş6²Øq3Ì3w$@8¸hW·Äšõ¨|«¦£Ë¦Va>£ÑS\í•8S·¤™Îè´±TÖ“ÔÇW(Ng«£Ø{™vâ…¹“X<¡v†UQD8¬V#=2ïG×õÍÿ–c‘‹‰2.UUúî€3†„”k•¹?×Áæ[slâ§‡?óE1‰á®‰±1QÈ­ZÚ’QÆÙä$b0^Øİëšt5÷î†SÚC£'ÃOYïÊŒØ+w>¨½¡ïEg-§0¤Z±dz,\L•wuyÈ³]d«Ö±VNVó Xs{*ˆ<OßÇ¢DÒÛÌ¯øÊ‘“\ğ{øG±Ì3Úœ?W\7–Ûg<CîÁïµœ¶˜{²Ö. ªºU&(
¨û
.u¬…vTzu²øgî‡â’×59¼T+Òl÷&Io
fr¿ÉscX6÷ı¤š¸AnuLã÷ª*jÇŞœ‡óˆ¥¢ƒ–.¤
¿´,+™“o zßmy¾h®É9PÚ²8A•]eëŞ#EÄ‹òËíT"ÛíÎ@.Í²á¨ÀpxUšÙéÉ\9Ã(=ÉóN@1	$ğÆ†üúìˆÇÑŒ2¶_íÀ’¬Ç°>¶À­&«’õ¹_6Ìé³”óæåùÉIRzÆ°ä:¥nqóC_É³_Ôvğ·@íQÆñ%?ä$åªƒLê@G›Ø(P†­ôŞäRD6|GŠèç§ÌåK¦Öñ¦+Ì•â,ªl‡·1VN[xšzál,°ZWÚÎ6à`ukÊ|ÏúÇßÊ5ŸÆvéægZnl|£ÂµÑz· '£ÖztûÄ¿õÂ¤l=Áõb¥’‹5~ÿ·ë· ™r@)U	ô²$4sdÍeÂ%IPd«`l mÑwk
çîŸJäôL”eœÓ6œr_ÛÏhˆHzŒs\_ÓÁÁí?«Ò†$[£z…«=
ë:âñOv)¹½×Å\xüß(y»‰cJ&¤Y¥‡UlWQİmõË©¨«Ë …°€ß‘ü"e}@00ºè—e ÔÊ-„ÿ™‰'mÍs·Àµ+°©aí}·Ïkè€X[1xÎ¦ï´Üøæ5	yš^`B ßîå™`úx2Df‰önù>&ÚÜßq3lHl˜^{Õğ©ö®Q0CøÅ;¡Ø
4„@~İVíAè±|w²Ñ°PÖNi±öä…ŞßŒ´ƒÅ½ìJ
´TudÌ‘95t"@
6õ‹Ã¥k5'ªÑ	#:T+¦F-ğæùz‰ĞŠ÷¢ jE‰‰¼˜Éó}[h·öã(y¾˜yÚkÓN"h›¬·oC3LÿT·®9Öİ!Iş±ã<´ ¹h&"KóbnJ,Ïÿ‰1zlÁp)ÌæÓW/ò& Ì‚jj)fy¶‚¡g¶EgçĞ¾s§³¤C Í„ß'F…²bÑhğc´ÀıZÂäÛò÷xÔşİô%ey±Áò÷Of½øŸ¦¼ÒÓÜŸŒ7¼»I¬~SÇd7í†1	‰âİéØ*@ÖÇ~¢—ë®ö ò—i RW	ï£R×	=.¿`b‚ú·ÅRbcBŠ¸€Ûõ	}h‹Oë]UL„ì±]c|Ù(AFöÊ:ª•-š©;¸)êßB¿>#dÔA-ûC¶”j|»4ÌÌÜÅüßñ…B#Üú(JEÃtH—›­EŒÃTÀÍkPpS=‹¿àf9ƒì,ü îtİ’2ËqîºpuzD£E¤ï{ô4>èó%Ô“.USsºŒóoĞ„…§ÙÛC«®¼,A¤à#ùp‰ş:iíÙ….P’u:Ï4ñ›h]ª8D[cä’ZÂúoÆL0MOáÓÃ×/Uæ`¯ëY|º[CéCi²Ğæé-‘’ò9şÇ„\96Nü‹´œ©æúÑ
)‰*YáWš«¿Ë©#«äŠ•Ô,	ú™¾;éMHTjíÖT©Nra®ß¼• 7Ø÷››³áşq±]7Ìƒ·¸ÿ¤kÅé"`çÜ­ò¨sÊˆİlÉôï¼(É35màk¢«wN®%¾~Ïswumi:œõ§»!ıyCYDb^‰±H|ÇÚh£!iKY‘NËÊşPšêÿÊ%ïZ›FGrdÆ°/ºç(Sï±š†3~V“*a-‚œÂäJ¿jH_•*ªLP©0+ƒ ^y/P6‚Ìº%øĞ0#Àô.$s=úg=YDGìûÙÒiæ¼¥ÑO„Ì/G˜|o_q¨°{ÙÑvï†]²2~®wÅ BË^ºá°Ë¢îW­Yv~
òlÚ.|f+ß„U%‡=â´:N€êEÛ®Ër¼o^am vx/2ï‘À!¡GËV½lïKö4â•¡rÌ6;#ÊÀkİî
ƒ|21Àß„ÿ‘u_ïBo<zãìÆ¦’·»¤Ñå•K#6¦tI¹6çöÎŒ3#ÊÖË`?€ú"¾§(&İƒırA¹ySÖÑ8ˆ?)—pS²fzEœ®úÃ1Ì‹_Ü*œ=:ˆÌ	…ùdËSÂC¶s~†õq¥Ÿ¸ø?_õ¹[Î[‡WdİÚ›tR80ØÔÛN‹±™êğdyé)1µõT©z_{Bc6gUîô"i {ÌA»× ´´¨=±Hf
ˆg¹`-Íoñ>}O(DÍ8».$ÚlÅêO(*$‹‡Èn‚C€<…½ÍŞ N„P³Ğ!|æÚc[ğ›Jk6™¤«CŞ’ós9¦—;d—næ÷Zµ|6Ø;Ck÷ÿ³ıÿà´ø¯NìyiJæÒ—k8rÌ|¶“ŸÑ"Àkà¬ŠQÈVc“­F•Îç¡¿5h]=ø¿ñ×Nqºl·ÏgAhVº_æËâÂH¸CTxu©Õ„à=(i;±ÖÔ¢¡áyåÅœ½×Ûà‹7V=JÚ=ó ı)¢1Æ³NIJâ4¤x_¿"í Ç¦§«Ã™ùâ.‹‘`Â»*Óú#xx•BÃÈ¸"¨H´XŒ ÄpLPPä¥ÑJì+AnfDÆ›ÍRÂ|ã8À§¿^GˆdY9„Ê}t„¶[hDQLÂÍ¤Ó>[Ğı)B$xæRÍ<÷Š­C$‹t;Iº.QE¤n÷Q†Ú|ú˜8¾î¸ÑJ0a^ì¿×ÇXİôZÃ ¸Êä…  kKÎõÌp5±?À…‚±}ñ¯·– Ê’®/şçia¨YáşÖeñ ©ö¨™:7;O\³§;oK˜»ä¯U‘^>ÙĞ½¢#Œw²l½<T¸ğ³¬<8/È{ÁÚwøñ––ª×Ç†_t=ò¿¦Lz;şT"-häÌ7ÏQvöÑî:fOBZ>v‘I\D›‰˜a´Âø¶u)[Š# ã(Wô¾O?-­ÑwZt6à/—ÃMo…ùcz‚•¹Wd·˜1ß3‘}ñ¡áéw!+©æ/üo1]X“"çµk:A±$•¹¯Ìˆ°:­–ÿ'Á²YOÇ Š ü®Y8\€rì%&€wær'f½ıé«xÌÎ7â-‹-ôÎ•-+R5¯ØgwâíM^Z?»$a–ä…?õ7ÊÄªÆ!	:‚éÆKˆxx³oîK#\Ş©ğ‚IFLM+ošßâÃ…¡Z½x$÷®OøIÀË$m.!Ø1/Ä7Œç˜r2Z­ÚFNıT¼µÈâ¡a£”“ Í•"ôÊI A6¶ÚÓöF¤ıßúOßHŒnö®ªø®È[fÆ&{h;†2ÕáŠûĞÆ“äáº<5ø¥Æ½ÿ«wPñvrjıÌ·-A*nïXbş›–=ê«ÜIö+›1Å vWSú+™Ş¬ò¿Ãr<ÆoÇK¥Jö)³eTTø%sflov Q$Á[W©›ÜğºPù%ÅK¬ÕvÉ)¶¤ÖæÅêÍtná?»\`gÜÃ·èÇ2Í¸d,ûûß‘A­f0”W×œnOPtØìI‹¡1@†KÓÅêqŒ3á`CY?²ĞüÔM¡½®Œ/cè’Ôçv$½Dò¾ÈDeéèëÊ@ì§£

f°”×[ª¶}Fı7ìÁ_¡o°Ã#=dAş¹±¹XÒxÃ-)û«íû\ûõ#]I^õãt=	è>5FŠAV¶ëIª ±[ã×±\"’ıMJóiËöv»ñoZ5~~w×“ÏQ£é/ş\¹TG2ûcÒ<)I×æç]4q<¼.VòÂÙ™¾ƒÅt„÷?í{¡<¿ç>F&ÎÓş¥†aîG÷¸¤œûOh¸C;×t	©‰›kL†&?ÎÕ×Rêquƒ¦0‚_›qŠ$tßÓ³¯İ¬öi@˜
;»•,İĞ±¨j£BœÿN%jÏ4ÃM2w7¬İº:RÛá`—ÙJ(—å"En Lè.›gŠv:Ê>¢Vê!Mæñ‰;+”
À' ;3Ğ+ ú[¶%çc|Ã×f¹˜‰G+âí% Ø)>${óˆÃ`m*™¨ğ«¸›;ªçKÀÙT°Ñhı‰	"]LGYƒÊI³xÒn¶¿5¡2vyV/<rĞáA/
>@ch»ÏĞ[Ó&7s°>L,”'\
¶†7LA£p>7!²Éf‹a„àSi‘çd,ğ‚¾K(§0¾-Ã|4hğ–Ô*¢'W&hg[å‚c™Ş]4…Í£öÛä}<NÇÃœŠcßš›Xnâ;­]P)$İtDş5¡Ç$ëaB?6yÉ
CÄ%ëE’w«ÍœFü¾ËœàÛ‰¹ü*¸¼Z„¤ÔAÁ±‘ƒ¸2±îkg"³&Ûa½¿ÅZq¦”^ù,ªi6º]H¯{Ö¡€‰Qó±Úb’Tşƒ{Ş²“ü€ãWf¸å²²9[;éÅ{{	ºNcP3KáLH¹?QÊsÜ­«l\ÀHŠ'ø·NÅĞûc€B–æŸ§«›÷µ§F@3Q¼<¥nA-ª×»ÒX&d]ÿ•o`<¡3Å±ÑŒ\‘D÷Ù_…{¡—{¡xZ|±kæÑX´„.Ë;¬eŠ8¡=É¡0h»Âçïx(ß~q‘ ,õ
½3ßµPëÖRTCº¨”$–ëJ ’	¯FüAöÏÅÈó‘P¹.Z–N²NMÛS¦¨‘Ì9ßyìŒHóÒ&ÂQÀpĞæãÌe®"ĞL«¾´HµròË„p¼¢*3¬ĞÀŠÄdâ7ñM£¸ß'øù-Œ‘gÑuãö>ñ¶Z6³¦­†NBÌü×"pÇË4|UT¶Š[ÁåS“õ‚a‚Ñ“'ºH¡a¶Ì„2ÿc	Oõ’Qmsƒ9Oñc¾*F¦óÉ^ÛêF”NVÀk ¦—…\Dd¾ùÄ†:§v”Óïk4¾±áâEé%[C%i_lñ^@'D_óll”e"™?/.çèÿI×¡½ováñè ÂÎa¶y Ä_‹LõoË‹óAñ‚BªŠYÓÎúNßÿÅ:VVŒĞQmRF ç1°¤K%†•Ìiê$Ô
_îÊ¬wşl6Nÿş¦A=8g~Cj ={[ˆ!æØ›Ñƒ!À¿Yå¦úSbÄ%ã#Ğ)! à’/êr7’
,¾©c¥×šì\EbÙŒŞ=Bş×1]«D	Ê`’›4Ø”ç±¥«8¨é†Cô™ŒEÖÕ¿Ë}7_ãƒER£GÂ—Óo¨äÄü?ZĞãü	Êº¯dŸæ]°ÖúïdZØ÷:L¿¡,;Á°¼ ï ³-p^I]˜Æ'6¶‰½vådÔñÜc`Ey‚g8e±œ>÷’p-³Ñ·¢EÔ«ÚŸ/í-¶ ™•O^µÀÖßM#Át{gÀÃšŠˆy:ÌVZŒ=–1K¦Şr¥NÆ°ÿSŸCşp§>s‡µ‰ŸÇ-[}Qÿ€ÖO…â@®Ÿá2ÿÅ3¬bÁÇ8t9G°‘˜ >«A†©œü Sé¢ü†5[aÄXV&=<Ì8d@vo{û¢+ÄƒÎ~º?úòzöV”êIAL¡+_óêG=£C|ßOë44O&°×f êì‰sW8›La£ •Ä¹œ¿ğ¦$8vÆ¯ ¨Ù8®EÎ±§ZEØ¦W±nó»#ËƒqºNk½•HÆ6Éö€e¼ÿO`«„C
a_Á.òÇ¤öæ ìÂ@óZ}Å>´xPA5ZDkòĞÁßXºòà½İh`Û)Å`²È,¨¨ˆØÁ¿¸©U'‚)P­gÀ+˜NŠDâF@j3ø»xGvv¯si»Ãæk²Ç\Âpl«ñxWã@kÎí+–7‰CÎÜ\2…w÷ÉÍeN÷±ó —ºÔúI
ÏPH;
ÂèÀ˜)j\€ƒñ*QÉ²™ô´™ Qx¼¶æ¸·€îİ~Úm”İÁXC©Ú<LJïr¢İ§ß¶ë; ‹¶ Kë_±½^À%IW»h<N1!åwGÍ¶°Qí£bª¨µèï‰„ÏèĞ¯ìm*÷ßÏ´í}ş‡2ŠÔş&¶.<Iq—J3­šw£" qT+ ì˜KlÊ‚×§?-õôOjùE%ÍûnÉ!™®G;›˜v2äÎ·î‰£yçÈ™YQXv±>Vˆ©”fÙ4
³…W8Ö.}’`À„\ kIU^ÿ»?l:¸hÒ¹Å¥m\Âù!yî:ŒÊÍ%€¤t­ÒÂ÷AæÁšŠbú;…[j¼£_1>ªsñûrwÓŞW/òŒ{—2†gv`
ôWsl²8r¿­‰ué?u»Œ`áï,¨”(ò3eP¸‚û¦ÈÔ$ëâKÂ3À^¶òìŞâDgƒ¦œJ«hZ`çƒöÎ¨nĞë'Wt{¯ášQ¥‡ì(×ŸKI€bI2ŞócõV9¥Zd~˜Ò[>ŠÏ>UIk_¨ÎC®ËÔCG÷;¥
RJaœ¥ğ8Ÿ»Â)J'îBL¼Òõ<Å/®BéÀw°€ccÄî^¿®¬<}]­¦s|ÎL,<¤ÉGÅahb>ÚšÀk‚©“>ŒRœækÿQ!n¼JşêàÉ†«–Ñ@ë³/ó— ä÷°9S¾¿†·ô_aB^Òøw[:§öPM3y)ÉÑ/ŠÙÈE6K³Ô!à°†aô÷O®êÄ@À?­ğoQfÙ:0Ú¹„»cd|`;»@œˆ•±7 +fÃ*uû aİ<E‰YZµÛÀ6MÏGœoÌÈ´Ù4.åØğ@É£[mº!îÂ|'6å¨†N¢‰‘RónŸíúux³½„Ä®× ^6*mÈsTpËám”dè‡Ø‹µ>–z“ª)ßÙO3N³ßü «µ{ÄÒ›¹dédí!QT
ğ÷Û¡÷iæ´¨:‚JoO_NÍUWh
XWQOğËÛxä6áåpú†ûm-
¬/Y©¦{$³C3š`š{+î-0TO%ˆ¢0°»Ä–¢ŠX×Rİ].QUÉ	(ìOy”(øÓ‘XltÓ­ûšÜŞâF`Ä¯Ú3FwÆÑ
6;;vÜù_Ê‚ãH¡“JWÇ}‰.ÙİÿÜyWÇšIH¾V³8~sEOÂ³h õéDLõ|u‰ş|¹‰.m†%Ô–¿ÔºÄ&ÊT¡s¦Şc	ï/ãghËÆ©©'vbtz3D,ó~Z"	RÏyr2iáuã,êËìaûP£Z8Kl<Ù÷¿¼é÷åª3İf¶ÃO?–\áô<Eˆğtièe!=@¤Éª½Œ'`|¥hæš†iQC™¯nŞf’ğ†a¨	ìm®{$#ƒzIL'¿ ó.õ‘›"~Â„	Åò·ª‘5U‚hü˜\†24ö•Áş©Ü~à!ù™ğsÃâtÛ‹a9 Y€ëŠ®úÇP‰oÉ‰Ö%Pp1ë¿½¾wjÃ`XE ›æ6¥€uºU¤Ûå“ÛÀ¡ÔŒ@Ò…Ø#Ä÷ù|h_­-ë"ôÕTÃ=¨­Ò3üv‡Õ¿p’7›Štm{A¾<­û,™a_uŠöXÒ¬¿«DW—ô/‹fåígçù'?r‰ÄÎ-mfÿªøÇÅFz¸"©KŠ«tßR`ê
¤²u›w}f®o»©Kn.å3î¾\¨ît[™‡
ùöÙ­#ñåÈéÉnkûÓ´ˆN¬™SGL «¿A)Z”—Û'ª6^ü­æøgŞÚ0À¢—_Fƒ2Ú&*èz}VÏÊêTSf ş-}«íÌ´²öA·H	_NÏÙæ‹N>dÀ@ƒ2IlãÜØ4u	dúĞ%Òufë`4åuR0R¶Qæ„˜kÀ…ÈŞd~Fïijº 8‰àåi,Á«O»ø@ù.î4Pm‚&Êu?	RÜİ·Şıô•¸ÉŸjÕQ˜Ø¹0(-3	Fä~1XsávË6¸uIı"}Í:S
GQê„Ëkı3V¼}¨ñUÜY%q,½Æ…İÏh˜™Á¸ZÓ=T:{7üXÃë½ ìñÍp!ê=ˆ­Œ…HœÒÜ	ûD$³ÂGNÄ`-ÈU_Ş¿	ÎS¬ï#{%kÆ*?XnÙDb@\)xÉßê©³0’nU@)ÜÖÔ©g<Õî)Œ+B;vÚ.âI­çp}Ì'tnà±}g?öÏ“hB‰8æ)Jú²-Ø4”6IÃ ¼ {¤ ğ¿;³¶½S)ãÈl³ôêŞ`r£PÓbª£ßb^ä({7—õIô´2˜•HDôÊ¹1å‹rÛyQZûqW–ovÚšÃzÀP=e¾#ÄÈèsaVë‰È›ÃJµi?_ß¼Ôå”	š§(3?Ä›Ó|]7FúQrØu³ôÙ½k­hì@Ÿ4«}Lvzõ¦Ø‚ÅêÃŠ§‹Ù]_xP}T
Ğdx Å=ú>D¥[„œepè¶#°Ÿ^å\°wNê[¬ˆLòsNÁ»å7ªÿÀœİ#.h"a ÿf+mìĞFáÒ13ƒİXÂ©àPX
€‡1%VÜåhH¤)ììÀµ£ãèx|-fÚ†EÎÏ—A•S÷îT’)-¢s‡@2]1£qY'Ÿõ—í‡;úé_D›{IÈ=ª×%qQ±‹A©
…œç|%r GVh	œ[Uÿaoİ*Â'FlºúÃl¤yÜmàgkÿBm[!¼¨(#;y¢ƒñpÒşœİ˜c<ÂÖ®Ãî«6¿eŒºö«‘ºC’òv¬Zj;voîÂá}…nîA<¸·Ï­Ò²d“à†S¶Ö7“ó”çFHHĞºßò˜1°Q[[!¨…<¹Z5ÆÈï(¼+ë|­LÒ5â€G£ı–£’‡ÎõAã">¾.0úÌ;"âè’º¢S©ØO1«°´¤‹çhò6ÂË\S~­÷7ş)ú.p¢3'mO¾D¦>ûÀ|†x»ğ@£È%Lu¦¬À?ù@_ø˜™±¿!Z–Yòƒ:æÅì«ÆN…a²HOt§›ßjk6Òñ2]¶¹DUÉJ›!–ad9\rYşù`zXê¦,É×_lg‹s"•ÃøªÅV^£B}wa
7bÜ÷f[5½a¥ÆVÍ‡D-â:ü3`LØ›‚÷ü’¤
óÁ`úĞµòN¢fğ¡Å°ìŸ-¾¿˜26p¾ß»ëÑ5»éÎ„-´xÓ$yBåooE}ñ¨á<7-L­SSó"E“Áá“ğõ‚õö±w8-t”ÇÚ”»YÀõ;ã‹
»7ÁÎ=òàziÌ0¤Äº"›u{.}{a4@–ò@;¥–Ÿl²#¡ -dWS1Fl8uÈJŞ¯®Ë¶ÊåñL§2€ò.Æóh-·1e3|˜ÇúKa‚'F0Õn‚7U¾—O¸R=mØVö/´¢z^¥ÛÕg0â×y!Bƒ÷'lpñ—ÙªJ"58ÉfóBÅ@ê¿é¿Só+’Ü½Y |áâ…r(#öD¯´ÊTë˜k³
w}¤øÂqÌYJíŠ°Ø+j%ÀÈwµzuõ©¹¨_Şu¹w<Ÿã
ş.DøÑ©_ñ²|°Ú:D'ĞêzùÚ@ÕËÃkTé±k6	³.ö»µ+e[1ş¤YNh‘1£'¨»T×aºö×p›íµ;ŸÒwğ„±iU\Wâèëd‘ûÀ?ãòAP,Â%¢Ş®ÆŞ9Ş¤§¯-£;Ş!Àß&pğj©tEáÊ÷Çƒ‰L¦ Â‘4a¬z2R¦Èüµ™Ft/a¡½ILD sC…Ãºt°P1+©ä¿{¼.+
 ‘eÒ'¡y»½´3\İ©‘4ëå)l?ØólN¾˜ô¨íìz"ÆJºà•—ªŞ/UºÑò…›wHÓ€ÎYá—»µm]îG†ÊÀLÜ7$MÚ#Ö6¼4åå)9å\˜=ƒæó“­9ÍªI7İ1EYQ
>Á¦‰åHßæÎ£÷¤fØ÷X`;®*ÎS¥Ù%¼LÈ¹d°L÷\‡Íˆ´éY\÷è`û?j¿=ñ«ƒ!ÄcY´šÂ~œÇ×ÇËRŒDç½jä-<ÀP£™«ŠØ>ı-ö1ùÒø¥iÎ’}Ä}¡gbb¸·;tëƒu:à WcÑñØÏƒyOéE9"f½3IæÛIÊñzãÅ‡S—¸O‚[[Ë|é§Äpo£¦´TõVXcã
RŠş’«¡$Àc!Ê­æAs®¢ˆÌ"¨ÅüÊN~Ü»İR(ŠAÎ.6VC+ÅAÖƒz›äcG††»¿“tíXX¯)¦d{ş·b}V–İLå‹7g#RÙB+İ§ç¹Ò[BİqZjScF­Ù¢ïCal|zøâ:˜‚1³)‰¶ì‡‰Y›•ÉÍdØ[‰¨$>ò¬ò%«RCîNH—&±FA=¯O:LÃ±÷Ó›èVlàì†Ö•ã—ÜKÛ›}	úÊİ¿„V×÷€BQl~j-àà  
4>?¥N¶ÑÚHÎç½L¨¬ñÃş¼œÂÏš;[H\ŒŠà£?÷}I|ãìø‡› t|´Óãtr¥BFÂ‚d¥µ,ÉØğ•ÿ)#˜Äc]– sÈ2¥ƒ]U}ªI–óH *aûyÆÇg-táfbCé¡…Xîûkh;‰ ›‹ªZÿ-&®,—­QÒ¹ÉVÀÁ;‚oáÅp>vØVØ
¯&ü“Ö”Ú?_B±.ºåÌ9şÁz ä×£*¸t¯¹“wF§ü?æ»ßèn^Ãş˜³|ø‹3Ha+f'œÄèa±·X|\èÛœus\ã—\	äô.lÃä¼ºV¿ƒéUĞb~ŞzÃ§	5‡|ÈÃ%¿ìı)}?dx‹S¢¹(jn:I€@‰ôæøºã¨$XIÜmÕ»ù‚‘JGcE/¥ 0i;»@Ê½ôC®Y«aŸ[¶ùò'eb®½ÀpvŒwıŒÕ|·Y†|ŸÜ0(^)+¶C»üêfÜ»É_\"Rë	qÔˆ¾ËãT#bI¤¥;ca¢Êa-ö K(Ş,'(ñ¢¤>ŠçxĞû· (”gõîÎ¥*Ôˆ¾ú5´T}çLÑìÏ¨â$µWRl>{°"$åĞAjNRÒ›Ë—6İbà!{5©‡wäÁ$oÂĞºV}í…A™˜•s<KHgÇT*Œ»6¢¿œ²!áòOm%2*¶´d+áMÔ°KúïCv’LÎ0¥/Ám¡Ÿşb7ZpÒĞUñŸVæšòKg$ïF!#IEö’ØíKğq+¯-Î‚)m¥póÏî(­ˆûíTaÅ•SK&–×“µáú,ï”«¹ÔNÃ¨¾R }]\Íô%Fzöc¿@Pê`ıÿıRôŒÿƒÍÁ»éHØäz#bêÿ†¢«/¤Ä‚=1â>Ñƒ]ñş™v¥A\ÕiøBÔûö{0Ì“œÃçN4ˆğ™å(ÉJëú3õyÜˆIÍf[Æí<ñvÃ6ßväÂ7ìêræ±òa1€£†»ÓWpVmİDS¡ÀuÙ_N‹å)_®wÆ›Oîú×5Ş´˜PßäRÔ:»& ®´-rËG*½Õp`h€=ëÌ«SïvÎˆ@Ã³­´M½“qDåÓP·ğîjxÍ¥ÅÑµktøXÓ2'S>$ê²çH•`›%œ¡1eŞ&ÑnE’Ó¯ò9¶±ÕvÏÃ8<G%ûGDÜì£iÇ=:½õ#ıô +l‹n¾WŸõÀÄ	ª{Z«4ƒ€æcXüÊÇPŒ2£ÁÖì—~®Î?™”liûKZñº7km`¯
Ûkìk Ñ¬¶\!gÍC#<âÄ¦™ãêbX,¦EØ‘*¿FaI*şšİ¾Hj‘ÜLÿYVûAb^,Ä&Ë”ü¹ª‹â¸·Øâøª€…»ïÎ€ÀÇ6„xªPX*õ:¤†Pzø»¹T¦ÏØü~ÆìÑ¨XK1 ‰—Éoç’^7)İË35]Õ!@[bÄÍ-+ôƒMÛ[kÆ!^‡ÇÒ ¤+nq0ïÓÂŒâIÍ&ŸùÎ\òĞpDŒ{¸ìÂÁl‡¿£^6Tyí'z³nÅ²éö=ëDQ,¨´‘CÁ¬•GHÄ˜‘äşÒ*£¨—TTß2ƒ•9Õy4©ùv8îhN¿ìÜvà¦6y#iÀE¼;p4‚ŒV&€}ÏÜW´ß—ºš2b[„Ÿğ©D\pù\!-…ú%¡*Õ&ùÖlãz.şëèó‘¨YHWûâ·´SºAfÎ(ÍÌ¡ 0”Jt»óê`Èp6•ĞnTØ“µ`ÎÎ3¡Ğ!k}hÁ)M4£Ï×d.`n§2õŠ¾ÉKt½’×m3ÂËIù ÅQ,?áS8ßĞøªâßêâ³	[[Ád!Y”y Ñ¯ˆ³¥jÌ… #	}S9<ÔÿTOÃÔ"ŠçNhü–šÎÊ) ÊnvKØÎ×:Ÿ(:¿ü­Ò²EÛJ‡šR¨!ƒ×SnF†HößKCU‘@º_CÂ¶-ÇxùÕ ™îáì\ŒĞÓfŞ€é^Ê W»ª**ÑDyn”Rû}É‡é§‚Àï§6qó)µ
i‹k8´XÅlm#Xwin¨·c¨aŸvÃMV`'*1Šm°ä™ÃÈNÿœvÃµˆgB·è?ÜŞßÖÅCÊ…«úqa2óKîzÿa¤0¢èıÏ|ÖUjÛkÔÊ@Wâ=ŞF¡IR:q …>Ğ–cgÇ=åîù¿ÇhFÄök¸š«S³x§–(Ã¶Ş‰ïg_T"³Ò¼0ºÔ6.e:p{n¦™jš5Ştürİ¼`¹ƒÁßúÆ#>º¦ÊcôÚ\gÚc É|ÊóæP$i?6á$Û7áœßÒG4ágĞ$#õ¼œi%{¡ôöÈã£4O²ÊĞqqÔBêñáş§gò¹®¯yÜÃXÊıxo6­Ê»@$[•–åzñÜ.–ÆOºŸ¤"}3ó )ÀßÛrâ½ö7×Úé—ş¤÷¡F¬
§QFZAæye¥¼hêÁmXï@áìım…¬úp¾œŒ”øÑäIb‹A{¬‚ëM5ø¥`!Ë^zLV£ØYVyE¦—8$øxÁê™ŠåÈ®ğ=UP–·o!mĞŸïCÀFÊgYÿˆK	7Ğ7KúÈú²Qç‘"“U¶<Ëû©.Üµy]‘·H¾Ú"yvf?-çg!»X:<ÌlêÀSÒíí Mr¹‚tpıI*ÃYœUÜ¡eomêíîş|C†£‰?K¥µ»M5g¯ÎœEúa¿û›‚ÏÍl¶dF’FÎ"ƒÅÙïë6îëïa×ò“Äú†€à§ëÓ²Lj'#àÊƒ"++>#³7=Cœ»ıi{#ïGéï‰W<¾©ëİkÛC/±®l,”ÖÁ7Zİ2¥~Qé¿EsÔ´¾KõÄÖ¥ÅÍ¢¨8>Œ˜Ü#»ÑßmNÎ{©ùœVe§/ˆä¾Ğ¥‘TšènÔªíVE²ÄÏØZàî+¢ªvDHnÇr³‘©Şy¡
æñÎÄR´ÖÌùÀT´|Ğ®…MÿÑÀã‰t¹ƒ`.¹ì>àLÚ¿•8‹L–'İ_RR×ŞG†b=Êˆc×bXƒĞ{R‡—§‡¬{%BÛ :Š¦* 8§&¤–¼ºˆÛ—
+Ìœˆk	™ÌöO2è^Ú‹“º^1håvhèv"4lil4S½ç)Ÿuï`’Oq¦kğldYvZ•‹ª{>oÄ'®Ó&clñ¡–O0JŞaN/´0òYœzÑ)0’B‰‹ë‰hiû.*¡<ÆiúÄªŞÅûD.6¹IÏŞ-ü‘'‰Œd,²¼ñ[BM„B˜ÉømşÃøI“½¡1şêŸõ¯].Óëï´ig[¢·4Ñ®ÖÎÑg»ØœµfŞw;û“ää}İV7äÈtÛïŸÑ÷ ÈÂó/ä·ìW6÷m¾·ãzzĞo×PÏEsïà_.ÜÉ ÉÎ–À7#<ëfd89N‡¶ÙœÖ¢®í“Øëí%Æe´Îü!a+ó‡ÍT#ìH
¸XFøÏTµzjÃô<Û¹ğWzÏÜE,@
Ä½ÛÜøe‚ËäšÙİuåG08I×æç¢_¶Š•|úp®Õ@Wİj[Ê	Da2µ~Â4è|;ß^yUİ"p,Ğ–( ‹-Ì82î/v&7²Œ¥­T¬¼ÑBÆ'{½ÑqíÁ=`äVT*Î¶Ö -Àşl?€&‘JîQ«²KxNµ›*3ŠØ¿Q¥šØ‰´ŞBµ¤© U£/>€é [¯úš}Á#U¨Æìë)ƒ‰P‰©|÷{ÚŒ†‘1	1®Ç÷ìšƒsx¨t•Mğà>}dÔ¦)ÇFÁòÈC#è/ u÷åÛV–c*©’Äà²nÌä"êª¡ğ¯ÓÎ9¸RƒTQÊ±ú±¥ûñJ±¿‚ígcl5ã‚&8VuÚ‚txĞÈ+hb¨Oìİ=Ì™¹©or	û>Q\õµI+ª‘¦ÈÕ‰ÓbJ¾Í:¥
³úŒ¶>¬KPà7ÉÊ–r/K#Kkj²tÃsV'ùÙDwğ1¼ÙAä™éæÑZWÿë™ã‘‹fîÑ’Ş’¹{Ô{Æ¼)`+•F·ĞØYnè‘£_„¼K¯ÅcÎPù&Õ©vØ¢›bÍ|6Ñ”–êãdá®ºË|%•šÁkqµV0Ã0riu{0‰Lƒ6±Wí ™ÈM-R(P±ÛhJ˜¬Wd[È¿¹¾YìÊW¬añ†¹rC1LÒj¸´„àèÁìÀ ¢÷ ÚµÆúˆ:¥*ÈáÁğ¢jYÖá9(zà Ï
ÿÎ«Áüä	Æ£^0åÔÖ o>Î`Ú¨U¼’aš)=hùíÉ+Àô”uŞôl|¦?ıL
4Ü…I2¨]É~ÒóÍ…`Å©LFJUòíÎÉRÃı:sŒŞĞ¬ÃŒ	—}Ê_»ğ;¹š®10*nÿ‘• ËFotÙ¼ş‘^Oü²R$‘.í"Ç1¦$L1şˆ_CéÛMp¢Ã®š„™É}ÈdCÇbÂñ¸æ¢S³¡£ïtSÉØÌèËÃBçJœUã”ƒó©x¹?`õp¸hÌZ{Ê*&"Cp0Ç»µ– b¥lß/d”Ù\ûğ´Ë+Æ¿Dœoáh±äO®„]#Nh¼{´'tƒ97°Ê'*ÃRÛ5 ÓúŠ=êÖå&§TØ@úÓÃs„%áÌô†m¿1’¼Ga8oØ7ø›¥nR
¦âÕ^Xñ?e|<…à3Ğ9Ê(¤#·_ªf‰u€VósçÖ¹=—ªT»u_¼ÈÈo—‰¾;êäÇÉË¸]!ûH¦à¿©Åïò..Gæ{ÁŒÏù¹z÷ö m·Ù±úÅ°}úC¶´&áKu(VwîÁÄ3Hs/)+Õì4mz*ÙŒ[·j&Úµ–ÒSºŠX+ÓÌ”¹áñ{`ğóúcÎ¦]!ïÃkqèízËAM]õÔÏˆ¾¸Gì“w´9ÿˆO÷ov®¼7ì{¬ª·z”Uî,ÆŞ SMDı›÷ş©)ñ’™Šg0oÓy”µpó;†#prÏ4À–RbI,¨Å/;Äum¢'Ÿ¶°ô«eşQ;¥cRÙœë˜+^ÜW+AË2ucúS¡Uôî­Y®xesÂq.¢´’.Ëò§ÉJM§:Œxñ!Û“€Ãcş'Õ
oV¢ôºeÜH»Aåñ´‹Ğ•K“|r¡-;Œøš#;SlM”±Û°ËIıg/ó»cÑCh	)õ:]V5XÿFŸ;.w‘Ë³!vç0B(¿6»Õág±CnÇ[||À+iìMúXı :ø~è|ŠOPÆ	Úa¥?Y~Hgn\½uˆwiT»:Û¿ÚwÛ\zÄè8e—aä¢ ›§{SMı5‡‰{Vg*Ò?]m¯xXxZ:ˆ‚;@ÆÒğ;<ª|<ãrİTEVôW$¶Ş)%Y4ñ¡û#t§F±ƒÓ„é^H°-d ?×·]Çc„X>Å3¸£œ[Èş7tœ7¥®'J‰Ò¥¬÷×ÒŒDn¤©¼umòáAöøÃqücó
Jm]½±'6]4á¢fL¢»—ô¿åo+ê‚UK*@ñ³;qyƒ/¼¡‹6åR#	”ÌûUèe‹İ8æ”µ\ØÛy³‘H"@ëş­D¦C9ÈI‚MK#Òp}ÿ1Õ(Ô¶LrÕÆœ5·RŒ6Â¬Lˆ=¬ˆ!\fÿn-;tµvÅª•E¯»Ç“ˆ[‰åŠÛ( è•'C¤{Ü¤|Õö†¿©¶ù ×YìUŒ
c'ÀH.ª1SğWû_4:–Õ/ê½3¸#ş2h¤A44Ú½¨Qøy†Ë˜
kâ²t^«
ŒÁíXØjÔ“ı¡ú˜¿$NmÒñÉ¦ä…!0d=]fáô}’¹”æ]a‹»Ó 0µk[ÿêKwÀ?0ı(LŞí*§ÊìÄŸ´¼Òø5 ô :å’Kà$¾ß¦ÙòiŸiEæ¡¡å:¯G4ı¡êÑbEÁêÄE¤¨×ÏTõ9ùÇQ3İªš÷†<½ö®şcçAªğ˜¡ñ«DÓñdk³ÓÓN 3¶¾Ü!Š¨)2ÊàûSpcæÙRˆËg3H8/·l'òÍ®_–nØˆ ´›TTó;ÎÏÇ¾ŠìşÚóäÇ‰FŠŒYÏ¿qPC:oq¹†X³ÜÏt4*y!dGü•vá\òÛ¢%ø'â7BMÒÅäóÒWC–ıİ´èó?­a%mX)Ê`p1$ ~ëœ¢ö¦ò´Ê'9—Ê[²zï/ôŞ 7|Âé”ãPs§0ÖI;
4*îEŸõøò_UKïÜŞ\çE B$b
Ú	%«Ã¬| çDË36fäÜõQZl{BßşÉ7¾£ÉE‘pN¸;^÷İªS¿Àam‚ğ‚Ø³ Å Ğ1Cv6°ƒËôS$WÌşõ—Pxh[À·.¸–6kË2ık¦ÉC¿æL{ÅÉĞWÛCËxHêÄ»¯ûz¥½ ñ‡Í^Ôh’°I'ÁŞ’Óà}–üF5[“ôlaƒTn*ÿÔ@ .Î<´ö )3´ÌôóÛzb$GpêÈ¶>Ï¯½ÇÜˆ\êA¡‚]*®=—µ]õñ6şµt3}µ—\g¼QTpÏ>	Qåú‚¤Ü[q¸cĞßì7'óÌ1_@ÂUáãV: ó{%OÄ–ÿ‡Ö\Õè_„Ï½¢imœ¸æF‰­T.¿±üñ9œG—í´%ü
nÄõ A5
^ 0›W©uZMCkO€ºKÎháP·D??:©³Àû¹W¦èÆÈÎ9‰,ºäRÔ%ìZÖQ\*5ß
´ ‰Ä&ÂBŸ O°¦^FîŠ_¡^ë7¿]§kÖ£ÊÑéb°LAK?PßíEaOÊB{Tñã©!•Şñ>·«ßÖõ1²C^û­½7ânuàˆøÑ2jÇ=âèÒºm~„¾Ö†%1®j>¸Äm½p»'õ°^V_`7a…(°ôd‚­uHNšs‘ÁşLÒ`@<Û£Ê\ú·”–áë*Şº¸ºÊú\æJÏx£N
|"Æj²ôq½Ê5”VÂ¹ „½ ¨³0ßTöæç	&A¶tÕBÉîz4çŸí&; |Cn¦ÔÃ@Lı·5ú³”„€2d“ä$JMLZ`˜ãõ"7v{~æxÕ%cœ·ù!1,×S°ù™ÊĞÈ‚!¼JùMœå:©"Dğ"{ƒA,Ü¯_ƒ(cH†VıÂÌÅççŒêc^ª$ÄÆ­À¦AºÎähÇ6Ó4ŸŸ”EF]`Lë†ıœQÉºÄş$“HËäJy,™ÒÓãqü{72+ÄóàS–ë»œ™U’Ü8"Öv0ÃĞ¿7~6î¥/4R­Ÿæ‘†[m8L¥Q8dh›)läÛvØ;AOsCëúØ­|¬SÒ	 ¦c|ÆÜï3i¸,ğ*ùÎËğNç°ã´©8Ûx50báÓwiÛ2c¢Œ“>c+04S»ôÖ/„²1\¤YÜªL w÷*qü<±&G&F’¢?(fá_''íıJ‹»HKãx¤û88ñÙ£ı¶¦²İÅI`æÑ`‹W·/½œ¬^!/TÙ%+AkXĞÜ…Çî©y•2®^MÑ"©À¶ÁŸ_Å%D_)[G
ûìdt‚oÑ¤ÂÃZÃèÀSêr0Í?~Ğt×ícYÉ`*”mÚŠäÅQ¹k8¡‘õ¾[Õ‘¯ò^Äá=Ät)^W‹’kùA·´¸7÷ß»-_—ï
WS©ŸY¼òë<ˆÕ"‹2
gµVdŞ¤§J†4‚Ó'ÿ›©¥å­½9	³ 7zÿ D±ûĞ‚ç.¬Ğ°¸9Vå+c*U0t=T‡Ñ-JFLrÁ!8™A½/‚¤1 \UÊÕ¯À‘e½ç)U³¥I5t€W@aƒ Ûá2Y¼Í‡ùR¬UØá›4Ğ´ŸÿJH†:•d@,9ÿ«<ipâê8¢z¬0Òr[+)›ÚâjÃ¶G-{
*lÍÛ‚µÅB¨Q8ğÄ"Ğ%Hx>Û@à´OñäxZ®‚ç×uÂ1¦?ô€Óã{Ä¤˜üåTÂ(Krj]uÔÓ>ÛSİZ×¤÷b3çÔşyÍ$Ökâ%á=·-xWr ù÷\‰NDdG–?†åh–“NM’)‘_'µ–K,ª•œrNÏz|G(ò}œ™ß
îö.º=À‰÷şê¿>„ßeï\–E£ º6¾ÉÛç¬|W‚Ë©İ+Ç€„À½¢ïV3{?*ÕíDõvàÃóZVÿö_ò¾Ğw¦‚Õ¤&£•“¤ÕÊø®oÁg¯¦áyS°^¸m,EÆLÆìî2 ×GÃ
,’rÿ£E/`!cÚRÇ5×T=”AıÖÅ¹‚ œÕ˜kŠØWA;:~F©$ñÍ#i—Zx¬aíèÜ×¤é¦¿ï ¦'K3†®È'üÀ¸®¤xåè®ÌD`Ñè7zñY{g6•ÎûÖ£ib’`ÈÍ*‹`8Ì“#êôoxs“…X2:•g<°şa 8?‰¬¯PàŒı$È¤X¯¯É_Oˆ-ÕstJuµ ù=t;/.âı?Â’‡c¢àWØè>I7Mkˆ«|­˜ĞQv^¥Á–F£¼½3Nò$ãØ¬R’z<C[¥ş^´­Ûˆ”("í˜ª¤~o€ègœ$4–÷N`–ö72ÏÂ!›xÌLVÇf¶¶áÁ?Ì³÷ÒAâáÙáYjøÓê©‡ÏÆ:h¯0b|¡ò îâƒŸ¶ÎÜ‘kØ‚ş)¶ê;Æ–h3ÖvAq_¾Î@q†*dˆÕå©
(L»g~Iom©fö9ß¡¦wéeÕÈ½ƒnçà¨ÎB/û:é)–¼sVAºe±JW…ÌüEx8å8u>0Ì]c„ëEn'1¿–ÜÕÒÁg®}¼…–^„'`…BCk4€IWOF±€$EsÛÂµd˜ÅeŠú<™È]$‹t/G” \ÌTƒãOp–M–z€IùïTûCå<‡(µ)2w;ï÷“ıHµN©=l<£x”š ÎßS[3û…°d‹²áTÿ²+§fƒJ¡Ò=…ûåµ·*×½7ë³ÏQ¼’}µô£„äœOÃ¤ÆÍ xägî(UÄ'ñ´-´Ld!#ƒ \f—Ğã±ÉÅ ì¶€À˜ÌC1±Ägû    YZ