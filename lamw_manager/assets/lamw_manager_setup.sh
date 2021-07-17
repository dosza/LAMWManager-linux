#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3305304692"
MD5="d4142e9ff416dde635016636092652bb"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22608"
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
	echo Date of packaging: Sat Jul 17 17:01:36 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿX] ¼}•À1Dd]‡Á›PætİFĞ¯RN¶şPª7ş@Û“b\1ùö,÷o¢Î–8áqä_ùT.œ1§v¨€Í³†´½{™ïª‡Öö–xùQø?O%àìV7re]Ù²/|x
"Ä¨í…®jrW³i<ÓÉi:T­Ëê{å‰ÒQnÒ›Ø\F\Ïq¬ö¿DÎ%†gk{˜Õ„ÎèœKì¢ ½“^CÀ`]·Gº}
íZïÃ‚¢wÔ×ğ„ÈB9®cájakØ¼¼:jEfØHM¾Su‹s¿õƒ[VÂ®½…ÌÌ†á¸wŒê;½¢G	tÎb°–øş:?\Hß^øAmÌ9kZJbg¢e—7¡‰ù:¡¥äñØ‘l{;OÇ8ŸíT>ò-´Â—Ü€aúş†e#…4ˆrPØdÊ/´ÃÖR6Ğ7ûßÉdÒ%¸	>-÷ÄêyùiV·èH×©(JbÉŒ>ßˆñNfèvÙëFZènQ´*¤n3c*Á‹"=ıQoş5ö´½s„”°¿8›Øõø°ĞäfÃ%7
3	ÓN1¼€±‘3‰'\Õî²Ô=Ú=t7êçR(]®˜5eæ<L#A´~Šsš9¹cı{³ïÉh€Ì÷ÿú	AC¡Š²â-E»ĞÀ8™ˆaÿŒ!±ñS&È(÷õ(«	;!<KìU[¥´¦<Ó‘OÂ€'uµsG•¸jÄJ`Dêg¯%±Gíß{kóF€²§Ö8Âw%TŞE$¯\ršÏMËX.h"Q&9ÎŞ'QÈ»·iŠ«%ûË}[vÕèç¦è~p6èró¥iÒ¬Â»,lA}ÒDá=‚Øáëƒ—Ô•”ş¸ l®5ß“„•ğéDƒ©¦[*£®Q´{Òº”ï*ÔĞŸtJ‚Œâ¨áóº¡`ˆ§H¿è­¦In¿¦×_ø:É^²A(1ˆÍ qÑIĞåş)K‚ğÊæ}¢ç87óÔúEGÂ}ğ·6¶»–Â¸­nË¹]@ˆph`r}ƒ§–vd=m›zİSØ½wş!Ğ™ìÑËŞ£¶Só½'A?ª¨¦.éö@¾(7p*ë"Å4I¡Â¯,@K÷‡MıäfÄù§	KôS;…ä‰PeôábŞ;ĞGú4¥¨AZÀ, Áç_õÿ¢8™ƒRyµph)M¶''‡¿ôD‚Ônt€%ÈÛL¼áäæ¥R¡ú;G»«›CšŸÚ2Ù'(v£ÉÅÂ™Hëf3Ähc®ë{3ÉiqùuÏlË0—mÑ(ôş¡ÁBEJ*·>7pV'å~›|º×S­½´£ERÛ¡õ­n¥)ìkú˜otz@9Ñº@kX]²¹ÃèËŒ§Ä:Ë,“'e­±IB©šMæ‘ùjS‚täzc ’¢Å²¨J%à
T^ÎÅ/TóPa¾ÛkÕ…ÓæĞ#»£\ü3˜¸ÑÙ¿{·(Tz|ílvßwQ0}«Ã±Àä•«t^É3ÿM×g~k*:İ2çÿ´ys‹"JDù¸äÌ	DJ¨ÕGØ‰×EAƒÍò	c‘>­'y3ê<X˜ÅÈ,üyà%”¯ö¿Å_}iÕ±—‡[–?¿¯oò(øÉØıŠó›"KMŠÁôÁ´ÒÖSıÖÛ@úÛ-ë¯ÌÂ-Øqj…a,7Â‹rújïÑæ—=Âù‰û½%îèà^Føõ×OäÕƒå¡½€}lÒÌŠDvÀyĞõÈ4€lnr)õ¿v#›½‹¥t5D„8ĞŠêîèzóõµEm•T”€C»$q³sèbJq+ÅÖ¤‘>n˜vú†T\µ-P;kš?ÚLİxxù“9½¸Ïâ£ü8Ÿ¸ŠÙÓfZEÄñéÌ:Ô™ ­_“ÇY4"TÖ}
j®°·q‚gÓÅ´*sR¡ƒ3t¯ØöŒF/©5Èa&ÀåÏ@0y¸UÌFû³{é“_Õyy¬hûÌ÷Ü¶t§S¤ÀÓm™Òø©5òÏ)P1ŸEs­ƒñ‚;+Ëƒ\Ñ²1¹R(QÈ“ÓÙZ!·è³²¶^—:ÀİH']Dgw¥3(5Î-ˆiqt}Çu6k0¬œ*je¶—ÖºùİuB›ÔIÛÕ‚¥yĞuö³Ø³“uÁ“^÷¡Çƒzìâj¡3<X`(@‹Û±¤t‘
•A¡h@”=·PÏ,
a¹~Ò6jÔaÿ(‚‚ˆdºÚÏ„ƒ5p™I[]d¨O®ñÁZ>Œ›«n¥#¾×î§:LhAı—ƒ®U~ï¦güósÁ²PùfÆ›#>oßßTíÄ8]‹L§¹Ü™C&¼‹™õ¡`,kPXÕ¤föQÑ`Ä‚/ìLÃds¦œ7Váyº:Â²÷ª†5–6%î¦ÕP=ë1lı<pzšó­_§,›Y!Uó0œµtZy,¦Ì…ß_zB|XZ˜¦F$[xdª”›äûÃëÆYÛe®Ç;tÜú[sSÜÇÁvj^`e³hQ¼àş•ÚÉ
èUğî·ÔÕîGéë½~Ää‰°îZ
İÕ÷–µiL5Lm–@;¼‘û"ÿ/Ù˜J”T•N
‡yÒ’¾]Ì›°ÓıÈ5*5«<‹ø>ãäG§„åB+°´¨çzoƒ"E`­@khwå(ß—è¬ú;“ Ğ7’ÔWG@Lñ»ƒ¾²mCyc²¬>69Q¹<¾î\vÌ÷'e7'vÈâéÕ;Q<5•šVQCcI m ‰škÛS=¡"  iÍªÊŒ‡~úæH®èEß¥¿3QÍÅq/dDdÔ¾âßwÊÌªŞ‰&µ¤ˆÇÒ³Zín$$&ĞZ
 Òü‰ÙÎ¢ëã"3€êÑpqœ·e{)İü–µr¿wI§úÄ¢õER§Qí¬ƒÂ(‰êĞ¹ÅÛØò†TªZ’×ëtÊZ,áâM@y§Áß²öÉ¡t¹lÏÎ:·¶Z>Z­í|fü¹uXï’x:‘È"Ëß/_ûÖHÏƒÅôÛ@5øÄPŒÜîEÏæ{#¯ŒW!º{&l‰“Í~‘ªĞ%¦‚aXfŞì¶=t×†¯± ØóÏ ¶n?½€*,ç÷cÏB®r *æ	„ß×°¹â±¦j¬ê*=EĞ
ZÎıî_‡·÷Î &td¤#²¬yãW‘3@aû3áç±O5\À y,ÂâÆæ¸Å=³hš®%™l{¬ËØÅÆt›Fb_¡•ïğd‰.tİzíi9SÈ{mß:´©-#M˜Û®î¸@N±{êÓOúôÍn–³Ÿ³)DÓ¤òGy‡Êhò%¦xîõ„‘/C¿fk£Ck´¹$ êÕ!Mi<ÑÓlëïPÓK:S§² ":ƒQ¤{¯êıá»–) "û†Ö`0 –-mÎ82±Ã’70õû}K‘Aİ
QÍ/¸
…Ô€’Ñ£5¢fkğYgŠøK,“¯ŒwK€(—h­IVS!(÷œ€Djí58à,Ö=u-Xy¯Ås€•«{c¹#Ğ¦ïáWneæõ¥Nş¢—kPÒ£`;ÔdÃ_’f–¿[O†µ+ÖEöÙ”GIBtù«eòÓ€°(Úß›ëOš
zÀıRğü6°Ó–óPfÜGßÂláÚË-È¬¥á–XŞÄv8 
Ûß[Œ£^ßM9!X¡ãİú#×‚*TóĞÑi˜±lÒU&¤x~WÅ°Ö3<%“âš‡z [XncŞ=Fºâ²?Æ»i¡NÀ›Xç©ìEwàn,¶SDPÅµ«Ì½|LË–S„Ôz@GÑ#.(7ŸkT"dÖ‡ä:´@ü_äîX÷rÓÇ4-ƒÃ›È©²üA>Üé­°`Ï7ø0ˆ¿˜>¤ª¡ÄŒŠÚì’pë%ŒF˜®‰Şb”!x>Æ®6ëŸ"oÂşiq°P‡@ÊPlè "„Ó_po_˜ß±ÆĞ ÊØ=NÁµ~nµ•sŠjØÁ†Ÿâ“ÑFÏÌ„©èq›ó`.J:Mz_®OïÂë—›İwHå§%"#›ª‘_J¥`«¨ÒL†Ë»NL$[Á!]ucÆ+jm]>¯2ÊS3Ó
)±Üó§Düƒ$¯‚å×<h®ô?f<1ã˜në†ò-,
Eéc¸e?.±¸¨'o>@s)å#ÒÍy›E¶HŠ“Ö/d híŒ¨ŠÉ—éÛßŒ¦ò$ª²nC´ÏÌaÁu½ï~šº<?;@:Pñ¨Ã+Ô"ßºt­ µJ’Ïü>tb‹Ë£B”å4Fü§yƒH½¢ŞØAÑñÅ_—AÀŸ CÜ˜İ¸}–ïÛ–Ù²<÷jYRGb`%–Ğò?-ØF¶½ÔRÇ×–É²†–$3™ş€L4ƒhĞ˜¾³Rïháã[Šjù¤b ìb±7 >°µå°ªcƒÜ§.7ŒD©>ˆ¦g*¥zî9,(Š6oÚ®‘Š¦¨E§höµb~¦1<­ş•Ü­Œş±N9*`ô¥Ê¡µxXnlÔ¿”«»—áw†4ïaÌ‡d¬%òAß&ÕÇ°i]º÷ƒZ_­ãÁâê«MŠš»¸WÏ–ü}T9ÄìBíWª~ƒ%¹¬äšK^Å
Ãë¡¬=*©^{Í‘¬?¾j$–eÉª<êô€<°v|G¢>¸‡'êŠíÿ²Ñ±—S^ÖÎuJ‹¿cÉÛ»f¢×)aÅ4ŒtØî¡>gíó–Éë°ºÃìO]ˆƒFb«¬^Q’-Ò®2E†&t<ÅÑTy7[©=mìÄ6ß©ÜBÒU 3šÌå([]KøŞókU÷”étğFgWQ
‰1g/æ<çMÓ´±§õ’pÕD¤a³w”ú	0Î&·ó#/¬|Òíh,Q[Ş‹LßA{Æ¾ˆƒR=ûWW*ïUÂÚ£lÄqô`\ı¤ºÿ}‘Ä†¥âz'Ü¼›K‹×šß™Ş-¢Ô22j'nÃ,>®i¬sJn5cVãï}v³=ÍkİÒ(òî—ÒÄÜ³h°î™ÀĞ`ËĞŠ„?"_1‰ªF»"T=Û­X'7n4ÁìP—Æ"ş// >šˆ–Wà°?3(‚fo¹«$«|*	É•:Üƒø6\$&=«ÙŠí’ŸbruY˜ë	Ïi'@åñ®0qÃ&d†–„>x4»NÏ^§êÃZ 4 Cıù§ã^"«ó]’ì°Í¾&Ç§hîk1"2e#ÛÇÕ×Exáf`wãzİÿ@@¯¿İñ´µ$5RıŸ¶ÚNuµe…ä£öy@'•·óç<şoiÚ†PV´£¿¨Ã,+ı’ó{²zê?¶›½FØù·Ò&¤}¦×ó¨ˆVß®rĞ3ê˜}–ı2*ö{×7¬›Tñ·¢y`_f8v‹×ø’mŞf¯JÎ¼>â•ƒcA	8ëÂÑÜ&}Âï·¹	ùì.FNlutìCĞóñÁ Q90S˜=MB‹ÄÑ¹¦UXş«2J¡´¯ù<€å$ÿ-úÆqëí‘xóeVR¬¾}àìî<0*YJÔ‹GWwJNC«"]î€÷PŠ”İV–ê(7Ö'z¦±ŒÃ&üHK`ü+LÍ1Ê…Âl‰ş;ÈÉziw?·^äİe4cŠ“5^Dït7Bì…­£AÕ¾i½;ÒÈC…ÚgàØÌéÿ&Á3 •{.œúÍ0ö´³}’¢Eëcvw­¶´¦©5jìûŒhÛ”î~n¬äT ‡z9#0Ît„Àv±Œß—YÃËšEâMªf£n³½I«ßŞ¡  v(Í_=îw8h@ñ»'-–u¬İ]İNß1>ıº²“•S+êsñÕ®ÿ»uGşsà%±– ş,F‹+[,e¹5ê3é&‹Tç…eÔÁ±ù¶vfæ| Ó0“(¹Ôî©Ï£Šæ»TÏÓ Y ?I¾oİyPË M‘Úg$¼+ÊŒ;
VƒzcÆæ'Û—„r¨WÇï4àgE¶ö§Ø|ïlã]ßäIFl#’«ËšÓ6Ï€~¦ƒ5Q\øË£}Ék¦E›3h*L2aqî´ÓNÜ1X,=h<¹)K‹
j\´?-	ÜØ¼Â[xóm§ë³«!çSél¯´N{Ïj*ÎY	«½¢UÁ¾òŸ5…u»+<Gs”ÊP¹¡‚Û`ÑZu [®$¿+¨M«-şÛÈd‹;;J¶Àæ¥ØêÈ²ıí)á6ÜÑ<Jï@ÜARö¸«ÏètLSÒ,%'{§_K}jªìÚ– tÀ,ºW±¹·¢ŒÀ¦ªcr²¶d©$ì€·Ç‡k¦$±jóW¢İhgàŠ¸=Ğñá¿“äŠæj5Ÿ™7œ¡•EÒîæ‰¥uXŞ¬WSMÁ|/»	c XZ~rZ"‰O,ùÈ‡9ŠY cVïJèşlçó¿»­„™¿Øòµ†TÎ°Ö< iœ{¢;;‚·TüüÍğø¦wı|jfËã8áqg„şX>{ô¾¸BØFª­ÜBæşˆ{àã{4n‡fåM¾ç¬g-7=}?¹o:¢vëšÆN€ A´i8@q¡ó-L1²?ÑÇ5\¢®OGD³M“×šúÈ#î©´WÒÚê=²ICîÄĞˆ¼e[²ÉkëóG¥®e›k½¨¾Åüà{X«rB7ÛàG×(Ÿh›g_¸ä¹•ˆH\ÁÒi\|÷z·BlIYêı´È=yÀ84&Ë«§’ÿ¹%f‚jh'éÈ¥‰lç]„!wROUºÍ€]$0Õg|}AC¹8ƒEÕ˜ÁR(ùÔí®¤e³Èäh“ 7Èz^	µí)ƒ£8¦­ôjˆw…f>"ĞF®S2²öé¼‰ã°Ó’.—BX³7[)LÄby÷ÂÙÛ¸°(~a±5>&§dÈ1v°Ã|P¹˜û²:ëéOñ_6¡ÎÃÄ¬³’jDÑzõ€Ğ-ï)şšX³P)š–Çäæ=y‰Ü…˜‚Øö5ãT8Ÿ«6ºtasª¸écNn,Ä<$N³tEÊøªx	:¬.ôwx fĞğA]ÒiÀn¤C'ùè%7wtC¹nÄº2ş¾—ìk…\r`DzJ©
YXª¼Ñ!jYD|½=±À¥„—t…ó‹"‚°2î'QDNDÑ43ˆÎõ´üÂ­¹/zNc…TÉ¨ÑÁ9'±‰ Tyü'Ë,E4‘"ŸG¨ú
c9§ô‡üº(ó™ÿû˜d+íŒ	kk][ ¹TÀi&•ÙyÒ1ò(„€UyÚŠyªià‰8èÈ˜— …-a\Oà#×âˆ’¢‘o°1Ğ#Ë·e‘NULEvŸ-¥ˆ™Õ`k[¼•bğfÛ&høÁ	|…r…rQÎşÁ¯e8©Ğ)…PdYdƒ		)‰sTÎåz¦´ZÀ—ÚŞkèxòD„câÖ¡m3ÃÎU!·Õ(šrÓ¡wCfr-%}É'ÎØª¾R©§ÚcÜ¾6%€ÿÒŒ€DM›dmmëG=¾li;çîˆîã†zSËü'ŸıùRvsgGrí³‡“°—|ÌH¾6Ãã›‘ñáo—ŸKÿ4œáy4ûËô›L#]M[şFVëXÜ¨lnpz[/ùdÁÁ~ÀôÈ¾,ÿëd—©9*|.sês7_“b¸ÍüO–dë/çpÙ2„K“:ªµ`t\sA¬F\!ä[ğ0½Ã*t-W’¢»zµrà{ìU-;Ó.´ÒX0¿a.ó­C=«çÕœ³¨æÇlGRc×—S§3± ‰øø…€ò–"YçûÛXîH¢®‰a‚‚2	Ğyş?ü]„Me«Íh{îS,9JxcÇåPdº¸h(ÍÔÃƒNíió`˜]Äçc—cŞĞô)ÌŞ:
ˆ(Áï¡ŠxßdÇOÀ•¿4ı¾)î”£E-­WÖ53o/Oû3ìØ¿×ûÀÂxËí`_ê×½Øˆ¥@3Y´ùÀsÆ
è£ÖÉe~©Hqp¥SãFqq`ÌÕçµ/YÀYMBE¥\ì|øGä6ÇtZ¹gD*9Œm)|ñô]Ü}ŒQônY©²şëèä°FÕaãm­¹<%ğ;%ì5]d™bACW??'¬eÛõÔ3˜P“åwÓ¬:ÚÊOüZ[ÆmÇ®=H_ƒÌdòb’Òœ{Ì­>M$›˜V©¹còsV7İÎ³x©(àâMÓFÂÙ’Ê‹‹ËÉ¢Í:vhuxÒ”¢«£4{ir–4Ö'7¬–L–_¤„ €ÂêˆZA|®1 6š%Õ/µ…·e·uN`cm©ÕÒj¤ÆôPĞ=ÚªD/Mùôé¬má …X¢ï4àäN7‚š©âÂİïE†P4ÊŸ0(¤nş¹c&Z=´uÔÜZ<#Jl83‹¨vÓ¯X¦±ÛW4C"+3äáÖlÌ,™oæÏÁ oc[›õˆz`_Kƒ^É?šc¸ğéD³Sàë;BCA 4‰[(o]my™9’‡êhõ²Í!ØÕ>BaUPêÖ,Z÷qµ´×Ô è9œfİhéı/ÀZá\ÉÉĞ7!wLŒs”ĞÌ÷Úc-%gâIs‹Ôõ÷ùGú«tÈ¿ã¯½B–,JéÏ ÊSRu,CáŠx³ÒP¿âQ•İ$¹Âlş3õwó6ÉDğ”^XÎ¼~owRP"¯R€-Gˆz:Ñ’½9ĞÇı-Ônm2A¬óİg-}^Qã¢ì;ï²ìpZ|ØeSÓ2‹he£¨İŸç<s ‘NÏçˆ*ÊöÃ@ìĞt>¡÷X€±£æFw«	?¥Ñ‚‡—š:‚&ùşg©*YX²³»<1õ`‡Ëº^Zp
†w>İ
­˜o&l¼Ø}\€¤äá³b³*G°¼qÅåÌÈ¡Áh{®À$”#`Ø'@a:?(5aY±ô:º´ÜùÈœB
„Â:NANsó' ¼Ó0İ•2w™Á
Tï©ŒbÌv|RÆ“İ¾óâxË"€ºnšRÃ=îi´Ó^Ã¸·Ò"TÆì>ZôšoÓVÛr(¾¿£ÕèÎØ,ñ-@j£¸û1ÒUŠ”«f8%‚\'ş'E_J#ñ?åU¯3¼‚²Ø¼˜Â0›k!p¦g3ro¾N×>·¢Å³YrŞ˜$5 ê_[Ş1ãODŒ¤ãè'Ë;Îø­E(¦9yØ]ÿ%ç·ÒsMÄ­sy²Ë ıÃ«5CÊ‰§Iİ¤Í!»®')×á„&¬³\|m(İdÃ>©İÊw,	Ö#àŸSwö€ÒT!tqDé.s^XG:R–MÏ»‚ô(ÄsÄa³Ğ|°úô« oRc}øŠH0¢ñ£$-¦…³´C¨ßoÓáúç—Q»(0=ëô\;F—ŞkĞiPË¼—bƒWPSæÜÚ‡²}¿ë’e,ûöQÃLlŒ ²®,!’<o¦|™'b¥† ƒ›Ë»²¹çÃÑë@¿;(¤,~¼¢·ÖE}?²ğâ:8…hXUémâG:»åY8jo¡ôƒ:º«?® EŒYòº}2Óö`óıZm1[µJı1KÌ„1Q]E†°KÑUàEeØS¬yü÷ĞyĞ½lk|kúúvÀõ‹V©mR:‘Ğİö6ª`®ªÈÀÃ90ÚÙw2…º«ÎÖÔ¦và0Èo_~ÃEä'££7ºÍ—Ie7}ô0ÿØ¯"Ïù„¤hSIœŞh2¾ÊXÌóGn9¢º—\ ôE\™b’Ô‘ØÓàgH²‡WçßÉ@ÁjınŞ°É·¥ijvÈ¡Ršµ¥®îÚn¾á~Ö}I:¬à·Ò¹ÇiõsmURÈYLá§Æ¸Ì(…‘:ö“V†¸ú°¿Ùß8Ø|‹ÁÃ!oqáfOaêAG½Å£»ä%	ÊŞŞÀ¥§O¯øãhHY€ş`EbàS$îª	yRhĞ=wCK‰§,½¦8³Õ~ÿï†AÒ{¬ZĞ.hcDBc+å¨åXş$”jv¸Ûm@ĞŠ|š¨†hé¼S”§(˜ä”šVSû¾5ã‡/æM”PÆhêŸß†B]Á\FÙzßÁDr£ĞfHÏìMÆĞ¨™Ù”5{á+óƒ!uã[ YDòRPG€(¡¥ìçdWYîÿ“sN¹_GSİ"¿”\rt€Óot(H%µ‰wR–¼òXFaÛ|£‰°¢CFpeo»ZÉ¥ßaIß9ï÷,Æ²ûÉ9lõÃú±Ş'œZÅ=†²%Õ³Ô™–lbAôq4>ŒåéVÍÒÛ,©Eİôê·:JØ'npvt§O:ì³”?÷ÔAÇ~YEÏ¬šÔ1àÍ¶$È¶ˆŒâw>™î1%k²T-TíS*
eG‡:øğüÖÍ/E)–™´äAÇS ÿ'z×í8Í˜‘(8péc´9wggÖË6 ­G·[ö m®?éHGTp‹<÷0„AU¨%'ãNOèÚÙ·óËãM"÷ú/Cq†Şí\äxFE½ãl'Lø‘|g•·ëg]…ÖØ±¶~3Â÷Uå6³\Hâê„ó7´yµßcòî¦£IĞYPa^îqjhÛ† W]+¡ 0S9d¤:u%Ò¨ù4cïr°õTÅÚ¬8½…wH£cEÀ¡æBZ
ş«t7rs>g,’ûñš§ÇpŞåóFÈ•ˆäeœ^CBn£“5M…;èÌ(æ	K¯ş j¹h¼üDĞî§R€)ZrfPÛÅR>™¹Oõo”9H½Âc“]2ğ™&29šÁãz*—á²Œº	:;hc.ÎG5`*ñä%1Ì¯Ú	œ˜£ß™Œ r$¥’)°USeH¬Zé¡$$ùò¯‹pB Œ£!İŞ¯(#2YV-œ@w„ÖÖKzºCH$©CeÒÄTŒıÇşPÛu<$®û"šg-?#n…öSnxäTµÜYŸ‚ÒÚ¥¸LDò’»õy˜Æ-­OÂªJZrT*e~ÛeÉh›FW+k±váŠ.b&¢Hµhˆyå¼R|øG¼NişGÙãÚm1ÿ‚q|Wâäá!õÀñfovÓ«}/ ‹c²Ô™4ÕƒŸ­îöG]¶`;	ÁAø¿9Ô5çèêcÉ…£d9„SC´ÒcM²Ó,<Au•\¬NÑëW„Ö7ºG^n<"		vtÈ„£Èò|/‰§åoìíû'ú„œŠ~Ÿé5Qq)`X¬Š…£^Ürë¿˜MÀÃ…Ÿë<lÇ‡l
˜9OôZ´e‡ß•SMãËH$ïÈR ]Œª´ëõyÙ¥pS_D0&Åac~l,ÇÊĞ°¬wŞéÃ®E›Ãz»ïÂŠ’C™ ô ‹¸å‘,7bâDöO!T·}Û¶·Ş£ªØ´Í£ˆX8ÊfS£¹«şî	Ù>‹w8z@ıEK,`a0ƒôãÂÌ·³¾¢[~Ö_g8çW8ÖZŞ¨·MÛa®Ë,p¤FH_)7ºÈm<Z
#ÓÒGY{Ñ¯>^aßMBŞÍ¦v÷/ë…ÎMÄ·šCY}éÚ¸n—’‹ıŞ\iE¦aü<şÄ˜ˆ›²ğ–éE"¥‘¥ìrŞª	ñÿ9^¬{Râ®{Qş£¦©Î¼'£°ô~!´PFF„F7_Èƒ½$4ÄGßS+wb	›G{«pr€£FÔJ@—·ZÇ'sh’sŒ\ìŸò%p#»†´$È³Æ¨oÜTäJıíhMcUégæ5ù†Ô¤QŒÛGmïÉv»wj 3ëªÑú~"„è~àØ´u£ãXyé§tMºÒ¢öÖUÔĞî!”†8Ã/eíAøŸÎXòÎ>F]'Ú–ŞÖ|«¢‡’¼®£Èióú{¼%AÚbéÉi E1°/Ks(t¦i3„z™]ÒÑ­†½ç©¼	èÙ\Ô1H%p›…¤~vì›Ûª<‰¦İ¶®åà£oŒ…¢}V>âÓß?~iü5È„}Ò,µ ÊğNZÜÀ8E‹Â\¯Ñ€µmZË{^€l·V¬xÊ¿ÊYÀ}ØQØ0¹¯ó[TîÄ7Šó/w ¡Àaé˜BÅ±¨¨©EÀÉë:¬úÜ .Î¹_Z†Êk¬—~ö£åË YDKfVzéR<Kcx®M‚y+‰:Kš‰Ÿpíµõ»HcûJ¶¸µwZ„SAßÃ±¢9»«Ÿáäºîvbq·î÷Mp¡¯rĞ²œ†×1±šØXf–â/í”¾À°¾Ü—eJFrQ¶Z*²}…ÿ‚¦•ú“å
¦/‚k¡Ã6÷WO“²c5]ÉñÀÔ1¹]Äìòj21ğ‹—„Ğ–ê:‡ºbK-ù:ä›ôÎRYÏ8lüWûï–•sëŒXBÌ¼„Œ:Úèİ5FJØ‘Z¶^Äë“İy¬sÎ+œ÷Y¼ßìÑÿ!x¹x22_n@\‰?3¤„[¦1ä¼[/ói²oõ±c´İe-4nß´š%ğdsñU$?«ĞÁI¶¬-6‹B`[ûú]w„2zš€;-¡}!QI[pªb1_<r¾wñµ\¥çR
Gİs‡öxQ÷({…ŒÑd(³ã80¶‹´÷=¯«>“dâÀuxĞs·G¸W÷RgŸŞ&¼­×|c²ÔÆ´	©BOÚÎNC7ˆlÁ:·I¶Í]·è3A×4)%bP*x ‘‚¢íÒÀïrŸ„XÛ[‘u»şî¹%ºª×
E=®Qéºÿï »(fl¥ë;³°ÅğhPIÈ
*ÂoÆ.¾í6³¾ó²š‚WFe.”gy
‰õ¯ôÛ„wà$ÂÏÏŒ÷AÔĞ@ügI.Î5ô¿ºı' èÆ\_vüçÃˆŠCWÒ~8„Ç‘d7‹]
ã¼i­¬ÔüºqÌæ¶>X,¤ŒõÖºzıù€\©.³§xƒ§Şæ'ø ±ãbôN}Ù„ä ¬¥mÛ9ôÇÛXÖƒæâñú4:TŒHÿW\aú>F<É}¼?èAúapÈU¢¾GºÏ2ı„Kûƒ©_p!ÄKo.P¥±R¬$¾w’kÃuÀÓ8©‡51W`/E¾Uå<ÕÿxNyC5¢¢Ä„Ÿ#»%qÔúAÂp¥v‚t”i5>'„^fä|½´€4¡wE.@:ÃÜ¿œÖpĞw„dSñÓ\ŞS3Í»d	/®Šè	*Ö3®oI›˜à|Õm^66jvôÌ.¡,³äWË#ä48¹˜æ¼èÃ‡ê9^;2—g„æ !<æK @¨«DÌv²WNÇÁŸÂ7ˆ­k?äÀ¶ºÓªÍMpÁüå0î˜ú7Ãi/KA½Ş1æªÈ­Úrx–ÃÛWÃÉtYòkVyš=EuôñÔõvj~ÂÒ?`g¯bQ$käù „5Y7WïŠú9i<ñ‹d)?¢µ¹°£$ó®şœØ¼°×êæqÉ†`É+K§ÿĞŞÑİeTÚVÃï6’ÿßÃgù¦Øå•ãõ¾b­$·£ø4‘ÜRlJGæÒ`#’ÀıHƒßb5ÉL Ú¾P~°#(¡äôppÜ¢¤âØÚ=£Ş[2Nˆ$š-òjbíRÂ{‡À+Ù„mÔá„=JÕMÖ>c²!Â´]º¼Ï«Ö­„3Èãfhm~†c½’rÛõ9%kôLÙšØUó}ærO …§Mb…ıXÂ´¾Å £%R>¡mÀv¾všXä"¤	È'jĞWşu¼ÖD©Š¤­Âa¦
²¼qJz¦:3OKpÛï	3ÒSj—?nÜdÿË…h®âÌp vTV’[Ïª@ˆKØ¢µ~MUˆW«(‚AìÊéñ!²ëÆì±ÿämÿÀ®w¥c”1um“cÒ[’5=†ª5iU^jKÓmPlcØîo€ÎêW/šâvˆ>îT-È0V
ÓCÆ ÿúö`Ñ×åº‹dTô8(n25FÙvGVY+ _¦m£êy8Lœ%Úê‡|·|½ş8Ù Dç7œÉ¡q1D°Rw²GWS·Â_¿!¹Ö€]ÿhÓ{fjmèŞşÁšåÏÓõ)ÿü–#¼å8
qrò÷W[Æ€ãAÂ.<u…Õ„aôpÌj–êÒù‰ë¨—Q*oKMõ	ÕR‰8’:Hw	ErÈ|â=Ìz<w[ìçÿ™3¬¼õ·uîècwošwÙ½ª*xqÉ?(Œhøc
$\T®„¹Úİ÷c3pzu8&¾X{yVlš÷¼ŒÙ€„LEÄö'r0ŒÎ€–JÎ†œxØ‹Ø¹¶’F±mi Å¶÷’ AV—åúÊ{ïó^£¨ÃK+O8(D7Ö'd‹©ó¬¸êy@S¥Á&jê ğ(ÿK¡Mˆ˜)tÜš‘ÁC°&è™3Q¢¼mğcáKÌ§O{Ëk­ğ±ÜÑ{7üSXò8iÜõ>	©“f½?×Ù2eæ`8b¬/ÓI…´èü¤çõ0Òê„:€–SH÷:ã Ëã~o¨d8}šŸ»°pç,R—%‘°jn½6¬)B¾gˆCêaï¶Ìâ½y?ğV²÷@¢ç¥ Ï;[\P-Õ¤ŠÀÇJÅw$»ùâ¶ÎÏ¹½16Ù}0Fªb0bßíÿ¬¼~\2xx‰½8S“¶q½sÅ¹ú÷Œ!—…Ê]påò™¾Z~4«Gğ"”qkÜ¿^wá9#Ø
ŒĞÇ´´Å¬.æÊáô²¼˜Û¥)7†eì@	B½¾GÆŞóù`‹½“§‘ÒûlÇÜ™_Jdx) Èº›ğ
ÓiÅ:ìàS’Z$÷Igß‰‡µo+Œö´lmFoœ_X«Ü¾_¦×Üİ¬·¸Æ]x~Cl¨#%„Év•o ;(9(8bõ)zaHçá"f¦>Æÿ^uãßä¹½™î1Ù8ÀÕ('Ğ+ĞÊ+–¯F–B™§å£ œ…1‡’Œ21ÜÿJ@L±¦H¨V<ùWƒ|{†Şˆ˜£@’Häee!lé1E³s2@¯k¶çø!È6ÍwìğY:äTırÀZ~†q}ñ3ı“|"¾ıt¶Ÿ|KÅµ÷ôæú@+²²=/0Õœv]8æÖÒí~<ïË]Ô}¢Íú×ÎG®1>é€\–C©0ò÷ì`»P'ßÊ²¾™¸Y3GõĞ}Oò~ÓÂI{ã,\wxÀª6UÓp˜åpyáC­ÜXğ–OI"ÁekºÃ<)Å¹µé”R„+‹&-’xi”M6İA­g±°_]=!Şæ®.ĞY{ÈèÄÈ3û„Ù±È¹—}.Ø7óÿí¢ÔÒ¤Ûü¦÷Ÿó§/6>`‚[¸øL©[ZI¦ Íı.ØGÁÓÙ©ûœˆ¦NV‚ÆÒ/”9	òï‚§=¾ö:í]¬hj½AÀ˜\Â†%N—ì³ì5¹$~CÇ…El¨¦İz5¥Ú`©¸d5
¥FeçÜ½d½]şëãÁ5¾É:°q=Z•»Mmsï×¹Ù{	»óDùvH\ëwnƒ”ï§ˆŠä¬@ß­QÄâŞ&O]¬ûXz" |$î¤ÔN‹Lå‰iè *¶Ì)l=êÌ}±O9²
Azìm/@bëà<£³·ÇéQÜ‘a¹os’Ñ¬Ïî’±Şˆ˜RzüÔßâYBì‹æ é„Kğ„I©Ìy<ÄİoO²¤ùv²ÿ¨}\¶Jÿ;o×´ÿâºújó”Ğ‰%#ÚÁåb°Øî	"mj·â'xNëÈc¦• €¢J{Öù£G!Ò†ç÷š5ÙqeeEâj]Õğ";ÇÕµ°›ïƒŠ
Î¾Ç­©¤¬dÀn¤òå/p¨ÇA¾¡
…Ÿ„+1ébÙëW3ÊëåJ“|ˆFkq'Ã'²P®0çà°NJa¸R'İêô†ú²>!V9g¥N\j7j¢S+0>¦ÇbÆSdóLq=¨©¾g}­‘“oyËÜÎ½ğÚ…ho6k¬¤¤5‹	BÄ§S è¢t¹;„Íœ±ı#öç;18)™"¿VLÁ{“P5ô¿KG~	¦ÆÃ«İ#‘D&èK
Eå¦™¨OÅ„h$ÆG;½fFa/e'I¤«µ"¾›Ì½Só?VÅNy~Åæ,B¹Ü´î·Î™¿Õ€aÉÚªW2ÀyÛøp™wşD³kóuvîQŞ¯è¾=wŠç&Êh*¿“-^>`3Æ«e,CÅ¿¦r{ a­R$›fõ»*GñÉØi£7j|ŸhwÕh­QFÏÊ† ŞÈMíuPÏVZyq>Kí&ÃK´nİÖG-9W©5vÂ©MsŞK*QÈ5<<Ÿƒp.èfrk–ÁÂòw„¦oÄ>9¹½!AÙ®Õ9ÿÃ¸I¦šj‡‚«>PŞ]¥hÑÕ)ÀùúÉ—´ª¦Z
‰yİü›’ßı`×©ÏÔ=P
F¬&§:eN—œw‘ØÎÿ” ÙP3kéjâ ps&ã¸¶°a‡ÁQ£Ô{Í?Æ0ªRşüwæ%ÈÖh¬SƒÖ´16Á×Ãƒ]ŒS`$Ë¦¸çQ5^ã½¢Çí;ì“2VéD&àä££¼ óòì;™ !Úî‘ I}°e’dcMû¦›®ˆP¬3t.Z‰ÊÉØ^(˜BW9ÍÒ$WÂ
³T:à¿Kâ×èÈ K’ĞyœúWcÏ¾vµ³y8léª»b_€ ÿşwæI¤é4¾U¶­óàŸ¶Æ:ĞûóM]jÏÚg3p‰ÛéjH)îr¢2äëÂŠšşŞ–t­Á€êljv§ÓàƒTÏàÌ4HL2·$¯£Û&	3m±Ñÿ»ß²½Æ¿Ä\n9f½q˜±8®wç¤µÂa–ºfecÜ„W ‹·štMIÒ„è Ê÷Õ¦†MîÈp6\ÎõE_@Ãb—k¿V~?zÄÿ"]©M|Re	ƒÜn/ø¸ePì-à.è9æÏø&Ó[c$¥ ;‘a•¦m>Šòšr'‰"w¨ã)¡î¦K8^’‚0ˆ{jûğ`´GÉSé´ƒê;›Â4UH„%}â*IAU¨¹P•=x¬ıÔµ³M7(Iş¼ÜŠöãyu>ADÔZ ¢±f÷‘ÆÜ›H4O,µW-Šu†e«ñ3îr¡õõ“&ü¨µ@g¥ÁAKK?ÙO\€©>rJk•Â?2‹¢o¢<çğ9ªËíG$Äİi´‰˜yb\=(o¥Õó'úÄ—_£nX¤ˆ&ÌÁG IŠÖ`„Ü×ñgBr&¢3p­0›ê\³Æn“4KâÄÊt9hÿ„«-OìÑzc™`¸&hø9Î„÷Eéx…l	•¬	¯¥v–cv8œŞ™3Xœ,¯¶6
èaøF$‹Ù¬ ÊØÚ¶³F±O1ÿ³í*´® ÷¦t\_ÿ‘H2,g¯Qçe#‡‚	È=s×i8%2Ÿâp¡Ô9€DĞªUÜ
<DHf.&l]§SıšIÀ´zâ¿}Ü,<NDs zŠ£ø©©G9'¯†m‹{èÆJ‚½?8øº˜/ñbf°%n}äè]÷ãéƒ½J¬Pò4#¶_ttZÌMHŠ½±íÜ½=ù%TqèŞ€jœŞ5‹Êˆ{£"t1ËÆ$á/äi;TŠæü½Q!”•fñæ»¿í·bÖ
N*B"«æ`·ÍÓÔí+]¿ÍÂàrÒ:úÈ¢Ëw í)^‘MîPÃ"¯İÉWí3ÿ£ ÆÕt´ŠS^ÙèŸğªêïiÒèjƒhÚ¹AzÂ kdMÒ¥'Ê\-/ÆuSÂ™ön4úğ×²Ö1W0½®şÙ¹lHø¡~’ĞÕ²–ıSÓßG‡Ä±l .ÿúo½Srjp˜@×İ4/c¤IŠæ°Ù02“8XÆ_¼¹CRîÈß\ ^Çt¡6—ô£Dt Œ/"ºo+R††‡Ã•…B¹×Ù•Xuj¾†¤¨Çûõ˜
»äÇTÔ’™ ,Ñ)2gÎ Zµ¥pî:öİÉDOqí†‹SğÄVy»`)Uy\º]ÆU$›';ŒØû=G&óú¶~–$&òİY7=KÌÏ:¯Å¤sQäúØ™>%Ï·;o;b+fîZr1Gl%ˆÑ|ÿjKo©úÆ+³é¨‚qÍN&+÷JX§2Æ¡H'@@6”³<bxÒÓò <fãK¨/9®ö›.Ö¦EüEOÉ¸¿·àœ<V&Ç[,¤Úä§ƒ”ÔŠ	ÿ›xUÿÜ‘ÍüQª¶®‡ĞJ^œTa¯Ä>y•Äoğ7«åÒk®\“ÅQüĞª²¢3ÓÛ§3@3j{(R?1{£‰ã¥ãÿæqKßlíŠÓ‰b²::Â³ôï$Œ­q•88Ã:øf¯L¯EÄ8Ê:|½“¦]{Ë¿(Ê*Ğ­Àû/ÇgúíHOekxÑşµ" ŒFú=oÂvÎBÿ­jQj@^ë¦Üê›ù@…!d²_È}uuiËŠw‹+¹™¿ªä<ÔS[¡Ì…ğœáAS ¸ÃÈÍŸ«âÙùçXûîÆc`¿Ø­z¹Q¡KØã•ãYÛ:¾ì;ŸK¨Ãt£î8ÂQFíìˆ½ÑåfÔêùb
óİ‡Ú§F²½ª}ñˆè=š{ã¤a«Ê‘8A´*Î›y›´±_ø6(¡[h¸w_K•Ğ~ íé¡ãÓ’Àâ[æ´(}’×pY@ºX™İ#v”s/7Ó™êÁ{Wû*á—eë´íêı¦z{2¯µ·"ø­PùD×Iö_œ.›c% îŸíjºÁ(Ğn¯uÄYg¯':+%†`ïlÚOß¡«Oî ää^ßœÅVMÖy9Dmwş×›g/´_©ÑúßNÓï`ÕCÓêy§TŸŒ›y—ÿíjº¯C¨UÁ\–hç-©¼Á¸_ÒS×üx‡A	Q×W4Ôn®Ù×äã F=¾ÌÊ¨¸¸Ö¯1$,ËÿCïåº$éM›‡=p•¬Ò~A¬f2¢@5¾NÚ=/EáRº‚ŠºÆD`^1%RÒ2wòvô_ñ¹#
Ç„ÏA}øÆÌ›`¦9×ÉêG˜ô´»ñ’§Â;8 µã,ÃŠH6§ ÍJEqéû #O%î¹ôwHEuv}Ä¹p"·çwJ°ÿ"ü_ –¹ŒÎeaXàÔVö~­1?Å÷X‰×4Ü ¤ç¾T‡â~96±Ò‹ÇVpfteá 2L½³£„II?¬Å´âaeOÈ z/v…Epp®ÇÚÙ .šó)æšò¯äLŸéœÅt ø	¿ËŠ\‚€°ãÀÿŞy0åé&–³Ñˆw¡ıÙìïõfà!DoÎ¶Ù´îÊÚÃ¬Yµïé':ZiC£¡œD½µPndÖÙäK’iÔ,Ä± UPQŸBŠGMğè|ƒ—wQêù«ÚÌÎšPÖBb°ÉŒÓÂ¨lñØ‘”—÷Ôvõ¼¸š˜e2Í–àÀü¤Ph†h‚ ñ\Lz‹B€ª!–jâè”ºâM“µÎ¥)½`óµ©BÜ~®¶T‡¢ ¹|NÊÒ9ÑÌ&T
ÂôMÜ)OØzÅJ(|OrÊÎíà¿ØK†p?–›AçrˆÎ*Í­›ÔìFÁÑ÷¶Æ¾KÈ`4îG´¤D~²ÑŸ“¦ÉŠİ$øÛ@ZÅ"5+y1?s6×pE‰Ù×‚'ãÜ¬hkö~e ûAqCY ı¼¼ôp—øİÛa&O´F¸õí÷ì0•E5§f!’ôŠ7Æmë¾¡èV¸r¦E9š»ÄçtÀÖ´­))9$Xm´7tg7¾ŠßiRßÃÇùz§Ä—”®òßJ•îÕ"Ğİ2™šÄ!Úií°Œ÷ÑÑ)öd”Pù€(E0	 JÍç€¯etáŒzı‘hw¤Óº™Ğ3zuÏçµ_ºw)PÓïèÈGÜµas8†]R¸ä”rĞ§†/(]9ª^‰î6Şäî¶İÅĞô×
)Ú‰¦Š*Aë!eFåu]¹)–÷ëOpóÑàUämË¨šqòÿiO”¡«äIšR©!§t|uÆ(§¸äNş÷MÑ{T´›eO=Ûî“bÃ0Í[À—ÄPõ­b¾8(3Íæ@4ˆ-TÃrøl­¢ÌÿWnDı¥Kiî)¶‚—”%õ­#ZHùlÂ:?&š;÷6¥?Yw³âm¹Üî³vJ­VG°Š8ïBê.i¬a·‹î£h¦ˆ6«°udìg@-ÖìùÈ«>Cç§GGéŸX.KßwkÓğÉ	c‘Õ$1õ»ÌÍ÷¶`Cy¶Æ3R×´˜GX#	×¯Ö_˜´%Ã4€ Ô›[ÕàìeŸ%Áéj}§Ú]ó´¦*†‘M³Z3ÆL.?§Q¹„h¯ÈÇIgğS`*ò÷YŒi?ù4ášĞ%Øu½…F+<Šˆw^Ô& ÒÈi
ÿ¤ÕÔ{ƒ.³æË¾ŸËŠ•³åÿHqü,ogjLi¿,”#Íãõ8Ê¦áe¯¤xü¶ñ?¬\l T0BÚh]yÁ(©6øL	yƒ“sÕk uğœÂh!£R•ç 0]`ã3HÌUªq…q—´ Ğ‡°Lˆo%,ı]A]¡À/p(Úª¡8Bl¨ğ°f]l(“À¹ár¸ûÕÔiMJù•U¨[Ê€Ò<kÇİ^øAĞTj¸¦Ayqb;‰›¢~‰{Æ¤Ÿ0ö`ØPÌf¶–XÍG‰–İ*dê«
’ÖMy™"ÄıfÓ¶Ø(¯±+ !¦u\Ô{ñfOˆ]”¶+zşÆ®Hi«Yõ’D¸i5gDÔÓ­C0çŠÚ&kB"T5ÉôdIèƒdb
ƒTôViZN’˜ç(iÒ~üÆYm†Ír4ÆBÔ(($/äás^OOlÕ—L­ÛNìsŸ“z`¶¯¸š“[ıöGqFILêÑJÒ®³åJ&hÅD'¶ì¬ë/~pWÅIˆVSîNàX¼Ğ(Š3·ìæSW, û#ë‘¬âeZqMf(Í›&tÁ­*6ßV!?ÓœKÏ'û¯ã¬1|UĞ|_ÕÆÜ-lºNaÏŞrs†NÈ€ä7_[[)PÕÛÑlÏr#?Ÿa¬³±±ñ_†–ZÑqN)pÀ¥ş¼²ÄP¨mò¿eÙ|²¡ÛVÑ4b¬eW²F	ğ/‘/ÊjñxÂËe–4°4¤J‰Ib~öL«(/Òòišà¾†³7@¬{b /hİ”†S ©ùÚ~Ü44ò\–ã&yŞ§İ<D÷2%õhùÌüní¿Aç6Õ~âGV«+&Ş³áÖ8÷¤¿/Ãöp*3e:æÔKƒ²í‡‚3ÿ§K¸z'3©Ÿ^ƒ7´y<;ÊWDx¨ú³-D§Œ€gÇÎzp]TŞ·×Ö€‹İ²ş˜TI6è	Kª1¨€şk|àÕàWc-Zšáºìb˜ƒ_u7·ÁöWwN»†œh^ª%Œ†NÄaaHâUşïøPzS¤Cäõ3¨ …1ÉlÊÍ½”ØÈ0G®?Ö©/¢áVºÉ<~2‘ÔRT*u×E^!¸t©æ‘D]ZÈâŠŒ£8½5#DÌ)gÁùq½ñ…²w2~¤Â<ˆmõl4-š7IoQ(ªI:1-H#SP°k<æèÌHê9–&Ö„¢Ş¬-ñçıÙ¸LÒ ±1Ï[°¢gM?õªE}uzÂà(fnúÿº~,l(_Ùd]R©)ß¶1…|Ó+Šc½Î^2|i¬;Üm8@	#Œõ²¿œêü‹ÇnrÛ¾\Yhœ»—3†Ã8÷÷Ûü–ájrmp‹Ñ¿ÂáQ¸çxE&,Ùj×„à ÕÍ°[B­†ÍëXpÛú¼çiÙûW-ë!ñ3§7-b{¨L$C¿¯}ıœáŒåZ¢aŸÜ]Î}™ª?¥yXY	XnÓ¹j8”¹-¢Ë¶±Rû€2Ÿ‚us@kTÊQ@¬Vè%u§f0{I,ı)@ÔNi×qûŸ°ĞÜ¸¦ Eu‘³š‰)‘¶ìã"Oì«ñ`ª ğÂì5³Ø©R½îG#66éMâ…74?BÊƒAíb.ã~C¬_lİ"¡M <Çà[·3¶šøxPö1g¯’ »Ñüõ…Ì<«éªif©³ü±*)fÏÊ.—¨?&" ÷××/¸x}R<­$>ûRøÓ&Ö&.|mÂ…£÷ŠÈTß5Ä¢ç¤„ ?.¿ªsHùË·Ûÿ"ájºiiQşÇóÃJ¢“Ãóp&šîH”ù;h®NÆtÿí\ê™ª½—[%#],SÛ2Ob%Ğş×"6'ºAF½¥| fšøIIPÂ»Äñ–ÙãÕÏ3BÜ«aù-ÒAĞS1üÚ&@ßÙJW›£IİB{§á%zÛ?šÁs‘+ù+@ì1-#0*9}gœKˆI$¡ZéğL¸‰W‡ı´FC€¥òYœœJeêÏb½p{œ½ÃE“1„IĞ5æçqT|x›õÏDîÏi:™Ä¡
{ŸúÑÅ¦0PI]ÕŸµY¤. ÃšŒõu/£û2FDIà÷I¤1*‰’¦–_å°s)œé›	ÌiM†Ç¹Tª¾x¼ƒŸeôœgNrêŞ
Â2`¨¶I'ì_±ç¨-J²ó—÷ø—ş×<D–³–>¯$`Ûs`P…|_+xÓüÀÙzW×tËaºü&ùµ•ö¹Ùi[?¸¨úh¹Uiëµ¬å„ÇÛ'ü…Fb–©Kê„/»¿Bmƒ'Lã¾ìÊÀ)W’›,k¤lámJ=p¶§Ã??·Û)^Ú½(İM1E‹j»{ÎH„ï®øè©<İ¬N%Ú¼j­YÔYÏ*×ø.$8¤Uh.ÆîŸ™”Sş›8èN\‰Ë×-¹^2tè…è*ií¹Ì…òeoóÆ›â¨IQ¤ò\¶Á¢Œ\t¼4›…*Ôe/'~W1s•33Du0´z­ÈÀ²pªûûİ;®×ÆÓ—şw.è®myÇ=”äoTÊV‰/tm÷zÆâºtçµwàbéY[<ï¦Â˜¶O	ôÈ£œYçGU¯Æc¯]ôuÀÂ«÷Ş7?íUíw€zkM$Jxa`¢D.êşÛ&å$ÎlË:Ò‰Í³J’ıŸaK¯
Í‚çĞ˜\\êa–f}8o´ÓøqƒÄ–ÿ@L0nG×v,ıä4ÌŞ~¨/õ¾BÆdÈ•snªãëqĞ/=9ê¢$
»nL"øÃ,^=÷åQSEt}Óµky×¾³6 vãõ­ş¡)3&9©7Øw<§ml®)âGÉT`u!EÄ>Ü‹Tû) ]Y¦ß7÷µT¢sóxÿÇ)ZSïå³S	B8ıÃŒdû˜PH°¡u8Ääí——tÉ¢©#&%ˆß•C—w“¥FŞÖºaîN	Ü·œÚğÄ¯x½Í”-ƒ~gÅk»è‚1Ôe€T—Æ?CØ®ù¯¾Ùƒ/ôOãgìZ$÷£¼%†#g·üx„ªXM%˜ñ¬€7‚tÕ€-f@x£k•IU!,§-¾ú£Dp
.Å#9+™¹Î®ñ½mÆü°Nàüp9X=·j›®¨ÄóŠ8+Gê\qĞéNöKOšÙ’)‘Nº×]oW§k	_ é\ø?Kq«Æp_Œ²Èbª’õÁFÿÉ@GÃf†¤>•«z„&O†ÿ‹¨¶°jÖ6çíÄÖÀ†¨¹×fº\Ñi°vË…n0¡P­¥A¡‡u¢Ho£QGZ½~0àe‰ëM°4Ã^„hP$:·Í§=İfª»ñ‘¿®£İ²$Ù½”G_Á»ÈÜ, ùòrä?õ×ß$1ÚººW°æhÀÛÁ#{µ·ü&]3˜_ Ğ!¿jsÏè„hØú8Îò§2¾Âag5(IôzôÆŒiÑ…zG%±ÛñÃ&×68EŠÍxÆXªWû<!p»’ÕD¥Š^´knŒ2±EY ÅS®Ug!÷<í¯#!Ş4h73úşWĞÙŸ…¿«{xC<&¯¸—ÈÑ.u4ş®BŠg¶¨:ƒÇ!¢¬®3L·‘('=Š`Œ‹»È;!O °	j:zõº(0¾*¾¼Â)fÒ²úàp7Ïˆ±¾±®VEs»Ö×Õ¤‘>ÔÁ×“(esô¶Ëğn=ü@îx¹†1×®˜Qs@ïÚMß\,1£°ên¸“à£ºmÄ>ğ‰ù~X8%k&¡ô²Ë8á³œbk)Ö‹]èO§[:²åzåU†QZ8ßË×Q5iUvBsà@Ly¢}Tu¡y“ß’éãÿÕ‚\0ëù‹”w<F5PÌ«½MzD?ø°ß6‡K@#£gå“æ¤z…×õ™ì||ÖÍåÓ@-š¤™t<¡Á¹VIâÀpİÈ¸±ÏÖ³>.ñ—a¿RcbœÃñà?ŒÆÇ·ÇêR#65>$İnŞ¾H?rKıjOQ:ÛÖ{K•”NÃ¬è-i¤h0b|s52ŒÎ·Šüh…Â/¤d<Q‰=H9şDÂ7Ó¤$ï6ã|ñ4ÃıG÷ú3b"¢qªM9dåLƒ‘vÍnÿ|êˆÙíq2^˜Uıó|¨Ÿ¾œÜtmüÕÓô*“ î´T‰KH^‚%Æ®^<y4Å‰áC9}XNjÉ?¾,Be¸¯çÓˆ¯5)Íí?âõzBş{ÙÕîâ3ôÚJŠ…“¬ €cÙŒ^KÇÙ]"CóÉ’V”Ìè¾K
à™”ÎQ­ÑŒ‹kKx»†Wƒl^n1QûM‹¼Å{´Šã,	ÿ/ó¾7Ú¼A©7ğş5¥líN"i0n2xk*3ğîaîŒ¶Ã1îÜÅü é(25;•sÌ¶›‡&æbÌC`™üÂ´6îÙz÷kÏì±ñ¸`_s·%[y2P3Ú4.Åm¢ôlªOnŠæ£÷±>RN]®Ùæ'Ñ­iÒ€Í¶#UXó7c6ÔÍ<;òc8\ÅÑ}ıx“çß'•îœ­"Ÿ‚!éêdú†@úeDÖ¾Êqõ ‹\ò”Õ}8f _ÛM¥èÀ‡û˜q›ó‹[ÒNœ3V8p«´g6Ì·?îªù^Ç•‘``ª\[YƒŠpßDÑ%Êµ4oùb{;U§+æTJa2&æE‹‡M3øÊlåa,¦İO9Öûh=râw§‡ÿ¾’
;oÌ®îÿKA%o¤ğ¡L7åô_M³K\ïÁ85¤b«€äusÕ`õxC8ï6ñÆ7¬€ì4©€v:ZòNXAŞB¨ÒöLlßjÖï;bëcneÃ (°½!Ñä@Ïªœxe¶]_”r®Cï¢‹å¿æIŠNâ#Â‚¼}l*åÈPÄ­x½3ZB)ïÏÉ*b“Qä…è˜şÎhf¾ãóF—Ùª«ïòÒk‚‰UÀïX3åÒÀ+^l=Âˆ&”ëkÕÜ6`IØíR­vZäÃ·Of¢eYŞ±Y’¦­„é¹HÚæŸÆ.÷T8ı!	HŠ æzŞWŞ„‚H qBu³köğZ8 ´K\‚±o‘²Ë”)nFÚÓ\Ôí[u	ÃrÔâĞ#2‡´7ÁŞDôëñ\º¬ç°«Ü¶@wîŒF/{R‘Ğâ”†ı4Ê‚DÎsªœdæ¯Ş˜[Ù …ŒC2ÿÔí»røvO•‹7Ã(§5MŸ•Õ5#JUK±H'DU¢¿æ|aÑÔH!ŞÁŸgÈ	NP	T²K,êÑ|Óû%Ëš[ìâ¤J%…D×åùÆÌ‘²ª¡&µ;Iğ
Wö1š”T]ÜC¸¯œu¡ÎÖ°8Ú¯sR7Wï4×¬‰!…rïJùğSA#?If€ˆ£‹¯%o"«S ÿYB·‹™™±ëBrø¯jŠïªÖ°IH+Ò¼§´Iëà…h6›ãÜ¶_Æc‚zXr£Òb‹hå%G?~çó!èó‹íÇy';m~<A
Ëïû¦Ia&¡u	TœHXÎfx@7ËÕª `%úÑÊs§óîL³–PëÔäªÜÌîëáv3¯ìÃ-ò‘Õ°²U1÷˜=$ÉÃœ¸Ş,L$,‹,?¥àXÈS©C¬PMïÉÁoÁˆkù>ùÒ{a#gZB9ÅÉ˜¢·ö6öÎ×°FTgB§‚•íe4ÿDF6jül§¿5šŞ­?Sg5—«iÓIRšå©ÎæÜ¶ ºÓßD[óÇn ×ÆÇfüSS°–Æüİ×
¬%ó—üÏä¾ÕªÕhë"ŞÆæmÊÆJ;òí¼Ù|èÖÄ¬ER‚a×û1+Î"G]ëqaêşÉ¾£ëdÓ¹Ø%O¤¿`Ÿƒùj6(–ã0ÂŠúı±éÅã*ã-±ƒÔú¸°2àfæá+©è[%İ|+Û:MNïçŞæ :¨4›³s÷1Ò½x^‰CBLÈ¤–ÿ :²e#ÅOxÑû"ãÚìH…¸1‹k=è ³À­GÆÇ2ÿé%r{BQAìC­uåj©ßíåk¾§Şhp‰g×#ÀÑY³Ÿò€Ü|8ô<!6Øu°Œì¼Óq5%à ‡\¯©úa­hÉ_ç§3gEzúÕÂ„#h‘ôÆ¸ÛÁ@”Ù4å±ƒé¦yˆ‰“²#j«¶ËmÆìİûpuT0PÀÓ­fçÔ…sóŞüHÏ)ô10J#Ÿş9€-ôIdëGEÖ£9Ş¯Æög­W3éèï›¬â€Ï‚JŒ{!8ÑŸ¼S­Õü+	Í½U‰=uØ‘î”²>Y¯ù]*VåFÇgFîa[JÉºÂš‡ÖÈ–ÈĞé\}#ğÂ«Ğ&|óşª’‡Êƒd1Ë³¢bhìö9şO„ÕÊ%®ÿ,ÕAë`Y" ­Z›È¨’éOúQqC=›J?ŸYÓWÑ]d®ÓŒîï^HV%—íMQo^zd‹/©!–p{oŞ·¤ƒñšñ.ªœûï03{D>âdèaGİıo¢ZZM3_7°,U·ìÜnÎÕ‡EÛ¡›Î:œèKKš˜?Â„ÑÅÆ,Ø@Ã~N_¾œ=HË+yç§ü›ÍAÛ•\°£u°D—Udözqo¾Ú€2ü¼R 05¨»Õ-PèºÌÃG¡x"ªãÿSwòqjp;j3Gí‚ğ’¹=võUª¤ŒBQÄ*/Bƒ\º±<ÂÂÍ~ú¯:y«aú‚¾#RWÖ`«ºñî1k«Í@gZ¹İäÀj°†XØ”-ìÂm|üû.æ´òµÀÓÊÉ×ÁÍWzËèôª6³è¤vî‹|=¿æ(,¹œÑR6´t€5PÔD|m0ë1H¬•m›ø¢Ó(şJì$²bß¸73ÆÀ´Ü8ªÙğr€d-QÏùúa¿$NĞ?ÂäÔ¼Á{ü/a>Ó’¢Gz™bªíâ>+‹½ÑVcóü[Z;áÂ5úyQÆTÍ$oOôoŸNq¯ëĞšäœğM“>ùäÍN] ¿‘]ç#ûzìÚ‚jéâ¤
%!/Æ»İ'2!¡¼Ü•Ø"¦çfµÑ3Õ±çÕÇ/üÈ†»õÀE.t\2]dÇuú×Ó<¶”Ÿ€ŸÌüìå€ ÌMIe7¹µ¡„w$¹·OfëD|ëIsÉşkÕàÄZlÔ,˜M#‡;Wz	šÁQF½;8ŒáG–”àMÉ›Ó2õı æÕı»P¾ÿÁBôÂ‰òí¢ø86?§Õ„Ûz'¶jà¼<ÎaãÈlmœÊpP1¤r÷0Pàÿıi,ÒKˆ3/ÎÓê³ç6OĞ©{“äÏ	Ñ…	ÏÇv£åµgŸà¶Ô÷	øÅ‘iÕu_cº6ÿ½7%ĞòdEgô$÷-y é€¢R$k¶Ìƒÿœ>¤FŠ:‰©>µîMúôø(y¾£ô’¦Ys™S„%Âw\ßß±¶“–ÚÒÌÓân]ß63½ü‹ºôÒgŞâãñÏ"¬¢¡Kï=yy¹&²³<Œ!ÉL«sØdèZÕéÁñ=¥9³ky×Qİ;ì¬<æùz[ò‚xeœK±ÚVø3Á‚ôâüE­¶__ã<´ÈU(½Œ*6¸¯CI9»ÙÂ¾@“4yEhâ"Ïâ|L¸u—Åì%?ìå°ŞBxÙÊP‰œúâ=}-)Ê‹™µ’ŞÏÅrègrWZ§‡œRÛàZåõ8|õféIa2EîT¾ÆÈ÷ò‚ñC2ëkí–°J
Œ ˜–$İFÊ¬;B.ôlÈ¥4YŒG…ó¬äÚAbÙp ?Y<¿v†ñêŸUWV¼‚ÚÇºÂıÉŸ~ÅVû›ÃĞ#âËİœ›¶¬~h@T8áN[‡ûëÜ6Xq„éÏİ¯8(%ÿZÛµİ”XssXù¥œ÷2q3ğ©ÛµŠ$Zf±üóNuŠ»$ëğ­¥·&·Íşn¹„%doP›§Çí„‡¦7²,.,Â-»æ‰EâçÒ·îÄhÍ)¾E°\¼Ìh“bÿÉÙ–)åB-h”Wú4’€òğ4
Utî	€(/™Xà÷J‹Âjôàóıµ†b¯¬Öq@¬GMnb>ùuíÒ´'`­¯
Ùaº1µ°Sr9oy²ƒÎY Ş—0W{İá·ï‘­dQM&‚ôpğnş?cÿ5âR”]5¥[a¢µ|”oVFBP„ÖĞ7D7¬OÌ5ûöqîÿÅ€åV>Ò½TJÓéËÆº6Õç„¶7×às«9HÉËó;òU¶ü[€ö)"uÚcR 
†R>ø1€– €˜Àò€•p|†TÀ=Œ¥ƒ‡Iˆq'ˆ0„	Vğæ3æ §¢±çê¤©t“™Ã£¯Ãà_¸Şçÿ(ë©gU¦<N
¡}¢’ë{AÜò-y?Pù©*òiğQ÷%ÕÇuYhõ û;®İ÷×·Äµ…Şˆİ\1X•-¨±~@/…hõn3—ƒo÷ÄzGÑ°_nåÀyà€†yÎÍúbm1ÜüºˆîH®WXP²<WèòóÅÆ%ß4•PX[Á@É2MQ°NH^ÎŸä¯‹Y”ş‰ã×in^Ëû6ùğİµŞéà[‡¼“¥¢¹¶»Š“¹Tû7ØõëPÑ7AF¢Åù…sÕºŒà™’z…ê±GOœX®ÁÇE-fÑùC& ^Ik¿çá9Xß -ÿ|nÎ‰³?>),êš£œqç½=Ï,.ÍmíHº0à>XOró¾™à‹v€›Éè—w Ì;d@oX2KŸw.ËIpáâKXm¤·ä¥šãd¯Ññ7‡Ø¸ò%ş*¹¼=!éø FšÁ‘ÀÍ    ßœp;­ÁQ* ©°€ğ‚¤×I±Ägû    YZ