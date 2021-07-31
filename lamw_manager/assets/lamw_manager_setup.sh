#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1545253322"
MD5="e2a9a1bf2854d0cbc2c8c76c43aba6b4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23092"
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
	echo Date of packaging: Sat Jul 31 16:54:52 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYñ] ¼}•À1Dd]‡Á›PætİDö`Û'åŞô¦=™pº!Î©¤Ôr‹¾dD˜Ğ<Ow‰b¶N¨æ®nÇÛ^lKL¯„&‰9ä£â!¢¹Ÿ|uİ»šZ¼C9Ú­¸[…'N€«¢o$Cu¥Zß%´÷›1Q¸`~Öòı…¼·i‹B¨Ã1¶o8Îè3a×Ò¨š>4%É¯Ğ:¤ d²T`Œ¾Kº´¥ßAƒÓªß¶À×Ño!µ¶L9ÖÖ[º_ïE6½Éè¬¨Á+•W9y¼‹ô¿7@¥½z[>ğ-‡J©6}bİ¶¡øPy'T}å,‘&[ÊØ]:<_Ê®Eå•5ğ‘7_4MÏ»@
¨‘Š˜2$º#‰Vûç©|¸$Ô(ÎCõHƒS–ÍD­û–y²5àkë·ePàşRÜ¬Ş{Xït-or×À+8‚–_Ìp‘!|€ırq}à“½u¸·ôÒ~Ç_” óÎá¬¾sÙAKµ9ÿ‘¥-K½05Bê.³[»çİŠªæƒGC;ká¸æÍI;šçb@Šù×ë/w}Ûùüp=Š”öĞOCAiŒßş 4í%oLÅa°÷´Ø¼@d,¯«CÎØ´úU8µ>.µ”&i¶ád!?ü…ï4‚ïfA?õÌPk:zo" Ê°ßJùW^êuÄ{Â÷«Z€fè¦aæJ4²ĞĞkİ2ÇšöhM·£Ò‚P‰aFI‹İÍüı¸kì¨ù­ZB7’A4Š“}AÃÒ-5ŞqæözgĞ…Y‡"3†OR!ß‚XãïŠºezyêË=F'ÿCÀì1G´™+z‘í5—d»À¸×XÑm l¡¿‹ş»¥wÆ `ŞÆöšÂ…ÑE°Á®çT/õ&Àª›ı…8’f=&~§U[´ØO«è£ÙZöÖ•x3çÊ[CZ·Û
|JÕş´Êâ;¼T/?qß€8¼7İÆs£ÿ{;¬ÛK$rÊ6¬XÍ¿q¯M,„ª²|„n©ÍûWÃÜ‡”´~'y	õ¦)kïÓİrì¢{O²kÇršJ€"rPè±ƒ‡é uzRux,_?âˆÈ,±>¸±¯£HÃoŸ~Œ®÷FE–?QæÊÅÌ
_Ò¶vÈºÚ.ÖóÏXø§;—’0W²ü«$E6 lái†*aiI÷ÄçlÑ;©—™St2ÖİdSâ'Zûù1†ø½ÇùÌÛ02¸4UÛÚ,'oNŠİšÑİÇ±5PcXÓDıäB7õ\&ï_dG«ÆD çwªX¨E"ÙMPÖ¯R“·P„á´µT¹)–¾kåµŸÌ‹÷ Ôhi³©U7ê õ7“Íø.!¸bÏ"‘À$Uªšjâ!‘¿¬½ò§tØ†§ùŸtÒš®¼)'bMúˆF°ÚWá®óÓÉ†kËû2ŒşdíŸ ıÒZL™ßm¤ÈØÀm.O£³sh»$…±ÒÅï´åÇX Ed¯NñnóxN;ŞDEv!¼­º¥××™¾¤×—“hÆm"×ÉRVæåHµö†<Ô2]”íôQl^vCùi?±nÒŒö¼©¸üDğcĞw¾tM3€q:¹œ~·¬ÛC¦¨¥BÂÍ%œX”Òƒ:Au!†ia]gâ}g×gu±¹UCîµMCOõ<°dä>Ó&ÈEç›æDomáfûİc–lÀ÷±}$¶7ƒ_Æ%êù3Œëy`Á‘ƒaFõúÛ<áEÉ²qí«jØyÃaôœâw¾Yº’¶‹ÀÜ‡"ÆºÚãU„àŞpİÑ›ÅÍOpJô[øI9&å³C¿Í°ÏıfŒÿæcÁ	®$"ÉÍvÁŒÇ´X›¤I'‚¶ëRŸãÊµÅCj½½ññ&H|şñ<3»Ã¤ô…‡	Rè6ÇVQV`f|¥K±ı,|k»,¦Ën±Şğì{Œ«°—µ7Š–’.œÏ¬vM.¥P™2óŠU[ÒÆÖchM§‚*6^¼çgøJqôÙ Læíóä¡ »GµJÌ( Yû%\Tä»[v-óşSpCj˜±ìHÊ÷!=ìÖ—Ï5Ê ò q*9UDŒƒ’S¾z¾~Xïàã¢¦%-‹Ëå¨Ã4š‰q“áßR2ÖˆÁšÅp²7v©QÔ0ÉâÿIm_Ñpóq.˜qÔsšàUŠí¼¯(¾èşÈT$D0èú×¯Á ¡Ö+w=Mà,ŒòÕ©kÿ±4s3hy¾ê)¦S¹5²s ³·Á|%XÆm!ÙÓ¬ŠÙAôú#İéî”%y»¸tLTŞeÅ÷ú 6`§Æév®]zE(*Ûı~ñÛ‡p•Ö­bÊÛÊ¼¨ãq0.”â¥gDÉC>< z’,)WöÈ—Ë[´_÷B%O›à
Â‘Eù&Cğ‚?&sœ.h©´„j&s¾£a¿„"íu‰ğÂ¹c/‰')&ù©—%3ç)Í2Q”v*İîómFúZÕc YÉW´ûÏı¨•z|
¼ã¦"‰Öª“ş?µ/Á*Û·L‰±‹ òTßüş—&muÖ½¾RdZÆLßâ‘wÉø*wÔÌÙìË¦,î#f½_è¶Ş·-›;ˆ¹˜CÙ ¨d İ¤+óß¢´DGo’·jÀúd¤æk0°`_„~›ÓR °BJ¯¨+h<_›Ô˜á7_“İ—SR“µìæ!Ã‹,½ı¾uå‘C
äŒÿÙbôï]•)aÍ.›Gwv}¾©Õf•şu| 8P>xÎ„!ø{Ïœæ÷ßÇIæÎ{•=¢WaáxÊàV:#´Ù©»ÀëR7\Fd¿ê"ÿp€vfºÕşpWüpp3Ä,±”D1½¿KJ6™Dª=[ä¢&‚‹kF$uÒÆaÛ•sk\öÙ¥ğ7Œ^ócb¬q–â''Êy…àxÀ‹O­ÙÔà¬­2µBªãØà?fY]áÚŞ6šn×°ğÆK¦ƒò¶jBªªĞT‰Q‹Oêz@HÃ11]±‡/˜KÜäˆúœ$	kj8§ç]éÇYÆÇ 1°2¾P4=Eî¸cÒ°v›¦…`Î¥s¯ºo7ÓÑ…$5ó8$9\v`lğš|r¸µÛ‰m#†}|a¥÷T·¿Ç4$Ü0)k”d{IÇóÛAzxİI[ 
ö«M¿~£\8 Ó5nNò€¡¬rıÓĞ¨ùİ;Ã›!òŒB÷_ÍÔâŸè¡ŞfŸÀq“· Ó¸¹Ç”Î/àñIm§æz’}E(pø"Ïì\qÅáÔšú˜œ„/ƒsŠÉÁ§Éôj˜›dX…TĞÍã‡.Sk±rî”ûy’ƒœç(oŒAÁÆÛÌZäŞ½÷WqºoÙ‰ Jë¨îïÅôføä©ûLWRWø¡G/l4S›ï™VÖì‹õâ{,ø|ÚĞp®’şBtK{ÚÊ@2ÖÙ¤³¿$Œ/;<"mİ¬õ¸;Š	¶GÿUy©OÌ¥jİ×ô±W]D/'*óü•<=˜m8çX(¼
§³ç?ÏÕ_lóÍ6ÉõäÙ+øŞ à¢€ÉÖéÑİ³²ÈLAJKŒ¤‹Ç@ŠÈáÙS–f¼K+#¢«E \iÏK‚Í.³‰a$´C¥Š%IÒm Ô¿ü¾U„ÜŠ0ÊÉj6ÈĞzÌ“9ß˜©~´ïu¦KÿË('WÀ¿"ĞÏÍğ³¤Nše.Fn–¸>p¡e•·¨©›b6i“rıQŠòñFRjÂ{Óç•80p©g ³¦j/9Ì9~“,çŒÅ‰‡ÿtç‹±VP„sÏm¨jÉIÕÏ|f•?Õ(prkXÜ~.¤ğ?Á£Ó•±àÎÀÏsq&å$ûd y òúy§kB]šÂÖ2]„ hiÎ¹©·¡Ã¤ï9*çâ­¤HÑ~|Í¼qÚôÿ¿[¼úï·]åàÜÑx¹šÂ¶òæI+w[k$o4×o%ç¹âxª,hâ®™gLœ4 û_çt]:ûf‰”</Gë³2Sâ…-Î›8„e=ØØtšïTıRan«gœpáD’ªÒ_àÀI¤…{ĞíÈiËHÁ§:DKãa^
m’¾÷õœó;Qc§¨Tjgš9Â¢œYfœz"³Æ~\¢o”Ğ
rc)œƒwúüıñNëª‘RÕÍ_¯b,Ù©ôíü‹²¾dDÏÅİ`½‚!iÁl¶ñ‚Xwÿú6Wpóg”¦D§İ­(U /î¿…óèA5ÌAâ,'ä¿àx„ÚgãƒÛ:Èjmß×&@±ÛOy¸wj‡jp¬”ğÒ©»[OxÀú÷³“^s¶ôÙM¼ˆÕ[¸ƒ¬_<¿,ÊäMH‡aÉ(5q.‘t	Ì
»Õ#q“‘âõñA-á”`TŞÜz&:lÿèƒ¡åxÇ½úy@CGI‚”õÕNV*ØÎà‹|‡\•€ûuº¶a‚²õ«" ÔRSéE]!Ò‹ß¹šyÌd$ç´ØC!]0-µ®$ÃÄ´g@ÊD~Â8*<Ëúûµúf>ˆIõ‡ç×lñhÿ pÍD&É’'ß£f'
[nH…±ÔÏ-/KÁï5 ycxøi­£}§bˆ\nvÓÕØ)·;Bİï8ŸdQ„¨ƒp±'Ääh¿Cn2ÛóË¤f]ß/<„GQ7eİ3õÌóÂØœ–ÀBZ²h’‘¼ğÂÉŒæzŸÄÉÙ`vGf‚7¶Ø”?Ì®d­`Â¬í(§¨Vú~ì<4Ó~·&-–kÈgö™/Úºçòw|rÖ—g>\gtC×¤Ÿè­«¼yŒD<Ì>·«!}œœ²ÅUÒw¾v877-"<,áV$¯P‡ßI$à‚k ŒÒöR"Œ¨ì¶×†)#i;¥Ã»O«-ãI^··‘—V(ì —/Ï!tíí¥6–®¾“ÄwĞ>‚‡QîVìuÒAXÑ5;+í§‡‚¦¿ÈX”ù«ˆ@ı¥ôø#ÔæïCtëÉx¾,ğïü²Aô*rï&¸? ÷—±q)Ù´÷¡J/g“;¯HiˆG£~¹<‡>O%{ş¬ Õ–øº·do•ˆÍ*ì#-‚ıI±Ûé”.‚ğï(#ü¼>Áû2Ñ×£àá¡Ñ¡ı¸üÏ;Î=¡_`pîëüˆf!sò4v½7?>qB[Ù<ı&òN‡æĞ3€GÙíè7ö1äJØè@›ò™|®Š’Ã#«kÖ;¡€»¾‚m_y‹è‹ğd|Lä€JÂn!Å˜2{vUÒ—BYîĞgÕ8ò<íAE^Ä·R*|÷¤Ä Ø[£Q…ÙüR›Mf‹OÒO0-ÕìQŠ0Ÿ‘íLBêÎ32ÓÏ9]f¥Í9T`X·¦tğùo’¶¢ JÀehvŸhù54kQ¿m“ùAêTEºI	Ä«œ%-'”ñlà)Qú®F ˜I8-ê–1Ù˜Û¥êîæèÇz½ğo¤53Y/«·l_·ÊŞ®æ eOgYñ.H=šî Ê5ª‚–·Ù9¿GV=Ò~kş•ƒsÉ`–áÙô£?0¯g:¼Æ°7¯¸Ş"‡œU@XéoÇ	‡ÃRL#°ÄÛ¢~&V}˜â·+}VúB¢ÛÙr’K—g²ëè*‡c`;£iã­É~ƒæÓÜÍ KkÖñÅsƒ)©{½/zÌĞ™ã¼Cü„*‰GİC†+xsâ¦)&¤cp9ïÎ‰¿ŞÚÙâ^uøºœ‹Ç.7érğ6÷ª˜Gg(Éü½vÉ¸*è× J+]åú„$Ä›‘ú@}‹|q_1ĞgSB4LîŠ?Çö½üP¿É™ßÄŞ*>3ÃT%|7Ğ®/ì?;Pñœt®ŠVÅÛÍûIŠ¢nB{hus! ‚1x§„—g|·ü7ğfFI—Ì„9)[æ£7¶*–y^È”é€Ñ1ëˆ‚Ô¤eçÛ´=8WÕ
®ƒÀ‚½‘%Ú5Wp)ÎØí|å2;eåÄÎ
Fì³lyAÙëÅ§Ú£N{İçÑoäÿ|\ËfNG=_úÓ¥L7Œğ ÷.dŠ×¨Yzib­¥òåş3†—WTŠ_`¾°èê£…´NaßVˆ5b]¢İúb{Wû<ØÆñ¡rÅSå4ÀkI#u£‚lÇh`‡+÷L`˜÷;|{
ƒ%‰…L3µši%0èlshHÕ¡Óy"^‰*i8×ÿï#‹ãÑÁ´LšƒjF<”S·'ÆD—°Í.’UÆ*=lké¸!—Ò
xzS0[| d¬åÒÏÉ” ÿÌÇé²Ì«í	W@I“€ğGìîÆÁV­í+¢ä%‰™üFÄmPh{<™óšLŒ;ÌZ‘ÕgU,}3©=&õö›5"-úr6|0~QÈ‘'!èuÜ;E>a÷vÈ’Í¯7˜âÚN˜Ê””¦a-ÀZá~á©ûÈºcò©…¬ïAõ@«ÃşÉ•ÅWÖU,D…ñØÒmpHéºÌjeÀOÂWRg±´¹G'0d§›Óå_Oqµ¤g½wáµüñâşRÿîÌN‘F	”F[#:X_k‘­u;ÍæÍşÕ{oÍİiµ…ÔstÆşğ¦A¬²’’]0Fc[2DzQíW,%JÈ†7B¿cl¬zÜ²y¿ğ]eòõL4äó{Pà¸Åçg³à®)h/£¶›¾ Xœâ5©X}gĞ
Bv”YóF¹õWÕB,OçpD—c¶KšØ¹ğÈãÜT<Á¨K&ı"i¥K”™CbuXï!õ¨Ó3ON=–
mÌMŞó—À¨!¸™
Ä™:ÙoäK“_‚ë˜lñ5"gQ(Ê´’$µQıÖH“ï2ç!O
øê2Û1ìÎX:¸îJı §•U|z0ÚæÆÉj‹¡ùfEoÂÎĞ¯fÊ ù4(¸Hİ>Ë.ÊpN`rû=Gzx²[üÚŠòhÑÈ¿r°µû(‡5ˆßŠ;E¿`é†>ã«»ü
ßŸH£js¦S7Xı.­§ªé-Äõ‘¿½ó”Hí¸èW àÙ±›{xÇaboZ'ÛC2@®Êä[¶¹F%ê¼lÔúĞç/&­öÖù‘/éç/éQ
Ó9
—gâ ú[•·—7±U†c[tbFjmKÔ|ÿ—7rë’9eã]¥Fî²õí•0vªVµù­s’ io%€ôÏíz&ìläŞ¸@i1?‡iğ¶=h¨TcW«")`ÃcíòÕßÍG›¤Ô(©ù1¶“¸¹Ó`—ÁXF©¡Ig—]ùdFN‚Ğ1ü)é×µš.šOİİ¦.ïÜÿ4KÍ}ófó´L–Çæ¬n:+£i8ûû/L/IØ’ŞŸ@İq‰Œ='™±ùˆeŠg…
ğ1âFş\9ÓT±PaU-ˆ†¸=ˆ°»™2cu o1»®0ÂAôØèá—?wÚ±`û;i×^üvœš^rO ÓÍa‰DˆkşÇLK‹¤v¢|vUò›¿o–˜¯
/)gãİ?ˆ6l»^=øàÁ´V|¦;ÍvEıÑbüÙ±Ä›VK§Æ	¥áğ‹ô&ë8îØ—@ë/C¯Ùàf³°1Ûú †Èg¬Ÿ¿b‰õ85â; )ºo lÉRÕlëf‚›™1-Œ]¢Ïa’¤Yš‚PSM%?
Lğì0Q2á•m¿= Ã†¬ˆ,ÙıùÇİ5ÁF5†1`÷Bí€Äû)¥˜x,{S~­ÓTŸ°óAŞ|…ÓšÒ"ŸèÓCBéLÁT¤œ ãv<™Y2³a`IGlaÌ*`Å¨»‹9k?^ŞÿVSú]!zu 	MJ)<Ñ§u¦ê¾Æ$o+¢3&\…ùRÿØ•ÁJÈ£›í4L‘»šm^T@izj:è¼ªe‰ØÅÚ-j#™ïS<ĞİorËµ«tP	ıœçå0¨Lş3³0š¤ñş::{$è†x{)ä†gzë±Çô£<á2NŒğÛ;7j†•4Q±ú4şúÃÍìX€b2â„wÒk Úî]éŠ>|g+épMÕ¹ÚÕ*UbrÇÍî%ÓÖH2ş²*oª{f{ºşC …Âˆ½û„³Õ)\u€Æ·Ê²“‰ëËàúTâ(ß37?ğBÍSÉ;DâÉ³/ªr}nä×YJT‡xTæº.2±>”Ğ¿Ô°Ÿ|Æ\Ô…¯ƒX´„ü<éÂ/Õã±ĞO/RV‚TµSWöò' Êì{§h wß”ÔJ¦¤(<ò=)¹Í¶¥ŞˆØş 3•c8(&h¢"”WO†ÑàŒ¶³h4…4f®UÀ²aH
úõTËê†¿.†ãí¼fqûs²xnú9'$?“‰åX›†:â‰Ä1÷4cÎ‹<8••éı-{²¥ŠøëÏIò#5„¤°g±ç	g`«ŞÕè´¾¦ÖÇé=:Û'^‡rQ–3œë®vw?!Œ^#Ó9s¢×Z=‘›ïHØb@ı,¢%åiMÒºÎìø^Y)C‚`L4AjOÌ¼Ã˜1{s
œÉ,gë*Ìì«ğR¦éÛQ)V+Tö„%÷ˆfèxkBN´lşUÈYYKSg)™()@å¶ÅH¸«é¬í Ëè”
Ôğ9y_Óhâ7!/B¶şyÿL¦+‰İcFp¤Ì›÷‰§eY7‡NëÍ>óà\$áÚ«Ñ>XRí;UÄÁ-O³SHÉœF¢fy™‡ˆán¤ü±~JKÈğ¸]]ÙUq[»Hµöı€\¨>Û0(äHE+ˆ¡n«±‰g@ú5ïı--ã9å7§ŒÑ;±/ôƒp…=èüÚqR³Ä%¾qÔm„èXlÚAe{üÒŠèÚ]2b6M{+Ü¹|¨Ûˆÿ—«çyBúÁOiUh‹8â¯õ¸î‚Ç9ç³Š ¡/AB4ÍyÖ%8ZBÔ0şÄH 0`Ë	„Tïvv°Âşî¹Ô8e®L'û‹0â¸O0N'Ïã‘ ‘K…gz†%²ìÁN¿|Ş’¸O‡ZV‹•¼îĞá†ş±ÃÕGä¨)SQ²AaaÜz°b££<ë¬æŞnù¯®äW:=ÿ|Ïß›jm{lö%>IvFâtÉğG(i%å
ÃSPdç“Ö	‰ûç”0ê•cwÃê¤#,’•­b0´©ë¦>vL6hÃ	3^úÙí(‰bÊ™¨œfB)ìô†OS³oÓÓ:ÕsEeşDÍ6†Aû?kp~÷*;˜%<˜¾¼¥vwETßà'=ÚûOHşÈ•|&v0ˆ´yyk¯>ø²ëñÕÓhjÑ^pšñ‹”#Çğhß*ìGÖúC²y(ˆSqcasáœ—UØæcYÔÅåÛâ©¶…™¢?ãr­st^£âææºÒ¦ˆ—w¥ği€Û‘éœVˆø›Îïµ…?YÛÖğ¦m\&¬qîÏk<¦Ç¨F²]‚7`‘'´«Ñ)®Ş«¸±8Fºñ—j^j~¥~ÒcfÛ+1Ç]†8	®ŞT«È0ŒÎgAx5a›¨ë7jÍ‰EHÕøÀ˜Ù?Œù”ÌÕôg–ˆGÌê›C_ÍãbX“|J¦…^µú³ëÚpq\Çw©-È¥“Õ®'t1w?”+„í•‘ı¾;?wMBş[C "š…b¨d7ÇH)}¥7MÉ.[‹æ9Gûº\·œr~?ÄhÊ_ë‘Ëº}‘ar´›Rß±à²l²ëU8Çù8:œ¢@ôïy,–¹†á…©Ò*c™$O¨‹?ójæúóÛPôvÃ×İ ˆdLâï?ç¼Å¢CR[\ãÌÀ;XNò¯2·Ëôj¡ÑQ¹hv'’¦J”¹!Œbª.L‹“&súÉØâ_”¸O*»ªø,/`4ZË–ï·¬<tWyñ%Ô]ø£ú®¨Hòì 2gÆ"AÅkFÚ#Iı9Ø‡·KR¸y&›–Å'ÄJzö‹ÄãaÁÃùë+ÁP„`»Y E|
Ô=ç[µ'âlI5{'çÕy›¦ö²mg¢£T’ı–òZ%FâöøGÌœğ¬Ü ­·œ)Â£´2_†ÄùQURoáDÛq¿Ş“¥›“§>{àP5¾MŒ²9_|W¦J0Ÿd„MÜ’Tå˜ÅöWŠLŞä‡I……fÊ‹¿4 !±»qeäsK)*ps{£Yğ’šñqÇ¢ËÏè_œÍ ¼Dt|>Ş­çöçA(	àòësjch*n§'WZ:Ög¡€§2Šk}n+±Æ’ú¹î<¯6Œ Œ4¸J$8ïšòÃşĞ?AÛÁ¤Çí,[Óaªû*şÈÔkŞ-P¤ÃÚì€q1cXU}1Äì»^‹§È{/¬ÕX<æFE¡(Òî<èôÍüí —±¬K÷‚‡C@šË(2È¥Îr»ZY"€(-fº÷•~Æ‚Ï.–/Ì°	Îğä±Vœ.`ÈKAnnF©–èiŸkuoh=•_¶ÇâbäôIáÇ¦àMÊ‡lHŠ,V\&!?Í"@'¬Õ	eİu˜Xäğíá‡}ŠúÿñÌS©Å+ÙLªëbÁP×¾»ªÆi^;b¯•/ç q¾h¡)IõêÒ7áPOOşéØØfhGJ*C’µ«ìYİûÂ¨<KX¡‡k€«lê²Ôºu–îÜ{`É´YÀ	ËM„ŞÀBøVç¯`Á³l€®ê–ÊZgô1Ë …ÈuÎÕ·„gË•ÕĞÁÌq­ G˜1¬ºMr@kfç	İÄæ~¦4’“b¿‹¦h˜vV:’Pùô¬j:œÇ3ÏPiÀŒwùu,z{½¼‡øRİÎæg3@QÅjë¾A”Ó|oçÓ…iÛBxYPeKò«Êà³<‚53¦0„µ°`ÄÇĞÎŸPNÿ™¢BóÓ¶H:E5u’
•©ˆˆ°ú@ŞÂÒZüÀ©·º¶¸?¤:ÆöYa‹®}{g?9tÑ_O×Ÿw•µRÏ8ûX"Æ3ˆ—Š¸{P"ıîÕ…kpıØ7‹|~_‚“¾¿díÜ"[{ÃAJvÕ—ğS¸;nÔ°PcêƒŒ¬¼Y/#­Ù
BWé"@ÎÌ·4°,j¼¥‡Ø9\`¦~ë²°MT™İ£Ë&ğí:dE pRlV|iÖßÁaf#*Å}î{Ã'¤]W‚ªó‚ğyÎ½uÚ·õ÷Êßä²àÒŒ×­ŸV\-?IØ^éºä“³E˜kdÏÔ=€È$'5ë‚å…‚mHÂµğkŒ<)âÉ£¬şvÀOynşâBÎ¨7x¦è«sfs9gÃX½tlª¸ÜœÒ¢‚¾¤;*¸›Ø¿ =2¿î9µrKa?ûq‹p(©
$ÁÇvËÇ)tµÅ Ïü¢SüõÙ)¿Ñxuuó ¸J¾Â¿1µ CQ=ü‡uÒH—™ÛÒäK6Ô›ÏŠ8»Št]n§G™uào~Ç.Ì|ƒ²^@WáÇ1Ü.}Ú)à’,'ÖàÚÑã^×´ïx1E¦©­ İ•á õÊ’¼kÓ4vıõ2®œêxÒšàpır–íDÊçSbßBŠØ6	ò$ùrğÁäØš÷øaÔ'«”ÅJ}<f!š<›Úvåš©U¯)Ò“âiµ»ŞÉ¡ê‹ŒNådg
%*P…TŸıA]Lÿ$F§p~5Œ©ÙfÒ÷îÃğp½£qkk6eøİÇÄRˆH•Ú£vˆ|—,ƒÇøğ\k"Ù)÷oô–ˆs_òÈ±¨ó
¼ ÷ñ»‘ ‡Š°æ^o“ö5î{ +‚N0L¶çè¨%Øt8òˆKğµ&P’Åâ  «²™¥;×ˆÃƒQb’ä1ÙÂÆõï 8
ç°ğ.#ÃÓ›µ¶šzšyŸN™èJK²¼€¥¦EİÌ«ğMR@¬ªe…CFºëÒ‘r´èõ"Ò’fKƒ(Ìà
ájÊvP2¢‘¥m³Û÷"BĞ7: vÈVŠ¼VíùLåú×éÆ0¹Âfã+Dì*ê¿h¯éé´ƒnxn¿Å´ =MÂ‹ØË8İ$“+6ÍüV©É`)¢
ZËƒbŸ¬aºÜ@ß©ĞW¢-ĞÔË¤Ê¸ãq·üh‘³5@ã“BğÂuÕh†Ò×Æ§¸ùØH=ú'¹ÙüºÇ…×4ÛÆ„,uW:Œ¥šDßQhæÕü°úĞŠÒ|kLD:šKWUcs³Nåãú
aéë`	C‰íİSğä˜‚ş¸å@ U‰z ³Ûà@yìDë9†ˆéµùèZC+¦Šç:ˆk8±Ñ•tÓ)Qjbø7ò+½/-1»•‘d4z'íĞ&ö$>qÍˆkŒ~Öé!ÅÉ[„¢)/?ä8 päÇ£—î*‚W'¨$a®^Ğv“¡¢×6XA‘,[÷l!ï³Y½m“»ˆ1=Ìø__õ« Ú$‚[×bfrÒøéÒ.H[	üÚÁüOzõW1WãHú+?°Fdšì öçz¬‚:İ¿”Ö8»ÙB%¨QÊ|wñ˜z‹P_¡DØ³“ÂŞø‡#T*k°T®‡#ÔÚmåUšs¿,Ókù-’€ä—f ¨àœUjò÷»ô¶ñ	QR½NL¡÷9M,ı›ÿ‡G¼­ñÃf_"¸Ôi‡'³‰ã‘ÍÙõ $ùœÎ3şSÉÜªGÃ¨Vİ\\Ùu";Š=b´µ‡é%Éèidÿúr}YcÄY“{?]
d÷?u£G}7çLˆ*YñŒöÖp«%P-ı·€)izoúxÙÿ’¸ĞLÙC8ôè,¦·šsS1Ù{5¬?ğI7†2*Öj§çZ}Ñ®weQ÷üÛBäÄ!W²Ä­fAm×ŞØÿ]„æ™»GZE§PWš¦aÇÇØòSÇ1$éÓ©HtxË8Ôå½DëŠ­
<LR1õ[lˆH{-[§41èŒ(q4úvºë­£«oÑÀ(»%ùl«—¡=,IgÃtÙªfGªúpuz=*ùÉRA/Y}Ò„wTvùÆæ¨•D¹­Ø›Ä£ø9ïˆ ç›-~ÙÊ*ÖÊ\3ƒu­ñy©âÖ±‚Ò_è¾s>%aî¬”
“­sDÇşSÅqSô¶d\À À=˜ªcEOÓ{³´ëŸ–?ì†ÈK°5œªu¾TR§ûÒdJ›=dL‡&¹R(¼¤0÷-Á•Å¥ù6­•äm¿ÊÜ¨ã âı½Å4aß^Msdğ¾lô
ãJP-.ï¥mšAw*d‡c›}5ßÒ°¤?tèYEã¨x¦K¢¶cşµÜQÏËOŠôÚYË¡µ æIÓ«¥aúk#üÜ™“hXéÕ)¢yvğ	%gÁéêµ[H„¾äÃìnk»­R#ù`“ë[”)£Ôâ¿¨×)AØà!†*T3çËÏèì>rÊÓD²“ëá
‹´¸¹>„¸w9‘ªU³‚'2g”XfÊÆuNg	4vÏ8NFŒXüÌmbŒü£$¢<27ÍbsÄ99®‘ô‚5óĞa™Í?¦Ò¨âhèÌïhí|Í3KÉ›smscëÿ„ f”tkÏ  ˆa`ÄDMGyŸĞ¬‘«JQÜÃ{]\BË«‹µ–ŒYíÏönš‘b,Ù 5|á22@æÄkÌİ¸mHOĞÖÛ³3eê’‡Ö±	DÉËÒT½ôp4ó•‰…³ µ<FÍ*q½Å€5”%øıæPãyûSäsé„ú0PJ“{K5K·Ò†O
S;â§DW.ñ¾¤_‹Ûe’M6ï¤"Fıº¤¯ôõØ]À J»„wŠãæm•ãæŸõ÷ªO"d¼‹!hAšÛ­ÊÑzâ.{Rumó
O	à¬ª³ú(cµâ2÷à$’„ª­´¶¾«J/	Å€yü. ¨ëÜƒäGYEÚlW~3çª¤>Ë®Fæ±ÚqÍ´z6³xÇ4ÈA]C9ŒT?7–øHÛÇb)4xx¸“_Ÿ”,$áÅG?ô{İõhyÄ9—rJ›À&¸Â:ƒ"›š‚æ3\,TÎŠÉÒÛ&ÓŸXÆµú\?WóG‘éhû[¶â< ;{óDOÑJ¦õ¦7icüdM“!qEu%2 UÀÉdAİiêú¡-ßÇô"Dê"§Òp !¤åë£ÓÒ@ç†MüÑ—¼S?!¥zÌ_èlÄ8ª 9N°»áY¿d«arİ†Q-q{Õš_}ƒò¡q—z¶\Üî(yQód˜yS«ÖVšÓåq`@Ğ‚d‰‹„éAV|-O¢_]²;J»ø‹6 º@7ª‹X@•Ù§;&o¬Kc™˜ò(\"êó(ÕNñ¿œK¸95ÚÓ3=»(cw}ĞğÄêû†ºœ²ºÿT 35nÌO{5‹/Ï¦ÀXˆ'¶8N'_ˆê‹5JÕ¸@OëÂûCÄù÷‡ÜçèõC=¥6"&B±â”öxdâĞnÁÑÂºQÀ~oŞoh“šCe[ELÌKÜ*MÇa*>óÁ”mš¢â»Wõ$º9—|ìÓĞöÀ%x?Àš€Å”=İ6g }C»òOcµE-ÑrÂFöá¼J“ju
÷SZƒ@ä½4<«â¹8?[…],³Ÿ&*+Ş½-!eÛ>®÷J {xÀ—Åêéì0i|éUüLÏE)b>©Ö>ä‘Ú‡×ˆ‡75½r² B7Ø`°¦’ˆ¯Íq;ëùdô….`•ÔIG}ŒsöŸaÅØaĞ<r‹êpÜ²m;snEô°3ebYÏÃø8ÊEàŸ)*MŸ‹[08cZ0¿Ë4“#ºËŸÂë"j+.E@rï#úÂ|‰jÛåsß5yS‰4­^tãj€-+Ù‹çÓ^Ñ] ]_ ¸ÜÄ@“íYÁ6‚Øøµöç7âVCTåëAÛ©ÆùGé ³PÅD+°šNÂN4hÙ/ºÏŸøX`aFT<÷²Êö¹Ö‡5 šÅ%ØS[âUØıªÛÓuìãó£I×¦ø}\Xj®ñØ¢›ÿ3‘7JJíº8ú•}$ıÄ¨Û'OÆ€U‘ñXà[@ş­ëËMbúÙÌZÚşI{ğB6+Î=5¯$}®ySÒ°0=Vœ–[ZGŠÚu±ûM4b@Y•É[5 pÆ,ğÒ„˜'©ñ²nÈ=üéò¦Ò‹G$ù=²Osº^¨`Ş÷*òwïÀœôkC¼½r«Âd|G6º‰’çpçÙ88u	y¥=
ÌsÁZ;½8»YÃHÙµˆšKW¦üªò!6rætÉª=³ ¼*“ò‚«± ÉËzN›=i¬ŒÛú`å{è¢ns¾øİİãşÏ=vò÷İXšµ‘¸D)'O$%Öı€r‘jD¥÷Ë®ÃuyYÏÇ*eâr7)b‹]Ñ“Šq„~±›	CE»46ÆUıºúDË-nñU­v‰êÊ[Ä<lıIï‘±š¸zef(hY²§L2;…='‘07æª²éM8å¼íhU>[QÉàE¡×}a•xQÂR6€,Z^[|}‘…}ÎÎÿ¬ÔHõ™4¹ıÁ@•¢Äq%Z’û5~[S¡5í†}ÙšØ IªóéŠ({àQ©Û„ŞO&…D¿,Qhõ!O¸ğ’„Òy÷t-¾´“ÿ¥†,ıK:
‰Ãj
¯ï™qĞ¾"y9ii¸'%Ş£R2Iæ v¢•q#åòÁô.ÍªËìÅç Så8VU$&ØèÍ0^òı¡aır]sÆĞ¦+Éñ¯ëâ…ÙJCÃ¨·v@"×·ÏQèƒÒ·ùl…(î}l>,g µáá¢ìbUË¼Z(tzZ¯è.¦á_zŠ"ØoÒíüBu˜æe)Íõ€Äø.-!ºq™eÿz»ç&û%†~ïË“J´â7õ{ Ä'@œˆæèÒH7”óÓ )¨Ã©ùÅréÓ/Úìîà»
ï ®šÓÄ›[]‡ğ¤„BWR£4^8¶Ù‡ZCfz À¸72µ_dIÄ©RSÙ.Â¼…*(;ÓQ¸ºàNé($¥,´öJ©Ø|£›`ö3ÊÒqø(EV~4Ãáx]É˜a"ÏX®XÄ5dl;^îJ.aÖûÅ®—¯z¢gË¾¿Dˆ×)v¨´öË¯/[ŞIå&v»j¾Û5“’`Ê/>\ÿø$pø²%ÖLOc]MD¡Ø¹Åù‚ô’˜­Ø·Ç€Ò¨-=ğïƒ‡ 	÷yQL®¥ê2/A6¾`i>!4ˆª8jVG¨Äë#(øj(­B&ä¹@2éúÇö	ø‰4ÁíßXb4Û'9ÙĞp½¾É×¨×>ÙÂ¸[]`' e±5ãN *-Ë—¥'.ı%' W•IÓÁ¡«ÈáµšíZª†&¬UªüZé¶«ù½îcqóéEÎVFµ{ë–©Ş¨¬Æ'KÑv”M$¨ÎììÂF§Õ£ÿ5ìöä¿mFÒ„³CW]6}¤‘dRwí7•°)¥"ÅmÈ¥¬ÀªZt[×$lê,»dÑ¿
}ÛÌÅê²óz	}9å¼T@jÜ;6¯œBX°Iñ5–¯!"'ê™ƒ£Õ~ñC/Hâñ¼r0Ï“I&ä½}f‚²á^g‡$Ñ˜õhëü9éÕQi\2âªíF¸R—¸*¡Pvëe}*§V‚¡„Ô‹Kt¨¶5©Wb1Ò<ôK”¯ØVŒ´jÄhı+½…ômØ§=¾åCk¨¢]å¢NVsõß®œ°û€±r•\VŸ-È/òUûY	ªÎ/Øa_Ÿ´I­`nË	Y®ÖÃ–d‚;ÂL`Vªî¯µ"-z¼Ña®Ğ*X	÷.ü¸0víbYœ”xSw	A+Bf?¯[ŒÔ¯ˆù…‚0„uáÄ·«ª6AJÛaJó5Ï£)lˆ–3)pv{,SÅÒ6ıÖ-nzOöãÕHéÇªpzËú\QY·Ô<Éı’ó­óIM™Ô(/A#zy	ÿ™]l€*Ò–PdÙ ğñÆPëa…‡êî>Ä°H—ê‚gqÍº\œ:IÀ `Æ³ìŒåsúàA–J+NĞÔŸ7N&LƒrİÍ0¼îõ/ßOÀG	yß†#+ğôü«jòµà6]¤feÙ"•“bolÂe¡5ávğö©yjÕs.A¬İÛúß[5'‘îßäôH ÍƒÇÚôtÄ`ˆÌ‡ı²¶»%ñ$è•­Y±Y¨i|æÆ‰yş‰nZ9Ãklí“õ7á£ÉéÉ±1*=™âEd[à~¬×&¿	‚Œ<:M©hM¿– mËjæËˆÛ»2Ã®Ü–(ñ”ëˆGŞ·r3­H«ä~;³˜-ùZÑ´`O}Eƒ(£²r=åw%+n)[E#lš¨…UhJÁ(GiYU:¨‡ü‹#-İ9/I¸58ÙYìŠ%; Øí¼×ÕkñögØô•lmŞ1ÎÒhËÌK7ùsïZ§íÎph#æüÌd5z® ÖŞæ´çON_Ñ ïœŠ½½¢\»Èï”ózóŠ‹@×ª;Å›û#-¦†à¼ü"øö‡1|iJvEu.”ç÷ùu	k»›§y¼ìWB£L®…*²éÆÁÚØZzì ©/›Èé7WÚD¡~	`›3~|€•)NECüh­0&ÖmÔLß¯fû
ËP';Ò§AÇL…Ä(GÂ<HşÿÛL‚¸Åïj%˜]îÓ£=3õCLÓ,brS`¼ïU˜/³#uQğø¢ä¥¤!&Tk/¢%÷Oãrä“2V7€S±œN'Åd?!`ÛMì/‘Ëƒ¶<@ò UxxªF›P+©oüÛi°[÷(¤{T„„İúgè*­ín Z€[r?	¦Í$8=mEÆuTäòaS%€/È*•ä^H[ß•’fú[“ü>êùM`4b5U€©œMñ5‹=I)}õ*Uz¬[£KáúºZ-Y…tÕûÜÓ¶Ó¾/Èj©{±1Àr”ŠµTo¾kâÛÃ ÿÒº{\™¡C~lŠñ¹°ù}0Iœ#0à<+§¦>=P*ã™G63°å6$ÑÔWè şùO9Óº#É|‘M#Èê£jÄf6Ì‰=æ-i®]”…æ‡1ğÖV„™	šÃPjÆäLM~R!³ló˜ û™Zõí‰ğA7¶LnÓİ”ÊÊ ¯Ñfáª4‹ë÷4ˆúÿ8"ÃÉ*qpprÚıå®í«ÉzÆ” yÓìùÛ(p¡$qåó1R”3AÃ ëDÂ‘ù¾ı$¡øÎĞóßyá¢½¯È‚âğ¯~Ë!^OşF‚K—¯ñw×`œY‘§’—uO;î*ÉÊ­¦(œ!M"Ÿ_;Õvî*—„lœ†Á
¿L2š“¾o¤>§g6¶W£ƒìÎ/¹QGGÂa è´ûEÚEøÏîJ7,ÖEn(Û>6kôÙŞºØË&5Eã ”şAúš{ºğfÂX
¡+£$KŸ’ïòv:Í__=T£ha±Iƒ#“ |`Ö~D##¨ƒGDÀÂcï´	 pÿ_İÕ‘¯O5z·í_“}A>«°÷Rùïà
³V“˜h3ÆDìøg™ÈW™·ËF”)S€9XFº2r´çµ5¦±|,İ¨ùÌBÉ×¥²PµÅÒ?…¤=2Lw÷ìË4kWÈf$•Èúès?­ÑGwû¢¶†³È‘v0Á¢&j·»[Ï`Ãpÿ:0ñb)´ß%vd§µ<Ó‡BÖI@Á—ĞñÜlÑLgSe~s »Õ¾ÛdTtÁöÆÿ_A4úÄ‹³½Îª‡|¾dõ…¦±XE_ƒz–.¹Uˆ
GÈ2ô«Vœ¿‚Y'îã¾>Ç9ˆ!›È™fY;µ‹7¬¡æÂ¢ZX+„Öñ¡ 	HY1æıh¥NãtÁ(Ô¥E#/xİ‘x0^É,¢r¬(QØ×3©%l'4nS-Û„¨ñ„}¹»-Š`ëB½¾â:©n0 ºÕÔkòUˆR½ß²ú“õL’OB<˜¡:
S/@ø§ ˜ºÜuŠ‡“É/ñ¨L’=ªsĞt!Ç«¹º*ãE4cTI Ç^2glvê¨şKóİPÁıæ^ÄƒÇŞìw£lS¦¼aa<V¦ü|ÑYQĞpÀ”ŠnŸ‘ám››Ü¤œ²qëCYhFŞq5F'h˜İ»— üÏ¡AÔ%ï['_o¨õ«w	ø‚‡œ	ÖÖCöÊa³gÊ†I)Ø!ü5‚DÑ«Vj…ıæéÈØ{[M¯$–…Ê¨‡¦íÔTç	i7û§;W¥B“[İ¾4ˆ~/öKá9®•eÑ›÷Âºr½>²û¨Ï~OÙÇŞÏ)Ö‚8ˆ!¹]Ún‰š2â©gÏeÑõj=CÔiä%Èº#Ş*®ÀÕÏMÉÔ,Ô«ûEKAqAyÉ²àU²/ª64¼WhIÑGÿ0aÜWuUlñ†J	7‰¶÷¿|oLãü„ğ Îb(‹N^f¤ª]Ä%Œµ%FBÁÕG3Ü’Û´ÏÚLš ~âd§á-àãìâm/×¶@2'¨«¹ße´±`¡e¼ü*CO4}ã'§!
V#ıƒ½–ÁOM›³n’a
›ÖËò±$ÅaŠ/7ÖŒ¥C×·‘X›‘Ç¡œ¡»—»®Åïß_ÏÖf8•ÍSÍ*R¢f(Vè›ë ñØR³ĞøätÁı`ùá÷éôáÍ­ÚjO§¢òÔÚ‡„ÂI-w¡ßç?ù.l‰¸;˜Ö­‚<c‹ÎÏË7&EÒåöh<¸ºÙ¯ÿùQßø¬KQˆQ~—¶Îl“úöÀËg‹+PæßåÙ©¸$´È_u›ßÓW:sïÇîJƒ·»†™ƒ6_iRfÂ[,~<wæ²ŠQÊûsmx[$‹$¥´nËïÜšo^ø›Ô®«¿OÛÈv²ÌGrk;Ú{x½5mpŞŸ5Ä†ğö‡5ÚSGoT­}ºRÈíÒÙ[ö†¾ƒÍß7ì§ènƒ(§ôŒ˜xd;¯îp™'ÚFâ“30¹.¥1yp`äCMIÌ^V‘-ğjR¯i¼ ˜×:#tİÇIîø‹Ïˆ\n³®NT‹kÕ¹-QÉQ{è:Õ(“ºt%ò•7àt"	à-4•Ën¤àS‹5ÎZhŠÇK„²qîLÂ–¸òå-#g¼ÇûœR/jœPİIoËQéûJG±EŒ´î;q±ÓFœÆ£$àB¡'"Rµïöú×Ğ
ÄRC×¿~€hşƒ³Š’Ã
~w-ò°eı»7½¶zò[.ˆèÅ\ƒ9®/ÅÉDå—ô71²9bóAŒ:©m%öºİşÉ©sGèóÁ2J/5(m/¨½” ¿õˆë,ôó‚ˆJ¹í+,aPv‡}…3]­ÉUßÖœªÌs;c¿Tµ×ğ©F^UÕn`FU*Iƒe^Â ï´t(•æ&= ÷ ˆ’šË„I#ñœC1SİUÍ 2°TÚU÷\hÙşÑ
¦"¡»™28º«ZˆÀğj²RrÖÁLMD®(X»B>ë(…é
¼¡¶Ç‡eÍ‰ìyï:¨íº†xv¡aÍVwé .ZƒY¨&|³s%bštÓ‘v¨4^^é9ÿ°§Ÿõ¿Í¿jµ’y`&§R¯íõOõİµoDX¥Ø>!*dS<º€”Õñ…2Ië@o:æD{!œã"Y}éusªç„°ÕdpÅû©Ìò:²Š‡Ù“RÑ˜›7½L+Êd—„fÂR¦ÜÔB{¼Q¿<çlÃ“}¡I$Cí‘48Ë¥:ÂÎş
Z'»:ªğß|ÇÜ¬‹5–Ö\ğ]æÓæ6ü%¼¢²Ğ¤¸hwbñ„%x£Ã .zÒŸ™Îm¯Q¶ıs_ëBº”Æs(°¶ëÿ™/Ïò™Ó‘}‘d±˜À	çi"««ô€>ô-%ü´ÿóZŠÌ–.T$C»—6™:m>ô¥üê"V‚ÿóœJÇx$³*»
'•|B*W‰ÄE©É¶ºd4ü ¶´TŞ?˜½Şo9yñ»˜›Ìj8CDY7¯*ÂY7chÏ3ö†?ÉKAÆÔä1'à¦WT»eIÒU°èİwğ_î68HC]^wæQjî½çwÂO¬ÿwÊ£–Rµ*-¨kb7úIÑO78ô™Âòô+í‘qî®>e5…1tdÊ!°ƒ;”ó¿‰	lú±Ğdà¼ÇlÜŸFCó¾kã£²8jÃ¥EÌ à›3Ù-}Bœw¦„¤“ƒxYòšı¯ÒÕ2ü™	’wtÏ‡©©¯†{§­R?ÔåG çğ’xäERÙP6,ë…Õ7ÖWÕÓ¿ğ¨·†øX5ıå«­ŠÖªtV®Šò2öAh¤äì<é­'‘¹©Vñótƒ·Ù[¯¾¶öÑ\^!kÜ+ÏÿÚ$ËÆÒbxê)òçÖÃ„ ‚*e¶¨µBª.vuÿ8¸Rvr;G”Õ8[ gâãcÊX*P
ø¬¹÷[ïnSÕu‚îg÷àöI(ç¨ÕRşbŞnW=™©qùŞtßËÄÁoï€üQƒÆàzjsÃu§™rç¡Û¶”cÚ‡uÊ¡µ
ÖÂ.ª§‹}s…‰–·Î•ï3Ì°HìæIH.ùŠ;¬äs¥­MÚd”óp=_Ïõö²Jó¤ ù¡=¶‹šRô»vùîÏÅã"˜!3¥~	Ğu®r7Â”–+>ÅLõVöäşsõ„Áô
ƒút:œÂ—s“÷½ØÈ7ŒóU£P$ÔÎùÉé6IïZ‹ANùš5°æ{n+gZ«¦6ı‡)Ç­Yò¯q®XÂú“AVÕ•ÿLb»Ã¥R½ïC%l£¢ãHõÓ-G<Š&BGô‡ù•nÆ« ûkà*<J²Â£ü3ULçÃ‘ëææÀ¾{üIø=knÚgTBß­"Á[/4hSt´¡(ø¼§ñN5A½Vüí_ì*îRéßúíWy~äù<.tªCî7x|=M`òE‰åì,[èÔ³÷y¾2šùíq[%Ş°ùöìÈƒÕàüÆViseñß!o¹:Ÿgh æ””³`S$.io9;×†k˜VM›Bp3J¶™g²—öNéSWşpkÑÃ²zÇ6^™ˆ#NÒC$•…ìbÀÜŠ7¶9õ§ã]¬sX½zyª5*Ú Ù4ùÁ#_³qÏŸÒÅ†³¶_GoOBRn`Ãà;}#Ú‹¡Åëáª:5ãÍmH†£Œñ[ÅŒ½(ÀÌC8Ì‰–Á
KxZÜã§tL]ŠŸ2qg^¡ kò¥^2OŒ¦¾p¢Û!>Í‘a¨rO% õ¦NvG®Â95Ô’VÙŞ†®Å¼ÓãÆV÷Ş»øZÚõ±Û§iËúËûŸË!¿`f(€š¾å.úe(ú™7Ğd3Ê F[[K¦Mú2©(qF8œåJ­6Ï/Ça†œ½àH\9HKŠOíßzÂç-¶œY2ÈåúoGŸ3‹á7¬¬WJ(İ}În+?„¤èé²ki%	’&ÿü‚dÖ]i)%©e9jÎKº8åAİx«Çß<y)]Û‹IN¹äæ—2v€&kö†§Š{·¨ò·½ûXm¬Z\µÆÀ­º~[¦gjŸÔš¶Vä4¢ı¢¡_5O(†‡n¨úš’›ä~úL`0Œ<ş1¶_u_(¥øt¤bÉvhş3õÀ+B¢oşÓ¹F“k?Zúo½I¢!'?¿êfèšA‹ÔâB<´ƒ;Æ´øgOcq…’àéÑ2ÄVØÓb½wizÏ¼,èŒ‚C#`ã ‘`Ï£"à¬’ZñÏ€Y:•ÙÌ°•¦àüÑÔğ^œHÌàêé\Úìö‹ï`/“açWz”
û—ıİKœjï€ä^Ø˜XHôLãÅ ŸwSy]Wo6Ú(1#„Øb4œ,ş3··jt)†×–PßÜ!M±pn9
¸kq³ß.êß‹jı¨ı!…Ë»
·NæÜ´´Âœ®ö[ÃúÏ¸Ş0$œ>QÙ^~Îp®ÃK?XzT”ı¸ÏRMŒÏqæt;Úg¬+ø@SÑSB	Gm×ÚÎ&Mãš²¨æ¹¢ñÉ4}\{ıaòmJ’P\gíèpJF¾!ãÒoíd÷[.¹ıØ²«•pÊU¹ñ+‡o„^0¢„›‡b7~<³Jj-àFÑ£¯µÎ-ê·q»wjš–oüçs°>¢º:ÍºŞ—\ë ß1ÚooÄÙ–ù¿kƒY<‚ŠzDYº‘±¶:*p¹j–y‘5BÄáéÁ{Má™el*Ó|NñÎo )¢Ò@^PîÃ9¯@ıå*àÊS&
5##•êªC^÷ˆÑ‹4¨ }ğã2OËtábFE‘à¾<Ï æaÎ|\Øã/e—]§¤õ×9Ír.ŒÉ­(Z¹v€òÄAfç/I}^o4ÇMî*mecXş3ø…(íš‰`w'V0RQ‡…Ê”µTêaö.'=MÔİãN|T«6…«–wUÖ©µ¦¨0f¤ ï”ĞR «ı¹"tML:ÎQ¾gîÅÀQûğ´¤9}“•ÍËNàf¹Í¶½´´3l'Õ[¬LÍÛT!b Pg+QŒ™ÈÕùiĞ} ¬[€ÚİÁ'ãåIKCüÍ]DÄ·;írh*‰„t"*¡^\+/mâ_—ˆPbïê	8ğSÕhéD—©¦é:c­s§[B®2ì+°(æ=îòø#Åªçàlgş,´Wµ;A’:zI€zŠ“Ø –ÖU•MÙL Eš{sURÙ­qµ´}	®Î›A ¢µ6&÷1ßPp\œháÄq˜NnæEîá¡%PX¯)©Ë2¨s FÔ·Şï ÷Åö3TÕfÄ8È´&FâS•A‘fV›	òcé›HÏW¡çâjØaá«;OøómÀèèüôÈ0N|´˜ÊæÎÑ$sËCI®œÑ¯åL8³Û1frUÔLÙÂ³¯¹;Åü·Z¾{iuÏsû^;w¤—W²ÈñÊ5C6"õiÉN˜ Í¸OwC¢]ÖÒ÷·SÌñ!b¢¡>Îy.7/ædÃ¤ãWiO°âùÂÈ!5xq`ázxyÄtT&B4Ë·HËµ hIö½ß‹00$Ó2œÈ7P<â=Ú„¸©ßBå5«fFßBÂÊÔ³‚¶Õ)[bkĞÏÙ¹Êš¡¨ÙhU2Gßdw61ı'Èy¥¨-’·F¼ê6.oã¡ä,%šHg¡F¸~7 ı§ÒDR,îJÒ{ª4
öFÜ«¶'¿Êÿ7Ğ6Ó “ğT‚ºl =)Bßï/Q~c6ê…x{}Ø´ìbü0÷èC§øµc8àpHå‡7—îİo¹ÒM¤”oPÒ‘"€XE‰ŠıÙR|·[<I™mI‚fùRöŞ°İïÒîqUïÕ)9Â$æ‚şæÍ%ıúÒ…¾ÛÕt)¡j«=‹¶ÅÜô­“@Nå%¨rykÕ8•Ša ¨¯¦bs13¢zæuÚ’Æ¯É³íuUÆ{°&`ÿM¶ qÈúFøB…m,RäºJRKaØzªäÃb]òµ.ÙL Ÿpí¹!©]8Â‹N1ùß“¨–]Íe…Lİªs)ğÉE%­ù9í©
@­wªR²ÏY1tÉÄ«Ï—ÑY¼ê¢t»§|!tBœ¿ôæÓãUå¼›ß÷?ÅpàÄk©P(ÂSå«úe½Ä!œ«×Ç"‚³W+ÜÇô ?y’LàúoØİìEæ›´Éñ_ghËï¿]_mÅ!N\© ¥ôÕ¿SQË…ª k§§„¤‡Ï<NY/À%\4¢j	Ù‡±xl€o¡»ùO1üIÍ-¶4D§tmÍJz¥Ï06Yuié	Z­İªßE®õ«<À¢9€`©B¿lSÙË©(=f{XµK7°“@•Æ¹5/´|–Œ¡‹Ê™•»£êÛC–<±èé9€ñã¸*ÒÚ,)öhéCáÜÓ¿ÒÃŸqæĞn¢óŸIzƒ
NÌ=D5Aòo\‚>„1‹np"Î°Àü„>U {¯k+Åšy&Æ§Ó’ñÈ=u^X´¾ı\'!XÙl²QŠÁŠ´’	¯9†â\£a˜ ’Ç€Œp:ÈûO+ˆğüšª>‘ÿ‰õÅ4Ü­SmÄGöáµjò*!—İ|,Çà÷É.ŞçfLm[O:İAŠJm1‹%Ô~Å {«Ê´á	 v1nSTM¤‘ó	€YMÃ^˜Yëxº|øº¬ÚZ3ó¡ tU;‰N³G`´ÙçÙDH$–œƒ·î˜I²Ã“³6¯/‘š´FTïÜè>pßZá¥€Ş|WWe:”ƒ™D¥*ÿqqA}22BLÍËƒå¹»â7‡Râá›š{vC²>2|Á(‡Ù¦iêRâÚ¸2« V¡Æ@Qºì».ìíózB›<•„ÊŞ’’m"na*ãYW)´K 0Ş-Æšjœ¼‡¸FÇOHï#yßªYZ‹{£ú'âİvëEã»„„]YŞNa4-tc¥£Î¾°WĞt^çé+~ÜÙ+ìÛÀ©¥0]Q®Ûı‚’¢S3Fº#ğ1Ë‰nÇÃD»ˆAo¡€††n•¥f­F“0Mr}ù9¾ô‡Œt„¡Òó^ù œfÇYæšrÏí.;™šÃXAA“üE]íè>€6…ÑêºêíBÄ	@Y8*½˜—R`ı^4†ûãæ^Äô·ôeeºÅk<‚wòæÛŸ\ôŸ=ûÇ@p^é?)íå
…ğa&'ªÅ°L
ÒRsİ!Úş/Ç½3à³¾úkRcòc“:ÈÌqÀ¾¾Ü/Ú¬KÅ€4¿lqï‡6l|)"'ß¡ûQV÷%5y°š©Dú¿Ã.‰U#i}h“Å5ÿA¾ö\›X+ıŠ)HQ Û×P«z‹øJ1óòÃ\Xuv:‹Mµ9âBÎfÕ~í3Â/1µÈDñÂË3¼ò'WN‚İ‰a{[Ğ…ÜÀØ$k‘ÎGT(š‘ñe¾_[å#¹’,Òñ†ókãRu[§Z¤€XF–(—é×Iél{€k¹˜,÷2ä;{Æ¿:óÉ•ÉÓvo)åŸë|3EÑÉĞ(ÀÌuµUõÃMPI‰ “+„½!&œÜ;·´×R&ÏÁ˜)Æt7BŸŸ¥`Ğ ;õ?‰ÕÉ1JòŞ•ƒâS=›ë¶!;-13°Sf`–©÷E¨Õ<–çCnJ*’~JXnó„W3Q ±f36¨›úm‡eí“H“ “&a‹	!¼†ñV¾]Â’ H©Í@kö€ß»ä\cÔgàHå¬‹/€-77Ú·,°$aÆ®ÌvÿÓ;ÔRûTùâÚÛ×^ÖT©4Á×—hJ#’Yì­Àrpâ§Pô9%#à&Fq5g-š0Ë½o­“Î­©Á·µ¯¨v:¥ùH„š‰¶#ÏöÑÂ«!Z®#,Z òÖÅ‚hx6wR·HC“³TcßO³ÔSlØV4÷¦¨õ“ìøTg­Ñÿ,S™·TôsÁû„êö\rìÄÊô%sY¼PxÆp6G?ÚDîğ†)í÷Âà/Ò0C`¬€®ËĞ4oË.Dtôæ<sÃpT†Ä&#ìGš•‚wZ’ ì´”ùÓş‚TTÈ:ÆH`”[¥BŠF«Â˜ï’ô83¦“·‚WÕ¯Şšoãwa@iNÒ@•p=‡ê™RòÒ¿˜N"ĞKœñ-T5Y|]ÌšZ{ÓAÌ¬œ¥G?T9iÆ}#ñâûÌ®ÌOPºÎ`‘BøŸÌ4Û9~ÄAGÆ_³8¡¨X"Ä’y®Yµá‘{nÊk$ŞÉ9¸÷šœhòæ,ø%w‘dà‘©WÛãqaäYÅëã¿têqğÀ2Ÿ©Ãj¢-4:öš™GÇèUijóÒ™p/†hFåJ—×Ó´ú½Ñ>
a:Í6N¦û%cî®KúÇbµ(†Âğ÷ñ2£Ñ?¹­²ÇøNËëÑŞñü¯S¤~#İâ¨HˆWÙÏHò;ö¹ÍÇ‡ÎD|ñõ•˜óŸ‰¶jMÄ€|‚æ‹÷ŞÙm…%{,T¦›&NùtÅyëø—½™hš¨N¥âKA«p¤¹n>ô”)Äù!@©Qo·î^(åKq•kñN¼H¾†åœ"ŒÊYšËdNõxõx!™=ñ^0×#?` ü<ê2¼£?)æn`EµêuD‚J48å¯óL³Aosr°Å"=ƒ“S¼_“½RItšº3/L aFBµZÙğl<î’O²cgKñ.ÖLì]­ÅjŸË0kî?`ìVÚeÊş	¶Lã-G™Ê®!µ‘u†îqp•0ÍİXñfhóØ^²©°©d]@óAÜr÷„}wúVt¨Ä7Ha86ÀÀ•4ÿ¹Å´Ày]Jî‰ÊZí§Tì]ñßö¦(ú3û¾…ät9Çı|åşœ:È@ÎMà›µßĞê#xvGõ.çyC†Oÿ…uSŞb=Ğ¤ ÜPŠ)÷çÚ¯•kJÜépëG1ÒÇ®]ÑÔåSÆÖ'ØĞlËŠ*5OAÍ§#áª8J4Ümt=aàçÑ`ZÈdIRñŸ“Ùyæ ÷öÒ=¾vK×«SÅfGËªôøœìonån Ü¿¡–Èz“ œs”—}&'İ¶^ğZƒ>%ŒbêDaoè™#ıËò:xÎw¡ÃÌäŸ	œ(2c“"tÁ<}l{™£ñÂPÉùy&55²Z¢h0˜£*Ã NümËª¿eqš;†aÄ™“'šï|“â×2Àêyp’ÈËF5¦š*<ßıçË«qò'ûg±ÅGğÑDw ©F*†¢~7éÉ—sbÉx^^sƒ¿ØÛö£ª”-øóŠ™_Ì¿B‰×k±- ı¤	,”4ÎÓ7Œnªèª¬•ÁèGó”õ(ø=ĞÖ-1L:`p¢`Î_òzÆ[ïülİÁ7Öcú}‡újèJı†W"¨A¹ÛEè¯lá·{óeAçŒ¹„)02ªùŸ"AiÄ˜ \ï‹Y9@gÄÍRË‘ü(táŒEßWYßâp<	ij‰$µ©u‰â>äG˜wı$£öĞ¤„ o¦õ)§¿Åë¥„*#Hám SÊ¡LáÏã3z­<8NWæE¥¹ ¤†©şêmçê=Œ~EpbôÉùº?v
’€Û©éÇu])ªêë€k‹v'©HmË»‰¶ØÄØ¥ÒQ6ÿç•ëƒù¥y ş&†ìßèWxaè"Ûz%eQéÇXõUnÿ T;F"s½fõFÁH<.şl†°èâë’†Æì¤ESû&¯÷ToA]®ç]Ş«³Åóá‹'TñdˆåÇQ¥‹İŞm])¹éÿ¤Ú…iƒè/‘¶ó™ö¡%ªÌ^aÎwíÖ£· º‘-Y‚!_ùYP‡WfÃçå!e\ùÜh²u6İŸ‚L>hÊõ££.Û1ŒàrHJ–\ĞÖ@¼ræbÁ˜¢igN$ºŒVLóÔ£{WğÿMZ&Úã-t±94™àZU1İ›ÎC…2Æi*Aòı‹kìv¶Ü‹`pÓà¨ãÏ9ÒƒœÁe÷·T[í^vR.dä oï/wİsık]êPµ9ÜÀ5Ç#±¬ŞÓyTM¯©WÒ‡*È­ƒUŒNØ8âñ–&ˆ^q–©|ÔÉãlêŞÈç1//§öm±e÷‘àı‰Ğ÷u¤N[õ°°OÁÚvM‰¡QÅÕ!×+»İ¨hGÌó”ĞDÂÍ–M_ÇÇÚêo¼i3³‘#ŒZ‚~bfœ0ª‡E ªİÃ
ÈÀŸviÉ¹·f5Ã&ğWÖ5Ÿb¨m¿¥…æÈ‰úc;YZ¹ÛæÁÆ¤ Ş®r9Ó@œ-ø:Ï*\IÁdğÃoı@mL¬N ›£èEÏˆºÅµ~¨]czäô9jÀ0IõàÌHştñ">[ª>|Ü~øÈ#ÁÖ›(ßšŒhd‡¿]2ªñ¼ÖBš®ÉÍv³&ºú¾D¬w­ñÎ£øÖKÓb}¾ôsº¢€}Òì;ó>„bŞ±¼ôA]`&œ`ú ¬²aÛr}zü³¦Ëõ´Í“¾#+N]¬;:×À®T4QyC$7V~Š!qq×HÀ„Á™7•
6ØZ…ØQ’×Ä†üºw‹ƒc“»'PŠ8Ê^›S,òrë¾Ø¼ñĞ mãÕÃ'ÙycU >?Á×èàòá+~+ı–Ğ­3Ä}(ùy¼/KxHeäÆÊ½ã¾(D‘èl¼jù˜ôGuãÑ8p²ây‚D€Óë‘÷åW Ï:9ÿ{ãŞÄ‡îóTØŒXA’ÂDMAÓEí"/U.À…––—Aîrc±$5üì‹Qî «ğ=a@Ñ¾º
ÚÉ)¨zù
¯½ß‡° äx‹‹në¦‚¨Lö•—Oˆx/fWeh¶o†GYÙOk_µ2<\õâ4nñY!=¼O®üG;)—©Úß|hùîıû¶³ºÂ’ı‹•wÙ“:“¥¹©ŸÍËcZåÈ¼È‡İÊ2*yâJÖ•İ¦K¶¿Pû‚Çé>"GßéäØamÅ!z •ìN ¥Ì+põ.r£!ã ç‰´f|öìß¿q:Mly™±¿C	u·`İ¢SDãI¶~œ]¾asVlF¼     ²8êÜÖ%Ä ´€ÀC+ˆ±Ägû    YZ