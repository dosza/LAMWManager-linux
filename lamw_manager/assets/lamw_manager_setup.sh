#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2650569714"
MD5="8bc24ac315f3854fbc632de17fef2991"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24352"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Wed May 25 22:04:30 -03 2022
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
	echo OLDUSIZE=140
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 140; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ^à] ¼}•À1Dd]‡Á›PætİDøš¾oB á^Ş}ïF¬—† 6¡ajhGu*Û{°3Ô•S…#´J„ôéÜ‡Ó¶¾×ƒƒCòßñã]}@cdt:¬J'sJ"×2„ÃêšÃZa¯Ã±7ª±ĞŞş‚S ü„á.wÉËö+Ì,Ïƒ;­¨°;c3¿Y‘ƒ’=êÌy+×ÀèÓ?»ÁUØ·ßqï÷	f·{~ü‰úw!,¨m½’ Nò0¶®ñÕÉ§ÆìO™¾šo,D'‡<ÜÓ0Ä)ú¶|Ör«*27Ö0#Z),¼X?¾Ä->¿.72r4'4ºı°­ÌïÁu{Ğ!OE¿ş¨ûLœjWM¸<RÒ/	eò#MG,.Ø]ü7!t³UgÒ åŠ'nûV'Ÿ$÷®Ce¶|—óÌìıœş0ÓC2‡ş¢ÓˆFåÄŸ@Âº’¸,ˆøvß*N‡H>ÕTLgVe­E0«"ô©ŒLjÁs×…5zÅn_9DğZ½Cù/ëgÃGÅ…¯¡äæQ;±J®æt6ûùÀï)øs¶]}‹ˆš‚5[oOÜü*ê‚Hº„h5šcÕpÓÈ‚tl„ÄÕŞ‰y«£ÖÙ)ï÷PŸ ıÔ,»'{ZÇÖy§D—šº°§Ş:¿×bßÉ«/²/yŒA²Ê‘ëãÍw<Ñ¬AvÂÚÂ(A™˜‰ñ8ãì´üw^•£ïâ¸€(¸Ÿ…€ğD(Ä‹9â†#…Zò¾¥¢˜~¼sü·p©‹ëïCàƒW ëŞäPBT)Q[ÄÃ„Ş+ Ø˜A‹z}Ğ–?åóÍÏa±[ª$C´şş;Xû6oƒÚùYÏc•&éÜèL›í™M/±_‚‹)ü"‡o}^1Ò
;¨ãêp=EÂù‰?„İ#Zî¹bˆ“š$øwbê®¸Ë¥Š«V½F$ÑAæ/ø»ª$–8x¤[àİl±Ì=ç†`£±H*’üÂ8h?°©Ô/ÓÜ7/}@â™$Ú…Ãå¦šì¾UÆ—zã°2xôÓ°qw6°_‚â\Ê‡ûzeØ¦Ê^mµÒò8Y¿ŞuãUi¤2ô[G³QœÄóå“äÀÀà&œ¥°„n¾ËSRûDAÆ¢ıw SÃİvÚœÆ»äd{4Gt„˜³&@”]b~¡×Eå¸-ƒº®ç~âŸã3‘ğ*ÅÿÃÓ¼E\ÒgïÒ/Î<C	0Ê”yû?¬ÍTA
®~æUåT_µŒh>œ¹æF’™6’"
d¥u”Ÿ›„[®“:FşÎjXh„z€¶N£Iqoeò^¦™†b“ÎH(âÓß¼¡ÆüşÙO!â	¥¶®æ^7PüÙ<Td¨sÕ°ºm™ˆÒ=®¼‡%wy‚Ò¯çUì½™ÅX‹‹º†‰÷‚½4°£”ö9õ›EGL‹×å jíòx>w€ÄyŒJŠt³Q_,ó$àU®„AÂS÷)¢4vÛ2ğÛæ|e’ÓBjTåEÑğ¶ÄÕ-íÎƒ/C*EugŒ¬í/Œ°ß#3h
ç~MXy6‰°:ü¨No¶•8Îlvœ±æ² çèLU
ÀîÃõèÕ¶şLÌò&³Áüé 8 ï¹Êşo
íA&­sà\AGóT)”ı”F
nĞİ3—øÿN’4{è¼u’¥±õ%p‘ôAz?àÏùWZëQ4I	N(ŞávÙÎ÷jW™†¸ÙiòğùP&Ä½$bÀşPI`€şG‹
çÿKâ"åhfñÉïÒoŠ×“>¡Á¥ Ä˜Ù™ì~$0³İ—ĞlÒ®ã”l„¥?vLõÖ—vºƒs3æø•æw»šû³Ö¬9Òé³Õ;_¸{Ö§
Ä¥ëã»À8À²GÎqnŒÈxÊn” ?Ågişq1íÙ®Cº¢¬ğµíÜùá,hFÈ7Í\zÂ^¹¾’‘°qêğgEÒ&SıÊEÎkOXŒí–LYoíŠ4È"èÛs²Wá1Ií Xö¿îd‡	n{nW`<ÿ…ƒRÕü»şÇ¥n÷66HXò{Íq+Ø%JN(İôe£‹Z“|‹©Ğí¼½ÀÆ“­-@T×vh¬óm,¡îÛŸup‹‚/2Û>ïAñ!¡îÙM¿ğ/Ó}N™hŠ8V„	ƒBŸüs·”Ñø¨ ÏùÒLAq5.VE°µ§ıšª…¨ÜMœødÔ>ãòµZg½æ|õÿû?çúßÕÀ.&³XP@•UÎ×¹{Å7Ù¿ÿ	è/z iWá÷·Êø¼AŒ_AşŸŠOà¹Ôtë³Ë{Zj‹UwŠ©xªõ~Be¸šeE>ëøeno=‹à€ámÑ!
´*Ğ5PÜ—±¹ü°tA²?Vş:>M&-skd­í##é*êŠ¶üœ-öãj7’e:¸TI4I*@ÿTá¨‹«†“(xÜGä1&=À^
€	_(¦¹¢[¤Y
G‰SIïù²¥·)Zé>u«0Şœ¿ó Æ`ÃÍƒ«àÃL[ï I‰VOF_JÎB×ªÙ{'ÔŸ&õj?¢²€ĞÆ— ©¿ÔÙÒô®Lhf¿*³7÷-’Ío•J‘°X© nŸ”WCàmFvfÌÓäúII¥¦’üÈ—öôn¹êãŒ÷TŒş­5úï¨sÚµj˜«(Ë7'N+yWM…ö¢Ôì‘‡×nS•E¾P1~‘k—…ğQJ3Óğ¹/ĞDòykÇÌYEBÕ&_ñªz&ù0èOé>˜t§€7„Br€´“Ç…yÿÓ:Õ`¡%Œˆ
>‚`>ª~…ğá³,Ç­h¡Š¶ã#¢e,
Cüm÷şo±á|éüÈÔ@[†ÉaáŞ.Ò‡Ï”hİi/P¹¿ÑÎ²ÛzX–Z»µ‡ND>*FbÊÂ+=Š¥çÕcáI³l> úî¸|™öÇ¤ÃcL8YèFaL¸H€½!cİÖÄ¥¾Œsœ<&ét³)Eylt¯‘2ÕDai“eJ*Ğ±{«şø:0¬Ø—†TEt\¦ú(ƒq–ĞwŞ*Ê~ÀXP~ÇÊVı=êröÌ8giÂR½nAVeS¾»a,…k®µÀmö„@vôÛ5n…oüHV¢AÒÎ}”R-5qò1v´¼àÿİefƒù-a$Æ©»à€³œÙÀr}~©5w‹dû.mñÖ²1²‚™şÏ¦âÙ2ÙE(2H\7ôŒ®ß]êM6¹ÿ—ãü’êïşnuÁ usĞ¯ñ¸õ~Ä¶Ö„ñ3	L«—ôµŒœuö¹èâjp¿¨Kü×uN:®Öb¶‚¦M,O ö~ğÓHÿ00„›m‹y„ª¹?eõäéúÓ‡ş+Œã’aadÆ¥Ç¸íLId‰R¸B¤Ÿ[ß¬Äİ'r„z¦HúªïÒ¸—E]Rƒ-B¥“JòšyâèLÖétÇc/éš›–Ç*»C‡îd08¶Ñ}âË!)wE:)0ÛÆĞ„ÄŸ »õÁÏŒÕŞÔXFÑ© KbÕj
$¦:şıúû8;Çˆä¦ÓqáúHëf:(÷YŠ¨ô‹·Ad.\T™ruC˜ìye:ÕJˆ­'ú[—å¸8G´xä®¸wç?…é7É÷Õäk[¶¸¿ä÷_vº§Œ£ï7ê_ğ~¢eQğ‡b‘Ñ”d+üº±lcÅº«‘Ué½’@ŞŒÎ§¢ôœ0„0By,CAËN&yù„TNdNHJS€$/è¾/",IR"£§,şĞ0l+ñôÚ6¼©ƒ+?1h (`ŒËƒVğå#ªÖÔá]M|éCØ	Û·Pn÷$âãlPq1¢0aIEù|É4É¿£ÙhB˜n+?º+Q\€?©uS¿mP©ÌTñyÁƒ8KFÍÀ¬=åÑï=æ;5Ù0ÓPoV *Ë>Õ¿çvş;YX£6ñ‚k¨Ÿª¸ş™|F¾|ÿ£:„x@P»Êpâ(Œ@q­…Æ"&´şCFì@ÆTjÒ¹)ÖF:YKòÃÏfzæl¥s¶µ5ÿŞ~=Ü|šĞ§7İë>;Òò)4~Æbü›<™l€Msà.³iİ8„äe†ı ‹ï›Ø8ÜÖ_NêŠÏZK˜õä“Ûp¬ÈÏMr¬DF ÑZ®(I‡±¬VÃ{êf%ˆã>°24_Èöqª8îZ“0ÆbA:ÅEQÓÏB11ı"Nx·8«ÙƒÉ;¿…dÀ¥+ÜĞ«Àa S÷ó®nœ§jç-,¹Bß—.v~×÷Ğ)¤Ÿ³Í‡l¯oÇÂ¢ÄÊ²•†n)‚}Ëo].dN™QšÏ×âÈ+bÙç|Á. jÎV-ª6@£8ñK†“‡™Œü"Ö¦w,óIĞşµ›vü‹¥Ën(·Ğ7¿Ñ“Üf>Æ°ª@”û q*Š‘8ÜÕk¯]ÅLFæÖ…ı¯)µ@j_ö-“=`Jé¿½=¯Bö,ÇüêKíR²šã·ùmÉ}\A­ıÔ¹¥%b¨ŸíxZC 7™6ºPóÙŞîë²¸ˆWT›ºäÁS]'UÚ–7AyÎ‡¿`_ëÓQšYE4ûUİnOôÒ“‹l)",/~I0¦5iæ44Û×+^ <	¹eMŒFš`=h×0ZzÀâŸİËnvö[i1Óñfuµ.ø~boÀø„Ÿ6vúw¤PŒ²EıùùcõF2ˆuUqEé]âê¸Ùâä¨šÑ¤>­Ø–/p ÍTxƒª gÄîShmf…ñLŒ$¾$å¶É&+CŠÉÆÚ6Uûêºê­Ùc
¤}§#Â­¾™xe'WÉ£®ëÖ—TÖ	Æc…•šñ<n½Š÷¤f‡™¹‚^’FO"¡o´Uu-¡m<€n’0’‘³æ&½—D½˜ÛÓ»nrŒlÿS7ŸR¹³/ãw«¦ô$GE¥Õ[„<wW§‰4ôNkV÷şs›:Œ6ërÀ±¶o
IÈmß$(ãäşçISõÈ¹/Ee–x¤c¾`
äsa¤¦íF]q3Š¾‚U‚«/=WYøÉ<MíÜärÖ&ğÉº ‡¦ÈPœ~®»Ü³u:"QĞFã˜¡Œ¦ª‘ÄÆ-[³æ¤âşÜ°Uh´–	Ş	t°ıßõËlM\½Nïƒ2Bğü4xÛ¤¢TÉÁPM†æCVÄ¤Ûôv†º³÷ı6™¨š ƒĞFÅA:º°¢%½{õ}ŠŠü–A¿ş–’l"“ã ~)Y°»Iğ{ÅŞîğˆCsì‹hÇğŒ±Ğe.5Å}ÄI€	“4£í¢ˆÉ(×íáGaóÓZü¿M¶wå†îŒÀÎ¥§’ .sqylöôqSO³ã™ªóÇ"hñp}Sª¡ùÛ7¼Ö×B'¸Mñ/ù¼Ì4¦IÀµ[‚’Ô60½Ştu£”®ŸŠ
±À
-çl³"…™ò“ÍôzÒzd9äœ,ˆCã“6q#	Ø¢;&ø-T¢Õ„Ó®sîw]LŸ;˜nU¸ï«XÍÊ°a©Y]%ŸÑe­RAOTwcÉÏÌ,ûØü<’Ş§Ÿj‚i¦ø;¯¢ç½é¡?aXëöÔ¶;GúA‚BsR0¦¨U$Ôy4O~jõŒ/«Ä—Î6g%ƒ;ÈAìˆwà´1ÍYtV*y.éyp<WI+¡Wâ‘V_y¯U)Úœ´_lafkïÖ(±Í'åóÏÓçàË×¾K¸Ç9!6îFgËúU²§ıË!=<~£·¼t‚uÉ;~åÍ#‚²íkùpæó¦t‘¦µÙX.y>kÒ*İ!ut.ÓıãÍzú‰éëw«U’Å@:ùQ#BƒyÔCàNyõí‚ìQ¯ƒü‘vş xó¦çqyØ{~–»?[9!LÓgél—Uà-}ŞµÁ§ÉJt+áYØÏıÛB&Şíå‹ã-—â|?I˜S‹tïi³¯`ÿ"Ò~`Ôv‡-ø‚}0ü„Ğ|>ù@¨Ûk°¨>f”}ªäxí-´rg]S‚w,Íâxo¢È¹Y;)òÂ5—Öuáó‘øË¼@x•áîä£”ñy>Ó.RÀˆU "¿¢¯–¢©ÙÿÁAüáŒdTàcÊˆFÁhäº€¼I‡°ÙEªã¦6«üë±;’§O<±Mè”•ßT¤h|±™eqL7üf6”ë‹ÒÄšu™/{çë»¥öjB#JÔp"Ë~ĞÑªOûœuJµ'lİŒY°ƒ^oÿ27I‚8P„+¹›ÆŒêCw€@0	4ınF2ÍÈºµ•”Ú>ãÏ(†´ıëF£Â\âQÜÄdÿ`8Œs…¤xÙU3ÁT¾qÃÃ [K4À1û=ö4WíÙ’ÎÙëÉ
â‰ˆÿaK ”°%Kšl%$ö;ièOhÙ›•^é~u2.
¶3Õ•=ÚxQpå.”oLMR ±v¿î¨(yÕ¾©üAƒ?Ü
hZ_ıÔ´9ñº#LEz=rHQ1]Ô’mzÎßŞ6µÿ‡ ò³Ú**Œãe×bpæH‘ÜIM1·àO7Şv~>°lCÅf:×öpä÷tQªıîKMÂ›"’hd4„D§½jë¤‚ÒşB4÷‚
°›2’C?Æ_]jş¤ú¹ç£i"Â§¢R³¹}/Ÿ=mJ„\CùÆ¿æY$Êak9góû©Ú´˜;±¯ßóY>i¡H3 Û»?3-/Ş:AàÓ>ã$	‹¹õ®¨¡qÃgbs£}®îš!¦-{gÎËUÿŞ¨™3›VQÿF>ÆòƒÖ‘RÀ$%Aü-U7æœ—Jœwr¤âĞúTVxíKpÿ'ëŠv‚ÍLN~ózG‹ùşêü™±j=áÕå4\oŸt¯ƒçKVŒˆxõU1le1£:±TÜqùIšÑU¦äÈ_Y e€vÜ\k‡äÅtvàÿôSvj¡’ÒÉÅæAßÛÓ¢9ø¹§H«€²iî¡)âJ›¶{«–©b\ØªœäfÁÏĞÔ:Ñ
¢?ƒ9ßR¤fÙÌF½®şäÊ¢E}·ĞAs•uQHÎ¦í|Ùª‘hşû—Ír«ƒ«|Â<Ù¸²Æ^v÷s:ÈÄ¦AXäŞº@>ø¬÷ÄJÒs 9³¬šDE:g:Ó6ÚªƒL·¬sÿ[î*Fõ”.¬Š'®9k©ÙÊ•“W§ğ^¿ÿ“ãÓ‚SÕ[¹ã`üü¸l%bñ¤·?€O¼RïƒêO¸ğĞ{ÁïÓCLüéœÔÃÜi@]H¬Ø—x;µ>´‹f²9 ãcy•Ê¨ôÛí´>2ÅÃ¿;²Œ€B]Ü!£Ù5VØ÷”L˜U»\WÊ Ğ#¸‰W&XşU¶ÁÕçrh^~À)šåİI›l¶xs:åíyõ,k4Šá!W´ä©ğ›ÂüKW×Ñ¢{Ï={º–#o65õ=æŒq?|©-š=šÑ[ØSBZ²ª©Ú~UTÀ4ˆ'+ßjˆä¼ÖhãÓÄıÌ_zWˆÿaß“3LùEœxTÇêíE© Ó©ğ,GAu€Rˆqôµ²N>çÅÈ¢“||
@dRï	¤·.Ni"Ş›Mrİ`(÷„¾å¡¢ªÏ¤ïëEå “5ƒ÷ÂÁ¢ã“CµBº ;
ÀÔFÿ¶ônË‡¡ôìæècâÖ5éq
ş-şÃXrÂ$ê?ü²SªSÀòFãv&ç·&Ú#døİº­fØ‡ôê˜U3/II…Zp‰—ñ¯ù‡åÅyWîn2m»ÑÕËÑ±a«Iiı ÅâÔvè:”ëHº!%@æ¦p27`ùl74¼1r"7Ô,ÿøx‰Òî½wï’¨ÔòÊÖjK`CÀ e:`ê°ñ…äsj‹µÏ8Ù½ó€V+›Ï‘(hû€5æCgTş›ç#±òjEK›Äª_GfŠá@ 	]6eácbc´ì¡[Cì1»‰6Õ¸ş‡Û\QFşè÷oãHîğçGßjTÃ®älû¼ÆMº7ç†•O
šo	1fê¦dˆ°ôœœÖ–‹‡S“n€~všÛ+[¶ƒŠ³ğTàˆèœt[l¨œ]†¥è’Áu4GÇlË–ùÇÉ¹ÄóUf}„7ëDŠJiˆº8}éWàâKã¹ßR AÆ²ºŒ6ë–ÛÍT¶¬Mä¸éáx[º÷ıcEÎ~›€ÕÖ[Êæk&îİ\G	‰÷.£¤T”†?½‰'‡`ÙU?3(àS‘'qŒZøöıÒ­ÁÛ²×‡oÕ^•õ£C_6Ë³2[Ô6û"D.Ö~»æ¦ÂÏi[\(9{)™oMŠæîûLº »È´’b¦—
#ÊL}±4Ê Ìx£é™X$÷t|º!—U«¸ù"'¡r£‡¢£N÷tå€o?ÄšÚ±Y€"[j”K¥/·‰@³lO)nîQU}%
‹ƒıä÷–‹Em_%Êà@±w×|‰¼Ìd´¼hrØ‘Ÿ’v:$5ËâW>¢Ôc–[ÅÈSñVÀrÙvşrr4&v)7WpıÏÆoÌÊî³@ÀJò”-¦…8yc†ğ2¶P¸ìõ‰;Àì(c~¡R;óÂxÃ¯Ğ­`:ùQ”5¹s.Ò^zé§ÒG¤#±Q‚l¤_ÀsD;®á:‚B9ÀI¼+êËçz(¡•+¯Ôsîs’ıÅ´>öÅ¯T;³óJ«jXŸ‰ô~fqÑàrƒŞ¸nY°_±zö>¤E¸*~¼ŸŠıe9l§&Ïæ“jùşp&é XtIíroÒ;µŠÀIª8ÁS›ö-Á 	QÍ*V2ß¬)îj\ùˆœ­}ÍİÁìyÉ†æÛıÇô‘ÎT°Çä-©s ³4Dùi?Fø#Ïêáq
vF—šˆ:ÈÉúQºäÑ6‰IĞ×dù|ôòˆÃL[ÊI«ş#)æÈŒv/ÎzEU1#+fµ>ŞÁ×¬„Ab­DÙncùåfaÛz¨Ms9o×¸•D`¶–Òñ.¯ò¾ûi›9zïšÕÍ°”vŸDÇ Lì<!¦ËT/ËŠÉ…x²Ó¢îÏÁùJè[Í|/…ì$©ğ”Â±ñ(8B#Ø r>Z¯+…<Ù%°!y2“ ç|²HP}Ïİ°èóFà‚·¸üR;oHí~ocD…¾î/?¿œ‘fB-7E–oéğpŒrúü$ıÌE{BM^ù§ËŠ±¥ô½"è¿_C ]	„ÎõµW(hP¥<PÅ•ˆc€«ÒÕk´««Ôyş3¿ñävçâAË<B]h³Ç¢“DoFI/!9Aã¦j~3˜ºjâËüö|şiŞENAfJ€ÜyÅm™­³ÇX`¾nÙM[ïe‹maËµÀ<³‡£§ ‰ş!3‹–Pô'8YŞz;ğõ­d¹fn¹´„ ˆš­LÉ~k¸'@’DbX/{¤©åíúf£>C‡t¶½. xäÒØîÖ!1Š[âUv&~„uZÔVÁ¯sqOÉH²ÕØÕãGzĞá?Ô¬»,½…Ø•˜ø™¿·“»ø×ìõ.âBéû'N 1@ä;Ö¦oyŸc ’çß'Êe_ïŸYxš‘Í<77c70–ÀQŠÀS¦A£Ìñ`B{ó$‘êôWè‰ôbzy”†B}!	,óG)@†2°$øRïhåı“­‚¦ÃªùúÄÄP%=ßïcğ”dI³3 m÷.×÷‘ˆa"åcöiIBóâ„5“[ËœOçz>Ùß9±6P<7Ë‡Rş.º,Å"±ªŠËBz€?'1é<X±aÂ¼À‚Âhxiş+2î-~¬Ï6±İ·éYåVâI¼ ?ac?ZXÚm÷©"¥ìÖ7µô‹œKêİI±±vx^è€£’Ÿx37Şd›4ï€Yo‚Œ(%<ºr¥dBOº=c“:`ê·8İU	ÙYDS~óÈ']¸–yFXœÈK•¬-›ŒüÂƒ‹õ2ö,³?üĞX¶à•?Œc7­•Ò^xß€¬Ö‡[g	…Óç°µ¬„õ=šK¤Pİz6€BRGjÿ½ÅNâ<$	,Ğ)7×7•Ù&¿Óâ!Â|B[Ù?õ¡íG&(ê:Çö¸3ˆa(èğ×-eÖYà\\ÃéR5AÍæ‡½-ÒÌB/d²aUFCbÛœtt\‰I‰îÌ(Zıt£cß³­d5µåÀìÁ”DFC}†„°s¦!çó6 "=Ù#§iq’TêTë^[6ğ÷ÇÖ)­‰œ{wˆ½¾z	æÅÿ#g´l¢;tÁ~<Ë3€çÙË‘´l<FÌEdü¤ÔãîNQW =Ï	¬S‘Ì:ØMn8ŞâÜ2íş±¹¹¯èhXuºÉZÏñÃxõG†ì £Ë\üJWàòñ¢›…“WÏ‡-)Z[S‚Ñg]-*ªL7hıU@Òœ¤MI³„"	caõ@‹ãA!Q£âÀãBlá¿xÔ/‚ŠU¼ªÙ³WÆ!åBsS‚S¦Y¯>©ØJ§ê7Şë†£)L	Kf~üÇc^Ş‰ÂâãÖ‹LƒFPÖÿ<g×ULÙz­U^®ƒìb#\ş…8Ùz÷!ÿ+àSLüêÊ’_íq¢Æ?rÀOØhZ9Å;6Zp´~ı•ZNiÄ¤ç‡Ikáş˜uÅÔ²×EŒ'õDŠ&njµ!û—ØëVÅ†‚©=«¿3À0vÆ˜òøÄ!!Ç‰Èç^±ØWÂ×á`æAi.ã¯~+~”´÷^»™(/D1Ñ“~º/Ô^à›	ê›sIRªaÇ$8x9ğÚ„ş( 3Kº©cHx|¨ÆbgÔé…Sìï°ã¸·êø…AÚ¸úÎõïaĞ•ä @0dirtË»ïÙ¨=H)B´D‚İÉhp­:óh.ñkjSş<©Ù
óo ì¾]^‹ëj¢/Ù¾$ƒŞ£èÄÎ ™ŞÓvoSè§b)NÌˆ÷ŞM —s¾\ÃØïè4nŞïb¨ó/¶©J[òØT¯¨yx@¦­qĞ´ÄJ~yà¢:5˜	?L‚G¶²{‡×r
qD—¬mìŒÁ”‹ñú]{ø„ei2Kù ‚º*àvV!Kó×BQQä£?½ı:P.Ô3Ÿ„·¯¶£‰ªn…¯p—Ä4…
O8]1O³º’Ğøã 7ÙúÅOWÁéiäûUò"Ç×
bHpÔ.&á]¬ˆËÄu—PyÚì•8Gbš=GÀš50èıatÎËâ"=«C­r@:ga[y[%^‚¢ø_v)0Æs2í›.’
fÿ7èJÚÓ­è.mÎ€>¸ğİ:C[xuòÊ
Ç=WEé£ÜüĞ[‹!Eœ1Á7sKÓAĞ?G‹'«ßN^ËÇ)aB¿£‘zÇ_ïÜè¬Œ´A#%x`~”?ã¤ÊŸŠâ6İ¢õ$hÍÖU öÈ*×Ç}i‘œ]J_Á³GıÂk·ş9ús¿ùË6³ùHÍdLÏÿÛ¼·ùÚŸBåía‘½øÖ®«la1(~â1QG³]¯hxfwìû_¹ç]²Œ'rEñÎãø7^ŠÒ¼#(fùÓ%&%™¯Õ–­Åòø<ê‘q`Æ¤ı‚Aá‘AJ•V6HJ×µşsá¡3ÍÄQŠˆvèwŒ…Ş9Uü5Y‡/zuÇf)-wÆ“€¨e¡ şP5!Ù™¶óeŠğ?V£¬6ô®@ú†c¾–KèqÆåäøâP¬Möüã†²h©ÍÚ0"~óulHdF‚äÄ0ÏĞ
-áÙ@ş7¶ÒI:`!¶‡2Ô²3­¤YiÈµX(å5±qdíš89n´İ0}ÖÒ"º4—ÒT•ù@™5ùEAë%ƒAaE{TŞ2Ø·3Brê˜õÇæG•îväLşßFI·ÊqÙ¥›š–mvÙdhˆ¼‰†šÔG¡lÇˆE²Ô)¸Àm»,ù`-ÃAÈø?úw2¬»5~«{šÉ)c†-ñš´ÁBø¨é6«‰Hó&Ñ€Ì.NgUû\[Z,2`-Ræ‰kÛúY{”w»MB´Éù¥m¤ô™™¹¢z‹_c5îJtg¾¶,¸¾bUœ¢O_´I¥TWuÒ@SÖîYAğ§ásT˜ª™zìÏ£·6“¶aÕïµÀÆ­O^Ÿ >ğG ÂÌb‹ºë¹ €GS;)Ü­>0Æe)`y€÷è=7~7°ßÉú^9ÁŞNÆˆ8ÛlÏ]t$*Jıôz›ADTİœ	û›jˆàfÓfcŒ7R-ZãEv{¹´Zcè¶…ÑL$¯¿sÈ-,Öl½rÌyY'ëû|X[Ù!¬CÛ.Î´äYöH_Voãª’‡J÷b 2WCĞÙİ£ˆ…§Ş0_¾®¨m½gÂ’?ù»8& ,	¦g¼¯Á— ?GÆÄBQ°Eê‰Ø%Œ?Ï£j%£?¸g÷G0º}ìSöDš¨Šà„]u}­<Ãzpqâ™ùıÒĞu¿øË“=].í­Á	÷Ÿ¢\ó-‘9ı½£i”YAÚĞQ|º&M¶¬ö&°ã‹ÖNbjEÜMª…‡Ûn<xËî†(B–OùWå3+¿uMõdC5ëÂ£?3ÖÁ‡`'—5üM¥sY Råuã ñ'ëÍ6ü8ãßšÄç5yO«J}ò‰ém*Şa/¦ëJë˜WZöÍ§ü\´I«~8®‰Ÿº7\÷l•îXH)Åpv]4ã «T7¾EkgVècÏANkPj3L:E*)}„±Ç’]ñß?µĞKM)É«{¤ÒsuAâÒt>€„É·^q6R|›ÔnWfôOhxğ,We—§0º~”JF&£%ÜŞUíúzd+0yXfÓJ²Ã&Ó.%Z_“ÜvÒ=}Áívš\şûtÛMÎ–õô··J§ìy¿«™E{ÕnfYBÒb#c}æ¡[èÅdÁÒw‚<%MÁEHv€Lk_¢<ª«Ä>ÄMêdy{)£Ò–&óéàÅ‚#Å5ÔBR{÷ó«6'%å«ºÀù	ÌÊÂõ.fŸVhq©ØUaS\#ÛdÏˆ¡r÷9œõˆùm6‘j.1qKùdî
†Œƒ¿¤¸^#ò­IbŸ!àó˜€üÆ—¨¼ƒÁCfç¾kx)í§¶ ;d‘pöx¿9ë*`jßüÑ)ZÚ.Â$\Ëü?ü§À_ùAÔæÀ@1rôLs_æLİw£à*aŒÂßQÿÂw¸"ÜGªvt.D×O-¿`íŒ^}éóÔJSºn“$g
‚b£‰,)z-_£ñùS×j±T¶xÊk™—0Q<ÀG{v-qˆT/ÄÙÌÚQ Òäƒõ°H=ÁY·rái,hQá\¯O?v|Jÿ¢Kk\ßÎ=7é°±ËNø{YG0ß¶pîÙ;@¿Äò®-³â¥Ç…®vÜÊioj…-8ıæYep÷€âFé£Â\l«!‰Œ;ŞŒ´›6|»]çFéøÀÂ))w“ˆáöıˆƒ¨†µé¥?m^H5Pº§D®Îå¸Œ`ÒV%ZÑÚ´ £­‘9Ö÷İÏMn9÷<GK"çµhãbèÆùİlûXi ¹ÔóaÚê‰Ù1jÒîüC”€Ì¿Õ		¹À¨úpwuµ3!NVõÆèÏëŸ›cXÒ—?¤NºT37‡!‘¬ıÀİn¹à%,ĞÊªLØºã8Ì¯ƒò8é¾ƒ)NşÅÅ¤ß ‰/${¾™w/^˜ùé4UYŸìXp.û‰ÏñzE=˜$Ï¦¸cU•±f!’mÌğt/b8Vãø.½6èØw³BDxü2VIxšcŸ2“'†Ñ?Qº kLËBHÃ§­[ÙpkÜW¤‹…W7òzğ[cJxQİ:(1ó÷dµ–ÿ£RÁx"±µ²1*qÀ©Xyq´Î`Q¼3:Rî`€ã·˜°­«#ô…*Şç«AÄß2òKRX$Dí_ ¢†W‰#'ÚGj
$(ªƒ\ tQ¾=´è …¨€ÅıÍï‰-/„_-{ëg4”@)Ï©C…àœçy T×Æ†°±)‰’8’‚ğÇ?9ƒ;Uq¡ãúùoàgah„EÊn£ss~«E”Çã¿Ïy•æ?ÖBûuJwÅ`·Ñz¬|Y…ì<I»|‹Mè9î?Ê0È£H3¯db|„júİ}œ{…ÿUIâÜÈÆöÿ…ÚN¤KİMUÄ„e0Jø.W×;º‡0Dp!Òhã»Z§¾ t”·eác‹
Š[jŒ:£le57ÎJrïX&oêÏŞMÇWŒ’º=Îj9ú’Vh;ªİ3öU'ÃPo-3¸£ÕG.èÅşRÂ¹W¿ªWPez'Ş¶~¹Áá/Œäß·Ğ=Zf³¥Š|ÀE¤˜zûè*v÷Kv,[÷²t?èÛ5Ñ$æF>¸9ºrÑÂG …0>z I”Ù÷cWi|õ½“êVv\S¼òeşø³÷oü>‰óPmGPõ>M3á·Ïy
ê¨%Ê±‹º8 «äK.Ûè>"tFˆ§@4–/nâkFz½òñŒ˜©^’×ŞÍ[4%úTÔÄÏ¿İK.ˆââÈ° Di»‘yDmó§Úé7ÖâzÂúCÉ·sIñŠ'²5h!u^–ÄÑCs
ÒJÃg<xÒËÁlìĞÑM‘2Ë€/^jõXò‚C¹~>—I¬…?Å"„Õä>é³àÇÿTdˆ	-_®ù‚ø´#7-ˆFßzU˜ñ(W>7Éç8h²°Ó‡}'ó3'”>WÁLaü×„/ 7¤u|\¶'wÄ±aú„Ãa(0å,ØÍÎÆf~Ä¥ÿš#Õx€êO*¬lÔ {…Œ*éX?½øJëK•°H¼æ§Ä6U„Ê+ª‡ÃÈ6_vÛ¸Õ(„ÆÑìæ³[=×3ÿ·›g×&n®“·Ø<\Iü!b€ÉV¨J¥¤|‚E1Ü(7Ši@©ÀõİH‹7à&eIÙ3Bµ“6ÚfÆnîµ3i	’jÀ×AcËĞRO£NÛY^tiaØæ…UÎ áDçC±»$UàÍ_[Û#|0ÑVÄ‘Ç‡vîà]´Š×~¦kC†ò¶ïB·h¸Û·/},´éIŠF.^/\eæéc•š_©,V&U3¡“F)K7ÇZBkSšĞü*‰=g¼ïÿƒ­`aL®»‹fù4)›mêêÒ~×b!GHòh à‘ÃGmuy©q Ü„ô»Áæ#¸†móhÁƒ¶²’#ÇÔÿ6•l@‰3Šg²¯s!M¤Ü„ı";I%åIüøv&¦_•ŒĞzLU¼ÆÊ	‚ö$•Áüôö6W»œàN&l‡Hjj-<°{¢–ázÜÔ¡m°áÂ
SÄnã¢‹Ú#\²ïA1Ä­ùÚ=©ø©>T* Bà¸a»^„ûùzTv@oÎ%•Ğbq´ßÆ:|œÛp³[¦„õïÊ­ñûú¬:êœwUÖî?ÎÊ-İÛş^*\hÓŠw ë æzmk-ôòÛ$ÖylÓZüıûçN5èû`wAMS¹0E…P¢[	@ûDŸ•øê»!	e'óÚ6p@ÙîÅC‹¬Aç½	#–úŸ@Kfï;õ£õO ªH`˜¡Åæpá†;P¡òØı2!eç–×Õš¤Ô²Ìtÿ:öe³æÁ×^N’{juñÈ=Ü(8¯2å+'¶ÉT0\tï“‘®z¼Îš.ÛQùš»’ıI_
;öŒ—êUƒÉ\,…ì0CL¾ ¡Š1Sr"6P w2• ‰\ú}y¦~›Vz‘:÷?¼
À™g?¦æUVc	…ãxBRn º4IÏÖÀ¨Šl1RÒ°)ÿPµfÄ}œtIkPC#¸6¡‡òuBíí%sª· ixd.¨0÷ôÜ16 Öí¨E…Èëî¨Ôí¹¬š}¶[SWtÇ®ŒòØÜ“·óYYË …rJnt«Ñ}Ké@<ñ {{ï‰0|	™hWT°sïVMŠé±áAÜ„Âv1MÏé®jS«®İ£Üf}Ùxh²ş×«Égé}„Ú¬'»~R3:’ÔMS1ÚY"Ô‚ë^t7÷ıJ·5ëb§ÒÙuséíòUd… ‚ÑùFÀîêã2g™:d kãœ	#ë¼y?³^­lvYb<™8ÛÆVğ>=%‚œP­ŒÚlAÇdÎ[’’¸ÜöÑimÙïÑ…˜õ^µ¿ğS²ªõ¹Vhg İI¸Ù°${ÌK9FŒ(¬Ÿ¥"Å,¿q}Hg~FÚş›Ô|[]îwPÓÇ[?ÈXq£
4è²„Ñ±ë‡îgæ}äÏ)C»Wìt§&¥qyDD2Rt› uÑ}n¯!MAb»ÕÄûä?U(gZz+N¨¸@[Ä•Ôt,EO<LTãş•%Ù_"Ö“¬6uqÎ©Fcn 1=_Ü²#Şw¼Ğ}%g-O¾\% ‡ôûÇğ¶£n21-ŸZÀÌÿ
$Ú81ZhbY4Ã0Ñí…JÚ!8,¨c‚~ƒëj-Æ¹ø9–Â¶1¿K²G/Í#’¯Øa¬`&;NâAÈ	æ˜ö%m²¦Ò¡·ÊIÆæİÄ¢¯Í&åõLYqq‘ß*À”‘î¦BÇbnò¥Çyl–'qo÷$_„~ƒuë˜±é‹åL‰8}œ$ãñä!F`è`ˆ $~×I²ÙÀk©“s~pŒæ¹¿Ì4iNGÍö#¤ÆÂgÛhÍëº~	VA‹š8Ñá¯”ğu³-q8°İœT&…ï%¯èÇ+:’`|ai$j}¨ŒÈ‹ìÒ†L”ÑZr—¢Jnx+Àepi•gü¼cƒSDX¯AN®+›œ¸{<Œsi^ÆL@SÛæÊĞ;Bµ÷R*E05‰õZæ“C‘¦u·‡–m;«q"¤±½5Œ>éZÎI[®Z¶TWWŞñPT€ÁŠO3}b;ä	îœùüuD9Y;~4½Fp†«‹)ÂgouoæÄ‹)şu½Ù±Ò†¦õ'XÜ#sĞ70ûÉ¸¤Mã”ñ@zVÚ†Øjw&S’Ÿ Šê‹%jüÅV]wÅXŠuö­&Öö‘è/lk?Qæ¹çm‰rÚÇñ †és} 30@è‚i¼ÙEzÍÅA†%×	òÍÁç×¼È]í‡ÆGlíj V8¹8›µµ•k.İæÅ,|­j>$ùÑîôø¼«œêcg\s4ü!q?,ÑMxq|°ò˜Ú÷^¡ĞÚ |ôòSÍ-®—®¢91jË*éšO6ˆü—ë’4l\Ÿ£À´Æ±¾”jw,H÷P‡}1·Xçzµaäjƒ`)X0îÂéÌ;ÈöÿğU­["ºÂX³Ş Úh‡ü½Ëòqk1èõ¨'mú´I0èÁ¥ÏDì­~È“KakœòõÜ8a÷‹TÆğô”AyÜ@ó—…Ö€K[P„¶L¥Ïé×ì öoî´`ñ­Ôì¿×†úN¹üŒaJ&àó¬cÌ½í"D\%*;œpÂfd/âÏĞŠàÍ…ë|Sˆ˜
Ï°­ôÑFÅFéi•ƒúT'V¢-tô¸éO†›’ ÚVøp±P"~yg‹0E™=9˜ú'6øS²¨>á”R°´aKÇ¡uK“ze„oØ<DZ7°[1Jj_iaSØĞåxä“áL¢î0så?ù$“ã-Ò“Ùê&hÆ>	aĞLŞÒÓÊ­ÅŠÀĞÁ|:&Ïğ_|Õ…æKĞ¾)¹°ÂÃQ!™„»:ıææÆ­ì–zÒÙ¢yÇøVöÀ É§Å¬Wá:Ùx˜|2œ(š¿Î·iƒ¼
û[²ŸG^@×‹l¯ö"H—
Yc ¸qâHÏíŸ(¯hÕ“–An»O\•İÂØC4çgòÆaeFàXºh½¦ ¥Ş ^WÂdiİ(4&O®©‹ŸÄ|Éiv#ïãz¦9u+»å 3†åôüŠ>ÄNÄÒÃ—*'½m2+«‚Õó†°$ƒÄÃ•Yšäİö†æöÆ"ÂOÕ¶îJ„ñFÃ%XT@
ıP#O‡‹vÙ:NÇ= šÄÇÉ¼PØ)Fz/Ë·ı–Ÿ¯k¹ÖšwJ˜Ö98vt0õ¾#gÅÂáÓ"zØ«Õp¥%QZß8D4Ms}~NfıXŸ’rOPkšœıIÌWİã·8¹“¦ÙÕ­‚ÓV„$`KìúLÑœéÔN€BI:7ÓßÅnHŒĞBSÍÏ7Á†Âaí"QZ¥“a°°ĞHÜ4gŞ„Ø\½ø`ÄÜş0’”Ì˜“:
äo&¹‡O‘Rb­•i$U…€HùÆİ±¶æÈ"AWÿ½Å˜y-åƒíi [mŠ5Ô¥øÑ]ˆ>·¡³ô•½f2ûõQ:–ï¾¥¼¶2¯‹}ï£$“7Îü±Q–#¨Ö+‰Òi‚È¸Sy^ÜS£º’&cYÖÍ“Aã‡]MDææ‘5òq3ß©nbgëÄ6n-SUı%µ˜´ =ÊËÑÛz½¾Ö02c˜í;mşbÊ‘5¿ˆ{Jkå—ıÚyÀ«1$4+’ıKÄÙ”zûè‚xáÈú ©nş/Ød„Æ×³?³~¸8$\1ENwşë"3A©á úÄëÊ¢Uš-0¦A¸2ëZçÙõpƒt@àÜoväl6»Åİb¬û3û]ÉºŞÁº	@c„µu#S’S*ÿ‚é¯'3…ÿ¢±]tiU½Vp"o6vû­Ğj~¨Ã%$BF¹¦¬Sà^ñåbg×‚ãnÙÿè|iĞ×K@ıHx ™†iFíÍaü²p ì“‰ªTQ£qtûà.)ìH29›ªg¯¾¬vo½¼md‚œtæb”âÙÉ•;X„ÔAm]„«¹å‡X-c<^rmmä‚§Ç0Z[¦Ò<¸.0H¡Éy–Ë2q­‹Ü0 <œ¬èÛ·ô- Ğ/ª‡¢:“êÅ·Oî‘»N+:YU|jz[Òwt	üMÛrw©$ë¯;~¡€4v“+7ítWõUÏ«³.?¢ÊÈí‰Œ¸Yé½Ü*e=K37˜:¦YüºÈ×r àÀ:©+‰@Å}rŒ$¿!‰ë"{Ä‘3Ì•¿¡4 \ù“’†Õ®8Xª¯ïmÑóÈ)Ä5=»!¢Ê0¶Ôwh¤bÒ§JAEìcÍc–šŞ˜ôG¨ìQú2~‹(]iå5b‹Ğ¢åçGSƒšğw2ôù{àİÜ‚@úìŸ.7¤ï+×¹cº‹9:¢şĞFï™É'¿¨îÚ‚3÷*¹ÁÁV1n(,lMv¤çã÷ò$Q!ïë‹<{öxvk4˜níÁõø«Ül&v!ÙßÚf¿6âÆKgÉ*ï?Èş—‰ó®dè®Uš fyˆ×mü§ú°éitÒm\+<&¶´Â:bÛ&T5%Ëƒò(ø°¤Îä¹C”ræŞUİW¨1Ş€ÎR†¡p¯¤'Ò#FZ|zIŸ³!$ÃÖ:SÂeæM¦Ç#JÂZØ¥ãÕÖCCÅ²½bp½¿¢j¯P[¡JX†äÃ°‘V†âèÉ
Ğµ?CêóE“ŞuÒ'’ÄkW‘B]&æ a“şâiÏ	6
›ê1,¥Q"Îeõ„+&ş!¡`Es’ßX ş²vŒ ¥€ò£Sq* ­:ı×¦Gv:jXD<öÂ“¸â6DeÁÆê^ƒıÙ·Ä›Z-¡²;FG4¢)ôl6fg?Ñ(”„¹Áß–Î¶Ÿà|«B!*)OŒûúÊkqiê´L»m¹eW"·Ó¿°™ğ ˆëô-¾­wb]w=ü2”`]'÷PV”áDÁË7w-ù.*ş¹9«r¥OPÄÁä}İéfûøj×•Ów©ù<ó]¥~I2!Ö­Ñsğ/ó×U¯D_3U±²w¹3§šÔñ+©º²_zÆ`åSí‘Q6mtx+<4ÂÇ’˜ì2ÑPğí¼’,7F}·Ï—÷é‡-WÆ“ôÈŞKûõ~c„R¡¼OÈ“ZYS}h$”1ÄB+M1.gÉÙ±œÁ&‰üÔ£µÈUœX<ÕGVŞ³É˜k7‹Ku	äŞš»úQmf&’šà.‰Gúy=F4<çqµöaÈV	àæÍX¼(p˜FÏe“ë•³ëó9I¨šÁq¢‹¶²Âõ;Õâ£ÑC‹¤ëÁZY$†–wUÜ£‘ªí„¿=d ¬¼#{±u)XQtà×3>¢`¾¶ÀLê`¸*FÈ%BAº¼jT†Ó _¦ãx=ĞãP­£Á?Sv£¹Däë7ğ:å£6@$»}JVôÛ§§KL-&r¿-üJ)ùH½	*s Œk’¤X™‘Ø!ğd*å£é{®àÉ¼nåÖ­Çpx#Úe¯‘l »¬4Õúwølq¤Kï ŠÂ„‘\H^] ¶¥ÕK`‘«#	<}“JC ÄÑgõ°ÃÅ·ÓetO­K¬¾ĞFİNJı²X^}]!¾²ù¤/nG­Ğ:ŠèauõÓkìÿ±İLqÀó’Zp¶'28…´õğ¾Aë2™t}cã°lÖDß{¶×…ÙÖ¦rsì£.Eã¸>6İñH#šõÉ.C™¾Fbô+…ÒÌ¨i†æÄÚdï-‡0BğºäËtóüÖŸÒÉoÂÏ¼[ª@¡_Ê@V’L@$o¤käà#À¾J‘L‡²ö"¾ùJ;úSõ’O)“´š`r´ØP´äªÄ+­qÀ`…ÓÎìê›ŞWT8»K|tĞ`à¥ÉçZdë9ßŞ_¡EV”@»		ÍÇïüMP9]$0«tcµ®—
x¿uGá5Rûù†ãu®)¯F1võ8Å‰¤'JXÀatÇyM±òîjÊ@tX¬oTåJc¯šy.™¤$¶m›ŒÁ=O£kÔÆÄŠ)ÉY¹†¨ä5ûöú?$sQû³£¼}T#Ê8ÿ•«+"Dú
¨íS®¸wår(ÿÜ˜SCÿ^Ó¼¥Öé©‚*K
[±ç¸aŞF?„ğÛ%8C‹$Ef%Ó˜vx;è¢-tKë_5©pĞ²T´Ò*:«·ë{½¥Í<Î¸4É›É*]?Ô12e4~ôú¢“Á`B[eÓv¾"¢Úá4—ká>cÓ4 ÿòú©8ÅuYşg3BE÷Ç9ñ¨f¹
2Üæ¬ÀÂrvª¿x Üçœâ+<å-V^Äm÷cıpƒbVO,×¨TµEú&ãiÁâÑŒ¡äÈğ™õ½üNEO¿ô<¸ ÏpÙÜ!îæ“€ ô]àhn:ïâØŒbI•]>|OgÃØğdn³¬CÑÑh¤Å˜×Åñ<ò$@Uƒ§TvRçØ¥N:2Ø¨c	íë[¾%ˆ4÷ï1äAòÂµ–|¸ñ©˜4?Y6(r™˜tÿ£*ğâË¡?Àƒz÷iÈ7Fgû˜5ä¿—C™ï‚Èƒr‘l®?p—šRFo×ƒ¹2­!¡œ·ÛeÍá‚VØó­¬ú9EzpÀ0[D–nY‰˜Õô`6û7‚é:pì’|²DSH‰”AØc?8™`9ş°ñÒk¡Ç2ÄêÀ Ön·È[Döbø%£‘œÛÿª²ÁH¶AıPp¬NbiÔ=,HÆ «Æ/á,;öêøÁ4‡Ü8Kº¤ğ@Ä³.Ú‰^·±‚5#{Ü@5)ˆBÏÀÕ')êÚ½@Ëcz¤”fşØm{€w>dÊ\‡1¥Å¢ë‚ãeÅæ®»ªLMkh´¯zÇyX!ÌM²¨B‹â=õ;LÏ–»’ÄÚô­ä³üÒÖğÊæïˆZŞäø÷^4çÿõµO0fwsåX¯ğ;Ùµí(â²ƒr4	°¨I˜n°‹é[£Àt¹®¾aïAoz÷”B„ŸÜ¢ãvo l‚¢ê¡è?R[aôôzÂW1ÔucdÛ8tİôòI:
ÿ~¿gÇˆWÖi®pÚ ~7¡8.Q)‰‚uQ2•
ŞõÉŸYVr¤‚¸H´Ğ‚ùwÄ,ÌBørÿ‡F*Hyøµ‡‹¨xÕøQ9â„Öçjut A±ÈºÔš;iËØ`ñFC©*(•5åoÌš =û9Ö€p[MD£ïËï­v(M%\ƒ«|·Uÿû“á»qGDû§ã¡U“NŸ‹»bõ&„³Am"?Cƒì^Bî¨(æ"€—Æ¦õoiM¸BÒh¿Í5</½ùŞ°„L_yòÔMqŸÊn‹±N·L ÅË '±Äw–ÂW©"ˆ5û=©X×O˜kS¿jèÔÇëóÛdÇ‰x-áÙµ“wóÅŠ-W‹ë²V¶ÖÒX§Ûş¼2MPù˜¬<ÃÆ¬&£TIÜôpgŸ¯hrëê¸=ú“l,æÏí
~>™ò=™­o|ÂßøÊ›¦OPI@I§¦z`) œ@˜¤fç©Ô]ê²ÿø]ïu	Ï~pÃÕğl½8”sÎµB™Ğ«ÆÅö´?xª )»Ô—„¢&
~ZíÑOºÿz’.~ğ”ÛDİ+ŸÆzõçÎR
ëˆˆ—wÂ-ÅU'a-$5¹£ TƒÇ”£¶®Rö,4¿o¨2¬³9$¬a¥0·§ïK9Ïk6òh!P˜?e‡\Q»¦Í}lVfÍS˜D7¹uø¬°¯èŒï ƒL¸.«É^úq>Èò!Ù%hgŸHƒø õ¢8á0agœ¡è"±T•*&\öñD ÛÈ‰Ô&¢,qCu‰ZwÊn¶Ğ%*æPúó"WÄÆÌ<ìoÏ–¦Q6L¢5áŸ„È3.ßc”Ló_™ú3ÉÁv"Ì8ÒæñO}f§E@şê²„;ƒÓäôqµø,‘44˜·Ûq¸”‚Ü	¡mhªx¥}„»´ô#ÿ.u:Òg¯_‡±fƒ€ßº0!T|hÅE;c‘ºÄ¬’å›#É3=}Šä„1="*®5Æµ0à¦¤êJñJ’·:NÀá°ã×
Z²†ÓêÏSlZ5îVDêåÙ/évã]ú5ğñg‘®øÒõ*ût¦ÑêÛuª>[¤"öˆBéh¶H¿‰™‡s¡,™İ¥B+nøæBk„‹Çı¯½|\Œ¡ä¹øäDWqóûÖ×©´xİˆâZU…:l	|d±…™#ÄUD2«z}?ŸÏSvn5ùOû‘~…öéş2è}ökwhÕ¥|S]™uİÂo ù¬‘1ÿı)‡¢É×©dnu;làŒÁ†O¥¢¿[ßtf´éµr$ÂR÷f²Rçx9Nàp°&M(ˆnxT.Ù"sˆõ©Ëí˜Û¡Dğâ=hJî1|BNâşƒ2iô^™="ÊLë\­'ñAŸªkgùš4o|ÉîÎªì®+%:ûfÉ:¼ği¸9õrŒ[RĞHÜaµãöHJaƒ¢<Ì°ÉûF˜-¥UÕÁYÑOıŸ‘£PdpçÖ¸Sü¹Î¹Çûªüİƒºõ»¤æ®Ç¹:®/©Õ2¸JN­CmWµFõz©7äf÷¦÷¹]„‰ò0:œY İÑEİ`â—'4ì[~jÈ‹°ÅÌeæop"<É®Ák7
0 ¶‰à´6vnóêÄ3ÊCÁç«˜[Ë3b[q•V2õå2ƒ>ğï(…;òq"æŞR`âO“^ı0G“ÈĞ¡~‰Ê°áİ#`Ud˜mÈV²ñâ‚¸²I"naHG´ZH6j%óU3™öAÄ„"{<é×šZóoµN„$AÎ/0ûü_Şuİ¼ç¨
,à>)•ø©Ê@hóMAS½dCUUjO¡à‹hÏ˜´âÈNYdjt° ÔbÚ³¸yO(1µl'Wš™{óBè}¿L Y{œYa@2µdö Òg×Û>P Ù/îb½Ê1ßyeÑnÀ¦6$]ÆGNG@ ÍÎ¹ÊåA¾¥‚è Ô³-¦ ÔÏC¾ë:¬CÈ‡eú	¿]Å¡‰Jpğ5k]ü§ÙÊò—á`Ç0‘¸z1˜góç„®Ş¤!"côV/ŠYaE9(7uş€S… Cì¯!îëT ãşç½®/6úVgßx@ìÌ[œ6øßVv’G¶À´wƒÑsCÑÏ…›×Æ‚ÿ*TVË}"x9ÄÕ³TğÓX8’U(‹cªoí7/p{?•E‰hİ^G6â¿(†AÌ–ŒÀˆ´°€{¥òh…Ş*LÀôÅú.ˆÑØ ¿ÏıÄ"üT5[5ˆòÒtœl€Ö>Ä é¡P±:v÷%,n‘‚x)_Înô§Ÿ*,¯¢ğ°]—×±3uããå¨wDÅl!Ç|çéÉ*%”ßÈÒÅäHá4ï;Îxñœ•üA¶óT$…Ú,_oUó9+Ì:aÛ>ªmØñ	ıŒ¢¥Á“0´Àµ²R|şp|hŸæsZ3çr·=N×Põ]ßß+ÂÒÀÂªv@‰â—*¨ŠåÑ$,CÎpzq“çS¢.İPÚlˆ¹îŒ
-ÃÀáÊ})¡\¯häÇ2I ^è'Ê²Õ¼wÃÛlÌEÌBM>…|Àú“&Ú¨Ô|!f´ğØ8ÀuQÆM%Y‹S˜ãş¥Îì4ˆ k}î„†* ëİy…êõ ú÷Z´¡ÎE9§²÷‰TO²·Pˆ^,j¡à†)×<P×èU‚¨“[©th}Ú€µ^4³¤ªÏ™2ïK?ºÃõøšC¸«±B9ğl™"àEÇJœA*ÿîy«éûîÑ÷2ëÏ(®\pE.­÷ÊšxoXÇ‹ƒf(Ûjƒ%ä¾cÕSõÀØ˜&ÚØH {­Ö˜Æi«b©;ÿI£ë8zëÄµ‡%¬ùã…Ÿ_¯r­ºeƒ{Adó>ŸS€á“¡Äæø”Ò}‡Ÿbó³Ø0yÇX'vãğÏ–hb$r¶*ŒiÎ*¯-ÄoSY’NE¾—.$|
®Yd0»­%åÂ9ëXHjÊ|é)¨Á8 Âye|fÙoëŒŞo„z5°?‹ãîS³´9X*«L¥súàå®Zû)”±]Ê`¶=\bÿmÏùà‘E”²ƒ6Àø/Dº×ıï…ñ*šo ?sÖ^
w_ÏNŞ‰——²¹PS_Õ˜Cmî¶Z0ºÂ9äJ
Ó,–£=CnªÈSR&ˆc\
0h<öDcÌ‹–Ô,y“oIXƒÛá¼<À’H×ú(j^,äÌ‰oÿ»f_ªVôÄA`B×©˜ó}2#d½ áÄğTšù\í³'~m—
Î—¢Ô£yã|Ì<?Î¶ã¢<kÅßK1Jb)‘™BOZ„N‰”Lô]õ‘“Tƒí®Ém¼ÜOÜú]q}x+g>÷ÂKyNQI‚æÓE×ğ›Å$åsÆpcïúƒÎÛFVYo9[e—ÎMÅíbnˆ?•ógúb}~ÆÉ
3[çO˜1Êİ£Ñ¥µ ØŠÖq;,ü©¸ÈˆpĞWëÑ¿ÄÜÊD"w…~Ò²C¿¼}&™M€zƒ×¬vşmPØP4£¦%íVùL·u°Š=ˆàüª³äJİÈ¸¡â‹ñş¼¶f¢Iµ†óQœÓYnö+ı@ÁI1ñr‹ù(Pm^¢Ë¼°+%ô5ı–GKàCèïa®÷á	ï—^É½OÛYx+İxb”"ƒ8ïÅµ<ºCe:ºˆÜšÂ,©à…Òû’ÆònÌbâšñ#õliÏ¨½,äo—ô¤»XqØ^€¸©ME]ãİÆ –;õ1m9âƒÛ¿ö]S ˆ£>|I'æ÷Æ!W_É¾S¤£¸=„E´µ&[1`qÎ)¦‘ÿşñz«¯òLÑ‹+`?ÂD½ı¤6äFØK†¤+mêçéæXAJZ÷€‹şºêÊ3*ĞQân¨d¦•&–£;ôº÷gÄS^9_òM<£àáÊ›F³ÅCŞî¤¨.ë¼š£ÌëOÌ¸×	6¾Té}N,õÖÊ]—:%/€¯[B:£Ù”+ô#¶s¥58ÛŸE6ggé©€9M’UÀ0ñœ'~Tw?\d±~¯(ÍÇY`‚©G¦ØHğÿD¹rjÂL@URí‘Vàg+YõÀ;	4_V.İcì¿xgW=:5šóR©iÍG}ô9E9¦Sv–¯ôbÿ±¸Û¿8aOµM#%`WqTÕ¶âÅyÒ¾ønhc\%(‹T1ÓH Î=Ø}øåÚEˆŞ—çX „w:*Gıü±ÛÅƒ5s“!D97‹+e”„·`Ò³kB§æ´ÜÃåŸÒ¿S‘<å2‡«ŞºÚª3Ç»F+3^3¥k&ï.ì™U÷€lCØÆÄ†§%ø}xÑ	$ş‡ùõÑşW¡®'Ææ4O;ŸgÅŸ •»Op •IJ1¨º×ğ†@DŒÒ‹ğ0†P¦k.S™û‰ ×çàİ–r½v–s”0}†Ÿ?æµX{]û–!^Ö®µ¤¹Üu7…‹á…Œ+Îº	C È£Ôşwd5 ÊTÓ\,YKÚkƒ°Â|BÌ¸aó¶‘6 ¦†ğEµq”z±õïÉ¹dĞQÔ!¯uE3¬±Ü3Áî£ä#Õe§C{6óêz5 =CPZ‘»"Ë\¦µ¹F©NÏ_ZS™o[¹ªÊO4ÉíEş?¿aÿL@‘A¹¸¤©Oì Ôbg-›éqvøœ•ñ†¤|¯P€°ó)ØG7<ÛbÙŠ6bzEÒì¾9¯yÁÇjå²z/({…‡R0í‘Áf»ğî@´r¯¤=Pww­µËLédªL„Ã7IË¨¦(Ê4ªeóº,{üJÓk¯ÿì	€½^NCsŸÂX¢_F7vEƒ?öû¯‘±–‚\¿Ê`Î›-ì§ ’Ô0üT?Lƒ“×•İ=$õ{ü2Ë#€„±r™Š<q1S•Ï,YKE‘"ìP8KV˜Ğ-lÂ1éÅ}3¢6×¢kÖ_2ù;şYúOÛÌ•LC¿#¯e¾$KâRÇ„ßÆŞÙqlgìŸr=wdÿEeCmxvsP–L#b%ç’C a¼8Ç6Â#æ½R$şqØoiøOîY×€
¤S–AàÂK×$+!)Ù‘é¥Õ¥éTÿóÀè»#ASxïÌ°‚İl/i<&¹Ã[ÍÒËxÅó¼€(2JÓ›Ù×Ÿ«›x¦ßá<'‹x*£-Tešõbë<æ©\}w7°Ö•<°Ğc³Áf[¤ÉhßÛªúwİÍ‘…WğWt8ÍbfîÏ}šàéMŞ¤{XQ‘£–©¼¸í¶‹^¹­•râ²¡¤K¢—È™	l9?Hœ	é¸9”	)ƒæ¨¬:‡tè[bô²úä-—hæóCSÒlr>óœê5ùànİ¯ÉÔëşîJ±œÍ‚k?Ñÿí,¶MÃr`´ã®^ËÙ‚@ªz!½™qØYñD¾·ÒÈÿCßü´Ç{Rõ=SK²jØsÍ"€!á„Dà#î•€QYÄëy9‚Z/D7ÂL¡pVy5ÊO¯àüc·º ÃŸËª#€€@	(YNbl)5Òó3ÓÛgƒÕ¿²ÿŞ‰şóŠhå á›à"íW+QÍ¶HX#É'œû‚8_¾;˜şâ“ôÛ4'ÅÁG1/ÜQ±PÆFÔ–ï!Ô~éfkÜU„èoŠ5¼Vv4n£0{Ê4ó›èm¸«¯P¿Rs‚7¶QCÒoñ=I¨@mşEJöûÍ_)¬ìg,‹s	Û`äËF¯{" oO­§Ï¾»nÊåOà¼;iï¯Ònéh‚N5½lßFt³4ÏhªÇÉ~9'iÙ‚¹b'bõ›e!‰H£H<tërmØdáGxapo‡19ô å–ÇÓcÙé¦HI‚[“–:,•O¨©Ê´×ÄÌ‡&­Î{»4 BŠF$»h,)|ëmx[e!à!ÊG)çd¬O÷1¥øëúRáÉˆqı²QæíSúˆî7 Ó3{^Æ¿Ø|¬ß‰Bpb€&§dí=åÌi[º¶™û§É`‚SÕÛlu¿ÇRß=}ä³Û#! OA•}pTa>Á$LúNP.ÄÔ?á¹émQÎº=ÅMxÜÌ5]âÜ¨I˜â'7Wg“Á	ğ²ë[Ë
dÍÑy	Ã¬ÌÏV	aKü¥@áo n|ê¹^f_Œ+(òÌL™ÁãÉÎä­ˆ˜óm.,‡¹èªé46áÆjFL/(¢õ|Oàyqäëšˆ‰g‰rÖàAÇ¤ üKxw°ğ¥
à>ÓÏ”¿ÉbÄb¥û¾M¶ÿéö7–| µz­ûèÓÛHvòçrëp[ÏoJ8lèÄŞç5·_Ò¶9£ÒöT†ÑìLÂO[&¹ŞÛ7ÙÉÉÛ½ëV‚Eaºšs“Şnlô]œ™fœ£Ö•ïR³@…TTSİîî»×El‹VU)"‰ØjíĞ½,œEÿÕ²g4ª"¤SÈJÖª…à1]h;¿zI?}Ó¨õüV¯ñÖŞB’o+ó:rt¦»9ãí{¦~ñ¾À…Ù•”î,sDŸšu$U"èĞº…¿`0Æä…ı»ïí¨'3Ëm˜;Rà[ßœÍ€úÀ°ÄÑ2€ÔJ’pÂ>†GÚFDC«Ìº@?bEÈ ´¶]áÿUx@A#…¯;“½ÁÔè´vå‹‹ëÍ§Q<:šªŞ!\ƒ±U‚<Ô´¡ zfÈ>\e´m'Lw¦<J”zÆ‚ŠóÒsß'<çÅjĞ™œp<„1ò”QcZµÔÿ*fÔâeÊÃ»íıÚ] ×üCAİÓ;Ä¯_°0jÁĞg‚ÚÉßû5ã’ı¹)_Pú,µ\ñó1œÍùø‡¦-l¡œÌw)-¸`(3?±z–g¦d)™àĞ^í°Àq+r÷«”.ÔU'ÇÂñA{â[2†öa‰çpÏ€v~D+¥*Qåû×zÌLj§}JãY+Ø¾‹ºï ¡âÒªÕ¾xNùH—¹õv<›o~ì§†@©HSdK·À7¾î|¢‡ài\øİ°CWåTW(¬ø†Rı—şŠ­U'>Ï2—¬xÆúÀ£ØÙıs5!¬î'‘#+wâ'ù-Ñ±0’	S`˜é¢Ë3‚6÷ù«›¿bÙ‹ÉKÌ_H#‡}ç°ïùÌãXò†€—r—ïïˆßÂÚÑJ3ıgÀMdŞññQ™$É1´S²›l-´WiÉ•›>^ô–ŒÑ£º 2õ‘K®£·è=§-ÿV 5f™ã$Bîì“¯8Ío~Ü¸œ÷cñUKú6Ñ\”+gbEé±ÍV?â·&‡Âšıæq»v½ÚqG›ZfÖaTdÍ¥ü«£[’eÍÃùs«ÿØ/6Â<‘²&§j¡~vZM‘®R~U¶b¬çL¡H¯™R„Ey0ûŠÁğìĞèÎüU’áæ E­ûadOê{¶i‹¶Y±b‹„‡Èvê£9ËVçŞç–“L`9ûV5¤Är10ûÄO¬*Ş&…ß¶/È@¹N	B|4©"n°H¹ª™·“‚º-„éËã»áë´öGj„¥œºŒtïe)ÜfÕjâhÇŒ+Š¾Õã\LĞ†™dv×Å9»\äêĞ2çáTK¬I;Öt	º?ñ¨HIæ4ı#†bCY%tp¡É“î5ˆ˜”Š%´ºÁÒVÄ
¯iW›L€ı×(‘)Çƒ†ö§"„KfuS±øöÙîÇlÉk;ıdªí×¯3%Ÿ×¡ƒyğGá‹Dgéz¢ß¹„Ã;JJ†¹œüØVöß,³CÈœ¤Ğ÷Ú»g¼¬Ò8*Å¥—,‘çÕ‡ºêæA÷hY¯ü!Rñ•ÏÒ¢ùß2ùç‰à|³j¾µ£¢d}’q£¥E$°õÆ-„`ã!Ë¨B]ÒƒÊ‚úg"†ØR °ƒÕËú».o/IûcıÏ\VÏéÀ}·=Ó€Ù•·úL=,´­6Ê¾às{.D:Ğİ¨„²åyW]hèñI·+%âñ˜nÏÕõÚ1Å`>‡¶…>¶ƒhpÖ&ìêØÄ˜ËÙÆÖòÎô¥9%®&zÂÄkşdô+†4ø´ÇNûùÑñ©Y-´è¬¸½[ÆÅij@Ò(O9Ñl°ã0`J&‡
#³¤Ğ|«(ÀØ´o ùLŒ ]¼êiÂÓ©\şµşÎµÂÉ€GîÁìUw0Vg;¸Â‚ş{œ=ù™«¤¾ñı$‚4^J…r‹>a}_œ%1ò˜I(¯aDÛ ’¸­~Ií¯Ü¸ßr'Ğí;ûªÚÑ `­>yŠ\º®	Ld‰!-íƒ¸%Hˆ¤üP áß§zÚ’Pï%ğj¶İé-d=÷6»eªQ!Õß
±¦7•5“ImdSe9<:‹ç Éè€”;ß8½Cê/ß-” ¤*xèA¢!`ke)¢úì1~;wy£ÜÆ6i½ˆF¯U;%˜²ÏÖñªSÁcS©b¾‚åÇEI®Š²œ‚¬Jè/Â«¶=‘ü‘Òİ¤ûZÌ`—•ò$0ßÏÃ·'n+k5Û	¦u?û#Q*›T+h¤}¸ÌŠÎ®´FÉQ‰Ì(’@™„­0"15ùñ!)V\%ÿ—x9ßµ—@ˆo6IŸÎE`:†Ã*Hyd¯3ù÷–Äf±ÚjÁ™êÉ?¬O€ãŸËÒùì.{şò*;’”Iæû‚Ã. võ¶
Í¹5²]=™ Å³µ¡ÙfôÎø¹àş"\y.ú¯Ês)&RŒ‹-—ã¶]¶ÜA;â5û·“ıè´­sÎÍsOÚZBépÅ‹ÎıOSÔÈŞç­lµ]FÂæ¹+ÓSsJÂïõFÒíTõ¨“F )õë…*!Y#é•eöÁĞ_{@C_Ãµ}bÙ”m—„Z(ÕÙO#·HÑªÓ{•ÿÿ<Úb¿³‡ú+ŸŒ/İç^‹ªTÀşmu-Ì.ÖÕâúİÂœ@wZxôPlÊD¤ŒÌµØÂYš‡*Jîg¼‘O‚LrDî¾’ıQU”ŞD´=f´ş×o{…¨éÜ¥v@fwÏa{éÓƒ7yQ-¾‰Á9™³Ï„FˆzÑZ®gÛJçÛGÃº~ğŒJ LxFwc(0{O×u4?’Ù7P‰Î·N/³úØöc×ÕÀ³ô\º=Û ¿ö{õÒ¡ºém0ÑBM0§|·óã$Ï¿1n&ø@R¶óí%mÿEûÄ¬^Eq“® ”Ü„6vrÊWµàj6—øŞğ‘÷S®ñë•zIÇèækšTŠ
!\«H(Û—p8ÿö¿‘ä~Ş0‰„üõµ–w R‡9Ü,ç×«.wT0Œ„®Œ•¯bÍ]Ö_–äó¬ó)Z4ƒ'çlâWÂâ‹ë²ÿƒÂè(†\ ÜÊ^GÓæñë H¾³ì±Q ü½€ÀÿEE±Ägû    YZ