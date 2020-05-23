#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="759879465"
MD5="1077d006270ac47b4096a18b99ebbef7"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21268"
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
	echo Uncompressed size: 144 KB
	echo Compression: xz
	echo Date of packaging: Tue May 19 21:50:41 -03 2020
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
	echo OLDUSIZE=144
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
	MS_Printf "About to extract 144 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 144; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (144 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿRÓ] ¼}•ÀJFœÄÿ.»á_jÏö€¸ú¯ˆ°ÏÛîCPméÁòqêÅoú İ—;óšR$qN)~÷Ê1òå$ÕRm…\o\¸fªP)b«³ø_FÅ·ğŸùoñ0(-ñîÆ¦Ü	¬‘ÆOùíMëDˆÓr„´ËÚ‰Ê:äŠl˜–G½šT ıAl;óO‡W³•Uì”Ã/ç™.}¾
¼MÃÕXèR½ú3¸¥ulqVâ„-½u –cÄ(¾ñûÂ„•'S&J«şV³4>Æ0¿@Â”¦è"è p=˜˜Kÿşcª“4Èfu7¹•7‘ö²K?J}YoyM%7xF#æ…åÊ2>zÃ4„¯^&Úí{ùÆrkŸWıŒ!(gúvğ¢“?cú‚	ŸYë]À.»!dyº‰*îü´»\ìÃ‹¬L2h”~Ã8´ß‡ÈLˆòo¤ü ‡¨‚áôagIVq•É”N”q…PyÖB‰Kz9Ò€1ÁÒË7ø`ôÅì‹x÷çÎ¯ó…‘^mÿ¤L&Cs•ÊÄŸc)&ÿeà t8–)ŸéÛ­ˆi4îNä}h	  ‡E#•­ÒØ¶†ÃEÔù}ú,zmIÒ¦òb>D:aïÿDûo¡–sÿ§¾?^D®¬éó­Ù„ÅEÏÓ~UÌ5[Ú²Øğ¾
H Q˜ÙÈ³Î	­Q^;|Œáç÷ªIŞfCuó'éxAeÕiã˜{×Ë¸™Æù¿ëÑ_C‰ØªX®öSâµcë§‘‘û¨éã1Ë¨jÕŠd#.I$%whÊ]CsÁ…Áç=&Vğ#œYi«
„VœÉ$iã+mbDÂÛÇİ‡¤¹ÿÃ^Õ\DgÙ	|º„ør¡_:%Gvã½¸OŞ"æ#jÑjeè×Rê±B,O¾S:ĞG1|	Ã noò=$„+À’‰4^à{7Å=p!ê=÷[#l‘§@JÄqÓÇ´ET\§êVQ½`oƒÙå>mL(¶a…B,ôawòvqA wõ"jó¢œm›Õö$‰Ó(Ã;Ù[¥`'0‹aU{}^!¿2sâÍ„¿:?ˆS~HÙkx’áŸ~jo>+i$ØÎ13=&u~j…X¾Fá¶ÉA}Áı&´ÔCúo‘A&¶LKÑüòÇŒô…Yôãˆ@Œ¶Î>°gvÿßJ«Å|ÿ¢%bÿAöá’<—Ø s…¦t€9J}€"™&*îó>*·ÁÂyšå«(!a¡¹…ÙŒhpodDh-XÈÜ!Ÿpµ‹I4€gpY½NLz%3Cğ¬k¥¶‘q~š,ZÔK„ˆÁÒğÅÃœ¬ŞE˜şàö67éjÓçñæ<*!W¦˜’»(A~`X2-ØÖmòÕÒ±—ºµœÑÿ«Êè_"½PÇU·ñGhf9h=¿ÊŞã ì.íRÄgjD!ò°nYrÜâ#vK¸Ô}Öb±[as¹3:„¾fj‚¥‡€Ï!Úÿ5;³á‚wŸéÊ¾0òöš¬•»|µ7³RÖœˆ#J)ğöU
©lr?È­Ø6Û¹ï|UîAéµG—ë}ÔhšÜÉ;y‚`
•Ç6ìê¿ÏËw{´/ÔÆ01z9‘w+‚l÷‡	VOÒ\’Å-FDÀk\¡ù´óry+sl‡çŸ0¹%é<°G(õÌbaÔ€ãB't£UÜ4ü2ù½ò–_

(+9;À­¢*‡Øÿíú10bß¡üm¯Ì+ËÄ¬xQîeR°æx•+äÏ4 †kSÿY-½EáÜÛ©•ÿó}Ë‹´£Zô@ğL-(Ì
+äÍÈ#<\²\OŠ6ôèÀZ)gÇªŸO¸Hˆ?Ée„êÆE¬–Ù1ŒQ¨<·h…øI®€Åzo|EÓòY×§–ğÁã6³èPFPoX$¬ZÆé`hatdøÎz¼Ú4N»9^&ó…¾§}qK¼?’Í~”BIjâ¨±})<¬Î99µı.°øéÄ|„Q ùå=ïuVi.‘aHYù™ş·çúuˆD:Xâß]Qê¿Ş`Ù¹Ú–xÎxkD´¿bÁäÅ­±L Ä_@”c¶TQ-`ŞS5Ú^şN&F˜àkêã¡@kmK2«˜EÊ½K½QÉID¬ I£n¼§ÙYèâĞŸÏ#KèiW¿ jÛNm8õüÄUôïŸiNå¦Ú³–‹«$«:niâ#üêŠ)J‰sÖ€/†t©¹¶^æöÕ–Æ6àyë­½hj_Z$]Ç¯yuFÏ(§÷äNQtIMİ?Õ×bÎš¼^0¾‹~9oÓ‹˜Auú:ü^0Ú×ãña‡mÚMN:¿6Ñ"¬J6šíÖÍU˜l‚oØ"£.t2 ®I^ÊpºídŞ&iÃ‡1üÌªûÑ¤á8=/WÅVÆ
Ê›laX0,Deœƒ¶Ÿ[@0<|@Qiæ,ÊKˆ,GÙ‡¡r”¾ñƒTø²XF1N<6*ˆ­;fPÙÇ^bg(RØËÑ›®-N®P×Å—m‚Ôeõÿ ‹b²%[“Á=ÒRü^$Ïô‘2~cO\Ç¾/„}3Pi´“ãÈk‚E¢R¹ ÀÇŠ¿2„\X¦“/TáNê~Ú'Æ…_“v¶Z¾õı:ùË_ÇI6ãy[uí€”:ÑÀÊgÈğP"YÉ
‹l}N¤ˆ·Ñg½øl+ù;×Œ6i©Æ–ß£ÀÔ³ïêRn~·£v7i•Ÿ_$9ğIkœàÆ:Üâú çõ¯Ní˜A…}ÁI¢³*€¿W>Ù.Nîö†!üpÆ¨KU@ø±¯éTwC;ŠŸî˜“¹¢|N;è+È /›UŸÿ÷Ô	Â¬á¯ãà¤ˆ`MM#¸ºÙ:LÆfoŠí†ôÉ†L¿gÕ£°¬#Á_sŒ=Ón ÿ2ã†$ Ó…Ê©ÓĞ‡as…îhuŠvÔ§Šùãæñšåw£õ1;)a,¢Ù(Éb—ÿ=°j¢ëmQ8ÏXXRv¯}¸¤İ sÏVßßFÅvÀµÖ¼ÿ Ş;.1(0w’½²©¡ŒìüFjØ*•aËTÒú(¤,+LŒ›a–Á#èX­®ô4}|¯ğ•‹¨wálUb]ŠÁÌo*°@Jğƒkëîu@)öF»¬v~ÒÍÖ¦„!%/3›?§gÌ%òØµÍO]Ê­şÆ#‡ƒrÈÓœÏ6)Šªôl+ ½	" )>N[ò bÅ¨ã¨ï£GV-¢ä(çÆ"»6â
†ŠYïT‡¼İ½üÉe`˜şÎ1^1¸æÂÇ2ANzØtğ*~è‡ÈŠÆÿß´p†ó„ş™h£¤`Ğ˜áMƒW$ÓÚÌénƒKño^›kˆêñ›ò«ˆ„°ûàâ¿Ô*N…Ì7çˆiuwƒ¡›	³[Éì2
ŠÕ‡çÜ½çªa²qŞÓÄ"ÙŞÔmr½Ÿ›ß¤é—_+´vJ±^Ãav.Âëï!“}d{h‘D{»Gó ¡«ÍßIÁÈ'(ªÅ(ñ\YŸXÀåQÙ¥M–ØG¾™gr0¿AwĞã}Ìb}f½#ÛWî…ÆÅù®%ù„ÅµÑiŸ¬òÍNvI²¨şƒÕÅ¡}lµëÁÚ¯ÿî××·>³`3ÛgW±¿`Lì´n¸•Ù
Ng Ó°©}BO»°mt$ûÒ… m¬N4Áë‘„¸=›®^NªÈoÅK@õkœ³ ‘¸n8&3àü@%”Ò]²m7Ït©ê¤˜¡‚öäùôJì;~=Äàdùöøâµ8“,(MÇ¥•¯ïÀL¡tî‰Ç5aÁ;}“R	ÀÇuöòúÂîñhÏ{'!ÿ’
ìş§uÅÇ…¡."²Ò$æ(ŸLİ;á… t]RºÁxÌJ{â® `[_Íc)#‹µ¥PCíº¥$üíçÉoâ8wÁ?Óˆ£*ùZÊS×c!J€›š´öROB%-Ì$[!raæÿÌÚQÑ„ˆæ µeòêòµãİÄğÌÈÜBâ‚V"fh`qšê³ÄûŠ¸bß"Æ,¨çáò¼FÚÏ†¢èijÈØ“GÛD{n’¦¶Œ¯j´-IQ ì&ä#_;Ù8ÉäÔ*¼˜ƒİñ;,A4ŸòBØ~?‰Ö8Òç¾„(ËH7¥²d©Ê2´.€Àku|o÷,Y)În÷+ê> –mËæ¹6ÅF}x:qÎ´‘ı:!¦¡,VêáÅjã #¿Ø‹½ø°4Y¾RrT¿rê¢ö:ó“Èq½h|i>ß	<WEïh_qÙNì¿\µF`Jd³eWê	o½ÏÄ=‰jÌ¢¿¼—ôP]f×(tÔl;K°|äè¶ÊÔ•uôƒëé»Æ
eŠtZ›\]RdFûÍK.ì5/ìÊ¹ı£lş~epµ/tZ¢×H¢ˆ“>ní±¿‡F?Î(…ºWç9a°¿Nî,Şò0:Âj-]Rn²¦ÊÑ£j’K°¬wF×zŒe;?j£ùf7"ë†ã«†E¡¦ö¿ß…P¨ı~dä5³Huej‘¦¹*X*8›niO”ªuíñgôæ6tHîÂKÚ\t“Ó´Ûp:¿/}üU5AÁA;0;¼]êQŒñ?fÜÚ=¾DšŸ	Š^8Ò)OÕ#ğm

