#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="473771079"
MD5="a041fccf1adfcd93d69ca4dfef279865"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21375"
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
	echo Date of packaging: Wed Nov 27 20:50:02 -03 2019
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
‹ ªß]ì<ÛvÛ8’y¿M©OâtS”|K·=ìYE–ulK+ÉIz’J„dÆÉ!HÙn÷_öìÃ|À|B~l« ^@Š²twfv6z°D P(êĞuıÑşiÀçÙÎ~7Ÿí4äïäó¨¹µ³ûl·±³»³ù¨Ñllní>";¾À'b¡òÈ2]÷ú¸ûúÿ~êºc..ÇÓ5ç4ø§ìÿöÖöNaÿ7w7·‘Æ×ıÿÃ?Õoô‰íê“+UíşT•ê™k/iÀlË´(™Q‹¦Càç‰zä(ğóÈ“–³0±…JµíE£{d8µ©;¥¤í-üº”ê+Dä¹{¤Qßªo)Õ±Gš½¹£o6š?BeÓÀöC„S¢ÊÒ®›ßBâÍH½S/ øû¸uò¦ç@u2:0˜ä20}ŸdæDÅ1\‡4ÛQrêì\ı"œTè•ïíçgGF#yl††Z{ª&¸˜ñÉÑ`Ü=ZÇÇÆ
É‚æ"x»7èjÚ~6ìŒû/;o:íl®Îé¨3zãÎ›î(knÃ,ãç­áCE¹JQ ÔhX©Q Şè4ô‚ë"ßa›ªØ3ò–h°oµşë½V\‹JŞïãÎ¹J¥œ|ó;Œ®¨5ÖuÜä¿ÍÙÉ§·D™ÙÊz×rƒKWH5soÍÔ[,<Wcç”o‚bì¾aèN`[”)Ğ4¢ÿĞv({²qC”JÂ+=\øzº>õÜğ
YE‚Åz}XÕ-LØ>§Ók°ï!ö,²<² ‹	lÂÎºlí@R™š!Ñi8ÕçùäodP_‹l?İ¢Kİ'¦ºögòAÉnÂb*«b×T*‚:>÷¡cÎŸÖ¥—ı0 gĞÌoª 
?m×2j›°ÃÓsduCMhQk	ˆZNQ9Aé4Í¬ë\í¿t=E«ß’*€/€Å$ô,xÈˆ;€³á7X=¡¼éÊ2¾ó‚¨ù4E™Óğ9¨Sûä€/[)àÒÌ4¡²ª†µô7Ñ®Ôt¶AäæuˆâÛõÄ¢33rÂ@ZÙóNÍ&>µD)kOS¥’u¾öçµ³ö=Çmxi‡bFx¾°C>§A¯è”PwIºÃşqë£ÿ oZg£½AwmÙoòùô	®’ZÎ²ÙË…É(c@8"Ø]B¯ìÔëuu? ¦•røuâ*"wŠNA‹ëÇó•ÆRŠ:ÂEr’*•L1ÈÔ¤@¬ÄM±ln
+é¶òÆ˜Ø…i»)¥
>q²ºõ|àyaÁ}*•LcUcÎ÷IÔ©‰2ç!òüVùc“Ù)'\‘•Šlaœ|XßŠš´±äÑ×Ïúø¼ph»s2„88¤V=¼
ÿ€øw{{mş·¹ù¬ÿo={Öøÿ‰ÏïmRÄhÎ&í)•&éùàùx€6çš¬üŠRy$ùĞï¹aÃØÅt-_É§–b@ä[£üë“¼ú«b~1ı¯£„ã?û÷äÿÍMHöóú¿İl~ÕÿÏü¿Z%£İ!9ìw|CÔÖ;iº±ıBÚ½ÓÃîÑÙ s@&×ù(	FzY˜×ÜÆ@àE¼(„0ÇæQXpı=™À³éB&	±O@eÏlÈI ˜a|Ü„Çca=_XÍï}3`"ª“•bAxä×ƒÈUªò8Â'š&F[Ô±6†…Œ&“;×…yAufÄæÏÈ,ğ`@Ğ5ƒè˜ÎöÈyúlO×“auÛÓ¿LQAÉêrVóN{§A>CÄÊ‘åW¾é2Ñ›	¯¢Ìì€ÁæL§Ït(p¦NŞi‡a?ğŞôyESòV?ì¾Zå/iÿyÉá_¬şßlî~­ÿÉıŸbáU›D¶cÑ ÎÎ¿`ü›½½âÿ·_ıÿ×úÿgÖÿ›úæÖºúQĞx¦šú¢ßvp ÿÈœº4àa	 D±]ğ‹xTĞœ,Ÿ´Zƒö‹İm´\+ğlë9v¥jÑNCbÜÿãË#3§q¦e×#ı6Áz£‰e¹åÇÿlsiS^¬4^
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
®nôëêZü‡¨%Ì©a|¶òOµP>›1L¸õ_zıo{_÷ÕF’ìy_©¿"]Ò4àµ$$ğÇ€ål°›iİ3ÓôÑ)¤W[Réª$0íöş/ûtÏ>ìË³w»ÿ±Ì¬Ìª,IĞØÓ³+c#UågddfddÄ/&çêï¡á«¹“"Ã6Ë+ã ê‰Jİ~Uğ§¤RõcÔlƒŒóëÿéŸĞ¯æ]`^[ë3bJ­_Ñ7w°İ@É„#€wxÙ’~ıŸâ*ø)
è%%ÇZ.gË=*İ¨1Ñ…1È_}£UúMy
°¦tˆD×Ñø *û©Q7JÅz[y=†Iw|øWÔ	KHR/Üq€³
8<>™+ÿe4VBc¥rÙ‹ÏaÍ@‹™*¼àöÊÆœï‹Uâ{ùëÃÖÉ&ÕÂÜ®b0ííŠá+Vá`ÀXøµq0S­ëöÉ•3¥Êö´¬®nT*“:ßXT™‘Öêº=Kà©ÌL*çF	İ-ÍwŞ’îÆríì{¬úì‡Zw9—hVNlˆ3§¶œ…·›‡Òhõ›AÀ¦Î†²Uµ©Ğ(–„rFÕdA=êÓQh«úïñ FöÆU‹ÌB'#•q½º^­Ë}6pãÄhMz²%R1’åH3™!E*/ƒÊè"ŸÈ’ÓÂŒæá¢‹#¹û³a§=î‘|H×ˆÏ„µv‹N¿Ë_z	şíuGŒX‚?x˜%ñ÷UÒ‰«ãîïFé¯ÉP~Çãe#tğ+¬Üx«ßm°Ş…nøé¿j0Hø¾ŸÿÿqÊß¨ÅéÀ	tœùY%?ò#´—ßĞ¥Íøš¦ÑÅÁÔJÆÆW¤sÕÃ÷\Â¨#[Æ	.‡=˜0—Õá˜ )‡ü1
ÎÛW$ ï¡êö;ì£ú;Ä²èØ?sLâLA8,ïÃñUVÚ<Ùˆˆ2ğõküşİ.}•ŸBYàYùíGBè›z9ë/²øa/Äz+×õz¿»áşNº“¾üF\Â_†¿!à°Îİã¡ü£Š½	:ØÅQŸ˜9e”àì¾J¿É¤ã¡A1 )níÄZH^ä'ã«Ì’ş:<º=""¹1ZÏâñÜÔKEÜ¦Ÿ™0l“f¤QŒ>ô©|EN³ô`KĞJ“‘•Ä ¾,y^jŸÁŒZş]Öqõ/¶!Èæ5M$(ë¬œËµ†gêlpf›#à]Tº(ÕDTÁîÔîTß%É*ÕúÔø…»#/â?[ëeùK·©`îQ˜^¨i92­OY“^‰>÷ºJšÀKô˜!Ò:ÕÑìË=Df€ ‡]s{ÖÇé‚ä°í“êæ9RöºvJØíy|7Ÿ‘àxnIfÚìs·b¶v#Uò›¤â*s¤Ñ©²qİõäTŠD2Æ-nı=½Ü†ÅjÍJ^_K›R•Šh£ÜyTà9õ¹;¿EL´o²¹½–uÒÔí’¢™B†by‰/Ïç…0~ù£#5n8– ÈÉ»bŞôrÂúíx8Nš>H~zêƒkZAe™Í”.åAît`"rÊke8øK "aıŸ}Ua˜H6_M ;b` 44!b$¿-ù|÷ğ¾×æe¢9íX!açS—¥öÜùâ3>øF%K–~÷4…Bûèv<Š.åÉÇÒÒnr>tÙÚËßê†‘YLÁãéKÏÜéå‚ô»+¿ˆHsÙœß[Æà»À:ãì¤M¼›o¥//²0ú2¿qÍ‘²÷÷«97Ò;`?&O6Â]ÌíFË(,a¦È`eÆ\27İ{†Ü4\`o)<AqbZáÉá‚4¹¹ÄÔ*vZ1K¼I4:šâu¦V¾ÖîÉÉŞÁ›VqJÏË¹XßÅ/h/Œ?ñ—ÇjœwæñL+R‚ÊiCá`ìÊî-åS­Ğ>[Î¾?”îı¤vV+ç¡bjµK<ÿ–zI>ë–»DrÜß‚öŞÊíÈíuäp:ÊûÙ.G–Ç‘r8šîot?îFYo#ø=‘ç}ƒ:Ÿjşò,ß »åd¡;æ•¾BŞgòÒnG™4lRÍ‘rÁ~ãHA[¦Õ´N;Û3»ÓÿzàYbé×UÓ$åÖ®bwós¸ˆİ»‡Øüb4703%Ğ›Ò¼¼i—\Í²½Úı”‰vFxtr)nçËRÊêèuç­ƒä¥»÷cºbå·ö`FévÛ?æwÊO¦ÆF8Ô8wÍYO.LñéÏıêÖV3ÙQƒÆğy;ê£&/ŒD~†Œä€á0â^V"9éÚz(Í±Êx9	šæÔ^\Å%¬6ÁZñÍV\m˜Üçµkn¼~L^òÍ€h»ß6§ à-•lŸ=•g“T¢¦Q‰­Ï­ÒEîïàóãíã¿¥«­k³œ¾ÅjJÕª×Õ—›ËF½‚¿R~¸ºœyAQŒ|	 EÅ,[k{b XN²8O8$˜YlÇÃ|¾”~Ëú¸.-óK¦ú–b(Q7æK
÷£NHÇŒH¶wH”ıUõ{ÉEL¡-úµµ¥*¢’xİ™Uš¤´»4ú†ø ²#ƒ¾”UÂèËŸø´ì´*˜…r³f™iò\œ´1&¼f}\ÎVVYë‡ƒ+Kl_~ş'´8V>j~½ºæÃ	 wa‘iú§'¯+Ïü?½ ^>ç‰È?–ï®¢Q<@üC?Ièì¿Ï÷¹¶¯-ÆÏüÚ»¸Öæ¦&Ó”ú×ü
	_ø²,©B$ò‚~¨Ë*Z³ÒÌÏk6Ò«ç5ÙÓÒ-K#¹4:M¼Â´à˜fÕóÆÅóÙÛLƒïjYÊçÖÏz¨Û$Ã×eÕòŠò,láu]û„±?ã²OPº«ø‹ÎÚôLìàYyÆåÛp´ê/­
*g©TŸ^€e¦à«š!_£0_Æ%Í_èÖ‹(Ø4¨	i·m?ÖÇÂJÙw…S4ˆq§
¹\ÈôgØNº]<c^_6à83hœê¦8©Ï¡s 8“gÎÄ”$Ü¬i· ˆÒ"÷—üš`[§bçNşxv+Aô7“œ˜ôsQ¾ñ; üúg¡<Š²UgÈÙ/ÿ¯¾ŞØ¨çâ5ñ?øo³ğß®Rü·µjİÆs ¿Ya¾£1Îb»={l Â28FÌ6
ug¾^È!¼tx>¨—¥$«ù2o^éÍşáËí}ñíöñ:µ·¸ÚWq/¡Ë§ŠRıíîñÎn³¼|~_ßZoô—uÈğ·ÛÇ»û‡üjŞ­§ïZ§/a#şz{_oèÇ»o÷Nd–zš\ÉêjïÚV™”lÃJ¸ı÷Ó}]ÀFúœ‘fe3áñöÑI{ÿğÕ7-üÚUÀ–İáûKÜğz-}Q¿˜ŒûU'è¼é%A€5“|V]`åb„?ƒ®ï­zÉ;.ØS,´n;èEpfJ<ú+8*us¹vz ƒ‰
œœJ.ñ] äÌ©¢e>’¶É±ƒ×÷ävGa…ÃÎ#¼vîŠ>Fz„xƒÂË O§>âÕÄ6e·là­…ãÑ3[Gv`íl+õ3_tã01üÁøâ«ç¸·Cı¥­§\!ÍÁÃ‹á#V¡â!â
˜×å:v›T™è&Lvg¥ÙDe‰¼ÑÓx2À¾.Õ/âÉ +â‘¨|D?½\;<¹a£àqsùàğ`wÙA3›d~¹‘C×ƒG»ÁìE‚f¥9!c9òíH:€¸:È±.ØCmĞK²¯¤¯¥xâôó
÷}$x)]&‚I	tU¿‰’‰0ä ÕïÑŒ¡D¼eÓ–0XM›+å•J(?—q€Ê:á*ğº|Å’è6ÜB…Ò7x‚²GseÕÅ€_}•!¢LEe1ïéÖRÄv-H=Uaz`^2¡u¥åğµV;«ÕÄ§Uê^¦ÀÓ>	^Àf‰#×,•X>”zØc)m~T~Ú®ü}­òÇ­Vm$- ?äÂ´0—áô†0'}ÄàÑÌ¶*í€j]qûiPµ“"°¶1wÂ¡aŞ™d±EV6­£ı½““İööññöß°T92”*œìâ`ŞvCÉêb[²3UÒ:Iëh–s@‡>6‡ÍáYo:3™´i’®Ğ‡`4
nI'r/V)t ÑB§äÎÏè”A›rú»‘–d6Hœ‘:½Ê(e&µ™×2#táŸ R½&¥¯¢(†&	.úç7èéRäL(•&¥À@[º6¥˜[ëéèI·'¬«Y®oéßzÃŒJŸòÆ„ó¾Y^×OeÏ€¦rĞ„µ|¸TRÇÁJè—²RbYS â)°e¥Œyåa¦Ù`„Ì$j­×a£\ñG&]İã4Ùı¦bGˆ˜ô“,ˆqï¹'9Úw Ş0èÃ
	Û	ºyÉß46€ÏNÎWrP½TdÀÂãØ4L˜)YZæ$ù¹^êlÍ,¿1­K$¿rù‘È`ø§@98÷å²‚¾öª&eìØMÓ2årÙ–ó@ZSö{éüÙàNİwe›M€_z"[Æ…”
Y+Ô¥ª>ÜƒH2RÙLA	³®Ş-ÓëØß62ÚIhZX¤Ÿ9rJº¯©¥6+ŠªD.‰ÔºU6¯£ï‹FïFƒ[òÛo&‚¦ôV'SLËxßÒûß•·-µèvÎµ­’S ÖqpØ}Äıh•¤%46Ç±g‰¨?aGA`ÍX)yOg“q õÃ^Ìh–™Œ¬"OV×ˆñÉ~ı]
­2šÈÁ#›3Ğç(º‚!¿“³Á.·`~W«Ud¡_5€\ø?™hêJ}GLÁLhçNÆİë´£³à
~ÙQÏÂ#–ÃT°Ÿ‡İ„D]õÂW×T™³wD¥âş¾¾†X	øV”u¨Ğ+
UåJZÁF¶sˆ‘vĞ4n	 †ìàÏ#nˆ“Ñ@”ŒÑßqn¥åü[ƒï&}A‘æ#”5£L‚ ìp:±utâN˜$qòHĞÒ<Š nIpö‰=€³~ı8GÏ#´¢ÁèC…aÆÃUêå$¹É¬Sk¹H“N-ËäO‚tuí-±[1>ø~íõ¾ŸĞQøú²Î""`Ni`3%?ÑxşU]”ÂÁ¿OPIÛdAub¡t&C¢J{¦-b±GP‘pÛwA4¦ø	å:{(,-a«ê[6T(¢è&
SkÏ0èÀÎR÷(î‹ &!¬şc4Tc(™s¥rÌ	¯ãëÊdL°EctE»«ÙÄm˜:¡r}¨ô#Œåt©m¸
Æ)­v| Ò(Lô@%Ù‰c*¶½üQk´p¼%xXÁÉÀ.éoåäQ~ˆ#&ËYäòú'^\×Ì=3·ñ{Î.9Åıû™xºIä ’ş„Q‰ùÑ§Eğ /ÿGòÄıÇ~Ÿ#şÏã§lüŸõÇ§‹ûŸEü÷;ÇìŠÿã›\>g ŸW*Ö»Ê]¤şt`9†ùÉŠì^B4P†}İœCç“HV²#·['Ø"ƒæuÃ6š	5İ˜Æ©ßjšî¥GG¶Jñ=Ï:yäê²ï*2~8â°×Ò¬I(1‚<k\eUF
*&szSĞĞèCÊğĞ=„I¾Y'zä:Wşè(N‚Êe;›–c_}0“pL•ÄR„’ìşÚÊ¸lW`‘Mì²4İÒªrş¶f}Ô~‡Gn®”,HX®Š˜Ê¢YBÓ¿GüÒ0áÿf2[×`ÁXÌ‘C¥P¥Ë©n*/!=tÅÄµ¯„4ÅÂçZ¡Ğ5ûšjHiöì.ÒŸ‘,‹c“ÙdÙüæ®zûàdf½˜fz¥2E^ç¢ ˆ†­q0$,a“÷pº°İv¼MSe…ÔÿŸœ¶èfNë“I	#ÒYhüzúêà°ıætg¼|£Ô×[ê¤iÃ2¬@9ğUò”ÉÁ¨üğèCj¾_ÿã×ÿ³4‰ÏG¨A=b/u«ãÃKÃ“ªx(’VsE”WğV[TàP_«æj//S8æÖŸÕ Y8Í1ÒeNèˆVAĞª)U™ìË@Ÿ‚‘>uµŒä«P`¤6kÚŠ*b&`J"dÄÚ7õ[iã–¬hª0V,E\Ë¼â	¨oj3@2êŠ–ã¿zvŞï’Zêƒ­‰Æ™.îæ¹šé’6ÿŞŞ?Ù=>Ø>ÙûvWÇEÓ«3ş¦"ó²ÈÁë9Œİ#êlÀµfa•ïİ[C´/ìš¡M†X²)U8ê€Öw,m%—/£˜äh„ãä]|MŒ¥¨¡¿õêZuÍ&†˜Aƒİİöé®n»¸35ëiğèƒØ	Ï£ ú¾V;†ƒ¿ì|#dg÷^>}f’`J«…‚Û}VÿÓá¤ıv3}»ìÏ¬ºKé¿F°_n¡›UsŸ)ë¦„[v‰IB›=§¨×è¨Í@¯l6Tp³¬ìŸ´Øõ”MvNrWCCÆROªhm“Ş&~dy¹·}Ğ~	€`z-4)õ3kgÕ.Ê‘•sXO±üĞ¾«6uYÛG'ÔN55&÷o‘Ó‡iR7<¯v‰×¼Í_Û]|‡W£PÃ»´¬öC z2ˆxñE´^{ì=õ}Oú9ûkc\'|ùØft!’ ]ŠXõë±›kàÌ6˜ÃäP¹Z˜Üìkˆ×»£o÷ÆIVî"Î¨RNF—¡¬<„MEÌNX¯?¤İGNè$ÿåx÷™ =ûE0é=|¤x$;üäQBªÆïÚ8JxíÍËÿ¾¹DŒÂU­…$3¦“›+)*6ì•º4BåVÙ@í:‚.MQf©JšÕ\GhOCæ0>TêK£-­]G¤ ~²ÄÔ’Z¨u°5Ë&?´ÆñpˆËŒ4Úâ{
iï”vÒJ+^tş²ıí6ûtùå4™®] Af(€ÛÎ%0ö¨Ô¦&–u)†MÕ–!5&5Z§¬$–n8L<ùc'Ä»CT3$™˜SËjÜ6—kğ?Nk<—ÑfÖJñ—é\½¿ıİÛ)SfÕ9Ù`ŠŠ5ÃìPåC¡Y…,Seš™œ@©Õ‰ì9“p+E
G$}aìüÿË²?t%ÉœgûïèQc
y[ò’”n›x§HS©ó‡<êf”æÎ’Qœ[æy
uA·lUàáÃùşñDŒ2ÉjåhË¨ÙÙcíí~/¤f°üš´ôJš^2ËhvwöĞ9[_H ¤YnAI6»Ê%Ë%ïx.6ê(ïï½l©ó¡ö¾aÿãTrÄ$À…· .°œªQvÂnŒ¨ÿıp<Šòª;âŸ f.ĞÖ­ëkËì­‚Á?Ú­kßåËé´µÛ&°a6ĞTŞ–¤2è7)V2Te³œï75`qc³Ì1|Õ*š)öl`—Æ¨º-QÔ-ÌŒ>"6ìï½Ú=hí¶€zÇÛowAğÆ#X¥Ò‹:á ¡Us·)
¡¬šøKıhç¤õ«64æ°Ö·ÛÛovÛ¯Şî3¾ M8Mhúñs±E}¹¯’0ÙŞÔ¢’§V8±î÷2Û´V¦àw[	—–MÚ-§¾l’ñ)ó{3EÑ¶_'÷,Z¾	Ç¦‚u0Ú‰']nMÌ%ÍAÉk€Šp%Dtù®?h Q†f¶iµ*8?”û—•ãİıİíÖn­Jğôh!ÔJl¼F[SwÅæåÜ“Y‚Eíg)¥¨ÓÑÑAĞ‚tvwÓDÄ TÕŠÊ¬3¥Ÿ¥Ÿo—èO£ãÔRïå®Ù†’¢ø£„*zãK›Ëş;~áö[J(3>­÷ã.‚»@©^d©Ân³<5=?èÚÚz¥¦(6^]ÓT>š9Uy&‚[a2[Ç ‘|S —!ø"ˆzE0+¿ñHŒ¡ÉÄ)eêPÌ3¥ò™Ü“/ò¾ÌƒŞìğMßk80D‘¼V1±ŒóÂe„màEsÅïô@zôUÙô`˜&K–Y”§*AV½ôbÍÈ:¦…gÜ,Ì
&ƒ°ı–œ3V?Gã‹‘˜3ZóÜ©©}fœÕ¾‚Ø8˜ŞÒhgé8_Í!Nz=–±°üòGıŞ0«ÉrŞülÏûñ\l1ıŒQbÈ‰§OŸŠÊñUÌ°Y´pN£Y™”ç¶“TÅ³ônºM«ä‰õ>¶˜öÛƒñÉ(º´¯Ï3×?Ùãım•DÆt4J%Ü4ÄbgpƒûWÅ	]/ªÛ2aÔMÖÔJ«s×Z-¬ÖªU/£/>R[Æ´Ù©§ÒØÜl’°/ä¥	C	ƒ FÃËd‚-ƒ’™—
SV_˜¨ ¾Tg^Î¾İ~³‡2ÉöQ{ï`g÷¯Í5QhrğH*b¼»ƒã•ad\Ã»ã_ÿ1Šb´Ú!ƒt35Áa€ı‚!Ú–ŒâŞ+!ğ<ÉÊlÀÉö±ÑsU×ÉÙ	d¿W²¹˜],ıÌú)¬·¶ g½2„M»æ–ŒeÈ¤˜¡mÑ¢Ô"T6Ÿ‹*„†7¦[ĞnÔ{pĞ?öèrôb¾À9:&Ãñª¦¡lÒß÷¤ÜkÓ'ƒŸ¢¡•XÃ$bæ}†®ÜLÊƒoæãèŒ¦ØÁ­vÜu;ÀØ<—İBlÌkÛ@Í5â¬ÛwS…êJµP›ëAŠÓ›Ûã‰Ò÷æ=nnÀ89¤!ô˜ckaÎ,¹2?MG“Á`¹RáÕ;ÅÅ4;{0 ¥°: w0YN¶ûFùj¡VWDkïÍŞÁ	¬^¬¤Åu#øÄxWSäÑ›'$¹"Ûœàê*L_‘1«¢±1K§Ìày6³V Õ¼Ò¨lpì1\på5éP ôœ}úzİ5WÕÇ¾+‘V‹a8ßn¯zÇ—½°
”B ­'Æ	éİğ®Ò–å1:aÆÓY2¿ég şË‘Æ ‚ÉTŒtú(^¹sã·¡ÙÒê°+éã”7­.Èõ%û,IŒ¥Ivp¯Üùıù<Bé•Ò¥áà½¥8úş,ª°İg»Aï¦(ÄŠï©o_R‘ºá^„9ÛĞoŠ0‹éÍ•õB”ô¯ƒhüHŸÆğªëÌ—İ*(.B iSWäÁXHªâ2É]:C@6íƒ°°°`ôn‚e	Ó:-'ß¥æô–Ğ1Rw+c´R7aø¾İ®}Ó{ü{ìkÆÕæóa¯›.ï†ZÚŞ–oãwŠĞ-ã
˜sÜæl¼F¹ïÍî‰_˜b$ù÷x—_Öô‹—§{ûa¶°àğ,œI—xù§µİ´1NHÎ‰OpøÎ\j7è7Òı`VVZ1+q0zÛ|A“zŞÁğ}›_Ğiµ¤˜øvïÀ$XÚubõ %ÉÍ\ŞõbcÛ#
çÂz^Äd:Nì2@óÒ´¶pRäFóH9ïÛpºÇr[Ş0€.ºG~œV-«ÚVy©ÄXùøm©—d¤åÎiC„ŒÎ«§¹<ÑLÉŠºÍ7ˆ˜ `UôIÉÃ~ftãV™DıÈĞ~AÌìÜô|“¤.º§-Q¿›&NkãİRk)U‹©ş{-©‹{a)rÃa`ÍÈLù–Ôz¼¸êõÔ7Ë¤1×}Æ-Æõ‚ñK•=©¶ÓKM÷¤ØîG{Ë-´áº÷+ë­°‹ç²½òX‘&M˜'á,c*/Ê’1ÀÈõ0'ñÈ­“ŞköoBŒYõ)3­¸(²D¯gÙB2fıtVÌ¦±‚Ze÷Âßow``®ÆÕçfúUT»93_A¨4S–g¶»İ.Mæq,TÌG<1ê€‰ˆ×A—YÖÁqnõ„uÄ0ï¢²ƒCVúr™æSlşvÛ#zE
4Â³ê"¿ƒã¸¬ûµ-¯ÃJß>¬Šä×(ç{¢·0êRÆÏ.ÈSYÉÍsPó¤ŸYÚV_Pbq ¢Î;ü½*J&@!/`ù²â«°§TTØ*#†©‚›ÏÒ2EVå‹ÊX–t´àåÕTĞÒ€Í
`~É¥ dÔÑŒİ£bÁ¬©ÑÒ|¦FF7Ø¤ê5º0ást]¤¡)ìø7Ds$)*‚¹÷„ a.èE?’ÅT½¥\ ¦bLkÇã]ÊØİË…×,öGbÃëbc`ˆ€ Àrğ@èïKà-!”q” £/JW³OHhşVP­R÷¶‚S9fFùOFDzûù+ªt ßÔ†Õ
>"3H™@d£t~ıG¾·ğÇˆlHÜŞÆ0§fÏYT„ÒÁ¤¸~‚E Ïğdì†@ÊkrºÇ–ÄĞ…¤h¯·×Úk®´«sæ%hNÚ–„BÑíÚ²‘iË-³¡Î§ºv£ú©xŞaÎ¨vZ¶"±ş¨pö¬²ã;[;°°\èôëk1¿"Ñş•3ñpùÙée7:‹“ı!µ$‘¡ï'E`vVç‹Ol+g$	!Ê-É™^O9ßŞ™Ğ´’Â¤;‰-4Nü-¡ætÆ ¥€ºLA;Ô‘&»“à¿âĞ¤KK/Q¼¦ÛÊ äy·ªH{—½²û(
£ld·w^ãÓnxåÃEãGq?¾”†¬©µïáõ ˆ®¬|KóÈl–QÓC»ÑE»³I;–İ’L‰¥®ú­Å.#­\•»1á¤fÖğB'îŒ>? ¿÷ÿ¼$ˆÒ‡%>ÙX]ú=È‚¡Û™¶bz38÷—%³ÂVÁnÁÊKb÷+]YæTj–øÎKQsSr÷¬`Cb«¤Û¬í…[Û},Ö›ó´õ»4s—…R:xKI½©"_aÍ°êMuª/ÌîIÑÀ¶LM‹[ÍÔèd÷°ã|İÃÃ'{`ÜoiæZ’»|M¿¤—‚øòcÓdqô£Nê87{ô,²¼îäÜ?¯¹ƒôNÍúô¯ù³MO\vS1>6 2S´\ O¦®§stF˜Må2Şíï½Ú;io¿:2Úowvá^
`Û3®å–š«üœ¬pQÇ+qSÉ8¼©›Ú5®M#¡(Åç!¬ÄŒÄtG¸>ÇˆÎBê0#«™a)’#‡DväîµVÊÓ­D‹Ãm»×nH6õGè£Á’‘—İs;ÕÑ_6"‘,³zv€º»RŸ°çJ K»(J@"(#E»S°4zGy‹‹07'÷–åXˆ³f×PTÑÊ;caŞîb;1ô@2¤ªtÊF–ÙÆ¼‚]Ë¹Aæ¶iæué$9Š“ñ+–0·‹¸öOwÄ«LêÓzág‰ÿóôñãü7ü¾‘‹ÿS¯/ğßøo·Å+Š÷Óq¢¸1»5Š›ÜR¼Îª‚ÍÅ¦2S»¾¾®^EWAÌöd½z>ªuá,QkaØŸ
×V!øJYv<¨@{ãŠŒ¾*#Ÿ©+­´=+«B«:D°¯b~ÂÚwøöèx÷hÿoÉ^¢Š
¶¿;<Şi}O__áw’”1gaŠ
C{H@à
Ğgˆ¾ë†ıM¥hŞ+ÿV‚`¡¨4E ±ÂpÖ%ÿÑe¤íUEtYæ#´õ“h6Eå¡øÁ°#5:„qZ€— ëT¾ÃYl*™¡‰4ØŠë 	ŠÊkQDRa>Ÿ?GåV9ªµÛ×ÂyT=SÖ*à]sr”|aüÏFıéÆ“şçã'‹õ±şßÿsİ…ÿyò.Ä ¬)§Ï‰êÜI¬ã
¥\Î’/ò-Õ	Íqå$©âÁ =¤*¤Ãåu€®§ŠşFÓ{Ş\GÄE4JÆ„%­n`q<8<Ù{^ê;äWk4ñ8º¸© Rúª§ÕM“UÔ^#%€!yx…úd:Kş÷Tá¯zZR–êhÃ>‚]zJÇÛ{;‡bûíË½İƒ“],Oâ¸GVÏ<ç™~„d÷™FVE·ûëÎ›öÎöÉ6ú´šFøŞM#/?È™…/}Ï©ğiŠd^~·»ÿ
iáó`˜9¦ß'›³›'JşÙøl|_‡#òPİ	QØ‡=˜éÑ(@§äŸJé­zÜVu´¨î³ñC	»öGJ†N	*JÔŸT×6ÄşI+÷âYöß	¿v‡—Î§T:4A‘\„½>>&9Øiú—DXU¯¥û?ŞHzš¢ÖSyYg<u€^5×Ì,:˜ı<å¿ıUw8Ïìç9\¿å‹agÙLáBß£T aı´¬i‘G.‚Ö‚ ÷±äl}srxóòC÷…²Q1äãUŠÅxxtb´Î‚6ñÉ<}«IP\ôÇ :§IĞ“õzã™ç€N1‹Û´ 0¼p‹&³.¥“İÕÖ 6ñcw’ÊÆúúúÓ?>a·¥ñI}¦Ğıeí\¿ÉxT5Gõgçf®ÛµEÙuNÇ(÷“lÜ‡gOÚO6rm#ß˜»fÖ>QÓŠ ¡Üé	ô¤Z¯Ö}/ã¦3•¦-“˜g¾fÕ¼1{x&ó2o˜…T×p”IİVÙÍåÆSL¶Ì=™ç²ê¢î ;«ÓÊ¢%PÛ˜nM³ÙÃşÔ4?İšf˜¹9~KÛè'Û¬ªÚ·2æövEæìS»Ù ~N÷H˜Ş¹Ê¬ÎQ*<u*N?Hµ#ÛO«ˆé/³~	²~v¦ÒDH×†ËhünrNÃı!†	¦"+2Qî·¸âP^pªšğí™Ëˆ¦¨`§kïíìªTS áÑc/)AÆ‡ï+‰TÅâÍÇeávÓ‚ıÉ*ÑhåNxErÚÑ(ş1ìŒÑm¤¤‹EÑÂÉ0è„f`ÓT ƒV‹ó}y»{pÚŞ;Ù}k¥wËYµ`ˆwUdœEUA¤}?aı’C«—°jVû¹¼|l.óëeÏp¨¶(IZ|XnùaáEŸn]YK{j=Ô5ñ»eÏğ5OùK†A®CŒŒŒ0¤5ÄE—~<)ÂA'Ljü&Ñ¸‚†ÔÙ*>U eÎÕÕ?ùék[Çm³æ1«Ma”˜ÜŒTebúŞñîö>•*×~³ê(zº0éMJ­)²,M©Qt>a¦˜1bÔSÚé2^ä ‡Î›<9¬>2±œ“n°Ÿ=É¾nú*¬€ŸŞ†Û9kµ³j­ıI”xıÂ{.D%—8“ãÃ=-W—é"¬ıHÄçğó~ŸcdSàˆ7Æ¨W!K0©çÆö1¨z5¨^ŒÂp@ÕdSkãà2©e›#2àrx«‹KKz¾EòLiÓ”F5ÈÛĞ~§hÜF–Öƒ†ù Ş~†)V%é‘Äq0©$üB%Ô«Ïª”sÉólÛ
„©•Ç‡­V{ûø­>.˜ÒÇ2…Zb‹j¼ˆ§/êV^¼::UòZXjiJ9‘Ô_éÒQãøí×¯}ŒV0×Gı«§/Ôéñèx÷õŞ_›x]^õJFÓ0½³qs·´æj_A{€î¼gD³J…wlØ§šè/ÕíV†|m<“FIêíóQÔ½„•s|1”øI‹ªö†ï	 1™á¦Â7»†Ëuíß¨H—l‡°¦½­ù÷Õdù3MÅîÔàÏÙ^î"]e¨úõ»jãE§§YÀøŞ¾b‚àX:Ş}³ûWñíöñ®-Ïûî¸m‰>>±Ôağ¨(&7Æ2§5Q…XÏGÇ½ÇÀ}…­%:ÿP¯WºáÈ{ç—ã÷°Xé_pğFÎ'ÆÃNâ†úsä2®§o?Œ“±úŒßo.ßu*ª&Ü7.{“ñzúû^
CÛôûá`‚m"™œ_±Yôƒ÷¡àá‰= Í0Œ‚‘PG–Üƒî¹¸„­jà`«x–‘’`8w¡¡wÉëÙ‡§B*9lø÷šLŸƒìÅĞ‡ÒDƒ¬!ñ ‚ıõeaôì¸§a‘şşû<¯Ğ†Émé¢õ/®à*™—n£Ÿ“=`±ï¶÷àdï¹àQŠb9¬¥JØíT[ó²]Ò}o@Ó‡sçêõAşíKe„ï08*Õ?Ö†£Y±úS-	ÊÄªa¡låZ§GÈâë]hæqë^´Å²ì»u‘÷J»›³ºhJM3öìå/¸i+éE²2ş¿Yv’F·¿Ğ¤1åæÔ(=¯ÕµMgŠ­ˆ¸}>
p^u?ú +ş:J}¹ÂÜJ_~W 'æ—p¸}UüÖ0¶o:#KÉ³¬²âÏ@VùM?ßöl°ågËÙWû°òÕëÖêÁ»_8ä¶ÕÔ®ÚËÍI6µqş£“ìcÚôLÅºÂ§œzˆÈ‚ì†&¬Â1ğ:+ôÙ‚ğØkÒHë5º9€¿A¿ûdşÂªn¼-:3‘÷nĞmŒM³Q©·)?.Ã E,ÿSZƒ6âÜšFÚše\İ+ÿŒH(d_HÛQÖ¾ÀœçKnãàÃ&_áØfgãşeŸ¥wWß„-˜üz×ÓÅçÎî§ïãaæWf>Å¨Íúí¦ºBJØõ¦ULı(d|ºVC·ì®2ìŒÂä—ÿRµäûÄÍ6Mf
kÌÕq<hH4Æ”×y¿üçìêó›¢úNbñã$kÓ^ªöBYdŠÂ	Ãût„l€tJÌ
®‚¨‡÷ä˜D°ÕÙ­!Ó é”†Öğ†ƒ×ğÔ¨9ËgÓ£¢ZÉJÉhHPá(ÑŠ«P\3Q§u:¡Ó1=7Wf·§Ñ6la*L‡Aã³,>3	ÈÈXò\ÙÌÌ•l[DnæÏm¼¥§ã×‡­#µ4êÒ¯Nß¾Ü=ÎNÖ$@Û&˜š¹–Ìa7{ÅZµş¤ZW•á]£ìØàlöå cºnîú/ÿ%^ŞhĞdo9^ì vPT|>IÈŠd¨£S<‘4*‰¡ñ9àé˜q;b„ô8W(<İŠÚ¿ü§Ø»ÀTŠ¾‡N˜7fvš„h·•šÓŒ»UÏ`{œiÿkù|Yûßúúã§yûßõ…ı×Âşk†ı×ÀV¿››ö'†Çü™LŒÉªè‹Øûò–¼y…Sôé>]Gã±hmÚË…ïş]~ò<–[n¹+›eKêÏ“aÓãA%Aj‘yòX¡¼çmCsï¤vñRwŞ¼t€eõŸ¬Ğ+µ­£şa+Åµ{‰šÁ—bdÒŸ¢aÓ•ş9eG9ûDyûs‘ıà2ê´˜TĞ¢´&ôSÒ.-•êô$sçIæsÆs¢´NO­–CÚ,Ş<{LÏ¤™	ü~¢kËxú”P±tÚ\ï(fm¥núqJßi8µ»!Ú<wÑê<íù÷ÙBlà&¿lfuDÄ¦7ÀÕjUØi¥¯¨Œ®ì7¶(YD6Š‰Ü´^ÇÀO©éé%İéG—Is¥Œ1÷lÔ<|‘C°*9,8AL¢´ÄfÅòTqrÕ{óêå;|v_ä§‚İšØ”»@	yFÅ›{/ãÙDİL™ó}Ø&€t8¿Si1Œ‰'  xÒuu—¹¼:e³¨Í²ÂW0ÚO~ÁşÑQÓÄ,PE}ª‡O$ˆŠÔÎ)y(Õª‡mªÛú|ËA³7•ä"ï-š‰{"ì2D‰l.”‘Ä…‘Oa	v\G+2ö–_»ÙÓ¢‚Ã•Öj·ƒÓI´„ó^¨(á&¥*0C¼YĞ®¤À—§@T2âò ÇQeü´A„Şƒ×<3•gİR‰–v2DaŒk:C¤ZkbàMÇU!†à´æ-O~â‚I;“ËM…=3»F ÛQõ¶XOîğvã†¢3tô;@<9	ñ>EyYTÃO<.õ¿Ùî Ô)ëÚ±Ö|ªmPO Wiİ3#f¶d¡ŠTœÊ63—¸<1
‰ıa·0Ağëÿêì0†~Dn½£`F|m¡à¡%jhàQe’;°s nÃƒi fØc_|ÕĞ?XÓ³¨\ºÓƒ²>UâD¢wÚ…=à0Š
ÉÆÎ»°W!lª®sêpÇğáz<]Şüy'ØÅq”ã…ä–8°é6©H§*²ÏéJ´ÇsùşaP}ß$’Äûn"IöŞª£6‚èŸğ}YÜûodÄFR€y›ôBÄUÓ¥Ò
¥¾=ĞÃVêwí ˜İÃ46-X
àuz­ê¶ß¹“"İ³ÚCÎo}K÷ï›¨\/ı-”´<»ñYFº~’æÉ'ß`Õ¥%vÜ+–ÅDù!ÜÒ¹ä~N`è‘ËË÷!ÿ3TëÍy8Å¡U¬£W©İ`Ô‹ĞÓƒÏÒ	M¹r­Èciè°j Ì¢	X×XÇ<æŞü:¾B^ºm?ıáçŸÕ¯§i¥àÚpi[™H®ë2+ö,©O¦x,Sà
¦K`9+n¬(7DyC”ŸdÃqwìÄØá)V'†Ik<B»«’Qd0"àÅ¤G:€É OÂã`@!¤!ÆèA¸y2"wrûr(Ø\¥S±§‹Fn@ı¥ík#3lm°àkm3Õ¤QH$rO1•Ó¼‘ÀÌ.¸®­Ùp]r@¦ [@ã)ïé%Ó^\ï^$‰ÂKÔQì§¡Q&*¹zªE8WO³x1v;]0pT²k©s1-\MË©\³ë[(#án‘ZrqZYL¶™‚mS¼2k'LùŒ.g¬™Ùy#²™–Xü-J³vBÖGÿ³öBw‚o˜îN³[s^µË{npšİ5Ò%VŒ„Œm/-ÑOs-øE„–UjÚ´)2
ÇèÒI¼ú ü'¤?G½Ax‰BWAJX4e@µ—¯<	ğ^†œ’”T¾C®4æ«Ş3
’ê”x!æ¯Šü‹—Ğ´N
É†í…XKù{h4¬(
,â!+æÊbq[!ÖC¹at¼ßƒş¿ZëÆ¤öYë˜ÿ‚ŸÌıO½şäÉ¿‰Ç‹ûŸ/5ş€¬W“aµßı2økõÆÓÌø?^²Àø2÷6A‡Şó_xKx[ö<ì¿pğFòîyŞĞµ´€ódï¢B®o’AĞ#Õì‰í¥îêWI™/:ÌÅ{²
û<ïFáEjY‡z<¬ Åşõãy-xQÂ›Ñ¼ Ó	‡ãD$ %¤vÇÃM6§}$Î'cFBxÀ‘wpù¢Ry^“_Q%á^ôªŞóÇÛı@¶X¢¥_¸Å}ñĞÙª‡^³ÙâÂÂ;‰E4Í4hÓ[RÁÛYQĞO™Ÿ^Ì*SÛ©’•Ñ€ Ã4Òå>AéE~ÂŸç5¨bJ«RjÉƒKH}óAÔ÷dã-«"•Û¶.J+Á’æ75¢zfõ O×)]Ñ¯¨G|V $´KJß@­$Édsî&¨â+ıä›
•²¤¾65´µ`)m3Š•ö é3¾¢}‘Õg 6@Á>Ibl&~ƒÍÎM˜]Ş¿->·Úÿa,?ŸxùïéF}!ÿ}áñ7'õ—ÿõµõzÖşk½¾ÿ¾ÌøŸù¸çÑ••Æ\õäk[p{&|4«Û“KQæBjÀ_Ú£Uª>iŒ/Cß«¶¾Ûow=ÛTóL'ÇãaÊÒÚ;8<jíµ<»5ç#Ï@ÁÃìßŸ]¼ä›¢³‹ãè'ºágcáe€ó\‰œi¸\J“É‚¸A§ošõÂ¬Z·ª[uV9ãí.ÿ„UCÖóT:²êHë9Y÷RW€v;»­WÇ{ÔXÏíIVWbv/ptãG½è=ì£G'p,¹²2yÖºõ‘6zc!ËPr¦MïÊ©ÎŠ¾AP;ô[ò†ß‘;$5TÒ×ËĞKH}òÇ5%–Ô÷2¤bI'‡™fğ48N:ƒ ²4İ¦ÛÌ+‰+¨*2¦¦{r|l&³†ÓXà›yx<ÏÔ€B®¿ä¬êµúvš¤Û‹LI—Æ×ñŠl6‡JÊÿğóÏßË?Õ$%ab{T×HÒÄl³­£PIO¥©6uMh»&«ÃB»2…¶dkrâ4aƒFÈgØ
kB"‘
ÁàFn‹¼ïÍLÑ‚¢bÜtâÉ`,‚D«òV¹õP÷*ØtÎu…`jµÅ™Òn­ÌGƒ‡-oMOĞV½`‚^c£´™xP÷0)]í
ôe}$—½±JôœËäm§'_{Yh¶•.=hÇíúŸßÅã>šZfÕ[HĞÿ_Éÿ^ ¼ÒÑÆ¾÷§ü›Cÿ·‘—ÿ?}¼ÿ¾Œşï}ĞÓÛ'lß¯Q‰%1÷É&¬ê‘<É‰5cFè,›§å„¦¶;ïe …‹™`q
½èENÛg [ñR¥V*Â¬¥dE€+Ä"8Ã$°ş.Î±_zqĞEM!K+äÉ¨ß=Œ
L›xŠî%,-ä&ápÂûh"!q½ø`O×€hLº7qN­z£}º‘æppÂQca²rg’…’æÏk8*Óµšl*ŸlŞQ™­öŸ§º,h‰­Ñû}è(çjê•!åw¥gœ«ßâ=íÿ*(šar¿»ÿÌıãqc-§ÿÙXÄÿøgÜÿ3ô€M\[~4@xN©8éÊìZ\„Á˜üápZŸO.áET=ïŠó@ 8ˆ¯Âş9ÔĞxòHkĞ=£šñ»ßµ6Í]a‚bmdj–À,EX]¹Çñ;‚ƒ€‰<lh¾äĞG‚±ÍJ?AĞxæ‹=´wíN:t‘IÓ»°Øœqj5«Û+ãQ0H††~_Õ&G¨fCŒdÒEĞ…­™k‰™û ¾¶cm`H’tû;:©¡-|º2öâÎ{AæëfIltÎ"BÑJt
`‰¿BŸŒÈ(Ci2]HÄ_€äõºhOn0üaBr $yfæ;f|ÀÉ€Ã. ^š…\ôppiz @&d ³”×Ú$yß4v)R_Q-¸ìª™UÑˆ!¸’”Di•ïÿ°aw‘*:¦„”¤jÄˆ*Éë½¿îîğ)aêÓŞ¢$I wÿ=ºaĞ.Œì# Ç0¯£ÀjÊ„?êEãw&¢ 3¢eŞŸ–HıÔì%yYMó°óğ¸ÿµÂá˜gã³¢É8­—ÆŒ;=Ş7©”«n{r‰»mıw˜ôÈ–PJu­hŞnXÌjéò°h<s%b76ÚïƒB›©ş†‘ê0c”ŸØ,‹À0ş­)8s©^¥FæÕÒ·õ)‘t6)|¬É·`¼:%­¿]‹»€˜X…ßf6â) ”êğÈÒ;?¢ucDï< PÌ
µbÕlÈk¡5QR!1¨ö™8S2PøµŠ\ÇşëêiM÷íòAm|&ã5Ì¬~~µ¿'Şâbw&ÙmÀUY	Íô—l@Š÷T(>ÖB±ÅÑ·g	¤6ÑÙh×8k6œ¦&é¢İ—ıyàâ…5¡·Á¨¯œ07+œ²6µ1ˆM´¦¾lXõÍè5+°C–¸ÛÈÇæ­ä}H°Ø;ĞÖßÓŞìetÖoûÂ˜]bÌf‚6õ­Zˆ8ÿº÷¿÷-õÏ/ÿ¯?ÍÚÿ5O÷¿_äóğáWƒód¸eşoŠ[+õU~(Œ‹_‘Ï“ÿß_Õ•ğ<E¦ş‡=ïáC¼F†o¸À( Óm@#ûzfÊ5³*ƒû¼®=|¨.gW”‰ÆVô’îÛ´ÈN÷nzõù!}#¯áÒWSk»s>‘æÔW®FsŒ×Zµ’¾Ì¾S[Y¾7¶êÌY‚qè.ïWóİÊ—q×m˜üÜçıwæœöêßr®ú /cgs\ñÈ	aİ˜—¡’d’ùkÈ¾™¦à²}jAN™U­°@‹/ò@géİ|QÖT8o7öE%¹x˜ÓL¹ÆXF)„ïòÅjç[×û·]­„ÛÀìšR 3H˜Q	K³€5p¦)ÚZÀ~¬ì¦-¤w6 6Eº~Ğ•ülú)£ÕE™1%Á=Û¸Y®Å4*¢ì,Z&E=™»°ÿÊ¢ÁÍ­hãÀD¾½¡ƒ´t¦³l¸F\VÉŞ*•-rÆ¤+)ÿÇ@HŒè†ã™TPÉûıæäÿÇ'ùÿËèÿÇ4ûhèaWş÷I8¢@Õ‰(©ó<_Ü!.‰%QéÉ×Çı®†</â^/¾ÆƒòJ‹diúî1î‰ñÍ0lú{¾:z"ü%©¿„AG¬¤¡‘	V!Q2»¸6Ü‹éÀy/>—vµãİí·»Àö¾Öó#CŒ¶„xu"(â&u··Ğ¯òZ\ša®NnêŒš2Q†%¬©	 óe@ÿyéÜ1ŠQ…è{TÊ‹mó†ùP¶µ%Êìa…Ô”¨çü±û¾ò¬ÿ§`ñHÈ’êõ_ş+“¶^·[õ£víˆµk-ö›³!Ã.ñ—ÿ¿üÃ*ö”´/²I‚ì7PG.IëaĞÅíöpt &Hde—{ß^˜Û/í(4HİkD¢ˆ/Š¢MÌ½7^N¬ı?‰{ˆ‘aüä(§{¡Ä‘ÔòzbÊJÆ]CĞ††m´MWú¤æ[ÎÈ?-©fÃ»:à¢–VjiFªë)Fƒ˜vZİEªüS$,­qª&Õ<RŒW´G]ÂÍDÛŒÈ*5ìrBúÈ¢ÔÜ/¹…ïk”çS³"ÍÔ S½98­É	Q_KuĞÇt©O(VtÌ£E8 ¾SÙ7‰>ªmt§P u$ìLF0¦fì5£Æ2haÌŒŸ•9CQƒô5c	öTqõªvk0oè«I$¾+N„«Ø²Ùs´r“Ë<êÏ[¡Aç…äâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ï¿èçÿpZÀÈ  