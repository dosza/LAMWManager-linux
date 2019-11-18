#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="107455086"
MD5="84e37a7dff9febd86b501c03baf4b59b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19637"
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
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Mon Nov 18 14:54:15 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=128
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ ÇÚÒ]ì<ÛvÛF’~%¾¢2Ç–¤nN¤Afi^dÆ’È%)Û™Ø‡$š$,Üèö_öìÃ|À¼í«l«ºq'(ÉNìÙÙ5D »ººººîİT]}ôÙ?ø<ÛÛÃïæ³½Fö;ş<jîìíïîííí4=j4Û;»ÈŞ£/ğ	Y û„<2tÇ¹¾î¾şÑO]µtûrjë¾¤ş?eÿwwv÷
û¿½¿½ıˆ4¾îÿgÿT¿Qg¦£Ît¶’ªÊçşT¥ê™c^PŸ™†nP² õu‹Àã‰¸äÈwsÉ“–eëØBı-©ÚvCŸÑ2›Ô™SÒvm/„.©ú
¹ÎiÔwê;Rµ#H³¡6÷ÔíFóGh¡lî›^€P“%rVÚeb2âé~@Ü	 wîúŸ['¯azT'“€	48@'—¾îyÔ'×'2á:¤˜ˆ’Ug+ù‹pR¢W´wºÏÏ´FüÚ5¹öTp1Ó“£Ñ´:´µ5’ÍEğö`ÔÕä¤ılÜ_vßtÛé\İÓIw4¦İ7ıIÚÜ†Y¦Ï[ãšŒr• @¨)Ğ09°T=¢@½éÓyàú×E¾Ã6ûT2äW¢À¾Õ†¯;j­¸™¼;Äs¤J9ù8æ·İ Qklê¸É½›³“Oo‰´0¥Í,®å—.1jæ ßš¹kÛ®£°å[#¡[„o˜ºã›e4M¨íõL‹²'[7DªÄ¼RÛSóĞõ¹ë,€WÈ*âÛ›AaU·0a{Eçç0Ö`ßGBìYh¸Ä¦ö6Gâ gŒú}6†v @ªÌõ€¨4˜«Kß=ò7²ô©'†EÏÛOD5è…ê„–Q]û3ùF#x7a1•u±kJAŸ»géKÆ§uèå0ğ‰OÓ4ó›2€ÂcÏt­¶;<_¹ C¨rL‹\‹AärŠÊ	J¦i¦m\çj7ø¥ª	Zõ–TÜ“À5tà!#.ì°fÌ„g°zBy“•¥|çQ!óhŠ´¤ÁsP§öI‡/[)à4ÒL5¡²®†µä™(Wr2Û(tò:DñízbĞ…ZÁ– ­t‡y§b’>¹D)kO¥Êê|íÏgº–	ÚğÒÄŒğ~n|Nïœ^Ñ9¡ÎéôÇÃãÖ/Z-z oZg“ƒQmé3ùtúWI-gÙŠìåÂäù”1 
ì.¡Wf@êõº|èSİH8ü:v¡3G'„ ÅõãŠùJ#)Eá"¹AI¥J*	±¤jR 6ÃM±ln
+É¶òÆˆX[7„R	ß8Y}†z>rİ à>¥Jª‰‘ÀÊ‘@çû2ÔÉ±2ç!òü–ùk
“Ú	)'\‘¥JÖÂ8ù°¾µÌÆ’G_?›ãğÂé,Éâà€õà*øñÿşîîÆüo{ûY!şßy¶¿ÿ5şÿŸî%Ú¤ÑœM:*M2ğÀóñ mÉ#´¬òKReâ’(~äC¿ç†cİ1`|%ŸZŠ¡g@Œğ¯ObğRè¯ŠùÅô¿
L?#÷ïÉÿ›ÛÛ»ıßm6¾êÿÿÍü¿Z%“ı1éõ»¾!jœ´&}ŒØ~!íÁi¯t6êvÈì:%ÁH7$¶~Ím^ÄsL…ù×ß“¼ëd’ûøÄvsaBNÁããf”X.êù²Àz~ïé>Q]V)¦„‡^İ©šEøDQÄhƒZ¦mbXÈ(`Ò¹sµõsÊ¨µ º¿‘xF¾kƒ@G·"d¢cº8 « ğØªÆÃê¦«~™¢‚”Ö²YÍ[å­ù+G–_yºÃxD»Òc&0^EY˜>ƒÍ™ÏCéPàL¼UÃ~à½îñ:‹"å­~Ø}µÊ_Òşó’Ãÿ²ú³¹ÿµşÿ%÷…Weš–Aı:[}Áø\ın³èÿ·Ÿ=ûêÿ¿Öÿ?¹şßÜTÿ/
úÏ rAÂÜuRÂ‘A4â™äß>YR‡ú<ì >„(¦~
Z£“‹gD%­Ö¨ıbW!-Çğ]ÓøB]ª4 ó@‡wàÃ¹ÄpÉÂ›GiœnèÄqÉ°M°Ş¨cYîâÃú¦~aR^¬Ôí™‰/‰H½aëÎ©b˜,˜.`íZíIR6iİ¡Á†–ğ8`:/©>•Ïf¡„¤ùC]~
€IíŸS‡^NC0µÆ®‡‡|Ø±é„Wä¢'Òüñá#)ÓçRBN3%c§Ş¨7òxÎFÇSX¢&Ç±»pêŸBLñ‹Uwı%6©À?5Ğ—Lõ©EñtgÚ˜6ä&À2=î?Ÿ[“š¬†ÌW-s†9T5ÖîÅ`ÈC Q8iõùbYD9êw[ã®&ß9ñ«îhÜœjÑD–ZËŒ”S®#Šİ?K»ZÒîK‚^ìNÎ>âe\ı°?³PP”¥®­+)íW¹8€Ä@r ²®Fr0…ø£ºpn
„J±`¨¡-:“¼v}OÜ™o.õàÃ?@—0ö/à0èO|Ú>'Ì´gşa™s—Ï]!xf£ø¹a¼gaò/b9Daw/~}ğÇËA\=.á÷&öŠ|ÂTÑÚøßŒîf0¼Dué¾é‚Ù¹\™órÛ>UQ²Ø¶¢¹\Ë’‰FdyıÔ¤s‘£Ê¦©D)]ªò¼4©úsÃÅ
²RZ!d‘çÒ:óàA¸BD;¾$‰¹à(,ÉçØÀ²J±]o(30àr6]‡«İ¬µ}ûVyz›C˜D`é£ƒÍİãşéÙ›é‹ÁI—o"[éCÂò˜;™Á<~u:iİrCV2ãm=Ë×:èN}ù›\²ºDhJ§Odèf}¡·%Øğ "’ÁR|UqSÂºµ¦<É©¯­¯ 	¬y4dˆCxÙcó(€æbòâFÂ@(&<¨cS£‘–o‹³Ø•î,izº¾¶P±[¤2c‰¥
V È¬1zJñ‚Ó`Ñ—?Ä`ÒM'¾w'šÖj0œh²b . ±{,“Á8éqiã± l{ õêY‹(íÅ«ŞğÕLbáº½şw¦"¸PåËÀ•BšE-‰ŠTÒ›qœÚ]ÁÑŒæ9°aˆZ+
6ªƒ¿™^Ìy8²’ì½çÍ¯ö¹?+;õæVŞ€`Ó^n{:à"]ßwıÒ´,³ÿJV}j7§ƒÑIëøV&ÂašI‘]_b‰àËÉáf­TûeĞÁ)¿]],6BU’Å^æÔSP-b`€8
ÎŠnËŸ¯öwKÅ÷!v§dw2›ó ±Õùü%‚šæ½5á,£î®ıßxéáÛ_´ q¡FMå@J¥ …à^f|nşX.U?nûä{¶‘#9ŞsAóÅîƒhøÿ°Mäv<ŞDT[Ø†™ƒ$xîºÁ8ğu+[|+á-sú)EííL[æşHï¸u4íĞÆµN;£A¿3ä¨p‘ ‹SØÜ8ÌÍ«~†ÔğØ7ÅÔÄœ·
99ƒïkf„$ôåœ#‰(¬fodÄÄfØ5LS\©2¦(&C}~®/)áñ³éôŠß‰£3R»ñ ‚ıZã}ïn?zM¹8/æä—©ÿñk&LÜ`
5L°ºXğîúß^c·±]¨ÿíí7v¾ÖÿşÿÖÿl,ı)ºeë`ı$€•è¼©DâXQæ¹3gåµ=úrÛTñÈ¨¸€×•êõ/tGØÑÄVçyàô‚[3B<ßt‚y<>{>şe<éhš²™ü=iM&£ÓxEÃõo¡ùO¯º§Áè'è;tºšÜØßß‡—£ÑàÒAÏ
—€W~ë<&äoàÉ(å¿ïSú!.ÕP÷šJäë¼	i`Ô¿À+H|^8	ÀŞÍ‹nªÊwƒb1E÷ÿš.JKÂÒÏVZJMuÆVße¬«Â\ƒIC-›Çeãó|(Í¡¬´Í¥ÅÍ#DU¼=_<ı‹!b¯¸ÿÎÖ•MQÂHŞ›O!uœ²À× 5rµßët{$r+r¶"#ˆ%DS›Å¯Q€&ŞŞñ8=;ªqDûEõ™©Dİ=«6&S”iÕ1ÎUÏÒ~›©´Rw’¤XÅP cÌ˜Í1<V¹¼!jìp®kA ZNÔnıGÕó)Æ*ºE6¥ï•Êc¥æ7ş\“¡†0Ş‚·¤Áã¡>ı„1~`=»jÕïÉ…ç-IJkk!$Q„Iª ;xßÔôI\%ÆŠ¢b\úM‡š^‹,àÀ¨4#D¿6Şñ“ß•F¨'IEµ–íÁ@·™<É\S-´”¶
ÏPA™é{=ÕQC”1[W9’e9QòS&9C—LHRú‹êi-Ã Ñ‚±Àú.Qq;X<GÇüª/ŞŸ±zİš?—Á§1(j+ÓéXÑª=k2¼Ö„jG£Vç¸+‚h=îô°^x²¿†ô¹¥;çÈñø¦qfúhùá#Á0€g=HÀXZßU¹–]¶œyO–"—.šïmfgs½âÂ;)&2ñ÷(tE:µZöM&?ıDÈFŞçÑd¸©eYË‘Üƒ£lw²„ áPÃñø1÷ûN4ÜŒ— É³”¦RØÂ„<}ê‚?äea4Ë‚`GÇŸ¸Œ ¯s¸ï‘Od„‚[×aã2:©ñ ûx{›Q¸ÅÅHÕAå½÷‡,Ô}Ó% ªà|.Ü¹’üU(òdø¦[’(Õ.ê·,q¿ÍU\Çº.}*ˆ!–¾jézˆª 
Ã0*>}Á“G¼U¾’Y”zd;k!yr>Ù92JÖ]ÖK'³àƒô‘(£òñÂèdgI7ÓÒ‹|íÉ\š¿é¾‘Mşïò>dqÅ.·Æi¿#$úÏƒ×–)\@Ã_Z£³1^Š~Üåó¤Iò6`ë¬Nf^#)3*³ÄRO÷@ncª¶­Ûâ2pÓğ{§†á¡2¸Ù<İ=K\İzà4ù]Éã¸g®Õ¦ìxj‰"mé,ŸGs7³­™ÆÃ§(Í *H—¾àÒ%·É]x‰·ãØcwÙÜ"b„†Z6?øè:Ñ¢Üa”y%n°º$]ÄÅá’Â}r¬UÖÊÏä¾³pĞÈÂ¨`´}P40I?¹tısé8úz0z9¶Úİ.*wê²Î’çbÆ¸ÿ4ßÎô­s¥Es~“ãwÆ^­VhŸNÒg^xg„1éÏ¿sLp&ƒÁñ8…Zkâ€§Ì‰aæ…wf¯1Ô2ÛñPØéÌÆdwQ$ ÓñÙp8M´;„H;ÉåQA‡|P{‚_[qâq:˜ô{¿LÇäÎ¾70×
ƒà}Kª¼Féö“(¾èer?+é“£ßŒE‚('‡ñ…ÙdÌ.rçñEÈ^¸¾uîBÑ™J 9 e2øÖÙ,€iß…æÜÏ‰Ä×Få—ß³œœUw¨ ÆâŞ:üW¥ÎóğÒ5’.K6uB‚i6.ÿ±Ù	´¥µÿoJ=]Æ‡¨ºçYÉ…ş$Q©Îù¡Ş¼Ïş–œ$0„y†@zEıïñ‡µ Í˜<³€¡¡±ÏaQ¼‡O,bH±mÚTõD1ŠedûaÓæF‹y#³nPv¸OÿRûşkG4“.şâH£åSİ¦Zºrâ	Ìy±‹ğÕîç¾@ûDh¦( »¶î_+"¹WxÖ\êŒ…OQ%!¬ÊK}¸Œ]+!¨?G_–‡ƒ‰`İª	]ŒË~È¦®ÙFù¸	õmÓÑ-m¡ƒn‰¦kj­tÇ"6´AF–<Õ@e¨åzxëf;\‡ÈçÙG“—‡Gg}àµ¹.
·€k
½×'mKg¬ÈîØHNV@¯õJ—ãù[´0`¬û¤Wÿ ¼Ït°Ü&ÈÊ`s¾Å§¥ˆ„0•6bí<ß3w
“ZúµXåKzVÆ`š(—Å:C=ŸÒèüÙ¡àÎaI¿}×£~p}pğFyÙé*§°”Ú½
(ÿ)É»tÿş}`Â^éVHµ:0¿¾QÄ¥Q¸
Ô*ù«Å:q?À™!,:µw5=éMû“îI\{*Õ),Â¬ 3#ß]‘²qĞí•vÀ4h‹§+×¦1V~šR@@:Ü¹©‹	Ÿ.’Ÿú¬¨åÕ—Œá—&uäZe×, ¶Â_”ehµgf	Û À*Ø¥’6[	õë«À¶êhbÚRuÖ:Ù\ÄP¿²­²AQ*Ïg‡'«ß„< E24bH:ú#,o<;øÆı/Ÿ“E(NrGĞ?íóc–ô,œğË9¢ÌŒ2°ªÎ£ö…6·‹H©Ò]ˆórî\Ë˜æ]¬&ßï†å5/±ï‚GØÖğx>ÉjÖÉÉz–‹R€² ¨Ü“åaÖILœV	2©ò^¿Ğã`–iOÒ;ï/l;•ÚÍ`Ø=ıâN·×:;Ü*`œ÷Æ¹¢Û„©äã™;?ìË[ÑÌÜÉÀù@·µÚM5GÎ¯ÿöî–T¡ônNg”¸^tgÅÏ.(X4ğº4<;HŠr™ö›øñ[NX<Œ}ò„˜XC=„¯?!j`ùİwdk‹TÉ±şáï®¨°	äÿÄ'é¬¼DìğMnèÎä­éJK `zp~åª†ëP~sÿlÚäs4Q¥ã;l:f‰.NéåP8"a¨±?q_':±1Ù€?©øï,ĞQ¦İ[‹Ï”¦Ñ+ƒ°#0"Â¥¢€ûgLùŞd:£ˆ÷ûsï:Ì8Ã
0Ásğ3µxû3]"pÖÖRÒ¡8 2ã_ÆZöJ„à¶Z`º.ÌàC‘†–±™‡gIÚæ+7¦¶åĞAtÎÉÁkÔqó²ùõ0:¡Óñ~æü:øËY¸ŒSUm/³š1²:vİ¿s§ğz>h§^qIzüø£«ñPy­t.ş‘M¥O&û8s·İänk…Î‰Z4­xù±0y‹¿§İ¡Ul¬ƒò)Ìé¡\Îl¬‰\Â9ãJÈİrWds‘Ğ¦±ãşD/S¯–±fâ§÷/e#²´&'UÖóK¸QPª«kñ_Œ.`N®µü„’Ù,`Ì­ÿPë,œÅG»x³EU«=	tÓ"J³~‹ˆO5†²]<G åÃ[Èşd¥g¯;$§±\(“BIrŞ0ÿO{ßÖÕÆ±­»_é_Qn±øX|	XÎÆFNXÃ`9kFjpÇºín	LŸ¿³Çy8/kó°^“?væ¥ªºª»Z³³ÖF1RİkÖmÖ¬9¿I¶îø2œ-é·ÿ#.‚Ÿ¢€Ş`‘õA §¥Åàd© G¥ u  ]H0†ªo´J?Ğ*=y–†Èâ2@e?UiF6·L±åĞcXtÍƒP¸Óü3¡½p7ÆY ®b(à y4Wşóh¬¸Àrù¼7<z¤ÕSn¯lÌqsO”¨"àÇ¿;hmR-¬6á*Ó^¯~0d9Œ…_Í3U»~aŸ\9SªlOËêêF¹< é‰E•i­®Û«Be.˜¤rm”Ğ0ĞŒót7–ª'ï°ê“÷ÕîR.Ñ¬œØgN-©…oéRô«ÕÀIÎz§}OÏV¿0•’I9î;še%Sòš™–RĞÿˆ—3RtÉ¿ì8l¿fç7xû©u³‚Ê+Îeæ]X¨éŠé>‡[7ê1ÙÏã>_¸ñ® )Ö†§?Â^§M§ßå/½ÿöº1£ràAÒøû"é+ãîïFggé¯ÉH~ÇûæZ4èàWØùQã¤»Æ‚Ò>¡*Á a]ş÷Ç8”¿Q¬Ó+é8ó³'?r*«Ëohf|MÓèâ`i&cã«NÒrÕ£\BÜ‘-ãç£,¸óÊhÌ?pä88m_t’€¾‡ªÛ°êïË"9À`Ì}ü1d
ÂùöŒ¯²ÒşÇàÉFD”¯(pã¯ğ7èvé+pµ
e­Á„”ß~$&†¾©ÈÉX‘Åz!ğ#Øù.××ğÛ¨èï¤;éËo4Kø+Bà7 ÜŞ¹û#²ğUìUĞÁ.Æ}š8Sâw‡‹ô›L:’"k@SÉ‹óÉø*³¤„¿O£nˆˆ–±Àn//GõÕ­è9\@­9şîáûÏ[p#\YÙ¬%…ÔÀ6øÆRa%­4[$Õ´ôÎ¤¼™†RÀ– ó˜î{æŞ“Y‡j%¯WÖ+&—C‹ı¬0¥RG_ğ¼T5‰¹)u¹…âQTüÌÍkjQÖY9—ª3t‚NÔíäÄÖÄÁó¢ğõ¾tR%ÔM…SS½Q}çt),oTj'´ûAwÜ­´ğ…Z/Ë_¸NsÂôBM¥©i…|ÎšØJ¸¦a¯«X|,Jï<"eR	`I(b)ŒËUzc‘FF%VÜx­%8g¦ŒHp\½®oŞUæ¬«×5êÊVÌN€;ScÊ¥}$ŸJ³$bˆgÂD1ò©t6{c×÷ñkFA˜Š,J‘Lœ/ò;¤;]fDDJ[§örÏb´’yV†L®ô‰©¾)ˆs§›—=üb¬éŒX³=SáÌôÎÙÉ‘ø†škA¡6ÅçhX+/«°EùN½·’Ü¢˜9€I&ô•Fİ7R­7VUä+òñÀÄã”oï»;©ÀW¶öUúœol%6¹0ó1Ònş4%.…YáL´•)ÈĞ(öí*á&ØsÇùüf…ûåÎ®]%HÔŒÊ›ìB&Af÷É¿öUÓ!¯¨ÀÌ™/“]ÓüuùG>QnTğ;Ş oãĞ~L'„\¤sèJò¨§Ìî´¨<+Gè‚ìx2C}?³Üm`‡üñâHäÚ52H™ñu¤ÀÍùaA×¤‰]ˆ—™‰¨ZW`#…õg£å…„îù‘¶µó=ÁÜ î;Ş$Ç@DK†ïa0ñ_$$FÄëm†xÉÓÉ Ë6Ù·i»¹¯ßHQ/—:åH§æ+<r¦h»7)·yJ'VífmŸy¤Ş¸İ3¹š/Úf	æ?ßS.hÙn‹! t0€7ÊKù¤,ØÌ}í:‘ùŠpÎ\GsÙİùsĞFÉ“°g—B%üw4ÅİÏÓqÕ4i5vß|Û*Néy9€„›˜¯Îa„šA	˜b‘ê:or¶¨+¦"UÊãºûÊ¥Z&¶s1!~xs÷“êIu1ÈT­£ ¬ÔKòY·Ü%àÆ´ôZö²YsY‡µlŞXÖ¶•µLe•¥ìtCÙÛ±“ÍšÉÂï‰tù\õ—fµŞ,'·Ş0¯4rõ¾a¯¶—Í ¡æn”K¶ñ;G
Ú2}¬¦uÚÙÙşç› eÚœ~])¾Ïaã|3g‡…ó­8ÏoßLkC?OÂG²¾&ß+5xä¬¶¹`eõ‘a–œ3‹™Ó¹rØlŞ5ê`u†ïºı˜.±ü½=˜QºİöŸógägK”é[Ş4;f…y¢œŠïI×T­r—”FÏGÍ·!a X0õQ~F¢ fH:Íò
à­ò2İ…N‡¤33’êE·]ŸóhSåbÅ°V•`M¼É ‚+
É9Ìú¢àılnWd½ì›¾oş\Ÿ=¹P²ÓUMzü0uÙ\™NøÈ´H¸šCxs»ù—´`uœm.¦±Kds.Âz]-€\2ê%ÿË‹W–2äàË—0nTÌÒˆ1ëÕÔ¤çÉ’jcPÛº>Ÿ/¥ßÒY„@KüÃz³U}KŸk)QwÈ9~ôÏ:!>ĞŠH¶OMäıõ{ÁEL¡Æ®úµµ¥*¢’x/šUš¤´»4ú† º²#ƒ¾,ª"„Ñ—ÿxÿyÉ©ªX°şäÑf­2Ót¢8#n¨Ú“ğ’…ÕÆ‹›²÷	&¿ôü”f*ëW¿VYõá"ĞvaG©ûÇG¯ËÏüo^,aJ^€ô}áycpÅÃZğT‚p?ßãšR¬I¶79ñ«(­îWUª¿*­ù¾ğ¹(ùH4ıPU´Eé¼Ï«bÌóªì1N9²ÈĞ©F¦%¹DàjıÏóØaO5K°gŒ´«ud^“ËÔgG2êAA]5Z\VvÊ-|Oà0fÜ×	Rz…€¯aoYÉÂ=Y\†‘øs¯ø+‚ÊY(Õ¦`©/ùªfÈ·V˜¯ ?–/tëÅœÔ„´€ë¶ÀÍìca¥ÇdL|)ªÛ9GR9N]*œæ'ØNR8áÙ½d@İfn•êGR-^5?“9yX.s&Ş Ä¨Bå”v€(-²–Ëov±5*vîäg·‚Ñy7Éi’~)Ê¯ı(¿şE(\ê½ÿ§¼Ëé»ôÿYsøÿÜ¨ÕîıÿÜãÎÂÿ¼Hñ?W+5ÿóqÕşi¹ù0 Ö8‹íù@ì²À?Iç|p3ŠØkÈÕ\f{!»ğÓî}xù (šV¬æ0>½äğwÍhÈ+_·ô"¸¢$ıì½¾Ô;=à…D.*Ó{Cıpé(uºD—@È2[ys}$À“5rLÈ†–Ü^‡Goï¢@©Ñ€‚Ux÷TBA¾wl3Ã‚€b- ®`ŸîÚÿ‹`Ó¯ø¢;Öá/¾z¾–ƒÀG°+”Hˆ¬ q™®ïÏFjt‹‡øSón±†İ&#ÚÅAÀÓmÓi´©,‘×1Oâœºoâl8tÅ05AôÓËµƒ0‚Ğ³<p´ˆãW_zsğ¦±ä ™M2q-C©ûdÂìä¸G‚1¦9!ãbäÛşZ´ƒ{u›4<²°‚±:>d_IJşîéçÊHğRŸ'‚I	tU¿‰’ä)3dêñ¶DsË¦%,1XíõåÅåíÈİ.â -j?›++^"£X!Ñ¥o‚œA}yÅ5¿ú*CDC7ŒÊâ¹§[[_\ó´@‡*gR~•	­+]ü¾V«'Õªø¼b:y)ğÊMl¹YZ`ÿJ%æŞäöXò‚ï‚òOÛå¿®–¿Şz¿bc6
RñÂ´0çá'ôF°'}ûàÑÌ¶*í€j]qûµVµ“üñ°˜/wÿ a&Øx}a%›ÖáŞîÑQc§½İlnÿK•#CÙh ÒÁÉnl`Í2(™å2šÎTIë(­M¨2AÀ*CŸ
›Ã¶Ó,°œ™Œ×€2ã‚>q\á$U3‘{sa…œf-tJîüŒN´YL¿s7Ò’Ì©‘3R§o¥ÌÂ¢–âdÁ½=r]ø_P©^	“ÒWÑ	]ç‚7ıÓ+„­É³+”J‹R #8ÍStÇõtô¤É#ÖU_¬méßzÃŠJCù¸Âu__\×¡²g@S¹hÁZö›*©ãÚ#t¤¬äIÖˆx	lY)‡¼óğ¤Ù`„Ì$j¯×pĞ®æG&]Íã4ÒIÚL‰#`è')ìãÙs&ïYtî@½aĞ‡4ñ”¿ilĞ—†16Ü~ä z©xÆxÀ±Y3­°d5j›“äç
x«³Å£“
Gõ|åò#‘q‡‘â]ıû©/·,€„¦/P>([`{›–)—Ë¶|Òš’©?JçO7ê¾+Ûl”ø5§)EœIî¨pj¥‹º”@ÕÁ§+aÌâŒT6“QÂ¬+×›–é;éï­—-4-,ÒÏ9Å]o®©­6ËŠªD.Ôzî5ß‰o‹FoFƒkÎ·ßM' öµn&›–±¼§ø?”¥=µèz†õ­’c Vs8+á°ûˆÏ8úÑ
qK¨­ëKt[Q‚K*\­	Ây¨.½„ñŒ·³É8€úFaoÈ¸Ğ$¡tR$oV—tG$ .y)Š'2î‡sQBJÇÑùy˜œpİ‚õ]©Tp
½øjÈ…ÿÒ‰v¡®¼É/ÜÉ¸b¶££ÿáB¹»—ÿIÃ‘Û÷ı=—ÿŸÇùßúãµÇ÷ò¿{ÿß·êÿ[š¾ËY>§£ŸWÊ×·åÊ[¤ştS|Ha<»Ş‘ü¯4‚Jö&#´Ú	ÉNBCÉ\[;Hğc †’ƒû	Y+Õİ¿)æ —˜¸ãHËï°¾çY§y®[ş—±nCª‹ƒ^WÈ—{…OÏvU®²ÈrLšÊÙ‘‚VFƒ†Wvğö\$¿"òØú?;
’hlÙn¦åØB7£õfn»Éà/ä‰'	îÏ Út8ÈoháÈ²Õ*+çÁÏ™õXõQûs)¥dá¶r…8ğ¸¤»¤³èSB‹½†~É»ƒ˜‚Rl	•ƒ±˜#‡z€¥J—Ò›Ş7ù›^ÚC—oU[Àª)^à†ÕrÍ&nÄ‡ãÖ8Oò&›¸tm_—¦Jš~‡[$üÕ"âóEš!‹´^K£Ş´¿=Şåe c”„dKñ³–.n=yè*Cê#""ãÀ½ñ'¸M	{ûÛıöÿ`Ò&ÃÓyo¼¤öRŠQĞ;¨ëú ‹I}Y,.wGÏE¹'k+Bê=H»cùœC(GSÎŠ#‚Ñ¸£¡aÿÑæ Œ@HSjÑ;ÆŠ©ë-,øÊ]]Çêöˆ¦ìiDÃˆouê·ºå-Xˆóª0åú,EñÊDñTÔ/ €%ú§Ä8°¯>„øF?ád ¡¥ç 5CN‡”É‡á%‘L­/}”¯WV+«K–dOxªjÎ5;íãC´ÒmàîS¯¥ˆ£Ob'<‚²pñşÓÎ÷B¶Opƒeè³9[-òè³2ü«;À{êf»”—sz‹U7¯·A[õù¦á7V5÷]£n^Ø}$&	íæ]«eÜÅòµñRë‹*`ï¨¥¨Ã4ÇÌ4({´/’Î=ô¸Ê ÒI¥WøTòJª]"kûæÖ˜ rLkã¼ª˜³‚J—Åë)PêfkÃ®ª%ÈÁ9¯Ú&0_6e¡nylĞÉ0ZÂ1¡Ó2?zÑøê8Š¯Â˜Æxè‡ÆÌÍ½%
kãÛ¹i1Ì;ŸD¿¨^ŒÏ€™0<yyZa’"Ú´¢nãPÆ5|HËj?T.O&ƒˆw;ÄYµg¥§â‹õx ÃÙ
]A	\./p6İ@ˆ$ˆD—œ\ıö_ÁPMœÌ¼…oÎ\ËøšwÓ¢™­9PN?!ˆğvoœdTŞõ¾-AÊåÑ$>õ²ıºü¶q1GÊZí!mør§IÂñŸšg‚D&gÁ¤7ö0ˆñ,Hv8ähNm!|»à3hÏÜµâz…N“™/Nñ‹éH’år²3–ØU—#*Å"s»òUô2ÂçPzÍô¡:_¾ijFí2¢['Í"‹/*©íZ·) ’“ŸZãáh„Û|sg1“|®N»iå#&ïƒÚşó6ëÅû‹i2]»,@B
§5V}H`¼æš¸¨K1Ä·6Íx¥ã–Šâºá(ñä%¿x‰es{[ÚÒ74ºœím¿İß\YöfV47EÆc s$:u0ŞÊÎ!gğBæèÖ+*{¶fı¶ecWÖ>Ú&·§\ee xoxY ePàQÂ®·PxZŞBéW†{D¹¡ùó»8r\©.şÃËõqı´şúz<o£Ea’ò"€tÜa¦ÑX2–ß0£¼j^PæoÀŒú§CvŠácQüASDÕ%æHâŠà ÜÃ£AÔs°;Dœö~8‡	Y(òO`Q3ï5ëÖ+„¥½PF‡mBGµŸdäÆtÜj´	/–õl”åŠŠËo<:&…»Åwñl–ãæ^]cÎ®m.²s_µ›fŠ=Ø¥ñFªQ”¹º™%±ûÛo¶¿m4Û¯öw`[lnï7àn!k#Ú-mDk\ÛGÛÍoG¾°Ò¢EÂîp	1¶tÎ—Ç»{Ò„Ï.3òw„ÂOã8ĞíØê¯ÿ:LĞêìJ¦°*“8?û»oÌú¨Uåò`Ø&_ü£ZÇ_‚ã( 6¶¢s°ÅB*İStM’t!ç¡cy6‰Tåóáğ¼Ê?m(õª-uËB9™jEĞ|1³¢ƒøc8n÷ ôA"½½¸“£mÒmTNÒ2½+¸ô•Kp93Ä„;\4Îåéã\:Î{»¯oZ–µl`J1ˆípO´)“¬x‚­¤B,„·£zŠSmG'ùøÒ‚®$AÿB›Àuö 2”1É±z¿v¿èÚ¾hŒ5³¢î§ß†cSÀâRm2ÂgwF'9ç9ãå&ÿvQP„+!úè ‡‡Ïå‹°œÚ)ÀxÑ)i4ñfc¯±İjT+ä¨ Ö@‹gV4jº+(æÊ¹ø'‹Ú)NJQ§Qšƒ éìî¦‰h#+ ª´gßü,ı|»D§–z+«òCŞfÉøß=ÎíY.ğo9:3Û¯‰ÀKßç›ıa18 Ô3ƒP¾#·Ù&™št}HXQj‰bãÕÃ±LeĞÌ¥j¬39!È¡¹å µÕ|ÕŞ{ó}ÌU°gò³ ê¡kÈd¬¬Ä#1†jä¤ 9a.½œûìYµÏœ>ù"oi!–àhà‡é×xqAMDcy­ü¹I¬ak¼…R“%¾Ù^zC¸¼’0Lvo~ÿèè•!›xÏ—ïÆ~Øç­Ä¼øH^ªmÓ°¾ìwzÃ¡Ò9!ÇÖ_I{_à‰ûl¼=eIíÏl™!Í7[4šôzşŠº×b5‹?ëx|@*˜÷óO{~»1¦N¤…ƒ<}úT”›¢pn>Ğ¸˜æh7ÅŠ×êÍuVIâ­È9rpç$äŒéŒØŒg¬z¡½0:€rg"çQçN›]ùf+JõOÂ'bî_fh4VÑ/ïø·¿ÇÑU„á#dDbd„ƒX*ÚÄÃŞ+!Pêq‰í.w¸ÀëÊËJá‘ŒÅ èRóòò²N*Á(€‰M^5ñö¡ü7@O¯U¦x\®Uj«•ÇeˆªŒƒ¸òé'¢qAK¾¼Ì0Cèš“XkôpÜÕ§‚<’mD“¶,Ø´°b3€­f”ÉL³c;2AÄÖ#úñ\Ró(l>ŞšßÓÌ	Ók`O¸Qz%©Q¾(UU_b`°5­ãÔ’éõ#ßj§X°k]Ÿ°!7°ël_]“·÷iû*¯èÌŠ5ü"ÌX´-Ü¤âó\Ë’@ÙÆ¤–Ñzöf9¨ôÖÄ2|‰0©ãÉh¼b.bÙ¨¿î:9#cgq­‰õÂ51ü¬RôÌ^0—D&AfU8³—ˆ/>ØÛ¡±¼¶ÁîÎp“•bE¿àÙŠ2õ…t‚i\‡©-,{,…7)˜!A„l²)µI$Arr^vÎ]"é~E{sîÒC-ÓšÇîÖPcxÈ‰nœHğµõõõ§_?©@œ<ì§§Àjåõc*O¢bsÒö+-?^{\Y«<ö]‰¬s¦Û«°È£,U5·\ücÒ–åq³±¹Î’a²Õı)Ò±ÇÑ1Cî!ö\b|‘iÊ1¶
&S¹vıÙ4õ¬,ÎRœçF¬qÂššuóÎO‘NĞEk¨äœÌ²¦×ÜtOe–ÓÖrù¹yš–ov¾ŸŸğFâÿ’?¹%(%)®=;-›ø¨jc Ê¢µûíî›#¡|h GŒK
éÙ¿ÈÕ`Œ‡y˜ÙÜ`®¦›:Cóô#ß–½Á¤’\™›3&ïHÈÃµÒ‰®Jè-\…‰øETN»Ïêãpa*ÃN¹pB¯®_Ò}¶u¿‹E÷¦&±C\ùa/Ä+ôei“'¾ìVAq¢Ieë"CÑBR—Iöş¬L‡Aö1`0aX/öÃËšq†ß æ;Ú.„abx½öMïñ±¯–»v^Ğ½nzÍ¢5m¶¿“‡7·–·ÇÚıúäÎ–¾DÙñÆ»MuÚ«T.#?ÁU™Kª:_¨„(Ê¥ªì‹Ô´*r/ıSgß²æÌ{ÙšB­âW® v~—V÷NsÏŞÜõVckäç¶zÉ~ˆÔà¤Û{X&ªjÀMF®H‡qñ”—P§Å1×ü­¼j €Û´hÕ+%ö€ßz‰°	o—¤×	)Ï3Ò°^Òì¨|ZƒVm¾B
!\äam'zÄ/O"ÒqBB1³sÓS°š‚<!§nG˜&NkãÍ6MkÛT§şK¾üØ:AX!ÍpD1ì¥şÈìËëíİ=¹ê­Ó÷œoóæãµïiõ†gUFZ…?Õê—*úb»g¼£î.µÄe„zŒ§°ü¤uØÅ.sYƒŞ™'J¥bÌ“pÈ‡Ê¤‘²˜x2™I=Ìñ5IŒ€şm˜
Jögc%}Î,%.Dº£Õ;V¶Œ=‰Á³iÌÓn!{Ôı;ƒq90ÄŒ›éWQnvpf¾¹¥Á –G·Û¥¥;
å£E²ÚÁ+Ğû¯%™5€§¢¬Ëƒù|›–ÈKW”Æ+kÂ°Û)°¾
<)Auqv‚Q\VkÚ¨Ça}&l?ÉoW¸"LÒ“ïˆ¾&†)/P'GYå²7j˜4g$ıv†Rê›u> âğŠ(™xTeÊÊ.Â’qBbYD÷uãMZVR÷SV¢ğ«8¶,¡hËë…+·ìgÀ
’Ë<dğÔŒUšjYî…ùT¸(n°éäHÕkt\¡ÎîºHkØ¾{ˆÚHÒA zÿHàÉ‚^ôS '”ª·”sâÏ4~ô…oYÂ?è¡Òî^Îío±©)ëüX×,îïh÷±"â•ŸÃ¬Ø5ZÂAĞ¥H_&”f	NÉ>AŠ Ã¤‚j¥e–©Ö#„ĞÄWë`ñ/5õ³cÌ_)“L>¥"–Ë™Ô–à§ÃÚùíïùÂÃ1)Íğ~0†u„½6{ûÈ¢Ü „)	¬<¬ûà'Xæxó&=z1œh“÷é¸ş;éß^o¯¶W3¹iWçÌ-JĞœ´1ÌÓ*ø¦ëµe#Ó–k6fCİ*uíFõS¡È3l™Qí´lEK¥“{%ÙÎë­ÓUXÑ::¢ÌïBt6å4ÜfÓ(a‡KR¨Û5¡ìgEZZ&gÄgÆU—+˜
eOëL¯˜ñpçLhªJ†ĞÎ['ş–P+8£ƒU@Q¦šíÉH“=1ğÿBè÷YdŠØV:ÀwHË@ª|íîæS¡/ic´½ór<<î†$ëFkR¿½á9ó=fÒğV|p9c`³åKªŸÌæÁ,½2¦‡6 /ôÔ<‹1Ìøj¶İ>1U»E©ä†§P",væná{…z~?Ş¿‡¼ƒÅÉ=ÙXYø#pr–
Û™¶bz38÷]0‚YV©`ßçåù¨Ûå,xµ|§–˜y¼¸{Vp´°æÀuvìÂCê6¶à‚cvÚ®\š¹-ËB)ÄRRo*3ã¾Ye±™mãF;)ÌîÉCŞVNÈTïh·p|‰3Áö({`\¯¯©¿]’g
|M¿Ï–bs°©‹pöQ'µõÄ‡‡]
‹Æ’$7˜!Ç&s`ìH`‰,®Ìªochy4)€¥Y5…ÕS kR,ó7Ua^Ûà9ú^é
£3Âl*—±¸·ûj÷¨½ıêÊhïì4à]
`‡1_åšÃäüÜ‘pQ%qKÉ¸†©—Ò5®N#¡(OCØ‰DÃAÛq†ÿz]­ATŒ´+³Õxn^ka¥¼ÜúA40f¸ç<ÿÈ<„Ì½˜óñ²'_îlË+GBpÏÅ”2â8—hO” çPFGg«4Ò@¦©”aúİçcwÍÚ@QEÛéŒİv»‹­D·	Éxx(¥”SN§ÌÙäEÎS/wLSüJgşá0¿’~sGƒë`øü/ŒÿY!È<ÃõÂ/âÿçéãÇøŸø}#çÿgõŞÿÏ=şçµñ?‹üıtœ(<İÇÅS?"ˆÏ'äà§âGu¶iØT.¢‹`È
™½rW»p‰©¶ĞíO™k+¨„,{8(C{‡eí5(ˆï”Q0¥–K;mÏòŠ@ÿšè0Nt€Åá…Æ°½¾:Ø?l6÷şBR %^Ø~{ĞÜi½£¯¯ğ;±è˜³0E™áÀ°àº_.}Fˆ¼b(Ş”á6Œ
åòo9F½K-âgä‰/(#ëÊ“%0Q?C[?‹z]”Š÷†¥Ñ!ôƒ48&«üßh±epO)—ev†èÓî”ßI¸P”_‹"’
3|şåkå¨T¯_çQõLÙÿ©€!¬É8¹cüçÚÓõÇk9ügºßÿï÷ÿ›â??vá?}Ñm:ÓçÄ€v$Ö‰q|8pÉ¹|£J^{Ãø(Œû¼èÀ=®j‹K'á»ÚÖúZIElïo7{µ
qëi\ëø%\x¿ÛŞÁèü¦ñms÷Hf©¥É•f‹®Æ×¶Ê¤dVÂí¿ïé6ÒpÖ‘‘Í„`/•¶UÇıofÊ]NRÁ‹X*PXG†öÍë ­Ö¥Oƒ+uF'æ†)Î¢8?ZG‡à¤®œZvSgWjEMYñleH^@ı|ÿß©È_ñôDÊìüé‹Rs{÷¯bç ÆîånãÍQƒ'œ§®À\#«g^’M#cÒêûB³Sà;ß¶w¶¶Û;»ÍVİpÀ¼i¸Ræ€œæ‹é{N©ŠOË<ù¶±÷
i±ì-ÀĞËiûÙ^NqŒ=Ü%ÿd|2>^†1Y¸ïƒ(ì‰ƒìVQ TÁO¥ôV<nË‰Z‡‡T÷Éø¡šıš’aÀ1¡PŠÚ“Êê†Ø;jå"e#øi|f2D:C©th‚"ùNãåîö›öëæL’7;uÿ|€¸á*Z‚‚àÓ‰á7^SÔ
•ï—F¨O³¾jfÙÛ})Ñç(ÿ{”{6~0kÈcB({ øó6¬­ãá–Ò§î9ò‚qœv­ïW¼íÃ£öÁá‘Q uæ“:ü W:“ 29ëcO“ hëµµgJÍ,nÓÄVJ)¬Ü4eĞIì¦¶cSÌİtÙÒˆç¥Î4L±ÊNMâ ©ï9måTj•šG†lS[ß2‹^{ÆE¨R+ŞT¨¥©Ñ
å‹9Ñ„Ô¢– ))Ï£ñ‡É)ÑñÇş(ö$˜WÁ›Ó†Üp
 ¬?¿ÉWL§	©sİ††°Óµww*ÕGh”¯QÀSAÀÇr"Ås€®æ¸,¸§}ß:Ü~e•h´r'¼ 3åÑDQI¿¤‹Åj2
:¡ÙXà
qÕjq¾/û7Çíİ£Æ¾•Ş}&Tƒ>JĞ›sbU‘[„ï¦Ï	ÏÉ†½¼QÙÀ	*Séy'ƒÒ•3Àét^30‡>€ï¶pxüøÓ*¿îOO+û…;¬{0+LRšV§V¦2¡nqN˜ê&%©rZÆ+i8œÉğà>Ümè›º¯œ^¬±>SS'İ%*«•|tnÑ&ƒÊY†£ 	D= ª¬¤:Îãí‘Kùì{Yï":hÖok×Hqm!0RoùçPb.ujíg¤íe‘kù|FM4, VyV¡Œ’€°İÙÏ¿pxQKš­V{»¹¯Â­Mr‰ RYeß
é‹Fâ}ux,€ê¨ÂyĞÒ¿¤º;Ôeçcß½öñò™0·ãşÅÓÀŠG;l6^ïşPG®q	®€FÓ0½³qs·Á«æj_A{€ØlÄcÃúå2À[G3‹n·<â—­Ù@0êHnŸÂâ¶†ñÙHqH‹ªôF	ï1êñU™Ÿ¢ÊŒ|í:yPä&ç
ğMu{Cöo«ÉògšŠnÔà/Ù^t	$mª¤ƒ úõ‡jãY§§§€ñ½}ûÄ„= Ôl|ÛøAüy»¹‹[FËóŞ6ÛÖ9êcˆué„ "ïÈèUšö=åì:ï—r›`Ò°ñG§Ÿjµr7¼ Nåô|üv(ı¸ÇQôétrfv‚(®©_°FÎ‡µ4öÓ8«ïÁø£sş¡SV5áÙpŞ›Œ×Óoî{)¶uİï‡ƒ	©!dT29½`q“èCÁCü "ZÃ-Í¿Ù^}2ˆƒX›~3÷tOÅ9üOv÷P»ˆYñ\®-h+)	©ÇTğ!TÈ»‰íÃ¡*Óç±Ğñ›äVp‹ÁpPÆ>û²°2ªßR°Q¿{÷^ßLóªîy}mrù!ÊDºuvaš½İŞ=ª¯¡¹½5Ï¤F„Gœ*½C a“+tn»Éwk[¦~W£“q6,*¼S+yŸZs‘°i§ñùİp”‰â
ÒÌÇ	§c7Õİ>M`×›V1õ#ß¦Y8„&A]V^è sùë?T%ù.q«Íç˜Â
sU4'mÁ†ªRÌòëßfWg<íÕw4?¢û`¥¯BÕ)±L`;(«EÛ@H§epD=”Á
˜œ°`Wf·†¦ZÃ|v\[ÛQ£æ,ŸŸµŠjiÒ˜i˜àåJûW¡&ÍD¹w›Öè„NÇôÜ\İz\E3faı!a:tøšı`ñ™5À°É¼T63K%Û‘[xÆºs?êÕøİAëÈH-uô›ãı—fv­&¾›ÁÊÌµd7I¸­VjO*5U
”dÇ'ƒ´/o†c¬ÃôÙ]ÿõâå•¶ñÄé-Ç‹u¬/rI‚á“„^(FÚ%Á#tîM£%B›ƒBè˜ÍD‡hAzªŒ»»µı›Ø=ÃTèŸ·‡öWfvZ„(*ÇJÍåN*Mªg,ŠÌ#’yæZÕ§Ş1Ôé@£¬°ºš‚°E{ç¾»Àµº/eIò„ƒÓîš_WGqˆ‡2º8JeYxÕ.{¥DÙ:>DÁø®Íl¶nE.Ë¾Yù†bwsVÍûèŒ›ÒÒ^•Ô½/»‹øïæ¢“4ºı…º®)ÿÚ&ä%Ö†óL :9ƒAçrÛÑ'à³×ñ>+Ì-Ğæ¸8G6~h¼*5l.êN_Rö¥Ì8òqFİ7Ú®°âG}íY62Ş¢XØËÖumnèŠúÒÚSL¦ï²ç–å¢öZõZíH]Ÿ{_ß3ô?´¢óİêÿÕÖ¯¯çôÿÖ7îõ?îõ?fèÜXÄ˜ê7ÓaõãD"s8“Š!½Èß‰J?¨È÷/¸ïÑ»«Ó".Œû÷ì®ğğ³ç±ÏIîÊfé’ùód@ òá œ %È<y,Wîó¶
=ú¡ºgR»ø:o^bX¨'+ôJm‹•<h¥ÛcÏ3¡ÉzaAÔó§hT·q ¥©p†‰^´+“a
m# †ı2 ŸEiUèP’ò-,”j’y¥¤kf8%†[[iB­öBÚ,º„!X¦?û!Y”¸BøSÂÌÑè2&·tåšiI†Vínˆj]T<M‰ñÎÎl»ø‹fF‡“tŠyQ©T„VšŠr|aÇ¨‚¤)´ÆP-d.òz*540­¨‚ø<©//>\É‚bDÕ¦äĞi‚[,¥e@&ó«]E«xé‡î›ã;ì¥ºd‘£ü=k„ì[h(“øˆìe/¨ƒ8C?†RÜ¦Íæ7a+†Ü0m•5Wœ±«k¼·åyôÍ¢B6•¶Ñ~²Bôë¦=´*êsu4ê|z"ÁlX‘vîæ ıÙ^ö¤f•©dŞ²ëD99Ë›¦eœ‡»Q¢wõP¿AÚ4)Æ'yŠÂÑŠÌ¾eDk6Å|ÕçáÊû	5ƒÛÁé¤Qöi/”„pÃÆ«òMw‹Œ#Iá¥pï­¸È‘c2‰õ=ˆĞ¨é’×¢2øY(ÑnNºŒßM¢TÎh­Ot†ëxóC·¸ÖzE±ÑO\0½.ç2DS!NçÌÂD¦®¤ãáp¬_›ms2½µh?1ä+¢ƒxæ"LIøò@°pËË¿6©ï©Ê½Û_\ÆmUâ[¹{H“×ëìÂ¸—sn+Qo²Á%.AÄ!Íw8’¸~û¿İ€ÌÆÇpŠÇd4.í™‰Fg„Ä	Ì»i_F²bN´
ğà­#1@jçc‚½£yg”™éH*¿\–O1òq%
ñâ«5P‹²ÁTÒ(wş´-3TnƒƒÁÕå‡0õÚÌVäËâ“^„®ç2Î[ÛØÇ›Œ%ogW>¦ç êœªÈ–“*¶ïtd×Ä¢~I¬{7‚zûğÔ®R­OøukØû_¤0E¼ö7Í´HK¥­H[’z.ëñ­Ô˜5ÛA1»‡©#'Ú™’ãô.Z=Ôm¿q'Ez4+òœiì–îß16Q™Uù[Œ%gY–bX†}~’æÉ'cÎ"<hÙ(§˜Í‹¥–J×·s»Bõàt|\ÚÇxàø_ Zo‡à)ì¤š:zsjq/Bh¾''´@
Öº*‰›C÷ñDÁ³7¿a£z¼—ÏOà øåõëiÚ@É™®9<#‹­Œûäu™ˆV,æN¦x,Sàa¥K`)ËY³X\‹bñIe»c'Æ®O™õ·:Á(LZc˜çpLE1=ÁœMzt¿Ÿğ–;†ËùË`ùÀ!á~ä‘Ë-òA}9ä1k®	¥S±¸¶Ç÷#[]fØÚ®À×¯}T“¶º&ŞÇ½ÄTNóE3»¶f#şÈ™fl!
;–¼§·L{s½y‘Äò.PG±ŸÆ‹QÉÕSÍ«¹zš¡°Ûéj€ÎİK›iánêÜNÕ!½åÀGQ{kñæJKƒHcN) Åˆ³NÃt®Ñ¹µ2'#Fö6Rï#çŠ(ô áòÄãÑNè>ğ#ÿÍIvíÉ—Ar`“Íî‹è‹=B‚-¢¶—è:EØ×ğ‹:-+'Ô´i«$ÇhíDÓõÁâ7>}Š¨\ƒğ¡I.‚ì•°oJq/_yÌyrJRRùÖÒX²úØ(HªS¢N‚¿"¬mV«ÑV)ä,|hïÅšß@£aSQ¶àv1W–äÁ%:5”&AÇû'yÿé;Iõ‹Ö1ÿ?™÷ŸZíÉÆ¿‰Ç÷ï?w5şpäWÿHãÿtıéıøßñø›*Ow9şë«ëµìûïzíşı÷nÆÿÄG	Õ•ÓñBcaLT¾³-¥Ÿ	ŸUÅöä\Ôù‚,ráVç'©RõéVyú^¥õx³½ßğluºt<Ì(xR–Öî›ƒÃÖnË³[s{
fwrö’¥I'gÍ÷ôóà¶ğ7æ^8Ã•È™†Ë¥4™,hs{ü-0nEYõıK·ê¤|Âœb>„yG+<½ƒYÁÆ•Å
'Lê
Ğn§ÑzÕÜ¥ÆzYùc }>÷¢{û{Ô‹>†bûğè"×ôñ•Õ@|¤½YĞ†e(]L›
Î©Î²–2(ÍÁ}²qoÙé16TÒ×ËĞKH~_HeÕKJ,©ïeH)Ä‚N-2U•ipœtkºŞ­™WWPU¤ğJBs6“YC†i´¤Í<<'j@!×ŸršÏ©¿ö)ŠÏ½ÈT|&‚±l^‘Í¡’òïùåLğ^¨&%a™Xllê	b0€õjU8^f(TªÓR×¤­k±:´hËóhÑÊiÍKN'<ã 2Û@XÉä-©®™:K™pf‰.3²²‚Ìî'pcD0EÉë¯pë¡îT°é\ë
ÁÈj‹3¥İZ™:-o—UOtü^0A­Ä8m&
ê&%ñ¯@•G"Ap©+eR ÔE‚°ùp?£Õv|ôİAÓËÂ,w) =l×şãÃp7Åš:¯xŞ¿İşgèÿÿ§Ü	ÀD“J¿{‡øO«ëë«süßú=şßİèÿÙ”M­”Şˆ5Ô°GÑ İaI&àt8‹Ax)ÎÂ`Lúpx
ŸsHúÈÏ» Å<à:ãái?¤–‡ŠòÏG/¼…çÉ8Î_¼i¼mm>¯Ê_>éÁ¿Ï{Ñ‹]|¤êN:(¨6­û%6Åó°ÿÂB?ƒ}u2ª$W!æy
ål/ÜÈé¢áZ2AÇªİ>lª¸c&fú×:^ùÄ5¶rbŸT5jAIEf}^Å–?¯Bç¸ókĞùf]º†£qØ?E.ºˆ
¯whìa›¬ÿ¥ L³¶…luÀ#QûúÔFXx(¥²j’B1sd<nÑÔb ”³4±öÌ•ˆˆÈ|D°Š¹™ê/ˆK< öj8
ê5=ÆrØäÜGNQ3O‹Î;ãÔ¤Ô8bÀôÑkĞ\“ä|yÆĞA™bH˜s…p®!ÉóÓ¤ïZSˆ‰Õ‘ÛªD| >#R°‹g–Şù­#zã…b–©+fûxD^k»¨‰’
iX²ÇÄ™’pyËÊ}ÓvsÿâiU÷õòAm|æÄ[3#˜çµ·+öÑ“Äy˜d—:Òİ’Î3ıå4 ÛNjÙ×Ô–}ÖŒ¾ş”@jÍv3¥nòK«öqÄWÀÒq¸æÂ*ŒĞ~p|²1æ
Çü@FmBk€ÙV_6lu&\UÕB¢Êwî‰‚°˜ø	{zEŸÄñ@oè² 4T±ım“ÎÑCÙ+ÅıüN{ÏÆİ‚üï¶¹¾¹ù¿õ§O3üßÚÚÓ{ùß|>üjpšŒ¶ÌMvg¹¶ÂÂü‰|ü¿_©D‚ód™ú>ô¼‡QŒßp¯“ÆÏGq¨È}=Ÿ"fTeT©Şb>T‚ÇÙeĞx‹"IŞ¢6B–»èğ}#Å0iÔÔÚnœO¤9µÈÍh-ON32§NÕ|oL%’‚I»”¯å»•.CÖi˜üÜ¦ü3# %¶á÷ˆ@U¤0nöŒ+9!,‰éÛ•ä$™¿†ìà›i
„­SÊÌ”y
´æEŒ •Íà˜š
‹¡@b[T’ksš)b\!,hÊ(Qn¡,W¬Ì|K¼{İİJ¸EÀf×”hÖè˜ABÖ¦QR,œ&À;vÊïÙMÑÒb;XÉ§m¤7 ›ˆ"İ?H$;›~Jè¬º(3¦$¸eù³{Êµ˜FE”EBKd]Ô“é¹û¯$ÚîÙŠ2n&òõİRÒ-Eİ³dİ\#n«$ï†Je‹œx¾âşæ ùÿ!¡uq<“2
ùnñ:0ƒÿ_[}š}ÿ¼¶ñøÿ¿ùïÁ˜V=œÊÿ9	crT’ˆ’-œÆ/C(	mJ/¾>wı0äõx6ìõ†—xg¡´H–Û…{b|5
ëş®¯¤ QC’8aŠeâ4´öú
$JÆa÷†çø‡gN ^^ìj­ÓR¯¦[NY‹ª§½á)Ü}¡Ì¸Úllïì7`Úû/Ô6ÇAz—{^^øğì,êDPÄUª’]±ÄSÒÈ'êEã+–AÒ
surSgÔ”	ˆ2,³a™LUHpñ—Aıç­sÇ(FÂô…ƒ?í|ÿLl› X²Õ(¸‘8Ğp¡ÄE®?v?–Ÿ•á_m`‰²»C–İµÈxoŞ²?O•øë?Ä¯³Š=&Ùl/²èqˆ,:B˜u‰ƒ. qĞš ‘•]'É:5OT:$ˆîÄ$"zE4—¢(ÚÄÜ»ã¥Ä:Ò“aM’‰¸ôx“Ğ šOLö¸Vtƒ‘Á7mS7P( ½:$Y™üÓ’B<|~‰ÑÒ"3=7jzÕâT=¡B¯.8î¨A‘†gz¦>°DÔi!G$·,JÍ-”ç«¸¾ÿÜî?÷ŸûÏıçşsÿ¹ÿÜî?÷ŸûÏıçşsÿù'ùü¬@¢ş h 