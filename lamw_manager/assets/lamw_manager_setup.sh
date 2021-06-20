#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1095679197"
MD5="4ade95447aa1e0323ebe5bcd729d1c93"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22956"
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
	echo Date of packaging: Sun Jun 20 14:40:06 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYl] ¼}•À1Dd]‡Á›PætİDñrú,Bş€‡"¼œ”y„lKi_°UW÷F©%n)RCah-ş9ÁÎ9Ë`ß-¡ÒòIçt"6ò UˆÃ"q+şŞJPúfi´dLÜ3í	Ö²ˆ&ƒVª©U.Å—÷Às#SÓUĞĞË ]°ô9dó=¨`k1;¿¥®"˜a¡İŒ;Ã°(¯2‡×™$ßñ_ò–îİ ]7Î 0”4¬xåí„ã»ƒ¹/…ì”o^¦<
9"– á²²TyÙË¯RvŠ<‹‚HZ£3æèÑà-ö£'œ#h¥Û•jdgıvùİ:Ó¬;>˜şl^ÏV.TH@·R¦Q{z‹ç´bÏT:ZÑìÎO	2ãA3›i Ú±›~~Êá¬åëÂØõqï„šwŞ»”}ûOsÍñg ’ÔağSgÔÕt m/z®â4ˆÜµÑ«v'~ÃèVgZ”çÒhé2dlûŸ•FË‰xX	VÁˆõ/l€œ¨ª”/åPS©h#ê‡q~d¬ûÖ9ÖÎxBˆ)Šã8ß±şsŸƒ‚¡/Òlü{a’ygütûùÿ¥`—ÕùèÆ²k.;u:—Ó‰ÏÜŒ) `ığE[dP¼,Y€™;ÔBpšrˆJhÚ”Pâ½ÊGÏ¸£*ËÖ$òvK²“ÂóvSÓğ^1‚¯Û'ıa„‚K¬öH€<rwšæÏ›0nØ[^TÅ‚{ú}/·Zi|‚¥v!Z•„iµéU-Û|Ò)™¯×†‰ìMTÚE|q—K:ÀO—øÆ½ş3Ÿ”¢¹Ú5­‡†ÀS0©vI×©¤H<L›\`ô×^°{¸È7F”dx]²ë—ÒeOS+µA*}]ÆËÆ/_Ê¤.¤œøç÷/Æ¬å¡ÎÃéìÔˆ^óçíM-²Lu«ßŞ‚Jâİ—:PÔ ÓÀñ»ñ
ÚãúQY™#¨H!#¼;ÖG¸ÃOÃ×ÄYÀÍ°ë×¡C•ÚgÏc1eæró‹÷–úQ0ğ0k‘PMKu[u–QÍZ“K‚T„xúR#Á»™Ø#¹¸w~ÉáÌK	²Ùî¢éşÍ)±£×Å¯S`™ş˜È€kı–.ªEJúI»ÊíX÷läQ|ÿ0½]~Ğ‹Œ¥ÕÛ^éÑÒ0şC‚C—	èğ¡ÈµĞR¼â§iiŠN-ú²û]4ÆÖ‘öÒ4ĞıQî²"ÛnäĞ¡»
ß„xØü'ó¯À¡ŠblŒÜŸMD¹–ûÂÓ¤W§Ò“ªÇ@O§c‹SÑKÍ½¨­“ÛÂx¶£7°2f¶6óÿä¯nXçØr/ë¸Ò=w+òkÌ€İıĞÍ^B+ß¯›‚‡*±CR0øó”hâå-Ûtzd4)z‘´Ÿ-[‡É:§n“«v	°µ2„¢è@<â6ízš¯ŒßOGZÀ!²v½°šyÁNñŸæB-	ì;5é ÿ´“…6’¸`NëaË }¿Q’F„¿	2ìg’J0ukıB!in§ˆMp{¡’éô4*WÖ;¼T¾nb¿\C¬8{š›i“tï»MdÚo~À?á)—³œ¸z`;»‰-G-)ôÅÖñ•sn*	“Ëá¸Ù8úø>3°ÖH½#c+üÒt57#—â	H 7¸k ©±«9€D1¥?<°à`ØĞÄï(ÿFçÆçb¤Üá«E#ÁTé@**@å¨©™xwü½ÆšdŞCèJHéBï³NÒKü.À¦NvÜ¥ä·¿âÈë‘XzŒ¸*<qÛm%Ê^”jU1‡PÃö}½K"ãÒ3¬Lúşı—úí,,8¥Äı´Ø8ÿ±*v©f»öjvhAŒ^â¾¯ïúI÷Ìštõaç|Ğ…”¬ª‰&£´‹©øà…€T<Ö±Ù5ÏÌM&Â'R‹ä§)ŸXiŞŒ[4äôÜ¥bÒäéÔÇQéô”+/ËÚ‘¹*Dd`®Xc¤[‚ä"*“t(’gx!Lm¦•é««x÷?#“Ñ7?¢¯aX~Ù‰u|–õ73ö6Â@qÔïhçÀÆiŒ2÷wCJoˆÜóc‘ƒDP¥ğ­²ì¹Ø‰‰	&‰@VkÃc\ Ó	Õİ~ËÓô	ÅtÖ«‰S#¨9|{ùgk¯Ğà›5ÏJÁÒ¨ÑçÙOtçËOÅÄ­õŒ¬ª‚ü1£?Myöÿ‰ÃN{Í§ŞL¾®´¥÷1­yÏıOxšVe­²—]ˆWândi"8‚	b® ¶¸»BN`‡¼ü>ÒJÓ­bysôg8PÅ_¦Xo—H\†ŸÇrqÈópd¶êÏÎçÒ§À20å‰7‚%.Áu²Û·P (ÀJÎ]êNòoÀ´v{3á"ßñoC´öäTzXÛPùğîwú:`2…ô¸U(éÖ òğ×XÙe¢›õì‹’4ÉŠÊ¼¬¬§ï„(åõ—M5uí‘`tÏËê` xƒ³ÂâğXÓªd—ŒÕ,ÎôNºî)Ëª7`H+(‘€–#Âgğ]Œ;•ÂÓ %ˆÜ~RO±?c	üU|âT™t+ “xKÈºhí¬ƒ%™›ä{ï·†\ïÜ^Ô#{±Ë‘‹†š|’¦›C!"«øX9íGí ´ÇÀÛu}Íœ³ÑVõ/‡q‡âSiüàXÓEüsP1%³øfı»X¡\ tÃC„¹”×[Œì\Oº9ì{s¯gÑhd4dÓn»(DàÌZË®%õëî_:RºÓ¸ÿˆzMÂpû@ @¡1M<¼í‹²)50Óåëı%V°F\İ+Ã£?‘Ú×+"Zÿ;—£¥¢A:wÈûå—:LDÅ¥J‘¢¦³º]˜8ÍçŞ%ŒaÌ÷B«F;é˜T9±-K(Å•v<
ù«üÚcíĞ‰Yõ_fã`uÂyBÓ¯u8Ê¯d¾³î#éü ®UL!£$“ì€XÒ+S‘b7Ò?cd¥Ä¶¿ï¹Øâ ·^oõÒ[´7ã«ù±ã–ü‰{Öä¢CpÅŞb
ïŒk+
lUÑpKO(zWĞäeYŸÁFQ%õ:Ç,W£1QF<…e¯€üîÏy‡ß°bÄs›
UŞS¥:˜~U-ğ°ƒ³¼O°Nş¬!¨ëeÎtÛ@Õ·;¬GÎºÃpó*Y(úXTÚÏ3q±W-„PA.%;Š}w&øø(çŒr£åg{Š´§$€÷àt
èV)@VÃé4©ØCz¼«N¼qe’ÆO;Ø5(ps&(¡¿îµÅ°
*éÒ!ÎJ;§zÛXû-ˆ-ü­ê©Ö˜\-¬z‡†şÒIƒ göj#SŸI°@w+@ü¬°õú+22²şjÌ(ÈåµÄÏaˆ³tY*oğâ6ãÂ>î;4ß€°™’Cô^*½LßdVha¶º—ísŸ…«Û­Ğ= ¼,}L³¶E›"pv»ÔäV¿øX}íò¬!î<L3‹kùÕlfyëoíÒ4º»çw-ª¿qØ‘¥ÑĞD-ğìŒ«`L½F_qp-î 1†¡¨,¹6zkHÀzoÕGnmšåblÂ,º0®ÇÀÉ_X¥Âıô…YŒşåÓæ-@0Ê¶¶ÓzšïÆn’mÀìGôQƒm4ò°ğöÀ«”¤¥ÆÒä]ÛeÃ8üJcİ`ÔİëjÈ±×«MÜ}ºåK•BÒÅ¨yj¶3ë‹Ş×RÇçXò{»Ñ·âÃ_øB-[b‘å½¢²ìx8æ³ ØÁ}(èc-Zm$@WlÕöÇ§~'kğ›c¾g<OS>5ßñƒJ€.Öû Ûû«{WfYRa“4½ÒÙF»¼‚zs‘ IÀHí¾ß9ÉEcÆ–x­Œ5Ş[i¥"`I—nÑI=êŒ[÷skßMpÙQcgD°ğs»¨©I:ØÁ¢×/ş…ÁÍ5W|Ï%¶tä*«!-‹ÙM$³ÖÇ®³ı_°R>é_ìiã’ŞËîD#K‡b`áÑá¦˜~ñBYfY`“‚_`<ÀÜøn*õú¶¦ë3®Œ}+ÿbQ¹GÜ¦v·êõëM•4†6÷,!¯wİ6Š§¯ŠÒª*øÂ#ªÊNıUPÆÅqXù[F9˜ir	m;»$ßäêUéåöøigÕ•­r³Ezä¨LIP|ÓuF‡ìãø:+µ§?l˜…Gû;¸ıfh6àrAÀ"ëÀ6qC¨ú¯ºğ‡y%Çât(àêÂË5œ£…q²CO§RÈ<Î`@Ø¯K0´¡®ásù‘Uüp¼*Îa_»r µDá7Õö–tç+zäjöT³KÙÆùsÑ©y€³ïN³ÅÜ¬;6PQÄ$Å[;ûzAGW{„RrG)-ŸÚzÈªj÷ÑP<èÏÂê˜ñf–×ı>cØ$­o[AG'VOâ‹˜¡WøŞuK_=«üàoÊPÙúèõ}|kÙî÷²,ŸvGÚK*„ÌW& Ï¬®¹¹;6ZJnæõ£ÙD«JÜÅ`ÀË5ò`È´ïü!Ô¡â
‚Œ`Â¤†"SìºƒìÓ¼ôo^kVå$ÉÉr	ÅwLY¨ªêuú&XÑFİGÆvHû´*(Zq!iœáÜ|i.<Ø}ŞfëÂ#¿†ÇdÅHïŠß¸ÉÚ%ÇÄn»¢ÊÏ_ËQvWeˆûÖ¶+RÂ®"µABëi¨Ášÿ›µ?ÒñëÔwË«^0Oo‚\„Ûîô)gUhîÄ‰#ãIĞÂb¡€IÚç]/¤TG ½»<•ÑlÙøĞ’¾E¾ı“o†kùwì)à®»ÔµÏ+íg%­,7ıº·0inäKê«ş¸ZçÚ¦Î1›.Å©îwn«îØæg›öÊrÓ1Ã³cÍÛf'L©ş2,ø<Æ(¬~ß7ôPuT4è‘4DS·µÌt—\±Ôo[Ì{ç¬=²5lÑw[ªÁ™^4«£o÷{F%‚¿’‘$;MD>‹qE Ÿ¯&^‰X—ËÓÆÔºØ²švƒ¥C»ÿ÷ŠÚ„cû¢$‰"1äe¢ÍJ‹
@‚8 çM+:]ZTı\çxwútP(á•q¶ıK$PÏˆ†)m?‘.…·ºvÆsb(áíøiUaCKÖExš™/—áà¢üG²_-²WnåËv>qY¹ÇAY±õ_ƒ_6İÁÆ¤±LYÔÆ¦ce_ç-/Õ—mr&é¹±v ët&_ÓOB›a¸¨Nõo sü>;ÓYnVÈJ´$@
b>+ıŞ‘‘CKşyiujşşTït<7C%ìZ°>­«Í 7%[ rŞoÜíùÃ2¯ï$¼ŒxEç¾—ÅŠ û„M~æ¾>¸Xàäœv3*´W¸P@T5èÑOy‹5‡¥³U(MÖN¢æ%T°¼º\±Ës}VnPóöñ
c/®B5AÈ*l|ƒ3‰—5´×Nâñ¤Bn[€p;ü»~|¨H‡„8@ ÄçE=2—ĞhsÒóµ´¹2½œu.·eû@Øç)&z›Æ3á 8‚s<ÏÒ¿‡Ó)WxñŠ–ë©(n]ºì–Ô?;åOáfÔá½‰”~@R:(º]@"„}ò¦i‹±_5p‰¶d?š,íR{ÔÉcÆ\gÔäŒéşw/¸ƒ½óªş©±
î¿ZÎ»åí j­^va6àîÎXQÔÔĞN¹X»8‰qÛuÒ.|Ş¢j‰VOgd;ÊëøáZÛ…Öùd}ßáíáN¡÷­hÃ‚#—mç‹ÍMçtøUÖcnì;¸aY–­¦=4iöaí©Ú©¶º—4“Œ]Cğ¼%Dé&áëyßCY32ÅnúÀ•ço…	ÜŠ4Îü0 +®j1IvR‡>ï,,(A›‚_Å5Aëã†!ÅL—d¾fğ÷xøCX‘¢,™op¸ü¥rº¡‚’4ŒXUßgO×O››æf}Æ¼—k¦ÈÒømxVÛÙò2©ÓjCPà”¤?D¦%8öÌŒÇø³àÕ·X1RŠÛ4j#¤à²Ïr}[¦ ´®îß´A"‡ñé÷3{'B6{ ×ã®µšÕÄ-´_3ŞŠ8¾?Å	ƒpˆ+¾Òw`Òéë*qL“_ğÅ±¨Ææğ¤[hâ[„¦¿Ê^È-Dxâ•
•*iï@©ûd¹¿ª¸à²˜+-.Å»I3¼{ê»„Ñôàı+'ÛYÀÛL5Mİs ÆôY«Yå¸‹p!}ô…/H&5˜õÛ"ŸK½@€90…h¬)çêCNôi÷‰P|a¼¦=. ½6ì sŠÿªn(c$=m<ÌHÌ3…2ıÚ0: -2!¤/Í¯·“æHpk¨Bòä·¹'e·»§íô²LíKŸµã3Ñ‹‘ÅLo[™±KÄ|Îê=…C~±UR—jz­>ƒÆu?~Ñ£‘S*/ca‚ößÆ‡!aš>ä³¥wN”-€Á	$–oG|8öã'ı”?xØ	q¤ÉıÈišˆí¹'T=+~¯SñÌ{¾Ù‚÷ÿÓ,Œ…›º(Í…‚M‡]*ıt´¾¿¥e¾J0gCÿ"Äe’¹S­íÓdzze&¡JºÙÏ`ÇØ¸œ°İ™®#Fñ<¸šP2x¹'bõÇ²À0mÆ2!!^WÈjæÁx›¸KHáÊ‘BÃZU¤§7ò¬7³&*`0ŠŠ:…´lÇ­8çŒ|L­¯n#÷«àömè—Úr çŸ830MÂ@™Ø ”øÃY)gˆ)‡>‡ó<‹1äe­F#Jñ–¶é~‘RgçŠ²æ¨ŸÔ?]¸
ZQz¯ˆ»õ^T(@		ÆõÂ_™´ŠRSÊ4àï:†ôôDec›Uìôèboè¢Wa¡ãõ¼.{J †Cìe„<Ô˜ºˆOß“?¦”.Š¼“-´ªİJÜWªi˜ãúŞ(¬O!Yu—GP6š¬0‚UOãûíŒà§ĞÁ5&¶_sRÕ!~f†î1…ğïBBˆü#$hq†hŒì¼Ò%oË§Àã)]ĞÎ	 œ¼ëá>²;ˆÕ4ş`òŠNEÀ¶Êç@oÎQ—ÎƒI,T=9,Çy¼BÃÍ10ÛÔ Ñ,Ñ[fèÂv‹¾LüûB ªôR*d!£â[ä‰345Ûø9aÇ„nM\´ëEb0ëøît«Õa¥\=»Ku“Uá|ñ@Æ
$Pşæùyo!Ä—nPä=1DëŸi9"}¦-®]:–ù+N,pƒŒ‘[½¡ğIc(‹ê:GYCÑfa›Yòo€Â!ú Íı+ù@F¡–£°ª7L#…ä94H
¼¸ôcø“ÁË;ıèªy7t<î:@ˆ®s ¹KÆ€ÄÔŞÃ;ø"Ü×2}Á=lÄßnúH*Üì£—»)Ï¡^¨¦ˆ­ºGütÑG¥zš¤`“€á»DYM*DXNé»€8,	­Æñs“¡"5lH[3øå–¹-B7"©ÊšahËÑò—=Ş:lûE~˜}³Szes½ël$\ƒ‚!Î;ü¡n^O0˜öY\Æ,¢3-‘£^#WñœÀ,¤«Yë
^ÊñJ¼V¼Uq#ÿD]ÍvéÍú€F~ŒòÈÍó+×2ÅıV™]ŠÃåsÜ'ñ
CUß]ôkZr¼¾dœGò¸ÏQ²›íéaŞG9Ë³åÙ×ıOÃés(bÊ×9n…¸œtÌ .¡Ğ˜¢(m´ÄÍ—ìè$C¡xÈ³3Àü‹úpzq ş\­fÊÆÀ™˜üà²TY¼ó˜¹º‡U¼¦{¥Å&íAd‡ÛÏÌ¦ºŒÓ¾÷47ÎA4T&
÷GtíÛà´­ND÷ı˜yòè³EPÚÛ¥U'8‹µt-ş¬|B§†ÇTÜ@á‚(P©üÒi¯âƒ€Å°–‘Hy}é2Ş©4äƒÚø¹:T ¬cj¦rlÎ§éµ\|WòÄËöëgª¡°RÍê¤ ||±= P”ìd,`atöAO|¹Ef¦Û_rU]C*o2öÎ-OBDŠµpÿLxÖbµyŞzì)£?¸êĞÑÃJÈê	‰Vì»ÇVà ­~°İåc±Kndx>“;ĞîmI•úÏ>ìâ7¡~ß°ö±zBD2%a"¯¬P!Ø•Xù¸,~v‚¦ìëä´v…
>ŠÒ¸ÿàCKSŠŸ‰8~p›!ƒÈÁ÷¸Sà<ÊÀ*af¦UD7«}N]ú­ÒÒ©’>ƒ¬Ãø”„ı¦Mc™ùšØ‹_H;kˆXeÆ©Wû)ı¤NDŸüŠBØÁ5Q™ú»`á©·‘~¯wXpi®Uœ
=î¹¢>*c]ö¶Á• ²¹çê5Ïl”¿æ×(‘äıÂÍy¾äçêĞHH-·†å¹kU~C—Ğ{Öu3Ãøen)CÎğD\w]™îW]€'ËF’ÿÎ®âÀis£•&>Ü=úV^yÊ‹-ƒq76’È†Í‚ëâXj)3ê+NIMêw"¿.|è$¯>\m—FÖ+>¸6g´ælØÂú»œ)ØG‡ºÕ:EPRŠû“Ów”éÆ¥˜ã¥ó-[è•½ûâÛ>Æı3t ÿÄlCU›"OÌ£t¦ŒYåê]/‡ QH{Ó÷Î5Xö²bÄÕIµ²¶–ùé
•]‘hšÍ1Q½ï§‰
2Î§ôú¦şÒy¼¸Í_kõìjŠ7«õg»‡Åp³¨mEcíDRÊÙ=¶_M@§$l\iâ¶ˆÉqç“³óvÖ4c ÉpÍÀË«“áõ™y€w5xÛèNÊ¶ ä'wPxÅ‚¥?%ÅºOxÂkUÕ]å@¼0fãÍ}ş‰åsÕ'ûÑÅbÆëİôÜiôöñ´–•Ğ^µr¼ìÑÌ¾¼ /ìMümA´†bÛ5—~0ù¨€…dÕîx‹Ép·ÀKO<Ğü“2™ ^~¤G©@NÈ+øgËI«‡ªí
Öc`š0áÅ97…Š*B<L~ÙçÊsôa¿5ş:N;Á(›•›BVEDlÉ‹p‚ >Wâü”"' 2'5D][Ê7ñìœu­0©òSù€Í}5HXå¹	¿#LCóuMH‰§O:°Æ¯!
9`Ô iÑ¢>ÆÙÊ™¸ZvBØğ¹$İŠ^@›N¼šô}Ø³êSM•Ã.øäÚ•ºüõ«
Ùİ:ŸtYNÀ2&xöÄ¬	2éH ™’0‹ÏkHûÆüNJÆÄ² ²¬7A—&QÏºÕKÇŒ¥6kÄ0zË¼0h-70$“”LjS•ªT•šŒ$9¬PWGşıûÆ²)eq>îd]Ó€n„K-ÉÑ]B³¼Ï[ysfáL4{±Ñcçìû$¨û×_|ÛiÍİ"ô€Nú£^lï)ü.^g¨NÒNíİ"ÃØT–·ux°¿'*İøÕgM}õvÚü@DøpsÂhÃsn-¾	¯‹ğ@'«ñü·ˆ¹ñ¡KãPXX­X¤Íp{ëáj™nµ~ŒÒBÄ¡'v¡ŠE£s9Ö·Hùsï,ûœ‡ÁÁÅK[Î³õ”FÁeÊ+÷ÈêQ¨¾Cé2ª¬9j#¨@o%9«XQeQñæ(à4Ú~dDí@%¼<G!s€€öP‘ã„Ì–‘íõõâì‹@ƒX5#O%OÔ/ˆ©Œmpu¾İF¯Ås¨¼Ä±†¥¥¾ÕÎXn2üvæ\TYdÁÊç7pÇmnàü4Qê¾Qpw„c‘çS,ğı/è³æ;cÊø™ãÏ¾ıÔïJ®F[0ÌT
xvñ~Ÿ7>†é;x^oÜÔ+8¯•i>F{¯PÏGÑw”,lâê9>úÒX&!VÈñoÔm–>Ç+? ?ME@b¯éÔj6“bvhZºÉ…„2
ş³¨ÃÆËŒ¦î{¹¨Ó;9ÚYÜØo‡Ü0U½@‚V¥d·CëÕpÉ_„‡;é>eOQa¡s(%he;}Gg%Å$	)Z%BûGjøé’½H°zs‡ybÖı=µäª
iîö{›Rô¬ÃÊté€ä(Õ$òn‡ş²ˆ±Tù"½?rb2O›ŸÓh"«Ó8ÓMã9Å·(0?›¾ny;uœt£o6×:oóeh
„lv+×\Ÿ)ì8YuÌ>'9sëŠ;Ğø~Š¼xTıG»®Bk‰m$®d.öú}}$w«;ÓİvÓ1{Š	ö4)*Ïºu‹”:Ø]ïF¬k¦2:•úÃëüv»öööóÚ*äg
ëöh/–>M¡•*„[Ám,öö_}Bó‡\8%.Ş®O‡	÷ô¢9—QòúŸ^j¹d–^|ĞÙGn£tÉšÈ…´ş§HæŠ*·DÓ7AtW´séËáx/Ş2Íóú1	®¼˜óìq1pÔßâ/hHOÂpı3ƒ ¬;nY\0!S°¹Ò,-Xi•`+|JÓµ~¬º5îèFê¥­$;Ùz(Œ`€;e	Tèêû“?®(­hF‹`üÜùÁäÖ¥åNEGÚ†pL1ªbŠp¦ÕÓìé­´Ïft±8~4W¿‹A"§îÄD_¡BİÁrZİ×0Ì¸ ×ìú–:yçàQ
È÷QÜê–+Îçõ
ÌõµùsËcÃ†Çï
ç 7Sßˆ™ew«BË€{è{7EsÀó 1g¡A¬À:Ó§E{ô[¡A‡-–,r®Õº™ãzw)ëè4‚¡jAò"C:“Æ¥ÈjümLÙ>‘øè»á)Àwúpİêw‘Za¼ş—L¡Íùª! ÇqNH Â¹zw|(¦&>õÑQô Æ%ŠÜÏ{_‰¶Ÿ„3¨D€rÂWå\`NËjb³×kã{'Âsşò¤ÜQæ/¤_ƒíV ıy» Ù©tşCNÚóåÇdˆ‚ÿÕ’ÑÒ¤}WLÔ7Ç¬
QËi)«8$Óâ¾¥§Ì_}1æK'«*Ã›ØšòQ{D´öáª¾Éåêƒıpõ®Ä×q»0l’×“cÙß(*ÑäéëB×º{…îÏúX°[©Èœˆ/>±pp6ñfµ¹ú)Q¹ÕÉôèGÌX?íK6s I•7‡ÿ´\\öäŒ¬9ŸáqìÌ1˜-ÒÑäœÃ‘…"N~ãê¨Ï0{»È¦„?]ó‰âe Ã	‹ÊkÀ,½ß rÖı¿:ÿÆÚ$i^krd¯—(+*ˆu·ØÚøgÆSğêğ$™ÿ£à£ôYL»F
ÅMgT')µtBÃÆïfêØtüåâ'B$ÎòÚìC¦ƒlÆr=Ez’¡SÌE_¦?¾‡‹Ïú9ÄÆ";AİJ2Ãpb @Zøy1ÂôÚmä9†ËG¥Ê5¿6Éo… òHÈÚ¨ôµ/õİäª»ÑXVº‰ˆMw`µ¦sKòö3¹	î¸¢ã'ö£3’äIØ9gßÕ|–]­e@ô¬`ô3+ö×ÏŸ’¯§šK©‚Ä±ï`°ÕùI‰´ƒ<nÕ÷ÄAb©3ˆYÛR°Êå‹ÄæMyÃßq ÷øÉªÒ ·Ch:ó¯kœğ<ÚÊ;ïÊüöZÿâtë¡öúé”xı-ğ„’•˜ù†Ñ¿»}ûi¶ø.¥¸BÀLë÷ìRÕ5‘Æ®É¹aìX¸ªÌŞ´*mDqŠ§_(&Q5×¨ J^'JÄ#ü÷Ê	4õä®{Ş¾™)ó^ºÒ«~‘é>ƒ«­1…ûPÔUºÍîš_U¢‘ÀÇg1•µš”¢MïqÙ>%“pCw§KÔåb7Úv&6½7õŒßUÜëAòhgLß°p¨çŠİ`2ääS)A7í]K}ÄĞV+Öbõ¢C!Íï·€ùz¾_½aNŠ76ïyo‡<5G?µ²¨@íÁôù“µE[’ğ£„¾ş'êËĞ”:Nôı Ô7‹×\	zè1CÚT8ï©|`‰ÿq•MÒ YÛú4Òªœ}iM;qPà#bË·*É{.ùı9HÑ›Ø"‹ºÇ€Ì‚¬™s¶Ê«û3Êİmğ+]ªÉDèõ¸CºêıßÑKRRë!šl ß@œ§ná´ÊK·œùÙd–~ÜQÎƒyävâÕX”|(ÄH¼¶ÒŞ«²”#K1 ã+µÏ‹—3ûuóv4ÇÎ¹jwêÛ¹Û&… — ~‡@«âxjf»À‹ğîE²Ú[€‘£OÜ’ÿ€¾8Ï«HA‚©ÆÏ¤êIúC‘vóÏ—X„¸ÇÓ¦-qvJ–2«OÕ¹¢\Aº
öD×/óç]§VÚ¤„>ˆ@¢Q£ÏnÃî›‡Ò·‹`;¸d³X‹S&[o·”$Ùë}ÎÒAjçv©Çşì°?æ¬O§ÈDÁ¼7Ÿ„"ÇñPWşd-±(ú°p¼u JŞ@¥™ Éxk¸¬¥€\CfaÁ#–Ê¦4Õâã9‚»(µ¶ ÂLm‚{—Vèˆd&bWe²„Ÿ—9
{?¬cÉ¡û3râß_İéúÛáº,&vYO¡Z;ötÒöU”ÎMn'Ûc{B	uy3SG³â$f_µå?a÷ØD±Ä½™Ğ¬»Sÿ¿É|­xÛ¢Ï!±_Z¡šâ{.ˆ>™lR ÛG—¼“ªßìyZˆù§zÁ¹lvWMâäşÒ`&•¾W¯g“32Ç1Û*Ø.rT¢Lõeo¨âĞbS÷Í”´ŠğŒ—ã» 0F-¹³sÌ(0POm.;'7x+÷7ÈÊ¦v»VuÍwÈ9îş,ˆ·'7®,¨íÁ‰_m@-ß¡@~½p%<9ª%2 »x½ ªdÍ`w!O¨)ÃëïöÁ•~±¾ÎÈC+Üxs!á26Ëu³ì±3s…|²=¸ëö%«ê·}ÚNš1=ÔÆéš¤Ñé/Ú:/Sk˜ÁD<»›!¯Le…Z×0aT³öÑ¬óm_’]­Â*Z€2¾$¾ÁxjéígT¬m^hŞ1ıÕ´¯¿ï‘Èó)÷¬ğ<>‡‡¯eŠ¹G‚J,™4ÿ¦Å#¼{²'Ì¦†ÿa|©kyƒª(”¸Vì ¨9²œ¡™“ja ĞÔƒ‘Àµ*‹lÿLİDğw…8Ò0GíIƒV)—¨HÀ¾Ø<+İwü;šÂä/2«†‡Û	».y,¾ìÍ pĞ?bó¶»ÈêCn 58á
fìy‚Î=,'˜çnm³¸‡$¾rÿ¢LCQ{u‡»:h5ËV¨à´«òÏ°BšÕvÁgÒµï§9+Jj,,‘Ÿ¨NûzÅ¬ùøÀ+Pö/–_’G[Äñãë³“¸gîDP\ªN².ëPÜØELA%ø…µÂÌv*¼±1]İ“–áêÉ–mˆ¬¯Õ)şõètqß’şÛ—Of\¹ûª2œË­*cıvùâyÑø„‡r
î}QêæÑ'Á¨ëâVùÈÛ})ú½ı¢®äÁ$ß¨[cõke–2Wåá]­Ïå Öél.ŸÚ1–º}ëY–°˜|Fõ–fôØŠ¤Ç×%åvû±æ(è›ƒfäÀ½H7Î}‘Ürµƒpù‚bâÃy7ğ‰•éLêá6eí]û±kM•£ÈˆF)K£“ñ‹ÔˆÕ›S¾íîûm‹%'óNoˆ ¦y]­c(Ù§|œÉ4ÊB@fSZ¯÷Éê@wvè¾9½,éRÂ„@`77_”ÈÂ4jZF›ªiOAHŒ"/]‡l <¿(?íé™meÆIÒêÚ³Z^ÎËäìl‚|¶ÜÕÈ‹¹85%Ù£ÈR]xu½²¹÷3şgL­İœöÒˆÈİî_ù'¼ñ`%@ÂC&¼i­ÊL].£ãŞ>µÉüÛgfuA˜|µ•ÆÇ0>•šãh¿,ï„èuQÚŞw? 4•§ş·T·Q	tç½J ùÃÒªãC×«®Á==†ê™5·)ÖÍ0™}l,zæ1¸Ã5cj{:&¥6Í„ÇíœªÈ¯˜%Ë<ìÅïhÅØ`¦ÑxÓ¾½UÏ)€2–ğ&‰$qı¼ó@áY¸ªôÂèÅã3‡_ØZfo/W·ÌÎU•Ùã¬Z³-:¨Uš—__Õ@­é¿¥ĞR4aO€wW—_É¶<ÊÏ‰(>BÏÍá¬tÒÂå·:=ÇA‚Æ¤¬|æÇj‰Ë	x/K7¬@Cìx/gQ}QN®¤Úíº°M¶nf|Ó÷|46.ŞtÃt`ˆ®Kà’½¬ó_OÜU&;²Øx*.r D4qJÑÌ¶B…EÛ“Ñû`bcÜ¢ËIØ¨*¤®1EzÛÅú!Ú#„¡ƒN²ü÷Ë%¼Á¶Ù€¤Æ‡=QTD·»ò¼.PÌÆÆE]‚¥²E3ğV
|’rE(Ê1Ë§ OıÍê/÷’wum®TäØècù¨æhCü1ŸşSxøöÏø3¬I“n‹bvÒ€šôn¶Ú¥(ôP`Ğsş,×Ó¶È””ìËŒ;=×›#xrô…© ßÏÆ¾oÅ¦­…¨#"®¢úu"SºÛ:…¶9{ÙGÌªW´e…¯.¿\³êÌ¬ûÛ´Uº€™ÅÀŒq¤F:Ã²‹¥ZYÙ2àXïı	bv	°€ƒ3òSı+juëıÏhÉ.8Ìd%Y2ôGÜµ. ÅûÑ90E¿D’K{x—¼Ô˜:*0Á/Ò¾şÑ#!©Õ$8;·*u©ŞŠDDq«
NÂÖ°úÎ/ Ş¾‡"­Œİ-»h„³ÀÈõé¿M>ôÌülütf¢.P°•ğï×G‰¦Ü¥·'Zàô†UF›ñâü/½Fq:§_«"¸A†bì×'Aæër´Ñ'ğİ ç'÷ÍQJIõŸé'.nwœ²w¼Ò„µßß'ñ›l‡7@L®‚–HºØz¶îÜ)Ò™*ìÏF<gÆµRAÉØ-",¥ÒL…ò>Ø(Å´áäoÆ·sö¢Å‹æ\ŸÚ1ÀÜåxp7Kp]øY‹×˜a~võVŒ€sª#\Á”!mZeì'şI¦OåÍØLÑ¤€‡;V •¢ätŒçÖŞæZU `—(Ÿ´nfDş
¯@ è9l2€åÙãËú7áú.-¦ûLúìïùWxÖruóõíkZ:nâü½ôÇCpr¹ùÀK°y'Ê°ë–¶YÑ.J.ZÕÀ	XH»åno-¡]S¸xûÈÅ7át=±a³]ì1yUØ¬	m2úêœë;¶´¦iö{È3'û¨S¹­WÁ|ÿ³®}—ã´üãŸ+UÖhÕ;w’p*W‚Q/>&€|"°6Ö}”®eåz³å3nÌñpêŞ…é­kKRWZ£~*Dæ¬ÚbÓGÚÜÙ:Æ€Ä1`¡½õ¾^Kñà	4d¸4ÏZÎt‹KÅw £mÏ¸£®8ÏB]èg¬æô-.êa˜?`ñ?’</›"°c‘‘äµ
WâLø`Î)…º Ş·âäœ”Îe>ˆ9MO¡®ä9°?J×/B™ö$=tÒ·ĞèJ²V­ôèİŠ7¸H¨èşY¹îXM ÖV€–Îg¸> )ëÚ™d7É…ü]¹˜~İ<½-eX…Å8~ÆäÁ6&¡<W»ëı®»ô)àÕêcˆbyõ‘íÍ$ĞU^FÅUA=ÉaÀ™Cú‚k¡d•TËhÖ¤1Ç¿ÿ¶l»¹¶·5h©¨ÌHŞ.½J‹.ßüŒfî ÍÜQz>?2-\¤¬a:²”Î„OÆNóš¡<x°¯¤«¯=áõ#mBÒ‹>ŠB ‘ìC¸—2ùó
­{9ì-hpÙ™”“_	 _bÂÓeÇQAL Cæ†“ªa¶â²«ñw@Ç2¾75®|\âš=	•£dõ}Ş%·Éá±áS#S¢!û»ù:¾xp§´K i¯R½èğ±eúI	ø‹/NºğîL--ò2·Ó›m#¥Ÿ{yË“J¹¹v}1nƒ	é°Å’‚o/1é#Ù_1AlQÒT(•òœzG)Ñm÷ügÏÚ¦•ÁGÁ¿®Ÿ–[IÄB!˜CÉ¯xâqÉ¨g›n|bƒ4<N@£n¢ ‡â¬¥ycÿnıh­ñ\yí#~XğvGi£Ö¶ F_*+İ&øÉ0ÆX%áÆ'ı¤Î³=~Wxñ8“PºÅòÌ)ªìqõTã^]]•¯Ó»/ZÜãr1Y	à(`ıÏü’‘°‘Nµ6|}„u=nU[˜‚5´m!Ô@±”¬ğáîìİÙ1*÷Fa'»0ŸèPù*éú®sSS"Íà±u.ÜöÙÌ~š<~*Jí9ã#¿{àš=_ÓN«Íúñ¾¦ÑÉãŒò¿XØÇ™HL.æÙZÏUù[İÿ»]<í&]ŸN¸k4ÿ¶äÕ«@¡ª”r3P;8õ…hqßB3g!â‰œ3íÚ/Û´‘l$vç+*k;+måØ	ú}˜êclÙÜ;5ø+Ïaù:¥IÉ{?X3v_š
ñ@üÀ´'ÌbÔ¼İÎTDëü•‚¯”Äô¿„êhˆ¨zˆz¾L<Dß”¢¸Qq”,0LÉğîVÊC}çAŒë4É{¡.¢Ädw™Ì¶ÄÉRTKéu"ü³‹´»š›èƒ\ŞæÈ­wôşt	%[yüÉÃ¯ s”S•ü5Õ`|¸ÆúzŒ¨;ÿópM_2MN°išÓI)êPiâxëíkî ?r,‘“ÚF6éRÿƒ{8Ît<ÀVJl—‰‚°æ¾(uÍüUãÍqÅÇ¹{ùû&Sœ<BÒÌE/ªl ò»·8~±½Ñm-iŒ
ïÛl~v+A{LpŒÉMû,ÿ€[¹Õæ>ÖâgÆÅp^4c#a<ÔV­&D«³ïı…—;`şrCgºµQgf!\@¯ !ˆS¿¥ê:÷Qå<:ÂH3™ıÁ)'õC´.r^ÛŞ¯V®ûÌĞ©},XæŠ©'ö‚=@Íª–h]!²’#•È´‚¯ìØ¥wq°0p5ñWÎmƒïä«ñÔ}Jï5¸J¡áU!_ŒÀòl|g–ü=H$R LëÙ«üóËgğñÈâóÙ ”‚õÊ(“?tÒì¤¬ò´?$!P6å9*ñ†Û¶¼ K5‹²ÊM(à„-jo4iÒ–¹
¸GõìV÷7şo¢æÁĞ2›¥.çTU¿Á½?zåy:tlı¥¿»å“®Ö~ú6Û%Æ¿æŸü!dvgª^°r²*ÖBÛ8WÙM@×.²*¬Y§ãcZbwƒZŒcS/5Œ£Bî—ıãÍ–¢şt¡gû4„ƒŞø¦àK„Õ$¡ã»)]2wuÿÖ„"øîev¨ÛÔjÆ^%ì%o¼MÙfäÎŠfğã¨=<ãŞ‹?p‰õ•q†IT)úª#Pó-3ñEw¥Û;F2ÆwˆlRËú`1ÔI)u¦^˜¤õ`jõÔ·CQ©™£s÷ˆ¼âÿ0öùI³BÕô	ğ—Şê>&Ÿ^"ˆUä«ãá
Ô¨‹#¬xRÃVëw¢]”Ïº3T‚_IÌùzáIÿ`Pî1S¤eg,Î{üeÈ1"ıérpHÖÀ6>^Ÿ;TV€ÜÕŠØ­™ğlÿv	CŒKóáØ¥Í”†{%ÂƒtheÄ‚Z§ã)b6cb‚Àà”W$ôóeŞ£bu
=ÑU«î¸¶“İøw5¸½Wfp	ˆ‡I»¼wêpëÀt,öÍ#È&é¼WaSVåFÏíô—óš_XWÔæ'ëÇİ¹‰€§\½6‘UÉŞc‡ÍsX=àQ(5æÁœ3Ë)&„SoŒÊÃmK?¯â,³+5½"R6µ¯öFk)T­v#¡ºÿƒ!Ò¬¤ÜZ£í‰ˆsû}CµFi™asŒ)’ÕQ.‘öp~âê"ºjöšÖIÔğR(P1¶G•Or‡p‡¼Y¾ĞãÙ¨«,qÔÅäæKĞ~ó®2Ç|®&ÿ+s{Ÿ½–ˆ†ãüü„e[P:*ôæöq½à †?QwM.ù<ŠíÊ–ÆÉÃ‚MÓ¨eªóÈvñÑ.DP I”¿MÃİêÆM“î™h¡gÎ£ú·CãÅ+ËæÇ­#è’Ä¾ƒ8ÈüJÜ$‡·	N$ €3T1Ë\çó¹k®Yb›6ò<³ÎÜß!ôİoş“æpƒ³QH~R%>TPQA*p’ÁŸÂ3—ªæì7k!$°¨¡¼»÷.©Ğ/×[r®O‹¬³ı›Ç”øò]Ô»UÜ²!áÖÕôÄ€ØÃ—=
BWnûá†=~{#ÚÌèK{Û‘3%IØ©ñ1(,C\?èçg*äâm¥Å
jo£_”‚²õCŸ>÷y®hØa“¨·5æZ²kì/jÀmµ_hÀYj”ï¼‹vº7må£[† y’«}Aßá. ˜Á)öÏ“¬,íDŸX¨!\ıX"¹`Ín›²Ê%vªp\b=q-™¾3İĞ¹ç¶‹_0øyœl…ÏİØŞå¶•>MJ‹g×â¥û –Cÿ6¨¤:ò‹Ü.y?T/–#NÀ½¸‡ÂŒÔ‹|d7ğ¨ STDTŞí!¾·¯2¤eCé*9ş·äI–Ærô™‡¶´òš59´Ú½ö¹²œFLIó¾‘AjaÂ7­¯ĞYJÒò´â[Ek&¥«»2 4{––Î ùvñ>àõ¯‡V­)yù»DßËËĞ¦2Ûò$®XG‚şS¼åR`¡(¶†6DO<`$«²çë†xË7í°¥ØİÉhë*P×–sªwÃÓ²¦¬”œX(ğÒïş»ùhAlùxW3ÀIƒ† ”Y\[ÖE÷áûâİÿY»á
àcE”‡–±/öŠ$D—'uE0’Q6õu+ÚY¡a—Féâm›¢İ_¡6ƒC@A³Z˜äz$@ùeÙ‡Â +Ç& ¼¥ÕbøÕ(»‘¤¤³Ëİ|ñ
ß*¦ÆÃ®­)CQ°jÊ»Ò–¿q¯ê?	ÏÓÛ=3Èş}òb+HŸ$ƒ›æ-ûH ïÚzÅyÈêzQÇµPïàf&.l¯¥ßõ_Ó¿ÎÉ<ìòíéIx¥@üÈù€5%*}Öö&&pä{tºR™lë]DlÌ¹$Ã qÃ‹Ô¨oÓR´Lû`Ù/9S)0úúÃÙ‰<wÜÀ›ÒTî:N¡&Çâ2ÇÃ¡[ îVÀ_)[œºtèS¤…»tÏö®ii‡¼'5ÿàÀ”ßø6Äom«À!8J¤©º¤[L­¹íy¢1]}¿ğ,Sg'æhÌgÆgÍœ‘¢ô1ÜÜC…êÛÅ%;•sşø™YâMoãG{ı³¹oŒöŞıŞKúæSÑ¿–Ûª1~
—Èö·`¿_ø¬"·Ë`Œul@=¸ÂúïôB-ù0ğİÖÛˆpÅwMsÈ›;<q)ì&©ÂÄÜTƒ9#LiS¿Hå >·ÛqhŞËÄÂ¡º~Ëı,Ó˜1ï’¬Z¬p72È$?ÙhM·Ñ¯³-]{Ì;ÓÙ‚8î½²¥tj?À`šœ	)!ÆJOá{·¤ì‚P[¼L¿“eN	7FEğS‘´şŞÆŠè¬{)ã°àãİ”ıî¬R ½:Ùˆ?‹’U´çÊˆ X­æ8°é´/²ökj¤B~—ª›¹ıFMì`©Ô8-cé¶Üà¡ÛÏC¡ON˜Ğ–\ÛTÔÚ-–y*U£‡;"xÚ_k?x%¦ÚZúæMÇGúT£7\|ÜÀªÂ»üql­q¥²zÌöé²ÉÎX–~ö»^’»_g×Àİn EbKñæ^¶¤­ÿÒZî¾&PóqÒõáÿ„«‚ğ¨šu¿'[eJ·FoÇJDà™Ó7üêK= ÀıhDİÚX†G(uDáøO&Ğ¹ëÿãBY5AÀÑ-8%J~¥}›x5å®Xk€=¹)Âj¸·ÖÆÉjÆÌÏ–§ÒZ·:j±Ö—à7¸xaø|íxrè†ĞÁk*§3¡}–º;Xl)x¦1ªÕPã}1”œ8èÀ×õíG*>X5æ¿k}wòêxy)-NqkÛÇˆ­.5˜íí I“8³~›g ë3_âo°â—Ëi¨şFşí›RTM  1¨€<'ÙY.Ü<+l?­%Æ³Eİæ¤Øek¯Êš”â‘D·qmÕ‰&ò¾ü¹Ûû¡’«—OÖÊú)‘ıs»‹ZLwf@hIÜ“õ8td‰UKæÈ;ÚLÂ-óé;Âà¹Â X$¬†òb^Y±Ö0D‹ı+”¤ÑÈT²îù…Lç¨8g³ÂË®|—áC¬æ –¹‰KJÃ„Æó03+ádùïƒs}u7–‘VEö
Ï°êØLÀ™£İ=›”ëGƒU®oyïÿí<"¸n†GNr¡ÏÁ.ûëq­•¯¨vß×~¾ÊÄK÷ Áû-I´*¶[Â_C!æ•Ö/Orìş%?Z„„¼ûò‡;5IÊ:]å;šè‹üëİ®¯:Ñà)ÿoéì"Ù uB—-^Öé¡Hå­×ƒı`)^Mº9¥ã¦Ù‰ÓğHrön•Mİí™sJœÿyLÆ#f”'m=uŒ{aÎù±Tù„éb¦¦²jK¤§ÆTàX˜29	Éã¢¢È>¹‰9D´™	WÜSgL›¬Ò¢Íü&R<…=ˆQi¤DC¦ïÜmnÚøüqòYşyRÏÜ;NôíğíU7Á«ã\ìØ‡‚Ø5—0Õm¹Tïwø-@¯nñ •¨Ù¦º‹tß˜é¹y/3=Á.(*Ã†ÃŒè>íÛef§èÈÌ'åKb>´*9ûóì1‘E`#ta™Xzr“£ª<ı€‰š9û*q‡Fˆ-ÍÏV|äBÀè­–Ÿ6W"ŒV0mSùê\C#Ög—±¸§îwô:2¯	Äğ2Ö¬ØË\–q®òã2ï0ùËÃß¯Ûr«Gó!Ô·hF;o˜xjÅä{ºÖœ"‚[Ô’X·©ª	UyÎá"¡)f¯èÅİdHØ•‘£òC|9ÅF¿›ªÏ±Ñåxç¨äÁC°ŠŒßº— ‚»¸$£¬ÅWøXÙëqGWùïĞ±ğjÃaÌôÿ/Ë’!û—øZvcŠ‹<Ç*{÷ĞzĞ"Ğó®ÍKæ¤lˆÛûx×(hjòñ÷í^ÂÉ# ÁÁµ^õdÒV#ggiÒG•äo‹Éêiû¸/ŒqqÓ“f–6ç1Äì2 Eç€“İ˜¨ı+‹®«{æß†%Œ|f÷ÿz*j	Ÿx$ÁÜ_Óä?Mp	F&—«ü«)O´üèu"ñsX’¶Fñ¶íğ\ééÀŸùxÉ»³[Ù«Î923X’…ìÁ*(4‡TH2‹@&.¥JİaÇ­—×m³fr¿êú'w9gàú±H?Ùw~Ú-µóÙì])¡­C£<ñúŸ¦æ¶
WyÍ‘·/$¥T® çJÀ/9ºÃ½Vî©Ëÿ™›_êKş™áqÜŒ¦~‰Ï±£nE¨ÿèË{ñãPÍŞŸ4şëÔ aàî\p’XÃ9Ú-ò|ç™|úê(˜ĞÌT¿óyG„ß@ßkóŞÏ%ø“Ï…é¥€Aö,›ätiº®è”égt©BŸ]¡4•-Z	v–NøñAË¼nWÖ>˜Ù!(êæNS[ÑN|SŞ¡—g¶ —š¡ ‹®ÁÚ`O¢Ró/ì)_"U@$Í¥ÔNnjD@¢…œÃƒ¥+ŸõOc<åP"I¦àĞ™–ˆ$i_^„…U2ijŒEêRöi±ŠİÖšJÇÕbgTSJ¤åÕÀ~Ñ`Îjı­ÍİI‚Ux5±DæH˜Í‰ÿ{úŸ}±v4Á£&ıÅñ4õ¤weÏ]‹NØP‰l»xŸß?)ßÁgìycîCªAQÕøpO	DËåwç´ÁNĞ‡nëNîãpÄ“r`3\ÕÁ_¸ÈÅ€^ ›fÊ”›D\.Q]Î¢d€g”÷šGo×X<^Ì%Ú—xmƒjmüŠº°œ!#T¤¡>²³B[VüryE~Î:¥-ñ_8ß[…§!­X@(Ç TZ+’Çõ¡6q˜Kn9®ÚÔÆ“‚®E¨ëÅ f¾Q’ò+$±Õşp|İZóùô=ë¸øËDÚ©¾a<u^w!
myêÇœH¶¸òÕÁ£˜rV“ÇŸŠtŞ×‘£Ç`Qç˜bÛ(É¥ª30ºÖ¥zÚˆLÌ„[©,èLD¦C'–A¿p²éKnE»!ß¨ş52k£q:\p@¡Œ•×>¡,Öˆ+cT Œ.‰x3t -’@ìíºSê@ÛwVE’ı¤b«[Y¯Ñäğ‘Ú‰
ëpš*„ïò8DAÑB’.‚zòÆcº{s÷¹G1’Óí[BñhJÍŸ½öÙô¦Â&V#_b@(æ*ÿ¥Õä¶Iª–óR0¿üµl€Á_CÙĞÍÌ.l7'%—¼K÷LÊñ¨¸V´½,(YÁÔg`©K°Wš’Ktİënî©<×eDü .•ÚÍJPºõsX3„UaCw»¾&Ûv	¹ûwkfI‰›ö5N’K˜„”Ù\UÔÚBœ(‹P¤MÈgÊRÙÙG'{†q•-cÔĞÎqM­#õ”T¾éºÊ´uÿğÏ¬V´÷]éÙ0„u‘].WúCĞ_ÍÙ‰Şç›òËx:=¥ˆVI(uj"²H‹ã— ås¸-:·Ú­`ò|Gw;—Éï?Gn¿è}ãvOšÖîJ¶
¤Êêã ¹[‡÷Ìú¢Pp…5©
o!»7qiÒ_SHÏ¼Yîb’ÕrÌ©Êgîd”6¯$A¼‡~ b–¤ÊõV­ıÇ™¨¹rÁİD½L6Œ¿Mu‹b* jgP'Rë	J'Q×”yÿ%K"j;q8V»`s­@5…ş†”¶»ZÓİı°H%lÜü‘êUÕåq¼k5ãu´Ëçª~€RÿÇoaäò[wÅÃJŠŒãÎ«Rcÿmíı-Ã
İ$å¥e
›+› i­L´yu‡\c4Qş9äº,ÁùqX P2Ò,Î:İ"ŠÔ]ë­äU·Á©aĞz_Toö¹+¢™<Åø1Û5¯Üšèz¹]%`â• û_"ËÎ[¥päy† ÌÍ,¢­7ÅK(:b>¶ÅÃõ,'±ĞÈ¨­.I|e @ğh™ŒˆÍÑ
}k×»>¡;}«†»(ª·Sè	©²´\%Şâ¢™vÊgÅŸ½æ-¸J´w¢õ+t[(hL÷ú¿½û{i¥k[jŠ«ÙpÚ$	—6Lïztâs=µá.¹H™ùÙôÁíL‚¯DÚ¡£€ó*ğ(Ÿ®inÒ>Í\zşÉ‹V[ã)+ù†ŸPCrˆa¨¡‚?+ÖXl‹ß›Á*YÃ¯1XNAóä}æÓİ€®˜Š»@·§İ;¥^¬ChÇúéŒJSËˆãèOÊ(V%{ÆÄõ˜=ÿea‹>ˆÚ“Ìrìësò”	ˆ=d‘Î1?qù`KX)‘8ÎÇG„JùÜÁï~~
Îq£ˆì`}ülëî|ìvWV5¯>Úù÷X*•³Û˜‡)¹Ëã˜âÎVÂ´íeËÌŸ¤+9Lş÷±ÿW—¿~¨ÏâCLV³³¸FÇ_6›~üÌ`Á´†Jn¿Ä¦Ê¹Úa‹P©A¤ûØ3È{|\˜N‡ÅáN.ƒÇŞk&?ÌğKìN†ßW|ID`;‘ yÈ_Ì#˜HX1­øúó	¼xRôõÛ]n+å@`S˜—–âÛìL,X¾Ú/¢f’»mªDzÛ¼Üì¦o•ì¥YÆ²ÚÛëû¿.‹ÚÓp1š‘²nïæ±"Ğkµ!ÿÏf‚R€Ææ£·¿O¹us×¦`Èë®jR¤Ëb¦ÆD¢Ü\Ã†€fß- oAñ/5k¡Fïá(İRæwU™]Š%ôNÏâ)$Pq‘¤hÒâ.…è9Ü+ «dŠ±³PbŠîª˜®ãMàÁ0ŠO~@òZÈvŠ¯Õb5Îóÿ‰a'”>ÓGáÑ2µíì‹&ş¤³4 OûêQê(¨®3Æ‡²£¯å~ã–¦—i'UÎÿıú"õğI—×9¯Û·åŞ½<¡6óhü¬Y5ØÄÀ$;´¥ıÀr±Á®,LSgí ‚àukH¨«Q"lU8U¾ñ|õÚtÒ
z`”{{hbïYÒ«9+$Ã›ˆ]é&Õ¢\´;y: éoãjg‹Ş`qZOC=wËçFwà¢”NlR	­†™oãGêuU 3Ûgì»gƒ¿<#„‘‰2¡’·3 +ùnÅUEÈ;¸»êE-[ĞöHP4®ÌI“º†”³i]9¶Åá’zÕÏ£ßîz|C5.‰¹éÉ^¹¨z`kbP:e<iîaØãÔ&„Ìr¼ËZ²ncvÅ6vèÀ%>;«…yRŒltUXZ…ÚLêEiâHë<+øQ?ä¨	ò»šbJkİ§o·T)ğµMs7ƒ}([<z4Ú>òã¬R2J–çò™îÛ¬¸¡oÂû—iÖÇ‘à?'ê6rcÅÿdKœ'>OkûÈ:ü¿Şi÷gWÓO–­B˜İâã<Çašö¢d6“ûôÕÆæ!D|3 ÷$79H°·I¨nù[<é\Ğ½TZ·™ƒ¹%ÆŠĞ“9r#5áú+ÉU@ö%ÉÊ\íw†(:óœUjFâ%neŠTXMs²«fÂF,¦péê>_l°ÁÏ¢m+&«a_~¿šÒÊñ?ñ>İºÇz	gš¨øE!!w¬>Ù=Ş­ç“uw:¦äÒ&í÷ˆ–j§§œ¿Sw²^Jøä%ÚµXÁ’êC9âİØ«‚ ˆMK™¥`8ª*ôÃ¶ÙËì
]ã…Œ…Ø\–ã®‘ óù½#u¯ffıš(ÿOÎpJêXZËüPvQàT‹»}uYÛ-ÿæø@¹uRJû†í— ãVpiÖzÄ°ºÛ$ºsZí¡8^|Ï×ãN-±H.‹ĞˆµÈ.–Y"iŠu)-ıVĞÆ'UÍÃpø:š¬&Iê3›JÖúnüÏ=Cg”ÄzÛ½¹?G‡İ%·ºÏfïQïÉÛè½ì>0S>²ö1•ÄEP4ùo#^ÄÓ=¡ŞŞŸ–Ãw—ÅÖÚÇtZ¡Õ®ºIqç_¤‡ª ­UŞ+Aé°Ä[`¢=J™ÆÔö£­‹2ÄRp_;Ú/°´²¯W/)‚Ø1ÆÄÏşDE£Ü,¦iŠRüb0$‘%»
]æ·3Y!½»in_<¹öæA/×Nà:íÍ*°È¼Z\™«}J¯æ‘§-Tsìÿ PY[¢y[Ü­÷+J…jşçúWÊ«3U—BzİÛŠZ†
Núà …JÃHQÄşøçwÓ67Eè£ŸÓ§äZå˜Á²g ÌûÚ¤ñ,4åi?lè7DF„Ğ]å2$Ÿñº r‹É ×6îê"4²-Yfx1šîuièÕz€gú$hdÄ€Û9‚s„a09f$©î1d=íºLc«Îà!©U£P½r ëjñŠB$Y‚†edÒª¸;å‹šşû¾ß=‘™–^ñƒ¾fC¦+Û7.Å6„.T”Ö<×…‚”˜W»}ˆAL8Ó #’,%>èæ‹`:<q³åœÿ¼‘¨Fá ŸïësqHØé”H¿Wë¾µ{Ğ7·|g^ôviÌii’mˆd-l8‡ºE—¬ìÎˆ<'×¼™DêäÿšP¬ÉÇ/i:&[BMgj¿ˆ¦×°™JûR¡
š17°ëNôy™JÕÛ!B;è…ãÊ‡„ré°ˆäV	*}B~—gïDBíÑU£ ùä$—ì—mum5ˆtJµŒCwD5. c®oìˆºµIËˆ3¬ÕB/X«Â½åKİ³^i ×kã…Ò„r0¸ÕüÿŠ¹àµéë5¸Nz>àä$à9Qˆ³H5>ğMûĞ„`>[¤Üª*A¶¥è&X_ÆmZ~eKÅ=Üúö{³Éó­ÄØÖzId–›ÉÂììtÁ‚ñ4ÛÅéf$/B{æ¤z°ùÚ/|ù„”$ÃNNß§ı
‹W´§Û_ÈLEãT—Íİ7.+²a¼>ï§14bï}ÃÏçÚ6ù64vÓ´ÊÒ[‘‡ÖJ€ˆM¨ş
Õ>¥‰h˜«“u6¦Â"Q0¬
£¯…2™ÉœÂágDN\¾¿³-ûpXŸú$Ò$Øı¾hµñO+@¨ÑÏ¿8g´²»€¯w«¼)&Cµæäÿ#3X];¦Ôwdäà••n~!ºëîÄ‰À_³OûïŠhE	Ö‡›,…Ÿ‘—rÜ²Ï.¾g$”%
Q¦|S„á_²#öÀğ–¾4õ
ƒÎËÆ•ÏVŒí‚Ú…±ÑÓ`gå>Á3YVHfÇù<Û\PÉj²˜Çuqs|šcq3})Zq< 7ÍRÜ#”¥·;hœĞœ¤¬"ïòmØÚ•ˆTÊ&×uÁFğ?è¤ÒÄ=³sôÎm'Ég¾ı«)œß~¿i-’Ø›ØBÏãrÉÂftvÜ]DBcQƒe·^+ºS² ÂnÇ—’Z}I_o*6 È¥K€ı¹ÁÖËŒ¨Y§ÿÀ[¾L`ÃÃÂÊèÈ¾öÙèRs™ªœ&”Û¿|< <ÖSw6ËJ¨o¦ùÉåÇg·?´EÃÜ6V=M»ˆƒõÂ;Ùöæ!Ë%Æİº ãznÍéã©jEåÇ”I6ĞÑ5˜x	ÿÀ©S	ëz”õ(ÙPõŠÆu¡]DX‘K–x:¥ujŸ%+×&Õ½Ş·ñQ†Q% j‘˜Î%ÍüHy,`¬eR8_¢ÚL',eF^­çñqÈ)òëğğOû!rmyç6¼åkàqIŞivp Nô¦‰¿š_Œ‡)8hf[Ï¤î„^å8äĞœq7[‘¢V¢XÊ§û
°ğèäìŸlLqPÉ†]R…¯hğ’#váı0Ë«çiÜ0Î‡TFqÕVf%QF~$vğ+ìŠ¤ğ[†m…âurÜ’Åš½Î¾ä¹°+Í0ïñÙ÷€{*§ô%{´æ×´u·%9ª.·}¸:¡…Ìˆ#Wè×‹ƒ¿IFÃUdV"‹0T{¶Ô¨AV\Æª‚#!Òy8Fˆ¥rÊEœ)˜GæôìğPf›;z?1Ì~ıÇC$SeQh2}úô,¿±ôÓ•db‡‘V!—Y= õÙ…Õæ¨f=€ÂzsU¹š5,¡ëâì÷c<üÌÌ º_›³€Hs"iÌ:iŒc’Zj™ğ¡/g7†e¥‡è –/ui&¥ó—óş ÓbÑn‡7_˜¸8èû”d¦n¦T‘¦Å	“ŒÅvv°ô—eVÖO%üâ9XÒÕšÏ›ğ½D+®‰ï2ÔµmÍñÕ~Äëj’ÅVÚcV°bµ»è¡É^]­¨$ÃÌOÒ¿=~áóO£°ûYê!D~¤yÍ®Õ^øÏr´Ê.İ¬E\L+ÄÌLÊaZá¿„UÂÀÎXÏ©Ø¿2¹©mÒf~Ê*À}}×7]µd›Ö:ù“`ç”B¶õ©¶x·«Éè«0oÀ=€·Ú—¯€+ú+Ä3gyÑúln»¯yCè5&Ëú,Ùâñ€ÀÿTƒ®="«Û†ù
¸‰£:‹”E((2Ñ3É¾«è“¢U^:ÓÜÊ`½w9Øe¨kñ@7ºŸ“ :	0³n ‰‹²€Â³¡Ü>ìŸpŸôÂdˆ©](§ğ'$“æú_¡Õ&!¼¼±*ã«G…Ş°PK5~Ğ¨Œä¥Å;_TÜöY2Î2üTœÈ˜ÃW> ’Ò¾ÚÈ¾.øÖŠÅÄ§&ß³sd¼XGyŠ©iíá—YËàKÂÈî0ñ(-şÀù„?r“(`?8ÈWÃ–Ö±	òÚ®Oò´ƒòl$âQ-‰éİk¦LFç‹šÃzb,ø7ÑA‘‹ÃÛ~¹~T'È‹ËàµJ˜rïËÆt…ı§´18ƒ&Ëº÷ÅÏ¯]İ·~8j=éÀã«‚§&
û›æz¿çªûì­#{—ŠØı(Ø²¾&$NÈ¿s«5Ä»·Åq\Ğ€İ†WÇ(eê|Ö}Æ\Œ_š~¡a‘­ÎŠğ]lúÂ˜8tñNÃPVêÙ©IÚïzU	=‘ë"ÏÓ©TÓ æ;’Q§³bL{üÎI½x:÷6)ùJÑk}Œ6Gw)Ï:İ1VXzŞÍ­O.¦4,¿ÊÕşv™O^ 1Jf(œ”Ç—Ó¬-â'„%ÉøTùĞï.Œ£µ<X¡ù“’Gü
ÀxHò¼ˆÚ‹Ö«ÀÁTLÀB-£—Ë[ndŒ{ô
Z¡36óáë¢Ú:÷u‰ÑY‡|7šb–Êô{·!Íì|ø&X}
Ô,ı„³ë’‡7ÊğÙy¹šw-IGÚŠ†B€/í«bğªDûd³º8ØPH—ùİ¯’V]77ÑX›ãhf}–j“æ-ÿ<áCÇ¼İf‹ÿê¸G.)İÌ¬“-m.‘¦‹”õY“N°ı=ãÑHâTÕPÇ¤²Eë]å3äÕÜféŸ¾‚tìúã™‰Lƒ›ÿèğªûµí:1·¯¹W²:¥í «ôh:À4mİ¹ÇŸ(áıùªVÊµÍûB…ş*øj¸Ú`àGÛ•\šŞJ¤Şi#Ì‡)*+4£íkõíà@N‚Åß´Éàd±2­iU¥÷„-‘»~³t“xòÂ<‹73.•_©cI
L„¥ãn%ÑLTnåI<K„Dã’şl«~»vˆuä$•O¡–K£\¾­!éÒ:Z'y…qoÕ£†U®}‹®‰E:]·3²áBøøÓºIù-%šm¤gHâ<Ú5Û†}pFÍ¸¸¯êQ MíõÎÁ¬ØÆ„¥„šï};şd+ìòÎ
¶`ƒ ç_æÍkc->ÕŞ×ÅÉzĞ)­¤„»@|d?{‰¹{¨4¥«"pbÜÓûë®v'ı¢*$Ñê_ím-k ò`w%òS ¢sÏÌOÂÈçWšÍWÓ7ú×Céeˆà"ş<ŞAÉ%¯¾áÛ:Ù­wo¼şFÊ(ù}ÈZnÙ¤×Æğ½ÁøÔŒç*~Ş$VRK{„İºWîz“äØ<ÜFÜ;ùu0³>„Ö‚È³û!ò…c±t]É1–Ã¿$œ_Ï€ÃNc¸<iL Ç£‡ä.TÌ™AÑïÙÆRœÃÀ~Ã©¼ùá­JK·¥ÿ›Á§¾jä)8ï1Ä¢Ë{í]újæk0´¾è–‘àìQÿ6Æ9çù²U»saxHq´-M/fW<šH¦ôÊš:y€ûÌÔÃ~s~¢S1GjÅ]p‡3Ûİ’Ù}`ÇŞ¡RøVâ6W,H3Ë+X¬Jmë\ºó•J?JÕÃÇ‚¯–a•	9ùı÷êClex, |uI^Øº|jé²[Âò ªM™Ğz6àVDh^ÿ=éå30¢—6s”†X8	:w!É Â‘XYÆƒ ˆ³€À¤Æj±Ägû    YZ