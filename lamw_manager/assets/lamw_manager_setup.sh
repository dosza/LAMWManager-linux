#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1568673997"
MD5="bf8a7714db472dc59ce616b38d3b6ea2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25536"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 14:16:24 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿc] ¼}•À1Dd]‡Á›PætİDõ"ÛcJ©G”!á n5¾1–àÀdlzØ@åŠå¢šuIÕæ®…)‰ä ÚcÏ—º>KèQ-Õ±®{[(áŠBuMÁœå!¬…ÁÅ?¤0ÇêŞ\’{Ãä:À£z‹²Å®B®WS/2î#}Lcqœ›J»223MÓ‹¿ÏìB'§#ŸmoK=î r#!(Ñy=Àä€Ö_!ŠÇÕ9Vğr],yh+$Â“½ÈÃ'û$#‹±wÈ ÚVƒT˜·B+)p…EhhÊ‚ÚpfE!í "ÿ ,&?ñp³­:ôÄ¥u¹°@¾*Û§W–å)¯`³[Ã"< Ç&´Ñ­¼‹FÆ¼f>S!-r(o— #cjË– EÙ—MZÃäÊR8©›¹Ên@•`Ä¬«ƒÅªcGŸ%TPRšR'ôæ¨m®áæŞ*úä{J‚ê×"}K)åN_Ü°aİiwNå1æèF|Ê9Î$í´í*ğ‡öDÓ´®È£ïë,UÉİ;#€»Zê29¤š’Ò}r¯¥TL£ †É¡â}N^Œy@°Vª½Ò»œ”É´‚(œR[æ·n°ÉÛ†ßŒ	ç
OG©Dòl]ŸçfùÔ™°ÌşÀã"ğáŞÙšİVÄÄNfrXğsÂĞÁiüSŞ€Dü‹,i©ª…mõÕv=îÏfÑvùŸ_°s¬æÓÃ7ôI›%JßıœFïˆ?7 	¥Ç
uİjñ-›“Ú‚<6ÁŒHsÓÿ˜CŞşúÄP*:^SÜå4„•çÏ&giÑïøjCb2Æäá{—f¡¨Nj§}…DZä­mŒ uüûµY‡U30®e“’Îlõ«pïïÛûªú]Ù¬g4ğ>mY”»NÏ"Í0H–İZDñ}İ*ä÷EÆƒìê)×°‘ÚWï˜#œ2 ËÖ"é@ó–²^4ïãåõô°¿ôj±Äÿ¸”CÎ´aúJXîÎzêbêÿÜ¶¶ğÁÉá–6_"óxèµ³íBläKRÏY…íqÇóñCßŒÉ!œ~@é ÄB]…_<°‘Áä–šE™nÀ“îm$V¡y¥ëyJèš´‹è%L8³ùìêÈ<-‹¼WSûæ‚D6.SeRÎ”Â)şcÏx0í¥ê}w±kµl‰îÎñfI×ÏRÂÌ&<ÅšwÑè?"ŸdÇõ›TÙ'•n‹üAç‰ve-ÃeNmh?vM‘r½Ü{Şû¥r1à@æ­ß™Ğš&xİ
B¢¤YSÆn ”Ñ8Œuj–f‚k½Î]Í3úØä¡‘}Ù ÙHãìÍFuA'IÉ±ò1=ÿÇÔ‰rNõ`È+„´Ê9‚p]¼´”ŠN¡¾¶“ÁW¸£l)g²çA_*‹Xr½øÔéõF|xc±¨9pˆIûÎM*­½qİnåíºRL'uÅ'†4ŠòÎåº‹´¬Îÿ÷óÌcí˜ -z
íg£åZŠìD9ë˜æ»ßş¨±ì¼I¡æ\´*ı5nÔµÒb£	ãö-@4ZñÖ r=¤XCG4)j€ÜÇM™1&æÈ·§v¤]Mµ”íğÍÑÆÃ¤éö5¼û&Ê„Ü=>!•lK
YÖ"Ç¸ã«:ğgáçòÇ!ß‹ä±/K}|ÆæçƒçB‰BFe_	{(Ğ¤¾Ò@†prè5ÃKˆ8•Ñ“¬•ò °RYˆ(1Œ+s£´~
lì•r2¬ñ* >Å§Ê1lBñN&.h¯^z„ÙCùäÑWq4Z33Œé÷hH Í«‹Ù ùx»/•¦â…üfÇì[ÅÆıà1¤ªyØ¥{h&Ëë.iĞ6†6…p0—ŒÉ·€mgÉçˆ^ÜcÏ9;W©åYÉ¶ÔÆ †ŞU{ZIÁ÷9‚ÆÿÉR >?¯7M6ŒÍì­4æÙ×Ìş° ¿o]O•ßµ´kn]±ìù«ØºÉ_	 û±îg¡öû¸òoyÎÂı€>q˜©À¿ÑşÕ
«—}XÔ
6†/ñ€$â…^4+³ •œvL&.‚vD’ãtíÌ×É¯À'yˆIT£¼„‰=ò»ÕdkãŸ<¸GI¹ŸOƒ ÉTû»ÂCè<[.yg—]¯ÍémåRB .ÒDgTò?œdO¬ÖıPÃ¿®7šhæ1XÒÍÒÀç:¥Gzs>yEYÊúFy!ÂÍÉr Fˆ¹ˆw¿$ó"]|wOMë±ÉRÓï×ãc6®GEçb½[òã~ùQ—­qœ–à×ç·êI|C²½Ì®4²•«ÒÒ^¿&¦)VÃó¦‡“Øğ‚c×sã«ö›>T)y·0&a1\nË½lUbHÒc]ê±gãé´#@åõ—şâ$î#“unµ÷+úƒæğamXÅß—ôVú}`èÃà÷—¥<÷§ÕîŞÎÙ¢Ó´• uçÂY7sy¯Ü(!F? rŠP–uQ™iÿaÈ“»I.ˆœ
Ïº‡Öò\‘7	*>sC†€óx‹N¡®À©í}ûnÈğ¾V?áhËéÑRy¦À×¨°lú÷ ñIuõ†róHºITÔvêŒô(Ôÿ#µCƒ»9—nÖ
¤€<š©„2!›P³O™}5ä|¯£Í÷f‡‡Xm9èyép'ì²&sO½{f5¿Lw_=Ù*ˆ8	²š§ğ}[Ó»”ÌhC÷ÊŞˆ‘ÚH5*PMÇĞ‘´Ì¯0Ãßi&õ~Ìá8’º-"ø'_/pôë_¥Éæ­ÛØJa¾ıÇß›ÜÂ:şIÌù*Ÿ†i/İéòâµæT/ÅâÕv¾ıYËŸ)çrTú¢â:€©‚¸³8¶áÿĞä`ExÕ*> "«ê(Şxüõ€Á,`,z„ÍVŒò>9æ)át ñAñ	Wãò„Ê´»}Q ŞÍÆ	JÂ”Ú
ÄÏ93ı÷z(§Tvd§<„Õl®ÁîåÙS¥qÛØKV@`İõA½l¬#Ãl67)ÿ¹™/Ñ3Cæ'¨àÛ%ğïkî±I®¿Éo§{2‰}â$mÍÙ:7j £SÙ¬ÀÙ§şBÛ}òHmâÜ7ÁGu;”˜ß—Ù‰Ë¼á>ç‚Q„%Æ@wpI7}ÂIqµ2+C‰…‘ü;ÊıÍTNCØÄ]Bf‡ää<à“õùµÀÜ‹²ÑÓ—Dàâœİ`B=ú°«'¼“æn-ÌôŸTíîh¢JñÂä§;•E !czÄ*ãÓ —¹h<ªfx>RÌÖ¼F1•Áµçû[cø´Ç{ø\Wnş)^ôèÁ¢J¤Zl…Fq/uÀ<ãBy
­ÕÃ g&5ï×’¹^·„('`¹›ÈhÍ½ş¡4 :>fjJzø†L´¦„¿Ü]UôÓ7ÛÛC‚ K}!ú–-"¯]“º®'Iæ„Çù1$¡ro[HéUAS7©é"Üc'zŞÛNŒıú›5¹ìÙ=Ä·I7÷Ï(;×=Ÿ¯q*÷¯r¿¼ŞR#suC’f´)ÉïìÍ)>êˆ5Ym™m>!›ã7‚ü+Nªıg fQ ?N3F¨sO½şt!ùZÉı%IİdÓAÄûß’…|ÑÜ¤N{Jz-.Óİ¥õU0á¢¾¦KÛWz}h€Ñm[e:ªÿı¼¯- J=ŞTš[‚ä°bëşÖşk(*kõë[ÈL2'½Ãpèå×ªKã„Óã—À÷1S¿ªkWwõTÂO¦ö _µ·æÿ›)‘5o
º£Vl,¦ƒtë6ãçW^Cµg.9»‹ğvÎ:Ø×Ÿå£<*ßï‡‘I\‚îö¸„0»ØÖ!<Ù“÷÷LS4Ş¼Å8DAà_‡ÁcF,¸‘n;ææÌqµ7“Ël·öE-Œ.º)2ÖsOÅ+K”N1³ÆLÌ\ë’ÕğÓ*•†)©Û9øÚ'P›­x”êû°óp"×
¾@qˆbfÛPõèâµÓŠu¿áÎÊ¾÷Æí)4@5ù× úâæÓ$\_£½vózItÿı}öÛ"ià°4Še3 ñ‘,»¸ğâ'%á}ˆVD)ş©üŠv!\¶¢Ûé“jM®÷_MìÇAJ#ÆF±RÆ\— 	¸}}Aä…cFÇõ]¹]œlq¢Xk~ÍÕà·H,rÛåû^»4£şU‡*íÌ–jTpÂ×®§	šy(ÃTµ5WfØêe¥z¢Îµ~7UèYTN—*cÇ€}&+µ9©®€BÀ
7‡ş×ìF+éûşJŞ©x¶-°°G‰Pw+ùåù­½X`ZOL¹R}Vm?È‰\WBÈt&³Ü¶"E$6eö÷A’Ì K”+óL·>‚Zà¥]¢^ô)I@¥_fä™ó”ú[û¢¼F
qÛ­‡	!³}®ÀL1!ã/X˜§¼^œıqœÖÄç#ùq¾ómS°­]àï µâ|%]s?woÆÊœB3ë™‰/KVé|`âŸot¨.@'b0Ã=}íıC ¤¹0/ßˆlnÜ+&#N·-a* ô3<–Ê2PIQ©Äş×UºxŠX:¸cõ—“«rÊZUßtwÄö›}ÅÎßDÄò8D­¡2’CŞ<{è€G-PSh4İµ15›0bóxm:	ì>ø”"kóXvi+²•yıÒ„”kN
TÖ€÷í[Â…OçÚ 2Ä-®Ùº.Ö ®O›iú@˜¥E*)×…ãLâcÉ5(;é.ª1¤h)æƒ…Iyv·Øğ_‘;Ê«Ó¨rù¼-TÅ¯{Tã¢_™Â]êeÉ~ã¯$G
£ßB€„¦2^®†!Vw·›êËG2Ò •;]4{«¥ÉNşâXzv„bÆ³Ç† á÷ƒÏgĞ
û«Ò°w<c‹Omı½Bá}!zåê·XğÄf%–Â\ax{^ºä×Æ‡QêJrüíÿœB2£Ú€E§"W	ñãW]kvéça¦é{•ê6/ïpQXÎ|cax]¥XA~ˆbí/ü%‘¶õÚ@K¡j¼?yû‚ÄŠ?Öm×hè¢H[;uäç‘A¹xœŞ‹p O¶ÏZKä;]ß,8¸µ§&hAtgP±®OÚ*Ş´Pæ
·”…¾pÀVš¬^_àõ4½1@CÚõnı‚VW4{N¾e0T‰ìqåVc£L‰tYúòŞQò„L4Ï—ñqËcD#CqZh,´M=	›ò³É¬Fq!´ï½$çb¥©³!í¤x¥<¨’‚÷PÑ¯ä†B~CùáO4ÜcÒìxËßEÂáÿ\VÛh‚WÁ†uÅ(ËdÙe+ğiR¬üÁÕ;kºkh*w1	a0îZşÍ¨óˆ½vôı{¶ıoÇ6GìÁh~’ú·¢M÷uÑUÂå'æö`çï&ƒKšY-KDé¥T¥ÃT^‹&’/{DÚ\\³ã)*ÉwLk	ë±İ"Å‘Ñã|!÷a0Øä{°ãT‘U8Q`Ÿ%ò3åÕƒ¡-•Q1åÀ[9bÅxf|‹¦¸kh.÷ç×ï2!sÃp™1kğzˆÍà š'Ç&l{5Cİ}æ£
“£®o[Î«ğ—UPËë&(Qn»´‹-§< bKró„E9‰oÕ‹âå´!é\cõ}3†˜8µ XÖ£‰ÇpèÒñâ¬KCæ	]Å«c¹dî9)oÏz‹ÍÿqX½ÄÚ]f‡ó3Ç3N[êtÁ–èât}Œò¡èf˜–Òuë:üòRvSûM;;Ö¯ —“è®
‰=P¢†B•úŠa
oà>ëÇC²-cˆDö£Gq%ÛqoâŞ+Ü.ÓÌ"gÙëbˆs
ö³qèexŞ‡$·ùN_éÍJµ>ó3Ö¹ù®ßs³5(Œ‰Y·U§¯[Á=«v~9XSódPÃ×ZRÈˆñ>‰«ø§Úu”»Â ^¬ÛÑÔşTÈõ¤Ô`F²—¾ŞèóRàC9›ÄÄ<Ï4W;W_.P›*›†ø©ğ°Ğï(Jí¸şv5$#¿ZQ-BŞ¾xDjÒæ™G•q‹Í@'ìÖALy	äuÆ2SÖˆ$yÓä¸ÌDƒl¼a¥á¬í£FI8ÏeÒÙ¶eª_6­›Úøè2ÖŒëò›,o”?óÿ-Vˆr¡NDµÓ]•d«Å˜séÁü¶.êYë<­×+ã†˜Ì»7™ÁğÁÎ¸WeÎdNI[*h¢]\‡İ1CMˆ>Õ6cPÑæªwØ§®
crF'¡{%ìµÎt_Xy“&u6Ÿ]áŞ¸ùD&Â­]+HuE·ï˜~Ìã@=~ZØ8	d±}ßã_«IB«öì"#€óĞˆ¡Cˆ§EI¬#1ı¼G7`UEØT$ö3”]J,Vøš®ªÿ†÷]^?Ùäı¤eİV£ø4Ì¢·Cø“ŒiäÒHC‹ï—ôíµRŸ)}*éD@î‰ÄÆÈ[‹ü183µÊ˜ŠŒÃ¨0YM1u:Ü(gx$Éƒû<Ñœ|?Õ×j6>%`{.<æ¤œÆ·›Œfÿ[i€lç¤(<•Ûxx ù´+÷"ÁJŸ"]1»±0Âà– °¬j->“J#·Î%'Ö=æFh†¼[µV‘J\Ê§ÎMIKïSì˜h9}’¼vŸA¬»r~qM%_]’bwÕ¤v°¶`+Q“ìóÏ3ˆ³l:„cş¬PÈç(Õ,£4¿qê Ÿôqë’ÿH1”aŠÈHBË¶Yãğ’sOzòW,¿y(çI¨.œ-“òZ#cmkUøKF2l’Á:áŒ‡
ß±¨£§‚Ezsnä4d«pdå·)PV¹´Ú‹Ë'ovqÑŒyÄŞt—±x}MDGg¬;wëYˆ¨)i“öûîói¬€‚Å¾ä9Ò±ò=ÿíª‡Îó$•{Ò±©P o"t¥ªÏ°IÊu¿70Y ş~g #Ïr„yù€ê'Î¯¡ªÜO)qvñX ™¦_´}´§P·RÍƒ rVOÄèÅ`Ã{†—È¯¶:l¨tx¼/GIê¡y•‡Ôr¥ù+NuQ	o##çTÏR|Ÿ.¿äˆ¹T5`¼,§¹²¼®Dè>ÊX–ÁfEU$mfõˆ,Ëã´8÷¹?E€ÔÀrî£ì>ôô¢pÂ;ôë¤ıóYBZ>S` Â¹E0Øy]»i“ëgq·‚ÈZ„XêÊGG•]ÿn_Î Q3ÔMÇñ¶ù²ñCÒ±xÎG22·,ÂÛÑ|ó\gİWÏ–Z5Ş}İzT¨Yx›„ =KÉBO¡  q÷›ücØ|7š}ÆºÈÎCÜD±¶ı[ÉÑüƒ³0S¼»h×Ç‘@vÙR¥vuB´!}93Õ;…7KÖsßú¦#ÍláT#Ş²x}$$‹MÕâÿ¹ŸjpQ1àÒ ¸½ßîªx¥¦Æ±ğÁ%ğdÓ8»Ñ@E?¿º`Õ@ññ9†wYI»x	ôã‹j`Å¹—E5	ñX¤ä1<ÿdËOşİPoöy8]/s¦äæ‚¦ĞâXQ½¶ ÛËÔ‰­cæÚ.õ9"ƒ„xrÄ²»›¿îØ™ÕS¹€ıq…70ÿ™ãŒwKKªîÜ‚4 Òõùä‚Ğ· ê×ec7HAÉua¯OÌQ«ÎA8…%WIØ^“”'J<§JÏ|0•6Ñ2ÙÈ~¾¦O&Úk½¯Ë@–Vç0™d9_npO,$¶ş +Bõ	B¨¤;êå³Œ kğÚWÖo \(I4ƒ.ŞÛ•"@wí|¸0	o
ÉAxXÛO–.Ğiá;A¯´ıA ª$õ‹ñ`ßÆß:‹\C‹cÉV«öpMªñ' Z@0¯êç 1Z³6¸y¦øÒ±ÔH½Ì¸!^,Ç
èË‚Z™¤9Eé\˜ìI$;E)ôëÀ’Œc¿‹‹ÕAÓ'íˆS‚‡%l8€ŒOŸî	[î\2Y¨Âk§ëÀ„;†ƒå0'¡«]±š×Şt&¡›3zƒ+&ÀÌGBÕòà¿6bËó
iâ¸*“­ßƒIÉ¡Xp‰e`€<e£'‚½•Ë"çÀ6¸–½uß:$é¸º.Ep‚M{ölnÜÄ«! Z»óİñOâ§ÌRj¯‘b¦&{ñjÍ5Ç	jõ3}Eç‘ 
¼ÔA£áï‘ï^ôçŠ5Ô;ƒ âËú*ñºïü>^è´7ih Y1NB3}%üÀµtJzæPOx€35H¼ƒ*Õ¦×„K|Íf -ıKP;bDOAÄKƒ¸€nh¥RöoĞf¸Ç0û~ô¤®
ÌëªİÚ»ÉŞIÀ²¶‡ó‰£²íÁ…ñ]š%VE™¸gèıÇ/gÚMãAïè}Vÿ®a)yq‹ÿüBû"XÇÃS‚N(K2)©P)´Ì2¸á,ñXˆò¥q÷ÚÇ‘–FVÍáJğ¶v«ë†è=²š“”sàh¾‚&È‡ÓÈ^5ÖÇ(mõ'wPnX”®	Ox‡	ÑÌW%jh–ÏR†Af$üÁÀ‹­“ƒUg§·lŠËlE†F·És\­y‚ëD‡>qÆ×®~ÔCUWŞÏ®—êR=iø³ğÅŠÉ|±ıG8t$b§êsd×Qv<LÖš1{ÍÊlûàtimy³Y!½ÔDphN¾xxi¨à;v²®šHÿÎƒP	¬‘ùQÈ *^¯)%¾ÃŞìZîâ­ü’n1ûS›.¡ßLp2]Ûƒ  
>)MÉXíM(¤¿âzÜ£¯-svòĞ]ö
Mş¾Óî
øë ÷ÙS^V¦<e£<ÿ’®°Pï‚z´Æİ3‡_†Jfº@Şœı¶[—åØHŠ²|K¾ø¦/SÌON]U®b}DíwÛ	à¿“Ñq\Ş 9%½Uş@‘;½
5á;ùn¸qĞû(P8]f9B6hó%Vœ[F>ée~ø)ıÎhE±g¡<r‡€7‘ßÆäœIZLMê_-ÂkÌà;;2©áMs?•Ç¶!rí ‡Â^\•
4_1·nz¥ˆ-ÆÃuöÃëàJãç&%³©;Ó~A+M=l@û#po©µÊ–C°OÈÑ½§im‘ÈY„GDğîL“o²¦•€Gˆô´T³¡=Mxn)½v3—¤Ù
—¾(4~ÙB6üáT’«)óæÿ#„­²f£fª5C	‚a	½÷Ğ]­Ùhø»„z7ÓT‰Ù…w7Jçöoy \-À®½!øE#§E
6‹uÖéöBüÁõ«¢T1¶^wm]â¨&…‚½¡º÷3pÌÃ‚™Wqs‰3*pdR1ùg×c8”ä£¡>nY1ø>:»d§ „;•Vºù C—×3ß´•D‚¶YÕÌ˜(ÄÒoØç"0¬ÕˆéĞÛ<Ö÷¾ª1¿°¹Œ<®=»¸ë•aº
?†«‚ÔEä•6'7í}Q>âlüLšâöù`lÓP/÷à—gd§nÄÈ¦Í<Å¢ütåŒÔØ.hĞ„VŒ™]ÈÜ:îåã–«Âk­Û‡RÚpxÂ˜ÓHœùÉ0Ç@¬Û«zÈ$½Q_¦/eğ]CÔÜ¯“ú\ÄÏ'ğtx<p`}Ãü®èn£
¸&;ÛPòïjÚ¶=pÈL²~CÎûn]ÁÎÇºWf0ò³¤yµ•l‰ã}l»§é2ôbñ+î½ài(‚Z‹…†3qE×œKÏ3ÉÚÓ”[XÇ…@†ÒÄ#•3AÈyB§j`*}4	öYKæ4(™ÅÍS^lÈ_"[¢gÌÆ·bfÌëÈHv½¶k€¯uêŠé¿E©LÍ:ÇÛ´•’z.2¢W±DF&SáK†x4œ‚Ùö­¿üƒ8*s­N»¤^°õ­9ji#à™‘-9ü*Í®^İ4ğ:FaÂó.ÂĞ	Î0Á%wwfüôqc+)…_|~lJ$m¹'ê†¦ZåÄ<S‡X3vÚ…ç%x4ñlÙ§Øœå[(5ëşÕ	ÿÂ{†9(hõğš'!„µÑVNY3
vj¼şßM=ğİÁÆ2^e…­¤[/óPÓ¿ÏÌW”#½«äs+KÉ+>üWÎ|µ‚ß@Ëæ‰è~ê¢ÓQş•ı¡>a/çŠ Q2·ë7ë+Š9Ú5vÏç°•bËìÏû†ÀÀØFa3ê¯<Pl®… œw2½6£­úş)£YeR‘{#&Q{sáTÒ<!Çh…²ÒBEl–ÌÑIím9(‰'a!¢yÃVAËí¡åã›<Ş1Jyâ;'Ğòšyç*–2¸ŒÁØví)v›_ÚÁG1ıêu¸«É½~¤2šŸ‹éÌTò4‘ùk*WCˆl K)7´SÅ×§ ‡m]+&N(c.í`/.u‘5½]¾-¦^š¿„$Î¬í±İQFõz»{<\‘ Z7ï•kxİ_/X¾)Ü¢Z¥|Oéb**móNÂëÅ¢‚üO¡ü¤eGV÷sµÓeÙCZ’õ½ˆ°¶ïµgÄnôğ@NqìŠ—u£éaİ6‰”ò©°©‡O±KÈ‚oV·³ì¾%ü“%@;ŠÍ6l¬@ÿÀªàîĞA€Æö¶…›Õá«ONáŒsûİ6›xƒQŞ¦–½ir·Ş²H×”—=§"Íâ·o·¦ôôÎI«ÿ;+“ÅßºT¤mxó“£sRî•ìZ@wDj³=Tw£šQÖ%{:G–F²2éW;2²›â¿Ò4–¬¨v…>†O˜[Å?ÿ™¹¿ÓiŞ0A'PWe*æñ,Òs×¥F‘Ç¢’²o'a¶°/Ã®ÒÅläŠ‘á—Ñ
ÀÎĞky€9º×í&²_±M^Ñ9)ø¸ğ“kÙ¶.dİ
ÎÜ$uJ@€Lh
ù…İyÊˆ?^1.ÂŒ/TÒnŸ-ùïş÷8¾š’Ü·€ÙØÄP¬!ªü¾CTß„
Ğ	°ÌE?K|#ú@&¶ÕÑVç&·ı„I¾@Ï…%Kƒ?n¢q”p¶á5~…ğn^Wç² 7AR=>%]§<Ö¨U'1>ÔªgJô§‡¯½Ù9ÂVÛŠÛ ¤ÆÌoùonãÛÉMp(¶’q¡¨
ƒw
â¾Õ?ı™Gu]bS¯şßëCzñ“O§}cÚ+Ÿ‚E§=ÿüêTû¨0QCC7¼k´›Üš¼úHBSæE•ò]•ïÌúäJ^Ã×øÿŒ&«»Yÿ¯#.ß5˜›HàC;ããZpŒ¦#Ñuçø2Çı7@‡f‡!æ‚
Qc²ÉXËß`_¦A]¡!Å ŒÛ÷è?¾T©ÑÂ¿_còà“3&à¾ú%ï÷Ü/‘‹¥s° ]îÇ¹B1qˆåÙ‡N^Ù¡˜§	&ŞÓLÃø‹A1ÏV~7ÜË>9wÀOdW-¿$†Å£²ÚDÑÇJË+bF^5óµ’V›ï~‰İzNÇ ¯7ŒOç%³fmØ÷´z¶…á8Æ4º"û=HPıÊ»,»Ú,ï‰Ğ¬JØÂ8[b´æyšãHó½cCÕ¯ùÙÍ.îò›‰Y+YìRöÄ¼*â}ø2øû-”êÈ^Ø?× ’¤‘ª)~¥CèˆÓô3›‘ÚQf¨O4p‡Ë³09ò4¸æâH×{â×Ü¸jÛ*tlQÊvû­ãõŠÉ4Bf²:ã"ƒ /ğ¥0¥ˆ*ÔÃı×“mgµ_ôñ÷–Ocv†›÷‡}b“ïÅuÿ…¤(ºòÙ¼Z[®Î!‘SE‡ı÷|44mîİlTg‰8ª£^c1·€=/‰dŸ²ÎÒüÎ°å°Ø!*£‡ğÖS›Ó=Å½»‘ÿfçyšj À€íWaªç™Ö=†HÛg%½¨¼deJ8ƒA}¶åxkıñ.Ø·F#'Z¢ÜûÄbÙóËRås4¾xŞaF«”YÄì[¦Xµ¯‚{B½Ûd«pè&7·1¨|^Ú/*W>9¡òƒa×LH.NA#šèt% èªáÖPIŒ±qÖa>p±FëQ;$bÎôÃP™PW=Iğ­ºcÂúb[æ@“Õü?ùÕ‘e*T¤ŞÓ7ëÛ_Õ/ÖªVWÑÿ³QÏDy\rº£b‡æìt#¥p*Ñ•¸cÚœg)Ä‚ƒs¨´˜×B)¤Æ:÷{qK?9‰®¦–$îwË`Í‚Ü4+1Ì
,÷”4B â_6K®„Làõ|Õ:öÆ×PÄí·oiYÚUëFÁƒ5©Û¦^4k:±°PûŞ`ML bÜà!m‘.Í&ZWÂÛ±ùÃ_Cçäu	¹³”¢…ñŠ„	S0gİ¹rR2(ƒ`º„=2-&â`VÑv¯GÌãó©qwî÷8wI¬‘#î«¿é#Y  -¢TFÜŒj(¡1Õp=Š@[†¶%W¸ıçAÛ¤á7N³u,YR¹Œ]˜ZL|avêà‹àplÏÜvúëT\FÁÚ«šFJ=ZUhÕ°…,Ñe¼—y@·º8şŒæ}1µÂ/‹ò7ÇÇ·ŠW)wM~y£eYLí>ÕLg$Xáo#Ôxô M®Şd šÛG¼üNl‰Á 3ëÌN'NDNvDµŞ8Àôe<[Àx[m?(™·D¿şÊ5]kÄDØj¤yIH4«+I9oıêYfš .Á'@¯Qó¶X³¤Ö«ù»N‹cWúUÒ‰/éşè¶ˆäv»ı€°%A6¤I*sG‰¿u¡%3°4ï–‡.i@YÂnƒÔdËEú¡$].s™Ë»k àëê8ßğÉd² ›ˆs\›O´ÒKŞÀÀ"EÈÕw1T [}ß!=ĞjÑF„Õ‰†X{•]-Ğå§~:s}Z^•öœİI	DÃƒÕaxÿµ°ì³9SLÅÉ¢ã°Yë­ĞPL”Ğè;d„‘‹7¦ÎeÀ9œ7Ïò½Õy*âŞ²I½­Û€Àå>fÿp´Ù°F!8:ûŸ!­\ÌA	xÏ`©ÿÓzm!4 ùEŒ„Ò-8W™“‹ø'Qëçaÿ´³ã£$ÆiñûTÑÅÈVf>ƒzâ;>hı7‘ _™2¶¬^XMuvÁÕ÷=sÇåä¹(E¡¹rÁŸS–2°8Ì„)BSnÚß®°5è&wá)ßäp@ùåªH­û¡h´½¨$ğNK¢™®Ä“/D©r#ˆ›!øòØø‘'‡ÂbàûiƒAÏçá»h|ì4î.±^‘%€éâOë¬¯Õ{0ş ªôñãüà™÷€Ì$Ûu™	º.[0Gå¡õ XÓE˜´‘0Ñ^µõã¾Tƒi~ølİ’1Wa[í€m86Í	"LYF®1™:GŸ0˜—Û¦è{ÄLNõşTz XÛ>÷H¥Âø›Ü8¨ß.@Oú5¡µU,lãÓ_ºªu_V€•ÊıôKà")ò¸ah§µŒûĞUÍOôğ–7XT³ì¶E¬°[ÑLF~ÊWşÕÄo7GS[*onøêÜtÿE*<Õ‡Üõ¡®ş¶®m|ÎîÔ¯ÖÚø#™‘ıf! 4kkgÓäŞ-GÍ€@åÕæfl9rı‰ñó¬8úûv¿{]Fb‚¼ïíÅÛ`
ç£7±dí¦_o`@,.tåÏÍ“ö;À^¾%SÕÔF,–Ü0À€ÏnÛN;¥
ÕÑ6¨‰ÁO¢Â85†' ªÀó=ª7¶"7şIõZñ¥¬6ùX“Ìuò@w+ŠËD¿ˆĞÊ>ë:@@ãˆÕLNQPŒßr†zœ;•ŠNÄ;jò2ÈX\âGÍVºLŠ§'Í$4ÔŒØ§õÂ<QRû-ƒKXhsßG¼ÕÙDQçDø9TN[MsÑ<¢Îù ^ÃdòhÃxûqë N¿†0‘¯ö×ÚEòš VI…_7:QëÿVÔ-Sä+qß°ÛgâPêÆ²Î †‚|ºS2: ¤4«šç¦×S°9óÁ|ËwÉ2eÛç_,jÑü[P åÜ‰íy÷ÆÆ.”ş‰Uhë} ¨¢Ù}ñ±ÄZòŒÑwÔ·;Øò­Û€¿úœòÔİ9M¹û¨ùÖèŞ„DA¦øl¨Ğ=¦ÚÉÚ“Ø‚ú½¨Í­‘áš±'ı—  ñ7Ñ[X´}»ò,›ğƒ2¯à€O{íi-›D³û à'Õ`v§Ş™z.•;[Ùïsó#$* ó¨×÷ï 4Ô\k§C8ÜˆtÉ£”İ¼µş£8ë/dÒíĞA@"…)¾¼Ü½:—„F€@åÛ4Ñã; ?.=ßñz_hètg7GşÚøÜ` QÔáuÛ.Y{®Aè[#ûn.‡ÅDÎàœŠLÆÂ¬)hğÈÿp	ÓM‚ç”Â¤äŠ°‘ªBÁ/7ÿ—ƒ«…}26ï¹Hù_bšQû	Y¶7Fn%Z8¼bHZÑ`®7¸¤A}À€CW_)QÀ¸ß+ˆœéq>_·­CÉÄ°ƒŸÁç%¿-GıÕÚE¼Ùøª4@vÑŞAÙ,ÓüXdOØ˜c=Îš]³Kø£Ô±[ KÜ/åD­¤?<ÊÒ3`
1Õº!Db‹„1C7àõúÜÄe$–ceíGhÑÇuá°~´XdD¡äÚ£Rß>£q©QöÄşşÃ[q’Ü´\Uı/ÙUÚÃ)äl¡SX¬×ş&’æÍÙ§˜BabÏC†·¶××Itîñ¬ 3§ûšÜxëš‡ñ¾Ã¼@u#ìÑ!¯gCIİRpëÎ¶°İ½H¬#İg|~w>”£6ûe!Lc+ö¬³ƒæc.Ér}ùvWw<,İ7$V?NNü§Y¡Áöxtu¬.Í†…˜…?
×ˆ	Ç¸.ÚİîğÄ¨‘»ƒ&J»Tİc_âFÊIfãŒŞŞİĞz™êÉ.¦ŞF·( ³ğ`‚˜U&xZ?J‘O^ÌùÔ,[Èq\wõl#+¶*ŒŠú®ÄTÀ{ğ÷¿çÒYrü&²+ˆK`&-¯û«4/Ÿr@€µÜ(2Î>”Íåêÿp+Uv–‚@ŸÄq„ˆØèÎ¥û*ìÚpÖÏCt¼Ï`ÂÍR”•n?’¥¢KªçÊÜP¡ò	Ógı£P…ió#4ú²öù“xŠó>@dö~î6ÄïîäÅ.†¶Sql£Õbæò1ì aì:—Æ­·ÊZ]š¶ÿ€âÛ†2ÕWNY~_¥°!½ŞV|DŞæ]ö·H°rÛÄÔÏt¿ûÆ­+ÇEœIÆ®Ê^8­ÁX÷ä1şâ² ã# Ì'ÊXQ«>#æı«” y*‚Ëm@‰’×ĞP·-Ñ¼¨É¦6hİkœÆBãO2\$”ÏùŸ§ÇÔ><y~°¤[Î»áw‹ø¹ê?úõÌ6™¿µiãdÃÇY­ƒ2— œ@ı›oº“uõ¦Y½CÛ'7 óï3ã[!*Ê+×U¢¡ê˜–cŞ—¿—Â|YLÁÕ¶NCößcğƒˆ¿Y.ªÑåë-g_+kÜq5n8l²hoµ—ŠY¬ÚÇôS£“å7G‹c"L¸z,÷·ªN'Ò*(Cev&ÕLxñ ~ÿ)ÊÆlR(ø-Â=ÙÃİ´P2ğO¸9°Ot½œ5uqäüPŒVs×‹Ş{a^%©ş'J˜¸Nºspqíª©SæL­Ãà²°wt½Wš,ûx?OÑ9a\¥H‘_§OÖAW‰?—^W=Âˆ –n„\I ‡Ãdc»àÚ’s êÍeqVö×|.Äƒ_‰†y¦Ò!fÚA‹¥ö”Ì„Mâzõï‚¶rğ÷'†/c/ÿp¦ÅÆ›^Š;?Ä"ÜÛ-Íú¬™mKƒm
wd²Y‰ˆ+ü¶ÿ¶¹‰"İUÒ¨9=òì—ñ‘¹ Ô¨éÜüw—“hÿ‰ú×xĞ{¥ †OÜšÀØÁ¯q _ë¶ÍÓ»:{ûæ`6"¬Ÿk-Ê´ÂT"ØI >¨pfò£ÍÛÇÁ9úójâøVÂöË£OÙÆÆ0´ğ#ø•tt‘ÈTò@€«}ƒ:í¤iªù¤Ó–šıì÷ñ"®H*·m’T@iê “‰´­tŒ>/ƒÛ”øû(ÿ12a›«¿‘â]ÜæŒ§äkLËÿ‹¨Hœ‘QDy#xQÒˆT3†{ a,„<Æó×ó
0^h‚ÁèÊG6¶aiT,RªŠ7™çyFƒÔtdî_È‰O\#Ñ5ğñ¨\tƒ¼ ô÷ œÃî§øTÑpË¤GV­Â@·oJ²±µŒHØ.Û¢åŞr?L¶?%hz˜".6uÊØêéâ™JcÄ2#Éó”^³³çBPıĞD,«}-°*ÈßÕ È@CK«2r—¦ÜR?Aºìñ_æfÊkÍ†‹ğAèÍÒeTşªê‰0±‚¬:÷ç4…gFfZºcˆ¥²‹°Q›×ÈK:üzŞµÈ0¸¡ãÎ°¼V]’ñ:|ûxçqnryÚ¿üŠ¯~ÂU/1Ğ…Ğ1VëÎµù|óÈË›IæI>­ïß…¥áU‘áQ³B"UürÆ1]»fà£G}ÖïHzLí¤BÜö=“ù—Ïï,Ö$&GJh,º¯İy+àWå
r¿­lC¿këÍvH6âª›‡ÈÊ>r@ãM¨®¯ĞÍò«l²ÓDä˜bÀÅ›÷oc=œY|v§†“ÌîO}ŠM»ÑÖ'ãzs_l‡€‡àıëªùªñæÛŒHXÇúM©ö”ƒ#…k»U‹¿}yoÿTqX@ƒ¼ºè˜NxûgEÖ±®66pKè&@(&‰[‰(ùÖúê›ôêÂ4ÜSp™±Í´ÄX@(¼RÅkDzztQ
ä‚œ|àªvªÉé¬Ô8-
cñ:)€ADS˜¦|%Û[‰“½ˆkë8Ôq¤#oØj—/òÚÛSàÂ&ïíö§æãWiIö Áù|ŒÍ§˜†…`ïÑ5K¾„IÂxÎ‹IŞO°ÒÈ>ã‡Æu\6÷64^İÕFjÀış/å¢´”›L\/éÅt5ØâfJ$±2ÒV=Ã½H€ßÀÍñâüÊV aó¯wÊm}±šY~©Å¥úõhÔ@ì²IØ¿@`«v½°ké!Pçäô&PÍâw†!ò¬ÿÍowP›m[çõ•}ğÉ$ß›«5Ê%>‡ÛëSÉÜKk&˜­„
ÕÓhS8ôSÙğ6A­¾İ8ƒù›…”	( ¬cO5Œ4/óY2º|ÜÀ9–g^İ:q²_—ƒIÙ=Ì¬ä“öŞL£–‹ÚÑI·¯\!¸‡Åõ…õ¸ß™ë©ı¸RñùÇ=ş|yÃ	Ô!%A‚÷7¼ùÿRK–t\Æ7ªŸû‚‹é:µ=ÆF|Œ ú,®D·`H]%©ÿ‹]ìƒ"´Ä97ÍñNËUnB3¸ò§ûóUì£±e¢hZ '+ m×À&!ÌGİg4$švm=CW…e°g˜·ÙSoyÃ2éæ+ñe£Íqÿ cLÇ¤	Zyõ‘sõ¸•f©“\©Ìş·˜èšæ'ÅZNmÀÁhè›·/&ÌÅ\WÚû
3·óÚcƒ<1Ó¿ŠÓÄˆ	ÕGdøÛ«»c„ˆaî€%XF°Y‹ëômc1£¾
¦+ëåı% ûÜ¬®ÃÈÂ[=È_ìó¼¬ŠèVš€·É|ãµ¤€úhŠıR´4…ím˜1ª…rô8ud"Ø³¨gúh"Ç÷„ñĞåoŒÃiF”³…!Ó–â¥“!	Uµİ’)êš£l‘ÉX”ù~}æA”Ì/¿3·öûE½ù³;ìå³R—
C¤µÆÉVcÁ²lûı'j˜ :§ ¾05é¡IËªÍ°xè‡(U=Æ›Q¬Øeú‹emß@|ÕG“;ëF:-¾@MBİ5™äKIå–:àŸ,?/e&*éUêIC+¾Y}Pzˆr/fûèşÙ`tÌ3¼å`KÁd&Q…‡JªT‚\*ä¯€«âPIxA/´HúY†4´à«ù	G•ÍÙ{„NR*gšmMÑüâofçV†*a¹UrŒ*æ'L l _İâhIÄ_©ú‡Y^t1¤8Q;gähUÛ±’Há.¦V»ˆËÉçnò(ÆO‚×†Ü)íï47Îê°(p#ãôß»~y
)“n S°©ùı˜Kæ(µ…Îh«—+›Şes"’©ª¬~Øm)÷¨Â ÅJ|ó‡*Ğ©GÒ¯v;óg	A;ˆÉ	=0¨rÇEÀ„AV; ÕË'Â4çålöBû'©ù¹bHÚ³¯°9•ààqcª
¶Èw8—ì×ÚIÄ(ä½yz€*M S%‡LİH/œm	õÜŒ¼0B`¬+,È4¸<V§Š/˜é‰)ã‡[¢¾À¥×¥M‰âê“&÷„* #S­ûS‡¾ñ%¡LN†«ä‘Z»[²á¬£Eì\HÆ°I­“àTÈ3Š»2¶ë‚¾’§é»fAXcú)Î	„jİdá©:$tÓMô,7Ë{oŒ¨"c¶mı6Œug±’)í“=unëIá4®Ïçõ…¥,~îtÃˆÕË;ª¦Ü©ÏûrõÚ6Ïxøğ5†AÕÚáPdúc£7ªM+»v`lïA¡¢Ï<¿0ÓxaáÌl0ˆ¬DZ}"k¡¡qV¢M†~™åƒÛ¾s˜ëTè_Á~2ì¨
ÔÆaãBäFu(U ”ù<nĞîùÉ¯rÅ¶y§ºñê~±Ğ)y8à\iÚÅB€Â®ÙšÊg7½®9ŒíL_¿Øót‰}Lö£¹ª‘K–Wı	CÚÃsVà5^75Ú6šŒHı§ —â”è¯?e¥Bï åÍ¿Ëååß¢©ç²H¯­C{°MŒ;DE~32]¨<Ã÷ÅÿMSNkØ°Àô¯~áÂÁC£*úñ¼î>0ôŒÈ™+œ(‚²Ç ÜÔÉÿ¬>àãş$%ñ»ê-ªñwëEvrİ=ÅÃFZpÚï-eĞ<W`¶-èñCÄš¼ˆğõĞ€c´ï‚ú0D:8*½Æ˜ÉJú¼lşŸi¶ˆ×ìÕ2Ê-Öl”ıº÷ìš…5a»”07ïÏşşÅ:=]ŒDñ­?&º‘/BP£B­@/XÙÁcGŸñ	_õÒ˜z¡ ]‹Ş®¾½(8—8œ<ÇĞL>mOù¤î[gºoâsó4gõÂ•à˜gpøüw÷i³³DİÜiõ,ìCb’$-ƒz!sL¡*5¤çÛë]Ü^ô´r2Ê3Daæ/g¹`üjPPí|*ïğM¥G'Å¶èƒ×öŞìĞ©5ÅHÑ±îW1İ[b¿w«Yá^Çbä7¼Sã`‹µx@úÕ*˜FYtÇifgÒZú×º²
@·h§ûF«BlÙTîÅ”<Îì][óƒù"T/.HFZDªMÎ¾Ac&âPÌ:ÊsW°¶Ñ¨>y¬æŠ{
Õşğ1|¼ó‰D­úHU–Ÿó`­¤W¬¨æRZ÷È—ËotÉÔJc‹'x†XÛä6‚ñ¡üFrÚõ…+„âÚ2ÔçŠˆmú`«_Ê¬ß]öİJ jÅ¯sxegS°&­ê.§Ağkh||Å^²]p{nDÏ¾@øvÌ?`h,Ñ”©T9„Î-Q#ë/a¨=´ÃeEğŠö7Åë;å˜Ú?pwy0º‡nd>SK1Ğk19Üt~¶º|v[Î·Lí€ÄË1ç&Äº*	îtònJ‡¹ò•ŸêèjŸ#ç†ÈJJ"E|®ÍYí³İl–aCàvÅ-À®——;?-ÿá(ğÓËCôÕîxA8`‡œ‰ù•0Qä£ğôÃ|ìÃísÏ‹‘ÅÀ€9†÷NL'Ù€êãø: 1µĞ¹T6§9¯êsšór˜ç°êmÀíºÁÙ´î ÑÜ+àcH.ˆi·EM‹œy0î¿ôIÆ2ä¶¨ä«^Ê—ÚÀïİÌ#Tâ<Ş=À³£5ïÒ•1˜*;Ã«&U¹<c+Ã„ÆÔ¿úî7Ş#ø·ÕL( 
*Ä„î‡ ş]°k>¢‚æ’_î— ã²ù¯`+:Hñ¹póÌzsë>ÛÓª…Ñ
,!CHÀ-Ÿläq—aßÜ7A§±OMË0uW…ËÖá¾£ŸmM»àÔ!¯©-‘Í³øy“IÇYHŒé ¹˜ãß¦»KöPyG‰¼±ã	ÂÈsE„„Xfæ«ñú~—Fvr“;špÄĞ½\Q¡ú,Ó2&ƒKÈÌu2Cü	wjwïİ_½Ì{ïL§`¿‘ãh¯ëCÇ’Èˆ/û‚E¾ÆqÀíÉP¢¸½BMÎ÷‰{?®F¢‹ı£^İn•_Í¥&uÓ(fØAFjÙ0øÎ«fˆ(€4ÉÀÀU.4³#ú©Ñez*	î»ÜË‹ú*Ä”[ğ¨#$¨”÷Ì5 B.ˆÚ1Œ×|Æ“²¤H¤B^…š-„}60Œ)ëBÄµ÷İ4ßÊ¼ï¤Q´$Š:èœ.¹`ŠìÇîjr-%ïÖJæmÖ»’pB=«|—sb½›2;Û“íÜ~D”Ê#m•éçª§NÒUiŠØ¿®ØzrôÅÔãÙ—¶É¿ÖvB+õeRı’¹ mQ­£®«ŸïMÔúÉ‘§İıÁ£]©~ÿ7||ÇÍBL)ÌÍ(HšÍ¶¬„}ÌVERà«°{ädoÂ"/\İ9éãˆ¾4İpâ¦õ…zØ„ æş
{²:’Cª:	ˆ»P¯Ûğ´:r~S²Z‘‚‰ñËª.Ø=Õ¥å|Õˆíâ¶

¿)©\´s—ò‰ §æıŒ²õ#ÕâW3~à®L|ySÆe„XáìÎßb=VÂµî¡õÔ«çir©‘éı-9x±Ei‹/—ı¨Ù3¤a^‹‰FnŞğå¡ÊÈ4Âc:&1bı‚gI‰Ï’-ûth\èÒÚ™TA°s¦ÕtXzØ±] Óñ9oS:Õóœûû(ŞÏnFL&Åmh·´qŒöH	Ş³şî(ö|T9Ğ‚ƒ¬£ìº@€²-~Ùr»!ş#²óÇˆ ~Š)NkºŞ»\øåºpKsôÈ²ÏP/]Üë¯» €©eİ‘H\6ß‡Ø¼al;¼:æ.¢¡R™…¬Ş3§W¾û* ’|Z]d–@½¸V½×Ûvşg|5©«D¾ÿ]Hd‡^²æ6JNKíCbRo¢[pæáı³‡iÌ••s¡çxùIÍRAÍşÑ€ =JÜ=Ÿ.¥ Şª®›âaÒXîèïyU¦¨9^C·ülM»äø¯û1Ñ*?ğËÚbCÅÄNSæU"Ï¤’À}ãÑ¼ÅÍÅ·”F+l'Ó´±ª”Æsıoå{p…zèŞİ>WfÁ{ò%~ÈTLìF5ÌûºWãú%Æˆ'ïSÆ­gmÀ„`³á<3qÄÖ‚›÷óûç­Sşw²Åã*!´1ëè˜¯Gœcğ(›J]æŠÎfl$®ÀZq4<yİòi1 !A¹„Æè3bòMŠZÎJQ\›obwà3Q±§}PnA6¸V¼ŸêÈ:·XœÏ” ±‘WYC%Wœ“J­3€2»©tá7$î	ˆµR\fqàpsz{ÿñHØE#‚/iËŒ€”›¾g³bNçm½Xs7Šßz£«íKiEL»Ì?ÁÅÖğŸ²5¬¤Ã}íİ¥4¡FVkS˜_—/Á-ìÍ×Aô5JUô³O/«ßşºÚáÙÑ6˜ÍÒ+0ó—Ê¨@m9]ÿå«ä[tn_OØÆÓ$K°Ìo‘ä e¶FŒT¦×5Ï‰½¦ŞD°?\yŞGEÊ„¨˜¶:òÓ7t“tçÙèÓœÆ®éhTµ\5fÛ¿zªOaqC¡•“Ÿë>>L[[Í@ÎúèâAt ·£&Ò-,95`Û#yèî\ÖZF`¶¢P	Â­— åàVHÒŠPXÄÏGh"¬{£’ßÓ6"h¥‡ºîÛÄm¦Nİü/X1´<‚âğÓÏìY[SŒVÏˆåÕÏƒBOş©ó=cs‡ÄãØÒïüş¼®+f)æMMé‘n|bˆXé°­¥õ$Ã9ËÛJÖeÅ»1úŒÚ÷†K0p—\ç¶ghDµäÔTnœeæ;v×°"Ç³u<špŠ5Òœ¡Xqv~îg±MÍÀÃÍÈ@‚AOBâßTÑñVNlö™æ€ÀS¤ƒW‚ãq§«¨;ç&
›„gÄyã:Ğ‰j÷ækõ{;à¾íOö€åB¶qÂ”ŞëÕèëç&9æ|	O]>çcb&{~Œx›Ä$JƒÂ¤5áÅ¬q¯µ›Õm6@°ú×—™ à¿Táä^gü­ *Dÿõÿb¥.ùaX]íu€>¬šéT] rÏkkÙ%á-_™†FİR¸Ç%›Ä	D ™G2&:]Ìıò—§¼Ô‡@ˆ²3æI‡İÙ—ÆLT˜®¾)ÜV ¸F°¸w·ŒÌß¹3¾Â@Ü)#ÿG²Ğ >îÃ‡C°qºUzKõéğzï@˜…u=SV÷m$0Z4/•°|ğú¾çWœ¯Ğ’H¤FÎà+Q/ÂŒìºğ4…«Üáö¹¶T½17F@6j¿l¥+Ù‰Åê¡Î8]—­ƒû¨»¼Kªud¢ıˆ?XØÏ¥1¬^Âïé\Û•n¤Ï[öÿ&‹G1V”ÕÄô[ûÇ0lŒüˆ˜tíŠ*âU§iL2³¥hÂ;vyåbˆªàC)–†òïÕ¤Âñ¥„?(`é®•ëû1‚`‡•l86ÀÅ¥9U{sğ0Ö§x[Flï«+óH.şï¢<ò‡Øa‡›•?ânoy—ÆŒ ¨ «‚=ÁĞÚ6
ÜH…mraÀ:ÔØ°fiŠâ‡ï^ìŒ˜[¤õÉ,Ó¦Ä-‡„ô»©ÑXLn} Ç6ì”\}~iÉÀÛ†’Ûw~ÑL“Ê¸¿«¼Fÿ‚ZƒñC¼^Ÿ™H#¡Q`b²ãÓµŸõcKõ('OK½–§oÔH!à2õn²@N“Á…‚aIt›TÖ2”ç@î¯¥+…•Q£š]Ğ±8#Rg°ÃcÇûü:$!ô*Æql¦9ß¦ÔÑs›D^Àşhˆsñs½/ÀéÉ¸•2õ«#›Ä“ÈÀÍH±–·fëñÊC­(`ğI`Òò8=™DœKa~sBw‘=¬š·ác`Ìv`q”ÿÑDÇ>Må}ÌvyM¶-Yn¹“~I{È¨ª4Do§ˆ£å$*©ğ…/º1…±Cs¼à¾ù[æÃ?®/¥nË™'}´Ïf!CP(i›½'å%Å’Ï¢É]¿‹ê	SÄs*rì±mD©vÆıÿ".S¨Rb™!Ò—\$K<Ÿë¬^œoSãM¶ğ ¢uë¤˜?ÿ8A1ÇÔË[s«EÚNßä^…FEY™btRX‡î.ÍÀ«$·6A±Ã%xí#øåXŠÔFæEÂ°ì¹Pà±;ô"¸˜3&ŸF¥aï»äy+´¿:Rgi°/¢!ıMªd34½r„l~[èêÚ›¼àruß»:jÏ£lÇĞ_N•g«ß@#ûÆn8
\nLs7C Ô`tìØàKĞŞ^ru?¨Å JÁ
Ü†ÁgèpX…:¢±à4 ÜAFdÕ¤•(–qo3yLi??k†aJÊ¦yêHaD[¹á±Æê;æà;Âî‚éø]¦"@CN¸åLdL‘jºUtQ ®Óƒ$¢~Æ§Öwœ€Ã÷
O;õ02=TV{kéCíL§g|ê†æÈïÛÊô½¼÷e1¾C¦ƒ	—Ÿ>A»G£«fvP™C8ı²·kH»ôTéè‚B$˜_¦ŞC»§§CÊ®JU3CÊ%]E£í@s>ÍJ,îT#Y<¼ˆbÅOE´¤Ø½†Èš½³pÿP}Ò‹ÈqÊºrò÷mgÚIDÚt!~.SŞ~
¾O-Õª–
áÜµ˜c‰Ünb›a @×¿±ó–ëÎÂväPOöŞ¬ ¯F	±E"Á¦W†GÁ[ğˆ+,ïaü€Œšß ¶ØG³P#s…<[£h¡‘ ÒÙÆ3§ÕÑrèiDáj™dq/l
nÜg¼¢Ì	Ûİb¿ç×1Ò)Ş‡¹÷f5«)˜|Ğ~ô‹ué]J6Å44|-LşMİßÛ¥¾;¼Àÿ9iô fAnÈ¥“û^_¸×ì–¤7Z«4?Ìöï€x¶	štÈ=NÀ˜ ”vÚŠáŠÎf@0ü]kÎ›Ô$²¸§§÷ÏğE·Â‡’lò´ñHÂç)«Î1ƒskYk±€ ëÖ?ÏØoÓÁÓ:³Ïvk&N%•Ô«ÿ®èU˜ÅæV§7Hj2b¨åP¤µò	™Î$İ@éSNÔå'm¤z‚Cùvê|Éó©&E+Œİ(ü”kPKùKÈÙİòÈ—½“u—Zş­(:y©3‘»ÓM5;¹…ÜÍéí]Œ¨@ ‘AOú_´ å•¤Xê[¤‹ÌAïôeÜ©X[äÈ}µ–Œ­¥iøü$æÖ=ñ¯d7×l×ÏmÖ}Vpw³¨«ã9#â9UKLÏ>Š¢;*xlœ¸ş}rßUåhAfäê²æíâ1V†
ÉqfK—ŸwÙ"–ÒïÏJÍ¿ºZ‚dhç¸ÆÆ.ÒdØIú­‡@&]MF¢ö[Móè5xÅ…üønaÔ•B¯èİT(Is=@>ª—€Øéj uõºaúÃºK±î£Û7Ê€ŒÉš¤Ì×À‘‘œêqœ0ù>DèÍ"3kŒ ÊŞ]ÔvŸ#éŸ“o}¤a§ˆø]^Ä ¶ »\o;¼CµG}E£›Ìâ<à“ç¢‰¯\Ã¹jÍí»İ!±Ğ$-£qJMşB\8z6ä-¬‘Æ³>ó×1¡éÍa“-<wÈJ}£1r,	`a³¨
EÉßV¬éWxå}Ê–ÂaÈ¨XoñhX7§YÕ5BJRv‡<c½û	f‘MêôG½¯ØyÄ#55c¨o]F”zï3 ÈY’x)&
[šrá†Ãs*?i/º¹» ê6;nåóı0}Ö<UAÈ?*ıóÌ§õ,#¡*T»«§Pt†{Ç^yGhÈ3çµ›ß	²àAcÏ^¦Ì]R1Xµ‘VKãP9¢ÃÚ¿#‰:Ï}läìÏ¬ğ;×µË¢È}›Ş6Wö´cäo‹kD®#\ò!ÚŠ;ôÅQœ™Jv6®»1W²n°e…œKâm
å–¯_[‚¿—Bˆ¿Åı38kò’bí_ÀÑdª¨ş\¼âw¶²,ßÔùL »—
âiÏ†I8¯7'a¿GH/·…Eı”Ä±&…òÆ¥›xëÂdu1:’ü+U¥4ÂÅår·"q×Ô°ºÉ»)ø5Ô×é>å‚Ii˜²KbÔø)†ÓÅ± :ŸÈ+rF_ü¶DšÒ”Ú÷ ®‰ğ•„Æ×%´‘M2“,DIÉä@À8ûÑå]ÏJÍö×ò»7Ÿ¥´ƒÌÚµ>‡tıl¾íˆEI·h|†}rÖJ‚§ùM›—é|q^øÏ˜±WdäréTyX‘Ûê­´€Ìj`å8ò²²°¶1íÜØ×0˜ÍÊwH8I™ß’0Ši4àeñ¯üÇeİZÅà¤ŞÜ†gA÷÷Òü¾0ü—Pkº:«Ù@Öˆ	ö.Ci.|gªú€»Èæ=jäŠ
Æ±‰6=»ı¢a^¦uğ$‚&c#3»§–éCQ”Ğ¶»ëJ¸(ê"@#½äÒÔëR©U2§¸eP0k†jªímÌ'¶ìşòlóÁ&¸Ø^„SHC^!^\ÄıœçÔ_°â)Ñsy’QUä‰1R¤‡å’Úáû¯ùû£#Øv3V´ºNó¬*u7º$'o)ÕÔÂ¼¹­‘ &K&,~zà).¹6Ã?Éov6¾†¾•îß€pÆ¦|póƒlşO„F®–ÿ ï/r”PçkÅİ¸FËcÎK´¨:F!«D¸@|ÓHc¡ı°' ;?«ÁŞpÖY%nÂÃ:)×µ†ÒğÕ#ù8»\“Œ³Õ®%LÅ
òàı*¶xï²i3Æâé~Ğ¥M®€¬ïBâü÷ÅfŞ`œĞ-Ö9ŸYÏ»@#°íÂ.BâØ‹Öø+À´‡pÅ‡?„¦ºù˜‹_é.²‡ñ%ßçKÜ€óĞÅõ­)T”ÿíüº×û¾Ÿ"šg__k|Ÿ¡µêŒ ùùæl)ÆÚ¢Tã“æ2êU†[’ÑØ•\×Z*W×æîKï¹ó€¹¤VfÆèTc3UÙ¸[Ykàİ¬q|ÓˆrNœ\ÊM21—»Í7øW0œ Pîd7Æ(÷=ö-$½œ Èè"ºmßX°ÚÖµòÀW$ø·<â~İÄ’PÅİ}ÓIöGPµlşĞ}ƒıêæ¦,îÃ€¯ûâ¬¨ ãIé_ äˆ®*½ÄZ€AŸrÏU:<¤õ¢ÅpËB,2sk·ÔÍüÄNpÓµ\ĞŸ%¦çĞÈ7‹r²ÚI‰ÕéL.Æÿ 1e¡pêÊÔ}J6×&—kñØ.Ø6mºµÅ¨ëÒm9¶‰^·•úeÇ€Í™ûô	âjkzLÏa?xÎá§2%Áx6s((€«¶^>{Æ”’SB9#ã9Ä<QƒoÔ¿› ØÕÁ&9KÂ†t>?—BË¾·ÊzÖq§œ1cË¡¥T=o\‚Æ¤Ávs-2o»ŞJˆöî¦*ª†š€3š‡¨É®RĞé¨lÜ¨&¢×£%Ò¨”ÄÙ;šå'ôüR(Å#.ø³@˜Qçe(Ûggºµ4oV¡‰ÔZaösé¸}jé¥YîŒŒ‹(|4X­xá^Ë<yöl½Éº&¥„	SoçëÒŒ9L|nëÂdÍ:“¹Ì7|A×$òi9p(îÄû
ØÀÑ§Ê’}Z†¡ÙxQÊWéÅè[âUL*²q…iB‘^½hAÛ#Gnj+¯ƒ°çÌ.vS¬Û4ª¥]êd‡ãñ¼Ì¨úU(è"|Á¨Êl—-dw™èÄb„½ç'GÜ* ÂN¦Né~|²ß×"HO¯*Å,ò=}Ba• €f¸Š`ópÿ/ 	Vô]ÚH(°ñ8½Ì	±E§æÃ–ü6¯(³ÆĞqQEŞÉ=¸%Lrœˆ¢#ÒG(”Ì#¤ÿ·È€B¼îÆëıšn*Z'’|^Vé‰ÊÌ(}—J r;GûÑ5ºxL!U×`n/î U¸ÓÜ½$”mu¬´ÖÇüÚÎ®İ¦ó¨Èî|oz€uïóYL»©x`«ïZàÆ˜r:/B|›UIh|«QœdDø¬£ëîô)A8X¹S gQº²÷æßá“®ÁèÌéıFıYîÏ¥ƒM#,&Áåxˆ´37t"²®Îl;ïıt…%pÎñÿ\&xŒ.Š7–5$öpl{m€‰jòó½å€Ó±û…/%¿\-^‘®±¢ÃÛÂ ×i½m7vzíWïÑ’Ï•¬º·£%z­Xo áEömpûú¹ı›ÆÜğñWèÔ«at¦ ¬ÏÙ,|õ¡¶5ûwÖh¶Ì­Û9)0±ü¡­JÈµŸ´•DàÆmxÄ,¿fá\âléÚÈ”Cúá¨š	=ó%ï5•§“£”Ñ®/OájÍ¦Syx+ãqt®çd.àùq@‚@QÿNáA‰¬cˆÕ¨V€©	ÿt¾17ğL~Ë:¹,²àÑÛª(ZĞ@CÏÙÙI»¨<îµ´y2ÿl›Ñ«ñ=;I\g…³ğ™çÎµzÕanG¿OÊpğKorË‡fÍó“M±&t`ı[qf¨õîs: a€¶nµ |¦ÓV\pI5•§ÿ¾/5~&~ï¤?ÌÎ™ê§cbà‰4‡ìç¯šD¶óí¶¢S©¼›pšÆ„òSßÔ,âHFx)óVqsF{ªŒBDa¼ŠeDî{úê…q±€\rÔ<e{€ğ~û³6ø*òû©ÍÈæÉƒ)}`çqqÂWõ9x;‰ì‘Ğ•Õ¯ûïx*|_””yWpÓÒØ’Ó¡}" @_ZÛ’tóRÊÛRõFµvõRe»ÅZ€LÂ‡Ô¬n¬‘¢LDÌ§…5œ9ãÉIPwˆ|Ïº¡²øä"\Nü„LN‘>™¢ç
æï­™ô¤[åbòÕz³óšf%uZv®†£ŞgZ`†˜7Šf¡m	="Œ'õâI"r(3~>Ş)‰ĞÂ©9½‡ñ®Ø‘ĞPÁ1ôŞz´[Ÿ])Œ ÆÓÆ ÀæõÛF¼¢<ØZ–ïæ<s<=¦‚N?u°£Ä"z²{Ú"Üniz6¥êš2´AU '„°“ipĞÄ`ha¦­?’¯A~Ìk¶“}álÈ`E!İ8SÌùkÚ(µ®P’¡â³ˆ"ìñîÖ–ö7!}œ¤DAÄ
hÂ¶ºDxöÃ|ìAç@*ô/Tk¬d‘©wGzûğØıí\}£Õá}””ÿ7’çˆ¿´7_¯+æıC±‚µ¸#mS(­™TìËÌc¨SQ-WXñão3kîrÅğ¢âW‡µî<vYbT³³¢t++8•ìıMc95"lRıU:4TĞy"Ñu'6ªùG÷— u•¦;ŞüÚãê„š”c;6şya)!g*I»ítz½ÍÚv³¦áÓuÖ€ˆ_ ¦ãu-ÃÄN4r£%Ãªâ·üv3Æ+}ÖJ%|6‡L•âå¬G%¦…§ÇëíÙ ‹Ò&V÷=½ƒA08 ö<HŞÓbË~xÇéC/Ï—TnœCì-k=yÑÚë#Æô
E<éMNb¿¢ ="Ú_ÃKTıé›Ï0xö>®KÚµv{¥È	çŸŞ»óû³DhUæ2›˜1ó„uZI\é6”G‹’„qåĞÉ`“€n‰=_<RóıY4ÀL––¾À­mtea›5v{ »±VƒCÂac±– ï7˜R²ÇÏJUqVôÿl†§6Í„0Î.^§iäf¿V©î‘Ë>·pÖİs×£z™v9Z¹©÷Ô#^İgÀ‚/™Qšz—ûy‡¨ÀdrVV^G*ÉŒcóÄC}ÀÀmö£èHPu8…Õ«9 ë,úÎÉŞFø+¬¥×Z¨•ºÎ[çõ„ŠBc¼ƒ^Ÿ†ÔLÃ‚JŠ7|-bQÉ¢È”+²ú)¨SBÕboK¼–¶Ìr™VcìcGcÆX¦üÈ7. CĞeo(ı»Š:$¥fÂxk`é<kÔëEÄîÔS|¢ÿüÇûp†Ê‘ì4ò-áëãœ•d	;@¨*?¨
.|Ù+ƒ”ájú­ÂT¦—UÀ&;œÌõ‰ö…Ì@=ÂwÕá-®l4u T¿‰O8@-×r–g¼Ç›øp="9ÿ'X"Ñ¥÷ŞÙ3o£ÆÒy7-Ø….yjÌıIW¢çae»,j
iR-Ô	%"É¸¨V[GaìtN_/ãM½É÷¶q-7ŸÑ•u­k
0ašxsKà´&¬úì	jÁ7´ğF—Fé'>íÌœ³ıY•µÁ ¸Aøº±t!!Wä¿T»(2o59:À~Éøv¨Ã#¾2ÑwÀ{ZkãŸ#’ˆ¥|È%rUÙ©+MŸAêæªmmğàóõ6QõQWùÿî§…è‡ÊÆòmÜôÎ'¨l%ïİã'´ĞüçÚ/@ËD9%ÔOñìíœ¯¯ò¾«ZW:Ò|’ÖJ˜ıRìã2úCÍúñö ¼é—	85lğW/–+BS#__×±ÊãÙ sRT|ná8ôj‰7YH¤î„d¬Ìµo€õÓèÆ«·—ëcG{ëÉŸr:=ÛSß~ûsÕ9û×çy*î·^äh–ßÈø·ë¤ÜÁÂ5Ú‡ ¹%²ËIPPÜÕE¯˜ÛhİBú’êM`í¶´‰§yÔÏJn	iaÈÈİ*š¿VŞZ;H¯c¸·0V÷´|¡ÜÃD@×Á\e¨Mxµ‡á"Ğõøk«úÑ“³‹ú€Á‹¼¯JÊ1Ñ——nH-®Õ?gÍ¨ÑâZ`Ö¶m.iÏˆG^Á¥Uæ¡^ß-v‚òë!ë¸tœ—&„ëµnşÔFGÀ¬º¿M–Ñ¡è5Ş°©pZl­ö¡Íbå04ï»ØfT¦‡^YêS*r‘Á²]å¯Û[ªà.­³Ø:P×y¬@{{:H`¿w½’¨·3ğèR
qÙ&1VÊĞâŒ©µ™{nı‰7Î¦´ø‰*$GÈÃG¹a¹[Ú‹8G‰ù,w*I	E„zU-¹vN_ÿSğlyø‡ ä&‰Õ…àAİ@cÄ Î0ü¡[o£àÂã¿Wgµ”—oNˆ ï ?áĞpHĞ t9äÛêFV.ÎP¯÷³981ÕY¸|üåpƒÒiwè¼Ş€(ƒ‚Îm8B`ã9ğ¼‘Òõ…í²øì¨XLG·ÃÈÊ#ÙKTÚmP.XcÉÃ©'Š™DĞp)DS†c¶ö©İwfQâ>qùÔ2õ
&°öæ[êx]`Ã¢;ƒAç=Üº‘¾¢%qˆv#*É‘Ku!öúš–í€K!õI%(ÿ²1OşNancOxRuŸX~Šdã»;ÒVløœõ,Qü«j#s¬¬È‰­ÌÙ0ŒeéQ£¹µ^CW³{ÜëÂV—{ƒ|Fxõ™By!eñZü¹^—™¢oÍi_™6n	†´ö•­=Js×w(÷«2DØÍÿœ1íJ|~ûøœy8nªÃmÑW1'­İ‘„ûÙs½®S¦Ï¹*c\c-5º˜¥Ö­LU:[iáèp\Ì¸8ƒq¦h”&Ÿ¥NìCsĞ¼*Å²~ó«(_††¼$ŠÌ1]0£nVıïÉVš9Q²ñF9RÒ\ôZ‡×±J“mşÁ_Lkì@S•º,¯–04]µÚr¬³Ü¸T,^ÎŠpHcÍ1¦Œ^Ækwã­§0€:)T‰ôP|e’zÆÒÅ³LŠJ¢H¯JGÌ£gD@{¹¸)Jşy É`ã»dÅ§
7½AÛ\u@k|Ô‚Ağ	ıêœY‚øHg³]¯¬/`û{-³ÜFï:±e•É¸…²¡¤R¦Èú#iÇX2­™ygRUı€ğ(ƒ'¦¼òZ]]Ïç
ì9NwÎÑØdTQÖš=°v½[ï(NÂ–Êœ7¾ÜÖ!¿¼~ì›Ê…µtˆv¨‡\
<Es«xz×´²…IŞ;?´Œ¤!ç¸h —·)üØ¨S´‰¬‘ÕñçÅú˜©wTçê1b€¾ûkÚ”ğŠ•ƒÌßÀÓ2‰@ßìKä3ÿ±Ô m]E]ËGçMÂÖéU•}U’®6ë-^‚E{Š²‰¶['M	ùË«©œÜ¾y`5Ã®¦İ½}y<ª(e€>³uã÷ƒìó#ÑW“ä{CƒÃû´¹©Ìw**TÀ>Ki¨l˜&c"P\ÙæbVÏEÛğxV@~ÒéM¾Á¥bÀ‚Â~¶tÊ~Nóèpfw’E«üÿ~É7È½0Š†ŠµóÌoÑÿê«®(0°ÕDÔ&PjœKKÀ(åšGË1“&¤ãh[{Z.xÈö>U¾&ôëmğ¨"¦i‡S¬æ»¬Ì‚ì¥äéÈCö‰î Ş"áÌp£Goµôr¶¶ÿ·^,©;ñª
ºBaÆ¦L‡ÑCpB"×êû¬Š“aãNoŸy}ô_ŸâJefÙGYñ^PÉ4ûšV¥eîtø‘äº­¢¼ñ!¥ıº>y¹¿\'jU 2»ájÕY¦!Ql^Nf÷=í|1|oğÜ›¾âöƒ¹ªŠşÈÆk7·2Àê¢Á’Gá¿ƒ¼A´úõpU	Ëó¤¢w+>‘t\çç§váˆD¿ ÛCŞŞá™áû2ŸtÄ¦‚­>Ğı[Öíz”$Va%èË%aX®Mûİ¿¯½­©›Ÿ¨ù:^9&¡”¹m·òÅöO0bRª^eHX’Î3>§»¨(£¯5(‡^&\Ú3¶v.Ü¥oo!ÕfîÚm¨Óû~ßm´ûİ=yVÁâ84Ò|"8ÙÂK	b©Ø(¤.¡¬ò¨½l‘¤¯¦ø9º‡XìHTİÁ±ÖèÂå¶GhwÕÜ:±˜V®/||®ª8òı‡Ï@ÍŞÎ\Ù+Ã®q³,F2Ÿ_ qÿTî·|kıLxÜÿæt2ÿãäw4İ"§jHåÇyÓë1]Ïàı5I¶ƒ1F+ÃÃëëS”g1ĞWUÃMEÏœOÔ$BVÂ,¦¨—çˆ×ƒTıÌ†íåõn´ÈÿşE?Ò4Ôµ”V¬»V¨qšÁÁJö›úz)f±j£®C†Ámr'ôMM¯ÍŠoüÏ©@x¤O9t0-?ò¼n<‰ì‹ù#ášX	~=C-A¿ôı:8zF´&“}›ïÇHsÅï{¥(«„‰5vûy=—¹¢¤ù²D…à1×“	DWûp£xV×òFíÉ­YŠdœ_˜t)ï¥Ìw%4Á(àÚ>*Zlç“»ØA·c]-3´`]Tl™Š³Qhæ¦P—[ãpÛÂêõÒ°›ÒO=’)UPû†[–ûÕ'âAfÆêS¿•´§©ÆoZŞ{ç¥qÃS¦ÆÄ,™ÿVUû·]&×®«í±‡øGì3ÅH^wú/Mî
œWkíC-9Ø÷ÒÕ²ûáƒ PõßäTAÑ#Œÿôı
Ô‚ßz.°t X•û<ä±’–ûË&ª‚Ò°•ËfVD6EßfRğ6—„¸êÀÍ¿Î3b‡X ‡¾Ñ‰­B‰3+TD~IrMl*½\’ç‘OfçmW»ä¥Ä¼8„/?Zi3‡   ¡ÿÃ8©;g ›Ç€[xÒÉ±Ägû    YZ