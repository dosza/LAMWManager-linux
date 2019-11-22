#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4234013425"
MD5="e2b421de3a4f6181e9b30d2c336306fd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20329"
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
	echo Date of packaging: Fri Nov 22 10:12:28 -03 2019
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
‹ ¼Ş×]ì<ÛvÛ8’y¿M©ãtS´|í¶‡=«È²£mi%9IO’£C‰Ä˜"9éK<ŞÙ³óó¶¯ù±­x%Ê–ÓÌîNô`‰@¡P(Ô «ú“/şÙ€ÏŞÎ~×öv6äïäó¤¶µ³»³·³·¹·ıd£¶±¹½ı„ì<ù
Ÿˆ…f@ÈËtİ›{àêÿ?ú©ê9»ÌL×œĞàŸ²ÿÛ[Û;sû¿¹»µù„l|Ûÿ/ş)§mWšlª”µ/ı)+ås×¾¤³-Ó¢dL-˜Ÿ§fè‘ãÀcÌ#OëÎÌÄ¬+å†Œî“ŞÈ¦îˆ’†7ó#èRÊ¯‘çî“êVuK)Âˆ}RÛĞk;úæFígh¡lØ~ˆPı)%ª,í*±ñÍ $Ş˜„Ğ;òŠ¿Oê§¯azT%ı)€	48À$Wéû4 c/ *á:¤Ù.ˆ’SeSõ«pR¡×¾´6ŸŸÉc½{Ü3ÔÊ35iÀÅN»ƒÖY¯_?91H4Ïƒ7Úİ¦¡¦íç½æ ó²ù¦ÙÈæjõ›İA¿=h¾iõ³æÌ2x^ï½0T”«B€†şy€•ò1êí€B/¸™ç;ls@{LŞö­Òy}¨Wæ×¢’÷¸s®R*&‡Áü£K *Ë:nsÏßçìä³;¢Œme9‹+¹Á„+¤„yoÍÈ›Í<WcSÊ·FA1vß0t'°-ÊhêÓ™d;”=]¿%J)á•Î|=]yîx…¬"Ál9È¬ê&lLéè‚ Æ
ì{Wˆ=‹,Ìèl›£p€sFƒëA;P ”FfHtôIàE>ù™ÔÃâßÛ/D·è¥îFS]ù3ùÎ ÉnÂbJ‹bWSJ‚:>÷‘cNŸÖ¥W0 ÆĞÌ¯© 
?l×2*›°Ã£©2„º¡&´¨•D-¦¨˜ tšZÖÆu®r‹_º¢ÕïHÀgÀbz–	<dÄƒÀŒÙğ¬PŞteßyATÈ|š¢LhøÔ©qzÈ—-Èp©ešPZTÃJú›h×j:[7ró:DñízjÑ±9áº õl‡y§f	ŸZ ”•g©RÉ:_ùóÒY;cƒ6¼´C1#<_Ø!ŸÓ¿ ×tD¨{I[½ÎIı7£ÿ oêçıín«mÙoòùô	®’JÎ²Í³—“PÆ€*pD°»„^Û!©V«êA@M+åğëÄUDî‚Î¯WÌWK)êÉ%Jª”2IHÄ S“9b%nŠesSXJ·•7ÆÄÎLÛM)Uğ‰“Õb¨ç]ÏçÜ§RÊ41X5è|ŸDš(s"Ïo•?f0™QrÂY)É&ÀÉ‡åğ­¨HK|û,ÿÁ‡¶;!=ˆƒCjUÃëğÄÿ»Ğ-Ëÿ67÷æâÿ­½½İoñÿ×ø¼ğ®Ğ&EŒælÒ¾Rª‘¶h¡ÉÊ¯(¥¾Gâø‘ı‘6Œ]L×‚ñ¥|j)D¾1:À¿>MÀ¡¿)æWÓÿ**@8ø‚Ü ÿ¯mnnÏéÿv­öMÿÿæÿå2é¿hõÈQë¤Ià¢¶öi½ßÂˆí7ÒhŸµÏ»ÍC2¼ÉGI0Ò‹ÈÌ¼á6/âE!„96Â‚›ÉM2Iˆ}2ó,{lCNÁãã†”8«ù²Àb~ï›Q¬Â#¿D®R–‡Ä>Ñ41Ú¢=³1,d0™Ü¹ÎÌÊ¨3&f0‰xFÆ7
€®éÄÈDÇt¼O¦aè³}]O†UmOÿ:E%«ÈYÍ;íù+G–_û¦ËxD;5&0^EÛƒÍ"éPàL•¼ÓÃ~à½éó:‹¦ä­~Ø}³Ê_Óşó’Ãÿ²ú­¶÷­şÿ5÷„…WmÙEƒ*›~Åø¿Vé˜÷ÿ[Ûßüÿ·úÿg×ÿkËêÿó‚¾â@.HynhBêC82ˆF|ÛÁü; êÒ€‡$€ÅvÁ/âQA½{z¹GtR¯w/v·5Rw­À³­¯äØ•²EC:
MˆQp>ı—G,ŒıQœÆ™–I\të&–å.?ıg`›—6åÅJs6´±à¥ğ é¨ÓÀºsI)Y6cX»QyšÖ€mÆ"Zui¸…a†%ü˜ÎKªÏÔóaä†©ıTUŸ`Z»ÄÂçÀ¥Wƒˆœñ‚ëÁvb»Ñ59…è‰Ô~^}$eæHIÉ©edlU7ªy<çİ“,ÑP“XŒ]ºÕq@!¦ƒøÅ©zÁ›tàŸš¦Ô¡€x°5Øl¨&À28i=têı†ªG,Ğ{ˆ9TYk'`ÈC Ñ8iÕÑx2²Û<iÖ{MC½wâWÍn¯Õ>3â%®D–^‘Fª×ÅöÈ¥í•–´}ï’ »Ó³d×?í@ÇmâFëJKûe. 1ˆlë„•L!ş¸.œ›¡2,êCh‹Î$¯]?oØ3üôĞ%ŒıçpXô’'‰f¾ Ì?ıÃ±GŸ»DğÌFrÃxÏØæ_Äq‰Æî_üâàÇËAR=.à÷2öŠ|ÆTñÚø_Iw%L§/Q]šoš`v®¦öhŠÜ]€ªh2¶õ¸F®VrƒTbU]<5)Æ<ÏQmÙT«ÍµÚ2®_”ç•2ÏuÓ“îÃ¸¨B¦KK$„ÌôBY„Ã³#<<÷ŠÓõ»çg/IjÂû8
Ëü9Ör YÑ6«Úœ‚š‚á*·mß¿ÓİåPÇ‡01Ø_Zø°tû¤uvşfğ¢}Úä‚Á¦&Ä¥°<€tH˜{¯Îúõã;nf¼«Ê{U}¬N>ª«K±púT.ozW€5b¹.ÄAQG<¬[hÊ“œ9†Êâ
ĞØCÄC:8„—R–h.V /^,L „bÂå9650Â©3q¾;5İ	ÍNì*v‹@JÖ])aUƒŒÀÂ£÷8’ù¤ªLóA¿Ş=nö,`»Ó7TÍB\@bóD%í^Ú/b)Òè¶{=ØğêÕ^hñ«£Î«-•$Â×é6ZoÜ™’àB™/7f W
e·¤*RÊn#HâØ>ï6š‚£’†Ïs`É½2/Øhü$!>Ú~ÂµÓ²’î½ï®w¹,:Iç¶F+Ş‚`Ó^´ïLÀEšAàûäĞ2iÿ5Y}*·gíîiıäN%ÂjÙpÅV©`‰‚¯¦¦•BíW1´@§©}¼¾/…*¥‡”GÒIª ZÄÕ  Id-‹n=Mw·Åw»S°;Òæ¬ ¶&Ÿ¿@PóÂüâhA8‹¨»oÿ—^¤Xaûç-@’šè1G39P2)@!x_Z…Ë¥òã¶I~`ëp9’“=4_n¯Ds|màÛDnÇ“MDYº…˜9LCçöÂÀô¹²%7İ Ş<°'Q€JÜŞÚ¤;)G'õãÁQm\ıì°Ûnb9š»œ ã67‰0s³%ª/Qƒø¦„šÄ‚óöÏ!'gğáyÁŒ”¾œs$1…eù–GB¬Ä®N–6+¥E1é˜£sB…ƒ<lÕÏOúğRÛx	p-zÍï¥$ñ©Üú0†½­ğ¾÷w^e.òKxû­ş¯]ÿç×Œ˜¸	Â4jÙà!ÿ°2ğıõßÚŞîÖ\ıwgwóÛùï¿pıw†¥_ÍtfæXÿ%ép->o,øëÁ]Ê|ÏeöĞ¡¼¶ËâAoîb£.g—ğºZµú•îˆ»&X?|zç½ä‡?°İpLÖzçÏ{¿õúÍSÃP#6T$õ~¿{k[¯¨kyÁ4ÿéUóì°İıúNÛ‡MCİØİİ…‡ãnûRwß‰&€W}ç®ò7ˆ:(åßïÓ.ÕÒwjZ;UyÒÀhp‰W>¼p‚'Í‡e¾‹ifğ×È¾ôPZR–~ú»\i[Ñ­J~õ>ÇZ®õ;Lù*r.gWùJÑ,ºD}3œË‹cš—GˆÊxŸ¾xñF,ˆİãÑ—|Ò`‹
%æaşh ‰ÿ€…ñ©QË­#X/‰C Unƒ¸"AÑ”FÖÉc^‹§7VòB–Y\õŠwšC[‹»œJ·İîPÊu×ºĞ}ÇAfL¡µJï0-iè¸5`L“ 9ß–Seoˆçp‡ç@
aº^LÔvõgİ(Fq¡.ºE._J¥5í(Êo
ü¹FD\;d¼DqBÃµGĞŸ}Æ˜ tÖÄ.¢µÔ¹ßëŠ’U[ç„Äù)ƒ6ád; É¹Öƒãúpb»Ôvñ¢ìÌ)$!z»ñçüöü î@=Ikì¹Ó”ZV'#Œ·ĞSPSØ*<QBıõ¦ÌLk-QØ®CTìZH–ãÆ©B™JT‰.•´WCë–¢Õ=c¡×	<4«â¾¸øHñËßx£ZdZUttÁH¼0H@Q[™±‘é­ÆZRQã•Bü»_9îÖOš!ˆÖp§å‚=Á·ı5¢ÏÓ½@'wÏ¥éã	ÔÕG‚a ÏY‘€²¸«jE^¶*=§KQÍ÷VÚÙ\¯x‚Ì§¡É[qštùI%¿üBÈRŞçÑHÜ4dÖr$à(Ú™4Zj8Ö>ãü~ß‹†›ñ$9c–ÑT;7!O~›à!yQßÍr ü1ñ¥ô~.wŠâ9ö’ŒPpô&ŒbÜwÆg·""à ïóóC+o~1J¹Eù`&ı‹ÌÀöˆ*8ŸKoäE$9<>†…ƒuEÚÚW.êƒ¸…'çmëÜÄ×€5ÄH_¹ğ-ˆ³ .ÃÀ*9Ã³h|Ï}%s(õÉ¦l!yie j+ÈL4(²»¬W®´àıì'ÑºÅã…Ñ‘gÉ6Ó1?Æ>hæYÛ\ÙÍÀ’K7Nù²¤Şš[ã u($~«kåµIe'høK½{ŞÃ×$Ÿ4ù<Y‰c…XäÇ"«Ó™H’FIK,ôt+rs>¦*`Û¢-^‘Ë†?80«Êàrótÿ,ImrÅiò»’ÇñÀ\Õ&y<awD‰½p–/£¹ËÙv¹ÇêS—hËWâã	·éÛ
oÇ±'Ş¤%¹EÄ'9?xtMoQî(Q‰½7Ø@]š.¨Çâª’ğ
é±Kz(YÔÊO‚Ô–;ööÑ¨Â¨`´½?o`Ò~råÒ+sôu»û²¹X3ƒ‹‹Õ‚:ÙY2ëBÌ˜ôŸåûÁ™¾s!¢thÎorœí“Ã”q€×¨Ì5ˆ‰ÏúÙŠ¥ŞcLûóÏœ~»}ÒË š8àÙ¡tŞ+=ğNùbKEÚÎ˜‡ÂNK#î¢X@½óN§İí÷‘*v’Ë£†y¿ò¿Ö“Äã¬İoı6èA6’» àz¡=¾ÑïëJé5JwFñó^&÷¢9HŸ¿E¢š^Ï˜›MÅì"wkb².‡ïÜ{„PtfHöI‘¾s—`Ö·¢ğÁœíãı‡9‘úÚ¸ ó{–“³JâV}
ôÏXÜ;—¿gé<_!]#Ù²°¤1£nD0ÃæĞã¯B[vró]¡§“|ˆnú¾“¾â‘&*å?ÒÂw1äÿ.ÀÂÀ<C =¥Áøª5H3&Ï,dhhf0ˆhşê‹c´)Ù3ªû¢<Å$Ù^mÚÜh1olÖ-Ê.BÏçé_fßßŠfÒÄ7dŞ‹4Z=3gÔÈ6CM==šï"|D¹yMG¹cKĞ>šiÈîÌn4‘Ük<k.tÆÂg¨ÒVçÅ?\Æ¶“Ô¡/ËÃÁD°nİ†.Æƒå b/Àl£
|\Ÿ3Û5cl‚n‰¦ŸõlÇb64@F&<5@e¨ãùx9ï f;X„†syÄqÿåÁñyxmO€‹Â-àš"ÿõiÃ1›g÷)l$'+¤×¡~­‰ë’ü)^0Öû Ò«‰ÿQÜg»Xndå °9ßĞBDB˜
±Æv‘ïy…IóF¬ò%½+c1CĞ:bÈ¡£€ÒøüÙàÎAIo;çÓ ¼Ùß£½<ljg°”KÚ¼)¹è}¶ÿŞ1á¯L'¢F˜Æßhâ±†¯2µÚ¡‡ï‚‰N\à+YC„E§Và®§Í³óA«ß<MjO…:…E˜)dfä‡kR4ºıÂ˜mñ`êÍh‚•ßE )  ŞÈ6ÅE@ÇéË_SêøÕ‰cø5ZÓ¹ÖÙéLãÚ$²-ŠÚ3t„mĞB`ìRIÛL‹ªÓpæTÑÄ¤´eê$¬uº¹ˆ¡z=seƒâTÏ¿L¬~²ŠthÌlô#,o2;øÆı/Ÿ“q$ÎáSGĞ:kñƒ—ì&áW«D™eaUGíã l nQ2¥íx,·¸{òkw±†ú°V¼Äb¾Cæ<Â’´†ÇóiV³HìY.Š‚ bO–‡Y$1uZÈ”ÒóÒL‚Yf<Ínı~¸œéØ©UnÛæÙ¯Ç'5w÷ƒu¡™3ÂTò¸AöÖO»êz<3wG*p>4gFå¶œ#çí¿½¿#eè½Ñ!%Óò¥K
ü€é†ÏÒ¢œÔ~›üü^‡_Ï ',Æ>}Jl¬¡À×Ÿ5°Îşá²¾NÊäÄüôwOTØÀòlV^"Owø6O·tKyk¶Ò@‚\Ä¹ªå¹”ßûä/²ĞyàdMTéøÛ®JÑÅ½êG$5VãûŞëT'–&{ğW ÿ‡:ÊŒë`É™Ò ~dv„VìO¸TÌáşS¾”7Rgña.à]„éåaØLøüL%Ù~©KÎÆBJÚTV»÷[Ï©DX n«¦ëÒo0ä©aä81›yx–¦m°r=›qÆ'Ÿ¼F7OÎ¯;ñ	±‘ŒàW™NÁ¯ƒ¿F“$U5v¤ÕôÕ‰ëş;…/l€všÑ5—¤µµGW;’¡êBé\ük£Ò\<™JìštÛİÔ%×¥+sœ•xZñğ;caòß°^ÌCëØXåS˜ÓCµ8œYXµ€5ªäJÈırœs‘Ğ²‰ãşDM®Â/&Y3ñ2ËÃKYŠ,«É)¥ÅüÃ®c”êúFü_«K˜SÃ€ká_¡dÖæ0áÖèU“£]¼Ñ ?e‰¢jT†¦í­V¿NÄ§œ@Í<<G åÓ;!È¾45åéi,Êÿiïë¾Û¸‘=÷UıWÀMÎÈòš¤(ÉcY+[t¢‰déÒ$3QO‹lÉ“ln7)Yq¼ÿÎ=û°/3gîkòm} h MRŠ¬É½WÎ‰İì
@á«P¨ú•V”èû`Ø]€2¡àÍpÒ¯ÿG\?EİÁ¢èƒ^ËÕàd¹¤E• õàE ¦šHƒ@54j¥/h•—kCÇÈdqMŞà²Ÿ¤£˜[£¯µ÷Ğb˜tíƒïP¹Óş+á_½rWÆI g18h-”ÿ<š()°V;Ä§Á€ì|êğë++sÜŞ*äñê×£T
›M¸È`Úë‘áCÖag@_øs0S£ï—¶É•3ãÊö¬¬®fÔjÓ:Y\™“Öjº=Kà­ÌƒTÎ
ºŠšß¼%İŒåÆÉ÷XôÉşr!Ñ¼œXgN­©ƒwéÒ‚÷›ÕÀNÎVÃ9k]Ï6¿0MÊÉ~<+:ê•%Súš¹¾sğbøgdèR¼ÙqxÎÏoÈö3Ëf•\ÈÌ«°‚ÕÓÓy—n´c²¯1&C>pãYR¬Å§?ÂZ»MoØç‡AŠÿú	ã´àîAÒøû"íÅõIÿŒŸûÑÙYök:–ÏxŞ\‹F=|„•-Núk¬ˆ!ëú«ŒR¶Eá¿LBùÕ:=8’Nr?ëIú#¿BWù„î|Æc–F“ƒ©™NŒG¤sÑãL!éÉšq‚óñ &Üy}<áØòGœv/zi@Ï¡jö{l£úwŒ´H0špLã‘LAè3Âñ(~nDÄxD…?Â¿A¿O Õò[ µR>ıHB=©Ó‰~äÇƒ7ø1¬|—ëkø4î‡cúwÚŸå~Dğ|FÀé›?F%ÿ£È^=lb2¤A#%Iqu¸ÈdÒÉØà°EZÈ^OÆ£Ì’1ş2<úb"¹pÆÉÃ‡ÑÖêfô ÖÿşÑŸ7áD¸²²)Ø&J*©AlğsS…µ²¬‘4ÕÒ«SÉgä0L/6íÉtæ3×ŸÜ\T³y½¾^7%šğg¥)•ûÀ’çeæI,Q©ıÈe,ô·£ò«î|^ÓBˆ²ÎË¹Ü˜ct¢N('¶5î¥7ø•“a±*ô¢ÆÊ;§ƒam£Ş<¡n…ï¸9ÚpáÕ^Ò_ºN÷Âl¢¦áÔ,"ŸóNÒÄ+ô•xƒFÙ¹Gd"C¦Ì
†ƒ¨>›Hg0‡¹*.±ÖD[0SNù·H®Aß7O%–5èeå±&@Õœi›tiµ(¦ÒÂ‡ƒIG˜ÈbF‘Jg2vYÉo¬æÂTt5YBEŠk¾(®ƒît’KÆ):ã®ÓRy`	UÈ=/C®×]éSÓTS°æN·¨(øÅÄĞ9±Æ{®À¹é³“#ó“Ö¢6ÇV^XS«¨—°ÕöN·Š\ŠX€a&ôñE-276KäãğñÈDc•÷ì»;-i¬W¶¥Uvuo,6…0öñ#¹‹–¼Å,¹”‰3	+Ó¬PØG¬ì×ÍTÎ;8«“Ü×wvér3AnçìŞdr	rSñÊ¯‘…ººÌÅ2Ù%-~[W¼és0åF„€Ào¸¼›@û*0rö.`0É½Z2¿£uĞ„ìïÜe†n°±9Š;#‘»>Ò÷Ã¦`Ë4Š+ñnÂA‘ÿ,­€¯W;;ßdbø€QêñøĞ‘ï÷ğ5IM¼°À×Eí7¢s¾O²ïYH&<ú¶â¨n·÷õÅ Y×•¼.İ®—ÄŸß!ı2&-ä u$İ[;2íRßúRİ«•¹@Ìüh	.‹¦”¬++,’êZ´âì0§O7ÂMæz½ƒ4ÜøR‰oŸµÒÁm™ÖÁ¼fæMëS¡?IÑmß¨r ª$%©YÉ‰îqÎì”T<,%°Ä7ÔÂC‰CÓ(]Dq¨ÙŠk†˜5gå,ïy±ğè½}<»-<æoZÿEF÷Më¾Èüú’õ–]»]Ù¸um:ÇIğFy)Ÿ¼ş1s_»LÇÇbAì§Pî2®XÒií¾ûªSÒó
è-7ñ×^ÀÇ:X2ÃáÚ%I\­=ö» ¸¼.ĞG“-·tUHõNZÕüñ³@¥”Ÿ6NÕ"\\£qzàÊ -fİtS$4 M\¯ã÷w8ƒ}ÁmWpË\9‚Ïö¿7ğ¼8üJ·Á—ÏyÏöÍr²ïöóJnïù­kwğ\^fO¹z¿±§ .³ûjV£õ™ßèÿ|À³<÷³Ç•r¥Ï.ü7óàw8ğßºÿşâîû47(Su>4‡Ò@Mj>*j¡@:5åçÈbl¡(Ü¨ÊÉAâÍÍÛ1[Mÿ[[0‡º]÷OÅ=ò³¥¿w(ëoš³Â8Q0såÊ„kZº)eÊÇ£–ÑÊHHŒ:ÖÅFC¼š
#Q‚«%£z%Ø{ŒÇ›­B§1™„¥5sÕ;+áÄ1öÄ/·{¬`Q)–Ä¨ÀŒxº¢ ëÃ|ğ^ÏİCÎù¾µõî¯[3pq—*6î‚Êó‚îõLSM~¯Û6#¹·ƒïÛÛí¿e„Õvö¢š}]&HŒ‰8èkû²Q.ÄyX}´²œû@}‰1Id–g(÷ŒQ¯†&\$KflDYlğˆb¾ŒËgâ”,-óË$Aµ-ÓP¢~Ì9–`ş'Nğ‘¬îš(ú+ê÷’‹7˜B' ƒtõksSD”x-šGMrÚM1\6dÒCU‘F[şí‡ÏËNKÜ’ù'·6k–™Aåq@Ë]„—|?c\&+w¶pta
ñË/ÿŒzzåÜí7ë«>zqV”-ÿøèmí¹ÿçWË˜’' =/½l.¢$¡ƒÚáŸ¥øvâ—{\R„ËîT'~ït×ÖİêêÁ|„„¯|&%ïˆg£`jReK”Îû²á¨ ~yÙÍ Á©À¹:­¤ÃŒbÌñjB›7?Xf`¦×=B §]µ#ï±B_f¾¾8:Òñ õ³«úP¹áwĞ´$…-ÀØšq]'ıBú‡µeuv&Àø¤úzâ¯a²â/­¢³TiÎ&`YçùªdÈ·Vš¯Üš&/4õr%{U!#°qİ8€ã}$VyB.î$—¢5©³'U¤èåÒa~‚õ$K˜İËw†[Y5¥òYóÉ(ÉÃtY0ñ%FA÷ ´k Lé3hq°É6‰ìÂÉŸÌ¯C‡ÿf–Ó ıRœ_ûp~ı‹p¥Tgü/;äü]Æÿm:âÿn4áÕ=şë=şëlü×‹ÿuµŞ4ñ_Ÿ4è¯V˜ÏÃŸMòØ®Ä.‡‰ğ£Î	…$€©G¡.ál79„§ïÅÓ5³4ƒd1w„ñê¥ïAÜè4EQ9ûİ`Äzô/†6:DG»~Ø€h j ·ó—~8 /ä¿2x¥×'¾bD~ø*šóclÊ¾ç=41"i
{ö<ÌŠ!åF#z…x¸ÂË\Èì{ËvZ2üEè«ËÔ§w^ˆOÙ°6O|ÑÃÔ ñxà‹?¾\+„«@h3< ‹¼>í!f´ßˆkÆ]µ‰Í&•zAÂ‹5æ#Po-Q´&L“lB]ä,ú"NDSà+úéêAˆPƒà(µqkùİÁ»Ö²ƒg6ËüêZñİ GØ“³Sà.	½™å„ŒÕÈ·ã5Q5šüL‡+#"›’«İdI¶•ôŠ¢¢š~›2¼$ç©`V_Õoâ$EÊ'„èÿïŞ*4¶l^ÂƒÙÇî‡ÜêPØ«bUuœİ•/•ŸØô]CÑã‰Ò¼ÁrëáŠk şñ9&ÖD‹Ç®íVuÍÓgbıV“[òÌh]hõ<6'†ø¼bd‘)ğJR…Y[âøjKfä•¶XŠFßµŸ¶k_­ıió‡¡S‘¦…~8?Š`0†98"´÷f¾VYTíÊëGÅª‹µ^qœºA:Ü£4ÏÖTÃ½İ££Ö»ÛÛCª²g(uTÖ9ùÅÁ4h ÊÊ|Ag*¤s”•s¹W 9B›J«Ãò¬¿››Œç€rÚƒ6I\á U#‘[ca…Ü/tJnüœF¼©fÏÜŒŒ’Y!ÕsFêLå^ÉM,ª)\Ë0zNĞ‡ÿQõ*˜”Å$$=R\ôO¯¤$¤ÈÎ@•&¥À@:±fXëYïIW,k«ÚÜÔ¿õ†•½åí
çıVu]¿•-Êi@ÖòÖUI§ ¡?ÊH½bMˆ§À¦•2æ•‡…Ì=d&Qk½~	àòh|äÒ5=N#š ‡lbLD?É5÷3yì }Êƒ!¬° C¯üM}ƒq_ğ#Áa@vª—i+]9öÍšés'‹QËœd?ÀK­-ä/¦‘¯L?¹Ğ5ºÙN}¹¬ Ò!¾Bu™¬apV¦B.ÛÇ	Xk*j~/?İ¨ù®lóPáË9d#p&¥£Ò¡•MêJ
E¯„1~H2RÙLA	³®\oXf×†¿­g´ÕšĞ¼°X?·ç”,t½±¦–Ú¼(ª¹$RëöÓ¼6½-u¼®9Ş~3œğç×:!˜bZg¾ÿ®p¨F×ƒQ0x•³Úq<QÂn÷3†Ñ
IKháíK,cQC*­	°;V‡^BôÆÓÙt@yãp3
¸@)ŠÉ“Õ%	¶¥OÅ’éˆ `_” âIt]~¦'£·`~×ëuB¯ş¸ìÂ¿éÌD«P_ÇcŠáE;w:é‡X¦”ìó}`¦»ÿ$]‡ÂäÖ•óã?­?]ÏëÿÖŸl¬ßëÿşûêÿ¶°@î£ğ6ã?ùæ(_0ĞÓ›d!È—éúH±Â„tÀ§~†*Œ[È;ÒÿUÆp BÍŞtŒşÙ!áJ 0ÙkË¾ÓÀp>!·´-7Às†¼„9èb"é9Òòµ¤ïyÖn^(ÅÖÿåü‘ëâ`Ğò"[E#`·-r”Î’¶D¤€´ÑÉ‰Á´²=“äKâA1’Â'!‰½—ofFÇVºµ7“pİM©È<Ép×dpP¾R²GŞÍ­BÔ¿à
f•Gõ/¤pPÉƒ«ˆ8Ğ×dp¬³ècJ“½‰>ƒÌÀ¤¶”ÊÁD,CİGR¡ËÙIïÏÅ“^ÖBWd[Áª9^2Y)[•$˜SÁÈEN³jÙi”p#dh¤ğŒJÙãÍ]ôö»£¹åbšÙ…Ê®ìy8éL‚É4e€zróÌV±ëv·i‹¦ÀßGÇRskåhD–!A ™}zwĞıêx—'¼ü¢tA›Jr·¢Ñqí)ò\RWéEô NÈ?Á¹IH8ç_ÿı×ÿÓ3O<eàq|yNŒƒœ¶]%ayí¡'¨>ì?œ‹Ú@T›+B<Hm$‡»cM¤ºCˆRS£Œ#‚ñ¤½¡ÃY ³A¾f”bYÆ@‚ªË-<¾
ÃGÏ-û¨G"ñ0âó«ú­Î³KV$EL…ôËĞérŸxÒé»hºä ÄØ±oŞ‡½-:ØBy°QçÒÕ×š¡“DŞ‰ô}|ÉF}Û{G­ö»í£İ¿¶t4B½Âhaf½¾ZßX$B‡iƒa—r¸UZ¢5ŞÖ­"0¶¦c¤<¯U8œõ_µë/æ4à]«µÓ=>Ä5¨…ûÇV3‹÷};áiŒP°;‡£¿ì|#dıWX¾}¾`­…B
~^ƒ¿uxW|‘}]vwA>6·:;$°Ù¿0¢t«ê>'EHÊÕûÅ4¥ı˜?7›¹àÜ¼ôØøÆ[Uõbï¨£¸ÃAÇ,ö©ˆ™´³‘´¸Á ïi} c5Ó“íHŸØÚ=…y€%¦híSH¾hûæ, ŞG	¯¦)ÒKi0™/›ª–öİ7,xäW¡BÊ²j*ÁgŒ!İÑ]jNÍ›–¯ÓhM®ˆ£äJ ìpò€'¾¾*Îé^úQêà°v¹_˜9wü…óI›ÆEÀ+˜	ß§0.OëÌRD‡WÜíã7¼¥€Şg´º”ëßtñ*¸Èö¨ôÔ7ÄN>é÷ìÖ‡¡ÛN—W8šƒ~ DD¢OAé~ı÷ V'7naÂ›#×ÂIàuÇÄ1`÷¼i™¤w0Is6üz?’@)µÚxšœ‡zÚş©ö¶'±@Êfómdr¥IÃÉ_Ú­ç‚”^gÁt0ñğ0ãyîğ›;âšlu±‡ğö‰÷Ö=sÕJBÜìÈ C8ç“M†7N[­¤CHç
|\bÍ]F´?ªUÄä½öe„ÚtíCq¾¼•ÖŞeDzE–d[QË!Õî…€B"L~2êLâñ—=i5ÁŠBip5ÒÊkh^ÿ²ı×m6ô÷«Y2]º$ Ñ?(2"¯¤ĞßKJU¬j*†QÃ¦!hwÚ´íÃTQòN?§ü±¢îÕ&˜.oÊ‡ğ|[Ëøç2äº$eÀÁÁ^À6õiœâ{ÛßîoH¹4
/ˆ^ù$7à¡„ö,³©$Á¤O{^pİÅV«òGU’á­ş¯´¡¶ós|5Ë È•$wÔ Oèí¿£%ö7†Â¦¼µ¸Ä–ÔzÒœ?KH§˜lÀºv	Ş&è¼v›¢ùÆê„äh°Â®A—åçA4Rgç™•àåu¸Ñ^eîVŠå¶miü£¼5›Í[òváõ%Ê%kT-Š…®Óş·2f2‚ğ¥l	Toy1.4'	Â…šÇ8…­QàfQƒ…c_Ö¦#˜@p‚¸Baß[*ún:ÎÌ³ècm¥(Ş…L³Tgä†ã£=×Ò“ov#ëtF>gLLÊv„êÀ½Ó›}fgÈâŸùÀ»jªT¯Ö-×ªĞ‡e]xƒÌÙ/¢ƒ±j'IyÖbÎ¯P‰FQ„Á~ŒÁE†á$‰Sò;:äŸpNË];¯[—©–V£u	ÒÛ¾Y–»óq§Õ%s6Tşh”;_Uë/F;š÷ä³·÷¶4PúÚ‹*G¤W"EìÉÈ¦ÆÒ„†şçöé
ætsßß~·ıU«İ}³¿ıÜŞŞoÁi¹Ã^9¾vßÔ®ñ†&¨{´İşªuä+-!³¤ÃÂ|ğ‹MóõñîtÌµ)pF~6ÑmèEøq’º›Ã58ÄÅ)ú’^ÉVa—n÷YÕªVÅ]
0EÑ* W·ğ—àoô¢[Dã·>°ö…t¥)çèšdé,F.ÂÇÚ|>«jçq|>å?] zÕEpğ¨J¢œLÕÇbh‘Ì¼ÏAò!œt@}”Êeî$ÁøC—L´UdÏ\ëÊ;nå|˜ëbË/ëçÚì~®Íìç½İ7­wVÇš60¤˜	${»ÚŒAV>ÀV2­áåh+®`N‹ß+KFÄ¥æı/´\g ÷7“«÷s÷‹ÎİÙ“Æ˜3+JIóU81ïéğ.D;‚ñŞ]ÇmĞJ/š­x[BÂ•ƒãôPD«Ÿ*L§n£(èTtŒvk¯µİi5ê]'ÑˆÁgÖg4 vP.{—Ğ¹ä'‹Û°UÆQ§«©ƒ¡%éìæf‰h!+áª¾/Ì»³úyşù6EgR½‰ÕÆî¢éé×·çö(Èøoùsn´_åƒ+ş-Å¥81Œûˆ¬T#´ÉB<Şf¤ªz±Óõ&a}RS+¯ìŒi*_ÍªÆ<“"ù¨Şö›îŞ»oJ.D…4ugA4ÀxÆéD9k‰Ç¤Çƒ‚Æ„9õìBÔè™QúÜáS$yK±[Û×¼ÅƒÆ$Ã›·*H§›Å†r¢Òf%ƒE÷ãËÑ †£/92À`7›ç…µÃXBÖ!hñ¬~qgÉ"Ù®•šêg€¤P¯»tÜzè÷ñˆ@3iÃì¯dl(‰è‡´­æ<ÏkŒ£Fãé`à¯¨.Sı¤¿£Ê¯d,>şùÖû:Ì˜­îª0ÖÇ³gÏD­}QÂ1Ó.egœ³j^&¥Òqr¬|ÒŞ¬R×©•ÔEŞŠÂã³·=š%Ñ¹mÃ–3ËÈ«Ì¯{ù¢TIB°CT<{ÆS8İÒ„®uü¢¹¢ÌKÊK¬/\d½´L«H½æœTIo4šĞ¶Lv.¤Æ¤ö…	£âëX¸¦nœG½#ØÂw¥•‹¨´MÔF‰:¿Â®aíŞ ™*œüúÏ$ŠÑ}º“ˆH?È9É¡fŞª$­oÇ*ÀB K¯d¬[ÂàÚ———µpZÆ,_¯N‘sx³`Ì÷„“Æ¤Vı„T¤Y‰Üè>× e}$õ?»K*öåµº9¾7¼[#Ë`?^œÉşÃ:¢÷s>2…°¾æğàÍO†ÈÌoçnÇæ2cãÎE¬ÒKc¡qB€Š²¬êGƒ÷Z:3ƒ5ñ¢°5™'+æ¨’µúûî¡Sş1VyW¯¬—öÊtôS4¶¨hŞš}’ûëWny”ä®!O\,HÎÓ^Å8¦w‹,ÙTìÁ‚A<%wL9	Ğ®,UCáaVê z,QMf—§6;Å’]òüò„#e„&É·ÕíR¦Q³c¤J'ØÚ¨—®mpÔT\£¥-†X)ß W6Ò¸¤ó³°Bõòe‰9ÚsÃ™ ˜JVèlf’ˆ4=õœ‘EÚÿ ÊVFaßìZŒ;f»6OÜµ¡ÊğôJ%nz*A.7Ö××Ÿıéi¾I©kv
,Vg
‡¼›fòfVe”è'kOêkõ'¾+‘µIõuVBÕA¶mFço÷]I«ÕuR†•aËŸ‘!ë{ì³3ä¸¶Çã8ÍPá´Y2˜jÍë¦™;ky–y×½Œ7îâ“íEÇ§ÈhÕê*9&‹/3yX›Ù.Ü™NyÖÌ.ë®¬æì»oï#ñ¿¦Í] ”B™”4ŸŸÖLTjµL…šèì~µûîH¨`](Ü¿¥¥ü!>_‚ÑæÉlnE
'³…ªniG±,èÁ ’rƒ[^(G@L†Ó:¥}•Ğ[º
Sñ³¨c@!{)Á9¶DO>C ­º>¥/zMo»•_­â°pá‡ƒ5—A4y¬V¸kø²Y%ä"Ä€“vIex¥¬*§I°2ì„A[C‰Î0`Ø)áıiÍÙÑoPò-Âğd¿^ıf·ø÷ØV9LÙ³‡'ôÁ Ÿ«F³¾øLqËdt's’;b¸ïİÙ²ûBû»q»Ö˜uwXÈÈ¥–œÎ{D
cäÌ¥„¬ü½á¬"
ö3çoÌP¸œÁ­ò»È\0—êˆÏGæH¿ÄëÇvŠÎÅõ4<‹ÉY•,vS“EÍp©1f‹.ªkNx.ù+yü@ğÌYh!ÕŞ‘KÆ‚OK ÅÚŒ·)éyBşKŒò®'¶T{ÌÈ`HÈªÎWˆx$„‹=l“F¦µiD–hhş,æ6nv
6&‘ûä"æ«ÿú*Îªãml-#[ee›YÛ.)ãXa]YµÃq%°¢æ¤¤âŠúv{wO®¦zõ=§…ihà{Ú„²•7›ö9ÊÜ¤O‘Øw‡»Ëq¡Åê)LBéòö±áLë`4¸"xéyRÎ9’PyÑS–œ½v¡…§7M0¤J‡óşdÌ§Ï¹	ÅDd`9½nå‰ä\ˆé¦"ŸÆÜù–òÛŞï±!Ğ—#C)ö"{µviçæ+Ñ²BÂGõû}šÀ“XÈ¨é¤@ÔÑãc‹îê-=âÌ;sfZ	óª=ß-‘—Í+‘Ù…a¿›ĞË­UO	}²£s$äãrÖ^ˆ7`aGÂIı§‚Êaš’cO/@ÀOSPöS
‚ãáPÅ¤=9äÔ;PÙB¤¨÷MÄWDÅ„"l$¤)»JS‰%‰ jH,âä’,DA& yFÑbVtdQ8ÒV(€$§yÈğÕ97(5ÔòÆúK‹ë;*Q^a3Ìœ*×h:E`Ÿßt‘…7²£§·‘¥£@µş± ™ƒè§@(Un¥ŒÉŸë…îßrI6~Ğ]²İ<is(íff¡°}–uä°ñ©à,P+ycÄˆsUñˆƒó¡ë.0ƒ:eBé_âŠ:”+]IM,ÁÑA­yPı³—ù\Û_Ì_™¨L?f.mVĞ*™Ô¾‡Éºµ÷ë?‹-„Œhè4Â‡Áæ¶Úlíc‹s£†$ô0ïƒŸ`šã)œ<&D<Õ(+³1d †$¤Ó|w½»Ú]Í@dM]0·¨@u²Ê°d«¯W—\]®Y™uÂÔ¥ÅÏ‘ÎŒbge+ÃXË(ÃDÙ3É˜9ªûx®%õ9Ã>.®B´7¬Ó\H¬{‡£R¨±T´|ãìgÅZV&ç‡Ïìm&g	
ØÀ™^O0ãË™Ğ4å”¡;‰ï7IıM¡fpÎ^®„£Ì5;,‘&¿càÿoĞÃäƒ7¸~Ëè¯#
ş¾ôEdú°­ìOAî¦:4ÏÛİ!+µÒh`Ò›l{çõ$>î‡¤÷F÷wì¿½øœeŠAæwp9
³•?\eÌ²d~h$²h¨b`hÇ:]²ï±Õ¼†E©ä‚§€‰Ÿ|îjá{¥zñH-Ş19eK’{º±²ô{är"Ö3«Åìjpî»ó¢RÉºÏ*ÊQ·+YÖŸj6øNC>s{q·¬dkaëë¬Ø¥›Ôm,Á%Ûì¬U¹2wY–D)|¥¤ŞLaÆ‰µ¶jÄ¨÷fl•f÷ä&o›pgŠdf|Ê[ØG¾Ä`Gb•-0××´µ¯È=³'Ù2x|~mÚÍc•¨—9ëâ%Ä.½‹&’%7Gú¢ĞRÀºI$œ<À×ªoƒş”Å”*Á[5UÖ30Ä²(X‹WU…Y°QÌô¹ÒõvÆ³ªLcÿpo÷ÍîQwûÍZ;îì´à ]	`R›1åZ€şœ‘pQ%qSÉ8†©[Ó9%®Îb¡¨Ä§!¬Ä>ÃFÛOp}†ÿ}m[TÓ¶TÄÇ´|n^ji¡<İ†A42F¸çÜÿÈ•‡\óXòñò;_ao+šòA4Ï%Trê8—jOT å@#H¢ i(::Ô ĞTÉ	ıî}È±ºæı9€TÙr:gµİîc-1RO:‰¥–rÆî”Û›¼’­È¹ëö‚Y&aÙÈ?ŒÓÉY¶°5¸6†Ïw…ÿ\'ÈTÔ‰Â/ÿíÙ“'%øÏø¼QˆÿÖ¼ÿvÿ|müç²xo='Š3÷‰Fq–{’ó)x«{ Şœ½0|êÑE³İ$d¯Ÿ&>œ(ûVãÒj„Æ!iÇ£Ô7®é¨qArG¨ĞŒ‚,ÍOºY}®}!Ùƒyœ„"O`­{s°Ønîı"eÁGT?áËî·íÎ÷ôøŸI^Æœ¥)j&ˆ„·üZø3FÀÃ"¦GS´Ñ—ÿÖ‚`!Z€4 áÂ€!8¯ä‚2Ò&«û‚Dó	êúYlm‰Ú#ñƒaÚh4ã ÎAâ©}‹¦X384Ôj2;—j,L7I2.µ·¢Œ¥Â|¿xÚµrÔ×/…ó¨rf¬ÿDà}s2Iïÿmõéê“ş?l÷ëÿıúSüÿ'.üÿ£÷!ÆæÎFú‚1 œ;‰µc\ Pâ\zG!?©7ñ NÂdèÉSúàÜT]>	¿on®¯—Õ‡íıívkï€?­Â·õì[çø5œ>¿ŞŞÁÏúõ»ÖWíİ#™¥™%Wf&ºÇ·®E“’mX	·ÿ~¼§	ldïÙ`EV^{™ê‹0i1SáÒÒ:Š²3¹‰2LaŞèî/cÚ\©c)±1Lq%éäĞ3„#%Í`ĞŠ”-¥YV•Ï¶¬€äá”Ï§âÿ)düO¤İ°Ç`gËJ{{÷ïbç úîõnëİQ‹œ§Î£\€#«gXM§l2´ûB£Suàw;_uw¶¶»;»íÎ–ş…Y_ÌPŒ¾çTqø4Ís¿mí½A^<ô– ëå°ılÏN§nÄîîŠ29™Æ—aBĞ ;Á(
â` «U”ˆñğS@)½kÀJ›Îá!•}2y$aªÿDÉğÅ1aØŠæÓúê†Ø;ê><Ïà{ê}ÉğÑù–¨CËwZ¯w·ßuß¶`¼ÛÙòÏG7B}–h*xa€…kZoåe¢ñÖÆ»µjfÙÛ}-±Y ¿ÿ*![ßµrïĞåËgãŞ²™ÂcN©@Jü)KYÀR…Ê¢RBita~˜Äc˜–ûç(W&5ôkÚiu¾9:8\ñ¶º‡GFå,¼9ŸlŞGá¤Ş›õéÙpÒ–Ô@¢[o®=÷xv&¹&ÀUÖ[MOsÙ€¿ÕÉnê.6ÃÃMÓ–:× :×ûÄ¢yÁARßsºÇ=­7ëMóù®Í¬}Ç$½öœ_”A{­x3ñ®f~VPkœÈ	é¤	(‘±ò<š¼ŸCu‚™P¤9’ëTâ7Œº€'§NŞ²a9ìtİİ–J5#¨:ñã5ÈgğâC-•z7|aK™œù¾éÀ¼´(µÜ	/h:LâÃŞmğ+š,îÆ8QÓqĞÍ6Àb¡°Ÿ­Û²ßzwÜİ=jí[éİûK#ãm]&§©º\"|OZĞëµQo®âÖc¿—×G[ËüyÙ3<Ú-ÎŸ“ûo­úÉ™ÎÉºÀ–ßDjÏ¬—º$ş¶ì9AğŞö«[D50ı·ükg-0bÍaÜ)Ü©ÎÌô½vk{¨ò"a•SOÂ` ‰IÇüŒQÊDÒÒœJ¢Ó)Š9=F-¥…'çwûï¢9qc“İêã 6A”¶|j­»Ú}šÿl,uõÕzñsaåI/Fõ³$ÇA
³€Ú¯²Æ$8O›QİùpNŞ€M]ä­ıÉs±¤yH>ªxYKÒ–âN³ûœlÑ,v­å_l ÄT¤¤¹ˆ›õçu¢„]S”Ó³¯­ao¦:¶:îv{_Ë/æ°Lp¼ljŠwœô ±¢ßK÷¥-4==èè_ÒLŸäZŸdŸöş×o}<§á,LÂdxñ,ğ…gÛ­·»ßm¡€½§e£j˜ŞY¹…ëÆ iÕ¯¤>ÀuvA²¡5ıZ`ÙB'‘~¿6æ¹ùCJâèÂáë–´ÉÙX¾â7º_Œ?¦h4’«_¡Õ8Ä€kcEí¤4 nÙû[U–?³TüâFş’õÅèyÒ#LÆÒ£_¿«:õzÏİÛg&¬•vë«Öwâ¯Ûí]\;:÷m»kí÷>¾±Îçğ
ÿåõ¯s¸·{tÔÚ	ÓŞ²ú‰VÄÆI£!>¯pÂÎQ–s›(æ°%D§›ÍZ?¼ Aìô|òV(ı„ãqôñtzf¼ìQ¯©_0GÎãföõã$¨ç`òÁørş¾WS%á®q>˜NÖ³'zï{¨ú–?GS„Véôô‚µrb|w/ˆºˆ˜º¯³¿ıt”‰v]gÁ>èŸŠsøŸp /¶â¹âÑ2RüZda…Ğ Á‡·B»ì@9™¾ˆÔwó¤Ş!@ŒâQÛëKb54y¿%‚°Hÿıú _4qè¡+ˆ]î£Ûâh†Ø·Û»G[kèâCW2ñ™´âğH§ëdlz…1à_°
Â¾z8SßÉ$ÿ.Ó½|ÀXúCæF:¹Öçïãqîe>NœşúB©@²v¹Y3ÿÈûtÖ¡¡SŸ.z ÿòªb“¸Öæ­Ui…"ÚÓ‘öºCó	©úåó‹3nÀÊÊ;ŠÅÓt¢ml¨Ø3eE!tª´Ñ«Ò©I\Ñ UÕ&ìÊüÚĞíÜlFCmX¦À†kAªÔ‚ôùö¯¬”6]š>Œ)¥ƒbyjĞLUÔYÍ€FètÌÏç×gÑœQØÁ s˜ã¢çÿ ùÜ`Xî*/rS%_Q˜xÆ¼sßŸêÙøõAçÈH-ïUõçwÇû¯[íü\M¼^„™Y¨ÉW·px]­7ŸÖ›ª0Ô•É†NFY[ŞÅ,ÃŒMÿå?Äë+í—ŠÃ[öÛ…_÷	ßOSºÈëE$ïu¢ThVx;a×Ö½^O•[zÿâö/ÿ»g˜
ÃØĞÇáÊÌN“o°Psº“–jkl‹ˆ*eáWõî€çµ;¹°.52òÅï½Çë©œ¤šLî°apÕ6êjŒ“7eŒ#—©éP=Pr; ”ágçøu–âëT³İ¹•IûfMäÓ‰İÌyM4O©sNIËwxLR§a<WñïU'ktıKís3ù!ó§(*ö-Œğ¹jmtš£Ş{”´£ c¯ã)»@Ì­÷ço%Wü±õ]ëMùWÃOdË2Yªõ”ëI‘ 9”lùFİ³VÀ*ÙZ{ÿXÄA-st‚2©tckyíYtƒ%a=—Ÿ>íu¶šMK@dâ|ÉUP+nÔ7P]¾bK”GùÔ†î´ˆOhU2/sTè2Ì¹¬Ç™jÁXë£p“‹¸ZyDÑ¼Òòk«t[ÿÃşÓøw§õÚøJ
«†¼ºéR¬ÛZ³KiQª^wQ4ºNpÑkFÑ(™×şş…ö†ı¶:¿[ûO4öyZ°ÿ|Ò¼·ÿ¹·ÿ™cÿsc c¨ßÌˆmÁS	“râ1wŠpt%ñˆÑÄ”,2îÄ$ˆ/Áä%ø÷èVå‰ÕY?•~ûC~UxôÙóxIVù®l–-¡¿HîGµmh±GÉ£DğdÑÔ–” ÒZØÇ»ëEó’äÇšJY WéZ2òA'VŸx‰1I®LˆÑÂØ«?Eã- SúmçNUû·òß¦·]„hÔHl·¨¬
ı–T—KK•&½ÉİSAÒ5ó=ƒpQY§·V}!íFpŞ!¦©?ÿò_TºÂûg`¤ã:æLAkMÓ­·ûn?D³×>gÌøŞÎl£ìøU3£_D$£/0.êõº°ÓJ?NQK.ì/Ü#YŠ­1nùî¼a@e^¦K[œ§[«Vò(‘ø¡ 1TqØ´ÁñœÒ2F–y2W|Ôße Ç3¬ïp^sØË{G6á’°iì.#¤ä…ÿ^Î†ˆ#ôC(õˆknqÂrüÓq\Pšs5×¶âáãE‘Uå0oÔŸ\BıÃÃ-Ó9]‘úÜ{ŸJ$ã¥[8é@`*8‹…oß7X¾yƒ‘¨¥gEGÁ\ØaÓ2ÖPÖd•¡¯R q!µÈ^X.ÍfULS®ì° P5¸œNºÈŸ¢{sÂ9¯
0#•Z›tÁ õx$ÇAöCÃ±5†>‚—<•ÿÕR…Ös²`a uÒZe*Tk†b0uÇU&†U·f,jÄ~bÂt^ÈÍDŸ]0{†à©gG#‰ã‰¾^·c'´@‡X¢˜ =ğKâÌ‚õv^ŞÑpÎVÍœ.Ü¡s©xÔLËõCš} bÍğ\•!ªjÕäAPå_›Y+LM$!~Ø Œ üúûyôO`OOÈŸ3	LgÙ’ëYØpæ	&›#v`¯@‡ıdªL!^ıqM¶ )ÔVfºO¹dgŠY­ÅÄiDß´ï4:{6”ƒØbÅÉ¨»"Yê2g®ı³¬2«e–˜FoºÜ¸‹Şİ6~‡ã²*çm]ÀE–ĞœÙö¨X§
²õÂJšÇ£¹{adt}&Ò$ú~*íÿöªCƒ´Ÿòm^<øŸdûFû>Å…§ |ƒá°4UZŸ´·¯çòğßÌóó[˜F£åJanÎn¢ÕB]÷7Rd;¶ró/¸/oêöc•·¿Éx–÷/¾ËIÂoRÒ"ûä¿´Ä¾ZåÒ—¨>I[ÚâßÎ¡­Æ³şq¥ã.äb=)Tæ°-L)hP5tô*Õ
’A„†ñ||Ni‚È•ë¡¼Ï–f+ğ'BÄ÷uÌãÑ[\ÅÑkÂË6í§°;üü³úõ,« X×‘ÆÅf.ùºLÄI–Ì'S<‘)pÓÌ
~.ªk¢º!ªOó¨øÜ;16Ex
z¡ÓÆaÚ™À8‡½Ó $tåt6Ğ±:ÂÃïÎ<í„Õ1ÆÁÂõÈ£Èua=‚
ú²(ğÜBJ§bÇ íÛ÷e¶k‚Ì°¹	¢‚¯o7©$íO‘{Š©œæ8fv¡2mÎGe’2vÚÂ~vLyO/™öâzs’$/QC±Æ&qÉÕR-À¹Zš
±ëéª€ ‘_K‹iéjê\NåšİÜt`ØwÔ’‹Ó‚Øb› &åˆóvÂlœ‘1€5r»"oDöà5Rï£(‹(tùâŠ¡äÑFè6°AÃÍYví—Ckr QÍn‹êè
kBB‚•¢ºW–è|Eåğ‹5«¥TµY3$	'è GCõAõÏ~Š¨i£ğ¡c.‚¬“°fÊÈ€¯ßxr»
9%+‰¾C¬4¦«Ş2J’ê”há¯k‰Õ&O´L
9
Ùë°òwGPiXP<ÀCT,Ğbi[aˆİ0zŞïOÿ_oôã^Úø¢eÌÁÿÀ?¹ûŸfşOîïîªÿaooüúÿÙÆ³ûş¿ãş7m¹î²ÿ×W×›ùûßõµûûß;éÿ/9Çhq'c¤~ôµí)ÿ\øx­*¶§ç¢ùÜä‘Ç7ŸÄF•jHÇÇóĞ÷ê¯Å»íı–gÛ	è¤“8g¹JY:»ï;»Ï®Íiâ((˜ıû“³×¬6:9kÿ@?ñgcáå€S\‰œi˜.¥ÉeAŸëã¯@J+ËªZºV'µ‹oXP´Şg‡-ëµq6±Ş“i)5x·Óê¼iïRe=ËíuŒôA4â ŒÑ‡Pl=Æ¾@ä¢!–ò¦•õ¥7kÔ†2=Æ´™ÚœÊ¬iu‚2‰Ü'Çñ-	ÇŠJşz9~	)Üi…{I‰%÷½+…XÒÉ¡F¦6u“ÏrÍ6(6óJæ
*Š,yIe¯ÍdV—aÚóo3÷ç‰êPÈõ—‚I·>ËÍ²èD¦E71Œ5óŠmö•œÿáçŸ¿—	~ªJiX#yë£šF|ÁÃê=\è­´¦¦Ië`×du˜×1–Ãš§œ8NyÄA%ä;¬WS äB0ºä.•¿¹)úa®~y/Âñ‘-¥`¿Âµ‡¸5PÀç\WVV]œ)íÚÊ|Ô0xÙñvÙôÄU0¦hn™dÕDÍ@@ÍÃ¤¤çèvóX¤.v%€&½”æÏ‰H1†Æh¶}}Ğöò°ûô¢w›ÿö>À±p€îé+÷?îÿüwø#å?ÛZ˜Ö‡ı;ÄÿZ]_/àm¬oÜã?ŞıŸdÕæq Ğı"õÈèDC{06™NãéDŒÂKq²‡Ã]ø„C2´®{Şæ<pĞ›Ä§aòXYz ¼¿ò–^¦“$¿z×ú¶óâeCş‚÷Óü½ôr½ÚÅÛ¨ş´‡ªÎ€JÓ¶_â…x_Yèw°®NÇõôıË|yÙ ’Î¶q¿’.zä¥SŒxÛÂ¢Š+fj¦;¥í•w\c)'ñÉ@Õd„\—Y_6°æ/Ğ8nü4¾İÄX»áxOQŠ.ãÂÛİïZ;%lØ&ëm)ÓÇ,m)_Hç(G4ÿtn#F?P©¯š¬PÂyÄ[<µ(¹N¬=w%b"ò‹l;o¦ú‚D@¼ŠÇáHİŸ§ XÆCA‘–ä5óth¿3vMJ=‚ÀC8	-5IÉ—Gm”î‡9V¸ê’vú¾5„€™XÅ°¡BÄ{3’8Õû(qæù]ìÑ¦Ñ£7îP ój±bÖ{ä­vø€’(©3{Ìœ$¹¦bim·÷/5d_/”æÈg¼5óËüoövÅ>†õ8ÓüTG¾[ªxæ¿tÚÉ\ÛÚeÑÑ×Èmâ³ÙÑ®~¦Ôm¾RbÊ§‚ä
D:nÏ×XX…Ú®@N6FÂÂCá˜oÂ¨±@ÿ‡Uõ°!`©3áÊY¹ÛpN|Ã@&)ÑÇÉŞ€_ÑGq<Òº$€~‘êë0B§«s—BXÉ°¸ÒŞ‹q· ÿ»m©oaùocıÙ³œü·¶¾z¯ÿ»“?ıqtš7Í¿Mqças…_
Cñ'ŠyŠ[r¥R	.’QäÊôÈó=B5"<áZ'=§_“Pÿìãù5£¢Ñ "¼Ä>z¤óÊ¡1—}$}‹ZYï¢Â²/R“}šYÚó‰,§V¹Õ1>ËÓü˜ÿ¦vÕbkLk‘
†&ÈMõkÅfåºËĞuÚ=&ÿÜ¦ş3§ %±á·¨@U¤2nşˆ+ï9!,é·9.ÉA²x	ùÎ7Ó”([gÊ”E J	Zã¢ˆ²éfË8†¦™(ÑØ–QraN3C+$4¥Ê-ÕåŠ•’‘o©w¯»Z	·
ØlšRÍ3XHÊÚì“Tg	ğŒÉ{vU´¶Ø~­ôÆ³Ò+…ÍD‘­¤’Ï?¥tVM”3Ü²şÙ=ä:Ì£2ÎÎc¡¥².kÉìÜ¥íWm÷hE73ùúŠn©é–ªîyºn.—UÒwC¡²FN<gqròŒD8dìÏ´†J¾[<Ì‘ÿ×VŸåïÿŸ¬İÇ¸+ıïÁ„fu=ìÊÿk&¨&¥Z8M^!8RÚ•|CÜï†aÈóñ,âK<³'@-’Ô`Ù2@,ˆÉÕ8Üòw}¥8@ìÒÄ	…U<$IC›©¯@¢töqmxˆ÷IxæWæÉ®æ:MõF¶äÔ´º¡q:ˆOáì4“F»µ½³ß‚aï¿RË¿Ò«ÜËFğŠ,½ã³³¨‰«Ìöºn©§¤WN4ˆ&W¬ƒ¤æjäQs& Î°Î†u2!Áå_)´Ÿ—ÎƒŒ"Âü‡£¿ì|ó\l›h_²Ö¨¸‘Øİ°¡ÆU®?ö?Ô×àomùo‘Dİİ!ëî:ä»·(mŒ¥ª(şòâ—XdI·#ë‹"z¢ˆØl}ÀÃ ;èAô $Hde—ÛIz…QYÍ•6	â{_R="KQ½ÀÜ»“åÔÚÒÓx€>éºDv\¶½Ih -‚§¦øR«úôƒ±!7uS'P( ;½“®LşÓ‘J<¼~ÑÑ*3=6šzÖêT= B
^ RpÒ'Pƒ81SôH}`©¨3"G¤·,KÍ5”û«¸¿¾ÿsÿçşÏıŸÿäş?ÿVÔß h 