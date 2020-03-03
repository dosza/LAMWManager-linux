#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1284224153"
MD5="123ec13ea22e715c4b9eb89c4d360935"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20676"
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
	echo Date of packaging: Tue Mar  3 16:56:04 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿPƒ] ¼}•ÀJFœÄÿ.»á_j¨ë2X^™›ŞÓ\Ê
]M:GŸìo|†Q¿GNM!^îZşRˆ}Õ"Ã•æé\…ÁiEô+­N¥^ë6¥Û¯­Fš ©„K$yÇjÑ€şƒËrp^áuu+“1G´é=a"§çÖ	¦Îké[&¿uÒy8!vu"rıØéÖã÷›Cäaì¶Û)-ÜT)Qã…21wi?‘U[Û–ûêWà9KêWxƒ~PNQ°elÊgVÍõ‹æ ”¦EfÅ¦Ãê$è]ác{“$ª^±æŸŒâÂ<`µà®²-&o}hùËa^´†s¸…Ÿ>îKøtâı«ÖÕ’"{
‘½x±-Õ²³
ÙSöÅ¬z	YlÉ†øR/"'EtkÄt{=¶äi†äAFQ•
G‡ª'ê'zÙ%”¥râpROD3ÛGÛ_ò,o>92”¸<[-3Àª«/L6›ªÁù3]Uè4=lÔÀìk“”ŒLÅ¿ÊÃa¬Ï{V0ğşn˜ŒnÇœ½wzï`'G]SÅ~3¾²ÇÆk Ã&$Ì „M>‘„V†â&Í Ù¼õqZ•\WO´šÖÎã^zµ‰N%¸M´Ó>=beJĞpŞQ¨™k‚E‹6`?fÀ0	Ò—†áfxÛ˜Ø®É"Ùc†Eõ®ÿ˜¬¾i¼ëŠ‘¸1_‰ãg*ÂØ¸6I™O×øçì#.äµFŸ[­¾ˆØ_©°ƒ1¸èYĞ­FçÓ ¸à¡Ú†á¥d}°1£)\ÕcGgúmŞ·—PM'ÕR©Ş5c2	»ÄcáĞ”Ç$‹úyš¢ç7L›dìæ¼jºR® yñtÆŞD ³¤f‰uA°¶1 –s)hNüu`¿GÈ£ 9vkkKk•æ|nÕT?Œ…„š¾#]€znİĞ„³ªó˜:Meå²ô§Ès£¯Ÿ,@ŞË?ƒëÏéã¸ËWR#¨R`¼¢ÏP H‰`Ù‹Éo¿*pÂPJk…šŸ'ßËÜjÈuócık„XÁ»ÜØ	Úpg,u{€Êí6¬,&|,)ÄÄXë/s¢x®ıhxS„ƒ˜2ó«»ÒÛf£ˆç5öUÕŸ” ò‰	[lÄú¸ÏtI5	9_o£ÀúşÒ?z4Ì.uORz×Å‰è® #À·EwÄY‘Â±vBªõD–ÂÃ¸-¬Å·qTÂÉ8ú€@«…°wCäeF"/
=¨ÿîÛd:­”1£§Õ@X8Ôê g1]éÿïQI/½+@-©ì›s”m©%á‡¢,æy¬/’jòÁ2-Çæ¾ƒª¯ĞñØ'6H©Y¼–¨Şu[qwBª;™UlfŒ3Rëe"éfiÅ¯(lW½òÕ1<b¯µÍ}Yª8Ğç#RÖ	ø,;Óò–Ò6Ø S_*’“kõÖˆèÈùVüv2Pô­¾Jdiò-núâıŠõñä–¸yf}XØÀUŞôŠBÜr–Òä2B¯hõ¦‡Ú¿·’ö	RcğKÛ¹à3¡ŠF«gËÖP¶²`àÁ¾h‡†Û+?×âö{®Ée6[.İòEæÙd?áæëjG‘½ğî)$=A9ÄçÒ¶)°&xÈN´˜¤ØÚbĞâ·k‹dË„ä2+y™™ü“­éj‡Gw3k|B£PT0ğé§ò¨7:±K §B!fõBÎºsÚ0DDRc¸l:R•oq?|iö]Î)éUù€ìĞ¾Ñã±aRşl„ÁšÌÇ×¼Œí¸›ƒ™¯y’æ&¨èĞ²ÊãÛFú¼Æ(ıt½Wé6O¸¦AğK]˜’ù>°ò3ş…Ú2±:ûzˆ¹ën2áÃ»r­~29f‹>ô¼Ş,8Ög’7XüœlËÖ»…EÑ;åÚ÷h/8£¬¯Ÿ¡‘NGEÍl9.yÁWf±’ú’–ù/å.·W¼øæ¹Q±6(kØõ¸.†JAÒ\´‚ö„TâÇ³îŸ÷H;`*uõĞHhÁe(Õ†ögÔ)ĞúªñÜw³Mí“NmDıcEö×Òfİ¤E#œË’c~,ˆ[µz µ'ñ 3u8qp~(X×Æà·ÎìlJ¥.]ÅÑ€óõ:‡O{ƒÖzš›—÷)ºgõ9a5Ş6îH8îúGeiVHÇèAlÓ›Æœø: ¤4ñêè¥MD®éoÍa£Ïr®ó/óß@Rµv,°¶âº<[1ï$Æ*°”c¨©î…ç‚RÎJ‹·¯#«WÈß²' lMğİâíçcøØ›†(éaûúÈ»Š…0ñİ]¶j«]o½ç9«×jD}î˜JØ€0&Š‚BÔ$ü\-Ÿs¢r”d‡HTŸÆœHòîE—{7Š¡µH¨ì—â,ı^pR™Æ¸mfåÍ}”ÚÒ7„˜Êàn	L°Ñr… ­é …ó6gùV‘T®A7®en6Ÿâ¿»ê(e¸”ñÔqªó^ÿuLgâ©î	—>Õ¹ËòÊú‰SN‡‡ëam¾ñ¬‚5½m7",îş…®yrîàÇ«Z{Åoƒz<+BG,½»«a>­³¸+¢X\>MH×A'®j(³ßÕVS¦OîrTŞ™ø¥z-HÜ ná™/eƒ«?LFm8~Ô;º€d«Ñ Ã·nş]u8}Âã4AØÈ'Hk[RóÜ#Pkáå,è*YIL˜¤Ğ
5Å‹QÙ€×±
ÜÀ¢U£!¡•lÇ0öƒõÛ]C½a?Å(÷Å'ÇKùÂèQğ‚#Fï¨_ üÍHù—É1#w-s–‰¸zô´ñécÁ­¬ÓM!Á±4m\m±±Š&I»GFQØÌºªj¶½!4Akık:U½ùRåóR3b¸ò®öü¾@åhJ,šR‚Ôªu$èlı°F¤GEÕ`ò£Q¼ns/`‚İæí+ƒ?Î‚#M‚0ÿUÑsÛ2;¦ 7}\^7ioV™’sÚHß:º‘?¹÷»sS–Ëş`£‹OPÓ–ƒ"oX¨aE«4W
CöH'µÔŠ\7äBÛ X¢›C½ˆ¥)@·xõÇ³r1â#ÀÙŞp²óî|·	-JâìYƒôÑq&%ù]ãÃÛÛJã&¯LT~ó×Mêæ>Q=ç©¯&¥ınCàä'æ„°ö«Œ İ§wâôXl ¡ÍÃóßıÆÚj–ä›Œ’TU¥ì¶Øö†4–¯››ehvZ|Á¶@¡¿ÙsM[¶œ]j¦˜â™M¸KójÄŸµ )c{z¸sÇÉ¡ı­I¹Ş/u&
=U²S$YªBëIÍC°ïw8á®·¸öÛCc½fÿY¶å	;¸Î¯¢§£›º}‹“j±\B`Õ‰@şBĞîÑö†htË@á—<âgÙƒÀÇáfŠá0§^ø5ÊœA/_Eü®§‡¶T%w×YPÁ]±ÒgY@?íà
mıTP…–óè‰b×„áNş˜+Eñ„A±JäUQxdağ\Z²¬ ˆˆC@
rÉ’VßÔş™Z‹dµ×Ã¿#Ÿø\‚´›÷@YÆ¯öËúÍD`Îk4ŒÒ]è[5»…×ÿÆ»ıwxMaj2jâ:l™ŸQQƒU#~Ê»Y²K®YŠñ
¤L‡¢•pÄá§½ˆ‹Åıt.(îLj„NŞ“O]ıÁÚ—'C0FiÌfÇØõ±“WG9PØÏ*eÑLáKQ€à£>ãË"è;…BbËÊ¢$#ÏIC5
<‡l!”™!Æo»×¸#ğØ”ö³‚fjò¦ôX9¼/{²ÊC\ò—(1#$-ì”×»(Í\{¡´(vsØ}K¸´LÔØÓ¬f¨j	Âyö®Û¢{-Ö=î¿Í‰êAM0æ”‚ş4kèˆìAñÎ2„^ğV-ş¦Œ<xí±Çà¤:ìò·WÖÒÂãdV_ÀP'-Wñ)»q)oS¶!¹5ëõ”é‡FÍÛàù Ö—2ËP[ÆŠ"Ñ;ÌCÍU’•‡¾iß#Ó‰¾{L>3¥>©^˜5ñèk%ú£1À¹çUÇ˜½ˆ3¾æçMÆZèÆ©»b-dÏ×˜İÖîı ×-~…b;kûq\ñ5JƒŠË‘p	„U	¢yè—À­É¡¼\‡vuÇ¸XM¦éwesì×²(¬y™Ajq·qG7Ø¥ñÛ•x-r]^<RèYäóœïîâx4«¥·U¢"Õr¾·(8°
ÛÁy¼5ü[Î™c?IŠ‡¿÷Ô!-üá’âÄx*jØÄ¹Cõ™mJ*¢‰ü¿SnÄ6mÅH«xÅ9mß¼6÷pá¡Ú7!%aYúU²‹·iAÙöWğæiÏNÖ™”£ ¹²ÍŒ<bÚßb¹mÊ5÷$3^ùkĞâñr»4Ôz«¶¼\aë®±0}]˜A­ÜõDEİèğj…Õ_v—f£Êá[Ä{0“‚Ö†ÑFZñ£h›§>wnOEà‡õ¼——Í[Ó…×­â™âb²nÖôÁ7„#ÀÙôPAŒ“+Ã	ÚGæµÍä(·ƒ	0¯0€µ7”ª¼§
€jè¨ş²?ZÎ³§ÇôïdvbfC°BÒÂH²Œø ’hA›ì‰ì¾ÛéÿkØS‰8Å§cü#%¼?vèí~íDÜLÿS8;·zh÷r'úg^×Cäƒ@]_y»áè¿Øg œmlø…èzÃY¸†:$ãòé0%Ä¹RzòüÖrT@ØVÄDt?¹€ |OøgTƒŒ…øc
ş›.ˆµ¼@ø3V«Åaäùz_ã&ôÎ0¸º-–Ó¾<C+j¸°´Mj@jAËİ\Òèz9Y˜R+s³HÄóreT9*V[q»ÇQ]s‘ílf¾Â²¢zpBúÿM¦ ößwİ@ Xrµ`OÔÎpT[ —œègø|éüh‹¨ĞvHªµ·ò2[u˜±àcGúğ
éÏIµÇ/+4¸…Ú¢Ã,¨÷ÉH`æïrÕ§ÛÅ7(c‹kíUâ¾t<‚C”dk³€ûÈõà£‹Qƒÿ¶ŒÉßK¢Õˆ7ymlSã4ŸİNNòg`a¿üHeVn–`k*ÌJ›ôƒ!ûîš³ölé¯Öf”P˜cAßáÊÒ6Dİh'¤z5õ²`o-e¼’²-Æİ¼`- z±½ÁQ‹Š[Dè[/"Æ9ÓÍZÔçM¾vJŞüP~ôdªÉ³+^µUè_ ¨°Å”¯³?M¢ı>RC4ı‹{xûLŸbØå¿`õt”`um30ÕÇj8Ü¶
vËMJ&öpÀ1‹‚8·iìÕo2í".~Hşÿ|Œdû/S ÷ñ_dàüíWF»¬2ò¨$ƒæÓQkºş=Ğş{qñ*(yê–ÒÛhtx‚í\>)åé¬×®°¯Z¹ÜˆsòØíüÛ‹uqS<Ìj™ïno‚vu¡£/ùEáŞÃ_9¦SoœñH/¥’‚‰sÒ©+ O™tù±Ô×æ§áâ`øUi’wç¹=-WØL£üäë=¡õIŸå1¢ÙLJÁçé¨¼YøïØĞ”‚s\Y>KÕ?TÖ¹J,5“$2YY-A¾ÓŸÕU[âÈbÕäğ	3òšÏ6Zˆì;1Êq„İß
‘¾ ËI½èÃ!ÜæH$#Jdºâ“öS¨ØÛÊZ„h-'Ä#äeÿw“	Œ ™…#D^e÷]¾9'¥rÈ¶€º2zˆ…º7š›–5®]°´*,Rı]2målAöå€Í³‘Ğ”²Fq”±î°¼ŠyÅçZ|œ=[“¤Œeº¿U‹<ßÚô¾Ü‡uGõoK˜¦– ¼_‹WÕô[Ùbb©c›ñôø^.§2Tiÿ9ë5fP£6ş8¦ -ÃãÃ ×gš	|ã SŸÆ}uÿ*3ì[®3¦+3\x7—	[µCIåYêL‰¦Fåï!8Ú0©\a?Cª@³5W»€…íÇ’ûMê¡"=6™ ">R±µW­K‹µîÙşÑ‘štrØàÄÌÁµ¼8«CsÉGª;ÀìÙ¿7à|^ ³óEƒ³À^æ$e©}‚)(Dd§ä»èÏˆÛ¯h ì#ñ³>XÒ¬˜·OŠÊR²ük¢ùa#I§œ®IŠJ~Ídwt`EÀcN
²3Bˆüïøô ß¸H|…€TUà›jV˜v#¿¸‹äç¿>íÔK×„•9Ë.ÔÙfM¿¦ŞƒwŞŞ×PN¯Ìf·Š§w¹¯{pÉÉ§Uü3ã¹pÌG¶J~%Æ¡Ë	ÜŒ‡Ò
ğÀº¸‚ßˆ¸½·»ü%|:­#NÈq+ï	(,)±Ba‹âˆ‹½¿wxŞí¨÷,ì-k¨}.\†‘JP âo=-9¾L%–œüˆf…}†ü0¯Ö+ã1æ½ÙpæÏËéıÓ¤÷j†DNS-éÆVY»˜”.:¾l$ÂsÒ2¢íQƒ&éà†*;Y…§Æ8p8¾·í]Tä¡Œ†®H[]¿xèÈÁŞ‚ç¹Œ+1G‹G%_paŒXééoÒ‘FBÑáR	“Ÿç²Pæ¾î$÷á¥ŒFj†š¨+>DöK4<»®qœl»–ÛkÊ©2¾çèéT¡)¼›>"~‚AíÎ¥iM`¹êÿÅ¿>K£®@EĞí§„s¤éÙ_Ïhv-(ï'#»fIíš¾Ía4lÌÚ\Ü©Aš*ô°&JeJ›=d%xÈ9ë7rÈÒŞY×ãÉ“#„ ¯M†4êÆqGCÕÔş"5èÜ»¯7‚îË_•Ü$¢Zˆ<¾¾‹txdìLÖAéìaêÙâ(’gŸ×“ùŸ82Š¬’2ƒï„“€Ğš‚-ã‡å·ä'Ë¯>šÜJu¶àmÏi†)×å ¡œéJé†š:€ ‰ú[¡Á>æuTk³ø3T¢J¦.N$^›Øó×¡§+­VŸ,Vvôæwƒì”Á¹şF.‡vàíê¢š*)ï>yÎ Ä@-y‡)é£ËÌ‘»^œ7GœKz€1)£íCöÃ?DœDÚÚŸáÙ,ø¢ÄÈñôÌÏ³.3ğ©G Pj@‹oà¥R;«„×ï!£P/¦ÕŞıEÆÜ)x€†Ÿ°:jõs¬quG9ie`÷D>‘%Š{×dÙGû1ó†¦)âõªvó°OIeî#ĞB	ÁU$hêÓöÃ,®­§^¢Ù†âuÜÛñ+kdc›¥ä¯4ÂŒc[ÎM€š®OYŠÖğºõèŒvÏíõdMÏ;áş‚åÊ’¬Ÿ3„¹éşÊŞ o«DëC~ã~_À¬ß£Ä3cªy‰ŒV»×Zy‹°ÈÈ)ANØŠ‰†©˜ëÑŒ<ßÙiJ!äÁÅA	ÕÓl§¯Ñ:ÃQœ„è7µ„„)]$ÅOn’ØE¤Ä}’"´àÄ‹ª™â‚Ã#š8^]ü³Ö%OŠ>°0»‡òš¯Î|¡Z.í²Õ¹6¥M>+V®«` ¨˜Öójı•ƒ%g}›6'ïííOmï<6"æX«æ)‡iŒúZ=iÌ"y-¯øšxé—FI2Öî»\0ÒÑÚ¶ìıİyàhÎÒ´Ğ8pÌ³0vÄ˜½aic–¯!MsÌEœñêÅl3î®bêøÂô*rù±¦KLœmùz5s±ä›‚ÊÔ3jtvŞ9"3şi¬ğìÛƒi_Ú1‡ĞçöíıaÃ©‡Ùê¡Å|¸,œD'³ö˜^«ôùvPGg¾×ŒÛ2h|ÿÈ{…[ßÛ¬ô‘¢Ê)]ÈóåóôI"ö¯g˜6¼Ü·[BÂ#FÜR:ÑĞ6¢Cí¢o~P¤tÓ„ª÷ÑmÌíìøƒÂ,Á¦ğ@¹œ=¾¤áäÍ´ m–ÉJY<’p¹qÑ4yã ÆtôÄ
†·´Êë÷ŸÑ¢¥åÜ/éí¹¶"ÕN4tÔœKAõÑ~Z£OÍhDDÏgÖ"•šêS‡ù–İÀ†0/jö;r©<ŸÑ/Ö¬'G(•€¢BÅ°‚4²hğ<:ª®cğ/¹eñt“?ã]XßÁcHüJ~+\ƒôGxMÙ!f|ö¬úüç…L+ãÏ ï9cˆ'Šf=N¿¾ø–(¾Ôh?¹ÛSËÚ¬xPÓâo Sg³úÿ¿×@VÆÖÖõ÷Ñï”u?æ#T	];¬Êdkx)‡àŒšŠ sóÎ^qÓı=êı1X^€Cà5å<0@ÃgBxŸfökïş!ÓVS½ÔM3=1Á*Ptâ*xõ¬*;j?Z Òû]*šÆó&É%Ÿt‡¥h¹à
}bä>I‡ –4l9¨D9›0äD…d£@EÊ(½¾¯E]Ö2_gŒH¾©çŞæH&N/Ap·iÜêx¾y¨§´_Pƒ™l‚bÕÙ9$cìİ)èæMÊw)4°ôÍ`rŞw2Åÿ.°LÈ —°‹·#˜şáh`Cfgfiuìûº©n4Y—&bf œ¤9[Ğ<éÈqãá9¿Ö<òÀ1ó-É0İôŸêƒü<@ ŠÛYø2éÿáF1N[ÁÌ!&­1v¶ëòİdX» +ĞkOÔoùƒ°ªm•;^h>}ğÚr_¹ Ù}ˆ.n‚nŸ‘S1Êk‰nõvWLƒŒtú[3i,Qí9Æ¨¡³>ğôŞßÎ6C5ÕÔõ{²?¢+E-ju Â1¹²QQš‹ĞÏ½ğî^ş¤–¢êWF»ØÔÊş<:q/‚=İ<é;«š¥¸^ğYİ"2\uÇá1ƒ±²¹ùÜê§pt_f_€ä&fçIPÿÁ§ÀÍÂëx0"*Ÿe¶d¹èZÈW¨ÉwÕ+NrÂ>ÈÙí’˜®ÒS>rE²ˆ ¸şª^‰v»ŠBJ–í9~7)@åÓf“ĞÂq?ã¦xîõ™+Œçõóf6l\ÙábF=½€ÒØ¦8©%HKb¿™TFu¦”pš³Co°Ñ_…öÓnWÌLv˜:·I,QÛ¬B¸\Áôı µFÉmÚñ1Ù5½É¡•š‡¬‹@:\1÷¨-6ó/ŸSôÚ¿ÍGHŠï ÎàÇågNK%¯¬‡–”`ßÃ|ãš\4·ì…šæ9Jç”àÅ}g
Æy4Î=€ÃŸc®ÿ ÿ+_Ú	‚Z+¸ŞqáQ¾½„û-ĞæŠz˜¢JøÃme®dñk®AÖLşø­SÏÛ÷/ô§ZÕVí*`¼İˆÊx©î¯¸KpìŞöœÑBäÓ¬ƒÁÓE‹…ĞÅ?NIÎÁI¸}7¢Âi;Ís1İK¹Â©*‘@+Bs–,˜oä¥!·¼ãÖæ†”üE>æ1L×É¥×ãY‰©Ïg(x°Ö¸vÈº¡sh¡€j!iùpÚ&sæ;.ÏÇ!2G[àoQÚ©¿{ ¸©©}û&ƒø½ØIÇevFíiÄ’#V	/ßz#×»üŒÑW–¿'.sd =Håu…ÉrjædG×n½¼új¢ƒS¨+êkÌÉ®F¡ıyéd±>ü+M›S-ÿ¢Ç—É&Zä¹§´NÓr‡”œtıãŞ§JÆçÕLÍñÒÒucÈ9Œùàµä>QÛ„7hNZS§èíIs'E¡/8]×ó§~LX>Q’î»Úg«Ç¶Kİ,}’6‹HÍv@bI#à‚WŸ‚PT=ïÚ€m“¿©]µks¹ˆ¾9t
ìéÇNG‘  'ÊÑ:Œ`‡ÇşMÿ«éIKê%œó›i9w¥×2õ'j.×vbS•~¨§Qb£‡÷M1ñˆø1È½>k¥Vö]0´¥ke+3u œ’Ì¨­^> ¸díÒê4ºeì ÉFx.Mq×8Õî±©r
5v# L°3Øİÿ‚£×ãb>rK§‡YŞİy¼°I’’DÊá|{Å³ê†ù…³Ù&‘İsÈ¯ä–‚Ÿq½)=È=HâÏÅùE%d¾xI¾©e>Ÿë
tè<Xû×$fîiGß«ÒÜA±ƒ›Ñ=Zå×)© ƒ.Ìo+ñÂúúwÔBÖZ¬“b%ş8¢¹ƒ~—õÇ”|o *3ä2"âyÎ¥{‚A6”v90ˆ¹(¼&“Oêœ[´r}ˆØiU.@Èdq	æy¥ÈöÆR³ÅuN0]7rY~|£ÓU²"eÛ!¸ä}÷vŸRÌÂ‡õ (òÏÁ°‘=Äÿ’J¸Ã¼WHÅ¾1äùêã	yKˆ&õgV;kW8Òøçt +)Œk.Ê :Ó4fà8àŠòŸşrƒ…L&‚+;6’Ù)áø?½’ë(S¨¨) "	½$Øê¥æpXí²âÒñ³—âx“«)ilc.f¯_U-!DOæ•âi‚¯p8DöÁ kŒ(ÿÄÃ4¡R0#¢Æª_$¶Ô‰øGv|{hE«ÿ7€äÔØÙÑHD¸Úôº)3qšú[“ñ’/Ò¼÷~AÁ¾{¼öyG~»S-Ç÷P|¥tE£^E±ûØß+$P¨]_?ÍßàÎŞ¸İõ²ÀéˆväÖú–‘d8—ÏRoUÀÌ¶ä<P¦€êÊÚÇ8„ìÓn^îå‚ìÉZ}~u8½±†É)á/’@ôVE–_'eÇ]KèHTqèvÇN/‚êxîÏş‘jÄßst‹µÏó±1ªL8Ú#S;3|È9Vz>e×1Lá³ÚQ`š‚a¨GÉG´ôsxí¥7–p8ùW(T$7ÖeúúWTÆ•€yüjÑ}Ù*hŒ.o4,3¤ø¾©Qw^¡VóÙÂsğã4w$Á‡®‹,*ÚL)\•ğ;åmªÖ¢]îvíb6@^ãDØã›c;@Má^÷øW¡©=[ûçÆ [i¨\©C]ÏUjf'x¹&kÉdF;ìÊ]ç‚;t*ÏóœõqÿW‘"ÖésX¦8¸OY8 ›ô³Ûg`É»–»(”¨ŞàGVT8"tt Æ)`#÷¿,§	\«éåŸ¿(Ğ cSm‘¦™[¸“¯¤0~µ’­0ã8¦G“—wœùxŠ0sÌ š´æØYkL²U"}ñ&yÁ3'c7º«¼`;ÕÉkIÈì¡gÛ¯Îa.-ƒX.è^Ëç¡„Ö¿AP
–¬ı‚TLzV‹”­Grøõ îTP†—.óíEş&XºÚ/,Oü++>»»{ ]%Í°rƒ!§bíG\ÃeŒ¶+†„õr#Š
x"Ït†3¸^÷]=‡
ñZr›·fáì[õ <ºë[Á[Ì¾jmO‡©^½—ÕqCÁ{>@’Øbd ŒÕœ,:90ÖWh`õŠí Qá	\€û÷*üg@§…ˆñ¥İb~0ïÁäwNŠñÑux°–Öi¿¨AÛ4‘¼ş¬8üÏ‘¾
ÕZ‘ì4…óf¹`VOUıûy¤fÖÊ4	ï5PMx°*\×°™¨fšK]†òÅ%z*¨iîÖcÍâ$k ™dÑºÃ¿7$pn¸ãà­
8Y±¶æài) Ø™Şå´¸Êa28"ù‹óálôAß41ÚÙÄ†ŞËÅZy¨ÉşC×ü+pšGòPcİ@} öPÄD¼¿sa$æE''ñ˜ae„OöQä(ša5¬›’ MKiv?Üƒ^Fn•a¿ı§ª½)¦&Pã÷š`$G}E˜¨¿U9±¾½¼ŠdHX°-Ş°*EL«ÅÏ\FZ uÀá€ò>O0‹Û¤²’ğş·ZxÜv»¥“‰¹Hü¾Iâ~h4nüøé}5šl,ë¶Mó\0ßJ;i9éúöM40$;ÃtëİYàÏZæ8€‡n8È\˜tÛŒ£Á>?ğµç²ğ±íµƒ}?ùJ-±h+¡ t”¤†¬F_óxábu°Ã—1Ø2æÜi¢¶ùà¤˜cÿŒ‚ø§ÙR¢Ût÷lìîxaßÃZË™.w-Ùsx€[?äÿµ”³8äÙ³ÚøñŸ;êòGªÕğ1fµd²kBæ´”õ¥akZ×U¾[ÃÃÆÒ˜hKB#nĞŞ'hÖtºa]±Ø`¿Y„$ƒÁ+Ã`v^h¾Nß(“T²j¯ÿ9v`3—Ânfº¬á=şÁæóbi~%(®Ï¾I0Ä·İ!/<ÆbĞã¢ğñ2t}èu?4@­£EßÄ)PŞÒ/Ù?¦“k}[ áüËİ/5êË^8²¶òf<B‘B´ÕO², EÔº"¼D…<‡_oÅµÙ§–ƒUï<
¹|D¸rŒ†4^¢Ì¥Ì\î)~œöÖù¶©‡¹«Ü%ïš]¯ñÍ‡T¥ÊŸ Òõzœ¯üV(ÓA·V	Û€#ÚòÂ6?ÕÑ !Y¿lAlÎ 2&~îj2
RBõÙõİ"OvŒ®ØœJ‡¾½®Y"íØ’ÚÁ“®¼Ùó.Ê)ù¸ e<4 `CÆ#Á4ræÿ%òuÇ†T¹9üÎİ1Î á7@*Ñ8i§?Ç3b5…P#İ¤·d¥HÀÆŒYF¯Q<¨Nµœ¦V
jÃfÈ±yØr oĞ[ëK—PêI[Òë>æC^Oék8	»fÅ>ø´_=’ôl¶+}Ğ¿%ûx³.…§“¾è­
º×CıÑÀ²¹ÂdŞtşué)§tÚ–Ø=‡vÆ¯ó^Æ—FT[JSæbrÆ«“¦I/?çdô]d×É@ã9²Yİy`ğpÀ6BÏM©È]5øö¤AE³ngNqÊöUt5Q³!nvŸ óAÿ-ñÅÇ«IúàâoõíÁ‚ï0’³ˆ ‡•Bc9pDèh†ğñó$øvºË~Ò"zË*›ÇgéAğ`õïaéˆ²ÚH3‚v‰¢# L±=¡ÖgÜÇE´Æ:xå”‘É±Â«1æ V~	®a: Ùwç16wl»ÛıŞ¸äUÒ#Ä—tãÆÊ¼â^@íG¤ò^fºÔ¨$m¶‚•b²?ÌÀÉ\ï¼ïÍv;‚«Ñ‰Õ	z>±µŒ'Ï(G¨â²\›qÚÚ¹ı›«¹{®c"ä<º‹tıŞëBcÍ#_*„¯Ì¡‚_ú‹’¿®n‡!*‰
“%ñ«jÍX'b¶Ä°.Ê³d-Ãõói],Á¿gâlŒ{²Î-kşU³ôîîHãµáešI×5,™(Xƒ`@®ğyªL0(Õíı¨ÌH„C…Íƒ÷vd7æµôÍzâÎ …‰\Y#¸òzE¢|,1'ª7ªæôÙÓßÛs¾„.ßøMIMUó[ˆàHD˜Ã{UH¹ÓBfÇ`ı5$ 9)c‹ÜÕˆ~
¼¡bÁ~:Î9›óM«ÛÍ§‰3ıòãúé%øc~|	^šÇT¾–èC†Šãç5ƒÓ¬bl@µN2úÄ7ø.V-–lZIù¦œn:„EÆ0|Ş²=uĞë;¼ô|±µæoRÚÃÁM±EE ÖB‘Dw$~ãß5qKäÃ„¤§ã‹KrB%â&¥=Gœß.¨š}œÿh‹¿Ò·[ ÃÇ	KG˜³¡ûıŒq$äÚ<Ï~Rµjg“)FdÎ‚.^Ü—°sŞXÎîŒ+SàÅªP /ÒäRu	İÄ;8.ÑRU‹3÷’íÒFsvÁ}-±¡½N> ®i™¤˜³¿”qnìJœBí¼l²¡É4SˆÏ´=ux)€Vu4}šc‚…8;`ãÅ‰À™.-CB“=Uc´cñ5€ˆs•"›ÓQÄÿŸÃÚ×£¬“(”ÈZÂŒŸ(=moÂq+ ‰e½mÚ}OCÚüL¬Ÿí~íjãıß‡uïßÛ·t|´Àë\3™qzíÜ´ï«Wj°Y|q_„iÖŞÂ[ á$/i‚²…Ì_[[µ˜QœùíÄç,yU±z©TFÓê[Á¯µ¯ÍÁ(Ô1Ğ…Œ%OÿÉU;¥µÕ2¼Ò?ÙM6¤´³¯PY§Â4ö¬QèêĞ§Û-Ø‰=ÜñüÛ®Aud<’êÁİAx4dä%­›·»äÚşjÊ¬M;dÌ²IL‡˜ˆÕwŠ0¨Ú
A÷	¬u"w9Œ~î®Oüí€™LÏİë÷fÚo®(T‚ÇØ½!¥WÎòs5í‰¬V	Õ'Í¦é>=y4™
$á}7„€I*Âd¥bxm¸é?SÔx1N…Ùÿ¶7å$ÔsSş«u{ÿ¥eÀËÚôJÈÛì8t—_Ñû1..b]¬Ï×şîæÚL¼†L­à–É>û‡©)JÕR¼Ú#v«]:¤F¶çÇa¾•¸¿FÛàO¾~SV›ß,Ñtœñªz œâd9ßHŸp2£yyÿ2 k
BÄ®õXÛŞUt	ğ†Çã¡±øj­Ô-vÍç}‚ø9Å‘.§¡˜K¦¡œàIaÓdW¸;¼_ÊöBšKŠs1_÷'¢Z¶úø¬ÇoÁ!2&­å-Gc”l¶&ˆcë?@—†D/cÑ0#”0µáéô’˜kFfzEnSÆ:Œo\Èµ]ùŞc‘-ˆ0.°Û©9K¯9šÅ§’ (&Ç´<RÇÀ{Qñ2Ü(F¾y®|©á—u51Z¼ü7",$˜ÜOÛ+‚Ê$‚´º“n¨ÆmÂÉÁN+¥ë Ë{ĞûJyşØ2Sf,1|}?ò@8¸=çQIø¥±z¹àƒòç-$%ÆqÄ *tr´a$
æÚ JÄ÷C´¯ÒÊõJÎ“‘Y~¥×Šæi?VÔé†u§w‹G¯ï‚«&›×mŞ]ÈªxC¿2H"õ–aVQ½SÍ;?½¿”ŒGliCè†([:êP«ËC«7EÈØZHš ®BŸ…-û+m„©Å”ÿõÏòiÏxÆ`‹p.~çßv|ãº	N[Çı 42«·ìÀlÌÄìâl"’», °G\›DØİ¦vÂ€Á…È"óbê?ëJ!¹Éx3¼R¥84Í0âŒ‰WGÜpÎ7»xåc[¨»u˜“Ô}Ì~Dîá1·Trw”>@M¯ÏÆ¤$ôüzQX¹>Pá)º!¥u£çÕ©¨.ècâ_|×ÆSëD+,|Ÿ…¿ÒÀªRah/X.Ü/ªz²÷¤ŸE°e6.´MÖ2À~s—-TŒL8Çê…Ê4FÕ·¿[Kf °f^¯|t(~*Wf0öµÆ‹;q;§]çH­Y
 ô@Zœ“s¬nÉä9ñ]X±=¡Û3‹éç²/‡+×’OÇ÷ğ—æ?qı#®‹¬¦º–ÕoA×²'ÉxøK—EÌû²M‰Å¶™§G.uª¦aĞm‘TA7>øs¼^Ù%‚›F%¤tmè»5Œbœ•B#ÖË®Î»¶ˆƒøÈÍWeL±‰¸L'îÑƒÏ¡55à6‹Y}‹]èB¥>$±ÜKäó7#úóW)ãUØOvƒt)‹$ƒçÂüFÁ¹kßõô¡‚x´NåP4ÔáÖs»¢>İöİ'cE©5ÜÁMğe¼Fxìé˜ªT1ç¨ù“Î¦;‹ñÃH¿Ò"¿äïR, åÏ½ª$Ó+¯lm¹à¨lJcàîLU¤q–’¨¡×x´¾5ÑŒV\£Q?»}BVB2|SĞ›Á·–b©ÆmÈ¿X¸½Ïì†"ø9Ù<mÇF0ÜæìÁôÇÃŒÙAˆqÉ¼•¶b`5µ¬“|}§bmnğİM¼;ĞòC¬_/A6Ù3%Ä´ËfÁuÆäfY&Ej“Ìù#…›o¬Í§Qu.)Ñç:÷Q@XK‚…X§Ë”íõ›=QF¥Ã™4ëG
 ^v/#ïêô3©NÏ#H,A)ÖKWŠ¤œ'÷¼üëÖ'cNŞÈ¨ÃlÛò¸o©PrHğŸÖû¾yGz}›‹•~–ÙÚc'±	lpšŞÿ`’HO„¼ú†ó¨µ²ø=_"ÒV—óÿ¾Y–{&İ–ç$à{½ìP]»;s:› ØÚ\z'‡üéÛ¡«V2‰¸Ğ‚šôj”$0×i‡LùIÌİtt)¾¿ĞÙ
