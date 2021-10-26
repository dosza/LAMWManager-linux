#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="31127450"
MD5="0c4f899b1a1221902e909a4467600bed"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24096"
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
	echo Date of packaging: Mon Oct 25 22:30:54 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]ß] ¼}•À1Dd]‡Á›PætİDõ¿Rñ¾s¥‰DWê#…q£Å´•	’±bS¯µ«áş¹ÌI—×Â9ÃMFç	OŠpnaï:\M]r_¢ŞtØIí–“¦.''ÚÊ…oÖäú™‡GÀmØt7¯Í*ìt@ŠÅ4Ë“ÃJ²†îT‚vG©“f¨Qü?$©!xs?F6YÍ`fq,uæÀ‚¤}*·R{ ¯+:YˆeÒña®h¹ë'Päì¨BâXu¬ì6(™H]ô\Né]åƒ¨£³ëfº‘¥Ì§Şáäh8¾e‘½ˆÍD2SØ<Ø±Órø*'Ö–^÷sq±ú#eªPMkoë­¯Ã(HêÈ‰VÂXÚ;ûñ³Æá7şUN'™ûÓa…>†ów:g`É	×ÜyM÷Pî§UgĞåDô4§Ê;×‡âÁºòå«˜'¶ \sÒk¸–³<  flx$Õò9şd2ZÒÜ±şV®ï[î_9.<…‹/døÒƒ¶‹ùà'CÿèüÎÃØŠúV£_Ÿl†3]ƒ'<JólÎ³]¾bXÀ;ĞK­]–q›‚ØµòŒG$¦9ÓKrÔòwêu:NFo@ëÚš}óÒ@†fÓ£æOÙ^w·¤öaå÷”×ªA1×´Èÿ<JmE–(Ipf¼ ¶ó>§şoêÕ”XËªŞğÊ¯ 0Tø˜éYz.h‡\¤BíGQ4”5¯Ü·6¶éUíeœH=*'’é},eÄëOÙs[9%3øÉòâšï‚*ÊÆs
