#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="576815207"
MD5="61ed589e3c2881ed8cb66bfa7db7a9de"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23992"
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
	echo Date of packaging: Fri Dec 24 18:00:46 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]v] ¼}•À1Dd]‡Á›PætİDõ$å=´ÀhÄájN]ˆñséóåöëeÂG¨Ô•:C\\zƒmlM©Wép`EWJªlß™Êù/]]p¬‡®ö] Nö¤Ìd¬Ñ…š²ªÇNcŞ]¶&…ÎıªSó‹šøÙçÁâ \¬ñ;ö¤Èhy×Ûõì±ÁÌ%À†^wÆ÷r€‘ºPßí<¸ø´°__ˆÔÉ~ç)WQÕ5!«*ü:2U®W‚úÑÀr•4 ÃWÎ#‹2ê`}³r]»(˜V¦,qå(M–+HÏÇœ‹¼ğ?Å<ÎzÇM/qS•zæmêê)JÔtÚÿ×¸wËÄÖšw¸ñ*$«ÊOó£Â¦ÊvC?èï¥Ê"áúƒ(c)|’1‰æÖĞíJj‰4ZÑ™òÑ;=!¢yfÜDà„prÁ6*€*A™ÒWBÌ?±Y)Á}Ú<	å§»¸ƒî_(vÛeÜñ¸(±J•mñ2\çÅM‡qÁ¥_Œ;Ëá×Ú}eÒ$h>fM]Í1H•ª-`fš(J'PN]‘è3Díé@öNìğDŒ‡Uui€:cõĞgPJj¶±íó|kîëgÛÒõ¶›¸¿b0ÿN”6ºBŒe>ĞÌšÒ<»á^?énÏ>€‡à†
ÓœHŸ·°ëFˆ;0kÑ¥rÚÑ³›Z¬ú
Xò‰÷™ÿl@”YQ‹tGµCÒó8‘»+‘_Ò%Íè-ì®Íé¥ó$Ïl”¬¥º	E‹IBÓ¯á9:Æ1k©şöàĞèñÇ¨eOFù„-VÛùÑÚ3®S9àkv7&­õ(ğo¤–¸Ho"bbt ö>©.I^Ïw9:Ìä?Ü3. 9†£{Y<ü‡1RÈ™¬ffŠF	â]‹aRZ›:ÄT–UªCoªÏØù@BØÚŞLä'•oÈlê¶†z?á
±-f~÷púÒÙì‡¿™"q'Jï1‚­íÖ®øQ~à‚ÊŸ³÷§.Ò«°rë+İ_ëâ
/o¹¹˜³6TËJÓªw¢õ"'³"Õ5t>öRD 7Û;ØğeÈt=ªmAÓ+Ø}¼=V—z_
îo<sÕHS[ÖNÆ&4ˆ­zIŸ¼X­Ì±N?´U‡½·2ôÒªa­z
l-´3E'|¿´ ûÎ“M}ˆÃ’Ä»³vÜ[Òÿ€,áV|¹m¢ÛyJ
V¦¶¯X·›®®“T™äahĞ"2S¡µ5—†X&ö«4ÂgÖõØå¤ì<—¾”ü/Ì³ş™Ğq.ò©Nø	åÎâÈ½z«+±Ô*§`0Šb_l}f?åS¥ı›÷`İ¤Ñ÷Á¦tÿõİkI¢"Ÿ:£A~ÖÜÎJv‡ï«N+ñô`,"ƒ›Ÿañ ¯;øûvYÎfåˆ9¼tñ×ö+YñkLoFNYU$¦ÉË™×jÕDP†×~9À–ztq1ÏÖ‡<Ù#mÉœpsU;xíöŒhPI½ƒ6@^nÇt¯»İGñ‹!œˆßå”Ù±<¸ÑeP*EÙ;Me«.1C`Ÿ,Â;PÊ»…ÃBæšûz~Ë+@_ÿ°ïaß¡^§:£qÕóÃÄj»OnÈÛ?eLÚãò>^À\IŒg;»CyÈÕÄ¬z¡İä†mİWÕ¦†>iE*´íô‰nSÉìAVpi«!ˆ>Zé¸Ï¿"+5ÓÕZˆºÍ;‘9]9ú×Š0”µP¯åa wfš:Sqƒ9@&WnçjŠ.îâMuC >710İ6l+wTT½%UY_£³~møa a%ÄP(\Óƒ1fY”Ò‰Wnä!Äí­A¬§âÊÿX€‚zRÃ5ŸïZ¶.J‹àõ.¾´L —Ô(Jv>…"ø#
gK*à1nOjÎÂeÙ¬^IJÇyÄ-Ü²Ù6«ÖJckeIéÄùl+;º™ÊMÖp1Üc§:+ŸëÁõT}—Pd¯üÙkBŠ€‹Ó=œ Ùì¿ó¨F(Õ;?Ì÷\•õêF½u¦œe1Í4jAÙë1ú¯Ôóœ1s^3ßf€‰hhâ§ c1/Ë½R¦2‰ĞÕzl_j4VëU}ÇN†]ÑE@™à4?¥¯@º‡vò4ŒÎ•<ÌÇOäñ7ª®a™Ô„µÚ‰Îé–Éá©Z¡¸d“ÅŞèĞ˜ !˜ÿbÇ½€®Y8®A²tUD¨^ÛÄúív»(-î£R§°‚ŞíÇØ
7Çâ°wñzÃ›3s’œ­s~a—`ùÅ¾’y¡ŠÎ
+Şïæ —F·"ƒyWŒˆõ9˜ÙBç–ã9¼N[Ğ&Uú4éf.X/÷U»Õââ U¹¸ëö÷Ç@¯³‚øCñ‹øA„ëº©_ğú¬Ù¨uVÖYÊş¨vxî—ÊEˆO™ö»ğV‰J‡²y~h~³'¯Âgmtå:æ•I­»0à€¾øÕÓ%çÎàr`J“R¥Rb×	L·Û°—Š9dĞ«m‚™]­|Ã{ˆ¶2¿xŒÕ†u®œè«‚0¬œèMÉé®¯ë›TJ“l%øŠSïÆÈ‚ÕZwÊ˜.„Ú7\œmUÈÉdÂ„3Òcsé–foæú±ØÚ[ˆ0qKhq”(/ÜªZí)6´t¯¿ |xÇ1<Ó=¸.µ9WŞ¹XŸ–@íÚl§Ù†4Hè…tt	N®À*%Bg%o_;>“´Ò¶x{öı±‘Cj¡|ôFÉ)–·õryjt2HæÒ¡€Ï_<ï”0’¿ıiáÖÌÄûEâ9Æ_Dã&¾¸SÊ”¯¼ä\>Í¿}ä¤}{¤ğE±¿ĞÌOc¿ˆzÑr®¦@K‚  qiª+#Zƒ‚Çz´©˜ê,Ñ ‰#Ô4ğÒIÍ<Ö/%AƒE9~ûZÓã/ÿÕT=>³{-‰y jããGrôd—r27È¾ÊS:Pé',ø×$[†ó1å+QµƒKìÁÔÙã¦ ‰PœÎûUwÍ>©ù.¢ñ:ˆY†pß“W•ê‰Â.ÿ-ÃÂc—›Üƒ6)™¼Îğ	 ”,³†Ä±«Â…Y§öMìA¿ Œ¤ÑZkùËfháÒ›¥‹ıÎ	Ë@>&…Ï”_TÓß;'¡	¸ßU9˜{÷LLbŠ‡“XÜø[‡Ñ‘s„4˜ocIàabGº1YtP“HscJIŠ8{¤«è,Ò¬ML¡JÁ”€ĞfÌÒÅÕÕEŸ–wy—O? ¤¿uHşóR¬¨m© u¸+aÕ˜wJ¡*z]ıC€‰¸5à§4å¾]ÿo‘Ÿÿu,éì†„ê-SüHşç~VÙ<j]è²Â9ÏÓÕÁ†Â$é
I·æÃ@†çªÈ=÷ˆnt‡à0’:”å§Ì·ù5ôà’ RfÖYÒõ7Çºšıù#FBšÕV­Âr¾¸cÔĞÀïyŞ®)çRùĞôFÄá}>-'!ŒÕB¯ÕıëŠ”×ë³bgDƒæ³~—÷eÄŠ`†ÑÖív.áš ‘[ÄâYæ†u˜™!AÃ¢˜•ŒOß~„P¸ı«ÒÔ5÷Ûeë8”ñˆµ(Pºƒh²Ö¶t[¿+/—ö]j§ò›v	)Y–áõ^7?4õ–Ræ€lt!J~Y­¬İÓ°Z›dç.©”>ïx0ªmúPxá¬äÈi¢Ì´Y¤mêA­!~BG1–£ã7ñ&e­Ä`Ïq-¢:Ÿ¥µ	¥p2¤Ùà`#¹(LĞNCo˜qy¦¶ÂßÿMÕrLTÏÏ9¤_1 Ø£ÛW-mÓ·#,8ÌÖoƒÚY`)ÔÍB (s‘8·fb(|.%ÔêpŠ‰0^»G‘ü#9Ó;%‹@ÖœËgšÊd¸Â¾ õ¾¥Sü|±€hèF}Ş]ƒ8›%/`ÚÄ}3äÎ™t€à}‹@=YRËuİ¸Iiğ‘ÛíK-xeªv)µ. <ŒÜÚfªıQTº´ƒZ”gvQSëuá;ŠXïnHMzT&>ÿßñ®¸ÆÌ;áwİß¡?x.L$Éñê›EÀíÕî>şBAo£§«Z®5Œ€®-Ğ·‚’Ï)ÊĞ–oc}¼BwËïùDì|ÕH—¬gO8 Ä—il£h%¸ˆ~N–ôMõ:H¤o–;‚j‘Ğ%§ï@©K)‘DÖ‚W©<F“—÷5OÕ Ë*§Îctx˜;3óA¢/™¼†›{ç´f£‚¤gP…ş|Á¡4YC-®«¼0p¼q€™ìEÊ{†”ñV’ÏhŠ´Ö\ÿ›ôãĞ¤§¦~Oa7­SÉZA.ïN7¢??É«:¢Wõv4ºÔ^Œ[yNxÈtÜ^ùämA_­aÍG»¹¿")Dyx¡^¦Ï[ÿô³[M3q™!öö–fBËª!j¾¿ItP¸{4wêÈm Ív¡ë¯=;Ø4«ÁDª2èïŠk„bQ¸ÿ³ç	…›ĞÒƒ”ü_pÿd"Ïšó£ÚÃÖÍà:"<«æ`J|ñ@QÅÑ,–Òm‹Tf\Ì–®èŸ£ N¬O¥Aì{0>^g&Ì¢‚‡F¦$˜‹xn;Ò.Úßf¿²™|GÕçäˆ~gS&§g/›è«COÕì.•Å·İÍ?Ú±ZöSî¡µÇD+&V˜ÄG…’*aß‚è[éwñg—MÆØfié1TÜ•ŒlÊæWÚ¬Jæ)×ğ˜£Ë£qµ?x	(àÇjJ‹@rİÉ“(Üg’5÷à”‹ÅYPÎ<áºbØĞQŠw_q\Ëc*Í óº2å¯¥&Pj+?¬åµ”›ágS¤+8i$Ò¢LE4uTıï­NS¨Q3xšLaX	IXB‡<Pı )Õ¥Ë¾Ã¨öÁNáh®ÌÌRr`Ç66´0, —Œ*İèYğøcóY¶I`|mÃMS2&Ù#2˜¨ş‘Øíê44@^viû“ÀäöMoa®{Ì÷GŸ±…³RA(Èù"¼èÖù|¡YÌ(äk×Ñ„=öIÄ§	¡™ eo…1©İNŞKºƒ±Vl¶•LÑ¡¢5Ç4¤‰ó=ö
;Â®¬7 MÁ½ú‚eò=î!3+Ç‰›_,Û¬DšPZÙ'8ëşKáËİ„^z¡ÀÔU^ B·Ñ_ÅëòÿO?Œìˆ¨yXl	”‹Ş\’l@ËŒtgØhÜæ£†Ä=/V‘•A=´(ö	ùFì6ëÙV™–ŠµbµØéİpÜ˜V+“fdz“o[§ß™™Ğˆkë:,3ÌtãRƒr´àºbêÓäƒ£u<™w—”ÏPõm›/gS3%IÜE Í˜f/kez“Ò¼Ÿ†,ïCÁË›<+Çõù†{èş›‰„mŸ¦‚@½^[§*Q”¿5Ë7¢nÊäe®©¡ö"§š¨_àUÉ^°CÌJ4Å)EmMğÑé{½{Pâ÷­ ÿçaxo¢‘çÒL¥}àû†Aâ-{1g;Æ0õut•^ÓÆ¦Ÿâô™WOùôú3ı^şö£.YÈ^IaŞÛè‰&Ì0gšı¡Ï­~ ÍÍ+W{v¨6ö95Šñ¦ÑÙ<€„’·FÓ=÷±À+6	XËˆÖåe?‘4± ó«^‡dÁÙÜ¥UwiµÚÙäT“æ”m|C¤´İ 'HpÂ\ú¤•;{ÔƒÖÄ’"L±b³gÍÁ)|Îıˆÿ°æ²’‡ie¿‰Î)®úndzGÁ«Ñ	ä1"J[Î'²A³9‰ù‡Öı¥Œçİú­> 
~‡H]ßI¦j9½Œ÷rtŸËã²•ãèBlpy³ï'LìÖ6Ş9[;:€¦rÀ"$«_T2ó7«ŸŞ;œ¢ĞD¡qÂØpU©)œÿ´á²1TÜáøÈRe¢ÍŸ@Pø†Ä¬_5ğŸo…UÃ¨§ç@»õm¯%DŒß§ÊUwLlª(sİŞ
áƒ½CAA{¡iª<{ ØGîy¦ò…6 °yZV(VÛ/õ}è€ìDÅ$’=^í¥V¿µw8rıâoFjü	XW±ëÆ/VÏ*;1Š.š¤ŒDzzVÌ?¤[)~s• ÙedJ	ã¾×í›|µ+zàZæ¹ùtz7U€šŸha¯¼Ü "ŒiÜ´Ö›æ&Z_Œç¾ê“ÀŸeô òHdÚÜq\²ùSó)÷6:>¿Ÿ÷tÇ„µ+hÎ—í,ÔhjÒ$î`zkà0ÂwkC~Â'¼õ	âëİjòìLw…a×šÔd4Jº]UEÚxß¢(éƒ_ùÿºcÀÿ×T/û K.?\šZ6kÕµ©¢gø!,:‰
ı
¤%´<Ü)yrbwÆ>âZÙÂÕ¼uöOçût oÉQ?Zrë¨Ö®2&¦aˆz6éİ°¯#‰É8Ù¿İˆnĞã%û˜†UYnˆcK¥´|œü”§ŒÚ‚c*6“‹¶ºA²7„ö-®÷Ï•™+tªø/yw Û€È×|	Ó_åE?'É›ı{şr6²°®õ8Xj5•/sùìö¤ÎÊr¤¼´cLlèB4XX[sn	Ç >¾ñÎ²¬m{àì®²xŒî•‘'á–W¡$ùàÿxs%$£SÒ†G~äõ6Hà¶$µŞËs 5|¢)^£„€¸%Öâ1ßÔ†Z”¼(şd÷ÄË2Å>†mˆ\îøï‰ÀyØ!›Ÿs4Ü„pä2]ËBn’ò«g®²~_Z@¸J5¶u~BÃ‡³õ,ìfŸ,idÁşä#?ÔñæV3UÉ9%Fqƒ,>Ù•2ïüÑ’ÊúvÂ—YıOÄ]ıDo%ø’!Jr WWEq¼[å¸‰çšô}“º˜Ş¡ú"Ú6·j2rÂÕŒ‰º¼ô¸^ÇÃ|7m/‰²4ÔTÒ/—Wß›û7¤ó‘»'¿WÅ˜Eâ_¤éüÁËºV*9¯Àö}ºõ(‘é¬6	NH·š›ŒlNã™w„â wZ½(Õ©¸%Æ÷Ú ;kïêÜXå¨Œ"ÕÀzÜ^³ßÆFÍ‰s’ıRúï½†k ”fV(ÓäHÑ˜û¥rûşÙ¡=g
Ü4rûöËˆákcƒt“b»>¼h úÒ we€¶	+<)`(áuC€"ãlØ¾ÈPQ–WËõ.qßÅaíQ”‚í]úÛ¾êzÅßÒÃßÛF*ÇZâ”øZ>Š;6—¬Ûg¢îjœúDh¦ö´Ùä“ÀO¤ğaÇT )“9*éÇŒ¸n_65Û_İš©9
µ~B‰¢úñ°¡,©é\«çkë!éëˆrÆŞ*‹
õ¤&Fì>8Š^¥[4W!„¸âìÜ²Â<‚}®"?ÒrC,MÈ5Dº´ı´äÒµ„qWA:<Ñ.`¾ñå!íİ¢ò¡ŒAÓ¬)
·téğ±œ*(®‡6NA¦<f¿n@ôĞMæ×GÆ˜Cß m0pê'0©ûùôà½ÿ)iÖ.kyø`JÊÛ©–_^g‚"¼K˜@í+5ıqô¬õ„×^?PVËÒt¦ÿ+xIì»×õwvÓóû=9‰j¦JÓÕêˆÉš#Ä^Ğ²^fªç"~E)}?fn€ëjN±uˆÅ\—øÃ²)»_Á ÿÛm&ÜV*v­Â¼º€ÔU÷üiİ²ÈnI'	rµ>„Â¸;›]ĞDé8(½>7‚*åy}Ÿ^6I>Ãš[E-ƒvS¾:•{Ag‡£Ê·ùñ%2N-aBâ)ÿzÃ°t~Ã_ ‹kæ¢£¹Š€ÁjQ	Ï•3Bìú¤ƒD‘^óµéx’¶¬,ÙŞÇ~ğÛ32Æ"«L–µG~
îe ¬ó1ãÆÇYÂÃôMˆY\†–g¹Q´ştÏôi5ÀìN:a>›fôY™Iš:òÆû…Å$•M·Úü[Ì8ÊÇ¯§wå
ªù‡?;F£
¾Í:.×x—ÂcŸuO½éÛBhJîc“å”›ATÎ´¾ÉËÑ††X!±à
8\¥‘ÅaGğë<·T¸Íb¹AĞ<Ô´Pµ«Òz}ÿ~X:fîbÑ¾a¬¸¤÷Õ°õgoäbš×¾ÙşÊÀ!m»çsÚ;_K0y5HÊÚÑòğ±^k´£…Ø$SĞû,Ê–@÷´‹cÔ&Ã—	oL@Uû1ãñ™ »Ë‘Ûykoœˆ­ã:ênJÚÇvKÏ‹'Êa< >â@ÛõË6æ¡Êt\«E´AêeÔn×2™A’8syu¢—tîÈ|ÀÈËŸw_,õdß§”z8,¡=·`3‚‘$åáRfVÄôß<Îº|Z‚Ávu%ztsp‰ë/T_\Ë»ñ€ÀLRùRÒ£l+’ú}¿ccJƒI²ó,9‡dëöò-ÔşénTi‡âĞjN–ì¹ûh®¿;C¸Ú”jŞy&¹ıç¬ı<ràÌÜ11Ô_±‘¾xºÆB\.ròÚ\ğ]Èux‹Weæ6‰§ŒÈÒŠŠå“{è7?àwÙ¦óm’'óÅÅ*m°K±ş°Ôày‚Ï…™N;JNÇ¢;&AÉtŞÊ×OŒA©C¹Ê©FsFd‚‚'mº'­^úä¾E©=P”\U‰™2'›68dV¤>"“#Â^şŠK:ŠT¢UÍ“‚nöwâù–å#‹¸å)>jÑ¥:/ƒÖüÖäesQiá.w)à˜µ,—÷ÿ]Âıx® &,ç,ÚäÙõ˜'5âµø}ÉCÏ²_Ö§/ã•ãäz|-ºPáaŸ<{!‹T®×‚Rø´åimz=Á™R™Ä¶(ş "(ˆ¡hûŠşiZn¡3b±ªlLmgF&İ`Î ÁñzGj?dØäÄêz3Z…»Ile›YsÌ?¸µr{(P3o™€ö!Ò¿–GûÆ±i!Öx1«§¨.ÑY€ÖŸtÎeE@şBU!ùÆläc	$xìõâÃ1j÷»úO¡?¨_İ¼­ğEJ™	ZÿR_qA“vÿ•Øm¸ñéİÒÊäšSŞw	à&ºßm^¯üäyO~KÖ_^8áæX\Ãí¹˜Z_ëzài$0mö£]¾~_vú_®ì†>Ø)¸‘©†= E7Òñ¹´~ ¢e­ıtHH¸]¤äv¢ºã)jÊA¼¨à[póÌm»œ¹_ÆB½˜YóF¤ <òv;õD@ÇÅĞ0ØÍÀÈ¤Q=n7/€×­é_á•‚¨pÆ›Ü–³mõ6HÙ–Ã”ëøúñzwéD,¥œ†mW¡aá9HwÌ¬D­>ûAÜ¢¿ã»>×Àa·yó‡C	ø<oÈ7¢z½gÕi'"Şï¹nşTY,ú÷]›´³º^Ä ¶nèéÂëYZoJ$l”vèTÊ|!n_^†•¬N¢f²µP:¨—,¢ÏïV¤'áNŠÆõvæ˜¹1Cv˜0-OÆïd\\`œ®Ùş~Âù‚N³ŸæHid1ª˜\×”öŠŞ¢ío9"åxú(«WÀv åÀíëº´Û¢„@ååÓµ±ZËÅT®öq…ßÔ&ÉÑ–…ë¯6VÄ½‹·|!H÷E*•E2ëïLáP`½|;;yò7*2€+2»ÉÛÑ–¶ÓdŠC-ûÃ‹gàçêÆ=`ôÌËe3Hã¦ÆÕbŒspq‚\A4É%Ô\:àÖª6æ"Jæ-(F…ì—mZ§Òss  	YX\K™:VÅ»H@®|?¨³h8Em*ÑìŠjã¬a)Ö.œ÷ïsÍcùÎ»Äh4	r–—[EJh"T–ÂÏ³Şâf&»*’Šdª¢IØZÒFêô;Ïâ´OK­IgYdß”Ã brQ`¥ßó®{r•ÈÓÏœ»£(İmW¬°† Ca‘içÒâ’"ÔûûÇ|ã«™ÙĞğU½·DhÉ(~_D#FŠš"éFÙI~,Ğ/BÀ‹†2º¹n®¿\[:ä^ç®BÉñAşZö	•ñ°
1hıºAh’—JËÎ?U˜µíı…G‚> î«gßÍéiGMW¬Üazp³âÓ}£&|/…C¹õ[¦¬¬”ôş[_èß?ğ®ü%áİvB7SGÁ//»ÎÁ°Ä@´®SA½ˆt‡tt<_ÑhĞæŒº«ÀV§soô-a©s7qÌM—°÷6…Æ›X›·¦‹ìiçá×ÏEn‚ÏÀç«Üz¯HÛ¶À¨Û,Øq-œ|G®B¤AIE¼u@šÜ°ng§Ú³µï¶mIŠcSƒøíÔ‰VöÁU°_ËóĞí§À‰rˆ&9tZÊ^cpiÙaÏC¢¥ğ¸“-–ÒÁXmÖÈ_şuxKø—ƒÕ6z_Oa¯@y}ÚªCû¯Zıª¤–ĞôEİ™©Ë¦*û%K’ğ=·Æ	›79Ø<GƒôKkuÉ£J‡%Şşu¯¼‚I8‹5rî,µøGa™!IT]È*zÿ{Ø4îçöñ¥Œ‡0 îô4JLÀg×|0¨rÜãİ(ÈviMä‘‡íf¥4¼åˆ{Nİ©+é)qº¤n!4İ$ê“MG$0ŠÍ6[…iŠüYB¼ºO ô×
‘«j{ÒÔº…ºÌµÕÀÄxU‘rñ/ÃÕÌ•üwÜÅÎ?ñ±%fÎH¶ 
ÛÉËãœ`”ºŸufN–*]s³vg]´õ\­çR–¿-WL…N•ü¦M`%MBÜ¹³Ç—ñ¥ÖºJß\¬¢{¿yz¾Œ@XíJvÀyŸ¾DÎŞ^uQÌfå…×— b¬¡¨®~—ÂxûLøĞ}>ŒEÔúÂÄ¸4“×/}R°ß·G>c,¼Îzß'cüØÙ Rta°–­
]EßLüFÑ[ÏÿB§ß€èxJ10”é:Uè;Õ¯}ciâD|š›_rŸËs´Ñ àä>ÌKí[2{’H¿Á"
VürãHá\5u4~éÓô½x‘“›±+ÖÖ‹H;óRºù]‡ºu¥iÇÇˆ†)uÃ®v^“€2³†2Ÿg¥ĞÏh9$ŠcŸÇù–€‹lÊ]ß3A—1ÃI·üà¦P©F…î æú;ZÖÂú½ûÙşøS³ËË'W¤ˆ1%†3/Ég†¸‹¨ÒÙ6!šŞÛ"ÿ&’6ì%ÍÔ†‘kz£ÚOJÇ¾u&ª£Ğo²öÑøê;Ta!
xG³y7ŒHÄ8,ÊO?„0ÉL° °«UÚˆLpĞ‚."bìÀ’1 z1‘=EU	6ó7œW¬UU¶ënîw—KĞ­¹§Óßtƒebö³¡¸Æ`Ø­wª1chÊ›ÉSy
BÆÔåÎˆ«íøVùç=¦ù÷tNsÄ³áò1í¨Ğ]6
^Aà]†—ç³½8Â7Á+|Zèãi‘5çÿ°'o'x<™[ç¡Ê‘J5L]$<g¥13ûÇŸ²ş{˜ÊázvA›2h¥CŒ¥~¾b¦šÓ"È÷ïÊ°Á‹`³@n?»•´Äë€nB*ƒ€Õ`z´T/¼hªÌÂØ%e #6ª·Í?)à)±tŠGqÄÃó={A·ñ•‹ğ¾_¯Õşv‘í[°7~}¸äS7LX‡ÅŒ!«¹h/ œiZ³2Şìofİ~3»1¯"1XG1Útâ¡u›%¦±Ùà“g|™òœPÇõAõª‡FQN8n†…­31Q|ã
jqß¿Æ
‘îmƒ['–ì¤,^E„T¥{lHı*ƒ”Ü[²>1xÜ¨Fy‹
mŒàAš”áZşè{õ<k¶Ú&•`Ë*ÄıLjÊ¸úıLcòl<¨µıø÷kÔ³"»3*ø·aóªvË(é)—‚nµ{[¦%æ; ^:†Ä[²îÁ'ÃBŸd›˜‹ßær°ç›euÏşœÄ6¡†N¡lµ~®–íiGB£÷µaÅuY“2°ü¥$!>öd·'Z¦	-åû|$OÙV³j÷éB­cdõğ;¢Ï·V:¿™HØØh€òâ+à·_±ü&üº yQØ×\_ú".­uˆË¯İ~eÓÛQ.KÔ'†p§è®	8şÖ=/Uº·)zÄ˜	•*É…ÀÕQÿoÏD½&^´‘ÌA¸‚†ËÚ)Û˜éÿR áÊNšvjQ®½ˆjKkw0lˆÄãCr-mëH¥æædK{è1Q_]{ğhK,h0øù#Éò<]@…¤H.É˜Ä˜ÜôbÇü²§·÷˜H¯%À/Û0/Úrp%É¾µ‰…^XÏDŠ'ØJc¤#›¸ááY.…æhîx¯{¥Qİ¶B©1ÿGÿŸëı¡q
²›É…íÛÈ|üOW¦¤u2î.›ãåpT+ĞhP\túê{jŒ½+ÿ:eÎ*s	1¯Àf+Áôâ+H_\¨ŞÓí¨éá¨ûÚ<­ÅÀ÷@Öw™E×@]!í†Æ¶Cı¹UGx’èıÙxlÔŠ…;X¶½7õ¼„¼ï‹¨qRğÊgêBí$¥ ªuõrµv{@‚èš4ù‡j1^²ÏôËú2…ÜÖÌãùÍë6¶£¡4fwçËs´P(#¥ÆÌôfœÓÔbG×*g÷7¤!ñöÏ~1`e€•€ïÈAÓ	G3pbûXaJjÔ£ú%”äkph§pO™¼òåµß…K9JZKÒ‡[{¶‹©8Hx	¿ä5éıdi\æäñYNDCLóe¥…=ı¼HĞrà:™»¥YØ¥'ÜœÃ´çU³Ç;o¨5ŸòÊóà´¥
=D’¢NKbˆGØ	Är·;FÓk5•Ç^7 ™<ğƒÄ& Ò?É• Ü‡6†ô·"uç§à7Ä.$İüá&Úû'g!ñjq’’Ú­ÆôvœCz‘ˆq±€ÑƒÉ?'Mzº‹°Bş÷•DŠf%……XJrÑÎóqs»±ÊÓÊç‡ªÑ è'ŸÃŞÔrëí…@Ñ­$º‚§ÌÉ'ãec„î	ğ¥¹¹ü‹#GÀ<Gr7«³µ§×:‚b‡6ÎùîG·Ò™ÓÙ/ä ÿ‚W4^»5“Â "‘Iò·…ê|ìsğ²Ûğu£Ó¸NU¤q³L‡‚”Ïÿ?µü_g´Ğ`@Ò‰©3t]×;¾È%Ù4‚À¹¡Î¥ƒÀ'ë9i¹§^OûÄüÆxş5‚ÄE­|sN¸xj/L.ô2şú½ApÁóÌnÜUnêÈ×ò«Œ9£«'¤¥‡çgî+gc4Rj•f˜äB›,,¦õ­–×ÔÍCö˜—¢NLf³±ËğdUÊ>¼uáÜ?~¡«ÿ_\J_È”Ğ”thËÆµC¯›`X{çB c§æåõisjÔ‚Ø‡ İ=#F;ğ)Íg;P‘÷AÆ†Â9¯”ÿ§¹D[‹,0İé”K>ã[¢xÌeİä’‹QœÃs¿cOJj9§©rëN¼Øô†Bä<8®œŠì>y ÁK°‡‰i«I ·ñ+Dm;‘°¼w(¿i b¿'†¹qóÌŒÃ+ÿ«’x›…WYU74K†¾ºŸmT+óXÛ­Â/8ëKw?G%š@dæb&t#„î¿ú
—ßíû[Ä'Ù|YCãˆ<$ct¬#“Z{©¨Ê€!!%ëŠ‚G£6i,Õzçüã+¥íüÃœÏ×RŞ˜DLl—îbTöQòVÂœİä¹‡ƒğo!×ú¼¶ˆw&$oæÔ¹H"ZH…1uH'ı$*ê±ÖË*ÄiW»»ç¿
Ÿ)bPb¬è*£[uı‚®„ø‚¾H­rV½ënrzHëÌå–¹ô€ìº+îkÛ?/l¼8Q•©oR©o¢>!¶Bi÷LÀ©š$¬µ°Ó>~ÙÃwòÛ;
h(f{ìô‡Îß™ñ9Ó„‡°ÅÍO„Jg?±6{ÇG”RÓg÷k’À¬öë™Ì`¨hFcÈW»Ó9gQÍ¯’«ğP…V$j ñùµe˜Òş·’êò¿’s2úW¨ÿ&à‰èphŞV!Ü uN{©‡HÑ=“«õYØİ3ëÚ-‡nR’7‚YºæÊr½X-F…ªlN=şc[ªã…àé&0Ÿ)RLêvÓŸjT°Tb]Aã»%»IÆ×Ïgà[|2L†Z^€LCt”Ëlú¶Î	*ÿ¾ÈS•”Ÿíİ|4çAåw3:åšı3F8b][ÆKhá6LŒ¬”´³Rª…|\™a~á^Â›¿5’ïú<ª¢vŸPXğäGE˜AuEPr´İÇ2–Xw•J;ó›
ç¦¥x¸‚§Èûq5%fÀ¯šşár¿õ¢¦9ªROmïŸ#¨Õ0-Ûa/˜ÖbÈõêsıÚ)0^¿6#52:äÏîÁ_¸¯ôzQ#qÚÓNê
XûTª8ØT3ànkÓeùt2¡W,5àHD‹Jzñ²¯ĞÈùÏÖbm:İÎ«ÌÙœQb=o*.î3‚Q	åş¿»ÀÃÿ ×Ãš_&­óÎ†ğr —u]\<¾Pü\ù¾kAªÏk¦(í)¢j#I<yy*Ê®è£\†òa°nPXÃZ9+8UT".áì~iw˜Ö–Û$Ú'øıvh;fÀ)6Òè_>)1lRäğh°ßMvÛ~wœiª@Ö>ù‰{b"~­Ûîüzl=Â¾é`uC(IõWµ(â#ö›àº÷Ù²sùoô‡>ˆô.öß–µ­Å£Yœ¼Ô|T0„WL½ñ ½\O5“ÿTqí\U0C~AgÑ˜"¾Òİ¦È†«O]ÙzsW˜ªÎÚß%­ÂöohfRØÈ…Â4†5€¨‰÷“Ö'k
î¢ƒnÇ_,Û²l'ò·´×D\\ÛÅ¨'úNÓ”9…v>>³Ï£§õçƒ#TïuÊÔØ<'s Fâ/š ¹ "C@9Hpß® ™ápPºá´ä'3 ô³Ê)Û@¹şÌ‹~Üñù­H…{vŸÂ}ãºìÎ _xCí>#™ÁpÖÓ®ØoOÈ'“ô7óÌŸˆÎ@,eÿî… ×îö^WPeˆ	Ú‘©¬÷Ygo2EJNåÍL0øœ‹QZƒµ\Åg}¢ÊÎOgFÑR~ØABİ6ÍÊ|#^
óprŸò%4bŒMB[?Éˆ£’˜Ku‰ Ç,()-H[Ç™^®ıª.ıÃ"¬Ã&o¹’Ì²®q²C!× ’lüM×ù1CGÖ?€kƒ¸ØíÊÍúÏyÛÊy¾LÄæÆæÓİ0@ÃSöj1ËPĞLº!D¶ñøú½:€Kø:…8z“ßLxšg81@¹?ùªò­$¿>OƒÒ#b‘
yLï®5Gæ)yÆ±ğäu?®`ßnw Û\®píÒGğÚ0W¦^_ÊøIZsh;"¸U>µı!¹a3ßô ]Z/ÅäŒ'j¬¤0¨×CÕÀùSë/X_ƒi`Ô—®§i¡#:h¾@£ÇT
û—Á‰<Î‰7x}º?:Å—óH¥øeà~H¾i&Õçƒ¡—î}‰=”]‚yÇ<:ÖÁVHÍ4ş”BªS`z7ÁñBYÂ‘2
w£[z"k‰É`J¨ñTùÈ„§b#ˆ|à¦ªÑ(ô±ıëè<ÒoÓ2Híº°ëÍ	œSæ&î|ÁÎ×lPÃÁç†s!Cv!¥-]ûŠ
–úüş™”Ô{.şû~Š¬ug®<ÁdT²Ä †·6ú…ÄOªĞDÕ¥®	š©œ^Ûë'£²%áYmÛì.=5÷ñCMQ-\·|à‡ÇIoBp>¶âÉÎ¶¯ìLÇ¹~È+õá ›9OW(·`Él’…ã7ƒ‹Ö¨§ñØtı'Tã·ˆOáU–¨šáe;‘FÉw¼&,—+Ë¸ì4¥®kíqî¯j÷†ÿĞ'ÛwçÆH0/§Ï7–BZmWK†âåFé%O>ÆÙ[x9iÆİlv‹AîÙˆ€€m­Ãú}bÍÑ)mò„…«Ad•ÜÖ>nÃq§+—˜Í0Kÿ®ÉMìÎM ©47Eí“ù¢¸éåÔÉÓË+f*è{h
›A‡QLîkAëc”v™PTîß"ßÕ¨ÛgT‘ıQM¼>ŞÚÔ°’á€Œæ0—•spµÏµ#_ÓE'>ˆl$ª¨£šì–ßC›ùÀÖ©Nıª(€¸{k‘ıtµŸ¶QòÒmÒ0ÍÛ‰]öqHå³¸ao„²ïÿÙ0ç2!ÙÙŒKlŞÄâ ÁÏ[-&xÜ–÷­iÊ`&k¶í5¹¯RÆaº°é8ˆCõaZ/ëIÍ£×&¥¦×º;4—@[ò—ş>·xd3x3K¨`‚lÙ9­‡Ë…B¹U]oôÊÁSæ§İÔ1	ˆQö(š4T¨×‹öd§–$E•txÅÁïĞ>3®Á¡°%‘éë!üıfıü¾ìğS¡6&úl’j–]qI**ÀÜZ¥~©@HoäÁ¾,£Ü9Û±xİƒï'ß[‚™VáG5ğ5ìXWzàòyZ‚M¿q˜¤¶¦âbÕæ¢§xÔFÚG4nÊow™¡º¼?°BJËíÒbzÕDu6³X=ÇÕAÂ¥£qÀZU¿]ñmLG>¨Ã e˜ûaœËÏWFü™ö»/pJZ=\¶›³8Ö—8>åhohÁ¶k_A~\ÂÄ~OUé¶ÒÔA :pîÕp©ÌKQÓ
òóÎ_æUĞ¯çl*9›zØFR'H‚óêŸdz«³êHÌ”úÏÁgL¼³tŒ>…—Ø@F!H„¯ÀD-ßÃ‹øÌ%Jıo¸´H_±ğLˆw—SIubb7Y»»%àL’±
z0ö5œ4¿qhåŸ·Ëì|ûğ&+XÚò×J2[’‰àšOœ* 
di-™ĞUìƒr%S¾aÉãÚs|‰‰ğ4D§s«@3–>AOúÑOù,dL?OîLªaÅŸ“ZpNJßYºİjNŞò²š·HFrÚ"ÆŞİÄ‹°rµ“LèUsKuùÏ(×§•Äß1•—VÅôÁŞ.@$‡ş¡è•Ğ0ñ¶«‘tS%¸›x+¾¶‡¼ğ›Â	PØ&{#L×z:Äµ×Œ5L5µCIìd]àR²â¬ÏY—…mhE è·-QÚ¢ô +šq¿PÒÁÒNóF³©›¤©"râœ¬+µ1—CªâU±t¨xzbûzã÷d¨îøø3Úvš˜\­BœtµJ3ÉÍ_¼Ã2²é¡Â"«ç¥+FÈÎÄâZ‰G‹ÂÏ„}z|pÎíòÕWâ¦»fµŠÙ5ôˆÿÌå9¼`áÆuy+³èyyà:Hv¢aMyg\ø…~—âpyìêi•±|übº–¤ÎçĞÓO7(ªEé 5=ÒŒj«._7í¡z3†ó`šz(¤BÌ «àÈéBKÃS<ÏšŸÈ•ºMMlÀr_u4ëÉCÚ³á†ÅOQé!)«ÊëOÈ3’²ïù½mÔà28®Fªãíë·åD«'«o2åÕ\®DÔwÌ Q8œÄ£ˆ~Vv²,Eö-Öß–jÃË¸|‰ñ&;ÓJmWuçú$d8è6êïÁ¢`e4ñc3î~äI1Î”wššZ9”yhpN×S2kìÏx·ç6QÁ£ø€[O=³Í¼Æ¼ƒBçOí›xn`¨»Y`óúQÀ„Ò¡ô,™ç€k.l©ÃY»æüV•¹“mN6’eE1%GHå7öºÌ(—4ç¼ˆÀ*ç£FYğSÔ•U9é“şš›ŠÑ­nğx_zfãi
n7;^n;“veû+^í¸¢âİÁ>öê^ï»2HRæ `òæ!qè:¹ìLØ}—Œ‘+}›r±™ndcr¬åbP
´*¦+J^…T§4 ıÅ;wFïFƒQ0şéı?”Ü +õ¦°“¦hWã“ù"Vø…: òh@Xˆ)pñgVùQÓ|ê$vË“À}fö0Å¦GámÃÂ‡ŸJ
©½ô3°şŞW’Ò¡kBŞ–)Y¾İöšB”©kyê.#&B¾í¿[0”É(+0’ñEøÌR§iöb°Óab-ø,Àt<½8mïÍw‡W5b)ûÊñI!uz Å{í&ÛéŒJQƒTö\²"Õ<‚!åR ‹†g2ˆğåQ Ó»ŸfÎ‘7BFŒßz½˜õ*LC¹ßHIw‹Q.®Ùæ>§b3§–›‘ B~?_CpÑŠ¥h£ÊñıTàê‚¼Ojâ}R|xæe§£xä	·Ùzì´¦_y¿†·§Íímî…Šş‡Uû<VX“ƒíhj-{ş	/¦¶ªRµ5LXe›gºÊ·Ù®ÿ— W**•!%–´´@PÈ¦ı@â¨Aò(J¨!¤ï­à|ıc›fRÊQ†ga…âÖcrÿ Î İ)¨À
	­,™¡SL‡Ïb5Èæ½9-äÜˆ= cË\zè	ª.v?r²‰à#g2µâJ©lm.Ì´åY!ò…Ø‘3&NY><6«¿Ø
Ö7÷M¢«“€-M{ÿ8ÑTCM°>8`ŒŒcÉÎV7Åj ³«'ÇAº±$2;f®"D#s’2^|
¶#ÍYä!	"Ôì`˜†Ìr³%´:ö$>ü®”Wø|·˜n }G{Ö„ƒØ3³éRÏ®¬~õ0v´aÉ2Ü¤5…¿¼äÚBª?ÂÀ°kèr}o œ<vîå3vÁ¯TúıÜUe¼¹wzŒÔ¨+/X^\‹¬üğK_ÇÖ7‘PFõSK\˜øÅÉ¶üiDOswƒF¼šsé÷Ÿ€é"zm	?vX~Õ}ÔX–Õ™ü¿u/º›7sö\…ÃÿùÒboÎ
ä£MÇQ	%Ÿ€áüÛ˜@—,Ã+3ŒQÙ ½c:NNüÔŸ…)ƒÏ]ã-­ë¾­“~Pô^…u[£_“.ÇĞkÖåûJ=2!o~n^ËRf&Rj…µs:EŸ²¬õÇİ7ñ‹ã¬£¤•Øé)–z¢Ì­wqD*ìè|´Lğ%ÈŠÕŞ
İ©>}=áÅùÄÔÌ >§M.¤oAIí1(Ï$Åh(®U†Š7Úã L2›dÙi.%Ã1ÄÇ¶â{¸¤3¾Tÿ/>a÷±J¨T¨ç3¶×Ÿà'(CMéÄ³¿ğ\¼¼ÿğ~¸@PÚUõtxg@)ù„zŞäy-l—UËKÂøjGªMÔs¶f¶¸ 5j4Æ€#‘¹âì´ªz7&3×ĞN‡ä¯Õ¨©·}^ë¾2öğÿê/¢bŒn{>|„úB1•?¸Ûlş4VÑé²‚Ó½W»”MÆzííZ”l	?ñXÓ¤Û2ÂC‰tzTmš€b…|*B¬F2Rë¾Û&F*İbwç£ÆTp¿4­*ö›ò"š{¹ÍìãºKËX†;8Çw<ĞL%m*yœF‚[rdŠop	!¢œ¤,V0K¯µQí…dµWÓ{Ø¿/ÆƒËœñâRZ,óòéuĞ€ë•ªZk1µ­æ¸HĞí`;òÁônlQlµí¦ñ$Ç¬y5§^uë-Ë¦,Ø]XWÚ€ƒŸC7µr1‚=†*É!üTÍŞXñ¹§T±ÉÒ3iLc1´ ˆ„‚°0ôçUoY…Ÿ;ñæÓ›Qb†—ş6b´Qéá6p£;,,ÌM¬ù1òñ6´ˆIçBB~tXWÔ‚s©=2¾¬C+!ñ\ê÷¥:CfË©©çfpqõ÷§&2VgÅ?½¯¿?=8+/òA!=jc(
¸›©3¢	ÃÛLâºB¼%*Õ†½C¹ë[œcoÖ,A×p£Ÿ›QŸº]‡ßl/@‹¾Ïä9GXuAAÇØo
• ZîTÙA<Ì¶FÕ*äçüFÕ½¥=¯Ûƒñº+Ğœ¸
T5ğ£Ÿ	™sH¶±÷×xfáQ Œ(Oº·\àCB×È|“àªMå=-³°@D’³R ¡b¾‹NĞÈ°	ûŒ½Q§(DÎ+“òÚñvQ8"kS—xV·{›¤ã#‚Şšf”dÉ^©U¸Y–ïËè(×
*,F/¬Åíµ°0V±aæß¨ª}„ÙĞá.œÉÔ'Ö ’°¬'ÜF âİk›ğÒ™^%äÍîSJ´f6“iğÒñHïMÕSY3¦³Àñ™ÉçÂ4—Ã|`Ñú£$ˆŠ0÷'Z"$×ÿé“¿Ùôqîµ¬¨Wq¤Kk!İ-s¡Ã‹kx²¾Ïå=EÕ°˜‡ğ=˜ dÕ(½y–­L'.Î‚}ÓDÃø^QãŸ ¢ª
æuö‚¼$ıF?¥è2>Ê7K­I•2÷ñ™6ÕœÎk‡˜{Ü«ø©¦ÍpÎ[‹>¢Txš|¢ge’nãBhÒÓ[‚»>KGØ6¦ëÖßìß±€u…QÉÎ)Œ.¸©Ai—hg àX×P³‰É³OÕ¢|-ë`êBòxƒªÇZ–lmê½C®‡Wß-ÉaÎW(Ø_3 áîÁhuÉ©€ES0æm¯¡6€Ÿ¢!+ª'—†	ïÙ—® AzøÜ7©_Îû¤¯‚¦#lı 3–ìæ
ÓÔ^±QÇ"öb…™ïO\(DNÅâ9mGğ3,yXe}”á3_ÚXëÑànp}Í˜püõ2H›ïPµ8¿B8Éú×g÷_•Ã–t£U$ =Äİ$˜Jg¢æå_"•ïœ=)ûšLâ£Š½ë€¸ê„ù(¹qgæ9Pzp48Ñ(Ì{jÀ¡;ğ™µš¾€U–N §¢”ùëòËQ+û«ó^y+µµ4_„’¤ã)f0qdÄ„‹Ğg±>pt=']Ÿ5\‚fãEPæÔBÕ Î¹Öº’¥Ål£D’£¸`
º"uJ…9…œ	 DzP¿­!øûŞÊ˜³˜ä`La²f¦¬«ÀœzÛÇ@_Òs¼ĞA4Ûvaªâ1ÒH Lq,Hak&¨å±ûÏ(òQâ™®%ÁÑ¢ï	L¬ Î†4İ¸h
õ—¨Ülxl£.ë:Ô°ÆæMw²º°‚¾}$r4$_?—Æ”.ï•äªDg°¬`=Z¼0pm0dV¢ˆb¸mƒ°!ÚY‹šŞKZPUE\}M «R©Ëñ¹Ÿ,gVF‚“n€ºr<-Ä-ªEDk!Î³‡¤h?ãİ“	HúÒ-Ş|ç/ò•–(gÏÓÜî[‚2ËQtÁàœÒÍKsö€ÖYË[mæ|+Xë¦v—Mµ§™ŠNê®ºiëµÈ{"|ˆL‚ÿWUºĞ®”V“0ùZ7H½ßR³}€˜j»Ç¤Ìµç‹BËLÇ54êõ;Kúíêlœèóré‹~vp¶YÖóô„¿ƒã2Á·†¾½?s?­’ Xh]³;Şï“oÅQ€^±-`¥¬^<eZµ¡U­\£F/OÔ€fŠÓlL³ÄøsûCÃDE„9m¦ôjJN8'œi½”Ùö™÷
Ş‡ı=0*uñŞ±ÍÛ¹U$¨sĞb2CË[;SJå„:ÄnÇ-¯3ÃH|ÁY?Î]ÄÛ’÷e+!ûË<Æ›5ååUYU{@ë‘ı)¢ãĞq…${ÕùJÕh:DZVl/_Ê#ß3R\F:ô¿ÀŠˆ_¤"8à¼`:3³Z6í3œ°ç{Î‚õ³ÖÎhKi÷Ğd	íÔÕ%Ë‹<ÏØK'—b-#¶Íüı_ß–^ê÷Mb‡Â"'Ã42t­^,¼€4ŒI	(¬Â¿ZoãÍŸEÚSFÈ¹¹ÅÊ÷øHÀzıíØ\’á`îü<!ù5]k?£÷
§V&¾$S¹-“|Ş.ø¹ÍÊADuåE¥óe4'D1İ(LİµJ/Ë°‹Gdê°#{í;>'ïßõ^¬üR‰Š\0ÖQ3·Ì`È”P
ñäŠ¿*zƒe
 Ò´Å(…½óôø´T`nºël8úñp$\­K x!İ¼TNŠ"Áºÿ,òŸ.¦~›–’Fb`v#m
¯`êU´©şÆÙŠŒXÇ²šGiˆ;ƒ±÷ÿÎÚ$IÒú¹vVõd†6ukMpìÔï³tÜ/¤İŞ^â?ÕTPÉ4÷ƒictF1}:ó›ÜåJH7Nh©XU„e–M‰Òxá†Fè:K¼¢©DÂıÒ+ˆÓZôµÕW|«ÜjæÜíÉ²â<¢ûX‹Tï¢çÀ”f˜I+bVêéÙı¾¥ô¢¿ßa`ØôjõD@ìáæœZEØ›oRü R¶–˜Iñõn%3mtæ¿Ii]]o_‡|®ín· ADáB¾ÕÅ"Ñ©TÇ}¨âì/]1(˜¼®muÀ$
B¶‘aQÜÍi%.	h öæŸãÆøÓ"ùŸ%bEÙ@Qj´û‰–ôõ<íJÎŸ0ˆ³ƒ‰.&ÅmŸÈE-D–ÚÈ|¸ˆÇCÍ˜N“¾•N¸d¬ÖsÓ+uÉ=wğã+PĞ·ı¬†Jåï‚µm…îwgJùea¨İü¬;a0õÃïÌ‘×±×CJ0[®(İ!²ğÆÙùÑ¾¿¿k†ŸXÿroÌ½C2Â¼W:b›|@ÜØ¶ìz6¤·TˆtW7ÚíëàĞĞ¶g mİõŞ‡¨hM@~Q‡jgRsö’Œ>³5æè¯ô¹T|£˜$ÙŞ¹wĞ!•üé†Ÿ­d(Xüš×øe‹µa“®V2Mptja6áeİ‡Èğ’İ‡Nîî¡-™«uæTtrûäÇ?¶²Pr’ş“o:
àÂE©tĞšøEKØ¥7à}šO¦Ä‡*–V±Šb9²1Õ¯A#V@a	d8„	¢¥ÆJæº±ï¡¨4:n uqNE½äå	Êéõ:0ö‚ù‚±‰ÌÈ_6#÷ƒœ…\¥§¦Ğ§è%ó¥²¿Ş±ÄÙ˜Ml2À‹èM¥ÿ¥B£ùdOmwë¯Œ©)†ûBP¥×ã9®½ç¹Œf"‚w_Kh}Ól*pÏ“Š[Ä­Î4±ßvô£8<‰G8cbKZ´»CDW±¢òò¶OĞnA@boèáªÎİO($LvÇî/—Ô°¬mØ´v¼'şQ˜+€q2ZçK˜ÄÛ¤À­	í×_ê¦‰â=°(aêŞø-’¨èo¿$¥©…2ıÙicà´‘|–ét,<°Ö>µ³²GwæU&Kb?¬>†wÔ„”ç</ä÷rŠ%b»xæ-4Ùdw»Œbu”+ï4ß{$$Êæ:.şß;ÀuÔGaæ¾_Ç{w<µÔA~à[BT{ò{€n"ÑÀ@²ºølaˆ½‚¨#¾€ÖhÒ(¬ß¹,„ıM<™´§ 3hYqk'ÃrÔC&xe^‰Êÿµ“Áwª3]£³òYÊŞ‹jÉ©”7™øÒäı¼ï»¶Ùº6¨¦…ÊEâğ¥FèÈ‚Wûş‡©³{ Ä3aëuËã®Á÷³‡ºb•Í2v
eÿ·lfg+SUDÖ ZñoòœN9)”h,<dUÀ·EPÚ<Q–HF¨ååÌóÃªœ/1®å"sÖk…¢<ıkåUçFz’]´mtè†õ×Ù‘Àú¡û¬¢ë˜¿I‹‡
q)ÚØ¤@œÀ£ıÎ	”¯¥~­¢zÂaaœÈvJÌK7äjef)xkæ$ŸÚñµçÄ)0YØrÛÔ³3öL†¢™İşæÔ“,ûî–°Ú°jª€Ğ024‚cùs2-‰ó­È€E	yEğ¨R[¢Yç£ıèXş-®Øa4–7ªÁÿî¥y)ô°ÃföšƒÍcgu”cü¤p
z)ÔFBG²éë¹ÈÒfPbb5K£DÍˆsZ0ÙÑ<Vèîü}AFÛ%ìtSû	“™Ğª®’ªÔ	sGqİ(H«t™û„<9ñÁæXî;¨/nó9"9¢eÀ¯…Zj´×H&“Vrñ)qlÂ@};Ê\4fÂ™.Á?úÜÇüˆ:XŸıiÏ˜æ›*ß{j˜“ïÈÕühÜ‚(æØ>ô³ïsş¸6
L
Ç®ú#g€PtJoi}±ô©ÎşH[æ¢ñ>4ÿª8ûñÀá[	~³˜<à$¯)0'ù"®ÔpÃÈèĞ?x­¡ä¿ÍB¢')[>øƒiK6L|>°F:½¾1fí ›€'Ğ^TÎkûWlãÁb6xÜÕÊ,ÆŠ ËNÆ0 Ah¼Œ{sá®Ußôù›¸¦ªyV·Ñ°F7zÃfÅ¯:³OÔşğªyºå³O…ü
jaXÕT
Y=u[nÿÊæ;>İÛØ§Ë·‹¶15â1ÛİÏWvÒ¾Fé:¨æ¾	_¼ƒ¢ øQwJ© x	=LØŸÔ"ÜwÔİ8`"×ğFã 8î4¤Ï%ç4.P§Õ…¬¯![BB&PÕ‡j’pĞQe’ÿR¬%'7‡ÏJöÉZrräéŠ" $&€!šEÒ§Ê—Œ§ÔŸ`ıDÚ,şÊÚİ¼s ±‡)< çÁsj‰‹—;ñ~ É´Aç‰å™´ëUáh;‚< ìİ­Ëf<Ì¼i]ÿúnOM}+“7>¿ábáuX³†Ç=î‰3{ójƒÆß`olÇ±Á|‘iù.¼ƒß÷9ƒ/k)ã”Ke“0 €££'o0ò¸Bb)ƒ‚¯Æîb(œ¹‡ûVš~à>–G¡·xFZ/dp2µ~WÊ\„åÜŠ~ª“#…].îLcCa—×Ú¼†±ãÄ‰6%4ÁÓRGoÖô¸qhùz©´‡®«›L¤¢ıôÈê ^­øFíD‡AågÅ­O©	œÀ\ï3v]V_ºùŠ7hr/æ¯¥‡7ÆË¼HÆø×äQv„¦x»XåŠWg*Ì^…à˜22|ˆ™!<÷Ve±>úÊÉFMäİÍba§ş—iIè?‰æä.RfDñ÷@¾…ËüX$§HÀÏ‹Ú£Ô-ÉP˜ûkRI5pø‚àÎ!ÕÄW	béØ3ö‚±eŒé¦„GºU
ş¶íÈ5>Ú¡½;ÂMÈEƒ‰A„½ë°iLBö;=!1b—i8gúd]« åcY–oè¬p&ÍVæÿ³‘Zèæ‚¸Ódìà|sÑrï‹T'¢\]Ån´« ÁÇ2»šçM3Mƒ$ôK‚wuj¸út4*³öÆZ…JT7²´•`-²÷‹4au¸´Ü Hy0Ho85|›¥HÌQB¹Ë‡¥æÖÇ(ÄZïÍ:H<Ò`9}\ÿÜØz“6”®ƒóÓ“MosÅùuè~İL‰¤oà¬°2)(9ãš-mæ‰äĞ%¥Ù8n£Êô?çVêÊ.^£â}-4Åßlæş—ÇyÑT&!íŠìå8p·/=ØnF’j!rĞNgŒozmš_şB– Õà°ø6²WõQª8î!ìeå¬ÕZA´¤¯üÅ=aòá{¯˜-šä4ä$+>å…£5`Hš„7ÿşt¢'³Á·rã9ÙëìHô9­SX[µt\fığbĞb(¬œ[ı¥¶˜zÀşI¸“¨ÿZ(‰±)Œß¼†d"e¤K*ÁÏ•û€ï—ª+şšê]°ïC=Î–BğéAõ29a°M0‡Î‘¼[ãiõñoàÚXĞÃÀ×· ë€ôH@÷©ËÚ4fE*˜ÏöƒmôˆÏuË`käíÒ„&å$¼¼lÏµ“M1ïf¶¯t×İ[€ó©±BÜB0]¤cÆËø¹*1kÒ]Õ…ÆÆ“\¨Şã$N(ñOvG§ÕáJîN›¥[T-¯%P¤¿;™	gÇŸ2wWõßtcƒ“2d$Ö	W›¡âÁòÎÑaV´â±ûÀÏÁ¬æşwbˆNL¦®l¾ì´ÚH–ÌÁó%âÙ#zÒ(ö1EØ¶]<Ç4÷ğpQf¼„èøJÔUú¾SØ¤Ö›­pùzÆ»%;ÊŒN§N²éWÚ¬ì’êß7É¿ËQ]rO‚ÓI¤³Áğ}§4ã‹éÚ ğ´“Cì¹U8kí°¸@œã7(4uÃÜè—¶äiP`	º¶ù PÎ|‹÷R¸JWq—ı>ÜäˆÿO‘èk`>Oîí£3›uÇäàÎ‰æ/8‡ïæDÃ/Bì>ô\'²}’ÎrÜ,…ÈDT¯FM”5şVsŠeÏG·¡
:¸ğ ø6O÷§ (ş]$ûg¹ğ¿š‚¯–e:—bHâlµæ&J±¹íşkmAQ"Ä†¯‰·:'Ä•äĞ§¥ì‹¨Ï¾h ·ÀÊİƒº®>c‚¼g¡©-éİjØ}R­Ö;ŞçœkIĞ}B«ÅşÉ×X¸ˆ"à®>)âG\ŸHCn €‘ÿ~WVás'øõ7ïî7äTL°°5°~·0U÷kuJ;ÎDç¥Ø¢SVè•š§æuR±@5q‰EøƒÈö{4£ƒ4ÉbĞÖ9¡§©ş{&¸^ÜĞÕZgê™±ÿj¶’+‡dĞ†²üaEqm)ù…VHr€%‘Èb°?ÛË¶·0Õ;İÉçèqş†ş³Ÿ±œr{Ë%[è½(ƒ_QØ@HRhŒé­I15Ò$bl—ÑaI¾ÍFõ€ÃÃkÒµ		Úó©=,0;ãl¦ÓR6 êË?·‰ÍÖ§BI@®ı¤ğ!Ó4„n¬cL?×½pæÍè9	ÊˆØÂ:]Á¨3„ó´:ìüÂÄ&?&5fZÅÙÓ¤3_oª$¿.’v26JÃJ†]–×WZíÌkú˜ØœÉR‘S\4 R&ß|Åõ8Œ[>t³²Ê(±•'ØÜ(*ª ıåU¶™œ{nøØl® ScìÉfíâ`M ”î‘m—hçpø
bGƒÚ’²€ÛU±òMÛÓ!I¥ÖÍa¢ÒÓõGT5¹î¿*6×8
=íÚâÇ *ü|C*r:å*¢î@ĞÓ£›U+Û"•ÿÕçE‚W[ ÓøæÆ˜1ÈÊ2Ñº¡Ìâjõ\`½d7{$ôïQú¢¶¨Ñ.Ó[èÑTx¢îF(mx¶ËDåB{ğ"+´k¶ë²FÛr'Xè`²OÄ3V‹ÉYÖh]wR{ùƒãôÑn€ííV {kË”\ŒÅï‚æÀ-¹†²1h9•ë¢Ğîò]öÌ0^Û–{@	g*&änÉÁH3\sccNnŒáu±,£"È†™2¡Ü´Ö5%ã'VÍÏ~Íª³±¡mÏİ×Œ¸Q7¢U]ûäp–>²ëQz<'dçşgÿ3HøD¦^Ñl§ÜŠJ†$`Ë¿`s$‚½WÓåÕÌ 1L)RÁç5Ä <”"D (Ÿbà6@¶ÖùhPÙÖË×æù’0S«Æ#°`ßoÉË¤ö/+K³Áƒ ¨]ùüQ‚F!› jØ‡ıFÒÖÅû¸Q[F”ö‚İqCÔÅZ]Ú„­<Œz™üªÀüáÿ’—IgH³ŠĞGî{ti™İ†í³Ì7X] ÅÓ_]¨ÙT©(¹ìîf÷\c¡«MGËCãƒ´w…DÓiÚ”Ø%ĞÇJ ü¹Ú“)f•@FÕÙÒp4–ÒLòT(¾ñE’_×ı‘:íš®úpC×Ú‘å¬`ƒ¬›ZT$Õëó&è~¼[Õg}5‘L£°[-|^¡.Úÿ"ásı:ú– Z’1’,6âéÌøV“£  é<ì4á$¨´%°a¹ m¡HÇ‰fgCõpŠSš€S2ĞJ8›™Ÿ'#¬ÙÅK–!ÂƒØG+Ív&-üĞ¾Wq÷Òø
?…gÂH:qsİ7ô‘R_n#‹~GÏP?d1Jcˆ)îäÛ·v¢9µÊÆ6Tç#Å3"Ñˆìı­ˆqvû©âÕœíùÚÛU„¤ß8LoğÏ -® ËqbÊ>îáoªjš_ÂíKÙ}Ú•¿Í¼ÖœçF+ÊF°]%ì‰cõ,÷uÉ,àş«¸0ˆµ¯Ú“İhæĞŸ¯E>rµ07£à_ŞßM‘?ßô Édàç_LØõË²S¤³[?š*¨.%[…íWwSUg 5vu]¡Ztj
<yÒş«ÖM}cuùš4	~L×qZKñÏšxA]Üı„;[AAÌtË%Ä Xo¬x«7Õ§%¿ˆs»bVåKDÖ¤êYŞUë2‚c‡)bëŸ .ÒóNÎW ô6'õñÒÃ2 7#Ñ”ù›ÑWÆ ®—-7Ñ^­yòû³Šdóg¾úîÆ <Ï&8v¯tUÉĞÿ•0%·©¤Ø›¹ÒBùJ–‚ÊxŠ—ÆÈ!f<""WMÓªî\'i1Ló°£èÙĞ¤^oXê¸+m~3&Y“b{2œXÁ“;VWÒµtNéÇF|¸¸Ã\ü~±Ca°»#âlûqÀ‘v+f5¦;’à•—4¼//
îçâ¶á¨}d™hh!}¬j´'u»Èİ6)Wÿõdİ|\šCx N$¿1ãv˜{.[óÅgAÖÏ£É«eúœ'ãA^N™6·úDëè)›QmŒ”Š®^ßËd±É}ŠÍISÏ#ûqz¨®ic5ÕFí* ®O„ß{ô!”·4I¡YÅ›A˜!tèŒyÓU œ_œËòMhiT÷OfşP—ËïOÄUz¾OÀõ4_íGp^«(~ôö;êPİd$mQ»÷'äç$¢®°
*h5-F#	øÖ5·<›Ñ§¾†¹h ’Ñ~ø–ãqÖÇJNøEº/Eud¸[#¼‰yr<&›]--&Óx.3}™³ºØ0ÕDëqûÏ’ ÖîirıÓÄâƒø/ü•å“/àê|úãa¬G”EÃ:màÀô0Ğ°ÜV÷ùZd1®JHÌë´Õı§ÎL*üÓC³	ÔH‡^$®D<õQ09´'8'×r>ç›‚ší‘Eœw=Ò(Šš(>9˜j”÷X¹dê˜è{õ¼ÛÁŒôÉ4±€p9
Ö·,!fA©Äˆuè¬ÃÓM7†ß/4ÕÔW/@ÃRKgÁ¶‹òÖ’¶å©ráÆcF¦4ñO˜ì°JTŒ£`‡\¿°fÎ+Tº¿ùVãGDµM®³

×‘ğ&i.ã<yÿ³Us€×H&í,òÃÜ„pğ§ğ$6ù¹MÜ¿ÜDªáõSümq+;MåVrĞ0Œ=¶×íóA s	¥¥´<ëQÏMó—RºÎÀ!oCÎµÜIJYHty³4¾Je&ö‹hÏÎÀm*Uõs—:Í‘µ
ïõÛŸš¢&p1T™Uh¢¨‘¡9­TX	H¾áÄ!ñğ‚FÜÄÜØ¸3
©Në¡±@]nF'|n™î³®uÀ0©d·%.û§ªRâà`'O
š™‚ùEèo1Ã´Sf¬ğTèøyÚù+á¥_©ìFî:£EO~êê¥QáMhˆ~©kéE¢*³ìŞé±éL¯Ğ²î2-?ãämÊ7JêW6½zñL¡ß÷®èÛ‰±. ñÑ	Ô!i«îŒ y§9µPSÎijù‘6ŞhË6ˆjMÓMü¡%Š~îp¢¦«/éx…&nvÊJJ'İ—x~¢£şpí-\à‹~ïóxcíß>è\y.æŠÃSz\øÌO)=Ê¬wß}FÅ¢ÑÔˆëÏ~•[§°ÿRïÒ]dxç„6­çs‡’Bœm`Î,©ì·0×’ò¸×HŸvRVÈü
~ÀùÀ|´Û²l!‡  JËQ;(¼šÍÉ•Òâ7ïá›E0‡)ëÖø¸ˆ—†'J,é4­²éÙÛ<«XIÌf¥“ÓMFçDüî¤ÿŸíƒæ½òXXº*ÖR1ëM„ÙÈ•;Ï¢ü=»Ï•3u¬ûÓ³àıD'?0ë’‹î¤D¶·NkÍ§ÖZäI.Hô76í)êÉi›w°b°ÒYÅC¡6-[iÍF`ášÎŞöÅéûøğë5këœº±1òf-Ô…€è0«eiŞömCì:¦Ó¼aAØ•÷¿ğŒ¢¤uOK¦H1¶”hù·‹
Zr²I­¬İÎ‘{Ôa¡¬ûåıqêdrj?Q`€VúYÄ*³f&‚”ÇÑŞ€2Ÿ¶™¨0“ÓÂãµ‚æ/Ñÿ¡rrÓa·üãdñ§ëSÆšÛğù|ƒ461UTß`€aÔ¶ŸP6¡âZ¼¢??`Ê¼}ğÎL†]¿By3¨Mep‰Çï°+ŸÛKfSœ¡Zõ¿´1d¼Ğ˜}q}¢÷ÒÙ3·cOm¢BÚz)®Nø“‚¨^A6‚aÕSHÑ¼–ÌQtè±(ª‚rÄxƒ¬ÁâàZäÖÿzÉqR‹û5¥zÃe¯Y¦æñÈòx¯çØ]()^çè–qø):„_c[—RS(<	˜Òûœ_Kõ'tà ·³cO	vÆÑÈı³È4j½6òÿÍ·§¢õKX‹R–i£êyù±¨IàŞ•¸™¡º¼‚nß¢BWWU´¢FP€†¤&>2÷ÄH>˜;.cùåÖï o[‚OP&âHäë‘¸ì,1g=¶q]o¶ß³§/uóø±äfkxŸAF–J‡³Ì»©Ò‰(+V˜Õy7Àş¼7+%KG:ĞÉUq›F{ñÌTÎ¾gĞ%W&¹‡ß/-×]ÒIëÌŞš-Ï=­Z–×+ÑËm!ûÏ#›|güğpÖE5ŠÑÓnt-¼id>w,pÔ(€zp.ûuºªÃ,u#Z½^ZŸÇæ|Õ'‚ôo×@Ónè6ÊYëñOûdêïI÷8İU^\šÀÓÆ
ÈïY^È%Ë¢¡ÜvØÜ46çxbi»M³}FõéüW¼üüy&uİ¹*+œmù: )?éxùóí¬< ¨½Ö5O¦Öà`ÌK³[RöÆÚ…&èåŒ9À{Ztw˜…Ú¶ÜeZç|\V'ë‹œÃêµªª    ğëÜ¿åx ’»€À˜dûø±Ägû    YZ