#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1137862967"
MD5="fe403e5a92c54872bead549af5236eeb"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20452"
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
	echo Date of packaging: Sun Nov 24 18:48:12 -03 2019
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
‹ œúÚ]ì<ÛvÛ8’y¿M©OâtS”|K·=ìYE–ulK+ÉIz’J„dÆÉ!HÙn÷_öìÃ|À|B~l« ^@Š²twfv6z°D P(êĞuıÑşiÀçÙÎ~7Ÿí4äïäó¨¹µ³»»ólgskûQ£ÙØÜzöˆì<úŸˆ…f@È#Ëtİë;àîëÿ?ú©ë¹¸/L×œÓàŸ²ÿÛ[Û;…ıßÜİÜyD_÷ÿÿT¿Ñ'¶«OLv®Tµ?úSUªg®½¤³-Ó¢dF-˜Ÿ'fè‘£ÀcÌ#OZÎÂÄl(Õ¶Œî‘áÔ¦î”’¶·ğ#èRª¯‘çî‘F}«¾¥T`Äi6ôæ¾Ùhş-”MÛjtN‰*K»JlF|3‰7#!ôN½€âïãÖÉk˜ÕÉèÀ`’ËÀô}™ÇpÒlDÉ©³sõ‹pR¡W¾´tŸä±58jí©š4àbÆ'Gƒq÷t8j+$š‹àíŞ c¨iûÙ°3î¿ì¼é´³¹:§£Î`<ê;oº£¬¹³ŒŸ·†/å*EPc at6`¥zDz; ÓĞ®‹|‡m¨bÏÈ[¢Á¾Õú¯ôZq-*y¿;ç*•ròqÌï0º¢ÖX×q“{ş6g'ŸŞef+ëY\Ë.!\a Õ Ì@¾5So±ğ\S¾5
Š±Cø†y ;mQ¦@Óˆ.üCÛ¡ìÉÆQ*	¯ôpáëyèúÔsgÀ+d	ëAöaU·0aûœN/`¬Á¾„Ø³ÈòÈ‚.&°9
8c4è²!´Jej†D§áTŸ^ä“¿‘y@}1,ş-°ıDt‹.u7rœ˜êÚŸÉ7i$»	‹©¬Š]S©êøÜ‡9g|Z—^öÃ€t6A#0¿©(ü<´]Ë¨mÂOÏ=!Ô5¡E­% j9Eå¥Ó4³6®sµüÒõ­~Kª ¾ “Ğ³Là!#ìp fÌ†ß`õ„ò¦+ËøÎ;¢Bæ3ĞeNÃç Ní“¾lA¦€3H3Ó„ÊªÖÒßD»RÓÙ‘›×9 Šo×‹ÎÌÈ	7 ie;Ì;5›HøÔ¥¬=M•JÖùÚŸ×ÎÚ÷´á¥ŠáùÂùœş½¢SBİ%9èûÇ­_ŒZüƒ¼i^ôİ´e¿ÉçÓ'¸Jj9ËVd/&? ŒUàˆ`w	½²CR¯×Õı€šVÊá×‰«ˆÜ):!-®WÌWK)êÉ5JªT2IHÄ S“±7Å²¹)¬¤ÛÊcb¦í¦”*øÄÉê2Ôóç…÷©T2MŒV:ß'Q§&Êœ‡Èó[åLfg¤œpEV*²	„pòa9|+jÒÆ’G_?ëãğÂ¡íÎÉâàZõğ*üâÿİííµùßææ³Bü¿õìYóküÿ%>/¼K´I£9›´§Tš¤çƒçãÚœGh²ò+Jeä‘8~äC¿ç†cÓµ`|%ŸZŠ‘oAŒğ¯OğRè¯ŠùÅô¿
ÿ@îß“ÿ777·ú¿İl~ÕÿÏü¿Z%£İ!9ìw|CÔÖ;iº±ıBÚ½ÓÃîÑÙ s@&×ù(	FzY˜×ÜÆ@àE¼(„0ÇæQXpı=™À³éB&	±O@eÏlÈI ˜a|Ü„Çca=_XÍï}3`"ª“•bAxä×ƒÈUªò8Â'š&F[Ô±6†…Œ&“;×…yAufÄæÏÈ,ğ`@Ğ5ƒè˜ÎöÈyúlO×“auÛÓ¿LQAÉêrVóN{§A>CÄÊ‘åW¾é2Ñ›	¯¢Ìì€ÁæL§Ït(p¦NŞi‡a?ğŞôyESòV?ì¾Zå/iÿyÉá_¬şßlî~­ÿÉıŸbáU›D¶cÑ ÎÎ¿`ü›½½âÿ·_ıÿ×úÿgÖÿ›úæÖºúQĞx¦šú¢ßvp ÿÈœº4àa	 D±]ğ‹xTĞœ,Ÿ´Zƒö‹İm´\+ğlë9v¥jÑNCbÜÿãË#3§q¦e×#ı6Áz£‰e¹åÇÿlsiS^¬4^
ûm¬;W”ŠãMqmgÀ£ö$­ÛŒE´îÒpËÃù)°VŸªg“È#Òü¡®>À´‚‰åÏ±K/Ç;!ãe×ı}>ìØv£+r1işøğ‘”™S%%§™‘±UoÔy<gƒã1,ÔP“ˆŒ-İú, ÙAãÔ½`M:pQÍ9ÓêP@<Ş7ÆUÂXÆÇİçã~kôÂPõˆºcOp ‡ªJ`íÃ£y '­>Í‹(ãNkØ1Ô;'~Õ»½S#^âƒÈÒkÒH5ã:¢Øş¹´ı %mß¹$èÅîô$YÆÕ»cĞ4E›»ÑÊºÒ•‹HAiæÊ‹ša¥ÇSˆ?®ç¦@¨üà¢KÉëØ÷Ä›öÜ?ş4
3€‹.yÊhA€àÂìÅäã?{êñ¹+On´ 7Œ÷ÌlşE—hìîÅ¯şt9HjÈ%ü^Ç^±€Ï˜*^ÿ+é®„éä%ªKçMÌÎå¹==Gn/.@U4ÛF\)Wk¹A*1ˆª®”c.rT[7ÕÃæzØ2®_é•*ÏxÓóîÉ¸¨B¾K+$„üôBY…Ã$<B'‹Óg§/IjÈG8
‹ı9Ör YÑ6ëm®AMÁÆ«pµ›•¶oßiOos¨ã£˜ì/İ~|dº}Ü=={3~Ñ;épÁ`ç&D§°<€tH˜‡¯NG­£[nKf¼­Ë{U}¬ÏUKV—
béô©\Ş¬.ô¶mÄr]ŠB- ¢*zJX·Ò”'9sµÕ ¡±‡ˆ‡ôq/¨¬Ğ\¬@^¼X˜ Å„‡+ÊsljcœÓ
â”÷Ütç4;·_Y¨Ø-R)Yw¥‚µ2ŞW<à4XNæ?’Ú2i÷ÏÆ£Öà¨32L°€½şÈP5q‰c•ô†i¿ˆ¨H{Ğ`Û¨WÏZDkÏ^ö_m©$¾ş sØ}càÎTª|¹1¸R(“¸%U‘Jv'AÇŞÙ İ•4¼È5CôZQ°ÑøIB>üjû	KÔ~_ÈJº÷¾?½Úå>²ì<Ûq¸x‚L{Ñ»=4éì‘C@Ë¤ı×dõ©İœö'­ã[•«eCÀ[¥’%–¾š›ÖJµ_ÅĞ¦öëÕr¶ª’¬/cÿ*|f_yY—3«ÕCé€V°A„ë QIÀ.ëB+˜ïn—êÃCYÉvK»ı =0ùü%’Ÿ×‡+Ò^Fİ]µö~Æä©hR’ŒG9š	–’‰nÊ½Ìø£mÂ§r©úiÛ‡$ß³u¸ˆÉÉš—Û¢9¾ğ»m"wÉ&¢‚¬İÂ6Ì¦±ÅsÏ‡a`ú\Ù’t€/4Øó(@H%noKmÒU—ÃãÖÑø°‡F³uz0èuÆ±î<È8…OBÖÜl‰êKÔ †'Î.¡&q	¼ısÈÉyx^1#$¥/çmILaU¾<’+±«ŸeãJeHQLúæôÂœSáq:‡­³ã|£Ô¶_&	»íZôŠ_zIÂ@R»A€áÛï{ûÉkÍ”	‡¿VÙÿåë¿üš7A˜F-\ÙïV¾»ş»½»ZÿßÙm|½ÿıÿ¸ş»ÀÒ¯f:ów¬ÿ’ô¸Ÿ7–HüëÁÊ|ÏeöÄ¡¼¶ËâAoîb£.¯—•ğºZ½şe¸]R,``øíĞÆ3ç0ˆ¦¡TãJ–ÉïZÒ%u<Ÿ´£àA¯7cæ¿Á@¼–¸„áÁK9¸X\ f¢ù9 îøèt8¿Ÿ‰—EÔROâ¡Ì«LkÓ@oM®ƒÒê{wÙÆ{”³yF	Â)¹{~\I¢’ŸùşùºCêš 6­ƒç¡wfÑ%ç&!~`»áŒ<=ş2uNCØDı´F£Ám½¢®å·Ğü§WÓƒŞà'è;étµ±»»GƒŞYßP}'š^õû˜¿AÈF©(ÆGxÇ9ˆPü,}§©Å”ÖyÒÀh°Äk¸H^Æâi1«r¡XÚ4ƒ¿FöÒCNÅüãßåºçc’• ä®¨¤*‹Ÿ\‘3Ş|õh+G}3<7Ö,5/U¹œT„.‰E±‡<€•Ï€lQ5NWcØú1hšñiR«İCX;‰5B•Û A€Z4¥)Jòç)âé•ü€Øo×#ãİ¤æÄÖâîC§–*­îZºï˜!˜«Óch­:™,^ÇmÒ cÂÍ1ü¶œ:óxCÜxPÀz¹0ä;z9QÛõu? h„B]t‹*C\«Tk‡Q~kàÏRy=Äxˆåœ†?y„şô3Æ¡óXì(]÷P-üŞP”¬^EÛBRÍÂâ`D’a*ÆuãØv©íâEæLÎ$!zÛxÏ­D¼ğ”+îFIÏ@jrf}Íìˆ‚LMp±BsAqaÃğÜ5~03=¶ÄÁC’×Bâ7®¦$ô©D•¨S	I‹õqµºeY `}Ğ9zıÀCçÇMˆX€/ZâcÃ¢åÆ $˜*òb“¨ÅÌhñ€T‰>ãqRåµ]ü»W;´;9ˆÜcàW×›BLò×ˆ>wL÷w"yg@"%@}øA<àE$`¨¬î¶Z“Y JÏéRâwY
Kç»-íu®W¼ºBŠy~ò¶Jì‘N£&?û‰µûG#qÓYË‘Üƒ£lwdBĞ h©Ayü™‹û}'näKäŒ\FS)laB^]è€å˜	ºæ@ØjâË@#è!]î8ÅsìI¡˜0ŠqÿŸ¹‹À€|ƒ3zÅÅ(Õ^–æƒ™ôG,2Û# ªàš–ŞÔ‹HşR#y2|+3Š¨dö.]´'ôÄÑ¨ç:×ñõm1$ÒW-T beÅ wséÆOT§Æ¢<…ìB#"¬©ÄcÇü5vÏ‚°äÒşÕbo'VÛ=ˆiÎ†ø’Çóã0ÆI!e-éT1Îœ5“¦)Õı²ŞTÏË:ãµ¬éåDŠÊ°z/
ƒ!<çåğôÇhq…nB^‚'$"ITw7ğ½$€‚<åÉÛhìÛªİT%æ¼}úşvßşî»` 7ú‰CƒĞK³ßßÊo”„p/ûI´ÁêØ¸âbO±¬uØ!ŞÈs‰Lß%Px;b:öæ]Ñ(¹ô7±³6äÈí“KU+ˆroJlÄ¤\e€Ò4SÄ%¡—ééBzWÖÊOOÔ®;óöpOUQ®Å8h¯XºMûÉ¥\0ßœÒ˜¹¯{ƒ—C‡;\\%àhesÅ¬1cÒšïsöÎ=/ïĞœåâ8{Çc)k3j…1ñé([±ôÀ;cŒiş™ƒ`è9êõ‡ÔJ<=ÎH¥Ş)_©I›óPØicd£‘C‹ÉxxÖï÷#ãQRÅNrÙÔĞ$îÕà×t`DøE8HC¦ba>÷î5ˆ•¿XK˜šŞU8íº‡¿Œ‡nŠß®!|„ˆ½sï/Ñ™	Ù#eâõÎ]/[Yßå
æìíİÏ‹Ô†ÇñoYNÎ^Š«æ)Ğ?cqï\şò-Øl@tL²ea6¹ nD0jÆæĞãïä@[±är‡+ÑMßwÒ÷Ò(°:å2ø‚‚\ïö†00r¥œÓà{|ÿØ…(2²|)ç¡§ô@Šö‚ê¾¨°ÒºËƒG‹ysvÛ¢ì"ô|agüíh&|yä½È]ÔSsAlKÔÔÔÛÓbá#ª+:Í½ŠÜMÓ@‚fp­‰ŒJã‰I¹ç“g¨²(‡×`pÛNJPwŠ.+Áêuº¢‚ˆ½ º:4òq#,l×tŒ™	&š®}j´²}‹ÙĞI™óØÁê€û0Ûş*„4œCÈ#F/÷ÎºÀk{\Üv×ù¯OÚÉX‘İ'°œ¬^…ú•&îîó§xaÀXïÈ°&ş‰ByŸíb¥C•Àæ|K@K	‘*mÄòÆE¾gêY&uÌk±Ê—ôlÅQ[Şï‹u ‡JãGpXû‚;ûy&½…lÙ‡Lózoïöò £ÂR–´sRşŞÍûlÿşsbÈÇ^™ND:0?¾ÑÄİZßòjµ_“6¸À·•&l½ÛŸtNÏÆİQç$IøKu
óÜsÙÉwW¤ltû¥0ú.ÄãƒÎğå¨×ççé ¤Ã›Ú¦¨Şt–¾uN¿>w½åwKMäZg×,¤?hóÈ¶(jÏÄBU°KÈ-‚$¾~.œ:š”¶L„ÍN71Ô¯Î'Y¢8[â³Ã/Ë„< E:4fs6úìo2;xÆ½¯_B**ÎRwĞ=íòD);'ü¾‘¨$ £,,kò}€DJ”LiûÅ‰½¥{5Î»[C½ß%«+£h(S–?(‚Éµ}DµJìe–¥ eQ¹WËÃ¬’˜:°d	Ã>˜K3‰\™ñ$»ûa¹Ğ±S«İôúÓŸ!ú‹ç·÷ƒu¡™bRòiƒì­vÕÜüÜA©jÒšÅioÿrÀ*ô€>Né„ÁL÷œü—,IÆ›n(Pòä ­ŠT²ö›äç·:üz
˜“4•ØXÄÚ‡¯?áÀRÈOÉÆ©’cóãß=Qâ ÉÿŸJ@²¹s	lí&O}!ƒÍV]ˆ Ğ’‹}9qÅ[‚üº ÷ˆ2‰àß<E“"SzÙÎJs,“¼×©Æ¬ÍøàÏ@0şÿô˜÷Q’’ÿ8~dš„Vìs¸´pÿŒy_Ê!©3O±?¯Âó0¬ >_TK„@ê!¶±’—öÅùÕş24ä3:€kky[Úá5†%"?Œ'f3áÒÜ-–pHCc3N¤ÃøŠ‚g©ãÊIv?>@1É~eç|?øÔI4OòUcGZÍY¸÷ß¸SÜU'
]qqzüø“«ÉPu¥Œ)ş=P<C!üL…÷±to GÔ5Wk…Î”Z<¹xø¡3y‡ï*¯ÍºĞ:6ÖAÁZæTR-~ÖÆáD-a*ùr7‚Ü%á\à´nDbÕ¸ãQ“ëä«„IæM¼rÿRÖ"ËîÈ*•Õ¤£
®nôëêZü‡¨%Ì©a|¶òOµP>›1L¸õ_zıÛû¶æ6,ÍyeıŠTc’Z @êÒ¢ J„d¶y€´»Ût Š@‘*·­(Ñ²öïLìÃ¾ÌÄ>Ì>¶ÿØKfVfU Ò´ÚİCDHò~9™yòä9ßIfçêß¡á«y’"Á6ËkÓ ˆJİ~]ğ§¤RÇ(Ùç—ÿ7˜=¡]Í»À|¶Ö/fD”Z¾¢_îà¸’	G ßğ²%ıò¿ÅUğSĞ;rJµZÎVzT
úQ1Ó…cà¿†F«ô#š²`IéY|ˆ¦ïŒ²Ÿ*u#W\¡ØÊ;è1,ºöÑŸQ&Ôş–¤^ºã, W1pÔ>Y*ÿe4ULc¥r9ŸÃ3UˆàöÊÆœ¶÷E‰*ö½üõQçä9ÕÂÜ®b0íÍŠá'ádÀ\øµÜà`¦Zß/ì“+g:*;ó²ººQ©ÌFh|cÊ‚´V×íU¡2©\%4·4ã¼İÕÚÙ÷XõÙµşj.Ñ¢œØgN­9ÿ_7¤ÒêkVƒ€Ce3
ªêP¡Qº:&Ì	å”ªIƒ:ÒQ¨«Ã÷xQ#}ã©Ef¡›‘Ê¸Yİ¬Öå9¸ñb´&}Ù)É|¤™Ìà"••A%¾È'²øÆ´0£y¸é¢ÆHîılÒëN‡5H>¤kŒÏ„½N‹Ş°Ï_	şôcF,Á<L’øû*é«ÓşïGé¯ÙD~Çëe#õğ+ìÜøªßo°Ü…^øé¿j0Jø½Ÿÿÿ1åo”âôà:Íü¬ÆÉ„Úñòš´_Ó4º8XZÉÔøª“ôÇ\õä=—÷dË8Áåd æ²:™òTå?âà¼{ÕKúªn¿Ã>ª¿,‹®ı£)÷ñÇd<’)‡å}80¾ÊJ‡ïƒ'[|Eù…¿A¿O_AåP(«4+¿ıHL}S‘³©ş"‹ŸB< '°s}Ølà·I?œĞßY6”ßˆJø+Â°à7¸¬s÷'ÓñDşQÅ^=ìb<$¢@J‰\İWé7™t:1F†v"-^¤'ã«Ì’ü‡ğ<êhÉŒÑZxç–^Êâ6ıÌ‚a•˜4k$•bô¥/Hù+2š¥€mAg*-Fû²ây©~30jûwiK<Äİ¿X‡ ›×T‘ ¬‹r®Ö(Fœ©»Á™­€[tQé¢tV#Q»S»U}—t%«lUëg4Pãî|ˆÿÍZ/Ë_¹IKÏÂüBMÍ‘y…|ÎªôJô©ñ ¯¸	|ÔI¯"=¡S]Á¹<@d8 ÂiØ7g}=&Hİ>)n^"å o§„Ó>×w3Œ8 G¸Å˜i³ánÄlíFªäWqÅUæ†F§Ê6ÆõÖ“SP)VÉ(·¸å÷!©‹Õ’•¼¾–6¥*ÑF¹ËˆÀsâsw~k0Q¿Ér[-ë¤©Ù3$E5…Ìˆå9¾<*ÀøåOÔxàX 'ï‹eÓË»ãÉ4iúÀ=úé­N¬y•e6“»”¹Ó‘‰È)Ÿ•áâ/5€Š˜õ¿÷S…¡"I Øü4æˆĞĞ„ˆ‘x¾ÁÆ»Äº¼M4ç]+$Ìórâ²TŸ;_|Æß¨dÅ’ïãªP¨İÇÑ¥¼ùX²Q:MÎg£>k›!`ùn©ÅÏßz–N/7¤ß]ùEƒ´”ÎùaL¾+ öçd']¢İÜ|+yy‘†éÜÈüÁµDÊÁ¯<¯–<Ho9Ãh’<Ù
v17›A,£°„…,ƒ=•uÉÜvŸòĞpQ€}¤ğÅ‰i‡'ƒ’ä^äS;¨ØyÅ¬ğ!!PéhÕ™Úù:­““½Ã·â”—3±¾]ĞV<{â9&=İ8oÌã™Z¤•Ó…ÂÑÔ•İ[É§Z£s¶œ?äîı¤vV+ç¡bjµK¼ÿ–I>ë¶»D2Üß†öŞÈìÈmuä0:ÊÛÙ&G–Å‘28šoot7æFYk#ø=“÷}ct>×üÕE¶A·ËÉ6B·Ì+m…¼ßÈ>J›e&ĞĞI5gÊuû•3m™?Wó:ílÏâNÿã€gYˆ¥_×M•”›ŠİÎRÌa"vçbËˆÑÚ0ÀÌCoróò¥]R5óöêôS*ÚæÑIY$¸].r)·ªcĞ_¶â—nßù‚•_Ûƒ¥Ûmÿ”?)?›áãÜ6;f:Q¸0Å·?wÔµ"’£áûv4DI^‰üéÈ+ ÃaÄ½,Gr>¦gë‰TÇ*;àå$lhšS[qkh”°Úke@Æ7[WpµapŸ÷®¥ñú1yÉ7¢µ¿mÎAÁ[)Ù6{*Ïs‰šJ%.´>·LH¹¿‹áíö_Ò‚ÕÑõ¼œÆb5%òj5èëÇÍU£^Á_+?\_ÍD#_@Q1«ÖŞ^  ’“äF.“.	fÛğ0Ÿ/¿Õ‹m\WVù‡%S}Ko1”¨?æ+
÷“NH×ŒH¶OHäıuõ{Å56˜B' ]:õk{[UD%ñ¾³¨49ÒîÒèâƒÊŒBúRVE£/ÿöÃçU§ÎPÁ*”Ç˜µÊL•çâŒ¸Y á–Çåte•¶~8º²ØöÕDce£æ×«>Ü zã>l2MÿôäMå™ÿÇ—ÔË¼ùÇÊ‹Öè*ŠÇ#TÁ?"ğ“„bàü}±Ïµ¥xu¬1~æ×Ş‡a`njR9M‰Í¯ğ¥/Ë’"D¾Q0uYE{VšùEÍÑFŠzQ“}15İ²c$·F§ŠW˜<æ‚Yô¼„rñrºÅ6ÑÀä»ZGšò¹‰õ³ª@6Éd ÅõÙBµ¼¦,;ø\—À9aœÏ¸í”î:şÂ¦³1?“;xV^ƒyù6Œ×ı•uAå¬”êó°Ô|U3äkæ+À¸¤Õá]Àfq‡5!-`ë¦-pàÇúXXé1Û#sŠ
1ÎùTn#W‰şÛI¯‹gLë«gS½'µâ5ôÉ dçañ,™x‹£’„›4íÀ tÈü%¿'ØÅÖ©Ø¥“?^Ü
FıÕCNDú[|ãw0ò›¿ÉÈ#+[uºœı’şÿê­Ç›9ÿ_÷ş¿ïñßâ¿]¥øoÕºÿæ@³Ü|FcšÅv{ öØØH„¥s.¸4Ä¬6ruw¾AÈ.¼´{^>(—¥$«ù2o^éíşÑ«}ñíN{Ú;\íëñ`£É§òRım«½Ûj–WÏÂïëÛ›áªv~°ÓníqÔÄm¦qÓWp½³‹Ñ[:ø°õ¶½w"³ÔÓä
HVWãˆëZeR²-+áÎ_O÷u[i8#ÍÊfB°—¼O ;¹#ëwƒA×–Ä£¿‚C7Wûao l¨Àå…cúá€bHİvÕ+õúD‘‘¥òbùH:¾&ÃÂ>«“9¹û{ğ9¸/†(q …—A„Nm·ÉÛˆ­bné@¬…¯ÑìËZ{\`©l÷õ3_ôÇabØi?ğÅW/9€n	:‡rE[~¸F7ú‡“Gµ5ÅCÄ°ŞÊuì6‰Ñ|<lfJTNe‰¼2Òtà¼•äãÙ¨/Æ±¨¢Ÿ^®8<äQáœ ¸¹zxtØZuŒ™=d~¹‘¡g»çƒ½Ğ`vrU"Á¬Òœ±ù¶‡
íØ[]0¬g¡ÎÙW’£’Ÿoúy…ç1x)ˆ/ÁC	ãª~ÓH’‡ÀG¿Gõ‚Ñ–=–°µÀ.×\+¯uğTG¾¶ŒTÖş××½DF±æ"šó µP¡ôB'h®­»ğ«¯2ƒh FQYL{ºµäI]{ñQ¡Ê}ÎŠ_ãÖ•–?Á×Zí¬VŸ×Mz™oáÄ‘c™ö(³Rb¾M>´a%ø}Pùi§ò×Ê¶X·®`ü!¦…y¸?Š`058¢İ>Ïf¶UiTëŠÛG€ªä„¥€¹›Mƒ´š$M*Ò~éïïœ´v»;íöÎ_°T93”&*œìæ`¾BCÉêÁY’3UÒ9Iëh–sAÀ$CŸ
›Ãjê,Ï\˜LêIèCÇÁ5©¢DîÒÂ:AúÓXè”Üù2Æ¦œ~çn¤%™R3g¤NŸJ™…E-EbÁ½áıƒ>üTªWÂ¤ôU3D—¡“ ÁMÿü-ĞCòh	¥Ò¢è ËC“£k3=i„u5Ëõmı[¯`XQi(ŸV¸î›åM*{c*—-XË¶J%u\x„”5pÉZ/m+å˜w&
™fÈL¢özàúˆ>2éê§‘ˆëhÏ¤¼ÚúIš½xö\È;Poa‡„ãÍ¯äoš¦Ç0†y€{œT/Ïpí87şIV£¶99ü\ou¶Ä”cL­I¯\~$2Øú)€Í¿ûr[ÁHúE†²¶O¥y™r¹lvZS2õ{éüÙèVİwe[< %~ŒD² ÍˆÉ’Vº¨K	T|¼ıg¤²™Œf]¿Y¦Ï¤¿nf´‘ĞcaıÂ™S¼ĞÍhMmµYVT%rq¤Ök¯ùL|W#`´ñvcpCzûÕƒà„½ÑÁdÓ2V±ÿ»²‚¥İÌèÕ«ä«=OÕ á´ûè m£uâ–P	çUàrÂ‰‚€—cuÙ'DL¼Í¦Ô7	cFÑ40Æ¤Çy³ú@WD²·ï“Ë“x6"Ã[ô8Î œqtS~&g£\·`}W«U$¡—_5`¸ğº3Ñ.Ô—rˆ19¡“;™öC¬Óöš‚;øe85VG=ç HSÁyöb]Ø§xÖ?1|€¤JÍ¼'*˜¸Ï÷ÍÄ0ÀXQÖi B¯È…”+i¡gÙÎ	zÀA•µQ8%àÒO?€yº~ NâkèñßqoeÀıâÕ,¹Îì¹!I“Î˜mK)ïdô¸+õçËŸ0÷	o…-qé÷Æ*Ã0¡[ê‡w8«"dä1™2ÑxñU]ê…ò(aÃ!»pÓwA4%Gå:«ê¯¬`]uzä3ì¡SsŞx¤IáŒƒ%‡Iê}>C*z@&’TÖ*×@*wü¡23,yŠ
ûa=›¸„*ÑÇÊ0BG—ø²
Ñ¤e‘P~ˆc%óğË=ç¼ãl˜d¾0·ñÀ®8yà;¢Æfÿ/r˜ïŞ÷÷2ş_6Yÿß›7ïıßûÿ¾[ÿßÒ¼[Rù’^^+_ß–+oYvøÒ7œ¥ê_È³wi‡¨ *f4s	œM"ÉÜØo™àƒ+ƒæ·õ.ª‰4İ˜¶©İbšŞ%ã#k%øgq¸¹ºl™xÆÎg@úBªµuz’e…«¬J|¡ B2·Œ6„ì¸ïšÂ/«4¹Î•?9Š“ bÙÎ¦åØâh£fîyõ]É¡vÁØI¿~ü®l"ZØeéqK«ÊÙ[šõQû™¹R² Q¹B(RÒ)0	-ÿ:²Öø¥aÂ¿-äµ[‚©X"‡RJ JWSHé0zèò‰j?=è/pŸj¹ÂÖäkZ(áH³eo‘œ†€LŒdY“È$“È¦7wÕ;‡'ëÅ4ó+•)ò²`~ìLƒé,a¾–¬GÓí¦ómªª*¤vøÿä´C/@ZnI—}‘fÈB£×Ó¨Ã£îÛÓ=^ñ2F‰I·ÕÆr†dh²ã£
ä)1’!ŞaƒxüÂÅY‚Ùşòï¿ü_X¥Éø<Æk8Ê«©YÕ$è§¡K’ŠÈ“RsM”×ú“÷—¢œu}]¬›»½Ú³Ï¥Sl5’81š/$È0êhˆTAĞ¢9U™äË@‚‘uµ„ä+WP$iÚ"& JÈˆ¥<ê·’ú¬Xhñª0åV*EÜÊDñÔ/‚ õH‰q_¿{ï[$şúàh¢y¦â†yIP:ñnüATÁ*À;û'­öáÎÉŞ·-íKï8LüÏÕP¯ŠÄšCáÉP¤Í:İjViÑ¿ÑÅD|ÂÎ¡*Òl‚%›œ…£hMqÇÒVrùÒ“Eñ8!q©ÑĞÌßfu£ºa†X0‡­Ön÷ôw¸NÍzê:ú(vÃó(€¾oÔ&áèO»ßÙYÁ½—¡ÏÌ!˜Ój¡ WŸUàÿt:éÌ}Æ®ºç3+ZQ2«ï‚òËç†û^ÕÜgJÃ%á†ıGb–ĞÏ)êõÚs/ÒëİÍ†‹m–UÀşIG[!2³©|ÂÑéI&KĞïãi'UÄ0H_®>1…¼ÚÛ9ì¾@@µªú…B§Œª­³‚jyÉÊ9ì©Øô…ïªÍ7dŒ\b967²Ğ½úm$©ˆ!#ùìG‰c„ÕQºü˜lxƒ|œ^Ô®ÆBÁL uWû´:x»Ë_»}ŒÃ7B¨á]ZV÷¡ò`<E|: œ¬M˜ŠCÈÙÓ‘gƒbt<$pÑ¼š}Ø'“ }r©ôË¿cE8ºÅmÇ \sùÈ­Ì„ˆfc8|çœZzw0M²x©’$ŞN¥2™Å—¡^»¨<„SO,NX¯?¤ãQî6I8ıS»õLÀù"˜¦ÁP<’]ùB#!=©Ów]œ%|ÿås{ßÜ¿âp] IŸ'æÛT
Û‡¹.`£†³DøúÁ	œ¦(3Û'õK>D¨XBz!>TêKíÍN~ˆHnAôdñÑ%µ=Rëà°l–#L~6êLÇ“	îR{‰öRñ'í
¤•ê ¼#şiçÛ6:òËi2]»,@¢ ‡/V"K`îQ„LM,ëRå¢mƒ­7tK¤$¯¤Xª~8I<ùc7ÄG4”ƒ$§Hìli:œ4Wkğ?.k¼8ÒIÛYõ2{Ù¶>´I°¿óİÁ–ä‚³b€73GÎš¡~hÃC¡× ³…*I0.×^$œ@Ï±Õ«ìÍ˜®VŠ@GZoØùÙc•¥™çJ’¹Ù„ÌÎ_ÑÄdK·åó!½Ãğ¹–¦R7&y97UÒ€®Ó|‹$;4^sQ&Y­lê åû¡­®ïd t¿f˜=½af¨Ìn™å<4ÖÏ­•;,£Î{rgrñ\‹,:Êû{¯:êFè±oÙ6åÆØø¸¿ø§UdKXEEÅÄ+6êÁØ#:ı0œÆã„¬¿ù'p¬™g›Më9×R« “Š.AÀÚoÛr_:í´ºŠË
‹Ê*Ğ€şåÇr“bú¢‚Q6Ëi{¿©uÏËìkVm¦™bÏFvi¼*ÕHÕAİÂu ²ÀşŞëÖa§ÕÑmï´àr€WÅJeõÂQB›çhÜ%„£ĞÄ_êG7t¬£rÆtéÄZvwŞ¶Úİ×»FÅßÃ:/h®øš~Acü_]lQ_îªdœ³7·è†¤©5ö”«û½Ê:•98ÓVGÅ¥UsìVS›+I‡ÊôŞLÑíèÄÏæÛpj
2QV¤ÍexÑåöÌŒóÌŒ³¼¤º WBDAïáş„
ehf—v³‚ËC‰0JqÛi·ö[;V­J0ê¨ ÔNmD£î¥»‚âçø‚rîè™Şí(Q§Ac@ÒÙİMŒª¨fşüìøùv‰ş¼qœ[ê]ŒfòˆüdúÊ·/m*8ğßqt†Úo| ´X¢0÷„JğLåo‡µ©éùI×ªÁV”Z¢ØxõLc,S´p©ëL9ÀµÜ9vÚÀ‡~S ;ìÉö"ˆèí.™*;ñHL¡ID)eêPÄ3§ò…Ô“/òÖaémë„_$ß Ã®dhˆ!äòİd\.#t¼Í5¿7 ŞÒWÎ"d_P£¯Yj3OUÂ­îÃh0Ö´¥aYxÆÈ"§'/oñ9Ëgõsc|‹%½
/šÚgúÃPí+ğá‚é-É{v—k 9E“Ù`€3Â<–_ş¤ãš,å-Oö|/Eóï %†Fxúô©¨´¯
ÆÈ|¨[4Îe´(“²0vUñ*½]£nÒ*yO½‹ã•ÂFÓ“8º´Ÿù3ÏTÙKıMeEÆr4J%|/Ä›fğm‡WÅ	]Õ€µôx`Ô‹ÛÜJ«K×Z-¬ÖªUo£«6ºæ¦tØÂPÏcó°IÂ¡s¨4%Œ‚1*Ë&3dh<Ë|ø˜³CøÂD¯ğµC5óù`çíò$;Çİ½ÃİÖŸ›¢$P5$ŒñJ*ÆøÆ×+Cé¶†¾`§¿ü':‰GÕŞ˜75AL€ü‚	êÀÄãÁk!ğ>É"lÀÉN[²è¹ªëdü¼ßÇ«Ù\L&‡~fÿV¬ÍÀYQ³ÉîÁÜ¼‚±™#fz›7hQêâ'«F/5*„Ú6¥×Ú~4x°s:˜öèrb¾À=:ŒãÙdº®ÇP6é¯{Ç’oÈ5¯é³ÑOÑÄJ¬ÃÄL|f]¹y(w¿Y¢3cµÚşÁmGXË<Ê±¬5×ğn¿Ÿ
)ÕFmî)lîŒ'JãÍ¢Ü„=qRHCè9ÇÖòšqeêÎRf‡ITÉ*¢³÷vïğv¥â:Æ%®òQ½€ü]b9»{°|¡4au^Ÿ~²®ìĞmPgĞmq5E^Ûy1“)’Ü	îÌr³U>)ŒÉtM>gõ/s–è¦)¨æµFe‹ıkáf-_¢Hv¤Œásëı¸ñ¸Ú¨>ö]‰´H]ÖöÕËñørVûR(›5 âq‚`q×|"ueyŒÀW…9w–Ãßô‹3íæ†Æ“²©i@Q¼ëçæoK“´ÕaWÒÇ)ıZ]{S6,egŒm
Irpïúù³ı<BÎ—Ò¥.Ï½•k¸6ÿ,ª"=dİH`çÓŠßáo^Ráëñ]0‚¶2ãáa·š+?„xKøDÓGú&‡¯eg¾ìVAq‚ÍH½Á"kÀÂ¡*.“ŒºYÏK@6Ü¡°±0Sõn†e‰¢Wyf	oQsúĞèzç¿ÕC¿ñÒ¯Õø„aGv³öÍïñï±¯¦¯ç£A?İŞ‘´½+ßÅïä…Zbç›kÜXlD#Ïø¶uâf#|ü$OÎe9²¦#^îíKÕÂ‚Ã°q&5ŞâåŸ.ÔvİE_lÀu'>A¾;s©Ó`ØHÏƒEUXiÅ¢ÄAü>œvùq]Å/™!˜¼ï´
jZ--Ébìš–…=vİÁX´hq·w½ÙØ:—Â¹±‡cR§7zé„xe^[8)R£y]v‹m8MM¹-o$M?Í+¶U­½Rb<xü¶2H2—Ùò'ç²!-IF ÕË\Ş†ædHYİækD°‹ªñI‡‡­Äèµ®2‹Z¡
„XØ¹ù)øJšs·¨ßMçµñv©µ•ªÍTÿ½ˆV”J€°„ÀípD1l°)¿Á’H7W½Ÿúæ/c›4ÖºÏØ¼¸_0F§Ò™Õzˆ©j¢Ô1;ãáxoµŒ6¡©¼R ûØq.ëh4¸&«©…yÎ9âPYòP–ŒÊF®‡9Gº!Åê®É¿	=0VÕçÌ²â¢¤[½ŸeÉ˜.Ğ=3›ÆrÜ”=¿İ‰ù02MŸ§_E¥]ØÍ…ù
Ü¥F¯hâ´Óï÷i1OÇBù5Ä£v
ˆØôf]—mXWó+;9d‰ ×˜©Å„a¿S	ßªô:	b4³wY0h]e‡%‚}YÉ/ÿ©ÙE˜$¤ú×H¼8&rŠgÊ<-0ˆƒš'myHYÏPƒ›hSõŞáïuQ2ı	Å Ë—_…%Ş‚ÄVAèKÄàÏty–Z-²*_ä»²CG^^ßM9&`OØ¬ Ö—Ü
BFÖÌ¨N*Ìª1­,§ÆähDqƒM—8ª^£ë…½D×Eê~ÁöñBcCŠBdîı#!€™ÑO$1Uo)ç,Â_(T“
ÓÚ8ÂøA:v÷r.$‹m®X)Âº¤Øx" ë€ŒXŞúhk<bGB¨ò‚N'†2¡4wI0‡„:juÕ*Q¡¡÷ Øù’ce”ÿhx]·cÌ_)S¥Ô¦j°–ƒ™ÁÖ,O§¸÷Ëæ{ï}DíÃ`
k
GÀìù#kG!'Ü`W~‚M ïğ¤H'Æ3m:ß*MâDÇ!Éº›İîFÆL-íê’¹E	š“6†9a…ös³¶leÚrÃÆl©û©®İ¨~.fu†™3ª—­ˆm£?Ê¥…½ªlÆÖ	,,3Aâæw$:¿rê!.[B½£ÒGüM²Í§æ$2ãûY°¿8«3â3+ÍÊILˆ2½r¦×KÎÀpw&4õª$3éNgâôL[¨5Q^)]AÛ‘&{’à¿b÷›++¯½¦ˆ¥|Š|—Õ	¤®ÌŞ.éŒ9=Qú·;»¯¦ãÓ~xåÁEÓgq|)•dSMâ££0]i—–áÙ,…m*XäÑM,b$mm+¶Ã æºê7f»Œ´r#T&Õ„9šÙÃÕúò óŞ?='ˆÜ‡Å>ÙZ_ù=ğ‚¦Û™¶b~38÷—`%³ÌVÁiÁÊsbwË]YªXj•øÎUóPr÷¬à@b¦›ìí…GÛ]lÖ‡ó¼ı»´p—…R:ˆ¥¤Ş\È‰!±a8õæf÷$k`k^¦jI£f®®;8q~‹ÓÃö5'{`\Üo¨"[’§|M¿§—âr°©îŠXñQ/5Ç—=
‹ò8^70XVUBZßfq6üÅê†•H.»)ŸºøX¾©
XÙgĞ7SWèfS¹Œƒãı½×{'İ×'PF÷àh·WğR {t8ùr-Ôğã_àf…Ûˆº^‰kXJÆåM½Ô.¨qcŞŠÒø<„X@4·ı÷ç1"Ğ8ÌÈê@ŸXÉ#É)‘¹}­…•òrÑÈ¢p[oÃ ëC3ùò§cˆ:’Ğó´$}ıc´ÿ`ÎÉË“¹“öè/+™È K­„ÂQ¶W*0Eö\ÌD)#1tIE	†Êâ(@Ezr,€
õÈqæáå>ÒuV¥Š*Ú™lÜ;}l'Âü'Óñ±¥Î9è2ÇœWpª9ĞÜ±2Ou/]DÇãdúZºæË2®3æŸ¨ï·Åÿ«LÊáoâÿçéãÇøø}+çÿ§Ş¸Çÿ»Çÿ»)ş_‘¿ŸÅÉ}ªQüä	™¢¤V=`ú.+¾>T¯¢«`Ìºv½z×úpÏªuĞíO…k«M°,{<ª@{Çí5(ˆ¿* #ß©ç¾´=këB‹OzÀ®LâğJ Œ*ìûGÇíÖñş_ÈcD¢ø»ßµw;ßÓ××øn˜³0E…a]$ğpÆg‚H †nR.ì¨6-ÿV‚`¡}­TÓ –Ë0‚&8…øŠ2ë¡<:Ÿ÷	ÚúY4›¢òPü`èçB00—ÀV¾ÃÇjl\¥*™¡©4Ğ‘ò!.•7¢hH…¾|ÊrTk7¯…ó¨zæìÿTÀ»Ödœ|aü×F£¾ñ8‡ÿºuïÿí~ÿ¿cü×“w!:eM)}IXçIbWÈágš|—o©œŒ^h+o*I/Eé^!8Ú9o4é•÷×ê‹÷æ>".¢8™>6N˜ÔH‚ÍñğèdïZÿî¢“_-í§ÑÅ5ìÕ£şº§E3MvÇUÔ^#%	 yx…²vºgÿ¯TÄã¯{ú– Eõ†î›J•Ú;{»GbçàÕ^ëğ¤Å“å©.WàÈê™w`Ó>“T£™UŞíş¼û¶»»s²ƒv¦á¾÷¹áˆ—r*3F¤ï9…&>-‘Läw­ı×8kŞ
Ğ‡ôé÷Ù¦l§´Å¦‰’6=›?„1Yşî£(ˆ£¬ô(ĞØû§€Rzë·€Å@ãcªûlúPBîı’aÀ)!q‰ú“êÆ–Ø?éä"e#ø½ü È"¡T:4A¹‡{Ó>"9Ümú—#DØUÑV_IE=¢V¨|È4B˜bÍ3‹vf¿Lùß X×™Ãt\½˜ôVÍ.äEJÖO«z,ò8PĞZ`ä¾!ƒœoNa]~ì_"SWÛA¯{(¿9:>ÁÖiQÍ­‘C`#¤b|÷ĞrVT/è½)_hMKÆ¯{. Ÿ,Fá´Ú›ÕÙÅp
œ¹'«f³Şxæ9oÌâ[¸%^oGÏ¢¦“İÖü¶Ö®dKÊÖæææÓ?<a‹%lKMİĞòhã\ÇdášqıÙ¹™ëfmQ*õ#BI2Êı,÷ñÙ“î“­\ÛÈ,é¶™µ9Ú¼"€çwa=©Ö«ußËXHÍÓ9˜g¾^	y;‚&ĞL&2o€…T7p•Iİ
ñÍÕÆSL¶Ê=Y€Â³î‚%XIëóÊ¢U¨Õ{·ç™KÏ¡úkjşnÏ³‰ÀÜœ	¿¥6…ô“Õ…UíÛK»"K‚¹İlP?çƒÌï\eQç¨^:§‰‡N¤Ú‘í§UÄüÈ¬ÉFA‚¬‰†İ£9Ci:¤{Ãe4}7;§áÇá$n<˜ˆArZyœãNˆ¯oy¾¬jzÈ¼5m ;]wo·¥RÍñ8€†îø>Wx_I¤”ĞÃ —…§Y?«D£•»á±ÇñøÇ°7E‹’.9c”µ'“ š}€3YÁCZ-Î÷å uxÚİ;iXéİlœ}øLHz!‰QT8æ÷Ó1ì_rjõ¶U­Óîc‡Ëwßæ*G¯z†¼5ò—ô@Û­3?l¼hŠ¯+«ciO­@]Ç­zD@J_ò8¯<áD¶†è±ˆÄ€Q¸GÁQÏ‘°ˆ¦ÔaÏVñ¹)«pm¯~üÉ÷Lˆ 8:nš57‹JĞ#Œ™›ª<˜¾×níìS©rï7ë©Æa0Ğ…I€t Ô"ËÒ#Gç3&Š3F=¥“.cülî²9‘”Óê#[xGéá	çÙ“ltÓW^+üTÁÎY«UkİÏ¢Äû>1"è½ûãD¬VWé²ûHŒÏáçü>G­"ÁrõQª“†I=7$“1ªW£êE†“ òhP!¨&›Z›—I-Û\˜ñ¬Ç”C]í]\ZÌù’g<\Hu²ÔiF^•ƒÎ;5Æ©ßj4Ì€z÷¦Xw”¤gKÄÉ¤’ğ•P¯>«RÎÏ³ÕZ€¦V¶:îNû@ßFLîc•à1Y™u è‹Rˆ¯Oÿ„ÊíGš›Rv\t©¨ôé&Ó>øú.éQAÖz<¼zøB]NÛ­7{nâuyuİ+MÃôÎÆ-İ6Æ=[ª}íqç#8ÃšU*|bÃ9ÕDSµ~¿2áûÅPBŠSïÇQÿvÎéÅDqH‹ª&ï	·2áºÂæ;vß(§—dw¼¦}¬ùwÕdù3MÅ·jğoÙ^ô$­C¥'!úõ»jãEo IÀøŞ½ûÁÆ±Ôn½mıY|»ÓŞÃİ£ãyßµ»[ácˆ%mƒ "×âè’öDå)>ïÔÏÎ–èüc½^é‡WÀï_NßÃf¥ÁÅc}<Ÿ]½ ŠÇõÖÈå¸Æ~œ&Sõ=˜¾7b.ßõ*ª&<7.³éfúÂ}/EnúÃp4C`=‘ÌÎ¯X>-†ÁûPğôGƒ@<FÅ˜â êÊÀœ{Ğ?—ğœnBìKeİsù4 m¤$Œ_hDe28÷!TH!‡Ş_“ésHÌuwHĞ¼†Gì¯/« QÍ›ô÷ßÿày…êcn%#-qùîÉDºõ­Nö€Ä¾ÛÙƒ›½çB¦)r²‘
	à´SmÍóvIÿ½(DÆå½wøl üïP
#ä|‡ÁyTÙªş¡6‰C$‡¥Rä‰$ÏB©)vN‘Ä×-hf»s'ÂhYöíºÈg¥İÍE]4¹¦göê<´w†,Yÿ^vn¡6iJÍ©=@^hlÑ.d[Hı<Fp_}?ú;ş&r}¹ÂÜ2e+Cs$\n_ÇvM§ã2y—UùÈ ¢éçÛõC³úl5µ;_½ní|
ñ{Fîj»UİBáº½İœdS÷?ºÉ>¦CÏ”Û+ Ê©§ˆ”ó.`jÂê(œ­³Aß-f¿&õßşµ±Ağ7öŸlÁ_ØÕØ¢;^áİE·G[•z—òã6\Äêß¥5¨Ï­i¤­YÅİ½ò÷ø ‡BÚ&ã©¶ËÒXó<cÉõh||Î/D¶VÅÙtÿ²aéÓØ÷AB&?¤Àô®ºÛúüıx’‰â
ÒÌ§	§cŸ«ª4]oZÅÜrx@¯vhßW:³Q˜üí¿T-ù>q³MœÂsu´g#æ€z®òµğoÿ±¸:C»§¨¾“±øq–LµV5U{¡”]ÅA´ás=¢e@:ÅfWA4Àgxôµ,ØúâÖæÑü‘†Öğƒ×ÈÔ¨%ËgÍ¦¢ZÚ¤ebc$(p”ÀÅU(ª™)óºĞéx<Ÿ¯-n=.£dØAg˜JËEbñ™E@úÛâˆ×ÊóÌZÉ¶EäV±ğÜºaz9~}Ô91RK1}xzğªÕÎ.Ö$@Õ)Xš¹–,¡–gÅFµş¤ZW•á[£ìØèl”öåp<Å:tİÜõ¿ı—xu­ñN¼å|±mà‡€|
aø,!%•‰v*òHDRg%J„†FĞ)C¦ŒMå\ õ¨ÑşÛˆ½LÙ‚Ú¿^›Ùi¢ZVj.wÒ›W=ƒãñ^ú]ÿÛ²Åù²úßõÍÇO9ıï­{ıï{ı¿Eú·V 4Hıv:€lÖ’Hˆ*§ówR1'­²/¢ïÍ/Œòiüàh÷tŸôğŞº1/òSaÜ¿fw…‡Ÿ=/Ê€+›¥Kì/“İŒG•uèqF–É£©xÙÔ—„Á÷’JØÇW÷eó’„å³²B¯Ôµd1G/~êy&~n{Q{Š&MW¢_ä¤QålˆBÂà"‡ÁeÔë"h¯É4 ÖEiCèPà®¬”ê’y„¤3œqÒ…(mR¨ÕrH»•Å‚„°Ç&õ€à÷ı[«ö@èSBŒÓNªs½#ŸÕ•ºiã,qàÆÚí‡¨óŞG«ƒ´çßg±AÍü²™ÕÏÃCREµZvZiÜ.*ñ•càî’FlƒaÊÈDñÍè)µ_3­ %ÔD|™4×ÊèÒÒF”Äˆº[É¡Á|,¥eBË¯ò“­â¥/¹l”ï°ëuèı‘å¨rvmâ¶zlş'¤U+¼ŒUu3%Î÷a—,@Ö4èò×ÅS&Ö†–P¡(ÂÕAŞæòò®çE…</+ì£ıd3ï7M<UÔçÚdÒûøDÙ0ZİœR­0ó¶£ûÁÅ2^ŒD%¹È[Rgü		»Q"¥¥Å²Õ}7Øç/„£óÁlŠ©òÂ„áÊ{	5ƒÛÁé$’Èù T#áöÒ¦*0]'Z°ÇôÂ"¯é(ÆíAÎK¿„£-g?ğÊTV¥+%ÚÚISˆñßé’—J¬uŠ~mo¹èáÖZ·xü‰&ñY.C4|Éìzyş¡ãñxª5lGa'Ğ¾£ÈëIñÄZ”ğ÷àk®—5¿602Sû«ÂĞğ¿®ÎÍPeh…‚¹‹Hõ«¯êì5Q$T‘’M…ó–6³–¸4‡DüpVèß#øåÿô‚<™Âñ“Á{¸<±gˆN‰§›ƒ>Õ®ÎdwÄ.œˆhòàAêzNØ—_54ö…—ûTT 7îT¡/ı¸Œ(NƒK İW0%|YIÄÖPœZpR! °®sî	0OÉ¼\¤XnÌ¦ç"aC9^ë2p9°z‰œ’jèTE¶E1öxë#ËOtË«ŸEsßO„ ^À>Yµ/T`ü~Îşé ıI'ƒu©´?i8Ï²"2d;(÷0õøFÛ•‚>ßE«‡ºí·î¤HOl…ƒ’ClØÖı;Å&*Ã[›¡V-LËğÂ¯SÒüğÉô[¼²Âf›Åœ˜(?v[šİÍı`ÒùqÙØà)äÿÕzËxñNšéè]ªÄƒí|ø&Ğ‘;×š|Ğ—z(ëş2jèõ}ÌcêÍïâh)æ¥‡ö8~şYızš6P²­‡ëc±ñ¼)±ÜÕâùdŠÇ2î`ºÆW´¼1‹rC”·DùIÖ	wÇNŒ]Â¦éô‚I˜t¦1ªÅ•Œ"ƒ˜$´³I f#¼Oƒ9Ó„1úäÂıÈ“îîëìíŞ—Ó@ö–"(Šíœ4f	Š—mK+™a{X_?PMïƒ"÷S9Í#Ìì²Û^d''d¿ÁïXòŞ2íÍõöE#¼BÅ~%WO5çêiIÉn§«ÂPv/un¦…»©s;•{v}Ûò%Ü-R[..“læ >C-:	S:£·3k%dNE>ˆlâ…-V'?@^a~Hy¥áğíäÿ¦½ĞàÀÛÙ)/ƒgçğ`Pšİ5Ó%‹„ìÛ^Z¡Şå:ğ‹:-«$Ô´yK$§hĞK´ú üGtÕpè’£ğÁµ®‚l”°iJ7…¯^{ÒõArÊ¡¤ò|¥±^õ™QT§Ä÷J]ä÷XÔ }RH2|hoÄšËßA£aGQP!^1W³ÛÊ—”&AÏû½¼ÿôÇ½¤ö›Ö± ÿ?™÷ŸzıÉÓïß¾ÔüÃ^û=ÍÿS|ÿ»Ÿÿ/:ÿ¦¾Ã—œÿÍÍzöıw³şôşı÷‹Ìÿ™œ´3ÀëŠ…1T=ùÚ†y&||V;³KQæB•€;›O¼¢J5¤;ãeè{ÕÎ×âpç åÙº4g:étœÑî¢,½Ã£ãÎ^Ç³[s{
fÿşìâËŠÎ.Ú?ĞO8vágcáe€“\‰œi¸\J“É‚¸§o3+ÊªoWºUg•3fó!ÌZáéË
6.$V8©_QW`ìv[×í=j¬g!y öü>ˆFìùóÑ zŠã“G8ˆ\6Ä+RVıè‘~ôf1–¡Ôó0m*+§:+Z† Ô†È\E|ÇĞ±¡r|½Ìx	ÉÑ©©öËÑ÷2C)ÄŠN-2õirœã, ×|¥;3¯\AU‘¶ÉÉ1ØLfM¦-P‘4óğ|©	…\Ê©=êÜ<­ÇAdj=Ò€±8^›M¡räøùçïe‚„jRVˆ‡Æö¨®‘˜X©N…ãm…B¥.uMjĞ¹«C…®²Œ
$k^râ4aŠƒFÈ0lAş“ó4…`t-È°^J|3Kt(ÿ½ñ®„ˆ÷+™ùun=ÔÀ½
;×ºB°³ÚâLi·Væ£A`ÇÛcÕÃíË ˜¡Zœ6Åu“’pW ±Ñ#‘ ¸àµ€2)PªÆ"A0p£ÕvzòõQÛËBó¬õ) ;îÖÿíİx
WÁÚş¯{Ş¿Üş{èÿÿ§üä ¡…IuØÿ‚ø[[Orüß=şßÒÿ³ìÚLU””Şˆ5Ô°wÑñS$p>MÅ(ü .Â`Júpx
ŸsH=UÏ»"Å<àvÃ^8<ãG‚ôòĞLãÅä¥·ò"™ÆãÑåËÃÖwç/jò„ÏğÿÊ‹AôR¢‡pŠ"èÑ‹ª82Öƒv*vÂŒ”åùÂŒPÌ	˜{øÜÕŸõP–PÏ´™x.^„Ã—Ò&ìá³I5y÷¢1V³ŒtäªÑæ1™õÁêaÇİ91Ó¿™ÑQÎ§»ql«f x’TR5³Jà´ú2x#`O:ê	@¬áj~N|ÃÑ$ıi÷›z}ıÌü¢F#¬ÆÿÍŞŸ[»@H¤.ÙÇç“Şğ=*Pá8.Ò*)7o¢0†êiš<º3Q_y„­gë´D2( f¯x/j@<L] ®60¢N¦DcâY•Íë¥AJ§í}s”rÕÁõµúnAÍèJ©nä–EH‡ªà‹Dã™++g‘r¾`,*3Õ_Ğ7ÈhAi%$À¹‡‚\Ê=ÀÌÓ!†Â`K(5’)pZCô=(4[ªhƒ&‘8‘µÆ$‹^ƒv•¾E]0˜X9\c2zŒ\ÂHõ` KŸïüŒÖ½õ„B1kÔŠu³}<#o´å&ÔDI…4}İçÁ™“ õ+Ê	äNûàêiMÎ÷ÍòAm|&á5Ì¾T½Şßè_ê2L²û»õ¾Áã/É€®“©İT[ÛMY}s’ÀÑ¦q6'Ú5Ï”ºÍÕBÌØ;b_ÏÌıyà¢…˜¡ƒà¶Sƒ–&…S~_¤6šDn¨/[öwÓ²fÁUfw.â‚ŸmHÑ'ú˜`±·/ØOGú“ q–ŠFh=}‰^ºÈ¢:ZµĞàÜóÉÿäü?,Ù»æú—çÿ7Ÿ>ÍğÿÆÓ{ùïù<|øÕè<™l›ÿ›,èZ}…!øù<ùÿ­{…	/“QdêøĞó>D12|Ã­XZ—¾˜Ä¡ş!?¶xf˜Y•Q£BøxøP	W”Aã/Š$y›Ú§Yî¦÷éÒ)†K£æÖvë|"Í©E®FsŒhy°›‘Ù8uèç{cª”`Hİ% |5ß­Ìt²n{Æäç.åß8q5¿F®ú …±‹)®xæ„°$æßeFIÉò5d'ßLS lŸ[P†R–1{/,Ğ¢‹¼%z*›/*ÀAšÊ¿@b_T’‹†9Í1¾ğD2J”_(Ëë”o‰÷oº[	÷€Ù5%š7:f!	ëÓ(ù,&@ùCÊÚMÑ¯v°z7˜·‘ŞúAØƒ(ÒıƒDò‹ÇO=:¨.ÊŒéÜñûƒ›ä:<FE#»h­'‹¢ÌÏ]Øõ¢á¦V|ãàA¾ùC‡|éO‹Ş:¸FÜVé½*•-rú$÷Éÿa Ñç3© ÷¯øÿÆÆÓ¬şÇãDßóÿ_Dş4¥ÕGS§òÿœ…19*KDII>Îã— “„6G¥ßÏ»aòz¼ã(Rˆ¡´H–Û…bz=	›ş¯„GˆOB‚BaA‹5â4´mÂº@Wa÷†x‡När^ìj­ÓR¯¥[NEKCjçƒñ9Ü}¡Ì¸Öníì´€ìı—j›ã ½Ë½¨/I½|qõ"(â:U¸·„ò¯óònZa®N>×õÈ42,Rb‘QMH9ÿ« şóÖ¹k£
áñdiÿ3±c""ÉV£\I¢ÎÃQ„]”ÿØ_yVÿµ¹‡U$ŠY´Ø!ƒÍeËFãªÄ¿ı—øÛXÅ’èI¶Yô8D¬úÄ€‡AOĞ£8èAMÈÊ.“ä}•›'*4îÄ$"zEDKQ=ÇÜ{ÓÕÄ:Ò“ñ [’	L‰œ¸ôx“ĞšOLö¸Vôƒ‰Á7mS7P(¡'½6&QüÓ‘2F|~Âèh‰¦º^5†´WTHx€ûjÁˆD<(šRXô´«¥æÊóUÜëÜî?÷ŸûÏıçşsÿ¹ÿÜî?÷ŸûÏ?ØçÿŒí—u h 