–Í¬Ub™`}?”‰&d™Íz¥¡Üwß#†&x‡/ÒM„Ñ”PüÜ•‹_¾oÖ¹÷^–A²fQ€!!Â4“'åÌë•7•V”ëö=}ìÊÍÎ·vŸıåf£õëWiZß¿œÅÍ"Wºo´éº5^ÑÕT~*‰¢ ¹"µ@CI$\[Ÿj¦ÉÚ¹Úx}tmuI—ì€4©»ÌşñV¶¶Ú8E¦w®™ª‚gŞÿdymÒöJ¨5+ÌğŠâÕqÆ¯,^DŸvD¨a‡şŠ¶é*^ë·àƒßÔ9³zÕû Ôñ—¥¸æzzÁøl¥å:ä_`é?5ÇµÁ’Â‘ñí&J+şrÉxüfš€yLù(‘QkŞúÕ›¤1pÚÒ[-Y-xÉJ—ÏF'˜‡k&ûY§]:¢³¬XòíZR™%ñ5g™ĞØÀı}™}` ş {b ºİ?¬ö9+,c|Â#] kä”™9diìT,b¿~Õ0ÑÖ<“Ü~c€$'ëÚx–"Á­ÒUë'€ZAúÍNS©L¶ĞÈ–»Ó+§zXML7bX¾½&Û¯{cˆø‚D¹VôÊh`pË)Ì€|Eb8šQÂ¸í{Ï"Nê…\BH¯•¦["õ‚ãø4U o#İ(´!f.ÎÏµ.ÇÃe¥¹ø-D"ì½FTv&
CË8’ÚØøÿ¤äÌpÜ8 ¢ƒäËÅŞ¸nè¦4ÊY“>fú®_¾J‰ ‚‡©.dë\œ£< ïƒü rˆÇãêSÙRgc“àj.Õy¿èîNùIèWÚ1zb))ZÙ©—¢‰PÒ«sîf¯Ä7n@”´[ Ö³†K	€œÊté..øØëxè2Šá›àiê*•}ëM‡”X:sšº3²ÕBÒâŒS×_“’—Ei9É~f°wìOïğë'`mN©ÙëŒk·»^øø iXE–Éå%ì<*~
>×ƒEP¯›‡E c½†äÎ“¤êáhË>byI‰¢2@– ğ‹4ŸÏÌ/Òœ•mƒ8¾¢;1–R”E–§’ÁJÿ‚ªÓÀlI.rİ_ÖaY…\¸ôÔS­ÂD’›«,wÊËİâÜ¯xUI|Ò³ÃÑX¾ÎÚGz5|ÕH• h0y7ˆTÔÃäã]gHª`®Èæ=¾-åï£Ë9¦Å.CVÕæm¡µ£byò†!Å%ÎƒEÈòÙC[0—-x"Ç{„?àWügÃ»ĞY–BĞ¡ñÊî5¨i¯­<øüdÌÀzşw™Qó3	ÉÔ>äˆÛtº0cfL>6ü=#Åã,Ë¿¿˜Ñ¸ØgWpé»MAì÷(B$/q»‰Éûcó¤ñ2'y”¥wIQ~t;SÂM Â*eÖp	´·ÊÇÈd7†î¢èÎŠÄ1–¯š§eÖÀàgÖ¦À%ş_ùºoïĞ9Í¤hˆº. 1†û>W ¡óJ}´ø+V8øÂˆÀŒÊ·0Ãq6 sS»Œfü*çöPö°Šk¶WÅE/¦ü»f(Øm€ÒÁWÉœÁï â"+$ƒ6¥Z€ âáW^ZæÀ(!Ûxœ©g^OS×,ÑîÇÑœ¡f@P,f>ùH$o…ÕİeÖşg»+9VNàÿÉñ«<üüh&›vƒá¨„Ğ*ˆ¥†yÉêˆÑ«>Èøèõ/.˜Ï šJè«Ğf;4-í³]M¥şµ9_ÕR8<å·T]î9 Ÿÿú“äFD=›4·ßX}ì›O`
µ‰Z„¢À)pÿÉ&[Â¨Ç¥ÄÌU §x¸(›L¡Lê½Ÿòı‹¦ˆhBô@g°l¨¼{Ó‘º4¡G°\ÚJK-ÆÍØKEp£Pç ®€ÛBQõ¶µJSˆÅÍélÿû×J`Hy/×œøÓù|·:Ã‚¨·~k=ÇnñoÓèNô	½õ+<€Ç˜(¡kÙŞáU¬±œ´Ívk<“´´³ÍW>6jß:Ë¾cnUŞ¦¿„5mP¼
zÏ°«ioeèöUÄısƒ1Mâ  «»ÇØ1õÌµsóÛiµ(CmP‰ºz‰°;1€¦±ÍpV?3%aÛ¼1…¯çÿ<]ó~w´®ı³'ƒ“´­‹—Ï¸çŒ‰~w@~kr-€gµ=²tØÁÙJ9!ÈÉª=(.×1‘“zë´ó,x4­Sä¡Œ¬ƒ¯w”çê§æ„«›K¡6çbÍÄ	¶‹ h•ı¶+Ë[Õ!×Ü>·Á‚émÍ/ví>W°×ş„ËÉÈÉÖ½#Å¤ Í“
¿¹Yde=ë¨ e@²ùìA~Ù¯g9’pfaÆ#î„	»–©æ:%{Ú3-ÁòHpœÑÄ áXvÚg}ïNzt'ÿô2*€ˆï¯&°Ù­M,U-=àÏ}#¿£# äaaåb.Ô± F¤¨ë.Ë5Tı„EŠŒÛÆ@¶Ô¢´¾•=Î‚ğŸ!¥ëS‘¦™/È‘É—ÿ.Kÿ—Ò “ª°j¢Èã2ê1~± [Ãé:ÿ.OÎ‰m^'Ô*øé¢TâÛª*a+=KóïWØ‘å‰ËzTf¶>ˆ£Â«İÜS@E<Ñ’°À1|+|\Eé6¿+äF<â1¦#¸D‘L~EÊkÁñ¾¨Üàé&äXDSB®šdœâYíÎlk:/4ºì7‰;D¡EyVäÊlzN#¹×‰ÀÅ­`g_öÖü‰qBîHLòçø÷Äò€<ãEuÃ\Ìä…0Õ}”ÚÌE2-âe(yñ(Æjı„/Aˆ0€73èUùÛJæ"şİm`÷?Ë‹›Gc+-3ä ˆ‰­àVØ{=ûò©åÊ×ÃğWŸøŸ¥Z©_€ Öø| ÖJ0¿Å©š	cñ}÷Ò«èƒöÈáç~‚¢S…aWŞÅá9‚”dÒß<a^_íƒxˆ-¨E±äv´íU³f6H¶q«ûÁ!);p¨#ÍÓ#ö UEÿ¥®ÌÀÕjôÈ›•h&Ó#?fìšd	˜O7úL+¹æóÓŞr©*ª¸@Še‡Î ˆĞEòŠ—Q`DÙïZPj¥ğõ)8ÛìT©ÀÖ%éú!›.ÈŞ}dí6íÃİ„)=½å1.&ÉD¦êN+½aõ¤âöµ«à³Ä.ƒˆâÌ›D%o.íåB¯I÷ì¾[5jú%¿iíİÓ…ø(S¦I&l"•@d—!ÀÒíPÎ±¦4•Ïã*úDqáH6EÚ*ôÁ÷ôê$#.ÉµÚfò“/0·6Æfì²Æ¼#7‰ÉÜ¡¡›Wˆ9fæÅTËË®‡–®Ò)lpCBìºèy†ÛB¡=?+kĞî‘­
F—ŸãÿÔQ½ğAT²@Á{«n°·ªŒ¢Ğç%!à>•9çV,ÁÙLJ2q¡ùäİç¾IÓ	¤|Jú‹‘´Ì‚B î	ÔÜÂéçZSŒ¸‚”A‘ÍIÉßV ,±W’ä‹íÓ£f¤)Ù¶0 fûşÉq˜Á]ºõÜäª;$F:ô5Øß¹'š€>’ĞI'Ì´¡ã©QO/—_#-ÏÑ¹s6ù\¸|ù—o”P9ğP>Å£ŞÁµ„Ùpá¹öoM*èIÄ:pEk×Ã9M·Åg®”ÊR.÷¨baN¨Ñt"Y6‹ìó%Y‰LöKwÓJw
tÅ~ôrD.XöĞ8X„Bh½sø3‡Ù~* 3ŠÒ£§û0ÛíÈ©œælÃs†mÑ³3Ö‚6&qDk|~RJZ:òî:ùşûM‘öÔ~¨7ó}No³ M]Åegé“CÍÀqÍü‘odï`XªÔ'ÁÙ™ÙÇ9°‚ZÂƒtZ™b‹Q°H~%‘¿+H¼ÄÂøøµhKbìÍcdc-^èf±B=·XñJ­€Í÷‰Ìw,wB\óU¶¼LÂü _{U¥Ğr‡4e}D=Ã,Ò_u	hÉšÚT7›iş|£¤=š~–µ«:ÈI1µØÃÅôß®ûØÉqü|Ûƒˆ—"W”T³¡gë£|<-!Ñ[qŒ‡ıËŞp›l|Ó%‰İŒt¥È0tl	eÍs=E•;w³½Òı|ºN¸û¢p`[j.	&•ì¾iŠµYı©eò[†cë9ásÖú„ŞXƒ_ÍÇ¹”NOPF}Š†5?Ôà*ò.	8ä—áÈÍ="zµOZf’ò¶T¼P©ñë—ÿMÃrt«ÀJîlâçf®¦†µB¤ó‹†3ÈÇúàE±à<éà¨|‰ãÄ=9õ¹}¾3H¢D{y
R¢ï·|˜{õQ³ÆEÚµ6n«ÖâL6Ù^øù¬Tßû~Ô’÷âåM¹îó;®r”ûÈ;!G{/üWŸ»Å ió}	]Ğƒ‰NÜøÃŒŠ¾ëØ´0, §“½öÁjwKÌ€Ö*Nÿ&å`Ê»¶k)@Ga3™—±ŞÛš
Ì}ó£ÁĞÎ¿Ö³c¶ÔX?l0*czã¶kîU‰;ZÜxôTèÕ>Â‘cX›iReFYÙ¢:Ü|ãKŒO=V6ı °v_À¦§€c`n=’Cƒï95µ{Uá÷O0Õ¢+Ø"T›¾H£"Yí„ê@ÎèNúªGÅL `õD¹HÏÿs.ä}X‡PÑP±VŸ­`líÎ$]C¡{«l=IeQä©Ôà}Qy‚;_[z';j•ŠAà|tˆÎãWß]ğ¥$Ééq|Ø‚Ûò}2x¥´eî÷ç§ÛX‚ÆF„ÛÉî%¨Š‡D¾ÀJŠØº{‰8\Z_ø“õv“MWn—€lÅfŠ¼÷ù`¶gFexö­/*÷ f^L*]ÌºÀ©šX½I‚ƒÚ3Ä?ç	g_Æ×çñMaébá:ç¹…$uZSoîæI>ò^¶ôQúAìX(înøÊ¿2l¡™oW·]§›½ÑmÇ]ò¬óÎbícòŸúZ¢ë15u.)­G¢³8æÅK!Ğô •c *¾eÙ—bW.R´ü‘_ß 	~İ¥=°bË¦Ú«o°îÒP$ÜŸÇfÆmÈ²±ˆC|ê&¹$‘‰T\G:Csš#:
)ã—>Ù!Âñ}™);bxsÀÖ
š¶á:}brp_A­§/éÂ¡Æˆ÷ÈŸ®W€!fÁ>™·òÅA$ÅW×—­Ê3ãCÉ²åìM‡šÓ™f£êÔ¡GbÑıWQîjNPT¨(ê-°@nªÿ=k4øà¯şÁ²²%¾¡òŞğ(/¯Á€ô“õ  Lìv 5è›é÷ÂzG´‹‰,ãš‘ã•€`XÜ´‰ßˆÚ÷¬¬¾™­úĞé¾â'´’Â³=}G¼5‚}‚6»˜Òo’X½"ywmIIÇø_ÆSÇ\Ü\‘a/©A™Ø9_Œh#7;ü·:X47d]T½±qIPªãÁBBU)M¡Ù0èËG8Ô§c`CÖĞl&|<ıÖ½€¯ßĞM@\Ó5ĞØ\òøéŞ–a¥¼ßĞ'Luø.!VŠ!mn|TˆçæòMpÌógÜ ÕºZ¢U#§@ƒDbë=o¨Õ^»2ëV”¾éBÉQÿ´”€a¤`äÛb‘Èf©KNğ%í9{tô¼üG;=[ùR æ,3ÿÜO7Â¶½Ñ&IÆ[T¿Ÿßœ§í/ÓH÷;¾GzÛ€-ŞÑïŞ4ÒıUáŞ~RÊ”+¹ü„ŞŸjpç¡„MZ»à6Üe¦S7ø<pƒÁ
İğfİ¥XÙWâ0Á‘LŠ¥ €Báv7‡ª¥­Œ,zÏ¶s¼LF½*¦’b»áñ\_¨rÚ…Âòf&Ãšáw +,Ê©d#ø 5eĞ¤îçUûªD™|½ÑkÊ0 Óê3í˜ŞJxqŒ`k;Z`dx@ÓŸ„JSù¬)ûÉé†§—¦|še“§{¡ZÑS=Ë¶ÿ¬IgÅØ ²cãZàS±`ü ëU-Mùs¼™eÉ¼Â÷¥ëÑMæ?orõÅ¤ÃĞñ²«´×hTsòPøïks]ßÕH¯=½ÜkØ_´*…‚ú(gò\í-©0™i´a[{ıxDr-rÍÉ¢u¦ƒRó•Ë¢»\ôu¦wmO¸R?ïXœ’ÀYR0'İCİYvÕöÉ™¥Éáİ=cnˆê‹JAb~›ª±¹Ášß·A¾YW`7W_Ûw¿6œ_¥­ªàòÃãïz8dáòXìW…k_0LLœ³f§\ —Ûƒ*æj'Ó">&©¯gçä@nñy¸ú³ÜyTñY«B}ÚWŞ-ñyóû¿?Yååo6ª¦dôQ•ŞÒÂ¡f#5«p´8Aï»ı*Ô-zˆµ•uæE±¸Ş^îC¬ğZšV\­y	|®{ÈIú#ƒÜ|ed×ÈÛ,VLPíIßRZs•Gi»Û%½~7ìªóf8\&(‚Å¦ŠÊ›ªD×	H]åÅó'ÍYeo¾ÿÀ0ÈâŸÿÅ†H,/Û«‹I7fšJí	‹jéÊW9ºôR}”!pY@Ÿ‘Ü‡õ.·æpÇÉß[ÌÓ&Ş€´Qé×e‘m@V
Aß_:¹üò9r|Ã‡õ‚Âƒ@ŸA¦ƒ<ÉËOFtßzÕñ„ÿŠŞqÕ`Õ‹‡">%¤ˆf0í¸‚ÒIÚ PÄ‰D…İ1jzıÑ3µxy®ÿPŠméÍlnag/Ü1™jg0DDÁê¸œŞû]r¸F"„2ğ–‚@|9g'Hhğ:V>·çº#c$«ŸÓÈoÉ5½ä¬FŸÃxÊã4\ÌÌ'fŸ)~ÙxA¹ğâ¶ÆgïÀ›u­|Å0I©»DàCŠ´‹Yp·ÎÂÍª"8lbyÂ,ıË |A/‹Ÿi+Šş/ã¥$k^‹?+ğ	æ´£Qc`Mt”­Æ°ÿı—%tNëJ¡6B (‚mĞkŞ…FØÁÑ…r<Óğ¾‡ææüıCn´£‚0•”ñDø#HÊ©ãšz¯ôW1ªñÚ[³û3¯.ÌHÒëi@Êú%-ï>áQ<[]­±Î·¹+Ö	d8ä\Y:¡#jÎJg'ĞG6-/­$åaS©¸@>ùâV¿Í`èÈş‚LäZÅâbó×zcÙª˜ùWô‚ŸZ§#éèÚ‰n9ä»äe
›í`ÓKe)\†ÁDE„¹BZùÂMr‚àw+n`ĞÒ”’X'¾Ú4£ ãçĞJ¦WzÃ¡G)û ‡šÀowQ8âlª,nwè2y§Çè,™ >«üç*¦eJNCRã}ÎØ®Ò€mMB¯¾yß
'…Õıf¼sÇs»ï×íá
ğrƒÌÓFá˜¦Şª6!~°ë;j ä×4VDh­0	=	Ó%ºB!9Ğ­oã©ÎòÇÖCyrVà¥—„¤åDè{”cÆßÚü¾Sæ×cÆİÑ’¤×†}©°<ÿæe­ ·¿û¨/²’	E›eUZíO™16	¶ N—Œ—<‚.SÊëÆ³ÌV÷xw_Ç•´xÿrïŸÀµú¯²İóP’T¥Cù*ƒ• ÎY±}4Î`ÿ*
"îKoú^£ôØ‹Ğ«z}YyØI&^)(h–p¢ü-´*v°3¸â”ÍÉÆµNSÖ%|7ì»Ë8øµA:ÌcŒ–´Èmå1Ø€Ìu6"¦We°{uşË~Á0¿nZiõˆ}zwº9§öï³üìş@-Üøéi†>¨Dª2ëñ_èfÿ<¾cƒİWk¦½ğ^¿%½ÚXŸN,+Ô?5ĞsÓŸÉğ7hù%4hàUÕcPŒ	)£M§2n-
'‚tïe£KZš[ªVŠ£ù¼Q FL¼ÄêªÃ…N
Ôèî°‹è~;QŞöóbhNô· ¹ç_%Q£{+ÓïÒ¶5áÀò“ììr]Š²Á0İÂä#ÁzÄ ³=ióÄÆöd=ğ1Ìa\h¨5Ñı‰îtjƒ«¾aÜ•š Â§šn8|`7€‹å6ÃÃÑÒ,¼i»ê`çÉ8÷Şƒ…E.<L,“†Ïts‹Aáyî*?ª49ÍM‡ØµøÂµĞ6~V'”ÖòØ%ÑÏÏ·
ÑëyÓêëÎ~/ï
!ÿÏ®ÚÛf„máFåıÆÄQ@^Šæèh*b‚[|Pn›£~¡¢6Uø+¨¦®á%òzj°*#ÊxjÌñ™klÃA¤í\ÊÒ£¾È›]8ó´%E×­yu?n|İø˜M")ã?ƒgûÏz/GHçİ=¹ü"@ ê>¥¬œy5qô—¸¼]Ø%}Ğ-í÷Œë‚¢R®A‚İÄnmbª%ËU¿+‚aä×ìë4#¾1Úp‘…Q¡íb¦)7(¾Ö6Ú=ÄÒî‘»;)çZ!#x?Æ×‹°u3ûeÈ)S0gú†UØ]`*–H!ê0Iïë"Ö°ü³q+?TaD»œ†®l'Ö‹&$x"5›`ôdI·Òù¬z©²Óö?¸è·€döÃ/pós9>:²¤›0ÿr±)°êü‘Ü Ÿ¿Ø»	èéfnì«*Z>›½….¹\ÎÑÉ(ÿ6™dd&$
D¢?I!ÔçPŠÆ‡j¶ŒÔş6@ÓåAá¾«€ Wì½(dr]ˆÑŠ=è»²ıõı.®¸ÉMóÀ¡Ğ‚ƒ‚òU‰YãáÕö)l9Ù^w)ÿ-èP=ïÇÑ=Ã(Ù÷¼¤ä<Pè~”ebòpÖs('Éiÿ‹R¾vİÍT e Ü5a…g’^'KcjàGŸ§Š{ø¸êÂY%™­'Dñ·7âùÍï>eÊs*zNgŒA2?‡>üÊêVtœ	îâÛ§¤ÊşÂ áE>SÏ¬@²ø¼•ƒ1İÆä!oÁ±D¸À7+x@:âœ¯å yßÇòş¿ç8ÆPHÜwœxQ,ù|úu&X‰Y
3ˆõÖÒÀP‹Õ¶Gÿ‚ úhlªg™Qª«ì|bÀšİÀ<AOmıEEÙwG„Ç»şŒİ°IÈ!¦a’íâã‰|×DÊÒºX€¥¬E üÀNw³.6 ÷;äòˆ¹zÇqÂ“ÓE¹qp²R™é
½+\¶˜³Ş­JbuPV`}i_ÎFä³²ºÅ(°ó+kúLÛoU'qæ!”Ş´GazK'2W¢JÓ	ÎúíØøZ;$	8pı†Wj½¥å„pÅM+-œt##¢Ó¨R?89hÎè³1Aî5ÿæâa7@â¸Èî¸a_ˆÇgí×Ö\Â|C´
KT(¹¬‚2[°é*ëÖ+RĞ%¦?éW^@-îW×7àŞÖU«˜D½e|¸oûLqû2ŠÕ¢¦~]Rì!†ë½ÆßW#¯®jÛ"éjÙµayàÙÅ"8^khŞ™¶¹©@éƒÕ¬?¨ï}JhzñjèÜ]?íEÔÔÀêzb“7¡‚H-ëÔáĞëµñ{‘]S±·UşŞºØû
°ŞhQà{Ì°a>-ºlšâyº“"y¢c\¥²'=Lı“;“‚×Bj—zú*/¯H—Ü_¢Ïj¾ĞZ×IÇIÂå˜ú¶ÈÆ©¹˜~7pí=”.‡‘¿ÅC*DİX'à§KêëùÎ;ŒN9Ùù¿W×cRÌ"ÅÌº%”µNÏ1ïVï–e{×ıŒÄäi¿ûV­ßŸècPp<K(¬ÿw¾¹eè´5’	ß™9xĞòAËõ§bÆßy*—œ®!2\á…¶ì±>¹(‚%hV¢/j)ç
	;#Ğ˜»úÁõüeS¶€ìİ(¾Ã^¢¢åY*ù ÂÖHØÖ2Ô)÷Iìï·İj«&
Kü´İn+ÅâTØÕÕ«EÏ—’;†é"¹|ëfp°& ôà5ƒGH9`ºã£Ù‚öà7÷ŞÙC†‡);±ë	×Ü÷xãú°ç¡Hıø»z“¤¿Ğú:t\ıOöJñcÆsc•sñx¦í_~°@¡:lpnĞ®æG5¦YxÎ$Fxõ-²_³Va|Údæ4FÉØ‹zÌ›SŠ²˜Û™Èî{ÉP¸G£D¶ $ÑYIo”t”XÂZÊœ*´¬6E}Øzê#èEÕ={ÃÅÀaë?¾©à)‘9ÍLÙ´İ ºW!şI +#*¶9ê*X û–
jôæ~=¢º DœD+ó¤WRy˜f&ÕçT^ô"ÖHí0=™~:ê&ÄjgM†ï—ß>µÌyæyËZ%ÙËFÑ|˜j¯ŸÌTrQvĞâëNªÙş¾`Å#tIO–ˆËrçWĞŠØÍµOKÃ£"èÏ¡Ü2şGOe>T×¹ëÙÄ³áP?ûlKü—M¸…`”Ï¶+¸û X“‘=§£¹)¦¶Aæ4»vohÏrÃq-wÊv·6¥Íî´$³Ò¨ Ïô5ãŒ¸z$$øDG”€Ñ†åC‰qc;7t–6¶Uï¾ctÍ?òeÀ~ÀÄLÙ¯·pñªâ÷Ø‡Şd#‰–Tı¸f÷„núAê''µÇ—Àº÷¸7gÌ›ò¶H~KEş
A“â±yà,‹N¹³‘@PÂ¿ó³µqg^K4BO=m"á“·„ñqr9Û7?´w)ú˜k-w,0=˜—üê¬îã”/l+€lŠlTĞù¯6N¦¼ªœkËÓC–ça„•\[¦Ÿ-Yí„<êĞ¯¡hşàöXePû±Ô+b’ÉÒ]ÍÍš‚¤gÉnÀ.Gq9Om[ï
D4à¡©¶ÖªEJ¨…Öè»U·ÅY]öapÁ¹„—§ÏÒ`3GE bß¶*ŞK=Á²	!zeöìôY±êvdrÈ€îş)˜³q'„?Î##-ç*ßÏ=‡÷j`õk{¤Ä&••ã¹êiKÏ÷ àG ë)8ÛRöôò¤q–gìŠƒ7«ëè‰ù<`:Øj%ßšî#¸¿û‡`ó¯W<‡9.(y|ûƒ»ï .‘Â 	ßúÃ
œÓr¨b”ÀoØ¬ö¯Şš¾«v—ÿ˜¶1’KÌÅèÿ£3´…bl.€â‹±¯:P.yŸÜà‚ÕóRjvĞÙ•‹Ïâÿ¤Z¨Öƒx@gnaš¡©İÒÆŞÛe‡‡FZQASÚ^7MóÓh/£-sØh'2)°ën~9Œu×\ÉåÕôªÈéÅ;­x|¼ı­“±-eJî¾CçÛ´~¢ú›Ëãi½šu%p¥Ê6\UÃ6UÕ¼Ó˜²HÜ§1”†75;%òdY h“M ®/u­w§ŸZ¥·V3/ÁÃ]§=­¸¯jØğ¤ÆJÙŒ§Â…Câ]ŸÍÿ&R,väñEĞ\ãåü¨jCKN¾ìzLH©¿ÿ3kšoÜkCX‡h4€€ì¼¯RfŒƒé?¼®_a„¯ÿ!{ ÓDcşD–j,Â$óšblœ–Ñ/sµkš7)8è“A¹OÚšúşBZ#N—–€åŒòİ?¥ÿÅ.øñ¢ØK0gˆT)¾53^W¢az”Õu#¡ „f?Oö«—}Ó’g+wç²~r¦çò¾^D}S-¨ëÉOâRqw>Ôcå‡ ´èuP±·¤óÜó"Èš“sJ&_Hz+ìÊi
ásh2¾4¼bJ²¡je£%…¦ÆúĞ½Ü7´«M±º^Z™‡L!À¬ú&$¡ó‘¿OÑ3ÊİÕGùá±½8Ò¼·"çn0‘¥3Ÿc@ù½2£R¹ Ñ¥¾DŞö±j¢É‹¸U4€M×õ…ë]ó[P:p.¼Ãu=õÂi±ÏÁ‚íÂÁPî2“tíSÀV½¾ÿ}z
‡ =#16ÔäW™,\ôì8Nšmèİğ	puğŸ).KGÄÿ3t»b8ïùãÑê
UNgZ3îK¾ïH:]h²…ÂÎòºaµ':¬Y€wøÂõX¡),LâF•ùtõL¶Ñ!×I÷=z¤ğß9eMÕ±èÉ…P8ØãFz_-Ş†ñf1ÑÇ‘Iëj! ‚(~RÔËˆóØëÅØ+GÁÑyFw+ŒV1½Ÿ»¸h õ2çÑZ·ğ÷¶4Dæ[ß·<ê^ét­M˜òa× 1´ûì‚^øb]=ø/ÙÑú¢¹}ìÙ2AW"|â€.‹Mç'c10sîS7(ñV¦Tœün]Y”îØªS½2å®]›”}¢¨—ÜCo‰nÀKw#µ^‹¸ŠNê\ü@@íö™Eay· Ô·r£Æ¬©-İ85ñI•KœÏçû?Æ5¨`sšÍ-ñğ³²R=:Ù`oNØ%^qwÉª= Q¾(ÿDºİ7:Ø=˜0,Ë
N)=9šûA°¦qÖy' Eúòñ©ƒˆÙzÁ­:è|G=õp;\0c9œw=`1Ê^ƒ„>K4·®§Š>zÌ°ğÍá¢¶*É÷˜Fè½«tïƒ¯$ n#€»Õ×0ƒÿ>wî!;úhĞë Eƒ+ô:Ş–™Qù2ŸƒÒ<iõ‚§=î\Å:øWéT-÷5Ï©?ú¿GáËA+Œy£`eb8S]dky<%›ç2¦Qÿn¿#Àæšáa©(1d½…>Óäñ¥ÔP~‡ÖÑ½`»`{Á³D‹îñ­òÿÀµsšivîÇ/K-¼Ü¹‹F§u¢Û"Quáö‡şÌ¯cI€|6ııºø3·!ó¿˜ç–:½­NFy´G/'U	ÆüwZ(r©IÄWÊ§¯–é{Ç©·Ò7İŠËğqCÂ‘î09s)Nrîd<Ÿx©Xà1µ7³©ùú}mÇ¤³Ü³È¦<)íl«Op¸½ÃB ÙCrzTeOXàÇõã.¼¡^¶nW–³,	Ad¡V6ê#ì…fXÅâpŞ´²º·ûÀÔEìòÊy±Ó-¹ğc­€.Œ­`‡•¦H¤ø‡p¿¿¶éAsÖtVR6+dÈG¤Ğˆ°=ŒıVà….¬ŒˆXHõD”œÚK(¯ÉPDW~§ı³ôu@³„’6(õ"à˜üH¨2|“<Ô1ğÓwXuÀWŒgéJÅ3 (~.FñvĞPÔX‚Éƒ|Tsà¯Š¥!–Ì$€ZmAÍ1¨•i0“6‘yOªêh:Ûj¡Òº3ò³Ø®GêO]Åâô›%Ë^qe·‰½jkd"yì,é;ßÄğÇ’É´¢ù;ê¡¡«÷mÖ</Öé›Òäüè ÿ‡`lç:¨[Vê jÃ‘’ŠïmDÓó‘SŒÉˆä5~oí‹ó÷‚JÎò_ªTzå² sGEº¶êúò'-ÈJ¼U¾~0İõ³zav0›¿öî{Zão·vËâœšğ#Ï5+ás•ïyÕé>5…ÓÓ%ÆŞÙŠ¥ÕuLåDŠÄ±#nu¾çÆÍì¹ak¼]	‚C$.§(dã«8dMhfÇŞ)ÌÆaÕã.ÒU>XêˆÁŸNëŸ¨4„‰©°ƒY
¤1ã½—¦üE%(ğ1—eê¾F:s(LLw&,å2úÿ˜ğÃOºš »Ş'	Ç`–í/9ÖNßÏ÷È’¸ Û™òıít@›XAL0ù„§9´œÚgÃŞeÜ–‘dªÕè t¬h‡Ï¾OeÈ–ÇH‘©PÉdSÎÿW Í#ÜÂòöğqµV8ÁúúÎ.ênz|’2êÒÍ´J…H‹ÈGZß6+tFvRü 'f÷è¤ÒX`kº²-/
Çğó«ñEwC,Ìlî1G­Û¹Na)®ó£§?æIl’‘ºjDƒmc^x¥-+÷qò€¾'»è3ÎÁ–;%Ÿ±Ò¼Ø¿*÷p-éı£7ôìÈØ$Ï(¨ôßv[´©p ?»ë]ò;F îpçÒ4 ˜ÏÛü5Mãa^g#¬åÿı0Ú±>{Èá&èşÁ˜Q“½¿Ù‡ÍÜXIbHp?W©./Dº#dsşŞJÇ™E—Ğî÷¶ÄÅ)”<®_&âßwMÍÓÕWã)ƒ€>²Ö0–L	¢ ­ªÁøé6^³9š¨n®AÑ¢ù’¡÷ló·wÌx3è¼™(§‡e_™Æ5såV1Uú&ü”‹¦¯JáÕ¼c$hÆ€ZÌéZ|ß„ûÿ"³±«­Òs@î¨°Ø’ËÔ¤¯ö ÎµŒ_iô‚)-5['²fÂ¤Ûğ‚xÊDêXÒ# Ek”&p{•°âÑœ¥=B&õaNnãá?µo±úä+¢£º²f1îÑÚz-êğ\È?aŞğí!½ƒ~ò;K§~™{D_m3EmF^fŸL?§¢xôşGXí-FÕú¥iL ó¦b_W_Ş(©j”èØ×	kê¶V…2óÖß¸gñ’:‹‡*æD=õ³y‹ó¢.Í}°âkæøfÌ±X{±­Ş¯3Tá²!U#€Ù«Õ6ÂtÖvğĞç“ŸÛVş©úÏ­hbV[šÌ8‘.Y: /î–³XÇèKE™cæ†ë!‡İèj@6ÙO{@KØÿ/^Ã°”’HXÌ	#Ã¤4ó¯Â¥zş£úª„Î„£ı¶íÉŞŸ¼lMÒÙU ¤ÊÛ3::ôzÿ×ÛVqU;ß
dNBİ˜}uŠL¤X‹:ƒé8¤V$·¡§*P¯»3Q>Ò°J¹¶ô´)qüpcşºJ@7ªSs RÅ[ˆ)ò”MĞß\ØŠ´Š ş®Úä€Yúnñ¦y³J¢­-²i¼kÁÒ_i ĞTÅ_u‹.‡ßÍĞ¢ñ365İ>"jĞŸr¼³ı˜ÖI¹hïŞRÓW‚XåY’!:‹Êm	óâ‡
„ä_Ö¶<iÑŞh>åµË&ù'8ÈÏ[mÚK×C¸&0ÁÀİãSbC˜01ï,íıÿ²š5ÛxÍŸ…—êœ’ßæúE›Ü™¾{92Ày¡s÷V|4}ó/ÊÌcª9Ôì1Ş§ò Ö˜9Otê0±«Ø:ìEI+ Şõ ~)Ò£ &j ×®äòåq«Î¤GšÒ‡uë6s¡PŸ.?Í·~A
D™p<Ï…îè0S8Mí-XSiw›_Ã’‘ëcñ¦õ¨Ëgg8¬, t™I8‹Éu½ZNKĞL’£d‡ØGĞø&°Õ5Ñw@¦t-ˆ•tÖ	bş.YÊo„’]Ä1£õCÏ4öi¥2BóôTáPíÉ?`ÇeÇ-.G×cˆmÛ|M¨gt®\©lŸ;ë®ƒˆ	¼ü4¹»0¬r56SxU+ó˜Py &UÈªĞ'#1$ü÷êTÍfc ŒetQ/í÷¤"[?+­di°åÀñY'ŸÔ*	eCÌ{08(Œlš™?]Ïæã§Tq^>­O~¨İküæÁjÁ0%›¦Önó}pİ„ä_ ]¥VÆ:H'ñ–Y´FÂwpşlßMSy:pÑæEÑb$Á]¶®áJôBê¼gSİÛy^#ƒ7e†¤ïÛ±8YfCŠÔŞb`Y»
h0'Ş¹—`úƒK1ŒR*-aıó&4ÿĞBR¼˜ˆÙ?Ä‚ æ[~uÙ:¾ıï¿Ò¡úy%öÅÄ½ Îôâ\Ÿ’‘0­fD©±±’‡Õ”U½ƒdLkeâéÆF£6©_ÎYR]³ùP"7åhç¶ZÄ¦ú&|C"-øKĞ$ÙÀR&{¤{¿†GU¹¦AËÔHªôÈzˆwÀæİûøŒöp4uíìÍ$­2…”3¸â½âWf~û
wKşÊÏš.&›?ñåQÊÛDR›”Ûãu„È¯Èè¦–sÏÊò¿ñ
îƒtÓ±,
3p‚m	
ö¯
0•F¥„86²!ÚÉ;‘Ö’Nû‘ô
õœÛ RNñSˆM:d›¹ O
JSh Ò¼äÀ½/6¡¾Õ¶mw¯èÑ·\W¨²êòİæëÂŒ¬9Zgq\:„»Ş‘¡ŞkÏ¹Ë’zZq¡¬-ù	nÉû7^t®{+s,É¡ıhAí]7–+XE–Âa±<ÃspØ4ë«²ŒÃÎMMÖºÔ*îíPŸ*oP*á6GQÀ[r*9»›!'ÉÆ©Õ	D¬sÙcÇ'ŠQ€IÓ/†OW ŠúšÇ_×qo@Ç{XW0=ÿzº†<]ÚHcØ1j•òd½x5lpQãÔoè	#,ò7p½†Y“ñXTjáD×Ú¬‡ÌĞJóawÃ;­‡tqLù?@4A¹@³É>G`@‚:’…“Îİ’Oo 7ÑE5Ñ[q¬TIZdØä\,?WĞµq^ ¿Ù)ĞÆä
QÑW³n}§0¡[6ovRT?g5Sÿ
Lx+'m!ÙÔ%dKäÈ†;QãïffâD»î^iµàj~;ÓF`»ñrÇ”]‹YØ5­%ìşŠÏ®°5U¸#Œš}d0÷2‚œF%ÌüÓÓÒ(è.­HÉÙn£jı­è>Ò°¥»—3R¯ÌÈrñŞØ-¿DÆÛüËŸg‰¦,¹©:<Çn¯<Æôò¤çÄÜ,†„ˆQ¾~ÖÎÙ¦}P„÷R×HÀşrÎ¢æLD²í¿©ôo	í|J)42í¦ØF2&¬Œ5Ökª<©èÒÑ³ËòªH”ş`‹õÀ	~±i0¼. É ³km ·Æîf@hŒd„éX/j
XÎXìNÚ×£Üª5D&·{râ6Â™Øò¥ÿp[)É]ë}áx¿y¼!zˆ¤Éşou÷áğø&_5OÙtNùtI×’xk×RŞ›×*N:SmcÀ£›àŸu¥™a}p(¤Ã‘‹AT|ê µ“­<FÕ¹4yÊïï1FÌ"šW¼Ä“l4¿½#XÜÊT^Îl;ŸÛÚsÔ®ÅKÖÍØgC‹›:Ê™ÔiUÜ%áÈ]f­Â€•.vó·>Óz0¸«‘,ÿ„‰!0[Â¸~½×£3bó‘œ%êWN®•3ÇÍû	Â¶ô.j5ƒ0lBëŞã4j5°ñ¬İ|l6Ù
(ò.D×˜z¤•g%QI#=á¡>bŞ¢Ø4‰)#NXi*É;IÑ¤Ï³7²|2
n«"Ñ("Do«’‡Ôj>¾e°¿íÂcP
(eÌ½’¿	âÍµØ æ{fÃÖÎúrckö!úVîb˜˜¾0©Y[¬:ÌjÍ>TªÉü‚\j]1WH¯9
¯Åo‹šÿk†ŒK¤9bîs~/¨Ìsq7Ò_£EdhêË†ZÈ%1é¯U¯`ŠóõÔf6%ıjÆ9E¡ªív<İ©¾?î½Ÿ'v/‘Â¦üf‘z„¨è^††”¾ß¾p¢<§@ÍÌLÊóãIU?ÔXí¸d¸óEßmÎ´=ùçñè÷A›Nb—áîÍÜÈ(%‚@}ä%[ ´F·5R¤YMÃ¤ÅàJŸiç/8ÇEügU+ÄšC¸ˆÂùø˜áš!êIÓZÜ¿;‚&¾.ëFŞe€LêsB—û>ùw¸ş´Ş¡›Šª= J‰€?•Á’Q‹Œè–ÄM-¼KÚÖÆÇ¹¢Åáh%‰à5¿ïäõngMäË>¨(wMûæâDŒlÿ¬gŞhOÖY¯93\q.PæaH:Z] ıgÿ¼W¢|†'İg -æ¢wÚÕ0èzHDGS›ª /Hù#N¯ÌVsë8êEÄ²öùp¬+@4*Õ ãïwñ^¡fµ)àğÏ¸$5hò¿{ÜbŸÃÍÑß’Q5_Zz´­¢í>päÊ,/‘ Vm4»§ió’B,u‘Vò«Çª"¸ûÑÍv…á2si‹_²¢½ùtUÀÕê
½€™C”üş"|C²,¨qŠ¨25ŞïÓ–üï¬ğ÷s}|Ú±y:•¢{Ü’6 F»¼§4.A—¹˜9)QfÃÍ¿< š‰ş|M£¤•b®VØ".ÁjmÛ…lgënÒ·ÈBöV®OÓzxö÷Vdê‘-®Àİ)4oöu¬Å,º‹Y%7±	’5İ5 ¯¯æ=æ»¡'¢;Ç—öİl«‰ø8	µ•Â4m'¤s.k^«¹-Èzº0ãz»Ö¿ê´È}Ö‰I·¨O!Aı}93ÓV©8aù*oõ8XŞËÑ’íş&Äâ3Â‡‹$¥
—[vÿç¸TÀâŒèĞhˆée[§Çí^r¢_' uŠxÑR'…†åÈ•83"ÔXÅ¾”Nğ	?)@€'Ò!Bºä”C~d]²äĞÈ¦õÊ›¨ûq]Ãf42AKà#³ÚšXíå0d­P)Œé%@7µ{Í¹4»fZÏ°Ì³nÕ2®$	1m6 ÖvŞ“'&lÏÜ]b`R˜Ó<jü|*ÄÊ´ìı\Qôy7Ê<ãëŞÎvæ¼^oûSŠkıd¼ÜƒœºeÄ•M#¼Ş7B†ÄùùÊNn?á°¿~+ÏOŞsædÎUb¢÷Z{²Oš&_ôğx™†“ÊŞ¹ìGXå|–2ÍK¥L©?òouàimEK‹¬O&hà£TšY¡ˆ•ˆïO/`¾‹ƒÈš'm‡¤	\şÙE Ë‚m;.ô3ÌñÎv­Ê¸¯¾FÒğ†CTïÔøc¹ë/©ù9.^½¼:è³ğiÈ£İçè‡…ğ~ö5ĞËıênÇV¼‹Pø©ÿ›(,âaGÚ_€Sİ˜†áA¯²|ıéì†jˆ='jÌB„#© ZQå³Ê¨iCÏNğY^„&êkI 5l3]Ê¡Â*^â÷ì‡f„e‚I:£ÿTy­“ˆEÊ¨¿Ú¤ûWc·ÂŞ‡•‰˜Íâ{]ïóôí7ôR¸U ‹ã1ˆöLÓMZ"
êJ€†Äá®¥ÆËóê5o±t:”¯š³ä–`.Á \UMe§†Ó§	0l·
ê^­9/˜·$B±9$qBÙxJ)E®ÓaÙ'•KkÆ–Atij]Mn‰û12+¹[H°ìîíI~BµlcNU_´QOŞ"¶“Ì¢ŞÚ¬€¾ıÕy>w÷I(Èp~Ú¡~Bk+ ,RMaGev0	‰L‡ÑJÃN‰Ÿı‰A­aåPïù-zE†oì»zf8%Ox É÷\€n„ñ
@‡œ£ <JËÃH™j`!8¬•Š¶öĞYø±ĞdOm«#Ë"5^VAW#º1¸8"‹÷í.ï3*?4™ªÿ2À½¶1¿_ÍQöû‹úQQAq1$MÅâç¥ğ$Ïß9Ü½?^=Êkòñr¼¯ñ¦‚)	ùîÒ«­Z$ı–õ:Ct‹Q8ÂÌ
L{Ñí}p¦3’—™‡¶²9uùŞİm‰†Â‰õŸÚ¡öHw¤5K­>[Ä§RÍEœ¹³º-g¹Öd)of°&›HòUò¬J£t¦„	‹{ØEñíR÷Í• 	~åù	~_<†°zÈßÍ\)ÈÃ<ŞP)µ²÷!ÕvX5Ò®ÒÍšqs°t3rµ)Ö]ê9Å2ãÌùä¡}Ç+7û»¦îVH	I(&4,ı{ûü!ó¸ı«œñÂà„‡ØvW_3¸¥‚¢çPºÅ„SØÈ½Ù0ãkËW±_”~ã1ÌÔ7ÁaÜìNdÖEõìL…íæ9Î_ƒ4gmåò­û’#LHÊû¢´¢Í²·¬dÇú$qÈ#c»cÏeúWtö–ğ}L³HS²®8v.êÔZÌàùWS÷*QMµGÕzaşlqu;ry@i{.rLÏ|›ªÁ¯Éìd&:²>ïqŸYbÎ¬¤¶²¯{Ú(å©¨ÿ çQñ.Ä­¨ªƒ1dÔ¶½÷†¯RÂuˆ´ô{Ğtß£*½ ›aÎiîëñö+‰Ù| ¾CŞ«»ŞÉ8Ÿˆ4yàÁÜœÚzõĞ‹TÍiğºø¬Ì°”EŒuZÄş_òq—n	ÿ>E’d#¶á¼‹Å¦ı€wgÖÔ—¤•éLWœ ñ÷~íPO´–{!2ØÃ±,¢…—ìƒ·QñÖ#;´Sõ“å*ßì¿<K“s.7£ƒ[b´üëÕøóÀnš5ù6‘·çø{ç‚Q?=Á d³8;²P×Ç÷Ö|}9€ÉO¸\C•ˆ©xßUKˆûøôT´^€qZl½¢zNsn_Ş§’F
ÛZ2b ®&
yÒWfÍÆx|º
”„£/°rã%ó“F–-$Êš.îÌz|ä0U ÔÍ˜eô,¶ƒÏ
#"8izµÖ{Aé}©<ÇôH¥5Ã¨Û³%2‘8Ğ7ñæ9¶2·sšñ à²VÏü»Å-}ˆÚœg¨~„*ÈrGúi¹9iğÜK|úZúRS«D•;&:¦v° ,ÀvºÈ~OÆÆAÙlá‚°{ÖÈ±N4Çï½×XĞ¨À¦´–Ä ²¿VØ¨ëÓ†“«­ìMì3ƒeÑ1£7†¾üW"¶yRs4µ;Vó´4˜ÜÁëK±r òÏr@€5ÂÀÓ|C^”Æ²æ:cúBPë'‹ŒüC"|f:ÍÕĞ­‡‚°ßšZl?°b‡qvé„àÿvM	q¦*áN¾uÓd,dıÍ, êÂÊ·üÌ..×ÙÃ`i”·R3Ô`‹EÿGc0Ûyît/P—Òowş.şBEñ	v±8ôú§sEq&Îwø=()äNn°¢Ù™UOıÜôâØ5PÒXîÿûdĞ_ÎÌK£[ı¥÷N‰×e€™ŠûHZv˜Şş ›ÿâ}Ñ±jÀ«ÕSı*M˜=ì¯¦GğMÈt&>z5ÏòHDÚŒ×ñF&şÇÃnj„R$ ´8>/ÿ
•cœ‹núÆ È&Íf$‹ÜGtfğíxÏ¦Hå_ğ'Dm‰9—ş&Ú_¥|Ö‡cMnĞç7İ»:Â…uÍa…ÃœpV¢=ì6ãnçü_¯6İi¿b²V(7“†QãPÚSÇ	DÜÈ`ÙB}•*Q]à®áïLôÿ>\õ¢¡!èÜ/Ú¢y îû š”òüHä¶Ëh;i‡ë­ã2wA¸ kW»'¯3ıE¯1uaF …<miG#X³Šß‹öwß4‹‹×Vd!YiÏç*É§l	­¿6ã/ùÇ
ü1Ùã×^>£™”â3É§LO1€ZÂœjH­ß„¹Ëò¢ÕjÅ²`ı0›N8ë^6ñjë9½˜p­È‹-©E’’¯˜RQÿMRÃçPö®åf|”hı:‚$ìÁfæÅŞ¾´/m†hL¹w_T­UŞ«P{@İùİ"Í¡51ıà7šÎjÜczå˜	—d.Gh5ÑÎÌR–Øƒ÷¥øÚËH’÷–tÖªŞ;°ëöï2¬¤œ/vW·…ƒŞb{¥ ¿ˆK0fúË,ã|Unèúl0¿§ü™Û3•à%øTÆG¤àÏŒ¸å É°îœÖ2Ú[ÊªŸGß½É?p?†½@q³HÇûCÙùOíÀÕ´ÃRAiìhYœ+Ü£òXM¡˜g×c¯ÀJÄ:Óù‰£6@×llÑtmm4î¶ê|uA„u¤¥–q[ü2¸:7ÓüATQ©Vt¿kƒb_qg†mÀÏèUÂQ¸»`ğ÷¡V#üS!ŒÃ7hQ…RóÏ}õ›uqÅï¦	 ‘¸ö±¬a
O®ß"lÛˆ.…¡wU0<¸F€†W‚Ï"±h|¨^d©&díÆJ©FQ°Zb%>ñVÈ†ºRoÜ©$#®[+™±LÊpâÎMi•<wÎ¡„Ê£÷+å—a× ‹Â
øôªS:.:hÒX(	+U±
Q­ú`©êu‘“<™’GµìàqB#Q™0w/fÔW]”ĞsnG¨”AåÃB²Òº.,ßÚÛ½e÷ÊşíĞÉ®ğhš\	ö´Û°[‡¡©õ+ÅÚ~×¢ƒ\5­ü¯LL´÷TIeb	-„ ‰ œ{q½÷õüåZ‡.Hî¡ŒEH”	{_÷C´TE¸Ä…½v„s½îôà©ú£5]péÉÅ™VJG‚rĞd7Ü¦•wƒ´
3¾ ÃK“6³ ¦J1¤zƒõğü<Y“x™èƒˆ:Å‰¾Âjª{òw.ĞO@k¤]µ8´Ô«rAEä±É ß“º”¿v3òÔÓâÆªİÅ•¶‚Ñó—5f­W³étSşUç6;	 ğÙgŞêõŠk)T=Õük2{b!ó´¥Õ™#–+y|Ã¨!hëN·Y‚½·ÿcÁ¤¨€
c«¸x@aÔøÙ£ºÄ'ÜÌP$Ò¿-eª\¿
|"€qµ‚Áh•ÛıÅú/"gúòPÛÅ[)òÆŠjËv%+ÄD.ûGM¢HV‡×¿×yfH`¬­sNAXQb–$ÿ¸iMcÿ¤ÜdçÅìÒâHğ%‘Ygãˆ¿5'M
âĞ©6–:òşBœG÷\oío1t¿/vÂ:´u'ÅÏÑd}¦îbÑ?gyI.¼´ïqkFvÛÊ´¬@4H^¾À&~ş- Ş´Ÿ×ßmÿÖìÚ‘Òe9]iu…÷` ±ÿ šLs78¬VÃ$ˆê+f¯ö½´×462îåÄÖf_cˆ]Âmµ–Õ[\rk5uş½vĞpÈÈNä(
$»ö²äÉjÙ¿£¤´ÿŸyxõ+ûã¹©¬çğŠÓ4è·’ØgV t–DçM=j$¬/£œÄ:µ#!ú€NE¦ˆ•NÖæz±‹ s­hÛÜ6››ÂvŒÂÍjò×­|¶±ª)µÙÿòc`¢jù
æH
UŒ*Ûïg‚j±âí…ü@	‚óF§ÑâOV=áß›$?úôœÇJ§iOpâßK]˜1l8|„“ÁMmûª€„÷ò„ùÅu»¬­eñ½jì ó‹krêtàÿ˜ŠÀ»4¦ ‘•–1CTŸ…†`®“VòÃ;;¤?ïºª×¼Ï,÷9Ğ¬ÕüªTÏkór­mĞí]=H‚B„±…z•Oh#‹ò[tíÿjhº³]¯(b^ ç1P|u¬ì8@ÑÁ˜Õ]<ÁnjĞ¦(­Gßÿä®ÊxL”²Ì
RÓ˜î¤ï0·¶ÜkKsø6ÉÎ¡ÆãÀŞùê­ïÍÇŒ¨DAÎŸˆœŒ÷]õÆÅ¹ñb_zr“ÿš1‹“V‰©½¶!%êÂôl§İn‘NÖÓ—gËq}«ı”.ß70¼œáV°¦âÿWdØ‰»á¥i×z)¾Ü.”ĞO¥”O z(šÁÅÀ`û§Ó(Kz”n¯ÊœÇ\†ºòjuÊb®
 ¦ß\)f„#‚U·:Ò–7J,GÍS6õ€·™Æ	ja1.¾µu{dhj;–§KïŞ)£uÈXNdãÖ‹¯@cnÚSÅÁ‚Œ[·YTXK@Á%èCº®¯LX@\z{gAÆ²°:{ò|²YMBÀ ñˆj€_’%Ã;	¡w>ªs+µ”½-¬óÜWÂ¶‹i¥ë>ó3Â²æ~İƒ«½f¬ˆ31g_…:­dÿ™ôçt˜Å¯ï×»qªÓØ]ÅËF÷’ûÇ‡ÓÖ2Õú”Ô¢KË¬îCÌn’½Ñ½?	ó&½W'¥ÎIÿz J”§}Ò]‚>‡­x´kZ*!Å]da”…Á—ÓDNÛZ 
©xÕ§^ìĞGŠx™×Ø˜íq"À g—§DQ’rÆ}»}	ì¼,gÌxÒoßgŠ‰ºÙÖO« ‚clcXX\ ½Á[hêLC>s¡®mÆ/ëSbŒŞ„Jä”é‹ƒ+@¸7¬ÎÇ#™9½oí™6X˜ëD/†¤¶•Ò%|cJ“¥ÆÚæÔg×Ú
‹MÌÃ'9'ÛOä	rr+w.ü¨nÑ±|X¨¨ñs»€õà)—³sŒYöïA^ÇÖØ¿é™âùÅ›t¼ñ»wr¢ÄÖê#9æ}J§<4r´)!gZ,ÛõxÕ€rYÎøZQp¬²‹ë	N¿|á8CkQò&yå,kIz¿Hh¼ØŒäk›NQšGö5[âˆX¡gh/ièòÂ™nr”(‘é?äG@%„G0ôš˜üB{Öë$ÄNy®„¨y¦ÿoy¢UôVæÏöx;‹VSº¾Ã.7ü]ƒTÓÇ­y	Ç64CöÛ•j³á¤
·º¯Öå%\—kGÖıaA®Ë&¸3Nd„Ÿ\\Õá’ç_ø	ï&¦¢æÈg!Ğ¦¼µQ*0øëîYqâKµÙ„™tŸ?Òúuö'¢Pcáfl¶ÄP;5˜}‚Óóáœî‚H³&œ.t+­£só,®q©åì?ğÍpKCâÜÓ”²iOÁcˆéWf…D,Fl8÷RB¹¡«ÏOÕ'/zœî%™MÄåºáı•1…O“s;û)ŠlÖY:*$m¨ŞîéV€g˜q]Û²óçXÔm#@ÿÈ]5ƒ¾oê—-Y–p<ğ\èla:üÁ+ü{ š,´PíÍZÖÚC«Ï=m¶É^öbn®œ†?RcW"5‚—pQÊè[üÜ‡oo‹ÛÓ¶¢·T…¼OÕœÆLXYıú×?ÇcÇ8»vZ™¥°ä×¬eT-X«˜dÃKDà®‹ÕD³c½Ğ¤n]ZàÏvÂ±GA5L :¡çäüÜé3LIIªäæ;Ñ©°OâZ©¹ÒŒ?ôzµñÏ/à ·+–°,K×=¤PªÂ(–¡Íú`&rM¥GĞÎwò,>}*î—æ4ˆŠ;è¼û’nXÅ#ËŸ[|“ù(\İd2/®¯{ÂİãSÙ.«ÒøÒX)(È—¹K²Êşf¿·”$õI¡%|L¿XuîË‘×bm!ø.RŠ9U½4½Œ.MvkŞIéC˜·h¡áÜLŞrÃı¾x(‰§•Y7Â+ËF-Í¦ã®ûşÍ€)úm¤Jíô{gM<âĞÉüÂ¹¢*;nâÒ‰ÒÃÊVãĞ‰±–+õÊß…GŒài¶?»ı\¦}ùJÄQ¡63ß¦ßlÚu)àæÎ…´‰øfs”ü}aªÓìŠ”¤ài¹,Ôşğå˜[”ùé[Ô32º–/•Ò§ã½ARˆ¿Fi[Iß–`æ¹BşgÍl²!HaË
J¸s‘y+·tÊšßµß‚FìØr•D}Û‹;pZ^’KLÇÒK0ê˜ìô¡ãpÌp¾-'öĞ¬jöZûG[xuxÏY-5NÚkkÜX,œİ£%sie¶~çE-®Epx‚¢×i…¡äï¶/ºv…QQçaíÔÜ×%Ï}s)Ù¸ÖæJéúÀ‡t×\€êtÄ X;	¦qjOˆê; ¤ñzÍöl‡°ÿùš7ˆÑ
o¾İ™%¿ûÜ‘›	ˆP>Úvgv,s¿ËîÙcLİ[-‚_‹hÔº´k¡mpÄ8æö´Jù)¢+Ş«k¿0Aí1æK*z9È»7R…×br³k

