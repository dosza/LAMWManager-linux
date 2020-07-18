#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="864100706"
MD5="632def867e24a10472d0d14327f4c18d"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20708"
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
	echo Date of packaging: Fri Jul 17 21:17:37 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿP¡] ¼}•ÀJFœÄÿ.»á_jçÊŠcm§ºx°˜Våê™šÅ£Ñ{­ıL¤ ß¼òàQRUÎ‰×)ù)(Pğx²¢Ô*¾ï#£êØ'(¯K>vÙ®cà"ğag>Eé¿ÈÅ/î´ıé-p†Ig‰#¸Ë4B£ß]™Qe"

â%UÌÃkö'B¯¹#*QlìúyÕ"Û¶|Y)¾;|cêro¤¥Ú&)M×}´›ÔĞ[@ YÕÿÕ¢…–ĞYÌ²£t-(fuÃ8ì2áVŸŠ7OXU˜µ¦x pv©ÆÏ…è˜ï->B.2ÖZDñÌòú_^§€•õ {*‘…ñføq8Şòï­Ú[ĞıÃÎ¯ó¡-ÔÎ˜|Vİõ<Cî3„mgÅl-°oHÊ×DN³;ŞU>Åü<”;?ƒÏç…^D,Pü‘‰ÅB_±ÑÒù^ÊğhNX3z'¢šV7ZÚL˜™éb²,CßRôï÷…Kq¦kˆ
{´<TÙª[À¸P©	¢ò1>˜ûİ1ÈBtÅ5	Ø;Ã£¾ºúz	¢8*&G»ôR½ÈM˜Ï¯©Ï‚ón©6A–u`?xîîFÜg[Èºõ5¦Q9”¿‰1ÕLØ^ÒuG/lünx	S'«õõvÎJ;¡Ñ_	OW åŠK	*|ú~Ú“”EÄ¾ù#]ïàBÏÒÅ(qlH3nK³0¾0]L³çÍ‰8ı)ñ¬’j­}C£Å!7Q¥D#î%€±D­™\Îö±¥Dlq¤›õaÓìùk°¢â×O$'ƒ.éã¥¥qÂöÜ¨\?œ5UŠ!Ê«Æ¿cqÊÑ	ù’¹.Ïsâ wœÕ¡ß«mëÔ”Z ÈUáÉrÙÛi‡.¾¼Ì£}SÏâQ®l…7½±Ë0áÖğ0xy&òy(ÍÀŠn:¨sv9÷ğå€§à·7s~ë<Ím%ğ!şÄÜË7Œ‡tŒ+4¶ëß>:ı#”ıq%äl†îÂŞb¼`äóíEœ|öS„Š<SàüF(äT–&äu?/úg£‚û	q&K«yùä€/@Ïw’!öÙ8ôª,-3r´Ya«BD°ÓwUÕ¥¯mù(°ª¾–Ù&‚ (¸ßÙÆ>ƒ›ª^;§º‘Hãù ÌLUÈÓ)Wêº7uœ9º˜ÔÒê8“€ˆÜ9	r‡B%-ã=Ç²—¢ıQJÔ	Rîw…â2ƒI¯"F*Õ&¤µaQì$zADÖ#ÜÙ'ù hKW[b°hª³ÛÖk ëY“²]gà	`š˜B·Ó}»ÅÑ‰œEÏSr½÷œÇa¼¢¿vÆ];™è;ß ëĞ yñNh “k•¥3}–õ9Í2-ÚL¥ÓOše¢Ä'ª¯Ëæ¿”a y«Ì&èAÕ8Û‰šçÈÜY/-ì= åóSAbfæ’;£]ãU2š×já~èj@’ò¿`±C§ê7ãŞë4£jÈT“úY¦Õ¼ óš,Ø*Á9Å˜¡êSùğ+nç>Çág>B¥©÷ïğ®ä}Ş5‘Æ,œ¶Ó
ÉF?~Í7(Cš£´âÃ%ñ·¯Á@È‰—=:9’
œªÚ¼¸Ô@yÍšÙ ÙÂ3<Eo‡Iä½Û )ıÓSR3‡6üj‰ãâ8ğŞŸWOšé2ôïÄH£?•.#ØĞCjDÄ`*“ØYK™ù!™o`ûªw
n^“4=Zq†ÜG¢º,ŠååA†EZ«½ı ..&Éïoá~ÀØÔn¬2mk')iêŒúÖêğ0ı÷›T·wó•:ãßf˜¥²²¦©Ÿšš˜ÁÌ0rL1cDØ~Üæ’“æI¬¢Û©%Š­¬\"m2y‡ÿf‘±)…‚¥K_©À¸”ï|°mS'’ZY­|ê²#€R>ÿµfhü;aªF|a,»›6‘£ÌÖñ|~ |«kÍÌ»ŠÚ£F”Öé+&»ÌÉ†ÛÅvRÀì6mE¢¶(j‚£ÇUøqN'“ÁB-ÊgV,Cÿî–„}]p€-d¦–d;Ì@İ…´Ğ8¸(I°ç*S€¥&²^óWîÔñSK~
n©›ş’Q>Îè.¼'ÉôÜ™]ëñ¬e UÈº?ïZ:÷ÎW¼?ëá`bã)|2¤y‡Wƒ!EgeÙØ…¯ãpæÒÂ4cN<7v"ÆT&Xá’ƒù÷­Šüîv'Æ¹wçŸ	ó¡op@«<rÊaùæMj‚©Œ×à<›šSøtIa9ÑwAm-ê‚Ü¬ywfÚàôø£0‹ı=t‚Í¬WI´òfi×:”åv¢yDßiÍrö3­œb©¬§^¸ePj6*ù?÷¹	é/šMÍ#µÑã¯‘6‡mÅ>*]ïÃùªt±õ¯ÄÇßâØ”-ul°ƒu|ºßXI®·{¾¦|šDÉüÔI©rĞz,C¤`”WÛ;!ü•ÏqÓT.à—QJØYYTËYğ¯ôïU±|P=®Šı/Ìø²ª	dR óÊ]˜>¿k]hEÅ8ˆ®„ÒfÖÑ;_K¯xfYSfÌ·\å®ö—uæäH$ÆBzCô&;†SàAT™SGN^.‰gÈF2‘ÛhGâ~ÁĞP<¿ıÊ¢yåS² Hêw—33Ô=ƒ=+²’¼=-¼•»¤Ğu=Î¼c÷Ü¹*ÖA“}7e3‹gi\råsøº+zF5öñ‘?¶rÚÊ Û5¡Ëœ3¿õ¿¹Ç‡K/5ë®"ÇåK&NJ¤M¥ã÷+Åt­…îé¬ ”ŠoXM97\ø ]lÊ^$cLK¯GÂî¤RöCÍ\2 +¯É[S.›‘:ÀäATµŠJ1k{ƒèf¹…óêÍLi^[-æjHÃè!ß«ò’ÌpÁqç÷uX…®±ğ|«ÆLSœ•“}¸ÔŞ×5àáÛ1
}¹‚û8LS"
8åŠp1É6ÖMuÈÂ‚‚^…9U¿1úZ€Ñ8"Eƒ¬HØÉZë'‹û¨Sè		Wåãok`Œ¾Ø©ÍŞıÂ º­“Àla2íĞÈ®ÂëÜEO)zÿ!şXæ‚† µ	=±wÇ‹dš©³.O’•DjÍ&6Q}Á:õB‰uWyzo³û§í÷èUÏÖœvıW=<ñššn¤o±áôv;T‡WÊú %ú}†‹¶Ú˜u{h°	í¡Mräïî”Êa\ìÒ¤Vá.$”•4Ş›?põ£.‘$íØøC€›œ‹F~E¬KŒÉ`Ö2çS!øsRÜÏ3*ŸÊ<I3õfC‚$i”Ê@¬d!"aöá '¬†0vë2Àhò7úDªşji‰Ú€öT~—´øVŠ³éB]@ªµ´3Ë+m’¥÷ı;¡ÇNø¬ƒÊ]Oa/ÃÀJ/0X“~ÃızC«×“òÎÚWüôIæ!c“Ø„Æämìæ ”X,>I•™ 3ÔG3âÓoœØœ½Í+
Ôê¡d~Äœ7^`œı?¶ALEÊõD¢èMQ×”+à b¡={|Õ‚„¡Õ&–şê¾¦!OÁ"Æ¯íÇ–7úrÁ5ê¢ÿÈdOwŞëµØ7;=™úÃi¥ÏßDU™+rB¨|u¢YEÎÀ=9°¿õ‰§&‡óÀd!9¾nÔSf¤¡:Öf@`Qì:Ç;NŞüÓÙ‰É	Ã
"[˜ÚŠ‰çßñr_ŸØÚü¾ä…ï	ª	¨†£$D€…{gU2ñİë2?îÿ˜Îs@¸ÂÏu¨">‘ã}‘-wÀ9l7!q*ôcÀ`‹Ü'vå_»Ô&tŞ·v>Htğbn/Şäâ¤@µ#ïƒú‹*Ó»æ j9ş}¸‘µ`V|å©¸º™ù§¸EğL|òÊP’¸gä¾J¦Æl÷x%¥Q¼••Ï‹h–ÌàÀ“[ŠËª^ÃËi¼,aîxÖ'ğ;Óû
«Gn”ÂVé8û±ígc.dÆ#u¨/È)|e›ÉQ§”©åİèáp”:¤p·ó»Õjå`0Şƒ³å;×#Da?*[ÿÂ¤ô0!·º^
¯øÎÏ3±PÈšwzô†Håğ˜pçûs‘X8%
Ç+Û36«VÃıöŒÖ’Ğ8
 ÷ñÏCéa*ôu"X­L”ğxBqÕbØêäÎº?¼¼Ö®>&ü©NĞ?Zà†céËy›÷éÀàD°Ãı‘©=ÖÎí¢&¹-ä¡¹B)¬e8
­=¬HÑfÀÕÂ?™¢šŠr8ĞJ!H-;İo¦sqĞ4x¬£ñ±ÓĞ¸ötC¦â^Û5ãëºĞ¡à}Y–ÁİO¾P×àp³".ùÆö‚²/X’pI.2VwQ”Õ.}úßÃÌ4 Çn¸K‹/+…7Œ•ÖôJùÅ¹Ş¿¸„Ø@†"õDíı8ôÓŞtlX)t^3Ã¦OØ»ø˜
¶Œ}Êc®æœ®ªÁ&ãõŸPÎ\èE„qâ\‘1Å¶z7ÍqpQy%Ñëdg hæ!´†½Bàš{:Eš_ÙÂşï4óÀ)š£7$†¾y´Àæ	ÕËL»İ¿éyrş«…WËX‘ù=ıÈ»sX£
8†~c‰Nq¹4S„Ñ3§c¶^0u6€˜	ODÔE‚6‘CÉ:d‰KÜ¸)!TRÜ·l»&½äs×oéO~je'ó“×IrmeğbÍ§ŠÃS¹V¿×` nJ¨¬#l>Öáé¥sçKŸ—H{¼ëá‚VÂƒàÍO´1k¦Œ'¨F„GªbŸ&E:àŠÖE„?ÅÎºG¢ÂÁ!Ÿ&ÔŞå¤ù63±beE¨W¸±¬”ãOV—×®¾Öáå3xIá¿M¬8ñ´yÒ­Mq©Zèz|øù+Oòóv7‡Ó¼êZ gZ–KİÖûæ¢ÚÁ,}÷ENcÜ¶K8ò®µíİ«/#½ñ¡y–/€¥iğ–æŒİRŸ“”:zcw/öQkg«Òú:?«—µrŸgUÿNSNsjš•<Š(æÄ1‘ßµy> ~—„\b@(¡Ç:Õô-Ûùµ¾·ÆH:dc¼Ïv¨åtv¡E=°Ù‡™á©b^Z.ÆÈgí¶MJCÆ1á…ÙïÅU«_x.˜ó»'×"E‰ÉÑpH÷ÈœKä¥Çf=]?P”P¥9´svÕO>È›@¢\Ş¸Æ–FÊNçƒwP—…-);¸Œr¸€¾¦¼Rlp¹È)ÎùÃ	ŠbŠaÌø—ÿ®ıâCé5‹R3*=›·hĞOà¡=qB8j…"RâVíÛÉ50ßÑ‚Ç¢.¿	(†í¿X§0yƒ—£²*ŠsèN>í!É“»¹}	ïk,3¨-~ÑBèaãÁõÎVúrcÀüò[“ ¦‚êe `ıv#Š™5h¡™}6óªõ¥“:Š7ÄËTìVF"Sòpî¢Ö×7X´M²jMÚKÀ'íªGr ˜_†UÅá˜âİsNÔOì}¼¬6“xFrA1¦Şø·¼j^Ï«s¿T¾¢i"¸ÂšªÚv÷	™p•@“ãDùy‚¸Ã.n8_µ)CºÅãj¼pÍ•ã€øÀ–ºH°èßåOIÇĞ£+¿qÄCşÁòqëmY;]‘/ Ó½¤Áé{ºR¼bıØØ•ìÑs¬yÚ¤!2F×]©àV¹t²B—˜cÇ€!y5Töûö„á¦ód!´&ıù.§³úÈ7ÁÖ²¦®T­‹kP26¹QÈñ#sI>’®ztîòfê õHE8ÂÇ{cê¸!”ÈZÙh ıë_øŠ]É»±¬hôei¢=ÉUrÆõtJ|VTrhÌÎKÕAoîJ;«RD³B~Î óƒÿõHÖq©ua3ßsÌ»°ãR*(×„:G9
â,¤à]È9ÁyÄØİØş=ÙBõ\c¡-¤„XO‡¯^ã ŒK3LVÂzğÏİ€ŸÙºŸ]e” $Å,¿e*-yy/wúì¥ˆ¹·±@˜~ö³£»BİùTI±$Á¨Ü/,?/©óM"J$zĞ}¿E±Ê£ o$CÑ¥E(¸*#·œ’2>>KBCŸ:e/ÔÙÉÓa8ı“énª€ƒQ†"anK¸r”cµÁ`õh@mU™¶FËY|nB%şvÒï2éíeäËè@ñò=º^>@\)ı£şX”ÜzË\ŞlÏ©Ä´_!ºÅÒ7ÀìKá·TÅ¤@ÀÄ1Ñ^÷¹U±ùæû|Ô…Àìd›rLrß½Ø_¯œãá.mXM*©#A½AŸ™l¡ï¹ƒç‚ê 	ï”å|Ü”ÕS(×Ìßëx¿b²³Ç+Ëîú\,iT*,(…İ0uß	Vo2e’Ü·bdıˆÂŒİÂK…­J±„X7iŒ1l_^*Úm
¸Dx":á4—q¾HQrİ‚¡¶O±œ>z¸”vó7š=Ü/yIŞä*~ÒÆŒÁ9I“ª§À{Ü†–!´»!)ù,qÎ­ß„|¡}ÙTÖ!‚ía¹±U¼0m>¬dîÂÕï³¶OŸ­:Špp¹£J}ä\vĞ'8ìb»F+]±·à3C–£ƒ&¯n.‚ÖŒCüZOÌ‚m'ã_Î–-]ñy{6p¡m	–|ÂO¢ØÆ³‘+	æì°E¿}Ä âoRR«§	ß;[ƒl:ı<<ç¸3è"·wş(¾a?dÿ‹4dr¶Í,şrIR”z+÷!r‚+‚ÉûÃWĞ6VÒğó m1-é.cÂOŠ9-8"µH7HÕ0g,7ş}ËqRŒö«·(r‡Ãeã$9ñ‡Îø]‹„İÛ
¿š‡-÷Tı<$­Ğ¾ÿk²ÆÀCŠrPÜ
&Nnt˜n¼û¤3Ñd«>Ï¬êõÉ´mÆ–å{ÿ¿–I	ú<µµhbJ(}ƒrVëß.à¨ó¯Q º‡Î‚Ì§9\ğÂÉ"5O<åJ'ğÊC¯?:Æf@6ƒÁÎ"‘/İZ%³ú	|ôÛ°XÒCÆµÑß¯?Ëq~gÇÔÿbÑ‘ıEäqyáø:ÌP•²dqp
¸¤94¶›%BüÇ›”`º¯‰C¥ä ,aŞ¾[¹Ö¬IßÜ!nµ®€‡Ï"g(
*¡¡R2ƒUšÓ~´[]±yç³{JH‹iÛ›ê¶­‘™À»ºX|[Ã?µpù †ËÕ­İêõ‘»._øÿwgv•úY|f|Çb4çŠ¬ãKçéRµa¡ÃMLµ¹,_”ÿß„0Á}Y»3B5ö™=yNÌøßîğŒ!å]ë:’¸ƒ†Ha'LÆaŠÙ­Q}f!"-‘óbWa ¹•„óÕ£Ù®È­}"&#ó5dq=XÛßÍ¬Ÿ;O;=î¡¡&y~¿~ kYWœ9®ië.ÓèƒX“G_÷8dº*F¤)ò¯½“ÙìÛØµOõsâO®z×Óºõ5•À{
äç”æzôÊµ‰:qÎú&‡d/„Fˆx#b˜’ú \‚]ÛÖ¸	_Ë¶Tñ\wi×¼¸Ï²×ËêÍº×÷8@ÓS6á£½”PéÙ‘}Š•ãÓÒzòZG¨)ä‘#¸7ìD7ß1Ïyt=)C°¼<,ï|3±©Kğ(›ƒÎ&\uÇ‘Ô$`pN]ÙˆğNÿ¡4Ì®æsÃ¢0XI’î¶ÏÜ÷ë4í!Œpï= ªqS@¹Â³6®!Å@®a¨0@	ºòàÀGôl]¾a«ªmyºà7gŞBğUŠ0f
’EñÊ6kK˜^£Ïäe‰j’uöîÁÔlqZEÿÌ@e–f#¼Å\“‘0 ä`CÄ¶,ô	ƒ™ÿ{Ğ«ñ_¼l˜/ZâzÇãC*Üt5ª¢@‚ËkLˆÜ3ÛH”aÆ7oX¥¤=„M{?ûİ7€¤×¸P=;ÙêàÎËk^üoUxù‡Êî‡Rc6rK2È¹¼”aFdFÓ\CO½1TK¶îMhÙş,~8íG/Š¨$„ø©õw¼†¯@lÈ4µUÇz2rPÎ_9ñ„*ˆçÌçcz‰šÆDe³ñ&ª'Èqç_T}C&¾³·§Ëî¨…£ëd½¤~İàì¾ƒóœ&Jg…DÎŒ>p?=ú
‚æè1ÖÌ™î#bŠ?ô(A=µ¾İr”EÿıR!›ºº¿m¸2ÓËéi"Ë!|Ãvg|!‚$0èîêöÛXÔÿ!œ)#zrÛÚÎ[cÂ@ßÊ½épA”¹¹ùP{ ŠL(×%ùî@jğ‡’¼©±¸ÇCrdº-Àß}æ}†¥ºš›ÉÃ¥ùïÿ7Ş3˜â/¿C53™İÛNbd
ûú3î6Söx¨Iœ˜>şô•™[’Û]s
ˆ-ïuÚª%Ì*€ ìğBÌà¡µƒ ZÙ|¸+ÖvÄ{-N²6r’ÍêR'—s BÒñ¦²×6ÜP­
æ½ß3‰~ ‘-
Ñƒ´MÔ(¼iˆªwu¢ã(Å¾uÎGî0êŠ€ÖÉ=wL:İ–Ê¬Ëq)Rfên;tkfŠøÒxpÅŞ(sÄÃ8Ó2ŠÛ&E#,ƒØ´Ğ_$ŞÔäÕBBá8{–@ù<CûÀDl)úCî(ƒ©»sƒÉC|c©mº«6qu*E–Ğ¡Mà —„Š™Q+Ìº‚‡¢Ğ¸ÍîÚÎŒ¸F^9!aYğ;uÀP€ Ur–ğÈÖƒyˆpeç›(é¡Yå-
ŸÉPDs÷³<cŒ)úWT•'Â—>à®%œS“œ,aCVvİúmWyÃjÇjT
–¯EİWz0qs®Hš-úÚUo)ÍJ¡“	¬H=|e|eâÚÕ YàP'6‘òèï&­û^ÕqË'o$^ ğÕO†»É¿{·q‘°fÈ~R¸ ü¢¾%dÿÙNg;!É3s@8.ğëÑ^²%#Yò@O÷iO(Ñ`mÊµÂ´õE›1Xve}©‰œÛ|'Æ$´‰Ê1_\‘XµÖaß•şl@„(J­ôeÁ¦ê¸š¼n»¦şGö,ŸwÃrÁ–Ív`½Á6ë2¹
†X¤ş¿®;exèÁÄ´¹´‰=ãƒğØß‹ígÏ$w@:k$-´%¬‰úÚÜËbÀZŠø7®+{Ì‡ZÖ3]Vù×S´
˜áfY÷ôšQ1™_SÑ#8£<9i3ûö_¹0d¦Æå=¿×I"Šƒö(µÙ…Õn°ñŒ›·*3\Ymšå£¾v†á¿?É§ÍÕ–Âf'34İ)ÿÄïêê¢¸cÃˆ…“˜Ï¹b"Y¬u¼Q§rZ3‰İêºÙÎë1Èƒ[şzµ g-:+r×¿iÏW	"uQX³R'Öà4œôOzÎÍV±I>Â:2Ús–vÌğRÓDCü3KRv
¿bk'Î‘aQVCÖ#ï¶.lÓPãáv›.f°Ÿ—")SX(¸]Ñ—=ØÎ5A?([DŠœçcyR¨åÑ>[Œ	JßlˆÀíd¡şÏ·9;÷\üH-k Ø„RÜCôÈ$ç@¨õsñéöGn¸œ†tê§™óğ¼7“šş;sp‹áª¹Tzc#p†ü­‡æL¿Nuô[/–QNjn<\ş…„ºúä'ğ gLKç !ÿ”«o;{˜=S¦òöÙp˜T†ô¸ÚòÍØŞìN±ôÌQ·æ[ƒÛ„°%|œzËˆ¦˜“—ª=E«ßİøÊFM;v´¿ºò2–Ï¾+¼Ô|Ëí¾Š³·/ÉäudfRÏ™‡("é·ã¯YñLO•X³ºú|3=pËª0ûˆ–ÍjM w†>ä î5×Êåç£Îì…û›Ìé±‘ÃesPz¢ooyNk°I«tY=Ñ
Ëˆ°(öÙÙ‹8€Éå4®”{
ºüÎ‰š*)äù?<îëÀÅQk;x%è ğf¢ÄåËLhfLœñ6-/~Ğ¨?“İ»FÒƒÁí»¿Š>Áôf_JXaeSuVÕ·„“7­1ª=ìòò1ÃC14ôTœÑ´=Ãzèkš×¶õÓ&21Ş!­ØÒ¼Êäˆ_¹""²ºwNâÚ8Õ¹qIŞC¼Wš!ÊæjT:ÊU¢´û£,'’3Áu¤èÊz	¡O)ÖrújÄZò-ÅV´=E>	,áÇ`àTd`,¿Úši÷¿ƒu+ıÔäîâ¿t½5¸—¨…$;oJÛ­
.MTˆ¼7Ë~
³¤ğ¬·Í`fv®‚¢./ü°¿ˆÔq­¶ßì}¹¹:.Nõ+œ~1m!ëÔÇ”;Ps‰ Wá<¦à±œŞ:kJíôĞ•«ƒò9z•³­4“ÿV×€ã?ÅZ
‘[„1Ud0H8~)ğù×7¦È!H×-ƒûœr³+L•œ?ä\JBÑRM8DòA`ÿŞèUR[f4xŸ	Wé¯R×şÆ¢ãäL!\ØZ|4¶Í‹ææ™ÂaN¼[?¬gÎyª"d@—È˜&Ù„O.dYLx‰$÷v D“Œƒ×_º=ï{|TrPÊí×E_}Ë]¤DğouË>‹uìkNó~ñN0E
“Ê*Z1p™’¯ÑıÕa@ŒèôI É	µlÖ8·Ğ^Üê•Éx+UûBSäºÙsYÛ'PêÚgQ‰I3fzzEœæôO|ùÛP;ŞCBKjËÑ¦½tú]ÿşXô‘õ°ªsk¯ï±¢L’]”WcB.ĞÛz4÷ÄÚùC	¸†U3øù“Ğö;_dÏT?ÄüÖ·7{ˆQu¡UGåÖ„:­”ã7|_wÂı¯}§[0P„¾vs^ßT”û‚Ë ôÛÏòø^Êi8&Á#0°Îr3HüØåR˜K®ì)Ô5ºïğ×¸gR³`¹ºPgë¡Ê«D6v¨Eùá ™Ü‚œı“^,„œÑâk§6[-ÛÜozˆ1€ô5ÍæšºR8f÷*Ütº“àÊDòtâ½Ô	ğ'm‡ãT6»%¼W8KãÛ@DYx¢)vƒ¯cH#ŸªƒÊA’z¯š™×ç·IhÅÉƒÔO³´‰U„ÑÕ˜øIçòjÉÓö‹ø¾–œ$i®å·\,%po›?*ÿBÊì*p)#°?¼¡l:æÓÎ#hÚ‚ïpà“J­çKŸÒèÕÿÚn•ÃÛšnÍ›u`xŞxæ œ$ù+^C
<plŞd•ymÊ.ÄÉ¡‰)^Ú~±Ozy»¬ê°ªEÙ¸XJ`UÏ8¬ïï=Tã'K¿‹5¨òIO×¼Æq¬:œQ!ãóœù¦ÍÇIŠ²Ó¼¶C@Š«‡s—K¨v´®Õód\z\’ã‹:ÆcÔb '?èOÚ…»<üÃÆİ‘Ç¼É$êy0tÁHé@:üğzíßs´„0s«º'”=„Dú3?õDÓ ÊK5s‘'K7Äw™"m0QÒk;¼£9m]LĞĞªÏß]İ8|pÖL›·MWQÙÕœô« ÂØhô)™¤.õ^EréO38Ù	U©-¥ ú7i&s0FÔïÑÇ®OÊÙ‚Ãö:WÊxà©mgÛÕOm–ªÄ­îÛ~c0E%º{|@!­Œ[]8ÕÕ„S´¶u^—¹|Ë%‹só±½ìöƒœà¥¯A-›*:ğ^ìk©â×±köË^ij‹“Ğí$+£AêDêopøÚÊS‡1wqİÇvê€iğ<ÍÏ”—«w…ãøˆ>½)No³„)FU›‰Ùú•ÍìÒ½İ”kÿfÏüÈÎÊImµDù°Á©æHİRk•¥¥kˆ¯¿öØ$€¸Ù6Ü$ŸLÚ[£ùß?q©ÙRX"L02_Gé¢Zà¶íïYDó÷¡—Ãìbğ;IÓ‘ë‘#ÍbGy­i~=±zz®¬bÎƒx%Ù+ìúßVğjJ]È_@n[#9d#Iå¢cOÿ– 2Ú¨{UÕÍ,)“ÿyR#jŠúú Ín‡û,CÊ+ê×ƒt«æÜ©ûù: WhÊDn)A9¥Ç4='6º*Àô%`l!ìEßâ@ĞÙìÕ¾ìñ0öÿ8JÊ—•Pï‡âYXÍíÈ; ìú“Ò#IÛE·õúÿKo©ÒÚ © Õ ÀN#(i¸Û‚(ôĞìÕÙLë'{{ŞüP¦îv>N²Èr—¯“`(‰ƒGz»{¹ïÕ‘2Œ•Ÿ‰™¬“QˆĞ
7
rjno¡9²âú¶ÒRu«ø¾¤—çµI6ğ#õÆ/caî0A*ÂlniTdY€Íîa:ád¼)7æš†ş>Œ~ªÙXBíÒ5ô›6òU‘<”\vlÊµe‚Ot L¼'¡Cq•+|§Ê¯”‚=âQ¥«Çc
OSì½Z«¼f#R¿'™À¾7T(ÄWáÅkRÂ«ıyV£ª>-—á=ÏÂgçÙm´)À/hóh\Ÿ*•ÑûéTlz~Éb;\÷íy³t¬ƒ#ê¿dM4Cåô@½ø38#*C+†w•loÅ’ ¶ÊÎ)aê\Y»-gT;Ñ}¨E'^¤-±¨Øê‚§pÕ7óğöÏH…¾É©*úÏÇwNV¾-¢5î…şêLr4êH¥nÚ”eºèblÌÑÑí†Új2¶p²n»æË³^Œ3®ĞÉaö(%ØIIJ/†óÃóËğºßí
é3úÏ‹1‰°ú¸l2!çÖIãï‡ƒÎ|è·õïj¦™O×ƒ6<KÙiş¯ªZ×UÜPìÕµ…¬„Ù`cuÜÀ³šdóSş˜öqÉÜ¦ŸŠ˜Â½üÕ,õfÌ”"7jìrhñ,ö†
õÿ£!)şú'/öSƒm¡3{Q·rhÙÍo¹éJˆš#½¦äğĞã!ÖÂÕ R«[bÛÔWaîGVÖé¬¥q;_EÍª_Y»¹¡}Ä¶%¼û"r˜Ÿ3Æp^$êkÛÿE±ÔØÛ¢ƒÒTğ˜i>.p	PÀt‰Â9 _&LÓ´YŸ±6ñõ7i$£ƒqÕ#wmQ½DàY¨†
YcQHvS¢à V—µ‹‰rû0ĞÒƒíqØîH`D¬\Û‰0d¡åµ^Ù­G­·f1ûúÄp·olŸ‘$Zî×Ö¬cß‘zqÎ‡ÜÅ¶m¥V<À”Ì_ÒëåéUñ`æ”e=Ì2„|âÏ'±ÉKÒ¶û ¦˜M}qi@TÑ©uOì£¢ñİ'2]–44Ï!›.ÿ³]4À"rèÔêÛ2TÛ2ãôÜ“§5n_Ş¢¶ë~CããlèP`‰J\Ÿ± ¶9Şô«;Puc±e¥A\ÊgÜHU³Ì—
tZÍÛ­f¾ËZHƒD‹³=ÑLèÍÍ·³£4Ù‚‡á>ÕMöAQv†°|}0ªz†èŸÓ|ö …¯%oÈ7¿
•šË8Ÿ¦e˜øŠÃô/C[kA ê¾“ıe,çíÔœ¿xÙİæT{˜—fä	o4Éf`ªZX Cæepo™yê8CÚÒ©çÍÆÓ £1vÜ ¦{İD1ÛıNš¯#gr‘Ş³yÃ| ­ë$ºQ/îŞ/«po„Z\9zŒr†mÌÈ©ÃDeÏß²)}bOúNlÇá!;ø<‚Õ„å»É¿ˆÀ¾#÷üÄÈùŒ…bÚíÕ#ÙëdFß“Š 9Øï2ğ¹½†\ĞÛT‰šôèmDYBáßOşÆ‡]®Tz·âä7¼É?¦ÌjãšcgÌÊ€uÎš²‘	÷¼f;¾ñˆ> ²jˆõ^[Ğµ=¼È~SAEO™ˆ¢M¾»ÿU¯ Õ±u¶ŠÂØ>B®\ÛEõ—ğÑ@åHÔ¶z¥Š5„øèÑ÷$¦ÒAPRÔ˜Æ‹ V şÆå¶Š/ù|¬CÃfWé»ÎİExÇµ°f¦wÆ‰9SùÜ	Ø`Ş„ËZ|'16/U6 zŒkU‡æ~„}-nÀzC]n‰$Kò<wŒ÷y=¿ìÙÍ‘yŠ<©Ïh÷¾bğo'ƒ_®WÔÜÌ¯±£ji@GEÒ{U°²ëÒ66™ÉP²—í¥«0)l¨¯cà¼¥ëÑ*ì;Î¶PğÜ©C™o÷¿Ç‰ıÀ&£8Áš³Î•>óœ}­oš$ÜæÖG¤/É¬M¯òiìY¥[†®ŒL¼ËÃ½
àÛèSHÖLWJKšq qp0úæV°'É=s’•Ïc¨êHp@’¸8`Øø¨ÇáÙÀ[{ŠóoİÛúæd$/Ğíşı7E¼yéİ?Êm »5•ºU&ÑŞ1©/¾›Øã«é¤§3A²—šuàc£Šîäiü¹Éàh}ÿ<ßj€õÈát¥ğI¤ğú")/wEb³&7®¯­”úq¬
Û‰;3ÿÜ‚¸BNÚÎ›Ğb2–^èËè?ldƒ\6ˆ¶¯qèÉîUÅr|vŸt½/ùØ!øõz"F"¦¬ìèÏ¬V€”¼A©¤kÏwÛÈ¿’€@Ó¦zÍÖ¹ü©\õPFßÑr¬Ÿ@ëj||…e?–›iD"ÎIıå© ­™|>tqWR-vñøfÃaªècÕ4Ê	²­CSÿ ¾äh¾ÀR(Š¸
[²‰fù~äÂ9Éëˆz«z}f¢ğ»âõ!^¹Ïğå®=†wšºZ€±y—†B“f’^¼¹Å¼e]˜|ŒXç‹Z_¨2“€¿ñ£ò#à!•¦3ÈçI6Ä,‰$ü:Ofª³Çê8p™È¸Ë©€&ZÇc‘0"#k™?M%r’8ZB) Ë
C’²–ØØläÈ’o†´/mIVñx|{I0r˜AkÓ3¦Â,Æ$‡³íÕ§o5~)kĞ·u]Eæ?óUœjŠş¬[õÙ*èúíaTğ…7µ)qN*uO“ AÏÂDßª@)òÁ¡:Äáİ0Q×	Dç=8h$+ò0ÄèW!×4œ„ìÅÃ‰9İÏQËóf®hîÉÑÄQš
!}åmÓ]Sö²z›”áÎ_ÃÖ±0§üy¥³èšÊ¬…ÑÀ°ú²ãc¥OŒRi%Ã¸Phe Ä f^»:ÜWgÒ‚¸QßÜ`^‚gğ8(Ìë¨ÇOæGãÂ~Ä@Ä[»JÍeí
¯	rXKo¶M{Ö™ÒÂ™o.İõpŸgşY•ŠÖ°¡˜ôt¥©ıgl‰¨\óA¡II6P¸‹'AéFŞÎhİ¨e¥óñK¾ DS&¯ÿbSv/Âvÿ”•MùO{,œªƒ/¥jÊ'6_NÒVi—¼SCY/7Fî$‘+’CüÁ‚HŸ™Ç™­æBñ/¤|àÖ°Ï}á*šáÇ0·kW7ÛºÁ'!<ÒÅBºvÉ”~\âÉ`aOÊÀú}~Zßê2õ€nt Ea±É±A…àA
!ú—G¡ƒI?$åºk +\Î_yÈÅÉ)TH˜@BøŠ£iËT–”¶’¬Ïˆx+z²\åO¶u´g½XÉÜ•t‡²ó|	!I/Hm•XOñ'nC{öc—£İ1¶¯Œ™©ek˜¯º³²şùÇ!ÙóSyÛ;â ùvˆ`ıdt»0s¸ù$0—˜Øv9x9”]JX>›—D†µ ’<Ê'Ìÿgö8‡—ÂgşÑÆÕFcj…äóâpÍÑKŠ¹wJj5#’K¬ÖtÛ±ãhP4ÌÙòmÈvuÿ3†Â8}s×+=5=™İÛ¤€¨º[²hè³å 1ÕÍƒúú’±Öï[Ù
¹ceÁÉá|RÇ£Êr–6Mã®ûSpTá:.“J†]¦ ¼bT†]“Ç#Ã7ÚÜë[lNFìEÙ2¶;ÛÉ¼òÓ'¦(GĞ‘Õ]òÀ²±»ï¬JÇ^Ñ	wÃt5«©$õ)¶Â¿ŒşŠÅ$+İW~*ÙÀŠ»©..L’ÍäNœf†:³t‘exœ¿c˜°r×fÒz)Œi¤˜¯9Y~˜W8EC2;/·pñpS‰:ğO"Bª=…TÃù‡É #ãj¼‡,†¢w_Ïd£ñF8Ô>Ìô"EéñlÃk? ‰şE
*S«ïDcü#I¦0¤äúİe•Ôg„€©şhQêg¤ûÀbx”’»¬fkÏätpëÃ”ÊzîñxXL“´6½â¾"ëàîUOD:3Cp°3ÉTË(*ùá®V{ÿq]åu”U33àï‡xÂP##ï‚Êşç~àv2/Q’YDJí%yW%©íÄ(ÊÔºuïˆİ¶Ôuy¡ÛÑtøò1J6ı0<‘dĞË*]uİt#OHËg<¡·»ö¹$LÁjĞàg¾Zøã‹·Ç ŒË%]*îç/—¦gFæôº5Ÿ9ï|gEÏ_àxZ€ŒqPÍºò 4³ÆIÔ®‚ 7’‹w±GÆWsÜJõf\@oFÉ5ùÎmcÊ¢"Ç6ÏtY´/îO75F®v/ç¬Â÷ ÏĞò¤¼ÿ£oqeÚ£ifëq\ØËÑiv€Œì]Fu?;
ãúƒÃ~ÇCÚõ°S
¡¸°v‡©«uTÃ·|'Ú•¡è´Zø[¤.p?+”Å›h¶û)Ôy „íÔ³¿ÌuÉ¿¶ªº4ôšù¦A¡ÎñïO×91ıö&tŒ¢]ã×à¤‘0‘è²ükzå@ÜÑ	CŒÿ€Èvò•8"Ğe¯şLëÛÜ¨^$ı¸"Ô×7 6j
ÂxÎÁ1YdÏrõ¢âm/2a·´jŞa÷"¨:qåPsöGä>bªB¡[B7…ÛùbÖCà.§z!øì:tÍ­°‘]~Ÿ[-KKŒ ]ƒA21¬j°¸3»Šxá¨ÿ9Çr1ÚµxâøP]I^Ú’D-—SªÇŞ(¹µÿÖ‘éb_"I™Í	Åÿ¨ATñxúMV1hÄ´$)Ô”n}¥vQU?vkùV,°]Cê> Sâ©º5Õ\¬¥Ë´Å—öê™Á¦ËgNÆ"ÿã˜hÌÕ®Áõ|·4Z,S
[#>Â8¢é¯¶´á	“ÑœÏY÷Kÿ¹Ä;ÈyÅb§ı) ¾Ò%-àÖn]^ì,Y^!N0_Ì‰y3Ÿ˜s°Bÿ>ÀO ,t:ş0
~-c…„b‰k‰"ÚìÃC"P‘.r-XÎ«ÈéBAÀc G9I]íg•3tü§´âÈ·¿e>Á™:MChû)~eÙ„Ï+ÑÜöZ¸hÅ¯.P‰E'RÛÉy‰¶/A¨%¨›t;İçÌúëå/¡ t¾‘]*Û«ç»âF0@–Á˜2ŞDâ— h„aÉâ$6°”Î®‰ˆñ¿œ‰•DºídÅXè«‚øB´d,LĞ¯(k´dÅÔqºÍƒÈ¼;\Òô³¹64—~1lÊ“<£?(ÜõkÉ¥c5<5‚\N±Ô¾–¨Ö¦.&:ª!«ÒFóŞ	vğÑ:äy»P´cø;ÖHL‹°ó,#]ÃÔğD¿2n†\_¦¨Ó¾é¹äÇ‚:T]|x,Ş“^ctÇóÊœ§l=‘¦<ÇJÚ¦õ3«lÙ.…–­•ÎØyY3•¶ÏÍñì{åRN1©cDÃÚù‘İ4Õ"áºÇC|ºò^ğöqËÀb!¨.x¬Ìù¬Ç‹4¸ú?‰ˆôÀqlß1ëVí/1–èÚúÂû€‰Éòÿú•(zÇ§3X– İ}âlzet²>äÌIŒz“³—.”%f –r…ö¶02êÇ`İ•Ğ¼Ì¡ãü|™û¶7?…¤Ÿ|V·-¸µXp.åM-N©x9ÁÂ@oÊåç'=áIä…g\->µmŠ?ÉWú_qã”**ÚiÄF7/Ä8;†)Òë²ƒÜ§ŞL÷cÙ+\kByG¹…'&tÛƒZtNJeü$–2Ø%v/QFˆ÷½O˜FnB!N~ş£<Æ6¾æŠ7eómî)¾w)Çİ|—×^c³Õ­5Q×bM§ñô{l˜)>-€‰–„µZicëù‹~„­ÌV‚s¦İo[h?olf­Åräe 8âB/e[ªïœqEßæ¤tnj>ıœ_x¯§èÙú‡Y!ŞêÒşÑúg¢óæ»*ŠÖ¤~E&.pY‰/³®/èj 8™Iê]-¯›}Ì~±è(ÄŸnSg\á!”µù/ı>•êA@˜qX©V,ÔÃcz3Ut‚?óà¨İ¢dÅ£máš[÷O1ÍYÇ¸íê·­Õò¾Ùm)Úé“h”Õ‡kCP†|ÌöÍ‘œÇ9§a'ßô·O¬yÈA”íKÏbÊô}l¥¡6vŞgï˜{	PÏ™Z‘/\3ÄÒßAA^DŠ­ÄrĞ°‰´õEYµ• ZÆÇ.fí—!Ü"Íê¹h]Ún[²oß76‘étq;ÿ_²Ú$î¬pyşäXD.^»h™+ˆ æ Ğ M•g¢ÓŠ0Cõz$å¦¯u˜IòeNüÏYÛ&´ƒ9æ)+ï¤KZ=Ù=â¶ÔÙ½ïÆ»RÇÑğ2ÌìÅ.gş1ü;rhjÿT³sñK¥ÊM:¹Çñnkâ¹×€±_³–P-˜Bå¤›/¼HŸAÖóÜûpØÑ+5Ég®4slñ~aví¯j´Vój¶ÿ{_498ğõ¾"œ¶£úñ¿ósFàÃŠ»ĞjH(•§fÜŒÕn3,*! 4Eşã…Õ¡³%¤-y ¿ÀàôÀád¼ğæS•âıù}ëÊ5Û`½âW{‡ãç°I…%ÍAˆ«º±^ÿõIïùc÷­·jPGW9ç„$$¨1H ªçSÈù!LŒv¢V6vÌbış¼_G†áÔ=k: ]Åÿ„ù‰!¾ Ñ£yÜìÕÒöë4"EïësÖÚ?âí¨aU”œg®×õ=@à§“ŞÖæTÀ*¼.œ	”[³ñ”«‰IØ%zØpÎrº¸—({Ê”Š
Å<jÌ^ä"æ8EÊ}$Sº"•Æ¹=“K@½X‡h!¥şb'¤»q
.şËb\€r9‰˜cà®TÉ[|£‘Ü{§ûdöÏc–ù*8/ÁíŒòÁ3ĞŞ–…N7DáïŸU’ãzŒŠÂ@ß†85U«Ï)Éé” UÓ‘a…3ÁÿÀ¯´Ô#lååbœF4ÄıÖ±òìı®ÚArQ½şÓ9‡Øñu–‡?AZxÊÒpWOPäˆ[Üz±FK/o‚×»ĞXoÈ›I~{‡œıõM×oØ“ y1c|+%c×¿×¾iä~ÜÛ5=šWN9Ä.I;fbº]íçÿ
!3LÏ”¦{¨øaLRW|Ş$cÑu¶½€5}´/a¦Ü_[Ş`”ÅhK¾AJ~/åu£
Ç‹ARüÎĞÏ0ôü½Iô¥›a”ÄOÏ	‰s%µfmş´Ñœ¬ÒİWL>ùnÑ÷P~“¼tF{§_336%Ì$8%œçµ*™Å$ø+æÆG:ÖÇÚ{—zÜ–|A3‹·çWÁ]ùfbfÛKğ*äÊ^|¬Ò›e(qFÁ4}€½Kd«qKc*üA…¿K1ÆûNg¯{Ì-ì8~üHzZlï—Îì¯ªk–‰¤ÏÛ&ââZz¤{[ëÅÄH½w£&¸)µÂñö¤Õ<\ß³ÙåĞÏvRÆªà´<^O¾UFÊ¦™Ø×Ï²ÆŠFd Æ¯-8†3xe9 ş¡§õS|İÁ~y¸Û_x2¼Šùé.…Ç`Êx®¤ òôZ”4Ğàm¾Şüƒ¨8> ¬`—Ö_ô_ÜÎ’*°hè”!róµ,¾Ã]RknTn›`8ëº¤Ù¿«Ç®ºpákŞFD„SBiPŞ†(,xü+ÚS®jŞt,Ow7çŸN-Ofá{²5¿O{ë¹Ğ:ìÒ}?Í=xÉÜEËº?DF|dÊ·í
ÊÔÌ56]:È ".báèh¢68 Œ`]†Ñxi äßÑ¤æïŞê.¹{N À2"Òkˆ„ÇŞ¨¸‡ştå–öevĞÅç
	ÑQSõdHÙö¶‡„2«Aø·dnîÇô™MÖ­/à¢¬z|A×Üøã«N‡ÀÁ=óÑeç‘Ó µ
|ï5IšÓ™Ôôlã²‰»f¤+;>X–éWÀéĞ(¤i¢ Ó‚t hªŠ}Û˜UJÒ:wœRöÇ½§ŸKÛôŞòÿ´áXô˜}KŸ`GÙÇQzq²šã!„Ì×³©4½ìˆàŠœ3-‰ÚsJt;“Ú"*Õ˜‹œÄ[^šJRÚw_È[d“”D²ıY€W#ºŸ—[íÂc9İŒ/[œ¹NxÎë`\ÃxB°keŞ¢q6Ó¦èÌí}‰`úBÔˆø*³FÑZ9|¸f„Úã¹€Ã»[•Z`/¬Õªá“B¬a>ùçÿt’:ÛKŠ]me­dñiµ$U0E\!tä€œş‘£p{Èé…ğ«v‹˜ğtZûúÊcşª¢ÿÊ!LIêÉÄ+°))s9VÏïªÜïƒ¦!İ0õØ>y”Íı’DjïOCwÕ‚¶º„Æë¾$¸äó^Éƒî[Mœ¼ÛFÈ&|ië;.0~ÿ… …Oªl´Wu×'€Jå¾ûëpĞöšf×iÄ0¢b7¥û1H®CĞgPO›w]ßÌã’Ş/q†òşkû÷ŸŠü˜í4EùÌSğ.›´@ãkÒ3Ÿ›‚;Käg|øÈDrhL]Åw«I¯5°`‹ï.rZÀ´@·ç^ª=“ÿ b<i-A{=¢äË§§ªJ$^œgÎÒñªL‘òïÄUb¬EŸ‘šacº•ÖRÊËHà¢ 7>oë-¢0ìnÓ„ä»H·~À	­L6À}©¢YÍ3¯òEQçp!ØĞLú'×
£€u¸0MM¤Näˆµ5Ì³{Ù‚6»ÇWŞ™êí—s±^ëÕo¡>4†‡XòS¾ËïÃ®ÓÂr:œ£ƒdÜG¯îqvP¬Îi
Y%ÖÜA¡ÊÊ&E¼¸Sk{é¸zÇCë	oğrüA€¯ıÎ÷§îï(£ÅôéM·šáÈÂZ¼®‡(‰P²å’°()›?U§OÚ¿µ‘rLî‘%æîqÔD‹ŠuÇÀÑn?}A˜ÙXÎÃÍ_ZÈFL^§%¨â¾?`Xà¨µäÆ-ƒÄæ¥£çq‚·¢Gš˜ÿ^¾=; ü÷%ç·Ñ#şë…èA?dõrIoc@ÃÃÿóòtö£Ç1,»oÛä(0- sŒ8Ÿn_%±ÏÏÉc$jH?ÆtA1µÜ@¾çø¸Îù!'2£M+‘Ã×†V€«ß/§"!­!iáòÂ÷Ôôeïa06N¾«uı}Ó3˜´Zb¾ˆ†šòİaÅöÒ™µu}A*ŒJ4Ú@YÛÿ7âASÙØ„}¯(:0HëÇ2è>€™{&´7,i7­M{©o¾ÿqU“¾Å±ÁSI×ÁxòÎ
r6Š¶¹ó=¿}†=/÷¦_¿Ï	›Ÿƒu*&—X³î£W®9â>Õ=õ-twbò/d²@KTÉş[†¤ÃüQÕ*£‡
>o„fºÜXšT½F_î*àÒ¦V”ÛJp¾fFó)[”o:eåvş7ş0û|”q»GTË/_­Üï‰e"ˆ
£túQûÈUI÷‚$U~‘(j¿Èö;œ ùŒK¦cSÂdjìĞ7İ]\"u[tÑ÷g·óÓÙò‘-ĞÙ}(•]gÖ‚Yâı<n‰ÌôÈÖÎ-ÊGÿa8B7œ˜Bú[¯Ü˜xÒe7AFİC«Ñ-ìoQŸCX
\*qŠÄ	0pÔV›y­ÚÕŞÇ¦¶<
å—KÄï£×å¶]å_ÌæÛ"Şyƒ€¯ƒlÜ<û÷‘¥ĞøŠfß!Öí'ü´+ mvpFĞişñI4OÈ,·!1í% \g¢AHŒÀ“ØòŒë,NõÆpH©éGÀzî¬ç',pÕ_&ôµ çEîÕLÙNò–êcøcO`>vpÍGQîÃ÷×pù¶H¸Mhü0a‚­›éæ-P‡ß*vò˜énàÎÊ{‘«-YznSÒøÒ5­rì]ë…Õz1"©•çâf	U”øÓğÖ]’)úÛp“u+¢ã˜4*m)f¿	êòÙgÀåØÿ)ëí†‡wlxÔ^BÓo÷~üzio¦r¨«†vÚØĞ'ƒ¶•şmj‘ 'ƒ õ¤9Ô[œ³ÉYT›ñ¼!”O‚¡øÚäCÕ4ÈßÙ#~€† ±§B3ƒupWbD>³ú¼eë¦HË1‰¤3’İ0C-´Š¬¿xzŞº!†¨ïû*ráº§¬~î$·‡‡Å:Cÿ„Òì		O‚ƒHd‹ÌÕyÅ*‡óq:zP%wÄùß*÷4Ä5“ÿÎÒƒgF¤"ZÉÇÃ'Ñ £îHÅe_3áÆD«í@voÉŸ^C&;t£GÀÅ_:aS’êÓaqšçal92`²OJÏàà$a"Ÿô«B g6‚[E$Ô±íÜš­tP?'ŸÿtdpËpå4ğ-{ıÖäÒ)§K³üÒ`55|©lİ]ÒÂÛ$£M¦¼˜¶6Z‡óÒ«ÇæÙ…pA‘¤TÂ8ÑéŠÀ.“y;X(ÿàÀ}sHµƒTŒùæ{£ö’-FwÏ[-GÌÑ!»¦ìo´QÖ«µC¿QA"ïœúÛîû‰qì6·yÕW”<µ±$]nVİdY-²Vö©O‹¤»ç¼h>•ˆÂ|íµøº`“£Ü54l: ö1=TAÓÇ^¸çğğfWYê¡öÍ[òó©ÑëÊèáô»ªI%z­¯«!aBÖĞZ³«¢ç!Ó±ã¯Àåşº,»˜]×Ëı1c2ß†Ğ˜™äˆÁ!OÑ%?.ç†Š½vP†Çs(¥§”°£‰¢ò­¼½··ü³¯ÁÜMü,M8Ü)4ÜI|Fqı|¿î“–I¶ğÄg"&
ŠpèLÂ±èÛEìjØE*WXfU~Æ_ßè¦²ìªÄ¹qû¬«°ÇŒÎ¦ü»åzâé~9/'µ$"“PÁu¤$ˆì! kÿ)TÎ¥SãVt€—~ìÒë¬ÿ\lå¡íüUˆ_. dLXÿü­±äßd}Ä”®ƒûîNÎ5eçÈˆweáİš Ga(x xòıèİì•Ğãíˆzg![GÑ¢WOÏĞ_7ÀWû,ÔX¦"ÑYºNˆÑ„ÕNˆA$œ;øô8(>„Š&¶¥d]ú-øó½†¶uqp`ş]h‚Œ¿Ñı¿BÛU÷À
]°V~ï5%o‹Â&lb<¾',Tê´ÅZcŞzDü×teÅíş¢¬îª†mºÃpÆZ:EMã°”ïÀÜ/.úpD}V-X,*I]¶Á¡ÁÏÑ¥ØEhEkHÔ@‚İP}Ø«åš!Ôrª qN+;Û÷¢Ğ(”³¶‚ÏA<)46ûhØA/ø”4_•â›­›ªÅLkÈjvÍÔ×hT¨åE$\Øíw÷‚ì°ó^%:ÁÀâáù:F­ÅïŒ¹ÉŸ³ß¿ãØoûã‡MQq¤öcİïüü®rÓZBí*Ã$Ÿ7Ğ‰FTô¢ZóKMèğ³â?Qá K˜¦ïå·Iñ³ÓÉ2*‹/`Z#µæ¿”eö>sœ9|vJ{¾i×U²5ë¯GJŞ·ï‡sRÍ5!ĞïÖYrKÍ·2™!½S.‹f·EØDÀvºè£D©õó»pg¶5ª)òUò+á›*jı†üÙæ5ÛAæ€àéú1×8íÍ¬â»ï_Qı€Jw/ã#d\p§I(E Ç:†uÁüD·Ô ÓxYã$_cÀè¯™‘ÿ²¬@âíhaœ¸«öy„s9–¼ûFã“iäpÈGJx qî*Iãb"éw5ù‹á6	í5Ãr|½¤CAÆ%W@£ı]†KyßRè:˜<Sşİœ«BˆÆ(ãWë[¬è'D79÷é\—šŠ¹¶AôİÕ½Ìö“ØÜdpE^·<ä¹FÌÈ¹´BÅ*äş1Éå§µ€Éì5İ4î]™˜ö¨ëŸOWdz:6§ßm­	öû[²„{–Â|–T³kåÎìµ—ìD¸>\í7Pm¯«ã™¤5âÂ/™7„¸AÀæ·(µ#øÇ·$6¡³Æ·Gz¡Õß³rù^ŠP¢©ks€9N;F°¡# Ç=Â˜`¡yúV	6Ÿq-G®®ù¨ôshf+åµñõÀl ıîª:-{zõÈ¥øuÀÜ ëfÅr¾"ëifÔò˜ˆ²éò@B(ÎÑŠAéà hËü\‡®Ø¶¥º?ÕlãNšØk„iµ†SÛoƒãvtdÒŸóMH.Ö9*Úr_ †åÇ	‡TÖc'Oøg`>ìÉq÷åbœ“sXq·™“É„h,³oÃêxßb#¸nj™Î(oßİÆ,h¬ìŒxé| ;ôúqq¡Lr/³º®oŒFUkO©>ki°Zƒ4îèæ­,ˆqÔ÷˜ş=ÉŠËüp…33ônQ; p‰|Zû&·~‚ÒRÍØ=ÜÌ¢DTtÀA¶âzjàåÚä¯UYxBCÈYÄgè›of©Œı7Š=x¯m5,Ûø?”@OÕµ#Wk—á4¢@ò1nèl™I ^ næªs"Ò>èH€$ŸeøtÚ”#zo†	41”U)İd}x˜ùŞgoçŠd]ã'íµ~ß§j!æJ¾Òx<z¦œf*Á®““ğ‡¿Ó8æ?ƒ=º±ŞĞ¾Öd\ÕDˆ5î(m\§moSM‚'ñôìLè‡†®Èab÷z-ÆRÆØN™‹ä‹}ËĞ˜wÎP¡-%–±²v¡cÅœ¤ƒÃQA2mşTxğ§<
/dQA%®|yõ$qè°ëbdın$€w½ÍP~ÉÔş‚‰N%~XN¬’'a7®• †ø€5ª°»oÃ*{4ëJiFôø¯×=áÊÛÕ…úÎRa{·CÙàqıYÙY1ôiêÌ>F4âşKÏXÅmûøøV!¡YØuŞïõöÊhqe‹ØÌ8ŸqˆW(K1è‡ñJ"qèŠ Å%Ôº3pu†>rík]…Ë;¬>÷eöO¤Ë‘q6èÅÅÒ×Hy0L;…•¼Ø)"ÄóÅu$UôVÿ:«®Èié|ğÉ7a_ ˆ=¾¶ìuEïÁFT_[¤Ô•`¢•C…vôqğ«Ú3u
z¼H¶›R§'Ä×3¸S±'¸[G‰DÇ)l‚«íRusŠõÂ+áY.ü´¡Z^Ú}Âƒ{ª¯ŸõÂå%“Ÿ@˜Ìı¨9µl¡{Ä°u=IÄùôALKAµ¿r€ŠS05
ü£À„FAœWÍ&¬ê§IºİN×ğBnºŒ„›O[/}dêÊ"¤J<Ÿ¢™Éó‚İOÑËD@/c|qŸßÚ¦)_3øf‹ºT –ä€ºth§c5¾E1³rèq7‹Ş¹Bö‡,gp’´ …¤
<E=iûo0Ûï‹’®Ó–|YA7èLfo_´½p„PßøßQ°¼ñ«d7¡o‚k§zÏ«póq bA,Ô]ÿ¸Ã¾öƒ|¨üğîè¤øšŸ§‹D 	Cá;åñ;gO…O.™}ıAì&V.A.F<ä‡2ŸAå»Ø ¼†G˜ÈÜù:DÔx«ñøõcĞõğ>•WU³t%~Í½GK!Hó±òã¼ÑñŞÃİ˜¢µóëØcc˜ëRgÁŠ-¨Š!‘ÖĞänSÖHvA'EÉ¾Gñi”õ5ÿ³?±‰¿û4íÑ$ù{òÎÏh½yµz[Ü™*8Èj¯ûJƒKFQI é¦åG^ü›LŒ_	›ó¯÷ù×y.Ù „¼ğ2QÜî˜ĞÿAêuŒFÙ*üNÛ-ª®x®-utàõÚ a±ÙÍ®ÕbiæÀg“~¾ñgP„æ<Ê®Û_ ³‘=gy°î>oY6‰ÓšQ‹bü¡i¨â²x–w›œçv†àaWÅÀmzæx¢àûôOÖ%ÙVÍ÷èh.ÏÂztÖşW"ùêÌ;CO6*1/PjK±Õª@t•TÊ—×ç„Ò’£aëeC 9NŠÜ<ağH%°Œ•®X(ŒÅ)+‚ŸÇ Êè@éLæsNµ˜Ek¿˜pIªU/1)Ïz¢ZJ57‘IßáeP÷$ò eïpf¼Vëî~kLşGü{á·N«jæ›Çâq‡qÇ„Lz^šY®Æğ=SvFf¹&aV…ö×5RÂAIduªnO7b7£ÅdBÔùT!$Èd®æï–6##¿¬¶$`	!Çæ_•…B»tªH‘;|âü×ì‚Ô
Á.D³.Êˆr)]BäÒ}|¦ÓŠcWÿÂ]˜µÖ†$êê¿ÛWíw¤-+šA«È¿ì±,fúx½E¶„ëõÕ#åòÈ5›x¦¡0j-÷¡ÒÔ¨Vs¤^•½ıp_û$tñ~çï¦ ôV×ô˜÷şöqÙo{7¬5‚£Ÿ³+ÛñÉl8Ñ]E{ZŒq¦H‹ş	•Bh±"²­˜d˜¿~W÷Lx³úÒ¶/íÖÇ•¿P6Ts4ÜK ^Ø°úw,¯¦ 'ûæ)xš¤@ï+;Ş×´Xas`R„z]à±EzÌ;HW™J¨{P8ôgSß=|Ó‹ùyÁWø·~ëPaIQÓ‚/1    ÕÖ´” ½¡€ i«6±Ägû    YZ