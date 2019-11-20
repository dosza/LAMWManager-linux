#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3568328774"
MD5="b9022e8fab06a2d75cc1908f4ab66273"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19774"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Wed Nov 20 15:27:44 -03 2019
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
	echo OLDUSIZE=132
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
‹  …Õ]ì<ÛvÛ8’y¿M©OâtS´Ûé¶‡=«èâ¨c[ZINÒ“äèP"$1æmR¶ãñşË}˜³Ïó¶¯ù±­xe;éNf/Ñƒ%…B¡Pw€®«¾øg>O÷öğ»ñto;û4ìíï=ÙŞÙß…öÆöÎÎ“dïÁWø„,Ğ}Bºã\İwWÿÿÒO]µtûbbë¾ ş?eÿwŸìîög¿Ñx@¶¿íÿÿT¿S§¦£Nu¶”ªÊ—şT¥ê™c®¨ÏLC7(™SƒúºEàç‰¸äÈwsÉ£¦eëØBı-©ÚrCŸÑ2š™Ô™QÒrm/„.©ú¹ÎÙ®?©?‘ªmq@ÛjcOİÙnü-”Í|Ój¼¤DÎJ»LLF<İˆ;'ôÎ\ŸâïãæÉ+˜ÕÉx	`ĞÉ…¯{õÉÜõ‰Œc¸)¦¢dÕÙRş*œ”è¥çííÎ³³#m;~lFš\{,Ç¸˜ÉÉÑpÒ;›ÇÇÚÉ‚æ"x«?ìhrÒ~6êL/:¯;­t®Îé¸3œŒû“ÎëŞ8mnÁ,“gÍÑsMF¹JP ÔhŸ XªQ Şôé,pı«"ßa›}*™sò†(°oµÁ«¶Z+®E&ïqç©RN>ƒù-F7@Ô¶7u\ç¿ÏÙÉÇ7Dš›Òf×rƒK—H5soÍÌµm×QØ’ò­‘PŒ-Â7ÌİñMƒ2	šÆÔöº¦EÙ£­k"Ub^©í©yèúÌuæÀ+dñíÍ ‡°ª˜°µ¤³sk°ïC!ö,4\bS{
›#q€3FıA;P Ufz@TÌÔ…ï†ùYøÔÃ¢ßÛ/D5èJuBËŠ¨®ı™|§‘íx7a1•u±kHAŸ»kéÆ§uèÅ ğ‰Oç“94ó2€ÂÏ®éZmvx¶tA†P7ä˜¹ƒÈå•”LÓHÛ¸ÎÕ®ñKU´ê©¸,&kèÀCF\ØaÌ˜	¿Áê	åMV–òwD…Ìg )Ò‚Ï@Z'm¾lA¦€ÓH#Õ„ÊºÖ’ßD¹”“Ù†¡“×9 Šo×#ƒÎõĞ
¶$ i¦;Ì;“dğÉ%JY{œ(UVçkŞ8ëÀµLĞ†f f„çs3àszçô’ÎuV¤İ›¿iµèyİ<?ï{chK“Ï§Op•Ôr–­È^.LOªÀÁîzi¤^¯Ë‡>Õ„Ã¯bW:3tBZ\?®˜¯4’RÔ.’”Tª¤’‹Aª&b3ÜËæ¦°’l+oŒˆµuÓI(•ğ‰“Õc¨çC×
îSª¤š	¬	t¾/C+s"Ïo™?¦0©‘rÂYªdM ,€“Ëá[QËl,yğí³9ş/˜Î‚Œ ¨Q.ƒ/ÿïïînÌÿvvâÿ'˜.|‹ÿ¿Âç¹{6)d4g“¤Jƒô=ğ|<@[ğ-«ü’T»$ŠùĞ¹aÃØEw_É§–b@è£ü«“¼ú›b~5ı¯£“/Èı;òÿÆÎÎnAÿwş›şÿŸÌÿ«U2~Ş‘nï¸Cà¢¶şIsÜÃˆí7ÒêŸv{GgÃN›L¯òQŒtCbëWÜÆ@àEÜ0€0ÇäQ˜õ#™Â³î@&	±Ol×0ç&ä$Ì0>nJ‰å² /¬ç÷î3Õe•bAxèÕıĞ‘ªÙ!Q„OEŒ6¨eÚ&†…Œ&;W[?§ŒZs¢û‹‰gdî»6P tt+BÆ :¦ó²¨j<¬nºê×)*Hiı ›Õ¼UŞ*Ï±rdù¥§;ŒG´K=fãU”¹é3ØœÙ,ä™ÎÔÉ[…à0ìŞë¯³(RŞêGİ7«ü5í?/9ü«ÿ7{ßêÿ_sÿgXxU¦¡iÔ¯³åWŒÿĞ×(úÿııoşÿ[ıÿ³ëÿMõÿ¢ ßó $Ì\'Ğ!õ!D#iá@şí“u¨ÏÃâCˆb:àñ¨ 9<Y=%*i6‡­çû»
i:†ïšÆWrìRÕ :Ä(¸ÿÃ%†KæŞ,JãtC'K-‚õFËr«ÿî›úÊ¤¼X©ÛS^ºƒÖ+RÅ0Y0™ÃÚµÚ£¤l2ÒºCƒ-,3,á'pÀt^R},ŸMC'Iã§ºü “Ú%>'½˜„`bŒ\ù°cÓ	/É	DO¤ñóıGR¦Ï¤„œFJÆ“úv};çlx<%jr‹±•SŸûb:ˆ_¬ºë/°Iş©¾`ªO-
ˆ'O&Û“m9ƒ	°L{Ï&ƒæø¹&«!óUËœâ@UÍ€µºG1ò@NZ}6_Q;Çæ¨£É·Nü²3õú§Z´Ä{‘¥Ö2#å”ëˆb÷äÒî½–´{ë’ »“³x—?íO@Ç,eá„këJJûU. 1ˆlë„‘L!ş¨.œ›¡R,êCh‹Î$¯]?wê›=øøĞ%Œı8ºâÉ‚OB› Áç„™öôã?,sæò¹+Ïl?7Œ÷ÌMşE,‡(ìöÅ¯şt9ˆ«Ç%üŞÄ^±€Ï˜*Zÿ›Ñİ¦“¨.×0;Ks¶DnÛç *JÛVT#—k¹A2Ñˆ,¯Ÿš”c.rTÙ4•(¥KU—&Uîo¸XAVJ+$€,ò\Z‡Ãs<è WˆhÇÃ³Ó$1·c…%ù8PV)vêÛÊ¸œ€MÖáj×kmß¿UßäPG&Ø_zƒè`s÷¸wzözò¼Òá›È–:Ä°<æÃNf0^›G7Ü•ÌxSÏòµºS_|KV—Méô‰]¯/ô¦@D2XŠ" ¢*cJX·Ö”'95âµõ ¡‘5†p/{lĞ\¬@^ÜH˜ Å„Ò3lja4Òômq»ÔMO××*v‹”@f,±TÁ
™5FO)p,úòq˜´g“1¤ï±¦ƒµêÆš¬ˆHìË¤?JúEÜCZÃşh$ [@½|Ú$Jkş²;xùD&±ğ†nïµ†;S\¨òåFàJ!M£–DE*éÍŒ8öÏ†­àhFó‹Ø0D­U†AÈ‡¦³D„¬${ïy³Ë}îÏÊN½¹G€× XÀ´çı›®¸HÇ÷]ÿ€t-Ëì¿’UŸÚõixÒ<¾‘‰p˜&GRdA×—X"ørr¸Y+Õ~Ã tpÊ‡ËÕ|#T%9PìfN=Õ"ˆ£à¬è6ıÙr·T|ïcwJv'³9÷[Ï_"¨ya~Ş]Î2ênÛÿ—î±ıE§jÄÑT¤T
PîdÆ—VáOåRõÓ¶I¾cëp9’ã=4¯vïEstÄÿ‡m"·ãñ&¢‚lÜÂÌ$¡À3×F¯{\Ùâ[i€o	˜‹ĞGH)joeÚ2÷GºÇÍ£I·6®yÚö{íI$G…‹YœÂæÆÑ`n¶Xõ3Ô †Ç¾)¦&¶à¼ısÈÉ|x^3#$¡/çIDa5{##&6Ã®AšâJ•E1è³s}A	ŸMÇ —üÆH‘ÚµìM÷½»ùä5åâ¼˜“_§şÇ¯™0q€)Ô0ÁêşaeÀÛë{Û;O‹ç{ûÛßîÿş?®ÿÙXúStËÖÿÀúI. +ÑyS‰Äß³8¤ÌsfN-Êk{!ôå.¶©â16Qq¯+Õë_é°£‰Íö³À=3èŠ[3B<ßt‚9y8:{6úm4îœhš²©ü#iÇÃkÓxIÃõo ùO/;§íşğè;é·;š¼½¿¿GÃş¤ƒ. ¯üÖyHÈßÀ“Q*Ê!Ş§ôC\ª¡î5”È×yÒÀ¨¿Â+H|^8	ÀŞÍŠnªÊwƒb1E÷ÿš+¥%aéÇ¿g+-¥¦:c«o3ÖUa®¿Ã¤¡–Íã²ñy¾†@ƒ€æPO–ÚæRˆâæ¢*Ş†/ş‹Å±WÜgëÊ¦¨Ga$ïÍ&:NXàk¹Úë¶;]¹9Û‘Ä¢)‰ÍâÇ(@O¯ø8=;ªqDûEõ©©Dİ]«6ì÷Ç”iÕ1ÎUÏÒ~›©´Rµ“¤XÅP cÌ˜Í1ü6¬:syCÔØ.à\×‚$ =µœ¨İúÏªçSŒUt‹l(Jß+•‡J7Ìo
üY	“¡†0Ş‚· ÁÃO¡>şŒ1~`=»jÕëÊ…ß[’”ÖÖ
BH¢“TAwğ¾©é“¸JŒDÅ¸ô›5¼YÀQiFˆŞl¿ã&¿+=‰:PO’Šj-Ûƒn#-x’™¦Zh%(%l 6‚2Ó÷zª£†(c6!®r$Ër¢ä1¦L&r†.™¤ôÕÓš†¢5 =c;ğ]4¢âv°ø?ğ«¾xVÄêutkşL\ŸÄ ¨­LÛNÇ‚ôˆVía\“áµ&ü{P;6ÛÇDë!p§ç€õ
À“ı5¤Ï,İ9GÇ73ÓGÈ÷!†<ëAFÒú®Êµì²åÌs²¹tÑ|o3;›ëŞI1‘‰ï¸G¡+Ò©Õ²O2ùåB6ò>&ÃM-ËZäe»“%‡’‡Ÿ‰±¸ß·¢áf¼IÎ˜¥4•Â&äéSü!/ë Y;:¾Bà2‚¾Îá.P<G>‘
n]‡QŒ{Êè¤NÄ ìãím~Dá#Uû!X”÷zÜ²P÷M—€¨‚óY¹37$ù«PäÑğ1L=·$Qªé_8ÔoZâ~›«¸u]úTC,}ÕÒ;õUA†aT|ú‚'x«}%³(õÈNÖBòä|"²sd&”¬»¬NfÁéO¢ËÇ£“%İLKÿù Û5 ’¹0?è¾‘Mşïœò.dqÅ.·ÆI¯-$z‡çŞkË. á/ÍáÙ/Å?;îğyÒ$ù°ÎuV'3¯‘”•Yb©§»'7‹1U	ÛÖmñ=¸iøÓÃp_ÜlnŸ%®nİsšü®äqÜ1×§jSv<OµD‘¶t–/£¹›ÙÖ†LãşS”f¤ßğFé‚ÛÆä.¼ÄÛqì±»è‰Fn1Â‰C-›|rhQî0JŠ¼7Ø@]’.ÈGâbŠğ
Iá>9Ö*kåg	rÏ™»hdaT0Ú>(˜¤Ÿ\¸ş9ƒôŠF}Õ¾š­N
•;	uYgÉŒs1cÜšïgúÖ9‚ˆÒ¢9¿ÉqöÛ	ã ¯V+4ˆ‰OÇéŠ3¼3Â˜ôçŸ9&8ã~ÿx”B­5qÀÓvæÄ0óÀ;³×j™íŒx(ìtfc²†;‡(Éèl0èÇÚ-B$‹äò¨ C>¨=Â¯­8ñ8í{İß&#ÈFrgß˜ó+…Ağ¾%U^¡tûI_ô2¹×ŠAúäè±Håä0¾0›ŒÙEî<¾Ù—Ã·Î-B(:S	$¤Lß:›0í»§ğÁœı£ƒ»9‘øÚ¨üò{–“³JâuôÏXÜ[‡¿U
é<_!]#é²°¤aS'$˜Æasàò—ÍN -­ıWêé2>DÕ=ÏJ.ô'‰JuÆEğæ}ö]r>Àæé%õÄkAš1yfCCcŸÃ ¢x÷ŸXÄÜ“bÛ´©ê‰bËÈöı¦ÍóFfİ ì<p=ş¥öıM[4“¾ñN¤Ñò©nS-İ9ñæ¬ØEøˆjç’Îr_ }"4S][÷¯‘Ü+<k.uÆÂ§¨’Vå¥>\Æ®•Ô›¡/ËÃÁD°nÕ„.Æƒe?d×Çl£|Ü˜ú¶éè–6×A·DÓ•GµfºcZ #Ïj 2Ôr=¼Šu³®Cd†sˆìˆ£ñ‹Ã£³ğÚ\ …[À5…Ş«“–¥3Vd÷	l$'+ —z©ˆËq‡ü)Z0Ö}Ò«ˆÿPŞg:Xndå °9ßâÓRDB˜J±Ævï™¹…I-ıJ¬ò½+c0M”ËbÈ¡®OiôşìPpç0Ï¤7ßõ¨\¼V^´;Ê),eE;—å¯’¼K÷ï_G¦!¼á¥n…T«ÓøãkE\UğÅU Vi»øæ¯ëÄ9¾€3EXtj%îjrÒ9=›ôÆ“¸öTªSX„YBfF~¸$eã Û+í€iĞO–®Mc¬ü4¤€€t¸3S>'¯ú,©åÕŒá—&uäZeW, ¶Â”Ehµgj	Û À*Ø¥’6[	õëËÀ¶êhbÚRuÖ:Ù\ÄP¿´­O²AQ*Ïg‡_:V¿	¹ŠdhÄtô'XŞxvğŒû^>'óPœä& wÚãÇ,éY8á—sD™e`UGísl n‘R¥¸,çåÜ=¹–1É»XM¾ÛËk^b=ß!°!­áñ|’Õ¬““õ,«R€² ¨Ü“åaÖILœV	2©ò^_éq0Ë´GéÏ÷+[ÅN¥vİtN…€¸İé6ÏÇ7
ç½q®è¶a*ù´Aæ“Ÿöå­hfîdà| ÛZíºš#çÍ¿¼»!Uè½›Ñ)%.İYòó£‹~@w†gIQ.Ó~ÿü^…_',Æ>zDL¬¡Â×Ÿ5°Îüá²µEªäXÿøwWTØÀòâ“tV^"Ovø:O·	tgòÖt¥%€0=8?ŒrUÃu(¿9È_[ 6¹ãMTéø›d¢‹Sz1Hj¬ÆİW‰NlLöà¯@*ş»t”iwÖÁâ3¥IôÈ ìŒÈŸp©(àşS¾„7™Î(â=Åş\À»3ÊÃ°LğüL-ŞşL—œµµ”t ¨Œşè·‘–=¤a¸­&˜®•\aÈ!RÃĞ²"6óğ,IÛ|aåF4Ğv¢:ˆÎ99 x:n^6¿D'tÚv<‚_†9¿şr.âTUÛË¬f„¬]÷ïÜ)¼Ú©‡—\’>üäjG<T^+‹dS)Ä“‰Ä>ÌÜmÀC7yÃ…ÛZ¡s¢M+~g,LŞâû´›â‘"´ŠuP>0…9=”ËÃ™5‘KX#g\	¹AîŠl.Ú4"6bÜŸÈñeêuÂ2ÖL¼ºp÷R6"KkrRe=¿Ä0ë¥º¼ÿÅhs*p­ıã'”ÌFA cnı›Zgá4>ÚÅûğ3ë QTµÚ£@7-¢4Êá·ˆøTc(ÛÅsZ>ş—€<á K={İ!9åB™J’ó`ğ.€™¿ë'ÃELÿ“¬ş»½oënãFÖİ¯ê_7¹#ÉÇ$EJ¾Œd:[¶èDÉÒ¥qf¢,®Ù’;æít“’Ççïì§ó2³ÎÃ¼&ìÔ@İh’RdïÌŞâL,²( …[¡PõUğsĞ,Š>à´\N—ZT
zQbª‰#¨F­ô­²“gmè™,®¢É;\öS“fs+ô¶òZ“îèà{Tîı…Ğ^¸+ã$€³/”ÿ"š()°R¹èÎ‚>YõTá×WVæähO”¨ ÇËß´7©6›p‘Á´7#Ã†¬ÂÎ€¾ğk9æ`¦ZÏ/l“+gÊ•íYY]Í¨T¦Ct=±¸2'­Õt{–ÀS™©œ%t4ßyKºËµÓ°èÓk½å\¢y9±"ÎœZSÿ
ïÒ¤è+6«œíN3öm~a%“r<0VtË*J¦ô5s=¥àÁà=ÎÈĞ%³ãğıšŸßíg–Í*·,8—™Wa¢¦¦ó.İhÇd_cL|àÆ³¤hŒÎ~‚µv›î Ç_ú	şí÷bFåÀÜƒ<¤ñ÷eÒU'½sşŞ‹ÎÏÓ_Ó±üçÍF4ìâWXùÑâ¤×`EYŸĞ?Õ`˜°-
ÿûSÊß¨ÖéÂ‘t’ùY“Ÿø«Ëoèf|MÓhr05“‰ñU'é¸èñ{¦weÍ8ÁÅ¸î¢:ğìù#Î:—İ$ ï¡jö;l£ú;FZ¤N¸?%£¡LAX#ïÃ¾ñU:x<Ùˆˆ3ğnüş½}©–Ÿ­Hùí'bè›z9è/’ü¸â?†•ïj½ßÆ½pL§½é@~£QÂ_j¿#àôÎÍ£’…ÿ(²×A›hPàH‰\.Óo2édlpXŠ¢-d/'ã«Ì’2ş*<‹z}b"zÆ‚¸½²5×¶¢çp µÆøü´'ÂÕÕ-Á6QRIbƒŸ™*l¨•f¤©–^‚T>#÷Pz°%hO¦3Ÿ¹şdæ¢šÍëÕõª)éĞ„?/L©LÒ—</5Ob‰JíG.c¡‡¸_ugóšB”u^ÎåÚ» SuB9µ­qpÏ(¼Á/ÖySaÕÔnUŞ+Õú)u+”ø…›£>Sí%ı¥›°p/Ì&jNÍ"ò)ëf+!›FıoğÂ(=÷ˆTdHµ€YAÁp1ÔgéNä0WÅ%ÖšhfÊ(ÿÉÕïùæ©dÁ²ú=£¬la Ö¨š3ms€.­ùTZøp!éYÌÈRélAÆ.+àÕB˜Š®&¨HqÍùuĞNrÉ8E§ÜuZ*÷-¡Šà—çeÈôº+}bšj
ÖÜé?›:§!ÖxÏ87½£qvrd¾aÒZ@ÔæøÂÊkjåõ¶ÚŞiãV’K0Ì„>¾¨³EjáÆf‰|>šØ›ò}w§%õJÂ¶´J¯î¥¡ÄÃ&—Æ>¾$‡Ã‚£“·˜%—®p&"aÅsš
ûˆ•¾áºÙƒÊygu’ûúÎ.]n&ÈíŒİ›lB&AfaÊ_ùÕÒ±PU·€™±³X&»¤Åoëò7}¦ÜŠøwqh_¦BÎŞ&¹W‹Sf—`´ ÎÑšı»Ì°áÏ¬6ºC~çq$r×Gú~Øìw™áƒFqŞM8(²¯å1‚°éùzµ½óÔ b;ÁÕ$¿mù|“ÔDê]Ä
°nUH<›{ì½½•Ñ™¶öõí ™ØåR§räÌ|…È‚Ö.zê(ˆ-BD¯ÛÕ}îyëzÏ•Q>k%ÿb—D8eU\ˆ+†êÎ!Ğİ*/å“Z\3÷Ët¼Ì„3pî<ZÈcÎ_À 'O6Â¾M…(üWTÅ]‘O³\hÕ0i·wß|Ó.Néy9hƒÛ8.à>šñïŸáKêÚ$r^¤›”–Th‡ÃIÓ½qäR­YÎ¾¿<oûIí´VÎc)Õj¨â*õ“|Ö-7E‚ÊØ‚šŞÈÓ5ëèêğsÍ»¹Ú^®–“«òqíâz7®YWø=•Ê<ƒ/Ÿjşò<wÔÛåd·Ô[æ•î©ŞgrÉÕ®™4ÔÍré*~gOA]f÷Õ¬F;ë3¿ÑÿzÀ³œ’Ó¯«ÅçÙ¼“oçœìğM¾s×äÅ=“inè‹EøHÑ×”{¥íÕ¶¬ü52Â’sd±pºP[Ì»A,¢.’##ğİ´³5¿·s¨Ûuÿ˜ß#?YªI‡ò¶Ù1+Œ…ÁT|Nº¡Q”›Rú¢x<j¹µˆ„pb5S4@­{‰€ îÊ+ ¦b°Êt:‘µËXj–˜Œóh'ãb“®•`I™Ép€«
ƒ9ÌF‘àõlá äwì›QşZoşÒœ¹T²]ÊUMº²0­Ğ\à–NàÇ”$ÍáùÑöÑ_SÂj;Û,§o—É[ƒ{õ{Z¸l”K‘VÊW—3/(4—/ØˆÌò½…1êÕĞ$‚‹dIí((‹íŸÏ—òoù<B†¥eşaİ¶ª¶¥­”¨7âK
ùù£Nˆ×ª"’uÀ]åCUı^rñSèdk«~mm©‚ˆ¯Eó¨IN»©Ñ7„¾•†ô¥¬H£-ÿñã§e§‘aÁü“[›5ËL§‡âŒ¸@ Q"Â+V=÷dÊS'^šBüòó¯Q©üVızuÍ‡ƒ@wÔƒ¥éŸ¿®<ó¿~±Œ)yÒ÷¥ç­áe†è{s@@N	¾€øù—”¢D²§È©_C•j»jÒpUiUÍ¯ğ…Ï¤¤j›x6¡&U´Dé¼Ïk
â›ç5Ùœrl‘+ Ó 4L)˜"j]µåæƒE<¨g:Ø#zÚU;rŒÉõeêÆˆ£#÷PáˆÊ+ÊÃ¸·æ	lÆÖŒë:A¯d5¬-k³3Yè§åè‰¿„ñª¿´*ˆÎR©>›€exä«’!_£0_ò+M_hëÅ
öªBJ`ã¦5p *ûH¬ô˜¼wI.EC9gOª§Ë…ÃüëI—ü§<º—ÚF­2ØHjÅ³æ£18P’‡é²`âJŒÆOîAi× ˜Ò&?·ü"`“­Ù…“?_ÆÕıİ,§Aú¹8ßøp~ı³p¥ÔûèMwÿÇ9ı%ãÖñ?7êk÷ñîñ?çá^¦øŸkÕº‰ÿù¸æ@ÿ´Âük’Åö| v9àP„dp>8_Å¬XêÄıCøéğ><}P¡M3Hó…0>½äH‰İh(*_¯ô#8è$ı½¹Ü»}¨D;ü¦öéYôÃÑ¥Ôí_1$ÏlÍõ‘ OŞÈ]4:!Z
{v	Ôˆ¥FCz„x¨ÂË€¸§zŠ½c»±ôÖêé	é®ã°r¶ú©/z£01`øâ«ç>‚]¡^CdÕ+¤xx>~$Ğ¢[< å
wå:6›4•èÌöM§Ş&Z"o_8™ÆCØ»%ŞÄùh:ì‰Q,êÑO/WÂÂÈò #_sùÍÁ›Ö²ƒg6Ëür#ÿ†<R#ìÉ„Ù)pcLsBÆräÛñZt€{u&5"²°q±Ú„—d[IKñîéç%îíÈğR_$‚Y	|U¿‰“)3ä êïñ·DcËæ%L1˜íÍ•òJ%”‘ËØAegsuÕKä+6FFgAôF¢ô |Ñ\YuÀ¯¾Ê0Ñ°#Z<ötm›å†§U	ú©
&µä×˜ÑºĞòGøZ«ÖjâÓªäA¦Àƒ;	Wfi‰ã+-•X”7uØb)QşT~Ş®üm­ò§­WmÌFAf_˜úá"ü ‚şæàt€`Ü›ÙZ¥Pµ+®¡ÖªzR<VæN1ÔÒAl_Ó>ÜÛ=>nít¶¶ÿŠTeÏP6ê¨´s²‹;X³¦(³vÇSÃ™
i§e UæÜĞ¦Âê°ï4«=ç&ã9 Ü¸ A×8HÕHäVàXX¥ Ä’?§QoÊéwnFJÉ¬ê9#uzSQÊL,ª)\Ë0"GĞƒÿQõJ˜”¾ŠHH:w$¸èŸ]#lEH‘]*MJà<tkLÑ×ÓŞ“.XV³\ßÒ¿õ†•>åí
ç}³¼®ŸÊ–Oå4 	kùoª¤Ã“Ğ/e	¤•²¦@ÄS`ËJ9â•‡…Ì=d&Qk½~àòh|dÒÕ=N#ƒ$ ÏäÄ˜8ˆ~’±>î=çò´Fû”X!a;AOù›úcIà3Æ†3”ìT/UòWØ7ÓK£–9É~.€—:[ÉÊoR«¯L?™p)ŞÕ¿ŸùrYA¤z}ZFY;ÂØ¬L¹\¶×°ÖÔoıQ:¼Uó]Ùæ3 Äwš8,È´â\JG…C+Ô¥Š>\cüd¤²™‚f]½Ù°Lo[_Ïh[m¡ya±~nÏ)YèfcM-µYQT%rI¤Ö¥±yÛ|W0êx;Üp¼ın&8±otB0Å´Œç=½ÿCyÚSnæXoğ*9fFÅ ìvñGÁ Z%i	m~}‰n+JpH…£5A8Ô¡—0ñt6PŞ8ìÚ€$”AŠäÉêŠÎˆäÑ£(EñtHÎı°/JHé8º„.¿“Óa[0¿«Õ*¡_5€]ø/™hêÉóøˆâÑÎLz!–i:ºWí}aıŸt&¹ûØßÄÿ©××Ÿdôëë{ıß}üï;ÿ-]ßå(_0ĞÏ+ëÛ
å-	é€?½R—·_HÿWÃ5{Ó1zì†„d'¡¡dCnlc$øJQCÉÁù„•šnÈß‹sĞ}NÜu¤åÛ\ßó¬İ<WŠ­ÿËx¼!×ÅA¿'äı¿Â§g—*-r“îs¶D¤ •Ñí…á•²=“ä»(âA[ÿ£ƒDcË63¥c+İŒÚ›I¸î¦€¿”gd¸?‡k2à ßÄYŒ#W‹V.‚Ÿs²Ê£úçR8¨dá¶rDx\2\Òyô!¡É^G¿äÃAÌ@)¶”ÊÁD,C]ãR¡ËéIïëüI/m¡+¶ª­`Õ/Ãj…¿ÖW#9Í.‰E§QB4’0‚Â3*‘Kd7wÑÛoç–‹if*S¸N°á¤=	&Ó„!ËÉñ/]ÅnÚİ¦	Ÿ‚¸‡OÚ¤æÖÊ:Ñˆ4CS¾¾zsĞùæd—'¼|£tA[Jr·¢‘qí)YR—ûEô NÈ?Ã¹IH€ßßşó·ÿÓ3ÅxÊÀãx?u8]8m»JÂ%Ù}Ÿ4WDy¥7~!*}Q®¯
i'"µ‘ 5‘úA+M2vŒÆ“
ô†p€>„|šQŠ9dS0,¦.·`ğø*0<›öQDâaÄçWõ[g—,l}ELyKñÊ2¯xÒé»ŒŠºä ÄØ±¯Ş…İ÷hÓ0ã` ®¥‹¯†¡‘DÎ‰äİèŠX¦V-´¬W×ªkË–Sx¦jÌµZ;“Cœ«-\g›õ4ÖrôAì„gQ0Dè`ÿ¼óõ\aùôÙ‚µ
cõYşÕàİc3}»œƒÑsÆÅUgÌ·A›ÒÅ¦!WU÷)®^Ø{$¦	í[üº^ÏÆå)j#Ã6ËêÁŞq[q‡NX<R‘i hqá²“j?J&©™LSzÄÖÎŒ,1Ac¢‚ ÎyÓ:gÕJBM‘J{ÌliØT5Ùë9?Ü„ Ì¦,5.„1†SFo¬a8!dšægQ?š\?Çñµ@ÀÖøO}¥šÑQô¢ÄÁaí¬¼02Ìç“èµË€Ñ)0>O`\U™¥ˆ«­¸ÛÃw¨Í‡Ş¥´:Up—é0âÕeíQé©wˆ:{2ÔÏÙkƒ^	œ./p4½@ˆ$ˆDÂyıöŸÁHœÌ¸…	o\ËÃœWÓœ½_ğFbJ`èş$É¸èu[BLT*ãi|êiû§ÊCXÆÅ)ëõ‡´àË•&	'>j=¤:¦ı‰‡€Ï‚d‡Ÿ|!^ EX{oixÚ3W­8ÄMîÛSlh>¤HÍ´%I:„­`›%J×UDûˆJQfEŞÿ^ExñK÷¶>çËÛ[-]Et¾¦QdI€%µRí6aòÓa{2qÙ“Ö¬P“óiS ­¼®åuğÏÛÙf?¿œ&Ó¥K7bÊ±‘Gı€TÅ²¦b\şo©q÷KÛ#L%ôÂqâÉ;!ê¸ñ¸Îî-ö²´¥Ï¢tİÛ~»¿!¥²ì´hlŠLl–Htê`
²•Cà¥ÌÖ­gTvoÍF¨Ël!Æª¬£Ñ#&NnM8Ë*Àñşèª2BÍ€à¡,Â·T¸[ŞuxWSe%¸~‰Í`)·È™ê’?¼\Ë¹¡£@60ªåE=0“Tq@Áã
3‹ÇR°üšå5ó(¶xæ”?«²½PÔ	·èƒŒ‰ºnª&úHúg?Â5<F]Ø{#D¤„“x”GÇ!ÿ5s3µnİ·Xv=Ñ!XûòI.L'íV‡qÙ¢Hyúø¿|›¥ß¤À¾hÍrr´×ÔèºÍ2‡1V«i†ìéĞ¦Æ©Æ‹æöé
f¦<:ïo¿Ùş¦uÔyµ¿ËâÑö~ëÎ2ü²v:ŞÒNÇÆa±s¼}ôMëØVZB I8ğ/aÃóƒ-óåÉîty´)pFşnâ§ĞƒğÃ$t=¶_G	zé]ËVaÌh÷YÕªR:•„ Î¡W›øKğ;zĞÉC8[¯s ÍB:)s´!Y:‹‘‹ğ±2ŸÄªÊÅhtÑåŸP½îÈä’('Sõ±š'3ïu¿'>P&2®;I0~ß!+N.Óºâ›Ã_9W2]LËEı\™İÏ•™ı¼·ûªõ¦İj[Ó†3Ä÷@›1ÈŠØjz D"¼5SDnûu’_Z2`â•&è¿Ñ"p“5€‹Lv¬İÏİÏ:wgOcÎ¬ªóé7áÄTå£ºT»ØğŞ±¾Î…}ÎÄóÉßÒp%Äˆ
]”ğĞ0 Ó©“B©ç’ÆM?jíµ¶Û­Z•B2ÄfòÜz6–îŠ¥ç:w!cüdq;…J9êtâs0´ İÜ4-d\ÕW
YGA?Ë?ß¦èÏâãLªw"±Ú¨HW—Àğ†çÂåÿ–_gFûñ¸âo	Ìübs0ê!f	PğÚ6è%s›}¸©êùN×›„õJMQ¬¼º¢4¦©|4wªóL
İn…‚m½êì½ù®@ç*8ûyõ1f2Qşâ‘˜@1rPĞ˜0§^.Pø¼ÒçŸ<É;šˆ%Øø
ş5\0ñ¼V‘İÜ,Ö0?ŞRéˆ5Œ0Ú]û#8¼’­3vås^,$@a‚Ïêçw/’íF©©~æ	H
Eğ¸CGÁæŠßí†ËH†ìd5eCA(¤m]Bey¾Xc5Oû}Up±˜òGıo’
&ÀâãŸ/ÆnÂŒ™#j©Ä(
OŸ>•£Ë™W×ó8ãœUó2)¥Œ“cÅ“öv•ºI­¤2ñN9twÒv'´Yl'ÎéoE_˜°
¾ûgª‰ÁEÔ=†gW^ßŠ’@£›0FŠA•{ ¢fœ5F<ùíq4B»hØÎH‘F‘4’Cë¢xÔ%*@®°æ•® *€Ø+Ï-…w=F2Öˆ`Ñ«««J8­ã †6…Å»ŒTˆªà ÃÛÖø%ÈÇ“Jù£].ÏŸ*²:	âê‡Ÿ‰éûüÚÄßëNŞ5èJä®—ç²ÿ°èÖ—áÖÛô­ùÊô8¶ßÜMÄBfÀ9£¨ƒUš/4N`mB&½¨ÿ.à˜’#VºA¿!VàK4¶ÆÓñdÕU²VÛ=tîÚÆÀ*Îâê•õÂ^™ÆÍ[³O2ï3İâÊ-@Ü5ä¼„¨ÄÇ¤¨åi¯Â9Ò³ÅÎClñ`Aüh_Å-':y¥ªéƒ'ÌJÕ¬ÇÕdvùxÖ°S,Ù%Ï/OØ°2
{¶­Æh—;±šsä+’¯öv¨—V ×hyy*VõM mp“1ƒHm¤qíÅækaE%dm¾9Ú3Ã™ Y
Vètfjƒôîí‚‘ÑDÒ{/ŠVFŞ%İÒ=1S›ÇîÚPexz%U:‘ wëëëOÿô¤
ï¤¬0;+13EŞMS))­¿²¶ñãÆãj£úØw%²6©^¿Êª“*HdµÜè¼&ØÍ¤#éqµ±ºNÊ°24ıÒ¾ÇŞ1;Ck{,1®Ë¬åN[ƒ©R¿ùhš¹³g)Îs«íØØM[ÄEÇ§HhÙê*9&sÙbla¾§ºÏYs¹ˆı\=ÍË7;ß-Îx#ñËŸÎ]”â™×ŸUL\Zµ0…Šhï~³ûæX¨H$(Îß%…ü\æJ0úÃ<AÌ­Hî±PÕMÛ£EÚ‘o‹v0¨¤¤à–ŒÁÇ+ŠĞpª¤t¢§zK×a"~U„1°Á=œ·
ô¹3Î«Ğª›Sú¬×É¶µ|ñ€iÎI¢+~Øñ~D“GZ±‚ûä©/›U@.B(i^äZ[Èªbš„ÀöÄ´$á@°†íkßM‘Öœ=ü%¡åBN™7«ßìÿÛj¸ç	}Ğï¥¢?Íi³¦øÂ±0¨¼5½øáî[,w¶ôFË~oÜÿÔfİnå2òU^¥¤šó¦Kˆ¢\J ÊŞlÍ*"g103qöNlÁ¹²Ü*¾-Ë ‘çWiu2ÇğüÅ]/5¶e¿p.«gáùˆ<®Èœ.¡°58MTÑü9#îØ3nT>Ú\ò7ò¨Ày³(Ğª]|–J‰¿-õa3Ş¦¤ç	á3Â³ÒRÅ1#ƒ!«:_#l‡.ö°ÕT¦ÙJ¡m¢˜Û¸Ù)ØÜAî3—£?LgÕñv‹¦µlª…Sÿ¥˜ˆìå ¬K•£pD1¬¥ùÈlËëíİ=¹ê¥Ó÷œwüæ%¸ïi3†ÅUÎÚ õ¦şb»oÜÇî.·ÅU„ög0ı¤%vØÃ&3­ƒaÿš:¥q2æI8äˆCåJY2M¹æäšî4Æ@

Â÷£1“>e¦‘Á{õŠ•%’ñ€#-z6¹Û-e·º?bC 3®††êk3ı**G…œ›¯@—fˆ~ÒëõhêNFBEôE5¡‡‹1tli«äÙŠ(ëğ`^g»%òÒ¥Ş:Ã0ìubzØ\™”ÀÓz8:ÇAŒ8.ï7íäğbvü‹ä·(¤&	ÙÛwÄ«#‚òhÛ£ü˜9
UL:€’<<•&MDİwh€¼*J&A{ MYØeØWúhH,Iñ@“`øt²Ö’6¤²…øe ØeEËXŞ¾\…ûàøX¡ fœæ!ƒÖf¼ÔPËš‚/-f
î¨Dq…ÍàRª\£éRv~ÓEÔÄ™DÜF–ÕúGB€Lô£Ÿ9 T¹¥\®¥/|Ë£ÎøA÷œvó²A’g8ç²íuÌ°áUàüH9="NüŒªÑCr¡G0C¹dBé™àª*(Vzx™æABÍ|5Ê_{©Ë ıÆü•
IÁôCêib…ª‘IíÛ–´[»¿ı#ßBøc„w¥>&0°ÕfkYœ†0$A”‡yüÓOŞd/FS0ÛeYÂ®Ç!à;ëµÎZÆ‡9mê‚¹E	ª“V†eZxu³ºldêrÃÊl¨S¥.İ(~&|F,3Š•­H cÍ¢cÏ$cæ¨Bì#¹–Ôëº3¿
ÑŞ”³œr9š³†I¡†ĞòA†³ŸkıY™œ/>1½œy$T(¿\gz=ÁŒ›*gBÓÌP
„ît&<Õ$ñ·„šÁ[®2×ì`TFšìÿÇR^Zz‰"2½ØV¶‘ wH@šíîUa é«´½ór2:é…—¤ëF¯Tì¿½ÑË}ÒğT|p5c³åMZ¯Ì—Á,û4æ‡v$/Œw=O0ÌD¼¶Ãm±U¿E©ä‚§p5^wîjá{…zñøŞ39eK’{²±ºôGä2"Ö3­Åìjpî/!fE¥‚uŸ+”—£îV6²,ÕlğFfæöânYÁÖÂ67Y±7©»X‚¶ÙY«riî²,‰R:xKI½™ÂŒ*hÕf¦0»'7yÛ¼8½Dtl 3£ÒİÁ>ò9ö;ş¢lq¼¾¡xIî)ğ5ı2[ŠîÌM›n uSŸQ¼xØ¥gÑD²äö@5PfT"	P‘Å§Yóm,¢H2ğ6k¦²zNûfñª*”p„GŸ+]OhŒ0«Ê4ö÷v_íw¶_£MãşÁNĞ¥ Öè °óÑXn 9Ó¿Â	—uP×0•Œc˜º)SâÚ,ŠÒè,„•XÀkØh{1®Ïğ¿~O[£-åáİl3Û—ZX(O·Aî9÷?r3!·1–|¼ìÎ—ÛÛò{§ dÃsÉ ¥Œ:Î¥Ú%h9Ğâ(@'
nÎ(4•2B¿{r¬®Y_ U´œÎYm·{XK4‘LF‡RK9cwÊìM^ÁVäÜõr{Á,Ã¯tä’É+O2·5¸6†{×ü×*A&¢R±~–øOO?.ÀÅïÙøOkOïã?İã¿Şÿµ(ŞS×‰âÊÃ}¢Q\åf*‚øbJªÈ‡ç›†kEõ2ºFl^
Ù«gq­G²ZÃ>U¸´
AmHÚ£aê;ªè¨QAü…PaUÚìtÒú¬¬
ŒÒŠaE$›q^ŠÑx›Å«ƒıÃ£ÖáŞ_)R¼Dı>ì¼=8Úiÿ@__áw:p`ÎÂICÂM¿RşŒÆ0#ªÀÙ]äßJŒ#„6$Ø"S_RF’RT<T	?B]?‰fSTŠ{P£A	xp"cå-Ş8cÍàÔU©Èì\¨Ãy¨¸)’q¡¨¼E,æóÅsTn”£Z»y)œG•3cı'ïB˜“qò…ñ¿ğÿşwãéıú¿şßÿû±ÿûø]ˆ!Ó‘¾ ¸s'±vŒK<U€<œ|¡TÈ«Q‡ñÀ“Ç685ÃÁ³¼|şPßZo–Õ‹íıí£ÖŞ¿Zƒwëé»öÉK8¾»½ƒ¯7ôã7­ove–zš\Ùéèbï:MJ¶a%ÜşÛÉ&°‘>g‹YMxì¥ºÃÚd0æÅL…KJªx¬L•
Ê°%z /¿Œiq­ÎõÄÂ\0Åy'“B[H”´œ‚]@k¢šJ¯¨*«mšÉÃK(ŸÕ
ÿ'Õhù«>_ÉÃ …}RKGÛ»;Ğw/w[o[<à<u çY=óÈoz\“âgª¿ßù¦³³}¼İÙÙ=j70Ş›F@n~³ã1^úSGäÓ4Ï¼|ÛÚ{…¼Xñ– ëå°ıdÏN§rÉîî’:9®Â˜üşw‚aöÅAV«(Àáç€Rz«×€µ^íÃC*ûtòPÂïş‰’áƒÂæõ'Õµ±wÜÎ½x–}Áıû0’á¥ó)Q‡*(–ï´^în¿é¼>:€Aòf§é_7^½–P)x$Ÿ˜ÖöSyk<u Œ6×Ì,{»/%æäô÷¿C-në{³„<$€š‚¿ïÀÜz?a*}è] ,WĞek§ÕşîøàpÕÛ><î- 8ŸŒû‡á¤ÚÕéù`{šÔ€†[¯7y€9“Ü¦‰8•rXÃÛiÎPœ:Ùm=áf8ïiÚÒ%éTçºÙX´S?Hê{NÏ¿'Õzµn¾#·¼™µo›¤ÏøAÖÖª7€jæk…}Æ‰œKjRK„‡”•ÑäİôŒøøÓ`‚xÌÄÖ u™\pàÍE~‘¯šA32:ô¦“a§ëìî´Tª8Ÿ ïÖ@¦‚ï+‰T6â5È´àœö]ûpû•EÑ¨åNxI{Ê!c¬¢ËAI“Å'j2º¡Ù˜à
‡Öªq¾-û­7'İãÖ¾•Ş½'Ô‚1^±ĞzbªÊ%Â÷¤Ã€QÕúnösygÖ\æ×Ëá¬oqş‚<›+åÎüp¶5€š~©=µê’øİ²çÄkÀËjØcî°ÁÄ1hú7ÎšcÄ<
šÃ¸º»R•™é{G­í=¢Ê‹„UN5ƒ¾&&1RF)¿IKs*Î¦<(æôµ”¤ ì™‹æÄmLv«ƒØD5jú*rKƒMÌ2pIéRW]«æ_çVärX=Ãp$0¨½ğ¨&©M‚‹Ä¸Ö‘Áâèóq½ÿ­ÍùÉ3ñY¤MLò%CM’âN½óŒğ,v5P¨ÉgÔLCõê³*e”„5Û¾‘‡˜jrtĞnw¶öÕsk¥_&\¶¢Åë[ú¢A–_HŸ¬&ZÕ´õ/é@ÒFoX°„o_ûx‚Â»e˜jñàòià%hµ^ï~ßDÑwÎ±FÕ0½³r×qÉª_A}€ÙìWe#Zú•
ûkÀ6ÑDÏ—^¯2æËÆùĞ>J®èœÁ±è®ÉùX>â'$Uíß”g4âë
ßVÔÜµ}¢ŞPşšö®âßU•åÏ4?¸U…?g}1®•ts“Q®è×ªçİ¾Æ÷Îİ3Ö€ÒQë›Ö÷â/ÛG»¸d´=ïíQÇÚÕ}|bœáQQˆoNëŠØ.¹MœpXø£³õz¥^‚¸uv1y+”ş"ğ8úp6=7vƒ(5Ô/˜#£zúöÃ$™¨ïÁä½ñæâ]·¢JÂ½á¢?¬§ßè¹ï¥°åM§d† `Éôì’ufb¼w1µVôzä3„Àt±öÆg>è‰ø  ş³ê¹¢–ĞRRüX¤ÁLĞ^Ã‡§B°ìğ5™>s¦¤|ƒí^GÃ
¶Ù—Ä*hÑGa¡şá‡õñ:oıâ¶‘Ğg?Wˆ©ÌK·¹Èñ.³·Û»ÇÍz0Ñ…Éè\©x$nÓe
26¹ÆÍ›¬ °/Ná|w:É>K5#?„’–ü˜:Ø‘Æl§õé‡Ñ8óŠH3Ÿ$@N¿İT
Š4]nZÄÌ4`ziõØ¤¢ï¯ÿT…ä›Äµ6ï”
Ìq4j§B´‘º¢_ÿ>¿8ã~ª¨¼ã‘ø	c`+"*ö\‰ˆÂ?B…3ºkB:5)ƒË ê£"YÀà„	»:¿6tw6›ÑP–+°áÚ’*µ }¾›+*åˆ®ñLÍOˆÒÿ²¸5h¦*Fá¬f@#t:æçæÊüÚã,š3
Ûê
ÓaÔâìÉgæ #bğTÙÌL•l]DnâóÎ}»©gã·íc#µ¼õÔ¯ßœì¿leçjàåÌÌ\M¸X…cêZµş¤ZW…¡VL6lx:LÛòf4Á2Ìp\Ğô_ÿ)^^k·[Ş²¿Øìı* h3ø|šĞ5ËXG›x„ê©W£Dh]x:aÏİ:õ)ûŞÅí_ÿ.vÏ1™î£Çµ™&!êû±Psº“•™jëSó 1EA×Öôî€gµ;ä´°.ÕR\è¾ÃË#8ô¤BLî°apU6ªªã7eŒ^•*äPP »Ê®µ}rˆÚIñmªyÔ¾u¾¤}»&ò	Ånæ¼&šçÑ9'¥å/xTRç^<ì–ñßÍ²“5ºş…æÇ©üº‹äÕî<÷\… Æ:‹ƒa÷JÛÑ³×ñ<#æÖÊó»E>¿l}ßzUüÖpƒi:šJò¬É ™¦oÔ=a9–fãYöePõÉUÒşÉ¤n4‘ærãi•´€Á—Ÿå^í·›õº% 2q¾‚Ê)7ª¨_µ%ÊãljCËFúÂÇ˜åó_&»>÷V‘ÿãì?-³ı/kÿY_¼¾µÿ¬7ÖïíîíæØÿÜÚ Èê·³bcúDâÌ\†ıÑ;E8¼ŒâÑ¾£‰)Yd|“ ¾P“÷Ÿû;'{tÃ‰ËÚ¬—ßı{vUxøÉó8«ÂÃwe³l	ıE2 *ÿhXIĞ†{d‘<JÈÍ@mI;+©„=¼_4/É–¬•z¥%…´Süù‰ç™Àœä† 7Qûs4nÚ¨¦Òñ=sş(Û¿•<=í ®¥±3àÎEiMè§¤ ]Z*ÕéIæÎ’6ÌçŒU.DiZõ…´Y¬6x†Ğ¯ş|CQzâJÏŸ”Ï˜i0k¬ÔM¿Hô‰éôB4{í¡áqÊŒìÌ6L‘_63úy07zã¢Z­
;­t„•øÒ~c`d’¥Xƒ‡ÈùéõTê6cúñEÒ\)?\ÍBkâ‹FSÉaÓ&Ê)-Ã‹™g@]½—ÑÏ±:¾ÃûÏa{Cşe*
ºÆ›Â¦±¿‘
»ŠF^Æˆˆ#ô}(5•¦oq‡Ìb Óó^HğPáj¯mùãÍf‘Í²B0êO>µşáaÓôîW¤>ÕÆãî‡'JÄÉéä]:Ê—{òAê$œ^jX¾ı¡¨$çyGËLHaÓ%²ûP†dM•"ÖRüd!µÈØpX.áfUL«®ì°P5¸œNBœ¡{1ÂÌ¯è›AH-PRºÀzM<òãr {1õØÿ£šÁ+‹Ê}m©D«9ÙÂ0=iÅR­5?1D´ãºƒE[ó5n?3aº˜Ïeˆfö.˜==M¬Ç£ÑD_ÔÛÈ‘ÜN £'Qà”.¢óˆ—&ÁøÁzA/ëÊixXgb¦¦.î(Š™`‚T<j¾åê!Œˆ>Ñ0öîçB>K§ìãSqHã¶ä Ck¿ıß^@ ØÅcrÓ¿Øå^¬ Œ%êe¦PGø’M;°; ÆÁƒlñˆáfĞ;#˜ˆ#;ƒf¦!©êwEŞbÉØÕTï*Ä‹¯nÕª©’V®ü)­nUÁ´ƒáõÕ»0õÜÌäKòI?F×s9¼çıàm¤Ç½WÆ/=‡-áKÓ}P5Nd«˜•Øg:òëŠ†¢¬/ÖD‚èŞK„ ŞŞ<u aë¾õÿÌÑ¯£°3/Rª´i¿hÏ……°•ºfg(æ·0oF+“Â%İD«…ºî·n¤H·fˆsôŞÒí;Á**·:‹‘-?i|–„_§¤yöÉ7çn´ì”U,f‰òC©¥Ñıİœ®Ğ<<í—õ9n8şg(Ö“ÒSNP³¥&¢ª†^œZAÜĞÏÉ	M‚¹n@¤ââĞ{`ÜîğèÍ/Øèá¥ûóØ~ùEızšVPJ¦G¼p±•	*¾.ñ”%ÜÉe
Ü¬4†L³B˜‹rC”7DùI6f 7ÇNŒM©hwƒq˜´'0Îa›4H1İ^Oût¾Ÿñ”;ÃEaıÀã‚ázäQü9Š“A}Ù>n¡¥S±€FAÀ«7ÛAfØÚ©À×¥T’Æ ÙÇ=ÅTNó23»ğ«¶æãWÉ™Ímác;¦¼§—L{q½=Iy—¨¡ØNã2”¸äj©–Õ\-ÍBªØõtUÀ€É®¥ÎÅ´p5u.§j“Şr ı¨µµxq¥©A¬1‡Î˜b|’y»a:ÖÈ¶Àš™‘7#{ ©÷QrEÌºËqÅ•ò?k#tØ>âö,»ñàË`[9»Áf·Eut‰Õ!pQİKKtœ"$wøE„šUªÚ¬Y‡ôv£áú ü5B©Ÿ!ÆÜ0¼@ Ë k%¬›2ZâËW„&/CNÉJ¢ï-)«·‚¤:%šsø«ÂZfµ-•BÂ‡öZ¬eñİ!T…ğÀs´¤.±Ön˜]ï_äş§7ê&µÏZÆüüdîêõÇëÿ&ßßÿ|©ş‡-¿öGêÿ§'÷ıÿ…ûß´û’ı¿¾¶^ÏŞÿÂ³ûûß/Òÿ§>j¨Æh×c¤zü­í)ÿLøx­*¶§¢şÌä‘§:Ÿ$I•j@§Ê‹Ğ÷ªíoÅ›íı–g["ê¤“QÆ6–²´wß¶wÛ]›³Ø3PP0û§ç/Y›tz~ô#ı<8ÄŸmü9„—Nq%r¦aº”&“}®O¾Á­(«>éZVNYRÌ?aÙÑzÁ¬ÇÆ‘ÅzNÆ«ÔàİN«ıêh—*ëeõ€Ş†»òQ?zŠíÃãGØˆ\4ÀCTÖxó‘¾ôfEÒPÆÍ˜6UœS™­ePF—ûä"Şrp¬¨ä¯—á—ò¾v¾W”XrßË°Rˆ%jdZySç8ù, ×l“e3¯d® ¢ÈV˜”æøØLfu¦-007ópª…\Îë#Ş,›ñ~dÚŒÃX7¯ØfPÉùùå™àG¡ª”„±±>ªi¤ˆÁl’¬ãa†JKdjš´?vMV‡red9¬yÊ‰“„GTB>Ã:ò7Å>B.ÃkA®îR'œ™¢+Œ® à»£)œTÊú«\{([l:çºB°²êâLi×Væ£†ÁÃ¶·Ë¦'F¬‡~0EƒÎ8­&*j&%õ¯@çG"Ap±k4é¡4°E‚A à|F³íäøÛƒ#/k±Ò£Q§şïF8)öÑÕ}Õóşíşó?Ãşä?Z˜T½/ˆÿµ¶¾¾ö8'ÿ5îñ¿ŒıŸ}IyÄã@ ƒGâ‘Ñ‰†ö*bp7)œ¦1¯ÄyLÈwá3É”»êy—d˜òÀAw2:ãG‚ÌòĞÇàùø…·ô<™Ä£áÅ‹7­·íÍç5ùOûğïÒó~ôb/©zÓ.j@*MÛ~‰Mñ<¼°Ğï`]«É»ç5xó¼$mã†%]ôùK¦&¸7€EWÌÄLÿzJÛ+ï¸ÆRNâ“ª'Ğ,(©Ê¬ÏkXóç5h7¾?ªc€âp<	g(Eqáõî÷­6l“}8ˆ„éc–¶”-¤s”#êº·1ÈP©®™¬PÂùİ[<µ(úO4¹±yŞ¶Î7SıQ¶‡ ^ÆáPİ¦' X‚BUÉ!jæiÓ~gìš”{ÆÀZj’’/Ú(Ss¬p.Ô%ô=k3±8
D…ˆw gÄ!pªöPâÌò;ß£u£Goİ¡@f…j±jÖ{äµv)’(©>9{Ìœeº¢‚‘mí_>­Éş¾Y>(Í‘ÏxóËü¯övÅ>ÆE¹“ìTG¾[Úyæ¿tÚI"´S¤5¢o>$ÛÄg³£]ıL©ø¦Uˆ)Gì
âké¸=\cazh?¸9Ù	…¾ £: 6 l«/–:®¬f!‘e™»çDÁ—H~‚doÁ¯èƒ8ê]@ÏKõv¡[×Æ›!W¯x_iïÅ¸;ĞÿİµÔ·°ü·±şôiFşk4Üëÿ¾ÈçáÃ¯†gÉxËü×wVê«üPŠ?‘Ï“ÿ×’+•Jp‘Œ"SşÃ‡÷ğ!ªá®uÒ7ûù8õù±ç3ÔŒŠFˆğûğ¡R<Î/(ƒÆ\ô’ô-j!d½‹^LßH5Lújfi·Î'ÒœZåfTÇx-wNóeöÚUó­1H
(š 7Ô¯å›•é.C×i÷˜üÜ¥ş3£ %±á÷¨@U¤2nşˆ+î9!,éÛ—ä Y¼„lç›i
”­3	eFÊ" …­q‘ÇqHu³ECSÁXhl‹(¹Æ0§™¡Æüƒ†ŒRåêrÅjÁÈ·Ô»7]­„[l6M©f†,$emúJª…ÓxÆNå=»*Z[l?VzãYé­ÈÂf¢H×RÉÎçŸR:«&ÊŒ)îXÿìrmæQgç±ĞRYµdvîÂö+¶{´¢›™|sE·ÔtKU÷<]7—ˆË*é»¡PY#'³¸?9HùŒDheìÏ¤‚J¾;<Ì‘ÿkO³÷ÿë÷òÿ—ÑÿLhöQ×Ã®ü¿§aLjQRª…³øÂ/%¡-QéÉ7Àın†<ÏGışè
Ïì1P‹$5X¶€õÅäz6ı]_iİ‡4qÂBt+$ihëõUH”LÂ®Ïñ.Ï@Í<ÙÕ\§©^K—œŠV7ÔÎú£38ûÍ¸vÔÚŞÙoÁ°÷_¨eéUîy-xAà£óó¨‰ëÔ$»j©§¤“OÔ&×¬ƒ¤æjä¦Î¨9gXgÃ:™šàò/ƒÚÏKçAFa~ÃáŸw¾{&¶M<±YkTÜHpØŠPcŠ*×Ÿzï+Ï*ğ¯v°H¢îîuwmrŞ[”6B*Š¿şSüúw‹ì	évd}QDCÑı­Gxôp=ˆƒ.”‰¬ìr;I®1¬­¹£Ò&A|àM"¢GQDc)Š¢MÌ½;YN¬-=õÑõ!C—ÈK·7	 EğÄ@jU/‚^06äf£nêª t§×F¤+“ÚR‰‡×/00ÚZe¦ÇF]ÏCªTHÁ@
{jG¤ã™©,uJä˜ô–E©¹†r÷÷Ã÷ŸûÏıçşsÿ¹ÿÜî?÷ŸûÏıçşó/öùÿÉDô h 