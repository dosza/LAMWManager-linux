#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="213632033"
MD5="2b14224636a569cd2672c9f276c8be06"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20684"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Fri Jul 17 20:28:42 -03 2020
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 160; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿPŒ] ¼}•ÀJFœÄÿ.»á_jçÊ‰1õ§ÎÕ¼ËIĞl›™bÕ9TcCU½@ğşÚw	ôBÏ#Ñƒ}h§“1õjº­¹Ä·ğÄ0„P!«f_€g¥¥G0·bSÌR‡‚0‹‘„à™Ñq×’Ãê^qcu«üv¨ÛIou%láé«'¼Ù®S6\l3Ü€}hTG…_	©ıªÄLF¯ñä„ØŠº>úHd—CÌ,–	kùÕ(Nl¹ ­½û.—•¶¾÷Ä¡ıòÇV‚êéÏÜ5}7-Lš¯$Í“ùãÃïú1…Õ‘Ogg¬V $cr…8c²d×ÑÇ€dæ…X°øG[>ÊÎmB|‡¹÷-¦›^g’<½÷á™sÕVÔ3J†ÿ7Æ4ÊÔ½©3`IO€lš¡zY³¢Ú2ÓÛÏüÈØ©ÏÔa-ëvØ¦Î
0¢ÒWÇ?»üËÍß.™¸:¨£CªÒ¾®î§Üj3éYG_MZËüÕóA¤ŸÓı”68~‹¥Ê2
Y1)¦4ÕÚX\àPí‡Õ¯S¼$êízaÚ©%Fvğn“ ?ˆ…”]Ò›‰ızÍW<%‹à„Üœ5Ü Clª˜^‚„Tõ@ß_V&¦_4°¡,Jf-úi²oó¿\Á%ú™‡$<>V%DÇ«ëNŸ­1†é8«
N(ÔÓ £²âs¼CÃj ìJƒ¦PÆC¤r|ıä½|î93Š³òè?¥ğ(ñKJ^W8|ïİÑ­Ñ¹C¯ËödšèÎY˜ÙáŞŞª1>Xä”T'pû.rLŒ ÚÜ³°ZˆÀ“Gï¦Æ¼a¤ô]±i€ –ö(”Ó	¦ŸÎÙÄ«)0¨~ÆÍâÂĞ#¾L7ğ„‹N­{JïÎ¢áËG$=QeRqÿ]¸÷M:ÈÆä)&6Ew”ëu‡É¨±bba:ø*Ãµ.¼á—¹¼UÚÓ¨¢}uÔDÊ/8J*ˆèE k…!YÉÑWÆÂfİ$o¥h”ü°\ÏUòÙ((½”NÎPÍÇêÕjª]ÀÛB;ÎÊÌÌ+^x®nÒñóİ?ò^sÊ‰ÚÏÚÕº‹œ=o
Äı4$ÄFz‚s˜ë!¼¯ğÒ®¡’RäVoÓëM»%
ŒÒ^ÍÜ9Eˆ(~ŞßW€H¡ªYm¶©ÃİÑªIŸ!¤£ÔâE«U,€·ôU­*4rµ"¦@Í%ÇS#ùè #¶Fm|èaÎ<³¿ºrPrğùjÍmn©u­1rºùú®WÎH{E›/8Ö>·OwGÈÄlZ¼DĞƒ[‘{O‚®hÊG‚dg½ †«gûa©È&åCå½«s›t~é ü§­á4ÔÈ0šÚuF-Ïº°É{²¡ŸfI„Ãñß~f°pGS‹}¸ÆøTA¶µ±X¬ì*şµåí:ügHÃ>ÀŞÎ. |e‚ß¨ìE™¢¢«²l@?LdÑft.Œ”£QÆ1ÇÌ&ĞƒGIûõ\DËs^°w¤ë6wã<„/Û•Ïûš©÷ K¦ñ¸âê)Eò
L1UÍõĞfVğ»Yß€w×óvšÓ°•R(ZÚÇÛ5q ùÚÉBrRÒxHÈ÷[nït2:Æ€ì…ºÜÙşíÙWûEW(V1Ö“f¨]›ëA™³h´Eyõ3Ø-õ-È{.òùÅ_`(Šx(8N@—è.^ê_	’Ğ‚UihÃ}²*¾ü¯€ÆláJqŞ‰z3ğá7ĞÄX´TìÕÿqwtMÄß„ü½çò¾Aá6 wä¸J%gğwu£0²ë*:¤C&DEg"C¶¦¹xÒ¼•ŒÖ{X^Ë½-®fç()§è`·ˆ¬œ¾k)©CÚ3K+¯³§a–ßC§Äã!¾¦y©İ&Ò–¶9Ø¤³áÉ|oşd…Må^l±æ£-tá{ÔÅ•3"fé?)!¼éû$Wè<œ¶ËYŠw­İg[~øÓ±½ak¨˜Å n§oÊl&Ğiùyş2ŒW”¦´ü
.¸ÿ Ÿ”OlŞE¸Ş	Vè8>‡-ái®K­/Xr¦+¾ôğ.Põº&ƒ€>×¼K¸ <LûFeˆ$xcİÁ¸-I]5)–éq°=ü´æÊw-T$Ûd¥e:E@öUÔšòœ“’äKÆìÓJ“Ğv¶ÎóËÇ-s6>ñ/ğÌüDB¤<~t>&SõfêŠ„HøX·Š~6Å°3p¾jŠ%üõ»òÌµº3"Dûs~øFüê,ùQÃà'Û\ÿ¤ŠÎ[·ª$v^-\S3Hûóî¦æ\FÍíÜóOn~Ø Y£sĞœÊš´Ä•¥Ìè»±èzrSé›+!ÌT_£õ‹®ª¼gù;ÔüÌW°t@8ïØ ’âÅpÈhl¿ùŠş£aİ®|p`°nP›@xñ”\dp$vITôğH8%j¶œj|«ĞK…¬Çùó¿òZq?ï”pF";æ¶8Oü·Ë²¡3rÊí—°éŠ²;t6l]¯­.±ê¶ÛJPÏSôËht¡ÿÕ÷:a½:a)$R“L—Ö6¡c¡u0G¯Ñ§Év¡heÒ‰`òNMœRÒÔNç]õ;¶Õæ5iüDP×‚"-‹Íf‹î6*•ÏEêoo UË… Éò{†Â§¬ô3†1cWÁ]và
ÎÍ5S|óÓ·s?ÍWé‚BJ¢‰œã}ê,'ÏºAĞ	Kf/uêaımi¨ˆ”Â€âÒìYDL?Ó’6ÑH‰B£ƒç³0[kÖ$¥k# ÑÇÜØxa–ªï(°ƒß†rÙİ›¨ œ„ów§4
‹Lea^éş4YD`ÊŞC0‹ÉÂ_M×ÈÑ.b7 ‚nÃ¿4…oÄT	 q‡¢ÍAöhëÄ5ú™<Úsøqä:_8œ³Ø/¥î¤êhx>àÊãmf¡òø4Íò|›éW2û.?şƒyœ A*ÍQHO:¸’½ã(m-bŒ<û¬j7m+¬w©	¤H,c”5?şÍ¯«¬iÃ•4%ßÓq•CaŸgz¯¨Jxà>3"¸BÉjŒtÎRÉOı^øíËNü²û"_ €<Ó?ÎL…›ÎoûQËİğºxÃna‘	¿õÛmøáOzÎ[¡G¥ÈwqÇ³ <b™Š’J2
^Äi¶BìXr~Š0±áƒhhuğJî¶noÏËòDã¼„2ï`#Är"á¨py´AÇÛ™º1rî^ z5°‡)µ”Bğı"ÕH÷y®d°\if¬şÎ–Ñ^(¢V²ÿ	ÕLšU¤ˆššæïVJÊş®»'#ñv#×TÖM®Í!Và÷ìoáË>O<›¡vîŠïkğÔA£x’rcå‰0ïğAüMp<}ù’ncşF³ù¶ß¯Òbóy( µÇu~p2]"FGBĞ›§&ë4P9Òó´ÁÄ›Ù^h ÊÍåÜ©ôÛÕŠ`~´S¼Š0Mƒwİã=N1ÔŒ4˜3Äûw±K^<ÚgvOl,’-Ğ^¼¹˜<àÑÖk€7aj®)³R»­f~Üíñ½¼,\9ÇŠ½A]‡‡*Zam	[ó‡†ëc~*tŸ¦,}†ğÂG’
€ÉbÿÃ?ÔÄù4’“ªÛ×ùÉˆù»ÄtÕ}À|-Aq¥©¯zİD‚ïvÅ»kÌ,ZÉ‚¾(,Áeü»ìeeÿõ÷İÕXˆáu7ËpÇ“7›1^œ\Ğ"õEú}ïÑáˆXpDÛügJ½ €Õkå zö$.¹ 3Ûıå(ÓÁyÔ/€Ğ	Ùüğ¶İƒ7ÔÚ»„^ëŒ4Õ“T(µ’µ$ë=ÈC!ÅCZI„½\@2Ü³B;Îš@H	îLĞ¾ÿ!+ı•vLHDÇ„fÔB{Y¿ïÌ'Gó¸òv‘ó8^”Q?´BîD_\ı·
Dj5b~û”A*Ü”VöRµml.D—à_¤ón˜vYpô9ÆßqÑYÅÙZ@4V¦üõ)nƒh¶CÃ"ÂQœ·bÆkáïĞ¾éŞäÂéhr+øT&§tØº‹õf]¿D£’+(ã=ëÉ§_$Ë"¼PN¾¢¤1‘úÖÀÁÔ:tâ¤K¥z#°‰¨.±DOé%¯²J¡–@À[·ZZDR.qU–/X"2T»Yi÷ÉÙ ¥’®tHİ€&QùÔñğk¤¾Úïu´±¢›ÊºHıa«³‹+F¿Ó*‰åÉ¯©oçûw	r•Ê8¼!K¬WÂşâ·B&<´ä1ø%£}ß>"{.¦|‹;ãBĞª8¿ÂšñÂâá½á<ìûj±ØI}„¤Ñİ
<Èæyép“^>øŞŒÂËÓÏè”¯Ïàÿ‹;|/†´y
~ïıy§\Ã´õøQ3É­%PÍ>w’ˆ]ioôNÒìÊè°èdúß4dÔ¼ï7më•õ1IşŠ·†kñ&aøyEÌiÃàWsÕÜëf`#
^nB%¦ ?÷\’‚ïcªwRŒ™	¾NÙqÖbjİœá4Ü’Â¬Ğ%#+?ã^ìÂ+É±v{+b¾Y/º6eeÇÍ9¥zp\ÔÑG§½«W»Bæcˆ)ìò•ªŞÃòÈÏE§Á:>Åıa§‚èm‚|T‡m.Ş¿ê„\Ìœğëœûœ¢üw·Q—õE¤Õ­ı¸œCIĞû¯N-öŞcr¼I/VO˜‰Ä?$Y˜ñc¢RË,Å%"È¶w•RynwHAdçªxO©–È¼×-3ódlƒBÈ~/(òy*¥‘Õxm_ñÖmXPsc¥aQ«M¨ûÈ:‡zA Ñ	kÕMã`¥ËqƒaJµŒğ4ŠŞíÛ´FštúYLB	¢”wv‘N1Ü¿Ğä½Œ³58ºYh°] şç„2oŞæ._xsj¥aİCê‹T°ú„Ì}ŸÕ=ºŸMŸCåM›bD¾Ö¨7ª×=rÆõ˜@Ğ{ØI;^&­9SuDÊ¨ÌJW¥“ìAùÜ%l”}í/óDn9¯·Aè3}´üf³)¥£pÁá‹M0Vœ_&®×ßÜ²ÃÛ©æç;B°#JÏÍ‡“¯ÇCß…»eõ=LÖ¥Pe¥v("‰LŠfª†¡%Ÿ~Õ|Æœ‰Èïš’8ŒOçé1‘›k†”`Lée¶ÿ÷ÕËEMnÌLóëÂ4µÚ>º´ñ€„“-”˜ÔmG$­â£¹æz+C:ÇÌ¥¥uúHÏhIÛĞ^6IùuÔLg½äé‡“Û"${Şíi¹ ´×Ì½´v1Õ ÎÓHÒı_<ŞTâŠ™h|¢´_)Ùcf¨ÇÁè–ìí›”iÙ™İ1é7v_ãÆ(Ä é±tônRÅ÷B.™!lgÜTî1mr¶ÔPx¿6Ÿ›ûÏƒ!†CuÓà&­v+—xcJàsëÅ/OÿÎé×!Gğ‹Û¦%ÿ ±5§m=@ÌÙzYóØ5b.‹%G×‹˜6x€MQl%€':àZßPMÃ’Â\_¾j¥?X=Û0öÌÂÜ)”=÷šg§„6nó4V6ïæ¬º²W™\İ¢È«çµÍVx	”ßLf½°xçç½s'§Ç$¶ÃQ—ÄXüY¡stâ~šNv¾±²ÓåH…Æqƒ”2
˜ÒùÿQâí+äÏaÀ®3Ü'Ë2¥í£?N”Áû\åS-R¨ëŸô\^º†}.W^Ü|ÅıïòíĞe(u¾±$¾¶¡Óºç¢—x±c¢bè}©X…›ÖO/Qw/$ƒé‚:ÛYÖ£îs–Õ(ìv‡$‚]‚½gÀš8Í >ME2®×\cLô6B¬6«~ToúÆro wdäÈİğ YPÊ2]³Ìz˜¨Î”ŠµgÔ9™³@-Ñ44MÜÉt›››âÅ	¤à·„På¥jò¥Ì„ôDğpDÊ
po5£÷Ÿ8‘kq8¹|!@N<SÙ¼ã$óhrµì×v´°%pÚÉGšØa–à
mJhŞŸæ‰÷øœ÷õ8àTU"ÏN‘WÖ—ÖÅ›œ§EšGĞ™"J>Õ.fcP¸Ô½œ'Ö¡ñ·UÚó½™IÅS&Ağ4Ø“©t­$25¼Ùß\¯ÚØ8<EQBÛiş .0e4uº?Ò,h|Ğ;pá[ÀNîáÅQ9DqÈAkl“å÷İAÓ°ğ<>5È¾qÙOã`"nîvà×Ò¤Õ’xav7drDk9«åY³R€¥€¡¸¥D ÁÃ™çéÑXù–ü,(9§ãñì«—3…]½!&¦.|'—i^Ğ$´¦ñTÔ ØµîsÄªğ’¹3,ÿ„„‹wWògZf›lêéÛ*ŒİaŸ‚”÷» ÂZ™“c#ĞYò_úmT²ùd Û˜ Âãô¯3¤FßB¼‹ìÈjÛ*,‘P%çS‘“£ğéY í·›FÌ½«ÿÕl7läNb<İKåUqXZpó~QDò|0 ¯#Õ	dv*·ïr²ÖˆX= !Ü>5Uó¿2!ó¸à'²0¸¶š³Q.’$BÈCeå^>›‰ipªée…¡ÆXµS6›Ÿ%j±ÙˆºâY×y×äŒx‡äfÒDÌ‡I{qğº;0éVA‹…(•ş¾Ÿ¶Bd ûj,Ô°ÁS­º]¼b †Ï‚¯>B!ZÙzK+QpcT3rãà¹ ¯M{¤Áì—tad•xßH#ÍàFJ¢	ñ#;G5KLyX7ÌÓ=c åÌÆ0e•\B$˜n'¯Úÿ“qíâq’0êãšîyF Tjªw/±CüG×*“ÓÕÃôVÉ¼á˜³ ò4âs¬êš‡5İ¢øæµ6œ.8ËKõÕ« ´™*Ôµ®ãóäâº×Ì ÜÄg½÷03)éˆX¢«%úÅ±éĞ‡İY
r©öâpC—Ú…ó‰Y¢d Ó¸òúæ÷d0\ä mIDîcç A)Ïsú
uâÈäºİgVå' !÷Ÿá“o«t ø±ø—t”!Ëñ=Ñ,lH¤ëJáğŒ½Ø‰°³
÷Òk4wÂôşI$zµÕçoê İ0óPµ’ÒlğÄTÁä
©È¥Ü¯°z [	LÙô7“r#d iL	“è: KÈA#|‰sUïi€ãÍÎÀU7ÃÒfaÇP6å[E°$Z˜½$¸¬;
ZÜƒ£y’dyc>ÄaIú éõ«?Á†Ô%~ès²æİMÕi·j.#è=–|ê¹“¨°.4Vô¢nª:’G’íEºu_ŠKá‚‹
•²™d£‚)';	E@s„Ä¦—t['*|Ğ™Û*$!ıDPcçóäºúŒ­¯döøñılúQ¹z/ÎğøA&ĞÏîz$—iÆ¶¾"«ÙùG©/>Ó¼áL}—Æ8ô"íÖ¦öËÏìC ‹÷œ,àjëD‘Ë”}\Wáf˜6bé])ú Ø?PYV(fï	WSHVÔŒ
ÿÎéÜ¸&o×ö½ˆøo“n4WŞ)ÕuËº%¼ôö2kÍ°P´ağ­_}ğØ*fô†šmÜ©*ZÍñ'çú¶[¨*J]0Ï´0Œ˜¿êÈqÃ#ø\XTB„kMğê—»ò^fK›;Õ'Îš’éÒËe;ÀwÙ„oö<ÏzĞ¢¢í=Â2¿6©O’¢e(%·ÂGí•OW4‡É;¿¡LØ@\üsçë.+…B>
–²çé#ho‹ñ8Üñ¡}ÜèĞ2fš†ç–dAğjùh°Äoö¥.t]6ˆø­Çâ˜Û÷ë#PĞ~	T±İaş)+üY’‰‡«Më¬¬,ˆ4±ÚZìXÿÔB0ãS£½Ş|¾t©ÈâGÛõ­ôvd?66¹ÅmÕïçŞ¥©óà€İ>é„i\è~‰Ø1Y,M*­kÙÍ°pDH!|À|i¼5¹UTß	T‰qÉZmÂ¹©ú3yçöÒµ0uî/çl~š%¬Sú®Q2ìvQ¼ÆÉBhÍè¯±#ÀÜ{8)Vu"ñp)øõÀŸ@Xn§Z5B…E¨=¤ònåÎQÓEö°œùƒ1±
œÁ«—†-á‡¢g/d§M?u¯F'²á:ƒyüCäV½‚§_¸Û­fŒŸõ	Äº=ç­¯?,ñ™²œÍrÒ‹ç°Í~úWh#wQK=øİ{Ö‚ºn¼ú~ØıÌÕ™/áw‰5%ÌWÄãëN	Ó›jˆ>ÖZá!÷TÛÃøÉ'	tFNã(cÊ&bÂ[>BRæÒúw7yô8ÎDº.TY3YLD–ı…Fª`V¿“±7Áá	ÇwÑœ+É›ù¤\¿Arf¬g®M*ÎíkÕË¼’?Bœ.¦±Ñÿ“Øê×Ÿ}õ×Vš‡C÷¢6…Ø	ßå—XtÙßéˆšÿ}å[_ÊËYĞ’#<¶KZ …¢ş ga†¤¼mÂèA(I†tk½šXI‚úñó‹vX3†Æ±·‡	©ó‚¾Û•ŠÀA"vv“VÒóŞôâôòqø„rB‚ª¢‘¡¬‚9Ââ­Q´³şæ*Óı™£œ$ó`Ç9ÑšG ‰­Óø§FBÀÛ»2ˆ…WÍI—2r¸ã\ã@İ°PîaVƒµçö'Z5CS5›\´íø>Ü0ºj¡
Y´(ñ3HO€U5@Œ²ugëŠ-ßi5ü$…'/àGÅ‰²švùé¸ıÉç½±b?>÷nyÏˆ›BÛ¯¦óê¥ˆ#Ü”LøR‚Ú }À&ÕïsqWƒtóÚ’cĞ‘ŠNB*ÇÖñ]âáû6’DÃ>˜“)l™'ÇvŠ²«èLJ–ŞSÍ‡åURœEëÒ‰óZÅ†U#HÎ¹ ½ÓÉŒÉçz÷=çE=H9‚•&`”ÖØ©“îQVç™Áq¯†ª¡ò5.Ç•
âHáÅÌ
'ÔÕ¥0–æÃ´˜ *t  2w!d¥†µf¹ª§­?ã	Õ8‡ãawêNÌ¤¯Ê0súå3ìõqºfGtÔÅ~¨†ÃÒt×ˆ7qÆ¦|	–ewgª¡…sùúTØŒ	ĞÃßÒœ}ˆ(bY’ìÎ^i¿ 	oã'4:šŠd®ÌÒ„_î©"‚«ğ»¾¬
Ü±f	‹ÚÄĞ)İ[“„ãã(Öcí]0”HTÇmEf…C‘)õ@?ÇGdmz} #Ï]\´Náãë§oãÉú@éßdĞÒåÓ5KCz¯N£P*ÿŠ)Õ’İÓzÄ‘bUEé0CL=Ó”r(ú¿&R@j¾ßï^µ¹¿ªÊ‚Vİa0S+1¨ÜyÃûàz*@Ïz{ÒùÇ6xg´ñV·Æ—v«ú]å#ÍêCJDa'Ûş,]åßtæ‚…_3©¨¦µ“^sÄyñ*]wÔí[Ä `ç!nLÉÌ©<Ò½)'¶¥ı;cåï®|}¶ìwĞT×µ4÷)°=¼Ïúæ— °]öşHC‹~â†8Œ±=$¥v'Ê”'ƒ1ı¶¡Ñ¬}¶o2vêâH}o­úy ´Ï®¨6G’Ä Ô›s3bÕXÒ/±*õ@´öK¦ÈÂhÅÉç¾’Q“qìŞgc5#†Ò‰bÍŞèËÅ|:T<n9‡úí‡âk¥¢)OÇùAjöFÇvï8TX×[îŞÍh«*ôëª/ûmzOµ6ÑÉhÇ—Yr¥ëúĞ¿8óAÖÅ¬ÇUym`ãáp5D]¡Uœ4:Cü´¸t^:£¦:38ªzÊQnD¼F>å{úN+½ŠSWÃ'ÑHËšÌĞwû÷>Ù‚7\¾·Â\WÁï`§‡Êš
3qÂD%Häø¶gÃø-ÍUœ¼x´	Ó‚Ğs'Š¶I% QÛ¼±Óú´LU+˜µ<wyÎÙîÎ@®{B
;]Y¬^ã?¯qWöGŠg— 3Ûğ2Ş9¡#wÛ£zÔQ†ùè1amÔµ³”üagœ5UÓ(ungì÷4&‹³ÈY´xÇÔÌFxtn²€sÆ¾iN2³|Ï¨±å®†ãZî;o“AH'}<h–$8¤^IsZİ[2%¸“¥8¢gNjQzú¿YVÀ&5(ŸÏÑşL~Â¼^ÑÚo{3y‹%Êg¾g@–v-†S0ÒI—·¤€ŸéÿCsòæûÀ\ÍÇ¶<N[tr“rmÀ~˜=¡°x¬üdb²(í;ÎrÊ€ˆIèjsçMwdæWÚ<K(1Ô‡›Rû?:„0Ğ3Â#ñš«Äˆâ‡€¤Ö¿¦8©~™+3¿óF\º¸¨Ms ­qYéB€™¥\z|[±‚i+é<»Àh¾u^X[¹ëº)Û?m½{‡Oîøš—ü€¦+“µ”Ş×ğUò¯Éw~VˆğÀìw™í¨ -¬“i°ÏC ˆÊğ\ñhÔUtQê-„œÎ‘ã¸Z·)L†1Ô¦í½ĞlùsGDö›îê ±¦è|ÿî–¡xø’IŸÏæ(’F–Rî3wßİÆ1fÆ:¼8=Ù$Q™¸PR}pŠôƒÙ³mÎ#é¯İ9½zÍÁ¾ïØì–Nqöt±¯•SoÁšjÊÿv–#c¥Ù#íºäHòxÛ‹a°¥?Zåù:´ÔÖÔA¶1,±@OxÈ}¯¯ó
^ªfÊğY¶50TfËFĞ>héœÊ¥ƒvúÆyg–Ì—NBt’FlMc3C2gç§bIş¢æz§*,ÂÀÀ»ÉvMŒ7nşwp¿Y‹Éõ
Ìta•9<(—æ||ærLHŠ_çİdñ…¦[rMEÛ"ceHû¥a,¡Šµ ‰nóë6Ë€	thJ?H¢CòYÜ'²ŒAàñ"/.«/¾õ{áÕjYk@çQ­ÇÂÃÿ³éuE#JÊ‹ìÅ¾(¼¼âW:CÛ$Š™¥·d°Áâ¨l?cßQ4˜ÌíyZj˜{¬îBHÆŒÜÓ-›H™°ïdréG0LFPÇyh‰-Oä ØÁÔê“Ÿàp_FH¿ßÄöFpÈÇ~­”ğ‘4¾BÕ`Ğq_{‡Yöd”îv‰˜7ËÙ]!ç³Æ±®şÿŠ¾(HœA·7«T?ªFì›ÅçÂ:­‚ÇèŒ¼·"qhÛ›w3˜"=.ßÑaÌÅ¼¯™ËêF$oq¹†ÃŠ¶0æNçŠ1‰¾´°Që¥¨ÍöãÇ‡ídŒ5§ëw»fÑêíŠDfziˆ2¼6˜¦ˆ(Â°¡³iL¥…t*~u¡øËÓÙMo¹„x?ÂUÕpüB¬Ú›u…½¬í—.)ÁƒªYù´ŠÄQc<,¤İØsv%<&–%­ÆKÕ¨ùñ]Œ€ü3_‹ò}ú‡çF¥õ“^¸Ò5:gÍë‰le‡ê<C®/xÕD:g~¾Ìß) şĞì¤=é¾Â†”ùJV¶‰Ü‚İæš¿lĞ¶7×Ö0#"{[Sz#
×ÌVğgÈëêwN{¸‰»¹è§§â€f­À[ş¸ø :}¨cò%˜·IèMs#şçûæ³8‘şrWËÚ˜àa¨Ñº÷•b ´9éæ›u€_£"§wDãriÛ«Í³lüş…*Ú`2İ3f+“pİ*CNÙíöğÑ”‘U=X¨fÀÄU£ûkÓØÕÌ¬Æiw}H¾¼¦®èÃÔÔİÍÖ¡Xi'ÍÛá´—ÆwÉ&Ã{Ú'÷rUijÊÑ :Ÿ’Y¹7·í‰÷÷ÃU3ß¡!ä5Ùÿ¬,,µ>©—ËéKøxı*D¦Ûnú¦İq&%ö>õøõškJ+ô¹›R¼¶ ·ŒéKk¿¾›ØÇ§„oDØéÊ_/•óÎ÷–LÉ $iV¡M?ÍpÂm,¡Cia×åîÃ“ÈXÍiñ+^˜ùÛÔÀa8%\@Ñ(×ä L?¯üË	Ìƒ…ö„¡g©<n´¯mìì-R­ñ¹à/´½—¨ßRd´ñÜw*àãZ«f°Mÿ\Ùb}?·õ(ü‚ Ë¤=ú×—£~Æné”~=\ú°(23À0æGwFr}Õöÿ¨ò+3ÃQß‰ğÏoda`ÄÀ{¨¶\b¦ÈÕÑ°û%Ã”Ôw‰‰@1Æ„ù5ü'„çêy‚éÉBìšvÜqÔ0Ê³ö—X?LR[$àÏ~P[áÏ§csŸëÔÑ¾‹qp?["„“wé‚%…ÉæãÌM[İîÓÜ\)>/hÒ®Çı×ƒúŠ+ùç‘n~‘¥¿|£¿>7åX…ÃÙ½ŠØü¨<Ìø£;ñ7•B¡-Æ*á,sª”ä7;šå0 P¸œÏ*z·`¢ç?ãsp9†02]
*Ì¤‡úİ¥‰Ú½1xJòºw>íïÒğq•K.Ù¢¥yO—cvïw¼Ÿ+]”¡4Q(263Ø ïkÔ†aC£{zD`Q\kÆBÕO±˜›o…¦à°¹ƒŸ¦Ï
e6İ`¡ùˆĞÿM'6ıe—à°í’]·Âú”[Î#àË$ÃU›ßaj•‡ø“ÇŞ‹l^’²¢m,ÅZ‡`Ã`gö"ƒëÚt¤ FÉPãÈ‘¿±±XÔØLWn©zaŸ…ÓøÂ}gŞ´S»7¸BSyp™LËM	õ»›ò+÷9ª­{(¾ip¹{ƒ+jl2s¬rBYM”İwÛ®z²% $Ğ‹Eß !Ú’RY˜ØÆ/zúßh‹ÓJ¼Ÿ-)ÑßÀŸ:º-@›Q®òKí‹§ƒèh'Å^Ãàa•Q¡—,{[:Œ.“jîõ¹€ë€¥ë1çŠkÖœ‹v/FGaâÃËÜ°U~_I"Ş¹/F\¦Ù{LgöV?©±“÷ªŞ9”»m9´îTy™fEM}A"[F ı.mÎÍuãFØgE 6H¡X¬ÈÅqíÎf“WcÆ¿pÖş*u¹\÷ä«À°÷øöc ½¡w±e¢/­•5ÁB÷L;J|­ätÓ«ŸÆ<ÿÒërÁÕ6]ÊÜ~Ãh“¯=Ö¥Õ+MHxîRĞVøı‚,£æ¡™3e(Ä@% bbÅ­`ÉÛı`åoû«%Åª˜šA¨’†pX†ÊÉ&6ôÓŒ¤N1,<®vÖ,Ì‘:ã›üDD°lãjP‘9óÍZN1­¿¬ùbÇƒr’™ËGÜóÛ¿Ê8ÔšğdÉJú¸y,Ê¤3Ü¥‹kéÃŞUg—s¾ş÷6IWÒƒÿa×¶¼¤›ÜmƒÇ{€@a:'õ–5mâí¿6½o™Y;o0Êtº¶'g­ª¼ËmÙø#Ró*š“fÚ;©•m*~Fù¾öÛb|Ü®m_>y•aIó‡¹çàÄÅ‡:—Ñ,`ˆSúa€cx–4Î·_İ¢^›;ìNÈ1[× ¯fV¨ìUÓ°c`‹¨7ûÅ© Ìi @rbX/dÒÃ~uĞºÜ<ÃÁîß!l,ü-!~¶²J¶Û«ºÜõSŸ©xMòÃĞ„Bª!†ë³@„Á|[Ñ½°@™ª<uC©n†Y)œÜ³Âƒ¢Q rZn^8.h4E/UF± âÔğÙRç<Híâ8%¤©ñŒ²Qû¬¿8Æ/8Ì•ö>P^ª¡o‡Ææ˜«Šx„zÿN0Ñ^AHËŠ¨/«ç}Ç•_Q·UşÏ:%<–­v·ºƒØø~ùé¯J İ0v¾ÁSœXÂ¥{íÍ<‚- 
ı„ÚÚşe¥Š"¶3g k4»ÖKy“˜P¾é‚0&æyÖ}{%Ş££M±#ú×Ùœİ3ÍûÂˆa=úHyÂPæĞ±Da:Şèr”z¡²¼”§nÓİG‰)¼ÁƒCnî ·,âSVe=ˆÒDL¼ñ?NX†Ã¾‰Q	²" ·+À•¢¬İÓíÇYå3*ì=öÑ0“òƒ¤õr»CTxk	°Ø;€—Ø¥æ®ˆ6¶ØZsÚdyçÑ	Ëò½PKı‚ØœÖE]S'ÄÄ÷D6Áá¤Î“œÊÜ>ÇRU$¬@Ó©¸sˆaâS9/Ä5!B–ÒĞ²vq—ìü4é5Êi™›
Ÿ…sháâÑ_
Ñ£T Mu©*Äç?ô«‰	|.ø‚­öäh+/Î»QçM‡İƒ7vûËŠé˜šğ›)fj>`cC·&nJË*ÎgNrçZ‰	¬iºàÒ˜Û`Ô¯0’0[ÁzÍUPÃşqü£¿uÌ®’ï^Am®àÚ”§”°¯W¥ûoƒ™,ı\¼ohÜ,Î»ÔÍX²›Sÿ8ÃÉ/[+Ğ^^  g¶í~“;ŠÕ%oNŸ9 |ihRªdŸÈç#dúı‚jÌ  'Zw¾ûƒâ¯mT{Ë,­Ñ•F£²\Â*²k%xÜ¬¬a›Ö¶Y³N=è×£/•%a=Ög!”#~1Í¡ÿŒ@DïyWè¾[”uCÌQõ±Òâz'Ø ÒÌy•nÏŞ«ûú­â$kßn:Ui¡1®óıÙ=Àø{û­rªß¼,,áÉˆp[Ó$>#[ãwÖÔÆO£jˆÊyn]ÄVÚS æÆ„ˆódà†½êc¤$Öü«ş\«u(grqõ÷­œgœ•/%Õ8ˆı?:Xêíí¨Àµxp(ï—Û•VSë€çl‘Äk%ëlg	©Ç1sG‰ÇÍê›óˆ¿"¥—*Ïı(C×™8p©sº‘ĞUZòÆËÒÏæß¶àY‡[3ØRiøÔd±©ñ@åÁ49­×µ K&Hu!ÖYa‹\İçcF›š*Eõ@GØª–Ò%Ï…h½ÃP+ƒ']ò´+îÊ‰=xn›¦g¥®šæâ«x#,|VÑcºHº¶špHnáNâtsÛ²;ÉŸ¶seO®¤ÆU;Î7*0Fù0H=×é‚W°”?1 ^eºŒçµQù$*ÜÊ>°dSÆ'¨ûÇÓûÌÁ¦”ÃÏÕ€÷IÅ$ƒ¬8ËÑ`G­R“"ø¿§ú€éº§ç#Ä(B8×ø–ßF¤0=¬ˆnwOFˆŒºnZæ½ğ$§’R¿–iI+É©âÚ*©ÿêÇ	 5ÃÂ)OWÈú’P”wú5Òw.!¿¬¸û7k«£™«åú[

lJ´Ë!ë2/rù]ob¿Ø¹>AJ˜ğş§ %8Î3
/·e!İötÓæú¸ÅUÀäš`cUa…İZÍog1h¸´t`q+Ú§^S#K‰Óµfè­3ŒR5To´LíXq#¹˜@i?K*—¿%Kª®Rxœn‰ñAÂ-•óòš”ÍÜ?†­EÎ{ıÍ¡¯e}ø0ß™º…3èÈ_xâ8Óˆ(`0îÏ£ FÚ<ØX/‹bw‚è†­6O^?Ìg4B¬³;s§6_¥¡Ôº\’,j€»7kKc«ƒñŸ¸Øvş?Û\`¼X¹]Í¶¡nÔóuqeL	câ¬juã$„ÖX§	L‹ÿâß¯+PA¹M3ãÄ¾-ƒşù¹ê³ËÓLfÌVjBù¯+½Õ‚sëBùG'TÆJg+7lEamŞŠ}@CxìÅ²Ëk©gÖ%ïŸÙ!²Î%ˆGE?¨Ò” ·ÕÑ™æ­ä¡ÎË¹.ÑÕ“tÉêX½ëÜ&ÕFg!"õ—¥?\TÎŸ†X‚æKCÖÕ]AÖ³G°À‘/E0Äù5„:	U%a5f¿}(òá½µ{4
÷`6\Á
:’	…n¥ìÎ.uhlÄ²¬.ÆÜéÎ‚5{†âæOˆ:ÿ
Àõ`G*Zœï3¼ãõD{E©Öy7ppø™°EEÿJ&ÕGs*)£Ù"ñ¸ıjDÈµxÎT£ã Œë+oşÛ‡CKle¡¯1Z€LHÀ@6^^œ„–ßàçv[“£zH}_Îû×‰ÉÃ¤V)¶p0´ømGj™şí–Ìm¤)í@›§Í’¡ƒ‹½§Txd¸_İ!p‘È"™“’,îÈÔÇÒø!‚—öEl“±™¼oe©õ~L•„¼®İW²)Á7	iB[‹ëNJõ¸7ÜÇ.a\Lt7$¬‰52“løN!ÏŒ¢rRĞ²÷P‰ÖªãÏË¹Ç b éCvSX©GgèøÏ¾ˆV_åºw‰†5\ÚÉâz©OúcÊ×İaL:@ı-~dS¸?Ãäc·âèâYyïÛğ´Le¥=•ÿAÊÛ‚;:À!º«“\+Å·÷¸¯¹ÖÃûz!eÏŸæqXİB1Á«âÂ°Òk ŸH†½[‰’,g }uO&M‚Õ|AdOŸ/ F1'”¾ëÛ¿Êğ?%+XŸrè·õ=
ˆ#cÊÇªhEĞíV¢F÷7i½eu„ ó@lE	Eyä·±Æ=…{ò!ïPz3Ç¥aLÂ”ƒ°khÿ¢N*ëïk'XÔÂbgGW‰…Øó=:ëIcÆ+ğîÂ™&„^å%eÌ:3‡àß£³áêüš…Ì÷ZÌ·1œB•ék‹Óşİc’õßÃ~V ı$2o»ª“‘‡;Ôu'S/)­`¹C
šÅŞ±oÌ»~lK2àm÷4Ö9vb6:7·bÏHõş:^9£ñ×ñ’òW0¹u–?åMr—ÒK¢°y8Êşe'/.eáºiLÜãeV >ÑD—ÕP§VºB#Øj´+^!‡Cİg%u£–ÚV²}Üı1¾´«jŠY¬M
©‰|¼÷ÜQ¼‘¦uJÖ%å]zP 0‘Z-Í}¸õKvÖ=”Ã»wYy+dá<ëØvgRyS­ÄMĞ#w(îjÖÎzU,‚+¡ïº>Wå.é“BûÆÒ]>K:˜¿™¬®¸†ğ*kÔ'Do+¸¢GÁ}7ƒöø'N(puÇ&ÔıU<XÉsË'ÀÈ<wöa/ü¿¿ˆ€ƒ‹KÛİO5º¿z–h$.ì—>ûE¿ü qGÀï$óı­9Fšàœ0Ğæ¦VÂˆb!	—-èag`ĞĞ?‹ËÓ~e¾`Æİïrh°†t ®|¶;`NÈŸ/¡š­§ÔBrÕVKö‹óT‚aÚ®"^áii‡l”?|¢­‚7Iµr‰Ğ3Yp?ñ6.MèÎ=lûAçÇ9Ö1rWbï÷ÅøTÔ£¼a_ˆK«GŸ…“’Ök‚›Ë+Ñ×|×xDFmtqosceË
¾èY~º•ºç"š]¨ö¶¹Ê?½²NJA¼Õ¯y¿íÀó§îå*¾EÓ®ºÃûÉü8&AM£r—T×àÿà·¬¨°’vx³pAR m¬4ULøñ˜ÀYØrVtê}‹ t`T'?ÒÚæ¸GœÇZØh^À”±¨6/®$OÛİF]·©c¾=ì}E`Ûh “µÂzà¢ç7]0|¦¹Ô´¶ í¶ƒWâ5oÆ(âçñ¯¡G+®À1ÁAºd ÈSÆ€‚|˜zıü0	åXÂ&ööØ»-kŒ:@/‚Å‡„,‹~[|»t©™dY0.¸ËşBgá›QÒrØ.©arRh|İ!¿¾ü1Ö -È1ö€6tÇjAíûYÍ˜7µlèAé l1&È’, ]?çÚ¥cƒSÀP*¶…´Åñ«AXØ,FĞ‡á°ü7‚Äyu»DÅŠ¹Ğè¡OYÃ¥´ğ  f KÊî§:ĞÒìzX*şÄt§ÔR+µÆf6–0^^çÄ:U¶¶T|ÿ’ıh:/³«>GÀ€cÉ¥}<¿Œc%ùçŞ¢6£öÜ²òUİo¥<_]¥YA,U9…ˆ“0²^AÂñ²X_ –Ôáçª7ÁÕq€rÛá¯w’$]—¸û_äfÚ¾Ÿ÷G¨·lş £“{È‡¹5+ïµÆë¥“<õş¤Ùÿ ¬Âc”‹‚È9†Æ‹Z4P;Z<¸zT ¤uˆ×­¹8Ô·Ãøâ{±Á2©#İ¿ $K®Ô1"Êß8©ÀRé¨Ü·,fu¾ßú"–¾lÓÿ£lç	z½ø,ÔÁêËUËù»Ãl+d7¹áP×<Ú0µ„À®7o¬d–§ˆ	íHl‹Ê1ÒpKúFÜ6=€BÕ@{Ó¼óIÁ‘/ËœÊØ/èääÄ¤’†\i<$,[ßŸ¤C%µTMñTİ^;ağ Ï$Õ¯ĞÇ|’"2d¸<Q\Ú>íWBÙÈÌ7é¾ñç<¦ñ?Âg&\mz³XƒF<ˆºdyz¬ƒ÷Íçç¹½·®<”½#¦PêE”½õ’i˜Ù‡5I½1¤ºé©ø´.ã6	ÏòMÏ1/7ö®á¾ş1úuâ@à4Ü7r:WåØ$¯ıœ“E®Û#ôØ\!	ƒóGa¡á¶´Ú÷}ë§`­NãÚ>‡ßŞ|EjgîÀ,7B{4Dú^ Q’Y6jª|o3^%+Ğ“ÜÎ4Ì	>>FîiWÄ„h¶©ÂœÂY´˜ÃéšdÑœ{Çß€Äk‡¬dD$µ²—IöÀñœ®şT»iÉeèuF™<±‹¼çBú¿ª ›’mˆ%ùnûyXñhsVä*ëµµVsû[b±¨#Æ7Tüb°)'q$mê·G‘6M—+ “ä|‹Eîvi³öc ‘¦·"6ñ<V²œ‰:´jïczÊS ’†úöl)v"ò‹*¨‰J	M™ıuàÓå¸S˜Ği½'>‚.šp[Ë%®nTá¥Ï~céWş)KçPß~‘õ3@òÒÒÿÚÂsK}¼l´VJ.Øk—_ô&7è¨\¶/;É¼×¤£ÁÏ©D–ó¡ƒ¯ü³itÚ¯êöË'náU´=›{FÓ¿©x0”h"êI÷¯ÿ,d¨È2šòÕ˜àeåĞle²ÒÇ~-ºt#9N|ı)RŸ˜‡¸Tëô¦nàÆLX´?ˆ’ùÎ+ÌãŒCwø*iìË‘TÚFgóNÙd$2¨Â ëÎŠ=1X¶?Z—CC¨­`øÖ]Tæ_}{&î±Î ö ƒ‡¼Râòná^ *ƒwiT¢ v]ÑÉK³lÄ‹Ó°ûÒãH°B¾!ç°RW‹ò 2s¼–ñ´bŸŞÜ)÷Åñ2r<v>o@¸ÊyN+´‚SÆ¬ø´OÔøå|	ò¤ÛI`™•kÂb wÿ„J±ï°oO|È­ ÒV™ûà@wßTï6Ïßp­¦Åwé®E^ÃÁ`£7,-TKÎšK\~P gĞé`‡@ÆOöİˆe/26ï¯/ÿÿ$IÏÿÑwíáÊiÊeu‰iq<óïÔğò:xT	‚»X7ö§×İ lüºÚ…şb‘²@K#ÆY)¼¤V/µ½¸Òaè†RÉt~t-Ök©„¶MdlQØ–öOB”‰#¶Û¾á¾Ë9îSy3¯1âL'K;¸aœp[(’<_ùğVÌç[÷aäQH½é­ÌÙw‰²—nk9kˆç€0lsgzØâuéBıª(]‡‹,P3½ÒwÍ¶¾_¸­!-í¦öfüG»Jz6ïM=|@Sı¯9*?¼o¡«§oœ}ÆiŠŒÕ–4Ñ%­íÆH±Pw56]@­P‡‚‹ãìLØC5€—q“2e½Åß*4rË©&–'zU‡ÇŒX(HAêZ.¤DÓj¶^İô­âíK†r×Ç|#ÑyT_b|^ ì%dÖ"nñú,$§\Üihuğ]á |9r%†Ò¡¸}àTYÀ3^›ò®Õ=½ÃÂ, )»†§á{¼ìBnæòÒn7—ùú½Õw-C$yå}%ºÕÇb«B?”¶ÑŸ—–{-ÎÿO$R®âzÓf½.!& YK»áMƒıÛÌÅŒM'ÄNL=C^hq{<_gıŒÏôĞ—
™Ê€Ö2^™ãígÜÂaZÍáÏÉüµşmĞ›Ö2ôúZ	'ViºıdœŞÁ]=ø6½°›JN	Ö´–éI°ŞˆA–Æ+œ¥–"/„ÿfÀ§>÷ßŸg‡õLJ(UŸƒdëBrŞ g{§Ù }àÚ\¶,¡lë·Ó t-?]r”Ş¬”ë±g.¨@Ö^sÙÂrËBP™ôÛ	İ:nPÚXÃHâ—¾'ÎOú æ„‘'ıØWšßôE_£çÅŒ¤.FÜş/+S*yh¬ôô­ŞrÏ—]ÈdëœlàåØ‡‘Â²³`oäóó¨›[ØïäsšÕıìÆÂ8LQÇTq.]…9 ]ª Hnl±áë¦–E&%Î?8şenJ;:ÅaSURÒªPWh-)úX›ı|F¨É2€İf6ì$„¹®¶"ıª3ùMy‘-ø×¹{¹¥Ä~N¯lníäİx–2û£úIR•6òb¸wUb'¤ëã[ğ˜Å\|Kh Y\‰-C©lko'fˆ`Ë¿” ã"‘Ìq ‡\9jTÜÈ}YåÆ³¦›Îi6]‘Lp¨ÈdŠ´`÷_u öà™‰ƒö›Èxˆñ'ƒ*ô¿(N”ƒä9ÕM¾B²^i‘iÒ¿ŞåJğğ·A[.•ÔB1ñ6]ÂŒûşk+úÌÛ|üpXî 
Ç%éØOZæ	ÁúÊ‰°B0ÅÃ ‡-ñáú||¼C°ÆênK_ZgÓÈ ä}…|'—.¶*[v9aÅ`&PÜñ,¶%úáÓØÖgÖÂQÃb‡jLTÙz_Ø\.ÊxŒâ¸Èµ&mKQ„¥1>~.ÖéUá.û¡š7#Uf<9Şª8^è–ü$Q½}Ø=”<uuÁL} 4FK	UgÅdG¡gĞ/İx%Pgù3\8\­Á¶ŞË³ìĞ=éq8Q5Œ[{~¹–ˆ7e<LšÃRšº¸B!|üÜOÎ06ÒˆÕ)?XRÛÉv®¾HõsÚWB;=F¥ÁV|2E|ºå“,îC ] ~e¼J<Ë·Y]Õæ¥åÛÕ~ø¥!Á¶{ö^¥ÌæÙúbñƒóßyPeüf=É&eäë‹ÂaHd¡ÏòÃAUM;Û9ˆÅ×E€@¦%¾úà o–ƒõô2üÄ±¦L[•AkÜ@Ú!vq£¶ªYÀFF\i2ñâÀÅ>¿$[´¨ş…şF•âÔÊH‰šhÕnj”qëö}tgÿëõÙAŸ´9“’›<Ã†F>Ü¸I»›Î»/`¿©Ú´\‡ÇrUZ$ºi²\qÓ¢~‘;¼ï½’¸·rÏ¶Œ'xÎ‰K3™Gİ…ælJœÙÎì¥Ÿçrncıeû@:¶ªEúÛf81™²Œƒµ`q½×¶ò_k2Cw¢÷®Ø T'eğÓQ­È·˜ºòìì¢rc”ˆ¶Êöòly[D`Er0¤£ÁtÊ[Mp=Õw/0lĞ÷Õ¿‹6µM:æóÀ¾y©è—¤ó²’	LòZ’°Qg*S•zSF Éf4î\GĞåÉáG›o¶ÉQl¶¹—qáåí2ëºÕşÅ´WŸH]RÊT¸-F)ÚÏ³‡Ñbì$q_êëèğ'ÀqLZØùxì÷f»«³âÃûšzê ã]Ï<%tÁ¹cÄ=F–Œ—SÔh5¯xZş‘µÓaì¡òˆBUµ¹^zÍöğ¾`)£ôÛü'©n7işÁıñç°W'¥›>xxq­`Æ+fg4qq­P ç‚}ÄB<`‚áóÊjïI 'Ú·<¥f\Yû4\\±™ßğ‰Ï2•·ÆVöîÜé­×ÌÈôŞ`™hW¥Í×íH"l''4D"SôP0ßBø²k mà~EËâ+œvKD\Nt6÷'ˆÅˆ²­ÈmQöäN×K=áFU¼Ìá^yùNjt+xc3EÂÌüs’/û{Î¸{Ú0òj)ÿl˜q	D§0çÓ®ÖJl|Iuìñù<rš¥.åÈ:'Â!ËyñÚÍ©’àÜ‹_uKEö7É™ÆJ§h¯Õ?×óÂ4(h?×Ì~Ÿñ§„C’‰iü °´Æh71Öa3ò×ÑÎó¼&Ñ_Û¸“îw,E-ĞÊ_LGÈÓ…&ûµ‘`h—Ô9óYÉ$-nšş6f'/ïJóîæîPl,…‰L«İâ—N¦pg-.ú~ZU~¬€»S1øV³Xë}Ğ1×%Nh<ŞuW2hP~°É¢îuÛîÌîsk}’Â[Ï“gêR3kËØ/à»}TÌ Õ³ûÓÎ¬u–Ìã½ëøÓ™‘ÉHâ „hñ*æ¦–qyŞÙ¤/GjªÎıög		EuÁC`õ0òú§Ğp—·ä^Şâ¾¾
Ê ƒ”ey8Š÷[Ç<öÀ#EºHOšOvqÎ–K“èîÊ¦¸Öâ¿ëB¼DG­ÔÔĞ(s¡>¦NäÆT«	Mş›ß,áó¦ı1ÈÏn¡NbõÚÔš¹Ú¥š#Ù’„bb©í^'urKüŒQtÈ'–ÍBˆ]~¿yÒ=°\»½*×› ¡ÅŠ';''†
ŠwLñ¸·2?Š³îhNÊ6ŠŞCøº«ÀËm°Ÿ“zZ·ZÎ-"îAâkdH_±Œ„şP¹^+¼éá¬£ñjje“˜İ·Æ.€¡.;‹30ß©¿¬y oZ¹<ºÉáÌ5¶ï1ê$«!Ÿó:àëdöä…$Ü>œwà"|%‡ûuèîğè»BÃÏ|‰"³·-ú5s¢Ú"S®ÖÁjZ%ëIrÏ¨Á‘\,ü÷ÿ-¶óLS®±‡¿9wÒàÇ¥GÈ{:ßN”? ½¢âQ	gà‰/$*6­À]İØºlİ\Šj<]8õè
€êJØF½xû1¥>ºøMRı­¹¯s_u¿f ¬µ—')®_©_ç8 ³d6øÑğoÚŠZ™şë)‰çZ3Ï§lIë)CqUK16)2ıììsXRìòÃz,[}ìzeu—;¥²©°Â±hS|ï§xi>Ø¦&A=‡ŒĞ”ù|U="Ì´gYÒC½×´€ìönW‹Ÿ‘ˆR¬­¤qx‰=§óšp¤aá¸RìËÄ¹ö&QËfán‡o&ˆ8ÊcR««ğxD?—„Ÿ¢³‘ ²I>ø[Pä—q ùçƒÅû;*oåÖ¸YöTù–/?4Â‡ì!®íI¢]¤²Ö4·>éiíTNt£î.—ÀşÉŒ2˜öÔ¡¯æ]4 *Ê–õÿîœm4`õC(¬·ğQ"Òß
Y[·gAò"ÊsDX‡îŸgãæ3…H\^S#wÄwÚs%
ÉP„ñXtÂ2>Asìã¢Å"’Œk¹ÄK¼—XÎe‚+ozÌÚ¼c$-õÇ#Ñ‰]¹´" KUĞRÇøE,?ûŒy?èœh>!tÀ½XÊH7|Àô+˜U^;ı(§ä•~ UK)D~n`ìäCd;îgtàîÚ‡JœA0aıàåÈJíœ+Î-Z*@ˆ îF†èğùa¦Iù[ èa|¡e¡ş\A ¨*æ]Š†k%À±íWòR\Í“!Vú«h®{|ñÉ¢[ µN_°¹âùå~Y"ÇE4*WõÒiÇ6š ÇÈÄÄIuõQÄë©Õíª¡„lÀÑÙ´‘1şQ…€,ĞæÓd?õ;~q’¬hŒpYğc×]=ñÅT[	Ê¬Ô_ÒĞï z1Çú^‚:x7|öÂr®ÔIygzç ,¦3Àé‰`H—ßjÎuP÷9	3Ó´…gĞ0¡ÚĞ_\şÑ¤Ã¬NÀİC­û*À˜b¼ıË§&]Â4e,3ü«ÃüŠ_§ğ1Ö¬›,A_q]›Í4Øjê&t<Ó½¸½åölJ)Tâƒ9ÛCàëCà£O­ªq ?ƒåÍÑü[ÌÊ™"ğPqúÌ¡«ª„>B»Î—	¿ÍÛLÌÇÚdëE~x¡ <¶¯aÒ„rD,G‘R6yÖÀÛôš½ âÜ?^HÅìEK*Ïj·XM¿I,½Â¾“a„’€p¢QèÒR¹».YÎî«Hıb  rd_kB~Q·Ó*ä¯O¯‰Ê½É’}åJ&51g=ã¬ÍócIŞP‡›ˆÉ‚œÿIIªÑJÂŞ½m ›T¸icJÇYáöK8F¨Ò¶¢Âm~O)ç#šÔ”Â°’­˜óÏ0¡|¨½”d¦ùEËaÚÆÈMr†?ÚIYzÚñ‚$‚ëF|pé§Ö¯9‰
…“v?~-—×Û%@ÚÀËôA>&4Kã#5bÕÍWBM),s¢I^zÑI0vDÆ°Ô
¸ı1ğÔšü¿üL?f®×îÄG÷
ŞH‰fôt8ã¹¼”À:¨b²<Ï‹îìk mD…AN¤Ê9uŞô±÷®[7 ¸ó*<04‹ÁÔHJc¹İÃéé˜ æÍÖ!†:ÓÉğ¹y={Š(âö—Û["tü®J?Y¦G¹¬4Ù{9I8p†ıì~)fcË÷ø¬A„tãÌC¿iÑ€ş}/–ôoŞDW/9"=S¤WyŠƒ/³§_±Ô«ç1³ï¹|HÇüóÌÂáqî ¹Î§§öj'P]í…ã
®R£ôPí¦“DIög âí³Ú}’+Òæ`Á´Ñ>c§ñ¹	ÁµŸ0C¾aQó§@¤Ç˜i‹cSJ üÎ’ËÅ;¹ƒ›¢(1¹èAF«OŸÆİê[‹©Î~n%d¿¶ô9§+³T»Å–j¹ÁÌÛG{„Nö¼+dÔÄy¶¡Tõ•DƒsCJa¼Óm Ñòì83y·¹Õ‚(aaŸGP}öhÂ†³ÀR qŠA€õVf™Ğz}²×tÚëÎr%1ü—õ–øËŸq¿ˆ|g´z@miİÔ”y\›.½ÖØæ/¬kîZ#Iã3	¢°.K ‹ğ{ OŒ$N‚eç2€÷oÃø'Ïï”¡âDâ._4JMŸ¿68©qÀŒ?yjBÚG\T‘.µRSë˜åœÂYM…¿·­o75ôroòTÅk·eÍ•ë‰êáÉQÖ&¶ÖP³…kŒl…BTÄ3&>·¡7İæ@§ S*sÅÛr<É(
ÙÃôqŞè@æ©YàôS_‘‹®0 ïÈƒ£ŸÖ¬Õ 8$¼œÜc—[h¢r÷:‘`æ‹r’ò:=¯<ûO\6“ƒf‘cÆŒ{¢Ä»—Ûjª'e4†ff6OÿŒÄûbR ¢åà 5£8ÿ´U?W¥Ó×5*`¶MA&M	Eft6ğôä¾¦~¨Éä²ú“œhs©zó§u‡2ï¶N–œ¡„­üoìú½ÓMƒñ%!>¶—¸ó®Ì¹W4»ñé]AÛSÙß<T·§Cÿêq§¥¡Ö"¹n4,ºõõ|ùŞ˜tüùQaşAšÅÒoxaB©±ßX¸Ò,\ğBš/WëeŠÑFÓ"ïÏ(XQªwğË›ÇUq®tjÑX+ŒÑ³WŸFĞÄ]$^(é'F©hTFÍÌ´?§¢è†Ì³Jµ@Ş-tvÃˆ-ÆfSÎ	õÇIÔ¬VaªÉ¾Eæ»%.åF<[ÏGş‰Ÿv$B'qMÔÚ’°qÔ× R‹L% .YlÏ†\­Ì$È³´„%M&7ò2Ô˜ü&¡IUÔ@Şä(O­®Vo-:ÉJé||?G'î½{—_&Ÿ8üµ˜Ç³9
OÙT5Êå{âlzQÇ‡ÊØºr¢Ã¤İM-	%gvëFÄ‡Abí¤¿ª¿ÉËî=˜³0Çp®­bÚD¿Q°
–é±¡»‚^sO˜€Òh\Aøéó3}˜+nÎ0éØ¹¾qKá?{éjÖõeOı%IØá0‹5I”Öô¾ –X'v±ƒ’@b ~„¾ŸWÔ´äÙMâàN'ï´TßÁ…yÄşµ!¤-uñÄ<¹U´&7±c°åÉ¤ÄgAĞ7$M¡Y²ÙŸ+èaä£\Û§g˜8ã‰À=.-T†òÎV›
ZÛLIüPE•’ ©ÖŒzêPN…ü„&^ıjB\Ä›½cAãAùsE+À,â~j<°p`<i²Ï5ó;*õàhÚvŠ!ºw0ÁLqŞhj´ƒûsÖvÚ!”´ÊdÌ‰S9.*ñ²ÙäzZÿ¡°£ûì²ôÑ3É1Õ†‰˜kµšïÏôê~h)ÖD‰ğ¼ìº=r{Ôkÿ€YíÑaÄ¿Òñ‚ôµ-]Sëz
 â@{Ìg"g÷ŠÛÃ}6q½Â$;ˆèş¤Á|œñ¬1è*¿H‚ÏÉ¥Ï¢¨UØtİ<äÖnY®Ú‡¢½iĞ¯ş®D186¢Z¨±ñ ;ABG¼«pÒÜÙü«±ğ9i{ä)\P²ö5‘Şc3ç¢¢ 4¯oÎ‰‡ »1}=™æ¢R$TuÌd€àE‡Ê‰Çl×›.[Ê"Ì¤›âsœÜ• dUœŠì¸GWæ±`ú ùâŠ;`tY}d´.C¶3P¼†Å ¾nóqvîµ8Å·Ô…|¥ò”èÍ³…òhËÈr‡¿ìfòêï<¦üÓÍV—uªhe’)wXº2>ïbq’Õéâü(ÖQS¤ñC¥	6ìè¼(â™|Ë\¦äWÛ•0ÍkÏ	¦È÷5­‰ğd5ïC§ÙcÙ€#ößwŠû‘Êí[ŞWeÌI¶|Îc‰’0½}d/RÅ£k€+?W-Ü¾„=/Ğ\UIDäËìt¢Ì:ıÀ ÕQÓ˜—P >[O´q­\WŞ±¢m¬L7Ş(]BëjÃÏ‡R%y¨bMúRKĞ¬‘×Sú.²{J£;Kåt÷4ÌUdKdZA¸|mNçNnó:•qß?ÍWõ•£¡Ë   xÑTà-o	, ¨¡€ A”°e±Ägû    YZ