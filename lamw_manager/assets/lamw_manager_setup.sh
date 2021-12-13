#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1304148244"
MD5="4b75ab8e46d44eba0874ca670d87cf77"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23912"
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
	echo Date of packaging: Mon Dec 13 17:12:22 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ](] ¼}•À1Dd]‡Á›PætİDõ"Û™ÅRHÒ*rèô,v—4W“0¡_@Yt×¼4iÍÿ¼¾ü•a0>‚š[üu½7€f£Éß¸ƒe4Î•| !â<].^•Ûé¤íGTƒËÙÓ¥|DbLÂÎyˆ¶¼ÑK5bs£¢e8É§º¶˜Ä…ëµÏËûoáƒv
Á„îWQA­H-2L§Ett€³7jM ÛAŸŸZ®&®‚q=ÈlÜwÈOêA9yDü üÙ^¿XÎÇ:^ñÌÄ4”lCvkF&İöù¶¦É¥/AÌÇ‰È*‰w	…¸)PÔú(kÕ‚½Éê«G3øbşÃ‰ü´IÁ ^‹¬F«^ªsÀÍC¦Õ¹c×æÆ÷–Oªr¥Q'nH´İŸ‹UÓÂta³ş<ğŞİB(»…Tõ«Â ÷ñ«¶/:€D¥íÙIû ÿdèI”·G,ù‰|7iéUÊÖ©°ÊÔÅÏôÆ’MpÙšµ“ï+ *yñˆ8È´»iÛOİºğ%»Š©›ú³TG´GJ°¢@9Q`÷}ìË^ÆCEE­i’=Ì_ÖÛÈ©¯[Q@#—¼®ÚIşq†0RrZ½ÎÑŸÍ«QOu%Ts&›®ù =5ûıçà<ã€x¿Nëóî4)Àu3>±‰á¯­ ÌK€k§v™ÕÕ1İwhÉï×fèş¯>J¦Åä â]İ_•éß_CšKŠ™ıu?Æí#$–:â'‘„
°Èwbb5’¡˜òE0íÙ°ÔÉ¾ ñ^·…|Û[ë9aÑ¹S<ó,µúíZÃCRş	æíç_I¦ˆN¡lŞª´a''ßœœoãw¯Gf¾+õ¾Ëo@qHøZë\|Ï0+ñ”ö—ê+ÏnüÃ°Dì„˜;|;±±GzFÙy«á^p³òUÓujüñ‹‡Àz¹ğÏ›RÉëJPúå`Ièÿ¶¹£íÂ6àŞ7k,Ò´ šˆŠŒê.‡g¶]‡ã[4/EÇçã±z<ÏºiïN‡;¡B-Ro'sk÷ÙäÂúµl±]J+uÂF¸^ô0»ï‰|ö?àht¢ÍøyJüÏZe¥å5£é`æÅcÃ¶<>[ÑÍ“”ã’mşÁF:8[Œqúõ.Ğë¾iW¯bsş3ÂÆõCãÂy¹y¬¤W'*Õcx—®œ“;
õØY«óÊÊeo½ —7‰·ş	ğæ@C$î‰½A‰SÄ|¬I>/Êjï%4œ‰•)e¢ıùB_™‹öÖ’ÿ®jEg•¢cı~›oVÈ4ƒB4W÷òx(°4)3â)ß¨²êáØrÑ²}JéB ©"€±2áè"ssyTw•ZÒôSâI1hG}xãráz¥(w¥|Ç¤ª¦>¬*Ã7^Šsı7Wï@°æƒ5a›H‘ÜYÉçİ^èÄêÀè¾aeg…W<3›öàœ˜$ÚrKy–¦× DË”ß·X?“jA­(ı±ƒ½â2JğÒõ8r—.‡
¿X|(çÊu<ÜüÓFLùáÕÕûûå¸ÙÇï‚jiØş;|³oéÛÇÎßtç¨PÁXÑlzû²f\tB³˜åí÷2­¬Oş×!ò$¦1Lœ A1JâÇÆ3àFŞ^P*şü“nxOåçîgŒø“µiHF’Šjéb0Ä´õ\Ü9*A×A!HoÉRØÙıSÉHô? »Ş6>Í¬¡ÿp«·;^Y‡OÉµ~}çşfx1uÙCf;®x¤+ó
ÏæH‹­-ÁTÉm#ívÑ¢”«›9>lWmÉzĞªécÚbˆ!G_jEÃßÚ6&8ÙÄÅryo\m™&Ï¢şÆ’¨æ\İ³+·º[¢å¡eÑïdÕ¶ï¡ÓQ×%Æ
áÂñ¹ïè£R|›3ì@Ş½½ÑtœYÄçÕU‘XHòA8Ü¯¤€[–ÿBd‰ÁCjÀv’â³×·êŠ@‘R‘<ğ¸^ùÉaİ‰G,÷*‰„m@g`541;ÆRQóÖ˜öÂ^¼UšG©Ã×ØE`‰±ÕqfZhË/tÈñ%‰>7¯Ë<ßPNÅP¢Ì=ãêä‘LUEWkú"RdÍONXâe„zp`CG¦ö£YÀ}4m<gWÃaó•	Ëİ"Ók=»ës/‚ğuú' –B~ÖóáÀÌÈq•ñ+”s8LÎ72Ñ43Æÿ–—üîóBCê¡j³$k ¡íTJoNE=dğäzê3Ã÷é"W'åÙÀ ±ê¨_îü0Rû+¦ûz*Àe¯ºTcˆeÇD²Ö¿‚â¸oÄp Qïw.ï}*øÀ¹#R»doÍ4	8»$RR~täbğ²˜wŸ ŒvéÇ@gÿÜ­Zz9)Ò¢{-(WŠš“!ú©Ú¹ê *'4CöÊ+”®1ÀRUÛ
oø°æÜ"A^÷¡Ê'T¬À?)as@%Æ&¬Xx–˜(Œ¿K2¡^ø~äÙq™·¢Fx1“gƒ^"ŒŠ3r´oe-Ağ)5ÁÌèòÚ0Šb5Å=¥ûıQ])Üû@3¹ô‹îİUy¹âE7?*µª|?¹N)nÂº[Ôh‚ô’§T¾Şl*§ÂWh¤À~i™xWmøN6wOÒÉ<n$gH†ß)Ëö¥‘~êN©(~b{¸Ö+æ:ß#ïWÀÕŒ]
 ›Ş!¸!Zâ[—l’üÁ€'»È¿]ì_~14V‘€Ÿ#,¤7GoŸêş£•cHs‹øšüJ{—hô;ÕtÿMd²¬5)	ÖãÌÍ«#1uîOX		ïá‚ ©xó¾ª*î”XzOÂ _{ q:AŸûäKèÆön÷Cu°[P;""oP•@ÆßX·9mº€óÏ“6””IÊˆ!“ÇÍ›2+<Ì+Ì Ûü•jæzZ<OóñÕÙÆg‹6=gY,qy@Úñl®æ{Ç6LˆYA¹z~MI Uö¨u¯fp‰ª°ÍDúƒ%vúùj¯NÉ™MşbA¤b)M«wQ–]ÓŞx¼ÏùD!¯PŞ…Ê˜ú9ËoåoécøÖùŒúñK5ÆËk×‘Åzu5Ï¼†¹†wM”õ	Båf®™ .À¡	?¯$8~v´>I ‘\Şç@K À°Êëıƒ–5r/ş<r“^î¨õ¡y†D«
µ¥m†13ö„L0|#ŠO¿Û¶*J,Ç4ÓmJ¼Q’ÜÁó¡ìG›œ}&JğfH€»-m¼ªòZÜÃLÛÆ7G|bÉ=&Ãš¨38¾"Åùá¬Ë…wÀĞÕôí'QeÄ¾P¬QS××9Fı)8®Í‰¹óó(‰?hm‘!Ë¨÷>eƒ€F¦ZA›8®È#Eù´cr×
mJµê@DÉP×ş	2&[FÃİ¿6¯jÂš,ñg¼Ã
*!TÒWl³y¶‘ºÒ’C°PX‡³´ÃHäÌxxâ¶ršú»•¹¡ WaFº/W.‚ÛĞŞö›NÊoÄáôŸS`ÿ UTÜ­ÛºykÕR¢v…"i¡°ÚÚNRAüo³Œ
îí`ºBpeB&wmŒ’0¤»›‚¹TÁD;%#CÌ¸İAÔ’x½Ái»%u*dÂL3@CòØ1ïØôkÉ¹Ë¿ñÅ”±YÛ%Túª«‡ÑÅEÖ	__Ëï'Êà‘¤÷Š8zE¸wü4<Œl„»n{&PR¼‘ˆèuîmqı	?HdA5ÔO<ël€™Eo¶ØŞ¬ V`¾¬°ÿêª6U9–+ç]”Å0Ií§1¤“ß14øİ
[pèÄ!¾¶9s}êt†1Ü¨_¬½P»¡U^~~§Aú2•\ØL«¬‡Tğ20çWæªw%‰Í€Uhï°K­2Újcò)û86uÆ5gÊ¤2…JO¨«¿ó "ÇY–WÈéµ™â0Å&w²Os+v#a‡!c2(92Œ¶}Òí¡±a]ÃT:–åêÅÉ>¥ş	Ts`áCŸ	ûMD°;ÜZçx t€¥“€HnîqµköA*hW-Ÿíb}€pz5%ûªŠ\°šÎs|áì<"Õš®Ÿ‡ÏMÌÎô™º?ù­ÄíÌ`û¸Ëúäñ¶‰˜«Ø¡V©±cI-nÄÔíì
§ÑBòQè¡¼
”åU8kÖ¦P4Ié>öœ·'ƒ%‘	ÊûşÈ9 ]¢äjTfRîSùmåˆ«7Çìl5„ï3¦©\r’‰‚Y™Ş? ÜY,pÚÍX­ÕEó,-Às’[u¾mJ¥ù$	ã°rİÍâ²@üÉ¬çŸl¥åş+f@'çQ4·-êE2É· ¢×í¶;‡µÀhYó~ó;®ËFP†éS?j»*BÒ+—f@ÛùNZ#ëXJN)'Ã6 ×ïoüd×‘êgÜ$ğp'å¯P5¤ÕÄ¡Ë8ÇÍì1V,Éµ˜<ÈµÓM”&i™ˆlRµ°è~ë’Âyüv„'S¶:Ü¦(J±¾•À­ÃøvÉ;>ÜLGdî1‚z-{ğl® ¤¸Ãu¦½$¯—wu–tĞßœáÿ§‰^KC³}ÁÚê¢Ù(°/ËÒTÛ‹¯İ/'” Ü°Á|éy‚qOb0ã˜ğÈ¬‰¹ø<Ş{
èùIÃºM8}5¬†6i& ÒÇíq›ôEÏ™ÁŞÖ‚>š†æ ÁJ‚ç‡ÈÏåCc¼â¹K[únÈ_KF'T÷<¦ ©Kš+"k÷‰2ÀÃ¥ koàì_F7áPèm¡ìF¢2›¥ŞÈsJBEôubÅ÷-ªd§æêJn6q³ğó+nüû…9t8‘€(J¼´‚§½=qĞCK…_Qèå_¬‹[}±=É-%l~
àjj/c¼k1Iåí±±aIEe¶åÑ‹ñûh1­ïoÒäŞ~ÁùNg%1ëóÜ(L‹µ;rÚ³ëÇK=È ÿîb^€”]¢qÒ`éÔ-õö˜o7z:X€­JPÕ×âtóš¢BAS­±ımõ0ğP°„{à*I‡m¶É°–ŸK8x´?À_"­v¾OOY‰Æ<…®˜£ùAÇŸ‡¹sŒrÈÒ°9¥_·şïÙC2œD?îw€å_Ñ¾Ö²!l:«Eôl³Ò)–ÌKl‚^iª7øó,Ïs¤<Üçz5XêÁwPÌ{OPo¼I0¤A8ÔŒ5û}p²İé	Åä÷Ì6ÃÃD›æÕ°à9„¥€ü:Òúx´npSÌÈiúTÉrC­s=VìßüÏ·
P/\0u|şç ÃŸ4AÄz:qX—+GÿOrNòJ©rø Âéy3Q«¨Œ ÷°'µä‡ñ‹Ææ€$'’0Ü	Uİ÷ìÕ^Ù*C>„	Ø-×ü@ñXóf{»ÖĞ -§²¡ŠxQÏDq‰_5äb\×ùÂÒ(Ló2‹¦yÔ-‡ÜÌ#â­…¼Éë–æJCd.u•_¶«÷B"Õ½˜‘¨Ù&ªpêÙ~Jg'“ö ^¸ìü °èä(,rElºÓïŸe#UÅÿÙ2K¢*Óşm3'çúfÛ¡z¢ÒŠ£Úö¨Ñ£´#A¼ÅÙfJ—ºÂ[ó´„ÎM¾D.İcZJARÇÓş¨ß­şÚlPv6şL~†Ø€‡Rãà¡…°˜]³Zêİ”p*Şc¾>‡„¼Ó´‚©GLhØi©‰0¸n‚¶ _ïñp t¤/cUkª¾ÇÔÖ$²ëúFÒ?	ƒ·)gtƒÉ¬SÀÿ@À¸b£ş´Ö0åt}Â>Ş¸˜eøÉIHé³¾Š¿QµG.©¼î‘ÄşÒ _Ø}éY{“CA	8Hı"Š¬TÀß©]sàù”:e~™{°îx§WŒ?E½yÁpŒìë™=#|%Ë?©Ö^k»áÉ$¥?1Øh/ìY3xŠ—ŒÄ˜’—ëTÔ•Ú_6ÄVò ñî/)ÀòF°¼Ù\YPVúêkHİ@E\Ú[Ãg*/ŒÍû'bMjéA·ßk	ÜNW‰=æ‹ã™SƒxßpgñÏ™óŠs­t„³­‘M€C¹p OÑüÖäuëÌäˆâ¸}K†?p•O»Y˜ïİ)õÂ&‘&ğ…kñü¯w®Ï.l7 Ó—ÊæßÑÏ€¨kó­Éku®TşØTê)¿ NY°="[\SdÕşmüÁ‡z…|¼J'ˆJŞ Ÿ^ñî¸\,Ty`ÄAÁã„ëg;ÍF%M#C?Ë››à‚ŠÖÎ‹çÜ€èÏò×Ø8üæÿd¯\öô=¢Ëvü~(°}ùp¯_–ëÅ¦ïÛ~Ê¨êØ"Rá~#•ZDOÅZ'#aÖ¹V™v<èK!Ú²‰¥N:uk­PõmUP;

SÿT˜Ít ñ^ÍÚ§¯Ü2ô™–¯ø…Õß¿2ÙçtäìX9#è]1S3X³Gã»NU­Ší­=*B0°ŠŒz`†îÇ‰•Î+´vg+89ßMĞ|¥ˆ«¿Dÿ±0Î4¨Â×…¾ÚûzìK‚h²÷Ôl^_ã‘%nå™Ş§àÏü¬;Mï ™]ÜBª‡OÍ=#®óØogÍ(vH&fy„$ÌÄ‹½ù:™òF9­ÈÔG;âÎ1y–}FÎTòóĞÜu¼E—µô†ÿí‚;ÁN2y±Z÷úé‹£©\io÷ÿ#ô˜D%jrCe/“—®\´M×¶ùı]TLWï¤
_Nì#øõÀ­O|ëÿ·Çz”Ÿ…JÛâÊ÷×ª­6•*ÿ—îUSéµiv{3[Í&OGëá4ÂÙ©Q§À@z®`¼f²è=¢g°«Á#Mp=ùû21î¼ú¨j0hÇbgÌ1ü…wÈœG¼ÚéH¬gˆ…Ä] CC£„nÉ	îª'æMìœ	©[¾÷¾rCSÏí#/5iœÑÎù«èô˜…N2¬¾ûìÜÿÒ«Ôô	¦ÏØ|f.rSWmÒ+ĞZ*¦rµ“÷ŞŒiÄéusk¬²±·¾æ^Ú-Üs±ƒúó” g»iµ‚Ì²cËP&e%<B„sÔ±<Má4åZİó³!mJeg¹aº“åí”Çë|€™ÌsTB—î•¼ìÿcÙa²óÁ`çÇ´Rı
èã-›°áS[†Iÿr}²h±·yİ\Ú3GšçS¥«âáOKÌš/-ÚÑµ„ÎáÄÕãŒ\¥.ÛÎoÑËº{¨æ¹
÷n¢è*¤,¶”pÎ‚F±o™Éïä‰Zæ_€€>«šˆ\—-4¶‡ô.ÂTZ¶JR8ƒ)•ç†•@…î«Px–|]UŸuHÍ7;y½uùánô`õàMpLº£Ç­;NJõ÷µ¾Ã¹Û#øG¯9à‘pŸlO˜'m)¾ÍÿÿÕÇ™ã’ñHRbÍµ%œ’ÏF¡³MÖÏ>:’˜´Õ ¶äôvŞ‡$ì}¬İ-p4ßõªQ?ˆÄPô7bğÙÙÆlúÍªßŒ¯i)±í»O(–Jª-hÿ»9QÛúnï³íŒïÇ¾A.û4’—2ƒ84Y:Â§VOÀ{×•ëìÁkñ¶Ï\4w¿~D¥p>èYËlíâarêÅÕBNôŠe¿E«Å›2îÏ÷øØgŞÍVyËÆ@§ò»•ê¨µÃ@üyÛéúª
l\•æ î€üÙø/şJƒ×[s
 £Öì7ÈúQh7…¹¿kdg¹_@A`Œ¿gËõ¹ª½›IG§Ÿ…o™dŸ
Ø,:2Ä>ù3o/R#³6H€-6×ó€4ŸŒƒÎˆoÄÓûD*Í¯¯“U’ä´ã$x.‰äçºÏîb2´
d”ïCçsCg¿¨ÈÄ­eÀ¾‘İ°T"ZTcÃa$pù™·Èd¾Wõ«N§3I2ûê_éGBÂşZö+\UÚß9ÊØÉš
8(¦ìF¹HÀ@ò×•|¦J2An~ìrÑö×‘ ÷Íı`C—JÖ.ñWœÖmVÔu¼Ü½hÑ…rõÑŠH(\d#ó£ß=â‘œ¡R…)6¾1­¸òËXë¯–Ê».Hİmrµï"Ê<¬xbÕŸıˆl]ŸXI“èšxŞ"m ‹)¤MNÕÍ_À¡ÕËe§m+EO@üW,U¤±à¼µ ,\óú*jIº§VŒ)wïëÑĞ;p§GrÏ±ÓE¨2‘XšÑgó9q”‡mâ¯Z‹
ãpíğØgïHÓ¹ÃÛw¦í¼4ùTCzºîôçÍ[Àµ”‰/Š•Úq5¬rœÕBC•‹'3ñôİyI¥>±<y:£ê†Ø£Ø{UŸ-£Gæe:}4ær¼&Hsÿ+mP²ğw)ÀƒCx‘®áqE¨\Tø{˜ÑºVµ³¿éåĞ:)V8öÛÁŠë†8¸´áS‰c6.¿£´dÌ)Fö6×¥ª·‡ Eÿµ;ÛsŞjüLt1½Dı½‘&‚•ACœ›.×üh =8:&”ûpÏk­Ÿ,÷ÌËö¶ù(ûú‘í“ŞÊÕ‡uugÌ¥ôe2¬%>%ôoÍ‹ùw$öàIIs<|Í—øc­ê‰g½‘vvŒ„»&Œ>,…T±JÒmÆ J…«½ı<šïvXš	·.%yöX¿k•Ëš§Uf9t‡•Š)FhÕ¢C€_E87ah´dèrEMaâÔ­Üœı™	ô•¸ü‡êÌø—%É¼ªiˆZeŸŞŸOëA¹^~ı#™6 V)«‚%ŞÿOÖŠËœ©×b}M¶šÙËÃŞøáy,Aÿ³tkw¤“4rºƒ“ ;ˆç#léK1ıR›P±=zŞŸÈÌ7xèÿâ;†"w†ü%Æ÷róZæe*r©¡æìí»‡yqÌó·Ü¡j–3j_^¶QG nx‰LÀ=ÚÕk><z`VË!wÑŠGqãï4yS3Ô»%~Ãµ’ÎúW4¼)1ÓÚªÑ(Uq`Vİè2PjÄ·ã‡†¾ÍN+æpü:üœÈHà<„,[ÄÈ&EWèIJ6W–3IÕ†ˆiÈ¤ãW­e¯£i±ˆ6[¤Ê%‹üm-qó’j–ÂC»åÀ4I»î2Ï,Då±îÚ×İDåÜÌ
©aÉ¹/iõ½	ú¥còA]D“;‚RßëQ&ä»áo8jr² ø¸7›åÓB’ÎM¶hAV6XÁtGúYÇ+ŞpÇÀ¡JúùZÊaÔú:í–ŒO@»PßhY]ÇÊ9ÎPF.úú•úqT-Ÿì>9k\¡oEëÂ` ¹¥ Ñ€[%lz§¯n¢ŸÑ÷)"ô®P{Bd²ÉFî{õH-óÄÄ{™8yÓ(&}4@j9ò7/7¥2†Äê¯sŒŒ%
t6Œušc~¸“EÙ§i{Ÿ¥OjPÍAíï?ğØ|¼JÂDèÀ;æE«¨¤ôÓsu+6NŸÍß©3JT…Øõó@/*íù‰Ts>£Ç'ŸÆj:wŒèV)¥ˆã¥÷Ò-i›F÷y©$¶ó¦Œ+n€ö)>"“A£ôÛ‹»%•Ô¤ğ†äıèšÃæ:(6k•a¦—ˆY•§á!«B_Ê hfoş•¸ÜuQ1YÂ€'T4\»zÓ}¬ea¼¦Ø/Ş/;ÒÂNP8;Âİr6^ù5‚1qd|‰	€¯?Â8õ_~Ññi|U÷ßÆ–-/õË-@&<Âug±d(;,HÊÙ‘œŞ¯½Ú ”{Ìk#¹©‚‘ÇÙşÇÀxkzdo<æ—Oht’öˆPœõôieÊtÓ$³ªŞQi®nMu,:@süãp„6…)€)Ù2I_BDF`ˆk‹ÁV©„[AMaÇ–vR\rôå“ÿªFÙgœA$)Ø"Ø„½àç$á–‡ÿ5óGK²Ó˜‹(ë^átgù0‚ÚCG7TJ)<ŞçÑ-è C4ïv§ÍHQ¹™äô·mÏÏCö˜°şô½übqÅÓ'¹*åAÏ±a9{ç>r”­~Áå}K .eÿ¯A†ä~³ÿ•} ÌÈRP±“ö©µú"ÍrçBß¸-Âí_UGĞ‚£5Êı ¿ø,<úş°ß­©hx¢RõSĞ’Jè<ô}¨ŒK{éÑ²Ÿ‘úë\"a¾Ó÷(ˆk$Œä¡—\>ÏA±AÀMpùØëÈ[21›ü±ß(ÒpÃûn4ĞhAß·#phès¨Ä*­,SVÅŠK¡·áú²	¾~;ä<ÑlÛ8Ø
³:Şœ|b«Pæÿå)Ù;iX½Vì™Z±7m!
rAyÆKIò¨Ìo(ÔN¡ÃqsÀ?…uAÎ®³2®{‚Î¸
ÎÖ~'ì#§Ã¹Iç"É©-ˆ·²cT˜‰8‚ob©^Šï“`N†XØ”5Ùšn/j†¯p7‹õYÊMİöñ’,,-Ù¯‡í±ºùgdqr§»He‰ÂÕé!\˜T+—–m‚O‚w0Fõe½öv¿j¦rte¬£LY™Ã	Eë#VÊºã7*ÕBÎi±eá‚ÍO2ræ9£ñ‘ÀÏIËãµî	Øüá'É 	a¡›ûéPŒ‘BPã-SÍŞEtì˜J©V€Ã÷Ø¡A*çÔó+CPr-_Õä¡zn´ŞFL’çÏšMÅmâ¡
çëwÖ\®˜‰Ëaê¦\`&”Ó]¨Å-òø-7Ây™•š*¶ûPyc¥µ„Æë€[Ñº+e»Ÿ(œ'q9à5#%l°|y4ÜÿZ%õOòŒpU‘‰‡(ö	X8G¿ùD…%Z(a€Í¢™¢ÙN‚†û'ıjÄ¿„—™l·„Ã\»Ÿûó¼¶qöQÏ>®VÿYÖ>_ù-a’Èd`óğ¼Y«à&Xåœµï9HÀ¬oíÊ¦S¨²º1†Æ5Â·:Tx“0ˆğh1:ãc:—C6ì©Tè <C„ı£,“ÿÃ+J ‹†½ôƒïb­Ä1^‡x²ÜÒüáç‘¸XPL¨%gİX‡á‰™¿°~Š°Œá«ì´.ÿ™Õ>Š#ê]<×İáâüˆEÂm/¦Cö Õ)5¾¯~œ‘·Ÿ°ÈJ°ëì£¿št«f%ï…ª9‹¼†’Æy^jÆ5vşÕš+¡šiİéÓe©;Ö¿>ÌwkŞ¾w ÿõ/—“GŞX…½AqW—%è¸Ú.?/hcß2¤êí]®Ş  ³QfrÚñWÒ‹Àÿ\Ì`{úŞp^JdNáSS e@å’ÿ’Ü¾¼p2­Ÿl^ÏoyWø*c²qÄ+êJæàô+,;X­Ã…õi%MÏÍƒU)Åï‰÷ïHŞ’+Pšš¤ÈÕèsgTe/ª£?±lúôX“Ê×ŞøÁcw¬=Ë˜ıT|#ˆ<o'V/†5xLÖ`ÖÒ(CÅŒƒ˜]Ycb+gbKR
ée”+`ßyxùõÖô ¬â’7k:¥mÇK˜§çD,E!ğ8¶ypçRÃ¨ÒƒÜîµ;÷…[Z£éˆşí¾ã‹1ğŸÍFPW‹Hˆh÷x±"ŒTõşÂ)?eMH²Ï]ÃÑ³Èx*ñŸ]0ÁÖâÀ1é²/˜“æòıÆü“QÄòQÜÅîU»ü¬WÛâZ›rJäx‘û4+ŞİDÔu™â˜O%Åµm¢96íĞ4“Ã»9©»mˆß"7Pg4¶šğ<MèvÅ#k^ZY‚€äÚA$š‰ó€Ë3ßèÔ÷;è˜”>¡ògI×¹=v"_çÇO·EÈŸ®‡ÿ	ŒÀ™ÉÃÓ¤ÂÅmã—;5†I²8A7ô3Ø^ùÍŞş‰–OWñR“æç<Øşk™h#hğ×GÆåÁ“ó·Á°û&©xwƒJ[˜~6¶òœ¼i~¹”Ì€Â™<3ÊóÒc³]@gœ ™ÏŒòQ7ıãŸİŸë#Ä²5:ç¼ª °Y‹ê¤[£Â_{ñJ¼Ÿù_§åUŒæ,mİ¹F¢¾y^¢ø^(JªBÊ¦z•å.ù?˜(š$›–Ë~ªoÊ‰è*pİmvp…æ kªy¾¤O²“ëX=æùõJhy?e[£Ç#È$yl©QÙ`ÖüİmÅ¨µ‹SSÂ½@hNıŒ'khËRÄ([6Ú-Åç¤ö;LÖ¤Eént¦ç%BøºT‹³ãnx¾8_àfeÎ¶æaXˆ²MÁÂ5›Âûp¬oÛàÀ°)}‡Ş–V²ı÷Åí¬¸Uá–ŸK•±ßŒ{‡ª;‹s<j<¿/×…ÙvÔÙ™iâ=H0UüAq8%Á‹¢ûm—Ò …¡(ÙæÕm”x‚Ãâ"UÙ[ï·†o¥ßzE«YZ´p˜	ìo\ãìu\óñY¬{Äp¡ÿê“}Ô¥×6¬c|ÑÛ«o!vÙÙ{ùãkÎ`OêL´©r"À3×¿õ™šöÀîÌcÄ{d]·xm5
¬²µŞâ·õè”§!nÈ87É»òúšÇíGk¥vîo<FZ8,z§Iİ€Ãáî;¤@²­C¥ØâêÒDÖÕİ&j<?Ü…­Ğ·  å.›Ùü\B)Ø=]M¬lĞ¡íc¤øwˆgwù¿Y,íº¿Šd®ö6a%Å©œ¿†Ÿ­thgá;ÜÄ¥â#_¢ËâhÆx]¼ˆ>ÔäKnüUyG5O$¹m[‚ÿYÛì÷–­şX‹'OË[fs€>Ì]†;¬D‡ûoXÓ:~Ú7ßé\
B²ûáïYü¯Æ,wäÁKâ6e¡R°Ø\[ø3üOc\œ`Êı¨ı(î#Ì2a_rùÃç &O"FÖ*ĞÒ½§ğ%Å¯Ç­"µaK¬,?g~Ø1RêFnŒíĞ›ÅER/Q&m—Ñ©¬.ãÁ­ñ‰?ß*@Ö†ºıôÀ¼’+²A¿şf²t=¸<úæÿGö‡PiWCïLëï+cô—P
DÚ^'"’S­w(¹Áû¢:ú'–T&´c=4ØWĞ¢ÁG2†DøÓâ+Wír·³]´[¨1ÙHÉá¹…]yì	ÜC[(±p«|/_İzâôœRşJé¨ö(tèÊö".øÏUn¤i¹i{aÚ™xGYÄ7²
‡*W´_N]&UP³¿Mí±ÜPÔ½²0sñ”{ë²¶2K3á§N
[>ÌYc\ñ¸®-}¥U+>‘7²¤È^Š‘f¶Ÿ5råãõ¶§[CZ¢ñò½T°Í1§Ezm&(ºCÁ]ùÿ•}èAø½“|ÛŸqÜ¡±f·Á.ºı—pÿÙLWÒÚ;9½¦ª”HúmiIR¸ÖŸæOÛÜù{MñåÑ³—áuÁèş]Ïjd^+µ±`Òñ—"'xBÖHMˆ>O5¸ş‘£¡±¬œšÉKÜ‘tü_WopÆÊÜÎ_\J8ÄFáñ9HJ•>øAZO%yIT³İo4li/Ô;«L³^f6)5-ÙÀ|­÷ØİC<é`{<÷ñú¢Ùİn5·Œ>mÌ/˜‘.'Gv7GÈ[ujº•²¹½›ÇÁ‚ş„IÁûD¼œ†Mğo\ğwÜH)ğ*•B6Ê=¼›ò·o-uË+ËĞxÁSîf)ø¦}¨Óá/zu)lÂbÒ¬
Za*p«
“¨!iê¬!e9AX®Çı‰V
ïş Ãî.ì„%„ÒMİ°â(§ÏR‘*½ñšÔı;Ç-“ĞA8Ö4Ó’OòšÓàfß2bÌ•rµÏÁahÏşıÅÈ•ÈÌoGŠHº°J Ø[Ñ_RŞbW›»"X<7Â‚÷ãÉwJsyw:$, „.lR°Â¾òßYnç÷2Ïe#˜%rÕ7KD8˜ç:­
½WfíR%%ëOƒ4ä6’LŸŸç(û7y?+£î÷ ¸ì_çmÓÚÆã—W¤Íu>‰Ÿ'Z:¥OXä¡êŞéqåè’”ûKÑôN·œñW$´@wEªî;øÕ0ŞúÖ|”ˆŸh[PQ(Ë=.E`¬N,îÃ)3ÚZ1øó£Ä{4¹::9+ØßĞkíÎqß[/<ÒtT(~.ã\h¢åçóhtïÑÏ—5–ë\³kr î’ÇdpujÀ¬õ'
Õü8-CKcÃ ˜ËSÌ×`_j6Éı0µºğdû'¾(ñ®gŠÃ@´…oÕ¬Ã¬FQõxjf8åvğ~ªUnÒéÌçøÓÜ¢Ãä|+½êYBc†z‚ÇÛ(Ü–÷®ÅãĞD¦Û9¡à=wÁ(>HíŠÃ”!]ÌÅ¼s0){lL @€lfdpÍ•)Ğ÷¾Ó-ÒºÊÅÔ[‚Ú€êå¿fp"ÂW?`D‚Î¨ÕÎØÜ}pxN +Ë‹`d¦|uĞéaŸš@õÊÇÔÁ«Ä5Î"nªTùçœUì>‹³óó½V,„•;ÿ—–Ûîg¦”Æ—+šÂó¹RÏ¿Â« #òå†ìJ:}]’†`†— e4‘SğçÊÿª}öx_´€nößÁÌxÕ)&ğ¨gV ğäfÃºr(ÀVÔ„ã4µ28Ü
òzo6Uv‚–0ÏNXïí“wÂ)ÚÒ…ÌŞóCéÉÀ¬"»«àìîğAö‰kıGKàğYóvÂïP'Q¼YÃ™Ú”^#Æ}Ê!|"ÒC1Ÿ9…ÀÛ,¿c½¤1&ø*iÜ°Üù"6±F¬•ï$Ô2{³î[ÑÕ‡)÷ÇÖ´ #Vî@U¾‘´_·_\Ì4¬óŒw6`÷hÿŞ&¢M
ç}O´]©´pºÊı#zSˆåeÅk¹„}íŒŒT¦lÄ1g¬¡3.(leuôï§o$&¾ëX:EÄ³
û?EH×•HñÄ^ÙÖ#ÿ¤P¨© qAÚoë–¼y¾›j ½÷Nîƒ9Ò“ §Ìğı†$ÁnŸ£{´bôR³Ûê ¹ÊD‹˜/§Úï%S\]Ÿñ–eÇ#YR r…}ox¬ş2ì»O˜~šu?Mr`)	$[‰§Ìï|™|U6Ê0r:7åu‹Ú kê,¸+Ãõ¨û(Îñ&ß¥çŒ¦´u¦Ëj¯¹¿pM”åøÀj€´%tèaäU6(=Wóg¨üWg’ÂºcjWB–‚×H"o2Nü&#å¼Ê§løóÈïR;„¦gó5ŞDåë/`½¾§GÔÑpƒ±‰zyü%‚ì@‘†ñq¿¸şŸ$µøßÙ«ë[¹jÏ¨K°£"[çzl.şk²›ûsò¹ãR-8´•›àtHíHá¼sóÆØ?­c& 9®òÆ›”tøCV‚O®ÂÉÜ¥q³5²· ş
a.ídY°›§ûƒË6Ö‡H«üåœg+¾ÙÊÉTšG1â?ßÏóG'C_¥í¼<ÎÑ‰Kq<[M¿$ZiS nûCJ¤ıMK÷†}½O÷»vµ¨Û¹Á)jz[A©æer½«Ú²G”¦œ/Èvî8ıëy‰ºÚÒÎ{oGÀ³şÊÌpfMV«Í1D1.=¿ßšòÅqşy‹:¼xO†GzøÃÈV9®AG£­jgî†µK-k&[C-£KÅ¬*Iç ú£=î©ö*Êü,GY)‹Û’ï)+×¥¿9ìÃÄ	O(®[SRa“¥‡?À}èŸŒn¯RĞ<î‰#gİ6ÜÆø(î¹¾l9mmïÃÅÅÁôíS˜`Z”¥®7fZO£bJ¨ËÀ¹kæ0ôä¦†•,Æ­©</#RDçÛ©n²Ø¾Ÿ”Ía¯`æRĞkvèöü®1¯Ú¾íìÂOÈE–Õ¸Ùœ!8ˆ}¼â®åÍ5VGK–şQ¤p¦9AæÉö…+Bp7¬xŞJgæàU»øÓ`øìnøõF?,_n±?+Š§´"Oªß>"äæg@- |ÿñbwĞ„GYİôÃiã9ÅMBÖÙ×eÈpiC[0pQ*öhòfG^@ ãÈ˜\ÿbu0<R.ö×:ÃoÎHŞş<URN¸²ôzÔ	ú_‚ıi¤Ë]¿JÄ°wqÏà§ª8ó÷‡‚<JPá¹WFtv)nÜ¾8Öô±_´œ,</û‚0Pˆ˜7Óö:¯P)å2(ÔµœoŸ”ëK·Æ!r26#:Bá4¡r&¢‹ËSÚ€[ ÓİI2kÈÖâÛÔ?Ù>øJl½ 6e75ö ¹±p„Ê†º²¿gŸÀãÍÚ±ÿlæÛ:Ê¡—ópTs<ÌŒ|’5FJ®x‹ìA­µQîÎÖa8ÿp.×ŸP4²¯ØgxG’Ñ‹©áùl_
üeU÷íæù_rÊyŒÆòœ›ùÏÄ"ßpa©¸øé¤ë1Ï .å€ğxBÀšò6²şb\G ’)ätFê> ‚|zô§`}âòÛ}˜Š ¾3	d¯µ¬o(µª•BÒRi™,øÀ€Ù4ƒ;Š¬n9¼á¡GÆi\Ì™"ÆëğTÛaNvû€<ÓTo,7±‘LªŠE¾äœ5L%8$?6’É®%¹âß¿gBˆí.¾D1“Fü1‰×HZ¡ fI¶`ë­"öU×­ÒÔŞ±ÔıîW´ó0ğ)~¦R}CrëB¹Ñ™fÛĞIC€/1Æ<UÊ™Şj¬¸À™ñÚ¿¬vn“ÅæÔD­Û§ÌÂË¦îıdi‹5óÈ’7]µLá’ù ¥@¦ÂMõâM_ƒ{Å±õ½Uš¾7;øE¡cM¦äï'Y†ì[×Ï’#›x2.’Ö-ï™sSšíÅEœ¤ÏöB.ØÄKm­‡óc}+\ÃWO˜@‘ÎÜ˜»Ÿfÿ]¬ŸÿÚô<"Áô¤/Júw;]ÇÖ
“sªó1ÅÖ:Äšæ­œ¸]Ãn­lÉ­:WØÇ£ò#OKë\¹‰£õ'8=Z]ùÒcÂåæ/	ûÓª”¨ú^û†+b/Š¡ê2ŠŞ'¾öÍôœÉæ‡Óş¥ÁšØ8xó$I]ËÅøMİvãeŠ,>ç•i’W®Eu…íWë56c6b+¿½áàı*¯ç,‹ê[½Ít”h¹\ÈgŠ[ºŞèZVë.CèKœpÕf­EŞMg-ãÚ×øùyºT¢iùÚÈ¶1qV4¶Ô6Î½kìÀÇ„¦~ÏDAD hoÚ-KëÓ8­|®œUÇ³1¨y¿«gòA¢–~ÉV¶ûZÊ¥áUWÑ“—Ÿ+èÃ7ï~9†m½¹©å·9?T™w}÷İ¼gË¶_Õ9-ô™†‘Ç^:­Ò%—ş í(r_¡VÒHäô·B»X€+}N¶DMe¥v!ÑSŸcáN,YÚrœ¯/võ˜ª;	‹£ÄYR„"ôa*ì‰äFó;«£9@dŠÁÙñ¥mñ„U|uë‚Öz^…şµ£Á½ÍvÊ2åÊŠ7àSŸÊ2ëÏêˆ²OƒÅ;„}=ŠôhœÒ†¤8%ÂÎÿÕsŠÖœÍ5Â/ÙY™î}ñæ47:Ã‘ì,µó…v1Ÿ€ÆÚ>*t[ê€SËHë•ÎáİrKQÖ%—?TÚª`_{'TÚµ&™µúYÎ›ûğ¥
ê4‡<q0×ÓsOd²úÉÓ'/aÙÎ¤²…Iš¬â˜Ö—.ô ¹Â_Ï™ò+ı×¼¨ä'
21¾gj„v–ŸD˜+™äõ„r0ô>¬0ÜÈÇÙ‰¤ZÇğ1íj	²& ³Ñ;È!çO®ÏÈ4–lñ6òf¾Æ2HÌ„ÉÙh—-­.õVˆ¡Ÿ€p ]ešƒ¢”ĞxE·ŞqTB‚§àJ¢¾¬¨éNtÇ£s
gJ”pâPAnÏÿ‘¶şûLG(›|E`»rWP;p‚Æ$†ÛŒ?aø Ç{ÉdÌöú1¸µ%øUçî™é«± „…n3ÅŞ}±:}ê/`NLš¥* iEµô:XıtZ- pTÉ€Ú5ı‘ÉÈ¶Cê² Óñ%ïEÿ9ò4g¤ÏÒ¢œÎ¬“Ø6uİQu†_K4/t¨¸ƒ®;éØøI_ç%'iGH„`?e™·ü\h¨ÚŞ?¼³ş›**†kj–äNJj7ÆC Ùaë¢ˆ.­P^½ËÕ‹ÀJÌáü{„utP!)§]#5‘ÙÓ¯ñØdX×ry;Ì‘ˆ,Ê@fÓ±ô„~ìso`È¨+¥h …›Æˆà=R4C‡)€Å`VTÙ–Ğ[§yØ2c‰L2Ê¹HÕmŞûIà U:sóËÂaY?£¶	18µ˜‰=X_>Eÿ/>lö­8sBØòÁólÏ_’¾;ŠÚÓÂÉhÕÖU¢Ş™¹AílU–Œ@Â>¢inX©Ø#¯¦µÏ×+ìÚ½÷$­Æ3âˆÁAî›¾4ï­‘_*OÉKfŠpFT$5P»Lö:S b‚yn@g#1¾_1²İ:üI›·Œ•›˜€P¢Øş³`m'Ş4ïÁÎ:96“%!E™Ü•EË¯=î\•;ÿìŒav—¹ q!ÃÁêF¾)É¾Ğ'š—NBU€¯Ì÷L¡¬ú$È×´Øå$;mıÚØz“ËïlPš-•TÍùUAKñ½æÇo“…ïãè#"”î4uQˆ¶ùşeLJèOEë@jkdC4¸Î~‰£@0Équ»aı“ÚöØ]v¢úĞš%Vø@ù W@Á¥!äõƒï…A~A\£ê’#5¼n‡zY£%!¿Œ4)’å£¦U4ÕŒÎè…Ì¯pmNÕµúzÿ¸`á$»Ÿ>7JM#ò³'? ÊZÓG\«5ÑRŒ+Á46Š¶Õ¹(èğ†ÅkâÍ	fa$â®œñÂõáHÆèÑ­:›ëÎFóz±&‘QÖ3±¹‡TŞØÿ=5õ-6¨5Œc%CmåáCJ1“+ŸA>–lRqÄŠ˜Å~Á0?¨ÍíÚ0ÂJô¥r7\¼^ÕÙ0°YrT3¼i»íŞ$íü—+–Ÿ”Ø®ç>h€b|yl¦¤†ßÎœ§ë´jZ¹^]­eñ5BÜaÖß“gb"ğz3O}º°7yàÉªuƒ·3ïT×;wò*Ÿğ®ª]ç„í×œÓÊ‡ó—äÛ5³³@QìÈKĞû¼VŠ&şÉŠ+³óàŠÕ¹}_rnŠUÔKâ…n¸ÆØ|ubk×Úß“o+e(Yñ²­ŒXİ
lªA1ú³ñl6ˆ´ÜB4û¸m@ÃõŠÂÉ,#­P=ëKD÷A`16À‚‘ÅöëuÏÀì-ª&cÇH¤±P  [=¥Ù·´Ïulù®‘ƒJìÛ@r@ÃÆ
-§kWš8 àÑ-/ı–}kØ)¢Ti¯!ÈÒ}2fŸ
ğ™¿ùÓQxRZGùºatºV¢G,ÌÉ(ûQî[@+Ig¨"§€D*êÚ xÈŞ†›e]ı	ÿ-WV¨Çç+\áX£¯à",5Æb+¤¬QS#%k©¬Í'¿¾ub¢zÕàèÔşdûcq‰§¢¡¿®ûˆ<35/lœ½Lœ™ó×½/ˆO}DµZr±6WåÔjï8ú~‰dÂ¿Ü´:ìêò&ˆŸ…®1Y¡H»;Ü>,’}‰±İ<¾¤“˜™‚ NúW]Ë;ÑÚ?;£;_	f9«F‹"b‹ó*¶[:ºÈ_Û?…HËşš¢TışÙ:R Æ6ZëqmódšiPYtFçƒË’µİæË&¢;OÅÉ ÓÙ@šì5=©½+ó°ì\@©:EÔmqxi;pÅøé•Û®÷ëŸt¯­@şzzC±¡}ì˜²õ²›ìüdƒØo„öH% é·ˆ¤:@œuÉó1¡Bt}ìÒı~4ÒÀÅˆGÁLÄ¬WÑ¤AêÌ!x½dùùYÇ@çl%Š¢é*#ó>“ÆÕw.Í›]ªJÓ¨x¿êõK»T—Ï¨ÊÎÒÕ®œ4†¾¼Ï/x¤n·å!f°¢»ØÑ›= æş¹gîc™	–óz[Ûş€kÀØöˆ6ù&lCÌ¼Ñoä`éŸ„­+ŸÓÄÎ,üòş3Y¬JÙ!h5Fæ ÿM·Û-­•éìÖÁ›î{„"0ÈjJYğF¥İdî¬e^á"º‰êÑ ¥dîÔ´3_„[sØÓ%·¢tc6úÊ®^1Ô§ksµ§]Ÿí–tÌ
4¸âªÓµƒgšq¬Râ¹g†öf'9¾|üÏ¹Â	ü£
×ç#Àª³¢u
õPµc>·$yZv`kZKÉd-wõÀék˜›îÃ›MÉ˜CĞn1)wx›˜oã(„ã.l$¯
AÍ?IÉæ0g?±ŒÓ”Ÿ8nÏv˜ OàQ\?·† k²³Cˆ‚İ)•¢Å{P	ÖYÄ\íå²Ê!ª.}g
’Jª»s23èÏŒ_#½_åC”ÁÌCGŸŞ;O‚v–<L½LsV&ßÍ¢]ùò„ƒm' ¸VĞHO7²Úcu—K@oTëKŠxèZ¤ö¥‰Tu Õ\'ÃHÑŠ"&.mr™ Ø##i²›Òq
Î•1¸.İ¹"@¸v¥¡#µ°”¨ÎKÖ}µõÿn0†£œš!zÁ¨³jàO\YMè»q>Qjšu—ƒ¯‹oEÓh®âBC8«vãGŸ‹×Ñ@²ê›³r&—b*ašQÿ°‡”¥sÅdâ~DBŞD[ˆ ÂÑÉğêÒå6¯ïMHƒ¢œ ±wb Şv¶mÙ£±×S?½ñ÷~AÛÃJ¡L@äÓh³˜Ç‹÷ŠYXù¢×Á¹>˜œ4M–-¸8‚õ‰bìßw$73’ÿÆÂ‘?şúæŠ`¤}J£wYÄõ!»eEÊFOÉ¡~>Ş> Bí^éÇÉw¿*~vg¦£aòæ£¦{ÕQ4% …0RÄ¤†èv1Û"=ø‚®Š7ç“¶<dv‘$*«äÁ32Æî¤úÅ“¿XTgvkÑKn¯œ—së‘SÎ>ó¶.u4 Õ*É„òÃ>—ä*/]ÎÄµÀÀ<Í	¤Ğ¯%Ø‚}ß(ğVz´X„²åÛrKŠ&zS "¶»Z=Ä|8åTÎ!Ãÿ
£^A…Å”qåêÇô	®9Ï½„ÅâÃz-¯K¥WÒI†Ëâ½Ï
¡	˜>ƒ}$ŸÊ³5ÍÆ„˜I3.t€ÜîûCW¢¯Ş‘÷ƒ® æZı –µ
qîÊgÀ±6 »ãB	ÙÍ'e—ã+u1D®Xyã­òR“R;"#ÁÕûUx"œ­ëúƒá\ĞPÕÍñ—$Ññ³ı¿ÛÌû•®ÊË³9âP’ù¯m¦ˆŞLŸÅ¦VÌ…{şt\%?9Ò aCÂ-¤4,»ó·©*¶^c‘ø´Eí™¸‘ˆÑı~¥¬ğ)×#ãrÍ9v‚ã·úL•˜#a5úg‡:’f«|ÖûT¶<ªÕé£Ş'†ÄoMt2í8ŸÕå'’‹miŞ:6·£â	«wuØ Î"İ@è†*jq¸ÚAWq°psìLTÛ½Tç×|Kˆ‡õÙ5„´ëDÛ ëXx?ØNªa
õ<ÖòŠE#C#×Û²læMNéÏ^ºˆòwy¾v÷Q 0-vo¦íÌĞC1(,;M»‚:ê²PŒ*+àgX‰Œ7j¡aÁ ¡ïáùH&ô#±Tã_=jİ–Ó˜Ğö	êØ³íÇÃü½ñqkI6(‹5ßê•-³N¼[z	/Ë–‚b‘N!îÖ+ÊüL|jÏ<­q¿õMÍ1ãsŒf“:?tS=~DØºá¸ì§¶d†­‹‡Õ#ûYÆŸwÏ‚š_Æíb²Ğg?äÜRF4äT,§Ñübhk˜šŸ%7÷òeM†Æø•Aj¼ål:¢yLş(†üüByslV¬$T¯J4—·BĞSXˆëòŠTû?‡ô»?İ·`
:GÖ“%³¦¢•i.‰¾%‚3öæ¨éïGÀ:é,6û‡úã­Ÿ_PÆ‘Ìòyr"Ô¬àìiBQ¼Q‰$Ç¿XFŸü&øˆŒ‚wÛBîÁ&-0;Ñ+ô»m½tŸì^h&œ(–Câş‰+œ½ÉèØ‹åd0)[Ä‘_tîv»­Ü+0]›¬HGú
°?6]š¾ ·KÓ~DÕåĞ|n7”ƒğ?Ì¥o&`âÓówèj>şGÁøõ£MÚ ¯:n|$\(uØ_+PùnÕ¶†¯ª<k ½9ÿkÈˆ
æ!évqä´$ø|ìàÌĞ8¡rsñ’$<ÅÁj ,Ò	¶»[gíÃïîXà™ –]Q¨,(·YaàQ“zÆXR‡R±­0‚¢«j$d#HéæÁD«YÙ%P¤è<9lø,m&¡!r±†ÓlÆQk9¤•÷Ñ@1Ô*u	~§r“åb²ìÿ«~,€²­aÁ6ZON'+üpx¦Ç¸ †vÕ„xƒû‡ÆÌ¡qú°ídÍïx‡Š{Ó‘ÿ¾Qº/Ek¯(÷•jê¿ºD·óöGõşÏ 	é­æÉ²üíü*»ĞÆ€AİüºûIKäººÜ*¦ŒåpÚABÍš‡EDµ—¡ —`:­köéjûc‡¸NF•£Ô'eÄêËeÃ"\.P‘i¬`Ê6GÜ•e Î&\ÒØƒ/äˆY>áB<sËrøa³lÆnqfüĞ¿ç£`Ò`ÚCf#ø÷”xL2¢d» &&ø?é< S]’{u¼Ârb[&‹­—şÂÁ`9Nù©ÚÒƒÏsE×/r·5çÿá-x‘Y Râ	ÿ—L`i\Ù†Š´Õ8Í5¯
²»i´O[#sÈüò|ÄÔ<ş¬
‡İ<$ãQÔl¿®&¶PºöÔ¶!œiË Ûí·l4$ÖjÎóQ™è¦~¬Eµ†|ÿqèÚÓIÔpÏ}(Šº.õa’O’O#G£=Î„€Ï®}YäÌ$åt| æSN—ußÉ  cÛë	ùyĞ–íS,šD€´z£X—-£ƒa‰Ç;|«(xdÀmÜ%êÁE±vKè!Øg¸oÙ·ßN@	dºé¯€†ì´¼ğ, –C9êU—*şçÆÄ5¾ë—äfPeö„¥ufË§)çÙ¦jê`B´Æ>iH<
ç=ÆĞ­ñrdĞCõ4&4 tG6Ç`¥%'	ÿS]ì¦æpÀmë2õ¶6¸%è¬*XÏ5£É)*£cgÊ¿¿_ñ×9—uc—]­ÔÔ;áÈ„‚vjrzƒºù$ÈÁË%{¥'.öNWÂ-iÂ©â¹sJèµ„ûwGNŒ>|)à‚:K\\ó‡¨Ü ùPÁoÿİá¾
.r°÷ŸD<1ÍŞ»Û­â#î§šgûÔœÅKGF‰dŠ›3·OÒß˜Ô½¦Æ7§¹¹õöLÍª§¨·ÉíÛ®Âk5RC	
ÄÔâW+l*Ñm¡êğ„SÅ¾·fºÜ£ŒH»¯º¥	¨Y=ÿ?y'AÍ°¨!VÊ\åıb™D§˜a¥Oc^„Ê¡ZŒ£9ı('‹V¾<H}·Ñ–äy"®õ´¥¢¾f€!:Vxaæ6x1'7ßÕÑ³É%»*¤ÙìXhOî,‰—™*Ò0ÑŞôî ÉbCÙ”^B3*àÉZ¯è¡;Šïò0iøÅho¶áğN¹«A/½h\™R®§%eúD„X#¤¾ÒTaıÒrI®qdxßó´½…ËĞMÊPöe/„^ÔGh}øaTÁ€ÅD›”º ĞOÈJô&ëú—’úİ	;Q0İ-çıIÀÓØt˜l-É#ÌôÛàÙ‰£È}Ñpø®ğÁ ÕæòÖÚU$™ŠÙ]qßïbè˜f;{m¾‹¦.¯®øàü½[0Ï…_ñQ•‡ı}øGÔà¯bç„€å Ò•>F±ôà¡©%šØÛ¾vQ‡xF9õÇ«ªN‹«ywİOƒ”áÂ?æ@v~4¥…a.w¡ÛƒéSXy].8‡¾GŸsÕ?½´—rR_‚§ãtgˆz9¬«ƒ‚ü¢¸Ønè©&SGğ€—9Óí=l`Nå¦17ß›å¤aXc~kTÂ—ıçï/¤?åB8|úÔñ£J
±+b-n§
©Y.¨ƒ6:+°«)­{ˆÙ¨ã9UÏ'5ù­§ˆGÏóèKïÉÈøÏÄúü)ş-Ì,î  öÎåóv6ÑT–O}üsa&ã±³‡\0nı˜½ÓÇ«UgN^¼ıWY˜ùn JKã¯3IŒe|¾Rmµ­X‰ÏQZuÁ.fÎiV·Â€%‡qşˆ':*Ş‡bh¨kg¬5w3«E¦Ì§ÑÅğ1ª;¬îü§{]uŸ@‡;R»-HdùåU„°†2ööd7ıcéMHtJŞ£RæK|”^@Í²³­%Ç@´Şj,‡MÔ^èÁò:aì]¯ë%ïHáî–sã?}M„4
ZĞ…]²0†+—‰÷ÒÍ²9RÇÁwoÂÀiRè¡g&Ò•€£˜Ù.iËŒ óÙıÊ=Ú•¯ú¥!H’Õû\÷[&>ùóml·‘ŒØlD"V¥p§/ˆs1}<³ ¥äg‡9£•öc­İ¦‘ú
‘ßï_˜Æ|ßGò8È»&ãˆ~°ã×÷Õ6Ğ=Í”ÊvÛøÏ÷¶İa™P@X¸d´t´!ºªÁ!©öùˆ PùY°,;mQ ¢gwÖ­ºü#Æû½o6u”¹é¥Ï)ˆ».DHFt|›=Æ!_‚c^)Õ®ÛµxŞœ¡e~Q©ó²ƒ_ÁF"ûïOãqI1ÂvÖºôõå0P«°Ò$.V³,äÌ{×P•8ƒ´5ù~¥I)Îş³eÜu¡ÖqAÁä{r•UšµI ±„	X4zØÎ˜‡‘<Ö£ms¤øò?4A=!]‚UVƒEÈ€Th’ìn˜+é:†™'yLu…ÉüÏÉt‹¼eíû¹s÷ºù¢`]/ĞOÜc¹´SâÏ¡¬UoÒ¯ =#lòÖÃ@tl-­­nná(b\ÈªëF§Hu¦ıÔMÃ](‰ËJÆ0ö—ì¡6²©F½Û.—ïãÈ–>º`È>È!”Íc~ø#Y‹x8ó'£ô½yşA	vêµXJ©Ï!.ùÔşÀ •@ÿ/ªbB·fùÕ¹Ë Š¶;YşÚ5Ìt‹!e#Şwæ™àï£>nÒÕô÷yárWóî½ĞeŠ¨mŞ…I5ó_œºJMI]JjB4Æ#Ï~µI*C$Ö¶‰–6¿£12!jÈMÃ÷ùÉR«GµÎL°«mó8»lZ6ø“·˜+õké?L¼¤î{`Úï/©O]±If¶ÎIXd¤¹˜aËG¼±Q®çÚÈs 1èlf5Çwù5ZßWPÌÊÿü°ÚŒ§¼Á2ì€ç›$ø[à7ÕDëíĞÆñ?íØ6ºàbZÆ”o9³ğ&(tİ:ÛşôWïï˜;©QıÊåm¿âƒ"•rMÄ§AšnqÇŠwD {U›ß"âáÀ²-£sú"ù/Êtkšl:45Ñ®®Õƒiª•óiØ
8a»¶ä4;O†çĞ´£(º¿;(-Vø‹1æ³hç[—‚¤éÛlûÈıÈgÍ8ÌEy´`ÛàOjØX0üKJ9F¢`&Â±'5<é]°!÷Ú.ö!İÄŠı`À~ÜñKúI€qs¸²*54~Št@“vØŸªƒæªSğd{ïºˆï	SeÓG[ünAŞˆ%¾Ä3qW·‘dú%“zk8qÓjÛÖJ¹èİp4­§Ä.ú+‹[0JĞÎ‡Ò)èœS´PêSe¿]5…²2m‘šÕÒHV54`Ê›g7™RZ:.’8ûÔR%eOòğh3KİÙh5Ë^»EasIôÑ¶#İ#I%«‹öG\[@’Ô'«”öeÕ«Vü[Nœû	‹=ä]R	}sê€ñÕ›õò÷DS&b-VYä©®ÆLo¤q_{@[Ô’_íçúîÿ¬êµÆ¶Oõ<ªÖ|c@´»v¦heÔš©ä‹+— |&r=_äFö÷Ğ* ø¹t^ >qNÂïtn.gçAîŠ;ÏgåÑ†ë7=S”ª\<©[‰‘{ÍÈ`$Ê}­,\t)gZùüL>P”åBœw\,02ü”êèô
LIkV’?ğû{f2ûÊ)ìì¿^È&ñ™çæ+©$Ö>:AÂÃŞŸNTd¬>é¶÷Œ­îˆàåQ^«è¡²îàõjyÿÒ0@ú,`iÍ¨0ŠjD«]T¥V4ÖFÂ™Û~?ÏâßXÔâCòRÉ;µÜ§”u•Ï1ô–ÜçCø4fŒğÀ
©‡òşùI ¡ 9ß~ˆ­ĞG_n!´¾dÏ…zšœ4Í÷…Ç( {÷{DBZ?e_
3]LŒòÂ¦‚‹5^¡`|<Ó/yÚ_ñÈd´FC§kMÅcK?p/µ#ŞĞbbSEö&tÚ>ï¦À‰ÏÃÉ9ÂìDV$Îİ½du?åÇ(ƒ±ÿa+};!¬åq~*"Ÿ3°ë“&¼ôöî9:²ÍhÿÊ˜ÙH².ø»²àƒü´hûŠJ~T%Ï
Ó/ˆÙ&},|'·9U‘ßîêó•‹v­vR†Ç	ƒ;Ô†Á|úÚÉ8;©‘Ò:b›@n·òÕ$]Q¾V“™yqa[^Şêzd£¤v0¬ÈïIyş^z.Z3ñ|Í­$Î©eù¾÷àö«9
jŠ—êuÖº°Ç@!«[dDDĞ^X"( °Î¿“/\{‹º˜î*Úf¢ó£,£Hğ¼Hù8@ÅY´S–~íÁI±J—¼ä	³+½¬Ælm¸lÿPEdÓ }ã	­â$˜“:úÉKŸ5Ğ&BH:Kµ‹‹×yˆDËû ¯AëÒP™™õ‹@üÈFìX D`›ß›DÒWÔáVÎ#Rğ…üMÑ<utycß£yß­ÇRˆJft¬ŞşÈ5´‘‡…!9#tŸ^É¾Ñ™)BeÚHw,>kQ6¦Àq®e¶Ï•j%óÅqş.çÂd#¶Æ.uYÅ(FF‘ìN›¶°çı·ß'«y˜ŠØÕ8 É5ud¥Öæó9°]ûY±Úc¹ùğ£êü¢p,»Í€ìËtı£•î¦fU}®4£¾¨ğdã¤!u}]±—ø¼íDåg¤·—è'$~aÃ£n¸"k¶¹ÂWx%rˆmjÿãúöSÁôuåû<KtCó»<xè©ÆUyódÔîJ#`õŞÊœ'Úm¶ş²'\,5ÊÃ2ªm5î®IĞtõ.:\Œ"ùÿÏ^vš°#ŠñFïœ1ıÊ8âÑ±±ŸÚ>R¶Ëğ§á7V8' ¦_—ºÔ4~TÔPÒBÀw	‹6#ä~lµğõÑí¬²!Èü6×º«ìã®‡/ü ÉF#dkmÇV)ÚÄ/í0©ŸC½wó¥qİá¼Ê¤V¯O’ŸQ-u%V;Ò8Å1Í"Ù¶UâÖ%&¼í¡H)¼ ø6ó!†Ï~·?Yı;İBî¸ŒºGŒk9Ëè0Œ$†6‹äšÅ<6ÿDJ5|”X¾ãÜl¥ö«‚?$M„]JàÏØa{'»˜Î`¸bªı0MOfÊc2™‡>Ø*°E›.²Qü5Seäm¶äùVw^×Ü*ƒù[TËn‹‰?ì	Á5\LORg”È’âMî<8Á¥u†vÈ¡Îô7«¿Î$ªZë^{N_\ër’l`Ú3lú±m÷IÖŒ§ÏøWJöáK|zæfd®†¯`´flld?Ós­Âz¥ ŒV¦°›´@ãmOÎ)x³²E×å€93ĞZ@Óa\=×œéã¾¸ŸgºÌİlÊT8Éòev‹å×â#•ºOqNIËnõ[„c®ïD§øµşÓ^¹Èä­ $**·‡ç6.TEgâÌ~ƒ8‰àVP—ƒWÉdNõûÍŸ€5ÁşWÙùVàÿ¸œ®Ö×ë³ğü˜£M%í›02†İ¥2Ì2%‰MßZü·Z‘ß2òw‡>p&½N’—nĞ*öHşğ•x“§Â°V´˜`“æîƒŸğ?”ê2"oö•Ì¦²‰ÔdCzÂ%Ì--–%ç·%Bİmö.u&I<ÅäA§[É²Õ+ùMc6Æ.÷pşqğÜ®ıx—ä|ÉÇ6eÇ!L¤ŞÈvoVô„ªâ¤*•jª‡àØ^Ş’ÖQ`¼£FöDŸ§M8'$ËD»ï_ï¹ºb;À‘JşlƒïÈ>¥ƒÉ%qİíjZcÒ!ŠñÂøŒÍUgOµªKÆç—ƒ!Ù¡\¡EM^•Tí([û¬4È‡3zñmì2 ûwšrM™ëO€ñòuz
[je`MÍwCüJøáı¤…Igå–c“Öƒó¶6w?fgÄ•ÄÔ!Ğ·™Ÿ§¥ù1Wœ‚ã`ÆÇsPN@«H˜şº©ç…Š>º,{şÚyÒ t±Y‘ÆsMdµÉ«­xĞ
†añÆäú“tíï9Í‡µåpR@Ï1Œv„–‚<È#†O#9|Ê§jÒè+•VÃ#SŠíeÔ ¢9nİ¾szr© =äÙBè Äèğ">Eç“IDákAOÎ?úÕ8‹ËÓ‚.+åI•;í@C¸ıÚ²H¼–™ú²¶J"©	¡(àQG—oj\SöTZhW¥¿Ê£å) >4Ü‹fµ^gƒ9ò˜„™¥¯æ”[‚ğ·w_Ø€å~-$ãŒV•ŠÄÙOU ş÷/ïé¯½	Ç^>„/â,43dx$ `ı«ÇĞg—MÖÀ=…Ï7°yÚc©Ï‹ÑNeÙ°‡Ç­|~J„°`ñÉ>d²#½ŸÉ~ßèÌ¦R¥¥§°Â€>Ì6½ü#ù2ìîú¯g0Úf•˜ïNxJí_²ıò¨IC‰à›„&uiïãL@ÄJ&®=>6òó©	Àr¨R7oš–V½nH“Y]Ë5ùûä]cc¶ÁÒü ÈÍlÆXŠ	b§—D¦Z£¹÷v†¶şŠ„ğ‡pá9­F‰^×ÁÁTZ6$Mt?V›=ÉÄ“¥<1h¦şˆç¸Ô`œ«.ğfÊi³Ü•¤*I¬0âùr }8ŸR•&ˆ„Ã¾‹Š{lÇÖ'!=‘şáÈË~Á4úyÖ¯¯ˆÇzo©¢¦# ŞZ|œb$¬c’Šu6ì›Ì‹r¯ää0_x"RHàíêìé1äa¿;k#¼ßj,mw+Â'ëñõ416æÛ_ÅqËY P&+³àvÓ.H¢ĞËèÕnÒ’¹b° íG!.>gGTÓÙ˜)4³üç·jìtÉ€ìÀÀŒSŞO¿ÚiQ¥=ïğ_>é(ø'c’ f<÷ñEz¥ÙØ—£†PSõGó`šiçÚ÷'ß´Fê
K‡é·õ5ZìJ7óoA÷ëcú¹L2’hCI<2°5@0ò¢Ç~…/Å­©ßŞxå±=¬¿f©xÆ@,×§P™ò*’dÏ%\J?viMD1Ö5 \"tëFdÑë/:ú´´İÕğK;Ôv7Î6kææ›Æ‡mÎê:ÑÉçğ”`ÂùGpêºSä¹O‰ê-T|øÓ Qı/<ÂÊ1€/öyL½Ø
~ŞëúŸÑn7zíw:Tâj3ıM2ä0{ìíí!&œN¹òu†:gî£šùÎç¯WÌé—Vq9´8¹é
r¾Ã†r_²;İw¢œ“#¯¹ËìŞ™ÕË¬w‚Ä¡iTïŸ"Îù;ÇK
9¥¢QúçÎ6‡¤SOWã*Š{Ózz–@èL)´J:z@GÍÌ©&XP±pà
‚ ‰*"}ñÁ„¸¼Şo’1ËWõİg>”;©•Ï*û7şO…oÜñR§Ä^§l¥ÿ ;'¹‹ˆØÖd£Yµh'^ ŸO[TåóB¶<ç¢}KñKdfëÿs[¬Ğ&à.AÖp±'1"qñ]{øÊşK¿“Ê+o ±x½;Á”ÃawS™™İ+5p®Úçş¯&rW˜ï‹	è“år˜_i,Æ;ôX
;Mç‚!ÀâLk¤Æ¹+dŞ“^D±²ÊŸaö+‘D­¹m²¤ßÈW‰¦{\†gtàkN|`N¬Û—Ö èÑ­µN_m¼a‹š±Æÿ+ø›[nõìôNˆ òŞ¾¨Éø²çÇaÛãûòeªÅüC€hvWvÁÁÊJ?ä5µA‹€ßÙŠïQ™Èôì¶SÅu-cu$c‘Ÿƒ¶G¸:y-Íıî@®\dõ ûñ¡Š;;û%t`ÄDcy ´;3ÖYN:î´,L¯äMV_~Ë¯îŠbÂÎ —lÇò5éT!âZXÄtrê[­M"Sr‘‘Œ/É5tQÙğ¥ŸÓíö7‹~Òè.A N(låôYí^„V0$°ÜœÙå[|ˆOs~í‡$Ã$Zü×¯$ùË‘Š»WUá$8‹ÎLvóÀø¥Hó8d]„Æõ1ïİ«<+SGF]¶öÖf,,XGtºkò$!'ÎßĞYXI¤Ö|5—èéH€Çó›­eB¢„-*øá-ÀQ¹ú¬,yÅó0€¿IdŠ$EƒÛû -‰û›îdqà< ¶>]DÃëŠ(˜Y´mNH<Ş&ÕÌVÀ®Å’±àÙ§òâH†0¿H‹¬š5 ­³km#…i)T3Ï?-ë:Ò6€y–Mâõª÷¹àà,¥SªdÎVÖ—º!ƒÎ‡²Û×¸YúLŠMˆRyëfêKŞÇ¿åğWOzÜ€Y¬zÎ£»ªqÆ[»è	¾ÊUdk'›á‹b$n–‚#YŞÌ^'ÁØÀ à›AWªí°Ûz8ª"…1ä„`ˆPÈš -ŒB  ©¡¸zYDó Äº€ÀÂ¦L±Ägû    YZ