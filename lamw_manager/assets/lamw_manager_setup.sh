#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2693967376"
MD5="8ac01624da26dab7b6fc4afa02de904e"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20696"
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
	echo Date of packaging: Fri Jul 17 20:40:40 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿP•] ¼}•ÀJFœÄÿ.»á_jçÊ‰3³d%ğyæ…hÄšOrL•ü;ÃomhG?y÷çíZİ°º8ÁCÑwj®˜?[n‡º“¡İ‚ú ¾z¢(¨›pîí”/‰¦/njŸ£h–O65S918¶Ó`eÀß]SqJpbE`QÇo™|7Ôä;
S3m?¤­aDRè“… pÃ´÷^­ò£`Üo
¶m
7l’¸]ìÛ°T¼í©°%=E¸FZccëø>€-Vóæ¿ÿ0áï¯¥¢!Ë`tÍqŠ¿Ø:ÖŠØ¨ UâÜâb.îâİ…x\°lÒïr4¥óéÖz_ hö ÒÎl»=û”ª‡|ÕtÇ9+ØnçïZ³rE¿õÔ¡ı/":6Ÿ!¡%ËïL(ÏÂ;‚µ@|be;P òÆ²x‰YYÅğ–ˆgİGµNŞ´¶µ{å<—}à¾C•]ö?JÒ­Â¶TîX.;gz¶^Eèè¥ì¢uN:ÎŠ«ËŒÀ˜zò[ßzî€T`y¢é75ªçÈ¬É%Oï'E]é6–suOi;*G<ëş¢¸AÈ¨-˜‡½Îk ³‹m…ÍAf’üe;³‹¹´ŸèZü·Çq56I>HøŒ- TcœôE¿JB¶V™kHÿŠZ€¼MRícJ1)6Oíï	á³0gˆ­Õ	I¤uÀ…ÙNsÃ2^–Çş[¶·£pK†iá2üàò6+æ³Ø™·Ò% J‰-ˆ¸ü+ş†±=oÆû{¿PÓ=ZÚ/eÿ¤ÑšpÉMàÄøæBÅk •<$MO	Xèôä×mÃB5cÜll|È¼ò‰—¨òKm_-UuäÄ§*68Æ	öñ2îwTQWÍ$û}Ïv£‡†swîÓ2õaváWÓÅeêüi^ò/òÏÄ‰¥›rÇÍã@ª¸VCAÄQğ8Ë=˜/÷R¶ı¦ğ1Uá™ nU{- qó>ñZgqÒĞö„WjM“Â,öB¨ÃRoßøÜ+4P$UZŒĞqö²Evv.è• ¨lØ’`Qz>Ğ±¨’Ô;Ÿ2 ó?–à÷]nÑÓBFƒÜ~“¸5„Ù¨ó”Ê<š[Ğ	TÎ·h£>Í‘jyÂò"6‘5[§¬µÆ´C˜tÃá"w}77,‡‚ãÌíH„ÈxVÊÜøfş®
¬ÏPsUF¶yúâ¤HC˜{s(úmPËÎUK?Ëˆ_NîV+%éaœİ/>Ô¤ê~!bœ9é,ÊhF²‡YSß@U¯|…‡ÚÚG †¸ŞQAœr†{N>•ˆOì!+ !y¸’•ŠNf#p]Ä&ó)5ıíù5¢8I-ÖĞk²Ô(SİµêJ{}dÂdÁ|ğtVò'DîIö]Ym-ˆ»µ¦´q)?‘¥X)‡.Ÿ°ßÉõ?å' :9vü¿ÍÿËHKc(ØdÆ»•÷
…ËSá˜Åx†gÍš7«%öÜíØb4ñ(êf€cXŸt8¿wŞeEÊEò&!i6[m w­–Ï–QıdyíØŸŠ vÕìa4‹Ñ»:m7€›$cl§v¨À?ğÚÅw>³¿.‹á²6 œ™pr[ú¿R/YÁğŞÒĞùDF­ÕÉ.!ø•V'—§CÌq¸øe¥
}Ö8@6FlÍ¤!ë%Xù“±7ö—“hŞGüÀ3Õydéş:o(Ï0€­±y;fÆjõ°Éá ¨Ç(0¬íØHsXm¹&¨“”=åô”Xğ”æ •*ö]FnRmNkL¾d€²®k´ÍıÉwÅä7ø&1ªo]E”Şœßõ÷S#…¯ÉıñÈÖ:?k¥¬qÓW[;†AÏ#fGÜ±äÊ3Éµ÷s *°a\†zWÌ¿t²¾Òs*¾]¶çëVÏ£W¯km½cçëÒ²K`÷Ü¸BöEÜ&³šTm6„DUõ×+°uióïJJÏÊÖÑMì½0Ğø.5aùV2¦ñ1Ş{Yä¡¤A›OßÔŒúİ„5’3ò¤×b½@‰¥¨9™µ+²yUgÓ4í†Äûcx9I€€)Ö9rtUÙMªV‹r.£ÕÀÛ,6›êód`ÿĞÇÌã¡~İlNMÁ
_ëıeŞ­ÙƒûTÚFÑJÃ{]D™–É¡$¯=™ÙıàÆ™ÖÍ ûjït: »Œ¦şB¨µlcí2¡IXtí–á’˜ùCBRØTÊ$T	ßërÊ°]!¸óbñ‰ûäa“$ˆ‡.­ŠãáNÏãrŒLõ×¨³óìÒ‘`á«Ÿl\T€ıÎ×€»’û¦¡ûŠó¾qhà‡XÄ®D&²˜áu¾e³ÍeQšÖ!õeãü?ŠëÕæuZ<Áë	p/5Äâ¯mä~5Šš½¬ïÔQ­ş¶¿•¯ÑãR„©Ôş…py§¤ÇHŸ¶ê®Ïü¦=²t¤¸[_Z¡—èãN–yÓñ.µÀ—ß©uO·ü
eZsÊ§úP¦8ªãĞ.ë-1^4‡&çhÄCÖ“4xâ7}Üºç®%ø’èÎ^Ôäa/‡i¼/	~ğ…o˜I©´N]Ğ¤Ğò•O-¹ÊQKšB%ö	²lfâµƒÿğşW£·	·MÒô.‡€¬³¦vÃ˜#ãKî…4‰÷'¹“LğAzìˆÕ«uÄÃö+ûÅBœšÿ¸?üú2ÌÛ¿<Ø—…M%ÿã9v½ucvd ÌÒAÜêÚ7`A111SÛóOW·¦jÊPóÀ¢È`Úz†`~ô²C»2éşº!Èx@c=Â‘'ó¥G]Ó¡ír
§]/Aø'Ê~Ün—ÆÓå·ÍÎ-të¬Ñ&m“}©IŸ·s–j]ğZ³Ç•S&4ƒUÜÿoºùŠæÈiİƒ Ñ~ºÓ„É”=<¿ywĞØmxiŸ÷7…u¸fÚ¸Z‡ÂÎ°V,jÂÍ«"$£âóÔ#{TjuLœôîÜ* ª®¾Ræ]±¦D>ói°^,F¨€vYååSıÜtkHÅ^‹6µ1âE?ŠM@bUûïÈ_9_©ŸGb‰²_d½¥Å‰U†°eÒ.ª`hùß–¿ÿN®¢‹­É+¨ñ†õf„¯Ääë­ê¡QtäŠ/Ë„ë!·VÔlÎTNu<›?9Š^'ş˜&ùCîşußÏ’|˜
ˆãİ‡¥flİ£–Î(7À€2štqv¸çê‰“6²ê˜KÇàõº³Ó§&•BâTúyªİ8qW„•i·MXõí;qóBn…ñyö£æ§ëÁ?¤Ãÿ&ÈQMïªUƒ¶àe•ø_uy¾ğÔ¾:$„ÚBC•T·OVxæ¶n ”ĞI.Ö|[,äD
@Ş®ô&ïl€ Qmœ+â5æMe,nÖ‘Øp¢S[šG8¬³Å›ÜŸRBËçMj–"_ıò#ƒUk¢T—‰¿ÈinFWûÿ':UoPú_à¡Åø¸ÎÃòqÅÃA£XLÉ‰LYèÙÔÄñB¢–w×ò¦V(sÎÃÚ¤¶)wŒÍµÙİuÉcDq*Ùê\èßÙPÎÜ$<Äšƒ=ğ“GÀà‹‰ Ü´"–Ò\Äº“Y÷bÖgŠ<  º)öĞÆR*]!] ZĞkÉ[“IŞjó«ˆèÉhdŠâ÷Ô‰ÍÁìa®˜¾µıºuik”vå/ÇoÀ2ºu·7q-İ ¦aî(;ûÒñ·‚ƒ#:®mËDÀ[«üÕ“³$¤Ó» ƒ•ÉÇwË€·}q!?ö¡-ÎÅigã<±îlgøMĞG­[²g>¢äu‘ù™¸¡ó+á¼ Ö4;FÓƒÛm´Oœ8Èú18á!åjú,@lç`R\öÇH9Ä"¼Kn¯IÈŒ"ÂÛ†GaJÙ.gg¤ÃÚ(ÅÜ –¨€úğÔL.>ÍûêQ‚"2‹ÉõIñ`šP¡kÁç/ú¤İ]O@£ÇtÀòƒ"ÎÄD9íG.ôšÙD¨„£Ş8Lõ…}´®>«€Ú	¾÷ËóEzxÕ'N¿Ê6+KÁ‹Aö	ò„?ºï3CµÎEËí©Ñ÷y|7õ“ÖÉÓÆñ|Ÿ­OÊ›S¹}!Ã-¯óÔ%ñíeb¦d‚q›5ß8îç…oúe$d<€ƒú”¼¿¢üScÆãjTªHÜYW«´pãå—-QdË¶ˆ…À¸DÌ`íKóÀ›åsçÊ9aÖ‡3W‰’ÉÑ|7ãLXøµüEÓ‰ïò¤Õ?Ìè¨8 lR -Ì´{4ä‰G®ó¨à«å¹t8ªúéªiæ³›¬?K n•´}SŠ¬¤¡‰ÁÃ¯Şö~Weâ>q‘o6RŞ»ÃØŞB;•»’|'[Í li½;¿M`õ¹„£Û×)‚;Ÿı«Úd8İqP“×ø`pnRùM\áõWhÃ®ÙdˆÎyÃ«qü’oùiv,°Ä ÙX1²‡“šæÜÀÉÌ*!şö¢ÌS9Q÷fòã€†±ù,ÅhštÆboĞGîÏòHBz@çš€LEÄk]¬ôl‡õ¶3n¶i>ŠøáÌ¦Ë-ş¹Š›ĞÛ\ºiçHíö´XwØŠI#Æ­åã.ÌÅUQÈ ÁMÄQ‚Âk;Ï‘ş0_O	š“XÔ>)=æ¬´ušw,làéYRÃÄ‘ÇŸ‚$š•ÜoE)'›`¤–h|w§ÛbÍCÿŞÆ Êáùj•ÂùĞ‰_Ê²Ö=™£ßÌ•¤»ÂÇq
 Åx~7¦SÁ÷Í÷™%wŸ~}âØV™™‚s ĞSÒr'éÉ®ŸÓ”Š4RHúŸİÄó¯³6z~‰ğ’xvØkQ³u×y7*ë-F`-Î:$ò„4Y¡Êße>ÉjnØ©MpS J‰ „œĞZH1ıá¹}pi(€`7Ÿ—ÿØ%¯¨Ê¨ÉÙ¹ø!ë:ÃØ¸RønCè0BKd1Ç‡)Ì¹î$'z$çÒ{¬5»Ÿn‰b‹ bn£ÒÊáf~q Ÿ«ŸXÆ~üºz9ŞÌ>…\Ú1•ÛÜÀÙGó_Ñ2>08êĞ]e
{¦d"<š;8¤j1‚&aÔl/¬ûQS»–+y›dvş]–H¨mÿÍƒ²9ÃIŒmwÆ!+†"jÇÊ3$HàÙIPuä‚MÆ¹èK‘Ÿşõ¡YfÁQÌ³úôÉuävâŞÍĞ‰væ<j„I9ö×UW.!–A%®vpNaó«ÅÆ6#ª‚ ({;uÙçAçÖĞ/Tˆ¬^BçÏ÷ôåDİDÛcÚåW®5,n§ŠnÂ3§#«ÕÛ‰¼äZÌ§TŠX†TN'+-µ¥î6ó©UtÖû.(Ö°XÅ';{ÊŠ>ZîÇ’SC[g˜z~µGôwÌ¥ËáCúY=Ízdãé.‚¸èC2÷ aCÂIöï£ù*ˆÆ‚ŞôVáùœóßi«ı(S/şí P7E)N­Í ‚?Çú2_'ŒÚBE£€Z8\ĞVÔè4v’c!Ş ½wÕ‹ÑjÀí;:ŞÛ P–·ÅÔ_N>>¿{rÂ#Û0Pô–4Ç÷Yìmßô<÷Ük¨ö¤`©ãİ–ØşZàÁ(Á¥xhª­AXıFØÄ•ô›ä/3~[oê“ÒÖòÅ${¸Œ×WDM59Œñøwª´å›‘Ú Ê7*i[I?§Rdµb‹Ïè›ws¹£FĞ“õ¿_{Ë¿Á<¶p[î³òï¢`ú°&ç„OÊ¬Kì}Úûä>Ã+Ğ@­çƒ‚#IF=8Öÿ½ışµNq`æ\;{‡øôö7n{Eù´´cjNÎ…8¿"|ªw[fê13àÙ6üõâõ>¬Oú01D‹gæÂE‡Ñï%ıèT-¥M‹Û;âÄW,ÑÄ
}xH»ÿ‰ŞæsS†—²ì»}×/B`ç¤X¯á0şy Ğ|°B²=<Ü_Ÿ ¥¶“Îxä¤B5ó›´'ÔÓøİ«+Á.­’4Ì½(Ñ!#l¹f:÷œ‘qÙÍy®m­Yü§êôEF¢²ø‰“±ş®è!Ü<öpÃeãxv&M+j±é)MªG<“ÍY£N#¨zÇíÃ‘l°³´ã&÷ÍÃ5¬w3sÒ¦Kêìx;!ù­¥Í‰»ÿÊİ~^Yüƒó&úfò®}Cmğ™C0; 
îaäøK÷™Ôª –€)Rtªc}ò™é6.Í(Ä~:‡Aë¿ñ0ì˜ìåz	â±›¤†˜ ¦Š *õ%SàÅ?ƒ àAU}®lKØµW@Äô.4R}.(	Šâ^3%©p¤CØeø¨QS“‚,¬Ã¬¦Ô" ­gcÅY#A˜:„¼ÍsßüÎé*¥¹O måF:_Ô4:ıîú6¬3ÕbÖ;èAnšéó)ªJöÖ¥ÉÜĞ—OüàYçÙ°¬¨ıƒoÃ»Å9€Î¤DáEj$'!CZÿRuµ%hSr3‹\çcŒ#â’ÄÔÒ¡¬Í
pKêN¼„¢Ió”_qEkÎóFNˆºş²YC˜ËuÇIÙ:àJß½‚2fŸûB	C¬¾
‹;qç»ĞåX3åß'õò´ßáâcÏoÍ§ËkÅ^Ñ®ÄöpÏpÜ,ØJŸ²ß#0sLÏ¼pÚù%wõ…×©ØHâÂ$©„\'ĞyìÖx…şØsÀãı¶•³2´eÏµ’…½B…guŠ!I‰Uû<^ºéê¡>N¢#ø{CÔzmÄ2RLlU3÷ÅkËyñDÄåÓ3±Åÿ¨~®š7ÿQ/¶jˆüÄĞöTæ#pàb%ÖõˆÊƒ;Â	äôÒÖXíüÉ™şÎ.gÆïs«m½%¦æÅ•_=¦ÆşºÚïÉò›5¡µ%µ†€.T®pî¾obºõûÙøTŒŒ‹}~ùGçœ3¤†Ì$Ë<ësmwÍeCçª×‡5¬SZIİz¦CUKk÷½İ¦„>Nç•lqMQ §EQÚY8¾£í`§9ï‹ûaêp(³ÊˆáWë½{ªd`.3¯rˆÂ{&HBŒ§qsuáØÑÓåP"¸.C6¡
è™Œ`ó¼‘ÅşæÛû£ŞÕäïp<"-S¸Iiÿ¿[© DğìÀÔ«egØùJ×¹?˜ ƒµù6‡œKåœ²K¬ÂŒ[ËİUT0â
•)"VÉ.Lû÷ƒ*ô_Ö]DLÚ.Î¼f.$ffdãâD°ò¡î}šX­›8é ¾éÕ7uºÓsõ–6ÎWzUŒÚÄe¦	]fOè|²>µİÔÂÓÙì›9±ïR-ŒIÉ7À&¹š\´Ö*9¬¾ ByO–Ñmà#4‰¢næ™’Ô1‡g=h®‘9‰52zµœvW y±”êÄ^'ÆÕêµØ°œ	†6‘‰ ~7gŒAÔhòÅğ…ø	Ùş¢{Ì	^mzRÛdIáŠ$Ñ¥Õ‡ùó“ì#ˆğ½ì¦hà ÙzÕ›LX¢ÇqzåW5ùŸÛ– z7Ãj©{Cå›ŸÚtõ¨vìíUÁ†C¦‰=*3,\ÈÅ8ØğîiØÂûÎ½ŸYMk6mz%ğ7#)j?F¨Oô^÷Ial‰ ^1æÎ[Ç7(¡ˆrõt‘£kKŞ
»|@SGRàİı·ä,œ“*ºIÚÀ¢¨ÒÌ—&îÍ¥ıŒf‡C¾o#³|ö é
ÓÄû*¼ïÿ`•çuÖL	1Æñœ¸^‡/cç'ıÒMİ“ÎÖé»V¦8H®¡İãòY§£Jæ{Ş4YLpèº­š zÕ¿w8­µ˜L—@ì¯Nê~÷1)‚	1÷îÂ\—§pŞªûµôqû”µKía¡¯aŞ¤æñ:¶f¯±I•‰`›;ŠÎªê“J†MåíŸÅ¤|c½
êÑŸœ;*K	.ğ0Ğm¿ÒÚ=†s¦P{I‰o›@f·r9·‹J˜ğ˜ßÎOš„°}-¶Äc \ñD`¾.tŠ_MQë‰™eÌ²~¦ƒŒ÷A¨cë†F—U.a­‰ÛŒdà´øü™?“7Djq"¬NšFZDhœéR—cÉæteV³sß1¡ú—[0›$r¯Ë³ŸS3*«¾>İÇÒ…­ÑĞ@5u¥–PíH;ØXòÔ9Aí
XÊJ•œµ`¼ÁÙ~®míÜºªH”,=|Q…÷+ô9d¾YÏÍ[’noŞÊ}
*İ±±µs@e•yoö8ËŒ|åA¥77’ËıPg^†òt_c`ßì;c‘æ)sùD†ŒjdY!ò8|X2uêjÅZy¯HßÅã°à,1àX)’• FÈF6O<æi´a™ü¶×Y|XT»çª1œçàoÆÊŞÓH„÷q¢Y4ÊÉ@jÍ»(ºdk§ÛÆg˜MÅ5™ÛºŸ<Ğ,Â¤IÏ«ğ×Ú\EãP2¦TŒ›½ÂóäÍÉû¤?FÚ_mcCVû¢
2¶„’úˆ—ë§_ÃPğF¼¦&¯s¹'(‡W—f©Sûy ‹çèÙ—
ªd'wm¡â'Êc¥öZ˜Ş4¨ ò·„›¥ã/QƒäB.DÆ°½ô*Èá£m¢ã‚j²’8°{ÏC*	|KÚ‡½i²wh:ÀAÃÔçéÃRL¢$1C™ÂÖkA@¦xºş™Õ«>ïïo›‚‚q$Î=W)…ó{Õ ô{H’;©µrß ÕüÉ"RœºM¢I\×(
çğkMŠ®ÊÈ@!Ég,X.şØà=×Ü¬5tF£t{Œ«Ş[óÇÅÙJĞTñ+öõÈĞç¼6¾¬ Ôa¢¬]k€yTƒß¥ô,!2ë+QBçóşã)½V×qºÀ«¹O³}"§Ÿê08XçycFşGú™¾ ±6gM`†•™s´ÁI/;•›:fHp€€V·/4oÚ7™\<t+¹Á®/‹x óÑ¹í±Hµ§/œ"ùb‘åÈÒŒÛ"”ˆ‹q²Ç1ÜÏÍ¤¥ZõÏv5íÈBp[èáÆq’ÙçvøÙ'OÀ5æ²H'j&ì]¾êÿJû€lAÈkÅ¥®ÆA+h	şš:·ĞJîüíxAÿ¦Šå~¸…™<·çq±4Zòâ’eW`dä5ê‘uBÅ£=L%¼Vï¬/Ó•ú2GôÁ÷½oé^‹ÌQUª¬éñâëÛáû`–ş˜/6¡3>e;ê·­¤‰ùî%->Ó‚“?İ|³ âtÇa¶Eİˆì·é)@e	f3Ä?˜€ƒã‹2Yå×ßìmUƒ^wií.ÃÆ}5õkfÇé×ôÚœŒ1Á$ùƒ‹ÇÑz=|é€ Ã*<']í¹ªÈUuŸ“	XŞf¼ÔŠáR„‚ïw^·GŠ‘ñÛP“Í¡²q+\¥ª²ãFß‡YçU™‘¹ã´´›‹diRçsÑ¢É!… ‰«Fi¦+$
}†Å5ˆ¸Á—ßúÀôãîZ«
Ô×aCeD	EEY–è]¬âÖÂ±S]íN^oõŠµÏnèm…ãªo 
øM¨d£yûi;ÏRü\ç§ïSVÂCY•ÜĞY7}ï°Ñ…¬éöAƒQSÊÍÆ¹Ya :|ôh8ı$˜±Pn¶Tæ,^yê¸Î”„,Óâq¬8²;ƒï¸ƒÃ¾üKñv”ÉƒÄ#§‹ráâ¸“ÄŠoôš¢;ÉöS½®3{¦Šõ~'ÁğYÏ¢\&Ú´Qq¯b¨.#Îqwíİ‰ÎÃHVfùÑÔ’nË•èèTØ²c[¶Mœ´Ã®³<„ûÊ™¼Ô	?W÷¡ÕPÙ÷Kœq„½:ïÚUÇN3’“qhŠOcgÏg¢ò­‘°ƒıÙ9#=¼ü>W·GN¡‘Õ!`3ÑBB®œà¨~±^O”[,Úzã*ß1Ñ¢<_Ïi,œ7¾ŞµúhäÈìôúÈZ9£"\i‚-Õ0Q©Ìq*bJgY³î¤+ñÉ»K~ójH–ÜHOÅWit¿BÀèe¼>Çs!íü£Õi`unõ[Â¨İµ$Q©´â|G7]öÂ˜İ?YıÑİSÜƒå lÙP!ñHyÎ8¬†•‰Œµ'ÒMEàÚ>ş«91)5µ§ù?H5½uWÙeˆ	¤¸ƒÒU|³ğ^¿[Š½…¢›ï½wØ}²îÂÏI%°ÍÉØxËÔ›ea<¥SÔ+—Ak¬%Aá§t¿Å{†A<,%³sFÅ=ÃfßƒjÓ³Ò°rséB`Æ©¢Èr®Iô¢‚Léu¹%9î¡Úí¸p»]¡ïa®AaİÈ|´İNºKàÆ4;ZŞş‰|ò‡[Ä}{´sìgÇ"FŠ‘6Ÿ'.Êá¢i(İG>ì´?’±<Ò­óÈaŸ^‘€±şçZ&O­lsÄ„€œu9fcé3šÕ¨Ñ“_e€‡Œow
Ğœ˜oR¬•"R´ ¯ò¥·ƒÈ²iù»úÅÇÉ<h/ºÍ‚­/‰²²|c?Y¼³}@ä³3l0%jzL\é"s£¢J æJˆe=«ˆúDI¯Kì‰‚$%®×Hú/tLŸáø_±šV²’XÆó¿×Ã ^„ºèÉ–1cœGze0õW¦nvÂPç˜Ñ;H„ÀˆM@A 3”É€ó¬#ğ·u9tÃ¸K&}ğ[Gƒš_rR«G¯Bó}ÙËålÔ¶Ş‘àZ	RôÑÄN¢İ1Ç’şiû* PJä\†ÕåºÑ.ĞÙÁˆìÎ|‚èÅœ‚x)øx5.Ş«ˆnæ¤6ğêÆ3Ô£á«˜q H7äÏb}Vfæ©9õ‘_ÊeoZÒó<UnOt|Eêóş1k`KËSsl‚Å;Å®”hûÑø¾š%SÿOÔQ ’0eŒ°ĞŠ+åÙ<¹İĞO©€1…/Ûš» ú¤1;ã4Ö/ŞH&ÎÜ¶v÷½ğË@it
Õß¨"KB*k-Ë f¹©³¿k€ºR†‹œ´/,©é€ĞM§dt˜¶ÎT{ñ³Şà¬– e§r3¶uOqŸê¯±&bÃtöÕÖ¾ÊÀ ïÔ{åûÍdÉğRôFóá¡¥ê Íìwà"
	0»Uo8[êC; eÏÔCâ™}1mc¡Ù’æ
K D~=Ûsx”ö‡Íg­§"ä»÷8Èyª\ˆ"GjÜWúŞ˜öXæ‡JÑ™p-píaõñVŞ'F|Lí8Wöx¯$²jK'nHnñíea®Mõø²É€×piá°­„‚§Îw„Rò¸,ZÎJ¬±Z#¬&ÉÕ•6F2ınvĞŸÔ8÷ÖLCkÄ$Ä(ÁÚ¦TWŞa×‹bEÖ¼\Kßäc-‘Tã¿å®öĞÇØê’0hÏÕ1ñ&gàŞÌïì’äö>¢4›sp}½;À÷—‡j"«ƒÚŞ€#! ¥ƒ¦wòíâò'.“9Åoôáöë*ó8HæÛ®ùe:-Õ™àù;ñNÅ}XA¦CJª‰ı‘yÖLŠ†­¨„Ò¦¥ø~ÈY±:PeCòÓÃ)j$o„ıs]>Ú 0KÌ«8Â´iaìP›ğMNì¥©şŸ[Â…–â¦z³1^3Âg–wß:„ê8FìÌî/˜‰('™—ĞvhF8¤>ìÙ°¸]1¯l{óí„gšê~en³ôk;k¾R”å©¥üŞcå’q·ZGß¹ÇSp@ÂQk×ÿE·äÖÓŸˆx(zÈås/È?fø¨üóÎ5šû ÷æh€)œû–é„ V?(Gù&);#È¤5¡„ÚÚªNyP4«+š¼íèä—…L ‘éùx:Mº&ó¨òÌ¾*dEÆóC¥İ“Lé‰µ_l¢qåîÇ-S¡D/_YägµÆŸNÎºõ(	Ÿƒ5²ğvrqœı7}‡ T¡>ËÍ>6ŞÄ1š^Ù§u÷gOùÃj_t*Ü³à—ğ}nÑ$-û¤-¸/èfÚ¾â"™ŞĞÿÜBpáßP8 ÷•Õó€¸¾ ¦ğ2Q|Šr/'Ç‘\:pW\rÜºÓ8Gúxİ^¿ÊÌõ74W;’%•üÂ3™ñÆôNùVf‘©¹:êçŒ#"Ô
æn’ßtĞKÚ× åz¬ZKØršYs
ƒš¡Ì¿	w)ÎÌ,:Û ìGMÆ¾3-ÿ1À÷»Êl‚ÿ= ¯uû¤øaß;ÔÕCšƒ… l£_¡7€`Û™Ñ®Ê9ñxÃ“!c\Qñv*öiCnRV2gÛø€ŸÍ•êh³=lz³8C
ïl*Ï1ĞoÙˆšcnÓ(:e:‡V%µÄË˜jT
êH]ĞùiƒR0ydî«¼}É*?`Üî!I’[‹øIòdC'×º´¶Â^("²ÈL /µ»}|FÜv9ÑÊOo	¶ß^C,/™eİ®hÉ`0¯›éÂ~¾¸Ée6Ê(î&gœ×~)Õ{oÃ{ıZJƒÄ—×aÄú„ÚZ‡t3³í¿ôwÜH“Ø¡˜çuIáAÇïf¥PL*$–ÜèÃ6ªd„^$…ÁBóŞãXncjÂ5`¶êBÿlº)†”oùEš;–i‚Ø¥R¢'İç%*dÑÓ‰Ó4„tİÙ‡PóÈqöÁ©oŸeÿÖMÁ3/Š³=²!Şírîÿî¦¿aEeöIOÎ{âN’/§Íz%.¶Ùº¬ötÌÚa]öo©¹ÖYJ»åæ®­¯ÙS©P›bîÎ5ıÌ,BœPêvàŠ¾
§úÍ‘ârÔÚöÁ{UDõ¹5•¹;†š3úWMxe"¼ÿ–_-ym…I­”Ù2~‰¨µâuª©_gÜÜ³Šq“ß'Ã="—#$€ÚgõÁzŞïÉDEv«Àˆ¨”}Á*‰)”BíŠ}÷IU$øŞÅâ—KFÖéÖ 9q-Ö¡ƒ  Ä¯!pæPÿ:÷Õ¢tÌ«à z©7KÌØJhigÚã¼—V|Úm¼.Pİ9éª&„l`p„nHÊ?ˆÜ±¸^vWQVÁz­,›QËÈ§Ø$bÓSì•%é@HX¤+ÚWX«ëg^Å‹Îp¦tX5ü8€†“¡ŞğÎˆmÚï¡-‚V5‡¿U¯ÀÍÀ™X Ê¢ğ½ü5şi`Ñ´Ë9½ìß-jÑ51ŠÙUCœÇ53•TA|ĞŸdjp>ı8¨£·İi§Øa´$ÆºR¹Jƒ‚-1\¥& Ñ«Îgİ%;g%B¿¿jÓ¸~¿3)á~øïrC@á"ÙÚÓ m>{ˆƒ¢%x¸œ*o•*We¸?æ‰›Ş]áM8¨rut&pX¼nìq7®ÛìÂ €!ªt­KéóÉ³ ¦€Ò®$Ô³`	;‹¼¸z ùµ4YªµŞßrnĞl6ÂšMPúaÚ,/JS¡J0£&…(vò§ğÏ7{8SÜåÑå$—*	şú,Vì“""Á.%Ó //ki3P„4•Wmû®L†m›ÈÛÅ°~$¨`øåÌ¬d	cQ+ÀĞšü$àôøøÔİÖXcåî^âÜ«X·i[”U=3Àl/#­Û¡âAÆ¤”ÊÒÁ	æãğ(È÷ó«lBYäEÿ{ÄÍÚWsv-í¾bØÂîñK·—xóKú‚YTÿû©Z6Ÿøû¢"€³áOª rW¢àè`ª]”TH’6àM|L.àºx˜i±DtG¸X£m|fk­*è0Èkƒ·
šµb:ny£Bm9®' (R3XšÇ±•A(œïï|Î[f#Üb’v·Åb‚µz#úş3mQá0½­´!n”xAÅá¯Úxÿí>›?xêä®«Q{RË×·øó­'‹w||~¢ëÆ8ÌyñÒÉ‚Ú°lbƒÑnÃàBNp­x`{3Ï.½ÆÁ˜–Ô|ÿzú·“û1P¼ Š°MS¬-Ö&¦_®ßüÊş2p¤¦*kCL~*€SÄv5Ÿİnì?w˜H<fK™ÂÒÀüpŒÑ—î{äÆ8VÔWŠè_×ª	Ãã€SÇânsƒ£ëID	ï!œ°n¤çÂÈ\+áËü©¨ó@Ã^‹TÒ¦ºlQ_Ş×¬èÕ@G0Ë$QlĞŠÄvõù¹-æVv1ÆÒ§‡œKL­G“C!‘S©B&/ïğ«!œ*YK]¾ŠÖÎeüa’eå[7ÑbõY
pA{‡^” ÌÌİ9\^­À’l§â Åé±‡ñİ¬ëƒÔÒg×õTgRÓùô-á Déï“Ùèš§Yí4¨X»2ÖµhÔìB¯/ô¯ûîd:‘I¡Q«Ñv¥à÷ıAºvˆLëLC8‚¢şM¬úºª±8S+†N·T´µš!ûÖ÷©‹lÙƒ™œ`ugá§KfÙv_½¸î„Xd0İpÍgĞ­ßÊVÌãVwG¯Õy2‰«"%šÇf:
«4Ÿ»!1â ëõCÈZ¹(Eº@š¿&£‘¼ú·–4¸¥‚¼âZú·‘4Ì#4øE¿°uK÷v-fİ§®EŞlêæ,<¼µKÆE|%È'Û¡{3I¦Ù¿w¡¿[Fën‘Dî7|í‹HjZÑ3¶"U÷@‘üò»yxüf¼ì¾—š[&[$×ääC²çÅä»¦=%­>Në\ÛW±'×?ƒV_=³¨ÎóĞüqò²ôÆªşá]†¾­™Víı}C¶*–\¸Í¯	áÜ1&%?p-µ?öQÒĞƒwr¹ñ­„É¯*VÁ€—‹‚•|Í³i®ÜÁ7G:ÿéVÇÓó$°\¡ü<¸ƒ›ë$j:Y«N-¯øşs_$Z´š˜HóñA_«¼£nEÿØc` y¬îæYr¬˜¦yPæF ŞåäÜ™{´
]¹¨£ÇQë6}½HÅ`ŞæÑíûëRét¿%çlg8<:Õ)‰¶¹÷|¡“Ô Â—:ò°°e]/½$9ª,*ì$1ÎøZ¹ü®în1Ê¹*7ráP]’Qh©|“Å¦š:¡÷oÊ^$ïF¼…‚”¸oõd‡z¢„¨èqô8%‚ˆƒ6bgŞ™ûÇ‘ÒÅBmˆ
ï.p·^ï×ùp*=â³(OÿR@¨ŞÒàxÃ…×€¯E«Íİğ“!M4C{Ôe?g{¥œâ©__À¬³KîÆäŸÖP‡ˆ§"HÍ­.¶Ër1îŠ^5İHi¨NIÎ9ä˜
·¼§È“"R»NˆİMøäHÊ„ığ#b2eü
VÛ;£e‹C=?#v–¼´#ÛÅı–[–Ï[„iÀÒ,BŠ‰áø9"XŸP“ MkŸ6+Í¤uß'±ÕÍÿÛ–‹&ÍŠn¶nöĞãÈƒY60õ^$«N”#ş>S„òm$ y„ok¼pf™Ú! ¿ôïüD€ÅÛB]ÆB/o…+Z†kÂÄ¬SxMô¥şJƒYÔTi^qÁlj°Ğ0‰~éÖ‡Iër™¹‰•=9YŠy&2NÑõÃ•«>c¾ø“VÛe‘Ğ=CSçH‚Ç!#¼XQç*XhDûLŸ1¹ó´o¾qM.@¤Ú‚4¹÷ÜŠò•»kq˜—eëúd;Ü3ğeÂmTNpc@â¨O¹İÀ§îb…w­¢5*I&K«¦¾2CíôÑe{+"Ñ_#ùuplö«òÂ‡XÑycè"8!ßş´eß&ÃV^ÕèçG´^.î* ®¶7Zõ%(ŠfÊÿ6ã÷üã‰ğ­¼çêícñäs®S¢l[u££ñ‚µQ¬Ñ(>D‹A.¾ŒO ^ÈÇ‹w1k~miyc<5
¾+'­8VşFÍúê³3L}=t”u÷ëLUƒ2Hƒx¹Œÿ(ú-û®‘?)½^Œsn:õU¡®úN V¾D5^È+"Ø‘¬ünAé¹òa&†–#yûÅ´	¬àuË6ÔYMn3µÛ\CZY‰pOü~xêEkeªñÖyçVx±Æ5U‡İäá±Tbm€æ ûöà˜ev°Ï®ç75ËÛç®ÆÜ ‚n<Iï!œ¨‡ÖC•÷‚ğÜ
p§ãã®ÉB—›×‘&£©@1š¬†Ë¾'€‰?ĞT9ö
j\“t’W¨Iò	3é¡T‹lû7I'â•h&uÁÏÍdJÊŠaAèèM+ØÃëĞ7n»óül]0´c2ÏÕ\oĞhãK±…Ïˆ‹½Ã_G× ‡±ìÜëÛıŞIô4òÎ ‰öu	0H n°d¦|‘zâVíRòÖ°~OA{™pxÉ˜½•7îƒY ¸?J]LÀ›)ÜÂ¡VD˜JÓ%+«$#âú`gŒ"€ÂrñDò‰U!j4æÕ<$€¸«öP|\­—éÙeÍûd-·èô›´¶ÁÊ: l’üjÎ%7RB†@-l^‚pJ=HgÆNµé³c´sm€{£$4Ó¬´®‰Ã“‘•c]¦êhêÆ°lsDñ—`>tù¾‡ªİb’§t†€İA£Ñ•‰Ù°—Á]tÅûçøÓçñ-úùnğ\=Ä²
M~‡îÜ}şÖ@‡^®Â?‹Ï-P7yÃïû$³ZB“úóÄ£á«Ôùìª§ïÉÁ`YŸ–%R”fèËĞ«cÙwQykÁ›Ø±˜B#
“Xùñ6c€.›7l‘Afì¤ø‡ıFHŸHÛÀä)È¯«+z3ñ?è?¿™óã°²„dDÌ1SOÁQ6SğW‘óªÑGÁ&V™ÙL¥#$›Êt›SBšı*ı
AV	åWDªŞ?‘Jïdƒi¿É_“Šº›—~]"¹œ@rÇ¸‡œö)°ÍBJÕ\xu v(ÎøMÅ¤U¥cÿøº¹Ã³Y!åÒ±H
¿‚BtBe¦¬xÉÒPuhoµXÂcôÕ‘ö…ŞÄºY9ûN3Ìä·›A¢CuöÆ*¼ÊÜn=Kß¤·İˆ„4¤Ğ‡¸ ãN ‰(OÇkœğ‡0lGtõŠ°‡KQÆ³3#“örõ	áİµj±oä
MÒTéšÛÜIú×?/†M*]_œĞ±îRïHK°Á+IoDg¦ò5s3
\ğ˜£3Sz²Adß§Š)GZäÙ>C§’×¤\µ“k²åsŒM~VœØk­±vñŒ¯a–Ğ6$»«H »³ƒNŸr³û2òh]ıêß%#¦˜mJ¿(ğ°µ?ne±ÎÀ¢ãE¡¨=µt£¾t™6^óÈ£ÚQêƒkkQ´&[Òíßñ¹7d¼1?Æ1«XöH˜Í¦¢ğıbÙµ¢”Aì6Û“Z>:hqĞi‹³ßŒ‰…òj+\*×®*$1‰23ÎäêÀûå9ÒA	{6¾ä lsE1¨a…·o)QŞNµ|)x,¹3š
ì0–ÁùK› aß½¨>ø¾›¥»íŒıÿÂm®½ÉòX$wvÒ¢ßøá¬5m.ÿFL«ÙÑÀôüVÅ†ey#|áÿhT¯¯˜Íª ŒAT2Zú¶\–>ÃÁ%Õ]³^Z 'ÊUB©‚÷I	Ûeèù›QÀÂ.y­ëDµò3õ£Æ®¡œ´¿—0¾pÜ„è|yæKÖ4!†Ûù#é¶4-™àÛ 1‰ßQ¤!o\ğ;;9·aÿÙ!¿)¹‡jn’îãÍ	%û=I ¿O‡p¯å(u÷zd·§ÓM¯Ï;ÔŞr­×f	 Ë#lZÌÙ&:,q@şEi”Ò{_Ø“2úBÖD‚ 6ù€7I÷"DCL?­öÕr:æÖ8U¶,`àw2,¹‹Áín#Àlq„E€ô$2R•=bı+ĞÆ%]Ÿ6ã8ÔvR!Á:Î±IƒÜDšÖìZ^4’¥Óòr9Ü“MòòôV0À†Ò²Oô
PìÇÆä÷~v&¸PßE3d]kBwÔ³â‹ìôå[ûka²#°®¥D¼üq6ŸIÜ°	W4[XÓõ«W™ÇI´Z—#Åÿêî™€í´Ñ+r›n®µ>Áå¥z!ÏhÓ˜ß•ßB÷MµØ°·vT+1®&š1Æô+“ä­¶»¬ÃÖe)ÔÎt$Ø±7(‰ ršM{èí\EU}W‚”µ30cÊDŞg*m0—vE­¤û VˆİSR¼X '92Ê ²N2¯)±'`ÛŞ‰¸³²˜üÁ|C.5®vœôH0‰±‰§ÀĞÔ#µMYR³ê1‰v*{,êjã´»¥«¦»pÜq¹ç€Ö¤‚€»|$)Iİ}Ó+Ç8ÚÌ04B„Ä:‡ØñQú,qğvŒµsÉi~%’wì{kVëCLÒÆ²/Ïµ!Xİwÿ÷†0F@æÜÍÂªŠ«Äõ)6ëG5í&ã‰æµ÷=…^æñ5!·„™«ÎLe2‚\NZÜTGyL·¾Ë€°H~-ß£B2bŞõL—Mc«íàÌŠpÇ6¹ˆ)¾Ğ|kÀŞÔ5z\³0³_Çü'>çnöõ°L¢”(É4>b¹WşwÁÙé„°±—dwìÈÙÏN“fŒÙ¯ıå¥p¥Ø3ú|X+pÿ°?¢È“ŞÕĞñføz£QÉÓ"ì¤û–Ê™…¥)FÃ×Xàb¥zŞ~7T'Ç²ÅBíÌ
¾Æh˜Ú	B4ëXYÑc:en&ËàT¦ãİ¦PÀ¨óõë÷=´w£¾@ö,»HvèÅ@;”ñ'Í…iè²¡í&ZŒké-çôFì47Œj°uçÑ’Eè:­¦=:ùö_ŠYyÑñŸ7‹SínçĞ­µL7ŠïÄ2Ù·l¶Fzı2PíõñéÙ.e	Pq~+¯ ‰ãÒ`äeĞÑÑ*Êb{ ÑDH”B”i‡ü2S€oØ^ŸòÑQ;µÅ”bä[ã¥? íĞÙ‘%w¬Ô¹åÚ7ILv–€’AYvJğ†},w×´¥Í¤°Ğk·r¢ª n}1”}‘¹ığFx-“3à@ô“X/’&r/«ŞlI7ùë¿Uş‹ÖÕ™îZiT{ ›ÿ~§œ=ã0–èÙ³Úı!'‹ŒxÌŠmæ vUQoóÑìx›ë¤3\íÄ~™NÎ5-2ÑN<¾¥û¤}¿.Í¢rûûÑëé9¾_~ Tşo‰´j8µŠ¯gšŞk6Åfÿ/Å¤‘bET©Ùå6Â½…WÕoˆœE2ÕwT½ç<ˆ6Z·²'éZHÓ{çØ&Åˆ4·Óª™q©.33G¿»"ĞØ-‹<¼Ñ×"è‚E´)ouu"È‡Pº¾¸Z½Æ AeKxÔÊ.‘7[ªÃ•Şx>5[çM k€†À˜%…’èmW®ÈL!Z™JÉwı½cˆ›İª_ã³KRx5”Ô2FV“¢Éœ2÷’3•‹óy3ç¼b'ëth.»[’Uäz!–HÀïªmÿ3J‘úë‰c¸‘íñéÅÄóÍ•n¥k¡Gåšÿ°ÌÁÃ*ööS6¶–ƒd@v.O¯az‰ıÕ©}²òÖ=ìØù·¼f	¼ÉË ƒ­¶{—…2…Ñ=ÖÈ7Ø‘w€È"ÑaâiHËšXËĞÊAÍúÿCÌ·ââoÛ÷9{H{şÌñ˜ng\S21…Œ±2Ò/BwÔ«i¨ÅË-à$%`\'É‰!”Í¥d× º‹­ffÈ'¥ Ë6á–‚¥5R½H¤Éò©Ûÿß
FÁì\øõğo>œ*¼‰G}®ñdy¸næ}ïµgF«-µÎõq«ZO:^N2¬R×Ú:oªã§Òè÷ÕÓÜV#Û³Uõ$+>W?+ï~I:ŞÊÅ©’~=ü#š’Ü
Øø<j¾ÿ×ßÎ‰}]‚ Í£‚moÍ¥·cl ˜D)¼>¤û_côİvxRÊc¨ÑıQÖÅq.‡Bì[gÊeM^­éì…Ş¢
ı%öã0ÿaÁ)³Ã°H½»¬-õ¦¢Ÿ?V™kİ©" …P~ÚòÒ°í·bÇÎ ?á1ÅBB¸ÈLÂTÖ ï×â™L›;Í3÷ì!õõvr×}Íu<À·*ÇœoÛ`%Çyaa{tFìh“_!ÆH•¬ú²És˜*) Æ…%ÖÙ~3Q‹ud]Î#íâ™ıça¥ÓÖŒÎd¹tûZQY‡“:ÃšBØ G;¯¡_2r)ã3éÜåË:ŠÃ‹‡–³¾†=€E%-F@ƒº\b;D‚·ö“]k\‹]a¶Ïß?–<¹Eª¢?Îj†`êØŒĞzê´
?}kªõ\eÕQÛ[ä[ õÒÇ\phOöxmÓCš6ŠG^K_–Á"y˜øZ#âå«ˆMkö „ Cäà“Ñ’äº¥Â)í¹†(á·ˆ3ªP1qØN¯›íôeQĞz§Cjæˆ•0™–~¹:uH¶Ò.ÉBRš‰c^z2M§eØPe?ñÙg^†QÚ¥	3¼è`#ÏZ`UIàˆuéSb"s(ÀÜÖƒéÓòLÊâDÛšqséºÃ%tÕÔnÛyüZXs˜C)€€ÖÀ<Wé­±a]RÃ`Ñ!ß$íg¿ˆú‰“T=9°Nkè½YT÷Z®åò…ñÑÀKF»ÃÉHÑ—w
Ç¥t_Ş•_ŒÛÜQwî7dã-×ĞNdœxß®É]>VâÜ‹Pi¢Òêš"z¹FåKùÜÚíÈ ,ÿºóçÆ(‚íë?•ùxÅËŸ{Ê
û×ıY©Âl1æsóğ‡œ£Æ:æJø¤m¾/ÙmL?=0ÕIHŠúg°Aª‹S§C‚÷g BÉùğ/Z™M§İŸÛ,!Ç«ìbª$†Ù•p’…ç˜õ² ÕF†SNZÍ,€¶°@°IŠH.è% S¸…Jâ;aÎy>‘KÙ²
¨iL ?ñ¦ÁóTãD¤+Tf^sbxø·ü²ÀÒ}Ú
ÄÁ‹Âºªš ]Ÿk–  ¥¨Nv´Rˆ[·¬Çû_g.šG#Ù§²ÕnÎau&Â Pâ60¤W‰üyD¢Q³a2úşÈ8oK4²5•nn”­ÚMVø?İ&ã«~&¦¿…»bÀN´ÚŠDŒZË,F^»Ö Æo^bÛ*±Z^Ñ$ÁÊÌDáb*`fA»ÄkÀ
…›øys˜å	è~ê+w›!µ€
²"¼Ê­Q§—‹Š…ôüÎ¿–yV¤3Â„ìP¸mÎiû´z_£ßJŞ?½›¯ü)|åĞ°~æ/¹´s¢ô+wG `z]òhª“÷= %ñ¿k*ƒd„]H°¨|û¥*õe£:ş£ìg±8~K5çÉ~Ô"°ÙÒä¥º„	r|V?¤óß eúI»F¡iq	~aô°æğÊeÃb‹]ùƒŒÆ‹uĞüoÕÓ&0ûègôKµÂ;+{.EzÜQ“J)7ºË#şwn)ˆ3ç/Ë«Æé¬­'+:´]™Ü û©Ÿ~-”#ÜÁ
‹¹SÒ)*6M6–,|¦ù¹0DÉ«×“·k×lÜ
ØpnœUV+›ã:E|h‘>j¨×sÈŞ²'îzh[0K¤û:	GÜÒHï·}? óW%â¼ø•¤„ˆ­Ëcg]û½SîÙµƒUà=œ$şŠš)M-,“;Æ@Ãîé¶×©;5r~WYª_«x´ç5Jì·Sf*{úì¥w½ d4¹»c)¸Åly”¢GO# 8Ü)_cuRô^í©Q8Ğâ€}ŒÀ«MĞá-¹çüAè;ö.QÑØ’”	*Bã'ú|ŸŞ!xÑm|¶Gô>^[‘ú%2±À¨2Wï*´Ã2¼–Í7Pe°v[„w„‰)Ê:·‚å#º«Îíá69î”
[™Şæ˜v3Ÿ6åŸ‹‡,›¤ãÈÄ°HÿÓuõvu"ÛBŞ ÅÄGÒF%ö^|£""ù^ıÉtX|¡Sõ»‰÷k“el}KC¸¾i#É'³Òw.ƒŸñŒét*j/b—­ÿb¸Db"uFiœ[ôâ6z˜ÿgÎ/~C ®DEf+øm«kwt, ¸wÒ¥’ş©y¤%ŸñÙâ3ä)
p$óqË_ÂEÅVG½<_gÒİèO6úcæ„r9«·® ëB®
fš°ä&aUâ”Ì†+Wòµ"£I(“éN+ùû…ZHŸ¨y‡XgÕ¯dşŞ<ba/ş<©v×- nÑdDDM=Î¥ı†:3>ãè‰ÏA8ÌèÈíØ
Í4¢L?€;Ğğ€?”×ƒûŸÃğÃ¶tàãÓÃ68¨pˆûøYlÉÀµàœ­™lèäˆ;>ß-ûh|>µù`s ÁËQM‹aì\ÆÊ[´Qw=:÷áÛ’
ù&7Ñ«‹°¨±aç>ÂÖ	G„k¡î¹s¿”=qì{ hÓf‚.6ò">ùqjëÔL¸
ƒË	Ÿ˜#µ¨™%ˆ‰?ÌYn®rüçè®)È= 0r­!éÈÀÔ2sÆy-sëĞkbkƒï‚AQ ï¹ùÿŞ €híhî€V8®ØßfAVKF|.Ûğ¿æí–K1g*‰ª¬âlŠ©Fk1/œRÈêSMhâ´‚%htó ’Ä+SÀO|JF11ŠÁ¼£û=w‘SEØù¬{¡ÂŠíüÎæŠ‰ljÔØíÖ…VòâTŸ÷)ûÀ^O°å€i_—)«oDÛ Âw}˜Ú ?æÀ‰A÷}\ì^iA`º8¯"», !$(°ÿ›¬¢E=Ú9såiÂxÈ™G:>üıï%ÓU)Ó¥ılˆªm7C9´ÑôA±å`Æ³4¢n%²¦‘xwôİ ‚gÿ3õ¤%»UªÅ>
AàámspşÔ«!v²BÃçèõË\İÓIçòíçÔm'zlÀ¤Ÿí4ø\¼Ô1ËİMrƒ‹D/¼,<Ëm6~)Œ!FéX5¾Vùí.î?àVJc¯u¶Ü}yKJ$m.Ò-Å+ÑWV4˜x€eOM„–ÒşMş:u£W¶Ã
&8µ}ˆÚh±¤ $OÈÑĞÏ—ƒZ|ŒïÔ‡•ÚÅÜæËCÿ9ø²çÎ@·x«NDgÀÇ”ÏâÕûlj™ßš«&€¦IKÍ›å”w€8÷›f¾X›OJ6Üaxj4|fÿ]Ïòí^TÍ\Bˆ°şaşÉ?//»Eq|—ÛıOÅ[bÎŠ›Hâ­6‘C`KÀ¬şx=ú!?à€¦—g"IºMUF·¦³ÉØ‡TÌËI¬'ü*Ö’Ş—9®İé>ZP{lBíÀÜökgÂÜQıqdP‰;R0%¦yI³wSœ
X&ó˜ÑÉ€ÄB„¡²ÔGëëšgf—4ÚÊ÷ŸÎšQEC&!9†ç!,yî3sšmmiFÕ¦ –ŒG8÷µøğ§]uÀ.KS)·âdd§ ÷X“9œTÂø{·MBu~^9G›½#ë$å|«9V|®6,ˆÍG287BEF€<”AB­Ù¤“òKh±'kcõ-×ãç”Kr…ì¿Vª×iöûœz¸yø}˜Îò½ˆ¬B9ŒMkÒ’û+˜|ŸáQ­M•#.n®kÉ ıG¼&gz¼å¯ãfFÏíG™t
÷" /CP|€D¹@3Ò¦HÛ.ûQæjkàå¨t5MAÛ¤n†Xc –C™Md1‘Ú‘Ç<m› =A~şCDb»Â\l#	],ÌH|0ñQ…"“ĞAœ…B³!Z‡pº néÖ\”[ÛÿÈÎlRß6í!İİ¦2€½H¨··|jPÇú·ßk¬M"hğƒpöÛlN¼óá¢|?¸õ‹ €Ï¶ä0¹fÁŠ B¦ËŒÊ®NŒ%30s¨Ğäm%?µAîºkà•û¤7Î©2¯RPˆ¯‚Wsˆ<u%¬^Ÿ_ñÍ™eô”>jäùÀA0Qâ+ªåhq˜„è®ÊLSqç†jA¥ÕçíáI9®°a;“+6ô›šr–ê¾*ş@^{x>úáË13™¨g‘µ éñ¿:Q&ÅÿYßhqhR'/DÂËÏ: ûø b®È3®-¿sÏ¸9×eT!°ÏĞ@
6¨œLb·aíğ]",¾ÑI%ò®?£†(JÔ)´eh%]/K·‚¸²åc;‡‰>¸j.WÃvÕ¥¹m¾ún/2 tˆo
/.ˆHx;kv9Åa—z_‡‰ÌŸö„(™Õ™dş%RÜLóóÙáõÕñÃ·îšÉ‚_ç\æŸ"nSõ#¸î–ĞcKÏø,	e†‡}yvëîşğ w3K½G¤¢åÏbXgô¨ÍŒ?·?7;…K®äg‘œAÄ,“ÂC´¼Š¹¯b‹Wá”Ìiü~âÙ¿×?M¬Oš8XUF¦H…Û÷Y”›ÅĞS>Š£g(ï[üÍpO‰ÖsèĞ„yj{Nßš8W¾ï1Õ¯z9eWI+jÎíº„Û	Mt”iöÙÒ¼¾GJTº‘7Z5Qs'*2°Qõm—M¤)ëÛˆªóD`€ 8%ç¡ L$0"‡[TÛ%«BW9„÷ù´’jíÒï$äw…0æ}F´¦³ÉÉ5 ³Îwøİ|çx_‡-ü]«ë–ç|-Ui¢Å»Lá‚MavÛºJ—1'~$(‘ ĞĞ7‚.u¸#†Ïª"Fíôpw:Wêsf ‚HËú3"KÄÓ·€’Q6Â[Æ#yó 	¦5(¹ÀÓ¿U¸+``cTÁ”ó/i€«©íõ)é¹eU5n]¿ß+L6>ÿ¾^‡ËlòHıDß©:§P®¼!·¾³W—z¶ 9q?ô÷¥b¬ùolTØ¥o8ËVÕı¶OD`Cğ6Xêr`ı2#Ü&dÙ–ù—ãXóÔ}¬¥éuJN!)Ö"um UW2İò›*ä>™ºjs~sWŸ}«'£xÜÃ%}A2{ÎÏ¢%şø†BÊÆÂ^9Ÿf%ZQÆG¸Eı·˜ø¿÷G
Êœè¿ó{»a·Ûî&ó3huÛ$ÚVˆ<¹ÛT„¶ëŒ~{>‹û-:&×JÎ —‹ìÏ\{nWİE]qvj.=ã¤¼im qŞ,Áµ·¶§•—Î9¹bIÜg¸ruî­mÜÎFÍ>‹k©™A]ÄpÔ£¿í.ØÉï&%§y	Ó¥ú¬}ƒcOg~—>QdÄÉ“¸Lıê,Ç4Ğ¦^O¦‚b!2U’½@ÓV£
¯ÉÄÂNNÓéÉ-Éú±h…xçö$É’’@½ì[7âÅÙïÌbA])ùÚî_Š“ò$@–{õÂ±RßS8£äŞÍq*>ÍßN4r¿ØëÊò7î0‡·~SÀ?•ê³âIßa<B{/¼ˆÁä„óIÍrC+E_°e¶¡TÜ+îhM,Ä´û©0øÏÀ[u:•”2«|5.ËßÊ&ñSqŒqæ}1Ûº
çé[©²—1­"[o`Åq¸«oğ£ÚË¡\¥l´S„t/»<Ö=şì®«/œà£¤Şb•›^i@ ú—Aè…(Üë¥ş²İæ|¢ì¯(–Ğ9M{xÿOJÆ'*ŞÏéË†XÇZÉŒiÜúR]æsEù«ªš8ò	÷	­_OÜß!ëY*lzˆÃHÓ—x„À ¿ÙE™«Ôm„)²gd^˜şåø¹º¥GåLµâX¾İıVLÕÁä±oDAäÆo¯ ´D.YÛù·e;MáyË»\ÚK ]nPÓ735ß¾¨N¬d|°ÈDÊÎpcJ‘ˆ¥pšÿõ¦\9ÜÀBãGô~nØîcLÊ·Nu7Ãß§º@3ef»õS ¡Å^Ô
­²[B"%U”2 ¦ÛÈÂh$÷c§SiŞPyÛã•'0ZMÁª'ßKªĞËı!G´$‹(2à}İ/`û éı¨u|[FM£E!lÉ+~.är¬¤ü²ƒÔNbÀµvtú¯íÛ·¬\õf%ÏuˆÂÖ}Ul<hˆRjšÿ¡]pa*0~‘Õï_âÏm+«ëªe¸nÛºîw©H_¯Şqš«¤–ö,Ÿ¨
zhW
@.•ö…Ìd†`F‚mÒEË«ÁŸ éËÆX×n÷§ÑÒS&pßÓŒÎ’E½'Ô¢v}RHà®–ÛŞc+À¤´cÏF“%ƒ¢ïj“4˜ı|ì‘r¨À§Bì™ŸfDÁæƒz	®·ÔzÃ·qöJÿæYÄà¹57ì‰™ì&İ¿v¯ËPpc¹…$áÎ”=ø²7ù$:Áœ×úƒ$Nn"÷:”ÿ&ÛİjÄ&ø™}^kç‰YH“·QgÍ^D*› ı—XƒÙÕ~²=ï,#d'`H„¼³••-r+ØªÄ?|.'JDQÏµ P‹c¾‡€Nô'}‚ŒX|!Í:a/9!y!Iøï	ë)˜xéŞMHÔ!Ñæ4ÔXÂ¦´;UŒá(ÌËĞÂqª<®ë˜ˆJ†ëÎ•.S_F_*¶_ôô8Ù·Ï¬ÑhÅ½#÷@¿k;8ÆÏĞ+$ö4±»óğ–•WcP(CÍ`	Î-ÃÉ’ş:åô‚&…Í¯‹²DÀÛ]K¸ó9+"ãÕë“<~>~sådz›&«ç*bTr‡ÜB¨H lò¸o!W¿¸Tä³Ğ¸%K¿œû2Ë>q…rZØ lH6bák±ÄPlîÀÙs´p5ŠzĞ¢‹À=ÒÖÖ–íÆn6!¯ %J`ùño~¯¯‹Ï¦|     ı	önÎOÍ ±¡€ ÇiA±Ägû    YZ