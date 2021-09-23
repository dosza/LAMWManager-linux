#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="760574501"
MD5="4e8058fe8d2893c675117aab670863b0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23916"
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
	echo Date of packaging: Thu Sep 23 13:39:18 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ])] ¼}•À1Dd]‡Á›PætİDõrÅŠİ5›°&üy–{Ü[×§pÚ2Ó‚®µ·ôŸ=kĞ¡¤D'z%š;GlH)¬É@æ|•Ò‹Z
@ø\ñÖÈö ÑAo…âŞ0ñ2¾[Oz™Ï“Q.|kbmWÕšõ¡ºŒ@+‡ş	;¶_«ãíË¡“is­8 Èò;„»§ã1xÁá¶CuÒçìvĞ»‘¹¼À>køıeÙ.„!Ö§¡Äy,3"a–DØqó†§óùmu8[ÉÜÃæÑƒnrÆÑ9€0áKÙvP×óÅ?8¥ÍuR{m`{#ád{ER	÷¼hí#'R`áŒÊ¬jn²°÷Ú“@òo¬!Á†\ğQ«İÀ©bYÉ9€ıù×bÊ‰Uw\ÿg¸~ãÓ¬ïqj‡<¬„ª+2­Ã=ÿw¢İ°Ôr<kZ7@Æñ¹¾à4ö<F”bè¬¾dUF ÅºÛ[š>+í>#ôÒ8m0a66—ñó|nj³œŞğã0€¾f…å£ºÜ†9ÇÑ¨!ib¢*şO	rt×\¸ÄU@ïMî0ipÙÓâŞz‚<ùàkÍî/}×Ğ¥
jy2÷Q¾²]aA£{WruÈ%òdªùÁdMY Ü@<kqBlDİeK„…æY9Ã/ì»¾ŸuúìºÎ¥wÙÅÚâò>­õÈ¡ì‡Ã1@g¿ É·¿G¢ÒÿÅ_òUş…Üçäk(OÊ?{†æÊåBöüiâUOuurğ#ù¤‡ĞªL—ÜÊ‚Æ×&òéáÖÜ_j¦r²®}^ÆÆ1*ªTÛd÷€‚ë±ŸAí…'q„:°”¹è'„÷Á)û8eöŠX•Š¥øÊ˜`~ ¿âèÑ `l€Êôpzs¢Ú÷—Ä3~Cª§ŒKDdG!6 ‘æ.Èf4»ÔÌZç™»Oól-GrcìÍ¿o¥£oûô·í×[éê„¹ ÷Š™yÉşäİ3Ù÷îI|¶CÄî[På4næêù^>¬^„AÌé*ÅŸJ÷Ï‘™V}%ôyb‘Vèn±†‰o5C—øoÒ¾†©œ¡”Ï‚M‚æOİ°3öŞ´ˆùœşÖÕGÛŸ³Šc‚Øš¥-ŞHA|î¶#{l›{X€~vJœ×ê]Ç:ƒ†_|äm¶ì¡@ W¢VlK‚twÅË¿W(é  —ÅT®ÓFùL0Ùø7¢t2>O‹ş#Ï`™[PXıj‘¦8ê•Ã¬^&œ Xöš>Á¨rç’åÿQÙÍrÃƒL]/S~µrYú¤	(Oæº¤İ‡íÌ…?”:2F a®e
êÕÔÇ¹ë¸3tıâ›Ïİ/0‘Œ’Qs<±*Gqµy‹1Ã”Ut¡°“xÉĞàŞq–­œ*­*VŞØº@î4¦D´ĞÅIÅA¹<àúÒ"`"¦¼ËZšõŞGÃ;¬°ãaÁc4"ø
vs—¤ËXüN¹¹Uµ?Á+ÆÛœT7ó„`€£Ú+@ùAòÔ-šßJ‚J`éfn‚&]6­E´¤ÄÓÔ€i¯³a-zZw~6è}rWq‡À»fk—„m‹—9/Ş|Tš=ÎË„=’†–n>€VãŠ 2”ş„C&Ávvñ>²êKìó3 ¿^;K@–ZS­"õC°:ÜË«Uş§;—¶’êÿ7Nş_TbffŞu)G¸“v÷6Q–äş3|HığÊ—¹gFÑ8(š!9íÁ›å[r×{D*1 ñueùö®2¦Ìœ÷»ÜÔûıi
°†mË`DéúÖ8?’Ë@ÄN0eH*X¢t“V!E7½{Í}ô,ÃH„X¿	ÕøÒ±ÉÁÔ_»ëQ[ébıÇ‘óóU3õ6ßÆ	—ÍS*·ƒÑ~ë¦Î^âIŸ8üÛ0Xp
²Ÿ¡ƒĞƒ½ÁdW(Ş¿¿Y£+=L~Y¯Eª³QqRh±ÑÍë$Î‰r?O§V®áÛÅÛÕ½Oâ;‹‡#03Eƒ¤ĞÎ)Yè“[ãÍâCe[Õ»ÚA2T/²à‹Bz¿/ïJ%GCŠWş×r™ÁleÜ ;§ßÊW£RÑ]ù_©÷ëĞx!÷–åµl?Ş0ßó›b¥W£|m´‚‡ºYwİ}T#©Ó4şØ.{,ıu2QÉ¨nS–XlÇ0b*3ÙìÒCZªœ2gà´³›V³T³sûz$À;b-ÍDòtK‚}ÓÃÛıø{Í{cÚ€õf4™¸šJNğ]fã—™2a|ÎE«÷>¦/ıÙÿ×3jùÆqÃâ°¹¯h£œ³ˆ’2­ÂzvyybS%#öÉ×:zl8Ul8¿ •	˜\ŒÜ“àgşN&è‡B8ÌÍWlÎUúü%‰Yt“²6àÜ…ß6‰¨õ.d†Ë^r2ŒWõ;¨œßR·J¿çICõEÜúÇgÿbüØ/9Qèe~%¯öà‹o¬á	w­Ş+[\‘ãˆÇ%:fuòD;#ü.	Ç$‹¥î{nM•¢î¸U=^¼ ^±6f…Œ”Œ»]ûâ³%? Ñãªpb¡å>mŠ5¡}¸õ+qaø²Ù7Kz@_|š¥ä¥ÃÈÚ» uëËxæì¦*îŞtÚ´İ;±ÑCA¼2Ä”ÑÑĞ:¶›È~·íÌz§´E¬@äaƒP¶—ÎgûfçLÔÈai&>¤ü©·n—ò¦x·Í‹‰ô¼ÕH|J’ çĞ¨¡¬9Ëkú?¾˜áB$ÌA…vÏÜ•óŞó×¢2*F¿¼–;–ëSDå‡]¥ˆ$Ù¢ røó¯l¡Q“sÉ¥õ÷e£ÊÈ4"ŠÅ6+½¦Œ—øi3şÉ“óÛJ^n;£D,ûÔÅkoåÙÂ0âÖ§š
ÏÍW"§¦’TÃÉ'€HëËYf–‚äÏ“Ÿ‰MwÎ³:‹]jA8^…$aÛ©Ğø°A¨>DZÂâ´uÉ]l7q¦8Ë¼‚§3Ç:P'B"È·¼4¢A!½,­SÅŠ?¸#¤_¨úÓçc#‹¨ßŒÇMÖmÃf¿ÍF$¹à:!CºB·ÕLÒŠc…×¯œ¨!Wâb#Ám cq¡U"¦,‹Ìa­×f®8®™ö?¹îËtö]â †ërMov9[‘ÂÖq#&„Á÷t¾Ÿ•“øsâIúÓpÂ´Ñpßğê<ø›uÊœ|˜x[=;Ó*ß¢(k&1ŸFˆ“pwÃ¨rËìö0m7Ü5ywdmÊ°‘Ò¾«Sl¯=¶]£ê8ohö®¾UŸIE:¼>Y^ØÖ™<j%ø­¼½¢Un_|Ë¶Së~‹™Aõ@*SŠß`6Ş·S†hgHFŸ‚æ3s5p%§9Œ!®Ú<ÀÜ¨^%Õ˜3åàçfiÑÌPNšüòÂFÃ1ææ 7Ÿ›Ï—>NúÖ»]ÿbNn .-¥¨?ì£CXİº“ÖÖš)®v—i=Qs¤¿ W²…¨å2Ê\;œ¬5ñ#Ã¸ÓH6º':˜ô æÖ°Ë§¾	Slı\Ea‘S„¯DY2ià´UV€C>§2Ö´İ{DQO±X@æÛò­Ø‹ÂS„Ğí ËËbÒäÿÌ'ºL"ÕúÅ†ŒpRôƒ(²Cë¤ŠÆ)À°9E‡eĞdVOi†ı‰ÿÛæ"a²Šƒ—á1•†\´iÂxU`ŒnŒ‘št8ƒˆÿqq8dë@2báÄH¾k™¦FÁerwÙ{71ƒZÁÛæR ?yü÷5ø2ıÛÎæ2¶îòÊIñ¢?Îµùr®=ƒU[aÎ˜ ˜i†ÇØê[©Ï£!Ì J¯‘R˜ëQ“öÑ;‘şf¦¹Òâˆ-	l<Ï=>G›E&1n¥½ßIéŞêR—:ƒl¸œ¨~[ûq”!5¢ğäcóˆ˜KĞ6ímßd¥×¾ıˆù8š)GÜ§ªi²)ÛT%\àf!œbùÕĞ<g¯ô¡ÉNßª¾CÌ8 …°»ƒâaX-tVlÙ],]®š×Z‚œ’ök¿´Z¹Ş¹ñÅaW«æfY«g0Ï—MÖ€Ÿ Ÿ*« Z ;n0¢j"7–VĞpÃæv†eûÀ-‘Ì9©øàè9ÿûÈ¯îÄÃDp­È‹ÜÔÆH³÷%¼¶5,IÎ‚K`‘€_Y]Âñé\]ÕT¼Â–}MÉú,JÒZšÓtÿV!¿|9fC¸Lˆíöƒû8JÄ
?~5\ÍGAÏo]½òuöFd—ÛöÒG=¡ÜI¯ ÍR—ƒƒ“¸ÜÉ	ãEâg	í¨ğ"¦éâæÒ@j¾3rë €N
ë6¾UáôÉ8
Î²T~vƒ»œŒÂ½F1n6“dP—2Ro›­¤®¡ÇÒwÈIky§sğÑ\ğƒjœÍÿƒîát%û§}xmÀxÈöˆM¢¡Ø$Ò7.®W“¢ÏÄæò1€wƒz¿~<Z=Ùl•"¯aoÜ*,ü„6Eõs-––Éu«\üxnéögZézy‰[ŒD4Q¯ùøhFã·¤±OrE3·>’›ÅTSª	÷¼
&Xs/¹j
*ŠƒO1!UVäõ¸ôwƒHÛ1d·¨r_(Ic†.V<,MÓdŞ>0©B púÀ;@'	>
—“]’ˆZ3¿{_!IØ\5—Up1àßJ­3!L`P„«şÇš¨‚½•K¤ÜJÔß\ä­Í¬,è|¸f©,3í¹ÁÁ)€ş`µ)M’(2!Íºğú¬Ô/&WU­ *)äÀL·óÂª¥,¾K´Ğ/±ƒ-ÆU'ê@¼>ÏVï‹©Æ6òmÿÖzŸ`şÅÿóW§ñ‘'óÎ'™şso³"nåø¡Ş@‰Rÿ<x÷¨.qÿÏ]I([˜¤ue	ò;V†óÊ»­q]ûOEƒı*Ú.|“üRÕp
ØÃ6éŒÚvúÁçÙ/ˆXzF»"&ğn‚ˆ/N:¤•÷î@dÂ„!ª`ˆ	•Ÿâa;S‘OW595¹]Wkí4+¶†Ë“åÌ™yÒJdzwëæ¯¢µ¤›šJ"Oé>¾ƒ@h2HÖôY:ò¤ÙÙ…WGÌDL¸iĞôó“Õ‰îÂÆı0¿8Û™Ö6[^!å¿]68ñŠ§® ‘&Ï&ª“pIséÑk.9®· |,¥?Í “_²G|ĞMwlâ™aÉgÎ¥f¶ò¨£G-~ˆP­	ÀÇ{µÆ]ì;¹z*BÄ09Ø¸™İ€s¡ÿn`5‚œytF‹A›õ ÅháŸ„L†^ë'{b˜¼wš’iš0™sŠŸö¼šôÛfV³=PeG0\Û¡ÉF{Y 5ïIÓĞsn×Ê~Àzå8ïÔAë`µ=G'G¯\Aºq„h¼e[…Àß¯“şG §—±èõ–ZÕ>\”“âˆ!lcéoŞ5ğ„eŒ•Z5${n®__©AÉ\ÿn×ÇJ‚Utd”æÍ|Ğå\èi«/°3Š©î8^Ñ‡ìË”¢![õ1Ém`RE»Â‹' ÉoV?<½¥]R‡84}ØeUMéaà±™ıX/º;f9àcÌ$ãÎ>êe…íRÇ@í?ÉRóI
AerQ†R2™H¾É0AºµéÁdçß‹=PØ!­gÒIäkğFhœ¾è6_Œ›	İ¾;RVAf*¤eÏ)Îà½Ì”Ö›£Ø\·Z¥rM‹•òÿ•;~iîªXÿ«åZ÷Á=¸£àD Îjå-\¿8Ô‘{Ãí&ıëÀù¨%‡OgŞVÆ>¡‹¢Û®s³|¿ò~8h§°™9—ASjañÈ=/-™ë\€³¹oô¡‡9©qĞ{•]A½úM›X…ş…“ßà’†é ¡At2UT·e¡uû¾¹‚v+ƒ»¯4…ÏÊY~²¯Âßn,ÉÇ¨OÉ(Íûò‰‘ÒÈŠ³© .ïùÇüvı•Œ¯oËŸí^±&\p„Ğ-jŒÀPY¿|Ék[[3,'¶›üb=¾¬IºÍ›¦>5Œ„ò@‡¿Åd+ÂüINeQõ¹=q
Äj†æ%KBï2—Á½]îÕ8¦{oqJ}.Py’uúX@K	ÿOémW¢½_,Ñ¶Ğ²ç!§óÕa{¢Q`~Sæ}]j®4,u­ ÍÌR¬.«fPg„¶iïöMûîgªp…×Ïñ6ÏÉŒKŸª9bûù¸1±3ßdSætBÚÓL®ÎÿtË—úµ ‘Ç¦320%_z*Ö8É ºJ¿V£‘‡qµŒäöê%‚º"u={Ô<FÔRÊÜÍ¯ôÌøQÂÇ¢ƒ ‚ú#Ê!ş… wSç¤^ÏÅĞ¿›|½Æ(T2—×Š3æVú”«Í@[ÄB5 p`ØKeË•¦ÔšF¶÷†6Xû²xM,UŒüÃşã:Oo¦¯bàANƒİÊ·˜ùÎÙÌ©Ps€JgAéªš¶›S€P¹½]^ú‰„G[— 1A;n<Åq×½ï‹ GßĞéb.ı“*_¥~­ @-åz0y€9çìD"µ^V¢N¸‹2,ŠõºGÆw=I³|•>ã`9©¤¯‰<>=uÄÄ
¸Oæï"Ï)â)GmÙ¾1<GhKŒH@ˆ¥ZŞD†:Ø·¯ï>YœÈB»h4<M­&]†˜óüXFìÜÛgUŠó3{ôy›‚‹ÕnkŞå2­Š`“Ê-¥'é@¼‡:Ì™µ`QAÙEG¸ÃÇ‰=™,Ê¹BñÌÁ]ÆÌUéLúş¿Ÿ¿‹P„¥ºfQçú€?¯§gkô•Ç,»e<aù 5øçEWff(ı30–g­(`c­>KcÃ ~nÛ/x¡¿‚Å¦!Ø_¢Gt4+W‚¢*¦g’ºÅ¥nìf Ë®6“TñõôO"˜¡å‹¥ÇÄü%Ù³,/ä«ÇˆÎF‹|„§Ï²;z³E#¾ÆåV•ôíö–’6Eå—¨òÙéŸÊê~£şpMİ'îıŒ^%Ğ®TÊ =’^Uz&úŞ„¶)G*à~k>b~I¹*a]ËÃ„ñÃã* gøB(­’k¿äÆ°\_63¿Ú^8P‡ˆäEÃT}ÙÃäæMæNiS®ÑáP¥Åºu`c%v+§Qí!Aœ¤o2¹MvÏrîªxÑ›_Ğ?Rj£_vîû6m£J[ 7òìaíÚA-ôŸ«:=?¢Ü>öìM„6Èçxœßmf+0noÂ‚ÿ—ş-‚Ø[Y ¬»A[…ÏfÚ0tÉ&NøgQËÂ©ÇRKÏ(áJµ©5h —n ¦wC»œÿLeXe?/¸v¶£iuÑ%~ëä9Vc
¶t5Ó*Ä×ó¯İgÒıEş>Z¥}Æ½v¥­Ã5® 3bĞıáÕ@‚óšåÙ—ÎC”rŞÖöiÕÔ_y”Ï§&k6š,³É‘¢mS’ŞÚ–ßƒg*JSÁ×»ÌiUä¼àLQ²—„f‡åÔ	~Ÿ†¶8ªßmŒÅeŒQ	§>¥ıéjÉ#ääıÁáB+tœÔİaº»ÀÀó†ÂßŸ ±o”{)µƒ¤'×ë.×‹dêU`±¾U&a!ĞEªQòÕøÆ?j"e7)iÛcíÓ:lo ¤¬dô™ÿé]áìŞ×I˜Ô³SÌ;§©~3ÙtéWhHĞĞö=l‹phµ]kñòÙjD‡a¿ágW"§TÂñ¿õÓ#ã©7}z¬»×Ç¹±*EEÍ‡”ó¦zoØ*5;„½jĞmÍQ}oœá“foÁÅ«)·ç¿ÜÚVµëf0,blBÚC>ÿù#SZÚ¾<g”d	Ç1“YË~¼5}ğ1búû3AAñÂ™f¯
™òÄW
4$xq	Ç.aúcxítâÓA ‘Öˆy!©s¹Î&ÜÇÁr«„ñ—¤9×iÏÄè	h®v5şØ|ğĞ²Ñ@9Il¸I©úØ¶Ãk}Œ)Ç½±š®³­Uâ˜…!¯¥ë‹P‰\lğfuíÎaÄh%¹ğE°¨wÊ“¹rF€8<²âÃjœ%¹û’,EÄA5I‹ÙÌ.÷âşôyx·­Aïì¿ı œ=Ô¿å¦—÷(­oLq”vgÎİ6„´ü¬ßÈõğBÀCƒŒµ¬IŸÇ\ë?	şÃ£ˆèÏa~(Êozœ:®r}+{¶aôhÃµÿD£¾é¢•†ª_¥²‰˜U_ÊÒâ³ÉùWàˆ8ÕÜÁ*t´î™Ç‘Oˆ ¢‘^»~ÃqA(ûà³U-7d½ t|ŸØóoÍßi„*ñ&—êtşM	%ÁHÊ¶D.}'(\•p³C@–ÿ¾X
Î’CäjzĞØöd ĞjA5|^W8ÑŒ¡SùB½¶U[½S2—E›ÄnÅU'•¶dv3ÒÚ‚Cóo"‰˜å=G@êdÇîØ£$~ì=.2’£U•Pêüïƒñ Œ˜™J£>‚–kĞæ7ùx§šiÓ6l[¼ m#şÄ=2lˆ«Ô\D(p.·ås<w¸«vD6TYÓ×óÈÇÌ—I`@âÚA³ô‘a¹Ğıí.dıxbÚ6¸c‰³Ó8eçÉF©·ÇÙ9éQkIÜT¾åò¡TE9—3Ù™Zfl%Aµ±kØšq9¸§‘`Ñ•éHî{Y·Ğ°¦—i'a ÑsôóÇp—1~Ğ69#Iz2ØÁÓ‹½ˆëõ:‚u{ÕÿE·?˜
E_t‚ÒÍt7Œ|ÌÍI¤õm/"j†îì`/Ûºİø¨.§Ì®Ğû¨ûŒ<GoñØÌQ²Ğc·Ô÷,}¢L¢>'ûÉß«ı5ƒ L±Éq:æ_æIgvoæÔ ¦ãÄ&Û8ºÅNš«¾twd~:Ã­*.¸OÕÂÖ¹O†­›ÓğŒ›ßŒ1mGG“íõÆ!àÉ=~,Üå&8[òås§¾ĞÉD@‰²­O÷YdŠvÊ<$Å&Ï2•”
£îi^¡R¼.9¨-öÒÄ½+8ÖYü‚fe.ç¾ğ3AÚ6øm7X9qmÖx©tÔqUşÎK­•1¬É_'¨ÚcL2Hƒ%Aëfş?¥L<lØ ¾•‰Í‚™ƒpCøP€uÂÄV”ç¾%ì½vÿÔsíÜòRÌ­ô¹FR@xº/×Ôãj™‘à“æ6ª¬iplnl×Ö?G§‹+6”³ÅGÄ/‚“·òĞÆm((ÍŸWjÙ×Œí#«&Î¬ŞV~ÑMAçë·Áß#?B‡Ú 4Ğ#ê\›9™ÂAF£óôi>ïd˜°yC>­Ì	ˆ½Mb£ĞSÙ3 Ò¯æè_—“v1”R_<cEÇ¯Ê5ü(ó¢ÖÙg÷v0l_¨ãB “^<%t5±JÙşbk¾xÃÁ¼!ç”¨MŠ	!×N#ù™pR.ş˜æ¯°¯E•İäïlZNÊß–oİã(°—cE+Ü»Ïújú±qPJ:)ièåÉq÷Ø0ÇüÊÿñ­ 0İásÎÌúˆ`VmxÏXíì.­”ŒYÂ—Õã@zqùd†\İıÜ¡=°Øe;¸­Á07Ùó~sbÅT6N©%n‘AnD\ĞòVîÀÏ9²W¬39ZØ•&E¹T1ínÀ*;ÈK=¬¨ûìJQ’Uôµ¬ "–ã[Xlwa‰AÚˆÏĞ	Û©	ºø§—ÈóÇõ©êÿš'Ìå»Eİh}ÅôKĞÁO:&ŸfsÕoí'eçšÑŸÌ29(}áOBf¿²2Ñ”@Úyƒ‹S¼ZÇÁévPğå–ÛÖµhúÎòïà€Ø74øªıÉ­êW¯e°åÖq/‘.Û»%¨wÄòo÷¯ÛE|E?,#iH.H¢ê"Wú*ƒk1y¿*9Â)?Ç	™cMîËştU÷TÅ„Á9i°Šc~Æ?ŒİÉ$M]7r{ÁíÜé‘ÿô'YçÔüT™WvE±5ñ“¿çöˆ-ã÷vchñ€×ßzuÿ&š3Ê|^	fëIğ1êß ¤ëˆáNÑVZZø¯DsNs¨˜Qùéª3£H50µÓg²ı»ª”®FëZÂ©Ò‹í™Õ¢1µ™ğoö·ÙÖjEb–5£ÎhÂñüD“}ÆF²qï¥Ís²Ú5~Bšy§›xpø¶‰³}…êÑ•>ÌHîº›½­_Á;×	B/´!Uî¥2ÄŒ¢Fã,ÇC z®¯M‚h‚P>ÿ×ÃiDb	¶.Ù†HÕ÷+cbÄõÙ²°J[À“·â›IA ìkZ|@xñx<—lÒ¶9÷KäŸÅÁ’xş›yLg’Pú&(ëŸ¾CAêXÆ‘‰ÁÒ§üŞ'+ÙŠ÷Ò÷y—ÈËfğ¡Æıì»Í£/ix[{7¾`aFM¥âè#Õ'+bÄ™f'ú1zâ€c¥É^ßƒèÍªœ‰â¤´Z´Õi§%fù^_™©Š&ÇÓAßZÎUãe¦ÁÊ]gŒ€8”‹Á¾x
mÖ§Èk±xïÃÁº¡¼Á”òÖfU&¾PwN~ûºI˜»Ôõ»K‹ÊàÓëÓQI{|­S4 ß<7ı]ëSúßÆŒ™‡(7:ÁÁøÇ¿÷Œ…ÛÓ_Jµú#jÀÆf}(9-9ÜcVÏËé| !)OLlnQÑËë_PIi²¿´¸õÕÊ|—ö79ÛÄTr-Ç$kšVõ¾Óø^4Iés{à“ƒDgm mS6×mó‘¥W˜W’<’ÃÃşÀj‚º¨‡„Ë‘|9	`ğÓÊôÌ‘W4/È¸mÅ|Jô§Ë	µì¾%Q8ÛI³#øãıÊ'®ƒfòäyWÇİ1Çy&Lo`ª£XV¨Û5¿gù`@ÏÑYNã\¤¨eª¯¯pğÅ‰óZ>‘%`¸´1©È¹v;£ª†¾¨ÒäİtoÚ•…ÌY@µŞıò¾gÓÖ¦Ó…19hÆ–Ëìõ±@Ë†õ,ÄuÀ±ODEÚH¶sRâ}²:ë2®mıˆ¼©{ÊÜPkÉ„w¿ETSëIIP÷YZ#iT…T±väÒFëÏ×À‚H¿ ”N|nÀvÃe×¾@Á…¥§WˆˆŞ×®œ9…‹W­ÖËöº’^T:…`D&jÏ&r}<íßÆÁ’ƒÄhµVVÚ"ÿ-üW§r«@§Vÿ
+¨îşãÃÏk!Å¨®&3º˜kÊHË€>´³~üMÄgS÷©[şg©Şlu]}œƒ·ºAÍ;®¢	!KcWÊR)<ÆàÉ®â*"PbœÔ.Ö¾àÎSss:İQ|W,ì9Y¿‘Å9AGCo:Ÿ2Æƒ˜×ŠIÙ{¬"ymGr&Ö
„.l—ë]…÷ƒtŸ¡†øU±) «­=¥cYâ"mx]Ïé=­ïÉ--YsâEJz“´ê¢Jëq¤dÉ½Ó=M”(»Ü1N­FsixáÒıöÿ_1&*ê3:9(˜òÆv¾t$/_úmêÒÂ¡ˆóDŸíN¾@d}ú²ä\$6ø•5¡]D…uwÊ½“€ÛÃM3ëv?;Óú ´nJ1ÑµÈxØQü@Ë’\»’®´äı™èp+w„—Î"p*†˜Šîh#ÁÃîcï“—NÚÚ0ëà^[uÚÂr©†©÷–Ø¹ö¶?ªáôC Nÿ@¸Q‹Ÿ¤C;4%»ëìÒáÜ':¼ª$$C‘íóÆlU¹+IÑA…+8ˆ›®Ù¸rË}„Øî¨ LéPğ$dªRk%sÃOy2dÆÊ¿bzÀnT÷mO›W™HûæjRLâŠ¹·ˆ°ş"iÑO…:û8ˆÌ¥+Ç=ĞuXà°œÄ…{s‰éÖB¢k^Íí“±o:+÷8ÇâBh>`î,¢ZÇğY©¬Á½ø¹/‹rÜ’ÁN‹b§·˜¥Ì Ù!OÛ2XÓwìc>°)˜yô›Í¸zŠşlİi¨e"ˆÆÊò[ŸHßŸÖ
• !,š
r`šoÚ?ÇóéäEYzÜ—K,ÁY(01jZŸò„ÇxøjÅTLçxút®ªœY£K;62û3é9EŒÄ„%¡VKSl„bk@UĞfA×U•>`x˜ZË³€Ow›çI'¦?Yœ"<siÏÊEÇÓ>Q¤áy<Kƒ·F+¼*‰XŞlnpÊàß†”šïjz1<.6,#™3ºp£í±M2½×ì ÃÑ•‹^©šáÇÊ¯3n9_Çœ&“üğfP:	CÖ…¨;¸0<kjàptÿÄŠ´'dlJì/äxŞ&>u</®Îab7ešhÁÄ5Ü‰°äÕk|zÚa.ß™fı"¢ÏáÄï¼Ş!¦tséå™íìáCÀÓy·à¸~›İo˜åà•M¡/n|b–(‚oM™‹"òºaş³¬ÓÉ—È™jĞ‚Ò]ÛéÌî¥Òä‚{){s“Ü6xN6åD.İ˜}"àÑ©A=à(.£ı#	~%á(fÒ²“&½ğnEÆŸGÌ Öî~l‰–Ğ:<ş©â™e…ÆÄgËÀÉ CXodvN_x;°)›|^Cœìÿ/C @7‰×…ÈòA<“lj»#HîŞÇ8	a¶â|(¦…¢Ş¬õğ£ÆÚ6AQÂó$¥Êu¥É‡ø$ÊÀ¦¿.z›î®å¡ JÚÒ« 9ìMENZùvH—O5v`ÄÈn@4wà²®&Š¦ª(jeOLóz…¶T7›í1×ùï–qÙèFr%éZ•®Ö<VèÄ	à~¢ğŠGhº.c§š
¥¬Áq-€ıØV»°4İNÙà?ÀåÚí½ì‰©õı1Ò'é“S8BÇbM!Ö&‹³¡–?v‹y„²'vr’Û9Ÿ¢eUvñ¤Ã°Ş×íìÔa~­o4¼À}ôÒd3&ß¤£=ÿÍ¿óØê0_:e{|»`LE.•T¸ŒêZ˜ÁE¢‰UÓyë®o{“ú_ÚÛsåzƒìîÿ‡’[;XóœĞr§xğÖÍ36›Î¼õè]{µXŞ0ÉÒâ‘ñ¡oê‚ÜrAæ?=Ò›§óDÙyorRe's E
ª™”+õŠ’²?B€U{Ÿ#Hv½2‰»ßqP†ÎVaœ&p<—@Ke£
İİàş°©×NE)v¹×
‘•…˜)š­÷Ï0Ó1"ÛÂV|9™r8äšu†Yœ`ÿ7Õ«YJ*hTeBì“bgØCTòÓ#q„{ï	'jÑ”º§#sóëâÀ(:ä¤ÁÁÉYzx„CĞô<6À±/°Ù?7ÿVo^UÌW‹!¯ö÷PŸTNK‰ã[yQ²™wµ'ù[P¨H‘Ò.È"ò!·m45Şé16ö/¬éOyJÆ+†î;q~˜¡/_êpkˆ)6¹	ÙRåØ)R;Qv…•èÕ±† ¼<7/6ØRã $_<¿Q£$zV†öUóy’_y BŞ–Bš´š!vä™+Æ¯)ˆ­ßŠá#EÔÎŸw¡¬3»áåƒ€¡¹R‹ &>˜¬'bìxù7mêÙ~Ên?%ítèŒ5ºÆƒà¿İí©ÁmwgMÅÃM­òçhİÌ*´ÆÏq¾¿Qf²‹²+©¨k¥©tª`—¥äÅt5ö¥?s4áŞ¹\æˆœM8Ev>šnG]´)>!/Í>äÊmY\è_×pæœô\éˆñŒáÈŞsiì¡ªtE0HiÃ"À_n…`ïUŸ.Ã2»7·?•tbÑEs@Ìöšè[}éÀÃ‡W R=îÔØ_õ3z„uë±wbDs@*{­×ôÎ g…N	ƒ‚åÎÔŸq|½©ptùh	³Ä¸

üÚŸöÌ0¬Pï„I¶y£oí»7Ûöá)j¥^	ª®+—¤İ¹£è;x!­x…Öüº¥âxÄS@`)ñ‰«ó*RFE ıkìx‘”À™ï8ÛYî?Ê<ÆA°ŠdaĞş,•ÙD[K‘÷«„Bu[~	çønÅ4=zN]ğmv˜  BÌ‰:t¢¬JŠ±OÒ»U–FcõR¨şĞ?İyÏ©! 3´³4vàRşÂ
{·­g´k]¼2úê­”íĞË~=ãëœ1OĞÍ9*ÍøÂ¶ÿ]([:2ê‚bú`µ‚ø[—½#³aôÒ†yğê¦ViI8…E%_^9³y?W¿svÑÈåŸgÑ³ÒBö¾Şsrş—HKÎ@Zö­âg*‡o"ë¤ÉMÔï×éÜ	×Óá?µ|®²'İŸ‹"–½fAç©¦³!U¿0o´kæšt $&‰°üD^×”ÉíÂË°Ó¢Õš­!l0§±´MíM	‰±¤h®]ÔŸSúOp¯,yWlp¢‹¡à)%+û§‰÷²õ3&°8CõJ>‘N	N9‚ÏDYƒuCpVê¬òIšğşÏ«×í”€şû’€S>|xš°)¬¼\{89­ôŒ¸²¤Å
C„k•Ø¾àã°­ÛZ ‰OÖ1F0äc¶©ƒP‰YoóÏ{ŠG¾‹^üŠW”«1l»L&‡š¨1ÑÃ`-¤ëVÇw©SMm€Êßz4NL²œ•o%”«ä…4 éáÉ·¶î{Û1kÛy¼c/
™V[:à¢A=×	ÎMÕÕ|Ñ‚˜NlX^`ğK=0-znáVay¼z~Ój_x½ÆZóh¬°İ#õ–"\B/té¡4"jÛÊè¿òÍ¡“Aßcãî{¥ÉÎ¡®F/R’Ø¯|¯^Û§u7Ó3ÑNy5í>ªNüÅ2Ö"L %ŞùIšÆ:]§¼™©5Up0J|e±X‚(„5eÆ¡U7…Ö®>ÁÚåIïÎNÆÚqFçl<ßÓ˜ë¾¤Òìô •A½$wV“VäñÿÍûÉËÁ¼(bMTâNçƒõÇCpSÊz¹fÁ¥£]v]ö*“É™ßvdİ›ÎR$w—N¬´Ã* ğk-)pƒÉÜô„¢Ã™0E$c¡Òü}}¬¼`'q_ŠueóZÛ‹+®V¬Ú…!ë8Ôæ$.–€ÁeqÆ+’”9Ü0‹z¿BWŠD"©ğÍ¦ÖºO>Ô|Ø˜
ÿø§zÊ`˜u(|ÂÙê\Ñø¤¶/è~ºÕæcÇÏE4?ôı.§”Ã…[êD¯µcSe_-®])Ğ)_í1y\TÎ²Ÿ€õ8<öÍqkö»‚Vp7ìN`QæØà'Ö™¨Aü”®¥Í>ş’7ÜÊFğ÷2mnÒd1i/e‡&..âôC,Ö*Ş<pjÃx°û–lQólA î^Œşß¯PB%#VW6n€nBâÔøŒ
%“±]¨5š|ñ{å?ÿÇ»Å•Q-ıÉZû¼°;]÷25ÈÀÆğ¢ 9Éùê•¯NG†ù1Ë9ğÍ…ı\oãW5¬0î8¿÷arcu ¸³¿µv¯¼
É‹òÛ§Ä+“dC0¥ënùm+2#ù3„HºæuH{§qÇ´Şg©it.l;ELAËU•=àÏGG'’`ºN4H¶ÛcÍÛ/³‹8-—SÚpª,•wRx:ôw_’xÕØ	4_tÅDŒƒÇ7€&5Sâx„ƒó„(ºÓ*uLÈÑ!ÁÏ3S=áP…ÕDë Ë!PAa„ğ¦vyŸÎ[€¡¹ªNübUÑSrX(‘õŞŸ¹’c‡8áéM`n0ğî"XğWœçP6ï‡riÁâ™Fn®Á.»T@ÊCÿ/¡v
5"‚~$…V¸²–Ïc¡öÿs˜Fã¡î¢«)€¯ Š¤"ğ¦ôÎp‚NgÅaßáwCOeZª†Ñ/BÔ·‹˜0yDJøş× ßÖ½€ ¿ÀTr‰SğéêÚ7J	lïÿ­wÓ<xÛFäqMIÚÂşõßÕ3éê	?Z¾ÚC=@Ùˆ]„h7AÿE
0ÿ6êˆÿ~Ç`„Á_»å[šìíòŞÛÔa‰øOş|ë—w_ºú
Ôu<Pk"UÆ"Y¿É,˜Y!½çœY—¥bk2é•²ÄÜË6±NqÏÂ¯ÆN¹N¹CÚÌ2¹„'úNê:şÅ-ûam&aa¹bß¡âió?ÌDú)îêLm>J	Ò¸ïğ­äàÕ=è»%à±”!j{6óm5T¨RËáŠ¼—­šQ×~Œ™j3=ÂÍ\ÍÕá4|2YÂ\0ôøQ/bT¼üD˜è–$Ç;Ôb³Ÿf¥[b÷&j¼`‚ÊµOÕšæ15qÉı¼›“}.<iÃ4hïçğ_9–H“kô {¢b-rOªRfBŒÚŒJxR·øÔVMÂß;¥´Ba6d;ËN¥nN‘å£6ñ{·~›;½2ô ï¿G}Ã¥‹°nîÌÇ6Ó%‹Œr«™Pä ø`·8¥ÀÓFÙD˜=(ª¬á~¥;æ4áH'yjm²”EQ[ ¬Á=e¿…¿Îæy¤Õ\ìÅ°]tÊİ$«æPçê–&ÖZùˆ½Ì§F'še¢y`=ß^6øS¾<ÈgM‰»Y`½ö+ÛQÒè’Û!uf—¨xË¥ùıÏ*³~ò`Gˆlö:±
İàş$ÂO8¦ì?ğÓ¶šØÁZ4$xÆáò«ùz•ì è£ˆ·o.:h´UM–ñ2wİ!%ì6çÈmT”»{ËÂû½V<Õ€!€·Úƒ-yÿ¦åG‘²ÕªØÍÈQÙ1[lKD´—hÊøùæYçùkŸÉäÇ¶Ö>¯vñÈ®­³1V&XLˆú¡fª&®´@˜.‹Kª [¹ÔulçT°	×˜zGjñ&à¹Ü6Ì¬ò¶~¤=/„T0nÄT—Ñ‹617j
¬¡Uc©2=â£Øo<€ÊJÅÇ	ëú	AÊüdå=_lÇ¬;¤LöåéŞı¸Mª%òË–„íÎ~äÌAêÎ³ ïØ$|Lû£‰|á¾ˆ÷ÒíD‰Ë,½nÈ 2‚lká¤}5·Ï\Çˆ»à#phÁåÃî™ö$‰Ê!#· wÒáf@‰v«®‰#l4)ûZÆÔ£Zëh,ñÈªÆe&²×Š&9—ß¶øç5ì²_/ÎX×õ$ÎòÇP—Y†¥â¯
wYŠ._B«|‰•h×&_M]­ p ±rø~ÉfæVoĞh£IåÄ6hmQ”ˆ"É€ô
øKˆ$Ñ®Ò—qtë}¬š§Ì²™ßëòxîú6qğÅŞ8e¿íÎ`ıˆ?î ÚÛ‰Dô!®²ÀDrJƒWŒ6>–œÎû$N‰İ&_,´º,¼!ü¢Aspò€O0ò–ñß¿³7"£$¹”Ê%àNköo«&!8>Ş¹%~¢~Å’>4ZBÔûH{ğ:’İ¾$àê=Zié¥RSö©Œ—?¼‡5ÿ—ôe¶q´qÙÏûLáÏr×3ªOhyˆ¦1èè1{µC}È2Vç92ŞªHb+û!ïƒ±•o¹UäpÛ4ü5ÁøL·†=·²Íí‹ÓA'ıpû¿)•nñkÔ2fwuR÷/š—n  -1p§Ì Ú3e[aFå¹Õ¾ÇÚ¬OÚgƒôG=Ñ:xé^ñªÊ©¹¿
êxÊ_Ğ'rl5ŸO²½Á?}XšíŞßx¤šelIÀ„IÒ5Ô÷{kŸhR{D™×£#z2ÆÙìÑN7ŞÖ‚„&ovšº¢S•FĞ*óò]i$ª™‰UÿJåÌğ2@7—ÁÉ'ÁŸÈ£'TŞ4fÂ)9}°Â~æÒ6‹œ3"¦£©O†5Û¡¯²G“¥Ã	ò'ÑÄHQ}Äkeú™>N·’;aµnÅÛˆùò(­?$Ï):ç?_’U*Ô5[7#<0PşàœsğİØ_ÁËøn*K¿,ĞA¸ÿ& âÛÄqŠä2›Óí‡2CßìÄ‰?e9Ú«FRe‹ÃF)ˆBuù4=j£{{D±Ç’¸6°U¿öhd3ñêãË–!£¤ş¦…^&1AÎpïSQrñõDã˜¬O~K-eÇô‹„
d–:«ßl".“vÕ|ä’ôûˆ^RËØiûşx§DLœJE÷`ríÇ‚ÒABÍ¾ğÂuV˜iXz¨Ãß§x ´äÈ©&U~'E'D¼eÙ:ƒş{¨Q´}éóO}ÆDp()|í{§À±):DU 1Õ;%9…3c7rÔêĞŠ£F1`ºûbd©²ˆŠ¨Â˜–½ç¢‡¶!ü+±µÆQ•ŞÄÁ´³d	Wpÿ‹¶jõòÔïş¤»Î<˜½!¢+ÔÁMªˆ>ÍôC'$Õ7P(˜ã1˜$ÎÛæÖ!0âz•"37‚<|ª~?î)züWşMîªD«h½LiNM#
Dßk
.yrsaÄ‰_`?£ü˜š¯LK•¯=J·êdu÷g÷òÃ:w•S}bc¥âµO_ë6ŒÁ÷ùaíÇ‹V#¿lı™å¼ÿ<@Ğç't%Nân{O"Û-¼ÆÅ€#·WGGÂ±×$8³€¨¿«J¡Ú£ó
Xb\„ŸòıS¢Â$é‚{Æe[¶w{8IÒÙ"ÃÎ:ø´ÉíáMdOgs© ‚7p¶wPd>ÏÙ…ñÆ^Ï]ÈË´Š´¶¢ôAÚ‹(`Ò;¯©œÂ‘É[±4ÅÎD'ÚP|qıª¶$ÎàÄª£¾Üo79š‘tçâ5±¨L0[—¨|yPßº…Í·­­2“,É?i­Uxö·Ì¦|nhéSëNôYêv›¾•‘²°…Œ!g
óò´OúÿˆæøgÓÚ3HNjÀ/I8Æ©xw&d ÷.1¯×Îï®ávZ¿ñHT…û˜ƒúUÑ¸Gv«4ƒ- A4ßÂ1€ÂĞcâ%b.öEéM ëésPàvØáHĞ5ÿ²°"ql’ºÆ¨äˆ¨aa7¾Kãø!1¹12ì ­$ÁvØôœ¿"Âº¸Ş¨Ï oIw}ÓÏ%»—
ÛNÑÙ|(Ø90J–‡¸¸íêz1züÎLı^ÖGcÂö]¯ÅjÁTÒq6y¤Ú@—ÊDÀ¾£9dÄú5Õú‡„'—®aèMç¨Œğ¬Óíéİ¹C¬qôkœQÄ»Bjğ#!ş~yÖ6¬ôWñ˜·Â¿Í÷i«›K}³OÚ”øyßKgtWë®!K7Iczqé§,±êa*Ú«µNÙ~Ğ¨§¿	–km3x®o„†¶Éè'½Bƒj-»‚ ±Eç}SÍŸ–ÄƒõŸ™dyVP úÄĞñ¯Iâ£¡ék›ÂóìÊ_@­‡-ÈÜ—e½ÙL4cÀÂV—1 (SiF|ÿb¬´Y¹qÕˆ­¼o¹\©--€¦%ë•z»ä»xt:ÛÏÓñ81…™ñª¶÷dBB.Ëoj±Ú=µ÷ËQ€>5¿RStÃdÊYü‚^uƒ¨ßÊJ9Çw>=‰’j¡Èè(¶gËå?Höb?ëS‡9ùîKV{úÌÂ*m¼Ó«¦æİİæQèˆÁ$IŒùÆz­Q	(ÆS±£aVš“üñ'ÔC"”sa1Â–#s- ·ùªY_œšÔ2QnFñ9;<p..¯ù|bİ+7Ñ=ğ¸M„…6½Khİ|ê_õæ{ä›­Ş'U¤Õ¤³YämïASšÿyi½+ü_VåŸ‰â“Â:Q°’é•pJíóÄÑ Ş5©%<¯v¼Aw«`º;³ +añÅ17[1Ÿ+kş’ ÍÍgsì¹¢P aMrçé Ğ¿2K§#íh]ğ7¨âM• U‰{ÙM›£uÊìJ-K`F@§õÆÿı¤r\ —!:ğd9n¡Nûc>Ø WxØ0ÏP•°#;	V~Še÷ˆM›ê©mæHwã½v‚Nx?¢éô8„á…ù ÜŸ™·¥ù{ }«r?v†6Ì3g~åY-(—§_eŞÌğÜç&æqı÷Ö?›½oRVög
I}¸ıdrcßWr°C°³ç·‚„”H„¢¯õ+‡¾¤ Îáiõxò #[Š­Ôi^g;(¢Şùø$ÖG¯Ó&k>³0­»Ÿ÷ZsÈÕwlcâ{œŒÜ¢ªˆ…Ãdƒ
z®Ø|Æš­o¬~B™i¿}|A:¡7 ŠóÊËAûEI—M<f;¡ÜÈki{²K:vÎÖp++Y±/$lO ‹Äwl%å0QLÄ·¿HEF:›÷b°Ö¾gû\¸rö_Rvœ"È”4†|Ï}ªOvånJ¤½¼*º„*Bèƒë=w%/ÑJ"r³>|‘‚²z@Fã|wbuVaéh¦ûÓÆH»Tºªd¹~_ï{iĞ¤T÷ÂÀšĞªYsÍºé½f¤ÓûÍ›0ü¦(Óéi!!—D*X-*÷ËNdQë/v³ªX‹Šj÷(o<\ø:ùÄˆ¼¤_ÌÈÄÁT…mNd ÷k­l?Xt­oKd4ÍÖ.sl[Ç¿†D5ã„a¡p–¡8Ÿhö’Ğğ˜uğTğ¸òÂÆpïQÙ7š«L‰`ùx «ó;_#‹ÿ,VûÍ'ª…O-Ä"p»€~uÁğ´°tğ†“sDEò†R¥§<¾ŠQ¾]àgA5X÷TZùºêøxâÂ6B	fÕ7zÖˆb@[k%÷RñBq¹F°—ù›Å16PÛª7Ìs>ñn×‚ï˜ÓÊÚ–ş¢lÔ|Ôi:8sjlææóNïÖ_¸6İ	ªp±Á\úZ`×ê(@³›Tsúeääù^èÆª’Ç°Ğ¾Ëôg–ÈÚr=1æs+ „z-ÂP‚$6.¡C	›Ùª¨¾ ¸ˆmQ¦"şJOî»›kiÄî,85îWô)¦VoL™(3»åpû;ÿŠ®qGoS%^"ivk¥¥1Oí@^éÊJöaúøY›µÚºˆ‰ sQqïcÿşjjÚ%~ı”Y0$¬OšòÓ!ıOÙKAMÜ£5™Ÿthb³KMRÅ„xÔÄnÂ¼Ç)†ø%~!é_i^eTL÷Yoş”HÀ®´Ú LO©µı«QÌ2ñå- ”qOÈı}›ûJ³<¿ê6Ùš9­x†C‘ís]™±l¤´XtÉÇàkğ·Ë-â±ÿMv´Hæ+×Ü³Vd'>|V“%íÛbhhØ@º&vE¨`É¬Ö]MÔâÕF€%>S)E®[[YÆìr·ò˜«Ñb²Î‡áĞáŠ›ãK¿úT(Š™¦m±,3­(Ú¸öêÙ-…$4tx	Â¾ÃD ˜¸~¹¦ÇœyC kÃçåN›Ï#%sêØ*AGFÁäÚ–¦C•°û·Ñ«Û¶ã$kŒ +U·İåëg|íJ"ö?eÆd$
ñND–½‚ê¢Â"b±†½şæœı…ĞA"®L {™^Ôè^£ªUÊÒcæØÏãÖt€PàWÛîH˜@¯›¡ñƒ¨ƒúéœ†S˜M¥¥ÕPñV÷Â2aSÿ)šVXw6P¥G$ƒLª¸ÂæMXÇ¢r|ºP¸Ícy±ÄŠ«—HõJWoz­…A¬èª|‚Şİáç	Ki³mÚOpÅñ\O6~W^'ó²¶@§ó#Ü²+`l6•VRZFó&·zG8Zm]ÒVo„oŒFµTR¬îµI}1’ß/q··Ê­“™?Bcß]ê¢z>ãßÙÍ}8‰Œ‘a6n`¿à¡ÏõÆe¯+ ¿¾‡zÖAá¹—5ÅRÉ01»¡Õ0´Ç(÷v‘:N–3à;GäJı©×do<{I ø¯Ûgb(©Gï¿|3`.Ro\®½ïjéÌC	gÇ¥R½-+ë	”g5‹Ä@U]ÉwøØ=H_ÙOtÌ­9¸]²ìiİ†!mÜt òTñ‘‚Tæeî†àë˜4cõêÕøÈ¿6m‘‚J¡³~É,/²LKiÊ)Ø£ĞÁÕpTâf˜‹:3@ğH±"GÙm\–î?5óÿª‰uY5Qçx=”oÔeÃk@À](¾Å<dÿ­¬fˆFõÍ¦Ä Œ'ƒÈw¿(›×ø~ò‹oÖ§Å3åõ•£&½†8j¾Î¢&.Oåá8ßî¹B_e`×ªŞÔ¥½M]òÛ±Àqß äÖóYÚ¬e×İ{œã®1¯XÔ©—	%%Æù†
#ÌÚä¤à‡ÿi¤¼íò4*Dün{Ì­À)²ò³Ih€ëÚî1z…´y$Vîéí#«
_ÙÅ#	L=‚öVwF#SÌÜRí- >É—)—Æ‘šëµ  ¡–{7ÒK€lîvTÊĞş&EXU".ˆQë :­lJ¸ğ	O!U^ÚÃR°»±wJ'ŠÒë¾ÂXÜ	É3\àÍ¾˜ÿi[;Öàğ;c³ùîÒœ’îãß@è éª×eìNç Nãe)…nwwyœ%>R[†6+–¿Oá÷eh`R(uDø«¢*Ø¬ØÜğ…’¶…+…ğ)p$wı»JÕYµ7œ)ùø=EÅƒd0Tö¸©—½…µ'rƒ,NAºGmâ‹ÍÌRìsÕÎ‘pªaï¢(]_æEÆğÂEKD¶tJŞúü7g®ú- ‡­	7eÌ‘Ba§ûqêËóôÈÊ‡ëKğŸ»ZE(ŸöNšxma>¨¥7ÿ|áCæc¯MÉøiRgx3¯Wç5ŠÌRÇˆ¡ÅR`N«;H`2Ìc†(.ïº*ıLô*ÚšÜÛçeqú‘‰iÆ`ğTÊZ¤Å‡½Á%m3fÏãİ ÏÄ¼<Õ™§É#«Û¶¥Æƒ6·ÇöÂlô÷‡%×Ês‹¿íëÙäğE¯İLTp¤=èyîY5ÂµVUä\£›ˆo‹ìó÷~‹Ä@…Z»OT§OÂ¨È|z–x&ØÇV««ÏœmøHJ¾{x:kpt¶<¯WşmœªJ;k!*œà Á,”©v@=Ë;oÅgÈ.©˜AıY´l ÜEÕµ‚M–íCğ[­`]{qî1–J²éFÇ!ÙM˜B››¨Y–‡Ãö×wãè•…!qduÓfù]~Şw‚Î2Î›šìmi;¿ÅÌ­¼Ñ#¬ñ-ÏØÍûÉê”aŒ…ıÌàã;))Ó’¸Íõv&ïç !Úïg:‘–¨~*5lÖ+?ZÏ#Y`H¦Ş	ŒŠ·©rIlŠ²¤azA¿¨å¿áõˆt†I;7}8)–Òx«ôñIçÈƒéxĞ`ê>Äçí³5é›©Fª3#ğpè&_mXà<Ø*L.Ğ`2¥ğ¿¶}«®omŒÅHVvÅÂQì‰:g <äûÁş'ùãpZÅdMÅt¶'ã9¹àµ¸î²Øùr¤ò¸î8Êl“ÌLÖZ£ä›XÆó§¥ª*†•I†î±¨-×Ó»%&õ_ÕKˆlÚ_ô*°Ï“é<OÁ&G°®¸¸xêIš&İÃUÔ¼öŠñËY=mn˜öÚã¬ŠĞò •/?°ù®šúÈh™:òŸ™S’ï§OŠİ[ì§kq‘¤xC>EµÏÙõ/aİ£Û&s©.qy^à& ”|®æğdæ7™§åeË}©rVÃ¿F‹ƒæu¨{ÖåÖläÎØ€êÁIcÛ“®ğ#&Æñ°U7 ‰Ïş•QBAOç€¡È!·
1¿S”<Œqè!GCtÒé´²¶áÆá$I)LåÉ£Ëšç\¦À§-^¹ƒPÁ¼ÅÖ½Ù)Vúú| öûÛ"z˜ú]‹¥{¡ÿZ¯áæÑhy~má/«npı!1:vyã2ÃÍğHÙ”WZ?+µµ&‘³=ä¢5@];+u^ĞÁ*ø¤,CU¨»¶¡«¬IsZ:´.¨‚½52Õ€¼ÕdŒ6?:ªê8g×¥ÄMOe‚¢G?bwfÜ·_hùg3ıú²e¼FLÄ3m‘ìS$*Dß9/İb™¨ ağ@J“wy-EyMÒÜ„­(¨Ñ²î»¢åw:"¼Uo Ÿi§kyå1ßÊmw.Õe±ÛÂsa7ÉF"‹*¥²8šAû$Œ…¹Èéí×IÇÒ¯§ŸnÄpby ÍËÈ!;1h·§K²é2‰ÅpwGL»ÙëÖIğ^ÕêxfVØ#-yÙá'Á¹~›;§t&i(Öq?˜ö¬Ö#¾ÛîºN Ú¦Z4—İùI#!÷]Pt>…±¦ “ÆËŞ®'ö$‰b‰yˆÀGq)ÂrÁÉË-ûc‹Q%ÿ|sz°ü _ ÆâP]nˆÙÃ~ övT(•İ”Õ·Õ¦Bó’òõ¨„Œ’Û¥>&
vBÈ¿sJdÕ7]–9Ã¯Ò£Ïı%1Ô=ŸŠ;ÎIn]­ÜË‰ªÍ‹µÑ"¢ÙM°§J«˜#kjzåÕä¥¡o}u¤Ş&ÕÌÎ -ï,@MLõ-zJ–qL[ÃxEWG_½uE–|#S=ùä‚î‹­»4‘g˜Ÿcîùxü,İşjWÊ‡1ìÚä¯V_8m‡ˆ0´Û9òŒ	à”õ*RÁT#;ìÀ²vñÙQ§
EË…M†vdH_UÏ|É|‹ÓjÒmXÈW}.°ü
K¯+€âwIn«÷	H]¥q?•qR%½%[cµ2FvÀõzÚxŸ5Ás:„`È’Ôİ•B•ù±P[,åûÔd$á-ˆç#ÇB2pÓ×ÇœÂb–aæ¬xÂE2Š3`€ÅÓ0ÍOfqÀ¯ıúxİş‹Ì*@Ä`U­*RêÕ„öùoîgÅyaİUşóo¥ÓQ0wNª2V·¥í>õC¾™í‹´j6–¶=ÚPœÎVQâä"Qk “yĞqGƒQ ßÀ¶%M&[ëËeìMu9ûöòËÈ3nÈ>šÇ*1<È}ÀRØ(ÿäYy~ÑÍ.ôÆp¡ èm¬]6ˆ…ÜŸƒu°Š„C-úZìÌÍCñlÍpõ'2ø%c5' Øğ™¹×cø¦b9¾ÄK%¦¿¢õg]½CZNåM)rö° ¿I;ƒ)*R¥±ÁŸ™‚Ÿg[¾œ¬-u³Ö…`°=‡ÜÃÌGñZL`Fí²faİxêò§y“¯íƒĞÚ‹FÃ¶‡Ğ9Î'¶Egƒ—ÅaL>=¢@qÓ"†‰çŞî OŸfÎ§<Ô]µ}…#†àf½ìÙ…ş5)
’{L=z]»ğn#ˆtDNêõQÜÛÔ0ÈÓ²9DÈ:Æ.Lqµil%¿D6ãâŸ;¹‚?Nœ¸(ˆâj®œ£({±APƒ„Åı “k¥.š8«sEŒw<æLcbÓ€‘y™åMÉÛ¡bnÈ¸òHÏ£Ç¥›>§;Êb2Rû*I>{<TÜÅÁ‚øV±Ó^qºyÿ}$Bá@	^áóoÔ…–‘÷_¤.ÕÀ 3lÚûÛ<dtç(ìùZşAc^k³#\õB“·›¢!÷Ô7‰SÚM‰Ã’›ÈÄ˜z;Æ„opßŒl’(Iª\9‚0€÷GRÿkæ¯IÌe4‚pÛŸƒ&§¼,-agXèÚbÁ¶Ô|q“ŞEÜn²Å§,~=#n&mœ"e³M÷Å¼ğQ"ÜH<Ìj‡!ş`]“½?âÒŞÌíè-¯ÿmºàP?êûéZŠÀü€ÿ3ÛH—@âJ	7Ùú@‡¨¿Ç ÃÓÈ¨ÂëBP£šS—,!ĞŞ÷<i÷A«åŠ°Ê@*“ÙÅŠ¤Ğºoz6k:®ò99”ß‚H«0ô›<'³åIÔ#÷EeiÔL@ƒà;†£*¬ş¤Ÿ÷Dü2œ”$û·¸K÷Ã4sœ¬jş¹8
Ò¦ŠZX¦.Ö‚`OGIZŒG¢×ı\Ë,àkûÁ¸D!?f –e¦¬<’ôviTÆgš,šœPÛ3Ä‡+T3qvì˜Ôeû·K¾öUC\˜Ò2 ºqØAptkgojç{i½Ââ¿VL^@—QE…"Hæ8ÒµyÆÔÒœİ·¸¾¹ä®l3é-†Ùâ*X@h¬#!›n›¡ÖÚ¾x4¤ÂNˆ=‰7µÙvDŒOO§İËÏ©•ı†Ÿyê)¤G‘š˜u&<§Ü³^İÄ6Øâkyª*}@zù‡õà²=,Ã¢°Dİ"/à ¹xõÿ0\l=4C†ü$”ÒDSAÙØô´æÅ7¶õ‚vƒ‰ÿ÷[1¸*Û@›•¹¥t\;s°0({)CäC4Ì§˜Ô4Öc8³%ëS¼ø##_šÁ*¼Ò°‹í\vËïùÔ1PÓÇ¹£}°ÛÎ.Nèg?g*zïâmEŸ8ËkÔ‰Ùa,eÊ™!ØÚ¼÷ğ<|,”ïŠœ.~6ÃÖrÈ¤²Æ7j!¾H¡î?-Î®Ä"º™ÎÍ¼.˜jGWÅo°ÃÍM4ü‚m^M"S»Bì¸ÿ‘o¥•Á‰éò*è+O ŒàÏ|Ä ñl†>·Èã¢$RœÉËwp "¦%R5”YŞ¹1 ½7œë=ë+Ó³ˆ(¯!’†ÅƒÒ^?ËÊ,),ş×ğ°.Ÿ”ïV‚c;
Ñ¤y²»ˆ¤Š "™=?ÁŒ  9?Ëà¡Ÿ\,Î…t–MJ‘{eíÑQ¶™]5Ö‡¯„e^á*5Õğ·X	—isüÿ£×mÕN¶‡k qN	XùÑ{ï»ETböÛcèKÕ©x9¼Yëä'Åõû÷Œ™à&½ıuŸMnõ…÷É4S1ì¿•²Iü…åĞsì?Wºõ²¼ÅşòÀÀÌ®âå_âDÇUSmÈ2Ge”–„R:,‚P™¦õ1é«Å{QfÃSºÃ=*Xòä€˜ô­ÜN:úóÜVa0Ñ¤õÇ:¯ˆÕÉI¦¹™‚ÏÔú¼\KöwoÄÏwV†ö¡ş Ù`GˆPCÖ‰ŠKnÖÃdùïóU[A$ª%×„v1îù‚0Ë}ÛƒbİŒ¿ÓöKÙ¸
¦'zUù”Iå(¼†ÆiòPï>şt3%ÔğˆĞ?‘R5kOë¾f_:¼RI`»Ğ×Ì‡ÅX§ğÓE-ˆU´bzw*Ÿ-2_^^ŞÛåt)Q!Æ=á‚CTSÿ˜¶`&¶%úˆ2MÇ¿"Ÿ‚5°\Jùtc»ÅrCl3¸æõ0œcÌ³d şï¾í>º|yÚ#	üİM’lR]ôM^1Øˆ¶úZ[)pTù‰‘•$ì/92Â¡ßGÆ·;à##Ò™¾
¡íË[„~E[Å{~p¢İm+Âä-N\
AşïáÒË#NV5Û;‹“jZM*ß}:ˆêœ/[7‚CâÄÇñe/í.¤ã/éĞ\ÔøëÔdoƒEËçåeÆ ¸qR¾«ÙùÍešXqµğl—¹,Òmw2‘Ş·Å4ĞA¼tñRŸÈb¦¥ÃTºvÆ×!*ä¦d#m³¹öSİeW§zf.z™Çª~øˆF@‡Ú€Áìİ!w@”K3©ªE_¹M%ğŞÃ´«1œ~‡öâáêjÈ5*Ôúş“B+nò_uAj­ï>¶çkØ2ŠaCvà
¬Æd¸Áb­ªR3wIC›Ûãg{€IœêîüØİzXGæ{fÃóÅE@2)$ÚıcŞ?è.µ,Å„ÉÍH)ËşÕÔ¿?ÎœıXˆ=‰ú¢ğñ_ê:÷,•v ÷t:ÔˆQùƒ”f*‹Ñò2pIÍ…€şÑ|èíî F¿¤Œ 0òí1~¶]ÜêŒ]|×æ±ØŸáÑĞc¿]Ú„ï9Zóà?“ÃãMøÔÉç˜}V„a+À^’ßQù:I&y¨ÿº=I»³9œ¶cÃ|…±ƒ¥o²_?Ár\Rx~^Çã¼2´à)¥$ÉÊÃêŠ»kHİ«?‰$èlç~İï•…ë´AÊØûµ³·fN{Í²>DÊ„+~;
!Lƒ!ÿâ§p­¼ÿ[©’y5<ÿDŸq:oÊ­Fxf0J…W!„oºôˆkZsv¶£ê»` ü†]_¢€ıÃ‘ßË
¸S45ıÙdZài†' HÂuu+ş¬[U;9*»Ü8Æ–§`Væ&ÔÒVÔı(à¯dõ+ÕˆÈï›<òRX1„($Å´´³ëSIîbŠ\÷Œ¿”/WZpg~1é_±åŞG)j¶W#ÕÀÒHv‡ îd°g´pİùc‰Bé±+Ø‰èÜÔÙ»:»>¬í‰dƒ¾1@—ÇwëA?ŒÂáU[èp•İÔà-áÁ…ÌÚƒj)\S?9FÄBç1À(Ÿ9¯m˜ĞÚ–4[Ş|+CIF…í·;GæpŠ{nP¤Kt÷FÁàÜïæ®iÈ%¦Wà^‘ÔcXÅÀ{~3_×
¤;TSH’óõ0q†4±Ç2øT”Û„]Z?0¬c:Ÿúa“@áBy†Â[Ïç¾¦Ñ`#âÓ¡IÕ¿Õú3ÖüÑà§2ÏÍâã¶¤¥+È5`%ø²8$&"äááù›5#3^•ƒ,ÚhÈq¿ÈòC=öåá1_ê½²,vÃiËß:Qgš©ëLß@rÊ{€â”zf :Â¥ ’³üR“Š´¡è,n‚+•](Ò‰Ş&K\stEC GS T‹q‘£ëÅ§¹ÌiÕo—'ÌÀéA€¯¿¼‘^ĞHq–$øƒ.”$psJ¹êrGuâ5¸dÜ¶»#†ÆíE7nºsóíî;Ë6>÷î.z[§ÔÆjÊ²ş|D0œU h<<iiÁçâs35]V­+ÊÚÊiÅP d]ØƒÒÇşï2•ıƒ+Ãƒ±eZÿ\^úõø[œæÇT¹OjŠ‘ânÚO=„9æèjcÛíÛ1Áˆ¿:-|‘Î0›ŠòÅÎâU_4›LïÂ:Œ¡"²ü3¯Ü­ÂæË=?¡´"Ä$:š…ÿT-»Óv¯qÌGdÕ›­±o†hÃ¼]n=ÇÃo}†İ5µp“LíØÉ ¯O4;6	ÑÁcôó•sÍY‹#=›op§ìöIuƒ'§§N–İ/(h¡á0}Œ¹_ÁU5’‘o`Ë‘ëcJÇé'"îC[†ä…'—ˆl3…Ãàbµ;nñjI3ä‘êÏ;¯Êî`JYÕ[Rôaˆ<ÎşÃhyPÏ‡ ßùUma³â'dâHÖ2mä¸oÑŞz¯È»©!Ö¬Eú²È¬Àà¶ÀË5yw;&Q¾òäÆJ5Õ&'Ñé¬Œ¤†¬,¬J“N-P$ì›Ç$â*g­äŸı§R‡†dÈy:­p”0÷ ïSÒ^²P‘Ç¬LÜñïİ0Ê®HÙ'-İ>)ß~1õ=}¯ G)»ÕVÌæT'°Ê‹Àxo:~•çoßùEê„kšÑ•šĞÙ9‹Âƒ†)èí9ŠP¦ø(ËÉåy¿¡[ç2ĞV†ƒgcT!Ì§ÊÂÑZÈ%÷!’#s-ŸºèEƒbòŸ„Œõ‹#ıŠ¯ìßoü0Î¨îüb”/" Ò!BpJw¯Èb»˜møEZ¦‚A*îê@.¢Cø2(ğ^]8#j?È¦Qg°{ëƒ£‹wbœ>yßP® Yƒ€ÿ°ì§£eª\¾.ÉÆ†tĞ“°Ù‡cr÷EZ¥ÿ÷£íÓœÑJŸtŠ²@1Âî"¢õ.Èøò£×Oã™nSõ<º£¶Ìq7¶˜(‘8Jø@õå¼²ŸF²‹Ä3ß:4ø†Ÿ¶?t_ VHİPïDœŸı´¶ˆÄø—Ò$678?¶j‰tLÈVÚ-:ßÚ0tÓ\),½ë_à\[·#ebÎÔâ1£­&xXG S´7Í+Ò<u‘1ÂDÅ';ÇÃâ3mÖô¦ƒšJ ÜÎiRÅÙßŞ–Ñé{VîK;¬÷—†	 ”âBº)–s}rÿ½;‹Ê-vT-Dã&x4°¥BÅŠW£ª1Ñx:óLdBÓBÂPñƒ2³˜4Ë¼|QG[¥{ábĞŸZÊø@[Ş…ÑúÀ‹³È,¦õX§!£!7§üÅ©9¾±@kYÁ |G°Ó<¤=n
‘¹Ÿ/íŸa±<œKoÍ¢™*I«ñÓ»©’Ú
Sqp¢Ø3Ã@Ôín€˜»{[è§†¦ï[ÿİHÁ°àÙ–ª9L¾÷“|zšWÉƒè3l
X2ëÖMg§ı;B½O‡ùpí.ÓÆ“²p‰Ì6u¥ûËâ¹ÒbÁĞÒÖb{¦8aL>ƒ‘÷ÃUÎí®W§ö°`ÔàbÌnİ¸YSã&hŞl'~R:ªé!Ö®ókÄ)¡Â{/f0oN¼G½’mÒÀ—Õ>p¹+lÇ-Qú$?lÇH¯å ıf×ìƒ‘õ€È©½ş°;ãsõ<WA}H[ÏKO ´k%{NØœÿÓá·ªˆâÛåĞú›ÄíÖßÓHÉÚ¤mÅ›-	F¼9
<X]“Š?cVúĞ",2Ú«y«K0_?¥dûe{» ŒEôVyÛ  R1Ä:qÇ3“××’0¥¿ÀüÿÂHµKy¶–»âZ‰µö›mù?~àM!·«`È‹ÖN];™øc2µa{CTqÑp2şB`ùTc$¿/9>MáÔñh?RYÄï{•Ç[İ"œŒ°CTˆá%ÎfÆpÿ/}ğâ„mD»_î_¡_Õ1èíîçzñHÆxõÇ¸…o²”)×4mv€.>õé…—Şÿ@¬ìß‚n%™RàÙÂØóéÄ+Ã&À´º™æÓSäÚ™­ŠŠUpgv´Fp¤‰‹e°SÆ7ıôò?p7‚
‰v¶d¸èiDÌz±àlìò4	r–3*•÷éÜVöc€S#°ï´*h,¼²c5-ÀÁ˜¬     FNT™í¦>? Åº€ÀguÔ±Ägû    YZ