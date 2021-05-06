#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="616436439"
MD5="2066b3759315627feb25c5e644a79fee"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21192"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Thu May  6 20:32:13 -03 2021
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿR†] ¼}•À1Dd]‡Á›PætİDñmJ%†3çï‚µõ¡Çä·=í©²½w0Ñl…/a´Ï¬è½<%.€_^@¡­À”ÕnèÃZenù6DOÅ^äÀ'ÙÕAd„+hI´×kq~”ÿ	-¯n¤hˆY)µ†¬ g›^:“PvåÓ<ğáso¡h£Wê³R)@qãáOtI Ï§!¦´7×=Ì±g&ÊnĞtõËmÇ7İ(Zj}È’/_Éã™]®ÁLf=ùd‰¨½J‘§ß¸FH¼ïÈVD Æ/H¢ºœ”(DƒÁOaRô Z¡Kıs±Ş~5.?w1åÔ8ml¥qƒ/ï R×Oà/šTVv­áUŞôBèÖºÔDÜ¡Åös[Ò*ovŠc—/àt¤Şöıú=º æÍ»kcOÍØ
ê*Àt´2×·ÁÏ/ÓÃ¤½I=Ÿ÷kç_9€nSš†].^â±#’„²âRšä4¼õû×XÌy‘t•Ùá©BÀ—Ä&·«¶n©»\mò^2‰$¥èßCé*Û?/J‰KùµÃ«~î7ã×êNèãË­yh&˜?Å:7 T¨õ|ÎÀU´»ŒàG
fDD\_O$m9Ê” úñ,‚!oĞ Ò™ì¶j!Ab4‡G‡f q²Qá3ã©’áøãìS‘àrĞÆõ½5¨J¬G¨Ê'ä³ís7?˜æÉ„ÿ©(úµFãEšLç¥¢NÅ˜8?µo™Á7Šı¸¨ÇïæÅaWHÖGî8$Á¸b“S#ã$·–ØR’¨’áyËü×HdH+’è=¸ë¥,mÍo×îğcÕÊx2‡‡Ü©
ÕÆ§fÏ=˜iUt!Z™.w¨9è\Ş~:î©RUÍA×ğú~€_&òè¸´ß²£É	½rGY8lWç#N$h¢‚*Ñ¡àpå¿|Ø«Èµû¯]®wgUËMW—ßÿaôïP‡2>ŠçÚûû%ÿ rí<0Ëg¶˜èRséI$!}FJÕ•ıªT¸åf±(jHÒÚ	d€§=&ë*VybLù¿ò»4ß¤ˆ%0ò6íÿŒÁ§&–è3œ²O:¿?+:<°û¡¸Ô‰ªñŸûR>ë›gĞ ,# [g÷¿ër€)|e<çTª›.`ã[¦¤Û[–@§cLÅq]~ñ±—S¶·Â—ÉÙcœnõD[(µÃ|«÷‰‘9xºS’RÀŸbüÖqRJèU@[òzÇ=ÕgÛ'úì"ƒVxcpıÀajp9¥²\/bRœÇx.¤ªzƒ	Ø¶°ñ+âÓh).xUÒØÇâh&P;
lµÛq÷ Á!8—ùšÇ)tãÌá>X›¨¬š„^q>“Y=ñ8±PÏ•j™Ê×™¿¸Æ†{Õ±İ6¤ ª.BÉ|ë€Z‡šíÈö¨8H©‘ôEŞĞèzİÌˆŠÊJØÀ0èÃ°…ı§s¡oİÂbAh€´¯fæ´æÛ[‘Y¨ÿ–Ut¹l®ã}H® ª‚_¸Zä§G`»*mè÷ã>(’m±ì’pL1Ü·†éôê*¬Oà¯“€ëd¬ô‹E²dgR}Ù-Ï’Ö5ù-Å3š—ÈC»›Ñ§;»QÖ‡li=ÓKˆµ`­ï?EüÎÖH>ß\ÄS*^ŒV«è¬‡¯¤ÃË"ÓL¾õPßfØgÏïX³1>ç»¶	{n°Àó½€¥<Ö5K,ÁE0Ü¸\6ÑÁèŞoW­„¬G½VÂµ·Xùfê-¨«§D°°5pƒsÉi× 4ÚküæÑ®JÀ¸Cït€†ñjŒGJõëlv‰²®;+í›>ØìÛ.¨ÆµÂ:CU\„;q¾˜LÄd,›kãØíš	ÒZ÷·[/b 3¼WA¦ş5oÎ ÿÆzXu­Â–Ğ`ñV Ršg”hpÕ^õ–Ïª³ÕÄÂ"'êA×}zøÊŠ¶“_3gÿ`»02&¨Ô?{SÜIWİ»p‚!–Àz„k#Xm‚|\ÁVyª
Õ4¡œÓe~ZVÚPwA®¦¼N’FÄ-Ö#³¯ËYå1Àû§€¢÷°Ìõ$÷¸½"U%E®‰Å£†“„ÈV¾/!ûw3’í4ì]\\ÍLvÁPŠf½ˆ-%O&¾5D¤¶ãàuá lX‡^a|lŒ-=óåº›ãåß·kõJœ]YuiòèœP…Lª(ûdé[4ğÇ³Fä I<nÄÊ©ü„§\8¹˜°G¤ÓZ¢ŠcÁúıá¡şâ_qòqÓFë5˜ùÀ`!Ì¾“¤-¡l´Ÿ&©Ã ­VÉŸ[ùÏáé«Ô>“‚]¤oPyüõg%º®tî[l;°ûœĞcÿÌè–a§-Å)Blè—š»láûiK~9y)R5TAÏ5´f]6OÀùñ.cÚ(¶""3©ÃnMt¿-ë6Æ\ÌÎYÍ|ZC4&¤.Í5júYİÜL`i˜"5œêÛ/øš2ÌÃ·d~#@.÷©"$*ÿ'÷¢õX;Ë+íEÂóİÙö0ü•3å¤Äc¹àWƒP,·&QBíJS–ø±LÛ XªÆ—´Ëëš—8;šhQ&mòRxæ€5GİNÜMÍ6ŠÄºü¶6¨Š÷eÕ<·Ü‘>øy®¹&ÆÁØrÍì›vÇ)Ï”HQ- ç«`ÂÛõÔ“›êaB | &quØa~æÉÊã›«]S`é{±ëW>šŠ‘êâ‹:møñ-áUV$,Ã	 Óíc”‹?	«©ÓòØ7	0_ÕÛm‘¬Ç÷l^Ş(´P åp$Mn\fó¨{cåŸVH4•’¹}V@$W‹·òDÅ<yÆ—,ëd$ä:‡£ÑG”:‰åy~úS{“MÆXÇçIp~Ÿ‡4™ÂÏ[ZøpÌîgR,-…§¿úTÌÉf«*
¡ç¿:²ù‹ëy¯tµç í v)1‹Y}ÓªŒ\æÁÅçR×¬‰X•ŸğZvb—+¡ŠlÒ?38q!üKCäç¿’#‚ĞÀGÖúØ$Êúñ)…ÆªœéX‚ş]1	 Sà—W´¹.}
4§—£Ÿ;ƒê•êÇŒÀy½ßk|è¾Í ¾Ì©ÀŠ®½(P,_Â¿³Pv)Îô™z.ã53ìUT Ğ¼Ş[8aÓ¯ à8Ï”7“Íú?Ÿv”˜i¾uÄ>Åc>ŒèŸâß}·Ò*ğõ+5äÿ)iK9WøÚ®hãúŠBäÓ6˜uïĞHTaøF&¦Ÿ7Ò8“ ^<sg|²/š¢dïQQ! §»‹š&]Ãáƒ½eiœø4ÓÍÆ¨oóZxR´5‰Ñ!%œñ‚í|xhHcs:—Ë7nGRl&à£ïŞ"(¦Ó…†”³Œ²o.½ëÖï2öR0îû¾±)ÆÔ{tŠ—ºÃªµ­B¬Á’C_,ë‡y=F<¤B#¢â'÷:»9™İj»¹i¨YÉ ¨5CãÌ’9l¸TË5Š˜}Ÿ‰·šŒ†5*‰|Æ¼¼ÊC\ ˜…–d^V$Ü«hDs'3=·\Äƒğ6j5€P9ûÂg‹‚£Õ{¥îO2XŞ3”ƒT~¸FÎÆ¥ÃbÁ”Ã¹lTÚujùÉw±Ÿòv†\JâÇ²”…¶ŞÜ'3†ÛK˜?äÓŞS9	lgfíã¢°±bÈ#Œí:!¶¯Yá99X ZNqŞ„N^ÔÌ¯ı‚¦ÓÂ˜m8gü3KÊ˜ßa|ğ ’¨G…“¿î»TOdº0ÖÎ“§ú‡×{Š:S¤êı€(‚¿è…“ğ8òË‰ò'¬%½ãçrTy7:Jƒöq&àŠqcò®™ãô?:Ú†M¸*¦±†=d¾Ò‡Íª›ÇÒönlÛâÜÌ`Øjº’84ùƒ c*c´äl3›¼ÜºİAËZyûÔ8«¯•³uİRBa”õÓÔ†)%¢®–—@Ÿm7ê$Éã7˜3ğƒîmó×d²8Ï„‹-ûyç‚„7¨Y–«®fªyÈ•/ôğ9”VkQ´G/è(û¤Â§š¸¹a¤²E~¨I‹2Wº
ÄÖeN­PëÁó÷_|ˆ»m_ômös–Ü»Şì~¡ÁéÑÄZiËaGIøH|fÜ‰^×ùs9ÚÎW²€1¡¥ùM!^I¢} ÏV¨ÁRbÛ³¹õê“1ø^VÀµÏ‡á±ÑóGrzW¾5îÂS[ãä‚)öQMë¶ìa®k£rfGW¬côü^M7¢­Oe4—
4©Ö‘ø‹)tÆ…ìx8_Ù__å¤ŞV°I#A~Œ:óĞáÕpî.¾{Ä;ÊdLÿ6·É}5€¸i òš"FŞ«¡PXm‡ovT;¸şà}mópLîãğy›HÎfœå¡©ş’C™+g¦#Fø” Ä/®!¸¨êf;dÖ(kÇG-|K|õ«Úy‰bÿßğÑ¤óş¯uóZ*È°:F­­Ï¤û“¡ïN×Êßø©"ÃˆÆ1:ÙƒCãcj`èWâ«³ÔNzÄŒ Eòğ>NˆÔËÓÏB8á=cÖèâºRèß¦Ó¬ĞÔB–ÈJÖw.CàF:Ä“Ns,AÍñ›p8È¼ŒĞ]+Íƒ |¥ñRzÜî«ó;dœä3-z0š‡8˜XÆO»‚lñÄL¸a„ıLâç±˜mïÿ Uã¿»íÏR,xryï…Ş´=¤ñ¤¶‰O9:&Uh«‰ĞP¢!ëe¯Ğc‘ÁùLä´ŞbàL W|"Q ™	IwÒ
¸D^šW#«ºø¶­NX§§}Ú”a¥¦ÒOó‘3gØ©ğšNÛgG¬KÏ
kƒdÅãÜTÁùjÀ(¬3!W»î/1Iß)?ã›3'Ö[9$×fë²›'-é"G×HdP—Çn¢*Ñ¡1%A’­úì÷•LSjn¯Õ®‘Uè¦ÃäœÊ5©]‘Âh…tÈ3ò¤ö IdÑIw©svçqcê3„Évğ ™ó'xS“²ıŸ;òî•”îÖXÿ–É¢üÑ¥‡ ™ïµ©°ƒğlÜœnzĞ¤Ó8ík»xÓÖ9­qšGk§ª×ó¯î¦4rØŒÖ7”ÈZ­z@Fa&"&EÌ¡™Ç²×gTÒšBî& ˜$«À:€w;¬0&oC6œAT:G‚ÌCXÜt;hq¼y&Q}Òo…ğvÏa¤Jšõm­Á%Œ.Vı¿"†J[ÃäÎš„çfi‰9Ò.rˆÓ¦şÄ=ÁetÎú”Bvö¢DaE°îÅ‡Ÿî ¬v6¹á†ÌàÊ¢Xì’;Ø±×=c–Pf‹çñÈÆøåÑ÷‰Q-Êô˜s„æ‹?™²l3õh©¤øÈOöEôíf’=H°İÈ[˜XOueø@<o;5üdcYó?6Ë‘™zn‡Îİ“¯ƒ«­2gçbËwO˜SëS¦£jL—~F«Ì|”2QÌ“>ú»à‹™Ì<bÏsòÙû¡Ğ¶íç"Æùş2Q¶°åE„`Öèf”@-iDÀĞó›¯ì§İ´âõ.MÊ¬N´WÄëLƒÚã.È¯Ç`5G!»*¥å®¬eÊMˆÜKK6t:iYít—0¼h'“­àˆ^_’LòCâá(Åüènùï,wµI7*î!„W·õ‚sX%…naê#Iå—»âêxŠ®ü6”=¢Iì›+Âÿ_õÅHwÎ¢ñ]µÇn&ZÕ]ş1ªb¨KR²Ê“å¶b<åüªõÑŞŒôM|È+ ^k“r€äç°+“Q@C]ÆqÓtp0b¬×]·ƒôÃúùè–ñœ¢ö&S’A«êÊa3Åvs ‚dÏ¯s&»XHKoMmjQñC÷‘Ü]İÌ‰”4^ã¼9Â8hIaqÕŸk´Âq|ÒıiÂÛ§r4| H"€²9!
`Ê£á÷¾Fh¬á§ÛM…¶ê+ÏÕœ¬p-M8
úğıI§¼òİ*n@”©Ñær…_[¢ş$/ç	‡r”#¿uÖÿÒfškú÷Oê+æsé:hhVÚªÇê`¤n,Œ
ÑGsqi¦¹^ø,„İ}âˆìÕ]R™jî˜F÷ŞZàHÀøİO‚¬#,šâ› z!È§z\à0¹0à ¿s9bJàëà"}Yt@õ¤BÑ&ùÓ:»V°q}yA(W
»†:n(ñüÏÿ]¹ïÑ`Ö¼m¶©„ú|Ö§nğ'±8Ç’-ûË¸FJ¡ê´š+hzl-_jÚM7Ùıá(O=\xm-ê¯Š­ø ©ô°yØ8æI=­b†‹ŸDo2âqdÉBÒSfÎøPr[—ı§ĞÊ‚`'øY.%­·Ê¼@qŒœÕ’ÑWı¨şÉ‚¹º¢q•ñ·Å™ùšœYX˜’K­X¿qBj0×záŸñÃZ3ÁB¥•¦2dqq¬â!¼¯Òz[š.Şdì^¤ª‚&-Z0a+h},ùsZ^@rìaf¢J{šó’Øi‹`ûü‹´uı»pƒéã‘ò7u´««‚üy~´Lø¨å‚WU#e.ŠË¯ÌÖ<˜I-X—Y{öŸÈí&ÃIˆÂˆ´èS×íÂ*êôÊk„ıñú0³¿ÛÃ•ŞçÎsÛ8Ÿø¨ê\K|ÆÅ
>féXØp[ë‹³UÿÄáY˜.66Ïr~±pÉŸ¸nŸà¤—'Y“jÙëßêf‰åõÙçTÆûHÎ²¡\#„¥HÍ‡üĞh\z<æX+VMÂSÏZw â¨V-»³ãñ,™™êdõ-<<;ÀÛ™3}4×Æ÷cWâda£mtœJF£b$œ#§­Zö<!B—©Ë0š«ÜpA"?t!Ö!OõªûªÛÊ~L">çÖ˜-«±A÷Ìãm
}Ü97B˜`¢œ“!¬:gI<å™ùQ@E*\08º:
øF¦mˆ
5&r_nò‘µ€²)M¼B´r‡5 ã.TÌŒÈ!Øb™¸Íì—»–9ò½T côõzm[EíæØ÷ïàzö{£ñwa‹_¨8­[ÅËUù.N8rëøÑGø’Oçºì è!XR¹3>RyA‡¶Wº€ÓCò)¨òô%­b· W{”Ì¥¥Bêé»eŠæ”µfÓît¶’>>•ê:ˆ:!TşUö%æUğ…Ü©©¬I?#"[ÔÁ–!7sErÏ®é&Ú5æm)H@€Í³“ö3ÙègäŠ¨.Éa'¶@ ÷ıMÏ¾y™ÿ²–üË ñÔâmsĞ¾ ÿÅ$Å}ëDÌŒíë¦vÉY=âôzX>k—#/¢5Ó&AIÍßµÑÅ¡Ü¾û5aÓ1:?­!&Á©øÎ¢ûcu|íkä£U=şëBéƒf:(¾Ùi»új¡CÆç8™
RC4/ÃK+'B
¯¥;ƒ/Åë‚Û$7Ú„¿|ûÑ>³në‹–ÅÙNX„Î@H!$(Ù¢ìôzQ¼¾[Ê	¬‡×g‘¨­ËÒ•Z˜‰hŒ/r¡™”ñ ÂRìä8o¾KŒY€SÆ.9Ó:İ;‘jL	÷Âë²}"¡b¶ÄŠÖŒ TL·ê®8oµ?ó‰S÷ıçoä6Ã‡Œ³œoRİ`=ó†.¼Ãİg1@e`™{³¢¶½¸ÿR‰?œ6Ä)ZR,Úó™\uÏ§¹¶U¸Öq¼YÅÔ¹j#fPÌ‡8l_}v±÷f´ÑÌ‘×êf¯–œ`ô€²½£ÙáRççg©•§0ó1°ä³,w—V:§%™‚ÒPh‹P7tU,+˜æÉÈ—¸#Ò‹¡E?F7ë†» qè/û†©oE¢Y¨¬ş!»Õ_rqâ…ê±m=cPÀÜ-yxÑ{Úô÷²Zé€Sà‘®i%ÎAèİ˜¬Ö@HÃ&˜ÁR@øûkX¬-¶êòY$Ÿï«’/š2u¨œ™b¼B Ãşô; C¡§Gtî™må]åouT§Sà’Şù‚˜H,Vcˆ±ÏsBÔ„}”íS¬E~6Ç€­D„ØKÅ'*“PRh-bE@ımüS‘k}+fÏc:?Âõ/A.R–9$•2:&Òmÿìl´ÕŞFA¿æğf÷H¼	†ìTë¹î¡36*tKlÿØë@–	rÕa“&Õ	[P?|ğÿ@Z@ÈÒUçû×î¾_ä[c©•K[×•¶­W)[la9†_ñÈ3D­î
`ì–r+¨of…Màù"J|‰ÑÑåY8¬{fd"ğ“Â]”µ£ëµ§©üë	´ §igÇvœaÙwŒl¯ µ²PPğgv¦
ÒIÿ]fx’„BÑd¿õ5%ÿOÊ§rDG)Õ^7ˆ¤•j=?}ëµ¬!;ıg :Çy:²à3l.Íc×`{@*1e¸Eê)µ#îıºFöÇ¹¦GĞÆ(ÇzúŠk¥1²—üWyx;A›ìeºJı5;ÿÁ? ¾Í¡Bæ‰¤ëôêĞB[oI5ÒH
‰3£Å
=0¥Ùÿ•À‡œĞM5¥Ff×Í
puî¹9s˜¯&8‰{Š­Ó­å`L¡‹1ı}~øävú.'1óW7?$ Uàñ½”a®!´z\fZÌCß2r¸İ–¤Áìî*¥›0p&º˜á
m‡ëfSƒPÙwèµ¨F”ñZJ•¨`æpT’bÚ8)˜‘ éq¬e¹Ó°ifù¿¥bNC{ÿ†æ‰õ‚ø¸làÕ%”À»€ÊıÒ>VıR•áD$Êo<6PìîçÛ	¿Ûeøk0ºmi?c‰…²Ëâ9—ôzŒ>‡Ùíc]´}Ê¡†#Ï¢Â¢H™'Î ãÁµ|)gb%´®è“3‘ÑnV£S?‘ê¬ÑÌKÚ:Q¦óº&ğ­Fƒšz×òıt`Ky;§×Yix[Ïfqúø*}eÜ®šo–+ÍÍá»âu¨ŸuRCÈUŞ.„(îy~Ë-È·öªÉXoæ»¨m£Ş´Q:nš§¹\S Yú…t×OPWËiÖ"hÎ#–gnwHÜ¼1ø »œuc
ŠF‚·!Î½Aü*ãLÜİÃ»\2íåàxÖØ7tæwjGq¹jÆzKl³³[Çt£Ç(Ğú<_®¡¼“ûšòŸ†÷üb‘c›—ÁŸÃ|•4dE3İq>`Ä>ã D¿ÎÑƒ?ö˜yÆ±äyéà3´yp*0lZ®$”Ìyæ€.÷•¥'g'Çy—,æI{òåùÑ­õ\ fı1ér®Z’ÃZO·`+µï³!øä=I¢À-FQ;’¯åÒ÷ü¹:Ú¿½6”a‚;Ôóö	
¢!ß£x°zäQi™`¢Ë]ßpvÓgeÜHÚxÔ¬hC®µ¹*‚	[ìÅAÌHÈSù\ñDª#’M€ä.‡÷:¾Á©ã`MDmÙı·s·ØyÓ‚\™Vçvsn8æbY.yI$_ßŸäåÌèÒ se‡v7ÓD®…Æ9¦ÖÅpè^1yJ(lKŒ^q;Ålü@•)ûrL%%ª"!c°n®İ"Rÿ${ÈÃ3‹¥ıùPß¯’”‰…¹™’@ê'hQºÜÀ€,ëºT‚!¥ÿˆÂqÌ³54A!›Ieû3âêà·yê÷õ8Åúî”ã,êj•b\ ¿XÅ°,ò³Sœ]B¯ãÓ«ÉYÇ©–~ƒ ™¤Šó£eÍ‡Vz üÂ‘¾Ú¦w‘îİÖÖ¾b‡dmØŞBM5Ík-màòÆÅ)z­š¡ÖØ@
G<º¢Ş#Ğ á©8köY’¦¿“‡1€.(rİœq«ï‹éÕ¡Hİ–×XğJ+0ãn:¨âÀ“m—HdÀª)ôzı1ËØ"kw4]OyïCŠ†¦}B$<¿£<]ËsÓöH,;%éµ¬‡ÇĞ¹I\3%|àZ¸ÛEG€£GÒëN„õ¯¤T4¹Ÿ×°	ËæÇf'Mè\\‰´p,K«0À^„ÿ¹îu‰Ôp¹¤¹Y~È(à[8$÷N;K
:<=Ù;jhY	i}Åí¿ŠÎ:é—úÀşÜ˜dÒH»ĞS1ğ*’óĞ8ù-¥Ë¡Æ‚áÁÆ\Ïêvã»If™gçÖĞ:Ñ´†¸ÉMô×à©<¼‡?x^ü¼ºŒ¹åÒólÔ‹›ÎììÜN‡šaª¶¡ı}˜È½ãÿĞÿ‰Kl¯¥EpİÇ5{ÌN\ÜqsËB53'¼0©ÚßøgyõGÏ¤šWî¾„Š+êˆh½SùŒâQÌ:‹Xdn–”î¨äe³ŞpoF[NÓ8€¦×O~[« |¼yX-œ‰ˆ½!ùX9‡{ğç³†ı2<ù’X±`<4–.Ä)g-èïé%(*è Êm,İô#’Ó¦'´ÿ­?Âh~ŞÙlqgjüJ*~šjâ·I®RİˆLªúØ%‹=´Ïßq~u¿›LP¤ı¤ÁíŸK£Iİ!Û®P®ÁÎ1hæSÓ9Ú/¦—„éÂ-˜*¸…¨’OıøĞEîFfv.“Ö´À«Işzâ7½dùNÀpAÁ6æ?6Æ!¾¦(ÂP8oá>Ïÿ<Pi¢ĞÓ·#Czúà‚€a¦á£Úã,càT{KYtu€åæé*6÷fn4'œo8Xcÿge2Îš›S@ÒÜrâ¢ğªx+œ¤Î¥ÍAB‡²çbŞ•$şÕºí?İ^$$’‘ÇÃ¨¤®È]o™&u®sÖ®w˜ÀæEòZiMFvãô,&ˆD’ás’Épû¿-Ôq ³]Ñ&-û°Ê‹Í‘Ò`ç6’=ÙÜş—È\ÚÈ [3QÓ¨Ğ4!i¨•Êhğñ¥nÛ@QÌiû-4Ó¤T]ZV—wgĞ‘ìB²Õï5#K`‚á™M6ÚñD%‹;óæÕ¸-^Ôå9Éé¿â¶sîL3ßu¤0ªqX|·‰–P?,-3xùn›°Dòw*ùA^<±öé÷Şš`úÎÈW·ğcµämll—ÙÃä8G:Ã¡ No‘ê°G³;(ü€íÕ‘7/oúÛ
öXåç	3
Iá›!o†Š©kue}ğkq·‘¬†¹âªŞÉİŸšeUx÷)ñ?O:ÉRGÂ
×À4?·Ç,cãÂÔ™³wğ•ú ¡åûğî#‹•ä½›sö$š„;St‰$B÷gİO.®³ÏM”’ÊñÁ,ºDŒhMÂV3+RÙ7zù^¬ïş»ÁTBRéşl/Íš¿>‹(ù)ÿìm¯¶rVËP©!7( ¤ò±ƒ•»ÚĞı{#uûëìˆİIcw¦†3|¿µñÛgö‹‰¨8»Îhc™Ûù+ –¿äZò( ÛÈİ'"©ŞvÉª»#èby#‹.Š¨$È_ãJO&OyûïRë:/‹ÿ5ä.¾¤/!'ŒçSqäW¥[¿½iõÒÎ}íìèÒÎÚ˜ƒÔ³È&3	È!:{5
Rö[ŒFÑ°´¶S
Ê²éKßãÚyåù¥-bëØl¾‹¯½¶Oà:Ê¾ |+ÊW4íÍŠ0Uim<¤y%ó”<®ÊÜ7°ÃuŠ°N{…xkuş†ˆC_©»îßÅ ÙÜGBğ”u ÂÊ"y‰8«úÉ—ø-_gzı·ç7ôÚì­X!¬W,Æšl›Knï“$	äÆ*F^ı:şíN€G½PQª`ÉEzà^wùù[~	s¬Ö/ïu·t
§,Üà[™B›DdÏŠ…]¶!8À–9%£osÀ~½bŸn"i”™ÈpLIÄ7,»¯@æÆ¨T¤œiÌ-Tå)¹ÛúPå¿³â,ÅÅ¤0O¨vÆêlô†ñå<T“4CCÛ<©ÿ—1†˜.í¦0m*Õyv‰ÿB±e¾iu[O(Y„,¯	zŸµOŸ/¦Ø’ìxÁÇ”ÉmT¾¿h¢c×ü"¬µÕÛ¥ß‘,ÒÎµzY‡:ùZUT÷6©÷Q¹3í¾›rE_(¬Ù):ı[UîG¸$ ºi¨è°5Ôô^züØh|/g,ªÀwKµ3QXo„Ô8˜/µ ™À°+MGÕ¿¯ƒ£¦l…ßdTÂ†Š0ğ·YÔ—€7nÆòFÛ7…%Ñ†~&¦Xæt³ŞŞè‘÷îÍKwÚ¡t×„£3¸°C£UÚ`xİë˜š+#ÛîˆQš«°lÖR)jI¡z>’JùçÆR¥VšYˆ$-©hs¼:.x­‚ÊİÂÑ®;`ÇŠ9~'çÔûSxÎ¿.îT¦x½7t¥í/ğbîq3ùlµ^”»=g2y’t‹%S^üb–º[ÀûAú‚¢£ºE"E`Z7ÙË<ØYàa¶¦i®pÑÒy"‹İø‡DAt3K>c™S²ú«XÙ¦'œ..» …¯®îÿÍãjıD2\@™ßùøË´‚y2q@0En]§CP"“[)Ã«ÔËçÃĞrw[ôô>ßà‘—!>1«¿ík>IˆRú™™çš*¤
ûqÓ¯a2^ÀO´›ßå) ı8¹Fãø
VàBvÎÊpå6Ù¦QØ^»C]•í óÕ¼/æ5Óæ­˜ş¤Î²AD’é­]­Ì•”pMÈåè	f¦&SşÎÈ¢(X–·ã™‡Lóˆ§BŒÄï5éå{µŠ)	ÂM£m[ ¨ïò(Z2iBdauĞ¯O ¾’âÛÊÏtôØ°ÈŸæ*Ÿ7¨-e®qÔFRRûK©ycnØ3 4µÑõ~“c~s¢şìÚÍQœudY=Ú¥x/ŸèÌüf‰"àKØX‹Àš¬rªúB
Aä?”Ì›Çûø®ëM´™bÎ=×Iq™¼D¨7öá‹Ÿ0µvCÂ&¶†ë)§^ô€š«ı.	úêÁaĞîÁ–™áô_&²UfmR0|,3“îDLxá²b»9>’lG²O©|ÖÓ{’òÂşê—}ÒÀ.ÊŠ8BnªÙ^™x™ì%÷­Äd©s¢7¿~šKâ}úÁq3m‰àê1§ç£ÒÕ!}#A´¢ôp‰LL4<‹uT0).K÷*¿ÃÚB¨š¸f¶3¶ùPqïæ­¾‹çO×U#gŒ3êåJüQ~ÆÍÄ¸ÛâˆˆÕmjGïUXÔBş+±EËr(#lQ¾uÙ[p8Øí’LË&?ÆnîlF9ã:3s½EÄ×y|J
5êÖ·ßqœB<=‰’XÅNpãÇ„ÅXäBĞø·°yòapÄ¿ºÖÀ¹–MÑÓåE…¡N¯!,„Ç,!Ær)Iaôp”H_‘àC}ô›g­MŒ·À¡“{4¨C2¶Ò³ë—Éos÷9-Zp¯§½¿Z_¹²Ü¡ÂÙ.¶jV®Ô4èUzÔ#ãŞÿ+â„~z~ìÏW¬!„×€ã™ä'Sôû£W˜<®H—ãÕ°	½ó3P¤x0îŒÒkC|4¿N²¨^ëUZf+v{/¢/Ç(Ì%šsAßÂ¶à‘ÑŸYÓYÙşAşu{ÌwOàÙê!×c»esFY4ùåôúÊ@‰Ò¾™F¯†<I^Š±uSIá•·©Šß€¾’~Ø¬Ém«’7º´§qÛR9›GHË
ŸÖ¦üïÙdÎ©ö31œKÒuI”‘£Õ©¬ø2ÎĞ™+ÕŞ€*Ÿ¶>‘âƒ/¯á¨ëZØJ£8éR…‚¼F°M›ˆÜ	1¯N`Ä¯*ŞšiŞD! ı&o÷<Ö—¤ÖüW²oø™ú5â.Ù'†d'ÒHJã³İJál7¿ˆq¶4¾CBî¿ĞG©¢Æ‚0Ê-¡:`64£T¸ç95Z†dW3wÿ<ß2òÏdsìÜí¾kS*X"İæ¼^ßÍÍ¹-óæĞ°î7şØ0K\W·ú{ëñS3/À]gÿ(¦¶²é¥a?bç…ğôXĞQÙN½ÕZ’D´ËO`*ÇE¸ö<ˆÑö~£2ß›·Á¨¹ö³Ë¤Á¸²M}Pô°Pk!œoûËØçÎ1ôyâ´m#ÿ”qİ¦¡Åb9‘ˆë..W'‹–‘XIL^`í˜/]£7¼@ZH MËC-Áèi£º±aÓĞÆÌF®e%X{‡¥C\tWCzÙõE†ûìÕ]ì’’E-Èã(P“&—d2ÕFaÃa²Ne½7ĞŞ§³³Óí¬¥hº<Ş"CbBq/aRØ*ªø€õRF¡¾êEJŠöÇŠ2D>ûÍD¢Ï’Ğ0\¤¢Ïª‡¤‘DuŸë>³ÇÇÄĞ”`õïøqP>ÓV:‚ıı….¹ÎYš'õÖ>Ë™Ç²A¼çQ! ¬êÊŞ¨g´*4üí;èaŸFá’	—KÑhE$¦EÅµ‹R©|ì¯HnÅ¼QFb(Ü76ï…²;ùh.Ãê¸HJÖ™;*×‘[ñu¤7"Ë¦XõKÑ(	rğc8¸”aëÃKˆÛÚ‰/´Õ²ˆ9†Qr~tw]DÅ’ ƒ»«ˆá‚l6Ñ¾ùÌÛªú›n¿Pù6Ëı¾‡¡îM¿2àá m0§‘ìg”x\w¼å¬Q–0pôÒ—CprÛiÕŒ¥nêp­ÚŒ9ØcZ”œ~¿Bs“xÙRpu3é§İ]ñ‡ØëM¥º×;fÁ 4U5ş!7í'‚³Ïq0[’ŒPr‘ÎÁ—x_ÕÉëÏ§¢T(a )r#NÒ½$.•t­=A	¦ş7ÄXPí
ÏîÀ?•L©2öNİƒoâT®wÿÃ>Ÿù>k'Öî=NûT^8ğêQU!a8nô0'½¾0_Íd®ñG>î½
Vûù`¦“¡ó8ün|&r©I@Ôé$bwjË­Í#:"íˆ˜fØû… K²‰æm"™ÈhB1¥DÊrêX¤Hñîn'Ñwì>:³UlvI89ìÃ‹ÑM ‘*Ù¨dñrKü®ˆÛ¯%¯kı­Y99»¥–«ÑLÂ;ˆêo”Øw5ò(†V{²
ğ‹Êå–#~ëPÑä­¾Ş§ë SÏšM~2©2BtÛ_¦A¬ı—ºÔÛ”YVŞyØİÀ±%‘Á :A%‰n4•{Î|¬âŒ'Î6œpNˆ(Vx`‘8®ÏÅ)xzø#‚…– ¸Õ2nø½[ ruÊ¿—ÇV¿Pjè>2«™1ãA†åÒI¼Î‹>Õ` Ñ¤‘ëhBkß!MäLÜæÂ.ÌTB^Qb³5
$³Xm‰ĞûÉTIn¨2½ÙŸE¥Œá%å­òƒ"L5$
nû§aj:YÇeKguËü\%Y[ÏÕ'J6‹?xN«ë3¤‡t»€çÄù”ó‚8ä_O˜x½gV¨Í¬/~/DÏj­§ü¶ª³er MLe@{–”\™$~Wg*»G4‰÷ğô$“27×$	k3’”ú ^‚Ğ>íp@ZšööÒpæ‡ˆ—Ì›UªÒ­t~'‰6°™Iõ^œÚ„á‘h¢ª±-‰8FlËğ)ÅÖií³Gºiêk´n]`Œ cåˆnùSİö7ª”÷B™é nï·r;É¹J€{×àÛ#q£ıYúì±7>«„Ïòá»ŸÕİÓjÏüU§J.íbY|ÿØX!LKÍ»‡ä'ÃàÅHÊªX–i2ÂôØÌê	,0Ìø9e	‡EÈe°l—ñs^X³Y—Ì©½‚"v†™àîÈ‹s¸Vé_yûÙ=’NÌitáqØdö¯âÍ&Û-èÉ±Ï:^¸zf­Lİß²¿¸“I%GlSE\}ûà2Ù«ØãÖk2½â©ÅWX–m÷Xy‰¼–}ÚƒçVægY£¯°6|ŠÇË©óI¤ãËwaÓò€êrKl¯}‡,¢~¦ÖŸUnòÒ3ßï»Ì\‚nu½—°Åb¹c©[â¢pz\¹N-<¹¥µì*¢ø"ŞÍ[÷µ¾j«Õ÷¯÷l ¾ÁÁüù[œô”¬µoŒÜ—z<ß… Í{Çö‚è‰Ÿ9Ygx¿Aáèˆ\ˆoĞë±jXù["c©S_Xª Eb>nN}ã|D|‘ğ­@’Ğ_#wé'˜µË³6z¿v-€ü9}éå ÏfKAñ4ê|Üw|hD©a½åx>ÏÀ‚ SHÛÙ\\©ª“J¥XÚËå;í}Úùr¸Å@ıxäyÔ‘ÈpQÉZô®%&
õÈ—¹Y¶—²nTıfˆ±Ÿı¼½ºĞòöã†¢¯—pwÁLÇÙ˜ùîZú¯•npWÆO¡ñôş}n¡æºunøIï´v5ûçÏúÏæšzî"µkÕ<]u"ˆ2(Ë eãá9)%‘îÛÍ^CrcZš…7CUªÔ<«äÅpÛcæõm(*DíÏ¼ÿ¯¸»m½Àù|ú%±sÊÆvÅ™±õnÉ}n¯7±¼b¾”¹~‘»&ÏêÀêôdj÷®ô¼
ªvê‚÷wYLÔÊ¨S„.eêÒ™÷?{«Rìº×WU¥ğë‹^-Y;Ÿ&š ©Æ)+¹–ç:³´«ÅVªêßÒeÄğJ™”Ûm’Â¨ªrÙ³EùkËÈ(ììãÀ£.ïåëM\Ã¹•3ÃX¨KÃªwªß} µkó_(İj	§ï+/T¢“{Æx »Ú®xËCš¨ó«C«æ(J w^×ï³—¬…5”eŒb‰ğÿÆaı½‘Éhı„½$&?ı¶É™óÏ‡M^‡{íÕÎY U±¡*©Äµ00`½a~HŒ¬FGÄ­Õqö¤0}Z½WôT“Ä¸W"&”r}°Ïrè¢àZÏ8gˆ}›S¬iiû“Ì'›4Qfmc»œå¾ØæŠà8’#7Tˆ©ğWŠÀbX°âú[T‡OV³­ÛT–Sä_&¥yÒ?b¯0	«1#Ï ª<‚Yç´”jï†+25ªÛ‰FüB{Ïcå?å^ºKÇnï'°š¦®«Ji¶?7µÎC!o¦pùR»‰ÂşÁÍµ§Óİƒ¨’×³mÙƒ/2nbÀ5£|7Áv~°gÏn]Á(H™İø|…€ùf‚ølŞˆÿÜ	tebAyO?Vj2Tåù2Â:ícXBâŞlÄ‡Ş–Ó8Ô+´à+¿ !nÄ	i)`®æ…pÊšÕT\á¥\ÆtHœç+£škşt ×TÄ—ÆOİµF=¢šĞšÌDgë×-½=ó*›Nœ›/f~Ó±¦¯3X$bòÈlš™@_™¡€54Ê…Gs¦\Çœ·f @8´¨2ªB½çáw»ÌúA›ŞÉ³kÌ†3KWsN¬Ä%hğæ†’ÛGI½^¬ÑwbtÔW·"k! f;±z¶êaµ€’H“=§ÜŸ;İHnˆëˆû?-šÖôÌà3İV|ë%t5ï¦ÜR	Ş’ê£Š!W˜0{¿X·šè?“å´-H/‹"~&ÙvZº!ı¹=BñP>œÀ·Tâú˜)‹>Ís
6#T§V&p¡{Ö}Z¹¿€.a~ân!„	ƒ@è{l_Ñ&”ÕZHv­%@WKÛÍ[Ö~!‘²ëo şì%g,¢nU
U\½-BŸ]XÄÄ(JÄBÁÊ}P–›ùÌ¡éı1‡<HƒÖ kûqúÚˆ†Y´£B«GÙº9ã­b&	íOGtÙy!YìlÅ[.™Ÿ“™õ	_OÉe¶%ùC^šDÆÏÃ#.ª¨)¾ÀHş²ƒğåø×ÿÙYpÉ~uÚSü%‰]FÌ÷$GàŞ#şu•xî³‚š$Q‰p=S6pX²°6Î?J€@_FáöDÛz âÓ5lÉùYöZç˜Všı«‘rù¨üùSÜ¸Ñ·³N´è%-ØË¶ô@êBŸ[+ÄÇT¥r	S{^ÖSåX`>ùMìFT5W×uJ$úït-³
´Â¿M†Ô´[CS¿?ø”¦Ì“‡p:éœÊ`Ç¤{íú’àãòWßB.İŠºMìÒ¢p³œR OÆ]µ”< ¥İxâ<ø7¾›ëº-L=tr¤O§ãCv4!ï@™ƒz8ŞğZ'ÆKGä$;½H4Ä2S‚h±c¦ÜšX‡İU2ó'æèoxwT#˜´9&@t ’&bÎT$ÖóTJÀı:Uö*Šæ‘Äô_¼>)‚º ¬‚DˆÄ,}ß¸7#£ümrøâÇ°
øè%ë†×)Ok)“³`QÙòe^€­Yı2NòfúCYµŸédO‰Ğó"2ÎÊx?¹Á8­ßÖ#éöMÆõ¢ E?fnˆ¦
ÒLUQéTğ9é=Oú&Î4w€ü–Vç ,¤†ºåÆèÖ>Û{‘>|ÕöĞnz´kÅoOÜ4pt–Uî—øÖÙ†fµbŠdHXûeV+|µ38»„å ’şˆ/Ÿsû5¤UjvŠ­·jÅ9h÷{Ô^ ·|KjVıû(BdêÑÂösØT=ğ@²íäçŠúoOÛÔÇÔÌ:öÍ!€µÍbº _OFÉÅn}äoíÛR˜4€¢±êP¥UºÜÉP{ß¨šì¤;¶´'˜^uÏÙn‹‹ó xj°}#ÜÓHÓ@£ ó±\ hØÒ¸É\Ì~ñ2~‹Ş`Æ'†ËÃAXÚµDÅ >AÏ1ºşÍ»lc§”±6¸;npH}€29Ÿ{™êR¥eŠ*N¦£ZòÚmİn,ê¿ÑVŸ­;ÆIV‰À”±šTÇE—ËÌtK‹s¤ûíÉo’ûböÏÉy:×Àıı’Ó¤©õ”÷öqqã}ª©VóøË’©d_w/EU…ÄÇ,B¶ìº‘€?"O>fà> ~ûÖRŒ!ÄXïñÈrFæÁ6r#7AÊéWC˜şÇ
«9#3^‹¤øqÛAx@4ó_ŒCâhÒ\L{ëşKçCŸøí‡6æª¯„³¨Óq¥¡Ï‡À;Ï¹keÙ	N-„Ş“3Ş¿Q0´¼j5 ld˜0ŞU¤ùnnEáçí\ƒ!CÔÛsÇ˜=¸òìšDy”/Œ/XüM2d"5ª]5ä1”Ÿ0›Dª½ôæMˆûï—M1ßö"f²‚¾m_?Awjö­§m{ü¦›Åµ]µ#*¯·8?¡´­é<x¹ÕaŸÕlí~íÛÅ¯mÇ<¤Bmë½ˆÙ»¤Şãp«Ù¤,<Û20\V7ßE\“½Kk‹H¦Ú‡´ÏH¯cÍ‘B}6w¥òŞ.Y~wvš†$,–Zò ûP#Pm‚=}§Áø]QªØw˜!“!u‘%u•kûª|ğX¬Ùx73}°+¦‰?¡ÕÏ”\èúEc5ÑÌÅÌÚ+y-fÓ•ß@Ó8.¦ßàıŠfVwõ”4­0,¡ÙÖÎÂ#©XNÆÛÛxXãõÀxÒ!Á^kÙf^Mÿ¨î R#Í[æ¾á3 u…Z|0”*È3w£ªÊı!Vi†®‹äRB$…À’ë&çë'äò%ÀòèîåÚşc‹jti²ç¾/®x®Ld2¬öñªÂk‚¡¨6'¸ófø0ÏÉ_§ªMğ}?°ÑOg›ûÎìÍîù[­‡Í±åPG…À’)ëğY"5€ï!êò+ùñ§ @iT)m&`öà`Bhîíı,øÓyQh¼¯	åLGğ‰wÔÚ÷——îe¦òº@¯}<	8×§³Ü¥Æ £÷ˆûP¨šï»§Æáßó:-5Q¶"à¿Î0Zé¹?çú	*ï¯#Vë„6¤úÔY(u0×Eÿ‚Pœ÷²ÉŞÌeÕÙØO¦ğ—j‰Îîçô0~¡¿ßÓz(Ê'“@ê†ûf ÊøTğæ9š nÔÔöïóñ"k°³”uëĞı¤·f®›®²{Îì™óÕA¡É/¹Ëí£Î'»–»£O™¶ëÑgUZ4m1†Ï¨*Wèj•?ìH&XÆáõÊ6¾@˜¼h?ƒnñXƒÉ¶„ ^<éh^0.jÜô˜¥ÿkQîäÖêéh‚ŒÎƒ<`£‚årÊtMSµoQT$ÙÃc„éë{·µ‚’©|
âZï†æLJïâÃA}±XOšÍ5/0¨7ÿJGiŸÙâc®,‘·Ü¬ØéõTßcëioÔã¦ßJG7ó…×XÎ"q&ƒKJ¢ã•ÒÍÚ ÙU²Dè}­û)î@¶ë‘1Òƒ0úüä…);¢ûÄ>mş.	Óô°kğ¹_]ÕØì—îFÎ²H§Ò½"ù–ôã/Ìß:àñB$ gĞ—É!ÉİO+#å¶Ì¿Ø7Ö–>#;}Vàñz‚ U4Ÿ­³ìÁAµ(3àNÅÑ5ºi¾úë£QÆ>º¦³åÛš‡G8e‹ğ¢Š–ÂH	‚S°–ÄR&ÜâCh™ñM5ÂŸz{_çí¤Í\“XËisøÀÊİá™Fñ§<îá¯i	½Ä^ï¯áwİ¨!íÊïÔ@Äk@bpz_Bqº1oh¢T»w×lG¿±€“Kß‡aøˆtP"ÓLŠ©ÿñœrs~ {{W	-ÙñçC÷£a„Ùcâ¦KLÈòAUâÌzõlá‘{2€Sâ¡›¨u«Ş0‹ÍŸ”|dXß™(Îà9#lPˆÊJzìçcÃN=ûÀé©°¥^/–ì9„91÷ˆ×bôÇ…»Tm`Œ`¬>¬6°¡ŠQŸ*¤™Ã=H|~ZYÉÅjGJ@©‚^çÿl¡q”¸ğ¬Lÿ¬ø¼¹~‹—ıñŒWŸmzãF¦ù¬n»ç.÷	ì÷²çK‡¬‰µëcCïšÆ’´¯Ùc¿wBÆ.hU%¶¬öŞe#9So)»8§8=jañ7»;>Ìiˆô}´M87Êú^Õ¨Xâ=º)ãÎ£bè óF<Ğ˜á2s.%Ê>Ö7œ¡a<43-~Èöş¶à]
cè }&›­ø­FjrÜ™eI”U‡8©Jÿ·ë‰­vği·­À3¡-¯M¸/ÓÔc³N˜¡ó¾)Ûä	Œµ.ª(±‚o'bNîİ×E{'ÑÒa)œ’U²éß2ÛúG/	Ï:ä¡™õ«ùÓC¯»tw6'¼!w­0yÄœäìœä6­Úc[üuØÂÄ ]i€p[º˜ı©Ì°ªæœ„av•Ñø#Üo 6½«QîÉ’}­Ø¦¡~æv4mN)ç/0óÃı›Ğ[ÙÿÀ
õŠµÒå«Ÿ¬agÉlH}¯(só~Éã`ëÎĞ¥He?¨e.Îµ¯S›¹'T 6›tı/Ö'¤b)íh´Ôo¶²Ns&íSÜñÇU€p3_ãJc÷L;JßP³Ÿ•É¤fÂ}ô	öd¢blúÈfDvİø"/%ĞÀœ
ëPV„ÓN*ÙG\ß÷£AŸm°\ÖxÁ
> íäzGmp{‰¦£Ìsªåvæ'JhSFBÉÄáÃïÖD¬‘Àà<ÓKÔgğÚä§²}¡Øƒr‰=úW‚ı²Ë:LŞ¯«ŒĞƒØe¦Ô&Û¿\ÂZ>8É]ô¼´_¸i¾$ºZ×êwî¡ÊUÔé"…û›€3ï¬`	ı>	e3 Ìmı¹Å—$Sôc#~'VmÇ­¼•"»ìL?ûfß¶±¡rïÊnÔjõ“RIBôÌŞáŠšş,ã–ÙÁ*©SZnbŸ…B¶˜÷ã:L‘Gá¢¥å™Ï$ä}ƒÖÄÖ¸ı×“ÜSˆ†mßKGBQË²ºÓv]Æ.à^Cps§uª	Gğ„ÑDjˆ0y´ylK4l|·š;²BƒsX¥ã%fª¬¾‰2š\[	E©)e± ³°`ÄYoJÅÏĞ¥ÉRì{Ş-\…yòRâî,k¹Y£¹ŞşšÅÁôï×Í¥¤M1Ï¯É rQMD3½Vjó¶ì<òV6ÖDŞ è.MÖ*±{GUıÎ€æîÇ§|›áÆø;áÏ[U®Äü—p	|x_ÈJëÃ0&ƒ<µÆàœMp[±N œ{Ÿn†î.‘·Ä	^ó3‘€©Û¼ãà=”"T²vÂe£}•—`3¢ÌıšÚD¾ÀØ¿ì:?‘ÌÉkµkväË_Œ‡Sõ¯*m`²ÈB>İHoÙäŠ¹›¾(w[‰™õ_§^â±ªÓxROP ¤Á ë-GH®‚ÄzA$:¤¬À‚æŠº°éªª6ãoNG%P‘CÎ{ÇİúÒ>çM•ØÄÎûÍ—gÛq‹5ømbC*UP'’“È)p4Ã8P„ã˜ıî/ywÜSç1ãÅ5~á/ûF‰©~j²{İNMå50º+÷)êNîıÌ:$Ô­Õfäd†¹—ÂzÚd§nºL?ÇÇ /)uÛ}Ê4mâºÏc)Ü5«Â“ ^×Ïi"úÖq%¢!¿v0Xë¿éõ…5(¾×ş‹h
§Ìõ—P¨XâgˆM`BuÙ¢÷¶*_ÍG ØU_˜S’¶zÿÖÿÕ LR—Âº€±ùfXêdG¤:¹%Ìùİ1¿¼åb~vãV/´“ßésØ¿?)ô`"3_|ó>®júj¼?9ù6ş=äñİTød_ºÜşÅ©E|ªÛ¥íˆxØ/ sÃ6Ş«×7`fZªì<_ªÚÿ«/´¼ky9'~Á^VŠ–djµaª`^Ú)Êô²ÌTaE}_g´­ƒxÑµ/pj­h"ğÏ¨B+=I¢?%±ÇÜ•Ô•²TÌ!ª1šhšµ#À<Ô­wü¶ëŞ€>‰ÔÒ—#½ÔÍÁmîàö¶q6³Æ ¡·½-Œ%¼a-¡GD¹ƒÛ>È´Ğö›";Ú”Ñf‘j¦µ…d$†júÈ=ùˆÒÄÆ¬¸ı'{dŸæÍ8BÖ«o®h*àïÂ³ åæ]pÖšlReÌíş]ñ:È>Y7§TN’sÅ6„_ºwhŞ|?sâ²rê% ÀÓA*ı*ÜT^g pw‡²WÓlVuÙáQg\áXa e:‘-8ŞòËáí2œP2ÃĞZ¹^1|N } (âAÑÛ£¹v†øòí=1óqlGè±góíç«°r– ê`¨„'9—ŒCf{Z&Òw·ğMÑM¦5ë78é²Ğêú` QîW8¼~Âº40SÃBš¡‰À‘mL9cÁaáXÁ2g«ô;òáÁXÙ=P¯t»!œŠQØ•«c§È}+fUZ2}ş!ªbrÆ˜†°–ëã¢n-•ÆÔgßèn^€iÃÿÔáQDw—â•ºC¯­@Iı¯Ók×w(¢€„AğŠÊ&ü¸&ÿI°1Ãa‡ëKöá"ƒ`rsxkÅ0¿MgÄ`èˆÊGÜlzyÕoú©jYl©¢ë`«ÊF½ñ¼ËìQ/OÁİ÷t’?$}|s>ÇÒ­lºró”¤RchBE;aÖ$r¤,±šĞºéßı·œ¹à<³œË‹ù,Ïs²$sµ+eÍë±¬„ß£¶p‹Ù£Òå@SR¾É3¸<àØ¤Cr(U½yo~Ÿ°†À^|õÜM(™ !B¯Tİ#+¼7µ .Œ_1‘Y:—ĞWmcV®W›‡-YÌ$óİîùİ¢]ööÄM ıƒá|.cHšÄ	]§ íYÿe£¾#pM-ñ=…û@.ë.£âçR§%JÉì 3Q…ŠÍ–«çxL-tc>&EftZj¬[§ ‘ Dı`¨ı™2*8µÍê¦ş8vfºk“uä@Õ	6>Tg7©úP·‹Aq±Ë¤g{Ó—Çh#…A\İß„-qµ˜¦Œ®&Ë±øÄpĞö¼Ï”Bƒ+3†2=¬Â˜²o…êàf××Ô_È«:ÖÊ’rH½8ÿ !şD¯í‘j-ZÄJ•d<Z3àÂWÃ5ù 	rÛ†"CŞÔÀ*6`zôÇĞnwÂ<’pUæH[WnÁ!|Nªyˆ±€bÊÜ‚“tG%ÿ/àóDVnQŠĞ(†°òGçXš¼r[%LHpá×Wœ£$c´I|„Ùüöö¡	sUJÂÃôÁt¦0"°g¿fßÂåæ.YJ›8}£Y¡‡ñÆpz^ÕÛï8Q¨)T&ŸYµƒÌà›2nJí¥Íô‚ĞáÛ£¦ÁEµ´îÈ@üÍ}íò¶½f‚ˆ¶&À½SD×ê#îŞC](Ša	ÌõÈò$RdKpö•Îó2úü€{¬^¼.ÌOD‹ Øs2¨®ŒJÂée¶Šz –5'y‹`ë{Â~%ì¢Ò†À#,,Ã˜ÀÙ¯…DY£ÿ,¬›Şfâ”ˆ¨$#,)÷)˜&&ˆøÛô^N>Ú–R£¦Ï.*ÀyÔ ¤
C~«xT‹’u\Ús¼ÎÑĞbK3± Kä¼BˆªàA[Ò¤Q‚„ö@r“'•J=¤›„dónÑ•HPa6œGÌ˜ãš&\Šôñ.on‹æ?L#¸½Šs½¾Y—Ì»CkÎ ğ”À°V{¯ ÜĞÉßGÉ»:Ú˜¶¾~ù§[¡gx„Úá€ÕR–ÿäÌßd!ftª’—qM"ÄÖ]Š"üíŸôşiÉÖ›/#c*Ø/¢ˆLH]Ê<Àü¾îé8vY{-íËJòÓa‘Y~”å²0u*R•ó<nd
×ÏšuAœ$÷síoø‰cFÕ¼*Ş$íSßgåÔØ:¹	ÙØº':Ãl^!vpC±a€CY2. …Ş„‡ß	†öçY×z/üyç,»yƒÓ+á,¼lŒ2RLC0§S²{°84Ö°Ñ^~
§«ZåÑ"LÇß¬*‚ÄŞÉ-E€­)gµü ÿ5Ò9éò“ÁEÛ­]²7¤ôÿÔOÂUÎyOÊz .•Ñí¢kÃîùüî©Lø#§Êé
ƒR°=jO[“{¡ºáq&Jmfsë××‚|€“`Î“¼í¬‰–m»í["0X†A#Wº…^+-Ã&Ş2Öp²Ê½n
	±±¤åÔ’ÍºŞj3øWÊCÑÀÖUÖaÚ†!
8ÖvÎkt!×®FšqÚ¼a=«ŒI OÔŸkÄY¼BWBİÖÂÚwgœœ1×íaeøS^ŞˆL`/×'ô2·zaÎüêOö‡äÜD8wMæ‡‰Ó+ù<FÂw¡ñÉíÜ¯Q^éB{WÂ™‘øSõ2/8»º&f…¦èwÏ– i‰µÓñY>@xÇj˜/9"&¸ÈOPÅİıâ†å‚Ş«¡Ğ¶ÚšÒW%êÂuäˆ-´SUÃh—Û2üQ¥å€©í°ÍĞúÁN®€†Îàj­»rôƒæäcrÕÑÉêé­Á,šÀ9zk~Û2tK³{D0</ÂUÄ}ºvtã©“Ué4¼£#©"`Õ3b
±›„D`°H%j(ˆ—_Œøœ‚Ò"Õ @õ.§påâèØ¸3tN»³Äã\À"¥Axû<ó@§dP`s|èï7›+ëŞœdôKêñÙ¦òb+_Ú¬ › µNMÑn^¶/±·"FÆ¤ì=Â3Y·N9¤i­7 ”ªtJ	 ŞYª _´ş²¾²º OhY;æˆÎ™éâw‰;ÑnT2JƒÂdyd”Ù¢*ÆP 
"ÀG®ëO6ºìæËYåÄxÆ„¶ø\eššRk–ëÖO´-éo~Eÿ¾¼7º½¹î<ñªn:·•ûã>·<Ş€BĞŠÍOÌ³E{××À[ÚvíOŒÖ€˜{tŠ¦‡ËÇ ¯~_³3T®ºš•T¢tå‘mğlA ‹ƒµußÕœÖl€¤ıÕÆ?ğ”'ÿ7^†‹‚>ĞÁ?YáåeİWYP$ìw-¹IÑA¢ŒDQ¦£‹·ãîØ¢ê©‘ gÇ<~^U±gI]›œìeÆl&ä§³ ƒä„áÃÂÄúş$äj¿Ùb¼7Kö=¯ë¾ãÈ_ 7­Ş…?£´ôÇÿ…âreyÿÚ^’£0ñ·ˆ«°kç0P¶Ç â0¾~SíşŠ„
ƒğnU1’£ì S‡Çÿ&­âÁ¨ŸŠõQÙ”R$Š¥L‰&¶QçôÖ<H¢%áŸdèlƒšrq=7ªùHÉ£r@9°*µ³âëĞî-Rûb¨ïj•`‹Î„L”)ó'GdKz®ëS¡0–ƒ}å©úõ°Î^k¡'ñZDZ†i*Ú.Hb¹ü!s1‹ÎÁ/@ëo4¼ˆµÙ?ğëÈÑâp“ŠŞkó9m…ØuÀD	¦lAwoÖ$4©lŸ(5Bjì®în–W.Ûq˜z…%
”ÉàV«•÷ÏïÌÙVâã£SE8wùp(šK®µBÍ¼¬dyß©ü«¡I‡l±LÃAU)n¥p}˜{åÜ
ıŞP„† À±E½·p7• «Ï°²Vä\ª‘lX#?Oİ½}o1`W[Ä—->)´Ò%c/öšÅ%­Á.f{m£mGK]•Óê¡äS¥®
š)¯Š¾‡Ì€Ïº5¯ò¸‘:ÀGS¾ÃÏÙÏ:.™ı½t•U=ñQ©´à%²âIâµ ­,.ƒÔ½c‡ò~6‰ñr_°­Lùà¨é$ól½—ÇN33‡RÍ4@İ¡üÜÌºR<'ğRêÒ¨!Ü0	“Ê´i8GP Ÿš!MX.îjx™*DwÛ…¬.‚•G›	M+O=‘…€tu<cí¬¬%Ÿvœó‡Ë §à‘Øš4|JÓ«©Ñş_<G}‚¾<ßÕd1ˆ,ÀäjvSõÉšíG|zÓ¶œOşóaq‘áÁHuïö[ÅTZô'‰¿æBv®Líh¸ëÅİ§ıcXÅÛã›ëçP&‰Y‘îqñGÊpß¸@îÒ¨†8÷;öòşÕ°ÔXı;4$Ã÷As«Ğ´°~õŞq^TUh
Y>%_éB½sş–ıÌïƒ+ƒeŠŞz`¹ølÍ…R!%bÕ¯‰ç·T™í¯å ‡.;ÆHoYO;˜>i¬bzxó'ëD€£¤$y’¦ºÑ¶Q_Ò<6öÁD»ıü+* ÔQbêÑûÆ£sÎc—µ/[DÖb»½ÌŞXÔH0ñVcéİè{*æUİ5¿g^a¬ 1íÇ†€7ÇÆ	ÔYïj@á×3ê°İ—åã iVt®ãkÚe6 kÛgÒ%ğ¾¤TiT¢ÔaØŸ˜ŞØ¡Zú…q½ú\²mrl1lOgÂÖÕkx«ÖviíıÈ!Ó£ì«°Cv=q9µİ‹Q-”Óhb¾9j§ÊÏQi³ß>XÑí{Î…½ˆmÿø+åÅ}’N*ğ‘$ñG.!•ü§K¢!k@=æŞM!EHEsÜ]Áa“Õ5eãoÌX³dX:7D®‰-\§Ü‰C/gTĞóËµåüi^ø]z¨óöI¹3²_ŠÏÜ­ŒOcOıá÷Â*ğiV}À
²öõP2:Ñ›    Tø.IÜ’‰u ¢¥€ğ³L‹±Ägû    YZ