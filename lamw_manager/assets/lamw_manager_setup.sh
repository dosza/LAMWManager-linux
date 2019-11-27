#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1621004791"
MD5="26103e3ff7dfccf68fa1fcea47bcfa4a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21128"
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
	echo Date of packaging: Tue Nov 26 22:13:04 -03 2019
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
‹  Íİ]ì<ÛvÛ8’y¿M©ãtSô-N·İìYY–µ/ÒJr’$G‡!™1ErR¶Ûãù—9û00ŸÛ*€¢l'İÉÌÎZ–
…Bİº®?ùâŸ5ø¼xş¿×_<_“¿“Ï“õÍçÛ/6·¶·· }}mcóùòüÉWøD,4BX¦ë^ßw_ÿÿÑO]wÌÙåpfºæ”ÿ’ıßÚÜz^ØÿíÍ'díqÿ¿ø§ú>²]}d²s¥ª}éOU©¹öœÌ¶L‹’	µh`:~˜¡G1<m83[h°ªT›^0ºCúc›ºcJšŞÌ K©¾BD»CÖê›õM¥º#vÈúš¾ş\ßX[ÿZ(¶"ÔàœU–v•ØŒøfoBBè{ÅßÇ“×0=ª“Á9€	48À$—éû4 / *á:¤Ù.ˆ’SgçêWá¤B¯|hßoíkÉc£wØ7ÔÚ35iÀÅO{ÃöiĞ8>6H4Á›^ËPÓö³~kØ=j½i5³¹Z§ƒVo8è[oÚƒ¬¹	³÷ı—†Šr•¢@¨!Ğ08ë°R=¤@½Ğqè×E¾Ã6T±'ä-Ñ`ßjİ×ûz­¸•¼ßÅs•J9ù8æw]Q[[Öq“{ş6g'Ÿİeb+ËY\Ë.!\a Õ Ì@¾5co6ó\S¾5
Š±Cø†y ;mQ¦@Ó€ÎüÛ¡ìéêQ*	¯ôpæëyèúØs'À+d	fËAvaU·0aóœ/`¬Á¾÷„Ø³ÈòÈŒÎF°9
8c4h³>´Jel†D§áXŸ^ä“¿’i@}1,ş-°ıLt‹Îu7rœ˜êÚŸÈ7YKvSY»u¥"¨ãs8æ”ñi]zÙĞÉpÀüu@áçíZFmvx|î¡n¨	-j-QË)*'(f=kã:W»Á/]OÑê·¤
à3`1	=Ë2âÁ`ÆløVO(oº²Œï¼ƒ *d>MQ¦4Üujìóe2œAÖ3M¨,ªa-ıM´+5­¹y¢øv=µèÄŒœpUF¶Ã¼S³‰„O-QÊÚ³T©d¯ıié¬]Ï±AìPÌÏvÈçô/èêÎÉ~»ß=nüjÔâäMãlğ²Ók -ûM>Ÿ>ÁURËY¶"{¹0ùe¨G»Kè•’z½®îÔ´R¿N\EäÑ	!hqı¸b¾ÒXJQG¸H.QR¥’IB"™šˆ•¸)–ÍMa%İVŞ;3m7¥TÁ'NV›¡÷</,¸O¥’ib,°j,Ğù>‰:5Qæ<Dß*Ì`2;£ å„+²R‘M ,€“Ëá[Q“6–<yü,ÿÁ‡¶;%}ˆƒCjÕÃ«ğÄÿÛ[[Kó¿…øóÅö‹Çøÿk|^z—h“"Fs6iG©¬“hS¡ÉÊ¯(•Gâø‘ı6Œ]L×‚ñ•|j)D¾1:À¿>IÀK¡ó«é ~Aîß“ÿ¯ollôk}íQÿÿ3óÿj•^¶ûä }Ü"ğQ[ç¤1hcÄö+ivNÚ‡g½Ö>]ç£$éEdf^sñ¢Â›GaÁõ÷dÏ¦™$Ä>™y–=±!'`†ñq#J…õ|Y`1¿÷Í€‰¨NVŠ!á‘_"W©ÊCâŸhšmQÇÙ2
˜Lî\gæeÔ™3˜FH<#“À›@×tbd¢c:Ù!çaè³]O†ÕmOÿ:E%«ÈYÍ;íù+G–_ù¦ËxD{n&L`¼Š2±›3G<Ó¡À™:y§†ıÀ{ÓçuMÉ[ı8°{´Ê_Óşó’Ã¿Yı}}û±şÿ5÷Œ…WmÙEƒ:;ÿŠñ?löÖ‚ÿßxñèÿëÿŸYÿ_×76—Õÿ‹‚şÀ3€\0öÜĞ„Ô‡pdø¶ƒùw@¦Ô¥;H !Ší‚_Ä£‚Fïdş‚è¤Ñè5_noi¤áZg[_É±+U‹†tš£à|üX™øã83-“¸é6	ÖM,ËÍ?ş=°Í¹My±Òœl,x)<@:è6±î\Q*7Æ=´Y8œ ŒÚÓ´l3ÑºKÃU,3,ä§pÀz^X}¦"7ŒÈúuõ ¦L,]z9Œ8ÀĞ	/»îîòaÇ¶]‘ˆ¡ÈúI™9VRrÖ326ëkõµ<³Şñj¨IDÆæn}Pˆì Šqê^0Å&¸¨‡æ”éu( n×†kª„	°Û{ÃncğÒPõˆºcp ‡ªJ`ÍƒÃy '­>L‹({­ãV£ß2Ô;'~ÕêõÛS#^âƒÈÒkÒH5ã:¢Øú¹´õ %mİ¹$èÅîô$YÆÕÛCĞ4E›ºÑÂºÒ•‹HAiæÊ‹ša¥ÇSˆ?®ç¦@¨üà¢KÉëØ÷ÄöÔ?ş4
3€‹ÎyÊhF€àÂìÙèã?{ìñ¹+On´ 7Œ÷LlşE—hìîÅ/şt9HjÈ%ü^Æ^±€Ï˜*^ÿ+é®„éäÕ¥õ¦fçòÜŸ#·g *šŒm5®”«µÜ •DUÏNÊ19ª-›êas=lˆ×/ŠôJ•g¼éy÷d\T!ß¥B~z¡,Âá	¡€“Åé½³Ó#’òÂbµHV´úš6× ¦`ÃE¸ÚÍBÛ·ï´g·9ÔñQLöçv7>2İ:nŸ½¾ìœ´¸`°s¢SX@:$ÌıW§ƒÆá-7%3ŞÖå½ªƒ>Ö§¿©%«K±túT.oz[‚6b¹.Å¡Q=%¬[hÊ“œ9†Úâ
ĞØCÄCº8„T–h.V /^,L „bÂÃe›šç4‚™8å=7İ)ÍÎí*v‹”@JÖ]©`mƒŒÁÂ£÷8–“ù¤¶Lšİ³á Ñ;l,`§;0TÍB\@bëX%~Ú/"*Òìuú}ØôêÕ‹Ñš“WİW›*I„¯Ûk´ß¸3Á…*_nÌ ®Ê(nIU¤’İIÄ±sÖk¶G%/r`É½Vl4~ƒ¿Ù~ÂµÛ²’î½ï¯¶¹,;Oç¶F.Ş€`Ó^vnLÀEZAà;ä Ğ2iÿ5Y}j7§ŞIãøV%ÂjÙpÅV©d‰%‚¯¦Ç¦µRíW1´@§©ıv5Ÿ,…ª$ëËØ¿$ŸÙW@^–ÁåÌjõ@: lá:HT°ËºĞÆçÛ[¥úğCV²İÒn?@L>‰äçµãåÁ‚´—Qw—@-½Ÿñ y*š”$ãÑcf‚¥db…›r/3¾´MøT.U?mûä{¶‘#9ÙsAó|ëA4Ç·ş°Mä!ÙDT¥[Ø„™Ã4¶Øó¼°¦Ï•-¹@ÈğBƒ=„Tâö¦Ô&]u98n:h4§û½N{ËQáÎƒŒSñ$dÍÍ–¨¾Djxâìj—ÀÛ?‡œœç3BRúrŞ–ÄVåË#	±»ºY6®TúÅ¤k/Ì)w¿uĞ8;À7Jmó(IØm×¢WüÒK’ÚôßÖxßûÛO^k. L8üXeÿ·¯ÿòkFLÜaµlpeXøîúïÖöbıÿùöÚãıïÿÇõß–~5Ó™™`ı—¤Àµø¼±DâXîQæ{.³Gåµ]zsuñ˜x¸¬„×Õêõ¯Ãí’bÃo‡69‡A4¥W²L~×’Î©ãùü ı‡ô:Áû3'øâµÄ%ô÷äàbv˜‰æç ¸Oà£Óáü~&^zQK=‰‡2¯"0-L¼5¹J¨ï1ÜeïQN¦%H§äîùq%yˆJ~æûç#è©k‚Ø4ö÷BïÌ¢sÎMBüÀvÃ	YéŸíõíZ'†¡Fl¤~OƒAïÆ¶^Q×ò‚[hşéUët¿ÓûúN:û-C]ÛŞŞ†‡Ã^ç¬k¨¾M¯úÎ]!ä¯²Q*ŠñŞq"?K¾®Å”ÖyÒÀh0Çk¸H^Æâq1«r¡XÚ4ƒ¿DöÜCNÅüã?äºçc’… ä®¨¤*‹Ÿ\‘3Ş|õh+G}3<7–,5/U¹œT„.‰E±‡<€•Ï€lQ5NWCØú!hšñiR«íX;‰5B•Û A€Z4¥)Jòç)âé•ü€Øo×#ãİ¤æÈÖâî§–*­îZºï˜!˜«Óch­:™,^ÇmÒ cÂÍ1ü¶œ:óxCÜ¸_Àz¹0ä;z9Q[õu? h„B]t‹*C\«TV´ƒ(¿5ğg.Œ¼	b¼ÄrJÃ•O¡?ûŒ1Aè¬ˆ]¥k¨…ß«Š’ÕÁ¢Hb[Hª YxCŒHr¢#,B¥Â¸nÛ.µ]¼È\ÀÉ™$Do×ŞóD+/<åŠ»QgÒ3šÜƒYßzvDAÆ&¸X¡¹ ¸°axî‡
O?˜™[âà¡I†k!qWSúT¢JÔ©„¤Åú¸Zİ°,°.è½nà¡óã&D,À-ñ±aÑrcPŒy±É Ôbf¬ñ€T‰>c%©òÚ.şİ©öûÇ-DnøÕvÁæ…“ü%¢{é^àN$ïH¤Ä¨!ˆ‡¼(€ô•ÅİVk2Té9]Jü.Kaé|·¥½ÎõŠWWH1ÏOŞV‰½1ÒiÔä'ğb?²tòh$n2k9’{p”íL-5(+Ÿ‰±¸ßw¢áF¾IÎÈe4•Â&äÕ…xQ™ k„­&¾ä1‚ÒåS<Ç”
Á€	£÷¯ñ™»Ì 8À÷0ø1£W\ŒRíD`i>˜IÄ"3°=¢
®iî½ˆä/5’§#ÀÇ°2³ªˆJfçÒ¥AÃqÒHOz®s_ßÖC"}ÕB VVr‡°1—nìøDuj(ÊSÈ.4"ÂšJ<vÌßb—1ó,K.íßÌ övbµíı˜ÁğøçFï¬/yì·„1N
)K©H§Šqæ¬™4M©î—õ¦z^Ö¯eI/'RT†Õ{yTá9/‡¯¢?F‹+tòŒ8!I¢z¼»ï%ä)OŸÚÆÚ®ıSí¦*1çí³÷·»öwß­¹ÑO„^2˜ışV°x£$„;ÙO¢õÇÆw{Še­ËÀñFî”Kdú.ÂÛÓ±7m‹FÉe ¿‰µ!GnŸ\ªZ@”;xSb‹ &å*”¦œz(.ù½LOÒƒ¼²V~z¢¶İ‰·ƒ{ªŠr-ÆA;ÅÒmÚO.½à‚ùæ˜ÆÌ}İéõ!nepq=–€£•Í³.ÄŒIÿi¾ÌÙ;÷¼¼Cs–‹ãìï¥¬Í¨ÄÄ§ƒlÅÒïŒ1¦ıùg‚¡ç Ó9îgPMğt_:#•x§|¤&mjÌCa#¤‘FQ,&ÃşY·ÛéŒ;DI;ÉeSC“¸S{Š_«Ğáká ™Š…ùÜ»× Vjüb],ajzWá´3hü:ìC¸)n|S¸BP„ ğ"öÎ½C¾Dg&\d‡”‰×;w¹le}”+˜³s¸s?/RgÄ¿g99{)®š§@ÿŠÅ½sùË·`³yl Ñ1É–…ÙäŒºÁ¨›C¿“wmÅ’Ë®D7}ßIß{H£Àê˜Èà
r½GØ7ÂÀÈA”rNƒïñıc¢ÈXXÈò¥œ‡N,œÒ)Ù3ªû¢>ÀJë.-æÍÙm‹²‹Ğóy„ğ·û¢™´ğå‘÷"wQOÍ5²-QSSo‹]„¨¶®è8wôZ(r7M	™Áµ&2*'&å>O¡Ê¢^ƒÁel9)Aí1º¬<L«×mèb<Š
"6ôèêĞÈÇh0³]Ó1&&h˜hºö©ÑÈö-fC$eÊcCªîÂl»‹Òp!8íµ×ö¸¸+ì>®)ò_Ÿ4“±"»O`;9Y!½
õ+MÜ!ÜåOñÂ€±ŞaMü…ò>ÛÅJ‡ +€Íù–€–""UÚˆå‹|ÏØ³(Lê˜×b•GôlÅQ[ŞíŠu ‡JãGpX»‚;»y&½…lÙ‡Lózgçv´ßÒNa)sÚº
)ïæ}¶ÿİ1äã¯L'¢F˜Æßhân­†oùµÚ¾‡¯I‰N\àÛJ#¶ÜmOZ§gÃö u’$ü¥:…yî9„ìä»+R6ºıÒ˜}âá~«4ètùy:HéğÆ¶)ª÷¤ïESÇ¯O]oFùİRÓ¹ÖÙ5éLãÚ4²-ŠÚ3r„…ĞB`ìRòL‹ ‰¯Ÿ‡3§†&¥-S'a³ÓÍEõ«™óI–(Î–øìğËÄò#!@‘Ùœşû›ÌŞƒqoÃë—ŠŠ³€Ô´OÛ<QÊNã	¿o$*	À(Ëš<DŸ`Ñ%SÚ®ÇBqb/EécóîÖPïwÉê‚Ç(ÊÔŸåOŠ`rmQ-’#{™y)@Y@TîÕò0‹$¦¬YÂ°æÜL"Wf<Í®Å~˜ÏtìÔj7nëôˆ~ãâù­Âı`]hæÌ‚˜”|Ú {ó‡mu57?wPªš´…æÌ€D1GÚÛÿ‚°
= c:¢ÄC0Ó=çÿ9KG’ñ¦
”<9H«"•¬ı&ùù­¿æ$M%6±váë'œ X
ù)Y]%Url~ü‡'J` ùÿS	H6w.­İä©/d°ÙªK `Zr±+'®xK¿BgäãQ&¼àû§hRrJ/»ÂY	ceÒ÷:Õ˜¥Ÿ üÆÿá€3ãŞ"JRòÆB“ĞŠ}—–î_0ïK9$uÆ±ñ)öçBãE˜~†`Â=ğEµD¤.byiWœXş¯}C>C¡¸¶˜·¹^cX"òÃÈqb6ó.Íİa	û446âD:Œ©8 x–:n¡œdwãc-Á¯ìœ€ïŸ:Š¦I¾j<—VÓGV'îıwîwÕ‰‚EW\œVV>¹ú‘UÊ˜âßÅ3ÂÏTxW¤{x<¢.¹r\+4p¦ÔâÉÅÃïÉ;|WyiÖ]€Ö±±zÖ2§’jyô³4'j	kTÉç»ä.	ç§e#«Æš\'_$L2oâ…û—²YvGV©,&¥Upu£ _W×â?DÍaNã³…ª…ò¹^Ã„[Óë,úßö¾­»Is^•¿NrJ’×$EJ¾´dºG¶d—ºt;¢TÕİ¥:<)2%g™dr˜¤d•Ûû_öiÎ>ìËÌÙ‡ÙÇ®?¶q@&’¤T²»v–<Ç™‰k  _\¨K8¼‡†¯æNŠÛ,¯Œƒ¨'*uwúUÁŸ’JÕQ³2Î¯ÿ§7~B¿š÷ym­oÌˆ)µ~EßÜÁv% ŞáeKúõŠëà—( {2””k¹œ/ô¨t£<ÄDÄ õVéK4å)ÀšÒ!YÜDã÷¨ì§Fİ(Wèmå=ô&İÉÑŸQ'tò=!I½r7ÆY Îb(àèät®üWÑX	•ÊU/¾€5-fªğ‚Û+sv²/JTˆïåoZ§›T_p»ŠÁ´w+†¯pXy„ƒcá×rÄÁLµ®_Ø'WÎ”*ÛÓ²ººQ©Lè|cQeFZ«ëö,§20©œ%t·4ßyKºËµó±êóŸjİå\¢Y9±!ÎœÚrşŞnI£Õ7l›:ÊfTÕ¦B7¢ttLXÊU“õ¨OD¡­<èÀƒÙW-2ŒTÆõêzµ.÷	ØÀ{£5é=È–HÅH–#Íd†©¼*£Ë|"KnL3š‡‹.ZŒäîÏ†ö¸?TDò!]#¾øÖjØ-:ı.é%ø·×1b	şà`–Äß×I'®»—ü½]^¦¿&Cù—hĞÁ¯°rã­~·Ázºá§ÿªÁ áû~şÿçQ(£§'Ğqægu”üÌĞ:^~C—6ãkšFS+_u’nÌU?p	£l'¸ö`Â\U‡cş¦òÇ(¸h_w’€¾‡ªÛï±êïË¢cÿ`Ì}ü9‰2á°|{ÆWYiÿCğl#"ÊÀWÔ¯ñWøt»ôT~
e5€gå·ŸI¡oêåd¬¿Èâ‡½7è!¬\7ëü6ì†Cú;éNúòq	Eü„€Ã:w8‡ò*ö6è`G}b
ä”Q‚³û:ı&“‡Å€¤¸µk!y‘ŸŒ¯2KJø›ğ"êöˆˆäÆhM<‹ÇsS/q›~fÂ°ILš5’F1úĞ¤ò9ÍÒƒ-A{*MFVƒø²äy©}0jùwYK<ÆÕ¿Ø† ›×4‘ ¬³r.×fFœ«³Á¹m€KtQé¢t^#Q»S»W}Wt$«lTëç4
PãWî¼ˆÿb­—å/İ¥‚¹Gaz¡¦åÈ´B>gMz%úTÜë*i/uÒc†HwèTGW°/÷™6€pvÍíY¤’Ã¶Oª›çHÙëÚ)a·äñİ|F€ã¹%˜i³Ïİ6ˆÙÚTÉo’6Š«Ì‘F§Ê6Æu×“3P)6É·¸õ÷ôBr«5+y5|-mJU*¢rçQçÔçîü1Ñ¾É~äöZÖIS·gHŠf
Šå%¾<ŸÀøåOÔ¸áX 'ïŠyÓË	7ê·ãá8iú =úé©v¬i•e6Sº”¹³‰È)¯•áà/-€Š„õôU…a"I Ø|5îˆĞĞ„ˆ‘xü^´äó}|lÜ;Àû^›—‰æ´c…„yO]–Úsç‹Ïøà•,Yú}Ü#Ğ
í£Ûñ(º’'K7J»ÉÅdĞek3,?Ğ#³˜‚ÇÓ—¹ÓËéwW~‘æ²9°"ŒÁw=€uÆ9ØI›x77ŞJ_^da:õe~ãš#eï7îWsn¤÷À~4Lm„=»˜» –QXÂL‘ÁÊŒ¹dn»÷¹i¸8ÀŞRx‚âÄ´Â“Ãir/s‰©Tì´b–x“ht4ÅëL­|­İÓÓ½Ãw­â”—s±¾_Ğ^<â).=Õ8ïÌã™V¤•Ó†ÂÁØ•İ[Ê§Z¡}¶œ}!ş&Pº÷“Úy­œ‡Š©Õ®ğü[ê%ù¬[îÉqÚ{'·#·×‘Ãé(ïsd»YGÊáhº¿ÑÃ¸e½à÷D÷ê|®ùË³|ƒî—“}„î™Wú
y_È?J»eĞ°I5GÊuû#m™>VÓ:ílÏìNÿ¿Ç å!–~]5MRîì*v?O1‡‹Øƒ{ˆÍï FsÃ 3S½)ÍË›vÉÕ,Û«İO™hg„G'g‘âv¾(¥Ü«^wŞ:H^º?¦+V~kf”n·ıS~§üljl„Csßì˜øDáÂŸşÜ¯îl1“5hŸ·£>jòÂHàgÈh@^#îe%’‹˜®­‡Ò«ì€—“°¡iNíÅUl¡QÂj¬•1 ßlUÁÕ†YÀ}^»æÆëÇä%ßˆ¶{ø}s

ŞRÉöÙSy6I%j•¸ĞúÜ:!]äş>?Ù>ùKZ°Úº6Ëé[¬¦DQ­z]}¹¹lÔK ø+åÇ«Ë™ÅÈ— PTÌ²µ¶(€å$»QódC‚™Åv<ÌçKé·|¡ëÒ2ÿ°t`ªoé)†ucÎ±¤àq?é„tÌˆdp‡DYĞ_U¿—\´Á:ÙÒ©_[[ª"*‰×Y¥IJ»K£oˆ*;2éKY!Œ¾üËOŸ—6C³PncÖ,3M‹3âb6FÀ„7¬ËÙÊ*kıppm‰íË/ÿˆÇÊGÍ¯W×|8tâ.,2Mÿìômå…ÿÇWÔË—<ùÇÒËİÁu4Šh‚Dà'	½ı÷å>×–âÕ±Åø¹_{÷ÃÁÜÔ¤qšRÿš_!á+_–%UˆD¾AĞuYEkVšùeÍÑFzõ²&ûbZºei$—F§‰W˜sÁ¬zÃ¸x>Ûb›i`ğ]­#KùÜÀúYU`›dØƒâºì¡Z^Q…-¼®K`Ÿ0ög\ö	Jw• aÑY›É‚</¯À¸|Vı¥UAå,•êÓ°Ì|U3äkæ+À¸¤Ùá]Àzq›5!-`ã®-pàÇúXXé)û£pŠ1ÎñTa#—™şÛI·‹çÌëËgSİ'µâ9ôÉ`çaòÌ™xƒ£‘„›5í QZäş’_ìbëTìÜÉŸÎn#ˆşf’“~)Ê7~”_ÿ"”GQ¶ê9û5ãÿÕ×õ\ü¯ú"şÇÿmşÛuŠÿ¶V­Ûøoô7+Ì×€a4ÆYl·GbÃ€DøQç‚CÃ(€ÙF¡®àÌ×9„—ïÁÓõ²4ƒd5_ãÍ+½Û?z½½/¾ß>ÙC§öWû&îÅ#tùTQª¿ß=ÙÙm–—ÏÃë[ëş²~°}²»Ä¯Öàİzú®uö6âo·wğõ†~|¸ûîdïTf©§É¬®Æñ®m•IÉ6¬„Û=Û×l¤ÏiV6oŸ¶÷Ş|×BÑÉ¯]l¹Ñ~¸Â-¯×Ò§Áõ‹É8±_u‚Îû^âX3ÉgÕV.Gèø3èúŞª—¼éR =ÅBë¶ƒ^g¦Ä£¿‚£R7—»a§2˜¨ÀÉ©Ôéßb@Îœ*Zæ`›;x}OnwV8ì<Ákç®è#a4 Gˆ7(¼òtê#NQMlSvË¦ŞZ8]Á1³udÖnÀ¶R?÷E7Ãü‘/¾yÙÈKp;Ô_ÚzÊÒ<¾>h*#î €y]®c·I•‰n2ğ Át`wVšMT–È='£ìëÒQı2º"‰ºÀGôÓËµÉC‘»6
7—w—4³Iæ—ù7t=áxp´ÌN!Q$hVš2–#ß„¡ˆ«ƒ¬ë‚í9Ô½$ûJúZŠ'N?¯qßG‚—‚ÑU"˜”@Wõ›(I‘CPıÍJÄ[6-a	ƒÕ´¹R^i¡ô€òs¨¬ã®¯ËWl!‰nCÀ-T(}ƒ'({4WV]øÍ7"ÀTTón-El×Ñ‚ÔS¦æ%ZWZş_kµóZM|^5¡îe
<í“àEl–8rÍR‰åCy¡‡=–ÒæAå—íÊ_×*ØúiÕFÒúC.Lãp~AospÒG| Íl«Ò¨Ö·U;)Ò	ks'éI[deÓ:Şß;=İİioŸœlÿK•#CÙh ÒÁÉ.æm7”¬.¶%;S%­Ó´f9÷„qèSasØõ¦3“I›&éÊ}F£à™Tq"÷ya•B-tJîüŒN´)§ß¹iIfƒÔÈ©Ó«ŒRfbQK‘Yp-Ã0Aş	*Õ+aRú*ú bhÒaà¢q‹î!EÎ„RiR
´å¡kSŠ¹µt{Âºšåú–ş­g0Ì¨ô)oL8ï›åuıTöh*§MXË‡K%u¬„~)k %–5"[VÊ˜Wf
™FÈL¢Özı6ÁõdÒÕ=N#‘İÑo*1qˆI?É‚÷Ky’£}êƒ>¬° ›—üMcƒ øøŒá$à|%ÕKÕ@,<MÃ„™’Õ¨eN’Ÿ+à¥ÎÖÌòÓºDò+—‰†
”óÏ¾\V° Ò×¾BÕ¤l»iZ¦\.ÛrHkjÀ~/?Ü«û®l³	PâKOd²À¸”ÒQ!k¥“º”@ÕÁÇ[ağIF*›)(aÖÕ»±ezûÛFFÛ3	M‹ô3GNÉBwã5µÔfEQ•È%‘Z·ÊæuôCQÀhãıhpG~ûÍDpÂ”Şé„`Šiï[zÿ»ò¶¥İÍ¹Ö UrÄ:‰ã±"»Øâ ­’´„Ææ8öl"õ‡!ì(¬+¥!oâél2 ¾aØ‹­ÓÀ2“‘UäÉê1>Ù¯¿K¡UF“9øbdsúE×0äWar>Ø…ãÌïjµŠ,ôê›ÿ§3­B]©ïˆ)˜	íÜÉ¸bvt\Á¯Â±1;ê¹@xÄr˜
öó°›èÂ±Ë³¡^ø*ã’*sö¨T`àBÜß××+ßŠ²NzE¡ª\I#ØÈv1ÒšÆÂ1ÔüEÂÓí#q:ºˆ’1zä;Î­´œoğİ¤/(Ò|d‚²&c4€I„Nç"¶ÎÃQÜ	“$NZúGÄ-	®Â>±pÖ¯ÿçèE„V4rˆ °0ŒÀx¸J½$·™uj-7iÒ)Ã±e™œãI®®½%v+Æ?®ı¤Ş÷:
ß¼GÖ¹DD$Ì),`¦ä'/¿©‹R8ø×	*éb›,¨ÎC,”ÎdHT©bÏ´E,ö*îaû!ˆÆ?¡\g…¥%lU}Ë†
Eİ$PajÍñØAêÅ}À$„Õl‚†jb%s®Tn9áu|S™‚	¶hŒ®aw5›¸S2T.£•~„±œ®´WÁ8¥ÕÃD…‰¨$;qŒAÅ¶—?i·+8ØÅ"ı­œ<ÊqÄdc9‹\^ÿÈ‹ëš9£gæ6~bÏ¹À%§¸ÿ0O7‰@ÒŸ0*1?ú¼ôUâÿHxøØïsÄÿyú¼‘ÿ³ş´ñlqÿ³ˆÿ~ïøïO]ñ|“ËçôóFÅz·B¹Ë‚tÀŸ®,Ç0?ùJ‘İKÃQˆÊ°O ›sHà|ÉJväÎqë›CdĞü¢nØF3¡¦Ó8õ[MóÑ½ô¨ãÈÁV)¾çY'\]ö]EÆÏG@õºBš5	%Fg«¬ÊèRAÅdNo
}HÚ¡‡0	Â7ëD\çÊŸÅIP¹lgÓrìk£fî©’XÊ“P’İŸA»#×‘í
,ò!¢‰]–¦[ZUÎßÖ¬ÚïğÈÍ•’	Ëâ@“Ay@4Khú×ñÈƒ_&üß,@fë,‹9r(£ªt9ÕMå%$£‡®˜¸ö•¦xAø\+ºf_ÓC)ÍİEú3²1’eqlR ›L"›ßÜUoÎ¬ÓL¯T¦ÈëÜ@Ñ°5Æ“„%lòN¶»·iª¬úáÿÓ³İÌi}2)aDš!_O_µßíñŒ—o”úzK4­`X†(¾ª@#Yâá1õƒ_Â}HÍ÷ë¿ıú¿a–&ñÅÕ#¨Gì¥nu|rixREÒj®ˆò
Şj‹
ê«bÕ\íåe
ÇÜúu@G NóBŒ4C™S:¢U´jJU&û2Ğ§`¤O]m#ù*©Íš¶¢Š˜	˜’±öMıVÚ¸%+Z€*L…K×2¯xê›ÚŒº¢¥Ä8ÆoŞ‡»¤–ƒú`k¢q¦‹û†y®fº$‚Í¿·÷OwO·O÷¾ßÕqÑôjÃŒ¿©È¼,rğzc7Ãˆ:p­YX¥ÅûF÷Öí;†fh“!–lJ: 5ÅK[ÉåË(&9áÁ8yßc)jhÁo½ºV]³‰!fPãpww§}vŒ«Û.îLÍz<ú(vÂ‹(€¾¯Õ†áàO;ß	ÙYÁ½—O_˜$˜Òj¡àv_Tàÿt8i¿İLß.»Ç3«îRzÄ‚lãW›FèfÕÜÊº)á†İ'b’ĞfÏ)êõG:j3$Ğ+›Ü,«û§-E#ö@=cASÅ¤“ÜÕĞ†±Ô“*ZÛ¤·‰Ÿ˜C^ïm¶_ ˜^MJıBE`ÆÌÚYAµ‹rdåÖSì?ô…ïªM]Öv£ÄÑ	µSÍ_ÉÃı;äãôÂašÔ/ª]b@Ä5oó×vßáÕ(Ôğ>-«ıXˆ"^|­×{O½CDß³~ÎşÚ×I _¾¶İ@ˆ$ˆD—"VıúoA¬Æ&Ã8³æ09T®&7ûâõî„ÀèÛ½q’…£•»ˆ„3ªT†“ÑU¨§Ç*aS³Öëi÷‘:	Ç:Ù}!HÏ~Lzc)^É?ùJ”ê‚ñû6^{óò¿o.£pUk!ÉŒ)ÅäæÃJŠŠ{¥.P¹D¶P»‰`ƒKS”Yª’f57ÚÓ9Œ•úÒ(FKk7©ˆŸ,1µ¤V jìGÍr„ÉÏ­q<â2#¶øBÚ;¥]´Ò
†?m¿Í>]~9M¦k—H
 Æ¶s	Œ=*µ©‰e]ŠaSµeHÍ†IÖ)+‰¥OşØ	ñîÕI&æÇ²÷‡ÍåüÓÏe´™µRüe:Wïoÿp°!eÊì¡:'LQ±f˜ª|,4Ë³eªL3s‚è!µ:‘=g’ n¥Háˆ¤/ŒŸãYö‡®$™sòlÿ=jL!oK^’Òmïi*uşGİŒÒ¼ÂY2ŠsË<O¡.è–­
