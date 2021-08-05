#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2803807800"
MD5="a241eb02e02b975cc9b1579ee5ae4829"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23536"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Wed Aug  4 23:53:42 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[°] ¼}•À1Dd]‡Á›PætİDõåó³À[}5){}ô¨óJIÃAVÎD"bødeŠK¬Bx10”OË>0RÒ—‹€Æİb‘âNäë—geF­æ×ŞyJÉ,.ôHáK@b¤
«ôW,£Ğò6lĞ×hØo ¹í\q)Dd¬o×ÂşB ëì©E‚3™wwê¤'Œd4SA©ìp¾S‡ÏÁº¼byÜgO\¾-€nC,œÙĞñ0"Uqğ\8æŠß5&À©“|ëh£}¯©­Z0”ğĞßX0e¯úÁüë/İIa½-l6U*aPö0&9xt”uñg²A.“ù.uÔ'@ƒj–-”šì¨öxz©ŸXÚTí¥jÕ§t8Ò½Ø×‚,Íò05ÁÇwAÒÚĞz€ŒÀ³øKÚ™ir‰Šæ¤Ê zß
¸"Æl‰ÒfNwl†k°(*øLÏ…^–Ã_Õ—}ôÄçJ¨j•câı˜ƒ%4p–A§o'ÓÎÏHRšWŒ-ùM.Â}rİğKÈJ5È…3~$è)o—y/l±)kçñÿÛşÈëxÛBnË
ìH2±çK• Šì-ù6ßÓs D—ËˆT+ ¤”ğP`€]Ê¯Ò»r‰\ÀYÊ¶ïà(÷ö#:“«=Ö±ğÇQZ âÏ#”¨Sn:b¢˜}Â‡oluCævë‘-~Â{DrËXˆÓ›Í‘YUöí¸a¤¾Q*GÏ°6“¸.V±fcîëê–*´ùŸï8âûïã-Æà³Ùœ·å½l£ÔŞJÊd@8£Q1f3Ì›èñhsîN;ePŞûb`ù«`ÆTo=©£nmCÃ)d@káWG®„ckGÀù}{:¤DF‹1_÷´š› 9ÿÈìœR5ˆfdìÖF‹ì«4oÂœ1)ƒòûr½€/ÙÍÆÂÜ‡ƒcïœ-¹ÙC€?Á'¼À_Ó$“ë=Ê›‚ø¦ÏÓpÓµ‚Dù¶ªüÒ±óZâç MÜpù6{]r”Œpä6`ßC‰)7GÚMç4g?'|Èk—ıßè›Gs{Y³Ó™­ eÎn¥Ğ¨E:w¹ëè5µkÙs"·eäSÂïñF,WÅTöáj”r†õ‚èK[±±£ó€+ÜGù%wÚ3G7¨?pcÌXô…sjĞ¾ïüÀŒ'ò€ SÃã@%üËÍ;³Ñqd·ûKq±A¡u—£xƒ§KÂİ20ìS[
ş°hC1ßFæÅæVœÚ®"øáÊÊ†ü3˜"ü	wí©ÁO(UÚFˆIm<ñgxØVÍíÃ©Ç%g»×ê£Â¦³8u‡ªŒ6h	Dğ¥`W‘gÉ|H¦«…„Ò7MÆ]9'[CR×™„ĞŞ©XÿMËÄàÁ¡¤Û©u™ÿ•G`“Ühúİ(q2¼PÀôäÉ¿Øİ3„Sí“F=®ß;<sô¥67Ó­Ôèo;0²bñbSmìB¬‘rí%`±5_†½–Šû‘çœÏçGı¦[#!æiş0O¾ÚÊw‡,“Û„Lï+\Hƒ0iO–p*ùl¬nà¥ıHÎçŒPgŸÉ9Ğn>m¿'@ù„ØÎç}¶«º	-‡¥Ğ¥×ß§5XO@ˆ@èO9=¸Z	¨7Æ €äÈ´Ç£–ä8’ºµš€?t(‰KâÇ%ÜòõÊ"K²úåş7—rÛ°½¶}&¼±D3'
ˆ]Ø7A¢Ü|g¿–?^	 §îl BI‚ï54Ö¡³½ö·˜#x ÂcRnğHåš€¥ê-ÈÁæ©÷hüÍ/ñLzğÔ´5\€ô(”°ÿäÜÏ) åLïï¯|À1+®-s\Îô»Ò'¬ÚÿÕƒ++Y¥æ·l€µnöuÆxù1<…D”Ç°äÆŒµG½jø!@;vĞÕB½®ÀÕjb}5'˜Ú…~pâWĞŸ‡$Å0/åf¾å‚’ë«< AX™Ü<°.’JŒË²êÆ•W,mÑúCàå¯j±Ayš,¨‚ğÀfCéØãa55ÿ+›`Á>ú1xzGÓ:»‹ÙŠ« Ñ®…@h$F:ÕtÂù«`øg“·JÔœ£xŸ\ŠNMjİ6”şs`èÕóç~muÀú2!İsWZ\#úzĞh~4ñ9R³Z)1ê×ËûôbÄ¸ğŸ¾Hßˆ–kíÒ?‰WÓ5´Òzş›¾ô°ÉâMª@¼!ºÿPƒÇnÚJıFÂÒÏl×äû
8ñ+ÄåË¼>Á[QB¯œæ•NıMí4åöLMÈÙ)‰l8ò%Çzç©JĞ¥÷··n¼‘“#ÃIàbqòz”ãE ‘›ãàDKLX"$d~_Š-‡¾°Jf#*ä{bŠLãë	½^è|æ¶¢pH“Æ ö·,)h× då^5‘„>IçétËÊ$ØmÄ±›ÑSàòëîµå"Ü\ÎÄTÄ×¥¤Ü´ÁçşµŞ:[šõhŠ7†­Z+1à´ŸU«JØïD#)cr9Û’u4Ãaˆ´ÆG’ş¡×Û(;˜õdtÎ¤õ>äÎ:p
Ã¦Ğ¯÷“æÌq‰Î«¢NÂµ(¿ƒVÈ2Itº;Ôşb@ƒ°ÔM¿´¿wÚèjÔP?ú”pÑè;yãÙ#Ø¨bp=ÉXÃƒÅ!¼¨É–¾µ{§Ä.ŠL…P4æ„p™kµ.f'W3ZàÒ¾ó˜Õôåàö£éPª™¶u bõîa¡\µ‘ÎTå®¯ñç!îÌŞE½~  $Oòç]”í9{ÑŠvLrÎ5ø<’¨sâV´JÁK‡¦ ykñ„ ı
ûK’ƒQËøk¿=5lµËí’cn°¨óÖ¨I•>FYï ÏúgÅR±ÓS=üÙ™ôÿÇsÑ.ñ™E/ª*Î|3,õ@~•r³qkp¢³µ»yŸõI'n?NŸ&d|¨ÍWyÕ  S[hÙĞù}<TN£d,oNEaŸ¿4.2’u%$Ó]É@rÅã’ş£á©ş!Å³ùÑ^m^ClH/Øk0whr¹™@µÃ9.WÔª¦¿|êfî¿#¹IÖ<zçv!Ç»¿¿c@ş2q%Jê¿:xaĞÓ<š•ãÂ^bº%SÏâû„’ÑÛÎŠÊØ‹ºDåo”JTkÆXs`{µÒf>²eì?Ğÿ¯Ãh,Á°oã@ïükuåJ^ı6ØÓû)±Ùô5Co1ÖW;O}h£²‘ÓJ—ÀÁ«ûšüÔü[-¤ÜÊO?·Â}ošj4fı›@iÄÚò~‹„µcÛ‡”rj%7†@Õ§<Åçq­ËFºñŞFPNœyŠRôşh4ÃérŞ¿ï&¨Œy¥WÇî¢Ãç»û‚+Ú;ö7Uå¸oØJ]sÏÎH’ Léä’¿wk,o8Š%êúËu2Ç9-
Í(
õÍgr•{öë•(€k’£¿ oº³Q0¼+áW/åâõxÃÙú(è'±íÙÕRÜ 
w.	t¾/Ô9f*}§ºv9HaaM~BL­!ŒsçÊ61ô[š|!ÎM.~ş×FØ<Ö¬áU†	¨¾ı¦¶‚Ÿq° ’.Æ”Ø§LŸiFEÁÊ”N§Pâäã€K¿Ò”²¥µøßQ:e]B»
lş¾7ué†ËLRM1;:0tˆ•åºŸçˆ~V8/Üı#–í#Sşºp­O6İOí2FDUo†°Ôl“®)ª0mòöÆ{PäÍ=oˆ_Qw¦R_RÕ¨5Œ)Á?Û_P§õ;üÖiHêÊt×øÇ¦ŞÔ}TMÓêAƒ˜a6ñ/ İ¶L>áK#ñh7„ºkßªwË.¤ñ(±ìØª$ÕÜôz:ù5t½e1•°­w	/Úu™ùx•!ÚYŞ2}£‡55“|¥$+³û~X>÷Ì3æq¯èÚ²&¹€R¥dbNj&C¸™MY·@+Ïm	TÑªg .µ;¸ÿÈ¬R9{Ç$‚%hÎ&¶ƒ¡ˆŸÄ¯W¢d!^dã;˜§>aéTziíÅíš°™ºEZ·†2#ÛÍ×Ô5MoÖu»‘˜£RMmœşô>).dg"5ÁŞı\
éÂ`÷€éæ!e€d™q‰Öíz_ß9¶-á’£ØŸpÇhqz‹ÍˆIcº*3aBZäØ¡ôX0ü•¤Ãn^¬up›êb¬Uß'	[‹Ô¾)3â8	 ôµâp'ítSÅï­Ì<ÿ¶Ñ)ø½ÆİVºÔ¯"`dXà‚è°v“ÇÈŠv®eÃ¥ÅÖ¸–k<ÁÒ>À¾Û)|˜‹.®s,²n5Yp.}Ü¸’.³’Îºw—\Íaœl¶ò<(Ë]©<nU	¶D½w]11!`¢vkìY?îî¾MŞüåS™Õ\Qîì°ùù(\ŠMÅÈ¥Úo?…ïª/øĞ¨&‚}<¤.ìÉ3v+ØüÑ€à¤ÄÓ“bÕÆøk}çî§óné-AıXÜÅİ äï6Ã;¹€ŸQÆ$´MAÑÀ¶­¼XËáğÔ#Õ7óv`ú^M!©ƒš§
î”‚òú-Ò’ ‘‰»K	rÏ&ğ† Ãgè[!¸n[\m(¾ëùøÚË4işá=o³ôn[ÄŒŞ{®6-DĞÉ‹€³à¨TËñğê´óÏ>K“gı¾® ¡·áJ÷uKZCúìÍD+|üÛ:¹gDÙ7ùÿÃv±°µ/˜+ÆyİiCÜ\èÆıÑzórš »}Õ8Äû«'vóÎW3á-º¾mê½#?´¥]u¥ĞÃİŞæ O–Ä‚‚ûÙ ryÎŸY#ß¥Ù†•vÃöŸ?—EV-}ŒWŒ@*N()1>ÇáİÖî¨`€Æ½6eSfÕ\;‹1’c$•àfcÃôYga
ŠC4ºYàXtìN‹
·oi¡<,—ÂlÒÓë{@ä(Œ$—Ô·uiK„û,¶Ú6yêË˜ûÒ‘
Ù™1’cµ6ø*Bññ–sîBF	™d%¨ÖGØ…Ğ¥Q³Åä·~øæ3|ÔmÄ¼<<a§˜¢ü)ØÎïÉèæ|Ş¦‹²Yƒ%î;¨ÿ±'“¿›R£òÌ‘Òih(²şÎ¤1{t±•”¦ş£õ-µ*CŠÔÅ_gu 4EÔU¥ËYçbîA¦Dyí¥®C1·Ã#»`]ÏYD7j½+ÆÆ5øë9nŞ£„“…"şáæ¦E„vÜW‘„ê’J°<A«Ñ’©¹™‚gÆ_Â0‚¨ğ¿¾(@Â8LÌî9¹wÄİÖz±è|nÀÁ±:ßı§_±fK!«ÿÑOûÜª9uŠ'º6^ŸúÈq T}å„QDÔ¾l
T€éè‘"Ÿ·\¤E½¦kÓ¯:²ö[a¹ñ¦Şâ-Îó;€fiÇU²ê¢fÃ.NëwœXşìÍ¶?ŠóÅìÙ—ÃZ¥ÛŠ¼AV<0Y•Vå†\WŸTRº9çRôÀ¦œœƒA³ê$ˆ×ü¦Ò§@\€Ü6	æ&Ğ’¢U®Ğ£fğŠÅ‡ÇŒßK?ñø'@yÂÅN?‰Êãmi,ƒ#ÅiÃ¨›Äú§³
øáh>œkn/V-xk8:%¸<¼9F¡ÌØídhíĞÉb¨F‘éF!½QÃîÑKÉ$”dÚ£©ŸxÄG9\E¹^íıok˜†•Í¯(CŸ¼•…¢ª-KºÉÛ,=íRu-©°~fÄ‹ƒ@UR‘?8L±tËUHGúgO
áVD>Î ¡e6zô‘nëFÃd8‡z#¥;òBæ_¬C0ˆ‘“c¾šuÜ*ÎºÓ7àYÿÏ`Ö´/C¦,¶ópù4lÈß³9:$}¢÷ì©"PÚ…Rsdûú¾Ö¶1iÉ}Ë¬ âı|Ò%<é|©R§Ú©3µ ||Ñ·È3:Ü5…è%ŠÓmsWˆ2qåkBq68‹­šiÜ³så)ç8`\õ‘Æğ@üiSGˆ~¢öiÆ–”¯wèÉ¬AHcÈ£ïöJÅåç0œåèúÓSX£lZ¾ù|©]M9¢Z=h7tX‚ˆƒûS™âbõ[æüEtìxÁÀh:iÛTğÂ°×‡]Ë ¼ZFgè;.àzéàínB­ÁQ¾ˆáô$Òƒû	’eÀE¶ˆkab·xÂU–O|ÕË§Tá5ë¹ÔkaúIeU“„ã
ø—›aáÕsBª¢gŠVkjì73ıÉş$ZxÒl‚ LÄtQÜûM‚gí¥1 ¹{wcDksEY³cdú)ìKåBÈ¢i¥Éuş1äbİ`Á'×Ö‘¿–ä•û÷Jv…û¸çcd;Şàïqï¢H
Vr®Ì×H:ö×^ä&"ÒP×ê#Ğ:.PàH«K›.ø4c6äQñh*9ÉË!ˆRÕÖº•f`JÚ×ìkĞ„ò6{Doºá×iÖ“pŞ¥ğ–¯w¼T_¢i»Këzk™g<”“¥~†-†`°Èo´MlŒö½n]±æ1Ù‡E5¥`âÎZ¢œuVúÃ‚h_hEÙi°¿®[¶æk0™ŠÊ~ÉMòÆ¼»GzïÓ_aj•Ğ$6»>ğZÇŞEÉ |MéŞê3JUr‡°T$ÿÁ;CÄqˆÇP/L¼³zÍ®Ç<-Õ>0ğ
{¼a‘¸Äfğ’&IÂN_“Cˆ›õë¸C4ŠŒÎ2m.÷tëB­ßµà6 ï lúìºk8{/+Q~ÈmŠáUÚqßºäéy»Ñ%ĞLúXmé Re½ĞĞdñãíè§ÙĞŞ™G%è™+ø©ñvÇŒäPŒßªô¿¡2Şy^’'KŒˆ“©œjlît}AªüzP‰[jø“—ÀæíàIŒÕ9’oª<jIŒO`b N%Üú¨ÚHÑ8kÅüt*ã˜”$u_f'<Çè–ºH‘k-r«d¤gŞg¯°¥@ÌU Âl0!- ,uÔö-}SoÉİ^F¼ kNœ#”üeÒË_ ¨ã\ä?óÓ¹#ÙFóe<PšQ³&e³'~d8c¸¿Æ$–-q6Ê55jm17œÄäªm’[ge)ÃŸ¬öÄ÷İì3­sµr¾´‚W±t(YwÔ‚3±t=Úß.t;’JÈÌ@ ¢0|€ûŠî_ñç¬éDÎ¦‰ªñöCßë´¶PÓ.­¶XL$Ò˜JO7õÂjp¢táT†2‰6Ö«;|Pµ‹«¹su¡	Ö©”€Ñø¤ğ·7Å‰…ŒO/~õë,÷Ç®Ø¿˜	È«=hï›™ïF·è’¦eéñX‹¬@mMg
nP˜’`‰…T!bÆ<'u¡‰¸áÊÿ;Áœ/ŒíCï¯Õ„í¦lNg†^×¯öQ7B„20üvi	R;yIsV˜Ûµƒ¡mÂU¿kJ&Ó6ÀïÏ@óù}–˜D˜ÊƒÒôs´KÎ¿F~Ò¦Ûğ£oïøUßÅ£Şƒ²ºÍx$Á®÷ˆ@¡•Õâ¡‰¾”¬3 ı¿ëï–ÙûèÒW¨é¡ÖcŠÌÓ³`3öÃÕäË^W¦ø3“ºôÕfxˆ 4YŠÂØV¸NîËÃèÿŸÈ7Rç>›9y	é'¾MÄ½ìó%åÓQ®~"gÕ›ÿ9ÙÑı ì+ëŞb­);ÛûÊø ¶xË­ñÈ[JFIê¾n²£&¢Üã{eXmî-æj°qÙtÒM…2áHj>ÉŸBŞsíZ¬Â= NVPV˜‘ÏRqù6E¨3d”1§>)®½`ào±©Ê@;wêçt½ø¬”Ëz 7ã÷éø.hpÇ3ø?ƒ‚¡º4*qk
½ğ°Ÿßñû¯ï"òÒÎ S"Øö( ğµ\-•¢©UÈG!6šeıkÈúr“RÇ@0¤›Gà+¹ÂÑZnÎQ,V\4Ø&``°–,xØKÃ)°?êÔu©´îş49öi{Ú$›î²<„ï" cæqnşxoKr·…á²æƒµ˜ÜGÇ Áé5"÷õ,sTrÓ½R•ğ°Kd››5nlúùVÛ Ëí˜ğûÅ³åÚr°­§bxª­tã¦ô¡ì6ìÎ8{DfK)äC>vKÀBñÌPØòBxo$ˆÚ`6ºÃ	 \€øMãÎÜ7L™8y®›)êÔõL.Å["áå³æášõ{#íšÀw°\±Ñ§Mºœ“ĞÔIÅ.” üa$ú?M/³¢DY-ğ´Èğq.±æ«·¤BµvÇ’¢w_´ÔÕ‹˜&¿SuKO6¾şÛ§´DE@â¾Îˆƒ2œß¢)*¶×ëö‚8—Ó%,,¾=Í)Şƒebu—c&d¡­+ÊbÅÕ,g nÜ Ùw&¥‰Ò§®I—¥‘ÿ[‡\Jk¿ïÙé†p-3;=PhNl|Å à§Æû:D]r‹Õ´>éFŠ©â¥ˆT1.TVäŠ´ÌÓÆê„ªT
Ât‹¡‹—în~që»Ø¤œÈÁ’Íz³çUL'jê†aõblğì©f«3uÖ>LÚîOŸŸLJML<›'ø“+_İ0ğ(‘ 	zû3Âæëœ2ğ2Ì‡ 3KÈ)²7IgUc[P˜ïpãëJö9Ö¯¸–nÕ ·42@çÒĞ¾¢/h~6ëVPy÷rHÛemÇ—%q3!ög‡¨•äëA9à‹oÄnÅ¿ $û#}àÛ›EÁåA«SH™Ç=cÍıÚ	$NÚÊ³£Ó›te;`æ••+jöaé3Êt#Ñ“ßŠåV`U,±x*ÜW…_Ô¦ÃÚ "Û
»«fÑr_Òª‡x¿¥[‰¥ë1{ÃMgDn‚ÂBÉW¸3?¼¡ì¯6R•Ï.Mé,mú€7ŒØ·y„ÿ²uWÉXA*Åe¦•ËY ßÑ}¶óßşP…êü)wPdN£6.¨¡ÌJ–# 4½Ü×”•ÅUÄÄê['¬ÇÿÃÈuÄ>ÂçMial),{'Çêñ®ko Äƒ|3Ô-‹«éú×µ"šUà,Hğ3í­šrˆ6üÉÂ`œ\C¾‹è>×MÉmÔã™bJå+µd)Úyrlº{©æ[gPXZ’„×}‡s*¤^0ZLHåÙ€©e6ŠØ¬ï>“HÕtLtîuUìR$œÎUÉ¥ñ¿ê<¤nZ0Gü»¯GHüII-äö$Ì˜ &\7°¸èÔ	DÚED–°ò9‰N—„bŒ~ì$ù
‹/æ¯f•YôZ×=)1šŸ&“ìKP+/OÖ7œó'TUªKİ†ºÔxCR¹w%F˜q[WTlH~Ú"ªà¹’Ü*Ö=L¥®F#ök8„÷è¢Ræí¥DË•­.d‘·Í¢ÚJ”HTYY&TÑïÊÃa=ê®ÃëàÂĞ¼›[üU«U£Ô
ƒ§™H¹p€¤6ºêå/šÃ]¡Sß„Q“åÌI2
ºí¼ÜjeKµ=äú—w{ß§†‚¾4CÊX'‡B©”)*j‘`x@uÀ¢UÍ¥”Šº’ù,¼+ˆ/¦!ØltÌT…‹ŒŒİ”´¬ÄĞoˆÛ¾£‹Xêãx(Tá†äs‘eFşë{äµ&4J•Ü·›Ãn„ÈYÓU¢
Ş8[k«µñ@¢«#ƒE‚^tÖÇ™U¦IĞ4o§ÔÀ$ãjƒ†¯ˆä~}rš”ğ"X¤¨uü€Gs¤ÀD¿[TêŸ¥N’˜ûÕäÁ%°nÃ¢ånû6¨;Áú¶±K}åj“Ûs™k«^;æµÃıî¯Rpù'ËYgõí¢¶H^HÊÄÈbÏ"åÅ™Ÿ Rá#0ûù¸…ñA¼dDMVÂNà$9ÍQş¦ú.`´„eóZÜ¬»ômÈ"ªgt‰š*"—z /Šs¯·5Úw;ÂY®a	|>e˜ş»²c˜èBÀ3 eÆœùÒ:ÔÍ&ôm
Vç¿ÙÍG‡\ÙÊí]É|Âßã1)_1 JRaŒ$…ğC–Ç>îœÏoR€?ŒLpÒvaæ“Sı'Bxx˜éj˜y
¢”¶Cn”xÂa_şB ñ“cE_Oøû*Òç{3K%¡Ä»r|üBMæd…9ÉNŒgä,Åà¬Â-ôüØ5¼Ä¥R*Néê• 3ËC8\¦8ËqH²6ßzîdöù÷h©ıJ¬™¦²1¾<T¯Oßïş³G¯_ëS™/—dp¼€ÊØ/¡…‘J<Š:Ğç% i¨]–É û`´SVS1à£	}4Jt{ØbÖ×„|<ô‚èÕ†áÛ	úØªÜ q!E]†’Ûjù€{Ì`Â°l9×r,Éñ»Áwñäş~tØß‚”p@'óÑ[*ìÏ¥É Ëtş	w“	`åR"XMİö¨H\IV}LhtÜÒ'8-jm›Äë­é˜¢C]-Wç·¥I¢íEw¾¾±ş:Œñì!ƒO©$aaÔ 4‰¼v¿÷Ç·İL9²&‡wzã®õªª	pÜÊ¦R`@¹sW+Ëu°:VÙSùÁ¥‘bL´a ¸Ğ¹i”bƒÓõq`œN·ãÊ·¶  ¾Éï
`¦ôgzû0²	vl‚ß·ÂúQw`¬€óÌ;¾¿äËç­*zNÔD÷›ºkÈşÇ?œ¡>¸ô¿´Õ6w*£V#—-.’ncÌ+”Ö3Bä¡-½Ä’çt‰rcıHµ—r$ ÈĞ_»8N–h‘;ç'ª@È 8Zê|.iƒŸíü”˜›å7¶Oo0uaX î÷õ2T†­˜D®íÌxÃ›©$ÅXiwÅR–MçÔ{5™üÄlIz¿˜×úpêGxêĞøœm‚Ú“—_¸EP%À]æA?*¶>3»’nëy+–úê&­ ¿,Ğm¥ïx
Úq¨…¥Æ÷V LÊtc9Í5/BÎÆéU©,<=sºRsY†Ã×¢A»ø)Å7ÌşvÖ÷£ì„/rßâódî]á³1Ç“À22ö§
ÿ¬BWáÀ†NÙŞãiQYs¤§[Ãö$¿aRâAİ,ºŸ~­ÖXŸáåÃPî·vùÜ eíl‘XjDµ“qjîì=èp|“lg…ek2¾­4S3°#>9€íÌ‡S‡U3™QéŠ,Ûİ]X<EGyÔÇı³k ®,!S±T<[—SèNy„Ù£$nA  ¯¢9Ş£ÉÖ6æ5¶xü s„˜/›X‹üxO4¸˜CZÙ‘*¾8‹¨¾ŸîX± 'Q¹ÜÑX>9M¥ı¾`Şßsöï]ZzFñI”ïL¿rns;x’î¹—D–¸ œz¶pşHÔ©Ú
Hû%£¸¦ĞC_0cÚXdJª"„› ¯À©6…8èTí—ÖÖ\o/.Tóòß”8(@„ÑÒaFL9t³”©kgEŞV§µf“RÕvøó6ÉÉÓ#)Pñt·Ğ¶C	UØc{»&XDÒ¯iìå.û»RVã^pÍ#ol´lDm_Ê­A£‡hÀ÷ìy[ñ9cfÍ@6nJ£	ùm I_>®Í¥ ¤ûLõŸRM*jqMCÙŠä^iHÄ?¡"ÔÍ×WDiFğ2R®g¯ÅÖ	8XS„[V%Œ6V'Ÿò;»Ôò±|àœ@uBÎ¹ªØ2åØh¥jÄ?bœ¼ß\«ëo¥%Bq™¾x¯ú=~Ä“ş!2›AãœBUäüàX†õqİbÁÁıÔå~½nNf$³_0ÅÍ°è›û€7Ì˜sìeş-‘?¦aµğ¸ÍªG~ÛtÛlš¿¿!'p‡—˜ÍE[®1‡DØñ>í«Ğì×¨Å¼Ìb)š@ök8EÃwÇrœQ‹O³šîæÖáß?²“`Gç	ç6Ê^•ãUñÃæbXğ9Ş{ğà}QÛŸDSÏ/ÒÿÁ÷ùtÛ"³ªÓ7R<ÖÌAß€Ùù©†Âbúµæ#kÿ"»ÙKpx¦›éş|Q<ıÚj]jN{ƒè,€àŠî—-yÖk¹¢&¹Ç‡­ƒ£î¸•âÕÔ‡Ö\O²–:"ü‚|hAÂÊ’¿ißSêqñ­¢zUoªƒéE19	QÌjEwnÔIíg‚jâLºõ7”Ç=Æy—V3Õ‚úT¯s©`ËMUëtÄö3Å…¦OUä··;9Šc:¹±ôæ,ÎŸº„šÜÉò¸Æİ'âVuŞÛWÿ:,‹Ù„¸Kyï3Ô£uŞ]ÀàëEÎ¬_¦·Åwáp‰í£JtqÍÓ‚a“È‘Æ¿{Ò+ç„péU×ó­f·íÒzĞsu}
·ûçÃ’Ä ö¨ÙLt¾ÕoyŞ¯‰‘Ÿ%İ¬¡ĞŞ,ƒ6šiİj™y=	„%»LbuÇîQQ…†5f?ñ7hCßÃQ©÷	}£uµ6Éãæ&×íÎ[¦9vPâRgÉ·^‘ Uµ'
”é"3c©7ÑVÂúô‹'¾t¾/•Á#nYßmsÁ¾²Órá¦¦ç7sJ²}Kl×N(˜ÕòªÜÙÀğ›-³–‚®‹şC}öÔ8àUx4ów‡K‘AÜ	Y¿´rœƒ¶:Şåê©Àu‰»pSı™–Ÿ–úØİ¬J0*»çTæ—l£LŒ*¡@¹œj¿€[>BÆ"~÷ûh4Ñ¿ÌÁEA¬õŸO²Gë_ †ù EğÊ†S}±Òw(Z…EØúï_‰+u|ôÆ·„Ø¤T×ğ0ŞÚüx´È[7¨mı™n²ô½zÑHEH=8É_óm3BİÌ³ÕpÓHåê.f—4%=ŠnaDxÆÁ¿çtùI~L*—MV)í¢Çæ&x²¸•Ù1?•PPÑ(±¸ë×S;™P>(º6Â`/IŞgäÅ¸¿n}LétËM/I|R›ûüé êıÓĞ?«Óğ¥yêìV œ˜ƒ`Äâ¨÷e@«ë3Ô¢`4BÕ#Ô[oòeX‹ÓIåL•H[ä1‡W‡ö›jèÙ÷?` C!3œ~îîµ¡÷àçÔ$ÙbĞÂµ¸+r€@ÿ"jÚö"Ö¿ç¶Ö-cníî;(Ã0?q:’ÁÖ³k%ØÉŞÊn&¯ËÁAÏÁ@RŞ©æ¡H#ÀVùjGåu¦¦œÔ¼H6îÄ3–;:±VuËpHÍƒœüòÂD1‰Í>Ût§êÇ"ú^J—7qŸõÊëÂé9=ÿ&°„hj©Ù‚P?~2šDfı¢«ZU€;©4_ßD…uõ²óZ¥j&ä¼0H·S¿§½Æ+‡-4wÕ.@DÄıç6‡O kö&$(@Yk…·ıDÿlÃh°Á"×4³á#b6/×„´ì Ûá„XÚkLlß‹»À?´r>°“ßúD„Id–BR¨¹6VU<Bó:d0M£·SêBéO7™—é#ìÎø…í#\º>¾µ&"äC‰qÈ½‡/®ÇÜ$“©Ic„:ÿê]B{J©iü°>íœb  ‰ÌaÌHc¤aÑñ•båÒPûİcµ%{‡ÂAGD§ÑX¡OõîÒ´†-Aˆ:Ûøƒà,\È°7„ş"jdVõ‹kìÁ‹UJçV1’¨V¸œ÷¢(õhÙ@s@°À![uÀYŒª(')Á.Ødb˜¡ZÆX„­Û‚;j0÷ˆ¤ø™§Ğ*MîôşƒìŠ Aì¶à¯Ç:Ùv†=r,igØaÈF8›*Ãû\W$/ıW¼,¤›ÅÎ¿«Öt‰oÃ»Í'Ô£1…p›ÄXSî~	r£]³X«æ	4ÑİÔÑ[å£Èt*)šhà`!4İçuA¤¤Ç›¼uc-®Ñ'å»VI}zï-eÖ¥¬¥#
†ˆ2G<•«\„´ßM²LÙ£¬ğ\½ ˜úOWc
ßÇë¹Ì¥óÃA$¼šlgQºXĞ¬¸íf‘F&Ú]âj•˜x	{ñ}0Š“µrØ±3ŒäŞÜÅ£ÒÜ&¡‰W†p«h¨Ojv@Ş·?Ç€}t·Ë-ÎÈÖà £óø>ÂãÆŠõ±xÇp~˜xJéª@Œ£‹Ü9‰‚Ûr4yÂ)F"gZ_çˆaÔ~G–Äc¡ÃÆœø‰iãò¢Eı×A(.CúWı×yÜ^öpo]MFU*lùic]°Á3¡şX‘Ÿ…dñ¨Ø8‰,Ò¯ù^ÿ¦lmş4¤ùeğAı5Çpº
´…/ƒ™ş8CT:´ü±Z³3:›¸‚Q<UŒ9Ì ó”“E¸ñ°Üş(5”–™Sàu’&æV²°/ı”«3Ç$—hñ/:¨¥[„ä³*ouŸ×å:B~«`çfKSAÆ-©S¬QÖ[æ\”:$×–úÕRIi„¹U]ábĞk²åKñ Rù53?³e‹MÍ(Í‚U½ıGx}q–÷&®_÷[ä Q®\?Ê†¿¹yÖİ›½èb;qÖlÙßŸENÖxå©\:œŠÜ4VFıaìÏ#üšÆ#it©Ô¨q8úDÉ¡MXVB¶œw ’GŠß³bJPtK·_b²Y“°¼¯=‡ºıÅg°1“f‚>îEt ~²ÙÙ*¬Ï´:7Ğİ ÏıN2t+#½½lŸ'â€†l˜ˆÅ‡3à	
oÙq]>A€æ2btÔ+)”éâ¿5Á\Ã†CcbÓ©šQşÇµúeëaÍŒÏœaÛ4ùùÔğ.F^”sGÛÊÓN¤Išõzël †pıê®¬.œìm—p–´Ånñ@k×°1ş¥Ù4£ÚÇP¸éXÜeyÔ…°MÑ° }çJL#f°Ù¾u{ÂôÒfY«IÕ¼ÊüoC©µU,CMé±/KúaµyŠ×@Õy„qD¤İ8í‘ fJÔœ ‰¾‹¾ĞÌ¸Šµãûsèó¯X²š*$Læ¼‡E[q3íÿÀkÇ*ğ¡*"©Ì8’`\íá‘ËRbPbx(#;çÜñ¥sGe¸(sóiãµGä‹Ø|$¬~"İõ‚MrWéœÑ– c¨"Nà	ËÉ!Th(f³Aı.Fíhv6G˜k?^±«ÈñÂcBËP¿+w@»%áÉ¯hVİ©” ¦É½{…‘¹¡„¨©A_lã ÙSaq4‚†ì­<å6:¤8Âõ“Ã«œÄC§/=åÑÀ‰‰á/}»H¹ÊÎşûd©od„]XğØ¥öyq?À¹†õ#ù”%›íÕ²hVmĞo^	K"RŸü©I»¯¹¿ŞèÔB	tªmÎjöË“-àáv]Ò…êK~$ò®Ø	~|¶{A½.FÆ)“ ÏzfÎ@˜êåæİ#^İê8›÷Îûcr]òĞŒqÉkìÍÌ@M´aÿ©Ğæ@İDZIm'‹
©æ+[à7ôåµÉh}Âª¦ÊjšaÇó¯eÈ¾Å¥’ñÏN¡ı¥U•”Eyï
>ÃRaá×c9Î#xâ9zÔ0Š4©î•Û_µ¨»Ö	”ÏÖNO*dS­ó!XƒKšMõ*!BÛw0Ìñ)Ô‹'Ëá9,—Vş³I\ÓDØÒçsCÁc3Yœ°Š"Fw@Õ•vûÆ)’6gœê–¦aK¶K*àÍ×[—%5~ü…FúD’GCßH‰vb@=h=º(°º«ÙŸ(T±òÃÓô6Q.>ÌıÃ3ÇğaÆ"Zçø‚ÄÂ°(56/×<ŠÔO0ùZù6x>ÛJÖ—¨Ë‡lğ æe`|´’”íX‹JAÓù6d  ìŞÅ×„^Õj],eÄÃzu=Gí­+ÛOå’è¿^O®k»úê ¡Wä,r¼‚†g;³U1DLu©l‚.'ô6"Ğ•ğ!|<·æo…”ÕnŸ™ÖÓ¦˜Á¼Şó¬š|	×kt´eNÑ¡»³ïùºD;¢ò)ùÖv­³Ñ~Ë‡¬¸äµG†}Ú«8€9ò¶eÒA…iÈ’;3n0¾zÄ@Kä<åÏÎgÍf‹P7P8(nWkR¿1Œ·ú)HëHÇ±ø^Ê}<b‡$’ù(×‹Â<¯2ªQ‰8øŞË
„•mÁÆE°.İ°2›ÊêãRÃø½ƒlù—‹']LÈyA0rõ´æ—Á7	é¥fâ`«ŒĞàí½Jè*,#Ì€¼ç°å]²\Maô4NÌéÇì-ÿaİSÅŞü¬ÈM¤“³ÉyË|Œæh’rpÎ%G‹ç$|ÿŞ
ÍÉ¬_Ì—°•ıáX@7ã›#€A‡;ùPa ¾Ñ4*Ûˆ­û“bi6-G§ŒÈ¼Teòõ[úÂ·ÆN‡eµüÁs¹ü&D(¬FY—n;úLÁ‹ùÎß‡ÊÄ7İvõ+»ñùè<Ep<Î9i¶k²¶&«+5Ó?K­¨Û°0G‡äI|*3÷bMˆvj½éäº+IÍÁ8N–ôq{ó—.Y­®y‡~¡Êòí<.;pmÙ åØ¸3¸[x“¤Ğaå˜@#‘…“RšØ—Õœ?s]ü´` ±½vp‘f[Z?k^fÓ ™×u¬7bŸœc ÿóâÄ¯†x#€1MFnäêªÃUÜ:®ÍÇÃ0vŠªOşÄ÷a+˜–]tc/©¿c3,ògWé°Q]fÜdÔÀ¯‰´«5Âòo\À5Ò}â’¸bA(R„‚”ÊOwß:ıÚ…á™j1"!å••ây£eÆ§9ª9|ÄcÒD"^nÀU«˜ºßÀ»£-â£ë¬Ü?ßhÄSÈ‹&LÂ¦f{+B²×YoPóTÜîµ{ 
İ}y)€!h\š³P9P~Ç€âü“øÿõzk­ìt	@è4L‹@Ç/Qyu)ŞcàUjpÕßaˆkÏ¹>87[×†ÚkNä¾Êää­ùæä¥|M.q$HHWÚ1"Q3ùĞøF°ârw(+ÅEßUÉBŠ8Ò{Ôd_êd÷¡ig7X%¡(ÒçşÓfÆ™{“Àußgé|ÑázŞ½ù1õèçõ#zç~ŸéôègÇÂÜc"nPÉ›.^å.ã ÄÛ	ÄNÿ%OÏR e›|c{÷ÀOı˜e?ŒAC£S\˜‡4)sÇ)?80®5)?İA‘>¡ÁE*ûºtQ§âñW¤,õi­E>jıX„.”H*şïvóÆdµpúåUáïÄ±üâ…!vh*¡—ö	®üWr¼¥|·˜L£N«J(2û"¿„¨^ç©tøÆüÊ3‹õçY'ï\ÎRN¯ÆY0dÂÕ[A7Ö}
5RKÛøÀ 4/Ù¯}ë@…è­ä¤¤Gö¢-au˜ü·*²×Ö‰ŸøC‹­à.)æByà!¯é.èÓ{_Hô”û±û7c×Bw‹PÂìêRÅÖYykÑ¨Áç
RÍ;¢è#NòßÆ+aöûTT®ïoª¬e-éÁøIŞ*Ucc£JQQ7¢HÕ g¦å$h¥`ŞQÅ¢H¦û¸4œûHà¶³7p
„KÜ8Š\‡}JáŠdúuğ«ü¾èõntà8íˆ1`ëCq uÇb?~j; $
©f&˜d¾vîdü‰¾ÄJBZf¢VQ©çè.²ğğ1ááCò‡ùÙ–0gÕéÊìfœëñl´,ö}hs]4ıÊ¨{t Ë‹ïN¢ßr©-J²áTòäxÆé·	ıù_~ª1ÄK1s]ÇÌÜv­šÃ÷‹‡Ù¨°a¦XDÌUh	Ñ#Ù`Uşƒ8ï<Ô¡ß›q"ğ€ƒ)A«G,´ÄvkoXi«ç³‰ Î'VÔ£†5i§®¡æqaª,Ü§^ß Ÿ¤àææ)ÖU]BœfŠ§Ú=Xê¼#=úÉrOŸ‡ük¯¸Ä¶}dº„`Jã ¸hˆCÊ4gÊ@QA¿è“¥	¨&Û¾·y`¸İ1ÏÜ
àğk*2%²‚ßà~Šn;€À<ùò_·²%rJMs‡ß—4xÈ)ª¥İGµbç‘U´{Aø }x££¦$A1vûYüµ]AÈ¥Ç¼2ÖßªŸSÆ²Œúì‰¥ÒÁ™ 6k• {-äÊŠ¨=?ã1Ó|ÙLZn¶M0f›ª@ôJÍ¾&Dw¼%–ºEpY‘ß|Ğˆ1©‰yäJÂãéiƒhØ@UÚ*“v|§ôZQ0(]Ş°¶.µØYbÂßjØ(c!ÇÍ yÌ1ÌÅu$‡6Jw6¤y›ÚY4˜ÁŠ|tE`+<ej'Çßp]¸3 Ÿ;Ì#oaşÑAiËaÆzûğ¹ú¨Û7@R?ü{õ6/ô¡ÈgÖÚÙ”¨üÌ–ØmØ¹j3óí”K`ƒ»ûĞòã‰	ÕO\¥÷Ÿg‰¿{´VË=hwj+š6Õ£U"CŞs'T†ığ¡qÿ}Òà%´IË’A‚:¢ÖÌ%>~(Ø0”[n„¡Nü‰ÉÒşÄ‚+Š»u½eò“w‡ŠRX\Òì”TÅ>Ÿş%4[´Jzpú;ı[ÔTÌÈ4eµBÈ¯fÒKgàÛ!)8Œ²@iŞúÇû¹Ç˜‹,>CfÒqwDŠnW©³z]‚‡pÛâLÜ‡DJ5ITÕY©êƒpªÜPÃ
Š')e hdİİêX*)¬5VO¨ö*öõÀ$”ğYŠ¢ÓÒ§æ%•'vÔ#·pÓ§ş!İªºmSS
&nÕ	ãòÀcpCbæôªüjÜdõø¶úµ“Í„mñ„ÜÓó©&‚±é[×…€z=‰Álál#<,¦[ß¯Â#^<¾È;ú8˜ÃtØš²Ã„ û”:î»oÍğd|HİŞY9® W ß7-šiõ —é}C/,‘üãRşÕagàz›÷P€…=»GaÚÿ46Î%mì‘“ ´z”_kŞ¼ik,^…1¶5u¹EÌ3äàİ,İı”²Aq“"ë5~q¹¶³§¥@ğ)90>kª,6VîíêÚ…UËáÊZi«	İ+•c öûàõÃ&G|­‚•›Ø¤4?ëÉBÿúEç9ÈöËdÌMÙøoøÄ
F&å»ÜÕ$ÄìXÔÆºãÿ¿¬Í'@=vBĞ!-5ívô°:†6©NâŞÉd-ùgo])ŸÑğã£QikÑ3õâWæ$òd0$€U””üÅn‡ÂçŞ5èÂ;‹X5Å4E!
ê~¸ümùïI{˜Š 6îZ+¸ø¾dT[·Â)S•Úå¼5gÅ/+Ö|wyKj[iÂægrd:DĞêÏ "<Ë|a,Kì$ÏUgO¥9ıd§Ô$MM°œ[“æAnãğOşö&yÎ)Wk®ö$;šä;ÂˆÜµZä1Ş Ş¯U@i\ø1©FtxUíugp„¨F‡-Dğ¹¶­Aî#µ@òcÍÕ†fÜÜq`ï,z+:¥A'´—S›Š¥÷BÒ}½ßÕøg¨êÄ!ÜAd(Ë>s¹“EiåRÒ.=HÍ+åû§Tš¿i×Úxk³*SJëlu˜HÄ±\¹:ev|)*Ş0 w‚Â5èïÏv+¡gš>	¼b)zV
°[Cö¹¼ú‚g«%Öš&\Á 3•/Æ!!×a¨Ïc	@oï“÷/FÏ×ä8+‰÷:±[ËËM·Ú0noèlé(ˆ¿¤@¡ƒZ·Ë†(ÙÈ¬=^½241;J$8ª2y2æê¥>lœ©³;™	ópY #Æ„'O•öÒçÓñÁQş“%ÉÔÊ=}!VŞ&Z'n?Í•oAÉ½òŸŞçb ı¹nÎ# ß·ô.ÁìcÑkwz>æõ³ı/2!c7}E]"]…òàµI¤¤²’”íú•…ÂÎŒ‰Px—èü!dµ«Ì"—$£Ê_á§Ø¦…,7#¼‘eáµÁXw	ß¥Šü. âØüV™NÂqûnú…}sÜÌKgç*Bğ@šæyW­¬ÇàzË£Ã>`°F’€òGšŞÌ…Eêzî!Úöº²øF™$Œ¾ˆâH€ÁkQ¿×ë‰œe£«ç5Ó	şÛo=Ã”X6‚d3…<M<aD/<™?gt=„(C¤Y«›:k3†¥)9Kê`Ü8qœÊ¯Ã?50—ğôü¯I…¥IzfôèDgà¢)vÅC(ÇşX”C0•¸oqTWCİw ¯œúƒo=ÂŒEŞ®Ÿ<•£Z/**İõ‡¹ş=geŒŠ¿Î¹ ¬Åzâ`úÊÜ´Õøk4t03áş&+LàM*AñFr˜ç	tŞ;ñ¯èà ÏÑOR8K@ã¿ùt{ÚŸZ7’×4Òæ!àEğõĞB§êöå÷§ƒÉóg~ut¿N©³5yí§äõN¿3pßå2tË»hl'Ó‹X™—»ÂFŒæÏ4”hu eÙÍ÷{xÅ„-óOæc¯ˆ…5uÖ—§š%‡¸RØy>Œx¾Ò*Õb<§Ág>"¸®j\™ÿ÷,Ààh˜éûâœLÚW$‰tWoK¿×ï(Ó@ñïñ":ŞyÛp[˜“”¼ÌlÓdó•„9€ƒ:áØ!ïw7·e·VÑãJF¾Öî2ØbüßE	T2^•ÄHîÚ“°3nöƒjj=Ğ¼ß?|™•ë3dTvfì; Œ‰0œ§×Ó&³ bXá4œaÙc:ô²IÌ"]±Œc¨ØYÈî¦pñÙ¼Ø@“±Â°YĞBÕjû¿müÍûüÊ’¥ŠOFL]åŸJ¸í¼.jZÆ½i8âüÿ4Á2»Ûz{K|)óÓŞÎÂúHü"Jê7}²Ï™›³ÁëŞRD¬‹ø%‰[®à‡ušIQSĞL(gº&É›6OohN¬ !ä–%–y8i½şIXØ±0TVNÜ†sìü­Ö~qàS¿¥³ª°›O4åÌfO´´{q„İu¹{œMñûğ¯““q·?+R“Ÿşï;	I?¨J?ŠÖMB’N"Ù©8ßÎ¾ÚJw¿&åİ½O1Ãa÷±ò°)=÷òJiïÌV&Q\,öUcOUº†Fu‹Iù°‹òŠ›Ò]ã9”Q•6şÅj1‹ª%ıãËğJàLP6³—0#‘¨ÿ”ñC÷Ëÿ#ÙqÂm®K0Õ‚áïÖ`8,Ã„0ukKqXÑJ '™\ˆà¯¦ °Òxş*ÖûV”İ¬˜×pX¦[|0>o-ÍíæTHøœ9s<Ñ¢Œ…¼Yc—›Ñ2İ\Hƒè*b²"·óTˆJ·ÃÅĞ½z&3Ó«ÿbt1Ó†/CÉ.–O'v#…Î5ÿ¾°È;-ß”îıúHÔ.%ØKaıB1tRyVZ²òMÊ¹÷ÊK åğ‘Â‘ñ4iúVQG Å_L#Æ¸v#Bh"Dc·…ÚD(bø€<qÌß¤AÏı8úeşh
—QH™ÎÈ°7³¾¢¥n»ã–óADo×ŒlÀäıÌèt©ÔM ‰˜ğD¥e°:
GÙÖ³qY“@‚qÁ­Sæ$#££ìfT™ğí•&–á:6‹U¼à:YÌŒ½ì»So¿§·PººÁzZÃ˜Ò G¬€Á"¾Ş`£øƒÒ:’µ]Û~ËñÖg¶«c¾³‡‹ä4Kõå`²€ÅÆŸöäq•Q¡‰G«éÙIéaíÒ"Wéê‹ö\:ÙUá¤sÎ—Qàà}Ô^µì˜8ˆ
jGÖì4oPq·È%?,Raêş*›í ,hñ¡aİe­­K¢Óî£6×@¶&¢ÓI_Ò›¶óµFôö9ø0£ˆÕòêƒøÔÄ.´ø]ÖCÛ×®|Ôoóİ-ı/¹ŠÄÃ|©îVÁèõëàÀÜû3 A4»Úî!¢{€¦’…t3Tº«h_´û©*ØIÕåüS<ns9c"F¶­a5qüddõ×ã A®ÍºÛú‹’³|ıiÒş
DÁ€ˆëjš¯nµ1Ïû¹›`‰¸K<Ÿ¬¾€MK¢ñ–†¢¥¯õaOÎ¾¬t<iTá´tA‰ñ/“ lâC§#WàİRÿgÅ*+’ÔÛ¾­ø€3Ú/vÓ¾"TçoÂ6SÑöØğ™%Ø:±no@v·œòğêgü'Xl³O*cxlV§Oçû‡›¨Õ¦ÜÆçÖŞNMEk:ÃHò¯~×fÎÆûh´f%T˜.¹¤Py&µñ=á¶xœjÙßÊtœ²°v™gãä
H(Üæ|
è_º9;¬ÌœĞÜx	ÉP0â‡~Æ–ä0ƒÄ«bø>ˆ™ü=b
–æ‹íöàÑâ\O@×]£ŞMæÅ|Gã1’ì¾¹Y|³-ÄÙ#©
®ÍRy&Ú®È½k´j¦^f—m< ¦Ën?¡wâÿ1xö{œ&³A'‚=…6Ô|Ñyj¨"ë-”çH”İ,‘òÑğŒ#/	å›ö¬±Œ~à‘)‡uNzı
EiOf<l*Í€N‡¶pägİäüÉ¥‹ªùTŸjjZ}¾ƒ”oåÇTÃH±¸Ù_&ÄoÒÄ¯ì±	LP»Fç±¡ò—Hb(ï]ÌÏ3…k*ßèïó*Î]şüüÜVş@–*>Æ@Ò(£{ÍºÈa)ßM2ññ$	¡B¦±£ÈIŒnkh°c2Øˆ¨´ç%cÉŠÆu¯ÊšXZ¯a^îğ	8’ğ/Nç0ÜOX}Ñ…o'w\KåjÄuÙ%¯úlÓ. §¦¼HêÑMÍZòDû;à?Íáğ˜™p‘qôıuE¿c(ä{(ìEZ÷¬+È›î¨ª,‘W¾°>#´ÎÇÇ!Á µç”?æ!ôÆÓğ…QÜ@kšşxk6°·‘“D†5¦^BúÚi¯%”Ÿe½Ww$ú8Ìk§±yiš9Å÷6EÖØ?ÕÛ©Ø°@™¾\¢cæ¬\:úÇ ¾¡ÉŒ¾Ë‰dšÀ#>uñ3>¸ºšY-Â|”ùRS‘Xrû!i‚gœCüñ@p	ø¥×\‡ÛŠı‚%î]\ÆËS$D¦ÍôàÎ4ßøÚ!m´XPp2ÁqÃZ+GIlùÁ2R¹£˜“¯ ñMfGù>ËšÂix,Œ-Õü:²‹E°Ë·íŠÒT6Ê³g£¥Ñ§5fë‹Ş¶üJ‰I3ÄQ¨–×ç3¼¢
ŒJˆ¨jŞ5q[}+X’ÿu-Y$õ”Ü†Ã@Ü¿kjhGÉr«8àıªùòşõ!„±ˆul…ãd™lT³¾%ßÎüÂ¾&O2@#İœ×`Gùt¡ »ÀÎİPåÉgPB®`aÇãFÆm1Éoúş”@Ì3º“‡ª—Œl‘±ùJŒ
z£#øŞì‡1n'Ê¶Ûıj–ÆXb__}MåÜØÑÂMà$ìÆ¥Â)
°ÚKBÄòß TQ.e® 0ß¸
“ÛÎBÚ?ÿf-`Ób|ùL‚5';ŞÂ©WLø¤¤Ò²l†YiGÁzÖiÒ†oş4Ö1E’½M}ú G¶¼7<b2×ÈÄ–ı<¤†€İ]\êE÷•îÏˆkoÒLÚòj£ª‹‰[ã»úÔÉ\ŸÀÚ1%ÄšC:#ñg4Å8CÆw÷B@Ì¨¥ q@…CJğ”Š 5µ‚‚çş12ú‰ØI<é¼ur&•¤•„•"şA¥Võ¿PŒvû[Şé‡’mq´°<:“£$˜··Ùšè_k&‡ıoĞõú!
M”9e dëæ…UP¦Ğ§¼âPó~àÅhÙåÆ³C‘S²b}‘ÒO½ş¾V«u«nšì1Ú‡¸D7Í 6AH«šS~·c÷FZÓà†·Åpvs»»Øz“ˆ_xÿtŒ®Fj#DBRê'WFëèfƒèÂœšïtŒâÎˆw¿")8K	×À|kš/«ĞUadšWí™é-xnÒ>*BÛâõ2 ‚:yœç½Qz$O3^ÎÏ˜‚ÈÀÀe<*5â†æ“ÿ0Dp<ßĞ¾›“7şê-?ğ¸^«œ}`ô:ËÀ‘:û+†ë,ÓÄÀŞ#ì*^e0fPá$kŸfÌ¤2Kæuk4›¯TÜÜ+şÒª†Qµ“€yŒwb	 UœØ§èê
Ãôfô¤b‚šâN3GX@¹}9âÁy¿õ…	£¼Ñ+›»ç"‘DÜG2©È?=Šš‘kº¨Lä]À;:åqzgş”bëU›@tk*‚(:È¡ô­Ma—¢i±íõâ9§ßCyª<Æ×‚€[ ÚäË¶İaıWZS¿fâ†ƒ‹Ên8(¼j­£‹—ù¶´´ê¤À˜¤¨DèİV³x+ÆËM±’Âd/³—]Lv¡KG°z4‹†ì«åC†P[?°°8^C‚ÏÀYw´ÌÙ²THh$¨uöˆ-¾ëÃ~}¦âÈë~2ƒ*­ü¤‡Ú™´çzA™‚9A9:¯T!´ŸZ9—q7L`Ü‰‘ñßÍĞZ?¹:öM”¶¶Ï•/ñ#üUîÕk|ªr¼ÛŠû¢EÿÃŒ3ò¢½±GD¥€âwS$Æşf€û;tòûèæ²Ş,ìÇ¥	bÆR÷!¼ãh$ùÎ*¦Š„°ËòŸ’ñoY@…W[¸ıŸmÀ")ûÛ]P‚ÌªKwÙ"¦»’xh{UnŞ¿Ÿz”“Tn¹7Ûh¡(‰w¤ÆÅÑ}îCjÂş9S!ö‡YhÄg¾¼a¸é%JûLPdJêüìİ|%?n]êRĞÀ±FhŒWÃÈ0SÜÔBb›øFWô5Ç7;âbö~M¬vµ‰†È¾¨»¬“¨k6Ãt[yÉ
m~Ò»fÑ2xëf7°³¥ĞÈ‹y_^‰Õ=ûÙt~ô—!¤±HwFı–=„"‘3â¶5T¿ZŒÓ+Âº3+”ñŞÈĞƒ¦¸6I:¼Ô?MÕµ©J¦˜(J°ÿahc'\:0¨jö%![Á‚Bw@£®…†«ñoò÷·<i©Ú HRÀƒM>mbV4xô^–í9ÅÔÁä¼Xy=µ­Ó±ƒU?öí\WT½ñ>‘ˆ¤j¢R›Ë9 ¹Z«ği ¸´µxJk‹[ôÑXé»Á‰™Ln$…jo†S/é77†Zzg¼„1QrŒ¬g”ô_rÙ ƒğÍ›n”qnQ°iÁKI¾á6åçn×}€¨Ï²«ÂÒâPÿÓAqéFo3Y Â(b#aQ«ô)ÒãGër`.?½[J›:3½«N&ç²) bå˜¸Û>lrä/V×O.%å™»«ƒúöåº[_3xÔ V7ØFXz¯2M1ódíoòN×¾Yk‘UÅBGGë"ê{şüM8¨›ª“œ³UœøÌ¿U-qLé¥SÀª_WQ>tBdMïÙ××aÊÌöxå¨I Ø‰‹	µ×/GKÅæ™ƒcÔAY+39m;ıg<!?JÔ)³Ÿ4oÖÄÖÆ
g¿ğX®)Jœík˜R=¥†Âš´}ó6@¯Ò9KRÔšOö`¨{tÑİÄ,z©º)"éÎcÁ#0Û¢˜‹xòSbı1±pÓwi"tO{	Ë ALHu¢eÍ1%ø–äBKÛ^6ËoBY"¼~uêHƒqÜm0 jzU³‘‚õÂëyƒ×ïUX3DŸIGª™/H˜ÊãÖA#£8ˆ»g‹§•oñ!íÌßß§Ó˜‚ñFä×ûáç•õËXJÛ€Ÿò_|ÜĞ4÷¹òã(Îå˜Dy$§. ó A~+şƒ5#¶&„HP4#–Ôæõ¨½g\Pfæ›h7ş<¸còC^¯ÂYuèÍ|9L\ôúÇDzNÕ‚äïÍ5<Ã ;DÊñPA£/]Ìa¥Š£e¢ÎˆÕKÕqáPO¸•~·å;å‘¨J1œ”ôßó×—¤Á6ü†„^7Ò—È2öbm¯ ‘rŸw@?°ƒpğ S!jS…Tá©—…¯/ŞH•Ú#¶O5ñài^h¤]_#éõrg#FçÖ4Cêè#8wúdŸNy­møö•åÈ¡¦·â£¸4Üm˜Y4O›µfURuÇñ <ÌPo÷?	b•P±42êŠ4/‘¨©¥}4YÇMµ>òšTX‚ôØäskz¾|^ôV¼p÷ŒÄM5J‘©ÛêAòÆ¸ón'‘Ïƒ|œv4â;?À;àM8îÄ°ÜÉÊ:İéIs1ÎfÈË©zU÷Yrİ¥å¥X“À¬Xvf'‚ƒe³6»rö*ã v²¼A¥+şËd¿>‰(œ—ƒÆ
ã²Çt‘n|İ°ü)ğŠ =ã³}J¸y«—!ƒèl°ü<‰ßœ¥
.³àr-vÏaj°7«A
`²W](İsg}Vu8¡)°x'ò"öğ™¹‡ÒÕuFoş.ŸäšSdB;Ñîe«Í`oÒ`9u-”xiiç&ŞÁÀv&ÓïiÚĞŞhœ\&^¥|qM·Ã[-¾mUİ»‡Æ+(Ä`
”šãu¦¡é@ÿ5|™i»†ã²Şä¥ãŸ÷G{x)W@Ê`#y½Cbí§½6˜"‚¬°iS%êy\ƒvÄ®Ÿ?À¥ïéğ`=æ7Øi(oÑd;1‹°§ƒÁr¯²{,Ç‘",«]m†‡`9Q´&Ó(6‘{JOëºfjmúÉmèh’S14—E†àŒpQ~­zS8v>Î¥¬”hìäà> >DãË„dı/âª[]5?;˜ôÖ|¤j©’Í+ô	—
É¨íŠÄíY¦_%l÷*–9R?\©îæ”*ƒrBkë¯aŒX¥áfy‡%nâ0@‘RàMJÍm×Ä¹.Veã›£êòAbŒb~/y
Û®©9‡€—X¯FÒL±YD\Ä‚^¤÷ŒjT6‚saE?´‡â†?º<àc
Ÿ»*¤ŸJ™²@+ûˆsv‚Ş)Û’ƒ*/»0ÈyAİ÷„c²ø|KL@yÖş ĞÎjÅí!Ó=âÚEd?jeĞ]íƒ÷å+ƒ(:å?*¦'”Xñai‡İeYÚR—Ã¿L" /Ğ¬OOè¿ÕŒe0í•£Ç·ÕİG#Õî@=mD
E£²n›p|ÙÚ­¶•Äh[˜‹‰òÃ¢ÍËC´ÑíÆÖy-ìç‚û§^Åôoº]¡'„ûMòiX”‡Ük.ÉĞ‹ïI‡úR8Ï Ëí…¥ â¾{³MÎtØkïa™³µ´eqıÜıãùÒ³ÖÙ"<ë0ÍŒ$¹vô-‹öğÁˆÉ¯­…¦3û};S« ?úıŠx®=äı·ËZ—òE	¾§VFt"ö„Û”@Ş³—Œ§ËÜJ¦ËiX°mÙõæC/)a¬ô©âÒ¾³?Z*–ƒ!$±Ğ9wUÇ¼z$uæeÌ*‰LoÂÅë¬	ÏC8_Z23#•Õj6RÎ­Îht•­_¶c!‡èŠeÆ4FŸ[~~Ù•G’…èÒoÛÉÅğFŸŞÎ !£ß“1áJ<fG±¿¬ØfÊ|çŠUÜµ`£ß†Ó¼æHŠº%õ}Z|!úÃÁoz¦Ä´k	1å²~P7œıœp1:SV+@2ŸÔø`ÑQ¼OLF ë,Û´d[sz]vÑÜ$ETy4Eâ5¸Íç F³Š©öQÂ¬eS¤1İĞ'&½×„üUé9{œZOfCh—DÊµÜï!8-³ø\f¡”ûs3ßÈ}Ò'ğú‹c£ÕğVÿ.ÀöÿF•DWÅˆr:™ûî8n1—m¨Í˜„3
x=&†€døŒë‚€5?tcÙ.˜Õ,MÜøJ®v(FeÙY©èû·»|&aQ'¢“_qV†Ôˆ+bÒ@#ĞÄÙ.3˜ÅÖw©úãŠ^ZÅ%.ö’†×øWe^MÍ‰ŸÇÃ+q“T…¶¡}uhÜÚ˜s.´PSùïJú#äHX –]¤X¢|	YÀ"iv6‚WUÒó]ÙJjÚéª¿Mu Í>ãÿ/(³Z×Âmû¬EùBlÊx´¥–@ööœ‚$H'NU+%Hã¿¤‰ì\CeíÔQÁĞÑuÁ`ë5?˜¼‰ª¶3ÛÀ1•ı•ô 4=¦L/]ÈÂs^ œĞav·Ó!é<v#lJ[œRA|éò¸~#2S˜öî¤+¶ùñ–Sç;ŸR¿äYğÜ9©*6¿êw"D?ş¥nâˆâ­$ä²±«¶^YŞÇT¾G–ßQí}z"ÿ_È»|·•`‘GVüR€ø÷Bøµ%
ÍvîtVyš[…õ^¾³•"ê½R	ü’n——¼Ô1´†×º‹p6ÁÖ’ºgğå·‡ ¦äÌ	À–[.ÉïªèDõN>«\^ŸKxÆ¿'¤`¯–jD·eŸîí+Äš-©;k®
Y³$1ç›£M"¤‰rjºã¸,Jy²mÜmüuñdZÜ†û²ÆÎ+¤Zóe¥@Y0rÆâ&X›ÎD¢oÇP#ZxÌúzº=Ê%ò=dbzÙòüıê÷Œ·yÙ{§ ëÆğ
” 	 ãø5·Ç¯CxG3;Êj~dè!°K5,°Æ×‡ğì‘7)0Éï°ÆJA@ç^­_?ëJcå‚M8OqiEvô¦Ê÷›xJ¾ÆAÏl@ i7É Û*±Z®fÊµ«œ¨ĞR³ÃFéî	«D³ÿÚ¢#[7Ùšåõ$¡Z­ºŞÜâ…Ğ¸3¿øs4?åßÚ8ãI§—'$d‹ğØN®JewÇo=Ò™Hj­İˆŞ¿á_&FK‚Â ªyc×Â/nÔÌ‚óÿõ&š(Ú9ƒW~÷ˆ‘øŸq‘?ˆ‘ÙºR¶N»LÒPš[¥óóe~~WlTÛE<…pµÏ«ã‚[&Ï…´¥¨6q ‘ûE|ÕCè®¬ÕŞ¯äÆı§Q	ñålûM*k…	9ÏNÅØÚ?ÿ 9næs2©›!&gáÿb~ÑnUÀ _°Á¹„øß!„Œ{‚C¡3øëÃ–wèc_DÎŞ0‘&‚1gÊ-éY'è2ÈX-Á£œÿå…)UĞ*÷K9 +Á·¨D!^)èÅşskÔÙ\ô¯
7ªSÖGMù†§!°Ò÷+˜*ñÿ¨-øŠö“ŞÁÿŞı”D?yÊl’ıåŒvö¥ŠOHz.#Ñ}½ò’Ù•ğZn™-;r¤mÉåoªİÑh›šÔQâeÌäıõœË‚u§_Š)R÷rû×…b•ú ÑøDHãyó•A#Œ]i_•æô~¾zûO£*\®•³{Æ°?ØŞÒ!_’Ã–Ï7}‡…ÀÉâÈR…Ø$%kn#
3×.† nSU,ŞTMgU¿¶XúVİÎhC7šhh÷—ÜÊ‹èq¤·‹x$äa˜yÜNu>Ñ“ñQw¢[oÌ5I)¾3M!L^=Ï4zç7Cşäz+Wäe >_œÿlyJì>Õñ»*æÌRûÉgíiR•ï„†¸±jüÀàŞâ Æ	a7¦##‘Æsº„§ìÏ´lü<Á³ºàÎtÏo"_YXí™¶ˆèúŠæ‘>¿˜°=`§€ÍGô	{:¹3hÎm(Q™~B!‚K™N†¤fÏšRƒV®ÖâÖT«s
ÀšÍ»QI%ºİé‡gUAÕDÅŠå_ğ¸‰œ634„Õ ”±Y²ƒÜ•Q®£Ğh­š\µÈªÔêV¬d¶Ò»Æ§µàµ± rô>r¤/äÑgÜÈÙÄÑQ#¯C–oîSĞım_u'‚i¡îãQósKéº3 ´øóÇÄs$ºOqç¾‡äÿ·1ÙSâ’ÒĞ\ÃbDJò¼CM1Ğ~ûëÊtúIÁÛ	ÀQhşÔíçCÏõ¾U]{Ã¼Ïø€1>®_‰OÕË¹h:Í^¶”jñ ìÏõÙ¯bä®íW-B?„!8*Õ»äûÈÅäŞ'OÌ!ê”‘^ËT«4Um!<Í™R"šEÛÃßø-#-ˆU ‡Õô&¡-§óá2ï€×¦Èr’ßÎĞ\w)îØ5Pˆ‹iY„|×v©öu¢wrÕJ™U7XU³¿òÀ´î%s—¯!ÓfŠwÈÎÏ!¯²oÛSŞº?«Ï‘H3;œÕ¾˜âë˜Úöı„m°ë;NÏ\Ä“Áe³ğå˜XóğğĞ¼÷ëVJ™î&kè÷²g`VæÙ{Â–Ê‰æ¹‹
Oº¡Y·Ç3ÇËö¢Ğ»E*jš0!)inı€4?OCg’ğ™P¾CxâÌ hÖƒ—Ù‰Ä®îÔ%ó™*´é<¹ŸèY(¯Ğ
«IExbõ”æ«È“×ËæqNPÁˆXsH5¶àBBâùõçÅı(_`/6QßºL"• Ë°¨­¥r2  Zƒ:ì«£Â Ì·€Àà±Ägû    YZ