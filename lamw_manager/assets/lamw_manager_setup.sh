#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2429210861"
MD5="9a9149565e7fcbd9073d78f7a02c2e44"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21379"
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
	echo Date of packaging: Wed Nov 27 20:51:07 -03 2019
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
‹ ëß]ì<ÛvÛ8’y¿M©OâtS”|K·=ìYE–ulK+ÉIz’J„dÆÉ!HÙn÷_öìÃ|À|B~l« ^@Š²twfv6z°D P(êĞuıÑşiÀçÙÎ~7Ÿí4äïäó¨¹µ³ûl·±ólgëQ£ÙØÜn<";¾À'b¡òÈ2]÷ú¸ûúÿ~êºc..ÇÓ5ç4ø§ìÿöÖöNaÿ7w7w‘Æ×ıÿÃ?Õoô‰íê“+UíşT•ê™k/iÀlË´(™Q‹¦Càç‰zä(ğóÈ“–³0±…JµíE£{d8µ©;¥¤í-üº”ê+Dä¹{¤Qßªo)Õ±Gš½¹£o6š?BeÓÀöC„S¢ÊÒ®›ßBâÍH½S/ øû¸uò¦ç@u2:0˜ä20}ŸdæDÅ1\‡4ÛQrêì\ı"œTè•ïíçgGF#yl††Z{ª&¸˜ñÉÑ`Ü=ZÇÇÆ
É‚æ"x»7èjÚ~6ìŒû/;o:íl®Îé¨3zãÎ›î(knÃ,ãç­áCE¹JQ ÔhX©Q Şè4ô‚ë"ßa›ªØ3ò–h°oµşë½V\‹JŞïãÎ¹J¥œ|ó;Œ®¨5ÖuÜä¿ÍÙÉ§·D™ÙÊz×rƒKWH5soÍÔ[,<Wcç”o‚bì¾aèN`[”)Ğ4¢ÿĞv({²qC”JÂ+=\øzº>õÜğ
YE‚Åz}XÕ-LØ>§Ók°ï!ö,²<² ‹	lÂÎºlí@R™š!Ñi8ÕçùäodP_‹l?İ¢Kİ'¦ºögòAÉnÂb*«b×T*‚:>÷¡cÎŸÖ¥—ı0 gĞÌoª 
?m×2j›°ÃÓsduCMhQk	ˆZNQ9Aé4Í¬ë\í¿t=E«ß’*€/€Å$ô,xÈˆ;€³á7X=¡¼éÊ2¾ó‚¨ù4E™Óğ9¨Sûä€/[)àÒÌ4¡²ª†µô7Ñ®Ôt¶AäæuˆâÛõÄ¢33rÂ@ZÙóNÍ&>µD)kOS¥’u¾öçµ³ö=Çmxi‡bFx¾°C>§A¯è”PwIºÃşqë£ÿ oZg£½AwmÙoòùô	®’ZÎ²ÙË…É(c@8"Ø]B¯ìÔëuu? ¦•røuâ*"wŠNA‹ëÇó•ÆRŠ:ÂEr’*•L1ÈÔ¤@¬ÄM±ln
+é¶òÆ˜Ø…i»)¥
>q²ºõ|àyaÁ}*•LcUcÎ÷IÔ©‰2ç!òüVùc“Ù)'\‘•Šlaœ|XßŠš´±äÑ×Ïúø¼ph»s2„88¤V=¼
ÿ€øw{{mş·¹ù¬ÿo={¶ù5şÿŸŞ%Ú¤ˆÑœMÚS*MÒóÁóñ mÎ#4Yù¥2òH?ò¡ßsÃ†±‹éZ0¾’O-Å€È· Fø×'	x)ôWÅübú_GÇ ÷ïÉÿ›››Ûıßn6¿êÿ¿gş_­’Ñ‹îv;¾!jë´F]ŒØ~!íŞéa÷èlĞ9 “ë|”#½ˆ,Ìknc ğ"^B˜có(,¸şLàÙt!“„Ø' Ï²g6ä$Ì0>nB‰ã±°/¬æ÷¾0ÕÉJ1† <òëAä*UyHáM£-êØÃBF“ÉëÂ¼ Œ:3bó‰gdx0  èšNŒŒAtLg{ä<}¶§ëÉ°ºíé_¦¨ dõ9«y§½Ó Ÿ!båÈò+ßthÏÍ„	ŒWQfvÀ`s¦Óˆg:8S'ï4‚Ã°xoú¼Î¢)y«v_­ò—´ÿ¼äğ/Vÿo6Ÿ}­ÿÉıŸbáU›D¶cÑ ÎÎ¿`ü›½½âÿ·_ıÿ×úÿgÖÿ›úæÖºúQĞx¦šú¢ßvp ÿÈœº4àa	 D±]ğ‹xTĞœ,Ÿ´Zƒö‹İm´\+ğlë9v¥jÑNCbÜÿãË#3§q¦e×#ı6Áz£‰e¹åÇÿlsiS^¬4^
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
®nôëêZü‡¨%Ì©a|¶òOµP>›1L¸õ_zıÛûº¯6’dÏûJıé’¦¯%!?,Ï`ƒİLcà è™¦N!¸Ú’JW%i·÷Ù§{öa_îœ}¸ûØım|dfeVeI‚Æ]é©*?##3###~‘LÎÕ%ŞCÃWs'E†m–WÆAÔ•º;ıªàOI¥êÇ¨Ùç×ÿÓ?¡_Í»À¼¶Ö7fÄ”Z¿¢oî`»’	G ïğ²%ıú?ÅUğSĞ=JJµ\Î–zT
ºQb¢	b¿úF«ô%šò`Mé‰,®£ñ;TöS£n”Š+ô¶òz“îøğ¯¨:ş–¤^¸ã, g1px|2WşËh¬„ÆJå²ŸÃš3UxÁí•9=Ş%ªÄ÷ò×‡­“Mª…/¸]Å`ÚÛÃW8¬<ÂÁ€±ğk9â`¦Z×/ì“+gJ•íiY]İ¨T&t¾±¨2#­Õu{–ÀS™˜TÎº[šï¼%İåÚÙ÷XõÙµîr.Ñ¬œØgNm9ÿ
o7¥Ñê+6ƒ€Me3ªjS¡Q::&,	åŒªÉ‚zÔ§¢ĞVôßãAìŒ«™…NF*ãzu½Z—ûlàÆ=ˆÑšôdK¤b$Ë‘f2CŠT^•ÑE>‘%7¦…ÍÃE-Fr÷gÃN{Ü*"ù®Ÿÿk5ì~—¿ôüÛë±ğ0Kâï«¤WÇİşŞ..Ò_“¡üÇËF4èàWX¹ñV¿Û`½İğÓÕ`ğ}?ÿÿã(”¿Q‹Óè8ó³:J~äGh/¿¡K›ñ5M£‹ƒ©•Œ¯:I7æª‡ï¹„QG¶Œ\{0a.«Ã1ÿ@Sùcœ·¯:I@ßCÕíwØGõwˆeÑ±0æ>ş˜Ä™‚pXŞ‡=ã«¬´ÿ>x²eà+ê×ø+üº]ú
*?…²À³òÛ$„Ğ7õr2Ö_dñÃ^ˆôV®ëõ~vÃ!ıt'}ù¸„¿"~BÀa»?ÇCùG{t°‹£>1rÊ(ÁÙ}•~“IÇCƒb@RÜÚ‰µ¼ÈOÆW™%%üuxu{DDrc´&Åã¹©—Š¸M?3aØ$&ÍI£}èRùŠœféÁ– =•&#+‰A|Yò¼Ô>ƒµü»¬%âê_lCÍkšHPÖY9—k3#ÎÔÙàÌ6GÀ%º¨tQ:«ˆ¨‚İ©İ©¾K:’U6ªõ3¨ñwG^Ä¶ÖËò—nSÁÜ£0½PÓrdZ!Ÿ²&½}*îu•4—:é1C¤;tª£+Ø—{ˆÌ @8»æö¬ÒÉaÛ'ÕÍs¤ìuí”°Ûòøn>#	ÀñÜ’
Ì´ÙçnÄlíFªä7IÅUæH£SeãºëÉ¨‰dŒ[Üú{z!¹‹Õš•¼¾–6¥*ÑF¹ó¨Àsêsw~‹˜hßd?r{-ë¤©Û3$E3…Åò_Ï`üòGGjÜp,“wÅ¼éå„õÛñpœ4}ıôÔ;Ö´‚Ê2›)]ÊƒÜéÀDä”×Êpğ—@EÂú?ûªÂ0‘$l¾š@wÄÀ@hhBÄH<~/Zòù>>6îà}¯ÍËDsÚ±BÂ<Ï§.Kí¹óÅg|ğJ–,ı>îh
…öÑíx]Ê“¥¥İä|2è²µ–¿Õ#³˜‚ÇÓ—¹ÓËéwW~‘æ²9¿·"ŒÁw=€uÆ9ØI›x77ŞJ_^da:õe~ãš#eï7îWsn¤wÀ~4Ll„=»˜Û –QXÂL‘ÁÊŒ¹dn»÷¹i¸8ÀŞRx‚âÄ´Â“Ãir/r‰©Tì´b–x“ht4ÅëL­|­İ““½ƒ7­â”—s±¾‹_Ğ^<â).=Õ8ïÌã™V¤•Ó†ÂÁØ•İ[Ê§Z¡}¶œ}!~(İûIí¬VÎCÅÔj—xş-õ’|Ö-w‰ä¸¿í½•Û‘ÛëÈát”÷9²],#åp4İßè~Ü²ŞFğ{"Ïûu>ÕüåY¾AwËÉ>BwÌ+}…¼Ïä¥İ2hØ¤š#å:‚ıÆ‘‚¶L«iv¶gv§ÿõÀ³<ÄÒ¯«¦IÊ­]Åîæ)æp»w±ùÄhn`fJ 7¥yyÓ.¹še{µû)íŒğèä,RÜÎ—¥”;ÕÑëÎ[ÉKwïÇtÅÊoíÁŒÒí¶Ìï”ŸLp¨qîš³Ÿ(\˜âÓŸûÕ­­"f²£áóvÔGM^‰üÈ+ ÃaÄ½¬DrÓµõPšc•ğr64Í©½¸Š-4JXm‚µ2 ã›­*¸Ú0¸Ïk×Üxı˜¼ä›Ñv¾mNAÁ[*Ù>{*Ï&©DM£ZŸ['¤‹ÜßÁçÇÛÇKV[×f9}‹Õ”(ªU¯«/7—z	¥üpu9ó‚¢ù ŠŠY¶ÖöÅ °œd7*p,pH0³Ø‡ù|)ı–/"ôq]Zæ–Lõ-=ÅP¢nÌ9–<îG‘lî(ú«ê÷’‹6˜B' [:õkkKUD%ñº3«4IiwiôñAeG!})«"„Ñ—?ÿğiÙi3T0å6fÍ2Óä¹8#.hcLxÍú¸œ­¬²ÖW–Ø¾üüOhq¬|ÔüzuÍ‡@'îÂ"ÓôOO^WùzA½|Î‘,=ß\E£x€&ø‡~’ĞØŸïsm)^[ŒŸùµwq?¬ÌMM§)õ¯ù¾ğeYR…HäıP—U´f¥™Ÿ×m¤WÏk²/¦¥[–Fritšx…iÁ1Ìªç9Œ‹ç³-¶™ßÕ:²”Ï¬ŸõP¶I†=(®ËªååYØÂëºö	cÆeŸ tW	ğµé™,ØÁ³ò
ŒË·áhÕ_ZTÎR©>½ ËLÁW5C¾Fa¾ŒKš¾Ğ¬P°iPÒ6nÛ~¬…•³ï0
§hãO6r¹éÏ°t»xÆ¼¾lÀqfĞ8ÕMqR+Cæ@q&Ïœ‰7(1I¸YÓn¥Eî/ù5Á.¶NÅÎüñìV0‚èo&91éç¢|ãw@ùõÏBye«Î³_2ş_}½±QÏÅÿj,â,ğßfá¿]¥øokÕºÿæ@³Â|FcœÅv{ ö8Ø@„dp.84Œ˜mê
Î|½Cxéğ<}P/K3HVóe0Ş¼Ò›ıÃ—ÛûâÛíã=tjoqµ¯â^<B—O¥úÛİãİfyù,ü¾¾µŞè/ëáo·w÷ùÕ¼[OßµN_ÂFüõö¾ŞĞvßïÈ,õ4¹’ÕÕ8Şµ­2)Ù†•pûï§ûº€ô9#ÍÊfÂãí£“öşá«oZ(:ùµ«€-7ºÃ÷—¸%àõZú4¢~1'ö«NĞyÒK<‚ k&ù¬ºÀÊÅ]ß[õ’w ]
4°§XhİvĞ‹àÌ”xôWpTêær7ìô@89•:]â»@È™SEË|$l“c¯ïÉíÂ
‡GxíÜ}"Œôñ…—AN}Ä)ª‰mÊnÙ4À[Ç£+8f¶ìÀÚØVêg¾èÆabøƒ?ğÅWÏ9 p	n‡úK[O¹Bšƒ‡ÃG­BÅCÄ0¯Ëuì6©2ÑM4˜ìÎJ³‰Êy£§ñd4€}]:ª_Ä“AWÄ#Qøˆ~z¹v y(r7ÂFÁãæòÁáÁî²ƒf6Éür#ÿ†®#vƒÙ)$ŠÍJsBÆräÛ‘0t qu5b]°=‡Ú —d_I_KñÄéçîûHğR0ºL“èª~%)aÈªß£C‰xË¦%,a°š6WÊ+-”P~.ã •uÃUàuùŠ-$Ñm¸…
¥oğeæÊª‹¿ú*CD˜ŠÊbŞÓ­¥ˆí:ZzªÂôÀ¼dBëJËák­vV«‰O«&Ô½L§}¼(€ÍG®Y*±|(/ô°ÇRÚü>¨ü´]ùûZå[?¬ÚHZ@È…ia.Ã"èaNúˆÀ£™mUÚÕºâöÒ j'E:amcî„CÃ ½3Éb‹¬lZGû{''»;ííããí¿a©rd(T:8ÙÅÁ¼í†’ÕÅ¶dgª¤u’ÖÑ,ç0}*l›Ã³Ştf2iÓ$]9 ÁhÜ “*Nä^ /¬Rè ¢…NÉŸÑ)ƒ6åô;w#-Él9#uz•QÊL,j)2®eF èÂ?A¥z%LJ_E$PM:\ôÏoĞÓ=¤È™P*MJ¶<tmJ1·ÖÓÑ“nOXW³\ßÒ¿õ†•>å	ç}³¼®ŸÊMå4 	kùp©¤ƒ•Ğ/e¤Ä²¦@ÄS`ËJóÊÃL!³Á™IÔZ¯ÂF#¸>âLººÇi$²;úMÅ &"1é'YãŞs!Or´ï@½aĞ‡¶tó’¿il Ÿ1œœ¯ä z©È€…Ç±i˜0S²µÌIòs¼ÔÙšY~cZ—H~åò#‘ÁğOrşpîËe }íTMÊØ±›¦eÊå²-ç´¦ì÷Òù³ÁºïÊ6› %¾ôD¶ Œ)²V:©K	T|¸ÿd¤²™‚f]½[¦×±¿md´=“Ğ´°H?sä”,t;^SKmVU‰\©u«l^GßŒ6Ş·ä·ßL'Lé­N¦˜–ñ¾¥÷¿+o[jÑíœkZ%§@¬ã8+á°ûˆ-úÑ*IKhlcÏ&QÂ‚Àš±R*ò&Î&ã ê†½˜Ñ:,3YE¬®ã“ıú»Ze4ƒ/F6g ÏQtC~&gƒ]8nÁü®V«ÈB/¾j ¹ğ:3Ñ*Ô•ú˜‚™ĞÎŒ»!ÖiGgÁü2³£„G,‡©`?»	‰.»<ê…¯2®!©2gïˆJ.Äı}}±ğ­(ë4P¡WªÊ•´0‚lç#í iÜ @ÙÁŸG <İ<'£(£¾ãÜJËù·ßMú‚"ÍG&(k2F˜AØát bëè<Å0Iâä‘ ¥xAÜ’à2ì{ gıú?pGhEƒÑ!‡ÃŒ‡«ÔËIr“Y§Ör‘&2[–É9éêÚ[b·b|ğıÚê}?¡£ğõ;dDDÁœÒÀfJ~¢ñü«º(…ƒŸ ’.¶É‚ê<ÄBéL†D•*öL[Äb "á¶ï‚hLñÊuöPXZÂVÕ·l¨PDÑM¦ÖŸaĞ¤îQÜLBXıÇ&h¨&ÆP2çJå˜^Ç×•É ˜`‹ÆèŠvW³‰Û0u Cå"úPéGËéRÛpŒSZ=ìø@¤Q˜èJ²ÇTl{ù£ÖháxKğ°‚“],ÒßÊÉ£üGL6–³ÈåõO¼¸®™3zfnã'öœ\rŠû÷3ñt“È$ı	£ó£O‹àA_$şä‰ûı>GüŸÇOÙø?ë×ë‹ûŸEü÷;ÇìŠÿã›\>g ŸW*Ö»Ê]¤şt`9†ùÉŠì^B4P†}İœCç“HV²#·['Ø"ƒæuÃ6š	5İ˜Æ©ßjšî¥GG¶Jñ=Ï:yäê²ï*2~8â°×Ò¬I(1‚<k\eUF
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
`Û3®å–š«üœ¬pQÇ+qSÉ8¼©›Ú5®M#¡(Åç!¬ÄŒÄtG¸>ÇˆÎBê0#«™a)’#‡DväîµVÊÓ­D‹Ãm»×nH6õGè£Á’‘—İs;ÕÑ_6"‘,³zv€º»RŸ°çJ K»(J@"(#E»S°4zGy‹‹07'÷–åXˆ³f×PTÑÊ;caŞîb;1ô@2¤ªtÊF–ÙÆ¼‚]Ë¹Aæ¶iæué$9Š“ñ+–0·‹¸öOwÄ«LêÓzág‰ÿóôñãü7ü¾‘‹ÿS__à¿-ğßn‹ÿVï§ãDqcvk7¹¤xU›‹Me¦v}}]½Š®‚˜íÉ {õ|TëÂY¢ÖÂ°?®­Bğ•²ìxPöÆ5(}!T8F>SWZi{VV…Vt&ˆ`^	Äü„µïğíÑñîÑşß(’¼D>lwx¼Óú¾¾Âï$)cÎÂ†ö€À Ï}×û›
JÑ¼Wş­Á0B?PiŠ@b…á¬Kşş£+ÊHÛ«Šè²ÌGhë'ÑlŠÊCñƒaGjtã´ .AÖ©|‡²Ø28.T*2;Ci°×A.•×¢ˆ¤Â|>Ê­rTk·¯…ó¨z¦¬ÿTÀ»æä(ùÂøŸúÓ'9üÏ'k‹õ±şßÿsİ…ÿyò.Ä ¬)§Ï‰êÜI¬ã
¥\Î’/ò-Õ	Íqå$©âÁ =¤*¤Ãåu€®§ŠşFÓ{Ş\GÄE4JÆ„%­n`q<8<Ù{^ê;äWk4ñ8º¸© Rúª§ÕM“UÔ^#%€!yx…úd:Kş÷Tá¯zZR–êhÃ>‚]zJÇÛ{;‡bûíË½İƒ“],Oâ¸GVÏ<ç™~„d÷™FVE·ûëÎ›öÎöÉ6ú´šFøŞM#/?È™…/}Ï©ğiŠd^~·»ÿ
iáó`˜9¦ß'›³›'JşÙøl|_‡#òPİ	QØ‡=˜éÑ(@§äŸJé­zÜVu´¨î³ñC	»öGJ†N	*JÔŸT×6ÄşI+÷âYöß	¿v‡—Î§T:4A‘\„½>>&9Øiú—DXU¯¥û?ŞHzš¢ÖSyYg<u€^5×Ì,:˜ı<å¿ıUw8Ïìç9\¿å‹agÙLáBß£T aı´¬i‘G.‚Ö‚ ÷±äl}srxóòC÷…²Q1äãUŠÅxxtb´Î‚6ñÉ<}«IP\ôÇ :§IĞ“õzã™ç€N1‹Û´ 0¼p‹&³.¥“İÕÖ 6ñcw’ÊÆúúúÓ?>a·¥ñI}¦Ğıeí\¿ÉxT5Gõgçf®ÛµEÙuNÇ(÷“lÜ‡gOÚO6rm#ß˜»fÖ>QÓŠ ¡Üé	ô¤Z¯Ö}/ã¦3•¦-“˜g¾fÕ¼1{x&ó2o˜…T×p”IİVÙÍåÆSL¶Ì=™ç²ê¢î ;«ÓÊ¢%PÛ˜nM³ÙÃşÔ4?İšf˜¹9~KÛè'Û¬ªÚ·2æövEæìS»Ù ~N÷H˜Ş¹Ê¬ÎQ*<u*N?Hµ#ÛO«ˆé/³~	²~v¦ÒDH×†ËhünrNÃı!†	¦"+2Qî·¸âP^pªšğí™Ëˆ¦¨`§kïíìªTS áÑc/)AÆ‡ï+‰TÅâÍÇeávÓ‚ıÉ*ÑhåNxErÚÑ(ş1ìŒÑm¤¤‹EÑÂÉ0è„f`ÓT ƒV‹ó}y»{pÚŞ;Ù}k¥wËYµ`ˆwUdœEUA¤}?aı’C«—°jVû¹¼|l.óëeÏp¨¶(IZ|XnùaáEŸn]YK{j=Ô5ñ»eÏğ5OùK†A®CŒŒŒ0¤5ÄE—~<)ÂA'Ljü&Ñ¸‚†ÔÙ*>U eÎÕÕ?ùék[Çm³æ1«Ma”˜ÜŒTebúŞñîö>•*×~³ê(zº0éMJ­)²,M©Qt>a¦˜1bÔSÚé2^ä ‡Î›<9¬>2±œ“n°Ÿ=É¾nú*¬€ŸŞ†Û9kµ³j­ıI”xıÂ{.D%—8“ãÃ=-W—é"¬ıHÄçğó~ŸcdSàˆ7Æ¨W!K0©çÆö1¨z5¨^ŒÂp@ÕdSkãà2©e›#2àrx«‹KKz¾EòLiÓ”F5ÈÛĞ~§hÜF–Öƒ†ù Ş~†)V%é‘Äq0©$üB%Ô«Ïª”sÉólÛ
„©•Ç‡­V{ûø­>.˜ÒÇ2…Zb‹j¼ˆ§/êV^¼::UòZXjiJ9‘Ô_éÒQãøí×¯}ŒV0×Gı«§/Ôéñèx÷õŞ_›x]^õJFÓ0½³qs·´æj_A{€î¼gD³J…wlØ§šè/ÕíV†|m<“FIêíóQÔ½„•s|1”øI‹ªö†ï	 1™á¦Â7»†Ëuíß¨H—l‡°¦½­ù÷Õdù3MÅîÔàÏÙ^î"]e¨úõ»jãE§§YÀøŞ¾b‚àX:Ş}³ûWñíöñ®-Ïûî¸m‰>>±Ôağ¨(&7Æ2§5Q…XÏGÇ½ÇÀ}…­%:ÿP¯WºáÈ{ç—ã÷°Xé_pğFÎ'ÆÃNâ†úsä2®§o?Œ“±úŒßo.ßu*ª&Ü7.{“ñzúû^
CÛôûá`‚m"™œ_±Yôƒ÷¡àá‰= Í0Œ‚‘PG–Üƒî¹¸„­jà`«x–‘’`8w¡¡wÉëÙ‡§B*9lø÷šLŸƒìÅĞ‡ÒDƒ¬!ñ ‚ıõeaôì¸§a‘şşû<¯Ğ†Émé¢õ/®à*™—n£Ÿ“=`±ï¶÷àdï¹àQŠb9¬¥JØíT[ó²]Ò}o@Ó‡sçêõAşíKe„ï08*Õ?Ö†£Y±úS-	ÊÄªa¡låZ§GÈâë]hæqë^´Å²ì»u‘÷J»›³ºhJM3öìå/¸i+éE²2ş¿Yv’F·¿Ğ¤1åæÔ(=¯ÕµMgŠ­ˆ¸}>
p^u?ú +ş:J}¹ÂÜJ_~W 'æ—p¸}UüÖ0¶o:#KÉ³¬²âÏ@VùM?ßöl°ågËÙWû°òÕëÖêÁ»_8ä¶ÕÔ®ÚËÍI6µqş£“ìcÚôLÅºÂ§œzˆÈ‚ì†&¬Â1ğ:+ôÙ‚ğØkÒHë5º9€¿A¿ûdşÂªn¼-:3‘÷nĞmŒM³Q©·)?.Ã E,ÿSZƒ6âÜšFÚše\İ+ÿŒH(d_HÛQÖ¾ÀœçKnãàÃ&_áØfgãşeŸ¥wWß„-˜üz×ÓÅçÎî§ïãaæWf>Å¨Íúí¦ºBJØõ¦ULı(d|ºVC·ì®2ìŒÂä—ÿRµäûÄÍ6Mf
kÌÕq<hH4Æ”×y¿üçìêó›¢úNbñã$kÓ^ªöBYdŠÂ	Ãût„l€tJÌ
®‚¨‡÷ä˜D°ÕÙ­!Ó é”†Öğ†ƒ×ğÔ¨9ËgÓ£¢ZÉJÉhHPá(ÑŠ«P\3Q§u:¡Ó1=7Wf·§Ñ6la*L‡Aã³,>3	ÈÈXò\ÙÌÌ•l[DnæÏm¼¥§ã×‡­#µ4êÒ¯Nß¾Ü=ÎNÖ$@Û&˜š¹–Ìa7{ÅZµş¤ZW•á]£ìØàlöå cºnîú/ÿ%^ŞhĞdo9^ì vPT|>IÈŠd¨£S<‘4*‰¡ñ9àé˜q;b„ô8W(<İŠÚ¿ü§Ø»ÀTŠ¾‡N˜7fvš„h·•šÓŒ»UÏ`{œiÿkù|Yûßúúã§yûßÇû¯…ı×û¯;€¬~706íO$3ø3™“UÑ±÷å,yó
§èÓ}ºÆcÑÚ´—ßı!»*<üäy,·*ÜrW6Ë–ÔŸ'Â¦ÇƒJ‚6Ô8"óä±ByÏÛ*†æŞI%ìâ¥î¼yé Ëê?Y¡Wj[GıÃVŠk=ö<#4ƒ/ÅÈ¤?EÃ¦:*=üsÊrö‰òöç"ûÁeÔi#0©4 ¡EiMè§¤\Z*ÕéIæÎ	’6ÌçŒç,DiZ-‡´Y¼;xö˜I3øıDÿÖ–#ğô)¡bé µ¹ŞQÌÚJİôã”¾Óp jwC´yî¢ÕyÚóï³…ØÀM~ÙÌêˆˆMo€-ªÕª°ÓJ^Q]ÙolQ²ˆl0¹i½ŸRÓÓKºÓ.“æJcîÙ¨yø"‡`UrXp‚˜DiˆÍŠå©âäª÷2æÕ6Êwø.:ì¾È;N»5±)=vòŒŠ7÷^Æ³‰º™2çû°M +èp~§ÒbO@+@ğ¤ëê /syuÊfQ!›e…¯`´Ÿü‚ı££¦‰Y ŠúT;H*¨SòPªUÛT·õù–ƒfo *ÉEŞ[4÷DØeˆÙ\(#‰
#ŸÂşì¸Vdì',¿v³)¦E3†+;¬%Ôn§“h	ç½PQÂMJU`†x³ ]I/O¨dÄåA£Êøiƒ½¯yf*Ïº¥-ídˆÂ×t†H´Ö<ÅÀ›«BÁiÍ[<ŸüÄ“v&—!š
{<gv== ¶£8ël°Üáí:ÆEgè èw€xrâ;|Šò².¨†Ÿx& ]ê³İA¨>RÖµc­ùT9Ú @®"ÒºgFÌlÉB©8+”mf.qybûÃn`$‚à×ÿÕØaüˆÜzGÁŒøÚBÁCKÔĞÀ£Ê$;$v`ç@Ü†Ò Ì°Ç¾øª¡~°(<=¦gQ¹t§e}ªÄ‰Dï´=zşÀa,’-va¯BØT]çÔ=àáÃõxº¼ùóNş6°‹ã:(Æ;É-q`ÓmR‘NUdŸÓ•hç>òıÃ ¡ú¾I$!ˆ÷İD’ì½UGmÑ?áû²¸÷ßÈˆ¤ ò6é…ˆ«¦K¥J;}{. ‡­Ôï<ÛA1»‡il*Z°Àëô.Z=Ôm¿s'Eºg+´‡œßú–îß)6Q¹^ú[(iyvã³Œt!ü:%Í“O¾ÁªKKì¸W,‹‰òC¸¥sÉıœÀĞ"——îCşg¨Ö›'òpŠC«XG¯R»Á¨¡§Ÿ¥š råZ‘7ÆÒĞaÕ@™E°®±yÌ½ùu}…¼tÛ~ûÃÏ?«_OÓJÁµáÒ*¶2‘\×e"VìYRŸLñX¦ÀL—À(rVÜXQnˆò†(?É†+âîØ‰±+ÂS­N0“Öx„vW%£È`D*À‹It “„ÇÁ€BHBŒÑƒp=òdDî:äöå0P(°¹J§bOÜ€úKÛ×FfØÚaÁ×ÚfªI£Häb*§y#™]p][³áºä€LA·€ÆSŞÓK¦½¸Ş½H…—¨£ØOC£LTrõT‹p®fñbìvº`à¨d×RçbZ¸š:—S¹f×·PFÂİ"µäâ´ ²˜l3Û¦xeÖN˜ò]ÎX3!³+òFd3/,±:ù[”fì„¬#6şgí…îß0İf·æ¼j—÷Üà4»/j¤K¬	ÿÛ^Z¢#æZğ‹:-«$Ô´iSdÑ¥“xõAùOHzƒğ!„®‚,”°hÊ€j/_yà½9%)©|‡\iÌW½g$Õ)ñBÌ_ù5/¡i’Ú±–ò÷ĞhXQXÄCVÌ•Åâ¶B¬‡rÃ$èx¿ıµÖ;Ií³Ö1ÿ?™ûŸzıéÚ¿‰Ç‹ûŸ/5ş€¬W“aµßı2økõÆÓÌø?^ºÀø2÷6A‡Şó_xKx[ö<ì¿pğFòîyŞĞµ´€ódï¢B®o’AĞ#Õì‰í¥îêWI™/:ÌÅ{²
û<ïFáEjY‡z<¬ Åşõãy-xQÂ›Ñ¼ Ó	‡ãD$ %¤vÇÃM6§}$Î'cFBxÀ‘wpù¢Ry^“_Q%á^ôªŞóÇÛı@¶X¢¥_¸Å}ñĞÙª‡^³ÙâÂÂ;‰E4Í4hÓ[RÁÛYQĞO™Ÿ^Ì*SÛ©’•Ñ€ Ã4Òå>AéE~ÂŸç5¨bJ«RjÉƒKH}óAÔ÷dã-«"•Û¶.J+Á’æ75¢zfõ O×)]Ñ¯¨G|V $´KJß@­$Édsî&¨â+ıä›
•²¤¾65´µ`)m3Š•ö é3¾¢}‘Õg 6@Á>Ibl&~ƒÍÎM˜]Ş¿->·Úÿa,?ŸxùïéÆúBşûÂãoNê/9şëkëõ¬ı×zc!ÿ}™ñ?óqÏ¢*+-Œ¹êÉ×¶àöLøhV%¶'—¢şÌ„*Ô€¿´G«T}Ò_†¾Wm}-¶ßîz¶©æ™N:3ÆÃ”¥µwpxÔÚkyvkÎG‚‡Ù¿?»xÉ7EgÇ?ĞO8tÃÏşÆÂË ç¹9Óp¹”&“qƒNß4ë…YµnU·ê¬rÆÛ]ş	«†¬ç©td=6Ô‘Ös²î¥® ívv[¯÷¨±%Ú“¬®Äì^4àèÆzÑ{ØGNáX reeò¬uë#môÆB.–¡ä4L›Ş•S}ƒ vè·ä)¾#wHj¨¤¯—¡—ú<!åkJ,©ïeH)Ä’N-2ÍàipœtdiºM·™WWPUdLM÷äøØLf¦-°À7óğx©…\ÉYÕkõí4I·™’.Œ¯ãÙl•”ÿáçŸ¿—	~ªIJÂÄö¨®‘¤‰Øf[=G¡’JSmêš4ĞvMV‡…vemÉÖ<åÄiÂÏ°Ö„D"‚Á Üyß›™¢+EÅ¸éÄ“ÁX‰Vå­rë¡îT°éœë
ÁÔj‹3¥İZ™:[Ş›¡­zÁ½ÆFi3ñ2  îaRºÚèËúH$.{b;?”è#8—'È!<ÛNO¾><ö²Ğl+]zĞÛõ?¿‹Ç}84!´Ìª· ÿ¿’ÿ;½ x¥£}ïOù7‡şo#/ÿ=~út!ÿ}ıß+ú §·OØ¾_£Kbî“MXÕ#x’5j Æ 0ŒĞY6OË	MmwŞË 
'2+Àâ*zÑ‹œ¶Ï@·â¥J­T„!YKÈŠ6 WˆEp†I`ı'\œb'¾ôâ ‹šB–VÈ“Q¿{˜6ñİKXZÈMÂà„÷ÑDBâzñÀ<¯Ñ˜toâœZõ"Fût#Íá0à …£>ÆÂdåÎ$%Í×pT¦k5ÙT>Ù¼£3[í?OuYĞ[£÷ûĞQÎÕÔ;*3BÊïJÏ8W¿Ä{ÚÿU,P4Ãä~wÿ™ûÿÆãõõœşgc±ÿÿ3îÿ™zÀ&®-? <§TœÇtev-.Â`Lşp8­Ï'—‚ğ"ªwEy PÄWaÿjh<y$È5 èQÍøƒİïZ›æ®0A1625K`–"¬®ÜãøÁAÀD64_rè#ÁØŠæ¥Ÿ h<óÅÚ»v'ºÈ¤Îé]XlÎ¸µšÕíŠ•ñ($Ã C¿¯j“#T³!ÆN2éÆ"èÂÖLÇµÄÌ}_Ûƒ±60$IºıÔĞ>]{qç½ óu³$6:g¡h%:
°Ä_¡ÏFd”¡´G™.$â/@òz]´ŒÆ'7ş0¡9 ’<3ó3>àdÀa—¯ÍB.ú8¸4=P “2YÊë	m’¼o»©¯Œ¨\vÕÌªhÄ\IJ¢´ÊwŠØ°»H
•?SBJR5bD•äõŞ_ww
ø”0õioQŠ6f zÿ}çâ’wBÚåc‹ï¼> ×)kş¨oÜ™ˆÌ“–¥Z"9ùS–ä½5MÉLÉã:ü×
‡c˜ÏŠæå´“ïôxß$X®ºíÉ%n¼õ?Şaş#‡B)Õµ¢)¼añ­¥ÖSÂ¢ñÌ•ˆ=ÚhëŒm¦ú­ÀdŒQ”V¸³,Sìø·¦ÍyZ¤…1t9”ùXâZ"ÔDRß¤H²&[Ü‚3@•´w-îbbu‰›ÙˆgPªÃÓ!KïüˆÖ½ó€B1+ÔŠU³}<"¯5šÔDI…„£ÚgâLÉ@‘Ø*rIC$°«§59Ş·Ëµ9ò™Œ×0_°&úÕşx‹ëŞe˜dwCle}4Ó_²éàSùøXËÇGß%ÚDgs ]ãl,ßp°š¤ëw_öç‹Ö`„Ş7¢¾fpÂÜ¬pÊ&ÙÔÆX LÑšú²!`0AÔ¬YânO [º’oTô!Ábï@/XOzß—Ğ±C¾íGˆhv‰á›	ålÔ·j!âü‹İÿŞ·Ô?¿ü¿ş4kÿ×X_[Üÿ~‘ÏÃ‡_Î“á–ù¿)n­ÔWù¡0.~E>OşK|UWÂód™ú>ô¼‡ñ¾áª¢T tN·ìë™)×Ìª>ìóböğ¡ºx]Q&[ÑKºoÓ";İ»é%ç‡ô¼†K_M­íÎùDšS_¹Í1^kÕJú2ûNí_ùŞØª3g	ÆM »¼_Íw+3\Æ]·=bòsŸ÷ß™pÚ Ë¸êƒ¼ŒÍqÅ#'„ucş]†J’Iæ¯!;øfš‚Ëö©e8eTµÂ-¾È¥wóE8XSá¼ÜØ•äâaN3å_Ht<b¥.¼Ë«œo]ïßvµn ³kJltÌ aF%,Í
ÔÀ™¦hkû±²˜¶ŞÙ€@ØDéúAWò³é§ŒTeÆ”÷làf¹Ó¨ˆ²³Hh™,õdzîÂş+‹7·¢ùö†ÒÒAš:Ì²uàqY%{¨T¶È“N,¬¤ü!1¢gRA%ïôÿyš“ÿ7<YÈÿ_Fÿ8¦ÙGC»ò¿OÂªNDIâùâqI,‰JO¾>îwı0äùx÷zñ5GPZ$KÓwqOŒo†aÓßóÕyûá/Iç%¬:b…$L°
‰’qØÅµá^LÎ{ñ¹´¨ïnï¼İ¶÷µş˜ú`´% tÀ‹¨A7©»½¥€~•WİÒsurSgÔ”	ˆ2¬aíGMÈ ™/ƒúÏKçQŒ*Dßû£R^l›7Ì‡²Õ¨"Qf+¤›Dåæİ÷•gø?{ˆGB–T¯ÿò_™´õº•ØªUjG¬Rk±Øœ¹vt‰¿ü§øåV±§¤r‘Md¿ò<štIZƒ.n·‡£ 5A"+»Ü{øöÂÜ~iG¡AŠè^#zEÄxQmbî½ñrbíÿIÜCŒdã'G9İ%¤–×SV2î‚n04„l£mê¸ªĞ'5‡ÔØrFşiIİŞÕµ´&K3R]O1Ä´Óê.ÊĞß·˜"y`©ŠSİ¨æÙb¼‚ =ên&ÚfDV©a·¨RB¥æ~É-\x_£<Ÿši¦™êÍÁiMNˆúZªx>¦K}B±¢c(ÂñÊ¾IôQm£;8…¨ãp$ag2‚15cg¨¨5–Acfü,¨ÌqŠ¤¯ÁK°÷¤Š«Wµ[ƒyC_M"ñeàp\Áp"\Å–õÌ£•›\æQŞ
:/ ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|ŸÅgñY|şE?ÿà:K  