#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2761471398"
MD5="95282c44d5744f43bee64d76b075134c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24108"
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
	echo Date of packaging: Mon Oct 25 20:32:33 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]ì] ¼}•À1Dd]‡Á›PætİDõ¿RÏ¦_İ»—”ÀÊÃ<ˆóEÆ(Ö%vYÛ@bêR¬–'Ä“ÛÂ/^$¶-×w"Ú`’EpòØ>°·ã˜+!û»ìä;GdÖÓ}ĞÌ§†ªÉ¦1fñäBQ®	>yè©¬:’áFşå ŠÁÛ±±["ìÄªK¾>Àè¾.òÖ)N…ƒô¹'†µ`Ã~2ªRL€ìëŞâjè±“†v7‡eØ¹év#»³ah$£üıñÓO•­»r›KoºsÅ¹cUĞm&vÁÎ}hï¡ÚÀBı„š"v¢·—ˆ*Ï½Í¾H3ÊÆIº•TËí cŸ‹ÄvÙr±6¦H?‡Èd\ÍDrG+Ë‡İq["	””ãæ÷QBÑ9}“-tÏs´oaßp²™
‚cÂ¤Ö– ~ó8œ$lA¡?;J.=H­ĞÁ}ÚAÃWÓ˜Áî odpŠÁ®Há£í?I®çÛz_Ó={XL~hrÙRòzæ¡î2¤<ÖØq©Šmî]ƒY×}Èj»o¹ÛísÄ5ÑMB¤ÑŒ«¾İNI%g:¯ÊC6{pØFuOüöG_³ğû’´%g)…ÖŠú(LüÛ–J	Q“Y5jb$Z6şsH’û|+1ªtíŠ¼ËXî1ÓxlÏ¿#Ej¼Û->ySó0À †ößqQ¨¬\Šsï­)³xÿ£ V‹z6_îöi9çNt~&ÁUrfpHWP2áLüål"Èù|œ7§ú®‘U#æ¸‰­á/‡D•RoæpWE]|¯„½åÈØFI-‚ô>’
¯i¼*İ0¸éæÕ öTc»Õy°¸çxèÖö"aÌˆ²ä"±^u&SÖÑËáÓN¶Nõà7Ùu¤GYı¿—\ÛşµùIÏÎ²^»’áÜ×ÿ,°+Š Ü+WW|øYdo“z¥—°)^’qÊ4Š}†ŠX
Î´V®Á=ÒÉÇ¹q}z¤´ØYÎéu´`ô¯ ÃÆiIÌ°Ğ1;°Áy¡Ã…Ğ>Ò ´>Fg!}ß³§•Ã^N¯ã >	‘`ùÓí…"éÛÛâK2VL¶ƒ GŸ=’Öæ~dLÜUùDµs]gËtîNÿÈŒÁüVæõºÏJZ‰ÛmÜoW7‹I–'MØ¥|ä}QU¿,mz†Jî•ŸT†¥Åx=äYõ‰MIB`7\GËÒ±UbŠü'TÅ5s.şÕ)-¨ÁÖª-ŠZ”påŒJáZêª¨±‡*‡~Ö°ı^kaíË¤XJŸ2ÄÇ¹=$y[‘Â9ûÚ²éëİ&–Şi°®Rêv.ø˜?‰ŸewEO?êé›8©‚ŒĞu€ªM{m*øÛ*¥‚eœ§KDÀX^]h9;\óEtµÕl}QÄVÜJôK.ûêX¶ı<×ñıÎÓieÅj„Éñœ·»k|’36 X2$÷Éºã«§SƒÀ‹ÊDå|#*òfrDÉØW½ù§™y«
¶×K9˜±Ç×à–ádûË_(…ğeU}T’&Éş-Hh§…ûØîcp“uIN‚ 4"o.¨
%ÓæP^/Ã=Qì›ƒŸKš×9˜\¾M¬­»’Cl”ÏæØ]ıî:Í,ÿ¨S‹Œ­ëòi
 SgVÊë½:û…µ’>Õ˜d’îr[³Ÿz†¶Ö?³ÕèÁ•C¸AŸm)rÁıæådÄ©îàU ğÀ¹¡	$µ |©şp9µ’Œ>7|Êû'‰ík›
