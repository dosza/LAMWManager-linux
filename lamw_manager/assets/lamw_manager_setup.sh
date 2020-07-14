#!/bin/sh
# This script was generated using Makeself 2.3.0

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1214482643"
MD5="2f2dc8d15eacb323ca3ffad99161b08a"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21300"
keep="y"
nooverwrite="n"
quiet="n"

print_cmd_arg=""
if type printf > /dev/null; then
    print_cmd="printf"
elif test -x /usr/ucb/echo; then
    print_cmd="/usr/ucb/echo"
else
    print_cmd="echo"
fi

unset CDPATH

MS_Printf()
{
    $print_cmd $print_cmd_arg "$1"
}

MS_PrintLicense()
{
  if test x"$licensetxt" != x; then
    echo "$licensetxt"
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
}

MS_diskspace()
{
	(
	if test -d /usr/xpg4/bin; then
		PATH=/usr/xpg4/bin:$PATH
	fi
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
${helpheader}Makeself version 2.3.0
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
  --noexec              Do not run embedded script
  --keep                Do not erase target directory after running
			the embedded script
  --noprogress          Do not show the progress during the decompression
  --nox11               Do not spawn an xterm
  --nochown             Do not give the extracted files to the current user
  --target dir          Extract directly to a target directory
                        directory path can be either absolute or relative
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

    if test x"$quiet" = xn; then
		MS_Printf "Verifying archive integrity..."
    fi
    offset=`head -n 526 "$1" | wc -c | tr -d " "`
    verb=$2
    i=1
    for s in $filesizes
    do
		crc=`echo $CRCsum | cut -d" " -f$i`
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
		tar $1vf - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
    else

		tar $1f - 2>&1 || { echo Extraction failed. > /dev/tty; kill -15 $$; }
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
    --info)
	echo Identification: "$label"
	echo Target directory: "$targetdir"
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Tue Jul 14 17:38:26 -03 2020
	echo Built with Makeself version 2.3.0 on 
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
	echo OLDUSIZE=140
	echo OLDSKIP=527
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
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
	for s in $filesizes
	do
	    MS_dd "$0" $offset $s | eval "xz -d" | UnTAR t
	    offset=`expr $offset + $s`
	done
	exit 0
	;;
	--tar)
	offset=`head -n 526 "$0" | wc -c | tr -d " "`
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
	targetdir=${2:-.}
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
    tmpdir=$TMPROOT/makeself.$RANDOM.`date +"%y%m%d%H%M%S"`.$$
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
    mkdir $dashp $tmpdir || {
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
offset=`head -n 526 "$0" | wc -c | tr -d " "`

if test x"$verbose" = xy; then
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
	read yn
	if test x"$yn" = xn; then
		eval $finish; exit 1
	fi
fi

if test x"$quiet" = xn; then
	MS_Printf "Uncompressing $label"
fi
res=3
if test x"$keep" = xn; then
    trap 'echo Signal caught, cleaning up >&2; cd $TMPROOT; /bin/rm -rf $tmpdir; eval $finish; exit 15' 1 2 3 15
fi

leftspace=`MS_diskspace $tmpdir`
if test -n "$leftspace"; then
    if test "$leftspace" -lt 140; then
        echo
        echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
        if test x"$keep" = xn; then
            echo "Consider setting TMPDIR to a directory with more free space."
        fi
        eval $finish; exit 1
    fi
fi

for s in $filesizes
do
    if MS_dd_Progress "$0" $offset $s | eval "xz -d" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
		if test x"$ownership" = xy; then
			(PATH=/usr/xpg4/bin:$PATH; cd "$tmpdir"; chown -R `id -u` .;  chgrp -R `id -g` .)
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
    cd $TMPROOT
    /bin/rm -rf $tmpdir
fi
eval $finish; exit $res
ı7zXZ  æÖ´F !   ÏXÌá·ÿRñ] ¼}•ÀJFœÄÿ.»á_jçÊ7¸mtr­£	ğÅBE( ËÙ>ş<ÂSi
 «r¬ô'hLUÕCnî$\ts¶ûelsW÷g˜é>©½Vñ¾F#ĞJûPÒ>ñ"Q:hş’E¹ğ^ŞŠ DB%ŸZöøe=ıö>QãÚ!§ZÔ¼æ•æ]ÖÂ¬1V'Q™Xuâx»ËvŞÀdšÕ½4òO·º”SŞ¡'914úŸÎ)uQ˜£„VÌ²Aµ>iöó²ÔÙœ#Æ=•)á\™ªŸ1ä2À~}Ï™‘€Š#1=“¶èƒ‘oŒıwŸc”f¿
Kƒÿ}NÔ(í†¸8;©ŞPÚ¸ª©*øŒm~ø¿ÌQaİ"EiA78¥ÏPRÇÛ2FÄ°7Fyá¤‹¤Î˜›sP)z/ÓS¦£–~7ªªïÑ°ÇdO¦î=àeî0Ä<«Ì§l½Ş‚ÏoÃ7
 irÙW™¾ö.p6×–KØ>ÒHı~Âqü]:~ Bdğ¥Sáé7b,O+™”ºQ |j«HØõ¢¦'ß§%–q
