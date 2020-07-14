#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="465891706"
MD5="68f1faff28b4e9064529f900b40d2640"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21316"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Tue Jul 14 01:23:16 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDUSIZE=140
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
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 140; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿS] ¼}•ÀJFœÄÿ.»á_jçÊ7.B&t*\!F‰ ìVõğ Í¡ğ;P¶(úh–) +#ÑıêA²ºBxÆ¥?æ©Y0Y’”|sÏŒ»Ç4ØÖ1‰~æ?6²¸¦´! ó'êü• Â_Á*%¶*ÏæAŸ© ÷Åç1§æ-LP®/¼‚¹Ğeƒ™´Â-H„¥ñ­a¼-Ôm w“F–ULß0]æÛ€€G{¯y¼úğ÷ƒ¥‡¼Ìs¾ğ[RNWüØ*¿jÒ³©Š|é™à¼:ÈàŸT·ğcK§²Í+8`Ã¥¬Ğ.x´Ñ7G^`f-ßÂ2ô"XBÂ§h_•}ğj7¨· LcŠéáØ]ê½Õ¶™X}<¹)Tü«D¸d¼áÕìÎ&nHÉnõ[$ğ<ˆµfHıây^’æ¹kÊûUÖrÑ	sÍZj±L¦Ç–|Sk@I8nFDµ»”ZÀÃ=Y¼ÖQUcóJçÖT,(®Ò	\yÜÜ¯qš/øD&€V©O†ø@íxHzŸ=Ì
49 ãâÅ‰uyü×…Z1{ÊSúà=¡Æ(1q`Ö6r%-“_ÛØĞtªbÄ·?ÙsÿğT-ØFßf),l-á—R’©÷[ıé|¾Bc+³º÷èû˜¤àÃÈy£ÓªõÏ‰í\gŸ¬q"8±ÁtÁ^x\ø jDùŸ5gŒÖãÉG¯øĞÉ&ãê2ZBûyNì¹vV®bZ>¶ú[ÀŸ¸‚]ÂÅt¥ÅoH]Òœ45:ô'¥zÊŒ*(
b¿Ái„ÂûA#ÀJP”Gşø¶c7Oñ‹ğd°	Šü.
³Ï|†ÊÆb@}»=Š¦±÷X¤¨Fxnq>ı­Ò¤îç*"@èÀ³[|ã,ß	ÅïÑÍÈÚ„$uf’İ#úUñô¬'5ŸŒSË6Ìíl6øt»A>zÈ½%º63ş}ÜÚvòÍA—è«Ì/ n,52m¾Æ‡„T¹n
¤_²	´¸ÁQ%/ãapø÷Ãÿká?÷„ì,ƒÛ™Ùû`êÜ$H;“zP³„Ö„ôÆ„ø"ˆÕ :è¢ò¤¢;? šÀ®jãJ÷?Àú…»{¥éEÇ†@0É§`…ÑÀõdÃôÃ“ƒ|[N*ÏddïOXï0ƒís! ˆ‘i+!QÒç<µ«‘š›ª‡…Áü8ï)çW¾¨G¾~ï…-3‘®u<ıõ°ş"““şWÍ<¨ˆmÖf´*‡%+~¡XçO‚ãöN ¯Yd¡Ò>Ãtl¹Kí•—…ŠïÇMù$ãõ¢Ê^¡•¯êmÖ´ü99&õØÎf
º-í…(%CÆqËöæ2·6£Â]?av½ôÕ½ËÃöo$æ,ë×àğåÎŞ7©Iß£Ì¨¶Q
iÏ
Uİ‚ÎRá’.8!Ø •kEŒ‡(Ê>[?‹ğNmöA‡v#GÙ–¶N™ívªÒµ>åõgÂ¢Hf/|¸WìíÛ÷×«• Hhs^î±ò±›ı±’˜WrúëS:ˆëÇFkÍ¶pEsÅAe(/”Y[2_-ÆGüO–J†±¨ÏÒÊF”ª~ª!ŞˆÏfûSg+—¤m×°lUn•åïÄeJÓğªÈríâ’ßĞyˆkµ‹#LHğÌ2¢¿tÄFRùÓù
)0ŠeÊa
p¹®Næ~È3§{ı$F×„«¦Ã	¨DË€N3`d$€5b¹	ô“ÎTîèÁ5É}Bà “ä´Ï‘KiB™rØë³TÚµL¹)ˆ¡ÖÃtºP‹ïÍ?.7|bÊ†¬ªı€B:8¿™i;7±>
..¸Aßñú7 C¢…_.'ULi½åÎI”\Ã‹s¡;Çßã“[Ü4â×Ş0iES÷¾c-pK·k•`3šFMÁå70g{suİ&ğA,Û§$+½ZøEWA¦ƒöÇêàƒ^jÊ#K'Ã\î×ÙË-¸ÇÒo=ÒD·&`hÇÿ;XPrüL8}BX?ü™ïZ DLæ¬"Ì”T	nû”Şäú$ V%6ödRv Õ¸)ˆ…HÍ…²­„êÅ¸ú6…éI%ÓÅñóô2—ğç°°”—ƒœÈŠv9™Á¾Ll-Q»+â®à ¹ëËˆşçÚé„IZr ,xã«R–T^é®t‚imäøu–âÃYËp"³G³+K#üA˜rú;Ï4Äò­åSŠ9êéeh˜Y]LòmÒĞû¡ã¿ËZ›ßÓ“PdoÌ·j¶P¬5ôÜ†‹ùÔğ¡1`;õ–ÿÑJí‘hE;ù^B°ÿò3C.éşİ´i¶]Oy0v8$Xâ@ücc¾48hn~ô«Ì?åœ½ˆOˆFÆ]öîƒ'ÜŞ)ü)xbÌ³¦ê‘qt°AÿøÎ=mgâ3ß$ëË7ß,Ã1Ÿ´ä'<Bk(í*ğ ¼H}ıR…—hÒ+r×W'pSš7ÅX}Kùõ®nÃ{èQÆv¬o'ñ€É ×Dô¨xaJ	·gïêq„[Jè?+lPãI,¡uí–e«9}É^šˆœ'|ñVX¤MhàH8nÓ³¬Ù¶&|&V8Åáa¡äÙ!‚ aK^&|ƒG”Æ ÿ#9MÃÊº²w,Ü+..§ÑÅKÎõéÆ	6­ÈÒÊTïîøñA2H8Šùnô¯¨ŒšéÁå¬ì¹§İ„†œÃ«E’ \A0|$ŠæL:"æœä©xL
w¿f¾WW0Ç¢"e†-FNân>G6NÑ9{Æ`P¦÷ã™QS£ñ©xÿ„pªıÆè‡UÓRÃ \ìMñ=Òì:Ñ¡¦²øïA&¢î„°âé@³Êş/b¥¸Ä–¸7â—<Ã¬5ß ×™Õ®= ¦±}yÍy¬©-ıf!Ò€Í•‘ÙÇÄSş“¶8XP#ÖŞì#M™Ù`o–Ì†º² pJù:k“u‚¢š!ÓÙ“¡7pBG[L 	`¾v\9ÒoK/sêi¥Û“vöç±Y1F‚±”N!‘Íõ,Cm¹×…Aâ@?DÔ)»™YÎ«z.‹) ;ŞOªƒKÜ†Ìk´ï³‘ßfİôÍÕ’¹a†4íJ±V¸%”è¿UÈ‚Wó®œÏˆd8rœ#á«› æM	ÅzZù†]%G!.ªƒX¡^7äBP…Í¨Ù¾‡@e$ÇjB68ß¥¶W“M½+‹L28ãsÃŞ|±)ÂÇuw‡q
äĞÑ1^<«eilä‡c3rJóŠîÂ”ëZŒ_¤Õ¹½…Œê-*”óWAßò!W+"†“ñ5ßs¥B¼3ğ#U¹P`ÇÉ¶t¢ü†‹BÚ[ËbkUQšÊ!ZFp÷C'Ht<ã¬dçˆ‚‘dºÔ'ù%M†ıW¢\‹äv"æÁçÑ‹`á3õbò­ ÍÚuq
†'\W¸4 X¬oÍ“/ÌâÀŸcœ×¡XTøE
ëG±—Z«(Øp}ã
X¯}MA¨¤€l>ÿB£TBzIsÑ˜°qV^"ïJ<‹X ÔA„Éq«]ZşÚ©Åj 5Äø{x#ËV|×«²RÅÃŠLø-ùéÆÀ?‡õ‡ÍÎë^W6È=ú,Zf”äC^§|ßzÎê…'—'r€•ù€s|Ë<±ÿØ¿2šÃçÉz[-ˆ$\9¯ÔFOÀÑŞºÁé‚ª¶îgçb«¼ÅßËnî™æ
fî¿ÑëeR;'W£¹@;IáCßöBP‚K<d^«[èÚ nâŸ\é39O"U«U±ÂüiÈÑA7œ—HlNïë!kºO ·ã7H¶r{bÒ½õ6Å¦îÿícaµÀ³Îy+:<’†l—kkîbn)fJyÑéŸ´­¯cuw³İ4³Y¹RAˆ`OïÑ†`Êy–šÌ6AAa/4IÍˆN¨÷ìB§Î˜T½YÚ9î¡[W™{é+—$rF I'Ÿš[æü>ÿk»•ŒÚØµŞnšóNå»rYÖ®6=ôÛ$Éº°DÆ¥ edÚ2¨Z±C–cvª)µ9æ‡;áTêŠèßÈÚíú´9·QC¹Ôç-ùğqJ´Í„z=ß³-€U—ƒÛqêÜ¬ñ>W‹É‰§\ÿ×œ&!ŒèŞÈµ`œÊQs05ó×šåÇrÛşùÓ’¯NVROÜ’ü¼ ÷ånÛªç*Û\û©†9XÚ{Î‹d=Ş“«%ôäE¬¿bÍfæäCéÀ,‘B?Õ
&…×¨W¾üûÌ¸`„u†^M_ŸÌ£§µë\ğd­s­±¤|p(×<«F%ÊF;ß"®áğ{¦±>ºàÎĞ³[«5I)ÀÅjL2±Kf_¤æuIeA„‹hl‹+aháW½á»y+øl/w¥g§«W:ìyÆ¾ù$YH,WFÑ•kEøËl("ëqA%Ÿ[¦%˜Ï-u3…Sœ]ø9¯†:ä& &[,Rhm…k»ïãvGÍ&™¯>®$Xør|æeì£Á¢Zó0ÉÚ’1Ğ8ÚÉI:V"ÙmJsûiˆv¬Äm÷¥¶>
®Í3rqÅº/Jş/¸¿Û®·x\ø/4–°ã6 ÄJÊÒËUuË¼2õf :.$Ì5°‰‡é€ÊnCş'wj-„'n~Õw±?rf,Û_‘÷[.Fòëî>®¾NÉO-"Õ†Œwº×Ú.¾´¦x´ß‡Ï!#ReŠ	î›„{[ı3Î.ª'ÏÏ¢iÂ a˜2D·Ê1{¥\;9t¿÷ı3ÛÃ¤2n½hü9)ùG}Äÿ/»7b·g„É¡?:¨Œ¡"‡­á¨Ök·R06uƒî¯}"&t¡Ì–ß^˜M<å¡Ömôt¯÷4T‘&;ğà_P K7ûß¹Eû?\ãL[X~¾Í
»œ4ër`çtáıì™òÙÇÏ9Xyæó,¹ÒÀéúB³¸OÑÇè]éiÀŞÆÖ’ªæ]ÁÂÔ•4«SÕ~™MŞãàƒÀÜÂG´ØN]ÏF»a€2"Ä]òí»"\²Åğ%wÓ~òŸrÑUØ‘/øŠïŸ‹ø,¶Ñœ`ZUhx$m;ù Ó°@\jñö¡#_Qì7¶–ÜƒÆöO€Ä»ÓË¾ÈshS¬ï]Ï¹qÔhT¸.l#IVŒ­BÒHğ~z¸sŞ‚Œ”òct}y á âapQ¹„ŞEÏ®!Öi—Š¯CÄ)p=jMjv}èe~í4q¶ülMŞ²ÃÖ„¿—x¦¥	ÒĞŠÚşŸ0¶ô’b0e)C’}ÈÇÅ7¨+±J>.«cQï´ØêÔ¿oòYÀŒÃ`™yZªäõ„xyo0“$¢„ÉÈt`·{?—";	•şÓ+§}n<±á”éŒÛ¡Ei"c¿'cĞĞAH²Ú1¾¬MçÔºíK—ÎRJG`Eû "~¤’qÂ‹ğvğ¹y#a8¹š9•~ò‰^G3G$ÏíÙë¯Â’ ªo«	LƒAt4¾]/^İ’õÒ^ã'óìO*$NïXÑi$>„'›X3h;¨"áxŠvßÁ°3Í)‡ ÿ2I„ÄÉ¸”¨'ê£q¼ısî©æY’…CæÁëM¨Ä wú&\K7QÀÒfóïàiÕ S®95z‡‡–ÀJ®¸#X×¥]áÈ*É²Èc(ß·
#h‘»4s?8ÒÓ9é9_;rÿ’Ğ@ƒ€¿©aGZ.éÇÚÚ¾ê‡S¹…©Ø4“õ“qÑF5Ù»SM¯Ò€Ş8üúÙ }òWîdzj|l(/ÓŒÙşq•S	3[[eòæSş¶#vFlçÙ»há¦ãÈG?« l†ˆèbš:œMßgÿÂB´¸ª>®ûS6o©:üF•2‘„®!Àfë°ë§£¥¾zg“‰ä!EşÜ„›âp›~DIª =š	ä°Ìñ`		<TGc¶Š†rÑµƒ).§¡¶£èjşë„ßpS}Qéúí‹œ¡¾A¬¤`3ÃÀ†Öü“}MJêœªô‘<³qzŠMytİ¤+Ù<Åo†7Ûr|Nñ÷Ñ¢Œo(ßRŠ¬rZAò©ØrL…Ó4&w¿RŒVÅÏ;7Í‘İ2É|‚ª‡
İ‹[ÈÎ4ayM¼•ï]ÑV¸l˜ÔœÂ‰àˆr¸>z‰gx}×'S‹	«“=[êÑ÷Øv¬jù\1Ãu‹ugAî×…5$Ò'-ôQˆ2Cùqâ3NĞèÍ˜™X¥¥·À‘l¯šb"ƒòº3§uŸ¾_Ò‡Ğñ4›&ÚbdõïPELë!í‚zÅ·œJÑg›<äR’~•éüàµÛ¤&.WÚ'õ¼ı®c±Û öúï¶vh¯ºQİ¦×SºØÖ°ë$ø]JîÇÊ(£±l?ÙûOŸí ÷ş4‡ß+{Jœ×ÑÏûœYU»ë——âØ]¦ËÿŠ©>7-á|İ´!4pag¾LÅÙ¬5CÒrÕ*)ğN>*×t¹ı312 yL)v¾1Ù'(3}Ò¥Í8hQŸNŒ¾Ô¡ŞBØ Ì³*ÊKIÿ ¥ÒÀô ¶ZìOi)zíró>±Ô×bıš¥1ÄU‰!Hqô±£¹ıß›¨\6\yšM('Åğ;‘1M›ÇğdvÜ µº³iqL˜¾êûE„şŞ|•Xm"°½âG'£_€w5q’|g³!À«Èà“,.†^eIo.¥©ˆ¿¶~ØÕÃKn@bÉ-½ªı#fôµ_UHŞˆà©RúúD\t É¯-§ƒ‹•4>@ŒL&U~#í@n	}çH ‚ÊcÓovù’J'’×"¼Ú¹x]ä!~]s€ßìÍV~›º6ZÀ·ÕÍß{„eåñ/¦Ÿ+¾bÌ¯FÇÇ­›Q¹È«›ù›Âõ¼nëõhÖxx¨éj·åà,Eç»µ[ˆ)C¦ïùÈ y×t\á!…2fÁDù×³-/ëÙ‘”zèÙ?m>¿4#¨ÊôîğÑÍ¬[•ÈîÉ©å­	Ö¡Ê R<¹­
l	şL“ZàK“I¬Çw£	Eêù‰öƒiòxƒ¾²›@daUşüÉ12‹Õºú€•9K&bWlOÀ+_Úk/ç™âD—’{<Èu•÷#]pÁäáæ\¢œ:·^l¸vÈ–²¿„¢¼óÎ)úÏââQt=»
Ú4µ•6T^6˜†P»;¸7&ƒÊvP÷Ÿr;²F¢¾DàîFò¨Æq‡n™ö«D&óÍœl87ºçìAgØ8–qV y¼Õ~ëç NŸ³&ÅÛÍf‚C
qù0;?ğŠ"*Ï¥œC	À+‡îÁª9¿é»Û×ŞjÓì73ñòIÏt]ØºV ÖR ùÇ"}c‚âûC{˜ÄøÃÌ¹W-ZçOC3Û.¿¬ş`S¨hˆE;^§OTŸ>†í.QVvÌØÕT<}¡ÑÓ=ºåª;”rf¼wâO¸~’›“óñÿ¯«¿’±q_È-2Û>÷Ù-Ñ¨ÊàzÄäO˜9ë&?oTÆæj[Æ7Õ –üÂ¦D«Û[«÷óiróÏ’S¦DD£S¾wàmL¤ür@e9
K·¬ZzóXå°7éüÙ¿S2ÓÀq‹5p#tr÷àŸÕ™Óƒ¿+tX©äDâ fÙKŞ³±DAÍ«é©u.v”ß×5°WIÕÑ}Æ•h!óOˆ’¦zR*ÕğvF0æuz(´3lÒydnm Ced¦U£‡ßÛ*ÉÛKàÖ¨Ğ+%î‡&nÖ•"¿G[<Í~Í\¥v_Uş®´—,ol^ùZÁZo>tá×! ÌN.uå†Swm%ÁuxÍø£ìK]ù„•ÈôÁÀÿiş„IEãÎúFÂOÉ—€¢gqï÷®éë¶ãú‹Ï‰e˜T¹8ô~Ç^ÍÀq—S‚PĞWS"_Ïí;{’ùôKÍµ_…SòŸ5Œ¤l¹PZ)¢v-pGÒ¸]Ä	³ê†E¯wĞ0¬ÒEó$G†×„3z¸SSjU6JºÙè“÷¿™ööG|²ùá‘ê{J¨è¢¤ENš¸)>/ÉKV`¼íÌ{`†³JRÚ3´ŸHƒ½¬} `Ínì+-OÚ€-ŸqyJ³úwãîyP%D&R•½Ú¿FB·/ªøÙ´:ì¥õ–T*˜.€éÒÿü¬+•©Ï´*•†ÎÍÔ€nëÖ‘î8&O å™ Ş»™•ÖÑz(¤ïä‰K0_â.ºƒê\”¦O	BûÏğ*e²›HQş8Ğw”‰ê>!¸,ÚA:ºy
¥¬LÜf»¨n2Æ'¨ƒtCKöYµmı®BDßPµIÊ,F%.Ş»ÍÇ O£:‰Q‰åSGü…ıü‰æ]ç¼f¾pİÈ>%^ê"‰®_º?ÊL·§¥s­Å”!½«bE°ÆœÏ\Ë4zw÷‘ÒmÅx<hR¥É$>°Y¢zãOV:®V˜‰ @8U×Ø­E Õt=Ãƒ8«iÌ«ƒÏß¥Î¨#Ş—àƒGÎƒTVÜÄ!£«…Ô‹¢Ö-üx.÷Ø°àÅ|&]­7tÛœ‚ÓéÖ8Ë ‚t1]@ö­17°ÇÆâÑİØ3?Ñ)këëC^q_JŞM‹NÈŸU7F»Jzƒl˜t\lÇ#CÂİÉ˜<½‡ï¼o¹ösê‘fÜ¸äÿfá-s&†ÙŞÑİ´Â‚No:8A96Ævú‰zp> ÈßŒò‘›qV_“gÃÇ¤çCdìBuÖ…lO$æ‹êÍ‚’·=ŸQ/™uX£(ª‹V!)W‡¶ã³Ä¾&y3©:†£×§ÚÚmsªoøŠi­h e @îÄò€$‰ îÙ¢kIa‰~ÈB¼]º9¶
_¦ òD+Ez9.ğk5ŠSbT†=¡–-‹¼;ÆJ<¸´èl‚ÿùÀxËã‘nçX©X7„ëÙ¸Û©¾2fé©1á³YÃ»M>óöCR)f—è'/´¯¯ìÄKQ¢Ñ(lújı¦şñmÀŠÑ¬¤¥‘1q9•½hqµ6öÄ¨F °ş}[—É˜qÆ`}ëßQ®ót´7İ‚Tf[w;'óÀ€Ö$d ]Ãä6–šûòòèoløÖğ*CC+Ùæ_èaDöåßµ’çÏ/–F©Q‰¶?/$v¨7â3ÅÑÒ±²U†R¯ÄöŠDÓ‰¼o‚/Ğ›Ç6¦1I7ĞÒ-[×	]©š6E½g‘Ëõ"«Œùá˜-lŒ"WÀ -Y8mŠ`ve”jã°ü]iuF»’ÀßïDaøK¯ÀÑ=µb|$må<ÌÄı¹bòÃS¦[úàT­:ÚkñDï¥Ì(<à¥C×¡(ï*„\ı¸(çîÒq†w‹âY,¿êw
uñmLŒ¦.±¯ÔÆ4”€µJØz‘ò·Í’êPõÔ!şy1h([ dh¥wª)6AQ?·Úì‚+Ê.eiâöBÉûş0,ı²ÂÒt»8	;&%lã‡,GoLR½)PuK÷Å±ô¨¥mÈ!1|fyØI7Òé¹u fŸy6]ûŒÚ2„½ùŞE[TĞ<ÍY“Ç6½Ü¹Øáü÷;6+›Ù"ºĞ¸p¾~d1!Ïo@‡‚1ÂLyGdÀÎ‹j
` ;ÕÃ…Sr•7gFN€ÊmJ	Øş-ìÀäJKïS9’;©;Ã¤œl°‹ê¹‡4ù­Bü èİáìQµÍy=·¬º:ÉdÕ‹DÛ½§}EŞ!$á5µo3wÌO±	Äiù)Åyğ Ûˆ$u,:{m<2%óSM›·[“oÌ5\?¾‰]/ß’äÍ~z#¿	T#ÍØÖ>É§SŸ‘œ’6=XªïÔ_¿´S g½æ¸Àê‹>oR®pÑë×](ö|ûŒ&n‚ã.ÈK°]î­àe•B†Jéü-/5IÜ,£×°·8¬AšS¬³ù_aİ"¼«Ù†íîY´B±!É’ õ7˜r§m[×’•BGşâ/Ê„Ê¨/‡4'ewçC3HOK¹æšã¿fÀaúÇÜ0ç¬ù!"Ïî—Ş>gx3ÅY!”CË&p6$u
'Ï©àB»÷#ÁÕïI>c³0ı%g4Ôä°®/J?‰0Òæ>	Ö8E¹µ%9| ìqñ³/bÅbşÉtë±Üƒ¾u@4è$|ıuAÑô9´P{mÆğË¤ª“s½Ãæp¾=ş 1[TËõA6øéÈ©+3ùİûi$‹´sÔÏ9JTÑÚ1ÍP¦<æÏ\«CÏÆâ[wiÚDg¢H%$Ay¶Ş-¤¦`kÄ”èoÉßr»âI4rÃQ6"Íí0­tòs1•›­q<-:dbØõ.mÍ«påšìiå2™°4Í}Ò·°#
w‰§ƒ›-Xã>®Ôf£—]Ê“Th:…ç–Ö…Ï›bÎÄ&l;\Z t¶*Å\m•£&x‰= ÎÑÍ>‰]_+Äl	Lç vÀ¿)S¤â¾Ç')Ss=ùšßBm~÷íÁÓcÃşñE@á¾U¥'àélşÆª[n·‚£ÓÄz½İ<îŞšz³RéHßåWdg—Q¤;
Ãø³:hdª	.Ê»ë€›êµaE¿İ6~&YH4ãË›ÕQ¹öÓkIªhûMµspÄhÏQZS7 ]–	QŒ½=\Üù'},€KB›ÿxš½M'zÎ}ØYVŒ©qÅ›ò³ÉIóú¯B_î«f¿2ß—Æì7Œ¸+†Ì«K±-½ÓÈå>As
ˆg0Œ;€õ!ÄÑV Ûµ¼±4Û´Ì@MäŸ›‰›ü®)_›$àOÏGü \y×™¼˜ÒIôX)¿±§Ì³…Êû<¬-5îe¹´ÙìLMá;5’¦”ğ‰İ'|V?´:Kf§À{¸•ÅuS\	†û¯¨ØíátúKx|R•?º´“^¯âÉœGÂ‡Dh9°-‚×›ôS½ŠüN|ª/ŸS),;QÆuÖ¿‡~?.ä¡ˆà4aËìİv3*ÇŒ9öúŸ‹8q³K·¸ƒŞE$J|Ù†ÕyÃ{EÆ“b(dXÊ¾v/óF$-"¸P^CKİ6uq£p‘±ßa­F‹Jc–u…âå6ô´³Ôg&î/ÈCt¿ÎØÀX”ƒÍìaRø!ŒL–â°8n“­ÎnØkF«.'~Ëü-ˆI*0l 5³¦á¿çG‡¦	Û‚²äÖo…6µ9GŞ¹ÀfO?KaH<_Aˆ¤uà÷öØå’Êù§l°ş9‡ê÷m”À€n˜r¢9i1­mhÿİg¥ÏDÄ<ÓÒ6›ŠEQ|Æ *y§(Ü	üî«–í’A³–†ôá/°åT|!'‰B¬+ ö|X6Â9Î?¾Ş}••,ˆ½ayËWĞYù	óx#|”ÅªsË «ÓÏúÅE0ìäavØô£€rå5—Œ•t¸œzÊ‚dU	rÄü?´™·)úß5™>7ùãYUúİš¦ëÚ±¦r¨|%ŠÎ(DĞÆPfbTİ$<oçé×ÒMëÅy>;'ú0cˆ=#$×«HBtd5ï€Ş
ÿ‹E —8jsÏ¶şnÇÚ–¿‘je0X¡"Ğ²ãYõ’¶d¦ @y*™k¯+ƒGN¼İg·/ÿâ/ *uUäİ’±È'8¬w*0–—=O† ï?ò,4Ş£Ä÷øì¼VØ†£ÜÇMÒ0tÊ(EªK»VÎ&-h*iîoø4ßÅ£È*V™Õ1Ã*mZRÒûı.F]M~©¨eRQ¸YJr1§/kvœVB=µÛ¿™Â¾ÇõC<àÅOTiÎVı|8ƒ³ƒ_»zî Ü|DuÊ“)9¬“~>ˆ»^]7Ûğc4ÂzòéÖéÅ‰@…ÃÏÜ´¾Ÿyp4¡ˆû=ÿohöÁ"À¦hHWiƒ¨;G€ûğ´8—CÌÇé;¨|gdİ5/‹D|‡”Wï}–=Œ Z•˜2„zQ¨ıN&µ™…oıÎíóvTËjÃ‚lƒ8ƒRËG£ö_÷[B·*j§±o‘‚
* ¸]¾F!K _È>÷Ñap¦Mä<ë4š·Ñö×q[>uUÿqdÉ
sÉuaZëÜ‡S×=õ:¡îÀiÚå×Ç’€i;˜Ù\¹Üã§wñùEÓ/X
Êòÿ«¨ç´ËnÄ:ğß¸ ß9@•…NV(DÔeÎÉà^¢)Õtğ¾¾²íÇiÙ¢¹4ÙN¯%ZÖñS(zM.í…Â	[Å×t‘ÆgÌÿÁÒ5”|Û:Iæ²²cÑV“ ¦üâ#éY”Ä¢E}uI‰¶+Õ£7ï'¨õ6ÃÛ_5®vå€5§¢¨Ù-l[`|«G'–}9Û™Œ¸ÛÕ{û"#ü‘ôDe1k§	h‚4–	"³§?Ù­`¨ÚÒÒÚ×îuór¿§ÊäBI¥Ø½¯K[0¬»)'ï{ÄÕã‚ü÷1X:”§ú )mù¹ŒµÒCÚ¸FB·oÂJôWˆİ|o,ßìgJ8~JƒV7ë©z
½Ğ<µdw¤È¸Y=útÛKW®h<»oÑ£µ‚ØFÈxR£P0ò¹o ’úv¥®:ğa7jFÎÀ;âU(î(,üÜiq4§Pà§§#äİ€	rsªĞlã±šú/£ŞôÉÖeEâ3©ÎÁC’Íz•Xöx
±%/p š×öe•AÛô·1Có¡Ò/JebçBèôXİòşt]t"å,S¥l!èéÎÄªğ“Ãµ'éTeD½†1-Ë‘®ØûòÚ0~]4 ~çÈGç‚ÃĞª8™Ç n²¤cp±¹\ùæGd¿4ã…Í<°€uãÃì4.aî¯âOàéÙh®›‰4ÃÌ£M•×Û2=w6ÔÑèL¤È3tk4È/‰#6‰Nÿ6Fçò§¿‡¼6®z¬Ù©²}œ%Ê5i$Ìõ9jÕzYx<PDî?¨Ïø-/ÎŞBÕÍ‘†	Å~/Äö25A${UMâğ¤…/°òßjÛĞz#2Ÿ`ôÓLÿ¯5Ù€¼ÚrŠhçuAu\v’öòå…‰EôÅ‡Àó§~S¼‘œÂÃ˜nÒ˜+°ç
‚aÈs÷³nY°×L38n¦àÒ zönùŸåAKÛšNÿçNµÍDd1`‘sËª SìZ*.Bì¶_^y÷ÜÆ1Ë0æzf!UÄ¹ç…Ú¸}B…×ÅQ–|×¦h-Şhß­/IJ#0õá‡æ€ÿÄÈoĞkpè]€C2ƒ³ae@ñ}•R|ò…Ì<Å˜4Ê8©(Êaö–ë³Ò4á³şùCœu¢{Œ
÷=ÃÓUQ‹mb2eƒnHŸu“Â»ı(ìÓ0–i$]ƒ&½‡öÊÁ¹KmÖ(c¾>@Á`.dÍÚ…Øá`ÉéîsÎÄß(qûÇ	{­ÄawæÃ8ËÌV¡KI‡¾UÏK¾vÆ×ælÍvˆ„µIt¹X+3Ğf^)$êÀŠ®¥­«/|9lO°Õ)½*ÏödÄ$›·ˆ8l.jµ%BÊ‹#²›év:
†ÃÛ qm­¤·ö˜ºşªäæ\Ì›£€M†W€øÁ¸3ğŠf tİ{Õ¿9ıX\È&ÍS3q®O¤+ ñQ/#<²š}©’iplÂõMJ¤	RˆuÌ¬ï´?L‘hÚÓ¯Xùy*0Ë:.˜*çYêm	p'í/eôìa†çO½U5Më4(æé ~îÍPs1İˆa¶sªŠ¸‘ŸqGÉ§Ëğ"ˆ6Ûe¾Uº¨IMLÓ|aD!âVÄ¹x%šyÑ¾r¨$õ%YÇf{–â’!Ÿ›w°>Õ~„”\[¦,ü©sLLE¶˜L—xÀ~ò?fI¬y°Åc?næõ‘Èí¯s’·ª‡õ ø”şâ
Â¹ÈO—ÄZ’ÚXÇŞu>ÚDÈ¼/6J’·»Óğ	nj¥À¥Ğ¿µÓKÜJÿQÎøêÑ¸¼¼Cştµ‹÷ç`úxıãE€>n¢ğ…‡ô‡„°'¨9Ä×–àÜ%ß·åXÀ Ó-îP_‘Éó´Ëo\st²×îÀˆaTÀ¯heÅO	™½ìáP „bùdÃ’`&…÷¨éL­€óú4Vd°®7¦>ÓzEëñ§bˆLÉllØñ
 p™îYÃíâÍ¨/dX„²
bŞó^5î1|­ú©[ßävH#®¹q¢È»ÜŸü}½>jë4ŒT:wRÃŸô¿»+}T|Šş¡œ9#×ùÂÔH{¾m‹¡ËüH;ûH‘ê‚9aŸGÏ å#&k+ïKŞl‡ë9F‡2E;ª¾9®¹Ş³™”1_˜‚Ğ_cA¾kÓwÿ·yhÓ\«)¯ûğc›ıÂu×bfx¦kÃ¤uÜºÆ{ fàF¨jåæÔZ›(Åàv{«B=°&€MûüÅÿkÁ{»…¬Øƒ¬IÃ“ n{Ç=I’0Ù—ªQí%û2 ş+]=•*NYgNl8ùpRH`d+§A>ıDR„—ÜŞ­&ÔœÎÅã0¨‡ös×|Ì˜lÓã0Ã@^GAë›ó®ò%°º	X1è¦­q¶XZ.¹™÷-ôÓÂ5ÈéıkÙ’5s‚jB	vÇ/9™^>şÃ±»	ÈûG|Õş-…s-“ÂG¬ô.ZVƒñß‰ûsqU²ÅhMc0N—›|¶ğX)9¾&ÔÎ ¡Ê(×­÷í×ƒv“ÊT”ä›s!’Èj7H‹f¹\Ù/Âcz[lR«r"“fêZTœ"Bâçšã¼x3c± 7Œ÷J_‡¦½±÷O5í¹\‰e%4ÈÁ$í&ÿ]2tş¹)åBÏ¥AE9
G
˜Ç	D¥Í€–¨sÚpáIR‚Z¦Bù²Ÿƒ/$X?Zw–2CO,÷ gIê-‚Wálâ_Ã«µl¯…[ãi'2«Îƒ«&E›uíµyğàLÁ^C,¾ùfÍDä' Y^ŞêüÃ·ÊÆ¦^UèïOçIå—“‹³Òœ¾£ìeò·vyh“¼1|6!¾Õ~A#LŸ¢É„D~ÊUuå¼¬®…ª/ŒüÁYCĞ¹áEòŞåà¨]^«î%ã¹ÂÅûbÕ~ŒDC|3r
“0}¨X¸Ë\ËØáÍ—çq
Œ¯(‰¦)à¹¹ïKY‚õU9:›ä§‚zl÷5ŠarRK‡A:1ªåíÖ,ñàĞa°âR·Ã÷ñ •©.\³B#Ë|‰š92&3´ä$…kÃìœeºNiÉù½¬·<bƒ÷òÜÛì^XnK…ì8vŸÒÆØŞÙÛ-öO]ª`ÀøÀî©9?8Q~|i\qe×Å‹²4:0};¿÷5buD\lyÎ9¸{0Y†.KáÕ´­»Ğ\­øÜş-;ÈÑwõ÷Á#¼:q/ÀGëâsE°³&˜§:é14ZµS‚¿AÚªZ`Y[/æ4«%‚À0/ëz°İƒÔøcí€)Z4½±ß“ó.mş’}æYï„$A‰3‡×*¨Ù…ãØï…kúÅÍëßú5Z29ÀÉ?55nòÒ¨cş†ºå[Z›ä†Œÿö•¿Œ'K|ªFãNé¾-^ˆñæ²o;$w÷õ¾èÇĞ*‹´%‘öo&oiBh2¶€axñ«ïï‹Çü’×œj7"3r³úÁBĞ×w…år?GN.9	c%€ìD`šÁ ®˜s›’ÒÂ‚”ø»œ#ÌÓ$'æ[„½_½^¿ÑGàH6­œ÷ïNõ¢àÁl1ºDm„¨/ğfÃò^„j[ -vˆÉ›-ÿró¾r¨ÏÀdÛ8Œ`åƒáÈU‹Æç\æı¤{@‚*Š¸TåìWè„fÄAüÔ
Ğ˜ğ<lË§[uî²ï’4üğg›ˆ¢4^®Ò®ìFû´a­ş:˜‘Ù™È³×fÖ”Z8 ªO¥ó^oŸOx¤ßƒùôÖ;5™%}LŠ~3¬˜ZÒ¾Ÿ"€>{l}]nøeSÀN|#SºıKğBœ£qè³Á@yDD»ğnÜŠßŠ#jq®Ö<.9SŠ.2$sÈÛ¼¶I•¶§¸ØêœÍ?¶K„·Õ½ †õK2ö#³Nq×b;¯uÇ˜‚¶şæıÅæ^®M,Ãêa—² ¼ºE>ïTPï	&O±E:¤±Ó,³O°uvsØÆÓGÓ“œşÔl"Íl7¬Õ*ÚŞT5[>…SØp¢h£Á¥»¡¬’[V]S½Ò-ÛÙæÕ&¾2jëš'¬:È1(’0(Ù%ì‹°×¡ßfót}@ø‡æ—BVŸm¨#¡4ÆZ±3Éá¸d<ÇyKíô‹-ç H5 hø‹‹]xÓ-¼‚)æ“±:DPÛÑ³çõÁ Ûá‰‚JlâóàwæÅ™)ÎÅ]#ÊıÖ†×ƒôEĞ5ZØ×>nˆòûcÓ$VSI…4e,.ùù¹y€ìhí»¹¾ßw]°=›™Éò^S÷{±6rp«Øzé‡ ©åÇ=‡"ğ]=+ÖPÉş- .Å Zí40Jå˜Î¯ÂÎ×IıTÎxÏ‹2o‘©a‘[Zí—²şÜ¨šíQá»&UàºHû
ŞnuNIRBúÑÒÔı€v­Ú²ô+ï*â¥âêÁ`ÓY§{°‘b‡…Å‘–qşrç›ŒT*h˜xt¬n†E¾á×y»wÛ7’ƒã¦h¤`«‹”©ÉËCr“"üÓ*‹O2!“øº¨£Ÿ·Šë†×DKİDbgŠ!ª¸~“31
“YÀ'XNÀbÓ>š ÓN¾`í#ì	âŠ\Ú¬£š•”«n3ë#\h†Ö{°g—ÁKl—ôµÆ¸DtµÅR²L¢ôøÚ^ädöpéÂ9œ¡ÅB§Ï[ø"øCƒw“ÃáH§UğQºüUP=/Âo(`‡)4 <ÚÙ5ôşi×C¥´MÖ=Ş0‹¬ñ(y¼˜81›”OŠÚòÂCìˆ<,4ığà´RÔÉ´g±—ü_-A¨VºW†&`ß'ñ>€Ø.Mfá€NJÖÙ5„hüÛ	%­ac ÷vÎÁaÜÜ‘;ùA~Y;Í÷mâí¦•Ì…‚‡L†‰Ï¤µt˜"¤¨M¥¯;¾Pñ[Û<G{—iä__>Ræ"º=³Ê`‰UÕ´Ù)Ê$‚_—ÜcMî‚y¶n½·HÕ8é¦­Ò ª¢Ú½â¸±¸øMVàŠw|;*[óÚó#Ææ¨¸à¸eš\Şhé6‰˜Äƒ¶å“XÎ£L-<OeB(&§˜›ß1zbBènÂ7’„q8¢–6û2*¼L§õ=T=Ìİuãü‡sÏ÷˜}Ì³é;Øşd\NÇb1°²õV´wi¬e=™<úÕ\e¯À4âQï2bÜ©ÑVQ	uÊX Émª…––6w¼Q1?0 ±8ÂÆ¢ `°b/aè}Vkõ¡áŸ?®d_• ª¡·NmO9”ã!’#p)ç÷x‡Õ
˜ôõáÌU^TÁÊ8?$›„JfôçC6ŞÉ»¶ˆ˜‡¡Å8‡Ÿƒ™–±ÂX½z¼,¼±î+ŠÙÕd†ù/[ pbZ4²»†tÍ½ ÁÙÑr))ö]èÏÃüøŞ¶İ•´’ÙÙ~Åøıî¨¸·KO*Púƒğ¥´Ha7%Ñó¼‚q(µ¦äO­,İóÉ/XÛ®µ8-©:æ×†ë¨úŒÆ7Ûk{[¦9;ë£?t@ÓÜbä´ïW™êTü”1);ìtA\å¡s±¢;wGªV0B$x¦ÈÓ))÷_vªiøâ®cĞ†ßºûÎÔ#tJ.Ô#ŸÒ81tI%_ªÕl 
.°@Pf[¬\È6Ï‚üËCøõƒv3]A‹;ñ*:+·}ÊËáMBÛì-ÔhîÄÈƒw¼Š?x¨3&£?nªcÖ¾ÚÂ«ÖÒø8”±iËŞÄn#ˆ’ØÚNFë·x:ó›2ûÆ"“™î>Šœ"¥ıôİ#Ö’á‹Jn²)¦ƒÀ+KîÊs)I©`°wqÃ^ºy;$‹Ù[‡±A8/Üû¶‰à%Æ®‹¼v£À•'+ğîƒJ}™£ªH@!Ké}@B:—ˆÌ\EaLs®Êƒ“6ZÃ1xûß¨Ã«ÛÖNª{€Q¥9b:qvüúÒ-±º}p'løLĞ‘D8ÿV'W³O­ËBj*©Šµ#YÎ3…ÙÂfîûQ}Êb™£àY_Ñ¤¹tˆã´Èˆb|\Dä„_‘ük3ë/ío…3ªiz–¿e
¼·Æ7†”q¯á¤`Å¾³ŞMŠÔ 1ûÁPB ‘+IY¾ºÅ%ó>ûÉ¤ù¥]¤Bı¦n
iÔ×çã"er˜1’Ö¿…ZzFšÙ5ÍRåş±ãæõ?AËKü83Ô]­²{²7Í|}-ç¯õî*Ï˜òFŒôu;˜{æàœ „.T`8¹òÒŸ¡³¶9Ìö£MQ3.ÈyOÔgaàgÕ»Ì/ø{ÜîîõÙsœmN¹«f¯ÿªÔÄ+d¯¨4´_‘M+€pF+c©¼@(%'…]D!Åâ„çå>hÿÉ)PÖş2ßsÃr@ÌÜÒUéòsMé²ø,Á †WçxÔR,(ÄdAë–' MhĞ–$Â†#¯&Ğë 4zä,1B¶©Ÿ8ùÌás„ùdk«‘äÁU!e°ï¤ƒ¬©1ÀlÖEÊC¬K•	(QÚùIUJ1Ş4·ÑİMm@UFíà‰œ4FšÙÕW»á(7Ñ£‡G>³–3ökÊÄ¥îihOn±åt­MQİ‘ØŸì±Ç¥3º­™ë+ª]Fè¢€kÁ…­}Q™¦¦ ]˜xÆE½!]£÷^k7M	úL… ¥Xéş±k‡ïbêĞÍT¯<·›¨ªLÔ‹PÀ¬páüòÉ±&ĞhExcõõL¤ªØé]°ˆe$JpÉˆ\q<¸'[¾mDTx×=¹ª_&wº‰Õ¹PêÏøHÕKÕoî!(Ûï/o1ÙÀE²ˆù”>ÃM>zÔ×£]Ş!¡ŸÍ÷jø=] I
q•©ò~)åAÃu$ãÕ¿Êìy¨Ò4İá6¦iÑN“ÇøRşùlã¢Ÿ…é¯Ç_mšõ,BÉ
3´ÜD°
]s'Ò¿œ‡‚6RÆÿ´%ºÄÇ !½YOÓŸ- %N×5!ÈIç“ÔÙQêÊ„I2‰±%°–É²hçYZ©õl¥.©föÉƒCîqm\4üÙ«Æ#[qC¦hİü½ÍSŒ_üˆ}RğÌ?³œ‡ıè0Î“Q!G9Ä’Ó1Eº³ş‡u”D´íúØĞ9¤vˆÊ¡æŠ@P¹iVZ³¹sÒûü? @Ùmğç×ewGa^w³‘NoÛDP’“9É#èÒ!Îßj\«cæTY=V¡‡ê‚£aSÖÎ€»o™·
ƒƒ€™‰Kî€ûeR¹ûFİı3 nÆ™'T˜-”¡T\×“8Díˆ*ÑÜ½ÉÙ>ÙX¦œ§Í©x¾<ÕdÁ	«:ñ×¬Íî´šœ‚6z„Z‹ì>¿7pO.Ùvšî¼aí+;ÙT%ö†ú]Äì]]ÊÚÕà~«Ğ‰¯ço @“±Óœ¦íKõŞ1"²Ò,ŞN»”^Å§Ï—½æ
aÀ¼e¹Jm¨n,=Oˆ´|X`Uµ-`ıC:½Ö^	á;0uWšô´0Æ3>÷±Å êÄ%$®ÂgBëøt;¢Èf{/”®kğ+#Â–|Õm)Z8TQ®Ì Ù¸âO?Á¤¯"ÌqÈ0æ3şEDàÀüÄPbÃHòDqí†2¡PöM^rìvqú©«ÎrÕ`ûd6¦óÚ¬‘ôî]Ñ‘»ÄP€?õ/@]àÃõŒ€ZÀ@ªÖëğ„—dyzéìÿØ£'eÂ†^ŸØ	&Ôi?›@\X.;ƒ‹f5.2ág;€wS®†ê/¡ªù=’V{^ÿ6íEëôÿ`/ÒØ™#Ofá7õÓHnNt²|ÍéF-_şv6èŒ:õ±É¯BbŞÑÆ]t7.à‹=Aç½5õaš”ßO÷©©î 8NW¶”@Íƒ$n­à‰*G¦^˜zW»Hœ&±Àœ™=Jï×Oš-’’WÀ(|ùà¦RëÂ‘¹ÃZÄ5L &Ü<z’ƒ+¹Uœ¤b9Kgœm˜P(PÛBã9“)Q«à,5¡în‚QèµNğ‘ı‹æ_[ùr¥¢@Ë#ÚQ±@\KC4Gœ}·âÌ‚õçmC³&¥CñEñŸË…r"Å!ö5‚ç‰¥UïµJ>µ-^¹¾DcçŒú•ÊÊ`qL§é“–jMÅñ(Û°5cíÊ.‹K#2l´LüùÍGÏÎºk£WxXNŸ¶Ç)9JÎòÚÁ€VİİöAÑhL³ ŸÏO‡¡9„nxG·‹Á”„Sğä˜:ÂßšË³Õ© ,`ãPYÁæìècK>´Áa·˜)ş©ããƒ¿ª…;wß¥&—j¥ÜAÑÀbç­É¹òÆ¿|ÁÂ|àI	¨@©×AC8l=ÂÅ`zHå©óJº’­:M»ùÙòO‹şk|4hÚ?€_d\y»Ÿ)CŞ¸0^ƒÌGnÊ‚ê}Ì‡Âı”‘]"Ä5MšÇ9ğxä “Ø”É\rƒ+}Û¿¤>İÀ¸ğ——™w·U‰³<`vÃ?XO|ÉajGªQñ³ÛPTyÇÍ† ³K­=ïêUù~E¡ñ?;BªK™—J.ù9#>ÕOƒÖKúæúáç~™Æ¼Ù´É­¶„ ¦QAşÚœöP÷!êG’SÈ‰ğR@¨¹’ß¿|µ
BTøkíGúÖ²Ä—äßBr¦F˜ı×VÕ“vİ«-«S‹ØP-bàP—ÛZ‰Ê’É#…/»x%ª|ù
¬„eä…¶3oÀ6à'lN§’µ&Él“…7§´a`>ÁğNÛØ¢ãüŸ¦ v0„+>N€Àèşšb8bŒíØƒ Å‰æ›"6"îªàˆc(ËkäøĞ[M^R51²¹@"ñâ x¼­¬ œõ»ëàöï­rz œ¢ßG«Öf‹LD%³dG96*Î×›b]p™Ô!Z<˜4¥êşåTÆÀ…ıØN5‡ıínİHa¢ØSÓ“¦İGš´Ïá/u¨Ç$«Wö¨l{Pèá¬æie»ÄRŸF¢r5îp#]ËÙÿ¬©.Aå¬¹et’_A9iİL÷Ò–.2yhŞ¡Şümñ»1ë×Z°‡OëõÕà
’ÃY‘˜ß(VQ4Øe4Œäv¦ô×]Ñ‹0FQjS¹Ü¯á!)ñ¼àHá¨FT|Ìùÿ©.­cš='îOÓ¶¿<û&’¤ÊrÒ‘:f|)Ø>d\çáğZXáàú»PÎZi‚…oÓiêà¼µus?®bƒ»âw©¥ò^b:h„‰çN'YkÿOúh«²Oúñ~¶[LÓ>äRš.°ÛÈ²^
;BOÃ.¤o˜ç¦‹Æ03Ñ¢æFAï¬|o1`ö2¡¨’1ã"»O©cH!eç›@„³…V*œRÖ‡º£I2İ«, åg9ğP{×L¦«tæi«ÕnÄ«b– c,:YÉTFyô®"ÜŸ·êÚÈş#ˆ^}Káßš‰Û,TŸ;4—Ïcè“<ÿĞaº‰!ÜªAeÅàVoÓ&ál$FÅŠ¾ÿN0Qe	±sÉˆ^Y•¢ØLŞ­¦JóŸç…ŒjXS¹CæpâM1¶û¹*Œ¼&ŸêB²J8Å<¬äıÌ J XƒYÒ(Å;s£uÌâ¬ï3|oÏèæÁ Ã:#²< ¤HàÌ,	g€q¸!àºù¶;ÎæØÈ§~Iuò§UÜ¸‡B²­êó´PnóëA¾¾ú,´Z|Ì~Û^Ğ¥­Q“•PÃÎz†U 2*Öw®f±ğ:§º»ÃØì•|A•OYÖ‡,qˆæ™ã:Vkâáü²7*‚'ÖÓFÇmM”8Ğ ®/ó>­˜õí¯ ş5úëôôÈ›Ç)üĞNûKğŞ/·®¾‰Xõ£‹«¨,áMV=KâÉ¦‘!ùoëÒÖö·ò‰ñg©i6ÿ]ÁÄ ìór+²oªáhƒ Ùú%%›qy=QÖ0e‚§]´ Gg'B!*şŒ}Ñ/q—“ü2/(s-ù|<âWjëÜÍ,CÌ´m-ï+Ãé¡ü'¹Y°á{ƒ|)‘şLiˆƒÍ0ÆÙ[Ëê.BRü‚™ê@ ªç)¼êÆ†t}IÔ’BnŸ¼³¤u=Ôˆ…â/kYk2 œ^eƒy]ƒQ£y2R%sÆCË8|Ğ‚Éuv=‹’ˆ˜SáLA4Ùş#Ê¸"Û*eÀ8­cQ‘Ôü7´ôL±6”PmÊ»Ò°ªáB¯dVï»"Âãá©ğ¢	+Ğ¬6Ã4!ìfU¼vCƒ¯­§«ÒÄéHKùË‡Y³vÙøøÚÿ24³iJŞ¾… ‘Ò/l$’ç—Z»ĞIê¦<4¨NöSEzZYÀl¤¼dqÔC¼ëÎše2¢nMùW¨¼K‘vp0ø8’/éÖ	ø{Ñ )ª¤÷h×õkqsU lí(ñ/,êsÑø·tö/†ªÓßÌ0ÏÌÎyö© <Ğš¦=kh	kS®à0¯L&SÛaLî;Õu0¹¡G¿äîDp5C ïV™pV§sˆ‹Ã¸·Ô…ı:°ÿ”ì%'›Yë?d"mI±7µjß­×Q"C<¿ÊxÛÀ:õX*şÃF(õXj:Æƒ8°98ˆ·>ñPâAÄL2·P7I´`ÓÏv¹Üó
Ç3ö3ç£ù26CeTéÛâW-ïçr lã‹€µŸğ êX96$'€FGİ+qS ŒaÚ44Ëßm9ûÅ@ {ÂI×¡£é.*º“30f$ƒ¾èÃù®3&“Àl¬Uj•\Ö`ğ©?LooöôbTüÆÄ¯øN¯›>L´ŞóPF¬‰ˆ;ÿ^'ŞC„„l’K|Ä}k»jæK†¥3— noŠEš‡Za+â¨/ØYMGÕƒ‡™äI§é‚»ØIMø²w³¶çT÷ér&Ú1‚Ù|–şì#”:Ëâ6h ;äd
‡Ê²£PÌØ´ˆXv”­ºÖM 5eY›‰1}!Jº˜@ ä½åYˆŠ3’ªaäàY¼øÿF¼¾`¾»wL”A¿&ltî$JQßÓy?ø"ÃM ³¿R’€Uã}ıØí{ğ#²™Îÿ­}MûH‹+ÆÈñº Û÷{`+¢³ éDå·È2åÄËO‘‘REç…ïØ‡,‡•,T*¥<êOlÅlñ:­NçOÖ4’£¸¼¡b ò4íDrâlÙd;aÙ}( Œ2dºåõ‘q
Oé‡_3ëĞ†¿ZÄeÛc|¤k	`‡VÜQƒ~sãH@×,ôFŸ]› ^hò
Å}ŸÂAª¡[Ì?Õf4ş’Ã¢L¼#>ß'WWŞ™iääÆÆÅZÁE”pƒ¤jj"Ş±ñ î««“%*>î)æÛA¿‰æi¬À—†»Šq¬ÊÍ½/jto?
s²—>³V¢ÒæOOBµÚÅÕğ>ôíİ¢Şëu¨ÁÄPv‘N°pn	PÜ0]ÆUĞJ±“ü(ò¬±‡¨½¢U+ã=Š	4&eÏ Qy~w2+K¶C#=]Iš.îáq–?
·)SjkŞPq.]9Ÿë¥‡Æ9[;(µQ™ù±‰îŸÌOætâ«–×çøH¸Ã,ÉÒu‰zRÃòØ3e{ÜÖÇıœŠ,÷_`Ş[àckvJ­Ç«ÛŞüÌŸİhJ&Ş—5{ìc2ÆÑ‰,møA(ÙrÔÓCB2D²²s§û…(Ú¾‘Rt<N_6j{7Şpµé[Ôú¼âaúFâöcæ’Î¯v$H‚›–@)ˆ?_xå9óËj,–'ïÙ
ç˜]ïı~41(ƒ‚ÆE»©¤Ø[	t4[¬îÓVîš!©!*”Å• –ÆzÓbI+áyß
BĞyy¿a#V¶Cdª&Åk„}¥ˆáª“TÈ#×&-°‹i,ÿº´—¤ãüqşE‘£QÌ·¨IlšÓzÓ?tê¡S®€H“wì¢„T‚¥US&—7øe=hgba¥—†Vf™l*³×AãÅÔ,Jy°V]~_“#66`b™„Õ±ïq	pb)5ZKŸEê™i8>&¶Ù»™Zî™N€ö¥U½Ê_¤—.Pæ±zcá(ôË„6úg¹œ ~˜å]™­¢¨"ÎsÎ¼8;*·­5rsÈb(ı:1^!Ëç ×>ø6ò÷½·ıR M€®:İ¿o¬fçVIt‘Jóº<ğK6“>ÿ4Û¾C±y^ÉQy5è§†ÛB˜ä4z3ı)ç]›^U€¥üVñ+±8qªÃ&°ÈóCöKßÓOn—„ı‹L1è0éó9&Rã0^¤”°wšş‘Ğ¥õF;‰Ôˆs‡Ï¬`¶®ªIcQ*îA%:Ó†¿$„2s÷«hß‡³_‹û~¤g'üùºl?%J¤s[5ô]ıj=šrBà%pyŸ”S¡ß‡İˆÎ#×Áæ¤íD\E)¦òÁWì‰<…§½„Q}2@[J€"SåñcŒ©]›{q=E·ÌDšÙ§(š,$)ÄNáÛ£s ¸I4¥cµ»ŸÑ—;_S	™vF¹!¹¾Êcÿc4ü•èN¸g~VõîjÿMâƒ€]™åm%jĞ‘£'§Ğ©Ìß ;õ­3¨tğ¢[AĞ%Ë;[Ó‰x™ÈC(QÁi¿‚mÊõ|R½o÷+ÈŠ¡t±ôË´pí‚G¯ÍÎ±Ö2DJ4‡ø mÿà¶†°ë¸^éƒ‰¥Q®+šnœ´2Ó+ÉòÙÇ¾°z-£êÎÇ&î|'$
% *üÎÙFƒ.Å„Ÿ
3±ÇlµH:LG7›"k0Áîó
:>Ã–¤:u5ø);yÆÃ^¦âÄ*Gm•Ö 0ÿj;†{g™5IgÚäÂ¢Û‹¾¡H–_×FÔQ“è²:œw><æ±›6«˜xn9İ($5qŸ¼#vLoÍ†÷FbVŸíA‹?æV9h”(û¿ÄĞİE’/î!6™8A>¡à™B¼àÏ[H8	 Ùú;Ÿ¬µhö"7(Ù¬ìøë`Èñr+iºÁ¶5¾—qS#gT|é–eˆmıAp€mIéA§•vIæm@`Êª<´aeKR­è‰æ›D°ö9†·Ë¨!:©ašv_¢/¤¦$ÿáRÀúÒÄc¸£´%8xîİ æzòˆĞ¡[~Yİc|%]ûµìİ\8Å-}Óz)şx‘9áfcÂ‘”€µNG¾úcí.‹‹üçÈôµÊ¬íH˜ø¯MòÜÂ;ayz?°ò„J<‰¯ÏãÉ’ ¶¢PÇ«6mimÒbGö\¿øïÚÂ^rJ!bıVåÚ¯µ
ü}R¹ÛĞw\Ö"&ÃY‡M”¡! d\æ9	ÀX;%É¼ÒE"“µ$1E!x£l¨»F1U7@ïF‹İÌBÎ«<HT~é»Ê pò…wê>Ô4?ËÀ}e+Ù.3Ñ¡Ho#;HğÜ´…¥ÖQ¤ kÈYÛŒp¢	¨
Óe“V¦r’ b‡mv/œ`šEAŸ_ä…LMºÏòâ3¥JÒ§ÁGµBeæ×9šƒ¶uÏ.ğmbéu¸e•¬¿{^øUæÄ,ŒàÈQnGİòÏxa}Æ­¨_Ìƒ$.£¤³0v<ÈŞã€ 	ªvıĞ‚ç§å]Yè©õHôÇ*ÑP©Ë2õÔ.Æ=Ù%Z)T¿Q1Ij…¹Ç"Ù£ãiD5>€ï¡'ÛDG¦ˆŸ§Î¬Z<8B³¾*¡5ÕºYfÀÒİ¦° »n“Ûp’3èh®¡‡º‚SWâÇ®níÆX×xÊˆÜĞ`­ÌøUir“ïPº{ûÒXÇY*ˆÏı@Ío'±k$PB!Îó›4Ù4'p!¸‹³fí…½q%.ú{Â& ºWö.Í—Rå|B±‰Ú¼²–P¡Ïô”5JŒ¯yó_=¡˜C9®\5ü§ƒ£Îq¸´æ m%xßÑÚÓ…-mŸğæ»USªõ¼Äó&|S ç$‡ ËWÈF¢­-pŸ$DÌ†^Å].¢à³B¾±¤ˆyM»­GdåúsòÈ
İ×¬8½ô:’³’†–f½™X°ŒgËHş£Ô~ıS	¹ñë™ñº–šşÆ?;úaV:œó_C€ÏÅÏ¾]À“VeĞ<÷…Eræˆ|ˆ¦TB@‡&ĞÈĞÔ6o·‰Öı¿]°Õ3Px€BÌıE$ŒÜDJå#¥CuğØ{h?Dœ”8Åiç\¤¸+êØ9'&Q*íámBšêjŸß.‹¥¢®øF°ÆoŸ[¶»Z+íş‹ÍT%ÃœÒìætüĞ4?ğ¤…--,%ƒøo“èW•Ë'ynÑàôJ‘äa=‚ V›´ù¹Ìc"uÔÊÈ!·ñÚuMI'ÙYßt´NäŸE´À<’¯÷™ëc›mÇÄHĞ> Y	]È²ËĞïûÇrâÒËB‹úÆ–æ}SOâ~ÈÄVk©¾	gD5€ŠˆŸ»¢hX\6÷{qŒ6S²j©­Ó–PšzzöOÛ´¥$m¬Ä¸ÆNmÁñk¦êÚGÜÅ¾2êÉÈ’:gDƒ¨î¿VĞƒ°¯^±ù}_ù	qö™],¦G¹TæIí`‰Jğ<~Q·¸lgf× ¸ğÈGÉ¶ÑL÷\¥cJwkÄGiHÀ3™Y×"¬Àcİ?Ï$š*²İí©–;šgy‹[io"Ñe‡vw†à^¼oÛR¶%uëädé Õ;ÊªÏZğ—!	Vïì jú-½Xù¯ı¬ÏÉŞPÂhØDñ˜½¡´N€&Z-/gÛC(¯Rs ÍÎÔz¡x—Ú¶¶ºrÔ.?vmûdœ¸-z½¥¿v‘É##~zÖt:k#¬aE¢µ12ôe’æ0Š±lcÜ÷5oSÿñp[¯,0¹ÓjÉñ˜Ó­µû’hY†¤ÏQÒÕŠ5ÜÀ}„í‚^Ø ,]˜W	ÒLê}nHtdQí:]i[o¥+^aÇ­Øà’òPñR¤Ôã±Æa²~b0¯ÃL(ÄÃ_ttãe†•¿Şª”OS,9ÃÔ¸3V€ğí)P¢İçd©øŸ-Šõ:÷	Iš ÿˆß‡êÉS–ÌÖJ«öUëılF‡‰VT¡³Ë&mº˜>Œšr¢âÖVë†•ÖóÆ5LëÔ,Ï+>Øs„úŞpW·Xƒ„¨  s?ûÂõF Ÿ¦€ğ"Tt±Ägû    YZ