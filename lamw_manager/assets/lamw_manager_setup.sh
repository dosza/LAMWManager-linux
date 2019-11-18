#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1209590168"
MD5="82a8b783b78b620af23e5b87c6856dce"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19637"
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
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Mon Nov 18 14:07:30 -03 2019
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
	echo OLDUSIZE=128
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
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
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
‹ ÒÏÒ]ì<ÛvÛ8’y¿M©OâtS”Ûé¶‡=«èâ¨c[ZINÒ“äèP"$1¦HAú÷_öìÃ|À¼ík~l« ^@‰²t'³³=X"P(
uèªşà‹jğyº»‹ßõ§»5ù;ù<¨?ÙİÛÙİyút{ûA­^Û~²÷€ì>ø
Ÿˆ…f@ÈËtİ«[àîêÿıTuÇ\^Œ—¦kÎiğOÙÿ';»+û¿½·½ó€Ô¾íÿÿ”¿Ó'¶«OL¶PÊÚ—ş”•ò©kŸÓ€Ù–iQ2£L‡ÀÏc3ôÈaà1æ‘Ggib¶”rÓ‹F÷ÉpjSwJIÓ[út)å—ˆÈs÷I­ú¤úD)·`Ä>©×ôú®¾]«ÿ-”MÛj´ D•¥]%6#¾„Ä›‘z§^@ñ÷QãøLÏªd´ 0˜ä"0}ŸdæDÅ1\‡4ÛQrªl¡~N*ôÒ÷€öVûÙé¡QKƒÃ¡¡V«I.f||8wO†£ÆÑ‘±F² y¼Ù´5m?¶Çıí×íf6WûdÔŒG½qûuw”57a–ñ³Æğ¹¡¢\¥(j4ŒN‡ ¬”)PotzÁÕ*ßa›ªØ3ò†h°o•ş«–^Y]‹JŞàÎ¹J©˜|ó;Œn€¨Ô6u\ç¿ÏÙÉÇ7D™ÙÊfWrƒWH5ó
 ßš©·\z®Æ”o‚bì¾aèN`[”)Ğ4¢K¿c;”=Úº&J)á•.}=]zîx…¬"Ár3È¬ê&l.èôŒ Æ
