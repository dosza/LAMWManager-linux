#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3237766929"
MD5="974250e6bde59c3eff2dec87251c6de7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20447"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Sun Nov 24 17:37:13 -03 2019
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
	echo OLDUSIZE=124
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
‹ ùéÚ]ì<ívÛ6²ù+>J©ÇqZŠ–¿ÒÚe÷*²ì¨±-]INÒMrt(’S$— e»^ï»ì¹?ööòbwàHQ¶“6Ù½{£–ƒÁ|t]ôÙ?ğyº³ƒß§;òwòyÔØÚÙİİÙİ~ú´ñh£±±¹½õˆì<úŸˆ…f@È#Ëtİë;àîëÿ?ú©ë9¿ÍM×œÑà_²ÿÛ[Û;…ıßÜİj<"_÷ÿ³ªßècÛÕÇ&;WªÚçşT•ê™k/hÀlË´(™R‹¦Càç‰zä(ğóÈã¦37±…ëJµåE£{d0±©;¡¤åÍıº”êKDä¹{d£¾UßRª0b46ôÆ¾¹ÑøZ(›¶"ÔğœU–v•ØŒøfoJBèxÅßÇÍ“W0=ª“á9€	48À$—éû4 S/ *á:¤Ù.ˆ’Sgçêá¤B¯|h?h?;;26’Çfÿh`¨µ'jÒ€‹õGÓÁ°y|l,‘,h.‚·ºı¶¡¦ígƒö¨÷¢ıºİÊæjŸÛıÑ°;j¿î³æÌ2zÖ<7T”«B€†áÙ €•êêí€NB/¸.ò¶9 Š=%oˆûVë½:ĞkÅµ¨äİ>îœ«TÊÉÇa0¿Ãè
ˆÚÆª›Üó·9;ùä–(S[YÍâZnp	á
©a. ò­™xó¹çjìœò­QPŒÂ7Ìİ	l‹2š†tîÚe×oˆRIx¥‡s_ÏC×';^!«H0_²«º…	[çtrA cö½/ÄE–Gæt>†ÍQ8À£A‡ (P*3$:'ú,ğ"Ÿü•Ìê‹añoíg¢[t¡»‘ãÄT×şD¾1ÈF²›°˜Ê²Ø5”Š Ï}è˜3Æ§uée/H@§£)4ó*€ÂÏCÛµŒÚ&ìğäÜBİPZÔZ¢–STNP:M#kã:W»Á/]OÑê·¤
às`1	=Ë2âÁ`ÆløVO(oº²Œï¼ƒ *d>MQf4|êÔ:9àËd
8ƒ42M¨,«a-ıM´+5­¹y¢øv=¶èÔŒœp]f¶Ã¼S³‰„O-QÊÚ“T©d¯ıiå¬=Ï±A^Ø¡˜/ìÏé_Ğ+:!Ô]ƒÎ wÜüÕ¨Å?ÈëæÙğy·ßB[ö›|:}‚«¤–³lEöraòÊPv—Ğ+;$õz]İ¨i¥~•¸ŠÈ BĞâúqÅ|¥±”¢p‘\¡¤J%“„D25)+qS,››ÂJº­¼1&vnÚnJ©‚Oœ¬C=ï{^XpŸJ%ÓÄX`ÕX ó}uj¢Ìyˆ<¿Uş˜ÁdvFAÊ	Wd¥"›@X '–Ã·¢&m,yôõ³:ş/ÚîŒ ©U¯ÂÏÿïno¯Ìÿ67Ÿâÿ­§Ow¾Æÿ_âóÜ»D›1š³I{J¥Aº>x> Íx„&+¿¢T†‰ãG>ô{nØ0v1]ÆWò©¥ùÄè ÿê$/…şª˜_Lÿë¨ áè3rÿü¿±¹¹]ĞÿíFã«şÿgæÿÕ*>ïÈaç¸Mà¢¶îIsØÁˆíWÒêvÎúí2¾ÎGI0Ò‹ÈÜ¼æ6/âE!„96Â‚ëïÉM2Iˆ}2÷,{jCNÁããÆ”8ëù²Àr~ï›Q¬#Â#¿D®R•‡Ä>Ñ41Ú¢=·1,d0™Ü¹ÎÍÊ¨3%f0‹xF¦7
€®éÄÈDÇtºGÎÃĞg{º«ÛşeŠ
JV?³š·Ú[ò"V,¿òM—ñˆöÜL˜Àxej6g2‰x¦C3uòV#8û÷¦Ïë,š’·úq`÷Õ*IûÏKÿfõÿFãé×úÿ—Üÿ	^µqd;êìüÆÿ°ÙÛKşkã«ÿÿZÿÿÄúCßÜZUÿ/
úÏ rAÂÄsCRÂ‘A4âÛäß™Q—<ì „(¶~
šı“ÅS¢“f³ßz¾»­‘¦km}!Ç®T-ÒIhBŒ‚;ğá<bydêOâ4Î´Lâz¤×"Xo4±,·øğ÷À66åÅJs>¶±à¥ğ é°×ÂºsE©8Ş÷Ğfáh
0jÓJ°ÍXDë.×±<Ì°ŸÂëyaõ‰z6Ü0"êê L+˜Xş¹ôrq€‘2^vİßçÃm7º"'C‘ÆI™9QRr[õúFÏYÿx5Ô$"c·>(DvÅ8u/˜a“\ÔCsÆô€:¶F£UÂXFÇg£^søÜPõˆºcq ‡ªJ`­Ã£y '­>™ÎŠ(ûíãvsĞ6Ô;'~Ùî:İS#^âƒÈÒkÒH5ã:¢Øş¹´ı %mß¹$èÅîô$YÆÕ»#Ğ4E›¹ÑÒºÒ•‹HAiæÊ‹ša¥ÇSˆ?®ç¦@¨üà¢KÉëØ÷ÄöÌ?ü4
3€‹.xÊhN€àÂìùøÃ?{âñ¹+On´ 7Œ÷LmşE—hìîÅ/şx9HjÈ%ü^Å^±€O˜*^ÿ+é®„éäªKûuÌÎå¹=9GnÏ/@U4Ûz\)Wk¹A*1ˆª.Ÿ”c.rT[5ÕÃæzØ2®_é•*ÏxÓóîÉ¸¨B¾K+$„üôBY†Ã$<B'‹Óûg§/HjÈ‡8
‹ı9Ör YÑ6ëÚ\ƒš‚–áj7Kmß¾ÕÜæPÇG11ØŸ;½øÈtû¸szözô¼{Òæ‚ÁÎMˆNay, é0^›G·Ü8–Ìx[—÷ªúXŸı¦–¬.ÄÒéS¹¼Y^èm	6<Úˆåº„Z@DUô”°n©)OræjË+@Bcéá^PY=
 ¹X¼x±0Š	W”gØÔÂ8§ÌÅ)ï¹éÎhvn¿´P±[¤R²îJkd½¯xÀi°œÌ$µeÒê†ÍşQ{h˜`»½¡¡jâÛÇ*éÒ~Q‘V¿;À–P/Ÿ6‰Öš¾<ì½ÜRI"|½~û°óÚÀ©.Tùrcp¥PÆqKª"•ìN‚$İ³~«-8*ix‘+†èµ¢`£ñ“„|øÍö–¨½•tï}rµË}dÙy:·5âpñ˜ö¼{{h.Ò/Ø#‡€–Iû¯ÉêS»9íöOšÇ·*VË†€+¶J%K,|5=6­•j¿Š¡:Mí·«Åt%T%Y_Æşe ùÌ¾ò²
.gV«‡Ò­`ƒ×A¢’€]Ö…f09ßİ.Õ‡‡²’í–vûz`òùK$?¯Ï—¤½Œº»jåıŒÈSÑ¤$s4,%+Ü”{™ñ¹mÂÇr©úqÛ‡$ß³u¸ˆÉÉšÛ¢9¾ğ‡m"wÉ&¢‚¬ÜÂÌ¦±Å3Ïa`ú\Ù’t€/4Ø³(@H%noImÒU—ÃãæÑè°‹F³yzĞïvF±î<È8…OBÖÜl‰êKÔ †'Î.¡&q	¼ıSÈÉyx^2#$¥/çmILaU¾<’+±«—eãJe@QLzæäÂœQáqÚ‡Í³ã!|£Ô¶^$	»íZôŠ_zIÂ@R»A€Á›ï{wûÑkÍ”	‡¿VÙÿíë¿üš7A˜F-\ÙV¾»ş»½»\ÿßÙm|½ÿıÿ¸ş;ÇÒ¯f:só¬ÿ’ô¸Ÿ7–HüëÁ}Ê|ÏeöØ¡¼¶ËâAoîb£.¯—•ğºZ½şe¸]R,``øíĞÆ3ç0ˆ&¡TãJ–ÉïZÒu<Ÿ´£à~·;aæ¿Á@¼–¸„ÁÁ9¸˜_ f¢ù9 îøèt8¿Ÿ‰—EÔROâ¡Ì«L+Ó@oM®‚Òê{wÙÆ{”ÓYF	Â)¹{~\I¢’ŸùşùºCêš 6Íƒg¡wfÑç&!~`»á”¬Î~Û'†¡Fl¬~OšÃaÿÆ¶^R×ò‚[hşéeûô ÛÿúNºmCİØİİ…‡£~÷¬g¨¾Í ¯úÖ]#ä¯²Q*ŠñŞq"?Kßih1¥uŞ„40,ğ.’€—1C xRŒÇª\C(–6Íà/‘½ğPƒS1ÿğ¹îùÀ˜d)(¹+*©Êâ'WFäŒ7_}#šEÀÊQßÏÕKÍË#DU.'¡Kb‘Dì!`å3 [TÓÕÀÃ¶~šf<FšÔjçÖNbPå6H ¤MiŠ’<ÆyŠxzm%? ö›ÇõÈx7©9¶µ¸ûĞ©¥J«»Ö…î;fæjÎôZ«N&‹×q›4À˜°'As¿-§Î<Ş7p‡ç@.ù^NÔvıGİ(¡Pİ¢Ê—Å*•5í0ÊoüY#¯G`‚o±œÑpí£GèO>aL:kb—@é:‡já÷º¢duğ‚(’Ø’*hŞ#’œè‹P©0®Ç¶Km/2p`r&	Ñ›w<ÑJÄO¹ânÔ™ô¤&÷`Ö×È(ÈÄ+46ÏıPcAáé{3ÓcK<4!Ép-$ÎqãjJBŸJT‰:•´XW«›–Öc¡×<t~Ü„ˆø¢%>6,ZnJ‚‰"/6€ZÌŒ"*Ñg¬%5P^ÛÅ¿{µ£~óà¸-ƒÈ­¿:.Ø¼b’¿Dô™cº¸É;)ñêÃGâa /
 ey·ÕšÌUzN—¿ËRX:ßmi¯s½âÕRÌó“·UboŒt5ù	¼ØÏ„¬Ü‡<‰›†ÌZäe»#‚EKÊÚ'b,î÷h¸‘/A’3rM¥°…	yu¡^”G`&èša«‰/yŒ ‡t¹ãÏ±'e„B0`Â(Æık|æ.3 ğ=~Ìè£T»Xš÷fÒ±Èl€¨‚kZx/"ùKäñğ1¬Ì¬+¢’Ù½tiĞtœ4ÒG£ë\Ç×·5ÄH_µPˆ•ƒÜlÌ¥;>Q‰ò²ˆ°¦ó·ØeÌ=Â’Kû73ˆ½Xmç f0<ş¹Ù?àKÏÛÂ'…”•T¤SÅ8sÖLš¦T÷ËzS=/ëŒ×²¢—)*Ãê½<*†ğœ—Ã×Ñ£Åº	y	Fœˆ$Q=ŞİÀ÷’ 
ò”Çmccßş©vS•˜óæÉ»Û}û»ïÖÜè'B/Ì~w+X¼QÂ½ì'ÑúËcãŠ;ˆ=Å²Öe`‡x#wÆ%2}—@áíˆéØ›uD£ä2ĞßÄÎÚ#·.U-!Ê¼)±E“r•JÓ@N=—|„^¦§éA^Y+?=Q;îÔÛÃ=UE¹ã ½bé6í'—^pÁ|sBcæ¾êö_ ngpq=–€£•Í³.ÄŒIÿi¾ÌÙ[÷¼¼Cs–‹ãìŒ¤¬Í¨ÄÄ§ÃlÅÒïŒ1¦ıùg‚¡ç°Û=dPKMğô@:#•x§|¤&mjÌCa#¤‘FQ,&£ÁY¯×í;DI;ÉeSC“¸W{Œ_ëĞá+á ™Š…ùÜ»× Vjüb],ajzWá´;ìş:@¸)n|S¸BP„ ğ"öÖ½C¾Dg&\d”‰×[wµle}”+˜³{´w?/RgÄ¿g99{)®š§@ÿŠÅ½uùË·`³yl Ñ1É–…ÙäœºÁ¨›C¿“wmÅ’Ë®D7}ßIß{H£Àê„Èà
r½GØ7ÂÀÈA”rNƒïñıc¢ÈXXÈò¥œ‡N,œÒ)Ûsªû¢>ÀJë.-æÍÙm‹²‹Ğóy„ğ7¢™´ñå‘w"wQOÍ95²-QSSoOŠ]„¨¶¯è$wôZ(r7M	›Áµ&2*'&å>O¡Ê¢^ƒÁel;)A	º¬<L«×mèb<Š
"6òèêĞÈÇi0·]Ó1¦&h˜hºö©ÑÌö-fC$eÆcCªîÃlûËÒp!8¾Ø?:ë ¯ípq_Ø}\Sä¿:i9&cEvŸÀvr²BzêWš¸C¸ÏŸâ…c½÷ Ãšø'
å}¶‹•AV ›ó--E$Dª´Ëù‰gQ˜Ô1¯Å*_Ğk°53Dmy¿'Ö:(Áaíîìç™ô²e2Íë½½×Ú‹ƒ¶v
KYĞöUHù{7ï²ıûïAˆ!oxi:5êÀ4şøZwk5|Ë¨Õ<|MÚHtâßV³ÕnktÒ>=u†í“$á/Õ)ÌsÏ!d'ß]‘²qĞí—vÀ4ès¸ÚƒÃnŸ§ƒob›¢zĞiú^Ô9uüúÌõæ”ß-5-k]³Î5ş Í"Û¢¨=cGX-VÁ.E Ïµ’øúy8wêhhRÚ2u6;İ\ÄP¿š;e‰âl‰Ï¿L,?ò éĞ˜ÍÙè°¿Éìà=÷6¼~	©¨8HİAç´Ã¥ì4ğûF¢’ Œ²°¬ÉCôi 6(Q2¥íy,'öR”î9Ö(ïnõ~—¬.yŒ¢¡LıYşT &×öÕ29²—Y””Då^-³LbêÀJ%{o.Ì$reÆãìZìûÅ\ÇN­vÓíµOè7.ßj` Ü÷Ö…fÎ-ˆIÉÇ²·~ØU×sós¥ªI[hÎHs¤½ù/È«Ğú8¡cJ<3İs^ğ_P°t$oº¡@É“ƒ´*RÉÚo’Ÿßêğë	`NÒTbck¾~Â	€¥Ÿ’õuR%Çæ‡x¢Ä’ÿ?•€dsçØÚMúB›­ºÆ %ûrâŠ·ù tNî9şeÁ¾ÿxŠ&E §ô²'œ•0æX&z¯RY™ñ	À_€`üÿè13î-¢$%ÿQüÈ 4	­Øçpi)àşó¾”CRgŸb.4^†äaX&|¾¨–Ô%Blc)/í‰ó«;øu`Èg"t ×Öó¶°ÃkKD~9NÌfÂ¥¹[ ,á€†ÆfœH‡ñ!ÏRÇ-”“ì^|€bl$#ø•ğıàSÇÑ,ÉWi5duâŞçNqW(XtÅÅimí£«ÉPu©Œ)ş=P<C!üL…wMº7€Ç#êŠ+ÇµBgJ-\<üÎĞ™¼Åw•Wfİhë ‡`-s*©–G?+ãp¢–°F•|¹Aî’p.pZ5"±jÜñ¨ÉuòeÂ$ó&^¹)+‘ewd•ÊrRŠQW7
úuu-şCÔæÔ0>[ú§Z(Ÿ‚&Üú›^ÿßö¾­¹#Ys^Ù¿¢ÔÀ1I­  uQĞJ„dy€´gÆt š@“j@cÑ %Z£ı;'öa_Î‰}˜}ÿ±ÍKUuUw5 Ò´Æ3‡ˆÔı’U•••ùe2;Wpø_Í“	¶Y^›Ñ@Têîôë‚?%•j£dxœŸÿß`
ô„v5ïóÙZ¿˜QjùŠ~¹ƒãJ&|ÃË–ôóÿWÁOQ@ïdÈ)!8Öj98[-èQ)èG=ÄLÄÀVéG4e)À’Ò1²øMß	e?UêF®¸B±•wĞcXtí£?¡L¨ı-!I½t7ÆY ®b(à¨}²TşËhª˜ÆJårŸÃ3UˆàöÊÆœ¶÷E‰*ö½üõQçä9ÕÂÜ®b0íÍŠá'ádÀ\øµÜà`¦Zß/ì“+g:*;ó²ººQ©ÌFh|cÊ‚´V×íU¡2©\%4·4ã¼İÕÚÙ÷XõÙµşj.Ñ¢œØgN­9ÿ_7¤ÒêkVƒ€Ce3
ªêP¡Qº:&Ì	å”ªIƒz2¤¢PW†ïñ¢FúÆS‹ÌB7#•q³ºY­ËspãÄhMú²-R6’ùH3™ÁE*+ƒÊä"ŸÈâÓÂŒæá¦‹#¹÷³q¯;Õ ù®Ÿÿ{5œ½aŸ¿ü;èO±ğ0Iâï«¤W§ışŞ..Ò_³±ü×ËF4êáWØ¹ñU¿ß`¹½ğÓÕ`”ğ{?ÿÿã$”¿QŠÓƒè4ó³:I~ä Ô—ßĞ¤Íøš¦ÑÅÁÒJ¦ÆW¤sÕã÷\Â¤'[Æ	.ÇX0—Õñ” *‡ü1	Î»W½$ ï¡êö;ì£ú;Æ²èÚ?šrLâ‘LA8,ïÃñUV:|<ÙŠhdà+Ê×ø+üú}ú
*‡BY YùíGbBè›ŠœMõYüxâ=†ëÃf¿ûá˜şÎú³¡üFTÂ_†¿Á@Àe»?ÆcùG{ô°‹“!RÊ$ÁÕ}•~“I§ccÄ`Hñh'ÒÂáEz2¾Ê,éÀÏ£ş€‘Ì­…gÑxné¥,nÓÏ,V‰I³FR)F_ú‚”¿"£Y
Øt¦Òbd!1°/+—êg0£¶—¶ÄCÜı‹u²yM	Êº(çjmbÄ™ºœÙê¸E•.Jg5U°;µ[ÕwIW²ÊVµ~F³ 5~áîÈ‡ø_­õ²ü•›T°ô,Ì/ÔÔ™WÈç¬J¯DŸŠ}ÅMà£NzÍé	Êè
Îå"3ÀNÃ¾y<ëë4ArèöIqó)};%œö¼¾›aÄ8Â-®ÀL›wë fk7R%¿ˆÛ(®274:U¶1®·œ‚J±’HF¹Å-¿§ImX¬–¬äÅğµ´)U)ˆ6Ê]FŸ»ó[ƒ‰úMvÛjY'MÍ!)ª)dF,Ïñåé¼PÆ/r¤ÆÇb 9y_,›^.¸É°§IÓîÑOo}pbÍ+¨,³™Ü¥¼ÈLDNù¬©TÄ¬ÿ£Ÿ*IÁæ§	4'@„†&DŒÄãˆèÈğ}6Ş ~Ğåm¢9ïZ!a——¥úÜùâ36øF%+–|ÏT…Bıèn<‰.åÍÇ’Òir>õYÛËtÃH-¦ xşÖ³tz¹!ıæÊ/¤¥tÎï¬cò]°Ï8';éíææ[ÉË‹4LçFæ®%R~áyµäAzË	FãäÉV8°‹¹Ùb…%,dì©Ì¨Kæ°ûÌ‡†‹ìc …'(NL;<\$÷"—˜ÚAÅÎ+f…	JGs¬ÎÔÎ×iœì¾í§ô¼œ‰õmì‚–°âÉØÏ1éqìÆycÏÔ"%¨œ.Ô¦®ìŞJ>Õ³ål„ø«@îŞOjgµr*¦V»Äûoiä³n»K$ÃımhïÌÜVG££¼Í‘mrdY)ƒ£ùöFwcn”µ6‚ß3yß7FçsÍ_]dt»œl#tË¼ÒVÈû•ì£´ÙQfTs¦\W°_8SĞ–ùs5¯ÓÎö,îô?x–…XúuİTI¹±©Øí,Å&bwn!¶¼­ÌL1ô&7/_Ú%U3o¯N?¥¢a”E‚Ûår —r«:ıeë ~éöı˜/Xù¥=XPºİöOù“ò³)±1Îm³cV …S|ûsGİX+b!9jĞ¾oGC”ä…‘(ÀÏŞ€¼0FÜËr$ç1=[¥:VÙ/'aCÓœÚŠ«XC£„Õ&X+c 2¾Ùº‚«³€û¼w-×ÉK¾é­uøms
ŞJÉ¶ÙSy“HÔT*q¡õ¹eBºÈı]oï´ÿœ¬®çå4«)‘W«A_?n®õşZùáúj&‚¼ù ŠŠYµööÁ œ$7*p™,pI0³Ø†‡ù|éø­^Dhãº²Ê?,˜ê[z‹¡Dı˜s¬(xÜO:!]3"Ù<!‘ô×Õï×Ø`
€téÔ¯ímU•ÄûÎ¢ÒäH»K£oˆ*;2
éKY!Œ¾üûŸW:C«PcÖ*3U‹3âf:F@„X—Ó•UÚúáèÊbÛW_ü5•š_¯nøpèÅ}ØdšşéÉ›Ê3ÿ/©—/x!ò•­ÑU4‰G¨‚Dà'	ÅÀùûbŸkKñêXcüÌ¯½‹‡a`njR9M‰Í¯ğ¥/Ë’"D¾Q0uYE{VšùEÍÑFŠzQ“}15İ²c$·F§ŠW˜sÁ,z^B¹x9İb›h`ò]­#MùÜÄúYU ›d<€âúl¡Z^S–…|®Kàœ0ÎgÜö	Jw aÓÙ˜ŸÉ‚<+¯Á¼|NÖı•uAå¬”êó°Ô|U3äkæ+À¸¤Õá]Àfq‡5!-`ë¦-pàÇúXXé1Û#sŠ
1ÎùTn#W‰şÛI¯‹gLë«gS½'µâ5ôÉ dçañ,™x‹£’„›4íÀ tÈü%¿'ØÅÖ©Ø¥“?^Ü
FıÅCNDúk|ã70ò›¿ÊÈ#+[uºœı’şÿê­Ç›9ÿ_÷ş¿ïñßâ¿]¥øoÕºÿæ@³Ü|FcšÅv{ öØØH„¥s.¸4LXmäê
î|ƒ]xi÷¼|P.K+HVóe0Ş¼ÒÛı£W;ûâÛöµw¸Ú×ñ  É§òRım«½Ûj–WÏÂïëÛ›áªv~°ÓníqÔÄm¦qÓWp½³‹Ñ[:ø°õ¶½w"³ÔÓä
HVWãˆëZeR²-+áÎ_N÷u[i8#ÍÊfB°—¼O ;¹#ëwƒA×–Ä£¿‚C7Wûao l¨Àå…cúá€bHİvÕ+õúD‘‘¥òbùH:¾&ÃÂ>«“9¹û{ğ9¸/†(q …—A„Nm·ÉÛˆ­bné@¬…¯ÑìËZ{\`©l÷õ3_ôã01ì´øâ«@·C¹¢-?\£ıÃ‹ñ#Úšâ!â
Xoå:v›DŒh¾63%*§²D^i:›Œà¼•äñlÔñDÔÑO/×ò¨pNÜ\=<:l­:ÆÌ2¿ÜÈÇĞ³]„óÁ^h0;¹*‘`ViNÈX|ÛC…vì­.˜†
Ö³PçŠì+ÉQÉÏ7ı¼Âó¼L.ÁC	ãª~ÓH’‡ÀG¿Gõ‚Ñ–=–°µÀ.×\+¯uğTG¾¶ŒTÖş××½DF±æ"šó µP¡ôB'h®­»ğ«¯2ƒh FQYL{ºµäI]{ñQ¡Ê}ÎŠ_ãÖ•–?Á×Zí¬VŸ×Mz™oáÄ‘c™ö(³Rb¾M>´a%ø}Pùi§ò—Êï·X·®`ü!¦…y¸?Š`0†58¢İ>Ïf¶UiTëŠÛG€ªä„¥€¹›Mƒ´š$M*Ò~éïïœ´v»;íöÎŸ±T93”&*œìæ`¾BCÉêÁY’3UÒ9Iëh–sAÀ$CŸ
›Ãjê,Ï\˜LêIèC0™×H¤Š¹HëéOc¡SrçtÊ›rú»‘–d6HÍœ‘:}b(eµ‰÷2„÷úğOP©^	“ÒW1Î]†ƒ7ıók´@É£%”J‹R ,MR,¬Ítö¤9ÖÕ,×·õo½‚aE¥¡|Záºo–7u¨ìŒ©\´`-Û*•Ôqá:RÖ@Â%k	D¼¶­”1ï<L2Ì™Díõ:Áõ}dÒÕ=N#×ÑIyµô“4{ñì¹7,:w Ş0Â	Ç	š_Éß47Laó ÷9©^*1àÚqn&ü“¬Fmsrø¹Şêl‰)Ç˜Z’^¹üHd°õS ›;÷å¶‚õ%ŠelŸJó2årÙí0´¦dê·Òù³Ñ­ºïÊ¶x Jü‰dAš’;*$­tQ—¨:øx-ú!ÎHe3%Ìº~3²LŸIÙÌh=#¡ÇÂú…3§x¡›ÑšÚj³¬¨JäâH­×^ó™ø®FÀhãíÆà†ôö‹Á	z£‚É¦e¬b)ş7eK-º™Ñ«1VÉ)V;§j€pÚ}tÃh¸%TÇ¹gÕ¸œ‡p¢ àe¬.û„ˆ‰·³Ù4€úÆá fMcLz<‘7«tE${û>¹<™ÌFdx‹Ç€s]Á”_†ÉÙ¨×-XßÕjIèåW.üŸîL´õ¥"&'#tr'Ó~ˆuÚ^Sp¿§Æê¨çÔÉa*8ÏÃ~B¬ûÏº`á'†T©™÷D¥âù¾¹+Ê:Tè¹r%-ô,#Û9F8¨²6
§Cúéç0O×ÄÉäZ zÅäï¸·2	à~ñj–\gvŒÜ¤IçÌ¶¥”w2zÜ•úóåO‚û„·Â–¸ô{ã•a˜Ğ-õÃ;œÕ2ò˜L™h¼øª.õBy”°á]¸Çé» š’#rUõWV°®º=òöĞ©	‰9o<Ò¤pÆÁ›„Iê}>C*z@Æ’TÖ*×@*7şP™‚–<E…ı°¿MÜB†•‹èce¡Ç£K|Y…è
RŒ²H(?Ä±’yxŒåóŞq6L2_˜Ûø‰àWœ<ğQã¿²ÿ9Ìwïû{ÿ/[FFş¿ùxsë^şïÿûNıKónIåK:zy­|}[®¼eAÚáKßp–b¨|!ÏŞ¥ñ$DU1£™kHàlÉHväÆ~Ë\47¸­wQM¤éÆ´MíÓ|ô.9é9r°V‚ïy‡›«Ë–‰gìÜpÄÑ /¤Z‹P§'YV¸ÊªL.THæ–  Ñ†á÷]s@øe•Æ#×¹ò'GqT,ÛÙ´[môÁLÂ=0¯¾+ù!”Ãî/»#é×ß•­áCD»,=niU9{K³>j¿Ã"3WJ$*WˆEJ:e¦#¡å_GÖ¿4Lø·E€¼ÖsK0KäPJ	Téj*É3F]>Qí§=âîS-WØš|M%i¶ì-’Ó‰‘,‹c’™dÙôæ®zçğda½˜f~¥2E^¶Ì/ğƒi0%Ì×’õhº±İt¾MUU…ÔÿŸœvèHË-é²/ÒYhôzuxÔ}{ºÇ+^Æ(1é¶ºÑXÎ-@v|T<%F2Ä;l0?…pq–`¶?ÿÇÏÿViŸOğòªAjV5zñ4tIRQyRj®‰òZüşRT€³®¯‹us·—B{ö¹ôïŠ­FG Fóá…$F‘*Z4§*“|èQ0Ò£®¶€|å
ŠÄ3M[ BÄDI±”GıVRŸ-^¦ÜJ¥ˆ[™(^€úE0$¢)1Îñëwaï}‹Ä?PM4Ïô@Ü0/‰J'ŞÅXıwgÿ¤Õ>Ü9Ùû¶¥ıbéİF³:›ÕêÖªÈ¡«9tÚ¬¿­faé½Û@°'ìj!ÍÆX²ÉT8ê€Ö÷+m%—/XÒ•s06ìÁFã°ÕÚíãæÖÂƒ©YO}@GÅnxĞ÷ÚÑ8ıq÷!;+¸÷2ô™9sZ-Úê³
ü¯;ÀÇíó4vÕ=ŸY©ŠW}Là¿|nxîUÍ}¦”[naØ$f	õœ¢^ ö½ŞØl¤ØfYìŸtÔ±â)ó™Êœd­ı®1”vREø‚ôÑêSÈ«½Ãî+  ÄRë F¡_(oÊhÙ:+¨ö‘¬œÃvŠ}à@_ø®Ú|C¬À 9ù•c_Ó)=«ßF¸J2BÏ~”8FX¢Ë¹À†7ÈÇéEí*`Ì„á	PçyµO«1·»üµÛÇ8|„Ş¥eu*çÅ³QÄ"ÉÚ„é©8D›=ép¶%FŸCÍK éQĞ„H‚HôÉ›ÒÏÿÄŠp2t‹ÛA¹æò‘[™‰ÍvpøÄ9# ôî`šd¡R%%H¨Je<›\†zíş¾ò<±8a½şNF¹Û$áôíÖ3A²æ‹`6˜zCñ,Hv9ä„t¢Lßuq–ğé—ì}sÿš„ëZöGª<)^4_¤RÄf8Çui„­à›%¸×‡ß4E™9>©Zò!BR	ñ¡R_*†hNòCD"¢'‹….©í‘Z÷\@%&?u¦ñxŒ{ T\bY½ÔùI»i¥&ïˆÜùv‡íüršL×. (äÜ‹õÇ˜{”SËºC¯hÛàèµéÉ+)nªOşØñıE IÆûYšÇÍÕüËïŒtÒvV½Ì^¶­mìï|w°%à¬ ÇÈÌ±f¨ÚğPè5À¡JÌ€Áµ	'Ğslõ*{)¦Û‚•"ÅÎ‘†v~vVe)å¹’d.5„³ó4ÿ09ÒmùrHO0|®¥©ÔeIŞËMm4eü¯ë4Ÿ!É×\”IV+›êgù~hƒë;@Æ›À¯fOo˜Y*³[f9íƒõK¢jåd¦³ÇÜ™\<—ç"K£òşŞ«º¢pì[6M¹1,>î¯®iÙL‘gQ1ñŠzp öc¦†ÓIœá×1ÿ5ób³i½äZ`ôOÑ%ôWûY[îK§V—ğpYWQ¨¿üN®cR8_Ô-Êf9mï75¦nãy™İÌªÍ4SìÙÈ.÷Q¥©:¨[˜¡Øß{İ:ì´:0ºíƒ\ğ–X©¢^8JhóÅ]rõA@à0
Mü¥~tó Ç:*_L÷M¬õ`çpçm«İ}}°kTü=¬ó‚6áŠÿ¡é4ÆÿÅÅõå®Jv 9{s‹nHšZc'¹ºß«¬ŞY™1m%pT\Z5Çn55·’tˆ¡LïÍèÙNñÌa¾§¦ÅDÚR†]nÏÌøÍÌøéÈ©Šp%D ôîO¨+P†fvi7+¸<”·vk¿µÓiÕª„ zBíÔF4ª]º+(~‰/(ç^è­ÑN¡€ÒuÚâ9´ İİ4@Á¨jYjÖŞÏÏŸo—èÏÇ¹¥ŞÅhfĞÈE& hûÒ¦rÿGg¨ı†˜J%
Ã¸ø#Pj„/XÀ`*Ox;l£MMÏOºÖ
¶¢ÔÅÆ«c™Ê …KÕXg’ È÷­åÉ±Ó>ìğ›Ù‰`'¶A4@GwÉT™xˆGb
ÕH¢ šH	(S‡"9•/¤|‘w´Ko['üùô"CC!o”Û&ãÚp¡Ïˆh®ù½ğ–¾ò!û‚ÊüóxÍR›xªnuFƒX7R”†eá‹ü ²¼Åç,ŸÕÏñÅD,éPxéÔÔ>Ó†j_ûLo	İ³ã¸\Í)Ïœæ±°üò'o(Ód)oy²çóx)²˜)1*ÂÓ§OE¥}U0Fæİ¢±p.£E™”q±s¨ŠWéíu“VÉ{ê]¨6šL¢Kû…?óB•½ÔßTVd,G£T‚öB¸°iÚvxUœĞQXAF=¶Í­´ºt­ÕÂj­Zõ6š1h£kŞhJ‡-õÜ16›$
ù.‡ú²PÂ(ˆQO6™!CË¸YæÃÇœÂ&p…¯}©™ïÇ;o÷'Ù9îîî¶şÔÜ%Z!á¯¤"ÆçE¸^ú¶5t;ıù¿Ğ?<jõNXpQÓ¿È/£úË$¼ï“,òÀœì´%‹«ºîÌß k à?^]ÈN`hƒègvUaÅÚle° ì/ÌÍA›“9¦k±yCÙ¥i‚²®ôRcE0nSz¾íGƒw{«bˆ.GÁ !ÖàÜ®ÃÉd6®ë‘•MúËŞ±ä&rÙ,ÜÙè§hl¡‡ÈÚL|ft]¹y€w¿Yú3ÂeeÛnÄmYË¼İ…±¬ª5×pn¿µ
4Õ¦nî)ìl ²JãÍÇ¤Ü4>qO£Ğ”€­åõåÊşt`v˜D•¬":{o÷O`gb±+î	À¸ÄU>j![L,gw–ú!”&¬Îë“RÖ•:£ê¼Z¢-®¦È+>/q²ØC’;Á]\nÌÊÕ …1™¢©±îçì	Ëš%ºA
ªy­QÙb7\¸±ËW+’3)›ùœ_{Òx\mTû®DZü†mûƒêe_Â*pj
Œ³T'ˆ)wÍ§WW–Ç@}U˜sgÉ0üM¿8ÑnnhŒA0)›Š‘v.šÙZtlXv•ğ¸xQH²¶z&·¬lXÊ»$’Tâ>"òìÁy„Ì3¥K¦{+×póş«¨"õ5+»œ#+~Ê¿yI…ĞwÁKÚªsäYÔk®üxâEãCMéË >¸ù²[ÅEU#µ‹l	‡ª¸L2	g-1Ù2dtàÂ~Ã|Ù»–%Šö™«¼EÍé[¥KUàVº†²€V†ÚÍÚ7¿Ç¿Å¾š60¼ıt×7¤Ğö®l|¿“k‰¼o®qÜ±æÛÖ‰_˜Ğõ“|<¹¦åÈšxuº·/1X?ÂÆ—Ôxç—ºPÛu=¹ãøïÌ¥‰a#=&Ua¥‹“÷á´Ëï3èh~ÉÁø}—€YPYkÁhIÎó`ïĞ°,h²ëÇÒI‹9\¸½ëÍÆÖØÎõ<¼ˆI¹ù¥ã•ymá¤HævÙ-¶á4Tå¶¼eˆY4Tü4¯ÚVµ6÷J‰ÑäñÛÊ ÉÜ‡ËŸœË†t,¿V/syuš“!åt›¯»@À.ªÆ'¶1£¿Ê,hC†Zbaçæ§à‡,yjÎİ¢~3Mœ×ÆÛm¤ÖVª6Sı÷"ZQZÂ’#·ÃqM`ƒÍğLù–¤Š¼¹êıÔ7Û¤±Ö}FöÅı‚>•Æ­VeLµ¥š¢ØïÇ{«à¿!í•YØÇsYG£Á5ÙôHÅ*Ì“pÈ1	•eÉh}äz˜ãx¤ÓÙ!á5ù7¡ÆªúœYV\”tê¡÷³l!Ãº~fÓXnŸ²gáo·;01FÆËëóô«¨´»¹0_3±Ôd¤vúı>-æi,”WD¼Hj—‚ˆœAoiÖ}ri‰‡uÅ0ŸÂ²“Cvr™J\¬„ö»Š"ù!Kõ‘^ÇÁô]öZİÙaÇ`ßaEòó)3x&	iö’PÆ`.PwM·qPó¤%éûºgPb-ò£Ş;ü½.J&T a `ù²â«p daØ*}j©‚:šîÔR1FVå‹ŞWvèhÃË«Ì)·ìÇ ›Àú’[AÈ¸œíKE‚YM¨•å4¡(n°éPGÕkt´—èºH7ØbhÌqHQÍ½$0sÁ ú)$¦ê-å\MøemRçZ›V?èMÈî^Îe±ÅëUX—B‘	‚c_mÅ#vC„V0 è²b(Jc™	sH˜¨™WP­’ ª‚]79VFù†Ïv;Æü•2UÚÅmªIk¹çlåôtŠ{?ÿW¾·ğÇğıGÔ>¦°¦pÌ?²FqyÂ} v…à'ØğOºx"i»Òù6mez’, »ÙİèndŒÜÒ®.™[” 9ic˜VXA7kËV¦-7lÌ–ºŸêÚêç"^g˜9£ÚyÙŠØ6ú£bØ«Êö€lÀÂ22ÔÑ)êa~G¢ó+§aâ²DÔÛ8êôÈ[%[ŒjN"3¾ŸÕ û‹³:#>³Ş­\‘Ä„(Ã-gz½äxgBS5K2“ît&ÊÏ4ñ·…ZÓı—‚Ñå´ñi²'	ş+vŞ¹²ò
ÙkŠØQúdÀ§È§]@ªÛìí’ÚI‘Ë¥Â»³ûjŸöÃ+.š†8‹ûñ¥Ô³M•‘>ŒÂ	°èJ	¹´ÏféôğxhCÃ"pb#i{{[±İ1×U¿1Ûe¤•¡2È&ÄÒÌ^hæ¾€Ğ—‡¬÷şå9Aä>,^ğÉÖúÊoÌ0eØÎ´ó›Á¹¿+™e¶
NnP»[îÊÒæR«Äw¾³š‡’»g+Eİdo/<Úîb³.8œçíß¥…¸,”ÒA,%õæ²@NŠÃ©7v 0»'Y[y3Õlr5sıwİÁ‰ókœ¶§:Ùãâ~C-Û’<}àkú8½N—ƒMYDšz©i=¾|ìQX”G»)üÁ²Ò€7‹z°á/Ö¢0MrÙMÁø`…ÔAÈòMU°Ì6´ƒ¾™ºB—èŒ0›Êeïï½Ş;éî¼>2ºG»-¸‚—Ø£ƒDÀñÌ—ky¤æ`#ÿ7+ÜFÔõJ\ÃR2.oê¥vAó†P”âóvbÑpÜö'¸?Çˆ_Câ0#«»b%#$§DväöµVÊËmD#‹Âmuê-íËŸv!êHGxÎÓ’TşÑ„„9'/{NæNBÖù£¿¬{"ƒ,m
;DÙ^©ÀšÙs1¥ŒÄĞ%}%B(#˜Dêâ“[ÔÉG~Œ‹0/÷‘æØ¨³ZáPTÑÎ¼`ãŞéc;ÑI@2¥(uÎA—9æ¼‚SÍy€æ•yz~é":“ékéØ/wÊ¸Î˜M˜¿EøU‚ÉBiá üUüÿ<}ü¸ ÿ¿oåüÿÔŸÜãÿİãÿİÿ¯ÈßOÏ‰âÇä>Õ(~òŒKQR«°mÏ•nŞ‡ªWÑU³d¯Oj}¸)Õ:èö§ÂµUÈ0X–*ĞŞ¸¢½“/„
ÈÈwêÁ.mÏÚºĞ0ãIx%Fvî£ƒãvëxÿÏä1"Q ‡İïÚ»ïéëküN÷ ÌY˜¢ÂØ.x¸ã3F8 C»¨WnÔ’–+A0ĞÈV*ZÓdXB¦ÂäŠ2ó <:§ö	ÚúY4›¢òPü`(ŞB00—ÀÉU¾Ãçfl\†*™¡©4Ú‘ò!.•7¢hH…¾|ÊrTk7¯…ó¨zæìÿTÀ»Öä$ùÂø¯F}ãqÿõñ½ÿ·ûıÿñ_OŞ…è”5¥ô%1`'‰ub\!¼eòe\¾¥’.‚{¡5®¼©$U¼Ö¤Wpã`è×¼	Ğ®WBŞ_«[(bÜ›ûˆ¸ˆ&Éô°ÁÂ¤Nl‡G'{oàpüjyí(F×°Wúë®4ÙWQ{”t½‡äáJËé¦ü¿R!¿îi>_
Ûí¶—*µwöş"vÄÎÁ«½ÖáI‹'ËSwT®À‘Õ3o±¦‘&)ııJ3«¼Ûıi÷mwwçd.:MÃ}ïsÃ/ä”^ŒHßsŠ=|Z"™ÈïZû¯q,Ö¼ éÓï³MÙNy‰M%ÿlz6=?„2ÿİFQ8GXéÑ$@‹ïŸJé­{Üät©î³éC‰»÷{J†§Ç%êOª[bÿ¤“‹x–àï wˆt†RéĞ5ä!îMûˆäp·é_aWEKl|ç0 õˆZ¡ò)Òu ‹57Ì,Ú™ı2å|ƒ‚I\gvxØqõbÜ[5S¸à)pX?­ê±ÈƒAAk‘û†Hrv¾99:†uù±‰LÙ¤‚ 2xİC	ÌÑñ	¶Nchn5’¢!ãÓ¶ïÀ—³¢zAï]H‘øÆ‚Z2~İs¡İø¤Û?
§ÕŞ,¨Î.†SàÌõ8™€5›õÆ3Ï{c÷Ü/ñr ;z|0ì¶v=°Å°~$›èT¶677Ÿşş	›ê(qYjÃ†&Eç:&cáÖœÔŸ›¹nÖ¥?"¨$£ÜÏ²qŸ=é>ÙÊµìn›YÛ™Í+x~§uÕ“j½Z÷½ŒéÓÜ1í˜ƒÙxæë•·hÍd"óZıXHu÷X™Ô­ÒŞ\m<Åd«Ü“P<ë^!b’˜´>¯,Z…ZAw{ÁƒğÊ»¦îîö<«ÌÍ™ğ[j,H?YáWÕ¾±U°ë(²˜ÛÍõs¾9ÇüÎUuúPá¥SqièDªÙ~ZEÌÌ]$ÈYØ=š3”&ªCº7\FÓw³sÚ~CàÆƒ¹¨$i•Ç9î„ø~–çËª¦w€ÌKNÓFÃ°Óu÷v[*Õhí/¼p…€€÷•DÊ©1 =rYxšuàø³J4Z¹^x<‰{S´¹)éb‘3Fiy2z¡Ù8“F¤Õâ|_Z‡§İ½“Ö•ŞÍÆÁÙ‡}¤Ù‘EUc~?aÿ’S«·°­jv;\¾Ü6W9zÕ3ÌŞ­‘¿¤'ØnùaãEË{]YK{jêš8nÕ3pRú’Çy5ã	H²5„E8¼ˆÂ=
z„E4­ z¶ŠÏHY…k{õãO¾g"ÀÑqÓ¬¹XT‚adÈÜ„TåÁô½vkgŸJ•{¿YOu]˜´ùOJí)²,=R“è|ÆD±`Æ¨§tÒe¬úÍ]6'òrZ}$bô(=<á<{’núÊk…ŸªØ9kµ³j­ûY”xÿÂGB½—È Ó¸'bµºJ¯ˆİG">‡Ÿgğû´Šh7ÈiÔG¦L&õÜ¸LÆ¨^ª“0g@ƒ
A5ÙÔÚ4¸LjÙæÂŒgX8¦êjïâÒbÎo<ãáB*„¥N3òÊtŞ©1nHU+ aÔ»Ï0Åº£$=“X"N&•„_¨„zõY•r®x­˜œ0µ²}ÔétwÚú6br«„‘Éêè¨Å@_”Jƒx}|ªø'TO?ÒÜ”²Ä¢KE¥O7™öÁ×o|tI*°Ö'Ã«§/Ôåô¸İz³÷§&^—W×½’Ñ4LïlÜÒmcğ³¥ÚWĞw>‚3¬Y¥Â'6œSM46ë÷+c~s_Œ'¤8õîù$ê_ÂÎ9½Ë ébQÕÁø=WFÀ3\WøÙ»ÂˆÇ®óåô’là×´5ÿ®š,¦©8àVş5Û‹¾ƒ¤}§ô$D¿~Sm¼è4	ß»w?˜À8–Ú­·­?‰owÚ{¸{t<ï»v×b+|±¤mTäZ]²Ó¨<ÅçšãÙc`úÂÑ¬×+ığ
ø½óËé{Ø¬ô/¸xŒ£ç³#°D“¸¡~Á¹ŒëiìÇi2Ußƒé{#æò]¯¢jÂsãr0›n¦ß(Ü÷Rˆá¦?G3D×ÉìüŠåÓb¼O/pÔèI1D´`\‹ÙhL„º20çôÏÅ%ü#§›PûRY÷\h)	FäV™LÆ}RÈa#ø×dú³@ít¯!Fñ¨‚ıõea4‹¹£a“şşû<¯PÌ­&¤å/.ß=™H·ÆÔÉØw;{p³÷\3E¾B6R!œvª­yŞ.é¿7 ‚È<¼÷Ÿ€ÿJa„œï08*[Õß×Æ“IÅa©”yâÉ³PŠ†Óc$ñušÙîÜ‰0Z–}».òYiwsQM®iÁ™½úmÅ!KVÆÿŸ—C£Û_¨šRsªÑŸ[h´ÙVDS?Ÿ#¸¯À¾}„¹¾\an™2Çˆ¡9.·¯‹cK…¦Óq™¼Ë*ˆ|dÒĞôómÏ:£Y}¶šÚ‡¯^·v>…ø=#wµİªn¡ŒpİŞnN²©ûİdÓ¡gÊíÚ?åÔSDêu05auNÖYˆ ï„µ_“lÿÖØ ‡	øûO¶à/ìêFlÑ‰L§ğ€î’#¨J½Kùq.bõÒT°çÖ4ÒÖ¬âî^ùG|€C!m“øB*Ş²ôÖ<ÏXr=šŸó‘­Uq6á_6,}û> \Èä‡š€ŞUw[Ÿ¿Ç™(® Í|š@q:ö¹z¡JØõ¦UÌı(¯ôj‡6í}¥õ…Éßÿ¦jÉ÷‰›mjäÖ˜«£=i<ÔT•¯…ÿÏÅÕÚ=EõÄâÇY2ÕzÑTí…RWk„½†Ïõˆwé›\Ñ ŸáÑá°`ë‹[CšGóGZÃv\cGP£–,Ÿ5›Šji“”‰n‘ ÀQBWW¡¨f¦üyÎëtB§ãñ|¾¶¸õ¸Œa½œa:(-‰Ågi`‹#^+Ï3k%Û‘[yÆÂsë†éåøõQçÄH-uÆtôáéÁ«V;»X“ U§`iæZ²„ZœÕú“j]U†o²c£³QÚ—ÃxŠuèº¹ëÿ›xu­K¼å|±uß‡€aø,!%•±ö,òHDRg%J„7Ğ)ƒÄˆ‡r® ŒúÔhÿı?ÅŞ¦‚lÁ -X¯Íì´Q-+5—;i¾«Áñø»ûÏ?¹ş·eMóeõ¿ë›Ÿ6rúß[÷úß÷ú‹ôÿn­ húít Ù0%‘ SNçï¤bNZe_Dß›_åÓøÁÑîé>éà½uc^ä§Â¸Ëî
?{_,”S W6K—Ø_&ú$ˆG•uèqF–É£©É²¨/	Ãç%•°¯îËæ%	Ëge…^©kÉb:)hüÔóLÛzÃñş›6Ò®Ä¯ÈI£ÊÙ…eÁEƒË¨×EØ\si «‹Ò†Ğ¡$À]Y)Õ)$ó(If8Ã¢QÚ¤P«åv+‹æa)LêÁï'ú·VíĞ§„ù¦TçzG>«+uÓJY"ÀµÛQç½ViÏ¿ÏbÃ’ùe3«Ÿx¤ ‹jµ*ì´Ò<]T&WvŒœK±##Ã71ĞSjfÚ1J°ˆÉeÒ\+£_K#røl%‡/ğ±”–a-g¾ÊO¶Š—å.°Q¾Ã2×¡÷G¶ŸÊÙµ‰¼ê±ŸBT­ğ2vyÔÍ”8ß‡]² YÓ0Ë›LƒD™hZB…¢Wy›ËË»ò¼¬ĞCŒö“Õ»|Ü49TQŸkãqïã	dausR8JµnàÇÛ~	ìËüx0•ä"oq*$ì2D‰”b”ËV÷]<4@­	§_G+2
.jƒÙSå…	Ã•öj·ƒÓI,óA¨FÂíªMU`úO´€‹é…E^ÓQ
ŒÛƒœ;6	–Î	GÚ¾~à•©ìBWJ´µ“¦»Ó%/•8XëÛ:ŞrÑÍ­µnñùLâ³\†h.¨÷’Ùõò4œDOâxª5lö`'Ğ¤ÈõI‘îDK”¸öàk®—5 6P2ŞSû«Éğ¿®ÍÆÍPeh…‚¹‹Hõ«×êì$u H¨"%›
©-lf-qibñÃY ;àçÿÓ´d
Çû„LÖ'Ë{†èèôˆ¸9ğRíïLvGìÂ¹˜$¤ş×á„}ùUC£WaQx¹OErãNåúÒËˆâ4<Ú}SBˆ•DlÅÙ¨'Bë:ç ó”ÌËEŠåÆlº*ò 6h‘ãµ.(‘ƒ›—Çé!©†NUd‹Qc·>²üDß¼ú9P$!0÷ıDâì“U;DÆ?áçÌxğ?HÇx íT:„ˆ¨K¥ıIx.“íS!ÛA±¸‡©Û7Ú®xñü.Z=Ôm¿u'Ezb+$“æÂ¶îß)6QŞúÛ–j¡`X†·~’æ‡OÆ óâ•6Û,æÄDù!°ÛÒ´ènî_h“ÎËÆO!ÿW¨Ö[Æ•wŠ±¬HGïR­`2ˆĞÎ‡oÒ	-¹s­É}©‡²n (£†^ßØÇ<¦Şü.–b^zh?Óá¯U¿¦”lkÃáÿXlgœ$oÊD,wµx>™â±L;˜.-—Ì¢Üå-Q~’õÆİ±cW„§Ğe:½`&éÕâJF‘Á„$´³I f#¼Oƒ¹Ã„sá~äIŸ÷uvyïËi /{K”NÅvNuÅË¶¥•Ì°½¬‚¯¨&ØA‘{‰©œæƒfvAÑm/†¢“2EßÑw,yOo™öæzû"‰^¡b??’«§šsõ4‹…d·ÓÕ #(»—:7ÓÂİÔ¹Ê=»¾í€éî©-—‹I6sp›ŠA…„)ÑÛ™µ2§"D6ñÂ«“ /‹@=¤¼Òp8mòÕ^èNğàíÇìÆ”—A¤s`ú”f÷EÍt‰Å"!ûvÀ¶—Vè‚…w¹ü¢BË*	5mŞ™„S4è%Z}Pş:[8G|ÈQx‰ğXWÁ 6JØ4¥¯ÂW¯=é¼ 9åPRù¾ÒX¯úÌ(HªSâ{¥¿.ò{,êĞ>)$>´7bÍåï Ñ°£(¨¯˜+‹ÙmåÊ“ çıVŞúq/©ıªu,ÀÿÁOæı§^ºù;ñøşıçKÍ?èµßÒü?Å÷¿ûùÿ¢óoê;|ÉùßÜØ¬gß7›÷ï¿_dşÏ||ä£^W,Œ¡êÉ×6$È3áã³ªØ™]Šú3_ªÜÙ|âUª!İ/Cß«v¾‡;-ÏÖ¥9ÓI§qF»‹²tö;{ÏnÍùÄ3P0û÷g¯XVtvÑş~Â±?;øs/œäJäLÃåRšLÄ8}œYQV}»Ò­:«œ1+˜aæĞ
OoXV°q!±ÂIıŠºc·Ûê¼nïQc=Éu|´û÷A4b—ÑûPìŸ<Â¹@ä²!^‘²êGô£7‹Ñ°¥‡iSY9ÕYÑ2¥6t@æ*â;vƒ•ãëeÆKH^HMµ”X¾—J!Vtrh‘©§H“ãg¹æ+İ™yåà
ªŠ´İHNÁf2kÊ0mŠ¤™‡çóLM(äúcNíQ_àæi="Së‘ŒÅñjØl
•#ÿÃ_ÿú½LğƒPMJÂ
ñĞØÕ5³` +Õ©p¼­P¨Ô¥£®I:×bu¨ĞU–Q¡“dÍKNœ&LqĞ†m Ğ~r†£Œ®ÖK‰of‰®1Ä¿òàĞ‹gp%DÄ^ÉÌ¯së¡îTğÜ¹Ö‚ÕgJ»µ2u;Ş«[ÁÕú'i3QP÷0)	w=	‚^(“¥ŠàD$èÑ.`´ÚNO¾>j{Yhµ>tãnıßßÅS¸
Ğöİó~wÿùï¡ÿGüŸòt„&Õaÿâÿmlm ³Ÿåÿîñÿ¾şŸd×f:¨¢œx¤ôF¬¡†½‹FˆŸ"™€óx6£ğƒ¸ƒ)éÃá)|Ì!ôT=ïŠó€Ø{áğ<œ<¤—‡f/Æ/½•Ét._¶¾ë<Q“¿ |6€ÿW^¢—ê=„SA^Ô PÅ‘±´SÁ°f¤ôÏÈf„bN¸ÀŒØÃç®ş¬‡²Ô€z¦õÌÄsñ"¾´6aŸ«É»5ˆ±še< #W6Éİ÷‡°ãîœ˜éßÌè(çÓİ86ˆU3<I	*©šY%pZ}¼°'õ Öp5?'¾áhş¸ûM½¾ş@f~Q£VãÿfïO­İ‚	 ¤@R—ìãó‹qoø•¨pi•”‰7ÑGCõ4M¾Jİ™¨¯<ÂÖ³uZ"P³W¼5 ¦®PWÑ	ÇS¢1ñ¬ˆÊæõÒ ¥Óö¾9J¹êàúƒŒZı÷· ftî¥T7ŠrË"$‹CUğE¢ñÌ•ˆ•³H9_0•™êÏè] 	$ZPZ		pîñP“?¹˜y:ÄPl	¥F2NkˆŞ…fKmĞ$'’¢Ö˜dqÂË€bĞ®Ò·¨«#—iLFï€‘›„0R=XÀÒgÇ;?£ucFo=¡PÌµbİlÏÈm¹	5QR!M_÷ypæd HüŠrã¸Ó>¸zZ“ó}³|P›#ŸIx3‚/U¯÷÷Äzˆº“ìş†ãn½oğøK2 ëdj7ÕÖvSEßœ$p´iœÍ‰vÍ3¥nóCµ3öoL®gæş<pÑÂÌĞApÛ©A	K“Â)¿/Rc&‘êË–€ıİÄ´¬Yp•ÙÁİ‹¸àgRô‰>&Xì-ÆößÓ‘>Ådhœ¥b‡ZO_¢Ÿ-²¨­Zhpîùäqş–ì]sıËóÿ›OŸføÿÆæÆ½ü÷‹|>üjtŒ·ÍÿMt­¾ÎÂüŠ|üÿÖ½B‰„—É(2õ?|èy¢¾áV,­K_Œ'¡ş!?¶xf˜Y•Q£BøxøP	W”Aã/Š$y›Ú§Yî¦÷éÒ)†K£æÖvë|"Í©E®FsŒhy°›‘Ù8uèç{cª”`Hİ% |5ß­Ìt²n{Æäç.åß8q5¿D®ú …±‹)®xæ„°$æßeFIÉò5d'ßLS lŸ[P†R–1{/,Ğ¢‹¼%z*›/*ÀAšÊ¿@b_T’‹†9Í1¾ğD2J”_(Ëë”o‰÷oº[	÷€Ù5%š7:f!	ëÓ(ù,&@ùCÊÚMÑ¯v°z7˜·‘ŞúAØƒ(ÒıƒDò‹ÇO=:¨.ÊŒéÜñûƒ›ä:<FE#»h­'‹¢ÌÏ]Øõ¢á¦V|ãàA¾ùC‡|éO‹Ş:¸FÜVé½*•-rú$÷ÉÿÇ0ˆèó™TPÈ{‡×ücãiVÿãqãñÖ=ÿÿeäÿGSZ}4õp*ÿÏY8!Ge‰()ÉÇùä%È$¡ÍQéÅ7Äón†¼/âÁ ş€"…	”ÉÒ`Û‚b °x ¦×ã°éïùJHq„ø$$(Ä±X#NCÛ&¬töqoxˆw“ğÂ‰\Î‹]­uZêµtË©hiHí|ŸÃİÊœÔÚ­İƒ½ÿRms¤w¹µà%©÷ÇQ/‚"®S…{K(ÿ:/ï¦æêäsQL@#Ã"%Õ„”ó¿
è?o»F1ªO–ö?;&"Ò‘l5Ê•$ê<E(ĞE‰ğı÷•gø_›{XE¢hñ˜E‹2Ø\¶lô®JüûßÄßÿÓ*ö”DO²½È¢OBdÑÀªOxôñ=š=¨	YÙåq’\£·qóD¥C‚Æ=‚˜DD¢ˆh)Š¢ç˜{oºšXGzĞ°%Ã”È‰K7	¡YğÄd€kUA?|³Ñ6uU€zÒk1‰òäŸ”1âóFGKô4mÔõª1¤½š BrÀ\ğ¤O ŒHÄƒ¢)õ%AO9!±jQjn¡<_Å½~Àıçşsÿ¹ÿÜî?÷ŸûÏıçşsÿ¹ÿü“}ş?2N° h 