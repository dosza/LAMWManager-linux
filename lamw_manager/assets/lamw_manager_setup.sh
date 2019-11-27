#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3254313481"
MD5="096a0bb057bb2cb9ed8b5c239ca443be"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21240"
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
	echo Date of packaging: Tue Nov 26 23:00:41 -03 2019
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
‹ ÉØİ]ì<ívÛ6²ù+>J©ÇqZŠ–¿ÒÚe÷*²ì¨±-]INÒMrt(’S$— e»^ï»ì¹?ööòbwàHQ¶“6Ù½{£–ƒÁ|t]ôÙ?ğyº³ƒß§;òwòyÔØÚÙ}ºµ³½Õh<Úhlln>}Dv}OÄB3 ä‘eºîõp÷õÿıÔuÇœ_æ¦kÎhğ/Ùÿí­íÂşoî6v‘¯ûÿÙ?Õoô±íêc“+UísªJõÌµ4`¶eZ”L©EÓ!ğóÄ=rxŒyäqÓ™›ØBƒu¥Úò¢€Ñ=2˜ØÔPÒòæ~]Jõ%"òÜ=²Qßªo)Õ±GzcGßÜhü-”MÛjxN‰*K»JlF|3‰7%!ôN¼€âïãæÉ+˜ÕÉğÀ`’ËÀô}©ÇpÒlDÉ©³sõ‹pR¡W¾´´ŸÉc³40ÔÚ5iÀÅŒNú£Îé`Ø<>6–H4Á[İ~ÛPÓö³A{Ô{Ñ~İnesµO‡íşhØµ_w†Ysf=k*ÊUŠ¡F@Ãğl ÀJõˆõv@'¡\ùÛPÅ’7Dƒ}«õ^èµâZTònwÎU*åäã0˜ßatDmcUÇMîùÛœ|rK”©­¬fq-7¸„p…Tƒ0 ùÖL¼ùÜs5vNùÖ((Æáæî¶E™MC:÷m‡²Çë7D©$¼ÒÃ¹¯ç¡ëÏ¯U$˜¯Ù‡UİÂ„­s:¹ €±ûŞbÏ"Ë#s:Ãæ(àŒÑ ÃĞ(•‰†}x‘OşJfõÅ°ø·Àö3Ñ-ºĞİÈqbªk"ßd#ÙMXLeYìJEPÇç>tÌãÓºô²$ ÓÑù@áç¡íZFmvxrî¡n¨	-j-QË)*'(¦‘µq«İà—®§hõ[Rğ9°˜„eñ`‡0c6ü«'”7]YÆwŞA2Ÿ¦(3>ujğe2œA™&T–Õ°–ş&Ú•šÎÖÜ¼ÎQ|»[tjFN¸® H3ÛaŞ©ÙDÂ§–(eíIªT²Î×ş´rÖçØ /ìPÌÏvÈçô/èê.ÈAgĞ;nşjÔâäuólø¼Ûï¡-ûM>>ÁURËY¶"{¹0ùe¨G»Kè•’z½®îÔ´R¿J\EäNĞ	!hqı¸b¾ÒXJQG¸H®PR¥’IB"™šˆ•¸)–ÍMa%İVŞ;7m7¥TÁ'NV‡¡÷=/,¸O¥’ib,°j,Ğù>‰:5Qæ<Dß*Ì`2;£ å„+²R‘M ,€“Ëá[Q“6–<úúYÿƒmwF‡Ôª‡Wágˆÿw··Wæ˜ìåãÿ­§»¯ñÿ—ø<÷.Ñ&EŒælÒRi®h3¡ÉÊ¯(•¡Gâø‘ı6Œ]L×‚ñ•|j)D¾1:À¿:IÀK¡¿*æÓÿ:*@8úŒÜ¿'ÿolnnô»±ñUÿÿ3óÿj•Ÿwä°sÜ&ğQ[÷¤9ì`Äö+iuO;Ggıö_ç£$éEdn^sñ¢Â›GaÁõ÷dÏ¦™$Ä>™{–=µ!'`†ñqcJ…õ|Y`9¿÷Í€‰¨NVŠá‘_"W©ÊCâŸhšmQÇÛ2
˜Lî\çæeÔ™3˜EH<#ÓÀ›ƒ@×tbd¢c:İ#çaè³=]O†ÕmOÿ2E%«ÈYÍ[í­ù+G–_ù¦ËxD{n&L`¼Š2µ›3™D<Ó¡À™:y«†ıÀ{ÓçuMÉ[ı8°ûj•¿¤ıç%‡³ú£±óµşÿ%÷‚…WmÙEƒ:;ÿ‚ñ?löö’ÿß|úÕÿ­ÿbı¿¡on­ªÿıg ¹ aâ¹¡	©áÈ ñmòï€Ì¨Kv BÛ¿ˆGÍşÉâ)ÑI³Ùo=ßİÖHÓµÏ¶¾cWªé$4!FÁøğ?±<2õ'qgZ&q=Òk¬7šX–[|ø{`››òb¥9ÛXğRx€tØkaİ¹¢To‚{h³p4µÇi%Øf,¢u—†ëXfXÈOá€õ¼°úD=Gn‘Æuõ	 ¦L,\z9Š8ÀÈ	/»îïóaÇ¶]‘ˆ¡HãÇ‡¤Ìœ()9ŒŒ­úF}#ç¬<‚…j‘±…[Ÿ";ˆbœºÌ°I.ê¡9cz@
ˆG[£Ñ†*a,£ãÎ³Q¯9|n¨zÄİ±Ç8CU%°ÖáQ†<“VŸLgE”ıöq»9hê¿l÷î©/ñAdé5i¤šqQlÿ\Ú~Ğ’¶ï\ôbwz’,ãê‡İhšƒ‚¢ÍÜhi]i¿ÊÅ$† 4såEÍ°Òã)ÄW‡sS T†~pÑ¥äuì{â{f†ş	…@‡E<eH4'@ğaö|üáŸ=ñøÜ‚'7ZÆ{¦6ÿ"K4v÷â—¼$5ä~¯b¯XÀ'L¯ÿ•tWÂtòÕ¥ıºfçòÜœ#·ç *šŒm=®”«µÜ •DU—ÏNÊ19ª­šêas=lˆ×/ŠôJ•g¼éy÷d\T!ß¥B~z¡,Ãá	¡€“Åé†ı³Ó$5äC…Åşk9¬h›õm®AMÁFËpµ›¥¶oßjOns¨ã£˜ìÏ^|dº}Ü9={=zŞ=isÁ`ç&D§°<€tH˜/O‡Í£[nKf¼­Ë{U}¬Ï~SKV—
béô©\Ş,/ô¶mÄr]ŠB- ¢*zJX·Ô”'9sµå ¡±‡ˆ‡ôp/¨¬Ğ\¬@^¼X˜ Å„‡+Ê3ljaœÓæâ”÷Ütg4;·_Z¨Ø-R)Yw¥‚µ2ŞW<à4XNæ?’Ú2iõÎFÃfÿ¨=4L°€İŞĞP5q‰íc•ti¿ˆ¨H«ß`Ë¨—O›DkM_ö^n©$¾^¿}ØymàÎTª|¹1¸R(ã¸%U‘Jv'AÇîY¿Õ•4¼ÈCôZQ°ÑøIB>üfû	KÔ^OÈJº÷¾?¹Úå>²ì<Ûq¸x‚L{Ş½=4iì‘C@Ë¤ı×dõ©İœvû'Íã[•«eCÀ[¥’%–¾š›ÖJµ_ÅĞ¦öÛÕbºª’¬/cÿ2|f_yY—3«ÕCé€V°A„ë QIÀ.ëB3˜œïn—êÃCYÉvK»ı =0ùü%’Ÿ×ç‡KÒ^Fİ]µò~Æä©hR’ŒG9š	–’‰nÊ½ÌøÜ6ác¹Tı¸íC’ïÙ:\DädÏÍ‹íÑßFøÃ6‘;†dQAVnafÓØâ™ç…ƒ00}®lÉ:@†ìY ¤··¤6éªËáqóhtØE£Ù<=èw;£X
wdœÂˆ'!kn¶Dõ%jPÃg—P“¸Şş)ää<</™’Ò—ó¶$¦°*_Iˆ•ØÕË²q¥2 (&=sraÎ¨ğ¸íÃæÙñ¾Qj[/’„İv-zÅ/½$a ©İ ÀàM÷½»ıèµæÊ„Ã_«ìÿöõ_~Íˆ‰› L£–®ì+ß]ÿİŞ]®ÿïì<ızÿûÿqıw¥_ÍtææXÿ%ép->o,‘øÖƒû”ùËì±Cym—#ÄƒŞÜÅF]<&^'.+áuµzıËp»¤XÀÀğÛ¡gÎaMB©Æ•,“ßµ¤êx>?hÿFÁ!ınw8ÂşÌ	~ƒx-q	ƒƒrp1¿ ÌDós Ü'ğÑép~?/=Š¨¥ÄC™W˜V¦Şš\¥Ô÷î²÷(§³Œ$„Sr÷ü¸’<D%?óıót‡Ô5AlšÏBïÌ¢ÎMBüÀvÃ)Yœ=ü:¶OCØXı4‡Ãşm½¤®å·ĞüÓËöéA·ÿ3ôtÚ†º±»»GıîYÏP}'š^õ­»FÈ_!d£Tã#¼ãD(~–¾ÓĞbJë¼	i`4Xà5\$/c†@ñ¤U¹†P,mšÁ_"{á¡§bşárİó1ÉRPrWTR•ÅO®ŒÈo¾úF4‹€•£¾«–š—Gˆª\N*B—Ä"‰ØCÀÊg@¶¨§«‡lı4ÍxŒ4©ÕÎ!¬Ä¡Êm @H-šÒ%yŒóñôÚJ~@ì7ë‘ñnRslkq÷¡SK•Vw­İwÌÌÕœé1´VL¯ã6i€1aO‚æ~[Ny¼!n<(à=Ï\ò½œ¨íúºP4B¡.ºE•!.‹U*kÚa”ßø³F^À1Şb9£áÚGĞŸ|Â˜ tÖÄ.ÒuÕÂïuEÉêàQ$±-$UĞ,¼!F$9Ñ¡Ra\7m—Ú.^d.àÀäL¢7ïx¢•ˆrÅİ¨3éHMîÁ¬¯‘Q‰	.Vh.(.lû¡Æ‚ÂÓ÷f¦Ç–8xhB’áZHœãÆÕ”„>•¨u*!i±>®V7-¬:ÇB¯xèü¸	ğEK|lX´Ü”E^l2 µ˜E< U¢ÏXKj ¼¶‹÷jGıæÁq[ ‘[~u\°y!Ä$‰è3Çt/p'’w$Râ	Ô‡ÄÃ ^@Êòn«5™ªôœ.%~—¥°t¾ÛÒ^çzÅ«+¤˜ç'o«ÄŞé4jòx±Ÿ	Y¹y47™µÉ=8ÊvG&Š–”µOÄXÜï;Ñp#_‚$gä2šJaòêB¼(ÀLĞ5ÂV_òAérÇ)cOÊ…`À„QŒû×øÌ]f à{ü˜Ñ+.F©v#°4ïÍ¤?b‘ØQ×´ğ&^Dò—Éã1àcX™YWD%³{éÒ é8i¤'F=×¹¯okˆ!‘¾j¡++¹#Ø˜K7v|¢:5å)daM%;æo±Ë˜{„%—öof{;±ÚÎAÌ`xüs³6À—<·…1N
)+©H§Šqæ¬™4M©î—õ¦z^Ö¯eE/'RT†Õ{yTá9/‡¯£?F‹+tòŒ8!I¢z¼»ï%ä)ÛÆÆ¾ıSí¦*1çÍ“w·ûöwß­¹ÑO„^2˜ıîV°x£$„{ÙO¢õ—ÇÆw{Še­ËÀñFîŒKdú.ÂÛÓ±7ëˆFÉe ¿‰µ!Gn]ªZB”;xSb‹ &å*”¦œz$.ù½LOÒƒ¼²V~z¢vÜ©·‡{ªŠr-ÆA{ÅÒmÚO.½à‚ùæ„ÆÌ}Õí¿@8ÜÎàâz,G+›+f]ˆ“şÓ|?˜³·îxy‡æ,ÇÙ=>IY›Q+4ˆ‰O‡ÙŠ¥ŞcLûóÏCÏa·{<È –š8àétF*=ğNù2HMÚÔ˜‡ÂFH#¢XLFƒ³^¯Ûwˆ’*v’Ë¦†&q¯ö¿Ö¡#ÂW(ÂA2ó¹w¯A¬ÔøÅºXÂÔô®ÂiwØ9üu4€pSÜ ø¦p… Aà#Dì­{‡|‰ÎL¸È)¯·îjÙÊú(W0g÷hï~^¤6<ÎˆÏrröR\5Oş‹{ëò—oÁfóØ ¢c’-³É9u#‚Q36‡'ïÚŠ%—;\‰nú¾“¾÷FÕ	?Áäz°o0„‘ƒ(åœßãûÇ.D±°åK9X8¥R<·çT÷E}€•Ö]<ZÌ›³Ûe¡çó;3àoD3iãË#ïDî¢šsjd[¢¦¦Ş»Qm_ÑIîè´Pänš<7ƒkMdTOLÊ}<Ÿ<C•E9¼ƒËØvR‚:tYy8˜V¯ÛĞÅxDläĞÕ¡‘Ò`n»¦cLMĞ0ÑtíS£™í[Ì†HÊŒÇ†TÜ‡Ùö—!¤áBq4|±tÖ^Û3àâ¾°û¸¦ÈuÒrLÆŠì>íäd…ô*Ô¯4q‡pŸ?ÅÆzïA†5ñOÊûl+‚¬ 6ç[ZŠHˆTi#–7.ò=Ï¢0©c^‹U¾ ×`k,fˆÚò~O¬9tP?‚ÃÚÜÙÏ3édË>dš×{{¯µmí–² í«ò÷nŞeû÷ßƒC>ŞğÒt"jÔiüñµ&îÖjø–/P«xøš´‘èÄ¾­4f«İÖè¤}z6êÛ'IÂ_ªS˜çCÈN¾»"eã Û/í€iĞçp!´/†İ?O)  ŞÄ6Eõ> Óô½¨sêøõ™ëÍ)¿[jZ ×:»f!küA›E¶EQ{Æ°Z¬‚]Š @k$ñõópîÔÑĞ¤´eê$lvº¹ˆ¡~5w>ÊÅÙŸ~™X~$ä(Ò¡1›³Ña“ÙÁ{0îmxıRQqºƒÎi‡'JÙi<á÷D%eaY“‡èÓ l :P¢dJÛóX(Nì¥(İs¬QŞİêı.Y]òEC™ú³ü©@L®í#ªerd/³((ˆÊ½Zf™ÄÔ• KöŞ\˜IäÊŒÇÙµØ÷‹¹Zí¦ÛkŸşÑo\<¿ÕÀ@¸ï­Íœ[“’doı°«®çæçJU“¶Ğœ(æH{ó_V¡ôqBÇ”xfºç¼à¿ `éH2ŞtC’'iU¤’µß$?¿Õá×Àœ¤©ÄÆ"Ö>|ı„ K!?%ëë¤JÍÿğD‰$ÿ*ÉæÎ%°µ›<õ…6[u	 ŒAK.öåÄo	ò7@èœÜsü!Ê$‚|ÿñMŠ@NéeO8+aÌ±L:ô^¥³2ã€¿ Áøÿ/ĞcfÜ[DIJş£ø‘AhZ±ÏáÒRÀıæ})‡¤Î86>Åş\h¼3ÈÃ°Lø|Q-©K„ØÆR^ÚçVwğëÀÏDè ®­	æma‡×–ˆü0rœ˜Í<„Ks·@XÂÍ8‘ãC*¥[('Ù½ø ÅØHFğ+;'àûÁ§£Y’¯;ÒjÈêÄ½ÿÎâ®:Q°èŠ‹ÓÚÚGW?’¡êRSü{ x†Bø™
ïšto GÔWk…Î”Z<¹xø¡3y‹ï*¯ÌºĞ:6ÖAÁZæTR-~VÆáD-a*ùr7‚Ü%á\à´jDbÕ¸ãQ“ëäË„IæM¼rÿRV"ËîÈ*•å¤£
®nôëêZü‡¨Ì©a|¶ôOµP>1L¸õ7½Î¢ÿmïÛºÛ6²5Ï+ñ+Ê ;’<&)Rò%’énÙ¢ut[¤”¤ÛÊâ‚HHFL< (Yq<ÿeÎš‡yé^ópæ1ùc³÷®ª€I)²;g†\Ë	Ôu×m×¾|û\*áP_õ“'l«²šxÁUöôkŒÊ2Õ(DÉ6ğ8¿ıŸaó	ıjŞyºÚZiÌhR*ùŠÒÜÁq% êğ²%ıö?Ù•÷sà‘9%ÇZ©xg+=*{ƒ <6U…x!ğ_#­UJ‰&=¸¤t‚Df×Aò•İÔ¨¹â*½­¾ƒÃ¢ëı€2¡Îw„$õÂŞk¸Š¡€£ÎÉBù/ƒD2Õêå0<‡=-fjğ‚·W4æ´³ÏÊT°ï•oº'[TWpÛŠÁ´·+†«p¸ğÆÂ­çˆƒ™ê·°O¶œ)Uvfeµu£ZÑùÆ Êœ´F×ÍUOE.˜¤bm”ÑİRç”T7Vêgo±ê³ëƒ•\¢y9±!ÖœÊrşj7„Ñê+n‡:7”Í¨ÊC…4¢tuŒ9'”3ª&êhDD¡­<½Ç‹Ùhª‘…nF2ãFm£ÖçàšDkMªÙf)ÉùH=™ÆEJ/ƒjt‘OdğiaZópÓE‹‘œşlÒï%£‰$’éšáùO°WÃiÑø—aŒ‡ƒˆ#–à>|Jâï«¸Ö’Áÿ>..Ò_Ó‰ø×Ëf0îãWØ¹Q«?hr¹iøé¿š7¹¾ŸÿÿSä‹ß(ÅéÃ4Éü¬EñOüZÇ‹oèÒ¦}MÓ¨â`iÅ‰öU%„¼êÉ{^BÔ-ã	.'CX0—µIÂ )‡øyç½«~ìÑw_vûöQş`Ytí'¼?ÅáX¤ –÷şPû**½÷lDøŠò5şşzƒ}•?…²š0gÅ·Ÿˆ	¡oòå4Q_Dñ“¡ôv®ë&~›ü	ı¦#ñf	ÿŠ0,ø—uŞıINÄYì×Ç.F#š8S¢W÷UúM$M&Å€¤x´ÓÔBòâ|Ò¾Š,)á¯ıó`0$"’£±ğŒ9[z)‹Ûr3†›Ä¤Ya£.}^Ê_‘Ó,=Øft¦ÒbäBb`_J“ÚgpFnÿ6k‰‡¸ûÛdóê&”u^Î•úÃˆ3y783Íp‹.*•Ïê"*awêwªï’®dÕÍZãŒFjüÂİŠøÏÖzQ~é6,<
³Õ-Gfò)kÒ+Ğ§Âá@r¨ÔI¯,=¡S]Á¹<Dd8 üÄèÇ³º$‹mŸ7/r80SÂiï‰ë»şŒ8 Ësƒ+ĞÓfŸÛm³µk©âßÅmW™#J•mŒM×“3P)6É·Øå÷ôBÌ6,VIVòbøzÚ”šDkå."Ï‰Ïíùb¢}“ùÈîµ¬’¦nÏÍ2Ës|ùy^h ãV>ZRãc0€<ù€-š^,¸hÔ'IÜr{tÓ[œX³
ªˆl:w).r§c‘S¨•áâ/,€Š˜õµªB3‘$l®š@wÄÀ@hhBÄˆş^tÅó}|¬éàı°Ç·‰Ö¬k…€y^L\–Úsç‹Ïøàk•”ù>h
…öÑ½0
.ÅÍÇÒir>¸µ–¨†‘YLÁãÙ[ÏÂéÅ†ô‡+¿ˆHÙœß[ÚàÛÀ>cì¸Gs77ŞR^^da:óeşàZ åğwW¤wÀQ0‰ŸlúC³˜Û –QXÂ\–ÁÊŒ¹dnÛÏqhØf€y¤ğÅ‰i‡'‡’ä^äS;¨ØYÅ”ø!ÁĞèh†×™Üùºí““½Ã7İâ”“s±¾‹_Ğ^<â.=–İ8ïÌãèV¤•ÓƒüqbËî”ò©Véœ­d_°_r÷n\?«WòP1õú%ŞËÃ8ŸuÛ^"9îoC{oåvd÷:²8å}L—#ÃãH:Íö7ºw£¬·üŠû¾FOuweoĞİrr¡;æ¾BÎgòRnG™ÔlRõ‘²]Á~çHA[fÕ¬N[Û3¿Óÿõ&€cxˆ¥_×t“”[»ŠİÍSÌâ"vïb‹;ˆÑÚĞÀÌ$C¯sóBÓ.f5çíåé'M´3Ì£uf‘àv±È¥Ü©á`Ñ:ˆ_º{?fV~oæ”n¶ıcş¤ü¤Kl˜EŒs×ì˜æ‰Ä…)¾ıÙ_İÚ*bîtT 1ü¾ŒP’ç¬ ?CDr
Àp8â^–#9Im=æX¼œ€Ms*/®b2Vc­ã›­I¸Z?¸Ï÷®…ñú1yÙÕ¢µ¿kÍ@Á+•MŸ=™g‹D¢ºQ‰­Ï.REîïâóÎNçoiÁòèÚª¤o±š2Eµ”rsE«—@ğW+×V2/(Š‘+  ¨˜co/À”Ó
\$\ô,¦ãa>_J¿•‹ }\K+ü‡!“}Ko1”hò%	ûQ%¤kF Ú€'$ò‚îšü]²ÑS¨dK'moËŠ¨$¾ïÌ+MPÚ^}C|PÑ‘±O_*²¦õå/?~Z±Ú¬BqŒ«L7y.Îˆ›ÚÁ$¼æò¸œ­¬´Ö÷ÇWÛ¾òüÏhq,}ÔÜFmİ…@?À&ÓrOO^WŸ¹~A½|Î"ÿQzŞ_Q8Fü#?‰éœ¿Ï÷ym)^·?sëïÂ‘_'˜›º0N“â_ı+$|áŠ²„‘È7öF¾*«hÏJ3?¯[ÚH¯×E_tK·,ÄÖh5ñòÓ‚C^0=/`\¼˜m±9i`ğm­#KùÜÀºYU˜6ñdÅ¸‡jeUzvQ]Ã9¡Ï¸í”îşÂ¦³>;“;xVY…qùÎÖÜÒ£rJåÆì3WÖùš…ù
0.iu¸L°Q\@Á¡AMHØ¼m,ø±.V~Ì}‡‘9EƒëxÊ°‘+…“şÛIÚÅ3>×W48Î§ÔÇõâ5ôQ›ÈÎÃâY0ñ&%F#	ûÔ4[ Dé’ûK~O0‹mP±'<¿Aôw“œ&éç¢|ó@ùÏBydekÖ³_2ş_c£¹ÙÈÅÿj,ã,ñßæá¿]¥øoëµ†‰ÿfA3Â|9ŒF’Åv{Àöx°1ó?ˆà\piˆ<Xmê
î|CŸ‡ğRá=øòA¹,­ QÍ—ÁxsÊoö^îì³ïv:{èÔŞåÕ¾
‡a„.Ÿ2JõwíÎn»UY9óß6¶7š£2ü`§ÓŞ?â¯ÖáİFú®{úâovvñõ¦z|Ø~ÓÙ;Yir	$«ª±¼ëeR²M#áÎßO÷U›és4+š	wOzûG¯¾í"ëäÖ¯<n¹1˜¼¿Ä#ÕkéSo‚òÅ8‰ÍW}¯ÿÎ§—x©ç³ª«:şŒ®³æÄï€»dh`O±Ğ=oÀ)vè/ãQ©[+¿?ŒUáæTîhŞylLÎœ2Zæ#`›û¨¾'·;
+ì÷¡ÚyÀFDŒéâ2'ƒ<úˆSTÓ”İ°i€·Ç€ñ˜Ù*²—nÀ±Ò8sÙ ôcÍüË¾zŞÌp;”_šrÊU’<¼˜<bhÊ"î ƒu]i`·I”‰n2ğ ÉéÀİYi5QY,oô”L£1œëÂQı"œ,ŒXƒá#úéäÚä¡Èİ[+‡G‡íÍL’¹•fş©í³SHš•æ„Œ•À5#a¨ âò"«Åºàöò€.‰¾’¼–â‰ÓÏ+<÷‘àe/ºŒ'%ĞUş&JR$BŸ¨~feš[&-aƒİ´µZYí"÷€üs¨¢â®Á\¯¸…$ºÁl¡Bé<AŞ£µºf›€_}•!¢LEeñ¹§ZKÛU´ ùT†éuÉ	­*­|„¯õúY½Î>­éP÷"Şö‰ñ¢ 6%¹¦Tæü¡Pèa·ùÖ«ş¼Sıûzõëí×L$- ?äÂ´0—şæ'°§#Äà£™mUÚÙºâöÒ l'E:áÒÆÜ‡†Axg’ÅYÙt÷÷NNÚ»½NgçoXªÊF•NvsĞµİP²Tl‹éL•tOÒ:Z•Ü#`Æ¡O…Íáæğ\n:7™°i®Ğ/Š¼œ¤r&ò^à\X£ĞD•’w~N§4ÚTÒï¼iIzƒäÈi©SUF9³°¨¥8Yp/Ã0Ş ş1*Õ)cRúÊFÀbhÒ‰ã¦~ƒî>EÎ„RiQ2´å kSŠ¹µ‘p{ÂºZ•Æ¶ú­V0¬¨ô)?˜pİ·*ê©èĞT,Z°†—Lj¹X1õRÔ@B,c	|	l)C¾óğI!²ÁéIä^¯ÂAÃx}4?2éO#İÑo*61
€Å¤ŸdAŒgÏ…¸ÉÑ¹õúŞvH8NĞÍKü¦±A ||Æá$à~%ÕIÅ@,<MS‡™ÕÈmNŸWÀ·:S2ËßèÖ%b¾òò–ÁğOrştîŠm yíMŠ˜±›feÊå2-ç´ºìÒù³ñºoË6Ÿ e®ôÄiA‚;*œZé¢.ÇPµ÷á†ió‡8#™Mg”0ëÚí¦eªı}#£ì™˜¢…Aú¹#'y¡ÛÍ5¹ÕfYQ™ÈÆ‘Ze]}_ĞÚx7Ür¾ın"XaJouCĞÙ´Œ÷-½ÿCyÛR‹nç\«Ñ*>buÂ0‘Âaw1[è‚5â–ĞØÇ›H£‰'
k†R¨@È›x;›&Ô7ñ‡!GëÔ°ÌDdq³ºFŒOî×? Ğ*ÑtL¾Ùœ}FÁù¥ŸÛpİ‚õ]«Õp
½øª	äÂÿéÎD»Ğ@È;B
fB'wœ|¬ÓŒÎ‚;ø¥Ÿh«£‘„GSSÁyîbb]xìòl¨®Ê¸†¤Òœ½ÏªU8Ï÷uÄJÀ·¬¢Ò@…NQ¨*[ÒÂ6¢Œ´ƒ¦qc?!€²ƒ?€yºyÀN¢†(Ñ×ro¥íü;mŞMGŒ"Í:(kœ LŒ ìp;÷±utDaßã0~Ähë‡9Š n±wéhzÀÌúíà=ĞŠ£CN†&îR/§ñMfŸZÏDštÆpl&çx$ÕµSânÅøàíúòı(¦«ğõ;œ:ˆˆŒ9¥LçüXóùWVöÇÿ>E!]h’Åyˆ…ÒŸNˆ*5ì™²ˆÅAEÌ>lß{ABñ*î¡P*a«Û&T(¢èÆS«ÏÄëÃÉ\w˜‹vÿDUÄ˜ˆÉ¹Z½É	¯ÃëêtìM±E	º"øƒµlâ,ÈP½>TGÆrºT6\ã”V'>)òc5PqváhƒŠm¯|T-§«¸¸‹Eú[:yTâˆ‰Æò,b{ı3ß\×õ=7·ö{Î,YÙıûYxªIä ’ş„Q	ù£OËàA_$ş˜÷û}ø?Ÿ6³ñ6Ã£¥şgÿı®ñßÛâÿ¸ú,_0ĞÏ+ëİå.
RZ°ÍüäEv/O"”áœ@7gŸÀù’•èÈ­ãÖ1n‘Aó~Í„ZvLãÔo5ÍGzé¨oÉÁ­R\Ç1n¹ºL]EÆÏG€L˜51ÉFg­¬jt!¡b2·7	>¤Ú"‡Ğ	Â5ëD\ç*-Å	P¹lgÓrL5Ö=	ï.’(åI(ÈîÎ¡İ‘ˆëÈí
ò!¢‰Y–¢[ZUÎßV¯ÚoñÈÍ•’	ËbAAy€5‹iù7ğÊƒ_š:üß<@fCæ%lÒ(…*]IeSyIë¡-&®©R/Ÿk„BWÓW÷PCJsÏî"ùÙhÉ²86)M&‘9ßìUïÌ­ÓÌ®T¤ÈËÜ€Ö°›xÉ4æ6y§ÛmÇ[7U–HığÿÉi—4sJLB–fÈBã7ÒW‡G½7§{|Å‹7R|½-ošF0,Í
”¾ªB2G²ÄË£¼Ÿı1^}HÌ÷Ûüö¿a•Æáy„â”#S·:~²IxREÒj­²Ê*jµY®5¶¦ïöB™ÂcnıEŞpŠ#§®#ÉPæVhU­šQ•>}9Ğ'ãHŸªÚ‚‰äÊP`$6k™‚*šL0)‰—¾ÉßRW2¢ÈÂdX±q-óŠ/@¥©Í ÉH-%Æ1~õÎï¿o“Xêƒ£‰Æ™÷Mı^Íé3nş½³Òîîœì}×VqÑÔnÃ'ş–$ó
ËÁëYŒİ4#êlÀµVa•ÆÜ×º·h_Ø14C›N°d«°Ô­)îXÚJ^¾ˆb’£^Œãwá5M,IÅømÔÖkë&1Øj¶Û»½ÓcÜİÚx2µiğàÛõÏú¾^?šøã¿î~ËDgï½xúL'ÁŒV3	·û¬
ÿ§ÃIçíVúvÅ>Yq—”#~ïEpŒ_ni¡›esŸIë¦˜·Ğ<bÓ˜{¢Ñx ¢6S@µ³™PÁ­Š|°Ò•4â¨§œÑ”ñ éä$w54¤áXêq­mRmâG>C^îíö^Â@0½.š”º…‚ÀŒ™µµ‚Ú ùÈê9ì§ØşĞe®­6©¬±¥ò¤Z¼}n‘§gÓ¤^ĞD\óÿÚà;TBïÒ²ze€èé8à›/¢õšcïÈwˆè{:VÏ¹¿6Æub8/_À´{±ØØ€"Vıö^(Ç&35pek“CŸ¡b·Ğ¸¹¯!ªw§Fß&qVœ"Î¨ZL£K_-¯«áPaó6éô:ö“¿vÚÏÉÙ/¼é0qğâ™ïò'_ˆ"P—¼ëá(¡Ú›oÿûúùkJ
IfL)&7¿¬¤¨ØpVªÒ•[Bd µë ¸4E…sUÂ¬æ:@{2‡q¡RWÅ(ní: ± Í'ƒM-ËˆZçQ«`ò³q7	'Üf„Ñ×S{§´+VXÁğMç¯;ßípŸ.·’&Sµ‹ÈPã¶s1Œ=
µ©‰UŠfSµ­qÍšI’)KeàObGüØõQwˆb†8sŠÇ²JF“ÖJşÇe÷2:Ìº)ş2İ«÷w¾?Ø<eöRãfˆX3“ª|ÈÔ”çL–.2Í¬	@©Ñ‰ì=“p#E
G$|aÌü<ş—ahK’¹' ÏÎßÑ£Fgò¶…’”´Mü¤HSÉû‡¸êf„æU%#87Ìó$ê‚jÙÃ%Â/äûÇbIV¯ÛZÍÖ+o÷{!5ûÀ¯FKí¤Yæ%³fOg³•B!Ír§r²ÙóPlY6~Ç±M`­ÊşŞË®¼jïîœrB–˜¸ñÄK5èÃI8õä'Q“Wİ1ÿ	Ü`F¶a¨¯³·*ÿè´®©ËÒi·İ#°an )½-5Hen Ş¤XÉhP•ÍrÚÙo)ÀâæV…Çğ•»h¦Ø³±Yß@¥¶DvPµ03úˆØ°¿÷ª}Ømwzƒ60Şx«V‡AßÇ´kÃÅQ!”u BÉ½<‚´z•Ã†¦ËÖz°s¸ó¦İé½:ØÕ*~+¾ M¸Ll¹qw±E}¹¯’-0ÙÎÌ¢›bN­òÄªß+Ü¦µ:¿ÛH`©¸¼¢Ón%õeóŸòùŞJQ´Í×±å=g-ßø‰. DŒrCâ‹.·'f‚’f‚ ä%ÀEØ"º|÷4¨@3{´[ÜÊ„ıŠÛJ§½ßŞé¶ë5‚§Gc&wbí5ÚšÚ+(6?((çÌj§8K)E­‚¤3»›&¢	P@U%¨Ì:SºYú¹f‰î,:Î,õ^tÍ&”Å%T	”_š³œ!á¿ç¯3³ı–€ÒÌßÖGá Á] Ô ÕCÀYÊ0ƒ;Üšte
m¼’K/ÕÚ2æ.Um‰	A…0™İpd‡ßÈ%|áCŒ"'Ò¯…=b	T#&Í‰teê“gFåsgO¾Èû2zÓ>áš¾×Èp`ˆ"1<y-cbi÷…Ë ÚÀ‹ÖªÛ÷èÊ ¢/èÁ0‹—,w8+OU¯z=†Àš‘u8,GÓ,Ì&ƒ°ıŸ³xV7Gã‹ˆ-­yáÔÔ>=Îˆl_AlLoH´³t\¬úM¦Ã!ç±°üÊGõ^3«ÉÎ¼Å§=?š³ïe9ñôéSVí\ĞHW€Í£…uÍË$=·­¤*^¥wkÔmZ%n¬÷q\À²ß''QpiªÏ3êŸìõş¶B"m9j¥nb±%ÜàÑUqBÛ‹šÇí9a¤&kf¥µ…k­VkÔª¶ÑŒ‰-Æ	¶@ê™4Ö›Ø1¡ôB#a(aì…hxO‘¡å dºRaÆá2ÄUêtåìÁÎ›=äIv{{‡»íZë¬ÌĞäÂğJÊBÔİÁõJ32®cŒİä·FAˆVûÀdl& ¦!8L?o‚¶%Q8|ÅŞ'¹ğp²Ó,z®ê9;ï÷áêB4S£‹¥›Ù?™ñÖdàŒW³ÉÃ®ÙymÒ)¦Gh›E´&+wÉ•›‚/DBÃKH:†ï<ô†=¸{Ã&[…/pö£h:IÖE“ş¾w,ø†\cğš>ÿLŒÄŠ:3ï3t´åæ¤<Üıv±‘[f«wİ0¶ˆ²›IEm¨¹ZœuS7U(®”µ¾¤8½¹3&Pú^×ãæì‰u†4™sl-¬™’-óÓt´1–-ªŞ)(¦Ùİƒ%x)™Ñu‚‰r²İ×Ê—çµºÊº{oöO`÷âBZÜ7<†ï€·5E\½ù‚$÷Aœ6'¸»ŠSÆW¤g|ªƒD[¥3Vğ"‡Y™n+‚j^mV7yì1Üp…‰ä?( zN‚>¥^w£æãZ³öØµ%Rb1ç;Ö.Ãğrè×€ƒ’¤u˜‰aŒ@z7üTé‰ò8:aÆÓZ2¿åg ù—#F}vR1Âé£xçÎß¦š–F‡mI§sÓè‚Ø_²ÏR–DÛj ‘˜ö;>ŸÈ½Rº4¼Sº«ï/¬† Û#n7ìİX±úö%‰î…™3ıf ³˜Ş¼òã¡œşµ$ÔmU]g®èVAqñ›º"ÆBR—IèÂ²1äˆè„…3Fï¦XÓ­Órìø]jNµ„–‘ºÓXi£•š¸1Í÷íví›İã?b_3®.°†ƒt{×Ä
Ğöh|¿S„nW@_ã0gí5ò}oÚ'na6ŠçßSà]ş²®^¼<İÛ³…û`ãŒë|‹zPÛMãÔç»‡oÍ%OƒQ3=æUa¤eó{Ñ{?éq	,êE3x“÷=B~AK¤9ÔlâÁŞ¡N°,$´íÅÅƒ'7w{W›iÈ¬ë¹’é8)ØE€æÒ¬¶ğ¤8õ+å¢[lÓêËÛò†è¢{äÇY%Ğ¶ªl•Ke•ßJÃ8s!­|´.² äè¼j™‹ÍŒ)+ Ú|ƒˆ	vQIŸ”<ÜÏŒ4nÕiÀĞíØÜÎÍNÁ5IRÑ=k‹úÃ4qVï¶‘[©ÜLÕß‹ $÷Ìävü‰D°Áfx¦üKb=¾¹ªıÔÕiÛ¤¶Ö][ŒûÇ/•ö¤ÊN/5İ6xlg¨)÷VºÀhÃ#tï—Ö[ş ;ÎË:oÈcE˜4a˜g‘/½\(KÆ #×ÃÇ#B´N#¼WÓ¿=ĞVÕ§Ì²âE‰%j?Ë’1ë§»b6Ô*{şq»s=ÖTŸ[éWVívsn¾‚Pi2¦,Ù´˜“É˜xcT¯ƒ”YÆÅqañ„qÅĞuQÙÁ!+}±Ætó)nşçz½"áYp¾N¼qlÖıÊ–×b¥o^VYüÛ?¥ó=óÑ[åŒ‰C‚ggä©,ùfmrPó„ŸYÚiV_Pbq ‚ş;ü½ÆÊ:@!/`ù¢â+(ETØ(#†É‚806]…eŠ¨Êe9”±,éhÃË«É <J6Ëƒõ%¶Ÿ£fìåÌš•35²4¢¸Áz¸ Y¯Öu„	_ ë,MaÆ¿!š#IQÌ{ÿˆ1`æ¼ağ³'¦˜¬·œ¤áÎŒ	ƒbå8 ı ¥ŒÙ½\xÍb$nØ`\RLæ ¸Gı}	sAE%$ä‰„Â$Æ‰9"¤4+¨VŠû4ÛÆSYVFåÏZDzóş+eªT ßÔ†Õ>"2€e£ôûg¾·ğG‹lH³}ä%°¦zÏTûÒÀ¢¸ğ~†M ïğdì†@Òkr¶Ç–ÀĞ|’ô6zë½õŒWÚÕs³24'mç„%BÑíÚ²™iË-³)ï§ªv­ú™xŞfN«vV¶"¶şÈpæª2ã;'03\èÔëk1¿#Ñù•3ñ°ùÙ©m7ú‹“ûC*N"CßO’Àîü¬ÖŸ¸	¬X‘Ä„H·$kzµä4|{kBİ6J0“öt:¶P»ÛL®éŒJu9ÍPCZšìI‚ÿŠC“–J/‘½¦;Ò ø¡[U	„½ËŞ.Ù}„‘6²;»/“ğtà_94á‚ÄÇQÜ/…!kjí{t=ö#`Ñ¥•oyÍ0ªáôPntEÑîØ<FÒŒeW2ƒ)q®«qk¶KK+6BénL8©™=¼Ğ‰{ÎD_ßùDîÃàŸl®•ş¼`†)Ãv¦­˜İûK°’Yf«à´àÊsb÷Ë]æTr•¸V¥¨~(Ù{Vp q«¤Ûìí…GÛ}lÖ‡ó¬ı»<w…R:xKI™,_a]°êÌtª/ÌîÖÀ´LM‹,GÍÌèd÷pâ|ÓÃŒÃ'z ]ÜoiæZ§|M¿§—‚øòÇºÉ*âèıÔq5{ô,0¼îäÜ¿¨¹ƒğNÍúô¯»óM4O\v]0>6 ²xS%´	\ n¦¶§t†éMåeïï½Ú;éí¼:2zG»m¸‚—=Ø£½˜ÁñÌ/×âHÍUşnV¸Èë»¥¤]Ş¤¦vNë³HÈÊá¹;1GâóîÏ!¢³8LËjAf(åQrÄˆÜ½ÖÂJùryÁØ˜á¦İ†í4$›úcôÑàœ‘“=s'7ª£¿ÜˆD<2ÌFèÙ!ÊîÊ~ÂY(g$‚6é"+‰ /
<4v§`hôü/B?œìG–e#Îš]CQE;ïœyg€íÄĞqQéŒƒ,sŒ9§–õ€Ì³ÌëÒErÆÉ+–0wŠØÎOwÄ«LÊÓ†şg‰ÿóôñãü7ü¾™‹ÿ³Ş\â¿-ñßn‹ÿVï§oEqãÓ=Q(nâHñ:k06[ÒLíúúºv\y!·'ƒìµó¨>€»D½‹aª¼¶*ÁWŠ²ÃqÚVUÔ /úB¨pùLª´Òö¬®1%"èOÁÖ¿bˆù	{ßÑÁq§}¼ÿ7Šä/QD…{ßuv»oéë+üNœ2æ,LQåĞ¸
ô™ ïºfS…K)š÷Š¿UÏ›è*Lˆ­ĞœuÉß?º¢Œt¼ÊˆÀË|„¶~b­«>d?jv¤Z‡0NĞàxê÷¨Å–Áu¡ZÙ94‘»‘qá|V}ÍŠHÊôç‹ç¨Ş*G­~ûZxYÏŒıŸ
xçÃšŒâ/ŒÿÙl<İ|’ÃÿÜ|ºÜÿ—ûÿñ?7løŸ'ï|ÊšÎô1@­'‰qb\!—ÜYüeB¾¥² ‚"¡5.£œÄ5¼¤—T‰4 Y ¼öĞõT@ÑßÈ{bÏëû»¢8yÀL¬(au›ãáÑÉŞkôR?ÜÅ ¿J¢9“àâ¦ŠHék?´x˜¬¢öj)éÉı+”'Ó]ò¿§bwÍQœ²GköÜ¥§ÜÙÙû;Û=b;/÷Ú‡'m>X¼Åñ
,Yı§û’YÜgYİî‡İ7½İ“ô=è¶´ğ½[Z ^ş g¢½t«`À¥%’yù}{ÿÒÃçÁ0ó˜~ŸÌ™m•(˜s¢ì%gÉqxíGä¡ºëÈ†°ÒƒÈC§äŸ=Jé¬9¼\ÔÑ=>¦ºÏ’‡víkJ†N	*Š5ÔÖ7ÙşI7÷âYö×	Àt‡—Ö§T:4A’\ „½îÁ$9Üm¹—cDX•¯…û?j4$=EQã©PÖiO- W­u=‹
f¿Hùß¢è×™ù<‡ë·r1é¯è)lè{”
8¬ŸW-òÈEĞZ`ä¾¥)9»ßÃºü0¸D¦,ª"x¼F±O´ÖĞ&.™§ı¤ÖŸzµéÅ(Ö9Mªl4šÏtŠ^Ü–€áä€[™5p)•ì®>(°p?îNRİÜØØxúõîV"%>©Ïº¿¬Ÿ«7ªVÔxv®çº][¤]÷˜àt´r?‰Æ}xö¤÷d3×6ò¹kfå5«`Ê­@OjZÃu2n:3iÚÕ‰Ù|æª©š7foÁœÉ¼Ì¦c!µuÜER»Uvk¥ù“­ğÌsYs
Qw4ĞµYeÑ¨lL·gÙì3Çbª›ŸnÏ2ÌÇÜ<~KÛè'·Y•µogÌíÍ:ŠÌÙgv³Iıœí‘0»sÕy£>TùÒ©ZıT"Ùl?"f¿Ìú$Èú	˜=šAJ İ.ƒäİôœ6†ŸF=ãÍDV a¢8oq'DPqªéğíeDËDT0ÓõövÛ2ÕHxô˜F%%ğøğà}5¢X|€¡ùxYxÜtá|2JÔZ¹ë_Ÿv…?ùıİFÊªXd]Q O¼¾¯÷M	0h´8ß—ƒöáioï¤}`¤·óYuo‚º*2Nˆµ¢jÀÒ¾OBØ¿ÄĞª-l³Ö İÇ|.”­şzÅÑªÊ_’¶[k~ØxÑ§[UÖÀÒUMüİŠ£ùš§óK„A®yŒŒŒ0¤uÄE—~¼)ÂEÇëü%,¢¤Š†ÔÙ*>U!eîÕµ?»îkGÇm³æ1¯Eaä˜ì©Æ‰é:öÎ>•*ö~½Zä{CU˜ğ&O	%÷Q–¢TœOù¤˜3bÔS:é2^äÀ‡.š<1¬.Nb8'=<á<{’}İreX7Õ†›9ëõ³Z½÷‰•ùş…z.D%8“IˆáVj+¤ë=bá9ü<ƒßçÙ”c¸â%õÊÇ`©&uìØ>U¯Æµ‹È÷'äQáQ]4µx—q=Û\ñl”ËÇ[ë_\Üó-’gB›¦4ªAŞ€Î;Iã¦0²44õŞ3L±f)I$–ˆƒI%á*¡Q{V£œ%Ç1m+€¦VvºİŞNç@]tîc…B-q‹jTÄÓ©•g¯O%ÿ„ÖGŠ›’ÎDÄõWtÕè|óÚÅ˜ñh% k=]=õ\&oÇöë½ZxŸ]YsÊZÓ0½µq·h-Ô¾‚ö İùœaÍªU~bÃ9ÕB©Á :ájãù˜4’SïGÁàvÎäb"ñ'=,ª6œ¼' Ä x†›*×ìV9\®íüFAº˜6p	k™Çš{_M?ÓTüÁü9Û‹Á]„‹¢õB¿şPm¼èÕĞ¾÷îŸ˜À8–;í7íØw;=Ü=ºó}§g°.>1Äağ¨(&7Æ2§=Q†XÏGÇ³GÃ}…£%8ÿĞhTşğ{ç—É{Ø¬Ô/¸xL‚çÓíaß¢°)Á¹éÛIœÈï^ò^{sù®_•5á¹q9œ&é7zî:)mËùã)"´±xz~ÅÈlä½÷^à¨1  7dÊÀ¡¦ãÈ‹˜¼2pÎİœ³KøGÑ*¡ìbÍ±ÏÓ6RfÎ)è]òzvá)Bş½.Òç {1ôá˜$ÑÀk°q8®b]QX=;î©@Ø¤ß¾ıÑq
m˜ì–.Jşb®’yi7ú9Ùƒ)öıÎÜì<JQ,‡õTH §lk·‹ï5hòpî¿C¹>ğ¿#!Œãí{çAu³öu}ù8E«?•’ O\ fÒV®{zŒÓ€}Ó†fvº÷"-eß­‹ü¬4»9¯‹:×4çÌ^ù‚‡¶äÎ%«àÿ[+iTûMÓÙœ¥ç¥º¢é\¶·Ï#o÷Ø÷ƒ°ão ×—+Ì.ôåï
äÄü%\n_¿ÕŒí[ÖÈRâ.+­øóU~ËÍ·=,dåÙJöÕ>ì|†±{ğSˆ+rWÛÍÚ&Ê×Ìíæ$›Z»ÿÑMö1zº`]bÇSN5DdAvCã×Æ~sÔİ‚ğØëÂHëOÍuÒÀ_o4x²	aW×Şİ™ÈûèÆ¦Ù¬6z”·aà"Vş%­AqŞšfÚšÜİ«ÿŠp(d^ÛQ.}5ÏG,¾'Ş‡-®Â1ÍÎ’şeŸ¥º«·aÆ?¦Şõ¤øÜmzN2¯xiæSŒÚ¬ŞnIRšÀ¬7­bæG"ã“Zİ²Ò°3ğã_ÿSÖ’ïo¶n2SXc®Ît¬ ĞS¨ó~ıÇüê4ó›¢úNBöÓ4N”i/U{!-2Ù*á„¡>! d³¼+/¢3 ¶6¿5d4›ÒĞ~à`Çü5jÁò¹éQQ-²RÒb8
ô…â*ä¬™Ê€‹³ºPé8=·Vç·—ÑœiØÅ(T˜ƒÆg?X|f‘1;âke+³V²ma¹•§-<»ñ–ZßuO´ÔÂ¨K½><=xÙîdkì¡m,Í\K°ƒ³b½ÖxRkÈÊP×(:6>§}9¬CÕÍ»şë²—7
t§·/î víQT|>ÉŠd¢¢S<b0*	b¦ğ9àiÂq;B„ô8—(<ƒ’Ú¿şƒí]`*E?D'Ì=;-B´ÛÀJõåNÆİ²gp<Îµÿ5ü¾¬ıocãñÓ¼ıïÆæÒşkiÿ5ÇşëÎ`ÚT¿›7í5ø3™“UÑ±÷å
,¡y…[ôé>©£ñZ´>ëåÇÂwÊî
?9ç[%n¹-›aKê.’aÓÃq5Fj‘Eò¡¼mCsï¸êP©»h^ºÀrñŸ¨Ğ)÷Œ«şQ7ÅµNGÇÍàKqdÒŸƒIËş9aG%ûDzûó"GŞeĞï!0©Ô ¡Yy©§$,•Êz’Ñ9AÒ¦şœã93VŞ §FË!ífï=¦gÂÌ~?Q¿•å<}J¨X*Hm®w³¶ÚĞı8…ï4\ˆzmhuöüm¶¸É­èY-±éL‹Z­ÆÌ´Â—U£+ó†-J‘MÅDnZ¯C˜O©îé%Üé£Ë¸µZÁ˜{&j¾È!X•-œÀ&QZÄfÄò”qrå{óêåZ|-v_ä'ƒİêØ”wbâŠš{'ãÙDİL'ç{¿G «
èpq§ÒbO@	@ğ¦kë ßæòâ”­¢B¶*_Ak?ù»ÇÇ-³@õ©>™ô?< *&TP/'ä¡Tk¶	¨nÊóÍá˜Uã‹¼·h&î	3Ë`e²¹F›F>…ı%ØqÆ,­ÈØO~ízSt‹
>1lÙa/¡fğvğt-á|èKJØ£IÉ
ôo´+	ğÅ-…Œ¸=ˆ±ã(„"~Ú8@ïÁk¾2¥g]©L[;¢pŒkºC¤ZcbàM‹ªCpëï'?ó‚I:“ËÌ„=^0»ZZ Û(¥À6ëÉŞL bÜPt†>‚~{ˆ'' ¾=ÆoQNÖUóÏ¤KıovúµÁ¯”åX«?•6('»ˆ°î™3[L¡ªœÊÖ3—yy,òiúÃiía$ï·ÿ5ğØ!>"·ŞÈ›_›IxhšxTA™D‡Ø.œˆÛğàA€ÎØ_5Â…·Çô.*¶îô¢¬n•¸èr¡GÏ¸Œ¢€ELcƒFgã6œU›ªêœyÜ1|¸O›7ŞÉßv±¨ƒ²a¼³Ü6=&%édEæ=]²öxï#ß?ªôM,ö½ÄŒ7`­*j#°ş1×—…ÃÿFFlÄ¨·ñĞG\5U*íPÊéÛ±=l§~çÙ²ù=LcSÑ†%^gwÑè¡jû;ÉÒ3[¢=äüÖ·UÿN±‰ÒõÒİæ€’†g7>ËpÌmPÒ<ùÄŒ Z*qÇ½b^ŒUÃ-œKîç†néøØ¼,ğr?CµÎ"‘‡SZ9uÔ.Õö¢a€ü.Ó;×ªĞC‡5eMÀÚ>æğÙ›ßÇÑWÈIí'p>üò‹üõ4m `\›– ­l;ÉuC$â‚=ƒë)‹¸ƒ©8Šœ7–Uš¬²É*O²áŠxwÌÄØæHnß›øq7‰Ğîª¬éE$¼˜I0ãM8ñÆ2@ÈBŒ„û‘#"r7x@nW…[hB©TÜÓE!7 üÒôµ¶·Yp•´™jR¨ÄÙ—˜Ì©k$0³®k{>\—HãĞ¸eÉ;jË47×»I¬p‰:ŠıÔ$ÊD%[Ogëi/Æl§­Jv/µn¦…»©u;{vcÛeÄì-’[.."‹>mf`Û¯Ì;	ÓyFÊc%dNE~™“¶X•ü ¹Y;!ëˆ¦%‚ûY{¡:Á5Lw§Ù­g^µË‚{®Í4³/r¤Ë\0âsü{l{¹DW,¼ÍuáuZV©i³–Hä'èÒIsõAåÏHzcÿ!„®¼!l”°iŠ€j/_9à½9)©|_©­Wuf$U)Q!æ®±ü‹JhÚ'™˜†ÍXqù{ch4ì(,âÆ+æÊâì¶D¬‡rıØë;ù­>ûqı³Ö1ÿ?ıO£ñøé¿±ÇKıÏ—@ö«é¤6|ü‡õæFóifüo<^â?|ıŸ	dĞÅ¡wœç“N	µeÏıÑËÜˆß=¯ÃRK3¸O/ªäúÖ'í0RÉ[UîYRW¿FÂ|Ö'`.~&ËĞ¹Ï=ö.ò/RË:”ãaµ t_ÈÏëŞ‹cÎœæyı¾?Ib“Ø/7ÙL<í#v>M8Âó®¼ãËÕêóºøŠ"± Ï2oXs×<NûÙ"`‰†|á"
Gì¡µUV«ÄüÌ9	Y0Ë4hË)É† v–ôS$ÄçÑ‹ye*Û Y²4`Àpè†BªÜçÀ(½hÀOøó¼UÌhUJ-ñ±²„Ô×oD}G4Ş°*’¹Më¢´,iqS#ªg^òtÑõŠzÄï
„Ä“vIÊ¨•Ä™l-ÜY|µª¾ S¥RJòêkRC¸PJi›‘­4‡ M_øÄ—´/²¡ú4ÃHØ'A,mš±ßaó‚kV—óoËÏ­ÎËÏÇŞÿ{ºÑ\ò_xüõEı%Çc}£‘µÿÚX_ò_füÏ\<ó'èÆ†ÂJc®vòÉ¸=c.šU±é%k<s¡
5á/Ñ2Õˆ$Æ—¾ëÔºß°Ãƒ¶cšj©¤I˜1¦,İ½Ã£ãî^×1[s9
f{vñ’kŠÎ.:?ÒO¸tÃÏ.şÆÌÉ çÙYÓğr)M&â¾i5
³*ÙªjÕYõŒwù'\4d<O¹#ã±&4“u/uh·Ûî¾êìQcƒµ'^]²ÙÃ`Ì£?ïá=>y„cÈ•#äÉ³Ö­”Ñgr±É§aÚTWNuV•AĞäÉ¾'wHj¨ ¯“¡ò<&økJ,¨ïdHÉXI%‡éfğ48V:RšmÓ­çÄeTS“ëÉŒ!Ã´øz>gr@!×_sVõJ|;‹Ó:§KãêxI6s†
ÊÿøË/oE‚™l’ä0±=²kÄiân³-Ÿ#SIO…©6uMhÛ«ÅB»ºˆ…¶˜Ö|É±Ó˜Ï8h„x†m °& ©àoá¶}of‰®ò (2ÆM?œæÅJ”·Æ[5ğŞ@[Öµ.L¶XSš­ù¨cğ°ëìqÓS-´ÕĞ›¢×X”6•u“’j—¡/ë##¸ì°íü¡°@à^ãá«íôä›£“…f[Ğƒ^Øküå]˜ŒàÒ„Ğ2kÎ’ƒşÿŠÿï=˜+}eì{Â¿ä›yşïñ“'KşïËÈÿ^ñ¡÷†êø„ãû5
±æ>Ù„Õ²€'>Qa z,†!Bgy8<'4yÜ9/=(œˆt\ Q 0^ä¤}ºßªäNE’õtƒ¬*p‰Xw˜öÂÅyÁvÃëñ0ô()äÜ
yò#ê÷£Ó!¢{1C
¹Eø <á}4‘¸^üÎ°'Ïë@4Nº7aN¬z¢}º–æhâqüh„±0¹pgš…’æ×qTfK5¹©|¼uG1f¶Úè² %¦Dï!£\¨©w>f˜”?”œq¡~/%ˆ÷tşËX ÀhúñışsÏÿKüÍeü…ş¯ÃçCØØväc„çB€óTf×ìÂ÷ò‡Ãe}>½d„Qsœ+rÌ†â0¼òGçPCóÉ#F®y@zF¹âÛßw·ôSaŠldr•Â*EX]qÆñw9aØPÉC1­¨¿ò	‚ÆÓ_ì¡½ë`Ú'E&uNÂlk>Ôh–fC‚5DÕ‰§ƒy8Œé‚ëé_OéLàÇ„¶)“´Fâ@ªÓ¸&Où:I’ğõŞíİŞ;í{’Ë¹˜ôGïÑE€Nìš€®ÈuæuğÈ ÍËƒaÜØ3Qs9‘Óó´Dò:§f—„"•æHæH®ı¬ëO>SM”Y½ÔfÃig_§R®ºé%¯ï0!1ˆ%”R[/šS›Æ\0äLã–áÉ˜OÄ]¬è,b°XOõ7Œ¢6¯Ñ€t,=bÎQ0ó©ãyº$Ğ„”gšâ‹¢8`D’'¤Ğ¦ú´¸ÅÄË 'ÒŞ00f«£ĞĞ|½óˆ;z}€|n–Şùmh#zç…bV©kzûøˆ¼Vğ>P%eiŸgF
V•áêw:WOëb¼o—j³äÓ'^SÁE£¯ö÷ØFÂ½ôãì¥ñQ\@Êé/¦	…S†­£6cFß~J µ‰Îú@ÛÆ™Rw¸±9ƒ;Åq÷à¾6ıy`›ë0BŞk¬k3aá©pÊm„©!CÜœuùe“Á­G&¨A²Äİ[/ã¦—ä¬|ˆ±Ø;ĞößÓ±:ˆDÄ‹·£ !¶.10ÁnE#£"Îlıß}s}ó›O³ö_Íæ“¥şï‹|>üj|O¶õÿuşcµ±Æ2MñÇòyòÿ|¥T	.’‘eêøĞq>D5"|ÃE,¯€tO3mLñü5£,ƒ_öøŞñğ¡T<Î¯(«è%é[”Ä‚ô.j…ÿ˜¾j˜ôÕÌÚîœ¥9•ÊMköZ]­Ó—Ùwò¸È÷ÆXKĞ4AöP¿–ïVf¸4]§9bâsŸúÏŒ”ÎÃß£•}Ê¸ù3®xä34¦ßg¨$&Éâ5d_OS lYPf¦,‚ªUX 1/ò@W©n¶¨ ËÔ”8_Û¢’ls˜§™¡Æe¦ŒêrÙZÁÌ7Ô»·İ­˜]¬wM
 µi$Ìˆ…Z¸@˜iŠÒ›¥ŞxÖFzg23‰ÈÒıƒT²óé'•Î²‹"cJ‚{Ö?Û§\—Ó¨ˆ²óHh¨¬‹z2;waÿ¥FÛ>[QÇÍ‰|{E·ĞtU÷<]7¯·UÒwC¥¢EÖ˜dl©åü„Äˆ^8q…|_ĞÿãiÿÜ|üxÉÿùïQB«†NåŸú*YYŞ™¹âq)J-¾w#ßçëñ"Ãk¼ŒFPZ JSº§pÈ’›‰ßr÷\y½=BøC11#‚
[%NCy¦¯A¢8ñ¸7Ü‹êø|½q½ÓŞÙ=hÃ´w_Èm?JŠ¤K&t¸‹ @7©»uÍ»ä%¥´ÂlÜRe<¢FpaC‰ ‰/½úÏ·Î]­YˆÒûşu÷ÛglG×0‰V£DBª½WIˆ²ÄŸï«ÏªğêìFL”ÔhüúŸ™´†‘Ø¨%XÇ\‚Õå>@6äbÒW%şúöë?bOIÂ!šÄHü<ªˆÄ­ûŞ Û£ÈëCMÈÈ.Îøôã—N¤ ŞÄ,x4ñ‚ ØÂÜ{ÉJlœÿq8D„xã'F9= â×cWW¾ğŞDc²µ¶ÉëªDT3¤Î-'ÄŸ®e¡®fQW	ÔDj¨%Fƒ˜vZj&4qy—€	â†d6Eª9ëSŒO`´£á&¢n>0JõE…œÌ¯(5ï—8Â™óòó©Y‰šÔÀS½9<­‹ÑXOå¼RêŠ]óèFáiŞÉì[DÙ6ÒÈH8‡!öûÓÆT £&Ô9Z3áFe&¾Ïê¾c,À¾ãî^µAÖ}Õ‰ÄUC“¤Šá$xÛÆ3sVor™£Ñ¢jt^À-?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏÁÏÿòJ3V  