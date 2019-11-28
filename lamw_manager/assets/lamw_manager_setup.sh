#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3723809534"
MD5="d438ffbe49f6b11b2a93880074b032dd"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21409"
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
	echo Date of packaging: Wed Nov 27 23:36:42 -03 2019
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
‹ º2ß]ì<ívÛ6²ù+>J©'qZŠ’í8­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»7úa‰À`0Ì7@×õŸıÓ€ÏÓ'Oğ»ùôICşN>š[Ovîl57Ÿn>h4›[[È“_à±Ğy`™®{uÜ]ıÿG?uİ1ã…éšsüKö{kûIaÿ7w6›HãëşöOõ}b»úÄdgJUûÜŸªR=uí%˜m™%3jÑÀtü<6CcyÔr&¶Ğ`C©¶½(`t—§6u§”´½…A—R}‰ˆ<w—4ê[õ-¥º#vI³¡7Ÿè›æĞBÙ4°ı¡Fg”¨²´«ÄfÄ7ƒx3BïÔ(ş>j¿‚é9PŒÎ L Á&¹Lß§™yQq×!ÍvA”œ:;S¿'zé{@û~çÙé¡ÑH[ƒÃ¡¡Ö«I.f||8wO†£ÖÑ‘±B² ¹Şî:†š¶Ÿ;ãş‹ÎëN;›«s2êÆ£Ş¸óº;ÊšÛ0ËøYkøÜPQ®R5F§C Vª‡¨·:½àªÈwØæ€*öŒ¼!ì[­ÿj_¯×¢’w{¸s®R)'‡Áü£k ju×¹çosvòñQf¶²ÅµÜàÂRÂ\ ä[3õÏÕØå[£ ;„o˜ºØe
4èÂ?°Êm\¥’ğJ¾‡®O=w¼BV‘`±dVu¶Ïèôœ Æìû@ˆ=‹,,èb›£p€SFƒ.B;P T¦fHtNõyàE>ù+™ÔÃâßÛÏD·èRw#Ç‰©®ı‰|cF²›°˜ÊªØ5•Š Ï}à˜sÆ§uéE?H@gã4ó›*€ÂÏÛµŒÚ&ìğôÌBİPZÔZ¢–STNP:M3kã:W»Æ/]OÑê7¤
à`1	=Ë2âÁ`ÆløVO(oº²Œï¼ƒ *d>MQæ4|êÔ>ŞçËd
8ƒ43M¨¬ªa-ıM´K5m¹y¢øv=²èÌŒœpCV¶Ã¼S³‰„O-QÊÚãT©d¯ıií¬}Ï±A^Ø¡˜ÏíÏéŸÓK:%Ô]’ıî°ÔúÕ¨Å?ÈëÖéèyoĞA[ö›|:}‚«¤–³lEöraòÊPv—ĞK;$õz]İ¨i¥~•¸ŠÈ¢BĞâúqÅ|¥±”¢p‘\£¤J%“„D25)+qS,››ÂJº­¼1&vaÚnJ©‚Oœ¬.C=x^XpŸJ%ÓÄX`ÕX ó}uj¢Ìyˆ<¿Uş˜ÁdvFAÊ	Wd¥"›@X '–Ã·¢&m,yğõ³>ş/Úîœ!©U/ÃÏÿïlo¯Íÿ67Ÿâÿ­§;O¾Æÿ_âóÜ»@›1š³I»J¥Iz>x> Íy„&+¿¢TF‰ãG>ô{nØ0v1]ÆWò©¥ùÄè ÿê8/…şª˜_Lÿë¨ áø3rÿü¿¹¹¹]Ğÿífã«şÿgæÿÕ*=ïÉA÷¨Cà¢¶ŞqkÔÅˆíWÒîtO}2¹ÊGI0Ò‹ÈÂ¼â6/âE!„96Â‚«ïÉM2Iˆ}²ğ,{fCNÁãã&”8ëù²Àj~ï›Q¬cÂ#¿D®R•‡Ä>Ñ41Ú¢½°1,d0™Ü¹.ÌsÊ¨3#f0xFf· 
€®éÄÈDÇt¶KÎÂĞg»º«ÛşeŠ
JV?³š·Ú[ò"V,¿ôM—ñˆöÌL˜Àxef6g:x¦C3uòV#8û÷¦Ïë,š’·úq`÷Õ*IûÏKÿfõÿfsçkıÿKîÿ¯Ú$²‹uvöãØìíÿ¿ùô«ÿÿZÿÿÄúSßÜZWÿ/
ú=Ï rAÂÔsCRÂ‘A4âÛäß™S—<ì „(¶~
ZƒãåS¢“VkĞ~¾³­‘–km}!Ç®T-ÒihBŒ‚;ğá<bydæOã4Î´Lâz¤ß&Xo4±,·üğ÷À6—6åÅJs1±±à¥ğ é ßÆºsE©8Ş÷Ğfáx0jÒJ°ÍXDë.7°<Ì°ŸÂëyaõ±z:‰Ü0"Íêêc L+˜Xş»ôbq€±2^vİÛãÃl7º$ÇC‘æ÷I™9URrš[õF½‘Çs:8ÃB5‰ÈØÒ­Ï
‘D1NİæØ¤õĞœ3= Äã­qcÜP%L€e|Ô}6î·FÏUX ;ör¨ªÖ>8LÀ‡ ¢qÒêÓÙ¼ˆrĞ9ê´†C½uâ—Á°Û;1â%Ş‹,½&T3®#Ší?KÛ÷ZÒö­K‚^ìNO@’e\ş°3MsPP´¹­¬+-ğW¹8€Ä”f®¼¨Vz<…øãêpn
„Ê°`À.º”¼}O¼I`ÏÍğÃ?A£0(à°è’§‰>'Ì^L>üÓ±§Ÿ»BğäFrÃxÏÌæ_Äq‰Æn_üêà—ƒ¤†\Âïuìø„©âµñ¿’îJ˜_ ºt^wÀì\œÙÓ3äöâTE“±mÄ•rµ–¤ƒ¨êêÙI9æ"GµuSİo®û-ÑáúE‘^©òŒ7=OàŒ‹*ä»´BBÈOÏ•U8<AÂ#p²8İhpzò‚¤†|„£°ØŸc-’m³ŞĞ&àÔl¼
W»^iûö­öø&‡:>Š‰ÁşÜíÇG¦ÛGİ“Ó×ãç½ãvfBt
ËcH‡„yøòdÔ:¼áÆ±dÆ›º¼WuĞÇúü7µdu© –NŸÊåõêBoJ°áÑF,×¥ø Ô"ªâ §„u+My’3ÇP[]{ˆxH‡ğ‚ÊúQ ÍÅ
äÅ‹…	€PLx¸¢<Ã¦6Æ9­`!NyÏLwN³sû•…Šİ"%’uW*XÛ S°ğè}ÅNƒådş#©-“vÿt<j;#ÃØëU³Ø9RIo˜ö‹ˆŠ´½áP ¶}€zù´E´öìåAÿå–Jáë:İ×îLEp¡Ê—3€+…2‰[R©dw$qìÚÁQIÃ‹X3D¯ŸÄ äÃo¶Ÿ°Dí÷…¬¤{ïûÓËî#ËÎÓ¹­‡‹× XÀ´ç½›p‘NxÁ.9 ´LÚMVŸÚõIopÜ:ºQ‰°Z6\±U*Yb‰à«é±i­TûU-Ğij¿].gk¡*Éú2ö¯Égö—up9³Z=hD¸•ì².´‚éÙÎv©>ÜÇ•l·´Û÷Ğ“Ï_"ùyíx~°"íeÔİ&PkïgÜCŠ&%Éxô˜£™`)™Xá¦ÜÉŒÏm>–KÕÛ>$ù­ÃEäHNö\Ğ¼Ü¾Íñm„?l¹cH6dí¶aæ0-y^8ÓçÊ–\ dx¡ÁGB*q{[j“®ºµÇ=4š­“ıA¯»?å¨pçAÆ)Œx²æfKT_¢5<qv	5‰KàíŸBNÎƒÀóŠ!)}9oKb
«òå‘„X‰]ı,W*CŠbÒ7§çæœ
»ß9hà¥¶ı"IØm×¢—üÒK’Ú5ßÔxß»›^k. L8üµÊşo_ÿå×Œ˜¸	Â4jÙàÊş°2ğíõßíÕúÿ“Æ×ûßÿë¿,ıj¦³0ÿÀú/I/€kñyc‰Äß³< Ì÷\fOÊk»!ôæ.6êâ1ñ:qY	¯«Õë_†Û%Å†ßm<sƒhJ5®d™ü®%]RÇóùAû7
ôz£1ögNğÄk‰Kî¿ƒ‹Å9`&šŸà>N‡óû™xéQD-õ$Ê¼ŠÀ´0dğÖä:(= ¾Çp—m¼G9›g” !œ’ÛçÇ•ä!*ù™ï ;¤®	bÓÚz§]rnâ¶ÎÈÃáé³á¯ÃQçØ0ÔˆMÔïIk4\ÛÖKêZ^pÍ?½ìœì÷?Cßqo¿c¨x8ôNû†ê;Ñğªoİ‡„üB6JE1>Â;ÎA„âgéOšZLi7!ŒK¼†‹€$àeÌ(ã±*×Š¥M3øKd/=ÔàTÌ?üC®{Ş3&Y	Jn‹Jª²øÉ•9ãÍWßˆf°rÔ7Ã3c}ÁRóòQ•ËIEè’X${ÈXùÈUãt5ğ0†­ƒ¦&µÚ=€µ“X#T¹©ESš¢$q"^[Éˆıq=2ŞMjNl-î>pj©Òê®u®û‚¹Z0=†Öj “ÉâuÜ&0&ìIĞÁoË©37ÄûÜ¡ç9C¾£—µ]ÿQ÷ŠF(ÔE·¨2Äe±Jå¡vå·ş,…‘×#0AŒ·€XÎiøğ£Gè?aL:Å.ÒuÔÂïEÉêàQ$±-$UĞ,¼!F$9Ñ¡Ra\7l—Ú.^d.àÀäL¢7w<ÑJÄO¹ânÔ™ô¤&÷`Ö×Ì(ÈÔ+46ÏıPcAáé{3ÓcK<´ Ép-$ÎqãjJBŸJT‰:•´XW«[–Öc¡×<t~Ü„ˆø¢%>6,ZnJ‚©"/6€ZÌŒFH•è3&5P^ÛÅ¿»µÃAkÿ¨#ƒÈ=~u]°y!Ä$‰è3ÇtÏq'’w$Râ	ÔûÄÃ ^@†Êên«5™ªôœ.%~—¥°t¾ÛÒ^çzÅ«+¤˜ç'o«ÄŞé4jòx±Ÿ	Y»y47™µÉ8ÊvG&Š–”‡Ÿˆ±¸ß·¢áF¾IÎÈe4•Â&äÕ…xQ™ k„­&¾ä1‚ÒåS<Ç”
Á€	£÷¯ñ™»Ì 8À÷0ø1£W\ŒRíE`iŞ›IÄ"3°=¢
®iéM½ˆä/5’GÀÇ°2³¡ˆJfïÂ¥AËqÒHOz®s_ßÖC"}ÕB VVrÇ°1nìøDuj,ÊSÈ.4"ÂšJ<vÌßb—±ğ,K.ìßÌ övbµİı˜ÁğøçÖàtˆ/y<;êcœRÖR‘NãÌY3išRİ/ëMõ¼¬3^Ëš^N¤¨«wò¨0Âs^ß@ŒWè&ä%qB"’DõxwßK(ÈS=²ÆıSíº*1çÍãw7{öwßm ¹ÑO„^2˜ıîF°x£$„»ÙO¢VÇÆw{Še­‹ÀñFîœKdú.ÂÛÓ‘7ïŠFÉe ¿‰µ!Gn]ªZA”;xSb‹ &å*”¦œz(.ù½LOÒƒ¼²V~z¢vİ™·‹{ªŠr-ÆA»ÅÒmÚO.¼àœùæ”ÆÌ}Õ¼B8ÜÉàâz,G+›+f‹“ş“|?˜³·î!xy‡æ,ÇÙ;ÚKY›Q+4ˆ‰OFÙŠ¥ŞcLûóÏCÏQ¯w4Ì Vš8àÉ¾tF*=ğNù2HMÚÔ˜‡ÂFH#¢XLÆÃÓ~¿7·ˆ’*v’Ë¦†&q·ö¿6 #ÂW(ÂA2ó¹w¯A¬ÔøÅºXÂÔô®ÂIoÔ=øu<„pSÜ ø¦p… Aà#Dì­{‹|‰ÎL¸È.)¯·îzÙÊúî)W0gïp÷n^¤6<ÎˆÏrröR\5Oş‹{ëò—oÁfóØ ¢c’-³Éu#‚Q36‡'ïÚŠ%—[\‰nú¾“¾÷FÕ)?Áäz°o0„‘ƒ(åŒßãûÇ.D±°åK9÷X8¥{R¼°T÷E}€•Ö]î=ZÌ›³Ûeç¡çó;3àoöE3éàË#ïDî¢˜jd[¢¦¦Ş»Qí\Òiîè´Pänš¼0ƒ+MdTOLÊ}<Ÿ<C•E9¼ƒËØvR‚ºStYy8˜V¯ÛĞÅxDlìĞÕ¡‘Ñ`a»¦cÌLĞ0ÑtåS£•í[Ì†6HÊœÇ†TÜƒÙöV!¤áBq8z±wxÚ^Ûsàâ°û¸¦ÈuÜvLÆŠì>†íäd…ô2Ô/5q‡p?ÅÆzïA†5ñOÊûl+‚¬ 6ç[ZŠHˆTi#–7Îó=SÏ¢0©c^‰U¾ W`k,fˆÚò^_¬9tP?‚ÃÚÜÙË3édË>dšW»»¯µûí–²¤Ëò÷nŞeû÷ßÃC>ŞğÒt"jÔiüñµ&îÖjø–/P«í{øš´‘èÄ9¾­4aëİÖø¸sr:î:ÇIÂ_ªS˜çAÈN¾»$eã Û/í€iĞçp!ïw†/F½>?O)  ŞÔ6Eõ> ³ô½¨3êøõ¹ë-(¿[jZ ×:»b!]hüA›G¶EQ{&°Z¬‚]Š @^h$ñõ³páÔÑĞ¤´eê$lvº¹ˆ¡~¹p>ÊÅÙŸ~™X~$ä(Ò¡1›³Ña“ÙÁ{0îmxıRQqºƒîI—'JÙi<á÷D%eaY“‡è³ l :P¢dJÛ÷X(Nì¥(İs¬qŞİêİ.Y]ñEC™ú³ü©@L®í#ªUrd/³,(ˆÊ½Zf•ÄÔ• KöŞ\šIäÊŒGÙµØ÷Ë…Zíº×ïœüÑo\<¿ÑÀ@¸ï­sÍ\X“’doı°£näæçJU“¶Ğ\(æH{ó_V¡ôqJ'”xfºg¼à¿¤`éH2ŞtC’'iU¤’µ_'?¿Õá×cÀœ¤©ÄÆ"Ö|ı„ K!?%¤JÌÿğD‰$ÿ*ÉæÎ%°µë<õ…6[u	 L@KÎ÷äÄo	ò7@è‚Üqü!Ê$‚|ÿñMŠ@NèE_8+aÌ±L:ò^¥³6ã€¿ Áøÿ/ĞcfÜYDIJşãø‘AhZ±ÏáÒRÀıæ})‡¤Î86>Áş\h¼
3ÌÃ°Lø|Q-©K„ØÆJ^ÚçVoøëĞÏDè ®­æmi‡W–ˆü0rœ˜Í<„Ks·@XÂ!Í8‘ãC*¥[('Ùıø Åh$#ø•cğıàS'Ñ<ÉW'Òj†ÈêÄ½ÿÎâ®:Q°è’‹ÓÃ‡]ıH†ª+eLñïâ
ág*¼¥{x<¢®¹r\+4p¦ÔâÉÅÃïÉ[|WymÖ]€Ö±±zÖ2§’jyô³6'j	kTÉçÛä.	ç§u#«Æš\'_%L2oâ…»—²YvGV©¬&¥Upu£ _—Wâ?D-aNã³•ª…òÙ,ˆaÂ­¿éõÿmïÛšÛF’5Ï+ñ+Ê §%yMR¤äËX¦gd‹vkZ–¢Ô=3V" m’à@Éj·÷¿ìÓ‰}Ø—3±g»ÿØff]PHJ-{<»d„-¨{eUeååËdz&•p¨‡†¯úIŠÛ©­¦^8dõ–=ıãŸªL5ŠP²<Îoÿg˜=¡_Í;OW[+¥’¯(Í7P2á /_Òoÿ“]z?‡éÉSBp¬•šwºRÒ£ªç‡xà±©*Ä‹€ÿi­RJ4é)À%¥dv¦ïŒ²›u#W\§·õwĞcXtGE™ĞÑ÷„$õÜŞk¸Š¡€ƒ£ã…ò_„©dëõ‹at{ZÌ4ào¯hÌÉÑ«REÀ¾×¾=è?¥Z¸‚ÛV¦½Y1\…Ã…G80n³08˜©é»¥}²åÌFe{VV[7êõéoŒQ™“Öèº¹Jà©ÈD*ÖFİ-õwNEuc¥yú«>ı±é¯ÍË‰±æT–ó/Q»y ŒV_r38Ô¹¡lÎ@U*¤¥«cÂ9¡‚Q5YPÇ#: Jm5àÁè=^ÔÈŞ@Sµˆ,t3’7–8'à ×ô Zk2=ÈËØHÎGêÉ4.RzÔãób"ƒoÌ
Óš‡›.ZŒôg“A?Mä ¹®ı{5œƒ‘Ï¿ü;ôcX‚?øp’Äß—É j¤ş9ÿî‡ççÙ¯éD|Çëe;ğ+ìÜ¨Õ÷Û\îB~ú¯á®ïçÿÿâ7JqpMs?qò„Öñâº´i_³4ª8XZIª}UIüˆW=yÏKˆ¢e<ÁÅdæ¢1Iù4å?bï¬9H<úÈn¿Ã>Ê¿,‹®ıã”÷ñ§$‹„Ãò>j_E¥£÷Ş£ÍF¾¢|…¿ïÓW`PùS(«4+¾ıDL}“/§©ú"ŠŸ< '°s]m´ñÛÄ&ôwêOGâQ	ÿŠ0,ø.ë¼û“4šˆ?²Øko€]ŒGDH)q‚«û2û&’¦mÄ`Hñh'ÒÂáEzÒ¾Š,ÙÀ_g¡?¤A$7Fcá4^Xz‹Ûqs†›ÄdYCa£.}^Æ_‘Ó,=Øbt¦ÒbäBb`_*“ÙgpFnÿ6k‰û¸û—Ûäóê&”u^Î•æÃˆSy785Íp‹.+UO›"*awš·ªï‚®dõÍFë”fjüÂİŠøÏÖzQ~å&,<³Õ-Gfò)oÒ+Ğ§¢¡/¹	Têd×–Ğ™Œ®ä\"2 Aøúñ¬®ÂÉbÛ'ÄÍ¤úfJ8í=q}×Ÿ`ynpzÚüs»b¾v-Uò»¸ò*C£RåcÓõTÊDrÆ-vù=½Ô†Å*ÉJQßÌšÒ‚h­ÜEDàñ¹=¿1˜hßd>²{-«¤™Û3$E3…Üˆ9¾"—À¸µ–Ôxà Oî³EÓ‹úÑ$M:.pnvëƒkVA5‘Mç.ÅEîd¬#r
µ2\ü…P³şÏVUh&’‚ÍUèN€Mˆ‰ÃßÀ‹x¾‡5½¼öù6Ñ™u­0Ï‹‰Ë2{îbñ9|­’Š!ßÇ3M¡Ğ>ºÅá…¸ù²Q:MÎ¦cŸ[›!`ùÕ02‹)y<{ëY8½Ø¾ºòËi!›ó;+B›|ÛØg¬“ô‰vó-ååe¦3_®RçyµàAzË	…“äÑf04‹¹Ùb¥%ÌeÌ©Ì™K°ıÌ‡†Ìc ƒ'(OL;<9\$÷¼˜ÚAÅÎ*¦Â	†FG3¼ÎäÎ×ëïî¿î•§tœ‚‹õmü‚ğâÉùÏpé±ìÆEgG·"%¨œ>ÔŒS[v§RLµJçl-ÿ‚ıÂ»w“æi³V„Ši6/ğş[&Å¬[öÉqÚ{#·#»×‘Åé¨èsdºGÒáh¶¿Ñİ¸å½à÷TÜ÷µÑùÔtWæùİ.'÷ºe^á+ä|&ÿ(åv”›@Í&UŸ)ÛìwÎ´eö\Íê´µ=ó;ı¯G á!–}]ÓMRnì*v;O1‹‹Ø{ˆ-î FkC3“½ÎÍM» jÎÛËÓOšhç˜G+e‘àv±È¥Üª¡¿hÄ/İ¾³+¿·sJ7Ûş±xR~Ò%6Ì"Æ¹mvÌ
t"qaÊoöW7¶Š˜K
4†ß·ÃJò‚•àgˆh@N	GÜËs$g©­'Â«f—°¡YNåÅUn¡QÅj¬•c r|³5	Wä÷ùŞµ0^?&¯ºz@´îş÷(x•ªé³'ó<%‘¨nTbCë³Ë„T‘{;øühûèoYÁòèzZËŞb5UŠj5ô•rsE«—@ğWk÷×Vr/(Š‘+  ¨˜co/ É	r£É—=‹éxXÌ—ßÊyˆ>®•şÃÉ¾e·JäG<GEÂã~T	éšŠ6à	‰¼ »&Wlcƒ)T²¥“¿¶¶dETßwæ•&FÚ^}C|PÑ‘q@_j²¦õåÏ?~Z±Ú•¬BqŒ«L7y.Ïˆ›Ú^qy\ÁVVZëãKƒm_yö'´8–>jn«±îÂ`ù°ÉtÜ“ãWõ'îŸS/Ÿñ…ÈTuÇ—aÑÿ€ÀOzçï³=^[†WÇ-ÆOİæ»h4	æ¦)ŒÓ¤øWÿ
	Ÿ»¢,!B¤á{£@•U¶ge™Ÿ5-m¤WÏš¢/º¥[~ŒÄÖh5ñ
²‚#^0=/`\¼˜m±I40ù¶Ö‘¥|abİ¼‡*M2Bq>÷P­­JÏÂªë8'´ó·}‚Ò]#À_ØtÖgg2`Ok«0/ßñš[YcTN¥Úš]€a¦àÊš!_»4_	Æ%­—©6Ê(94¨	Y›7m?ÖÅÂª¹ï02§hcO6r¥”èO±¤]<å´¾¢ÁqæĞ8¥¦8i–¯¡q ;‹gÁÄ›”$ì¤i¶ ¥Gî/Å=Á,¶EÅ.œüáüVpÑß=äD¤ŸkäÛ_ÁÈo|–‘GV¶a9û%ãÿµ6Ú›­Bü¯Ö2şÇÿmşÛe†ÿ¶Şh™øoô7#Ì×˜Ãh¤yl·{l—‡³àƒÎ—†ØƒÕF¡®àÎ7x/Şƒ/”ËÒ
Õ|Œ7§úzïàÅöû~ûhÚ{¼Ú—Ñ0ŠÑåSF©ş¾{´ÓíÔVNƒ·­­öhE…³}Ôİ;à¯ÖáİFö®wòâo·wğõ¦z¼ß}}´{,²´²äHVUcy×7Ê¤d›FÂí¿Ÿì©6³çiV4o÷÷^~×CÖÉm^zÜrÃŸ¼¿À#ÕkÙSo‚òÅ$MÌWoğ. —xÒLŠYUõóÆ¾ë¬9É;à.ØS,4¿ïC¸3%ıe<*ugÅCàÁXnNÕOtç±19sÊh™D€mr` úÜî(¬p0x€jgŸˆ0Ó#ÄdNy:ó§¨&¦)»aÓ oŸñ˜Ù*²—nÀ±Ò:u™‰æ~Ïeß<k€À¸Ê/M9å*IîŸO0´
e÷wÁº®µ°Û$ÊD7xĞæãÀİYi5QY¬hô”Nã1œëÂQı<š}Å¬Åğıt
íÀá¡Èİ;+ûûİË˜™CæÖÚÅ7¤q>x´ÌN!QhV–2ÖB×Œ„¡ˆË‹¬ë‚ÛsÈº"úJòZŠ'N?/ñÜÇ¯zñEÂøPÂ¸Êß4’‰0àªß£C•hËKØÂ`7í¬ÖV{È= ÿ\Ã	ª©8†k@ëâ·D·! *”¾Áä=:«k6üæ›Ü jÀTT§=ÕZŠØ®¢É§2L¬K>ĞªÒÚGøÚl6›ìÓšu/RàmŸ/
`Sá‘k*UÎ
…öXp›o½úÏÛõ¿¯×ÿ¸õãš‰¤ã¹0-ÌÃEğyÃ	¬Áéñølæ[•u@¶®¼}„4(ÛI‘N¸´±pÃ¡iŞ™d±EV6½Ã½İããîNûèhûoXª˜ÊF•MN~sĞµİP²Tlr¦JzÇYZá0ãĞ§Òæpsx.7›LØ4	WèƒÇŞ5©¤DŞ¤…5
@c¡RòÎÏé”66µì;ïFV’Ş 9sZêL•QÍ-,j)îeFÀóá£R*&¥¯l(†&x	núg×èéPäL(•%Ã@[º6e˜[Ùì	·'¬«Skm©ßjÃŠÊòƒ	×}§¶¡ŠÁ˜Še@Öğá’I-+¦^ŠHˆe,/-#eÄwN"ÌDîõê!4Œ×Gô‘K×rxì~S°‰q,&ı$b<{ÎÅMÎ¨7ğF°CÂq‚n^â7Íàã3'÷+1©N&Ò`áqnÚ:Ì”¨Fnsbøy|«3%³ün]"è•—²†”ó‡3Wl+X ÉkŸ£hR´ÀŒİ4+S!—i9C«KÀ¾–ÎŸoÕ}[¶ùPåJO$²À8ÜQ)ie‹ºš@ÕŞ‡k¦ÑqF2›Î(aÖµ›‘e¦ı}3£ì™˜cèçÎœä…nFkr«Í³¢2‘#5´Êº:ú®F@kãíÆà†ôö»Á
Sz£‚Î¦å¼oéıWåmK-º™s­6VÉ	ÖQ¥r€pÚ]Äy£p¸%46Ç¹ç&áhÀ‰‚Àš‘*ò&ŞÎ¦©õM‚aÄÑ:5,3YEÜ¬®ã“ûõûZ%ÉÁ#›s Ï8¼„)¿’Óq®[°¾’ĞóoÚ0\ø?İ™hò…¼#¢`&tr'©`ftÜÁ/‚T[­B <"9Lçyà'ÄºğØåùP/\•qI¥9û€Õë0qïëˆ•€oYM¥
²PU¶¤¥lD;'iMãÆAJ 5dót}Ç×Q2â{®åŞJÛù÷İMGŒ"Í‡:(k’¢L‚ ìp;÷±uã<‰£A$Qò€ÑÖ4Š n‰wŒˆ<€²~û¸FÏB´¢Áè…iÂÃ]êÅ4¹ÎíSë…‰È’Î˜-Ãäo‚¤ºv*Ü­¼]ÿQ¾%t¾z‡¤sˆHÀ˜SØÀtÎµŸ}ÓbÕ`üïSÒEæ° 8±PÓ	J{¦,b±GP³OÛ^˜Rü„Z‹{(T*ØªÖ–	Š(º‰'ÃÔêó3ñp2×G#æÁ"„İ?ÕACÕ`Lq®Ö¯8áutUŸ½)¶(EW„À_Ë'îÃÒõóğC}b,§eÃU2OYõpâÃ ÅA¢&*É/mR±íµJ¢…SàTàaw±È~K'Ú}œ1ÑXEl¯â›ëº¾¢çæÖ~bÏy+»7O5‰@²Ÿ0+ôi<è‹Äÿ4q÷±ßˆÿóğq;ÿgãa{s©ÿYÆ¿uü÷‡¶ø?®Nåúy)c½¡ÜEA*à¯ËÑÌO¾Pd÷ê$Ğ@Î	tsœO Y‰Ü8nãæ94¿Ğúh&Ô±cg~«Y>ÒKÇKn•â:qó(Ôeê*r~8ì`è3aÖÄ$A5¶²êñ¹„ŠÉİŞ$44úrxh‹B®Y§ñ(t®öÑRœ •Ëw6+ÇTh}Ğ“ğè"‰JqÅ°»sÆî@ÄuävÆğ!¢‰Y–·¬ª‚¿­^µßâ‘[(%V(Ä‚"&‚ò k–Ğòoá•¿´uø¿y€Ì†ÌKÙ9¤Q
Uº’É¦Š’ÖC[L\S%¤F¼$|®
]‘¯î¡†#Í=»Ëägd£%ËãØd@6¹D&½Ù«ŞŞ?[/¦™]©HQ”¹+¬a/õÒiÂ9lòÎ6¶›Î·nª,‘úáÿã“iæ”<™„0,Ë‡Æoe¯öú¯OvùŠo¤øzKŞ4`Xš(|U‡<Ud‰—G/y?c¼ú˜ï·ÿøíÃ*M¢³Å#(Gfnuü2d“ğd"Š¤ÕYeµUÔj³:\ZklMßí…2…ÇÜú³¼ ‰#§®#ÉPîVhu­šQ•N¾è“q¤OUm	!¹2‰Í:¦ Šˆ	ˆ’2äÒ7ù[Jã*F´ Y˜+–!®å^ñ¨4µ9 ©¢¥Ä8Ç/ßƒ÷]ËA}p4Ñ<“â¾­ß«ù¸$Œ›oïwö·w¿ïª¸hj·á„ÿTó
+ÀëYŒİ4#ê|ÀµNi•íkİ[G´/ìš¡M'X²ÎUXê€Ö”w,k%/_D1)Œ^Œ“wÑ–Åøm4Öëæ`°9£±ßíîôOqwëâÉÔieAÀÃl'8=èûzó`Œÿ²óe¼÷âé}f´šI¸İ'uø?›N:oŸfoWìó™wI9â^ÇøÅS-t³lîiİ”ğş6Mè°ç)Z­{*j3$P;›	Ü©É{Ç=9FÜõ„3š2 œä®††4K=i µM¦MüÈ)äÅîö~ÿ ‚éõĞ¤Ô-æÌ¬­4|ä#ëg°ŸbøC—¹¶Ú¤²ÖK'äIµx5:n§gÓ$?8køD€ˆkŞç_û>¾CÕ(Ôğ.+«_ˆC¾ù"Z¯9÷|‡ˆ¾'cõœûkc\'†tùÈfìùc‰2Ÿ"Vıö^$ç&G¸²5âĞ)Tì:7÷5Dõî”ÀèûÃ4ÉÃÑŠSDÀÕë“i|¨åñÇú}8TØü„­Ö}:}Ä‚N‚ô/Gİ'ŒäìçŞt˜:ø†â‰—ìğ'_h$D :/}×ÇYBµ7ßş÷ô-"Ö”’Ì˜2Ln~YÉP±á¬T¥*·„È jW!pYŠçª„YÍUˆö4dãB¥®0ŠQÜÚUHb¢'ƒM­ÊˆZçQ§bòÓq/&Üf„Ñ×S{§¬+VXÁğMç/ÛßosŸ.·–%Sµ‹ÈPã¶s	Ì=
µ©‰5UŠfSµ¥qÍšI’)KÅ&‰#~ì¨;D1C’‹9ÅcY¥£Ig¥	ÿã²Æ{f½™îÕ{Û?¼Ù<eşR]àfˆXsÄUŞgŠä9“¥‹Lsk‚'PSjt"Ï$ÜH‘Á	_3?ÿeØÚ’äî	È³ıwô¨Ñ™¼-¡$%m?)²Tòş!®º9¡ygÉ	Îó<‰º Z¶Æp‰ğËùşñ…æ’5ká–V³µÇÊÛıN†šƒ}à×£¥vÒ<ó’ÛFó§³ƒÎÙJ!f…S9Ùüy(¶,¿ãØX«£¶·û¢'ïG„Úûšûgœ%&n¼%qÅRpú¢ş‚4òª;ä?Ì)Ğ6õµaöVÇà}‚Ö5uùbC:éuû6Ì4¥·¥©ÌÔ›+ªòYNö:
°¸ı´ÆcøÊ]4WìéØ,o R[";¨Z˜›}DlØÛ}Ùİïu{0zGÛoºÀxã¬^†ƒ`œĞ®9úG…PÖa:øKşè¤Õ«64]æ°Ö7ÛûÛ¯»Gı—ov´ŠßÂŠ/i.Ó;nIcÜß]lY_îªdL¶3³è¶ ©UXõ{…Û´Ögàw	,WWô±[É|ÙâSNïEÛ|XŞsÖòuêB”Á(7$¾è
{b.(i.JQ\R„-!¢ËpÿA‰4³O»UÉı¡JØ¯¸­u÷ºÛ½n³AğôhÁäN¬½F[S{åæ%åÜ‘Y‚1ÚÎR6¢VGGË€–¤3»›%"(U%¨Ì;SºùñsÍİYã8³Ô;Ñ5›PR”P%Pn|aR9Ãÿ¿ÎQû%¤™¿­"Á] ÔÕCÀYÊ0ƒÛÜš^œte
m¼’K/ÕÚ2æ.Um	‚ ÀÂF˜ÌŞpdûß•È%|î…CŒ"˜¤Ò¯…=`)T#ˆ‚h"# \’xfT>—zŠEŞ•yĞëî1×ô½B†CôĞÃ“W2&–v_¸1 ¼è¬ºƒ!p®Â!ú‚³xÉêgå©JàU¯ÆÃX3²‡eáhš…yÁd¶ßàsÏêÆø<fFk^85µO3"ÛWÓíü8.Ö@}Š&Óág„óXX~í£z¯™Õä)oq²ççñBd1ûQå?fõ£Ë’1Ò`óÆÂºŒæe’ÛÖ¡*_¥·kÔMZ%n¬wq\À²ß§ÇqxaªÏsêŸüõş¦B"m9j¥nb±¥9ÜàÑeyBÛ‹†ÇíùÀHMÖÌJ×Ú(­Ö¨Um£9/>[ŒS:la¨g±~Ø$Áˆ	¥	C	c/BÃËdŠ-%Ó•
3v—é¨ ®
T§+gßl¿ŞEdû°¿»¿ÓıkgUš\1^IY„º;¸^iFÆMŒ±›şö8ŒĞj˜’Í„Ô4‡òó&h[GÃ—Œá}’?°ÇÛG‚E/Tİ"g'àı>\‹æbjt±tsû'3ŞšœñJc6yØ5;¯ mCúˆéÚfZ›U{dƒÊMÁBÃKIê‡ÃwúÓ^Œ½a›­Â¸Gq<¤kjE“ş¾{(ø†Bcğš>ÿNŒÄj0ôAÌ½Ï£-7Êıï£èœ¤ØB­fÜu3ÀØ"Ên&A6µm æjqÖMİT©¸RnÔú~áôÎx" ì½®Ç-LØ#+…´™šsl-¬™Š-óãl¶1L–-ªŞ)(¦ÙÙ…%¸)™Ñu‚‰ròİ×Ê—çµºÎz»¯w÷a÷âBZÜ7<†ï€·5E\½ù‚$÷A$›cÜ]Å†)ã+Ò3Njã0ÕVéŒ¼ÈaV¥Û
¤ šWÛõM{7\¡F"ù
€“ O©×İ¸ı°Ñn<tm‰”XÃùúÃÆE]ƒpP´	”%¤wÍO•¾(£6`>­%ÃğwÜòD…¡ÑA§N*F8}”ïÜ…ùÛTditØ–ôaF›FÄş’–±$ÚV‰9Øwîâù|"÷Jé²pğNå®¾¿°l¸İ °w3båzê›—T&n¸fÎ4ô›! ÌczóÊ‡rúW^˜>P·1Tuº¢[%Å…Ä#lêÊ<K‡ª¼LrDÎ!GDç l,œ1z7Å²˜nV`ÇoSs¦%´ÌÔ­æJ›­ÌÄi¾o7kßì}Í¹ºÀz>úÙö®‰ í}Ñø>~§İ"®€¾Æ-`ÎÚkäû^wİÒl; )¾§À»üeS½xq²»'fK>ÀÆ™4ù/şô¡¶ë>Æ©Î9q	ßšK£vvÌ«ÂHËæ%öâ÷AÚç
XÔ‹fğ&ïû„ü‚–HsFK°‰ov÷õËCBÛîQ\<hprs·wµÙ˜öˆÌº±ç™“‚]h®ÌjOŠÔ¨_)İbÛV÷XŞ–×@İ#?Î*¶Ue«\©r¬|üV&¹ií£uÙ!GçUË\ÜhfdÈXÕækDL`°‹ÊñÉ†‡û™‘Æ­>ú‘¡ı›Û¹Ù)¸&I*ºgmQ_Mgµñv©±•ÊÍTı=+RqÏAîQ0ñÂ6ØÏTÜ`I¬Ç7WµŸºú/m›ÔÖºËq‹q¿àø¥ÒTÙée¦{Âm5EÀáîJmx„îıÒz+ğ±ã¼¬ƒñğš<V„IæIxÈÒË…²ä0
=,p<"Dë4FÀ{Eşè¶ª>å–/J„,QûY¾œY?İóiŒ Vù³ğëíLÌÕXS}>Í¾²úQi7çæ+	•&cÊrà™mß÷i1§“1ñÆ¨&"^)³Œ‹ãÂâ	ãŠ¡ë¢ò“CVúbéæSÜü/ğû1½"áYùH¯/Fc›u¿²åµXé›—U–üöé|ÏôF9£G"ÂˆàÙy*K¾Y#jğs!K;ÍêJì @8x‡¿×XU( ä,_T|¥ˆ
aÄ0YÆ¦Ë³°LU¹¬€2–:ÚğŠÆj2hÒ€Íò`}‰­ à¨£9»GI‚yS£Êb¦F–F”7X$ëÕº0áte¡)Ìø74æ8¤(æ½À0sŞ0üÙ$&ë­i¸scÂ X9h?H)cv¯^³Ü‰6—ƒy î‘ƒB_ m!¡ˆ£„‚9F"¡pI0G„”æo%ÕJqŸf»Àx`*ËÊ¨ıI‹Ho¾ÑeL•
à›Ù°ÁGDÁ°|ô‘Áoÿ(öşh‘‰ÚG^
k
G@ïùcÇ‚4„°(Î½ŸaÀ;<»!€ôšœí±%0´ã€dışz=çÂ•uuÁÜ¬
ÍÉÃ9a‰Pt³¶læÚrÃÆlÊû©ª]«~&w™Óª•­Œm£?2Ü‡¹ªÌøÎÆ	Ì:õ:ÃZ,îHt~L<l~vjGÃÅâäşŠ“Èï'9Àîü¬ÖŸ¸	¬X‘Ä„H·$kzµä4|{kBİ6J0“öt:¶Pš¸[L®éœJÉèò4Ciiò'	ş+MZ©¼@öš^lKƒ.àS„nU%ö.»;d÷QFÚÈnï¼H£?¸tˆàÂ4ÀYÜ‹.„!kfí{p5b`Ñ¥•ouÍ0ªáã¡ÜèÊ¢İ±yŒ¤Ë®bSâ\WëÆl—–Vl„Òİ˜pRs{x©÷B_ßùDîÃàm®U¾^0Ç”a;³VÌnÏı%XÉ<³UrZğ9±»å®s*¹J\«RT?”ì=+9¸UÒMööÒ£í.6ë’ÃyÖş]»‹B)¼¥¤ÎLÈŠ¯°®Xuf:Õ—fwk`ZOf¦E–£fft²;8q>ÇéaÆá=Ğ.î74s­ŠÓ¾fß€ÓË@|ùcİdqôÃAæ8š]z^·rî_ÔÜAx§æ}ú×İù&š§G!».Ÿ…?Y¼©Ú.P7SÛÓ:Ãô¦ò2Şîí¾Ü=îo¿<†2úovºp¯z°G{	ƒã™_®Å‘Z «üÜ¬p‘×+vKI»¼IMíœ×g!«FgìÄ‰ÏócÜŸ#Dg!q˜–Õ‚ÌP)¢äˆ)¹}­¥•òå6òÂ±Aá¦İ†í4$›úCôÑàœ‘“?'7ª£¿ÜˆD<2ÌFèÙ>Êîª%~ÂY¨æ$‚6é"«ÂA^zhìNÁĞèù-^„~8Ù,ËFœ7»†¢ÊvŞ9ó¶íÄĞI
QéŒƒ,wŒ9%§–õ€,³Ìë²Er%éK–°pŠØÎO·ÄkLÊÓ†Ág‰ÿóøáÃü7ü¾Yˆÿ³şh‰ÿ¶Ä»)ş[Y¼ŸÅ“{ªPÜÄ)áu6`lÎŸJ3µ«««ÆexéEÜ²7Îâ¦w‰fÃşÔymu‚¯eGã:´7ª«¨A^ü…Pá8ò™TieíY]cJD0˜"‚mpÉóö¾ƒ7‡GİÃ½¿Q$x‰"*|Øÿáàh§÷–¾¾ÄïÄ)cÎÒuí! ë0>ô]×ìoêp)Eó^ñ·îy“ı@…)±š³.ùûÇ—”‘WÑx™ĞÖO¬ÓaõûìGÍTëÆi1¸ ^§ş*d±ep]¨×EvM¤Ànd\1p«¿beCÊôç‹ç¨ß(G£yóZxYÏŒıŸ
xÀšŒ“/ŒÿÙn=Ş|TÀÿ|¸±Üÿ—ûÿ­ñ?7løŸÇïÊšQú‚ Ö“Ä81.‘Ëî,ù2!ß2YA‘Ğ—QN’^²KªDĞ,P^yèz* è¯å=±çõ}„‡q’Şc&V”°ºÍqÿàx÷z©ïï`_%ÑGix~]G¤ô5G‰:<LVY{µ”t†äÁ%Ê“é.ùß31†»æ(NYˆ£5ûîÒS=ÚŞı;Û9`Ûo^ìv÷»|²y‹ãX²:ú=O÷#$³¸Ï4³2ºİ_w^÷w¶·Ñ÷ ×ÑÂ÷>Õñò³í¥ëX.-‘ÜËº{/q,0|L3é÷É¤l«DÁ¤‰ª{š¦‡ÑU“‡ê7ƒ!;ÂJc’ö(¥³æğpQGïğê>MïØµ?R2|pBPQ¬õ¨±¾Éö{…Oò/¸Nø;¼´>¥Ò¡	rÈ@Ø«£ ’ı{1F„UùZ¸ÿ£&@CÒS#j<Ê:í©ôª³®gQÁì)ÿÍw(ºÃuf>/àú­œO+z
ú¥ëç5Eä"h-0rß‰AÎŞwÇ‡°.?øÈ”ÅuÄ ×(ãÁá±Ö:ÚÄ%óôq6S¯1=¥À:gI5Ğ`8è½¸§ †S nQÃ¬K©d·õA=€›øqw’úæÆÆÆã?>ân%Râ“ùL¡ûËú™z“ó¨êÄ­'gz®›µEÚu	NG+÷“hÜ‡'ú6m#ß˜ÛfV>Q³Š ¦Üê	ô¨Ñj´\'ç¦3sL{ú`¶Ÿ¸ŠT‹Æì ™ÜË¢a:ÒXÇMP$µ[ewVÚ1Ù
ïÉ8—5§uGİY›UmÊÆtk–Í>s,ö§ºùéÖ,Ã|ÌÍ3á·Ì±~r›UYûVÎÜŞ¬£Ìœ}f7ÛÔÏÙ	³;WŸ×9êC/ºÕÏ@%’íÈ÷Ó(böË¼ß@I‚¼Ÿ€Ù£C©#d{ÃE˜¾›ÑÆğÓh‚¡g¼™È
$Lç-î„¨*2N¾=§Œè˜ˆ
fºşîNW¦š	Ó¨¤¼¯'B‹04/›œOF‰Z+w‚KâÓãè§`¢ÛHU‹¬+
„“‰7ô>À¡)ûò¦»Òß=î¾1ÒÛù¬¦7A]'$ZQ`iß§ì_bjÕ¶ÙhÑîc>ÊÇÎ
½âhÕÆÈ_¶[k~ØxÑ§[UÖÂÒUMüİŠ£ùšgô%Â 7¼	FFFÒ&â¢K?Şá¢$MşQZGCê|Ÿê²÷êÆ‡Ÿ]G÷5‡£ã¦Y1¯5ÂÈ1Ù	©ÁÓuºÛ{TªØûõzqàUaÂ›<(¹§ˆ²ÔHÅáÙ”Åœ£ÒI—ó">tÑœÈà‰iu‘ˆàœìğ„óìQşuÇ•aÜLnæl6OÍş'Våûê¹•\àL¦†{Zi¬"¬ÿ€Egğó~ŸadSáŠ—bÔ« ƒ¥z˜Ô±cûh£z9nœÇA0ñ Ï5ES›©w‘4óÍ…ÏG°L9p¼Áù…Á=ß y.°iÊ¢í	è¼“cÜF–Æƒ¶ş Õ‚)Ö,%©™Äq2©$üB%´O”³â8¦mpÂÔÊ£ƒ^¯¿}ôF]tîc…B-q‹jTÄÓ©•g/O$ÿ„ÖŠ›’ÎDÄõ×}ºj½ùö•‹1ãÑJ Öz<º|ì¹LŞº¯vÿÚÁûìÊšSÕš†é­[¸m@k¡ö•´ÆÁ9Ö¬^ç'6œSô—òıú„«çcÒHN½‡şìœéùD<âOúXTc8yO ˆ!ğ×u®Ù­s¸\Ûù‚tA6p	ë˜Çš{WM?³TüÁ­ü9Û‹Á]„‹¢õB¿¾ª6†Š´ïı»L`«Gİ×İ¿²ï·vq÷è9ÎG}ƒ­pñ‰!ƒGe1¹1–9í‰2Äz18=î+-áÙ‡V«î—Àï]¤ïa³R¿àâ1	?œMÏµ‡/Œ£¶ükä"jeo?¤I*¿{é{íÍÅ»A]Ö„çÆÅpšndßè¹ëd0´wŒ§ˆĞÆ’éÙ% ³‘÷>`|z£Æ€€Ş!(‡f˜c/fòÊÀ9wÏ?cğ¢UB<ØÅšc§m¤Ê8œ;SĞ»äõìÂS&„&ü{S¤/@öbèÃ1I¢×`ãh\Çşº¢°:zvÜQ°I¿}û£ã”Ú0Ù-]”üÅ\%÷Ònôs¼$öÃö.Üì<JY,‡õLH §lk‘·Kü÷4y8Ş¡\øß‘Fˆù¼³°¾ÙøcsH"ˆÕŸII'.3i+×;9D2`ßv¡™G½;‘‹²o×E~Všİœ×Ekšsf¯|ÁC[rgÈ’Õğÿ§5ëĞ¨ö—š4fÔœ¥¥º¢é\¶·Ïbo÷Ø÷Ã°ão ×W(Ì.ôåïJäÄü%\n_–¿ÕŒí;ÖÈRâ.+­ø‹U~Ç-¶=,dåÉJşÕì|­–±{ğSˆ+
WÛÍÆ&Ê×Ìíæ8ŸZ»ÿÑMö!zº`]bÇSN5EdAvS4ÆA
´Î…ênAxìMa¤õ‡ö:ià¯7òmÂ_ØÕµ·ew&òşÁº±i6ë­>åÇm¸ˆ•JkĞFœ·¦µfw÷ú?ã
™ƒDçÂv”K_`ÍóK®Ç©÷á)Wá˜f§iÿòÏ2İÕ[°“3ïzR|ît?½&¹W¼‚,ó	FmVoŸJR–À¬7«bæG"ã“Zİ²}iØÉ¯ÿ%k)ö‰7[7™)­±PÇÑt¬ ĞS¨ó~ıÏùÕiæ7eõGì§i’*Ó^ªö\Zd²UÂ	C}:B6@:Éfy—^8D=9f lm~kÈ4höHCkøƒWğÔ¨Ëç¦Geµ‘•’Ğ ÀQ /”W!©f*.ÎêtB¥ããùtu~ëqÍ!ÃF¡Ât4>ÿÁâs‹€ŒŒÙ_+Osk%ßVXyÚÂ³o©åøíAïXK-ŒºÔëı“7/ºGùÅšxhÛK³Ğ’ìÆà¬Xo´5Z²2Ô5ŠOÇY_ö£ëPuó®ÿú_ìÅµİ@òóÅÔ®<ŠJƒÏ§	Y‘LTtŠ,F%aÂ><M9nG„g…Ç¿'Gû×ÿd»ç˜
CÑÑ	óZÏN‹í6°R}¹“q·ìsíƒ/kÿÛÚxø¸hÿ»¹¾´ÿZÚÍ±ÿºµ˜Fê·³ã¦ı‰€á±&c²*ú"ö¾\%4¯p‹>Ù#u4^‹Ög½üXúîù]áş'Çá|«Ä-·e3lIİE2 lz4®'hC3²H#”÷¢­Â€ahîÔ•º‹æ¥,ÿ‰
jß¸êô2\ëÔqtŒĞ¾G&ı9œtLĞQáá_vÔòO¤·?/rä]„ƒ>“* @šU×™zJòÁJ¥Ú¢'9$mëÏ93cÕzj´ÒnæñîàÙCz&ÌLà÷#õ[YÀÓÇ„Š¥‚ÔzG1kë-İSøNÃ…¨ïhóì£ÕyÖó·ùBLà&·¦gµDÄ¦7@Fƒ™i…/«Ç—æ[”,"ÛŠ‰Ü´^E@O™îé%Üéã‹¤³ZÃ˜{&j¾( XU-œÀ&QZÄfÄò”qrå{óêåZ|-v_ä'ƒİêØ”wbâŠš{'çÙDİÌˆó}Ğ'€Ut¸¸Si9Œ'  xÓµuosEqÊÓ²BÖ$¾‚Ö~òv;:f,êSs2|x$@TL¨ ~AÈC©Ö48lPİ”çšÃ1«'çEoÑ\Üf–Áªds!$6)Œ|ûK°ãŒYZ‘³Ÿ0üÚõ¦èœ0lÙa/¡fğvğt-álÈ‘°G“’è!ŞhWà‹[ 
q{sÇQEü´qˆŞƒW|eJÏºJ•¶v2Dá×t‡È.´Æ:ÅÀ›U!†à4Ö-ŞO~æ“t¦!œ	{¼`vµ<µ ¶q¥JmÖ“;¼™@Å¸¡èıöON@|{Œß¢œ¼ªæ'H—ùßljƒ_)[Ê±V*mPN vaİ3'f¶ ¡ºœ•ÊÖ3Wyy,ˆüá´ö0÷Ûÿò=vHá€É­7öæÄ×fZ † UP&Ñ!¶'â6Ü»—`†3öù7m…ğƒEáí1»‹Š­;»(«[%.$z§\èÑó.£(`dlŒÑé¸gÂ¦ª:g·®æÓæÍ_tò7],ê |ï<$·ÀÍI9t²"ó.Y{¼÷‘ï	Uú&–ÀŞû	cÄ˜g«ŠÚ¬ÂõeÑğ¿‘q*äm2WM•J;”rúvl@[™ßy¾ƒl~³ØT´aI€×Ù]4z¨Ú~ëN²ìÌ–h¿õ-Õ¿l¢t½t·8 ¤áÙÏrÜs[”´8|âFP­T¸ã^9/Æj÷áÎ%wsC7ˆl~l^x¹Ÿ¡Zg‘ÈÃ­$µKu½x¢§¿K'´@ÄÎµ*4ÆÂĞaMC™E0_ÛÇN½Å}}…œìØ~çÃ/¿È_³
Æµm	ÒÊ¶r‘\7D".Ø3¸>‘â¡H;˜*£ÈqcY­Íj›¬ö(®ˆwÇLŒ]aDàè¼IôÒí®ªZ‘^L"Àóéd Ó1Ş„SoL!„!ÂèA¸9""w‹ävÅ4P(°…J¥â.
¹å—¦¯È°µÌ‚«¤ÍT“B= –È¾ÄdN]#™mp][óáºÄ„Ì@7€Æ-KŞQ[¦¹¹Ş¾Hb…+ÔQì§&Q¦Q²õT±p¶æñbÌvÚ á¨ä÷RëfZº›Z·S±g·¶,PFÌŞ"¹åâ² aÑÉf¶M9ğÊ¼“0£3RÎ+!w*òƒÈ$^ØbUò7ÈÍ"Ø	YG´-lÜÏÚÕ	®aºı˜İ˜òr¨]ÜsÒÌ¾È™®rÁHÀñï±íÕ
]±ğ6×ƒ_ÔAhY=¡¦ÍZ"q¢K'Ñê½ÚŸş1ôÆÁB]zCØ(aÓÕ^¼tÀ{rŠ¡¤ò-|¥¶^Õ™Q’T¥D…˜»ÆŠ{,*¡iŸd‚ï›±âòwÇĞhØQ$XÄ=W,”ÅÙm‰Xå‰7p¾ù£éGƒ¤ùYë˜ƒÿ‚Ÿœş§Õz´ñoìáRÿó¥æß €ıj:iŒü/ƒÿ°ŞŞØÌÏÿCøµÔÿ}ıŸ	dĞÃ©wœg“çNµeÏ‚Ñsm$ï5á©¥Ü'‡çur}‚v™d­*÷,©«_#a>0?“eèÜg{ç™eÊñ°‚F¹ÏågMïyƒ1gNó¼Á ˜¤	K€JHì—›|&ö;›¦	áYWŞñÅózıYS|E‘Xˆg™7l8Ïš0<N÷Ù"`‰†|á<Fì¾µU÷N§ƒÏ™s±p–iĞS§"‚ÚYVÒO‘ŸÅÏç•©lƒdÉÒh€Ã¡
©rŸ£ô¼?áÏ³&Tq£VI;ËˆVpô«Mƒ#za˜ÉÜ¦™QV	–´¸ÍÕs§]Q¯¨GüÒ@<Y—¤àZI,ÊÓ…› ‹¯×Õ`têTJEŞÍÑP–.Ô‚JÖfä/Í)@¾äØ—S}†1ÃHü'1X½±ßaü‚‹–™óoËÏ"ç?LáçãoÁÿ=Şx´äÿ¾ğüëkùKÎÿÆúF+oÿµÑZâ}™ù?uñÌŸ 
+Œ¹Æñ·&ãö„¹hVÅ¶§¬õÄe„*Ô†¿t4ËT#’_®Óè}Ëö·ßtÓTóT%M£œñ0eéíîöv{Ùš³ØÑPğ0ûÛÓó\Stz~ô#ı„K7üìáoÌÁœp-‘5/—Òä² nĞÉëN«4«’­ªVÖOù)W|ÂECÆóŒ)2kâHã9Y÷RW`ìvº½—G»ÔXÇ`í‰W—lö0óèÆ†á{8>à\ råyò¼uëeôÆ™\,C²g˜6Ó•Su¥Aóò†d?;$5TŒ¯“/&äyL°W”XŒ¾“JÆ**9´H7ƒ§É±3ğ•Ù6İz^1¸Œª"cjÒ“ãc=™1e˜¶Ä_ÏÃçóTN(äúKÁª^‰og1¸ÃPgpiÀ¸:^›I¡bäüå—·"ÁL6I2–ØÙ5b0ñ·Ù–Ï‘—¤§ÂT›º&´m‹Õb¡]_ÄB[5_rì$áÏ°Ö„Dâ(xãkF¸-Bß›[¢«<ŠŒq3ˆ¦ã”y‰å­ñÖC¼7PÁSëZ—¦F[¬)ÍÖŠ|Ô1xØsv¹é©ÚjèMÑk,Îš‰Ê º‡IIµËĞ—õK\ö¸uşPX Çp/OBøj;9şöàÈÉC³­úô õ[~¥#¸+!´Ìš³dœÿ¿âÿChe Œ}ïNø·€üïñzÿuóáãÇKşïËÈÿ^ò©÷†êø„ãû
±æ>Ù„5²€'>Qa z,†!Fgy8<'4yÜ9/<(œ‹tB öÜ©ÈXÏ$.ã6Ø$òŠ†ğ²òl>9Äğ½tÚf0\†´ğ)¦Äk>ÊĞ¥€Y¸4£ HÔ€³ø.(7A‚§lf{o=³-G­ç¿³ ”Uraª›b¶]‡‘ç3Õú;hªÄm‚›\§ ¡=¿ÛòØÎùùOj|¦JÌØëéÀ._=Ğx^O}0	ÆHBA<ÂH\â„²IHnŸBdGYŸ5‘BÁ*šºÌ5ß‚œµ¤%¦Ôñë£.ÔÔ[
HsÕW%]¨ß_¥”Sœÿ2(0šAr·§ÿÜóóáÆFAş³Ù^ÿÿıß§†°‰íÈÇÏ)„ g©Ì®Øyà¥ä‡+ål
§:âE4ç’ó€¡Ø.ƒÑÔĞ~ô€‘k' Ñ~÷‡ŞS}£*V@ş>>ÂêêÇÈ6ÁAÀÚH64N$B–`[Q!å§¿ØE{W: E&uN‰ìé}¨Ñ,ßg«iì“‰‡¡ß×”ÉŠÙc'™úó|8üèº–è¹÷£+sb0Ö†$ÉN”Ãã&ÚÂg›Í0¼gd¾®—ÄÎù±P´jØ5/Ñç#2ŠPÚq®	ûy«ÅzZã“k˜Ğ^ Ièù8>àtÌÃ.{Àµš…ØGp|¡{ @¦$ ½”WS:wøQ¤mü$¾Ò¢Zğ²zV9F‚+É†(«ò‡\åÎ@Ÿx‘?³3YrDˆ2É«İ¿vwJè”0õi»–‚6N20è£÷ƒó~¸Ğ'ã\hçUø¨NZó‡Ã0½¶g¢Áà4iXúg%’“?õ "˜&Z’mX’G-ø¯LR¾0Ÿ”­ËYÖßÉÑ>`…ê¶§x–µşx‹õ
¥4ÖË–ğ¦A·†XOB
³ö["îÑF§)ãøĞzª¿aĞº1,Æ™U‰;ËLŠ¯ø¸,O¤0š,‡R#+VW1Yò"C“Hâ›IÖäz¦ÁP%mÅ¾A]0˜XEâædÄWŒÔ€/‡üxg´¥Íè­'ŠY¥V¬éíã3òJ¡)AM””	8ª=>832P$¶ºØÒ	ìòqSÌ÷ÍòAm–|:áµõ\ıro—½Á}ï"Hò'‚Æ	ry4A$ƒÏXÎ#År}s’ÀÑ¦qÖ'Ú6ÏÚöw•i¶DîÙhafèwÍZë%,L
'Ü$›Ú1„)Z—_6 z ˆ¦ã!?¸ÛSÈÇ-]É7*ü`±·/ØOÆêÜ'/ŞBD4»ÀğÍ„rŒZhpşÅô¿wÍõ/Îÿo<~œãÿÛíÇKıïùÜ¿ÿÍø,™léÿëìÖjk?dšâ—óÿ7ØW©^$#ËÕÿ¾ãÜ¿jdø†»Š¼UÓÕ×42Õ33ÔÌ²~æ›ÙıûRñ<¿¢\4¶²—¤oS,;éİÔ–ócöF¨á²W3k»u>–åT*W­9Úk%­È^æßÉó«ØSe-AÓÚK@ıj±[¹éÒtİæŒ‰Ï]ê¿s
p: 
\öA(cçS\ùÌ1fhÌÈ’ ’ÅkÈO¾¦DÙ>³ ¥,‚ªVZ AE ³L7_V€…4%Î[‰Æ¾¬$ó43ÔøL ãÉHk©.Ÿ­•P¾¡Ş¿énÅì& z×¤LUë˜6„9)«0(‘¬æš¢¬ÌÇÒn`ÖFzkf"ËöRÉÏ?it »(2fCpÇöv’ëñ1*ÙyCh˜,”õdvîÒşK‹;µ¢ä›:Kaê0ÏÖ×ˆÛ*Ù;@¥¢EÖ˜tliå øÿ#ºá|&uò~AÿŸÇşÿaûQkÉÿùÿAJ«¦NåŸ1ªNXU^â¹.qIJ-¾w£ àëñ<£+¼ÇPZ(JSê¼hÈÒëIĞqw]¥	FøK’y1#‚[%NC!¬A¢$|ÜîDi~6ŒÎ„†»yÔİŞyÓ²w•ü˜?ÒäÁ¨ÿ&tÀópB×™»½!€~YİÒ
³uò©Ê¨FÆ£‘áÒ.ıh2 ó…—@ÿùÖ¹£#QšuÊ³m]i{ Z"iM±J²Inşä¿¯?©ÃÿØC3QR«õëåÒ¶ZFb£~©r‘Zû€-ØóÉ@•øë²_ÿa{B"Ñ$Ff!ÈÏ£Öİ'n=ğ|<nbo 5A"#»8{¸öB?~éD¡I
I¯>C"¼0ÑÄ¤²›®$ÆùŸDCÄÀH&0b–³³PàH*~=Ñy%M×àùŞDc²µ¶ÉëªDŸTB¶êOOÈÖPWTÔS’,EH-µÄh³NK]”&¿ï0ErÏg²QE³ÅxF;ö	7ÍB£ÔÀ/+ä˜„e©uÓ‡9ß"?Ÿ™)¢êõşIS,ˆÖz&x>"=9¡XÑ5nÁ˜èNf7mŒH'Q U$Lc˜S=v†ŒšÑä<hiÌŒ_•™kBú&Ì± {O¸{5ü&¬úªWNÒ:†áUlÏÌ5Z¿.dG‹V¨óÒ rùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–Ÿåç_ôó.ª,  