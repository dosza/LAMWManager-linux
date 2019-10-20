#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2362708613"
MD5="4e9637b9872bcda02cf950333f7a241c"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19100"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 104 KB
	echo Compression: gzip
	echo Date of packaging: Sat Oct 19 23:12:30 -03 2019
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDUSIZE=104
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 104 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 104; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (104 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
‹ Â«]ì<ËrÛH’¾_‘9mÉÓ EY¶»­áÌ°%Ê­hÊbR»gl£H%Œ@€€’lµ>fc{ØÓÄ^öêÛÌ¬*<HPOÛ±3º-°P••ïÌÊªb½ñà³6ğóüùSúÛ|şt#ÿ×|4Ÿ<}ºù|«¹Ù|ö`£¹±¹ùü<}ğ>ó8ÀWÁûúİöşé§Ş‡‘l|~ù?½ü›MìşUş_Nşu_L/†ãp:óe=>ı¢òÇç­ùo5Q%`ã«ü?û§ú°1ò‚ÆHÄ§VÕùÜŸªU=¼sÅ+\	éÊHø€"	áeÆqkm*¨EFëVu'œG±|ƒ±'ƒ±„ÔÒ9¾²ª? 0xõ'õ'VuWÆãÈ›%ÜvtêÅ ¾Ã8á1Dá<ñÃ$Œ@©;~?nûà5NˆˆNæS$qİªöåäÅi’ÌâÆÅÅEıÜ;¡ïóË:¯¢†ëEcp*}ßQ³9b„v8ˆoèxô•€Šè‹ğÙ²†lÒSEÓ0Ãgm®¬Š‘ïãy³HC8Kb«²sxĞëwzİ¿´ÖÖ­
¾lÙµ+j¾>ìïŞğã=¿»¶­
\ÙÃirÜ²ù3pœØ=Ó(á—HÆ21!f(1Ç™Ï\”¼CèÓ·XgQxùËèœÎÂ(Û²*ŞŞ¼Úâz­8áİ;Ø†äTV%OÔÖˆ'2 ç5 Ö„ÙµÀôğu@š+‘LæQ VeâY×ÈFÍ8	Î¬b)äÛï>Â¹×ˆzãş³¨1fü?™¢ªÆ¤ÆŸÅÿ?ÛÚZáÿU²·èÿ›_ıÿÿcÿ?%×ïŒ7úÿóÌÿoÔ›èÿqØhn4šOÍïoˆø„	Ìº‘pRğşaŸß‹ ä%Î z¾7ŠDô½ŠÀwÆ“ç¢‰2@
Ø‚ô4õ/äéãSôeè\cÄx&w(|OÄ2¶ø/ò¢—D­G®û"B‡<Òo\éó›y€ş÷‘eUÇ.óE@ Ó… ¿e†@ü>Näã†è•]"W^Êñ·IáÂıx7k|*‚¹ëErœ„Ñûµõ+å°Ñû6mxØÛ†œ³æWToá]Ú^A¬¨¥Kj‘ãÓì·ØúÖ7”JœòÒ‹“ø¡ßüa“{]z	4ñ	]9şäÏ«KO»(7/Øó|¹¶·ßíÀãÉì[@„#xqa,¨ÖšD6uHĞ<j›Šƒ$¢œ¤Í°Àª&¤\“y0f·k‚ I„Ø$œ.`ÆÑjâ¯ÖÄ‰/NZ|0Ã­G¯_u•ğ¬È2»¶¹ü¦B	GòÀ¸‡ZKÃ)¾UÜşÍÄ5¯0´¢ĞhªçJ÷Œ‰ )O-0k4ª†ôsáÏ%1¼ŠÉTŠ•ÈWó9‰êçM1„EÈÊ3ŒË¨¤[E^¢‰¡µ·Öjkƒ™ï%È{¨‘€j<Ú£qİŠõ+æ!¾mÙ¨-”Ÿ°eˆ]8«YVÀo¾Y`¢VI@*–Ò½ÛV´kŒ†£ÒV›xMü±ŠÑé¤µ+|l4Ş6p½i/7S7æL©RÙŞ¦sŸJ•­­qg¦øW8‰äŞçCÛùë†óıö»u”ŞF†0òGQ_”Ã‰¼áÏĞ1™¼±’æ"V»ÕøUªJO‹±N’^Ê ½x"c1“±C"¦­ÚUõÇÃƒÎğxĞé½îşÑQgwØî÷Û!¨Z2<Œ•	gÑ9:¯­y­mïyÛûıï×	]¥Î<Éà(›£U[j²ß6¦•èx„N¥ªØ}[7eÚ"ŠÄ{RR£‰Š
ÒÂRó"í©ˆ¿…¨ojÙ³"#ƒ”GÈH.×;ÍcÑó‹1%e!_†N„‹ÿCµªÔ•aŠŒ$Ë˜œşè=êÖDFŠ*% ÀÁ`ï†J[Eñ=É¤úCÆTkn§ßSF‹ÊZU¸"»oÕ¤­š2ä©66Xø#4\yŞæ¾ŸvU8üI™†1eÈ}p†!ã’7O™Àv¡g¨<R
=%”ï’.LPó±~,ôkZªÇ¢‹g…Ó˜ÈÃˆ¿N0pì¡‡@L%ÇœWŠ)zH'’B±úÎ²Á84¢6Ô&Ì›”‘ªõšàEilÉd³™óöfãæ4ûÕÊÕ!`£¥J‰ñÍ›Çï®ôUÁ÷Š|'·1Cl’	Ø¿ÙÚ­ T\åg×ìcL„¿qĞÒ(öKÊk3Òıà
ñoƒO"¿lØí¨¶g3IFÍzD6¡²£•ª•u5Æ©.¸súÃ™‘–O”hèúıÔRaöÏ«%¤„R^X«äL.t?]3®v15Ê2Ò,_BÑdôÿ³º™q ‡ã§ñàúöO3a—Q‚‹Á¿Ïå¾Î(¾×
!Ÿ¦UÄü²U[K„çƒÓTï×µã­šÖiˆ4a€ƒÿå'ŞTà².8ˆ'º¿Ï½ó¬,1F€Kù åWè«½‰7FU—K>ş;æ½<Á¥X	jâí#…QU¸ŞC¯€y:F„hVÓ©5çx#³úa˜‘ØíÚÚÅi(¦Ş:gK¾&Ù3¦U\¤âÒ¹šEo,ÿ&xu6OÎ7“~4ŠÈ6âïDQ½ ½²ºà5bìDt4àÂKN1.ª¡8îE~"ã·A—[hßõzTèßl"»è_^3±rõz<¤Œ_Eî8q%ÍieË5"úÁ×ÏİÿSáÅÍ=Åñ[ o«ÿ=Ûj.Öÿ6Ÿ­ÿ}İÿ¹÷şOZÿk667+€G§9İ&÷dê€è;Ìa±&X‡òİ$Fåvrnúo'j9Ì… üvS»pşĞn÷w~|¶å@;p£Ğs¿P•Ğªº¸Ì'Iÿ5¤°3™iI„/\ñz;¸R“Ô-†óÿyâÜ“@LG(DZÈ¯XîõvhÙW±*.Æ÷!9ø–ª55d2nxq<—õ@&´“¤k%¦Ÿ©•<¶Gó ™Có»º­êò’÷v¨š4¤×œ;ı$æz—Û]Ú€ƒŒYĞüşî#¹f‘¢ÓÌĞxRß¨oá÷»C$±e›İ¿ø<¨O")q<~=ŒN¨©ük$â$nDÒ—xød¸1Ü°sÊ°»ÿÃ°×>ú±e7æqÔğ½ä^Õ\·½—¦ñ»8ŒZ}<9YÙït;íA§eß8ñÏş`ÿğUK“x'´µÜH;ã:Øú¹´u'’¶n$i‹v³Ì0%ãò»gC´1Ş©uN‚ù]iš\eu@Úe³%›pMÙ²z)¦ ^´	Ì®8˜­ë[G‘w"’ÿ@[¢ƒ˜¡×ÀÓBÊ
Ï ö¦£ÿğ½±^Ÿ DSp¢Â°\E¶~@Õÿ‰_|=È–§Kü^Å^]Q¼ÿTš6ş7g»9H?‘¹t~é´(öÆ§ÄíéšŠ“‡–Õ|ƒL‰1EóFÈ‹uVM¥«moX­¦¡++`"}f-÷£ípœSvL`úÇ¯~‚ÔİÑ(ZØÀòF±YßpFèÀí´Ûp¹_íj©íwoÇ×Ğû¯GínWwûë~×¢·ºû¯R‘”…Ÿ
Ì!‘¼8BIæ ~~uÔ~yÍ¬dÆëz¯u´úÉ»„ºTiJ§Ouèj™Ğëh(Ø­ƒ¥ğ0!B$T)Ø.aİRSåÌ‰×–) Dµ7×Cz4äğÕŞş£°·.âRU…•	;‘špRaı@M;”´£)/öŞ`‰P%-(é™óÄVe*Î0µAoL‘R}¡ihŸ†Têàìô‡GíşËÎQK ·:ìµlÇ%Xˆb§kÃá }¯òØéªãÎ{ıü¼ÎÎäç½ŞÏOl0Ê×ëwööi‘d*ŠU&W3€Âé–ÔDrµ‚œ:÷w:Š£9Ë_äÀŠ!Ú¢b“£Ê1ˆøğÁ›–Ø½Ò•Tö³ÙøòÇ3S£~˜«æ·†P±i?^ï	„zY¾‡`ãœü¼ùÔ®^öÚİk–6?KH,Q|;ÛA(µ~{›·2"p>\OVöª¤5È=ã×R­U90í6è,8¯ºíh|úl«T}ïâwJ¤“ÎÔVğü%ŠZTæ÷–”³»›ä_&~°î&şE`–ÍÑLŠ5•Û™ñ¹Mø¾\ªŞO|„ò-¢#"
(™+œÏ·î„ó6wø…È~Ü‘d¥wpæ$M~CÚj3½™$f3ŞK§êÄ;™GÔÓÒí;¹¶\Õy¯Û~9Ü;$×~µÛ?Üßj=Âü¨™w’¹ñÊçšl°0[%İÚJ±!7±É`c<8·
:‡ß—Ü¤ø‚#h«“œo2ÈæØÕË–¸VeÀG5zb|&N$pşì®¼lÕşdULvµ«öˆßÔømËŞ“¦Bg8ùeê|LP[Õ>ÿİ|²õ|céüßæÓ¯õ¿¯õ¿[ê7 Ÿ– +€ª~ÇàBıO9¼˜Ğúİg´²§Å›…?SÍ€|™úÍ4<h¿j¿ìô‡‡»ÇİÎ@¯™6nzyµòİï½®­…1–:+¦)ŸbˆDáØw°pøøNc4Vª†{W¬\_ÓUìH×Ã¼ò®c—ŠÆà†yşcâ‘-âË:Â ‚7‰B_EØ=&aèÇC\ ´j&vJšSqâià¾
-Åï¶N:¸uHA¿µ†!ÃFPG”óé£ÕH[)]±+•j“[^öÛ»İ%è¦ëf¾;Óçn-à‹}·4Ôml{Jm:Ïr÷Ì‰šßt‰D-Lêjğ³²ØşÜª¬ãÂÖ”gæİW§i/l‰]IÇŞ]ºx1ãMq°:°–-óíåõ¿Q[—PìK}0i ':/¾É€ämS­ÏÇ§r|¶¢B©¼‘˜±¯T•õ€N?¶ÖjTC-nÍÓ‹üÆ<oËWÍ¶l.™Ä4ƒûzïèQç‰o;;š¾ç—ãL"ÕºXÁ9I·ıú`Kg½êÌ§9ñIÄñF¶è_|Ñ<Ï•jéÖUû»&P-3†|ícmİºw´~¤XRÁá*z	iÊ·-R^¬ò¢FO!‡?×!yrµê:·œÇ^ùÊtmXV"ª¶­ÑŒy¨(c×ƒ,ÔfhdË\Ú,×o°á¯íşñ`ˆ‚û¡Û"¨ªJ2ÆTr|[ÃÓp*5m:¦V‚…yS,“,¢’ÎÔ0Q6ı	£¡ğPıô	„‘/5#JKU)üüñ˜Â2k¡ğä´äÈ”mR¢î%ğBÙ¢Z‘i©å»ãÌ&˜Db*/Âè
ö‰°«Èî÷»»HW¿}Ğ9B±Ò)Î‚½Òu›
0ÅÕåê°æªâÏ‡§f™¹t£Q×µÅLå»&ÒUWŸÇ!íí¹.Äó uáJy³=‘ÌóµãJ¸øË_”ıfgtÚcº9ÀƒhÕª×`ùVs·*‘q¢½¾øJŸáóıÍÜÁNpgg'àøFƒœ™êmN‚.6Wˆ$ë;¸‹ÿáòisäxË&;?Z)=8ªc„²Ì¿Q€ãh
@“ »¼É*İ‡oê;'´M,Õ_é]æ!©w‡5W<Ôó™Z®çJ}tÂ&­9ÌcI1¡ó²¿tx­=†èUçí#9ÏQèÁû‹S‰é®±ÍÅ‰l>ö%2º™Üştæ{c/É·¹Ølxª,ú ×İßÙ?¶wĞ#RŠÕ¢	(2z¼ùÂK0"Û¹ãIqf"½wí«;“¶ÓšïuÒı‡£ıƒÎğu{ÿb‰©»p /O3EÓú˜·ø1yûıX]rÁyÔ±¦”TvE^R¬ıÙáE £¶ï>Û©,·SÈí¥I]¼Ä…)îŸL$d¡¹/gÂ‹˜Î¢wØNé;&ÍµZ®£jĞsJÅ¶©ËdéØMîºÌ>ıfâQ U—2W§YP{Œ)µ>/şÛ¬®¨™ÉGé²®¾îtw0HQÀ±?Ç´
^Á¬©ÃÚYK=Ûì÷ß‚9Mñ¬¾±İ£Á·?(ñİº¥“±¥¼¯˜„™¦ÑÄÔ×uDä{Rmp£¹Ålo+\z7ÆHj_ã>Ì5•1,û‹ò,Ü?Ã¸òë¯æÛóÁÂå¥Üa>«iÜ¶îôDwRw‡¹¢îñT÷ v¦Ô.7æ=ã4ùÖRmjÏh*rŠ‰X¾ƒ‰UÍ¤ûxˆşdîs¹`Ğ¢9ÁµY.7„3}œÈÊ\±*¶_7º“~nocÎ`Ïí3yàeP‡¾«2£r4#ó×·i0Zµ2}e{ŒävÑçk<ğß£ãV3Íßür²Á‹Í†©Úç•;+u¨E×ûé 9!®0¡Dgî:s©ŒÒ4“+£t!°-àY†@î8õ¢§-uµ+}m©³5!œŸWxŞÕ®—5Y“W½Ö:Ä$5Çw^CêW¯‡/÷‡ÔÃ¼¹-VfºÆ¿
PPî…¸©BUQs½(¯Åi»ƒÖæ–Ê·ºB“èÚŸ•ˆ”õËŸÎ²{+_qI]Qz„,B€æÌa¦lEZRA«:ÇsÕS…:/µhQ7Ğ=-'f¼n0ê‰}¹GIŞ˜³¸Ô‰¯èšö¤Ÿ’°×¡àô¸æh–~´ÎJô¸èÓD{?8>úóCs¹à,`ë]8„Ë'‘şÿÎ—S?Ëï?­>ÿ½õìùÆâùï'OñÏ×ıŸ¯û?¿åùo°›wÛ÷Ù)ıå (ıå [@_èd7.NĞÃS&9;‰­¼İ£w«5!÷Şb'÷Šÿ…¾«~\Æs%×KÌq‘Ëş¶1™‡q4.é«ÎêØ–U(ì.ÍRüıè9®F³té¡—ĞTì*‡åDÚ–îsš"*‡[.¤–ÜíT y.ÅƒåbìU	 U­["3ƒSüÑ…öù.
÷üÏÊ2ó4Ãí[¸v¨œxË«À8*a¥Ë¦"âò'ó1şK=J ,x\²Ø!…Qx—1{“Jô°™]ª™éş¥~TD$p‡ºÆøˆ'}”İôıÓòMßŒÂ²³uÅÑ)ÇWÃ+&âué­,ÉÊlû¾LĞ)gI
ÉygzesEøÔôÕÜß6eçÂq…=oy:Ø»z.éz ]\ÑT|@oËwˆ?şÛÇÿD¥ÃQDw/é’²Oê¤ıLŒÃD–]…Ü›ñYÌ?fJÊµ¦úÙ¯ì7Ô?›B=Éß~gƒb–8(
øp·ó^­%õ@°¶ê®ø6şåı5ïŠ‹å¶9[dvõò`Y]Ğ§1=u«×|7·|+…í)ÌœSª˜¾°^)UL¦xË<ıéîL‚İá²\og ÖW…r¾ ¨§á3ÊXUÀùvÊ£Âï9@iA>§iÎîğ¸Gû×¾ƒbÊÓêÌÈ—Ç*š3\lï|«1i¨Mÿ¸î{q’ı¢Äù>UÇ4OüFıİŠM›ü Ø¥Ô]> ŸBäFì²ÙˆãFµTbiÃ('ö¥+÷–t8˜ÑáIÚ{dÂÕdVßÑ·÷mÛmãÈ¢çUü
4¥½g‡’e;—±£ÌVb'­N|9’Üév–mÑ;’¨);îLöïœu^g?Íyìù±SU¸ AJv;™Ş3V¯%(  PU¨K8
“«oXvÅFÈu}ã
aCœñH†±Ãê2ji˜UË×[Ÿÿc%|Ãâ9©s”¢ë‘Ä.:Å»ZxŸÂÜ—Æ€óIÈwñÏş…O×4J½êÈwßÁ«£‰z®qT—³Œ®¨…¸xñ¼é|v joòóğƒ÷ï>¶DÉfó>‘qÉwİİ'ŒµÏüù(qğtõ‰ïğ'ÔS”ã8:ŒgÂéÒô‰÷ó,X%›„ùdH2?…ãá¼n?L	8H"‘zıÇ°ÕÕmFÄê2$Ú"KÔ8$´–—!W[¢'4'üÈÒÃû2$I„fÀ8+•îz·Å ‘‹OzI4’¦”ÇáR:!Š| †e7¤ïÚß·¥¯EZLµ.  ?¢ px}SÊ„/’š‚¢…ÉÚÖn-J’0¢¨Ê³bLcGüØ	0
6üz•™{Z©SË•öeK'wAJÇ”*ÑJ35Ä«dè¹²æÈ’ŞÌjÏÒ_¤)Ãmô×ÉmH†›À”¢Ko>À$ÒM7E×· C“séC4.?ÿ”´’£¢éÙÁÔ€ÂÅ©Æ®Á$sÓ¬rl	¾áœZÓùÏ[i!‡°r—–k¡+¸(]8	O–#q‹=‹péW.™X*F„#²˜ye¤-$éÕ*¸=”´)Â'ƒŞnø(E½9èöÕ‹\•£îî »ÕhÔÖ·j4H¥Ô6ÁOLhœ ™VCYë…l`¹•ã‹=İv„3¹SÀ22Óñ¶´ÇÓ¯L„ów Re=ZÔg—¬SøƒmU“Û©šİ„À+òïh÷Çã½¿éAğ1™ùªÛãuàÁ¢Í2¯D	£1a§¸×Ù×Û£^yŞ$2R0œÕşbü= a:NZ5×Ækœ-xbß®–bt] ´‘ËàÑ[ŒGB•wEç£@ü Ô«^j†§ Ê‹ÉşÍƒYôÚŸ}’Á Opƒñ§w”î"ó£+¸ø[ğ^fŠÉg¾h½òyöJçùMçÅî~Œ~ÓmKŠ#ûB+YdÅL»B œÉÚ@2Ì×qş}µÀÖêŸ…\‡¬â¢È™İíİ/¸wË7¶g¤O|õUèÊGTe!kÉû,ó(œÜtüaÎ˜7-òf^ÚíÙ©ÄF·êÊª&ÂXJùUÀ ;F7êÀÃËy&ty¦ßtQÅLlœ[âŸl§^Ò)F­.ÏŞá–ræpÓBDÈ
°ª” 6¿j kBtËğX
õ6°™ñÓûl8;›«œ!âßò×™Õ~MÃxŞñ·şlŒ¦XF£}³’JŒ¤)ksVêz~ÒÕ!a¼’[;//U´m*-ÜªÚ>"b3õA¯ûbğfÿu÷¬Æræ‡ |Œü8‘ÈÙ–@3bQĞšĞ·Ùˆ\=%­/\>y·%ÈÀÑ ™t¾NÖ`ÇâîÁAÀ­Kcp&‡Z÷ÜÓQ4	\éK ê®¦j9Ôğ5‹g>
.C˜Õa£@%yŞõ^5Ü°ÃĞÌhôMçÜNˆÛác3µOê=7Ñ·ÎÂòk€+î¯ƒŒR¬Vª§ïa\ìñãÇÌë^`L¿pZ„ëÊZTIê¬+^¸7ëÔuz%[·AB‘Ú˜¡oH5Iˆ`¶'É‚-À”ßù®(7`füé¼&«b®4¦œ#A‡‡À¤h¡7è/@aš"tvò!é6ÑËŒé~}Œ¡
àûí2å‡Ç9÷B½V,šuyyéóº?õaaSÌ,ÔX7 ¨”ôga7øKà¯Yo®ÕzğŠBæ|ü…p\Ğ“/¯ÇÊ ºiEÖºÂ#‡^‹ºjƒÂùêoM~Áx¥s–¯f>HY¸RÖ'õ_K´”ÑŸ-Çhò‹¿oÔ}jú®Q—z2m¥UXP•@6+÷ŠÏÂ)v (©iŒ]µ¡$ XÜ§G¯µ¨,fÃ06Pº³rãÒ($'åe4”ïŞÌîÔ|LlĞRw©-Èª4ïŠ‡áè½Ïz"†AkıÑ:»_Â	,àÙ|Š¡Óm¢9ÄÚXmÏW±­ÿÂõ?ŸüNYÖW9ª©åŸ)ÙÖêUbŞìĞê¿g3v•¬@-s{Ÿ¹]M—ªá¤œŸtıµÒ°Ò|sİ±ÁŠĞ›¸ˆ ¦Ø&Yœj d™S²s‡X]ãGšBz€ezóĞŞêŸ2hRHÄÜ»ysccãñ¡{³8ØËK—°–RÆÈÍ#Yš´ÿ*¼Ûlıa}½şĞµ2Î”á¨Îe}ÌS×ÈQ‚+n?ğD6ô×¶A¦Ğo%Ò¹ÇÙÑ'CĞs-YCReÊä–ÓvÁbòš×_M¥çbq•â:7:LµÓT7÷Yv}²tÖŒ©k2÷›Ÿ,÷TYW¶—‹ĞÏ»§p¹¿ózyÄk…ÿ1(¼$,Œ{  x¬×yÕÙïƒpË¯Y‘ûô¾‹ñ9¾Èµ Í‡Îî/ìHİ_ªëºÁÇ2ãÈ‚+R—;ç•wØ¶D@*—:¬;•« faõ†–@²ö©@Y"\Â¨®éKŞmfR‹uÖ¹è9_Ò Ë\NF‘OŞcÇ®V¸ğİçcWX€e/)DU1LJBÅé0ˆƒ1#7Ö{?GXÎğ´ü•ÈÓ|g®×¿òÿÇjDàú`4LE*Më)~'!&İŞêÚ©±àÚÅ^-½‚1ßk²ë˜\E~÷Ôà\RÃz5ÃXQ-ÉPe¯bÊšÈ]q—Î^â,Y!w¥S‚­âëŒÌ“Š$%n•ú^LÜ©1Í„™•¬g95l—o9«G§´P^šœ®[Óàğ–_	QãØ-Û‡ëœ„*+úJC4‘	Xµ«‰x’Ú'dÑ+b;U*F8–’
7,û|…™Ñ³¡‡›ğĞíµ7ÉpÚØÂÁ•—à÷óâ„,%G¿›.–õñfDÓ ›* »ü{Vd¶$fÜX\2s´ôe»óFĞQE:]Çz)­ßÚÒoN\
°•‹G*ıùÓÈ í‘vtØYéqï}tß—æ¯Á‡ÌaLFW"ôY˜bXsø—~VTEOr˜Ù‘4Â_s:ŸÍ‚I2ÀdÜµöIÛIŸ3[‰	Í_µ,Œ“	©¼³eôÓ®’=ê~É¸œh*Â­ô+óº…\X¯@ç¨1˜`nˆ!ƒ†cªşƒ³SR¿Ö§³ˆ’b>ºø4´°Úİg¹"Êô{Ëì´„Nº£TİÁ$†ƒ=l­OJùi‡¸:§şS}Ù\i˜³œW5jÿşß2”âØ§›S3s‹¡1ÊLåVÁA>Vd`]A €¢g0XeU=ÉeOC˜¢±‹`$uœ<‘‚ğgcb:=ÅPÈ«©Ñ£h$—ñ ("cyÃdî©Gl‚ì;uÈ‡$¶91Â9£s¹Ô²&Ä•åLˆ-(î°€˜·«°±ÌĞ™eÄÌÄ>„mDéÄ—£Àğdş(üÅJ¶[Í¦ufîB,—™Ñã´t)i¯8B^QŒ]Ì03Ø‰T@>yPFÃğVU„JDf @ˆ÷¯fÎ —ä˜òÜâÂf…[nÏÂSÈ—û c(+ÿ#óş+e’üùÇÔE¡¢û`ˆ¢¦?ÖÓ¿ÿw~„ğ'!ÄWøØO`á¨õÑ>007	`I+ûŞÿ¶9JŞdÇÍ¢¹òÃ-÷
qëÍô=&S’uÉÚ¬
İI;ÃyZ™´åz}ÙÌôåšÙ”R¥j}QJ†eEÉ¶ª7[V­ˆãšÅ|tÓùD6bŠäŠS¯Óìèy*DgSÎÔÇîË‰vŠ'½mÁìg‰Z·¬’õÅg´Rì<b*¤“Ÿµ¼Ú`ÚÅµ n'B{9=h»ÛLîàŒñQF9ÖœŠée¥ÊdOü_Å‚Aúı‚Óïç@iUĞç®Øìì¾l½é[¢â<º–6£O"ÅJ| hÜÇ¥½ó<‰†ÁÚ&ìMt^ê§B¦&‹y0Ã ŠãCy¥âôèÖÆÊ-nÔˆS‚	ç¢š×`£¨” xÒu½µæ,¦<uA¤_É'Âä_ÿT|ò'÷hsµò{àä2,ö3íEy7xí¯ÁfY¥ºÏ;”ç£n—72bÈİàZ-ÂôãÅ>²‚£…[\‡bR·A‚Ù2ª\]H–mCœRfÆc«ÍŒxö…ÕqÈ›ö°é%¢å ‘ùRçÈ—8ŒÁ1bÑİÄp¹*ÎG"ãbó@Éô2Î]j„Rè¯ÔCÑÉ‡–½yÔŒ°Là ìbÍÕ£8•‚(E±2ÖteuI<®¨¹^We¸I3¢‡’+mO—Ó»ZÉèª4ÚÆ\4h.Qü #!‘‚»‚­¤‰aß¸Kµ¸V†BVN ÄlJ‘‡3¤Ïğßh¨,ˆŠC–Tò”L3›·ZØ(ßnZ4>éÑvşeÃA:Ù“/w¶å!¡NAdÇÆT3ê8›jUaä ÃWyNátDïdšª¦ß~Y¨kÖ8@‘ÓÔ¶=Ä^bDÃ$:ZÊ’Ó©šÍe?Š¬§^î,(3üJWşa'2eîh°Ÿo1ÿS>;Ê×‰ÿ÷hc#ÿïá£µÇwñÿşuãÿñŠÍóGcÿ6ãÿ¥éŸ„™…-Ğra»A<&ü¢ï… 
(Cu7øOI›Eri /q½şubfh0ÂDè•ŞÑóŞ½şî^«åÎã÷k÷ûİOáğ{4îš}†ÇO¿ßİß9è>ƒwtæºk=‚¯ºG‡-w:šŸ\÷x²ÂIÿg<ÅlC66¥gka„Ã‚lF‰³8 O³i
«4º›®…Rÿ‹2m[Sõi¹úÊ’õUu1ÊÆE#_`æfŞÁÎ	HmQœ
Û‹rJ—ªh'pà`Ÿ+Êß¨_?„<¹Ğœc #á¿\í¼I‰	ÄÕŸ½8<jw÷ø#•›Sş	:ù¯†òğca(æ+ğOBO¼~9Òœ„&Ã6ƒ¼ÏÃnàDx Q"F‚yß‡£z¹Rmw2°ñ*L8‡öNmÖÿĞ˜Î¼øÆàO©£Hß\©¬x/çæ¤À?"fzxŸ$¦'°ğ€ÅX¹vÆıÔ™%£>K°­:/İÌ÷U=Rbf2å#)ÔI ÓVSI]Py“¹|2aÈgb)¡–äzñ÷IæZE¼Ák]s&nUpW¢·l$_è•â$øÙO÷¨°­iO‘…¡ÒÜšHÒÕúåŠ["¡/ÇëfëÆãZñïü§•»¸æ×ÒBI)‹RHkäX=üikÅHÅFiÎ+¸´V ;À|³N²?Ïƒç#ò1.½µæEîò5x‡¡‚mÛr¥¨ÛÕ~«¡¸ÖAÓÜj3k¼5b¦®I%RÌÁ~¦	ìx¾ªgÏ+Ä½	FÃfËÌ=÷ìÙ"¶ÙÑ;‚„ÃS„cå†³ó]
†È¸ˆAÌÒ>YËf$'á]TÌ
M4E óá\F1İHNèä¿Å™³ ujÅtROBÀDtb†éŸ¤º9ëíV=˜EùY¹NÍã¹.ƒ3œ\D§ ­sI~ ÍSï ¼M¿W¼^ŠŸÛäÅ¡¥–LAĞ”÷n®
Ô€’†ßa¥¶Ê3ä¾¸n‘‰å:2¶ú¹ˆµ×s¨]Ôä²Ş¿ÆÓ¼n©áß5/yv²e6•N@yT›æC†ŠQ÷İUC¼Í‹,Úò´xIU_ØŒ0„Zr“§òVò>¨¥Í”u•¶uİİ¤·0ŠNıQ#~ïÏìxû2;·m; i,ß„­º®¯’:†¡–´œJWmQÓğûTàpc˜±ñ¹¦F=ÈÈ4éˆS‰6ôN‰7ScÅÎä,Ú"»ÒTSµ•%0ê=C-]âU 0úö ûºwØ~±›–“Æ¦ÀÔé‡%y3ıı¾ùÓã	wõ6ÎM‚™UÆfíyÃûıtÄÚz) ª÷æo*’wÉ¬åQÁıTjÕ´ôÒ0÷Ò¦SàÓimbŒ &: ±@½£CŒ-Ö*YD.ŸIZÈ[µ{øgU
ûıÎK\¶¿ƒÂ­º†DIxvåÅÀ¼¯:fÀã¥lÛô…èªÀ”™ÖT¸nµÊ³%@z¡ux<)Y„üeºÙ³­ÁãIñLß-¹ø ÍƒW[‹1¡ÎZùñ7Ç J<ã¶*ô¦ç#K\´Ömê’ˆƒÉœ¡‡“¨‡Ê=x–^âÙc-h'HÃŸâıéĞbÍ¸ODNğµä¶Ñ£Šª``£ß³ÖHq›a–m˜»ì-Ùãq8"^lu±_º¶@3=âI4%á/¥î?íğÇlw’Ì®Ş	ß¥}´ÒÉp¹fu÷cpÚ²fìÅ€…áØŸ]y\~÷xeÛyËIu
*Í	LÚ<3/ˆÛ9ÅãÊ,Áà!¼Še"áA4C¢©^?ÀWş¨uæÃöá®¦A«N‹ëXçÄ²¶vÒ„,ÛĞÚv¾„VJè5^õ_o¿:ê BÃs82·9åÇ1Í§o÷^Œü8ÖqŠo÷`¶¨[Iğ1i|¬Å0•Ûô+ÙãñÍíïD®ê–Q ›Of_1Ö‡¨Fû`¾Áä¿ĞèÈ¿â£|\!Æ-®ß>äã@½œø	GÖ6ÇÎ¶‰¤Ÿg˜®0¹ÚÚúÁ{½³ëíSäìİI@iïÒùûß½d&‚ºßû£yĞªO}î½òƒÇ3Yzèˆ½õv"¼mÉ…ÿa`Èb—{©YN¤ÁŞîşÑ Óßİ“ê%ëÆA=E|úÌV^O­/0œ9[JÑ"¡bºNÜ³VGtúüÎaœ1’—ÕÏ'P‡büøCX×ø
í…<úáÏÃa€»çdÄ	€— ª`–æ —1jñ¬ş>êHGTßÒíÄ	²š\„Pÿ8]‹ĞiZ‡o>*¸[„ª*’Ö¾y•­Ãá§)ªÙÙœG‰RÔ¾³ß¡›R—sı9¥çš,@ÔçÙ¤Ş¶‹V:ƒTÖ uŠ¶ÜÅ'­›;
ò"³…	ÊK.F¤Z¾;úñqa-`ãsìÇ•Y&ßEu2Y€9Œ~/ùÕ¸uÏUÊïŸ/Æ?ß{âÉÄşxŒ'æÅ°šù§¨½d¥ Â'0r5«ÌşE²£/”‘ ŠÉZ€NĞÖ~ø“÷t?ÄóÊ8’ˆ¬ 2f)İ´çŸä×Ã\÷¦cälá¹°™ş€UÙÿïÿ'â4 §ÑlÌXÚ*©ÀÕô~2ûnŒš\šÔRĞÑS¤¾Ù°Q(s0fîÉ¸¦Ã§küÃ~p)òğr*Úö~ôVmˆBaD‹‘~0ÆK!8^ê¹äÑ@üŒçH†â0Qy4Øß¡H§p£½í>¾7Ú|™Y&Î”IÃ!S“Ó¯½âŒq+'rò¨áAïÇ^K¿„â<œY“8L®ßà¢ß|4h&ŞL‰e3NâzAÒZ2r"î1© uÊG«ÉÇ‡â®µ&kİ	f>…Ãòd~.EÑÖCm4=Dµ<·ãL¡ö*·öÆ•´²rmm†¬êæTã<0\%ÃLª»¢Ù.¬p§WÀLÖ²åã¹œ¨¸¿•fÇµûÅÌH¶tÖaó¹<³·Ú‡®—)äª™kAkDÒ+ ÛDšlPQÃÖ˜“mœ\Ç4jãğâ%†RLÏ~— ‘GĞâ~ÓaN¡™)M¬iÜ(Òy53Pbë¿õx~"¯ny¾p3Œ¬™Ví^â‡#æ5íåWÿTe©q„÷$À±üıÿXOFõŞ×Í´,_>¢Bæ-“÷½Ì´KÏBúûÿeş/!yãUbJe²•š¼R0¢ª?OáÏæ
ˆ75Öz•Z5§!®í¤ ô<¶`Y‹¨Œ<na~ºÜ³vÆ
 +¿¼>ÆI, ç¢üÑj#Ûòş¦AóYU%âøö ×ß¢V¸Y„–½~!Èõ<80n#‡¬Ôº…c²ÕL±Ò.«j†çÍ'%ÑÀÊ‚²ÆĞÍ]OE-X¤ÒÊM•õwNEc¥qü6}ü®1\ÉZT;b­©4ñEœDr¦°†yÅ›Îsî\4’Ñºùji»¤G‚¥X6lc¡ù<@ÉŒYò77<ˆõ5ëkŒ}iÛÜ å†ç*gÄ^“D9$Üh¥”î/t¿ŠìÅeøÌÁ**)m§S›	~ÈMd³`¸{¨øş-[W7[ ª‹j®4+K¶êØ4À…^x­X=n }b|êOÉ(±q£öÎ‰›õ6ëÍcšhñ+Gİ¦~¡Şø•ë4°ô,”Õ­9Ê€ä`‹lè* ¨+ê±Sf¥t.Õ[ä¨[¡5{ºáRVËç¹,Öu~ìšûoÉJ™½½L­ÑĞHeºd[£¡ÖV¶1î8éÁ©0a$ù{åJ)ZjCÄşÑfy@²œI—Í¶0[K9<nŠ8}\fÉ£a-—®âÖjV92N<"V°ÑóLùX·+ctòØË-{®}±3uÁ@ŒÕipayËàÌâˆ|Íş® ¨‰ñ¥%1ccå…,Si5Èq?ÅåÚ]`%/&¥Ô‡ÛPe’ë×‚ 
Ë¢*+Š`¢†*_6¹”½ÊÌî—Y—0±8¬…¶3€4S'f²…éŞsíX/Ì8ŞÖû³uq– R3¶8b™ê“¿£h¤S^—×™%²\%³¥å¯òW¤ÜSù-7·quaŞ]¤BwQ-7ââ³Z–IÀ¤´hÕ™ƒÃ ó=Ÿ2Í®8³İ¹‘”tòÇ‹¥jğ»?ì¾°-zK	$Î÷†&LÛ3y¢w™•ˆ6?ÎØ~öµÊFâ§BŠŸ¿AT|ˆ»?!ñ_¤İ:3räÄÃ=Ï›SJ«JíîRòĞ›ÙÒ)GZZ¯ğÈ)hœ»7ŒÛ2Ğ‰U»Yß©7î÷B®æ‹ö™ŸÜKêÈqC‹®Xö ®¹°0€7ªKõ„K¯}í6-/óá\¸–rr—0§ñ£Í`dB!ÿˆ®Ø;ò¹ÌCP.“Şn¿ßÙÕ+.é.uiæ¿kúÕ-ág¦Å+s•³79'9‡[ÌRt/Ì€L’–ıÊ•ºGlg-û‚ı…¡äîÆãFm3œm4Îñ¢¹Š!í²U·í·yÄ_çz|Y?>‹_Ş‹Ïtâ3|ø¤_¹ßí8ğeı÷à÷œ;•éxùÜpWyÛİ¬&÷º»a]á}ç|!CåÈ—™@ÍşVŸ)›nã7Îô¥|®ÊmíÏâAÿÏ[ ás™~]-–€—p¾¼™ï¥ÅõòÖ=/—w¼4ƒÁÁG°¾:ß+LÄª6¹`ia–¬+‹3§KÕ0Ù¼k´ÁYÔejd¾ë£\cù[G° ºÙ÷Où3ò³¡Ê´è-oZ«¦1¢Jä¤kÚ„ÆËZ¸ßZBdaåŠ©pL!oBVÿDÄÄÛ@ò6ÏAşì¡ó#Ğ“R¡“ˆ.û§ù8††´ëò:Ê‡²Ø¢¥ŠMÅØ0¶€Ú_eçÒ“çäÊˆ8Áé|XÿÛNQö8øÛ>êìµûí7o~dÜæ¨»KœFÕÕã,íîßÊû‹	§Ò¦Ç¬¬³E—ºN~Ù˜7$ˆæğ¼Ûîş˜–ÇÙV-}»BÎ s´e*äŠÖn»ûª×ºW»¿º’y³Ğraİ~„…L`VJT Úª—K“ .S%½F¦*¦Ûo¾^Š¿•³=Ì++ü‡‘ÌB-4O…†¯áÂâ@na*H¹"BÑ<5‘?tWåïŠ7XB SCùk{[6D8-ZM`Ú¾±*2	èKM‚`ÚXşóİç«UÁşG›±ËtƒïâŠH Ğ&á%WVk7nÒK!˜\èLüÊÓ?¢6Sºå¹Íúš‚ Æœœ·Ü£şKï‰ûÇg+X’o@ú^yº;¹gÑı(NMŒ/à$~*¢G¥!£¸•ü±Û@ílƒ5„İTĞê_¡à3—ƒ„³‰?¨"¥ê>mX:ˆo6Ä0x’‰,ZôĞ¯Yû· …qˆ¨Àu%¬©—3¦6WÌ´­wä›ËÔK‹hNG hÈ£­ÔîIÊŞ¿ÇphG3ÒuŠ½Šÿ0 -kå•¸
Y„w>®İƒ™ø>˜­º•UÆCYW›å ËW¶õÖë•ŞV 6ŠœÔ…Àæu{`‹í‹ÀªÉ9‘øR
†h›Ii~¥p™c?É\à˜¯î•â¸Òô#nïšOÚâ@N¶Ë’…7©0ºEÚ¥Ù/OL°M»tñ‡‹{‘ÆŸüM(§Eú¥0¿ş;ÀüÆÁ<r©_%ş›ÿoğx]8¿n½òøÍÇÍõÍLü¿‡›kwñÿşuãÿµGcŸÀyx³øKãÿÉ•¾d°¿ş{²¹C8ädƒê23Ğß†<=Á`w_'¬5ò"E3ôuãıınwg·U[9~jno¬Wä‹ö^»»ûæ€¿Zƒwé»ŞÑs8Î¿mïàëMõx÷U·ÓUšiq™DL5cy70`R±M£`ûOGo€Íô9OG&º	”l$cnˆàE°|fá3ÙW®]?¯z-ÑÙK?Åµ;›E³-Œ1Ìƒ³cF3:gqòSéĞ'”›€Òº!V·ñ­Ú=<‹º²ê˜÷öxqísUÃ¥·úîª£´°y7Cüé²j·İùÛ9€¹{ŞÙİïïòç˜a¸,U=†›uvúB«SNà;¯;í~{°ÓéöZŸ»¥q¬üA™a…ëX#”¸´Í3/ßî¾y¸ ¦^,ÛÏÇÉqò6aüas§zRDÛbÖ€'æ"pÎatÌ†¨jÙñ'a0b# aáÌgpäÿâSAäR‰„İçöşàe÷ ¦m§å’Ë¯+_ußàİº1j³£ñT$oÑŠü—ƒ9yHF	†²Óª(uË2ğÕõœşœôsoÚo÷6n œQ,îÃsòHöPÛÙí½î®:íÃşàà°¯Ô=AZ.åIıtî×çgã¤~2K‹¦>­æúGy\´”Ã…nËğQîíòÄ)f¾kßÎ¢ÅHïÎá£—öpTçUaSU×4s+n$iQ¨a7766ÿáfÎV°Eók@]˜•Û€­¦‹ºN>*;[ToÖ›ú»?u[niï{:èõ'ü=·fëŞjÉÛõ¯ÅüˆB–ÄÛøŠoô^õşë•çaò~~Bxüyreù‹è.ÂÉEVG'»uİ2#åt4[N9µµìÑp¤%f•|ÓñV­Š<ecàá¾éïZ»:Å¦ç¤˜¡¸ªÀşàÅ§±•uÃËÅ´G´a©ÀüÍj$¨{Mè(T&ü›¸@3Q—\ñXºg5}ÚûÀó'‰‹{­ş—Suõ‡ıv×Üƒ¨°Ê]ç@(Ã0DàI‚L°qAò-xğª2Bıã/)\Ô¬·Üò²ãL29TIØŸæJ—y¨EAÕãYx2çX×1IÓ6ÖàñÚ‹á	ÀcJ!U4£Lµ”rl's³¡*Q_«ç_ç6m|1©ŸÍ‚€ÇE¡‘À#iÅÙHüóXK¼Â¡|v¬½‰âÖ8×®Q<ë-œ¹uò¹`ˆÕØiPª;]ë®³j©¨† šõ'uª(äÎÌ}‡õ¤{ĞëĞM<7ˆä
Ùsr;´¯¦/ÒØDöóŞHôÔ/a2Jµ7ä:ö½o_º(àE¬íÙøâ±ï2Évw_v~ (×+ ”i]ÃòÖÎ-İ7~“°Tÿ
úÈæÌõö¹Ç3#…maéáPÆÂaËû½Ÿ &ÇÉÙT<âOª>š~¸–¯8kø¦L@$÷¶º,~¦¥øƒuøKö*DBy8¼Ô¯ßUÏNGj	hß·L Õîî«İØ÷ínIFÏqŞvÆ9êâC„Gø—S¹Şá›N¿¿»¦Û«ö‰è^ã¸Ñ`ŸWyÁ^?-‡µ1˜Ò@xò±Ùô0.?|=O> …R¿€{œ†OægÚÃS?œEëòì‘ó¨™¾ı˜Ä‰üî'´7çïO=Ùç£y²‘~£ç®3Eç|U´\Š#‡Ftè¹œº?³±ÿ!`|Š&Ir7œql>áÿÎü“6ç~ıá	“1fxğ/cçC`¥)- rŸ¨µ'¡?œÀ3<,b¢)UÆ3õ˜¢‹¹ğ”	!¾Öy!~fóòppÉé{OÕcÕŠTJp¢³I4ñpğ® æaİ[û§ŸŞ)5ŸpÊ–HÉO–<ŠÙ—öMı¬··íN¿µAj((ƒğkdC,k4ˆ¯&‰ÿq‹KŞõ†®£9é8É>KåıŸ|r¢Œß¥9íI´³ûù'qÇø.#Ú§•b §ŞnIÉ?-`¶›6Qúéh.O”}ÈS8—ùëßd#ù!ñ^{j‹Ì5ÑO˜üQj=~ıëâæ´ İEíõ#öó<NTÖ.j6®uÂB •B %RÓÂü?‘I,,NØ¹«‹{3â )G4ô†38p™Â’ãbIøïOÃ¸¨•.QØlvVb”²†<#VqrÑÌ¥Ó[Ù0`sÃ9mİ[Ü{ÜEVaï}tÉ°Ü1FGÌ||fPô&.ø·rZ0³/,·ñ´}‡$â`ÀCfÀ2¦ÈénÄĞZiâZ¤¯÷öïv³{5öÇÓQ ;3×cáÚ›Ál­Ş|ToÊÆP³$69¤cÙlCµÍ‡şëßØó+9í´¼Å|ñt>—>ˆ”1=ŸÇty€AÀÆA‹ŸBÒ¬†±¬áiÂ.C˜pŠˆ ùÃo$¶ı+ëœa)¨æĞíJ¯N›µØØ¨¾İ)±›±ÎØ?Oû3Ú¡$8^Jé3yWV+õ|Öİ¥õ!Ê,ˆ­i¦üx\cöí.t³Û»%µÕürÙ!ŞÄHZLˆL+_Qf²ED°¡Fõ¿Ğz3åR+¼ê:}ghe
4è²}2ó1t/°İáG`¸7P°Î³k¶3¶‡¶—ÊàÉúV³NiÙÍ^t 2ci¹ZßÓ–ò^rúÖŸd_r–«nE!wı	Ğ²Õšö:ûzéÖÊúc,¶ò.#mŸÿu÷ùó©7†ÑiÜø¢m •Çã‡ì?è“±ÿh6¡8{xgÿñµæØ©úxøç¿ØşgmsãñãÌü¯¯?zxgÿó5>÷ïÿûä$nëÿêö½æ*ÈĞ †µçç¬ù„åëäÿ5®İğÅçÁ2Y¦ıû÷çşı}à‘àÛÓé3GH1OåR?ÄÇ”˜ür›)¬*a#½ÎşÁa¯Ó[Ü)†¾ÄÆz'³hrşŒkF6ÄÏwéàÙàM/}UÚÚë±´¦’:µîh¯…„¬¿Ì¾ãÒ³m4ºî¢ ‚&´Ù! èšVfºvv{/ºÂ9câc,A”¥0!õõ˜'!_ÿ`~ !ê°ÿ ‰?O"Ì=›ó°LWÒ:(MO!Ô¬Ç„ı¾’ĞöH©ÌŞò4_r|Q,±âŠg®:„–Ä"Y¾…ìäëe^(•‹®|*”Y)Ë¨W
ë"¯ñ 7l,SÀ²4¥ÂÇ®<+„d[Ã¼Ìw9-™Ê^Î„šŒ–ŒT”éš²Q¨iÊØjÁÊ'ó	¶ôÌféÀObÕ½ûË_~@ŞC‹uT˜†BÒ«¤¯¸NG+€²‰zéŠÔğdO)!µèz¼et=
¨@"KéÇó£W­æbüÅ|Ë!ŠŠ)
Ğ,‹fs†3çO®öàœFgYôß£ÒÃ(ˆ)Íi4Ÿ$ÌÇ\çstŠY-Xr=£"Ì.B¡Ğ—Ñ–,IyíÂñ°«
‹EÚáv¶Z0™'Åú’ú„GÚ#ªŒQ
! Âqƒ¼’	£¥ÚmÆâ ÆÄ[D²zÔÿö ŠYM÷˜s'ÿ)şÿËÉ€7ÿo¬İÉ_yşõş5çcm£™™ÿÍµ;ùïëÌÿ±‹ŒÊf“œRM½ÿ­)Q=a®&ºŒ,²×E%mIaÏuê½o
ny—fXEŠaÙ›àÅ2¢ÕñÙsÎÊŸußÑOÁÎào¬Áœœğ”/d-#X$,“©ÂÄñWXU±èªWÇŞ1?!óO8wl<OyTã±ÆıÏéš†¸Ód"ç6åSüA¿AøÁ
ü:|±JÅf.©°À¾“A%CWÙ‘'ÇŠgà*¤­®@.£¦22†VÌ˜2,[$Mhuø|Ë	…Z%‚CÙíº!3¬ÂÁÜ~Væ_vI²ÔØ94b­ñ`ôÅsä¯é©äèqh’	µlÖ³ï|Yó-§Xqè„x†}¸eş›z-ğÑ@[Ö½.™i£/Ö’fo%·ŒCŞØ¹>[ÌÙ_Î/à‰ùn#~ØÉ²Á÷†ô`šÿù>JÆ~8BÃúUç3ş—âÿ#X4èÈƒò\LI(oñ:`ş}íq–ÿ{¸¾ñèÿû*ş¿ì !2CSÏºÁŸçÁ,@*³ªCz‘ÊÓ“Ù34TŠ3¾tŠĞŒñØ§=gÑh]†“s H‡ÚÖÓ€`ÑˆaRË–Ûqágåé(|v€v0<ËáŞÀîÑ±.óß±U('<µãSŸ½ŸgV· Nå$‘#Q¿‘ÒV™·8˜5NFÑ	È> sÖèî¶wövaÙ»Ï¤šƒ?RZ§ÿhäs† âŠÅó)…ÖŸ6`$b@è¢ŒÒI8
‘.‰v˜m[ª¢ÂŒO˜!H<*k°nòùÜÇüŒØÑÀH ŸÓ`òİÎë'¬­[Şˆ^Ã$K¯38
gÑ8c+,£WiòWÖ£ô¤ËÂFk]	ñ×¿±_ÿj€=Šqˆş"‹:EE;É!1 ?Äü€rE2(dTç&Ï¡ªŸèt ŞCx³ğAÒZ
Ãpkw’•ØPéÅÀ‡#t
S"&.Uo	÷p¥‚uõ'ğò…?ô§šŞ\ë›t¤S¹šôF4Â]!şôxM´DÃ…!~ê»¦©vÍKe4“.¨€üTCÉ±=Œ„)j¥~£¯TÅ+,Í{(ôkì?øç:ÿgQq0˜àÂ»mK€çÿ*{²úŸ»ø_éü7ô._ŒC/H5¤Â^hùÉ™Í6	.ÙYà's DbOæçŒŒŞêsA.ûÌc§ItÌƒÖ˜œµ¤r÷mO»Ø¨<$…êLàáp~Š…O­©ó›m±§Áø™.i@®šOëñû§x£Sºöp(©iºĞ;‚¢Rêmbdbƒ2ÎI¼æ·&Ê‘ú£?¤á#0ğ‡"“sE&iğë0ø.È³¬Lá 8A-Z^v~Øİ)@C›|MY{BôÖ*ÙæÚósdÈš¸¶1È$@©¯é¨ÊrU4pj(Pdb¶şÄVˆRÓreÆíõR?Fsœ“KbF˜ôofÄCP8İ=yk›Ö¡, ºÔL¥qÆ€¡ƒI…CMiM„æ‹¯˜Lú}­ğ	\jJ2®£´è‡Ædbs_aï}äq S§pT‹ :¾ó3ÚÔfôÆ
`îQ/VõşñÑX eÂzùGNIJ3æÉçíîŞÅã†˜ïëÕƒÖ,õô…·n0Ø¤ó{ñ¦Ãö‚İwâìVG¼gìÿb¶3ué*÷cE_I ¶	ÏúDÛæ™Jw)ŸÚ‘L‚SpÍc1olkafhÏ¿bÍ5m%,½HıF]4€'¾l2 uBÖh>ª¯‰¹g{!Ğ›æ“,rÛóeÅ©’
~Œ`o€¯ğ#SÙ¡Ôæ¦+dñvÆ$#¤‘Uó”öûüß»ö[öşosc3Ëÿ­?jnÜñ_…ÿû×‰ÿ–†«ıáßèM„;'.ÒUá…Z	£† pi¸©£W©3.¿v1½î»÷ª+İw[¹.ó>g‹¿8èêŞ;Té5ÅuVma\²î 0Øı¡ÓOc˜ñÁóvïÛ–‹ëJÀR©ó°S}@ïU¼ÌŞašg“æ²;|»Ó¨eÇ¢%¯³w«AûÑ×Z¢¶Vôâ“ñûß:yÿ3ÃÈpÅ(®•-wb
Ê2ijGAáä}@Sãà213âœúÁxŠ¬1†ØgZî´âPy”?s0Ùáñ_¼N? ÷bƒ
ğeOÂÒ˜‹08™©÷à9…Æ¦àx˜ã|Í§2D,Uß9´g¬1.“ùhä¨X°ßhÁ`1ãU~Ù©<ÏÔöË‘Îs€Hx˜Ì€Ù:àÅ ¿‰öáëËp2lÕÖ‘†²†{Ã•}qk²ˆkï‘½Cª™fúŒö\íşi4ØÆgV•Y}“hˆŒ1‹`†g@ÆBøTO^kV²x§üZ©ìç<HÃvz±·£¥TàåÌì	ùmXSß™'’}bkxGmì9èM×=q¾ê@‘v:ÃôÒ™ÏµlÊÚ}µ©ô=_ûca«‡
+`¯Ã„·¿?„	µ9ı|NY0¹`;Şá›ö­šøÂ~à×š><K¿³›÷Off3([½´˜¦ ZÄĞ«„[±P¸HLgÊ3FH¿•G…ÌòŒ|sfü8b©X¥"—dÁ&u*éJË İ&™ÎjØäÃæÁÍÕ´ÒCÑY
!{êà/êV'Æ}Ş¢$s|:•t'ŠëŠm¾ÓzçÊÍl–0ñíÒÏ´LJg²« ìTt îÃph*jÚÄ²;6¿„ÿ¯“2dğÅ âÿòÿÍõ\üçÍæZóÿÿ§äÿ—ÍM“Mmƒ5£9ûWŒß×>O¸1ü˜]=`'ğMøUë8†g2<!Õ;ÁÔÕqRÏ……Îğ÷”Èp¦B*ššåÙ|âTõ*â„gÇkƒQ8Æô³¢½ÜäœÅÁèLÙ	Í&†
Ãéœm1y§-«ÕÃ¨ñu„
'•t®í½€Ÿa|äˆòS"ä¾D¿Q¥pÊÀèœÎ‰Ó	 3uvì1¬†ï÷ş”ä,ÏÉÆ!Â~G•¿&ıÅ³^1R¦Ãzò1ùô¿äşom}=ëÿ»ñøáã;úÿ5>ß¢AkŞ¶gË©4É,ƒèç$¡ÖØN¥1=rÑblå5ğ˜YªÀ-@F—–Å­¥ï6æİçîs÷¹ûÜ}î>wŸ»Ïİçîs÷¹ûÜ}î>wŸ»Ïİçîs÷¹ûÜ}î>wŸ»Ï?ÿ·Šø< h 