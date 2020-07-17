#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3084583045"
MD5="5551516dd0aedfc4f9fb8984bd3e571e"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20652"
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
	echo Uncompressed size: 156 KB
	echo Compression: xz
	echo Date of packaging: Thu Jul 16 23:55:16 -03 2020
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
	echo OLDUSIZE=156
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
	MS_Printf "About to extract 156 KB in $tmpdir ... Proceed ? [Y/n] "
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
    if test "$leftspace" -lt 156; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (156 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿPj] ¼}•ÀJFœÄÿ.»á_jçÊjÇ'{¾Ye}]3ÅóĞp¥¸I6ix¸lróŞ¦¥âF]§\˜&+Õš…ÁXòéñs‚{¯ ï	ï>È€GZˆÄÁ~iÛçë)OÖL1ã”Ö*_67“8Õ¨Æò9›øğ´u¤úÅ,ÿüs¡‚NØ¨â¼Çğ(e±çÚôï`C@ò£r_ã%“˜©¯OFípµÉ ø-·®©0dùÃ©@ôp½>”L%ÉÄ'±[u–êubæ¯2Ò¹®^²5‘”‚¶:¨Êvæ¥Ç…ò­,sû/;î\°„{|°thÑmƒ»U·àT³lFáiÄÚjIºRÙÕâ‘Üö`Ÿñ&÷J}Ë-dø\ø{¡‡ú?’¼EZkˆºÊÃ´©pê‹ü+„Ä˜İ+â~¿q7ƒsëÜH·b ¿ASxÆŞgµlÄÔsàX©QÈÏzõ£œ! íÉmzxèÑêÆÔ blê·I>õ®Òôpu§<V7™–Y)õë‰iGß[(—>9ü[ñ–:Rîæ*^áÁ|Ôşc381Îq”ğ[rçLÏ’¨,)·-ÍF ü™!MO˜»şôº³Œ¨Á“[}f‘v“·èoI5¬rÂ[Ô\yÄ†ûÚ~èw`ËAµ+l´³:öK¬’RÛ„ıªGˆW€”ßÛrG¨É®ÌÆ‡iŒÔ‚âİÍñ¿İšt=¸Í[«[@oZ*&_ ùLTSBY¶d¾@+rmS.¶spó¯‘is^Ô–ø/É6Ã¨©ÓÌÙ]øjxSÂmø¹ôAFH¬ï˜?õOú9ÖÕ£ºÆ7k†D&œPÅ}]%ÒˆÊR‡ÜĞ@<&5Ë¯Á1©O“‘åÚOR"B‰[vƒ9cğı'F›iãU&)·2ŸÉ°|oeÏ”1íBz´šsÕë€î9nÙÃ¸ cP‘KÛÉ@mùÀE5êB3!wü©ÿ…‚õ`ÇjŞDê¼ß1ÇE×1o¿†©[ÿWOS9kA7uÚ§,°6â#op¦3\“÷Ù1¼i„M³YñL°¤kç‘-›‚n½Q]îAòéZ…A
„~Œ€DPÏ3S&$A&êØõ-í¿6Ä‘¸ËÿÎÑâ8¡÷p¡y[,¶¹ë¦í€ªNß€VÕ‚uÚ,LĞ÷¿ŸÔÅò}=Û8Ğ€*Ô«¡ƒ'Zeÿı  Ce>¡åÇÉ…"Æ¯PıfÒÂÒÚ‹¥şXäÑ9$øËİú¨3Å šãTEè
ú}Õs(Áç2Íû{pmâ·M.$}Ü…j‘t<?£|¬ZÏLóp6	UC( RQv˜j“İõeÉ°Â6‡jŠz‚¡‰´ºã.D³«OŞè{ßÌòG½‘ü©ãòX……ƒÄ=‚ÜDlÖªR’İ
h]ºpy¿ş¥~)ºõ·ôô–Z¼»¦böï×'{ı´ÿæ¯¼¬›ì=õÑ¶uÎ“ãú\À©­ÒÍÕdQ%l­Şÿ²÷3«æ%`§ùÈh×ÉÙf¾î¥7©‹¬A ×~1n^–ÀÊs9Jb˜*bÀMŒ8•–3¸ƒÀ¾ñäƒ¥Ú9^Ï'ûú¸IVl‹{}OßäHÕŠ¼áò°n#¢şÓ §Wv‰%¢±q iĞÿƒ¨sÕLÍ÷iôş¾š5ûksºä¶ÿİ›ÅˆYÛ‡éüwèãã•§]Œïgà¥L> @Ğ¥
ÉW¡-tUš ÎP\ğ‘«k÷g_¸hk1JR®ï~Æ´ßæHSgn ”°a<6£ªhÔ?¦¹Q¢Xš°¾V$N7ºi˜.ÂøÑ8^EH&z4f<("Ûˆ”ÈØY8èsÂˆVö|ƒİ "Â<û‡PÖ¢ÀoJâ›(ºMIH'¦â%`¹­.Ó}£åÃ¤`JŸr+è] Ìí2[ä0>Nâî
´RÙk©Zcö{¾Òö/¡‹ ‚vH	+MqÚ"
(;p£Ñ¢b’Œô5Š{BTUûò7Wpå¤Ùæ½¨Î/”·Åb^—W‚yŠ½ïdØw²¯:Mpzj!×·h÷¯u¸ƒå’²m(œ†ûê|‰‰'™)'¤pÃ¬5ÅèÑÊ3À\’Ïô‚†Ç:u~õP-BÇ¸Êõ€Ç¼–p‰ÁÚ6Û°;Òh4¯³ÊÕ¥>CWğĞÏ‚¹™A&¯¼¥gœB@|u¹›¦0ş¥6§2·ÃöeXI4&ÑU”•¬â¾$ÁÈ¸6Ğ·ã/'°3Ø‘4t,#èÏ‰œ…mQÓ¡=~yO‚ü¢8–	± ¸QQÀt#°Õ&ÅM^(™!ø>j±3Wx¼}ìŒdTÎ(!\à’Ìd›İf$w»ÎÉø#-Bò©`™±j È'ÿIÏf–2|KáyLpS‘åı²t{UxSöËh”=Hw__¶@´f!D «oÍnp5ez‰·±åŞ•[­ü›+g„µÂÂ‘ZışÆ±á·¸\\û‹ÎZ(ß5P)$.³víÖ(à&Á4¿Ö‚ˆ–»'vÊ~=¿¾’,(°–äBl¢F¯ûo€C3×ßk÷ê<‰Bi?ó;ªYÛ‰À²c-÷„‘6?+ı•MƒÅQÄ.XA‚í±ö[ğv<ñ¦À lu„æHıl„‹ÁËíxxs?ÒÌ4¹Nšô&¦Ù% .ëeòÔ‹J«)xèg3Òƒdr	ˆ›{ÌIƒ%˜zÎ€âb…XRúÔ·’#x\$®Ğ±™zØï@|­r•ÓŞÅÙ©ÊæÉ¤¥Ëp"}]¿¢MÆŠeÀã›¢´”)
‡íÌP›«ËÃ%V;êãÉInZj÷Æ¯ü)÷ÚÀ9~\GO`ŞäHÔ,[Œ(aoAàX=çPwDB@!”²ÍÊ¥%ÉY’>÷±MåË"-ş¾SŒØó^‹5æ?1K÷¬‹î¶ÛkãúlÑJÄTv›¾/åhÁuåM¥Œ9)%a£XÎú¸7mÌ˜	sUt©q²'¹Nò±ÒûÁ³ÒùP™|Hï¬¥ì Ÿ™ü‘yƒªËt¹',¿Ãjö}Ò=¤š/f¦23c±ÍÎó˜tz~B´ÊfEú”Æı&yzé¤š,s{º\¥ŒüQHüI“bÿuÔ|Í¨ßĞkÓ‘ÙfY+	A•<õˆCĞË³44~Ía6•î¦TØ5ä×ÈrÚvœ°j.ä×+;–ğ4!VÀ|bZ5È‘œ[<l÷Ön3r2øe<òê¨r0
È}’ü¦v<°YcK2*1õ¬/®Fœ"æ¸ğÈ¢N»Hy“ì¹ó)emÆìşåŠš€«of‡½g£IEÈV•½Ñ®jQc·ò¯C„Âü‹q€VôA}é=ŠMÑÌµ ötã]»!5€=1\®¢€N	İÔapÜğU†;:Å'×ìbÊ@Ì\áäË~­M:Ş¿®LdEbêÒ3DZ¥Ş«Ù	Á8èó@ò
M Wï«h[òùìé{7·eüß\CM¾¢ÿ•””¿R”U‡gBçªb…_Ó[ÏÄE$ö/İÿUô¾ár}K´ ¹Š¤O-ö^¿p«” ¨.…ø¶cÿ:öÿ  NıåØ-%û;ªÀyq+ 1ª¬ş­Mş”×3`u°äj´õ¡x—œpG‡B”E“Ø2×Û3ıcÜÓâ¼;jSàŸ=»-]|pªe\â5T#¥†˜3^5šÇ“TÖà† @ar`€‡˜İd†kşé=ÍR„?•j¹Z«¥‡1šÆ~3ı°z7—zsS;Ü—%ÜšúåAİëÜÌ	…q{oÇ«iK™DJ8iéFZ9ì¸,ñ•H„ƒÕDŠóœ_$Ş‘`5R‘tµ„#èÓåUª}ÅÙ–.ŒAw§unÖl·²şô™d®qô/XçÕ¶ŞÙ´Në:0A‚¸0‚{&„,ôÎİ)}—<s½GÛŒáÒ`Æ/ÊÖüpÖZË` O;ëü¢ t¥à.ÄHë	
<)—Î’N¨‘AbM59EACú6gæÔäzÏÊ£	Æg(<©q­$ws²m`wê?‘ü ivhÛmê's­ŞÈí8OÄ
Ş§¨cu—[‰$‚7Æ@ãÇ€â…7Ió;‰'.ø‰<ßÃL!ëãÛ×Ù«¥ lõ_yš ùf7¹\©†§¥2×8ÕAã°¾W÷k‘¯å+¹t=Ê´ü»tec '”_éÀY¬¶í&æ^ÏrÌ$	8\8`İtn*P•uQÉLÜaÊf¥“qÆÁT½"|‰óo@éõåâ¬ÿÜn‰7¢ÊX÷{Qh%tÆWí¸bÉ"Áİš2êş²ls8?Á³ Àn3ï)éü¥\íS¦'±áİˆ!–4)™aVÎb¸’ñ òzŞÔC×îJ§­½+ÃÅ¼„&âõá.÷•Ä¯QõÓEiÏcôÔtáéÀ¿o—EƒĞ#Ãšºì>.„I4ğ	Y(w’_LĞw1ñ×&y‡íŒß‰´Â‹şkàHãE<Ÿ.œÈS×±Ñ~pºïl €e÷ğ	o‘P’ }t0	t©×ŒÜ½+Lùjám1¢7ç	Bò'…êx³o¸F9{{%°­‹lä0hØ=y¯f¯UºÔ›»ÒZSŞú*¹éî­ÊyãòÍiòÇhbÃÓ«)C:Z¢|îSı]ÅµãwC"İ~ÆYƒ)|ZS<vÿê!m5ÓbpÎE~*µ±Â­!Ó¤>¤7uØÆFí³üÑd<ñj…BV._}¹it©Î‰4•ÔãQ›†msöR-°Tô!£eíSON0	Ó$.s±¡n°şy="µéˆÃòe§Ô[öf~a±iJÍhëgXYàõò–2ß8†cqÇXiüˆåi/7ÂKrÿéŒ¡ıåø¤şM¾\WùRÙ¬éM60_UÕ†¾íFÎŒAQıvF‰I§Yâo±«hk	q)C®ÍJ´gü#òá˜çLr@|Ô$£ ?ÓéRkl­rÕ@Ê\¨“å$oÔ"*jYT_”7{·Õjy­6ğÇ¹¹®­…»¯nÏÖ•z§†åÿ¨¶dhhŒb¦Úi b÷„6íı…ö¼Úl `Ãš3¿·º`øÂu¼˜ÔG÷*ÄÍ½DGy-İ¿³y‰íLŒ–áÓSæÛ±hWòÏç„Sxı+dMƒ–Äµ¸Ò@‹8vÙ8›ÓY6_«ˆÂ{2Øoô¶wPYãvY4è„ZºcÁ²‚‘Ì°Rşàø¹a/‰NaS« ~XÛš/†˜`HA¤tğ/'ãı˜Øøÿhüš:¿Gã¤Ê
º7–SÏàífˆnóv_ª¥ÅJSqÿÓö:”,²»ïfáêQxí!‚ èvvüŒ¬Ê9Ñ¯_|UØú¡Må¸£Öh‰zPuoæËûi±”­:icÚ<¬¤‹7+cÆ¤käøÃ8°˜ÿmëhÂå}†´÷\×T3è¨Y†#ÊòÛ¨NM™¾‡Ø…~¢*JÇ¾æƒoFg–"÷"ùâaŠôxÒ	®à@ÖëPu/hgD=;C<ıö;©3¢ bP‚t ÕÈŠc	ÏÎ4:5t×À•Écå´;73³é¡W¯UÛÚ~ÿèH	ÆûEÇ¸Z7…'Y„›9ÄP—‹j½ßÓ3â!wC»—Sht­Â§l|Š»7dpnÙ_ª=â5®ğF#œjÛŒQ±î†íHb‘¼|İ˜£ì»àèï\ıîëßY²O5[£şÁ^§a“c»$¡ÑÔ€Ù8°ÓL~¿f2Úrş¬ªŸçyôLçÜ˜oL6(rËuqšVaTW›@1ËyçWÉÜ¥4Á¸Yå½ĞHõ“ïæuŸ­¬òD¢=2)é³#jÎšÏœAÛS
@6ÑÓ1ƒİÔ%–Ê£0Ä„¸9j,ëâƒAÈe6ÏŸn{‹D=(‚cßp^í?Ûj¼J>ü+ÁÈaFßBÓqû‘ïz½nş©¡ı<Èî{u3
\zfm¬/^cœn%ªAÖrğíX<
šş%eÂ>vhK5ã ö/ôÿºˆ¥.ÁŠ§´‹NÔ8ñYFÒÌšñoÜ+°ö õ+‘Ràòuà…’dgXh¤%¯¹yz¨[i€k}åÙª÷²ÙrW{½ˆi„à;PÇ¤#,<tjgŸÂEÎÙ4’d¬hAI¸:¬°*aÅ±İ¥¿¶•¬±Öhz¹ÊHú¾ıSÃø˜™%ì¦öÚv´÷#
áXcQæÜÄyX„ë –Èšmï9Óú¬G/¬ãÊÁ}ÕHKêyWbù­Òd.¢b%™¥µL?”>nÏÖú1’í)¥–u¤ÏÖc{Šƒîk2µ‚..]ô@ĞxÍ9£K¡€‹ç›Ôi9ˆZùnè÷ÁD§Ğ%‹jp&IùuŞµNX	Zf mÌ
ùËW3¿è™>xe}µ»J8jÅ»‚'tm¬jŸnu
ÜNßn;¥;³J²ÿ—ÀÃc1@é],°”5r'{Ş‡$áY÷Î_A­0hLŒØ5ûÊŸÔ½ê2E*¾l†˜ƒ>D¶½¬“MòÔ™LİY\)Ó6­(;‰@R8 °4ë×ÜúÛ<RYo…š‹ké²¯<Åi×¾+²á_ïO¾Åíöå–ÁyŸís'tTâ`·÷8'JbkÛFş(zêÌ"L"x×mªíH­c“tŸé(H£RÿæëÆœ±©å
¯éÜ§«Ir'ÙÖŠE<\5ğçÒw¢u³xSşğ°oTFÉâì¼œ%ÈC5PºG; °ü½Á÷Ÿ…ÆÙ'­¹¼†:#VZ3ôítvHßŞÀ¢Ïƒ4XŠAáq?ƒã‹®,³…ÈëµZ¤”R¦Ì›!‘+™rÂšÁ§+¾Y(¤›hŒU*ñ!j°ô,éÅ.ÚÆzô/b-øµ.VŸİüeØ~§×ëJUiˆEö|ÑiÙ½–ÜïnüUâ=AğÉÚ»ä„¶EV-IbßiÈ2¹¦å4+sg8$ÜD°oè£·{Ÿ<ĞÙR‚Şç_äQ4Î†¡øÈÈË¦„3–AjÓ)ÏÈ`±µ]—èÒ~¤ÈÇ­Ë6Ôq§zDY7—{w‰ÿA–q yn‡Ì2/'‚–dµş*”“V#m»ÊÉ¼Ö©—M“§gC&n:t0½Ë×0Ü‘•ú‚€§v ºğê¡H†¬®é.ÌZ˜Š¿NãìßK9q®Æa`æiÅĞó]€m9pmªÔ3üš+ò‹‡›KG®
òbSksÙÔx¯²åÄÕ|Øİ).X¶ƒI†ñªçpg.DªE¶µJ[¾fëlT¶ó½ô8š:°jÒGî¬?Ş
¾Óò‹ÛÅ,7ØÉAqa©tøåÆQ•Å¢ä¶ìU>¾sZkêĞÅc¡ğee~bã—c¶Tº»‡ÕR)‰òâúã³†ÄŒ•:f€œS®Ğ©PcíŸOşXûµ5­EµØHÆÃaYIBNàd³#PFÓb)Å‚p!Ö€ÄzĞj|òı	™ub´LŞ¦šã‰ëe5¸Y°OmJ÷ÍKI1­“­·LÍ`ÇtÆ¹BI/\Qñ½É•€•®Xç_ÄÔ˜ÜÇÑ%±ÍZœNLásxÃÔ-g—ÖdE™-Œ]±NÃ—½OÔ¶8rñ‡÷ ¡c8_jµ…5€‰œWó­ëU^köŸäNJ[xé”ô@õSŸb…ğLš.*“á¦ó›sÜq!p1r?½½æª UvÓjrİ˜åíD6ÒD›#íğ|Í-ÏÇÃ+Ä |©@æDaò±c&K°eŸò=[#Ò7œßÑµ¤÷1û&8¶çœ—¯Ûp×”n XXG¬Å) Bğ«“.fLdH­è_aÏéJ*§*1l U¯-ñ0:W,ˆOÓÖjÁ­1\éé€ÓŠ›UòË†·l5<çİë®Ho|‚eöáz¨¯t°ôˆx”Ÿ=–•ÖèÑ×ÚeZ:¹/‘zÄ€!.ÌE5¥~#ıJ˜¢j7ªÑ5DÏ=•ß´{† )ğÕuMë}rÿğ¾,U½&<l¹e€÷{ĞÕ÷lÅØôD®†Ş-À´]|¼6Ï,ÉØÇ0†hÁ#;µ: _¢ÑR…änyM9³ÈfZ>ÜPôMH`Uhg‘‡¤y€üÑ+{ä•ƒ=-Ô{õ P¶1òÙ.["JÛtU¨Ë’,ló|ûmàÁöQFó½Ô–ÚhDßG:¸±!o¡…N"KAV<TUù›Q(‡ÅŸ!49V“ˆÂ±ÎËT"Dñ ÆÅòÿ†a›º¨mğÖ‹2²Y'ìN,ÈW–ÀÜÈá…2HÉ+`G&ÛÑ(´Â|â¥…›Ê¬/e¼Ïtx
×úµ •ÙçÉ,ë_Z²KGt [æíÀÎanzâI¶‰şÇ@ÇÓÒ©aœ‹bªZ6@~!CP:ó*Ìæ 
­üåĞ7“ÁxÎDÅ“ƒ‘9$©ÂÚ+ê³<¡±éWó{Ö_Ûäàİ’ñFAâÌ.f
…ñÆR!»Âaªì)½}òÖÉNó9İUdk÷¦›°ºšÍqö„u`…œïÛ·N¶˜åz  o-l?¤VÎ€ÕTÂMóJUø²™ı1MÓômAôXè9µ}S)¨#­.•ƒUïEpÒ–Vº|ß"ÎŒÚM´‚O ëa…8®ä¬Ú!¿Â¡ær;[¼„€¦ 3R3«şÉ%Ğ®ûšÒL 	Ì”5Ü´d’ş!ƒ{áòÖ„³Vg%…Š†Mó %PÎ“nà†ƒÃÉŒL½£•üÉGU)êŠ{ĞĞóÈ‹}Ö8ÇlW›Áæ„}˜<O‰ÈZà¶ƒ2Q³—ÂòÎlêÙÃÈŞ\o•Zy>ùô:·¹;@"Ş0,9œAú‰S|)Q9u-~„i¡	7Ò¤mı[éŠ%vJE‡E#GiYwo÷)vw(mS"äÅä	lTEW¢©½ *ëë¶VQ„F&‡"2"İìÚ?†’	+½pîÀÏÖƒ¹Eª¼f‡:ê´™~õÌS¤€séìaM•g•İ¢7¶Ûe[ØÍ2;;·	-¡üòJ’Q?ænâvĞ"eÓAÅZğS­¿¿ÖA?ŒI!bu°–¼|9ÖşOuŞ&Ô£üñÿ5³tÆf–¸½et)G— „ˆ0á ú@µ}A‰¬à¦ÏÓ3x ´…æ6d\‹5ÄÄ€öñÁÿŞà„õ}aĞCøf0Sˆ÷sşƒªe[Y5ÿS¶óÌÎ!@O—xĞ-lvò’²>ø%TBû%_÷Sšmæö
WÍ5DÇâ¤ÀŸXU¿§hP!èĞÿMA€ÂYQN¡­´It/e†¶3J¡ÿ|7œƒ§À@}€ÈWtwÖ½¹g«†æg,¯3°,«ºnáï ª"“5“÷_²«šßõ7\\?ƒ˜úSm>¨‡ğÍë%vL&±
€m›ªÔü*)rGy+„ª*éåÀ´ªØ$O–ûAµ×÷’e 5'| Kæ4Ä‘tıdsÙ!¤ÚãDú2y‡O‡$È³ÃV@vø)Ò­GˆÓ8˜ŞO˜òz ’eânxØL4À”yó¡ñÜa\Ÿo‹ÿÖzmŒ·buá9S_ú¾ÕæˆÉ`™x¸d?c–Ó˜¬·iô…&B>>îÿ¸cE,¦æBN¾·Pé‰ù·–d¦ìOıÖâNñê¡>Æ9lä&(?¹»¤f[ XÑm‰Æ]I­‰ƒé;ê1	İöîb7]í6„aË;ÇĞ[Ì#¾5M4ÚjŞr>ˆ¬OÇlÆ‹Ğ*—î"x‰à†&M‘o-ù•&Ø›Y€YEîÖ ÿÈ§),8Y‰¼Ó(rò¹~»Àë”måQƒïãmW@m	Ø-Õh®yx¥ŒWmúT`'P½İÙ'qº7©ŒÑ!|ó<ëÜNğ±ĞP‘n’7,Šzñ›xzÙ³áÌaÅ–‘]á.…G5D‰ÚxS*ù‚«Î(İóy¢B—ì!e×O#tÓ‰ÜÁ¶ƒÉÛ“øŸ5êô|áàQÍ Z·ÒÜC¸…†#îû÷º&)ñB¢9Œ3¯m“†¦¸f^p9ÚgöùWåÁQ~fô´ŒöŞƒü¹ã =QO½÷ÔêÌÅ¹Ãbë'ã×MáÜÿ´riï˜Oò/Â¼ÜAçÕ@_Ê„¯³ß¢1‹b34áºÀK'Ê·e¡¾»x%×{¡ågÁ±éüq(F2ìÔ¿êO|ıŠŞ<MŞRñ`l©¸\ædÉMäÈñÚN%0×•æ¨×Ë÷³òÀô^_<}“Õ±¹B rz–(qQŸ?ˆÈß
)ô)Âxd4€ü’FËê7yçx4Ö…z´i$Åøº½˜„hÊÂX/N“hjs!ñ'#\µ£UZxÜ?q,©8F˜ñQwÂ
xP!€¹¦5lulÊ-±øsÏìxk?¨Êé«cÚ»Ë (&JDÊ3 ÁË6r¬{gMHu¾`ì)F)—ÕÊ«ƒ:¬ÛMS÷Kñ“†;ó(¾û¥‘Bùm&ø“m
4÷A)³óüE7*íj»´Ll×±Œ8:¹ßÍƒb{äêÅYYûGi€ğcj€ºÓÇ·(øÑ³}æåí(ã{w=QZb[˜%d¡›„m¿d’võ¦Fm÷¶z²o­xÕŠ~&C±|ù‹T'Bğ;{ªr&Ã6ÂéK²¤«mtæ6Ç°‹¥ô>„Qæ“ÛYŠu–­Wvº¿+K%ÇC7 Û¾Wæ§ÊqÕË?¥$˜9 ÷8#™i*G–ëi	üA¹¶d–”Fğû‹RLsÉí{kW:›?Ôkt¤*±İç/éÏ %¼<FPW8Şcì^ ²‡Ñ˜dºsıç»¦öŠ4Úùwƒt‘—’m¨ªšjÙ»³Ñcˆ'jå2w¿zgK-·¥A•ƒ¶˜ÉeŒ¢q;?Ã6QÑ•=Ae“’¤²æ 1Qpœ,Ê|É,Êó}k¼ÕfÛ¥;üâû¨BŒG\šx¨{ô5¦ ]¿l\“‘í*ìJ}ôK·½øŞ.ØGÂ0„b\F&²ìÀ_–‰¼áR”0¶vQõTæ¢JÀİA×ôäò©İÿÕ™ø¸À™+\Ö®ÂÕRò/a§«¾1îQA/,ìa3¾ÅÑóhµu1Mëé)OÊ‰µTú¼a• E¢ağª0µf†Œb·É ­Í-Íö¼°é´¹N4±3Šª¹5ˆ×H¬ÔÜk iñLà+¾jı)ñÊ¦ÕÃ *„OÛÎéCÇÕ‰ÉB Nè>I½~kŒ	Ğ’Üe¯Ól– ê AŞ–Ô@>nš¸—çEí6íƒL¾ä‚”ÙÚ lscÖc +®:YÓ@SÍÜâ=;/<µ†Ä¡ÃqGRÇ]‘F)7Ò›^÷íÏd?dˆ8×7ëzb‹»	­Â˜Ê¨L sëhmdÑ‡/ ˜Œh ñtqø×¾®õÖäG0c/L#Z-ƒ¤­±Z‰’¼Ë™KÀÔÏôË­®ìé­+H®(ëdéoy±šÌƒãÅRÖ«Kp
è”A dp™õ««än6¢^°cÂ	y¬7š\3
Å¬}mCšÔAã6ËR³äš°èÎ˜å ‰/éä¥lòS¡tyëX·OI4Yâ+k§èBà]4äø˜Óµ1ì®:“'5G¹CØ”|`€]!fçS%q#ÒïxíV\-÷5’'0Ë|£‘íõİ=(:pP
<¦uøcq€üÜ·™€%ÓĞ8]¯Ñ|¨~6›¦®¨E­<oíÔ.‹ËDµ|˜…+ó.¹gâ¾,V¹±µï4nÄ½XlMçdŠä†j|£…2< çA/è®¥ğ#Ü•ÿöT/š×GïyÂvã*İ‰4pÎ²ùélt­)B–mfœ˜şÜ-¸?/ŠAš&­t³swóY- önçkÕPÈ¶ıi_ ]×LLªÕ²ëÏ=h™ğåÚ®5âTõaK¾÷5(”5Å»ëe{“ãì²±ƒ[6İKušØt,¦«/üİ²wx¥®§4¹÷ÓîöĞq™)#–ŞF¾_œI×if½RË®şn-——ŸïGFœpÀ¬xÖø[fÆkø¡3ÉEµ%[Ä z²Jµ*C/‘Qûi&O½Ï$¯Öl#:Ñqjæ/!°%Vô'+	"ƒ¢WA4è<²º§_¿®	íiC·`òæ,©¯4µj½¶iÅ™%ïYÇ[ó£Áã	#‘§´Hé@;r¦Bp=‘|ÉI‚Úhà<àYÑA©Ko³¬ÈóL®ëo;@‡¯ĞY:ŸìuVşÚÔû€³ºê2	Àd¢2!@bqÆRŸAÇ„3ÈATÎ´ræ‡|Ïnø0,´4­YĞ[$Âa*!Ñ…eç~AyùÇ¯áq"±˜eóÜqâq0ÊG«°0UìˆQÃÌnt¯nİÉ9w’Z¿XFIÂ«dRFt­YP5)?	¯d…<ä¸%m[ıéd4w)_ï‚ïXl‚ÿ»ètÈÓÕ.WÌe‘.âìSÊ™UQìÛğX%%PŞïTx«í”“JäH'(á=bÌJÄ»ï);›ÅÅÎ;
#i>Ö‚4š•Ê†Ù¹^}kªàoU5šB%‹ïğËº­¦Joãù­9º ¨Œ^Ä4ÉLŒ2ÙáYç~åEÜO{ËæĞ¼vîààQé$Î¥¦«nKWõ+Ä ú=†Ê®™¨‚WZÁ¯!C7£jİÓg(û°ûd®aîĞÎ•Cß¼®…ù#êñEÙàk$á…´ZWÆ&?§hÉct¨ÿrdfx¸×ª`0¯J”÷pf´jRÌÖFv:?ê 6D¸ºÜsw¥Y*¾üRâPY+rÿjíB¤ËBªF³­"MÓØS¶î<şĞÁ4Şip‡Y`@Î+}Š—ş!&§İŠóı_
¨è adİ÷¦èÄ;ˆÔ•²œkr/±hÚœéü<I6¶áÅ3AÂ+uÚÃ1Å€/°oå›?Ü©p¼ßqƒÆºDÜUÅW<(á'TÒz¢èÀ¶9<°Î@ìŠw—Èëî¶i ¼EãÎ‹Ü·çç6‹ZÍïYôœÅZ^ˆ†gæÊ®:ÑÜ›ß¤T¶Ì¤™*9{¥èâï2QÅíR5[²TÍ˜#RİXúzŠğ,Wÿe7ŠĞí oš/yFÌl‡âˆ·¦¶ölšIšôËŒ‰‚±ó+İ•šğíè’fËäì8ô(GMõ¯©÷ƒ2EÛeK»`ÛÜbí…¨ñ_Õ×:ZfÌtÑ5Iƒ€ç¹ë‘Ó:ƒ<Á 2{ê¸.ÔÚf¶­†ù6éÜ¹»±é¶m6®TN‹Ò] ŠØïÚˆŒL˜éaF._zX¦†ğò ÂcYšOÆQt-”F:zb«û*õúìN#İâ˜õU‡â~#ú6Ğg…OJFö’'/¢@4{íøù¿=l+CbÎš»<^	ÿkÆ_ù#ÉT´ïÏ \ÀQO£ç§°ºÊQt¯.Èhb+&knŸ¨hF0mbßÁW¿rhÆG'ö²İ÷÷,I†£f_'Ùh‡çYI·C›FL¾kû úèMx„}PóÄTrÌ¨X¿¸·Ù?ûÅ8Y’ú^XYÑç¹¬Æ¢ È®¿à¯C’­ j¨Ş5\•HÄTNø+b TuÑmcºİ:MÀd}Ãÿé£È¸ÒH»˜‘ÿ3âÓaÓí™ˆä>x–œPİÑl:> &‡ÕóZL‘¹W€îoU‚O+¢¬— 	ïM0¡ˆ /Ó„­ö®C¼ÎV`N–Ã8dtB½Â9‰”3¯p^ÎzĞäVyŒ]wq¼b×Psºòªcõ°W¬ºh›o;NüóõUjb
—ù.æBçı”2læví¬“ï:;Òu‡>ÙI!Â6îMtˆÍâlÔ%H j¢:W"hÛÙªapà”~U„fÁÔ#‹æQ–FÃ‚4{Rå¤ÿ ò»Ìt“B
û˜÷‘…j²RNq ­öI™QÍıĞ•%f0fn¼pI×‰9[Ë–°¥q±¹…ó¢dÎ\=7|GJgJón·½Ô(—ì {P¥w¨´Î¾¹;º<Øê…8âd)uà¼yøù¾íü¡ÒÈ@
€Ìhç¡c¬:B¯ú„¹¬‘º|Q•Aúkƒ	Êò#v“œ¨:€Šşv4!»¾ÏÔ/u^íÜOQ»”šcÖÃÌ%:´Ûm³x7“À2hÔõ;şç"ìw¢–ËõPTS¶›'WkIŠ¬&X×‘G‘vaR¢/ÙT}<O±Ğå]¦>õâA˜ä'Ğh2Õ'°µ¶%a}²ÛAÎ<›z_
Ï˜ñÁÉ1…2éóR–¨ï3VŞ»³4Ê6Uk¢ë¥%’Mñtº®ê2W3UºoR>.cÆ”,uöL¨U/‰›9³À?­'&ªÌr•¬¶Ùwµoû¡¸¸h5x?Sí;Cg‰Şeá°a},ƒÆå²Ü_k¾±ô‰XışÂ•sØ:	Â!Vhgğè¤ÄWø%Ÿ]3H\,7t3åcDÂ LU…_=İ«5£)b€,
rù´¬PßŞíX{Ğ0òù'´NHº§îÒA6~.åw_–ác#ìwBDû+ãd2ïäİr¾º‚—­²öŠÃ†æËìÚ¸ÊãCº¢Â·Q˜¡zeEÌ¾öç$7/çbúĞ¹ÖùáO"QÁ0M¤•î,)=5ı„A¦?¤&[íß[FÙìÖ¦šãHåH<”pÅ	µ4ÿlíïsdxñÜ’v¥bn+Õ's®$F˜Õ©Ûßww7Rõ)Š°3VDWœÚ˜È¨LA\ëz¦ŠIUK(
b‘0,ik

W!M1èßômŠ¤|¨‰ÿ§ñJÅ¢uó†ÌKì_†	ûú-æêò\Ÿ˜pbÓz8R›o‚ÓÈÜs«ÙûõÒ>%w“ŞÚ‡Ì³Ï(	ÇÑ™‹˜{Û&Xi™'ui¹‘ eš|{{
y•'3êÆ«Ø{PÄ²£%Éı’¬¾°dÂ’£®zô¦ç&a+m
x¨h½0pğ>‰¢[P…øG&¶cj0JBVù£$»ÊÏh“‘†%şÑ3üp*l—Çš‹­ˆ7° n)ÿ™J¬¡3°E©’&ÍÒ\†Fû¬G¸‡Ç–ƒPsgm§õË(d×š+–Á7\¨A¸c)WÈÙ½^…F5ZzÎğ$faØÀ³¿˜lYUR2ï8ÌX40á-åÇê‘ˆÉ»;´T!ª´¯>O‡Ô®«<Ğ†'mÎ^…ÔÓ_¥Y«à©Í³ƒ)EÑcÍg»z
	6›˜A
N°pm~X»—‰_eö”zŒéAÌÓÔğuû¦SA¤„Ş‡9H Hÿ#(f‰«¼ ,Y°¸ÿ¢qˆX],™/Íû²1ÄájºÆañpšÄÎƒŠTÂj¬º«§È"Í>ä[7›zp‘'ıq••.)FH’7ø|
¾¨àU•Ğê­U±ª…©*±ìèıì"‡ÌÉÁĞâI”Ë±¶<¤şf…"Ûœu_r­– V#K°Bæ\º\bæñEÛ"Òˆ’¯ü´4w½ <–²ÀŞ¨ 2º¢Ë4ñX6f®±{·2F
èÌb—è
ÎÍù	½VKĞûK€`@Ï´7S»`èõçˆtŒ÷>óç5÷•'£­ æĞÓç¢‹@a­ÖòÔËÀvã},W
Ef"˜õOÕµ>}¢Gn˜ÏTCRÆ]ß#åP!l>1„ö¦êpV÷£)3¶¹2h2Pë³d[-‰t„U4gÏ€^‡T\EXgÕÛFI¤s-cÿ3¡×ße3-È£¼íj6$åæ ~¼âÒ4şVµ½T²+Y™‹ 3ÜÜå«Ó‘MCÎ¡>F«×˜Ùµsg+œpĞĞy%üuËÎ›~úí‘×Ûƒc™÷üShœCš¿¼ßÖ`áÀUç'ØqÕ74Y,'IºqD{µâ
¥­c¬åg/?âI¯ô?)©çºß¿o•¾†k¶+İ)Ğcz6=¡T¤S{^³Œ.¡‹@UÕ¶0åP¤¯Øys0p(1Ï®3£­/ âµšC­3ªpÕşğm{ ™yX˜wlzÉ®maîq)Üƒw=é/Òz2–f•cÌßúÎ`à×/òÊ¿`f@Œhïy?¨Ğ;tÌƒísÌûhİÉÊùåª'«ÁÊô¨B°,”¢mGâ[½Í‚bòÏÕÖ;M°W"Ê„ ãh‰Â›·Í¼8‹¤/5¼c­.ãsé67í÷A$zò¶Ÿ-¢-bØàNƒÏ»fPn±)´:‹r8²ddµ¬¬oİs­Oã0ÁUPGœ@*õ·\Ø$k‡ì{W3¤ÙŒ€ÔòM8ş´Cr M˜oç›åãwæÀÈ­jîôõÂ*àQ8Ö“…O‘ÓjFê@šw:©)W‡ÖB‡kĞ»*Ô,ÖÖNsè:3@„óX-1<sÎ«ùƒ™³¾CÍ²YUgÔ·¹ãô‹¿/M?mø* f‚)4 A hïÇö£2¥›}z+!(<âpV®ºRßË@ˆbÚö¾Ã]ÒÁ3ûVŠÈV¯ä8şTÁFsTGÛüÎ$//1¾ZdĞİ¥2—QÎú+u=‰ÇL…DÖüKà¹q¯®!„£"
‰JS%•q#ÆĞÅ¥]7pŸ1tì-9F>Ä'Å×fÍFŒ4:Ù¹ÀNÏÛÚS‚Ë2áñJ=¡h¨…TÌcŞÿ®ô3ÄáS¨–jğêÑš‰U=8r¢İWWQ4·è34†É“yEÄcxÍªrÉ, SD"ŸŠ»*Ğ0¡uµí®ü®VğpîôÄà^…
m„çéš~?Ú‰g9ªIƒÈ/RúÀÔ²—‰;`íA”“H‘"Ñ`y¬-CK×ñêìÊN¶n¶\)Ş:³|ƒ±yºWá(Î|‡ÌQŠc…%PU§Û$tçï#YS|òT¶O?#ës
ÏZ j{ox¸†;1”æ×Ï´ePæÃÖû†/#*'h"LkÌ(´ÒÂÁÃK^Œ&÷lEÍ€¶jÍ¥?<	íúaˆkt«”•Wó¨ºAÇ8Àm·ĞïjP$hrööİ›
ƒ
½CÎnUüı,¡ò«e*Ä7Åˆr–t¾néª]€‹À#½:Ó9Ş‹f	æ:§-ym~•ÖQzflä¸nc	Q®tb»ÆÏÊ}²¤ØEêC§?2ıÉY!j°~:¨ IäŞÚR+"_Õü±3gÉY+ò
íy¡bà_ˆËò¨CªlÇKİ¬}!¤´Ñ=-O4+0~¦£êV]; Ï€ûœ·ÉVJÿ¦p	¯ú1\^”R×PãÎb}K Ü9"j©»%ıV_şAy•å7İ–_y{¬E—&v¿+[PQÀÕGW€pwĞp°™xbù‘¨üµ?4Ûá@Ûí…<Å< Aúm)À˜Ó"±rñåÈıõ¿ Å€Ö˜*u¥b(:NÿøË“5#Rş|K…´hÛk²TT7È ¾îlĞÊö|ÔHç4Í5í1VJIŒ¾cã„½*×“Oié1‚sw#¯‰üs{TÏövƒÁ¾eÊœå'sûÇ7±õ¬1Hì‘†öo [aÇfE§S¦X?K÷QbˆŒ|¯½îš,«Z<jM Ÿ¨^­öñÓãW~d·tÔWå‚£8ÃiY£wvLV³'>­KÇqu¶Ûà‘–¶ÊJ¬®H Ë•}˜æhÆtµ¼¥ŒÚ³î!8]İ¿±~ XpÒ7ê«ØD&uyxİŸkÄ›Îˆâ4…^“^¯ŸJaÉxµ—ÒŒ2ƒqeÚzşOaUN"› Mğ˜·ôådHôiş~¯_·âRïÁ^ e•0´c+ù+oczİE®7Ñ§Và—èÇa
QóˆÖñÉ²ú_'.bwj§À_l¨¹»œy/ ˆsÃ÷’äÒƒ¼/'RK4¶e½©õÒã~Ÿhöò·©²¢-.ğsŒ²Sİ"a	¢‰`]FKkÂ´ZòòÅ7 ½ÚÏF2ØÈ"²È­©âÇä4™	ËÇ.¤OK:'øáuÙ UFÒZ¤‡Ã\*ß&ƒÏá”jSÍá (¾áö³W|8a~ùTÌóvGğ"Ö›Nà¼÷ô ÿMGôSŞƒ3H'­“ğƒWaÒwBá/¼ix éjìÒDí¾k(µ¼ãÀLfoHW²6©J2ã€¼´K*‹°YjpáV#‰*¨ª$:˜§ÖuAUUXA2C¦;<ßäÀ‰?pò$;°<ÂÂëú²‹óê™Ñ¸¾Íy¯éÀù]õ-%é©âóes‹‚¨x»µ#ÃÇÑï°ïğ\D §ğœvô0şßäGåÛ	] òı1ı\l™é]ËVÉÃ…1—¥,á¼Ş~¡ÈßÇÍãF°‡ï¢¨º27Cz¹¼ÂğŠÉTg”V0qĞ\l	GÈsi*bzÙÏyŞ™P=~Kµ€ªO·Jï÷·
@Øª *xçmª•¶{;ÜèPÕíŠ;½Í[á4[Ksk“2O¢ |XÁoWN©5nÔÆ‰†p‘»¢©ğÂ«®É.çI²¸ì:XÃKÿB+"{%é®ÿMò¾öj†#‚YfwÉdƒ›€ù¼pıŞó ¼:Ø Z/¥·ñÉ÷«ÜÈÁllcÁNSŸV`Ô¢‘Ìesøá-ş÷¶ul‰Ø<	 iêä4·Ü<´úYSùŒ¨øËWbĞœm=‘õx3W)Ã!š@¯c ¶ş»N‡jÃÓ“£<Iô_]#TuSË˜š»Î’•3ÂÆ[/ÄjÒã!A¤”|ü"fĞã™$‰Ú¼ÙfšÆ´>ECé/Ek’¹F›c›?)ŞoVh½é¡“¯_(åÎ<"ÍW§&/M`g)7š°q)
¶—\bYÊ
ÚeYÑ6W`yÆ,ˆ8.+ºL#[ÜÚÿ1nè(ÿÌJÁiH*cm˜ÈuH×Ò¤Äß¡O
]>ûXØíwÈÂI.ÙôúCE˜=qƒ2dLİ5yµpXy¯9úıŠtœ4£¾;B?’XtFsÈ©G1wÁFÕíaİ4Ø•‰jû -E÷ D½æ¹Å8úf¿RÈÒ@ü£WğìúuìÓ`¤ŒßQr˜`f4½²äyoŠŸ9õ$e§üùıOH‡}B!ÛîÄWÒ«¸l6æå…œl§ İ[Eñ @Çı¿î=ÚY?¿>¬HF!aˆXh×ÒBW×¬$l8Æ§¿xy´÷ùº“1·¯İAŞ/øOıÉbpŒœÆsİ™b’>1¥!ãDyÈM‚†ğÎo²ë(7ºÑ?_Ÿé²G¿ßdB’9tè0BÑ„]œ°  ¯³ŞĞ¿^7úÕ/Ìè…Â(İ÷î{VÑÎÕpÒ§î&
/æG,0vgI«¾‹Aïï	T¤ï®gX“ÁIw-2ÚVv&2ñyîkÄÏ «4NÕ·^xÂŒÆxj¤Ÿ¥Æ§Š­­ÆëëB”®àı,ÁÄ² -jzòÛÄmÎ9Î- CÊ‹3û™;*º ÔjÛU~ı	æ¾T
Y¤s!¼¡°'·›ÕñíÍWTÄ¸£LÿO—şW¢æe0ò1ˆ“Ãú9€N	Ö[%¯=oã1Ënp!dø%U’Ì ÛXüÍ5'#Ù‚×r
 ğÍÊmY z“ªhB›³ø²¡}ûÍŒ!‹I5jÏ÷TÙ´â¸­=í¤ò9+-LªÑ¾Ü=±©® '¼èô· X€DQx`*8Ï©aŒ°MÆ.pP³(7ã5ŠÑùìøKæ*ZLÕe 7ì¸S`hdÂŸû®´‘è	ˆM»'Q€ÀúÌní¶êòti@<äº™ãrêòzı¦b‹Ízø­.,
#E0¯¥·ÜåZ­¶²XZn+Tbˆ)Õ[ĞÔGJ*éIñ&ÏÁ0ÂĞm\¿]Ñò×«§}õ§[ÕÛx` ’ùèöCº·ók Ï"xÃ¢’>úpMÿéü?d-¶U½µ¬ŸØí?³<Ã=è$k°ˆ‡ıß¦™kùR€N©]õ¹ÆõûâpÁ™¨Hvœ›éÅÅ·¥¹8Í×î·™¶Â¹š+×ÏÎA±Ìli¹‘œç‚v¿j­€Ãé‚	6»ÄñòóÉ2‰¾v>¯4áËw6›ş´NC%¡ºêÒò,i¿“>—™º²ƒ^Ñ!6mjéHY™4‹‹ÈÊ€âoŒ€ÌVÊ>¡^ÇÈ
ğ.Ñ€È‹ô;$µm G–$Èê©^3õ*õ;®öı![GŒ«	Î²Ù 2Ï4—WáµÙŠN¥Û7,ûs²'®ŠÕ(—s²Gt\úËTíŞuâßÍ‡+ˆ…EUœôào?Gğ¿P÷tGŒcœlc´°-œâ‚Q
^‹~b2H‘ó–(v"œ=ÓMê0lLX§¶·pÄŠŒ€IHî	œ<Ö.H}¦Ä…hYuŞCÎñ{ƒkÚ_A ¶˜–YCMR•…üŞ¨ĞÇæ€ßbì6L¼%Å¯íà5ï+IxOÅeSåĞL3•XB¨}ãFŠ_1’’Ã©ãE<HÏ–µ’G?7×öŠŒÅşI&F›VŸª¯¢Öñ$æìAZ¾*]°à³ğrbà²ªFøĞÇg!èïûj¤C7)QöÆ‹ŞhY‘Ø!ÕMø&Õ‘ÛögÑ+S‰|œ<*zöu«¿S‰?“Ë•¶æbÆX{¬–¤²#,;MM‹£°ÎÅ/?´§	`Iyé.Œ†ùü2×‚rzKƒXÔ„³AM¯GÈcúsüv\3Ï2'6÷ŸJßpò\ŠÕO[RsW ZPtÒ¦|5›œ½î–Û|¶GéNN‰šGÒ.(ÉÍŸ…gXp	ÉÛ-c,^‘ğ«İH'n·Ì:ûñë‘òÿïá^·<­l­\òa!%:À'âøT*æŒŞ%¬%ß¿İ{;+Ö÷¯éñ)›Ze 	îŞ´Ï(òìImm08Õ¶ÄSÙ;)F©#ñExNÄC¤·KÆ-1N³ƒÛa³Ë¦¬H cq£9WÁæ†0+@MÍîeœtàº³(„Ísu>ß×ßSnèä¼ñØò¡é'Óã¶w5s¯@q!	=©ZÕ”Õ«‹q¿è³&µ¿†£;mIØD|c«ç¸y·”WµÅ;3cjáSA;5úi]¬Öıœ‡	É›cä³ÚîØWV¬¯”rƒÏä¤¾’®W&û§´M}ÈÕ-)@ÈO'Bî*¬Æï£Ùvä¤C™M"ÿ±cœ^(ˆsgi(|VwÒá§bÑ«'¼“{”?g…t~ï$VŠ6iû>“ª¸Şõ]Â4ïG$Ñg¦ÊUÊtÛIÀì’š1.´»#ézàêÕy–ê¹ÎpGwÖ¬^v<qÀÒ…•=ÏáºtÁ¡Èl¾+µumå+a“Ï±6Wú+N*Pæe}ˆ¡IÆZÄSKx@ 4´{Ïá‹4^Ù eWb©ÅÇ÷’üÅÜÚî‘”uH©•ëÜšñEğ9+Wm8x›×aÑJŒK`ÌqNĞ.|İÀ~_Æ<CÕqÑS­óßtk;t½ílÚ6/­©XûÉ›%åŒQ&Çûô@¹‡ í5ÎŸmâ ¹jğî:î êaöËE`ëî9¹¢¾÷—I‘2Ê‰éÚ™X!²k+ñ¤ô€1qxçxQbrÛËj™5’(n¢¬ˆÍ#erjÓIÔ©{ÍÊxÆí²³Cá¥»˜Ps]>º L¼™ÆïÏ>Ö0jÃ¦Q?‰Îò•óJ‚$ôäÅ%@BÂ“))DÉšÒ‚ÓÏòCùrõgEÍ–Øs
©$èwœT¾ŸË:£î}gÜˆù×¸Ø &Vïâ”5aÜ”²ì©õ5¼qh¿Cm'G>D¬Cz!*n;~”\ÕÖßû8ÏUxáˆ6‘Â¼$@+Q¦Ò;ó3hRUßy)¤öµiG€*wf:ˆ7w¦¨äŒ…="¼½²Öİ5*YrK@Ÿè¶¬xÌ†ş6ôÎIjÚ7b#>°ÙvvÍåo‚Ñ¼2«b›ÓÖƒÜ¡ÅW´z~0ï‡eâ^W$–†Î‹ì
ôIs0%üùè)ĞµËèpÖcr5¸ÿî^d~«Ó§Œæ²ó;lè#¬œÛ‘WÀ2û¬îÛÊ3×Z8a±› pŸt{*óÌó˜7Cg¿J_t„ ¿íKµŞyÔIcG2Ü	æægbõ‘ÄvÎÁFL,Œ÷™˜ıˆV¤òB!˜›À|ØÊë„¤ø}Œû×Á§®”ù’ÖBqícMºì ›¡¡µ9½'‹ŸW‘¥âRà?¤µÅ;K{Ç»SP|¨µÖ%gŸ®AM“à{Xóá—áó¾ëÔAïDÃŠ8€ÇP9ûºfÇ÷rÖ‡ŒZChó5CŸà©vú†YA†äœ—«¸Úúo¤÷ÎÛıı(¶´.èç¦Pµ¨ÇP²´MØ­TâIy@¬rÀÂCñSUÃ›ÊRO)mxŞ9…nıX°‡˜mÓ˜Aò„/c¼ôxĞ·&é'(ú¹Oğ1Äú··TŸ_S'Õ÷¸D{…Û±iàsÿV¨rÓtæcGµWÑ\AKUßrû)~t‡¡zÄ‹HØ^¸mh·j‚€z‹*^Ù–ï°;ò<8·ŸÄ°$HÔ¼D`£i·ædTˆòœ´™6[,HÀP™O	â¹¢õÁ“•ç²="g M3tÒ$2 ’Ìg›<Çûµ\_ÿÅ²_Ê7Â¸äb}ÀÚĞ„dW¤£ôèƒü”(eœï›Ä=BØíÙ¿t¥Ğ4´ûèA/ÈÀìÆ#Á+HyÒ2ÉË(ÍaE7$ş…A<*ÏÒï&¸˜vü•ıÉvÒ
O:*ş:—·´£ğ È;øG>5¸ƒFÄ`>¤Ó!5@Œ°[sğëMYZsªŠ6M¦Wö`Ï–ÀR;^0ñ§+I'î¿Í[‹5‘ËCGÂfÿØ]hÑ|ËcÓ>¶€É?cPl¨Ù¡ÕNá‰{oÒ‚‘èN	Ê^h¬ânéaõ}ÈI9œåìoëfÜÕ•;îOÑ1´mr~¬½b›‹J£Öut¦t›ùÂÃÊ…‡€˜!ûĞì}*“˜w'„<$â;İi—õºSïJÊ–¨ŠèóÓ;?÷ ZÛgßë’ğ/UiØóÃ4ÍËyS(¿¼o×]&±«¡Ç:€µ%fç**n>A‰¤„Cîƒ`)™\@ŠúI@ S0­TïççìN#D¹«q©]š–¶\ôÛÙË”ğbTî…j:~ı/Š©ğgè¸æ53©[ÓM&ò÷:ÅqCqØ¹|‡a§J³'ˆ=“½“,–Í)X¯=CÛØÒÔÔ½f)¤{âKÃOfÊ+ŒE}9Çi%‹Ã¡i	G‹ è
í£ÚaHd~.Nà.wùëdZh¿PSÌòûïUeã,>¶ÛÍ£LïYÒ1°à¶ÇÉ —¬³7ÙÈî1M9Eê&ÁÆàˆ§‡¬)/'°İ^I67_½:?Ñi1' _6½	¿ŒBS(ÀDü–U=÷£H•JVƒÇlÿÆY‘FDÛmAĞGƒŠXv€â¡Øïji’AXÛØÌ½ò•ˆŒ°Çp)_|èv[Œ®…ÊT‰/§3YÀĞ?[Ó…ÕÆ]p¦´;c¦ûJr)ø7åYéÇì¿Ú»úa)\#ìÛ)HvÂ¨{EPÄs£÷´rBšr„¾/‹[æ)1o¹oVPfAxX
«°)6¥EÌ“ØáD€ãÀæœİvñOöƒ»jµ‘ƒù £¡üHs'V„7c|hÙİ;Ë’}íåÿäQ¸‰È01‰c	I×„<è³l±F†âH2f·ÓÑ® ”qe´ÙÖ«ªî€Õ½‡–°/tš“;6uTìƒÊüŞ„X¸™cŒÏ‹VÊ`q½¶'›èü‹vâæq•ıÀLÙUï>–"d8qf5»~WV0Àóc[icCò¥z¾"`!ş^/®OzNÎÚ­4Ì%‹“à8Zio1öêqù&äuô×
©ÎèíŠ{Ğq›ŞqxÃ°‡ÄÂÅßr¦KÆb«øMƒy#©©~t/ÙÈkş÷[“¼FèXQÕÔê¼Ò¹<\¢1¢pAµ{¬ÁÚv¼…è·ìŸŞ&¡ço™È¹”˜³éÕ‡ÿÄÙù|Ûº».¡ÏÜâœ!5;ğğ‘âo™´½f{Èùco×ÖkvøâÁ,U—yXY=§ØX9±¾„Ë­_Õ¤ o¯8±±†bn	Ë@ÆÏá©xNb'¬€A>}ßÈÂ¾yyCĞ¨›Ï¼ˆâõU¤ohh¶û Øqš'gBğxX‚‚¦sWî£…¢sv÷¦<¥}Vâ ´2Y]¸Â5íÒñÆ
ùÀ·7+ßÔvö…îW$FÛ¦Á&ÂÄ…&®©\B¾íûF—Ôid"¸Ú?– G#Ú¨\Ë\5šN’š—d0w÷M„»`¦’YZïXĞ-Ë¢gÛğLI&³ßøÅùÓ†k$6wıY,×Såi†+Ÿ<kÅÒÔ  ]xnåoâÄR†Šœ˜:3ùØ“gÖ‹šÛKâeêóïóGä¼TéÇäËøï¶'‹9\Åeıá[ı•kS[ZâåÊ+ÔA'F²\EÄı}Éœ'çNzr¹àûÍ…NƒŠÛ”pHË#PPˆWã¤×Á¬RÍ1•©¼e¹4x}‹‹[p”Ò«IVİ¤M|™=šŒô…ßX©ÎşhZàÎóq\íÿÅ–ü4O ğt±OrEñƒñyŠ"¸£ïRÙ¼8Ğ;Nô"³Ø©")µ ²ÓéÀŞÉ¨½ˆó”ØÒ=±FóŞ\l¨‚T9ÛI-ÒÊÑTP–
MnMà¤æÀ–aLZ0ö(û¥¨úşeb’éªñ _>–uÉğ˜GqŠqİ,Ã¥,ÀÉÃmÓL‡°’:T‚ı}kzâ°U&_9g¹ÿF«­:Ö>d-I»Ñ±ÃrŞºƒÆìÏG3	ÔfàîfZ®N ‹»Ö¦Ğ^ØÕ3Øä¬>zc½wê²Å@l¶1V™A›ŠÅDdY@ùşDSŠXn‡š F³N&ûmfMîb„xÈÙ>¡Vs€­àÎï™¡ò7sa0!_"½ƒ0oİ0ÊJ#Ÿã‹8’¾MªˆÉXôfQŠåå¥dYsµ.[''Ş*ã‹ÑÙ'qâI²qw=9²b'‹ ÀC¡ÌÖ´»}ÙÊ˜ï¼Ãùqâu	n¯Œ*’ÿ›Ë ¨ÇÓM°¥Ÿ Ï’¨j¡ìˆ^Ù"Àƒ®Æ"VŸ¬]£È=á‹oÈ˜˜cá^á¾£O w«¥óYWšíÉ@ôŞß"rI+Õ† ]À\e	ÚÓ²áMüg?…†ƒ<ıfÈ=ÒS;×ŸÉ,›hÑ WH)Á˜8Ş`ÙLQ²İ³S$hg¢<…®=N+Â7êxdÀá}JÍÀÒ—‰¨ıf=v+«·1,ÚK$¨µöºš@ºø¨­£]–6aÁd…æ*Ã‡*|ûSPÌNéP	êBUüT+áé5*«>Æ,û5»ÖÎ"m~pècg³kÌ1}¼a|Z)äú~“aºÜu  \»‰™-QÄ‘ş€)MÃ1£©§Ñ#†±ántì=Ÿ3nÿÙIBe#U6´¸;äùÈÖœSõ¨NP=Ô&}Öa(şîİ…ùÓÈT(M·˜D}RüãÉƒİ©©4Æ±©“qEÀ\8ÊñM¦]šØxĞUL‰0‡à	ôLïP:¬ïÚó¢IÛâ~.¡(¶°mìÇ‹Ab•-{ªkù,.|¶æ5#2Ú¸…“;í>W±(Ê­tw¨¢Ï‚;ªa:!LV:^Ù^µäÂ¥jd«ØxîÁ/@À»ø›%t•Û® 7in9O¸ø8pÿCè?6±-E54ÔkaQ…Öæ¨²õ×¥­ÙrY³1‘'¤ù%°¤{ ÕëòyÙŞisQÿ¥~ ±ÒIŸâ*w}âwó!ªôî'Qã
\(ùãŠ•wH«yÌŒÁL$À³±·Šrbï¿;$V§LkMÙÅ63 ŞVÚAíä$+ô>=\W¹SßÒıUBO!li
Eu_ùVÚÚ6Hû3 ŸâR>ñÎBCoéšòà’9‰	s&çış•š^¦yè¸Ó$àŞ<Ó,_7®«/İc´üÈ´ÙÍı•BÚ´D®Å´œiˆªâ?jë®Ášš?„H@D &¢4ÂƒÑ¶hFÎúñİy “šŸ@AŞïœŒ…8ãE,~Ş‘P½›‡Qj?£w©>ğŠgÂ¤3œÊE±œşÁ¦©ú)f,æ¤N–ÕåBzãå¨µ*h5Œ"¢¿²uXuGÿ@ÿ¬EM*C¤²¾.@sT³Ù?øšWØiÌM¹€îå„•º2f‡æoà   ^U…U[ †¡€ ğX±Ägû    YZ