±H3oÂÖ]{‘÷KékBÌæé!U8ÜQ_¶Kª3æñ|kv²AÿNŞÅ76i1ãº?ö
Æ)é0ÜæØƒæÔîˆY\eÉ¤ö³c, Ô·‚MÕÌ6îJï\¹í‚2â§°«í|‘FÒ{JĞGEzºÔ×FWRÓ_›íô^M×Ó÷ß›½ò`N?Ãùİ*KÁE™3
zV8M9Ç	·|Aœ¡Ç^«>èo—=óÏÇLÁz-´u )‚ˆ/§[>ùlJ£(&îÎ¥¸ô–üÏïì$PÛ‹™Ú.Ok¢7ßSöÌgÎù’¢íèT§®¼™Í¸¥Ü‹Ä\ƒÎûêMÄ£0z#õänpÈk0¤™egRÛïm à~#ÏÀáN)tô„Õm˜bœ`ïaQÀ4µ³jIÄÖe×ÀÊ‹ÒeşÇ0îA¸=zq*‘Xv‘r¿ª¼1rMìèÛŞàòIªœÑ1eëeEÄã!@©~‰š•]YP]ÂŞåSÏ®ÌXéı–ÊóO¥±V¡½µD&¡æ~#ñÅš„{.;ş¿nºä“¡Ty¾VÄàAoXS`á'Zš/©¡ç-“ {Ä~%ãòbÆ71h™(ÏelÁYĞºımÂäµ¹úÂÊòÌğúzj-¥¯Iso³„MªLĞúî=‘ æ¿‡6¬¹äœ€ª¼w6U±Dw¯7GJò"ıÒ­î›ºã„1ïUkÑÍ¢¢şÕûà	d’×Öœ|Ÿat¶lâï½Ê—,*•Za{­W’Qrî¿“úœ—Ø²Rªë c¬Šåpäép±?ÑJìê¨qÕ0“¹ªD4ìC¤ˆj¶Ö6éÍäTçjĞ±	_?/şĞrú÷W
æÿ¥J’‰¬²åšq>ìe6Ëdyë6²Ï•x4áIüÚb¯A/Lµ÷{ÅP´3.óıl‹
«Ö‰ùJKÉhH;Â÷Î”@„G`ø(jm4ö­Œo «"Â"XW\øÄSÓå»FåxlËÿŠŞ|›¬zPäó©¡­šYã;ù¯y©D™uî×O,:÷'{‚ğûÎ¶O u+¢›Ğn_üºıq›eœF½É­ú	—£Kb ÏÑ4ŒJÂšöıËyYÖ0Q0ñ?ÃhVú~û}Øås$ UP*<ÎA[K½šõòoÓ%3½™
j·O$™<ÃšGï+ G‹ æâ”üw9Œ3ÙWşQLYÚ©¹éHˆÿÄõE~]ÃkcõİçÃ+bZSÎLÅ#a§]òe	¬°ê¬N*ç¿¯ÁÜÈŒ6Üù‚5Ùó½èèVGØ–½æ¦z¼¸»‡bÄ”Dqgu¾vb"&ĞÊiâRÊ‰4;††È{_Ú^Wø"5RdÅ‹í0=š’î—œ›r¨šrOÇ_;¬îêöo<L6çªõ1_hĞ¬b£ğ1+»íq8m›#X:t£at¾R||ÎŞz$ˆgeØ‡¤†	q€Ã÷U'ïèÚ¯ŸÛI›Ívøg­¶
ÉªÎSâ›&€f–z»	ùjŒP xR™SŞÿÊxÍš Ûı•6’c>şïlì¶s–¶µ¶$[n¤}¤Rn‰‹²=PRJÂË1äc (oÜ1IªCóf;%€qää[·O>ãC-§søÄ $ú8K¼KkÓÄØÖ_E*©ÿA­/ÙM_¶REå”d£¢·ò›s@ËµFĞDWÖ¾Èyk0Õo‰º‡Pš’Öå$–¿†]Èš_lÃNésYcñ“ê3eEò5ÎWÎya)¤E=/§ÅÕûôJd³(0»¡±­LH’ŸCí›7 ãâTç/Î^‚d¦˜m|2íVë9ÅŒœ[®Ôv_´ü0½ê8è°l„»šh	 í›^Ø‹‚;)#CÖu¢Uröñ6ä´ûv#¾T½Õ­wlg'WÛX¸™©|Úxğcûí¼î7‹)ûÁ¸;°ºtKn÷‚ú*M%‚f‡v±lüéŒ¢æ¿w	ÃŠ_f"c€iyû¾AÛ-”¢p˜—¸€üĞTÏõÊuÍ—ë#šéŠ|M¦ÎewÂ×¨ËO1‡”^ªJ~+„×#v¯Ñ ŠLÃÕPº lÍP8#şryçcÀ“‚’‚ÎìùÙ:aóéÔT²ëìGœV7(ÀßîÙÔÏ¥èÆæ&`+EUªİÍôÛİ1ò›Gò5Kû^	ğÄç«ùé:“à’Ô3xátZ9õãº–®ˆK)[KığP[è‚†@ïÊ”Ú™5
X¦ÎÍôûïtİ‰=ƒ2ØØªH–’fj¯__nOzûEú|lÇ'‰.%Ü¬¶™l¶FJãò´~úQåßc…Ÿ_{¬0J^jÿóá×ûLMZµGdˆG9÷ÀÃ¤ó©)Ò/¬zì]_¦¼°—€†gš²Ÿ×ƒšs<hz£\î?.ûè ¡sÓu;kç”hİqæoRƒiLZq™ å¨¸#AD¦ÔÁÄNƒx
0àìCöÏÏ(ËµµWbÏwòÕ^0N‘BãªœcŞ©):VaSÊ±dÌ>‹±‹ÜäËMS5 ì[â{HEf—öô¤’¿º2à@PLz2Q‘_i‹ ãºCk¬½.R&ÂX=¥?Œ<æºš>¹KDÍ-Ê“P9/°Ê¡°Qä2¶M"ÖF¯BH×ûŸTÑÊ§b‚(ƒZ²Û'B#NE¸‹×Q>,]î×#§¾|Îñµ[qNM[G€0.å>ÆÚ’#nuq£õQVjÛgU½èq²»ÅÇe$ğUlR	Íf2ÏW^e€îŸŠû)¸½¿]çºó(‘VC˜cµ:„ZÑ5$[5ĞßÙ“äjÀ7õÍ’fÑAJßúà˜«{€¬kìØBz8çz1„£k2kïü$½qbk}ŠjzkÄ™Ä|:°ZX|võYÔş0æÖ+7Ÿ8AXèâßëĞ¤ìqÖDhïY5X+mà¬>‚8±Pèd´8¶ÅmB—Çw1qBàrÄUqü5³6?³óß zd›~Îr=‚B
Š<$£ŒähÀ·İÊëÆ•£)ÄŸü˜¿ŠÁ$w˜†i6†·ËÏ`äeY¡ v%¦µe(z#/ÇOi@Án¡åK"Í¬r$ê»†Š|Â|.ÖÛœ±…~|ù²Î”Áû¥Ot-H+ƒRíÙå‰)”
x­°İÕN:ã¤ªy7K>o¼MlZçhjNØÎ€¡çGu«ÄŒúú~PSÚãQûäÀP>ö#¶ğÀ™}«ÄøÜï4)íôÚg#`9ğÜ%‰‹½Eİ%¡ZcşÂ/…eóYR"ey‘pôş#°Œ,üğó6sU½=VÁWª5Qıµ\ºÙcø!R¬[×X «%İh|Ô0ü4¥à
ûû¸áDÃŞK§N0À%L·’mŒ™a*%Üñr‘{ËÁwâíÿİfRàLF×–9µñòUƒëK¥ìıÓ·¹u•™*Ï¹SÁ*ÄÖø½š½­ùS0:ÃO,×Tı¦İÇ§"ZX§ÈDˆ%‘c[ì6G*e
``3 Ùt…ºµ¶½Ë¬{$"\
ƒİãşØÉ5¯{ØòÑ€<#˜¥)QM#Æü,:
ëÒœdU— Š©ø¾9¤ko‰b€ê“çCÖ:Ÿ£:Cv¥ÔF†NˆÄ@ªÙ„¦HKU<ù…ämOD@’ğ«‘-< ,4‘P¢;¾Òÿ–‘÷{›{Ô»HbO|¦cUßÅè¦}æàÓ”iF!Õïƒ€&Éùz(ÿÂÔå?È*R	?Ú)ƒp)(Á¢`äØÇTõG“ü^ÌIÄ%yRè«iÓ±A9‚PıT#šçÓ„ys²Nì6f’Ïê(ê„øì¬ĞÅ¯I:¾LªÃ!š‘šÅTG1à"êTNÜ–«2eŞH²!9åÔs¤AT*5J£6£É›{p˜¤‰F…Îx­Ùq;u{3š3Ç“I¯@ š×e:ûêß­Zß—Úrq»ö³7ç!Óƒ¶òÃ¼ú—î«Êæu+Çø¹]3v¶V}rcÂª‘÷ùß
’ü%°8&)ÉHÁºOÚ.ú¯.$B—‹pn9ş¯p®ˆ½uS¥6Xû;1Ä*/6D9Vˆ:*ZRD ®&{¿>ì×ş§ó<¦ßGòşØÜ&¤¿¡Àz—N'5Ş ×='cF€mhÖ£P}•²ï¼{=!2/¥>€ú÷Aƒ`’B;DE±b§ì‹•î°Wõ\7Óh¬m·Y;%'ÑCeÿ0«*4ÖAv*m=4¤ƒ™ì-”]zÊnıšÓ³bìçQd‰ê.¬—ÈôDâu’êÏ@ğ>Må‡ Zå˜ÆWáùÍ°
ê‰#N~ipa_Æ8
£”7)Ö–ÁôÖ×&/Ìİ<zØ2åŞàHIØQ4·ØYÿ|¶ì²¶Íiå-·,d=Rœü™$[VyvÄ˜iÏòÊfÒfWz_ğ³’´ÈPÕ¡Jœ¥¿Z¯/NÛV¦#ÛßRg–ÒRZ$|UZ³m<ƒŞ2‰#úgå5ËƒÂQ)Ÿ>—ævz{4 ²ªúŒE½ ş›HÖËÈ¥¦M8éŒšr9»3§:>`Ó£!W¨]âá¸k´ĞªkráëšM0ğMu,Uéâ.wİ"·P¶'Ÿ²QrnåC‹£c™{ »]´ò‰âç¥3WÿTêcĞÛÚ_gh?!kàöH1OgC|³å?Œ‹{ÿ	8rÄ¶£¨x¡d„ÇjœW?ŠÎ”aG1¿ÙÊÉ¶µfĞ½ˆ‰‰¿y­ :»çÖ{±m2ÎßVCDße$0 wN1K¼´ğô›-#§¥tçÑ•Ï	K¤ifÀ{´oò3½‘-;Ù-‘iZ §šÔm`8$Ù*j   Â$L€8Ø û»€À
: ×±Ägû    YZ