Ö‚LÄç!ÒœÍ¤¯Œ‡ÁÇÄœh×Ã¥¶uÕîèä0Úš°Şée!ìÌDfİRa¥/:g†3‰û!‘Óß(OáEp¾«Ö\¢Ë¶Vx,&1«ÒtŞñıâ‹°ëF?ÖgkícÈ£„®YZÆ˜dºEãJÀñç´Œ´‘,Û§£ÕlŒÑWCtC}2ˆ§Ú3r€ùÆO.SÁÄ)È_†p"« †‘ÊœV/­w…°¿³9 ;Ï®Ì\:ÒÎ@BB€DuèÕ5UÄ£Q™ŒN³Y¶û÷y»š®¥Â¯í.C§~ñIHıÒWd¬TœOôq6L3ïò}9­:àIÔlú×)¥PSŸå†vÈë÷Á×.QHŒĞÌzD2­u-BáÜ¸œxÜéå'>éüı[…j‹™· Æk&¦zÉ¿±É ÒÿVÃæÚöóÔ7	pƒ« ]z˜’:·/{M‡h´¯iDÜv¸ÕÙ¬[ÈÑFJ¿î¯•@¾”5,ÕÚK¼mWF+íjÁ¢h8ß|q}ñB¬OÛ¢%5EFpØj*uo”¹Å«‡QZ`¨o·¡;9Aîÿ™ÊzÕ.¬œè	&ë¢)]+»ëL-{JÈyÑG9<rE„H°'ĞšvÉdÖ)8üÅÅ=6öàà–„.s¶ú¦dô²&&TÂ¶œDçÓ59 *¬ ExTÕì G¶Kl®ìx¦Òtğ¢ò³nì‚Sı£¡>6Ô¶A¦ô_ìcó|áÊë µ‡`sF³şúRô#¿Ok³tx{{ä×ßâÉ8w@†æ”+ÔL@şk-ƒQ&AèÀ†5êJNçñi1]šö…XWSÃ½àÁKşô2‚"*+¥Û€;0ŞBP¸ì—¯óo$PeŸ›)v ˜:sí»ı ÿñC—!`G¸|^ÌËãâI}cÇ;\ˆz‘FA7~ø`Ç¨]{:]Ë5­N]šùß_Å>9-Ã”FgÿåĞLAôí˜à&O$`ûâQMØ89°‚°´FIô@`«‡aôÈL?á³ÕFšZ™-Dæâ>Âµ—:¿OÁŠÿfs& 9Îl»QŸ+/­ğÉ_=]ñŠUTÊòøáuÈ|Ú¸r×$_–ÕL¶Zò÷D#µÈMÉ ;ÉSí­¡wy³
 ÉG”¬ƒ}’°¤˜ğ&¼ÿ
