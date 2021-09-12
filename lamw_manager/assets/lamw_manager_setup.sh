#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2592133703"
MD5="498d871eda8395a8fea04e489e99237b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23312"
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
	echo Date of packaging: Sun Sep 12 19:16:00 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿZĞ] ¼}•À1Dd]‡Á›PætİD÷G§S5ˆX/¼p£äÉ*Íú-Ó]m%í9¹gşs§ª£ÿøpet
é•f$[b-0¯HbQÿ<gdâoÄäÑåÅ¾·Äœš˜ÿîØ×tPa[CïdQ?İG$jf€wH( øø@1ÈJÏGi)”GÆ_Õ#Ru-/Èè[ı§©×sè[ë®Hr|¬©wTršã zûYPî£é¤—JVòÀà”€6–CÔ¹6Ì·6›‚ôYd…çl:´Mø‰z&c42‡tEşwGé½âø‚ç¢4áí0I¶SãëCÕ"¨ÄÎüŸ¸Mqğ×Kq¦3Ñ¦¬Ïı-eœmY¨ù¹2`í@¦‹œ*­j:`«‹¦õ¿xÙ×úK¯A‡R©åâÇÏ~èÑ]>3T>©FzŸ¯É¹5‚¼å€/ºÓ¿øÅ©šwĞR*Ÿ˜Q2,}ê…K„‡«­rô1Àö1Pé’ıä›³iˆ¤p•è8Š-hİû÷Y7ëµL®_`2ÁãÂ™H£ö=	ÿrG¬
 ^ÌX$¬†V)útKB¨ÀV™éuö‰“ÅBÇìcøšüá¢“Ê2}Æ:pFL1š‘LrƒÏÌ/#;!@óá˜™BèË³‘³í$€ŠÓf,m‰^ÇG§¼áüvrï^úîNÖ_
