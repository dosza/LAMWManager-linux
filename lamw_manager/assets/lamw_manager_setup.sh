#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="988266399"
MD5="9a1ab16698096fbb43f4944540d5bbcc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23688"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Wed Sep 15 14:11:47 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\H] ¼}•À1Dd]‡Á›PætİDõùø”—a‹ãS›“«ïëUT'rí:ø½¯V¬E úoÿ6ÃAW8Œôzr2ƒMµ‘ÛËÖŸÑƒm®`†1Jv÷Õı¹y›À:ŞX1¼1²XZ'-5 "¯8Vÿ˜+‰2NDH)X:d/tdFnk=ø¸›şF‰€…(‚å:™=ñUxÊ/föDc5_‹!¼Ú¢’½ˆJùïI?I/ØÍ­Œí•ú”"üE«
¢çšÂİ5ÎÍ Ò©’
ƒ,ç@•92c†ñNJnŠoV1 Ô†N“ u?sTğt4Ä—ò T¥äZlı™Ü|qmQAÀçà¼ÂO²`•ú01µE>3â\É7eOYæ*J<Ñ*Ú R
1İéŸr+9¤‰öÒÃDßb§òX‰nPŠŠ«í÷ÂzØ¹ElÜkÂÌ®ëğ§ƒ½<I:âØNnEê‹ß©ÍNš(s€©»(fwœ8ûWÒË_|[ &ÕİÑ æg‰fjè-wáˆ!WŒ†pÍ×|UìöUF÷¦
§¾`‰ÿò›*ax¦’—Ø$Nf¬‰â½Æ{f–Šn8«ï8»BLmn‰´ÿ#3¬Z> ;Ğ˜gÚöQšr¯¾P+˜‚¢¹ô”¥7§]¯Pu[à2ücŸ}Âª£,c5©Ğñì8ó›ùêt…‚ÑfD	"æçİƒc¤[¿’`âCA›3Ş&K V^a*Ut_•Jy…6?îÚg{‹Ô£Üå*–f÷7"¦å3	=ê`>æ¥ƒk(n®+{æÛÀ¥¥m[HsÍÊù8>Ñ7’ùÇ¬²Ç¿Mƒ(xtæ*´Ç·ê'ÎzåZ fMji£è¼`dÀjâÄ9Où²ûh¸vˆ$E¯íãŞ+¿™/ªÂâ?ã=‰íSó;äqİ×*úJ±½pö òâ?Ïdòã{w"ò_i0M$µû
 e8iFaŠb'üºÒ«nŒc!š¸4DyéZhVg49ò-WDQægÊß«_Êpß$Oäëóš"µ5áô\¹B‡gVŸ˜šëÔ†òÒ½RÑQYpÁûá:í‘†Tg–+Z¾×(oJì>+©Ğ×6èúôÆ ç’Í¾õ†»šâmãGôœ¹ù3–ª"³$±9Jõ–³¢!ò"	P'9¢İı\Ÿj'`w 4@,ëYº¨ §ÿ£¢#„à©•|ËSN¹ËËYyÂÙ~,)¶0ñÛÀãD+“¦Z•¦İ(ê·‡»|ƒ=÷îŸ–êF@„¥„©2ƒfó¬…D~«è…^u01ù0dŠDo]cĞN¨8»ĞG§ \İÁü¨f!íÒ˜,XCY"ª›ç2CCo´ØèûÑÆ\3­Tx	»1Y;³éˆU¯ãƒ±g©Å
2á÷%Áè°ŞÌ±ë–±ÓØ8"ø¸Nê®š|¬‰³ºóZ—Â—ó{jš¶}8$¼v(´ùñğTºÏ¢ağÿuA4ËQœµmš¢¯séYSO‘=oû&Ÿ‹%ï—I–?–oU?ŒtÛ.CéÎ°×á¦ûGC¢œĞó3Ä.5!”ÊSLnÓÛq.Ê‰¸Ù‰¾u¬-˜<2üO¿l’x"i¤Ç	PŒÌ6•?`¬áJ¨Ú³9H¦8€=ô|IàïÆDÑI]~G—Hãíjk´lSv?¡ç<4š»öN²Äpâ‡Ì‡{ù§BŞ´”cj±æÉÆ5åu:½Ú‚.½(?°—É‰ı€2%(ùbË‡†@˜Á´Rÿî$Æ‚§õ¹—D%Â*áÿº	†şQÙnØAó%®´9‰˜Ö;ß…ì÷c»qlİ2|²è7J[s²È<Šï¦·9Ø&Î¡\âdğRé‰â¥$f¹:÷=7İçp#>Sâ˜›2õ¸FSè’£´Û>a»«Ñ\w`è&mrz½>_>éôáãX2“_şg·ÚèxŒ8A°RÊ!(İEB¦hJ§a$k—j5Ù­ûÖR¾©6$•¤Ê»‚ÈsŞ {ç¶©¢Â{‰Å è$iK3H?Ùò-üO3éÔ,¼JYÖ˜.¬lNë±áf|=¼B¨PŠ¢šÀjÁ°Œ&U©^<×…Ëd²	mÄlß˜¼wË:5<ŸÓ0AhœR>iL†íª§Úx… ‘-&I3±Qñà¸¼b0«ïuÁš@êÄmív¼è¸$ë	Çµmç~š#ó^Ş['ß\Ş
º´â#TR;U¨?Ñ=de–JKM÷İ—_¼›ÌlvûŒ/â]Œy‹u˜\ïöëºÖÖQ¨9ªÄ¢Æ^+‚6e­ÔÎUsNıI.Ã¡N  MÖ$CuO‹ğ§àL6k…†s­YäMbYOS	!â ‚^ª&œdo1«Û1xÉš³ttåÍˆØ×œŞï£ÈK(ˆ%¼{Á˜/6ñM­„™°â¿,¶:¨T~JîP\73õ®˜ı ¥2µ—‘Ôj7`ÚpÛ° Š\åb¿DCÛ0˜±™Á'ße%`‡ïöû2KYÏ«ƒóõu$	ÄvQq7pâoÚ’~Ã­û8!ëÚ.à¯Ëxpˆ@T$‹ÁlcÕ÷ÑCı×EDêé6‰ <uû35Ş=ÔÇĞplz#cƒôâ‹7šîæpkmBkJL@	"s­Øè
B¾ºT<Ê¬‹ÕĞgÓuí(™.¢/UÍùâôş
»Œ¨O\vÿzÚ‘b6YÌm¢Jÿ;MhXî%8î¿•TC–"ÓÉä•á¥?½B##ŸWªã1=F‚oŒDşƒª7ì’&–nk¸h»ÆL¥RÎÉ‡Q;vG?Pàr	ŒT%…òÇ9íêşq8Pá85ô…­Şg%¥ÅqªCUÓ!›²,}t›Ş4ËåLxÂçû’§É„ZÂ×’dfÍ“l¹‹yôÆ.”˜¥<îºëÇ«‡ô<\‹©/¢e&:?]Ì//½#_SÀßél¿ÂX+\óŒß¼.²/±íı‚'›ï$dNùFæÓ6åömE†~Ôqˆ©1 V‘cj0¬-lNÌÁˆ»\•êÃzæXP^cóXv¬k€¨æPQûg­QxgE’.\£–gI#T0hÇZîüûºC,Àšt‡#jR˜©iŞ€l¦½™L~Ê”Ú¡,‡90¸Ï}¬OçĞ›}‘œøU¢{¥ÚJEXÁÆ„ús-}—yI×ô·CÌ´Ù6÷éC¡3åÒ!^Ç†ª¼LÀxˆ3”uƒBù+³‘OØìp83ÉJñª¿·>¾R®ÿ9iZŒÂWÔõ´(Ay—v{2ÏqA9ÍÆ¶GS’¸ÊÍa›qQ1kÂOjE¶õ×ÏäÊğ%èeRi.XƒXh¿4ab²dó\à&=Ûò‘é·á	üd;¡õFçç?A–‹{2+ÅSæ¥LØ¹"Mr¢š/zÎ|hÂˆıé t;¡uñÎ¢yKö Œ_ßu ™M•'ù¥¼èªæ9Ú‰&„Şóˆ1nie7NA×ƒÌ’vÂ|áş§3ılºT¹Öc»4Ò×÷"üÙ‹pgîÈ™û½K!’0ğ7G	dïä¸wqìW±/¦Ïy>¸â…2Šüx¨ƒ>2¤6xfíF»:aÒ‹H{wT–§6:Ä {>âXïûwo8Ğ8.W ¶ZŒ©d´b¢,[Œº2vô[¿?"!ğ*mí)’I=ır¹&»× KêÏy%EÇ•òV½î¼¼?ƒ¤­^¬—ËÌ•‰£pfvá Éîş­Ãéiš6ğÀdpOÌdº°	ğÙhj0‘ ú®Õñ—°IÇuî™¸ñ_=$O4ÛtŞÎd¾‰úyû.@Ùø©µ/[åDà{$wê'¥‰Ğ\)È°èù«Lß
Ü75ÎIÊvĞÇ—ÖD·×]Ñüƒv¶)‚ï' r¬’¥¬S`³˜€²:ùÁ¢ÖÎÆêP­OsP€ l)\_2sÒµ×÷,Î½‰£?Æ|C¦æöY’ûhØ±ÅE4ÅàcSïİÇªÍ\	ˆ2c¹‘Óö[¦%{Â°ƒY¶x›â¼aK™©*ª†ÊPøí˜»0O²Õ¿“#ÎiTàoÄ»•ÿÕô İŸíô+/g1<¯¯ìwÆÄ‹h©”¦Åâbo@rl>&S #{ñÃ5Qöœ+]×Ãc%ÒºhA>÷xcı¢bú|œ5ğî–óŒİXÓ3Ñ3¤pïØ‘·Š	Rú!`XaÙuûá5Ğ«Òe$TÈwP‡ŠWvT°5òòŞ§¢*Áæü“»¾IV	§YŞ [wÊÜÆ_uÅ5Ê¿óL\/Ğ*Õ’…ä©‹­£éoSj`æp7é×
 ş
µPR­’ª®¦I2J1âò—’•¶2P´¡‘Êb‰T•4]µıVuÌLUNø¼È‡ ¨)ÏVdI‹Õ—¦Y‰¿úÏ·¿ì`<G[éI!¸t'±'ø'ˆå-ÿ©1²…«¬#ÿğ™æëõ‚af'A²Nisõ ©F~ÙÃ¹@ÏÈXºS{QXÕˆÆ…r‚Ñ¼·‹Zğ‹:úÆùéıÄâÊ¡ªø¸s¸ñàXe}\Ôqî;ÕİúY–>p4vTµˆl0=Nu^Í^7™£ù«nÚÍì¦ÏpUÙ˜ğ¢iaş1¢YkÔ¤@J`Í¦£R{¨<òæä18m®ñ´Ic¤Ø½ëm§£Ğà‰€~”¢w=As-Š,6<üéO-j)€¿±ÕvÜ¬^¹µ•ZˆQ/©ÉñÔø}›KôË‘Ø,Nâ."÷¨ßnù­ª+‹zTÔ¯9ÆäÒ¢*#G*nõ&gíäÀjÜjËÊû#\˜HŞgÎøôŒ¤»[Ô1^S¹Ôµ[T‘‹»Õ|FÔæ(ØÔâöıû\I®ÔµE‰OõLÍêÓÃ¤P«4éºÛ”ñ7
>ìP ´;;:	·kf+´ÌÏMâÇŸœ|R’=Dú@ˆ?’U`¬=i˜TW­{Vky™0“IĞ&†xF#©qÆC“õZÊCğ3Õ¢ªJ•’ÜªÂ#Õ»ıÂ>İ‰£”Œd;¾c†Ã…|F(şQX‰à ¼@»¦İ|œ±sú*×™#³{ÑíèJä±Ì"´j#½|ô
\gHE=T­+úQ"o;½(\ÏN‚’ø5êÏÂÿ’ÛáiºLbşW˜è($"zJH#î} c@áú‚¤™¬
‹·=Dl"cÊºzFÊNÖ¼Ú;-0EÁMô¹=Àä“è~ª!5)c¤ƒtHg s5Š<AÙ8'Ú›ˆBtÃò,^”Ş˜3½¶6Æ¨#0íœ}p6ÕÔ²>óJb©JõèI‡¨&$å‚•0ru“×—ï–qŠ¹Î–IU–Ô?»À3óAb~ÙR­i›<ÂaÊĞdy!—ò¤i˜C7¢ÀÃMrl’ òc¼øq=[˜ nó£,æ†¶<¦¼`ùŠÅS…ÎÿñËÉ‚Ö·Çß‘]Àb2ÍŒ¾ÊGF N&® 	Wl’vã,ÃÀÒƒ‹eÏïİ!%K8ÃWf–¼DÇt;3UñMÊŠ‚6™{Ç#ÒUõcÌHAmÃ(œÜ¬˜ÌÄf’å”
}:”£¹]ÌÎ”Óõ,¾{&yŒ*êçV* ¥{ğK¤V	À#MıLßY/Ù* Ş%î-¼<DÀ;È]a†OøİüéÃ½İŞÛ0##Ùè1S®¨áöÂó¤©Âi¥sá, A<ÇG©mÉúÆŒeº¦nŞØ\•×+²yMoPÅæoKV3—Â–^ıã|œcöW£–Öwİ!£`ç+°F#ÿ6Ñ»@‰Xtüş±$³ÌeÈÏjâHAQæïÚFÅ§+¿‰
­¤vX+‹ìaš÷…‚—‡ÑY<rH±Ö`‹ó,œHü"J£BU*6jš2x
Y4vşşpµD=Ñ›½R¥­ÛÕçíòÄ ×íFN“©7ôxû	{øò¢XX.‹QJâ#›Óå|Àš(9jÆ G8®‹J]"úADN;OD'=ÂËmì»ìšo…­õ˜”ûfü¶Em±¬ì3ıvŠÖH?#™Û¸ñÿª_Üû'vñTĞqú°gµpÀ7(7ãTA¨l«¸ûİCo¼€1œ¢¾,h Ö$GÒÄ?&Ôf2Âoğ dø´½Ïe³óÀõ{A"Ş@Ñ"Î®ê<«ü¬ï? ®9dÄ“XFâ!7\iãö’8IšHµì³ç’uL¤Ë¯öfSf†¿®Hp¾bK¾³™™YĞİÍ´µÚ»+tĞ	µ>e»è^÷&‹¡¥¦‘BÕã,&nV1†²‹‚ü0®K‰ÎÁ±–¬?íşWûô×#*:±U#›r4>Ê’š³·Ktõ|Øq¬¢îc±¾±ë…˜Í‘¯—[Ã¨LL)¼ÚÛ-"»ee­ˆ[İ0’†(2ÛÜäåı;^M$?şú¥Fiøôfù/€yˆ¢Ã¢é6?r3$‚?K~]Ãä_x‹b_ESUæáıˆ®ÄK‰Ö/åÏJ"¸ë`%_ënŞĞŞ'üXGÈ$]šeúS‡Çşª.äsñˆ‚˜Ó«ööÏ:°æòÿğwõD†—ûŞ»[¿ Ò[áP<WÊxLEÒËzšå Ù·SØT® Á#Ôj‰I&Ìd6ÏnxæXi+)¤.†ŒdŸ3QKFİ,qÜ[Ğ™ëDµô‘w©Eã:WÁ`ÀİpJ ·b˜6]²¸`°İFôQî…´§ÿ¯ÖÇÔ.¥gQ‘»fè/Šos)¯Ç¥e©iıÓÆšõùø‚fmmšŞüe·˜íx°ıG]ÇûÔ„•¦5 dë™È§ÑêĞ0‰ô©ô^.ª¼•ã_ıç½+$9&kï—çyY³j¹påØn#rØ[œÑ½çÜ¥¥Š2h&æ êYè;}<mô&ï·zU«á0Çğ~Nwd1y(oı«Î5¡Íb+| Ã)ÜL¯‚Ù§U>· ·ÅŞ¶¬b·¨kØÆ`‹Ã¼Ëœ!/–û.2ÿ-lŸMqÕÃ¿šİ?ÓÀ]3Š(Z+º‰·f´{Ä´•¹ĞoN	âçÿ—–i#<0=øºYÑÂïö»_üq†	—#ü!-÷©4NŒjÌK$…Ä\=­ÄQ fà7RêJvLÓb9¯l&’< §ÔÏ¡
Æ´èğ(§G«I’¾bÑó7¹8ÌÀŞş ÙÀ‰%›Ó?,õüè³H«I:[U58°ëª‹&³òs«JÉÈ¤—`È/'Şf€åùÄğéu¾>ÂceM=ñ<`—p ï¾l38œÃyã!F‡H`ò¿½n¿ÍJTÎ”Qï®jh¬­Ÿ?T©KWÊŞ1jRÛ&ô‡_b Et	ûHVf¸Wæ‰ˆ¿õòÜ
ÀOeèxĞ¼mÔD,‰>ƒé{àÒ½œ÷¹NI(Ö¢îäB»¹rş£pÿíÃKsfš_ƒãÔ‰ötÒÀîZ;{ó1æ>Šc­d·ˆR—ÿ}‘¦k—¤˜Ä¦zà±1|–Ü0EC=¸ó\øÍCâIù¥ISROÑ(œzne€ßéê¾P‰šÁf…÷Áz3ªä­ ©¥£tt]¹.aœğ{¿âÃÁ’Ì©£	s¶j$ ó}¢	º_ à[#L§-OwLÄ­,>Âòÿ8miëmÙb$jjÎƒD	 ä¾»Åî‘€ ”ş™ûÊòÖ•%v'en{nÛgânVŠ]ÜHõ,“Îí¾ªCC*g±œ®7­.=Ñxã¯‹s%|–²1ãWè]é`¡F®ß‰I¥ÿ*äÉÃ8—›ÙÈÅÛV…ß!…µ›Õë»ŸÑ3Nõ„f4tJ`ŠÀ®Èİï†,No.” ÉdF´©&aJ ÊÃ¾œ1”Íà”¢qï *İ¦êËÍ3|‘4,PnAìc¤Úİ´·l“Ùûå6hÓ×¥oK×xÛ.ù~¯¸H€ˆÍ)ø&:6ÖZà¸4U(yZıJÎSOu %ß'ñä'ã—;Õè„,å{Vtv÷”ş'~KIÒò`@œ‹Y|î“Î¡"©gÓc©^/§"ÕEŞöË,»*NI9£AË½üÊ•Dï-;";{Øgó¸î£ß£xQU~ùt/LCDLc'rš”Ü1{Ê”ƒPŞÍøk&û¶ZØó"WtÈ¥ºÿ\¦õÕIgx²öOl¨\pädüı¤Jí°”	6<×¥gÆ–VHóò0£ïÒùÑ·ŒgÊèõwb±s¬ëêŒŞÌnâ8‰c9'ô­Àr˜èÑt6dâ{R9³”ÿqdù“2”\Ü­he¦ï
/XôH5?ıüt–Î½Ÿ¶ŠÓà©]OêÇS›P¦’³ÔöC¼=”ä$ ?)(»Ha£UYÔÆ¡	¿+»Ø%»nËš`Æ¼hş&’3\?è4ãÎd®^™Õ‰/ˆımú)M†Ïv›1rØƒ”²2C%ç~î…”âUşUÃÈç<çvé¤’w’©Mz|\¤$z|»°Ät(Ööx^ê&|7Á°†¼aˆ&ÎrF­Sìõ·Ö™İlŞ¿V“wûyOŞjfM÷Ø9«¬Pë’?ßŒÖØe²Ğ%ÌöÎ©RumİR6ŒŠÕjo© ç‘bäv©KÆùn-¾Xú ›“d²øI£	g¹¶[‚*Ş“(Z¹ ãpv^ïFËÙÖ›÷·ÿ4•A$&Ìo‡!5´CÂl©›©Õâ<ª¯B#åzi;Yè¼è$)M'x3fìXQ4…êKÓ¦Ì^ÿ¸ÎÕQı*ü£ÄŞGÒò˜à÷¦¸öp;º¨ xjE!)êë}„Âä‹kÍyOÖ^‹~6p› |A
“§/e»òvÄ“{@dk1—e8sF‹yQÿ\Ë;OhÌ-5ÄàB;«tt9“Š4‹wØ–İ(í(ªSş1âzVU.óÍ_L®y >F³†+×â4iø%³Y7’ôöÔß…Sì‰m©89úß*‚	$µz½Ù¡å~ã+X<‹5!ÓGOt((øÃÅ‰ù=p¯2ØDÙöğ{BU÷Md\êÁ|Õw•}ø¥èÂİ
‹ Y:ˆº³Î–SgÄÍ}¢¬´(‡ım0¦ÎtÊH®º^ÑSÅ-2³¡í,3£éQÅÀ·×Él²ªÖÆ}hÿz°n%QıvŞåvıX2q9ğ~÷Oå6è¦ I¡EŒôé7½§}a½h¢õé`ğÔ¶]êEûŠ<¿ -†©år@GÓ²¿s ‰–ÂÄ­¾yüríÖ 
Wsº¸ïü•Œ†/iJv<
¶
yh”]¸9øxÀ>y¦Xı·ğï¢»ÔfêiµlPş"œ6Š|âi&ŠQQDĞƒfé’Š²"Ó qcL$wp ç,#Q¶t(z«ú¯)AÈoÌsó*õƒMÂí{€Í+±F†íá[;X.€y<N—.="Vá§WY%Ğè£EÚëìò$c¼>¹£LÖ]B|å7Æ·óB‹o	©è²ŞQa^/OsªL	n!J¦Â;äVŞ9“yöwÓ·¹²²íZÏ„}Z’v«RÏ Êv?rcù#:ç;V…ËóaÅÚ(—– ™óCÂÌ³AfÉ
bNó[×©éG`¾Lş•½ íÌ5áÖ”Ù“WWğ{
‡ÅDÅş¯ÒËL°óR,Å®ïLäÂ«´§,?‚p¦U¾eŸiŠ°3ãYuÆ¡¦`›$Àïmh;Ò¸9ğáy|üz‡DÆZÎ¤§ã‡Ö¢I°lvK›V—€z‹ª›‹SÓ†Ñ_à!À»,€¾<§ìö±¦İŒ|£WXi"¨¡5uâ²(Áa˜«Éå‘mpÁËI|1½ëÉ¹¥qª«âÎ[%iK’lò½°N•‘ÁwµUôE8Šô"èìÈ›—6a»d7áTÔÍZí½½ÌN˜5¼u[ù…Îbiº¸† ³ë5ÖFi0aİ*1Oÿ«câ–•ñö9SÿXËQ‡Õš/!à›Õo®Áà©‘rG»-1šùÌò‰…`²õ[•oÀxQ‚ùµ%?ŸÏÆg/G`Ş¹EØµéKi¥C$£?ìmš>€{[ D/ak¡.kòBWØ:=“‚Lğ\ÕaÚÉ-r2ÒÙ'QÅÅ©ŸÑÄÔM ¾#
×ó…å4S7×©SúˆÆŞ.şßOÆå½Wp×Ñ ‰F÷…¼<0bßSTï·,F´,kùÄ:A}âÂtÈöäë'—K4™Lz\úW+ÕIäËÁÆf¹ÑD‚ƒÚ1 #n=w¢$håØ»VÔ7¢6=¨Í–kİ€¿ÌßUy™ ºÕû>¾‚GaØJÌCw¤@)!.å0ÉuTÊÜº·Ñ›Ümöï–°“0 Û3:c°»È-ã•Ü</¿¹6†³A“MœÓ}›¨áD mŠLè§!‰”2*«à\ŠÏø3=tâŒ´j?e›GúY¥>wü,6Pµ	?f°ßª[²¥‰ ¤'c»³Æâ‰÷çHIñISHŞiÃ‹®gEgíUk“&ê°r*Æç¯Ï§‡'M­½_uk¥8ù:ı‹‘A}1÷.ê—RáÉÁdËLÕ_WeY×¥¶võØ¾DWG­ş}Èñ}ËÖ|d½Oô\¬r&0š@Í5ˆH¾î"?e_Dúp­ ³2X8XºFô)¸JP ıÓ +×„îøíÛœBƒ·šp2µv”]Üá%“ÉZN…›tà±uãøµ3½§‹a2òÕn-â3ªHÔHûNÎìBòà5|’İİ8»¹¥ë®Ó'g£°õÉï£bAöºÁü˜~_åİÒëòö8òĞß0òĞîòÛ8gWoÀÄ5@]øBhŞ_ŞzÁ/°¥¥PyûúËûğÆ°€~¿–²”iÎR·B½õ]c†š‰t‘{^fòÕõq(7×TJé½µ"B^‘IAtÄH›=ÿ¾qö+âßv³=ËZÒ«¯2xşG8«w™¿Ù»9G:Âdı"¢±XĞlÀã(J»)µõ´âĞ@U`æ£råÓ¸Èz!„K;W|Z¯D_Ü/ØDüÂ'pâ* ~q ÄI	™pÁRW[Š_ÎŒWVï¯[ûˆ¢> m©/^4Ï,à{ˆsÍÓá~Ğ¤ú'r’¤õÌ:m=ó,>Ó¤‚ª¢Æ6”èÇñÇÁØİH‚µé¾êƒ÷¶2Ë.4/¹7·HÓuì<[:×7ÑÌyF*É,^!4âÉ“¾B[ó#áªú]´¶%(¡È‰ß<ÔÈ|PsTÂŸûÊ;o7”—¹œÚË	w^©PV“h^$=—Èéòù|· óÅó„„a1m{h¨ªŒ‰ï³_ã%±KáïiÃØ†Eım*²ÂºQt²ö8İ—¹„ùqõ¿~á+µ¼¾ÆVôvÂû#dŸ³ÆamÂOUšN"%Šü¢^§IËşÕL*5ÇÊ~»Ïâşf¢¼8ûİù²vú.«¨"'-»TâîNäuEÀ§Wß¥š»±†ñpa]ù%hı‚â'fFOÒiÊ2QgıÜ!áÔ_U÷åĞj«Ì%ÃËÕÂd=–A¨ ôß…©X
éq—=H›1*•#-v±›Å‘ô{[=q/MyCZî3škUM™Ö5QI|â(Ÿf5òä£~ŒÆzqÖéÅ|³g>;HâúóñYzE¬ä|kf¼¡¾ã¸Ğ˜‚7ŸqNÀyíÜî; Bµõ­ÊÕb31Yú,'÷¤Wx\¡c´Ù¢a•ˆm\ã[äş(÷ÿ±Åsªã‚êüšnV,#QºÅÉU2wsr±r_Cÿl¨ıªµnæ‘¢¨{w=ÕQR“ ”‹Ûcæ!#™ÖÓnN3Ä‡¥Ô›Áü)}û1Õ’ÖzïÉ*,•2¹Oˆ•Á]‘\|A9`,Â]¨(v-Ë¬HJ ˜ ñ„¾ğZ Ì’”.°é)ãØd3-]ƒ‰NÔµŠ;@Ìî•€6í%ôvŸ×"Y¥„úÄv§íHgø‘Ê—â¶èlŠ@MÍÄ‰]É„×
2»_*¹ÓuòÅILÏ}Nµ*ûsäi«ë4ÃªŸG^Ë«±lß;*ZºÜºrŒÃÌ¨gñ[ù3˜aü€~HùKÑäA8(óVÙ§.bÙò9·Ó› ]R“^PÍ÷®„ä4;À¾rqWînƒI€]Jƒ6^­"¤¾«®•=?ÄÛKiX;ßä 1‰rÕPŒf¢lp’$WÁE÷sÈÌÉÌÊ ífnÚ6ƒ# bËg°„,¿ù·¤E¶UÈcßø0+`^›{v8&fp¸HCéíñ6bQày8`EÀÒúö_ÑŒ¢FÒ±
Xrßô Óö÷)ËÍÂe~’d^ŸwîÀ«–áõ,Œ­7'MaÕ‚5Ø,¿ÜSeÇ Zñ
b†ıÛM¨#çŒğŠïN*@D~uÛh–+pm*"´]’”™aô¿÷ œé1Ô^63ÂM-¸¿VÀúAıs'†V+ ¼e qpÜs§4d–¸Ã
Ø|23òreıRŠô¢¤N›UéÿÃsXƒj«“ş¦8Ä™~‹¦ÍåYæµg<`Xò|ğä€™q…9·i9ŒPªc¢¡2Ş
\1d]÷Ìyıš¨†°"ªø'@ëèótaÒg’µ~:çôCş°X‘ıŸ¦K§%}J‘YôRR† é-¾hÛi*‡øñ˜8er¤¯Ê=«L
^V{„6İLd	WÃÅ‡iËPôE¨$cKØ•5ıBı9DF:†õTdb›(·=aî¡Ñ°O!kòá*TgGp×ülè†~%_ùµzÒÑš)ô“ÜMƒÏ‹ı†H½æÎèßf,‚|-Š©üÍR‚Ê_µ*5ƒvµÌTnÇT[}î­[‡—'İHq%5¿Íÿö8«zW8w¿qKê>²p2—ÓªìIçÎ4êd®ÖÜg’C²Õn)*	¯ÿf[l„Ã³µÖËÓ¾ÒÓöËÆıà¶ó‰6tCÓ]q«ÂZ‚İ5y+ ±ÆDµ•fº˜…¤Î’@%Ã÷µt;Ú·|õyíö/Ä)ã^îƒû{fÜ]såÿ1ú+”_ù¿d-®X_¯eÇ½Ûà+/xÜ7>SÇŒ·~&[g„U»i!Nuù¹mÑæ‘Ô,R
Ì¦3‡ReAKe6É›û
í¬¡ıË”¨…^HÎy&³_Š’0ªó„|PB©çºe€\\À]…‡²
+ç¡¨­°m¥û –fäJPgpX›"0ÎÖ˜WœXm§˜G8,ÅZ.=Å²…¸{›9–3àJ$Jõ¸N;/@Òœù×pµsZŠjõDTÔÁHt‚W_í'u÷·#?EìYkwxSş¸â†qB;ºù–ÇAİÅŸPsè}ƒ~Ë7'»d4¢x&¼Ç ¸RdêŞÇ©¹`*ü±İRO´WÈiëDûñ7éÚ c­HhVÉ€¾Ğ<fw²ØşêÎ›9L.ÜÑáØ¨¡ªÓÂç‡Û&ğû¢ª±¹EĞPœJÇxîõ¤tLÚºóÌ‹‡¹K%%XQµHÙ«3ûË£™ËÅjï^áŠîN—Q%£oÉ#¹[Å†;QF}g€I~ã¤/Oé‹!]gºš·5™+G×V$¬¥××áİ¦¹Ş>â°r~Ám¢óÇqñá·ó†Î¡øXïÅ‘`DDP(l
ıYÈÏÎ·<Å2>S{Xé‡ïğ®S¬³İê¤Sã——VU…áp6µ¡I±ü#
høş-@oÛRŞ°å×5`í¼îNK}é±PÏy´õ¼K¹™(9ÚU–àŞYé»iN†“£,„&Ä©†÷b9ÊÜ‰åÈx¶Ç—›ô	}Í¯Ì.=Á“3aªnMx%m²€’nZ_¿ 4E$ô}–ó¬õíÛ<º"K”Kïäxu ÉÃc@(¾4¼§åì~B#·êÁ[ƒ ÎL{™Å‘œ¿Æ`\Ğ‹Æ#3D'Ô:²gôâÛ¿;×Cø·Rìı÷sˆh&{SE1ÖÇıP7‘Dñs€X¹]ôÚw˜6Zæ‹™¾±«WqÆ°­{¡`^p?½ í€"![„éĞ%m9uÃ:×1èĞf5-Eº<ÈEof9ówÖ¦$–”µèÑÔC9˜¡(1ô8µ”D_¢ú—¼%RÊu¦Â‚Sî;œ—°Ü†\*“ ´!Ö¶· ?ê0ÈÖ¨=î&Ü­wú>¼²Áıó<Ä¢¹‘jÆ6âíø›R(Ù"
!´²r²#jS–0øì,ı“3!ãG³ÜŒ&i8û£¨¦@"Ï•Äèe?–ïÍ§‘w&@*Í¢‚1·[âº^†±³C¬”bNœsÖ:àpç§bdÉ.@5ùíWaQl}À Ü½|©7‘yíAÉ¶YÈñ¸¤œ›Ò9î\ü7ò~·ÛMzz-Uk€#Q¹Y]&äÄÈo×²ÉÁïí>(Ÿ÷L±pÜuˆj…Á —LL7‡xEµ?>ÏkL<êÜë»±‹¨ó«Å±}yá5ÏÖ–â¥í6üKËÒ&:8w}åG¡ïÉn<IªTºfìMr>ä¤Uâ™êÊÛŒ’õá£‹m¤`É~	i}u‡¥GÜ{ÿY5î•jş€‰™’q?’3I,a¶rëë€KË”8Ñt‹(g ç0‹ˆ~Õ:À·'×ô#[üĞrLYe^Yó€)7Ô „±…>ğ9Õs&”_NÍ PŠºÂÓÑzî®Ò¢ °.^§®B³ö¿–%÷gg}yš.Å¶ É©èMhU½ ÌRô2ºÄøHÕRÏ‰ÕÒÂU¢~P¤şâæXi	¿lúx„5ëk]€QÌ ;l[–¨h¥ÈèËt¸‹Ji×íL
`ƒÉÿpttáLdB¸6yú–Øƒ\!&ó×±À˜¯Á4Ìå*`]}aİõÊØés)HÀO¾Õéßº¦«Rá•ÍtŠ
Èÿd`0ôØ]~yq¼˜\ÿ¼H^Ïvy¬’¶ì¾«Yv˜;¾wöNÄL¦°G­rq
1(<»·¯Èê9éƒüµ–ÀÙ'x,¼šÑTyø«–fëáíµÖ¶iüMjç» 4N.ëo|Ùö,â!œ=XY/ÅzÿÊ^™ØC5…ËƒYÍ{™êÇ=B
êo¨|°Hv°ˆi/â´±óíÖÿ¬óñÈ—@À ìJh(ôvñ@.vı'ÿX}±òD,,E„@~³Ìñ×JìÓ0më%Õ¡+FÿK˜xİ3áVVá¼½ßj ~íXøõ*úï±Š »ı·m^ßÿi	'hÄPpbK)O@*Äu?:s¥¬«´>>ÛB:dzC“@`ÓãfcoÑ—+›üµ ô4rĞc&­Caß»©|ƒ&ØãíŸeŒÑÛ«ÔÓ€z$+&1Ró”ÎÅ³W¸1…‚IöwJ şfÖ¾¯T„÷è÷»ª¿¦şw„¥ŞÏ™{OpFnSqü€fhş}1Mp Š÷œm|-Ør:§³Nš¼‚ç:)àĞ¼×a
‚R¼3p3.âv‡3]‰Fu®í-"¤Æq­  B)ô¤AGXjXmd&š‹šm“—TGÊâ'bER»ÎÇ:´»áÑ˜âtëxq ¶ÿƒ?Á¢ÒŒœ5)MàÒÒÁô[£pÏÊùŞtø]$æqKèt÷6¤M*º=~7~êÔ§=ÄÙ³'Ğ]¡˜Â8¾µ¦'k¬NP’vT 8¬ªLkFÙt“‹C´ZK‡Rm–ÑBı0X ÅSD¹åÒ•¨
^uéCe2aåFñ“•XÓ?Ú¤Œî‰’²ğR2º¨‚V~3xúVöJ	äÊÅ{Ñş"ÁxŞ¾ø2ÅË«qÆ©YR”´le[yÇ~©­%¯…¦v…¤Ş-t À"rmõE÷RW+"EtÉPÚQnäèKkJòx4¶ÆlVåÖ‚6„d‹åÛ9À˜`ÒõÜîé”™jb2 F‰ËøC‡éI¥Ÿxã	Ùˆÿ™÷ıµ1Ô	«E£ĞÛŠ€× ĞÉIÇ¦ëæOàÕÊTvñŒ[´Ølvˆó*XTa*!åuâz†sxã¬Cg»ÃÊØTôÆùB%OıëÏ¤Rı1D;ªúV]O«¿¾®ïö}Õ`k64ìŸESàõKw+ç¾`àÊ‹ |•Œõ_şøf«œK·+Ò’ŞóßÃ×…˜)7ów9i}P|Ò¤y‘…¦€Á)›«ÿ§½Â¶¼<O&¯½R¾¤¥é­ïä‚Øpùx¸o2|Yx“´ç¸¹q„™åÑ±îL»
Ôì(êÿcn¸·1„2Ó¢BÛGãşk˜“0–™Ä¨°)Â¦4<ğÊ‡ñÍ’#ûS×ùG.äÕıw×Xöİ§7ñã[t£8œ?áÁÒê´,2é¶1Üi³9QzkaN8ŸÓ—n<ñä×·Œ¿à¤+2×5ßvb5‘5BÛ¯s¨Ï›zW
bPcõüû ¨´ãZxJª!ŞÓzÚíÉé9Í´ÿO8‘èBÈ/7Z8ì×Ë´+Ñg†ÒT€=pèc”&µÀéıSùÊ8Lóê½ÖxÏ‡ñkØ&úë³ Û½—3TQõLÀ#w2.l¸"±
C_:‹¤şï„Kl¤®ÍŠ"0ÈŞa…êóáÒ¶ãšEjzJ¸ä‰â„¤À€ñúÌÓô¬ğ'â÷Lb§Jgñ„	*Q¿ğX6÷8-XõægüÏ	Çåh¤æ:PG¼kÕ\³n2_FQKo‡ô>BB ¼È8	«‰uìáwôˆÈí£¡>W«{vtä);–†Zj§QIè'P¥Ë·ƒT›e­»]|½09$Ş¬›Á£’[••9h¸¸ğ¹¡˜.-À×Ñ‰ Ûƒ¼á":²7â%_Ğ;ŒÔÿ”¶í/}LùEKç­ôkG•y‰ƒ/ôò_šfØërôµo} LÑoÛõm£ÑÃÓ/sˆ:
vĞÇãÓ<T9–îrò¸ö³ŠDu5Ó×yÚ'¬â¬òêÈIÒÄ^èM‹ÊëKµ>9ˆ¨ŞğÊz+á6L´{ ëã¾Æ^jsNK'/™‚¶ä.ClÆD¨Ú4–E½¤VZ€ïC[¸Ñ¯y"ZMDw„ôI´—'°‡?P'vU=Ò-xDn Ìƒ@gDÙé¡-7;záúHğhõ`U´ $>^ˆ¨[X,7ñ©jÂÌyø1v=‡{ÎÀÈ¦Áe/lñ•”%¯u´8/…ÓG|i‡2cÿ¼]vcû(ÖìÏ;µÁ®±éô€‰qå÷v#ò‡¡,Õükk«ŞB}±k¾Ö„Ò.ß®kuF¶ÔáB4­%Èã]¦ü¾iÎEÁ†E1ÒU[á;Ÿı¹gèqTé=³WÖq…4éXHA¹”eØÆpŒñ0ph«4,lbñú§HÍl³g¢Êš¼!ˆ‰§+3I§÷>²ü‘tß³¬ù‹%Ş½&áK¡½O%ŞWËé>EÏØ?¬­yf$¬nƒnXëEqIA•SìŸÃzk­'¯ÃV¿¶‘ìÅáÔ¨ŞÏ¯~4ª*bq.´†ÙÃÏ>=Ès9îõAéWİ[‡e~![0iš²øa|,£¦=wÆáQy)ÍœŠÅ›bÌíZÏb«Qï»`‰€V³Ã¡(L¢qª"HÃùÏ3Pâ€h÷÷ÏÃëA\ªš§aŞ½ˆ Ø 3â[ÕYw‘ÊwñFQ“÷gJöŠï++Â×<à„Pãt>d¦~ç¤×
Ç^JXåŠÀ…à"îjtÿöì(d‹&%$½‰}HVoÈi®ÉÛIœTÖéZÜrSĞŒ;œWIßş”½l M*vÔ:[µ‘MÊÜ@w|½ó—Y,Ï‚Y_‘îlh—Ì=µnÎÏ>ˆğÁ“®&ÿ·ôpª7îyåß½æ¨KÏ,RÀDÁÊ!hjjwKdW®§+}
~EGVå¥c^êUÇ88t†;æ‘@*ÖÆ“LÇòì5™—1€½Ã´IL^³î`½„GC,QúË0°è6¹LÂ$k(qá¼ºT¹¹”Gm5ë~(¥e™jáÖŠxiòE* =KÁRlÃÖKé¹ç[=~ÕS^­rÖ‰ Nv!ÑgÑ˜˜#†Èÿïs!Á˜(vÍBt?[ÒµŸ£ß,jsæ H¼íóp1µÉí‰üÙQG–ÒÒød:3#ßÔCÿø*$ŸçÁ“%£:ğÒ,À[u²Q@”]>‘ææq—âŠ§‡ô°È&øÇàæåÇ±IâM;ÒÖBÄ·¥‚ó›aLû^õ_t­²8B°ºÖß^ä¦IÚ»û •˜}I´Õæeéu„î*ûQÍ]¶ƒx^',ãz—¦#ñÑ1û?Û«úv™1`lŸµÛ”l-€ÕD"Æ:0ô¦Ğ½÷Ç*Ôóà÷ß¾‹JŸ¯PÃn­­¼´Gµú~â$)ÄXSOl§/©(\Ô/qÒGÀòƒ~Uuk¨Û$ÿº}'¯ÛPûÙÔ¤–îuÊ{ÏãoTOÀ¼k²?ØŒåç\,(k[C#)”s„bÜ	v9ÉSâ¼¾ŠŠüµ İŞ©vã~Õ§ÿş–ÔÛÊfİPïğ/
uÊƒ$YÍÓF²ûÕíå6§9;\úÿ„A0Íº® >x0UøTd·#e7	ÓC{½xQ$Ïšì[‚¿)0÷s«‰AËbÖ(3R4•#‘Õ¨”5`OÄÒVB]Ìï#K€??9©Äçá BSÑZWNÌ:‡ÅcRF°Ê;Xë&.ÎğÓî¨Î<‰üêìHÃÂäb°z„Î¿â·ùe]*ÿi ·îÕJ/Ï¹Zr.ŠUçìÖş~ƒ­Z\Wu‡ˆÜ”6=s`{vlJ¼-jåùğ%" !ö"`_?êõn~~ñ#]³àÏµDĞ‹™¤WØçÿ…ÎG(úÆºX„–a¯2=Iù³U÷WªùWÏÈ	 wïaãYŸ( cGòƒÍ4¦Sâ¢nĞÚH£ò'—’íÆ0¼(ıÙ¢¬=–×îœ8Cùì8/
€b"GAZ‡ÀK1Ép|NUÊáJãµ¤½ÉÛM¤–?ÚïÆpíòV`¿ƒñ\`$|}E;¿ºğ65ËPø¿ÈÂ…I×~Ô‘2Í÷¼ªŒ M•o²,|Û†tÖ~‡iYşlÖ#z;¾kR ¡ç¥Ï|aI™“×­õİØù%)<jò—ÍQ9XRŠšéØÒ¹S	?\'_m5éŸ¦æÇO!½N 2K¡,ÇÅ…w™!C34‚6­yÜy¬ÿF|ô¨q
ïÿş± -PèíòÎC_ëî-7#nx¹¬Åã³”ê¶ÀÔ)/Ä¿İíO;«·&®ë>¶ Y\fGİq–„Ns®Á‚†Q;V€m¾ªa™<lĞw:ègx:Á¢f„[ÿğÆY½¡(šŠXÕÆˆÜÌÙîâÄƒGöºuİÿõ”qú]¨iâ.Hsp&"×¹‘”]ÎÆcÙâ?÷Úê3ôrĞxì8½4Œ(é	–3æì¬öĞ7‡üŸ6!~ZòóxëüÎøôÓ-dÍ¡]µMÇ1QGãˆ‰ƒµ!FÏ‡Lš çïáÕÉUZßn\˜¦·T’ØE|9ÉgÆ­¦âÇ\ê.œÂ×¹É'(~/1ÛÄÑÑ¹«×@dØQg`KPe¤¿YZÿªû0‰¸óĞeu7§Æ†0#j¯çxS
›j¤ZZ±L™›#>I–­hı{&d¸dÁ Â~,sHİåáR§tÎ<[Ú.Õ•1¹NS³ã<ã€®ÔÈ>Mpµ‘÷'- #•‘ÓW§?íW`˜‘¬„ìÑû¢V'ÒCbÄ3âQæ£Á9Ï_tO™RÜKÜ(ë}m/Ô
j¤1À‚*Q“•_dŞ„¸±ä×õa8&¤‹1PÜ¯(xÙh$nŠFÿ¶OáU
fñ„nü©dUŞW²¬/£Pµ@…ï–$kªÙÖ"Öä<³@W‡hz•Ç˜F˜|ÿ<’Â·”ÿF.EĞÿ¶è„dÌ§}tÏ\{{¤‹Ø¡¾Ù¦vÂ ·.æT”q5>’¥‡2J¤ƒÔ—ûG…üš
¢\ç‘šR™hI“q±6_ODÕÌôÎk°a¾=Ÿ—Å™v®@€ûL;€QÚg«¹ÁPÔûÒn&ä6“¶Ûíöv:)ËñyhÉòäö¹e³Q>wt%F=Ö ›‹€'<fláFÌà÷Ô¼Ìšñâ×î;Ø—>7Ú|K®yşĞtK Jü—¤nÔ¯òÕêè8g)#néRK2­}¦x±ß›Ëû×C‚YÓOë>¶¸°‹”öŒg­-„à”fãÃnjşOäú|Ì´"¼ŠîÔ±'7YfìPbMb‹?K·
6ıdå6y©Z£dn¥rš?[¡Ô‰hBš!fRîâÃ„°ÌéŸzÚ67¢,…óÚö(Õ{ü|Áƒa˜’]UA	Iì/{àP/Ÿöú¼^gVÿ£X!Whb«3â Ëc¸MšPU~_]/W…[K<%N]t£_/K+³Æû¦è|x¼õ[g©3£H®õv¥ö§M¯óYL‚>!¶éîå9¬(m+c<ËC9O®°Ê#^û¢cNév41ûî^ƒù¼9i¶ÈÙ‡jt®`x-ë¶-ÜÃ:˜TÙGò=õ€ƒÒE€—ôã ÈI³Wš”¹g –·;ä­…åP qcNıH»+Á¿FTô‹#’vÆ&Iâ²ƒ°3•B/l5³TOÀ!Çöäæ¶Ÿã¯(UòŸY¬Jò[ãH{‡M³¯F%T3ö†0[ry‰"¼hve8‘ı©ø`‹õë`ê7Ÿ—,L¬´'|I„ë^B&gßmÎk,}i}]0¢ÒCÌÆGôL0©íÁ#rB)ÅÖhÿÎ~¹^º‡WÒSø¢ø}JJ¨ıª£nƒ^ª0Íu±À²%‘b0[1£ü¦ß@8ó²¿ Œ‚cÍ,K›˜„Ïq!‹±GĞSm$ƒ-TX$§gË%çz‡aoóÑ ‘]ë¤Û?w¯/ˆ%iµ	È‡ç–±|. }èÔû¶´W”°Â=©TPÈú„[Ø­]g–‡PoX?DaF—qÃ0‰7õb+HlñÒ*{	}BFrTT\Wc¬QûÓäß¼î <şwévßNG;f²q;kéª×ı¬mLn^ĞÔ²k¿¿ìê4Q(â—tñà<F~Mô`"V,Š``&|°iTzJ…ìëşøL¦…àÜ¤Ã×›ĞE‚†îöBğÃ8¥bş©/I§¤€<³1f[¡Í‹ŒÏãèù|)°t•Œ)¬¬ÂM‹€µM‹ã²5­1»Cı r1÷>—ÌÃÿé¤z)"d×òÚÕê¿u$ğÅJ¿¬pDŒõ¤ÂÿıX*6t‰*·…¯JÀJ<g#ÎPpÀ x/>¾<3I$-úı¶°Réµ^¿zßi7kK3GÑŞ¥Ëw0»Î'Ô§o[„È(.˜YîŒ:xM]-ÌI"g:hp¤ c|ÚZ²‰„egıjtÌe
 iDÛs;Q]ñóßÍÅI",üVkéBp|­Mã2oë÷³Ö ÿ¬¹ß.Ú*ôñ]±@Û•;Xˆ6@5Í7’ß+($Gk*Ä¥›¨f\ù),ZXtŒ›¸·l5…¯ºÍ(á°Ê±Ğıb3T>Ú°ZùC•Í§•g™Ö#-×Ú š¹Áthk˜éAÇğ~”ï¾?%è0î®üÄC’ ı©Fu\KQãc10Ëc'¥6ö‘2é·D[:m~—1éñÛBKµEû\wp¹{”ÔX1±!V”§û?ä¤^VFñö+õ?Iœ‘2(f.8BÖ!‹–y@ä·—l`Î1©zÉ}CÒ>J!g‚©Lë¥Ç‰J~ŸäW·Ş<„Ÿ1¤Å /|ËŒ_ï‘àY—şuÿF!F¦3E?wrüs„.’¯Dq¥Q2uÚÊ;ñe&€oˆVÖço×³],gb²ï.ZİÊÆSÃâHƒ*™Ñ:ç-LGØÂ kï8:§#Pn|} äÏ·† f(™ÁØÏ­cSæ…Lš`@#4@ä£dr"´1'
‰W–w›ìñÌŒOîv.ùx6Ú\#ä×[@äşåaCDsPü}ÖÉ™ÍÃ{>8uàbêçB­/´ZQWñÛ‡·ömWÓåTKáuld ®¸XÙµãiJ•.csI	0‰ÏXZGP˜
8r>¥·s`öKî%ıÏ†Tpò¾ûE{•êÏMñ&ïĞ¬Ør¸	šĞV¡¸ip*jTÿÂğBµÓ'*ÉğÙCâµøG½fPxF°4³ÑŞ[£&t"Ê-NR8wd¥ŸÓ­ÒĞgaâI`rÊ2e¯`ïÓUC“=D¢ŞÖ¦|º`ï±ŸÒ×à+ÜtÌ
yÔÂãô!^¯ùŠq“œš	‡öáÛeqÉ3öŞ²¦÷‰œñS°Æ/ÖÍıšÎîø”MĞ dL*Õšö¬è şr×EŒs ²p#“×ÙÚŞ¸‹V¨ÀÆª´;¯ˆ÷ç‚¥qñ¯EËgãæãTŸ®¼Ş$›HãòÕàÄï#w±¦~?ëß1M²Á¸ÏÊ/x›ß™~Øë¥1¯bÅşÊë¬0|$:„…nÔ²ÒKi1Åı@¹;«-.XrNÑÁÙ“¡`±—ôBÂ	W—	-¥´Iìêp®©ê3Ú¥å¤›âì¨‡Õí
>	ÀşrÛ¤ô¶kvëÙìÍÓø/¹ôã<A4
OfcŠ¹V¯ ´f\Oê2­wá¥ËŞ
AÏêâÒ›eì5Ñg”È8¢8N%³***™XOœ˜Q"BğU?Ö¬z¸7SĞŞt‹ç ñk¡1¢©ä~ÁÀë;¬¹» .x¼…Ì0ÉÖ©Ê?Gà¦ŞŸ¾'¿V&Ş#çåHæD×kîaÒÀÅFİ½!óÍOÖêëâÏt¥éôWØXCgıe©)	gõÑT¥Û†ƒÖëg÷Öqfj7¾2¦_†‚´şZ}ñqáÜ¹‘o2"!¬1ááUËÏ_`¯ÉÔ¨ü¿ñŠ5F^zc^¼1|åÀĞ &(·ûÃyb`#.•?Äm‹ÉÛY#Ãù& ¿xú„ŸÇÍr]5ê¯‰-J<)ö])0&‘?ˆd±EØµšl²O|J¼ŒşôÙ!G'ƒ64
6şP)%c	é´¨b¹e*.Ø?ÆŞØkË›ØÏ‹Ë«’–w 0ò^ÄÇÌ»6gSæó]Æ|m¶
ß¨2Re1«ÔÁmæjåäe—ÑélÿµeÄ60ß<ê¸g7§½O¾µ´ˆ/Û‚ÑŠ Ó»mN±§ûÄÂ0‘ù?ç³0u>øÀ#(¥%Ü-C_bfr™ïJ¼ãÔÀ¿eÂí×Ôt	œn–šl	Yó
F*ŞAáPËGVÎHCEóÓÑ§jÓÊÔÇpl¢TB°˜İ`©áü9·KÔÈjŸåóCÃ´’šÎ–ä<ÇuÀKZùå—&ñdÀ6Ru’	OfÓ×
–]…÷¹Ñ¾ÑG«	·ËnøGµ½]Å¶óÏ9†oY4w!pˆá0ƒ®¢„¨Ûe&:~0Óù¦¯Üy*¾vC~Š'ö× wH0/á”ç¦ÄI˜C{CH(&‡Y˜YPN¤T‹—MÛ¿Ø&LgÖ=[rOçìì–…õŞù»—$\à>¸Q—CyÁ¿ë[’î¹«âşeH‚²*¼X×eŠí×‡ÿÂ"{% ±’Â£—„Md¢æ .=hÅNÅÆüõœG*)]@•t¤Â VLèİFuL@ÓpMÿFÔ—M‚¸Ğæ6A¢‘Â¹Ï{ñ=NgLDêÚgÖBÿáò+øÃ]¤J§^é–µù5œ"x?ÌÔ¢HºD¸¢ª¯L["C4„yhEB˜²Et’üËäÚkÕÏÚ-Ù­=ïôiÔ<ZbQyı"F¯IcÕ<àBéªNU=ƒƒÿd­ZSYH®°°s¿ğöåÚû_Êä2,Šû‰Àx¨[=æ|Ó~ÛaØ*¾éÍî*Áç¤ÌÛ	]½ö-!ì-o.#aTÎ±Ó?ÊçØúw4;O9ÁŒ.ß½'¬Åÿr±b^n¸6O:#n8¤Rà¬imK)è»{°+h¡ÚñÌàŒ÷$`õöCŞ	'‡úN™p6P{¿%Àº‚ ÕsÌfJ¯W&Â,»üĞ'o=zÕ™±KPg¿íÿĞ—å«Wòö¶1š
<wÅó\Õÿ|;xqF¿ü‡¿Æw8§İ¥¥QÀïOëğÈö U"{…ãnuYO2MV`SßM‰²g›Ë
ñ·¿=ãßQĞ5úë¨ª! #ÃL ‹À?ë#Wh;0«a»™WR™xn€kV5›ˆzÇ,Î,2P£zğQ>Æ2ÊÈ÷÷ã¨/Ì×º_F|Á£h¯¥SYm—”–!ÅN÷Á·p¤SŞNeÈâ?­$e°í?hÎ`€c“rjİ¹Î«jÑ3“eyu¸’cJŒ_’+ËG_Æ¹ˆ|@î|Ê¸âyÛzûõÚyx3è1'bOÊøèJıòàdÅÆî@‰Bwq½6hªŞ/\yğÕ¨¹-³¼™}%{PÎEèÊpÿ8›˜µ‰ûˆÌ‚OAŞ¼çy­y$0›&N*©ÓËAÏ"eÅ1“ıoiK¹KF?åì„8ÁÀ°«Œ{,nûÑ‰:†!¶[Ó®‹› Ç¹w µ9EOŠxËÉıò¶Yã)5uªÍŞî_ÄEm•‰°nÔw“ÑqÀ”Š±ĞÛ7jµĞA£$(«İ#õB3¤ I¯—7ËDœY°ÅVï¬",~·ÀOåˆi ŒÓúì5¤ÚT§‘‡ àëG„‹rW¶4\:Æs3ëõªÓÙŠß.Äk‚TU$)F sY³ĞUc‡WŞvgè3tò3ô\m6M
Hô\SÉK”¾Sr wT?7ÜÜ?ú7ß³¨f»«œ2æ ÑİÔ=Fe
˜\Ñ7V‡Kì>÷;oàô¼ú^˜àÙZ«ğ[…ú`	Ñx"ÚIÑUlÒÃYeTèƒÚ>3Ê«İ{Ş6Æpã‰¶Zjà½Ë¨áò¨VÑz°ş‡ ¸‡Q/ê¸9}Â8zj  ]›ƒ½³îÊ˜”m*2?Z;¼û×ğMQ³ì®Ş8)yt»[yPYêj#u…-‚ˆ=Z‚7›:_l¨”>¨"LpEúVª}˜÷½w2İgÍŠ<N‚ğp‹®3ßşx€lA=hc³_öc ~6ø­İ@¦Hrs£OÚşÑsó‹·Kâ×\‰³ä`ÛØ¸ÀÉ+3¯œRÓd>ˆIcç÷øöš¬ıbF7Ğ‚¥Šğoï©^VúİÍ¾EÓ0]xÍÄØÑ³Qì»²¦Q]RËCáÎ>0Šúì‹Çc’à¶ñ{¶˜	d¯ã®dÃUæV”ÇšSâƒ°hàŠÓxáD_³ÉÃº”5_#xWdg¬€2íC­ÎÛİ|òİÑå'èÒ0ûªÊnl`NÍi¥Wg¡Öå›/¢?ÄÀ iİ&{Š`SsüB~{}ıÇf$»Öè“"Î?	R–=bş('¨cRû-'ì‚ÑÿGQüÈ&ë¾5lÂ›%âùÛ;÷M€ QÆƒƒéè˜{£6!êÛ¼< e71æ¸€àH2ª;>i4c•¢ÆbÛ?5‡Ns1WıLÕ¤~ŸÍÜŠD£ŠÌ®"€áÔƒIòLo®{MÒ†È{Û|›C ĞğZn&<ŞÃIÍ”Ìó™£(x?$ß‡@
TÑM€³§‚Ä'pÎúNœËjB–·Ë‚ÿÌ]òCq/Ë	OVf:H¶`û4×w½E«¥?‘Y€Z÷~!‹V\Nm:é8}jE`ò UQÚõáKŸÌµr†IÂn•…Q¹Ã…İÅå`V¬™,,æNEí­7‘©HhÜénÃ# RëoÙÂ€6 ¡ñ½¢ïß,kn²³±¶Ró3HÊ³znéÉyá«ÍÅä&•GÂy.T¢…•€5ô³º^u¡®Î#9Ã„‚œ2šíe’GWS5ˆâ¢àÁWÍ…ŞxCK,kÜToş³ÓDü˜y÷¢tjèÿ¹Có¨ŒY¿{z}ÚRî¨ÖâÇM­ú0
]p/F½ôZsCÂCG)”®Q]ïÍ2ƒ“°ÌªÄƒŠ”‹ux¤<Ç«#]>¢:Ö•«—ÉIj¬ùÛ0d‘c)b.5O0&.V_éµ°´'«”õXÔj”ÃSµ1ßaÛ¤Ûòš=ñ…?vÏœ7ÒuÚ¿@®a)¯ƒÿ …L Vì\¬Tİ›Íj¢îçwÑ¥N7Ï¯†Jôü4•­;€–¬«®¹óQÃb$ºÛPOÓ[#¸&^Ì‚A%™RKQçÕ6˜'Üª´VÖ d˜%Á©NÄhØÍ…DQÅCEİ3—5E#ÜÊz†¤‘¾.Ïx\#šú*°¬Z<gOı#¿¾†÷MÍñÁ‰T›2éC2uN÷çÃ9„¶ï€‹ÁÔc35•y>uN¬ÎÒÄ§Äz°õ6üo˜EU>Ş@ 72íJÕ 6úÀ+¤=§qi:3–]û;•²7‡&¸š«ÈfcIlYÈ
Oî1 í¤8)g¯×ø¾¢	ØAß1_ÀÇ˜\ÚÇø‰T3qü’ÇO×®t¶ñš0Ş°baU{hò ¤h…ôÖ!ZÁzyUÛ„.ùwîr‹–&g½SiÌ-·P·Úä‡¿¯¼Ã-EÖØ¬è˜yUxVQÔ/›­
Ô‚ı_~4w[EÕ
#`ãJŒ6Ò:æ!&áp’Ç‘è¼œ@~¢µŸuŸCƒUkD.WÃ(¡{vşşÄÖelSl\ò¿|•=\ş»|Nš«ØS ~´ıÊ¿½õ?8TG Q§x $„[ÑÏú¥¨Kƒâ{ÕıÛƒ‹œA/}ÙËsÓWÂÔuObÑa1ˆûaà²ƒê,2hS`Œøù°w>HæbßFQšqN"ÔªÄ1wo&Re©5¶êĞœÁİ´'ü˜,ĞšÑ-å.PÒ‹3K:^† ¤£'³ñ=á¼¹¬PïÑañ¼ÎĞFt×õ|é‘aÃj­¨‰¦á=Ş³BGç—-UíBîÒL×îp ¯Ùa éàj3!)tÎkùÕŠëNÒ|5VÌ¡ 2bÆú”$l¡²Ü.XU¤Ê,ic°5¾sçÒn¸Aã-pP(âG:)ì`l?Ü‡	„Í¬£ACb;Ëj@—JLûÀ"9¯©À]j‚Ia›VšQäò‘w¸Î×İÄèìl  êçhÔRõuKà;jò*ğÕËoÇgŸìšÑáóƒë MÇŞÎ±ó3½•¨¾bˆØ-lÙ]*vñŠ•9ñÒwÆpİj#¡ù{<}§GÉ’/Õ¬š™ì$¦‹ggZ¬86ƒëéĞ•ÙaMÁø‡³ÔÖo,îÔñy‚ùÊÉê_Å¡uWÎ²
…÷ş‘Hs ¯õ ”2fÁíß!"âmX¸‰qsaRÅ(×ÆÊÀ4n{£]>@)AØ±Ïñ®k2n"n>òÇÊÑ;½vÙ¼ÂïÎÔ:ÇÁÅ°´;!ŸE™R«àâ#Q~„°!<JVÚî”*ïWÈ÷åî–ûªB¡0Û½·Ç7İ9T±€é¯ÛÆjOâÔˆÁ6wˆ¬p“Ë3¥H—%ş+IGáı}Œš,%®—›”C·Ò½^¥Ò9cT/ˆ`C±(2t9Â‚/x’¨&UÑï¬x¢LK’iÒã9<-¼ØCÛÄ2Y/›6¿.í„©°ÚÕr×™ë»l3}Äœ–•—°?HÅ756°[==itbpE2XãÇˆí†_ŒDtè=|ÔuqL!-ğYŒÙıŸßÚÒùÀF* RFDIå8~¿‡OÎ½ØL²²Z·=ÃHÎôÆ¬#ë•\L§' ĞÎ·âØ“Eh¢Ñ–jZ£iìèÕ6€Ó¶Yõa?€æÔ¹¤íNW²UJœß §ôOœMIö.=÷ç<dòºçÚ	0sRÀå‹U¤ÏŞœ…ğZƒè•ÇÌvi p
í{ªİûNÌµâÅ5şáab†…ÑjDGjWKÌÍò”nHuEuéª}Å§·„BdéıB/©rù¼'!ƒĞ€ ¸A‚"¯«AdúŠöÕÊŠÎbN8€ö‚\È,ÙË'ÃwFÿ¤¿Rq_R8Á|ÍÎã@@¶ŒHA±Ş1*ÇeÃÁä—ı6ä~åØÙ"t(0ñÍ:nçqáˆmBCG¶<AÕØpªİd‰‡#“¯˜¯åIÎÕ?ËJ¨wG§@…Š¤ÄÌEÈ3åxY tq”~8õÃ•Œ˜Às4† !SZ>ÎîÕ&œ1(İˆ¨™¥ÄŒRU¾–ìøXeé7¦DgáˆÅs–m ‘á€`F>H¥ÆT§wÖS“Iåf#³hì”­n3zT/ÍÑôè¶m -3KfXWÑˆEÏ-u÷°0Ïú-Ÿ‰Ÿòf¥'± B%s	ùsğ#ßŠİ6<ƒŸmqç1#$Xf^b•œÒyi‚Â›šºÂŞt‘Â'³ÓuÒûU Sf÷ñ›Í‹éI„×W¾iuºÜ&ìØi.e3ÒìàV§.`ÑM,&³,EÑ@˜ä@’Wqq¸ÿä¥s(…¤;¸öµá¨]?/!³Ù¢gî¿“ÜÍuR?²ÚTÑV¼ú
N?O9ÓZvŸÚ@íR‘"3j_¼E`‹m–•è”ÁXk†uòT(/.ë,ä†º5)ñÅ€©å•5F¥°9İ¿‘’@9Å¬şÄ¤àLç‹\Q´GæÏ.fH[TXÂoêÀÖ	{ÖZ	4œ ¹ƒ½Z²X¾f#HØDànTáU ÏnáTÌŸÂ§uÙ`íÏ?™·¹ëE,
;ÌÉx™æZ¬%YÕ<z0Q hg€Â\œµe™OÁ%ªÄj…QL"Ã[˜î¥W §]«–@bÜŠBÈµÏ¿’•'­ãçóêÃW´¾üÀ=_ÕwnXp4QZ÷? by z¬"°Ùaz.+9¸õğ‰Ş£"…£<šÈüêÊ¤‹fµS#c9f;/¦qºÑöècîå-ÓPR3>m¶õúŠÔ³Û„QÙF·½B‡afo"(ïb6zÖjHéc	+~ÒÔî}p'Ãv>N‚.¬Âo³¦İ,wvCNdÉŠl9GZ>ía§Íiª
Léß˜rúb](ƒ’ÌÕ£¸‹øˆTğ¥öI<˜	ˆÈyo{¯ª‡‘É@·e¡ÔWƒ†´æŸ¢Ç!T]ˆÍVĞR‹úKKZò›Yä†
ûü áfÖ– ±3÷>¶'â6ãĞÈá¹‚ÆpèßçX‰±¨÷Ö¸M²CĞû§ÔSä%ˆq>ùÑ™ñ­-œÓÀ’€¹8@Îgõjı=çrÈ÷°Šè^òNE;´âÚ70ª!Û³Æø4{zR¢øÛVİdûï›Je$é9a‹¸ç©æ:EìÄ§3ÊRŞdûÕ5É¬DQíd­¨†…s³‘ŠŞK-çÁ¦2ÁpÖúµØu2Øûè—x	ÿ<ú!¬<?}’¦œñ((Û.â$Ë†»™µv¤¦ºİĞ	v]FÿZö˜«S´åYÊ›¼ Ş´Îµç˜Db]Ÿ§ëuQoD”Ñ€‹İ^x®÷l„“úUpT=ğÔi`ü\¹?Is-	\„ÑóEM×a@ˆgDA'Ö@Ü…Ïü ×ß$¾…t†ùpÿP"îµ€| €¢ïÁR«?	ÿíü(úÀ4 VæÀ({0ÇĞÃi¬(’ÙTL”ø 9nVÄ(b\g´`î¿%»ãÙĞ
&ğnNE=ƒBtL+~œq—Ve›ÍĞö-qzï½D²G‚p3Ìiå¨ÿFİ6ÿâc¶a»Ìó‘º´ç¹y¢(ğ¸ì	o T8¼@.ÎâçYrIw ¾ÊàÑEÚĞüMoò'óÀ
FM%U8ù-ÜC9k¯íÛÌè„Ï.xÄ`Ï‡X.PÉÉp6Ù _ÀÈÖ 1‹‚Ôö—Jx¡nâã™:óqB•Œr;Âè·I÷®Uó¢4jİ«U¦6"â(§w¢C?ğõÖBÁ„ÏU— D5k¸‚—B®ÑêAÿ+ßè£¤¹ÆdŠtº½;¶–ˆèÇa§PÔY¸/ë}’L2íw§X Sœ›O°!!ñÎõRü2·ZD¹2gmXáÜ½E2dÖàRW(o¾S²Õg	4¾y¶æw÷@'ÅõÙÇÓ×jeÊ_"_'tÆ$Ï!Ëj¦Ïäş¢íê¢çñğÛòQ²#ÍfËX(®9I#[¹Ê©vİÔéØqSIOM¼  ´~³\Ğy ä¸€À”ğ b±Ägû    YZ