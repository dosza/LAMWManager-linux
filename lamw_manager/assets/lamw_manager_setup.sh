#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1095628638"
MD5="9850975466dc7c40a10b5686fad49b34"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22920"
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
	echo Date of packaging: Tue Jul 27 04:28:11 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿYG] ¼}•À1Dd]‡Á›PætİFĞ²´@¡/ı²ÈÄy\c^IDóoÏ˜eHñJnójj]°³s¡,˜d„¦Ôm—¨á™xKİşŞUº¤À«
Hó1~èØSYl¿£Y;uÒ¦MÆDü’ÚØñóa#E•ò_¿8ÑvZBã-#-1ÁCi>¢ Yµœë0‘í}IËA$\U0¤GŸĞ=Ša#¨Ë{Í†”ösğĞd©qPÙ$ÃÏÏq‚çğ™ó¨³èwFÉ_BV‡†|‘lCªí3™c€
ì=Üƒ“E$3«x°Oœ¸b´½Ù¹Z{[8lœdØÈáV@š<¼¢¾7c)z¡«YjªCÖ‚´Üş½Õ)uÿ)Œ.\|C×n?Íë.ò¼¼ˆ0j¹TµÖg¡:ñÏb"¹Š¨]òe‡¸TtÙêV[¿OüÊ0S“Y' ®š4‹†í%-¥$£†p.Š7;û¿äô¨NöŸ‹w"å«lÏ]<YØ›Z’=\·õÊÌu®'¸‚¤¸S2ÊQj§(pƒGC<=€{|©NlM;ı) ãfä¸Û†…³E —é¦Öè4¦6OùO‰™±ƒ–XMYJ)ûó^³ñAĞ8ó>»RÌ8Æœú¤ª6{1ê*š49ŠÍ–î"¬Ô´^ë#™‚¥s°{e--0şkBV@zlî£aõÊœUø÷„2ƒsÃ »Å?õØwBaäaÑ
mš¼eØå¶èömGK»:g?Ì©½~ÿ(Ú–˜ÔåXÜcM¹î%$’DˆF›‰}•­záaV¶»şf¥³¡ØÅbŠù–{ø©É}îedCú\Şò[öv¸†"
Ùúàs´İ·3ÕÄ,_°~`	<çP7K{^‹g·C—ºÉñ®£˜—Ÿ“œ¶k—Õö küJ\ĞÊûÜŸ!2ÙˆtÇbìßx¿ ²¿š(9vªÌÂİu–q¤WóûyÅâcÑQö^ÃtÌ¢’a8,§·gşLP4$–gÎ€§*ÔÕ}İ) Öc^ë)YD>WNugXÖ³ïÿ[ŞOˆ”ÂàâåŞØ«UÀ:Ó‰{Y=ô’ëe÷.ÿ2dÈ<&è	X “–×T²îŞì¤BS“ŞŸİğ¥Ê®îãÂ—Í?Ef'+ŒM¯Ğ7Í¢Ç,$;´Õ6±zA¸³qdI4&zİ
¾Àø×R@*5š¼P.}"ÄçEú¦1Å¸X_Nb;Åf3¨r‹¢ÚËfêœ¿ Ş	KÒÇ½\é-qNäå%3oótS§\x_¾Î£a¢ŠÖ“'¿AÔéÇLI	lJ«I˜C:8¼økªuÉx>l€üh„KUÜS?>›»cÂiƒKÀß)¦ª†XŠ1å0íLŸ3ä±âĞİŸUEb.]L|p ‹vA9áDµÂ¹€,vouóı-g¼N ô³XàFiJCÎbĞÈ{|€Ğ :ºÄÎB/;3qV=…4çÓ5©·»"¥j01Çlá•ŒMğÓ·¯w@×»m®‰™3£Õîú[©ëéHĞˆ ®ğ’*‡Íó¸÷JT8oe.xM\{9$j£† 1ø í’Uî<>ÒC÷jr”m4»ˆ¯›2ã~Ee+N&à˜Kz©'PeUô}/8ø7l	7eh¼D¶D#€=ı“áw—Oìj/Ó‘a½±z‚&®oLÄUC9—€f«dİüTYü¡ß€™ôÒ“¤c°•M™ĞÀ¯ú‘Óƒå”\˜¾Ç^æSÛ;/ÓÚuËÛi/u£…	™!>2îë”óªHSİêşg} ¨wNŠèèÈ«±‚¾áĞ—¶*Ç,¦]³$.tÒøìp}HVF!Ãâ!VœZ£¾¯+(í3”’h)ÕÎÃÍW÷ĞbNÉè¤íN`›]Úº˜û®/“¢Ä¥¤(;ÿ‰ú‹{áÚëÓ%Ÿé lºÅPÚ¯š¦‰}ÿİP’Ü¤,İ…ß™«wÃ¹	R7ıÓk¦ğ7ùÂÙl ¤ìÕ·Ø³„9U%›={aìÛ˜-k^Ø1ÁšÕÜ©yxÚTU­£š"9Y`ûHSŒ5öŞfO`\Ô•ÔŠ I¡f‚‹6ecÛ°:qtL‹ñ¨Œ½EŠ„ñ-ÀÿõO§yåcÈ"·Ÿ÷¼‹S{ùĞ¯ÄlèÉï£šºè•Iîä*²ßÎ,ÿ¹ënKC^å}ôFÊKÃ|ÀW2®İZ‡e.‹¤•é{­ZyKXp‹G:Ô-Ç¸%~â“¡‹YîĞ-qÓNŞušPøA9°î¬?UCƒuuÿÁJGFŒy»rd Èo7 ÙHóFÙ áuHÿÆ† ƒ?àÉªE,Ü^GIÿ»V'‘3ÌÙ–.g¾†.
ÑÿØ>´ŠáĞXu-P¼ËÈ‚¡õV]e”L{Ê’±;ñ?ıx5b~DÒo–IOÈuö¢‡ôjf¥ö…}¢tşÈoÄ ›¿,ÿ«Õ!ÌºÜ¦„ÒLÚW-àâ!ıvæKHc§¯®3sõrëœA¾ò ğÏÂ…­}I+ÈĞĞNå;âäæÁ‰)¡¤œoå$°º¨„"µeAËÄd<WĞ‘à¤OôÔ6¿PêHXÈ¦¹W;¸Ñ2J 6¸åóñ¥Œ»º-ªÇ{`ƒ± ßK6BAÔ¾÷Í‚ÚŸKÀ,wšÜÅp’±Qà";juÿy£“#Ë ,œx‹5ÅÌÄÊ8b4Î‘~n¤ ¾`ĞËŒÔ´nAÍœ¼Lı:vÚq]vŸ²£…‰téOÁÊz•ÅÏ<ªÉ¥g12!Aı>—¯YÍyzñ–ø8ßK¢Á‚Zv˜şQîX˜Û§¢Ú1•(ÿ1§•g%oÖ·üj‰…ER¬TW0Ü®!låímIMÀ¾„hœo½‘Àèfå¿ño‡D:§6Ä=3ƒ	n¼$¬%e´g>¡;8•ÍN§6t´‘ÏM ŠäH)Æq–åıÄN½×)DkÆÿ)…m&\à±øMİÚÍ|Ê.sı±$ßÎ3p«G-¢9g¼,‚P¤p—±šµßGÂ<Q*ô„“prQÖ>^~ê÷ÍÀknk0	™}çéhÛo°°V8éöı¡0bâã3KnißÔ_îŸ¢oF‹ïd[öfı5/gÃ):¦•€*ÂQ*XKQ¤¤_gHhÇZ»Ÿ~Š‡åó+ü	t2Wî/÷3ŠÈÛûİZg
»[O³³Z­†cJ³ôŸ³,á6İ?Òw5v52în”z bY>µç÷QáûÓ/®äª¯·Ôïê‚Ì2Çä³~‹©@Â®à”¢Yó®Ãf—ë)­¸JM!Ğı˜_–éA°¼ëÃ¾Æ^T¸MÈ<!³Æ—åªLÓUCÚ@OPÔÆ.‰Ÿ÷€åsEÓı À³õş]n4iW–…˜•Vº“Ÿáçóÿî.Œöy9ŠFö'kUâòC½¬\ã>·v6‡E„µş4û38/«œ:QÓU»U5êäÔFòqÎÊ§u ªiû>U\Íñsr»ñ'hVŠŸøK‘z¦)i&g Ccgç-ª7lı2ÓL÷#÷ß™›.t"ë–×‚ Vİ*|ŸV¡`Y·Ïh_yµ9x–9 #~ÌŒÏì¦©¡s Ÿ´¾ûg°¾²]#òÀúû¤rtŒÄÍ9ú¥'±DÛcäI×ƒÆ¢ã ÓÀÇ£'»úFù±Xlèo¦tƒ^²ßğàhfR°e·B—wì>™Zß%%‰–
&Ä!ÁVşÇ”¾…”Hî_º‘'ĞX¯”ä\IøMrQvVßO„M¨€øŸ‚É¢P;«ùHÍ»Ñ‘D##Ïrİ·S‘WØ©wÉSLôv±ğrCR,I¯ƒ‹Èû=»>æt©¢<ûç>P°8rãºëÇİ³±ÒÔ!Äš{M°T-rg Óì`™İ0œõ—y6¦ç¤¡£³@ß„z¶£^Ö&¥/SÈ"®2À²È‘çmèMé^@Éòo/A4i¦×—K|­èQ‚ˆ‚SÅæÒ8o‚Jüßzïl€¼vW(Í*Xš%áù”IÁ?hM.lsé<ó^˜+É*c dOTEè}I¨òFøß4¯´– Ü 9‹ôà"B§fuBiÂRÂÆÏ¿şRh)ªXèš¦ıô?z\¦¸v×»õ%¸Í&4`ÛÓù°Qaë³ØÈ9
K½2rTFxkihè#›hVUĞSa¶áá¦ÍRS$úæL§KÏûØKS^Í	‹µS<`½˜p?Á<*²ÚÒæaşÀl¹ßçëƒ‡UW—ñ…™Û¥€Ç€¶ABó+‚üKïLkåM¯¢-ò#­«³­äõó à$ZÖPë,4ô9lYúÿ}?İü"y”²MAmíj.,Ø
bFÅFĞúõVAˆëv¶‡“Ú L·¢ê8Åÿ¼Z½éT”OöMîÎÙ÷=-!
x4›ë!šš§×.J\‘UôıÉ}¹i)âêH§D£"Jz©o{GŞ@Œ]Ã>ü5N]MD}îDÃ’›hÌòÄú—Çq3ÌÚxêqÍ7§KâFÉÊE<Wİp‘ŠtóbRNX~a{ğm.©ı;ŒÛöGJæŠf>9í#”*47ráø®bŠû”òĞœ:æ$ÒZÓ*¹AÀ¢(SoFÓ-‚ß)…ìÊ.ıªıÃìM®XßŠ=N
;LŒv¨ŞàZkv²™äÄì0Ea"Âñ¨P{ÁğÉu.ú¿`ËXvBÙŞà‘³|—ª´€ ì¶­6ANíQ¡™¤Ş˜ĞËög©p%+à´ÈN/|íj»'>,:Õu@nùwUg;2«‚Åò­º×…3g¹X›¾şıT.:›/kUv‚µ»£•ÍØ{.·T€¢µÌ"énÔl$é¼Ûëª¢´“™Ó6”q“ 3êòì÷¯?·î+YÔj<˜	µL‹C1j,Ÿ€ş÷\nÀ´(†ı#×¨	¯îºªˆÿd¼Ök¸Òë‰-D`X×ˆUœ½¢º9«j5V<ÿÀ¦S£İş{“6©A™:^¸ìkÓWéº&¯
Î Z|öDBÔj7J3Ü?&dƒ+D&PÉ—%yGŞ›kyj‘F|&|¯“ŸV!2^ÈÇs0ƒVıÍ/XŸÁŠæ®’±±Ñ^ì2`EõŒ8°y€*=ù@;Å¾3ÒY–3·å¤w«¸æY¿ÍK<)ª¦sç\õ¿&íj­|ÛÊ“hóÆ×/}–m”P9GÇ^€…I“ q´\¸G€$© ‹¶öÒr¡Í~»ïMˆM™f½MÛ¦bE¶J9{‘îë]Ì'»”s’}´[ šá“ôù§ÜV-tFLBğßøoÀ— ¦“™ôîHÜ&vvmÖ".A¶¡PãâIÁg­ %©eñïÉàW&œ›¤ïàéÖ^ëHëtåjĞfÆşÕ / `×îzb§Í.õTüaE‘K¸Âví$—e(‘÷ˆO”'xi€’>#w Ï÷@±Ë}E^ƒl©O°ç+Y™cëšà<Ö6Ï›îQ?Ô
¾˜V©‘eÓÅr<Ç%Îep€å6]Vö¹ßöôğ LKç?' ®9Ô†Ô&¶†—Ûi6A×(o+ä)emvMBÚ©ÃİZñ‡„é Ÿ‹õOñQ’É®ôÅ)¯ÕÃàÒä(÷(fJWÑn@—ŠiŞŸÚ<ñìz>ğ[ß4XCQ3îA7í`öcÜ(-Ó F‹Cáã¸šÁ(:ÛäôèE8—›¬`[I‹a¾}ÃsvËö*] Á¥ë%Ò1O¹?(®òåx(›P—hØ¤6ÓĞ‘èŸïDÊ¹0k¹¤ô@¤×O¼I¬–×Ï	
õYNš®ª8Íı`ğsÎâ˜úä›òÔ#´Ôÿ.í5\ºÑN·C‚fÈ~™MõÛ£lÜ¢c|!Uf<54•‡RTp¯bRÁš˜´f|<o§|L]ÀMŞ°@£Ö¤'˜MD¶üiÕ¢nG¨nji1e¤Å0! şúk»ûEF§´·’mí`¢œßÀ#ìpTAÅ|HTtc û/¡E(óÏYy0O|ïMøµ§XÒs¡±ú–;ÄQDè^M uS,õØ“Åÿ±Z•T"³lA«ïufg„BÍõq¿¹YQîseôNËú¦…¨Ğ€œV9Y+vQx$I@´gßmen—X¢Ÿ[¿˜®²À¼*©4µ‰ŸÂÇi¤wXĞŠ[ö'²ßĞ“D>ÛIÊ)Ï6q›D‹´ª~›ìß—0¢âÀ/‡7½èÆûpV³o¡ÕO+Îa†¶(í:ŒYyx\¤}(KÒsê´OĞ‡´«êñ<”>"¿j§kŒ
¿Kïö1`Z‡Y	»ˆŒ]Õ®
ı¥7Ñ½é>SòÂfÑÕ—i÷ïxÑ¦Šé·œÀcĞ1lwR_êúÌéuvĞy`‹"ÕÃ'/{Dpîğ­dƒ¶Í;_·zlaî7ìşÅÃ.h‹j“Ç>ª÷ï‘¶üuİ©7.·ZR	ÉTq°2Ï†ëGn!•ä ÷ĞÛ»ï 6!Šw¶o7'ıñİw‚ö§¶¶ReU„ƒ¹ºÈ}÷7{å=1RUìNzh˜HaGÖÆpÂˆqş ¡ö(ÍªÔhè©äîÛı!™Ÿ©¾î©GœƒŞù®ñúªc‘ÖzbIàÕg„ñÈ¨Ñ°˜ÌA˜Ì#vVW>B‰ò*Î1’{Ö˜-”©Ÿ3+ò¾­Ñ»Ñû…|ïBT«·³bŸğuÇÖ†Ú‹Ù{›k™´¿¯g2ıàôÓ“åHŸDH/)|é’Bñ–åNè$³‚ÓÕIx¥Î@„\v¥¶5E ;h«ßa’H? Ø¡’Q}>ói}8=8ÈHÔÓ®=ÂŸÆãÈ3ÿ«„â|ËÂæT¬mÔ.³x¯®û§V×¼"	.‡ş–ñîËîJáŠ‡¡&¦‘^³#äuÚ$Nˆ€Ş0YyK´şÊau'Æ=*–DòÉê¡J9«ÎgK
‹õ´k]Ë2?9$6\	¹üå‰…€g
-±O"Ÿ¶?bI½B¸NˆoÏËm+´
İ17õD<°[×¦X³né°ÁÓøâÿ$W”47¢…+(ï¹;½]Fxà“ƒ,‹§aY·š5ç³*¢g­ˆgÛV’½+,¼ÃöuÄá‘Êø	/Ø•¸yÒÉÁB`Ğ)0H.ÅM€zkâ•(d¢pQ¬+È¨èâüøzNl(T*“}0Ü×Š]°˜èüå'D+˜¥ğZhW}‹¯·0!v@•¡ÂÏjÜÜg;Hp³ûçÈo+å,¿å€1(ÓJşqX=á?†hVÕ«êoU˜!Ó…Yd²Í;WÃ4ÂùËÀhê2`¯Z[éEŠ€s¢A®”á$ƒÎ; “ÿ|aò~Ôš•ı°â)«n7†µÉ®ûğjæPÆÈ1¿ı4clà*’ıÒúX¸bª¥Ç‚Òwahğ#ëä@¿$İèCØÔ´›^=Ìä!ÈÚuxß†û0!ä {’Ü¼…õ&²â×9²ù¹¦:"İ†¨VÈøûîºÔ ~È/éÿ†m2ª6ŒÏÂg·‹hp³ÛÖ<ÄõíØ|tÌ<rìa”|cë°©7rº¹P¿!)Ø˜Ü¬`9yâD´”P®ú	#ƒÍÊpÂz‡bù+-@Õà•–sŸ‘¬’›³Ü?
š»ØÖZWmU&rM¢Ò™òM,ƒ ÂcK½Çéd’¥–)şi ó ÃPëˆfà9š{cÙ~¨çcL¤à®_20}Áápí ®–T¾§'Òâ
`ÿU›cP*±U¾uU‘)_”Ş¥O¥É=—´÷ƒ–Ìƒ5Úm^ä¢Cr]+ÌÃhWZt¼Ø£Ã²†›_sÂÁşP¤É¢Ñ.¿ÌàpK‰ĞQ¥Ğ`ùvæ¼#ˆé·³7Â‹×	ûÛTv€µøÍE[xÃ/'õ>%¼ıÙù=}(«6ËfÊ{ Dş¾„ûQIz4Ì¡³’»yoªâO:%îƒrSeÃna‡Û‡ÇµI¡™ÌıG_s
¬˜ÿ¼@‹+³‘)u´I´qïŸ„HØeÔp‚û„/#sµêom!o˜m:p[4”$?t.Q‹¨êó‚x÷yŸp?ÚĞIaïÿf•}ÔÄ ~Spizs´à²¬<Ì0")Ñù_„ıÕí…\;å”•‰{MŞ+òsÎ]ÜÓ‰+9]u°äzÜêä’YøÔµ£Ÿæ±İä4¤ÏK:fësƒ !ş.ÉJj$ö¦ˆĞ1%ğß£}æ³WfÈF<ìƒ˜Ë '×¡£øĞ¥p0—¬õÅ®RLSsğ(2Ç9Å'û>¶I!Ñ°±¬ï9ğgfï‹5ªƒ 	’P€:õfÅ¶+=]¡"Ïá2QäÁLFMĞbHtW 	õåW£G?a³6\‘tÙ\ã4!<Æš
'¶`Jø˜Z.1Bl‡ïtoqMœHb>ò(sêÂ§ôŒeòğ^œÑ["<Øs6SÙÒúÖ=2ü†²r»8%ÊYlŒl“^—¨¥|ŒdªÜê¬ÈŠHÊ¡cÖ=ÑZçŞÂGÖÜ÷[,ı½bæoæë§Esğt½¨È½c¦à‚.lŒı‡%RB¸r˜-hßÀ‹Åµ²¡Ğ&‚hYã EçW+Œ6¢şÍ>&h¿tzÑ*RÏ?är76{vó•¦ÑMV´¸Ñ
H§‡ÅI&
w‚ Sp£8Fc·–æ)*eü¹Ûë#?ÉÖ^d1éÚ§ı/ÂéİÑÎjyTÖŒÀ8IÁB£ˆ¥êOG6 %{ÀhEXç¦v<¿{}lGZÜ1îÕã¾^9=Çn·ëÊ8+“ˆkOú2òãŠ‰
Ş+Õêº*t¸ÑúøµmF½ƒé ƒÊ^ÜÈYh(ıî0Ÿxı+V+kÎ2€ÿ=É_C+ØĞûZæèœÄÔÜ“;CvLs*3ğèİdGÆãQÀ€ÈPbİ4SE³=‰Ó,¾]SI˜}´µÃ€*Y6m{lƒi7<VŠoä©ØÓ»Æ´“1àf¤¯NÀ±«„>ØóUm®ÉÃ†æ³2œbXä©øßÿe#×¸œ½œxÇLÓ}²İuRÔ×{qü#ˆ…W8ÌyGÂU/ø)ãº7X³]`ñ`m=ÇûœdYÙÑWõy§ç”ÂÉQ/öq%*¼˜%Ó³qÌÅ†`ÙQŒQô8£¤›Q	Èz–çÈ„ „oP·'ÒLí1uh^¦ô“9Ê”ğërğCbª®˜3¸›‘^p³±?D¡ü³øí1d W.y®ë>›€“u«é0ÒâÖR‡Cƒ="AüB?Bn“Šæì&­¢ŠÔ"S6¿+Ü4Q7Äa7ÑUµW¸³éÁ
¯ó­«Bø¢(EÉO2ñÛá=«MW	ÔÑ“b-›pê-Œ1ß¼Qu×b (Èÿ@I´06F¢Jùujf„n¸‚÷rJ_ôº-Îù^ógÒ±İÔ1U¤°]ŸØ~w‘§«©¡yÆIçænC˜ÊZƒÚ¨¾ÔbqòÏ½)O}˜_SL[Î$ÁdÌlëWÙUÉ0¯ÿÆ©ÂŞF‚û®á6Á°\ØVˆÎME¢Y _§Ë6Äi¤ªH{_ÊL7ËWğÈ‹ö»ÆQÅ›B–n>Ìm§§Æ9vö·¶†()m×ÚZq\£ìÓÊÀuII‹/¿¦—ú¼°ªOo2TÍ‹ÔİÃçîvš’\4äÛ§]çtCñ¹é>b§ O~¬NqŒhø]˜Eİ—EL,!n¯½q'hEQĞû5Öû‡aVC¼ïäeçŞÍ}ÙäïÁ_dÏF˜á´–Ê‰]‚zù¤®µ>İœPÇÎ„Ù|Pf›r^áˆXßÍMÍ¡põLô‰’1ıv+YûuZ¯GÆ$'–ú›•“H‚ó‹?°]áé\˜ MáŒ§[­ÉÀ`·õcû\êz·aÕÁBö©tÎBf rä\Pg_	¤½w"¦ÅšøBı£´ÍUŒc%²PÓëéÚ^øæ4ëEjGn¢Wp?Â­í)G^ˆÅ»s×E¶ìàÿ ­m<§m^ÿÌš—êƒ¼ÛDİ÷eK}De'|ÄªÂ DMÛ"Ùê¨&É^G>xÖIŒŞ `’7>(|lå¹ş“DòkyÈÅ„+«àûá…›F~Ÿç.áqŸí'åşã£÷’¦ìŒŸ17İ¡.µò®}ş	Ï P{R¸Á«¶Òn±’„-Öu?ze0’^Ñ »]?fç•!W™!b
l*ïC‰ÊD!7>Â2>ş0ğc./ŸÄÙH—ÚÇòa`Ó=ˆúÉ/ÙdÙ>©èf=@sy«(‚Á¤?)å^TŸ$/{ıC{.§¶ŠUä8«
:#÷óß•œÇ£Ç·	8\§ş·ârc\çTT^?<m3UnMp÷˜gRÂâËdÒC€WÕ@bY([KYh^“3X¼_ã†ùTõkó¬_=Ñ«ooN"·LN!È¼Cæp0v©ö» &¸§°ÜëÑoaH¨©L@ÀÈÛ5ñ›ì¢¢Vµ{•Mƒ›éMrÑíZÙçá'4şÄÜÒÆ3^ê«ˆ¡uqóšŒÓ|ÏLÈÁ†zéŒ½OÔ™Â6"EğÅ^vjû‡ñÜòFq€3á-kü½—GÖw?*=8W3±SÀ¸š¥¬]©ñŒœAmş›$?S«}ösu` Úçfçj¸Ü&ùò,‡]-™(ÎGê>"³—§×€åqÙÒàİ¯{F4;Ûš'æÚÎ†ÙAráÁÌ¢Ô¼¡aäAiìy©…İ"7`ô«ÀD¯…Ic¥ÛÙÍƒ­‚–S@†É³œe|M©á¸Œy%o®Ü´K4 R¸şj)î’I³@9úF£Â])êfŞ#ñG…]Zïœ íNÂùX`Ú_¿Şkƒ©ÈìuJ(úzhÖBå=—µOÏĞ F\$"î6eÉ†7´a‚Ø¬¨ùÓ§k“F©R RD'n'	lCyã-Ÿ*ùÄ´4[ÈÚÍ H¤ <A¶ØÎt¶‹&";ğGAæ)K{=è^—.”CKU}æpÄ·Çiİî›í4ç\9½oFÀîÅ=•î^ !qíÁs!H’ÑL?Ç_¡uâÑ»mo('nv+ª6¡ÈÙ1¿áGÓLoqÆ•gV@y‹Ã{3il€ûñÄjÒ§åÙ=e:
®H€±)6Ù\}™ÜpkïÜ#Nœ;Î|?	İ…oã÷êÒ¾VfZÑÚ"ißF|Aä®ADã}ğå’dş Á0DkW5ßÓñ+>Û*FP}L­L5ï‚e²Û²äÄ},S´Ëı7×s¼Mbc,‰=ë'»³5’“ß"Bxòt­ÌØ6c£×)ÕàŸpÎĞa…5‹J”äJû´$…ñÆ$Rhä<ÎaJ)ğÍ?Ïmª±KÏıGô^stn¸^K%Ézµ1Z£·ÑF_G(J; Tœsí¥Ò@gŞ>e@ÙVğp’>wxĞ#!kˆ0ö{â[gµG1ØÎ Õ!iO»)É¾¨m<b•:/}Yp¡v×.¯›Ë†W¸Ó­À¹¡ˆo5†QÒQhR¢àò§A,ô}€n°Åğ*¸æŠº«=,~˜ÈŞ¢Ï.V„óa…Ğ#;ôŞÏõ·¨);áU„# âeq;Õ‚¸`YTlI"ŸpU<ì¿Lt² R–úë¬™á 0G‡¿¶M˜=õıöô
ÇÈú€Õ€ÏLí˜mÃòbÆÚ®x>¯+6Š³åpz»5Lî*ø–6êeAd²9õ-m«İ.ï?OåÃç2È(R…M|¹_6yÍØ&£¬»Oú~òDıgi.N­¦Le†—šsæpJ{]ñ(…²[pk‰È[Dòçi©%«~°àú¼˜9`ƒ*ÊœZıÔÜk°Gz»Û¢ãëiøiÁöótàîæ’¾Ù­~K«y†+]àñß+dlöUÂÓzİ3\ÈTşÕ•ë'dˆf1ûè'}*¬k}c°
Pm"#d1ëİÅjöşUŸ%¦¼HÿtèÛQAÛ€ÕıÜkÉL‘êFvĞæE¢p$ÉÄ¾ÒrH% ;kµš¯…—o­Í/Õ¯¯ß2¦ZhWãÍ@‘p:!n”øsóÙİs§[†ˆûVs ¿G˜gjæ’€Iğo¡oì
ğ2õT„^b·|;MÅÂ$~“y¥\ëúfUìQ»c´†]c?sş÷§ÖÃµ“:	„£ánNrí¼ÁØŠlĞé) ¡~+¸&Âá©2ÔŠıŒB!İšCŸ{Ù³vhóíŒ9›Uÿ¥Q:=‘réŞêòõâí‰oåWV¤;ªáÅ§·: ]$:…±Çe2%ç1(?î·#çr¤4ÈÍÓó%KÌ‰DÉêsPáT9åó¥mÛÍyµIËäğíÉŒH²x‰¯Îƒ]>Ãçh÷÷O¶kõ)È¹î£gd:)QÈõaIv÷l4¯Öş°{ƒ °`[SsAñ –™–¹í¶›Ş¾SA­è“í	8e½¤×ÃªıxÆ8¤XÇ& 7Ø%V³çú<!ú	Ÿwå$jQ€°c{{u‡á¯Ç8Í.Œ†ÚÊJëçEöû÷pO7e&	b½rÿaíóÏŒ\fÏ»°ª§ËÈşYBq2ÃÁùFÛ¾ ŠÑäWè<A½+"$Ÿœ°cy½p.fyç|4P±77@-úËÿñıw±¦ZÒkÌw>¡è WÊÚ7W•hv‡QA\)ôs¸X„+…—)ŞŸ¸ÓOaËì‘Yikç`*xDŞ#¶KSlW’é/³K¸OóFuØ±W1Ï~KÏ§¿T­@¶Ö]¾Û´p¿›é&…%1À¶œì4$Øh‡o8¯8:ä~¡t“ÈT›Vj§”ç©—À‹Ş*…gğa*<w[9æ:diŒF†ÈQ–GğAı¿FºRõ?ïP£¦Õ«^$|Lˆ`šè¨VLâ'lëLêF-ƒ…®„ô@âBWô<ñüMìk	bºŠøı/ı|µ¤ÂŞà¤¤#—e[¯Ÿnöœ½µ£ÂrE•Íì–b‹…Àô(ìv,LÙ…üQ·LÎw|±$™–sª/¯%dÇŒ]°ŞV$Ú…0@ÑeRÉ«ºÚ‚Lªëöí<kÜwÉÁ±D»Lú~Í•2±zÙSÈ¬£ÌµÑ—jÅ '8µ¥]2í³4©ïŒ}½áRR¯3óşF!~À&¯üf<„Ú‹0”òŠq~æ}?`2DÓ)±s£4CËRøm ‹A6 î&FHC™¬X^e¿şZ}¶(-]³~şO|ãïÈ$ÛÕÍËRœR¯E¡md	¨ìUéxuÁÜc3³=Ş5œåÏ½Ê ÿã/KøZÛÔx¹\>îho4–Ù³-d>Œ
Aï^§Œfa°`»¹Ûc<Ó}Œ+ŠH‰oàˆ0·{…(™b·2sÅğ"¼ã/9zK˜ãpup
óS˜L—	1ØÀ¬•'ñõÀçÃw§åØsŒOÉøö_“@ p#Ct¢,Ò$%ú¼˜ÖŠm%_HÇá]V¹ŒJ5eÔjGæ_"'«HÛdş«Ep@şT¯DD4ÒÌPÊê}Ññc±Ñ?çÛû¿Ô%J–¤º
édßœ±qòÜJÆ„m‚=72šãöıGvÜŒµlãóå{z½ğNŒÁŠU`â¥
–AÿqAÖıp>;Kõ	Ó8ë)¤*‚8İª²úïşàÉÈ°Å\®T‡hÕrT±Ş‰Œš~tèÛd{ÑqT—z±a§Eƒî[,½³yk)áu’…÷SñçƒÇDÿŸOã×ºŒÛÑ3z5pm©•GN¿!ı¶F¼p®×ºØBi6Ô¶çßx	¸LE"5Óæµıáu3‹?†‹S‹í˜ÖYîŸÌW>àô-ì—S´¡Iç0+ö¾3FÿÍ*cVm’ Ü¡ŒY¦ô~€ü–„âîtQøJpÍ?‰hÍßÓNïı¡–îÓ‘u ‡wËf¸»š[ûÄâXa# Q1Ö³jÁ"æÈwà×tjkÎx‘QJ4ÃfhûËÒ¥×èY¶ú™i?Ñÿ¬0ŒWßÏËûk›æ‚ïÀH6c­¶c“}¬Ùô÷ˆ„ô¨·@õóÜ:YMT=A8..‚ì‚À÷âÜ³dÁn'×X²é¨bÒ¶NX†¬$s„Ş‘”öBÒhT{t‡JË×†tš¬PöÍ6nÉ.X$»H”[CÕ¯Ì2’&Zâ£ªŠ%;
LÒhüô“íJ¼][IÃÇµä\Ø¬“òROş ¹ƒ7[6ÿv¥RNKœV(&1úÇ'/K<î£/ÃoEA' •™@CyAéw„½ÇG5’:ı^@ã5 ÙŒWßÌ9tãÑsW‚¾ïœ¸ØN ¡ÓSÚ÷“£î(,i@KÃ&£+¿ËtÜŸæj@6àx7 tŞåt*ÿovúI‚Ï)R¸ôì9¨ÆlO"R$i,ëĞÜĞJÉZ‡ÄyNAØ&Ôfjó–:,¿?$¦V•‘"Â›À—O?§mÎ ‘¾CÊTªÌ 'şº5ôRk˜ç6ã‚ş»f{E7m~ó*òÉ°˜â4'Á56j+ÕÌ9ig…JÅ'o^«”2†¨šƒŞ¹÷ˆ©ö«¥O˜ê7m ÂPyim	`3y»ÿî
?¯õ»[lêÆš:º+?Ğ)Ê€²`ñÀ¥
È‚<Œt<nÄ CÚ•ªÑHtoµ¬tq¿h–†ë#âx"(Åˆ±=ˆ¢?9_a02@kg! plM+øßšqñ@š€c~Å{7Á Ìû‹ŞçoN´u[Ó1(uZ}…FÆ	PÂ\Ğö$ç
K&Ö'gì´ÏZZtêzIÇù¿®†|'kÇU0Zô-,ójŞ=œ°£àÑÂôœñpÊcK‡–îô9ë¶svÛMÈC­Öß!~§ƒ‡Â.çğG”®úÙí¸}§ê\„cáH/±ƒ8õ¹ ş½ùÀKEÙàÿÆ!7Î‘£wiâÉ²)”ôB&&µÒ­ŸŠ#òKÒ&ÌùN”´2¿^oêj{]êƒçDâªğ˜c9»"ğbuÔÆÙÀÖôóôšÕZÃ(åù-9lWM*ÓıÜî	Š~Ş€Îş%xL8aF0 ø÷!=yáÃÄÄJ'mq1È"z‡	6üK#×K°euã¼ˆ1´_õî–İ^Œ»Ÿ]lSó _®	»»eÇô(£VMóh„Úš'¥½ºÓb°º×AE8u:<äix	ã„Yƒ&àù;#/¡>ş§P	Ù´´ïÛ÷0ÿÿ,§ƒO€˜‘ŸuXµ/¨Ê×vN¶kÏ %ÃÜVnÒ0JÁ !š²4Ì"§Uö£î Y=ó£ØöİKÛT'§®´Ì…p?_BTëô±ŒE¾ÄÇ¡œ2Ü›Q :]Ññ‚¥üé
Š:Û¥ØGö-Ã!1§™W}¥5RãÏb„¢Ñ¶Í°§[Æ‡¼Fy…$"æ'L“90/MSîÉâÆÚÔ¬Œñ—Wñ½Š{gç&‡A43N Lß‡|xl{4ŞÉ¸ºÿq«,†høÀtùG×£K²ü+¬@¡„õşL®ñì÷'É¿œ©AåCØQ„h$åıa ?^™¬…ªµgjì~¼H9Z¾–ó°³wZğsô/mQÛå{¢¿Ì”ËVÍ<üŠ6Aµ­¥|ŠõË.üYÄ ï¦£®OiVÌ­ÉÏd"]\Q6¬+x¨¬ë¨÷1I]è­W€s-Øô”vì.f].£Ü!V3ïÅcÁÈ…¯XóÛ0h,ìáƒ'<¸v|ÇÜ¢Z‚/îôÙgYéJ>_e%{JF#cšfß•«"(š(Ü ‘.4ìr¬hU/Éï¦—»ßrG1šI9kcwZc¶Ç#ùSêëEL.]¹¢&—·“ı‡“ÂùGv–wòz"vW|FŸñ"—xt¯"™†fU|äÃ:‚>É†*VÜÍÒ;-æò Ñ‡ø•¢0Ú´â«L|ò‡EguM`±×f X5óÙRò^šûùÉêØ†ŸŠyo¦ï³¾š¢)"¦ÃÒãT#ô\P‡=Tãª#KE·°ymª\fÆ,¿fá¹ç¶-H³İ¢ÿ°ššu
ır&»øş/ƒe"9ĞúŠç¹šVK•ê&ÿ+“î”™#]T øfëºAU›-Â˜P-×;s‰(—óö´@P½şÕeLÕf7´R	€Úœ5¨‚¤ëƒè–§¸kkËöÄê@äÈZ›Tñ˜ƒû™¸ÎõQ³—*áqk˜ÖŸóA|zÃP!_C±¬Øó¼,^ïÆ£ƒ9fÚö}º—òpÖê¸úå^†HS†:¹4û$$aö'«e[ª²`ò:0†À„•tş£ïä5Ã"`„/ğ‘+yÿšœ1 èŠNí—ÕV#4½vaLfC•kÆDà‹c}ÙLhk¢»x9[÷Ä¥1zÇ´³ŸBÀ.HÁ<x\Íu*ÏBÿ×	äÔ„İliÍ-ğ	*ğr+-æø‰õÆÎ[K½¡ §Ôçàl¤¶.ìÉH—¨6Ôkù„]-C=±À
5AO9>JQdAãâtÉçZ9ûêñ|Pİ·xt‰Ötrş‰
Î©äéŸò?"	Gœ%RÀå/½G#P‚å7¨…ÂeáV÷(á¡ëUâ~@ãÿØYÜ²w¥]ø,ø¶šó|…;y©´ÉÃ3®ÙúëÊ5íÇöB'“+Áv¶\»¤„Á%=ŞÜ,ÅmZ(ü/ÆÌKätÂ¡%É»Fé8I‰¼İŒ‰;²!ª•UãSHÎ$§bF‘vhô}E)T<¥ƒú®!ÔÎ.`ı:ö ‡+ê235º4Z'ö{ZÀa Lİìœ¿å9‡Æ“+sQ˜Á–Æ1 Õ¬"¾Å<lbtª«ˆ†;Â”à½XŞL¸¡5¯_C¾?•!úCÀT/H2Œˆ}Šö‘ÄßŠÑDö‘?Uy©Lj˜TU‰Ê”/‚Ú6²µÚô¤èhr”wAò4ìËlJ«şfi[_a > ó4Â„Òå<@íoS‰=kÓDöŞjë]$Wì]­>=Œ½9†m¢Zbss›ÛP&e¦+m|S(XOåÒìèÉµ r¹WnÓ	H¶íZ¼,‰K±¿¸òQ¸ËtÜˆ^JåÉÀÏNG—YÏ3]tµİ/Hç"ÍË!Qµ-rF$Ï­eÇYÌn:¹ãUXÈÍ/—”y«0DÀ·2è’Ó»"C‹%<ÿÊ­‡B=İ}¼¤*=xPºuuÇÎ|Ó{ÉÒ]º8³ç­NÆUQè·†ˆŸ×s$o ’ÄWãò÷®¦ĞHLç[‚T·]ÈW¯.hØoìbÉW«u·/5¾@öïÊÀ¥Àh`ñ´Æê°…PO}˜‘c•şç‘šÃV°$ÒA*“Cæ=\W|M}1kËŞ38­àoT¹¬^Í-mMV¥iÏ÷¦6¸b~úĞ‚î4û~Ê`ÛTÅ ûëJ½jcYqö†—E“öSjŒÖË§}aCieº¼aı©ÏşÏÛj‚¬Ù„ ÿîãA'A9ã-`¥Ó¸Ğv¢B˜ÛJE˜³Kˆ•èÄŠÏ•lñÔc©Âåéöä†šÑD´Şî"Sd>V®h÷â‹°çoq–·.F–ı8àíüğ¡ù—º·˜[ª!Xj57òK§-éÛ)8`ÌbÊåÑ¹„."ÑÿãPïÈ”J;7ª	­¡×å´L¸KkÖgØx;“‹ 
^AM`~Vkß@TÕj…–6–7-Jg_pVêg±BÎª$Şv„„‘à´*Ë&RøNWL%±S3p~X»¬öFm|=Y—}ºÖ7¬yŞ·ÔÆ½¾6‹Óî£ëï
Ã)ù¬Ğ’i¢õ3Ké7”8Ú(!È(ı³c»-å¹Õ»Ğ¨âç">}Ï×Ù_}[´çX¥Un‰z\
XŒJ¢éjN[½”š“åà£Ê™A,lñ\j¢\Ë‡û’nÉãlUSÕvx×n¡S]êb/ñ¯joIàÒ¥*×ç‚^ØÑª–
ë•ÔdÑ«2tkH*ªö>7Ey8à…Cè|qz~)H‡Rì¯íü"@æ§)Åñ–S…N~oíËk¿è¶í84¬ÊÀ¸°&÷ºD‘•>ziM*Z
¢¡
.ÓÕ@Q3ŸqÒ¡cßÎ©ätÃ³•NØ
«ÓÇ¥Æñù›¾)W^.p¡€û[ë§2ÄJ¸lÅ èe¡`iSì PIJà0ıf1J–ıñ¿Íü!á$”û"Ü)ë¦¬¬¥qIEÁŞ+ã#XöêĞ²Ú‘†ßƒ~º*1©™™¡ ìqß~"gh1ÌÛúzÉB,¤e$ñ8÷ƒŒ«Ïƒ*ùõx1¹5õ _[¤'Ju‹—Êª~yNÃÇ°E*ïK€¾OÏ- Ré–‰ĞJî3âM‚{,6S@€ÕãøMr*ê'íçå
izW#’{öÕ­Ì Ò›gju6Zg­u÷–ˆ|`&Ã3{·>%~:ÍÜ‡sİOÂ“ªJn]+×Œ…ˆM˜e;óeÆ‘SËÄc6ÃX !õ–å•È)Äç¨%‡)ç1rÖòè±ÄĞÎ¶ÁCfÇM"Òë"o¬*¤0==×·ÆQ°Ñù©p˜Àgy «
øØ”ÕÀıæãöG|aºAÃWMÂÓ~¦Ë%èÑƒ¨‹L•#q,xØ$ƒ'Dˆ±Â²JuO^áÖ¼-Î"ñ9˜®˜ºY»ÑŸàn RìN“ñÅÙ¥Ø›¾u\Ğz‰ÎktQã}î‘zö±NŠ ‘a)†6§QğsÂTÒ›r‡_çK§²¬ñOMƒ³•šcªÑÄ1üZnŸÕŸJAZ£È¯°¡…À¼YÀ`óîa½³fåô]unÍc"B=¹£}ÚÄÕ7çB«#}Ş.u3vÆ'Óğ¸º9§ÑÆ'dŸ£”hbdM	Q`|4A;ß¶Üçà&•=4ÆArt”ÇºŞ0Ô&xED¥6Wä€ƒT·påY>Ø|s´1¯3ùuï³ĞßPîÛ£!GIÉìæÁğe["6‰1ûÎP¬ºšM!±§IJjê¯òœo\ø[Eğ"å<Jvnà”X»ĞÓıÿ§dœ«p¶hdÈ<•&gEÙùVìôv.–‘5›»K¿fra·9FcG³X‘ÇÇÌp	¦üL&*€'ô’ÍK+0ÀÓ7LhUÅ›™<\9 0]"âÆQ:6µ”›–ƒ˜Øk7ÁcFÓ[rV5¹2Ç\1mH/Gıõ»ÃqŸ9@bø?7A–àCõ¬ñ×ˆîRš¨öX‡o¢å×«2Mã´Ešº\Ş¡>´2Ô:—úÅ¿'^eûÀÿ“|DÇÁMr~`Ì}´¤*Ì«,e¡V%ö:ÕŠ8!1š‡>ºÎ¡³B“4½66Ş©D–âH§.§1kr¡îÎg³|`˜Rß§*8÷OS´ş_$Fş·/!Õ·™f™¥^ÄÌÊS7Ê‰‡óšãNøWË,H‹uÍlpÕÙĞ†÷ËV¾ƒf¼9J'P\Å]Òx^ÙèFà~ë“=g•¾i’œÂµÏ»*UàòI©Îƒ/8¨é	œ;’;!É*ÙrÀşÕÉ{®Ô(Â‘y„fŸ]`ûxL3ô>áÖ´”Tİõ@Ñî@–ï~º¬»#b3¸ç`å1Î)WÃÏ©FqÕ×L2ò½×õÏÉ÷§úéÆ’D9“°°0Ãı¹ÜªX}à¶Lrã'¶ğøı¯RçO´¦<ªû v^ò¯Ñ¿Åâª$L4Á«ÄĞH½,ıˆ$Ï\émÿ0yA5†ä9TDÀ™%uĞ,sËåí44§iUµÍ¾8fıĞˆFôrZ8˜›Æ­Ã@B¢ßıQı¬}Wmæ=ÜªØ]fà°6G•Œ†ú{ c¥ç¸µ€;†·-[ry´Â”)XÇlÁ{z°j³FîÚ¶2ø7ò6–cÆá•´oEâl<°à~\NªÈ×tjÔO!Œ ‰ûVÊ¬ ¨>˜ ä‘.'“")º8 €„şú—‘¤ğì
qmäÔq<u!f]º¶qfBáÎÜZ°ª/  (»ô|K˜iŒhŒ–ÕóÿòìO05&ø~4îç–Œs4°`á¥ŒS¯’zg9J¹~¸!ÁÂ\¯oYà|Vx5´ÊÊ·ó"eïCŸP“:ı©(XuïD„„o.ê.£6PAĞ²%KS`–ß‹hğ?Ë«ş°DÓTfñä×^%Éàxè=+a˜€ƒKDÕ§¯%zâö¨ÜÃyÃşr‹¦Ô¼›ŞaÜï ¬H’NsW‚lòYÆBjXŸrnŞ3Ÿ	zBfĞŠ0›9ûf3Qüñ“¸¢ÒmIÑ4,Ö.ìùŒãèq¯‚A¢ ×„sknë*¨§¾42–ğUM[TõjC_Å ­ıbC”_PŒWş¨µÿê¥ºˆó.rª—â<ÿ;˜í¾ş¤­£o„df†hÛ9\®`ÏÛôÇ
ÛóÅ–—(¿d*V5]s]Ğ|„zµeò‡•	¯ºGbù„Urüfî÷Å;Å¿³}Ädğş9ÚCcwdf×ç™å~%Àö?nÑævïjî3‡QÚRÊ¿1ãİªvkÅCgDéñ?¢õ3cĞZ™7#'ú}TØ	œÕmT&ji1¥5ø-Å”=â›<ÿ|Öiú­÷8áÜúå˜·ÀÓm)ÉZNêDƒÂõ^nLó#>@ÀW¬D]‚\R–»Œ(Ö²wµØÇ¥‚¤ùÙ76fw†ş1ı=€ÅP¶Èöà	Kj]–L¯©HÃíÅc5°š6*~øûc\dW¥ÛÄÛ à…­Ğ ÿ¼n$Ç‘d î5?¾üì|Ë…µÅËšøÍjhöDøàˆf ½Œëar)#“ÂCÌï½6™›=°·ò]_µÂùe	C¸ùĞ—
<Fº	ŠSoõ©Îh:Bnxt)óNÑ÷µÁ¡^÷|ğ »T¡O‹¬pò£˜×$¼ı™ù†9ÁLJtE7‰z
F- :2=ş'—Œ†İŞ‚wÛª¾ÊC	ÃiOÙ1?I¬Ïág4“CÀc‘éë„F¤ƒ;YA×W,£@É’}JÎ/µˆà²@AÓ‘fşÀãwÍ‰'íñkˆ5À–³³JK*œ¢ F¼MÕ*XÂÉK?rDæŒq×œIÓ£:ìGw¹Ñ
Öái7Vy.È„JÔ–ŠrùÊ¶£Öİğ	æï6xºJnºWŠÄÂŠ„ÊÇşÑ"ÿoŒ–sKûC_Ÿ€¶¹^õ~3ÀQ{s“ §B¼°ó‰‘åÒœşî-ëV11#dQ‚Ìlõ\
Ô(9>øÅš;çLìÅÁî¾gíXş1û·räh¼„?™pe0ƒl+Òˆ8T!~şªà>}õ
sõßÀDD&±›6²/‰]Ä¬5ëE‚é*XÙ×6¸hƒá
KJú47eC9˜ƒö%Ro-%@„ĞW Ê“+k ™YLxŸb#îÖà€£•PÈÛou›Lú˜BõÄ”]£Y@æè´O€xáËÃË=o›§2{¸p<îø›3±İb\ÌWf‰¯ÓµË¸u}¥;áhø£Î`à@Z˜GòODí³Œ-bÅ(2`mØ!ÃUNöRi}¸`ÀÊ0@PL²¤”Õe2«Ï²d•t·¯±«õØŸßº"ÆjE[Z ”ÜW´L9Œ¨‰}B·™x]ÚËîÉ­ĞnöøÀIÑŸñ×ĞÄl”‰†½Ivúùº€ÛJ¹Z0oÓïäZ©ÑÓ˜İóïà&Q µñZj:FÆ—–«ÀÅ‘"DÅØjH¨pJŠ+İ ø`)€İãûDºVO!=şLşes²ªÔyrÌZl«€—^6ŒÜúÒ2¢q¨@ÆzĞ¾;¡'¼İ0ìü-ÖûO€Ğ<v$˜XğU(×øl Ù}ˆ‘F’+µˆ"æÚJ]‡OJd{IY_Úc¶şè¡uDëöª²‹(½àãsr¢¦ Í‡7¡dTI.<apš‰V/81n`-Iû¢}'â>Cd¦9³^,Œç<ünÎ°i•>x¢“”æjÅ%s»Ã‰ ºÔn>”iŞ¤¯Â$¤{§%«†:· µãjôòîÖÒqìÌƒûpÁ¦}r±-ÙöÄ†ÛÒEieÕ=?zh¸µ¬Ÿ¬Ù–í^Q 0KG+´n,•]u­Ÿ„3ìA·øûJômŒ›!GÊÒ-XO³°ÁVœ\P_÷¨:’¤ù8”2M¥2‰ÚÛ,ê–ÈÔ]b-°ÅWm-ùzˆ9ãA2'`V´@9èÓYMßØœ$Y±„Œ×ßm!8'S\¬D'Šíœ!ïc™ß'Í7K
>”f
à¦¼vŒÛ(³kEM 1J}’Úkët(±U|<w¤ªÙßı› eø‚ÌÓ}œ207—F=^ÊTıû³@…M#ZçLÄ¢aü^Czö>'NÜÅ]RÕyIónXâ’Ÿêƒ¯&”ı6“<Sz#I»CJÙ)uµı8L¿=ìİ”h'P)ê\'X•‹æ=ÅŞ° ¸¨ÊÎÒÂ–§grQyYªöÚî¾pÕ…´¶d]|ËIx$)5K>^GÑ#º`É~PÄ²Ú€ş1a¬û˜§rx$]ˆ¤ kø0cÖpÉaØË'Œ¼êúÇ`ìA#òöO«C•ÑM§'òäM*OÚØ—
x)z8­ûSºxˆ˜ä^b™Ue†”÷ú¼£ ¼~g‚Ëšwt§wÉŒ”ÿ¼‹"ß+PÕsc4½âQqk%}Ly«Ú‚jçC1g6§]áX0¶½ÑHnèçšFh¼^Sÿb@¯Œl«QC+qQÿt…“¨à	- Œ`Ôº]†àöÂò?÷É@J³Ö>iÏµÕ,+cEôÇûX¥Uÿ(º¸óõ»¢¬ûw e	!†à­®p‡ÑFÑ­Ó]lGFÄÏwV üœÎŒKYUU…<¸¿v¯µqPÈĞù]@rŸêN#]W6w’eÒêÌGqÄ˜náp^|a5‰¡<.keuáÄ#x°jå“Ãwr9ÉÇéhÛ+ª‚¸(²F[	àt12ÎHƒ$ê¿D>ÚõM_n–ı§ÒÓd¤íR½ùv8‘DçŞ:]
ÿ#üÑ9mwÛ>Õ,P*ƒ“jÎ€¤äí%ÛŸÃ%Ášª³¢Ìçéœ÷b=ú*nh½Ğ ñ•2²R ““qŞeÓ1·¿½7ÅTÌ;·x»çDÑËA¯NˆÅÈ –æ] ·™øjÃİƒxI*t×@OíX´SRà`œãM¹Êsjv`F@°Eõ‹üÎÌe—u™ë.ÜÏåÎşJâ	¯„¢ï’Ö¸iú™qç*QäQ¿˜
´m—‡„Im_–ÉL
RG§<¿ ´ş‹e‹ö-òïMØùe6ŸyVĞÁ>¹¤û*8‘Ë9Ûİé}p_Î>+g²Ä3‡’…İ«Kï7Wc‰Úr"QÆEàËÆ|"4&¿¯*í» Hú•íÜEïÄ^äoWN‹›~ß¶’İÙÒ·Hµ¨§`JŠ•,¶q¾¸,qÄ‘¸Á,LD½‡Ù~\’4œ3õÂ›@¹Ñ	İ~†œmò§ÒèõÍ'§½bºgV‚³b#Ÿ­Uß…‹ŒXŸ0LàhÕ™A#v‡Üâ&RgÂCT[çıAˆzYw`^“¿”†‰ÄA9Ï"ÈıÀ¾ëPCà?Ù^Üë‰¹@eF[–•ÖğŸ~“ÓU…¶SdlÅJPşÖ “	œŞ·öaå#ûáa:oÀvb	ùzM
òHË©Çªk°~©Ğ%CTál‰\
V‰4LhÌŠıë¦—Õ[ƒoÅò–iµEêàÚX‰uüà|ø½÷û˜ìo”ŞP¤ÿY q©O'8
ÚØ*\ïæ #ÄÆvéÇ;Àæœë|-,…{+~ó%úGv0—şVìÑk‚ïá¦“€	|æ6½Íã{{%±4:L—_æ™„¹(VLE“¦­·lGÇîquo´Ue¤9,4HhJ&r½J\hi0Ç¯Ò¡Œ·ß"òRE"Ôó‘iÎãê2¥æM#dß~Û›ã‡Ÿ.[@á±5÷sb–”=)–Úöåp=TFcâ¼¨ó.5FÉhŸtBE]„0Z÷A§’œ	2eÌŸ³I¥£u7“$¬ŠÛXÇuK¦¢§Ub‰@š/i¹Ï'ê²!¬6½IyNÍ‘Ba<´‘±ÑÓÉ”U›St®i{ ¡½)2ejüW»Rô¦_ËB½¸(æ©¡Q”KwVP´CEåNOyÆïÚAc»C¢¿C¢ISfòª”oöP/oä*aA®²ªU¶cİ2®ouFä~œöMêE,ùZ\£îÄxÍeÄÔÃ« ½>Y¤Î7d1G­Sèõ˜)†‰ÆÂë/@b
–>Ã)¯õıæ¢ƒ9ßŒwåS1"fÆf£I'™Ñ~z?$?@HÍsªÏÒä_a8Ã†UêÙÿäë:™_:pö}ñMm:šO¢-$vË×¶Š.{óäQVr9¥QHÛùö
€bD×±ófçˆ½;ÑFõ8L·Î|jéäñàº4_nhı¸_‡‡gÁ‰Ùl9¦ŒÕº†æ"´É•ñsàØÆÇÊqJ`óƒ«ûœiõÆ|\kuƒÕ1®ğöbŠnFAÂæ‹9(Ê–Ivù#k7¡ŒnhĞ\RŠp¹‡Á\“ÙÀÿé†­¥Æ’àáÎ¾6ÚGğ‡TF
tĞ9qîÀ~“Ê „g
ÌœR~ÑK±t?†ŸmcœõR¡ÒC¶¶™ÌÜ>šd§‰QÃnR(“ıòÖmÉµw·êfuÑîco‘ë¢‚.‹  Ö:§xMˆRŞKt¡µË6ñÔO¯®¼)QxÌƒ×ÙO?æóPHä7?¼÷¢L=Ñëu–ã®o™A:œ³Ô[¶âªÀ”;óB‡
}5{mDÛÒ÷q¨¨Ù–ô†wc„·¯üp!yç=ú¬„È9ª‘ÓÁcJ®‡=IIˆ«v¯ôÈ1§óÏ’™“–H'á#9âÁ
»®@l›	{L³0‚^hŞ>>g¢Û2c1Üe°âõ:—“Hw¸ºå*Õ¯Ót!g<°ÃJmlYíjúŸÙ›w¶Ïçç%%,½Nö?©·Ä,~©5ÿ¥ADÚku]È±Œ³R[
§"ãù_ë€î*>â	*³+’_Û€…¾Ò{ÒÇ<,^³ê´ß+^€Ró!ÙÇƒ× ,ølöÈ°ÙóMVÊL*ŸòG1áuŒE˜±^· ˆo½ĞFU°GÉ²ÙDúìñ¡à)dút¢ÀÆU!®™Îpë9SeQ ]Q»a½~C5}øå&DMğ)»&Ìµ¿°‹|(/”o03ß°·2åÖû…ë‚ó²÷—L
=é«Ş„eÊ¡*
sçŒ¤$’‹ÆÊyƒì²5DãÇ ”;˜Tï0ó—m‰E9{´•XD%áöCE¨azwkğà§È1O£Æ¬Ód(?ï š3÷lˆí\ê¯y YÕË€ò‹Rµ·ì<ar¹ã}ÛğEN›|gÖéQ2<ş°¢}Ì‰TıŸ¾n¾&Òs?¾ƒeñÂ¹tñ­Z@Zk@X™™œ·ã3ıDìkÇyíüÑÕ¼ˆƒÆÑâåeÀVúÁ$¬ï³’EF¬Íe´*tÜİq\N€Ò&£Z‚Æ†=6ôğKbÖQêZüİ¤‘ãeT^õ´B»ûÏ¥/8ˆª(†S¾4±PÂÁÆÌ³u}»6"h
dA'kÀÇ”ŸÙ&@3Kä˜­ĞÖÖ"ĞaïñÁĞı*yF9m‰ŠQÒä.ûP‘Å¿ê•¤ÖÌªlÁ ß‡»ÚßV§x¬–œ}ù¡‡¶ıN±¸JvÊ¹w¤§d¬o]°¤Û¹¿öb:3ŠÉÀÿ?S… (>l©r¼6|X~ú_¢GA‹ÔJŒOÿ(ê2àÇI…³W{pB¦¥Ç3!‚K*ª[åÓrBff‰)Ášµ¥,ĞT³wÃ÷xRC*÷qÕjò'0§šOUñTk¶Áƒğb°Ğ…kÏ:U¯ÈAe Œ¢Z r÷RY¹2ÿTÏ,‡ÓòÒ¡˜g§lŠtZÿJ•òÍküÔûîä8OÁ_Ìc*X+pˆ4±Cmº ¡.¬Æ¯è°7<Ã{",—¤WÄ„C¼(e¥Ÿ¸àb1¹¸ı¦ K‡×$Nš?¿ó İMâ*ñäddLVL€+ñøÛC"•şî}HÍbM“_2ù*t`	êj6‚é^Yæ)Êe?ÙNøB—.Sš¢;ÓÍ+jHD~?f(îg¾#{?Û×ûï†ÒĞÉ²&Õ2Æ,u›¼ŒÇH›#+Aè	+ÀzŠi?>†kŠè{~Ll˜=v
3›ô˜ÙÒ ¯#ÖZ"ÊyüM¬„’!½53†£G™
®è
ëœC`{ä ‰İ/!¥úÇh[+Å‡¥iKwgl_½&ÿ:­ùppF›“Îš¹ÉÂ¿›»jı7£Då2;µ"ÃM·š¶h§ñjâ_aH8vÕhûÆÓq!ŠHÙĞo9Ş}ßÿ1ÜÆşå:êÎ€N %’rAş<QîõÃµ'Fù°¨äMÌÀÙ”î6ˆŸTuÅ„«Q‚‡«]3Õ%¼ê5e¾mgC÷ş~l1PgX©(¡©#Så0+…•kâjA¹qÄ¿¤Nõ³ÓEÇ¡ßKF98şN\òD}ÎSìu‡fv¨3ÔÔsœèÁ”51¦±	\üAv	8Ã KËŸ¾kşü^ÿ{<ÏU¸>òºş.ò6ólj# œh@¦k¡6çöpd3XlÏbİ¿Ğ"æ*xÀÖâÿÇ¨¾p¥<¼YA)QúXé#à ZV@	!¶~u/rÔÚu»4j1¶ô’/’ğTRæ×ëæ
C¢øî œÀ­jl,…*2´0içHÙ´Ò¦áªnj3ŞÛ4
 èŒXıÒŠX¼ÙœÒQÇEjZùÂ¬†L_Ğ—Æg,Æ¿Ø¢/IĞÑ}é_¤y&À5Cí!·¤»&Çìù²)4êıE`Å”=+#>-Ë›'|4§ûf¢÷‚½@¸ÈÍâˆä%‰Ûf|#ëSFœ¶K<¹7ıã÷à·è—TçS0Á«ºËz›}‘’!tØãO˜Ó‹ÕÜ+òØ“xƒ5›x­¹Î±vÑ¿”]İ0ÌDõJ¬0!µDœõ`íí‹Ëi.‚:£ajÔä«ÿc*®Òó¬‚­Õ»íğÏ©(ËñáskÅ­súG—_ï>ƒõãLnĞÔ…ÀUœëèƒÉô@‡CÛFq{	Z3ãˆûöîçh•¥Å¯°ëŠyJÖ£À×‡+)ò%r AúkÃä¸ Z•|MG!KSÜÃ(Õúâß-Ñ¦v%‘vş
H&±Wá±ìôËwe€5¬²ìÍÕşSùªÖ7*†U~¡ø\ûØ¬$NÌ%i·ş'ˆÂúOÍ¶*k"y<óÏò¤ƒbDPé~º;~îc;[¨M8İ{oEÄûåö˜£?N]À¥áÚîUUvK§’›%DìÚ1QÜqk¾.¾õ¸ÿŠPmtnQ­*jjÎ+÷iÊÀ÷’÷ioªXe+/n¾ûÄ{~øŠVk˜:6ÁqxT†PÜÑ]H™ï!K …Í|Gp."¬bîØ´àÜh]a˜ú¬bˆ+ó<)åG:•i^0)cÆŸÛ«¾Óş¸ë0- ç¾İ[ë–*êUåÏ‚nüS‘ÍAk¸µç÷İ¢“•ÆèplË5ç…±¥‡¾ÛGšl¤IDÚ%ÄÖ nnRìåXUîÁì:Øh$ÓlÁ´ôLôşğ£®»ŸËÁŠËSÉŒ¯M×I6ü5o5HÏPÔ?Vp¶d5àú³º¢Ziî¥NW>*ì9KœÈ('laXµØÖü<·Ã>ÉÕÑª%Gu0ôşífvG29®RÓX#úºÎ¸ùx#O¶	‹°_€øÔƒkÛsòó1øÄE«ÌI{¿y qŸ& ¤íPè°Æ¤ZÁàšº	lU¦»9ÑE§®5£×û—oi•€,>£šÑ#œyc;~åj—rfª„Æ0‘¹×â¤-ı¬áè#¼WçˆÇ?tä¢cÄÔ˜ÙM¡ï­äí]•íz!¶õÑ¹d"(æÅ'|Ï=WZaÏlzíW0<®nòÇH¥‘=¶Õö<Ï¸	iÓî·½‚$i	J<¾-ÎÀ.v'Oş</Æ¶'
 ¾?Íñ?Ë³"~­‹{¢âSŞ›ô]3%boÂ¢,/şJJçe!’HÏÄR³ü%'ˆ/ËÏàÿ¦´€r§ú¤Åjˆˆ¦ÄÒñ Ü’—3˜_ÿ´Ô>gıe0Ú‰á˜Íw’í¤µ#‚ş
‡§¦¿ç5‹0*“Ìã÷úéıºáõg¶GïKHÌøgı‰SS9)×xÓF¶é½^LœÓ¬“Q§æš%«V³YsQ—Æµb5;l+´5â”rfh4w¡ËÊ%„GyójõİÇªkIÕ~ÚÍC˜™§µ;XŸhx³½°ö¼ÀN0ş[âº)¯ëÏHÇj¨W~‡£ GjÄÚ‘ñ`«orÉâXİuÿı‘ÖKiS^˜”„ÄMC "¸šh+²îÈ¤Ÿâs# \K²–"mì) Ë¼šÉ¹&*®ß÷ÑmiÜÎFĞL)J¹õY"‚)Ï:ÙÖ8gÜĞ¨£±“Êı¾0¼;§]gÁ?ğzX?æ"üÂï¥·‘¡†,çó 1¦n·¶w˜Pæ¯`Ï±:ãÍÆÔXFé¯\D8‚9OVÇKsŒ²Ãñ¤Ÿ¸®¡L‹yÌ¼v½ú‰o ¬«6\õ<µ'~ÿªvú4ğÉûW6?äÿÌÔó	lxS¶>½~B ¡=D“ßŸ³±>È0`s©×ï‚19I/[ÆÑ¯ã[#ßhÉš,9~}Ÿ*í@‹ÎDZF6ò>)¾€qÃµë¶Ÿjv?å}-A¡uäWR˜¸×üˆÑÅ‘\_'"š™û.vì3‚ÚŒå—j¥¯D-eY?ó0M;V¢HæTß.+µF­Ê——„{sÒç«Ú6<ª¸ˆœ÷œğˆtı*£Zã]$ÒækY‘í¤mt˜4"ğdİ?Qì íùûöÓY„¥àfr¿d^õÁ×wß¿%Íùè³~*oC&~FÇqëş™ÛU €ªúH·Oâ¹LàŸ¡ºÏPcY8ËJª.[,§ÿœ·üA4,§Ôe§~ór@Æ+	·ÜµC{kÎŒrÓVRD¼#5JÆ"|&~§œÒò™é²CL*K®âpç³ìàîA†ú£mš^Àô7cƒå/¬@»Aó/ÏïÙçhKòÎ6Íy­õŸ5Õ/Ö‹ 2µ(àI‰ö¤z²ÁD:+»¦V´0óa¼N«-Æô[ ‡°Ï¿ã5ÌÊÒN˜ª_*Q	L¦T7‹û^Ù6¨Ô´t‹˜ôo>“¨ôè$Ä   …ã‘¢°#[ ã²€ğèŞÔ±Ägû    YZ