‘\M'ÀIì–Ş€×Î
.Cx°‚{—ÙD¥ÿèY<°‡ĞrÎº2qì%Xé²êoÉ^Ï©2ì py+ÇCªRß@¶MÒX}^L
N€Ÿ8lãs¶—é°@®¡ê†>p+€Td•wÉ)Òa İ¹ã6 "öQ-j ¼qCÆU61„3Ììÿ¨újbß&^Z_^K	˜DÃXôp?Un·*@%ìisôo_!É„!? Kš³+øp@wj¯¦ çQË`'œ«¢Ÿ’`I¡±Ò’œ	b>§†½=ç M%·}ryş•:?Öœ*‹vĞlÅ×Ğ]<[5%­a‹ÅHæâ`ë;Ê>7 ÕX-¬·*†æQÃd+[ÀCÈæ±k7kk‰o³¼í¬làFÖG·Î¤¹˜ªñİ0²ŒÎLÅö<³8´eì-Â‹ä-×¢U#Üè»n,›®÷AÕë<]ùÑ]àbÎ)×òùG‚ôg©]¾íªh`«ïL¿û·IÇÿÙ[Ò!¢q­WˆD´zzü³†cÌ" ¿ÌOx‹Æâ'àgÄÙ÷^Çªwh#_XÌ±¤şFß”¯-îiBtQĞLZ×¸,i€ÓÆèpfM{º½ò@RfÕì,[E¶iWŸä/uWO—.‘ƒæ£œí~ún"M¹Ôhâ?©pÕÃ‹oµ¶íªoQ­pÛä0¨Â·s”XÀèû¤‘İju!IßVóì›Õ²¨Ç\zÃËÜˆ­^–:2ÎcİM ‘–7¶Ê7‰» ‘êKyï>Y†ârÔ–2È¶ïª¹uQÉƒ¸šÍ\ù=ññOæ’Ï˜–¤9år·S?Äyã\Î¾±ÜÔåj®‡İWSqÏzBÖ4ô´A‹âÙÂÇÅ;œš
XçåõÀ
øíÿ{p|•já-ÕEn.•Ğ#wêŒ“Zo6œ¡oßvqF”ùk!LKŸk_IûYÓ¹µ‹£c^mF4~“H›á½{N\™NVÒ5óş<t+ÌLx8¼œ,×ÖuÉõUtİW»Ñ¿‘Wşí€zôÂt“,–0 ‡i7Ç5kóÏ	3ï%Ée¹õp·«mÿÂ@šç¯lâuûttğÔ–mú]Ó¶O¨ûÑtCş]ğ…eEæ>²µjIË/<§¸›=‹qeıáÕøÂ]Y†Å]ê	1`%¼¼æÆ°¸H8ÉHû
ıO?ê$Àvè®4+gùSĞs{Ñ
ıĞ°±ºãŠ\±Nµ,y'mæh@¬øûı<©wğXA,m‹“¤çİvm´²DO³*½¼1²•é]v¤ê¦–y|`Áò=ÚŞ*¨À÷™ø4†hÆíşLgKá×Ş—º¦Ø>cÿÌc`øûo(Ó6 ıë¶°V?N^ggqÅLígÙ&´fsxá.ê
2$Ê¸_İ"yB˜Ì¼œ9^f$[óÏ¼ˆ)©1"¿ÛÑVR
Î¦…”÷KÉÕäu(iÑ
2şñßxĞË
'Ü>E®eB® Y?'€‹ÿ¹óÜÂ-Ô%ÂŸwù‰ætW†|Jl†ü-LÚÏ2²Ñï¸šÊçĞÑE´jêËÆQ'ìˆ|]7ŞÈ÷‹3£øg†Œ&İÎUÊ8ÓcŸ¯üÎ ÚPùgÁ‚öYìÿÈ+¯@.[ò®—¬ë? ^ıÏbó­Œ?È²L‚®:Q
Ø¢£9l4iy›½›èç—^O…¼³!m—K|<š€Ÿuxq^><‚fñ ÷]¬i=ğÓá]¤’ñ¨g¹Ñ…«À»L´NuŠvzË›†Û iaz­ŞLÔ¬FVf‚v9´ãÏGzªßİ‘|Ï	¢rŸØG%ÖÁóâÃ³€
\üı D”¾X®»œd‚¼Ï& ¡öoªúÎ*Ô%÷¤­·»ßM?JÂ3¨_LE='û=3,?UVÛ*5EİŞ†ìÙÛl;’÷'Ò…À£Lê'Q;Ënº²ò½ÒÌ®ôÛ½˜09£ê?Ä}zÁä¦îK†ñyÌ	+è³‹kY‰Oˆ7ûK';BŞ¶b]İç€¢¿²ÀuM/İó,Á^)=LšÖ5KüWÄé4øÈ{ßĞ=ºı˜¡)^úÀ;ˆ)áú¤"[«Ù-á´|v&Ê±{ª”Ì¦ŞI\á#®§ü2ÄgD0š3 ~3B"ËSËıÏëRò„êûõF°êIOòò„#î4±$ödÙnkMÈ¬I0"î´ˆ&ÆhåùıÖŞÎyõå ø@’‹Ä4c¶¾‡{v{Äw…WMşiÚëìôJÿú¿|qÚnAÄ`š„Ï,#7“2ön[îùaÙéœ#¥ºè5ÀJºöÀD›óğæ\0„Ó›Ş7=“ïì/{½éıbW©A|ÂÒ`ËF¡[ÄêVOµ¼q€¶KR0K±”Ù”ØÈØàÇq€¢õş¹óN&Ø àx©"®i”ı×íç‚/ÄZ¹Y	Ä™Ğ9¦CëÈ#d±8;.‰Yåœà”>Õ½rdŸ5)&çX­Î2ƒ¿Õ—çÓx-ä3d%¦c?ûo.²4i <Ù“,6Û!:Ú¥–{kÙœ$sÁ,9¸ó@rA®Œ<'Å>¤ ØIe¾ãF¾pXÊŒ¿s,ÁrÕÖæQV*†
‰³’ó6*ê,;e³Şi{šÙ·ûY*³å®½“!‚UÑP(MˆTí¨ÖŠPRÑìPOûxóg0“èa˜ó%'û& aŸ­¶nyğ­#ÒKL†ñ7Ø¯[“¸¾“cH4¸Lç…)è
lB»<«çìš¦³Ra7bÀ‰!E‚SS¥EÙ­ŠwÎ{&¦  õÏ_N{C =T.ŞLË¨¡<î§Lg9§ñ·V…
:uK¯§Óc‚Î4,t^È ’¦ Î+ÄÇÑÉı‹LZ¼G[Xª¢È©ÓïÎ½™¾¹›uk!|
éyÛÕ=ôè	%´îLTJ¡ªi8ššX¬¿9B:nÀZìŞX9öF¥epp×(d©u/Ój­„o?vnÌâ}h·"}¾Â‹ÖçŞ}C¯u°£é*Ø®Ï1xawt2X²<€úğâ¥‡+ô;´})¡şQÔâSa½·o%J’Ôü#}Îãm rxFUÕÓ™[Ó‚h±…ğ€4/ø^q°G‡L®!»%'İëDy?ÕêûÂÕç©Q‹ÇVd‹(poT[æ¬Æ(˜á@“Yæ?´†¿ÏY@7(Æ´F7Û!ğµT“!ûa”ëH8&A°fÁ[‘Øq—c­<îÏ’kK%	3ÈEå€çÕ DôtDÁ^J‚ôTHDgâÙ˜¼SJƒ¢ƒÓvI»óë%ÓÂĞå¨Ğ³+Äî¿•«–kP9Ğp±a·ÛÍÊò¹õ¾<È	’K¦.Ø(Ûã÷¤¨¢,¾(Ã$„(g¼ÆÉÿaô"ëÑø>=ïş«²	}*©™XrQIÙZœÍWY¨¢Î¢eÌ|´$¦~§¤ñçÛ´¥|ª ¸¦ÈxŸ4Î[¤ÔÒ Meî€´“´"äÿãiÃ½ŸÁ2cŞ½(æ¯
S¶Ëœ¹Æs“	4>£V¶oÒPI¹¨·¥(bÀ"o}ª¸ÈhN¥’&/y¿º¯¼ø²J‡«à™Mè›™b¶]¨·Ö'êË×y5šD	J»Ä‚n ©|ÇAº¼(j­Ç7
%Óİô¸6Ê§À+Øüíñ#¦¼c‚Ê~‹ë„ª0ë<Êüm`ºç¨ö BI³P²Œ‚Ëdœ†‹ëH±Í"æÉ½rï,­Ôy4‚‚„*k0ELôÃ@½½ŒŸÕ!“Û*‚ñÄÍKW)nÏ¸Kz(]…À…iŠM(ñk¦fñ÷qå¦TQÊŠ‰‘‘¶»ªj¨ã L2äT¸WøHÜÄæ¬Åh ƒ—˜_)ÀÉYcÖ6Ôú×®îƒ67Ü¨`ÆĞ —–7¨$X§>< Î‚ˆÎŠ}»Û›2m}Í:Ã—/}zkôÚ¯~ã=\Àd’çÄ±ÓarÓ¿l2v\Iœû˜ã!¥[bVwK*D‚tKdü­¦´¸ÑÛœÿLZ˜béÅA²í£LOáQtïœ'–p´@TÖæÄ±5™â<¿¤jóŒÛkÆDq¾ÿ¢C?Ğ”ÃÛâYtí›5Da¦ ùuÑjqnLr:¼u÷ÖŸ¦pÏBò_v<è‰!G>õj-MÖOÄª6—Í—îòÁ•%²Ëo‚¤/›¹ÙÑAc¾\Ì‘ÇoÅ\L\áí¤Ã7Ğó¯ºaøšó§Æ24æÿJ.ûäË7€ÅHÁ£ƒ#ƒ]ìÙæ¶qaê°,`ßXæ“kÑÄ¼õ`t0õ‹Ìíùµ‹Ğwºë>:Í<Âœ»f`¸m4çJ*a|›‘`Q‰ªŒY×Åµ?ª„ìeë¼+Œ2É¶—ˆ1õ¯ØP¶L1©nÙ£~éÏÆëÏ’ÌÿÃ“8kMÛîá#ï¥›Àm®z±“ßƒq¶šìPV=è·ªEßu%Ï^ùü–Í•€Æ™ôĞ¸õr¬h©hª:ı_³“]˜ìXìP¡LMëAŠwUc@ğ\=+ [†Ä´¼h>”•;€¼_‚VØé(R²m4&Ô`÷;HAJç6¡)½·>?)Š¿Ö3ÙKåC%8z04‡®ıŒ#uOUJ8ñÊÅ¶¾=AÒÄ\Éì±„ÌV;
F$à'Ë¢0Øˆ;˜Y‡Ÿê…$‰cF¢h£éÓª7j‘à»à*qNO8åİs·u¤û_A¢ÕĞÈ|´Èÿ¡x%³­PõÆŞcqñyßâ$IÊº ÍOÂyõÎÓ&xÄ•øIØæH¯éœìÁ#O„ğÂjÕVNÌ]4…l×iŒÚ±c‹Û&¶,\Œ%¯–è¤£YWbğéS<´AÉë1nO*Í0T%‹F}Œ	\Ãáe@¸vL°D‰Ö:æÍ>£û˜OÜ‚O¸#Â	t‚ÔDFİRmh7Ë}qã]Këwd[mÅrá3P¬ TY—EÎqÅÍZÆSq¦bmwb1A
Šj&ŞsDOhÜènÂ®…Qáâş/¦ÍjN€¯Íú;°&Ëa+fDs6€îƒÅv½ ŠÄJ8th#WÓÜ^ |Cçø­—H$æùª`×¥zÛáÄi±a Ûrf–QÁÓÿYÍ`#	"@Fûq—:¡s"ƒ>2Â‘¼‹Kñ“~}¸:¾WÁHÎ­!å³ÛÂ‹ OĞ¶_¹¼xµAD(Ï´êğog:¼ÜNuEÓ>¶3n+{ƒ£hNmÃÊñ‚×6»Y:E¹xK0¿¬ìX²¹ ×x;òæ­íø9bĞQÕÿ?ÅŸÔ$kŒ¯nQq.7ÏüÖf¢ùû.,­&]™¯a¸?ù^Šfaô7<åØH%ZõiÇ7¥Ãˆ¾-kñ§Úy>ËæÊßéÀê}=2OÃ\J±Ù,>»>ì…5dHµVJÕ§@†×`l·&&X1ê´îo¡tBğ¤¹èfÍ£ÚGS5½aV]™ª§¼çq{Ü!#~¿äŞ¶E'o}Ë)Ş½Jú?ååà1«–­‡¡õ|ØÀ¸—vğM ¥ª¶YÁ7ÓCş)GøbÌ‚èİÖÅïr®…ÛÆw¡îA7ÛT³/^]NÊğ£ˆytl÷ÓÂF%Ê)…Hëm¼·lvWõ†ğÖ¨¿[Ø[•O@zóV”¤s{:ZEŠÿJ]_•îo>xÇ5°œ*_H!cÀb ÁWŒ#¤±e<=¡ÎØ:¿Lò	Bª öã¢¯’¼¶Oö-âAØocáGò³·Áá´ªFÊuÌ„ExTS
yVv¶j«¬ód’‹ùg;ñbµİÚÀ%¾¶ÙQ¹cĞ§ÚéæÉ¥ñé‚áÓKhu2ã)Îtï´?ÜÆ‰L[P4ãwu½É¤Õ›Q2=ò’F Ì°uÄ ùú„QnÏ¨ËIĞË}%«‘µ­*%ôDMúò8á{Õ$bû¡‹\‰]±¿™„tv|8“¸°ü~J`îêilâákêQ®³õÓcFîß™Q=\ûÿ^šÀ¿?CÀ¤”±Ñ„ÈB8ËDóh™¾w€‹9j,d$o’úéTÊHãx¬]¹KëH?köí¢“eÄÀƒnëm7Š~LÚâÉÄ„l²¬£†ÇŸ\,S&1tX-£ß±aMwâ¡É…Ç3]äTF·²JÖ¦~yôj×i³Ús¼½â±E+L¸ÆØÊMœ»"Ğ‘gaIøÎ§²á7¢Û·pŠ¾;>*¦ô•ĞáY±ù³; ÌÓ6m±h&/µ°¯–CXİêŠJÅv°g(Û#_lì†‹á"vUôĞxÑäÚÃÙÒu'Øgø{òÀõF©>Jt©Åeì”„Ã„©0(xå2W® ‹ô"ß-¾]G7&Šìğ}ı{@zëÆašõ3’ŒÊĞmo#|±¶è8‚P¨“5aùúa^‚W=]ê“ÊM†³Bp:­Öñ²Ê¬ÕM¾n¥› 3`°‘Lt‡!7[rvUø…ŠÔ	 ÇêØÕj;¤İÑ¬¢-x~”QoRb¶$‹£M£û8‹UÀÆï¥-ÙTÌÑ~^ıŞçñ\Zù`ßë  ıxÄ˜Ç«1êÅ±©é3T°_)ÂKy+yføĞQåL½
ìÃ:!ú(/`×w¾Mb°ÄWTÄ©šsÅ‰BË!Ó×xÓJ”~–qM’ÌOçé±x'á‚*¦„óëš©rªÖ ¿Ôışáõ9eõ¼?&}÷Oº–<ÿ3&„}¹µ Ù\¸í»B7Ïá˜‹E¶°.ëì1½·qºHBPnçø6dóO–ilÀ»H¡XG™o˜ÿ |‚£°¶f¥ûìygÒÚ¯—_°~MA~^¥ñoA’»Bxnók£Á;ûû…î«»`8²¯ûÂw·ÛJş8‡úãk2Ëg‰4ÉâªvÎyáç+â«ŠL#7
¾W ×yE÷)O‹Wbù5î¿à]–4½¨^¡|Ñävwc÷X,ÂÍch·´›ÿg·-gµc‘Ú,ˆ<zîKj”àM³®×=¿Øj¬ÚNÂ©Ñp}B íÔì„1f/ëÿã,q™Ct±áI.5¾ÂBğZW1ööX}+ÂÚY‰/Ùä{vÚ†h	pİCvlÚÍÂ"ñ.êYñ¥ú‹qL‰s?¿p$‰C5~ê!ä´7—Ç÷€C¥êhc,i©ãëµÂ.·(½o‚<1S\FŸG˜Öd9¿Œ5€	!Š¸·›ÑÀ©à£lŸûóä@ ƒTyö‘¨õ8õb²>äo'u7”‹“Ş_"‰0Ø å*
¡ô‚»9	Î€ÀQåCŒt•	•DäDLvMÕJ€7Öøì$©PhŠÍ7ùH6‹)³ôşÄP‰(IæG¹¤GœE8YØ†¦åÁ«ãúG!Á†¯ROj„?²¿z2UD
¤0ı3S:Úµ×+˜kÜ…ÊÇ{©XMqNˆKw¼°æ•N£M_r†‰Íõ˜ú*vÔYñõ¤
¹ªv„£ªi{Â<^ãŸ‰¡Éøi%LI÷Û”$ô™ÑA†ñúù4ZÜâ‘ÏxdO¶~vÁF\ÜVª¨½Ê‚í‘„MñÄæè˜½¥§uH¾jCä„wç tò:…­Ù%;Õ^G§bGeoá¦ÙNFİK\‚©ÿTìa5iº„Ñ¾/ŠÊhS9Û+ÊMŸ!Ì‡§9^7Q«Õƒ‰FFŠÕË„,&r»æø—#*Ï;ÿ?ÚŸç@LééS™&V»îûLS±gˆÎí5Æ’¼—N4Ê,ŒçÒ>áRÏÊœt×¥”h"ãT˜¿‚©&ãe¹‰*Ğ"!k€ÂÑ&bH{&.xdĞy·k0ŠHâÑñZ`aBgcFÏ 	ËŞÂõ|iÈâƒîÁ¼1ˆT4Q>Ó÷Jd;gfô~vu`$™({
sT.¿zé×'®n©~í:‹)w¯Iß'»Jµí0Šå•ıgvûŸäÓ(éóÖ÷áÄŞFïu”x “BÂóÙÅB‰zD^Jœ²-rù©>B÷É_%].§s°Â¥àXj’Ù`©Ì×TæGÚ3o\ŸæiÓN-¾ÃİÆ6k‹Öîé©Ü
 I"„ií™Wß'a÷•EÅËØñÌ½f·Ï3ÜLGùYOt¯ì>Åú™ùœ¢äÇ>ñÜ¸l„1rêé"µ75_üi6´VIE$»ŸbşŞğÖÑ¹óq‘ª0‹Tª*I‡Ş½ü.¶}õVrrúéÊO±¢‡˜9çIyÖ_{#A‹Ï}/¢¶±ÛA]Ã.Ï_T3sš÷Á&ˆ›Úêw‰É“äKv@
KO,<>ë‹iãù„w‡çaRHL_“ŒÙeN‚u,V–”Fl’gM!±â•ßigCÃhrm´åTj ”¢–±¿;£ßo·ƒ¯ÅDP>ö´+æ‡sLş“s:6
6pôZùHülášõğŸ’‘éAƒÀ°¤îßâNÁ{¼zù›Í3>/a« O‰0ÒM,@_´–+¸ ä¿0Œî:gƒçoÁå‰¢¢ÒÙ6ßsğ²¦°"À‰½Y2öDlmÓã»’îOáÖòÃc‹O‚ W¶X®ØG@†…„©ïûÜU‰G²ƒŒî›fó†‚ Œê-¨°E\R†xÎ7ËR¸ã>W§rôôNà‚uß…®*Ÿo¯æm÷a9j	ÅÏÓÁ¾×æ²	0Åìşî‹şp^§Ïæ~´ÀàÛ×}´M½|ì›`x{»1bÚ?tv«T4˜?\cÓÂÎ‹õû¿iİã­G‰¯/jõe	ÃÉ†GöÍrÅ>#l {‘Hpl5ùR+@şXh ı±^|¸­Š7³tVpŞ*xù!€"ÂÄfíHl'Í¨Hn˜BÖ^˜ş*Â™T`,ÅHÖôHÅ6'„Õ„$ƒŠ‚–©ŞÊ–"ë¤U¡ÀXİIL«îÒUı ÅúP4õl²ãÄAßVÖ]+
çeRÄ[Jb›İë,Eø’^°ùZR®«™– ÓßÄF÷ï©"+Lw\	œL^Ì³G7UükmÿtœÏôÿÃ¨¨=Ñ–.ƒ> Éš©
î\‡eµÕg†Hc!ÖÛMæ_L]È­/=yÙGÇr¥o­š<|Çif
}ˆy##=÷oTõşa•ıËSˆJ´?ëŞ“4¡ÌãØmz=·æä0–Vh²Ë©‰s§cæI¶õh•Û_“uŞæÓKh+™~še0Şzï¥è‹ïÌv]ñ?0ãÛ,Ğ9êŸ_8ï€¸TŞ|öŒõi³*©}¥#bAtZ®•«¹?&ÂA£”#& çê'd'2ú7èÍ³‘€ú:ÙehÅ‰l¾ûŞÚè[Y 0ÒJ1bªn{¡ûWd¼sø>ôùÏÕÄî?–cé $í¯[ñ†§ËİYMÒ†LŠe{{Çnµ„˜cxëåòÒq»ş.Òå]ÏÈÅ&t$‡
•ÓËŸ++ˆª„˜ã˜‚%g¼j´AâÈÔ.zÅ+'½'×aD,pâ*¿Ã¬ˆÑyˆ¤Q^ˆ²šìVÊŞÙ¨ß«öÎ¤^#y
EoR½‚ıœ´‰¯ú6ÁO°R#„h)‚ï-¾ÕvÚnŸC…Ñ‚¹ñv¯¶>v _ÃD×â^­±]úşĞœ['îœL;dZü ïT£rÑ¸¶Ş-‰±•\G¢X)~¸¹uerKºS“ŒG÷œ+Z¬JIb¨onÁ§•Æ 1Ã õHšP?·#dV×Ø…3õ™¯Î+ŞKu«‘ÔÍ˜ñ„
£…j £‘ì†¯ÿÊCF9Ç­ÈÓág4fG“hšjGìÓì™Æï”ÎzOrçù.²À•ƒ „J(
~Çü¬Ÿ\ÅÃŞªƒé´óhû’¢Ó
`ŞÍú£*í+d~;#B~D Ä„—Ì×.šÑ#0‚—şœ†«Íõñ;˜d|õŸãDÿğ*
¤ñ.ÿ=údÖ&ÿØ¯€Kmšl‹Ú/ĞÜ–ÊHç¶^Ï|3¨ÚÁÅ”
{ ı0Bq2©Ê&¢Ò˜*†>ïéìúZË¾‹^ ~“™7Ù£Ø¿û½1$‚ŠD®Ahá +wÅùíêaÏ*"Ë8tK›Îé¶^çw…ğ½³Ì»7Ô+L¼OêL–¸ƒıEo#ƒbÍˆGzgÈX®º’ŸÖÁ>sÈ=~Ş½É“uøfP¾¸½ŸÊ¬>JxJ„U‡¥=Õàw²‚˜ÏEÅZ7„7¤â•5
‚Ì¤h·4!yvÁÑ„û˜˜x0tÈ&B5$5RpÑøå{“àhBrŠŠ%15¼êİ
ŸÏ§ßwÃh¤’–NBÁd’HZÂB#a›[RèŸ¦¸­à_»¨ºsn|“™	i6©‰H€e¯»á×îŠÈœÆî£i¿6Î¼fØšLï2/ÏDS­Ø*oÑíÅáõ—r-NÃ'ß+Í°ã¨¿è'ÄÁê9 ,%-.Lm>ŞÒ•ù„‘Ê±¦«”€cÔIõ<±<ÁÚ¿¤–šã“‡‹U›6rä6ßçö/şiÏ%nxR¥D òú'#e6¾-#+dŒ=ÙcÙ&C%š:;	4pöli{°¸[–Ì`÷º¿GÅÛú1Ò6l†{
lïƒæµ7e¡ 'Ã$EÙ£ùm×”VM‘xÃr%œ4–nıCÔ×!AZSbUËAá[÷Z6ëVéE™Á¥32h;¤'Ş((ÅƒMhCd¨O=ÒË:háY ÑQü“UDïD…ÉßÜ^Æş&ĞæÂÎ¥:>ƒƒ	²œN†å@NkÖDófÎ™§/9“ÿ€Él¨FÉÁ]ÇÛ;×ß3NÕ©ºnhÄ¹3?«z¦ÃcÔÉ’SX'ìÿUB“ë¯¥ÏBª.9ÚÒ©³)ÖT]½÷cĞÄçú?´¼×'Zt?ø¼÷})o¡#okilZìúÓ×fx¾ÕjX3n¦íà–4ü+©Ø³ÛyõˆËLfù›Î¬‘şmVÙ¨ŒÔöLàÕ_…ŠxÁùX¬ÀÆ zÉü–‰\d.¹,<Ì¤sSü¥®¿«4
~¸‚+B ‘à\}ÈİôQ‹ÇæœÔ±±0Ğ¤¾>ëÛ'‚íÑ ¤ÆŞà a2ÜN,„
’ÔÏëÛQk.OrR²³  ®öR¼%áõå»¢àÍ.P®Sî´Ø}å :¹Ğ;¦¸1­ËùâÉ{‚Qu•˜´•Óºp‚íY!Gš¤°ßAk´P2f¤„6y³¢Î,S0Ë‡ÙöDõ]µNŸˆ'šH9JODµéÌpu\ÓßèAÒ?ÕfÌš¬ŠEø2¡-²Ç‚ß¶Ñè|^í0‰;@PŞayƒUÄHYR)¾Ñ)4Øfèè‰~NBKÜš„	3~F¼¯vúz½Ğú]oWFùd_gå´’“lìCO,*¬:†Ü»™ó!ùÉHÏ£fÄĞlì1†ååhÔ%ÒÇPg”å½7cT¥‰Bªìä{Æã¥ì®¼b?Ob!q·¦­-ËĞ"8$…‚cBg¯. t®2 Ä“L/<T2T‚ÿö§èW~Á°ŸLÃ­…8as;µÊƒ³–a¸,¥í
ŠÎ'èSR£TåZRIç[aoĞª­´‰î:8ëÎ°X·ş• 9ê»+X­’Gš÷ ûÿµúqPx,b:UæÂ ä:/irn‚Ìæq7lXâ¸<É¤ëÄHİh¹›$òf¹”Å.pŸl^3Ìç„»ê6Œùq/íÛƒÍm½¥e)!‹fÊ^ş ‹`ø·ÇEpAÅ¸ólTk5K±<!<Ë ¾9òŠºõƒ……Œ•©\*åklÈöˆÉ¶äŞgiù1Õ“]°ŒïQ”‡Ïj‰=ÂÙ63C$~t¤CR£éŠ¥IX|2dù3ûŸ~J½ıØ<Ş7Ü¯tƒä×ÆñËœÄå®ß”:œ»)G†ŸCı£B+,×pq|òFßåGä+;…¶•ÜóœoœEñ£…aK5ÉH2Ü¢E1Ë#éÕÙ‘N•R_GŸNÈG„™ A9ùJ‡VŒqw¯²5Šµ­'fÚ±ÖOï¬ad[-3ôÕH¾ÔãuÆ)Xšbân¯/ÖK—õÒÚúsê\"}­Ó7vÂá‚€¡*ºƒ>26ç"Äv@Ùœû~·Ã '"G‚opH®qåZ³”ùzõ z‘Úd ÒrRbƒ‡¥• Ön1Ğhv<dóŒ•Ğá¡¿‘ŒM2wµ¼†i™¡´”Ã$<p(AŒqQq¦‚Ä™’U6ó)»Úõü¦U+7^3¾«F"òŒ$½Ôiçpñ`/°ı[r
¹,ˆšç\:ù%A_“@ª<cE%©wSe&‚lN8V4Æ^»ÙhH’jß<=J„‹¬¨t
g¤í­uˆ9‚Hbk'=úÖ¶U/\Oª™cÖß¶û`¹„¸:íÚª´š2wõqà<¨,¹±2* “ƒšQÌ½X»—²'Áé.ÇèÂu“Ô€v½jBìüÒgÒàWpl–Ú‰™µMv<Xúß˜ŠUÔYQZå1&yŒ…) »ÊÆ¿v¦¢¸—ŞÜ#®æğ¤ï›+†f[X»–42ô™Ğ~ÂŠØ—¡B Î$•/f)×XSánÙæx
6Wö9<‡§'œèÓ¥·vƒ[ˆa‚Vd=WÕÚæ$ò¹ş´e'©Û“õJÔ-?>›TNJ«®yX’eösğÙÏ'ìíSÆV?¿RúºÓäˆ»h%>N»ÛR×e+"7’RÉğİp*g(iÅnU(kõ‘ü
9ËÊ“u—)}¤¸æ­BXø6– Â»}&SøF_îo*›¨SâªÛYRøC]åÛ™Y’ªäŒ Œ·¹´Ï­`J×4¤åqù±İ¸’ ÅAÅD"tLQ€š™Â–O—Q“köLËrA®HÚÀª`aU®øË%uë`Ú ˜×Š³k=Ü4n5]_¶S‹3{M•)g8x&äûí¦ğ'>—6cq”íEÎWÃ¢?dšÓÙ!{/‹­“kék)tÿU•Ñ6LáS(›&·6˜¢ÙÈæ›¿³·eRY)N€òFa¡k–|SúÒÖ7örË9¤«õ§qÊ›fcàIÇû¾vÕ?0òÖÎ­j)[ñËàùâz4y>ğ]ğ ÃÛ»G«÷Â]»'‘¡{Ã]9oÌÖĞShâS-Úİ‚®…]Ô—ÑTÈ±nÒ	¾ô·ştB÷ÙmÄæÜØÕb¼¾áàÆû$:Rù±™ÔÑ¹I™cxŒáÃº:âR}m,¶¸c45ÛŠ!¹ä‚r-PhÀ¤èÑ‘Œ¥‰Ì(GùXë)Ÿ"ë#M:"ÅĞô~íVd‰/|®µŞºıÄ§äĞ‘ÜÃ}—ÔÙÛtªâ²|%˜šJ?kPÕF_/ÖyiV@=óq{7YnŒ>ÀIºˆ‰ |œŠút‰Ç€'®ÔYÅ™±i¡
lå+0hÔ»jIªŸ˜B¾ØÑ¸¦>tS¦©Ÿ-5Ÿ=‰â‰xŞmœö­®öPÔµ)å@$ÏB4ºş·ĞÜá»—Ö”Ú†á7öı½PŸ¿BåIo®“Ë•ŒIA'w añ-š³3‡™“ŸXb]T[[hg?Ã´¢5Yä‘wP¿z?Ú§Ffâ]Q)§Öœ@øãã[í'İ'9ËwÎs½áFz(jÿÑÜ8] ÛØı d‰fæ!!ÃU,U(éÜºé” *”Ö²C.åî%]î€¿D!ZZÒ`*nâŞ¹GR¤êpKw=øÍ’Pf:=¢2E³7ä¦€ï²»Ò‚?ôZ¥LU¸ÙÓhM×İ\w„±pOÆÀãmŞoñãñÌuò!háT«*Äôıpº2ü¥÷›ĞÆºa*Á @â=œˆ}‹TPQÕk‰®ğ–[CiôÛáÎ)£=TnJ›‘vë1§ä‚ä¹^EÙàRaÓœ8×úŸŞ^—{DeiõçÒ™„b~]ÿù-¬m(Oóù)ÓSá•A€ğMì0Zqqj{‘ƒ¼p=íá¦­•ş•‘öª±æ‡Š0kDCñ%=Å‡²î£ıõğ¦àH™½1(b£7ƒü­Ëg„Î(³ì.bá.à,>ŠØ_ >H­F“‰Ø$	Ÿ¶dZC¹®Ô¼•Ò^% d¥1ú±pªüZ
R’{BoeÓÈıuz*_?9å»(WN^¶…Éö($dJŞìêíaˆ}rVbGæÇ-öÙ1,3WuFèÔ¸1C¶´l–›Òû'éÊ<ı©Ãâ.Ì}ü“õ@2¼»¡Î^ÏæÌ|¸sÛRN¡b{Àò}ÊÁc9Ÿû«Ó-T„Å¹•İË±E³-Î…ˆ ]r'? ŞØ+úóÑÒ»†g’mX™´ĞÑĞá+™ÿKÍ‹Éâ°œ{€÷ğ/,EÅ‹Q9­K€´gÎ*ÛÎe4¿ñ
9`én¿¹Æelba®pT&)`éÙoÉs«/©{R‹Éq‡“ê¸Ş;ÈR8&@¥ö_óº@VöEZ^/	›G'gÙuáÙ`gë+AHÈ¢š-ôLè_–ÊMŒıë¶¡»UßDnmBÂ¸~cè†iš÷ŸÁGC¨şx¥¹ Ğä-=s;ü¿"M}_İğï[:ï ^¦ºwe
y<ñåËJÊ–ZZW¢9\}£Ò/ÇSc¸Ñ®	İEdéyü;E„¿Qï™E+}ªCÑ#uèÖ„d/¹‡Õ)˜¡íû…lÙEK¬â¤^çr«¹92/xhb/	àÄŞS7+dÁë$¬QÇK#ú~şïy:TeÚ¹ä£¦ÆÀ¸)@|µÔşĞ‘¨Å;£ÃWş £óø ™é;QGFúï*Š.lÈ¾¯Ò)ÃËœ•‰¡Íƒs™­—0Î8ŞÚ0J1şls†åÄ~m8Çç3«õ®Ç’qe³ğo|gˆI²à"Õ’ £—°ÒÎ'hG4y¢‹m6é.²/g'vÔºym.>‘çs]İ‰«ÓE÷xµ'§µ”µ7í?	ç#-dñmÙVi;Ï¬’PÁ¬lN–óµŞÜO®Âıæ¾3jşï8l!ÓOã¡ˆí‚f·&ø–ŸÁ×ËæX¿Hù¢ A#yĞ‰ñu?XôÜ%ÆXÊc5"İ}ZçÃ~\úcÌQn…rQº´°SZwgjˆä¥™8˜öC¥Z(aßNéè± l58‹Ô-I]bãs7{§|&?şQ}˜Gşp³¡(İSzoY›sÚÚ8%&•ôX¯³«Œºd…ÊåF3ã#–Qk­z"ƒ±ò¦‘>[K<É–ıàÀv’ÙÎrMFYGÉ‚±B¤Ë‰Ø0©6âc™Ÿ™SçVïÉ&±ë	Óáÿ‡‘WÕ´Àaö ÷m‘ë*dŠuAs5–¼œ–¡[Õik˜–%ØãM’°!ã~~ËHèè¬E)ÊéÙ@=Ã›0kkFˆÈtèzJ—RŞÂ y²O>b|«lç¹×eÜ%ÖœUµm'¡â¥àZ9Ä¡¸3}XK1µå‹ah@ònŸ4¾!­pfé #‰÷¡òÆ–ßˆmÌ
bÀïAnunê™_m"„¯(2„Ó,céULÂ‘Hº¼G©•ÜEh¦¹²}ÇİM‡î¾bãT}°îÉ‡+û’s[»À[ùV,ŞïĞOsx{pÓ“ 7ÖNì|.Åš¨¶´EN3Bş»KÚ(ş›Í—àƒÕ³mp°³ëè5Oº6ãæÛ`$9QÔ·œW¤ê 3Ù»9äpfSãşRYÔ=©>â•×7¬”û‘+ëÉ/Î”6J|óeŒ!KûÛv†È ‘YÀş¸ùËL»x*ByÔğù«ã^4ş°LÏœá¬êSÚv%ûÚ# 0ô¥íÿ*ó†í=éé\Ùµm¬‘1(E¶ĞÑ²1x8¨=¯/Iµw§’"!ïå"hÿµ~'–†Ms·½YwÚ‹®!½àpP‘òµ‹;ÿƒGŞZ‹ì…/
1ÖÊ'ŠŞº¦qjp1™^ªı‰8*IRúçÒn„³–®ºäi‚²Ï¿^dV¯ï¤Ë¼÷›…Ø[Vß‘!<‘aj„}±®Gï}yÿĞ¼á®¸Ñ>Z¼¥,¹Ş¯¯½ÌšãÁDÿM³†^Â—‚%Ä­K}gê­¡¦ñáúô¥¬æâèéÖ¶â$ş,i,ç¾ÚÀ¤;»H	¢ŠÓbªÔM>FÇB%$õÌŸÌœd%Îp™ø°Ày3úÙ}*¦ŞÑpşûİç£ùá >w¢áÚkAÜ†x’‚ó+)ıjÓÌ'£¹Éë†ªáÎ’.™@XÚu†t:ïšˆH·cüe6î‰ëJH:m}=lİã«j<–5yÀÿŞbpj];a1‡¦>t¥‘t´LtC¤
äÆÙJÛJ€Géúx„&à0öı~.éå¿‹-‘ì _ïvŒv«åÆ¶‚ËlŒ¤èÖz´V&(ÖßÉóõ!ƒA¿\®ŠÆmeèÙ1<a`Bœ–bÀã¤ÏÓªOÿ„'à×êÑĞ@˜ÃO"/x­¦áÕ5µöñôw©Suòsq‡ñŞñDt)ŠŞŞôÖ’ğ—Ù,ë³‘ã_3È\øgXvç—SãÌ{ÿ­Í…,;YußíC  ·èï¹lù0Ïo:øax\ÏW„ı“ì‰ŒÚF°Ş%ZƒXÇ)T{§«ŸuãˆÕi¨¥ò.ÎÕ?±z¶ãl™qJ3İa±m÷H<l*Yê6Ôµò`‚Ã€àåJ‰Mì_ i‡ñ±„L×>ùTgñS½}à²‰çdrz–Ÿ3‡íÖIÉ÷S©;1¦õ)^Õ…¸ 8-n1fn®y9UóíAŒWfÈ©,Ô¶K”L#pié‡B19Ñ¢ùğ<È¤aŞŸ<Œ¢F4–äÉÆğ1¸ªL•Ñùe€`0Ôñ9Ú/$t§B1~<új.i#ªøx“G«éÒímôÇµS–æfcS†¼G }°[Y 7ée£émÕÆ´9?m5:YBıåW.“G·Q«õõ:êB1VÊá3>µ’
hÂ#ğ@jyA¬Ü;3µ6Ú¤‚±%É\L3r{±v}Pºò†°$‘
Éö-U£NÍAsáµS£zÄ#+˜ë”UœÃR¶X „ø$Çj¿¾ÌVØÌ Ç›Â‚…éâVÆf¶ğØv³¿\H‰†‰JBA½+h­o¶»#&³cÇsïWÓVV•dæÌÆLwæx(÷r­Zùïİû¡K¿)#mÄ¤%ª…°'nĞ)\×œ2g„j¶^`wz-†¶{¥ôSŒ“)ÁÕŒkní²+{Öw°)ëÊ÷9S±;ÃØ—ÏO¨d1>zë÷Ä{©Bì± TÉÇí¼jsÏ;‰ şìä¨ÂÏ‹ª4ƒ™^raì»V­¬Å†EÔ:/L^ E»’AÓ¶Îß…šSŒXÀÿP¥ßèøÌe•¥ò½åˆ{†¼àH¨5­Ds·ÔB$³°q’v7!?uOÃ)!Šš5zçª(5ådÄßíy-5:A™ÖœMP“ãgX(×6şÑgæ)pŠÏxB8lSUUÊWs8„Ï‹’üƒuoÿŞ~^YÄšSŞ¿”‹’Ã{Âyqä[W|äc£A¸Tâ#ÃÖÎ°¨YG&ŒéE¤-@úñ¯Ó¨UåCæY%ŸÕ÷É¶}Bêw ØI®É†l¬jâ¦wôñ•ÊŒl µ¼iÃ¨&zÃİ”Ió±–ÄíT7.¸Qî¯Ö”ÖÉgD}¦°Ãõèò°Ø¸A–n¤ğÒûÒ¦Ê×âÉ12WÆÚä~€KîèS­x“Í'9[f1ƒ@Ø“SJC–ÜN*_Ãs¢±•5$ÿ¡ü°Ñ5
¨µ~±xrÊÅo¼Q»lbÙGå1øÀ*òDë• ÿU;­ıevniÚN„C8øÃÌTÈÂ—n0‚õm-µb «Uí’ğHË,z‚è›¢1+ªeÏ&qï;hï	cÓÊÔ°ÄqHCwøÒ^ºÇ^nÔcÙ3Îeı9hûO}Fn†è¥š÷.MbAô /±Æ—a@%Çñ¿,¬1'01ç®úpXÃ+æs1½¨´Ø€ÏªJAh,ìát,
™4wlŠ‰=¬9}¢QÖ_1"êÈ ¡&ÌÍ£OÊ7Óƒ$àbR‹ÙÌ.Œ1ŞOˆaj»Uyz ?¼ˆ‚¡ğŠêöÈpÃAÎ<2”¤¿ÓŠU~|~‹yxBÃ™v’|W¼!ô[88üîÿø±¯,v@)ïZõòlÛ¶8D‰Ë½S×â‹¼%0  È˜ƒl‡S à²²=‘z÷Ğ¥¶öÓ„™€|/Ò €z³¹D0F0’•;o1Û²ÚïXô:bàf…ˆø1şöÿ$‹?v6v½UÖòİ…ÇqİuÏÂºlk/E—`ï¶ãQ{WÁİ³l¡ÙpĞZ#-é¹õ²(¨ĞÆ”zÛµåßYÖO&s7&ó(&Ãô•É·]Kêiƒ{V™d—]R+O€Å6¹êÌs;ƒ!ûS¾vüã–°ÃĞg	ñe³/ŠåèäŸíŠêµÿÅv|>şş|5Hã“/E•%x¿üªhÄŞ´F (ºWhÌÍ¤Xy^pvü¯”uûó£õk¡…(Rë¬M»çÀ|™šÕÔ:¦/ÃÖT+ŠrÆßoI„•ÁÀ]G’j{/÷¢rEšb²DGy|
üğ¥%T—ŒX?e|/ôÁš™Jé¦¦½L`$õño
Eş‚oß_€ğU¿~‘ë‚Óîìµdÿ¥ªa#ı«0\`6¹E¿Â]I\WÄ70ÇI•†¸*Y¸…”|œ®*¥é$”A#_^cš7¹,xILîCùO„ÖqÍ1:sS÷¦Ïmfì•fE$Y'GŒ'ñÖ[Ş'q÷7Æ‰lî‹V		Ş9™–Ó„ONlÅln«Éd†bV¼¢h‹EVŒ*Î|HŸ¾l	&[‚È!‹z»Fñi(Vxô&å) š¨†On]uCæ'¸Ãkœ·IU„ûO'*d… {¦Áx ‹ôX]Hƒ¬>¯&‘Ÿ:n£ÜÜŞª¼ùXŒÙ¾%—[/uª-Hh\åNÓ$ó^z¡±5DÓ)êq '2²l¬­ïöòæ"­ÈP Â)(/`·dlf
]3¬;4T¼ĞŒ‹!ºj”lV

