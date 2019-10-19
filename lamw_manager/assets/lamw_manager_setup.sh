#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="499566867"
MD5="2100807a37d41d918e1bc84fb8a4e290"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19058"
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
	echo Date of packaging: Sat Oct 19 18:47:17 -03 2019
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
‹ e„«]ì<Ùr9’~%¿"»È	Yî.–hî–†=KK”¬±$rIÊíËÁ(²@ªZÅ*N:ìÑşËÆ>Lìó¼í«l3:PÉÇÄÄ´lH$€¼3°¦=ùêø÷âÅ6ı_±½!ÿı=©ono?±ñ¼¾…põçÏ·ŸÀö“oğx¾î<1tÛ¾[ ·¬ÿ_ô¯¦—i_ŸÿÛá½¾½ù;ÿ¿!ÿG®ãyê00-ƒ¹5ïò‹ógkkÿëØWÏğëùÎÎØøÿ_ı¯ò64mm¨{—åŠúµÿ*åÊ¹m^3×3İ`0f(nºøñT÷8"1tàiÓšêÔÂÜõreß	\íBod2{Ä`ß™Îì*WŞ"ÇŞ…Úfm³\9À»PßĞêuíùFı'laŞÈ5g>Aõ/(YAWÀô`¦»>8cğ‚Ô>Ÿ4OÁ%Øúá ú—'p!ˆíë¦íG6Âå˜äÿ»0a6nŠ¦×	|ÓfŒšİÓë A³Ùİµ³¥BÓ6\Ç4¾	İñ¯b0Ÿ|t |úÆ³à^|İÒl:û #0®?ı·kê×&î Y¤O‡ÈŸ•‘^;ìì?]ÿ¥rÉ0=0Æ½7ªOGºóGšéy«ÙÌ_/—Fº‡¤¯ÆpHtÊ¥Ò3å|Ø~ õkÊ3,•ØíÌAfŒ-}2°ÙÍ à Ë÷uìßÛãÃNL;¸…SÓö¡şÓê#™§ÊñrêÉ26kµ4óîÉ ·ØP.}æíjšwm×Æ.c3İéVÍq'Ô¤!ı4_ŸxšË,†ˆ›ƒÁ†"aB,ƒ“ã—ƒN³ÿª¡hçj–9¤ª"íE`DCQùÒj£ñ$‹²Û:i5{­†²pâ7­nï¸}Ö·¸Ò²´ª4RI¨N(¶¾ •¶VÚÒÖÂ-a/u›cx*ƒx·?îPÇ,ub¹}Áû=Òw*\PbÀrFBmI'ÓEeqÜ;’pHMAP	Ô	w&iíúœ¡kNtÿÓ?P—¦¤@iÃ¨r.SÀ_gN‡Ÿşa™#‡Ï]p§ º©a¼glòÿÀ²Aõo>?øárPb–ÇrdˆQH^±GLîÿ+é®„éô5©KëmÍÎÍ¥9º$jO¯PUTŠ+_­RMR Š"-s!æ,EÕySázïÉÖúä/Æ=âÅı«©c°øn`_•óphwÙ×€®Ğö»çg¯!6·}…67M$+ÅóÚ†:D®Ä`ƒ<\õc®íê³ûêã³^¿yr‚ıå¸ÓPªä·NÏÎß^µO[œ‰Ş¥1$nÏs‘“æŞ›³~óè²‚ïk2]k¨;µÉ¥`w±ĞNËĞÇüFï°!c÷C,Ä‡.¢ÂF—(¤Ë5¥—œñj~´ĞĞš‡C:4¤}vx¼`Bs±ByqBaB T”_RÓ>E#MwJR]êö„ÄF,·QÁ-(€”,q¹4Õ¯0´AkLR|¡itËDè`ìwÎıf÷¨Õoèh­Ú~CQÂ…Kl(ĞîÅı"îın»×€û3„zó¢	êşøÍaçÍ¦‘ğuº­Ãã·âLIP¡Â·€+Ey¶Ä*[(™œ½öyw¿%(*i~–s†hÕ¬`“¡’Dtø`Î"’(•˜÷³Ùèv‡û3¾ºêŸà»lÈ¦RÈ\õ#
íUûşPG\Ğr]Çİ…CDëIüWeõ©~<kwO›'÷
‡ibpT-h~‹‚OP¨ı
…äàÔ·×ã¹P¥È
V#»K­ˆQ ¢(Xİ¦;ºÜÙ*ßUìNw$æ¬ ¶:Ÿ¿@PÓÂüê0'œE«[Äÿ"öCy5ög-@”Fh!E9('R@B°”_[…J¥ÊÃØGK^Â:ÚDjÉÏÅš¯·VZóËtã2‘Ûñˆ‰¤ sY¸3ûq(ğÒqüïê3®l7øa†A$"ÃulN— Ëaû¾Ô–ÈêáIóhpØ&×<;è¶¡a|T—¤4^ØÜ(LÍ©¾´ÒğÈ7E«‰,8oÌrR¿çÌÄëK9GWXK¶)Z¬D®N’â–K=FbÒÑGWú„ŸMÛ`·êŸÊ¥(:ƒêÇBxïª¼ïııƒ÷”Šó"J~›úŸ¥OoTŒ>}Óx*3L´º_¬¸¸ş·µ³³¹™©ÿmïllÿ^ÿû÷­ÿM©ô§êÖTÿ‚õ?à@.éSQ×+øë]æÍÛ3‡ãµ=1¥À@_#L‹yµÚ·©ú1[Ç%6^úÎ¹Á®¹5˜¹¦ía­wş²÷k¯ß:m4”À*?@³ßï~47Ì6÷›ÿø¦uvĞîşŒ}§íƒVCÙØÙÙÁ/Gİö9¦ƒ3+˜ ^åÂ^øz2ÆDù/ÀVÍh«†¶]WC\ãM´¹×&r“ Áå…íİ(ë¦*œŒŠ)ºû×À¼vHZb’~ú»\i)4Õ’­^d¬+Â\GICUÎãäø<]C Õ Ô6ÓıËÆüRˆê¤"¢
wú§ÿb3 xÅı·\W6E=Š"ùÙh€©ãÀóİÆSZR9><hBèV¹##Œ%DS›E_Ã M|{kDĞéMÃGÈ/¦M5ì>´ªİv»? ™ÖlãJ›YºÂ?õ´Z­öâ¤X#F¨ˆ1"L„æ?VÍsxCØxÁí;…I zZñ¢¶j?i3—Qàk¢[dCaú^*­©‡Aš)øÏµ0Z`›¾Ç[Pğ&Ì_{ğíÙ#Æ¸¾µ&¸„ju|¨d>¯—ËIm-#„F˜PAİŒ
M¢*1U•Ç¥ÿÄ´™i’ğ¤qPT*	Ñ»÷<Â,ñšyØAzWT«rºõ¤à	#MµĞJTJd6¢2³ßôDGQÆlb\e´,Ë“Çhe
(Òº€¸ôÖÓš†¢ÕA=ó|§ã:dD¹y˜‰Ïáñ‰Ïà¼×êŠX½FnÍEÀ·’¶zd,Jhm¬E5^k¢w«GİæÁIK DÑZCêÛh½|ôdØKK·¯ˆâa*ON ¬>B,ğ¬‡Ğ+ç¹ªTåm+Ò÷x+Já¦9o%Î¦zç1MdB’D¡+­³Q•¿)ğóÏ siŸF#Q³!“–#Y‚£ˆ;òBÈp¨±áX{$Æ,¿¢áf¼ IÊ˜%k*„ÍLÈÓ§úC^ÖQ³,vtô†ãù:›»@ñ=ô‰0të:ò¸§OêDüÀ.¦ŠÀ(œìfÊ•v€6ì¼@wMPTÑù\;#'ÀVŠ›aÜO‡ˆÏ£Ôs½,J5í›¹MË"ÜÂoócÇ¶î ˜˜©„!’¾J&õ2‚QFaFE§/tòX«ÕÈJU<‹±<—-$OÎ";'b’A‘İ5b½±¥ï&AíFG%a¦¥}ĞÔ10’¹1?è®!'ÿK§\†,ªØ¥ö88>‚S=hoRáşÒì÷½~óåI‹Ï“$É+0 O<©ã™sK’FI[,ôt+R3S-o‹W$à¼áK§†aUœoÏU·Vœ&Í•4%s=T›äè<ÕEÚÂY¾æÎ'Ûf«OQ4<œATn\-¬åL¸m„¨&Yæí4öÄ™‹Fn)Â	Ã†œ<¸N”C”:Œ*‡^‰l\]œ.(GâbŠğ
qá>>Ö*jåg	Ê±=vvÉ(Â¨P´½›50q?Ü8î•‡é)úK»ûº×iî·¸°Ü	ÔÉÎÒ3®ÄŒQÿYºé…}„¥ÅR~“ãlŸÄ„C¼j¦AL|ÖOv,}á!Æ¸?ıƒP‚Óo·Oz	T®‰H'†ÒŞ)_c¨Jìi(ì´ÄÙp§…2èw:ín¿±@ˆÁI.*9äİêSúo=J<ÎÚıãÃ_=ÌFRgß¶ã›ã;ÕÃà}½\ú…¤Û£ø¬—áå•PĞ LQq‰Q‰ã3³)”]¤Îã³˜½p9¼°¡èL$v¡H/ìù˜ô­(|8gûhw9%b_–_>g;)«Ä§Ä@ÿ¤ÍMLæyğŠÉ$›¢‚Æ”ÙPGÍ¾Ó£bÏ)¶%•ÿï
ıœäA4}6³LqAÇKÒ”Êˆ‰€.]ØqÆü*8ÄCãŒaô%s œe™RgÏ÷ÈÌL¯p¨³Õ'Ç0+®xjN™6¥(O’ìÕ¦Mó†Fİ`Ş•ïÌxò—X÷w¢Z¶ïŞ½I´r¦OY#a¶Rs¥uËF©³-T0}©*ŠçTwïT‘¿«<1.ô·ÂT'¨â(UãÕ<Zë¯ÌÓ3"w•†Ã‰psš‰]‡İÀ8.%5läãúÌš¶n5Æ:ªhº›±F3aK¸×}„	Y¨ÌrftÛjgÛËCHÃ9„<â¨ÿzïèü	jNĞeî	ËO{
f¿œî[ºçÉ4¥ŞSä_–Ïn}íV÷ßöø·pcHXç7QÕswÄŠûL›*jbY) jN·¸¬‘˜ÂF*£]¥{FÁpRK¿»|ÍîĞ^CTÄ÷:bD¡C—±ğ+º¬=A½4‘Şu\gÆ\ÿnw÷­úú ¥áV®YëÖg69¸÷	ÿş³çS¦ÁŞèVÀ5$ÿúV÷BÕ#æÓjÕgŠÙs#ü+ƒYæ`Éox¤Áiëì|pÜoFå¥BÅ¡:Ë%&_ğı-ÃîYaNCævpéLY„•X£ J‡32uqæà²1Dw#/™5«MlÃïEêÊµæİy>›ªü‹:	Lƒ‘ö-a TI…\
0/›ªÇÜÚ¥?µjdGâµ%ê$rÌ\ÂP»Z24a¶ÎgÇO:¸V@	’Œ~€yfGçàqgÂ+ä0ÄamlíÏùIJrÜüş¨d!¡*œóÀ|ì¢$vA9QÚãùâHœû Ç2i/ÚP–{Z%ç
ò)dÌşœÌ…‡ìqâ’_ì>®Šâœbw•†É/1öLÈÊ¥ßôk=ŠW½ÆÓäço×S:ÕU´öoÆ•ªO<1r+rõU/a!
sóÇe=œ–û"ÉîëÓFõc%µ–wÿñş*ØƒJ7bCàİ¾äçC×Í:İöıÇE7©ıcôñ~z†8qç8öéS0©Fº‡ÿı‘P#İÌï¿‡õu¨À‰şéï¨ ¡ı9®Ë\Hfå%ğ˜½Óë6qİR^šì´  †¨W{a.j86ã7ù³6…%çd¢
ÇÙkÚ¦/Ågì¦#¼°ÒTmï;¿Ä
17™€Æ¥öÙ”…Ğ½.­sEgFƒğ«‡1‡o„Î„A÷Ÿ)¥‹i#u†íõ§Ú<L/ãe`ü—èdªû¥.7r)gG@íŞ¯½†|%bôYM´[×¦Gñ†HıË
ÉÌc³8-s…‰ë1¿ñ<Ì‘ığ“¢Ë¨óäü¹À56¢ü²Ë):ut–Ã`¥¢mi7="uä·?“StıµSn¹$­­=¸šUr¥qE˜¯L0KìštwÕ”9j«™N‰j8­øò™0\TŸÍF²Ğ5ÖPù0,Ié¡RËÌªA) "ùXŒ u6Í1îL”è²t~a’5O–oe.²¤æV.å3HŠ¸1TªÛ;îÌ½kœS¥h~."Ø¨tå°Ş\­g0¢Öi5/FG·t??ÊŞ‘DµQ}êë¦j½~Ä_%‚š:tN‚Ë§ÿ³|”'záq©Ë×âÓV.”q!$>ïEï‚˜Í1Itò›ÅôéáZÿ`êüŒ•âPMX«êksvTÑs„:1İÁhj*­*>€îÁ‹jçŒˆ7¦	He%¹²L1®Ê{ÕKÜ1*]·ı–Š7İ7­.?Ü+\L!ÒbDĞîöW?1ı(TÕ‰å1ó§[;5ìësŞ=
Ÿƒñê«v¯¿Ëg×"ŠĞìÃĞˆAQç!f /-G¤ÊÜ=L¨Ò\4´hªØô´$E•%°©­§µ[ÃQ(¤¡nTèáŸÜW.ÅÛXÓ.ŞÑÔï5c-´l$-¤pd\‰ß§³òvxÇs_\›AO.î•fîs–Ó×+äKÇü†±;•,=»šUd–¾„Â†éefü"Kşä¦àm×òñR`¿pnqå‘çgÒ1’§rd¸é–R‚#Gƒ›z6K´ŠÍÚf­Ç52º*›Ü™n R¢¢ÏH‡æŸ¿eÇÊ×øĞe#×´%—.¢°ê"}E€}î±båBşYŸñK‰Ú£æ›ğhVİªÕ/8OpÆo¼ø4õ+­>Ä_zÈ+sa1Rù6Ç"$÷Ù·.›:×ÈUËˆl2Õ±“`;—Ô-rÖm-”.	µÂ×·ëtOIëßŠƒ2º½Ê(ËPä kÅ¹,Cš+;Zi×¤«ˆ—‘<TlKĞpcO@)bäEpi»œËRõ}	"‚âg)s°„ŞG¼y,†ËpÚ^«´R‚\ÄÒEö<ïÉ÷Ê€{b¸UıÚWó©K6’’öÌ„Ká6—'âK÷ïæ MS|åL,¥Xù$+]€,¼S	M”8\C!ƒ8‹¥ä:¸C%bûs;º!b.Ş,ª@úZHrÎ(†Š›J>u¦—¿èvIô˜¾h/ƒHºêé°0éKHËNá¡AŠÅçéÙC_BDÍÜÅ	·ÈXŸü…–°¼[dDdµAé™V?^ÈMåQˆÁgœ\|‰£‹ôÙE"¡’®p‰Kpu>dÖÒÒ­Îˆ¥ûË¤{ÅuO¿8Ï»— "«‘ybŸáoçgs¶^mO#I÷e$‘îüÌy¼Aóg»Ã,šÄÛJº3ÁÃAÎò_ãğÊ¢;zaû	5óø‹W·è)tª¨ÌcÉa`ârv¶(jvOãâ(¿A”ƒN"Ò…ãæºœS~÷1Ø)p[;Õ·ö¥.õÑë^Õ|Õ5Ï½bœ:\JÑJH•‹‚ ğQcù¸°ˆ%~ğœù‰H—êÑJ‚”LÍ™·³Å¬4áŸ±”â…Ü/z!‰I¯ÕïŸõæC–Ë¹—ÛyW·Âë¸ÌóåOåŠüMî‘\YÜ˜å?•3@ÜÌöÅ>(õ”‡Õlü(sW<íB«æ*FÓ&tĞ\±¼üĞ½bŒü— öp¥zÈ—}ÇWğŒ/ÿŠ/ıˆ/õ†/zÂ·øß—yÀ—}¿‡ßñ¨L¦Ë½¦¬-{m÷¸‘âÕİ#Ç†¯ïÊ_éÅaü/Ã@éş­Ì©¢ÚÆgr
×²˜W‹6]¸å›ş×€rêÍeòq}~¼ÂãËÇ½½,xzùÅ_^®şğ’ëF|®‚aè+Ç½áÕƒPªÓQpt=,J–NW‘ó0‡QW‘	øºÅËÏİÁìéµÌûÈûT)³ nùØá4å$ú‰™ùyÒï„cJ:æËc·ÎCş>(L™Sªß3æüş‰"~ê§<çwwÄoñ%VhèğÃşYxOm^¶«ˆ1ñÊù7Z*4•G3‰_¿v¶ıÄ,ƒá]ê'„=Ã?è¿:îÁáñIğÿæy¿}Úìÿ{ßÖÕF’ü9¯ªO‘.iğXøÒÆ¸ÿ2Èn¦Áp$wé£S ×XRi«$lÚãı:û´/3gæµû‹m\2³2ë"	Úf{ç/õi#Uå523222â;­ıı›ÂœtÚ$i”•Ù)Ú¯ÿº=¯T¶=fU§tùaáäa÷åâÚ%EÂÑwZ“‚Õvö´’¼]!gĞ)Ú²õµrÅ¨·ÕyÕİ^­Ü_[I½ÀQØv%¾³2CbÌz55©ÀE²$×È”ÅvûÍæKè·r ‡yi…„Ñêj°½¾<«|*«¾½½ÿÓç­àÏ^ãöCÎQRÀ¶ŸtÂ 6È6à®‰ò¡»¦~—òhƒ)t25T¿¶¶TETó¢y¥IJç—FßÙSvdäÓ—Š*B}ù¯Ÿ>¯äÚX¬?¹µY«Ì4ø.Îˆm²`~`eµqã¦¼üÑ•)Ä¯<ûµ™Ê-ÏmÔÖ]8œ‡}à(ÛîÉñËê÷Ûç+˜’ }/=k®‚(¡ßÁ!áÔÄøvâgû\S‚ÇVò§nµ³u$ªK»=¥ 5¿BÂç.%/‰f#oèë¢ŠX”Îû¬Ó@|ó¬.»A‚S†,’æÚ¿ùI‰!—ˆ
\m¸voÑ™ÆÔö‘Îk9dÆ2ñÒÂÙPPŸÑV*«Ê²‹÷ï1lÆÖŒ|°n×‘xËúìLxáieFâ¯~´æ–Ö•S*7f`Y^¸ªfÈ×,ÌW lI‹Àº€â
öjBRÀæM[ëbaå‡äœHr)Ú	å$œë/#,V
§ù)¶“ÌNyv¯œ)Neú×‹WÍ'cr $ËeÁÄ›”İ"ó'¥İ J—||²LÀ.¶AÅ.œüáüV0lèo&9MÒ¯Eùæï€ò_…ò(¥Şiüp8GÕø?|éğsã4›Óñ?ëËøKü¿yøW	şßz­aâÿ=¬ç ÿ%<àÛˆq&il¿{bŞ{#á„ZFĞ<8€D,éÉ;à‡pfø(»ÄIx^>¨ñ¥$«¹#Œ?'~b”@3{À½Q¿ç8	ÄıÅĞGèšÑ÷Ï rˆ*œøMßĞ²øÙ¾|Ş'ºxbDn›Ô/(ğD°«â9Úqƒt×ÿèŸ?xHCJFôñ…“qN{Ã6s7,Œé­ÔÑ§gN€OïÀ[§®è‡~l8vßsÅŸ53Øvƒ‘ÖÓ­Ò)ùşÅø€Gâ¾ 1PÀ¼«4°Û¤ÊC¿xĞd:°ã*6•%²¦|“i4‚ÍMzœ_„ÓQ_„‘h|D?L;#dà]"4âxm¯¼>|İ^É¡™M2·ÒÌ¾!µ Çƒc²`v
Ü!ÁØ’œ±¸v¼jFƒ¿Ó¡ÍˆÈ@gz—*É¾’¾R”U×¯póC‚—½è2LJ «úM”D/Ş¡?!”à÷xÏY¦¹eÓ–¬v8Î¯vqE!²‚T¡Ü(æ¯­9±|Åv¿èL„>‚X(}ƒ'¸o¯®åMÀ?ı)EDÃ‹Êâ¹§[»]i:ú¬­Ÿª`2%·Î„Ö•V>Á×zı´^Ÿ×Lw™O¶$}P˜•ÇW)•YH’WYØc)r½õª?·ª[¯~³õÓšÙ&È’
ÓÂ8\ú…7Ãœı(à˜™V%P­+n¡VªvR<Ö¦eÄ|é¢‰§¶eéíï·wá8ßiıˆ¥Ê‘¡l4PÉà¤™;`²*Jfõ‡£¦3UÒ=Nê@‹Ô#H¡O…ÍaßJÖÎMÆk@¹y@¼(ò®q’ª™È½À¹°F ùD’;?§Sm*ÉwîFR’Ù 5rFêD•_N-,j)NäeˆÈïõáA¥:eLJ_Å$$qæ#º2ı³kôi÷#ÜŠ¡TZ”A9èö” »m$£']¢°®íJcKÿÖ+VTò”·+\÷Û•ıTöh*—-XË¿K%Í9]ıRÖ@jk	¼¶¬”!s2Œ™Dñzı6ÁõÑüH¥k8œF‚¤£OUbL€D?É.÷yœ¡}êõ½!pHØNĞLş¦±A,y|ÆÀpÈƒê$ZCcÓ4Á¤d5ŠÍIòsÌêl-$¿Itz¾rùHÁá'x7<s%[ÁH7ùÕp²v„¡Y™2¹ˆ/ñ`Òš
 ßKçOG·ê~^¶ù(ó¥N²=¸ÒQáÔJu9†ª½×Â˜?$©l¦ „Y×n6-“ëÈß62ÚüYhZX¤Ÿ;rJºÙ\S¬6-ŠªDy©u«j^Ç~)
m¼n8ß~3rqotB0Å´”g.½ÿ]yâR‹næxkĞ*>buÂp¢„Ãî">[èƒ5’–Ğ(Ö•è–¢‡T8Z„k¨½„ñŠ§³éÄƒúÆş d\X’L)‘'«tF$Gÿ>E)‰¦#rş…}QBÊFÁù¥ŸÚpÜ‚õ]«Õp
=ÿSÈ…ÿÒ™‰¸P_ÇCŠB;w<éûX§èäó–Ÿ;ÿKÈ=´Tø_Eÿ7#ş3|ßLëÿÖ/õËø¿7ÿ[¤ïÓ{­€¼<İ'™°^t9%_Í)wü‹§
¿ëÃ‡µ«àÊÙ²×Î¢:ğt¯ŞEµ_•k«zÓI¨ÊGUhoXÕZC/º#­`ÏDìî%íY]xM>\çÓX¸%Â1ˆ†¥Ãƒ£NûhÿGÒ”ÀK=>áCDıÙí¾¥¯;ø4˜³0EµAi°àmW¢qˆj5î¿W âUD°ó'êoÕóÆ0bÕª¿b¿Çğ™P™íÔ…1ÈNŸ ­ŸÅö¶¨Ş?ƒÑ!Ôƒ.aw¬¾A[²Mµ*³¯	”‡ôqN›%á|Q})ŠHj£/£z£µúÍká<ªyñŸçİòÿÆÆæãõÌıOscÉÿ—üÿŸ êáì PÉT_0àSj7a‡Š˜2ôäPa˜¶Ğƒ…Ü¿gwÒÖëÖ«v§wp¸{²ßîJ»»õY/?¾ûcš+Ü~È£f3'³©w>Œo»‹dH]>/”G¶ÊÍPdá¹PqZV	éMVè”{&ıÅa7Q¬Nç8òÆ; sDá€£XÁ¶×C[û¸÷s0NÂ§tw¿×†‡Şep÷8\•ı[Z¢–èimÕØu„P[ŞbÁs]è§„R'Íˆ\å*ü·½#•´i>ç,pÂİ §V{!í¦,5Sdšã*dônŠOÎª¦@3?ÊKÏ“å˜>ñ§:L§ïjÃM©Dz}·½>
	1ŞÚ™ùÂ"Q˜İl¼]zÃGWa§Å4ŒÓpe¿1nÀèÜÚd%ûù;ÿüıË&TâénÆ ÀÛ/2MuRª|a*fH-SVÇr#˜(H+”A#uœĞÓ‘›Üê÷¤¨"rğ¹o÷Zj’%ö~ëÍÁ¦„ıç;?uã§á%“ ËB­ˆ ïsè^i¥¸·Û¦r˜Ù‰}«Ú¡bqËï In gÛœ:§kÅ†¶…°.–`´Ÿ9 ¶È*^†sNCú÷òB„³!›Æ²3€ôlp¼Dƒgz~Î	ç’S&ßeT³E(9ôét.rZ‘BAtóœPm(?5#rAE™šÁíàtRu6ğ%!rC•ëòMõ¨¥ZOŞÈäÈáBÒø\9†¼¸´8ü.^»0œ]*Ø\ŸPvÈıâdoúÕi´aXñÏZ¯(nÿÌã¾šÍÀ—uEÁ¿Ì ¾.ä.ÏĞYYŸy®ŒàtùOÇ´x<	óÇÜŒp»o25]9Nº0Â‡Çë79r`Œ¨Ì“bó©:[Müx"¹‡D¥òÉ~¤i\ì‰şøı¥¨D
+]İ¦—¹ù4ßIáê‰Øûõ÷IÛ«TŒÖkãCf/åÁ+$aÃo¼h;ÆS!{ dÄ.ìç°AÜ»wÏÖ*H›#<y
JóÎ(3ÕÍİÅjß?`Kğ‹5#Ô;jXõÅï+>½n¿êì~–œ?)ûËöÈÅ]xçƒ¸«Öfº"WÏ¡·ÆÀíú"˜˜›Û¥Ÿ~¬hÊ+úàhogï¸×Ú9ˆ"V;eÊİ8‚E=ùàz*ÙUçTE*ìÇVUb;ÁÛ ^í_÷Ú½7­½cû º÷c!h£·7OUÅˆõäÉ‹ÂÛŸÏÙÈ	êaµ¶¦ER*±¢`¤{\ÊDÛJ…Ù2:(æ÷zôRs&VÌë¢ÕCİö[wR$[sÇ{ADı´¹ÃV‚÷ƒMTj5ŸÃÔÀïº[*.w">·AI³ä“o0ÀH©ÄJ™b1KTî£s;7äËœ®¢(+LÒ›öşlR¸á¸_£Z.Ïâ#«Ÿ$™µßCkö›‚£&ˆÆ£Úú¦Ø?î>œö Ú.OÖ)Œeä>[Sö?j&j^×ö¢A MP€ä´Ş
Xp7Œ3_òšş=#¨=/†,ÿwPH¶ûG°¯üãê×ã¤–ñš¡"t ©H¤á™ˆu‡–¬(S<”)œ®iZ"ÙáH1M²Z«lŠÊ£ôwÇNŒ]YË(Hœ²Q$ÚcBó/¦RLGxhÀY	WT7`@bo´9k ­™SrUĞ¨5‹Ì˜Ÿ[UàNe´Aó Êiªo13¬j^ú¼ö8j‰Íóe;àßã“®œf*À“qœ$GtíÜ®y\ÿ}>CH0vmÖ{û"I .QG±Ÿ†š¨”×S-Éåõ4íÛ`·3¯ÆuzšÓæ²ÚB^›ËlÕNß8o1ë¥™N¤1§<k¥ã®5’W¯{¯Nöz˜B½™·W&sn¬ÉÚ7y«²'°‘QğÎ‰Ü«·››,oyÀ
• ë~ÕNè>ğÍÆíIvãÉg©K<€DP`KG}T“Íî‹hÖspd`jº‘˜R@³ª1µkÆÁ”–RäÈÆŠÓL¼ ©N‰WIîš°˜éÕÑA/iİ·9£´÷FWŞ x‚ºè»gÈ‚™²¤€- \²|ı»ÿ7Õ©_¼Ùş?›m>Lİÿl<\Şÿ,ïn~ÿ¯¯y×?®ui°Ø½ÏN®å€,H[\İÑM?Nü1I’cÇöéºG†‘¹1‡`Ÿ[g*èû¤CÜÎù™ÄêÀäğç¤ewg×q,Ån¦Ûÿ'"‹T°›é£‡<B3|i^YĞ*imµ»R¢ÒvKŠÔÛ^.’5‰Yeì§œ‚d´¦t7“rl§£õfn»ià[ÊOÜC5$¢ˆ°«ªE8¶ÊÊÄAw3è™V}ÔşLŠœRÒáx2…äÄëá2ÊÁÇ˜{Uø%~F”RË©Ì›ˆr(?gªt%±ôş6kéô0ÇI>å`¥)—Ôp¶RÇLGªŞò„¬dmß”&ò‹-B’Ü©]HV·_•IÍ–R;wÉóM2(n=]yV!u™#¦¡áª½Ÿı‘'dLÌ_ÿ×¯ÿ&mEh{‹Fêƒ§pì‡?Ï|8ÑM£n"&S ¥R®4Øì'ñÑ¡4Ò?GÂPo¦ŸŒğÆ“*Œ†ûĞ~U”2£Ít,9ÁÁät½ ¼ò{u«g@ÓtF4Øª[ıVVŞ%ëzJÆW¥ìÚ¥”>Ö+ŠÚĞö2Ğ®”v‡ÔrG;]>_ñ'Z¿?ÔjÒ÷Fm½¶¾"œH 5©ÚíİŞÉ^U·‘½lëµxÂû¼¡*ii:T^çûı¸6âIâ<DNù¬²êA—±ø-Û¬ÜÏ¤@Er+¨õq‹«êé¡D¢I×†ÄU³ˆõ™»!3öT:eá5’äüc¥èšaäOHqL3õ,“ë{â8º©/ºÇc¬}eSÆçı Î¡°¾wZ˜)ç…óÉ;¬ú•ÇHş˜	ŸÇu gIŠÑTuûøİ´ †wIY½û²?åé(à‹¡éFFkRõÃŒôsCx"T>t›’ªµ7˜Ä©Ó¶fò¥ZO£K_¨x–ßTïŸ¤l4îG‘wu±?ùK§ıDMş…7L|M}âÅ»ü„ZŠGöö]×˜íëBŸTÿùkd~0õ“€š,%á-‰#Ér(°¦Šu¹%ˆ/}ˆ¨v¤‚òCÀÊRé¾Õ¹Ò¥UïÓ:tĞXÛ¢V³Së
¨$Àä§£î$I)Ê.×ZıCN.º+Vú°2çøKë¯-6tr+I2]»,@jû¼ùûãMeLÖ¦$]Šá½eìÒ†C¬´—(«m¡ïcGşØõÑñÏ0|“*ì5­5§³õó³¦ºÈã‰“$C‹äTR9³J)­-6Ò<75ÍÓŒ×àeªëÈñë™•(pöWÖƒğCu:‚–ADÑ'£š<¦&LşwûÒÑüÈê0 Æ8º¼ZÊ°O&zº3gİSªêÊ8
/Ùüj6µ¤lğ-Ë:ë¦ŒùEjÈ¬ˆ^· W
œX\0
Î‰÷CyS…±c_«¤üå6,/0Ë{Ü¾2&’äÚ€m”İµ}ìô›$!ú%§³œtö·uLÀæÓ
3'Šk»ØÓ‘]s2Û2(ma¡‰¸¿ÊJqçÀ´aƒ%Wcoi¬`CXGcÁWícWXi	¸Ÿ$’’K(ü`Kçd[R¥Û%pFşn†= şÇIäévl› |…1š^^ËVeÒñ`ïµYµªZ…=rÄ À¬0ªÛøKğ;zĞË´^gÂJ
‰-VLÑ¦$é,B.BÇê|:©ª—ax9ğåŸ”zİÃ‹ËàÜ—…r2Õ‹ Ùbæ½ö¢÷ş¤7€ÒG¸À‹“xã÷=Â–¡ûÆlïŠn}å\M1Å…,çêìq®Îçı½öë.ö&Ë¦öıü‰6c’O0ãÊav´Äµ_ÇÙ÷å{ªÿ&p@x€)C²åÚıŠkwö¢1ÖÌš:\½ò'¦‚ÕU÷î|cOëÈ‘ÀÕ±(Ğ‘—ã@ÓÍ9º+W`9õ’ °Y!¦¬£½vÚûíV·]¯Q éHÇ“»°^£•T~ÅBlA9_H~²¨DúH(š‹½™CĞ‚tvw“DÄÈ
¨ªi|O7M?×.ÑEÇ™¥~	j¦‚™|F¬²É@½ó¥=Ëş¿NÍö¿sÃßxÑÍ­†h¿ +×ryy/Z½LMÏºŞ$¬Wj‰bãÕÅ‰±Lå£¹KÕXgrB„"eŠŞëvvzû¯¿ÏŸB”IKpápøxñD¡Ì‰bÕÈIAsÂ\zv%jöÌ¨}îôÉù¥2°5f›o 'm”“ObÃQ‚Áe0éÑqh{Õ=„#Š(FLSvÔ]Kôqxüç9“g:ğ?0ª}
›m)ÂÓõš±ŠòË0LeÌ§lÄ¶öXMå“~Ïfø¹£°ø`åüMˆ1“ª¥2€?~üXT;W3/•æQ&wfÍË¤ô¹+¸·kÔMZ%5Z_‚…fC“*j4!†ÙMæ,¡}Ã\ù´™(à¶Ï\µ!ÊèÏ“£>†H	F}Rx•:úL~ıW„è láRj¢'™0}÷„@Àlwõ\h_;–ÜUõF2Ö	Hğ€ª?­yc&6j¬ë¨ª®9PéE×ù%Hˆ“j£ÖX¯=¬Â«ÚÄ‹j&´äëë±R„nä«I·h j|¼¢0'¦gb:±õ6¤Ñ|eJ–¯(ò7aÕa”ÆcR_ñ\¢©Œ¶~øl1A“/÷î-šÓÀ›ÏÌiˆY™W<
ç`½]ı1ÀŠJ­ë LeÈÈ5/-"ZÈf›î—Á!™•Ïâ¡¼zS«Óğ#³@»È$âÒBK‚.Mè>¸Şyì¸
&òM±
_‚Làh:¬™ÖpzÍ	Œ5[œ%oşoÎÿéèç`,ÒŞ¶ÚMOÿT‚Ô
ÈÍ^&ğp—fÿjA«*©úÔµj2U-Gäì ›¯µ†•Æ›uÇ&S$¢ 5¡6Åé@œL pJ¶Ìqÿ½(âk¼¥å—l`©Ö<Ìo5†‡,–ÑKcéÁ¼¹±±ñø›GèÂ,7öÙ)È˜åî™ò‡Z<J¤IÚ¯®çİ¨ù°Ö¬=tóY{JPã³>bÑÔ3œàšMà{²<n6ùdç•“mÛ‘!{s0$±çÇ˜5¡r¦ÓVÁdª6n>›fî‹ÅYŠóÜj35vSÓ¤gÑù)’	Z±†JÎÉÌC61Y˜î‰²nÖZ."?7OÓòõî÷‹ŞHüÿ†äç²„¹Øº„ªèî½Ú{}‡[¾fEéÓø..¤çğ*Sƒ1¦¸?·!q¡¦›–‹ô#ÛV:%nù’WÖ)ÄZ8RºÄ)İ)]û±ø‡¨Õ¨Ê§äŒÃ%ôêæ%}Í»Í”Ñi±Î:ƒ ‘ñ} g™£Aè‘‡Ø©+»UP\€ÑF¤•gBm!©ŠË$ q6@¤Í ö‡‚0˜0l÷nŠeÍÙÃoQó±aøÇÜ¬}³{ü{ì«…(ÀúpĞOT´¦Í–âwòÒ4ÉòÎ‰S›í’Ÿ-¹‚±ßõY×1™Œ|÷Tg)©{5#DQ.%P¥¯bfU‘¹â™8}‰³`†Ì•Îj_ï¤Ş»Nšsx>s×¬Æ6¹lõÌ¿Éq°`q¸¼är½6•òÂì´™uÌ5¿’GĞ4«b¡ÚR¾Tæˆßø­«Mx»$½NÈjWâ7•JäÊŒ†4¬Ú|è÷Bä‘‡Mxèöº:Èp­ÙÄÜÎÍNÁ÷ór‡œÉ~7MœÕÆÛ1M‹m*Æ©ÿ^%…ˆ-¬[€·Ë/}ÙÚÛ—|T³N×É½”6om]Gß«søEe½Á'IĞ?Zãého¥Ëúè¢¯ì^ı>v™Ë:®%¼™–bØpêW¾T”Åd‘Z‘ÔÃŒ\s>0`wqÆd¨ÈOÆJúœZJ\H`ÃzUÒ…¤IHåNcîv¥ôV÷{ìÆ‡‘¡"|š|ÕNaçæ+Ğ9‚ è#,PŸp¤jè#“úµ6B
T‘èâÓÒÂwŸ³QÖáÁ¼·LKà$+JJê|¿ß‹èáö:È¤ƒ¨³sìEçç.#œÅ<§Qëøë¿\•ğãØ£›Ã>	ÆÕhŒ¢Ü9Ú:5LúQ‘e5…R¶¯=8‡†«k¢lÉB>–)+»òJÇ	‰e^4ÔEp˜^2/’F²8Çˆ•&±±¬E²
+Ïqä±A¬ ¹Ì}˜²6WS-mB\ZÌ„8§ÅÖ˜›laAõ]Ç Åt]¨^†B¨ã9Çdj#IGêı!@&óÁÏœPªŞr:t—pçz]¹ÂFˆ3~Ğ¥¤İ½b¼cë˜aG)€ó;:Üzä%…ñˆ/aV…pZÃßè”ñğşU&”şT1NÉ!Å2Ä…ÕJÓE¡‰¯ÖAå['ñ1²ß˜¿!É›~L|J¦ó…Ljkğ“a=ÿõ_ÙÂŸ'ˆgøĞ›À:Â^›½}`QnäÃ”QÖ½÷3,s<y“·§Ú×v¶çŸïùt‚ïmôÖ{ë)WÀ¤«æehNÒ–iUÜ˜›µe3Õ–6fS*uí¹h9¡†Sb™Qí¬lEkyÍìØ+ÉX9ªûH®%õ:‰€—åB´7eL}òı5QÃNHpÊ£VË)Ê~V¤ugeÊ}ñ™)åÊ#¡B9òå¦×Ì¸¸ËMhÚÅI0?åe»[B­à”ñQE™jNÉv¯ÒiÒ;ş¯ñ^ËØ¿/€Ój`zÑRÆ| wì¶_¶Nöso¨<º–1£ÏB8‹—xO¥±Kk÷Å$<éûWŒÌLsl?¼œçS"S“ù2˜ePÅôĞ§8<¦7µ5sgnå’„Ó–¢7£(•dxÊ=£TÎå®S8¡îü‡Éq(;X’Ü£ÍµÒïA’K‰TØÎ¤³›Á¹ïBL‹J|Ÿ”•£¾¬ldá¨ÕàæZ„™ÛK~Ï
¶¶¸	Ç.Ü¤¾.Øfgqåò\¶,¥tğ–’:3…™\ÄuV›Y˜ù0…Ù¹ÉÛö°É%bÎ¢(òµö‘¯±'X‚cáÍİÆp¹,÷G±Ø4	’ª°ì#ä€à½E'{{d„ XÜCÂ¤-Ö]+²h©  cİTVÏÀÌ`EÍÍšª %mÔ}®Ì{º@g„ÙÔB´^8@—=àÑ^,`3æ£±Ü@3Á „3²uP×°”Œc˜º)Sãú,Šrxæ'cBsîGÈŸá¿A_[Ã’”²(I¶Ïík-¬”—›¸‡3ÜÉİÿÒNzçËìmYCHÈS iàäÉ å”:.Oµ'ÊĞs(Ã‹½(F<z' ĞTN	ıùûPwMÇCQEìt·mõ±•¯=„GRK9cwJíMNÁV”»ëeö‚Y†_ÉÌ?
ã‰«ÌlyÃç¯ÿgÆl¹cü¿ÆãFs3ƒÿ·±Œÿ·Äÿ»=şßìğO::Ñ­b?1 …É}…ì2F¼È?ªd'„Ñ±¹ßÀv;feåÔÛØÚhWÔ‹ÖA«ÓŞ?äWëğn#y×=yrÇw­]|½©KìoYZ’\]0êjrŞõ¬2)Ù¦•°õ·“}]Àfòœ¯*e3á±“zê“á˜¥".=®á~˜Hc98¯/=ôš“1m¯•@‚AlÍ€yâ"ˆâÉ½T@ yå;¶¡áĞÂZQSÖûN’ûWP?ËCÿ3Åİ5GoRubÜÄ³(wZ{»‡0v/öÚ¯Û<á%‰p9YSV1ıºÈ¸â+ÍN5€?ì¾êí¶[½İ½NwÛE4»züÎ‹ü§ô•‚NÊ™Hã¥ëä
·.-óÔK‰pwèdıéätòÆ lb¯Ôª¯*ree{¸XÎQøÁúâìZìz£ÀˆÃ°° òĞòg:k£ˆ°Û~±×zİ{Ù9„a{½»í^ÉQ½–nÂ¨SRq˜Œ‹!û©TìOs ¨@F6²¨ğD•ğ=Û?˜5äD…ZwP(#@ÊÌö÷“p“ûcÿ1V¢*Zï¶»ß­9­£ãŞáÑ±Q ~â’àÈŸÔÎ§^mz1œÔÎ¢$©‹²Ñh>qrÀUÌâšh	…5´‹¦Œ¥“İÖ¨~†€.[Z7ß ÔùÔÌ²_¥æä:<ª5jóYøÏl}×,ºù„áL¬93Áf¾V¸œ(_`MÆ4”	)/ƒÉ»éÑñïÃ±ƒWàÏˆ~¯Ì.6{|¸Æ)€J,Û­™0¶©ãø¶ík§Ó‘ªfCã¢g"ªé0Uª±<·àŒBÅe½9ì|ß=jíX%­Ü…S<[9`Z/–u±¸§áBÇŞ¹ïä„ãÚv3±»R}9h¿>éí·¬ôù\ºG¢Ea(£¨šd®cø„Y$¼$G¾êfm'¨L¥ç|¬Ü=­œIN§óš3.˜¨ĞÎı[|0M×ÄmwvZÙ/ä°ùƒYc:è”Òç,i°²Q•	u‹£àlÊT7)I•Ó2N¹Á”›w V}"W´á·]CÜä‹Ş”—}Â%jëµìëÌ¢¯Fµ‹È÷Ç^ˆzTğ¸úÄ»Œ¥,—òÙuÒxÂ9D”1Í¬}íÉS`Ãòf*Á/Îê‰IÔPÔiôĞ5¸E®¦ë¬ådÔDÃµ'5Ê(	ìÎÖ‹ÃæE-év»½Vç@=·˜ä
À#[T¢Ò‘·st"-£·Ñ¶å°«I;@Ú¨«¨çÀ¾{éâq 5¼0·£áÕcÏJ>:ê´_îı°rÜ
ÊŒ¦aúÜÆ-Ü6†³X¨}íÉ‰–GT®rÔÖ*pØm´?í÷«2@Ñ|oxµ%÷Î@Æ¿Ö0¹ËGü¤‡EÕã÷„ ½èºÊ:º*ƒQæí<ˆB(ç
ÈMÛ©Ğ_ªÉòg’ŠÜªÁ_³½Ò.Í%d;ıú]µñâ| §€ñ½÷å‰	< Üi¿jÿ şÚêì!Ëè:Î›NÏÚG]|báşe.×=Úß;>nïÂ‚é´@Âª|"¾W?­×Åç5NØ=NÒanpö±Ñ¨öı+TÎ.'ïCé_ =ƒgÓãá¹DaSı‚5r6’·'ñD}÷&ï7—ïÎ«ª&Ü.ÓÉFò»NU¹íıÑ”îe7#É³œ X <Ä "~%œ»Ñ/ù¦£È‹´OK¿^ÿÌÅí¿â²¢´Dï^sò ›‰§”…u– 9ãõ‰O…<¤ØØÄu™>‹VŠ7†/8£pTÅÎ»²°*Ø}¡c¿}û“>¢f/£ò¯,ôù)">õ2ÿöFGÜn¢A1ÆîAß9:Ô6¾M¼Oùä]«›:šS8#NÒÏ’óş[FâŸ{wÒí¶?¿Ç©W\A’ù$†âôÛ§êäŸ$°ëMª˜ùQñIı€FÓ}¾Ş9)ó—«J²]âV›¡Ö
+ÌTÑ™´?^ÖH­Ç/ÿœ_ñ¬¨¾ãPü}OôU›„Ì]%8T£¢÷¤S«Ó»ò‚ªG1V%¬Üµù­¡¸Y³	­‘Ñ¡ãÚµ`ù—«¨–&±<&b<eIwˆâ*Ô¤Ñaöfu:¡Ó1=Ÿ®Îo=®¢9³°‹û˜JË¼ÄâSk€y©<ÍhÁì¶ˆÌÂ3Ö0w…Š»˜¬Æï»ÇFj»˜¼~}rğ¢İI¯ÕØ>¬ÌLK¬‰›_5ÌÖkGµ†ª5K²c#ø¥úò:œ`F Jìú/ÿ/®µNo+äìàÂñ9†ßŞ¦ÃìÆD ï‚Xh‡x:aGš}lÎ”û[ÿ¢ö/ÿ{˜
²y´¨¼6³Ó"D-6Vj.wºôU=#qÂÉúlÅTX×»6ÔîÀÁóRzäzâ¦N>çïğJÎ×C©T’[­ïpèü¦>|Üº?Qjá™»@#-”™I÷ä5|â»64³Óı"JjYöíºÈG»›óºhLç™VîğÌ¤Àxê­à¿O+¹¤Ñí/´Jä‡Äz3«º¶àçjŞı,òFçïPì>‚À½ëLaùšm~W ç—íÚ;Åo«ÔíÜ0=R	¦]³ùê¶k´=YaŸèíæ“ôË¬3êd—mèÚò{·Wš1ÙÊ\Fæ}ş°üüÿ±Çõ¯ZZy<~ø°Àşƒ>)ûFãáÆÄÃ¥ıÇ]?ˆSµaÿ+±ıÏúæÆãÇ©ño6-ãŞÉçşı?Îâñ–ù¯)`¯6Öø¡@ƒÑš^ŠÆ‘Í“ı×ºvRdøK‘Œ"Uÿıûsÿşk‘àÛ³ñsGbÈ¥È}6êÛ$LVuu*ş<ÇJº{¯º{İùÙÇÂ—XùÛgñ$
G—ÏY3ò¬.ş”¼™Şt“W3k»u>‘äÔ§N£9ÆkyB6_¦ßñé9¯7¦î¢ ãĞ–_]³İJ×n»»ÓÙ#Ø#&?ÖÄ³”†!Aç‚÷pˆ::~€“ã$Ñ¸:}Ì{ „²¾åci´&“'Šª¶ªQ¶Õ	í€”ÊâCíª>ğ¤X`ÆX"u)*ÉI²xéÁ7Óìh•‹©|š]Pj¦,¢^),ĞšYácšÂr¦¦Røä+Ï
KÊ›Ãœæ/-™¶lRMFSF)ÊLMÙ 04eb­`æs` …G6ÍŞÊY÷Ó?şñVò“ÕµØç˜&FÇ’^%yÅ:#MôëTS”†'õXjxf2Ò]Ou].TQ$üãÅÉ«íÆ|úÄ¼ÆUeÆ„ä2I 18rŞèZaix‘&ÿ*;X*ÏÙóp:š`X?~­`Êu™FE”GB©/£%YØ“Ù¹û/‹-˜­XNÒ=¶³5¼ñŞÏøQB´´÷ˆ´FP>ƒ%‚W?É ¼P=–j·HÄè©¸Fd«'Çßv RÙ¢\Ó=á,ÏZşÿzgÀ[œÿ7-Ïw<şæJ¿ËñßXßh¤Æ-Ïw2ş§.
:x6~ejjÇßÙ'ª'Â5® ‹ì&ü%!g˜:ì¹N­ûÀƒ›cïA§3f˜EÃ»5g ‹¥V§/X”9½èüD?¥8ƒ¿1‡p2‡§l¢Ü4RDÂ4©,Bn…Yµˆ®[uZ=å2û„¥cëy"£ZéÇzN×|Ô q&r¾äùÇ>ş`¿áğƒ•ôuRôÒ—\f>PbI}'EJ!J:yúH‚ƒ“KgJsNF^I\AU¥ÎF2kÈ0mÑiÂÈÃãyªrÍ88Ìº]·ÎkD0ë€`/¿\á_5I‰ÔØÕ5­ñôås”¯é©’è±kJÍY¬·ßyZó’Ó¢84B>Ã6|aù›Z5po ‚§¹k]	ÓV[rSÚ­UÒ2vecçæb1‹¿,Ï‘‰yµ‘<ì¤ÅàÕ>=è…½Æ½'C/ aıš³”Œÿ[Éÿ!LtäÁó\\Fá¼˜£ÿo®?NË››KùïNüÅá„Ø½èøÿcêG>rÁX”Ò‹”EÏÑP)NùÒiF3ÄmkèûÌ{.BŒ%ØÊ”ÈÒ>«C1PX8“ë±¿íî¹ğ³ôl<'¬Y²›–{ƒX¥m]ît±XƒD1Æ%&øÌï"ÿ"×-ˆ¹œbrtÔ¯'¼UájøQılÁÙÊŒêvk÷ ÓŞ}®ÔüHk9Õ½ç°I ‘Ï*@«5¢BíYz";„.Ê (1¢0‡é¡–×É§:£¦ŒG”¡’NÈÍOÔÅ.›|¾ğbè?ï»F1ª¦çØıe÷û'¢eZŞÊVÃ +¯3Ø
#„@´ì`¥eôšUäËÈ÷ÈBCt'Tâ‚e£µ®*ñ—‹_şi{‚°çB¶EÔÈGí$û$€ú^wğÃÈ;‡š ‘•]î›ñ5â1™;:mˆD÷ ŞÄ"x4—‚ xŠ¹÷&+±¥Ò‹Ã"Åc9p‰zKº‡k|lª?AnT/¼¾76ôæFÛÔAG9•ëA¯‡\òO—s¢%NùÓ\5½j^j£™dBùä§
jÔ'Çö (0QôL½gÎT£
Z˜š[(õkb)ügíÿ
Õs„ïK[ÌÙÿ76Öfô?Í%şÇíÿÖ–Şáy ˆ9|Aª!{¢a4”J€3ŒÑ;ò?ˆß›Ly‹=›^
2z«9Î¹ì‹ª8<Ÿ„g~ô€Ì´ÆdÑB²Ê×í7]ãb£ôl:Pj3õ§ç¸QxT›Ş¿ÅSñÌ>7OZ=8WMÇµøİ³:¼19]¡Ìeœ<Ôt¡wD<ÅøFı!ì`ÈÓc‹3NéxÍ'nã(GêDHà#øC³É©f“Ôù&t¾ÓÀÈJş6‚3Ô¢QáåŞíİ2´È×T´F„ `ÖVJW×š^¢@ÖøæÔFtF(¥¶n’B)sÈUÑ¢©¥@Q1DóI^"‚K’Q;ÙÑLõ#ÂƒÂ$Œåß,H† Œíuk›äéÒy×85Sj1è†Ş-´ÖDj¾xÆĞA9ñX6ç
àBC’r¥Iß·¦«#ôbªD¼óPÆJÃVBAšŞÙm#zë…bV©kfûxD ÊI…´^ŞgâÌÈ@ğXU…¢Şê\=®Ëñ¾Y>¨-'Ÿ9ñš–€M:¿ı=q€€®—~œ^êH÷”ıÒ_NÒv&î#í>bÍè›O	¤6ÑÙè¼q¦ÔŠ±†v$5îÔ<”ı¹—7Öa„¼kÑX7fÂÂSá„C±PChÍ:”'¿l
`uò¬ÑxT[—c/à7'iâ¶¦<+>(|ƒ‰c±· WğQœŒ4C—Ğ²|;b:#ŒÇl³œv)Æıùï«]û-zÿ·¹±™–ÿš¥üw'òßü·şMÎö[À¿Ñ%šƒ$)ÒÕğ‰R­¢§{7 p	ÜÔÉ«Ä·Õy…ÎL÷]Ë;÷àUG¹ïngšÌmN'ß9ì˜Ş;ªô=úÌ$u!.Y§w|Økÿ°wœ<ŞA_£­îwÛ.Î+]¦Jœ‡9¦{–™¢;sä;	 ôÑ›İz%İí9¿ù˜ê'@×Ü•õ¢Ÿ¬ß´øäıÏ‘áŠI\±2ç4Ü‰	ûT¤ÒĞ Œ‚‡“w>ƒÓx lÄ9ûÃ1ŠÆğ^$‘üf@åÔ/è…I¶¡¶LHîè½X!ìhšötXòÆ¡'pfÚ‹»ğœ¿"8?9¯_Fát¬bÃP6'†J³Ğˆ‹‚ef§ÆÏe˜ùwSµp$<š`ù‹^ìñ.Ç,xŒúÛ•¦†kÃUmq+*‰›ß¢üéjÉ3Zs•Oø§^×ÅÖ?‹2‡¶G	°Œ±a„#`c|®§®5KiºÓ¾ÖDî+ñ±_ÀrÚ9Ø5 º9Æ]†ı]T?ºº6¼£¶Ö4Š†kU^„¯9¤•Œ0½¬Â(ÏÍY”•ûzQ™k¾òma­G…å‹ïƒ	×¿ßªsü£)t%v÷ºGû­·+ò‹ø¯5÷áYò]Ü¾}m¼bq¶4y9† -bÈ$\$F‰”V$…ß¨­b:"?iLšî?ö˜z*g)ADâ”,X¤—,g‚šÉ2I5Ö &w[Â±«a¥‡²±¡ZJ(ÕÔ¬½×y''©íÓ)%+QNXWNhûÑ:W-f;…Mo—~&i>ã]-d§d²@è 5ºCCQ1V,Åüò”!½¯x ùÿq¡üßhfğŸ7!ıRşÿ”ÿËeqüİ^W 0€¿ÀµZÇ{È±¬N;é´wñËâ’3œŠ¡w-ø†¤öé„±àGtı@œÁo4ıá«ÖaØ§8/|“ŒùÎ|1ãI-’ïÇ©iHE[³MGNÙÌ"wxQ­rî¾?†Á„ìo
‚¢#@Qì.´‘Ôl2*œ€¸°vGÿâ©PwÚ*[-ëws¨p’óƒ)Õ ½Wã¾SÏ‘ä*ü4Œ€§ˆÀ7ª§‚G&…]½Z­‰ÓªÀløhïéœUuÒ¸"ÄØ—\ù.ù¿
„MÊt¿_›|œ|ş?ãşo½ÙLûÿn ºhÉÿïàó´fm{:¥™eğı’Nè–5¶S:…‰\ô€[uÍâ`÷lÑ¥UòÜÔË…¹ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏòsËÏÿ´¨h h 