P`‘ŠH6ÅñÊî qFî°"6g§Öş)ØOñ9÷©XU/4ç¦·¢dâaá˜û7`ËÉ=ÉADÊD‰2#éÉÄ[ ­aÅÛ†´ÄÙrCu‚.mJdI¬ÒùäYÃşø“˜V•æğ,6<
Ã»:ƒ,¹VñzÎ6wønÎŒnSU6ù0Øb‰‰.@ç|lV/6&-‚3_Õ©š‘
gtÄÛ$v²ÄÃÍ7–‰}pvW«Ó}XPX=——¤|,x’SóÇúP&Í€„l±/²QB?YàEËÌ÷¢8w2H†Eà4Å¨Í¬½Ó7h¤5Í­úñè®¿™˜I©íó*q8‘µ*ôq+›4˜„¹L‰$‹ÕÑjğr8l"©ÀeÍá_‚ÏíAfùÚ8ŞàpÒğ”óq´,s­âŸC>9#]ûäÁÕ¿³
ÙØåG‹&³l?EÓjÔ€4uÚºòŒA*»<>Ë¨ç„#›ìï2gphxßA®ÀXÖrs-Ç[ ¬–š»¿è“ºÜ{Îë<Ú€qä°£Q#öùâæ0ĞÀÒgöR~;tA€J©¬çÁ\ËãnJP¬V&€å?Uó,ŒÄ,®' pÖã¼Eú¬_ûîZ„l¯r)dBeœF%¥Kqf%w|e–,û¨!ƒÁÂ4˜ó“…	‹f¿¬·4š1ŒŸìT´¤óˆLòÄ°n°DZ÷¢óØ¯°lÕ:óòm;NºËeÿı$²YÀ©EK¡^œO±¡´^¤út_ãm÷¯€vÿ·×ì'QW®”e'çg¥6º‘­“øıB^#¦TD< ™Ü‘U2}r7tMĞÄÑá9û;Iù¡ä¿ÀÔ'i³t Ú{ê÷Hì¤M8ŒpJ8l¬_w½+ïô¿ò .º”ÌR*äúD…™¿¤¸	P—”ÌV\¢£©EœññÊ|óÚk3éÒlÊàt"5ãRfJMç¡¥R{örL“X°œªñiÈÈ‘x@™nxTÃ>BÇš/Rç!‚—ºÉò>Í–|Ê;ıRî£5EX$Òô§Gù›ÓÓˆ&~Ñb¹5Ã¯m58'7(p'7Œyf‚Ÿeu£É-Ú¶‰£œˆ;É	|»7Ğ(Üd5õ|På×ÔµLÿç…Ö`uïoOV“Âuc†ŠPĞÆW1Ç¾ZíécäíDÅ¸Ø«u+Zjƒ$LÕ$åËşßšì’ {}³ZÆoù&ÜÀˆYÉöWÒ7?ÊG[ƒ¯'!DpntI|±q`LÄ0cŠ™gõ>e‰¯Ëûı÷'å¬\&áî¥”	¾}Kf7®³)în¡£AvG‰¿ğÕU?+ËŠğ:¥(KJµ(ß²œìµ[°üÇ‡
ÜÀ®šÎÿ´Ü FãY„õX5ìmEwé¿(m-…¿nd z?ûå…ìõ¼öŒhv;‘ÂÆ#Œ‡À`t¢ÜtIÌnı>LõÎxOW±Ö	”À!læÜøa©° Ğ;ïğ¹ &×ÁJ@6h‘)Ò/š”‘>Á%Ë)u°ÑË9{oÍ-»ÄlğªZ%·ıÇ¶Oö›ŠnWÿ@)ƒÛ¾5¶”<¿¸nëóš0æÄ’)Ou]Tiúæ:=nàjxÄƒC'<Ò¤¸È¨éò‘á§N¾şÖ´¢#›ËêÙSJ5é ğ@ãaxh´ËöÔe|³´×Y‰¶İ|˜¸›N5°}‹•“ßQ03¥hŸP¼ôŞJéö²ö–(ç§fÉ€§3[juÕÎ1OOšáhÌÁvåĞ¥Ñº”Ğb¼àŞ¥©kpÄÙGËSq’İ©Œ–u^ë™Dæ„‚I9\:Üp42Dä%N»+«Á¹|ş¯Õ?ÙF‹ÿ|²Í—ßMĞ\ù%T&í;P~ø[Í@Ç´Ãƒ8Ö:šáyš2¦üd@/ ŞîÈÀÑ˜Bß‡¢=DHpšË@¶˜«°+¹…|ôÁÍ³jË7¼Jbnğ‰>>ÃpÆ0+;ƒjmS( ˜Ÿ+ €Dlwc*™Í'şd7?\D½T–E‰Êh,M>o¡ãÄÒİ5ÕBqPk¥ˆñàÅ—ˆ±¯Ğ~{›Ú6/1{!Ê!£Éµ(jOƒQoíl¨=ÖH*^©øÓ°6Xê&‹Ñ]¶4rµ*¨•ÆIƒyFÙJæÍ»ôànl~|‰z&G³û.–-;4Íp²lÆ[6r:ÿ¶ß§sÚır«Á\o'õ	|/‹q:®OËDÈz¸‹J%Æ›ÍH,“2S-‘ğ Ø|/ã3oÔU\àg¥lğF9VåÛ^RD>O˜ÈÕâÙ_¦·;c²7Yäx‘×	dêwÕ}	K\™7	€YJ&:QñzÁq{]ú¬Ñ àÒ‘¤_ÎÏª¯HÎWı 1Âè0\úg´‚ ®êù‰à/£i¶äÎpc ÅiU‹é°Í¶†ÈÃbğQûõF„øxŞX½9_õûyJJFË=§˜oà5Ï!a><Œœ téhDŸœ×†³‘Ü›İaAÁÂş'Á,«O0ÒÒ'}·Ùb&lØú
2ŠÅÆbìm©ğ´L[¢:* rß>cÕD3.ÜCè[æÓ°Ï·CûhéíäåsÔ³É½ÊÈ–O-(Q¾ ĞÙRÉbU’«ÜwBğ³øˆQ·G…Óã©Šjëûo#ú¨ÆJİÒß±7ùñS¨e]]øÔpÁ[qLO’¸ùU;°€Eí6QëPTéXô¹-“¿¼êDãk>úİ4a¹Bèì(,ÄpNhQø§>Ñsğ0õX¨W¡]İŸmøá¡k/ïÛM+ŠÊ÷Î³õ½êŸ¨QÂ$Ù–)‰Ÿ¢³§£fd®@ˆxv’ï.´–ÁS¬S†‚¦VO§]“<˜ª<Ë$‘È(6¥ĞğBQn¦¥Iv¿^İz¾F\'+Ú/ó‘ïÉ´ËâHÉc­Â9=ÓE¹WÖxÓª_yóUTô¥"@İÆ“f¤OÇrX¤¸FëMQ{w™k×Î‹ƒ†ÍDa´xS6˜®{î7¨8{%‚¯
m
8ÚŠ]j	4MÁÁb¾£<ŞBëìÌ—w*÷œOğª¾ÚWoAf':.ËW“²W¡¤FdW{ßà<šqn7"3Q¾CàXĞê\ µ
¼‡Ôv9ÿmãè'é1„kÊd|HÄ£sí3‹Û:#@T G˜{6X’mcRIËï}d%ÜÅ¿}bÿGTntkê™Y¯¸éBµÆ“µdl§
‚â!>êÎW„¶éZ­…ôierÔŒ}úCÑJåB¨2¼aşe,ÛÒ2×5ğ*cìÕ¡i®1 ÜØ‡û$/Fv¢—ÍYÙø‘\ö~¥aù5mºç”à¾jT£Ãˆ®ú»ãÕäuÀÕUm#Ì4Ñì¢Z˜î	¥ j¬ä1äİ /­…¬ça"äê¨(_¸(ÑGJ·^G€¿OdCÈDmœ*GrŠğÎDnVRòë±œ¹S˜‰d%åŞ@v ë·Tşj‘ÚÜ¹9‰ä: Ò%û…iikŸá‰á'ÇOôXSEä¹6c”âÙÔ;éò°§“Ş¯GXçJ ¾µ‰‡²*3="³Êoˆ›°7ˆú
ÇVê}s(¦Üº›09S5GR–©÷g:Ö•Æsı¤FŞ—¼¥Iu÷hßÉ´D<X2×¦xƒ!§İ\·Aû“%°ûĞ4¤,ó´£Ş=fÓüp$op9d¨·ó¶mmjFœ‡(vı„ì…Í¨ı «¯“eÒ:Kò4v¯T5fªíCíe;ÑCÆÄ-Né¥ÖaÓßÅ<3fíVœÄÒ?˜—±ÊuÜô5F¿1F» ª3gÌ»N°QÊÜ7«Äfíi	À|;‹OC¹eícVóüCÙ”P&”ZäğGAdHsÀ”›=| _äıBÙEÍÑôé§Aèè/ß=‡çÇş¼Í¡–O‡íÍ{*Ñœéáï­d¾ÂvørÆil»ó©‡Äg×Óh°y&PŒf¯œå:;„,¯e)J³iZŞµQ§ú™2š\…Ë·‚‘¤¼7^a,çy¦­<ÎSmíà‡òTí&Êáí[‰@ÚGp¯è‹Y^zAÙP·v0<<rô&!¯×”:á6æÀ»l¾Hr}ó`t;ÄI\ÍŸ*Î' øà!ğL—€ÁSr;-Ó@Ÿ™?)lO|Ó€f8]0YB…€lº¾H9•ŸC7K$ßŞd­êº
º‚Z”ûÓ%u‡Û…|gòš9é¨ÙØè·uŞq)ä´ëKnÜCz‚R^xKÇ 2¼òù #¿òRZİF£à\xU›³åÉš3|ê«,¹DòŒf­Ãÿ½Ü×æO§šòbŠÏ…â•ä¸¨®?A#,ìZ¨·òßÍöœê»3²œî–‘Eâ(ÙÉ6÷iÒFªäc¤í
¹³Œ6L=usà´
ìˆ0ÈÀSa+â3ßú6jÍØªercg¯ Õ<=‡ı·=s¥[Î5ëF¤iß>d.}Sè³–¸rÍÈèµëşPøÉÉ¢`1àS. “lëî J·¤GĞ=š´åÒ—„ìà¦árö¬ln„ÃFwê…„ş.§›¼ÖVUê7O6ó<àï Øğ{¬İM:È¹ñ+Àœ¸v°Í \í—ä
Àë…çnı8—ºGDE*Î.‰ÓS/ÔsÉ‚éRß½âËY-ª–%HLvVÆò-	S¬%Ïe}k+/C||Ó‹O»˜!ñ»ÏùªÇ mãñ€óŸX7ñ9q‹"Ç¬E”äjÙ©ÙuıißËG/cIt¯ùâ3o4¹Ç$³x.ì¨ı\ù"æ¤%¼ õ9.÷µsûQ<t!K,–Y¼Ÿ„wäÿÑ¶âUû.Ì]ä„côÜ	ú´ê”–5fMMf”œ¨M
¢eF•Æs¼kP*¬ƒG8i§º%¢	U;¨ö3ÈHó½Où‡mµ“Ë–3.Wİ¥Dkñ2ö±aÛ#‘7WfĞıÉõÖ´bÌ‹“¨>BÙ©6³qÄ´&E€_î-—p=ÕLxu<m•ô‡È*ÙÂÅ†R¹q¼ò‘óAˆñ×¥S^¦˜ÅRité‘½šŸ>ôÖIä»‡ÔÊ¤R™?J(Á;Ê§Q"á¼gK÷fà&Âjs'œéˆ÷!òs	¡¢H¼T«b)1)Ë1úœ%'D‹áÿÇbC`dYÜò,ÿÇl Ä‰wa´§0Jyï[8H°} ¸ÙØÌÑ`¿µ„™àŠLıDìı=¾E˜I¦%KÚçÕ#î·'”¡ ³åÖ š•úxHk¾;òœîw9™aë İ< °kšÈ(y³¹ÂCØét*ùpÖ¥8üP;“FZéJ¾t%Xìç´|™y=­ìJBÔ¬	ùŠvÄ¢\M¼Ôğ5Q„HB
˜I‡½”À&³ó·ÏÅ8íš…¾Á/ÌqyR”IwÔ•‰ªÂ0æ Èº)pOk×|º'Ğ	w¬Œt%áÃ»‘_Cy
*a“Ñ1ÜB®êÉàÌ]7…Ÿ~ºfà¶…-¼1<*R±ØDÈ—té…jú
w!Q:'ñtWÄú5;å’Ïhkg‚¯[äVw²¸õ™Ş.´e^‚æàéñ"Ë™Ó‘ô#ÃàóRØïN	ş£ç†Óò:}0ïà¬»øFPJæäj×Mà…lÒ}ŸŞ‹“gzÜŒ„‹i	eå§ô¾Fr°G|ïsæ%ï²°”^	lûıw°RÀık¥G1ıúµ„
X#1V†İ-qÓíaÇ‰
Ú:ˆõ¸¹Rm}şö}›£<ÇV\'×2Nf.jc²ÊÔ »¯×nÎ*ºM?Wõ—²+×qtšS2«yç(E°hŠ~êÿ @8“Îÿ^‚ñ'C—Â61orMÑ8·‚Nf¤<NézÑ³†RqaÃ0î{E·ø¸¹ş…¢ˆQL’7¨5óÂ¥c Ç±:üyl¸8wNÒg‹"™y!B^¸E±µô˜ÍSZ›¹ïF÷hDÑ·µã¸i‘¡‚hİ·]iLÍèĞ®H²ğ½dá~¹ì]|!¥©;)£+4j“‡Š¯	ÏÃŞO8ËÕîçïƒÕ¿ìähy¼5Ë²ÜÀxº‹ÿÕá¶·n,VÔÎ0+ªZ²Ş£B¦w;XJ#µ¥Q—sº<8“ñŠiÆÁLñPñ›äz„>s^\ŞtJ”_œ9_$âT¼#¿H¿…0kŸÿ(HÏƒ	b_æÒçÊÛçğŸy –4~üĞŸ$`€¥K‹/?äĞeõŒ x%¿ £c¥0ù(]\&o¿Øbw×Ëi›Ì}®ŠR¨jò‘Ş\Û©-ÖKJc…}×!½B8:Ú×²OÒ­#ÉßöleƒÕ/ùÉ S#˜ÊZïU¾û¿Ù†ağÛ±@^ÈšœºÅØf$â}p_Â	h|	ŒkúíMš•e$tKH*¬'Œ1Ç®Ù·,ŒKxól;w'øŞæ?|
/ñw˜ß89IW?t#„Ã½h_¼R:drè¾dSOä q½†CPç^˜dgDjßS'•ÁY¼äBÓ¶N`(Ä¹’Ï~½Ì¸·yOáGàCñ±v>~dÂ÷åğ§,J*;ƒ(.PÕ:]Vµ.ÒeGrÃÒxsd0#x« g×S{ôŞ5IºÍ«:nø ÙÅÛ„•CqÈ:­êršã±@6Æ5§äï<ïd[I˜d·:“Œ[DôG`ëu®ï(äÑ·‘¸ïòq°[Ó›ÅTVâ˜ÆÅ$†€`ArkX„l/ÈÈ5·X2^fÒ p)QËÙ”Ë:VÔ•›YÄ×j~í§x9äÉ?¹yjİÄøï"±ğD+ıÒô^Ê)k³0ü†M¥
²¯‰ Ç<Pè(×Ë„â‚J´Ïéëù”ªÕM{W wÁ=‘[ßå™e-TÊï/ËqåGÚxƒê´Xyö>Àğ1U¡KšÎx¸º0ìÉÖ]öİó{˜2Uª—PN–¤„ã¸J`¥ƒñ“È3-l>Ô3ªjùÄjHè­ÍE"XÖ,à¬-ÿIû¶¬¹rò¬ÊÛÜL!|P÷:E¨6WNJzŠxsáã"d& ºØÊ¢yÇ’Ù˜3.®œÕ“¶&/ÎÃášZ<j–İ•ÌÂBI¢7àx°§ªaÌe¡°Å)'¦÷Ÿ¤°¼‰U~÷×ıÑc¨ÕâßæÉè•wõ×-İ3üaò;òY•B Ç	O·F¢¦¥sıË!ŒØÌKµCdE²:@ö!‰Êœ¹›>Q[ƒñ”4“{nö£4q.»h^ëO<˜ÉúƒôwPÓ	Uë@WÜ»X »uv=ÌlU+Ä_ïĞØÕx{…Ÿ˜é³êèæ”»&?Öw¯=¢¯ÏñÚ)|-¹t –"NrÖÿ	"ØÎaÑ¦•*9&¬„Ö©2Öÿø¸šc–ÒJo7¢¤ÓÖÖ: §¿Íİ)}õöĞ~(Ä†Åú‘ëíø şÒ¥\Ù¹]£SI<é…â5%¹ÊÄqßşv››dZçö™{^”)ÑUÆLñQ{
iE+ñ€yáÏÌĞR?Œl4ÿk­µª»üjÚø—Ï…Pï>K3”€ÏÙ[â¿{ì@ïWêĞms—„€p›ËØ­Ñ Ó†Rè³=”Úè©1¡X¼J‚ûÒóõÙ¡6Õ¶&CÎYnç.ËÍDÿŞöôí|×?JC‡|‘ÿEçŸ™S’¾/UğÈËs‰ºŠäPåÊ¢;;ÚÕõ!ÃS=pM­ƒÆ´2Ïô˜…@ã$§ØMÊDó-»{¬©ã×iªpŒëÖ¶Ûr|K„•µ³Wy±£€«}&JŞc´-½d ’UâG‰şPşÌz¢aIá=RÁ›òlZ¸P%çH_MA².‚ßaYü|`@’©åçäô’ÌGM0èöQ…îª¿¦?ä@|™bİúÃKìO
M„”Ğ<Û°çÇ6¦
(wîB%'½yñ „òLĞ@5L›\ú\enò7Š<wÍk;wräÏ´¸h§j›p<êhyW½4¬Ú3Ìeÿ¬A=î¯UG‚ÙT«éÍñSoÙ¨}"£>Î0©Ü{S’Ğ3×³œyÚ™ö™€«Æ˜­åf˜YıİÙ£~—;t¿3#Õó_ãÑÆµ=BúJ:û’‹ÕI°=­<pv`éüıHßà+dÌ ñÎvk1‡*Ò±ÜÚ>üÍSqtã‘Û×.o|O3Ôu¡…Àµ&GœDş•‹™ŒV‚	™L˜¶ÍRµÔ8ÜÀk
±TcÁßsËó®h[¦è·‡hVŒ\Ìs‹÷pÏÓ[ÓvŞÒ„MdYåbT¤Ô"¬3œ¯Şˆ‘Z€Ô4J	¦vˆüá/ok^ì“ºÉû/ç2W/öLëó_â@ùIxõASB•Rd"ót„A¡-t»zËê'h4T2ÒÓ¹Ún¬¥'7ğÇÇ´›Ú\ÚeD4 {”M$™A€¶½Ë)º›Aß›³–ì·DãKä“$È÷=&Äaî5hn›¡UQX}ö”„6Ÿˆ	â~|Y¼¸{Éæãåm‹æ?_ùæOáiR›Ï„´Úı8¥§ñØº½}Ës6Z 9vop‡O ´k1]:nœ%h`ûCı{Ñs$ÍU…Ü7#a‘ºÅ÷™CX-+}„JÇ?ı9ƒ¦ì$cş‡…w#€~©ğÊŠê×DMĞÿCÃjR‡ïA…G’Ğ¶z^lñä"Z±Ro5›ªªu©}gôïÕ*Ú:‘\*oé?:òhÖÖ¤eiğ=¤Yâ‰|qoÒœºàæ¨Y©¤ ÔO¬÷]	Ô3œR=G9¨!E‰ø»ÌUÜC£xcĞ¾Ğô¸©Ğ…¸#éàÅê M»]oÎÿd_ãa´ÒPqxX”ÖÔÙvô—"Ü¸eOÉ'@ò‘m¾jÕåT¤¼ë
{ÄÂ(§ÙLßƒ¤t‡›¨­r£¹õôå—Ò\xx)Væ;šDWó×ã#¢Şå\‚à‹01{)ÕßTòûø{ŞbşşKÔB»ß„>]Mî¹¢r¤VÛ»{ÆjÒ)°éZT&­}@8½ÄeFl™Úëj…Úvë,/™nø‚³;ûïœ­b¹9#;Ïİq(~Íğ·îŸ°=FÖE¹VÂîÜÎƒ@ÙEXInï¡H%Èfñºä\£ÇA:šĞ¨›+öwmènĞSã;ïæ%šû·ÉDôs¿Émµ©hû(‡aTˆÉªXDåJÅx—€DC:"ô$ãƒ®Yµ{©+8ŞZêšéMC„»½õöÂM	æ;!aûn/åëÂ²ö3q›tÀ´¾5†¶Ÿ‡šLïl›Qdl£ê&?ã5Ggüäş§”¡9ÔJyÒ¬œø•#Uë|KE­•©p­8¤|Û~F› øï½bû˜Ş[¹s[Š–ã ‹|9”t ù<!¤lÂ=êÀb’ŞÔ0YfÃf¢|Æºª[§xHÄféM4Ì:¢Fj/ş´‰-gSkÏ,ö/	XÚ#Ğß ACpÉê¿¤ç÷ºT[ÅFLªˆ\Úš—XšDÕ	æÇåø š1²µC¸~Tæú“T¿'2l½·ZkåüŞ\(Ş?¸#urz•,O8©Sññ_ù|‹6ª”ÅÇšG0Ú	x]ÅHkÓªáAˆwæ"õ£[Ø†¼°NÂıRty'Â§‘“…Ô0­ÊWsø¸hNØ³U ¦kP–ÈRı¬ü¾@ÅãÚÂ\\2—’,Ô&O3\ì…×¶Y‰°Ì¬ìÚp<—F—ú¯jrèIïP¡™W5ÆßœHßÇÛÿğågŒ¡¨ÛÉl
¨
¬öø{o~[ÒRºy~Ÿä3L’b¶`p.|St±>Ó°¶©&zç ûDT£ÎnÎÆ'ÓFLï<—'LÕ#$OHó‰X2÷  }sÚ§xyr`AßB€îÿÂ{dm£"Ä/)Pv@şB[*ŞZÔ½W¼!fşÆÇ°\tàì0ŒØ·í/1(›’L1‰¤si¯ )]ë{QÉÜ¥øÿ¥âÌ“$¶ËxÃã«Áı7ÚG®(<xıÛü[˜~‚ŞörÌÇíFÊÌ»¦ÖMe2Â%
c"K×)gFz÷­˜’, ²»µe¶;H(Œ;š^D’íÂ2>ê>ìƒ&¼!¨­Yò_õÊ®ÿE@ç³ùÇ¾)Ğœæ;àkv½&Ú
«ó¦¦Åä#,	ÔIK¶Led,sbnÒÃTPx9ÛÉ†,k\Â‡°ÔÅŸÀÓjäx'…ºŸÄ*6 FOqVuºå¡ñs#Ü™EEY'Ìç—¸"õL>	=mÎ}[[ûDà{") óóúÈ¸ÂÖáV,¥›Ég3jÌè™µ)¢¯4\fÛ_Ç-*a^UÇF<î€l‚û—f…mSEÃÁ,¥5&â~™\·l¤•ı»ÒãÂö¸çÚ{õrö¬.ÍVèVŞp÷R2°pƒ€Ì¬øƒ?¸
+¬şŒÄşÇ’Üú ¯ƒtwVÜHöŠ¾ûÙp!;ñ`…èÂ‘’$f]ÔVş-<vkò`ÆŞbĞ(I×#™;'	`ÿ†‚‰Dß ìRÉĞóİ,ÇøâZe"Ğ¯Àâ(õ©Å`*ÎrÕöx)ı…6”¥éíÏ!–ÿªª|ë—`ÿ¬Â¬Á¼GÀŸ°ÿ˜Ò³E§O[3‘Ûº~ƒ-¾5N­ÃQf£¦îUIŞqdO|å (Å–{½‰–yÛßN†ÃäÚ›ø„    	ª" æ> Ÿ¡€ T£Ï|±Ägû    YZ