œ"|ø ß?ˆQ&Y­m5;{¬½İ„Ôö_3‚–^I³ÂKfÍîÎ:gë	„4Ëí"(Éf÷C¹d¹äÏÅÀFåı½×-u>"ÔŞwìœJB˜¸ğÄ–S5êÀNØõ¿GqB^uÇü¤ÁÌÚºu}m™½U0øG› uí»|¹ µvÛ6ÌšÊÛÒ€Tfã ı&ÅJFƒªl–³“ı¦,nl–9†¯ZE3ÅìÒxU·%ªƒº…™ÑGÄ†ı½7»‡­İPïdû`o<‚U*½¨Z5q›â¨Ê:P¡‰¿ÔvAZ¿ÊaCÓak=Ø>Ü~·{Ò~s°cTü#Ìø‚6á4ı©é4ÆÿÍÅõå¡JvÀd{S‹nHZáÄºßËlÓZ™‚ßm%pT\Z6i·œú²I>Ä§ÌïÍEÛ~8Ş³hù.›
BÔÁh7$t¹51”4%¯.(Â•Ñå;¸ş DšÙ¦ÕªàüP"ìW\VNv÷w·[»µ*ÁÓ£1„P+±ñmMİ›”ó@f	µSœ¥”¢NGGAÒÙİMPU+*³Î”~–~¾]¢?SK}»fJŠâªê¯l.Høøu†Ûï(¡Ìø´Ş»î¥Fx=’¥
3¸ÍğÔôü kShë•š¢ØxuıaLSùhæT5æ™d
,l…Él€Dvø]^Bp„àË êaÁd¬üZÄ1†j$SO¤”©C1Ï”ÊgrO¾È‡2z·{Ê7}oQàÀ=DbxòVÅÄ2ÎW´Í¿ÓéÑWA8d_Ğƒaš,Y:aQªYõfĞ‹A4#ëp˜q³0+˜Âö[rÎüYı/GbÎhÍs§¦ö™qFTû
bã`zK£¥ã|4‡h8éõpDXÆÂòËŸô{Ã¬&Ëyó³=ïÇs±Åô3F‰!'?.*'×42/ÀfÑÂ9feRÛNRÏÒû5ê.­’'Ö‡Ø.`ÚoÆ§£èÊ¾>Ï\ÿd÷wUÓÑ(•pÓ‹mœÁî_'t½¨lÈ„Q7YS+­Î]kµ°Z«V½Œf¼øHm1Óf¤Jcs³IÂ¾—^h$%‚/“	
´Jf^*LY!|a¢‚ø:Py9{°ıne’íãöŞáÎîŸ›k¢$Ğä"á‘TÄxwÇ+ÃÈ¸†1vÇ¿şÇ(ŠÑj„ÒÍDÔ4‡ö†h[2Š{o„Àó$+?°§Û'RDÏU]'g'ı>^_Êæbjt±ô3ë§°ŞÚœõÊ69ìš[V0–!“bf„¶iDkˆR‹lPÙ|.ªŞ˜nA»Qï}ÀAÿ`Ø£«AĞkˆøçèp4šÇ«š†²Iİ;–rC®1xLŸ~‰†VbM“ˆ™÷:ºr3)w¾›£3šb·Úq×í có\v²1¯m5×ˆ³nßMª+ÕBm®)Non'Jß›÷¸¹{æä†Ğc­…9³äÊü<mLƒåJ…WïÓììÁ<„”Âê€ŞÁd9Ùîå«}„Z]­½w{‡§°z±’×@à;ã]M‘Goä>ˆlsŠ««\0U|EzÆ¬6ˆÆÆ,2ƒçÙÌJtZTóJ£²Á±ÇpÁ•×H¤ÿQ@ĞsRôéëuÔxZmTŸú®DZ-†á|»½êU_õÂ*HP
´œ'¤wË»J[–Çè„UOgÉ@ş¦_œø/Gƒ&wR1Òé£xåÎß†fK«Ã®¤OSŞ´º ×—ì³T$1–H$ÙÁ½rç÷ç‹¥WJ—†ƒ÷–náèû7QE€í>Û‚x7E!V|O}÷’ŠÔ"ÌÙ†~S€YLo®ü¸¢¤Dã'ú4†W]ç¾ìVAqñH›º"ÆBR—IèÒ²	”ˆh„……£÷,K˜Öi9qü>5§·„‘º×X£•š¸	Ã÷íní›Şãßc_3®.0Ÿzİty7Ô
Ğö¶l|¿S„nWÀœã0gã5Ê}ïvOıÂl; É¿§À»ü²¦_¼>ÛÛ—³…‡aáLj¼ÄË?m¨í¶qê@rN|‚ÃwæR»A¿‘î³ª°ÒŠY‰ƒÑ‡pÜæ˜Ôóf†Ú„ü‚–H3¨%ÅÄƒ½C“`YHh×9ŠÕƒ–$7sy×‹m(œëEx“é8]°Ë ÍKÓÚÂI‘Í#å¼KlÃéËmyÇ ºèùiZ	´¬j[å¥cåã·¥^’9–?9§Y2:¯æòD3%C*
è6ß"b‚€UTÑ'%û™Ñ[e	ô#Cû1³sÓSğM’ºè¶Dınš8­÷[H­¥T-¦úïe´¤.î…¥È=	‡A4‚6#3åXRëñâª×Sßüe,“Æ\÷·×Æ/Uö¤ÚN/5İ“6xb»g\ï-·@Ğ†GèŞ¯¬·Â.vœË:ônÉcEš4a„³@Q¨¼\(KÆ #×ÃœÄ#C´NFx¯Ù¿	=0fÕçÌ´â¢dÈ½eÉ˜õÓY1›Æ
j•İ¿İ¹WŸ›éWQ9)ìæÌ|¡ÒTLYÙîv»4™Ç±P1ñÄ¨&"^]fYÇ¹ÕÖÃ¼‹ÊYéË9fšO±ù_Ømè)ĞÏª‹ü:FhŒã²î×¶¼+}û°*’_ÿC9ß‹½…QÏŠ0&xvAÊJn6˜ƒš'ı\ÈÒÎ°ú‚›ˆuŞãïUQ2
yË—_‡=¥¢‚ÄVA1LÄÀØtx––)²*_äPÆ²¤£/o¬¦‚6p”lV óK.!£fìfM–æ35r4¢¸Áf¸ U¯Ñu„	Ÿ£ë"MaÇ¿!š#IQÌ½"sA/ú%,¦ê-åiø3cÒ X;?èRÆî^.¼f±?6X‡C ƒB_o!¡Œ£„Á€}™Pº‚$È˜}BÊ@ó·‚j•ºÏ°]˜Ê13Ê4"ÒÛoÌ_©P¥ø¦6¬Vğ™AÊ"}¤óëä{ŒÈ†Äíı`s
)`öü‰EÅAˆ LŠËàXğOÆn$ ¼&§{lIíQHº€öz{­½–qáJ»:gnQ‚æ¤aIX!İ­-™¶Ü±1ê|ªk7ªŸŠçæŒj§e+Ûè
÷aÏ*;¾³µË…N¿N±ó+í_9—Ÿ^ÆÑp£C±8ÙRKú~Vöggu¾øÌ&°rF’¢Ü’œéõ”3ğí	MÛ()LºÓ™ØBãÄßjNgP
¨Ë´Ci²;	ş+Mº´ôÅkz±­º@N‘w«:´wÙÛ!»¢€0ÊFv{çõ8>ë†×1\4q÷ã+iÈšZûİÂˆèÊÊ·4ÌfÕ0=´]Q´;1K´cÙ-ÙÁ”XêªßYì2ÒÊ…P¹Njf/tâÁèóò{ÿå%A”>,YğÙÆêÒïAÌeØÎ´Ó›Á¹¿†(™¶
vnP^{XéÊ2§R³Äw^Šš›’»g[%İem/ÜÚb±.Øœ§­ß¥™¸,”ÒÁ[JêMœø
kF€UoªS}avOŠ¶õdjZäØj¦F'{€çKìv>Ùãà~G3×’Ü}àkú$½Ä—›&«ˆ£uRÇq¼ùØ£g‘…àu/çşyÍ¤wjÖ§ÍŸmò`xzä²›Šñ)°iø“ù›ªÀ mà}2u=£3Âl*—qp¼¿÷fï´½ıæÊhíìÂ¼À$¶g>\Ë-5Vù8Yá2¢Wâ¦’qxS7µ3j\›FBQŠ/BX‰‰/èp}…ÔaFV2ÃR%G‰ìÈık-¬”§[?ˆ‡Ûv®İlêÑGƒ%#/»æv:6ª£¿lD"Yf#ôìuw¥?aÏ%,”2A—vQ”€DPF0Š4v§`hôòanNî-Ë±gÍ®¡¨¢•wÆÂ¼İÅvbèdKUé”,³y»–sƒÌmÓÌëÒIr'ã72,anqí!Ÿï‰ÿV%˜$Ô§õÂ/ÿçùÓ§øoø}#ÿgmÿ¶À»+ş[Q¼ŸÅÙ}¬QÜä.âuV=l.7•™ÚÍÍMõ:ºb¶'ƒìÕ‹Q­g‰ZÃşT¸¶
ÁWÊ²ãAÚWtÔ `ô•PáùL]i¥íYYZEĞ™ ‚mx-óÖ¾£ƒã“İãı¿P$x‰**|Øşáèd§õ#}}ƒßIRÆœ…)*í!+@Ÿ!ú®ö78”¢y¯ü[	‚a„~ ÒÄ
ÃY—üıG×”‘¶WÑd™OĞÖÏ¢Ù•Çâ'ÃÔèÆi\¬Sù/d±ep\¨Tdv†&Ò`7*®ƒ$\(*oEI…ù|ş•;å¨Öî^çQõLYÿ©€÷!ÌÉQò•ñ?õçÏrøŸ°],ÖÿÅú_üÏuşçéûƒ²¦œ>'¨s'±vŒk”rA:K¾NÈ·TDP$4ÇU”“¤Šƒôª”·ºJ(ú[uNCìys—Ñ(?6V”´ºÅñğètï-z©î`_­ÑÄãèò¶‚Hé«V?49LVQ{”t †äá5ê“é,ùßS5†¿êiIYª£ûvé)lïıUì‰íƒ×{»‡§»<X:Åq¬yÎ3ıÉ,î¬Šn÷çwííÓmô=h5ğ½›F ^~31^úS1àÓÉ¼üawÿÒÃçÁ0sL¿Ï6g;5
6O”üóñùø8¾	Gä¡º¢°'z0Ó£Q€NÉ¿”Ò[õ¸¬êhSİçãÇví”œT”¨?«®mˆıÓVîÅ‹ì¾> v‡—Î§T:4A‘\„½=9&9ÜiúWDXU¯¥û?ŞHzš¢ÖSyYg<u€^5×Ì,:˜ı<å|‡ª;œgöó®ßòå°³l¦p¡ïQ*°~YÖ´È#AkAûXr¶¾;=:†yù±{…BÙ¨‚òñ*Åb<:>5ZgA›ød>ÇÕÎ$¨N.ûcÓ¤èÉz½ñÂs@§˜ÅmZ ^¸E“Ù —ÒÉîëƒk ›ø±;Iec}}ıù±[‰Òø¤>Sèş²v¡ßd<ªš£ú‹3×İÚ¢ìº§c”ûY6îã‹gíg¹¶‘oÌ}3kŸ¨iE€PîôzV­Wë¾—qÓ™JÓ–IÌÆ_³jŞ˜½	<“y™7LÇBªk¸Ê¤n«ìærã9&[æÌ€sYõ
QwĞÕieÑ¨mL·¦ÙìÏajšŸnM3ÌÇÜœ	¿¥mô“mVUí[s{»"sö©İlP?§{$Lï\eVç¨:§ŸN¤Ú‘í§UÄô—Y¿‚Y?»GSHi"¤kÃU4~?¹ …áçşCÏS‘H™(÷[\	ñ
(/8UMøöÌeDÓFT°Óµ÷vvUª)ğè1—” ãÃƒ•Dªbñ†æã²p»iÁşd•h´r'¼&9íxÿvÆè6RÒÅ¢èŠ
ádtB³°i*€A«Åù¾ìµ÷Nw¬ôn9«ñ®ŠŒ£¨*ˆ´Æ1¬_rhõ¶Q­Óêc?——Íe~½ìÕå¯H‹Ë­3?,¼èÓ­+«ciÏ­‡º&~·ì¾æ)É0ÈÕ`ˆ‘‘†´†ø£èÒ'E8è„I_Â$WĞ:[Åç
¤¬Â¹ºúñß3}Íaë¸kÖ!f• )Œ“›‘ªLLß;ÙİŞ§RåÚoÖS…AO&½ÉSB©5E–¥)5Š.&Ì3FŒzJ;]Æ‹äĞys¢€'‡ÕG&¶€sÒÍö³gÙ×M_…ğÓÛp;g­v^­µ?‹¯_xÏ…¨ägrc¸§åê2]„µŸˆø~ÃïŒl*¢ñÆõ*Ä`©&õÜØ>U¯ÕËQÈÓ#¢Â£šljm\%µlsaÄ³QCoµsyeIÏwH	A mšÒ¨y{ÚïÒÈÒzĞ0ÔÛ/0Åª£$=’X"&•„_¨„zõE•r.ym[’0µòä¨ÕjoŸèã‚)},S¨%¶¨Æ‹xú¢nåÅ›ã3%?¡…õ‘–¦”3Iı•.5N¾}ëcÌx´€¹>ê_?|¡NÇ'»o÷şÜÄóìòªW2š†é›»m 5Wû
Útç-8#šU*¼cÃ>ÕD©n·2äkãÙ˜4JRo_Œ¢î¬œãË¡|ÄOÚXTµ7ü@ ˆÈ·¾Ù­0\®kÿFEºd8„5ímÍ¨&ËŸi*~p¯Éöbpé¢(C½Ğ¯ßU/;=ÍÆ÷öÃÇÒÉî»İ?‹ï·OöpõhyŞ'mK¬ğñ‰¥ƒGE1¹1–9­‰*Äz>8î=î+l-ÑÅÇz½Ò¯AŞ»¸€ÅJÿ‚ƒÇ0úx1¹4v‚h7Ô/˜#Wq=}ûqœŒÕ÷`üÁxsõ¾SQ5á¾qÕ›Œ×ÓoôÜ÷RÚ¦ßDhÉäâšÈ¢|/HÔ0è	e`h†É`Œ„:2°ät/Äü£h•P»Xõ\Àó´Œ”Ã¹½K^Ï><RÉaÃ¿×dúd/†>&d1ˆì¯/« gÇ‹ô?şäy…6LnK­qWÉ¼tıœî‹ı°½'{ÏRËa-UÀn§Úš—í’îš†<œ;ïQ¯òo_*#äx‡ÁETÙ¨ş¡6…È"ˆÕŸjIP&.Pe+×:;F6ßîB3OZ¢-–eß¯‹¼WÚİœÕESjš±g/ÅM[Ig(’•ñÿÍ²“4ºı…&)7§Féy­®…h:SlEÄí‹Q0€ó
¬ûÑGXñ×QêËæVúò»=1¿„Ãí›â·†±}ÓYJe•¾ ²Êoúù¶gƒ…,¿XÎ¾Ú‡•¯^·VŞ…øÂ!w´İ¨n pÕ^nN³©ódŸÒ¦g*Öv<åÔCDd—04au×Y‰ Ï„Ç^“FZÿÜX£›øô»Ï6à/¬êÆÛ¢3yÿàİÆØ4•z›òã2RÄò?¤5h#Î­i¤­YÆÕ½òø€„Bæ ñ¥´eíÌy±äv0>nòmöp>á_öYzwõc@Ø‚ÉO©w=]|îì~ş1f^qiæ3ŒÚ¬ßnª+¤4]oZÅÔBÆ§k5tËî*ÃÎ(LşşŸª–|Ÿ¸Ù¦ÉLa¹:N&)€Æ˜ò:ïïÿ>»:Ãü¦¨¾ÓXü<IÆÚ´—ª½T™b…pÂğ>! ³‚ë êá=9f luvkÈ4h:¥¡5¼á`Ç5ü5jÎòÙô¨¨–²R2T8Jô…â*×LTÀÅiİ€NètLÏÍ•Ù­Çi4ƒ[…
ÓaĞøì‹ÏL22G<W63s%Û‘›yÆÄsoééøíQëÔH-ºôëÃ³ƒ×»'ÙÉšhÛS3×’9ìÆ`¯X«ÖŸUëª2¼k”œÒ¾Æc¬C×Í]ÿûŠ×·tÙ[;¨İ•ŸO²"êèOD$J¢Dh|x:fÜ!=.
O÷‘¢ößÿ]ì]b*EßC'Ì[3;MB´ÛÀJÍéNÆİªg°=Î´ÿµü¾®ıo}ıéó¼ıïFcaÿµ°ÿšaÿuo0ƒÕïgÆ¦ı‰„áq&c²*ú*ö¾|%o^á}¶O×Ñx,Z›öòSá»Î®
?{Ë­
·Ü•Í²%õçÉ€°éñ ’ 5È<y¬PŞó¶
†¡¹wR	»x©;o^:À²úOVè•ÚÖQÿ¨•âZ=ÏÄÍàK12é/Ñ°iƒJÿœ²£œ}¢¼ı¹È~puÚLª HhQZú)é—–Juz’¹s‚¤ó9ã9QZ§§VË!íFï=¥gÒÌ~?Ó¿µå<}N¨X:Hm®w³¶R7ı8¥ï4ˆÚİm»huöüÇl!6p“_6³:"bÓ`‹jµ*ì´ÒWTF×ö[”,"ÅDnZocà§Ô‡Çôô’îô£«¤¹RÆ˜{6j¾È!X•œ &QZb³byª8¹ê½Œyu‰ò¾‹»/òSÁnMlJ] „<£âÍ½—ñl¢n¦Ìù!l“ÀŠ:œß©´FÇÄĞ
<éº:ÈË\^²YTÈfYá+í'¿`ÿø¸ib¨¢>×†ÃÎÇgDÅ†
jç”<”jÕ€Ã¶Õm}¾å ÙˆJr™÷ÍÄ=v¢D6ÊHbƒÂÈ§°¿;.„£û	Ë¯İlŠiQÁŒáÊk	5ƒÛÁé$ZÂE/T”pG“R˜!Ş,hWRàËS *qycÇ(„2~Ú BïÁ™Ê³n©DK;¢0Æ5!Ò­5O1ğ¦ãªCpZóÏ'¿pÁ¤Éeˆ¦ÂÏ™]OO#€í(ÇúÛ¬'wx;qCÑ:ú œ„øŸ¢¼¬ªá'	H—úßlwjƒ”uíXk>U6¨'«ˆ´î™3[²PE*ÎŠe›™K\…Äş°[‰ øõuvÃ?"·ŞQ0#¾¶PğĞ54ğ¨ƒ2É‰Ø9·áÑ£4 3ì±¯¾ih„,
OéYT.İéAYŸ*q"Ñ;íB?pE‹dc‹Fçƒ]Ø«6U×9u¸gøp=.oş¼“¿ìâ¸Ê†ñÎBrKØt›T¤SÙçt%Úã¹|ÿ0H¨¾oIâ}7‚¤{oÕQAôOø¾,îı72b#)@‡¼Mz!âªéRi…ÒNßèa+õ;ÏvPÌîa›Š,ğ:½‹VuÛïİI‘îÙ
í!ç·¾¥ûw†MT®—şJZİø,#]¿NIóä“o0‚êÒ;îËb¢üné\ò0'0tƒHÇÇåeûÿªõæ‰<œâĞ*ÖÑ«Ôn0êEèéÁgé„&ˆ\¹Vä±4tX5PfÑ¬k¬cso~G_!/İ¶ŸÁşğ·¿©_ÏÓJÁµáÒ*¶2‘\×e"VìYRŸLñT¦ÀL—À(rVÜXQnˆò†(?Ë†+âîØ‰±+ÂS­N0“Öx„vW%£È`D*ÀËIt “„ÇÁ€BHBŒÑƒp=òdDî:äöå0P(°¹J§bOÜ€úKÛ×FfØÚaÁ×ÚfªI£Häb*§y#™]p][³áºä€LA·€ÆSŞÓK¦½¸Ş¿H…—¨£ØOC£LTrõT‹p®fñbìvº`à¨d×RçbZ¸š:—S¹f×·PFÂİ"µäâ´ ²˜l3Û¦xeÖN˜ò]ÎX3!³+òFd3/,±:ùJ³vBÖGÿ‹öBw‚o˜îO³;s^µË{npšİ5Ò%VŒ„Œm/-ÑOs-øE„–UjÚ´)2
ÇèÒI¼ú¨üG¤¿@½Ax…B×AJX4e@µ×o<	ğ^†œ’”T¾C®4æ«Ş3
’ê”x!æ¯Šü‹—Ğ´N
É†í…XKù{h4¬(
,â‘!+æÊbq[!ÖC¹at¼ßƒş¿ZëÆ¤öEë˜ÿ‚ŸÌıO½şìé?‰§‹ûŸ¯5ş€¬W“aµßı:økõÆóÌø?]¶Àø:÷6A‡Şó^_yKx[ö2ì¿rğFòşeŞĞµ´€ódï²B®o’AĞ#Õì‰í¥îêWI™/:ÌÅ{²
û2ïGáejY‡z<¬ Åş+õãe-xUÂ›Ñ¼ Ó	‡ãD$ %¤vÇÃM6§}".&cFBx™À‘wpõªRyY“_Q%á^ôªŞËÇÛıH¶X¢¥_¸Å}ñØÙªÇ^³ÙâÂWÂ;E4Í4hÓ[RÁÛYQĞO™_Œ^Í*SÛ©’•Ñ€ Ã4Òå¾AéU~ÂŸ—5¨bJ«RjÉƒKH}óAÔ÷dã-«"•Û¶.J+Á’æ75¢zfõ O×)]Ñ¯¨G|V $´KJß@­$Édsî&¨â+ıä›
•²¤¾65´µ`)m3Š•ö é3¾¢}‘Õ 6@Á>Ibl&~ƒÍÎM˜]Ş?->wÚÿa,¿œxùï9üYÈ_wüÍIı5Ç}m½µÿZ¯/ä¿¯3şç>îùCtcCe¥…1W=ıÖÜ^ÍªÄöäJÔ_ø‚P…ğ—öh•ªOã«Ğ÷ª­oÅáöÁ®g›jë¤ã8c<LYZ{‡GÇ­½–g·æbä(x˜ıÇóË×|St~yòı„C7üláoÌ!¼p+‘3—Ki2Y7èì]³^˜UëVu«Î+ç¼İåŸ°jÈzJGÖcCi='ë^ê
Ğng·õædëY¢=ÉêJÌîEnü¤}€}ôøô	"WöQ&ÏZ·>ÑFo,äbJNÃ´é]9ÕYÑ7j‡> oHñ¹CRC%}½½„Ôç	)ÜPbI}/CJ!–trh‘iOƒã¤3 KÓmºÍ¼’¸‚ª"cjº'ÇÇf2kÈ0m¾™‡Çó\(äúSÎª^«o§Iº½È”t‰`|¯Èfs¨¤üOûÛ2ÁOB5II˜ØÕ5’4ñÛl«ç(TÒSiªM]“Ú®Éê°Ğ®Ìc¡-Ùš§œ8K˜ã ò¶ÂšP€H¤B0¸„Û"ï{3St…ƒ ¨7x2‹ Ñª¼Un=ÔÀ½
6s]!˜Zmq¦´[+óQÇàaËÛcÓS#´U/˜ ×Ø(m&^Ô=LJW»}YŸˆÁeoAlç‡Ò}çò9„gÛÙé·G'^šm¥KÚq»ş/ïãqM-³ê-$èÿ¯äÿN/ ^éhcß‡SşÍ¡ÿÛÈËè°ÿ¾Šşï}ĞÓÛ'lßoQ‰%1÷É&¬ê‘<É‰5cFè,›§å„¦¶;ïu …‹S™`q
½èUNÛg [ñR¥V*Â¬¥dE€+Ä"8Ã$°ş.Î+±ßzqĞEM!K+äÉ¨ß=Œ
L›xŠî%,-ä&ápÂ‡h"!q½ú`O^Ö€hLºwqN­z£}º‘æhpÂQca²rg’…’æ/k8*Óµšl*ŸlŞS™­ö§º,h‰­Ñû}è(çjê=•!åw¥gœ«ßâíÿ*(šaò°»ÿÌıc-‡ÿ¾±¾±¾Øÿÿ÷'Ì=`×–S*.bº2»—a0&8œÖ“+AxUÏ»&Ç<(vÂNØ¿GOùå!
 ]2ªé~¸ûCkÓÜ&(#Ğ.¦¦è!LQÄÔ•¿#,˜ÅcÁ¨†æK{$XÑ|¡”„‹g¾ØCc×î¤C·˜Ô3½‹Í—¡V³zÔª!¤N2éÆ"èÂNL§³ÄLÿvBïÆŠLª#‚İ›&U3«Î®¯áj7ˆoDK ŠœÍ›´ü£$ğ§ïêõÕGJ>¨…ıßîıyw§` )VL%];ıè\@…#]$èEo£@Ce˜õ¢ñ­;õ•)l­§%’¿:5{I^Áw5€»Nêğ_+‰ÇÄ‹".›ÖKƒ•ÎNöM*åªÛ\áRÿÃ=¸Ã_B)Õµ"†Ü°ÉÒP)t\{j>;gÑ.&êØLõŒ¿†£T¨ TY°£0è¦8ÈyZ¤P0Ô”ÙTË”Z¸Ñ²3"i"RPT“-îÀxÌEZUºw1±:
*Ílô> ¹¾t`€„œ¥w~DëÆˆŞ{@¡˜jÅªÙ>‘·j¢¤B"+í3q¦d  bè~ûäàúyM÷İòAm|&ã5Ì¬T}³¿'0†îU˜d×7CcÕ*Ó_²©“SQïD‹zGß%ÚDgs ]ãL©OØL]Àé"ÀpÒëËş<rñÂŒĞApË©Á	s³Â[Scˆ;kêË†€õİŒiP³Âd‰»çeÁF›äæ}L°Ø{ĞÖß³ŞÅd$AË·ıÁ¹®01vúV-Dœ…ì¿şıÿCKıóËÿëÏ³öÆóÅıïWù<~üÍà"n™ÿ›"èJ}•
ãâWäóäÿ·ÎêJxŒ"SÿãÇ÷ø1^#Ã7\Š•
€Îé6 ‘}=3åšY•Á‡}Ş?VÏ³+ÊDc+zI÷mZcE÷nzş)}#¯áÒWSk»w>‘æÔW®FsŒ×Zµ’¾Ì¾S›~¾7¶êÌY‚qè.ïWóİÊ—q×m˜ü<äıwæœ¤šßr®ú /cgs\ñÈ	aİ˜ÿ¡’d’ùkÈ¾™¦à²}jAN™U­°@‹/ò@géİ|QÖT8o7öE%¹x˜ÓL¹ÆXF)„ïòÅjç[×ûw]­„ÛÀìšR 3H˜Q	K³€5p¦)ÚZÀ~¬ì¦-¤÷6 6Eº~Ğ•ülú)£ÕE™1%ÁÛ¸Y®Å4*¢ì,Z&E=™»°ÿÊ¢ÁÍ­hãÀD¾»¡ƒ´t¦³l¸F\VÉŞ*•-rÆ¤‹ƒ”ÿc $FtÃñL*¨äıŠş?kÏ³÷ÿOÏòÿ×ÑÿiöÑĞÃ®ü¯“pDªQRš¾¸C\K¢Ò“¯û]?y>^Æ½^|ƒ*…”ÉÒôİcÜãÛaØô÷|¥¤8BøKR
+‚X!IC#¬B¢5Û°6<ˆéÀE/¾vµ“İíƒ]`{ÿ•ZæøQz¡L¶„xu"(â6u··”òoòúnša®NnêŒš2Q†UJ¬2ª	©ç$Ğ^:wŒbT!úŞÿO;ß½Ûæó‘l5ê•”ÙÃ
)tQ#üs÷CåEş×`V‘¨Z<fÕb‹İºæ,ûrØÑ%şı?Åßÿİ*öŒTO²½‚L2PDÇ[ÿ.	àaĞÅôht &Hde—ÛIr	ûæJ›Ñ=‚7‰ˆDñRE›˜{o¼œX[z÷Ö"ÂÈK·7	©EğÄ@jU/‚n04äf£mêª %õ ×ØFşiI#^¿c´´FOóF]ÏCÛ«*¤ ¬ ºj‰†Esê#KƒrJjÕ¢ÔÜB¹¿Š…}àâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³ø,>‹Ïâ³øü?ÿ“¸l%  