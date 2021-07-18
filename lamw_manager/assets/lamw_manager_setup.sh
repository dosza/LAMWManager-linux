#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2748216711"
MD5="c980890c1d5fe5f52fa146d960701d5a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22640"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Sun Jul 18 02:52:59 -03 2021
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿX.] ¼}•À1Dd]‡Á›PætİFĞ¯SğuS90şS6S`—FYmíÄPòÃ»P_1ñ}U4ÍîY‚6Àuó·Y‚|ßó³ZnV7,6xîÏº«ËˆH:10V“’-äS’]üa%x”,‡í>·ä×"‡˜.³Á±Ò÷Bqâ‚€‰ï=Áu‘†¼W‰¥Sù`ep,èæÁúÇ‰Š%\ı4o«°5ò®gôÛàÅûo·V6ŠíÑeeJØ<‚=ÿÅÇ@îdRåoA¡øl¡Ç_<ØWšKr¾ñ1U#¢½¶ŒãpfåšÔ¯[¸Û¯ÊşDßıppş”.èU|Sltg¿Š#V)êz<š­ïË	eàÛI>YãÔúJñ1œŒ·×ÃbúELÏ<J½¥qÂ˜Ç¯
Ìtğ`F´Âîp±²Ş·ÆS.•5M""l¤ĞºB8¡gÎ’äqHN÷_¬M*«È¸aÏ£ÅtéÃÊƒNû›ÂC´t¹¯‚"†¹¤ƒˆûúõªºŸºßŞ>ÖìâLëUô;êc!G!÷²wºÔk^öYÍêÀÔ(±_hl¿Mzö p«QÉù‰ˆ|²1a”ş>İ‡ö’M”G„B)\vå“:u¡Û¯Ôi¸‘n­åAÒè@bÑOB<Ñ¹n…€,¯j_P—E%âú±÷Ôç»(–Q¶É­J€·„>¶?„ı‘«zĞ#c Üä¬ ÑÊ(]^”td`bu“îô­¼^z-Îş.è*ENhxáµvhƒŞó.ÎC‘ˆ‹§ï(å:y ›#QÂrq¸ˆHl?1ÜÁ*wY;à±à%À‘¸-²Êà`i]6Ò_„ÈK˜T‹vXÉò¶j*›5Ôíçô¿3c˜ÂÁ›Áq{ÂRˆU\–’ë“‚8Ó71~ŠL×…mêÖg¼ò×Š¼EÛuY¹ô4@úª®ps\`o?yL¬NˆQõæİ¿Um~à_ò'Qn±{’"Vü?ü ÍÔw[R? 7V˜úÍ_ìğvå~’<…IqËQñº¿g3G‡ÔE-V+OÛ'#ş®Ñ¯ÊM›­}˜Ü39œˆ” ¤å—€WÉ
üIïo©Ú3f  B|ÎØÃ&P ´+¥^×:‚K[	MÎg4C…‡ø‘mJ/‡»µEDPê[ê ¹«t¾1·¬³5§ØuÀÌ{{Õ)NÓa w©¤j"ˆğ)½'>~j§rL¶bÚÙC’4ËÅ£Á/¾bî­ CVl x3–
ZO3²¼QÃÕ5Ö!©Ûµ	¸W<âu“ìéP«µÖø±—j`]0®m'‘ùßzHğ®*Yù°xd=éd@ı[ŒM{ña£5)—b„™òû\,gLc$“Éé|9¨†kgÿ´"‰6º+Es¡2Åÿİ>ˆıÓ§ç1ñ>6¬èyB\$`Ç˜ûÍ…S¯i6k{áçÄô$`…ĞPdò@êbKë$<h^`6G4IR½9¨•˜^>}ÚÌ¢¸ˆEqÈ¬Ì¶ÒokõFˆõ›Iš(FğêÛt@©&8Ë›÷£Ù‡´Ô³‰b¨bè	Ë¢ÊEIîR2ÙAĞLãQmY(ÄÆ‚ÅôÓc}|Hï§vc§úé4¢Ó^ö1½Éè	Ê‰ „ò}nè;=µìíßİÕXçã1,á>3åTÎ}ª»¢Ï‰B÷.ßÈb¦išéş{ï¯3Ãö¿£P‰tOáóq€Ôß$ä¤e"KğM]håáª„oq\ã¡l_“âå}³ØÌø6ğÂV ôµòz‰ëÒî?k¼uÑ[Œ8F0,ê'vgM(‘A·¨V€:Äè²­^ÜÿßYe'=0+ö<m Ë–j~	í{ç¶ñõ @¨ç;( *3–j› á=™„PÖ’z‡ÔÔŠÇ¥†v$Õ#ì!H¬^»dÊùl_¹¨q2w‚ÓæÅ,Û`!œ£
ãmWQ¼Ù¦cuæş4q$ótÖevhaáZ)C*?­hp¡“¨Kœiˆ)úù;.GÓŸ¿Ñ_bF4EC³ÚßNZĞ`ÿ§X®„ãêÈ«â1Cız¼‹Ó»7P}[m “×li<…şØ–èŠº3±~MlaY¹(aéw Kc±T<¼»è;ÌLıAtÁ7/‚®¡ù®~††ş)6HËÿæVË“X˜ƒC6héyLÖYnõ¶—Í=‘@@á„]´ë‚ƒˆáº¥ïbùKòÿ®\zmg„ÃÌcJ€m‘¾Ì‚ûEvöÇ`ãğ½ØÊ¾|õ¬ë§aïq †JÒ1{í+Dm"‚²	ü
ÑgÄˆfáßä‡7½L¶ÒèšíøÛOz©IŠê¤À#IÙj¹šä0Fä|Ëªûùµn™j‹>cŞ(5qDÏÑ2ŒËã³UÂ&8¡§…¿œ"ÅÔ:9±3„<İÊùwv»ïš™ëüáÇ=¶;ëÅI‹ä(àrÈßå¥··ßê 0ÄÃñÌç¿ö;ñô8ûÚ¯)®¤„.ƒyæ½CäeÀò45„ßì6ÎSE…^”ËfL:Œ NÂkÙ¶!ƒŠ½QıÑâ5Øc'äK6óî†`†;nİa7ÎwÃh†çÖÇBÉ ¶Ğğ˜|_’6(’a¤À¹_y!)¼RÉôÆè¶ˆ­¤Ü#Âju±}I¨}ç£…ÀĞ~¬TÖÔÄÊ·º·ï•Ü/
±Ç|·±Óñôtb¡ÎdCò‘pÁ	òó‘T[
+xrá½ÕÁÚ†Èió497hûuáË&Ã@ì®hÂKÁ_¿‹°­Iu¡y9Î§L}]ÈÌšŒ£r€;nÅ–}ä‚àşŠe>Œí©5n¿P1¤‹¦M”U`ÈrğÕ]¤‹Å¯‡æZ: 
¬©}PÜ(w¡j¹îÿ©{P92–W´z¥4:¥F!Ä¬6?FÎ¬qDdÕHz•ÌÛÖMr£w²nÑI´D©1:$ ¹«œôuSŞã’Ô¢ ŞHK €ÃKF¯Ö°şø¬­I	í±ÑPÃ¦”“rë
U={îÔ2è£BSs;şc16œØEY&swT¶I¨Â7ŞËÉQ+NFàê„âx=f(Õ)lwÖxJo7RÍpñóIwY„ÜêF­$Õ°‰ÖßÁ>niº\Ï™y?wÈ‚õÉ6œµÿ™Fúw
{(=sg·§¬=Á,zá­L7àëèMÉ×5“¹=ŞÄø6Oÿƒ;ü¡ï$ñl­Æ#›	«=5"o4£Ÿ’0¶´1øw¨<TŸ©¸÷şu‹]«êıù»dmxV»ğÇÑáüñw±¦2;T¸ˆô·¬Åç…û¿d/v…ú¹ÔxPdç±7ñs#[3ë&HR¦GMìÒ »?ûÜÁtaà6ñ¼â‰Ñ zlÍS(9ËÈpgì"ÏóÂ$cœ¤”/ëéZBKâ|‘¬ÁIØtwbZX	èéµŠGà`:Ÿ#‚
Ñ²û­ ´ôÖŸ¦k!Ü¯„ß¶,ÎÑ{á~Úc—-ÛmÅ€Y7‚ğ¼æà¦<EÀ@ßbå®Ü<çö”3àËÇÏğÓêÒQ¬ŠÃLU0æb_r~×[å¼O´o<¨×•ĞYıÜ¯›˜ÍÂäPÉSâ:6Û«ğÕe]¬ÅŒiö9=ùËÌÖddjá]Z¦­Œ@G!ïkÿu§0Bi“eº	ß¿cò´ˆ!eÆß¯3B7î¿Ø0Hò¦Ï>ğí—ËÅ^R¾Îd {ZÊ€¶Ë¼]Àÿ¹äÉº`‹şz•ç´$øëYIM°n¡Ì„1B‰w+ò’>~´
MÑ\uHª·ÔÚì‡—:¬‰¼ã¦<°5ÒP¢ÅÉQ ‚®õ/ÉH¬Ë°’qÊŞ¶Ó÷×$¦ƒõŠ&ç€Ù¶1QòYÿˆÒfÌûP‹.Õ|hŠàøwÜHc{u:]·AÒô,V2ç“íM› ,}½RíÀ<Å¸Éı ÌHKO´´0øc‘bœ ^Á°ÙjàC¬Ó);—û0ó/wİÍş¾Q?£êF;>UÕ•Y»¨bÇöL.íºªšdÎ}Y07Ğvİ9šÍJ50ÿ j"€Ô±^¹Ó
ûÚØgÂ¦äfœ4øH ²ş0§.B*£¼eÕç!@V£Ø|¸	¶¬>ºw?{‰K‚*B©d½¬:ôğ’ÕımF›î3ø2£ÂĞM=¯-ën´R¹n`êğEßl9¿7ÛöÚÓ¾ç§E×ÖqiĞA	ËSÏG!.ŸY&–p{iPC|€-¬Û2ˆªñøpWÓUˆÍ GHi†\™xpV›vĞ8ÓâÌ”û¢]ü+øÈÆ@‰œœ÷'Ÿ#»»U3'@Lè-và¢õ×§U{Tøˆƒ&~§òW8ıŠXÍ2PÛ!ñœ¯K1O±ûÕ@í½n‹e¥t;Ô˜ió®m6¬€ŸwÀ„wÂøâI²B¾¾~ïP¥gï'G		”_#)®ì§<5‰¬a…emWr¸¥/öä–ŸY4´¸åŒh¾>ÚqÀ–ò3ÿ~XÖƒ—‚FlUşxälœjPë)wóØ‚ngzYáş+DÓ†	*ïE&Ì|^›Aí’]`,çÕ)ìz8Q?S†ÚÃ#ÿ<u=Qá|ú”këÕ&¤u¡ã @Z$u©~‚îŒ$RqšíkÀ˜‹Nqå²ÚÙ³„¾õr²©—wbW§/ç¡¡Ğ>|h{4xFïÂ>j‘è•ûËS‰>hó$z.®£ÛF.XVNãÓæ´HR`mNCW¿ŠOöùÉÊ®à>¢#
¼¯¸…ìŠ ôcÆ…VpkBâ¿æ¼v ,6º/*éNGu<´/åzïWáiö~p¼Áö¼3ªš‰•Ô/gåRíà‡½it@5Lóå÷9û3HcçNât¦Õª¬zÌaéÌkylR…ğğ.dıTu2„uM_•ëìCéíÌ~ªôD<‡¶–úÙN(Ô¾h†§dærÓš	]bb’µ4^¨u*nò'şZˆË/xKVx€-	¡–Y?*‹ÊRoİ™Š54Çô#S‰p\ï¦(¦bˆ«wö°’3ËEùbÙo£—ÆB)b —'gÆŒHID=ó#—Úåß¤~P+´ue9~ŠûÄ¿î:V|´h3¦²¾Çš»à|e"äO¼ Oia\ãex=+ƒê6~¡Ÿ·NJMh}µƒ”Ô“ğêâqˆ‡¯V$g©	€İÕ©}…ÔŞË‰N´‡…oXÏŸ²?.dYøÑ˜iãû0&¼Ï,Í0ÅY.‘42¶lUS£éàMe+˜lgL6Ë´sıQ[]Š¾;çƒ—fÇøNVq“°la=ÿ»I<pô:¨bñ5•¼Pè<¤í-ÿ¯Ò­áŠÍpe31÷ßÁzÀbı'T ™¼Œlxp±êíNË@‡l›Ìw†ÑZªTBÉoŸS—ëX4Ìl(rµ°Zpî˜A¿9„± S´ÿiİ¤ôwÏ@²Ùf]#ìËøöW“*ç…Ó·ãü‡ÌŞ³šeR˜kä3uO`‚ğ:Ë\"èr¶°lô¹£s˜ë_ ·êÒ–,ùb€c‹`¸¤Ô)&îgXÀºü·|=ö‹À'Òéø438•@Ÿ»ş‰˜ê¬Ôs7}õóÑ¢‹Í5ó§hÍüZÇö”ÃÔ¯‡^‘1%´I$õfïO4šÕşÒO‰$‡ˆêõ„ïR;¦„*³ ¾UÄP×R Çm3Æ~‡4ÊZabGŸö8Eá'	Ñ>Êµs%ü’–úÉKÖføª …R r›”ø4ßÙ—pîR]Ãº¼rÃÒÖIC×ãè†{–”)Db€ßh¶•ÔtÙ¼ó6ßLQçÇäòÆÎ­Œ‹{ÿåÁ$ é„é®Û”ÕŞ’fÁÀDl¡yÌ:q-@”Ş£Ñ4kEkù¦õûîW-•A¸İÉîÆÎC¿¢ö}¶=joEÔRìñ¡%BV¢DÔŠ‰»ô5)LÕBV%z;§©˜»¢Òt{ âşö³¸œ€¡«p¶–~ \—m<º‹¯XÁµÓÂ:îm¹ğÍµá!:€—<ïXÍó¹âÍ
%®ÍÀ„fID¶ÑíBÑÕ‚~n™CBË¹`Šƒú^ÕéåóqÿşšåPŒç’Rî§]¯ß2¥ st6N³9ö’ö.{€üµs¿Éü)O¿lOÿ­7­ìÖmÖÔÍªC	!°ÓV™É™§Æ	ÕW;ş`‰ %3Şwüõ¨ºŒg  {Ç±‡Œ­(ß„ígğ+QŠË±>¶Š;Z•q3ö
ß‰D¼›‰ñµ‘hˆOİÉğwÚÌnm¥¦ò’H×§Ã§Ü:h=•Ä¹´æÏuÙÔôÁår|ùšÌsÎS±§JÎ@ôâ¸Üü… Q@©l}¡Ğ}%%–Ù'#Ï«-»z:;¥Úy¼HĞ¢:‡zär´‹H–±É®·Ôêy6Fù.j9=9ûÄ¯ù/àı¾ÙG@ô„ƒ¶ÚnDæÑ±@a>Ï~1*E
ƒÿ~šË®÷Rjì¦˜4kùá!0µqÊc¿¦)à±;‡­=ŠèL¶ğŞSv¤nÜ­Y•UªÓ‡©m¼A%÷6HxÃ²-¯IV=P¥}§{©=A`É’&]?§İ—ZM@7OŒ·rÀª²XÀåSÙ=%ËK(·Ê~}¦á†_Î¤’ÿÿ—rô6(—Ü1&Îr}%NÈs'ŒU®ğ:JµŠ¦S·öïz'°BõÊ”æøº‘™©—»fïõ›¯p‹ld¦Ğë’ß
øo•ïülg³yC™F²iÊWÆú–ß°?Ä±ôâÄÓ¯ıe†­[8PHt¦ÿC÷áR˜±îØb„¨Ãä’9møöm}æ ßl¾}SRQZÁ?Mîà'ƒ~n7äºáÛÁ¨NÛ*XJÜÉ àWyÖ©æÕÀûÃÇ­‘ılÆŠ¿Ud’Í«šãm¨5ûg5Í8ûi)*Ôï* ®•d¯ t“ÛLô*}ªƒÌblQè
™-tì4ÇŠ¾…QíPuZz'S€iNˆÊyS¤6+Â¡ìHêœá™ƒ9 ëB2­Jû„Ù¤ĞG/±ˆqìğ.ïñë6‡¨«
Ô§Ãšm4†×ÁÌ+Á@ÄQ€Éq6vTï]p,ºm¥í¥W¿EœìJ°•y³Ù¶E qQZØ¬Æş§ÍbW²FU@@×Ï'ªb§¸*‘;ao+»C‰êj¶ÿ¹7Ä
ğ7yÿIãÄ¨	šÜÿ~­Y‰„[4¯Òİ©·<úøO¢2,nÓ¸¹ÂøÊ×½Éùÿ´}9<"2! <B´õ ­=ƒ7peÌ}É‹«åzêT=ç6ş)H«Kç˜a¯‰ìÃ„ )*’½¾'Ü©t1“î5V©t5¸Q|öG`àÌsÌÜ¡šŠ|ÓhÉ¥å¡/&7ªôËµáQ£%MÖu5ïìÛAL?~F¡H|¹ÿğ10¹2_ÅïLí—Çµ<ºõG~PøçÏ´ÿ¤ëOãısuz¿>'‰ä™’zcé K&õş AiT‰y&c²ŸsÑëÆ>…5€ì»ÈTÚsKiç›³=±Pôñ_—k›ó·êq*b–S„ûÔV¸Á/°R¨=èoñ.!¼©Áé²K;´Æã£·M‹»hâv«İ„‚aÒëÀjrqù'OÀP¥gu$R7vÚn×@ˆÒ¾<³¯î§”]Ü…1jttå]¢];(GûŠà›f\ßñ•_+ÍícùË¯©&ĞZs˜ü¬åÀx‘‘&·Kb
mnNã	RjTê½©ıÛÌCß¤ªÜİR-úìâ\«L¨Ãİ¿ĞšCUå/p/œ¯D‹D0Í‰dP8ŞŠïp1Sq‰O?6,» ·@¸GÑ·Ú~fX‘.6Õ¾á¯„LJF9nW¢¨:n°"òüÑ­9û»şv+@ïÙ+9Ahñà
qMr0ŒD4ı‘\H^m+àâóÔ¥[ºêƒ“¬“[³ÅqeõJ%I-€A}Iƒµ6 §ú4ÿ ]DÃÁq‘òºgÔÆ¼ÃOöjºZÛÃñÁ”6’-7JòîÙõ4‘z2,yY§(†£3„Ùòr1:‘s9¼VÜSÒ±û2‚,e	t²„®İ,ÂWvƒ¦8ç	€dïîªÖ ¸Ñ­}ò‘0ñ_è¼xÜÑ)µûkíÇéƒû	¦z‹\QÕñ75ı¶tè‘H8Ö5¾ç}á£ú˜p¢G©.~h‘–€ìm>î¹X¢ŠZ˜ZØ}l¿é?öZfÎ‚²»7¬½H¶€êA#<´½D]‡Œ¸´?GÕïììR³gPA“Å…aİÚÅe¼SÅH‰±±~LUÌD"Øcò­ó%ğX5çDƒ•vÀûßóršv^^Æñ‘ŞÔeLÇ|	¢JTlr”`ÔÅ†`ç“ º{ü¶WDHRâ.(ÏØ/!'Ğ3Ÿ=–Ú>¼ßÀyG~œ… œ¯ô-AÌğjÏ:öLÃû›¤â5QîtÅäKd¦"‚eLÖŠğ×OÖºO&6Ü”ÛµáÓAvTí® 4CËÒF˜t1GKz2ŒHùàjä‘A“\—XÆÇMğôŒŸÄI¯#)Îó
uCµD¯$[Ü¬f¡½×æ\&ì¾#0­ª ¸]TB>ŸÔL)CVG’ÖÔÓÁÒk²z@iVR¬ã»
'ïtòÌOz>~yæQò-}}æW!İ¥™¢(Ò).
¢"Ì*‹	ÈM-éÜì99ÇIxŸ_ö£n$-K«Û¿ke	ï=€¿ÑÙàÕõÍ]ºüÑ¸(rÖÏ/Yˆ•¶Í‚ımì»ìu£½4åº8È_Ëc:¿Îõ|LjøÛ;[D™p2šŸd5Í®]~ÆsÉ¿W/§0s¯Ø[ê7 Üÿ?ÙŸp»
¥eøh^[IîSe¿¯ï“44yî°TÖw_ó¡9Œ/²7°qo[ã²R-va$8îao'Wwf„(PÜÂ~Pßö[Ë0_>JŞT[ıü Yµvåú¦}œc§œz[„Ñ©*EŠD’ƒiÈEÎ+ÜÔüDÿØ;SºÏC°µòˆiöüÉƒàÜWÖØQÄ(â3=Û(M•·\¤—ÑçbftĞ/ğ¾Fı=;9¿túÛ5‰-Š>X•ñ‰Àï‹HZ´çÜ”êÆ!ÅïUÌ`ÛW¥­+óÅàr6alM0©ö8ÃôyËÙÚÚ×Ü
BË4!@9ĞVø¬Ó)”>œx±hŞ€‚¢÷ÅY¼¶â>œß³%ÉÊ;¯Ï}ì
Oœ±dŞú
ŸnBÁ@c~°EË¯É®”˜®b6r·n#ÎÈš=¼ËÒ"Ù§ªêÖ·î ¶-ba*†§ñJ4Â¤–Q$Şƒ}¨(xÕÜ1Pƒ÷ÖO	ú%$ A«îj GÏ‚ŒÑdŸN©¥Ö_—f€Ô'¹¸ìÚQÑš!káö¬ÌÕ÷] ©Á8TiHÊìçö“s’9-½ââ³³Í¶oã¹k(RMÄA#ĞÙ=¿¬fÎ"ÕóÄj9ŠB ¹ôBJUTu¹¼¶(B´>˜pqzˆ.ƒ¦ü;ÕxÆıKµ²ó!U]éÂQšµ‡è½èÀÉgq° ÌKÙBIÔH»§wÙì0æ¿‚··wp:¬‘a ¿ZÚ>ót¹¥ÑÙ¹13"ÍÀÏ&Ò…G7˜­t7cDKP¿Æ^(ÄŠÈ<¬ô±õÜ¢‰ç_o’µU&£‚Éî(1DMÊË~
÷çz˜4Ÿ*İrı¢·)%2lÒ>.òãê¼=„> Iâª• ‹®9—„€rş³×õ ˜NÑ(ÜĞcS :ä½ÙÇôA•·—Q°®Ğ* z¤&»šd‚£;EÙí·—7$ßÎGqyâ¼õ{¼RÕŸÀÓ§} ö¸\k²³›ì¹¢hŞ½¯³ûŒëN£BÈêl+sO]'@Wú¾‘9ç~„"NŠûÊô½ĞoÍÑlH‹5âßsÜåJ*QŠÙ&ZĞp±ã^e³ÒÀx¨¡ƒ†™¾k Xï	­îæJ4ïjwïÛN"ÿÄYÔˆK9ù¨bÏ]ÔáèÌ+¾	¡½ú|ZX°Ärw¤Y«-s°&Ò4_*œ¡3$¹4J!	vÑb–ÿÌ.:@ßdüÏG<”Å&ãk‰véÙ'ÃbâµÇf ¸ğ~Gˆ#™‹)9&÷ B<5d¥kŸ”Ö,ŸúbHÿœB ÎLFÚƒ0õ€Ûı«ĞH*íÉÆ¹.x	em½˜Â”Hß‡NË&›¡ókiÿ\¬cUê^ÕËéqzü7ÆNp;öB™u°Şcl‘-ì3_7ıqKa«0(~<ë'U¤œl+E¬Àr6ŞÙKŸMr¸±™·½ÖQ'm»P”Ãî…Ó>¥g`šÓ2/;¦C}¢	Dağ\Ãî×Ùñ,µê¾RS¸èX§â¿~®6ĞÆ–‹5,=0Â¥ÿÃY 
=ä u•†îˆèÇÒ6‰}sY(†O@N%‡\’y×	?¹åšı[!Èg¦üzeb5šLSX¶Åk˜¤á’ärq$Aƒ+«‰ãl«$€‰,œÃãUI¶ü†£ÓóÚé´Ï™T±Šàd„ñİğIà—fıVñ²RÊİb*Ö]Ùâtùmpõ^÷2¼”	ÓŸ)¬ˆX_òÍ…@‡¦‰oY9@şœû·İ‡Î×ğÙ@5FWå¬c‡€Q{:ô‚ıã
BÛõÔ¿]&{o”ÊÊ¸föšwšOFÜk•­å,âH›Ç“ºF^„	‰´/[³Úß5#Ô,Ğ	5²£L{‚mLıÜàİ´¿¼¼€	QÕ¾”…ªÙ„ç‚CÌº‡ÚSù³Ä‡ÏÑ)m‘K¤.ºáó8>İÅªä³ôÉ\÷ê+av2SÌ·Õ^ÿ¶¡¡ˆõ\º.'˜ï‘úà†—ÿùØõ!¨ğû]Ğ©kØĞuÀ™Û|ÄÄ÷«zw˜[Æ“ğ|ŞÜ”Í¾‘ŒÆVIˆÍcs?(ĞÕ8—kµÃõºtU]ÿÚ˜½_”rtáv£—À¡³¹Cé1œ`!»Ôœä ˆ¡ÇÕ¤MÎaèeÙŸ&&và¹÷%¢ì…ù·êâù¬ÔK»°¨“ätƒ%‡JÒ!Áö	&Ö6…
dTê<—ÒQü",!RãŒW`7Óg¤Ÿs_¯ÏÖıkûcäıìg
¾¼¥pÌªœu&Y7†&µ¼™®ËÚ¸T k$™=ş9uüüÒ%»`·p<…±ÿ œ<Á—Xº½ç„$mZS ”G6½`Ÿª¥‹+8ºJæoÔ‘ïÛ	ÎÍ
³v´9§H¨UÙ#Ì•Ç<Ê·ì,&4$Õ4v¤.åöD+¢	8P®ĞÅúédª8¡#ñ¦•0áRœ•‚­Ë¢İLúh‘hŞâ8ª	¢ı~]¿a·Ä5JÙªt¤©µÍâŸ@>§fç–áp™éx°b Â;àó8ˆğ{ …‰Ëóx‹4×jı®>M#‘‚À’òßÔgöë/ Øk	¥B‚ a›K´šŒ<0<JÁÜ/4Ìmi¾ö½Ÿ¿Ód/jİ“-sÊ;„S3ƒ¾Ñ£1Ÿ¢="BPJ=îÕVíšÿ Z§0»ì}­[eÙqšÚ„Eâg)ß¼¢Q8][…S ¢± ;¥½å‚^´¬üâX†iĞR4u^7ºPˆ„ÔñM0’‘îU“w8­"%Õf»úgQĞZĞ	.üf“åËe7\¡û&¤F,úZU¶ëC‡ë:÷ÈœEƒ=g&`h»İİ‘ÿœ¢s'ÚĞãX£q¹®NÓ‡»•^ß‰Î¬o°êMÁ¥àPEöBÑ\w·D}µ¢¶¾eö!/iÈÈë»|<Ïhº)yšE2êbYl3™p÷÷½Ë¿
·Ÿó±—q@$±rMØA'iª—ÎÂ‰¼]¸º¤Ót!|¨_!úÛ•ø¦‰{"uÎ0cÇ“ƒŞwuã³oÎXãÎ1}öj[ÚälX>ÎÓÔXÿp¦ëŸ´äÃ‰ÄŒh¡üÓfN11†Âp­å‡´\® mlÆş³/¶ì“rSşŠò†9™üs·ºnıEŞñJ#§«ÒE“Ì×Îå`İ%èXÕµN™²(ÏDÎÊT}#‘DMmÇ%ú"a.ât"}eáİ{§«~Ò×`kv»Ì2BnÛş¸ŸÂºBvµÊ× #r¤¹ÂWeI¡ô63òx>9á ¡^[0Ñj;Şj Ü.bõN£ğáÙ :ß=i¼k’ÀÒ³§Z6Í£J]c.L}ÄW©#sè*L”…Û{hfBúpío^ğÔ÷"YƒóÁjlp~¼I~ë…Îæz¼E\é,û®ÇHÏiĞ‰±4s©•!Â¾uŞøÖj<¦&<·ÇO8Ìu|`É\Aš¶ÔIÈßg‚OîØ>O.aZ*ËÈrê4(Ï¾¹ø€­•÷ÛödPî¶§äÑíwmY@’aÓÒ°J1¼Ù–¥Ù° yl=É'F›[kŠÔ†ÈŸ•T‰bhÁ§§Š<E:IIYU‡}D·´MŸc³‰ßóŸ˜!æu(­+3MôõµoÔG~¡Q´&€ß×Â&MğHÈöĞVı' p.Şkxê~áuõ+ª»RÇ“ê¨'.¯I½j¶ÿ2ÒµÎ6„àæË—ÊîÕHëaW¥AÓu!$Å‰:Ğç~…ş{ˆw İq#ß™éæõhÌ&u~ã¨ğÂ°w¤æ;x–¡±=òn¢©–Â#lÙç‘ªL£«aô¨ÆŞNl½.Óq
|~b\øáÚaú í6Í§öT$Š´‹ØŠ¦ÒgTĞ¨åû-T)œ¨Yü]ù¥ïWÖËåÅŠòFĞš%ì+dW—_)wÛÖoÿîséƒœäÁÉaÕ'°÷W¹ÉÍè2ÂN¡'f™-¤6¹3%‘ìšœqŞ´;¡Õ€4oDñÌ¼o	Âİ6wCĞ»{ì2øT
¯û_r	90,øóÈı×qblı6{ª7-G[íYĞîê‹F”OÅ#5ÁW¤sW£ÓiíC“íÅ=”ïEõÿÖM‹My5KÇµYêÂIT¯ˆø§H0ñQèšô\^Å9®u„İ¨¬´óÉÎu²1^¡æã‘³ÕHF£+ˆmoä¸ÎªÜ*i‚VîDH0XQ’u÷”y—ÿ¨‘ajvzöØ„:iÂë4å¨“mˆÜ‡ÂuØÇ íZFkšnğo=,"Ë¶ÍW ±zKJ„.KvÄ‘º	ë|Š‡	¸Pß8^èp‚BfwKŠJ³t´Å;ONGË+„±Uk‚	¥ËU'Ö™cÏ­¨§bÑ¹}‘UˆE·¬ÕN2É(p)'I.7Ó¥´œ¦g-`Rè×Rë£Ï»Ñé]µQxÈ|åzä¹Î-îö5'{†&<Ô¨kÊDëa»š“4a)Ü…}AÎ"!Z¥Ò6ÔŞÑ5f¸9%…ÀÛİ‚ æEĞKÕ¨ıªPœÈvËÒz»Ø•!Ÿü;¦×„œ8¶ãnFÁwêã*>>’Êü~Kv´Å"´}u5 ª"ƒ¡^ièY?ŠIŠ;fîÑ·¤‹hÒ¾}Ï^_ª~\¡M–ynñà¬qsQÒº*û‡i{Xµ’Dˆy}~ß
^EkÎ¸ÈågîBŠû»]¨£İû†P·?!ØJÁ²Ãûb¦O¦=W_¥ºùb­®£˜Íx‹T"Q%D>KÃÕ‚Öqñ¬\Ÿş Æ0aWÒU­[‡J$(B²ø}óÖ»Ö2k]T´}êJòÁtéÌ€*A@uDæ5İO¦-ĞÎL3$ÊšŠ¨Ë&z|Ù¾„ÍŠÓšK`İ´Øiø\.Ì!4åÜ4„{oX–ŠŒãŸKŞ,™H©öVä¤Õß àæà8œLW¸9nÉï—ƒ|o‹¹bCOşRzCÙ„Ë“t|7Cé]ÛO2!­}XµíÍÖùÆUAşj`³wÉš^3E	Ï½kAïe4İÄÙÔØ¨pÆÍ€ëàkhÆÌN•¤FƒëgKñ%·n^óY1Çô£iı›•xÄÇî·ı½ ÆÈP/¢~7˜Ğ>ãÖÀ¿ìÇ/Çáë8ƒ¬T9¯å8öŠ5Õ§Gá9©~¥úÛæš3kò6I\ÚÄÁªŠ¨ @@Æ¹Õ„F WĞŸ+t7c2ŒY»ü­ÅEöB_¢8¹¢âv}
ıUw,eŒ+˜/(‘›Øùù¹¹kãW¸ìô#|°NÖ÷èŒU_À®-0…v ß*‚G-D’wÅçÔÍÜªg97cŸ_] IRRCŞÔRğãŒ´I­• oà˜ã*˜J‡´Æ‰Š)JÌ³†¢JÆ%1mQqğz;Ø/zgo´
İ†uÉşVÏé§Åwb9¦l7£­¦ùm¹˜UŠ¹MÄQšGÑîB\÷ï;nLîG¶|ÏÀ¦ì˜rEÒ=
é¿i©[ !Ğ½)«‘RİÃ
£B­Mééô@“ ÍØ;à‘Ã&”RfËï¥oI¢(àC>lÍïEÑ¦Ã;nÖc=µÄe”y~SâF¤“Î >.…1æ$¯µ¸O°Á*Û1±÷=§¸ìLaÜÌ®×ºœ™Ñº1)E_®ˆ«1@ÏîGyqKòÜ„GZÆ 1óÍà€İ
+¶©´ñÿ›îÉ³Æ„ó;º0Íº½ õÆ' Ç0w_Ï62Ÿ|ª"_ë¬ƒÌMÌGô=3²üv'á; İÛ~(X,­:§õOqŒE'b!çç~'¬ã¢¡à©ŒÊ¨ñâššÿÙ:icÕJFæ’v‡¯R|Éø÷j¿ê-aŒAÓ*à:b-ZÅäpVKäßY±*×DJT¿U€º£¾êlª…R3œşì«‚{”K4°qQ­ñí±F‚vuâøŒ<>I_:2…4áÇÅ^Î5	²VëQã1ÀFfb|‘[öp2é×?rhí¹—ğşn„QÜpÄ00|'“‡PDóøOöº&ü<rú.0¹\CtDcX%%#!g‰ız-ˆ_FGM¦ò½¬iQp/‚Ø<íÚäğÊöy‹GSİ¤ cçuÙü„ˆòûÃ™aX¶ã^|œZœG4bĞH´€b*^H‘]ZZ¤$`^m¦°§l<“ò‰ß³Mìİsƒ¿Ëª¬^òsêÏóóöHN©ı‘o¾ÆÊìÄ¢UÚ¯àÂ.İL÷téy¹;áNsäùÚiù„X¥&‰şìíd„b¹=o°`Ğ¶¿ázM3Z‹	‡êzŸîË’ˆ¸æÖ_É?´sŞ¿0QÚöT0şkaK–Q‹yÅEµ°ö{Ô…y%M	ò®SB hTed÷í½}ı2qdl¸C¨K!Ò}n½ŒÏów}•k¥i˜sğšv«|¬‹³6†Ç~P¥ùúqvmÀîõü<¾úÈ"R˜PNŠÒ¿Ğ¬ˆtt'¬b\4­^ê‚GÉTâ8}É6Ñáwßg|u÷	ÃÃÎÖÅ:WpR÷jB¾?&GJè?>ƒÁ½Âu²6e:iµâ¸‡İ¼IOGQ5‚„î¥ëCÀX•èO»éqœº\vr×À9oî*°¥SLª>9‹lá  £óN'º?^;ª·ÍìKµe­‡©zPñZÏ13Áö=•KÔ‡î¢ı7!’2| 5¯ñáj§G9ÀÔ—ê±¾¶ÈÔiúìÚjÖ‹YtaÀÌ¶%ÑÚ¡7ˆÇÉ;GÇ±‚¤nUÜÒéúêóôõûşßè£¢WZKJë*ŠŸ „¸_6G Ä­­–WÒßÆÚìÁ&²®"<é\	7š½•+Î×UxPV›i¿²Ö6~ö—e“´øİàcJüIŸ,y§‡…x5u6r ¼ñ+Ë5‘ÃÕ#pÉW‘ÍªÑ9ÙE”nÊVâAòj'ï¤¼K«ƒé—^:Ü†Íù15JlİŒôò¢R½­¬sTüÁt+«‡ÚõÉ¬íÇ•Ğ´˜Øs£@©9ĞU¥‘Ë‰œ¡”)×=±8İ^–78Ÿ:ÃÙí¹±RQ4±Ín]úà«
5Y€ÆÔèécY|[|Ê^îãË…øœSÀ…ò¥¦æÍğ=ßÌÙĞ‘õÃ
*\Û9ç”U[İ`hÕZÌ®uş†€e–¬é¹“-4’2OœÜ¤á“Ü=–YİQ˜— çb·ôKAÆÇÀ’QC„ãCNiL:<³“ö^´X$ë=ƒåg M_|î,$€bËÛÑÏ‰Š$ëbº~ªdj
1½ÌzÈğ„[×ö_PC©Ú1Áaşqì¢n<ÁJSlß:oºæDéªîH®å“Ø™ü7éRBIA6¿ÂC4ƒIÑ
vÀÂ «·kWŞì“!2qNâjØpZo±á¦äwe±Ì3é`aR»Ö´¹¦Yÿ„.#Îƒëçò|b=SdÓç^˜FoÓ+v]ŠmK«ÚgÒšü,ã÷ÄMã–Šw¨ƒßÍv‡´!IP™a,ã³3GŒ
Á¹N0Eïfï–Ìåuö©oĞ;.¤hr©õé&7MY°-¾Ì”OˆpB÷Õ€ñ§Ùª;n—Dõõ4ÃÙ^GÔùÿSŸ«2J¾×&Go‹¹•œşçU|LŒX|«—!» ıECVn
{¿R1e|üonâ¦gŸgóù~z’¢DôDí8~dŠ‹Úˆ†ÍšŒî©aTÛ«/‡·ãn=èJTPJ÷­6}|^ƒwáğ=SLWèÓê£úG:ºáƒLe„¬Yj‘fnJbvÀËgy¨'¾•—TJ!Á{¨Ÿ:Kä`î„î7ÅDA^Wu_ÆgœQÃÚ"ÓóÏ–˜'iïx± Å¾‚@7Î…Cüzp1>ç©ı÷[‚ş(AùmÛóöºï¾9Kå„k&Bsr;$N%Õ¼'ß×öî…†úg\¹+Ê`™W8ÙLì `Ä¡‚»¸]è¤›-0]*~g¤|_–Fp<Eé?ÑTTÕ“v`7o—?Ì(g›Ğ[.Ú[µƒë¡œKÒí\5c8–1ó(Ø“!¸îêâ‰¥ÙXF/¡áM:Èœ!,d9\Ê`cI>´¾!ìdšÚA¸wÜóò™º@cÖ-Œ¤dÁÇ0ñğq…K$AT1Öh_d»A%R˜7ÿ¼mŸ	ÀqMœî«4¬%^CíË¢¿ÑÔã¦È`jäí­fDŠøk­Í)ækJ©B;3`+SR5ğ^‚û
ÍòsiLdã ß
4ÎæwÍ>Ë(ö@0måÛm%Mà·Œ]ùïëlmñˆ70İ¶°‹ˆãƒ`û M+¯Oîá;ñhx±´ü¯8n´¿Ş‹ò:WDàÜTîk“Z€µÆ<CµšEÒÂ6%±ÈOªŞ8M£uPıæ°Ş;»”¶5Å ÇæÄdŞîá[ÿ•;è^+ ;
nÆ_X~‚—«â×È¢ÚZ'ID0êØC‹³^S	õ((+&‚ŞÕ”¢§mí»,ãüép(hxÃ€†t°Ü-íSç 2 ƒÿ×Œ»® şœ‡º÷í (4¨ø¥J¯ÿ„¦^±Çwj˜¹*ÿĞÄ¾`oáEæ)Aœ !”Ún;;!é’>Ì¨ã!âPêÓ°ó-­KÎÖªm Ç›ªuãŒÍ²¼^B·ğ{Ó°Èùá| ~jç€®2âkAKºØ¶ßıÁŞ–ÄbPYpé×İ¢Ü¦×<sùQÜéT*æ/Æé%®ËU-} #C4KzÖûàÒ=Ï0EDLN=ßtÈD»kNÔ˜Şt.ƒ}ô·nXKouV¹|ªÃ+µ?vd~ô¦‚§„Fö€?u{×£–DÏÿÑúC>òó8<‹ñ°LŸVğĞ¶Ø‚q¤
XnÜûF0_KÔ~=qV§rOÌAH°Ø%7ˆ?€op‡ûäuN¦F#j¥ÖSó·£
èí»œ\2¶¨=!Ò	L(ŒÏ³S‹ÿsøµC“Ó)ş˜áF2ÅErÍ*Ùâˆ'vw² JÉ™ş³Z#,e—<E“ß· da½˜oñš?»M9YZ²Sñ‚"•ıº°ñâ›@| /h¾‚Ñ²ƒ¾Cèo¿Ş((Ä Ä
 ’EK9•¹^°_¡š„ò$ÌĞ9¶,v™8ß­bÏpƒêø¸hÛç‹r)ÄâÁ½$l%ÏËĞØ¬Õ6ı);nš²PÚ.òZ(Òé @0Ğ¥”e˜°‚8Ê‹ÖI2×¡YEøùWŠ?
qà8<@Ó^Ú ‘Ã`©Á9iw¶j~ÎW¼s`‘óĞJúBNƒ2«Î8ÇmeêJÁHŞû\>vbu>M¤”Å²5ˆñdG¯³Q¡sÈaˆtêéDæTÒ÷R¶Ô2¸!sï¤’®°Úû§|Æ”mêÛ‚å—@j”Ovy£mXÑ!@EÓ‹f%4µ¸Î(À …Oä|P¼ªoNá\‚Ò?\²h^-[5¨5âÿxÌğ),Ú.¥‡¦gıåpß‰j ˜ˆTöáD¡œÎUßòŠÁc4ñQ+wŠÈWí“ªîeXA£«wr¢4‚¼ÑÅ(9*ı0Ü|ú:_7İ¶wn¬„Î¯Tô k«¨y\éW€
ê²6¬Ÿôû-UÖ>xT˜©_uana€„H6Îö‰ò®c<ØxªÚxÛ¬rh£ıŠ›%ãØ%ÔlB£¡7Ì c®Ğ£Øxã}%ãñÍK@¦êgu 2/jï.”“Jœ;wà&®å´a«‘!xˆm“øİûi[/I
¡	 ®¥ ÍCö9µí1.dúÉ:Øá6sşôØÀ³Ôò|>¶Zã³&ã¢‹ùKŒÌÜbdµ?ŞÒöÛA¾:P¹J'ñPBÅÑ;ì›´Õ\ñø×nô®¨[é¨.Ü%¤ˆÌâz”s%4c7‚¤ªBä’"Lr´Îgƒù”!›æ©è@äUœşxh
ıl‘
«{HäŠ•sÑ@Ú~’^ÔV;YfÿÅúRRåˆ¥‚ A.IJ¢çÙ{3ær£±«.*Q:eå8sJp[;\hÃ
pó	'¯¤)FD0½ı0-6„2F\Æ…ÃNÛkr$´CÄĞ­õ°ø‘¬'`hË´‚ıìî¤”‘“´P(àV´&Ø>Z^•Ræ’ŠF`¼5N/Ná&¨¬8hî‘"—í2Wp³î<‘g³6l¨6Æ^£–v^ù„Şc¤QÅ±ºŞ^qcÇµ)‡í˜[Ù`è½PB*®QÉ£æŞTdÅ
KæxÔ!ß‹’’ïÊ®¦Ânt¡ MïLËğOÓ±œ8æQŠQÓl¢*A0wqïw=O%g¡.°Gpæ·¡ŞÛ|IaØ5¶qŠÈ÷Õ&¸Ál8ï¯ÉæUê6Äl1´wÎ\Âuˆ§·_š¤­œwzñ{¼ƒÃ¶s†úÆ˜^-Ïø"±åB_ÿ¿[ä0”z²ğ´T˜W;Ï>ñU‡Ù¦¨sˆ!bàı(o )qİHİ”–àMşØw”““xØı«ÎáàÜ«yWÁ©
Å=»÷üƒfÌººøÑá~¥	|¬B=EğÕ©ÿŸêâásíD~&@ùH[ÎbRîgéÜz øßÄiğô]MÂ™º†û*yÎËEäôÁÎ3Y7^„Ä{;İ½NõçB™[Û,mxGMŠ+¤ÎL~]]ûÈk‚Ï ¼hÜlM¥wÒ±ÛHĞºg³~#×W„”Ó˜¢¸Ø”iş8­ÆŒ(ã_JÆ´Fœ¸'f‰ÆÑ£o,ßºt’£ÌÿšŠIƒIÄ¤õÓP#Şõâ*ÌD=?;g¶õkZ¢(›Ë9i­k!=C—Ñ|°à>vĞß†W3'½¿šD&Åg5ÖT›ü"³ª—ÊXkg b)BØ´[èÅ„Cwñã|ê´,“m„	(s‡<KjØëhÚ)ÍC`İk…4À‰Òz°Db$¾Ò±Ú³q$dÅ”ã¿5Öƒ@_+¼ß}7ÂÈ”qbÎƒôú–Â²¹ŸÅcƒ$£FÁœe‹Ğ­±õ±¢k¤ÏÏÏa@B£Ç3WÜá‘{Ë9|_ ‚îñ¦|ßàN7¾>ÿË’©Šp±“á
ü'xsŸ‡‹ÂJşèìBd¢a.¾#ŒOãø`[*Vª¢†ƒo4óîbä/ªåZ°|é¿‹±®_Z>‡#^Z…}¡×¼–MüYê
âùÅ%X		½‰ñ=&–eèİÈ°hîû?E¦e¹Ø“aË~ŸÊÀì¥ÎWÁ™Æ7İÈI¸IŒø¨ yPc¢°PÁòWës¾ïŠ—xF ^pşƒĞÃŠÓ‚!¾¥“Z œó/¶õÑ,T©[ğ–œc%ò³›N“‚1X$à¥ğy²G0cñuÔá_D²`Y”ÎWÿğS	é7Níà	¤à1º‰çşÊ“ ü†¶À(¸¨–"JP}ÕÛU¥4ÂYä ²¶ö”‰Ä†CN‹¾ú¹â”jˆó„8úè¨¢¾ŸUwlU!¯Ä¸‰Ë*õıüFıL€‡°`W…å“Àı6 ~ »@Ç¸ä6aŞHb±'2¡Ùù„şıˆ‹^Ò~=&ªAL„·:æ ç#gáı—¦™,ÀlAÈ.)£™+•ÆÙÎöïˆ2½Ùú½"¶3r]!ÍuRIøà-NvöÃ„N1)ı‡äjÄ1rgæ¡Ê°ï.Ã)Üı%‹¥Æ{¶]­¹ÎZ=Ê¡è¨6ûÀ…©F¾ÉÖ×kÍì¹UÙ/ãŸ@ò­
4æÙÊÔß¬òñ"\v+;û´¥Õ9Vı±¸
ØØº,ç£*˜*ëÉGáĞåy®N÷#¿û‡óhÓÕ^/äÜ(K£K€g¢Ç#usàÇÉ@^¤)7§‘Íßb‹óˆ·…~‚qu´€x¹ÄßÌk†Àcr$à×=Q‡»Ö&S(N·ª«„eô­2‹ß¦J£6´R.5c)™¸&QdÉiãLaò'Š‹ŒLR!·jÇó¯Š¨)üÄŞ7†RáOl¾$ôC:wÚ‰Ë ÜM4¸»¨$• 7=ƒJx0ó[GJ£Ûg¡î‚3µ¥ûøÒı›¦0;Ù›JOsÖè¼ÚHù¢ë¢yÌ{8ÃºóŸ=o
L%›XÛ-0Ù–…|2J¤EªL†2KO¯LnM…"ùƒ· ¥˜|É§,o\y0cÚh^O8°Ê­Ÿ±Lµ Xc'…<¼3²±1{Ò\†„ÔÕó³>îYİfì—ìu˜5ét’ÎYÔ
·1êaO*™O/½8öí’Æô˜U‚v{%!ßß@gõş0“Pğ‰ä­Ià½‡~&Ó3r©;è@Ëa_. >¥óAäB³’œØÔGç´˜ŞÏˆ‹b1´7`_{Í¥*a´n)
:FNô#ÌC0h6—Åy5â ªam¬`Üİ’%GW ¤¼órŠ‹’%‹pÔ—Ló‰§çJªrµ¥Ü<ç!‹äpá}H‹"á¬j8ò|¡k¢1Œ‚„Ún‘?œ}" :%3,	UV°Áï°ñ{¿£¹Ã¥hñb2İçŸá¼ƒêÆS¼¡¡0õŒU ¸‚ö%h®Šo¶nÊşjĞ¨ÚÓ÷±¯´ØR§½e?ÿÊ‚–„d«Äj¦äØ%Ê;OÇ\»`tíY¥\dJ²!ù]Q^å_j´×¢¤Aìå¯Èòx¦­Õz³pïX¬^l ½—.6-ÅÖ/²4} ÿqç‘—ØoCâ¸iŒ'õY,$–1ÜªÔ ğºÿ¬Áü‹Œ6XGáOH$Ë¶iÑ,sÃ¹üMå‰"ãŒy)’ôÂ[*£ˆ–J¨8jäØ7¾0ìåÂT#ğ¼ğ»)@lËš …Ó—gğ·İ«çÃ»¢‹4½™Uƒ=Â¡’Ñ‡¨E¥r]eÊdêĞùã¸›¸á[6ûá Óœ‡‡dğv§s{Èá."ñ‚¸±ºhèÀÚˆ‘‡#ó÷“Úš(G—ò*×"uIº]¬e §kÂWûHÓ°¼UÌqô£oš®—˜ı[KcşÓ”›eà}æ¼ÍÁW0:WÏ†@	J…;â‹]À±.ˆæ^ì[™Úê6áTÖpÛ°ôû_Óï®„däj-ŒiÃ¯YCìc¡+]7Œ¾Û¡RÎ ;ñ¢ğ
Æ°°†Mİ$ÇÀdÍ6ùAs¦ıF?Y{2]f«0LûPĞ#™7mõúXûmŒ½¯Ô÷ğ4‡-^`3Áâ›°ÔeœF8yï¸¬³Ÿl†(‚•è±€Íà^í‚@ªÿïÓZL£›8à_­}Rn(¾¦<íyßz±äD0¯›µájŸA$`ÙÊ]â´ö#«A£ÌÎòùE¾­Yç–Ú¨–DxW)Ò?((û*OO¦çP4“#b:¢ˆ-6Ù…ÇŠÒØvWHÒ¸ì¿K6E–‰#N0Ğ‡®ØC¦eÿ]}æA´k šçkÿ°6&C`İX3¹?“z‡#œ=¹RÆÜMÑÆô¾¡Í½qÛO÷fŒS—3¤D­ş@£Ò¥cá]Ó|<wKôËª6`Qwñ;q6×LYèMÇ}^¼×)švÄÜ­¡äÑü˜³Ğ7ftµ #°ãW- ¨Nª­a(¯rßÔßôÂª„CÑ<%aÜ)äRöÆY¯uX6û/;l®[®·üÿª¾ï@˜*ö‘@µƒCYO¸ñJ' 3D/¬Ø;_{Å  ­áÚû=ëE)ù5C‰>ÿL¾88”…–ÿøÍª(Àz%šKíIË:9wxô–üZ1åÏdIe°òpö€œ˜QÓR†r¦‚©Ïnx×?‡5ädÃz8‡ÿ·%dõnµbò©˜`‰}ÆÚ¯oâqÊ&¤j>œJ!Ç,²OÙü¨˜+'¶†)µ¸ÅÑ–êy¶%>¦óá`w”‡º#íÄír± ØÒø+qöÊ´xu¦'·²Eå‚!æúãZù‰MÙR]¤³0Š‡à¤ê7¦)ßìÈG¢Z,:k£œëƒ5›˜ÑëÆÖ«Ï¼ÓHË›DËœ$.>Õ%äğÏp¸‚¤$zË×íägE	ÏÜpkÈ÷¨ëışã¬b„“>fØö¸	á¯dÕK~‹<üµ#èşYÅFš±®øŠÃºl·×<—€‰0FïnËŸjRm#è‡CÚè¿SÙ¾Fr©S
²1Ê€IZÎşd!ó,À˜T¾Ë.g^uÓC0€š>‘¹-À¦.tà;Da?É¶¢Ãr¤àW;¶°llĞØËé)Gù³Å˜<ûÂZ‡©ô¢2ËŒÈr£‰¥ıS”­~İ 3; ;÷7šR4›$^‡f‚¨{gù2¿ãsV-5#b‚»„E2ÙtKâ_YÖÌì©Pşë'`Y”ÙÒgH VåSS"JÊ+6W…mö’rØUˆ†ïÂŒ6e!G§‚ÙŸ–h÷IÍõĞ?ÏÖ{‡]x>â„]†*xMÿĞÍKUÛFøŒúšöc6»ô'OªUÈH€ä‚P'ZÅ_p,¤Ê…ŞM7ß›3›ÆÖY*A1ln×]B^Ö7ŒôşbãM^³e:úÛÀC~)ùÛ2Ö‰ûĞÀÛÈ:¤ŠoªFõZÑùT¶òfkŞpáégjÔÒšR¨+¶ŞéÈX¨mæß=’0&Ú”Hš=`º$ªwÍÂ×Ÿ”VJcˆÄôm-[f<{mş†ÿğÓ,FÍS£Á(wÒØTAË5µ.½lËÿ¥d`+=U?ÑÂ_2¯Ë ½­Ãêy
j‡4Â<-³.»=aÅèoú¶ø¯g]êVœ³‘¡(Â™Ôö±t¼–èØhxÕ!¿¥ |}q¨†@“¬ÿÌÉ8šáHlşy6ófİá%‘²y•ñô?¡s‡æ‹kÏr•—?”à”R4¢(P vŠ<ùÅOYXºÂ÷$w@ø$	§–Pá“i¿Nby²f÷ÄBÖh<Z”ÅnÄ’ö×§ÇßB	È'L?Şw,û`÷xÃW¸3œ/ÖvÓfôÚŠ€“ÄaÇü$¯Yı…?‡:…=Ÿ¨³MLëß€²ß•ÃIŞà»äKs•¹º˜Ô”ôØéœt%uJ`	¾C¿#ªuOo"~]¿Ï‡¢`zÿA¨¬á”a3ùU½N€öğÿˆ{.é¸i$ØÍæõ°³Ït²öT‡!u´6¾ºèVMœäK©Øs§¿–cÊ4‹Î¥eÍÌï¢á8êœº”’©#˜°7¼üi(fuñ<$ÇÍL¢ßj×¢‘ª… «vFùÓÍo¦¾İêÖQÛ¨{U2YXg¸X£Òÿõú+n¯S\	ä´71‘‚‡®}QC¬ko&ìÎïúlôXÖ‘Š–5ŸånŒô|#Û¸IË¼…;½œsB 2«œäåFZJ‹ê®9¼R+OÀG·©ùw™–MôƒÎdŒïG+#)ãZ}”hDiÁ»H±g­”jlÔR·¤q¸$ÀÆYÂ†FûšnÜº'~uŠìkC‰O„qà‡ö]’¦±èêäqûÙ§(_åŞäï º@¬"©Öşh‚Ï¸}%S4Kµ<µ[	™kÁ˜{1zùy¼Kdù[üy¤9‹ ”ä×í”²PâC·zß£ğ[¤[:´FB†TCbq2šÆ§Oğ"¬hÅÜ)×.¶¼EiİZ–ôÜör™(øŠùş}0+²‰N"„.qîİr9€„ÂñåĞ(ÀY×®*¸¡—8-Åì´®HD·(ë9`&ç ï¯uH2>– •¿à‰~†"3 Î‡Iú‰ãKƒ±âª,ætl¹+=I1ˆ¤Êfú-%7èOKË³Ñ.kë¸’ÖùÈìÌ–BM+ËÚiĞé¿!ÿÄZ5§r*äËäùé¶¸¡ÔúiL€ò¸áñ#cêÇÚÇÎs¿a$ñ¨¥Qà¥³äß¬Ò*Š}s“n"Rß5,P4î	Øœ?<}Hì¹‘Qº;…½ûÄµ”3zĞ™GS÷/’¿×šÚA2Ÿ-JÓW+%ô<G˜ó1¥ ¹¬GqrÆÂ6Òöj¿¡2D^Ô‰£52â°ñÂšI/Ö±½*ß–c}ëvgâ5)œMpÆÂ§å^RHE”)V~½'?Ì"ìFSÀBD[pz[àÅ ÃÊŠØˆ‚ğªÀ.‚>°G^E×€ TUev	ÑÉŞRA%¡‰¥æ\ˆ‡½ù#Æ¡kÀšW/1	4~o[Öxİ¨5VÕ¨ÏÇù@j…‹ÎÛŸ]?\¦;„gßdU'2Ù5n"\8DàEvyİ¸a|È¹ØçŠœW%À%!4j%€ÄÏšnW‘WÚ‘1 1ÓäèI@ZË“ÈÜ@)FmİN°q3/3ãNwqÔ¢‹pâ†5Ê"üˆ7Œ£{öç$„gÑı8UèÒ> ¹¢I':F‡^šÊ_1dÃéÈ@ò«qµ©Òl}äÛ¯nX~Ù7úÈ‰6ošÒ.üÊKF÷JnZãéˆÀ“IÖô;EdtglÜf±!È-”ñM>®oº5ú#ÁüÂëƒŠ¬f7ÊêÂÅİ(%:J
oîF Ÿæ!1¡ñ
æ‹¦ÏNj«¹]°îl‡DØš)ı?*x½Ÿíœ]îšJİGáÔ{ãåg“¿şJŸŠşØ «ø±.«yk{òø÷¾Ğ¢ëf®îÿ:B¸)„=•-œÖ+Ğ•íŒ¥yEŠG‚öûX=øD3djl˜‡VLQpêçÅF/ëLÆ8ößĞ·wu…Ñqk›º”–qË)R#ìH#µƒ”7Êémıuñ»¶œ›ƒµÜ?±Ò»	4]/\é S·5ic7ÙX>½ÚÇş·V¢’Aîe°{Y¯@ıÁd]*¿1øç:äh%q•¹O’¶²ú9m°×!«x:FéÄk/6Áí²ƒÀ0ÀüïFr´Š%ÃÅ(zñ[µhåû¼±{€Õ@ÏúkwkGÊÖ%be”¦Ú1KN`—kˆ¸NPíÃö?ŞW(gÃÜ?¼b™ØFıïƒw,ZB¢íÛ`É›·[íÔÀ%M¹şºCíÇ4ï×eƒïÎ!‹ G	/Ér œªĞù££Ã\d›X“ıßÄÆ?XÕ8“|O­¯ÚÎÀá,ê€—ûä Zhp|—ËŸêè(T]z¿Ø½¹!ZqwÊ|_Ë½1œ,ã"D<Ófá¥/œĞe£º‰æ]_† wŠñÀã ¨§ÖÄÊæ_…ÈÊ0BlËu[·`ÛÌÙ”5LÎwòXÛù(Ê[*šíâÉ‡ª3šs`?°³’Q}rE,ôƒVúı‚ãlZÂ®µ:š.'b™ğøÉÎéŸX×¤ÃıˆÙÿ“^&£¢ì¶‚ŠåšOLxçJãˆ”ß~yÆ®‡¢v*&*§#§½«·é{Ò&=å¦Íf +åyfß\í¸³ŠC…\£ƒg#ú\e‡¾«€Šè$;¢Æ  ÃšFiP7˜Eñ¬•1›óÃy¤ÎÕBÙŠ•ø¨êN%€ë¬U<Ti'æfik†Ñ¡oEâ¹È!*:7ÓÏî¡ƒcÕ~sß}nšÇ—›*£‰¡Yºbh3`/_ÇÓw®7›ŞÊÉêCÇÕk)çùöPïÒ?$ ĞØ
Ì´ğâ"ú(Zs¢Ï®U:¦²cÖ’7Î³ãNg}«;ˆ»İ´Mÿä•:µÌ^ï.†‚.7Ö=º“FÙùüé&¤×…Ÿ·ô)ºşŞù¥©à(=}qûÄõëó»<¼'V3Ï†2# ca±ÿ°«½Qßİ›]nEk@¿†!V nS;‰œQ&Ë× ÿœu±ƒ·÷tk°ÃˆÍ~Ka
5Lîcwûì·tè¢™ma`Ìsj×Ih	2®íİNœª†q£yb6£MlvÄµotÊ`1zIyŒÎ×jWƒ‘°Ts˜«­sf¤k§6´ ÿ¾”šƒ8QëŸÇh*µ
ÜX>ÈêğQú1GÒ}‰`~ÆıÓ §C>Ly
`BfŞJƒ–š¬¬Ù™0C!é¨Í!s©¤8c‡füÒªRB‘_<,³&`u»–õ>ÚRÓ²¼éø_êJÂªÇ CÛµÌ[&
˜%™é*î*†¶<Ì’#ã¹}ÇÆ”Û¿ŒÀµà
Ñ@[ùËlï¥Fi‘D©³©l”±0?n‚ì¿¼ß_ì²&@=Zg{Íáä¨¦L¿46º,Ò`QÃ¹ÀçBMQcçr_Òm¿Ê
Ã2=a¬RTìÆß¢-]ğ²­jOJÍ$Ù'“-ñBÜq…­x†ÙG)ã&:R_†—›¦>(	IyÉ
ñ§Fi_ŞüGg;jÌm?5_h3îì‘ío$—·’ÓDpeâ¿mëN1*á'ÛÈr')2TşôOÄ|×HÿYù~}ûB_ğ…X…g®ÜR$¿‡‘ šÁ³ŠÌ}œí¦˜Öÿv(¼èTUÉúu¥€+D¢E6fö>¦ë&:úX›5û=ı7èÔMmå®S¯°š8™gÌÃZ@ÚK bW D%;á¶8™*<††*ŸÍüA <¬’µxÜMwwXé®l,%çÀFçit!›RÊ¾Ñ®jæXáøÕvªBÅìIšİ)§MŠÑgØ*ôÖúÚÒÕzÌ*UÚ	<f0/”¢Ãê/Û<ÀšÀğR)…ÈH}t•¥ßt&	7(K¡hÖÕT%p. hÿ’¤˜]j<ø‚©Q0bÒ¡t%ù–då)™ngÄXa{Xcÿ¤~HÆ€ËZ¿”ÊsİY<_.ò_Ç|b¦ähERNë“Ôƒæİ‡3à><S‰MtåŸ±±­q¶ZÁŠ5‘ Ô’ış•ğrmğO<ál…Ÿìio•JäÀ†¹#«à2Ğ—Wà#³´NZFmüeh¯,¦¬x”4ÓÀT"…t
)Ñ9€&ËÍÿĞKÉGlíiS5‹U^Ô…Å6_z—’ê$HÀ 8^.µV1ÄX#ª!í›‡µváb/È’»[d~»o<¬pAkÀY"d„l¨ø×±óJõ>êèÙ èÌÏ¸ı°G>‡*òI å< ±èß:Pª*\P¶ÜAHÊy&É1ÓpÆXù¡ğq)[Ô>í¹Æ$•°nóš•+°‹F1›DFREÚ14l‚2Š™~zyô•¦ÂÜ)G…è€+d‹Á½wÂ×ü9’Æ»{+¼E8Ï9ËøûËò?ÃDb—æÊ7Ğg#_batr3T^ë5šox¾ê“ÿÍFİğ¸ıÂw$€Äq„]rˆÀáTo¬÷Dè4äWŠˆï1«õSÉîz6Ööm‡,]ùOÉdÿÊIG ¨Ş¬¡¯Ş]š¹ä~²äF<h«¥óŠ©¦¾‘‚û~¡¬&ıë&2÷á¤$³„æ—ûÔ*ş{Š	äàÎN½P
¾ewÀELo%‹Ì?NèëÜòwF¹û±ö(×ËOCÒÎ¥ãÊÄÅ‘Ğt[ØÉ4é<ÃŞ7¹ƒ@mFÏ¢Ë4[F§ô¹Àìì bğB¾6¼:Ê¦]Š"k$ _Ët¶¸v¢ 0pEUÏì>J×ón((_ã<K·“tzx¡…»~¾ó?Ê©Š¿@Â˜)e(ùÛ•-ËHlª×S[¢i/Øˆ¶?@¿d¨À“rA
gF³#øºpõˆ>±&@\o®S}ıã1¼áòYÌWeóìû§‡¨t4F×“$¨Ñ!o–9^ÿ€Nİ`9MÓØ¤çËè{zG±İ5„ÎO•L—à+$¯PÉÙñCFjß‘f³yZ€"¦ea_Ñ=a¥ÓĞ]Òš•·ÔìœíÂ™Øú¢Y°<äÀ»²õºçòp,¨T µ;Ğ$3;ïû„A|¼Ó9ã‘PŠúhvgÎşb¡ï‚S»ÑbëıOº¿y›İ%ÿº›ºúHÂNå.ü™ˆK%ÑQÚ:’‡Â=K~ÉÕ”¶j2cãïdÄ/&U[#JéVnu£îÎlKò…b±	9¹ƒíãc<÷İ8ïªã'!æú<üßQDYV6h©Û&ÃŞø¬œF5^M<:zjY«L!bf2bË„:N”.·¿õÍ¿øÃF¤>_ºáÛÌ®¹öÙ’Ûrµ	‹Ã¿)jzı˜¡e¬;C!œ»6Èí¹CTQè/Î›ÅK ä,+K(„®·%;Ë!£     'Êd‚„ğí Ê°€ğvÙ·Ç±Ägû    YZ