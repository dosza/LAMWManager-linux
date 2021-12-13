#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4134218890"
MD5="208596b94c5cea6e3619fa3fc9383de1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25556"
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
	echo Date of packaging: Mon Dec 13 14:12:24 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌâÿc‘] ¼}•À1Dd]‡Á›PætİDõ"ÛcI‚4>®ÌøğãÀA ŒZONÊUwĞ†X˜š^—ø]$l¤Ëz¥˜_Æà~Îí‡—·û)ımì0Œt#zÔğ­AÄ`Åz´ ‰4vó{dñç¬,
RIÓØv¾0\ÔrOáÈñ!kÅl«>z'®Ç)[ótÜ¨‡Æ7@ª_‰Yl Ë¨´­DşwãwÊ«EH“1>™¬V:J;CAU`º˜{æÂ½×.±Rçgnoû%l¾º¡<õ¯^u!¿!İŞWÅ~neŸ±ƒ İÎ	¸ùxba‚˜qz¬¤£F‘E®¥ÊÁÎ™¡Í$˜b"‰’Œr_‰ÖÈkõ(ö¯»ÜˆÕ«ZKì¼HEåúi¤Ñ4{·pWåë€­1‹µ4Ç6¯¾rˆrGaÏ­…Ñw:ßŞ»31çÿ^¤](©Ä£—Áşçiìç…„ÿß~€ÈĞÏ`çº²3±GİÔñg¥‚ıjÒCˆ5ş"€,ueh>ÖB?+BaÄÿ NhÄyò‚{Ø”Ëõà?Ë3¢S_9"ôÍı¯Iè\´ÕğJRÇGß•Ù¥—	é@™–ÌôÌÓNv;1\ÂÌC-+Æ=dà™×Ñÿ¬wù=WGèdÇá‘½Ñ¾Hwqiäe´±Ù·!“—´§°)èJ½YŠ'R–'–ëcÙÿoÚø‹ae3ØsèDò}»àéaò:&¸‚pnBCc©#gö.X-R¦M¤WÕ÷ ‰„Ï5VëŞ¥lEàãŒÄuğL‚«W¬>ı#Í¶à”¼âØ‰’Ù(4kÉ*ÙƒjV—Ù«M±˜¬3ÎƒµõUb„åœ0XµL!âİÅæ>ì!¦‡³|óÛŸ$Ï 2gV¬hSÜñ_MéË ÍüĞ B\uĞ4Å7€Qˆ->g^+$ÀÈù†µÇG{›€	ó­˜ç/jX¯OÿV~ªÔ›ŞİZQÎÄZTtÉØUıiı/!„ıĞòÉ“°òsDÊªSÁÆNØHÖıJĞáÛŞ™'H·ÄÉš”ÌãB_"ûu‡0˜½W8ä
¶6¡Ï*´ğ¿Çïïì,{Ú¤5Û:BYîÈã…ŞX½şÀ Wò€‚Ïå¦^¥&¹Ã«º%,Q£^³¾»ñè­#‹jqÒ>te»R
Aˆƒ®/ÈÑ‡"
Ñêt$95cJ2OHcaÃ
•P£èéŒ·T1)½i{O¤D:xĞö™É |q› Ìò„+Wë¬Šè7Hè9ñi|ÄÊÃ×¼”¨é]Ût˜_šM…øWã,É£•€¤w:<çPŒç±O÷~äánÓÈ×ëhœ_€-ôJ! Oñ6J¸œá[¡,uV£X>ì^€^ª¼U u8’[ÇKZ à-Në%¾_[Æˆî[Æáã7ªè ½S¬r
»*åZÉÌÔrã³ïå[å¹ öüÃZâ­õ‡GYé¿R1ËĞsPÕ,.æI>hkÛŒ‚;ê-ì‡dÙè&ÂÉéî½TÄ Ê"+Ñö¼†	j^º±€	´ Í­½4è¤ÿ}¸ùC:,f7>RZ€(‹J—WLnÛƒpTUQnC†)ëô$šp"ïÅ€À(Læ\9+8¶&|]f
–ò<- cV¡i=:H|ÓÇpş¸kP†Âº¿Şºİ;‚º˜–«¬yİæ%wl$Å`ÿ #äÅ©İÙ !ÀFTFœ[0Â†d³3{•WyôgÚ§%BFL·ƒ8÷…ZÄİN‡zl®ˆè5Û%ß_`1UÀ$å°S‰ËkªlwıŞrÉÒpu=ò÷gğ%§6Ô´yÙ|ñ¥Î¬$I,ı¡íá4qú«Ë Ä½“¶–$‡¦ šWíªÓÙ/²Ş¼ÇŞ›rÌu§	ó„˜Uî]Nô­¼%İSfí«ÿ““hz,sæİíCx¬ıQ[Ÿ!b-{t~§áSœ+¦Ü>óç·š3õñÜâpë(×˜Ù.tŒ§2‚ÕÒTå·eJ·ùîá¥¼ø¹ŞúÔ¾‚[N<0`QÊ£††Fl0ÖüñGÎq“9ùÉi™£Â6Ä96¢½ß6[a0OŒ$õ¾dU†(ÊÅ†
Ÿ3…ÉöP~ñÄö¢Á7êÿZ›iE…ã‘‹—ŠceiªGÿ+ÑA¹.ï2¼*Ë¼¤ç¢èdyÌè%7‡VÀ±¨öyZ˜&¤‰Å@eòíğú>&·ä&Ó!ÚÇò¡ó28{tv‰tİë2D×Ø+û¤h0b0Ø¢ø0u£ÙütØÃ)İa²ääÚš{ÈrÓ6ĞÅQr±)ğå€‹Ğ^t7†>¨Øº?oœ-!èñR9V·söo5
“Ÿ~5²;_—–±Ì¡éKx²y°›:HŸïg"Êğÿ8Â_ÓuIƒ ²Ÿ©6%İG—f™táÉ6~ÂóÈ'íÛbVô?
°áÇñ4%ŒŸÖ5AvõÌ`ƒ¸å¨´ü3İ3‹	›ÆQ¿€-Š‚7HéÆbm ıîÃ«b†yƒƒVnè¹›–sÔ#_ AF¹Şö£“¬¼ öE0ôÒãÓ¡ç@<Bo„&rùF`U’pÜœG ^K‘  ËÌe"GôõÓ<îä&ş®C"Óÿ=©ÅD³BÿDVše•{á³P~â¯¹Šï§!Œ,€0»8W@ö!ËL8§Xí¦Ï±Ìß&Ø–s;íÖ¥óh/ÍÜm%¤v’3pÔoÓ¥¤
ÕutÇÔˆ™Tùx¼mm…â¬,’rò›ÚğØî]
Ê%¨#¹ƒ:ë÷ºn† —rÂ[Úm K+ƒªÏ¡*„·‘]‰e¥pRÜ1–²¦DwhõÃsÃ¥ñı~šï×Š.R2»@:Cç³øÆåS¯UĞúÿ=SÆ‡™ošë1Íâ5-èPK›ÙÊÒd’ÒwªÂ>»5Òãèµ(0$÷1/	Ùğ9¿Õüü§«®vQ»ƒ«c³ˆZÉE®Æ¿¹—rãîõ°®·Şjõ€âlÙ4klıU@5÷?ÈéÈ“YàÄ5ÉôOû/¶ò±ó ÃìXqŒËúµºÚE}<A
±™ÏsjÈ4LÌÖ“ûyA,\ŒdvÉPLÑ
¼`•Â9­È ±µ‘©ç¿‚äŞÂ‚‹=0†Hrí¨ç!°±F9à“nxg?V$r9M\Í¨{ús›W–’æ™3‹«îX:ß"¢.z8u7@Úƒ´ıêç»ºK'QEı
5èšÎõ™ñ<1¸‹PáMĞc1`øöô30ËÍ–Cı–Æy1!·#ƒõÈcÀãn·QÂI\}Êë½ìèÕ^‡Ö—×Û[€rGâyñfˆ'´„•´÷!2.ÒÉî¤r¸¸•A]‚`çQë×Cˆ¿Á1é†*ÊØ_¼õÜe¹Áï%>b=@&]&‹ÎòÂe(Ò×ˆ	¤‹!¿AZeznñPÑáTd&Øi4ûgÌ¦æ}ñ®DÈxìµ¼&BëÄPÁIy(„ØìrZøv÷1ç
~V:‹2óu †ò4Ş";ÄuŞË¶nc6j'~İ}…9Ô÷5Ú0}P44í„
âSåØıúÒ¿A¬í‚ºÍöº´¡c.4da@Hiy—÷ÆÁĞ!„ $Ûñ@8 Ÿ¤cí†-‰ás‚^æ>Ÿ¤…‚5oü7¯Åá¶7wÎïE)—³2,1l‘›.
™“Ô8'‘å»Z±UÅöp‰¢ä>F…%µ‘CwµGYåşRûc@ê•èã!7Ğ´ÿ72è>Ú(ø“×<ıDH&ŒŞÎ	ŒŸÿÈá³Vy¢éseÄÓÁ6kY+tª)Kòâ…ó3@ûÜùÊÁöÃ3¹`×•Æ°¤Í>;™Ä¡”Ÿ|WKñå.RÔKÆİçÉd¶ƒ¦ ËüùÓÎß‘‹B‰!<„¹Ú9d
5#}-Ö`	O‡åB{ÉÛ™?ˆMz‰F˜];K>Ö8©ŒÙ!Ó›pìl}·ª—‰÷ç>lÌ†á/ü´y2t¨?äQF³;Ê\kªfÑ{¥º„¶”.†€ôf¾V‰oó-CÍÕ~2Û,i ìl:¡§(ìŸMgÆ4P(¦—‘ ©e›“q-/”'—O\ÑŞÆKÄÎ·>Úìxå4#%L5^\{ıÜ0ob—·Ÿœi¡ÚÂ•27S°2a
?_¼}Õ]çXP„Gø‚ŠáˆÁ1À¼tHc=ØEe6)uúäTƒà®UIa0VÇOáØGÎAÂ#&)¹ğ¾öæÓ{|ósÔŸTë¼&È°Qmæª¬ãuOÿ3=B¿JÛud0`~ÇT$vCÆŠÊªœôƒá¹öèîÊ°H>”ç‰98Ot“’t<­UluÉ*¼†–,ÿµ²¸Á1ùc›N D¥¶"Fà¯5ß…EÀ¸nòÏ”•8äÏ?Û,€,7£)
FaOú9¹~oš£HqÏd–<+T×O O²­d•ËH/ÇCğñ°˜ *ìÃÔüPKdÎÍùñ¨u5)!ñÆuğÓ…`İ¦»’d‹í|·¢Nlæ.v0e¼P%×ª¥
¨Ä
ÎÙa|dÔöœÅ4Â)V²ñÊ.ÿ0[!â™;ˆQqfgRN-É¼y (œ÷rŠ,ó¶Î0(a"àêÕı10µëÛ›dcİu ´*kÚ­X=/­]TDkçcëÍ4ğ§.oã mäHQtr¨ä«£’Ğõ»†“³DA!¶¿" †Ì¹ğ»:,İMö€Vè6ªšp%55vb2â%|AŞÀ3.ìn„…ÏëıF`Ú?vÚjA¢C›eÜÿ(n-a¨6à ³n&L0‘ˆö¦³!	@9OÓJw»Ó<¬?Ne	 
XZŸe`¼#ŒOb?1üS67f¯ÍëÊTšn³èúëNz†e)‡b
çñc#˜û€÷®7¬â<½K\.ë
Ø¼P>ëÿİ÷”Ôñ‰FRøĞxDa"g/—ßW1 6öÍ?Ü¿Iğëœº=y9ª[h*É§¾¨y¨*©Rêš­Äh ®x¶y©`+”ÎsàIL•ÔM%Ûæ¡–]±—ÆT´ ¨™ÏG‡}M•¦¹Q öÒŞ€Êû×vœ2†ö=°¯~±‡PcÂtü*hÓx«æãôÕĞ(Ã?ésÛÇ9Z$ó_¢Àe¦b:ò ØF70+kSôYi®‡‹ê]ßğK2•~&¨“xà,…Ùbœ­ b”=à×Xñix0% Ï3€aËSşXÈš
26…óR3lk#®CîuªS!N’	 ÀÄŸ P±š±yİ]AE»zõ_Ør÷ß¹•Û¶7F3ŒÆ#óË¶ƒ ‚7	wúÁïFÀíctƒ»amo#çÌ^ÌaöŠ ÛE§i.eÚ«<dl©uØşùÇJÑü#+ˆû$®æØA)Lş9³+šî¨«adÜFuY"¨|+˜0Ëtn˜àùœŞ¸ˆájà37	×±Ê±u	YF»–mø(j=lòĞò»†w’ò-q¢b™¡LİM³uTnïÿ-H®£DæÍb¼Dkò·`Ø§ÊCÚîQñƒ¸pã¸9IÈ6-™v*!nn­¤—<ğ€‹ò0ÛîU}¦Ía›¾#!;*Q§œÌTáy€®ÅJ”²Ğïirr–ÎĞ:—AÏr7Ø¢K>ÙÎ.˜rı,×à ‹q{¹1ÇÏ”Op£4Z[‹bvtƒ‹~¸<ªHç&<¿B%w3Šˆ9m'+øpìMÎd°Áf}\ÿ¢L¿Unã˜Ë¬Røğ`“:0US8!ÚÖD#¨ıÕà-¬/‹î®¤m”sQºQâ¼*Ht8½†¯¸PL0)x\J<xk³hÈ‘°˜r†ËOÔ" êt}NÙÉfP“£u6!nE]£İ¥é¾Iã·ÿ5\¨f¢ƒFMìlêc óÚ/+ã»°zëJøÃ]^Ì­9<êMÌ¿Ù4Ø !8?«õP?,f‘86oåÅ¬µ¿Jê6İEºÒWíÌV9LèUÊƒîí	D’ó2r@¾5¥X5ëåîA)f}mN™Û‹3‹ê‡ËªK}ÓH‘åY’Íµp7i“oó$ë÷³ŸSI©é=’D»_×ê6…hÂÎn`üšŞ=qĞ…i¶­`PÄŞÛù6åè7×
Hïõ-¸‡g:y,İ!±2µÕ	}}Ã.aŞ€ãÍ>`vz«Àú[‚ÁÑ‹®Ke60/¶é¢éH¼|§C­õH”5`0NK©oı¿éÉ,#UıáóÉÎóıVS^†P:Aj’´ÊÑÏ˜ÀIzH2N.–ËçŠ‰<¨ü*ek )â6r!	µ;\ş£…Â®P«ÔU†óº:Ñ*ÎüÈÉ¤qÿ‚…ÂG·oB[¡‘Ô±)^R0Dş£XPodÁeBY}Hl®ò¶…i	¿YLÈsœBïiªìH­£"aıLÂ¦³&xï‡­-OIÀŞ]x š(â.
…ª7ÙRU¡_Ö¦Ó'ÖÇÛqËA•6{nY/;†ÆgbÕ¤õ¼o”’cd{×·\äd>i±¬Gy_>‰ˆTğç>ì :S·UJŠ1w®ÏõÖ‰N¦ÅO˜ßÑÓâ$•$c”1Lê’‡Dë4Ä¥j¬¾F…$Õ€29·ÔÂ¬·¤,~Ñæ³Æ¶mIMõÎ…É`$Aî™Ökî²l¬´ÃdFtîl‰˜wpÜùˆ¢1ED–Ñî±î2 ìEO[¸°×UÑ÷B.’ÜA=~‚xH{ÆÁT{ıÀëy:xÎ¥%bxwíòˆ\­‘›I’t¶ğsx
­ÛlãKnWr‚ÅBúÂÚz(œ¶7î:úi‡ìÎ{A]5,¶²5¨ÄeŠ(3ÄqÈ‡ÎÜ«ÿ’C>Üš\ëGJM§û×JLPkqäe€{DÖ­ŒË«o™ÁˆöE™Kh
äçÂC¹$Ã€?È0&4%N2d­ëÁ C2ë;lÑÌšà¶û'àpò€dYÂ+AêCŞ'3çg5,ªÊÛ×ù-Ü°ğI^Z5cH3¾†¬ÇNFuöÛ†Ùd»ƒêJ4?Ã+3Á<%@Kú«Z0
¦f¡t»”gö/QÙ«:‡lİè×œš%öĞI‰›ˆ~Îˆr_7t—kíªQ²¦Øİî–ÕUâÙe,ş@™+â¡ç'§}ô3ô'#\beP)óğíÿÜBN‰LS…9[G¾dŸğLƒB!B–¨­õFH/ê€ªê[”ƒSâjéV×‡ğŒoŸÁÍs-¿Ğö¾ÄT‡û
óJº@>ÓÈ¼¥ZSTPiÃP?0Ù£Ş™jêï„Ø%ìè¥G£;'êFQÏVvÉC6€E„¨c&2?Œ’íş+Å¬MwÜmÄ®^#i%ïY;´p OÈéh£ÿäØ±­JLl¬¢tò¤©Ø 'KW„ù>9öÿœ„¥$iñ~©ïÛÕÚ6¾óçÆnĞ-Û)ÌM)pÁp¯RÖ
±?æ7gGt§Î	xìÇ:/p]Í©#‡ÄĞÍÕ(\ ¾¾Ÿ¬e)°¸=9!‡§„iô¢(÷+Ò·ókM!«áÅo•õVØ”	œRú”MÏ±¬4Êƒ«÷ZDŞéºO¬II ÁÊaş-;E}şü:E‡šXÉ‰RÕÉn¿oïpßãN*>å¾á@ûÆ~ß˜íi¡^y‡Ì­Ã‡dÓyº4V-aø>¢Ù<­p+Ã\¡’…šªÈKd©
×ñNø-Å¤tf* ÷?	xnDf
µE)ô‰ìVë›ü…bhÂ©UĞr^QMéıaç$Ã#™¼iÇpOVHÌä~O·MÄÛãç‡w××Z|šNO,Ên•œ2ıùÚ’FÒ)K×I™m#zÿôYõTÔÃ}pŒ¤Â(ãnµÔŸ®ß>nÄÄ·
»bVOˆfŠ¨ªaŸ´š‹O…/*XƒP²²ÓÂ’ŞŒãNåğ:©®ÑXvë3ˆ˜Ó¹Ï6°óµz±†…s1OxFÃß Ş—Íô´î·Ä®SZº˜İÎi«¸`ñm>¹hx¿qâY=ıO¡Á“`ˆD	¶{ªe¶ÍğB dÂÍÌqØÂŞ±ğÔº4‚ç=oéğĞÙdRUdCM“nE0šj˜9€.¢ñ[3S7]M'Á×˜ªŠı:º3rn,‰r^úuÀ¥v€„‰ü­S¤W8ğOÄ{D€(î´}6H“¨[Ó ß½8v_ûæœ©‡ÂìÕ©`@]Dï¬ÇùI ı8[€ô7z
ø¤¯ßkæ4:ääûcÛNjE!SŠü, šg9€–17*PßÖ@¨b¼c¬ı}µÁf±H¸å¯ó0dO:—Š=±yFáÔ•‡=¸®IBN“‚u—“ÎaWöãœÎ7Ş‹î´áˆ gEô%è|ßçuP©³Jş¨å	ì(Vå3€;µØK$2É¼B<ïA(†)æ'Ø¯áx#Êïµ±Å¿7¡ò<ãl-`èoü€\KçßC‹}h€­ÌŞÚ,Æt½ë–Ë‡é­w"ağbü\%eôxêª7úìÎĞ§‹Vü#¶«½k•·SOqG
:4òvX0gœ4ÜcÅ Ótm^<S» v#:A*UhĞ1ã^²®¬ÿ–Üƒ€Õ«	·\û˜ =¤Í·àíÇm‡µ(<2Ã{3¹š–07¬Áç|¼LW‡Ş§ŒÌùiå˜AîP¬‰ˆó´âo‘&”´:k&ùè¸Z¯	:¢€uPÎMªÚ|RMs5rrÔQ÷D6Ã<…Õìå¥‰#¤vÓ‡JÆ¥60Ãy;×Y”Ö±zô÷äèK	¼/,»BÃ*&É>r¡ÎWOö	!%Ë]ºÈœ4Y^—:rİtıU˜eŸ!ŠYPu:Çbµ¹•"@@yw!ùş˜Ì¹\¹ŞÀFüÈŸ°9¶­Ôbcg°§³ìÊA8­“H:š²²Uº`N
;·C¨sßjT¹Or<àœr×z!rÍK˜6ÙµöçªÿLâÑ¸m(ÛÌŸöİbWéa2ü[ÂIŒVO©Ğ×äCTßWZâÃÍ•@+à.RN¢<9Q‡_fªÕ=¾X;g(µ?)v­»½ˆxxl5^ÑøåĞ†¤n}¸›=hÚwï> şa?Xg"‡jNåŒÀÁ¡< óm8E¡ğ£çµ×mÏhŒS”G—âyÁZ³õĞ°o/eq÷F`¦òP›fD•è‚*;E¤êväèÑ‹™ÛVûlšhCóÜ2yË/CPĞ»§xÙ&%ZÆ>Ò0\Ÿm²µ¯…‘ÓÏ›8Ïô’¨“D%ÜO|_º‰gvÜâœµÊ‚:’GĞR¬˜ï ïú¼6lw³É{6×Î|	t¤ôTÌ«añúRßãœo—õ®	ù·Ã¾³$uòôG^Á‰XIdÇd#[-.SuX‡ÏgI~ƒøÙq™w¬m¶¦2ÉîM½‡Œ°$1H²ã| >æ…«Ÿ. 7œ-jï,xí?Õ‰4ŠtH™¤àŠŠs¯çšRı¹ºr_¥Ø>ğXWSÅuO@Ç•óLG¹ğ¢ËgŠÕ/‹°pËªû fp«Il2QQ@<>!¸ÛäÎİ[‡…3ãeëõIÜ?!äÜßÀ¦—KÂ`l5À¾±å²gı6£ğ’—Ú©º¿J*\„PL– Hÿ3vËóÏwÁì:<¶7ix…Ÿ`e«…b—¶ğÑ¶oõËZƒò
²*ÉQı„‰%Dİµñ9e ß°Œù¨~”´ßƒ:åæÌ! Bu*¬İ/`Şiú<s‹	^HãÒ+êÁìˆ5¶–qåJièu·ñJVNĞ§ùÖ§ñì-8äºCàiï	ù
è¯»eoå~)–4„˜$…{$£v=Ôâ†à :Ğ”Ç²Ô¾(Å5¯ë6ã»[± aHLc¾-€Ïu=;œ‡Ö«†r{`|åDÒå5äÈ_ï„òqkÏæŒËç†I	:$sœKÙä’¸ê£i%#â§<°õj´ãæç›  Ál÷¸K8£Ô³ÏœêÃ´xå4œ6§h'è[Ò1íj6Î;ó W†—'üÜ††ÛÍ¿ëe0W¦á0fzcO™~e"“û@‚Im©¸WÁÍ%¨¤1Y/LF†±¬â¦›ç³¤ŒOğî©Ï¢`âû¸x»çqòCKeAì¤:q5….İk¸Y°âÔàùÔ®Õ?t\µ_ÁÕê77'Ã¢zF,Œ…€Vr[âCv :=àÓóFì=:à¹óIú]u7¬NËÙŒb@ğ†»†¨ˆ£û±÷-mnÔy[Ü•˜Ÿ‰VañÛ+•Æí3şÍDÛ½ÀoGÔ_&b’WãOÚI×Åe°$‹Ñğ,¤‹|Ü+\%o vÑm`—Jr»Š¶Î…¥Xí&å“áZ)ùëzÇ%µçûZ\ÅäË\Ïà°U€î¼?RÕ§ÀÌ/º~ğ»ñØvôÑB¼)v’™Ÿ~5ÚĞg—ŸóÍæg6è¾66Ä.âºˆ  ®ñ OÛ!Hï[][läM~G­ƒuô‡‹{1~K&÷ú¿Äû¿¤ÖÔgLÅ¤$ìŠ·¶m/,z‚à™SœØSÕù:¾1£·šw<ù#$Úz×•‚ğ½ıç ÛbsñzKA¨x«‘ˆu
ûÍ¼öğ©‚ïé d‹ÚJ¼éšÛ³ŒH‚HˆãDîñ¡-‘D»}áÅ*è†;ÕÉŞ=7‚Q­{Ú*ñºL©v—°x.L¦Y¾#	IáN½¯t¡úÚ8fYóq†@A}9j}[~Ğâ’í¡S1–™òÌP¸,‘s=BF”®§ºº«öx¯A„£aºùsª¥¯P„¹“Ãú¬‡JjÓ%Ju1¹9»¤L¯‘7¢ó€×Â\ë,ßs~÷[^<¡h‡)ûÑñRSã“kÒ'½ÀqÅx9ı#í°G"°àĞ·Äøä©$„³+¤Ä½¸’d¸ğ—‘£ŠiÍk} !¾ òª•…²rD·ÊïĞJ+âÁ H5±ö®Iz¾]·ğx¨ÎºªùĞ|_ ›ªÙ M(1Ÿ,Œ`7ò‘0Ô€²_üâÅ=~, š^˜à œÉE¯J{PÀê²{àÃù°{Ö^g.Æˆ]ábêíÛrÚÃº}¡{‡E¾ô’e!Jƒ5.Ğğ^¹z+~ˆ¡xkò®ÇîG*4 ’`ûtWNÃÄÀƒPÃ¨_
šª¢ªİ%îj¤›®¦ÊíVnâñ[MµJåãâÉÉU,ş'ùA›ÿáİîş7šG&õåî9ÑÖ,YÚVäÿ¨qû7ÏØDKš›íóe«¿-š‚ie¯òíü}ên·z’ºĞ_‚M`>}ãŞs¯P†lÔº¦µØ&À(ı¶®‹S8+¿šå(u@OØÂ¾ö ç‰òfVCÙ42R·Pğ¿«7Ğ"İ!	Ú¢ÁÅK$ªu%Šiq¡.üXPÚ¢Z0zâO©G´SŒr‰òÌ_¦¢Æ\Q¤ˆÂÒqß¸¥³†’ÓMìœ¶ğÔšËçkiåt&ãº˜û‚
@(+!úU2Ñ‹W×æ yÖ»r%ö®\–­R~¸}Å€WJò§}õ‚´Áñ¹Qé Ù8N˜ğ¤û(s–m?€;Ä6;M°ho¿FÅ¿øFïó"ı~“0¥8Öıı,»™ˆ6È8ˆÌly {C¾áÂ;Ü£p!>"ÀİK@g‘ÖâìËÖS"šKÎ/%Îûë³ŠW×Îşâ€-X‚˜óò'Y±T~7¥¡É:€ÕëE‘Ãe¦ÜR×DØéÄ¨ŸR33™¢¡ÇO
öÊèN‹tª–'ÅŒF 7I^¼’§œ Èxã>rNnû+ÒcøØÜÔŞ¦Âr³U™ƒ<'¸‹÷ö9gÄØnj]¯“}'ömF]ÚJì)*°şg²Öj
p¿-N÷ßˆ©ä|LŸË0óI„F^KòÛ»`È¹âå+­%™!»¹6:UK2DÊ-öÏØ£J”W¡ıx¯ƒ³ ±$&2 )ŞÉÂH2(š&¶üõ6‚[3‰»Ø{aÂ6i¬µÆÔğÈyÍİ=ÇĞ”¢qDåk|ã"Àü=¯±^ B|ê¤D3gÀ…Ë$ªr<å†Ãc­|¢»wİ¥«¬“Ñ…ú“£ñÒ¢¿×`¹Tõ•
ÏÄv’ğ’ï+ã‚œ_5²çÅ?Ëó²>û×iğš«ù3&®Ÿ¾l®\Œ³³ı9À¾6~§ÜÔ"Ú9#6Êªm˜ıÊC“é;*»ŒhëZŸ÷İ|÷:rFı·‚%ÓÚ´5ğ•ú’Ç%¼åŠ#ı~æRµÕh~}d|üut²"Ä;`j£ı(êe£Ø¾èó.'‘Ğ¿Heçı”’våªßò,ö¹ğEõ³+ =9ô[Ä8CÕzê-GŠ9Ã ~?¶‘	½ãt2sbWÃÓj?&ŞiÌ¯[ŒêŠÂ´äYÔª		‚‘}20`6a*LÏBgùdáDBæ	XîêüIxIGœrhé==9"f,‚xùÕğklâhşŞ3Šrd†´:Ä]Ğ×#?p›xákYasÇ¥ô"í\ŞK“>®sæ˜Œã×ğQëûgUŸ€B–˜Kv­ßD=Vçíh0NfÁÚ©ü—$æàöÄ¤s9ÁğÖ;íQ	3$½&Ô]Ïj¼|g_ĞÕ6º‰˜×¢©…½åÇè¢€mŠrtï1î±ÀUw¶™·İµı,SK^Ô9\¦dv^²²p&Ü	~˜¤<äÀŒ#­@J–m†ßñHLƒš)EİÑœËè¦îĞï$o8ÆØqBå‰š?:€h‡uÙ¥¯¨O«ƒ|uR,–¤,-f¸BÙ+'³Pİï'2)÷ï½Õ°S—ÖŠïd„(B•;¡Œ/ºy% °òI]ÜÅW8Vœ”3#"ŞùX¶"ƒ‡—ùqøGß«Jó_¢Ä½¯5¦Éš,H%Jíı’ûÊyí×J¿ËÂë1Q#÷íøµhíœÏ™(Ûwzğ”²jÕgwtMìËzòa‚¦ø¦‚Änxÿè”i±Ğåü¸#ï-m@$8°ÜQhÕxÛàØœ0™´oÈKªŸ@Ÿl½¼*}wßˆ,Ääùà¨.¡Î¿+—xÿ[„.’%@×Wê¶ÌB.2îr‡vÌØ6‘¤|É„|Ksé‚¾¼ÂD[§zAÁo?!d4‰[ßõ˜'°>Ñ!~`ßP/š^Û¼`<Ôáp®AwZ{êE0Ş ÄòJËˆD#¥Ÿz¬6\I áÈß>µäşJ~Ë‰g<Sñ‹{šÚš+Îc­hÙÅ¸5Ï?I	@õiÈa4~OK#Eæ1gÁ¼cbİ
¾h·çÈ]X«—0Ÿá“’˜ kİ¥OGŠÀøq0+ã†áMWËB&#‰ê¬|d„ı3I‹İH¼X{4¬¡$Ø!Y ÛÍÄ„,—¶NKüı¸›µ«síı~6-L†`òÜOâtLšCºÓ-ë¨yã¥VFm‰ö²W†¥At¸‹Ô_Zz?ôñ=[1­à@Œ^y‰GÑË|ª^áY`p®úWÛÿ£ÔcüWWßU@¹7G;ûoZ“N®Ò“pŞÍPv°èkß,ÁÚ‡x/Ri®œn²“Á‚SX»OA	¸‚ĞÛ2ªºÌù;NR³şŒğ ÚrÉznŠ†Îã“Ì ]—¡cnXúš†ÀsMà>Ó3şØÚÁ×1ïô…?ªd;à‹H|„ÓÙ½8AUl”˜ŞµWgk«Hóä‚¬ ÛGN¹¤æq¬( nÁ…É‚)ˆ$EÎÄ§<ëQq  ¡G7h#¬•/Ğzn·åÌä´/µ;üÕ)n’×ş¯/%ºpâÙcX¥qhrVEÉ)µ®–Ø©ëš!,A2şÜ3òÈö•áŠÛ½“—&ÏRcºaİPq±qã€=Ò† j~¿ë§¬Fî¤®Q~­é]ÁÜ$æ>DÕ#y)„Tı“Ò–cxŸr|FO·êøvÕ”ËpÜ%ÉÑnaQÓÛZıÄ÷“¥Ê¢çëY °îå:*‹˜!a%ëlcÙo“²ğÒæ·ó°ä7¸UD£ø;¹2g&Ám»‚Ù's¼›H"[Ì–­ƒ•Ô;òïL[õÈ»cÁKÇRb™ï¢\uFRÚ*²*ÿŒ¾ÿû‡\ÛÀUdq‚­•ú`Ç×Œ‰3u|ŞºFB”Fµœà™ğ…lFˆ“am8«û“ù'NI0%ÆXš
ƒXÃÿ3¥½GÉ‰ZızıÛ¬Ù×·ºÕ³æ€TYSzÚœ†¾¼F óÜaBÁ eMSU8•1¨¨øTã›êîÒák¦ë“ô\7^t—Z€¹^‡4ƒªîMÙ_éµ\¼”‰»³–ïÆê2«Òıp[ºæí=f”qE<U×ÓıÚßßeµ9
Ê2×†ñVoáå¢u[éSÅÔ«Cfê#yñ/aĞöŞb¬7èàËç—‚»MKMVs>Cû~D’@ğJòÑ:=j–)K`Ä œOİ?ù[¢¶§U	{ûtåQÑhn•\¥s¯%Ô#İ˜Ìù•n’@ÑØcr¡DÙ$NW½0¥Ô a¬ß4’<îoÜ¶ÓÊ€a®½cù¨:p2-ÛgLĞnbBë„pL€hVã­‡ |ùxâGÀjÒÙõH&ğ¬Agã˜‰	~¬ú¤l³~·3íGcÈƒ99Û®Œ
"|¹3)‹R°}TDOÒ³'Ók¢ÙQË±Q”¡X[¨éTËøSÛäÃQdÓ(ÌA‰qbeY^-‡[kB@úÓ³Ü«*æy=¬4 6”ZSı˜ÛïÛí"yü™	ïÃïß,»¢ö:30˜5¥”P yrJVÎó^^vDv¡eöw3ÔhkŸÖ—Ï·Zx	¥u]_ÖJãFUÀ°égFªßõ`ïúÚŠ¹ÇÄ×w§¼i[¥û®Òm>ÊF ig‚5ü½ä ôİı½Ù›‡q5ÀT±Ùm<í¡mÒ üŸvƒ‚ı@f#Ë²X+Z x´İ¨‹ù«t-¡úßk†ò9%øõâ½£\şÔ#NiÔ ×„±õ„3f³fØ”Í'¥‰mÑ3
¸¨8D"-ÓÂ8›àğ©1¿9 VôeêÃ^Ä/17»¯uA5¾Ù5 0«•›šlWw–ª[±İ<¨‰h£;lÆ:A!Ód{&à‚µü’¦•,Õx›š ÀÑUèI®N™<à,ƒøNWy'şV¢DÍ›QÏòZ^u¿?êF¤<Ê®ŞS£í÷À¡0 üîãïÅ&&ı×Œ†ôùŠg7”İâ”ç·ğHù§şh‘•QgØ	I‚ıì/Tık8Â „¯ã67`=€ESïm5ÌààÁ·É¡˜rÌKêAô¶wz¸…hœø°^v”ŞmêÆ³­µªCD<X@Î·­š˜)ù+xc:™ÙĞ6UŞ×¶ĞlÂO ¹®Ç’‚-¨-Ô*AŒ®È`ßy§ª"\{*ÅZŸ^ÇDˆW£^?€dú¨l28àÎ?Ñ˜/<ğÁî³D&mO´ÃéÛÎ`Hµ»šöè¼wé\S™öÃ	ŸÁBŞ]Çw†ï Ş°’bˆ!ÏËÒ˜mÜ ½<ª»TyA±¶ª—¡¼H¥ZQdV¹Ï)7³C{`YúÕ5”$OÔ˜3€Bƒm‡™m€PT¤%†e&å$ôwêT~PÑd2ëš(ŸvFÃ[±÷cö‡á"\óØiûZç×çUÿº=A{t}ïÙµ!šî9“úŞKtJw¥v‡Ÿ#¸m_9)Æ¥ŸdáŸ(Ø©îM»*ÚPb&Ô™Îh&ßû4³0D?õMÛÙG4ñßj§Y•/'òœäZi3âŠÔ!¹òxNÉÌ9-òéYêKÈHŠ İÃÑ\_Q»ú«Í·;¤Ú ÕKMåd‘¯4ÀnôøÊ¸Í“\N¨GˆĞvíûiİË¡Iü8€f[üèÃwë³äÃ2×àZRûT•2¤Xğ6•6¼FóŒÅUÒˆ”¦À4tvAç"à‘Pçõˆ8Æ^§èXêÆt ¦Kr"ŠR’¦(öã÷5}K‡Q‰Ã·¡õÍƒÕ;½‰CW¬¬±À‚+Nô‚¹s>j0Ckw>NêVÒä_å¡~xöAÒAëÜMúîmèeCçÚ	½=»H#õuê¯õñ,şŠ}Ÿ5Ëu÷ûRZöëMê9f§1YqÍxÍ!Ò~'PŞ»íÜæÄ‡ÚG°/òm”÷Ît,O›¶Ü£»°á€;ê~çÃ&kˆQÜ"ÉW^?oæ.JDÎZ”_ÚáæJãwCÍûK¯;töƒ>*„'1¥V•-cCŠ€JóŠ\I‰ŸÈ8 ÒÉE/âT#j’Èì lü°ênTWiùƒLÊÀ0ª¿¨À-6¬¸¢r?¼‹ùéƒv­L‘Daú
¶ğˆzÉ/õÚF+–
Í‘^ÿ[ş+´]î­6N¢İ•£¤¸Vù0.¡'+©ã,ÉÇíäÙ¶_hú=Â>­Á¦ëñÉµ-Èä w÷cVn=oògÁøé¯qW!P÷5O…½ÇD¬­!6†ıŞ¦âò¢î)ÎyRÆ[”qdU· dîOG Ü³·V5âÒĞ%œ™1×zTÙå,”øİèz­MÔÆ¥õÖ"]ĞŞ“IVdîï¸Ô“]óV¨Gæ){ ®«{ÛxˆCŸf$­ô'÷Ê“ï†±\§ãˆ¤ §;¹B“1¤áÊ÷ùn9Rë!€Qi kïVªÚlN˜÷ÆŞa;úš=ø6Mî#¥p7á•Ê³MK²‡’aŞéJÀN@ÊN@hhº?. ×‹‡0Õı_w©E¢f^¿œUR@_ˆê“ÜÜıS…A,D­2WUà0fÕQÍüh%Ö£ÌÖÉÌÕ‚)7û¾ñt?};àê/RĞ².“İ$±yHÎx!æHÉ£g-ƒ´á¼äªk‚@#¾CÌ!)vŞ¡¨&ÁKàc”$ZøÉôrku©ÙL³5´=5[¿Õ#”»K¾ãÓGVGŸ„÷uÅû6¼m¨ÁÄ' ²ÈÏ‚	O•éµáX¤9$eôXÍµ2‡i‡éº~’Z‹ÀÌeoÖÖ‚£.|û‚BáNÄ"F-A+°gZæÔ¦½¼ŒaZbØyŒ@7ùJ4m,azjPbµE38åC ˆ×µ“+ï<²§ÆĞªLüú/ù†²·_ëé;3¯pâù”î%ËiK¼©Aş"'ºïy·—B…­èç6ÚÜµ£ª?ãÄg¶^	î,3Cû>Æ¤–onIV†ñ-8aUX´[9@\ÖM7’UÙ$,:Ãmxm²ÙİÑÚÆƒiwk¨[áü®zJNË†{ÆO©µ:=aä'¼Î¶ÿ Vå‚ì	Ÿè³@)P‰˜6¸Ê«ßåóßŞUtõçñİ,0±æ¥e¹œ6pÏ±‰eÕI`L¸Lö¾*j9(\Ô
°Ãxãn<QX£œ%£êúvr{ùV¢nÁ2¾E_Š¾?<i,ó:±dbûë…RLÑnHÏ ³	¼Ü İ—ƒ´”&Ïü’¡Ú.æ¾©É…pYûhûUf#®·bn-)¹>Şğ‘ògÎH|D»g2µy ˆ!’›´c…ü¨ı¯è%¡_„Í2³¿QÃF¥‚òévMÎ}ßæxZL_ˆy©É,¸ÈÅHØ:17(zYŒ6ƒ³È´¾ÔéÕ 9R`‘ãwñà-¨) hi<k‘k†gjDsÆ“~ŸYÓ;¥_cuI;X¾ÎµBù” tdĞ`mÎhqgb‘İ1uKp0ËN
’êçÒúlËK>N§[åá‹Â€«Ä7äğŒôÆJÈY´féĞŸˆ| ³?3‰tæÖ.)qÂän"4Ucæ
¿ÉÇê<CózÊË¥º/öá$¿‹iT =iXÁvö¯U|÷x4`•=±.Ów‹mõïíæ¸p;à/o»ïÇè‚Ñ’«°¦±ÊÖWs-Éªñ+ZÅqŸxî(Ë¾i\f.®p÷¿×A–êøqú€sM‘°Î©	Klïh‰­ëH¿Ÿ‰˜AI{â•3¡3&(ñ»J)>²úÏ4ç¡æÁ‹a=ÌEİê;—ø†qBg–üe®WnX9€ì×]®+íkÏ•&èœMüiÅUö÷fóvÎJ(ã|9§>Z}RÅ÷ö“8Sh.âäŞ©cíÂèoMŠœºXàCfæ«QÖVû|ïEŸ÷Ò¤›Ó5Ú;ƒWºA|ÓÛö\A¹é|ùËòÕùÌ÷¨`XtšÙ[iÑyÉ–ã]M×cj2jjÓGŠOÍ"ª„²SKÜHÕ¡z4úïÂ„Œ¸Bùt`Y•ùÏ=‘W]©GŞãà~  Š£qÔs¨ù]QLÍ¯Ú3y9ùÛmR”± $JL¾›-OV±.d¦Uô€C2Ÿj‘
+FñK÷¦ĞL–0Q	™_f<B…Â>Ò>¦Ó§¶dÓŠd³5ùË2y9”j…´Oês±5‰Z”¢óãúj‡â³í™3À›#™›‰å™Â’››ï]y¥^ÚÕ)=H,Ğz'|HÛÄí9»Â ÀA­OáÛˆ(Oˆ‰.3´#T¯«–vc…Ñ‚²ŸÈ~éÍ¹ş^ØÉVpË§.R?ÈLÖr¥Ø‚¨üŞ}G·h2…æ¥P´ÅmßînˆF%Şù$DS‹’Šp²A'7`TÀ€wzcÈÉ4:t]K·	¡Ù<á^“è×SH¾ií4 º5	9¶.}PüÚ¸¡–‰W°EiFı©‰ú:\›®`ƒ-,piÄ‹G{F‡Õ8qø¦‹Ÿ^[*¤¥0ÁÏE•E*axÁzÂ†“‚|I2–†˜­öÊjÃ6´Ñiâè)‘/*’t‰¢ô­^BRè ä5B®äš^Wrg ±²©rÜa&ÅŸ^¿JØ¯n‰^íà:ÄK£ï0: «“*¢ã$–P;ûFLÀmwÊc[àJ,z5zÇ>¤–,?Oåm.Å³ñ_dZÉ·V3Är•‰ÛMvÎHüaĞ»3”›€XÙ½ã'İé4­19«µÉô0Œ’±6b¡òHªq÷‰´¯¯RœÜ‘FÚ: ”¿¤ğA1­¼‘fNQw#–v˜eüŞÖ×‘sénMtĞVrV7>·Zk*²¸6ï¼CTÃTxğæYô£‚–i .0cwÂŞm0ş•çï}º¦÷ğ=Y“„èÒ;şôŸí©fÈË²6(ÙÑà…×sĞQ…ZVô~¼|†Şiqc·ÊÄ³C cH9´¢Eƒxú}vÀ‘2Ü^ ½^¥ì(PU0<4ÉA!hFôï‹\låCîô#v¼º*G8bİšwÇô¸+C·šˆ+ïfáüHI
eòsCXóöc1um4ü`y–aÂø•3C4‡…ÑÉ4wîqq¦Œ¥»E5œ±]&0¯ ìdJa;ÏÙ
|º˜ZQ5ÖÔœ$¥+:åÆ]~&–ê}ÒZ1{µRêíøÍÆ•›õ‡*ô‚Æ„šıjÇLÛÃAè1…›/–ÂL½áeuc[›¼×ä¾‚F6Paãxp)o/Gè_à*PŠk©PŸÎm,3ÈÛş®×¾eÿá-ò7Ñ¾*ä0»hÁR=êù“ö‡ŠÅëzliÅ›ĞVˆ¯øz} Q–+ƒYX*	©è4fˆéÅV…‡³µ2ê°*ıS{2 LÒCYA“ğÎ?OÛİX!qíuÁ6±ĞÚ±¦ BZ¹E9lÃ…Œ­¸\N™İñÀÚÍY‚7#€¶KÊ€f÷Æ¾Q•u¼Ø˜À
‰ÛŠÕÚ]I4İï[¯zİætÎŸwNi]B³bÕÏ¬Ğì…hT³Tæ‚ö‚dÕ©*‹ë-sªàŒììÃÿÔ¹U6)QCrm†8Â×:|‰l|‹”?~k¸=í&sQØ«@‚sJˆ Ğ÷™x C„&Ğoå3=XÌ´®šxulú ~ !Úß¬)&¦µf&µ“ÉŸdw 74GZY’_’‡¶…Ÿä×ÈÄ¿Gjè†°e
ÖŠÕ´§±º,m†1Rˆ·×¨Ã´ˆ`ša%jıü ˜[‡\dò½Ÿ»´;+>Ã³İc­”Ùî0N?]ã‘ñ¤t‚¶j»°ø¬IUÕR¦7rŠÂ‹ıûéõ©c¸6J.„5eœ¦¢Jó¥–í®<gÆŠ
w2©cf÷_è>Ù “Ò¼œÊ©3ŒèŞO'{tz^èİ‘$=z5À\èlXÆ7ôâ´Ş8YAA†ÅÊRGÿU)s®}4Á÷$HüN‡
1Â€†ºxw\–×Ñ@b€Ô¦ê£æ_Û(.+9_¯¬:®¤8àù²¤ÚÒw½ÜÒ¢Üıwé¡ºd.d¿$x.¢™”‡ê¯32Ç°b	ã4G÷ì@°x^"|…©Ö£*Æ"Å×¦âV$¦ãkÌ®=MÄ¿O¾6¹â‘Z ß Dö›±®§GºVm¿(4h´½å^­ä]{¶—„Ha0èôûéœqÊµG›ş5ymìlvPÉš~,mfÅı>tyiyãX¹€8õÓÿëSø½›B£Ëì2XŠ$5qd·Dn¤9VLñ&F^•"u$LÊOnkI?;!q®”˜ÚDH@Åá±´äe±ô3Ø,Ç—{€çÓ_íºÛöš¿ĞR]’³zÚ	f¯G‹‚.j}ãşZŠ²¬³]UVÒıxtÒßIäqFŞül9S¬şÅÚŞn ©0U$-lÄ‚Q‚ŸËúF'¼î4”ÅûyÂpd».‰iÕM4ˆ×Ÿø¾ê—“?%>ò¸¯)¦äYçz³¬—.,FTÃ}£`UĞˆ-Á½<R¹¬Yr*çñ:Âc@Ú‹ßå7ÆAKäísk¶ëô¼ª¾Óƒ¨01ÎkÇçm	¨ŞÙûûW£W¼Á6*K¬½	J½„äÔs²«-k”DËÚ0ÏP¸eŞÔ§Õe6X+[ã›.ühÔ!£×ò:ê`µ'‚vx•Æ&ĞAv¡¨DÛÂæYà=¯ #¥¡âàŠt8Ğ²(çô„£QëİŠ9Ä¥Y¤P@Gnqà)´HÄWKÚÙÇ?ÚZûğÕ¯|ˆ•”ëiır™éÅÁdçòIp(ZĞµ*+RÔ7xd¤rì­¡vï×=9â1¡Ø×Ë3=Suüù=Ó›@¶a_:ºúë1èUaJş úku˜}*S¿Ùd¸ªÃ—(â<8îı	'5u:1Á‘H!íÑ{¬HÄ{vÉßA×œBÂbUmş,÷Qš±EQ+Ÿ‹|Cö¶$È€9†áÔhG.·2µEV×³XÿâÔÕ¼fEkQéKW×	±Ø¨_­fĞê*%y=—éuE¿Íï×$h,QŒZN†Cû‡½ü=ùnÂE-‡ÚÊÖe”^8[zÚa|CcAw–š@­F¦vÓ}Lñ€±±ÓË)”#yfÒı´S‡gA~-Ã¹“ˆ#«†Î†&²ó`B——dWÉ0øSòşg¡U¬}£8i—;qåH"dØ`öaÕzñc›¬äÎŞ,aÌÕä5gY“šàbÔ_Ø£~DH0V$ëÀ˜Æ¤œ<'Ğøt†y£İt‚¤€ïÕ½MG$yŞópí˜y"ïZ¹ùë•„—'óœ@¸®Ğ«ê%{5RA†Bu%c„ÍGÆsü:´ª¶ö!°Á¬Û¢ £iOm!|qÓ¸Å€
‹f›†c¿xn,9æ|zrË-FfŸEx(êmr×,®/“HwÙafë„-]éâäô™ü1¸Ç’àE;3¦zgt§õÀh„N2ocA=ÈèDöµw­ˆ‘§:…M [ÒÓfÓé)õh|$
¦Ï%ì©“mİ&*jõ08şUŒ¸ŸD&Á]ØòÃ¡ p	¹G¯µ²^«
˜«Â4ÑB‹ÅJ×‡Gë<y6è™sÂs(Éô8Ãh:çìóÉw‡r»Å…ÔY±AéÎ-ï,»¹¢îÃ”zaÓª‹õ—{“aR7†q ?»ìz¾4ÆÛdªØjøÜ{ÿ¯ºCRm}”Š}T®öòÕüC‰Fõ ÒIğf‚cíÛt	ºı‡äàëb™¬ªB’kn'zP:Q•Li÷0vİíÚj y
pf¢
mcªŸÒé6úv‘µÒ/ë«÷—Ä GSÌáÍÑO]ÉtWFİ)é¸Ë×_¡j9ˆ›><ğFO'>+ó¤¶20”êe%I¤p—¼›Ø`ÍEü‹]&•Ó+ºwˆ5 §„ñQ%©±ó»·Ÿ½;®?öó°A¥xzÚoÜiêè|ør*¿‡¥¦nñçuF]3)6ƒòRPê·Fø½Z*gè£ÔL7´¤]a»xa÷[_y«„4)å¨hÙwĞwz=]ë×ù¾Ÿ‡Ìã™LÀÊ’ŠA{î€K,fıüm»ë–Äš˜:	µ„ÉBbZ¥ˆ© ÙåÁéXÄpŸÀ§`«ƒ1TGärIæf!÷3¸?J/{şı1q-my	ªÃq_øÁ2_jr¢Ì¢Âå7¢Z@³õ±Ó$oæjxNÅ¸ñ»h|`BÀÇÔ%ÒWx`9H„ç9ò4_=ayÑÄ?ö5õÆê×¢lª—¡ò¦˜ d»Í¿³.‚:æìøÁBÂÂaëŸ'ƒ ¶3®'Åô8 xœ"êJÃ*÷JV{j×øCT9§iaYÚ¦TßŒ×5__‡
'Kp)a|Ø;èü^¡yXN£jøh P€ûl2Ù>Ê¹&ë„¹–ğÚ[6{NÛœrgm›Í¿Êzp¦wğèyq¥Ö	÷FfI¼Øß=Zèë»‘«ªß¯
z46¡ÿ½Q¼û¾\«ÔÌÄ+' Î–¯C2>mùB“ØS€¤—1®àôò¨w£‚:ñq”‘±×VÃ¡eôLâ—wV[E“ÌØ]ú JgÕ÷ÊEË[EÉE4’/hÙg_ÊÏ5{ûÔ„¿¶V ÉúÒhX<‡,^¹%LZ`¿ÜÏY¹4€\ÔrĞú¶ÜtAŒ
´9×ä’XXYÂN’Gº	4ÂàZ˜£K‚¶Z8‰e:Ÿ	:Ô(É_^ëAF#+î¨Å–yÿ'Ánıæä¯s¡Ñùa_<èã’ƒ@@âv§OˆõÜw
|=ò¸½7É %ß#[Yá&–yÚ“ÚÍı¡Æõÿi3	~BA¾p?BÁàüÿ}Uı›vz^q?Ş¼N6Ó£T&ÍtU¿[6ÔÁØ€-JRßjü Ñ.¿ŞNĞÔçzÛ:y ıÚşÑ±tÁXTÏÓ‚Şá“&Ş`ª»¿;¯VxÅMºĞfo—é¨9y°ù©Õ¼"º/¹ª"pfçl}ÑYõÇøûws?L`FnÌMF.vì:yœa;4A0³u^yÙxîz –£æj¬nŠè¾Ô	ˆW®NÆ¸İÎâw‘Á
­d 
Pû?|¥ƒ~ÖÒubä†Ø âì—ÒMéK »,ØÙ'_hr¤©¦&ûóhŸ€–ÕÓ:ÌGlÈÛSHÆ	o®·Lâlí
'œÏ8¼	øñƒâ2½ƒ'	gÿÒíB£PIf¸ÑOaËÖ­}¢’j_¦¡êR
bõÕWÄC²ÁL½õqª»Áqß‰6v•êªn£Ç¬ß©œ×cG¦°Ïõ”ü-Ëô[¢o"’“G<•mo¤óğ{ÀJ>ÛÍxÑíî_ÊkZ,„@ÚÚ~ÅòŞ’EìÙÓE—{ÖDF¶Y	¶7ñ­Œ.ë%-=„atüó!ƒôÃüœiD$™z)|ğ-›h´/(Ë2 \dĞ„x§İ-ò(İ˜äân	TL0eĞÇªUÖ¹õQËN$/T´<Ò¥¸šË\ï©g)Dm»£f1^ãkÚ¶Gş`ócàêŸ`}ÕB$bšaãtSáBú5J¾çîp‘îæ[—!ÿkw‹_[J|ÛÌ¯˜›3Ò-l34İÃÙ.
e_Ùğ\)%€~Y÷4OÚa»ß`¾	'oÇV—îş3¢8é;W‚ñ b$4naë.k¹«ŞH é¤e¤(-, ‘ tºgChÖæª¡ˆ3VbtwÌÊüÏ=t§ûGû£;ôS‚Œ’j™€Ì—fÛµånBôNLÙÇ)9ıVÜRu‚sŒ1	Ky6NXö9>%µYDê=>n™Yºª’µg¤\åŞœÒT`c£¾
ÛIkÕÅå-ru´w‡ô$0C]—½fDŸmX Vêè-€1 Ls7WÒşæùü¢û‘ø¶-ÙÕ]£œCT¢Ÿ2éÅÄ¾™– ‹;”êgÌÊY*©0WÀ	ó\ølŞèo²SÛny›»€ÈÄö}#D‰í¦Çì}Ş‘:%‚Á˜"2VÃéM,‹òÑ;À.cEu³ÖwI(*ŒšBhé @mÈå®ê–=’áªd« WÿC)qúÅQeç¿KÍk¬Ş!€f½*~‡¦VPQ¦= sçÈ]«.oPp%Î…€˜>å¶! ¸Õü(OS›
ÎİX%u<¤?{H„ö;¦æ¢¥|ú3î@VÏ§´†Ğ¹Idğ(Ô«~q–™×«QW” |Í¦e²vàº%¹Ë
Ê9·mÛƒÅ9³|ÎıÆô<¸?Ûùv½Çg`í¢m<t”_İ¥#vÀgbÇ77Ç–ØPo¿ªpÂŸ:ƒ½Üø…w©ıß Jãë-+aH«ÚßÏ\£d“§÷çW†Ô”V²‚‹Ü|"­Èh"‘˜·‚†úw’y-Â¶î0ÎZ3öâo7Ø!…Óz¹¶bÔ§bİ~ãFDŸIËóş5vÃâJÑ²({~({²—Æ5Êè| o¿W2À’¬ş3)çä%Ö*œ¡µ‘_6­Ì½‰„ P>ú±.~MBÒÖ¸3èÔ¾+DšDgµ"M†İkÊ¾A³UÀ<‘ı©A²íÉ‹ÄÂÒ}hÛ]Öƒ~wxÇÄ¢GCÓŠî®LÚi
Q&RQn"‰~=^ßµˆyFZÚEiÒvŸ¹0ô{Ö~F=M‰ÚòIèvª7éÕ«º1”Dc‚ËM_úÑF`QÚNüb$—BÎ-_„kÆLllÌõ+ŞöùDÖÏïÏª®æéú›Õ—~áÑ€’bûfü˜ÄÕ©˜ìZÁÒzoèÜÛ)¨fâZd-ü&‰¢Ïøc	KñCæ~tÃ¼—Ôü_ÿp·<ğ¨BÌJMÖF8.F"ˆéAÎAlGëUbùƒ=–®şÄ9X¡Qç¾''çA&Ó{§tóšx©´àáZBw•9İäê°ek¨rtf‡¿9Ç%„¬ˆÃ—Œï<¿Û+åoğVäHµy^€š:åì«´dÒÀ ]Ö¥]¼ÙÚ£Ó~ ­IÀ˜>íÔ64[a——Ù,†§È™[C†ın-G¹BT)'vĞ†–Ëı
’¸àJşf)€,”gm‡Ï¹í‚°³«»)c+ÑvÎº^è!Cº!Ê"áù»=J±ÊïØO€4£¼–Ê}µQçúpµvUâQßñ÷2¾¿¢¦îµ*ÂCcÇc??Çm8nÇ}1Êt€k”œÛ«rÅ°ìJ›D³¹ƒ6òÆªa·¨ÿ9Í£³â¦¥DŸÜ|JvÇ.Û,4.éĞ‹U«È¹¬½vx¿øø¾?ôaWšzÒÄ1¯QÈl+†¦[â¹vetiÁï®ååWë|8M)s@RóÑÇš©¶¤Œ'uåûRCß·€şm€Ÿ—os³©)pÍK9¡ç~‡Q»dè£ˆ˜loV¸îÊĞÙß¯–G‚ÓTˆJ—„G'ÜAk-kwÃ}rÕ&,Î²{_¨ÿkO©\fÊ
§Ïúı®ãi’‡×™ê¹³ŞEÓ‘,)é.‚×Ë ş¸ğã07©Œ©Ÿ:ôïtåÑe6FUx;"••g'_*Ú¤Xr×Ã©gúõ'õ`ØVåòe†÷T2·_¸ºÄÇÈ±øÛ¢ôËpâ«^JİÂÃ]Ì|†+Ÿ[‡o“Å6„jxçø_œœß‚\Ãò¿t‚OŒš2šdU¼g˜Œ…‚·ƒg×ŒiÏ¤@1(D!8û˜ë+@­½ñ×3x~û.èÉˆ¢=¾µÆ¼™„\PU Í·.uın{©³êyja™¦
961Á®‰µhæşLl?óñ
êÍáB­ª#È{¿%z-X¿?³ Ø›gp¤^Œ}l>WÈN\ÜfîmÇsìƒ+GË€ãT”­°^ŞıınH+²EKŞä-Kïäwí<¹½şR	­GÕÁÕ4ôOÇfÈa™öo‹|øtÁº&`ä–Ê“ÓÖút$<©|ì÷~œ
…J9Ämt–ı>ß¸ŞºÖÜŠéRñ2]}…µ„'İzîg•{Şok	U-¨œV ÄB0á1š‹t¾ 0Q 6Z'|—İ‡a,	Ì¨¤šaî<†7U½¹šå¼O–Ù’ÂS°\X¨£4·?iyW4ër˜rP^æÄŸÉ¨úÅGB%«Èm.-Óï´³Rûk$¥¯©²ãÌ-':r.%ˆ~¿©Ğ$¿ïZ_d0ş`Öã¯èt}È t>{ö"£lrƒ¯[„q'—ZJ¶G©@Üs'äOïíşæQA3Ş¾AQÁó§BpKê“:Ñƒ­AN×35¤öÊ#z‘Ô³”ãÁxbéÇæê…MÕ\Ù›ª¥¹£ Á¦B=ØŸtNåB®Ù“•è!¤6ß5—ÌiÀ3›òÛŞ9ßdë(ëd!´¨?Ÿ3Ç¢™º8–¹¾=ş{Â`éòšæ‘ÅÉëQË›œ}ÁMb¾—İœø•}Aƒ»ÁDĞê¤Â(¹%º¸¹”C”eh1UÔ€ª—aåg³$Æ…‡'©ıùë‰	.’ôç:½)“¦[%‹‡ —ÉX>ª°˜rŒk	˜ãá2iÊ&!ƒ¸U½+"5gİÀ’$‰IÈ› .®:€&Ùïı)vÎ¸…Àb0³×†ö"N/Nˆ÷[bŸ7	KÀ#Ù0Ø¼Çá$â–üØ‚
´7€2ìX?7üúZ/cu¾oDd=Øÿørër ¥ŸãK¶˜°áx»5æÊ8Æn»wW¥à”Å_„dÌ”Dò_¡y».ôív¨ùµ)blåØ!}­¸ÃŞ5HŸ?ÉI
ô,ØŞŸEƒuÜÂ61îûò'¿«eZ¾(óİW¹Ò]ù*tll™(ï<|läaqèã™½ó!FŞ›IsşÜ÷)[ªğ@ö]Ñ›+MS®»7	>t³Ÿ¾™/OæKS­ºÍ62)¬ûğg¬P4Y½ÿdÄy½uVZuIÀßî}´?èŞJ×´v¢ã? ùvoÖBËŸ¶û)Û`¸;X­Õ)¥ oJœ†¤£âNa¥P+ß}Y êõ}eö5š«YWƒàkíø¿Î#}nCã¨ûôæ0ë¢ÖÙè.ÅöVÅƒ~ŸÕOZàõÓO$Gå×˜÷‚”F>ütĞ±:'ÔòÃˆ´)}úñŠÖQ°>Ñ3â

šNF–<×y¥„àÿÁÍƒ°=í¤PîÒËÅÁçFİÚŒHÙgÔàôôÙúsüÉÑàsƒX»”›£¶##cºdxdÆ–«'!(¡ ÒÎjzK+ÇËÑ
BJ¸Şõ¢ûiFÀZ°ñ¹3ğRzyfbY
nŸÊñI4‡PO'Ù?‘æ™9¾^{ÅÊº8õX58§+ZºKØˆì±ºÊÏõëL‰%Çİ±Y€’Ùín‰
î3ñ• ]õa –‚³JÍğë7¡Tàd¶“VW†i6'°›H50Ãs—Y=|ÿ/È±ÉäFò Å(3xl!¼¥é]ê’Â›¯ê·jßa0 lØr‘ÏÑU–Nh0·ö¬Şå€@8$·¸±˜kú§øZ©˜ÿ•î¯qMtÂÓ™ëÊîxCÆ÷7äpÛ$ù²õ
²‹9áµ­.ˆHqÿIUÖI1æ ×¹'üäÛoP"½n‘°²{É6`(k ãôÆ›’Ñ6-%‡³<Ô^¹¼ö(Š·Eşv£H‹ ÌxŒöøÇV˜íƒÆA‰úÒ5Eâ4Mgı(ˆÛœ˜ïñƒ@äZ³@ğ0ÙöB.8#÷»6º)=HØ~*>èùêGÅóÉU‘®à¶©0¦ZòËiÆ“˜ÙŒıÈ}yä*ãB€Z&õD…À41Ô¡Å5ášùEñİ˜
h‡D%Xìc'Ğ–Z}ŞÏ1•ÙŒ}ÚÀ^¥Ü0‘ÎM<V½àF¸‹ÚQ©fL—ë•‹ög¥¢íi1ÔÎc¨Ú1w ñ1èa¡( 7ı–ÿ¸›K^P¬"ÜİóX…®]&…Æaut¿V *"šºï%W‰Œ>ì#I;êÙ›˜âQ;~T´f‹ÈÇ˜”!€ï…)ŸÓZp•¶îÎ­øt•Œˆ¬ ˜>Â à®\ú.I]b%2$@uÎ/$.ç£x4iÇB´õpÊUË×ºIy??0êV™% o¼Å¢§‚Şf²wí2è,?¯Î_ÌãŠ° Å6íÅ=ñ‹ö£Á6Äî1^@¤égM¤»û2`®09åtÇ•D¥˜	˜Ù›fM”,ÙÁtN]Ú²Š1á¥ˆlÃc!fé¬¦¹Ê¾Ñ%á"dÑI­|“´D’¹—7È£MÃSzœ3TÕ ³ğ´ÀÉšÍ¸*á1ˆP©égÙ>Ã„ò]8ÕVMå„¾8§=3~òHwÆZ€—ze”RG·3Ï³±@vx7y•S8¸{ni·i¢Ú}d¦qà/¿:xitíÓñ:Ñ'Á+ÄrÓôÇG²sÇ¢æNõè¹ÎäyÊLßc¿íO”´Œ"°XòRàRaLÕ:ü&î˜'IÉÂğ»âs$×²9„N£²AS¢ÏÙ$wÁ×ÜÑ
=p±ğõÖ¡ÄÛÅR`ƒÿJ%ÿ¼ »BÓ³X‹l¿e¦|\İşnßljÁ_ÀŠ³XI¨à…ÍIMòeÛ„x8rJAîVæï!`è…t¼Eo!1å²õ%¶gfa)«Ü€éíƒÍ”H9$?”óÕªä[æ¥DJRş¶«ƒ‚<±Eõ½…“‚¿åtşTÿt*¦VÄä„‡cB9Ö'7?loéél9'½Ç6k«@±dV	u.rë>ñqsÜ£•©ÅØO“·1Òf'Ãò·Mø­mN7™EÁ3Á"(<M•§Df´X•r¡¾-´ºë:Ee_UÄW–WoªíÚ2vŸ‚M¡á)(ÀPÙş3C,R½k>åò%ô0ÛòäòU+:~,ZìôC­´e€ÆsDÓ¶ÕãêŸ¡Fh³5õ²¼g%SÄ)ÑøûÇ½ÍGs‡Ãı¯¢˜­¶ª8Ã&«¯‡tËAƒ’/Š¸<F%²Ö7Àf¤L®~¡Ø«@ôÓö.ôFóè¢ª5-N/SÀ¤íåuœ˜İ“‘¨‰z	êùç&9rl#ëK¹EgîRecN_ÏQÖtÛË„Ÿ’…íuHš.3i~¼wGpí7^a}¤~ÿ”ÙçíÇ\®àûºíÙ®ØÅÆ‡MõhÆ*½a7Âé!k3Âõ{@ø!Eí¦îk® Ÿ÷çvÀiâË˜¯Cñ=!1^CöÊˆKU÷à`ˆ<g«Ä¿#~Š8Ø;»›ëˆ?xúj¤ÚËÿ‡Ú…'dí„ª.ÌÔÒô„dìjãÍ£:Îué¢B6ã7ïâ/#ñ 2©ôå3Ir<' Ñà4ñ@ÃìQ’ş„ÊdÖÒ¹îe,Ÿ‡›—Ó©q³ˆ9ë)£)uÄôòZhvB–¥1¬`#)¶ŠÄU%6ùaA•- ÀÁ:Ç½	ı ş e£8—‰˜]}—Ş­'ÛÊï¸êH¤LĞ.wY] m÷ªè-Ê™ÙÚ U¬RÅ­¯?¸-aMLTÃV±Š:*—~£ÀR×&Á˜;V¹ï[‡ù”©‰_Õ¿z#½ä/äuÎo{%©aÍVW¹éŒ¸(M8z8cÃ¢ïD”‘•EÀ|cÃV-şOîÎUÒâ—D`˜núë‰ç”;ÜJ=ê³¢Ç»lÍ8i"ÚëJfKòš0)¤–3¥6Àoş%„ÿ¼Óc¯Ş¬bN’P#BÊQ¾‰Ds©üí³ä|*T½ ÇÜœe[È/‹f?¾F@šã­®Æ:Ì&µyéæ’…àræÓåDNïíÚi\E°Tz›3$Õ\á
¢•%—ä¯Ëi·¨fzbV•È¦Œò_¨[¥Œ:‹÷Áõ¾‚·?¬I	×0ô´Ê¡®ÚKX€m·ƒi3Eq„Ùñ®ı³úål¢…ïœî!¶ÖÊ<}¼í™|0fZ™İe…ï€ôâ*™£Ù¢rX#Ñ±£ru®—×:_Ëœ¶«Â/w8r¿~ÃÙ¿Ku3ë°y9-È>¥¾µÀ\ĞÛïDÔ­Òv²€~¬CÙå*rEŠŠû)ª%¾ZÅà§&y…ô}ô©‹­¡ÚÊq/aµ‚x²WáûÓ7ÇŠæáÂ*€öí›ğ>‡.|7[WLÙ‹¶ãÎ™¦¦u6Ñ}Ÿ¢MGÒÎÄµæ¿–ƒtBfYLÜQ;!N¤EwÍÔ•ÍÕ¶˜ ÊØgÓÜäi_¢å´ãè±‡}E§”3É¼° •Ø¾á¦ÿºçq2¬¼fÉ¼Ã7|`Ÿñ	)-Ï8Æ<†Û|ˆAâ+;:„ÄÕRz¸bşêîåÃÛ-m®¨Øe»¾Ó¥¼K@TBÀ
TeM¬º`l‰Ì¤<tB›^˜5 XBš+HÄl–‚œÍ<èr=xù¹À~¥†]íDß”YòpKí^#ÚÂªÓ°S°‡ 62WKe²=İš³LË—Ë¢›Í ñˆZÀê9àxhñK$Z’“,.|ncèã†\°æ©~úõs#Æûºë¸d<E»=®öô>ÌİŒÈ´ÕåR|Ùı³ee1ÿÓ"õ„­oÓo¥/Ÿ‚ÆEØ!Û^_§'ÜÑ©€o‚™ÛæàwÔwJûf´æ_·…ıp€eÜÌÂı„c£‚ĞZƒ}õİ—ş¨%÷O^[L…¾¶È-ÿXU¡ş~Ìg™ø?Ïƒh}ÃÓˆ&}VacÊ³‚7Eœ[œdºÛ{Sñ‘rÛZ`®Q©oN	©PLfS/|@ÕíRCˆ(±*	d£‚ğÕ¢wüèï(°L#f´ş@šÄòÃ©Î¸DnÔ(¥>¸*ƒjåÂ|÷\ıhH×%Ë§urj×Ñ«R‹")Éã°éS04 txùİİ%æ6ºá¼îô]!X¾–ü&ğ¨EAı¯c,p¼.$oâ‰0‘§…If„ ¤Â«+ØL´‰¡q¤qé•í”œ
<TÂı¥@T¿ğî¥}•w§sv!jL_ºñ©€c†÷âF~°
§ÑyšoOÒz&ßÛ-i§ˆæĞ„V”¶³ÆÇøGÊ,üZlÌ[GêŠ=ó·‡S‹f$‡9ïŸ±™f0ZMs;ş3ÚôÈ¡ÌáŠkşïcvì‰||T_qF|85¤~Û¡ïÔU¹‘E3×¦ü¡;ÇtƒİàÌÊsÚ&mšSµ4K7ŸüT#RC(xïÀ(+ú†{© …3á;)ÏQ×píœå<,„E°à“—ÙÓÿó
ÔJ“ü^§;ï¾÷8şŠˆgV:e\ZbøïÛ…×Dä¾Ãåˆ‹×û.µÂ¯>«NÜèfîíMÛ°Š3ï›ØÏŸ[€qA—ˆf%È‡+ï‹Qğñiã£–¢Àœ~£ƒ~{Í¢FTDgÀ·%ô-­§‹cŞ=¿¢,Á)Â´×dñ7ä‹‡ú>[Ü¶g~!Â¼3ÁÃ¨°X¿x^å›I¤!6ÊØe3©BI¦Äo4ıñÀğ”]‡Üa%öÓßäV1Ã<%¡U7	=Ë	8Š|€qê~hnÕLBu«´"­P³zc³P9xı_/+³«û5Åsáá³'Úm ¥G7UO”VoBCÏÆç«NÒğ¼VŠøÒ­[°ùã¬½!G}$Ğ<["oğoÙğós±Ì¶Y¯$)Å—¶DFN K`Àµ !Ir‰êKê7\©ûÉœ¢fÕæş3¬…T–‰n™VçŸKÁ›$xÜe$„õ,OtËk!, W†“š’/‹Õ/ğÕà|l()›=gxÄB²Î CV\6E’—Á’R˜º ıˆ±)ã£s²± áâ¦î+×„*-²VşüÄìMîË¸Û.äïÁüDÊMu•µ ypˆw®{ã Õxà5®çÄ°`=å/+Œ$ş¾Š†fÂçÂc"7Èú2ü´L’Ò¶³¶v™ã¢%$©L©KÄá~‹NtñG@
e8.ù9â…9e€Ò}ç	E³›&TÕ)xÇ…ÖMúºünBÛ´¨İ?åmXâ´Qt0p£–ªÉNEFİWv8ºIşò¨T·ñv¯=na.?¨óê¤‡ÀFèß~\¤¬8ÎB;H…Ú¿¨~²Ì‚CjÃQ˜Œi6¡
Ìáï”%ÅÓ npmÓÚwÁx´’™«k)¶-å‡kı_(í‰‚Kh¤:şİ×ívÍŸ0æ°B(Îò„‹0Í™´¢ ‡Z]%o‚)§28­.Ü¡ÚÄ^ò'8³Èu.>…T•S‚â]4.ù¾´@$P§‡»Œºµ‘ñhí½XßT°Ê$ûâ–ÄîB-æÛª°luõ—f“òæ!AÓz³~«I¨>!Ân"n Á°§SûŞé@¼-®o±¤¨„ë‹2š¸J‡œ6i·u’ÃUNó~ê™ï‡$3×¬,©[tZñ…J4ñ5‹Ù_ÎO{L¶æ¹ªÅw£iŒÃwe+«Ö7MO‡ßêÊ3¦Ÿ`zºO9N8b“Ëuµv k»bÜ¶–N     ’«ío„K… ­Ç€ëœñ±Ägû    YZ