£Å­ipêKÉ‹Q%H%½=nIk¡tçaW/69¢È,Ôáß»©·n_.ÄÀó¦h.Å¤fƒ×?ì{º*Á}FuF|X±Ä´ËµD56dÓèV)1Âp®#İ*Ç-™àépLƒÂäˆßõ6zõ
ôés±–'jïkêümRŠc}ËK›
±70ãù««)QHòı‹ñ”ì\€]uôr4Ñh^ëA[‹¶DPø7D:QP]÷ ıÊSÊ2)T.W€b&Ùz‡—¼ÿ-%{ŞBVÆ3>Ø–şÉ äJñ…ˆi&Ù‰VóârûZÉ;[¾S‡­ìÚÄÒÚ”íxãÔ "aOıâ´0ŞƒSOKk$dŠ®k×â™Ò­ù_ ´µ*«ÛzÊ!ï¸k3dpÙ¤XŸb•şyÿÂ6İFq¯‹»jòÄµúF¼FJ¾¨pBm¼Øî˜ç’Åt«¸2	)®Hìf‡‹÷g
Ï
o |ûÓ¨óÆ@ÒQ0`ıÒ}®½J°Y†ZD÷«C›ÁZšæŒZ­s›X‘{†½y«QÓfœäÔaYØÎµ6ÙÊ ^× ¨ğèº•à;_Tk¦ğ.mĞÒ¤ä½ÑT×èêò°õê#ÎÂ’ßŸ,Ô» d.«÷ª”8/û™öŠX{ÂVÇV6•W~¯ä)ƒKvŞ³K…¨äB\—‰n$ô–fÁã‚l“ˆa›½KEX·R"Éƒ-œX9>°ª—¡jD,ÒÍD“¤„ğÄ¾à¡•×fı^-’ u—é=ÈîcUÎ5î¦ê*œúîÙº½ËåÇºêôxÌ8ı3p‹I¤h×ÖB’ 7éJ7ÖOaÓV˜—“avª§DÓvBM§¹kœ	¦kÁï&ş¹ÈYx'ªjl{CÜ‘SS6Öê[šœ(Œ6·#"½Ê$Ó‹¿qŸˆµÄJ­xÕÅIâKµ½LæŸÑÅ~ße·ØÂ¼¼+ê M¦Ç^ê:‹Èä4ìB ¾4£?áG*ÑÜœ2í<Ë•#¨rCE†iÇ4#|·ÓšIÓœ^Y’#$¿¢£Eí¤‘“º(2Ùã!V B(çÌ%×O&}&à×£•Mû@«o¼Y+äßÒ1[ğ%5¥{!O3‘Ö¤oi•Fáğ´¾îš<UÔôò¤+ØÂs£TSĞÛ|Ò‹1kë¤vGV€EÏŒõ““Ü^y‚r#|mKV¢ƒÁĞàRF7¿£¥>yÈqï‚õòE•|ğpÊÒ¶œ!ŒŠ‚V¦\;ıMG¾§{Ê÷P¯ÆA¦+|2ì¢1E&şÑX?Áæ^ùî
mOÉI¨éVÖcÇx ¬I½÷¶S2ÄŸ('ñšw;ŠOƒ!€}ÍÖ«3¹-ÁQ
'*Ê •§BäŒ÷Ú,nV£_c&¢âşüZYWa¸Tq@î*áî
¦5#ê’ÖÕ¹°³S5ØhÙleòa]ÿÔ°TäˆÇé8ÆOñÛ¤D>Î¾G¦gSzßñKWŠSõÿ-v>Ø´ªÆ…@C@!ØşÈUeÔŒ:i*Ë$vzÓ™‚Ññû–&<˜ì4ïl@£›ÏË@¼V:£Ë—mõ>E@Ïlîü®ã	Í0Óíë Ko"VÊ„½xÚRÔÚù,Ê<ã5§ô¥r]Ö#+2©ñ?DÂ2=ÜôÄp	GÎ¶k¡å¢ŒM7>Ìç“ÿ%2Çw\‰!º„a-gï²¿6¯Rn£d–KĞˆIİQÈWJ±n©ó47Ô¬„@†Ã¿¸„]Úğa•K¼û ä”İíİÈ!oÍÂà\Ï—ıbU’gÒÊ±£­û©ÿ³JtÜ÷¨5•¥ê4ª²âÆ¼#j“æ5¦š¢AIW*uÊ62 ¡2ÆĞÁq@‹Úßı°`TŸ@†óyUK¦>£}×°¢÷9x-ô.YÚ–ú4¼X¤`.ŞÄ—àÌí«œÈkô¯ì?ïù`ğ¿0‚zœ’%9w?¸tJm´èÆ<ƒsb)ê9V¡Ï³nç›
¾¾ò¦¢X¥©~MúG¯6y"Œî,âTŞã·à’üLş&>,®9,úÑÑOÓtˆŒé,2‹û,¼ü<ê·f·ş»ÁÎmr$îÌŸšT…ıêd[*Ğ±ıt	±]Íz½±)ó¯M\UÑlÿ)Äö·_ÓÜœÇÇÛ®nN@é È–*Ó’j«ÈjĞ?9â¤y Xñ+=“ ^hØú@RJ
·µ‘´ÏóLåÿvrÎògå†ZOi[ğ¤*´«
6Éª×¾{øÆÏˆ!‘èååÕV-¾Ç€ŸÆHl?¢8s!&Û¤:äz
M$q"å3ÒTê/X¨·Jı9ùy”Ê*§®s2Á¶E$æ; H€Õ—_odp išt}BÀèÔ|“J®ÍæúºµQ¸Jå¡°%w,'ïçJ¤+<‹=4hüvFàÚ“Dqâö¢Ô¨£Œóé‡µıJŒ‰ğ KúOP/¯{5°D¿¡ô7¦/#ûËZPQr{jè~˜]®ÊúEb¦º
…ç€7^ùØ>…òÏŞüğã2PÁmAu^/HnÉÓ «İ&*=£û‡uîÄp_‚nåP³¢½—¦ıõñŞãLŞŒwŒ‡´}¡ğ>_N
B±MJæKfšmlÅ°”ÛüDPÕ³Îöé(n¸D·wTk…rÈ¾Pı[0^~"¯Ì@`AÈ5®.×sçf$ì%â@Gá¡ÿ‹h?¦-Ejáø¤)õ´»%HÑ3ÔîvÆzOö¬©Wòİm˜S$]Zæ_¶.n@C6‚GA!44‰ë:}'­j°n½
¼xZ2ÚúËIqsDQ÷rù{wÄ{xV‰5W]·ğÏmç¤su…Õä‰O±¨xL¼A¸p/µ&(XÃb`ç†İÙTWbÑšiÎ”Á¢Û ãka?.3Ñ¤á^´pLøŒÅÇ5½±õÍ™n¸ÇüçRhÃ-H„*€{„FbØ¼xÅ?ÉmÚ ·âÚ$kØî“(v€áxÒ\3ÿE<<uBñ^º4Ô\Ãêtıë—ëü¶Ş|Ã #O¾E%y0®ê¡M¨ÃçòRd»FÇ…¤ì‘?™Œ´185ZÉeÚ):0œ#yµÑ%Æ@5J.Mïø1¿Æp¢À°ŠÑ½N“ê¤Pˆ.²uLB3c²Ü´ˆ¹úVC¾ve>³^]EƒÑDDu4s5å¿	TÕqNÔ4ô=£›ÃOÒ)í9ÉşFí§NÛîYé8ÍU±Y&£k/GSLŒ9D´¶#"ˆËä„‚²T7eEÃŒ’Éã¡Ñ„­ôXQ…iø¡s1nCôTÄ˜²ˆOAJÎĞvvë5f]šÄ°{üí›%®Ø~Ü/¼DX¯ÁÉ6>Cmo1 Ó8L <L¤>Z¹ÙiqîrÈC6\æ%y^Ë3?Ät]Ë]Œ¹çUÈ%Î03`¦íŒ¢ùÛ‚Á½gß:m î>Œ—jşğ Æ^òcFÏÎÕç£¼q«eş¸·Vw˜â3ğ‚g¦·<F ¦5“=0Œ‘‹B¼÷qÀ÷ŠHç×NvØ½+ò¦¾LkÆKşïXm 9ÏAU?õQşCùÆ·/„ª§TP÷…ì6I	GÙZÒM…Ù¨œ6Z¼ˆòNI®ˆßòq¥…^¼OÏ–bó+öTk4<ø±•§]ôMŸx¬óª×‚KÆã ¶æ¿£ù›È‚cÊ:1|.“Ğ?–'’£ ™&Ê«ÌH¢Áíà%‚Â·¾»9òÊßÔ»~e8ÂB^|#UúEz=-ı„^Ö'ùÑS¶ÈmxÎ%5ÅeıÑƒµEnñS~ÙYQ›Z,=	/Vd¶Äv¯Ïë>…!kã^·s«™Îx!99g®âf¼Ò^pé	B’J£ +¡„úêØ'W<MÛ×4yŸT¤©+}o3.Ù³?’êì6kDÊ›sp¾Ù<0#ïàJë§AeÆR!	¾ñ²3Ëõ‘íÔÃ˜éˆ®1ğ0&O-}Ÿ°Ñ# >c‘!rcÌNÍ½-Ì€14VIíN´ïÃš¾ Ù—¤Tixá2ûµWAC9Áã™?ÕX
ö$ĞƒúzÃp„2.[Î*)”1ñJ“K4hóµ+ù|ë˜ê øÒ¢ˆrïœÖÅšœ|"võÄHoD¹¶ôœ¼K·ıÈ%Ã9şš*LlØ\Ñ5äò2?ŞsRQ6P~LvjâÅİ!C+×#bØøI¦ŸSí=÷¸1'[Š*$ù‹Æã!?÷õÚ‘Éÿ'"ĞÅ•/MÌoš;U\ˆµ	›W	ğJ‡áleí{y»zËXå•Ìon]l/Ôó’´ÓÙ{ÑBYbxOñ<±ã,&Œh#qÎ‘K…íùÑÃ*k©Ä¢+zÇ;üÓ×åg’Z`Ñˆ¬Z”|¹ ØTövú½üâsûy°RMç °±Wó‚2Lèš¸ç9Ì/=èC³çacÕ71GÏu'¿
%oÃoúÛŸ€"­6ÑÓ‹Ğã¸p»%?f­ŞºÊâú‰·Â3œ¤ÙÙbôËõYªÍ ö;_¸w ¤YV0Ã€hİåÇy5@HÇ.¶˜ÉÍ]+©ïm{É6³’Z}sKŒUá©R	vÄ¨>ÎÈ»' pM¥7ßQöõÂ§.
zÊO<9×ßú9Ü_Ù:ÓüğÕëô·vNÿ¬5Á¬¼X	"ÜºÙvD…ÇŸ[¿…::§Ãi-¢A½†‚Cù¼¡s m ¹­h‚ƒ®we­ø˜Tœªã5å‚äL`z±ïorÑjj«YªØÕ	ËiÏX¶÷$¶6­Å³×0q?FrĞ¨4=5&r¸êÍy¿,×Ø8-<©…ÌcSgN·Y ¡5m%Èà¤îúıl('èò'äÈ%s£‹©Ùwí\1—AŒÔ~£·u®HrvÇ8'iº.\Ñì/©Á60œÂ2ïKæ=x{éDÃ‰ŠV°{Ô|RIu2‹GŒ^{è˜¡Ÿ°ùCæ %f¨ô™ü¹Æé¥ŞÂµw©ÜDÃ7~¶àtQ(µ¶à [X¶¡•Ó5şØLñ;P6–ûgœŠşGÕËN›ÁçgFŞ±;¨fõmÍÆzÚ-	«epÅ¶`ÕmjcTä˜$âœÎx&¿¶F>teôd£gMw_ÉİC-½U­(CÜ©]PyŠiçÛm3¬”nÇ$jo©µeó·gQXÚ+&IsĞ">
ìc;_Ø¤%ıÕ‚{Ò	|Û„aE‚CDÿÈòæ9D¦2$w&€¾yzùÔĞ¯÷@œŒ®òüÍ³§á‚ˆã‡Á5O§ì’ÃåmğÀY‚	@ÀäœÍ­…©¸š
±Ä.ˆ	w§­GjÇ5Ñ#{íQ^¦üqY%peHMz#ÂŸ¼î.òWÊ	tºsÒ$¤õàæ@s§c›g]NObó'¬‘ì‰I¡ú½µ4†»´>DéMJéD8ˆ´#ñi	õß+€÷}_VÈäj!#`ÿ`O[İÄ3!ô×ó¾Bº9Ìïö™ÄlqrÍïÈ³dû¯ˆ¤=@ÓÎ¥Ãd__E^/FH¹wôÉïŒAµÿG«kş›`G4½Íâ/Yñeºí+¥¤õ¸w"Ó†MB„X±ns…sÈOx«@[B’©Ç²í@Ôıó¹öâ~æÀˆ¬‹ã¥[1n‘Qºç2û &zÊ g‘(³+ñÊ­|ƒÛ¬".z‡kÎËÇüº"ûÃ‹HÇÜ¶ı®††ó™tni#à¿uç{İ«ÂĞ&19÷ª¸¸*Å˜g@	¤ŞxœÇ&³o’×,TlœŞB»Õ†cmİâpUO¸ù7ãÏQã'~lâÛk6µNÖÛ<Ã{Í±|÷[°Ü:Ó—e½…G,53Í-\À–‰ªô¸ú÷r„µNÉ
ür¤X}×
&G7Üş|ö†ƒ—äoÇ4p‡ã+U›¬ª›ƒ+-â°s‹ñmKS®ÀáíD”‹8OÊ–†lØé“®qaE·÷ü•®)>[áö´Ñe¹.K~È¬½ëD‹òv‚-L4~¬š«üÜ¥Îúøû¢wğb²”–šÏ²\9D>Ån%Ô©˜vg¿kÆûyQÊ1¿,?ìgça4dbaz›ÕısŸÿåOÈô9lâ@ÒøıÈ£ğŞUé§ÍFÎŸuÒÌ“È¥ë{©LŞyH>˜æË\ÑÒ@R¤Ê…ÊG´%uª:1óÊ‡ÀGï`×°±‹›—
n*w_—Ûx}AqQU(‹ç£Nÿ~8ÙÑÌÅëÖ^ğ>’g¦¼5³èbK®
ù5@†Ë7PàÅ;\m™ê^õ-áªÊ­±œ0:¿‰²u=*µÁ³ã='Y$Áá/·ƒéÏd}ZÚ¢9¿ÔEN|‰c!ã.·Ë¡FLğ#3©:{“òs=.PZW§ıÛ>]¨KÊ®óQ!¯óÌ­K»?Û“•°VÑ£d†,OıcëKvÔ÷”şòb-åğyøz¦A$Zbû´ÄÿÑÂ®jÚ¸=Gë2.Å˜ïc¦ÆÔ6öÖŸVÉ!.ŸÒˆbùg} ÅëàÊ­ƒÔŸµı-Ç×Ó`n´)è¥%%¦‰™î‚SJÍ’UñŒóT)pÆ¾9,¢œ ej×,šŞÈÓ¦)>¶'Å”FMùMïŸ(Å³OK"Æ®µÚÉŒhßÿ$‘Ş&¾‚4®ò’¹™"ja]×…ˆÏmä²°ód;Ô–ÔTeÏs}ÿ:*SäÉzk^’÷óÃ¶+=<fí&{Ô¿PºÜù…àíğp`*'+«2¡1jnxMƒ·‘‡~\b÷Ò³ÌÂOhšÇ²Y]Ã³¡»wˆÎ÷ßPEÕô™ı£®}‹{Ó8¼ü¼}Ê‡Ê|ô…o&kÙBk†"ÙX^‚wwŞ0ÔhaœdY‹­Òı‰9@æ½¸G¼¹=Dw·j>)dvşKc.å®Uö%S.…Ÿ¼$%.eƒ¥0JeÇé0‰<%ğ%ûá‘s†A/‹2'*°q½ 6qü¤+`t_.æra-,+“”ƒI_>	zé*tó¤\ndA^ÒZ‘¬4¥˜ïFøc=q*ïñÛâÉ¡å/Z±Œ¿Ò^~ê<•ïg‡f€hTD„^Ó>Š;Qz)!Ì¼lú‚K­j¬K<NSv[Ğv¤ì›j8ƒñÔÔ(¸Gœ¤ä™á`g;ajJ¨Ïmµô[:úßY±z¨Œ²Rv½AEPGõXoFWº°ŠšpT(( ãşïõ²¦ï›ÖU®¡-nÀzĞ0s¯6Ó úÊcÔ9Ù–Ù4sÌšŠã¬?pÙğäB-øYMšÈÂkâï(P.ÿ#à÷İ˜ã³å 'Ora6(;¤ ó„ˆÉ\b¦a]!ü0<¼(Dë4sË
pMËÄtĞp8æbn=š¦ágHa~¸KûÖWå5}JüM0 :šx¾2–çùöÒãÂÏF[*¨d8G\ô${I "÷nK±+;ûxchšC½l€“ê4Ï1¹ë‡oHÚ£§šwİìÖ-¯~‹/”tôĞ4Šh°Ø5	,#«aŒ–«AN~JÆôè"Ğä­y¢Ú%‰’KÈ·¬Y—’Ñv•Í¼K®¯&¦œ$³l²•OîÈˆÕUÿ£O¶ã¾H/vr›ÿ›¢,ÿ”âY- ,Pÿ{ÕNÂšv8õŒ'Ô0».
­à+l„ÅHjîW¯¼ûˆÚ¹[CşyÃ9ù›0^q¨˜ZĞÕnxåèÛPó¥èâ×Fİ¿hòà°=i k¯„ï7Ázá“šæ²¨ÃËVÁ»–Z':Â•‘#aÊ×¡há¼Ÿ&FŠWPˆ&¡ôB ¾8Y ¶ÈóKvåì’2ÖK·]D›¡­¬*ÔLóŠ)_"<+Ë3N‡†wØ©L©NwBCÕ7Üu·-×õrxÅyhS7);!®‘ô‘|dü¡ø4z–êOz€$Oç£MF¡Wõ”	áÇ#üõ·~L.Í™™ê—Š„Ã•PY‰ğtfLç¯U5“v\	qb0®;CbnowË|ÕD¿_ ÂŠ[±lÎ oşìòŠñ§‚yæxÎ§üsîÔ£ùF‰o–´"?pŸÔ¬ iÍ2\cóbIÕcddşÅ¿Z•ëô"ædå}U£h›ó£3uâyn{Ïø£ñ‹Ïgç»Ô¤JLä›ÿî¹dì¿mDp»¾:dÃ!ª¶²“<“·ïİŞÙ¼<9¬<ÙŞŠİpŠjœpy’+dŸ'e“U÷EYMÂjõ(LöÕÕÄ1æƒRAñ÷2Hh«e®U%è5õèS¸ÆÔôU0½/ôê–x“êœ„Ğk1Ü!åÇ`äOvÄò%B¨¤yNºõ¨Â7GöâXl³.ig›ô}r€x¿~Tù£ï‘ímŞä,HPw–JayËaäŞáªšåw”ŠË0D;(ÅFŸ*$‡İYiÑ;yşCùµ•¡Ñ±¨}37¤vÿ¿S‘DhñXÎÿç0$Û¢+T´¯à¾\vÓ–8kê—9~×l»PïöQøpb‡Û)òªÆWK8€<–G—g-Hß 7æ÷–ßÕø$¤·íGØ9ßÙüÑ8À`uĞúG¥$MpÒCÉëÿZ‰#\J„Ôœš»#lu+‘’k7öƒ2yDU˜—›r£Ö”Ê@w‚ã	8øı!µ‡ıá©Í±ÔXËDs×wOè@‚ÜÕ³…ÇOtB)ÉTëZ……‡¥¤šsyß²ñVÅ–™Áª±¤ <QU=0ƒºÖç'®%–ôTéi^Îşf¥í7ê€Í†!W-iœO"Â}šš Õ/ÓÈ‡nb¨&b‰5_åˆYÖ¢óI¢
@qxç²¼UÏµuoX¹áE/på'²+Â•dÆ>¹ÕÅ²«èú¨ğ(KäóN‡}“õ,îÏ·n'<òM‚Œ#Ú–ØË%˜½EKa„¯%cb/âdÿÖ(fğwïmijw¬ÌÔ_G%7èzÊß"AsÙúõMpH§ÅcäSšï–\!¹5-
`Ê•.½Ô®:Û&’sªÃ}³37/ 	TûHÒˆ5Db¿gÛX»ÙmŸTíxf†R­,ç?+YB5èMÕwæÖÙï Ï›ÇbŠ‘-â¦Ua;ó°0¸Ğ|•zÈü‚}OŸ—‹BcO —”57º_#ºA'Z
q<ŸƒöI­HóøÕ¨ex_A x)iÛó˜Š™1ŒBŒÙ(QŠ²™™$Q—co& ¾œZ›wM×B;šá+‹ÆëIŠ±jV~÷Àõ)—ı©¨N˜¨šš™±na#ö!\–êkèk÷—cOc„ bï¿”bæ÷n†›ªÓµ†B’”TLS
ß@0¯-à—‹ãä—…<0LêÖ´÷‰ø‡ËBÑXf«ø­ªïÿZ[Ğsàa1óZØèY9ûñs£Œ'Õ­s"°L<ƒ8[mÁö)GG_ˆsˆ†š¼STfdPÖ´‡w”ICÉ
ZdÈ¾Î2µn˜İï·|ffè§<ûCÍÊï{ôÖïS3Ië^LgY«b}óªª’ÁìƒoÃ÷
ê;)RÛã½pœ„È.TëşXaîîŒ6c]Ë%Ü!>¦e×<IˆV?›EÜñªDr¬¶ë+­Eİe;i_¸˜,íÇ?ÄêùŠÕş`Lº<úUĞ®Máò`1"{›Ò¥pâµçFĞáhü;››JØ6~æÙX€ú:ŠÏ‹q˜şKz¡o,Ë¯*ò¤M¨X¹F^©ß³ßNÌ6–Õ
ÿvÄê ¯M\Oƒ¸sXˆ¼Á´Ö~ÂûCü;U`v¹kÍõEõÈc(Qûg¬„jS¹ö¯¶úñ§_{Ÿ6«”‰ğ¨¹—‘ó¼ëx‘ïVººb5JU[³GìRB2B‰ÍêÆ5x8m¨áƒA´
”"»°Ÿ*_¹ñ¶Ü;CàÓ±|†?c°¦â·v¦ŒèhÀ¡–š)gN±}çÓÜò_»ô“™Ó–'pˆœnĞ³,&bTÅw…¸xcçâáãÄo2Ñx¨ŒÈ£!ö$’à8cà‰`$Í‚rŸén8R\X†²lêë;¯-·èB(˜t:u‚‚e25½À#êÈõ¦ÉÍÖ›êú•{/bä¼º¸âşÏ9*Õ§‚ôMUQãˆÉâíHªgÑ¦Ä^.¤ôVê2¼_	ûÀuÀ„›±û`Òõö„®Õş‚z4Ğ¢£ÌœŸÑ…7÷ZÆÉh2[UvEŸèM	çfÜ+»‡ÉêOH¼DÓ"Dã«˜¦âD{Ê»k~’ùÏæa¡:iÕj:UDÎ¹¸ò} ô¦“#>ÃM|«üâEZ/8üğÓüCUum5ŒÊƒ:ÏfÍ¯XeŞ&ÑoKRëÚœ<pÒÍ×nÒ£q‚%4ËÑíS²5äïŒùÙ¢3)ö[ŸlÿpZVÅĞYÊÖ§$W€Ù@O™EvÄÄâ-ÌEïVàj´½’g¨ .ˆGŞ»ƒøã†`bÏ$zT)©éœv±£›]÷íÚZ
CîæGl¾â‹Õ½”–õÃ4-$Éiùğ¶y“ C“v	‹ñÜœ>¡%ÍJ@Mî$2²ııù¿·ÄPJfÃ½ŞFJJó”ş dêJ˜¤G›PìBO½_Ã(ié;J¥XK~[ùÉ5í{á·³ÃeJoeÔäPï<2½P‚œ~õBr}à\´Kaz7`©©´F}Á’ˆ/ÊVÔMd¤ë$:¹_2³„¨.ÔRª=³Ò›qãS0!€¯•Ôi+~èŒ¹ò‘…è‚1~'´á½G˜¸óÕ4-}	 ùÚUú?Ğ+ÊÑŸ‰Ş†â³Á#œ÷İ`ãìç9?4Ó_C™×Nft¤,…/„[PtTÅUÚ«=Ò™«-¯Ru½À…É•|“ğƒWÍğ z$Z3¸öÍ·3#¸gğ½¥Êü¿'áîî×û¸€»ı{ÖR;©!j‹8¿X)u6«Éğ¦(ÍöV•t#…c[€:À~EA¹a¤<¡Õ»pJlÖ?H}»^L6gÇ‰sˆ¿}Ôkî}ÏNÖØfe×g«T9£0§>äïw÷úäXšYòˆƒßÈÂ¼‘ø°^öÏjğí”U8ØÜxˆ§‚RFoyşfu•Ÿéÿë­' !€i÷ïVW#ş8'H ]ÌVRT¹§FöLÆa)1Îú¶‚¸È{5p±‹ÖÓ›"›
¤&
gak	[ÔhYB³„äk+<ä`>€mà³èÃ›&'s>ª¬šúáÃn¶Ó,ĞĞFy¦§Ú¶£Ê<óp¤h¤L
Ln-ø¾H!+¼$¦'Å…«­8c£ßayAam££qyá¯i÷ÅÂüĞFB¸6¬¤±ìÅ¸^§y¹ÛI”ƒ‚Hgaˆìâ´æ}¡ß“*ŒOcŠÏ&s- 3ƒf9ÂAS¸ÛñR¬—AĞÓyòÈ”,zj¸>J|7›òÑ²?_Ï¦*t6O_æ:íì2­z$Í-*y'‡`µtªvWxœù‘û´tÌ‡èBQ‡K2f™³¼–úmÔ23.ƒèDğ'_‹–äÅnòÖÏŒğygvEé²§Û6/¾‰xCÁci†Ï>P)Àÿ^Úc,Y—$ÑÃò-Ø%?]ò©¥gŠDõxğ9qËŞÄĞ*FEW€œğX4¦OÇ›o¼ò1eöMbm5õ#8 =ºá®ÕéáÚ|hîZ¿Â”6TWìÈKˆ¯qæË®¤ô$
cèVè,-Ğ´e÷˜UbˆbLí²°5ÅóêìŞTÜ—U-…?éŠI-ÂÔà5²,9)ÿ¹mğ|=Î·‚BnøëA¼Ñ
m‡À§Ä¤ÿb4>'¿Ô º´_ÇíÄ*Iß¦?ÆùVT†+Ã¿«²¢D>§Í
·ÎÕÉİ¤?Bœ@:3Š‡-ŒNÚdçx'M§—"üÑ%_:È	^ÙV‹*ìšív]×g{&ùDO5íc©>sfxB,'h×;`Å·¤?ÃEêéÛÉB€’šhvíò$Á‰0"íü5tßåIæ	¸ìğòˆG<M÷
]—´ê§R£§”yƒ¯;œßtQ/	z÷V’Ú¯övøò%²éQ•°¯Ñ{#„­Ö‹O¿¶<ŸÇo9Ç­ç+õÕ!/ÀfÔÃ-ËØ^"itÌ+;±Şò.¹‘Õ",ıtå} cá˜A¥XıñSOß…Å–U1]é…çß!Ìµ8´Æ.È¬ísˆù%¥·´ïée®¡+&mçFı8ló”S¿Å·EÙŸäo9•„×‘ãF9-şİÉûJCCÑ !<v*®—€!ıÁ¹RÑ„AgÈŠó9W²q*&­`™g$@(àiOı€@W¢}Ãü	w„;ˆØ-Èïë}¤ĞReá<œ¬‰ã½núLÄÜÀUôi­G—¸¼,Â÷É&~ªµ€‘J0[»sìÓcÉÎ^Ó_†)+¡hB^Å+#
£oze	ˆQ=Ç”Ha0±;~‘3Ÿô›dşx˜4Æåx—FG£¸ƒ¤ŞÏ‰Í1×BPKûÚºKß+qc=ZJÆ»,¬ÔŞ´.7Ä^Q4d×2•q~¨´sQéV“¦9.·ÀÏ„Úé±d¨Ÿ{†¢sã´†ª—ïÿèÒŸsòZòâ	$óD¿¡©×†7®¼@eøÖ£½E£ÿ"4+8ÌD7Ğ>&¹k¢9SÅæKr‹{ö6F‘û¥º<BlıfšB_2_ä7dOÇ>¬s5ÃsK‹;²Lı‘ 1Ì"Mèk´Ö…fŠnÁjı­¢y`ü0ÌĞ&{ğ	:•—HÁ FöTñb?Z0Á¡Ô·OÅT¥8¦¨AXıwBAN}Sei~î)4$u¢6.åØ%	lÚ…–~ÛY	ò¶·ØHñËOºVlXÉ<O5„RqóˆZ‰rö¶z.mŞQ¥5¦H«½¥mo§ªoW’ï«ÊáÀŞ°
ê8æ8û¢pà|Pt˜‹ñ.Náá%tºW­è5¾(ˆ44Ÿfš=ñh«Uiş¦·7N€˜ÿ¾ê.³”ªgırmßÚIL/;ß€ñ¾‘Òdï^Möõ$7u€jqM¯ßöiAvghšD9pê7ÜmKÙ‚ÿ½ÃÄÛz­]7›6ÍÿúdÑ‡ÓTŸ¢X}ÌTñhßÚ™GcK”ğYô—fÛµu62»óßJG^Zô½9$x~áx£€Xx¬tæĞk´¶‚…[GÂ¥Éğèv&d¾h&J¹lÚXñYW4æÙ±Ll´<¡Û\€3?(²¥¨P¬?ØË”$=Æş˜ÆÄŞb@ÎÏÑÄ×FãaZ¾Xuàè¤FáíòÍJ§†5`·WòÒyçg!0¬QıÎP. è`q/%xNbsF>ª#çÙšGğ©Lª“ƒzÓPtË•\ĞPÈIÌÍJn’FVCußCW.C£rsú²^Ax¼$Wó*€3ùO°X­@B9®¥Œ6­6Ô«­Z¸½‰w£Jp»÷4FgMnƒ
VÚáÆ}¿v€»9Ğÿ3¬$5€¼Òóm¶,kÂ¢í“ú”©°˜4ˆ&¨ÀåùÈ&$Å¨ÍT"A8T‘%óìj­¥˜Ät ˆ(/®Şé¶°æa’×ógôëÌpŒQúYÖtb3şCYv¯1Õ™€›e—O’o)¹Ó‚Ÿ]o¤WD5?‡.ª)¥dg×;ß—­o¸.DO¿Lá[÷ıòL$Í‡?_Iƒ¹X.si98ûÅö9t±¶£U)øŸ©·x8…ÛTzDJı·¯ ŞµUc@œ|¿™“ğáÃB
?Şõ×7U?)ËŠå›‘¬¿Êûl<{'e2àŒÚ*J‚,‚	¾`œ¥'lü‚5›°ãajøOéHÍÔ`–Ë§5êÇ¶²"ÓQ{µã¿r#×­´¨\©îÈ#wño ¿‰Nó®ò_ùpuªÅãşÊ*ÙæœO¨ËdëSFñ]ıÖÀ;5M‹Ç¸DmÇÆjiyT–Å,<ıŸjØİ‚íİ F‡Öváeä…âwj;¨E=ül§$<ÈÈgš¹ÜK¤uƒ¾~KKğÕhSï·5²BHÃÀÆ«ñ_óƒöµ1ÆDÇ8'ª4h›ŸOıÜËÇF!+c	;Áç\"Ma®İ–¤õ‹S2¡%ëT¥DÏF ·À­ËÂw}¥±@)Ç]Á}«ŠïÀ6pÇXëÖ_‘âD1dµcTÉhvw‡0•|rF9p3²ĞÚéØk¦ºœ+ıÿzïş¶ÿ‡Û.C‡t˜*%iH©€–˜óß]M#F¤}ĞÍv¶J«$Ú­)¹µ¤§áát¨„æG-œ%·‚Ë}o\A@Ô–=@å­âŠÏP3”˜ 4²g¹¶ñÓj|ÏÈåöÚ…î;ş€½3yóˆá»Æ%jŒW	mï+Ğ:^HDZ­¬æ÷Ï9špG«È$v%€NÅ\³ö›,ù¦¥2ÖíP=¦ª¥Œ'ã(×Á¥Ãô³(PKíg‹Êò›hä§õeó€„èá³ŞŒÚbS;eë‹µğêí5@ûï±U²é`?(®=jnâÁ/µŸ“áâ=¢æovç}™©át¢7Ï”æ€9õRç²f2§çŞÆ/.ƒ¬…õ–e%œÍˆµ¶f€CnÖ9|Ï‚¨Pø½1!´şZÏÙÛB•`ÿÌF¬ûá"H‚_ò&Tİ¤MPr÷?v\bĞ”6$û/ßa6ËAÂj_IôTæHØúÛXãv5ĞUn±àßGsŒ‡âåš'?ò&Ú!å|Œqÿ‘¸‰^…§&ÖÂ
o4È`y½—rbàˆ„¬±®×~^Õ˜HË™u¾6·¤‘¼Á†	Ï·‘+Ìò€G3P]z¡ºòÌ9eë¯38¬‚±Ä½æÉ&bk2<IóâyOõ£Õ •ÇÄZü­V]ikÃÜùİÖ},*c\Oã¼Rs_ÈíVlJR°Ø·mbÏØ© (OAMÜç?Æ~E aœ-ê¿ÆT¢2VlîªGÖPò«p½À¸–ş­ö¯/»[¡Œœ×4MÑwßÃ"y9\*Ÿ·c½|=ñô«–ö}¼¶©âgk2Ü.Û7ƒïBA²Ú%[«ºl­SàfN’k÷’©Æun%›×ééYÆˆµën%?ËCêÌ]h^ƒOÌÀímåÊç…ñıŒú69îl±@llòùXO¿.¢çeùI®4†*7ÙvAÂ¶j-’QòïuØS_,âòüaôØ³ƒô2yŸÌ\»¼ÂíØŒÎ‚“in˜öŠoÏFú,˜ª´p(FØ{äowÎfŠ©º.ĞŠM²6£ßáğ¯ôÁüi5­W”£uÎ¢ç
Ãrû58l?è‚‡:åÁN«›$f¨ê•¶~ƒùí Jì‰˜ƒûbM¬Öd£[EBšBÅÔ“
õ¸zœr Îz|S€.f: çIæòsÈ¢EÁÃ¹íÆÃ€Ó7æIDf7¥'	ÃŞîÿÕ…uå>µ¡O¶±{04.~
rÉ¢Õ´HÈ>H¢nK„‡bT–>õsJ!ŞˆüÔ±¹Õf¸fÌ¦ıùï™e›ìFKzíDÁ}ÇBí¬T]ïv©`'ä'Ì™¥YóC¶–Ü¡a¯ØP©¦‰ÿn²MÁ™)SÖ‹‰?÷Fzu³Ç{%]H ª;éj¹«ZïËSxF¬óÎC”m³´B÷ZbLŸIèXA?]{?¯zE|‡ªA‹M¶á×l`-OÆ»¬Æ©˜–?İlıâìåÖã	8ç2UX±­éµ}­ÇqRÈeó„H‚Õ!i	”v‹ôÉ–³ª¡„=­wé—_ŸA¯ıçôõ?Ë–†2f&Ë•tm¯µè-8Ù{meôXû8ÏIÕ¶4ß%ìÍà6ÄÇñ´¼v©õáR`™µ.À‘‹2•“4‡JKXc_dÅĞ•Ì“İ1I÷¦¸OºKŸïwûA^Š­Väàğñç‡OÈ !Éq=”ÙG¥(İ
bşåãÜø¾ÆâTöúæWîÔ²Uò­7´Ç†äÍDd3jbÎVˆi	ƒê*eº‰»+µÖÄ˜ßƒe‹%]§„ªüZ?à¥æÇêv5Å^s 2ÿ@ÊßŠ&³5p@L,Ã‹ç¨æ/‰†ü0B¾#¤¸ğ…oeAş¡#:hUu¿Ès'llâõ|d5îp«rGê£Ül`»)áÂÆn?¹‘hùyàRaŞısû>qnÂ¾.ğ¯†`Tò(÷SN½u?]á»<#(¦A—Äºî¤­×ªÏÍUYáîZ»¿°[š¾­ûù_¸>  â}š·T?_û”·5
¿´Ê$«Ü˜P¼ùu†ğZx¢*9ä[C»ŸâúB…0P5wïá±¢Ô"|ªà,;›‘=;`@Ö\RÈÑm,cGÍiUÈFI#dC»ÆÙÙ´V† J\ÿH” ò¬!2x6I_qiL‰bv«.¶”4kËTy¯R&2ç$åÔfŠ‘Õó–d÷~¬ä'‚YWp°¤¹*É·PöĞÑQY•˜Sãêtª{ˆ…JM¥h
¥ ‹PŞs;hğßÆl¸äÍk_ù¦óŞœæ£S×«+E‚5kp¡Œ<š`‡¢°M°ÖÌÄğDØ/¼…BÔøë¤/’öKÚÕÖ-BcƒFmWÎ\}Ï•®g’dâ§[ŒÙâ³ÜßªÜ +<l¿ ï_Nv |inXÛ×xw¡Ó¡Ôª¢v‘†D7Ö	Vjj t<f!:`¥-îC`× ëHKËnÈ—dmO¦3ïv¨³ËÙNS^½íÛ;zº5^§	^¼áÊ=›4T Ô,¼ğd¿`µ§ş"UAïcå«ZÅºİH7ˆ2°IµkØ‘›Q~^¯U¥é¡këÆûî2óI‡¶Ë/ïÖ©€¬Y&5ŸŸYH³ø‹Ûüˆœƒ¥OÍôŠBèÏpiCV~Kfò§¨ËÈ!ye¶W#cØ"ÒË³ä­k^*¥~2fiòÊÇ¤nWéË‰Ac+zex¢B¶wè­¹ã+utyÄ§}á»/.XwàH`µiü	¢:G9 ô6ª„gÆ‡s:ø¸ƒ‡P‰Ãi´n¦ÿL,T)t¦iy	‰kÜP²Û“4ª D0)Êx¶ƒ*ôw.D D¬¦Å´íğıÀÕg‚8©Ú‹êœ„u‘]Û«$^›ği×ê˜¶¢Á6Kè(Ë«‘ÔòZİQf	«ÅHµkŸÁ•
°‰7ñ
×ªaÑ„	ISI‹*>
ı£iTÔ¤ÓTÄ¬í€è“¸'ç«oÔ­À˜oŒ­KBlª5}ŸIZ›¥]Ú¹·f€M*ò2Î6-Üÿ÷«AËa(ãˆÑÇ/;M(½ÖgL˜ƒw»<Á,İç‚exğr$a–'>ş‚Èjœœ•¨Ó£³W¬.4=N%Ñ=lÓ4BZ)íîùŸ±MÃå¢ò ë~´ì˜ÍÎ‡Ú½Š!}°„à6ÄAÔãñØ·¸7³¼CLf[µz¤~ğà½êØ6Lş A¼@YÉıwÉ$ŞÄR‘å
Ë›u7d_:T·ÅV÷E«ÇdŸ4ÔWãŸìM0Núî°Š5Î,»ô}TBâ¥i°–,eÙ]:ÃsO#5Æ3—î„*±›ÛrpG¨.ì1´Ê¥fñµàâÅƒøfM¨.ag?Zäx7ğXÉ…ÙÓ"[PAÇoËáºv°Zñ¬cgÛŠ\bXcWgÑ/é)¨D®”(l;Ìƒ"|­|Ûği™^c‰ò½Vf®ji›¥YÊ›X.‘÷<‹c‡YWà	Šœ¹†Æ ‚'“l‡ÎÔx¸=ì)»móú"×pî8ş”µ,¡e—"j3Y[¬%¦ ^J"‰——0’£ÿ·";öëâìğÆ^?ëøË^mµ.\vx}Bà½;hß)œAQ e±×¸	&nF¦pÄÑ‚Ä|éÖf3¼ºùÊç³	Ï¤îl¶yqäXxÌ ™Ğ„h~.;ÜºV”?2‡ºïëƒ–vùjîÇÅÆEöøşÄÓO·x“¾‚”-heÊ@/`jÀs-˜jãc¿]“CFFıšå*ã*#ÀzIVûĞBÑÿ óºó.Øv1-Ö7MƒçæÊÔü{äQ†Û¾*®˜Tè\ªëó´TìNï=íÓ=£À£q­{Wºe(·Fù].ü3÷·ÍŞô`Ã´)Ë®3Óê)º\YİGÊy#ójÚ×.èpuUŸ-Ô9rÜjEµ¿D]l;
¬½Vøö>$A˜ÚïÚ 3A‰…‹C­J„O„¶ Ëv ŸÍ÷çöh_e„0ò’¦ Ãõ…›<¾³¶ƒi!ˆ‹H]·ıŸ/â-8®gµÙ©aÅeöL%!õZâÃÈ¹{)_/ ³W
~[¢ `S8şßR“Q`ò8 ?º+óUèNJêß)^ 7Ğ>{/@ ¨¼æò ±`ê1¨Ó™nÍ8c¯zœÂ¤Wkè<á'ÊíÂu—ûñÚØApWÌfÓïÚ1ÃÑK‡şû3N?T²ûü+¬ÕW¦Í@êcº/Œ;°”õFÉ@ş~€ø£¶ÊÔäK¥ïrŞ#°ôr”I¬
œš/€ÿ¬Íä	qqóµ1NS]ğ*(–ë@ïğ ‡¦[ÙÒºÉCdü2¿éWá·.OOW¬9BøI ’î6’7İù£©mÆ¬@ŠHh™›6¬‘Ş¿‚l¡½¢hì“>ŸF÷îF7Sz ±Ãñ”FJë-	™‡°ÕFyûA4$÷0\´Ò%Y+ªÌQkzü¡£ªÓ*ŠN¾z¡âÌ ã(ß1(÷Òé…]ú“IÀô2p—jj_Vb’¹½* )*Ó»¶;aFÀqRSÓô_ZÂC L[hŞÊÇ» ıË®½œÀiòy
ğâiÊTkÍµÌ+÷åñ(kã“Únc‰'kà¹-óFß±÷
´s¾Ù¨ı…‘Q©Ü;â~@I‡dÿº#MŸaÉÎX~e<ó,‰“¦É€<_´”ÃÙf}Ø°@ÎıvÄˆƒä5#Âš/úÏfé	Ş`’‰sQù¼Ã—èao@uL_ ''’E%VEÙ.ÎêyiŠ*¶Ñæûˆ±úı%ùò¢Èq™ïâ+'QJEM1K`æÄ'-GÛ„ôşGÉ¨ŞûƒÀN‡ÃGÓJ‘ÁÕ“4V‰´çgV@Nó‚ã÷£>ÁœsbBkğIR^0n>„Ø(•¬HDñsN˜ât§9"I3×\â—c“‘İƒù·c†÷N¯çqBèD1^¿“g=»«‘ƒr&7íAªÉF<Ôoö²Ëğ/¯+g·UÆŒ’? *à‘€Ô:.	sÏ†³Ç	Šúòë"şûóÇµ×ÊhÜsØMŸs oPT×˜•ë»ëJ%¨5Ê”³oTëYuÌ¶ß<–Ü²uŒ¼©lÌ¢øjqõº[ç½Ú
dš}--Ä³ÒsBĞÂ‡™ÎƒÿE³%æé	m¬ ¾Óq;o÷Itn²­˜¢ nU½bq9~C[ôéY·ö±¨h=0ÜI«ò	æ»ïD1ÔDp«r¨’îí"4ø‡èiğ÷{ÿç§vº­–¯—r¢‰´ÃuBQ"`¼$;‘•ûHâÈ%FÃ”F½MÌ »è4¬WÌoËXQÅI¢øçĞ×5¶™1Éè®©\dTA†¡ŠèFvúSr‹”o÷m3qS­ğÕM&jYJô‹¯]Ú•Ú„ÿTğ¡‚j^zv˜Oş•Nã"åI,w-¦ÉĞ¼Ç}àKATFÂNf<ê€üÚÓñX'·YøõŞÏå×Nâ±‹$0iğbÀV2µô;sù‹™`ÇÎqDØ¾‘ğ…xWÍĞì2aí&f =Â—ñÙ‚iã¿ ­òKt±%Mâø¡ê÷ĞßY.àıŸ¢ä·¶Cé3MÙY—»;:H9Şµ~=Æ=¾Ş¾Tõµµ?€ÉKd u%}KZºÎ$)°w„RK>‰Éí í(µ+j‰Á@}eğµÄSLcBèÀvƒ ›É Ñßi±k#©ªşrg A„qœ~Ê¥Ë£6!F 8úªéûø³â|ñWÿkc…ú¾Eø.è9;ìwû½l«yêÜR6‰=!î|*`r™}$2öÈs´óŒ¯w„™lO4£/÷éuimtmıoã,Ê¾µˆ=»#ÉÇ@®µLÍ–Ë’•èöÏ; 2¨àËEPŸp¿Z-çhX‚Ç’•Dz›hY:™Ã·bù¹aR†!x(Á¿Ì;Z÷¬„yV!Ÿ•±6éiî%ô”ÏüàAMğîıKoØ*ÆAœgX7K¶R¹9f®êT*^ó %
“¬è"LÀ_Ww¶yÿv¾µx¶ı¯„»Ğš¼’…ßò\ÒR;®Ş”Œ;Ÿá.òú*q—Œ×äl2®pŒ[}7ÆÍ«cıÛgN™şáMœïQ–Ù½‡éâZüıSGı¥A¤Ê(®,êÆ€?¤ş-P€KO)şa‚ÒHRş¸¶ŠZ§òxËc_gõ|P…ËëÇšCX	‹Û(z»éD>«Ã£»¡+FbŠs=X•>ˆĞŒï\1›RÆÇ´Hï1¯È\Ø¼{èøâh{Ç=ò+ˆY˜Ÿ&!ŞpiÊ•úËBTíÈB2Â>)€‡åG3«SÌŸÀ7z_XG•|ÜÇu¨ù7éMÌ]mîk¼ÖÁy=¥
ÓhÇ[‰ÂYJÍ}y‡+.jŞŞ$ó}Ş^`W›eC—vpE—ú²ªÎKŠV«6a|Şğö•
ÙtÍHİÃ½
>&-Ê$ç –á)œ~ÆåYÂJN2gı/ğ\¥A_)B½şY4¯R[R–€#«M{çÔBÖS®X'Ë9¶qsi=k›œ‘£RŞ§–3g¨m“ásº«;SGë¦o2±•öô[úí;™ÌFô†äiå›P¨Úú#0L®1Ö=û-lÌ}¯kş^Ùınß¸e|(cƒ:÷Ã¤@¬#S>[ÕÎ;ÂW4ï¥à~/İHƒ|F=ÒÑ$’ÿØ\¶eÊâö.à„ìmYŞŠ!3Ï4Á;naT÷Hä+Â,/EBoóbÂÿÆoeÖoæ¿’úïU2–&¡ÕH¨{•ºØ¦ágXB¯ñ†ç±6ÿíÃ4ŞŒò9Ã. İX|„¶~©0&DÜ~ïÆ\d¼Ê¥à9qæÚF˜šÚ¾êà´GÓ°‘»€D»œcê² O	¡í`©¼a°k–·ˆÁÌ“˜Ü:ü‚—!‘½ëi•´7ÖBû&{F2¬ íoT°Ó°eP¸¹°"w4x:=
ø™‘ğ=Ä66ñEû£è€ğg,ş-kø2ã³¿MişêMm¨*P•l¥í|ØÕf¶c&•Å¢Aª½¯Ià`e~	càŠSf¶©ŞºÓXùø°¢â	¨ì7~EàÓ¥¼ø|t`Ä°ÜÃY¥–«OG¦EWöó›ô#Ñ'§ÄpƒlGÏ _ïëŞÅÎ¨°áÿfQM]æĞ;£
Êsğõ*æŞ§ğ·3Vò~dIFŸoìè«™²JÈjO$€])(KÊá¢†ë½ÚÓ=G ]K7ËıêU­Gm
¶ÆÎS)sØå ]µLñ`øĞÔWu3üÙÌºmYlÍ{¹Ä¼ã¬§¶iç,
!©ùƒöº…wb7Æq%5œƒÃ5bmrcÛVk+Wµ¹Èøˆ•	¯õ¶wğÔJoAêcÒÀ=È6.Æ¼~7=Â>Œˆí°9‚÷Î6X¢ë1HÏKMŒíÂ¦)XÌêŸ$T¥'ÅtÓfkèå¸ ¨¥°b´tPÊïƒÎ5dYo9²†ïÖ¨»É“À’1~Îf³ÇMŞ•Vkt½‡m3UßCtJ/œMZOî$näæÓE QûÑqD 5p´NŒ³ ?¿á7è.±‹Êó)¥e&x“î64$áø¬
§'×íÑ¦V.
ŸT–’'JSBÑ‡>ÎßâÈ£Ûjg0§6ü‚•˜lgÉä?Ô"lY”`~øÓ‹=×zÙJø¼58¸Ÿ‘wÿ|s‚Íô°>YBïút{ãmúDCøF>ŸYñ»wóãoˆ$½ „§O¼‡—gAh1:)ê}LüİäàcûÄaìôŠéÔ„®ûÖ>r.Î5I¸Ë“ÊØZ½u¤¶W9üÍ|Yøº½±Ä+Ş¼#{”3ëf$6km–'od¥è·o}ğ|Å˜-H4_‘4@§wiÅh*§{ÂÆ!{Îd·C—.ëGÆAq™Ìmğa+·•Ö}7Ã^êA¯ët¯æÛNÀ|üöÅŒ»×BìÅ@D·ã‡ôÍa`¶Å,U:çõáXÿ™8u èå_ÁwÒ´İ¦ íK­œz˜GüBJp°aşe¤Sƒº}ÂÅõ!Š
üG7pƒáê¡ô¼iX†ƒ¢¤úH“©¡«ÜbBÁgl/ëcµGMˆ:©½ïomªıeìèfìœ$—}dê6uÍáàM³)$\Ö‡12~ßªÒº·#™Ä·ˆE®ÇÓ‚Ñ!'`å&+I6Ùò¢‹¯D_s³U¦‡U£­4¦â¥='ƒI·™­ÊYF‰ÕÆ@k|a0.¤g÷hj:ø1Ôt.¨ÿ›#E¨Ó9—²9öQ¥*rÃ©ËxDÃoœêbŒCŞ¬±”À;É|‰ô‡öDk7Ó78'Æná÷.7ÀtÂ„$”¢£<&ULÄ†'!£M\¾>›Ï·óîƒ/-/üÏ¨ÑİX‰0´k•jDô"¨{Y:Í|IÜó“$AeDõ‚ô[ô+EõeŒ‡äµDá_x“ÎÌÕ”¾ªç2	ñ’™™•ƒ¶öt¶Z0yÏXaØ+R¿ÛmO	ªK#ˆ¡)MÂ¹Çæ1Q]Ÿ­ßí§(Ylë ÁJ>…JO“dœ©×Ræ8iö$šÖ+ç–RÜµ‘PQS®(}è¢U 2‰*@ƒ<S\zhŸ•ÏıW¡O‡â3&Úõ——2¸C
ß]ÿl™CÛ…;ÏıiË&j‚jòM•çûIgÕÂÍ™ÀKg±)\ĞªT5E•2Ï'Ò¦~02%äşdóOäÊf€1—Æ8e;°‹‘üCôòZKÃâŞ¡ »ûÆª‘üşæSQöÚôÑ¯¦Œ™>Äû Ì¡ŠGd•–ŠîC·Å®ê m1mG¦WİİµFŒÖÌjoDàµú‘‰pÔzÌ'ë¯¸x*äƒuÎn,µ’B§òE¡Ês‚v’§Ij®¬ëMU$Ê:>ŸaC7à±Ñwó^!½7p¼	œÏ*]hôC=¡oÌ ºÎL~¬YŸ-êÀY³ùvÛ”AÊŸAx¦‡ßû»ìL¬:†Õ—÷0ç„bJ©|é§ï1o>õÛ…Ür$È-´h=äRÖÒ-Ã°$n<h°%Œ Wø+Ù¦ãÔ¢)CªdT®à§XßÊë1?~ß€Azç•ª›jacÑ¥Xzi;và{rîgÙKª¡*ã¢waş‘e¤Gf¦ª	à˜Ö3w¶€«ô¸1(;]²7ÕN³¢^v,ëïíÜŠ:k&ßZÿ–õ?Í]å,³[=öğ358FÊù­8uLµT©©ş³Éî”¸"šr(›œÕqÈ*8ïáşTŠ=µÒÏÃn×—^Ñş(bŠTÌXsdˆ†ÅŞ§™CÀÎúyè6Øf áMLUï\ğã#æ"È¾­IÒ†WÀ</´YŸ ã¶wi¯÷Ú3±U<”‡ĞTÛ2tA…R0ÓaX¢-í$bFµZaÃJĞrE‘¥Üö!±şcŒuè¿)á ã»’´ûù¿f‚²‹à¿uÖ2Æè¬Guª;˜fZRl™õçâ÷ÿ²x¤”6zßÒ‚ÊRÇ"¬ë
DÅQ9€*[rVr„—Ô/$G‰ÿK¥·s·£Šo»ê!sğ:<Ú¦`û'¶‹"Q¹²† 98ZFòù¼ÀÎÙÀ˜Óúvî=:ôÖqÁQq_­buâeØ&‡Ä¾şö %ÓRdQ$’ì8Ô$¤¯©Ÿ5Tã?‚)‚OşÛà¡,‚†®.>GYæôàf8ğ!TOv¶UG´#Çöú—Ûic3Ñÿáäu+yánû‘'/öoÅíC÷ˆwí™ô¹GR[Ù>®¿wIŞ«ÏÎÍ^zÁ
PgOPuíN94*ÎS¬‹ö;«824~a½™Nğ8XÄ5Ìº·Ã;}Ûd2›#8‚¶S‰ÜÍ6c`Úµ$aã§SÏª‰ÜP.òµóƒnwË=}~M.ïáªÂK©ù,ÀÌ¨|S–1·Õ¾j—2ìµ'âß5åÑ+´§MIİ`I¤l¶¡	ä+—
©”Fd‡ëÕ0híï˜¼¥IƒÙ/3/¿2Äk¯ì+øÎR™
Êg÷¼TĞØ@ã³Q$/:Ûx‹|.]zOãmğŞ“øÙj@”ÀuøŒl5ÃÌ.»’H€`ÔÔ[ŞC”œ–{Fj[ï§…³iA9;ÄÅ:x6µ[ã‡oÔäöBò`ºöx\W%QÔµÔ±Ş;ıu%¹|¿ğácßâïøcQs……UdFqvKD†Á¢pC—ë(XU‹Îº¹6wZ¼kÛUÁ„Ås‚Øò?ŞDlS®{õãZ¢];Ã};¶"ı5›_H€EĞ¿t2Ak&OMïšàÂÌbÂGö²R®qĞ´õDfW ÚÍÂ´	Åƒ	¬‚¢-kÄX§±ZÕÈp„¤\ãl¿YR#]ãÖ¾KéPÇ—æØ¤+ß-ÅSY?=ºv& Õ;A‰Í[©-†Vm7m-™2ä¤&ÁüùjÉÜæ5è,ö‰Ğå]µîqÔkg|†§İÊ%™´S§Œñı¨Hüˆåß°9:Úã^e+¾?»™/¨4•³°­Dş¸…x+f*} µ{>JHRäÃ!›OôOÑwŸ×÷ñT–çdRcm/R,†Ú)M:3¤…BNÒ8ØÙ#Û~cXçÏè:Ùy|ë­ê)9fëá¾‚¡u—~0[7 `§!¶ÄĞBøñ¨Vm× €õ›GÜ2??i×dŠCÖ£È9Î:=+ƒCÑ®€[ªi)¿HC–CÜ¤îÛÁ~•öuŒšÛÂYmç^‚áB c‹›ÚÛ6z¤º˜Ëù3zŸWV¢Rè“J°(ƒú;ãı­4_£G9ª¨iŞ¾$Gƒš÷ªƒ!“ +Ü+0y?½,é›Qa>¼6†£Ù§8¦ _¡´_Sî±zøóŠpóºİ£Ÿ¾ƒ‘÷ÀÎXÆş…®3$—ò0»4ªŠw4n¦ÒŸ“lĞAŸ‡’›éö~|¸%Bie£€/Û)o´öx,³Åø?âO­OÉòµ[T ŞS+åˆ‹L‹©·"§XÑŸ:O^PŒd5ÅãPôÄİ:YŠ˜~‡Ì~É«-ÿ°ˆª°(.SÍĞU5ÕÚi³c4—0 m×xË`ÁeÌhç!„é÷=~ñ¢¸i½Š¿:'0Së ×&|¢*ºXI„WLŒD[èÌàŒ­&°=ÆTÉ}W#7(‰İmía.ºaåI¨bmÇ¬¾‚n Dm›ÉÕÍß#ã RQøè$ùšÛÇèyÜB’ÒÕÇ«Xt!«³¢§l‘±OCL>z
Ÿz@RC	ÖeœÊ ‹Éwa\`­ÁŞ1õ×šÄFÎHUêıÑŠİ-ëbaGÅ¬±±0/uk,m¡×_Ğ•ğŒü k§E‡¥ušˆS)dğB¬FÆ%ä«ŞW$í\X:7ÈÎ4YÔg†(ÍÜ¬ó]äfÿ7ÆÓq`şDxêÅ !ÜˆDÚ‹ÄÆgØp.hà†)êİ\‡ÿO+™ğ0Ÿ§!·…pÃí"9Ÿn>Hòˆæ`Ïkÿ]>ôİî)ğ+_CÚØ§I_ã‘tHj;Fèê^b1×¥"‰ŠV<>ÂDÈ<‚ŞÃ¨ ÃT¸=óÅŒ…c~ƒD¿¾°¨8@¥;íCJQaàú …)Q¾àË È«õø]¬xŞÑâËÈÌÑVÉÀ«›·Â_%‘bsÅmøŞ%-~]}
)Ğ¨‚†)ãamS¦Ág¾8ª‰cD)é¨‹¤d‰„¸÷+Ácb™]¦@¢4”B”:T-‚…éÜnUÜ´/UC¼ÈG'Œ`ÜH?;¬.ÄåN:2@åK…efÏ©_|òE{Ê8.Vå…EƒÂÈñï¡†º®%; @¹Ë6Y›±dÂÀ>ˆu§¤*Ì½Ğ·‰o£‰n–+³¦´|`hÁæÙi.LÚHbÍ…ƒ’å[aÚhdü5í–oYi‘IN%u`œ‡•d» ½{ğ 	|Ñë?„&F½†O›0Á¡F…¹€0jjLñÜŒúyDÏ¸2I‘0ü/®„U$.!1)ÜY€Ú1ºÎ—G·AE›n¬¡T¬:•Ì÷ö•+­ÚÉ¥.É¿$B¶ñÌ]‡lvÀ‹İÓnß¸ÔhğßÒìrI®mšµLº$	y˜†İ“”#—¾¹1)v¨ŞQˆ÷Ó×Ô6Ï;+Z‹Pÿ2òñ”·LjKì³©…¥*ÕV­«HŞšjœH¨äA3 øj.åÖ»·œ–šÏÀ^·= ‘’Æk˜F1uÎøICùğ&Ø˜w}ğgÜÅw™b“Ÿ«Š¸mÒŠÈÎXW–&ÿÙÔ‘ÆU|QQÅ«ØRòOD¥8áá¯ao¥Ã|ß;!LÁ©71›ÍQæ    «â= oa_ ¦€ğ€J:±Ägû    YZ