=Ğ[,¨›ŸIš÷ZM"„ì²<Ü-ò’iôñ”o³¨^ÎPW‹-Oò· ƒáŒğŞ¡ªš¹&ót·mñQ…×ƒì"†?òÇs?pÇ~œàª¡k½¸ƒŞçî¹aÆ,ãQ}ßªyûQ”góÁKsÈ0©V˜TÏxŞ™¡m`ÍìÌ¯¯ŞbÍÒ l8[¢÷ÔÉé‘Ægú´ì>©Xç@L0ª]¯jFŒ€‘=¬ŸŠà–š:‘T±‹ĞÕÓuTßµÛ¿*¡×á¬áèö¤)ˆÕÒÊ†º;bÑètaëô¶ó±«Ä]Ö$¢•¯å6Ì¹%+Võf=™Dôx×ÀVeÙ_¾ï¿lşğ˜ıCı¢%‰Cl¥«ÏQßk,Y\«È,Ğ.-Ä±µ·Ôh›gåÖR“â´¬bBBÖÏÂ‰Ô‹kW?`°ËA×wİS%‘´o›ù‹ÇŠûÇ{p}_4\4¸m™-»˜_²Vñ±ß (ÕÚ©AØÏÄ«e7¥ªµ“èò	MMìïµöŒ*k] sGüÒ‚†Zr©1 E÷´i)8­PıÜJoé}õOwPaãr›¡é»%‚;îí3>kLÃ‰ØmRDDl›sóZPw¸š ğÒ\¾dhºQ×ÂF‘wN\[a•9ö®àD‹²†S$ Çdì[ÕaQì.ÕÈx–íÅFa†‘’!geW¦ÓÀâòãšÎ+;M™¸.keÓ
PäC­¨F=œ„+zÁ¨E[	yé2…^Ê2]_	&ŸºlUíœé»2UªsÙ™Wá{V›¢—ÌÿsŠ»ë]E,[ê3±cor–„…·ŸZ-H>USì#ŠôÇô>ÚykQå¹îDG£å²!z|¬5.©\ä7O0Åê\4şµçö2ÛŠèÃÊFˆF>.ä ±qS†¦2dÆ¥$J´†óŞ3:"LÓ¸vı”ÛU ‚çè®¤ï-^wÏM$¹>1´8–ÿ³ˆ"wLãÕ2œY4„ŠüÇ{%iÄa£"óUÂp€rö3oÜ>e=,‰NÔ0X©LŸ*B$d¥2˜RRm‚OÇ˜ò©´dz3\©}t™b-÷{À!‹ŠF!–BÙÕà8…®A2c+…y8rÜsjdBHdè.ÆT ­ ™öØàEÖn@ªyu~xkÛÁ÷e	59³£9»Àf¼˜Ä=(ºMş¿*ıÖÍpDP¢\§ƒ88·FÌq„ª¬çG€ºïwÄĞ)zÇ*HíÜ=«¶êùşpM:©·p‘-w#vI@š]s±6;6 3¦ƒ#Y¯[ÅF	vÙ‰”‚…~~“>YjÛÛL^ƒ®~š‡¼”„öu2ËŠ5Ä›Ça
é¦®¿¸ĞMZ½y55wL—¥"G88aÔKÉñCì´yÎ"P„wQ®ø;¨ë×Ğ$aıP©ÃŸ¢†Ät¶Àó9˜j?¿4
w
jœßÜ_ùÓü¦şWíXß®ihw°ì²‚×7ûòµßÏæ¢æ¤˜ ªu'3×ç×Ğº:N~,œ÷}Œ´MzNÒ³ºPïÅ#qø¥²òùf´È_+$­ØÄäàø3ÉP3’¨oy¬U¥”O²òİ».Ä²lèQR»ûÒjÖ¢Ûı†òeB§AË„¬Ì–PI}à6Q*hn`B.~tÁ‘…èøH»ÿc@ÔJ*"çI¼|`iÚ‘Ê¢66­Y]OüÁ!ÆdééÖY©3û³èE2Ä›=m( ™´›Mv8 &v<ûÆ…1$ÛŸp|a¡âƒœbÌ),°>‘¦fëCõá¦_/`k–6´òÖÔÍCûŸ0eVÉ“*²®°:¶_j¡ıßW$c`>£×ûE
©Úc¢*` Ë…3Km±SAw@Úˆ‰±Åv.ZÙ©VÃ°AØéµÂ^š3¾8v ì«ör¼k¼O2¶µóÁ”êõ]ø5:¿]ÏJ­wyqeÄ .šÎ¾ÖŒ—dÂvÆ¶›Ø’¿‹YzJÀf+’ÅŠÂ—Ø9®Ô95Mv®3ÊbÄ¹ÌÖ€‚lG‰sÂ‰“læı„Ü:‡øÀ­ƒcù=h5JÉAeeoëIÒ1¯Ğ-WœøhUÊüşvÂı\†â÷şNÇÑÜBÙî‘Üwı­ÆúT¥¾ÏÖÑ5»Y”²‡Æ_º@:5{v×7©SE¦|Y^Ù¢UYc9Œ­t,Ê´å#äqˆÂŸ4vß`¦µkà?.?`g(ö1Ø±|Ÿz
XA¥Í,Œ\òb¨fÉû[|Ê'æ“\¾Hâ4È/'Û,ieotÁjKÅé‚Ø 0ºóE×X0±±Àï4;h›Œ‚î)(HãÉ;gŞ;³¼\Ñ¶ªÊCÒ|Vêj¿_¦12X*-Ï™[¹ö9x†3¢<xXô¿İR1ÿ¢Æ±lh&·¶KFü†K(Y8-.Ø÷­beÈ'F}™ÇÂª´‰ù¤Ö8…N üÜ©o=uqT}G0œq2ğjôÿıÈx×W? ø:Jæ&lÂ«ŒœŠú•¿7¤r`U¥m¥‡ âÕ¸ş„äÆ¨´ªá$+ä¬.T~#â×vÏÚ™¶B/Ö€³¯@)É©ëœƒQ^MØÊN²™åàÇë›T‘+"t®[€nGˆB<Zİc+&£
Ì×/÷¼ÉÄä-³ÆÑøTùÏÌìÕ-¤hÅ­µ^“ÕÉJíÔI†â úã$ğ§«(ÍÅ#ÄïÍe
ìaæô·ÿàŞµêˆ“‚	|¡
jn»$¿ªwF+ìR“dÿÃC»½a$+@Å –B"Y?HWL÷ÔxJŠ‰½%ñĞ“@½2'7ıöÇiì¶!õUùÏEÊ‡Ãï[ü>¶«~i.‘ï%óİ![Lr­
¦Ëlø>"¿*u6H `{ÍÊS„ä´Zq„ÅÄÓm÷9üº¦~ùvü¸ü´_–Îÿ÷¡T©ÛŸM§i{dV®'ñ2¹« ÃØmj‹^ÄÁÜ»£›Mx8‚"Ie€ë?&{àl+9kæ½^m\±Ü#ÃÌ(ËO.İFºFy"ÆÁJ ¸ñá|ïîUğòæSò„Z`‰èT{ÑS~ÃM–Ç…tüÎúço/áC%B¦%âÚş%m&f-<Í¼¯eBT8êò°³¹æ}îÉ\äôëCFæê¿ Ã7éıàK«ÔáA`	’d/E,=(„}Äv|4àí£ï0fgG:®DçŞµö7Ã¯ô$ „ĞßÉì	1'7§u•½Ğ< y:å•O+İU—F¨ç—ÈS ä`3ò".gz|—/>‚Ø0Ô"ö¿H`Í*B¡G¹ÃøUN2`´Gr<üšËßå_‡"ï‹ü}—c<¾,Ò³`¥ }] äÉƒ4Ò)NqM™™ åë¶¾]Á nK “~Ô-¢f0Â	fÒt5ä.ŞeÖUxi-“ÊèÁál¥wWHi´ú52ÎmAÊ!e Á¤9“dÉ¬‹ÎŸ½k0%¶ØÕc=!ŒK™Fô¹2‡á)xó’¶	¨×ŒyT›[*€Y6©FB‰.âà[EËú»‚KØGƒ4“Pt…L%˜5©UåÎÂÓ…­\AÑ¾í‰ıÓSá$ù©u¼4Œª™NN|0H±¢rİ•¾DCOôHÈh&W× S5‡WêĞ÷dËÛü¤§6Å„ä/‚Ôˆ‘8MÒíÊ|nÊ{½İQæy,hûßËû|Ôt´5Ì‰³º#Ãæ7…¨Ôç8V¡Œğ’şº´4¢C’¯¤7]MTØíùò‚8p[ ®ClÁd<eŸ³$xèÆ•¤.—êqBJeå¤Í/k„ÿÉ)2u¾FÒXeC¦RUµ­„î‚o…ïÂ»Ş'H#-ëfKDr(LÛ‘¿_†@>A¦ÇY£L&é&µ¯°Óóİ"û3¤úu	_0”~¥¶ƒ†‹.:•}õr5êÉh9GDB‰›M¿fÔˆë¸“Q—¥)ï~Bl„:¥eÓÙıu­„«º-•4x põôgc[XDÍsuÑÖÍ¬“%qï>¿L&÷^œbşŸ|Äà_£1÷†¨Ş…½¥®úA¾l~…7gíÎÂÔP…ê„v :ÕnôçÍ~mnjq×ş!¿ŒnßUŸç—¡æÁ|!ğ°Ë~%†zRLŠ¼LÙİRÛ£zn­öË?:<§/ì•°›"*‚i,ºIª²,I5ÃµÉè&©3¤3
dì›0GwıÖcóâEgY|™MYk@™&ì¥D mÊ$qi4î#µ<y¦àÖøRR–ÊD…^9+L[‰¢ÄÏ›œ4~·ŞˆF{2¤¥$@á2ızR°Æ¸º.§/ïõô¶m„7İ4´-³ˆè'ê»XFEì™–\R§¼ŸŒ73.IÚ{r°¹ÑH(÷?3Ã{â‹#¾êÑ	MöVxoØXõÃĞ“ª¥Œ6Êòb4•ê—'}‹Y”I…=ó;o^p‚äÃÏê‚uãz'õşÏX ]Ì~·‰µßô§PÉ1AyÓßj
5¶}8p_kpNú.Pº‚ë^ìˆ¬Q8—ƒEµ˜!1D!f50XOÈ5£ÀoNÙPqBqòÖ{ …1,RµW±ãÀ>×UüÜEI&•…wÉ…0P«á“ ‚;Ë/Wa9ù}¹EqSğ•~·šŸ‚
k³ÂnV¡šã
"(_RÙ×ĞøÉ3~—,c¿%ÓäXÅ†î8}ê,H›R•‹×oäã—¡½‘hd(‘G«SUÙ×,~°Ød›_L<mÔğª=òƒ37yº¡|¿úäg¤kÊdïL|4›5ÎNÑbRìO`!üP2‡²t™$Mióâ*˜(˜§¨±`¢ö:FC k
%Á+rl¿N¢:°ùr¥<Ïæğ¼*µkFöè–Ú…–ÎxX#hf}jkŒÆÉéÅ“ü6kd°Æ:&HŠ?\ ¤êNt&“ci&²-µ!2,ê_7%±+Š§»$S%Û#%BÇ¬ÀÓbÿÿr–E£Uxgƒ¿ãĞ~!º8’•	ºõ„Ç‰ªÇ
uô´cÕ>‚gåö  ìiúy2[jİ×Ee<ë\ïîFÎÇ*ÒK0àÏÓNM†5~hØ¢y…^óyN.ÄVò,óC)Y”HkË1‚™™`#ÛsMéßbt‡³±22¹;¨ğ*AÄ]›ï°/ß}3ä0vîØSxl*¼ıúåİâº›ãª#
«’”0ß¢(Â9¦¢÷‹¨ğù,Í 4,3”]7›5kd½º8ş<{İ& ·QGo“â8)v¿ŸëÅlc[PüÔ‡Ÿ°t‡:·>|-h£JJÜviÏƒ™é fÎÃ)Œ±é^”ş‡2hàQ‡Ç©qór&ï…Â´ØæÅó¡ÿø½·>S‘-äv}û™¸ëXCJ¼7Êëv¨¹~ëZº
E¬©Ÿ›ø±­‰êø
ŸööÙĞÍÁ``çtÔdA”ıË”.\Íù£ö¼+@ïg8H¸ä‹ã‡8g~ÄÍ¨pãÈº€BÔ¾ç›‡8Ş	÷Qø’}øİš³ì›xUÁ$ÙÆF»rp‹x¢…ğÊ–öRÁ|A
ÿXu—(%(qå¾?Ö;NÛ]x7×Ír†ù!/ø">®õt¼ú‹$lq|ëõª¸&H±¥.¶¬Ñ…²óMhYN/0dƒJ%…G­
…~:ü;«Gú¦™ù[‰ÈZW!¹RuE\ Ñzh"+aûïX{šÉoãò€:1„Ôè°…%y{ÆiõòŞHÍ$f©ìÅäòDx‚ËDàeø6ÆNGƒvÆ,?IÚNna2xF6Gfä¶`³©)H.Ë–€ xcûb©½,Ñ7ósî@È‰æãMo`ñu{¦”r'àywÄî#”ï‚‘ALÎu&$B%U21¿\lW«|‡T©8iÎŸèj”Sï‚Så>:¾‘ğ&BÁd×Ëy‰9ïuåvêuFAŒ¿ğ±/6M/ãñşÈe`­% ‹¨{1ƒŞà%ğğ$•ûÑ–…ºåÿŠ¿ä±kŠW´tLÏcå)öOgÿQà¶8ç^&Á˜Ûşş«ï?†¡k¬=šÏğH¥ ch69½@ÔÃÊ!æ9[ƒŸGş½SÏTª~µ›Ìà­Úz…{8zšÃ ¥Á£„™‘‹8¤æ¦Õ’É1fX½ñxèôv’•?8³f¥—ÛWâ÷,Ö*6$OÑÇì'*”ÖdÃøK`©5¼—»:èk/ñâ Ò
‰—I“Ööò&†|:Æ;Şûl4'4şë8‘ï,ªpNX-;YÏÿƒˆí1“Æ=kªH",V’ãåÓî¥»V?²«jQH~f„¨ÖG¹)1µ'´{Ú¼	‹o—_¡‰£QQl|uU&	r1ƒùYéu³NaÏàAB|Eh4x¶À€êñTÇÃäƒÉøDÿÄš8#Ú€Õœ|À¨ÇŸÉ¦S¯‹|K«ÃD½9¤WJÅ[£xG˜ÌÛNM"‹äQ=}4¹gjgÊ-vôº„î)İG'‹@oä«í¨êqP’a›ÛÒFnšõI€ ^œ:`ò!oSC³•¸P¾	_ÖîSN­”LG¥V¬ÀSDÌP|’í™ˆ|$†ŠÊ-Úg ÎŒ‚' 0P¶H3#º¯ï-F§—H¦ˆİ’f¶L<e$éFZVq@²s/ÛÇ¢†ÛĞ®–ûM Şƒí™ Í$­aìSx½¤®2³=½PßNfZò\k1— Ûê3d­§£V¾»ßıH®§›ÕÀÉõX½Êë@)âuº9»(„)ÔNÀô+î¼ç
Ù“XI:¨àÉ7²~NÀZµaÄ1 yJìe¨Eé.~°\—
ô¦3jsa±€ÀI8ÆµÕã8cO#–›Aù×LÎ–´ëí¦ãèJÖL—é2P.xo°Hø×F§Z8(¸Ã]÷&¦õ”})1ØPRX]„zëWZ/óİ2ƒy4á{×Ø
‹yİM B‡¯#x_¬ÓjÅsµ!1Ô‘ƒÛo±å³õ>Iê¢£ì› íÁ%Ã‰tû«¸]q+îXÂØCş?9?³ã¿<«3‰Œav'­ÈëŠïDM­ "¡¼æ´…í‚µğ-ü,}×FÎÓ/ë©~[;o·-Lbç[ıê“;:^›k)'6|Cœ–ñì.h’^9>}#g<ßˆÈ¤ù¡5“^/ŒGz6Îi¿îøpë¶+!pf‰F}¤¥¿SdAıks_Äş™GÇ_ê¡2öKÍåç	H?ØÁ×	ÿ(¦K™|.ŸÀÊáO7t$d}|É˜RøZ_XDÛÿ¶ÌP3¼†c€ó|'äK?â£&^é†eÎç•2öÜö®X^O·mH)Æ3ßº>Jß`„O¸‰÷1}Mtêíœ³e#îêê«Šqk_€ÔïŠ¥¼³K÷›Öï¾‹.A½„Í½’_r2öß]ÛqFôò¬™AÖìG<İ:Xñíç±L™
ñöî•®	tu(„ga#	ã‚·M{2*†Et?á ’$ìy¬b@Òéù¥¯‰ù~[‚IÆ˜—^ZÚHcó˜ÖizıfE´¡mã+¯ğøˆ-cõÒ<™¼¡S(÷XVf’%v8f¢yÜteN$M»Føå^­â„&€BV»Ééòe\Ä	º*‰=ÿP/¸‡A°‚¡ˆ {êªW£Pgˆ·ùl‰Î7»Á¼a’oLg÷ZF¡œ¸Jé¾µ1ÓËŒÆå;¤:ìDrº«aÿ€àQÉN]òyJr¦ö÷JwG~¸ß ~è.Şœº‡ŒÜh+àü°qL5¸¦}¸¥ğLæ¶yäRË¸åù¼/[oó)SwN¤_iÒ\'1ÇÂ†Üş‚©(°õ”G‹•‰Ë9 DˆTN“¿’{Àïz*X»ü¦½ÚP³Oàò¥ò¦9Ÿ€ ĞÆÕ¿­xÒÈ¨²R™AÀÕÆûÆ~€9û©ÀØnç?Kd~°TšR˜ï-ƒì4´$ÛZ‰VùÅi¦t¸ÊdgàÍGˆRÍ'Å<H=7sóO9Gı-ãİ3{½&w±Ú4_¥-ºœkv€‡×¾i”µæ=G\c†¼õœ=¦˜œyy~)ÎÀ•¯}Z¸=Ï†"á oî2_¶–Ê
J1ãÄÍ-"ÊO!“cŠL¡ißŠA¬Mì8©xŒËÅŠçzªT…±FSÄ,1ªº9ŠIuêçã¤çÜ÷}ó/<`V_1Ã\€ıƒ%n$â“€T"ÌU½ÂËuKŠR¨Åéz•¤ZG¦*Ô ¡p1œ^tŒ[íô–B+ƒ,³oj‘7?¤Sâ-_t=÷yu”ÈC-L¯£õ¦+w6©€µ¿óŞòxNV`^„òÓÍû†ê…ôÍ=Ä#ÿ&O)İE0«{(¯S­ú€oÁü?xAl5Ny 
İ	âš×+Mn,ª4Q?ÁWH¸Cx9/poŒ\Œ¤HSÇNó¹GË0Õ¾İ7$’øÔ·gŠÖé5…n'kõ]‚Y—buóÆ“e»9Jøh£ö\CàLâ^&Ú 1_—ñ‚Ø%áÌºTw'Hü‘Ëáw6Æİg?xĞ3Âf é¦E]{:Ø_™0J‘á+É"m¡äVÜ–P,ÒÙNüiõÔaÍù‰k¿¶sGé¥ú9*„H:NEèërZŸmZ¦Æo	Æ¬òZ6ºúãWí†£ÓNµôàWåó¾HN”qï´ùrQé¥V;ŒEŒLHóWˆ¿öÖg^†ú‹bƒ¤¦6Zÿ¹¸Šï˜ĞETJÛËå,£‚&k?›Æ×«<cÕ¨Ùø	ä‚È—`ı^At
½G~wÛÅê]Øº(7U{Õka îHj%ÃŠ!<OjÓÈ3(õàºÊßâ¹¡tÖÍ>CEüub1ÚüïqÆhƒ`GÔ/¿=~‰ëO40‘•“­k E|kÊÕá²‹¾›ŠáCÅšKá2˜ı'“¨ù ¨A|C½&c6±;m›«føfÔW²`+e|›¿EC¥úTô“ATky7|7î´‘ÑÄ~ÀıBoƒ/p:ÚŒ=êI“½›\+Äõmï¦¼„w»3 ÀÒbßKQÓ‚>VcD¯‡J†ë&s1yf'ş†ŞsÔˆ
wpÎ+N­‘ñ¨° ØÚ¢C0ŸzÈ7 w’Mhµ8Öµò€¼ÏLfû›Õ›ÓKK§ê4·øû3ÃêƒAcİ“““è#<èzÉ%w´¸³Y_‹£ğ_PO…TjDª™Şñêö;‚QôPPz•»í4¦”ëï8.0ë“óPL'š8NdÕ_M1§?®¸¡cÿµÑ÷wvŠ„Ï¬ÊDânF4ñ]æm äkQF…ÑZr…ñUqŸ¿ A«Yÿº;[J™[\ğÂår·*-qRö(Kª™JŒNñD•!Æ‡§½3 U´f–¨H¹ÍWe°Y¹•-oJÃ¤áÕW>uğhÏæ2”}eòE;./£LNCæ3ĞHl§µ†‡\ı)<è İyk©—eãWóF›	“ªCÜ]1XÇ=-ìóú¬¨w…€ƒèÏH—Ö$:ø`õ”J¤+‚É±×š_•œ=¬'3™Ê¨Å"²˜ífÊ:ô!LõKÒ?İTTÚ‚ w¢+$sLpp\¥²œ¿züšıcØĞå‚|Å½û¤g4P·=W¡Ê&:İ]"½]eĞqÙÅ’†v†ÀÂ"ñËpµNœZ¦5ïEVI…dñ`&íñ];{ì„`'-L|¹ÌFÎÎäÍ,EAFp4Ÿ»Ó?? ~db8—Ã-±s‹¹
{f¯ªãiIàñÖâG¦•7.ô‰•µ À…çîá%Hä)§ó¤¢å½ƒP§÷‘ßæ¬;Ÿ@b$íl0¶˜g…vš¸V»ïñÇß5‰© {›÷õ_®ÔáœB×KçBş¯Ã‘X-	,üaÏåÁß·ÿ¸ õ¼S°²dá†ËF.ÜÏ"{¸À¶’ÑzÍŞñ"şp-„ˆÉ\Ay®=š0J.•÷ş³¬Å±tãìX“ßºÏ€¶E¯¤ÏÙo?ÛÍ´·	Ş»;¼B•ÍßiA­ï6IPpê„@¦»¿9£`ÑåØJ%ºvRB¸<"¥d³?g…3ÄzJg eA‘ô´Î8ˆ+17¢œ\/IH¬`–!)T«ÓôP{ptat“KF
2‰5s›Ùkªæà“RÚd¯¿KTØMÒ¹9#3ŒÙuu¤OËÜã{Œ R)¥ŞŞbZá8šùÆf. ,"Ùm#û.«²F”›ø©sbÕäùR\O›–}±«}¨IXçŒ„(eV\V	W­ëÑ¸¤^ÄTC’s\r­`¶~<&ÔÂè3cz'WX„CûÒˆêqHr·»KÂ}É$“ª_{‘ê¬<%$+ZëSÚ'²H0!¿n†Û”•„Ì›3Üíf8•j’}Á×HVZsôwfíÙ`ˆ·ëğ¹$dQô.½øql¹İĞó8{mI#@œ³´õ8áUËäÛÉÀAwŠ…ìô–4dc+ƒä®KŠfë¹}t+…ÍzcÄ0ü»ÜÄG­4ˆO™èÓçöhóÃµúå˜‘PôNZTÓ¥N9
¸["ƒşÕxï ñéàD¾¹…™T2Æô¾¶è4D	]õi3EWÈYøs'’¬ %°!ÓQhÒïe_‹àÑî”æ>È„ÑW(i"_ /ë…8Qò®9Ì¦z‚šÈ¹ù›½/Èì½~Ú@S„J‰i€øŞ=©<ãmåE 1Là«¯õÀ/GáUß™Í# ²ë&cmFY±+¬nèYÎ^”ø#:&›jşl¢`àÆWöÏŸ<¡×Ã¡`¶•Z÷‚‹Çù qŠòHFt•îûò7º½a9óÑİ9‹"RåÅ“úüÃ.÷ÂÂvr©ˆãmJ×ù3´5[âZPø´Ù¤û²
z‘¦Y€ò{²SÁs»_ëÜiæwIù”]9ÕxvÔ9êZç—mUÚø
€K}¿/T1
4ÊéM¼n@€ß·%`Ûs2ølŸoq”eËS3ÊîÖæĞà	uÀjŠÓÂJ÷ä/V§Ô‚Æ¸ş6ªš3Gè˜È"Õò¸/ñ•=„GÿÛd,º¢cå	^ï™ÄdW²$”üÔ¸W¿¥¤“0%Fù‡H‹rOä„ÓóIEªozè‡ù.w-œa“!Fñ­	÷İ\&jÛ(ÏôÖ/gghêÏÇ'^ÙX_ı€¢.Óàå„Ë]hAìtª"¹>¿MìÄï,çšÆ(&ÇGê®ò‰_”‚e1¸ú»zûïI/v"5+OQ(ºeç@ÃìmÔ˜ÿ7`§‰÷Æ¯œyÉ2ù6´hv>ƒ»«˜àì¬¬¹5OĞ"Ü	£êÊ|²Pñ·€çf[´¬ÖÛ4|Y1öu,MÄõ¤é[a·÷S¸ƒ_şÙ-› XéS4<Xp¿™Ÿ$l\fME[‡BèâfRM•qRî¯ˆØÑÈÿnì3B•4ñ<Õi%gJG½M‘~Œ) ,“ ğYŸÒÎ/Ón;ÚŠ±`dÀø¼º9±on†ìg8]‡éèÙN—ä\3¼œ;¥Wİt5Vòº)	ssÁá²‹€IˆÙpNYZÅæ¦UƒQVÎ„÷X hl±KÉÄáğ JƒK‚ï`á!SÖ=FÂ.ìŒœ%Uçi’Ú’T`â—ãÃ	•?W"óNq£äè¦ÉÄ‡œŸ?i†Â2äŸğA':½V#áè?Ümkì2-W9±ıF‡»öÜŞ„á5J> ì„q¤¿ş«RØŞ/Ö¿sùŸäiÓO¹×R¿uWÕLN&*²ªk`Ÿ İ”šŒ`²¶ƒ—]–¬'ÚuÂÀùëÂå­ŠËBádTå¿qÓîá¼ÄÍÁâ5Ì €a´ÆÜÿê‰Öt÷Ô†_Â©”ˆ—Jãpsš¯Å…‰8öœã>´¾]l)í$=¸!u­¶›5³6G(*]Ùt”ëe¾€(
? “ó›¦9åHadé˜'å†–ˆÔÛ|#|}ı „MššÉ6ÌŞèÚL¡ A’52/: <.Îwº¤¬Q…¶…mü–U=Hœöq² ¥„
gµìø×ìI\l½´æ-å¢SY„¥ÖfÀ­ÿ¸K?Ê¿˜*L)Òî)Ö§<Ñç-AşÑ ¢6ƒË÷ İ1¢üh	Etò»ÃŠÄ¡!„ğëjÒ˜-)4jOÄ˜eÀÅR@ŠRg?Àa<cÀ2JÓĞ\Œ÷dFÌOö|Íª[Tû]G]Oˆª”†ïÃü¿[â$:ËVÖªÌ İáC}wòwµ>ªÔƒ›(j±q6pş	½Ü<ÍÍÀ€ğ"ÄJqÿ¸á–õqÒSq¾ıı}¶^ÔÅÇ¿¼÷÷Ø®Dè‹†‡Ç	³¹Ñšä‹Q”ÏWÁk²«Âæ¸ÚWJ¤8Lî/æÌ7E³¬/­†Š¬Eyiı@AC%(ú‹ÔK¾ h[Y#·ˆ‘bêfŠY<yüÄ}EÏÑõC$KK’aÏ-=€;AÒŞ@åG‹—1EÁ÷KBÔ_E ¾|
I¿'Äa+ÚğıaRañ+c©åiÜµ–µí7Uéñôûâ||ò½;%Yô±ñuëÍ£—âê^×´©?ï·/Ö½!o“a«A×(£ëNa’¢Y~§_o¶—»Ì¦TjñOƒAô¦)³ ¶JáátXØ‹gÄ0!è ÓÙP}.pvIİ•q\ŸƒbƒÆ=`]ª	‹ÇºÅ*Wã.b.,ö’¼! ª™·2ù¬U'©¸Ê“ÿ©è¸V&Ü„/]ş—n»\,µé<O¢<J.E¾´•©»¥N¦ßõ™R>î£””´•æ+bØ£W¢*R M8¨@Ÿˆ•Í
Ò3§‘g‘q{·£‰ÚõpóVäW·œ4£æ–Ö¬Ú¨‚_®Ë şK¹è„Çe@u³f	 âw+¥8÷]ÎĞµk'¬$GZ ƒßÏè òøß®/ç ’CÊ†HX½ÈpèFõüÉCCİ;4R1øSJooy_n‚ÚôüS¥"{/ì «µ¤]¨Î§>íÍlÎ£Øó’—@ææ;(âŠİÉé<åä‚5L$âúaİéÊxÆFaÎIœ©‹üñ[VrÿÛ t×L³E%‡ÿk³ÍşûÔZÖÀ€]Üÿ‘AÿÅÉ5+oí¤u1G/mPDk)’Bü€€  ÖdDÓ/cUğ&ÒìUçÈ˜ÎKg9ıçÏ
"Â
Iˆ±.ş=ó³³^§T)
ÿÖjœ¸ç7ÈUL¯ª>µÑfœôÿÁÃ)¢Oáj@¤‚¦OÄz1{ól¿µıZYqêÊºCÁš€šñ‡À"OR¨Ñw±y'1V3\«kÓÓwñŠĞ„¯;-`œ1‘Vµf;İÀ&¯>c-µ¿¼­ÊæĞbMÒ¼ƒ¦ßÍCEpGÎÿà7õ\ŞÌúqy¨ùÒ3ö;}”pàÕ‰¦+ #ò8å]äÎPw$„?¥m•£–YöÃú=SguCÛ2˜Ân¦xÎò¤ä`ø’Ş9K”)Â÷/©ÙSE	ËÊı'j !Í~{fØ!uµv÷‰øêZêìVËùÃµ¯I‹+ûêK÷`Ç>rğÙù^$ÃñöÃ¨‚mBÙ9_EÈöàíË¹WùŠ"?Úˆ&Í•|gn£â³ wµ¸íõ‚å*ÒàÚ‚ıHc,Ê²¢«s}nı&~SaN „Ñá‡ó(×#EüaÆ“.ša)z3]]¬B'o<ƒÒxš²âi»¦ìâC“tÍG+ßÛEÌ…oG©Švr^å0°ê'm¥ºıeÚ+>ÓMğTË¥ç†¨5xòr©j;T[Œ¶Ü¤ü«~­Ìš%TõÃşOˆ*Š×i¸	bL1eFhèì}Ş”œÄe9eùP9×–”£4ş‹‹6_€¡F¼«§íÄglï¯¡ã¨ûiÚ¤¾ãım±û*‹‡IğY9=Å”R”î'¶Æ`¸ìñF"}{†§ŸÿE3ãÕLäÁ¿.5áöÃÓµ¦ï—Râ0êK‘5#¸HƒåèÑ5çøÇ‡¾È1™´ÀÜL¦öU­Ù˜‘I¤uğ
£ŸCc×O?µË-~ãFq€áê¼ÚætEk0?é».à…ˆølº±ô [í+]½.ìÛÌvãÛ:‘eÁº+~š ÉºÒcne] »U¶Ãê¶wÓ¤ö–ä]½´“ÜÆMº[€käŞ¾Ê«óÜ»Lùß
£²mœ$XĞkÕ·'æ£ÎrĞó`ÁY„r	{ ı@Ì{…ÌBÑW©©¯‚ q5¥%µ_ä­(bYÁ¡=Jİ™Ô‚è8
M
ùZôê;Ú-ópcó²˜˜ï:_÷3‚=	LòE’Úo6†µÅ%®G}Á“ÜWXSİXÒëÓ°kX¹
>Š1†øükÉÕ3‡wÍ#I½ ®b&Ì'¨š½e&éà†â(`4“…§ğL‡ş`1gğ2¡ÊÂóÛ<wë¦M~ÂtsiQM°Oå % tçøı›«êğõ°ùÚÇ^ù¿Äj¸Ó³lS‘_Ö³˜ö7ØÉ°NJÒá]¶…3NV	Ø™{°úVí0ş•öl|†Îg­ÿÒ,íg-kA†¼4³¬Š>DQ^Cšˆ±ŸQZu)ãfÍ½WpŸÉfN4ı	.Ôøû ñÏƒ¥'U9‚ÖP.q]bF0ÉNkrˆšä{÷¥™›m4<D)ÕÏâ¸¿‹$Öø,Ï2Ç»åDOcÔ	'Ê==ŠºgŠ”umwï^S(=w8•iêi÷[„€0v|SUË>ÆÍÍ
/áğ7ßìï_;ïålw±Í½iõşæåb+ÚğÈW%ÂÃ%Š€×¨­-Ş»K  PÅ;E¥g³S©úÅ&á˜Ù9!j…Œ‚|*På:YÒŠM»ğ´ˆ2SÅÊ°6ºŠZöœP{°3½z¥oUPYg" F?~¦-ŠæÖY7¡·ŞšZ!B-<ø¶å›N½UiZ)Õ$Àbm4}"ÒQîi1ìÀ8“¦ôì)*“)ÑÁFb ¢XmÑÉÃï•N4Ğ/<°Îmœ–Ç%–Ë÷—Œ›!gêÑ÷¸¯(ÿ6néZÂOÖcÜ»X¿ş».ÖÚ¤ÍK"~©ï\O_¸æ¦Xëš=¨oéªÔV‘’ÚıÊeZÛ·æƒ2ı;wT[8æ`°æú	ÉÅ
Ö3$ı¥”}{zò¥èÆû,p•}Î‹¼‰k/5¿<¨Š£a^èşèúºŒ¬uúó%¸¨OÙX'4×²§f©àyGÂÏâì˜wÙNˆBĞñê×Œ¼Í´£¢ÂçMÅgÜ«óVı‹—%£è´›ÿ)=ÅÎI(IBªwæáA}‹ÒÔ £De>šR6TÍ©ŒÕ·zÃqjˆCPÎ‚ú¨rÙvË«Ì¢İ™*+L.B=tŸm§Ãà¨Ö@ˆ{¯˜×%
f»lŸ²ŸŒĞ®Ÿ¸9­J@y½A,¶=?ÖA9“ç{¼Ûşe¿\fÄ˜Ç™'ÉQYPLÖêHÏŠ^Ë5Â=ær÷2ûĞ¸şFçŸB’Ö1ºj ®™ ³”½¬«G}\¾±g‰´s+ä_1%Á;xoĞûßTc£7Äm‹7áåî–ŞÇ%ğl*· »izÇ±Áab
‹_| ^•¿Öù²¼7,e7¨Ú¹•¼q p_±¥?üÃ¯;á(Ób"0úİ‚q¼ãk ÙC»î·‡F÷Fìê«÷vƒœ4:›öğ=ºúnVÁÃÈUgÖ±Ü—Ê…½K~qn"ˆm”ğ#jÇÖUkƒ÷%TW$Ó“~!ˆB*Òã?°¸3D¨‚şñxÊ¶ª/x{TËC=Î,`¿§@¼rï&ŞŠàWLİ®ÀİÖñÀlN"N
™å•ÿ€	Ä'èÔM’,[
UªPØpî©´Å<1$¾ˆƒv°,¦Ñù€¬X†k,¸‘İÁ¢gq³ëYWö¦ïhQ!Åù˜Ø¹I«‹ š]¯=zÚÂÊ…ÛâJª–ÆÄ6Õ'ã55k9zÛğ†²4É¶,œ£˜û£êñ…÷39ewËÜ•÷=6ö$şvxİM±ê‰a¸Üü"çU˜sıãŒv¿¶·“ZÿñáPõ[¥râj#«æè¦W
mÃV‡¨í$ƒg>&•—5“P»é ²-*0($ÇòÜñãt8MÍ†ŒBTÏ‘CÏî¨Q~” KM!š½õZÚ~éµü6V¹SÓÙF¸¼l¢Ãb|wJÃÀu –…KF¢ŒKbß[)v¨ óÊ°uë$d¿™ûÑàPR«Òz²a”£½*Uê´MCev5fÊd‰*ò"û/š2–ş?f«"õ¬+ùˆš39¾JÜ‰ŞómCkªòá…²§˜7Twf½=µA¤ÚâÏq:‘726‚Eü¬‡FhôZÜÚi5sQàÎ+°|sùÂÌW±ğí4‡ Y¶ùGK (=–#k!ù¬Ã&R6\ˆø_|(°ğ4
-Lˆ”"^ûÍ¸;ñÂ¡kÀk@é¨áJ­ÃıY»ıİ¥qgÒs}(Sm?òÀg¾w°:f EÃ~¬¿(¯şô?Œ²¸–b³™Ó‡&C,Ø¡òËÈ±HÁ\s‘„–]öm`ıYoHîôŸ“Ò©
Ş
ïİ¸àğ+!3ãy"@GmÚTëŠˆbp#¿/4ŠqÄÚÊHTİÒ¨<‹¦G/·®¹§¿$û…¼”—tF±:“°ÑfA>D¦eCW^Ñ²½£¼ÖşÆ²B+e
NËŠ[‹ŒPÍeÖÊlşìRğ¿d&ºçš¡­f5(Ò.+³Ãe­Ó-SQÑÿ‚îY[U|‰ê@k°¥Ûù>ÿxuƒºá›ÓŒ±[ÖŞÒq¯õî—ûNVÄ]/‡ÂŠv¿ş´iË¼ss!Şš“j&\× ê·2‹ÒjWCÁ>Š#†tIÒü²ãüPôpÑĞÀhı—%1Cã †OPú,Ü;j»×„­ˆjÍZŒ*Îú+«ï¶ŸO5bd×®ú†…âÓ­Jel‡“—Q[M†„æKa!ÜúgEçR§ì“¼‰Ÿ¨Ïn€Ş0ªÎhî‹UÎs¿ÀC†	¿eÎLAlàaØFE¶;ª<[~ÑÚÂüLC¿§±>)¢3‡^Q>·ôÊ DS¡P:G\k—¾O¿¼¸¶ôiK²…iìU^Æ®âíØi
nÜGpk€WJ]ı è¦ÛW×q¸°Ê´ë§ı¥Äî™x®™åÈV»CÖQe†|«)hqû‡¥ÜÃàª·‚å>ÉØ‚O²ú/Û€kHy
ãÀU‹Èm¼š¹ƒô4’6“¦xÓ’zëöù©Ç1®Œƒw´xFøPhuf¿‰Ü9x$[©¡à³†•#¤›ê•±xé !ô%îÃ»Á%¥7ôV›¾†‹†¹¹ÕÕã˜YÒT´«*@B\&Mi?¡ùÈâ_~®>:¤°c2®†]í%e/™ªÑú¬mõÏğu~ïü´-	æ¬Á°‚l£¤õ»-
A‘øÅµ¾÷	æµ“QK¢ÈÈl\AMïÅvµÃp¨‡0Ñ7EÍH“&Ê{Èÿ£À{	'³©ğƒW{/–…<Lè9ºò\ˆ‘_¾e4ÜÒ=jİ›ç)q:UšD‘#lû”dûu!æy§—õvS%p•	¤ñ9òh_Ëõ$àPŠél «rÖ‹vÓÄDÏnGÑ…³ñœğÜh‚ÌÃlõ¦*ÉçHı¶ »Êé±P3>kw)8é	·ùrÄ±_Rë7ÅÍOˆ•“V‹fÏwşÑ*'íõÎß¦5|b†jË­™JıÁ1²SåÁC‰ºä™–ö…ıî<û‹¤¢'RÜºQ¨Œs‡Î"Ó|=Á˜²’÷`ÜO»İÖ¸x¡AÏy³jß•k+©ÈŒ0D~å©`·òX{¼â-D—ûŒ” 8”3êûdH|(;–*:ë|eø<$©&AŒí¤€İÖÊÔØ^…@äMoîœØŒÑŸ¾1ÕúAİ	‚}r³)E<l2ê¥ŞzP$J¦rÇ½ „~İ	ˆz0z¯{°`Ì$ãµ=Ö’ X¸¼õe´“†°¼Ûg&¨![’NH¸K¹²Ìªv	‘û­–›YÏ_ÑK°­Š+Èï!æ?‘EO×æÈD+>ù[Xf)]¦s¾±n•¸&t›î,JûÉ•,BëîÅbùöÊ<ÄñxÔş	é\šî|“£é¹9¯-ïäµ§E4ø‚qsYåUØs§‚Lû¯âzÔzûsr¼á~ë:Aök êdØm•I¬ùÌË'$u_5Ùq¥†È8ÚÆz€}¤g—şZgf¶'xD¸ıhúªÙñ 9›¢ã¨hÓ?Âı‰¼p31Û¬Îws:`Ÿ·ÕKàÇø']·»"æÿ˜èÔVsv)k€,÷‘K÷¾€~—¨Ş ”.Ğ»èa!¦ )ƒÇuûM88|È^Ë'òÅ¾=¤ÃÇŞŸFòŠçÛMºÕMÀaïßHÎaHNY!Ş9XúòEöU|ù=#çJÉ’õÖÁ1ßˆ¤ã,¢İÖ®åEŠ¦ÇÂ×ı!D0¢–›"ÁÆ$ñ"sÂÛC !îæsŸ’IVtÙv³¸Êè?
™W/ÁÒNñèÕà¤ŞóH©ğä” V¡ûä\i-©‡¹„ …¾'ë˜HËã x)£’à{çÖàƒ¹8u0Î‚¼ˆÕŞP0i|Z 0şƒåÌ¶v–TdäÁ—ù A¯ôe´¢»›nü"{yB}NZ {#V,ıZaC¼¦!×”¥áò¬ÕhØ‹Ÿø¥ JíO,¦ÙnnóŠÈNœw¤İîH]µ¸‘-²½Î4ùı2/
¬ò0×s‹$–ò” Oç¢Æ§ç˜#nÏ4 Ñ÷ÚÑ	5ÂÙ2{|„í®µ£Lq_·y£î‹*” 	eÉÃ¦ïÛw©¾ËtÂĞl#aÜÉ€ÎŞÂÂYi=Òx™VÙPéQlÃÇb¡-à­Ï¸C³Gÿ”c@Ä-ÓàiNÆ3à=wîNQZ.zM–bs9<Ğµµ:¡dk¿/p‹ë¸ıS
ÿÆPœI3,=ˆŠY/.ˆ·kèQ™_&ÒÖÜŸç.MÅ„Ş%1Ş@°ÕÌ6Óõcx„Í_3.jÄÁKPº347ômÛ~¨j²`éxçlâ‡3ªàóÛ‚˜}Ù3«•v²_®&obCe[&Ç{ËV?ê>‘Z¡AAI,D›¸İ‚†òÚ?Ò¢-
•%ÀëÑ¡nË[
%Òn|ùá2¼Óf·J„a%[ÿ’g`¶i›Ì&l™õä	äÜÒšŸÏív{†]lIşFÌÛêÜu^ÄIl'µÕØÁş­°*mlä»w—ä—H¶×ÁœõL´æşÖ]-ADz±ş÷ù`À&<õùÊÅ2‚©ş¯c #ljŠ´ƒSmxÙ3Haƒ*ÃPµÉîƒªéÕPTÛ®Çˆè(»â¦â¬ÂæsU Ö:?s?KÃéø¹ˆ¾S*Ú\şÇ€Zôæ6‚¸k ?2šíBnÒ&.uH1 ĞtøHcó²Ú©zözU¿é)er(/Y ¨_?l•Ÿ›~ùÂÊuëª*¤Ò/Á)ŒK´+0©R$(Öjß5ëò˜—ş¿–Ï_<R¹…Ohã×Ø°ûÚ]<aã4ÜÔÿÖ¼ªÚ§o'œò‘ILêX7·`gïÃğhbN‚sK|hTùëß27,z¢)èø9:ç6Í”ìOvœö¥‚­(8e™`¦WÊ$ùQ±Ö&´ëâÑ5:-ïíÍ£[Õ¡Qâ5=1$CÅú:¯à½¿‰ê‰ü4½{{7=Ivv>×ª][N¡hk¶–E¬½S%h¡€¤İñ@b„®Ô|Î|ÌN~çì°ı±µO2msÌF´9EÈÆœü“ÃcNå¤Ó*U…ò,.ğ´ n#l7W´L1Ô½/)r»Õ¼|©Èº«RpmÈŞ´	\=ÃFuø:vIã”@u€tÙ~ıcöƒI¡H«NÀ;ÖuÁp‚”#Í¡ãù¥Æë}§Î=øûˆ+ßzCîB¶å„Õç_D¨ 4"Zgvç-ƒ‹xı›ú¶æÁ4èÙÛç©ô˜¨$g$„âD–—Ú6Ñ:îˆS±!( rô4+@•‘n Ó™aù9¸È!Ãß€›ƒÓâô:6OºcÁXéúã£ştV}?ŒA0ˆ|8SjeÌôFßyp¿Ê“zê	ëxÒ)±NÖ<éğ»B¹ü58¥T:–|J+Ã± Zl‚ô<ƒ¡óTSö#P¡ÚÒke1²}HšûèĞ÷ÈŞvB¹ËŠa@%}ÔÌÄ8¼ŒÃ/?\šÌu’}7‰âÀŞMÜ¥$¦jò\PXû?$\lüÎA²ªÖæÚÂÈ¥g€ù­—Ç)@©Õà<×£~÷Kì¡­×@@ ª¶IígiªôJ n‘†ŞOïÓ¤¹b¢ÛÙ(uw{I&ß^Äè'ñ|pbÊNgË>íHp…hÓ}¤Çõ¦UéPX³ìLxY¬ù/7ÚN!šŞ)CŠ†*Xÿ6é¦R·FDÂç•WÀÊ›€ïtZêë¿¾ó=Q{Û×gé*²;í‚65öæÎHEdB¹cız'· ÌÔ—ÀN1uaıoÈy¡ç¬hÕÃ/:u¯>Å×¬bWİ ½¦>Àôğç…®;¥·c¼ÎŸ°H:ÊwÆYÙ© cC¢JÕï’"–/JÌĞˆˆatîıƒ–¬µ€-,/¼ 2³Bäüá6[BŸ­vhÜ†S“’ò0mf~"'ä£¼½z•k"ÙÅQo‹[µ±E¨rÔüğ­I¾Õìÿ™Ôë
6*3ÇyÖ·Šhî¯¶^,j»å>ÚŸ¬–	 £Õª§¹ĞóÔ*&?¯›´"ƒÊÙ‰ÖÚ8NØK+è=Jˆ‚ó»Ç:0,íÒµÕs|˜,ÚÌ £*¬-5À÷QÒšÅÎØæÁ)	–5ı1ÆHb„=r‡£^l:çè#Ã±ÖAv‚šùr5ïNQæ£#¯‡¶c0û¼[gÃc´¤9 ú±,†{œ-“É5XÌ½óéâ—-)#°‡=`Ùÿ¨Ô9ö]PU«t0HE¯ Æ:?Ã­[r7®ÀÂX/Ô% U»0§z' ?“sîdS|¢7^7å”#?a°5V¸cÏî¼a¼@%wt—RiZêi–]c8Ù¿?‘	»]Z)!s€_ĞÊc®P!œà;ÂÈ#3ññˆÿÀC*é;'Ö’+P®º~{ªR‹d¿8iŠ>w…èı‚ó_Â†Zy”¢¢oÆ¶’mhôªZ3Qÿü‡á º4•ÀZœŠ=Õ½‰2Ú<(Áƒ‚p\ŞÕkzFoÄ^à½Í¹Cs83—=ª¡ÌvQjº,Hú?ï'_ådóWü‡ôƒ~>Ê™Šé6iy²ÒşÚaK­»¾q!Õ$v•›”¥Ev?÷}[Ñ˜&8Á³?ŒM$ß@R»Ù²qÔ÷F½mÆœ’‘UYø"Şì9¬ëWÈFtê‡õŒd>ØIu'F? ¬„Pº¤0é™–P¯ùû'D¼-C&ãì´OIé÷0Çˆ—JœÎ5h—|‚ğê|6-–Ó_¤|v§Åƒ¿Ÿ>ëh_{À²Ÿ³9è«¸êöê8ğ¬ŠÃ©°(ß¥Mù@
3¸ÎÊ æIÕI‘€äÂğ§Ë`0„i>«Ç—ïg:?cí6õr$(½9ÉÿÏ-! Ó²ŞÂö,ú*;Ùkw¹õ«8u(ùì\z¤¥_oqÉX¬ó´ƒ´ÚU)UrNjZ·9»ßPÈü­¼ÅÔÀo«)åÛ1å•€é¯µP;õ&¦ó:µ_!±WàWÖÔ[Ù³ê‡ß´ÖnØ6FkøvG  "ÑÑ¦xòøt×Cójê6¶Şµç=7}MvFä9%¦&Ÿ­˜
!Üeï’q•ê«Vå$b„Å+ëîEy!of4ô¾åNWĞõCüÈÆÄ)f€ĞdåÃ³îm¡Ìêı1Ğn)„ÃÃ ñm{Ì@€™#%C]eICr?c,¥VVù›ÿêzWš/¶Œ-¿\h{÷ƒXAøüŒ©Ñ™mòÂ6®ËI6Ì³„ìòy‰Œ¥İÓ«;ÈeƒªàÅØ³×„É¾ú3ìf¾@·ÎBèÀ;×.@ğñ˜V¢˜ØcšØZZ\bGâÂl(ÕÃ˜T¶»/[à´àˆğIIÀò‹aËGÌ…CQš¯÷ZIµq‚4½ÕşÊLÒ2îuÿÔ,+[­¤<·ôDş©óé½%\Û/6Tû#öı[ê9s”ùš[ôkwX!/½oïºÌaä™±ìaQgOrûZ¹zšı¨fPÛ–¡¾ú3C›p¯ë°¢ë›uÍ.ÍÓšq{•Zù¢'‘ú?ÿI¼ı¬„†Ñ	„ íQç_ÓG¬nØÔê7(Ó6@˜-çæZÎµ…Ëy«˜rÃ¼I›é@‚ØjÁƒìân×ŸLÛ`>òñ2êŠ;<ôQ›R¼’Ëoï¦Ä0@X¥ïÎ©Š	g-`ú»°L˜ßı@Ñ†ñø¾tKîf®eoa”n~a”Aêø9öÀqªïÙéÕ?‡bØò:4n5Y¨¾0Øñ/4ï}ÎfzÀ“iûâ†Ï/ÎØ÷eÃ]ßWË/«%"ÜÓl†‹ UÙÌÜéë´ódÍöÔ³‚0©·\21oÎ:#Ÿr·7@p§ºnˆbQMÖ);c¤iS“ é4Wæ<HÙ„6¹ç³]Ä4§spÜO^¤ÂÂšKÂG~d“Äò¢Ê·â£?%Y%dÓ÷ßÖ&Ï|aëZ ó'Òä¦pµ(“ñŞ4 E÷Ko!ã$ 8{İïæ”ì#·›X'á8ëJÜ’òİF°¤­9š÷ìúO9v¦uÒç‡Šù¨;5ëë`ò6on‘}OçlÁVÛw[Ğü~(Qå²š•_³wl•Ší9˜Z`¤»»6e½ÉŒy×ÈËË%óOóÁ¨N¡’”·‹üÎ¿„GlÒ--w7Ö4Fvß×Vöœî4mö`œp„´o`Åsc–.ÔZ}õWÄ§Òg7fìËc_&âa§şc¸ÓV6]FÌŸªªÌyô³•iÇåY™3_ç|7^Z&ÅŞ‘ĞJ`ZiP%zÜ¤‡~ÜB›„E‘u`gŒ•S=ÛÒÛS[¦	g@ı|t=jZ#½6ºsèâsø¹a¨„UÛ^†¦p¶åÏÒº¬ks#áSÛÖd>˜,[ÿ¡(òp†róSJçŸŞ„=P ¸’%Lœ‘:3Ç§Ñ’
¸ŠQ¾-j•ŸOˆ:›½iÅä,ÓBØ=Õß$#Û…y~VvNb¸%~;4z²QKüe<4ãm|q)cÀ5¶ùÄİƒÓ§r‚Ì†ğ½²h‡NtıPŸƒû÷ìúS|Ñ²¬édJL6v­‚5œ¼&ÛJ¿ŸµÏ·Á+Ê¾—pCQ4NïuU!HcF¾y¤oÒ¾d
üau
!êj²ó×t–»DHaïìª‚ÂFŞ¢ˆJF9úéMúšÓ@\òéİªßí1&DM´éWÇïâ_Ï½F>ŒÿdéÕ0¯¿|Æê.`Öü8ZWŸ.•¨¶³šNõÑ-i=ß¾±¹ó÷€å	Š< ­À”äİ`‚Ô¬o<åj4šMlğ[¾~Üi¢½…•’Dkµlà·¢-ŞO€¦D_·VìÉ}ı
Vw*Z~BZáâİ!Ô>8]Oë#÷ö´¦&›=ÜÔ©’q×°åŠú…<ÎZ§ãfWá<ën¥ìáƒ"ïb’Ôt¶°&ºÕoêÕ«t-¼¨i,Ôøñ>ø÷Š%õÇºĞ-šó@æb¯Û{,}g_VÙ¿ÂÁŠ9Y!l‚¡ÍŒZ2ÅØäG>oFÑR|£“ O„(ZÄe‰SÑb±†¡:Â
Âù¤á )—ólV Ñ	¬4"%Ø¨Ş$±'C_uœBş¡ ¡£ié:{cî*=§ò’B«¤Îa¶UyÏ^±â!JAØ‚5»`SI Ù•î¬ÇÑ7ÙèşøjJx£ò‰Æ ªTèŞöİœÎÃ°Ô‡e”ÿ¡ònQ™9«vÒ.5³*´|Y¥ÿÊ¯*š™âœô}}Wİ;Ô”šî<ˆú<ĞÄqÂHz5Áğ…(gã;Ê0×Úˆ;#Æl±2S«cÑì®[Ç/ìH¾çO°ªìm­HX†-m™H)…Xé¦çQ„TÄ		%q@V5’V‚¤ 8»püÂ@<¶q°pOig“Ú8r;2\lÈ®‡t~Ò;`¦ŞwØ^Ğû¯æ!x==?µlìğ[ÊR½ÙQiœ	â‘rmÖëD‹aìõ³vµC'¥JIÒ."ŒƒuÊo©ì‚fç$v/§B­nãö[(Òf«Ì'İ.^Şø†+Áƒ{mH*#MErV®öû\íÉ{ÚYiùæÏœ8ç\…WÔü+Úz&åG×

o&hFæèÀ8dÚ¿$¼¢@Á;„­ÍéB¬AºôY«A-şf“5ˆQqqN= ø"ÕæîaÄôÁEUvï.¼ùÕ¹4°4m¿@
Ü–ˆÙ¿?È2ƒ9:Äg‹5Û Ò„I|-jaåŸÒbİzÓwêÖZ¨í’BÃáoÌ×]–RˆP*,ÖÇJ0rßğ}{€äà\‘´Æ#Ê÷}Èr—ˆqylÄİïB©X‡ØÖÓ[ÆW¨¹°:ŸvÜlp¦òtº~¾õ@Oò©355«³ÛŒ„x¤ØÕ–Õåô*:/lÂñä3¼Ø½î)æ¾UÒc¦¶Çq•÷ı ¤®TpmK©ë.?²îzá5
†ñh9WlH,øı&±X1%î}…ê—ß.ƒU:d©¦ËnõJ“f”¤ŠLïÑÌ9,âeFJâÜn$„tUpÇƒ.’Û¼ÔnVÏÌ1Ğk
±O)¬+J‘‰¹Ñ§ë”¶FS§ì‡…æ-\ŒàªGÄ	Æ'¦Š#8'49NJ_Sí¼_I*Òl¿;?5}Å,Lñ¨íjúÆW:»uMR´t	uAs»Ì¸ù„İT°äú7ÛUà. ód#d'Ø¬“Q²y~y‹‹Ş§ü¼bˆÊ9ì—/OŒ†Óz>yŞŸª]Ûø’-æ¹q û
é·!4(ÁôN®/{iqn¡ÀrAıK(vz6ÉÏÔîº‰ì¶"Ö*:~‹ğ Ù®DD×LÙÒ„¾äÚbİšyliszc/ ¦}¬ñ`ÛùÀ\].•´ˆ›Ûa_À#8Şêo]#ŠË²¿Oığ³Ì !¦Q·|Ú‡x‹ÛÛ@Û{vpÓ3*5_aÁx´í0¦‘wÒÒ:?Ò{Ãh"|yœ8‘ytµT•[&e”1Ï-”æfá@…±ıéz‘«#ì«ü]¶4™(º Ş†ÓcC•i
¼¡öÌÙÜo+Q¶2ºO‰ ŞØ“¸5¶t;Úu¸Âb™x‰¾€ $ïNâdúQ˜æ­Õù#ÿv?y²mlKLOßÃV‚öæ­ÇåL7(bÆİÇ–é«³b·“’{úÍ^Ÿ>á™yêîïw ¯›W"2"~v”Ğw˜ËŸØ]©Z¹èÂN·œÓ¥ïÇ5T–·Pğê¿¥Q±a¦ØO`œ5éËµÜâØ‹«ù/ğqürşçk{ä.V¨M¦YØ8(î ZÃRƒ6ğÜf·aÒÎøJĞc²¨3ôØ÷”\¤\­`¬ÅMQş(Ä–ó‚•dRÕ+áHĞ]h€ÌÄ&í†+±˜: 5Îâƒ«@¤’ôapW‡ù3®ZN†RJ1Ö‚n•HÉÜqEOõ©Y·ş°@|Xfi%¼'kªƒ=JlªSçƒgúaƒ+Üf‡W[<ÊÎDF`•]o{3J{Õ‰³# Œ™döŞ!5îB›a˜äPÛ“‡PÈ#³÷Y>$_a·ÿø]NÌ0Î¼‘äÅ«"¯¾&Î¹Ì8ßÖâ+-¤›*Ó® ğœ<ÿ€\k™i-ïZKã>şŠù¶DsÎ+–YîŒìo¹Š_7ş¿â¥ÈDáÏTË“~øˆÉÔñ´o29&,iëN!u•ÈëRãÒíÂ¡	†	‚-£E«tÁ?èÀBIü…´'°9nÛoiÕôs‰«×ÀH± 'G’
µi.ÙØ£)ü^}ÜÍôÚ÷àñHªüUğâ}â|2¯C–Uå[jº$¢7§¸˜ºaÊ ]ü‚ù“ÌI(Ô/ğÌvÅî%¨İY_ŸAj†| ªèÎ2Ç™"'Ña:Z‚r??)põ¢óÇ«ÊÒHx1ßM×!ĞS½Ì„›h(„ËšFn;:Å„ˆ•…3S÷N¤OÍ&98ø~:5ıèb¦¹S+a[oYíiÇ]øGÅë0ÔMGbã³Ö™ÎRù[@p‘˜Š;:QİUì w²ä>–	Q€
SÈU-.£O
l2û³„.¡©¼÷Ã«@Xİ¾Ğ€%NS½ÎZ^?½‡ ¡eÃ]KœÖŸ²Ü¸z=Ÿ´imCHPé¯æ´×»Ùb—®ÃÆB{çı³å÷ÀóÒì^‡Å³Ğ¨È10=Ş^ô¤!Î±;eâè'wx¹à}¼Ú‡‡ÒÇ&ÏëúƒPv£B]ªN|(ùÛÃb<x{Ûû`f1†nâéG£ß*Qñ–QÏZéûƒ1HæZû´]•÷Ñ©0â¼[¹¦4o&fCnÁtw]#ú`4Q¯°§Oe’,¶•qØ+Å+¿ëçªÚ­]v[+”¨3PÃLŠŞˆ‡é¬4ó‘F×af‰üõİòæ?>€Tr
›ø6¼•—k:Ş¶¤àb>´#1'?Õ!ß|Î gÿ6•7-µ/X rşÛ£CR…İsĞ,C)XÂT”ÍÔ5Û«(¾'pH'÷ŠŒ+Äªê
˜
m<X‹z¶º ˆ6=ÌïKVê%oØj3—"{I@­çi-!õ”ís¼‡YˆÊ;×¢2İUˆæT#µK¥§çŸ@EJ >gSLÄbÈ:±ºQ.Ë"±‹hgŸOüŒâ¿èTEú C ³¶Ê
‡¬lhmÅ«€ó’3
“é_"oš¯G}Vë§Ì+
_5tH\€iü'q2O¦Ì”Í"¥÷MòôÕA+O p&w^’^a q¡ÙHÿK9lô'0ä",$Ûz2>ÅMÅÿØÜß˜Iª(dË• IB‰‡ÿ”sj(/˜˜h£ıÛ>~JÏºèGÆôlEúzÌO>Ö½30]Àœ×^U,ª#—'-Ş>øæ.‚\°UÃG³şûû(Ë3¬§ÑÀ‰A_–ı(Û=6bŸ€ì,İÇ~hd¢º´êcÿbœÿ‹á|¿ å´ºPÎ•CDò+9iaøËPb(“æ_–8­Í< „=zM¨EÅåâv"`«OC;–êdUV‚d``1Ğãh±a%QÏ°fheu oõÈ9wÏ´œ2]5)ö×£‘û[7™¶³&¼;pI1¸ kğFzc:åp²>Ø$Q{3Z†cœ¶2»Ûğ@@:»,‰x¯™ZÍ‰L°¼ÿàî¶|…cÛ(fXé¸#/Ñö˜¿âÚC™ÑßşÔñ×O^›,t´e´sÅ`¨Üœ:[½cÉ—¬
™€¥-	û%?UÆŸ'hÍÀn8Ëµá±¸ïË…`<  ªÔ3Eÿ)Ğsí¹8ÇSöd<ŸsÔ&Öƒ>ÇFÁpÚŸ@pzbËß0“fo—Óv„† §@N9”	¢‚2˜&3z9Í²Óu=¾º:6É#
üíÄóÚr„ğx'DbŸVË¥õıQ«=M}ü½¹{..0õî-n9¬	Ûüå¨ Ô[Õ;u*Õ 6V¦®;FØ9ÌI\%áüÅ>î'‡|ş•°ãÕñÙ/‹\p€~ äqeÂ¶‹êÜQ¸¼”ÃÇ9ò!)Õ¦QÕê#k-•/ƒLƒµO?üN è1¬zÀrp:¶,üd]‹Z:|—Â”‹)”Pµ8_åX’ì?–×»Õx2U
êõŠh)á Ó)Æ’ÉsJñy#¶&À½ÂÈ:Õ]=ñg@@ d¸ßÊŸJD÷ÆÌô;Î7wàÒRŒ)}‰d—¥SEï;~2ö’cêœœçM¬ãï~%=Ã|{†{/øÉµ;Ã1¢Ù´{ã~A —(šéåÊÙE)?"Z¯ß4 p™Ñÿ·²$–²ëzJr)¢àÄ/ó/¯èDO½YPÛ»|n~f^fáe8«f9'EŠÍZ‘<,K´ß>n¾Ğ~d³/¼G„l‰ìPä”TWHÌôHzğz¤ùáÄ™Îâ>B±Ia²7ŠRŠ ÍÙµ˜†˜ˆ<ú¬6²˜i„¾êÏNôIPÏ‹;À_ˆ~çãr¨NõŞxú¡{2·Ù¼\i‘ÖDl©3Ö	¢©µœÿjd Ù»#¾´¶#ıÿVqÚ°ÕQEÔz;Á	[àWÏ÷åô¢±-Hí¤Œ§ŠÒ‹+:£„óæ½p¬Í­Ó€~ÄƒÉzñÜù«X¢ìcƒ(z(ù¬wvIĞ„ÔüÙ=Kenñg=I¿q
&î;I˜ÎâGVq“B‚)êÙ&mÔ* Ê”ÈLÈü²š?Èï»*”ûÇİdC
å²Úï‚eH"€rc´]ÍâşšxPYšŞ8åİæÃ¹¾OOä§íärbØÅ´BQxqãpÑ5H’)NbCş?l0•'‚˜0Ø«6,IwˆÅZ®¹ŒŒ`lX¤R&2¬§1@eŠ[Óî_{33.phDzÆËfsV:Ì[ù!³¬FqPZ˜Øş½İm5ŒÌî!¢¤;ÍaÌaåï“”ŒÜFø°Êğ½:y=’b	6g7Ùî¥­şş>¯-îÓ/ß„=ŸUb÷¼“ê±§^`	z³Tò×­£9j›ıóĞ 5A“ŸêèOßjÇ;»=ÙØØ?XNW»ƒ&=_ßû·³€#ä®oÁfî)ñ(ºL)Zm}ù™{¡c:ó{şZC[®3’ÊÓD5¦ïâİôÑµ]¿ÇÇ«z(L4¼T‡‘±ëbnI” Á­Õ¨F®&„ğĞŸzÅ—Úä
PÁRÛwÛ@sD/sF”Âxg  y•¢jù}† ˆ¼€Àu™–è±Ägû    YZ