Ê¢Ã¨EÚàÓ
¢ÿk~=:^q£Ëªá ë%ŞEÖH*oÒ¢ÌÌzéÌòaÈ/róÅĞ¤6æ‘+(x”†uYá#™×Úb†¼m†/y˜ÁÆ¬[)ïı<×ş™}nz?=tä¼Ã˜è¯ı\¬jeLìyI›Hİ'¿uÀ°®¹ğâßéY$¸ÏĞÏçN;9ê¾Xì;"d[S¾¯p6/“†’(jTúH„z0MOZL&m*4HØ}**n»zÈjnjõÇ- &ôCë®,L×=éŸ•<†ÒäXŞæjK•ægê„á‰šğÉ­m=0;bU¾rå,˜m-·€“Š>
`>YMã¼¿QÚÜ#]vGs¯Ÿí%ŸC4'Ù¸.Cœ>YŠF·7*¥Mì®Ùhö&ñ„¦Ağùi4R”W+ˆçv¼iÉ×%¼÷­èËÔ>ÿi¤D4¬õó/Ò²Õ¥›O,	æ›³ñÀ2í#«\ŞaM?°ºÅH»A-‡då|Ì’H*b!MîSèù’›ååÃ€³7†1ê¥@_SjsÊhrnšW¡æ0İ;b<>Pí¿™4ÛQ¦³tí¡åÂ©áB}šÔIz~‰º’W±ÑéÃÜ§›E¢Å`>Ä®ulÕõ²`J}©—B`A?L‘ßP5ÏÄ'Œ`ptËGÂa‚]Ğ\®ÿ›½e)ÛycBNƒL[*[÷rR Ü´#¥®İ$wpKy’®ÒrSÂÕî,°Buäîí/óº*YwêøÔ–¨ò`ƒDStŸĞû¢Y3Nø,â®KÔ©W×Fú¿PĞ,)gº€PøJÿªÀè!öbCµc+ÇJ©†Ti€²~:Öà_Ÿ‰Ì™_gí†2!¯Ó4°…îÊŠ=–õÅ–’G@²­2zï±ÔSD‚)ŒvŞÁjg`ô!æ	zpÕ1ññù7?ÿ f«Üe’	PãšØvˆ9ô*@}QB½>‰zùÈÃR‰t>ïî‹ñ¿ÆII@«
úo½é9å>éü“0m:dİ8»•2SÌ·×ÙÇ0,yÆ`0Ïí‘v
¥FÕ»bŞ aI<‘(ì”ÊÄHT¶B´ºÅa1²:z™” ƒA¡b7¦ù{’%wõmMò…Däm„Ÿ…P¾¸¤õ?ß2É2,•£Û5ï0Ê`{Ô‰|ç‘N¦î›V±Ú(½¥Ë<G ob5Ù!=…0øe²›J¸KlŞqL¾p¥9—N^Ù3klö:K0•?¹ò¹imH”^vY}L‘z­‡gdxÇº^zeŸşÙ² ÁÏë­Ô¡üTct^ 7_s–?®l%öSÌ`áO—æ \®¾Ù–'ÅSsÔñmi¯—í<mò†™vèn,óµÄ—F°*Uo¼\8iC™ÒßJôÓMşÜq1FJ_Q)XC¾²ŸGOûê¡jâ~ÏÚÁÜ^á÷„oi7›RÚ’²«9î°±@àÂƒ5³ú‘,åİh D«´Šxâ'ë¸fŞy[ÿôg"ÌìïÂØbH¨/¼*ÿXds„I÷Ã3D!„Gî0ÑšQçÄ§±ƒ£çç´ós=îVl0-9·êÌìêñùr3˜İ"êb¹Æe‚ûİZ\f¾& cªwÇì”²Ÿes:?÷¡DXúüË9€ò”&£,ë¬…KR’ÃDı­»xDëîïP¡âÙl˜H+·zQÜÀE;Nì8&³Ÿ]’Ş­ r²Ò b8M§ «ƒõ”kË"€ßÃŠÈXß8ÆÓcß¾èW6héÏfÍW]%û5%e?¢´0KÇRÎ½â "¡?×”€Ï¼¸ 9C/ÁÊS(=gÄ”–\\Zœó*˜¡V|q±Î[öÇJ„%µãĞ[`:Á˜V¦jĞnft\ƒV/,'ô4qºyıB¼ÈÖ|èËz‚SÃ8_4?™*|³„ëcö‡ g {xåÌ.}WÎ!%ú¿ŠLÒVá‰„ÌøÉ%ñh¦#EvŒ¹ÙŠ˜2 âo vÔÄ5ùAÅÆ!
N–¢#¹ìùtª`õŞOÉÖe…7¸B–¤Û×q^Ú¾M74ş—ÙÉD9@úMïËîøs$»3±Ü?u‚D32™<J0W²ÜÁpãóhd%Gg¹?w9êG”¯õ‡ã Ï´\sec8Î‰<9b‰2–oéì&:«£¡àØ¦ÿ¬}¾Ì+%äHI~]ıp‹9ÈÚÕMm‡sfH$š~e0dÎŠ*YS#ÚÁIIPJV~Š³tä{7Šš¤É¸Ê‘£NÂ„S}²ÑH«#Õ5e| šys±¬%wŞ}œÍ£!Rzğ¥ŸŸ8İYïôiİë¸mâ“ñç—¶˜¦œ½lè2à­"éP(Ñ±ho%ÁiØõ¢úKºh?ğ¨¢`õl"VØ	çéAÅïqnXŸ/uÆ¾Ìug™=°ä^N„kÙˆğˆU4»¬ä–å‚¢Õâ?QgÙ|ò&÷å­F@è»)ã_RnÓŞkÈµç46·øN“Å£Úåp¿÷V÷ØÍÃÔø ‰[Ì›¸ã_ó°Jxz›fvN8°NâI!b „²+|º=
±ƒâñå:û`ÄJ3©Óg1¹ ©ï4Ô¼Ò¥	K/Ğ„¶=:sıKI™MŞZ|´õ=ÿou¡]Påg LÎ`ià#nZÁ£Pf¨íb6|Ø~zíµ¤ÆÖ¡&çï#	s|Vø<2>Ÿ}`¢ºxU¶¯õk{{~1¿‹Îtb|uì¦~f~WÓx4%*1\8eÔ:!Ey™––y”=€ÓÕÇÿró<½ôÜ:_Ù.Ìáp_®¯Åã´¿äï¡yKÚÅÖG•!ç¥¼Eßˆ]^M–ƒJÖãÊí^¾ÚEå=±_Fbóîyf@·+(u\ŒŠx‹8½R.Ì¬h€7 ‚k‡Óiõ­I“şîİü¹S4­ÅÆpuñœgX4pô4ô¾…™…E¨–HÆÑñÅä~õ²‚¤£—fpuDŸ¤¶¨mHÌO™“ )PDCl1àÕdÒÕLe jwçÚpç¯kğh][ğ¡õÖğ6dQÂ]·êAn‘	İ%õğ zŸ7Z¹Ø˜ºÃO!Ùæ’Î{î†¸|óÓc¼ò„3åIªÔ÷…@íıÅ»Œ	Û~øÉ¦bÔ´ïûs J¿O'N“ı6»®€’õ.·ëµ°•¸®°šUvBCP7‰Ş	}¾3%‹=C»œBª £zzéz®LÖÄİRK¶X°J^OÙ½^¦‘n/Y£Z¾ş48nÇØ¥âX4öÅÖÂÑâ÷Qá¿Ä?Ü‚WÇÃ›D¼šŠéÒ0¯(qéjÿ°.“Ò"&Õˆã¬lõ$åP¦ˆJÆÜæ>jí—µãütáÇ†V‚îC:ƒØ,Kr9šÓ@íİúµ»¯jfo7wùí»…Ø	¢Ùá•°oŞ½k”@-|©ÚÖê iÉ#PÓÉ[„0ºmÆÉ¿ãW­Tj™]efqûEùĞ®™ÌVP-¸ºñº­‰yˆ~ë#„äÚšm@û¯šŠá˜“'5ØŠû)Wu†³&í¢eòd6b¾öºV ..Y‚¡GŒóe,9¢ÀM_GØ)µŒRİ²kDªÇÇ/Z¹Æa3S$Ùkv”¥2®ĞûX mo•Äu·İ2¿²ŒèØòaù zL¢•ï£6vÙaïÕÑ.RşÙõ£á
Q)b1I¿ºC› ?¯– ÍæÕ®ÇgÏv§¬š]¤ì>Ê¾ÖÌÈyêŸ†Wjöïh™öŒs½ü÷ÚHEÖL*ï®)m÷è\%–8‹öÒËáFÇQƒà‡fgI||úd¯U)6wî›Tÿv¤‚ ¾K­Ş©X^À ˜–?0¢òvyEÁîHì¢ÏÉİŞU=½òBUèâÔRÄl‹“(­üŞÿ*†ØpX”:|ØÄ9ÿ{›’‰á- Vß$m<¾¦µ>(¶ğùŒßX•Ç™¦³È]˜‰v§îßOaæÀ	²ÚI³ °„væSöØ`V=.s9¢×Œ¦ÀT¤¼Ö/vLHõ´›İ"ºì]cñÆ¼‡‘¢Ã İ[¥3±veÌç}†$Ä{åVãÈaè¼ÿ6Ò"œâõw|ítå-Š{”{3	G%PhøIxfÃ=_¬`xÑMtÇp–¥®ôÏØ'×aşjìq9à¢P³¸ß!KB±›oÅš#)Q•cQ<$«[êªD¸°t¸¼MCİ[¹CÑnb?‡DÇ%[3ş¶Ü|_Í,S¼ûçE“àFñ¨I·ì%é}Ì´ºå¡ÏW'WÁI+.½—‘qĞ•^d"üdÁOvf“ÏÏx¥»t^<Kˆu6¶„ıŞîJ‡Y:ì·%1ÇÆ
g´M’àÌk£ß7“ ã¯x±ÆXiØ&…–ß?("¨¯ İSóä*–6ih_BÆıvø±9òŞV@›€µ7›Ûó½ •Xº1:¬´	¶œmÀ_-*sè^òŸ]Á“È`Ö§ îåÕÓt~E˜ãi«¹V8N‹~6cóS·Ã“öï^˜/¼åäY€ØE'G€2äÒ´?z;C¸.¶BT’hâÕÆÿ©Ë\0kdêìëg0§qšİ$øÜwâ>ğbÊ•.OŒô›ñ©L’2¡6L£ ”j2Ôêäô©“X¥-+4}÷ŠF`!2e¿RÊ²n;™alëÔÉL!8V‡¼™1¢6ıa‰}÷Ò2©eû«7Ÿ¶‡Ùµ§·q­İ…B•ê@Pù2æ)j]î#´Oàz{ÙŸX±ÆµuÆ1´t„­Ûrí×¬é¡%%äÙ5ZœA’KŒÅKÈ	N T:0dŠ&õ[© ˆH«N«mÎöìxÑ^™áFç»$.ºßd­°\gkKL/’Z°ÁU,r³èº?û¿XGdYúEoBÜmäôx8ïo0÷¥e®åûÊ®ƒ?¦·â€àÈ»#y·¹ªDHa]ÔšCÿ.ÒæeıŠ]OöR#ÈÀ-¶&@!“ìhØa ùÀ	Òø¹˜zÊùƒ<ieˆØ“G–— ±°éC5“|J=2ŞEÎõ¢åÒP§±6Ë¾a’ÉÙ»Á)–e†H–Şhäâ\€z9± X6Æ­‡:·}¦SĞõL|¸…„¯÷ÿÒ¤3¿«8{Ö™Ú[2p‰º"ŒªôCü	mO°š}ÄBã«4nê²r&~¨‰zÚº©ı‚; ¤æ=ê‚è5ûh|¡`h¨%¾[<ãéÑˆ &«œ·áåI1bå#ş”œhˆ€w@ lM²Ó":İ#¨Ö“Ó8"vãï2„Å¥°é=ú½—ÙêÙšƒôa8Ät®Â,)îè}¨O‚‰¶BÙVv`¡8¦›É2EÉ=¹)"æu½ÁÕğ¬t4›ÁˆËj…Ğ5mÖ	pk³ô]òjÍ)IlFó‹> “d€åUUgä–»Kº{ğ€L@3o=*àjf–¢(©À˜µ‡›­+B*]™¸N˜—ïÃh¶‘á5xG;÷q•v˜%ç\ã,]ï9Í”›¼=ÃÕorİÅŒA­*GĞ^~u·Ló`CŞş¨ÕEœU§ØyDj®?¯‡ÎZÔŒıûĞÍ¬¿¾ú†¾‡ğ¶ÉßN¸>,ªWö™÷±5"ĞFÈ›ÜÄzæö‚s(Êü‚ÚŠŞãÙ!¡íîÉiúêë—i%w«ãİNÄZ×% cuê€	4 zäÊƒµ&¬ÓË«TUğ—¤áQ>ÔõRµE©¡l|Êáì|íP­Ã%şû?5¥°å™ß§¤Ú<ñËYˆ9å0àå÷¶¹š2¼õrv´Å7½Cµ×Ûà2© “
îÇ@Z4+,5~xZÀË¨é«â#°Šm Pz¦N&/²*9EÍh@Ç¿ØÀâïíÍ©u\•£¾¥•862PÕ|B3=Ô´H}'‰i5 Œ ĞĞíæ•iiq–Ø'’	t´æ°£¨¶>=Üï±IC\0ÔŠÊßøö³cÅöÇÎˆh?ÕÅ‹;ÓoÄØ‘f%Ñk@;ÕvœÍ'úDÎ–‹9[2óäãU;ŞñxüÈdÅš‰•a]X¢µ5üÜŒ|²n>h·•wµìz¬g}ûµù^y>”sOSÀĞ™;ˆÅIZZß‰8–\¶ÅìĞ ù…‚0Œ½ÂôÆ’%&
)Cgü½Bçê[“i ÏVYÌàrKÏŞ‚”ó×éc•Fæ9¢r¥VŒH
?²™«X•Mu´>¥×ŞäºÈÁtzwdª|]e@µ$ûxëŸ Û•."h¼˜¡
7àÉQú½3úxplp=:şçîÆ«gw$]	e
“¼©Íı
ë•ÃÄv‹ÚT)‘.‰uj‡¦®ÁI×'ş½ñŠ©Pn½‰#âC\ ©Š,ö|àİêsY©CÙ
Ö]?Ë“:û¶°°{ú¨ÎŞô¬>
&Du0œ<ª¾{ ùà?·Ô§‰Áf
EçØš¼{+<.*YE/‡ÍEÊ³±¼î}¦ahpÄºã‡o,0ZUB-÷ü˜1–Ö¾c­huW;ŠrĞ‡ûmg‡xN:~Í÷Úµ¦è«8ã1Ü%» æ;İTò´fï³ÌçsAr†Ò€Ş¦m/üË¼ìÍ¼"Óa"ÊİIåK¹¦B2b‰‚7bz|XÏ’›Ò‚Q}>]vó™úêÉ(#|xùšvöú?•ÑÕ‚{ıA±ãºQË{ÈÛ{È®ÏDıõ´RTÚGáÊÌ‘ÄŒD,îa“”ƒcc3ğ'ô«"ˆ!™oíïCt]¿nÅ:'Fç:‡‹ƒÀ?›fş[u-£ˆ²«^Ó³t¢cşCø¦Q)ZDÌ¡Ÿ6‹ÛßyÄ)2åsu$!¶ğ­¸Û•öÑ­¥¦ÔwÏBãŠ]ëÓàH"@kçB$eË}}Î•Ó¦¹³Ãd£.8ÏRSµ×Aÿğ>|î!cüÊq"–×7™“ºùXhÎi×½&ÙcGC+”?44N2ZŸ·£_‰G"%t*tªÀªnÍ|k¢Zß"Lù"êt¤Í¿Pkb6”÷ñÏ´P"ML-ª«Q¸ªÿ'DİIF@D”6ãÙÈÎùztkÛÿz—q²‰;Ná…4{@Ã¸v‚h¼hs!ˆÕüu‹ú.ûz%ößJÛ c5çÀ¸á^ôãÔ¾¶¦aâÄM!·( ÚÔ“Z}®²Œæ^–YÁ&ê–³pâ@ÛñÚƒ¬Qˆ şú€Ñ!’jrîÔ
½—«KbF¯í,°W,a‹à¥°$dÆ£”·eÛÍ†5KÃ¯­¾8Ë6DÁ s¿™… #ÊúØÒBÊz&d&\4]Ä‰ôG"8Úô˜ÚµöÖD;!Aà,OW»P*ç'eÎé7¯:âƒ(…ÈÅ9;éÛ,öêR7¹Ùš”
Õ#%ï"7#FMäËÆÀÙŠ&­K{>cq×‘$uf·KcwöXˆñ„÷ëBŸ)´Ğìo‘}›@T@ €yùÉÙ<1+A%ûo‘–[š½qq½Qm¡ÌÎ›gf¡%Á‰i ¿ÍÁ’Ş‘-KKxøÊçÑr¡¼ŸÓ—€ÔTË®nĞ6vØH\A‚%JßvË"À7%ƒàØF–f0xÂ`ÏN7VWÍÿa
QW!Œb­·ójy¦.í»şMJÁêÔŞâ¯R2?+.dº‘6p)ÚF_6d™'|¶®•Á8Ğ¡3òb Ñln¾(-ıù^•\ß
#Éèšİv6m)ôí=“}:Yf?ù‡_WàUr½{Fo
jS8°“cö 8Ğ…‡vW¼ò ƒ[Éé\Ãâº¥¤é}½JlPV€ÿå1ŒW÷›Hºß9Õ´¦ÜÅÜ,[{Ø7
¥—¬†Ã³ş‚?ÊÎß54OËQõˆËò¾1{l‚"¿ÓAveÀ¤‘x5Pî{$ŸrAş ¸Æ˜@­è¸ÂÅÈ}<^Z÷Î~ó»†@Ë\høc[~âåÂŠ´ĞÚ$j	ûŠ?à“8Ï=Õ%Ùq<5]ÕpWãÛÜQ.ËåJ—Ú¢'{Sb9¿O¥”õ {B7ó%½İº#‹ÍÔÊJ_ÁFşvå¿*Æ¦	¦•¼ÕJçNw'’M–,;y6-íßœÿå†oş‹ã¼lİ&6‰Yd[ƒØ1¢{!œÊOØà£g¶%?Š9…|zˆ#Ä¾9Ğ†×æmhbÿòâË`¿èsi¥N.ª"3ƒ¤
Zkj±}%ëÂõ¼¬‡H†â6ÌNÖß†?“H‡ıleÅ}yÊÌkh×\õ MĞı{>Ìˆ]­²sÑ‡·š!Ğ–AıÁÒ	.>gª†N<3|eÄÛ¸0œ©»UÒ¦±Ì&ˆe5iR=-ºéWó¼VßyS[®fâÙá¤ âóo³L¼Pÿ™™€Xà™!ÿœöŠFkxnLM:<ëcĞ/Àn\0bFŒR³ÍİœD‡I)È±3¾à=­Y€¡FW"¬@Ö§Lÿ`Ô•—GØ½®±Â>,;.¥è©ç½‡LìÔş¼j¥¤İÄ<Â¤¨7O¸¢§¾‰©Ns‚4JD}äÇD§pTk§cfÎ¼i¿Ãb‘–á|ƒ†Ñc3İåôÔaêd'"*%^­ÉI…M1!§şÓ«¢hñş>æş°pÒ"woøgwºa“(Ê<IR™4Í%d2§	TQ¸¸VŠ_™—™õ‡ÍÂ|#¹g+ï~HG9“çÒ8Ù]øçô›ÏÁa¥?Ñ=•ÆQiRÛèÃVñçÅÆZ±e/G	—/Oíu7ƒ°4˜š$—ua+¾km‡¿©_fĞÓŠå˜uÅ TßótÄÓ˜öÓå|Ñ]à~ª9ChÀñ©yê–wş¾ê‰ú½Ìœñ
w;oı?ğÖG»w•¤–‡yŞ¥ÑµîÁpŒ™	HÃÄ‹T&C­>­Ï«G¬¡ö$±lfVS§hñıá{é¯±EmDê\I`öFMÍ·ŞRPe‰›àçb$Õ(ÍxÜ¦!Œ0÷^ÛØ3{b•RÓå±ïÇ–Ãù×[!°ùOğ]ŠNvnÌã½¶Íû)8N"Ç}ëcx½ÃÁˆì]Ûiè¾`6Pœ!å'ïÂ[ìÖ4bÎe,8íÍ#ˆ†5X!˜¯<QÛe:@UT÷Zµ½p[t[.u…H¤l}Ó‘ëÙw5†¶ûxƒ&—¤ìÄQk•çrè•¬@CéĞì
&û›ºaB…=d·³µ…Ü”_šk¸ÌìÿúÆ™¥G›9Ü@ üäõhnï…Bãï'{eˆ±æŞğwú±HvàÆñE–‚dòÁ>îÄN,€!İÿRMÂ!ºŞÌ®²Zÿ5Öæ~¨i¯§;´µ9ı»Éj²İÂP˜Õ²Â ´ç¯JdT)‚|bÉ?Ş÷W—Ûİ,šFi6bE‡ËS±èõz	ú’›‘R·s¶ˆj}í0jòéğ|wí^·­ylk·NÂA73E_Êø®v'S¶Ü©„ÏˆúÚzèÖ^Ç$NŠª~´›~€“C!…=™‹uÙŸ¥ônPº%hÍã¥¨[ÆÑÅ“Ê‚ ¨jãßAw™ù2ßZD%.S}	ë
g<v'$–Êÿ—Â'­*({åä0´Súj¥N}Á<ü0VaS×§pşŠg­ÖKº'Ól!F‘YHì/<H’yå´õ¢v£Ó$)¿¬zº%’#Å›“õåE´œæÄ'· èç/ùÀÃ'Œ4®ºä;˜s.½škæï…,ÓSb+$#İ‰v^k`dB)Ò+ù;üì&ç€-RÕWÓG©6”$Xù;‘š|­H£›’ÒAjDä«Y`íuV	VZV—’ş¾™¯¡mz0×ã¦eHbÿz…şDÚ«ßğAû¦å9YŸú6‚	kì|å5i¶ÙÃ˜ÁÙß‘,ÿ¦Õˆh.Øí6	’Éíäµ~…%¬›ËÔ„Ml>ÆI¿äaóçÚ&¬,!ö:p24
Òı#^]i'm6&¯„‡U›A	‚›Ø°¶Ì‹lÃ·,–|T.§bCüÑœ\tİo¥­³1ù’_%Üå£Ù2"M“¢vş_?/ÄHï€ï§ò.fÃi/eÍwşÂk\`ÜûÌr…‘ûNµşk8ÀÜğ†z÷8%µT%pËŒŠ¨´È-í *ÛÁ½Ü¤3µ:h¸†èåtoYùSHÆ–_)ZX¡ú(Âfu:IF_HÇ–Ì¯eC60m ¯B×{g‘ßS¯İÊóÕ#ïéîbÚoMNy90Ÿ72á!	Ôú˜cÛ.äSKÂàõuP'0­óTé"™`+rÏš±OĞ%ãˆ®š¹‡W$}Úd>àŒi¯TDÏ€¯g¸èÁO–aR°z/EÓóxËQ·ßçNT¯ŞWJûÛ˜Âœà(™rÙ·Ò¸wúXÉ0s®C #¶ı¹yçàÒ6İ0È‰™ÌÜîäB”ÎLYÏr,%hbÆşt50ÂjH¹aß	~•{Œ&´…V’µD
r;3œ{O#„N‘ô`º*¹….áf“HûÌK3_÷j0ƒ |—:‰¿Ü2ö5BmXuzİ™ı3O@ì¯ñõVÊ²Œl gs†`7«x7UÃ°¼Ø¨‹¹ä £id3	›ËB±YÇÍ³’©±œÁ5v£sáû¢qrkLÁŒş‰&nš‘Şîz7¢¥XEhùÌÅ#Àe#~Ø€!ïY¯£—Iâgª˜ó~.Ù(d™[$çk8Şl3è¯:‚–Ş%¥Z¸èc^;Ö~)Ç"’V¡\PO:@Ö#®®}´w­‡~aëWp	ftœU3±XtA‚W„±QM2gÂ‘+œL~Nu<V<;Xí àW~”êd¿¦€©>×ˆş))3kX/x~tÔ•-†Ó&ÏÆ¸L«Î·¿nÍÆ¬°İ‚«Í›%ÆcÄx¡}´ª²Ic”KB"èêD%Q‘“"Ã›9õ¦Gô”ñÇ Á¦#ĞÏïK28ç#Œ|2k+¤Õ‡Œ•/Ûf?Œ£ä%ó| ˜YpèQşæÀãHÓéÔ‘ø‰o$¹Š<!Ù].h=¥“Ÿ–±C“[´ç^ñ”Ñ;ÑÍ$I%ÆŒê±ôÏePP¬ò¦ÇU5$ÿ”8û9W±ã,°«½êã[%õxşğ¦é¥Û7ûøs+ÂJâóæÿ´›p¬á¨ÿ¼ø—ûıpÍeé¼ÙËÁÉÿ‚u ÛGHÅ©c’\hû´áT•'ÉÅİ¶ y	_u5ñıçßíŠÇğ‡ê±-áÀ)+onG7ÑÅªÀJÔBšŸ{,³2¿V‰§)$²0lÛ÷£‰*nwò¾Ãqó=I¥í¿Ó…]…°÷ªa[Ñq2ì´53
×‹ q.HFtÖu¡5-q§nÏ¹¯3ÅøÇÓÉ{u§]L°3˜õéHBÆ÷v´ùb9Å!G0ÃB:g‡y‡UˆúJAõzF)‘J÷Xu{ÁW°SÚ¨ØÖÖùyj*ı±eJAæ·Ä	ê·Ù±dr=ÁI€‹kíÿ÷šBX=lÀÓ¹ÕÆâvR$İ'ØÜŞ•vÃE|R+yYK‚Øõ/ãjó¶HÛ"‘ÁY£".Xóµü:Ğ’¢
Å‘eëĞÜ6ºRsña¬fñJÚ¦(kŠàåÆû#3ŒºÂê3o!˜ŞúD„/‰ T²	!zQâtÀÏ5÷ó¿ü„œ„ûK:ÁÖ<¼dQÁß‰QwÃ5w2ÈÍ`×šéë¯ôq‡ã:ì‚ÉÀ”µŸƒ:¯<ì¢äSq§ømºM‘¿8JCçD\)Œ¹˜Š)àÒbì	Zµ±XDV^…Ì§­aG
¤/¨È9ÒU¹2ŠÒpff©R=É­GæÏíN®Õğ—ÚrX1³‰ñ+…ƒp€×’, …ˆ®$Û&Ÿ8æ5àhİ*{=Ót8ú×6ˆ©ÑQN÷7kÛÁrkÂzócHÁÒ§°%P”?ÚÙÊJİ&F.ŞKÊŒ/¿İ¿©¾±GyäQÂèB’˜:ÈJìMkbSÇYoÌ7ÅÍuç`-’LXÆ¢ñô­ÉähsèN>îŞã§4 ÿ§ f;™ÏÒ¡Í«aÔı¶ó.®†İ¸?ñx[C—õÊ?MÊñQaÀy†ØÂÿdd9ıİÈjÂï‡›3sRì!ÉôLüÑ¸P0Lñ²ïşMxÿşJ?kùäá­qbİL—bŠ“şoô*®^éq¶ÛĞêQÀM,é¢Ñª®v>kÜìqsŒ¢æ!<wıc;Á
5{¥kÁ~ÊKuš¦Æ—™had!'h
0EµñGÏL,¬Œ†/ ø!
à¦Ú¤«ÆWãG{£«´ %2[P{†‚Îƒ*9‚é_fu‰ nÏÚsëÛ«WÈMÈ7vÿÿ{ÏT`ªo¯Ëb’^£ã®ìıÄ–”Å¸¼<ËòÅ2#NËš	 ı0h0äŸ48éŞ4ŠôOé]ÍIĞZ+îIƒÔÊ¢ÑuµÀ+c~kDı}(íC-÷ûç~‰F[YOõg®¶QUÎ‹Æ¸À,Á#w³ú}N¢}ÅÛüJÉë&¥qm¡_š®>¨L˜ÈÏPo’YbÉûw­Eóq_"6xG"ó}l .H&0ûº~‘[nB…O›æ|éî)1¸ƒ=ôêIF¤¤Í®¶],M±~¸SYÒ¢£f^ûp$ïjM‹èxTy}çØ,=µrÕµÑàY¢äbƒP4b¢ì·/>é ÜØÃN;s<ú®˜TA-`Ä|[—…Ág^>^rwß>?c!ãk‡M³ó›¾Ì­Œ¶€°@ò×¢±™Pˆ*9®{ZŞ}¼Ì
 ½íÈ”f–e—‰A¢,ÌÀw>’!¾©F]‘03|Y[qĞğd£D•‘Ü¼4`i¡”÷œGºyR¼Ú¦êGåÈÓ•d®7G¸~ki.M)s‘¹ûs¦+	®6<«;··¸P+ 7ÒKÍÔy„Ø{åÄa£0”iqêºíx=J<ğè˜z­¯jÄ¡zP9nÒÅ=›9¶Ú·Æ¡[÷¨´æß o«’ÛHh½Á§ËÅR°b¡¤Q™fsiæ¦nkœ3´¨	GÎõÕQ,­ËK1L­x‡©Ñ¢º™R|Dm5jsO(Ó:PÄ¾õ£¹ÏE“İ7G,HGáäáš¯ú‹Œ°Ä*aCdvùÅc’êÑt¬rQáwµL?íe¥
‡åg4ñ“*"ÍÜ|18pï¥ÕÚğ	`•¡5{˜?\šËoÄ«Xº"Ñ¢Ë]Ìö¦Y>VeÂàó¼’®ä\í>¥å‹ÊòÄ°ÙµÁÕ»"/%WÇOŒ:àN(L_‘5Â‹Üj ˜/X132¾ñÆ½aE°wüœÈÙ1›VX ¾cŠ Oç7•âZ ª ÃØÈ¶Ê`=²¨I1¬bl³Cé\ÊÉM—Wjh.ĞRF¼¿fà±d‚ìO"Ö·~th(Ÿj4{îÌf¬F&’t*bl\<3ShÉ zö	Nä—¥È¥ùOÌ¹O#àŸ‘¯âh."o®€£ä3"£.êË}÷‰eƒ(aßp”‘@t…¢YölœísúŸôk™¾Vrh2ı¶­çÚ—ŠA®ĞÔÉù{¥’„i”·
àíŸ:ÌA48KĞ’gÜÖúô¬˜³Op‚|•Wgq÷õ^£ş”uéyÈÌ©Ä.˜Fê,£cûqiÀ÷÷‡|l2Qq‰ÙEİ gªdĞëÒòZÙ%"››E§ÊJ–½ßhõXÃáş¨S2ÿ>Ä
|d}åÁ„6ùyL,„Ôy®×Up4#Íÿ[“VR­–¤SD[bƒs.„L£àyYv6
‚çLEü<`½WM C¹7
<ÚË÷d8®_‡‹*ÿ‰YYÖİkwã;¦n~'H¢¥p¶ÜDê=œò3¼Ó–gï†RÌAÁºj=ÿ¥òG×N=õ!‚7ÕY.êŞJuÕ¸ñË½|7Ín7ÚÔ%5<UáĞp~ğÓ#ÎP)’j¥N¹OÄ÷ÓÈ%êF@Ä9İ<P
|Önª4ä-±Lc×sz<Æ“Æ9Ñú¥\õ(Í0ı÷Q$õ‡ŸiÏ+h¦®5]Ü˜Ò€±‹V€ˆcFN´Zõ}·jÏ@v§@ÍZºxØù—äıÅÛ†n7aA„Çï=’÷‹ËÍğ|µLÊ¿	mÌ‹È\|ÒkBÁ'ğ±­oIÍü–Ë½ŸÙ™ÜPÑxZ¬ŠRÆËŸ«ŒêXj6±wœ÷Õäf‹SøÆí]YnŸÁI$¼kşş&'¹ixhû€b×á
-®¶$¶™/²J·!¯Şº€ÖÇÒëTT7ª¿
ûYZ›?^Ë˜Rš\x£6m0Œ*_:\¶;µE}‹;/9sİb½g½ÒüìÔÌàW¸†…×ıÇFç…Ö¤y¥JÑ'³k­h2Hù«7˜«Îˆ™®„™‰‘@twŒ Ù™"^éÅvDKÛÒ¶+Ş«]B#l,i¡ò/œ-U½œ¡<ıe?Ã_ù²x”>šÄŠÚ+=XlÏd¬×¨jÖu Ò¢1¾ä’Cÿ;'U›û#½©­Õ‘ªÜnÕiï|ğŞŠs˜6ĞÈ0¥+XÇ)õÄNO˜©ÊÅƒ@xuuV%†ÊíÌBlËƒJ6ÙÔ$¦’ Şÿë‚Óy‚:Â«õÇ§£>““úp£BSrcOÒ¹wšïîl:0q_ZçÔw±Tl"¤øÃ÷·’g9mİ6XKÛª±ÉWP¥\·È]?bÜù/–9+ÛhÔ¿=“e$&T¢ÚÓ@œ÷ãÁÇëq-³
4Ë©KP=ş9ms?ƒKyà?
7suóºHrì>ß8Û$õä…İÿµöËç³U=.Š¿_s l'”ºÎûÁu'Şs»FZ&ElÄ·”"jğÆ
±2ø¿ïêEjícù¿
õ‘EEÓ«Q.šB˜3hµ<$1²ßZœäZ"ç÷™NcàÌ.ü{6ƒDA[cºmÍğ½ç\œ1Ïxc)ñ÷Ö®sÈ?ÊÆˆ7lLÒQ„R7P¥€‰PX"È^ö#¯°öÎg+ ;&^æ5ûu¢Ø	Eúegá(9ë<à+b=µ?Vâà¯‹º)\¶Şñ£÷$zè6Jx_µ
æ˜­“ú"oåW¤¨PÅÔ½,¥	ç’Ûq‡w‰%àèbSíÀiyßı#Káñ·±»—œÕÍ<&şeµØÎ=ƒ2Á†ø8»ì#Â®˜@y*¨0)œ<NøÃlÕÔ¼ò™†ÇüE(à/Õ‚y5æo¬ñcılYèˆx&}òa¹ƒ]åKãùÁ€@0à×tÓHâY€šw‘?E}èê+mÃ,#r˜OpÏlo/Û@‰t¡Ûõ¹¡Ğ½LOf¡\&…ü	†0åX°,ív@LÆ É(².¶oœ:•$›Ş›(PØ
0»Ú·ºA¼cÍíÆy™h>©“Au±0ˆ
â¸3œˆV%›³I9“zYq{ã=Ñ§
UĞˆ(¥JO1ßïßN[Ø¼_–bLn«ŸîÉ«@9FeıCQğ~Ú˜Şã{L¿œ>âhéèû¿Î®¨1mÃ´ƒÎh´v‹¤0Òc­İèrë[£:ØoOz9HaÁú)ü[ÿ"ZÇx[óy¡Éb›“3Æ;ƒ~:?ÌƒÿÇ6ŒÙÍF&YàŸ"¦5#à§PQ2Ş¼­î>ŞS°¼îW_fm aâ|  ï«e2p°û`äğà³ÆV­˜ÔÃ†GjûÂ^wğ@‰ È ´8>#.¾»Ÿ«aü j~;¾Ğèîa|±VşÀ¦ º|h`£Š±d¾–Ë<XÂSû‡Ö[)€8œ°å’ƒPY(¸2f«ìİ–şñŒòæ|÷çp(d”ïñ ïÜŸıa
Ê Úi‹g2 XQÜåø©4zQ…9î­_LÖ)£Ş¸¸ı´Íß¨ñÁ"™6Ê2(³(‘cS×kV«emùNæÒ“I/æş!k†ş­ñ<L\O’Õìs”?EdqødbˆÈ,BšcA™<`áµ}—|1v¹«""‹ÉÈÑë‚¤N±ÙÆéóáUÎ~k¥®/±ô7]#EŠĞQ}İgô„Ÿ#èEHzZtÄ/°R<hØ_P¢N•‹ª–.¸i±^…œğ;uò‚Bdâø!ÚTX;·ÌXş”®ÕPÇücTCW*G+a’ÑY&4-Wf:m³s·HŠ‹µª„N,-h¼6äÅ¶œ¬¥êè£Æ2·3ÙÄ·§X˜îsí÷ï>€Yw;?¨X”£ûd$jZ®H]ãíAÀñ4}	+Mòƒ¬ië²~º:¥Šp¨÷ÌúyÑNƒ=:NSÅ²û&ªŞ5°axÉ»\¹§(W1Éı‡ïw–ïŸßÎ‘b‹÷ù98dˆL·iB†%}gåoó`s›iÅ³<á‘l»Å¡‡D7Ú´ÖZA?âGüŸş7´Cæ”ïÁëıRåÖ²'Àè“y­µMÿîñ——ò¢0{éj’+/Z^D­Û¥ú\~¿ØWÖáŞ]Ô•EXÁÿ ;«˜hëÕ:„§HbŒ÷ŸnĞœıÛÕÏHÇ¼I…©_Çü<¡!
Wá3ßêz†zÖÔê\Ÿ÷ˆ=3O™Å&É"à°>­W¤±²•d§"xDğ\ÿŞ¹sä‹ È{«\åÆQè¾“Å"0–òí#JÖ¼¼¹–ç%‹„EûJÍê0o¿¢¶¯ß^	°ëÉÅòD…˜ïEİë[–ƒ†u¡àWãÍ]ePHdŸÉvïfb1í6¯'¸ô‘<BÕ«j{å7áMéŸC”Àg¿ô¹Eåğf ğ QîU{¨“EŞ:B0R®ûÉ#…ñn±HChfØªÛÚ'ö†ú0™¦u½jÎ_hCî*Áœôm&šk,µö Ó¹¸¾+ªÚ£UÉ63âå‘¬‹‰ÉÄ(­Ö>B÷:ÆcL™ÄˆíJ,ïiAı×§ğ¶99Ôf¼“ñÀkh8bõí®ÁÀcN±€ÄKFü
àéë¯õæ´_E>Åå”ç®µŞ»ùg¾kPÀÁD·ÎZíûÆo¤Ú´É¼t1{Ğáwy>>ãr†lÛê,š†À‚çµŞA(Æúlk¡K7-ªR1Mxàµ§áPÏ$ÿFH2çocÔv5íÀ$NL‰1{Ş	Q·´<šÑ?>ö…ĞqÔ»[Z×c®4òô{<Àß©1‰Ä*…c|2'ZÌíáÔ*Iğz|™XYú:”±deJİ‰xE]|Á!¼y÷ËÔ*‘ ì8D”¼®ëŞ.¦N* [tQĞ!ÍŞÓá^^’Ãğ õ,“ğÏœc$0?`ç7éŒl±Š:ÊA¡öì¼¸‘ğ•ğ†úd„‰İ¶Dû?\`pÇwV¶LCš$`ğDÎ‰>H]Åáo"$ö£Ù¼GéÛdKé£›ñvK@—£~Fœ'Ë)…ùXÕdsµ¨p‰Êo…’´vLÈU.;V¸êx6ÉÇ&	y´ÒÚ|¿È3ıåÚ)ùíöG‹ó=ú¡ù<6¨Nƒeú«(aUaMÀC`Ùà“Pìtl¼sÅO%™˜­_ŸÅN“¡…¦»â ÎN×A„*«À×.]‹ãB«JB=„Î¢:SÀÚ“©Iúv¢¦„¸ƒßùı£‰ÕT%“aI!Eò*ÈoÄåbŒOòc±=`ÂnÔ)‹»_åš&‡kåj†Õ>­¨%Nğ°³UÍx¤åûûŞ¥ø‹ëŒª ËèÚNï*ÏŞuZ€vª7RF²ê"@šáÙ~+ŞŞwël¼=Ã£¨Û8 nsÿWˆ®j"[ì›`ŸÇÀUüE‹Õé<%ï³ÁÅŸ»X0ÀƒÙHş’°Ö
xm9s‰ÀåŞ6ü;*ï³Dè¡Ê~5W4tôI5Ò¼nº 9mÈ“$ÕÕ Úâ`şûıÜ¬¢fLÇâŞÌ9*·àh3ú Ú~ƒš·“ó$6QS+¥ Öe#(éÛFßCÃo2Ü–ıîæ±òò‰Ã‡µù£4g[ŞÏ^^Á¼¥3IŒ:}µ<Ë!¯ŞöÓ¸–(˜óé3Ù€vg]Qä L¨JÓŸÊ‡D¿u’m]ÃX³*–Ÿ±¯ºxÖ¨>™ŠüNâ,ı€«y8"Ôd, » Ú! 9;ÕD÷¼¯=*Àûä9±w7l_í‘‚ªÿ5«+Û\ø¨†MF‘daìl*WÜ:ÇÓp„":ÚëÊúEçaÇG2ŞsÅ¢á,)nQ«2G_ã£úªwÿÚPßƒudŠJ¾ób†1tÉ÷3ÿm€eáÙı`d-¯Ï][WÈQ±ş¿À¢‰¦BkÈ´'=BC\ 4…Uói [†ˆ>·ÒHÇA›°ŞòŸ¸±éQv¹]@¼m‰W‚84éJ«•F€ÔöF´†WQÁIrÙ!-âéw««pÛ—P†ŠqÇ€[ò :1ÉÈÏyYgôıëùPµùğïtŸéd#z¿	]¿ùñÁâÍ­ü³ø„´3oŞ¾–f5ÊnßCÁB±n/Ú;³…xL¤º~ÜOWiÉÎÇ’)ß®DSß106ë»¾æÊÀÀ â1¿¦¨!–n)`;™	Ñ/—ræÔöäÉ^Gœkµàà4Ee^\F,„©¤aL¥Xƒ¦‹.óß:ÙÖi× “c¼±ÌVÔeığnÓ%şúï¤ìª”~R¥÷/©söÌ(ƒæà(áÖ)qa{ù)ÌÃ^º¢wBŸÈÖOp³Ú\k1€—Œ’€7vEòCOŸ¤-ìòpë†Å>Ÿ‰Şv•7w—]	y.fäÛh!ä²?Å#»^™eŞK_~Z­’»n…¬1’QËĞ²È]ã'ˆü 1ÅaòÅªœ¼ÓÓùœA"ÚÛ6hDxÜíJ¸Á>üOöû‚Û?P$wHIŞ¹ØÔ2í1ğ;cì;íV™î5 ¹—¡(È?óéIÛ<1Q¡¨ñİ²mn,±=DaÏo¸1)H½ƒy’°]'3wg‹x¾ä°‘ìµT¡]ArÀ>ºE²{:{† öBÊó?NE¼æ*0F`åc|A›—³ôúÊôi„^º”QÿÍíÓâÀnÃÏ‡d‰Zò+9!LÑ6çzşHÈ_b×ee<-	V&VAâc€^5º«Í;0İ”htön¯„‹”%T
a†™IşšpXı¥íX’=ÉJU^ÓËvšŠ‡Ô3“Jz¥<,æ9ŠÄåîØ!yN¤Ül@¹&©3Q•W¢V¬Š´-Èuu›»ÓğEfì¡“İOÜşxªÕ8tóP=|Jz”ËªÁ”TNŸ{tPÃ×ĞşµçĞ"
øß&âyú©x0ébà …ûÀHÙæĞ¨”«µL“zl2PxğY\­ç]³ßky—¿¥½ü?õx5]k Òı®­“,¢å+¶É£Š2ßN‰ñ¯rıÜ(NsYÏNCcOa\äø³:7yÁ5½µÜ†V5‰³Öqù`hHR‡—?/İ~`r—©v—8÷Ü«Väá³Ÿ˜h³.¼0˜Éx]˜cÍo¦60È€ êcw~gB`E§Å8³éz‡»IóAXVßÌ¤.–¬ôíŒµ­‹|})“cŞÙÇe‘ñ$À"kÏK°>Kşs†é8“çÓÇÔ²	’(²Êè>’°gA¾vVw
ƒÇF¤êFc…FâÛYÎ—˜h'ÿõç‹Ö=õ0 íqÛíw28ZÅÏ÷¡ği·	±+­Ò,!§CÈàîBôÒGµ¸ÊÕ<o"ÕU¦“„=¸ inj°’ı¤"o€tı«W|ònÂÀãÌk{^v4Âf¤óìlm6Ûÿ™ä&uXCpŞO¸%$÷ZK?æ¸ñ¬šeM.I¶q’äÑö`öê·Óñ+¢î€#oÍñ)„ÎÂw×iÜÍùcËâÎü³¼Ñ	‡‹bcl›ÿDœ¼²XUPº†¿^ã[Ÿ0/ò©ígŸ¼l³áD”‡¸™tûBÛ–JÕqiSÔSéDYDŞÔ´(¹à¹	UdÀ‡b”¶ùGb$->‡[.ˆ‚X¥<ßrá"FÂ³	äêóDŞQã›È#?jáÚ(?ò.¶pCshAj²”Êñã!qGSc!ÑÊüsL2*Tå§:ÉøÉ0uúAwH¡{œ^˜e)|ò ¸×ÎÊEÓ´fà›Õqúª÷¿ L<³ŞUsĞ7ˆÚÈ‰²%dyWyT‹Ã¡ÜùÆÉĞğ¯A&%K×…6şğNí¬i‹>eHf]2ƒZ{0ñ9ïÔ¨Òà„,ÆêÔ¢cµ^¹E8SšÒÑçŸ¬“í¹CVvEbÄu·ñg/ ÍàÉ%°W¶æšÄ«ºß¦*/Õ©rõÕêŞµù±W•@B^£S—šÃˆ•‡`p%RL(¡¸²P "±Vê'ÎëûáZBRºnÓ¦ŞÍ¶Ñ“¯z×FÉ8N‘’ÊÍÑ3ığ/øÀ1]İaT–î•q™*ºÉ½¦`İ‡X]q?yà7ä¦ÍZ `Âã NóõJi„D8ENN£¢UÀo¡ÚÅjÁöu[¾o&Ñ]€k^xGSìh½²Ád¸Œ¤&eL(YÀE/O^‡u¬7b'¢Öç’aÈYÓöc¥’ÄŠt,îözÖ÷?Šæ¢¾yÅ4°XôûhòJĞ²“¶õqCHçà;éA¿Ø/pÒ±¯åVÕ‘ÂÏl¡0¹2¾Ì~ûtÊ@c?»MîruRœ¡ÆÂÎÀVF‚XcÊ½‚¯>eQŞyä¼‘bÄ¶»SŒ{7E<>qr£ØZºÍ×ÑñìfC2\ÍX”ñ©ú‰®¥a»	^63×êxægÕ’v¥µ‰îk?˜ 6ìu¿ûo’ŸÛ1î%nÆRÛßî²_ ÇÒajÏ$‘ËÄ»Ğj‚P.VÜ‹qPºilíã=V88£2ÿø¬T’ÖŠ²üê[Ç²ƒä¸ËElP£¶í£¢•ë=pDíQ@ıD©¢g/°—[Ô¾nq–0¹ ®=¥&¸ÉàŞ¦ À 1Š(áûeN)2ŒOiÍ#kúÕˆu W¤¶ç’ixH¼ÙÒ¤ö—ß«¢.s`×BhxÕ/PBè¦0yšĞ{S›³¿³ˆ˜„iH·GÜ>(Â*°£ÏÍç4ônâ¬¦ÚÒk?ƒõØo¾DB€.‰àˆX¨4j<pÕúoP)ÿ|~;g11°VÀ3îYøIW4WâÎ¼äö“(qoOÔlÂ1ËPºhÕgw­Şì"gCÑÈW„Ú×–¢šâ°ØßQ&øB&Äø7ı J±
µ¼BŞ]±b‡Ú¹„êøñµƒ#ú`X?åJÀ.g(ªY¯9‚|ëÍ^a'5Ú}N8ÍbÈ—=´*%‹ë`,8jÂÌ<Äå•Coûƒïİÿ•€)ñ4íGˆó™:–ò]—™Š¶S€OÌGq®×N|¥Î|w¸™ú…¨ëèX;©Œ¦=×A(øZuJî9 ¯
:Ïô¯9gğ‰`EĞá*ªÙ.|`Ó+!ƒz'ÑŞÄIíS¤»‹ÀC¤#qµº$Še”YIŒ?–†dÒÖäQ
–k2M-]üÖÁğ{¡«p©!©ëÖ Î±¦÷¥„6|º•ø+O)ó<ä?Ê.S½:CÀĞgâ¦ãÜî¾ÚÌ!´BäCop"Ìk$[ÙüˆÚÒhA…ÄBÚ
Ÿy 7{4Ë’¬»be„hp÷²í˜à@>‡:‹ôH{8•ëè“ˆ|5Á”·(!w¾LÑ)0¢ßL"…™kàYBètk4äÈ‰~õ”³‡îñø×ğ&NÕI:¨w@Ié¾BYé×T”„rJJí1{8VÀÑñæ¿SixÉO‚Ş’¬PIRµ²QÔ££G`Pûf­²×_DçÕø÷-3ò7êO=¸f+3sÃá¦r—´¹»#ã0®"ñşOtfp™Ë;{ñİ[W`ÿ]|s=&›‘×ÿş²î<×€Ú-P0:–E[`À¾«“ç‡)6 ²&ÓdÖ
÷ş?d#8Æı].­aeêhO6ãoôò³g+—N;X0 ‰¾í·b®.:áÇUÕí= ‘œb­P´Ô×
P¢¨‘¸š_<üjÑş:»U¯ŞÜ¶éçWnÕ²R¶ŒË¸i·Ë•@ÆàÉ©Úƒ Q<G©Òâ¿ËvÃÇœœ+Ç‡ålò€Lù"s\¡"W¾áL	ìºó]j=À*Ëád7“¦Ì”÷8ÒË'™59OtÃGĞœ{•UËHm¯öŸ®9¸4cjPY#¸gTµ¬}ïÁí^ğR…Á½ˆ5W(ç	l±ÌïnàB9Dò]ë¢†<Ì*Œ[!à+æ#‡‡(O(Xâ¬0¸R›W
İ÷±Àfs
ÊˆÜk|Ó}1tÄ¿–£q{Ù–»Ÿµd†¶ch~q’ÌæI±a&0r–[i¥	FÖ¢ïÊëÎH)?ïã5'ò´Á †×œc&Ê¹%K?”ğ&åò`?¦ÎG:„Ãi{ùZmôMR‚4UóƒáRÃÆdgºL&¡©O$‚Ác0h,„Å!lNÛ×è>W†Sö»vxYµê	o’ÊÉCiÔ8Zp.­p #I+sœ¶"©EÙRúZNzF¼Ó%½øt>s€ëÜô Ïõ(ÿß…O Á»wó“ŒHXã.&µ£¯Òıê‹‚¿“çdkXBï“í}ä2H´7`²3 E~;QH¨’ü¢ÙÁ½ËÖß„7¿-„¾š˜L?µ )Ü41!L3EØmÈã\‡€6Ë”Ï%øñ”€Ÿ¨Qû½Ìù2ëÏÕ,öÆs6 -áÅC”C¾ÿ÷
0¼åÏ½"ğº•4ã™ĞÕ©Ù%X€‡sé”é¨9{ÇeâŒVÅ·´îòPº-ùBuÆM^ îEÇ0~ºK=C€4U‰#†œF¥Bâß¼·ŸIP0'OÍ½|û5ÖQ[IfÅÄ|€½“äåaÇÜ‡ìÏë>u3 Š®<¿Vé@0WvÒÇíº©¥±ÕëW«ıÆs[™¯t=në­sZ5ëã1*ù3r" ğz%ÖQ>ƒad¦¯Â`Í™›X¹Y)FäÖ”,§M÷†*ƒ
x	ÃZGFxy}!’/›UP-‰Ëc”éáÀ9¸¬òçgfRHğhÿCá	j5ßZ~©³ò‡ÚÊ‹¡‹‡çp%y/x ¸º°˜ßª`w±³n@âe¨n¹ç}qPµ6uÂäğWÕ·
z±w‘§ù'?[˜ l^şÒµäS{_7<6Ÿ&¯T¸¦RÛâŞºÔ”k~¥AÿĞL‘ÕÜ¿“ÆLw„ê×	Eg›]ÌFı7*¸Š‹J†¯õ±û€È…D6õ
lI×0¢P?eşİwŒ^la9j9ÆÊë½Å3š±NÔö/ÙÓ´‹SÉN¿F,çB¢YÅ¥c¶XóÏ©Ät\?µONAÈïD:-ç*œI›¬R­Ôª×YÄ”‹÷¾öãú.³ro½8Æ¸4·ĞG”9o
£Á1¤ÅòÆÄıã’…–»ívP53«\?æ–ƒŞïÓELrA}‹˜–òˆ,?=$²hñáÈÜ šİ¨³‚/D±(ó.‡æ© ”ÂAÓÀ‰È=ÃiŒeîY1›~Útşnº<Ê9ÂñT‚‚;¬Nm~WxÆ²ê^5û¸,ÄÎªNt2 <)Œz%%&ô‰ÛØ—ªWêFÁ¸MPŸ¾À/Ï³û³ îšÀB×ëÆ¨Â´ÛİÓPÀdä6wÛ5BåMÓ2EQÿ›¬¯£¾¤±6Bâ>”d"ÊßP-B‘±{íJ¾ÖêkFw’Tßñİì²MUÎ7 tTû²É¸>²”MA. Ó“ÏKÉüô78=!0»L«ëÎ6ŞCğ­ÏI¦~ê`AäË»šDe;LÍG9ºí[ôƒG ª_äáo-)îœ€õZ:Æ„Ù¶7¢]eãÄ’OÄÊ5üÁÃ}º0æÄ»ıÄ¹1¸Û¤ï"(]k•¸1ãa ÔìÈ@¡. Ô¾*¦³+ÅÕ?—)èÖshJvs£¸ƒ*:¾‡\Î!Ùlûıö°ğD'¹7ï¾ÅÜv¶kfLÏZÕí´ş’Q/[GÈ†íœ.tnÖşOZ-èFÃ½ãÚâ€!¤–]µuÎ9ÕÈ‚Ù§U†¡X«p¶Á[ıÿD‡¿ø¡®--—l6ÜC!ƒèæ@¿A„[úŸ;¥49)Ü_ˆ0˜ÉHéÿWQó1&"™óx—0u×Z¢bªø{£ğÙ&ÃŸş{99"bX}ÊBxX#ZöÈW\³Œ”m©Èx†â!şT»º©}™¦rr¯²¤„Øk7TØš&|Bâ›ïKf,}ÌëK,zÕÏ”@«µêXÃ‘ÑŠcşgšÃn ½ğü˜Òñ‚È*û,º³xËC<“64	JC‰ÉŒyIp¿f­PÀ6AZuºbHïA%‡ñ0÷­Œa÷Y£t§[’ä“É©sŠu><s­có¤¸ïÿyULp#ZøŠ	Réø˜´¾w)Fš¹Íƒ“m\0?\¡â°‹¦\w‹Öy¢\õg¾WB§S0½íSÙÔ²<7I\3[3øGß~2Fv³Û·A…PU\J~ˆ·l¢Hÿ;˜úv›mDü ·wmR—KŒVÄvN¢ı¶5—K¨@ a"dØËïdw]úGúAª®Yºyºº+[Şò³tJ"sÙ.·¬Ëj–1ƒsyäŞ‚…xoÚñ{èr•q‘Â1ë©ô7h Ÿ?¶÷ëWÏ~’ÂÀò5TU¦Ä“ĞWò×u‡v‰"şLØîÜÆú\/LÒÊA(nèË€İ„JnğÙ
‡b­üˆ…~£i½ÔiœŠ|0<_…K>6Àx»1ø×LÂS2˜ñûŠà /æ®{¹z`Š4ïddÛ}˜åäëóØPv8C‹…pÙ‹ªæÃ ;g1{XD…½³±z
O½N¨wûı¥Åû=D‚Ø~ìÒÁUC¡>kp›¹ø9¤¿ƒ«†…ıÀåb¹€!qÿ’0œm½"4'¢µ+–€[ )¤æšn6$j±Z‡$¹µSÎ9‹]½÷`óH ¢y'%X¾E¨kyÍ=Êö1ùï¹@ƒc+2ÿ$5[„2Í9·«W@t‹§éQuãÃ±‚JñxÀêd½Ğã¤t$ø¹r[+ß*šwÑ\Ò˜ÄÚöa1Qˆ=ît3:˜ïÏ`|£øñéq²P5DûŒ~ò=O«‡Ø!‚]i‘ÜÊìºÓkÜQ —Å`-ÅL"Êó¨ûq£A++r8#è®‘ VØ#9«İíÀòÁáĞAUŠüÖşÁçÜXö‚•©DhŞÎ7ä£ ¡\sÖÕ›Ü<†Xè',•¥ËQVvóÀÚa­â®én'Æ—ÿU^ŒÂÚ*dZ–È?pGÜ	X}ßè×ú7Ğ0|iá½d	èÚ"d|Ô<»cï^îCÌèÚÖ·Ó¿ÌTÁÈioÒHVZÅ2Ùù«zMùYñ¼ĞPúË*È_Ö{Gs]÷èò®ù¢OìA ¸yrŞÇeÉÇ“l¿ñö®yY¯Me«xF~ôc³­ìã#[‰Ğá@î’‘™ê›{–ŞÉ6æÚ%Ú‚F\ró^šb—™½÷?7¡7V2¿ô‚µp¼vŠÀ°‹‘÷§l$MJ×ÚÈY¨0ı«Ô r%öS¼^PÙ—÷ıÙŒ£Â¡9yÅí:îº§f­P[²’ôîú™%Nr]›ê{-Æò¤©¼î;«~5Ç'#ÈÆDÊ|ïYËL§|„­¤‘7j²kâ™OPMî+gV*@¢ÿß%úCİBÂÔ¯£äC xG à¶Áª¯¾’æQ5ÿ©™08ÚUÙDNOËcöÅß¡¿j¹é
‚ç”¥—UækXoK>˜‘Ò©2‡;S†Où³)~š©Õú91_Òbèğ ¬ş²Ò^´“…+c‰—Ê¼Ã*Y}=¬î6&Œª³+ïræNïg½íÄ@´2È€³öµàÏMje…Óò] j¬oåÁ!GlÓü?úÒrgäÒk9brP¤,¥!z÷Äë+›lÓ€r‰RØÙ¿4Ûç*'QòvõîìTòê ‰Ë'J°¹êO8‘¿˜)ÜƒYâ~	İ…ô/eĞÈaœy”T–ˆrà#¬9Uœ®ºÈ;ûd§x¸É‹—53¹kKÖ3µ|#Ë~áSğµ@‹Ö³şÒ¼ ½­Kn„³]ÜĞ‘TÔ<3º/·“DËÖ¼ıı“àáG²CÇ’Â0Ô¨DL«Ic—ÖQ²]ºª§î]G.öîŠš;rì.µ<¹œK|ˆ¾gqu ‹®ZºšöA©)7é0-I—­›Â—)€¶V‰2D¤ÿ“Qñ‘ãR¨¹%gäØ«]>ô¯:“¢¦O.›“Í.>JBó^ò¸)V.N‰DÉTÿ¹~·Tìçg¢¸M£áB6l+,F”aÑ˜¢h£ÃCÓÕÎO5¢,Ÿ Ò@'™ü ÍÌuºÌGÀÁéÚxs©ØHe5<ò-÷–%m`zÌS!iÙÏ9côCIÅôÒ5$r²†àY˜Ø¨µƒÛî,¿A]öºÚt§µT‡À2.blÇrõ"APÏµ€pÁö¼ıb¥4UÜfi›CFàæ
¹hr»ø
UĞHÑÒ!…¦®j­[É$|¡„Ÿ¹d†Ò{D—¸ Ÿÿ£WTÎ…iEĞ£ß{îÿ*ndX]Å‹á¦ŸXÊz9Ö£x+Yç¬×Íàü#¶!Î…£op6³¼E´şÃ  Øç„!ûP%“ÇªH p…‡Ä‰¬]ÛúÑEÏÉag®€¾¨t¡YÓsŞr„FŸù2' ëë”41óhÜÓ®)ôf›¡øËÄ@ªår0=/ {H·ÙİH˜9f¥OÄÕêIcõ8yÈ¿
¬©Aö2åkî1Úœ#o³û×ó•ÊÃüã´jXŞ}ƒ [{’ß_¬Á‘ˆqÎ¤Jÿú#›ê›-údİşÚ´“˜Šøâ­“r62É–3L‚A5ã®÷ÿ²iQ+WM)çg¯g’0×2ƒ1ÖÃDùw^Ãœ£šsÑ:£0¿–DÿFŞ ‘ƒúTXJ¼ğõîìX›]b0öh…©™ŒR„ƒ2È5Yh@‡$ß_ûèÏÄF:|¡ŞŒ*5¨DŞ«mKî©Z:îe…–pÙ@üˆ.q jŠ[[P¸¸wŒCå­g©©"4õÚ*Âî®, ĞËéÉà¥Ô¶èšYUK2k¬ef ¶Õ¬F<¼Ø-}–	XÑóıã*ÇÇ;Ì¡°¥ŒEJiü‡¹#Lß´RM)¿W$:PnãÂ}¾Ği(‹Ğ~©a)A¸9Á½ÛwU9=º‹à¹õâÜ+¿$Ksêh£P=îºá¡ÂW30›beN –<·ã›g¼y1sÖ ÅmîÚAL”Ü(‹’ŠñXè‹(Ü‡ùc?jé½‡™<0?lQ.gx~D
z ­’Øi:T>†¼LöÙK3XO[ãÚí/ÃÃ-µBŒQÙ0
9Â$B¤l¦éY^/İG+ŒXZ7Íªóèúÿ`UğVmîPVöé\lİÒU~ª•M}UÖ7_‚~1°ÌÈáwã­FÚ½­ˆNêÓX„
Ì%Ğİ­äú7kP1®ÕûÍP8ü ³ã3åshÚ²ğƒ˜àĞ@b	‰é£ä÷³å»êÿï¡~÷ğ»¾71qŒ ß«…rÈq<±¾€Ùœù‘(à!"t-®ã“Ñ2ä#ßdü
TşV¨ßlZmâ¶±äÂ;‚Zày'1Ò4a/WÍ|!:'æ=N#¾,0;mÙƒ”äaı³Zm„áŸãpŒ
qÔ¢+êEËƒá"n	g-É‚[0=wNë½©˜.˜=XŒ¢4ìH·ôM©xÈo \¿ƒOxcÚ4xÏÃSc€a‹Éşä'Î•øu¼ÁÑ8ÃK³Ùn»ñä¸Td9!9îğì`İUŸ(#¸ÍGé§N¼fr½¶aUÁ¿8ó†Š,Pÿ¥ÕæÉÑÔ•[³!Ş›vª¼w&K©‚¹üJVí ÁÈâ‰›Iq0uiaÖuãÑL¼ŸSâ:¨FÏîåÑİ"Õ]7 ávI:±ø’æéPı°Ñz“ßŠj´NYj”’}¬Ÿ:n¸£OåVÆ™ØvBóÆh$ºÖï®ó‰¤ÔHp_K8ßÌºãa³nâi*ÍùmÑwx…—å¡H§gVEêÚ]­PbÂ)@]ˆÁë¯uàŸ“o½¹ŞÇ5íÁy1ƒW€·÷˜b
2ê9HşPß§{½hçß;NâCŠ½î¹Õ_·õkKßĞ¨„5¸’e=èx€ ŞÕI»¤?É¾Êe §„U‰rÅĞ9úº
:!­k7‡¾ş<Gş”ÖÎÖ]è2¤ì~ è=q¬`˜«´ S’aW.õ(fèoØrLb%zt5*¤)ÎCš)lÖ:ìğ ±ÜR¿æ‹z×ÖÙI8æxõXÉ…ÅÅ¿k@=uÍ8QiÄê÷O7Võëßk60ZŞ<?€™‘&¬ õÈAx'ğl‡$-½¶²ÿ¦,ĞjÂöY#œÍÉän›¶7DÆğ,Õ%ìäê]¨úËy—C‡eÅ^s	3kmË$Ç5"eËì°‘¡¶¼ô9UF¿9 C2=vÉ4v¿XYà2õ]|ºùª†m5¢oJ–ƒÏÔ]j—ï¨ƒ°Iæ`øo4)‡À)T»OM_Œ2†Œ¦ŠY2‡ødJ’ğ´gwGÉÊ•KS¸?1Cñ8Y‰8}Ä)¼I©Äë–Ï&ğ}ïXtRoÉ”G²ÀPË‡ÔÑïæK&g3¢%ævx.¬ÿj©‰ì¨åÉ}l¯¸ôPâlæãr‰IbòIL£`ÈTN1oK@ûc¸†mÔ.	œ÷†í‰L}Ü™6²¨ß@%ìMG„Òµ–xŒ”û†Ø—Û
‡nY~òá\'Ó¸'i™Ê“şAé¹m`BMÉ‚OÖN*œ¢s8¯pd™zLº(XCñ)¹wäDDC:Ï6@> ÒÖlh—Pò•N*ö•äœëó×îÅM  İ‘spÕM ìµ€ğ-°¢Ş±Ägû    YZ