#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1480963930"
MD5="a95405a46f5b0b98ea139502b425c715"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23312"
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
	echo Date of packaging: Tue Sep 14 13:07:39 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿZÎ] ¼}•À1Dd]‡Á›PætİDõû	®P©LvGyêV*d”çbÍÃ¨]4t“O¡÷¦O\A?ïw:¬¿ÛQ±®ZâÏ?T­ğNò8†lükR’+JcœÏjH,–l`n46¿µ2ş¹íGÌU# WDAÎ"îB{3AÊ·'¤AÅÅ#ŠÑù@.€…kÒÏ¸7O¸t‰…Â˜Š¾ƒ§]ª+^YDgæ?`—ëŞ|ÿq„ã’ï¯‘+wÒ80¦ûÕzÌƒ "£µ,hW
_Ùñ‡ÊÍféŒª¹ŠFRCéERP>nâ^ª]¿”_YŸæÊÄ?¦p…‡	k¼n†ñTı[÷Ê0áªÑšñêIxp/QñĞ
]zEì!¥ 4øÜ oR÷dÛÆzG}™¿+ÉÈÀ£,±NâšŒLC9ƒ&xdÊÖ­TÚ%”w7x6™Àª%Ö …­Å:bÈ8\¯É7’,9IË¶ò«œ,DÿU|ï¥]#¼–Hü:LÄİü„°Ö‰Y­¾şE:P”¶5 “Îx§Z±Í	;ÚåÃ£~¼S­¾¨íúÅtİ7 îÅÌV+`¥™@Œq‹™Ÿ°yÔÿ©—+aÃWş’üQ)ª`¿Á)¸T×$$ÌA5´ûFç–NbˆÅT.ããm”ãyà¹êY¬>Mæ@÷ƒQ}î´/ 6²º~øï¢QC×ÏPgv‹9ô¢pê:çK±ˆcnõ.™­G; EF&72¢_öĞ¶¯ÌÕD“Á<;ËYY,Ãrºƒ†{İı¯éî
Ö/çoÈ]#ÚÁ—9v[S°
ëü®F?zø†Å<á)ËGH€<k/Ï¯Äà¾ñòO˜‡•ä½Aü[àDMöÿÁ‘D«4Z=ˆç™¬Ô¾G¹Ü#”[TTº©ÙTà7|–Ÿ±ºµqæ%=®d·uÒ¼Og´‰p:ğ:½Èx<üºò‘„v32Ñ.ÜµÁ®Ë÷¹¡·‘ÜGMf+hò¶{ümÒÀ
çÕOƒ0‹.÷É×õ/- l¿œ<5bá%}7a(\È\V°¶wÉnïzÖFAfkšê“_Âµ|(†5ŠÜû)ö0¦Ú¥¤¸¨nÍ»µ!´¯CÂ³¶	û ·€l‹€¥Û.Qø¹?‰ èªZ ÆÄr<•ËÆò”y™Àâ_½v1·óÿ"Â	ài‹î?.Nfô_)Iw[ôíş‡‰ù™‹òD±7,_Ögnd_xiá*–…š9ßâ[™€ü/ãù|Y+n4™Sªà[_§Yğ˜ñçÌ	…Çÿ‡'ÊÍÑı5É\T)§Â‘>	èëu•«¨úbs_ı@³Ë^“i‰ËÑ­99=ÉÎ[²¯“Œ	ÛÁáK:ó†‘%ÀA;iÜœ?Œ¨ÍI†Q%ã xvêÌËÛßª§Ù?¡‹ªF^&æjˆCå×ëßdİÚ—VªCÖWS¦ã…º£š°O=ó©O´ìveyn³UQîuùl[B›¯¥rµÓê—¾ç"Ó¬"—Ş¼Ä•ò®«?^õ:xà› Í(DùD3àxÖÛÂî˜*~0ŒÚf#P…¨ŒU'±“^e³½V,{Ù‹UöYL_õçvcm…ûcSqØAzMv´—6DçHïï3dÃ¿L“;}á¢chúş{6ûj¹¿ébìãì»`İ'?_k5ñû«ñÖ†–´Õ2èº—i-t~UÕMv†º¿/û#×á(‹òı_ùÄÇ¤æuÈÌ¹")yj‘G-<YwÄŸ–¯W¥²ÙøR<D{3vújS{Ên„6Ä¤.;GªX“ZbOÌò˜¦î½¦‘çà÷5‡(¹ĞÂ!É]Š%)N¸´¸h„Zğrk %„Ÿ˜Iˆ"\úñEº$áÎ€1™H“O§¹q«\°JÅ„}Læ\õtl¡yÕª¼›º6­üTœ“8BäÎÕ3Ûûö0OõĞÈ°¬Ìâ!.Û|³½¾äßÓO¹nvp.ì
DÊ³ nø¢ö¿:t¨QÔê[â0#«¬VğRGŞóe¼&°5ø´¥ïïvg@™|!ß£Åaå’“äp™
‡'CğÇŞ¿ˆZ¬>`‹ß¬¸!0«'F«ù¸ºVfM«í–ÁiÊĞ¶3ıŒ…(í}'õdƒN”_¹´ LZ/M×\nˆŸâä‚(»'”2'çÆøÃ+qgØıwmğkDi½«òıøİD{€”¤ªao¶	Äıa§P£¨¡Îİ'X¿¨{MÔ[Éßšøİ·t ò=Dd¡Ò­qŠ;¯ hri
wôÉî6á·ôc0(?ŠÓíí´õé–<>F|ZÖTµB&‚™U((	3]|:Tğ×rÇ

yÂ“ ñJÇç‡,u]z=<O9ö™wŒ—	Ò`¬‡±o?ä£K/µÇ*2Ÿö’í]à¤zo·ÔÔæby”x<ClÔĞTè
¨ğd–ÕWİŠÀÄi–Ú_Òª‘M‘¸9~Zòt@}²ôíñºPºZ)àC!=¿ŒZİAvÿ;`Û"?­·=ô;	•p‡„ãuc#\v¿'IÈvÀÌ¼t…Šw«åG,ˆ¾ H£6ß+Eny¥ÙJ÷À9×¦¦fÊQÍ¶¸ó\X| ~ğ†Íí²íêd/r³]ı‹R•.OÏâ(¥.óú~ù˜Ì³Ñ±°…ş7z7PDj€é¾š€]–ƒº$/İióxºœ"·±
År¶Ì¼Èl¢Õ&au:Ö¤¯òoÅ©« n‚]Åå¶Š\­s«aœÎujVûd’û“ŞèX* 4`aøPxÔÑŒ9ìÈ[X¥8È\wÎÕ‹ÛÄebâ(zégª–—n[ÑTµÔw7¬L,ÁÏ@)8
gXÍ;¡:w-s¡"IŸ©ò 34»mÁ ¥@‚jÕ÷ÈîéXCß“wN†¹jAÊÁ9'<‘èÏåìÈ?cRLÀà ãh½Uûj>‡EÃá‚§ÉÀ™>Q"¼iLŒÔuAfÉ¿€DÕ˜œ½ş§R<h i2vdöõÇbè‡Ñ~ÏTšXVØü›*e¾ßÍæÅ1X{„ñ<èbO«¹×ÿ;]QF:œUÈKœäıØŸÒiUñş|Zñı‰IÙ5BÓ1"0•·Ó7¶­­1à¦r!†[v‘šçó×FÊR¢oGšÒNccÇ¢ä(5¿‹9À	š—_!å;ğ¯	m–ú8a{~Â‘OÜ©xYT Ÿ¶ü«ï·O÷`6}‹ùYŒ’'sÄi·İiJ)T¿$rÖ2zv-kmÈæy£œ®< 
h³_P7qs¸ö*Š­Óû èœÅóETAË,“jÃ•œÃş™·6Y¬ñ0ìÓU…dQç†ğäø¸Ï	X5İ•ü¨p•£‰hK¢úÔİÉïmÑ·sø?Ü‰äcâeìÌ³ßâ?™¹ÛìY:êÇ D»8İÓ¯È¼:å^WŠa† Ò?Pú°,`í¹œÓ#Ó…±™Éò<Cm*Wˆ“ãŠh¸r¿òOù0DĞğØR¥®ZÁ8 Íì„.±ÊíEdîjä­g$	à­gÍ¸iØu¯Á\İ®¬,Úß¬Û¤·`–˜ïçâ{íl¯Y`^0,9`>§"Çgv¤ãòZõ€ªLV¾‹Š\ËOÏl½Õ ²q,ÔfØNÆ´óGttU±8vNvºl(r¢â’®ö:Xm~/g„H
x&,ı“cë/Æ®z–F>È{{bf;ï÷I¡N¬3¯F¤øÙ÷ z«~%É£ú$¿`GÓµ>ØTß	¹!¤Û7YâTÖR¹Ø‚ë—ö~‹6÷YõÇIü£Ù´…ÿR9Ñ0|Ã.è|„PÌ×Éâ1Æ»‘/äÆÌ”1»ÆGUd«‚ïú»N6tİ,vy#xJx6»Á8ÜÛ,#n}Á¥Ën2ğ.Ö$n®ûs»ø€F/têĞ|½&ùºüšL¨Pp#í9"©Ì¢ÏlJTÊT¬ë–¸å('ÍŒ[¾®Ü‘Ÿ(K4tµ®q¸¸ñœcüb{®ë€"§5¿9•}K°%î™ı×.é¤˜;ÄtC¸tÆ)Ü î=tmœ«ø“şQ;ğ:WŸƒÂ{)hNazN$ğ›\ú^ÕØ(¼¹N{OåûšF€ 3®?-"ãğ¾ÃåbËP<Ã[Q˜†`ï%@ÁÈY(şíyO;ƒ–^¼í—¸«•ªÓ-úÄ“iğZzJ¦0Æ):hNÏW”{Ò'È±)ïº9,%5¸ñòIYİİZJñ6–4·ÁùH™ôö~¸åPÂ—ÀŒ|µùrgxˆìwŒıæ%ğJ~ØªM…täwÌ_àOaªÁ”˜vci«Z{'éÅö,R8‹Óy	.â7bxxfıAo4/]®8¤6qr{±¶'±CáP5ŠKg	Î}ø›v(‘›„Kó#È‹&üî6Í*Ç3àÂâRÊ)Iñ‡.2èEŠÁbí]`|ºdcª:wk8@K fE ÉLúƒšTéĞwír=û•Ccº£I	Æ·«!êªåü(|toeÄ»¬÷¸ğÇïİ#CÑi¤êqu¦Â3àÛ÷b]Ã”zƒÉú4GÌÑƒ•°/\W˜FwÄ€i•ÂüdÔk×¤ôogelEÕøÁÙÆ¸ÅµQ«M#Y”İƒaQ
2&¹(|„GÜ¶ûüğyDÈFa¿ºl5…,Scš÷Ô¹ ½_#úfÙN7Äôkr…c8İ-'2úóF7¬¾A/4ïâ¥Í­yõÁ•?@·®‰}aBu§³MãrØî
Û'’[åõå(µÊs5Hg7“‡‡6D{6º’†uÚf¥3ø‰•²ñˆXîe:izÁuué¼Cdg>©Ÿv²¥Ÿ7 z2*ŸmØÄKöŒ`¦¨âæv3é‡„<çcÛŒ>¬iñçmd¿ç®ègs+¹íÃ	8Ø0HëÁ6‘8üBÂl„ñ†İ¯j!ZµkÏí¨-Õ96·Ñ°Z ¹«“å’Ö@şÒ—%ö{ÀÖÛM §Š^€@‹¿’ß}´şÓé yCŸ‹RÚh|¬¾%sômƒÂÍ^0¸.kàn–Æ­–UlÉ«vÀ:8¼…Í{ğÂ©Sãì3$Ù½KÈSÚ>€]¶¨›ıobÊ94ÕcR	otä¹yÄº}^¹ó¨şÇzÙâá‚Ô*/z Â‚i´qñÜDZQ­ÁSœà>øgÃ<Ä-Ûš	¿±whss\sçB´ã²Ï§j›`Y‘ÓGÔ¯£û‚%%'¥UJĞğ"Xt`BQ'Háæó×‡$ÎOjÊİšÚ‘7wN¸¦…)Æ›¥š8¹õÓÂ]i)ÓöQ/IÍ`d]ÖÁ[­ËbH)çÈƒs+áÒArLÏÏ?ÎX<tó[·ËbÆé³.ÊìvmÖt5Q÷¾æopÜWà¶“ŞGNl#;èo›$Œ‹© $Š2{yyºO³%ç¤|zäC}bbûEyKŸ½Óü·û)İ
±×Gã‰<EÄ?ì™ıƒ´BÌıœLÍK5À»Cé\„JäÒzuõ¸]'u¾‹ÂñŠ²Ç–ù?QT²±cşåD1"
í=AÌK™¶(<ï“\‚†×ü5ùÄ@­8vû¨N˜÷{ô–÷f(5tSD	äIËâúFc¨ZÙ©Öw9Î	îŸíd(àÈ18ÄJj¯s‰Ï5Š®.”Ò.Ñåd®‘Ò¡ƒÂì\¡ª™BHÆ8Âñ‰)G,ç8·á¨z,Iîú fÙÌPÉ·y˜¥è¡íSÁU>¯»ªÿö<Ôˆ¯{•¤õCÑ-!Œ:+¦¤	Ğ6o{ÓmúN½ûì‘NïG³±ùP"~x>Š—^]$5Íè#ˆWæ²)«i\³„\ğË«è0Åß»ø0ìÏ´vC0tÂm¤.F÷["±››štGY{]…XºŸ5œ¬Â'ê#ì×&ÀWô­œ
ÕÁA©•Ùã¼/ı^É­N0®³G¶®}_<RŸIlÛƒıµ”¯Ü)‹å–œ×[ŸÕR©ƒR˜YĞº5¸31™$F¾.Ô…ŞbÍôè÷9û ë¨=ÅÆ¾@Ô²JÿU•YîäG´¦e5?»FúÚ’ªœÉ›¥Åçá¢ë@Kşƒ¥ÉC›p°ß•óµÁ²öM4F2©š!¤4B SÉ ˜=ş+h-!–\8­ÂæiCÆËXsD]ÿÉ?C[-ã=­`¶ ‡êìŠ¶in™YíºÌ0rv«Œrzı±ˆ¬ÍáŒl¾ë EcEÌ¸Ë&kXú§äı°l‹ÕÚšW3—½íÇs—^ÕİŞÃC)xûy†µŠyH“Œ	
•R0•ˆ“8ÌñOe®ÛÆ³ªÕS«3”õı9gŠ^øRÂT_®f²	Å‘fJ£*i´ó\¬òƒ°`ñy Qío[¥Y%Uî_§[J/ÈûRm¨·/ÁKM(ÃÛø6C«g×´Šûûtq´<ÎììyİlúÊÀÿZæ†î€îùï²şqÊDN›’Î¥A©N	‹z%ºõÍ+t¡¯¡—,q‹«¡^1üqVìë—]ºÆjwø0ûÁÜğâŒ0Œ^Â­ÅLŞkéÓëKqº÷¸“Ïu°A›B¹ŸüDel2™8‡dœZêí°myVùD5ï)]úº¾96‰Sówèª®¿Äæm!
6'İùT¿°¥\ŞEU‰¸fôBm†à5k‹¦#IôÃÒ‹ÑÑ¢¶ğ÷¡¯dÏCb¬Ñ6Z)h˜¾9Óí\½AÀ °u÷‰µƒ+h(LOU…J¢2Y¨şÛ¿gm÷EÓ“~/Õ¹D³”ë¦¤ùªèi#¤ğ›<¿Á¨²R<Õ3 ’ÍìÚ[g“¦lßËSĞ'FşV'ëj"•½‡(FÊW¥Jš6´&ÇÅW‚lrpÑÆhÅ:ˆ¿—ƒ“ÂŸùcJ•ÒnÒTGĞa·¸ka%g ¬Ò°e"<it‘p£-®C¸ÄÄ”B:ªó3(^Aw?C†Oñ”¾ÁÎŠ %IßvÃŞ»É½ÚÀˆ„Úd©Ÿ<lºuÆãM,WZ?5 +‰0 JJÆXU†<7_?çÎÆåq}aC¯z…5A„Êñ¯ök@™ÀJòHğÊ9ø·0OÓ¼rİ,àbŠh]g)©€ôg>´Ùê¢Ûg`ù4§%=MŞ(å$˜JºpÊ“Åş¬å‰M:ÕaZúâşÚ[¹4$ºõÜ¿^âqJ [q`j—WM>öRªïôÃ©¦7ã4{'İÿÕòLŸÂ¦ÙÔP¬gîòÅoùÛkHpùm>CÈ„g¬<êÕBn418ADÈŒ]‘.6GĞfßÉtò˜U_¦Ø”Ù…G»¾õ-NäõèØTÏJ!Òr6!“œ$[˜›:}W>ÏW\ÃÅ“¿ƒ£}hésëXGÉéÀ…—™3ÿ¥’m*)E]ÄËĞ†¾í/»`ä2ó¢Ò¨bŞüÒU}m,;£$3~Á„¼‰
„ÂöY×#nH2âXwûßŸpg÷Ãí<§}X¾Ä†Ö$-,÷Õ˜ïàš½6”ÖlfÛ'Û›·¤oDÿjQÑóù–õ;ÖË]bç[ş+ş#\ÜÏ_ïRÃqãBØT¯Í(ä*ºƒÁR>Æ›$Eï–Eï2vt_¬¬ËIÉr¯‡ÛîÓÀœ‹ÏóCi4#U=IQ(æd"Í¹VB>ôkÅ#7'*aºCë£–Å°Á¦
jslÖfêV‚Ñ¨*@[0_7£?óD£ƒëézJ'aõÔ}Ì)ïë?yıoOÃX±‡f[f†D
g±Bƒ("á–Y=n4·ß)Í>BÄ~1ß>k/ç ñşhzQ“'ûN\ä=bîd+E-Ê|ººŠğt9	=†b2")>ŞK`Àƒ—§ä„‚y6&zótU1µMa¯JÓ—ÊüV9ßrU;h^mıFê4;«ıô-pà´g,[L4O¥TuN^,")'Œê+
ão¿ÎD]šË²Øg¾O¿—ğ!õ?‚Gøó¼Ú×ŠZ×/t
vVUâçVŸ03Ç@UoX:ØI³º×šĞjù2[kPÂ™ZI‰ã¿iW5zg:µµı›„iåîêrjX ™é{‹æ<^—“Hí8¾&J`µ™Aù~ë¢Qµ¨ì9¿EÁ‘«’t:èGÆ}ëºï ’Ñ*¦$¯Df?dşŠL‹è>âŞí?R‹jYşè†'ˆCuV4Ÿ‡mjBO0‰n·%şP@­-Ñ2ÖûÄ"@kzì -p™› ¢íŸKÒÿMê?Å°ødUY»®ËU
h^¨ìÅÑuÿÊ‚¬LZwx1ç+©ì	}æ¶ßÍu'€´8¨Å½ AëÄ„9™¾O_çg^;S¯£Cvú~û-plän¯Ì‹7í§¹¦¿iÿ3;YŠûyK1Q	5ÃçºëiÛ©€‡§5Q{RÊ]W{X"|µ€qÿ¿&ÖUµ¨MÕŞÁq¹¿°±î*{‘­úÊg…¼‚âılXJXÿœä‚	eîazSOQr¶@ÑîŒ¼ø°Ms„±,1÷şĞŒ{/'¥ûİ6í9ğŠ‡)w÷'¼R9¡ıo›qPâ}ûĞún©7)ÄƒáGş¢±&}1­üêc`;¢-4¤
N/¢$ywâûlhÒ¬IÒ) &…‡iŠkaÃ ~ Eó£T‡&è­rúSK¢ì„{ˆ>à¡Ò™Ş5I½B„»ª™¸esÄQÓt§±Ê9ÁìÎær2\^¢6¶¶FPÑñæ€62%äy«Içâ8ã9ùmÏGï«“@ıÛ—ÃÔ~Ğ$S&¯áó<¡OÅˆ8^“çYºì×Z9Â¹)A€¯3Üâ¿G·x™×Q^ã\éeUşƒ›ŒÉ©£²º÷¸peLÔ_ßò­?£R´P®²råæ`d€BšÖ‹ãıB¹–_º6;ı^w¯¡†İº;á³ëxÎşfyÿL|ÚÅôÉ"ÊsóO—bwN/V§ÕB›Jó¹ÄV¹®ŒúX˜”X
4d?ç™Ób‹‡&—àd òÃ·#²Ã»]|Od5€|³S¶	x§.Ÿ)b¶àØ±doÓ†äL«óæ­x©€¸`NíÏÇ¦B\ÊDÕNÉÕIWÄ­:&}“pñ/Üø,¿ô‡–OP¯¿+–D±[&ğ0=ûîô:á#¹`(çr²ª4ĞìÎk¹—ö í¹	!EöO–-¥°§ŸÒ(tÂ7\.îôèŒJ¼/Ù«Í€g`pO´0¢l/âëz 4Ïî3ŠT²®%´™ÏkÊXÊPû2X€
Av>¨ ‰É©©3H> ù]ì©~3ÆvÅ§sq‹­Ok‘Á;É°M46Á:Û6|1 ÆJØ¨²‡‘,Ænı•êì±ºK8,
•}	õúÙó>6+_¹óˆ‰|Z"¥C¬Ê‰šî6]d–Ğ†ødê@ÙC0¶y7Fcw²
ŸxqpíÕwN ‹,}ùÆlpç~T}äKE,xu‘¾²ÏvMàHÜ’‘@)q²á»İ7+iBëß˜Ï-KÔöSÔğö§P« Q×S}=ÊóªR“²FªÖü¼Ó›N‡EÎs&L«/ò$î~dH]ÿş`Ä.%³}ü·y¹¯”äZ‰y(”p~N©†Kâ;F:&æH1ÆßÖo[4÷ît¤ùúZÍ_m©ùÙÂm,PxK_ªzùì$ÛXÑ”ne#Á½çŒCŸ¿1Ì>uÃxBƒÑs
uàµ_Á¢ÛfŞ *­¯ëÏ»m×=n¶-éHR—r½£SG^6‰[ßb$‰<=#ç`Ğ(Xr#†qöLW_‡ëÔ8KÍH4ô8¼¦¸Ù=…ËNèòè
ä®Py„=éHò¡däÆÄW®Ó-¨
W–‡kdÂ³H²D.&Ş+ı\¹r<œ
Í¼IGpšzx$J;2ÑÇW¿˜_ÕöBÂÛòÑ"hÇe}|±t®(ª§Oµ‰XNÅhsìÌ˜j$É}lø"ë(Â^‘o5×¼Ş­¢0ˆ°ğVš?®bü%Úö…È|Vn å–ú0U¾#t¦åàó¯_I{”t^hãĞ<Hr>åøìÊ{ånÈİ˜ôúHPàg•"èùò˜¢ò°’‡ä0­}Ÿ×ƒ’£™~’ÓYwÍ§ƒ¼xÖ€$¦¦$~z±üPÜ5! å5…vNo©Vˆ›/¸zÓVhU­U¥,“s90ib‡hşş-¶UnŠu¢,
ûE8™jún*|^ÀÄÊ»'~Ü´[YOšÎ\0Å?Òˆjè_]˜JâÍ	—Œ1oJn†HOïØ-W7VÕâsùõúò&W1v´2‘WÒsÛËÇ“òŸ
õm5P8k§h¶A%ÿÿš€?;-L›Í‰ˆ»§ÁHRû5¦!¶Âet›Šåï˜ä@õÔÂ|qı®5î¹Ğ;d“ñG¥¼Ù[èO×³¨Á€ˆy«Åe]å_q‰!³Suf-I™âÓo¤•Ï¦hº›,çû<thÁEÉ`vá5(ø«­?Ã(IÔÛK÷×ÿ}º<Öå*ÌÎ´B`«ç)ã-Š·›UCÜÿÄ‹ƒ·Ë”ÌXìlAœ’ÓŒYü @ ›;Æ ±Ó ı@˜¡wUF·µ%ö‰<’‰i‹có8u6>eŞk4oG	ÆHÖ\$öı÷{¸ópø;½¼Eq%¶ğÄüÇw&µ¹»Aù~/s\Z•S‡¢[¶ºL–¯ Î¹Æz@À>Á	;Ç1õ·…d—'uQÃWğWÁ¤ìL¸Y\ì–Û×šH,˜bÓÚ#vè\äW8ŠÄşDßm©Í½X5-.[*H#A”ÄÏÇeb}…¸ë©;#¯<Äùú´ö™ 'J!(B…´y”é2€O¨‚WL±àh,Ëxgxt –ò ±!Ù;#±qY¢ Æ|<>¢zşÆÃÒõ	~Dbvxk>ãHãµ+ñÄ$ÑY¥ÊlÜ¤’Ê^›ü?';ÿ‰¢9DÑ095Õƒ-ş_V•\Ö›—¢+ KÚeQOß£“2I¨ÖVí<x{±øóC@Ã¶Şvmc\¶¯Ô{âu¦^ˆ¦”9œéÔĞbH	ÀE4ÜhDgtH@nQ•¨ÎC¾°–Æ£‰O@ªá\„»H
¢Eµ™şĞ{½ƒ™ ¨ñößy¶Ë”J>Ä§.¡˜
2&8&˜ßSi¾Aâq>>õĞ4³w‡œ¡x'O„môÃ ê®q§»‚U«ÙŠ/êM«•ç÷æg
j8 ·¬ÚôÕK&iÜï:Ÿ›”aşLÙC…!ÕYí'7²¸ˆ5¬8êl¤A•ÛôŸR-aÎÚl(º°f7'Ï8S@ÇFŒ"MÄwfê7#yŸ²ßù—
Ï%|0[Î<v«NœŠp{³M×…"˜7¹ò‘íİR]âıŞY'€Í!¼)ŒÖªÃP+Ó‘û¨„[Î=ó›[á¼¬,Dç9ÜñÁ†ÂğI9&[wb³ÿòw‹Kr'6İ/,NVK©[iPÑ˜6t[Ü5èfÇ;koSRÉ¢ßm¿3ó¡èû^X³w¢®ùC3 GOÅàÄ~›æ"–ÌE«3¸n~¦~–ÊÉ£ö¿s3@%¼ë?ˆáğÛ mè4”Ø(Š¨Nqô®•S¥×‚õbÔ™Á·9'gæ·ü
Ô3‘Úä?ê¼s&‡º¨ÿ8/íyñ?M14òw<ÇZel$óÜÁLJşù@Ö2[x´†Îß*wğLez=cÁ §Ô¶8Zä´µrªûºÄü\Ì¾“Òu®è¨Ò´Öì´?º*0Ö²éK[Lê~n
=køî°ì#®~râ¿ËÌ %ë8ğ ¼±†X¾¯Ô¤f™^˜ú¨ÀLcâïYcq¾‚Ã§¡Ô“¬ƒ”÷*†±yš9DS¿¾ÇHV&¦.èãŠìÄ€÷­ÇJü·±öâà	 fØŠEàpÛ·(ñØkZj€¾vÿê Û/Ò*YƒY‰ÈŒù”ÂëØ
•dŠ€SäpÃ/Šv÷CÍ+	eµÌå­¦Wú·7KGŒîŒ"ñä[“mÌÎôœÃùø4uå<Wì¢\ğ†ˆ	K´(­öï=ob¨š¿Kä8Œ•¶„QYà„`NVºUhÉ -JÉvAbš’÷Ï/?(&œÛ	tœ[î€:?l´ÃYÓÈ¼½ÓNøY©šİ\%@Q¥§ì€§‚= t$L;†Íd9Î@¡Gdü×û#×bÄñÁ]4ıW)Üõšô=äğêCÚá([ÆÂ8Iãˆ)(—*:¸í]œ THÅç)¢álƒm¦-y`"#g¹£ñëªï{é9$)sfR-8ÔÖ{Á0šàC<ğˆ‚º±ÀÙ½e³d¸Õš[êˆë³i0ÇlU»5	£«Ë{jOÑeŞÍğÍÀ-ivU]˜9T,ç Ú ü‰j£Säâøû§¦ø	¶°¢%Š…ıƒhåk–TŠ‘’ ºxáç3BšeÁâQc†£½*9¯&ZDäç^ô–ŸıßÖ›Ó[Ü-æ¥úâuÄr›_¼y4dî&$ ç™mÌ»¡-l`Âªt@Û³¿€‘î…æoJ=HíË”T©\k}¸uÙTÁUİ'nG^øßæAı‹A=Z“>µ'
êÈÜÑŠ~â°ÛVÀÍ˜a¶!Eÿ¼	˜İ$1|$Iò%­ø¼ùJ–Ş•dóëãˆÆëê+Á™LóR`&y¸ú¾¿±Â±Î<00ËÇíÑióKÀªk?ıv±;zLŞã”YÂÇÚ¢ÄêWƒmzÔò‹®˜äm\Œ‘CŞó¨¿ÛG	ÕvÛZSuQŠZÇ0-\e¢%Ôñ†ÖÀ/+“Mw”´814c°Óäqm>xv*îØx×,áJÅLÜ¡ŠrãÂ_îK—oËƒšø¾İ™¡ñdĞşG¦oaÍ,P–¾ıÒ¶Ë±òï Vwó„Ç}
aHwÁÎ/''Ze'Òı™ñ2À
mËÛÔè!àÕå#Àf9
´£%²‚0Åã·@îÿè7¯¤YEà‘ˆ×¡—‘!-ué:SE¢!¨M÷J™2µÙõ\ºvKĞ—¤pµŞñÌ7—<õîivæzĞS*HöøIÄ0ØÃ¹lbÉİsA‹’%~d!ëÍUT	’y^/	Ïx7MÂóla¶"L3t ˆiQœÁ]WùT’ğ b¨YÜŸûóÍ"	 "8]^¼O&PêŠ«® AE}:÷kÔD,èe?;m62:Mr :†ûzy,ˆ)¦¼]zÕîcÚƒª!ˆÒ£±:[8#ì(0êúW¼sÅ¿z£,ËóYZ|o&2TòŸÄ„êoA%PÍ¥&«<&hˆ*m•Â	éºıÂ0ãöLáˆæ^’Ñ«Q·<†>´]ƒ¨<šÏ'ìn)˜±´Ó>^xß¸&"±ÊïµÁ>‘>ğİ§jB¦Øsjöi@ùo#Ÿ
GYª7ÄRŸÑ™oÆ/¹&¢øÓÿ~_Ÿ¤¨O¿K‡e‚Ù>óFh*+evVU‡£®›ÿŞpÖ±¤	»æ<c$” ¡ú•o)[«ú‚½×¦{÷ƒ’¿1›êğ~*Ì]‰ğåíD‘G&*(Ê?q©«>™:;ß/Û1`#~nGŸØÿÉ7Yé»…Ù¿ulQÓ>ÖZÕì
E|…Úª˜„™ÏºšÄÄZÈ±–f¬KÄ6ÂhøÏQ£/B¾½K"lã+õù
hç
¨Ì<UAj•yì»¾¥²D¦0ºOêäJìl®§ã#‚>{“
¡y$74q•E\s æ<Ÿ²ÿò„ÄuHÙÀijdı”,9ª÷ğUø!k@I³¬jG¹=˜â®F»¿-ÎNóì%‹Æ#¯µRâşi¨@ËÓ—qÔAşaTÑÅÖc*#ÖÂ¸Ø`í¡3LxïàˆşÒeâY=_@VmV-!)şt”MšC	èĞbˆ,†Õ3Jcy”Á¡¢MqÉŞü_uÎåî^[”BÁDñÏvÉãâm“Æ&IŒ€ÎœºÕá‹!HºoéÛ}hà>Ô¦ièƒN{¦ƒêw]¥\ÂŸdë¢UÇ˜¶|ÂsÂQE¿L˜ÖjSó	[=@ÉO)5 RŠRÍ¼ĞÏüÚ÷Á*
”TG‹C·`ós@“òØaÂPC*¥0_ªƒØÓŞİ4â.ÏÓ§Dã5µ4±…‘÷º\m»˜‡òù RBÌ%:˜º©_›BÙÅ¨[Ùßã­7§ôd™‘N­·šşüxb.­üÌ4E\E‡Ÿårª±Úo‚m”pŸh’o{+hÜ¥öùŸ,®ØJ%ß:½?ïôÉÈ´:Y“”‘è
¥o’Ó)Vù[@…×öláT£"%qR£ÄÌAB…!ó›T¯›o,³&  ú¡±i=‡H‰C¯óH)áümOÑPdşñh÷³,‰²‹cØTßO!”|Qô2œZögçè±š®‰¾ç?ÎÿµE#.Ûç5÷)‘´k&ã×JßsbR¤{"~&™«¸“w•krçsæaMÊq¹¯p&øÙô
Yÿ¾Zv®ä³NH6®€s}ÿ¯2†2QãwAõy#×ğ÷±H<BŒlQ˜âot‰èäÂšöÒ¥9w|ƒH™iRë8ÜoWßØò€ô×…XÖñŠRÿêQĞv¼«‘MÌyglèM¯“rÆë	F_Ÿ}7Î—Á÷ğVv’».¼[1ÏÿOüäØú!ãmÉA6"#v9«ê/”Cî…gøî°’cPÆƒò$ÇMšS™ºP–ïËºl­ÅK;ÒDı`*‹fb^Ä2**¬švÂ.¿Ë[@¾LËÙîEY}W†¿~¼fƒœ·lZ_ì#÷Yª´àl)˜stgr(K70}2ß¡WxnĞLÆ3ÿ’
¦‚3ŞVD8Ën&¯jã'¿Q¯!“,$@È©­ç\%&å{ÆØë ‡×R½%)Ü³ŠW’KÛïhóöî }8¯»ö+¿Û›rãgõ!Ó¦X1ïU:„ íİijíÓO
T¹óI€sŒ‡sNbéà¯ã<C¨ŠÒ Tí‡Šÿ_aà|„¸mG™pV	+‡Pl¹ù¶~DíÑJ¬·ôıúNÍÁFÕâæ;[ı"/#Êzõ§h(áãwoZŠ{*ÏsÎùbdM¥½ë¼¢j¹né?Ê’e«ô ÜÍaÃ–ˆ¨í¢ ËáÑçS’Ëk.h€USp—ÈšÄÃö|{˜ğŒ òâîÕ™‡HˆŠú³âû•Ô)×YÖù ù´†ÛÙ¯AŠ÷—‡Ç‰4îwşgœ»tÅÑ,tù*rİõ_±.¬:–¶ğĞ<‰ÆŞÛ…1Ùé0è‹¯!Ø—eE'1ÃÈ`ì»ŠrH'ÌU8Šı2"$ÈöúÅ"û¡ã4+®†ËjæšßØüò)@°™6p£IëÃ5Í úqæÓO@îúa&ª²Wô ØªÿÎ&¥İæ6ã&9·–¸$8BY~AêkqÀÆ:ü¯ã£å3ö­Ùs,{A˜]'yµÛu€Ç&zG–º…mÍ|]Kåø^Z¨{_5§`·İ8ş/3ï]+	­2æîŠê#Lšc¼6w²Ø–­8¸’RdüêÈÆLŸø¿6l^E'éÎğo™"qua™lüä/NvuË]V.>C_îúç»OçÒ½ fìÕÛk¹Q÷GS4C¹¸z˜+6¶Jo¹É¡ÿùk·çB¥>^í˜G¥"yÿµ?nRÌnJ%ë9ï.-ÄG+%B;Ãó “póRY¤sO®l9K4ü8À…ÈØÁ&ÓÙ_øh]©Ÿ¡ä8Lzşu]í 
vêkkytDDêıƒÍHƒÕ-Vm¦a3Ëoó°Á¥ı%Põ«Á§’Tïø|ª]CŞ6tÖıÈH—næââ¥üÿÉG™ˆ‘oèe¯0äS-èá…‘é2Ø´Š4<Í¡rš
gµšüÀˆ[4³DºK_ÔV.Q‚ß9¥ò8Ì8´œ®œ¼`»÷?Úimq7”‡Ğ¬vıÊ”á’,34êß´¦<EH×Ö@2òšbØèeÚQs	â>EÛÔ\c­Ki	^ÎĞ¿ÉIİ˜§8\Ø3šÌxøÎÂiJØœy„æÓX©Ñ
q¸¬(©Uˆ,-1lêm £Ü”©÷¡9níÌJÊâOùıe8²›¤É¯ó¼=“ƒ±˜‘p»ú­,M>ŸT(y\gõ<ÒõêNö¡Ãì¿&K\ïk¸?g"¾6#VlØœÓY½Ä é…¿L)–Ê>Oåá(ŸcØKè-da”xjn¶O¥s4äd…‡ş#2T8¡ÚY¹Şú‘DM³ÇÇF7—ïËwì®øÊi@Ê÷÷ùøBÌ¬¬éJÄ^‘å•‚ÙK»bÿ}ï‹ÕóşhøÚ×Ä0	+ŸãyXG€udÀ¶Ö#Ån–™ÎwX+=-èŞ~¦à¦bx¤èié©I¾–ƒÄx(Aâs²ûğ+ôšÈãXTà¹9»¹
£kÅ·È¦ÏUGca{V1ú(‘])Ù1J‡&]-gİ§¢8¥J­qfæı¶k`sÇ!HL9!9ØH^:‰xQ<1¯~Kcw®.bEó{à•EoÉPŒî‰Éÿ†Çş2ü7ìŸ¢Ä1È4ˆIZ É^İØ°ô~h#ÿl†E¶Ó_ğ4·¨#}ZÙáoB{_qg²@­d–;+ß“5öÎ~,øºQwRc˜Sœú<O„fĞnÔÒ©LSìó hB Ì%E&}o%dµ2A«%oê@© •«a	2<Lé!¼+zÛ;§!ŒÅ²Cƒ3|eèZpÜÖtˆ,' =KÊ†BaßÔ„é=]&Œ¨½át'Sø$­7ÿÎ“å,§¼›,·Qs‚ÏàqV'õH«–æ¬:¤?Š–EvF§·KÊRáƒp:òî³¶p×;÷áÛÓVËµ‡‘uì´øºg*Å~şºuÙH¤x¾<U-@KvİˆÏH]W‰7‡â¯â,‡ïN"¤¥ \ÂÈKìı Œ`Ïï×®O# &lŠCP¶Xÿl0¸á¬ë?=•Ó=l
 RÆ0EA1¢Ñ»U}Èh­DW“b¬ŞIÿ@À®·„@Cˆ6Lşöë1LáY[f×ö4i%½@†ˆu
v?Á–Bˆoq¯HyrÉ9´ÆŸ¶€?È^i@e—BíR´LÍş“Wt’4‹œPîÀ7wÑ¨Ë;ødl±[Ê_d^§Şbù¸ğã={^·	ıi›Za[2ê	(¢‚ãÇÍÊ·fEù\Èºá¾jGÇg8W3±`¹™şW>wÙYGåXnƒhñ•Ÿ›ŠrWfW|¸âÜwÉ›eIWöÈšEç¼»VŠ+²Büûø­|ƒ‚Kê„À&I¤3ª¤ë ³u»#´³d› aN¡¶4j(Ö+ß²;›ŸBí/{
2ªğéß~Í/=O®˜áàöˆNYÑÎy—	r;]òÊÆF0m¬8åfòÚ”UÕ½ÔDåŸ£R ¡ÇÕô9×†•h-¸¡öÊä	ÚÃN¿l#ñ°ä‚;¥ß«ıZ­òxÈb/iY×:=à†L*PûW€N,3ég °®> ‹1ÜEC¥0O¤.ùèÖšwä£åAwÀ‹åÁ-[š˜™b½c9î¯Üı¾|~9@»šÅ‰cp á[Q÷Ğ”Ğãi“ 3„âaaÇÅX©¸)Ùl%±nòÃs{Û¦,úiWË®ú½ZÍşŸ–YQûÚ°¦É¥]#îQÕ.?‰#°Q~z¦c¢Œë tF²^WVa‘9ŞpÁ]·új8gV„ÍA»|†üïGğ¢æ‚¿×| õ¡&¢—ĞÈX$Ó£†XÏ´ví¸i“KnDÌ_^IV%î<kvÌ"’q´¹h"¥Dê‚PYPi3uoÆŒ•eªÕş½ƒƒøë*	¿UOZIı4ĞÄ‰>[Ûå¬!ÉCïœ|ÆkõwC€w¸çsäŠOÉ™…Ÿ†8Ş€!øu¶ÕHlGmÇ7¥<ø‰¸8íÏ£„üv%ï’‹Ä·‰}ş¥Ó]tbçÍ7ÄÅ.ƒ¡ÒWÛ Œr˜Ç9IØ¾İÙz¬ˆÇ ƒ;óC±~rµJ$âL:z•Ø–¾Èn³6ª-iúÛÖ–­“‹¼§ı>ÃRsş÷ïu’cºûcë!O‡ìĞãë7İ¯¸è?BzJÚi;EõèöŞniŠ‰ÕŸßà´ª`¦Â{×¶˜/å¢Á«Ğ„ålxjCéó‡×%U7Zçîıô®9_.1(Xãs£®’„0ø—i¢ ÃŒÄ/\¬;•jÿN×Õl­ïŸ¦Ò÷îÆzÌ0å	gÕHŞ{ë¦Æ£,áé½œtÛ¯ï?_‹wÎ9qM QwÒeûßË 3¤©òÇ†[IĞş¬¹4ø#E°;6UvlŸwºZ#âM¡˜*cğšæ×øñÇúËfdíş/¸è¿°«“©7Af]«×µÄQFaoÔh€µ]—C”º2İ¦×8šó…¦›ÌÅ½?$ÜóóŠ€<BªÄË¶·Ò)¨Z¸ xxõ¸©i5Ç…ËWRÈš)³g© şÁP‘fÛÔ„Eë¡åğLÜÂ0Ä`0ö}¡s<ZêYc:#uaº¿Bc¾RÅkõfĞ[#»Â¹`ÉBú~˜b‚ß#gîáá•‘ }ö°28„Ùı)ÒÁCSŠBÇw^áıÖæ_nfZò9İx§#îOT«¼vuìå›æŒ'e½yÛjL“4Ú6ˆ`Ğ†Ä¨	7[Ê#e-Ë…Û×Ÿ;"w\ÄÂ’Ÿ!Y×İvÜØG(© Ãı<ĞîÎ°‘[™·4ƒ!¹æFÉ3S}¢ÈJ›ú?¹„vL 1üÈÒøøÜ«Ïñ/Û!Çé£ôËò¬»Õ1ê¬Êˆ3µQÆÄ ´¯qÌ$e˜`\ä®ÕYË!/)æwI9Pmqúi“É¢	~ë(Hwşzt-Ó±7Ò@°·Ô¢c¿ƒt Õl‘¶·Ä0ÙmF;ğC2Ò\Pëæú}=TÊâZòQØáF±‚|™ùÊèTZmCæõlÇ**Bg${l¦Âºx’Ç·ò¯¸¹vá%0q4ñs¨0Cnûé4»ò~A‹‘¿*Èó^½ÄÀ×ğ?°åıD¥…&ÔÚÍ¯œ³oÍöĞ¹şœÉ!‹ÿZÅT53Ğ•·ŠÉ€d	Î¦Uî/ZÆ])œ ‹ì/½üÅ¯c–„O „@Ù;jdõõ´~ Íó;|]væDjbƒzã%½·#QSvyşÇ{Îç€ô£”ú2™ËkÄßºßÊ„T> ‹<¨9IK†ı³i•}LAÌA]Æ“*Np™¦˜Ìe‹×åsã^ëTØ”Xì±²äÂ’Fï>AƒÆoI:v…2Í¹]=Šh4ûØL¯ÕIÍ	÷}Ìˆ²ˆg
 ‰/…ìÕIÁ0ØÔW§¿3×œå`"°¬E_ZuB“d(·¡Yş-§N«×8ŞßŒÍÃjŠ"Ã‹ôLoåÆ…òxJnüpà’Be²£eÑ­æ—ï=mJ»Ïßø·QqKŞª~šJ$hsÇÌu_šNmg<Ë  Löp ?DWA@—\b„ı&;Õ°½ì1ïDXÓê»á¬—×`>®pB„i:>CH¢×›IP»lI Şôd¶–­\[{æ…ÄPz¸ã©m©5#¥Ğ·=Q,
¥BNY°[±5bjYF]ò¿™¯;ã¦Zoiş< ëöf Ã`,Y^Z”şc"G¯m‡Şœw”ø&oOp™>ÔìÖ'!ÚeŞñ<¢úH•QŒ¢ÄÃ²w
~æ*‚Ì’ƒH„sjD—|»ã1Z@Òiö¥•|À¥Â ‘ª¬/³ëÓÛëÈ+®h‰ÎJxÜĞ’Hfäg˜‡ Bó&
y“»`uÙ´óÛæa°³‡zäC½lØX kæ]ØÂ@±º0CUª±›¿ñæíİK³)õì…ÆãMP±ÊšE×±9;µõúmbŸÓ~Óx ^ú¿¢Ú4w,ÌÌÚ1^¢ïÎàîİR•U½ğ×÷Œ…Ë;(/ß“ZB¦T^£zş"ÍK¨L§DØÕGã#[*/¿óİ8.š³÷ÂnÎ"W–Æ¾pĞˆĞ$½ÔĞPÀ:q7«¶(ÖÔV€<y7¦À#’„Ş/¬Ì›¸ë,ìFü¥4°s{ÙãÊP#’åpÊ³`>ì3U.=üôş¹êàÏˆé+TÇ—|S|.y-£Ùl^Ô•Š"Äİp¼Wzûy|B	W¶úrqbÀGÔÄ–g’^|r0´ZÂÖ>ø~ÛM’©ÂGM/F+´ñ$W”mmqø7Æ~¢˜½õ–»^Ä“¬,•¯À¥ğğ7ê¿àm(í¶k óª¥DˆãîZ!f4¤İË”@?"sJÅy¡"ÔŞÕ%½ß6V)i7#ôDÆÏ	«ükØö™òèò	—gP’7î!-VB–E-Å…}kjNepŠç%Ö­c,yÂn¹LBŒ«‘¹%X7°=¡¶ˆGİ]ÜƒŞênJ±Ä&Âœ„M§N‹(Ïî1Ó¾…3$Áöjòîê%“¥¹CÔØRú §´ôeIİp,véëéÂâÓlswÚ;vÅÁ3ëÇJ6±ÆÛ|çzòò'ğo-§€ÃÖáÿõ+qS0wbSwâ3ùD+÷ßÒ„‘6¤&‘p3åûö™íRw{q<ú²8+@Ÿ‡wYW1å4PO»™ÓáËDÌRlÎÕ>'7ÙAôÈ¤ëĞH«dÃ^×Ó;wäB¶lğƒ§àˆf¼¥5#kĞ¸¢|PÊT_;Õù0Ÿ~g»ßVè4éû‘yÛDíyY*¦Á/^ŠYlb^»´Â¹ ’ôhœjZB #9°ÉÔR+®$tÇ£`&9~öY	GİÉ]c… Ífı|É¥¤ôGCÛµ4„#xHè÷­ä)~Úéó›D{q3Ä®‚ÅFbÈÒ
¬`kÁÜ,Ù7BœA¹æõŸcKë †\€Û`½ëÑ™_trÇr©¥ËúéG«eø~Ä3È>‰ÓS¡¹ƒØºsı…[â·u\X/,‘MùÍåŞÕZC•šnKû…MiñouˆP¿¡†úK2Â%‚¡èjLï°ö€¼ÂÅ®o–|Jæ1Ì(oìÜëÓòÉû¯G°Î„cWMc25‰à96djÅMş¼‚ÉNğëõõÎ£+wx‰ÃefB=*5şH»ß`Ob›*	±­–¯”B‹RnI«!uŸÂ³eaºE_ÿGDáÊ•ˆ]™(Où%wPOäâ,õ¢N˜è7’İíˆlXÙÍs9ÎÒ2@%~M)r4i€n*é\ÙO#¼HüôÁ#¼½ÊÔˆ®‡¨Ÿıÿz-$/ùíÈ¨~© ŞNvu$©FÎ"V]Tf£’è—FËÒ¼n¾?‰O€Î™fœ€{ÛµÔùfËG,·T°ëiµ‡£kß+!ùÂÇ7›â9xvı'
å æ|£T_'kç¹P@³š~ºÛ_åD`·î„ŸF´§¦šx©$Òü/£±æOßşzC%(
¶ÒÌŞÚÖbúYÙ@
 ö™7Sì«ÀŠ*bUw à‚ó‹î¸°â¸jÿñT.â	a¾”•ÍğIPÀ«cLt­!¶/íÄPÀQ¬’İ§AbÛ¬Æ¨ºBû‚Õî1 ú5uÒå23ıJˆ®÷†Èò!3„nóœVçĞ¤ÆìzCƒQÔcfMaÔŠ*R„v×î™¹‡Ô?Ùf?ûœş^ZÂF}Ñ·>Uúœ÷nº{¶²ºÃÍKúÑc¿j ˜{o ™IE|·å’ğ93_`‰/‹œ•‹—mW¥¸ãlÅI×-Ìï®ò|E¹°Á'ejƒ¾`SY	HgïÎ³‘O’ZØbªÜiÎvf%å/Ùalp«¦(Ÿ¶ı™Â—ù^b¾ƒ1qã_Ã7ğõ«¨PøŠj‘d’À¼¯ i»¬èàSªì¬‘Áe73`ÌşeÄxŞ,%™şJ`õØá›×çKHšaÎùwm|WÀ‘vqÒf¤úKşc·7šòG˜/51µ§Ï¦í˜œ=ß<ì)-¥(Ô×j°Ë«[ƒç¢ëM<¸ ïSœwü Û~º‹K:_ÃóÍD;îe0xŸ®ğ5¾gnQ@È»A>4áœ˜¼ğ©ª<CÒÄ3„I!ûê†•Z`¶Qår8-–êaPÌåis³z¿1 †A'¾ ®kJ	¬…ŒëŸrÌş³Uµx´ï.¬ş¼ND½*?¹ÕÁ£œØshHæ%o9””:ÏÙÍŸÜ2²¦ş5cÖŒ€ÚÍÆ?UÖ×ùÇlŠ>uĞÍyƒÖd^Â>úA£øA[È’‡P‚š©‚U-° ÊIc9’foÁS£hMHçæøöW‡}-ìT”ì¸™Ø°‰mÓ}y½Tçº4\šVZÛS4Pg•ÍvW×¥ÒhÀ#ıÛòĞf’‡kŞQò‚Ë—e#B:ğßpqº±g8b/Õ‰ímeõr;ü¤Ç¶I^–:á[2«+^¹+Ã—ºCxˆ^õ$2
¸A?ÙGV
¦ñYÙä©uÌ]©İqCnJtœÈ×{ñƒ›œ|UUkƒ,U;x1¡SG”ËPI¤äöøU±N)áaµ.-á‘£µt¬{=µb1jEÆå Ce.”€ğçDUH©hH˜N«¶Ö­¹Î½~áÇz'³–ƒäÏ±¤‹a¢KŞ`ÈG‚OeÓêæ/S-!ùÆ+€b3±ö£ú»×ùjCÁŒQ¨Vy±zhv—•/œ(¾·Ìò­ªjD’cÇTWÃjèµÈFæó>®½”o:”bbvHÍÑÔB û¥«(‡5ğŠ£¡SÎ8–Gf†‚P¡›Ç­šôRç÷êÏ®|ï4æ5ÁuhÕ (Ï&*®ÔE/Š[Áí‘¨71û?(Rº¼Õ7 ¯;Òş„©ßM@–[,H…Á™çõ†õ{à4õé‚ÂW‚¢w†š°–ê¤c—Ö…®m.KF´PhÆ°	ÚsP¢ƒÚOJ¹eóc8­óÅl¿A¨ÇEdù
oËPaã=œ2-™¯gAµƒà9$1÷Õ3û<g¾J×ÛÊî#¿îëo4&íLÛŒ>B[wu›ú¤3ûÕv»Œ‘+UçÆe£_|‚iCÉ¤X)™²¿ş¯UÆÏµé¹¨ïƒŸJkC'heìî_^~[›7 Åcb/ŞûÃØÆ!2j0wö‡1M§eÕÔ«µÄ‘]´¯”©Á¯L™0gğÅ¯Nê‘2wˆÉİN:§./ÅkFm]2‡-‘¡Ï-C‹ >jÈ	A“î¸æüÎV&°•>S÷s¿ğ>
ğó®Fª¥jÉH/Éı˜±VLÿ¤G]`¯Û¹¾±ÃGA»
°	›$E_%T±¬µş„$W”+ÑŸ5TíÌ¼ÒÛ|å 1DpA¦U7PtˆÛxõ†Eû*›‘eÇÉ™t/o¢ş“0î)qˆı‡O/W€ÄœËŸ{ÀÍ´Ã«è»…@ °8­¢¼¹	Kó	“èŒÒğWİ=µ"2T^³$yáiØtúŸQ¹ÄN¨`³æ-<U£y¥İŠb.ÂS¢T½w£•-‡{kÎÜA'İÇ‹YÒ¤ ëä‡Ø’Ãñ«†·#ª=ş@SÜõr6yû+V9Nt@ƒ¡Î‰İ=*o¢6¯ˆºê
ß·lVYıãe¢~Şà{Ï,T P×º;OİQ€Úšù£‡ÉÃ†ùóT%$ld§Ùg—r¥Ànyıô¤Qi¾TY
©vfšJY•§ H˜"¦ÔôÉª¦ßî°9rjŞ¬'×	µct™¿ı‘xêT½˜»ö¦ÁÃ
ëƒÌu%Á¸ ¢z™Ï–¢§B‰2¥·P\ï,E³ê¬á
‡Vhá%T?ªÆKğ·d¹ôEÍçš}»p”1v¡Kä«°- ±—ôşb*¡OÜ“ô,·¹ñ‚´ÏI‰•e9±C_vÿp“/îÂGàÂ†Ÿzà®qÀ9ÍÈa¬n÷-•aœ"4óÇ€å®ØÜ×Me32	Rœ$¿ñ¿'ÕŸ´Z+eœ¾¿¾rä†j1AR6#ÿÄW4å=B!NÆ_ Çö5F/®¤çİZ´ºègŠ7¬¢ÒWâP|ô‚M^]_C`à$çî5K†±¶³¹	qò“L3¾ÌËvµëyÕÑmÍÙk¨^@‡M($T·mŒÊUûëÜJ¦czdır VrÎS7BÒã=ÅûHC9,Š±7äÏÅS@¿›Nâ—[Ÿ
?ªO¿8cä¼‹‡á‹¼à4s?PG7–Xéaf¶”w´ş7ƒ+ÍQ%eÚ‘3NĞ‘Êª²må¸=ß¡‘Ş=ù_™Zbfy>
Ü¯üèÑ‹ĞéÉ!m¤FZ”bİ¬ÙO”ÖŒrƒbß‡ ),@°*÷g{V5›¤H_U|~9±5›!KÉ’°İã'İñˆ@îYÑ¡ï5ïeºÀûş(PÆ»k¢±™äï"õB‡ØÁM±gº>ÔK¥d)søç<R{FÙş0#•¥¤¾_qÏ™3·€ŠúÒoSF É×•³Îa•8*R'2I(4$û8>„ëvqû¦CÏSñoíÒŸÈ*@“tª”æl´•VóÀê7˜‹İàğØsß‡Òy+o¼[÷ÖNE”œRûƒÄb¿+%¯Å~şVœ	O,ê%ÀxšJ±ÅşV&tÿØúº‹è!Ëõ1C-4iwÙ	ÒeEê{KUÑæ:-ZvcåT¨Cİ=Æ˜µrgƒ¨2¶eéTó&ìz(m'Öƒ‡‹ÎêBç=èc¾_bÎÀÚÕ§ã¥I!R4ùp‚êKe°§K½‚Å[ötó±8¼îµ§Aã¯I6Tµ¼ƒg=¤ Ğ“|£½ï_ÿ%Úä¸Íç¨ç£ ‰ÂĞß6ÃáŠÊ¤ÛˆÕßsog¨` Ñh””
ÁU¸²İ†¤î"Eö~‚Lhd56Või(>ÓgƒT¢ˆ7«ÆÄP­Ó«Ÿ4Ëº˜Zr]Ì«‚ZŸ±şí$ûh[6aÀ©yÁ;õ;Á–ô»e²cËïG¼UOŞ‰ß©§Ù…ñğeTiÕüŸŸ«6MgùVa‚jÏm×*‰
Å9KOUƒK1$å^F6_/liÊÕ¤Ÿ“Ì$0ÿOÛšÔ“,}´¯ıA“Ş»:è¿Ğ>àë½çˆ-a„×x=€ 	¨¨¯nK+ôcÇVÈı¢¶IQr´£Ë?|EıœÌ™Ëd$«Dörfås–è'w•…oş7Iç‘E7L‡¼™3heC1~OWsºŞ8cs_'Ãœ¼òÙşŒOx¸H—,ÁL+1¯™|à'×v;pÇ!"€‘Ñ—ûøÉGÔéÉi¥‰@BƒNÎ´~” Ÿ~¯<Áhxşl×w*¶*Úşkó{~Aü9İl²´„@©p£Çú3Ë$‚ô1í"X•Yz²ÎpÜ9(uì¶‘¹½¶ºOŠÈƒü/ndàŠ	ën×VÜœŞ]Ãñ“§-~mxò½O<â¥ÙŒÊ\¨;Y¾gé±ÚMßY•<çĞ¨dÈÖ¤^9Ã`ø[!(ÆÀ•¬«Tiô¥˜í/*µŠ­àcç;³@É$åÑ˜‹t=¢b–oıàr€j,/ÿ¸Ì?a³š‰Çäs×89…»`º£İœá³ŠÖSvõÅ´0ÊŒ9Ï–­7#´Ì>šõŸã=…ÄöĞ!ƒï×øQm?¢*’9ég×ã|9Z Gqú²úÚˆx°ÚÈgæ‘Ñ}/ ‹¬§ŒÖÖàÅõÑª}ë9y”õ.ºÖY¯ÊI%XL5ZèlÒ‹ıò
ï¡Q::ùüÖ >IPybõ.½WY“UÒÄoV(Æ½k­ı[X·õQBÏ"sM?1X8¶” ÷MÉÿGË-oRK%¯I’2ËC‚Âºì»®˜vhè¶pæ~ÒO³‰­£]Ô>`¶ÿı€%½øİkëÁxgCi#ÔÏ?`°šéŸášÆÓC|7lz˜ ªM¬NâÆßP	œG]K+òÛDè4×¸Ì(¤Iù”É‡RÂ<MÕv_¶'OİL‰‡ØIŒ•\d4`Ã¦á©÷ •ºè=qĞ¤ô I9WÁöùÍ¯í¬s•ß¹› ôğSÇGË×Ü¤Í?Ñåı¤	#ÿ×ÉÆ*;Ûß{(,ëéì‰«±œ²Ã›Ş¥Ôèo§,µh0ÿ § „°AÆÜ£"‘3Bñrª¥…îK™ï`¨u<Àe³Ê2Âeªewi<;c-lY’Ï“9ùõ›Ÿ‡V‡{~ß9éò‚8O´øeééFV³ç·şn|6òïW‚,Ìƒh> ^¨„ŸËáéàûE ¦…ãğß$øñ5__×œÕš•TÓuøø"±dí© ‘ÛŒÇGâ|ãjÑ,]¼[u|^p€+1ÉÕ»ağäkÀÂ)~§Ø®…7è’ÀfÅœ‡‚€·3ªŞÉÕ“+m‘{.Sò±“®}0]µ_¡Õn¿Ijˆ2VK—›ù¸ø
ĞöÄ¢&C²ÅƒÀ%
Fç€,j–ºwG0ğx—°ÚD‰ÜõüÏWçûXC³EW/šáºh“Åo–ŒÂT,DhøÀhaÒÂ]y>2@HäšÛ;[CHw„dŒ&¡~jµt9@ÄÔÃÒ—%eÕ›ìå»éğİw™1Şê¬©×Ãİ`kRS\à¶8VÓLûZ
Ä·÷ÆK¦ZPLÄ°ÑW•¡Ğ£EA…öÙSæUpÍnœŠì´U›İ´ş¯*¨‡ù)tì\/†ó©Ì5hÁ ÿr<!ıéD†ãÌñ74¨Ÿ-î‚=®Œú-…Õ³ëÿØÄ~7ŸLRyq†÷gATw.Î_:1YãNG<wº›¿C„OÏĞhhŸH[ÉûCËÆCì|…§ŒüûÅS‡øD†¯×ÓRtod>ª‰#A·¼EpPåâëx7”ÖWùÂMÍ­dr9"I#,Šl™¿S¡ÛJ‡İëÏ0ü/áÌ§_¶[x½	“&¼Ó¢ø´ªàŸÉÁ¸¦ …MĞYkcm4Ìã•29±kxÄ™JOö'aJÆŒ6‘ó›
|w{ı,ƒ4.Ğ´ğ±¡“i+
˜SgìôÔW£ÆiıGDü‹Í2ÄøR¾6fÁLß\yèÂ»FÚ¾²ÆÕïföÔ(ò¦A<ä”ö
&"%fË‡*Xù2 1\”²OttÔE}a{)}¨@ú¡ìæÃªÊb ZA"$…Ôx	ú7q5®÷
’¬:¤nR€O†³2haG¸Õ4ÏKêxÖmâ± »
™ÁòÑt:afèñL9gšÑJÀW?‡6`>^tùŞp òÂcl’ù§³®P½ä·İfİMm¸ËM â İ‘ã‘ø%•»—BÙñÔræD`N Tfá–VúgüZa¥qú{¬y)=ZUS/ûçœó<'ŸöåwÏ6¯-r¸Zz`m–÷Ö§q½¡{œü­Š@óã%Ÿô?ü=A fè‰:“>áy”ÃÊÌçÍ¿aú!º+Ö+r`‘bƒ(!P:Xÿ…Ó{¬›”Ñ-y&Æ3²«¬Î,%\iş"&c1*ÿ!œ‹	Õz¦~¡tf¤n ¦ŞS:·âOZÌGPï‹´ÏÁ©|·`ÒXˆuéPÓD¼|;ÖzâÛÏ¯_	—æ 9ºIÙô¬#5ÊêD¿æöÔ
îL`Èé›:3³B¬ª÷OP×Ut^$•fOÀ,£ÈwÎöE˜7BU„Úaˆ·Ó?›ÌãÚ§‡mÎ¼øf´âQ|M8ŒŒPAbùc7|:}zM0æK™N£¿œáN;©Ù±à%Ó¨TşA˜5·÷ƒ'Ê8×9R’@¬LÊ~6®Ğ‘ˆƒÇyj‹[FÇ¥¸\¢G9æğ^mø2–PHÅœ°˜YÇòíIäsù’åôrMgTÓ3÷€‰¼‰GÑ$Šjlñ/x>VÄ¼ñH“ó–g†YÓİ×øvÒT#Ya¿ÿğ§,¤Œ—ßàòXµÄP¨zíì’ÑŸèİ%ñ{YIeHÚÒ°½IQìªÇ|N4Qjï±`‚”»…q	–¤´æ§^D’ßš_|o&ÎÚ^õ-ÛÇ^º¡	¦Ïrµ:sã¸Ìİ’˜Çú\×ğC·~-·7^c»¢{	 bãŠ+>ÑÜExÃ¹Tn4#›aäj	QÆçW{–?¸ìË|¢XùlO®©åÃI\<îhí³=o(Ò£:æÑoLeówß¸À´dò½=İnP6^	³ª<õÒ2æoó·ÜhON¯®hòD€.l@àËBÚr8À= Ã¨ßIgLU_^ø˜
—¶kŸ9RümöÃ©ÙVWŠë»e³\È‡YIdM#v»	ı€§ÑÏaÔ(#}«(ÖĞ{P5K;n²a’x9eYŠ“|4§àa)JcÃq
ì<±ô9¸§on£Ã´yŸæ·áõròòp·İÃMu•<_:J¨†·ÂœGğ&”y$Æ±ÊÊå¾p0¹"óM¤š<_Š•Æú5å=ä4Õû¯R„ª?´±-¾ŞçÜ“<¥¤¸ÿ¢Z°lå¨C63ÿÊ.8ø³3xçÒÇ{_ÇÉ˜cSf¯|ré(cI˜Ønde:¨ùLY!mt©¾?2>¥İô8H<hYt!Áá>¥0r¼/€$ĞL¾iMİxïcİ6şÿè¹Ãè®55@iÍ|P…Å44)Ï‚
ÒÛ+›àw(o.0üÊ;BcTB-„Ëà±‰€1J­ì‘Îé|$í´´Úô½íƒïˆ¾³@šœ×?lÅ»USƒ¤ú5_ñn++¯Šûk’E³ë‚ÇHJûô¶E1#MU½G‹|wTŒÜ¿ıµÒa±98:E(HRÌö½Ûâ7%õx%%`Ö¤ùUÕB€H-2µx*8må´ÚBà±Ò•Ğì!æTMFOK®)¢Şé3„óˆ­"ğÏ=¤àgŒ}@“Ñ«G²È­àïYCÚ¼Ğ‡ŞGÉùCÇ½íîù`Nw.¼ØQMhÁ‰ú°À/"lŸ^hü±¶ŒÃá˜ËÒÉ»T?ôª²F¿=+;cæïÿå6™}UªğÌ^4,ğ]â­ôÓTò„‹:s½{ |%6'Æ\Ÿ¥u©
GkÏ¡±é©¶™»–dã_È{³Â:¹âiğ®¹õèfß$·#ï\9ç©á„f^<ïÇ*£—³E¬v&Ñ¡i2÷„˜¢½°ô}g±‚½•úå}IÕı½^½²š‡–""%Í8”¬Øë 2lü±#àwjëelKú`”•‰i$à{»›£tİº
İ²lKê–—ŸŒÔßNa´é¦ïØ´šøqÉIë0 8‘¢¿0Vw¨²ã‚œ¥*œ¢MÅÈ7k¥¬ïV]ò*™d-òÌµÄ(İ³!~·Ö=îQµJIb¹m:e±¨sWğ\Q«öK{`f(¶“ÁbÁ;W¨Ç^¤Ö `€j:·Áˆµì½ù5Oÿ·bm¹1"¬ÍÉ WV|èâ'±;ÃHXËÏD°Pí›P4N.87ƒ9;©C44-"#Qr@“ÅÌÁãl—@	ã‚e5 ı´ˆ#cÏô€Ã>+q>³Ü.Işmº©§)ÖšÄAB´ÈŒå^{Ç(ãßDŒzN³­°IH^3s?IûÄ×‚T†‚ßd«…L§˜9iz„M)Âl‘TÖÿÀ §}^Sí,{¬$;ücš—û?fNéÍ‚=,kè	í7Jı¤¯|O…Q
Ö¢u=ÖKÌ    Pş½¼Ã®Gš êµ€ğ0Sû±Ägû    YZ