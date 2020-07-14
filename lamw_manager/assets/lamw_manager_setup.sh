#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="898111386"
MD5="538bc472d3c711e3173098998b460120"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21292"
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
	echo Date of packaging: Tue Jul 14 17:41:47 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿRì] ¼}•ÀJFœÄÿ.»á_jçÊ7¢,–NÃ5PÍÊÏåSµÄıù/E|ÙÑò™°ÂÄ OË½uS‚øÚn–,#Sñ§¬Äßnm©ö^ƒç81³-©3®e]´j¸8t3÷¿ûuŠs˜y
Iío^¶:UêW6
w€¿#¢s­^¯ŠİHRf‹áĞèç0"J±S'(ûï÷×’éÏ9éÖ
 bÈÇ77|Z¨*hi{dÙ¹û1z¡ûÕ{~çU( 5_o|/÷ºØT	Ê ¿Ô×Ä!SœĞIö’óX;`îÎŸ?= Á{0
˜¶şX¿ œ6zi¹çÌ8B4‘;ĞÅ&†¿™"VÕ_MQ·İhÌ´úg¯$…›Ì´f‚OˆÄUg†€%³X²©Öñ«&¾üzËÊIGtâA­T›Íì#éoÑÀû-}»²JÉÂá:/¾ƒ>ÇY`%æ¢]²¥œ*á£Mß‚!ñyìHş]ÉŒÌ¹…éIbOÈP;(ûã§2íÙ1vÃî5Cw`z
º·i‘ĞOÍ÷~²m;*ğíTñ0“Î×ŠşÆµ9ç‘æ»T7ãÒ£‘_¦	¡xy²L¬¶2%HìeÌl<EøˆrÂ]û
pß™@Æ¼eó)ê&ÿKe^è,G7#šh5H­4ÖBhŒ!GíEDFos“q2^šøÛs“œ6zÓ¨¿DxGE…Jp'”5#q©RÔşr=Z¶¢,½"ƒÉ¤€E!%Ïí—@—İè‘\{7ø”¥å‡²ÙùvD-#nıcèïï-ĞÍ7ù«© ú7ôïº”ƒz$æîäXUp!„P½×D_s‘Àgc[=°aé™ óaàª2†ês´4}ı/5ã%Ãe<Ô‰Yv]ÔoÖlDHq²w}ÇOï~‡Ç¥È/›9À› cN4Ë®ó½h
QøXÃÁúwÕoËÅ6ˆ*İZè§/X¶q3–¤ ÀmûÇin@cSG	
D÷A ¸#¬·ë€”´³b^“İÔ
™‘úÄ3óö˜Ù'çÿÔ”¤¸L¹?ú3²¸~¶„¨R;1…ì’0†k1CËmêó1ÛàxÍ]´u§ˆ«HğZAF b	³G1vÊMÅ¼Ä>Ó„°ÌB‡#WÎR0¶Jˆìa…ï8‰Ëgr¡(¹ÏÓƒ˜NÛÄÁ‘G;Çû%€1c‰»ÊUÿêÒ=÷é?‚üDÁFz5ŒÃş²û—:Â¾»‡Ü8û|©«Óáu9(Ôº#‡åmLúEÊù7Ò¦ÔYZ(¥¼é[áÅ¯Á×/Ó·Iú¯¬wbO&n {XîqÙ‡çËì9È`î$´ğÿ³a†Æ°SÑ=ÿüô“GÅ—trÜ^Ÿ{iÁÖ1•ïûàº5õ°MŒ(è‰u…(	L¶”O4ü‹0[ú|&(Q»âÇp¡RZ#.æ„–{®cFV‘×ò+¹qï‰±"²B02`ÕŒº	wÒì;âĞıç¼x‚Ø–â%=“Œ½òÒmVwïı¼©w*Ä‡hĞ„¼µ¥½C]¬+ø;5­v4ö¼ÀÒó»¹‰`G(åvĞ CšƒQ¿Ø µvİ¢Í««=öªÊgÚ¨ó×5mItüG;G8<W°$ê(™İ˜×\.*ê†)øMSdÍ{ú"Åm&yäõpQæ(CIèlÓQ§wO¢ín´€çã‹ºz4ÛšN@JW(½j7ë?˜­­xa¿kİfLÎQ°8üy æ]§Ş”š*ÅÉâój! V qí|yzbO–ASÏm/´i6ÀUIÀØú¹Ş¨ ˜©O=Ñ+À0ÿ.sÑDGe|X@ß1‡ıÓÇaàëiì’öÁå°ê–m}]ıÂb§Jez%jÒ#œ‡9O®©S j„^‚ëğ:»€cÁ=#Í¡pÑK!]÷º¨¶ÁRœıÂm©ù¥'Ñ‰õsƒÙõíí¶Uzd£Ôr³éìµ9@EŒ}Ôd¿B³ä÷OÚØpØ±R<7p—eíz—k[õJG`¯Ü&JÍ€©8¶VHqâB9M}UğUM
EPëX£ù^?·÷C¥ƒœMˆ¥³N“Ú:ƒãÇ¿ê­íK&H‘câ6´u\ùsÖ~‘ìŞÓè-n 4Ú;,ó+Ó%hè(ŸHÅDÿ6i7VU.f*&›Ú	¢ƒTNeá„÷ÍW-*BŸj?'­5€F£w8C;ËšÂ¿AOá‚möÏ„Ò]¤Ú‡¢Oş0Ô`ÿ÷¤øå®õ„´T#™Â˜^gÿ ]M·¡NP™òOÁx/,Qló†kq(C¹¡¡bé´ €nĞÏQO©ó<éi xPø¬Hã‘gˆ0ÀàPI¼ôõZœ¿&ß¬5d¿ûòëÜ3,Íş(V]ğ sYPÜ8ü‚ì³Å|VeuW²aá–>.˜•Ly§F'ÿ`É´¸g‰+ÈI4ùLƒ†t‹Ù†¤şU=áôè2 ëQƒ—0Ò¢+‘Vá¶Ô‘nèTº5BÂJxy:>xé§“BëX`M êĞÆÇÅSù•{ğ¿hôñ<á›-ÏO©ùïŞn’¦ĞiÕm²¬/ÈI|×êYµÏÄr»›qŞ»K›ººâ!4ıš÷ğĞÅ‚£\şÑç"ƒ¡Ğ¶	¶£J(	òGŸˆºÀ"6ÿAI­[]œ¯ôbe}/:³¢¹mrì‚68XÅ+œ×ËºFÌèça÷##"³İEÿ÷~>¹z½ìO¬³]©xÆLq)¬åù»¾["±´\6²×¶|ÿ$õxƒA(XÊUòÄ,2±‹ÊOœÔı³Ô±Şi·§tQûñûûf=še"!õDÏmöõ´À= ]³)ÊN{GsŸ_p b"6©•ğÇˆypd ß¦e
¦°÷]nGn¡Ìxù¾÷a?vşÀÿj5'!sï;ªuì²”!âtğ@@´a0è¨âeâØ@Ğƒ-;*aÈ%‚ë; ¿N.ŞÀ?X{ˆt×ÇÇ­-uŸ¢½ry÷½ƒŒá#e¢EòMÆ®¡o)q‹",R ‡ä»<õ¼5>¦ù0i{i®*ĞŸÄA.ú\W”f¶”WÃHÀ‹O‘R³)Çó$¾åìõÆ—Œ¥ GŠ¡{CaæKŸAÊk"$Òœè÷õ"û´‚p™ÌxàœøQ<o×¿ë]ÉQéÈPbØoª¨h›j¼ÃèÓ^L@Í’jÉ	·XË—ìêihÓ pQ*BMò‰_Qs)V±Ê§Î•Y›ÕT6óïyu÷AÁÁëèƒ¸™¨Ëı(Ø”àEN_àHÔ/NïPâZÅRúşN‡Xó¯ßÓÒPúBƒQ¨'Yª~$
Ø>ÔÎ¾à<=ì¤¡3|Ä3çm²/JaÂcèz&†|%MÅdÙ”ÆLÈ~äYeÆuqU÷¢ª¹D£ézj>4wåVÕdcİÿ³M,0|t‚Lü¸KXÊ×¥<ªÉ¼)<ûÕoşßıàfAB±_Ü‘ú!¿´8¼{Äü©ƒ¼¤.w=ñò¡g˜›Q¤ò7XS¿Õï¶œb¦Í½OĞÆ¶ÁË?bòl]ÈpÜüïóuƒÉtş
&õoÍØ	:Š\îlêŠôj%,øóDˆí9TÕe­8(r'/êtºĞ–Ğ¹PF GÅÄîT7ÒVœ´–ñ­\IÉZ fAßÏ±•z¾²õHS3y½kÛQME·¡‚ø¯ĞyÉ‡ö3V¼‘I¥uŠ|…í]U).³AŞ¾,üöÆx¥pÓ¢^qOöÚ°³£©¸K—7˜ë¼¡R‚Â¥N·~
Şşÿ®5ÿ¥:7¿(ü•ÖùÈ¹¹f¸ë¦@vY¢s¨ÍÄ "I§â7¤âìkQºSŠIˆ‰ú×»ëë9œûmÎRÓ’Ø“Æ	ÈK¸q ÀAhËì†Í®tÜ;‰gål•m¡Ãü>¾]xÜæ‡ò¹r$ÕUzªÁ3=ñ–«æb:uzö±ÛÃ¼ZM/İ¯ÛĞ3Bj;ŸÖ²}SŒXÈ99à (MşDº%JLç‚(D!x¢Œ>¾•øHôŸºš¤UPM~&Ü¦˜A½Ñ6cÜ×§rmneÒüí6Gó>ù3èÿ)dÏªn²Ù>ãrTÁ°Ä!dªR-Y4d R†RCºü—›œY÷¹¾â»ò¤æòMqF5;×g “[•4x†‡jê¿øöµëfñ‰\A‚†>aÙ<óñïäJLlæŸ”›d°ïEÚâª‰º¶‰Çéÿøÿİ½IŞNVÀ	¯9ıdEØ¥&ømŠÔ'd8-‡é+lïô)æg÷êŒ4w<Št8TÌ­nšüûÑ“†¬
Ş•¸•òê§MÔWTc<üÕš<YÂè#
á‰5#¹\V¡„£Ye@%:Y`1ÉNW¦8‘ÔfÌ€ã4Ü6C… k/iñ¢ZºÏ×	ó¾JÖÂ‹ya;u.š™µ=1oW	•ÿMbëw£°2Ivøù:»Ï¥çÂ´ÅQô.« ÕwRÙ4
ËÅ… Cii
Âü©°§µ#åeëDŞ€ùWjiÂÊ]~î[;È»Öã)³JFqeÍ]ÆÒ÷œœi·”Ó¸³«	ü˜3AãKêªC#DTcš„%›tº@ÁDLPòˆ>3ö8ŞÆö?~â‘Ûè_è@Âğ$©½G/D¥ÛT>êGaŒÄmvÈT†ÖÚ1šMĞÊ4”ª§@	.è ’½Šu:ìó¡#2Ù¹RöJ·"†@¯
¼|tbXÉ·kC¢ØŸsõãƒè>›«ÅÜù%ÒÑÄœ5OÜ›[RB;=u µzSªòÇ‚H‰ù•MæŠ'VÊâ4´5á™IŒ~061+dvÖeå‡˜Í^ø¯üœŠr2Ôê²çéş
|Ï€|Â”ÈL‚¬jcx¤p©¥Óö·ÂS."Ê2}e|
^-‹Ï®Ï3‚Aø~üÓkáŸ3óB‰
‹ß”,7E²á<ŸÂÔÈÜìÃ¦†wf>\Vl>¬/P²<NÂÌÂi·|ñWÒ÷!â(ıE²kK–b[NÃÀdß&•D/i†|znYó•ÒÉ/¹Áte†^÷¬CŒÅâè¼³¯ş²@ÑÍ‚é2Ëœ¶hGE~›H`U†©jÔÉíWRjö»İX2 ¢’9ûïÄçê¿¤&ß+çDâóz)éGbáğÈ“èLÓ³Ûœ)èò[-çÂ*ø—P¢[oo±å¤öíBéø“äÖÀshQğÒöÃÌòÛ’¦VçnÍ²ŞàS»u–ÛbIğŠ~};7i€i·µÙ%MzM¼a½ÎNÙ›p@PÃw‚Ó§JD×Zï­¬“mK!`(0º)Mojíe¸5†÷0…	—b¯lMqsÃ·Ç’±ãôŸAÍÓ”ú¾Å)Ş©Ié®oc_¥ùíŠ DG<ø‰rª«™²Ïp»oŒ¼±[iœƒ·Ûj[Ë³İ¢LìP½«kL)¬ŒKuuŒA5æ¢+Ùû•[h'é„FÌ“á’9–k¯ì›QÔ‘PâoåÌMÎD}„§Û%_\×ªÔGˆÆE~ÚÔR¶¼ÑKA¯X3Ëìú,HM	‰âÀK¥‘€àÁC¼?	; Â@®°ew]qzû´´#–Á~İ-–é`ç÷5öH3©8hg÷w‚2–â5O§Ñ“·QØIÊ.r¬¦Øßr\¾Ï°­&y©aœZ Õ§k`–ßãÔµ8xÒQ"ö—6Ôu%¥·æŞ?€Œù†î¸Ãu\û´Š)\ğŞ§@$ëø³Zv9;¡;¸cÒ-)kªQp¥V97¼}À¾öÌìoáÌGy<Ç[oÍ< Ğ_-sæld„«4xÇ+:Gñ¨yb
ö³ÖV?]ˆšÿ%{w®	—qÒÅÓ€µu¿™ }ÚR*œ%ĞóQÓ#E.·ğx x Í’˜{Dt¨à,¡ĞêáTÊŠÃ"xBr©İ½Ñ?Ûèr.>I ‘¨ÓõĞ„Èd®+k¶Yk Å68NFL,ç¤)>¢SÔ)­šˆUTı“‘ú7‹Vg¤‚ÚKï•#ğYµeÉáQ2öÊoR&=ÄewVÇdQb¯©ª^HÑŞÔ.JxtßBæSn$ªõdë§‚nµvö¶1*·V|$Ä`ö ù*tËò±s±´à­’\÷¤Ò®q^iCîõ±€h•KCyÈ0Ûx‹#Ü—!ñ@?ÿ®ÚD‡à:iYg°ËŸ5,&zc³zŒµãuˆ%a¦.B0òe¢‹õe-º‘Ãm{ólØ¥&q‚ÜnŠ<í•ÍÜ'‚ñy8ß ÀFÌ+MB^‘(÷fsÜøĞ=şåp	>ÌÃÈ%hiSº9ñrVÏ-õO÷¾|ÚÆ´&š£¤Òš¸:²óBÙâùf›ò€4æ$gÍë[õ$ ÊøåÏïø<õŠ‘@ÁE{¹¯~Õ«Áª
È}_Z;R ~èv.WÅ³ÁG@„ß£üˆ	h·PŞñ$VtÛ´9¯XéÁM8A‰bµÓ?¢ÿ=Ôõk¾„=dÂëNÌÍ%ßË<»~Œ˜Nõ. ê'õŸÏ¤V¹÷€7Øñu¶ÍÃòïG(ëFed0bª"±^a€Ö‘’¡Cî×pÎ5¶×s3
¢Üo·2Á‡*8š€ÿ¬\6z³‡)ÿ±Èøç¸k‡  ´>èïm;ºx\T—JÎ9÷˜àÒ])`|fíx|SÊ+6&ÖHLéŒ²¦ŸËu‹e,T-„×Î)OrÂ®ˆHó‰Ä…`ÑïŞ¥‹¼hx¹
1ş`sî§^Ú•Ì2y‹sÇ]4¬ünî¸:Ç5v0‡R»Î;O £+HpR¥y»´TˆòNƒ0xR`>æi@;a@’P|SF-ßµÑé02Ş")ÄXSó^¼‚ªŞù?Ü±í7×Ì£&RcäÉeåÍäÛd+fÈq2NC#ØŠôŞU#ŒšªÂ<ax àèAîå	'Ïƒ7êõÕæR¨9¾d§$õ^ƒKû*ÿR2Æıù²‘°´èm|”[
YÛIÒkyÔŸn‹v>cÀ:ÁHÏÖ“!EÙzFÿFö¤¬+&ûOç’ÿÇõ)ÆúVÎÜ?ôÃï¢²¶jÊƒÍÆ´dèMé»$?ÕÖ[(t§X{ah!1€×)E¯ÂO¦eÔ®¤÷©CĞ‘hy[.(/KXÕe÷§&á,~í"'Ú\ù×Öb&=goH^²–ŒÒé9’WàÈäNPèªĞ{·•˜ ÅˆW¥]“ºM¹V´¾?£n°]ŠYZó¡x;b&5´‹3úa^ßA†#vçkØMÉ Ë46Ñ’áÀ]f£ pÑ
ÙSĞ‘¸¸Âı×š%ø~¸r|G÷²|êPò† AíÒ·a½‡áÚd]”øĞe42î¿yc lkex^Æ4|^àŠÃÆSöBû•ç«øX`Y2ôş`§C•³*BåƒX±uM&(2×Kµƒıúœ	v‚ûv“„Î³ Ç;Ç#WHœÄU[j2øZø&fp´}ÌŞ˜/%MµmO BÖRµZe/æÑ„\å·xR+\ªÌÅh‚Hfü; ¹PT¸+¬ä8<®ô¹ÜÛÚ×`‰…Ùq?À£bİ¹‰…†O.LgÓèt€—RÔ=ñùK¹–b3àªb£÷êA%X..³¾‰ó ¶›´"‚ÿ¶ÁRkzŒù_ÇrñÄ*ºs
¨Îë‘YÚ?îuƒpìğï‡=RÆB`ïù}‘mËëtä‘Ì¹NÅ¾€Éœşƒ=ÍH¢áK—M§ƒwêªx•F³Ñ³›ç\5Jõ© xMxdğMoÎÚš.Õåh¨®–)‚»õšØfõ/qƒ —^OÜ„í4Ûr®§Ö›ÕBYìšøX¡O¹E:¨Q^w7‰‰<nt+ïæv0Î5(^i­¨ÏÜI‘à;JßR.^‚§,<Ôê§óÄîû‡o
TÉ(¥HOS€É+¬5¸ÊµUo1’'c)’qŸ_dùêşôv)¥]UñµFZü‡ª½ÃŞµÜ=ƒ²$v3æL@Õ¦£4èëÅ¶]¯Ñ6Ü2€Ë!¿KQWıÉú"`‰tJ1…†Ú5ˆ|_ ğş5İ¾¸ú4ğõ*÷feÑ¶ÓŠ3µ·aµûgˆ?Ú&’SĞ±Å+Ï:70hr˜‘Ú,‚ä
?åkØ Ei—öp^ÎZúŞğk«új£¦OÌ7•×àÎ»,ÃN¿çdÊ^ ‡:HIbŒv¥Qz3j‡ïdT¨N]¢¡ëá{]›gœIp§öúŸE%ei\¤ĞàEcñåk‚	ãOò¸şnõ[g{;å´('XUA!½ËÕŠ&jêÿ¯ÆÒu$¸ö<Š¯W®Â´Í6JûkëœI×qùÃø" Ò”*9—º˜=RìQ\‹AC8©¶=å|Ÿİ±‡ölsäÑ’Sp,pü	Şz`Å8– ¶`ÓæEÄÏúÔ9&xvEnXÚpëñ<M~¡²0ê›U^u½“ñ_ ¹¢@àÇ‚ùk5?EˆK	mî“±m5äudË•ûmƒMo>]v}ôİè­fKd!7Œ9*GPéï‘{Ã$›^%­ûız¾áÉkç¹ÓlÚI–õNÛÊ_ m4Ô)•±òJÖt÷GšëÂy$k×…¼f£¬S
a<†«nÔËê4Ü	ªnC	<†ğ3ßû,n}G4Æj‡ÕµPá
xàß¯–`0VÉR`I0-³å/ªJŠEÃò*öà™>8án¸è,‚0&iYœñÊpš™OHh«Útˆ'59ñıAn´ï´-Tƒú>!—:²Á’°iêŞÄŸú@.­âND¿{~÷ËßL½é†<§ÂŞC¬»FÆ©¿xL²î=ë¯Y}6ÈF‡8áD-ò·hFŒ' Ä_X8ùÿGcEN›¬wi¡à‰¥„Ş'5·kğQ×İíÒtçlp©Ò“¶/'¤.¤Å…œÑÕÑ˜ù³¦ßó“¤Ê}UÑ­{–ÈÉ³šÃ{0‰Û÷Kà‚m}àĞÂ_OĞîÿ]m¼&ÏÁ ºJşÖ›—Ká³-ª‚5U|äã©|¤¬w´Ød¡­·½	âg{wv¬³$ƒÕP‹è*5âõê3«ó=È`kZÈßnÌİ¡ÌªÛ«Ì„a¬†––şŞ¡MÄì¿õb ¬ô²nwÖÈêÅgG”Zh_*Œz…/Aş$:ËÒpƒ¸YVµ¤<™:YQª’
…»@´8A„p<»«®VJŒÒ£ûÆ›‹&–3¨VñRç³cpÉYú™ÂÕ!-œÊå:ñ›ß°„:?9‰kÌ8j$è½7Õ«¿ù¬H¨|”™|Ş£{L!Cªµ ƒï;¤èÓÅxX‡‹Sá¬9‰	©«ugÊúw.îrkQ|0<Iõç‚ùÒöw0=™7Œ³.ÉÔÂœ´ƒíØJ'•åyí2·ÑÒ+¼âsó·Ó*\j¼jÜ£èmŒoÌ³¼òoº‚Àå­~,J÷×§È_ŞZ†ÌJ1ì¤ğÚö(	ïzSk’œü	`b:=4=ûVÛ§5_-,ôû; ;¸LĞí7ŠÙxJåXËZhÌ©:ñÜÉN*W6†á0r’œô–6;*á²ÙŸV\³OALÃÎ;ğ×ßyŸwÕFu”jL‰í°‰Ì÷ìŸ]ş”ĞÍ¾¼
àÜ?u‘ù9ÿ5ØJ¿š“³€cér¤Œ9Ÿ‘MvÀ±F«5ÿs¥/uø÷ä.0Pp¤`JjåMi-Í§É2™PĞ§S_Íä_ş<¼u…İ2‡C>3¦`‚U¨İ;©­„‡u°’¼D§…šDÏŸ’T"u$àóKSşeu¹?±}±°.+ÀĞ±‹Á|2+¶?•ôùêt/F†ÖT×’P˜P
óÕU!>G
0¿ÂÔLTÊÈì	û*2¥Ï„ë§7ÿ²®lÁ’ç¯«8\IßôŞK>eG#-?Ñä-¥%0¸àa,‡5r#‚:F=B<4p/ÈA”çn_pìl•^UD…˜”igŞŠüÚ¥ÿì_-ï°Ó
ÁMœÍNÍxoìèªÁeİÏìáˆ·¨	>?+Œ“)MM<İLâB¢	µål¯å‰*xÒ­&ÉH]ÛİkÛîÕiáE±r¤5±0?'Í$[L
@ÄñêÉ+÷÷øLa£ÊÜÜ©=¾OëV,ê²¡àµ«dsEMR²Uò¦iYfÉ”Í›TûÆó~UEfºÿ`­•pk“6³ïJ÷Ø{vH+McS‚y­g(Uö¿(é­’9³!dZºÀ‡v›iøiH—ÁDr3ÂÿŠWÈîbÄ#÷ß±ˆ1‘ã¥›(r•Ûºq(É’8.Üğ€ÃmÙ†.Q¨s‘ëÕÂ5J¸ô›S”w…ÿíGËû)U6PÉœÉaµCM[J<ÄŸ†+ë\@Ôt’‰´¬Ş’MÏU14+)9;¡RÚxîoïc	¬dŞç=:eÙ§3K¥oıÅÌ,n;³°˜—§Ìå±÷5p+_¬¨ß¼$°ıÂQÔ³¿‹œÍ§š±Mëª¦“ŒÌĞÄ6.½2ú¨¹AFñ‡ÅÜÜÊêb'Æ>&@||9W™Z–9Q
Aœ]•¨?ŠFÛ½3‡Ş(ÆÙñ64V¬8m(~\™·&Ú€Ìß@Ş”4Í¨E"ó§ØÙ/rR4ğDô*|ëMO”óıa“ıEV¢£¿I86'šÕ%k¡ø½ı	?BfÏfğî¿ò?ÆïîãÏíV{ÚIxù½*=à ŠÈ/}aàZ¬ƒ”NÆÇ7˜Ö£ç¤-:ÙÑ”_õYúªÛúvH·Æõ#ÎÔ<iÔ/n!m‚9~¼©Ò—´fÒ×…3ktå lv	gtÓë{Oƒæ¾eÂÑ_ƒâ@ŞÈRL`;Õ
"é”f¦yLõYÙSL#=|Ï"Ï;€½v9²PÉˆpçecÛZÃŒƒ	«
ÿÑ;öcÄƒÁe=e6” è<#’‹¾ùóÚ¸M A™ƒt´Qó
S¦¢f“s•SX3_÷¨‹hePë^_]pÒ;U‡Æcçşã–_—1×·ÿc$Ì„?û_ “òtÁôÑÈ¦SfÚO‡¶î€
‡F*ÿ¬k™ v*Œ µ+yRS}Æ}™ƒRåX/E
>,Zn¯rnşı3“uPTf‡heßïÒ]ƒô˜Z=o¬/\¥È´¨SkrÛ'µÿ:*ÕšÃ6óU	IÜ£ı—lØ_@^;p[v‘Óeä‰Ş8›XÉ=qBÔé²[Êßfƒ”%Ö÷§ö­@²7ãšèS(b%É®j±<p®Á™Äğ«æìüIs5·m]5Ô„Z0^€¾É¡Xş¹÷Æğ¥
ÃÔèş€ø~Æ.L}.íg¨ÜæWvşé:äògàL-CşÇUF¿Ëœg!SïÛ$éo¹¹yù“¥«Œ: YÏ'<ÅªÊ¦ÆÏÁç’Ùğ®ªÜ‘¸T˜BaÌA7M8
¼ûÜdÛSWqÒûÒø\Cò}Å9GSŒ§‰yo‚¬ô¢èmªH›SéR£k>4“(!ñ u%b„!Vs%+z£jyèæcCÂÃ†•Öò]5ËK®î!AåFóÂÔy°
§âsl)/[rã¹óß3HÙßkÄM€¹0xã¯/“ô{yĞ{,-Û8ÕaÕK2Ÿ™©ò±zìïFªhºÔef|ÇÎrqe3?I}G™?Doæ¶X¡h]Nü®o–g<sÔpÑ±¥M>uÎÑ‰}ËVŸ§x;.—ÉŞ<t£±nÃ|"Ü0Ó€ı“ÉmàéÆÂ_ş&±èóö½|Æºn¨WåÕ¶ˆ?÷Ò°d¦üÙKç¾I.oYÉşµkù±.?»È"Iˆ|{¼¢Uå‰V4O¿6ùõ$GëÄMÇÖ|2M8ªú_Kìt ©êcÌ³ÚAÙ&ä¼ SÜ„¿Æì—®S°0ÏpY\ùK 9R}ù?¬“öç÷‘ C$Ûô£ËbG	]ú¥®û{Ò€Œ‚œûªNºÑB÷B²‹<éf?üñ%¸	¥Àå‚“×Â÷ë!Ø¶øj>Øë_¯á²Ğ`İêoE±CRø+¬T<HüYº;lÌoÎqëÿşòñ8…ób÷¢oçEóE$Ó"Ãõçú<ß™‡×ğg§ÄN^V"d@põ¯8•l o~ïkV1ğ 4´×}>1´É¾öÈ"àÃØÈö<,±Ç]U–¸“Ğ]-æ>|ÍW[D¼ fvĞí
LMÀzñŒBZ7GİgñÛ¸?ÛStça†¹™wœ=ÑÔšM8'Óì“]DR®3—ŞÚZêD*SK:Oøi:€œŞo+BJş<Ğy¾F¨ô»T	¢¡û/í¹Œ¹Œ—ãà+º[^h ôÆÌãôcç0¤‰âíâMc¹¢,Ü\À)SúSô€ n÷İ‡UšßÒ£ieš;$³é'!î/O‹6£û»ÿmòÕ©¥îŠ`[2™UôwŸvÛÀë¦SÁ²“?;Q¨é0{÷÷	ùm£/BDğpü0Lüm•É…ñ²¡M„½êP±Ï‚Öl§Æô÷£õŒŸÆ$ÇÌh$_5£ª}‘|ñ'©¹v{I"ór2â¼P˜¨Äâû£:«ù3"^ø€Çõ^Ğ+$ÓAF\¯‡„xÿôBÄ
¬ó|QyWB—#µG`Á9m’˜‰Óø–dĞ3jÀ6×ş“;’&w"-8ÛCÔ7°„zë®%Ñ	dÄÖÑqHTjëäÊ;š+Rp,äS— 5æFÉ!ƒå`À½L/¿%2€ºEş©~ì<¢ÌwI`ú³_?XkY¥ë¶0 ˆª4¡\‘ÛGYnb\*+æÌŠ7İ{&†‹WH£UÌ‘í±‚À-Ô}4®­´Éy?‹Î:,ƒw™ŠÏr×ö¯µÖŒ~­¡È'™JvŸu´}šŸXDñÂ²ıtoİ‹¨×°cÅ¹p¢T1X‘’ĞSJĞË³7¯@CËãBìG×7ùÜ0Ñ®²¾?îF˜Œ¢y¬_›7L2U ç×Oè+ù0˜½m—ÊÙ¨1QÉø¡zòç§Ïå?#­d,ÍÙ×’M×ÃVı§ ìHlów9ÎK³*:rOs5¢ªpç–ÌW+è×`S
ø`¨GP&„¦ã:îà+Lv9Él÷°h&»/†cOôŠ¬Üf±#~(±³“Ù¢Uœ©
Œ÷‡ÂŒ0IœL¦c©¨tácı¢Óæ˜u d¶Ñ V´„7{l´Wal3¿FF&şÑˆÕ'Uã:ÓÊğ4OÃòOv%°Ä×$~ìù:j  ú3•¨¦Üq0G²@!XkÃ€ª,:×á”Ê\ê\òTÑ±§ÅĞˆ[×E]—Ä›PÖ4{~Dº Æ\ÉÌéÓhÿ²Ë»Lá­Kàø. qemËã–_m¿ÁyÂãÇ\ÔZÚ$03F„« =´ß)_YÑXõWŠ—WÅUİÔå¶ødâø’ªB`¬±“[KÓ€|a-Nh `qHzh!P†£Av«uòÃ¹Š¹t– 9EğudYYË¿á=OĞ“Õîf1ÈO‡<œµ£ &+Ë™0Ll‡éVÎÍrêšÍJäÂÉJ#/”æŞûËæé`ìò#­ÄN^åÜRˆ!üÖ¯–‘»7”áõ£ÌNˆ|Ü¨ûíw¨ùåU°0fäs„m(0®ÃTÉäaµ}µ#Ô—T¥ï!J-¤â~¤Ä;d†2kNNĞ0™A|@"
”MîÇÃÚk/¡øîçÖ4y‘’E¶Jj3YÜbNÔU6ÚO©üíXgı\³	•À*r×-…‡'ğ¸º1Ÿ‘3·Ã7³äÚW—Qõ>ÓÌ›c¼Ÿî Á‡äëğDùdË=ÿÀÜ×Ÿ2İË`ÄyéøÚ‹|;¿PP'q&¤:ØéÓgÊä¹¢°àØ“ù#İ­¦j+>î¶4'¢=G-$=šñ¤À*|W;J7ë×İ%Q*İ)`ÌˆE:sb°'3}á½ x¥¬0v‚Óæa»İæÃ><GÊ®ÁƒÏô^í*âW½Y|Ëëö“ãURvÍs°‚ƒ*ıƒJÎ0Ú³õÆuD¯¦²‡m3&KSı>Î”ŠN‘¤1Ã Wü`?ÇŸ¯ÿ…™MÄ9f²#pÍzŠ³M	£ÛÍ-wäBÓÌŸî)ÑÁAÃÉ¢Å9GºÁ\Ì,ğówó~7+í@pşDÂıÔğNFkGƒ=âäFGK@¶ˆø¦ôŸjJS+ëôŸ.œA§ÙfI)”©XæË•!Ä~;Çµ&Cáï8¿fxfEôm›İGŞ·¢ï—ã×~ÓßafÔĞ–x}4#F©8_rÙ0ÅsíÜ.GÙ6,”‡mElc2€µĞÃ&óe±³ßø7R5!o±ÙØşr€÷|E­½îöN0X'
Õ°Ê¸<Ãl²A LYNi²;KßûCñ=:±laÊûy ÎÓüN©`ŠÑ€úPJÜºGRz­eª‚ÇÅ5‡ÜÌÙ.ÚDˆöƒ ÜYˆ€Z5èò’%æ1ä=yd(À°oÂäÅRÁïËp"†*¾TŠÒ@jXGŠĞÀñc¨hQÉp%»Ñ×Súƒ¨%`‡‹Ñ†v«,Ò‡ËšÔ›½«C^…n-Ô!Üä¹íá1ØOH	:ä"jû%óç–ãiÛ”}wyİÉz„Äîï\îÉdªa£QÜĞyRŞB³‡Ã¼”kW,‡½<5Øéˆ¯Åc…¼ÕîßöçT¢»#õ¡y+ÈÛX¦"İ·VµãÛË M‘T«>Rşİöw²9›ı¡y6^µmıcø¾)ä¹Mõk>2éNÉÙˆ=òÖmAY“«e)ÔğGwÀÛ¹”£|©ÇÜ±1tÌ]MmZ?Z¯1‡]³HÔ›‚HiïI6|+®É{ËªÛMôT‚¿ øÁtÁJÿ^D WÅ¾~YÁl0Ü-ÜÁÊTH¶]Xà]Ìsï&vä¦å*Dta¥øØ‹ÁMoÀæáK»¶Ìîk·5šĞüBÆ-Ï6å$<³Ä©;îLÛc€ßÅZÄÛø1A4Ã·q)yAiâŞ>ØyâìÑ¿¤±c`€Ğ£¾úeØkÀf»\ı³âÃ>"–È¹r½eµ¦tç÷.‘Œë]ÌQ<ßÓ7¸ÌaÆ!‚—A+"Õ=•s.Ûæ»8¥ËhĞ‰Áu'Ğ¨”ûÓKŸ*ëåCŞtŠ““ Ûc4*Øtr•™Éñè1ÛŸ™œ¾ Š‰È¬ÖX,ıü²¥gfá¶óÊ\Ê†: ÌšÆ·õà˜¹íeÌE‘µ98mş¦<°R™,$­f9²¶yı;Â6^ZS8xT7ŒºhÃ;–lêÃkÀ‚áı‘±«º$8Óçé°‹¹)¶5Âa¦:c`ılİJu0¿ÿÌ‡OËèz;şãÉ|§yp‚v}¯{Æ½´u”1˜‹,GW.:„ò ±ß”Ï@ÎŞ×Ò¢&o½Ô1<qòş-İD:M<Œ¶~ğT”ƒÒ†¦Ó§`Œ-~¢M*qºÈ0ãôJ™(
ıİ
å™¨ÓUªÏÕí‚§İØ… Ş<rÌri®@á?ÚÀÜ€xZÑÌè¸hxèAÉ{Ù}g9{bïğ¸ÄÊ˜»Äàôl¡¾…uşEˆÄx~²6s¦óã¾t1-éÏÒä8İöW²õ$§ÚöŸ}™î€3âˆT;ƒdFsS%Ã¼´+H¬1z†
>Ï7-pò1+–(Oö©%3†Qõÿ}*óŞakê&¶.…šJ²òS>X++vÂ @êãŸû½ q]áúx$OØ&~LJƒä‡åådhŒºøo¥Øiüqh0×ğFrÓl!¼¸UËV.ÖÒ[ŠwÈ´©« eK›<¢q¹òo¡U5Ãâ†L Õî¬Vşø­œ~¡ïºú¡!ÂÃECı­Ëro¹¥³ª˜yŸ)“skDÂ0
íL?äWÜéŒÂ6e³ja?\“ÍæMÂo$È©DF6[¶øªôÁ;Bºµ®WX7ªZh2¥	x ÷õ¸3g …WÎ"£‘ˆ¥â´¢•şGæJsP›·j8±Â‘ŒâŸÚj³Dù’(²¬í[ŸÚM_¤ùQ¹/Š6Ûî	  »p¡8à=è»óD o£A‡1]šÜOVÍÒ˜ Ğó d;„«![àÃ‰dÇÈ‹ó|U³ ûTÃÅŞ=5n(Ù²ÛM±ÀõŠó˜ÒMœ…µ§ëØßOçÈ+3¬HĞàò1AF²¿8uG•ıè^&ãµxĞ]šÚE8!6ôEº–ĞÛàÔuäQø¶•ízİr²t”Óib>-ßJxmúo{zDEA)Ù™­ñZì«U(¦_xK‚Ëù½xÈ 8]"ÿü–8Ÿµ:ÙTˆéhÿ6İ„„ïÆP0ñj;1ø"íûÁH#@s3R dd)ö$Hd`‘®Å º{õDWêÕã8bÙäçˆCuÜÌëèî‡İl¢{å†€š[÷J
 ŠŸ¤Ü«îdÄÒ ½G­œdÕ-ÈÑr‹)ïPÁ®ßQ³`*»V’Ê.€…@z-ídæ4‘_{ÂÍ@J'£í»^AÕ|6´h~zÎÄ ˆ!>!—sGÒ›À£å8U»U9‹ğ´¦é¥76:pñEJ°v0züÇ½€ ÿ,<Ã0ì?ã8xæ¬ZQ3ÍkG[¯ùGúÁ¡b©_We„£*mL8õeë]"J;ìóíú²çvl]¤wïÒ>,Œë3µ#íÈÓìXQsâ$¹Ka¡@€Ğ×òZÅnVU¦OÉÜ­lês4“tT=gs­k5D6¡`ÑĞÍåŠ[Íšï³Ö–§.gßÌm¦~ ÏæW^.\&o´³Q[™nÖÑKö'mƒüÓ‘rÑÆÖeÁSzæ¤	(Ş1ÈŞ ãƒtå6Ìe¸Æì:?OÔ©…N¦ÕU/ƒ4"î_­I~Û6g£¡P%oyçäØØmÆË‚¤ö4~µ(ìaçÍÑø1²6ÎRòz¬·îoçwÔ'Ø’nI]$v£š)´èó‚ì=*i(•ÉÒì§~Ã#•€Ñ„-<ëeLôÅ+µüŞY»lSö¥à-_5€;Z‚œ‘!>Ä¸A_­c¤¿[+ßü¾¹ìd­éFËWÊ¡çjÕ µ_=g^mÈøÃUºNv<¸©Ùº$‰Wy,§ò€0ÅóÛ÷¦¤Ôôí0`(f9ø÷Ú,;…-7eÈÏµcBô$•TXĞ(†œÑw+SÖTP Ş,jÖäHT	s÷£Õß#—ÜOáË¾_šëÊWµõÌ@v÷½Ë~™uxİÃOºúŸ½'W:¤÷ş*_‘Lç…™g"úèº$%ıBÜ"¦†$ø{~¡¤PtE÷™ÚêhqoO=ñwiq\±üàâÈ(<@êUæ¼#åú;Ü!…4­Î™e t²ó"e}ÔHs¬%5ä:³j¨ö"¶$ê˜”úŠ‰ìè‰¬îáp^¯:ïR7-$1u©ıèe+¤†¾=xÉ¯,óXmˆ»5‡Ä#¦P÷îÄÜéˆı¼ÈM4şÊ>j•è‚®®¬ újM‹nâ¿Vä"60–½§C¹¯NË‰å±Õ…~×¾}ÕK®‚+¸Â§Ô0¶ß8Ø áeûõ‰§íNK”Z² ş¼póÛv?Åa0şÒSg)(©Ë(¦w½f¡õA–Ü§±2`_n‹Œ'Îöi.V¼!{Ä…¦ÎDÛšl!Á¿ÆİrP;go pr	ïoÕ»]N³Èã½
ÀêS¡}Ñ„øQË±Ğ*}xF;|S¹-ôä†nÈ»à¬y.¤ú¹`…	WÆñÓ¾£IU  pDøWŸò®¤€5'wõ"<cî® ëRĞiïA;ú–€#¾R5P&·4ñ«*ªÆ¸º$tŞ;ß ‘o…Àñˆğûô‡)
G[ı°_âã|À’_ÃŠšóİA11mP‘Ë
›-„ÖB€åôÀ¤!åaaİ‡ÄÈÓ¯»òÔ;}î@åèCOPAiä¹Àö€œ–·¯I<*ş(}ì‹Fü¤Ş›­¹¥?yÒM¾à#ÈËÙ -Ÿ²<(ÏìªI.¢Æç–x_Ó ¢eÓ2µV˜)£+ŸúQà^B¹z¦g.4?o#¸ëcöÜùAfzû’Tõ rIüôcD¸®çväÊª³T‘³
oi‡k>ÊGx–{ïÂüxôä‰ê£Jüózàn¨]Çnÿ<R ¬2_ÆL'«ém,‰öY(Ãr–ËAó¨¿óÍ*_•8P«ª¨Ö=HÁN7²)A*t$üĞGÂ0Å©Èu–êAd3Kç\îAé§´e¸30^h‚@}à;f•Õ}[œ¹š²šx!ÚDŠlóñˆE8$@…2W
n”®ñTÄÚ³§ù™¶ºs¹Œ5`D8Î…“2õq®„1Rm šç åÇij]MEP^?ä4õCû@:ŠÛAíÜ…ç^jĞ²_l(Â¶‘r‰Fw<~ù½ĞŠ-]Ò&’ÛŠÕeíFÊqñù¯vÛ7®ıë"'ü…’Ô©¼|ko~Å’óï)T¢Û@ş¯4òï2“ê¼=ü„cÑŸU§AÆZ"ŒOLn8”JsV©¶–ù®6ß7=›z.¦hÓ˜ñ¼dXr‚H˜`6nœÂ§^Oá®K®¬ˆlµ„µ!}Ç ğ&ÎÆ/Q‘/_ôİåíõ²ê°dgÇ3(:Ën{û4zìé¢ŒHnÁ½‡VIÇcÒİpÙuWE‹ØÂbÂV¡k…H‚À‹ïœ¿ì*Öš'w{í4N³9Ãºxfƒf=¡ûlŠˆNFÏ‹ì9@/>>àÍ9”ésFnøâæ…Ğ¡_ÜBà‘f¾°Ç©:S’òŒîÔuå¾Ç•dÒd6_ıUa×ÏĞi½ûlIª-(cÎfW_ëÙi·w:¯íh®×¦Om%p%Ær…®%İbõZá±—lş¼öÊÀ!ï²C\ç×n‹„Á5Ââ+lÔ°ÒÔ íòõª½µù?#Î•zDör©k'zˆ:%`u<fºğ9d¨ú¾ğLuô‡åøo†Ÿz—ëG4;P‘ÚxÇ½lÛíòœ†R´g¼šò‹Ø¶p¼ŞO4A`Èd QÂÎÜ¸Ã+/ şÄ•YáÆ	Í¢MMrˆt]¡hô×a,¸§Ìô™L5¢<@}Ræ£HKúÔm.‡• /W{ØÜŒĞ¢
À,µÅ$×Ï {ûì½q}ìç‡<Ï/çN-¬„.û'ÑJR×ÅM öNq¹İùoQõ‘`Rnn!È.Ôæ¤T­+â„Ù’Îê!c˜ÛVbPd•j3ÒÈY†yOçFB*q•IP6PÛà4“+nG¾æP¾ó¯±®Mx§Ú“öÏï—Ÿí ¶Ğ…AóåŞ X´ç´fí:fÈ©„°l·½­¨¡EízM$÷`Yßí¦@#zd)D”b¶` ­Öãö0®Xu¿ó!:lêG—×ñÉlÃü²uM1Ã‰À™ş5^ªfîĞf+€ÒÔ$GCÒóZşuRZGÈ®~Ä8ÙĞrE¼(C€p‚Í7Èk?©‹õ`¹ic´ÎWh"HeeL~‹Ğ…}GÒ°øç
«ÅoÙ3¼…ôjµ”Jq´75dßí©à7ŞÑúèjÂ<™‚tkÔúÎ½£mhA¹y‘PK«„²Iì"©Wà˜TÑ|VLñ2l|ŠO4Õ ê,;ä˜€
¢!6S`*Çê?!Ã£b(45`—ni¼—õi+†¦ñ"ş"óÓ-=ÜŞ¬*	Ÿ<FA íjs‹Y/;KEdˆz©2§%…¸Éˆ¶Ğ£›‚4ë>Ä+ÂÏÚ/§µ°C-ıwOí?ÈD—·œuD33ÛÇõ×ªe»id¨,Ó‚İ¡.ËÖuŸF)İ1ä¢å0@ÉY§	ïZ¥ezZÙ¯¯IBltû¾x-b„¦šÖcByWB‘4 K	y¾ø‹ş^¶øu…»áª„«ß^H¹¾¦®¨H¸y–8+üñ½R\~ÈöøÓå¸«×Oà–)ëÒX”wÒOfäıêå…vNuÓ×s°´ìAmÈ¥¯9U%Š^Aä“Ê«âÎrš‹­z Ï<F€öGqêa„|O>Ø_=Y·i(±xŞ‹ß¨;68ëÌ9ø®Cšª=“‚Ë®¹¶o^˜PÁÌâ=©Pª2osçÿø¾áşn)w¶Cª$bM/Rë{gÌN=°k4~j„«—@,		+ä<GóÃ&(OƒõòBã+î„ÊÄ y÷ëàâ­‹çò7<×Ë¬«îN,¾³¨î½ŸµÇï&YşñÿQ¼œfE×ô¾5“˜ñœX´¤ağİš°5Ğ›D›SıìfÉÎ<aÄ<¾øÿÙÂ¹}¥ò&/ôÄ:¡*3$;ÕUç_t+]"ë=™dOTÖòÀ` ¯)é.FÎjp§a#‘Ÿ4¦0O³N¨¨pµùpŞ#·ÈaO=MÙ2‘[YÊ{I’T®X$k÷ç—¨5ŠØ3o/„€•úlB¬§[Kµ©¸¬÷Y2òb,íÖtaÂóÌ:VÌ›¼‡ää3rÁòÌã?s—çá+ÕÈá>£ë;Å­c©_‡Ñ;mBÒLHîSCŞ;¼Tùõı«ğuÚYé†Nqí+MØ¸±Ò…ß¥u!y!ª•œå¤$<ÍDduM‘‡<îœEi& Š66œsì‰8úÀ#ëÈù!7êÉ­#H—©±È+C™Õ»cí}ø¤gˆ%Æ<¡º­>ŠAwDÂÊšØéY©äñ i^°şq24F0#6¢ óª…ŒIÕ¢Ê9É€mlµ<S¾Şÿ€+ U|’–)”—$;k¬6ü•CûòÒAp¤3oç*ŒŒ„m~]	Ğ¨ü1s!òò, ”š¸ï<qàbU~`yå¨32@6Œàa	ÀÖ,HÃWÙªutÌ¬5x
3w÷K
Q×¡c\ĞRM|ö,m¨²	0ÉªD©ÓªõÑ¤ûµ×u¨ãGUÊ å#œ‡{:¥z©•-XvXÑkEDË¯”êªş‘#u=gì¯«€q°¤ã(˜‡i9Mû‡Âß:ƒZéã‚´Ü:h×ó[WQPÉ´&}6œd’G†L+óŠ9}O¼+„ÁUTckïûÌíá…<âÍy…¾.2Øe\CÇÈCkrÿûâ3‘k*ua§qŠÏI‡JÜÇì q4^¤È[±FCCT€PÛ™‹ íÃÈãm°µê³@ı:¥úkc(í¶m›şèVQ» ©On•Êšo´oÄB~æ¡4j;ğ.—[3skwPéîôHˆw¶"­±31&^İ††©B×*µæ~K÷¾n€Í1›lcûÎîšHã°W}<Ó½ ÍÌ¨]§TÅ8–Ã¿Ê·iòïIâ…j½(®Br³CŠÕØ)«‰ôÅsQlÏğËÃu"-æ/ÈíºÅ§@à<í/y)u¸\CJ®™•jåÛĞµ`Üıö˜U×['Ã),ò11Óé­¤ïå°x/´vƒÉ_Ğz@ü¿NA¿J£
™\Èò·Ûhr·Ä¸9-WGÄ%…“'ÿ[÷…pÓh	A§ø} ğĞ!ËeLs¿k_î¼ª¼/fî6C¤8ám‡G:ê#?ÀÇE™§¥cöqñF6Şæ4€7C˜cŸwòÏ›…¿•w+êÆNb(ÓÚ!GK@S¹Mö44 a‘‹x1’Õ.¶D¬„pÈsüËÿ´Ã®uR-À•ŞâÁ•şğ°­-³Ê…©€ÏÜG•'¨k¦­¢jùôã¬Ê¨OIªIÇ$Ùã¡HÕ?].p¿-'(S>èŞ&¿ú©íX3_)ß9€£4Y¬ÁøT$Ú733µ½›şN^ü]âGœq•ü,rhWO>ÍøØ»Š	}m ;pëısRy¬¿ùûÙ$Hd£,ğÚçEòàÀTªR=ù2/+ä	y-uëñéâØJí§şYÔ¬5}ªû›s®7NŠüBoO½pƒNO—Ÿ¾&{cÆ‘¶Ö  Sµ<eš÷Œ½‰Àê0Z@fÑ—î‘4ò\ ™øŞi;”|‡n~İoWHê‡L=FßNè½y‘xJz¿t×.#ßã¼ƒÏ‡cºÍûAN‹z@Ôï6)×\À.Õ›µ…%rØ†@&’%JÆëÆÉc’à$¢e>#(‚®²
7‰5ûŸGÊµ!ÁŠ}“]ôÎÅÅ^ĞĞš?`n„`óğ=†>]#/¸•ÓA{º9©r6ø?ióÄŒ†ÖJDíT+]Ö¾t}#œıéåİG›=éo	È6T“™?XN5}ĞÅ¸G*hpv…ãÓÒ[zI@nZ®Céğ‡|aõÙœÚ1nß~hÁ
t˜O´› rÀ²ˆ–S)~—YÜBÂˆ¨?t¾ib'[•¬Øzl÷;X	¯IéÃÁI^¥AAªƒôòşYƒş‹‰Œš=ü×½‚ã^Û<O†±B“½‹b¦€áXæèÑz¤sº7|²ŒVnù-Fš7(§7èd— ÍöV ·„Ç1Á‹·™“½aïPX3Şsq¢+Dç•Ì”ébÙ&Ô«ª
?£ZA‹5ªÚÄ<sy¥mxãqQô;¿áF<7é±KÜÂZ¼üwfÍ«ç¬Åw¢¯ù•ÌZÿBü4|ºoY–Ñ°‘„ÑÓ^sÓ1÷¬¼u„X’¤åÇï¯P¦}øÉ<CŸ$à€©4«{»U•Ë	—÷¯ññ-põîPhÁÇi„3X]ƒƒö{Ü­#]üQ~¨	ğQÓj
û$	(¯ëåÏıP´W¿t8S	*e!™Å§ãïê½[vòÓú“H¡Ã^¸QŸêx('ì3@«x¡$Mo‰öh¦¬ØÒcLw9_ñíN=Óå<Õ 1õ$ÏBÆXûş«{¿1Ãøˆı“B!•mÇÜM°òü¤6†1ehÊşH>ïSğş&ãˆ”øØ­÷ì2’2àû´È·]S}¡:Æ9˜Ó¦Š–q‹–Úó‘—©FØü]gY™ßÃÿMã’
öl …[Úl/)¨™¡‰ã‹ävL~,‘µ~1tJáÔdäñäÉÕ=>ĞhÃâİL_Âbƒš×§<,ªLÇ4Ğø’z££.jƒ"C[š…»1Ç/ĞYÌµ•úN„ô˜‹ƒdõ@Öªs¼Zò}[ÿù¢×¤ÊGè;]áZº=œıXãhÒ‰xÑ=²g%NBèÇ¹–r@!mTıG¨¨äa,W`å˜ÁÏn (Á¥p+‘ozŸ(ttã[ÏOI\0sP«ÅußA›@qÜèó	}m¨ZjZ!-ùÑ#unó9gĞ¼{™$^™w°å«Â!R”D<Ü3#ÁY™œc>Z¸:£ uô¹Ÿ{¥ëÔĞ¶¸ÂT˜€×ËÎ³,¬ƒşÛhŸ™Ø`ÛæéÛÀ³§š<º.f?îX-9™Ú_j…vaÿ@›üv¬‡n6\N”ãHá¹”U³Ô_¬øF¾MTNÓÓ‡ÿ×fıŒÏ.ûè¤ı©ûbl$”& hW¿ñ$-/’:Ù?}oô‚}¥‰ƒÎ_	¬Àî”ß¿¹°˜ï;t~–¯ç´²AÓ¨9÷Ê®µ¬ ïí–NPÍ>µ ³ÇĞàÙ+_£xOÎ'ÙÍŸ™ùÎ2ÅÓŞ«qS0¼T£ªÒq¥ßÜ·¢˜	ébÜµ“Áà‚ĞÎ	A‹}#zêÊgì§²hMa<0Koª${lˆ¤‘Fuˆ3Dïä¡êYÑë6è%¨É3ë)7478¯PÄÖœ!g6u‡˜gÔuÓg#È8Ğ<½&ŠŸÌ{vùå±_aåO‘ªG¤‚gä—7sË	è[‘¡­ŒñPÙ¼şÜØÔ#ßŞÓº}0üœ„Î´2"Á.®¼!géÉRŞ°-¤`±³#Š5wİ0ŸEu(ˆ$œ¨ë°5:¥#9’¯÷¤c^º`¸Tœ;_ç+q‰‘³İ\e!Ê«[uæ7øo ŞŒ."ÃÃÕÖàî.yHFöŒ¦ªáe™p¡qTº’ëõR·D»­ssÃQ…¤†i	½¾pp¸"J°o9q]ÿ³Ş4Hê'k9¤ uÖ>ËÉ¤l÷‘¶Ò+©ˆ^ÃÔÿÏw3ò“"§²y‹VÆ`cËÔo"ê(©eV¯ì(¬CëU9ôEcD=Vù–r8Ä$Z¶˜Ù1+%‘Š‹æ‹ëwç£ßÃ‹â¢¼ÏèÅÃÒ³ÄDó¥†h8¡šğD+ğ„#³	m×|ÚêÕQNJ  ğ‘üˆD;œ[7X$0oËòÛKz²Òö¬çT94Nfú‰s/:ôlµQ_“n+‡/Ô•Œ¡¥´2OŒõÇ
¶Ï;ø¨F×1¥ÿI5+uŒéTÆk°„v2cğ’ÊæOÃ|ãEç·äé»:fI ºìv‹ø¡C6´l™¢ÙéÕ“Ç¤W÷=é¨Ş‚ÁeúÑ§Õ$-sÀYá=(/TÂ­i™Äï:8Àí8ıá[HŒ¶ù=]¡	Nfy¥K^Ÿ¼NfM¢GĞ…‘8G·b,YMI1Ï¢`6)‡µH·ˆ†&g¤äj1gG+‘%—ºFøŞ5WwÑ EÿÂ(tœ@­t˜Œ#¤Ğc•[¶:©TÛª¶&‡ ú¤0sµh*Ê®.>¬ØP8âãÔxqSteÍ/!ód+jÛÄ?Â+;„_–ß‰Wf€’ï]Ğ¶V}:9sÁ‡B"²})M¢««Ì(|}*ıŠúë³ˆŠ‹Ü<ã4Û}éEV‰köÈuwªØÃ‚ÓN›ÿJëÎa¤nR(¿ò2)x°IøÂB}ğAaã ê=s³¬o`
À k0Ú ˜xÆqºQ2@“nOiø>s°f<ŠXéˆ-åçi~±	OSIK×GüÓDu_CL
êj9Wÿ;¹È#Ğ5}>UPø_´!Á)Úeµ.É™Uæ¨+ñ¼E€‹2ÓCsI¹Ü¯¨â7T	sû×áıv„§Q¡rç2˜üŒ1vÛ¸òÄ+Ç"ÍHÁ6gADµƒÙ‹ü—'´àvâ¦æT%ÂÙı`.{_ÿ˜êÿ+lëşŸ,mÎ>½Á9”‰iñíV»¶pÔc#‡{e“Ë–Q‡?ĞP?ÉÇ
>5Ş;mF|MouÕBàÏÕjñ¦Ñç–øËÖ­mj¿z%ş)”®µ¨#¾µ¥]fêï„ÙÁLøcŠÚD5ÿˆú Rs~7“D;rÀÉ¹ÒÊ·:¨›Ìã½Ãa÷Îë3m-Å.»?msÕê¡j8fòpO8HŞh«êN$ÌÒúÁºÈ±š~L_×[l¡vst×»Fõ|³É/ß3ØºÙxãJ
^Ù†Â^a–_O<x¥Õ ‘;¹dB²ÌX%¡‚€nÁ'2ud‘ïŒ&L„l¦‰ÿƒgªte	ID{prõ~V2îd—á?’ÚÜÜÒSJâ¯CÃ“êh!BÌóÈ‚BSÅıpó.ÎÂø¼5	Ş!çê'@n<S€F¡7O@–ï ¤¶05•p=TZ3Êª{1"Cƒ±!™¿ yİà)i#’9} ‰«+œ~ĞG»@½—m„±‡Ø™I‚áÓ—x)¶«HÄ %bˆúŠY:›>Yî6¹û©öÜu§k½„7—¯ªéô¡˜øNUlò‰Éş9ô²İ‰ÂÂ;éı`+ßÄã^jhr\LGƒ^$7¶fä2üãf ?P\4·ë©\èãA³Aü	:	².ŞG%LÁôaáÎi].Â¼"òÕzYBé½4õ3zóÇ¹CÑÊV¶gîxO¦ôÛiX:­†ñú¨g±¸PÁ>x†k®ÈÁ½KPE³î€'q£Ó–²¥6CªK8ü ·²ñºÓó½ßÿìÕëUgÁü¹ğiéeYe†“i$û[l5_…Ä÷A †UŒ71À­¶Ğ
¸GOÈƒi–åÌ}ºø¥ü?\4³”`Ú¼8Ô§DüˆY˜GzşsUşV’9>eÙ¶a§ê<ÏÕàB}ˆy'lµøÚ{ÔÿqÑtñŸãî¡“­o
z…u¯ ê,oóy³O†8q½ I‚ìT…$ñĞß¹)(E"¸¿æµ]±ÊSSÇÅ9G„‹+²sÃ²^qøõ¬‡İ…2Eæ0¦ä7Á÷ÑÊ:ras÷S[Lÿk¯76…‰•@ÔW4KÙxÓ[‡Ø\ö:C2Ü(8ãØ€<>2&óÆĞ
iš5RÏš«¨	¾€P¦èH‹ĞrˆHMùıR¿&°Š|ìâf­]ö’°íEëÌ}Ï|%Ğ†ß{	<Bôxj’yÅ»f"çæ#ıî.x’¹.Y	õˆ
ƒ°çÌ¯‰Í¸¸˜@wcØKRÑ›¶WzÌMö¾G¸m9ıB£[ašÉ5¤4KvV+¾y‘ÔøÜƒCX³Ó@ò§-Fù§¨¹B.%)œtø¬İzÑ†Çù0Šƒ’•öÁb8}M ßñ‘à+î2–cls‡]œo6ğú²íè²ÑPG6ş}»\0çïù@¶5JTš_v£ï=úå—RïŠÿI7±‰öCP~ÈÉ5ràp¤²e‡~ucg}é‡¢{)MâaGøF­÷¤ÿÎAB«§Ì›ÇYc|6kÕ¬àÛÂ>ıÖ¥plo/³Z3”i&½ı—?ÙZ´’ÓxL‰î–ÊõPËİ‰ğYG;îÿøn&VD‹„†ÈöÀZ;èªÄ¬¡‹¼è¯Hí?»Hu;¾%œ "—ò {ÒÔ¦G’¼—ÏÚ^Ñ³Ä´úŞ·È¶Sz‘Èß¯¸›YÖéÓµ:©­·—DoXC {—áÑV7ßÉØ×„oAùş28Œ”0©>9şG^Ø@ÉÌÆü	:7Ğ‚‘7B½Zî,­jŸz,OC6VÍ&¼92Ğ9O*ğ	—Ï
°0©ÚUZD¡áñ0 µ!İ'!Œ,©õßh1¶_ÒŒ³€Ùt3š¤JÈ¦£Ágä±œ³ªJ˜’!,Ôz6ÙYWì¡ÃèQüÀ”şSŞ}­Wä'•¯JèHF}òà‘:¦‹û8XhtèH½n~Ø4Íne]II¾#ô~8·2WÃSŒ ³Â§‘0`Ï+=‹4.\Šƒ1BQæc²1U5j-ü‹I˜g·÷*!JTÁıŸ»™îšÏÔñÚˆ¡3E|K7Ô5ç5Œô×-ƒ|ı¾	:]™GqĞİã  D#õ
†ãóP ˆ¦€ğ3‡j±Ägû    YZ