#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1113172043"
MD5="d07983740833c5eb6294a65424da12f9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20696"
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
	echo Date of packaging: Tue Nov  3 02:33:25 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿP•] ¼}•À1Dd]‡Á›PætİAêe†‹‘›Z¢,Ñ[†6lIVûAß¼sd¨—áŸéqÅpï?½’ÙÑx¸³‰mÖhŠ.2ÃğíÑ7!Ö­¿>(Î™ˆŸˆBªqÆ½²È{¹M'Æ.>hİÈ.xÌÑ2ÿğJıYØ—•c
ÀùIEˆLùøƒÿ‹V®V7*Ha…Tb+9Gåv±¡ù²»ŒgòX$a#Eïï´?q-?É^r`¼ Ù¨îGtøÒ‰r\.R¦‹ÔÅ!’Fş€"tÙ¡|bçU¾MÉhÃæÛ”ñÌ*ìÁØWmys£—MnN:¿VkW3Ô+¢÷8Á¥­18I'× 0gNÔ–|‹à–[Ø%¼—ø… ¥ÛÑ¶k×K+¿‡Sê÷YìäIş•›ëùš=!!m÷i¦úªÂµ5Š:Öt$Œ	7nÔ<›a™şB‡$ëÂ¦jDQ3ãTf o¤şãi¨H#»À\9€ŞçØ{±ì®Ù¹XvOªÑÔ‰…#†ßZš’ZemÜFÇh¥‡,bÃ¸Úk,¬ïsŸÏãTXáÓëWÓ{ïzçø~·Æ	]F<0Ïİ5v´jtªš¥S:öVÍ¹MU!_Ùñ|9Ñ±üTÇ°ö¯ä]¾Ë˜¤]pä4ù-¦ò7rV
†TŞ:f–²¶æ‘\Âä¢ÆÛPßW7‹[ıÂ½†aú±µ™ZÅ:MnC]„nŞÀûU;²rÙ–¯ìËş7†?cº26l|Ë–C—Xş¤dT„^ò§‹£T5ävıTeÏlj+ïz'ŞCµÓ mxÈ¯/²^)z6I…oÙ/s7èíøüa¼u®Ä8ÿELÀ<Øs¾&¸fâS•gËuChjwéÆîÁÉ‚”õ;jNµ§}ı@Á9°®Yt’FœO-jWÁ;¤†	¸@5Á}ú1“ğ7­ôŞ+~]ø!Á,e-å‹iÏÄÏÏøL§N`ÊŞÕÊˆ>:k©ÖAPåì‘0y¶ÖïQ–x÷•"dVÙ‹ím¡{øQÄZtÄZ”’7‰ò~XàïÕ©Sêvi=é†ÃŞÊ:l9Ú8Å-±CWVxEäYáõ¾NĞÔÎM¸*œZå­étÒk§Äbq`ª“s7Ü^¦Q–›®]“ƒ.ZqŸgó–4Ø›üÃYdç˜Zø—‘µ]•Ÿşõ±Ÿb-äòïÃQØñºbÀ
¿•5¨</²ş~g?21İÜí—ZïÎ´ò¨ÙØ8TÚ8™“„OïûÙ¦Ù£EÙ›f¼lz—
¹Ö}—üÉ'ıc§<*°ŒŞ©`€"­ç22º<y¹Ï7õo6í‡œB#ü4<³Ã—r·¼ÿ*Å«Š§ïšEsw)‡ÉTXre€Í¢F%[”k8†PA3Ÿ)¸Ê™;Ù¬ÛÛğ ±™L„ÈÛ¤4&…bóUO”K¡­c"Ô>BüÇ
<n?èkÜÃjÊ<iHóğ4Füò„ÖÕ9BV›œ·nï€"œÖÀÍŞL.Wƒì§Kı•ó’Ã€ğ:ñá´/¶RÚÒ¶¥ï—ıQà¿uR©şÚØ±ÿ©H@1©”g© ´ö¥[Á“`NÍ:xWÏ!rOô«R8Q·&Úˆ‘J¬¿ø*Ë
:{ÔQãÌÕÓÏí~lh²!„â$+€—õh‡5Î•-Õ5_#øE1óé­Äï=•6ˆŠö!Hæ  $zÙ?„oÔ6<é[qØ0VtZu&*g?¹ ,¢nT¬k<].ÀQ[\Mğ@ö!&uõ9¿M®3G]OSºcuAo½y¨S{W¯‚ñmı/ÅDñ­mÑUU©:6'1*ÅãJP~ã¸Šæ-{¡çšFõÃ 3_*O¶Ê›á®;*eIšÒOZJÅŸîåbŞcÚQXs‡µ¹­à×ñúb¹ô'İ25ŠKT=ÊsÌ¢©`L;²í°3zÓ˜ycº‰J¤3\øÇÛsÍ&Ï!#Ç4ÑË¨ËèS µk¹6 ~ÉÇÑ«¥ÈğáÎq7+p_u¢µ.bXŒßçÛ5²'Ò*ÆîŠ>ÏèíPK‡ğEq­NjØ¿íÀğá6ça4SŸ=dÛÆå—·Di#ß°YaÕvtÕ
c?	êğg](Ø}ğúÁjQ ùñ°¬ç^‰WÚ ±NèWiN&:Xš¯nX“j( ÅIQ‰DÎl
ÙŸş;àf/ÎÔdFò5ék÷‡¦AGÓ8yÿO+Ô7Ä¤×òN®&ìŸ¶0UÀ?0’g§e±ÿ“é*íl):U4PìÕtŒ1Ít»]Ùe^u_3wì\¾uÿö–u•›!Â	Áyˆ×•Òº!wRŒ`Z»C0«"ld@X’³¢OW¦—ï\ÀÙÕV¼â¹´jn®t^äë—_È¬°±Ø³cZF„·‡³¢¾¯1Æ'S&vU	ŸN<&Ïe"qáÒØxú³Ã)ªN<:Ôø-cx1×‚ÀÒØzı¹(´º BO@'L_óê_·_ÇNU$†MÔˆ5J/I…p3Óÿı_réQñd—µhvBünPí7‚d†Ï•H®	w¢öC£kkêä_`XOß×°dJ®ÿ‘ç0ÓK)m4Íİ‡îN` ¶—E6¶`€Â¹ğ9T~Q—U y»ëö€xºÏ·>^ü\É_îH:¢M›ô½>…2[Rl¬Å¡'¶>¸=Ga·(=cZgT›ô¨D‚Sô:Û÷÷%:‚ñ»á±‡À¯[ªQ¢-òg‡´‘YFV'[•V±_š6ïQ•§hl+‰®7z×b›èÿ€súşŠô•­/0,26ÃRO÷²#Šˆ´‘-1ºYé5l=”½‡üÛ¼ÌbÙ¤Ş/:â–Õ7fß</sè~ÉmõÒc<¡å†×`qP÷PºÖhÉ%¶,Aø6o\¤X*å=×ÿ>£O¥é˜™™H<ÀuJà)L£Ë<àûĞGìx8Â§Ö’G	§y­‡"E)X¿à3ú'¶îxÓ c|\Ï–û¹ÆyE*©q˜ç–«ìªZ@AK¹ÆÎQ¡Ì8‡fÒWvk ¶‡“Æp$q1ÛäJ¡±ªs0W>íîn• QÂÌµ2"Q^´¾ªÊuŞĞ¶{¦Ø“|
í<| ë2¬}"K! ŠG"L‰ÄÀÆ`D\õ¢ìRUo‰M¦†ãÊ—¿N@®ñ©¯¯§­ZÙ²á2ã¦¦‚ŒäóEİ·›z)»MF6AKâ(<D½Xx½ò9İÂ)Oä¯Hv‘ş/ğ‰v‰¼5¡îÚ³7şHg6Šÿoh@UŠÍà¾b69Ù½ÊåÃRN•¥ntÎÅÌŸö#½Zñ€>]×=ÿdg!TbÎz5Eú˜Ü£Óï õHÇ\Ö„ ²İYõ|5¿Âr­(»5·Šò¥î8#Ó‡µÜÃ~º!6€%ÕŸäj—	%3ğñÅ{s3=UÌ$~“Pó³‡Ê”I =û€!áXW˜C%ÔwÿÒË¹g¦r÷Ğk¦¬ÚÍh†h´«úÇğË3'4BÓîkàp¹=Œ¾¥‡A¨JkŸy¸bqdkÈ	z¼0|]%ÔA’7d{FO­Ë3È;ÊşÀ¿kë·ÑéõyŞhï^z
÷Õ†½ÑzfØ¢/<_âh‚wŠ;Òú›4G“;<Bîˆ¬²FGì¾IÊÿš•È'¡ÚG;ÊlüÇ2©`SÏ˜²¥oÊÔÖzkŒÔó÷ÿîè&­ä Ñ×„èıÕÿM ë©7ü¬ßrÖµ¦ÜRC•‹¢öí¿ı!¼Ñ×(ÛÅõ®¦¶{Í¹ÇMxzÈ°^œ ßÿ)t=ıÃö\£+©íuœCši$©òõÛıä`3]®İ†GhÕÉ­Cı÷§kJEÀ?Aåó±'êü#r,öÂR»ÄÔuğåÂ¨ÆEZ¿Ï@‡ï§/’eròX¾­²GDß2r;†	ãG`D†Ô´„hÛˆm“½´“¶µz÷Sñü‘Wò~u°ƒ€ mG·w‡´9<¥jMH•ƒ	 /dT€ù Pˆ¥£íëğ+Ó^(™kJ‰­
ƒ_t›÷Q8pæ˜	ºÊ úÃ Hº~ÚnàsA¤&c`İzteĞÌ5:„mÔËÍ©õg‡6EØîv¯»2¨ÛM÷ò­™%5Õ7¬:2¦=gŒşŸ”Bß\x¢‹vŞ_šª¤(;{¶İ²b©xŠiË81Ãw@PªŞî+’ÁR²+ÜºÇ=mI†ÿ#®‡˜V>N<›Ó1»¯Í3¹z»÷²‰Ív	+Å¿1KH*öŞññ„ûq*œ×(~'¶eæ¢‰“¹×î¢Òèc9—0À. ³—0ÁëQ›7‡HşBLéwPnRšˆ"0ß^må\İ8¢Jsf+†Ú·w0îü¼š+àó¬©/ªs÷õ9×ÿ+¢è Tg‰¾ëßº56	sLHŞ¼IÄ?Ïƒìt%}¢Yşû_²ˆÃı¬1<úxÜ–««tø”0ë!#®jÄ¸€õmwÅÂ:ÔD*{­l§#ÈYå…¢û¤¶÷O.¯ö?¼’i}Šy'ÍA —¥¬úïl!æ‹øôä„&÷«uŞï×lü±¹Ÿjkİ~x!ò¯À¢õ ~«¹•jK`Ã;`•fîW‡¬âJ9=-[÷GMŠMÔk1¾Ñ--<vc5eû¦ÍCöÑÆa lú?0û)ª?÷ó©ŞØSçŠ¡¹ĞšfšU°†Q®Ü"æµ‘ñ\ÕŠÅx •›~ÕøJÃm¯¤a‹‡MídE¢muad­²F¶ã®.ìf— ‚…ßßpbÊT˜Ù‡UüÄLßÃY>ÎT\ƒÎˆƒÂ1g´¥)ú+wÁâÛ•ù’”ì‡:Vı8ök¤•g{cìzGX
( Nšzbš!8,-îºï…¾ÿ–%²ØÔ$í©ü˜Ÿ”†ocg	ä}µªqg.Ğ¶¬æ>-<'Ş§7kÅ“&P»ß½-ç%Q^m(àQšØ8ø!æk¥Oİ,øÿõòhÛƒÙÿşïªÏ‹›µ=’6
Ä	µÑ+™%Ô™3pK«êú\³[ö®Xg‚Wh´)krÔAİŠæÃÓ·Ë«/üÉ£³QÒi—N:Hhqïvk]0•oˆ¢k]k„‘şÔZ\×ÓnßB:Y–¥²ë¯L¾ÿöÂ.Ç·Î‡Ì²Z&Ò½rf‘!|Vs Y6æ.è¦ÂÌû¥c+Ô1-ÓOT9s–4”ÉkÎ%kµ-¡0BçÊxF%l÷³c•æçUeøz1{À³%“ÿ¢Oï†eåh§zQÿù×,,'½î½Õ7gCŒ6gÚõº
„ši%µ”Û±Z™Ÿç-ÁĞ½z˜fof}…Œ]j]1
”ïmvµßÌº©÷»"iM÷éß„é;ìIÕÓˆjÜ:Ş;c×°n¸C¹3¾ÜåĞ«p4NéÅ€”É\ZL¬ß±JOaÃˆÿr} Œµ ˆ|ÌµRo=pªğwv·ÂƒO¼¹M¼ï$ûwå§Ğ{Íál´àn¤ÎØ(÷ïé]-p÷¹˜F´çÑ®LîAÆ˜“:ÿhg¦ªH¬	ÒÔîõÕÔ¯îL:JîxŞ™ˆõˆ;ìyÿû¬ëôxŸu°ÊÑ/çx×{í]²sˆt‹à!(T#®U¾Ä£3Ú/šßÈæÍÆâ-®ä
)ï™32ÇSºÓÇC°5u‰Õ¢ß¤6óxyœèÑ E»‚ñ.õNv8ˆ±7®)0İKÄ¬ô\a°µÔ—Öµq›¨Ì‘Bmxëa+2…•±€-­ßXô¥æîev˜™)«ª§Ç•Ú”§T£“ØöÅ¦="…ÈHå$2¢sA"¼³Â­6gtqÑ2œRœÉ	Ö±G¯k$ÙÚËı©5QÎ„ÍøÖÆøš„¡a¬•vÿBœÂ ªq.{Kªëœµët©Áµ[HÆ;rUrË@— ½óÑn“·/ÓcPÏ!ùÉ—ØĞRğ©ƒ^©{–pÔL;Ïûö£„”›ùıhV“!cšÔê…] ¾/ w¬ÚÃŠ¥>9€ğóH(oÒª§ÕŞ(JåÈ¸kî•Ï.‰/ë¬;‚ş!ˆ&jÿ~€ÊŒw¬cXª¾ãˆëY£ÿ,¿o<¼“%Öğ†…NÑ<99lCD³>B9_ÆÖÄ×ŞÇìjGÕ†õ–V
•jl&Õ›»³è ôUèL<uôCş†‚qYĞTë~>&Á^ (ø¶“ßk: ;Fg@GÈî“	f~·õ¿£'Zàgw>[Jº`ø²iêşÿDST5Íö`CcÖúSY^ŒR^T*ìD¤Š¡k~»ScHæèSÕ«¹¢±ºê.ì¹kšd¾SKíKÂôlvı
4Š~àÁ»€>§ÉÉ@&©w¡5ı/˜Ëæš²˜˜.õŠî`1ãçÿ4ËXwÈ£¯Ø…8' ÈnbNx¼Hgc³ÈĞ®Ï`Î=Ç´¶Ä^x$ÂFÅ‘8¬şw2®¸,X¤…ÿÎ~™j/ÇT˜&¾U0“¸ƒõb¨ìFşJ’‡	Ô92½\fœvêGa}ÔĞK\¯óÑ×mYÈúÈ+K!;}Âd9oMÆtİ‚L˜ğ×)·qB±½,:AË`ï»÷k8‹¯æ=CjqM*p†\=Ø!ÿQöPê×»È¥‹F ®=©ã÷ç»©@ÊêÈm-Õ£X‚ç]Äà£o`’……`%ÿY—<]“€Åy]pôì"ÜÔ¥ù0"3áRÜpƒ²‰wûZi5ÔIÆï¾‚²®%Ê ëà_Ë§¨y°,ÌáZl)ùÌ«¤µÓ™p¡j¹¢s8›3ôuK?·àmÇ¿°fz½é@\²ôC{ãì*å’2QêÃ²Ì¥3Ó¨#"H“SYvÅMHNnxÆ©Líš³”ßO¡Êná+…ğ~å©¨—[­zZ$O÷üY¿nYó\:˜Sî‡¾ï/ãÂ«iR±OúV%šÇH1M]¿ÄÕf •²„4JŒ†7¢`7ÕÆ@İtşåiİ —æ/o˜×(È/ç½¬æG«:¦ø/ãT!$¿ú"fªOøMóUÉÃS¥¶jÌËö­)ª@ÎşD<
 S…pq†ùÇè]†\ÆbJu¯ÙĞêøo;¤RM"&…ènwc5aV¯°ºoÇbi—M!ˆ~éßuA[!æ4Œñ{~Ä?Á@Ñù*›<òlÎ	$#'|êØ%äøqŞ+¿è^ø¿ê½€ºI2¯Cá9û†/’=QÊà·_2öB"2Âi¸„×ÆÚë9~aÇ’èKøPİŸúk,>‹¸¼[X/à³Ÿ­‡D’MÍx^O±ÒØÉ}_ç¸,Ã±Ş»	Àò54ôóäÃ b]F‰:!Í.˜<Wfì/2ãúıùÚÓe=û!^ÍiC‹i.YÄO˜2©f¹ PU‡Vgô+y†>ÿã¨kÅè’Ë©=ÑOc$]–‚·$Ï«_½Óàæ;qtŠ‘ÏMÑ$B`(¾¸.%z7Ù²8l×î{ —q§fí+“«„aKyª‘WO²u¤Œâ›×1øm×éšqFz—†F¹Ûœƒ+û.Ë‘H'oZ¤?e÷®„=ÜGtñu´Ú(êúápÆæ[j³­èFØ<¥„2H3ü®Pslˆı‹ãÂ-êŒ!Ş¥¾Ošú~QËõ}Ù³ÌŒL‘m*,Îy¢GÛ®©ÙúedNÖf)…k{ôyî(¶›ô°4•>\1Ls0OÂ¼æòĞüĞğñºXöPÊÅˆXP¡”ITÈÍØêx<wİ1u½¨0¨Ö¯;º *Ùâ|ks§4QÛ>½6êõ‰A¾½'üoá`ˆ—ödÚ†™ ¸Èd¸-p{7'<Û?B$Š[UÅZp3|Õu3İé¨KL26n‚öÛ,Zc|ƒ{Ü3t‹«±ñ²jhP²3G^'|jÍ3Gü6|K2_~§^CH
ÚNN’èYPÄ²ÒÔ4æ§qŸ·=Ò”è¨OÖPUTì‡ŒÓäìâÂhj «ç\VI°ÖÛE )Òlu²¡§‰]Wzf6×é+3	1(ØYÓÑºc¾4{(7«¬ĞÒÚ®£‘?¥¨g/{ş',Ò²*ŸéòD‚œ¼`‘é§¶4w©H£>£q¾vÖç„ÓÒ0u®+ºwa­Œ0Ç«ƒ2.b±ù> ˆ‰j+t¦ñçÒÔš=wĞ}"MÓ¬ÃÁT›— ©KM¾ŒrSUA8÷ò›f~&ï¦ağõ¥ÓÊ™8Şç/äÖŞï[^õìğ©Œ`¢Ä|cÈ{]s˜ë6¢c>\‹}zi¦v&0"ü‡ÂA!¨úC{Š¿_¸Å› $3*?|vË¥‘ƒ?ó$şb9,iaù–6N¬]©Ü3Uåào]Vv$Ï öÛ=q¸³#=°teÙ/È7ƒ| Ó'¤«›!$(U` ¬Îa'šŸıZ³`D"Y«©Š·³LÔJA?Üâş§8ÈRúEÅhC´à}ı×	µ` şÑ JÊ#MJ^ËXĞÛe[9£`ÆD)æïMÈŒ&0ë8“äŠkvóTü80’€n>û$hÿqŸÛœV§ÂsÃ!JÉ÷%´ïOVªúÏÌp<¯m]š9ÛQLØd¼e.‹É¦h#­˜ªóŞ%”g›,a|VGlQN¬ôm_Gø««HÇOÇr^KÕe…x¹w8ˆ÷||iÄğ1µ³š,{ñÔòŞ†?N6â/éÕŞK†|›ì?m¨¥ÀBQG&Â}¥²Ø—ÒßYŞT 3oı³%ˆ7i†¥ûšøŞ)pKKƒ·ÊÛ}" ¹zU#68~Ğ†,(L½ïÍsÍ”K‡²}ÏrÃ–ˆµ R¯
c±:bXö£\Ul¯¶ÑÎ³“K5ldh0ùµ|M½î»Œez€‰8Ü$ÚYn^Qüç„5Dg],ï?¦ÊF™éä q!ËĞ;móšÃxq­æéK¼ƒ¾Pír¦ŸÈvş©,ƒ•ÖQÏ~†ĞÄ¶]èEˆõ´şš¤ -½ÆÍ4>Âx@Iëz@kŠ©ä~ùúÂRó”-"æ•+	•÷%ç³ã¥PˆuÄ#QãÒ2%üìRÃÔ«W[&gÂ{íœÌñÍÕUdïd¥”C
4äõ¢Ù^<Øm@¥Ì¢ú9ñó]åû7ÛûÂäùš÷táM}zç~rÑXÛ5‡ğ(js©L#~”™;ßÂâÿOlˆQö0t?ÃÕUO3cÀ9.øš›(N’ïï¦ä{Íh £Èa¹h„ûª×4â3†Ø‡ÿ'î„İñ0U
¼Ú]ËEL&­‚“ŞÚ«Úå~[p½hÈW´ÄAÛ u/*VKñàq“æ2SEk´Ü·äîG˜?xÅSS÷[vnBH*0h¥yü”«ìkv¡î^ÔæyÄ§×D
u»ª¦Õ3F5[‚!3õË¨$iQ'€Äÿ¯3©ª7ñ_´RµN€ªHij¹QY4ñ}÷4ƒ4Z‰râ¼².ÊVİy3öËéÚ´'mlüÆÔvÃÙFc“óå©I'Yİš“2p<}Òqi#…‚áPk|ğCIZ8™4İŸho\-m§Ez†›AoÎv_i*ğ@ĞÙâ>ŒúÏ¹şCm 6ãğ04|”4ŸJóH­T‰…òs
S¶”0Õ°d‹¦÷ˆD¢™¸Íÿ.Ï]	j\yßJí©VN³‰IÏüb6ÛášÔT6‡p3/ ON¤(“ãw9‹0ZNTtí?P¦ÿBúÛñƒ›R +p·ÊÙ!7j±¿N#KH»ËçÒ’ú‚¾d´.Ø×GÖÑ>*İİ}€›ËÚ¹¬Ÿ?ğªú¥ü²^r»¾¼ÂÑMMæ–»ûÂ©ås&Ò¿1Ü›ƒ«XĞR¤úŠ^èÇ@ÛëŠê WÕèAQGX«T•¹ÚË•G£Á»(ûäùI›PlgfäÙœË5Ø;ˆ}Vç[ºX±š¦wÁ£p}ŸóJ#69DyErBE>"“ŒdFÿ”ÎØq-ñgLq¤<póÙî9»ğôÍí™¡~ Íƒ1Ùi}Òù—Õ!CcI)=ğğAM9Íz^½Úk	'Ôäİ±Åºaƒ*yËkâI·ş˜=ö¬”´ Ã#ÌGÑâ'‚É{ZEcïmÄ%é/Ëâ±¬T~¡šË©M¦7TCìÚ?²õï¼õ<­.èÆıŒSY¸šİÄµUI.Å»á'g7UâÀH|÷ƒ*êWäãáíUĞèáÖ¶v6óú-¡¤Ïl†¾RëVM‡3vCbØDªœ÷b<d­,Û‹!•ÌE¨}|_XĞ´KzÀ…‚ÕS%röÜÚN.°éËÆUÃy¤ Ì iªIìqòwEİ4û´‚ĞÛ)ñVjc
4Ù¶“ ¤È¿€â‰‘J /B¤x+ìHäò3bKq,gOÿƒ“‘ca‘ıVÚãıAXË¨ÂÅ}şg7e+.Æ3÷	õöG„õøîö¦¸½#C8±‘7Ğn{è“½N(¤em‹”´ªØJM!¾wQ{+m‘•—¶ãé\‘CÖEÀÈUş Ìæ#áD¦·s0´Æ¤~wı„¥)ë1¬Ü€°éúq¼Ç6	¸›4ô9—©

tG,O-®Ê:•u&¥`Dƒ¸œôhf=xm7ÎÖMİVô=v@Mö*wg#JéöŸºÖTm³X„„¢eÊNÚlBb=Z„ºƒS:Ä4øáÀÿ1B¢"FÂ—Ñsü½âwÖ¶¥H#Ø,ÃØ¼†t[ç¾îáB@’Hê4¥àÛ._f•ğ×­¬#Ñ éÁ4ŞáeÍ—;†Œ¥Ù¥êkmóÂN~ªYëÀòGùÄñ¾çã€ğlİ6ø’råD¸¨rw¥Š>cÂ¸yjìjÓprö[§ßÒiuãŠt÷­âü··Îr0ËPåø¼o«’v_ys3ĞÙ€aêBÅi‚Ğ:Æ
™û¢“i8“LdÇˆôNi¦«û–,kq±´¡VmFÏêW'òk>îzE,¿zšõHÀâÍW$"ö ph½KYãÔp¢jğxŒä›Î0i„4Ñ'°µàüOhÖ\ßa6Ÿªrsg€öøÄIš¹³ësbQ¸N¯ÏòoëBÙÿuGÅ.­OER6ø ¶±:ş’–ÒÕ/¡mzşé×ÅƒÉ­Âz?v…Ü'dÂ·¡«\«?kvºJÿmş~œ7ÎÆæ–^Ç…åæ¤m?§v‹HcÎ7ĞŸó"à2¡Ã2b”ìB©DÂŞÛgã‰°M);Šœ>)é_¼ûPµºnäûü¯ø’%«ÓùmÉ
í¯„o±ÚW“àò$Ù=›cÑ‚ûlMD,†úrpG	8UÃğõüÄÉ	MUwÔí´)+ë]¹@éOpÆæKï=o„.±”ävVĞ‚ô«¶{_ãç)©%l`^ÊÄ8Ò“Ôç~=Í_n?6ê©{ÁÈmš2Çg£}H"T‹,ı+J¾!5è8ÈÛô¡€E!HdùÀ
İTL©Õ×*–Š]_ ŞÒ?ØİêocßâlfBïé;/‹¤ÀNNïZBìmvØI¾êúç5Ş`	ó!£Ãû|CKÎ0<÷ş†Á÷Ò÷À¥H©ş!~V’Z;$"àñ†„ôˆö\¦u‰%ğ5ÇaŞ‡Ù·pÄâI¤$˜|*á\¾‰™çµW˜s]´õ8+xR~]ê­õ¦†…„–°˜@õ¿×Xg³Ø;Åtiñ‡Ïÿ-ƒh’O{…g¥ÙŠÌ‹q¨I¸KV¨VMH–‘Êl#Òugúp4Úçö	côt½İñIˆÊF‚é=±H  !vV#e`ÚV¼f<W©“^A¨:µ\ÒØ_Ú”e¤š67Ğş£¼œJ2[j³.¾#Ö[<7mmêäˆgÍ(÷GÜm*oMâ·X6Ò-d­=;¯]z­îf4µdW“áäYÿæèvİÓØ‚Xç±y*°7Úœz04œEûÕPÛş‹ÃîÚßXŒ*V	š,ë²)#‘÷xÜ¤{ği!‰ªeËgój–+dİãm‰®‘”Õ	î8«\X9…üãªÉgø.O=}ó½šÿ}×Çw² æÂ~¡5e¹60ã•³ï¢íCEÕŞ…JÆáór8âÌıL§üw¡¯aÄ	•7$¯•g3Œ‘®çäµ
íÃ0ùÖ©âÑzãªcğ°ábG(Ôø`éùc»Çğ×À$/Z¤¢…íÄKè;Päj\›;*æÂê|	íûûãËx›&`VÇà'iS>±brlzìRâK¢im‘Ìü AEZBrìB²±ñ\>ÚÇ4õçÉû j„¤å[Ÿ²Eş^ä«G
n0‰=ZÌÔÊ–CDûj ‡é_»}Ö´Q-6ÆÄ	M-ğG»¤ÆBcÁ…›Õõª˜|óŒÇgèáp¿ŞÜıÖõ½¿¡\a>ó"¹–»š›ÃcÈ;¶’àaJG©‰ò|°	?|kO'âA;Ui¹Íö6–•Wæ°‚×O²ÈÎĞš: ¦>q›Á»zGBÅ'R×ÌÆãq†›¯ï"şqgfèr‚,%.´bKÉà(\„+´µ<c²ÚúÀ¹ı’M‰'qôÅNŸYC¿Ò£\@ˆÚ0dç˜yíÁÑù Qş¿m‘u=® É,ûeı »/Ï«r?cÿÈÍø?1YVqè†­¯$5¯QœC”1?Ò)©@†ŒÔ·9Àx õ£³XÓ6ÖäÚy¹^HoËùäBş]¨îhø±pá7*£»ğÓ_ìã¢¨EÌã';dSĞƒy¿]Ñn~±§=Ó“µP¶·Ò^T@º«ÊC–íëáLÕPúÅÎN|ÓYß°ıe}ãz»Y9ğ]õ[2ECyÄä‚é^ÄÛ0LÂ~%÷º~=:ŠöŠßµô|jëojì{P_WŞ}v2äÈÚ#üò€º«E_ì6˜§z‡Í²÷Ş™À_O¶79K‚ÑÓÁ`¿dvØ·bìïè=VõÀ"óÁ«­ Å"Û+ÑYl #½Z!~êQm;”<¸ª]ûÇK®é¬Å>“0ÓÎö×
¹‡=íAß»lsnİø¢ââ6yuø’r[4uËò¤.6YŞÌ4°ŞÈá~´‘5ìPQAH“ew{èóˆ"Ó%\`;u:iZ¡k9ùÊ†3‰ZàA¸Ê¥‰³•wåØ}{kC@Kü;n>;&şİ·NI,H‹ØSEA,2(øˆQÃãW¨ş—”·Æ1Æ?š[Qñ,ZÑc/.°lÅåË;!•ü<ƒáÿ]ñå˜#¦a›–°§Zœvñâô~*àfPZ‚8ÎJ˜şDdŠ	J©GNŞœ€£4şôç³ÉÇÙ¾›ğ_±ä»QtY‘z'õÏÔ‘f.Ã¤NbèÔ
^¨Úíû”
ƒäÆ‰”B8ˆ£A—ÒÎ»ZÊf­H62QÆ+×ø‚t‘MÏ'˜õ4Ô¤ísë•èª§.Ÿè<œlùÕ4w'Î<ynÂğÚ/ğƒƒ"¤/_OÖYbëİ„£fîAæ•È#;_œÁÌ0›i)ÛbmWW.ãTØş=™hj‘éÁW!_ß[ttmxûÕI÷cwP
ÒŒÍã:•ÌUdª÷ò)7êò°»bA¬ä¦¾(ÀĞmÙDàœx®c†1Që¼Ëı"=˜µ&»Ä¦ıŠ”üù°¥£ôL¥ mÚí€4¤Ù¹‚¦ÿNÔtìÇ]5öF˜×Âá¸Êf6ÊU<«D‘H·yFÊ•´ŒßšUŸ^s˜‡wã›Œ­fj]4§šFãGus2”¶~ÁaH+Å/V.6[ĞÁRl$Eƒ›páx‡KK¡ÆA|ÆúBãáiœÓ@ZI©Î	é>sQÂ‘/»ÜÔq·£i9‚L+Ã¡«2PüëÍcÆFÕHÉÂÔ¦côâ‚[È¡ªsé#)7*öx±ùĞ·µÙ–ªC¶³á)†ŒA–Ô–Ò±°¾8jÛ}ßó¤/µ÷P˜Ú‡H‰PM'€Mæ¹fÕLÛuÀypw‚	‘?	bâ˜ÈÎ†0“]ú¾¦UØTÕ=^5¤^®Ğ„‘$á"ã¬9?âšj’Ö	õOŒ4†Ëºb¯ir=ò>Êx]Can¿'GAÇ!-†Gä‘šL–æ\qåÍZv³¬PáåÿáÓúœ";¥üfÅƒIb|»zÂFÿ›=aÈ5#]Ñ¶Up©¤_8q(•4l@ä¨´Ù5¨ûé;™’fË2yü5C•€Á ˆèíÊ×Ìƒ$àıfOQ—­¸—ÊÍ¥³X‘œÒ=Pñ3ƒŞP‰ùt¾Ó¿LÎÀ˜¯J©lÖÕÄ_×E½x{õöÃ>ãbNO}gtì-0B1œøÙ¢e"Ğ©	³ÑFtí\3rì
Cö §EBy“÷îhø ›Z`QX¡ä#ê>qsµØlxÒĞŠåKyïšİë6i“œiF~cÒW•Kbv‹sNÈ^ûm¾—ËûõÂÁÕUKİ°™ü˜©7—±ÑïüÅ›f)gØ©BAj¸Â¹§Q@:U‘6	(¥¤„pH»úIyöI«ÄİV¬#©Lóìğ’?!xSddÂ¦Ÿ÷ÔÂÁ¸¢\ø	²‘‡×^›‡FïÓ—!íüøø‚¤H(‹?„:F({EçræÎ]ÕJ=miˆÁÙÛÅİ¨ŞAN=E(§>oV“ÜDÛ²‰·&ÇÛ2€Õªî®—Å+PÒøÌ¼pJ˜c˜«¨"{µA¢]ÈıWZ÷c·&æ#Çk× ÀI¢SÚ a£¹‰¥Q¦®p€eäEYA;fØZ”Ìëçj?ÿl¼îyÿU‹¬Mş¤¿y|Úy¢ˆÒÅx]X	 Ô3ãf±nÕo>@|’2õ’ŠõM²ÔBw±æåê[ÀT*h#tÜaõ˜ –v±E€b†÷Ã›úğhz•ã&k*)ıoV_ştCügNk†5ÈÔµB5gËÛµİ6W„c]n†!Ã¾¶‰ŠY´¤ÂñÔˆ‹›»"îõ>¡¹_r•"ğ¡ ~ä!"–zky!æøÕsŞyvŞœ3ş‚ûh¯ÑEjS@ÔãM-7ËeYáJŞÖ¯ğAíUóñˆ5á­Òü@½ªÖ·©EŞHe8¨[¼Y¶(Ğãíö±ÒÄç©OeK˜ueÇ¾déjF?mŸ7ÔP:À-ü'=$Õu–ñ]0ƒçÌVDTXø6·¢v‘xÇ÷ñ`Ø´¨6Ô¡Áã-aË!dú	Ş^œFŠÅ6˜$‹ñVñâüå_G--¼(ıUGO·ªïåXfT³7-¨TyZNî­„1‘Óô'Iâ×b·ó=;ä £z]YÒ¥Ÿ%i-ÚŠÚ²Æèãø]NşgÜñ­ ŞÓ/^!´¾úKŞQóü­4¬O\[ÿ×Ïªgb€Ğ
'L´oO))¦Ö{%oÍĞ‰»¬,d›§” kˆá¸|aÂKU¥+…ÊóÉ\P\íÌÖN@C•æñøôâÿkfáÛ6ó  ©Å;ô)ÇâLÀÖì›¬÷ìvÆA"„¶:ô.ì/¼/v]Q+°²V|[wL½˜rŠ»ª'nùş«œ÷‘¾}_É]—ÙUÒû€Ú‡ä´îcÃ¾=¡Zù«]ÇıZÄ&ãd£oá!ˆğÆÈç†«oØ”Øü)öSKÆX¾bV’«Ë“Æu—é†¡Á€&Ÿ+@Çš1®û>ë^¥ˆÌ3 \ùUI†Auh—õVµó~Î‰úÙi×ËK÷0#ÕMÃj0#àÒß ¼*¿u¯ğ·H’ÿõ†ú)\xº÷ß¶½â–)bÏ“äK@©
Û>²lHH¼¾¡^İI  `±÷±—Îå×BO‰êœ »ãİßá¯/“ÿÍ·Ã”Fìãü92GJYE;9‰ß»?EÚ‘KÓT±! Üà—ÛÀ»ıL†.±Íy7—›íô‚÷–fƒJñS“ËÆ¡ÊĞö¸¢ø&CE¬-è¼!Èë˜½ºpR8
)¸6,£˜ÍÕ¥!iˆ/:tJQó±QäÚ¡±0•Ú_(“÷õÎ
‡n/³´ ía«Ÿš‚wzl¯ßÃå³§úØ[g(Æ#LÍO7OT¹Ò°Î1ĞúmØ&™òƒ´ó¢ò€à"5”bx
šaÓˆ+:}Ê0[0ÌÎ›<¬/_.‘¸ªÒÖx„.¢°dÉ£ÓmÙ¡í÷vÏ¤n )ĞÕßËPuA_vï!RX €İZc³“µï†à6qJ/N„ê€Ñrñ„Pın–3=ÄA<¤2
J`à¨hÒQ Ä‚|>Ì¾ÔP"(A¨G˜ñ'ÉÇgq®KO,‘ƒãÂÊ4¿`q±1İ?B^ÃÈ—J@×hT< Ã¹²öPÈ@x±a«í¤OJ‘4w+e—æ­] [NıuöÖ6Ó9A_ÚòQJÛuÂÄÇ,¦t“¸‡›dÅÔ[7%!)+{(¼6ì<(•{»ù¬„$Á‚*o!1Ğj]SKˆoEY)¾áÍ–³”õO«÷‚UŒÂq¥r »Xtøú–[³[#ˆäÜx4µªÍÉ¡äêÆé¨ÎÕÂˆ'* ŠD92ê¸úoœMÚşİbkÙÉĞŸ9ÑŒl^74¿)èô<bÉ¿Õ—Ã0¡~ÃÊ*Ú¶V=<9{Y‚ÔO²Ğ†Tù:Åˆj*WœcIv½&^š7Ö@:øÍ‹ª±™iÍîFnøåàËIÙ?¹)#Lkó$c7—-ÓŸa¥PÃJóŠÎoÓeÊk‡)à“tK`rôïeëdG»oŸûbŒ,uäú¤eJ'ãœ¶óãü¦aœL¸O2–“_C!Ü{˜í;Í]êñ;èã5cµPFÉIrW,féN™EÜ¤zmphÙÏ]"çB†–œZ¿ÍF#´p°BõÚZ`: 
¸¨ìÕ°#©§`ûØœö³°€Ít=€N‹CrÎô}íñê%ã•­	0‘°#®ãoìg·8äÌ÷­!šMû¶¸<Òáƒf&—Ø:‚G°‡ÿ%mú 8\[©)Q~±Üé(%,óû€jñÀ×JŸ®Şº|ó|¢GÇS:mt×€˜ŒE•WîNº7b:6N–§j‹f§ŸÄ¶ä& EM»ş¡(ß DÉ;ğ¥¡Aÿ¼½ºŒV‘ZÆûÙH¶ƒˆnädÅU|^›n¡Æ’™ ) †~M	´R+İıÀQ)5—‚\~£Ü\<lÆé'{`DQ–àÚÅ+w×ş>,ˆ@ !ÈŠ÷²å‹€9¹Ïæ»§y[Xèo&¼G‚0{ŸAy”'5—¶/7W,†$Å·A“âñÉú®{PÆiåÇMoß¢Ü:ZWtıB3rÎ'u©Ÿ‘C¯ºË¢Dm!6ÛäŒÎÓ¬ğSi=€£Ü{0ÄLò}Ç¦ú“™¥ĞCJ²Wû8­·Å·ñ€éƒsÏ¢gE€ÉPÑajš.Kö¶ÃImÜBruxlX€˜ae+ƒ„ª‘˜Ù´9™×#êr^ˆ”~Ye_ĞF‰š§lw³”ô¯ÀãÚÓÀsLpÿ„Æ-kCØ<†Ú„ùÓ
ÓdÉLÏf+çÍ …š¬«=)@78Œôã^‚Iı¸=kÿæo7Œ52Õä‡R¶ôt½ÛğOYÔm™n>„ xÓ…ã¾–WøÑñîŒ|G%¨¦‰=EÂF|å
ÑºıB<ÓGs‘Â¤xGLlÅyœmS×±È³¥·æî·®Ë!GÕo ôRÆ¨úààáÛßfvŞé•J Hi*^¼T¦áeZL>ü2ü–@k
D<•I¾BÂeÆÒ„:IäğştĞy/Ú¼ßPáÃM¾‘-áUkÅÂÙ¤¥%Á6Òl_çÏšÈYÿû²B°·é
¹[f†šïºâ¸ñóN_¸ª9)ÖAu_É¦n¾3â…ogóÒşâ¬IÈi,q¶åk„1£Òp7(w‰ƒ¯tÕèû2ÂœÏÆ$P)¥í‡¼úÁs£Æ-b|Š§„%(‘M·¡ĞúŒ]™4êvÊy…Pz/ìH…Şö LTIdª~4ÑçÅ.†Õ¢Ì_Éf3§Eˆõæ	¨û?ß™nx#¯ø0Sƒ8ën¬X/	Yİ€¡BÂì¥­míÉh³åÖ'KÁ…EK†â‚L&K¬j2«æ=0JJ›‹×ñ'×Ó“¿Ã’‹H”«:”¨IŸÂzÍ‘£%0`¬±´‚a—±c¯(=aUÃÉö«Ç×ãpÀwõµ=–¼±½qF§zØŠ1VÜT°c}»M* ¢wŒITµ-g}R°(›Øäœ5µx4·Ş‡çB4ñ³ù†û[xv+T&aıŸß›ã/ñ,h5mP—u¦ÏM©R•’¿éU\2;`s&'fJ¹Ó8u üväô´yã	°``=ş|·eh®Ñt¥'&sÁ4NĞ,øòğôÓlqÊÒP%øè~i	üFµ‡fØ™‰'[{Qt{Ï&yÍk-FŠõáncM>êËi²q¤¬Ÿ9ùDŒrÀ„Óñqğgw°Ì§8ø«à†ˆíÓGn‚àCñ{p|+÷ÇŸƒåÌÆÒÙŞˆ2hÃ™8¸ I?.úÂÅŒÊ–…tg³t½`VFÙ`oMño§b‘nÃ?LÆBª«{÷¿˜ qßz¡|xÑ¸Ï³Öø2öïÃ§ô$‰îP/—D­y=ì—ş¢Ñn¹é¾¹°”†GKİ9sü¤ÇÖz2öt¹{’şvå›/ºüÓ~ÏAU1Ÿg¶(-YY
Ç&Ù‹9Ó½…i)¥fQM¤FR–ğcÌáÜãÀ]ÃñíªÎ‡ÅÓÆº °O4¶Ø¸ê}îåVN÷é•æcÙÙédÖúk&™ê ©ååÆYm7kR«N\7ÿ_z¿µ­—FíÉYËM²AöKæÆ¾7Äi¹ÿˆ&«;W[ï —oÕ Zº)n¤/£…G‚ÎÓ-èˆ`6è]$Lú§-§%hùt”ObÑ©À¨’ŞôÊ¶.ç¦ğò?9Ì¥> #‹FíTE?—„Pç‹&pWùC’'Z,tˆmßU"Ïå;r×Á
&ë”E>Ÿé~!¯ÎB4.Š±9Ì~=ñ‰şoÁ'?j0	îøòëDÄ ­Wú_ø°ŠæÆ4FßŸÜ}Ô³"°N‘4¿¥Ò³°¾âXS±'’ê†;Œ4Ä‘ÍZk±(zVãRÅJ›VæÃißº8-õNE
r«¦§ëzcÒ³eu‡ŠáÀï9'üÓ…c+¦­Ôi†ˆ«–iì—ö*óVDìtıA¸vë®tvn×&F§°—ËF•Hğ¶cç“˜-HíÌ…%‹KËu2äÎÖ¾¢kÌ(~×k/ÖšàG»ıKblY‘\KºGd°ñşKç9XĞdKå(lèZk¥ıÕ·lËR~­L¦³‡-¤s{IÕşï©¼º™²FS¦‰aG.¢„ ÏšzRßÉÂµkN¼×‹^XkeÎ p4Z¯US	Äİ+Ï!dØÔÔÂçnq]¶H>åç[PñÀîÉf@öª»:Ñ¹ÆlP×ßiçnè„¦@*@Œ5•ÖD5æñl¥ä6>ò¶çaÉ”÷vZÌ@°š¸^šÒS8òíåh“/¾Öárx’ØÌöë\uEKeX~ÖGËô,L ÅIqs²ı‰8»†óŒ¿cÛ{¿3àGFPX:ûŞ êâ¹Øñµà…Œ+Åİ¤X…=`ûq¼¤Á3¦¯EúWŸA õx8à‡ÂÍ{Îã©›(ÛÂø?V¼ŞoÁˆ³!»–jğ§ì¡«Šº<#äôj(I[U‘w&å+J÷$$õ¶÷$«YV»»G†!áù§e-Ÿ™X.¼°q¼¼c3çCœvçš..AÛ›Ê•Ñ9u†Éqó•Gç¤vdö4tà0fSZĞøVËZI¢Ú½ÑãÜC¾ÿÅˆûÎAÙ¬r@t†³¯„ìùQdIè”«†J­ÜEëù!ÛˆöeqÌxeª´42õö°›;ò#ˆ ™WŠ&©¨òÑ®°‹k¹1"í¾Á(/?Ç£8˜zW:}—è\ÓQb¶Š§±âÅe9fíëeuİ(-ğ°Ø6Ã¹ñ?ø„÷=n~“%^Tô²›Ú÷óŞŒ_q7†f	\Æ%!*Bâxócş¢4(Hİ*fQÙËØ­şeœzt!9cé­f2[·ôS„#[Ìk¢¥rƒ&ğvfbk(èíSÂj-Ø›7<BÕL•!×M(ƒ0†¤ê7{•œÙoı/ï]¨·áŠ
óòÎß|š±Ù?¢8íz*0„	„ò†YBXÌrt6¬â ’ÉÔÌq°å½‚¯/Sïp§o.Ó@Bò´vtıÚ}ï­PwIuÄŞLÙ¸1bßR`#s<-pÂ<É´ö5Ö³…Ù'šIóNcÀÖYßM®7GBà¶gïÑ)¨J:Qí6M3ıíGTˆju÷µ?k+"äÓ)t°×‹¥†’1v?ñe(>‘>lö¸Ó"Ç~Éc±ÊÏİºÑ|\W”cç$éxù÷ë ¿ØíS´Ø@Vã-s®a²á!.}oŠœš‹ â©™¯PdH9€Ú eèx[fkê²MÄ‚+F	¦Á¹•RH˜½¹‹/çJá’îK ›Â…½%ßéŠdÅ[! »QÊ\.?ÚM˜ÇoŞ	]u½_ónõXcq!´tí/ùÊoÔÍ;JÍàQŸ4¦–’l½{î>ÏÄ{ß2m*ˆe‹úà}FÊ“ì/“Á
Ï¥P†¦!p~”z¼¨öÙ{â-Ùæ
á@]¾h)s' ÑÁÇKëŠÂëg§.:,|0÷Ìwmi§™èòeO4ñ–Ójuo½¬—VBß§XÚÑUyñÙ‡óĞ×ÄvÇTËWø“<¼iJª'ÄĞBYxº•«òöAyUuNê7‚fÍ1É+;{ÏS;ãÊ3ÈîÆu/¹[Ú)˜¹Ÿ ¸â4bL>ä8-î)-²å8QıTkPÙ¶Ûú½‚"N#æÆ¸ &­‘‚ÊÙ°õ—²Ğ¡Sv—é®Úx5õx'Áæ¥Ï¿ Şy½i
ôôZ9¤Öv§ÿ©ÀRÓÈörçXÈ¶æFµ°8=¶9Ø Ä0qK½Ã;/?9J¾êm‰_‘^Ÿ" ±k´7f2­Ï?¸ìB’3™Ï/i­Zz-®ÄE'ÚŠ‚TÇù*–Î){RÍÃZ¸ı:Ò6³Ä`ÿhÄÖ’-ã@ ;-ñl|'x¢À(øá®$X°ä@¿ØÅşÀTofúã0V®³¨{Dyõ˜™„âlo65í%ên ‹ÄÀtÊ‹}õ‹ÁùÏ€ •ÿÓ¦§+W„¬d!d‘oXCÛyÀú¦&K÷şqkäşœ¸ Àõ`oM´Ñ^eoÄf8[j@ñjk»NR‡;ÄÂ„ö´Nb{~}ÄàÇï²Š=€~:“$¦ç½&Ê*V8¹÷ØËùÆ[œkç¯õ#>†‹OóU>-şù‰¦§È©ë«]¹;äáš$‡È‡h<‘4y¥¿gïÊbåüİˆ6…ÃŠÍˆĞDkyãğ†ğ1o “ÜİË¨Skåé¦äÓ…Úë<Ù×¯GÇo:{âÖ‹`w.ˆoÚb0´×ÊKÎÏ¬©6Ÿ$¹Êw=Ô†c;2œ@<ô4}ÑşzÚ >¼ÀÂ««;‰ÛCì¼'¡¡v-S|NqÊZ.'—*éŠô¯4°?Lª ¤¾Î9Ñƒv¼ØÎõŠb‘ÉNBÜ°HíCqz[6Ì?^è	Q%É‘¼ÏH® 'íğ£sA¾St°Äè±`!X){š!¼’«•Ie_Ù@e†ô¤ª;Yw·ñ|'¤¤RÚ~„ª÷ıIßyéY];F:TúÊ0¨ÕDJoâÛ ‹Ñ`ÌXBy&½³—-t¹°[ã²/?‰ÊTg“öØ ØßİØ	ÕÔ3M/;Ò øúœ‹Iôa‡Çñ…§0®5ÎÖób/;u-¶iÇ¡º”xö)ï2JÑf$¯a-äµG~=GOõÜ×%¨°Ğ×õ•Rw†Ó•µ„Š"aş‘<ß:š?G÷ˆ,<‡Û”B3ŒÕ/t“™|«nˆ21fìÔ'æ­·éÕØJ›ö³•¢0#©ûd{®.ˆ{Î Ÿâàm( ¿’¡ÄôSèÔ”Ù³?²‹“ËÔ"2	ì?SÏàrşÅ^Á	¥s×ˆ|æ&@´hô¾Şb‹i
`Ûê.pfZwW_ë%8•¶sÀÜÄµóÍÊÙ›óEşj^İKdM¯	*àhrH/áÛ6ÀŸ<´ëÒù2’×z¿¾N	†ä'm»ÚÅ¿Œ1Ãtø\¼‚ÊeúºGy†e2íhM'œªû>šTâHŸ®@5,£$.yæç²;Ö:AfÜ¦e!Ä&ÕõDlÁÑá®õiæa$ceÑAI/€ÊØ°¨;Åîl©‘ù× ih©ú`Uçëf«ëèÄ.59cşøŒ™'n÷ZÂïÅ-bjÊ‹ãd*}ÿ)½‡âäNÇN<—”Ö}<ËéQ¥!£”cöVôı=3‹½.Ø|O#Ï¿¯£ÈÔã ³5GUL€h 2L5ª†cË:Œ¦IwU2‚ı/NÂÒ?¬¢µ™: Ÿ½ç`uv	Á÷6Á !/©RH¿¶ğúØç¤¯é„V‰jÑß¯lóC©ê|4†ùaíÑú,–97„ºjú±‡È¶èKÌÈf¦—ŸW¤GbËIºÂ¾‚¡ôCYE"‰6zEø²"ª—ˆÏ'T—Ñµ‹$Œº˜x)"8Y2á¬ÒŒàâ±Š_RK+Ôe¨"3õÛµínbÚoÊ”D">©®¿š;¸àŸÎtÇ{õöËK*HT é™øª³×Ø#‹0§Ù^üyÄÖãI)0ÒvfèOfåd.+ui!>Ô4@şñ¤`¾¡÷SŠÿ’dv‚:Ş=ÄìIC+!8)XgÉ-U“&£ÒêÄ",Å±ÉY Õ$T^ÍŸõgëX1pˆ—IÈHˆ~ymÄU(ë‰	%”D"C}Û@¤1;„ˆ‡©$ª½=ÊÈ'¤Ç‰¸P2O?JXFœé®jQ‰•eOÿ­m°§*»‘r^Î@,¢œE§¶R¤8q2„b^CÂ?kÍ}¿¼|Ÿ%&!£)Xˆ´¯°Ê~»Îdhıñ×âÕz€
¹Õ›sJ|c²4ä‡"ıßX]1ˆ³T2oº¦’%7÷pé"€J/º8k|Bç‰™â£‘¼- Ğñ~:Qšî?8Íàä|v–w4BD}ö`%›Û£¹—çíYü§Ô“&9qæ['¨˜³.Ø;ìòÀ³Úz¦!åãË^2k¦GVWıÚ_¯½g=Gó>ÿÿmİq›ÑÎ…Ğ™şqÈ¥ª†¡ª1áÑ•DòQÒC”ÒUµÙYÚDĞfŞœÁkŸiÌ  &s_¤ªŸH„Ã	Å@axøHÎCZŒ`­†Ş;©‡ÊB¦‹í6Æ*ş;ã(ş‚ız;±?ğİEwşg]±L·V¿n/O ³§Bå”æÔdÁÌÉp”M=ªİmuq–l{ö!C2¨ó(ë´õfQ ‰)†xëÄ¿`WzN™1¬£¸ÂßoqJ]«ä&KPU	3
A*…R6GÑÖRbIíƒaÍ)=æç¡@O%…mQ3;¿mô_!VRİŸægë›ª-íÇR­ÅÎWQ-+Œœ«=$áıAõÉ(ÎWxQ¬>R±'Ä¹êüI"3ÂñJ·¤]ÜîœçÔUÁ%¼~ù),.­ÏñgÍ>Ñx-…!ß·v˜¼×iX|´õèÖ|æÑ¤ıw€ŸJËD»2}kÊEÛ=ÂrBO.àû&S< å-÷áˆŠ¿¶u7äG96½ü…¢WŞë‡¶§Õ —äëŠõÖ
¿gÉS«;4Ó}»½Nâ¶#d p)/„ÃlÔ÷ğp€®ËÊœËB3\š‡ø§”¿Ë|pùƒ}j–ÚÈ¡†Ô*HØà…ûY)«şÀîvº)m»0å™˜óçÎ€;msîP-T¹C69¸Ğïv¡w‚8w}­Ô-`X/2®3t¯ö$Mùõ+QÛ¢c<KÆĞe¤5>èŒ÷ò-õÎÇMp‚DkØY™¼[€à£”¼.¨	M·©§'ñŒ›æ &íö-dHrüT€H†R½c_Éİr¢”KAøIc­]Œ2í¢›lJ/dá í—{äAÀãnUÊœrÿM~ ˜ÿvÖ¿-wDH´±XèŒC³a¥}~´­z¶.uSBWÌaşúL/Sr4ÿ,9MïF2“Ø+I²®êMÉ©C­ `M¹<ìrôì½âŒF/¦é}zKÿĞ|N³«”|¥aA­~^”™Í¯ÃDe:à·Ÿã|b{ŞLG@Æ”Ñ•ÃMæØ+õ7yÙü$×ÇÛ¨ØN(†èPA4•ÏŞ=çˆìá‹ÿÇæÒ;Rû†âä˜PòYÎR¬ˆ$€Ä§Ó*‡¸«cÁA°İ]¨(Y±i&à>0b¤Ãò¦‚²y,Ÿ ?¸¥h‘AúQŠªç,:,­Œ<Aßha#¼ª!ÄÉ3üS‡&àª:IIÀ³œŞ²ÑË8ì‚”ÑÕı‡Ğß˜i‚‚ì¥–Ô¿xeúbZV«¡#¼É`~ä‹!A–Ú)i$ 2E£) –E²"M0i’F¸²Ä—7›ã:EI¬s¸Y×’èwz¡z™%Rs†S®‚Îhƒş`0w¡>\n¤/Y\şÖ´#Z/7şù¸3"5	ïU·RxõÌü)äha{ÂqÉ­âIúÆªš›†ÇÅêœ?=ç€¼~Ê‰™ğî_ÿ×ƒĞÈÓ:½e5¤Ã€æ©#xª¡›±[zàçÖÔ¶`¬—uÁ€æŠP²Ë©E½_
fA;ÁYË‹ş™©I¸'Lu5AšÙ·…Š ¤à¬+ì6åSÚºË¸òlP:š™(9ÒQ†_<Ø[@o»…4%¦ñ Ş„d»ºÂÁf,ĞÂ=^İ/öır.²q~nµÔIë®×ğW›àÉ©w\~…­ñ«7ÿÑú1‡ãô1¡rKà~7GÜÄ`ÊYÛt¸½¥¿v‘ƒ¦'¥—º}½‘À1uÕ¼Crpÿóe0ÎÇÎÔôY|]*˜FbãŠ„ò¬pÍÀaÈœ÷W1©lÑ<N45¶™mŞÕÖ]Éw%¦uCàçÛ+ø,é6êÉyéŞrÏV{ aQ\Q±¶ÚÌÇŠ-¢üÙL—(úÎƒÒ²\ıü2Ë¨‹¼ñ­Wšœ ¬ØÎŸ×ö!.²Îenïî¯Î6tq¼À«°Õ	à¥ìÈÊj†ıEë4Î¾KšÛ!ö)!Æ1şÈå@s\BıšT•´ ÍÏ¬tL(NÔ3¶§gø¸ºÿğ]Ú#lùT™	ÃÇüLJcöÇøº®Á®‘¨¨I!  œšù;nĞüß)ƒûkë)<_5ù]
E{déW²Ñ94%2­€ŞxÇşÖÈ½ŒaŒ˜pò¯Á¨½ÒÅÁ=Òhıˆe×r‡´ÅG§
15È$M&#;t¿ÿTùŒ¦Ë‹ÿxàÕ‚3ş7QT[è“1°¥ğÈÃ…ïz/LË¢Ù…¤Äºş0«\âloŸ`úÓG'Í9¹›yı²œ: IÓòùÇVûš/¨Ë‡ÔhÉTş›ß‹´kf¥ÁX[§ŒøuƒŠ‘p*p#q ÅN	µLı4ûÿÌG`ƒ“Ğs“ì^'¯yjO4ûŞcóW5+r½€=ì«¬‹Ãƒq-MY.ñÊiÎş§õT©Iyc¦«¿mû·“ü[\.nFî¦Îq6OÙ‹ù†yŞÉ;éæ™0“æj¦£áß~
cÿ«ƒ¶kéFk1²
ÒëS÷Î¦iÎyy•Oğ(6Mø
ÚĞ9.ÖÍÙ•B¯dmêÍ£ ¼ß×	6 !ÈšC@afuüƒôbÙHDÍ6Fƒ)€Şa™>¹Ô%^üÚ¢ºr'˜~ÂÔÎg-ãzçtdƒŸg(ÖHô»m}Á	¡Õ“·%7òA[e?Ÿ™ÙR ¾mÛ†ì5A–ÏÓ`´Òƒæ¼$û»Ù(°®ïÇ 8£ù€˜³;Ü š1_ëäÜVÚAŒ*ÿ°TV UV{Òj{Ÿ^•‰ã
¢Zs›ãÍS'éÇÖ:Ëı`Á§ı¥¦)HDtHQ•J ˆ\ÛLA,'Oß75ò–h±‚F¨ì<
¼R !»¨"S¹>—GGˆ‚ÖÏİHÅp’ œ¬öG…÷b&Äa4#ëÄË’£Æ±…çÄ\ÿEd.æ–³mQ7a-àRx ­Ñ|àÑERµ¡I8]üÎX6á1Miã÷šŒ?c5HŠaSœà¬œ¤‰ÀŞs<è[`Š=¹l‰:
+—‚F»Òø¾˜{o]²ÑKnWìˆ9µHéwï«ÌÇŸ    	wi7
Å ±¡€ ÇiA±Ägû    YZ