~j'Û„è¶Í•5œì™ À°<õÒÍA3 ¯Œcğù­JTà ä„A8ªbîàxVlaÉ@«%Ãä¨§É™	aZƒšÕå Äş®­yÌ~º‚ovPÁ”Y€+¹±3z6u¾ÀL'¿Šh êÛt|;
È*ÁÛ#Â +šÔv § Îw‘âuLAL[°âó\Ú(Wù8½±#3YóåŠË5©ğ)†iñ½Àø±ï¶û‰<U}¹˜İğ•'2V/P²cGÓ4Á jL~YÜ×İ=yÜ;hÍ<U¸Ò òÛp5'Z`–NTá¯v‰İ˜¤ŠÌPº,ÒUWT¨³Í ¢£®P
tL_Ç‰LQ3r¬8í·ÏÚñŠ2¼°³%^SeAwQ®C­‡f®Î©W'‘…%(G4lõ¿ø¸ÄAÀ„å"‚¸š‡§Ûô(Ù4#|üÚ´G]/É›_Ûwß‘½Ş»êcÙW}šê6
=Ë¼<Šˆ%oÉHe„‡Õ¯”Õ)KÈE­fÑ¾0ÂùDŸàI"òU°8]cˆ‚1‰ğu1obú¬gŞºß–ê5J×ø²Ût#VsæÎN­y),•¿Šcây™Ø
»Ã¡™H6H—l	ìòYËív;e°6-°İQI [P¸×úÈ= vÖÕËç1Ö]`¢XËebù|&¥U 1—K•]@ÉOıÈ@Å‚?)B9Y3{\µ×i¾Ò÷-J ÇqvòË—¬M™í(ZQzÃ24ª‡û4BH`„ónÙ3%”Hø‡Ì„æÚ’úy”I35Ú¸ÿMó`Àk·l›•şö|D5Ø…ŸDdè¾f–Ğ?.cÕC²“*Æñ?‘ LZƒœ$>Öd™Õ†ÔF *×	pò‡Ø=×}WŞ 9Çœæo…È+Ã²¬`ø\¨ºXÎ‡DÈ	Á%0kÍ ŸÉ?)X6ªßEÌİ¥‰—KcbŠïñ7c„síÇ`ÕiX³ÿ4=ğ5Uğ:S{•Eib6qõœoŠP^>J"dŞèŞGuZµ–Y^D;,rnêêA€=¶Ö½Y1Lûëú‚šĞái‰ÒÇ“h;Fí»Ğşì)ÒYON+Â Sx£ˆ·æuª"Îm±®I±Ëåè4Ş2ÌR²»_„§ØkI¬ŸiÊÜ¾AzöŸØ$kîÈ±"Z‡€S1 =•ÑûÛM°S'4‰ßáŒ \g­ù—|Ş¯C5I¾,íºTódÍ¿¸Ä İ’§˜ 3eYCW@_T7ˆ6ç	¨ùòœ9µy´¯nÜ½Ù¸"Ş×¤áÃ8}œëPf›¼½dôqkuí©>{{ALèF"Q9Y£Şi$d%Ã;¡sü†—ã7	Ç«mëØ`Ö$ŸîÓUT^åØŠ<q"u˜,ó yÉ§¯7Hƒ:è×÷3›`y^ÁËïÎ&¸…qY $ŞóoÜğCb&[6°äGYË¯íqc Ş˜ltÁº È0Ab‡ÚlÂûL¸P4¾°ÑHÿÿÑN˜Ì‹gŠVûä,*J™R‚İŸp[JTv‡8Ã»a>ì•çQíüøÂ3±ÅÿŸ†½JF›Z0ı5$ùyÅÎ#æ{¢OÕ@FÿúæÛ{úŸùcXj…Ÿ¯@İ˜£Gm¼Cà]Óo 3ÿÆ×§oŸßXºI{äL¿ÓnB9ğ—"’kÒ©¡WEù¾±¿±uêÏ–İ|Šª7«ä÷\˜k_¿Ü“Aduã}³±ëNû•=zFKaÕTæÓş5ÿ¥p›²ø8¤ò½2Q”‰½¦:†D'E&KQ!CU¬dOË·”aØ…;œ“%{HÊoêáœ¸ Şâ°É^s/ÑQ(61Å˜M|¿ízkÇñ×uDÊQ0gyÅ­e÷Óï!£É±YíNLÕI«Á““Îk9ÅAØèvº9¢kN §ùnÓ¼Š°2<^Åµ5ü2ê¦áçN)xÎCâÁS“°Ğ¼c“ûå“ul#pï­»­|»	ù^Âm$W=¢
FÜ®Ä¹jã
T Khpqî)A]¤•/XblyËxFé§—Œº	‡¶íc9S„ˆ:®wšì|4¸µËéK!ë=&f=wjU†VØ­³j0¢k¼.œpkwœ,ß^£l-;ASÜ±7”Hg`“(‰Vöö>…—cZ9[b5À`Àˆ¸
Á4%µ.ó,ç¯º<D`VcR6jæƒÃMGF)ª?÷É;îáî°çÍÛ6Ó´®ş`€ãU(XxóÙ†£ÿ ÈÊxR†\s¡)¾ûé†VíÂŞıì§( [<˜¾]É”%SòğLJânvúZ ıŸüf´¼‰ˆÂ	KuNˆ8·Ş6p@À,…,nôV¯  jYâ}ıM‚ ï¥€ğUÖ8±Ägû    YZ