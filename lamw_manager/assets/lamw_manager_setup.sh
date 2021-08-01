#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2027396103"
MD5="0d29acdcf118dc431643bd480cf035c0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23400"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sun Aug  1 03:28:35 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[%] ¼}•À1Dd]‡Á›PætİDõ¸fyØB0şù%ğË ç­ã‹±
-y€®şz;§ä›dOÏi°Cßù1j8lZ ˜¶½k6_ı¯@K!è=JP@F0‡GèU±ÌÖğßÈ	&F³Š¾˜%÷$Î*í[uëbeyr‰aZv?G@äØ±N½÷‹4# nï§ÕØ^J?°ç5;İöïKõ:
3Àà=ÀH¾É
oGÿkw¹ÔtÒ$ÿ¡…„FO°İq™ô•ú
ä	Û:õ·Æë_	i+*¬¥i–qppã6='ä“‚K®;;+˜
_Ÿ­áÅWàpâì?7–¾<ÿ¼L^¡oqÎKX‹3Ì!)››$)Ù»İ‹Ï\1&ùYÃ¶VS¿;á!ˆv8E¦Šn<©ÅšFûÒşb}{¿õE«ß¿2ƒáÉÒÛ­LoÅ—bdÅ‰’!†µ×0CÙ_f£¨àË°8Óñ¸Şè÷Åƒ¨…É¶àDY-»`¿-D!ÅT^S.³Èº“Œé®¾6L,¨ƒÔ2Ùº‡Ã(óóu!Ñ™S]¡†¡ô_n©O]9òU]‡óşµVµ%ÉT2ÙÛØ¦¹LQé‘6³¢<ÈFNæªò7(ë²ÁTù.OæÜ™âÃ8v¦>G‹‡(svmè³ì— U»¼Æ[GJ5•“-+=8„·C•Íaãı¹ª¢z(bYSæ@½sÙ1£œIĞ^=j_Rf¢Vü%GÃ.­›ntÀ¼L‹ï¼ûaE@iâHI(†eÉUŠñU\m©òÆ‰™¿½İEs¨Ü#ÍQöå©bìãñqVáPİ“ç=ğ]7,T±6Gş°Ôæ=‘ñ×Ş!t¢ËİgeÌï<A+$<á *)	%iÛ·Ü«ÜŒ/Ãå¦eÏ¦çEŸNm§’¡Ó¿-«²à5Œ©	#^€ì¦ÃÛN	•r¿Æ·ÜUŸĞÂ³/5D¿Üv˜M3àp•@µ¬üX{!¿R(áŞb…À;IƒbÎ É¨U›÷g X“Ê±Y?º›çÈ¨½ŸŒQywûlö9LaéÉç\$-¢—p,Ãp'wÓ+¦´!ãÄ4ÏE!·À÷H«Şõ“góY9,ÒŒ÷dõ‚p‘~}Ç¸y)áŸ˜÷êy*ƒ&<›L‚(û6€„¯Óc)ÃÈB6Æ/ÓI8!‚ZÔ¿GÁ3ÂÌìuo1MÄæÆW)FY¸ÈÕg¾Ôjõ—W³,Åİ†-ÔIh¤Ì%4¨›-zÓÕ
¦XöUhMÂÁ5……já.më,Dr h‘h ¾³UÈÍßµú€\2ÿ—ëË8X{F<UñĞ†i6yl|À{ˆrCó‘‡‘÷¶-Ze«úÎŸá—h}‚Sd†­|‘§PG!J?qqõË®PÑ¦yÕ¹N?±Š”pÈFë‹GO•in5±%È>Â¾Îê¼¼é”Ñ^GíëıV™TçÄ9n6åå&8¹Î‡ş6ÖAe°£ÜÕÎ—Í]>Æ÷äv²É'=Y„<&ÂíµdrÎN§àO»p¸³÷Á!4á`‡ã>;Ì ÙR¡çc£kI3Ğ©NıÇg@İĞüÏºœŞ—d§1ß®’(ß±=Çëˆ €!–¹<>û
ò®,ñ®1oàåkBöÎ½‘ò­´+y$úŠpğGrˆaäÉ¹-ÍÛÁˆ´Rmèßê+½Üiú)ùm;ÆÎ±„ûpI¬;»SD67M»2Å“éuô‘éÃõó”~±è	¢2i˜ÆGÇFl{æŠåF¿·(g­8ƒUÔÑß ğªÅÖW_µ0x¼\ÈÁâ$eVu’»Zúÿ»J;&;‘ËˆaöÉ|ÏÁİQ‘å3Mõ÷/äf!{éßWœª­…ñŒ^·ù¹ëºØ˜‡»’Iû˜Ï$_œÂë£ÜúØÆ3±E Ásòk™ßüÎ>ÉQ¿¼ ’Èïk‰EW&Ã£à‰Ê¤½'_é ö]à4%™Ü~ŞÉ´476®õHj0Ê$øMé–{¥<2¾CeÑw¯.PÁ£aï¢!¯tÊô†oål×ğÒfk)£¹¢ƒ².ˆ&§è’­AgöóÒ¡Ï!ÏX:’±yĞÈ:Cß)ïx¹‹âXGªı.Õnçv›ø:{*¸U+W‰=ƒâÖ­PO¶ö5	”Ÿ!Lñêÿ6ì‹ãÕø²Ïl“CÉËåçü†+ mÓ*¸ÊDBïÇ$…?úY¾6ºö.Z€¼Ê…X2v”ÔHß£@!Ôw
©U`=~Öâ+JŒ¿äöxØO£d­ˆ@kvW:‡Ù!ã½ŒWÈu£I	}'5Æ«¿3*…pÀqÿ½†6nÕ…À^=‚„õ”`ŸJWöúy®!r¼¨
^f¥Âlv¬UùP‰‹¼³î¯aÄ‰4³×M9a7=Œ–‰R$ƒë¡ìÀç#ÏÑä·Ö÷r¬‚`\cå%ââÚâ¯‰¡ìî§ô±ÕÎ“^æi.Ñ$Z¥w”§¿ÎæFáâON&:Œ•HoŞğ–lÂmUongû¸OjMÀÜÛIqOÏ°÷®<éí€¯Ç\ÕÎ#bæ9[	çÌ¦Àšƒ×ÿ´Üµq—Í¿¿¬d {¢Æ6ÈäË¡¢‚S	ŞZ¾Ë¸|ÃI?ßK DËÊÁI?OÑñ¯«¬1òvT9GHÊ~Zueõ¡Ó¢FİÚÚªøLór/V8ÁOÏÀ;P‹ˆ”t\×ÊD açNK¯W2aFŠQ×ÿva)äCG}+DUQ’ëá3Üüº¡Ş³§Ÿ;}[Ó #¹L‰l©ÌÅîÈÅ-(¾KR(a1ÛÁ?DÔõ|	æN°]‹³¶%dï*™ˆië”rVà²!7"´IÜ±“ÉŒüDPäê'.‰À&'Ãçë/¡.e/ùKn±Lc\ÜJæ‰QkSß£BaÍ—¸”ïFi—³||æfš¼’ƒï]j›K#"ÉRºc0v`z™ÆªSÒM”Ò6³0c÷çMÈ÷:™Õ´çÀE<Ãa¯”ğ™iZø iª®UÄúø,ÀJcnÆæBØ‹`QÄQ×‰Şy,?Yk&JÀk!k‚j±‰ió%H‚şjĞ>a4ç”é¹³JÃ}\ ÙŒ¨Ï­r¼-A‘àì0¨ÁsJÈÎ&“(ŸK¼-Ša÷t-NvO%Ôö[ åÁˆŸ Uûû–ğ­;h|éQ{ªëÒĞı!mÈ]^Åx4c†¥B¨îÃíïsî¯!<K—‡Ò>á@rá woG—Š¢è¹O4*ª¸L¥“±È² ìVü7§.c…1b‚Ãíñæè˜6ò€”4¹F%1öÔo§3ò Úíğƒ2Õ M!¬Ì¯Q¸±`Â;EVİäã®L~¿)q0‚@eùÙ?â+SV÷/…ØÆ6š’M8ğ<óˆö¤½iCMş‚ÑCf’û£;	T™1¬_¿Y¹áÖ£lúM<ı
»²ş±qÊº=>Qı^àçşÓ”Ğiq¯šäÌf™Ô/
é©OïT ™l>–‰6«V—g¾şô*csôÚè!ú’¯ÄÙ±r(5y¬9èüª"ØÅ·u­Ôom»ö¯%í¢©+‹“Ÿ‡uŞí%İä„ßÂÔ“—W/_]DôxE:Ôk÷ µqŞ|fÿz§ÙVYµ§Í,ábYBeº×S4+ÔÌªV;_T¨g’DÏnSÊEH¼è®|vá¦g³d…c/˜Òİ‰û‰¤şîT”T­NŒ”¡ç§xS?ìê:`Èò‹XÄ±Ã°Î¬‡'eV·Cmš“^³¾¡%^ªhÕ*Û~F<Óÿ/jª‡")Ì*c_\ê±õ±z¯pŒĞz_áÏ|¸Ë¯|d“Vğ1É´_Gÿ†ÀP¢|Í+ß¬Í¢·xšÎL¦4ši÷®Ãñ›ûCÏ¹ƒsµCŸ²‘P‡îì&»Â uÑN*—'¿’àÉÀzéUL¬Í.ÿZ…	quå^ó\rÒ­‡s@.K©£’Õ{XñH«I-†¦@åéGaé÷İèÉEZ‹?)« s­F§šÄ‘Û‰Ş Q

$/ãÜ™Êñ¼8&´w›í(¬ûÿñ8•"O›bæCD”ÒC<U’6.è)/ÀiùÉèô}&ôàrÔªíÚ™Z÷íÓÿáÕèS¹ı‡€6;)ágät
ÏæVÿ¨*ò7 Oª¹¢üŠEnkVŸÉ(¶É.‚°!9yt­XQ'±büT+Q¼Üœ39 –²}”Ò|Nón6vÇ6&Á´ İÁê‹ê÷ûŸ™íÚÔ¸^èè,k«)f ?àXÆ:ZëZem\ÀŒØ«Çú§Ì¨,¢W9í+Fã‰F,0_æ³÷¸&VFä1f‡2— 9]”ÑgèS§±½üEÓƒ­c¨Ôõ­àÙe_ŠpRÿtçøŸB™ëVGoXQÒ1ö'dp³N˜‹$F!§lÙ0'ç>±°«À%
íÉ\ìâ	Ğ™‚ÍÎR ®•5Q4óÏİè<ş*©Å|NDx%Âx¤å;÷;˜<^ãq+pÇÄf]¸=á»Ëüİå¾o¨d<läÈ4¿‚¥¥Xz‹<…u¬¦Éãƒ›Jãáó3:[BZğĞ÷V÷÷9yÅùvõ§„nOqM-Deàx½QinuõbÙÓk" §¸!6jb~_CÔ9ÛúBJ¿o-&pO}»N'°ñ„×\è3Yd»ìˆ¯xˆubyëB.¨¦ˆbê"¦+ÿ˜„jø|ºò(yÛroŒ¨u]@ª¼¬Õ±Ô¿md€N3«ŒIç;qÁ)3¤óáÉ8ãùÕoeG'ôOXì™K^òşr¹¶’’ß˜…‡fĞr3s°!¾ş˜´·L™í h¹–€‘U8¡
¾*½–R»w•nùòÒ4Ù¿S–€ok±m±äà¯ì±(ÏœÆ›%ÒçÔ~´§zÓïß(lğîöıF¶Åø“ÉÿlW9d,Äöí‘`òe¤>–zå»æiqmé¡Uµ™Ü×À"’v|À…İ#cb@õÁMw‘™³5=¢<¸8÷4ˆûf\ƒLDpÊÊizG’D´^ ’¹UQf–ôoú¸ë˜¸ÆD¯	"ÜfÂñ`óÓİ$·nM¶Ík„qâ‘ôñ&µË˜ğşôsÅßüªDc^ß0î5rê‹tiŒ²GÚõ²	O`Q.°?}` XmjÀyV’1.º…ÕĞÁ=è¿¨<‘s.ËÖà”r#£\ââ.¯	ÒŠídZ‚z¤NdÛó•2&Š5ô"”Çuèä()YÜ*¯/t£|õÎ }…#'Y’õÕ¡ØĞcÇD‰/>$ÑsÒp6w¯0íÓãP@ëÉê¡g°t,\i|p¯Ö‚“ËKşfÃ”‘jÌc&6SdÈFƒ'f+§zş²× šË¥P±7ÖH\"Ñ ¶œ±˜5ün#nÄ1t~tıíê'ÃÜ(^õù7rùˆŠ+å™CçL˜Ì«?#›O„
"ùœÖÀ‚ö„t=²FQ¨¡ã®òïvÑ€‰½K(‚’ÛÆâ!±Ë„+èÜ]‚šá˜±‹ì®&
tì%vÎ¥P,T3ğ•»ÎÛ{n_ÅS|G¿4d¸kâo>8Ô?ëô¶Âşƒ£}Cb·(¯l¸–$ÚÌUfØ¥–C-æ¥ª)§•s|¤a‚-®Í ô¦ß×®´YQ’ØÔLHuõ nËÑ–S´o^É¬Èi2·æÏpÿ$OÒbº­ú§çô+SFq¸³
®îmË- 
<A'È%fàâô*Ê¶ÆÓ\©Š,öJrä¼WÂoV /Ÿù¶ò ¸¢~äPÜW ¢5„Ío†HCbRç8«ñ	eûĞ
ÅfÚ³¯]¬àK);+œnßÀĞLÆ?j ªêñ"#ÿÄïˆ–\EÒ§N]v0Å6D<-Ûm8_"Œmh}Ô#³›hÅMMç‘­üş3ÎŸœ^ŠÌ?ûGIyë-ÑX€tÏÍµÔ¼ÿoÙAA´Ü²®àDºg¨w÷Yv†ü0òBŒó„f× #	jèÎyxˆ°%ü29²ÉG²tE:‘ìƒÈãyg.Şƒ#‡3[%Vp‰Õè™º}§fòrèM†îzAÀ×æõ¦¯Ğ4ÓJR]ºí;z†ï<J¶…Ó<Û=Òkûe±«ø„Ébn?¼?:zrGàÌ™[¸«»xå0½Nw§±w÷}sÆ’ıİÓê{YVŒ!‡Õ·‚a¤uÏ£låíßúú¦w¾˜nš‡ä‰ß¿ühKGšƒâÿ˜#àJ£‰­·¥¡(;‘fÁs¡~õêªmü0_ÔíJ§ó€BÕ«fú|€z!¹Î©àSå¦ÃùùısÔ–&–PNøEñ‡²w|âmŸC+–=õ®6¨)c¡P˜!-¯âüÏ·ër»…'†qîÛÂZñ>¬cá’…e]½hâ"–ª-ÃéaysN™|ıH|ƒOT
“D ?ô§‹º*Ì`”€õl“‰IycˆIÓ§¤İég»ÙµÕŞÓ8>ŠJ5«+QÈ*[ßÈzI5V,ŒÈ¯+_¦9:B‘²ì«TlÂÅ8Â_•S›¸O0Í€³é î‹"0R´Óè7Yç³»’[6_–{8=EôGVy•`Ïõq(Kÿí6Ì~µ…Á÷™®O´K‹Ñ·¿ ğølÉÅCòLo'Ù³ª#ù şâ(Ñ¡Şâ²ÅÃÚÂ(¤ß<À_Ãç]å#Pı6¶±º¯IßöHÍ»ï$‚N[2}iióHJ¼ûè‡«²åÏ!ˆ PDUGíšÊ—-õôdv7ùÂÌu˜º°1âî,‰‘:Ç5æw’)¨sëª'mÙÓ$òé¯/ÉRîº¤ïnışÿù®2'õHmĞ,À‚6°¼ÒVµI¥ããÌ¥“tvö×éƒQçëŠ¯æjò¢¶¾­µBÙ6$48”•sXï’>g&¨JÑD°G:;¹OgŒ Œ&ÛS×Ùˆeqí¿!]+ÊI­ğxèÒÜr´ü®AO‰ó(&’YÚ—À6y–'-Oàs3$i2bÖòÛuıÿßÄ™xr›ì…%~É£CT¥[¶mfJ´èywÌ77d…@9ê·¤™IãWÙ7°•W#UzìW¡r
Ğ–rĞˆ`XÈxÇx‰‚NYXµ£›âì—9¹NÑ­v¤tp¡0‘©í2^»oF'=¬]dâeò‘,…'ØŠ
<2‰xN¡òr„ìÆÏÉ‘ŸØ%ˆöÅº'cä#¹„é¹l·+àèE¡#—n½şmù¥¶öª6¡˜|\{E¨ı•»4t¿2‚dğV€±è]P„úşHÕâÕQxï»äÚ{w‚âò	µ,ìÖ±³Qoè“;ÔÚâ±Ô¦7õM$€ô=Ò¹S«¨ºJ2¬ôKŠ¥èŒ³kSËëupÇ#ìšeÄ{3]¬¤8NÅH²ËØú¶ÌÔ+[ı)´¨‡³Ax‹I–ş2@¹bå;ÑÁ—„!Ô ÿä$ñ í,iÊãb`û_äÏ9ŒÜôusñ ±yá‹j7G*î‚À7œ8ÅHá¸jd’è0$ÊNÙŠºÇõf¯ĞË®ÆPWµ«,D%ç[ë”â:•ûRæ&¾öTĞÚqT+•²ùyhxWP'ÆÈ³£ hp3-×é‘£EãcöôK†6fÈ/:Ôñ¡4·­RAà@+ÑjPç‘ ˜ïÃ‡j€y"Ñ±T™ë™tm²ÅÀ5ê˜2r­Y°bv>ú¥\Uè¼‰Dİús.WÔR4ªYåŞÄâYåïÕri³ÕÁ¯	¦TuA5có0e:=Ïy˜`)'j¢Ôò;ì”¶˜a¾Œ–Ë‰×/T4—¤Û¶zI'¶ê'»mábº Éİ…^ÅìI´–å½gwmØ0ë§Rl_<C	˜Ö°ØçQ„‚4€³Â±èáñÇXÜÜ´û¬ê)fgß}…¢K”…Ì£ı'¨ «ÆšüòĞ·p½¯FoKIáê}—#C,nÕ³3‚»r)£9è&”Ÿ!°¥j¾7š·<ï^eÚ{Ñ«Ó9*â;ÔšÇ/um·“(Ìñ"v.§rcå³îZ•ËÊØB<< €íÌy4Üİ<T!Èş$üw‘5e\ipu¦f~»Š²	·ákÖÃ 9¸Bëù–ÿ'ÄøF"£šUb[
áÇ¹×™\şú5xä	ÇqE¦YzĞßy˜®CÒ`½cà\ññ‚V˜ôdùµ}ò»¯¹¸Üy¾ûBÄ—†íJaİR‹¿[—¾3ÚºR¦Ät&Vf”ıÇsÓŸİH6åwO"ØéÀÈx¨-¼lWToøÓˆ±YŸL08ª,¢µ’öz¢[å–zºG‹Ïu™¿û\úB3JXÓ

Btgw7Êv–+~ÆY{%æ.ÖP˜QvÎÇî¶Æ,Ÿ¡ûc¿ax"¾DgãÆÍÓañ‰q9<ƒ£iM8 ƒ‹:Ë
íÚybµ°^áŞÎµØ§u™ó[l%ş9ù¸¯g¿çœØÎ·x¬†@.³ÅäÈ¸Ä6Ô×—JÜÆT—v¦%zÔs%q— PÙ-u&Ôá5_xg•ü+–2 `EÎøiãøJAèñNğ×z.Š*ûéñ¹Â™›A 2ğŸ¾5/õœEK_•_¤ú[oöğ'ú†iÚùr†êf">AÀqÁ²¡GU0m›õŸ«)Ä­ª™”.¾U )®XD{¶´
qãlÎKèĞYˆŸÜ k”|~+æÃ¶špWIYM„—£ã'¶-1 ù—Â¿€¼tÁ€‰œ,04ğhà4Uq`$TÚKîe·—5í¾· îôµ¿2BæJŒ99”ó4"7æêÕü„jpbÚolÒxªì€Ão—c7úOï"V×»t'µõRtü*üì'¸Å¨— ¨z¨fÒËõQùißªxuxı½Ï¤¤p*Cv§Æ-|¬†î†ğZ‘uœ:{úôãLÒp' "Szw/›Ïğ0»M˜/˜$yç—	üi{¦u¼Z
ã‚:»\”Š*éèÒïìg‚â?aàÎ®â¿o)×ªŸD¥ü–(Õï¢ Ü%¸‰^Â.İgsPÚ¸rFDûwâ~V.	Om}<BŒåIãÎšûF;õ<  ‰®Ğj_•ímsm”!éµ'˜L±§6¼Òt5†T6³ô°òØh¥<;Şwš‚\k™x'”™ÔĞõ"®ÑĞ•\jöHxÙkD©xÎei“1!GNs2d£œÇ«óV„×qÏéÄ°ù"ô†Î_¨†*dõ6Ûi³ªsDfCÁMîí49/èÕ×lÀß­0Tç‹eÜlôs¼´cĞ_Ô:àC½•ªKÉé)BizU!ÁĞU
m4ªYêíQ“W8ùDK ¨©cÕ35¨r
ı€ÕÉfïìıªe*†¹’èSã %àUwél·?¹úœcîôi’ÜkaÄ´‘Q©á%Ï¹‡óÿ¥ÚLw2ò$*Ï~B1®„~ Rï¼^¹ƒö·f40MÙ»`ÇQ%é”=Ë’-Ì¼»U‹éÏ<Ü¯C÷™ü`Ÿ4…ó_ø+l?òâ*zìaå‹ã›qÃĞÀÚÚ½{ª~$ƒß-u6óÕe#³…¸ß…B•ê–MøÔ4DKÉ,–p:!”' s€óéfRôi–6wáòmÂÁ<øïÅy åu+şw†+¯ïı—:=ŒéÔÓd®^¦ ±©Ó—pÊ¯#”á:¸\X²NLÏf³6ª¤±¹'y¦02Iåûº \J4æbn@®]…pwh#òøóa%X«B¶Â€ˆ7˜ö‚B²¤k£ÅfÀô¸ÆtZuä~/ÓDE,3ôeMò'PL/“«?<åÜ·æÄ¶p˜96 {ê§¯6Ï"Øê;ÛJ¤áªû±Q¦~•ï×¹îO“`ø˜±ühÂ¸ï/ÉºKGæå†E\0 Õ·ğƒqT§É´ËÔh*7m:{%æÄÆkS@K¥ónI.]ìd†]‡DH ğ^–˜‘oTtİkÇûş5g”6I¥Ò9†Švcü‹ı£H/jº;k/¹Tv–­…5V>a-  k*É3®lxIm‚J.hXtÙÙú¤®}à€Ñb‰˜×|´ñz‹çÂk{-vüy0kÖÜà?ò !áfı’hFM2vÿ°™tÌq:o{o`å¡'>#bqãíËCà"©ÁVØwİºU:NèhÇDsg0sWsİªÏˆ6ƒ$~/°ï¹D’=¼:b/r¿æR®œà÷+Ä÷W Šs´xy’PÑºn¡ š÷¤§·®ÌÇ2ƒ™6K¾£â…ŞCÆç¿AÂÜ™ªĞc¶F}×APì^;ú\~<¼ M‚¯§¹á ó)§K)´1[Åı@;İÙk¼CZ÷ªÈ±8¼Y±ŒÁ˜®ÿàÃúPNzæSöyïù'±¸¥şòµÂvèµá¾LƒjÆJÉ½ú3·³dÆñ‰:ám›@-yK2¬1)OocßD³=$à-†JIÍ
aµ¦Ÿ­Õ[ï¡Œ"èÍ+ç¦¡Ù†ÇÒÍLrä°È$;)øì¬)¾·IŸ |Š¡h…V2¼9¹=:ã'(Ïu‹ùÉœq[½Íõ)ŞÑv°×½8A‹Òl*A-3®9†›$lhJˆêˆÒ©ŞG ;äŞ´…´«fõXÔdÒp‹y=Às˜ËrXç€ú;â£G`¸Cš‹+í×^Dx¼ŠE+Û¿ĞRKöÖŸÂUU—ˆöKà¢š;³´$So:(K¥*)ùòÁ,¦4O_À.îËeè
+¢âŒRÎ
VdäX!Ë›÷YÍùÄwÃ"(n|>ÿŒÒÿÁ¥e1æ(@»ƒm~P(|m®h‡'×»¾ğ­á…í¬ç6Ë|-´ÙO¸å·Z/”¥¦(RÄ¨FTæÓ;¹#šİ0-à õ¸¸“l\)Juµ¯%&©¸-&ıG±Ér¹µÏoCÊã%ƒ}ğ‘ÛİĞÈ×´tTËÖÕ`œØy4ÔYëÏ#µŞèß OâÀÖÅ~š!m+Ãttvì‚z ­óø3Eá¾LÅ›öEì5v#Ô]úœä‹¯öpû5M—ÅfÀkäØ(Ï¤‡ºè•Ğ‰ÉÕW—­Ü¥IÂ³çÕ:gı6 ³å-¬GJ5 ÿ·~—Zğ`+x…±w3Ì{­÷o©ğê~öhÇ:ëk¹†³
Zø·Î¢õ§6ÕïtiÓçæ-½¾qêÆ™e)»Öòc3Z½!E¹c¸á¬¬´e2¥S}ğY¼ø:òfQLN•Úı;FQ±]QYü•]%mß",ä Ä!“n/9kpZ#“nôM€È·±2õm%&nÅğ]«kÚ]vòş;œş#i8¡Ã· ¥ îî=?hA²CÿĞoc¨ 1×M\?Çâ_'ª2UÇ	aj˜†. •EäŒ¹µ*¦cep¤½÷Î²0ºe4rŠˆesØö	0³ Æ¸<àc¨ÏUy£€«õÚëüj‚m&;¦W4orÇoB˜2ÉEëq½Q1ÒØ×9!ú@4,ÿxÑò{I*Ó9
“_›”è°ïæ;Ç+5¹cå¼³Àà#W‘‰ØgQ[882ŒŠ¯ï‹õmÑ.Å½%K¯âŸr:	£V¿÷Ò™Q ì O5şı"ºÕi³UöÒŠFÖWğ¾­ÖpĞEİ Ëš*­ùAÜ—è/
¡Ùœî–˜Ò‡_ â*¾~}øÇ@:×ıÇ—È<Òfy¸fàFn¯ÎzZd|xğWœ •q^/vNÓ1|–äìJñæ“>0aø %‚´¹¤ÁX¡yÔa2ZáPs :Çı6ÀFcáro"tR]¤`ı¢`£ôßv~µ™‚–E“¦>ß;#dÙ›ôõyHàsß×š?Ò$–ˆÉ?]T\óD­ã¼øÀÓÍáIbÔ¤gGî åÅú¶Év´{æ!ì`êú4\«ÃGß<fù†½úc^Ó‹´¥ÑşMÆ,…Ò´«ç}~(|Êm›ÄkÏgëÖ<é]\Rå§T`™û›»…\$æJŒ«wœNMó}icĞtÂ/âm§ÿ!Î¦ƒÙ,ç4ñ	_XStˆlR“l?ÅvB}¹ë`²LĞ+M=dz":) ×%'±Ÿx.´Ùßc··†Íá1 ó˜Fš´•ş!»>f5z[M½™ıç×áØO.Oæ£Á…à{·GÅ˜÷G!%¦}ŞÈäÓH:Ò/úíw3î¥-aÅõÊ#&„D)>tåu-º]Z­ÆıÁ $4xŒÄ=jtLfÜRğƒZµB”ç«}ÈÒ£öü#ñ$fn€÷'Ò)ÏSAù—³ƒW Ù¤píF	%2ÚUìEéSfli›éL1c%OÒr—ä…MÙ#‘ÈxƒŒÓ:‘ë4}yíP¢­ÿñ«ÉßN‰Z{çË×¶P‡Qõ(Çr5"Î5çYÈßìbÚ×Pë~Ÿ˜à%¯éñQåBÇn2D* k%ÜŸóğ½OĞbÁ>¬iJ²×3^*6"3†çQªtõı±$pRP|éåtü7şê¯âÎ!…šAì!}#©6b.cÉØıæ ëV9Ğc%øÑms<©Ğ_1
¶E|¿èØïyÂ½#ĞáhUEâ>;ÿ1°İ£îw “”z8adUîŞ¢]_vk*’Öséº—‰Œ\ËÕš'ôƒƒÜ¦ß-‹ÆEû
Ó>Jä?ÿ	¿è´•–5Æ*¶I‰º~Txò:ô²>ÜÒ~óñÇÅ?Ìc$òƒì‹ø†7J³à~nH8	rİ`J£È–qPZÈÅBŒv‰:UØš+çÓ‹Å“ÏµO?tÛ†ÛNIn­%úœ`µ( k2YİwÚ ƒ¬t‰¼m“Ú¼+ƒàZ?ı7P“rŞWÌ™à-…Ù.Wc•!“×D€Á‡k©K¿é/¡æC“.W¢´§$(tÇŞv5pœÛ&éŠ3æËZ/î¨2*sâãú}(höØ­ıR–ªbİê‰"*ÉÔ&ˆBšNmUÔ¿qÎeRé_šàåáè\ÍÀë.™÷"ù6Î-QfXTv§Ú¡÷½ğí	ÆÑ‹Âhìí—ğ+†Q¤{>™Ë-YKk¬ıf12ÂøÔoz0zeè×ZRSûœ_jZ™¾¯y}ŸlhÑÄîğùé¬&ÖĞUÑªŒ¬¼?	‹ôù¨è‹
´9§cØÊ´F/1@«P{!~hhë6”=TÛa*ƒ±£ŸL[Ï%6üÜyUî—¦¯=%ølDøı„OOp.U/+âì-™D´~ÌJwB×ü™ œ@qÔé?k@ÊiSUö¯s¬ñ©u6¨PtÓ3ÜXß3ùĞK©æ¡Ÿv7cKº™Æ7§÷‚¡É” “fŞ+ÄlA÷§ª»·ÙÙX“XŸ*|È9m«TÏ^Ü'Â¼A“©inz6ciâºÓ¯¤8]!òÉ[hÅÕ6"¾>“/ssÊv3‰ÿ¼_Uj¾õaóDÆÕi1i;|f0G mI¼ÿàğŠXà.TUî@& ¦©—Iå5)UTuÚ”43/Ûû6Ó¤JøT~/„6ºğ	˜
›.F±Z+5ZIñ¶'Û’‡W/:3åeÑVö»Ş!kù4G~­üeù}¨]gpgs;Ğ©Î“Æe<òß2øeÿÉ4*×^Å¾¿öOuB_øáUÌáVëdŞá«ÌæÌ“M{Nƒ]¢q(¬lCçÂ^Ãpä6^ŸEtîû¥yq—ÊÁ¯yZ­’§våƒ¿£ğ];ƒ°«ô¢*»Ã‘$“½TB 2O‘ÕŒÊ¤Ç¥gv{i!U1ÅoáÍ§B"$ê(|M0}(ëî@õŠïÖÓnšã<`Œ+©4@ı@Ù|‘Ğbê‘«¶›~1kßGÿó˜Õ+i>ÆA,%^WŸ'Õ¯t+‚4Ê6«ßG9W›ˆùYùRk¬úlê'ÊÃ¯½f¡Ès=kĞ¦VJ9ÀÔùê$‹¬k·ê¹C1¤³4aO—?HdPkà•EzÛ	]·¬èp(]ƒî]úŸ$¦ënö¨‘Şœ–$jòHÏµdC»áª°,¿?júªKr?Ú{OOz'.ıŞâÀ°^éê,6]b0ñy‚ÖÜ7Ëó¥õ1}ü
YÀz‘Ük,h¶h@ÆîşÖŞbmÊ[‹B™aî¤ËDä ü‚O}F¶Ï`›Á<‚~¬"áokW‹€…Š€nWŒ¢µ¿LÅíc_Š~”âüªñuqõ§üÑ:‡rœ9®¿á­ŞC‘¦:X9QÛ"Û+R;·»íwRMÉC»BhÁĞÌ»ëé‹Ÿğ¹Ù¡nÊ¹ÿÅP,X¡Ønå9µ°[»ÎIĞ@îÃ¶Î=1šä£dŠÜìì:,-0üÉ‹ÔGÖ_àß½Š'ä¤¡Q¼‡7; ÿjÀîBUød2ñnk7q•ëø1é	zIÆ:]ƒû2ğ0ú²›ÖÈîíA›~ÙE0ª°İ€§*rh×¶º¦CêJb»*?kÏFşğ'¾Î®iŠˆ)ıœü¼Zœ‰“®¾[j™` M¸Ñß:¬*wF“fôe**´ıßBk>Y³¼’J±‚YÚ~÷jifÅÔ† Âmzçª¡mÒÔİw6Š ŞÊ+|ŞŒyv$Ğâå|yãå5w­DóïÄ‡0%D´·/î¿å]2µÒ»¾vŠåUd³ßRK’e_)ğò;Äºª’k9lT+Ë>8„mYq](¥€äÿIÖ¨€Çï(‹R¬ èÇÏV´f–ºŠ*¥í_Tø.‹/t©İµ\ãiÄçîP|n§pH©fÂ4ÒGãîæJ?\¨zrø?¾¨Ğ•.û%†ÍÈyšë¦óŞ¯ á¬S+ ¶³°eÁ+i	nó°¨¬Şÿ*@xîéE—ŒŠA³Ğ`À´J :ÅòN	D>Üx$Í¾'-±\£4A¿ı¤ì Ò\9TÕÈQ©â>á ¸…âfwRãõOİÚK*„]FÏ>Ï
7+éR³"âğ"Qmwdƒ ìÍ¤ØWuëf¤øW~Ş´aÿA–S³¯¿1W´ÿ•ç”jnóîèd (¥ĞX™ÓÌøLmmù@Ì¿şz†!&9ièÙÒ´Ãë¥)ñÊzòşÅƒ¨âáÀ¯º;÷8=îj7êb'ÌIò_Ğm-ú0Şï“ÆÎ|½é$
¯ÃºyB/JâñLõg™ø²C<aâIfò).HŞaşÔ£-dÒÀx¬ä9ÇÕ)á«áÒš$$
­„«ÜÔ@G†¸Ò…!/À/5—Ì´{²¯¢3»³ÇÎZ)şR,ÃÆÊ›§m‡KÒ:6¥‰@ ½YŒ;[şcğ¨s œå×++ÂšÌf!”ÄŠõËf’¶qz( Azş„÷œ¤[êQ3óNTIo§êÚİ¸ìB•@(‘bÒ--O9çGéÒP	7ØïŞ¶{éÜÛÇäRîä¬İçø_w^¤ D¸P~™u¡ÃCaÓ’æş&‘¥;Aéø¯HÕvÙÏŠÁ„]f"Í#÷lÎÚÕíhf˜²æsêò+Æ¯YaıÎ’Ç×Í‹šlıàİ¼¦ğÃ­µ½my©ÜÑXrÇ…!%sf ÙˆˆŸ2Nïş	­•©ï¨è¹„¦kzÀº‰øÖ+*=^àõæQGtr,îcK}ğ’G\Y5,oq|±ç‡>M"C0Ôip©Át[Û5D)ãoN´	èR4Ø¸%D7§*Å±û,pÔ]£hOìô”òòè£\…Åb.¤„ŒêæPdqÒ]§Õqß$ªß»pxF!ê‰¥¡â™½» ĞöGÑÌYH`â3bL¶F/ÓR]wHº”‡)sX0üë•5
sæmàœñ98æœt›®S‚e”ê^·±Ï»÷™ÀµúÈ“àO¼`w+lèóVpùd¾N™÷¢7°¦ŸÆÀÉ=˜Â.S=I"ÇLNZâXfiù9u.Ô~÷VMæ[×E×¦Qi„ˆ!¾¦[Äş>owkNG€#*¾æ¢0”å+H<
hØ Ö…xàIµá‹ªïV»XÃhuÀÂlYõœé–u,›=±÷ù²ê°|¥øA–ÌÁ(ıŠ]”ãÁs¶ö) =*­^º¡U¶z’²œ,@?uîÅã½¾¨˜¡èi&jıLEéÑ½A¦Mù–°-àOr²äí]Q{ÅVD°	%¡¢PX,‚¸v|CÜw‡•I/ÿÅB°ÎŸ‚-™Y÷~ËùîF“OƒJÚºÔÜÀÏŸ´ıÌ>Ôu©’¥YÔ„ ìğhI‚Ö\“¿…ô<í­6ô§< m““ÁŠ.,Í™š¨¼ã[/¥uuğ?æneÌºCóy“Î]ÏS·"" _èóí^0ôÊ	‹¹4ÛÌ†9>'2±êç‘ë\¬óo!tìÀ ì¶XåcG,•bŞÍ0kµ_:aSt#pÿƒ1zü¢Vn]éëÉ`FÁé&Âÿ"I¯¸PñŸrĞ×Ø8¦ÃÇáòyãşÖL´ğz%¿‘'V¯şDÉ4wÊK½bß||‹ØšaÒ·m$iõ:ŒBlÃ¨¢Ëú—ê†„J»¦pháVz½ÿ9)%—^½Ä*°úAÌAÒêÑÏŸ›Peù¤–÷%u•ûm½#Şöˆ¦’±lÌW•u£1ûU–QX]/Hlˆ”ôò­ä!OJ>z,iNğkU­òıË¸P’ø[À\l°€i)øG”€y‚Du5‹;öıÎê_‘CÃ*«7ä”ÄBá Zm„¿uğŠ«6!›ı´‚&"¯Æ°)ù$séDŸâ²"S^Ö;PÖÆŠû-ªÚWw`çæ1rŠ:÷,øØ-ÄÕ\ 4ß#O<n!ïà¸hqR{ÒÀ8éÈµmhŠ÷«W\ÕÍ.Æªğ9”¿Œ–_ÚĞ•<¬SdQíCûµ Š “şş!Ê`ö·–69œœñúX¦kZª¨m£°£ô•²½,s}Bã.m
ŒÆ‚“É½ß8LŞ•Ã8ÅFÓ/"Õ‡çd¬|íí!şõÖèÛÈ\–ƒ2Ã»¨d~>U êĞÍÏçe«JÂ#ˆŞ¬,˜çû÷¶yÊ8J@èÓ¿£Æ´|ªï1”é†úÁ‰d|³íøäğHã²­2Iú0Ú†ªİv´ö$—Î'>ßj¢îrâµk6#L%©6'‹æ	_
Õ†-aÖ½×nOôŸ£€ßéôİô„£¸,×FÑ“¡`§Z€3™QZ­K½ƒúä/s÷ØÈè,¦e&A_¼ZÍÅ´\†¾İ3£Ñññ«¸?S}ÓœKxT]çiÊVİ`E¬áYëV7U/»ÙM¯Œµ1ymšFèExÊÏ-¶/öòû9‘.@şü	Ñ°k®–>±“2ù°ÕFe‰5‹~%{¢=#™îÂ'\Ğ@,C·»•Æt?€œT¡«OK78~…ãyü2¬í=+‚`—c÷½™ŒèÚ2K77Ö$Ä]Ö²z‹GÂØy²¡Yä ‚wıœ˜­87n°u‡¯áƒíB¦ï›’b›pÒU>ÛxÕ’=58¶)°Vì®4úlÚÈz¦¯ oášĞq^‘kÃÀ'‚«»í5\`‡}Üí<Rv‹Lö¶	ĞXÛOìpåj/_èÇÀ¦š;f*øº‚F»îØÓg™x¹“•¼‡1aş$I3›½¹Õ_Óu·c;ü`ÉMOT(÷'±·U¬ıYœC,Lıã'‰¥ü`R,¯¡;k?2X‰óğ‘RpIVoo@èŞßFn†Ğ“z8«“ô—U÷ Ì@>*éiCÂûŒW*‘7£yµa‹
•…»`ËÀ’ jŠÒútr/}Íé¸Và»ªÖ7/rà.éiyÙ³áL)&P—¤[ã|Ö,Ú<8—WÀº•…H5I
‚¯6Gî”^¨CS(ú„®X!NÆòåì¨ıëj„Œ‘Í«ô(!xr dX~zÛÑÌÌ%×*ßÚæßãeÒãn¦+ ´ ¸£V–õ­&^•kkMâ)©L2å¡ˆ,œ_5hc–)|›‡·h¢t¥MVğŠ+°'Áî-,1¢IN¡À.<†»<ìBûfR]Œª£»¡8ÌœåNYyfÕtÏ
D“bŒg^´ù%Ğ€¯˜ãê3F˜·“YúVà·¡‡{šK#‹'ëÌø÷æ@“Í8Õ¬Òs¸Ñ›v¡fga×‹÷ÔÈ|HöKDj÷xcùÓÄ`ÏHœW¶…D¢£p/¸¡{Ïô›gÑ2ÉİH¹^0cñ%\–"¸·Øóép4ø¶Um[ÕÂàAº±’éèL’Á¡î:¿V#›ë´RiQh³(ÿõUñ¨ù'èû9åèpxèèi±\Ğ$cSò¶RDÈØ¯Ù‘r\Àº¥oÏúU¬‡Zˆä(ùå–æ‚365.]Š³$tz)»ñ&ZÜ&[»İZ¾t´D«A?SZ°óÉªA?KøG)R„óV Ëqø]A°"1ız-ÊvLòGfÜŒjèb<íÒc°˜´[’£ÜcWi	:¬9X(×”gC§"ó¯ü(v·Jè¢§û`rŒYoz¾²«"¢ØÆàØˆIO´¨ƒòöŠ®F\W¸æÓ|ß›2Ñ²a0…ƒş8¨¬•DP:ß®5¨Û¼ü5Q}y]²ñùÉØ}‚lGôìfN$ú$UÂÅF,!BR°Az°[Ğ.4y£ûg-BÅ¨¨VÏOÙ@A}Ûº˜a”·Y]0'ˆ“4|´U
µ éry¤’şŸ§¸T°¸yS7ñ&âïaßÏ{¢  öÜWı¶O1+Ú” 3@L	#Asék$6eü%¿/9vKìÌÈUî‹Á‘jÛ¨úYğÚ»DûÃıÇfEÀÏìç^R#Q·&‹–‹÷„qE¥v«A íı¦Ò©Nä=Dbæ=áZU—e¤şG˜Na¨ğ×?U#Ÿ;ö‡¢ú`€€¨,„õ» ôîo!±G5Ó·Qr5Óbvtx.+#õÅ!TÌ¸M™ëå>tºşoÈ <9ŞÙgÛªõÙ²™eÌ¼éµƒBìÏ  h°—:D””Ê~Ø	}3æß£v(÷é4F3+±«Ùà7†Ío†(…k8(²c}*3p&Û¢ø!’]ØJ`¬*,œdè_êJ>/"º¯&.&æÙ(Ïv0-<NpâZŞYm%ÊW×StÛ¥âáesí“
‰iş~ûƒÓ¢1A1Ğ¢¯1ûŒ`uJFÏ"]8<¿Ä=uVë	öÓ†eCV¬áÆAbiYËºdVŞvÿâX§"9¹±.®›]$›SŸxÎ3´CÊ×x®"»ÙºÛ«ø"İ½Ä°l˜İ€iìõì­¶Ó,Å.q¶õ	î´¢pxõlõ
Î¾†Ä,4¢Ï!Ïz} ö
yŞ4õèò’“°!òZ¹hâñ
¦ÖrÃxş;Í±mŸĞ7â‚T9š¿‘›?ˆÉ‡ÍÒÃ›	J}O¶Ñ‡¬Ø:»TV˜dÔW>91‚}°Ù¯‹ÅôR’ØÂuG$ñ›z×îGkDÅ‡ {‘6Ö«á”]c“i lDİÌ?Ëí½Ùåì' ÈK<ÿˆÌÔ³®áêyĞØ)gF–¿•ÇÁFFåö£eüÓki¤FÛÇŠ9tÁà¥B9ûH|¥QÌªj•vdî¨®w{K x”µ›^4K Tq?hXo‘Êš2™ÏC‹ù×Ş~Xä ØîG+±Øğ)I(OÃë¬¿˜GN½7É%vpò¬QìœRdd* 67µgy¦=ÆZ'¥"£atìuÜ´²_‹—záât›cŒ¡0u$`_X)QUCÜÁóŒN¨ëÓ"oú§æüqy”÷¯ĞF ß±ÃËhVŠ©M…¥ºÈæ‚$–XÙ)—3ãôŸdBûWÖÜ—ÁíV ‚"tÆŸŒòà]…#*§í5ˆÏç*ß)_ïiªšóå¢Oº5@NÉzí}c–•PxÄM±ŒbÀ‹•‘Ã $š,.e²ï?	ŠY¢]Xaîâ{Î›Iå.¯şMQiš@aû®d#E¦»•†[ö†G*î8¿§îm+u¶ñÔ|a»¡´qî2Š(ë”»¸âı¢W¬:ğŒ|Eç2hç€aA ûÆ\İ	fÇ8º¡'6“€qß¸hn0Ì¼&“.­|^^YIòÂ‡Eµ\é—æµYÍ&î³byì»¾fÍ¾$P=|Ç÷ë´Å°M±eÊ;˜7¦ÛØcáïıg„ïÃÒ¯&¸sşMöµù“(âÌøÕèpÒZ:Â ÉuA˜V¥xnîóL[7ÿ³w‹x/!°ô'îäW•Sä[ù˜ç…èëš.Òÿén^úÊÂ¯†.æZy¨36æOD}ívó‚!cZB¹¢cbù#R=£4ğxÄ(|Ôæ(£ñ-„”Ã/5ÑİÀsÚj;æ½<i4«s6ÎÎ„>9˜Æ»VÜ©MBˆ(á	‘ÊFW¤!š¦dÜ®Ïù?öí…ì?Î`ñ»re­ìUmså|	S½&ÃúşÅpGÈˆ¾@hß>6hQ¸°ŸæÉ5†Á—^xMş^ÖŞMèŠ„ÓŞ{ÎàÅ…ß¾}í®^-Ö±¹a4¸ƒÿÅ_ºNÉß_4<«,¦º}|UtÊæ7Éèdz)ä…ºº¥÷>pI…{»''#mjq
P¬Êš©È[¸®à78mÏû.¾¨Ø³{É$˜Eˆ[·7¤ZàHÇ…E+±ìŞƒ>Ãuœ4ÇÑ†“Î*€íïPl’‘©A;)>P^ğÈÍûòœ‡y”Îyµõ‘]G”ÁÉ«¯<òñÄz¶ZÃ½´úæ¯ĞòÓB†Hú`Ÿ8 «E(SZÉA"Ï‡ïÇš¬1úÒG€¥i‡›zÀÊ¾p9”vªîÜ\ÂAva’,æÙ¹“|g’äÖLlÚnĞ x°ôĞElë7©AG3‚g^cß·
J=«Ó±©¶7Ö/OrSx0W#°áÜ¤¿3	6¼Ìq¼"	ø’šh‘ñƒM§?çsè½U à’»g|rs^0Š×-U°QzÏ¨¸Ğ1µUšaÁÆÔÅØçe^3ŞÎ¸êûtùòK]¿çH´²¦9ó²Pq¸‚#4å~f¤à<­7ÃèÅ‡Ü4È¢NàŒäQÏ,½ùKÔ3õgâ¾ÊşJ‚¬AùëfÒ:H•Nâ™…›ÌÀVT°°‚ÀÙ- N¹Ò]<±Ú‰-ùÌÕª8¥\¥Ç;U1’EÈ…CwË®Û{GßÒ@ˆ½ı|dwmNbÛhš£Ç*‚ËVjæç¬Ê}©ì$‹}ÅDØŠë°Û§´Š»Ÿæ§ug7àúàÅ«¯Â¸dE¿Mëá4e»âükŒŸ2A&:QrZŞ­Øè¦¿2àD#©¸n*\¸±Ç³›ªé„Üü„Zg`d«^;u¥4S_è½"=C#Ê ácPj pı>ì½`¤Ú³ƒTîşŸ[ôH'ì¨Ö)àXsHÄm4÷x›;h _rëR9ÿº¿vRQa[åÆ«0y\;÷Eå:ìzï +%èÔ«»üŒë¼älÂPí´pkwÅyOŠ1$ë¥ä­Ğ?8ì¥îgşŞ‡×ö¶IGí3Æ£ø¶K6­²fÊAuRâ3xØËÈşÓVû);+ixñÁäw«‰Ë$W]?Iªw<Ä–åŒB!ô¯q:è"PÍBûº›?«º§FÜj5åpJN+,/»5T?¸ıh6·M;Ñ/¬‰élº‡:~Òä*×şÊg›ÖuÍWŒ•sÜEvù)ëË•Øk²ºÎ:ËÄ¥–„h7 `{k'pö@3{‘æ‹û¿Á~í'› `¡Â¯ 	„jPKyN¿ÁTô†õ3b;éwaŞÆ¶^yœÚ0³QUkD¤­m*ên…õâˆ‘CmÃÜÌ@ÚğŞÌ"Š
‚ÎMH“É¥Æ•o*õ¤»İÜZXĞˆ~¸1< ß›¤Â>ÌZÄÉr-o}{_wÀÃ´Œ%¿fZ[º»äA%6¥\æğa_Î‰ÎGYìú@Q‘ëÕ^õXRòñG¢4btÇ93óÿp«“‚q zÇoä¶lü;ÚÏ­£”Á3•5‡ÎeÕa.­Ì`ÖÓO_@ª«irÛiºÚÊ‚`!†ÈB¥êYU›d›¼•¢^¼‡;+{ ­wŞÙîõ§õàU>ƒ}v‰}˜›»~ÆCb´~°Òeˆc­å_1.¯CèM¨u/ ïˆpÊ«4l#z.Û]€¿Ölã%J½1Ïd2f	¾¨eµ ·‹‰/Lª˜'C‡‚3’9XèXâŞ.×6¤!òğÕtÑ9òÂ	¸«ı‰ŒØòÛñæ‘Ÿ}Æ½+Í®Ã‘ÓoãÔ”¿ÙÙnqòsÃ‡N46Æ#ûŠÍÏúLNHxÙ'L [Ø”L„o‹ª›Ò,®?}xˆ™,FWŠ"M?´ÙrP¸Õü;î¤²*€Ñ6ÑuôŞëw¥’Tî5™[oûp Unå¼î³v„â°0ışĞVˆ.Ş²ĞûÂP—¸ùŞ)6_Òhü^¯*`®tò
˜âLlj|Y Çûgø¯”#›Ø¿¨°É“øt53Jİ+
yí(®RÄÚ&ø*ÄÔ¼À»ŒU:0Ù‘îG&Ø¶í1dá²{Øñ[„ùĞED˜ù2Hº¦wªB/~Ğ
Rj¯“Û¤¤|½F×P(^ØUL=½Í*ŞìúõK„*¥%5x´i—­òóKƒoVêôŒöÙcÍ&<¼U…msbëró€øSŞ1H')]0ƒòuóË-T‡cƒúìÉİÎËBjøãëX'-Ü_TöİF
•Òê–ş
s¯ÓfbiCÒt¢vM½Û¨ğ[!‚b5ªlºqÅ†Hwå›ú3˜ÕV2âñ­‡:÷,ù–Á¨LEüÁÏ”ÒÌ¸ÉÖ-±=À“åqá3· ·{á:štõ¿ØÑn_°8ÙÀ›F;Ì>ß"\;g±²
B›Cµj‹g±;“h\*Ş_J€Í'Ûn3WM`mS˜­™‘‡Òó5·äó4ÑÎ8!YACål<Ğ\ÈÛãb×Cö…Eì§ÛÀ·±°çÚä—‹ß{¼È2ÊŒÿ)SÁMÙv’¹àCR¹Ûİr,Æ`¾¢ãMlª°ë*E`¼×©7ãïšq,Qg3ízEŸ>n,d6LñHÃöÔ—–.•À<Kã;S—o²¡îöõ8'
Ñè(Ë
%÷˜òU¼Sï.[ÏZkÑ2íÊå^zà5Î¾•O6‰v¯"ÄŠP%KÎ¯.Pù¶¿ÿì‘û’V©{ïyU˜¸hO)AÄ°~kïtÄ1‰P†œ×µ/ËË©‡hùÿ÷qÇZÙdç¨Ø¤·mZ=ôÊ}©÷)°Ÿ D%ª¬w¡LS–dW¾2~kî^ämÉ´ØÚÀuCª¹luƒÕ·eµ‰ˆ‘Éä.á´*^Ñ;„Â$Øš{P¼¥üµ„ Ü(5’èEX~ˆ³şø»Ô3Îj K&ößØƒhÌ7	œ€u5{ëCIÒåÄ;©&#~úùß¬N0ˆÁğsíÄf¹Î¬­¦,gÛ)‰fJÑ\‰v(…Óª¯®§œ¯…%Çê¹=Ç¡KóêÇ"	B•ŞCOMd8gtî÷êj¸ˆĞ?''ûÑîş:1u›‡´ùÿ:0Ì­A¿ÏX¨”ÕX©/g‚½¨KtåĞûå&Qü5³ÿ á~ïkÆ;sº©~pÅ¶ŠZûF	ºû=5$sï@‰“˜g3LÜŒèT CÄ#–P¡=R´7e¢ÄB{ç¢¬¡%# K2½¥ÍÓıÙe ˜;„¤•šl°Wî£)”YüĞ[“£ë”{s}Ö>—älyùã&âœòoË5BjlVsĞ"&ãI‚©\õ[-ÀPo*Ò£°µ‚$÷KÁ5±ˆS|üG@Cü2¸DN¸ŒŞ´|fâkZGÆ©«WÕÒZb EÌ
?L:lUğ­óí>UFªå8"­›×0%œ_½Ë®äÒŸÈÌm ËBÃgj‹ßÉè¶§[Z%«¢ÜDh Œˆ¬k÷Ä”¶¶ºôñr\eÇ@3O’bòø+ëxrÍÁ ¼™OÂ0§DC¾¾´¹ ¸9òx¶£©øküŞ0#UÃ"±{S&}ˆ‚§uvkŒíNKÆE·¨ÿ¹÷xm5ó\ÒF˜~çû`eG{´÷ßÂIç‹´[Ã‡’ğ…·4G6˜gİ¦Ö†µıÅf?²l©5òB0ú€Ä5ÚyKRwï¢œI¤eí®;ˆÇM‘1Hî³ŸÊõûÈàª‡ë[Ù<4 O€Ã´NÉŠ‡c69Dï;2¶dB…
ÒBU	qÇlVÜîÂUMşüâZ€NÂú<ì®²¹»»ë…îfM‹Zh(¤ğ òn¦©Q¯?aÑœt;@Ñ‚k›6Ô‘énH^‡$åı#_:k|ˆoÂ2×Ë¨ÕÚ‹,{4òğù2¿%JÖS]sÛ.RÓ4ŒÑ9LJÿYã>'ód°É³v>º3[Ì}å§º³ÇK–3¬B=.Tª¶*e á{Mš.ô-]ºDMu1=­_„Ámô/	ÈÅHNÿrë¸¯=¹¦tı­À+îñìŸšv"ÛŠ¤Ã•¹kx”–®wÜÁŞ{oïÁ‡dWw˜úàòÂÿjiÜê€ñ£4E<9tïöÜà¾÷5åê[ôTi'†]ş¡R `ƒLšƒ³ÜÄº>›4m}JïÅÊeœ$õM	ì˜È²ÑôÛÂAT÷òÔ|½!S¤m@*>ª©µ`…Ô‚ Úy…€n¾k·9êh™E1"5aEûë)g×IúıÖ]€ëÕ£ªÔ
Yù”vß.q× {ÿwW0d`ÂPéñ=VUÓÃ«Oå°#° İáôknsox‘«ÕZ,¶¼…®0Ú"ÀÛ
†H6Ï	HÅÓ@H€‘:¾G#nšRXÃcîí€wg[MÇ&zì¼zP­N´xÜšµ 6™Ğ«(‰ºÊÙ;%uñúÆèNİX|ş5·öÉ/[áïeÆ2ü£ƒü~¹âDd«™¾›+|NMW
Ñb$ÅT!g!@æ€µfËK¢²ç.°¨îyvÜ
‚‘¾
çÏ˜ÃO‰4¬c­NG(`d|kšyj°ô(¥ƒìÄQêV€k%@İÊ×ÒÀaO´¬á’‡>ÿÈıEÌªN¶·àŞ4°^@Õ)ŞõŒâ(ºÑRå\ºQĞ?,Û¯@MaUåÅ¸}µİÇù¶Úò´¹ 0‹Å5–§ú}DÃ¶çõ\d"Ë½ˆ„à—\å^{­·eCqõ÷æ*qô[˜aì¸‚>ş3v_ê#˜Î»4tÆ!XQòç£Hœój;Î8ĞàÏëö&N	Œ˜¬J&T_¼n5JÁ:«Ìó¤ôgÌå(§–Ş^•Oãá62¹:´šéİ¾+v´¤µËG5AT*ÿ\ÁFf­MÊFÒ!Ê=¿­ Çw¯u&«ç4!ïGˆıi`™)³ßFUúŠŸÙ½$ÍÂ‘l^½™ Ãª~İÖ„úİÑ`Î@"ÏÌ8*y³yÖßÍÄË,×óë¶²©wmX÷-æ‡j)ûœ²ÜDïyÌw2îëµõÜoí´6R#ÂÑ!²sm"rM¾OàûdnúU«˜üm$Üô2Û”…RRÜƒ®u×rr`×@ÎMŞl9(Ø›‚ƒ³A8©]ñ;†e–Á€ÿYíe\9<r«X™şÆkÏ­A"82Iûà±}ÖŞÊ'v}ØWÒ¿Èxè±Üy‘á §Áã˜g³°ëmÙj­ O©ìŠhGÉ…Ä'ŠEz+é­M_I;èSæ Ô­Ù§¾–Òú‚‡a‰\:BäƒSÙK©·ã‡ş /8+E]ªlid½m¼´úW×H€Íz>ïf@»ÕQ­Ö¥rÆµ ‡‰ ¸ƒg/wv~o&ålÀóRI«]ı®÷ı²„zb@fÂVÍ«-~ÊP#4E/š ä/§ÓÃÇ UiädÓ†ë%}Lÿè{2Ñ"Ü¥–0_¼XÈıñB“eÈşÿKy†Ä¹{›qÔW˜q37—ÕNˆR3OFÁa²~¤Ng~á+ÊnÖ%ÑtJg²TØ÷Oó“-Œ¼_’«,mš´Xçì!¾Õ§;ö]€8}7RÜŒ2HäÉš‰*·kÌÚ0H–×Z!J	A»+Vo¦FB/a¯ Ê4únÄ‡ ‚¹iKUüò²deM³˜ùåÍ~ŸMâĞá|n†7ÌÀ½Cbbö¤ß™2zıÊãÍQ‹7¼X\:pİ*Õ7ãu2	õ6d¬ÔÈ8–€ùÌŞš„AL[y¬3	­Ğ°D­q¨Ş2fúİ‰10¯ùƒéfÄlV¤qŞ¦ZàíˆJÄbyg\\ª¿Wh†”}<¨4Q{MÄ©éô¹²ˆˆlÖ˜-P_¿l"%{zŸÍ·áÒ)$‰D2Èšr‘ªa<ND( ê#„¸}9FNb5/`ä)´úl:E˜9pZ¯»JãHë{ŒÃg*È*JãAÔ»‚"ÙşJ¤œ<…nõc„ÍÜFjZ –ìÆÆ’k—kW kÑ1±¶Lö¡¿S¿»$”Ú¬É|9AejHKE6„5°÷zJOÔGØİ‚ãF¾&¨{viÁì×Ç…ø‚ªÚêsµ¢ÿ~Ö°•F°=İ·Ã‚L]û—­Ö ”E`ô,Ù*—  à¢$Şd˜–šn¼ŒúgÁõöızÙåû|æ¹®Cwc0œzµAÿ	$GË«be.çzÄö6¿‘^S'şy,~¿d<8<æDªXO%ÎÅL¦míei£¬»Ô±İXWQ°üĞgÜ²vµC§²–7êZiK	U0#ÛÌqqøE—5Odkğ%ª£ÏÚ)üåànj
Y•kÁhÌÇ_,#Ğº`»áÙÍAºùèì5îŒ±ÿs­ú0˜g<Húof)ÚÏR¬>z'Uı\ä¿–À—X/•Rõ¤ºâ;NgÚ|Z¬PNœ*<p_F_3ã§Ì²jõÃĞ©	vF)±ÈjÖu’ÿŒí(Ø.æ‹'Åp)“&õ;¨Ô$qúïm¦€ûş$eÁ' Î¦¦M"ÀwçcIøı
æÚ¶2Ë·ZÍºl¸l9jv°>ÑÏ}yÖ3»İRh—Øg§Ğy#¢˜C¿Tş‹	ESGNK'éì˜©2ÈÅ°ô
(¬FDë¿:ò>×C°¡æ@éAÓ’8=ıx"O›†½Ë“
'ZRÛ.Šõ›iA—æëı·K lŞÛ˜ÍÛmõrÉ±±Z hŞ|ù&E•Ó!aâ¿«Å;Ÿ¹ÿx©Ø:rÃ/6JD”½7,\)AöÖû¿ªé¨¨t¥1y	sZíÔJ'G0¢S“)3o£¸Zê\¸$ö ´™¬îZÈ6}íy°Æ×©¨Uxeñ/ø9ÁÎ	…•vö3¾JŠÏc¨Ø°şUT˜‰ÂºWëÀj^iS=Û,G«<¸J»K|~áÄğÁ´Ï±ê«Šq„5«3ØÀuÀæJ¾”’8àB>Ï”SD}ü¯G¶'•¨{İpY”O@¼•}g8€CglcwB ÊòšÔ¨“ïQßş!@å?UíÂJ³ô¹p‚H/HÃP™Æw!æ¦ĞÊLáFqHwÏ$’Œî&¿
‘çğ¿ñG;QÄ™‡˜è-¥²‚¨1%ë¹½/Ã½0·*ˆëoÉ¤‡½á3Ji-ùå!b»×q½jR”¯m:-soÖÕ42f´0¡Ï~˜è-Ñ‚€+°ğv/¦9>ÿ^Œ˜¤ÉåíıÜ:zÑHÃSôÊ˜Ì"onÈd¼Ài»)¨ªx°
îêößzÖ-3‰ô€’I2½º‡Ñ¿‚fÜÉ¬{ßc‡ÅÒ¿j§„®K‹À 91 c…n½‘“4O{”,¨ÿ¶š4?FÆÛ¤©-ªë¼˜Áñ+à_ø;Aò™ŸNñ¼t¹«ywİ?K‰`9× š[Ä))*ëDV¬L°æ=qâ/Ol¦„q¾dïÚÔ+{y2ûr>L=Iš‰ w‚<§Q;ªGÏ2&›F´°ê$d‘İ†ƒå‹³Æ.¹ª&eY¦ıŞª,9PEi?-f3/è ÔuŒ2Ò¦HKç’ÓW´Q'ç‘Ò³Äğ`ş—UJøÇT›î¸ØFgø6 Ù$¸Tä•gä!Í“Ø"Õ7¾6¦‘®ÖÃ¨ŒóÄj hzL…á=!¬ËW"÷ñ¤`ç{¢ÀÌ`´‰©ZÛ¾´*NõRBÀ/YLşÍnÜj§µİ:z„aŠuÔ ¶ë¯Ôğ†şW6´BÆ¤aø£×–¡×¨+}!œ]™Ò Ùıp/9K'$$pè
í—•#Ş÷š®Ziºí‚Ç‚>£‘Ÿµo×~Â"X9¥%=üX~3¯Vd~yT[lÖªl”ğ¨„]7ÏÁKSÜ÷,n¦˜¥«%Æ¼ÙpUí¼v„YR&Ârº5ÄDš1 ¾n9TĞÿ	Sƒr#¡Ú6>ä¾ß³áù÷²Ò3)í7NÆÙiÙ\	ú.ƒâ­u‹gÅ î­Y¶öÃÔ¦^Ky±hhƒ\qCÄ°sì/Š%LûÁ£·`x*²‰mG¹I$6ÓM«Úƒy¬¹šÂV¸yì5‡Ğ{šíµœlÆQl]¹ÉÜx÷zz„g‰—ŸÇè{Û_şqŸjïö—#Î:vŠ]9 ©æÕFÂÃ•9g&š³ñr=Aö$*òy®~â6x”md©øşu(£ æÈ^=™ºùÁ~7ìc‰9%¯…É  ®²b†3Ù¡y<?8b"µØŒ@ëé¼Oë›wqİ•Ù€Ú!Æ¶Ç3º=a«æ²RµÑ9FlkWÚTBW»Ş¾JW6˜ò/~?c,®ı“²«]¼4õYî8ïIPĞh Ø¹	eëë7B4Q¡A‰İE¸İÇ¶¤Tö£q‘ïñõEz¿õş‘È©GEÔTxlT9{òL»÷”­Ã	?òõ|âU¤ø®×|ÛW×ß‚q7€mk6¯7õÚÖ~“ÛmÜ³ jâÒ“^®S+¿7ÜSòJ^q‹bÚ${Š;Ü?/İü.”:î]Ù®2¬HÁe{îí_…^*Ì˜ˆû\æà¯µLË>¿5I¦©Xô—¸¥À½³®VruDmÂÏ…’=L3‚ÈÊ=k/+µ‘M®|¬%®ªa§¬Ø7[ôÕÔ¯Æ™¥„ùÓ&ÁQÎqZ‹á÷Zçcº5˜vnùÈy÷k7|°@9,*¿õQ(AQÜ'ÀÍÛ.Bh…d?CÇ1ãÕWû:zí¹–/şìõ[e‚bâæºo<áÿ¡ÿ.#ÖT³Ñz™ÇDÜivæ£X[òÚ‰ıƒ•x‘€Lßw¬s,”W‘r$ª™¹@m™°Mq=†f÷Î)¿±1›N8½¹ÆH5ìœ;mÈßØÆ/mÂwâÉÖn‰g)èM«(Æ`P˜ë©ÔE‚Be¯{ÕÀ¾au+ˆ}=ØY¹áÏ]:Ë£<¶Xã°ˆeLÂ—–!LÜ”Õ‹¬Ü2$buáSÆì§¨-`7Çç³EaøÈ.1¹î–……öç©­Hÿ¶îĞ¹ JdÍ‡¶16ñ©m£’éœó}+p¼¾^¨‘Ñt` *<&0òf8m½°•UØëUâ×‚^˜Qù[Ë°Ğ:ê¼°ÊC¾Ì­lÛ"æHÈN‡³Š£™{`ö§ªõŞLv P+0o§*dí¼+ü¬-‡uùç˜l º‘l SA†˜÷U!p½xD
’ŸÌ"Bp7ã¡j˜dm¹Ê+gªAø÷XZös$,Àe—wCÑähqÇ€    Ão”_‚3 Á¶€ÀpÚqŠ±Ägû    YZ