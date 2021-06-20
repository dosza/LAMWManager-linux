#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2926504036"
MD5="432d6d362f3e8b871529c983eaee3363"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22896"
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
	echo Date of packaging: Sun Jun 20 01:33:20 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿY-] ¼}•À1Dd]‡Á›PætİDñr÷o-a˜V²˜LÓÆÑ‰Z¼‚òBôİ<,'yQb«è¢œºÉ÷T8°aÏœ¬lkOV–,õV4Bı2sİPgR}ŸëÓs‚]wá©éß	ƒ&˜ÉúG®ÜÏ®v\†äÏãgÃ¬•ZÇúc°¡ëÆBDı5+Ì ÂDE/S´ßŸô0JFtÖö¹Õ–>Ô|Yõç)yrÃ ëìüµáÖÈñ<Ş»½b¡Ø7¡¡fìËœ·¯«Â„Cr†{şÎXhËb¨6jsğŞ3\V`(u„É”'µ}Œ¢òXòøõâ³Á4LA¶G¾ÂST")Àıº¬ùXùäjÑØ§Ú¦aÂ .éÒ(8¨°|´ƒ‚Ó¬ºşnÈ…TZ
…wÀGù¸DÉV4„`ã»ß¹à“qjd~£]5bÇ­°&°EåÚ½1ÏT*™L¦ÄŒ.|Q‚Z™À/s¬OÌ¢@„Wöò=»ı-'àÕ¼¶N¼“—V#(J²œW©Bç7Ët›ıÊU9'¢g£×óº+9ïöß›&¦Á±ÀÜ9‰öÀ@÷“·é™µòğy&¿Ş)§úX%&¿µT’äN;¥ú_ğÜi³q['±½a9ƒ^b4¼MKÌW_ıSÊÈüOÅö³a,µx›­íd'´(Õğæ uäá&‰Jæj†l¢L&d$W…ÓÌ_
Öu{€Âï#9!äqôiì®ÙR5Ú€¦ójö!Ûi#Æñ®p7|÷ÈH¨è	tÅÅ`ëî)ÛG\FÄñ ‘ƒH·\g52T÷dT—kùt1ér´Şué{š¸µ\˜~%'¾¿íÑ«,‹0Á°¶‹]ı†»ô¼z*ŠšL»êà_åJ‰ÛÆ+ufç9ÎÿM–@Û,oº	0™ w#»n­tşú}¥KıƒõœVÈQ§“o€eN%kßì#8*J
>¸,"“şÌoí.äÃH?¥©ùd¹Kö›#ªhù,sÁ“ÓÈ¾dâ±ó‚ü-`O-‹\;sß)Z×!&ß« 3º"úz¬¦½Y ÖçÀŒ¼´kõe>Ëh”õ<Àë ÎA5÷ qİ¡z„z#Êİöoõ¤j—MòËè$;C Ãñ`¼ñ€*4çNöË#†¸Äw §ÚB¦Á%Â·`ùæ¹Eh¥Pj(´ÅÌ«ôğfãğ*÷üSb¾/eÄNlC$_‰I_ßâî¸R[únG‘eÜ°=’¸}X[-4shøÉÈ"Œ&O)ë·¾.4x)*UòŒ,Y¦ ]{pûİ.^2<×ÀŒìÛ@æº?3>&å))šÇòà‚Ôì‘7&¨¼Iş'š ñ\À6eÿT>1F•óP)l'à×¼Ì)@ÈX+Ok•0ıÌ¬Q÷¶ z–U3vŞÑ3óG‹?íë)"‹BE•½|w9Vßà±ûÏFw(WĞJÅ?G€àj“€©Ò“°aõ&+PH®”ÙCÚ×`œf->ğ?Øš£W_i~ÖÕ=>2ª)o?ÜHFØËzîîAÀÕû'ÕşĞdÉmîºì–B¯`iœ¼/$ëı6UiZÎ=şi:Iø÷Äío:Ç¥hQ
 Soçñ©fÊô|] Ç›Ğ}¹ø:•Ã',+UÜñ*†Ë7YZÈÏsëÖdS•ÓCâ2CÕÕš2y¼0õÔ¤+<ôŸ¼îÎÜ}›'>Ş
