#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1216041318"
MD5="5039f9a38282aba72be95b5c723c18d4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20816"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Tue Mar 10 03:03:31 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿQ] ¼}•ÀJFœÄÿ.»á_j©ôr¸7 2U¾æ—Ø0{,¾½®è•ªt¬çÙ:157H[ö¤fõOõ$Áºhíè{nÅ^	ÙîB!m¶s>¤™4Fõï™ NVŞ10AAìÉ›ÏõÑCûş-¸¯ÑÂsÅ"Y˜H6–µõQŠT!X©©T» ¥3ê¶1:‘n;‡@c§—†İ›Š&Ø)³ƒX‰3Aè(Î&ïñ0Ü@l‘ğ©ªá–’õôÔĞ©zº|¤óä&‰÷h…Ğ®ìp¦£t®mÔYLÕ±…i-„–	uº2ùE hœy5	’O+ şÄéÍ)È¹ ¯üœ!lïóˆ4QñSÃE…ƒ,9,ããâ›ş=k: 1ãô"?‘gèXD¨Q)*£ş]ÊÕìPÇÔiÀJÎ%n¸Ò}6°M$}9b>¬ÔpË Ù‘)>æàÉÅT½.¿ê–Éœ›Rê“äšÎá/:³*Üõoîülÿm<6îH›ˆ38bkÑ gD“’„.¡º`¿î“êšâØ%høîİ='"š}ñ
5×_‹´`@ùaz1XWÍn²°í» :¿Õz‹Mn»:¼^*ƒ‰°CYX^î*ëƒ[£_j©àê–(ô›g¬ş¯Z¥$LñØ¨jÛ^™Í)_ºù/Dhfë§[8¢Dà4¶dª‰ŸFQ.SHiR#ÒéØÈVc_}ÀM+a*ÃåYBÌãï‡û©eàÚÇ5†˜Ë]ç£ÒÇ> ”\×‡Ï¦bÈz1ËPÎ ¿#¢ØğÂÈè"bé“­óW¹Ê.$„#Ò;#&Ê{ãV ñÒÀ±A$µ?ªÆG6w´f¼âÜò»®yÊ‡IÅ!¨ãÃ·³û:ìæºç­²†'mšrÎúD+™¿’|*6ôKNÀÂÆ~†ì.ÆqCHQL›eÙüG£‰â»W¾Ïƒˆ™ğ£Ó­®Á)¤7½œ½¼¬ .œO,mllÄÌÕi°ZDh ºÊdw’€ê·ß??Ë†~Îa¹t¤)P“Ûx÷è=U4Yœ%9(B³0qG™tëÊû5¿Kôm1ÿ¾A-†DdÂK (•k«Ëí ¦æWy¦ìf İmê²øõKŞK8µæ‹y–ƒàah€¯p‡2‚‡·°’_Ø%¢$6¶Õ
£İjà‰/==àãëdxn68¬m
	Jÿ~ÀB4'5]üÊ-éÌÆª7õkáR=’„®†js·¸†'ZÇš€÷ÜÏ®8¾vêzxF¡tW'Zï ÑP¶Ğtˆş»nõIúıÌ0•šÔo[u_Q É´a·şè„æx5NÈÔpÙàBÊGé—l¾¹wä1®‹Ş›Œ—ò¤¸‰£ØŒII¬–¤ÈàvT^š‚pc<•´ªØØe†ÀÔ–~õ·tvVÙXGĞxõš7¸yİÅ7ÄÒ_Ñ°W";¿/7¿(½öNpş¨asö¬vë ²7Ó¬²¯F¡„_¤`¬çè¤…¡¿œ[
³häg.ÊU¾Ç“bĞˆ1²Ò¢H÷§®ânøÃDê›µÁ*[R@Ş?$´–OQx,6]ÍÁã†¯ñ¹T¹"¯ÒL¿!Oj;¬yÏ/}YíŞÇÿÅ^*ÊªÊ ş@ZúÂ>İŸJÁ9w÷>FÇ8ü[Šõ5‡‘¢#, xYVw÷Ö÷†à€îJ’lçŞ‘Äˆ?FMKj-;Ü~"Îµ91qVÊNBtÉ‚štx‘˜s­È±¥˜ÖğÓ{œŠ¬§¾ª;aE\slåïÑŞüP`-p«Èÿ,J<ü\n¨óÆºYzkåC>áàuû×ÕÕº&öŞXÏmÿÈ´Ï™[º0k s"{rpi—x1áO‰0ÁkåÆqqÓû û¶šáƒ%œ±¢u‹
‚pì4¯gÄØ¨ZQc3,Nú-Ğ®Öù_ÁÒe¥ÁÛÅopù6ËŠjæAõĞ«Sâ×2D{SË&¥ÓİÒÕÂK^\ı°Ó£ÇÂÂ±2}\†lğdZ”ÁNÒ”Ş»w¬²<÷Šşuà*•Ñ!ŞR.Ó©+§2º‹•Ø|¼JªÕs+ù–!hï0…< ªucZä)×ÉÇª#6K‘y×ìÿ<ØZ¼D©C’e…Ao~cp`Ìbåêäİx•V­0 ™Ô¦æY˜û457…º!Çh°TØ…œçCqZVWsyØƒœDÈÌ ì7OníÖ5¼#r6¿>¥Ãê97V®™ÓßÊ˜QÕ¿ÒB[—	e¥İ”˜äÛ¡=wî5)‘5g?X6 )Äw8”±' ‰ÃØÖgrá£ñ»jlÖ¤–<uzÜ`ğ.É+À|ÂPš°bF3åÙ317ıQÔEv»càß°quz"˜¯ŸĞÍ£ñ]H=‚ò2¥ÿa><q+0|NØ²QÙ)±Bm«¼XhzYà‘´¦5W©Ù¬?éÄ³‰lc_¼µkäEÕ0N¼"òoPŠ—Ø{2Cœ˜!Æšßæá«úO6/9'7|pÒÃ?´¡LzıÙq€M_·„XâWÌ¤í—˜¯ğ#!òµålÄVú·¢¾¿ÚRÈ'‡sñ…i¸ôÕ.ë’¯üAÜI‘lŒ1›Ç¨˜•8mVÛpOÅ#ò­/Ö’éd¥“kÁ8/ÔtÜ·;2_Ù'LÿÔB!°°.êÓ¦Z&ªÕ“Ç¢Eøß3­ÙÄ&ÃŒÂğŸ~Oö®İRgÁ}f;åš¸º6ÛX¾Ô°8sÂ	ìC&cÏÕlNV½«0¾ŒÃzwAãÍ*¾«*èèÔ¡‘¸¬”õ<Ï'øMã‹¨\sÔxl8½A¾Bª¹1´á‹Ry¼dIÖªNm¢ì9ã¿Î>zÔS"|‹ÇÚl ±jÓÖØpxğşìäüK@bŞSÈšôù_%®Ô›O›GäVP³-9öæM2/1qGP/}]]Âø¦EMÒèøR‘i—,ÙI‘ËC8„bfvÎ}ßdÀÁ^–,EJ$yŸ,soÈ¹È”*¿å8“ÌÎXÕ7 òÓ¢ñËWóô°Ôš±ûÍÉ™U"Åp¦Ï°…emx÷ò6X\ÃNËSa
^8lam¬£Àà{êü{"ß}ÖÕ”Üí3âqIA}&¸	e½Ğ>Jş8¡š{PÖhAsD¬ZæçÆi"rš{ì%íx´'n°(ßñèkU<‰®$ş‘©
ğ¹uu·Ë9¨Ph*©(eşqsàŠEhË¦ 9¬½™õçú»YèûïõûŞGÏ >3gDãÊâ‚s‰{ôTŒÓ.v8v\X´Drë½ë¡^L*Y‡'Œ|¹p\QÙÈq¤Œà`îöâˆ¼›‚¤Xıu|¹çğPD–„İöœ=ˆV’ X&êèvœ8Ú£¸éûÄªÔ#bG{›¯‹ ¾[«™†oA¯N`u±¼ğˆ—°U+FUšDP±ÁŒ…¥'îıåffQdÜæá=aßÉ2VÏ!Æ,0=›W»Y(ã¥üØQsjs&:ºL-uí’uY¾bÉ–‡BhD ¥eìx Iı;šj9ØZB40Û®Ëmu±º˜Y¦	ŸÑm‘¨Êê“ñ²Ÿê{£> …ÌÆëI;hÿ‚#«,Z˜Õmİ!té	Mleº„$åóL
E`Ë—‹Î¹ôB	,[+«ÍHûó‘gp(‰¡Ôá·Ú=6BÒ”(Î+-ø±‚GÂÇu¾àëHÙL;„ËÖ”Ø”r–%ÉÃ< J£u>Ü¹ëàZtƒxĞ<S[HMe‰¨e9ñCÉÒÙ'é»‚ÅCâD à¼²<´4iî„j·ó¡áö©GÔh?BJ³ÙÍ¹Ü‚sTOÁD?ùt~úŞuã(Ö2è[æ¥>cÑÊË|ıd@ƒ” ÊñÉäÕÓÌí¡5ÜÏ¾æuF¸q£VçiáİâıÖ&*EÜ\€©ëŞ]¬¸“bE=½&@„i¹ä]ì{†\ßT¬|#Çiı@Z6ÙÅLİñ  E÷Ğ‡gûL#ØáÂÃü^»ÇöD@V`/ixÚC†Ey§U±ÅtxïQ‚D–@Œé+Å vù²ØSëÉŸ¸6¢|q`ŠCÇŞš§dÉ¨&5ıà}C´V/á7_HÅh¼½í¸‹«¦'xß¦E¼û¾È&®ª…®BM°ÁñYˆÌ’ı¡ÑJ*ˆÊé%½˜Šb9*ÆtO°}‹'ß°‘Øh‰ÂX+ÖºK–ƒV]£”v<€Ÿ±5öR¬ËgfâMÑy±¨sº0Àw»¿³éÜE¼¦EŸF’TN2âAÜ>µÜ‰IHQ-Œ=hÜœõ7+¨ÄF;U“G"5Ş`X$™¿'–o-÷Ÿ­úÈ¶¯|dÈ¡|ÆïI±?É;Ix<qBtx5Û„¤ÒLÓôGe€7“ıHç#Ø¢ÁÿÅ‹sÚ/¦ŒŒÆs$Ğ÷>V”Ã#
¸½~²¿ÁÀ‹Ì\¹B§­œë2ã?fw4wGâÆKĞÓ9ñ¦}ÎMÎn»n¨×Î‘*±1£í6·PCMãÓUì[õ—EsCÁó¨²ë ½ò‚P’/v®®“DCšÇg,à½±â$H”üõ‰§/éÛÂœmÔY4ÁïÆšßQÉïá¯é\³FUÕóÄ`£º„µ}B£á†¤³Ü [7Æ¸¢0OŞ‰«­´‚¯¿Õıà=Y´”8ÎïSÍ§Xé`‘	BÉO«£4…ôÅ<Âu9É åéDa, Ê+ßI@s¨w|‘ÁqöO;ÌêIrK…gIÎ…YÒ1ğ^¬9İÎi0%ì_7Ã†­ß‹å^nĞ;‹J4èÆ•±ZPz*r7)¶ÅkR‡ş*ïìúUâÜy_eil†ö¹oKÁlõÙ× sšŠŒöïlp¬£Ü“††`•Î¾Ğ£„ˆ@]ZhĞ«ÂD8
IÇº„¨øXÓêŒÁ-9c`Š”D
)‘¿µøˆ
f›*¡ÓUàÈ[üáìÜô{®'<éö<Ä<¨õı¨-üìñ­õ©\
p®Î~nv¤”1Ë ©¼JtºÒ?.-•‰·ş8®<ºiËÛÙyëÏ—1ÖSK6Ò#úaXÛIi5ñPçlZ²±"Óç*ñâJ5¥t[*áö>[Êïc|·(qÆqM$oàÕÙú6¥wéƒÄ×ä?/·ŠZ(j% ÖIOÈ{`·ya5üÉŞÁê“Àû©Å’ÜX£ákj±hr	ÔÆ#¹¦/ È³?€ñoì2—n†³¢¡Ÿœô§#çZ%™ebb"*™šÚ,E.ïWÉášó-Ş>±ÇáÒ¸™Åc˜Ò·^áë’¥ôzÔğHûëóRaôÁÕ<mz¨¢ä¬4Öœš^#jŠ5µÂ*ç 0¤qA–õç5Æ›1Ä_å~eŠÕ‡"°ë{8Áƒ4ôÀ¹áÕ9»“‹¹Œ¡‰ŠÛë¥H†Â¿pÂˆÇÔÆ°ºË^Ô“†yà„¢]»u½‡œÆCŒ÷è£uiêün®²w çŠîr…¿¨¾6\Ç4v~¡K¸ëUÆ¤îÅí+¢]ˆM¡<Uor§Ú-›zNrhªUÏDÖÛ#N:+vMb"Yø+jO/hqç$QY}îÊ(ÙÕØ “ÔrÉC”[îÔÅ€êØbò—rMê³îo	²ÄUİí•Ï˜Eñó5õòÜ~¹Ç{`¢hÇéXclÕlp>foP€#+|N7•9±ƒçe[‡µ¼ëúm' LL ÍWÅÊ)…«›Õªµ7İ±ú¿ÌÒéõ8:AÈÜZœ'{xZÖ!16˜N§k“ËIZ™ŒÊ#6ä#ÉÃ~PZt.™&ØBüœç_^§RTuı(ßÖuY‡$óa4z8&"¤=ô,QæÔ3+:‰8Î‚<ëÔdİôj¼’kÅx’láÈdG_ÿ-“iËçÔØ±§,0EuÕ>)yÿÙëd¼T·»@Ê½"ÆÌ¿s%ÁN‡´LK	–rá¸vg~Q‘ŞzH5}x¼ ç€ş;ÅâùjNãËåK†UH¼üŠó$KX«>h°"Ä÷_×¤äVEÎ!"*ãşóÄ>Ûo[¬¸Şùƒ=0fõç¸€¥[20“©ügìÔW¦ÌŠğe*sÙ¶1¯¼®ñ(aDÌõ»LcÏ‰	Xí:¼% iN¸‹·Tó™`EhGÇí’q†lÁç8©;¹4©d‚´KøÓ ½)#‹\í”F¼™h*‹I):ìaHkë; ™½±CØ‹G ~dµ×Ñõ\¹#j)jeàfÜª«uì@ÌW!"ïĞS%¶UòÔ•„·6U?y	#ÆMº>ã¦ÎUÆ(ôğ»‹İ6ö-“Ç©¨Ø„ñÚ¢1NÓæûô2=i~bQ|÷ °„©ÂœßHş,pß‚ÔÈá+Ö!¦å/÷è[lh¬fÕº1„Ü€ï¬¶×£MÏ>û\°¥'æÛ©gğU¸]’úö.‡üÀxÅa¸_ş-’Ù T„÷Ú4/i’Ã`“h®^jÉg(Ñğ;él"cã&n€üçzQŒM>*ÜÊâöfĞ¦bgnÕ¨a)?S±±(Ñı^¤ÌI*Îï¬ByÎ®çaCë9—=)ÃXáÇ3`å>#*ì’#¦(ò° N9_Ãô(š’W‹§ımôÚmUR#T#î´­«ıò-»WŠP2+ÿWı€Ï	„¨ˆ¿ˆäæß#’Úöğ{c½àAêüÒáì¦¹fUP°§qF.[AêsâÆBÚ ‘˜œÌ¡+ü•D¡ò(‚èã^Uz¶S³ƒ…Ã‡&ş½‘èÅ“jL†‹âÌFüÀ…¤Bº¿àv¾o·©¾GÚ.8ˆ	,‡O!
°¡p3ƒ<A†
)ë¢û8ªíjã¥%X¦êL1Ã|rı_Í ‰BgŞÚuÖet´cKÅRWçŞÏJØù»aµKà…‡³èÁ&Õµp¯šúğ"ºÙıi)7È¦G<mM-Ú§CÂ!ìÖÆèÑàĞs\åˆl\L¬s“¯_½\ TY“ÓÂÑ]=ZƒˆÛã³›áèéìå¡k…!§ú¢y«ut1Èá¿ñ$s*8çyÒ º„„¯“oÉ³Î¶±dh@­ğ4Iyÿ~Spüı²–ŞÔAûÓ_ëU(l[}ú3O<îÖZ\Ô"Fš\á€ä‚3’ñ•1kÆ÷l£ÙM®+ÅcÒ¦dfˆÏ„å²0³¢ÒN¨š
Ã%ø‡…Í"ğ¿°hwn…ˆæÙ­­ÛP5«8¯ë¸áqkeUiJË¡aoËşßíĞÁ˜ë=gÿßóMşç>Ÿ·tpn<¢Èa:ïªÄRÆê×5Öâ¾OÛåı™5¸4Ğµ›éª—5G`"ºrµGáåé‚zQæf9ïl¿§Ç‹[ °õyÜëìÌŠqÄ……ùr›”{ ‘B}c1 'ãM’„c\Ç³˜tg*¥&\—§ıóî‹£ñ?œ+ŠOÙF¢s§-Lb'B+÷ƒ+upÎÆ^¯c.Îy² Ì<ãÁbm¾)\èköIŒç„XHÄiÑŞuõ›rT¹™¸$®A¤·]
¯ÉÀ±›18%2¹1v5U’Õ§¹-*LæLæ$é_ÉVí!ÒäöàÄgÇçšm‡|¬§‘S¤üZt`|˜ËƒD³œ¡S\£8~Ìz	3×İg_I‹fÓEwŒ´[W¿±MƒL¶x;ú‡HÀ¾Ô§p¡t©—ùn¬Ê,š"by¼“¡şëî
àƒË„}êÔ€Gò†S_Ã!W.¡·Ô½›g×ó:áII¹wÅfªÀMñıíÇá)#İ¹Úì\Œ¨å’<±ÏÉáe’€ÿ‰?×¼”{‘´†>!aáÖ»ç”ª+ö¾,ó­¢M¬¤~ ÷ˆå(†è?ÉÖZÚíÜzÛ:à.ä«a¤]îÖ‹úH¦é=#
IS ãØØ1½I¾Šâ@;èêŒÓ ;Lªİòê_ƒ4kã9ˆ“Z-Bw63˜ p¢¢çÚîÑÙ=æò ·­­ı€ïù±}Dmâš'·]6‰ê@ƒ”Iô¨y¼z­™#è}¨ƒ[8ÿ:„Vó ŠÎÿûC÷ ‚·ßá@ÙæRÅ§ù¼ÕZhã¡QYõ¯û§×» m>‹k‚@ÒvñHR°¿x	óG!£efq>ÁQşæ’qQ
n[‘ã£ı,8Yæ9öÂ¶Íp	|ÖÈB-èšfø:¨:‘NRîš²¡¹]$	›‚ÑS``¢‚¥^v­,GÃclùÜ‹_+Ë°Ho¾˜7í&9$ß–â4*‹¥JFõ{?÷Ox7/ù~-§5eûªü«ËØÁ?%;®x5Œn  øá¿`z;ÙÙé*uÅS^hº½„^ß	4úwÿÑŒğVÂá`õô+ĞëbúŠD&êùàÛ¸Y®ØXUàœ
¼V—õ0#ù¾bª¢hœ¬şÑ•Ãüw¬‹©)¸føñäØBş¤«AÿP~GÂ‰ĞÜZ—*ëİj£pğĞ2ÁŠª[·uÃ‘èjk&>º3°a®U±$¬Ú²¥ì›ml1Úç²>æ­J!¬ıÍQ×Iùg®ã2 ®¢ŠÂPFOÛªå9Œ+üd~ï\©d&’¥j%ÇQ­×]Á‘É*¬e•´"/›-^3ûã<+úŒqØt,°9–"%È“ğBºEcœ"i«  ÆTšfmqIXRÁšÿÒ
ÿ=ó±’ßoê«ñ›3`7z&9Úï”œXQË^‰Bğ¼”¢²šGá´WÜ)ÒcòMm³4Îï¿ NªüO•æşÚµ&hç3À$Êbw‚Q–§‚¨(Ùüºİ·ñB}‚ğ›hs0À9¥á)x™È5Ñ1 :Å˜ì~¦+,ä*èşƒkÄaî7e6I\‘h9_­Í0‹¸|‹¿/Úõ”ÌĞvek³ª÷½Ÿ!¡úÇQã±¶k¼*g-|¬“ïŸÔÔÃu«µ³“6ï…Uøg}ö¾^Igï0~hWUüåÂ~“vÂĞş± Ó˜m]Äéù¢L…„aÓİŞÅí'Š+X+ìƒì÷º`h 6Uøğ÷âa÷.ÃaÙ]é«6óÛ*réïş™5oÎz²—æ îuIZ»øh}OC¿é%•™7İÖ+§E¢4n»?³•'"H»	âL{Ó÷^ô‡Ø	TcN¦¶âY—ş'I×vd‹_‚ÿN{£±àÇpô@ózºÆÙFkê*MáI…á¢8Ê›Œ(şƒ5ÆDcâ Åã^EuîSw}që—b}4İ×$ âÅf\–ğ³©Qœa>q£‚– "l‰µYÍ©ê¦È˜úñ4z&ë‰Å˜WòZ¯Â)íÛ·O.i?tä¬Gy]®.Ÿ¿øîF.¶}…ÅÌ˜6“û!z¸İLr_ÙŸí'¼•RbÕb1àŠc™o®É)u•3¹àiëåV^€xg*+I3hFßF"C‰_´:¶$‘ç2›zÀ“šù=ºN3Fô´ÙhwDƒ\eû?#åµzpYU&ÔÒA²—u¸$´¤PmQ¢Œ0ºc01åh‚LË©şµÜ–º‹­F|eëOú<u´-Q´Ñ±ßÆ^z¼ä>«âsp6Õ´®âKÌÌğÅ,a¯C`¾2ˆ·ÓMP²{M­l‘”HÇÛ/¡„î±šñ––)„)±ıŸ9¾Oï ‹†ñpÄÙÙdi›c»•èôuÖ¾‡±)D)wº´ ëºÁŒÌ"£ËVˆvz6"d(È.9w½æ^ùmŠ,,‡‘é&Æú¸ºªkyĞkCÄ]rÔå2 âŒ6êšÿäíéøFuqdÿ“C‹yy~âoE7]ş¹G')<«Š#öc©ì‰\/bQÀI1¯’3­íæM`ö¯¥İÌ¹Q™—ÆïFYJ_VxÂn¸Gâì·;æ3ù…_î±%#mXÚ¡úäjd@?¢ö¿èŞ9C˜^5ÓÖæqVSåÈ]!ufPqu™³iÙF‰v¿É)ncpÍ¼Ÿı±ğ<%Nºyï9çğ@ıÒgRH™ó¸ã ¯’õ¨U@å@Š¯•›R?@[‚÷? ÜÇ‹-­LÁ
{1ì”Ñt3aŸA¹rº‰XYuÀz,ö‰³u¦#|*u#XPĞ‡çÒ@ú$Çîim§÷S4"l
tãÜ–ŞçP~[…ÓÑØ&–(wAK¥ª®KUäh×1úÕz lÃæ˜¿­•Y›–5éY?[ì B¾æçÉ˜àdÕÛï¢7‡ 
Õ•DZ 9„÷ÒºT¯¿1…Ü‰-~ªáİ¹X-iSƒ÷=‰Hˆ"§ºÁª3³Ş®@½Åì`^%ìûU%V‘åçë*õ!·LMKWâ
Şâô"`ÀbÕÂ§EúfáZoû‹eSöHEJ¬ù<âR›ï# Š'ÊNÊi3¢· ®„†2¦‘n©¾;]-Ã»¬vJ¨¾˜ÒÜÇn 3ÊíH`òî!¹9º-ÛÑ/b«ÁØ¢ğ3‹£ƒç/°cnW·ß’òM£óÌ—6½o›ÆqQBÅ¹¡S‹àêÛx.lscïoKF‘²45˜FÎ&;¨~·‹bôl*ÙV$fh¡ndÁœ½¤®)$¬‰©Fî;wØ˜ÌrşKc´CŞTØ¶ÜVÛv>Ôâµ6Ş5óéOîÁİ´ÕİÚ¦Â¿9ã”·$s

ow•ÚLj¥İ¬âÛö’¼ğ_¿ç¤9Ì)›óÕ1–üì_Œ²|ÈòL`-ò¸
F²­Íb;±ˆ%ñ€Så74¨¡’<´¬¨ÙÔò1#YÏ[q{U\hLC¸5Ñéên2T}Ÿl%–ËØBètíQßŸ~ë²4Ëç&zçöÉ7HİîÈŸ±›úr„/ŒDm¿C½Š0Æêÿ‘ÃB‚açxi}¦•'xKcè,iAV¼|Ï®0ÇÛ©£Ï$6ÓäŞ}±õÈÏíÀ™qaBv÷ş==vBĞ>VÈy)r²-Ó
qé‹,É¤„Õ#ãÚ¾xÆZÛ ù‚R‘7OJg®;/ï½ƒı6yz¡'¢,.K…œÀF™@áã¥Rêæ‡i+"d™Ólée?{íÕÏ~Öñ1*%¼‘.%¾s<ÇŒ¤é‰i«^µ=jÎ¨~
D¸á]¦¥Ñã…Do„Šß;©.I·VMï	ºœîm?tB£G“tw§3šÇËkÇûÄüP d7ÉÉşš¤ ¹aá1¿Íšus`B·Õoì“29ø4f®3wŒ•ûH¤£Ï¾7EyÅçè”µ½xú)W+ßèû5ˆy•o?z¼¥cf®ÛzĞjk…de%hÉÓÙÆĞÅ~à:<ÕÍ˜øà”ŒæşM
ñò€äNÒãıÒ§„¢¾Æhÿ,¬OÜÑé'šX#µ4ğ×h¯ã¬‡şç3˜b÷«BFƒ¹ğ1ö’v•1,g6õçñøXE(jZsòšm»§‚ê#¡³Ÿ¾c$½—Y/Ó[ÖC/¥jr»Èh@e7Ÿñë"8¦jKò¤@ºtuúç#‰Kà~à İ4c½­°š|‘–l	Õß»œ:<Åó‡ÈÑÅôÈZH¼0†óÓ³<7'=9.U¥¡ jª—áÚ/õÈ-—1·âÆgöi[€>	uñ\Öu%}™ÑƒDî¿dO#˜ı¯‚r5„™“¥§T³9÷¤3ˆˆÇQ ÷¨REæó›Y…ÒâöÍ1`ÙS
,õEYy»É¯ouøê†Áú²süÅÅ({¬Î5ÕlKµõD@ YV~ù&7ŠX«ÜÛÆ°u×jd]B<k¨¤è˜¾ñú™ş$…Wà5ˆÒ
Ü´zÒP!lU€LäxŞ5Ãƒ-Sû¥M\ˆ’ı\ñş>]sñúÈ Èæ (ZÅÂ• &
¢ÔÖì§†¨ıÒÿ‹ŒÓ`Ó=,—Bf…W'†ƒTe3Ê”.Æ¹«˜æåUYµøÏæÓ˜ë*)‘ç"f¼Â½›S¢{İ…‡ÉåÔ‘K#¸·!WQ÷ ïc!ì;×Ê´ê™»îŞÇĞ ÇSgV+–æ€b´ ­¥ÊŒí‚}Â3håÁŞGä<ÓÖü®M¸”®*q»£ééAp½×=¥±÷àŠ\Û«ä™øë 	 ÿĞúi¸.Šwn*ÃDø´k«±xšÙ…SZP{Ãâ¦#zëérµ–dš{¾à Æšù/£¡5mbD¼äæıÇ	Ó£|ù×7K¹ˆ¬³³U)®l€â’¢ÿŒ´oÜ~¡8…‰Ô—¦“‹ #êÖmñD]\LùœFCÖR+\vÅ÷ÏCmºg¶!da²ëB'E…¨'²o¹Çÿºmı^.>àŒ{ğsL	–ºî'£Îo~ßb@ ÷âiõ’ğÅ’Ô´öÊínÎ¬¢4‰òÌ•d‘…>Ãb¤ô”Ğ…Un\Õ¨aO[äŞm$˜WÒÄu±'İ™ãá¡ƒ³˜¿»EäOÖnX18İµ,Ğ²ÒmL„´Ä8ì&²Ä"GÓb”ÈÃÊæpôe•ó±OzD÷ Ï„ÛDİl*IN8u†êC'2xš¬ÕÌ€‘˜wün”…€d›Äİ=U)a"®Ú¸slÑØëÈÌšÉ’e›‚ùódØÀqwçê>Iğ-Áö¡[o.ç°˜‡3´_»4i`©ÃèãLmÜó_˜—]®)[|)Ïì¸˜¸êò”o—œãmeí–¢ú@¹B´SÆCò4Gƒ×°-*ß ´m³cTZü4#(X·9ùù–|ößf&6ì Ör}n© Íî…:4Ê÷ LÛ´«Ñ¼Á\<y/ÃE'¸–€ˆU‰ÒMmÌøÄ.ƒHÙ/ßt¬…zÒgïH÷û’åœ ¥JÒƒ„Zo™±‚’FYÛ]Å±E¨hG]öŸõvofŒDS¨ÿÑÖãğäuá¨õâÍÀuÖ—¦¶‰“ÉdHÏ*ôg~˜ú¨jïŒCšÕw¤CÚ9¼œQ]·!Õ
½m–ä<#?OİQÁxâ¥+&oÄH«]z	ÂÀÁ2T6”?ÔaeÄÿ­üùRõàäuòğ«‡„²_ò›…ÍM t»ŒºrØÿìãÒ¥ô@Y¯û6{zÅÍír&G’à¸¹ğÓÄ@JWvƒ—}İY8. ¤OK-¨Mööä€T¡jîD7¹Ö‰&Mii7sÙºQ>;S[g­R}#0ä¸•‰nKË_ß{tacª&ĞÔf»Æ>%×Œ„”‘{@¤4âéf‘û¶mîKåÇíôdúfé/¼ÛwÛ²{Õ´ŞFK±æ(ù'èaX«q~×ÍÃÑ2p¯àã$WÅÕkç§Û½•rú;\ÁÀÎÑiĞƒö©‚p™Î6.BÀØÉ b$x¬©sÎÚÅËåvTH	’¯Ğ´—ãÈÇ‘ˆÌ/İIªzÁóC{m$“É<œ{œŠ M(Ë5©8åš)UÙt»f„1ÚÖ†nÛæà…á/»Ûäš)rh«Z'İØè’ª)òÍ¢C‹ŠúÌ`ß	ÙßUçr¶£’e§³	™ìNh7ıH&\îÕÿ.ª3súÍ-»Àñ[^HØÁiµ±WGÜSôN ‡ÀRH`ÍŸÁòß‹şHX³Õ‡|ø!Î­á<´øa|ö8Ù§§¼ºK~ÃXíöô^9{ÙöúŞI~ÏğìŒ11Öõ{öğ’[GÔi=sâõT	=õß„Œ±Få,	V¼ƒc¿ÛÄiœÄm˜93Xz„Œ±.Ûó!Ã°Ğ7>ÕMS!!³&î‹²{§:aW`‹¥vW_¯‡/§Ékt=Ö…(ı¤MŠUäíºè-Ê«!8~º‡^wÁÅ˜¹=à¹mÛØBßRuçXF¶#Î¦q¤öe¯ìM×)÷SGYq›œB~d¤9†
éõ=¹ Ü,Ì³júX»ÛæÍva—¼ª‹‘ùz^|ÜŞŒKúÂ0¸Ìı¢
¤!Ë§aûºF.’i(ëa„vãÓ:ùıüÁpòÓM´w&£Hôí¸šdXàd¿úÅnpÚ¹™

º˜ŸÙv·.şX{…Ù€ÿ¯Õ›éb¬^7µÏ#ƒ ¦Ûò$^Éò sD!™øv30 Õ“Y¬ÙQHĞûÔÔ ìé,Òò)ouvÿbùÜ]-h7v°~"Môœú1&036lnxª¤µÅ¶V9èú*©ÉÁK’şŠ¾«j@ërÊ¦ ¨–ŠìÄŞºéWv¿Ë!8|$b+ˆª|ØÎÊ5+‘iIäÇ(p}\{1¼Æ¼ÕH)êÇNLTUH,%NC³0¾©ˆPD!]–Yÿ£Rë½blyá2˜Kğç[ë(Z-Ow§tS‚ØÁôY5KÀÈÛœ_Çì 4ê~>¾>ZÊÆ³÷Ş,øüÆlJX¿d#[8œ×%qaDİû»¡>'òAc™Šq*¿$ßAÏ_²‡¿9ßçÙcÀÃá;<ÜôyY©¸IÁs}~×äáıkQ»“İAÛXBØ¹õ‡Úb\Æó2hWÙƒsÿÿÉ[Ngj¿]~	
3¶÷„ÀPµ°Ç¨cÚ%K@é­æÆèãÒÒ:KßD•Ìæäd<»~æ–Dó½z)a«H·İäöJŠ2¾aé÷Dxø&VÓ>*¡ö(cïø“åŸµ³R8…­~!”ÖÿbïÖç’÷¢öØ˜…Dì}Eñ-QÆF«Q‚E:" ?jÌ3P¯j´oh[­Óóİóhµ1È$¸^sÊõ2µßš)´ï¦ÿ z}·sÒ¼7öà]ÆÔ¾çÇ…7%…„ı8µ {Ëˆ¤…‹õh»ûõ#õ[»:-#ae²$\Õgßì#HãX*×à@m#^1Fı{TĞ¼B5ô(‡!¼ õ»îhA|QÌ¹=.dñÏËä‘w÷~sœñÄDûª¾RóğÊ°¼OîV\ÊO7 #ğòbÃN;ÉSŞÂq&ëëlbşãÍ-eˆíÌª..1FÁ'dîëŒEz¾ºØ¹£ÊÜ¥´Î—J¦,ğ+­n²:‡Äãlç6à2¨SØÔÜ!´U¨ı_T£ÑÅÏÓºËÑ%heˆ1jÅ b½ĞÅSJÕ¾Å°!ùáÓdã‹…Qî0ûµz Üüœ]‘å}Æz½«È- ÚÎİş?Á£5{¼VŸ
ÇrÄwöo«t4Ió(.†^bó=Š5"­¢.åXŸ€¬Õ:^>;€Õëœ@_#êÇ“•ƒä`smR@ŸkQøIìŒ¼ú`"#N4'å¡eÙVE½Åz "RÃ¯im-!1´A±ßÜ/lP_’È³ú–Ö—{gŞc8TFFì)QG@ª§YE?=ßL@²G±õæöÆ§Ş*!$¿„¢Â3"”VB­€g©¢ëqŠ³úAÑ,
¬C„„ÿGÕ(ëÛÅGç£d™[ÛÀ¸ÔĞà­TÚüÈˆŒÙ½0Öƒ4nÆrgWß£ä7sÆù:ælìäl@×b·Iì%‘¦Å—ößm9˜œMJw+7PŸçSµÕéş6ûÜÙ³š2…ß0•Zø¬AE5@½Õ’Ãi‘ëN ìaŠ¹¸CàÁÂyuD Q£…ÿ!Î°8Øc
ÃmÒü¬÷.GÕßÉàâ‰s#Ù ³§%´dş"8\¯¢Ş|Ä5Øm‚&¬ "
¥~…ö¿ípÕ¾·ÙP÷ÙyéîGä‘û*í½àn¹ABºÔİ"§ŞƒúZp¯
%~Ì[‹LôŸ3MEçğ¦Õˆ9ót?%eÂT[ƒÿmß°¼®¾˜ùÊ4ph¿6áÙÌáƒÍ°Ğô°ßp&z,»4ˆ\ÖÒ„Ä3R|ÿJ¨°µ@â™ê¸÷
»Æ\Gªr0Òû àwcğ¨\ ³Â˜ÌugTx‡#ò7*¨Ú¦^ÍFY ûC-ÿâ±†SwT3Š˜ˆ¦ÙX‰Óı3¾eRWGğ¿'2*İ‹KŞOVş=¯±¸T[VOö÷P†üò¤†\T))ğL¢Vi_3÷nT¢Ú=cxÇ¶Á'³bŸç=l7¿ıˆ£¸îÙz¦Ÿ}1 £hû¶ÁŒŞ`ÄœrEúIıÑ`úğ/ŠcĞ+“"Ø"İÎ‡=Á1.ôÖöM9x)±„Š~j©îMúä©‘¹LˆH)ÎDD¤óò8Ô…OŞ ‰ë ÒŒ7jÚ6e†¤"‚÷8‘ùÊ¹‚ñ,%õ÷²-˜ä¢4 ¾éıSØ¥YêÛß¸:|ï:®zàIÊ!u·zK&è¤û@î)õ¢«Á°®ùbá€ˆ5¾:»{L§Ç3•œ©;O/…€‰Qª äà<û­%4Âÿ‰RÄ@Í«Ö€ò¿ÖÃí®u“X®èoê$Ğjf7+Q÷LfáHÙ­.\ğ6H:8ñùƒÌlq5œ5*ŸRÿÁ¹†™+"›’<w6Ô0C®u³Æ(W§˜«§³î”«É «Ü¬óO3xtÉcŒ2òz	XÿF°Û8Úïï#–]-µaJùúúªå€êˆæ]ov¤İ¹Û‡úáM;@ÁdÑkà®L¿õñX|õp˜-m›
K˜Ò¯ÍäÂk%B)Gšù•€-¡³7³Í¶Ô7b.ºÜ —Ş	g—îÆİËëùı$ºÂz>ŠÖİ˜P2[ift8bæ °Ö"ëZù%t:ØÑõ¢ù©<ä(2W«á™íGÌgQåÂ Ld{B+¯¿ÌäHíş>z¼ó%»hO/æH`dëêUPCË’ì4%F|¦S0ä!ÍCÉÓS­ÚÕ¬Çz]`Ş!öÆÔ¤>_ßPOÏ£Îà+æL9‚=Yg>0­K_ıç[Ó¬ÛXşÀ×MÇÏ¤ùQBğœ´ô¸ù"ÜğrµxÃ)òæ°
¡Oß<´ús²%	ô
 *ªaMh§K¦õ¿o«Ÿ(¹÷ wØÑ’! É‚îÀcŸ{¿G4CfgÙUMx;êİï¡à›ÃZ™‡ÁÙŞò±Ãò 6g{g`ŠŞ²„’{rƒéË«m˜ˆ†‚‹n¢­É£Ú$™P2±;m[¸£Ç²´¿Š=ÕÆI½‘CMT îâŸF9ß˜ÉYYycÔ˜*O%ı¬ı’1·8ˆáJİvyÜaäÛæLä hGò‡zQÍ`éêïÿŞy”^û€ô¾C¬îæ–nö¢*rÓş8N¯gÔ±gûm€šHÛY–õÍd§tez}ŞüÅOG•1\.ÃZˆ³r1”GR
]^¿ø×vi‘”À±ÿ.Ìd~îºˆ§*5ëÏñIÌG˜cNcgÌÚKˆÅ¬•Ç;L¤qÁkÄà‡o7>¬'¥Æ)Lxü)ãÕó1	ñbõù!ïsÕá_c0b`}ÀY0ÄvÂ^åÍN%‘§i´î 7ì«#.
®óBUĞıÙˆ	øş&X*ÓE’ğïBK8pÖSê”höT5"ã†m³•à^~êº¼Úús¡¨7°gæ÷PİáĞ3&:í0\ŸÊu²vy7{‚%+}"aT<Ñ‘õ¢ôu^Æ}ÿ è¨Z¶Nƒd¯ •aİ‰ÖÙİ qYĞs(.hN\Djò/Øê¦ò‡Êó˜+òtCZ4æ¶^F)×³Üºú€(‰&pFTkx=Û¥ÎO®_F…”k—x>ñïR+oäO{…Dìï•|úÔˆÈg¤Ìf!ñn~UN2µ
»†“	äÀVÙúï#—,ı ¥°2·fa­3›i>Wu£ş_ĞMÀé‹@W
^>0ìl =Å–Â›Ó/cä¨;Oïd0jfÁô~ï‘ÈJ«Ü¥XT–äf*İ÷~e½ÌzÕšÑ-iga8sŠ{åØPqø?yóçŒ²yæ¤(22gŸçÜS enS.×İşãÜV¹GªÅ@ö›c’öğàsˆoIb†€¿·kSv'9§Ã“ıØ6}Áµ0CZ’›ì;˜{Éÿ”jÒ¢i€Wàáß$‘ïÎ¯~bşÆ¨ ¦%›q3
ƒf¥H¨sĞ•ú£,à8Ózd
»İ*©j	”‰P›¹Ÿ<sšÉ¾ù¸CxÃeÎ(éRáÒ%ûÈ¯øf‡Æ(œö¨ğØ¶¹
™|=ƒä•Y6£ñXaGFI~1zª\ÌT‘/=líıWí„vc+¾©™të)Ë¢Ä¡l©»¯ûÙÖÆ¹/æåşc‚îûMÉTîî“;'w¯FŞ±Oôò³e3Àâ/„ÉLêk9áƒ§éısŸÛv]õØhçÃjoIS7f:Ç »#^ÕÂÑ2î.Ú>Tğiåš’ ÅØ¥Pˆl‰sp6ªÑ\êŒöt 8RxX)/D½»È¨ş[>-Š\[ËAåí¹Ìg9Ç@0LœH(HuzÎI³Æ ¯Åû£Ì¨ÇÂ0‹,äûõoS71Öi8ø¬bƒ3ïXï±­…;0¿ÂCç¾d/ÓT2û½
nÒò’¡å+!60ò;êgÊÒ¿Ãd½æ©E“ì†…ï†LI-õ‹*{k3¸œ÷'¿ÀJ=]%9ÉAaÀ»{İºá¿qÅDBÄOÍÕÌ§Iî*Ÿ
Ş^­°WB4|Å'ùîŞ|üÑëwª/ô	Îå63Ùà!ù@Hé<ó.-ÿ'¿'¸ì­™ ö¡’û¶Ş¾²êù´Şîo”Á‘¢JH(h‚+Ÿÿ67§MsO'u,ºV'[ƒAll¨¦ç8 v2‚Új(ÊÁŞ11‚ãTcU¸ÁN_¼õ-Ù;Nüë@âİâBOÍ*ñ<Ï-Vùlîàk|hÈÄb/èÑå×UiZ¯é‘ï%K¦€ƒº>çvŞQwRrgL³çÊÂÇ$2ùÚ‚;mpwîLßàÙq'ôú£ãj#¦fyóˆÉãNò“&àÒÅu:s‡8ª›Ï~ù­×H—¼¸9c!–w]ÜAÄkØ«D)±Â±¸Öóâ4Ú;­è¦:0ık+Ş´Æ3²‚‹Ï®Ñ5£•2Wià¯Şã¢µ%y×n!:’Í`]PÏáé†?Ñ	 ŠØ˜5®~vÏ+x›X°ÁİGLşç‹j¹\#S¦Sª/ÓNYhdQW+aÙW	äÜïWT‡§¨d`†G”Q?¹˜àpM8¢mÛú­Q( Êc¥\hïÈğ[¶¡Mgá?1a)¤C—Mú¨W¼k–çİÌ1/ç‡^9¯š‚Ş/Øñ	º<…É|¢`£älxÿ!ÙÎê`ùı± 2eií-=cÛá‰v&C1€İ‰âHØ
œd³_ÖRëo"Ä^C…Ö·@Z	²@÷¢Ú,×ªÕ»IÀ—ˆÿT§³İ—×bAÉ|A5-hË˜Mf€AÆrßF,œ‹S·&ËÁò$‰ Şª¾j¯=£N9_¬Ciè,ñißN4Œµ#!ÀzsÄ$ª5×ÀZÂGÓé<„8zCû¬ÒOÅÊj§kœ¡9†Ì¿?¶^v ¿¥í-û¯HıkÎÂ{¶Kt=Æ¨Gd7z–n¸®éåá‘è@Ñ¥+qf/Ù‘Ô»©oÓ¢ê=åiàÜ(¡¹WCëÍ¬'k`ÓçƒÀÊ@ÉUBC«Ç«ÃOÕë[W;XûÎ4/M8 
ŠsWpkµZ/gŸâˆ7rRJ÷Z&ÀÕ9FgKáO›¶O2«ş:a˜-Í§€O¡Ş>ÄãÕPüq~}!Dô´”8F*Æ{¬ÑĞÍìÂFø|öt9«^z	~ÏœŒzø#eZG¾Ï­Æ9z¯ù0`ÒÄ0ò¬Øi6ÜnCÿL\n‚13LØ¼`¦n.ŒRŠí[9qYPƒ.òíÒçÇ4KVÏğstAsŠÕ‘@®É‰,ÿ›²UÌœ›ÚÃeÕ¸øÚ6fÿ©ü‰JbmÛØªcê‡dÛöL¶Âf·C™ÎI¥¦èœì&­vŸù'Wjßúì4ìMı6¦{àÁŠnèˆ	g%Ù&CTÛæ¢)ëÒ¢Ï:°ùR/[º›‹Š¥q¨¸Úï±şÇ´ä1ifnJ…kş+OáSë-˜]Ï¿4qšŒ¼uª©ƒÇŞÚ
LnE¢D¾mÈ»`åÛÌÊ“Ñ<IGñŒ2Ù"2NÁŒÜXM3pÇİxİ™
iÅ§7KdìâcD%v~eZÈ) œ™ˆ7Ğ|F\€Ñ*¹d_†}m,-(Qšv®"+Î§¬FB-'¿m¦¶Øû?ô˜ÚÙÑŞÓ4›ùßÕ‹Ê?Õ§>¯Âûp›)4Ø¬›-õÏ•—Ùs7è±ë}ğYLG®"IŸ)İå@×e«¸/.A-MlòßX	ĞĞQOãæÖ¯Új(ê©eØDë‰5ßÏƒÑw*>~iPÄ¼aB\¦	t©ÙÂù,àyÇ-ğê`ÛH1?(>ÔN_£MaàñÏÿ¶Xwèy¥äDŞYã´¶ZW”QæØúÎRd–”oï¯Â9˜”¾ËælÁ¯áùÉÂÙ²zNQÆÀğn/ü—‹Üx–ÈËÏ¼%­y¤ 0£a„òÄeTóIª†ª!]ä?ÂZ™%Ì„‡¯Æ° ¦ß¬aôyÕÔtáDï˜«}›|ßñO8®ÊR½ÈV8Ì€8.4ä…º´ùšsğ.±5ˆªö‹·ÊÔSòÑe&‹Ñè Í¨%ïª¿Lq Q¦=D…q8Ûª+8(æŠÕÉgÍzê„şs5fó2fĞ%A7}å†øKÒ³È,TáQik’ßÄ²f	EÒnùâ´4­Æ÷we$÷+“`,|ØfJ¹¶]¨*G‰êÿ»¦Åv7h/Ì½–IB]ËfQfõtÆËyö¬)Äg3³¯_G"« +«ÄîÒM!B
d…]å<Ğìì–Û Ìà¨è{VË§X-‹"¬2Öø!P…’Q2ÛÇTAviğ~C¥ƒí¶•;ÔŞ49fú,™‰V»m².Vt#I|+ñ®»&9_±YS.Ix ‡·8É:ß^ôA&¬€å°° ‰^Z;'h.á±\©vpm’É÷«)	2Çãº„Ç0ø÷òP¢»’
ˆE lYİ]œBÎË±NˆzëÓº²Êö7ÔÑæ3!>/‹«ü'¤“QÏmáŒDÆèê¹Mÿ/şÌn
ù)IÏµWÆC“Íê½¹Šğ#‘ü·à†Ób }â:ÁºîNwOZG	¬lFTLnTÂ3mCKzÅ£AIMŸlU„Ê<àE›	P ˆ°LÒïaZ«³ø²&„öÅ»M["ó0É÷S±C#Ez&µ=Œ®u%6/W—/XîÎ
^¹y25ƒ:-—9oE²+âéÆ,oŞå|tÙÿ˜ø¨å|Ç¸z«g¢ßâ’Ş™s÷PÉ·t²Ş«k¬m¿bàõ¶5¸¥Îu;	ËGªZ“Ësâ*r¯õÉWı^§y¨#»Ó:Áñw‹
ùèöJ8¢º²Q_ö90w¢ñ‰p ©„ŠeÎâ¤Q„§èŞ9úİ¥æ)MvİºYÛ^½©n¢Í>»tlm"¥çoEûš¬b~¬ãåĞÚ>û™{¶ò0À~»ıD|j·>¯uˆÚ)ñ¹ò|Ê‡éÔÀ±Åå3¾<5xÍ)sªc©IY’ÀúØ¨ØÇT¼-wkU``3Zù²	¨KÙJa6¶!äìyƒ¶ø)'> ùgçHâr°;©Ù¼6i;‚·fàW~ú•&Ş7‹Œ„…É¿¢&Ó"#˜2(DÅAï&ŸKóÁÓ E›%ƒ1é¾y™s&±±¦”<Ï¥Sæ8©ík#a4=¤I±r #ªÂòìŠİhë,9ÚëA™-s’ş¸<"PÇR“£œZ>azÄt‘ï%šjQ˜.tÑ0#TN†Ã±ïæÈè›\Ùq™™eK‹³<Mg-¦€à4ŸØQ},ñ‹Eœ¥‚cM«´Ø!‘hÇš¾yumqG”.øŠBUÖîH@S(YŒªÍÛ¦ÓãÖ¢ÊhÌ„bYnï®Hu½ÁGâœõøÈÏÑ×¸¸û6ãW‘â*ä™måoR‰IÁd1=cÁ…ÓùkJ„{nó}ouDÂ}“'‡¢¶Q‹Ùy¶^Ì–T	Û¹IH¶4óÜUaë„óª¶ZòÃÄJAÙTp,‡ùwä_¾-®gÁ‡¦Š†ÂIuä‡6•4ROJ=³lş½¸fSƒõv$õäjÁèÔVö¡h®ØçÎ5vÊò„—ñŸş¥•>	ŞlLbƒúxÆ^/F#kYŸ-4Ë{	£\&>ƒÚõªæz¾”¾¨f3%â	©„C3{WBp”’­p–Ì¾§G6Ìú5¦† |Ñ¼ù^ŸÇëeš!†Ò½r#ûÃW¯e=÷Ìkş¤}«3Õ"ŸŠh'~›u,W¿PœW¯qÄÿ)1/ğm<ö.¢qö~—A"Cì½§£œl`<4lz]ûÚ0Z¹kœÏãEóá°ŒuÊÇ:z…ªwT†û“úöA1ƒJ¿_¼öÔÕÉêDm@švô;ğ¸¡Nw¶F>œs
L1_J6˜¶4 p^&¾lPÓ~x‡/(c!ŸëX*;s0åKŸts‹ÄyÓœyO¤P/ŸÖ‚qàpŸo}¤òUüš¾8ƒ;V«¥Îrs"øR¸g^pí'àˆÆë2\+ú_ï¹ÅWn-fI éìP×eüŠIJ=ú´1{ì‡ª¤cFä à(g¹)Òê›mô5›¼e%‘HËĞe× Uà`Šø¬b¯)6$<àŸ`‰†şh`vêBt“Mfm¢[”cuÛŞ˜Ó"?G¯2}I@<İú³:×=ÙGjóÊ&ä9ÂØî$uÆ
]­¸o‘ñ¾ˆ¤&õZ0èL{€¼ì†×/µ˜ñ|-c¦ô»Æ~.‘'^u'íë°rSËb)·AìµÂ˜©¡ÿ¾±rê®.ñ«@°~Õ©×€5x-™YÂsqqA`<ÍèÓ®fev‰ÇpÖ³et¥íQ'ÅM‰9pÎ³ƒ–I©-é^O¡V¾fGg3·Ewº *'²WÊ(â«…;§%(É¬èqE;ÒVÚYœgúe•Hf?Ê$¶äJ˜
)ıÃeé™ËŠŞİ<†^Õ¥ëQÔRJê0LğØm@©õRˆŞ<ÖÉªÙ…s2Ÿƒ	’ÅÉëI)±´b.XnDk¢´zn¸¤/!ôZO°b2Òè!C(¯›¨„[ÊÀr`3,d×¥çñÀÎ\ÛO´7`“	ùÜDØ¤ÍÎÄñ`´à1Wƒªø‹8ü&¹NÖƒW©t}cì¦ßQ"¹Ãbxô	C ùèë‹ä¨ÿ¡K!“##½5¬Ly©
¢oèµêqB{ nÚñc;7¹Ó4}Õ¬_Ú’"]Cr]‰Wçˆ\Á^8ÇEJrFâÂ=A[™Ÿ©<Ò·Ò­õ÷œ·K‹M~½³›µÇíé¢	Ó³5¨ ôºòls«ìÄbS2ùÂß	ÏtEÍŞTXÀ$‰Ïª¥AğÎ=6ßÆœå@Üeàß«ã£á§( ™–5¦Å¡V:…Q™˜­èı†òƒfº• ŒÏFuÂÖÊ—0&7’ Ù6V"b’{F>×Ûß¬ß¯¬­ÙÈ@ŞGÈèüî»|0Ğì1¤Ù×|…×ã)Š­´…¼¶e;À˜yØÕñ‡¿,KYf¹ˆZ±IÃ<6íŠÆªë¤+›Û>¦şq}Qƒ§­CÔ7–ØŠ]Nq ÄOç• ¿y‚¿§{ÛƒÂ<,Ç²¸[¯)•-õ??j>ÕGü$g~Rºğƒ·—œ\§ªpÀä‡YíÒ£ªOµfó{§;œ…/”
h<vCŸÏIPÈBà±ë	eÍ@òµ*)Òv÷Ä<¸÷fúu‡"ÖŠ­Hüó…Dñµ­Éûbyj;Ÿğğ0õ8£J¾Æ]e	ÑâÀ­Ä¹@=Šî¯¿Y–5¢PCøß2Ğ…å9`¯Ãşê’Û—¨¹µN¨æóC¢f]ÙŠítiså­¨(ÙÎFŠ ³¦Vëµ67w}wR]¬i…øF"“½XtâJi½w{Èı¯¡BA~FÆ©v)|aÃ&½ü¶Q›ıZìêéM	68
¤Œø%<fáF¶=@Ö·a=ïQ “Z&Õ‘ŒèÇcbÉÇP9m¥~Öç?),¡×ß¡ŒÃM´å½ã/)Ã…ÜmeYä¾p|GéV&RX­mÀ*öĞ*Y}ÎEá˜f3§©ƒÀëxÕæV¡yVhıùÊ(ÖfË7ú¢ÏÈ3íXÁÓF{cÿá^Ñ/¡Æ‘!à—¯|ş;æŒP+k¤îâlImëNróÛ*ù;Şr6%¹­p¯H.÷×j`òs^£?õî
â°,_.cDÂzk˜¬!øx±‰lµoL¹n¡l.IEeE«Èt¸Ö­†Z“q4êìà2yrxktºOĞv)ÒMf#bù[Îô9Œ TìÑJó{àĞF#ÁrK“Ú<d¦÷Ù[&ÑÙĞ^Åã|šH’©OşŠö—+ŞN"éÕšÖ6šr‰ÿ¹lsN4pbıuÊOf`²Rp$*FôŞ<{«ĞŸ¬.³Ã>.r%cZp)èmğU1/×­k¯·®\ßê—± ÆPYAşNLkö¼C§ØMÕçÁãVB ÀÊzeMìuÕ
ö³ªm³X0°{Cap¾‚w¬tİÃD;3ØyKT%¥ÈSbp™gùo‚0·$9J»ı›åÄ‘d$sÙ3~¹NäÊı± ÄÉ	¹™™Õt©QïºAº+ë‹Rú¯äºÍî}Dï	>È¡ğ‡.ğ+ä§Ğ®¯'Ëvw­ÙQ!{sÊ#ên»‹:şa!¢­û1jK‹c|z—b” Æ²qAëâ±©…’…ñ€°âZ<tz/d%µkÑe÷ØüWãŒsüL$Ëò{JBOÃV‰«wä¤XÚûË‚wçy—,*èıy‹ûFÈªV'¦M¦|®•ÑºÈ¯jñø<“gëGŠdLÕ‹ÅkÃgøÁ<åØ€xºiKæ.8‰ï
Bf0ã§ÔÔ'Å	ÿ.[j¡aUËÍQı ‹†î6 Z›@²|2¶+–uEëé’²›Á‡I|¤•wş®¸øì¨’½ÑQõ©Ş)UwCöÎ‡nP¹ÿà|A—¤Â'a±àÄnÌ¯—ßï3GW‡(@F¼¿Ğò´x|aE³z¦eoKh‹ŠˆÀş‰Xìt…µTó¡“o&¬³•0ì†É{æµ}Ğ$tXAËìaNĞ¦_Ö\;|À2ç´Q·´†ÜR˜0#V¥¢á,qÿCEcx · yÍá¬Ã÷mÊµ·â{NŠ7WÌ¸J’ƒËšHé%¸+\‡aš²s²`ŒÿK|)üÔµQy/”á¥zÜ"åÄşßcõÍı0¡2u°Q­v¬fx1¬_¦·Åàp"ÂÁ®fP½¿‹%±–öG st^2ñúúD¹—Íó‡Â…ŸBñ‚ŸùˆlQ{yîëëàüµ`Ä3~î~+†ò¢êÛ•zåL"RâƒCL`%¹+-R¿òg¶Ÿ±¶<näî®×ZDÿ |ÄuÓİ‘¿®U6v‹ -œ€{BğÁĞ £e"dSå'ª÷-íŒSÖªg-(ŒEI~\Ù½âéé˜m{ë-ÌX]œ9C= ğ’ê@á›VŠŸáÎÜ 	M’ÿÉvgk?’ÅîŠ‹à‡/˜`ä‰…e ì1)td&k ˆâC nÛ`Äî{s„q+³åpKãŞ9,NJ9MHš(‘LySóCİX-*©	Ñ¾æb/ò%ş•h>;EkW§ÂOJeäLz¿şa¥“¼TÅ>š/‰môV‚Vj
Vœ1óËªYJën*“Æ×•Ö‘4^ªÈ-‘ê·¹X[TYÊëò‚î«%wäHÏšHC…Ïúóy8¶À¤ŒÕÆ®—$$ÜÒiJèÒ¬£*?ÒªÈ2âMü­¯äá	Ps54­ªewe†­d-vª‘™käM)&	ë=E#± 3wäG´f‡¼:-Â¦İ5ó!ô/­½9¸ÎÔ]m)È¢vó†*.È:úxìş–°[ÀU¥Œ™Záo»âóƒPÓœ|Ë#$¾$nn £êÁÕÅ8–²¨y$óu•°sÓ<óõ\O¿b”é\JÓ=¤Ûíù?¨‹èŒ%Ñº'Èf:^…}ÓMá˜n‹x·Ê™Ì°ŸKºëëµ‘Ğ‡/GØA2yÜİDÕliÔL«ÎXÅF¨¦b5Å£4â<°J	¼Z£úîÔÔaâ¹ŒMvæÎ–¯âCôİø¿*‡d HıƒäxÆ>Å¢p>Ùè„ÆfœĞÕ'éäİÄ/ìÅ#ÚmVp…á)ïÌ5şTK/ùÊa¼ğur¤¹Ï›99¸­Jñêu	ÏğŞşJŸ¢m½Uê*âê…<áIu†ğYñcí¼SJôõø:ÿÈ«ÀÈfÚ9oízMœ›[AV ÒÊÃTñÃÑ’]L-@¯í	`ÙƒÅ¨L:pËW‹â†ZO]ÚHÇ²ıX|¿3–VvµXèÑò´ü;Så²õ`á‰Ã«,>F,JId¶ÔA°\“ôè=NšÌ°.ºEêæÇ]IÓı›eÒ²¬±!Ö	}ñ²Q±L+¹ÊíÑáªòY    3€İZğ. ª¢€ šOØo±Ägû    YZ