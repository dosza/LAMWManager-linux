#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="935404052"
MD5="5b80b7bc75975282c8272c4d0ec4d54b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23816"
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
	echo Date of packaging: Sun Sep 19 00:26:57 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\Ç] ¼}•À1Dd]‡Á›PætİDõüÚ4©¼0yèèt|¤?
~¤ÅQãâpÉEùøR×N=Ñ¶¯'ãáWû–‰×÷àìœÃ1²ÍgB«íéåìÔÊª„(=éx~+lÉPê˜—ÓÒjN²®·@}gmƒøò¯>İuãÄ—O„P2ÌŒaCÀHp>µÇcÁ±_€­¸b™Y‘Q¹d»¶q
¢¾¹¬ßC9Jû—ıŸ¡€M‹+æ*¤³—eÿÛ­Ü[Şqø hÃ_º‹[H@ã^ÅG‰±3İôÕ#X[Úw|)$î¶ÎîA({‹¬+'ÆÒ=@ºíÎz?6µä`'Êeıì­MŞÀZ¸ê¾§5ú‹PºÀ‡æNâ8ºÊMõrÜü—¸ğ£±…o€±Õ«jA¤¦V*š½X”¼ßš}ùìÎ/ôù¨Vz}c«±avyÍ’È>$›¼Dgš¦­ãøl\ÕÀo-m—P\Ãô7äú÷€6ÆÔE£eûû€½7µ„0š¾ĞşÛG#%¾'qb|4ÈƒÊ°a–óœ-şˆ¤-.pbÏ‡Úü|(õD"Äh­z:ÑVQbQASİÖJÍ{f¤Á²¢‹¿OÓÇóí¡oÜĞöé2ßi¡Š¿š\­ÖAÓ½ƒ²¾Ï³ku –Éû“2¿tëvîßé±ªÜI¤”0~²³\ò¥Ôñºñ„&½–HÙ¡HÃ^‘ùûšô÷{B™!3±R”IzÍTWÆíÆmMaQÙ(f(â÷‡j¨†aÕÒupo‹	Şnfä77„¨Yá¢íá3·tr¥äåñÏu!÷=ÉËh¾¾ºŸ<š|…§YÉœF?G¾j^Sşãöé`y()ó›)2ê°ËO\ıíì2z'½s3>[¸Úk8EPp¹±rD~_•áHØ¯åqi*œ7‹İ½¾©[ª¹c…Ä8&ÎÈó5}‚Ü)CY‹%Š|5@ÕÄôµ†0WèP|öc‘‹§î»–ş’ş?•Zrç€!ön›ª+ ï
Lß:©ÊõÀåÏn§0yêÉ+}p±rŠ˜¡!ËàÉ½”K#KBl‘¹®ó–"ÛÃMq2vÿ“u(}ï‘eà…Twœ¤àCœ}@{5û¥~$xÑP–1fgØœöL€+¸ôj«¶.@qÂ˜Å4¶»4t}(ğkeMn•©VñtŠ0@`dMèöQÚj.³ğA
yŒœ»òB«nç,ÅŒ µªŒıx]ÉÏ9L«N3ûöŠÀİÉ‰¦±‘WØ8‘í%I0B-Ÿ_Û½8>­OFÇ– axëÄ*¨»ìíñZYË˜Æ`1PpÎÊşÎÇÌoœ ZÔ®€c	r¢âîÿ…²õAƒÇŸeî¨$#ÏEC±UÍÕOEæ2.‡?I¯4ãß…9÷*Ë}M€›Õ]B÷‡Ù¼iòÿ	gÜE™´ø|ŠQ°]ÿ³K‡Ğø
*t’³®_<Z†"Ó­Ñop
‰HXSâ*hÑJ}¬èaÓ¤V’Ë¿ˆæáè™qx¬0êªÆo¼…0üËâkÎê%Îı	M”±ë¸s,O?ØÔjp…à”× ¨?e³E» R9^MØRA~D<¿5^L°ì–zhQ'ÄÌâ#$[=çœèÇ¦b“ş½ñS„¾è8Dám…°„®êR"ĞŠ£ô”Nìô++'à>Í6È–ëy‰6 Q5g(y§nô«Ï'ï{ûÜHœ{ÖBIg´ó’LE†¢ÿ“D”ÒIpCY¾Ï6á¤b ¿©äØŞ ‚,N	½txÎKó%ÈáHĞù”
J½ÓçpıvÉ•÷Q·(óäÎ¨)I>@|?‡^y™l¥óÄA›L0Z·n0J@l7A0×ôúŒFIrO‚ÍBëÃSHĞÑ +O6à 
 ÄQ¿çŠ_ĞPÈ…ZCNµVp§˜«Ûs§†l`÷XAbš7UÆlİhŠ	ı6FµY‡2€ Cv¹Á¯`ÊU'=¹ÿË#Qo:^XgŸ ®Á<H8ŒÑ‹;{HŞÙñ-H†°Ú»"ğhÜŒ/ô.Ëú»-"Ã<ÅbŒ™jl…×èÊÑJò§–|ÂÔê2R¤9bÀôIÎPB´-Æ!·XEk)Ôn9Vè²èşê9\uoïşÛ®á†CYƒ941Ï+ÉÖæPuùÔqÄœ×ş¹…Nªªt1“ÍÂî4Q0´Y Vô§.èR’6m®Ú–ÔEê<tÀÄXµÆçÌä$÷yuzv ¨
²0dÆæ=UTÄi®„»Å6÷‹c|†°nî“°Œÿ:ÒèWt””Mì,cÜ¯‰$±Ùa[N E
"Ş×ŒğÏ2YÉ¿_m[GÜ“¦]DGø$ê€İó'°ê ,Tñb¦ô0,FJç£ZÚ¯÷k˜G:ôc6 Ä¦âJëE*ö`Z¼ıòùåeĞlzÚeD|”Ãş
Œ`¸ÃPXáÕH|ËÇ‘Õ·@ã°*òÆò±Ø?è¯ ‹`[sßjµYÃcD`ˆDª¿,×!ÌÃÙİ[Ş™ğºŒ™wú¹)v³$ww”‡Deò%.2‰q`©¤»&£ÿú)Ù «‚`dâ"%ƒŞ™ôÁmb³d”\|>0{.9rËÑùrm(:KšF“&˜òPfÿ I¿¨_cĞlÆòÇ„‹Å³	£CNÁ[§O“~ojv#š‰™©Cz›ø3€	~¾ÃªĞ)Ô==İ!plˆ…üŸ0ZæSÇ”|0Ş  €¥/AH’µ3›øõk3êÎ@Y(0Ì"÷NÇjñIô5O/·ì-’áş&b²i°}„x6ëÒfè	®Î×œuû%L˜]ÅÆ"¾+<T)“´kqÅ¯Ó¿Æ¡h[LNÜÈ±-ëz®¯X…4z‡-€úØÊ|Ë¡û­ÀûîÔÁõ.¤ ?3ïñj˜›Ê9[UGkÒp¼ì¢@ÊÉ±É"_z55Ax‘=3	<0$5bËÛŸËüÑcc&ş)ò¢Gş…Æj*Ş¿NŠjÒãº<ÆfÔövb6tmQ·«Cûí Ò³cÛöòøª~Òå$*IÍ©áh_ÍM æYaÒ^ÙNWï†¢O£ªÆÏÿí4öY<‹€âà'È–N´ï¼ŸBˆIÄTÇ÷«ìJÀ:Ñˆ—Ó­Ò±êó<²ÒàÆx7Y!MB($‰€q?#¡|håI{Ö ïÙSÏs@–	xíMııÈÀ3Œ5§#ÔLª°ù;?9Aäa%KR`Íga`o0")…NOdsQ	rÜ.ë¤—Çm"ˆes­GË¸Vù›ßîÚ`+ ëM§[.»CçµÇÕ#q­¨(£\ËXxë'& Ï­ŠİGõCP~ñ\&é[ÇhÙrD«X¹d’ö1¼m~o9U;?
²CÀ’MV¼¹;õ
ø]B¨´)G:Ğ-µ&æ p„4-®K»#/Q3Ô¿±º›¸—ä†ö²”<ŠãáaP·ûêÂ>Ë¤$E\Á<½ÇeÆĞ±Ğğ]"QH;Wr¤}r#°\jØ0Î"½	‰s§A”Ä ×Q9ù¤l'cÂiL.ºñ¥ì˜ÒzYC.\!}uB¤NöK¼EÅ ¯É®
7ĞÏ.;S eˆÀÃ‚Î>ÛD1ğPÅ¹·–'é?¡”¡éXKAÙR?ğÂXXŞõwˆ)^ !+ÔÔ¡ĞÀ|@ö ÆÜı;w„ü*úh"O]>ÆÄûM*Áâ¹r
Õ!?çQj È®Òu‰PÁ='0@«º#ˆ—®Ì+1¹8~Ò!š"Öş9¬ƒÅîMÊÒ¦ í1<vòÍ+‚ªtÄÛ†Eê°šƒ €<šºVDO4šúúÍTª‚zm†p‹Ñ…	ìøª³‚„Aÿ7 s¬`'šRI$uEnÿ±7ƒQüy²¿@à…[¸Í ÜúÃ†F× \ K›RmÄvï–¸Ãƒ«tÖÓõÏËNÆF@¿ïW°1£ÊÉíl-CUfÁĞrAo¿“fñÑ»°©êXÌBRñ¥ƒ¯Ó>Œ>çáhı\†ÆüJÁß½=mFyg« v{Æôl¤To 1t'‹oGxşZëØ^İl‘Å„Tb;P6KxTîK‘(Ñ|×Evmëú‰C”íÊÖçåyevxf+k¼ğ2`1‚dÄIÒş×?*~¿°ŸTDå
i»,×Š²H$ÿ6Öh^óÕŒlmx¬	?E-fÒÑÆÄºuJ/Ï…‚ñ úpXqÊÃ~Ñ™y’·tï<s?êÈ/‚+Î_aŸÁ­Äu¡l.jWÊß„A}¢uYwQdé¬âéñ„¨*û U\ckñ/TáIÛš¼EzÖ©ßMVOÀ®àóçıÌq8bIg¨›[<*Ä*ù•t©ŸÈ,¼½ä8ic‰ö	ôˆ4‹ø@¿î¼ Í³“$îË™w¡Ô¤¹P5·bÅAãÙ|4Zšo›a™~?ìı:âi~—˜À¼úÕ	±2¶áÓñ]ˆä¾<2ú¶%µµÛ:Ø¿a_;‘ŠãLÕŞ-‡Yd]×•RÎ¢xV-Â¯}a£ª«›¸++ŠHø¿rcğÊTÈ¾@ïr„™LYâ–s¿Ù1+©Óh|î…æ™Æ#H%>2QÑWëxdêĞ.ƒË|¤{Wxù‡k‹f†UíÇ;=EA§şºá‰µ[Óëe5ĞcXÈy@¾·‘7hpÇ†ŞÕº²ã6•ÜßŞFH¢O$õ™û€]oµBÚAŠ‹gİÍ‚ş~ä’)±–¿³8;&¢JhXƒ¢K„iz/2Û±†ÈseeğÓfàQÂY¹6×æbf¹>ÚÑ†HÖƒÆ®m”-òî ÆĞJ“’Ë$dhĞ`Ğ3«ı§Y!Ğ´oLüõW~vŠe€€Ö·½oÎ{Úğµ€z8`ÄÂ£ä…&Œao•MM3X[”¨õaÕn”Ó^øĞ®ÏOÀÕïËz« Æ¿f»ó9»éªØ€6âåÍ¥;V.™eoqm…à/T#7ß3ÔÓ stËÒ.ê wm?½Ò=€7T/`²KldN×^ ¾sZŠ¤;å–Ñ@³‡-ãW½ñÛ{“7ã7K´¨…¦Ò˜öÃÚæOpDÌ¢a¢]PÖ{†X	ú0»]WÂÎ/´g×‚Y‚Â‘™}¡£æô'¯wŞ†#&ÌpcaÜÑÃ«U$9O»\ÊİQ§CwwzVŒ?¬µfÜZÊÓˆ7š|=³ê†=ÆˆrÖí†Õö=C¾S’DŸst\‡‚Âî!	!^æ´ûÎêd¯"ºš›šºK<-ì“‘j	U¨úüÌ'âU|h&ĞüÄzqÙÏeè…–ññ¡”oà¨Q5<'®  £.±^Bï&ÅêŒ¥˜—Ë9]ëøèÏ—`¨¶a@#Ì¼¯eÜ+HÓ<ë¨Š”Î(÷äPù’*Òê•]åt(#†„ÈVp÷™)"úØ):|ïÎŠü[&Â7´=pÁÙm°%îòPa$´e÷¾¢‰öVõ×Ş3CÈû+`?9×lñ‹¡±¾šS? m
Èœõ’\tÕJ
1n"§©Ÿ!ë¨mØŠå&O:.“ï¤sZĞ1&Â3|s¨ê¨Ğü¥¤I)#´QôÇ­~ÆÊåÉ¼®¿Sà‹ÌñÉ(iÉøùê 2gïNù‡mHXF¡£ê†­ğ}şâÑœş½ƒ»§ıy¯É?1¨öK®ç÷é!½;ªÌ¿¬@‚ß^.Ge`¥İ5*éÎv‰£—g-+¯…W¹%/nûÇÈ°»ó—¢‹Šıå^¤Î©P­Õ"k:­Ä:/Ç¾™D„Úêü!0H(/7bèÖtù¡j¸ŸD#ÃßÜpĞ+k¦¡Êf¶E	>•P8ÂW/ZÄCÃêE»¼»Ø\¾/Ä$ãñ˜Kº èŞ¾I ÈÄ-ÀuñÍMÅsD_°²ÎŒ’‚‰¨]m1ü«ì“4CBÓtı“IxÏ7±L6]KuÆ_®ÿÛj6`B^`"yÎ\lsØÎˆl2^nÁó.1y_¢“”ˆØÿ ßÔ^YKof=•ß™•“¶2K¤ìÒúhü‚Ë“|÷HQ~wš#øÏ0€	$Øœ2gñÁèA1¾±f¾?<™/y‹[‹!•ı‡;ñUÏ¹M/Y]ã*.‘—1r¨ÃqóÉ…Ôn»_&_tt={&¶Ipôyëì³l"B¢y%#…¤ƒYòLë€/ÛúRSiFeS*•k4?Ò²µJ¾7v_ÎÌn²ËğÔ•
@ä\õÛhŒ`Š¥l•‹ÿ
õ8l¸¨1xã[O¸%±Q~¤¨ûGoíGÊh:lnÄHiğŞQ›…†ğk¶š{_™h½~>.df?$‚e=! tøJâ+…¹tG¸úÎöìÖ’;ì¦Ùò©}°)İİæ;Íç(0/kš‡şCÂÿús@À‡Ül&½«ÏAÃÆ ÇeÜ˜XàÖ~§h g:6ÔÇ‚s¬ßÕÂ6ë;9-Pìˆljç‚_ÃW:‘İW+_Ë†‡OÁ;€YM¤+†¹l® ïÅf€n;#µğˆ~“¢Ô\o'UìúF-^
ÈÍñ=Ú.ó°şÇwoJ"£]r Í·’èÙ£«’µ7SWw”¶\OM´°ÁFıı¬I©Ú5ğ?Î]Tü-ÇÓgäç3„ª½³&<: ÓÆ¿ÁZQ´ÒşîÃ”¿
ı¢ö±Õ>Šr^Õş?2$<Û¯´PF!FBŠq¡?Œö|áëTO~Ûîó0‡Ï1qÛs,Î—‡-¡ÜØ./°n2b´ûİäÉu·¢r’oè#eæÿ“›—‰TÃ+Tºñ‚v×pX©ÃHgåÉ*ÕwB%C0í¬«ÉöÕ”}ú·â´“»CLm1 şíh¬	›¶²ªF¾ñÿã½ö¹?[úbû„6#BL—lBÌrÎvfóiQ!MªÏ?Ò5wLå’³Qmr‹N˜©,º7İTFH5ù‰Q+:Gëò:ó¿ƒü-UØ¡™0[	f"u&¡i}˜“OØÃ÷™FCiáÕ+Ë	ŠŠ!,lj‘F€©˜KÂ$Î=ØÏÂ„1²õã,´÷ùMYÆá•0sN¬",´‡"ßNÿ9»ı<cõóm·‹¾Ù0Ew÷qŒIµ}†µ í±I«:0Öıù¸“fg_“2ö(ê©¯1b;ëYZ’# ^yá‰±æÆ†u#?Á¹½*¦sÅy^*W+é´e­—.;¥`PÍöçiÅqØKáÄcH{\Y÷¬3å“
[ĞO°Ê!íPîÔ¹ïƒ±Ôq&„¥Örç!ş6jÔÄ©\yÂğ;3`ëZŞò_jœø^¶ÚQÕİ5êOğgÙèzóŒÍ'ÿ³®Èx”Ñ„ÛUn×fî9¿MÆŒMJs;·U£§F&vË¹‰®#CƒegdD"§l`j¡sÊ¡“ö÷gã [BÕÍÍÿh ö}îxU‰ÆÂ¥û˜ãæŞ‰®›ÙëèëGÓg¯Á"ıªqïo$ë—ŸâDlkE.½¢¯;PøifÆ£Ö*9-¾q—ƒs‚Gqû¥şKYêódÚÈÙ‚Ş<´|JÑªÿUsQ%@X1í$£›§¯#_+ˆ¤#ÿ¶¤5íÙºÅ<Éäwu_ÕnÅô¦{*ù"ï¦u—G¼ÒñCÿQNnŒ;pF+˜Fİ6¥>ˆ¾À=y’ƒşñÅä¯ Ea+iRËijqCKçY_uQ‡á¯5zS¦|ÓÿlÅyïAH$D¸s-~™4˜}”^‘nWs\\±=$”R{³Sm×ÕY‰Way}ºÔ4@ÔŒq¬¤Rö¶
+Ä–GÒ€²'4Ü]¸˜´j\ñÙ(^1¦i¶›ÊKD^3¸¨·Õ©âÿ£ÚO¥ºa;ğÑ·egD\ü¾-wËlR6ßÑOµ·Gğ½Ô]²JtYÆò³üÈr¾™`*³—9oVs”áóÇ©ûî„X!í€†»8ªæ`¢ï·p‡À¹´Ö¹(œOÌø
Ît¢«w•&&O`ÓûÅk†°«ñ½©y¥è7¢WÃIÎºğAg´xyÚÄ àO³€#Xóï€©v>Ü`ãdƒò¿²/«´ÏËpo+ßh&;fåkXI8œSÇáp:ªmYxi9€ëíŠË2­äIÿ—Ev/^TSY¾æÄø¾BsĞb»÷ôF|é„ƒ'ûÂßùœ±Îî‰ìù²­ØÄîÅøì«¦2ÒF²M	‘Hùjığ…âî˜]}Ü¿˜/Çts ğ@¢7“Ø'/zŒı4öïßÂ ®TÒHÀÖ%œŸD(ÆÌe€*ƒé¸]æ¹	‰Gæv"${ÙH†c04Òe¸k¹ÃuÁ:g£ÍT$bLd—<0.‰×Ídp†¤A~Fr‹Š2MyfD‘uİˆøği|Ç:qî*ËRåG™ÄD†~P€f§’—°#”Ö8,C”„ì|ŒèŸyÆsNå•š<%Ç8™÷iHËLô¼şñd…¥%ízŞ±‹9¢º\Û%´ÒuTp)õ28m:WxÇúbÅ”¥Ñp8³ù
A@Œ°˜zòWÚ´‰©2GEú<7f]ö¿ª´‚:rkt½GË4’Šgİ’Áìèÿv"ˆè+Šï±,EmŠkqE…ŞcŠÑÁÊuİ›†]Åƒ†ĞçVä<z Fó+ÔDçÎÉ`+g$3ú¯sx9/Hlğry²i'úán+” Eoo'äEsé¬Zì&¿ˆÍ±×:fp<æÚÅ€?eV0ÅÖÁ5aXxyÏ=*9Œ•-z|Yd[£ÈìïÌ¾ä±O2Z‡šŠÃ—õ"¯¶(ã5®AØ°m¯ô3k<¾E‡' ©©÷ÙÕ¦™Ù;-û0òâÕZi é6HDÀ´È…òTJ/zºÕÕF‹sdh®XRb¹İBĞoËÌğåJé©óÿ zjJqlzÍ ˜BÄ~,Nâ…ú sÁ’Åıànkœ¾Ùs~™.İ¡3àÏ@®„Jøˆš¬Îô©³ĞÁN€É!ô>?¯	¶›-+\¬	˜3g¢m¦ÑÉàM£€2:NZê£¦»¥ënïvÈ°\æAAÆbŸ©Ñ¦×U&÷$:ZÛs9hƒ æÁ§!E¿(Ãu »óMòğÎ…Ã„]])„rOVÕÜû^¦7–ÅSF/<æ3X÷ì7H×©%, x4»Kÿp(¢¹44¤Ó|[i>N¡åŞJãVE¾XSòáÒ¸Ç*1³¹@
"xeH|g“1™³m?ær¶|aÁ¦+­}¹yYÍÁf§Nb¨Ú‰ßşTşŸ,É,ø22ÜÀ#á’ÿlhÙ£ã29NïÙÏt:®œ¦J>ÿ_Ãó+1?ìˆw:¡ù½Añ²0Ïw³^È…0Ş… 2ÀµlíğÚİó”1©êª£2EÄz¹h9Oj¤¡ÈÛLúí^eôoĞ³Lş¸gé­§>êI )Ø¼’§•cL JÏ-ˆ /œ¬mŠ^^j£èÁh–ÈÚwZşdÖÔ
­«²ØN¬°‰GMoË‘g#8œp\L|ÙùÜq:öò-±ÉìJ7ƒ­&ì6'´‰ÒøÉû©ò¿w¢šƒæ]4ÅÚåÜÊÍ8‹é¯‰›Ñø9‡	£`¢	ºMÔÿ}&ú\¬62I$‘… £>‰¦'÷ŞÍÃ¨1×Ã(”«}î:ı®ÊäÆùÍh8KgÿMMæ•§ÙyIà)ÂôGÄı,Éâ‡ŠÅÒšBëŠ`¯óWr«9H,u×¶Ï½ÄNÛä³Ÿ¡Yñ òeŒ{~ À%m}H1"Ñ[¹áó__t³•Ô¾¢CÒÃ$®óá­Ö€|D<‡‹µöãÇº·^#e¾Æ;…Á– Ã•-=»İ¨2‘mI•ºĞ‡i†ìÃÈb¸ºUúzZ”?JÏ™¨ÅÜÕAÚ:¡I®:Z©B2†dÍVùsgI³À*çiåìp–f ¾Û¾²æ¼Òw.éÜ=‰¾ÑJŸ-~’Rç¯úúÕ;OõÛ¼:¾ûíò‹hÛ²œëC›…¥t×M°%Ö’
YîósTÌwOHEÕc§g§=7È°4İÿSƒ(Êè;Gn{V«€üŠ8ŞqÚ™^ueåÖ‚4¢\VUEÄ–^l¤¿ela€çÉ÷ıK(£O‚e}wı·^Ãè!:¹€+eË¾vÇ}ÚIlÂ£Ë–ÉÀ	Çà#èHCCU9QÔzRa—î°ZÒKœİÙW˜k„5¢wd	èòóF_¿DP˜ÓdÂM}°Ë¨_Áû‡ŒĞ¶ÑJ+fØòÆb‚eÓiÜêqQıÌ&ÊSÒxûk_gòeÙÕ‡¬Šá˜]ĞŸq˜êd'TÊæNQa©b8ÌXCğ¶yğ®Îj¹Ók“†]3ºGo~&K;Æ´d%xÏHCpGâ&eEÀ>Ö\cmJ/Š8“íÉ™ì’<°°4¿!şûñy •ÊÜ#”d*·œxoIM­Lcß«ÎyOĞíÅ‘¢rÊ³;RˆZª<ØâİV#ÚÅò—%‚|è([|—CY|!›Ò›ÙSSEˆ˜†Å¼l’`T\¸šìË¶M™I<.5tGëW5 ˜cµ1îÑ»U®V¦D3nW‚Í+^c¶U9c@z…Óq€?¿ßï¹lr(á3Á]¶ÏËÚP1[«-¸×+Ì«6º8‹½šbU¹Ìeí¥ûÛÉñD2Ìª_î'¯í¦8K?”«ˆÃå
?¤Ê„YÒøÂ“@(íèğYÿHkï?^’[”µ“ÇÔÄ#ê¢â9z37©\Ïs„L ©ÓFDÚŒ´`KòQW¿tåÕHùÉ®1Vâ[gÊxòjs~ı:ÍĞ”ç&+UzlúoXˆÅ(E–àÎÕ’ö«P›I_.åº	M‚à¢oMb½¶#¦u€ØÉÑ|4C~û¨6òl.Hf»Q]4#ÍˆpJGÎÆö4®m;"†55`µªªUš7”d£ã†Ks¸ å¼šOßxÑ‡k+¡÷z çgbğX#J~Nó!ùÔLUvÖ$|¼J¸\W¹†ruHdyN¥sÈ5­ê,èÌuâªhÛZ¨N#Ø-±—İg×c¿+«/ô¼°²´~¿¿_ïàŠ²	õá+)¬lä
„v›ï¿ïG§:½àåKWW©x„ÚI8‡ ïd™@S€H»œ3¬H@†ûûn‘×,–`¿×æ¢¡¦¦áGÚY“9±éÇSÑƒ‚§'ú\È-’ñá¶½Êêg8 YÃM¹m³ıÉs¦ËÅœ]^­}>XQ}¸²%D
“)oø‹ÔUjM™hŠu]Šîk;²dğœvşÿ„ó~qôõá¯<JÖö@ #°/õ¾½bş2©IûIÿsZJmúMá¼ä8O¢l"ªpFÖsßÂa¨;bàzcóÕÁ!s?
¼ÁÈn eS)ó’$	{F8õzª+®S(İó=†bbØ’‚d¢¹¿J/W4?=ªF¾0¨+æÓò“»dø@Š£íHHüep6$9 ÖöÚ¥å¥K¡”—6;
YvåÛ¶E©éuRJ‡¾Ø8°n=ûéøó$îcÄ!–Áµ˜mysn£@Xš*³çyT üSŞ±ï:Ì6m8µî®áƒÂÿ‹F'=I šÖåAKVh<Õ/÷ì„sÄV{7ö)³^”ø/ÛR‡ßöLëô4dÓKÃ÷Ø¹µ%=lléBzĞ} ºÓê„ÌÓ±’Ã(àªÅ0X^j¤ã§%^°ê`3hÁÁêƒ2Új‰ AÃ{EšıÏ5§Ê@µ\KœêqcÀ(i½ğ(o%ÁS>¡…Zù¥øı<'MdW	µØ,ø¥±„IµÀyP?{‰z óôÀİ«Pã:P5Z'}–èpÃsË›îCÍEñcıœ2Òøõàéİp:˜Lsj=¶i9c8‘ê¤Wè¶K§è0¦´ÈI!&I *Dáû£ÈÁ+ÁÔ[wä!ÜW¬QRƒÏÂ\[{àl£.8‹OáuÛÜvxëÎ"H’ƒseì»s+EWXÁCûÌÕ_$àİ‘ÿ9¯b,Şšøémn¤ÈPÔ\ûaKb~Ğp1)›Æ•*5æHE4¸° w½‹R5Ô°#’f²°yÍÀS¿’±Å—TRñ,‹ı|†3ÉÂf§&”A’(BGÕPø€´	h×V´Yƒœı¿ã¶üu¸ªâ‚Èú’Hn[Gƒí~'¼è¬ªIqå¢˜£|õGÎª©´·8ü©7©†ÊŠ˜Djâ»¦
!÷\9xEX¡ó·ô1_íıôbÆh„Ø!]€«®$l|¶¦›Ñ” °va¡Î¡ÜÁ³æ‡má‘î¶có6¤CïJ.bxx¾–õ>jv}*#?œ”…–Œ’Ø–Eµ^å§s°ÿÅ*'ùarn:4/@’Š²Î;_²:ğ¢H©I˜½Å<<JñúQK›­N£å{M
šAr"Pƒ¯cÔÅÓ¡Ú|‚ö±À„.€Øyô"ÜÅÙb1M›6ÄU4œN ğ¼¿üŠ”‘8Ÿiôß÷‰ù0Ë{[I­ª8Å½za¥¸(–²‰-R_„¦Ä€ödP>Â-²ci<B¸,…ñsÜXm·FŸ¼dJ·-2¥tc7à	ô*7â7à>d¡gÆ@Dl!7¿Kıoİ Ú`WÌ}iÙøzh ^Ôm6Ã™çt3Ó·Í’ˆc“°(7v¨ØÙ}#T8`ó`ç2æ.Ûş†Gİ¦fô¯›‡\‰wˆ àÁVbõÃ0ÉQ}Üta¤mF|±g<ğ©o>×à¢YI¶¶<ú)6Ø¨u`®7'Æº¼ò’Ú7t{ğíyúxWâ¸Ì;áØò<ï¡Çk‰ÀIªNREš´X/~G1õ52‚»Õá± “¡!%É|ï}ä$ÅÅa$!N19òmıd:äî¸à>Äv\s 	Gi\w£›`6@•“ú8¨2pv,]Ÿ´+¦™R£Ò˜\Hñ6—ñï±b?{¥~œWúî|Ä¡™g]’•{Ò;5_±©cÍª@T\zAµåìvÊ¼ê¹ÔÀ³ÓGIµ’Ó{hw%g{ôTÙô5nìøÊæœÖ×D¸%åqX†¡~«¼P³ğhĞò±ê÷:g1Ëğ‡¼è:ÃÄÄı*Ò9L­WoSü®7Ü’ss‰øšYİ0f” {û»Ğ
GÖĞÊwÒ^¡Î8/ı<D²šç(-+“ğÂ¸a œ2,’Ãc'º¬Ò±F¢cí©Ä—XFË`ié,Ğ|Ş]råj¢Ç¼ü­pkQ[vœˆøÆ ¿Ù/À’9†{€r°6„À@JˆûúJ€™÷²yÀ–•7&¼#È:şÑÂëúğ8/0Éß{ïÙ:„½DˆäÉlÂugrìˆ‹mîÍ(° †+’NÙ¬âß–k#&¬  d<$œjÙİÁïoÚı8³úm”§p>K¡¨@26RïŞ97‚Œ°Â;ÉYƒ80Ñ§0s“ÑlF0Âğ^1õü¨íßçéaı!¡Sè,!á½·9Îáx«ğÒo\ÉqPĞ¸¦şÊ†ù‹ğÎÍyş¹O ÛàúD*9F¶œ×(u ƒÇÍşüßY6m­@ÂŠÓnŠƒ´+·PùÆAMZnSä'Ò†rª‘GÕşêáö
Üó†˜-–=	.{À7XòNã^êG„K'åş‰O†¬gÙgvàº—Æ‚„ñıæ½äÿÀ’´a€w%`ÏÑ!d2ïé»êpU¬76OËuoÂ²‰ñL'<êèé&,kä‹å5k¿ŒSŠ¤¤ñ,{MÓ£7nß^ñ¹Y'û{uWS:7ƒ5~«‡°e„á¯ô”Sêxí(xÎç![Ö•>°é…5¿êâgü›/÷8Qû4Q«¾jGjEÓrÓõ¹Y%¹Ù;æ´ô-ş/ı“¯:ìh?¬(€¡jarZş†æÂ®ëP_7‡ıÚğ¡¯qó6®.iŠtO=¨ìF]û¤„MŠ. ñr¨@´;Ï¾TµŒ..§à½6Å>rèynœk…ôh1çú.¿ç¿õd¿‹{ÜòRVßKn=,z4ÕzËF˜±!UòÎÑ3íúg§^ˆoáh+Q‡ªjà3dÈ†M#i¡b’ç~]ñåƒÕá¡é}µŸk&*î&û*sbd¨pºbÊ®Û y¹î‰¿–Ì[Š9É•„ !£6?†¿ÇHS‰%i¯Õ#}
™ì÷Ry*Pá@ïx§[¢õ
e’ jOˆ ”³+vßiA¬a:ø™úYHMŠš‡îÌ!W*Éó'nÔ“Õs_5EÆm5J_—åè£r§Â	XÒuk;ÇÕR«áÄî§×’IÑJUK_ó\ê#3î"× Ã‰kT½è´ñ	Uw€Ï™Õbd#ûì
ì›ë)gHÚÄ¼&6_Œ–Y…Smõ†O†s³¾«mÃfyŠùgçó§W~EIîK¶"÷|-Û|À¡6Â5šzÆûjƒ}\Z™P<ç3s<}ù¶)8¦9½ûÇ—(ù€ùcÃÜÛh°ØV;‡—ÇyO@ößª‚Ç)¨O$Zíïaş±RìaèIØBÅl8â²í1_%ë75­ªŸû/x–¯æu“®ÿ¤,õ¨d ô¸—àU›<ƒÏSxİê(}ˆ³’m’rNG'éyØ$©>SäD U¸×ÍV%:AË+]9d`)Ûå	±µWÒ2&e¿X9ƒ+œmC'ßÈ4	\vÑè»š¼raõ<â6’ı~|¨×ÛÜŸ"ãè³†¢,ŞDG½uSØi·¥“;0\D×…˜Ï=£ã=ğf“xXì &˜¸IşOÒ9¥8cG)UæÓû%nzÑÒ.]:n+(BÆf]•‘ÙÉ'¤g¥NPn1˜¾äÑİûÀéŞç’”Çä¸-OåZşˆ•|=Î¸ªi$N¢)O—j"¨W:é†¾>(k:LÃwãsëOÉKû;oî;„oœÉÇ3«Ñ®²8ÁÔ L^Ëã¤å’²Ï«gîM¸,Y¼ÀL\ä¬„&Å%Ä;>f¾~îÛˆA±&9±w ˆCÒk7÷§@KŸ®EYâ¸„'šfì²½ñÿTJÂ7©ÏŸE³¼­rÈ†¶Ğuh:vå×€ÎÚø†Ã{¯ŸX˜óê´«+ z$´ÕşÌH™€Ú’{†2½9ÿæ‹º=w€÷_}âÈÃf{ø”Èôb’M)rlmïUEW'#Ç5çàÁ˜ÆsÙ¦1í“ —*Ò§ışp5ËÃ¾,3]m¢}Â|¦0B¶û™Üªq6*¸fS~ÀFŠ24U9+”Sù²Û?šér·X:è"Æ]U¶
y¾Uü9’Ü¢í—H¡°Ü÷eqWH(}õ¶>7ÇÒÂ€Ä–24±¬ii·1Åèy¹ˆ­Änlé˜0ŠÊ»­æmXj³|b¥ı¬ÄĞBg=¥>¯ëğôp-…Ø¸çŒ
¶‰'Ùb¼È œŠš’ÿÑıÀñYb‹í½7¶‚Ÿ…Z$ŸÁ:k´AìXõ^/±ôæÕyèm 8öÊ€g‹‚d;¿gîè!ŒBëúÙÈŸ“ö˜¥3şº ä8Ø§O’©Pë‹XK.Cà%ò}c:$îDÂa¶)7‹Kƒ–KzZ¿å’0Eo”bh?ûË_s$øñåƒ–¢Î*Ç¬R§óåíT÷:zOÈİ¸HËH‚aÂÈ(†µ L$|ÂféÓÈ»)~×^óa«k è¥!Ã±}Yı‘#"VÛKç½1’¨&Àª9Ğˆš%²N®³İÅSë€ôtmë[ë)fœJ†ƒÉ3õS,»¥üìDÑ¯Ó	ô¥·¡G½ğĞ¥xV0LÂ+r¡{HøÖj¯¥—µé«3³nû]4Ğÿ€Õ †ñôNòÙò îÓé0·å0Ö“,àå%ônFL{jn†f®l8_bp>ö/…œ­›2³'ÖóÈ¶™•­ÈÆÃİ²Ú©"I*}@s¥`’Iš”c?EI„Ï_×À	FÊª%ìÎ	N	XØ„¾´5¤=¦ç%ª'aém‡áœÚ` .¨ éÖêPèÿ›8N™"¯ ÑÃ nÉœWæä±°•¶>õJ»¡y:”tL/z;j[Ï´#š[(úÈeÆ{rƒÑ3»iÌ+V?q„Öc\ññ–Bt‰šábİµ‰ŠL¾Ë#€°Ä5œşè7qnd1ù)œ‚E71Ò#-ÚDÉ¢SÚÿG™±Í·è=[ÑúQw«-¯6E¡Sä {ë°™D;¡ì¸¢%V¨¦ÂxŸÉ÷Ş&€ı•ãõ‹Á_Õ^uôğïÏÅ¼¦+´s4­Fmú]÷DíÛßŞs¹9ôŞ)¢gl¢U°=E£v±ÆD,˜”—f[³–òØ=vkL„iĞè)k‡Y5Âõ´t³B»5CìyfÂD¼kÊcbéE@9À´Z>Ü@sIô‡VHsÅÔI¹–ac«kÿ\Ç!÷Ñ ¹ÑOU«ğ¼zVÄ„³qQÜ©³`yv½hè>Ws9Ší ²$NW/î,LÓİ‚îñsH®Dj ÖÒj£m`´%¯Ó§7ö`¹¼¡Cs‚d\Ka¾T‘Œå¬‹ÊjÊX¹ÕŒ®^B…1ƒ^Ij*[‹9)øù	4(–:¨$#H¡›Uå™¤l 	é@ôŸfX*%Å8è–cŒ÷Zïÿø@±mª…İ¢øSİÃ;éZòlú„boúTCà:ß%#‚Îhbÿy =º(ş”×-u­C!Ğ™âîÀÓõ#
à½È4´Zä"ºn[•Í’f•Öœ²^¢»ÊMsLİƒ;–†*ï¯]+–U¯¡zI½û}Ãğ^q€4‘æF¼Õ²şD°Ğ¼‹Ã9êùpßP÷Àï:-J²FÜKÜÀ¼‘æoI²ª'ünÊ‹Ø–‹Êqğ>í§fI#…´9æğ:?¡.ÿ´bÜEvÎKé^;‰C=ej@?AŠ†$iõP!ÈÄbyTcª|™ë(Å9B6	ï¦ÒÊ_
'ãmü’vUîÏ&=-~ˆ.‰Kæ9'µ{_ªÇR²e¶nÅ÷K¥·S®Ÿ±-l"=†»u¥	Fb#Bîv´J”>kÕvÓgØPøÖešÿ›PœçXŒõ?##dB Š"
ŠşÍ_…cò&g‚Š¸÷Uì‰£à¥¯¼ºÇ1,EÁ“‰G]°§¬—@»ÔÀÌLÂö¥IÍ®I¼ûmBæ½‡7ÕíõL!^§;Ä	hªèÃÑ£öË„.|¯-ß³>å]-ô5„® ½Ğß³x‹-˜ZÊñÂ>j]x»$>¦i¬ÂæM¹*4Ùøà&³~:Ö¹ëº®xRJ8ZšT-ÎÿVbßüzr÷tû­óµÊFÆ¶‚ÄHÖš1¬ü¸ïÚËÆî»Ÿ×ûÇ×»1£½Âˆ¨(•²˜ cá!s¼¾z¡‡Ä9=O¬-›ºlÙÿRIseØë§õRÃ Ô&—N@	%oLYmµFÇ,WâŸÄr	Æs}ù¢UÂ8‘ˆu®rQ˜­Gš8ÇÓÒ-»˜—Sj‘Ü† w$95ÿÇ/QgÈü’ÊÂ¤úÒĞlTñVş/íJsº1éÛ¤q¢ıººçNDâŠ§˜‘èÏ€ß<ÅËOÌªÃës¶ŞïÄõˆÆTvC‚ØijC”é¡Å…E»rï_`!íQØâ‡Šñn¹¿Ïô~_ûÍÚ«ËçcE§$Ïc0¤ºd(ëíõ¥oç–)ğ{8ù5oƒI1]Çàõ¾–â¿Ô	õ;Œsá¦2<
­âÎYş^äXh ]1¦<\OåØ2¬F	9¥ˆ„–·ã·)µŒB¹€Mşı¸[¯Kª¶æân_H{
Ó$ÒÎF€ˆû¼)'"EÍ
úû‚GÀÑ7„¿ÉÓöì _6Æ'E@Ú/—0ıg7²h³¡âòdÊÿ­İnœÓ€‚£Øå¦qÿ&)˜‹åÔÛcu7uIRı\eÿøğ|ÅĞ±0u=¸‘ÿ¾{Ò—ã´Kø"2kë–Üä°’©wŒ,tXóæâì%tuUŠÁ;˜µw$¼ß¨w`~N&>sX²†GD×¾êùù) ‰Cê—'0Q²Tè8=<a£‘ÑÄµ¾_|ë&;\pÁ¹îe-·R;®æÖâvDîÒ½waz `5IL…÷|,Ô]¼–Üí“e—	+b' ğâ%6‘âú Óı"róÃ˜ÿ Cy2Šó^‡„R¼z|±‚N
'¡¸ïF5/Ô)ÚvısÊÆ}ÌäÁ°\²òÇÿ|’X1w6Š˜QbY‡ŸâIÆÊ@hş'»Ä(-Ğmwi5wøJÈt@* F§¦
Ñ‡!Ìãññ¬ñsĞt” H‡/u7¢XÓö=¶î¥…—ú>˜ÿWÆæüˆ‚z÷ulÏ:·ÆÜÃÅ„vÕ[ìÏ°n·ŠöVm´’pn¡û .Õš¢Pln2
z OzNñø t“‚o»š’«í¹Æ¡˜èNåx@Â¼Ğ¾ÀPü¼MLé½LêeJÇ0ß‚Ğ¾n¥­r·Ñâ:ÒÉ£<±h™‰DÕ®=¿àx*@Š­•à™‰ü„Ö¸S<°!w#Û²Óót¿tƒ£d¦È^sæfGÚfÔ·Š ©§ÖÇñ@iğf¦—€ò	Ìf1œÓKL.Ã~•Ö¾K2½ƒÈ}äõ=º2>ïÖ³´.4x¶ÅÓ2£¶zQİ¶œjİ«¸‘ÔÜ	 r>¼95ı½Î{‘Ğ|:³ÍÖ"xÌ`'êö›é ñğ)Éõİ€9	aJô[ÿÜˆ)5Ç&w'–v–¾4ÜÁ]—öZ÷V ×U“Âx2¢ör€"¾ıœğ=YUr>:ÎÛ>ÁR¾ [.§v*™UâÃŠjcõf°é¸¡|d¬fÌXÍª³İ !|íÒÏaß7zIîƒŞVc³œ•R#>€2oª<hLT€D#ÍoâÂÅ×€¶<xKÊˆ–à®²–â‘o`ƒÏ"6ÈÀ1^œ)¬›ôv¥síörĞ‚Râõ}¤ú³¯€ß‰ÙQ°Z7ŠÖí5,F·?oï…³<
­ªPJàÚÎèê•*iyâœ k%V°p-ƒÏdBêÃt
h®7”h‡m¥â~Å*üŒ³Ò©–3±`/„5/3œ;s'ùsæ‹„C¸s™pú·8Ì«WÍ¡çŸ‚}Ha˜¾á"´Ç÷‘ÇDø½idW¤È€#ı‡’eÕZ‚E[”Ím×„QkfÍ8ÅPÉ&e{s8º]ÜÏ¯ÈUn—i[œ›9"%ÒÜ‡@µøÎY _¡ôŒu6´ÉY%@è‰…Ì°0lÃ8hŒØ‹!UBh\óˆ ßóK<ÂÍnV1Ã‘^|­Ni<ë}z¯%}´…L”!ıÆÃ„8*ÆI8°ó®Í<‰>:XõÖT:y°ï@6t>9QÍÄl§ÿÈ<:«ªÈ™qZ6ğğ•Òyğ·8EæTK›¼×Û 
á"a ÌÄ`=¬‰Õ@€§‹rc?‡®”­2+@$ê)B:õz6ªD+&”JÄ›×Ç¡`HÃò_…a‘N°ÕæÙu95	Æ¹½½ôøÙk¼Öz@¨+÷\g/ÌlbsÕ-¡á<J¶¸²¦2à.xY×ğÏ¦•5°K#…ïÁ÷_ãD2î)57vx˜-r½Ó$u4ßŠ9OËşAÒ®HŸÕ6Â-®È£üZ¢ «¹LXI¦¤—'ÎYM¢³¤ÃğÛüLÂ¿ÙÈüÎ¸«€VàzçÒ(Ô1 ˆMKãß£êªëÎÍÏÁ®S;wöE1ß]Ñ¤WÊKìcÍ­ëqˆŒ”ªLÍ¤ÈÖSášxgIPB+ŞhÓ"ß9·…½€6	
w\±Ñîã„]0O¥‡µ‘¥¬]õZŞ4n¬÷CgßÃqê$Ó«>Ur×&‚`µ®œ3½Ö{šRL…«Xœãîš¦”§AïCñ"ÛNÓñ¼vB0Õ’ÃzvyUÇ$ÂàdÂ˜/wo:åågz§¼±»5
âTärUÔš´zõ÷BXv¡õE÷×9½Ê‘‚±sWæäL°ª¼ıÿ‚òæ.uzA_7…gA‰Å«pPß6h‰‰³ÒŠè Ú})Ûu’‡MLÙ€ĞÊLuİöğ€ƒ†Ë¦:e¢tí[”ş” ;œ ›eV£ª¢åHÅ:,ŸSùøM*=A8¶ıw¬ÒMUYW,Æ:ÂGÛ ùĞå—2-F¢ {ÌB"õ%:ì´X€d6çS!ÔíïÎ‹d}³×cI¬õæÇE
(r	F ”FmQ½ø¥Hß”u5ÇjN
Ïİ,fêŒ"UL+İÌ¡zû±½6Dò½ü»¥8‘ëo ‘g0¾Ë0†x¢/KĞ"Â»×È2ìùoø2/åsHæüûÙeÌƒ_UºS{\ö°d ?æÊ‡Ù½ÿ¬:„7_TË|Ò·ÏAwf§Ÿ‡æ¿bwÆô…âxÇŒ(‹ñ‘®áÄ1YÖ½Â¿bü]ïIåYñzó¼Jì‘øæ{y½dUšÍ¥œØïÎf	¬ù#a×µbrhÜ
Õà
‹ş×`"à_¾p5bIƒkW¶šFy 8ïÇ8ÏgÎŞ6SÌ`|ã%<@Ì!‚ÉnnóÑß É%#g½N>Æe+À›¯µ:êÎ½ü§¬’¼Gb¦gKåbÉ!Ò«Ğñ¤>$øG£§M§V6ÔPË\×àiã”Sía«—]wVŒŠ£ãÚBéY¤ß+ÿ:kZÅõš£RQD¿¶pí%KÉÌî‘x
L=´ò;%ŞåÁ.×øû•K¬IÓBYİ!Ùdš\Ô)¦ÒDÆ«DJ¬IZïœÆ#ïÂ;ä¾oYÖGsaˆ…{¹d1‘–û·GNÇÕ©@|GWDzo‹»å¢½ë½·æ‘”M³øO7Ê‘ü‘Cqà3=õA#µ©ÛòR)ÛÂÂ¤€kxZÂ¯› ñÕ;z^…öv.˜ F:m2O®©ÓÛ İ[}´uˆ\‹ÑøMÕåæÌÖ›¹ƒSJ)ÛÍ9%­H]» d³¬¸Ûk~»GDT\¬XLÒº´§ °îQ, of\ı"½ Ì«N>ş  óÉñòÍáYgŠ—.e³è>k«ıv¹[—ÙbtZíó;ßŒÖœn	Ô°©>Ã­òü)!5õlUØY¶‰½›ŞWöé$Ôê°–Ş¸½®²-UKç4rÍd8»ÒjQ`ôª"/ïa•Ş	C5öÕÛ2*1¸ªÎÙaÌ9q‘îqwã–ı;g™ù	ğ¡‚PûªCQQï¨Å8$àæzÕ¸İ´kˆ}*S,Î˜!p,Š&6A4çx'8X?7[-ìÿ­¼Êet4xÉßbJ¯bÃÚøx-R‡¸'9ÜO¼†İE­aVâ”rÈv]^“Ó§Aê4Öw‚’½Q0Sh`•¨¯@ÒjÉˆ†zãóõ:ˆ½s™4:ë, ú÷ˆeÚœmïm1”š(zJ¼ÏŞÎ×âcønàĞŠ¬`e†Cé–Q¾åp¼{^Í,K°ÅÍçR¹ˆY^Ïk×ä3VFı:Nm‘ú®2"|¤è-kÑ|ıÑCß§ H³Ç©Ó1Îÿ`ı¬^çâ»ÔÚYĞòù,HÑ6*ÃÊ[˜öãÃJ¥)xcs’³ˆ¥Ñ™|ËI‹Ë2ÎU>BÉŠìÓfgDÈ¦›ß¦ÎÖöXÙg¹‚Kôê¹$¶Â2é±Ú?»ãmªDÚS„Ñ%Ë›¼ú)®Æ 
ÛÂÄÇCœ¼ Ó=tSÅ#7Ñ…ŒÆ}ˆ5iäo®ã«
åËJ‡†¦$‘—m)÷ÿó­Š‚¶}S½HS7ŸŸ‘ˆÌ­¡ÕÊ¼Õ³î^ÙE^!he­›D|]_ticúz«,X^'Q&¥N5Vú ½]÷§¶N<?Ó?)}v)– cö¨ıP -•cßtZƒá\‚ëô)™²÷	ÒÄYg"“¤ÔèÚù˜FMCs¤[¨£Å]Pt[;;XàÔ#º:Úï+°õÀù
×Ğoå¢ë_E"=¢voı[ûu½»©S‹,¯Š²®qª°2AÏl/t-şZ°Üö·‘|ğÒ¾ê‹ÒØ±)=À*èNó¢¦Î(1ÍÙ…Ê¬.í=6ÖÕÃÓBÔ?½ÖhW~S«µÊg®ÉªTD0?P(ÁÏ%—K68ï¹Ø³[Ç¢$üÃ‚v”x©Ó«w)u?ô9y3ÿ‘3[sÄ —€mõ]™4ˆô›°uçN)¡Ş%Z9i{FWc©H=p„…ò÷q.°7Å@#qëİ	´QA;/øèošv`õ±¤7îj(±¤X[òøUgxĞ™ÇºN®$Aœ[;<ş¨ü»ìµ1á†ëTzA<NYÍ23È¦‘•>ELàPİ(yHËzOÖB/O%ÓU>yÁ¤¿fÂ²6Çèõ#ºvZ’ÜA,Ù9sT“¨?KûİÂÿëÎwĞBÃ¦œúğàTÃìŸ+rÎÃ›QÎ2‚ŠÖûDŠ˜œ ¬¹©‚†«3Ğ9dV£ºX›ÜşÍ4MÂŞÇñÖ·îmbHcÏ	¬e/ˆ“‰Ã¨‹P,éá	Ò-€{s?–³pŒ»j‚ißêĞE~n÷´ÅÁ#i)İ‘¹æ–QS=VD›?¼ºz·(øĞêşŒ€’×'à†ıaâšJÙ®Zd¹Ş àŒ°œåñ[ {!YÒ0êí5P9¨Èr™…]‘?i+"o˜+/Œ@Ñ)ÊWó>ÿìƒé£şßyG—s"]È_º,“îøaØ6iTa¬¿şğÚ•é^\ÜÉœ«B»§rĞFÅ=æeM]‰KQ
:ùlÙIúGq{U½OYı½ª·söºla#ê˜kä`,˜•&Í|T¥¨¶\=#½B5¹KÒ€*u+*­',Æã­@µ]*"H¨ ĞÎ¦‹ßdÿ>•/X}<+èuÜšÑK±;¶ÇV]s¶°•îÆ—i~¥*iª´¨£ª_‰­2Àiòm>©S/oÊÀ—è/¬bÊÔÄŸPFÜ÷8ãƒZ<Y®_6EGOq·›k>¡øí—ç€Kau
µ–×ı$Qt·á‹{h¹Ÿ‰â5Ø.s¢wü†ä²÷G"pëÎÛ¶É¶
p’[Åh8 °]Ğ†6Í¤4c¿(}còßéÿy]aôÆšK2ƒ‚İ,¡Rr¨ú, é‡İ[ù ’Ò-O:Weå„Óy*7ÁöèD7İj5%†İ=¬¸ªZJ°ìªUßtàæ0Ê€Ë…O$ËİKÇÁ]aë9eÔ ™³³z ØVGn6ÁşÄ1ñúbÀ aÅah­-:w™5áè»–4yz•½KIå÷4d®_0jm…Fj	¶B0SÅÀiêicZæ¯I–Ş\Ü"šÿ¯–ÛPÖMJ*å
ñ`g†@ğĞLl‹@…êÖ”²W¡%>à©/ìÚnnQ<°hTè×„
²º´¢”ÍA‚İŠ>bYCŞ²ñÍßğÔw§t<lMçû<ê¤C²ÖT[¿¬¼‡dß^@OQ?
USƒ‘×K/o}ñÖ·)Ş#ÿô-*“VşºêÖç¡7`d ªìKÂgy;¸ÿº	PÈ‰ßuTå×ü*kp|CöWn¼Õ÷×üÔÛ<6ùD'ê¶÷²¸]2˜2{½Àöˆn]Eñ—Qx4Õ™î0ÑtçÜ%Ä/jÕš	¶xÅˆ7¼ß2QÊyÕ8_nÈp:˜ÿrÒ-=-ô½#{0LïF¯–Œ´–™ÂîQŠûÆÕjL½9©£&(íï¢ÅRÀ[µµqÀÚQµ"Na-¾ã+ÿšãï¬*Å5ïóL9óÔ7óPªôPv¸ÌÆ“Çü&à"zé:¨,º0KkCG´B~Ñüœ¡Q	–6ˆø¾p·õy€®”½'?CUç g÷T‘4=ˆM`´.¸7’ü–ëÒF¼H_}å½§Ê`OôÈ°Y BÛù“4:9qJ
pSu¨H‡Òr9´#e½;¯ø€©ò`jâZñÂµc4†&·©Ñÿ'ï¸=8D‘\8Zô; d)¯ØX¥£÷Šú68kşYc.œÂ£÷(ö\K†Ë
?ö]G{[Iˆæth·AúBAº¥oh¶ìïÓJC†èË[ÖtBSşÙ‘s•gÎ#dÀ§¥Ò8{®àÕ ÄjvC8«Ş}$%N*¤2•Ep¥s…×\Üw&Û!1ãª½,¦?š0É.hÛ¤ŞBãäd¥`áF°&N7L´9]ğ_RèŞe¦"H(ißkN˜E1Æ,ÊÚ¹ ®Ú;ìöúŒæ“&µ7®ë?Q„´?û%œÉøgû†¿HxP„•Ñ²Ò\Ûxİ€¢):äSƒ)¥ıìĞ¥*uÊ6êÍ ˜ãc=D)kXS’E‘AïæVÏbÏ€”zˆÊjápä^ç3gÓıĞí{à;ßÑlE;=øJr1tw@å)öÕ¼µ!şñúq ÓÁ^ŞŒ5Å«Ô
i¢L¾é`SU¿ô+9©	ûU•—O}±Æö Ÿ?-×¨ÎhÙ»YÖåçD¨¤€!'á–yã-•%¹PKZ:CÙÎbV¬ªÌ&®I
²!u4ù®õ;ÂØüì#ÊmÙĞó2œcˆ5Œï½ˆŸy%OÜ$áèg`Ó‘§7»|ğö€÷âŸ^3Éî—n8Áß¸ö+:æ‘ÊÎùò–CûaA+:8€¨iÂ©ÚßÇHiª£Eæk“ŒØÑòvı”Ö[§89tDN‘È‘Œ©_ÒOÑwCÛâgvõõï0»àŠ1§cs`ÈXœÃQ¬¥…å'EIé
Íô'–Ïä[r"q@?äNä”}Áo© j?vj@ı"ÀôšÀ›ÙÕ1åá¤Sc¸Ùl±s#?Ÿ'F=SU<LÌ©¯Ş¸ç=ƒS  ÓLœõ#$»³íñ–Cì}‚ß·, B†6‰ín2 ¬ºUÙSw Ğîhå0¦ĞÒT«3ñëOJÛŠ’w‡ÓAf‹ÿØ`Ï¸şöíG8D+2íOĞÖÜqs<_ªAhê¤­@6b·½mîRÃ…‹><ºÛ”!´lM%ÀÿãßÕ‡ÛÇ‘}–¥ñqL„…cí,Ä uc€—ÚìıÈ¨Iµ™mˆ*¼A[´Ì„sF5ú3ÂÁ×™í1$k;-û´ß€7úŒB8} ¡GH¬rÖ¨¨€º"Å‚NÄ‡ò°]h%„ãõ½OL,Û.£XY´10ç÷ŒØ‚Q–#¿YÒ0¯…Ğ7ÖÂš€@±Aù·A'0¬GlY=ß		ú!ı\Õê’™á‡nÂÛ¤¡c Ô¤Ã9W$æ³äMßA¯Ù‚.%!Ÿ.¸
Ã~ÜÔ|İde,52÷½‡ïíº3’†¿ î­‘£şÜB½)O…	ÔÄò¿B®/ƒ?[áççÚ`tÉX2Dùß:E¿c·ô¬Ç‡ú(EÚ?‘ÿ¦È• +Ã2º“z»ûoG¬hÍ]Õd#MåaàNBTÓ÷ØA'ù£Ï[ûbxé ~jNä
üG’Qšõ&‘_>Ó¼ÍN¬­g«ìÓõ‰]ÆØV³ñxÀAuE¦v’eİ*MUš%Ã ŠBRRo¥Û{@5L±xÆ¸
Í+7ûd.³6;WÆäí(ÃºAèø£<)i³	ŠkŸúOŒ,¸O‚B“M¬à ¨9•2Èr°ƒğˆÒ¿ÜEx”ã”Šßê’Ò¢ú¸çœ*öÜwSÒ1&ó9q€^Fˆ-Èé´ù Jøs5¶Ì„œıağĞé N§$5Ç}«é[ÁjA¸ŸH»¬î+ø92OĞ¶¶PŞü8³¯ÆédçSÁ¥ö5˜¶šÇÀ†[ò'	°h•Âûxö÷™ª²iÌ½ĞéŞ,és°¤”øèX*®÷¼\
Ûş‡¬©NÙí.È€¾d]KëcP{–åµ êQ{ã-0XMË’bdíVù"Hı¨«'°çğıÂB[DdKx§±ï8ÜU41`p_Ï·§LÓÛ£€S½7ª´§:úåñ»©¾ĞÑÃí˜]$"#if/¯¥Œq.#Ğ—7¹Ñ^3`Ïš%’ÚAÒË’;=zj«½»°å@\7îeıõ4¨´FübyI`©›-K®‰P½±Ï{v²?×P”âb€êÚx·î×3·m„Å"rTòeécÙÙS²b‘³E1´ª—ºÃìAº1×èª¶Ö
Â…ÂI‰s¼kcCGpyÔ‡B—g
¼e´¤ú:z][ş>J+Ì›lã¼@tC—^}ÉÑMÿE÷#§
TP–×M*ß–ìÿğØÅ-ä¸áø–®n †ŸddûjÖgÊSpüJKDÖv%9DÀ‰^~ÌñX]ü±ª;ÁzÚ­Htf§ØwPÄ¯§2å@sIVke¾¹£LœÙæ/ò‰”%E³ZàI r*º:Tõ‚å¥†šz?@fÇÀğ±zé¡òˆ·©?%7VÍ¯îêAöÏ¬Ş¾Æ€†ôß~¬ÙtöhâÁU `¾É£>–1½†(ä á»^e}LVé2Ê´O–ÊşŸKöÔq‘fã•(‡:Ûªı/]å¢|æ)Åî{ëE q\L«}šFŠXÓÚ´Z{`µjG%{®‹Å¿ˆrl‰?çi¸w–UC#$ÏA«¡L#ÀòNHÏëGE 4r6èìV"l”ààrê2»ø-£M¥N‡ÕÉ`»¡Ê|şr=ªæûÓã³fMé–£á2zÙ{ğj±+§S†8ØKo0ŒˆS>ÔÿÅòšåS‹Ìòê;“k
P¯ª¥D²`©Åx>ú5K]v‚ò½.æ`Ú$²BPvü2¾ãÊ(
¬7N˜%dª 'ß°„ºÌÒÀŞnQDñ)w×{Ñh`Üe8À‘Óp—*éC~ù/÷t¹m²Qª~Á1|
§Í€/ŠŒN$?¹:£ğxÔ$”Uï„¸¤4y’|b¼­"Ur"PğØ”N~à£zß	ô7B?qõ>ÅfâeÔ=Øo¯ÏPÌI²åèÒY1'JLë×gÊ“‰9C5¼F…HÃğ	;cŠ…¥}‹œWuS€.ÊœeøõÑL‰9ÿsP9d%Éke-4ÀÃ¹§‹ÎpÁAô/y2b	Ã±…'ìT§
¸n±(ö—ÕI÷«lï¸z&;ôér£ˆEéoS~E©£\wsŠƒ¤–,p£Ÿ‹ÇÏÂj¢	KŸÄÍfBÌú€»X†|pãÜMöD‹×g±aTÊAõ§DŞbŞ©EöuË•bn=£º'MÔ¼âj1ã¤u~ÏpÂ§H£æ—ºSˆÎß…¡ñ,ù(ÕUŒÙìA¦n»]Æ¸Wv¾×‘½íK¤#Šùä|Obª'O|{Ş÷EÄ7i\nÙş;Ær¹Ç,y]Ë••°ÕÙÛ×”iZPeŠ™­›ùÁ{‹7ãÀÂ%ì-õnvXä7h‚c°dræ^ü™Ë˜ŸQÊ¯q“‚B=*û¥`”V~pĞ%/„ü’{û¤¥ï•<§i|]$ºÚ%7÷²ŒdW¦Ø2U&2Õi£O„ñ*Œ:=UİÍĞgÆ}¦C»r)»¥£\‹‰÷[ö–©ÃZ¯\cU¶ûBİ°i¹PĞd$1İuãtã» İç×Ú„?€Åªğ9!Ö+óë+5F³Ûµ·øs÷ñ2 –`0ß:¹Š½(õ¬ÛjË­sHEñóÇùp×SÖÜ‡K/@@²×Šrhô$áéÃ-i‰å'Ğ”r‚öÀä”­–„-%rY°s€'I¹ä‘¶uv%V½V‰æ/‚‹»œ}}€!("øø#hYU>S"9–BxeµÑPå\–û)&…õÁ¡ı+`{.§±™U›vì“`å+cSê²­û˜ËüãáùÄ„œp}Œá¿Ñ"ÑôÜÓ=ÿÎaáöĞƒÀ|*ty¡ÃlÛ.Ğv

À6£ ¼¿¥…R³ÛÇsç¼cV:ĞştüJ¹E¯†QÅÇ…Ä—ÙÛJÓ8’NN)3îİ3Mm<GvGÉS†·_‚xô–ß‰8K5M†ÔÆR@“¯ĞÕ¢±< Í)JË?òĞõn6ZGooÓQëIfwÑ¤İ\ø ÄÍm‘ƒ¯ F¹¸²ÕdKØ2bµÿ¯à)âĞk Çï¯¯DZñŠ“üã¼ş´ö‚Fö4Ò#MCbç¯VâãçøÛ›Óˆöå›èøN¦!pHÎT±x%:£Q€ô”~P@-…Â]Şh¹Ës•Ìô$¡ÿZñ?j3¡üõ›fê\òÖ°h5·‚³İóÑÊÑ³ÔQ,L˜_¦ìøİÁPëhš®1»ìå?éBó.æSKúÉ?İøä‡îQ í{È9ˆàyJJèücEÓô•MˆC[òö‘ˆSZ+ßŠ œˆÃ]¨¶1„-ï¾§ó~j…qÖQê1$´"‘`›ñİ½"äfê:iÏc#û>²…ğÇEQÈtÏ?Po0Ë/¼Gßl´…z_§lI1ul>?Ö²+p±ĞÂÏd!8C@[ëGZ‚¼”­8>#®8ÁP28ªÅÕyœæš#äÃ'ßaû„¸á»‚Ù&•›gâW?Ü\`
pÑğÃCyôëö:ËÑ¬Ô¤"e¾R1YTòJØL’qUL™â‰“âºp}&È§–Ì5:ÂØ7OØ¼Õ Gç9ÃZÍ&û7Ã} íó‚¸ÏFróÒÛÛƒø 2%àgXf3aJ.ü«~ûÊN´j£Háß›a&‹¦¢˜nAGÖ“éÅGT5M&ÒŞ—ğ í¤õ€9fS¦º¦n°À±|4hà)È)ŒŒ¹Æ×ãÙ·ÂE× MR„óÊ{"&'‘÷…Rö°şiHÏˆ‰µÚc­*Dª–& 2ÉÕğ–Âr[:Ï¤‹œÉ–g*k·öŸÈTê<t÷è«#c$õŠ<ô+l´³4 œI¦µÜX@s+i)ÖgÓ5ĞÖbÕËîXNó¨İÙ'Œ~èÍlç¤ÃZÈh'“ïë.FÃ©¡‡îÄ²;¶ªFi«ğQæY¾*ù8W­Fù©9ÿÃkDˆ`tµ¶¦ØZk3C7Ó­¸lÉ•åãñWëfİ57îÍícÑ
¢Ï™‰Ù!OS(V€·ÛjÆ~€èèî¥|†ØŠú$Y²,.n0`²³Š*Ù[µ£\İ!ÚÎ°¥ßÑ€ãu1"÷“áT¯€³œJYåFkË¬Á­µ—ıõ96s1æméêãe—¥äï¨Ïó+]€¿M]9¼Üèzl:@$ææ}ÇYn¼\O`h(+b ç@Àa¿Üve¹éº‚x4$€¼lc,ËstŒ¬,ôyìbÏÈß›—Eß±×ùî0CšZÒ•«ü 3gëU“»%RİT%<4V-$0Ám¸ˆ¡ƒß!7Ïı]dÙ¬°2ûNmC¸§Íï}<Fû1G‹öWâÒ±ì;·yØCÍÚ§ôÿMª;b7€Ã4</şıáËúI‰h1†eÙ<5TuŞ¼ ““`‡¬éš	¿’Bf*Q46|øZ2`¶§üÁçp2ï¥bhYÇ 7š¤r’µƒiåıè5kp÷lÇáag¼ô$sVş%€ƒ³ƒ_ ¶*é‹6¶İ¢‹Z=Po¿Ñ´ÜüDUqå¥üy\£²ÍQˆiÅxD½6i ³ÖT³Ò!¯ëËØBeŠQéıiv)1³Dë#ÎíÂ…ı(³¨ëB‚€^Ä 	ÄXı/¼óÍWçÂœà²Ç8ê­sUÁ´ªu»Ä•£Í"be:É'øê¿ox´†'´·@òhM¤ù1e6†ãpQ>‚+4øJ;ÇÕp ›/Ãğ (5A1ã¹Õæú{4 2ôY[}Ç9d¾@í:vu¸:ıÅ~Êl²µùR†!Š0’1,:×ˆasEİ‹	ÚÛuŒ±-Ùæ&äÕ‘z ƒdÀÂÀÖ¨sjA×á™ÈÌ?ãyÿòø„Œšídr_ÃYÖigÑ’.„q:Us^¹g¨åLİÀü7ÚZG—lŒô÷ŞúÍ<û)×ä¤§¢œ%H†ìØÃØÚ&4büàNÔò*[•œ8"RÆùf8­XÆL±í£E%zO 7ÉÍ‹ÊáWø.éÜû˜o¼ûØi­ñ€¬è•:6¯{Y1”³ô–ß€½±KìÕ˜vgì…ÈÎ|Zö÷ğ8¼û»ó
fÉ·0’òÂÄŠö*­aåÜøì|¤C¿’f£ºãá$ŠCÈRË“)«ÃíïGÅåtEql#j`Œmg[B9-´h‚[e÷t3JÀ8>÷x{™KÜŞ­#Q¤äé|Å8E„c(K2—  áhŞäæõ ã¹€ÀœéEB±Ägû    YZ