ÔG@~ú½ïÍÚçÄÄ#İ)«£G8ÍE›í4OBä?tÑ2Æ	–…h>O2eíŸ9kÆn¼’Ê>IæGH¯dÒ?«sÅ<ÎAš[	öèşïªì*HĞ|/ò„	‹ë"‰XÓÆTšJxxEİ[r`™×fK!*œy– Fƒ°ƒ³›éâgC…À@ØèÏ9j¼€ pèöäÄï°?wXª³c‰K6ğA
B±¯‰¯XU‘M›Ç ¡VğÓWGÌŠ!I¸³½n¹TÒ¢´:·$7J¨öQ ·8'×¨ß!Ê¨‹È1Õ¨¢G¾ù<<–qüY4:BŒßÁkjÑÜt<xù':¥ô›g¨qOÀˆ¼î…†ZÑmmIŠìÿW<»ûì=xà¡ªzxÓ˜ù‚`(¾Ñªy î.Y§vÏ›5ƒÍ£øs>¥ŸûøT¿VœÚæuØ™Æ.	2Ş|e¬Ó
8!Jó`.—á'JğEÆvíô³ô–¨3ÖšGı¬Ê×0µı×Òb×£ÂfUÖ5ó G}Á&yÀ	
¡G’Š»óñwœ‘Ë±¤–8Öµ9Vä`â|ÊøÉãİÑÌÇ|³+:ø:³úVDæ™ñß(¦Ñ™³)N‡‹É+zJ—äœ¬/¸Reƒy±°c†Ñ’‘ß¦~·IT²
²İŞ‡%ôÀÁO¡Î9ì@{ÿ’_üW1ñJ¥Úe½ÁŞ¦ï*Ø½MÃYJù¡-³i3cGî¹‹?l—ócĞblãzîÓ±A5<{8ßı›Ûµ#.ôw¨~FQ‰®\Fö W&®êQl_.á¶:ùŠU’şóÀıü­Û„¶Ñe>¹`Ÿgâ’ø‚Qe]|+8#çs0}ËzO£p›É Jåƒe ZõùiD»2ÛñÒ”0"r¹6ˆÌ^Ø3Y„½³ïnP
ŒhQÚÚ«D÷&¦÷U’oÉ5}¥`é/6˜(zXêÁÇ¥E?î’Š¦õ-İŒÖ¤j:P"p`‹ŠÏ¥ñË˜^m÷õïïŒÜû&lºÍú$üi8apiõR;¿qşş+#aÕeöºó$9ŠkõÅK™‘f8ã›^2^ŸùåOIİs½Üú‘3My•Uş‚ÕèBşÍ^.:=fÏ†ÿ5¬¼“¥*´~<}ÍìÓÑğXàˆ°@Õ×ê“Ò!uf°gÅ^6ú­ü›İ6Ó	õå’­-*0u¸Å$}j	W½g{²ñiJï´‰":8°§0Ï”…âÛG?k¯ZŠC^¦ëÓrÀ”‘5b&>–üÎ8úC8ÍMÍég
§3P„œZİ¡ñÄ•l!Ùço•òN)üÊœ6wg7Møÿcú$^
ÜYòŠÀ[³—Ñˆî,m;‹ª€ÒRgLİæ!}›Ê4ç<y64n3}­
mnÌ¹pj‡’U„&\¥!†¶Û”à‡(tô=ÔÃÏéëñy #úœÿÓMßóOß÷ƒ<ãõy¾…ÖèEs¯¸‡@-×ÑC/ÅâıdUàrã^ÅÜ9§ÃJK°ÈB|L×åÜY?£¢¶HÕê„Vñ9Î…n ™etjæm‚&ı‹”ÿüA‚¼#WcGré¥ı­†-Ÿ{ÂHìè{½cc×©lSÅç.NèßÆ¬¨Ú”&»ÔØ°mYnßƒAıØK ŒØÊ¢û]Î=ãw±Ÿ®jÑXú"ÂyË íËæ{\AC“GjÌL‹©ó|ÿ¬|é‰È_¥(œ‘Ù±>pvQãyVWmÑk—{±úÓ#/úŠııaSPR¤£3óò3=KÆÔ?Õ"#ì3oAKÉj”vWQ§¼†R2)Ï“!ÉÖ•fdÂİäUÖpSjnPÌĞ—­](Xš,&(·xc†ï¸òp/v8k”[ãüÂÿ3~Ä>ÎÌ›ë…úeå1¤<£SÂ†>ÊBp¦[/€ÂióšÆ&Ç&ÙôÔã ®/9Í¬„|6¾F¾kQ°›4Ô(]ÁH»ü‹pTf&Q•Bl•–ğÆè¿f±Mó¾³ÍŸGşò73Ôß¤w÷ÎùÅ¿ë~´,·”\)àè°šÆ¡¢~ªGn°Rô¾¼ù# 88+øp´å˜vtf9æº3´æXùrzÓØ†şW/½îCzÚ¸ ˆµöê­ÌØY<XqO¾Õï6vá#¯V¥×³êåÜrn€ a°¸ĞR‰¾ŒÚxzoİ>,ìgÒÎ`Èdº D?’®£ƒÓÌÙÄZº<İ`ÈYH.£è¤&ám3‚yÓW{ÉíOH©'7OĞ@s)%ôój ,œ6LŠºMfxwnNAÎc@£ñ®]ds,Ø\í#ù£‘LòòÜC˜¬‚d@H1‡şÙÎT¹}~êRŞcÒ&æ‡’SPØA o=Ùƒh••ïÒV;Ñ^~nVi}k>‡Fşo&A­hYy= Ê8»›§áğÎÛÀqFä,œ®NŠi³vËm®zl“Qæ¾ùHÁ3À,)Ø–FÀ#³¿4xiÌÎ“ÅìÌÍìóÆEâ·o_.J*+‹á²Óh&ŞšN3Ò¹›±b¼[Åßqkl—ª4#Ü+ÄŞËÙ d.[ß8>ÿâ;üo@i²ÚÚ½½Ø’!š£½+pß{t4Ù`FŒœ^ÍGgF¢k¤¦«À\*„¶q›9y˜Cİøœ½#NØ•í¹¾İ(<÷·œ¹u€dÏ‘7•KŠ"gIYº¥È±ÂŠ}#‚¿Ë8~S!8W<#JºÑ!ÑOÇª‹BÌÁœÒéoÀğuVÖ+_D-Ûá‹zÄË¶ËGç&š’b&ş‡`5Ç4uüpT©SmêPj`¯œ”ş…wùÜ§àèå•†-*Tïš°tÈUga‡S}:Î¿@;âsœĞ7´VNøU=øÄÚ™K$s#n°šHïcæçJAÎD¨°…8%qÁfË	Ğ,¾…ˆòa )­İ‘ñD¤Hô†[_!ë½´Èwş‡<2ŒxYÑÀÒ%:ÄÂ”"}RôÆ?U¥ˆR:¾CW¿ß“q˜İc°¾_„ÖŠàèZtZ½Xj:õfÿ† Ñ¾Fóÿ"˜8ÉCî?N¬Ô#jåR›5®=,û¨#KLP5àd²ê¯ß-†·Ÿ©,ÈÕ–?qŠˆ¯/ıø@FvÑÇMâ1«'ç"ÒÚ^Ş +µÀ1'g^à ›éYHE“k€ü¹2uèNÙÌ%/ÍY‹	¬u,-¡ØW¯ª™ó³ÔoÓ"¬ÉÒàRşrwof¼/•¾Šƒs“)(£K$á½½ÉW/7tºÃg%hL'­`«š ŒŞéï¨&Qç'	÷Ãhšù¾>Š½Ì¼7&Õ-,Â‚Ğ÷Gñ€â,!ŠLŞòæºtÉ#ÒŠ­ûDÅgå‰¯%N+øÂ{WV6ùhÓ¡Àşö›Š«œ.Ò£.\8ıG˜éä&‡QÚ›B”÷³³«€ÉCS-…fÊÎ¡Qõ¹p¼£È‰@Š€}ŞÇrQ˜:Ú¿ı:Ğ«ŞŒC‹áú“ÄÃ¸N@…<ïï‚RS^ğ¡B2ØON¬ç¶útIû4ş‹‡ÜÀxáø‰,ß¸ìùÊVâ/ñ¤csÿ“bLXHl¾Qé· 6ìzœ®€,ßè³uäÅv]¿¤9*‡v»‚… ¡ûÔ:*EÙ
¦A¨Hf(‚ºÛ?'/†ëC¿ÿÜãÈK¦’2Ë4©†©kst}zø¿Z¸ÕøF8Ù½9 ¯Åš§Æ³şÀ÷SŞN²nšsh‘"kEÇcw’AÙ~^.%¶ë'áE…U'·¥iÔn=Vfnºß‡5£›cÂ^t¹itµ
!©˜º„Zn•zÿeÚé;ä!(b¶ªI_ÂJ=­#Xë`Ş¨-†p±9İö¸Ø¦+Ùw—#2¼#ŞY$±/í·˜Ÿ¾ï>N²ÿc&a‘¬ü2ìê©ØW33X¿J:‚ÔÏ-ß>;R­ê`.Q´&rVöykÀ?fe´ Éî…¤·ñÏ\Á ¶sgô‚W©°Iì«äIäÔp³QŠ¢³Êæ·ÒÓoo¸9u¬lRŠ)ùúŞã÷®\FßËMÏ.×+©ùè,h©h~b@¼û}ñSÓ.½É$ èç¢w3ã}’Ÿô(¶šù÷e·Ù\^€ñüq6µ¤€fó6I÷òÏ³0(-Qè
¬>wrÑºşÏFŠDğZ
ùÈkS`Pøóª7£gœ©ü­¡‡oìPĞtñ˜©|Œ9–ÉY‡6iÉ…Q;¥Æ-×¡5ŠwãEbœrEiè nq®æh®döØ:šëIywu`™ ıòp#“AfMØ†Ørh˜ƒ•<²9z;†K‡¿£e'ıâ‡œ·1ƒ(~ ŞÈ›¢%’äÄ"¯çCª.µÉùd¦5#a÷Åx#7¦9|©M-€bå‚÷ÎˆÂÇw_¯£yLxKñ„µ÷`%JÖâÈNê.Ö)cê‡€ÓšÅç+*“»gÚ.«‚î»ë@¾êvÏÅÎ¡8€–vAì5HOzõBãÎ-¨c¡M(µ~.Ù9ayT±“ˆ™R·JÑ™J}¹ønæ'¿$Úíò´ÑG"{¸±^Ğuß³Ïõ/QL>P%9Eùm§ncîùwU™rÜ¥:œáöÇßŸ’SWz8²‚naM?ËcM”^eàæAßeåfšs!Ç•VKHRrÊŒ•[7ùO©•'ÀäK9Rác»«§¶Üÿ@_>o¶Šæ4
YŒODX¹ÈplÛÜ‹xº¤GËbşİP¶G&ñ
¸Uëi°¥§İ„í<•¨VãÍcµ ÕFŒc	b³Ú)W†f™t€ğ+Wd¥8l8LæîqÕvËóµ&¦%û	+ì6‹·¢Ú©G¤7jëøÅˆ‰'A¨ø‚°"Ö —SÓ@.¶ím)W”JQûšçÀóíæŸ‚#œzîø?ĞöƒÈÆƒ±ÏNâïEšg€¯«î‡f\#Ú&4ú¸à°äğÇÎgÓå{l<şbÖº‰åAÔr°bN¹uæ°~ğ ^O…:ùß>W— ÛË¿0l64±ıTÌĞÈ,™Á~úyp°ÿH~³-Ñ„®~ÇËÇºÅZÊâWÈ P"yf\an\K/ÇÆäW%×<sÈ¼è@Ãà„_­}ÜOo¥Ìiî›Ø¼aàobEº™°à‰;ãÙÁƒG†¨|¡
e0P‚¹Ÿ*¾YŞµ„…^kMg’wöG7Vby/S¥¦"—Ê{|é‹7<jWöó[/¸Û¯D`bR™†š¼óñåùÎ4;Ä‹Ş¤ô/>¼gªÉ3@¹ó±ÁVÈ»:#Œ“z¬î0óN1gé`ª!ØĞÉLˆ"ÁæSÀüC¿áÅ >üB³`_é[7¼;`é3(¸ù}¶ê4Ì4cwÿ$ÀÄÌ7İw¾¨‹¾Ä¿šntú4ÆæŠ\G-Xeµ8ìq&ÃÌL†9»iyÓYT“4Ç5 r$Æ<;Ô_óÏŠºeE® ©Š,S”:Şd}·I.©'óâ„`%ğs¢iµæV¥â )ËA(Öã]ËU©Šy³Ië±%k/ò[<d'IUı*uÛ0Înà#å `í4‚Ø˜, 1³{›…w‡fĞ®  ÷QıPR.ÛÆèlFàÉhĞß‡â÷”€H×Ùg[2±¡öµàµ`X7œ¨rçÒ-××·KYh7ì7B§
I6ü»…~üb"-Òj„RDıŒB 5ËˆÇxZÚ¦v@ğkî
æHm´J6úİå¹Hëë‰S:¶ı¾ŠêKÅä€’”_Ks'¦½lÉ?bE¢sâ—ø˜v¼¾ªÏãşO"À¼‹²E›—6\÷}8wÆŞÆ­àb¨«¾NĞ
—qhf	ª.,FeÛËºç[W†¡Ú{Èy	É¿¦Ës–“]2Aû¥r"]E§¼'{ì—ã„(	YcÇ²+Ô8Çã[ë°ùë2‘–Şã’ìYÁÆ°öu×º'éñY–>EVRmÏ°ß;»¬ÎâÚL—„oãÓZ~lD‘zŒT@ÑsÎÌÂ>¸åÅ#1“Âª“ÔMö=¡8ÖyîmñæNßş ¸ˆd\¿÷kÇ[Øú¥@†ä2vrA¨V2PÙ^XÍ”¦=¾-JI†³ÙÛxª âaásYcr}ÈÑÜ³']…§±Mº¾§¦HÃoJù)RQR>ë(İt>i˜‚WkG2Îjl¬©ƒ]jò€Çÿ`Èà.œ.àB>˜Ï4™(p%ØÇı%+	2#åÉİ—êÊ>OkR›ËJˆ‚×Ó¤uÀ9¾Ğ‰¼x˜‰Rüw¾[ş½x.Ÿ(‘¤ŞL.	±¦ô¯#ı1Yay£·GEZš òJY€Í¤‹ÈÀ#‰'G.“Ó}ğ%Ò–‚óŞØÈãV—K7Å„ ê`gDmfœ»~‡<´)âÜC/FâËe;èö×"4ã‡½^ÄvJé¨§ÎNg¢@…ÙüK¼á–kÂîÑÌs¾:wÒ5ô#§Óà0€‹Raÿ[¤Ö¦lâN,…ó¯úBÎøõ $lí® ”ÿ%ûæ	|ŸËyŒÂÔÎêíâçl'ú ã
9àĞ,)å7øû&Ûv}†H€]"L@ª_´²Uçc ’¥£®QÁ Jï3SsÆÄ9Ü>˜#o„sEj6™¤Kª“Y7–2ì7¬¤¤~B«IÔÜtÃÂIf¯…caŠG£©ª±ùãĞÅyÕ¶á —•³à‚¶	Ù²íd×Ö¶#¸Àê>+Ş‹®#A.Û&1dü>\e°©¬:¢œ\×»®mTÉšşYÓF,ØÇí•–`EœJÏÏ…\]’ã…,tKWXåK&Xæ&œ\¥ìšH@»F:hK·ÎvœºÆôI™¨#<pb;ÀAÙ¬ZiútYVù^Şe<Ók[& òµôë­,9%Ìˆ-ÈÈÎ­‘/İà'êª Kwe ¥@öÕp‹/¢ãT¹\Ü’Š¥ÚÁÏ*û†¨ûß .°Ïj$ûXày ûR+¼Ómt&s›´o¹÷€‹ó*}±EsF‹ s]­[p—tÅ£ô9±¦°e^İ¼áPEï&,M“xrT,ŞÈÌúX†8	¢b2^UiG¦ËÃ<Ë  .¤¨E1ª(
uÓ¯&€pÜ&’u5¥Ezî¸_å£Fo)
ÊÛÌ³­ëùvK8K"±ÈàGyDiDcO¿¹ƒAúï· AÈ)?½qíş½}:ŞÁ¶\&ŸŒ¸©×mæ¤eÉ†ºÖÌP…¥¶Õxö§0µU4³N•dNà¾ë
“ñ’–§Â/uQ‰_W‹ûÓG+mN^)c8š¿)ÏZ%yšFQH‘y)RYùè¼çĞª÷Ş¦â 4<¨9¾œfevé‰ŞXÂŒ }¡»Gœ…ªÂ3çµ±´
pË2—õM`æ®.TÚBÅs	·üêm•Åº”ÏS™”Š¶Ì™15l{â~»WM¤İ‡Æ¹^2ü³v#ÍÆ‰MITî.k”¥.·äÎM¿ÅÊ˜ZÆs|?uF‘å²½uÅ©|öQ(îf1®ø)…°Ø¶§©º"‡2`®q×ˆBK!j/¡²V¹î—“¯‚ÇÌxfßøZÑ±–•Ïÿ'â ¨“À5Z}Î×­S}ıàœ!˜b!Fs³¹) ÇRwnÖ6K²Å¡}/Ğ’âşö¾8;Ï¾¯ÀJªL|™A\æ¨»±7O#À‡Û±ª£o{¿Ì³]graÏdkMV¸½¼ª¾†ñÆš‘šy<)àún»,‘"ª#•Áö=M_uÓÂjŒ0â¹OÑÏÌ›{gŒîÌ¶Å}ˆáDB|qªUÄNy…b^Ò¿2ÏÕÛ	^É7\¥ôe0¤-¡çÈg÷:ŒšU8œ	#?>zf¬ŠÉ!Õ),Å²WXúy]ª¤|`·v†‹ö$åõL¥ôÿ	²Ì€–9ef2: ½‚ú˜ÒüË˜Šî†áè®˜ÙìR­7ƒ’–Ü¼3mÙa
Ö€ä\[¾gÜ‹Ÿ¢c†áÏwz‹ú‚ /ò=94í–Š
ÓuJäNHíß³	Ñ†“çèF)2ÓÑv{è•ÀPZÿŠ1ıÌ…*FtH¹jqë‡ş"?eŠÀâõX¢GÖüãÖ@ºZqUoĞ‹»ı³GòîAwÌÚAhÓ1Â›¢
tz~¤ë^°•å¿¤¯Jü~r[ÎÔ«ÇL%§Cw0Mªi£M>©ŒGC'$CÌ<@#—bQU.©®y™é±èíÑòòK(^áø53ÜO!§û¯…©ïó³íò³Å£©î…#‘ñÉDyŸ8o·îmÎİş¹ô‘ÿ‚¤s^g(ú{°ıl5Péß@Ô›üãz«f™Õ¸Âfà­_âÒÎñ ÒŠÊ¢€¥´7Ó*÷†CêO‚9¿r¤±à}×‚g!Â
]åã2LÅ™™°À*p˜p1vz-¼¥.Š‘‹‘¿Kâb–;t‘èÎÍ,}º3?ç–@‡‚†ëƒ:Xıi¿[=*Û`
 F
÷ä¦tUˆ,äÉ^\â /MõåŠWaÒH­Ùù¸_££›ƒå2Üaİñ„ä¡ÂFãŠGŸ‹îŠÄSô‚L-İJWqŸš„ p?b¬H³?¥,Á)ªQãh–Foì$ÿLK(h› “6v«vå¸…&æJık“ºP* G717ëèğå$ë£ä'¨uC-%Á
?»‚-l€Rs|	iÔ«ªe¬¶>2Óql9p­ğêªÕó7{Í¯D˜áÈ«/Üp4ï×Ê´Š^ºH*>z=€;ŒŒ’H»DöApT¼ÿTïıœÃA‚+ƒ[¡®è)ù¾‹úJï'o™<È•ßÛÔAF -ôŠ©ËN‹gYØŠî¼­»Ø™·ö´,ù{üz&¹WâH±/‚»æS&ÿ¢–KcC„*Ñù˜kDÙ±œV)¹kXh±bMUÆ7h,Ïm¦°2¹€.‡3¨hÒgÙZM­Õ×Ÿ¢˜g2$5ŸªãâğSôú¬şLÆÓ¹ˆ­²Æ!Oíáe„‚9[é’¤ËŠÆzşÔˆ×íß¿·™>Ø–ñö˜JiÀ…ÎâœŸùPŞ7ÚO2k—ä'';ãk%(ÚÒ6Dn·Ò8á¸|œ.üü&L6_(””>+¢7ôÙ~èŠĞŸš­7ã±JÈºğƒaG}©6Ç=HmZ|×d“:”°RŸ}7ÎÆ	¹òÆÁjKU0ş¤ıb@¤‚ÇìSU;œdáp¢ÊÆ‡!‹¶6+„Nmú–çôåäĞ:[SÁƒ˜X>Ä4tn,¾‡¤šì“ÌûJNİ¦QÀj¹†ÓağØ––s½po‚KâÍÓíáÓ ĞBFGş|&%’Õ.9ƒÆ|‘"zåçXÀ¬Ô}¶¼ãÇÇÍÄ¤¹aKìw¹5Ğˆˆ¸åi5º„üë±EÖ
ƒ½¤r‰Õó÷ídØé>…+]™_íşù~©²âøÃËaBñÃj‚ÆãÖ¡/[ĞÆaÀ&±È¸íÅÔ{¼hHPåÙ¥Â`Åèü‘í§X™T	z›Y#D#âó#Œ‚g,··ğÌä<>Ã`¨¿ù¾GwÖ–—­G?=•&í¢Äâg“¿š—î“øŞO•åy2íñÅ×ªÚÿá”[/²M¿½ÏD¬Êò¶®a8¨6İßŸû’^fù¥“h-å æQ…s(ó Õ2šìâ<Æû“í•~à™³úh›¸õrˆ­û
6‘õï\!m³@#7!-Ø¨¨æ=ôğ)r=©ò’ƒ,†¹ Éw¼&xÇWñ®¨ğ¨¾4šÍåùVÚ;¤¶áà”|g¡Èz¥e¡6‡3,2œ!Ú¡V<ıCn“>½â,“ù•*Ú#×ïÕ¹AxâJ³-Ç§¦ÉëÎu
÷|Ÿ~4şvË'$’!‰0`ö¿u™Fà|ìaÅj>ğu$•j{c¾ôàÃJæ;İrc» º¡J)¡ÀÌ¯Rª:óí ªn…Ø½`±¹Yjªä¥dªOŠàÉ´|ášrË¥¹BÀ¼<w†$¹¤dB‹6ê7‹B`µ0ó¿ì\~F,£ùï±ƒáÍç²bM†A­'¾¬¥Õ&&`"[¨JËwógºfA’IéUt1E¨ZÎ=‰¦j±3Uü»K¹÷š&^NEBâæ(ÒöŠêî&TO«ÎÊ}Ì³Ãû{H-²ˆàöº˜Ç¾h»P4§Lõ‹{ë¼ —v­»MÃ2J¼Cœ&ÚìvIl7d2æŒ1qy(±ûâ1”>r©`íPkf²½ïUÅå…iÀór\t"ŞNãxÄÒ,éa‚·4ªBNu¾Ğ×şºÌ`t±æ8ÜÑ˜‰õßºWQqıAS¹-siAÙ¾MöÑ{vT:¤Œš&±[Ìw;ÿ5—º¿ì¶Lµ5aF×L«áUÇ7b@¶[} dUb çá…>+ßÿ·„ÚOô¥]‹chÁàÊ¸&!æPÿÊÙ` ê…ÌÆS…&‘Ú5”ZĞQ –Ìê&çÎ#LJ÷»rdÛŠ3W˜·Pş©ä #ÅŠ1iÊ†Ò'0Z†s,fÜ ’ğ"…:¥ƒ²ú`ñ_Í’RÆNÇ‚d]0ş*”pÄ“¡ä«¬‚cü÷1ïóa?Ğ!ÿ%æCÃ¬Ø	§TÙ/>3k>BXcÏ/JßB/Œ•jã+šÌ2¸¢=©Ä#ˆ“_~Ãí9Æšİ¸±z²Ã^Ìg¬y¾İ—Â´?ô.ğÈàÖXÁPjƒ±-ƒ4'[Vg|ÇEÚ¨r€2Xóà…¹¤HÆ¯ Š¤ÿßìH’r¾(ÚèúJú×y>Lú{/“„€Gõ_tŒ¶KĞ&yä‚¾‡i]xJÁÌ\òğE¨$a~õ*çÎîiÖ/Ö«yV‰8Ç¨ß4§ØÓÇ¿x÷ÅÅFÖ=):	ß¥Jaá'¹GêL'V¼uùÆF¨ÅĞªŒÏıd#	9ˆşˆŠ!-eÅ0g@ÿ>©—¦¥ïèº'i•h¤ˆÌZª¹oãOã\]“ŸƒÉùíeé£†€dÿÉ´J[kz‘,áˆwlªGÏõwœxqZüã~³5¾nšİLlõn¢TÚ08‘Ú4²©ÿ²îW¶r•Ø§‚_î ÅÉ@˜ÿÚx´‰&¤U¿§èÜ¢õ¤E5äö;38ëX,+_|4ªY¡¹+¯éÈ'kVqK¿U¦S’·z*C)^7ìÙ›™U™M` mÚ¿åÔ*Ñ>‚k¤÷›…ıw\"€‡ˆf+¯#¬QKl¢®Éµm²gÇ<nâ9®Xdq†íç5g¨¥§ ¸øÙ—gRüAq¬f‚LS©İÃ-‚i•€‚;î3”k2;ùÅKÅ]Æİ2~ú%$Í:¯Ìæeµ“Î­¦û‹ı¾ÄÊN°£$>‘{5ÕÈÉq*‰k°­ım6›ìı:õ'¸ÅÕNŒ; ŠAUÃ: UĞs&ğ ´0Ø í1]uë1TÜëï
[èÒ…'„q8aIÅîf‰õÌæ7àÊ’#@OI{V5ß%óJ«xùÏRÀÆlR5D+ãğ93 Z	8æ!#ğ‘ø(z­¯Šs8*-r3@î[ÑOŒ£ëw8yäÓMišÒ ±’èX½†/x€ç;‚;ÚQÅ/p: —Â'>>Õy2röaöqn¿NŸ]|!ó>PQ¡7 zõší»²¸x«š1(ÚuÚÎ»ğXIx#øÚ‰3¶ÂöÅáõŒÒûÈÖrà™@÷BÕG¥Æ>ïL2…¡âÓÒı%…,£\ÿv“¾üªºs(‰îåò¤ù—¶{€7Ñ~MèÅåê%Ö·v9úP:şA9Û—}"Ié¤”J,b%ÎYŒMznvFÇçJ·ÙyĞ¶`QBöÛ£Ó<óHägÊ:-Y\mExN¼ü^Nã¨^xaô…²Ÿ£Î³ à§ <šÁÄ\–JòIh6Ç!MÎ^ˆe	ÜécÕ¹€ØC3XùòWÚº"Ã>…8*Î	‰şn2ğlnwY<ğH{‡ˆ{õïŸˆ³ït]ã÷µFÀ±õ¬ˆçÈs'ŠuâS	À|›€ñóš*ßÇû¨H¤;I“QZŞ¯Õ6Q?Ñ{_³ßhqİùCà{¦½_­hØw™®AÅ…_@eoà­q;G1tÂ]8rYŒgş¡ŞxÕ
±x½Û4"ĞSŒK1÷±±r?b×¤Œ „üyÀÙ1Å83­ªëÖÏùOüµ™/bƒˆñÄ¯}Y(`æ¬;ãOÑªıÖ×S;Êº‹é—r,¿U¸uÑ¢#âÀNxîX¸ÍE|šg€$|na´RJŞ1¸;¹»Ôè=º#…”l¸êH¯£Ü»6Zf’ïTs%ëˆ¼·Y	·{ôÔÂ¬ÏëRéLÇqF¸Ú±–^
ØP“bµ­îêúÈÒ;İèˆÄgñ‡‹bLy]öúÒ	€ŒÈL?ôÒ[§‡g8b›9š·í<î¸‘ğÆë®ú|ºìâ	7^—io	á’6ªĞ}†ò+lt.IòçæğÚå´(#çQo7åv\×U‚ÂG'Œ^&vx­íBcöfKIç^‚ò¬¸†Æ98ëï }Œ:‹Ç	;”‘ñ¶²°$Ë&ÄÜ“¾ûSÒD œZóE‡$>EMÉ|°ê¤À~|ôĞªòŞMNTğ2Ëí›ñ£°b@\5©ÿ_QÃîKç¾º<ş&”+»õŠ'Á1®0HU³B¡ Nz AVÙàÊ¼ü,À¸Yÿ“b"y¿|ŠÀü´€»^t«ÃéğÎ\ytû«¹§BbÊ åÊcÊ r‹Æ5„ˆ¶NNÜ¬O(ö€9OÖØ´Ñär™¨ã/g3×«ºü<Ó>¹wø² AŠÆHŸŞİÁÂÛ UE³ßÙø½œ.¡y¾QïŞ·{]{áxR€§ıaäîJ€ÏT\N¹½“©Pwq¨5ËœIöF]w:pgŸ‰ZªÅ¸ÅQmæÆ“E ¤*kZÀru,½yÁösyÊMáWS°Â=œ"d;T,İØ9§<<:=-±Âdc~ÚÎ‘'¸6N‹(8YßzñYC`Vö)û—IWöş®=>:›B[/Ô7$=S÷L¯ŞF„p¡æ·³œ,j¨}’oœ›ƒs|€õœ~FÀüäáß³ì9ûÆÚ.¢]†öKõ‰§æ,¨gQ.í›*¨}ZâLËüzg‹„˜,ˆ"PJgºª'‚P @ã|€‡.˜¼SI€# *ÃyÖÄÍÚ†F‘G‘bÈ¼Ãå“}¤Ñq^–ckMiûª¼d¯Á¾…›#š®+w&’33ÕéBIPá*s{ª¬¨~ô•"½…Â ÿ5³k'‹vRÖ&ÿzO±y‡uéao¹HÎTÄ¨AvJ¾†Ká­‹p¶ ¥Œ2U]Wòˆ‡’5˜İ%ŸóÕ'^D ™ñri›ª„rŠZâƒQîªêTër+ìsıí¥jA-©t<Ø™g2Ú‹TA‰a±7^bßRÏ‰‹€°Üa.c…àŸØl Å½BrÍÒ†È±Î*3@P¯şáÌ]èå³}ç©ŒFÿ8YÚl‹’áï=FŠ´ÄîjÑI (+m
“|ôèá6”¢”±'øyRd©¬¿eìX}I§ıÇZt]Ä…×§ÊnÒnŸÖ*Cå3^ÜÎÆp>bÒĞv  ÇÒcÌq<V»Fÿz€3®·A<Éöî·Y
 jÀï¦™7q¯ Ë2µ -=Ö¼ÉU lå-¸Œİò¬ÕŠL°ó^µé#Ù-³-‘³EZ²@ÙMštŸNôã‡™9®G?òÏíÅ•j¨]1Ğü«rô÷¹§™’¿Y};R>"é”5è^ÁÃã¥p“ˆÇœÿ9çòc€8O)`[!då¾VvøÄ6£Q²Nµ™”­«õc§Ú,j£º’KI“÷á|ñzyì±Ş$V˜qC}taÒE2mP÷g{¤…%¢°ˆS°Æï6Ç+Çí’¢pÛ§Æ¡¿;¬õ~;]ãd©»Ã_Ùw¾U­]•·EM½j¨@h÷ÄöëU[ÚbëìßW‘^®6ú¶HÊ˜ïXBáŒ@$w>hĞ®ãEçÏRTl´k¤äCç¾ãOªë'(€'¤ª¤uÄPÄş¾IöÍPèŸõR•3¾MX·.NÑZ;%£P[¼tàd5¾¿üT9—/µZÀ+^À:RcûÏÍKf =Éøß¯.­Ë²ë&"¼ˆõYWZŞ¦ò¯$W,eØùîšºì=aÍuŸ.ÂÜ>:k)Ÿ ğn ¤zëú«@
‚U†ÛË»Òë9x_!âÜ(œ¾R†² Æêh›ÈåÆßSšMA“î&õm¬h}YKFòÃ­YøûŸE‰ô©Öî¯—•ª›ZfÑW¶ù£Å,1;=1æ+véØë=¼í\$‘[iZóP>Îšÿ¹mv ÛApL"RÙ0aë©½hŠ@ìï²ıË–}Ssk§ø÷l!EÃo=0c™Ï²®ò,¸‘’¹hSy$˜º=Ne°›å×Ô%JOsiÁ­Ö¦K‚¦íÂ"½@•…m2aghoÃ¯Ø\n1÷™¬ÍY“R¿^²^~Dšo´¬bÃ ˜şı`m™İ!WĞ¿nØAœ‹]ã…¯ÔÖFßÌ¡óŠ§’8ô=h ?Öà›„éün`-´‘ìòıUÖpg$2Ò’6-2ÒU//à¶ÅõËóÍ´â2ñˆd‡ÇEïv.›¨Yä¯Èî#¿”ì_?¨‘˜$—CÖ_úb¥ûèKgÇü×Ò<¸÷¥ƒŠHÙ+{üKƒ!?]†çµ‘Ü‡Ç=ÊtßGNkûê>†fŞ«ã§&ºc{mÜ7^.E<ÉQ6H%>!^µ+y_qü\¤æ&İ|Æï â¢»áÿvéc*nÌ«€àpñˆ^E;Mär"8o1ı
xÂ?¿#3§†RåAŒ‘kI ØÖz÷§&ºĞØÁµÉ~IIÁ1¸¡ïrrè‘øü_ÔTÛT+L‹_GfÓ>ºµç™'Ø÷]ác¬ó–:†a­vØåiµ&ƒ²'ØÕ7ñÂ.y8•gŞª¢&ŸØ
àVÖœÌÉ™qËUd”¤s>#©íâ—îÜbyºó? Nûsûñ…šnv•I@UÒ#"uÿaµŸá*3£&H¨­hÒa|ôMĞí:y¦©İĞ«¯ı¦¯¨7ÏBNÃ—%}ànú1îv<›şÈ¡‹Ùµn±5`—_–òÜï#ŞÂË6O!õµC½cÉw 2–‡-ò­Ûl¥S¿ßqöŞHş—Ğ'ŸÂä¿%¦‘®ğÃ3>†T|ëëŞœàDJrvè+Q%ÆŸbÀ4p­Ç•rd«µÑ{f¯B3H+úS¯â¬Û	?S4Nµ2M%í¼Š÷a›ô¥îğÍÚŒ¢Š‹_’™|Š´€–Îí3à±`ËŞĞ<°ù°Ê†U'zİqW·÷cQ¥,àKiÖ‡ìmA f ïÈ;-_3í‘ŞòûâªÙ2ŞßşA7í –g•†:eí»RŒ‚ò•HÎS–¸å…ğ©æó“³¡‰6èÚŠÍú¤E±çÊtƒJm*\Q )Ê6õÅ„ú¹ŒÇ´ıÓ" S¶	é¶£uÍ½ÍZõÉŸğQpsè˜×XM±Ä{œEäBÜ€aÍ	TSPˆít3İôÃ§=)Õ}kğÔV}?-ùnßc)ûÃEŒØ +“ğ¶a[Kı,ëÈ¤\q„“œ³d%ËFE8îP	$-‹¼a'£[çsì(ÆÑ©c@k lef…–îk“£Ì\ù8à8ºo*ãÑf¥]°6>~ºb8xzra¾“ÛóJM.ÿé NÌ¢ŠN@´JP×ÚÃT¢+©åØİ.`9”-@É:Œ°2R¤b}R%\Ì‘Èzã¿gzÃ¤Hm®y[‚sW;±«HÆüGFp~Ÿ^Î«šÀ«S¦¢a›áAŠ t¾Øé'å"QéHwBÜ>,°NísÛQöãÔ j‘ñö214J‡¡ÉvWTs0IFµåƒmÜlXÛBÚU`=<¯à"í¯0máY¡rn¼D`y„Ø³PQ~ƒÿS§Á<uÔû/ßÆ‹–€?Ã® Ñ0ŠOçöÓâeìORÚÎãÑµ4şü;ûw²±…B #Khİ‘§¨:.nTlÿémzc=`(ÓWk+È×é=©Orqû> ¨z!jyŒâp@©VŒƒ0ïõì$åe˜,$i*Uö–4Ã¶ô–2ù¿NB›Ö½AÙ‚ŸOX=!OöìÆ­PµJÂ
®VĞVºqÃÎÒCàQ+c­Kû¿ç&·y%3h‰Päï‹İÊòšYÔ`²;ø#zïìêà‚H2½³ÛvgW~ï^*À:… “>1“ë¥ßNßğ£û‚-~ËW½'|Äƒù¨˜&¶)ñöó¬_ˆû^Wö
hyØ¾Å5ã*1ônÙı]z„¤’ao'»9ŒNÑÏ;‚ì‘»°;NGbŠD9kËá3ò€cv®†ØÔA©¡£P"Ä÷²Á¬ˆ<D•ƒ^RöÆq¹fI Y\_ĞVc:øöÚ¼Ãş¥À+ô_%Ía»xs—X€ÛMÏvĞ_ZŸ)üc‰×>¿¬˜=â-¨Ç3½-juŸdqĞ³WDjçr‚äïHêÎ†<¹«Bke„û‘¶$ä„w­¹¼TpÔÛ9×»P77§†³7óJ´÷ÁvÊ)áé^M=tÍK?’ ,D°ü¬âY|g¯%¼ó§»IÔ†k¦£³øåg+Œ3ı?µˆÊíˆ^¢ e˜3¯›6kÑBzã…FŸ`ÖÊòH¦oAjÃŠ˜Ó&Ça&Ó[d_Õê¢LÀÎ´å«}ö¢ÇaÎnÚ+$(i‡Ÿ9ªî&¹KÃ|ŠàÂ6»†eÆØChÕ¯Â÷•\qºz8b	æFX±±5IÑ#Ö‰Èëı.‹ÁmJny[±½ZÕíS©›Ü†°¯[ëT;{°*4û&µOnxòl¡ºk7)òºU%ù–Â·AšdNÌ T¯©Õû¯òm}X½j*ßğX³«şÉ9à/ûë‰ÇLRªÍn’Èkúa†]~]øÃY¹Æ5ïº
kÆF§xnú¬ûƒòäA¹—“{].!D$tâ²æ¢â&ï80Jtf«òujÍ)à/älù§œZJ~8€hÒi—2â^œî»ÎÙ+HŒÁí®órN±J2„Ô(2‘sÒ4a6;g4¿ˆ4ÁºzïŒ”­ÙÉ©åso€7åF(˜ÔÙMÜ®¥!÷_Ÿ—ÒyO#P÷·„½GHy¾²Ç29ÿjƒ%N¦Ø*3ªRqWİ¢§6§ÒjêæùA|?Ãò*Û€j¼ş€…å'Ë¯qä#_ÇUÈÂ‰8ØE‹BÚ‚1bÑI¥ğo¾qò›1‰UêËj<mÎmÜtr,B	ŸÂ'Ešc?1Ç«,ım*=ßxíºI<òì²¢Fë9ı l®¢ erñmÓ„¤ïÖ/+ÃF”Š‘Úê<…#:Â0-]õH)¢²³K·Ní@KÚ§‘ZÔBù1Ñ9œ(Ğ•ZÆdà©¤™›ÏÏœ_¶k<ğ|¹YsÿçŒ³hp§¹ÙåJ*8dSSzæÊó–®Ö°-3Sp‰W(¡¸WÊö¥qÿ/{íT“a9PŠÓ‘!ÖY€@$2s· pÕ0-,fÙ@qÅş‰ı†0ıs…ÇW>ÎZbOvïVóZ&Zy³o~r§‡ğ±¿~VƒI¨Ú ÷íşZKyt;Ë›ŠI¶Øù–ÔDd›©yHÏb¢ÒUQáóv½êi’æûn  \‹mº+YINz@yÿIæM¾ØÉà ,WÉ„g+´Q¢ñ¿²hÓ+Yy”5å¼Œéä]ÚTÓÓ`ä³b¨}½ ûšQ®HHSï<×‘R©²gâêC´2
xz$>ãôp‡tÅxmù@ÿğ#7FØ§®ÑØŠ¢opTAŒ!3£şÕ€ŠWëëHƒaf
á|çÑb{ò=2ebMºÀÂSx.ÏÕ×öñ£XUlöyW»§a+¤•%Yğ¼\q2¦n ½/ÿ–±ûÃjå®¼]wQİ“c:|Çœ|bœ”{&˜äâAR3×ÖX/”6çªõƒïªyŒq:¿Ÿ_B›Ó=Kô]˜»­é;õàøÒ“Şv¬­0òHI³µ†\™¨u‹C$M#VÄo‡QÔ	ä,S'æ"§waÿW˜I'Òºı÷D3ÖìH‘i_²¬RO9è¦«rC™ÜüÇ g!"©é ïjüŞoªzRUËÅ%ƒÉ]dLªRØ\Lë?'»Ÿ¬µçWNqĞğ,Ñ9±ÃÓ·}¸×q„
syÕŒ­§Ë†Í¸[*àÒöåz' š')|„H¹ŸøµM¸4eîõt‡şI0ı¢))Ş”?œøÏt\Á¢H£#DùXí£øƒqÛW)èm¿ê)AŞAŒ Z[îŸàÎ[*°Óõ<;úş/”—ğô}(32ßJïM=Q
8ÀDnˆ“_êhn¢¡µzàuUüIg ìú=Şİ¹[æ/æwàû¦¤§¨ûï+UÙ×½I,Âgøcf¦º=7p4†€„¹:ûCşxåÙ°Ü‰»"ŒmÖiÀ¤×hÄ—uÀ0
rÒú-õé}0Ùª
™„ÿúÈ6­¢ „Åy<®ı©ÅuéËÒiÛ˜»¥ß—–½ä/fãt&‹CîÔfdš|’$”­/UäÓÒ!"+ªòp[,9ƒ	!3íÓiY~‚î¡RÒĞÜ‡ÇL"Ì	~ÔãÃÄ¤sÄ®vçg-o2Å›å²ˆã´hB2?mnâ…?Zìª¿ß|#§™ƒÈzq÷sBc–ç‚i+fg–áê/Øã,7ï	VİÇ]ìiÒRº°=ÂDô¥ç}r <ÙAo<,_“96»›ü‘k$”²åG„dgéxßy)İ^ óì2H¹sÒ\ï¾¹†œ–Euá®;Ÿy/”§œO®~w.À,(ïwïY
¿/]NÚ¹Pc«½‚
ãP®Ã>t<¹-3Ñ¼)$ı»ö¶ÉI¼9±ºÀ„ìtÀ	s•§6õLRîÏŒş·êóì²—ôAKÉÑN =o‚-&NB›-Z9,kÕë3YƒäJg«%k-ê6|Í¼)¤ Ì^øgğ3/·S%Üñ“XDùdÙ9y¡’w—ë+Û³1…ŞĞ¹¥C¹[„Ìq>œı…2&e·ûSÜ±—_¿­Ç…êÕ~ÔÛúÇôû›(Yò?ÿÙGü92m\ÜB
'œäƒgƒe±×ªhŒ˜Ñ#Ñ¾•(ûîM.õpu—ÙqVvéA(¥ªñdq\Øîö4~îíÇÖş§²ìS,’œk¿îW0ïìIŒ\Ä$g¿@æ‘JµW‹š©ÈVJ•Q ájoÚªY­°@è[<€:c^ÔlYøwíİÔa‚N}vùºK‰*ñ¯øhgÀmÈ#â‘è4Hè¦±„jñÕÂ@ÿµ\‘âÆ_ôrè’T•ò\4’êâ@W3Ê˜v\Ù]ÿ"…Ò}0µBÒ•ø§ÿ*5ÛrìGÊÃØñ7[S êÙ+¸ëİ‡`~ÎŠİr]õ;=Œë³&òä‹|WéæKi´lœ^,+£=kİ)äQ%˜~_,¤dYj»pıZñ±áG…û©yŒÎ’†DwÉœğˆÑËÓM!{áuÔ%¾;I5¼iHÆÈ¯á›²`¨¡pWÕ¡hft­w¯,‘+½úPò…m‰]†ô¥F¦ñáM¨¨+»OÜìoº]¾ÙŸfĞ0ˆû¸ âF—I%{bÖ£³ÚE¼->¥=–ŸvÚÅ©…øLÓ
^İE–ÊÉ/z”Õâˆó6U6ø±+S,Ï^`mâå|–;´¤Ms¤Ó]D¾	İğ€×Üı[i?çé_å´=ó#‰³Ìá§èQ.\;ùr1ñ´¥^m‡W
j'‰`D'–ÌbªƒˆşîNin0¾‚½†¬cZ<„#vœµæ½¸ºÑAš&ıy­-î·dèÁº«ç¢»=òtN=RbFDÆ“ñíOÃƒšow¡iY'@¶Ø1ÚÖjTØ‹^vga[ZÌè8SÎÈ——ïÜØáT¹OµU´äÂ£è
ØCnK}ÕÆïR…êevÕê­¢®]Ïõ½Ÿn…ÄtÚeÙ·ÊKÛ„¹ç§Â] şœwºª …=€Ma’ESÊ]uµ7Îò¦<Ák FUwİ»Ğ.J%æ_n²¡ª†,4„¶½Fríù/
á=4¹ì¤Iç~™IK »¸~Œù½Î\ß-{ ZûB¯ß¹˜ ÆLŠzxİâ8ÍEé…Yi½PÀñ¿¢m²vVÚô³òĞ@ì¸?D\áyœCæ‚qI!y¬¿ºE>±ˆïÈ±ª°èã—Cõß	ä){Np=†/&Úwğ€ub±7Aé[<+ iĞ¯óM[%"‰ÉÜÕ¼pFå©µáà‘qÇêÿv m¡°2şwÍXíNì©DóÄü’&à'™ ¶ğ·ì"PN™Cöİ{X(µY~m%2ôKÀâ®¤¾–Š£+iÜE/MH#Gk]Ü­œ-òÁüæÖo£…õ°şuÆ›Ó°ŞÛWÙí³¿7e¿øî}ùø¤dÄˆÌsv:Ù†Ù9ıFi@ÿSÆOË°‡°èã¤æ#ñ<lÓG8»Ã³|ïÌş©y Ì>ˆ(°Q:ÂÁğlßÎBê)®ëQ©qÍÊT»A>2£—x ò"òé¢õB‰ì:¸m¹!Š+¯LÌæº¿#åœx”é4sìÍ~ÒU€o1uã;#2øÚª6ÃÏÒ Œ…Gê‹]Àñ'ø|&\Gİ&\ &Îzl‚Ô÷QÆbö`+Ÿı"é”\4“¡Ä3M£X¶~yC›ş¨²¹ëOâÌœU`Ã!tbå÷Z(cDQš¾çNúğ¤^¨ÓöÌM­_nRÅú35=ÖáÙTÕ¥ñÁa*"z¨>
Ü
ìáXåÈ-KS ¤Ä”Jmmux \k~÷bpÑŞ[õ;.i’¢rL©:ÌŞ©dcwf~ÕTÀóÑüQ|ñ}K1[âïhƒ@äü^9S$Q¦iBç3?ê2ÅŒùÔË'ª™bWˆ°'¶¶V¨ıüqª›5,7£ÏN¨éçëz„ªïÛ:s;nK=Œêf½P4Oå°s§$cëfDœø[•,ôUó?-}V:÷|ÁF%ÿO×±òÙú´#
‚Ä2‘„Ö¬…ÊFtl	AÙˆòÛ<š.Óş›ÍÊ®ÉF§Cãp¼·IØòÁp‡UæÙà½T%°ğ…¤W_ÒÛPcø£Dá€ø>Òí¸l•İüÏî¯ùù6A©|X¬¨Àâ’èsŞÖãÏì#$¥ íÑ6Ÿ­Äº’ûMŞĞš«Xn¸¾œôİÄXŸ0«ñ˜Tmw!ş!2©	öAsaèñ„³¿²¦Fê{ …CMùòà©’ÓW¯ì…[›‘
ôÊ|ì¿v§7Ö[¼Æ¥›¶Xàw›ÙI Ûş7È“¼ÊPn†É]^<hÄe`êˆWêxğzµúºVçB\UIz'(wÿ“1Üxö”Êxöºv!^O<Yw59üV¹É
¯İ	üJóæ¨q›<®«íÚ1èôo­5Pç«AªÎßÚüäït.lo]Lƒˆc'9±1Iqó.5‘­}„Eˆ/ëºÉş£†‚ =ïl.Á‹Pğ6+[QŒÒ)4$£[ô9?=àç+WIºÂ§™F^‘'ûÉ²Cú™v¼öÈ¼—jÁ ¿ù¼.ÛM%Pœ'ÓPIò“LùJGL9ú³älş¥¹z¸O(˜ïÌı)¥âŒ–|fOQ(¯û-áÙ9İCÅpÄ¸ıË«PjÜàÁ–³Ãç“Â9­-+ õÕ|®TJ(¼P]ø@BÔ6“ò5zæĞ@x–qvÜ;ÿÖèa¢ùÔjğ£ù¡{|ş½MúÎÚ;EØåîA·ãUnO8û¼~ş§`!Ä Ei>ËÎÒØÖ^…Ş¢t³$$L	ïšØ!aB¨¯ ¯bûPåòifü…¦«çhX›GkşhÕÃèZú¿„x:´“Qb.Òq››ğ¨ü¦ ĞæjÆ:¸•ÀêÚŒc˜“ú Aºúæ—*ûûÁ5­!èÁèA7V¯’I3ö˜3èi"=QŞ{,ŠgĞE$Ãî¢Õ5¢5Y˜n”w¬Ú%† ¼‘òÕªÉ„$Úì+X*( ¸•PÎW­¬¸Ã™d¯€QÌÚ.¼Û„Äg¤8Iû¶†Éäm
§LçĞÈõrŸØ İpÚ#œ’Tœm>ªH¼®“İˆ?Œó$÷+ÙY¡¯à@oğWUR"9®Ò©×\~ôÿ ¥o.£zÇôø0Aè¡xí$›Ç+Ã-{Ù|CbeiE=|ĞuÖè²Z–õa¥ÚEDM–šÿOó×'5@<hoŠÇ¢zÄÑzH™%Š6@)€ø7`F¯ÓöÑAİ’üÛƒ4™›ÌE ;•ø)JûTIu‘ÈìLuîœ°Èàm’hçTî û«:ğa`‡©[çğÜËi$sMs2U’ËPn©µ•Ò–Ó–>*İ :aò‹$û¾l®s "•Î±o®dGÅ'(S&“ïÅæ½YæÃÔ§²OÎg‘ ™½-N{e‰ßdWŞÇìµŞt	á#½é¼ÉxÍáP_–ÈüÀcõ‚êV¬æT™üé®òRAÒà®º|÷Qì`’¢q?Ê¼Ê;gl#B†÷ˆtëLB‘ä½d)~êXódJ½Uêã™vcÿÊxrÀSÙ«?¿»êes¤íÂÈî>òÇ¶ukPQøbr‚g<>';¦ÀÑ‹	;¶¢YP[»°@ÆKö¶€Æ[æ‰µ”¤Zq'ÑS¨WMñZä>ó(wú™³±…/ÕiÔr\†hC@ÀhØÉ€Ş.Ë¡²¹Zaƒäëßİñ,Pä°‚ŸÕI:Ë›Õ‘˜Ê‡Ú.FF¯êÇ˜‘ñ3¥è¹K›pœŒüĞï–¬¨…6ëI .KcÃ3}|PÑv¨Øñ¾uİ
¶ØƒÁşş"ç®ò€’´XyË^4h©nˆåÇŞ²Ñu&&
ãøª}„p(,¢ïğìz´¯™‰A"«ƒXD‚Ÿ7•—|!³b…¤6C.µ3q-À”5Û²¤e½şŸJ bFj™–v”)ŞºT‘}Ì(KÇ+f¹å‹!·9Å}§ÎëIbé+ß>Sş—ĞR¢U‚1-"ÅÈã¹K6`gùÚR¡Ò7ãÚ}a`#ò¾©Q\G/õmqATIx5sÁ¦^6ÓFêçÛ™kOCÃkW»¯ük[á$tÔ2`y8HÒÛÉˆaÃoe©?"º”mİºVÛl0i×%ÁyŸŸ.ï¼Eí÷sú*¤ÒĞb+ø5T­)Ÿx¿:xhVP/ÓÑñ·û&Ÿg5ºf3Õ!ãt­†“äûæG.ÌÀî¢7M·÷ÑÈ½¶Iwƒû	¡(ş“Ï.èAPÆÏ1ê±åéQï”;KlMì|ÒëÏ-F  $QÍVºªEzdÀM$‹_Õíz[Í–LvenT¹1‡Ü²UU~i+d
†„Åii«h˜(7Xq“³àş	ÙÃ[_+{—è*,`“×ß(Í_µ´ïjPÄOêr0
•Ä¾¦Ğ!Óndjé¸«xõŸ‘.$Ÿ¿}ùÚpïbĞn\Û—[e0ç	•ÏñÅnØD–Á,ü©DäËbûZğ÷–õÛ»cğ{«…W:ş=c~TÍÂSY”>Ì*=æÒã°ß:•Z¡$ÚÕ²ãO–_ğ6Ì÷íå³½èus„¾İİNašuS^2¥œ/QúÂÔÃCk„Dp'r}?ªâ¾2Ê~"ˆñöè5z@›øû…ØºDX’¡Şş›Qy\ĞäÑDë£qZ±›'ıÁöûë•á˜í¤ˆ‚I¦së[g²ƒÿ;?CIĞø±E€ÕJ‘Ô¢1üà$‰¥‹O§b	té‚ˆßÆíÎó¢gİTkP& ÙI5Ş¡[Büó±°İË·¥À¸/êH»Qó‰™?¥(èŠ
œxİ9,„gï§4pÿB”‡®Ş¥šl¯Q×±ó4`²bÃ9$£ëédÈ,ƒá_ˆ±†\lz(—‰ºşÿ,Å³äšş†t>ÂZf&›ÍgÈìîæÕâĞ®x²'¢›ö»¾o[Á<0ªO &¸½@‹ÿ.nN59ˆQ1s<z6†sŞÅzWKÔ ±£êg2!Â÷En|ì¦.K¥-ZØF:±a.÷¨Ù×q€VoMÅò6“%«óÔm\ë]8¹œûÚ]{ãh.a×òWIÑ“EBe]²ıúğ(gñÌX?Ø§ƒ8õø|^É›½ó@q4zwŒ{ô‚éªH×<¡Ü1[™§Uñ,Ê}Óİ“î ¦ş+º¤Ôñ/Š²‚Ä×{’ry/ët\/–4XY›¯áWÑ°l"‚©şF0g„·æ&Š³CX±×Vû±üËi¯©Â–Mh?Ÿ<Éø¯÷ô€¢ÖÄĞ×
ŠãL
†Çƒœ'È&Õ=×^¨HD¥h¦hİÆ.DâÏYoÚ N˜l¢ïtš„DJ½%½¹#ãTÍ×FÄ¤í;Åpa9R/NÄBhé&ÜA& .¬[˜ÄıG@×²|ˆÈGò»Ù¦œ ­ëjä?İ²Ô²Àgâp\X¼×Ô?'3f;³Ğ™ÚÙ…UêÙ™$èIJ¥ı‚^–©hƒ“ÓS œíô¼á¦ş3>ï÷ë‡ÙCî&/ˆ´zÜ]1­"vS+gø=¢vTÔ÷u'	{	E‹½T[›Ó{8€(àõßƒ·ö|¢é#G0}Yá<HÃp@ºätĞüÔc‰ôƒÏ 7Oş–R­™©BÊ¸CnTèhù“¶N—\@]Ê¨QF]cĞ“)'¸‡ğáŸâY^TQw¬|¿Xo«8âáÔÎ[/ñ E˜¿(òc2O:°øşZêaL@­zX,+ÿ­Qëïì?ñ*Ó¨ñôNÅ.Í€=ÿk#rr¶`Y¾ÒTÈR3yY­/m¬KxQ¶0şnºÙÇğ¬!™şbˆùšÙPç†“½*9êS°È¡1ù…*-ÂTÆ‘®îœšÏFlåÕz]t¯ñ‰ä~ˆW;8;püRõ±Áa›SE×Ê0]EÉ*;¦Î‰;°íÿ5	YOCWN¼Á[è]|ßşòyE Ï{˜[R¨~u³øwóhÙÕâL¬o”ÛïòhÃrF\¾ÌQWìû=õzòÖÇ.d¨iIÍ+¥Ã÷s^¶±Pu 9{yGêÑ‘Ó„ª0z!L¶¯Cïß%u±ˆŞõE¿¿J«‰½l=,Ai3õìú]?(í-£îİ?ûv¢XûdÇ/d§¸lÏ´1½M÷ ×ô˜°"gæS™T/‰æO©üüK®âÓ·ÅcsÃ—Ê8E,(r‰‰º4"Äœ’¸øyKGãÕúL<2QB=W\d¬1eåŞü'¿g(CT…ËMFS¡$91‚ïÈŞ½¥}iœ’‰£"„5„4¢×ì¹½‡Q«"€Tî+ÈB‡=Æè‹ôì-†+æ×1.ƒJÀR°“ÌF!ŞP¥ŠşCSÈÖÕôÈİ%RÅ´]0ß{¢ ff8,œx`~wPğµÆ	åVÔvóØ2jù Ó ``4ˆ½JNm¸©~¯±½Ş†9\+H,õ)·Ô%cîÁbUl¶òm°ëÅ.ÿX(x¹j6PßÕ‡cŠ'-Ikú–ÌÉÄ‚˜¹èœ|Rdv2‡8¼uëõHU«ıÈJÛÑ«ˆØw«ï…ºzM1ğf»ç‹ªÓfÅ7ä2LÔûÖÓšEì°SùÍc’BjÂ‹4aÕxsL‚ê›Ïïôú³Êb4Š‰n†öcÍAŒ;&‘ğ±=¿zûŸzW°®Ò&MåÑå¥¥^ø¹<
{PD&À]i„ÓÒŠÜ¼‡Åoì˜O—#DtÖ­B„oÑY¢"´t‘éíÀÜvÔçÍù®¦`,ŠÊSpS=H’?ÎY}–s×R˜5Ã$Ç;ÿ}
?àoDvÈ³ÜŸÇåRÑlZ2…P7"íêsw–çZ	UYĞa4xP
Òrå»%¤™ú‹‡#£¤ æ¸3»L:Ú_ê¶¤kíü/€È›ü:àú¨„P®şs>Ç­ÿŸPü÷•'^‚^ğãµÌòBÇ£hYoÂÕÜ)Ôã$U´1'ë›Œç©Bì\Q½×½¨>•É./zKÍ 7¥i¥51Ã»”j‡Œ¯®üooçØíq=‚3ÓšJ$ÎùÛÉ—q3reÅÇûa×şSÁ–HŞ?DR¦ıË–#·(]‘Kğ:¥”séõÌ$hÚSMøñ-È…´ºÉËs`iš’9Y}–&eÌô ‚æ““ñ\àóg&}'7%İ¶ZecÅöt
…Ü¸½+·Œ)4ã-½Õin»)t3Hù>/>ĞF»A¡$«»Zz¦ö÷yb'Ê¶ljâÒÕ]WS[<Ä¶¯'>‡¶·çRÃ[7ğ*D½ò…B>Cpp
*J“«C€¡“ übÛc¡"uƒ
¿Ê£‰Ë±şFæ6ÏûFÑqS“³¡)?Ícy ½‹TYËï#›AãÆ6¦#djZ3}±éuÎ¸ëˆ·”	/4ƒ;p€y¿V±"°wæpÁ¾Ôd¾GÒó„§g¯¼äëD†·šïYËÕ¯=:’•õÛM"o-ú4¥>[yN¿áL<® ˆÆƒç–‡‡¸›Å^&Xµ¢âÃKEqÖp0…^TÙ4¹Ìóà$®ÅM˜™¯ãláñkâD8Ê}ºjZ[ü;·ÔÍŞX8j€6âi:Æf¢$“ztc”k £œËÄŞÑWßzŞ$¹ı]Ëtïå‚Às×ä"^¢òÃò3¶!í§”–d¥0Dkâ%VB‚c´+T•~ê#¸êœM¡&¯^¡’q¤'Éêù©ÚrÛ‘5§fy3=Á‰Î‡–dÙÚ¼M ú6¶,®{~"ÒH³û3«šEGlô`uéì!nÜP-´UKsRø "5§tõ	œ´›…)æ™Z\§ÏZ ›ÑäÎÄIúÊOìMd=T~‹mŸ¼ñ’ß–œ¢à„Ö×Ãë¡w€wÂ€À")ÊkÍ<¹¹Ç1tô¥rFp-EKuÍ†Ljˆ@6¼ù»•\ÃÁ¤\åUÓ¿§€Bƒ¬-m¸ò}‹q®¿‘šß÷ZtZ@ÔÃkæ73Ìèm8eÄ}Q’e;BÃÙfy+Ş»·Wğ­.²Â^äÖbL=÷¡jùCŠ¹—}Ê#".[¡€åï±93ä,Koª,Ÿïï>	²¡9Ç¤ÕİËz°è•…% y–b!†[úDÓşÛ8h)/}\*?Pïwí`8+ŠïŒ]W¾œáûò%uD_¢4˜nì²AİºÄø—’H*^õãtµ&Ğ+ÿúAß¬ø±àƒ—“&;»	=À×PÊ9úÙH…¹     ªˆnğÑ É²€Àİş¢“±Ägû    YZ