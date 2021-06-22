#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2704418260"
MD5="e22bb8c070fa370f23ad085c7b994f98"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23012"
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
	echo Date of packaging: Tue Jun 22 19:09:20 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿY¤] ¼}•À1Dd]‡Á›PætİDñr	A=h:®Òö€Jg(½bÜtÔ×†*W`Í nZ~	yÁğÖ²(Ÿ üqtóbô¯°.°ôÊÈ~ãşa‚(Np´låçõÏÁP§Ö"Ò‹¹2Ê¾h–I[¿>>YóÆ4Ñù“tÊ8`: –Ùh½‡yQÚ-ç°Ê­‘yóná•k{lÆ!ÎjÒ¬ŞüN÷îÄŸê¯FišûLÛLàµ¶nbæ6OÒ08Z»Ó½ş€"&wxŒ3Ù‡@ôp'¾ıƒcI%>—bä@\ì‚ÂV`õº~<íû#	ú·¼‘­]ïÿß
¢®(’µâÀ„ûr…T¦£™BZ×Ø‚TÅêÙJR¨öı8¶”©™Û¦k¬o¬MÊ”I*²­Ø¢´+úmºáš#CÏëÀJÜÌ°Óó7œx#´6ªmµÁ×ÅèIÊ³^İÒrÏŠŸG.ÂqÂ
‹’»5½wŒ {˜%O
ÿg¦¾æbj;0,áu¢—†–İ€ÙŒ7Ïÿ†
¾æ›„‡åWßµ}c‡"ÇµÚjë‡&Yëh‡€ŒÆãÖÈÆ&˜‘¼³ …—^ˆß' ÑÖ5©äp¾ÖÖ¢8‘Î=½|'ì%©©Ä97	 í1,p»½¢Ûˆã¯¾Ñäş¾³Ğˆ3îõ~äİ«>×$=Ø^…’µñM#ZP­,–BãVQ¶Â¨aùƒ| ÿT<£@àztÕ¬Ù[åkò™<¬+ñè|C?.„‡)gğÓƒŞ©IşF«¤êßç¢e	Ù¶ğìØ…VBÒˆÎ‹‘Öz:}·¨òF÷×ÊÌ«‹v @÷Ğ@·6K(h#±tÀeeÆ\a
FEíilï¹i+WyÏ­¯‹äÆŒ¯Is¸¥:Ü+ª×gåIë»£yÙé5Ğ´dŠ,_Ñ(™1aÇÎHéÁ¸ïQ©›p>r¯i²@N/‘ÖwŠ •>Ìá£ lZRè(ùâø)ªõÉR6äG*öa¬Øßq¶|àÆöÜš~¹"İ@Hæs,İºL¬½eìhÏYèÄ’`á¿àåÇ€~4*n\ëµÌûŸÿ$>…à_¤ŠgIÂ§’JK³_ÂÆA\f¹ó·—iŒb	Ö®Íwu¡ï…ù±amñÏØ†*¢]¸ß¢ãòöËBá×±ı¼[Ë©~&÷¦[®ÖjÃ!¨¬ˆ+)=ô_Ò¹nÍa˜#
ÇÓ:õ|aäûÎ‡7?ß¹‹·^×Ó—,±5à´È8r4àóãŸ¡Â%¿Tñ&™œ€_s}îèGiwâæCÓdyIT’6ØÜó)Ç…(Êıƒ6ìÊÛ©D%°'şS!+r-è- ïj6‘«L~ÅÍŠ’mZ«uWÖüÀ;U#CãòT¢~Ó¶Fv8³nVm“¢ñÉa_£×!ákzIj‰ú¤ƒ‘lœ4¸k,Ş-
Åœ.€y£/–hËğèÜ¤Ÿ…Úlf#ÒñúªS^¬ÏOÛ¯ÿPüY¶?ŞXxÙø€~ı²@fiÆ:…­LÒkãTD­KÕ?Èƒ““3Ñ;¬f¸½?Ç|'Âj}Ø·ä6‰Í¾Õì ØŠù¡×Óévåáñ´oŞ>HòfãÏÔ©ˆµ9T¡|Y@‰`{ŞF"ä¾¼…rÓû_f€²È<?
Rsçw†\“Ù‰Zy’–§ëˆ\¯W)4²ãåÿßWO[åäš¥ûøÈ©ä GäC¹àâzåàs‚¦ù«I¦ñFSÜìDÌä‹²5EÄ·Ô	léÅ±hp]Ôù¢p„×­!wVò:ñôm«ˆ³)‚(’¶ıIí±ìo&/á[İSw>&	ÊzÄ¾E/‘ˆÔÑdæj[ùÂ¨‹~@9ë*¼Oáœ?ûZ®ˆ¼ùUœ—ŒùW³‰å›ŸÇ·¹ûâ*%e„Õ8©kÆ¿ùú$Òë‰Ä4í75]ˆ'…@÷óê¤:G˜>h8[g*Xêt]#ˆoS¥9˜¯xÈt¬­ßÅ^$Â5°§w"8`°2+P°;Ow&ÌY$Qóm zô¤ÄRÌÿ9µ)v[xxç@ŸêRã«n:É!“0§ANmtL8(hŞşøSâ@ôåª,ŞùPH$ÉOq m­D‘×Œfk´ğç-Âk?Mà¶×JÉ²Š±ZøÌ‡øôTb½/ÈoJWPÄš$ûæj{TøˆwyêÜ­´ú¢ğ›´SÑ&íÒ34I
A+¯Úÿ–jŸ»ŞÈrËóòşËGàÔyé0¡­‰[¼¤Te”ıî}ÓÌ¡xÄº´z­r¾7ìïÈ^¯Ù×÷l 2©®^]qÅï†¤!5í¡&—@£tfD|:Vt–ÎÆZwÉ!ÜÃB.Pi†u¢Pİ¢şA”âe2¶Ô Š‘Ç¸ñ*È5-_K‰†~¢ .µÑ±àhÆ¨]ƒ©G/sb2$8Sæ	£[³7lÕüa 4Íè„+±ƒ  µLĞ¢óå­o[…U%=T¿œÎVV«n€¤ÇN‡»])Dõû©sdûÁİ·cHš$i"æj§·´õùhmâ yXycu¾ú$¨’ÚO+~7åâÔOá@8DÇQçšéï0éİ7C0Ë@¥7G5:ôÛËİmîÀĞ(C(Æ·4xÛ6™ŸŒïäü¼5½ºT¨vŞöÎ³9@g³›![Æe¹Y`c#¾Íİ&`Ô3  úlŞ}•šÙ>?T ÷¼¦i#ûÒw»Î4äg¯¨–áò¦BGÅgäãæù\èÏ`‡ÚS£®c„ÉS9>Òm–[¤ñï78®o‡DFÇ	e’³˜®ç¦£¨¹fÉhó·øòpşï(Ğ¤&É”S³Ñ~ß[*udÓ#àL¾ïi›6—¯œÄeç_¤Ş§Zétæ©•5Ãœ(uÛÆÁªŸsË§XĞµ¹”du‚]ƒY`P¯«4êj¹ZÌÄÜ’&	’…˜ûIÂ”ÑÓùzíå;©Àj ROnA<z­ìı	¿ªÏ'É†À™lÏã”w¼µÍ~ñT*õlÌ.ÕUòwÃˆZÛ0)	)P\,MvØ*3HJÂD «¹àÛs½>›ÃÀ"“!„:t)ô­	¬»Wº6o2İë$0ŞŞüÄ=È7•^TP5sŒíÿ[Õ(®EØTõR$×Š+œÌçuìKv:¼K:\…ĞæX©6Z@<~hşwİ!Ul&ºbpf*¨¡JÏ¨½±6_Ü­Ï­"İAôpM²Sˆö£ĞE‘Å˜ã›˜«#®Åí/–ßÏm>€MKÌa[q!ß`ÇN©ÈªCä>™ÆÇi÷ÎÖš#.K`|MMuíĞbê 4`ç=ŒÍ£YçÕÆŞ/ÅLá;!¨\R¾Èv.<ä,„±DlÌEU<ô°~qÁ5.ÁgéÉl#¥myşì¸}¾`3'ãs;'ÀÏÑÀ¤Ï³”áæá•~ßY¦Ã6€su oY½@<ÈêïÒèÿ¦³Áa¦Kˆ6(fùñlÄèAğ	t»±³M;«ô-%'v*[ı¼kŞ0¸‚ãEÖI¶Íg)2yºbm›‚`jÂÒäá0>¹„´AÃ@çÅESC
kR˜óQàÕiÏt¤†çâÓCpbÁ²îE[¡tjŠ÷º˜>…úô•RF{7Ù!‹ûlìµq9–1 ÄÍ¼·	¦	>ìDÜèÕŸµÓq‰¢ùÀhg‘s¼²¤¶?¥¸œ°EG}ê³³kHŞ°ó3Ó¸âşÈsÎÂôõÃØ:çP»m¢‚Zõ’r¶n¤Æ.i|™ yÊô8ı4’ìĞ;À›h¬5ê¿Z”@Wîä-ÔıKâZV"‚ÚZİÉ:_”*V„Æ7 ‡ÔD&ôZ9*Ö@y—;±ÚqT‡gÃ‚—V†R›Äkj·ğó ?c‹Và8&-Ğ¶õ¸3Rr½¼
ÒšzyÃ¶ÔûSRŠzXJxÍëBWşMîI A <Éà¤ğæ-‹@ ÒÓëÿ¶f\-ËC|ë§ÚÿpùµŞ‚Ø†Æ£ ¸«Ê“i,ÍÜ>¿ÓuRè`ïıë(Eº«àwŞL‡>{òCpË­¸†ù@ñŒARÖàıI£—6nMq²ÎÔÚTSÉAÒÀÄ	5W—ØœHÄd_Qú2ÛsßêòàÜlÀUÍÿù÷—›şJ6ÜgJ¸-ü©IäÄ§¿ÀWşÂl: íâô>L*Ú…W‰AUµÏœÚÑôæÛ#e<Ç…ûAà³\²¬å­Œ@°\ş·¼BÁÉ˜AË´—š³ö®^ÖêIÍ <™ÛÏ"­©+¹G!–“<ôŠŒ÷M„snö;0õ
à<Ÿ¿»ÂM/=¼Tï;×y}–!ô)F´ûÈS,F…¼j1y¼;-åPâ}÷Bİâ:ˆ«lš^Ú3¶® ¾’É¡¨»«/ôƒeÓP‰cÔVìéÃz2C¸Kö¾Ø•"q±ŠSF˜D
T€3ÿ“ëşl…‹1%‘÷sX°­·6:QúYß¥Àê©îQ’x2ºb|‹kovë•ÌsV•S›·Çˆòe_"Pİ\M÷¦&ì‡?«`„D`ù«a¹—V,Y{“ŠÈ×š¢Wö,`-=æ$hÎ^çÿí]¤Ë¾‚È‹é›9u—¨˜D¿BëØiYiI–zöœÀ‡´z4ñ$yÇö	°O®å¡ë~ûÑìša«ƒQ°VÁŞW±.NmÑYÂèè³µ™â5×ºô¬'¬ Û_ãÈîâD`ªæ#_œÔsİI:Ÿww¬Ù?•{­Ëó8W|e(.pê”‹£–é ¿Pm€8}¾;ä1QD’~glé³ÈR˜§Àˆ_\2Ãö¥Î¢8&àŸ A¼Ÿ.&‹‘'EFğDAqú/~'–B2\$òƒplÀmh:¹ç=ø…3ºraJªÕÿ+Zì}(7êœ-ËeTn•SÄ…ÖÔsŞ–"Hÿº.º`Ø~Ÿv·¨¢}ıü(/l¬0‚;	±ï¾¼š9IH‰ “–r´„¿ æÎCÀ¬BÓá2‹Ášà‰
"Ò¨|•ÆÇwc1KG2•ªÕƒ¡¾9~Lı§Nª§ŒO"	œ;›P­<A,ÿó_îÆoØÀç¹6á°;'M¾‰êTägÈ1woÒÂ/±Ä0Sl¢!Æs»± ´fíè:E{^£AG8šˆğşVÓJo3:Rv°ÕzÎ¾)•ûŠ.€å‚LÿKSÃIXs¶8ÄV„‰‡Şl°
i4€È´à«²éˆ†AŠnd,©‘%Ş¿î.4\”:!\kÛm‘Ö[JÓ!aÚ²‡Óõ¸3"*n¸!|pÓÿ…ĞÕ^¸©Œe™ó†Ş‡ÎÔŠdè†®¨p˜;ê®ŠÎ0ÚW;Õr„Œ€ö¹Ì¥Í/«MÓ§m)»¯v=ûIz)êÒóá_ø?ÑÑ.¨ ‡‚Ík¯äkPšsÖjåRãO•ÄWù.W™¥€Ä©{\åËFxÄwá6Å4[Ğaâ°±ŠëÄN™·¡,€êÄÿŒ~ùàœ÷IºæÙ›0°l®Ô³ëz,g[\ÜQíçS„,Bà;Ô‚úuá¹?´›-W>â¤r$3Ó·ò'>Èn×ç©P‚£DL¦~Z[GœHsà¦Øb•Îm¿÷ÑÑ×Œ4‹ä¦W¹$š²Oş¦öÖ\3(Ü™÷R)+0§áj]+Èqæ©÷(8°"¸mcqFá„ÿ²<I‰ÇèĞŒÚê^˜¿÷·ÿwşür<@æ³ŠD©Ä’ï5@ı \UÉÀ,LÒ(*Nk)ôÔ°G·xT5U¯Ù§QIöã‡m?·YJ<ãxuoz·™—‰÷qÿGÁÚBİí Ä¼)]Ûü""la4ŸT%–l4ëûüÒ™]+=JP3ÕØ$!Æ„wo¨º˜bVÇxãÑEW«0f\bqFœ€GTjÉüHŞL¤®Šİ½ÜÁş[š±©X
:d‘=õRï³¥‘ËçÊÒ‚¹{Š§$o AèyC}PdÉR½kí±®»S»¥}:&õûŸ=»jKW+İƒ	d¯}–AË¸»éß6˜¯ªÂR•úÌŸ"… Ò­råVJÒÚÓÎ~^ùYyuÌLÜûú¹Vz?8'Ñ:Ù/Û¾o™ÊÕ»’(eG>âØ±ã(ØTS«áU
îÏÚæ‚¦ÖùûĞqnwO§Ä‹¦¨:ÖÇ,¼ÆdƒX;-Õæc>ZÇ›¾¹´e‘•h2s´äUé&wz¸o'lğŞ¾A¶gö›ÎlJP•ÂêYöhàş!ô™•æÆJNVgq?û¥§dóó¨Âê¥	7q¯Öw‘¤9ß·Œ‚–&/bÌØŞ¾mÕ1¾|$,/E*²öˆŒ*AíÎ_qmŸ õõùÓíÕ¦| ì,ƒ¯Ë¼µ1[ìïÊL]ƒ°‡ÍC6°>ÂOoNì°ª´½5\ÅMoÂZ2.^¤ªtc™ñÖÖ@¯PÚÌıS4Ö4íó»ÿY%“Vj³–>Dğ^æ•0£°íŸ´±ëÑ›:Æ‹.….À—Ù€.fÉiPìzˆpÙéí‚x‹÷LÂÓ©ç¯|=³Qì{	oŒ‘ŠÆ°ó
½"±Vv·ñ…Õ6¼ÁZa~.N¢{İ‡šÂ'€si33ˆpBOì¨6cÓ~O¸1‹|rå’2«¥ÿw¢¡MTU©íGƒ|	FÎ=î¡( ˆ¡p¥ŒgaØ¨W—¢ çsdî#œ÷‡N÷Ó@èáŞ}ıf±g±Ú| ¨³Œşå™ÎÃ¡•`Ù+³¸`õTeA6c>z6¦à¦9\3‰*	((­«Ş@×ìÕçcúü§£Åù–%iŸÇÄˆ^€§!¤¿ğ½tKñ¦‘¸è<›yŒ¿¶©«î¢€^C×é Ã‚ëÍQj8ÛFjäbY<ƒÆup’‚m¶Q6óŞ	¿¦ÄĞhZÎ@S¤=Ç>Á ¥Z	#ğN½B¡]”;Ç`£õÜ{/Ç.XEŠ³·XsY İhöj4ÖRşÄ$•ªÖïâ©zğ¼N™¿LŠ4tÂîbÄí:!Á
È?ë,ãgbMv À·bÓ+K£õ}˜S¢!Ñ£h0ÃY¬<£^\:a®~(ô>hÖ3#@Î{Åbì3Öå"sùÕÄƒœÒµ.²§KĞêËÅÑ-¼«ld¡+–î “´L7Ì`Ñ=OäyE «×¢¨ZÏ¯×’ŠdÕ‰0ŒÔ“ıŸã“/o+J‹ÔWÚ	ŞZ3¸İ‘7<:„)_]3µEW¹|}Œ¿íô¦åÒ±ôóğvQ‘ù£Uûş`ŸRçÅ$Œ$GG»Ö¸°çğ’Ó·;Îéîr2ˆêLÓ‡ËÉ!Øt{båíÍÄdM§"˜ø[´„I—T ¨ûªÖ?Ë®Â„½èÊˆ¦¸âÿZ)·2K¯-ñÁò†ÿŠÃ væH¿ "J$‰´}V¸øx^X£ŸÃ—fêÃï“¯í–Ç©	vÂıkŞœ9­$Ğ_Ác=+:ßÏWÍ@`axä&§ëÅ•ÌŞÑÈLßeB ›¶îLù3A²¨ÛY!¦6üH nÍ0vÓºÄñâèõx¸h/6½€˜‘Ïïçğ
ÎƒÕ¨çı–übhÇ›ƒ;3äL¬òĞ7Ñ£w	v9‚/˜ç§Aü#Kë‰ÓÙ”e_g&ìx’ÀAş*[YÃM;¥L0-¡\6Í5—l Weïø~İd¹Â†£tÀ¤QZ8Š4~ê%ª={d–+w½§3”Òí5oáiÔúÂïÇ%ë•+‡†cÑzQÖƒd¼éıÏ")uìHX÷'Š	“Ù%Oºƒ‘¤Ï»iTúWU÷¥M¨.?Al4X«\É`÷}¡>[j?
VµíÉŸ¤åšà¸ş~Ö;SëL©°yÁFÁˆòu—0m˜(öøèÿ`å¦Çcâ¡9Ã¨Pl¥oô²u™D´üÍU2bÊ=[ÔC2ƒ›TâQ.‚’¼İò¬|umÔCä±Ô*ßgåŒ]‘øğÏ§¡ğæÙctWñyÈhXëCoÍø<C’¬DĞu¢ü@ğA‡® íQ¹aˆ%¼w=ğ“‘ÒÜ#h/Jí6ä8ÕFÌè?GïÆ$©²
é»³Î„æKéŠz+IUûà´2¤¥Š«yùW¹ÚşÁÍâQ6ŠïÉYhÊ&ço%ã´oÀXåƒ°ÕÃn:rQr.I‰³?‰Z_´E„­Rå¢œµOÔİ×¡™Ó?ºOÏêW´<p,{…ØÓze1ûA2¦ğ¢ÀÂù‡Œ£usÅq2–ê×ÿ²ëøì¾;KK¼xw®SÜtpMxg'×âPşDHÔ DØ%úÁCd},Õbä°ïoÿK(;’Ò0A§Í©9*R-~Áq•>¹&Õã>ˆø±©Ñ¼Z­xZòJ€<SÊ/•ãÑc‘¹Å¯Ëàl‘XŞeB¤©¼ÿÍ¼í±9±;G:‘öà¾çÄ £´ææË3B¯y—kÒ8éÙ°™4GawA¯q½†P!k…š½‹-šâÈ¾-{?µé-Ğì´}# o·ÿ¾QxUo=ÃÎ¿púJé|Çëî6d²äû°W«·]"Î4¡Wè¶?˜ØôœØXaUrZE«€LTÉz*d_£.€Çà±k*§~<#îËwJøZ.nõg5Ä@Ißlàõ¦å«Ì0M­êĞ0¸¼l”È„ô‰wÏ½Sf“LF7'sãÒÈ‹ïW‰}Sz+Z­1{×¸0.á»½s7£=Œd$¥ Á‹¡ióÙÑıµ®ßãëCñµ_ÕÃ›É°aï 0ìtÓ)¥¦¼)#Ú:æº%k›øÖpá©©<h¸£rƒÆã{a<İOUD“RáBÅÁ1&h_Ë!sXb9İ±6™DÚ­•¢»‡5:¦JÖşâzYÈ ÄNĞ©¾=PÎè¥‘¼®şÿ‘†APf=RúAyh´Ê3ƒãû&¸òL ­H@d*Ü~˜’°‰a-9îõ“Õy£ÅŞô/p¤™òÃ3LGN2×N£~–	m i›Úin¢a„¹YÆiûŒIÏö¹cÌıX6€Ğ¾0çOøZE)×Ø§Ğ4`—zÖ!ÓµÙ†úVÎåö¶U"”H.‚Ü´SÊ.(HerV¢Ase«Î™ © DG¼ªe jc×ë?Rxú·Gk#Ü})/zrf¡iEïß(ÒNÜ˜¦Ÿ‰z5oĞÿÇ[CUh†ğE&Úâ¡•²*ìı„jÒQŒ	JX¡»‚X±³ÜEåQibps. ÿ½õwgÁõÖ”§ÆOh„.Z]UÃS3>I¼¨‚?´™Cö\›!^»3úå]M+rHMÏæâüS<!ÏÚ¥',7!©MlşJ©âü |N=5‡õ­$àLoÌ÷8ƒ‚ Àˆ-Ùï–ÓÑÚ{H
6Ğ±ÀïÈ÷40tÿAÇïÍMİ÷VYÇ$•¸µôœÍƒè•Şİ5¦=êë¨9åù\‚á¹Oãäß"rVl§Ä(WĞ¼LÁ ûÁÉàMÀ¾U"éñÒ‘´6s‡¯yrvîŸ-±“70Ä4ªììÙ~û¢]'jXÙıŒÎö}¯En&"ƒ5c‘¨51÷ícN§Ú°‰
P6N(J5áÃs=‡Qµ9«œÖsz4$&Ä¯"\]Ï½éHp<•Ô’m…sbĞX?±{Ÿ–ç¹[İHví6™ ¡l…Ÿ&Çbæ‰]æ‘ş¶P uhB €`î^äDŒ¹<oÃál0Ì²ŠU›îò:¬§}¤ı/H‹PT¶Ñš¼b™KÚ,F&a’rxä^Å2qgq;å*³{q}¶³IÎVí†Öÿth„Î€×œ
¤,Iù4¨©)ßZ›P“A1
?Xj81›Pk HÜ!Y“,s ‡·@b¿ó~Æ"o\%
Œ“µÙÚ[Ê6g˜ï!FÓg¿Ú²DèÅGƒ‘G‰,tZéF€Ì&¶ì~û&¿TˆQr¶Aúj»jò»£„–
Ä¢2Ç:QÕÕVzİÉeÒDôƒÄ=G7š–_˜õ9Ù@.E
\÷èÀcgü­ÎºĞT OZEz©®mHÊx#PvM/+…O]¼œ;³'øªAYvøšdBİmJC|ÄqdM²Í¡Q¹dâLPÌåóCâãV„=Z‚èñ—6¸#HP¢ùº…HÅšÔqfBşF%dÎQ`Êb^•µâÿÂ‚rnëÄÁzpüÇZõLNŒŞrbÒ–(Wà4J{Q|ÊVúø
—JŸÒëVÄÃ/ìèlKW†Ó"J"|^¸ÓdvÂŸ@iûXcgËËë(°L½zº€.R¸¾–R!ztüª$oÙô/¸|!€© “" eãCP·šyü=´›zØ¶}Çg–ÆeTÊ[IüË5cš\ê£‡ç×t å#d¡jÓ0Œ²Ãb¨8pQ—Ä8¿¤× t£ë.#?ñ·P½9
¸ß®ÿwOeÑ
ru5‹¡ë˜·€ šx·ñ)°–¿ûäæ¶Ò"ÑNá¿:RÃçHnŞ†ÄÍLF÷êÛxìıªIU¸/õçS3êb%:ê°F€uĞØ0h„PèUÕ<oÙÖ8e§–+‚Tì:šÙ‘*¦ğìF`?î°Èœ…@û-?:¦ ñıb¯OŞ 8âÑÑÍ·Ú7¬ÄYR‡ï–&ğ	€é9{ªö!y—ù_­cjã€˜P
º§v(]cUì ÔÅ_éÚõ°G¤“à¦ˆı‰sr5q1IÙØğÖ’©Är•Ûp¾•×[¶©­ígOŠtk™0×Œù« äèL²BÃÂ÷nuVb—û†Šcò½©~>‰ı±¿r#@ØÎ/	KÛš<CÛW!±‹­*ëuªL%êÆY~Öfè—İÖ4Å€óOvD¼rY’‚l„ˆs²VöŒš#gôOşÈ|2ÈM›’„Ÿnc@„¥³ƒÕÅm”m®l€Vûš6Bu—©ÛnÑ<aù<CoN«ÆÙZ)Æ0öVÀLO¹¶æ€<ÉcX}’Â·¥\dG³¢=º=³gƒR¢ªÑ±±çóiÊğßÜÚ&d9àBŒº†OI5ºëô†©ô; %—KÊt»*rí0ªÂª§çÚ±f:¬ Vøøìü©Ş«ne°@¸Ã¿Pù;n1 ¦¿\¿Åkí›c'1™h:‘Ä*“XÃ=óÄwÛUñû°^ ØÖƒ `ÀeZŒ·O 9¨$ë İX”ø~|iÕM´:;9ÁĞI}š¸ª†‰Ùä]èz—§²R<íÔ^÷ıD¸z>}Oö)Üä&á¹ 
uœ&ˆrK‹PQen—>¡)ÛÚUş"$’™ôrİ=«ïƒ8H—"ùƒd°[ŠNıÇ¨Îêº£cÃû<E¬ ‡|b‘\zq.Ó¸´À÷Œºº3!`ì2ûß‡s4]F)%šs!£} õE$ŸÓ¤#g’.è)´kNãX~iMŠ·ï);~xHV]ñ,}·V"_|İ†cî-q±£c˜åT0ÇÊ_.*€¿Õ!RƒÂĞ Å’Åç¯Qhwˆ¶R›9Äù«³_fí†|®Û…%gßd/ôäØ,ş‚˜ï"šVÚl¾,0öÅõjaQ|ƒ—ß2÷‡tYe5FÃ}œ±•GŸXirŒAèƒ¥ÆÍq3¾pÀX7l¯³Ğ‹éC]¥y:7çÒ¢àc`9Ã£$bÒß“¡Ë§oÒfÕÅo*pC„v Ğ‘&¸!ûi’›ØX$ága„„\[aõ">¢D2ªEò>Çç¶N-UöKõ³®í,”=u§¯ûÄ	áq¢:,‡”„ëö³¬™á¦Sv[ÿvì@Ï“ÈR[Ü9ìY!p[Äº$GL)šÏM«lr\Ì¿¾ïœG…É6‚ïvv;¦:àßŸ¨“¤íƒ"D©ôÿ‚(zl…›‹¬’í$Ö‡	÷%üRV§àV¶ÃÍ8“f b¹!	¾±¿#<%CØôímĞ¦Gënv’„Lòní4B‰Qõ°YR™c—XğzË{o˜šß½4æ—EŞùî«'?Q<"âÊ*Ïõ>dÈ6ïÖW¾<·³Ó|5‚\Oky-¢¢¹Õ^ÔoQµDºéÈ|`Û'[âoõßµ =Š¿› 7ã}¸å43È€Çğd†½ ¢!›,ûÁ;|BÉo[›Ú„mcGSîn{úW€¨g"ååfKÄÊ¹¼Qè„RYiªØu®¹V‘mõÀ·ùSÛÓõ”¥Ñ^ş³{4(‘dË–:6oI:Åßëñ•[=G¸XÅE–ó‘‹ıçë1o9`]Ïıxã±¥q;A©¢&ÄtÎ¿íÌ/âP”“poeáÎp\éXŞø$Ó¨T/<Hª¼;|lè¨ÀV‘è!UjnÍHÜh;úÉ_Ä{8ÑjŞ•´‰*oÏº£¡¦ƒ“óàĞİpÉß)áèïzÄÇèÚ6à‹˜íÏİ|‘ ­xl>±*óı¾ËN˜ šc?ªÂO£—¿µĞ ³iôÌÄÁŠİû¡Rì¾Ì¯FİÙGäİ…ÆR¶jXUœŠğÆK×Iá5"oÈÃuT­ñ„I§İİ…ØAİùáŒQ«¤÷®,O‡8@PãÉşC·²ß›5©@x{*µJ Œ‰[ ø~mÀğëb	CİÔ¸hæj—ò~‘f{İ]ô•¢q"W@—–ôn’éaô¦7…š6V1Hoşk%Mˆ—^¯ûf,;¿#>lz˜´÷í+&H(´™Z?ğ;
^´ûøUó#XiNô™³¿uä&¾œr-Åûs<F–5×±ş³|¢«À%'„ì
ìŸLc£n†˜çòGeĞh¶hr•¤=<&}x×ñÿ<Å×ñŸb·˜»oÁ¼ğ¢¬{SıJhL—®º]ò7"	MW¨I.Å«7C˜rë)‹î—€9Iúeßœäj•Æªo+İúñP'”üsñ^ŸËêÔ¡u-¸Î”HîMm^ºnî€|%Š£‹Àıp•‰@(^HHfŠ Îa@Æz1ÙIueoa}¢€k‰«‰ü“.Åò«äÑ5£l“Úì¶½[OêóŒÏ®Ì3…á~ğ¦7Èİ!§„(U¯†”½>ó;R¼jc©­£ÜH~ó$Ïúè±›„¸ú,<ÜËÚ$5n¥†[oi‘‹­Ã¨\éL‹õ>¦<›ÂÅ¼¥ê•şö÷©^³0)º—I	ƒÖ‰éT\Õ“º»½_`áÃNJ§ïˆo5¦æœÖ”šŒ×ÖxŸ&G¯Êh0¿ûñÓÜ¦œ¦2š¦ ù7&ù ”Y‹½^Jé-uÎOó;„2JiRëß!ï`uÛÅºÅò6áõ–L] Vulò¤jà°X ¶‚nÚıÚ!¸¶‹.f©
µë˜-®ª
yŸ¢›ä©[¤”ëvÙ8wÅ%Î6ıµ4#Xú«Ñ]×y;F§ÃñçÖ÷ èPFÄRØÀõ[¹»Mq,éû¦-ô×³ØÄ*9KÙŠ˜®Ô7
Œî/Ñù†LÆ!›…å¾Ôø^/rÏD…«Š¡ öƒWy¯K™ãÓ¶øUÀÇ,ûwüW	W°÷Gó¢BúclşGõËX­>5¼—Æ.|ŠÁÍ•‡&íwô·î¨«üib/ík!İycs… ÕÏ:¯ŠêjkĞg®àŸ&+&üDœÑof!Ğ³‹+Ÿ)ş/|!C.€ItiÔ Î¶+S¾dµ€¼¦sp&.ÅÖÀBê˜¹2ŒÁÈÙÈ¹êìw¥g)=XÄœ$XeoÔe#îğãBÓ/u±./dş¿>}P$]-¹Rm³U	çëcè¬Ú~kNQş…K»ø`!AU½K]}Äp‡æp]<å.oU×‚K%AX	®Ç&?³T€nrãü5½•æ'Ë¢$§®ód?ŸÖGŸ}€`¾Ù÷¤?Ñ<ÀÏÀ#SP‡@Œê¶Jr‡<<:%¶u±¡‡e’S&O—;ğ%Ò«äøx=#)Êçn¢ÇİD		ã/¹ÎxîmLı"•¦‹L6‹ØñÏÙœ~ÌH>¼r=U¾ÄµÒìA¼@½Æ;ÓÔW?;lÇ:Ú6>£30aß„5ø€èG{]Œ¹ÎÁ@k§?(Í\Lº‰¼û;œ6NË®©•éñn0Y±é…5’F˜I…ğV‡&<yèú(v•´‹›<PzN¦ƒ™Eúoêpİg¶­O%ñŒ8ÇâD¢(“~DCfîˆ2¼(HKi°¤?3¬-Î½¨ğ4âM˜•±½+^JumºÊ‚_QyÀÈİ­Í'emÇII,VIDàC+c²ú¨›cÁ³¤‹’¤ÊË˜ÒÀ•ş®üÅÕÜ$CdğéD+Çä›‘¥¯S„±Í¶…gVÀö{LÍZô²o–‚Wñàmik£k
ÉXQzjÒİŞ6ô……òÅŸ´Œ¦XÕ…½µ¶TÓë™iNÏ‰nOEa·Aãb»ú¿tÛ¾MÁ{×Z{×I¤§ÑråOÄM±*(ëñğŠÂ´Q+Ñø¸t¹’{ÁæçvKV¤H®ßRK½3ÜµŸR–7ğÙİRd’¶Ê‚yJ|ì°øíï¥6n(¾î ¥’dÙÉ;®p€ì´Œl?¹]íboşF¨—_õ[Ú† ï—tNPï¿ NÆ5òîóÏøTkÑy4»÷@tI“Â§ÆJjíHH}ùEBˆ,è;oŒ4¦xö!µHbkÙêÚ_ xÙeğ¤Ã)¡e.ğs|°<Il4LYâå‹ÿ
vùIà	eMŞJÒz	”‚µ`à}m&1û~/æl@’ç@Dÿv†å2ÇóäØ†¨¶¡ş1å\8µCdó0ÕŠk£8ËÚËÈG uWb&ÀÄ9VÄQ­"|2’€”!±¨r]úk!˜½4ÏİÁédş_{3ŸÎ¢9ô‹LJ±páıöR:¿A?Ğk)ÚZZf’P;K3 Š%öãDd“»šìÛÓB;"Ò‹X±òıŒ*!è{*Ş¬»6Jo²‚ŸÒOÑ0 L3“F\¹ôò…ØZÓU@I³'Œui6Î=zÍ3ià$UèK˜ÂNtá†¸úÎÑ^-şO´[±J[ÍN›|›[ Êr6·‚ÅšKİĞ@¡qù¢y!4ØÒ^õ¡Û	-r‡¥"Php<3BBöÓ:\óAV‚qÁP§s˜‰dÈõ=æzoZ¬x;O1Ï‚[µM@ø|ì>,HbujwØØª9z¢I-LÅ)éYcoÄ”ÄG„HÒîƒgNóÔøbˆûØ~UOÚÅ0î£jÙ$ˆ>o À`ÕRw[Š6ø—9ƒ¡—%iG˜•­}©§ä³ş¬—ôZÓ¤Š÷ì—èÎë8Ù·«fáøÂİ	ú­]nêŒPL†:¼zî`·ĞúFIŠ/İõª ŸDº ¡'ö«ÂväRhĞ'),o^Vá38=ñ¯Ôÿï¯©´GÙdMÆ(R6N$L^¹¸!™!‚÷ÀÌqIyÆ¿¢6‚°w÷%
{Z÷ÿ{·j I ¥DA	¦¢
?ÑŞ=\Çoï¬pL´å½ï¯°K‡$ğ3¢€ÔßİdC¨”ñ§´~	»ádö¯få| –EñBÿOCKGğ§v®N\bØ¤N‚>¯·w´­÷aC•a×_=‘È·RÓËmJ<£ÿ×»XH•B ÁK¨È^Õ"¡¢ÖësÈ®¾à¨7ı¤º„È)¥ÃrK’<>ş›>‹=Ù“†¯Îß« .óq»º«w@èš—æÔãÖ¬9+Y'KV¬+AãaÚææ?€	$ÁâS‚óèg 2A¨0'p³’‚b»«·¼ñ$’åË&ÄäÓÙ`f%=÷3á‚k‚kü(»¤ÃyET‰”‡¡š<µ¨ªXg–ä¶Äk^7Ü@š†—.YCpmx‚W_DÒ‡ğ0"Zgz;'mºÒğçÉÅ¾)‡‡¦OÇ¬ÂÌ`ßÍşJÛ`óœPk)ù²ŸĞ4â‡ª³ªlk°ÿ„O²jïşX,„áI÷_¦×vS¸ô©
?)+ôÈÒÿ°%]áÓ·¢ËCŠû«OˆÀ^48ãhi"´ùÖ*¥àÉºUÔCŞyjzº²y¾ ¸K€ÛdoéyŠ4İ‰sBt‰@ø	<…ÔÅ^€Í)ğòèoó‚ÿfØª­N)ä–.n-ÎÁ/Ş¶tt³pŞ›[*}%èÓJz	/ÈÆb¯=” T¿uç·Ò¿—›ÙÑ¡D|ÈîŞ@ónn>a›N°Ù3´KB”W1ù‰Dn¦;6‚Ü°Œ˜áÊ™5B¨ßBF¨[aë6ıæy1X™Éû)eìiŞ¢¾ˆÈ“hÇë§#_,ÄÚXFt;õ©£Ê¦dù‰ÇÓ»w}#Vyéêjş(ÿÄÑ@~­„÷;A@ğÎÌË5Q`ò”V«zï1ªv]Bbçnş"%Ÿ:œ¸˜˜—ã üSÅèœOå³½a\{mÉï3BFh°uÊÌF©CÙåäakRëóŠ Y=UßEqY¥³š*Icˆ·şk½@oÜ`¦uñJo'Å5.Ìª|\s:²Ş5WT( Ÿk:º,–ñ»4ñü¸=²vÚ·ó˜BtæˆíâÈíÑ<¾«	Â²°gUt2%^KÇ8e™?÷~_=ëã°ÙEØÓy³‹Y’Rğ'ĞzUrPÑ¢–ÜÆ¯¦ ³cF¨şîyû,CŒ‘”‘ñ¢«îwrt-”ŞDÌM“Ô­5¬+£‘°
ÙKÕGsåÏæ¬A€'µKæuÂìüá\°UYÚ°ĞÚÛîíŒ€¦A‹ù’lšg²$,“‚*	-Ø’t&úlş±N†s£ÁÌ×ë£§x_éÓÅjeœ«Œ ‹÷ÅmlH“¯:’Ş{C‰¿‰GèPx& (ÚèH2-•úüSì|o­-ULlÜ˜Ìrº¾À;Ñ„µJFDæîKâÇy¥±öwÒ%3#Ü»z}/<t§À#ûêÆ!–4¤›»Â†Û:şIª‚v,Qée6®AcÈ•ü¼4úsBÌõ³ÌO†=ˆê?€ùL<"¥:{1)ÊJ¨©DÔx7’ëa.¦;y'Ø$ºkrÈ"ó>«½"Š ¯ê‹^ùË’ÂJA1¶OL4÷NàQĞ–	øxÂd„'î,ñ”v&VÂòÛº§À©Ú| x,nmµv‘‘,Êà|ãí‘™¢‡œ-ÍÀC®ŠU%İ´ê°A´audFãÈ‡”9¹ªgøq,æR™°aÁÌæaö~â¶ÁœÄkØª˜
ü\¦:Ğ§æ|%$º… Œ{!»Áı©¯à6ş$›9õĞ4ÔÅ£XÛëå%héîa<pX^Òu`…™—.ú)/fÊÃ{ücõï·”ı¶|l_0“õ j#V‚èy
šÏ–„òH¾<ğSY‰€ŒæOctô^—aÆL£š_ÁÒ"Ò3F`^0-œûÔ™fY{½¡¤Ô$ã(,ZßŒé_3×õ(±Çgµ¦ªï°f˜)9.©"ü"‡nüÁšm¡Ä1`}Úäø¢	Æ•§t3«.Œ«o°µ‹rWGÍôEXM
Ş)Zq&ÿ½Q¹"¿Ld»v¯‰Û£l¿ê™‘2Rªc¯bP2/>É”ÿ„0Mï×Cª§ñm'„p¥·B%0íî˜÷ú¯Ü¶¬›ß>ôA¦#Ê~Î±¥0—.Ş¶ÙbnÁi£ãµ<'´šÆè¯#=GCÃ=‹á`¶“j/;êOğnä×ÿèçÍ¥µQ«Nìåç¦v¤ÉŒŠkÑDàæ=q÷+ªAÚ„ÉŠpÅYèHßñÈ+}A%¶Êå.úøÌ™ dÂ;áÈb1¨0“g˜+Aøu]Ø’…ôõ‹c®ó½qÀ  øM¾LSŞ»HV?˜PÚ”Ù{/Ø”™ÊN7Î·.Ñqz2§ĞOÎk ¦GÆÛ´Û erŞé0{jGÉ: ¡IGÊ[Ñ¯0´§…¢Š=«Ô•èc­êAó±L!bo ŞÜ‰FÙ“ÄM¯‡ü°›Dã$!Äü0(¾scíıŒAú.æ·83zeí‘¨Iİ~N¥?nİxü3ĞN²cë$HĞÙ×í1üGÃö­ pÄ’…™Ã¨¾¯™óª‘7' T’J@ƒ»
úgÆÕ¨AZJË`%†:ªÊ5¦)—M;°ÑŞ‚ªA¾Î!†ÀÄ'‹v%¯k‘1-mrÒaˆ¹qèŠ•£BĞÕGq¯À¾ºŞÙÎˆ§ZX#LÔR‚ÈÜd)úsÇ»0Ü2üÕ·—qöïDûÿe,hRıK)'~“[3Ÿçå;Ë„x6mÊ*$Í~Ë“Ü_Â€ç?’n˜ÃÏãúØA™_~Ğ&AÿŞıäÙwlŒ¥>æç¤@a¨·—ß%í¨cóğ·m¯ÎN½ëmJ)„Lç‰x%/?%ˆ¸Y
Tã¦U¬]•Íú‚J@Ul@Š[.}Ül…q2Ò5v!Aš(©UáË‘ 2Ÿfv5<F¬×E™Ãú¯n%a¶MÍæ>®góöáÉÎ!Œu˜T¹cîáXõ@‡T1áò ÁĞ|~º:6¥ÊÁ©.™êŸ—x2ò!-­R ŞœıOá_H;$8V/Éºe¸VäíYÔZÑ4cUõœ¤|´’ÓQ ^İDì¶wÖÚ,xw5Œ€÷e 9G” Ç÷¥µ1+Ò¹CÅó§D´ÓİTZéáÙ"}Sèâ(òp–eI?šH’-Ìµ„|ÂnüŠÃzeä«
F®Ğ×roŠ\‰­¨ÿGşİÒ=¬ór25oÀr—·´t§ñAáaØ-æ@ÒÚÿß·š¤O&éÈÄ«RI&1æÜš–ÅHY£öºh¬gË¹[¯Õ9ÆO¬•–¾{SœAõudLøe	ö$§à”›¯øf[´àô[^æŠSpö@·Ï4´òœ½ü¾qšÿ›ÏÓBqÀÙ3º¹Ò[Ç¼Á4°: \áçNBMÒ)¾ÂïT=Çø–'Vp±ènÈÓoş13’ë2VOßŒcNcâyágö<™ìuek<zYVÆˆÀ\yé%ÿàÍ^´`Ô&…™İF­†àğ$÷wDï€#'¦†Î¹¢&Hæ°_›*J¤	pû³Á%Ôn§¤0ë‹¥wt§Š½€]QI{ÅZ%Ÿ4Õş,@J1 x}0Ó´sÜÏˆ÷ :/İ«ùñÅÚ­ şãnP©£±‚K“ğËK2|ÌŞ…“TÁŸøŠ&ÛâíåÀÅ0Åc.™ WÃ‘õ
òã;b@ì¦)ß"ÁºSù"Ó–½ìL*¢ÕF¶ÃÉ·´Ë›f¸%pìı
oSpÙÿïJhMİÏ¶éÀ%ò¨*nD¹¬Q˜áô‹€·çyÎÀg¢,>”ÿÅR‚	U€d;QÃ†jø%?+JU¬ÿ¿RS^†Ëblm:Øx·˜^	é’Şåï€ jĞ–N˜Û¶ĞrSÖelóÊÌòİİ>úÖ|ÑÔM½¶¯$Ôî6¬>\©×$æØoGöXÚ¬5”ÑQ`–øªV	Ğ|67«¶²i¨^’ET‚‡u¶Ò}ÔŠ£ãùÃoZ\3¯)¡ƒP]‡~9ú¨>ß\±ŒŞÏß%ØëUQ1¢„ükR1eÔwÉÌTL—q[X”	DèÇ7¬aSİt•\Á.>Å"K‘¸uS¦M~½9ÅòŸ¢
ˆ)\­*@œs *]ÁZëFxŠN(ğ‹©X¼Î_›"ğ:¾5vEtÁpo>.7*Æ‹#ÅwİãİæM|ji®êO)¬Õôï\Üs<öòS@êÂ=Aò–µëSéÄyàââôQ×DĞR~¥*Úo"ŒdŞQr¨^4t½·Ùó*U8A^îç6\oºSe{76£5¤ªí—øÚÇŒÍcg¿@o·–½ÄLèE
Ç±O©A1Ş‚ü@^¦QÿQ.ªW×¡ÅxW!­5š;-4†÷è”¹:AN[Éfõ‘›fXlÙ9Ú!Vy˜@?^<ü/²’¾55á;õXŸeµØT~/‚ßòZ| è÷$c!äÕÖ×ûÃôœ6­†-á„SõJ*»YamBè–8•ÿÈŠVûé côÃDAÏ¯­oÜ",r,ùĞ°¤q¬ Ò«~÷ê~™Ú‹»š5ÕüË]Ë*úÅ‰ÜÜÍDçÚ¥1‹Ê€Ğ…¥r²sB2c«z¨—E’Ç©Ã§ù¶İğ®ü&[bëåwŸ\ú|-ƒJÓyÑÅg—|Tuw$½·Ø·?È¹d©.ôù…ŒÍeW¿QİLBìX•íÙ»E¼`hsHUÅBTÛ9xÆdx‡Gÿ- ^)–ÈÓæ”»ıNj7û,@»s![xy·R©‚ïVª •q87É'!ªy¿=­•ÁİRŒB\ÂPŒ|ğ4³èç¯dK„äWb!O
NÍ šÛ²‹d	eªÀ<ã½ïåfÌDàÛĞš×ŞæÆœÌ¨©0‡ÛÊ©Ş„Ú-dŸQ‚Ïì•wÿXÒ¿zÇ±ëq¶k×4S¾ŞşŸ³+m
`ŸÚ6»:bæ)gO±ĞNC’-E#üÆxGWµ0WÇğO÷xoæÉœ°˜©Onn>Y?+ˆÜbÍL­ÕøæÂÅeOã
gƒ1"€»:RÏSD^ş"·k[ÓxŸA´ˆÁµ–ë®nw]ä Fílõ’-’3‡¶Ù
j"ì³ĞÔ†x‡¬'gW€9Ò6–İ"{ÏyPkvoüÑ'™£{ &lìOÅo¨$fÀ|’n8mUèÏ{·ÙõÿktÇ¬Í:—9±ë©ŠÔ²¬€¦ûv±„¬a?«¯C”<AôDÚ¡Gi­HÆÈcu5è‚ ¥-²9>ş…0fsbMìƒû|ªû»êTEİşkÖşs]Éi6OZŞSM:ƒéùÌ6Ú4#F“	‘¹ò	élç İ#I%roàÎ4E!Ê|r_š	šÍ«øÌ¶!È–.·ï=uùzï®‰ÚåIÒ²ÔwK‰ŠJãÍâ¿Œv~PÒà(÷’Ë+bPËôÛ¨bl‰˜ûü_b#¡UYÀB~´ãØ&€Nü¿¦ÓÜ®Yt_›¿ûœ)|¿­¡#w×Âˆ²U…á©„1Jj1Ú‰ş”x4lqpW5Ô»6 øÑ+õîTë•[,ĞÃÆ7]¦Hè="¤c`Íò^‹d¼fAs“’ÚO#äÒ;²gïÀAı¹<fSÆ$|^#ò#Õíµ«+•4ÅD!º§1œƒ°4í‡ª
ñ¥ÎaåÍÉ@.ÿ€5`XÓjèÌPo#5LJPĞ¹”ZÉI©Ô+dRŠ`·úïò:…tQ¤:0–ğRà¬t#6ğ"Ó'€•ZßEñRSÑ+8 ÉBùE|xW`mŠø/+…–­šêÄ<`7àIîsËNtÀêNŒw1áİ×UœÏ]¹Å]3À‚>^-_q½()¥1FeÅ×á¸9	f¼òËâ³ü£½@õ"lÂ%ù»dÁç¢Û¦ú¸µ:!ÇÓ É”US\£±¨Uka½ô¦E‚ÌÅ¸ıš•%ß ôÜdODli“{+´Ş™ÆÈæ¸©óŒ…¢Ô/²¶a†›ø‘YÓÉÇ’!ç')
Âƒ‚˜H7ó›}g+ï¹Ç¥§×ÅÜ´V¦I ¼ª’/Z|vJPÚI’áq>ùú€>åÌA–#àÚÈ1K¾†C°Xó0@¾¨—Å“hÿÙÇ1&³2* Ë®¡PªĞHäÂëŸ…H„é..|˜’wv¿SG,Z>­œæ˜øÑÔ	Õóü<÷5ñX·ãç6¾F† LÃŒäxÀAo±º%Ï|gŠ7«E60 rœœ“¬_©•G	hÑ  qnÑ;;W¾\+š÷ÓºÊf¶f^r•DÂq¶MiÇÛ³FŞgì5ë[8ÆŞ"(L©¸À‹Â_{@'ıDveäS½dÀâêõòËM}l€õİ`åÑ‚°LéĞ ­R$¯‘ˆ/RÀ/ô…ÜR)\÷IKÈ’Ø6J,>¦§Bíjàœ+q€ÂiÇœqÇ`Yr‚ÁñS™Î®ãßä±,!¬g ‡Ù\ù)t‚ ÷Şõ4°WTq‘ÔšpìH¦ùæ÷‚Éjî¤!!*¼º*]Ù·õ]ÎH#é´¨`‹ãgì‘çqx =+¯¿>+½ş¾	:éÍR=Äjy½vl–oÆõç³YµÁfB¬lÜß>(í*“ïohÊ ‹˜¥™|äjRæRÚZ¯œ„!¿×k3“£ ‹`‡Ö¦üËFjµh%Èêto,è¨Ü§h©‰M¢Uµ›[…Íÿßùğ“$VÆö‰>QöŸ‚¬C?0TXû—gßäÚ¨5ciéoÛaNÉT®Á—ŠıÔç¿Ä:Î5vŒ÷W„ÈßouF˜÷F_–ÀV±Ã‘€×Ùé#€-ëK*²På¾)wÌõòñ@ZA¹›ke®xAãğ² –eº«Ûè*B}_1ñlè÷E?‘Qµ÷Mü‘Ä:İÄÛ³sğŠR+DûcœğT“Şº©Æ(öq6SÕÉ5Û8hõ¤&L^Ë¥QªÆ­õI;p‡¥5<·BaÊœœi{ Wm	:#iyˆ—l¯åüG¯Ã™”
(âaKS1zƒ{ hÖŸW @)|å[Lµà2IÏóÈÖäàvd2qA’-"dî"V$©}°cQ<€dWëòIiÖÑ£˜kn×E7ˆÇ/;30† F¸íÔBîîÊO ?ò¸_WªÀúÅ 	Cy¥8bŞ_d³ñ§æyÆ„jµ
KËÿAÒRÏÒÆ˜ ¡´ï8R=ÂèásM-Šc…Dj’ïçeå.“üÂ°ûıòæx/
ïÜˆ—ªÃ_Æ¤Ã+R`ƒÌÈÚÉÆ·q½«LÁ3øê£¡ 8m²\e’Hé6	¯Ç‘Y\…$/w¡•}9Î¶k¼‹9·œÆ•]O]û®»Ìœ*šµ8Öll>@·ØØê).P ğ@2
>Üş.‚ˆO8¦=¼3ë/JÈ¿ww–ó³û]LTó«=Ñ:çû-nÙ"=ÏÍ®¶¥ˆS\ø_,÷ó ª—D¯ŒW•b¢ÄìzD'™óP¦ ˜t*oHÖÜ’Hó1”Üz9ªxÂüeÈ†R×ejdUqãÎÕL/ó´ê]\</6êJRÏıêo„RÌò´ÙIl‚O—håIs³,Ë3!V[ºöÏ…?wÈ†š6¯¥ÜÒÊ«j)QFQ%±ô­TñÕ}´ÆxIŒ]?™övJ™Évü]ı‘•WÆf÷O×F ^€M¼Ô¾‰é­$Ü[có46ÕFÃùeè;‡jÑ×À€5ôúfŸå=Íì½q‹£éŒ›§ŒŞ¤·A?ğKÄ1¡àÁøb'Àå”–„ÎT}ë¾Dà•BÌŸÒLHHDê^†œ×¦Gv¿Ú¢£Whõ–nÜàQ&%‰J
Şe…\Q¼f’é^u 	iÀ³"¡í®IE‹¦T@àKuë:WÆ³¼À·¾ü	~\8o<à6ÖéÓ æÏ'üd-A[Ç~A˜X:ÛŒ=Ššh‡4*¥%ÃÛå3õ§óíG ãs&âõãçî+dågNƒyô§òY¸Ñõ‰¾ûœÓXÕDĞ‚–3©#‰Ÿ}Ì­â6İZ¸Z²³íl#œX /»5±ÓØA=è*ä Jš®Fg×cqµ&„»wÎÜ‰œpghCæ"ÖÏJP¥â¨í|\}`M®%ŸBç;KU#X¨Ö°&úµ+GyºZŠLõc¼2çE=¾'Õm³mBÂ¼[i\õ¶ëŸ°âV¹R¯ëOI—^*Í›—_ARÚÚcóL“p€>l²DEPš¦ ØËåMœÀ‚u‚üè®±OîŞ
_À`?zœ¡7n£ŞÎ§öìHÔ¯6í•Ëá¤m„báïÉå”Şİ¼Euù
Ë6+¬¶ù^Nl˜ÆÙÕæ¼`«ò¾|Ü)ÿ•#üwˆ¿3²ÿó§L…#Àß"µ¼ço~Bº!ãñ$:óîõyœ Š 'ÓñÑŒ¼ÁCÖh4ÑÓ3…¾˜R'¦]]²‰Ë»Vw
šŸöH`dNV
8‘û#çq±l%Û–¹Y@l¥tjô¹ ËÃ˜Éq<ÿµ'gÃó¡ln52KG¡éLW©ód•Ê•™e“Qqı&`À~¡àöSÈ×A]×aYÀM?»²\e–çQÓX{Ä¨İm*¥LxÆvâÇæıôÑ¢Ôî–?ˆR½…’·,é6§ÌAòKkğ'’¦•™>(r=L$ë+òÿƒä>ÀŸ­0›Ê/mT;^‚ÄtxXË¢„#Ê²¯ş-ø2õ
À˜sk˜O ‘1Ò·AÒ½¯`ÒÛà¥~¿şrK)šgIÂIb³M“DòÈ«‹}¤Í‹¶nêµA«…DŞÂv°/YU"†Ã‘†9G²M0virµ;Ä‡µe1$òëvM§ş:îq –öaòĞêL%¡­dÜ[½+}	=Å+á!­~½1:_¨RxáC³£è:=Ø:É-‰qéêÍØîc®®‡‡%4‚q‰)\KXäĞdæT6¥ì±ªÖ9‹ç³ê·3Ìºi´·}!Â?hØ{/e3Í´£˜X}ûH7…9|²µqÅŒúÂçY~À®Yñó«ñ•/qâÔ¾eŞJ‰Êı4 ĞØsúÔØ·Â˜¿âÏ¨Ø0ğîKS¶Lñ¿ò5Ë@têmYRP8–µ¸ûÓc¨­¾?é½|[7Ì•¡(ú¶ô³ğ™ĞET:IŒOGÎÛ“ c39ê0t•¨ò8‚‘¿ÆŸÛÈ¹ë¶N£è%’ğ²Õ8SÏ†NwùÚ¤)—UGû#!Ú¸jŸ§‹ï‡fı‚fj£1"¦ŠUÁÒ'„Qd+‘†`NÈ%|.yÔ`–#­ÈÿMd¡¥röûÙ,ˆR†äZj·ü½FÚ=ƒQH™?ñşh–yáÊ¡mŸ‚%h‘ªÛP/JÄ0¹Íè{m{•ğé ¦“,H%ÑM®jD/‚Ÿp??"/Á¿'à²ŸÀèi³å^‹	c
Z†:o8pMÜ•Bß{˜ÊçÃb*…ÌÅ­jDkÒfóÊ×f‰­>£Ì;îØ¶v‰èÿ|(ÊÉE‰)Ûl$š …[ÃIí\Œ ‘ûøÔMQıbNzS hO[¢„ÔP>CJEZ¯û{”×½v?Í¯óüúo¡ ½ä3O¤„ÌjÛîúqa ¸?=Ï¤öÒÒ)UØ€°÷mÑØÃ$À&tF	tEÙVÏïTGSLAz:€».¹	¹CÏ €UÒ¢EÕ
<ÒäÂOwõæØ˜KC¥ÛTƒEäù/Øé ¿sj–PŞa¨¹±í$gVøIWTj9¢|‘Ò`¥š™{§Â7Â>\]˜Ö$^LÀQ÷­ÄC“K ^-20GxÁŸüJ›³ëUØ¯¡mTVåç“ıˆŠ–·¨”
9‘:Ğ>…(îÜ+‡¤| EŠüyË¤Úñ”5ËLY»n	#hOO9Æ¹°´ìåwè´:‹¢L¥Ø&o¦;R¥ªëÌlYch»Şº~Ûa #G}Å'“f{Ñ|¼7Ë_04‹ô’ß›c½¶Q±j`&™¶6bI-ØÜŒIóDé€eîGŒErÙò‡hÃÓæ€ÓŞ¢ò‹vb[H9ß@õŸ
=¯ı.Ñ9HVÍæ ±7¼bgiBËáÂ7™uÎ ¥û€	qtá‚–^“Â©uœHóï¨˜£iÍdAÄÃªKsœIèÄú6£ğ²mv‰€.qä®M6áÛá×ì.H|7îë"q÷¢¥+: 'µmæZr0ÒM Ê»GØH}±íGï¨7—yâ«¾ª5³ŸJõ`[·ÈdB¬†½_)L”¯Ù¨Z¶«z¥Oõ½ñO»6U¾>~²-õ÷W.ı†kDóyî›ICz®°{”ãƒ:Y—@yØWÅJ™ÚÄQ•g¬š$Ë/·cfÚ’Ïƒã|¹ó”WyBd±0º7=9Tåqjx£TÃ`ŠÁ"ôª˜/+`U€+¾“ôÏıßr
j˜¸W—ƒ Ér²–u º:·!‚ª¼?<ö»7ñØ{|ÑÅzW+
¬óñí FœÍÁ7Åê(&™ñ«Š|ãÃñİ4ÕZ¼Bx¨³Äy±Â^^³(K~4Y"ë3§ò$ ,õ(äo¶9bË”6Xj6Ê2´@Ş¯øb ¡O}BÙ"ÚÀ3¸\ç2€şÊšsGÛ-Z»ŞÙl%­‰{º÷ãÛ’0{µ÷Ïyé˜Ìº*}zô5­„¶¸¬	" Ö´=ÃCFm1€|Ú˜“8L.ãC™ª?/ëD<m.¿öÿÏÕˆSşş½Zú8™Ÿ[-ß”çÜ?Û´›áSTu?bä»õ¯ôà^:ëF+ÓåŞ,Nyk&-Îr=[gºD}mğ±ş[lÔÅ÷RíåV‡¯ám.Ù( “nÙ3¥-‰œA[‹â>‰)Û„
et‚j—=•xõ˜î>s£^!ñD“YÆ"òGsƒGÿt¡=œƒokÚ¯_úçË.¾%îz¦¹ı"…d$%Ñ$C•&‡)Øx!Ú¹ †ÉC+j˜‡ğ5¬S¶òÑØ–Ï«Ú¼•{NhA²dòÁšc{5%iÁo&QPÎèÇ	»FJ)êÅ7!v…ûxoûÇ™Òæ8õ‰¦yÖç÷‡6%(Ö9¡ŠƒQ€â¬­Íùrâ^â‹()ÎdQ|ï¾üûÙ·	ùP‘xÒbøfÍxˆDğ«E8>ğÒ;ğomÁVûİ(\ÙáÄætbcì·5À}½ÿÅ,,å0í6ŒâP=ògÜÉV¸Ï1™Zmô¶¹»P¤4'#Œ,ÆşDÛ7ÿ†<CñØS¾í0Å^`½®F>g³±¾©ÆË©=N¾˜GĞôtS„ˆÈŸ5Pés[¢»ş-÷ô2‚µ¹i«ÅB˜•¡ÕtãœSÜö	ğíé7@Ø—ŸæŒPƒˆë…ì…­EN²ŸÂ ü0ÎE	®kfÅĞ=O¥Ü‹ãEan¿8ø>M0l0wIÁLÊOŒçô,äç¢³7…©$y*Ïğˆ®¸ŸGÊ/=lü¸:MŞ±}°3Éì¤J,£Üò«Ó¾Âlö-óvâK¼X •®¿ƒÙhÿdÅŒ[è;€$Ò-N•¶óYxéı¤) µÂó,·Ó>Ö7¿ ¾ŠÜ7´³§×İ8à ¦ŒÇ§ÿ¦dÍ)½ÔçÚ_Í¼×İĞT#)°çŸÕcTá´öÎt?óıTTËJ-‰ôrxÉu¢ğEâÔ;½U¹|Ç/«®øw;‰‹÷{~Ëg6VHE’İêY²¢Š‹Ä:CéI„ğô»¡Ó}ÃÙôhŞİñåûT—Á”f'áÂ–ùD°ÅÈâóÁÁ*NË…¿&›ÖÎ7’Æ ¼¥2_2Şñ³ºˆ" ¿™âã$‰¹ğ`úH/Cå5='¿µy^c¶äD~Quëµ‡¥„ş²s€â«tc¥÷\’’OW)ÎØËø‡ª N†T)â½F§3òl¨¶·‹­5»‘?© ÃSsn±[²™g¶"r«-±:xèq?Æ]f<Úì¯ÌU*vy†ó\	u’/ë`àÆZÜà×RãmlKZ[¶zqİ”Ú¥ËÌ~ú¨’p/¸=96IfdE§…Õ»~H–€ÎÇòèÆ+ƒ‚¦Ù‡ô	jô)Î]È Ö±OñJ‚Õ{G´WŠl´è‚–r«,èÀ)œœ‚|ö`Ä¢îîw}m)yªQŸ1†%y¾¶ë$kî„M1Çõ[½“ÉÚ&¯íâiç
†„n¥Ş+^
|ËGj9zÆ3V/iÇ"¢È4&x
3_^‘üšu(ñòne¤Po¤ 3Êwé4²14/æåû˜àµÏŒY¬‡tuƒzy~øü[Š’……uS*a—ëôQ.Â¿¯“«KÛP«Gœ4'Ğ/,óÄ»ªo¬6Ò{ş[Kíå<‘èGlUYóB7änyï­ú÷VCJ¨”hœşMK¬ÊQÑ¢¾$Ñ0{dï‡Âµóıı/.±Nßh¼öI°Z	ÚRüÌÆ >/óY!¾ĞÜk}øO¡sú Xô>&d£g»Î =Áööuë³€˜ç80]˜ÏéI+Ğ¡[Ï#Æñ_SLšìl¸aûS!tD4ı3KÂâ»fXô&ò‚“ÚDÅl±ì¾ÛS>›?U ¨Ğ¥˜(À2ù.ìì†{Nİˆ|Ş¥[d?vÈi–ivçhä¬i{—i.ASk/W†@Ò£,pB[D+ŒBŞk±?ˆè”…÷{&v!Ò`ö§/VìE&ÿxLÈÃºÒ¶Á#š¤`É‰2Ò¦R *V.ìÇö8Ÿ[ZüAP1ß™Í~@ïxV\ÎQXM$LUö%Ùı#ê1•˜{x¢>uÂÑã=Pë,¤ÆÃÑĞŠ®(E HğîöPîHµlôƒbl„A+ğÂRti¸dÈWô±í¢›É-2ïñäñN^• JÌydõmÌ«áH)†Qû©Ó–_E,ÖO5¶–=E’qüH°‡î‚`šŒ½dÿ/ÃòÆÎ½;Cc”@àTï£¬9£Yd¡í]Îi}1ÖøÿŠ­V'´‰¡HûJ“²ÇÊêÍÈ„ôH§GbL¯ÁŒ¢!ïKşİ†ÕËf:–­0wÜ{{©™¡c¥ÿvKŒu£·s}· ²©Ãjfè s¸iß×aRÊmŠ;ãúPâòxµ‚¢ê^4,mÚ´PAmP™³ÎÓúòî·Ò¼sÑwXNï|íê°Ú1jŠªfØì7#iÈÓv¢~]¼ˆãe;@-ÍÒéÇ£NòŞµ“şæ9ƒ;­&'İöiø$…o×QGœ”Ã4YĞ¸Î Ò„òÛ7ñmÈjì|îf³‚âß–,sİR/ótçG‡¸Áp†¬S›”4x„‡,0¨Wú†g# «z1ñ·|S^«?ŸóLÆw—óå$Nk)¾5HOÄ»Y´ÆBºmîÅu0wn;è™ÖE(Xo”ˆù(‹æVªä7
IÙzYN	^ÿ'ã{Á¥Æ³^K5æ´ÑéT³nÀ®û<¨µØ‡‚>Ã>ı-íãÉ¾"Â— ûÃG¶ÔÔÂ­—>µÿ¢ÜHl*•áS¨Œp¨XX‘‚ööèßKíUÍÄ˜ˆÇVêó¦|ººŞÀè)i&Öz][ğã•ú)±AP—|#öÁRˆdæšç—i®ä7a¨€²²î×|22ÈŞ4}LwƒõÚqËì“Á ÷ŸëšÊøsÆ¦í'ÖŸB:¦jQ'zpVÿ‘ğéèd·ú§úØ0'ŠP?èÜ%wTĞô@é¥A01YdkëÉœÁ&wÊaş=‹Ö-å´*>CP}‚å~TÔ]ÅD…Zbƒä~˜;@Ì¼€oKÌ¸ü®%Y”êŞ}Å	‹a¥[g“ûéıĞgvÑ¬liv×10™=ƒ¾Â–r}dOf*Åêš Ç1i?¬Ìˆ?kĞ.8S;&	A;fKÌ iôê+ÅÇf À³€À¥†Í‰±Ägû    YZ