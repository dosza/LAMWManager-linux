#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1260929669"
MD5="368426c6360cf50f66267292a1782c4a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25000"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Tue Nov 16 16:07:27 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿae] ¼}•À1Dd]‡Á›PætİFÎ®áƒ5W©•;ÎX«†¦=“a×¶SÖ€äÏñt­;v[?*â H_á‘E¤§ê™QcSË"@ĞŒ6d4ƒ–WHMÿ<AEt„Äı4AÖWÚ¿y¸âH9ÛçFZg€à›Ü`[’Dz€dGZÅ%L¾`¶dÙÿ=Zµ–ã‘µA§0vÄ›h–VÆ" Ëá8²´ğÅšğZSÜP.Ñ
	¦‡·@EdQÉsCq‡T¢ºT:¶\äbæxƒ?kz4Ñ˜ä[Öc’îN1SŒpÖƒ>vd[Eèçì­[“ì†\É¥q¸Å&9pPS\/÷éİ€#Ç–Ü)»RœgB9î¡×§ĞÛúòêOCûæçK´Î$ÇR¡’ØPğ.r&†äÇ”j'g>íÊ¹V“SÃï¤5o†Ã	zs´üÙSVNoÊmİ•}`Ä¤¢â±Ê3N|CèlNƒõc_Æç<èİ Ã}$ÛÙú`ıÎÉ2"‘`*‚ÖXël£ª¶¶üoôælîI¼éB€éÛ{ÀĞìö5qy¢gy2ñO•cXT&Ó}HsÜ“hM«C)}ÔLP¶E>ßƒ1Õq[•h†]ÄhÀQX:Ø¥â—ÜÁ?X(…¨ïvnœYvÀ(/óà›ä50Yãç-#Š 6­¨g"h´Éu£S<-^1«¢_XéC±â˜oëO]+à‘>äÔs-3\M¡Ğo¦KígÒF*zÜ\li•¡Ÿ;¶ ‘u¢ºVYwÃšé–ø­¨YšŒ5b—˜`y‹ˆ]kîC‘U:Õêoàk¥=#ïÑwäõW]ˆco(9S?¶JLí
O@ã¶DØÄ#"’F9	®³áyO$lÈÊ/+j¢g]˜Ê6gT,A—4@J„.a&”!Ô‰•¯ÃõÊ`0{fKc’º£A Fxëş|å;û:=le9ÃøwÙ‚…Ì¥fµA¬ú/1ÄŠÜ&º¤ÿ©Ş˜Pì>Ok±b:pZÜ6‡Z#gg•g›dŸÓ_âÒñYõXQ®Îk9i™û!U›º[šÜ™–æí–¦yz~4«Iµ0ªØ’:’¶ü+ñvÎdJò›"i¥&Ë¥2mğkö4ÁıtBñÁKŒ€¥…:jĞ_ò!ØæÛ«o’Â4ğ™9@ñ_»!
‡ú‡ ä³Áï(à rÆ'ş‚p•›Ñƒ‰œé:ª·XÇßöwk,÷D~³g¯åaù)!ÎPjºÍfƒJİqPÇ»:+ê-ªÌœ·â¬¶½%«…&÷‘ş"gñÌ¢÷©fzXN©ÛHúª2éHDÀXèù±2ÂS]„+bã‚ªéœçÏFÍòèın4¨–^rÄRy™éú<Î×Ñ¿è9á™ıÇŒšmƒ	³™şğW ~j|°#µNÁ÷_SŒÓTwÃ‚ìá ]:­ƒ‘%A•øHa„‚Ù|çZ~Æ*UÃ°¹‹ìó@N*¨ÊK9aÌ®L<±§‰r¾®¸În­ˆ¬«È©†uµ³CV9ˆò…ˆ„áPâ:¶Ì4.ğ—·™¨ƒV‡Jì
ûjÙ{…rÓ”òlˆQp¥¨j>œ2‹Ä 'GZ*~àk1™†;j¥‡Ò¶8CÜË9Š€Çì—g)ßş”ÒÍMïÍ0«’ İ'|£\ÜSÑÉÍfšÄEßWPë×`é#œ¶·|Ô²6ö²¥
wckN'ó¾yÛ/Á[|ëA1Ä}Ãr–=ê’šàˆyÛÆÁHG‡Ä’¨P+qÇR9ÉÕÍÃ&Ó*Q}?UŞ0½º > ğÈZ³>wå0#¯Ô/‹¬` Şp¯pJ×û¡¶ÚËë·’¨/3ÍŠâ_M_ÓR½œ¿O)OëÛÅc2Ö[±#ß­0¶á‚6üçç9­SIŠ@v«Ãr |s©¬½o¯!Ñ·-õnÉ;K¸¦²OÑ—Ç;¼Êiÿ2ÚÉ%‘ìÚçÇk˜npã\(}Dÿ~Fâôòé©ÄEOhqñU"şğ£†®jz|Bç´;‡èiûé¯CüÅûÛù‡x4aNùL…ìGŒ[Îá~úpúİ†õìŞ‹U¸íší¯”Àzmw»³³c8:2ä
À¦ QŸÈİ3­Æïw´E?› KÅ¸ú¦;Ğf_À"º­œ#¿°)|+FI€«¿	ÉÂÜ¿ø¿w‘sŞé­NV8çªíëÄèà\ñí=Dk§²}†™­õñ%:ı¡æÒ$™{}Iëª¤Gû…8®Ä»®èÉ©‰2á	«éÛ	ıvWnÙ ¾¶ĞÊéƒOê˜*ÿŒ]~Icd¿ãaÅn
_QU³õ@ÏJÅ	}ËÔ›öÓÅÚ³½›¤irS¦¸í~Ê¹‚ö>Æ]«Hâd mchdq;ÕÜ%9:8á|<Ğâë¡Û_Hšå4M„R
7ì&AÆl‚)Ä'®¸EÂ h©Œh
gc8%Â9¢–Ğ^Ğ€ÙvÉÀŒ˜-Fï:· H/à'V¦¢É£a^!dipŞ§Ü?€µô&Š’©z$»i’›^sK3—…g$
›Ökù2æûSš³šÊFıf-
^'ûa±d{U*Ú·²q&T ¹WAÜóÜÀqŸ-kBXE%òû02-4 oş.Œ™yÛ|‡”Ğ¤øW'ç;A^ğhÊò×ƒZR4iÒA<LÖ[gU½>3K&.ÄÁœÉD"ğnì2úzÌ“=€@K$úJµÊú™ô÷LŠÃ¿…ş«¡¡hæC´/¹†Ü”úÅã¶5c~Aë.Åpou ô‡¶ğ†>X†ş3Ã§ÛŞHå3´ş`©£ş²¾¤–…6•“Ny8ãi6p18µœf ƒ·'°=ëÁD9hR‡9MÒ9'pqv*ªp¦Ræç'ÙIÜÄm|o¦Ûøâ0Z<ØëÜbŒ±‘ü©ô¥¨Ah.d_yU{#ÁoÁ.İLN s‰”Ù¢ùÂz.nTÊ!ıAhòh°¡zäÃ”)P–\’)è!PØ/Nû*{T’iğc)¤E1Ü¯Òí¸ åraà"ÁkUŒ‚¾Ca_˜o•ny[1iÌšø‰ö¼ğÖÒ»|è°ğñ+‚}>®ßmD£_±cúÂ·æëjW­Ä{Ï¸øºí„ô+ØİİzC‰bÑ1”N¸N/&Qq;U4ªŸrQ¿“ƒañwQk[2¶ÛCšÍş	&‚zêÖA—9–r„Â/†ÿŞV¥Ï aŞAº*$OÆ·S6Ù­ S ™’¯2ª”qR^²ßŒ ^ë7Yù~ $,nN&ó?–‘S0¨ÍiûÌré1åé»°WU	îñdqlR¯Ğnê_È4l>ëH<¾'(
gÜİ6ÂÅNìnÕ½ıÏÙ¿İë\&”šÚä|%±şË^¼´š$0ê³¤BoÚÔmòõüœtIã… 
^Œò1KWuµ,4»ªš_¯`¾¢¬ğpxùî’åz$…TpvkkšÒ	‡±r¯VE¶s¶±2‚y6«Dñëõ«UQç1*õésWhİj¬yç¸l-OÛ9:%-ZÌÖ°qÑ.–[Íü]¦|•X?±§}«úÖ‰%S~¬°L¼«lìÏóz$Ì6 òrÅí‰$_kÔ5!W0ÿš“DnÛÔÆ_1ájïSò¾P¡>ûŞatlOÖìYß5ÄùğÚGÒC1›G°dµÕé(Ô‘YxÚIM¾ÕP¹>.9ãGëˆBjû¥ÒIÓYX”…ìÃá‘ìU(U¾åèÃAÓVô²‰eêÍâ”ro™kF÷_®!¸ıÀ¾‰´Êsü±éî¡j(¹Ö¾™GIkèA8~Ø{õ=¢¹îHeMG€ƒbrC›B
SÍ¨æTæ·B÷n”`şåhÿ§´~¿AA‰)œNûX›º;+«¤ã2=]O/à6$%ÉMÒU^h5hy9kŸ:ÂÚOzö"y[–’¿A5´>W;arÌ¬j/ÕhåC»œ8²øU’.XÔÆ¿1‡ÑâB…pÛÑ ™‡á³MdÛèW‹hyQjÙP´ÈÊèüI¶ŸàV¦P:ä£6ihÜŞI|Tr	‡Îs¡+×Ly]àÕÍˆ uÕcœş Á”ÆR%DÁ›òVÍ­ò¨D’J•‰€&ƒ°‘=eıEtU˜ó—é[ÌÉa±¦—ùƒ¾ïú0^sZ¦èÔ@<vi¢}Ç5L1|R.RÛ¼ÀÑ6‡çÀ NÀ"ÖYşÿJß`sº“ß,¯°ø‡ŒFÚû÷‹ Æ?8Ìnqi™ë‚×q8å	°?59·İ††qRn¿ŠHéqfØhu$œ@TçvŞZ‘£4W•ïgvœºs+«VÔÕ\‹yNÍŸªÕ_Çİ´êÂ+KÚ¤°Î+Ü‰|¤‹+;R²Ù&çÇ­ñúêúÆPâ'‘êšyµ${Ò(.ë5ûúô¤//ØbğÃOğ=¼æU„&^®'h}']+æÂm›¼h*—-K/%ñ(šR»Ó,&:doWKGV%‰Z~{œ÷z³ìq¸[)±öÒ‰|HÖñèXJU
bf*«¡pŒöº$ıënŸ´ÛæåRÚr¤›“‰ßyÄõ¦_î¯¬Ÿ×ËÓ3¤ECn´ B1Ø\¯ÃC²®¾åf;°¦;>?0¬y¦’ô°¢Dpø"Ã+$ê¤Ã»…Í¤Š½ü²¶t²¼ä¬u6 34D¨ê¦œƒV‰sí  ©¬kØšÜŞß#FøÂ2£Y1P¢ƒ™%Ç£Y0¼µ³pşÖEoA•=Cå2
A]şÛC ºl`ÿJ¸0RÌÒöæ,¸êmœŸÂÔ›íà÷‘®Õ˜¯Fr§~\‹mÚLÿ·´×ÀLG.§`ë?É<Ô˜©Jiy ˜Qğ[$PQ‹úï‘Ÿ@P¥ª„®à€õ|ÊßÀ[I™_XllPUÈ=)B Vš¹iP„ŸWW¡ò°ûË7ú“M`06í0)Ö`1r]kvÂúKˆÒ©ÂÆQ@ÆÊˆö+`âMdÑ¶ğ%nÄe¼X¹4ÿœa• µ»rDıa“Ûµí–ß }[¢gf<V,{‡´Fõm–RY*¥d}¸<õœ>œ¤ù¸j¥š¿ŠïFö´Ó
•dúïûX¿¸Àª¶FéšKğç/—Í¼ğ¯eIã»¬ÎÁ]UÚI‘²L_Ñi×Âw¬X"™Ä›Õ™›án±Ñ5T¬y°MĞÍÇÈ3¾®,¹*4³4[mäªs,Ê-a˜„ù~…:)îøX$*“LŠ²y.í˜ÆPœÈ=çøp¾ÁÉŒFÍ—ïˆÂíĞú´Otå·=ıô¢}lêØû5QÖtçßÀ}O÷€P¸Ô}ªP""$Sç4RöØÁPÄ°ò"\Í‘zâóÚ­KœË†+/*¼i¦ÜØ5—ÿ
¢I„Li©PÇÀT$¢¹t)jZGU—FäÇVïÚv¤³E¿gÙm™+B%¢R)­T=NNp¬V¿%°à—¬ÿÀ§® .†Y	 bã•`X—Ì“ÿÄ/2ZÒ6ç<i<yùÂ²K…ÏíH“¾›ó¾¿ö-çÓªÇÁpx1gª+e³oÒy~ì\ Û¦Ç?of»YYBÌë=…	;gş’ŸòçgFˆ„;÷t½Oñ@øF<!7ÒÔØÀ¨ş ­p×K¦|”9(ÕÙXã°I‰_Æ„$Àf#6İô‚jtÍÚ{qàÎùoCX"×Ãovú,ÍĞ¥!¼ù .:¯˜-”t™òñ€Ê1´¥KĞ'‰BûáÅ»áR>qUYşE«î®ç±ğÜ‰ ÑQo3£ZúØéx0İˆáòö/:ŞRËÜƒıIynÎÅ,™¬ÒÀ:Ã‚8»ç"j­ıƒôy[9îÁ‘‹€p/rµä·F„[ÙT¥ª¶Ajxà›İ–äà¼Á¹‚gkÉºOS)`ópå€§ŠdøgºùFYŒ÷Ì¦ì9­x»ºA*ñ…OO	È~<†^‹ÉJ“m‡2–æ›ˆW2…˜½Nã‰4¡Ó¼XH	tl½“ÊCs0ç¤s>³½l8IhƒîŒ¥hîƒ·0òwüóí½¡óZ‡t¡„Œ„êl*hÚ°Ä+óÌÅ#oĞÒ×=&J­ƒõäVl,Êÿ‚Ñ+‚%–@1B¶Ä°ÿ èş“,/#³ïûF½ûùÑ‡ÏÿX>F«Yª„+4ğtqÅ¿b}Á ½8(Ït¹]ŸÑ¨°€égB&ÿ	/üÚè:hhDD2NÏQî\biZxå‚İ¡OmHÛ¦îi7û|à[;1óCãW —,¿éÆO´T#F‹Ş`Y0Lí¿¿Hâ‰²’ÿ*éöé$pÖUjÚ7Éˆ,%UÕ“»bŒ÷xiİ=Fôüxöœ5ß:ÅE„ÇŠFÔì”Ã8†Eti%r&Ïé_	Õ£ë­³hu„,:ÿ<$XA!^yèqØÙcÑ–|ú0Úpm”Íûr¨Ly‹ÎßãØGU)ÎÊrÁµõİÂ\P“g 
¤à¨6}¡‘qÙ/Ç'tŒÌ$=Œi[%šÎÄVŸ„¾÷ÁŞ£)®ÇA³Ãtª=¬N¢¼ `§D£BŸy—,À¹|+ˆOßì% $HRtÙº³W½ w&è:'UvòŞqa]şE ‘Ó?ç÷}ÕUäÏıŸÅ…Q•EˆŒT¡]Ú 1˜¤a= Êg¹¨Õº³"û¼\vÇËuä+œ.Œ€© Ş‹‘øUlü»è–¶ašV]ÿq²ÜÇåíHx&ï·oıA¾ªPŞÈz÷U×*.%‹½x^®Ğ¤²¥YÜáäÙò™†z¶%˜îÚT‘ì°C‰l—,‘ôBáìœûf4j¢ä©± Bó#r6å/i-]!7ƒİS Şõ^@×2Ñı¼]ø€	IWR~ñH³D¾ Ã_È‰K å°ĞRwfY’şÄ¼ 
RÍşıYĞ}$F¥öˆÜüşFĞKİHF#8ô«rnkÁe`¶R‹Nø"ö);½”·dHm•kÿÔ­Üºf]^½aÇ]néØÁmñŠU’n(‰rğ7’¢êhœECiQ»šÜ±:X¢—Ï¾bä¸"—YAÓyÈv,‚Ø1'N5ŞC6döOŒÿœu~»A‚f^òØ+*;0ã·÷±‡?¡œÔ`v’ƒ§ş´‚Ï‰rÒü¡à£VngûótTŸë§AÂm*ïé§­¹~£Ó`â(ÅÉ³Ô¥¡•ˆ>Bg·ÒpÄ>VÿÌ²üÇñNğIos ášÙá¹Æè¦% ø.Á—ı
9úøıäÓh´i05«ËJlªVÈLía+­
üê6‚C›pÍ"¢™õÛÅ8³h$„C!4Ìwjëò]ÏarOq­»»¿İ@_Y¨–
U“UEˆ]xuX¾O[º}Y›İ\[Wk§Z±}&'J0uY¥ª@¡®àaı¨ÅX" Š"¨c
‘,W$6å[f˜MQ¾2~°¶üËçl8Ë;wˆ©Z¾ÚªÌÉ‰Ja|¦eŞSCe\*Ü‘
Äæ¹ø®ºÓ–Ÿ›ş ­3íó„Eáıµñkˆ§Å*¬ã¾åµÎ±Ã¶{\Şb™YÃÖ>í[Zˆí!–§"'
Ëf`"©¼Æ‚1·—G¬Å5è^nòJX§WJO¨Nâ ê¸¦m ÷}GlhÚË@á¿2ÖŠe\ÜuÿùyÜ¢Ÿè×ÙÔ ­MÅf.imwz÷cª…õ•‹ğh Ìı¦WXë±»¾µø¯|¦X”js¸)CŒñÌOt¬o#ï5¢®JqùHö	Ğùå¾_•ôˆ --|ˆRñEFˆÂP{(C1·¨ò^‹Ö)—ş#;ºÛ‹c…¥õ×»½rŒWƒ5­mãd£Âi3.IWFHjEÎºÕšÁß.fï£Û:RR_Rad#ub¦ğ$‡NNŸHG,T¤ÇàiÁÎîôu…	¼ÈÖ _Lpy'ù‡`_º›¬á[ö6Ú§ˆRMJğ9ÁDGÛèËC0ÅÕÏ€„Ù‹¢²w}j=)>>à&pF¨iaŸ$”ıØ;÷ [àív
FxA—èÿ0*kZ*³f#6Ä•oC
Ç#UëTåÖĞ@"¾z'xT~GŸÀáÉcLÆ!k˜îmLŞá¨o„&‹ntC””„¾ü-¤¤šáÒcÚCõ‘d}Ô8˜®RJ¹·FJ\”óÜAÊASæşDi‹ã„.göÁ¸w³_õ/+›†—‡‡$ûkagöæ3]KÈ 0iÒ›N+GçwùûVe‚11UÇ’i×¼g•ã9·N&tQÓÅOÄüw›nüp¶iËş¿‘¼ßYÅ¢—\cƒí¹8IõÓK½z£˜¦o†=Vb’±2&t)é6DÙK‰¦·4dÒPûÿz@ÀkwàWáÀ™Ÿ¡'
`¼,~+¡®XHG½üïy¸ùsc¨–½³¢a ï·¬?wÆ~ÛœºøÓ­M´§6Ö»ş¶%5³±ğ¿s£åÊ$¿õŞ€—Ëux?RË~j¼óÖÍÂ&Ú½ÿ“@5îR¡*;õ¥`E-[µ«_T'é¤±¼z.Œ£¨È= RvƒÍÿn~ùDnÛíg³{·¼ —r¤0y“rË÷
6|øÎãÒ\0?ÅÀŒÈ]5Ï¨âƒjĞ›&qT 9•rs«A¾…wé±Ó%4db÷èQ¯5­\Õòe@W» àË&NR„$Õ1òOÇõëœ¤mE>~”¹´‘SÀ[“¨ÌP²,Óé8øñG|å/™—ÂuÔòÃ†šxmßË7i¨²ËÕ™tÛ"7ı{’åósGı¾üŠjBÜ#a*AmÛ|j1Ò­‡[&&ĞpÑGfvİí$.©{=õÅ–pİ¿ôg¸,Ç<õÆ”OÄ£·(2Ä‹¨´ââªêM˜­Å¢(:¯A8˜*uº[v«*…KæïÂşwZéöNá"h—Æ‰¶Íæ–ó!_(~dÒ^Oa/l×ğœ\zFÃÑÉCXl]È
€İ€ÍÙKUÄœÈ¥Ş_ğ_†ñ	]‡—OV~Â[Ù4ìµQúeÿÖcĞğ&H<Hz{Â¾ä’IVµ¸/P|s'dH7çI Æ"ŞYvEñmŸ;"8Ærf…Kj[ó/R&ÀîŞó¦nüækË¤¼ÅinSşŞ¿f3š‹jÁ§¾•Uä+ÅÇ€WÈ/¥m/ù édy.Ïå-x©Í‹¸‡¬]0ïn8/çÌ†G~Rñ¼Ç©4Ùä
šVKPŸPæ]¬×öö×I;?hØ*¾ù0¥ËÑ:~?là0>eja/¯(á%‹Î(îî/sœæª ÏPL€Rà‰UeÕáhuyù*Év_ú%xÓiGƒ&‚¨«!#¯·vÇ¢ğJx\ı:2†_"H];Ğâ”=<é®Jï¢‘%mÖ×³£„+Ù ë.“Brz-t†µ3²ĞCy ¨›E}T–Ô5R}Ê|3£yèMŞÛ©PÔso İNíÁiXÌO,0’3í¿háıİªÿìx*¾rô«ë¯‹áÚƒbv«Ñ¤ªZ‘R¢›ŞPÍÙpsjáÛNgä½j´îêCèîÍb“›HÀ®òÿQÇûMİÅ6tô!a€ú	ö|$#_?½0ì-`YM~jÜ¶º	Qaš™6gU"$ßrå @¬¾‚±iœ/@ÁğË«—k%´ª=è-ö” ¬ °mµpğ\†0ÚÉiCÂ²ş©|bÄ 2hLËèmh]òte^˜•¸rş¶‘&xÓ&Uyuo;«šã5²©5 Ñûè,©Üzb°“À u¼Êò¬Í)·qĞÊÕ<ÒîŒ;4UãŠ„Uû5ÍÆ‡†ğ’ÅL›À(ÒLØ-o/s¨ôpP„8
‰p…I\\¼Ìğa¹Ğ|Ä9!§¸–whpõïÏ»r÷kèLWAú@„½Îb÷îàOøs™-ˆ¾îñx„Ñ¥P?b—ìê[t]3(Ç{.gÈnœµ·ÈÍM©»P‡Ï“VØ¤hT ^ğ¬6Ë¤‘ÑÔ‘”-Õzæ?°Öí×Û/O`^Z´4ôhµbâ&Ø·Á1?ê°,z£ÌøÂå'¹wKP–ÊYûîõÌlX×}F"¢ØŒÅ¦š¥$]m±œSI"Ÿ,Íš°?ÙNşÏñq>ˆ¶‘(s.ÅìçoŞ¡ª#hèñÅ;|@Dñ$Â™dE^@%[+¥Şp|1_uYÓI¾œVºÿğ©bïjLîvsŞıß–ù%/ÚŒ@Ëó©ğèßáÒ €PŠÙfe-z™"x#×RŒæ.Ñb`–óŸ#–Ş¶ókßñWŞ­!ş—ltïŠµC£¶´**Î|‰ˆµí*=yèveõFl 3ƒ“&.ÎèŒ–Äßg†AM¸­¯—„¤°íÀØ<{d¦¹KüçÃh½˜w®ÑÙ¾Ù1âx|$/LRÍÒÉÁä)ã­ğ	É	i9túAó1ÓjÖz¿"Ï<\*¨X
±ÖO¤~“D€º§™ü²¡5	ı‹¹¹S¨â”è<ÚöR÷uO¸j€-a½Iÿ%aõj_ïèÁ:fR–fìŠİ,tò,l÷=Í–Jw!¹”W³p_ª46î‹)6”€f+êåÃæÈ³
 ØŠÿVË{eêïo”á]S[n<l:ßD¦œÆ«cDËîÑuÒ)ÿŞÄÊ^ÔË8¯u»`‚ï=ıÊ£÷AŒê ß(ø'¡©¨ÿø“R^úW§G¾v¬ õS’8À9 İİÏá~mDH‡OCÃ5ÿ Ïœ¿½=×W1ËíÁÛ•²µC8e3PÉ4yÎÍW—¹Jäş@õ!+¾ôö;Bm 6ğ*¤€‹#§€äJÑ'¿ûâŒ#ÍoK'ëœnmC–R½†iF,-š¬S N‡€gşÒÄš79)-¦ =á[¯Ä©¾iıÓ¦L¸P\¨0+D]:ä4^½,vŞ¤`¤@·&ÅPãÎwË4´ù1‡À,¤û¸Ú+¤¿­ùPĞjÌ“Q'ğW·ß´(EHùyÂ˜ÒKf­=¾ô3L5*™–TNq1Vq‡- HĞÚzÇ»²£D+Æ¶Ê¨’;Wó›TM;S÷s{«À$RÌî ‰\.x²`$
:èæ³ü¿»×„-¶–>’6& {Íÿ‡çj…—ªè,XÀñ. Ø…Ô ª]RŸ]â™½NŸ‹?@à_hMB	[­/E¾€ Ûsğ«CIUÁ½jP/‘ålí“¾çH±ÌêøĞ¥Á;§${œbáê»áş9HebpS¿@”å—{—Ş˜ Ğ ÙÆ\ã\
ËBæœÀ/uû :ùıL¼£rÚÖ¢g§~
ZrÍålCaì@:-EW\'£#“ÒÜ1Kò.§yŸ¾4’LR5òpï İó»üî×¬>í#"ßÔøî†ZÂWØ©ÅJN¹fãfA06Êåâ´
Õ-›;js« ×<J¾7áÛ1/~ææá»åéô
Ü«MÑs'¢å3Ù_ÓËô¶k90¢-GğNË©-×&óU]ø™Éo²`J‹í‡P&öX $v­Y´¬“óÍ¬±ĞF¹&ÜB^ä÷?kø¾¾¯'`Ÿ_€æÆ§‡upf.±ÚuOzb«_dZp=p¿h: ¡GÍ/à”Tíéü<9´ ÷%2ññ%ğÌçvÕÄ0ótvĞë ï’VõãçPSÅqQo™BZµx¦Õ^WG*Qôè?™=Øâ|XtèÇH\İ\îeœà)R¤İ"ŠÂóe…mñ•÷¢Œ\äığ÷É&QCu5.'íš õ³/MRÇsØèMƒÊ”÷’¥—HVJ.‚²úºµ$«›O–±z:¿áYt!]&A¿şT,,»…İšß÷áÄ®ßæò¡\‡òÜÇ9TA½¾-ã[Ã(ÔÕÿ€úßÜĞmBÓÿ¨« #‰lÚtîĞæ^ÖÇU=àë6sîL	šıR²Ø¯8†K×İ+¸“ÿÇäJó·=1İşÌ¶à]&µšl¢5°ó%Ï8y+èâ‡˜Ú„` ŸH1E·	ëè*‹æ_Ì'zÎ|–g-û©Wj\•5
C'¸iJh2t+Ãá?¨ğ”¨4¥|M¤%_VÜœ›åDËè“¬LÌßw8®­91êz"#m~¸…_ -
*Ğ¡¤F3˜õşÉP),Ø!a¦
·êdï	±-ÈkÏ]_Œ{Éì¥u>ÓğP[„Ç
°;¨{ø»ùR9$öÑkZĞê¸çqd7û}¨"ùİÿ¼ÎL€ò“ÈòU9/ßÉS,)-Õ:•q\Ä?¹ûD7&:	åT‰†g.V7¨:%Ì?¸M½…=ê÷BÕ€“àòİ5Ü˜¿__Wˆ„'ÑºíXeÅÄ	Æá„%g×Ë0¨ºVRS<ÕKêÄOi…Xæ‘¿K Eşƒ5ïïğ\b÷"T°ÑcxC}+(²é<Íı¢Æ›¯™~úë%>0øØËã÷ô¬T=qçØdsgtUékè¥ù‰ÿÊúí¨úcXÎVø¦øÉÇ{å–Bs«%ñu- ækiêöWÎy&¥¯	–!ºEÇkixQÃ8tG×8OëĞ†”%Ø @“º[3ãô |-¥©ìS£Ål¼sÁ6:kÄvÆËzoÎO¨Iv¹Í¯á‡ßˆİ´õwãB£LJÏJ#Íª¶½hQäuûŠİağ„¶4ˆ’AÄÁäfáê¦Euôåı¯âV2CqÑ~ÅèâÔ9ç^¦uî›åƒïqÚaR©£vT<ù&,•áëò{¶ƒjêàRsë®\/Êv*Ì8&²¬è3¬Î!&YI1é?`°6¢À>ŞeèŠRÖDBñËb‹°ÙR|r+ô›rÑ÷é±¯ìnVØ6VGVYùvşşÂ›Í1­ºd7u}^¢6©×¾¡»ŸW!~i„E‚æ*§ÿ\JC’äXr=‘};Ì;lÍö)!<ğEz@…_
ÖGëuWµ8şÅ£h$8|?@±·¾uè_‹âk¯–Œ@±}oT…—çwŸK3F‹Kkl#5¨|¾‚€¹,$·;îÀé|½²¤Òiûq3?ı¾_³†Q˜by;óú _wn³?Ğ«[—üõ³ax½{Ík8|uñ{Û2ÍÖ‘ñË4f™Ld\Òäo½üKî)ˆğ^CG5¤u‡Ó(G™IÁ‹	õí9CtÍçÁÜu¨Àåv×ìa~è®î¿ğWzY>·ÜFJT¢ÛıĞ×‰2ÉI–Hà^ŠÆ¸ñøˆÃâµvRíÁ{>¥2ce1±nÛNd	¹kT2Íh™w?+¤¾*Ií|Íú±‘ädaAäŞh1££|ªíeD©4aòlz‘Î"|5ã%òø·Úßz&{3Ç Ø‚‚ %Ük;æcòö*üáÅ K;q_Åf¬¾9ˆ;#Qy•Èøj Äá·ÈğÁÈ‚ÜòƒIÜîÅ{Ä#ŒÀx¦µM3ô›•9 S`£0¹ìpÃOJMQ…™½-€ºdúÏá4µç‹ÃåˆXaÎŒ`VŠ2ğ»Dö)ÃËxâÈ®“íŞ™Î÷øø¡rØâÏ¾ïû‘›	ó®§-\Vä>^æ…9ìáÌc¼n¤³ò	ˆ’ë†W#ÂSœÿåYoÎ‡
ºê=ü¨ÅÀ†dç€H9
1Ø?Ñ:ÔöZ	x])D¦¹GF¤Êóøûï]]ñ†*^Å_ÓBÜ¦-ó?Ÿ6iÎµÍÎĞ–¿7p–ÒBZ±ØÙ¾
(Õdã)+€·ÄâŠ26˜d}Ë¶…‰JCûfjÖø·­¡_"‡z³ïÎÿÔf’˜~*Ô¸×\ìô¡è«{Í@ôS”*V±b¶“Õ»l¥šáî½ji6DN‘‹ï„"7l»Ÿ¦	z<¨ÉÅ¨Ú#?ƒ$rntV¦Ğ*¨d¨œòL•4ì+ˆ	ou‘Ğ^¸ĞÊ×ŸÀ¤Ãéh°áP;)¯—ƒN»VÚïà¼Œ¯á«.C2…ÇæWZèq¢õ:ÙfˆlR·êÖŸ¼ş¥§ç ìJ¥µÑàR‚rk‡ò r3N-õDV!„-ïÈCš7ª—‡Hÿ}£ âj¨Jô$Oş k˜¾€îÜwÊxùûÉÓzÙç-#îöÁ—!y|@^ÿ—çÇ¥`ï@#¶ob=Øîf0'Ç]a1ePƒ„³V"ÔÊçš<Xİ;’áápE]¤æ~ÿSsRÂôZ`RÁå{A8îå±>0Ø„ë‹½ûû|ğ±Õ©•&,øsÕ«ìüƒ±ƒıˆÂœ=Beà‹¨"¯zí"”[¬ K¦jnd­	—w¬9A¶]—í%÷™!ãkFÁí0±¨ÜùÃß”xµÂm·(lIÄCÚ-õõ7ÛkÈ˜Ã{Ü0n'iÁA¨ñesÚúE# zŒ;KâÙ“öM<t«eSğ^½2 s+â bAØL¹”E*EhR™°w—Õ°*Ò€€~±%Ü9È2÷ÚÆ'•æ”˜}ßà}ˆ‘Ôà½€%÷‘\Æ…Áíˆdqú¸Ğ¬ìÿ<¤yù5&Ô¯ÖeG Eƒñòz ÊdaQCâNZ)­(ÜÅĞúÚ¿Ù¢Úç.ÂuS¬lvÊ¶“;ü2£P–yD·luC½òçĞÇÂö¤Bšz´ŞJä;3‘¡{å
ğÆ4Êñ_1Ç²F(Šün2å¯…y~²Á}§}„ÙÎ²Ï¶ğQWœS O…p±éwò³y`%ŠÁá-ÅòmplÕUßHçĞÜ–zd^~Dâù­ãÄÔñwpà ¾Gj|ŞÄ3Á5›t —›G¤=ŸÏ)zåÇğÀ;¦mÄœGa™5ñü¬BN,G‰ØIë–#İøŞ¼sy0±‚n×Ş

óç1z`k[ŒW¬p‡0¹PäÆÔ¾zmö‚&LUùãZÿ°çsítbvø,œ% `œw¸İ†áÇ.œà>à«ZZEõ9Z’ÔßL‰CÌycì!Ô^}w$ÃeÈ¨«ØhßG–ÁoM±ÁæiÕ¯3õ%Ñ|ÏCÈÒ1²'èà…%›]R¶±»JKÑé¤ZFå­ÎÑxî9g98Åg‚J"Õh+ç2ğ˜÷fÄƒ“(¤1¢Ñ vÄÓ©ëÃ(3!>ÇIÄ¿”’™Œ²jMÈFkU¾W6”FÜ@›ùu·‰†{btVLj÷IğÏÍÓç’Âpï/ª( é¹51<‡4Î®¾ÅÉ™.;Á•š}O_]òV€Erw¿‰.Ãuô!7VT›òád7†È%¢z¾	wâ?^Knu"eŸIpsˆÖP\t+ÍD[Š¤Ğœè5úFyzèğ¼áˆŠÈ#ç<J•¶%ÃfséÆ"4İe¬¦‡¹ò7pÖS3¸{ßï5zİîÍRÔPUVj*ŞĞòÖïâwJ0Xè1XTZõvß·7Pk¶)³ê”ÔÍcÚ-˜"Ë
MãoùÌ´·;Ğöêó”àõgš3‹_Ñ£[Ü^]Ğ%+y®ëI"ó~1£àó4U<0GYâIßOÇª%’êŒË¤à3½5YÔƒi%¶ÔÇÛ¿hñŒrïßbXñ½ºíŒÁ)^SÏ,şAã4¼0b}q¯Td³èYöFM"ñf¸>ãÄáƒ¢|Qÿ#P­d—é€}âº>í‚Ÿ÷¢æ‚
ñ¦9­Ä`Ljöp^ƒ8¾ K¸	“• ¹„”râ<ˆ:	•Öö÷äOA#ù°2ˆš°±§[Û¾[%ÅÆ`‡€]í÷Œ%Ågm”±yŒ¹-eÂOÊŒŒÇlC±Zb¿ky_bİõªV+/ì/ì¨CDtÚÂå0YDİ7ëSG­²[ —ÿPZrÛqK„¼Ñ	Xƒ%ˆgÈ²@¶ÿ¬øÜlı8ï/¸Úyµ>Í‡ö6ö,2_Œ«å`*ÊÿFû|ÎÌ)§âº„×fİÄa:VŞêz!À@RJöÑx‹Ãìıƒ<	7êB`,¡\hÒu˜éïálšñÅ»’k@I=uJÎŞ`tYØmHë£¼M&OÆ|(™&ÃcuÍ:Ğê…=
•‚”|)¨m!bÛäåYø’µê/µ_Ç¹q|&ö8'‡ÉºCŠYò–´ØªQá vO»H!©÷U bB^xŒ‰´«MkÜ{•˜	Q”‘¤×‚)ß£\¯M@ğf–Ïñ-9q£ƒ¾æ®/Ox 3Ú±¿ÄyŒc)~´ºo;Í­õõó„Ûd‹Œ>mh¡+-¯¡UrÀ&»NC Ä‚'İƒ½£Ãİš‚)×g5-—º!0ÔÇˆòˆ³«<[ œÓu-V¡2MkmŠ`ÄÔg´³¤šÑJò7Ä“²79ÂDfR:ëùŸÅ_@h÷Qÿ|Ì(q»×w“D[¬r2¼NX×å4KV0k®ğ›êŞÁS7.õóˆ\¨™‹ö‘õDg	'KBÏÉ-ÈÏ€•aÜ–ö§Ÿ
‹İş•SÀ,ğjÍõ·[ÿ	“Înü³ïQô#»Ö}cüD½PåI¹Âh´R#À,ù“Tğªú	"‚	óËrØ§§%‚"/
—×Md<6&ÿ)õ½qéq$Ìj=&‘ï¢IŒ†İ(–290#Î	p¼cg«„ 'Â]jC}eî¶kJıçæSÕ€Y©fğ²áÃ)?Œ–ßâÒÊ5!É"r•n+$Ş¦Ÿ„í¨z"R9mR‘ßuE«=OH6|q6t&ê¨SáâEÔBWÅuX£|ù½H S­Ù²¡jó£1ù´Ÿ*”–5ŠN³Şåü^çµjÂf˜tÜîLsï~œBg*F÷ÿ9Ôs¼qW–˜+zÃPYa`Ü}‹ßæœPôÍ•½¿lû±ùq0îKŸ1B\ìÛ#:È\)Ÿxå¶{ ¼)èQ|Ó$*j¦j«ˆõâŠTw½céşÕ¹j†µfj£mèP¯Ë&×ĞÿVt”cµ7{Ÿ†2ì&ÆÀØ…!ÑÁgó&j[kÆir$7=XÊ2şşPceÕáú6<Ôiuk¢¢±…•L¥¬‹{®ğ(zIT˜>-Ù/rÅÆGY}I08ÿ‹oN*XácÇ¡/TÁ<ÕRÛ¦OkĞÖ¢İÈ®ä€ÔsØ†?©—©Qµaö¨‹A¬¦FTBæ—Öâæ±×C¡µV:jù<¸’•´
r	Ş˜DV+FÇ÷
_ ) ›ö³ËCº©ëºÿB”`ÕôY8&^Â0nñ6JõÂ—jš»ÛpògÕİ®ô¯/™iµÓ%ë¢8˜²e9/åòïÎğ»‹¡£=0÷œ3Wc÷hpß»ÁøŸ˜éäüéqüIî-Zó¡tƒË( 3ôçkôlËõŒ@2$ÎüS	úI˜š£}[B`@rÖ«:M‹ÖYbÃfv3•gÜñä!ÚÌÇX¹ğ™¡;ávÆZtY*Újîø´ÅT|rOEQ¯5Î¼: Ì‚1FtíÒksÚ®â<=P·ªög:ô&Åõ>¤>5$Ÿ—z3?´24KY˜Æ ìÚ÷ ·N‰{‘j¤áÎ˜÷oûJÚq¡b¸µ^/K¦z¹IÁBø©öºHû$qÄÛjTI•º¸Ë·„8&:švîêS»ØÔ|m‚‰°0"Îó+"ÉÅ“ÌÀæ³™ÌOç>|ÈJb¥‘ì%ö°kàI.›¢s¹1a¸Ä†êëJË´ş^œÚ„º0Ù„à~áU®°R%®©5Ç?SX•l Ãğ0¹B«´«×lOøÿ‚*OBŞ!Ú-“xIƒA.–u=8\İÿL§0VSŸTÒ1„|î=(%'Ì+'oÔæÙ†ˆè-"¶‹×f[.åò_ŒÈË™?[é/õ4Ö©ØÒçÏÓI²ŸN»EëBĞÍ¬gdÇ=¥cÌ&xî`7'²½\“àJ$¾|ò³å‚…Ø*Í ˆœ_)8xg‡©š@¾'’ßH ¥LAÜ/»—¯„Aÿ"¸ÒLH]ĞÜ?Œj>
µF@ÿ$Ôñ`ò6¾“/ÚM€#>[Mà‰ì|ÃË—Âªà0Ï¾5¦?°†Š® ñR68˜Û7»û!Ì–5yó 
Óµ#„´×ê#òÙˆ˜–c‡Sm<O`mÏ-¥~$–Û7Á¼‰©VmTî0¢€<à„M³ äú9¨¹LTí˜PÖ–/}MÚ-®*HÊDF­Ø|?¸ÓWewÁíªœ?¿`#9(øÇN´Ğ?2m¼Ó0İ3Ë8BKş±ö­½÷‘JCz\AõúZ-,ŞÃã,^—ûY`7No¦x2ÛÒ$ÆÓ# ›>«µ…47CÖ—¤™°¿£Ä¹ˆúXéNu/şå>xä&%¸xFÜË2ËúÉªèëœÂOloÑ¸GÉİÓ]ü´[Üw¾AƒÓşP56Æ{§ÿ!jT8…ò ÒXÔ“‹NcAb—–nH“?>‡ùš‘¯ÚBÍƒíşhÇFƒq—bôl’Òù|ùQx…vu¦ãí~ÄÄæî à¢'ï†¡Àƒ”9`iåy™©›>F×†ïšÄ\z…6¸ÚæÑ?§ŸûêsºÑFjéV1xxÌ”‹ ‡_6Áõ‘‰ÜÖÛtÂI(¼!S»%ğ¾qU-e& wSáJ[£xgCÕ`U°éÑä'¥ ˆ¾¢ëo hªá8”ğ€bu,Ûqò™:†Wò%OµÕ¼Q¦Q	Ê='¤ç„;>\’bØ§¦øİßq+µÌ¿¤@9ş¸ŞO]û§Áhg1
ŞŒ—y›«îŒP=[şmñ³IÊxGªœG½—«`ÑH’J!¶ÿÚWvĞ0ğÉÄôì˜7â—Ä‘ö™é‘.·òÌãw Vûï©])·u~çhÊL>âÃ.yÊn¨7ñ7šÆV›¯Nt£	E´
íÖäExêª¶pÒEd‡Vm[ÜÿIŠ=4æ«uÀû©É8—ºÅ)†8=lÀM'ø¡ËñGÖø@¨]õà°ëF”ü¥Jÿ–“fÚµ¬>ÖUrèát€C;VPd¨-E­'¥n».ŸBØç2ÙĞıaı!€ı%»wùÁÆñxáJÄù²SÉÎ:2¥&¹2pK;Ö˜‡Ä4ËÌÄ—µ©õŒøhÊcã`š^“0<¤ıÂ‚İ^³¨­MÂF°”VŒ+FV¸ÖuƒÎ°<ó–øÆğ†ç'_©‰6ák•cROIªÅ³š QY²ğ¡àÆ]Q#6ÀV&¦0°­İ`ÆğašÙújÂÜjˆ°¼À ØdByÂ’C>¤é+xcßÒÈ¢?Nïe`~ĞîÚ-PĞåJÍI ò!XÃÁjŸ)Á
ru’®aèúıêâ`Ô §Ğ[,/<²Ûqş\n£>JØ$}Õ˜^kC™µ„İˆÉùŒ¨ÈÑ‡rê¹­návÜ½Í’¨"<iÁÿUIFÜí¦™{^¶TşÄ] ÿ¶+ß”B2$48›Š3C:ØÏÄlá®xâ¨æ¼1pŠÖ‰½Éf rËˆ* sY89Bóe°èÃE<q_NÅô…¬«Ò½F©m8Ä/Ow>ŞŠáQs©ƒÔí.Ö'#à¶üU[o,<ˆWš˜Ë{+†÷`…RÈïÇÛ•ê}±og0H™%šÓ(÷¡£ƒ°»Ï:R¸`+øôœùcæ¿©t5õ›È)¹q8°{S^y×è›r)aDCÅÅùÑ?ã»¿™ê‹Å¨‚¾ş¡’íµ+ÖÍ.qˆ¿š¸„š/ºÇÔYl*%Î÷>i×eXò¥„}{ŞÍl«]Á‚ælÙon-VP3ú£¢sw†^¿`säº›Û×wÉ/™†“¤óø‹:ş-BH‚–¢ìÓûÜ¼ÀX÷ï—„õåê1t0[¡±
ÜÆ8Wß¤:yÖ‹ŸgYÙÆ…«‡,æÅäøb±nÑZà,á“nşÙJé9œ“—È™<4‚^oB‹qÕÒªÅ´·÷h5²áË²cÒüi5’(¦³œx8–›|Âh|7ve¶J[¼Nn£dPE›ş95 Sµ¦'/o›níıé…K“«Á~³×&%mƒ*QF
{”Ö†f!‹#šPHGOˆ)œx'>ƒ[gPÓí¬7LĞVÔ‡“æ	…Î’¢_×ÆWh`s?zñÛw®$@(_Û®Pi¡×›*îTN>o—D”v˜¥¦V„|u¡Æ0ßIÆÏªêÀ|Öß™Mšˆ¢;·,$rH]¼¶cgŒñÃ÷J¸Şı¤4m-(	r—ÚÆ,4z`²P»BvÃHŞë¶m•ÕÄ³…ÕN™Œ9ËÕ„|I|Uq	ãvíèáæ»8! ‚ü9mıíÓ—N!°#ƒ Ä»+-D¿87/‰”`'¡h¢XÃùZ€./‹Ò{á‰ÕLjj[•à8ñ¶ÖN‹£b2@L©ÉÍ«Ë·åEqïÆ13¸ŞNP´=U
¹‡->iÍ’ÖJ©Ãã•ÿyq´I µaºVÆéÌ¹ºYĞò€ì¡7‘L¸² U4Ûèä~åU“ÿ‘uÃmc½Áß9Y09y
^Io•÷Xã0\shLÎw«]O"mo¸cÛ¤½nşôf­á;Í™rØFzzŒ#±¨Àı«Y®_˜k±mÖÕùµ8)„ò¦Oí¨ñ{†QW,öˆ‘uÇ`
5äºkÀ#–<Ú8ÑƒZø¸U |“[Á.êÈNj¤…mMšçñA0‹’švÉOQ5¯.yÕ|“W,k0I†®(½ÓÏ”ƒ,À¯uÓ ğ'¨£CZCÂgoG.œØ‹ß+TC+ 2ßkƒÌt9RF3îçÃ¢/`¿EYaÚk\C¹Q¶;J´‰’0‘U•Œ^¥™³šÒvn7‹§
†[I™~ì^ú¡xÅø2§”Z»fŞKú>3®|Û		Åxù@õÑœô¼MÃÍäH® :p5‰…€¸hó ±Çï¿6†ëT¾, ú'BDlxû‹\CäRĞdÚ©>ƒJ‡ÜR­«¹u1vTB‰ıRJÄçæzhğ@m“Ø
—wijDÊƒÌ:Eg3L‚§«ùc¿¤¹½¢¬
¯Îå3.»®.~•Eº­¬yŠ±Ìùy÷¾4¿ˆœ_“¼¢Œ¬Çmòè9}X/ŞÓ%W¾­üÒ›œ*PlÙÕ{'ıSÁg©G£,ò¾ÅĞãÎÙi–ÖÌ dI·ŸÅ½Š-GÉ¾ ‘?¯ŒM+û¸âê¿lû
şÊœ€áx4Xô<Ó®»=ò5Æº”ÈÌ'Q *öòo`º%C¥8éıç8f=û¢ö›:’"¾r…3MóÛÖ¡;QÓ‚-<•HÁy¢YÏ©Ó¯_„‘¡ÒRE:8}"À¨ha›Ú&­~üäÃ´è8ØG$Ÿã±³>±xQ°z0HD6yğ…Œô­×ÒäIgEÕ_•¤ÆØö0b€q55xİs›Ñ?r<cPÏœÃT*‹hß¨n7¨XîÔ	åÅxav½ıÏb­l¾Âøƒuıú/$Ãå×br.z¹=ó²Y•Š+J€ÃG4H½‹Ñ<¹‚p”K•Ôæf|ílèë"h[WÍ*†-u²»—9úàUKŞ-7$]kƒ©Ã‰e÷+eã	|9S3Ù/Ëä-ü`-?Vıóş(_¬–k ¥ùw1[jÃš;ï‡:ŸsMVù–=®ÓÇ$@ŒHÌb=ˆ`Œèná9ÛôJÁz~îÓEğ¿g8ÿÅâLŞ E¯aDgı0ß¢êµ l1\'rëZ¬·±ºê^²ş5¬l«Gø/Cğ75DÌÎ±uñº0b0Ãl–í«YeËòšG+&%‡ìüÉ@>\òöm¤då ³–v^[u¤ÖBÌ5
¶­ü1†–À¢¤œ}Cò 'U:õÚ©q››_ëõUcQßT÷èÅ0rÅÌVÒî’`ÊëHË‰¡èáek«ÄG÷ =ï%YV´¦Íó‰>umÉ„÷ËQ©¨üËLV(Ïjm[¬ädÎ—Cç›}ã<OƒñJ8íº>ÿë¸;NŞJ|Ä½8Å2Ôå!½Öû×– BÏRİûèy$UC<åú ÇÈï£‚"ùqéEÿ«ŞL±³‰›ä^<şm˜hƒóv-¥q‚Ãœò†<CÓSÚÌŸDış­‰°ö¡V	ùM"BÒEíßlxŞ ó®áÕ¦ç(l¤©Á—ÕáS¡ÑÖSªN"«@GLè§îŞêÜ‚”¼¨EŞx›"ŞæÀ½ï¦8M$5t×gáøg\Ò€(»/xğå=~Zœ°G}/ğÌÚ(:ì¶İ•‡4’ĞÒİ‘Q¹§TÖ—É³<¨¤ÁŒ±ÜêoÀ‘îJ¯¿Õiº»(ê¤PQ³ûêtåçñŞÇÉÑ7†Økt-.Â ”Ö¸YŒÏDçJÊ÷İÇ„eÊ;56Æ_«¢ğ¢HXHnÂ¥2£¦ƒI‚UîÈ6C"GÂ“~s%f4´“3:¨ªièî+—±íŸçàƒ46a67Ø2¿ĞĞ†ä^‚SGZöoMÄÎ(2]ó/®ü³yE§ÎC[w­@–âÒÀ¥Zh*» •·îRêª'\†IÎ?76‰ùˆÆù”å³=Õ ‚º{9?—r“¿Š9Bàò¦9îI·â~Yığ t	`XpR ·ú{j@Îl‹‹ÑÄŠ#m›‘½„YK‚ÖEiiÕ€ÁÅÍmÙõÁkS¶x¤Ög¤ÊÍd
Oc,™2ùŠ`ON‹Ç}Ä¬BZ¥[G æÒû$Ør–<{–"ÆAZò Ãy%&¤£	1U7hÉâçªÏ³CœíOhU•i…²1y@•ã§sN·ÌÀ
Û¿a¥ä=eÑU8ÎıÍŒâDôRˆ˜–%HSóDÙDPs+aî_56(öö#öü+Å/\$tüÓ»P¤,x•ÑdÌ{àSg{ ßVVH/Gæ&mVª¨ædbÙ°U<ª„*’ÇĞ»¬›ÍøõReW±T+ß´ˆy'’?Ü$C7oT_¬šâ0‘æÄ_õüm=yŒD£r"C7üå‚üu—á
‚;\¸U¡ô7jju¶ÉJ}“u— ‡/+›j€Do¬}SÉUÂşñOû‰.‰R46Ø¹¯cK·OW¥şÀ±BK¯çËïM¸:À‡j¶ÈXçtë9ø	¥l)$	‰*7Q÷ş‹!|Á4WEŸVŒ›×@¿$3¸€Ï¤öÃËƒ¿ci«º7Û¾¦Xä…ÿ]Õı—£];iÜ8Ô’âÅØ«¶µiZ‡Â‘©,«¶‘æû!~†uŸ*áEƒ‰ì/™·Ò+]Õ!z±†ãÈŞµÿÂÙÊ¹<ŠŞ,ØT
Æ%«UıD¤‡	kèaÆçæS—8ãbªE’Ñ½©$¥‡_ÓÅõ¨(˜@_óc¸Àe­Õz™¬'—à$I{ü¬yE²âô?uıÙ°	¿­z `…¨oDÀê¥bËëú§ı¢+(Õê\éŒ­wçéÓal•9t™Ì©äe]K­
£Øy:¡­™Ù½JÂ!F`FŠx¶QAs«<–;±ê/ße	:‰l”»aäËÉŠÏ£Å.áşUÁ’¿——‚Õ¬KèF?†ÅXÆµ­xˆsØƒÉhf1Æ:= ¬6C*ó.F]3ªš8©ñøn[şT*îÂI9PÉÔ"	:"ÿ?û,ŠLÀš?ŞØpÇÓzÌé›‚ÿÄ"8Ÿ~¡’ç¸,rs\3Ã•5b¡fs¢|Ör*A¬N¿®äºŞJøSõğcX»,Ò&j£€¢T§üGENÍßÙ™P½<­ŞSÆ“à fw2iĞG³k}[,´.İ€V‡•L&ëäX&ù÷ª¥Õx?¢ÕÒD•6	!]6¶Bc#ä»¨mî­t2»¿p†¢T`çÕmìı;”Ö:ƒ†à…á!D†¨Ñ¾µî?àeMKwdäŒ™M@7fşs…}í§ä|f…»r‡>Õ$$æ4“¾5ä=¿|%âyëĞ»5Æ(P‘†øQ ^±Ê2…‹ûsP7ÈÂqÇu7E]';‚šœ2›ëO´¾±¿¡”ÓÉwë©!2_r{!¬š¯1›¡Ÿ†¶Ç ¦Ÿ'ÈÃ…Ë,%¨
ĞM™2ZÛ“]À
D¶ûÍ8Ô_)×ª`‘,YPµÉ ¯é£MO	]Ş8u¨
9¤å ˜ÚÓâv’uuÒ0zS5¥‰µ¸Ü(Ê¡ìÜš–Cd—3Ê/„îpò	ÎCd	ªõîıë:vGŞU6©mKä†˜>ŞHVrÙi°ZÌ),DC}rÂ5· ‹„ü›C­Xl€'óß„6œY2tî„úw=ÁÓİ5q:7»SñoêşËÄ¬Æğù»%ö‰ıÏôø¬j•RhW+eÇü¡RŠ>òå&ëêÇ®Pğºkº.aR#*Öü¥UÍK¼½¸oÕĞonSC¶9<!¤ÑB†	ç2œ˜Nş×f•—„9¦äWtL[§ÚŠn¥ÅÒäªx‰|äw©£	Uœz>oÅ`ŸäkVrF)ÂJÑ¶ªqIw:vB’–/[dõ{hÚƒ[ò–IšÉsR·ÜşÌøÿÖê:sú«¶E±ö¦/¬/³ì‡–æ
=¥º»îe5ùvƒn lt€ÌoE%ô ôO:çƒÄºzêåayË  o9=Ï˜B¨}’ÈUón¾ıœı¸4Ã…ïa‰É×ıtØOxÃ„gÏ¤P#P?*+F}g€ùØ,r]´
š›¢8‘F^
w»¥NÖYw©øWîÚXÿüŞP)öîØ8†ˆñ~şcÜ÷+¥ƒË>„ˆ±úæ¯*È.öW°lõïı< ééôÙ`«•i¬÷vyæ&¬?ì V=ÏE!mëv³Îg9~Pô=ıQm¢?`Èä€pº˜Òàm­GÓFN›Îìe+4P‡ßµ"ªø•yıØÃ”7iÿø¤õn?äÎ§‚|ºÀä¿`ğ£ÖŒXğ?[ï”)†Y³”_ŠÙ¹ir1™ğrğb¾A¾Ü¶né…^ì|`¹r(îà«â³O…ì¹1ÆÉÚ9ˆ!Ú¯şM$G7M}ôéãP XFÑ;»%¸ıÄaÊ*íÚ²¥ƒG6.ı’™%H9óÔíjÿö§[ÃÆÇ!šd2gá¯î¿i8ëzcö^ØS¦#%hf·¾ş.]½µdiûµë‚Î>İní#ÅÚJ[b—ñ«ŠÓŞ{ö¸¯<€òñW
;€2¯	Î*w}ıg?…©6/iØËóùY-$øç¿'*FrŒÚç&óÓC	6e
4LIobuÉ£ÊÉ	¥MáW°LäÔÍ|j­Ì'ñ0!S0S§åãLàË3„ÿ°JVõ@¯gš}MÕ~nè¯?Á}	Ùjëóƒ¨T^H8óI “×W6ï4½êéÖ¸~»_ãĞßjÆ‘aö/øÌ…8gÄ9Ìù)qş3£¥zOWÖy“Æòy
 õ¥Û·Z‘Ò­8^ÊÒ—xºšÕ>¢«ÙŞ3Îìy½S#4@{^®0è:”î•ñ
ê÷ATşnÍmõ?„•·Zİÿ=6µ»é$š³-µ`V•Ó²\úfà6NdXI €RkëÂEgP›)$ÿÔ“}~ïI0\¸Äx[¡¦Œ¶$7	œÙD¾Üya¯ÔIƒØ6Ü|èºÑdåš¶í-ê×%y¾p¿ã+ÆêĞ ÉØÖØm+Cxš}ù&(À¡Ì! K÷`èZ¾ú1“qÔ9ø+Â«Q «ğ¤ú£ä$¸ƒïì"tÈ6ãLPúÃw¶ç#ÀNâÌ1áì²(ë×²İË¾±>P[Û¤ôç-D7GÿE^g<â`©“$Ùú­;7:·V¬|İËUÔsvì$a¯œâŠî\¶d 7‡/
f³€şŸ³O{'j:‹Šô6(?`IeäBrà0;Èàj%¬!W3=Q¼óª€o \ûÿäRÑ±‹ÏO"cr{ş>G?}@ºb§ØÖ¼à\İûFöó¸¢µôä“¼{W`à±9v§n¼80(Í@,¬Õ±Õ½¹ßMTœ­íƒ‰]‰QœXÂ¡²à^	Å‚ğ¢ÅU†…Xuk} ‹ÌVT´ªR43ÿÔİöß‚c¯]C7)Áç
æ–IíRç«™õ6ˆÆO¼m¹Ç}áY­‚s)3Áˆ’PŒ	[)“‹²÷Ïûæ¤¦ïÒÖ¸‚’j2(è0‚Ì©IEsÇúş\€IO@dêÉ,Ûÿ¥‘PlŞ`K[v`Ê~Î)ËQ7rù'­}Š·ÂâYËÂ~w$c®m=tn]—|L¬šÏE¤mê´¤çr^ñÿû5äB†CÂ5nÁ "•‡óŒ¦${,ªl`ÔÜI?Më]0—âªK¯Lvÿäç¦Ó:PÊS6ËÈø.©¾áúZ+=kŞŞjê´6I‹ä˜ÛüÉŸ¥ŒêHôX¦eŸLŞ¡î¦½N•GîÔû\±¬SÆÔïÛ›˜£• %‚Äë¨êtiF’Ù×o„Õ
™)éšP©jÚóJ—Z— µ¡èeBòR.Õ!—†ªVüÛ²§"îãÓ½/áÑa$n­ÜœÀ!jãC„}hÕ}gZ€£”;^Íš6:z*ï‚ùÃœÆXÉA% æcáC¢ªç`b@uv´Â>¬½"ì•Á×üø^a‚5ÿ„[êI7y‚…ë'S¿
“wà×©ÙÅÁ4£!XÙ_Ì8¡ú7‘(´”ÿÉöTÄ":‰÷4Û"ßXOvíQpöÛ¨ÉWF©w†
8Hr»¼¤Ú& Ådâ»®gÂFR¬kšÿ~Ş“àÏo!Y)ÑÃ³}é·’òvÎE[—z³-Ë°¹ë„ˆ‰k¦@M%&Üê—”J™ J ’öœúîüfVK¢
œ†ç•XO¹sfGH)z¿O$Î0 ÕÖg/øa*ò¡ãp¨PÿJ®·{‡U,÷M‰ïÓÂ6e3\ÔËâ@CZ›‰ÈÙÌ7‚@“ëIÛ¶›	îYJ;àãá¼â.,·Fø±Úƒ2BÇ&±hAZæi›9Ô×‘BI~Âœ}Êáéô–Øé —Ë„éİ>™ë]9¼*Ñ‚éh"ªë¨|~ \é!:shÖ>Áá’ÒëiÈ˜n'Ó¾¦jt‘ï½ôÂ6‚P¸Ÿ€‰‡ÅóJqC-D>ÅO$†œ¥·ªì" SwŒY„  ”Ğü.}˜l…û£Œ¡Áw4µ/‡å©ñLŸÈÅ ‡ Ó¥ŠHSÔAêj6vøOaH£aÜ}ÇÅğÜ^3ÙŠ_„–J¾Q>…QÆªˆe“'[Kn'tø†§\ê üO4 <,¶P/÷²1ëÖ5‘ojı×F)w£Óz¢ëµx¡äÈ
 %$5'1Ü5ÖkàÖÜÛœÕje†}Œ>ã»q–G¯)…­[ğ[nïÏIa£‚P¡G‚„ÀUòˆa%Ë·Õ!á×BâuvêbÊ\PæO~ÈE’è1lºK?ÉÑÌxqwÊ¡{Ç³ÏÍÆpÈ66R¯ffN&a)i!c¡éÍı¿(kÏe<crB—….™ç½4W¥7)­¬&ÀŒé×L¤dX·®{>v•´)6œÖY9ÃÆ+¼Û®Z~É
Àr‘;gŒàıª­–?rb(¸Šn¦j7ãËÆ „sGTøôØs¢˜Ë/ïçg ,ªXm/hf+YcÂ„A;N
ª¥d";:`=„ Œ£ØUƒpBÅ¾;
Ä8,¶ÔVÔ3k¨Z‹½ ún&cè¾ú¦ÿŞŠ,MÔÆÍ’©n
Ù…GúËfF-êÌÆÖ²ÿĞ0¨Ø„zÏtëë@#>á š<l°\>‰"‚Ééiòõ5÷Eë“Õ»Øsşè¹ğ¿£Ä»IQéå†*¨TÍé½	À˜8ô¥ìş ‡İé6öÒm©©É6ŒÀ·Œ&=á¯|šÌ~¼Õ¬šse¦õˆ¨feVúœù³fÂCZ»O€¥IlÛĞw!Æ°¢&{ƒc¦Ô:(Í¡İªì`"ÍÍõ®¼‡á÷ÉKb˜Ç	qıfŞ»s,’±iä½^íeSı°;¡6ÖÆ~ÿø)TA“Oé'l½¡vØbÏ/ªI’u¾†²’n¬«¢yÔÙb3l9˜àÅ½éY(Ş şe·Ræ­á ¨°˜àº P?yÄ<2}ú³ú0øªËw”àøï¹¹»AëŠ	<ğ^ìâ!¤Ÿ·{û½ÊAçw¤ÙÈÅ•i`W¨¸Î¯òm^nlwá¨Pª Z«¾#O}¥à‚JtÛp>÷…£í´hÃTéš‰@t7À:Ë¾"Üãª~àŞñ‚cR§ÜúÄÅ|±wªW}eÎ W¾ÁE™>¤ÅìêçvÎzY­µ„÷2Æ÷‹ö2Œ"Mˆ¡Ë§°|¤ëÄ^£¢ëØ6²ävwã™Öìür™é†òDüóš¤ÓäYéI}rƒÑ»u Gw$Ö<ŒÀ†K”ë ~P£´J®V!$'ÍûÈi{(ËùæêZ«Ë»].#ÖBËY…ˆu×/SUCÜ	>Q ]~ PÂríLÔôŞf•7òZ‘4"	Êz­æ±Oß9¾a[Gâã.ìçÀµpYç
ñ6jyÁ‡Ó´¶r¾÷–LlcçÌĞ‡|'Ü·/—Ú·Å“envåC»ã€Ô½x¥$ÛI’nÅÙß•FÙ'€¢åÔ|räHW5m«;>NËDa•äó—4mï‡¥gªê ·®6êx) }Fqã\Ö—ÚAkvr˜d‰ü´O…© ù°H˜O‰º¯¶Ó'ñév†jö÷Ä› £`ç(Øh€ç)³·<¦’o"î_ˆ'ñp3…HîØl)Â';¸<¯‚M´.’:3µªºó»®çÇiú÷’ÄaXÿµsšÊ€r‘Câ“€ÒJ55¨W­Ø·HPÿú:ÏÈOxk
9ş—{úP½ù
—j†EFMôU»¡ÖÛù±
2ıÅ·ò­geÀ¤»øiÊXUº8ç$­³®vyƒE-<í
"³z^îL:œî²\ˆQ¿%}	¾&â.l7±¶•şÕ7oùOj€†-cx=pSÚ÷»¢‡pæ’d%¾¤?eÄEÆ(dÄ‹¦F´÷+ÀT¢·¯P]m®Œ[;AşfI„˜T{^	BÎ Ş`•§ËıDì ?€ ¥ø¼TMM%¯i§ún7Âp°šC˜¶¼ˆ2£i€½¶d<TÖ`_ÅvÚLæ:ß
u‡Ñ£¹û¹Ü~¿60wkÚ=¶çK]0ÈÖ)u¹MlXS²†v¨<‹ÉnÀÄ‹Î‘¦™˜ó‚¾ÆL9©ÒÖ+B!
3òé––ñ	$´ÎĞÓùÈ$€î&E;ï/İ;°Ú°—Ê{ùú½S@pd‹GûævMú\Û•÷ëP)!TFÔ„ãõë,N%Å£şYŠvcÓò3ÆÏ]•„4¾‚l…Ã#wrN5ô‚aµá²¹Fø¦Ğ’S×´I˜BúğõãõØ	4ÎªbĞÉ¸ÈFm@n&p÷¼øõ,@¼>Ë®,øu©tñû,s-²¹yEŒ˜®_ÓÈì]şe3kR‰4—áo–ø\ÓiŞ¾*†Í£®ëKSÀ‚íèrĞ½!˜;é‹óíœ[\ö÷52ôÿZ$V´?È6°Q§éè(iO­I8 ÿ¬8.åßf4D†>!¸ÑXf°š+îXTw*›Å©èGíş¹2R’Üò;;ÀÊ’Æ¥ˆû¹N¥CÛBRëhRëd¹ğÄé~£í# Â~ûÈÖ“.Ê™<‘VÇÍ.shf¤ˆ|GqMç-š!½\}ëS 5¨,ã¹Ã³÷lìQüJş,ÉÏh2½ö+d}Ñy…ñß£y´ğ8~«b8tª—¶Û,³k£ÅsĞññL°V"~N,r¾]Ñ…Êd\†îÕ9S–t1½äüiª¤Pfó¨®˜üÌØVÍc…~¨š¤MÉre·±¾<6é$âïqó2`©æ¾œ4Åyq „ÚËß‚í*Wµ£V¬ÏÂl#çsu©…Ó»vÉ;Z•#2§®Í{äS‘W,ÖTğÑà'7’ ˜ !F.Ìrî/%Òcæı³d1±àeµ	§6Õ;ğ·Jó±©&@ImÂ¯tSÆ%Dğ2 ÏB‘:*Lëá¾¦!ÏdÏ3ïvº‚…İkSª·©æ®Ì2ØİFXà,9¿&Î^U[z3Šº®VÍ¡'¹Ë5×iÃ¿È
QRˆL_Ìş«Ò½>qUú÷e¶ÇşÖà¹Œ%®Ÿ4†Âiõ·ëqÑæ¬˜ÎcÏÈ‹¡±*)jÂŸ%Ø‚­
ä˜vÅÂ TND$ì
±(ï’ñRı†önéyœn„æÎ£Ì%ã{C«Ç¹İ¥&›•¬ß,,O<9ªb‹†R1&ú÷r.ú‰¡Ïç}?ì’øS0q‡yA^!ú!ú`¿Ü—¥=5»+÷[?`çÒ9RŞ¸†ç~9K’3ÉO °^égcEãW]qe{ jÒOáVlÛÆc?©%WûE"]ñ6!¦+ì	İì™ÙJ†¹Tˆ*N¢(Kùw«6|¾­g²*bª¼m"Ï®?é8–ÄÛeaÁïLQ´/hÀB,¢€âºc+4-pdÄU9õq3ë£ÕôBé¼– —ƒÜ¸x}Dé"m­_òTÛY¿´VÁâF—,]*oŞ†•{lç² b¨”Ì=…ÄƒF>‚”§0ı#_ı¦7J0«Å„Ÿåıw¶ng£ç9ß/YQ–Š.÷Ø¾Äa‹sÈQ½-H¡]Ø±‹9{¥ Ã;(Òø¤ÍÎFğ6I^ĞÙıÂ"ÆN{Î§·¥e	#áÌ8ñ#\#¤D@‹“DüòÍõÇ)ÃH±•>ŞTK¾˜?X9{’ÖFÓ7üşI(?Ûh‹[ ˜Š$sxJNŒ•áT¯)šÔa#ÛS«Û®íÊÃ	jùÒ ¶è5Íÿ‘Í2ìZXn°¢y\¸>Np³­ŞJÃ`»]a4ê«GÒvs×/OÏKòwª•ö3Ä“!Z)„œÚ<×wÚ¯½gèDÕ¿×;¢^­0÷Hˆ¦lz@5Œå-Ôß}Ì2ğ6ı!;O4ÓÅèOMe|îë4¶)$3°mª-["¨dâÄ s¾^ŸèÜz wBF½¹U_›¢ÅZ‘¢Xi9‡qK|½Ÿ'á%·Ò«ßZQo±‘Y
ÌMZ«*|ÛÌhÿ,_NAí’FôBö½µ ³+“Øq§-I7Ü0o[ˆˆwÖÃ8õc­Ø1-‹Ãèéæ%…Nìü†Ó~ ÀÕ9{Î\ÂËêH[ÅeY)¸ŒAMz«Šúø˜FøRw¼
£å·ÖZÎâºè~üşçu\³Knò9áe®”aÏ\S"+³÷·pnVşİî2©XzåŸ~E³„rzkÍÖ=Øàı§_3ù&;X\`şÈ®öÏFîç$€%9[{¡ÒRmıEhçÅ,§«èYoqÅ²e[)øh:î6+iY€ë³njÊ|i É!àk<fF,ysÂcşƒoá'¥åj¯ï,vTfÒc%lË©ˆí±‚ïKz»ğÎıc´2…Û®ŞÌ±£A*û!ÕÖÕ{tÉVZ¾™]şìøf¿C¢İOsŠŒª°€îÛo43GL/~’÷î<¬B¢à<©$›Q®'ñÕµYiHOa§óE]ú®3\ÀM¿	bÒ_ÍõîA%
œûÛıéupePT[X+ÄkõÔŒ%‚Ø*ÀlXNİè7TpfôÃ†b(áÃ8&Õê5€‘*¤bÄÓcÊcD”Á¬6ÑĞuì»È‰ ^ìDhúƒøv÷w–¤¯’è§U#y×M×Ì‘”š Ú[, ëZ:‡Ÿ&x&ù¦¨?Ëû™ˆ„=rVì¾Ë·jã~fÑŠ¤^W:d    [+İä÷ Ã€À£¿´±Ägû    YZ