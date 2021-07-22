#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1845376220"
MD5="c8ddc927c0e0aeec5976c1aedd341bc6"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22716"
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
	echo Date of packaging: Thu Jul 22 18:25:18 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿX{] ¼}•À1Dd]‡Á›PætİFĞ¯[T^ªó°-6‡ÛªÁÜgGKsaª‚AõU§„ä¶Fé8
ûìğ?pƒÆ 2Cl+#’#ŠîÖ6F +™+×»jñ¥h³¬D¹orºèLÏe·êĞü'”¤Iï;ÖmŸgƒ¡G¥´ì^rx$Êweê‚¦,À‡Y9É}eÂ¤ÑÃİûî_İ2Ú…éLkæ×}‡:…OVe»ßõ}Œ}ˆ\}±X$ q-ŠâŠø’pr~:”¾?‘ÛîØ€{]ušq2Ûå"÷êÙ	,1šIP:ÀFyPò•¢ùk"û2_Ø×½š:ÇôN¼|pMÈa«ÅãñözM5¿ÁD€.Wû}û‚Ù‡×·‰‘±µ¯efÎÖÍm46#úŸÌì—Ãš >Ë‚¹­ßd­1«¢¿¾˜¶„¾ÀÛÎC¥F’Å;aMd ğ¸RK‹çêN½or%‘ÑK˜‹+Ôø<€_ƒß[º½#¯'OØBXZ/=ÊUü<w“¶ª•Î¢Î2ZW«É^¶Ç”VñªŸ|BÈgØ“…Åæª'ø{uó‚å„{ô…“)[å®€Ğâ±Æ™¹Ü a7ìMHYE<	ú ›/ÛºqO÷•¹U]=_%ÍIXn7k¬~z‰°ıÛÇ ÇZEÜé91cÆš.û‰F`aÖ2¤XÌ9y9vM†¤¿?@aÆŸo?0ÌóÇ´ Åè=7?Ãõ¢«hÿ®N'ÊL6=ŞœH»ØİÈ¼wÏ`»|d6W#ÅéZ“ßÚ(îåA˜oÕ#ìÂ0~g4 N"MbL8¥ÜğIq-3´¤†bU¼Î½Ã+Z‹t=AZs·û–¬<Ÿ+\t¢¤ÎşiGc-^Ï°©vCì“ŸZŸ'ƒÏZƒ ™AÓtÜ×€‰lq€m¸ºAÃ›HÉZä ëF€o»Uï:†ONif‡ hX[ÕûOås2JR-õEÜ%{Åæâ®àE4ó~"BıÉ·I!²g2ãâNß Òeğ™D¤K–ø£ä5y5I.ö)|M¬gö>f»XıC³?¹DsÑ5üÇ\g®n © ¡˜ÛÏ4®Û’¹Åÿ¼82àÄ[­J\³mXÔrîopîŞVå›{ı^7LŸÛ‹!\ë-œ¡rú)˜!‡çp²@OGšçèQ
Š”Ö||Ä…¿-WŠS…ôW£ÅU C®Šæ&6QOİ10Õ² aQ¥û¡x¶"ü	ñà&hvTÂ„ÇDdÑİEumğZõa¿=ºîÎ‡È Œ“cÕu8A%
ÿÍ)ÇuiÔÀ÷ÿlšşkĞ+¹O¥şö5
S.`ÎİË(êYN}“–LOÀ?×çìâhù=B&‰š^æÍ$±ãÏ¡ÔLŒ6àŸŒoüØJˆ3fƒÓ» è_iÿdïµè¶†l«[ááÅe?]	Viø¡¼b|úpÒ´ÎĞ§õejšòx	|²òùX9«Á8‘…9gŞ:ÅF‡¯ŒóØiõ'‹.*/"î-Ì×„J‹©è#w™c»{K¿“7Ñ`Cñ»Ç†sKËÊPFF
‘£2°+—=p4SçW’b= ÃÀ%ımŞ
—Şâ[PqSŞíYğğnŸ´ƒ¦°”À¤÷#2…©YèàN€çÉÜ•Xşe'’^1ı0GÑ]l móÄ	].¹ÓæeH+ù¤MŸ&"ïèÄë+¹?%Ù½mì±]ØG(-³WP!#u4íJ¨§ä”A¯åÏ?—5B«®;FIÔìoCby^“ä0­¤RòÑ9Ö¸¼5m§ö+eÍ®ö#QŠ{GPøÆ«7_GNö/(„„°ÂÉ
V•ãêqhyœâŠøSÔœdHçCzX?3ÈØÅXI©ª;#Bg[ğfØô½¾¶Ùˆu_ìi¸|o”´f/¤JáBtw5ioP&³Haˆ°Õ–Ñ/y|!WT~®i*ß0!£×›ª9¶•_4^ ôá&ˆò%.cŞ×‹Ãîl¬å-3¶úïzÎç¬Q©ç YÀgeûp€Ã)ï‚éùºs¦øk«äVÉD]úzò„1„f'ŸJIı°û²ö3©QTãLøóLuÔ‹p°_·Gm!¤oVmŠÁúÒÅ<ÇïÆ–°»¡Qµqí‡8¢mw$5Wá	i@NÂ¯“ÙÍÃ6¦£_uî~<×…Ælám™À”ÌO¿& (“8³! ÿTÒÌ4F½–zıc%vú.©ØÉåT¡şpÏ‹ Öˆös´ÃŸ-Á¼ˆŸ?Œ…2ùfÉĞÂk!Üq,¼ÓGã_‘a÷'fë9èsü•PìÙy£A¤ud¬k	È÷©İ†iˆ¨ãöš_3SW>mo¯sŠãÔÃiõd:”Ô×îgğšÍ°»©gæF-Ò×ûSSÍœ©æµåBnVû’«¯c”¸ê§ò0ŒéÚËoÈÂr=ş7Ç ˆ¨JœĞªç<«6¶õ“fç-’æ €Ä‡'ôı3ˆÈÙ¼Ù{ÑÇ›î0£™éƒfx}>Äò4 ¡Í ˆ¤ -¢Ÿe`)T$%atP¡QÃ¬;JåÄ$øõê2,e×ZW¯ûu,,Lóï˜sñZ‹Q—”ZÄCµéÊ*«æ[­å5ìh‹5]~İE<gıEDËbÓ÷yJnİÎ²Ğïô~6y;^Ï¾ğœèI²LÉ Àm0ÁŠ‡Ïæ‹ô‘wÀ_tÊ\YŸ’h·™‹0¹ecN¢¯»Öœ„å'ÅÎØQîïÀºöÅ"\ÇJ„¯á…+#éQ:Ê²ÈálsÑ
]I(YàÃd6¿‹l4¾‘yÇ™Ç_ü% ±JèûòC¼Ñt@Gê‰`XR^y‡,&
;›<åBSÙ@eC‘*g+ÂæğÑæ(éâXõPO¸ğ¤ô¾æp«”¯DÏæíĞ7Jh‚.—]âø÷,²SYİ/Ëò›×ıGÇŞç×‹<…8¤ıq@a·^>ZÃpšÉ)Ã$›ìc-«òÙaêX nyÀŠ‰µeĞñ¶D%ë˜C çêÁ!N5âˆYÎyHm
LÕŸ>"˜d-½Œ¼ÀqÑ¼’ÊôÑ‡©¥Š©“6öNaeE­c´Æ!EøÚñ¶AÿA/JïòO]²àÓÙV¯è(ıer£°K‡›¶ã$*DXQ×`ı—ÛS*ÊÒæüñäbœÃ\>²Y³ .—PğŞV¦áœRAÆá&+ñÊ±°ì6W'şØ{»/CŸïä«eZÀ:Ì·Oùà¾B€½|øÁÊhZrùû?ífhm<j©ül¬·G>!Dtñši÷F|Rhÿ’ùhÓ0Í¼)˜
Ê™+BX¿Y‹´WÃjCƒyüANs¬wA·b¹JÁŒ‘Uçß	Qk.j:öÚ×5«À"1cê$8†ÄÅˆÙ¸¸×ÃÃıv·gI*GÜ”dÑ"XI(ÍÅ…Gé¡AE¼ĞÍ­t/¨ÉÀ>¨ó…ˆ¢$fÖPÎjËüÓ¿6‘oæ@‡§c¢9uâi‘ÿG€ÅçKd›ÊŒ5®³À4­Ÿğ	u9«g· ŒIİÃ²÷U¬¬Ùmƒ€‹ékmØ×’P›¥F›íSû–LøZ‹ÓXAıÌ¦†OyÑÈiL³Æ1¯Öeµæ(¥"Fé×£ª+k”ÆÁy?vF¼1•:Qt­2Ê9G|€&¼]Š¸A^kCĞ­ ÉI¤‚ÇµGPŠ¡Auˆl';Ûõ¹£‘R$Â-u"ı¢ıÄ'ƒ£8µ¯ä>l#leÄ~ZrÕÊÁĞgYAÕZ@ ÙFjÒÆÛ§Ÿ­BWxíšØÛhVüQ¬ö„#i:GºöxrÒvKØ»øB&«‰†±æ£ÍsÈÉ¬¿Ãår‰£#Åš¯Ú³t6ªÈU±"£É‰g¶%{3L iŞ¨?aÿJşwXÛ;„™ƒ€“ÂX «W m-‡ÿÈcb' :ÂrPÕ³QÅéó_8‰sİÊ–û¾ƒUÄ‡äP ü\*T~(•»“İWÏ b^­”©îÙHôh}ë:^I:Åï¯‹İ Ä¿wEèÅ†_¯r$Îcc5ğ¿Ü‡‘L˜Ü®q:%?‚Z2Ÿú²ÛÅV¶OaĞévS‹ø?ûòaç&SÃ`Æí6<J°­ÍßVTQ˜m5÷±ÛñtĞ6Ì“n8¦q(*­€z"íŸ)‹‘“hßùmÅW[ÿ]×d|÷ZQÂ"ÿÖí&e;Ha^xàıú`ä#Õ±&z'Ê´O22g³Yd P¿;æ$Jş;ÜÙË'Ü?NšRiø§e0óö¬†‹;ëÎq_šÙI*Õ3’´|çç˜9
#C½‰~ÆQø]w„'—@0ş” ºáç1©ÿIV2ùEÇûXY]Çk‡%{N[2î«Cum=w^¨%†rmÁÒ~íã~³ 9W¼‚í`üatWrÍœiµ{a§û%‡NÖjLk‹á‚‘xwCsÕRDxê y™O`_§H©‡³}Êô€Ñ½(Æb@O‡e^ód°)¥eÍT'E¬»Ò£¾gŠäIK*vUùa²Tùl™ÄÛä^L5€fµë­¦¢…W½Î{„…ÕXÓõ‹€‚$Šaş;k:ñâSÑ¶¯e.EÈ@W–Šá ¸:+ZkÃ¡ å‘–Z-+©½úêåAÀ\şGúvV´Á~axhØà$ƒ2Øşâ¤CM=7aÙü«Ó=qIÀ0°oŞ]¾’,øicÛr™–ÛgPEx®F‹‚ZB\&½çMÓ„âµcÌ€şëQJj´>¨<›5æÎ‘õh2q{ƒŞGoL2ª!~u„2l3H«¤šä'„ÑÄø™ş‚—rRJÃi?ö{
†ëĞojhN+\«‡#^ì2k©²Üæ/‘ß•Š<±dZ²¸¶bŸûìóªm½!}ö¢nQCÖFC¥G$Ìù×wˆSèiJ§í5í3·ä‚‹’}-·Èù6Éƒ^ß½vçGÌ%=9ãbß)ÈÔ¥‘ğk ¯ÿ]ì~¼øÖÇ–H"æ @ ƒwá8nîå—qÕ¦èCS:;X­y¬ µ%‘ÙõòüÒyÆ#C”€mBBBjÙÈ³aYãs¨†1Eõ¾µ®XÔe†•:ªTOë/x•ç 3•Åü´D)_$¾)$Xoš‡„ìø¥ï!AîGúø|ÉÒ3v¥è^Æc;°ÍêÊŒ˜ÉÓ
ËjxïVõ“0eQ±Y"®ÎõœrND=^ƒóö’|İ{~)nüÎÍ¬ºÏñ2å=ğ÷bÅÿÙåíó×GUUKš;¿Pw>KFóa^AyeÎÚ.j¤`0{{?®ğm
·4*_¯—q-çÂ¿¥W¸À#|şrm¶û+tL#c}^Œ3Ç)öB—vÜÂQİU90í¼ÅIë£pû*o»¨ÎXİú>¹•\-»z¾¹0wİ0à8eäIhä|?Ç’wA)}OÂxİ¼ı¬	c.@š)\ñO Z=MØ=†|…î&kàú ÕXr™FŒI§û“35m“¯t¶A4EVä^ŸÊì¡ rLv`àyœí¦ÀN¯–e)Ÿ‡‡/SVş’€I*Ä9€e€²	3¯s ì![¤ö3ĞQ™¸¡Oë–,BaÏ¯¥Uü“5œÈQáŠ\g"{uM#Z‡I6AbèE÷f‰@ueîÛ2ëLO,OO~%Z/fµ#§’±	N8ø¾z[_¥‚úö×[òp.°˜|š¬YOQ‰Jç0E¤‚yõŒğŠQ×£&—¡nä·iü»e·Z¾>|l1ÛìÎØë
ëí*2 ?ÒƒÛ=åŸÍ~Bs·`®ÄSÄió	@?_F	b
MœL²'¨Ÿ¸ï$’À@Ÿ™3²Fë7,À*ÓºËÔ¿«\sŒá7®Ø8S%Bƒµ?ß,"	‰~yß;‰§0pñ×dVÍ1Ôñ¨å¨·ñ÷ÄÀW'ƒÊgô9åªÉ™³EwòoêœO{†ÿ‰Z¯¥Æg¡ÅãïÕ Ô=Ú‡½¨N¨ã&zM›v÷
!,+Ÿ—ÿj£æFf¹w¶SÖxpÇÌ#´–¬OŞÈè42¯=çzªQ4†2ºçaÚ" ¦x„#alä-‚#V=¸ñx%“Œ=ô3é‰vŸ“¤8ÊÆ!@[D>Á¸¢ +m‡À,€V3j£Ş­b…ö,ïtù…nâò ,TL¿UÁºËÒÒ¸¡»O˜È“"M"ÆÛõ—O%…ğ‰bŠû«Û­0©³°®<KŞh!É¶¾1(F!ş.œ¾<Æ¨¨£½Ñêáéñ‚8İ_äÆªoiË/d@«6ªf9¶-"è=ê9¿DÙÒŸR÷s“5S†¥¤öİ\gk‰‰ÁUûsX£ø(ÎSk•Ä¢ú34•§ÿ¢¯‹ã¨Á‘°ÏîYAWÑİ­Ñç†¹ª¸²w¼?Ÿ‘z;2°Q!íÌzb¦pr€Æå^bÍ(#½æÓ¼F>,L‹lR*;•²xTèTqøßƒIÂg?Çcÿ“±!ØË¦ÿİÀİ¸P%ò&=åy¥—»`üî·Œ¡O¦­P?Gé%2Ñƒ¿Û;(UÀ¡T¤ ifÊ×l½?ºB{)!ŠÂ™²'ÍlI™ß.%"ù’ƒ@n	êÂ±ıÜ©ÿ¯º%şX=ÑÍŠ]¶É9|bxìÆ‡Ú#F¾VÛä¹İ÷eW¹üŒ©˜ZŸıhgf±nÜêww—Í$‘ÑºpJ]ı#¸HÊV¬SI#¹şµ|èëml³r¢´QbÚÁØìù®šL|ºuŸ7¿Kpìö KúË…u}NR|'ÊMä6>8ÉF‹³ĞÛÙé ’t9#—w7Õ¡Ó¹Œ|ßaĞm¨D‚Y0x„B}–ÊŒŸ®¡†¨XáùpíY¬R´ÌHàûŞ£{ÚçT¤±™À:3c¢ìsXP³=şŞ5“8(¯D´éH©oÿ8©*^›ìY¢Ü¾–ÎZ7}Ø~@ÙOìîÕH;„tS©_!Õ¾©)á2y2%^À‘ÁËqví¦}ËDnÅ”«s: ¶Yb·øÏıxÅ>D”»›™%@ú+w]œä&å¥xÒdæ€î-€"‹l—[¼u;è1sGåLmŸ¢%Jvn–å;r¶E¹Ú½¬Îv,ÿ¾‰ó&"Íüó…€I~f{,5¢€ÃkŠY0şpBŸm<üôÈ+óÀJ²bŒÕøêìÊòSı×ÕïÆ‚ÎÙ!OÆ’/ Å_G\PeliIü	©äd’i_º…Â[Üu8¹¦åÂ€)š¦ò.mÿÉE‘ôÃÔ¾É^â€©ˆö‚¼BÂoŒd}ÍtZç—¤nGÎlvI¤ĞéXqX_¶‰¥ğ¸Œ¿[Ønà_z®{
¸ßV€Cı½k§}!:’ñL»ç‚—´îÉÓ€¸a	/ÜDXÛ×›]õ
ÖÄ"@pX@5RÙçj«éïËRL§İ.BË ö6Lwş}ÌõœF	¸Ÿ•…Ée£·
…óVGéæ°·EÁÄ–ôMŒBÎ—%(Q®ÅÂîÀv)êŞö¸ĞÛòeŒ”§crYƒIKÓs@…B®ş‡†“Òˆ±¬jäğl˜~é|ÕK@a9/p–;Fÿ1QøitÖ?=‰œ€åçÂo=o|õº¤0b•êöó›¿M>^Nl»^¯qrLoö0ÖÕÖ±,ûˆöÂûé–¡òHû•—Ş×özúR·$®k÷ÃP”YˆeSVG"nÚ·Ì²q5òvÛÀ~UÃZ†CFs¨ÈÆ7×™üâ02KÆa`ÃÅVÏ@Bë™Cg³”0€ù~«±T›)BµH¥c5¡	éÛI øª<*í• ,;A-ÈØí%;tiÖ>=q”)*íÃ¦•‘^;6 eÈh—¨]¯ö9›0Íš¼.XYßè(»ìoôHÍ½ïÂˆò
Óó¢ ,kÉ“UËV_î·šzš–½¥É²¨“ç…TäùªUÕ¸QØ=,Ût µ•ÈR'¶Út—o+qù‡FÆ.nÆ¹»X”glîj\¾‰È>÷]^ øCkZ4M´´Œö¾ÈµÙ¹9İÇ^3Éò•fi«ª—éºB#HÉ‘z„–Â”x‹ıCk»Bø „ì. øpÙ™ä#‹‘
„RÅ«A&x’Aä¥c¼S‹7K²¡^c(œ)ô¬,ÛqP‹±^;¹õÿº|FØ´±K„ÿ™f"o’É·QƒÄKD3¾¨:Õk!¨õr’5x>)CQn«‚ˆn©'ÂZ.±ëb2f;Ê0%š§Ó3,&ıÈ“™†‰ÂULé×8T…:øª¯Ãà((ÎGÈª\~b?ƒÑêÕI|oRJ­OÚqb¸µ‡[RF)¿™­[i#b†+'»á…‰¹G»)Ç øÒ¹¥ø	ˆì§z	šÖ\>ß®»&d1,G¹×»Á1Âxxxú
DNX£ÖøÚ0E1,ŠgŠèÇf“îëc•Jäd¾‰ğÁA/óŸ{Ùú~­:½Àêì‹@¿ ˜iÇ«™‘·ø¡vÄ9Ây¶ZÙR—gé#I×Æ •¬|»‡Pˆ¹*Ö©^Ù».iBM,OZ¿|Q<ËBğ'åÀìk¼5’¨ûŸIRT•IÇÀ½¾xup¢…tôµ[ÁË²¿GMÉJUD •Ö•à:ÌPåw`})IÌ/­ÀVùiOb¼?e¥²º×‡? ¿/#Š iºµY	‘0öêA×»[Ûx}Ğg}aªypôpo	-{©“£^Tt†Ô>³C·w$¢=ãZ÷“…xÆ9A‡æ2™‡ë”ÎÊL[­’¾°Ã¼şù"‹°b³|Ú¼§hÀØ_ N/.èYu‚uL§tï±ù’¶èÍíÚN[ lÔÅWUCÓÀñ?,I•Ç³ßÄ~›Ì„eAl¶Œ+YÕ}zSVÆ“©;+îbù¤šªÓMå¡6tç(ğ{Ò­P¦PŒ‚×bPˆª MçJd[ï`v®“¦®¤>˜\Ôø7éiõ"y™ÅÜÓÇÑ´ÃA§cü{
Štõ¼ŸÈbÃ5Èÿ-y«ßp¯ùø¨®¶Ô¾x ‹×½¤÷Ó²6Ón»^	å?}%ÀmpêŸ„C‰ÿıs âFmß5É‰À$êaa_¢Ê¨‚ëÆôÒ5SHŞfV$§ïa£e¶¤ºe»YÿOöl7Dİó}"p'‘Å[Cîğ ÎƒC›ğW1¢,¥ˆ¶D:
Ùt/«ö–QÕk¨E2ÆÅ´ĞÔ«³şĞë$ÀôÆ4ü˜»ŒJ·RØ4Ù¯êşù#Ûp¦¤Íjü}™%{Í¾Ëƒ Ã}\›ûrâŞ:¶ãØ$ÙÕB”.LêÉ“FQßrÑ˜º»Æ`´/òós %[*[0­Ò
ÇyI^…âá 
GNól££N^‡nşG9ÍOr[éâPçúE%Ús%óĞÚf^/Ecs‚€ÛŸA—óŞ/©ˆtØ$à[«™6['ÙŞ€åÁ'-«G–ú¶nÊ7Œ¾!3Ô›C%N¼kCåTáñ:
Ô»İUÀ*PpZChuÀÉ¨›Ì#7mİ¼æøùÃÎ´“QıFdWTÑŸó)g¿•î\ğ6šRÅ‹¹ñ¾hıÕÿ‚æ©.¤qÎ‰6c5@©Cj<YS6Süa€8ö½ıxç{Dúw5¤Xv“,a½Ôäò^-İ€„–Ÿb¬7°ÈÜP½(;áÚZ‰õh´£íOÕ£BÑs‰«já{½ ^ï8¨¸‚ ^W­oFÕ Œ=¸ÿ9™t¶™r{e¹UYabúGâÖìjFÈW½ÍJ…ûß8ÀÛÊk°Û14vÏ ÉwÇAÄÌøÃ„İ FÑ€¢b©h¤ÎªW‹Â/ÄAÑ{J`s,O9UËÖq”È”ª‡ó7$å†+«$mˆ›Yâ™'åä¤ Â’Ÿ«èõuğ©Nå)L7$¹ƒ4¿òüß`;ªÉK ƒË´^İÎ§)ğºáÅ«5§O¾ÇYÚÒÄ_0ë¯`—„ØÕg'!·3{ÔP¡'+
s†y2LûAÀ C·bÎ9útä_õğaúMUÆ^['eq©°™z9äÍáêh(å„°GáMr–˜]HWÉ*›Pğü`(iÏ,§½%`ISd|º'Fdh?&XŠ…n«T<ôšd½VaÿKøá|;Åij±i×}‘NQîËiÜÇ\DÊ5„S2X´Êâÿ78?r³«=°H[·òìü;Zƒ3³©vP¢~Óç™Ö]gíGıõÒı ±”+ˆÃ=©^kã‘J"øOe©gØãò‹x¿v#“r¢®iæ`÷lå¾ºŸú‘Üàs?‘K1Ë}TíX6C‹€½F˜ğæ¸r…Ğ‹Kõµï2¤NJÓÙb‚gÈ©íñGŒ-Ë!ï]?¥i-ûòÍ°£[`°.dÀ?du¬¶™|"^åX[!¬Îvûø<ËÛra<\MóÓ(ÉN<ó˜ttXüØÖcõVÁ—*
,È´†µ%èS<´DñkºIë:H´`“/î°±—ŠE­2'²Y_l¢m™ê‘ o>«¿ıô¢dÕBÛ?¥:Ä·-³Y-<Xıš}şf ô¬äP‰ğùÇQÆÅBšÊóuÊkœzŠ„9Üs.;~‰Å”!çú‹ÄW€†X¢^ìöûwP²a’>^“$’n.ÖÔÆÍ
JoÁ¦a×m5Ó#¾a6ãÂ{"ˆ`ğoö/?¡2P+=…D(¾{çõMàÅ^ïğzû‚¦QtÉËÉ¶Àoä"´úgp 6f,öœMM(,"â[<·s¨îÓy?ŞÈˆVİTı£ì\R åkAq„Çútö`$íoO"¥Ô —&.Š%£Øş Ä¾uÜ’Ÿxxé@@³ô¥.{ì`¶\d4Èø:ÂÃÔ·}IÃB$ÅÙ¨DÃÍ£èCã¶hí|Ìs¢ÏŞqÇ¹!ïµ -Ş¦Û¨ã)ä•øŠ'æ”À«W;Û/æıiïË†`TšX¡XÊ~ß&ûŞÍ°×üiáÑ~[XZpC¤¤jßÅs1ëšSTt`«kì‘bys¨ol•&ó/E¼ğè€ -@ÒL†N—"±# 'ª%øĞS6£oBC9X¢PÉ«H¶ü‹Ë#Z‚ğGvÙøßnå«W`FUµ€vs‘4Ao³­[¤y>kşĞ?ä”¬:lúDÅ(dè!·mÌv:g­a4ò`^À  ;ÊÃŞ+\º±ê*Ï´J¯ ä$Ì³‹-,$w<ñÎâHNé Ó‹“IìEª|è7æ;•B¬“NÎıVa(²7ÖX,‚k.<¹Õñ8‡¤5A¾È¸İœB‡î""8õ5’t8~ŒZ k½e‰Ò{“$¾—¿ÇÖ5*5êß|š¿]>yCµx–´cqçëÄ
A¥ñèqçı’Ã–'RÀ ”òöã¾çPz}$z#ù•8Ÿá/#î*š—ø¼ ³Ïøº±^ÔO¬^1öC¹ÌĞ4orÖ=¥èÓ2¾•IZmC0<
ç¨ÔÏdÔGï‰>C4ÜÓ¿ü›#î•>ğP§¤7^’ä±QÃ³RhåºCdåIê¯)o}ÄdTùL}#ü™D12YjF’WJñ¡ÑE
C)­ó»£øM	ƒ,d2µb¸™Ì$›Á[¦õM˜ZYğm‰ĞŠ]ohÈ€y]Sù}0Í—l€ÕËÏåÅğ;“ğt'u—È&ñOb„EwJHµ7»if*éŞêº|C˜bm T´â <\’õñ-QÍY!´:ßƒq¸úY¤Ky+BP’Ø/*l†ºë÷K™Ë­DZTÙÀKºıË“L¾Íå´Ì}³Åf,ø+€®6¦»T—k^–ËùGc´IVeÛWsTšì
#°ştàãÚph’yc²6­Ó¦1kŸX°ò.zĞna¡)€ÀÌ¡¥xYéú°—«ÙI¬éÄàM6v=¨æäÊ’rùØrm˜7H'Cèù ¬={ˆ}*:ÓëŒ8Á±k¹5ÓOw;zŠÃ†Áê	æÕÄ!š,WËğ<ö1-Ñôêîwªºø±dó‘â÷¼¥¿‡,É¶û]Âj÷Íµœ”½†¦€®ÏÉãYrÏQ§˜ÊÆP¸÷Ç–?JcT³‹¥É¦œÙ‘j•@?;ƒI=ÎXÏ@™4ıÏBËõl>›ßÆ¤š:Yæ/Ö”ì"8Ú-ßìVKÊBôC•Gñ‹È$3uô	Óî³°x­ç}Êsß–@‰¤a®¡éçÒ©`Í5ø²È ¢R÷ƒ»p…¡ÏšX“páæPÑ¦ZÖˆW»æ¦5Á®Âqb!´Š¡Êq­ıCkÂ]d%‰¹¢1Z0©Ë›Êó6±MJØ¾B³™ÙˆP—İ°³ë_}óBÆ"ÅÉåc3 %%IïJéeÛilºËc—0SÕi"2
=şä–òÃz­VŠúãb|(ÿOc[z%õ`Ğ1øTÍÌ	jÔT-šÓš#‡—u\§R3€I9Óø•ëzôgå”ìÌêMéié½x0FgÜC¢wÀÇşJÖ¢¨e˜B5îÉµ˜(İ²Uñ	2— 1‚Ç)CºßäHÀÏêÄ^P!¹
.İ™ÿŞ²õ\¥P¦¢ş¤¢¿±ÂšÜÎEyÑÎ_ŒSS…RA•³j½aÄµÙ%?Hªéé~–/s›¬¯šÁYÊ¾Šg&à)ùâ#„>¹Y¢päŞäD¨ãéÕ&—ˆgKN.ê{¬1°Ñ°.^ö÷½}¦ñpä»	2Ì“ï¹‘‚[ >™	²ÖÑ©lû¦Æœ-7ËHo¯Ã’ùQ-OAG‡1yGÂ(ˆ¡eüE¨¨ ¼0}àwĞãl ´^]LWJĞŒ®Ï8TÊÎxxQù5¢X…ï£0nQŞtİxM½³g$fı(ÅÍ_Ò|¸ò•=J}t‰<0ŠijÁO*ÓÒ‚ Jƒ‰íøCê»‰¥ÿnÌ•P¡³sz6L/é÷ğ=|›xµùQîÑøk:â‡ö‹®“áB™Õ#ÿømH@2Ği»,ó«XëÇ<ÇêÛÛ¶t9[&¨¾A=—ÁœLoÇÔÙ}rnáGSIÔ5ÔÏÇ¾ü÷D–ê!sx]®ûèÀ‘¢$c5£™ÎÑğ¦İäR¯ÖO	aälcp¢Qú×ši±^+šmşäÁ¹
2ıß|7Ø9¤Ú€%Î ¯Œ·Êw[@­Sí<C\×)1YœšÜ«“ì5L§Bÿ"…¨tş=>áÀÔWùå~1vôBáÃP©¦ –ÆĞš5úç}"m¨ŠÛIJ¸Bæieï˜„uÁò=@û)à°V%Ê?Šª
=«&ºønv=‹áàY®ÏV¹±“b“Ã¶”Û÷œ	¤N<r!rá‘9‡ÿŠ!~E;¢?@[p«Şìx?LŸgÏôœWRS4n:æj®•‘f®<æ2´º!V†Ä¹)*Ô'¥Êås¡Á5¨æ®‚ğ§·ï·òUjÔYé°2OkSŸN; 6ê‚£¦ªš+ïDîøÂ%ùºÉFŠ/üTG’¨DğˆÑ…Š$ï°¨•fÙJ2öÊ›°2Å—IMz–©ÓD:°z<¨NZ¿ú®¹Pl`Iá¦&_”OŞ]³³»« @B›_åNzyõÇÃÇ ²vÆ;çT=»qw,bi2¿¾Èa_WØøˆë¼¾KÙ^ã¦æåŠŒ¸MTy#OñÿS×?ÑM·wÿutŠ&’+È;ßâ
Ü¹DPqu¯¾ºC^lÃWÚ„§[ 
‡vû ›ù<0ªMï¿):†|&­iíÌ_{Çf¼€ªçMÓ½ÄjÆê@{õ‹w¹¹§÷3cJ,·ÆÓ‡1„‰ÛRPv¹Âğ©åı§M3ØğÉüÖzQGG$ı'¨õöó¤„—2Ëe-qÓ	c§N‡)B<¥<ßK³JÇ½¤átd§ê~eUós¡Ş¹£c]÷ÃĞ[ ›¶pk×}ı-fF!
,C6õ¦Gï÷ı”Ã@Ûv+éÂ7H8–¯™™<ıI–uEÚc=Xò¥ÉK*‰åáŞÅ‚0û³ÖöĞì«šÍ/‚ª\ {Á&AÚ’:UŒ(› ¶!yı—˜O.{
-vÄF¶I£A'E|B ²–A¶q!ş»­nÉá°ÓĞ¦şK©ãŞ†÷U Ê¨?œ¶zT-JDµ W–lË?éDXQ‰“¾X«Ëå™Uù0fùn[Q±Âe ÅŞF¬!©5Owv]¦Jï[€WWX‡­ï- sëÏÂ%*d¦
Y–€E°FU‡{á%wÊXÑ)›ëzª+çªìÉAŒLùd×ü))ØşceÔNÂ>à
iç¶-cx#…êÃá(@‰—‚ÒÌ ø¾P‰[ÇêáÆ×˜»ÂÔ„ãç¦8ghpGºÖ•L›dš‹}E’¾÷Nİ¹ûäàµ®KäTQ­l’Êçç‡„öq_¶ª¸5²4ñ]İ’L²¯ñoÏOJaÕw1š°•Ú;gùWÆ ãÑZîuç/ñŸ1ƒ¬h $º‚Éûµ8%0ˆN°˜`•K‰&jk¡.H¯-ä‡6D.Óp ÔÅ‹RÌÕ$s	5ï`€ø/~“q:N#{\5ŸOz¨Ğ‰`V³Ì*;Šôş¾1NŸ˜ì¯ù€ Ët³…Ûºx€ƒëF{Ô‚/b,f½l@ùîÓ (Èè&P:ø	@ö¼:_2Ã£
¡øˆ¨
Dä
³û=p¯z•-kvírıëÏcÉ"ùJÊÚ„ Z‡Ãİ¼ÄkàòóÌßŞ©ZI®øÆ;Óq»½³uU˜{˜BzvgìÖ[¶Öq£ğ5Á%UÚ ñ“ÊÇ2°#®{÷"Ú×ÙZ.*œL>×
ğx)6ó¼“ˆn[‰
˜ìEa/¨=8¤;iõ±(°Ÿ~g!qEøŠ»b«3‹£kóä{7o?4ëOĞÓìªF²¯²”Ù´!Äí—ñğRD´em—ãí2ÔıÉ6È
È…4šö6QáX@lêò\_W›×5ï{Gó‡]òÓÌu£kxĞ1€nŠ7IflJÁ«¬_âk¦¦îLéë¢ô)x­ámûZ¸‹mKy Ÿ´ZkİAvõ§İDjiŞ3U-ğiÆzdô2’ÚrÕî†Ä5u<úpXª	/#ô‚¯âfuŞçZÉÈ0R–iÌoİN!Šƒi©‹öåªµv®ò‚ùı?;‹ç$F°uGi1G5¢X$‘'aœlxæRˆ•nõŸdhU0ªF>»ø7Ô¼Õ2*ôá
UõÎÄ‚õÚÏp·9nùâ*ÛŠŠ ^”µ©˜üâ¯&ò/ú3-˜p;é5@\Äå%©®_³­KN]a}k,ôˆÅŠ¯mì‡p¶…ğ#­»ÁAfâ²ëbqñ$²Îy©´`ôy¹¶ÇJé¾ìá®Æ‚ÖxFÛ†«€ËÎç±0cş¯Ä~ØlĞxÑ	¿!N.ŸË#MzÕ@-‘‰Qëß€' UfbÉw¾[Ê˜jE‚)½;hOĞÁƒYÌ8ÇÖiĞ5‡¡BÃåx`Bd[Ûm@íZÉ¼jèA ò¬'Š[ËÖàubÏpæT.ÖN‡|'^º*Jû®ŸRÎbRÒ'áU@iŒ.Æ	“–†£ÿ~uK´«„”^áØÎ”{Œ$>x VCW9ÎQŒ3ôBÎ„ÁW#€Á€+S¹ÕvÊıŒí·Á.Ï–í±68+Ş¡Â< ¡S–µrQàW¾:ØÏö~>Œ1xI§šC5Gi€h[ÆgÓ»øÕRâíAI˜w|–·g•¯€Ûwò4^ˆÂ>Kæƒ€TS®ú@…7Ñÿ· Âs°|*™»„»P;ùÀşUQ{™@/í’`d¹ºtW'Êöq¯Æf~Ò­Åtn8P°…½ª¸p Ø/<8‰ŸGÇoÔ¸º)!iİÁÒ¿dÏ£É\Şm=²›jäÄLä‹1ĞLW|sÃK!°.åWé©˜~Á“O]Â²Ğâof•®ö=ÄU/šQyİ€ôÄM?j3*¦eÂ¼_H(p
\á­Ÿkæ—ZßÙ(ì×Å·ñ¤¨¸rZÿ¡Ü<DxĞû¸>¹ËL!£³ZtË¨m9İs
óm²ı¤ëöÃ® D2¡/û^w¢Y²8~“©3ğHaƒ#Æ!Ş®•êÉÂT¼¿íïö×C ÆâŞD÷ß¯6¿#ùî#]´ßV7û}Ò‰{Eš‹Ëç¿k4€»%ù^ª„mÚİakˆ6#…sZ:{£‹İ…ÆÅ_ß«Sdÿ*˜ÄT…_¾b!RpA/{:š“`ÏÌèH2‹´=ÙJ|‹ÄÒˆÚgTğ*³¦3Ó)R”{»9à6¡û•ñ’Û9˜İˆÇnŒ¢#­Îä\
Ã„n#~8æ
M’Õ¾n )&;Ô
K>Ü¿ù;œO%A"R˜Âq8gxÁáyäOªâ~eH•*5D?qÚ~{™L@Óë†æBÍ(g-¦pÿ8tb5MëÈ	Ÿ?Új‰‰ğ]²¦ &×°95è¤FÀ,ı¢)¬ODómû`ôû„èş§øHĞpÀXçl»“sÁŸd1"Iÿ´eÒcîÈŸjBVí}¬^©rLÆ±ù;ñÛ6X$.±)Û_ö)¿>(ãçì+°j¦®ÌCë»CúiÃL×uCœdƒ#Ë‹ºTÙO![–jƒ€#Ö“nÎÛ“@&é•ú2w°ú)éŒ,¿Fs:`óK%Úiv¶¶“öÌ48ı“·xáÅäp)jÆu,Kÿ«!î­÷hX”\hÆÉÔo”èØq[÷ÙñÃo?•"ıA#S~DËk‡±¨†ÉÃP Á.ò#\^Y›‹oVÆIß¢ßÄ×JaAkW”•<g°DÉ›÷—TcÓ4çõ;­mÄöp }l¶-\qüRjµ%ô#4È¥†ø nè³™2ñ¡9‹{spş7g°ñjuì¼.™6Z¬õßú­l´ê¤PZû†%~ğ„|ÂÅÑ`}•Î÷kùîÇQäÏ°£g>~r&üU“›L$f'Ğ‚Û¸õš´Ğ½e+“GZÄÎ•êAºÃ-(³¤ÒÜÒ±¯¬i
$Éğ•|°ÒLaÜŞ×ÃY,Ö„¥=ÜBş»›~Ì*V>+kf}•"ü=1“UÚo«ÚJQ×O
äßá›û¢mËÚÍº‰%şÉqó<à®±UNø6?ÿ9™ÊuÀ–±|öªMj’•m.]ñã´jéÔS¶ ~¤™N+øŒÙ(©Oj…“BåşÂWœw^`D´àÔ¯ôÎ"·€»¥Rõu·]õ©sÒµá&¨Ã¢ZDyY<Ä{ÿêhã¯éÆY(J©Õ>cO—Úğq¡„¿;efKƒY?ƒ˜IóP6zTşÌèQ!AÛIJ…±‘äSö¦†Mg	°8Y€!„ìQgˆŠól‹¤VC'•úÍ„1aïÄçA¾Z¤PÃÂŸ®–j%ÏYšÖ	ék¸2EÇí
îıäVTd¿¹:Œ™k»£ òÀI¨DúI{[üO$Ñ€‰B¶­#ì˜`õš4]O
ki\RDc`ÎöÒƒ=r¡ôQªL$ä/ÃaÏŒ•i5¸Ñ>Ùn˜Lv÷Gh—TXå\OÃDÌ'7WEsˆAdÙ(Î¢dbüx½‹ñ¥‡
H9xtÎ½íó/‹{ÊÉ®´”¸ëÓô{4ñëïP£Ã5~&OêkÃ¨=µH9§åt11Š$céæ.Ã™€½Øšà±öêvós
¾puE>"ßŒ™œKªCæ·sµVM¥¼O
\l
1÷ùõ¦«ÿğEUr˜l³ÌJ0œåÎóËº Ællørò•º„†0@ıİÎ/^u4!D¨Ö_9J¸\ÜC“©Ç\£wyLCû×“'˜Msú¤*‚÷É$´ååéæL)1Fz¤oû°Û¾®ãºÖÈ*1Ş±z%ê¼¬ ÃËßÙú„¤Ô GY¤{zä“x–/`ÏéL»Ğ!.A2Û`V‡ìVW/8.×Í.ïÈ“MÌ0áXoé?Š*›"z“Ñs›Ã¼¹±Ÿ…¿Õ©£²¼æÈU}ÕÌ¸|µäk‹±d
íÛº*cUO;WW=îb§´CT’oúkÎÜÿÙuÎ5QF+]€{ˆyãşÅi´ï7w¬t™Ğ¢°å ¦L6N+ïø´®Á–&Qx4§ºäA}l³±¶£¬”BÒğÔ¢P+×\¬:œ½ ÎÕ'•k~-å­ZGa¬gĞ•G3'Ÿë"²e6İ%]bÑ½[yÄàíY?i­öó_‹ÑĞYd?ôX³t2}>ƒ0Hˆ5ïÉÀW jLÄO°y|ÿ6ÆNáà>:ö"0¹¥ Øô³(uº##êË3‚ñ‹RBçß)	Áe5Å+¹Ú}‡İ_‰ğw¹Æ¹»“>P¢Hÿ²@/ş‡B
ƒK‡P3ìQ”aM9é{Wë¿¬P£LIZ@BADşAÂiòÄÒ«`N©‘÷g>û¡mÿP»ºI3D½Œ¶<ıŸ¦”n§pĞaˆÑ»Â&ÊÓewÎ¨r>¿ÿŠ»˜"ì‡ò>“:lç1Õ¿Ä£ËRaFìçïs ÌÜ¨hÜ±¹sä#ú-—¹ìa´#öãùfÈ×m0bè¤:s(ª+Ù­12wFEC'y Ÿ¡{0ÀÒ¨)Ó-+–'oÜŠpÂÍkípáBA5ÃóÖêdM¤A
§éÓ—m,b¢Ë¬”–=æ½Õ‘üDĞ%‚Nöf¦«½¿ÔôıŠ‡IÉhƒ¸$ÎË­=j¨´W¿¡€‹Íë‡2¹ú¾ÖÕ„üKs¡ux­UaºêñÂD¥sµ;.3ÿ<*Úÿ˜·o'he\¶¬ÉÜëÛcÓ]¡¥¬şÄ	ß·VÜX Ø¹q&Hã2"SÈ£`]ŞË=oYr‘1kQQãşÔU¹Ã‰ZX‹ÙÓŞ¹BÏ	 ‚;¼Íé¤ƒ€]«:˜Ã´„;Iù1Roïx;.0Äİ><•Msu9¿G£q|'~Wo® ¡âœbŠ³z´>téL:È¯[ï’§éÙAmÙR‰°ú€è$¸Æğ" ÆÎ¬†Ì}Y“Ø9š6îè×šök{
œ@duÙ‰uÒ¾elü¼·‹Ô:»l³£(AP†¬¸|K4VëÓñœëß4¡„‡¹%9¡Qby¤No§°ØE“êÚê¨|æõM†5öş	›!ì™ĞH¢|íáÍÚ³ìÖèA}¶‰òÚ'dü™z¸ï (w%Ù·Ÿ$8,8»ú0a"Y{àáº]h×é‡~Áî_
9¿§Xì:tI	 ¾dâ÷#ëœ„HŸÌƒÚ¿2ñáÁı;öûÂ-OÌ"Ûµ>´„q#K™ù`Qªªó¢h@R$ÊÑé:Õ~ûDó ~utÃŞ÷f>óüëöí…Q›Äğ¹º,ê‚è`Š‹– ®òübgmÁğåüÖrH˜®æß|õŒÛ]bjø®ÅÒ–õ¡‘ªbÏºµû\µåí†8¤Ì®ı»-QJîŞõ6m®¹	[òQXo-æt:GtY¬‰¸x®eà‘×©¯q©ÖÜŸ¯æòÜ;9z{eá7ùSw¶ÒMT‘(¤3	TPúÅ@&§i+ØÑ÷Ÿˆ#ZÖGßî²ô}Ärfû¿x½.ÓùVÜ9 °¤¥¢yæ+ÕĞCKW2ºqkõcÀc^/N]‘t-;¨6¾*W?Ş‹ÀÇË€*åÆéÖœiLÀƒr!¸,e—å¤'—©£Öú$¥‚X‹÷/tnáİ½gëØÆĞµBR!ûWèÏş+É«ìga<öÒfxèû•¶£êÍ)·‘Aª—”º[E×Ğ@ö'i¬½¿ Íô"ìÑ3-SbN[µ£ùDäèCPÀš»£Õ=ñƒÇÓtàëåsU}+COCÊ^dÈoÌ&ñŞt€vLªË­ÜLÕ##)"”iuÛáëÄ9éqª‡ûm®kòaŞÌMZ¢%Ì2ËÆå¼>äÒŒüçş³ú0Wséƒf!@ÅU“m@Ü¯7~,D¶æAN­}İ¶)PYÄ”×zA¡Xû©ÍÅ-¯‰ãî	×¾>-¶ÏämØÆÍ+»½¶‘€\|İ“5dú Ë%{<´C†íúx_¨±˜Â³Ä‚û·¶âºEEÏ¤jšgòsF`ñòR5pÕ'›©eÌâM¢Ö8Ğ$pò¸¡¶»Û/u‚‰§ÅÙv¬™” ÊÒ‰‰Ìv‡°nÊô·ß)L€ìÖÊ.×Å´ĞEAŞ”¡Êè•óm¼wÒk&rˆxÍ¦v"'Ù}â€ìh‰aÍ‘Õ[ç~ùngÎBÓÈãRävÒ+°¾Î+¢Ğ$ÆeÍ©ÃTÑ¥räm9†˜CAnÙ9‰ûöM?‰&ÄãtÓÄİşİŸÀµ”%¹ŞcRa-œap‹Dcà]VHËş!®¼>ó†»–F'•„¼‹[	X !Æõ“˜×êŠ$\Ï`±‹À¥`Á?AØtmŸUL†µÏ*Ï¶¶±?JÚŒ±ô
× B»OÉ~|&Œb°Î{
TíØ¥E“1Ô~ÃÄfÇ“¹¬5r§¬Õl…¢‘6Q-jé³_3×>ˆ˜…[%·s<[\>#cÄ4æÑ*<iWc˜1YNCª·–&-µ…‚#¤BÆn+N óh5l^cßˆ'àUciªé ³¿º:Åõd‰hJÃó0:Hm^‡İ'ŞÙ·ú¼$²áÌ«âk—hq—?uädü®y/AEzĞØ¥œ–iCÇÛ²ŞKk‚õLyáHÅ<"å’¢u5MÚª“<Käï¬B¤í€h–.’¹ì¶#mC»šøº¤òX4/+QUhØ0–?u0ê<gVöîZãğ4^»°o{Í×ñèºô…úL˜—Í+h²¢°vfÈ#zgÈˆıV˜ ªŒl|ßñJç
›Ä6)] RşüSèïò‚£ìlÊ`a¸¤ºß÷ŞoA”ËåúèXEŒií‘ã ‚ã\¸îî™ü ÚûÛF$ÌÊV„êu”]bà ¸£ã:}BT»w—'GÔId²øYĞl"ŒÙÿXŸl}<5ºE’¯úAÛNkc2.‡‚ùš`±)“uWòáôu§{Q”ilv£Ô±¸ısåïğT­"„tw1ßoÁßK(^½5ª=óÑx(ûl%*Q_2BÚ·\éÏ7ÇÉÙéãÍQ(1)do²³ÉÇÌÁŠƒñ„¡4bêµ¿F$$·í†à	
ü]w8ıBı	àA ÅU£cü3¶ùmÓë_d‘3\ø=n”uF’èw¦„*‡Âaê€¨%yÂT‡hMïXM.%T·«¹R=9<Ëg`¸ï3+Æß\R%e>3ö¢°-·c[Åª´Úß¶'Q'‘h¨ÀŸ[„¸ şP¬Å-¿¢ŸáXã–Bˆ ÑÃÁ9Ÿít¨œ>^™7×@*cû&² ®Î\S ªúğ,–6ÑÀT£Wuàİ¹0{Íøde·º¤3Éöš-ös½™í~ü_Âœ.]¤sfúˆâÈ Œ¬€£¡;È×‰éqøáˆ$›§?¤Y.^„òˆP¿ä mæ¼=¬ª¯Ã•ô2–×oÄ ;‡¥{Œ½LK×Ê:NôûY­˜ĞŸæÔ'¶Ã7Ì¸-T{ºõLKı¿A*‹£ªjAªïÉĞK9w(˜é 	ùÕV¿üÏDéÌ=‹¦ò÷åŒ*Ûrƒ…¥‚rç‡ËÈÛœ«ÜŞBƒšÊÈÜ·m¢lE.‚½¤‰›‚š\(ÜŠ+z¢Õ.Íí»èÍ»ü—Xk¢š¬`>ô)`uª±7åßë_tÛ\m }¼Y/Zq¸ÈA¡ûaDg«P¿“ïÎW5{¤^ı*j›æÊ÷®:zÓ¶,ğ°åÜ”OsÀòïlÂâªZª·§Ø€ÜÌİî~İÊr÷ƒ¯ËÎ¸ïÄi8ûVPåS>R#bûÌP‹U¸©çnX½}RÌ{xÀ+¢V»eR5²0ùŞ$ÔŞç/ùÒ?Vä:´z°•V?ÿœœèš™´6A/q"^1I[<àòOY<&%~ÒŞµÀí[g,9DÒ¥Ï•hG
©<O¸-6,•ò¸ÕJ5‹¾ÒÓ® *á×ãéw²8$ä8©QI‚²ÛŞ(İÍÈ|Gk÷Ç	)qI8Ş1$ú8;ä¢ÊrÅà2SLü¶C.ú@¸éèc¯$ûõ•¦lÑÀE¤¨h°‚ÃY¾Õ¯ZÏJ©1ëfÍ½+×ÕVgŞ‘CÕ¤É*ËİÛ¯T¥ÿ÷Œ›Ì4¥uúş·u÷2èèÔh¾•­zòÄ¬â±)…“ÑÙ™
‡Ú4JØs½(hvæQ2 <O¢•>£VøØô1jö:š7Â@4L (Ãd2Nusİ›$>Ÿ)eÒ¨ñÑiç¦æ;´i¯¬]¿f]—¯[™ımÙšÊUÊ.ƒµzŞ×ÃÕ[,aS"À’˜R\1{%S?´ö©ŒØ‚÷Ëo§W[º²Õ°âê(´J`İ"6jÄqâH‘±¬®R¨UGRë© ûCñNì¯Ğï…¸úäL8V×·} 5Öi$?ó%#/³]@¥3ñÜet]5V¡ÊJÑHg¢Ê?©ï2æ§&DŸ¦‡™ ú\§—,áÓ¬¾ábÌ*½‚¿ö
Uy¢íÙGY?šı²5¶JîŸÆâ¸=ˆKêÒLÉšEjk›!İh%’åm5ÂÎ]È¯cÂi½ÂÚÎ ‹r)wBæ#Òq¡ÇÙ—'¾³ôppJ¨ƒurT‹Ûpx£å,;Åè	ìblp?€¼ˆısK›€1êÒ˜¬'Ê	NmÜÑl=>øf)RŞ³›aBŸ\Ë»ôª1
²
PB	Âï-ûÒØd6#ÌıÒ=Íµ+-ƒ2›~oxğ@b\iÌxåxdò˜?HVİX¨CZ¦qÀjáìCS›Zò—iTõ°ƒGÌªŠ„#nK„­‹%>=ş”ÒVÙäéüÎI{Á‚ ’Š™>étJsÒ˜¯î
ÕuİŸ(À&XAõˆåÏ0k€»h^÷àR™öÌjuçNÃõĞu+4L?®ÓT°Ä·†1|KÇNšqËëÓ†hJîaR¿YÈ#	¤‡Kr	?Bœ’Àw~< ^wYnu]³‹Ô" TM…ùÙ=ï“¼Ìw m}iuŒ¤¶/éö×¸z(ßÛB­ekZ3ìtlˆÎÆ´TÑ(w«ç+Ş¾Nù!I“5.ª•Í-=£u ‘ÑÉ¤§ÛŞ =/c®PQc·g°¯{¸ş¥ãWOm–<i¨˜¿½ªªÉLk_©ˆ¹õôóbñ¤ˆ]‚‹-ˆZ
ÊGëõC»#W³·Ôj­­ğwÃ[Ìoÿæá3bkú4ÂÇÔ‹¿ûßiL}‰ µ[;­Rş¥c˜ıvIµ?†ÀT¿§\Æ½F½~ò˜£˜°¥Şüı
z§ı×‚;ƒ9?Wcæ`ï£Oæàjé‰lXF«¬TÚ
º…°³G¨(Šì–|SCJáO¥•8ï²Ç81¥*Šî@Â¤¤Ö`Ü~i»öÊìçÏîirYf€Ìïq:a]ØŠñõqÆæÉ7isäõ(ÎUÀ½Z¶ë¬ä[åïzĞéÃå\·ĞM"Ÿa—«güŠg¢Jãn"gXë{3û;^œy“æøz$6œ£µôbö‡\/,Ò’òpœÊÏNGµÿ2QÉ#rez"ûR÷[øø	¢Â:Èî„½ {jÈ£_a
†…<Šy/1_eÊ¸(›:å*²—,ê&Sä¾“§{*½EµØõ¬ıÿÄìÛ

Ø…^ÖÚ24œÚé³CS4ªÉW«Œ@İµw	5dìUÉŠ\£­Ú)û·pùÍ¿#³DÏ÷2\CëäÒ‡·<ª¨b>;šîHøy\k–’èR‚päl²˜‰nÁq0‚Âô†ª|¿š~f@S
Svñß}=Ea1	¬†d¡¶¤BJÌ^Â¡½)ÅŞ( l =:[K&ú/¥"è ¿é¨›†×7‡ÍáGÃµ™ø"0¿I~6d{ÚÆŸ/U¡Êl4Ãsó#ÈXsàXÂ5ÿšëU¶İÃ+¶H×2Õ[/½0ÈšßİäĞÔ‡=F.}?,ì3rbZ§o¼½µœ¥"@#Î¬ë:1•­z²5—xü×µØd±oZ½¹OâËzï!é„H=šbMß¯ÌGŒ¤yÒË…’âkŒE˜|rƒ¶¸É(‰K'ì£h|úÚµ¬Ï¡›]~ıå2<ËX2ÂX·&2	ÛW¨*÷¤±ï®¼‘XÙ®¥“*&_räeÁ2£•şV9Œ‘góå1¹ø®x<è`Î
sÀ6mÅ¥ş¸*¡0‰£f×0cÚò‰1>şÅ£—İ&ƒôUm»«fÂeÂPö:ĞË¤Z+€3Af¢K OŸ·ÂÖ f7aîËÕ‚ó›ıÏË[ºH29“—QAK#·ØÅGYÜçuÇ$-§Cœ,º_¬ÈZnå'½ôŞÊÌüŞ‚Ouá…FšÂ¢„ÕíƒÖ³–±ºGå½ÿÄ«ì]·ÉM–€ß–9tü/ñ‡v~ªÍ©i( ëˆ†y³í¶Íš’â?d‚Oo€ÄD½÷4‹tŞÜÂ7ç¨~–(Æ|üòtÙ_a à½İ‹´9ĞløñQ°t2}3 ®q$ºH¶FY'4áíıˆÑw« Û<KÌØ[xİ}š[ÓÉÑÏ×£O ?¢ü½]ÙPĞˆ•­Í§0à¼‹Èz¨oÙ‡>{:E¤Ux²wòxì›	šª0"øZàİË °Oİ!W­éŒƒZ?©ÆdŞˆ§&é Æ‚wBÏÕıúD{ tI©‹bÜ:dÚ¦I•¦O41&[OòÚÂOÄ8§gô­¹Îé5sŒ , ÒCE9…şI—½åAuÑE"Í9nY˜Ë½xI§÷Å*­ºH+ãïâ,MTâÌ„9`Ñ„i\¡3 osšœ÷<ÏôØƒÂ¹Ì 5½*zÚø2+Ô?,©]ıÛÒŒœ+Ù?®İº-ïı8F:87`^,»×Ô BA:Âì²^&ËÜğ…¼rÒæH5ºù­ïİİGOüå‚ê¾oÑ‚óiŠ]xÚ„SAòò®X>Eàœâ…I‹p/a#X—®«ŠÙêŒ.0Ê·`ñ™Ûš^¤Bûìı&,ßÆ9ÈäÒ¶K@v2a«ÿæ]‘L>9[üı}v¥ˆ>õ›•"ƒÅ˜x[Ãva²¢ÑÅ$µæ>.©ÓÔÈv`ı`;ãO{âš½""Ú ˜šXXœO¬©Å¥Ö—ß+†¶$îËà%»0ÿ½53{uÃÕd(b÷Í]etbì!÷™¨¡ªÀ`TDl	™_‹ˆJP…“à¸|y> »d¨ÎrQªuj-0$n\Pë,’Ù§öä‚Í‰òäŸzA(ùâkœÊÖ¡?’6Ig êG’Û¤…×Ó‘0ï¥î;æ*jÑ(v\Q€ï¡«!–	§o—ñè]— ïBÖôÅ6Æ¸p(UŞãw\yÍè¾¯µ¡+:ıS¾‘i'€µ£~ò’Ÿ&ï¨îı·5bÍ¸¦IO~¦6ÃyáÀˆ]Y‡\-¨Á[@ˆi„¨_­ŠºYB›ô%ˆU>Önÿé•ŞŸ`ìà?-NÙ•Ôöbúàú&Ğ úÖ‰Jj½Pt£yÔöÒŠù˜4 3¨4§—„Û˜n_+]Ör‡øÃulJà²å¯ôsK^x58'ÉĞş“H.{¯}>ŞŠ Åh[ïñ)Ğy—Ftê+TÉ¬?âñzz›OÁÕ>UÆÙ6ÉøÀM>Uïó‹ÏPJhHU§Éu‘ÿÔ‡ûëpm›<]Ó$&…@ĞfcˆÓh|w^³·MöJmjK†ÃÈ}æ‡ö¶ÅÅÜ<ÇûÖûTM©è¹±«tn$qìš×FïãØª9ãş ¬=Œv¾•~†„P9ÿı@[ÑMú˜Ñw®½U~ÏÑrÃB;ëşÑ|W~[©Ä^QhõF;×7<æ+¾ÜSÂêŞŞÀE¾+wb¿`ìıŸ2?Å‡Æ_áRµ‰«!TÙ§=nd£d¾EÕ@«rYÈâü^»Â~~ÆÇÑÛZxŞ¯?G»Xæ¿†4ÅC¦ ©R'.‰Ğú­8ŒÑ×€VO €çò{¶
K1ÖÖÁó±!(=JòÉ^şÛ¢©»÷÷[êrK¶ŒAI5dr5Û7MîÊÃıÛÓ=Tå@/ğ–š˜Û†‘ÆIDö¿÷Äÿ
rü¿:ƒ!{–-33ÎŞAêÿCGå ›]›k¾PQaÈ³tå¹.1
ç–öDÌqkzµ=ó
À'¸ÙÆÓftº­:&%üˆ“£µÈ"/`âå÷< Œ§¦àØoQ“øÁã´WË•ã<ªdSGƒa·pëŒ.uC@Íg&»'Sc<ïÄ/üÖß—'ƒS Ô N~=!]²Ü^ÜXƒKÈ4ä(N)D Ğ41Îyº”xëãŒÕÛ§Iø	´ƒìlî´|3R–²ÑÑ‘¼ÇF¨‚AFêè%Ã·7iòEn=dwÃ)Ó(—şĞA	Î0ŸÁ¤ˆ	İ®5.†	ìƒÀ-$Uì‚	Ó	a„íéñföè2ºÙÛè9“ùsÅ÷±º€à¯TÍ(
¼3IÀÚgf]/VÛ„© ´tœz¬&¯ç¬g¤ğû8L~µrP5ä¶²Ê|¼B±]o$cG0³ºĞo”š8ƒGÒÉÑÒ-pá•ç˜Ó(¶?%qÔI7ó6˜èÏsmíœşµyêwmˆƒøÇ€óFÏgœm­‘ËØÕí²¤KÓAs¼'õ>´¬#«„í!‡îë–FßûdX¼ôAGh‚š—€uü­aˆ0&:0ÏººÕ$ìudcã¹(±ot2é‘¶cZæn©õ Ó°ÿÂé÷àõF#¢§9L>ØÙnÂ“¸)zÎ¦5Y Êé¬s{Ñà©”¡Éz|FÎIÅ*úÉ„óÊ˜0U}¿n˜y3_Csópµ®c“_òß<ÃTNe”×œlŞ´_ôJ/V^ƒi D•2¦øí5)Ñ/;jgKU´ÿûQ”ìƒû3. ÂE” Ù
ü¸ĞLÚÜT[EMFØ#ºô€i”cŒ>ïÌ¡2uñZ"[eú_y4!àxÀ×±Jé‡¨ÌxôIŞˆƒärhİ‹¸KæÈ,åÎOÅ—Û¹şÃ‰ã€Øïjò&Q:y®fÆ¤ÔâBM˜EÅ‰zŠ\ÎÓ&å%b<¼â°„´í…5ÿ—6¤Zæ¡è§_× 3	Ö1™¥~æÃøÙ¨D!æò¸´F‰À•)3Lb8ô¸¢…aÌûë|n• GáØ¢òŞØ"‹_Ûc¹<+gJDlò¯¨y©×9°ÌU:<8S%¨ØÕK¬Ä*~ñ†¦šçO¹C8Â…y]2júãÕİ¡o;†lÒI‚U:‹º:ôè¦½¿ê[ì•„ŠFÌ9%ÚS+téÉ/½”Ï4ˆCVWÇŞ £™˜Sñå‰Q{Ä6MDâÙ4¼¦ø›-eìeRs¿¡+ÑV×NÀe:è²Áìc…ã±ÎzÓ2yÚPLb:}=Cî7áŸ.‰”„/Â_üÌì<TšäF§ñcQ»ŞjEG´ÚrTÅû¶¬Ú¾¿B*±•>{³{DA}{-;ââÜßæ‚9«çÊ®ÿMD5` ÍBnx“Ï"Yrÿiˆş¹»µ
5ÅİR•oka°®5ĞÂ¿pc4ø{÷lNğ £°+P¢gÃŸî8¥%Hûw[/ÖÃSÏWğÍœşµ¢oÛ„ÒÔÔQ^u­pc¶&Z•VÏ¨î¹ÿy¬¤m>EózS8•?!O/gòcë·}ÅN€ãï;º„óÑ	ş]ïó‚¯5ÛåË»$·%„+Ó -;° gŞ¥Ê–b ÏÙíOøjé-¿Ô3W˜Ôí¿€0!àLÁ•¿é®>(\3a¡ÍìÈª·D?H©ØÓKo¶Ã—EØ
+Ä\ø$Æüú†8#VlÜP;V¡ö†bÍÓ5Û[Á‡‚šú}Ş;§/æÎ]Şfû|à›¬‹ª'ŸXŞÑre`KÑÚ’dõDÀœöÆ'ß¸!n~`6MÙ»şÅ`à	ïãap|Äª|º.|
ÜÄÃkÕL4ñõdd~“â‡7"±İ?ĞÁ‚ sI,„×˜Ä@êåPoqèú/³ p¢h÷ú™}‹-‹øW‹Í¨,è8¦‚3âŞc?˜ÜĞ×`«EÌ¥«Ï©€¤˜sä‘¸-ÂÂ9•NÌÊwn£Ì‰ók7C#:H…şÊ:Ãz u 9$:²İÛE#Õ^dè¢ç“äå2&·å¦ŞÙY`rUû]nD(0ÔÌNN‡Ñ•åeH »µû\ò’â¤©ÖÓ(YçhV¹†öûğC©ãño5A@"b8¸Jâo\Yıì‡ö¤zÓ*$Yrå»Û\ğ¼ÿ=¶?Ûv1ºj5Ò¶5?Ì­ŠÕf[êg!y¸I½Kyn²Ç6sÙ6œ·,ƒ¦„¹¶ºyE²´%yH_Ë¯ˆiëoµ•˜]¾;§ú9áP:vrFy©ãß ö›?ø@„¬Q ™A!±÷½rÅE/-±:1)3OºIT‘0U’ÚÂ€NP–¯›hæçØßiEwƒ¯9äÂ¶»vms‡­Ë¢Y",ÌõŸ‘¯Ó{ş¨¤à2oZuıí*5fßóÛtÈ_½jóc¯ÑDrx”êÉ7’ Z a‰ãÏ c2r<=—ús/3©™œx¿5n–'CPµò!‡U¨uIëĞ&çºNi0ñäH|9fÚı¥¨Äõ|íÅR’l,—_ù^Ää 2Ã¨kpn@ÒB¹F›]İÃì…võ^6ss4]µFÂÏ¼6Áh¯[båV˜Rğ[Œ›ÎÜ¿+P&Ã}:lQ¿¤–š$Ğåîà+Ş³-vl¿1$?Á–QËÑtv÷è«¼7]kFŠ   ÆåUÕl	Ü —±€ğïëÇJ±Ägû    YZ