ìû@ˆ=‹,,ér›£p€SFƒ.B;P ”¦fHtNõyàE>ù™ÔÃâßÛ/D·è¹îFS]ù3ùÎ µd7a1¥u±«+%AŸ»ã˜sÆ§uéE?H@gã4óë*€ÂÏíZFevxºğ@†P7Ô„µ’€¨Å”NSÏÚ¸ÎU®ñK×S´ú)øXLBÏ2‡Œx°Ã˜1~ƒÕÊ›®,ã;ï ˆ
™Ï@S”9Ÿ:5[|Ù‚Lgz¦	¥u5¬¤¿‰v©¦³"7¯s@ß®G™‘n) ÒÈv˜wj6‘ğ©JYyœ*•¬ó•?oœµï96hÃ;3Âó™ò9ı3zI§„ºç¤Õö¿•øyİ8=ïº#hË~“Ï§Op•Tr–m•½\˜ü€2T#‚İ%ôÒIµZUjZ)‡_%®"r§è„tuı¸b¾ÒXJQG¸HnPR¥”IB"™š¬+qS,››ÂRº­¼1&viÚnJ©‚Oœ¬.C=x^¸â>•R¦‰±Àª±@çû$êÔD™óy~«ü1ƒÉìŒ‚”®ÈJI6° N>,‡oEEÚXòàÛgsü^8´İ9BR«^†_ şßÛÙÙ˜ÿmo?]‰ÿŸ<}ZûÿÏsïmRÄhÎ&í+¥:éùàùx€6çš¬üŠRy$ùĞ¹aÃØÅt-_Ê§–b@ä[£ü«ã¼ú›b~5ı¯¢„ã/Èı;òÿú6$ûyıß©×¿éÿÿÍü¿\&£çİ!étÚ¾!jë7F]ŒØ~#ÍŞI§{x:h·Èä*%ÁH/"KóŠÛ¼ˆ…æØ<
®~$x6]È$!ö	ÈÒ³ì™9	3Œ›Pâx,¬æËëù½oLDu²RŒ!üj¹JYGøDÓÄh‹:öÒÆ°QÀdrçº4Ï(£ÎŒ˜Á<Bâ™Ş( º¦#cÓÙ>Y„¡Ïöu=Vµ=ıë”¬~ g5oµ·ä3D¬Y~é›.ãíÂL˜Àxef6g:x¦C3UòV#8û÷¦Ïë,š’·úq`÷Í*MûÏKÿËêÿõúŞ·úÿ×Üÿ)^µId;ªlñãÿ:ôÕWıÿ“Zı›ÿÿVÿÿìú}SıUĞïy¦šú¢ßvp ÿÈœº4àa	 D±]ğ‹xTĞŸ?%:i4Íç{;i¸VàÙÖWrìJÙ¢!†&Ä(¸ÿË#–Gfş4NãLË$®GúM‚õFËrçÿ3°Ís›òb¥¹œØXğRx€Ôé7±î\RJ–ÍÂñÖnT¥5`›±ˆV]naa˜a	?…¦ó’êcõt¹aDê?UÕÇ ˜Ö.±ğ9véÅ8â c'd¼àzpÀ‡ÙntI!z"õŸï?’2sª¤äÔ32TkÕZÏéàhK4Ô$cçnuPˆé ~qª^0Ç&ø§‡æœéu( ?×Æ5UÂXÆGİgã~côÜPõˆºcOp ‡*K`ÍÎa†<“VÎæ«(í£vcØ6Ô['~Ù»½#^â½ÈÒ+ÒH5ã:¢Øù¹´s¯%íÜº$èÅîôì#YÆåO{cĞ1E›»ÑÚºÒÒ~™‹H$"[à:a¥Sˆ?®ç¦@¨†úÚ¢3Ék×Ä›öÜ?şt	cÿ=çÉB@¢%‚Ï³—“ÿpì©Çç.<³Ñ‚Ü0Ş3³ùq\¢±Û¿>øÓå ©ğ{{Å>cªxmü¯¤»¦ã¨.í×m0;{º@n/Ï@U4ÛV\#W+¹A*1ˆª®Ÿšc^å¨¶i*QJWÊ</M«şÜßp±‚¬”–HYä™²‡ç<xĞ®Ñ§'/HjnG8
Kò96p Y)¶«5m\MÁÆëp•ëµ¶ïßjor¨ã“ì/İ~|°¹sÔ=9}=~Ş;nóMdbHX`'%ÌÃ—'£Æá7d3ŞTe¾VAwªójÁêR¡)œ>•¡ëõ…Ş`ÃˆXñA@D”ÅqLëÖšò$gF¼²¾$4¶æñ>áeÍ£ š‹È‹ ¡˜ğ By†MMŒFÁRœÅ.LwN³Óõµ…Šİ"’%VJX S°Æè)ÅNƒE_ş#© “fÿt<‚ô½=2L°V½şÈP5q‰í#•ô†i¿ˆ{HsĞ`Ó¨—ODkÎ^vú/Ÿ¨$¾ş İé¾6pgJ‚e¾Ü˜\)”IÜ’ªH)»9 ‰cïtĞlJš¿ÊCôÊª`£¡’„|ø`û	KÔ~_ÈJº÷¾?½Üãş¬èÔ›Xqx‚L{Ş»é˜€‹´ƒÀöIĞ2iÿ5Y}*×'½ÁqãèF%ÂaÚ)±]_bà«éáf¥PûUĞÁi.Ïg¡JébG:õT‹ ‰‚eÑmÓÅŞN¡øŞÇîì´9÷[“Ï_ ¨ya~ŞYÎ"ênÛÿ—î±ı« I#ô˜£™(™ ÜÉŒ/­ÂŸÊ¥ò§m’|ÇÖá"r$'{.h>ß¹Íñÿ¶‰Ü'›ˆ
²q›0s˜†Ï</†éseKn¥2¼%`Ï£ !•¸½)µI÷G:GÃq§‡6®qÒôº­q,G+	dœÂæ&Ñ`n¶Dõ%jPÃß”P“XpŞş9ää><¯™’Ò—s$¦°,ßÈHˆ•ØÕÏR\¥4¤(&}szfÎ)áñ³íZô’ßI¢3R¹ö‚½©ğ¾w7Ÿ¼¦\œ—pòëÔÿø5&n0Z6Xİ?¬x{ıo·¶SÛ^©ÿíîÕv¿ÕÿşÿÖÿ–XúÓLgişõ?’^ Öâó¦‰¿g=p@™ï¹Ì8”×ö8B<èË]lÓÅcb ãâ^WªV¿Òa×­g¡wjÑsnÍñÛgäáğôÙğ·á¨}ljÄ&ê¤1®më%u-/¸æ?½lŸ´zƒ_ ï¸×jjmoo½SH}'š^õ­û¿'£T”ÿ"¼OD¸TKß­k±?®ò&¤Ñà¯ü! 	xá${7]uSe¾‹)fğ×È>÷PZR–~ü»\i)4Õ’­¾ÍX—…¹ş“†ŠœÇÉñy¾†@4‹€æPßÆæRˆæå¢2Ş†/ş‹Å±WÜËue[Ô£0’÷§cHÇ,ŒGHZîvZí‰İŠ*·Ad±„hJc³ä1ĞÄÓk+ùNo×8âı¢æÄÖâîSôz£1Ê´îZgºï˜!ÿ’é1´V¶Ò¤XÇĞ cÂ˜Íü¶œ*óxCÜØZÁzI zz1Q;ÕŸu? „ºèÙPœ¾—JµN”ßøs.L†¹vÈxŞœ†?y„şø3Æ¡óPì¨U·£®üŞR”¬¶¶"„$0Itï›ÚIªÄXQ@TŒKÿ‘íRÛÅk‘+80*•„èMí0ù]éqÜz’VT+rºõ¬àI¦&˜j¡• ”°Ux~€ÚÊLß›™Z¢ŒÙ€¸Êµ,Ç“Ç„2•¨]*!ié/®§5,D«zÆB¯xhDÅí`ñ;>~àW}ñş¬ˆÕ«èÖ‚©¸>N@Q[™QËÆ‚ôˆVãaR“áµ&ü»_94ZGmDë!p§ë‚õ
Á“ı5¢ÏÓ=C'7¥éã	ÔûÃ õ Ce}WÕŠ¼lUzN—¢.šï­´³¹^qá¬&2É÷8tE:Šü¤’_~!d#ïóh$n2k9’;píL-5?ãê~ßŠ†›ñ$9c–ÑT»2!OŸÚàyYØÍr Ø1ñôu.wâ9ö‰ŒPpë&ŒbÜSÆ'u"ş à ooó#
ou1J¹Eyo&ı‹ÌÀöˆ*8ŸsoêE$Š<š >†©ç–"J5½—ÇAÜÂoócÏu®âKŸbH¤¯\x§¢*ˆÂ0ŒJN_ğäoÕ£¯d¥>Ù–-$OÎÇ";Gf¢A‘İ5`½p¥ïg?‰6(/Œ<K¶™ù!öAKÏ‚HæÂş`–œüß9å]È’Š]nãnKHüÏ½×&. á/Áé/Å?;jóy²$ù°ÎuV§3¯‘$’–XèéîÉÍÕ˜ª€më¶øÜ4üÎi„a¸¯n6O·Ï’T·î9M~Wò8î˜ëSµIÏSQ¤-œåËhîf¶µ Ó¸ÿEÃãDé"°C¼Q:ç¶1½¯ğv{äÍ»¢‘[DŒpâÀĞóƒO®­!ÊF)±Wâ¨KÓõP\L^!-Ü§ÇZE­ü,Aíº3oM€*Œ
FÛû«&í'^pÆ ½¢1G_õ/†ıF³ÁÅåNAì,™u&fLúOòıàLßº‡Q:4ç79ÎŞQ+eà5*+bâ“Q¶béwÆÓşü3ÁgÔë3¨µ&xÒ’N¥Ş)_c¨HÛóPØiicdÃCÈxxÚï÷#ã!RÅNryÔĞ!ïWá×V’xœôFİÎoã!d#¹³o×íÙ•Æ xßRJ¯Pºƒ4Š_õ2¹×ŠAúÔø±XÕô0~e6³‹Üyü*d/\ßº·¡èÌ$ì“"|ënÀ¬ïÂsö÷ïæDêkãòËïYNÎ*‰;Ô)Ğ?cqo]şV)¤ó<|…tdËÂ’Æ’ºÁ4›C¿lvmYíÿ»BO'ùİô}'½ĞŸ&*å)?Á›÷ò»ä| !Ì3Òüˆ/Ö‚4còÌB††fyƒˆæßbqsOŠ—ö’ê¾(F1I¶ï7mn´˜76ëeg¡çóô/³ïoZ¢™´ñ}ˆw"VOÌ%5²ÍPSO`OW»Qn_Òiîà´O„fš²»4ƒ+M$÷Ïš±°ãª4„Õy©—±ã¤u§èËòp0¬[·¡‹ñ`9ˆØØ0Û¨B#7¢ÁÒvMÇ˜™ [¢éÊ§F#Û±˜M‘9gPêx>^Å:€ÙÖ!¤áBq8zqpxÚ^Ûsàâp¸¦ÈuÜtLÆVÙ}ÉÉ
ée¨_jârÜŠŒõŞƒôjâÿ÷Ù.–ÛY9 lÎ·´‘¦ÂF¬±å{¦EaRÇ¼«|A¯ÀÊXÌåòƒ¾Xr¨P?‚?;Ü9È3éM?ğ|„Wûû¯µ­¶vK9§íËòWIŞeû÷ïÃÓŞğÒt"jTiüñµ&.jøâ*P«µ<|ó×Htâ_À™ ,:µw5>nŸœ»£öqR{*Ô),Â, 3#?\’¢qĞívÀ4h‹ÇoI¬ü4¤€€txSÛ¥¯ú,¨ãWç.Œá—&MäZgW,¤K?hóÈ¶(jÏÄ¶AU°K$mK-b4¨.Â¥SE“Ò–©“°Öéæ"†êåÒù$§ò|vøebõ›{ H‡ÆÉF‚åMf¿Á¸Ÿáås2‹ÄInêº']~Ì’…~9G”¹€QVÕyÔ>Àâv%SÚ¾ÇBq^Îİ“çXã¼‹5Ô»İ°ºæ%Öó²â6¤5<O³šurdÏr^P{²<Ì:‰©Ó*@¦”Ş›çfÌ2ãQvÇóıùRÇN­rİë·O~…€¸Õî4NF7÷½u¦™KÂTòiƒì'?í©[ñÌÜ©ÀùĞ\•ërœ7ÿöî†”¡ônJ'”xLwÁÏÎ)X4ğ¦
4<;H‹rRûuòó{~=œ°xûè±±†z _BÔÀ:û‡ÈÖ)“#óãß=QaÈÿ	H@²Yy‰<İáë<İ6Ğ-å­ÙJ `zpvçª–çR~s¿¶@—äs4Q¥ã;l»v(E'ô¢/‘0ÔXy¯RØ˜ì	À_Tüwè(3î¬ƒ%gJãø‘AØZ±?áR±‚ûWLùRŞHqÄ{‚ı¹€wf˜‡a+0á3ğ3•dû¥.8k)i_PY½áoCC>¤a¸­˜®s;¼ÂC¤†‘ãÄlæáYš¶ÂÊihlÇ9tŸsr@ğUÜ<9¿îÇ'tF-Á/Ãƒ_9‰æIªjìJ«"«×ı;w
¯çƒvšÑ%—¤‡?¹Ú‘U×JçâÙ”VâÉTbJwğĞMİpá¶²ÒÀ9Q‰§¿3&oñ}ÚMñÈ*´UP>0…9=T‹Ã™5QX£J®„Ü wE6	m‘1îOÔä2õ:a’5¯.Ü½”È²šœRZÏ/1Là:FA©.¯Ä1:‡95¸ÖşñJf}E nı‡^eÑ$9ÚÅûğSv(ªFåQhÚÑêÅğ[D|Ê	ÔÒÃsZ>ş·‚<á S¾îÆr¡L%éy0xÀÌßuÿŸö¾­«$Kw^É_N1øXøÒ`¹¹Š.lX´«ÛÔÒJ¤gY·É”ÀT•Ïß™uÎK÷:óZõÇÎ¾DDFdFJ‚ÂLõªUFŠ{ì¸íØ±÷·ñe8[ÒoÿG\?E½Á"ëƒ N+ËÁÉJAJA/êB@ ¦º`ÕÀh•~ Uzò,#‘Åe4ù €Ê~ªÒŒln™bË Ç°èZß£p§õB;zánŒ³ \ÅPÀAëh¡üçÑDqåòytôI«§Ü^Ù˜ãÖ¾(QEÀ/{Ğ>Ú¢ZXmÂU¦½^1ü`Èr ¿š#fªöüÂ>¹r¦TÙ™•ÕÕry:DÓ‹*sÒZ]·W	„Ê\0IåÚ(¡a ç-én¬TOŞcÕ'?T{+¹DórbCœ9µ¤ş¾¥HĞW¬V'9ëfô==[ıÂTJ&äx`ìh–U”LÉkæZJAÀà#^ÎHÑ%ÿ²ã°ıšŸßàígÖÍ
*7¬8—™wa¢¦+¦ûnİ¨Çd?cL|áÆ»¤¨N„½N›î Ç_ú	şí÷bFåÀ<‚<¥ñ÷EÒU&½3şŞ‹ÎÎÒ_Ó±ü÷Íz4ìâWØùQã¤WgAiŸĞ?•`˜°.
ÿûcÊß(ÖéÂ•t’ùY‰“9•Õå743¾¦itq°4“‰ñU'é¸êñG.!îÊ–q‚óqÜye<á8òGœv.ºI@ßCÕíØGõwŒe‘`8á>ş˜Œ†2a|ûÆWYéàcğd3"ÊÀW¸ñWøôzô¸Z…²ê0!å·‰‰¡o*r:Ñ_dñã~ˆüv¾Ë:~÷Â1ıö¦ùf	E¨ü„€Û;wŒBş£Š½
ºØÅx@“gJœàîp‘~“I'cƒb@Rdhj!yq>_e–”ğ—áiÔëÑ2ØíÕÕ¨±¾=‡¨5Çß?üáó6Ü×Ö¶ëDI!5°¾±TXI+ÍI5-½3)oF¦¡°-è<¦û¹÷dÖ¡ZÉ•ŠÉåĞb?+L©ÔÑ—</UMbnJE.E¡‡x?sgóšÚA”u^Î•ê u;9±5qğ¼(|½/T	uSáÔToTß9]
Ë›•Ú	í~PãwG+-|¡ÖËò—®SÁÂ£0»PSijV!Ÿ³&¶®iÔï)Ö‹Ò;HÙ…T˜cŠX
ãr•ŞX¤‘‘C‰7^k	.˜)#\$W¿ç›w•ëê÷Œº²•³ ÀÎÔØriÉ§Ò,‰£â™0‘EŒ|A*ÍŞØuÅ|ÇšS¦¢Ë‚R$ç‹üéN—‘ÒÖ©½Ü·-‚d—!Sƒ+}bªo
bàÜée¿k:§#ÖlÏT87½£svr$¾¡æZP¨Mñ…ÖÂÊË*lQ¾Sï­$·(f`’	}¥Q÷TëUùŠ|<4ñ8åÛûŞnS*ğ•„­}•>çC‰§M.Ì|Œ´›?K‰KaV8mg
24
…}»Jc¸	öÜq>¿Ycá~¹³k—g	5£ò&»IÙ}ò¯}ÕtÈ+ê03EËd×´øC]ş‘ÏA”ü7ÀÛx´_Ó	!éº’<ªÅ)³;-*OçÊº ;‡ÌPßÏ,wØ!¼8¹v’Ef|)ps~XĞ5iAbbÇef"ªÖØHaıÙhy!!„{~¤mï~G07ˆûN 7‰Ç1Ñ–áûLü	‰qÀz›!^òt:ì±DömGgÚi½Ño¤¨—Kr¤3ó93
´Îİ›”ŒÛ"¥«v³¶Ï=RoÜî¹\Ím³ó_ì©	´lŠ·Å :Àå¥|Rlæ¾vÈ|E¸ç®£…ìîüDãäÉfØ·K¡ş+šânÈçY†¸jš´›GG{o¿i§ô¼@ÂMÌW0BÍ Ì°Hu79[TÓ	‘ªe‡ÃIÃ}åR­Û¹œ¿¼¹ûIõ¤ºœGdªVÏQPVê'ù¬Ûî	pcZz-{Ù¬¹¬ÃZ6o,kÛÊZ¦²ÊRv¶¡ìíØÉfÍdá÷TŠº|®ú+óŒZo–“[o˜W¹z_È°WÛËfĞPs7GÊ%Ûø#m™=V³:ílÏüNÿóM Ï2mN¿®ß€°q¾™‰³ÃÂùÖœ·o¦µ¡Ÿ'á#Y_“ï•<rVÛ\°²úÈ0KÎ™ÅÌéB9l6ïu0‹ºHÃwİ~Ì–XşŞÌ)İnûÏù3ò³%ÊtÈ-oš³Â<QHNÅ÷¤kªV¹KJ#Šç£æ[‹Š0P,˜Š(¿#Q 3$fyğVy™îB§#Ò™KuÏ¢Û®Ïy´©r±bX	«J°&ŞdPÁ5…äf}Qğ~¶°+²^öM_Í·iÌ€\*Ù†é*Ï=~˜ºl.ˆL'|dZ$\Í!¼µÓúkZ°:Î¶–ÓØ²¹Faı@®õ’ˆÕå‡k+™rğåK7*fe†Ä˜õjjR‹dIµ1(‹m]ŸÏ—Òoå,B ‡¥şa½Ùª¾¥Ïµ”¨7âK
?úghE$Û€§&ò‡şšú½ä¢¦Ğ	HcWıÚŞVQI¼Í+MRÚ]}C ]Ù‘aH_–UÂèË¿ığyÅ©ªX°şäÑf­2Ót¢8#n¨Ú“ğ’…ÕÆ‹›²÷	‡&¿òük”f*ëW¿VY÷á"Ğõ`GiøÇG¯ËÏü¯_¬`J^€ô}éysxÅ£!ZğT‚p?ßçšR¬I¶79ñ«(­îWUª¿*­ù¾ğ¹(ùH4ƒPU´Eé¼Ï«bÌóªì1N9²ÈĞ©F¦%¸DàjıÏ‹ØaÏ4K°gŒ´«ud^“ËÔgG2îCA=5Z^UvÊm|Oà0fÜ×	Rz€¯aoYŸÉÂ=Y^…‘øK¯ùKk‚ÊY*Õf`©/ùªfÈW/ÌW€K‹Àº€â
ÎjBZÀæu[àÀfö±°Òc²&¾Õíœ#©§®Nól'©œğì^1 n3H·Jõ#©¯šŸÉœ<,—oRbT¡rOJ»@”6YËå7»Ø»pòÇó[Áè¼¿›ä4I¿åë Êo|Ê#—zïÿ)ïrú.ıÖş?7kõ{ÿ?÷øŸóğ?/RüÏõJÍÄÿ|\u Znş†ˆ5Éb{>{ìp(ÂOÒ9ÜŒâ öru—Ù~È.ü´{^>(Š¦$«¹#ŒO/ù ü@3òÊ×ëı®(‰GûGo¬ôÂnx!Q†‹
ÇôÂ>ÅF?\:JİÑ%C²ÌVŞ\IğdÜE²¡%·×a÷‘ÀÛ» Pj4¤ ÄC^Ä=•PïÛŒÅ°  X¨§'Ø§»ö?ÂbØôk'¾èÂÄ€uxà‹¯×søv…	‘ ®ÒõıáÙø‘@nñP *`Ş-×°Û$cD»8¨3Ø6F›ÊyÃÉ4Â©+ñ&ÎFÓaOŒbQD?½\;#=ËG‹8~•·o›+šÙ$ó—ëù²Hp<Ø'f'Ç=Œ1Í	—#ßö×¢Ü«Û¤á‘…ŒÕñ¹$ûJ‚TòwO?/ğTF‚—‚ø<LJ «úM”$O™!;Pÿˆ°%š[6-a‰Ájo¬.¯¶ñlGîvhYûÙ\[óÅ
Éh,ˆ6ÀX(}ƒä«k®	øÕW"ºaTÏ=İÚÆrİÓB ªœI-ùU&´®tùgøZ­T«âóšéäA¦À+7±Eäfi‰ı+-•˜{“olØcÉ¾Ê?í”ÿ¶^şÓök6f£ /Lãp~Akp:@°Íl«Ò¨Ö·PkU;É‹ùr÷i‚×V²iîï5w;;­ÖÎ_±T92”*œìæÀÖ,£’Y.ã©éL•´Ò:Ğ„*¬2ô©°9l;ÍË¹Éx(3.èCÇÁNR5¹8ÖÈiÑB§äÎÏé”A›åô;w#-Él9#uúÆPÊ,,j)NÜËĞ#GĞƒÿ•ê•0)}àĞuî8HpÓ?½BØŠ<»B©´(:‚óĞ¬1EwÜHGOš<b]åÚ¶ş­W0¬¨4”+\÷å*{4•Ë€¬e¿©’:®=BGÊHd-ˆ—À¶•rÄ;O
™FÈL¢özàúh~dÒÕ<N#$ ÍäØ˜8ˆ~’Â>=gòEçÔØ!á8AOù›Æ}I`cÃÀíGª—ŠgŒÇ›ºi…%«QÛœ$?WÀ[-å˜T8ªç+—‰Œ;Œïê_O}¹­`$4}òAÙÛÃØ¬L¹\¶åÖ”LıQ:2¼Q÷]Ùæ Ä¯‘8-H)âLrG…S+]Ô¥ª>]	cşg¤²™Œf]»Ş´LßIßÈh½l¡ia‘~îÈ)^èzsMmµYVT%rq¤Ös¯ùN|[0Úx3\s¾ın"8±¯uC0Ù´Œå=Åÿ¡,í©E×3¬7h•±Z£ÑD‡İG|ÆQ0ˆÖˆ[Bm]_¢ÛŠ\RájMÎ#ué%Œg¼M'Ô7û#Æ…6 	¥“"y³º¤;"yôÈKQ<’q?œ‹R:.`ÈÏÃädØ„ë¬ïJ¥‚SèÅWu şKw&Ú…zò>>"¿@tr'“^ˆuÚş‡åî^ş'Gnß÷÷"şêO62ò¿Çõ{ÿ?÷ş¿o×ÿ·4}—³|AG?¯”¯oË•·,H;üé¥øÂxv½#ù_i"”ìMÇhµ’„†’¹¶vàÇ@%÷²Vj¸!S,ÌA/1q×‘–ßa}Ï³Nó\-¶ü/cİ†Tı/÷
Ÿíª\e‘å˜4•³9"­Œ+¯ìàí¹H~E"ä±õv$ÑØ²İLË±…nFëÍ$Üv“Á_ÊOÜŸCµépßĞ,Â‘e«UVÎ‚Ÿ3ë±ê£öçR8JÉÂmå
qàqIwIgÑ§„{ü’w1¥Ø*±@õ K•®¤7½¯ó7½´‡.ßª¶€US¼À«åşšMÜˆ<'íI0™&äM6qéÚ¾.L•4üÿ·Iø«EÄç‹4Ci½–F½=è|s¼ÇË@Æ(	É¶âg-]ÜzòĞU†Ô%FDDÆ5€{ãOp›öö·ÿøíÿÁ¤MF§1òŞxIí§ã wP×õA»“ÆªX^í?‹r_,×Ö„Ô{2:vÆò9	†P¦œFãIFCÃş£ÍAfÔ¢w ),R×[ Xğ•»2º5ìMØÓˆ†ßêÔouË[²çUaÊõYŠâ•‰â©¨_ 2 #JôO‰q`_}»ñ~:ÆÉ@CKÏAuCN‡”É‡Ñ%‘L­/}”oTÖ+ë+–dOxªjÎ5›»ãC´ÒmâîÓ¨¥ˆ£Ob7<‚!²pñşóîwB¶Opƒeè³[-òè³2ü«;À{êV»’—sz‹U7¯wA[õù–á7V5÷]£n^Ø{$¦	íæ]«eÜÅòµñRË*`ÿ¨­¨Ã4ÇÌ4({´/’Î=ô¸Ê ÒI¥WøTòJª="kçæÖ˜ rLkã¼ª˜³‚JÅë)PêfkÃ®ª%ÈÁ9¯Ú&0_6e¡nylÑÉ0ZÃ	¡Ó2?úÑäê8Š¯Â˜Æxè‡ÆÌÍ½%
kãÛ…i1Ì]8ŸD¿¨^ŒÏ€™0<yyZa’"Ú´¢nãPÆ5|HËê<T.O¦Ãˆw;ÄYµg¥§â‹õx¨ÃÙ
]A	\./p6½@ˆ$ˆDœ\ıöÁHMœÌ¼…oÎ\ËøšwÓ¢™­9PN?%ˆğN’dTŞõ¾-AÊåñ4>õ²ıSù!lãb”µÚCÚğåN“„“?·šÏ‰LÎ‚iâaãYìrÈÑ5œ:8BøvÁgĞ¾¹kÅ!
ô
"&3_œâÓ‘$Ë!ädf,±«.#:GTŠeævå«èe„Ï¡ôšéCu¾|ÓÔŒÚeD·NšE_TRÛ!µnK@%&?¶'£ñ·=ùæÎb&ù\vÒÊGLŞÿ¼ó—Ö‹÷—ÓdºvY€„ Ok¬úÀx#Ì!5qY—b<‰olšñ"JÇ#,ÅôÂqâÉ»!J~ñËæö¶´­oht9Ûßy÷fSreÙ›YÑÜÌ‘èÔÁx+;‡œÁK™£[¯¨ìÙšõÛ–9BŒ]YûhGT˜Ü"p••âıÑey:„–ADy{ŞRáiy¥C\îåA„~äÏïâ0XÊr¥ºø/×ÇeôgĞQøèëñ¼ƒ…IÊ‹8 Òq‡™EcÉX~ÍŒòºyAY¼sêŸ5ÙQ(„ŒAFñMU—˜#ı‰+‚ƒp†QÎÁŞqÚá$%d¡pÈ?EÍ¼×lX¯–öB2tÕ~’‘Óq»Ù!¼XÖ³Q–+*.¿ñè˜îßÅ³Y[û9[ßZfç¾j7Í{2´KãT£(sÿt3Kbßì¼İù¦Ùê¼z³ÛbkçMóîÒ)±6¢İÖF´Æe±s´Óú¦yä+-!Z$ì—Ó9`[ç|y¼·/Møì8#7ñ@( ü4‰İíAø×Q‚VgW2…U™Äùy³÷Ö¬ZU.GòÕAÀß0ªü%8:y`c+:[,¤Ò}1Eë’¤³¹ËóéH¤*ŸFçıPşé@©Wé¨[ÊÉT{,‚æ‹™ÄÃI§¥éíÅ$ìn£r’–é]ñÀÍ¡¯\‚«™!&Üá¢q.ÏçòÌqŞß{Õ|Ûn¶­eSŠ‰@l‡{¢Í˜dÅl-½b!¼5Rœj;:ÉÇ—–ğt%	úo´	\g C“ë÷k÷‹®İÙ‹ÆX3kê~úM81Ü(.Õ&#|vgt’sÎ3^nòoE¸¢Ÿ.rxø\¾Ë©“Œç’Fo5÷›;ífµB
b´xfE£æ¡»‚bî¹ œÛà±€²¨Bà¤u¥9ZÎînšˆ6²ªjA{ÖğÍÏÒÏ·KôgÑqf©·Â±Ú(?äm–ŒÿñİãÜå	ÿ£3³ıšx Üğwñ}¾5õƒJğ13èå;r‡m’©éùA×‡„¥–(6^=ÜËTÍ]ªÆ:“‚š[RÛ­Wı·ßÈ\{&?¢>º†L&ÊÊA<¨FN
šæÒË¹ÏWûÜé“/ò–b	~˜~tÑD4†×Êß™›Ä¶Æ[*µXRÀà›½Ñå°?‚Ë+i Ãd÷÷^²°‰gñbùÔıM²)Ò¡ËYcÕïöGCş£-\’İ_KVà®ˆ›c<e©àÏm™!h7[4öûşšj2V³ü³Ç·‚)¹øŒä§ªëcæ/•ØNÿéÓ§¢Üº….ékç<_Ôç½“bÅËèfºN«¤xïVD9$r’?'´}ï's¤Ğ€şl¸¯¼Ó™ÆúÁyÔ=‚ƒ`O>§Š’@Õ0F™†Aƒ{À2Ê†Ut™;ùíq4Bí]8^H<‘„‘‡:0ñ¨ÿJH\b»Ë]n°¡òQøöb$c	z»¼¼¼,‡ÓJ0`b“ÃK|{@z(šĞ	k•#_”k•Úzåq¢*“ ®|ú‰h\Ğ’//ÎËºæ$VŞ”ñùtAhD²hm–ÅVlKÕŒ2ù\ö9G–¦zDò8KÊ—…-ÆöòS÷ƒtX7€®Áôå¢x¤³NÔõu jÄ•ZÕ÷˜ÌÈ5/-ÚÿYÈÀœÎöËØ!y+Ÿµ‡òêÍ¬NÃ=ÁœÚÆ]@ê/´	mBÚ½¨ÿ!`§’#jºA¿.VáK4„	OÇ“5sÁÊFımïĞÉ k¶8‹kşoÎÿéğ§hl•¢gñ’9ı3	2+À™½DìéÁş.ÍşÕú&{ÃU¾=Š5ıfë«d´Ò©j¤qœf´°\İ±0Ü¤`†D„ÔQ°¡¦Ô&É ]ïÉ‡Ø9e‰¤÷Qík|¤¹KH°Lk»[Cá!K$Èp"1Ğ6766şéIâäÁ>;V+o3ùµxK“¶_)«øqıq¥^yì»YgJ¯_aÉCØ§jn'¸"Æ¤#Ëãfcs%Ãdkø32¤c£c†ÜCì¹Ä0³&”c:mL¦ríú³iæ¹Xœ¥8ÏSã45ÜŸ" ËÖPÉ9™d…«…éŠg­å"òsó4-ßî~·8áÄÿ5$:wKPrC$R\{vZ6aJÕÆ@%”E{ï›½·GB¹²@î3—Òsp‘«Á“İŸÛ»¿PÓMÕEú‘ï‹À`RIÌÍy“w$äxá
HéDO%ô–®ÂDü"*ˆj=`-n¸ˆCg\.¡W×/é‹¾ÆÚ*ØÅtS’Ø!®ü°âuù2ˆ&´\ÏÉ_v« ¸A¤Îs‘½f!©ŠË$³{VÇ¥Ã 	‚0˜0¬úaŠeÍ9ÃoPómÂ°ô»^ûf÷øØWËk:/èƒ~/½RÑš6[ŠßÉÑcŒ[ËÛ'í~rgK„ìxãù¤:ëq(—‘_ÂªÌ%UEBåRUöahV¹÷™‰³OJfÈ=0Í VñcS—:¿K«¬9‡çoîz«±ã…s[=ÏFdÆCÚhÒû<,U5Gà&#W¤ÃÆwÆƒ¤Óğ—kşF^5GmV	´…j»‘¥óã·¥~"lÂÛ%éuB:ìø«—4ûŸ•Áà†U›¯ByXéˆŞÒËÓˆTPµOÌíÜì¬- OÈ™ÛÑ¦‰³Úx³MÓÚ6ÕÆ©ÿ’K=6Ö›D+Q{i†?2ûòzgo_î£zëô=ç¹ù†ì{ú•ŸQR•-ƒÖ¤O•ë¥¦¼ØéÏY‡{+mq¡:á),?©Èö°Ë\ÖÁ°EV‚R·ó$œrÄ¡²,¤,&¬KfERs|Mw#®~¦…BtıÙXIŸ3K‰‘^aõ•-$cVE"ïló´[ÊuÄÀ`\áVúU”[…œ›¯@æh0©ÑëõhéNFB¹ŠEñ«ö³Š¸#ôkIa—ØÙ‚(ëò`¾¢f‡%òÒ¥aÃ:Ã0ìub
l¬OJˆ\=œã Fp—ñ˜¶­q	ÛBòÛ?|€“„ÔÕ»‚ ‰!»TQÆ±ì&­
IÍœğ~¡”¢Dİ¨¿»&J&¬áE`™²²‹°¯dœXÄ]£i“²“TÁ”•()-K(ÚÆòêÙÊû»{À°‚ä2Ã4£Ü¯¦ZV“zi1MjG#ŠlúRõ]'¤ó».R¶¢6’t¨Ş?x² ıÈ	¥ê-å<røsm}á[iÆz”´»—ó¾[lñÉª7Ö5ÃÆì€û;šŸd3ˆ°áç0«FCöĞ„i@ôì1	¥ua‚Sr@Èè·¨ Zi ej×!4ñÕ:XşÚK-îìóWÊ$ÓO©¡†å¹D&µ%øé°vûG¾‡ğÇğJ3|L`a¯ÍŞ>²(7aJ+ë>ø	–9Ş¼I]Œ¦Úò|¶¬DáCºÁw6:ëõŒalÚÕs‹4'mó´
EézmÙÌ´åšÙT·J]»QıLDğ[fT;+[Æ’Eé+Ä^I¶yët–a²Nñ ó»M9Å#·õ2JØá’jûrÍd(ûY‘ÖŸ•Éñ™áÍåÊ#¦B™µ:Óëf<Ü9šZz’!t§31&‰¿-Ô
Î¨BP”©fû&2ÒdOü¿Ğ9Ä½D™"v”j!ğÒ@C'šW{»¤€TèFšúìì¾œŒ{áÉºÑ¨ÇotÎ<EŸ™4¼\ÃØlùÒƒª&óy0K½‹é¡í°&Ïc3.“mïKÌEÕ®ÁFQ*¹á)°Äl»[ø^á„^®ßûoÆÇ!ï`qrO6×–şœ\†¥Âv¦­˜İÎ}Œ`–U*Ø÷¹Ay>êvy#åC­ß©f/î-¬9p»ğº-¸à˜µ+—ænË²PJ±”Ô›ÉÌ8ñgÖYlf!Ì¸AG
³{ò·µsÓGDÇ2ÓIÙ-œ#_âL°İñÉ×ëkªQ—ä™_ÓoÀ³¥ÁlªD#ª|ÔMM.ñáaÂ¢‰$ÉÍq^È¿ÈP7ß!ï²îÛPEE
ĞaÖMaõ™ÔÊâMUĞÓ6†¾WºBèŒ0›Êe¼9Üß{µwÔÙyuetŞì6á]
`‡1_åšƒÆü+Ü‘pQ%qKÉ¸†©—Ò95®Ï"¡(NCØ‰DÃAÛ‹q†ÿú=­ATÒ³”Ç³Õxn^ka¥¼ÜA44f¸ç<ÿÈJƒ¬®˜óñ²'_îlË+BBŒ
ÏÅ”2â8—hO” çPFGÚHÇ´•@¦©”aúİçcwÍªêCQEÛéœİv§‡­DïÉdt(¥”3N§ÌÙäEÎS/wÌRüJgşá(™¼’îsGƒë`¸ÇıøŸ‚ÌCù_?ü"ş>~\€ÿ‰ß7sşj÷şîñ?¯ÿYäï§ëDñäé>Ñ(òÜA|>%?X¹³-Ãh¡r]#Ö…ì•Ó¸ÚƒÛSµnÊ\[™@%dÙ£aÚ;*k¯AA|G¨ Œ‚)Õk:i{V×ú×D‡q¢LÈ8/Äh<}ıÕÁ›ÃVópÿ¯ä)"QÔ†w­İö{úú
¿Óİ s¦(3ÜğËe Ï‘WŸ2\ÃQ“]ş-Á8B£w©ş@Œ”¢A€<ñe$†By²îíghëgÑhˆòCñƒ¡ºitıà Î»+¿ÃÇal\Êe™!ú´;å7C.å×¢ˆ¤Â_<GùZ9*Õë×ÂyT=3ö*àCk2Nîÿ¹ötãq=‡ÿGÂış¿ÿßÿù±ÿùèCˆÎhÓ™¾ ´ó$±NŒ¼  ëšÜ‘Ë7ªäÕ¨?ŠÂxàÉ\pá¸¼r¾¯moÔ+*bçÍN«¹ÀQë·‘Æµ_ÂMûÛ]ŒŞÔÁo›ß´öd–Zš\©Ôèjq«LJ¶i%ÜùÛñ¾.`3gåÙLöR1_u2óf¦Üå$¼¦ò…ud¨ı¼Ğj]ú4¸RWptb`n˜â,Š“É¡•ƒI*9Á) …Fv¥VÔ”5ÏÖ"äáÔÏ€ÿ
Ÿü5O_…äc¡{‚?}QjíìıMìÀØ½Ük¾=jò„óÔİ›+pdõÌÛ¹iÉLê„_hvªü~÷›ÎîÎÑNgw¯Õn˜·WÊS¹1"}Ï)Îñi™g"ß5÷_!-V½%z9m?Û«Ó)²‡»äŸLN&‡£Ë0&÷İ`…}qĞ‡İ*Š„*ø) ”ŞšÇ-`Uûğê>™<”@³¢dpL(”¢ö¤²¾)öÚ¹ˆgÙ~“3"¡T:4A‘|·ùroçmçuë &ÉÛİ†>DÜp-AAğÍÆğ¯)j…Ê‡S#Ô§ÙX7³ìï½”èŠ”ÿæ;¸6¿7kÈcB(ô øó¬­“Ñ–Ò§Ş9ò‚q­«v›íï×¼Ã£ÎÁá‘Q uæ“ş0œTºÓ 2=L€cO“ hµú3Ï¥f·eb+¥Ö@nš2è¤NvS£µvvºli=tRçZÄXe§¶xÔ÷œFzO*µJÍŒ#º™­o›E×Ÿq@ªÔš7jif´BùâDN4!µ¨%rBJÊóhòazJtüq0=	fÀUğæ´)÷œøÈßä+¦Ó„Œ¸»aãOØé:{»M•j†#´üÇg0à© àc9‘rA@Ws\ÜÓ¾kî¼²J4Z¹^Ğ™rÈh¢hPÒÅâ	Š5İĞì,p…¸jµ8ß—7Í·Ç½£æ+½ûL¨c|¡ÇîÄ(ª"·ß3l®-“¡|y³²‰T¦ÒóN+8+g€Óé¼f`â Œáğø=¦éÃŸVöwX÷`V˜:¥´éN¬l@dBİâ8:2ÕMJRå´Œ3æÙp9“á	ÀO‹¸+ÚĞ7_9½¨³"US'İ%*ë•|tnÑ&ÃÊY†ã 	D= ª¬¤:	ÎãÑ“Kùì{Yï"»ˆ'`k×Hqm!5?RoùwXb.ujg¤ff‘«ü@>£&P«<«PFI@Øîìwg8¼¨%­ƒv»³Óz£Â­Mr… RYW)é‹Fâ}ux,-¨;zĞÖ¿¤=Ôe|GÀ¾}íãå_PanÇƒ‹§/vØj¾Şû¾\ã
\¦azgãnƒW-Ô¾‚ö ±ÙzÈ†=ôËe¶J€¶ö½^yÌOjóÑfÔ‘Ü9…Å9l“³±âUé?Şc4â«2¿•ùÚuò ÈMÎà›ö†ìßV“åÏ4Ü¨Á_²½èHsIAôëÕÆ³n_Oã{çö‰	{@©Õü¦ù½øËNk·Œ¶ç½ku¬sÔÇëÒ	AEŞ‘Ñ«4í{ÊÙuŞ/3ä6Á¤aãN?Õjå^xœÊéùä#ìPúpãèÓéôÌìQ<ª«_°FÎGµ4öÓ$™¨ïÁä£sş¡[V5áÙpŞŸN6Òoî{)¶uÃ„Ã)é=!.U2=½`q“CÁCü "ZÃ-íÎÙP~:ŒƒXÛœ3÷ôNÅ9üOÿP»ˆYó\®-h+)	©ÇÔJğ!TÈ»‰íÃ¡*Óç±ĞñäVp‹áhXÆ>û²°2ê­ßR°Q¿ÿƒ¾™æu<Üš úÚäòC”‰t+EíÁ4{·³wÔ¨£½5ŒÎ¤*†Gœ*½C a“+tn»Åwk[¦~W£“I6,*¼¸+ù!5##aÓnóóûÑ8Å¤™(NÇn©»}šÀ®7­bæG>Š³pm‘z¬5Ñæò×ÿT•ä»Ä­6Ÿc
+ÌUÑšµéê@H1Ë¯Ÿ_ñ´STßÑHüˆîƒ•¢U{¦T!Ä*¡ü ¬!Z”ÁEõQ+`rÂ‚]›ßzvšMhhóØqmæGZ°|~Ö*ª¥E/`¦!b‚—+ieX\…š4SåŞmV7 :Ósku~ëqÍ™…mô‡„éĞáköƒÅgÖ Ã&ğRÙÊ,•l[DnáëÎı0¨Wã·í##µ|0ÔÑoß¼l¶²k5	ğİVf®%¼IÂ}l½R{R©©ÊP $;6<¦}y;š`¦Ï&èú¯ÿ)^^iãRœŞr¼X¹û2 —$>Mè…b¬]<BçŞ4ªQ"´*„NØ>u„¦«§Êª¼÷@Qû×¿‹½3L…şyûh¨pef§Eˆ¢r¬Ô\î¤K¥zÆ¢È<J‘g®u}:àC$0Ê
««)ú™Òw?à»\«R–$OØ08à®ù§ê8ñPFG©,¯Úbo¡´7ÛÇ‡(Øß6¡™­ö­HÂeÙ7ë"ßPìnÎë¢ysSZ¹Ã«’º÷âewÿİZv’F·¿PÉ6åR£ˆ¼ÄÚÂp+@ç1§q0ì~@n;ú|öŞ§s…¹ÚW çÈæ÷ÍWÅ±†±GÃéRÊ¾”ıH¾ ²
iøFÛÓ–ƒiÔŸe#ó°!(Š…½lC×æÆÌh¬ÔŸb2ıx—õ8·ò,µÔnÔjwğDêúÜëúÍÑÿĞÖw«ÿWÛx¼±‘ÓÿÛxr¯ÿq¯ÿ1GÿãÆ
 ÆT¿™ë='Äéü›TéEşNTBøAE¾Á½øxŸ^¸ğØ]ŸùsaÜ¿fw…‡Ÿ=}N*œqW6K—Ì_$¢†åu(qDÉc¹r_´UèÑÕ=“rØÃwĞEóƒÄB=Y¡WêX¬äA;Åõx‰¡Hf;ˆGÂh¢?Eã†@)m”3Lô²ı[Ù*Sh!5Ş˜+-JëB‡’”oi©T£Ì+$­›á”nm¥
µÚi7³°Z†(şü‡dQzâJáO	¬G{¢Ët˜ÜÒ•k¦	š/tz!ª=öPñ4%Æ{;³(ã/›NÒ)æE¥RvZi³(Êñ…cÀ’¦P1bÈNåõ&Tjá`šoñyÒX]~¸–EAÄˆœNÉ¡Ó·XJËHPæV»ŠVñÒİ6Çwj9t/ÈHù{ÖĞ@Ø56Q&ñÙËX|Pq†~¥¸M#ª-n;WŒõaIk®9cW×xoËóè[E…l-+ãp£ıdşè6LClUÔçêxÜıôD¢>Øx&ÜÍAû3²½ì=Hí9SÉ¼e†ÖŠrr–·‰Ë8v¢Dïşê¡~“´iRpQò+„£™7|Ëz×lŠùªÏ3Â•öj·ƒÓIkğÓ~(	áÆ¦Wå›î-üH’ÂKáŞ[q;#Çğgd|¡5Õ%¯Eei´T¢İœt!8œD;©œÑZŸè×ñæ‡nq­õŠb£Ÿ¸`z]Îeˆfb«.˜=Å§L]IÇ£ÑD¿6Ûğédók'Ğ~bÈ!EÔ„¶’¸é`á–—µº3Œa3Ş!S•{·¿¸ŒÛ4ªÅ·r÷
&®×Ù…q?çÜVÂídƒK\‚ˆCšïp$ˆ¬üö{Ù«OàÉZ1\.Ú3Î	P˜C”Ó¾ŒdÄ.œhşàÁ[G8bdÔÎ&„·GóÎ(3Ó‘T~¹*Ÿbä+âZ*<âÅWuŒ‹²ÁTÒ(wş´-3TnƒƒáÕå‡0õÚÌVäËâ“~„®ç²MÎ›,Û Ç›Œ	qàW"M¦ç êœªÈ–“*¶ïtd×Å²~I¬{/‚zûğÔ®R­OøukÔÿ_¤0E¼ö7Í´HK¥­H›°z.³õíÔŠ6ÛA1¿‡©#'Ú™„äì.Z=Ôm¿q'Ez4+ÛõœMî¶îß16Q™UùÛbg™´bX†}~’æÉ'cÎ"<hÙ(§˜ÍË¥–J×·s»Bõàt|\ÚÇxàø_ Zo‡à)Ş¥š:zsjq?Bh¾''´@
Öºf‰›CïñDÁ³7¿a£z¼—ÏOà øåõëiÚ@É™Ö‘ÅvÆ}ò†LÄ+s'S<–)ğ°Ò%0º•å¬Y,×Åò¦X~’…wçîØ‰±+ÂSxín0“öæ9“F‘ALO0gÓ>İï§C¼åNàrC:X>0BK¸yä×‹<BGĞ@_¹åZhBéT¬®ÖñıÈÖA—¶·+ğõkÕ¤Í½‰÷q/1•Ó|ÆÌ.¨¡íùPCr@f ([PÆ%ïé-ÓŞ\o^$±¼KÔQì§ñ¢GTrõTój®fÑ/ìvº` Bd÷RçfZ¸›:·SuHo;€YÔŞZ¼¹ÒÒ Ò˜SgZG1”Ä¼Ó0kô@n­†ÌÉÈ‡‘=ÔosExzp¹ ò¿h'tø‘ÿæ$»öäËÀ9À•Éf÷Et‰Å!á%QÛKKt"ĞmøE„–•jÚ¬U‡´v¢éú`ùkD½>E8°ax˜(AöJØ7¥º—¯<‰"½9%)©|ki,Y}l$Õ)Q'Á_Ö6«Õ€h«r>´÷bÍ‹ï¡Ñ°©([ğ»˜+KòàÊ“ ëı“¼ÿôFİ¤úEë˜ƒÿ€ŸÌûO­öäÉ¿ˆÇ÷ï?w5şpäWÿHãÿt³v?şw<ş¦ÊÓ]ÿÆúF-ûş»Q»ÿ½›ñ?ñQB5Fåt¼ĞX•£omKégÂÇgU±3=µg¾ ‹\¸ÕùÄIªTºU‡¾Wi+Şî¼iz¶:İ‰N:e<)K{ïíÁa{¯íÙ­9=³¿?9{ÉÒ¤“³Öôóà¶ñ7æ^8Ã•È™†Ë¥4™,hs{ü0nEYõıK·ê¤|Âœb>„yG+<½ƒYÁÆ•Å
'Lê
Ğn·Ù~ÕÚ£ÆzYùc K÷£!»|Ô>†bçğè"×ğ•Õ@|¤½YĞ†e(]L›
Î©Î²–2(ÍÁ7dã Ş±gel¨¤¯—¡—ü¾Êª—”XRßËRˆ%Zdª*Óà8é, ×l½[3¯$® ªHá•„æl&³†ÓhI›yx<OÔ€B®?ç4ŸSí3Ÿû‘©øLcÙ¼"›=C%åøå—÷2ÁB5)	ËÄbc{T×Hƒ¬W«Âñ2C¡R–º&•h]‹Õ¡E[^D‹VNk^râ8áaØi&75H…`x%ÈÔYÊ„3Kt•!Vww4…#¢8J^[5po ‚-çZWFV[œ)íÖÊ|Ô1l{{¬zbÀò÷ƒ)j%Æi3Q`P÷0)‰Z¨<	‚K]	(“¥–p,Äë‡û­¶ã£oZ^Ö`µGQ§öoF¸)öÑÔyÍóşåşó?Cÿø?åÇ &Z˜T½;ÄZßØXœãÿ6ïñÿîFÿÏ~¤lñ<h¥x¤ôF¬¡†=Š†è‡K2§£éDÃKqÒ‡ÃSø˜CÒG®xŞ)æ?pĞŒNÃø‘ µ<T”>~á-=O&ñhxşâmó]{ëyUş‚ğiş]zŞ^ìá#UoÚE	h@µiİ/±%‡ƒúì«Óq%ùğ¼
1Ï«P€,gÇxáFN×’)ztí`SÅ31Ó¿ÒñÊ'®±•ûd ª‘û¤"³>¯bËŸW¡sÜù:t¾UC_²áxN‘‹.¢Âë½ï›»dØ!ë`)ÓÅ¬m)[pçÈGÔştj#=”RY7I¡˜92·hj1PÊK›¨?s%b"2¬bn¦ú+"½Ã¡zMO€±y’SÔÌÓ¦óÎ85)50tW$4×$9_1tP¦æ\á\hH2Æü4é{Öbbuä¯…*€ÏˆC T7ì!Ç™¥w~DkÆˆŞx@¡˜UjÅšÙ>‘×Ú.j¢¤B–ì3qfd @à²òµÓzsñ´*Çûzù 6G>sâÕÍæù_íï‰7èÂâ<L²KénIç™şrĞm'µìkiË>kF_J µ‰Îæ@»Æ™R·ø¥Uˆ);W
â+`é¸?\saFèMp|²1
Çü@FmAk€ÙV_6lu&\UÕB¢Êwî‰‚°˜ø	{zEŸÄñPoè² 4T±ƒm“ÎÑ5Ù+ÅƒüN{ÏÆİ‚üï¶¹¾…ù¿Í§O3ü_½şô^şw'Ÿ‡¿&ãmó_“İY­­q 0"Ÿ'ÿ¯ÅW*‘à"E¦ş‡=ïáC#Â7Üë¤ñóqêòc_ÏgˆUU*„·Ø‡•àq~E4Ş¢H’·¨å.z#ü!‘b˜4jfm7Î'ÒœZäf4Çˆ–'§™S§j¾7¦IA	†$È]Ê×òİÊ—!ë´GL~nSş™€Ûğ{D ªR7Æœ–Äô]†Jr’,^CvğÍ4ÂÖ™efÊ"È…Zó"FÊf‹
pLM…ÅP ±-*É5‡9Í1®4e”(·P–+Ö
f¾%Ş½în%Ü"`³kJ4ktÌ !	kÓ()Nà;å÷ì¦hi±¬äÆ³6Ò…MD‘î$’O?%tV]”SÜ²üÙ=åÚL£"ÊÎ#¡%².êÉìÜ…ıWm÷lE7ùú‚n)é–¢îy²n®·U’wC¥²EN<_qsüÿ‰Ğº8I…|·x˜Ãÿ××Ÿfßÿ×7ŸŞóÿw#ÿ=˜Ğê£¡‡Sùß§aLJQR¢…Óøb%¡ÍQéÅ7Àón†¼ÏFışèïì1”ÉÒ`Û‚b °Q_L®ÆaÃßó•à !jH',ÀQ±Jœ†Ö^_ƒDÉ$ìáŞğ<âğÌ	ÔË‹]­uZêÕtË)kqCõ´?:…»/”W[Íİ7M˜öşµÍqŞåWƒ¤ >:;‹ºq•ªdW,ñ”4ò‰úÑäŠe´Â\ÜÒ5e¢ËlX&S\üe@ÿyëÜ5ŠQ…0=ÇáğÏ»ß=;&(Öl5
n$4E(1E‘ë½ågeøWXE¢ìîewm2Ş[´lÄÏS%şúŸâ×¿[Å“lG¶Yô8D!ÌzÄ€‡AOĞƒ8èBMÈÊ.“ä
=š'*D÷b=Š"šKQmaî½ÉJbéÉ¨¦É†D\z¼Ih Í‚'&û\«ŠzÁØà›¶©¨Ğƒ^‘¬LşiK!>¿ÀÄhk‘™5½jqªP!×÷Ô ŠHÃ3=SX"ê´#’[¥æÊóUÜ¿ßî?÷ŸûÏıçşsÿ¹ÿÜî?÷ŸûÏıçşsÿ¹ÿü“|ş?} h 