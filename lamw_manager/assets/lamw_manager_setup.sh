#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1258974013"
MD5="17408997d4cf7e0bc276b4aad336b9c7"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20752"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Mon Mar  9 21:40:19 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿPÎ] ¼}•ÀJFœÄÿ.»á_j©Œá6y‡êÙ*¶+@íF%5EßİtÄO–X¸º?ª‰õ‡§2¸¢±ï)ÙÇw"°Š<}ş÷3vf X7w<uÿßÎñœj^r£`õgdmúÛÀ*­Ë¹ÏëtÏ³MÄ~‰LWÄµI%„ß§z&··k2q
C¯s œŒßÀ÷İ'=Òg¤d{lÜ 1‡X³i>¤ h½¢kÅF|¿2óbwE4¥lª|ü)’Œ¦16…#.w±ã—Ws³^±S…PS:ÔÏ‹ŸG¹Z.ªì–ÓaËîİPµqüIÜ»Ÿ½¯y:ÿà‹¸„nÒZÈü@,#ClÁjv~U™ãP˜#Íz·Qjô1ô‘ì¿â˜£iÇ(ODNƒvN,cèï4åê0¬OBq?™F¹ó¶[YÊêòOs‚ÔrK@¹ÑğŒzÓßƒr?^EÍõaYÖUĞ-˜LèqÍl@Ë« pç‰ï}ñ‚záf³œN‡ÃåòEwó•P›I©2¡ş 2>2ö¨7çx³æã’ÔÇšœÑ££4„õ?	ÃšÑ‡b†?g$†ˆV%®1ˆ“õ§*€ÊŸ4‚Ÿ×‘•’õ8…Ô·ñ<ªVP.Ó…,ß¹œ‚±Ë2îi5z2‘¯KÉŞbÄïtı%`ù#ßÓ0˜0yó81ßE‚¹”ŸÄúèÍc1Q$‰3­ÓÁp‡–ã¼Ê©ššÙ44ÁƒGcl­µŠ@Bqµ5 Á¤·	§2tüy\f—$ÉÉ04†F=ÍCŸœ
—E£¹¸;æŸîõİŒ6ˆSu"Ö‚ÍØŞ—ä=	òÈ¨t—eôx¿ƒé{¬`4_ğ6Y$²OˆÈB7€Uˆ°tæÀpøB<GÿQg°Ë)iØão¨Y¥ „£‹§«º	±êjz *"™tçP«º•Hâ8™L 5DË÷s©o+¬šzDˆï¼ÔRINÓªÍ°[…%ÁÇ'e‰!n†‚Hªí™æaÃ5<¢zÅü÷¼½•uÑYŞTú(º,ãĞ.¡Ã?Qá#J7ŠaXÃ{¯fUÆ,”]úì”\œŸ®3*5ºÈL`¢ËSÕ8ßãF0¼|Ë3~îº,¶p¾r^Z˜]QeØ]€ã‚éü{XĞ×EÁzëy.y4íGp>E8!öÃ“éˆ¿’ÊÉyÒA½À,
#K6»êZÌõÚW×€÷Õhcˆ§ìH¾â‹z ~ùA?Ù™ZEAZ‹rm½ìzÆÖ¹“Í¨>jİñŒGkÎ¾Ã©æR­¨¯·“ÀÍ¸Â7<™˜üìI5/×Y=–7s•QM¹U-å Ùê·ôÃàOi¢à)ÚMK[P“M}ø§WIæî¤×3ĞÛ!¿?FI2/€8&%,l$	¶ JÄ˜|º«PRE,Ø7šÏÆ Hñ¯"Š|İ=UWP@İ(ãv„ ˆÍP()Úi¹Kf^u0/¶ÊC×H£	"¬MáPHWÛ
÷"lÑê)Ï‡Ó’Îv½Ø^:—Ğş.´~zCÛUm$üÑØ¥ĞÂ6Şô!ÚG	èu£ÒÌÌ[íQQH¡@¹Şjš¼ƒ(ÿ,¬u^oâêÖ,PG(iIÎ²7b•­Ô°•9‰ÿÎô)›„RÛ¾¡ÜJKyëŒHO3çâRÉéQ±Şd|¦šVtè—°Çy-ûHÀ¨”÷º®QøA¢ökã6bT2jâ:éSRóÈd‰¼-Ò½Øù‰QíGJ¨g6ÒZ¦Õë¤_5Cz‡qñ–d (œ*NoÄå´hrH¼"­²µQÁ˜#"¡}Ô
[}49uáµnÔ’šÜarh_©–¨ø$UhI.nc@ã71„äÄ…Rz_µl9Jb‘qÛ?=¤Yuà#d|cÏ‡ôdVÍËµ3İ	jÔCG)YùÖ
`œƒc	d”ePæc.š
ÅW…tß)æİõÛ:wkÄ˜,ÿÂÂÒb]kPjR¥P=Å/Üsß#DàÕÙ(qÂ‚®È˜¥b#{d­&á^î¨|ÿû/o"æX±´Cÿ™ñ/¨Zè¼«‚ğ;ƒ0¶W§ó]RóÑ¯¬¢¼™°‘_jämycÇ@Õ—ÈÇàÅ‹ËGñLô@ZßgNøNï¦–ãäwOw`$”5F„AìÆåê}ÛPÖ"¼›0U‹bÇ‹¸ÿñ-ÍñˆÃİ«¥fÉëÕ+…":×6R‚4I±ÃÒn¹lPA†A{ÛñLTdÃ¬IúuA˜Må¯« İ&(q»âZÌ¦êèF;Šƒ~¹8KíKn°Rl²LŒeğ¢‹ià%Q€²ñ™Ì%0Ãä3ÀèêÄ zªû—i"”M¤=(nİ#~´8¦õ×$Qòš¦d~£Á]¶şÕ²RÇ»”¬”k)´M ãôÖ >pH*,Ş¢µã;é­—û6JÄŠœıİD3|ôWâ;¼&ŸVÄıëLàÁB¨ï¦$ñ
a ÒàÖ¹6Y{®Â‡Š»Éqå|ë›|x2qÑĞxÑ,¥~ÖŠQ½4û
RH\MÑ“Dı<ŸæîÚ§h‘ßÃòVßªªKNímóÎš/ÉW‹œoâ›†ó”M£Db7çúÇÿŸ¼é„ŸRÜâÚ®x¼¤bLq F´ÒOuOÊa6³”Ëëáiø96N¬à„´İôxÍ9¤ƒQ‡„	ƒ?¼-GcüŸÂx>Zê ¡Ü¨hV‡-µíàNª¿¿É¸ö²LÀï›8`ÇŒGv¨èq­ÂQœbéÔ×'Ìè@©V¾ûÊ Z.±ã½G
;If~şÚ‹?Â`$°üC®)µ‰=çH™Z‹'úœƒo×şOÍ—V÷t`·±“oÓ8@û²è—eiÊ4mÌtìt>F?¶L;/±Á™«	ÿã?Úˆ%Õ l…k†ú&A3éK0çì‡«ü¬Y‰AÚÕ=pîckRèp5›ÄE"Ò$‘=FL=ŸÔWz,k4Xw×•ò¡¾ÚFL¢-ĞóaO::^ñ=ÂÜĞŒîs3cï[]›1Ÿø‰åáñ)éjÙ’w-jĞæNİmkJ`ı_A•íøij&áå¬ô.D&L\oàÏ½JÑjjE^Å3JT"ç£LÒ2“[DøØëQODMúøî¥ª'×ÿË¥Ûÿ·¨"ê¡í{éoÆ#-x’=ÎTöÕ;è¼hµó
ğğx~}F`eXaóÙpf¸ùÃ1F…şß°uQíraU$étQå\êğ¨Ø¢ù•%Ü_çR×_£^£D6Â3î~¤9§ß¾zSĞÎfBLµ˜ƒiLğ\ª«Æµ„,ë’¹Q_ÊÙtüGh,ı¹=µ·³_ş·ØÚ=g’m…½€ •Œ?•òA¦º	DÏÕÑe¿ÚzUÄg4#›´¥½â?<½1k|PßA„}¾2ÎîËİ"_
ËCîR6wWjÏ¹lı˜m¼$`ƒ¢á·Êè!RY¾œÈñ… ¢]òfÁcó…éC€±Eëà@ÄÙNÎ.Z2óÓÁ8¨§
…ä³ÒÚ-päœ§(ÈJ¢m´q.©UJÓ É@ğp¿ëKÈÉø˜³Á¨ƒ	îfÍÎ>w Èè+«çi
‹^ÅïJ´Îè{4V·ÚB³z¾tæE6XRƒè{èŠ¡â¢V­”fmzDËø™UÎpÜ…¢6åsµeRDĞ“R@à`üı†N¸‘ƒOš©ò4)—J=¦Ó/Ç¯ßp,DkP%$Ö.­Ñ,ºÖäĞø§çãò2 yy«^Î´ŸÌşµ}ÓlÆÙí”!ÿÚã€…3ÍHùÙ(GĞº­E3~‰š¡C%Ôìg¸œãCáY–¿y»"ËTzfœëÉ²qİb6ë±O	Heöa0ˆ:9œÚ[)“YvÃ»º1TÈôïC6yÆ4D Y×ÓKğüİ êu|bél˜â)3nL”b/œôÄÎZå°ñpiMH1ÌÏÆx¾8,øMª{š¶û3â×Œ–cô4>K(ÀzâQÏš?CòZº€~Û8áç}œù›•nè½ÜwUÉ€ËÎ»¾I. S•à;ƒ"Œğoİ-p+€zIñû hvMı2Äøœ¶A1f9 'º(×õ5»¯g7Øà~ëø²"{ıüpWaP}!cÒ|Ò¢²ó†³Ã`¿ï'm`s¿œ¦…ëMÒ‘LÆL"F ëÜ°Ål,á²·YŒµá`•ì	óºÊC[<ˆüü¢üESïx‘¦æ“+~JŠs íA–±©x¿qRnnB/)kXË‚o¢óıß¹ùáû÷»LÒ4cÿyQßv“A>ù±¬µ‘îi]–-“ÂÕ1¼¼‡­_‰HŸÔz¬úÌšŒZ#»;ÊÁ
®²%O½mi¨µc(ÚÙÆ8pÌğ€F:ÀR›jü»3bôoò~‰1¶©M‘òbRLJH%q/œôÂÈÌË’ÙHK6Wa¢§çOã;‚=ËQï¡H;ÃîwĞ6j>ìçÈÇ¾Bmy³¼vøÉ	U¹¼õNv}íÇ«p0%2\]åB|n¿×a-{˜Ÿ:É¡ÚéB/^¥ÀÄI‚èYÀÑ–•Hœé„Nü<¯T~å·Æ@Õ±Ôg¸àŒmz‚}ò*Ærnèm51¢€È‰ñ›ÿÕïìµ;‰”ÑÖüÍV¿ÜzìŠúø5ß­‘y=ÓÈuŒ'u"3;Ñ´OÛÎ–Ğ»¿)Á,s/Gåï6ÖØR8bOz9Úvld;3ÒwÆ9¥çÉ·)5%ëšU[¥¶´ìùÁê*]®®`
ÁC£àf}	ó_w W€—®Zû4l•úRĞò†	ZQT”aÇV´Œé'j,Ü&y%Õ!İäR}”Ø<HÜOÎG”*ÁV9‹éyt‚ßœ=5cD¨V{üR	ÿ\È³(Ô\\FÉÈq}Ôç—Š³8¹#¯âctN[İ=ÆN–å?Ätu ¾SşOYˆH5#áæà\R¢Í”-ÜëîF¸©¾b—ë°ì’øª–œöWXĞ;<ş©ÎÚzíÓjä@â— áº™(`°×ÿ²¡2ì€ÒÊn¦^B†óŠıF¿kqè9ìŠ§Í5àZ.j´E¯]Â3­…ãvÆŞHœŒ÷9V€?ı…,Ç}‰  ¯ñt¢“aÉ,Ûà(‰Uê"!©Bo!!WMö·cªN7<àÛğªPA+í$]`³›éƒ³`°{R&ñ¾»Ğğ8„ƒ´“GphL?xín›şø`í»²y®&:Æ-QÃÈÿåºà‘P'<6“s$dÜ•Œx·`¢H†®Ã'º«sKr¦š´†^¿Í/¬Í²ˆ¡·˜şTäÃk‘1¥Y­4¤f|åÅÌOå~¬¤­ô¥ÿµö¹ ¸ Ç%Kœ¿sÒ®Øf²&ĞhwÊ¶Ì
^ÿ-ãµ/2y‘İ^Tø·³ô»N 1ï\ [ä»s¹-KtşN*önÎjúm¶¦WËšîµÒ¤?hÃsj²$HÚ†÷Ïİ—"èÙqLŸ'u0¾‡†RáÁõëÏ0÷âU‘SØûY¼§îØpK°àCÄÃ¡Ø²ÊÎÃW(ÔÜ
¦~ƒ#®Â_Õ_OBCµªá9”x8!“gÑäØ1¢_h5t\ÉÀZ7|g(šùô¬ò‡ÈÕmnéİí4*V¨éäl=ReIÆCËi	 IŞ<¡u¤ŞËÇCQÆ~Ù×KpuQ=S®Şz™äcv÷aÁ(wÅf›'('lŞfvzÕ®j{Û1	ìÔ

¡³qJ~\FÚ·½£Áã+7­ÜË[3ÛŸ¶sˆ¦|ÒÖé4ä’09ìƒİÄ[;È0pÄÏ «ÚJÀy4¸¼]—^	ŠføóêÌ3ó¹—:¬³Ÿîû¶4±“¢EÛÍ±œ†öÆ•µFÁ<·,x6Ò§1×²u‘’Ï¶ö(
O@1lE:Y\ş…¥Ù‘êT¥P§r^Fê€¾HRÆÇ/Ş3òn¥$†‘­•ÇÑòZR³Xcˆy;ÚıcˆÇ˜8­O¬¹)*ßi?é‰‡h ø\;Ó¹
÷bhÛ>
võfPúvìæ~xuy‹UÁ ‹*a8ƒW'ª4.¯¸ù@Ôü¾l„“nÙãFqÔ¿áâO‡‚­˜¯@Ä™zéêïdxifq`É¯ŸsK½M’µOiòv*zÙ¨ÇT9[Ÿ¶·ÀPÖ+‚âªæÖæ†aMr˜t„OŸ­E]—øã>¥šƒ‚O6Ùšw9UĞÄkğÊ+Ìå]= GÈn÷´Ü€®ì¬¹MXÈ$
¨Ip¯p/éªâç¾ª¯—N†ù—*aÍP2Å×aR?T_°Û—’<Çóô[6•Ñv?'®ÈCºÄuédß~	¸Cî¶W+ÎÜöHUZmÈX0¦Ä%×Ï+¸PzpG¾~€ßŸ¾vè OW¥Gvˆ2úOÁÑE¾Ã°ô<£U¡qÍ¢SJ9„‹o=R9Ê®˜ì¤ÕÕİ£÷Ä™WæÀ/Ûg[ƒĞmh¯óıÿDw£ä}?Òo“t„•ö×¨ğÌïÏÈ<cŒ_«Bh4"àçƒêæ”¢^àX_$ >± â˜ûÇìQşb	coEäïxİñRƒ#Á{ßhu¾çjf~A{Ù-C»›[HCWÆÎ”a+ûìí!TSİèB¶* à>—?	p6+ÊSÌÙqçPEãR á"¾ŞÍˆ <Ìäå,¤ü.tÄkÉ1e4ºı‘¤ÂšåN­–dc|¿¶ĞYœ˜¡àŒaR*™§Ú+µ+ÎMÁcÊ`Mõ“Š¤€Çhİ•ÌZ¹Hf¹Îì‰LvÜ‘åÂ‘àÎ÷Ò%·*0Ñfr
MJLµXæÎ6S¬RÏcÅ¤:‚MÇT+±£}cì¡$†[§Ò-Ôy‘Üó¯3ö”IàZÛ³zñÕE§Ák8c¤ ò\;/5›‡%©İ´IØ_~öUá4ìvoú¯"®ûş;–!t’Öä>EíJMqŠ§Âş¾±éÁ²Ã1‰¢A2¥9iØìJëßåº°vPĞ3¾¹ÊkQ(aÜga½t0¡MØ>N-¶æäœOÒåG‰Hó;“˜ì¨zë-ÔFÅ_n'¹0ÈıeÀ[g°÷áõ×ÈÜü@! §x¢B$‘:´åû'ê8CÓ9~j”é|MB}RÏ‹À1#ÌO\âz›1ç:Æ;‚ÁGÈAú—Ì7ø¤eXXrg¥Ü°œ@yí÷w—Om ÛõaıÈ€$åÜHÓš½jñÎ7jÁÈ¹ò(}gxñn'V!îaJeä°èeÚÁ=_¨ÿ$Õ÷\Œ‹•RA1xÃ4A]^@Ù3İ…
ëHÍ—ó$h¢WÖE 5-¥‘fÃÏ@œÛÊ¾¢£ú£!¶‡A»ì¤y¡D™ g5Që	I÷^IìànŠ 
¼fiŞ–Ãdcé8*ş#×ÓÍJÂ¿ÑqgÖåÈ–ÅÎk¿‰’ßcÉkËøé¿Ñğ¥åê¾„òÅÊğì4¾GÍ–¶ZŠÌ¶ïájÍ©Â-¡]Êç´ÆZ-a gÈtëìR6ÍEcU@y‡}ÏPêßÇZ ùBNìr¥Oàú~°* â"/³ÏÏæªR?kiå·å`™úï/Ğñ6ú>LŠÉK4L“K5! ©Y>ö/Š+‡j«;Z³¡Î[ä÷ùhæYÈáá=È‘ÚÅ‰ôÏJª7\yİ–\Å¹Õ^®Ú¹üh˜B¨vg;8ısvSCÁ£Şª”LZ¨®ÔºË/„›Hù
 ~ãm…‘Zşî†V¢p-*q©Nÿ5`z4e6nxk&ÙÅdœïƒƒ¸hì¯‹G Â’Ï¿dÙ€wDúâYA($Ã”= 3 ØìŒY˜'uNXj¬B2¨ĞÅ)4{E8éË±¶ë~ƒ»“†V([À•H…º[‰-v]†÷èyf¼FH/ĞÿÜCf÷)ıhBğ§¶ÏÌV[i2[LíîoX•Ã>3’Æù§yãòæ/ÌËÕ!Š
u¨÷ùV·GÑ«öÆµ¤Ÿë{g•iÙo!îÅ„Ìpªàß—HĞ\|‡r©U™›û³¦ÕÔîºï±lC| Ó½‡MËö ¬n;Îhcß†¤äğ•8`DÉø”Vš¦{zL±¥°3¤˜öX’õxZçFçñ2FvN¸²LF7ôvˆ¹óñ~'‘µIÁF²‹vN¾ó—§0¹V_R¸F6‘‘gÆd?FL©¶¥›t,×¹ù"D‘›•ÚŠkHüön…ÕÕÀB¢|"Se™¸Ç¡erZ¾aâAÇÉõ¬¨€?ŞÍ+Ïg»£l›×-áÍéÖ–1E|ÉSH†ŞæĞX¼ „k
ã‘¿Ö.•„nBÔUKb‘kßSXØÔŒ¦:åê5*7{üÊP&7`uÜs’£Dv#XÏÔpÅ¿  ci)3ÎD%®lc³‹S~kØK“kğ¢~€ä¼*Ş* •œåùXpBM48ØŸ‡ùP¬
ÔĞ¯ª°wxÉ5Rø #¦7²ø£Ri_¢«\k@æĞ¬g¦Özwil£Ym:
ğ5KY½m©,J,tè¨³K–Äğ»¦ÊŞÜ¢Š—T#‰AÓvhf ñ™×èƒ£âô˜«.õ›¿W„Üg‹—rŠàLGÓ\¾É®ü‘ "CúĞÑ¬M8BÄ@÷ÜPàÕ¬º:°m¬½òg•j0ä\¡şİA8ånË¦Ïö¬¹®İr?­ —Ç-EË]åh¦6Y­`¦ {ÌÔ~‹Ó57‰ÉQm²ÖT4QÊ¨…/öJ"MÉ}©lˆ¿Ö>øE²Mv_¤§1QK\/À×uŞ@;Í÷B®÷è\İçud‹d\EŠŞù'éØqp’M7'U÷¡P·•>Rp¦+cPX¥ú‹8›.ëÏõü ×8**Û—G¶æX è#6ùİÜ.İqÎDây?’)…LçgR·ş¹	ÇÊ/	WnÇs-ñ±c‘µìøsõÖŒİ‡ÃQ(¼ Š¾rïÑôF^7’›H"¼E!«'æjïá¶‹âÎ(YuÔßÀa¨Xc—6²5;óÑ ‰†ûë q`ç>ê±€˜è¥[ÿø¢äô¼¶wBx…Ş7æe-Äú›’	­êò
óÿmCq¾–î”{Îµi%Õ5¸0êˆ–,ÔŞTÏñ[¨a7úÅ8F+å˜åÛà=Á~âs$p`Ü4Ô°râÛš‰ÜÇà-%Ê@ÜÛV•B[uò²½iÜ•Oõ»0¾°ıc&eO4]º#g¬:Ş‡…Qï—Q¶s§ù4+²PQMNş®ÍgËŒÎø·Ş‘I1ô*š*øW)\=#Ô°ge©Ş_Ê¾ŸÖÍÄàÒsËö1ÌwûZ¼![Ö'2P(®ë“qXÛ(°+V–ò›Å]ß=‡nõ­:œZueè5-Î« üã¢kÉW-m3qmŒú IlMlè­‹+]Íöû¨zøp«áyşĞó–MÎÙyN³/o” 8Ç”Å,zñR=Œ&9– EÜcpóPŠ€ÈPmÊé@1H²i´òÃÅ>XOK"´¿$˜>+Ù]6§éHû>ñÂş±…ù€md‚R:m_?g)^\‹¬Ü?¢gÛDÃz½9ƒÀëODåî$ç+‰ÈÓÕd›Ò?jL8Sò¿Nt§u~G…ß¦ï¨¹ËJşjIß™µªÇœ‘ÁµŠ’ÀU7£Í'_İp¾*õ\.è]Âré‹CüÈ/å	nz~Ši‚4Ù}DÌÑŸÊU¯Ó¬¶…6Òú¢ğÊ¸è¥´=FZòÏX¦|s*?z›¸Ë­î¢šÏù†—ë‚aÆyÏš§Î|ëÙ z›A+²Ò›%ÓBtGØ4 …éÂP5üR?®Ë‹£?Çu–±\]»nŒ8"ÕJöÌÀdÔTØ”yÁÉ1ÁzdIÍvXí¬6a¢!¦$V0	6_Ï¤¢pÏ%äâïmfi«QY$%™W§(ÓÅØ‘‘=\	à¤Á-ä¦¸Í¼,ncê@…[v¾<](åé˜ƒ˜ákPÉÇQ¶¡ßsáó}3s‹×)/	·ÿ%N ÒÃÂ¸tld5Ê÷.`Ìİ_ÁÂó•OÑ”7ˆäSƒß~ÎÈÇ÷SÀ4‚‘ü ¹ÍÌ:Ä0>g¿Šù’¢íäŞÏhñ•h¼Wú`ñ0«4Ã;ò‹Læ5­)q„X‡(®	õÿ|'V>Ò6Îö}Ë9QËIDYğ;(™#È÷kûFó ¬M"İí­ü,0b‚z ÏIa¦öû«ÿ’-å İv‚	åÑ§˜¶fˆk0”HQfÙ£¹‹‘°³óúñ¦ÈR†Å	o¶Àøˆ–/ş=¢îçŞa=‰¨ÿâ2àğmj,dJjt©Mòã*"J~nl)ıŞ¶7Aş5R0§‘49İ2öÌÕæÍCø(]OéYÎo¥X{¥Y+ãıF7x¨nú…›ÒAŠô²J¹4HÃÄ)ñ‹•—E~SñÎ›{SD]Šd"ùº }<p«zMVá(}§£ ÍüLh|õ9ÑVF†R÷4õœÙKW°ÇŞC\±d~vén¶ıAPLN¸Fş´,:\‡'ÖõqºäJ²@÷nÀç†¡_HÙnÕ¨—S/"U>W|¬tAø.9ˆXPBG¼‡f12{~4“]{<zªÔáOŒÒg¸ıÆt[¥Iv¶²]Bd[hËaõ½¼7ÜÖ·VCÿà—V~8£«‡@<¬Ì'Çª§í­0Äuså*ì^ÔŠÍ0›_Ó}ôƒT—
µTÓ_ğ)Îw­<O–Èf(¦`²8ÍC	zn‚Ï0¡q7±EâÔ¥¬Ø:àEèéÜ#ïõ
&o ˜8E7¤úÂãÓü§;é’ÿ[ãfş.Ø°wà2fñRg?ìªıæÿæ¯ë>ÇY5æƒ÷g­	–'7ÌqÅ»É>wçìgŞŞû«ÿâE{_ˆ£yC$P‘¢î,í9?[ÌÓºÑ.‚%rÎ3vCÏ¹„Œˆ 5fÌ
ëgçˆcif—0˜K1´í/ì¸2›ÃĞşÄ¡|NŠ@dÃ%@sóxæ¢¥G!+Çz¢‚¬F¬3+êÂ‚û7 Üæğ¤°×‰ÍÏ{Pş©°ıÎrPnÎ¼“.;@Íh×ìeåÒéX<+T¹Ï:zéÁXk„5ğÕ»N€^¾^
[aëëéß™j J¤˜`½R3ÍÃA‰w¡zä«†é^Á_<˜É)‹ÒŒ|ø}‘.oÑ³—±¶‘Fc¯X?Ãà‰#ºw)û,=³¯ã*1$§w¥Ì>åïîT‘¦Z[E®ê·_[;”ı	ùbĞLØbPbøñVúĞşú²üeîÎ„X@èˆ%u>[9ñn¹ÚV
p_\÷+]•xÏr–Q!ñ²ø¶çîòBBŠNÒÓéı8ÜFÄšXJÚ¦ôjò3ì>z/ÔZ«Ud—€Œ{HÍ_R*gPÏMPı‹ÂH ËêÖ¡>S_@bj‰%]Òl[ï|ˆoÌ¥Ë£_Q¹ßó‚´–Õ<Ki¹ÆÎO‚uxTyˆJi±»^0lYZ´ÊMñÊWĞ÷@o 02ƒäÚ4FË{­w©Ë®x"táÏyûˆŞ™£…ÅHzaAéıŠ.m®ƒÉ'!vEsØõÜªƒ3ê¤u„şÄè<øé(Ì6I5QÉd¸Êªë´T!PV¥Ä0>»ˆãıˆæŸWÍ\’('*^ĞcŸH~èÑÕR”LµÅßh;z—3j†ìšvè@=Ù°DäÄó{!÷IñíÅZ1¬şH7IQµ´¡N.W©m`‹ØÁg§,/«Ä<´ú¤K fQÂæWÖZ]‡ıÕ'ÇRÙƒMª©øşù%H£¾ÑÍízyÓFÕPö#ÇÌ[©>«Â²Ã¬G£¾ã/°#zB=SÍKF;@°—¹…>v6‡.,7å½ÜíÈåùÏÕxÁM¹ •y¬ğÈI1÷ê@éåzI `dHhÖšO”Ãqi8¸¦f®IIÊ˜/ÆõVÕß#0$Q'r(È:¹V¯X.bÃèŞAn(Êu¦RÒ%/%Şr<p…†%ïbd·gböOsÃ` ¯ŸîÂ¹+ŠuDş†mB¡h³„âĞ<1ÙS€ñÁ?jÚ(šºğÅ.:)yVYNO-Œ»¢öçYs~¿ºB39~9½b Şo58ÇQ(…ãû<ê6(Z ¤B*¼!ˆúÁ	ZåÉ,5nr›ü  ÿ?Ö}à…VA<V‹V*ô9Kå/ÙÍ±.7À9  Ì…aY&càRê)S8nµÚ[É ‹ÉòL"ıµoc]¶å]Íû9 9‰ç|úPs?Å‹8ĞCj3À—E«]”¬Ú]*ò;F×‹¡Fs,V¤®o¦Ô]bş¨a¢gaşXQÑ[h<ú4¶~m&r®•°Cõ3m¸ñ¼pífÓ¶A1g‹â\
—ğ4ÿÕ5ò¸›ÆGã3#L£ÍoŒü·ÿ*™æ^ı´ê.õùnÒQµª_:Ú˜E İŸ%a”_í7Z8•ççÙ+Gšºıu©ÀvW‘#¬q™„ÿB¼ÔÇŒüF‘§Ö%?½6$ŠÜÍ¡Lk\ØòÃÍüí| BrõhD$·QLg‰™fP?¯ißÈ±Ô?÷}?²Uƒ¢	ÜËÃ}`‚›şz¦¾*¢”[¹´ìÛuÖklr œköD*%+ˆÉã2rXõë.G–‡YÓİßiP·¡TyB™mİê{œÆ§Ò—0ví7vøW—lB€+ÂœzÀ7Ó÷ƒ‰IÁKa—ÎôÅ+İxiœˆÊv˜ùÖçMùÌ*úİ§Ü%«›v¶øÍ5şÙ³LZF8©a,1¾Gë!EGK„yŠB®0P˜ÜYâ…„áUy—pw—±
„ 	àxñh¶É%OİvEÖß=™7¨…ğ2’q	RµúÙdÖE¿Å ÙÒ1(˜‚äu%6ëJe*Òî_¬Æ[w$e¬|H®¨®•¹Ôz¬?-'úhâ^ôÆõ¹“ãï·šØÍM®µ¥‰¥¹ Èâı‰€!ÖwÁláƒĞÏA·¿Šu.ôK¶$¼U(f‡ê´k+zALusşGï6ÒÌˆ!á‡ó•şZÕ3?zªóCHŠÁ`M‡$~ŒvœÖù[¾ç\‘ÎÂcepÏıÚU]ñú$¢Í	èŸƒ¡sJƒ¨gŸMr×¡âËuŸÙ®÷MØ“5kÏ¤ùnİæ™	Ö)â† ÀÆ"£Ë“Îiä˜Ø¥ë+×¦±º	Ï¾¤ÄÖ>4¢b·ò£±8zV\ËöGìØáª®Ú´­ò@Ú*®ùÂ«èœà¹dŠp¬
¨Iı${…h¾
H‚c«ú.­ è]ØÒğà°]Ñ5)1}xÓŞvæxíó€XKIY˜^ÔfËD÷NôQO;	€Ù òE—KÿÀ=UĞŠÙI?8²¨§ı°$G,. J)¹îÊı¸úğ6âKRcH 4Ç‚ÙI°Xõ}-Y†1ã¶6öÍnI_›¼-”A–_¼ã–Ö \iŸ‹˜“Úú>Ò¤ÍFbB}g`üşƒDÕ Á ”ƒgş2&¡ùwr-AaûĞêSÚyUdûïœRòèšuı‚Õ*ÁÕih8~MUÆŒ;™Ôİİ:cÙ¾¡â¨¶m´é-ã{Æàc/êU·ZËİ“”Ùj“ÉUİ42#Îáå<¿[ˆC¾¹_ÃzÏ@êåÓéfOğ>Öş [©6Ùêsİå³á´;éÀ>'ÆÿÔªs@5ÈºÓ7›f†HjºS¬	qFÉï$“4;‘k$ä¡}€‚äZË’q#Z:Ïÿúµ4 ½_ãÛ—/¨¥½fò“±Ç%¹Æ¤6z\”sI94Ìp,á&›¡Ô#?©qWNçßá<õ<ş\d»Şœ>¹ƒ!Ü×'t:Ø0D§ ™Z¶¸ã±¦kÛ£àÑôÅƒ‹Nz§`,TÚÈïñ=iHDš[yi@fæUKjêÛ¡(Ş˜Bİ,[õyü‡ Ëå3œiÉ.o¦øjƒRCİ<9¥†E6YÍwñ¾y)w:ÙÄuö+H+êÚÉUp„´Ëİ¡»–Ç%<Ô	GkH'‹•b3‹ÿ<³
—!?4_·Xùõ÷¶ú;ÃùşE÷ÊxöÓTÈIw<NC±RG‰a4 •[d*W‚õ³­ı—3Ù¡i•-d3ó¤ö#ï¡WTß«c;<.‡ø„¶ë‡­€îOó¤´ôFîjWİIMÔPmáÿŒÛoş‚Lë8{æœT‰éêğå8™’T-07Ç†"´Xæfnx±7¾çÍj•!BD·näÀ
ÏÍwáÿÏ6§¬G—õâ½§éšğ±¥	ÿñ]5Ûñ»É½ì-ıŒÓ‰œ:yIUkÇÂAo6ËaÕ` ¹ˆöëß-Ö%ß.¶Ó¥
Ú¼ÛaöiNÒæ¼PpÏ]<£‹åÇÂ¶'åtlõ[àF¿ÜâB™ĞÓ‚|ŞÏÌ´ß°h·J‚‹îaŸíÁ×$Şİ†•EämYæ»
Ø€†Ø¢rHwiÂäËDhÇ£¡]kWµS°¢W‘oBŸ*DòèiÄŠ­ uóe?Ö"E›´k 
T,—KL9µÂ&ÃbeûüV³´•âA;‰z
6§1ãQ[ôÏeÊæxO†8¢ùF3ÃßÂX±u&¾ï‰@ò•är94™ÓfnG9˜Ú¿91Ä3Íeê–Xnº©Ãÿ~¥yE
á-;ğĞ—ş!š™ü(ÛıÂâŠš–º>+{]Aƒ^YxØˆ‡sÑVİÛÚ_4‹× .DËÉx•×çƒÅÂ'Ñ!1m´1à% 6Æ4ú},YÃlÄµ}KyÉFş;‘yÉ6çÀVQ†_(xîöôlÓæÑ‹ÁrÕ`ÛHáÃ<ŞAeÜmã"'µ—1œ ‡M¾û°¯ã5:OÉ`U+ÿËÇ²¦ä#76¶«¸È›Ş/
ıy'JÆäú,İ4Üöù‰X<=eã8={üô-N
ğ¼–ò#ìPéæ˜şAÄ],ÚK’MDÛTl³Fln5»(×¾N°4Å¶º7ˆ’{Üø1ÅS~Säu¨Õó¹ hÔyÌÏ5WİêÔ¿“*´Ñ!EÒÁßB—r
÷=ş„(ønr`„§´{¾HôÔ‰—X>Ü.Ez€¿:©¡‹*İ¯î¯¾|ÇŸ81Aµ¾ÛUˆd´ââcø†°€ÌêvIHb*Zßİ«P4µõéí]´gšAòh‹n*n`ÔÁ4™§?çW¨Õ?o )ñùŸ3¢Má{5û6æ{»¨şµÀs$§\ÒŸâiz‘±Îcp.=ã ‹rÖf”Ä*v¨£¹6+Q,M…=ÑArF1(q×Ñ#sµè%¦™Q˜•p[h<å¡’ëøx°ªÅO×&wF:ùêœÎ‹ˆ–ğy#äuô‰]ìØŒ`¤Ó§&´ŸEŞèæÙ*döòÏÁ¨{ó÷×hıÌéÉØrÇU¹àõ9êØÉÃ,UïKâÛ¾un^Ïb)”Qrğ™úû?=éã	cg¼x}'tb}ÑŠnëq†d´gøºè%îæ }8E––æ¦à:2ã°Ò0«r¢¬y]»&ëªÙ²ªÙÑ]WIVÙtÈ%QÃßĞqlÜš˜_*Çˆ1*ŒÛÇ‡ïe‡`Aˆ¹éŸF7V÷Œù–ÏÃlÊ…j(” ‰R÷(„(¢ğzó`ªf*şÀÛDïDÊ™ömÙj¿Ó–r4Õ>Ò¢cÓ{ã‹=R­¼X†E‡º(¡ÉÜõ Ÿ9í¾cµ‰å³ÚÂÕû±Ô·/ş¾Vd;Pôl£ğ$äcõ¨şŠB{`ßxPó;„á‰·Ö~îÔ8ÉUdxX‚â=vu“÷aLñë°ü’³hWì4'p
¬¡Ù.Y…N®~`×ô7F/r¢Ôı‚ßí^zQ?Ì)yí<ãâ»Õ|1áLÆ%»ïÒı^Ğˆ:ÊÕ€V'UÇQFŒÏ“"¡F®d{• Cn`¨UNF•†ªK±o<¢†JË¡/aÒãÑaÀ) &=ZçÙxÒA.û<§<´Å_K$²
[º'{¼„ªı2Á¶qÿ Ë1…*ˆÆã·½8¶6¢†Ñv÷Y²)DUó<G <H_CÉ•¯ \.Àj€†ég eEÿóìX²dêP5l×´q:®M”o-ZÏ”GPaş¤[–Ó¶ I³1°”2šš“%kÛ‘ö÷#šÍ¥<»øHÀWÛ¿ˆA”äpW•8¬I4s±fÍ¹íó¯Ğ‰Ísl[ô)I.KÖX§0Ä4ˆ“ò@L©oùg4ywk¸ç¬Pw<[-3›â7V±D–C/ßŸ/¶î?å·²¥ÖØ¤ÕàÑŸCË¥0VÀ}K¿0Y±¸_²Î0÷1Ë¬ôéKƒ;Ö¨±™~9"‡3)$ˆ–4¯J…—0VÄ:Q—¶õ¾ƒ¯¸Ïîú¿ ì`ê¤xd³Ff¬¹ï®ØdHşİ›—b³i=ó&&ªj*¤rê	ËXº%ï* µBe³—ÿ,'G ë"²Ş\£ë?àr[7)™ÉYŒØlmğ†ûş]vÇt–¶‹$™`MQ·våó¼² óÌMI65ræEÆ¥½>|°¬È¢ÆTc·ÔC—q}°'ª”Ëñ+ñª/ê,ÔÏÉéO•ùÉ¥ƒr”¬¼~Ccå
kşBw$ LÊˆb'ÁH6"Êò `1“_í¨€¼K(b=ı=‘ñÚKJÏŒË•ŸŞ× C»å1°¾áF@lİXLÊÃÁş| ğ&Wvö:„‘µÛáÒ\ilŠ		RRº|šLQ2)Z¬\½J¸uTÔUÑ\üñ•Å‰˜QØà±˜ÃÅ Á‘¥˜±éŒév0ÊG8ÿLä‡Ùnàw
xİ±8¶Ô<S-ê‡&OuYê<¶KMñüÆCé¨íğOÎıÂ¹IÑ"8Ğ2´V~íìKÅ_PD+¬¹Ğ±«{›~j[¦[üŞ–·ïQceù7£1w¸|Effwşã;¦Sy~ıÊ9¢Ü(
Û÷L*"IBLøŒK?€z´ğËƒ*·Ûl—ä'‰0j…È« ©ıD8d`Üy4R~‰İXÎ•¯)ÅPNîIšuµ©~™'#X·oùâièxI9RŒüD®`¦b |Ñˆ”Şô¥EÌ¤¥äNY»'yó®§:$^¶Ó
ù·ÕTÜd=(?°"÷ç`£Æé”eQ
¡•2§r@T­FĞVŠufÜw’OŞ™piLfåÀÓQRgË¬¡/†/òCñ/•jl6ñgèPÈi¾,Š˜ø¥PÿZÓ;<wŞÆHû¿i“púÃ/èNiÑOÔ™:²Ÿjò“ïFÙ‘ÔL6Iç¹'û¯Ñ%ª¡œ)|T1 İX\Şâo¤¸ÖšN£gÂ.ö²üM¯Lz[ó|”qi‡mi*3=pPñ‰{lx&´§‚”’([—%¤6}\¤‰å"¸Ó‡d¢r[U¿
a$KDä•P;-¥eT9Ş1¬Àƒ –•¦~‹L9^t–4¾ FäÒ‹â§®B!ÏSÏÕq…İ1Qéj5l¹F­æ#Ç+ädÙÄ9PE°?ö´b/öa¥7ÒØué5?ÊÄOağ©O¼ñ³ÓÎ)[tv#^|+¡\ãxÎ˜§gÄTŸxäíAÕO<kh ´Œ=F+‰ºç?f±Üü¥[¡"Ş€`”ÇåOĞ½°õ¤<#£™ì)n:_‚¾ò7Ğ<ÍCo
Bœ††ëF³çİ˜ÁÕÔ‘g.éãÒÅ‘0y!ü4ßæÀYÍYÒTşÎÃ§$;i,’Ó"Y=d²0“æ¢„öğŸ:Ş™»— í8&%Dš!¤^İöéØÙupC"Gluj-f”—½¸Y-[pÅUëÜñCŞèy&BDrÔ&c
3Óh'31âÀpêE+wQÒ?oE.`1c[lãÎa«“6î6¯&íÓzRİyÌrNÎ_”ts—°¡»4@ù	ÄÕ3¢}4yÔW#rB;è`UÒ à%GÂÖ†Gvá¶y@ÿ‹&ìBì]ÖÉ8DtÍH¬ˆPÈLÁŞ:¶ÿÌ&ö~ÿûIãñì]–—ÜUEbÊ?$«_ûı~vW>ğ7	TlÌİ®…b…ƒyãÔq~fºÍxU¥RXDB‡y,şÓKá‚D:-¬Ø"Lı…=am`¯n §aL‚=¹4[4t4Œø[Õx‰Ñ>Nde¡’`±¿é3åaÄĞ¹}†$ôD£9<ëH	Z° ¥%­>-&Kg*Óqn[5æXšE½"åORGX¬JA¯ß–[]> üMR‹qKÇ±°'4{RO©›˜æOUTÍmWÎ ‰ … §–ƒ§¾şşu	IE*İäaVPM A¢VÓ¸pÊCÀYü&$˜¢®BØ é¦œõtƒ—öŒ)ñzEF5,é¾üv*OnÿR£:ğêM£pÎ±¸ŠšĞ÷l5®;Az¨ş¥i³VgôCàÀâ=-¼¦£ÒVí§ úd7üRın¡‰Q¹ŒğÆ<ÅJI¶)”Ìde ˜ÿ˜ŠäíÈnK(ÖÉG(Es¸½İ¾#ªhe†¦ç4eN_­2<|X± ‡4WÈ«¿ÖÉ\z2°ø‰…ıªÿÂÆa*”´^cÒqO=GF¬“Ş“³£0ğ;ÁÅSt«®ÇZ¾qaVóùã¸l |PD(@Á[ü+KÍ?°ÚBDy†¬§Ø€6Ná´xza\¸¸`àGN_	ò3ö9Æ,ÊÎ¸aÓ‚·¥Úiß”½2cf€‰ªğL3”	7–{i‹ÛH(¨…tt¹›±(†@ˆ\¡õ}4ƒÈdV×àvì£k‹qä¢pÏşS‚Ş=V£Æ_‘%–¢•~ñ¬ÚŞ}êYz´›€	s¼@à‚²B“ıyı}ÏÙÅ\Ö³¸V€‚/õ,[cÚ0Ÿ°œ¶¨~-¯‰¢udM@{‰¦¥®gü¸óñğğé™0ú‹€-;U5ñ›E#ı§@=§ÀqRw¤0ÔÈ—öÍlî>nÕ9ÃÔnÁhÅ–.Áh0Ù¬-Ù”§ŒD“Ğ‹Yøî’«ÍP%¬`›ù²læöÆœ’—6>™?J®n÷km¯ê‘,ı	y)’i¾e…¹>saT»\¿y‡Ú@¬Y5¨‘˜mî~,)Q ßŠ±Ø€#@2rKÙËÃÿ`”n-äÛU)‚:½7U"àÿyïâìv«ú#¹ˆÉ["÷ëYN÷V™H?€h³ÜhciÃ¥4!d:ı›“,¹÷9"6RY²¹L”F³½_2!ƒSW87È±l»8”¨`LZá>3l:dä ïj\x>¶¤<ÆÄ‚f°qŒB"÷Bz–ûÌ
0O¯“ÂÊpmñr³G…êFÿK¤Š¥ÒGÏ:Üş0›ş‡ª1éÓ{ª%Î5J­ì’=F2ĞYF€Ú¦O¯jÜ ø©Qx7÷528³/W—áÃ·k˜‰9z¡Ùp®Õ°dÇDƒÎŸD²ÒÚ×ÁmY¹)ÌJ°_Ñé´¡ãôÜ¦$Ôvß¼ôEõ—ÓÅ zıu|è­Û8áàÊ3ä4©Fóó®M7±MB?`zçZ_LÈî§í#£h$ßE˜¼5”fe$ûÑCÃ¨¸HŠëûŞ>sœw	³¡ÈeØ›¸¸‡dçƒy²ñƒ¿Ú&H§ø‘>@›FBG¯àSVëKùúÍÑUßû›ó¨•²à€!Ÿbñ™›hLC”]„SyİPñsmÍOd>ë{¾r4?„ÏpT½Ÿ³OÛ<¯³•Äµ©kºUÜ`÷¿Z
Ù5çbÂ£ZÛXàøú­ÌB35,KÇ 3íøH/Ñí•,‘e´Øú²lûXÊ˜WŒ"‰jíÖ¢SE-?­ÏfÿA0£5y¯ÙÔ‹=Ö2¶m¹41g…ºbÑFôÁé´zãúé/ÚÇ–Ì˜,@Š¯óÑ5;”Y´1Ê™~fçRW‚³ç’Òçü‰>Ø“.Ê-*-ÖI‡ñI§ªÃ–k´ã@áÎ0x
Ş‰*¬F¹ädTİx"Ğr QtÙ¬$u ëJêË—ød`€³§ë« &6m$Çş6üBÆ}|/èCrZ9ˆX|ç²bíY¨Æ<":Û‹²ağïU¦ˆÓ¸|šOÌ·§²Í½fµ©NÒ.ü±¬w¿÷d<<ÊßgJ¾7%¡xr™UÂ9ûÆÒ…ÿš_oÌãhOî,İK³ƒ×ÿ°ëXÍFM]DïJ,Ö¼ËN‘¢Cö?†ƒ‚xša]oÕıdp0÷jrTg	´Ğ ¹füòÙĞùs L;Óé‚Ä·ÃKæçI€]I‘ÃLUÑÍöP –µà?êm®ía¹$lhĞ(êhS§¼‚öªE·Œ*Gı}m6nƒ2;#—-öÇ4¡]®;äÃ °ƒ uK”½§KFnUé	€ı¿§=¸é‹ˆàÂX^ÜÁ¶#?“ÊÂJ(<{APã	kÇ|ÁH`ù¢FBïFr+¥¿bí0Uµ¢œé%ÂG9ğ™nåK!¬)Ğ%$*Sßè`J+y%z‚›êÛ–°Ib4W'‡9í‚YWPyí²àUbŸr6¦íéZ4”îEÆP·ïá0C÷é0»s«‡+øüÄ-ü…5j”ò½ÚD8­ÈÆŒ‰ü_`\6óÁÊ#Ø^IêÀŠ­[CÄO6£%ñÁp¾mº¸aéäşõL‚Û=â×—ıö•**êâåTÛ®æ¤0ßm=>ãB>ä>Q‹ˆ–™ÎÒQ"÷¼¬Ï­\­®Ä-Áñ4w>Ö‚íÖô‚>ÈæÁôøïÅ|Öàø†_ODğĞmÛQï(:òÀe[›Xj“–EbN&ú×¤0‰FÀ‰+bØŠ“p±±¢{o^År¹Şıy)ÛÃ¤uŠí»Í` Ş‹¡ãït^ÑÕ2©×gé\”8¿æÓ­”|^Ï\Å‡ŒÕä‹€9ô@/OyKüè.¶wšt3eQÖ"ü]×€p˜.äJ¡¤CÑUİT«DÇ>+VsŸíO"˜štÉ¤Oâù:×ÑÁC;H£˜‹Á§Zæ©è¨¬Óı5Xdï·©H†ŠŞÎ%7©B¼§ãXÌÛ(:O;~¸iæ2gÚºĞÉIûçS†2™©§üZåOv®‚wsâ·Ù²ğ!B£^g*sˆ²aâ•¹œ¿:~2C3ğ¥Tp9ÇÑû;‘Ÿ™¥¥
¶º5›*dy•Éõá»NfWP‰aò€
BD¾‡hå¨ô%ÒW½¹‘òáph¹/voCûÁ2!ƒı>iøä€Á¶"4‚C¥˜ö¬GËG|Ö„Ò7«K›Õ×=í#èí`H›-sœ‰G_ô’\KÎ#Ôü¦ŞĞëÎ	ÔÓ˜l£‹sÁ(l‹Çxºr-+áyõİÒfP"9yú
7|w|Í~„ê'Ú=ù ÑG|%÷6çÿÇCÙ>¶‡=Ü‡e¯éœpë]ãÕ•®šÏûi l30ãoÔ}vãQ	÷b'?âu]G 8»—i'‘'µ÷BVOCIg˜gÜÎ÷1ØÈæemà‡ì¡ o5MÊîoªÉm8’˜§ÿÀ¹¥É‹1ªBéèJ¿ÏlÔ¹»LTtZ	œ\$-ç’Î×()¹(’ÒdŸÒ#]…á²î®B;' \€s~ºï8¿|Ğ€´Ïx­ì8¦D\³s;›ù}Ë·îBrgšår|ê[¸~“œ–W°`T9ğ¥CAXs£VüP6õ"YßÇ_¿V­}oÙˆÌí–Ô,|Jú«AàÏ€ó6ï¶Ÿ%ZãØ„YâWåéYĞoØ1ŞB×õV¿ßÌr)!àY@b:Lé}pG',LgDÇJûç—\»,„ãBàã'û_ÚtXö®µZM½§)!&:{Hô^²»üùtäÅ#§&Ã °S“éVEÜ4š8Ò)…°ÍFlÌ è@¼q*(é»)'°fWEâ—uÆ1V	EHWMçé5'ö| q”G-KEO“dFÈcz{jR ã ìµBµ©¤ú‰M'Ê²g§Yó³¹,8nœpÓ‡ıÌeÅO«$İLµw+K X’o5•¦mñA¬DÅb»ä´»İ(ªPŞİ‡=]N®İ-uª¤*ü8msLÇõÕzÅøS_¬@¡ia^20úºÔqï¤Ë¨ÏÒ‘ÛÖ>>=,<ÁQïPéw '
<7>~ÕÒq«óùQ©\,§D>›À	¿«c(u¦§¢ÎIíè6,vüN=©7¤ÓË4è1ÁÍ‰z”—ÌÊö7G¼ñ«?³}gjË›é¦Lgm*”>"şIÄ‹ÅÉWÂó|­Ai™ŸúA¹k‡$)
ŞV*Âöš#(©×—È.Qy•—ofWHã×LÙ™ëè¾_„hùw½0«\ÕLü‡˜I!8Ë„ğ‡Lı–m
¾Ş¹Œİ³º¿Ú©•ÆÏ`Ó²‘«–¥€‡fQg6f]m}ŞÑ­GÄ‰ï­A9aÆo 6sø{«ü‚™(ø…µdÌ£À[ÿÌö^·²Ûu?{L¢·#G‚|Šz!‘/Nˆx j6ëvXÈ½Ïø–rr®ŸÒ‰´}®åC“Jƒ½…äBH%GfÑHõ½ƒĞp>–ÄŠ—oÆ ô-a1èÆ×áÜ(Š$%›zÇùd5¼'fÚ©ÚBÃ;/dS‡O½@&ß–ìÿjVúDæ"èpÔY vß¾‹ì*üO4P½rìŠÈx²)çd˜|Z÷=§¢–ºIÖ‰z íCfCªÜ	iÈ¾€škÉ³¯T‘iÔvæÖŞ«`¶‹“:CÆßÃ‘!épÅ‹¡®!ÆB>uüµ~r7­Ì)vöLN¹yZºö^óCœÓ7ê³lh1t`kO¶ÚE¥áÊ‡iø¿›æéüY—m*·ĞìlçíıŸ j÷µ™U‰{AÉ+L'ı‡´
ÄŞ£ wçø½B@+2Äjîœ%ğcabôSA@à Xø½Ó~Ipô\P#}¤nAAêı%İÌ#æ„„4m!Í"‘eı&¶	c>¦y¬v©	÷‰=ºqFQ=±ˆ—¸{ ì¬ÁÏœ`œ»
‰6ùşâUšøvğ:ÿIh¸R„…ZM½åï:+­oS½G•ÌÑ2[lWÚØÆ+E‹n—¼!â¿VıİÁZˆ[%¹¨­ğ `É¡_KçÆÑI#1.·HA×e„F…‰¥°ØUš¼"@¶Ã)"Ú§cãq?Å|¹.	ÍI¸i¡úw%†	U˜‘Õ3ËÎñC<vıoÚ=QÈòœéuX¼º"ÿÅdİÔÁ|)eMøwD-Ô/KéÌã¹åzu[pƒéha£~>©” _ëÙóôòİ¦F‰r)°3¥œô‹¥Xèê[NAtnú²ø9*Èæg™•3Í}I-ßãÓ²şü‡é©AÊ\wY¬e|éê´Aô×¥.W5[Ÿ‰½ˆ<v²ı3™Ùú¦3¥èÊXüÙ¥êñsãäQãô:«0ÌÌØcøòø«<ÙÆÃ6— |İÁğºß-HŒ;¥Óø|æ&‰(î-Ù€±@â•éFÆqFâ•¾‚š§}Ò¹I|ÃWş Ú°Q_†h2¿ò”÷|˜ª¥£4o<uš¹‡Ù¥?Y_]şÆËÈŞİôoÖIA«•ö3…'…µ•~zWĞ»«ìÖ#Hà¨I`»G‡Â¨3İhä8Û«‰3ÁÆÊJâ²©WşTÎÙì¾ø,uŸÛca§‚‰•ë{8ıÿ×õ=UÜ}=q~»Û¾ş	±ÈeöÀ-M3‚R¯~07!ë”ov	õºš™cŒ~(ğ '6?.—ÕBSR§	
m•å¤½a×ÖUôásJÚãšcÚ9)Ò©Ù]KûX[A`6%¥ÔØ»’3rù™Ä}tÈƒµÜ~i˜:ğÈrYNÀ„GâÌEÙÎLæf`Éƒ¨‰#K1Âw8ZüJLU§ÇËÎo—DÃ%†u8ø]è¹áWôä2òl„[5#[BÙ'‘ˆ¶‚=şNıŞ‡ÑÁ8ñ3Ç˜ÒÛfÆ^£÷ò6Ä–¤ãúYMeFBÁ…²²¹ğL¿V$d#"r@W;™ÓYp·M¶)=Ä_h"RÁªªË8ØÛ®3òó9J°KC×××Î‰½*¹“?pÎÇ®‹f€øã²rî3eàÉµC’f%NzĞ;*}‹Ù‹ªwN2vœWõÿÎ‰„ÀVÜt°J²?ô%©>wu|ÆúªÈ”Íå–ßBqÊˆ/‹,Ø.Iâœ,®rÕ`™J$¨8bÖ$¹)òdÇ 7O÷‘±ó­`ß½JôÏÀ³ƒç)üíå	8=¾ˆÔ=Áb©pzÂ6ËòÈ@' |ßƒIQ;8’×’wM¼­0î¸Î¦™S„)úŠdÛaWÍ>¯ååˆNdÇ`»w6¶×Ff# ¨»¥/Ö`g6¼êúû§Øf{i?¤àÇ.Vx¥ «ÃÀ·Œ­(aÍ)¯§Tg{€‚¤­½v*Åwf¸ËJ¯ô†UåìµÎeÉ[w?%B©-n™>ÁÔÅ7õqµ
Ì+>Ÿ˜¨|•n;¯ÒópÜqÃ¢DñÊƒ		­üä`I '»½¬!.OÍĞ{1µ›®¡ŞD\
Íz¬z[B£ÎİWv>ğœøİK¾”,ÛâÃ„j-I{ä—¹0aä1ñPeî~Ó©ô%£tÃ—©eH~6ÊğŞN)®OVål{î»¥©$$şM–2%C'Os;%\`¹,¦òå~'9óíérxôŒ=ı!É€¶vÇ¬¦éSG¢®–…ÖÉñë½K LÅ»ª7ø<„g‰è Ğ\úä3™kÊ ¾Ä›HàöÒÜç«gò"ƒÌµa’üBôåÒç«xAnbÖ–H‚šß_RºÑGR˜X£
d~¦-MŞ×O—N”ëê†BâD,òÁƒq&‘Qvıº§œ4âŠ÷ÃS?ñ·ÙPxvøs8o»{­2x¦ÏŸÇ“Ö<,r_+A…[W¬Š±Æ'+xb^İ½İWP[q¯xçø%”3çs×oïDS¥ÆÎ O«¥†½Ñ Ñ±£ ¾çbY½¸w%Q·3'	“».—W ÀÉØ“Ö´ãQj¸bt­«ğ ú0A`s­«OÃ}îÇ÷ÄsŒ©ƒêğÅ…ãRÓ+ª+Ü²¹C¬¬»njrçcõ«›yqbØ°÷Í;j«™!!Àh So)n?ìôî#ÎÃÌïÜ@¬¯ÃVñè|1O
,÷ö\ØPSöh|‰½Ÿcš\X¢©!…û!Õ0¸KH$õô$²Ü„l<óq©,EáéƒÓ‡Şë¶`—Œ’>:+ÈH8ì’[çÚ'R@Íğ€3¹ğg©Ğ"º•Ñæ„Œw³ØT³-¡˜Ê+øõ%º/{Ÿ¬²³ÏÿÊä­\#Ú0Ç×.˜Ó•ü¿—²ÉÆâşÖu9 ±–ùQlÊš,IX÷3có”µöz}bÍU´‹ßÓêôÖÖ÷Ìxiš†g;Zÿ9z¾˜”„EÜ´€nVº“v,i×À-˜H[ìæ¤ñçÉHÒx^h¹“ÿbïUÉ¤3À‚Ê­oÚÉíÕíJ…¡ÑQ+òâãHìÂÊ–yÎ™ëÑT>Û¹‘¸üï!¾Ì³†HiÜ÷°ızàÑ¹'ÀmÇzÈûÃqw¡ÕIïBÜ2‹ZBV?/«g›­T9)“Å`” kF‘`%ÊR‚Î¯nŠN¯ügĞõ§Bd Uv¤pSÓ>‹‘‘2Ÿ[%ú›¯¼1§K™ªõ*v &íhÌ>s¤Š?ã¥XSŞF}™ş¼H©>ŠÁ)óÈ™NxâBcÒwŸ²Ş
úPÎôG¢RÙ E#ğ˜lS:ÊÉ[ñ;I*hW›åÚK¡ğÍ>{8İˆùjf+±AOU¢mÄçï0g±»ò—®2îM‡ìil'µš2èwU‚úän»_VI›Pä‹›\Æ¼µus² ã©Gİ¾aÃ§Û…]ÖÅâ¦qü!-6—;ÃËÓõ½êƒ¶ëëÏĞûí,óµ\‚]æÒ«ì)-y„f…•~¬.Ä">t%ü¾U®;¾KUrîJl¥.¤iLõ!ŒË”c«ÛÏ®ø9	õCátg÷›d]­`1v0h®‰µ½Ïó?*Á<Ç{+çQ€jd`¸–wğ”¹Í¥?_•Õİ5>M§q$º:¢´mjC®ñxÑN1ï%A;\¼h-½Z2Á¿™
Ã›¹·g£ô¤¤nÿgñ1ØøMªª|÷£À¹\±¾«o¨»Æë÷Öå¥æí¶ Gp‘]Y¹”¥òÃ0´¼üŠN²Ê}‰Eûùß¥f¤è67"×­4Ru<ş!‡]Ïa¿ãm/c.ÚÚ Q9ŞWŒS¦çrhx“
İõeƒe—[0¤é”˜lşÏy Rkİ™#å'Š¬ˆÆ5G DZıxƒ—Ô=&:¤Õ›èI$øázC    ‰.âm
lm ê¡€ &? '±Ägû    YZ