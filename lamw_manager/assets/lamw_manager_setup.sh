#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="371978385"
MD5="0aacd874203ffa377e4ef4b71f3a62c7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24180"
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
	echo Date of packaging: Tue Oct 26 00:45:12 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ^1] ¼}•À1Dd]‡Á›PætİDõ¿Rk÷Ã™Hø\èÆ†Ê¬^B*>F;2D™ ìúT–«’îHe}´±¿©ít,°Å$<blÛ5¬šñ#­x[ÿ vÌmº¾‡òø]Ÿ•Á4”e+ƒÔş‰€lW·=•SÖ¼áÖÚ×M«£ÛÅÎXçşÖ¬SíÄÅ.Eï²w‘»¾jóCz¬ÀGlå‰Š
GmÚşy/§‚›°2÷«cÔî56c`Ç	vÄ`XåÜÄãqã˜_]1/a.äÀ€nàv‘³íêoU8üğ´OÌˆ~kR/ÌLß¶…¯şÙ“`ù}şX)`c|2G™\°®„ù}B!(á¾e7Æ¢aVhÕ–8¶™aZÊjòpZÍ@ÓjÿÙá¨ŠwÑá•«Zjó_ÍîB9ûÉ:Ä‡ÍÆæ¨â.eÙ¿­‘~ƒ#Û€èÆ»Ã¯bE çO`”ü¥G|¿å£Š| „\­öÙºÉ1ÿ*Œÿx‰Şépi«]D>ò˜©@€š•T5¡ v¿åÖß şFĞH…Ğ‰Ò,Á]?ÜØ_]†b†NºõÙø>ÒÂK áÿ¯…{‘2Ôâ¼ÊÒ~di8ø[tF-g”ÃÜ#”ıÍ}uëÙœ£iÜ”S~vW<ÁœH´ƒ8h3 Ş[}“ÚÍ¸oìq~•"9›ëV6qÁÂ’ŸÈmİ9šD™I@[ü¸D‡­®ğ
Ãg®"ÑlìI“€Œ=Ã&B;Ê¸®ûÃ±]TÊ·Ş«•~¥e—²xÌÚeŸ#òÌãı¾c1EzqÔWù+L*áä¸gí¶O” ’¶×yŞé˜/¿2¦+Ù¶vQaHdßwîDá®º6¡$8}œ­o—Úp˜LÉ+Cbÿ°–ëW´i „22d+ïôä©Ö¼È¨¬î±õÄ¢VNô­1ï†¤›¾trÃBŠ(R°_TÒ:²&C¨énÜIgª•Ëõ ,ñnªAS³¼ìÚ4{N|vşmHAa<ÁJn§2üëÚs /£¶²5_#íH5A½UHÇL%	M'À<<?dEò~–óEÆv¡YËğb¿­æGy.4™,¶şVQ$V¦9í4E¸YĞŸyQ
€Ó·ôÍMI®®îİŞÌz{C'1!»ó„ù¦’+Ë’HÜ, ™dnŒ¾Ó—™ÜrûlÒhÁqÚ84	_æKišëû)PnV«Xøî0I&ê0Xç	Ã³z*zö³†ÊRñbu>YJêæÃÈ¾ÎM3ZÂÖˆñ"1TXŞ?8
üë[§(õ#(>nö«¾-•ÃíiÔé7Âò¾ğcÊ~D¢¤œ™˜¤ç{Ù}+á­å69„gÔúd´˜î>ú²¯+ñxÊÅVàå6n¬äi,¶ÒÆCl,‘ø¢oİ†zå(:Ê¶ªY¹dA¡0=ñÍñ„h™¢¨§µÉÊm$©ÃOÁkI”ìY>ö¤¶æø©%™VÔèÍßâ€w·Æ˜{Kc»‘ĞÏEJ=’òŞ–yú·dIEi‰ÅEß÷bı(ó½¾ˆa¿ÀÛÿÄñmHu¾Êo—y„>¬3u
ÿ§¼oå^*Úä·±ÜE) ­+Şm uæÎ*õÇ5NáÀf©‹„(‘µUeÄÇš!C{Ëìã×èmÓæbÍûE{ÙYYOoyáõ¦»cşÊÇ²:ö³¢ŸX6M¹>½vÁ©ñì£NıwW:Ò/ï›] D6cu{ıÜöe1§dA!f(Y—ƒESë†ˆ¯lnBK²FïÎ‡şÓ°-ój+âik‰Ğy¶Ã¼RÖCï3”ˆà~UPJ¢+i@ĞÆ ø%³u¥æ‘7´Qõ’ŒbÖÉ°È'$Håp±XZ ¼ Z»!ö‹1Ëó.¬óµ÷›O‡Y(r q8¢[WÃ€Â$si
-yëÃÉÏ,xE\¤b%ğSc£aÜÈqv}(z-ÁkÔ‹.ÔÓ) FQÏJ•­2{ºÁ«`Xã¶ÂLL§o@—‘ƒ{ø€)9/æÆYn4À¶·÷¿"·?œİeø>†/Ä»Ê¼P»{~bù¾Ø™öHj#©¦ˆä3³§C#^Cäm†÷ßƒ§¿^0¬ˆÖ“ p0âæá¡[JŠ*ØŠ+ï¾„§ha,|1W
ÚÌİyÄŒağäc’xğÛ>+f„Ã‰õªÕEÇ¦È6ÊÑË‘&!ûäc !XÚø…LÕÈŸ:¬òõ³‹d@¡×7Êbáy!D|$¦¥ÀT2çù»"‚Ï°Û­¾gLÖŸbdÛÎ±â68§M<¡ªC<ÅE‰ÖÉY†”Z/È§Úi:ÚıëÂArÖ+x¯aÔ8Œç³ÍéË®ö6Z›0²û‚JœKº€¶²ùH±„Å½^åP/o^¯dQ±šªï~L4©Îê€¶«bÔ<:B«m(@‡¢Û<›x 1P‹¸ÕÙ´¿]Ç‹0°P˜ÛÍ~C!˜s	:³\ˆôºÉ^H·<ÚP[•ìxÖeÁu£ú‚FBÆwUm!ÒB3ÅÔ1¯êÍSNjˆIŒ‚'H?÷/<Í¾£_IöïfühøfX±KŞ‡VÍVĞ?Õ¶u¦^·¤œøGƒÍB^·N0‰m6éW›xjN)h?(äıR6FôÜÄ<ş++Š¬èëQ]˜7Ru³ÇÄ²˜ô vÕSƒyªãz²¦Œ “VHğçÿ¾XÏâãkyù)È{>©è8GZçó¸‹ƒ…&Å[RY62}<F¶òÆ—¬v\Q¾¹n|‚…ğ†ëÇ[‰ŒïîBYHÍíµ6ÏN¶òˆÒ:ïìÖÕ7Q°¾{ûæE„iê®‰İÆÛ—šÓqo¼%)H0Œı¤;A`@*ûvÙböİ:Qí¿sÖî:ZRgA?O?®)¡úkâ8oº>¨éÔÏC?AP–ö0mZe¾„>2FBƒ<TCE&†OP˜µR+÷&>C$;LsOhYÕí¸üù:íÉŒåŠiØn/ûA¹•ü¬“,·>YcS	ÿ·KjI›·3G¼ÅíÉ™VÊj›Ñ ÷gë´1'Ú"`ÿ6#å“¬øœÁ˜IPÛB»â@‰ğ)¹tRÎ4Çc›mº7«¹Çä´Äş§|üoP4éj*Gé²5ĞĞâÕi5ƒ#…×µıg‚#é í10®(aï8„ÎögVõ#«ÃÇpÇêE)ŒÎXîàåØÍËÛ'Úx^ˆÌ‚bŒÿIÅ­à¾†°¨ï¯Y"ü+©qjAFPàZ$o;ã_8”› èhŞ ñ}¥¢Øq¥+û¹ÑÌ­H—§Ùè¥ñô=÷”}. F½ıOŒnİJ.ñqÍ6)zó:àk¸³hsİ"³+CEãßKYçoæ”Ì£-İô™ê>‚ı­O·ğ!N|,æö}±3ê_,ÄÆJ. °!ÛÒÍ)P©7µY¼7ÿÙ)•]õK8ª|r¬I]'­·*„ûÍêş,›9«åoó¸Ù³‚{p»ÆºıœÊZÿğÍ{ ¢Ém=9åèÿßt2½ƒÅ‡==¬’}VfVPæ6z0£=Íù€q™Œ’Èà @kuœoœzKk3‘sõjÊ2{ÂM=Æ|(ä­TN——Ézpzf„ec{´g¤$úå“âë|c¨PâÌ¢OädŒ3ÜÙ xŠ™ÓâA‡”y(,ÚJr¡|Š²ĞE\_èöñvĞ¢‚]z¡9„ÂH	ûœˆxYNÎ2}Prƒ›ê£QckyÒûBCÇ/Bm±¹ãş¶**†'Eù¨#Zx) ^ÉcğV™Â1È®fP-©’€C~YIjwukpF¬C– YnüT%ÅŸå®>ÒàáeD«¯´nIáfoîÁŸYÌG]EÁÙ
ön3ŒK'ÜqÎ~h«áqk Ü(Û¿g}1à{cœ4X©Áô©à úôø(ü'<e*Oö:¡-çëkâ2iåMª®éA¢löjRârmıÈ¿2@™Å@ÊcI8©k¯*‘]V‹O˜r¯•f"†b.¥Ù"¼¸x(Ä¬SB'¦dt¡s[\„è¡•&½%WI<4ªÛ’á0¿¢²†êtwt4BåNïEœ*’KÇ€
9WD+>¸1`±‘B#‹ÉtæÕ¡ë°#…L ö`[p…uËÁØP],¡ê²Çfÿ_ÿ‡Àb»´4á¨yùE¸èóÒb‰ëß-bóaY9À¸·İ
ò­"Ÿ–qf.ãA€ˆ¢;Ğ d®­ú"‹ûfæ+×t M¯r‡t™Z‰§kŒhÜı/#0’˜Øx­?õÕİü<Ëm†ÜS^p£E‚t^ØƒŠ°Eî¸íƒ¹3ÄóÀ
Ø^›Øõ1Š¥…Wç‡PWú„áºE©ŸµyäC €„ú©a £<mgÙßLI§~sæ‚•ØhövéŞÀläÀš™¼ñæÆáœ0íÛÒ-¼Êj‚X©E:S3.r˜>äûÒI›­;€.ÍŠ‡  Ó[·xú_8ÀPÆ3Ïùëj%á“21ü£z- ûz½bw*ª*ÍØ“ºın³°AÎ¨ëEº;88Æ	'vu}ÂUXmGq¹½ìYsÚ‰£…¼-Ò\`bHšIË¿4&wŸé(^,S ¯·t‘Ê«©£K6s
¬›2»ç9(SUĞZvÓìÇ~Â…N‚…‘8$NĞ"©”éÆü±¥³.
1s¬#î}‹•!¹§Ú?a¶?f ^èsLº¢¢
EöÎªó%ißâ’s¼ûÉh¥.’“F¨\÷»öŸ+½Y,Ï‘¯­–t©IÇ(@‰-ÄÉrÌK¸Çh´ceOLÆyîÄS×·hårör@şOÉ‘IƒÁwâHÌëíé©±[ƒìâ2?æhG•„ Â¼6½³¡¾Ğav¿>)nÈ¤‹>×¹Ÿ;³<ÿïtş 5àš FV€EÀzu¶º™kÇÇlq¥Á˜RnY³Ä´òÃÁŠmDç—	‡>3n«2ü)AU^°„…nü¦¡•H°VhµJZ.Œ ˆ$=mPÇ·íÉ>+.ÙC4Ä€˜ÇÒä#S-{ßì'ûr1#ÑH¬S\,{µ«Ät—›Dæ¼@¿˜•Ã<z<ùŞÇX*©*xwWâlg¢ß©W‘EçÆ&a1Ú©9sU%.ÑÚÿ¡Ìå‰Ö3,ÁñH¶ÈcÇdâ€*Õ Ğ'a`ı.p±ÔWSXÓŸè%LÿöªpwÖÖi–ZÌ	gkïº°8²Ñµ|(Dö…<à@Â2Q‡¾ ÀZı>ePšc¤ætPìÂ¨a9„{_à ï±Oh$c¹¹ÑÁ²GAVÈE‚èÛ6°ùYŒ>PÎ‹Vï»ä™IşM5æĞEËá)£%hEU	 ±şÿ°¼È‚§m’rÒšhè¸“óE!"^ø‰/ºRÃ€f™u÷ßf›.™=¯L&œgpEÂµë–”öšhÜ—œkõ˜nŞò¥¡¼¦]w>%«zîufyk4,|(ÆK.GxbZªå»°å[j—3DÈƒfŒ8ØWdbÖàP—(ş&Iiîr	†êò¤*åR»ÕpÒ3ğù~íî@a]±n¨Ëí“¨¼ò+i‚Jï}:µ‘ñ”ôór	ğj)ô63KK]Sÿ Ÿ—ÎÙk(Œ X¦‡¤[‰œ5VÅdØ"_\şìoŞZA;?î²Qæ/_Ò™)7	İf9s(É"ˆ5g°ı‡¢1Ş	™^1 SL>!‡“Gf6+ê^aŒÌŒ0PACUQKãØYªAy'5\…Ùg…9Zjt¨uú¿°°ˆ'1l(#ÁÔPôÿ6ö×	vi™ÏW){/£'Zğ ¢i*v² w@¯˜Ñÿ'Ì;˜‘|³§óİk/€ëµãìn[ÍcM3=ŸÎ	.üë¯1ÉİuÁ{øpÄ@ •d¡èŒÜûc'ßÇ;EşiË[bÄ+R»vVLµ;7ËvìÚÀ&¥‚o­zfR1«·p‚åJr~ƒM7££èÙ	Ôh[ã‘-ú\if3;%ıÊá}R4«ê½‡#g¬>Å˜¡š‹aÊœ˜1M¦ê¬—ÅÂbÒ'×ü _…7‡*‚öuu]`Ê"u¬e92‹”ÿl×f ƒÒÖKˆ°İzú±ƒKÏ½f”€ÇRê!ÖQµÄÔÜºK¶˜Cq+”İp`Ï”7Š§` ®A[2ããk
)&{-ç AVrúé°òï[YZ&ù4^²·¶OTÀk³3½àÂ«LÙêç~8úW ¨ĞŸ}‚ò‰Ã>d‰Û¯!®ŞAK7²ãÇGıœ· È	›»}…Y‚„×*Ê7	äÄñJ\¤éŸÙ¥?<Mã%v–ª$»V'aÀ²­xù'º"“0ôXê'-NÿkÄm{éÑæ7<k¯ahÇVÒß¶‹r4 .|°ÊÎvÜŒôl¨×û·]êçP÷/,Çt<eÎ¬‡*“[7/“¹³O‚¯Ò¥*÷À²@Ò®	TßMTğLuĞî»dPaˆÄ8ÂšàÍg–Wg(´'†ç—uîa®¾¨ùki¬3ÿøÕò˜@I´ —çûm:Î±eÕ—`³ü¸¾y£ò­ÙÆT¼Ú4†æIøáòfó‘ˆ7çA²ºÙ÷ÙÍ?k©¹¨–ª÷:Aèüú¬ÛÊf@;®éˆ='jWfh0Å=üf†½«cZÃÜ.¦Ú_†7E,3£Ò[¤F¤9à›iú{hWJ•óÿÍ£ÉşòÊ5³9”ö%HÆNA=Û/k7•º¥#¸üÕp{Z©Ë(ºÔİGpi`¢Ë7İ|D1'œJ¶7ô3tLÔâ§ù]ÿ¶Iı¦ş[Ùë{¿A¹S™·”4Xã~LÎX(–»ªÑ¡E³Ê{b_ÁHÛ÷lGŠ£+ú$²­û.Á¨æH*ÄÓ½¬îa¶y ÂÈ!ĞßFÈÛziÿ8!y^aúk÷È^÷¤ªØê—27úv‘ĞÈ1£Çğr¥©4­¤óÚ’{tã²mAEÇ•’µCz±3öù1Ù…«6‹³ºñgSK2Íâ‹Wç¨‹¿ÂÛéUlŞø]ŞĞªÀ à~­ş’T­8„¦cü’ÆªÂ–°‰ëJÅ³+Õ´ FâT†Ùø}s”e~«¢O>€|b¶ÂVy²ôwU°³‡ãµ”"‰Ä"Nàléë¢RÃØYCâ0ú9?˜½®Õ™ ¿+µ²«1zËG°ü­)ÿO’y?õJ_ÿb
²Á¬ã¥ª=´ï”ã¬KÿXC)vÜÔò2Z£İ‚ûiÔ·:d¼ÍpFïeQğZ)óù“ÏõÕ·pÚ{ÈQ×ÖKSyHêª¯ŸÇPKÅîßn´ nqï¯¤Œ€{F~©^Õh[ä¢'Qb›İì¾)ÇÒÑ+«•ÙgıûE1‡šö”Œ;‡ê³UÒñè‡N¹Aù9¯Æ{ÍÍIpˆLP3OwÇŠ#RÑQÛfÔº¦#›rei³ø>´`®9«íŞ\Ø\s…ã²½î¼91‡ò°"×¤‡$ÊH»·êËÌ™W2ùÍ’ÿƒ_ì¢ƒL±‹êF`Á®ëû˜@IÍ—”D/ÇÛqÌ¹—èşì˜lFùí&l÷ÊŸÁÜfuúàŞ¸ıuëîË¤ğ¨y>ìHHjg¦ï&s=?âSÕ¹Ñ%3¡¶`T€ĞRï…ûü§¦|Q²‹Æùµşt}×¿n=cÅcD²O`E)¾>è//]…:KìM+nìA¥F³·½"¨àÅË¡inPÏ¨+ÖpçG1¿SrÜÈU¾ï?û?ÓÙÉ¢ıÛúRå¤•+3QËd˜†Z±dÎ»†PGe9D}X¯"#Yöğ÷
&[c…ò3}©Ì€›€Ç3é”àØ¡‚8¨Ë×qîÀ2ÅÄ ¢ ·¢ûÁg%^’­%@¾1Šqa±ÉÄÎ\`Á):†C.Ñ¶GNŒ|}	ÛDãJ–°¿éÉg“(:’7/9ò×˜®³úã{Ñ‰ĞL(XŞ‹ ×pSÜt®¨w[Å’¨Ñ1_»?¿Ãªínq,XşbJ’PîQœ$¥8Äa½¼‰¢Øëªà½×Ìæ³
¶Ü2ø­Ó_“OêËµòI KlÄk6şë÷dˆÆmˆân!fßÃ¿DÉo #†92EÈ´|ÂõMÀ+c0Eƒv–h8ilR5üìêßOË	>:0¯AÇÄÚ¤*/ù9ûØå;CÕk¹†_Îà‘ƒ i	O¡¨\O8‘İ0=à›Æfòn|j× [J˜_d·@FöÚç¸ğ|_u¿¢÷ã•şD­eŞ[L5Ï‘àm—Ú­3tS,ß"jpÁŞö˜ŒªÏqM7o²H˜x­Mx£:tû,Ğ^á‰1±œ¨»æ€ÈıÁŸ´4BGÑÿ]£ıq	Õ3a‘á{I­ˆ*c¶&È	9”è‘ ÈèS¾I(ü[ÀÀ©A}…™%¦ÈŠñmMMûåÒJºĞÎ9w™ej)wZ‚ë¾Ó¨€záéh5ÃD9ÖA‰{“+"ˆ ò;¶{äÌ8ğF+íŸ]hc“²L˜ÍkëŒåğ+ÄSë8>DÔ¬ÄŸ//Ğà:ÒAòón t¯`yìmFòH»„åÃRîé´•˜%Ö£¢0HyN”#B@|ç¾ƒ×GDŠzIE5›©ŞP§ÆpÒ’-¢Ü™ØìHL¯…´+tğ&©›$ó¸Ê%à|ŞÙ°ğÄ‹Q¥k‰à¨»z®¸ÖÕàµ	£î‚hcr“ë5~b}ÿ(«ËÎÁ1İ=sZ˜àyZÌÄLŸnøŒ :ô±tĞ÷ =7œB‘¨ÔYà^_½ëÜµ%hĞ?p§—xŠ–K½ßÄ!-+<Aâ»wr‘6nÜ\ßLşíŠÿaf2E~|ÚûØÀßğİÁ˜v–ºšV·—¸&¾–Ş¤7Øu	L¡CB÷Ì·[ˆL4:kÎ+¯¸èß=¶^]2;ä¤›GÀå”dfq¿§ÅjcÌ–Àáñ\,;e‹"ŞÇèÏUõÜÌ)æ•´£ğP/‘™è2›€8±oÊ&h6ó!Š–•hËƒV}(b‘ošê‹$	œc–_+[`ğŞêí¯=rtiO¾ŠŞ+“à–"oÇŒÎ¿ÑşÎİ*Cj{›“Ùù–.ï²•±âuj:RMd³¸ï¼g«ZBÕº°ƒÍrä?7™ci˜é±B[İè6Ûåñ-.Œ°|Zé(”&¥èdDohSM€RR2š·W{µ,ùºGNâş:*MEdıÍ£Û6åb$$ÿ;_t®†‹íÖ#lµş!f«Û)€)ŠóEô0êíÀ! ›mp#ççÄ6@öÁhlš£^uvRú‚àÂw{–2,_šsQ×ÙCäİİİ£]Gû.[gDN™ûB‚÷x c@“§Å2èï~öÀ­Såz^‘©ƒC˜voAÉ¤îáÃÆäü¼TÆs×?™âìêú~F¯ÿª…6I¤ÒQ6n¯*[fÕ–‡ rÄi€ËÖãâ‰[”DÏ]ka#–Tê€ÈGæ"K@¤¼F†õ”ŸØØ!²@c½6¦¼b1°´ø×gD^•(g¦'h¯ø³E·=#yğfé^%¾¤©Òşƒ€óP‡È8?VP—6½¢ 	‡$«<f…7Y?™ßK˜ÏJmv^÷Üåæÿ¤m?H¼:Lh¿c¦.+,mŞsäncÃcÆ—lCéù›/®`iÄÑ²…‹	Ïşåy³Ğ¨h¬†tHæÌ9	5Èõæ¶KÂùOÔÅÀï¹å«ñO~Ä¤YáSQ7Ñ'Q©v$%R&.Ñ'Œ1|ûŒé'v`ğ)‰ŒT	° ¯}êÊ„BøwÒ +aˆ9İ;²[ïÔ¦Ë$ÊòÊ-Ø¿sõ‘_dÈâô·ÀP
’,ñU‡7‹ ØIwJ8ˆØG$«C>^U•ì‡ì+Í¦»ú3£ ¡í…×ŒL'nQ™±€VµÙvP-¾ğ*F§OğRÂ„IÎ]B{?¤Ã ŒŞqWÌí“:ô}§VñuóFî±¡ÿË¬Ÿ©¤@µb^]¹Õ	6²W¼L“ï&²LšÂµpR*/Ùê°ñXuç.½ƒ~‚ÿÛ…OZÑÖnÇ5¢BÇB2¥i,÷Y½—€ŒêT?»¯W ¼*Dğ`Š‘ãı¢OësÑLT2%ocn+âc¶A‰‰=ZéÂ¡¶ËíÅ‡³×>ZjÓÂIÅ,æd@Ö¼µä#™‰ñ>ÓÆöhbÅ\³’Ş$.¹ñ‚¬ĞÆûë~5f†Óš÷Nt,’Ç9C}¦<­…	Cš ÙJRDEûï<¼„ÈŠ¨¶_\`/ĞŒŒU¤ôhá0ø½Úú./¹­ÑÉ¾~õ%ùoZhˆú˜šÑvŞİ†È¸ÅÏÉùƒ­øg•`« Sü¡w™¨ÊN×úù€Î…®[2möİ»ƒÁüõªDjH•Ñˆ¿?Öw‡`@ÿ@s9E³áÉ¹/¡ZÎ ¿Qõ€Úâ${Ë¤ \ÈkS?é†ØîêŠqÌ"£ìÅÑ*°ÜÂy{)Q/¨ı¹ a‰Ê|h
d[„}³Î’AÖ•©™È¯|³õ·Ÿ¾ó¤è{d7]§ƒìß†ÓñCqĞ™].>Œ	.…)°]…×G¨é„oMvÅp£°òX…Jµ	“RFö»L9Aÿçş©õÒ®Â²-ğ©t1¬ÎİFéæ\šL>Ç²Ó8®Z$³a/YQeA™É'¥.Å·oN_¤úf ±AÂšú-?#©¡ã,M"ä|–÷¬­rFUa1‰éêà zo¥˜7×¼úÎ‡ânÖ`F ,"£Ëã_YbÀlj¬è7]Ê½=XçLC3×ôü ßx{š±ÓJ àzUÃŸ?8[½ÂÆ‡ı²& n<®5pÂTxÑ`Ê¦ÙxÇf©ùúuË´İµ–o¯IÀÉàuQ í€c¶­è®dUŞ¤êúxñ`$d£9`~LÀ|jB_¬£må÷Æ_ÆÉ7ä¸i÷˜€Şb}ğ{œ—0æ[ëæ4¼¶áûEôvæâ9K CH˜e×7¦ëÂX«{‹“…ºÉ©aßN¶øÈˆçßôÍÓ4
Ve³8I! ®$]t›QiÈ© ˜G±,ÆßË4#Èî%ƒyÇ*¯°,è‚fu¼gPOâYEr°mgÄÂåm`–¯¼«Âu#æ7#'È¥Â“?d½òÂ—¼öAtlG£“9±h}ÿğÜspVû7ÆO…_ës1î­/œg(òu¡ÍÄ•vM5ZïÉ,ºüsÅ*?j.1I8ãq¼\< ı‡´†àÏcL"S2Ó<¬LAO‡9×o†ë/îWØÑÚwñš9`sRmÊ¬$‰‚*
uŠØ%T–h0©ó˜ä©«Wûf.A-Œzo¦bºÖÄMx…e%Ç$ä‹_ım@w»©•
l¾>îxk¤Ç¾€§Šüsş´kt
ó-w‹ï°Eğâğßã0=.;èA6yÎÀ,¸„)@UG‘ÑÆÒ€,…ŸYã«"ù¤‡"f×:moé¯mÁ‚•¢hº™èÖqï§K"Ûé´¿'Re2.ûæÉŞU•$¿ƒ†<Ìw¦(gáäoÁZ!! ¹îÏâà ¦S	-¹ú´X±“GåÕhCİ;TÆõ«ä?[Çè¸®nNOŠÙ
Dê¯áş3„¦ù:á#å–şÎŞçV~Û.GiÌ›õTŠÜüv&£Üp©E´	G!¥Şi…Wûò”ÎpHA§u·€Å-^Ÿ=ºH³¦hÏâ¡-œ„~˜Ü	Uc¿z¾Ú Ø
×¶*­ À…èKû[ª‡eôg—b¹}z†yMl™É<·ƒ@
Àb'rÕ§‡òAXÿ2b"Tn0Fy»FŞúÄ$éMLyT&í(roIa%‘#óWóÕàdP4×i‰´ İûunFNéá âÃ.£óË’Ê¶s´ }‡ƒ ¾·åÔÙú‡i&uƒFVÕˆ@v_²ö+­‡Õ0çó‡´¶ÍÒà%Ñ‚Ñ{\@ËÊ€MÒù…€ËTùÀ3ôÄêi¸o®[…C/F¢	S²¿a3=Eaf©‚+àï¿H¢àáWD¥o×ÍğøÁ‹NÉ¸<éÿe;ÚPá›}Uã0¸râ¡îX‘¬4›šPfTß¢¹Ê mcîTYªTƒGböc´ÌÉIšøNC,á€sÓıµ„ã!x.Cau¯Ó3Ÿ{ïÈ³¬mdú˜l5ƒÿ”“ñf„ ßô'í‘ğ|Û¯%A>É²gR X+’¾ë‘¥ğAm¹-ª,Œï;\;¸×owCY‡—Ašµˆó%;	Àz€ƒ}¬×­Suª¹-œñàİô`&‘«
Ö*ÿå§päE+j;„«aûÓßšp„ë€¥SŞ8!ËáŒšÃ;ÛÄÕÁüÒFÎIGŞË8¥Ûš:+\§æğ=¤v£§†aXE)İ^ÙokÖönBYXS”qµ¼Áº¢A¸ü¤Á1ğ¦tQëıçihˆ½±\Ì“=Q‰\L>nm6©À>„äU“Êôx—BôwewÔâ¹/ÿä~PFÑ}àÓ}b„ƒªªVîGhdáÏĞÂi
ì.:U$ÈƒJ’ã@¥‚óˆUsT#¨Áµ9×·!ŠÁ‚`˜ƒÜ õ­§ÈF¬÷òæÄĞf1ÏçšUºlª] õãÅşL}'W5=_ùŸ¿_Ä
E¤m|ŸSíx±@Ğ•¸êÄ"Å’õ#
oôOÆ†?paÇùuÿ1°³ù¥Ú\f,à²ÀzT+ıüÍc@¤ÇMjjKŠ_r»t]¨“w~õı31Zd¬¨ ½˜!'rw°G‚Bıâÿê¾ïÿÿ(å
Tûfê9CÃF,v!E‚½}Êà‘=Fœ4œ‡£I·0Jwfy, H¨ŒÒÂŸ"¦”„,Ç¹R oábùí=öNXy”pÏÜ©Ör( Bï?‹Æ#(H­ÑÀºT¯Æ¼_°m„‘²y0	¶)Í”ìÍãs‹s@4ì":$ ^hGÛ™“'ã½o…®X­zÒ™†]Û‡±JÖ*VÂ²Îltµ3Ê(1ÏÇœ7ÆIÁLD=·§¥¾ùìÒSş‘U»`Gúxx%Å«ÖqÂoaÄëÂ ë³ t–_)-u¾{âXÇtÛ“ÏüÎ;DÏÙ¬Í<é¼1zŠ5·ÓåqÑš«ÈxÒaÒùC:sâÏ[›1ó­Jõ·â‹|¸8bš&$#“Ã;Ï•CZ¨]y1š’ñG<•İ,H¼î{%LƒÆ# §gÖ(ÅÇƒİ:TåÇk(è‚*î—oR)$..˜OŠeÕŒÜí5Æ?ô…Aî:›I|¥ºtl#I7€c^¦ĞğA,aNNİÁ¨âÍ}õ°Ğ®4°şèJ(ëÀ=Â –İ²'ô;±puœ! w'%wŞúÛÎsı„ b„¬]-µJCÿÛUæF#²˜¹c…ª³ÌÄLïñÔ›MJX>—3?f@×„´lıy ¯Éä·ö!„Êmap‡U™±2·é¸ÃÀš„îñˆ²c5>OS«Ú´m(:£šé³î	ÚEÓ’tk0n62g·”mx„É@Ä´YCï»± qÙ`²ª…®åÑàXÅ<ÿÑÅ(dN+élbA§CrÕŸ†ÖOÌ6úï[1Aƒv»ú÷õäy@`¡„Ô/2q|¿`æT‘9:š»ußQ˜3Õz|GŸZ’™äú¨tá1&1±ÆQ=õá)fÃcĞ40*âñ $^ÙÈ
¨ÊØGp¼çòI³5Š$ğË;+)/Çp2;×¤ñ³.øØŠhëÁÇ°–L”PÁáåê¸ØÌ#9ìœ˜–N¹wøq×¾ùÁA)]é¾a.4³‡şÔ·3ÿ«(ä Ò*OØï_¯È9¾ìêY¿eN*ÌÉpîúÍ)*øLÑÖìË\Á$CàA’ü§lË£p.Ù|ç*¡@Şs‚öŸ¼â±?ÛTè©: I¤J]˜-°C·o9=Íü/zŠ½ ıŒÏÖà­omùŒ¤=,Xûß«Ò¼X ãE=Yd ‘U¼°]bo¯‡Z¦»Ú1ly€XíRƒ>ëÁ?Ï-	jÅõ±rÒ¤ÀUtÌ aì%É­ÒÔ|ƒœG¹N{±:uáê*yÆ|»Ç¬İİß±ı™Æî“Î;äD‚Ç*÷<¸š(S…Šsñ9—!.a`şw?µ·-ƒÑ_âí5Å²àÇ6¬%F:#Â„~îWxW‚PòùËv¥ÂXY>­ãÍÁbMgEêƒd¸ƒ[7´»S†Å9Í§ÅELFAE”ŠÖT
_d¤L µXı¢ÍJÏyÓë.¿ö*¹•oCÅnØ;}ÿŞ¦„ÏSí[Yuh±=““õß~š7\‘Zâ° ‚,Â„Ş.R›¡†ÿè=§{×‹*'VšUÁİ¡––¡	ôAÔ[Ô‚)nM'¨O ŒŸ?giÍÖsmÛ{®àp;emå>S|Bàj©XtÏzˆørÏ¦¢Â‰GÕò…æ3G	‚mòöÔ[ÈGÆêÔ	:à1×V¼Ğ®ë¢òğÚ– a<nÕ/òÛ÷AiN³BÌÁöÕ‡´BI5ÆdF ›-EÔÍãÄ‰gÊ,(ë‡›f@5àˆ4%›¸µûxÉÂÖV Ò Æİî7¼á–YâÃÂ¿ÒÚªîôVâ:V$|èkò¿ìšMW?¶ÔKikË
È¿NcÊñİs1	ÒXÙäùBÔ§¶MZæøhşÛÊ~ªÏÑkì8=ÏlåÑä³eÂ±, ÎA¦î¥‰{Õ¹—#/™—;u:¸p`V­v§)ö÷^u­¦Õ™Í³—¦M»cY_#/ic¯:ª—öô»öcîJùle¿äÎÆ-ç‰ÌÑÎ%o(~ _Şz Ü,ıRaÁÁô—üÏb¾9Ì˜îrdQÿú>$w‘ÚBQ¥à{]ÖÍÿPÆÇMK?KÇnÿ°a‰Ãºo›‚/Ë{Ó4&”xô	ê¬)uIùL`vÇ‚xf‰ˆDPµ»úñWa:Yq»†İÜˆ³œr>Ÿ2ÚykZ!s5[~˜ÛİXøˆLD¯¾Â²ëjöøBìV’SÛ1öfF\ÑŒ=é3„>Ò0ºŸ¶ÕãƒéPøïm‘jrY-å{ù}ér’Ë}]²Í"¦îG™ÃUäíÈ:m¥ÃÇQ‹f<?s³@OÎÔ.ÙÅ›™²:+†Èø­ûñ¿{k2=nÿ´v'’¡ãQò×%†µŒ‚>2ëßxc!€á<6$¹äÎâü· :w'L|Ñ/,Î»š@æ¢û¨şKF¼¦³³áœ|	vº‡U‡Z|4s€éömÅ6°s5;£Ù‘«´°7_ÿ¥Ğxì§®ºÖ­Ó[òº±Ï/øótp‰i3¿µ¿Iá€y<æäœ{I&c8'‘¼§3ÕCx‰‚Ò§ëÊ1 ‘Í/¥¥”7q)dA™ez‡ï|£Õ8c½a)RÚ.¬éİ$ÁÛ*5|aşG°qA­ˆÄä@‚¡\g’Ùv
5±óÔ\N,8a%X<ì¦èkÂD=»3;CG ª•BXx‡uµŞ†;ŒÄó§{ÏeĞà|º¼:èTÀsˆ#¢’«Øna§‰ôìµ sn1ÉL8­Ü¹Yig€‘†Á9;ÖÆº/İKÙQ;Sî pû"Şô±S¨°¦]f†2tëKdàÒŸ¸a.zÚàñ­CÓBf’x;òU9do› ôšVú`óé}^Gˆ”·Yâ©§6‘_M›Î-ºêŸMËUÕÊ¾9ĞYœÄ/P<ÃøùWÙŞzyw‰_Õ,s4eÍ^oLÒ–°só¬Â>X¥Ú]i} G>n¬Â¬}ItôàšÔ	_É€A¡US<«²«“7¡¾¹Ü½`l2ü	½éõ¤æ1/Ívc/> 5ì+¿^ğ"jfÕ|ù –¯ê1%êùä¬şòE[uªnÃŞ¦#³TÌáSÙ}K½×9~! õÜ¢>Ô-ƒÔÌó_’¤:fŒ‹}…†·şÆì CXàçÉÔN*§ªÇÀl¡¬§5èN¬ùÂ,°†‰·k’¯3ÇN |@Öe„”Ã£F_ßp7³›ØÅ¾"Ìn“9¥~½'oò˜½NÃP'Õë”ùü·­¹¢±µğˆ˜˜Ş#ga2ÈÍÔŒÍ;}’a‰?«æz%@4ÍÚÕğ6E.AZvıÎv¡ÆfÚ˜}cyèë¼AÕƒb' HqÈ±{•hzË’/¨üH…¼¢ŸŠÒC*y	e	%©@Ëu–íŞ
ö]y®zõÔç!GeA¬éŠ®òİè¦­^W„ëÀF<)=}¾wÿcŞí5i¯Kõ< š#À6ı#ø¶ËÛAà˜´H^†ÄdğĞÚs ø¾Õ%Æİ¹‚nîk´ÅRîĞá„]µŒæ=ÍË¤À`™•bn“©û8è^¯şÔğ*ßI@*†»])¡f[z1i·ÕÎ6¶Â6š›?Z¯n.CnÉ­¨ş…’ê‚(Íü9ç½{ÿÕ´â±)ŒöŠDÌmc‘ü›X´D‘©ÄHw7q6ÍÈíªNG‘¾¯£òi5%cëŠv‹ÆØLUrE½rl0Â@9(‰ugõhË>ƒü‡{ÿòb«‚ŒqvÃÚÔíÛü?³Á!²xè©SÖ¦<É•Âl¢¢P²‘(h\(Hd„såë¥É[$s,şŒ¥ ˜9;­ªf³ÄİÓt›_ï|4¸~ãyr–-ñÆ°ù¹2¢U]ºÎ®"ASM=ÄÙQ”!œÂÃ>õˆ¤»·ı“¢É;H?5ÏlÊhúP;hÆüò¾ìá ösÉ*Á÷U6Î¶‹øÔÇ êòş½ù6’/¶%.ßabkÖ{©Ô¶?mí©vL2®C·‚‹ªA%ªìIJ\%é;Şïà$b&ù^€zU;¤‘\Ô2`Èp'¾EÚE¿S¾õ$—Gü%4‚¶‚#=SàÇ)P¸¤Öş~7ÿ=è—vÙHù›®²ëÉÒŸ3«.Û¿FuT¨QÎÿlYíÍëqªN!¦{¨KØ^?
ŸXRo'É$/÷²!†öÈ÷½$^:“½uf}ôa•¼Ÿ±—¨ X¹ÓÖşÍ¡Cr¤Ò–µóı£zâÂĞ„Ìú¨ÿ¶œW‰‘=[{à4…®2E.oÚœ7™;ïwAGqä\€¡¤ŸôcJ®·ûáÃYlÇäP·TÊ¡œ‘E"i03%-±+d&>şCôèZˆ8‰²üØmçÚGÃ·Ğíïı+ ¦)ú+ç9â±ì•ÁovQ ­® xÏæ	´O~É(Wºü`>Çİ1.n—ı‘ešUò»·•ÑÑKånÆES¸Î.a†©ŠãnT?šS®-dú‘\ àvò;'fCÏ‚Ü‰ø­{MŞ¯ô
F•^æ,’ÖÑ(ßÆÓq1zMØ5{H“nH·Åwi˜&İù }òÒ’o=ÌoŠ¡WÊœ äĞ46ôTövgC±SèR­¼Ú{ÌYË°P˜“^ôËKYp	°ü®àTªÈ3¯NÜ {q—¢9_Mc2OË–Û­ÖA×Â¢Ô|îa®G"/µàÃ@ªíûÛÖy'Ú’7÷“Û‰Óª]=búT§Ê÷yœaÃæóÒÔÓ¦VšÃyPMzæPº<º¾Œû—E7a)â™;vÄ©Ejêé·êğ<±ÔÇü¶v—ÜÒO{ïùõò«N2´JW˜;ı_ã(`î¬,„ KÙ?MšSíƒÄ zKØÏ¹i	ïŒ>•ÛRÛuŒÙSÎ+?íPjhB‚×ÃPÂqì³éæÃĞ>Ã'.‘~Sø¢eP	ÉÖp™²ä¿”sj Pœ@ËX,öÓFqàş­ix5`ä’Ûı_ÿdìcÂjÓ ¤Ù†˜*DØ­¨Ü'î3h3´«)ñ*É7Ó¡Ù’#šÒ|¥šÛ9™Aæ“ÇJâ5Åïée”1?F…9åô¢t§Äq-™û3Eâé•^Ô‰îm’ê´ïÔËRN~åH´ó€300)Ù2mB^ù`ß§‹‘}± t¶TöüûìÛøœ¡èûê£ÙZÜô“Ä|×*-äl–Íù¶´çÜ¢Í*Xg°”_NAù¤I‚Ï'P„ÚfÃõUBš&ep0ø©ôYh›o¤–°Ô½²ËQÕcêáıogÂ0Â †1¹4±æšN?}×¬íô9¾‘{ ì&íŒB
qˆ»…üS)æ| qjfFÂP„2¯^<4EŞ%cînDÙq¤˜a(øö)(|À“-¬Ñª"W)?—– P1ËG¸\¾ qİüŠ—*m–‹¦f+¿ãôùp‹Z©.ªqo¤Çşig´IfF	ô¾ÈÄ"ñ<ígU<ú;e7ü¥ÕEˆr,»0pä‚b¿Z~…H¨çî&Fº)ÖæıÖd®(Öê[‰m|å¡Æb}„‹ÇÌ®fJ ùç7N°¦÷‚µë4é?,cşq³æa|ØÕÁ·Â-ùUBVhSRTäê\á—»ôa­Pä’|×ÍF²ëlŞôMwQ€Ä¾z™b-ŒC]Ë|DÜÓôj*ÚŸøDJ‘º{`£TİA¦VC÷6Í]§8Ü´×YáıÓËÆu™ÁqèoóĞ_am‹ÎÄwÓÕŸäXvõêf“˜ßƒ ²a"ªW;Ç•üjyz¼èÁ°R©ñÅŠI¶Î zíGtj#:¦Y_=2x?Ş‡5ãd>ªÁÎwÿ)TZóÏy^¢5@ö•j]8U1b—€Ğ‡ìÕ8©7­ ÛÖ8Š®€”wÌDsX:¤ßÛ:ØØ‡ø±Ğ†—½!ØÄfñ$™ÿöœOIöôâŞDÚWÙû¥\/˜o~•ŠY…eT£ÈGiFËmÜÃ.1}5æ–Y@ÎzŞG§]+àÅ€	8G=± äVe\R›4ß{¾ÀÊ£ãp¥Ô â›ªMÍ³tÌR›› l¢_¼…yù’jÏ4İ$6¾±\ù°úúúĞÀÈgk³=j÷À…%ÖÕK¿¸»GB 7ÌÀtgñ}Û"99Á3èOÿÖ›˜Ÿ“8Àƒ€¸_zÓEò!¨J¿‘üÈœç¢TO•"K£Jª+ŸÀ6Yûë2>2¤	¾Mš›ĞV§$‹ÍB1XŞ›X_ó‚j­Ş}dâ,r¤o|6H£ÄhhwS´²Õõ‰&»‡Ãì™ıyZÜT"5»2a×İ·Š`º/¼Ş†–Ğ‡8WM?6	şÙ–İ¥²®ìp¸'u‰%¯ÑzÌ„¤Ö8:R1‡È¸ˆ Ïuÿ£ĞâE&­ö®û+íÍCş0G&ú:åãğ•a²¥šaìÊó^“İl¦› s–iQm2‘1	É†Jœœî˜ıuå¶ˆK<·ÅèüÍ2ó~ öÎÔÃÄ¢ï{.·m-9W–É+B³Ç¥«¾–H=¼póÓş-ç2ò¯*ÈGŸé«§p0áŒTÖİ®ğ ÏxCA>m[¡Bğwz˜z£3ıLÊ“E{ÒímT.enâ§ò‘ÏR—¶ÎÕ4b(?=pç£Š]rÕ’îê§«eİqJš,$è1Ş*&ª4B’èÅÍÒ]¹˜Ô;&9UŸÓªU7·zĞÅ’˜/e¥@Şñ«á½2°	¬=vI¯íC é!M?ƒõĞ1êf@™’&áƒXŠMLä¤U5õ`ğÜsÒõ7 <Rìõ9 glÌK&.SÆL¾î+RA˜‹8Ì4O“9­ªaÃ=/¼5p‰š³ÛË¾ÆŸÅVÛ%é\P>ÛÒäô’5AÜgLÀÆÓyS%v” ³Èá£8¨z³œƒ†ØÀ3Ôäª]—èï.áO$îõ€b.?Q”V:FDµ’Ø’ÃeÁ	ô)¯ >`X9§Ë™uêÎ«üRu“Ô %ğï]›¤&_îwHı¤åÿAÌÕ*"Qn.æô‚šQ¶Y´š
«Ölt9
^(¥¼{êÁú-şÓ.ånGïû]€%œu=8Å±€Â;Ê}rÅˆ+\±GšÎ(åtOâ6:z"švõ&¥e‚#-‘Hw¹l.«³Sm¡j¾]0ÛóîÖ™M ã±tZ¯X6wØşôiç‡î6zÑªÓüv	,‡»²4¢¦9¦Ø6"/†Õãz¡\(ÙIIéh¾C*ı¡t®¤Ê[7Ñ!„î}¿´â¿üğ.FÂ0ÍàH¼§LôÔØşpskÎÈªKKÊ(]ğvƒ&GÌZàT>>‰
İı/Y¥aÈæŒÉbÖ³?ÎG(ãFôn ;.7³ŞËÈ†»#ƒ²ús#³ÁZ%âøš½Äéš¤Õg…àèÒÅ¾F{ÛM¸şÉİÍ×}7¼nİŞògÕ$u	l4OóˆğïìH]¶Ú]„X›•‹Uò/:»Òæß@u"á­3êˆbĞéw.äÕTØ¯Y,Ï¹q32ğÙ ¶Ù #éß/Je¡š{¡#¯÷·¾½?Ú§;vJ†Dbœ
ÑØêâôXúa(>	Òæë_f.ÌuìNde­±—ˆÄˆ”Ê}°5Ù‘¶AæÒäi›ô©ÚéNğJŸš(3ˆšÃã7©I²ö2 °<OmÕ§µ›a@ö›¼R4€»ÖtÓÊ¢|Û *ùş³¸Ô(:ÓÏB¬ÖØ˜ºiÙËÏşgp ôO£ñZËğÙŞ¬˜ÿÌŒËEX“[µ‹íÚ„XvU ËRÜùµ~	JÃıwÃ—»Ò	áv? 1úµ-ÆãÂ)B¿½#-Ğ+Hó7Ãı³è’•C&()±šSäÏcC1!‡B¿¾£=+‚rb)$Øb·’Nzìnõ|YĞ‘ZI}ı6x9±a)H^òœÊ$İi$QGPWï&q|ÃŠşÒ›Åj^k}ìˆ7){õQ|ğ+§/‚÷€c<CÇÿ oLìBôıàGUí¦CD„‘/ÿ\™o8&¼[É±3íøŸÍÌÃñE¼6"6€gŠ£[èR.)»yˆ«Ï“`øC/İ)²`q%ËÓ|a ûqöÆAW}XMäuz‰púd^“µKH‘·ßÛ/ÂD-‚fäÑóMJ¬nM—pºóŞœäHŠŞÑÁQJeêŠ¶Iï€F'ÈåË’Dæ,è7_â×K;Föm‚cym5Rãìºˆsj³‡ãÑD?:aòÂt9Y]—´æ©H•„Œ¦¢ŒG¼ëÑ1Ûú3‚ÓW¬ı·.³*Ša©`„k‘1‘zÛTšµÏÄ=Á]-ĞAfXƒ[±ÿ0£nÛv“m’H|¼‹É1Ù¼<˜íœ÷ög@ëğPR-‘ŠöÄJ„}.‰ÕÄD  úé0t5ĞO²“ÑåÙ &W¬	zµ%)$)ß¬\Êaáõƒ÷F4å„¶şS?à•~§24SëqÔuÅkÀı%¢‘d|ø,]~Otú¥Y„›UÕãÎ0á^7GCƒ8dç·Š\aóºZG†K”Œ@J· ®™MÁ·Dä·3Båù‘.›Ú¾W şëÚ7ê”Ú5£”ÇŠKØˆ®Zæ‹Œy¯ò›Îs´sºñ8©9ráô DÂ œ:³…ú¿‚-'²ï—¸xá-‘Å?Š‚}X§',l¿,5ò	q™ÅºùÌo“/5Øvça)Î%ïßÖüG)5FiB0"	Ô<AÄÂ·¡0Y¶4
D}æé8­º,|nü7l®’®½xıeŒãK—´ñßÅà4Ã'EÃÀ"CïıaVc…>ÊåVLhåëuMµB3®+>Ç:4Ó®xÀ<ÆsXµ‰)M¡Ê‡0{D;Räûú›ñÛE·ÍH¸{Ï³^4[%Œ–<7Ûd=õÒà¤«:Ÿµd[T›ÓxÌ€£8ûbwt‘\­¥Œ§! --¨TNåmå‚;÷¹“Xggó>šÌ½|Â<Ã?´ü(EGãy	¢ÌòÓC4Ñ:4r¶âƒãz²÷µ¨iæ,ì¥î‰NŒgÁÂÛŞËX y²Zb§õÓj® Š[ã”Ş…_»Xh&“»˜qÅ]öHnİâUáÒàú@èØfñ¸V¿üîÌ›FâY}àÜ"$°0 ÀÃ¸âÛé¡¿ ÔŒ¾gÄUŸ:iÜŠøl5S%™‹m3”ø\4 gwÃ8ÍğVß+¨šÚ9kÒ&~¯¡]a1ïMë9Ñ«0ëÏ”üeQô1[ ı¿]Ó™:`f§WˆPßqİÑJÄÚ(Ã§²ŞŠ58ğĞØ18 ºr|fRTv•ú¸•§PÁ×ûzÁ‡U„¶1Š›´snì»œèfJ ìéebÜ ÂR_s	+>äÄG¿Tîlú»Ú¾Ó—ÛR“N&'ıë•mÃ·5/‡ZÔˆ7\ı­dcbuª÷Ö.ĞTAO›~É9D¾#ŞÒ) BlJü-Q5¡wÂ1™]2É
®Œ¹·oetE{ş§›ì†Ÿ²¡xmšGÿ¾>òw8ûéF›Ê¦´‚JOf˜éüàî`ĞÏcºuàaJıÔ
Ã›Fà; +Ê&5kØ¹R¶®Rm|°¹E–ş<s)ÜÊ+¯Ì-QrVøŸ½½õÀW+¾5•·@Îµş~PÛ¿2­og A‰Ìt’xˆ ÉDä[L<Wóâc4Xò)ŸÉHXqÜ˜4÷âÇ–ÆDc$xí8È9ãc< ëXP¶´ë÷;|Ï´#ut5CŠ—|wNÕ¯²óÙ”zõ»!óè+qÉ}È°˜ë!{l¢o‚n`¨qn¯<rL¨‹h(ÚëbŸwy!Œ10#V“Ia”#í€]´É­–ëZ7¡Ôzmj¸_P{Û¥Y‹A@G
=ªj×@Q“¸¼Ü“tâ¼ÍvÁ¯€Ğ2,I]³¤ˆ^Cå­²Æú/v´×"Ï¯½´ˆÑ&<n/´Ê·Ü›×=
À€ã¬Ñ@,ë2OŒÁ*¥I#iJäTø£&ç‡R–KësË¤Ji¦Î,A\¢Ÿ™ì ±|c’Ü·äš‹ØÀâhç8KCğwô¦f©Îä]÷îlv<¢¡B’ÏNBI)Ï®1Šè5&Î)/ô1£ÅJb¬ÁƒÓ<(¯ÑšºPªaBÒo;Ä£Èéìx»¡Œ\g¾?Ù_Ò3c¼åV³À±G½c]ïÁOÉîVÿ
ârZ/”R6(¯éBVÃuÌï¿ŠÍˆdµ?Å4Úx´ğAX)İPWÏ^
h2¯È¶ëı¥¼Ïàv‚ê'Æá»AIµ‚šéIõ‘†ç;š)åæ(UbÂ´sÉcÓ©„Ÿ£ğÿ>Ö4ÂÖ(…ó|cé¦°›<Ş‚?e$,	l†gTú m¨…ÑAú4şyÉÎŸ Fš¤SO+'*ôÉ§YÔ:ÏšË¬mŠeIñäfBoHw?¹G_¿¡“ÌÅóŒˆË“„çm²òıùN.-"®º‘ÿOgCIäÆ«ˆ‘ô'rn )]ñ×u!"üîèîÁwˆïOÜÀc¬bÔÃ… Ë	zÁe6|
Ê"†R6´4i!¥ô®¦É—ßeTXÊ,™Œ£éŸl½f´Ä“Ã¾T»[{K.¡=Úøë Ø¤%KÎm¤õÕ~‚P'—5·aè¤q¼5Ckğüõ%ÃmĞ‡u—
•BÀÿîT~¬uvV8<ÅSUß8aÌíí	İútQPYù¡`$ÜF>%~µ»Î'Å5Ÿ"SÌH)Ğ×‰¥…ZĞõ¾L¬ÖÏŠ.»…–qÜ¤>ïµQÉİÅàß1B«ç¬-}£½.¸¾ÊŸ$LÌ¢¨Õª)² ƒ3Ú¼\wı8?	À×kî¥iìi3X…ÄJ›MÙ>8£ùŠ ¾²ÁZ“F"%VbCZ¼\ˆœP÷JŒâñ
A×s töLÄú³G¼"]ò…[!nZ(@pNÈÄÊx°®fºüA§sú„ê;…ŞüÍ
õ'à{EcÛ¢Ü[çZ=5Aœ?<GŠ¯fÖFN²ï© ¸üÓ 4ı¨OeSğıâ_tæ·ÒbÉKhŠ¢óÕlõ¸9ÎÓñê­´üÿ"£¢&¶ëÅ\D—İºJøû%1¼§5- ññ&öæqWÕ“šB±ıë[s¤mË6T®ÈJ÷a¥öAÌ÷©Éu˜rıvdy¦c†t§¡Á5ÔH•¼æÌXö–¾êTƒy†wò"ö”0ª=Œø°¨eƒ~§š°»‰ü+¸+$ê,;W§ªËü 4H Mî2ÍJ4—Ù•Bò? CT=Dy%‡Â}TFrSê§ê€körÊ8"+eÒáƒ;áY%èÁjF¶sx×MŠ»7öC¼'+DKNy‡í^mÔ¨³¸Õê^>€|/_PİØ‚¾ßî0‡[±$îç½Î'n½¸Ùpe8Oe­‡ À^áì¼MŸR³"|FV-f+ß®™íÏ½¾âĞ™Y°ÖëÚÆšÅ°àˆ#Võ¿p€`Ù~‡~óÙg«ı3²9"wÅnîœ‚w'QãšUg	nóÅ71ÊRò†æÅU/QB­ÕĞ?o}æ[ù†QˆúÅ¦‡’MÎÃ'%‰ˆWĞ¦íÊ¶Rj[Û„5)6ğIH“‚Ù%Xr!bƒNØ›gÖ‡™^›ÉHg ±
×u,ù!‰|S;¹—¼‘1}Ú—	³yplÚâ	«³Ãp #w½:.wGNÜ·hRËmüó²áÕ‹c^Ÿ…^c¸Ç¬•ç‘v¢^›{|;‘\pëJà"ªà0KÏ?XXêujç¤ ‡(¨[œzIˆ‹0“rÄ8™›.B &LNÒQOŸÈ1K‡„tÆ^JmÉ@¡ßÎ	‹½JŠ¬œòn êÍŠö]¿˜ãœ”F˜9'á²£Jæ;«VEŸB­rC!l!ˆ×œivÆr>	=Çü\Í²ş ¬Ş_dÒ}Åz4ªM¿İ¡úÑG ¥aŸĞÄZ?ãÍCÒ?<ÛŞSİò	¤!7Òş Ëñµ2VSáœo#6î¾EVHÉ ƒ–~õê¯'…Ü®4èƒ©Ş­/Êz2³³ww½§XGR#™©ŒîE?yOJTq<¡J¦vàáH+eZÍÃ‹l›€¯è|9£	ÑøsAc°ó²bëâ—ét¯™§ó{	F3HèôšÄWÛ‚Â¡7_^Ğìh;¾·jÛ”r*šO&¿65ZNMlEP	õïóC„üéEöcÍ›ÿUyõ°k:nÖ
Œ0|ıfƒ³©¨ÿ#“óN½×¦³†¿jGd\ıs2X=h¿!v¨Öí€™pÜ¶3×ZyÁ’)¸+JŸºôBã~™›ØmËåK'¸ŞÆ¨¶p86[<ÿ*“%²ªÏ¤yVVöÂF»Ó×ùÅ^»×<Û#î?S“ÏHÒ1†V&-òZGğ4©áüİ	÷æ…$Â—+Ş—½ñ1>Gí¦¯áEM@„?ï`¯‰ª×¦×px ¾ºãÌéíÂaDCkÒ°ëÆ¯vº2œíÀ÷Î¸¯ÍİíºÄõ>‡ák³È¨~d%7<@|Ã|¨ş-µÁyÉú»ºf¶âY;}N77‚så~¶g‚6©`ûbƒi?!“?Œñµ¬çiÜïÓ*b&Zk#ø	û1¨’È“‹Ö'$.óD[xhIÍÒXTÒ*ÊQŠ—Æ¸Z…¢·†D&lõY_Â^¤@À6›º|dyş]Ào¨ú	jš€!µòC>lì‰w%ô†Õõ<gt¥Ó|M\‚C„#¥üêxæI”8£{ŠS
Ş*ë"1¦ñÔ^Œ6V£zjû	Ú£8õ“JÜ[°Fæ‹Åê»Ë*2‡ü‘å¢±ÅlÏµGµŞø%Eµ	OJÄ¾°*QÇÒ	¯*R7Î(w>8_šPn8¾‹ê•© ó¨«Ö¶ß˜¨ÎGr4GşõŞø€ÏİZ2±`~ßì=µä&]c;Ğ%D†Y}×ùCErv‘Àíg7ã›)D}:’îê¾Õx0w„N´íL%l	³§¹>EÚÇğ¿e¹VDìa›ÌŸêI­Ï‹Ş0Òj¬ñm¢¬íTä£#Ñ,•<™›Ó¥)ÿZX_·0#ŞÕ^€å9N%N³¯!Ù<ô™±'ü0ø]"æû¿üPÎæ…ì¿ş©ô¹ã“[X¤ÌÁÿK¢ÚÁÜÃßñ»òÀZ]‚œ<ß™Ñ†ú‡_˜Ë³X­4£síŒ²)¾°b h¼ÇŞâ~…en73ÂQÂR\ uÀıjdáÌ g—A xC³ñ‡t1HwÌƒƒ¾+]§#±óìÜs‘‚§6gÊa¶!¥»ó·ûøââïm°‹A„=GFÎÍ´Òè“Ëqg¨›‹‹…z¡øÁç“]ÑhòË½™À‡®ÂØ£yúSOúmL4a ¤Á5’'¸ùfJ¦Oì`òóçÔ)ƒPLuù6Õß¤’›Ç¸:ß®u´U8i/¤(5³K<‰·¬…€4]!Î²ÆVÅş°Ö­xóŸñ»T- këh	1ÍË¤çdî8o^nü¼îAş:ÔäsˆvZ±·£ß»ğEN®Â±Á§ıÜ÷Äz~îŠØ–ˆå}Ù{„L§.YI+°sVHb¬á'ñ0'/b]pÈg$´>zl¦/iÍÎßXû šĞÎ¿óuT,—¡@^7±«şz‰t,€ö³H"©Ò¦rŠaÎfÇtvsKŒã5üÊ×è8‡Õ”¼1ß=›LğÄ	¤ïıÎ>UC@7€Ü³—ÆÌLúõ;éwe¢k0HJ-¦$79¸¿íkO¶÷íNïLoeš	·!ğpÓTvÄ19•‚Ã6º81Œ*z FÿÛ¶E¯h3õ|Xs™¨q,.P<kCÉÔhî%éìí—”‹SUù÷‡Éë’(êÄÙNğ7j‚5İÒO–}ôœC³â®¶ZZ8.»Ğ4Ò %,Y¢¦‰|{';"ñĞ:/½È;¦ĞKØ9<sAuàà Áğ÷™zLÑ]EXïš”5CQ˜"¿M}èÆ`DÀÿZîùÔh¸‚‘LÔ;¬¥9æc+”ío64…T[WHš`Ó'Î}QÓS“C…0.E£veÓm/İqæóåñ;MøïOéµë3J:sÍwc6Ö‚µr@@…Úûä3¿ªz\)©Ê»]§Xä{°G£ORm¤‡Å„ıÍŠ†ëo—;ék³ƒ«×@3¬tÔ³ÊüÆ*ƒäl¯Èz B tKàŞÊE³Î æŞ4ÉÂšzWÂ`t¯‰)ÌæYÀh£Š™›Êåİ¦Â£|#¡Tø¦¸‰b+x|gõU ¸ wúkÙ |ÿlJƒacëó•8éÅÈ
š«La”E¡¼WŞ£#dáê·•—C&Î£EÜf¶gˆË­mV“q@jc×æ)K©gNlw[›fäuåÀŸèjçŞ{×ÎXféN\ş8|A’%õJpà’ô õ¶ÔúbyêIh¡£H~wµWÕmßFíÅG¦%¿ï½”Ì×ÊEºcX½"‚½ØdËµí–D)_¡h*©«ù¼êÂŒ	eşfJSAêRÈ%9¦Ã·Éíåç¾°V3"Ø~û“i¸ĞQıe†ğE`ÃÈx¥‹bÀ¨Qœ†Òk¬éËïüú¤hõÅzÇeZš¾û„Dƒkk£®ä0«Ø[QnO†qÓÁ ½lx²oï‡“—ØèÊdõ¯f8A ¸`áÔÁ,È/hé„^ÒDŸiª#±1ØæŒÊ2–bôö-nTê÷F«tÆ)zL{æœóO°´Õ‚¾5OƒCôá’o¾%ò²3x–1Š`–Ş£g6+)—'gì° ‡u-»o¬Çò¤oÿHáDì×Je‘cH;›®ÿ*´IX‘Ø¸§8º¡0i½VfŸŒx¹ÃöEÏèBë~³K†8¯Fêi¦rh+ßŸın½„ÓÔ¦H"f1Ä”–Ae=GŒğ“Ó¶… †*ÅŞ*ÄÑ¥Ûh±(`œíD—\*~kşgDµ{œìÔØ“ÿ÷Í{'ã©øag®ÎúıÇQ;¡¥D'€”ŠQ$R)C¥]g%ó¨½”Iƒÿß±Îv*«™iàÍµôÅØZr”oğ…šÃQtHÂ)+×İx=Ì3kãJ0G˜U®léW¶½£ÃC÷9|Ñke§"rU6›<ÊTmû^J3ÀÆc«°¿Ú3¹`Ñ‰G‘;Î(m¼Õê9ôëŠ÷GËèsF°ÛÚË{©tÃÒjÒ§©¾ Ê‡TÇEêGaX¢ÇºDMĞvšHé ï Ğ+ÚŒÿ]o¹NZÆ,°¢ÉyÊo¥rÒ&@¤î¼‹ï«€6jYÕnuSë	\§GpFİ}Ø.<|EÌugé¨=Ù¸•ªJ¥¶U6<Šñ¯Â–_#]½4I"$ï±h «¨¹}@ôñ:pÜ¿Ë#¼w`Y~>‘ñò’Ø†yÁq½¢ˆqÏåğİÌ`*ôÍÂô^M'FI	sí€œÉUª‹¿¯¬fÕŠæphee3NÇ¨ÓºHzÒÛiI…H¹¥%è`”Æ¿&®„eœyïƒ¦UÍhòÉEåˆB‚Š3#°BÃÖÂ‚‚vÌkiõo£
î¤ßg}>‹Ğ:ñR‡¶XğD(ÏûLN7?b¼ßA>=^i6k‘=İÛwvìY ¡‹Ûì¶º.I•SÄTvØ­…Ñ¬Øï';tÑÀ)—Òø<t¾—§Ñf;55´™Å‹2¥²9uY*¿&Tßõ*‚yÂàQ‡?ãÃı˜H}.Ğel¼IÔ{"…›/ö³YiJdPHê³íDD’Tô]uåéÅ†ƒ»Ë·ì‚(eK.qÛ´#"©¢e=¼×øªvĞÜU¢E¹y÷¤n]“½-l%MZ"İ÷Ò*ëùV˜Ñ$Aí¹W 6Xb*@óv7÷§Á-¢¾
éÊ»‡Ù¥i°A•ŒÊ>a)üÕÜïGÓ®:!XA"	Éí³ÛP%³8¶@øBßVæñ§|™Ô1{Ñ¿ì5¢S¢Á„$âsâ•&ÛçìZrjÍ…'ûı„„¾Œ˜GèrÙäW*Ç‘á‹Ğïä&Ä:$$øv'“;öğ&4ÒSåZ=Ã<m6O^³ %ÆxVË1ÍB]­ÿN‚ñd`‡ƒÀ`¯À®šVŠÚWËJÁ6gíªøÈ÷ê13›&5Ô•¢'”xœVöòŞ6˜s7=¦GÂÏ HœàL"û¬+ààç²ø˜á
1yÚ<¼R‰Ô“q0YÂ›PÀT›’—h2nÙûË@xä4^Ş¢yNG—x&ÀËä›T+
ÖÃV:ä•×Ã¼š¬´ÚäêôîôU÷ÁÑoi4ˆJ\¸R/%	Õ¼ÅŒáOooú<SsÌ{#Ğò1«Ï	o©øÖçÅÑå!`é”Ÿ-ÒÍwÏû‡ó«5sfÌ>%lÈŠø
Ù(!tîÉa	Ñ‘lAB°qÒ\}´1i@5ËIíTé›nA•˜n”4“npVr~´K Éå|]ãË¹¨P¡•ÉÓˆ¡)Q#÷fÕçÏöG1æêŸQR‹—KsE«~šDÉ Ì÷¹h¢ëBF¤¹y@Tœ—ó„Â3¨h}¯‘$”€–Èâ>LLëFyıÃõ†äyÑµCUBqÖHÃ"˜TGãv*¸`.ƒhÕË&Á}ÿù¯†@ºcØ$já‚Z3|û¸†Ìrpéc–¹sšÓÄ²æçÛZÉÖÛÒ¥¾Y('.8ÚWwÒb\‡(¢i$'ßŞJ´ÜR½gá]‚:#»î  /Ÿp#%Hsƒˆolq¾—.©n©DİJ&ücP»Ø ºUâ}Qî«§*¡U±yGîHõÓ?ĞE½)?qÆ?¬kÏ!óàù(lùÏ¨$ÍÌ}¶NÑ¦Å€¶ë ÿ„ïêsªê®L=e”ÀÏp¡	ä©Ü%§UĞæ'fyè­2É)\bgï=æ”Ä6•”ï±aÃóÁ­v¨ÑvC†t™|gÓ,V”¯(âRù÷•Ó}ÃÀÑªÈ*ü`ôDBòY¹é {Şç„ÿ2ÿr¼Ÿ«›ÈR­™ŒşMŠ`úˆ–;¿<.€>ò8ÑY™O]ôiS˜ÓdöE³Òİİ¾ÉZÅ"ãÿ#|î‹ÅJLa–Îğzq›ƒ‹à‰9J@îS)0ÿàÏ#Ë·Røñ$Ì7]ÉYPgˆ£’¢ŠK´¢é¾}7Æí¹r*¸cÍ‚nÌ}ŠıãW&ê°L{ƒ>˜Oh¨5Èµèœe\šFÓˆ$<Ğ³x‘ç ìøIzzv%ñK-ƒyldØZ ¤îÆŞÔHM–µÈ?>Eşx¼™pæÿÌh [ ¦ëàL§æ³ˆ"yŠ€Nñ{=£-¡{ngùÒvQW™$÷ z-3 ïÄåÏ%á“®Îju+ìš¯P¡ÑCÏloğéÔ=»r|m5¿P¿r¡qïK1ß¦şöO"j&ìÿ9V)ãgˆà5ï_ıV¶É‚ç@Áó±~Ï½Œ÷VY´ÿ¼&æ	Ğ†È•‹0ƒ¸6Ë¨¹§ºî6UÌåô¬iÉbPı µ	£B²dµ4Yq’z­ŸPW|5†ô°K­÷—QËÍ§`÷Ì.6 á;Ö§N-B–šr¸mÜÌGşâræï«¡&\ô¢1àª»µğÀ¯f”;ãs@½1{®”p%¶ÿü]c0!º•'/‚*¤[ádv…¡Ëe÷íuÀ¿\Hh,¸Æa°YyñVZwQÕÎQø)ûàá§”Ğ€¼ ôğä ¶Â¨äÇ>„*(>‡ª½ C¡mvfuŞĞê§ 
©˜¢¨+Sı)ë! 	¡YNEoheb$Eã
òÊÏ¤	ğÃ\µU´¤¾ uDê Ìæ—Ö+e9â¼q     È]Íç¦Í‡ Í¼€Àª·±Ägû    YZ