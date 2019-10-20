#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="264861614"
MD5="8ae92d8b25fb45e44e5dbfbce4ebd6e2"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19435"
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
	echo Uncompressed size: 108 KB
	echo Compression: gzip
	echo Date of packaging: Sun Oct 20 16:17:47 -03 2019
	echo Built with Makeself version 2.3.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=108
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 108 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 108; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (108 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ Û²¬]ì<ÛvÛF’~%¾¢2±ä¼H²•XÃÉĞåè„yHÊNbûğ4‰&…p P’­ècöìÃ}Ø§9û²¯ş±­ê.$¨‹ûìÅœ‰E6º«ë^ÕÕİ(W|öO?»»Oéom÷i5ıWÔ¶Ÿ>İ®áÿ¶·TkÕ­­Úxúà|aÄ€6ó¼÷7ô»íùÿÒO¹2ö^ùüòzù×j;»_åÿå_vÙìb8ögs——ÃÓ/*ü¾³$ÿêîÖ¨~•ÿgÿVFW±ğÔ(ZŸûS4Š'sÎƒĞ±™ÍaÂm0ğë‹|xøaèÃFÃ1jáÁ¦Qlú‹ äÏ¡?v¸7æĞD-]à#£øŠ ùŞs¨–·ËÛFqŸ‡ãÀ™G¢mpê„ ÃØ÷"æx!ş"r<ÂÄ@ª;şB»qô'ôØ”À‚ébÆ½(,ÅŸ<?¢yø¼R¹¸¸(Ÿ;çÌwoqYÆáåQP±1«ôO¹ëZr6‹-"_Ãö=ñõ-‡~P|>ÆP˜ôLÒ4LğÙØ„+£àúcäûxÀ<àçàÏ£Ğ(4;Gİ^«Ûşµ¾±iğaİ,]Qãğu§·ß#¾6éû»kÓ(ĞÈµ=¬šèC€ë¦e!æ –Úg
%üğGú¯ÅØ%fY‹¹’·}úòá<ğ/ßÓ`œ‹s?ˆÀ4Œ‚37o t…¸^C½Öcx÷ö :åQH¥âÁ”{`½Äš0»6˜¾	Hs!àÑ"ğ j&qlTŒã`À:–Bºıî#¬{(Wî?‹£ç¹Áÿã˜ªjHjüYüÿ³5şŸ’½İeÿ_ıÿÿ_ÿ?#×o1Œ7úÿóÄÿWË5ôÿ8ì9Ôª•ÚÓJí‡â~óüæİˆ?Éxÿ‡p(3ø%Îâ!z®3
Xğ½
ÃgÚ“§¢‰4@
„©iÊ_ÈÓ‡§èËĞ¹†ˆñœyö¹yhˆ¿àñ‹nÔÙ|ì² †÷H=±¹+,<ô¿£8¶_x,B1	ºàÁß‡ŸaÜp½²MäòK>~g6ÌĞ€ã‰&ÀQ`ŒO™7åûNÀÇ‘¼ßØ¼’½oÍ„‡u0MH9kñÈâò)¼‹ÛˆµáWî†œZøøÔó-¶¾5Áö¹'¿tÂ(|hÂ·Ù½.jø]9şäÏ‹rŒOÛ(7Ç;p\¾qpØnÁãÉü	 Â<†0
0K5"›º@—Eh¥-É‡~PÎ@Ò°À(F¤\“…7nW@’±‰¿ğlÀŒ£Ô$~+x{&.›Ö1ø`†Áë;Ç­G9<Ë²Ì,m­>)P‚ã<0î¡ÖÒpŠoÛ§S#q`ÉÉ-H4jòû¥{&¾	€Çc:`–h5éçÌ]pbx“©$+‘¯ú·à$ªŸ3Ã +Ï0.£ş‘ney‰&†Ö^ß(môç®!ï¡D*‰Ñ¥ˆ›F¨	âÓº‰Ú"€ŠoØ2Ä."«YUÀo¿]b¢RI@*,©{1¶õi×-GÅ­&ñšøcV$£ãIKWøµRy[©Àõf¢½¢™z¼ù›È”
…½=ú÷±èS(
DK¢³ øw˜|o˜õ¡aıVµ~Ø{·‰Ò«&#ÿqõE9Lù%0w6ˆÉlàŒ¥4—±JĞØ­Ç¯P” ğä!«$é%÷Ğ‹G¼?fsj1DlV/]êµ†'ıVoØï¶ƒÖş°Ñë5~%¨J2b˜T"œeç@ê¼±áÔ«{Î_òóİw›„®Tg1IÌQ/­4™o+HÓZtB§P”ì¾­›´åˆì=)©ÖDIéa©x÷”ÄßBTŠ7¥ä»$#”FHK.Õ;ÎcÑóeK`JÊB¾<0ÿÕ(RWñf˜!Áˆc°ÉéŞ£nMx@¡¡
£8 Â»¡ÒQ|Û‰ô@}È˜Jµ½øwlÁhQI«Wd÷õÒvÜª(C*3…ŠÍÏ+ŞÂuã®‡¥ihS†Ôg
\Ò&àHØËôô¥ç‘J¡†¡„Ò]âƒnÀ@r>¡Kıj†ì#bÑE€³‚iLà`
$~N0ˆØC_<6ã"îà¼œÍĞCb8áŠåo!ŒC#jCmÂ¼)BI¡¯	^Ç–D6[)o¯§ÑnN±_N ]ÖZ*•Ÿ¼yüîzI_%|'ËwrsÄ&š€ùÍÈTn…  âš(?³¤1>FGø­Œ~IÚ€dmBºëıO!ş­÷Iäç»ÅÆ|ÎÉ¨…‘MÈìh­j%F]qj†î”şˆÌHK'J4tó~j)1ûãj)RÂ1/2¬¿Ur:ºŸ®iW»œŠêNyi’/¡húÿ¨n&Háøi<¸§¾ıa&â’#ˆp1øá2ïŒá{­ÒiZ-.ë¥ˆ9.X5ù|S9Ş¢nùH8øø_näÌ.ë¼S†xb ûÇÂ9÷ÁHc¸’R~…¾Ú™8cTu¾éã¿cŞûÁa‚¡+ÁràQ‰½}$1*2Ûcèe°ˆÇ0Íj–B"¶æ¯ÂdVÏ÷#Í »YÚ¸8õÙÌÙÙR€IöÓ".RqiÈ\ğõ¢7ägbu¶ˆÎ7ç®4ŠÈÖâo<µ²ºkÄĞ™zDt°ğàÂ‰N1.Ê¡8îE>åá[¯…Ë-´ïr¹L*ô×o·]ô¯X3	/d«õ¸O¿ŒÜadsšÓH–kDôƒ¯Ÿ/ºÿ3¦Â‹5Z8.ŠãÏ. ŞVÿ{¶S[®ÿm=ûZÿûºÿsïıŸ¸şW«lU—+€ƒSŒËŠn’{Òu@ô@æ°\,Cşn’ Fåvrnêo S¹… ôvS£wt¾h4zÍŸíXĞğìÀwì/T%4Š6.óÇE@’ÀÇõ)ìLæc@Z"æ2›a¼†nWjœº…pşñ_‡;œâ °Ù%qùòƒn“–}£`c|’ƒ¯ËZS…GãŠ†^öxD;IªV¢ûéZÉcód´ğ¢Ô¾/›²îÁ/ÅŞU“†´àZˆC7
E=J”›mÚ€ƒ#ŒYPûáî#EÍ"F§– ±]®–«Y8'½öI¬›z÷/<÷Ê“€s\™[öƒ)5U•ˆMÃJÀ]€‡ÛÃê°j¦ !”aûğÅ°ÛüT7+‹0¨¸ÎˆŠ^ÅT·æÁKİxˆ],Zy<™.ƒìµÚ­F¿U7oœøU«×?ì×‰wB«RJ4®ˆ?‘K;w"içF’vh0Éc2.¿6D;µÖÔ[¬Ğ§ÉE¡¨1@{¢ÂlÉ&l]¶†¤^
™)¨Wm³+L²ÖõüQàLYôñŸhK´q°Ó ô˜áaZHYá„ÎlôñŸ®3Vë€`V–ªÈÀõ¨ú#ñ«ƒï¯Éòt…ßëØ«*Š÷ŸJÑ&şMÙn
ÒÑÏd.­_ZuÊ„ñ)q{v†¦b¥¡%5ßÌ ]bŒÑ¼ò2G­uS©jÛÒ†€ˆ7B­f¾Ía"}f¬ö£ípîSvL`½“ãŸ!v·EK€D§´Ql•«Ö¸w®ö+]­´}óÖz|}xÜ4ÚmÕí·Ã.®E).î´O~R‘T1<e˜C"ya€’LAî¿:4^^G–3ãu9Í×2ÚNyúÁÌ¡.VšÜécºZ%ô:
¶©t0&Dˆ„,›9¬[iÊ¢œ8ñÒ*„¨òæjH—†to…½U—ª*B™°©‰H*ŒÔÔ¤l¤ÌÄ"qiïV•Ò‚œ)OlfìSôÆ)åš†öiÄ™:¸ ÍîÉpĞè½lê½U§;¨›–M°ÅVÛ„N?~.óhö:ı¾ìØœc¯W»°š“WİWÛ&håëöZ‡¿ÔI2É…¢ W1@…1R-±‰¤j)uìœôš-ÉÑ”å/s`ÍJiY±ÉQ¥D|øàÌ5KÌnWêJ,ûù||ùLÄ3]£~˜ª¦·†P±i?u®Âµ,?@°aJşVÚ|JWÇŞQ£}mÂÊæg‰9Šo&;¹Öoî‰­Œ ¬—ç“µ½
qò@ûµXkeL»*N«n#Ÿ>ÛÉUß»øé¤„sµebşEÍ*óO+Ê™‡İMòÏ?wÿ²ĞËˆŠâh¢ÙšÊíÌøÜ&|_.ï'>BùÑ”µÌ%Îç;wÂyÎ;ü‰B~\‘d­›8s§/|Ÿ¶Ù\m&±ù\ì¥ÓuâLõ4T{3Õ–ª:´/‡òqãı^çp¨ôó£ZÚI¦ÆKŸ«³ÁÌl…xk+Æ†,\Ç&öà¢ıSĞÉ8|ü½âF Æ/AaXœ¤|“F6Å®n²Ä5
}qT£ËÆglÊAäÏgóËzéG£ ³3(]Í±Gø¦$Ñ¶ì=iÊäyš“_¦ş'	*«úÂç¿kÛ;»Õ•óµİ¯õ¿¯õ¿[ê7 Ÿæ AT —TıÀ¥úŸtx¡@ëw×ŸÓÊoNà{â;ÕüÈ—©ïÑLÃ£Æqãe«7<êìŸ´[}µfªŞôğjí³o–½®…1æ*Ë&)ŸbˆDá˜w°tøøNcV²†{W¬,\_ÓUhqÛÁ¼ò®cWŠÆà†işcâ‘,â#Ã`Á€¾+#HhŸ#ßwÃ!.ê%úû?ÇÍ›:cx(CKö·©’Ñ:¤ _ßÀa"¨å<C:ÅhB±
q+¥+f¡P¬‰–—½Æ~»E	ºîº•ni‡s[´fğÅ¾;
jŒ6¶=¥6•gY}fµïGªD"&e9øY^Glß5
›¸°Õå™%‚Åî«U3—¶Ä‡6§cï6]<H˜ñ&;XXK–€éæêzK<‘[—íK}0i +8Ï>I€	Ú–\ŸOùøìÀG…’y#1ãPªªĞ:ıXß(Q5»5OÒób[¾¨·eSÉ$¦¢¯ó¾ª<ñ­g&§Aãç¢ÄeYB'Kµ*Vˆœ¤İx}´£²^yæSŸø$âÄF²è—}`Á"ÇæréÖ–‡û-A \fÅµMãŞ9ĞRú•‘bNGTÑsH“¾mµò|ç%úFRø‹:¤X \­‚ºN-ç±Wº2]æ•ˆ
¤íZkcJÊ„ëA*3Ô‹	²eQÚ¬Öo°á·Fï¤?DÁ½h· Š²’Œ1•ßÎğÔŸñLM›©å`¡¦@ŞdË$Ë¨Ä3U´FäG"ĞxÈ~êÂÈåŠ¹¥ª~úxLf™µTxrJrdHÒ6)Qw"x!mQ®‚È´äò‹İ‰‚M0	ØŒ_øÁdìa‘İ/NÛûHW¯qÔ XégÆ^éºÍ	˜âêê yXs]ñçÃc³LŠ\:ŒQ)«Úb
¦ô]“¥ñ*MTŸÇ>ííÙ6„‹¹0òÂ•ôf]úŞX´H/ÔNú(á^ç—_¥ı&gtcº9 ÑªU­ÁÒ­únUÄÃHy|ğw”¾€/îl¥v‚=?›‚åj²æ²·>	ºÜ\” àBßÅ!ûø¶8í£œ€Ø²IÎrª!-$qÃ¯YàaÄxŠP$À¾ØdåöÃ‡³·
ÕÚ&f‘ƒê/õ.s‰Ø»Ã†ÍGêù\®@7S¥>:a×!§˜ĞzÙ;t®•çOÀ½ò¼}Àgş9
İ{qÊ1İÕ¶¹<‘©À‡.GF×R‚;œÍ]gìDéà6åËÍš§Ò¢ºíÃæá`ØhĞ#RŠÕ‚¬	H2ºbó.˜aD6SÇ“âôDjïÚ•w:m§5¸×I÷‡G­áëÆá B©»ˆ@ŸzŠ.¦õ¡ØâÇäí»±¼ä‚óÈcM1/¨Â9^L±òg×%|öb;X!n§PPt{&y=ò63Æ¸2‘„æŸ3'tf½Ã^Lß	¡¨¯ÕŠª1ª}©ØÓu™$} ³&º®²O=™8hå¥Ìõi”cJ­Î‹ÿ9«+*E&ò‘º¬ª„¯[í&)
8æç˜VÂËø‘yøA9kn£Ç6ûÃĞ§)•«;ĞôŸ@ú Ä÷›†JÆVò¾l¦˜Zc_×bëp¹Áæ
{[ã:Ğ»¡0F\ùûaª¨)aÕÿ”$áşÆ•ß×¿v3——RW„ÅYMí¶U§mÕIŞÎäŠªÇSÕƒØC»Ü˜;tµÓ·–J;Pz¶|DS’“íL¤ÀêÍÌHŒb
$İÇCô'W”-š#\+‘õ¨rƒ?WÇ‰ŒôÁ£`*1ˆëFwÒÏ½=ÌÌ…§|¦Ø¤ªãÚ23Ê7@=2}}›£UKÓ—¶'ÜËú|…ş;8é+5SüM/'+b±YÑU{íãì³|‡`Ä5ëz?¤Hˆ‚P¢3u]p)Ò8“Ë£t)°-á™‡@ê8õ²§Íuµk}m®³Õ!\|_ãy×»^¡é‚5iÕQk­&©)¾‹5¤ztÜ¾<9Rıä¶X™èšx+@F¹—â¦UYNõ>¢¼§t:í~}kGæ[]¡NtÍÏJDLƒ|³Á§³ìŞÊ—]R¤!‹ >s˜([––XĞ²Î1Ä\õT¢.–Z´¨ë«ˆ–
¼n0ê‰}Eœ¼1eq±_Ó5îI¯’07!ãôDÍQ/ıh\(Ñã¬gŒíCïœ¹èô‹>¦rÁX*ÁV»pWœDú?vş;]Nı,ïZş{çÙnuùü÷öÓZõëşÏ×ıŸ?õü7˜™Mƒ»íû4sß¤ ÅoZ³ô…Nvãâ=<e’ói€lÛ=j·Zrï-vr¯øßµåËe›‹bÎ‘9Q`eS˜ÌÇÃ0çô•guLÃÈvWfÉ¾ÿA%:^Šë€Ñ,^z¨%4»òaYÁD†¶•ûœºˆ*Â­(¤æÜí” Å\’«ÅØ«@²Z·Bf'ûÒ…öé.÷ôÏÂ*óÃÍ[¸ÖQNúbË+Ã8*faÅK¦"âÒ'3ó	üWzä@Y:ğ¸
d¹C£8q.Caì5*YĞ—­è\ÍŒ÷/]šy©‹à#Tñ‘˜ôQrÓ÷ÇÕ›¾	…ygë²¢c¯9†—9şLÄ«Ò[^’•Øö}™ RÎœRäñ•u‘+Â§¦¯ú†ü.;gÓHìÅ–§…½‹çœ®ÒÅEÌØî1ô¶âñÇûøŸ¨´¡?
èî%]Rv©Q´Ÿ³±ñ¼ë£:`3>Å«ÀtI¹T“¯ıJŞÑ ÏğüMêIÖø$ó°yd¡4t(‡»­÷ôhı,±‚wÅ÷ğ¯Ø_ó®¹Xnê³EzW/}V¨ú4ÁCGŞêÕ¿õ-ßBf{JÓç”
úÅæÒ#©Šñ`²·ÌãW¿ˆÎ$Ø¦(Ëu›}¹¾Ê”óİ@=õ/£´UÅ\ÜNy”yŸääSšÖjíOº´İwPtyÚ@¹üDC}†KØ»¸Uƒ˜Tä¦Xv0JŞ(qE¾OÖ±†#äÍ¾‘/²[³i“~Ñ €™;AÙàcˆ¢Ñ3o6â¸V-Y„XÙ0J‰}¥çÚ½%ætx’ö<ıw{ßÖŞ6$º¯æ¯@SÚuœ‰$Kv.cG™Qb'íîør,»Ó½q>}”D;Œ%QKRNÜ™ìßÙï¼Î>Íyìùc§ªp!@‚”ì8ŞY«¿I(  P(Ô…¤É4}ûÁ(H.¿cGÑ%!×õ+,D„qÆ"yÄ«Ë¨…q`^T-^N\l5.<®ü…ğ{“§_ç(EÓ#‰]4<‹ÑwÔğ>…Õ»/•g“€¯âŞ…G×4J¼êÈ´ éx¢¾k•Åä,sWÔB\¼ÔjÓYtæ£hoòax^ûcí>¶@Îfó>‘qûÉ‡ÛOjŸz³Qâà'hê/Şâ_¨¥xïaïĞŸ	§K¯Ğ'µ‘¿B:	³ÉÎüä‡óJ¸ü42%à ‰Dêõ‡?°••MFÄêc@´Eæ¨rHH-?\l‰–dP°#K7ïDhŒ½RÉŞ©u*	0ûÉ¤›„Ó)IJ¹.%"Ïª+×0Cú¡óSGÚZ¤ÙTí€z#r‡×—1¹ Lø$©*(š›¬MmëÖ¼$	%ŠŠÜ+†ş4vÄË–Ş ğ`Ã¯W™¹¦•8µ\h_6ur¤´M©Üè­4SBL°¥=WÚYÒ›™íYú«‘4¥¸ö:¹ÉpÔ å£ğcm6–À$ ÒM
7E
×7 ]“sY¨\~v”t)GE9Ò³©…‹{RŒ]…A<ãªYåØ|ÃŸ8´ªóŸ7RCaå&-WBWÆqQº`€–Cq‹…¸„ô+—Œ/•5ÃCˆáYÌ¼2Ò&’´j•Ê\Jêá—^wûø(îE¥ì©„µ\‘ãÃ×Ü@v£Ñ¨¶6ªkÔI%Ô6ÁLLhœ ™ZCYí…l`¹•ã‹]]w„+3¹SÀ22Óñ¦ÔÇÓ¯L„ñ7 Ryk4¨Í.i§ğ›ª$×S!1»	äÏ¨÷Ûã­¿éƒÿ)‰<ÕÍqx°0FµÌK‘Ã¨Lè)îîìéõQ«jµIØ#d¤`8ªm|c<>Àa:NÚU×F2$§˜ÇÔ•RŒ¶JË¹kóñH¨ª…áÙÈz õ²‡—šÁÀ@y6Ù¡y0ó’½èÜOz#€>Á^œÅ›÷Èï(İEæ{W<psğ+–à½Ì“Í|Ñ8×ÊÇ¹V:Î¯w^lïuIé7]60¥8hû·O´’IV<Á´ë ÂÉ‘,$ÃLóé•]«"p°‚“"£dv·v¿áÚ-_4Úš‘6ñ•W~¢Q”…¬%+¶Yæ^8¹&èø|D¬6-²f^ØìÙYŠ/&ŒnÕÑ•UU¸±(<åWĞƒnİ¨#€^Î3!Ë3í¦‹*(fbàÜÿd`;µ’N1j5y.°·ä3»›f"BV€U%µÙU ]¢[†ÇR¨7ÍŒŞÃØñÌœåÿ†'gfûãyÃßxÑU±Ğzûö£€‚JŒ¤)ëp‹Vjz~ĞÕ&a$É%Š——*Ú2Ÿæ.Um‰	²Œšz¯{ø¢÷zïÇëYáŒåÔàğ1òâDz gXÕˆIAsB_zf%rö”Ô>wúäAŞÔA¶M¥ó€p²
;vîïõ¸v‰`Î‚¤GÇ¡ö=w0
'¾+m	DGİ•T,‡R >G`òÌFşÇ FuØ¨CH7½W7ì045½EÓ×âzøXMõ³Jç*úÖQX|pÁıUQŠÕ¥Êà=ô‹=~ü˜Õ/
0¦_8ÍÃŒufÍ+$åVŒOÜë5ê*­‚­› ¡HmL×7$Šš$D0;“dÎ`ÊnŒlW”½›F03ötµ&«`¬T¦œCBƒ‡À¤h®7h/@nšB4zòÉ6ÑÊŒév}Œ¡à#¶»6`Êsî…{-[ê4ëãÇ5V÷¦Llò™…ë …’^øqƒ'‡˜Ôšõæjıa’ÈeÎ§_	Ç-ùör¬¢›Vdµ¤ëî9Ä°ZÔEäÎWO5ù#Iç,_Eœ*È³p¥ìˆÄW|.ÑTF=@ü¶£É/ş¾S÷©iZ£.ådÚL#&ª0£ÊlV.‰Â€;—ÔÔú‡.‚ÚP' ˜Ü¦G/5//FÃ0Pº²rıÒ($'åe4”¯ŞÌêÔlLç,Ğ.Ráw¡%È*ä4ïŠ‡Áè½ÇzB†Nk½Q‹İƒ‡`8šMÑaºL4ƒXK ­Ùâ"¶ù¿V8ÿg“_ƒ)ËZâ*C55ı32+ÀZ¼Báşë-šı÷lÊ®’¨fnï3·«éT5Œ”óƒ®'+	+7—ëÌ ­‰‹jŠm:‹Ó(Cæ”ôœãá9+¢k|K³CH7°LkÚ[CáCUŠ1·n^_[[{üÇGhŞ,6öòd%,œ¥”ñrñH–&m¿rïµÖ[õ‡®-“±§Gu~ÖÇ8u%¸äêñ=Ox`C{mdrıVR {}01ç’Õ%U&On:mL¦Zóê³©t_,.R\æZ›©¶›êê>‹ÎO–NĞª1TbNæ>rõ“…ñ
ëÊÖrúyó.÷¶~\ñZæÊÏ%	sı(5Öİyµ³w‡[~ÍŠÜ§Ç0-.Äçø"Wƒ6:»?·!9v¡¦ë
‹ô#ß.tJMìœWŞ`ØZ8R¾Ô`İYºôcöVoh$«Ÿ%‡KèÕÕ!}Ë»ÍŒBj±Ì:ç"gKú Î2'£Ğ#ë±Wt« \ğîË‰+4@‹¢—¢ª&¡âÊ‰´Äş˜†+ë½Ÿ!¬9{ø5j¾%rÁ4Û™«µ¯¼Ç¿Ç¾Şø‚ŞÓ#÷¦µŸÉFHy§I—·ºvjÌ¹v±K¯`ÌtíÂ¢Qv“+ÈïœKjX¯f+*%ªìULY¹+îÒÌÙKœä®tJ°U|½ƒyÒ#I‰Y¥>‡çwEjL5af%«}ÿ4$£ÒÃ‚Åáò%gµè”Ê“Ó–5¯ù•8jœ¸eë°ÅI¨Ò¢_ª ‹&R«,Çj"Ş„¤Ö	iô
ßNKK†;–’7,Û|‰‘Ñ³¡‡«ğĞíumâ*µ±¹+ÏÁïçÅYJ~7M,kãõˆ¦A6•Cvù÷4X’Ñ’˜q`1ÉÌÑÒ—×‚*Òé:ÖKiıÖ–Ş9ipÉÁVÎ©´çO=ƒtFÚÒÁÎr—[ï£ù¾Tõ‡Øek2º®ïHÃËÄšÁ¿´³¢"zÃÌŠ¤æøšÁ,ŠüIÒCd\µúY[I_2K‰	L—_Õ,Œ‘	‰¼³yôİn)»Õı;ƒñq¢‰7ÒGV;,ìàÜr2GÀ sCt4$Su´Œ$~­O£‚b>ºø4¤°Úİg¹ Ê8<è÷–Ùa	œtE© º½‰ï{}l¯OJñi‡8;§^„¡¾l¦4ÌYÌª¥ÿoéÊŠùqìÑM†‡!÷¹ÅP%R±UpBPÃ„)X/¡	 @Ñ#¬°ŠdŒ¢§!LQÙ…?’2NÈAxÑX˜Nè
y%Uz•ä"äEd,¯˜İxqÈ&È¾Sƒ<XAb™#œS:—S-«B¼´˜
±¥Å6ózµ®6é:“½™Ø‡°(x²÷Ì¿zbBÉz+Ù°ÎÌk‘å2Ó{œöB—’f÷Š=äùø×f;
È#ªA8Î`V…¡DD„xxÿjÆŠqJ)Îİ(.¬V˜Õèú,Œ1…|¹Ğ‡²²?2Sô·”IòfŸR…%İCd5%øé°şşßùÂŸÔ‡Ÿác/u„½Ö{ûÀÀÜÄ‡)	¬<¬{ïWXæxò&=nÎ”n¹U ğ[o†ï1™’´«–fhNÚÎÓÊ -WkËz¦-WlÌº<UªÚç…dhPT”l­zµeÅŠ0.YÌû@7Od%æ‘\q
29§B´7åT}ì¶œ(a'/qÒÚVñÌ~‘¨uË
Y¾p§•båS!ü¬ùÕÓ.î¬u½8ÁÚóé@“Øİdrg”
0Ê±æ,™VV*OvÇÀÿ•/¤ß/8ı~”V9½QnàyìŠ­ŞÖöËÎñë#‹W‚G×²Àftƒq?„³8P‰s‚Æm\:[Ï“ğxè_p¯=ABşÈ^‡gå®~–HÕd>f(Tq|(«TİÒÚ˜¹eÀRqê`Â¹¨æØ(Ê%4]o¯:ó©€cĞáWò…0ø×?‡¼ƒÁÉ=Z_Yú=pr–
Û™¶¢¼¼ôm0‚YV©€îóåù¨›åŸr5¸V0}{±÷¬`kášW¡Ø…›ÔMà‚m¶Œ*Wæ’e[Ä§”™±zãXåb3Ãß†İCaqGlò¦>lz‰hÙ@$F¾Õ>ò-öcCp_t×Q\®ˆ=Å‘È¸‚ØÌWgzéç.UBÈõWj¡èä]Ë^ßëzXÄñ‡ğ
uv±êê^
œ¥/E¾2Vuau‰?.¨¹ZS¥»IÓ£‡:WÚ¾.Ğ¦7µĞ“/ +Ğh/f°ó£±Ø@sâ3’yPb—°”´cØwîB5®–¡UÂ¾”˜MÉÓó0Búÿ†Jƒ¨ØeÉRŞƒ’©ÆsıZ+åËMóÆÇ#=Úö¿¬;H'»óåö¶¼"$”)ğlàØx€JFgí±
ô`x*Î)ìh€LS%ÃôÛ÷!uÍ*Ç¨"r:‡Úv†ØÊôh˜„BJY²;U²‘£ì[‘u×ËíeŠ_éÌ?ãD:²Ìm¶áËÍÅ’1[nÙÿ_óq³µóÿ·vÿıÎÿßõıÿ•‡RÑ‰®û‰û4|r_ ÉƒÅ×oÇåUò"…Ñ‘±§À–»buùÄÛÜ\k—eBg·s¸ızŸ'­BÚZšÖ=~¼Å÷-L^WŸ…ïo-Í./U5–´“²­;ÿ~üZXO¿óëHÑLøì¤›F2rÎ'„éCÔdB™r\?¯FàÅKÉtD³	ñ%=©lsDqò]& €¸Ö…]Y±É2¼}ASVóŞ²ûP?çyş3e·İG!ÑnÛÈ3«vvşmíÃØ=ßÙŞ;ÚæÎ‘Ü¯ÀRÔÑùİv‹(¾Ñì”øóÖ«ŞVç¨ÓÛÚ9ìŠß¤uƒjŞH|È]2j‰®ce`]Zæ™DááïÉ5—õ'ÉIòÆ!ÿa®Ôšt^¿Á¬ü°9	\„s~ô£!ë_²-oø#¶?DÚHşêQFgÅq$¶¶Ÿïtöz/÷aØö¶ÚîÙ=9Êda
Œr#[P{ã«Şj_-¾¦€¶ÆW_ ~è\û
µê ãE){0ÛÏ“p
“ûÓğı¨D5ÔğŞÚîşx´°âtz]U4œ¸¤8ñ“ú`æÕg§ã¤ŞÒ¬šë“µfë‰cq ¢ƒÛĞ=*¤Vî[f4—O*ÛuçKtıl¡Á|¨ó©é°S{ ¥æXÕ›õ¦FZü¥­ïê [Oø‡"_+N©ƒ…ÒdéÛƒg²úX1…õfŠÊ³ y?ë?Œ§>0^Í"Ú¶rr±Şãhœ(èÈ“İºîÆ6sän›6°f>©ªÜ5.Z¢(#aÁq¤‹³	~À(TÖ›ıÃ»D­•[pR§³)wå…Š÷4\¨ñÔø%WÛÍÅîÊôew{ï¸·s´½kä·Sé{Fè
Ch ê‚D¸f÷e ğŒŒõjëõuœ "—šwâ³4é4Jæ¬ y>UVÿ˜3³D¡5Pî¯±³ÔÍÛny^Ñ/¤°öÁ¬s<¨œÂ®,m°ÔCU‹£ ?ãX×1I•Ó2Î˜ˆÁdÍ†; o"U4ŞÛ®tCÜâ—¹Kú”JÔWëùäÜ¢/&õÓÈ÷§^ˆzŸdğ¸FâÅšà•Cùâ:YÂ$Š˜fÆ¾v…ìgÃâö)õ_œ—«!±Óì=¡«n]-×Y±THC Íú“:rgÊ¾aó¢–`¸rŒ].¿Drù&££c`{`İQŠs;_<örñĞ‘[†C™Ö4ÌomÜÂmAØi_A{,ÑòË5µµ¶:¦ÃaM(šoñ.·ä^xü3 ÉéT|â_zª>š“—§`ìE—5.‡«q¿“¶=Š¹|S;úñ¦š,^Ó\üÃµü-Û‹NÚ…B¹pÙNo¿«6Fj
hÏ½›G&Ğ€Êáö«íŸÙOÃ$]ÇysØ3öQ¿Ç@ø„9•ë¼Ş9:ÚŞ‚sØ«ú™è^ã¤Ñ`_VxÆîQšKëşğıOÍfmè_ §Ò?KÎB©7à§Á§şìTû8ğ‚(lÉ7X#ga3Mı”Ä‰|ö’s-åìı &kÂ½ál4KÖÒ'úî:©;Ê¶;ö'3º{Eßñ¬/ÎrŒbò!~}TÂ¹mß¸±Şly‘²{ãÜ¯7ìëşo‡çŒ•Ş»W›wf¢)&B¥N›ñŠÄ…¯LRL7Ä‘?ï‘¥ı<_Ğg“pRÃÎ»X•èn Pì·oß©#jşÂÉ~-¡ÎO6ñ™DûŠ Øn¡Ò0ÆîA¿rT¨Bl|9I¼Oüä]oè2š8#$Ùoéyÿ­G^Dâw©N;É¶¶¿¼§™$^AZø8p*uCüÓf½i¥?Ä¨=äW8à2û›¬$ß%Şj=ÔZa…¹*g¥Ç2BêñÛ_çW§E<+ªï(dfq¢ní¨Ú4dî=r9€bT´€|ruz^0Bñ(Æª„•»2¿57«ÑĞı:®l¨QÂçq¹Šj9Ä,†UDŒ§,aòP\…œ4*Ì^Y7 *ÇçÆ½ù­ÇU4gvÑÕ>æh¹DŸYÜkâ>_*9)˜Ù–[xÚºcšw]&ã.¦«ñûıî‘–›‡]L“÷wŸof×jì§#Vf®%ÆÄµW³ÕzóQ½)+CÉ’èØ~É¾ì…	Ö¡ªÄ®ÿö7öüRYºàô6BÎ~ôÈ38~Çğ»@ÛT˜İøÄ]B3e_n,¢M_š¸¿“Øşí¯lçsA1o„Z“—zqZ„(ÅÆJõåN»²gÄN8y»ì¢ğ	«jwÀÃ†Üxğ¼Œ¹‘š¢“]ßà=^‰Àùz,„Jb«õ½~ ‡Î?6¦‘»3zéO…Zxæ.H3©JÒ=>@	û~šyØ½!µ€}½.ò£ŠÙÍy]Ô¦sLË·xf’`<õVñßª5ªı…?)ÿjhæE×†Ç¹’táŞ¼Éà=²İÁ'`¸×ğ`f—ló´a8OÜşyûEqª¦yÚ¶†éB0©Ìš@*ªmWk{ºÂrvÏíÖ“lbŞ†e²@ËÖTmvŞörë1f[¾…ËHÛï_î~ÿÓâ?ÒufÌÍãš?Ä;‰Y®ÿñpum½•ÑÿxøğqóNÿã¯şÇU?jŞhìİdüG¥ÿQÜ£eÆ/¨‡ƒ)0Êd(vÁP…ƒ”—Íş*uó8ÃˆZgqı–E2:d<ÂªËİãçİ_ºGÛ»í¶;‹ûîÖ9::üBç>Ñøüô§í½­ıÃgF'zwõÑ£Gğòêpÿø íNG³3€ìæ2C=ÔÄñŸf¨SÍ°«ÃÆÃ¦d•êô	Û î6f„ã®ÂÄùâèzŒÔÚ
†î¦g‹B©Šÿûğ8Ø±å„eŒFv†Òu3“Îª*ZEW£·iQ£^hÕ¸5gµ!ƒ•ã“¼k8}â\tNVsF7Ğ| òÎ0>VxÆ4ÌOáÌŒ/a!28=Ã@VÂ}eç%p‘’cpõoÀ+ûÇ?Õ^Láù§ÇùzúÓËƒŸÖÄÛÏCùp`çàEòË‘Æ"{lsè¢] Óu[ JÄH0¯áy8ªÇ¡+Í¶àãVö×+ êríåÌøGÈ$pêNbúïÌO–¯\¢qÿe¢d´ÌG	–ÕÎK7ó¼¢GÊÌLB¦|ds¢ âKMÜhqãŒñ±	C†¸“H5R‰HÀu’1«)hV«[N	«Z\•è­’'ìŠâÄÿà¥kTøVéLQş%Båe®Ùx0<Ñ.WX	{It7`SİåqÍøsÿÉéC	·ÂHMf¥æ¨<.?Àìá_ÛË–3‘&|Ç©µØÙ™ õJ`'û™ÿ|äMÎã,×(*p/Áôhë“r½Û®ö®ºâZ;Mc«¬‘jÄ¸L]ÓfN%\ñLsÙ³gŒâŞ£_eè¨% s`ØFGoÙáX¾&Äìx—‚!2nb³´MÖ¼™
ÉIü6æ	KDŠ@çÁ¾0c²HŸĞÈßÅ3¶uJÅ´Sû)à‹èÔ,
ÃDšf½Wög@Q>(×¹³xæ¡lŒÁL.ÂA8–Jêv¯ğbtı·âäí’ø¾M^ÜIÂ¥Ièô ]ùèÀU¡“b`£¤ã¿ R\‰G¾?eù€¿Ù+¶+8H±•ÏE,¾šCõyU.êıİè£º#Ô?]Ñ€¸‘h@¾ì¤AËüÈã#jÓ}Œab¦ûnW]¼ICfÚò´xAŸ[p„³à,&Oåµä}—VSîÔ§´®«®¦]1k-ßfå£mN‹Wa+®[FVÈ‡¡İ=([E‹™·§G0†/W´¨Ì2¡Ø•ˆ`CëÔqázæXpgrn_±ÔRi#K`T:S:ˆ£¦R#åÓn-62:êLOß3Óa3=™pWÿÆ¾I0³—ÚYÿR¼bM[°ª½PbF±j¾S–¼¦m5÷‰2êZºUí…w?Úp
r:­ŒMõwGìÅ=I»d¹|$i>ÖpCŞ¨ŞÃ?+òà±·´ó5«÷¶H%\º!˜„IpzY‹y_qÌ€×ù6Ò'¢«“fjSáÚÕ,Ïæ€ÓÍÃ“IÉ$ä‰édRÍßœƒ'“â	˜¦-8ù ÎıWó1¡öZi©òİ15‚MÍßPçN8Ìó
‡5İ§R2ÒÛÁC~NÂ.
{vá[jÄmµQ¤m¬9w‘3¼ÔW4é—`AE0„Ğ/‘"ºŒŞhâ$6Ãr,Z1wÙ¼`‹ÇÁØo=³ØbaáÒ2H´Ğ¯¦Ã_JİßnñÏl{’D—ï„ïÚ=oì·ÓÁp¹®Êö'Ğ®ZTÄ¯¢ÌÆIu
*Õ+'i®\¤g€Û•™*B­º`À5È¹má¢©Z¸¡¯µö©Ë‡ºœúíN:,¢¯/`"œËÚ†UáÂ)ZoBm›ùZqÊ¡—xuôãæ«ã@hp[æ&§üØ§ÙôÍî‹‘Ç:N1uF‹š•øŸ’Æ§¿ÍÜ¤·LüíooO&(QãÍ22àgóKä[ñcıˆb´s3e}¨tä]ò^şè_!Æm.ß<àı@½Œ|_¼Â–µÉ±³i"éíANı(¹ÜØø¹öãÖvm"§oJ|rHü.¿ÿÓM"œÒıÉÍüv}êqï¥?×Éº©†x¡µµ­ÛÚrâŸ}TYt¹—bË”±c›Pvá œ…"~ıá³•ƒä©5ÃÙg-¢\ŒÂ³€ÁìÇï"ÿ”É›nTÇ©“1İr{C˜×øıÅÔè¥v6†>®şˆ€Z¨‚QšÁ¹lLÖVõ÷ÉxTG:¢Ú–.'NÕà"„ú§ñèJ„FœÖ©vxòPÀÍØ TQ´ôÈ«¬6‡˜6’³Ó¦¨ıÎŞİ¤¸œËÏrß\’ˆ¢àœóTCÍ±ÚÓ„ÎœÌ]Ôn{cæqs[AşHÃla¢ò'#V5ß}û¸°f°ñ9öíÊÌ“o¢Ú™,Àœ¥Ş…'ùÕ¸}ÏUÂïã&ÖÔ¤b­7ã	œ›5SäPzÉJAkOaä>ªV¹}L¼q»ú¹b´åíŸß}aHE7ğûèk^¼É{ººğœÁ&àMFÅŒ#¡›öı³|üW´º0¥ï_F6áÏSxşğ¶²Â*ìµ÷÷ÿ
¹èß Œ"?bi­$WÃûÙl7º±ÖÎ¥iO-1CÁù¦á›
©ıúc6çŒKáhxƒIhüÃÿQ˜•q*Òö£ğZ…‡9=†ùã))¶¯lªÏ‘ÅfB“ û<Ò)Üh‰‚£İÃtƒ¡ÍçéšyâLä9l2U9üZgŒÛ¹#ç¿€îwé¶õK(ÎÀE1©ƒäù~ô›FÍÄ›©cYÄI\×OÚ-qFNÄ=&e„-ƒlõóó¸k¯Êäwd6uØ,û³3ym?ÔzÓETË}û+G
=ğ­po8“–—¯,ÍEİœhœ\Ê0“jÆ.kºËÜé¹Õ¢«šùÀƒ"ˆjùËW2Âì¤z¿˜Éæ&Î:,>`KŒuèÚy™B®š¹Ô¸F$ÅR ºO,“**aøšãdG ×0šA?jñ])–ÊÜÈƒOæ‰<‚÷6s
ÍMJÒ¦s+.o®63Pbë?õÔ¤¤Á•‡Í0v0gÚÕ{‰ŒX­iÏ¿"T¬+2×8Ä{àXşşÿF	Ì'´ş}ïéêê¶•&¥„¨û^fú%ÌBúûÿeŞ¯yc^B¾‡Õ¶\õN–zTñ†Á >xl¦€x!pSc­U©W;á4–K;¹j5)ú–µˆÚÈãÖ(µözÜ6ÌôérÏÚ+ \ÅmÃ²¿´<Ú	°V;…}8ù£ÖZóöV•VQ~Pûàj60˜÷j`ø… —óà`ÀX¸r°PcèöÉV2ÅJ§¬¨­µÚl‚ÆVæä5ºn®ø*JÁ$•^şĞ3Šæ,©n,7NŞbÕ'ïÃå\¦y%±!Ö’J_äÁ‹ˆAÎš¡^!„Ó)×¹Æe`Ò#¥%[6lg¡ú|ŸãÉŒYò77<ˆùËkŒ}iİ\åšç
;Â}µr»¨yuAÒzJæ5E2æ§m<(@VØÿ ´v›ÁxÈF1ş#RÍŠğ… ŸÒø~Âz2<åÏÃàô4}›MÅ36[Ád€@ùQ£dØâRÒ.¡êŞ$æº&üß‘/ŞQ¦3€óh’y­Gñş	mÅÓ9§i–fœh*Ë0äUOÏ9„h ZÆ3œMGhïXŸ&ü‡@¼D^¿w1ˆ=zöe·ßcåß)Â"!À$á}ü‡‘ÛŸû#íQT:>÷­„xDi„¿ŞpHÀÕò¯ «R<} &†dâ,Qütäã?Ê÷q­…OÓ¡?¥¿³ál,h–ğG.ˆO€8ºóîOQÂÂÿH°—Ş »iRàL‰b¤é“ÈšL5ŒJ‘5 ©…èÅù¤=Š")â?úı`8"$bL3¾”1ÇÓ 0›Œë<	14°®¶T¸VZL„|1¼Ñ§Î7‘á‡MFû1N£ÑÌ:”+y­¾Voš¡ƒÑİmQNérÉqRÕ#ÎMÉ½È¦t·¢âkìlY]û‡ŠÎ+¹Ü˜£ós"O''¦¦î…·ó•“#—nŞ”t{×ªO9Õhõƒo¹;J)áµ^À_ºJB9P])ªÈ!!D])’òØ¤äqU0)ÂÜXœyXÊ.¤â¿“Pè4İtÓ‹Õ(Œ”T‘ğKpÁByà"¥FCW?«,X×h¨Õ•­ŒûŸw —»ÍÎåR,‰ñLÖ3ÈÈ’ùLöÆ¬£ù°y€0—ÃÃ¯Y¡&Îey
iÏ—–âÖª<2-¤ásdj°åuõLFœ=ß¢ìá7cMçtÄ˜í™
çæ·tÎÌÈ×ÔX€š_X a,¬¼¬Â”ã[õÚDødqG=ÅHòH#Ï©VWEäGäcÃR\Ü®ïlm½
+
¥†
Ÿ6¹0ó1Ñl~™’“Ãši3HÓdæé*MáM0çõîÍûµY{ÆWvÉç2d¨OşªÏæì,3E+dÖ´ø-]ş†Ï‚”k _qx7€æ`:!tOÿåº|T‹sf)-*Gçà0ÈLçC¦©çg–»ixœß^,™lT#c¢œ_K$Î÷º&,DL fZf&fı®eêÏ&‹	Ş×rçëä@¹8‘ÿu»[vâ¿HHŒ¾{‹lğ]#ßí¨B9¹Ü)GZZ®pË)hì»×ŒÛ"Ğ‰U»^Ûçn©×n÷\®æ›¶™ïÜ^5á‚M±¬A] ha ¯U–Ê	Y°^úÊuZóá
œ»²«s0¦ñ£u”÷†áş#šboÈ—2C[åfdûèhgïU‰Ç°L=Âƒ×1O]ÀÈTš¨RN™Å©m¿ÉÙš:\ñœ‚$ö ¶?IÚö=(—ë±ÕlûÃ“»7NÕ^Nÿ¼Ñ8CAY#ƒf‹nÚ!nòÀéÎÕìa³æ°kØ¼1¬ik˜ÂJKØrCØ›±ƒÍšÁÂûLˆ5¼|i¸ËóŒV¯W’¯^³¬0bu¾‘á®²‡Í ¦Æ®”Õ#Ï×´¥|¬Ê:}Aÿ#'€c˜.§+Å'àl˜¯gÂl±`¾qæÅí—Í˜šğ¬¯Î÷
1«M.Øê†©`fqæt¡&›w…:8‹ºH‰ÃwÕ~”K,¿¶s ›mÿœß#¿¢L‹ÜòºÅ±hj¯äœtEÕªÂ°ƒsç£â[‹@ğ™-tC‚1EX!ZX,ÉÛ<‡ógmˆy ³”
õCÒ™™æÃÁ§]——Q¦ÈÅŠa¬*Æš€™@ïTÿ
;“qıKÃq§gğcGßïtúPgğ·s|´¿Û9ÚyÑyıúÆ5Ê·‰Ó¨¸º3Ôí½ŸÚVŸa‚ÚWLÃsYfƒ.?t]6‹+3óf€„£9|?ìş’–ÛÙF5M]&›êª„• rY«·søªÛ¾W½¿²œIÀQh»0o?ÁD&0Ë%"mÖË©I )’jcPÓz>_.Åßòi€––ù‹qg+û–^×R¦aÈK`ÔÅØ—K˜2â-Dp×DşĞ]‘ïK6Ü`•4våÛæ¦¬ˆ qZ4šÀ´=ù±7™øôP• ˜Ö—?¿û²lUU,Xbk3V™n7Q\	ª6Â$üÈ…ÕÚ›4öñ':¿üôO(Í”Ö­n³¾êÂA ÃïNÎÚîñÑËÚ÷OÏ–1'_€ô¼ôt{rDáÍw„SL€ø©Â—FŞãÆ&'n¥³òëÕÈDöĞ!ã3—ƒ„³‰7ö¨"¥Ê>mXˆ)O¢Ä8åĞ¢GĞÎª‘ú)Dáâ¸Jÿó»Eì¬KmÌ#mkÙÖäÆ25v¤8ÄÓ r§EÕ{Ò¹‹÷ï1lÚÖŒtçøÒ
şÃ€¶¬–Ò½06Nª÷`$~ò£wi…œ¥J³€¡¾äÊš¡\«°\A€rZ.S ÖŠìÔ„ÀúU[`‘À*ÉÆ—øRŠ)kI8×SÙåÂi~‚í$u>»—‹ÃßJÕ¸Q¼j>k“9yX.f^§Ì¨BeŸ”fT„Ñ<0Á6	ìÂÙÎoEÆ÷«PN“ô[a¾õ;ÀüÚ7Á<r©w>>ËıÃAÜø¦u —ÏÇøÿ¤_Æÿg³¹şø_ØÃ;ÿŸ·5şcoR¿áøû]]_{ü83ş­ÖÃÇwş_oãwÿş¿MúñtSÿWwõu¯¹Â?2t¨Ê:³3Ö|ÂòeòÿP›ÂÓ"Y¦şû÷çşı½Îî6<=>s„‰ÍÓiä«ñ3c0ùÇ~3X…‚Ñ  ğçVÒİÙÛ?èîtçWd†!(LÄÊß>†8œœ=ã‘Q6Äë»4eÿ SºiRim×.ÇÒ’*ê„Ö-YDÈĞ³i<z†­7zì’šK8;TÑÎw+3\[Ûİ‡;„sÄÄÏ˜‚KÒ1^úId(µ0
Î}Ö98z€“Ä›%!úÎ…yxÀ2^|)êˆŠ„‚ÙS3sª¶ÆÄÁSEhØ%›Jö†»y“}à“bW<rŒ½àP„fXKb’,^Cvğõ</TÈ=øL9 ÌLY$¼J!@c^ä#Ğı!æ)`™š2à‹=xN!$Ûæy~ÈEÉy©&‡“CSFÊÑ#åŒ-R[)˜ùd‰ÆÙ,x+fİ»¿üå­ òÎèZìs«3­c
É2'Mâ1]´(¿RÉ™¦È/™Ï"ÂK)!µÄz©-ëEHd)ıx~üªİœ¿ã˜¯qÙEQ0E^3ÑhF8rŞä’Q`_Óğ4‹ş{”{ú1ù#„³IÂ<ôåy6CiÎJÁ”ërav
E¼Z’…=)/]Ø¶`¶Bf1Iw¸SuMUºgJñ— á‘ÖéØ2r!T8 “—Òa¸»±Øqñ‘¬}¿•ŠYCw3çîü§øÿow¼Æùïq«uwş»åñ×WúmÿÚêZ33şë­Çwç¿Ûÿ)EK#ã åÔ¾7OTO˜«]æbà–ğc¡N[ò°ç:õî÷n¹”Ì°ˆ<†9fkúÀ‹eV'§Ï9+srzø^;ƒïX‚9¹ÃS>“5`‘0O¦Û_aQÅ¢«VÔNø™ÿÂ¹cã{Ê£Ÿ5îÇøNaş¨+€;íLäÜäùÇ<ş Œ¯8ü`C~¾ØÒ’qšùH™ö*ŞñIpp¬xn`iÎéC++Ë¨ªÌCËfæ-:MheøxÈ…R%‡²èšÆ™a…fÌågeşe“$Kí‘]#Ö?F_|Gşš¾J»&™PËb½6ûÎ§5_rŠ‡FˆoØ†æ¿©õPïT°a]ë’™6ÚbÍi¶VrËØ1ä«³ÅœıåLñ˜¯6â‡,|oHza¯ùç÷a2ö‚QhÄŠsÇÿ¯âÿC˜4Qmày.&'¤7x0GşßZ}œåÿ¶ÖVïø¿[‰ÿÆö"34ôìĞÿ™ùHcVqH.²ô´=Ã@Å±oJT¡ã¶5ö}N{NÃÑ(üˆA$"€hO €…#†NMÛî¯KOGÁ³}ŒÂÍó©AÆİ<ß£m]ú?d+)N¸kÏ§{ù§iQØúŞÏúH½œÊI"GGıFJ[¥ßj?jôGaÎ> 3jnw¶v·aÚ»Ï¤˜ƒRR§ïlè2â4 â’Å³)é>ëOĞÑ!¼KF©Œ‚D¸Ë¢fëä†*¨0ãfw„Ël‹‡|îáå:ß#¶40ÇçÔŸü°õãÖÑ#oï‹VÃ Óæˆ·ë÷N£pÌ¤¯Í'5ø—	ÛĞdêü—uÉ=í¢°ÑVCBüíoì·¿`cœ'¢½È¢F>²¨'}H¨ïqß'_¡2ÅÅ¾É}èê;:mˆ„÷ Rb<šKAl`éd96Dzqğ#Ö.o‰X€JëâOàe‚7ô¦šÜ\k›<èÈ‚jĞáW…øÓå%15Nñª¯š¦Z5/UĞÜtBÖú—È¡FC2LÂğ-GŠš©ßé3UBJ±…¹y…|İñÿ\ûäÃ!*ö{œx7­	0gÿ_[[}˜•ÿ¬¡üïnÿ¿ıßØÒù<`D€œ£÷õŒ4obšzæõÃYÂ&şGvê{Éˆ'‘ØşìŒQĞëºã\PdVVcûƒ$ìcŠËŠ•œµ¤roûMW»ØXz:I
µ3ÃÙ 7
jSû7Û`Oıñ3ı¤ÕƒsÕlZß?m@ŠNé0*… j$éš„“©¿“ëubdbƒ2ÎèxÍOÜÚQÄ'ZYĞU‘É™"“ÔùtşÎ³¬ëOa#è£­/w~ŞŞ*@C6QhJªÇ‡¯õÚ–²ÕufgÈ5ÿxl£u@©¯ê¨Âø\_7pjP¤uk=±e"×Äì(G ‰â˜ë¹~	g8&‰aÂCrÌˆ‡ ;°]yk›–!/°ú©™rãˆ%"hSR!ùâ3&ã·EŸ+| ’Œ_ašôCc
2±:R¦JØ{yÀÔ ¶ja¢ã;?¢MmD¯=  æµbEo¨ñ¬LØ&¾æÈ))@ş±jÒ4·s¸{ñ¸!Æûjå 6K9}âµ›d~/^ï°]?Ñ“Iv©#Ş3úˆ1HÚ9P‚ÃC_zÖ1fôÕ§b›ğ¬´mœ)÷!9B=’‰?À~ ×<ıùÎ6Va„v½KÖ\ÕfÂÂSá˜ÄoÔh@xâa©gæ£úª{¶ ½i>É"·3Kğ¬8õáÃÄì5ğ|bÊ­‘ZÜt…,RÇALg„Ô$(OiïØ¸¯àÿ¾Ùµß¢÷ëkëYş¯õXÂ;şï6ø¿ÔTòV"ÒW`µ“<gˆW§şĞğüŠÛ;’W¸ÄCv¯3{øÅVœÊàbƒu?jŠÂ8éFNå'.Ú`Äe:•-ŒjÄ±Ñ|Ø òXÙòãAuÔÆp®>Û]Fì-°â|NªñÙ8©3â‚9~‰&ìt‰‹t±ŒÍ]o“°ä÷
«ò•¬6]ŒG ¤î¾:”¡Û¹&ó6g³¿Ø?ÜÆX+âûqw»wğ#$ªº¶÷¶{Gû½íŸwÒÏhÛ{Şé~ßvq^)˜ƒw!³SyåCëõ¨mÆQä´ÒI°¼ÙjT³}Ñ¼®Ù›Å ~2E³æ¨®%|6ŞÿÕ “÷¿0m¢¸j¶4Üá±»X&#ò(x8yïÓĞ88GüÌìBC8›Á'Œ¶‚¬1Ú†3ÍéW2æÎæÒÜu¼½¡oÉbQ–Ma×ıâ½?8G‚U
‡JÓKc~„q(Ã1œ™vâ.|'›N4s"ogQ8›JÛ&*&9´lP2búN³b¢àã¹i§|Sİ/GŞ7Š‡#áAa¤­^ìò›"úùË`2lW[ğŸXÅµáÊ¶¸U™Åµ·ÈŞ UM3ıFk®úÿ4
lã«Hw´I8ÄÆ˜…h20P·¯®5—²x§~­‰ÔVŠsæ'Ïa9½ØİÒ|ğ|™`Ú¹eXUÏ¬&¼TbmxGm¬9h×=q¾â@–N:Â”X˜Ïµ,Êê}µ¨ô5_ıSa­èZÀg?	¯ŞÏƒ„êœûŸüó'lk§{ğºóK»*ØÏüZsç¾¥Ïìúí“.ÅÊfU>…£EÌ0È:±Àş§ !?œÜÕÄğ¹UH÷ÄÈ7gú=¦ŠYŠk„¦dÁ"u–Ò™ §AºL2Õ°É»Í­rÕ°ÒGÑXŒ±§Zêà5k'Æu~ˆäÍíÓYJW¢˜°®˜ĞfšÖ:W.f3‡‰o—^Ó<)qH¯‚²³¤“@è 5ºCCQÕ–İ±ù%ü„!½ox şÿq!ÿßlµÖ³òßÕÇkwüÿ?%ÿ¿¨S•¬O,ÎØØ»dü†¸öYÂ•±|Œxû€õáUøUë8RÌ$~“Œåúès9Nêæ± ÏßóH$Hª-’åh6q*z±Ã³Z—ÆØ¤cô›ÀĞMêËMÎEÜğG§JÇHH6Ü?PNÉÅ°;ú§*b¨,VÂÆí*œôü s5¨ïüã=G”šz! ÷$øêiÅ08ƒÁŒ80Sg'5†Å0İWqjNFMŠö;ª|›ôÿw×ÄH˜îëÉ§äĞÿ’û¿ÕV+kÿ»öøaóşßÆï{ThÍëöl8KMRËàô3:¡ÚØÎÒQÈtôˆ±•×,ÀcfLd© × …üovevkî»…y÷»ûİıî~w¿»ßİïîw÷»ûİıî~w¿»ßİïîw÷»ûİıî~_ùûÿÖ›‹ h 