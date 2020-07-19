#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1985568614"
MD5="546e3f581f1b40e45f0f1e1020220b00"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20756"
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
	echo Date of packaging: Sun Jul 19 02:35:41 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿPÓ] ¼}•ÀJFœÄÿ.»á_jçÊ~7ì^}¤T“†UåTLgŠÎÀ˜dïÚ"‘´P)‘µ`)Ğ%IvZèèãJK 3 Á÷f‘+Ğ	İ~§iLİ³PØbŸŒI·mqè°f*×¿Ñãa­ÒüªÚn1ŠGq„ÿéôÅIıbŸ½ƒ‚
ˆ ³[F§8ğJ%m–If¯°=ÿ†ñ§{‚ÍdGúW|$,cúÂ‹I²uzCg;Ì7@ÇÒšÓ	w)óè`ğeÊš¢ü
Ä{%&lˆ^[ÄQàM¢½FˆÒ­e 5fë¼‹ˆÆn|·$¡½zUû-î¯E é2â¾Ş&2şÄd~t/¬gqGÒ¤Œ¹à_”½­I[´<jwìajø˜µ®Ä‚ ë)Y‚òì© Ct§~›dÂeÒˆšW9»¼CWJÊÛñzßíò™ÊPWNIV¹ÖGQ)Ï×Ğ«GNmÜ
©i‚Ó+»ï2——Õ@Ñrî£3äÖmÚ‘~.yJª®Û}#ˆ¸~%7§ì'$3§î¢á„Œ•®‰>éúAYÖè<s˜C/fLÔãF9â	{sâf÷´{İ§\Âç—nÙ‘¤@”‹ Hq¨ĞYƒî„UŠ§³?°¬ûdÊ~aŒ¦Sì“@| àiÿu§Í\k®@"Q< Yo™R#Ÿ¡ÍºãJ¯ÊP<Q3ÄšÂ)ašÈ¤¦zH³>÷&<É[JOfpI¦¬=ºÍ¬Du4R¦‰D¥ö‚§]™ºåÂPtìáY ?ÉæĞ³<+¬ò‹âV!S<­×Ê;ü%;*#` L]›ÂıÄšÅlJ?LØPDÒJ×GÜs€#àĞ
úqâïN'–àƒ1­ö…uÙ`$¶İ[{ÎòpkÌTÍ™Ïƒ¿şÑ:Ø-Qõ
eŠ×ä[r¤Ñ{Ü¹Ò6ß¤p«‡V°ìGf'0=«¸ñ;Ì~ÚzKq¥îc²ªìÑ0%LÃŞĞfÍ•:)ø§Àr…#Ä¥…Á—!Ö—V8K~ã³yRË
åŞÌšU5}Æ­§hw‹ÙSO#¯n _°1%òfï¦ë9³×•ÓD„² D6ô€B_õ¨ØMÓñûäjG,ä² mäıé'ˆìÌ$ìZSrì½#“¶X4Vğ«Ë^ÂÛRšöŸğ½(hôì¼ÕC2îÙÚZ’o¤Ó†¥ohŞ•KøƒL§Üí¥üob¢Çì`[v¢”â{IÙ3ò,ÀT;_W
 ÊT`ì¤+˜,Êùt©›¯Ó©}{â
ì„öFË–Öß¯xy(ÀÎÛê‘ Œ¸¿ï$ù¬²q#ú¦T)‡[rúúø3íÏŒ´ÑªŞÿK“SYRÕ¸°¥$¨—Œ ØAÆ¥À›:6LÂ4 a°æÂÅ
àD‡›whg\ÕüÛxKà.¬Ç1|ww§*,
Á‘B`^SÅŠÃ¶ÆIÔ2¬ì`Á)éª+„÷âŠÙ|á1‡ÿ³n'ï…¾ùL™†sÍ6Ñÿ¥÷™Jaù1¶İñò xkré¯‡uŸßÜóÚB¨ßOë0¬ó«·g¡†t¾¬¢ºöN™¨‡c¥=ëiÆb*a0€ô²=!p‚÷eÊSkFŠnä6ğ.Ìì7M>Hzæès'òQú´ÅG4'n©ù}³Z µQ4éH‚ßYW·µœ²Û¹•ìµÇÕ–wN7ÀóğÇÎéì=klZ(¡z¿œ©eüíÏ±­•EéhAĞ"ÂNYàsHÁ&OÄ[¹v=™8¢	µB­LLú`£9¾p±R¹¾¨z¨RúÀë¹J0LK²‰CnàÒk™G’æ“b¾üZÆIe{í*â&³¹RìJ‰h”šOV7‹!ÂcŠòñ2–Qìâú¨Qı-óƒ­ qV$X4À:­Ã›&ëR©ÅI«)‹• —ï°,V/¶™·¡M7©<ÿ}òof&2˜}<)³2+8'À+y¯Utˆ‹†!høË_TAEn#N¡h4
HóÅSµñuİşæáêëE"Âïø¡²j´vÓïá°H¦}£|¶j¹\¢ (Hg+x±´mÂ>ÚÍW³_dh½ñgoomm$©ıiÁA—qõ¾“š}=¶j¦Û‡ea?¢‚"ß|6ò§âowaØãE`àïÕg¾åşº££³;µ(Õ@„:ÃÄ"LµH P¡pPy–mL“ù3ºÆÍÑş·"X!åæ%noåİäpËi4Å}Êƒl;‡	¿şµ'¬:NØ!ñıéı¸ÛñU‰µ£¾í„£Íú…÷wì^D&›*)&I9xì0:ğMw]ñµ¯NÚÔáånê²PÛÔ[`±s’åS¦¹VËÉnÒbŒ…M2áÚC¹ùÀ"ÿÖ:"®€«1¼™,åŞF_Èì{I*ğ²‰‘#{İßUÖh;ğ0¾R}˜"ãhp bÖ!]çä½ÛP'e;Í;ÄÁjÔ¼³àğüÑ…K7ŞïÆ7æÑ:ò¤Î9_¯ã½á±k¸RëÃÉÉÛëàw¡nÌ?:§¨Ó—¤‡Î‘SÔóĞ8É_?ÚY÷Û¢²ŒKmÄaÀw’Õ&ñî—ªËgx­şG^ö8*¾–Ä·çúTù˜9àvéœÍ«zqGõ8;ágÄ(‚‰sa“,îòF	u¯ôM»Şñx3"Ü-æ9ôg™±îü›É›»õÃC|ùÿûŠ2´ü	‡¶Œ°Sñ¾ñİªiÑRÇ¾÷P-Kxà,ÑWV?Nñ•`÷¢{›+«'ö4\ø ëEìÎ¹ÿò†7qı5(réXHŞ8ô(úY×Óû6k1ÂŞ8$_ÏÄÜã-Å?æ€‹Îyt5!øÜPÂú¸§Œwv•ŞÃú)ğÎıé° é³/,ÍşŒÉÍ]·0EŒ:ÔF:ƒÏ	"é?ù†™0b+ˆEéí±&±5}`0{j¯CP'aÑÑJ{€s±z“ˆ6×É£îø‘½sÏ
Z÷óƒ™Ï0?l”LŒ¼i*O"$ÚgÄjAB¦Ôò¢ÍÎªlAw4uv › '’¢ÁãA‰Ì)®%A¦…Jk1ìuùú£ôğ|ğßa²¦³–Ÿ »·ÉÀyÓ8F…ĞÍïœæ%LÁµxÎê‚ÃñĞ%»;ìWş^^+œ›Ë( ,®Ç(¹—ØXTĞûÖn™#U¥ül4òÆæã<
ß¬ö;YÓ1,ßp™lˆ‰OM=(©²Fr6Ù—ÃïãóqaËˆ§YÄÙqOV¤ız¯‹Sä
ks”ÆaBÁG&è/i¥¤`¨¯–“3¨ÌnaİÌ#ãe£¾»¹gFÃ¹¹®ó©ïòX‚ß}œ0J)ZkëuÓ_!Ê[TıyŠ†'q,KÂ‘QœuíR‡‘ÏIYRmrÍÊ£¬Ş³ñ019t,+{ìƒÿê[ª I•=B3÷£œ÷^Ì®ßº9òôœ^O	½¶öªIù"™²È¡WÔtğV›†­¿ù‚ar+=òØ¼¢7ø¹>?1í"_±­$.i"7Ìİ o]˜<Ú§Ñ;,OzN;÷åÛÆ§CmÆ÷ì›´%~"ôÄ´>ŞƒdµğVĞg”æµ%}IcÌõfw	pj¼j‰pe© ş;DW­…¤Ÿıló.* l›°‚7wÀçRì°|÷«GífY™ËÂîsÜÆ’)[n·œt‡`:ê";ëyìŞQ?ò%ÃL4à	˜­]g„È_ÙwHš›îk]õxmòcl:ÆS¨©¦Fğ0‘go6_6©jZ°ÌŸPV;+ºfÿÜgqOPù¥CÜß_@#w±…{ëZ¹ËP¸[W×|WBbkıñl¤ nİZ»ƒ‚½¾82:mÊ¢€ïˆ
MyøÇë!ô'×çŒ`=MZ¸•~ë½Öâ½Ş?¼—m`%ytÀì£Ú™´†'Ìw%Y¦ìÄÔdf)H­UÎGägÕ8º‘ÛÖ»»óh†½VzF7ÍïCkvO¯›““Œ2¨9ÎºÌÂè\›÷ÇFÄ©÷I$Épä ¸vm±×Aëå°x!Rj^3w?Æ5"¯‚®ÇxşP¼©†g%|D¤]NˆÃ™;À¼w£.4Û +œeı‹ƒ5²şÍqåÈ¸…3Û\ lÉ€ğùóp“ş‹0İÈ}¯Ç«Yd¯2%Á‚+x‡Î£Üƒóxíl#7ª®Ğj|YC_jø_‡}.by¹êuËV®CÇ«˜vÜt]ù©,°ó+˜Lj›üIĞ†G¬îåFW6ÌvfáJË›E„6SÛ–~-G”„¶™â"¬dŠ;ñM}D!îåô±,ÎÿaÜd‹D`ô^+5öB
ÃO`¬ã&(ù5=ó¨o”şà¾<hÅNøå‘±Q3†
dtñq}bŞF¶à‚×ÔEBğãnz{à-(ı¸»§Géñ´çiø¯µ–»[bR-i şaø¶]/&ÿ¾ÍªZ Š„éË`—nUH*F÷í..JİN¸Áöø„’ØV áŞåhMåÇ`ßá*	İ–%à”.V/P½/²4·m5ğz½A/vÙóàwÿËïÜÃı§ ešnà–üÍ©aL®Æ°t*·4às7rîÇşĞ)h’ÁÄ¢|=„¡b’¨˜ÑÚrºôUB—ºáu—O*WÍêZ_ëX¡+-ÿJƒ‘“òV}˜Ïç³ ğú¾‘t\ÎµPwr´wJo(†¤÷Ï}9xj^@|É›©F£€+ùÎ$USxˆzZ6	úÎ/*N%‡L§yŒüÇ€'ô‡nJ‘\Ì…{Ğ.-ğ›nú^ pÉ(¿{"€gù¢·š.e¡«z)(Cl‘¥áê>ß3Ç<8'It^€º]ìÙĞ«ñIEÒHZë²Ë(	j4‘œnƒ}¾L²CèRğw›¥ŸâÌøêçãFübçç„ó+7¦S8âõPÈ¸ÍúÑ´?ğÇ¤HàèéQ|¬$æbäCÚÇ#åxÚ9ÓÜj«?k“ï]*Š;¸‚>õÆ~æ°ÿÚAV_>ÒâÅ”i„Ç‚¾ÈOi~¯+¶î]8[‡-[EH5._v5VšäM
óßü[•åÆæéÀ-:(ßC|û,5ûúÅ†
PåPê,kŠÆïNi¶v=dıYõø³·àÖ+¶B-²Æ.…&6“w­•º¢¢ª—VÚ«FİjRóœCbë£oSf}G¼ôÖÄ‰İ|í`}KôÑ£‘ €ä&¤¡F-ôã¼‡ÿÕÖ}’ópê'±<bëšƒeöÂà[Ô«±ï»¾NÛfnÍDQÜbÜ¶¥üNzsŞ”'•’,b‘<,…_äp;]üíMi_wioûsªÒm›LßÁWİ!K‡&Gˆ±y©ÒMàBR~VŒ—R‹Ãc—>ßãÕd÷S·ö7÷ïÏ<×´@ƒù+†Ö¼1ZwÊ2ƒf¥3ÎUæßÙ¼´Lq¢oY§{½jÔ„2æMH-j½äo}Ã]³ÇaÍËĞËj_‘ñ5,Î¿Úë¹Oºl.x'¡àŠB8­„ˆœ!ìÖq±NéÈ9wáìõIÇşßİ}1{%jøL¼VÇ§œÎ–`Ûxƒ+}KsÄS_]×C–ÂdV¤=
[0?9ˆ^æíbä÷ç7u»hò>j„»XôµÜ†Wcƒûq“AZ¯Z›2Õ9Ìı›?sjiÀÅWïê&>q¥¤néı¡‰³ÿç?i{—ã³{Ğ)y¼J@3“l#Ió“0ß6@h½cÆ€gìº¬ûôE‰_ùMÎe¨Á¸ØäÀG|ÀJÂÒûé˜é'óÚŒ%s¿;G’ŸúB?¤Œf»C9Oªç$>VÃy©ş–ÀìÙR[ÚM÷A`qc· ÆÍ«M¼¿¨ˆ§ùÜ4…òlTd5x·»<oJÖÈúÜˆùØI/±_uá‹»òF—ôF1-}l½Ôã+©iAÏ\9°NĞ›1RwÒ#p~È¢WÁ¸”(”e;á5üOÃ6›õ¶“¹”ÏÑÏ\'î9¨—½¡*\şC›ö¡ú³6wxŒ¥vèT3ô(±hé´şG§®oTØ™\*ıÍ©ñàYøCÇ¯úÂ¼?úLÏÑ¼æ…›û*Übœiï„[ ‘/8&uÂ‡ÈÁÔ¦,4{øb£I©cä ¸8uı=µèéæÂu‘±€¸E†š0uEÅıéß|ôLGùÂŸP
¿ƒ%~Öóïï‡nì‘[4ï”£ôgB]	"=u	¢"•±ˆ%Ë¤)‘ğé˜"Çc%^
Ü)-Ñw®Æ$Bã¥1NZ1è«²rBÍêx4†!ïÔ-óÁçÈIf§Ò‘÷j7òì"ánSK¦yƒØ“EøÂª<à?îğ—Ÿ|ÆÔ Ûê©‰µõ­ˆP Uô™¼ô÷aµ”
Œ©"QòÓZ²+‹¾q¶±¤Ô³Ÿr½è÷$ÙømÏblah8O‹YÜU=¾ÜËEŒAl…ĞäªJ\aî¢®u3•Ü`V8Z¸1ÿB¡nér¡zXuî×-1)O£;¹õ˜3ë+—¡ZAÒ`nÈ`À?ºÊ¶	í·RunŸöhq²åº~A7¼ÓjÿWw§ßaÌ*¹ÖÃë}–K°”ÒÙqÊõ€‰Í`H8lïÊ_á
&èÌ¤³Ôş/
];¢‰mÄr‡@Ò
õ.¢Be+ğ³Şæº€Çvå^äâüª8œùÏw–!FÑ5)fÍ~ú“ü`ó}wÖâ'şë×hdTà´!‰KË…¾ù!Š$´/­î"v`p-]I¨ªc_ú*W>–.Jmàs{Ù$Õo<‹ÁÙq¼õ½æ©È.*Ã¼¸rñ;“CË-Ec|4õ?ˆ»ƒy$O›‰YË:u¹ôm ëáTÚy·;É«³$Ì²Ÿ‰õ2ŸÆÁ[ÕöÇ%É'şã`dÚÌÒåY‘5cC§Q`“Cœü¾Ã"•.@J7Ö¶å¨c¦šÍ>V º
Á3×–Ï€O§>…İÆMÃ–4K‡zmşXïÔëæ+m³@j¦Ş¤æÉûÖ>¦+\EIúÃ*Zº{6MGï,@¦çoYÒ¸ƒ­Œ‚8™
©,	‘qb`A¬Œ¹¼’ØõÆ<Ş’?²>.ÛœÙuZ-\É_’5¯ìÛ*ÊDNì¼ÇHÊàŸ^2;şœÎ›¨‹š$]Ä–51‰»à²†í6[=ìÆ5ùå"Ù·F&ÙèU^f{l\^-B
şÖÇ¼ı†'í@¸§­fÇÑÊ3³‰Å/>Ù`2p£!‘ª+yŒtYš†Ë•b¿Zi¨áˆp‘ï”U0ˆeİÄ¶^2%Ğõë·Ú™…ú§aŒ¿‘Jà²¾îòÕtS_t<Ò‘pˆô°Âà×$[®jÅE•iWĞ?Ê¹w?«@=—»¥!/æ¤"q³NéX-ï[„fUyW ßé¤œ(¨s“HJl8*{ò$w3€oæÃ¬©óß[;›?fÙø ÉÀ/^¥!@¿®ÿ5c…]ãö‚®R´±‘cSi5¼sà+@@ºÚúJûlÙÎåÕq¨
÷Ã—Ù­+ú«rìsãxl'×›8³É¹‡ÄËfÅÒçx2,ÚiÆŠæw§t7ü gZ$PèQ–¸µ1æ°³9,ä¹‚c]%—A+G©ª÷b@¾ş]òş±iŠ÷‡W6^ÍqËªU³<¿}u7’ğ:J‘dÏ^SÀ\Î¨·ãã¥GÃ·}À™ÂE[£¯%ÆÖ,1‚íşã—>Ñû><‰rÖ¤ğZ¦Ï5øƒ˜»I—³jÑv¶X«ùaè;L¸¶Æ“Éš@w9dè,]²ùdÔ©á,Ó?æj~G)ç>×Ó@Ï˜¶J2êJèûJ\;îè½¾o«	ó~È†”b ”´²¨ÄØÛ­`Ôæ–Îçöì]XsCÅ-ºqSNJíÅ,º«À‹b{ànÔ\şGåÏ ¯Bµ“ùÇX Fy8I¹ë6—·-`	ö á1ğ2és;âÖ‚7sVÅ«È!Dåg÷C-$úı6iocxü™®¯ ®%7ørÁ¾jş)D-µÅñ^ËÎÄ€ßØš$™o·tR?¢ù€XÆşŠw€û–1ÉÕç»~‹ùLıY_9KºÄ‰ªìEÔM›…}gé'6a!V•EP—”dó’ÆZ.!Ä˜´„š1÷‹TGI(hv>³|d9Bkx'[-dÉ<ea"îwqğÖ|Íé·í(1q¶eÙ6¤‡œïì?‘NæˆJiîÚùf©¾Àå÷FµÁ‹—$AŞØ 5»YRL*éÚ QJÉVÉp7‚¬êÅIñ*3=%ä`Ú/ĞƒË®l²¨v(ÏÅ`¥õ9ç“¯OÕ@¾ü¡2A6Œ²´¶0ñÔ?ï‚\–Ì_âÊ¦V¿œJ3µMá4
üËd³;BıFE*ì‰3~—ƒ¹³Ú*Ş“ê‘ØÒ‘Š‚ÊÄ10”/	
>\›³36iÛnéoÒQ™ø¿Ö.ù,•áÛU­Ú¶Âß´¥<1Ÿ<?¢ÖûqÉê0ˆin'l’AO U T×$)0€B£‡½ÆzË7‡Ÿ…&ú÷‰€»"®éC¼°¾P¨ŠÕÏ¼	ğgF$<dğ§Ø¡DÏO	Ä ÿ½Ûö…F
<FÍCcÖ‘m]çVxÙ4\¨+é+å…×ÀĞäiWÜ¯å<.÷BÀ\PäG£™¤¤âº€GÕ
¼®P:Ó×ck]`«I’Ê`DoXË¶ëFé®l‘N ¥òÓº7±¶D¿=Dİ“7¼ùBJtn‚ÿ3å0ØY¡îP®€{®
g"¿‚Æ\E{>],ì­¨„e#!Ûîw?c×#újDÈ…ÿ\Ë"÷®OØÈXé&Ïú TÅôÒşPøiÜ5ãéı“Úp…½ıtÈ;r!ÅÎ}ÔÂ ;iÒ>P{i¿h¬½TÈm±ÆHøšÏu 1OJr ¤ÑZ0¢Bÿ3pƒØŠ6l‹“T¢¾cà*Mj3W?¹ˆÙŞ½ö@H›)
z<×Jµ|¿*GhƒW€D¡IrÆÒ÷ìÀ]|ÕjMÜQ-›«t›ŸE¹ø„gøÿoıN?ßƒ2;>s‘Tq…dÖü¥š	ë ©Ğ2xqÔ5U¯V0RğVêTúoèYr;<Ş#@Ê~1Ñ×J9léŒ¢®R¦¶Y>9nÏ.òzfß52ñËPÙ»°n•SÿrLºtş3²yhf’öõzWŠfU æÙ~¿’ÈQ™ò_.ü!Tëùê”Y5HÉÊuMJÒƒë-< â÷LÇİò†kI;»Æº-¼¦ÍÂ–"„È–ËRZQ»A|şø-şÙml»dÒsazB»êóI*È°­,‰jÃµ×“D._w¸rVwù}Ù×:]dÁ³œ™Â+Æ!šï~¸xñFé<Ïq½ëF´ş†@&*èÕ½HDñBñ¥·v•†²ÿ¥Bÿ‚Kx4©ÛB+.ıVÿßJ¢î,nk’]—EuV÷&Ïå¤A¥~]–!t|.jê^ cŸªš±ƒI ô?GzØı-\p83Èkm-©ş0—…5áÛKÀ±§'ídw`‡'çŒ†QÚÈN:0XüdeÙÇ,.•˜B€Aö@¤ DÒU:Jœ ¿h‡NUÉõ2å=‡ÏE J$ĞELÔjÊ˜mÓ9ÉûuQl é¬™N™|Ğƒš¼›Ùc{2 ~©WºY“tb6N‘½Dda¬0@.å¾UlõQô‡ÅÉñMaøŸÄéşÂr
ä
!ŞŒ_Ô#ú?ş–&v]¼”²t¶ê€öî§zcù® 1´Üö¿AÂV®ŞL‡`øñJ«MÎ{í1%¡á‹kqêæøn”zÿóÍ~”+<ñÓ³owTLz@\ëÃúúx£I"?¬T{,­Æü­WO(Æú¥¾üE°²ùDó>,¸[ß­K÷}ÑÔ3ò-Í­‘€ğ˜£Ù¡,™ı›^iü’}l/«á¼ME/Ó^å;JÏÿ€°ó5|²ÚT…*¬Áœhiº9ÓÇÅ_ÿt’PTh/Åq­”Ì—“CUïBô–<< äZçL¬-’+|$:êXf±æĞ²-?ÿ›&bXÚøŞéKÚpô¼i‡¼‚¾/\.Ú³/9C·PÊ¸¡˜Œ›„Äi)ş¬;ïRîxèÙks…ö±9(0‰%İüS¬fÃzƒ÷« ¶=%4äSGUòˆšç‚AEÙiÍGzé^Ù*[MªºT0iAzòŠ—<ßÜÕ'tù¾Ç%×#ÚÔ(÷ìüò÷ğ+{‚nfÚÄD G‘ÂáFPÜâNˆ•×ÉÈ~ÿhó¥ê¦=Ö‹¾¸q4›âù@TD	L¥#gÅïjk…OJde+^… gpñügAı«•<Â1'+Í]iŞkDÈ¢°ûD›”^fº­:L±caäákjƒÕ}eŸÄ/©œ	üÜÁKáİÓ£vıùP¯¯±‚uE
¶šÖ„ÊI{ <He\:7U]ã>¯çúW»ân¡®Ï£EY=< w@’Q9áÒGîï¯JÏš¨›Òz Á¶0ª<ME8«?©Ïnt¿givÒò@Uµ÷¨†bi5)Lè¦¤U»4ÌÚ\ˆ°€Ÿ+DÇ¿ÿÎªG=â*»ù†Ó
0lzÅ²»£ ßf7Ú)Öíq!‚²N>GÙ?ÊeöEFrnŠ‰ÖÂÆÂ¿¡±cÓî`LcîXÚRˆ†/–Ç8£BQë¡ıñ…T!8K°#ëæBëéÜ Ù
Ulâ h@Hq=F¡\¥nzö¸_S`Q—3S{”š-¡Z;ãÙ¬æç• íJÌÆ=SMr2Ö>|9[Fô¾ i{»ÙtR/âË3aşÂ—Ëñdd¾“ŸğÈvHtE¦Ü„ß[["İ;#´2dHÌ[›ù5Ô ³1°òÍ6dLôÄªAİ«†²ÅØà“Sà*&±ö¸4EÅ7k©neZ]¯“>ÙWcÓX!ám\¡Ëæ¿µÖ™‹ o¸®vôù:SûQ›ÏB@<vJ=ì
«ÚUz±VZ~o
0©Ğ›8gH¾bUµ.ÿyÛ_Ríú’8ĞxÚŸ9Ö·µî–jÌÂ³­?¤Ù¥ù<Ò­E€È`¿FPÒŞÎU+²¢òj¡ÏgÎ´à†U¹ZÆL
ñ˜Ú~eó_ ÆƒÙûYz¶„Ğ¼¥ÚíÏ·yWö}Ë ÚùØË»Ë‹PTÍÉ"ns$y,«"Vt.´§B©ú•2>x³Ö´UÑ–.'ÿÑñ¢qoÖPD‡ğ-¨^¶3‰ ¤CKºÂe£t…; ¡³9,éæHÕÔâ£´Ö¬W‚;ø¬£u£R—K1©ŠšïZôwÏ‹B¨œ­†~(~¨™ÙJ­‚îÈBC)‰kÄ=ßÚÖh¬
VØUG>º¡°©_dVÜ©ªS»ó×Iİ-jî÷ÖÔê™„tA|	†ÑAÒyg¼Cd/iû¿ˆ$~	¦‡ÜñbK£ı³(X|±JAû+@\ĞÖÙÀÏ¾âH·Bq€õå™Ò-Ü¥?ÚÚy€ß%ÀĞÇ.9Å™jÓ¸Ü¹?Åß ¦×ÔÁ|È,âb«$	¦e5ˆÓJIşùövÎÄïZİõE!f5zZ¹O¼õ‘ª
tğáP-ã…–ş½—É„sÊ;	ç¸½‹UñDŸmĞš}Ÿ¤×+?#$·Yt šS£ŸTtØ cZ¼ödùÛ`ğ§œR5O„?nï:E§E£
;\)¦HÜ¹Ep¢#lp…÷q£} éşˆÛßEäƒÄ³„'ŠÂcñ6'koÀù;Òô½øà£(/óòB£Biw‰9ˆy2| ¨ıˆ§œs¦*>MögDh_:ëÛ	ÕUha‡]~b¬+ÁÔç@$È×•’\…³ŸT\J5	.b¹{&ÈP6±ĞÌ\£':Òöq÷k]§V¿DgÇkuŒö”@$Ô©¹ÜUU #brUÇi*|gx~½Ğ V–ö[Ö)m-Yënh0Y¹¼
Ú4åD}®q¡ÖÇ[ØÆÎá’DîÔ¾ÕÌ¬à!RˆŠ°AX, Ş4\’EĞ#Hç;osâ¤úÚåª±¤¥æöâ›a9šÄ55v03”Æ©¿D£R“Æ†šm8ÂÊC5ŞæHÇ
À±W%'	$l¯ÿoÿ(Kï~ö/±.ÖEÂ¤Á59™9É0ã´dØ¸ÿ4â¸ïùÊDá7j±o.Á’Æ<@G´Åu•‡6™UüÒæ®ÓD`ß÷V&©ƒŠqÖy
=jGt9gr…0oM„RØOFËÍ*9TÁ•‘8N7'av6y/S4ûÓ‘­ÒËJ«»–ÿİâ^¬ˆ!»ÂAcƒó˜°±k@ôS(km£¡İ•ûÎJòÅ—ÜtµªåPd‰.ŸúfÕ>ï¼«!,Äçé<?Æ—¦ó°ï©OÄ­$4…Ò®F·¥+¶ª9GÈ(¡¸
óé¾O/å¾ÛävD¬œY›êÎ$•2¨¹­EßU '¼•…ºA.P&E%d•jB¹É°pF!Í5"uñ;o8«¸‚À v”ZW2ƒ_Øàß’WşIà•Tİ?¾m¢|ú *&äYMÅò¹Ì[‹OÈª0&^áß¸Öíş¾i«ĞÁøEÀƒæ,IXSf¶Îó×MÕ\¥"¾ˆ`­ÓVYN
·z?K9J+€¯ŠÖ`ªĞÇ»(’Ëp=(=n×ƒ¥M2‹•Ş¼ƒëM;ğáàîTØ§=*1*²›ëÚeç7"Jì&¢Å¸}ÔÙzm}"¿÷ÔWÒšdùÄLJFÑß¼hn*×w¥<#­”©5ªç\Ó%şß4íÃz™³ğşDm4lÎÓ0¼|n’_ «‰^Ê‹{İî“„|1wwi]Ä¥ª<DÅ·­V|1jŠoZØÎ–_5ÔÔ¢_)«©şE}ú¤uR‡~ûm½ªÿ½9Oâd"Šp’÷°|KÈ+/öv)æå%x×fÓŒÆlíw7?kBV„—~ís>&’Å€ÈtpRÁ'CM!’¿w·»!¤0¬ tp-,Z>sZÊ'®ØÛq;™@0ñ…4ğ•ÓCí9yŸòú[k£ã&ÄQf®ØÙ9Ÿ6^bàSÙpaê;±yS*ÖKHug:™L¨¾¸	xMÅ»QÛ5ëÃ8R+•¯™Wú(55ğoş‘·è(…Ÿ0ğ•/¾şf¨{É Ö^ş<°&­Ğ„F[ÿ§6GüzŠgO–ÇÕ>Ç¥ª£v,¾î
æßhâyB>0„£=ô{OëŸe%Ú€G”Ú¶'Öª‘›•ùÙ…eÊâô>`’›Å{. ›ì£÷úX™¸ëG¿0’oÁ‹h:r…è
¸Î“ôÅî_ŸĞ!8xĞ‘n<òíS»éy¤ÌÂ>g\%€5=Ùp‹nl•÷šĞ78zWÛ€™%ÃœŸ¶è{´Ç×¼ÿËk~9iØ^Ì³r2Ø‘¼»¦õÜoıMWÃ*AkÒg.ÿŒÔ5Uß9Ín3¥öÑ²ıãXj[îmYP—óméæáüvë$*»\ÌÇ!TÄß‰‡œZıùÀ(%m,7Å‰xwşXUåXÎÁ,!>	~FøC»«Šw–@È0‡š‰Í/PhÊ@3x%Ö/Ósù’År˜š.ä	gê"kGP—˜mÃïÔŒ yµtJXñ’$æ)CxÖ:Møn¦Îñ¼ù²ÉÇHK'Oø;¯•z¡ˆ´ÙQÖë™â/üØUdkõ^eõ|(!Í%uƒõ•~šCó¶h4ÑHø¯Ã¤Ã|d±• "}†9Xj¤J”¦ş·ÇmÖ[ot ¢ªÌıX–yÎ2½(İ/.vPb3bD¦ [ íaô	)HÁ<™VbPå}¯X®m0mòG7¬ù‘Şk~=åô±Å ]d¥ñ».´ñ'‡8<Hßk/e?N-ä›0ÎÈ‚qøÄÿÆ¢·ËéÌ‹¯?ä‡ß…Ü]uP£x’»M™ËÑ·­NÇºÓLÌ´7â.bÍ™‚~Æ,=˜Gq-	¼’?6G}p1gÙa/-hØ¤8ÅvÅïWuÂH ¶¡IBrPU±µ…=‚»›µõKZ«œÓ>j7HÏ–chÉ­-tşn“ö<0V.¬ö’şW%(u:¡ì¹„ƒM£s9ÓÙíP€Üg)'¸Ğ÷=uyT°ç+.,”WE*.ÂÑÖ%Ó¹Ÿí*5p/”éÑ7}A`mPDù€P|z?Ä§4&á¿Ò‘:Kyb¡¦“*ŞşıĞÏN#É|Hs××qı|Êîñ¢«KMKö*G	ôıBø÷ 5á[ŠÅt‹è5½¨„U¹DQ½ªİse&OÑøÊ]z³13n’HBK7BÀƒ•×
¹á7¥L&’-§t[é±¬cég{'¥ÅÀÃ˜GÏÇÓ#£å <#PyÓ´	ùkŞ'ÌEîÀH*¡kk$)é…İµ>Ï…â6tÎUF'ãIÈ+i…¤‰.­/äÕÇ\ÎƒMÑu[wŞÆ©ıL¹r÷äB7NËĞ„Pä«]G¥QˆpĞ?gà—T!i?]5ıÊ—RqõëÊÇm³İÓ·ÈÄİq[Ç&:ÍêµÕ«¬ËVäX52­Üm‘€Öyipä›’lo`>hØx¼å(YõØˆğX"åãŸ_#äWÄXŞÌÛ•06Onùé§ynwŠa±ª¸iÀ.NaÌˆF¡ºD„•%İ ‚üâêJö}ß´ÏiŠg'íÏÙ+Ú¦*v½àÂÊ0Ôi./—q\Ğz?ò·ÈûSÎDKı[Æ×.­òñ·÷ğe¡;uµrî¬i‡	q@Ã#Œ†Ëf¤¥SH"ĞøK—WEy¡ä"i`à’Æb[5¾DôP_[ù¸zÈÜd¤î–EvŸ?ş¤<ğ^IùSŒš{.ådÏİPkW¹°ÊÖ¹ÇÓäğC‡ésî«Ò®ú )
VşU×™‡:ú¦˜&ËV¿ŠªW÷Jé6lõ”˜;.°Œ2k_Ìãı¡XòÌÜ	&[ø}õ«w[ÈaÜDQU5€Š»Ô=ªÕÂó#û³_Vvì—ÜmBQd)¦¤HhêV…ıq&gê_BêÚÍW«>qƒ~’ŒåQB˜mJòbÕ•ñ*^W;ühú$)‘7İÂ>*dhïá!E}6Ú‘w…Iiæ±bÆDIITK°æí„ 6íÜ7~!rá¾àii´¹™àÀ+’Yz›f.°í”îö¶w×_¸m½4Ó©_¶–®„NP©§ÍM|pşT¡©Ûh6î­Ê%©´u~¢ÉÉê[ìMMÇbzÛ$“êîó¡¹.aÕÏœ«&NÙÀÑ'@CgîñqĞëæŒËíQ¿jì¥Ö9í%ÿ_¬]á¼.3êGÇ+l1nË˜6jûJSb’„«QÇqÊù‰­ÉXÔ,2ÛP9áÜGVòÁVKĞÒÃÛÁíÅ@Á»ÛB)eÎê ø¬™h­Cõ$æ!³ J]2v4ÔOå+(.¶S BØ·%Y¹H©W]´<¼óŞÄ< d¤ß¯Ÿû§Æ¡ØØR5LÖ^P7|¸ˆÓælU
?@•D.q~¿Ä6Ü /KÃsIùxÈ³Rr$èû¤DÈ¼'ÛŸ·†‹¬Ëe˜5W±“§½Ó'o6)7˜WÔaN¼×Z»Â;c­GhI¯]å“è+ápË‡ú²ë¡RVhP„'©Gb¤7ígõ;ÑKgºê¹“ ˜{ª²äÇ@r³¡Y
‰Q	¾Š3|»ıRò@¨é —l{”7•”ì>Oò\ƒgèŠr‚h?ğâ)›µØcİ¶ u¶şkÓ/¯ŸûÎóD*7ÜîH±9yãfQPö8/­ü‰âd÷YFÒ«'"%%Òüe ¡¿¶®İKc´¿6©¸Hº	±ÂTaUœ>u™/2KŒ¾‰E¾™j5\çèì¬?ct}šøƒòfbØ)Æèt5ä¡šÀÄä0Mâ$š}Úß´ØKR@§à üá/nÕ:…-¯-uØ³ƒRêÉîQ%Õ~_Ê‰dÔñ	Z†B•Gšs([ğÖ^©?áÚàHDÍ-óa[ÌmDîë¿Y:(veê½Å˜y-¦ ‡Ú£.J³ I¦±Ğ‡^±r‡Ç_HÉ]†§	'Pb_«•£ˆê¤=¡ÅÅÜÿÀ·²~ã<âº¾	Hà^¯NĞ÷8\$»º¨T•8¥~Ü-N?ˆ)ÿ¡1ş©Ù$¶pLH|WÙeL…Ãlió¸Öİã"ĞÊ:Gx”¿i#ùˆJ©‚1÷µ€Às¬º[Å6”è	é³ZË*?eµ_›ú­8 ÉO›èç/Yí0´ûõ]p-¥½X¦PåMœƒ6ÔèkÄˆxÕé‚ªÉ§ƒŒôµzâËĞ$ÂÎe$àÃ—²6ò½‡€2¾´Võ9¿R±’´§ºyä-Ã““‡•Ê?\îŸ6ójşñ¢Jjê<±?év«Q'yPàIFJ^Í ¹ß¦~™ë`jØšWÂ|—DËÒ©¨»™UÈ‡òâ¸ˆQ€ïo¶+’+NÜ³Üª¶rp{¤H;7ùc‘·B€8dÃOhÀ¢‡–òÁ¹û‘37!NÜ;ßw“ÒWK–9…Z€7ìòğ/‹|˜qUËÆ~Ê‡R>†I6Àº+¶—o×
Ø²i±êÈLHÎ ¥wùmhí‘×™™‚.hœÙ>gâÈû6…]õñaJÕ»·£ˆê¾¼%:³u„ÖwGlvÒİ„*Ù»|€z,T¯m{çÅ‰>O#ìß¸|½6É ø T ğ‹¾ñ˜ªa½I”N+$î>‚`adŒ•Ó“İsKa¥ÁâZ³Ğ3Iµ.€èJú<NO‰E 2È*]c*Ùv43G¨1{l€¡úi(¾¥¥„´kı™V3°¨¦/!ÈhÒŞ•¬•k¬4ò„éw`†AùÓ[é¾*„€"²µ`é%²Ñtàãª)š»*Ssî¨È=ã}A'åc>¼6Dÿú^^—Ä¾ID'êK¶Sj­ÆºœeêUÛä*³íäaêx6˜j„Ìn…²ûàK4S3góØ|Û?»Œek}W´²*·XRq§È×F”ç +=dÇ¾ä¾Ò¬ĞWxkç®ç:&ËİŠ¯N*£/¥<[çêƒ£c‹Ä›&Ü˜SAó5eadè~Ód+³/guğÅ•9jˆŸ²Âg>
b+÷[†éÚC\¯+	Ã&ƒ(O'SšpG9v†š CmÛàå!k•4xÌÈj†:ë×&ª¶'û¯½'”&|GšûD9˜‡ÇGãWv·iªËªÆt	šèd4”Mœ«L§±(?‹¹¦OúvGëX1İLç!í‹Ğ‹)ÍTXWµ§`¨{Ğ+•ö¬m1rAŞCù“X¥p™}*¨ñøÖUòÀ‹ bÕ	2?·ŒÕVD~Ux¢”Z(•¾À5/€aÜ¿ÃÙÇr„²Æ‚ à¼Ş®œÿX`^ñöâ­ÙïfŞ½™På³Ó6ßmM—@#¤Z2Àiq
›oıÎÃ£˜wØ [f_B¹bÀéÈ@;åQíı¥*w›|(½ÊUé­-¡Æv‰Œ£·£Õq”ÛıBQ…š´ÿéA¾zRaş›-ĞÓ¶Ë¡š6<–õUÄº©¸ÅÑÁ¬ûaP3ğ-° Ñ.ÖhÓ‚X ïŞÕO¡É 1¥>ÙÅ³¨L-3cışÚê`’9ze‹¡¢S³*ëAU¢>h•+èĞ*%Ê4VğÁ$J½8XoWï·d.¥ì¬’X¿Eãt¤nÖ‰R&´b<[AÌÕî@a;\
/aÑDG(®,ÅØR=ùM­3–¨¤“xtL›ÔJú¿Ã²ÏõÆø%ùÛ]zÂü“2Ï=ú`º*òvW¶à÷xÛ47øØJ{½çõäµe/¼pK6ä›³K6³ŠÂ¿«éqÃÊ=¢¡ ;†Ä²øDáâŒ™ÚğÅ=ekÜJá¬h$"8ÃHšÈá|)K¶	—ı€“yViÂ$'ÁR23¡ê>O}	8Ô^@Ê÷¤#·äıoô¯…‘Á"9ĞkÛòq¼îÙâY\8SË^(ß‚4€[ÑÀYV ^=!Ÿ ½ıò”/ösÔH9Ù9Æ5p‚ ~]•+ÎÁÈr>JàÇÒİN4±üzÙ19.FÿšeK]6a}‘Lç%ó^UzÔöŒ1›Â‘`s'8±ÿäo‘&4°Åì–L¯İqpéMPL•İˆİ6ŸÍfwA'ÅŒdG©x®`¡Q"`<ûÉ¶|Ñö–è—é2&ÈªÌúó%oßjmÍ t×Ïè5›.V¿ Ñ¹¾.‚%LËÂ+n©]yœ9Mw™°PÏ›s.ÊÍx€}# ]+áXît»I´nšäQØ•‹;9¬ƒéÁ•n5HÜ=š+ª'k¾¸fŒ{rÆÁ˜lÇ,B	1af;Œ[c¼©T©Ü¹¸Gƒ©qƒ¨rvü5*µ T jöïÂ*S„i/¦&”7óeÊ&¹ËÍÁ?4/şPo“¬^ÚÂàÔõ…8"uÑèëÏ ¶!}*lsÔÍµı)ÅÀÕ¶·»Îh´ĞğöŠ´şyã>¼Õì¢º3m³Oì•÷Ê*ˆ†¼¿ğhk#d“4šGOV+}œêğ‘ä†d¼­úş]f¨¨æàhiÎk>œªäÙûévi|¶üóvïëäãÏ‡É\1[ò}g”L:YoŒ)h‘#èÓYEgGÚ«ë	LlQ8Ø>ÊmšÙâN¢ûS»{Û•y!KpÉ´Å&ıÕÿWŞÖ‡)ƒŒå¤ò´|ã“O0&¬vr©U‘fAYŞçn²¾{Ši2Ó´/CØáÓçµü§{—+{ ×u•t]±8¿x²œA0ã§2ÜV¹ÿÔ®š.ÁB4g¸YòxeQ^Í&Fx‚³àP8héü£”m½~#š—Ûä£Ü–ùÍõVª@ì5·úı£yciœ]K+F4jR*W‹ä ŸÛo™ëæÏ ?)à}\–,¾Ïº…ÎÁÅ´‰–°ÄĞ!‘ñøıT3de«eúo&<Ôå?µeûQô%m}[/=Û'VAp”y¸1g¬Ã(âvŸOGISmL7í?¾[«8ƒW¹bôá.>åhÍ²¸tíãt¤•»¥óìåh©˜˜g”—Y*ÉãÛ!»‹ı ÇÚÕĞLïNetß]Ü–—®Œ½{H®gYt`c|Ü²·X3¦Æy— Yv
UÊäqBDóTqüI^ˆ¤Fì"–…ôºB.–#ó…Ø$7É™›‡µe‘õÁJ8›°ÚØß•ºG÷d}€-rqİ¾fš#‘æqÍPşòH7P„ÏhµQ¶¤B¼˜Ô˜ÓÑj·…Kb«¢ö=9£Çıß…ßAm:‚Ê¥‰áÿ.âğ4¿’BÇé£Ü}1«¤îİ0w›ÃO@æKe6¾úÚë*8&¹`ë.l‚ÿu6M¨]}_-*^¢ÅFÿVÙóû&P`9ş8i/Í½Ãğ~·øukÅwòÔhWì·w‡Î×Lv­Û4¦u¸J*ø:1{@¦œÄUö¹Pï“Ø+Ô,Ü€ï¯%,éÙ¹6‹ù{` ™C¡Ö•¥„­ªo†.w¶¸¡bH•ª_ş¥¼¼}ÆÁß…
ÕLÂC‘_°fÔdTUgÅİ¬·Q"ã! ß†+e×°8œ±Y|—×C1ÉRqø³|æÔ-ã¡¤ËaÚ°ÊëşÉ©Ó,¨“YÂ³©ÂcKûĞÎJÚÜ=LGIlO¡&şo¶¿x°ÇNöØUÕ"o;·>DÇÔ€h„Şã:y:¼–/nSNmüøÆY™„Ÿ[ul“†Û×¼mòPhÏÍ$ƒ÷,×L<¬¹ÿ™{»#ğ– íS"²Ü®?±™+(uà¢ÇÛW““á®~g³6SO¼Óı…ÛúÌÑ'äl_ñ­Ç6£$2®féâò3<‹.ªµ{5py}Şú¢=ûOrzå“KrÔ¸DËĞô˜/„$IçÒU‘×Û'»€§–Y[Ùl.IzgI¿: ü/İfÎ¿×T?dÃ‡ŸÒÊRAT\E-)©&óW¬Æö #¯h¨_$Ò¢*høÀÕ`µI%`nşY­h²Ş¸F}şe$¿ºâ‡UÜßUÌŞ‰Áo¹ìh’«÷ ¸5ê<)§Pæ.ø	d‘r]½ª†ò+†­_„Èí6«‘šÔ’W""mĞ¨ úˆSl%ãà™v°şÁTg¸*)pA]n|¨,µêDö@T›ìˆáG3ppj~z³œÑ' h¤dM‹fĞÅºÔâEjÅ ¨½¢–K×“\2p“K
˜;“SÄôæ6Ë{÷v³9›BKá‡3‘¨$’eJ$YŒæû¨Å9Œ#Óï=ûrïßh~Á3/¯ÁÀàË¬Œ>rDb?ÅqÎHø!´ñ^ÇŸÄä©ë"œiòÕY	=çşŸeAs¾ñƒşCvå€níi]–ê¼¾³ffjAğô$«	ĞDK@¤ÿz5·¤ea-°ÎÒƒ?{ƒSº`a^ÒÓ«™ÊTgèrdQÛ'‹«/m÷ÈzH_»ôy†î-e&vÎ_ïá›“UĞ.Qî`„ğ»VïUŠ‘ë¶To±çªX³Ì	iĞğ¥Š£êºCvä™QAÁAi€û&Æo5ÿEÙX îµA»!Ë”Ó_.” œ¸¼¦È]Ÿ(sÃÃIGú®ã<º¯2ÈŠZ{(äw–•ƒ±9–Hy)ºÛlĞÒ{ÉSPCmÇ]™ƒ®nGíêÁu)á=ˆŒ;!‚Fœå8†Y8Ò5Èéü{×†h¶,º| 7ÿ¥äĞJDÏ¤gÜ­kåß<(µx	Q/(nÒÈy5º‡—ŠŠfˆiˆloÃ_Clï¹@Øşµ–îË²İd¿oïá%dEkfª=ÚÙÕ™‘x•Â™‰	%ç…ö ç(#Ô’3V–Ÿë†o’Îì+<iágwR‰'×¨–J»Æ|™wO.°'‰”¢yÔÔºa	Ø„õW§£b¯"²™+q;xµ’u$R[²Õör¶šíy´Z‰èĞNùXŒ¥éåù#şÌ^¨TL¼MÆ¬©„‰ø^ èÛ|‘ˆõvb"UÀ,Š¿ğğr)ÔùIø¡ğ|OyÏ¦£E–‹¨ñ(¼¦mş—l­ªŒÀ#h3'É/›9m¯ ÜÅ=P¸iÃ[  œCœo6ëU|jp®¼ãŒ¯á¸ik½®qä(³êqëc$x“–=è‘ÌåĞÜÊÂá’e<¨w0cBÏ”Ä¹¯Ñtê)	³šçÓAö÷°$UL|l¨ÈÔ—†°|:›b¤X&:¬
y›+J^ûL†ÆÏƒîUKåöy&2rÿ©¿!Dmµ Kt’Í“^Sí^·seÏü•‹uèÁÚÉFƒ…Ü+x’}›âKùEHˆ²iAóeøÈş,|3šRòXtÆÔ…æé`ËNšì× ş`“¬TélhpE½ã|s
IuF¢ıäßT¢×Eä¾·ÏÖİŠy¸ïó4µ ¸Š¸½¯?ÃW.ß)X$pƒáÕˆZšúì	³8’Î<ö}©bqk<–ÔJíÖ£©·’Ôz˜kTÂ
ÄıìzJ~ìWYYxb9=Ş?İ]BâJ]NÖ ³¥ßğÑÅ< ï¾ª{YèæmğÛ@Êt!=‰ÁqŸ·Ã®VQŠ
¸´yÛĞ®!m$ «VO;Š‘<E‘Ûmš­1£…÷Qrü6›¾…-/f*àõwVÏ€ÊƒÇA2íğ†ÖêiTîeğŸTİ¦^9jÏ?‘o¼Â¸²,Kå¢fV4c	Œƒ#r±">Ç[÷—[Ê<M ;…²e ;«@h<œBCÈó¹Ç”ø³şÍh
¸G[I±s˜ìÚÆxsİZ g³YÒÏ0cëÊfDcNß;;×»,Ë…¢K˜¥.¥ˆô¨K>Oó*t¸%>Ÿ¡0!ŸdÁn	õäQÅ‹ş1jÏTa•Â~ûÿõÏ­X¿4—=#³‹&ñx¯÷,»¾“ŞÈ„vşˆê]8v¨Ö3r
Z7(‡ñ.°nÉ¼$Ç7jo¦']QXöMmÒµú²ş£··¦?	¶æ:à	ŠŒôDÿ hn5ŞÀ#—ÿ0ŞÀº·@ºU‘ó.å[¸²ğ>%Ø ~ËÆ6JE’âF„·—ı:›ÿŞº#BÕ:hßš$‹·k²ZŠ¦—Ö×ºÆÁhÆ½U?5Jl®Í¿0(Fä¶­àkó&oXU† ÿù5„¯|Œ{fƒ\´ARCØÚ{çÜ5ï2^1HC¥húD|‹ÍoŸ ‡HZnå â@ì¡å÷¶'J¿ĞÛä{Ï³™L¼ğÉz0¢>´³ıÍAySZQ¯Á)ÁÛ•	MrBÉÕÃ†®Q‡Ï¹7flRXGù…	´ûi²şèBAnoõ|Íc'ã•dæñ2 Ægèí"mŠĞËÂ?£D³ğBV`‡ DOä/gÿul›R˜I%d«óJ€F¯{®M$2´SÜØôÇ°D>ÅíqiÛˆ¡,u¬ÏnÄ´¨"gç–šXVÙD¦şrzS5ò°înîÕíÙD•RG+Ä 4ˆG¯…ƒ9qñ/º"ø¿™¨C˜®»¼—îö7áÔPm^Í	
}td-áw‘Ûûğƒ€á{(\yšÛçåë6Ş0'{vHú8aw+ÁÒo×v³RµCŠSÏü	Ç@BŒãNÁxGª°Lawî½…/tûuPÔcŠZ;kd‚9›„ÍçzÒWĞ’¨±<:Ê¤)\3*£4aÆ×îê¹ö<)îåğ:³“Ë¿9¡ä%Ü€ç% 2VU‡4Ñ(İt@{cNİ¶)'Öç‰ìšŸn>„†ÆHäÖË™Bç»Ë`4S41ñô6‚W-iáØ§CA›WÑ«Ÿ  ¡?*êŒ‡IŒ°mı÷éjœĞã û†Í“?rQàî-ùr. 9åG€«|Ğè3åFw‡—¥ F´|å¦4åH¿˜ËH3ı­ô9ù_õ%À=œ*m33ìÆÓ8Äš÷ÄWœ‰oPWÌ6¦jZY’Äs´@ÓÎU›?”×ï/`vÎœi8šùŠ5Ê™Ê•ZèOÈOí1¢Vãr²–&¿8¸Óaˆrä¯•´¹ÑVFĞŸ!ºh¥±µ„NTœlWr@œjQäNh%_œéI±8¾]Ö™Ë,šç …º”æ•¸€	x9ÿé)I7ŒÆÙ]üª·ÛÊ(y÷}ÖÀ/’/{ÿÖãà+áúşJ¡é|—Ş(ä=l\Ø@ŠtNÖƒ’\Ø`ÁP© ëğ1¡QÇ<Xæ]ov­)¼;Ã„ş°W,¦|‘Ö¨éÖè—ALåW¹® 2"¾a¾%Ók£œ_æ-ºªÂk­I¸ì+Î^Êd¢mİ‚ySB#óHfaïªi-wI-ƒŸöJ:bxSâ©ëdëcŞDÁùgÖÌ – ºY2+.]Zku:-¨1=ƒRŞN÷Æ™VFÅ£ş›Jè†ˆá“ù6–.3t·v9#œ!0Q¥MÈ–‹®i
 ¨Í >‰†’šÒÃTİ ©7x¦W# ®êÄ²•Ïïõß.hİÑS‘¾³Äê1>æ§1zÉÒ`BV"ôœ¼şS\KùMÖX÷¦4ü9]7üQ
­ÄÜµk®VW‘Ê¦óØr“Â’À(ı!1?V·İ$¨ÒtL¸ğ¾€ë\“‚½pDĞ‡£»£ÒbËÀ]aá÷Ô’Õm°áLûG%^Cjƒ éÊ¡›XQÃ5H÷/y¯8ô·üïÂò=…w~ãõTŸ·%ÊKÖ_¬¼Š^.‹¢ë>sÊª¿õ”­	 r¶äÃ)ÈS]Æ·ê:I±Ø=v ´z<±Y‡)]$¸¤´ØÉ‡#XõT­½5nø —`¢TÇ²Øã…¿b$ãÀğ••çÙa¤$;û_Îˆõ¼®ö[fµ+Ã‡ˆš€ˆñrD¿Ïë~E…rdçÊ¤ÑŸ\C	öD
*é…¥K@c%l’¥ÈJÑ.İ¢T ûd€>	œ%…×wCÃ™3ò£ÿoö(¾®ÄÂÔÒªé@hW±æ!¸Æá¬ú€>Ë«gIi¨ ­—–í¸şĞB»³òú‚Ìêivb¢Š·cˆ‘«lä@n, ÁªÌTëà9‘¦vãs²h ½¨F(ÔÜšRÂu˜Tv¸|Ú2>2sËÖ‚ÍÌ%¤]İôçŸÑõğå`FNv>JœcFÓ•ˆìª˜ŞUÏ7ß.øTåSvİ• ù¾O¬Ç’Bô³Ï®ò¥æWgépÕÀù¿ °
âF*ÏË.<hrá³`B¦µ÷“p2Z¼Nlrº,Å}ÅÖ8IEg™ïtˆê%©†æ”á*ğ	U¼‹;[
…"Æÿ,Ø HW,‚8‰N†m¸¯yÌ«á¬«¬)<¡tì¾Å–ş*n
.èÆ-“ÃÔ_WBEÜRæ$ÿ”o“Õ%<¦b–y‡[IĞ€zM<kUõr@¿Ì²|éêYüoğM§ËMºƒc–n„Ø®ÉM©ZÃŸ¸«d¥mñÆ³w9Û_¹3MırŸÖ£ãUÇC=85ŒĞcw?òêAa¢3¸›ÆIQ¹…Ä§²$@Rö1ñe[õ§Õ4^v{4°ŠxxñjQpFîw Öé°Ò¾´‘ÍmÛ¸`±r©ê×Û *_İšÖÌ„;í¹ şHÚÆO‘QTZA^VîÄ—¿E³jZ
. EÙõ-.8í^ÌÂÒçR£øö{äİˆøœÒ4”‹MÒn³n3EE€Ã›;©¨pDœÒÌ´Âş¯ÔYéófİ2Æ»æ+Ü.ùäÇ–¨$Ø›tÜ]ŸÊp2B_Y:½ìB°î«¤sÆ¼Î©Ã–[¯î
Ïí&¿Ã¡®}/Ç‡iŸz˜Ò<ÒHóÛZ-º¨×æétG\4+•CmJ8pçZîwm’™u³”I™1–§¿kú}pD{~q£ğ^a6¾v–!˜¦o‘8ò•ĞYóC]æ
»OJàJ³bğI9SBôQé™ƒ=X]Ñnò…—2'¡Ä|´µÀÔƒã±9íŒZgÌ®EğL¾hQ(õ.ætŒåª7§Q×ˆS5_RÕw1™f¸óOŞbU1IraxYÿK§Â2›Ë¸K?uEKêÓÄÏÕ¹—©ítİ\šQ£\Âp¬tÕj½S$d©Èb
<Ğ4ñ†KùR›ÚJÿ!8dX¾}Æ†aE¾ù`s;Ë>qD“t¢@6¹ïñçM•çjÚıô €ù½,t±Ì?A8Ks˜øÆ33¨Áf5Á‡C­W/pøC^38ï²"Òh ˆ½ÙOÃã‡UÏ<Ãæç÷”8¯ˆ3†‡y*=ë>ÁgŠh}s|ıä*Mâ#øDxš¬üEà¦¿›!LÌ½Êyñ­Ç\AÛÿ	IÀËé¾7óş»g'Ó?Fík˜—Íq’°( qm¥+"$‚5¡ùíÃ“%Ã_ßñ,¡  İ¸Ë˜!Œ&É¨hjhñÎPÜ²²–’#Å`°óïÇ.³	§­íÅ™ª}ñGgÃ=ËÌÅùiº¾ª„^ù Ö3h3kE`cÆÆI{ÁÄÍBb;uó<ù”"ÿÏÚ,Ÿ#èG¡¼2gëä°¦…UŠÙ8[‡?voG±…‚ûµ$]‚‰Ô=@©íòÊàGÓ½Á÷uwˆÆÌWrW:ÂWÇ—ÈZ†G&Oÿ§iİ=¾l·ı7-¦?¥Ù•.-s‚£©èk.=j;úÒMš‘¿*‹u´Ğ›íëB|v‹şa
œ_ñ­Í·· ãXˆD*ÎİÈZ»áêùI!bs”ë ¬ş{•aìIƒeLEâ ]—œ#¡˜ÈEğû¿ÈQS›Ã-Ì•ÎÂ^Ğ¥u·6‘3äBZV÷?
Y9˜yrGF)ğû‚÷ı(‡Òº£›^WÔ-vpø™jé¯yáä[íùÒŸÒ'-‘—|êm^”l¾&QüáRr	ËnÔu(iI5f0aZé	{cqáÂÑ®ğrÌô?5Jg„ª¶¦ls+	&7	€/Ñ|>}P0†ÊÒíôô×¦`ù#­èB*8­Ì,}òª=¨º[¶n €®·ó(ƒ’AlËÑ`’¤°uC>r&õ4F¬î©R¡OVÍzGU†?×q‹£Î ™¥«¥ÖU>S°Å»kH§s™ÚèÃÓ­óW_ÿË<ÄbÁ™9NÏû3êï|İşÃ}£ŠhÆ‚/ë‰'~í¬fİNìÕèğ0àihDüˆènX¦ @CÜÍÛñ-›ˆRÿ!ArC*ğÛÅ ‚¬¸˜;º`¤o²c &UzøøÔª‘)ŞQaìãº˜1¬î…Z·Ê!.l‚°Á[ıæ´a’)='¯#ŠsñæÈ5eÌÕ™*ê‡"´	·Z‰Z·­òßÔºb6ôê‰sUt   Ìd…ç;
Œ ï¡€ •®íw±Ägû    YZ