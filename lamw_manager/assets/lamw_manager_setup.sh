#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="542801537"
MD5="afdc1ab15e26992a62a4a0e66a8b26f0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23576"
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
	echo Date of packaging: Thu Sep 30 22:17:09 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[Ö] ¼}•À1Dd]‡Á›PætİDõ|B½"RFŞí›M"<Ø6c¥ò|š÷¡13×ülW·ğ7XxÄva|–7ï•ßOæIz@å‡‹+NÈş,Öü1¹–Èf»yj-¸R€Â>;ÇqËfgÃ¬[ñ:.)>$mµU@@AïĞ¯IÙ/$pİa	GğqzçáER¦aŠ|\1S8öØ{ãh‰3gk×”"Wşÿ´%­§;ğb' ‡Æ|åMôßcªÇ…@ƒHìùš©ÛÆÎßhçàcõ ·~=YAKÔ!QËDµI”äÎú"OÍ’q½8.Ä£Ö"®NÛ¦3ª°$`úp½ÆPU}œ{õ/†[}%ãÍSÉgõ€UT˜Ì2ÉOCa#ãq!.Ònû™§r{²Ïÿgvè¨@jƒ4ˆà†r¤„`›BÂİçØZ Â„úLz_{ö@íç`í.O5ºÈ±/šI4™T¬ãw¡>€½c^ 8ò˜ZÃ±û´ñ¶rª¸íFh+,Õ~Æ?òü#x=-¦éÌ¶‚Ü€ŸÕçm¦Ç(0—)c ›¯¨pÆEqêK÷Ö8h£‰«Lf—ÚÕ®=T©ÑìR#Š‰¢Eí3™Ó\¶H5¶(ñ û@‡Füòî­%â®¨œ‹»I‘i ‡ë›úüQ¿ÎH|UN¸ß)„´µ.}ßòoÑÄ¾d¶óÁDeòîYŒ´ŞvJë•A¹ïñoÂÁ€ˆœYØZ‘5ÇúoÑ¡ŞµÈ¡Êıû‘ï±ªbKw{º‹ƒè$,	,„[’qÜˆ8ŠŒÁ{@ƒ—Œ‚îÔŞD²ò ¹ éX¬õ¥VKq=û×²gZ\·Ş!¤‘dü~™ÜÆ{ã6t¶ìq…ê365iûöµß†Ê_Ç*mËƒ7aåjø~«PÏøa`ÁıãŸ’à‡’õ4=ºû¹Ü0E¢©wpÁèú_«P€zıçòB C´š–öU$
ïÃ¤9€(¸İ1ºá| Œ½«…›'ÜœoHõŠ}ä*œd}SL¬,Âü3>ÑŸ¿™@ˆ¡Lš$ş*vĞ$w7‚KÅW¨îmù†
¥Fğ¿Y…=yÖ½hrø¨c?Aÿ÷fxPWÍeÃª–!³„$fòæ,â.ß4^:Š`í“K–˜©¢CŒ3ÌºÙGé›yx…ÈHSÿ+D#ß¨Ãa	öè8¬0XìäZ~>‘ƒyït„i›ÈFJâ®d$*%oH²µ»K»™úôâ=ïş‰‹1—°msğ“‚ì«ZMsq©•åO» ~×ÔeA²PÃÒ€¥ÅÙÕÉR•e“€Šrôpn(è£ºu}Ô¼;ùÄõó[€Äê`jhğ€…MƒšFk_ÙNè ğÆµ§ÈÓúU¼ğ-2eşÖ‡ÙHOqÑƒÊDì¹—BáéZAoe>ÛCŞ¸k\ˆaÆ2köEÍÛÎËˆ@¯BZ>P¨Æ 83,Š%e‘9}†‘x‚¥ğ¸Ù)ÈÇ£ãnY²tÿ»Å­²yhNõcñ“ÉÇİƒwÂÒx¨u»Š BuŞî¥¢qºö:L|¥—˜Şx¦fJ£E³üË¦ĞĞ…79u4t[¨ò1ô)gåĞS®'F|]¸ïRøV#Ø››oD{ y³ÌÆ«RpGç±K|È÷òEÜ”ı±=æÉ$…Ü—MşÉ©˜‡"ƒ‹dM)Á\^aŸ³Ã§çÉá²+Tëƒ»»Ä}f}øS€¬äıøC‹ã6’Îq:MªÊ: $2W["j+a^í\Bò–I™GFõÕ=Ö4]Û0Ä¿‚üv3'°ÚZT|¿ŸéÕŸØ¥¸2R¨%Â0cp©è¦Q1BÔûólİ˜Å’Sù›ƒI†¯[îÏn$ÿíéj¿şï)|C[Ìÿ)Ôèœ‰¤¿µ=×ÇŒ262àM½–IÇş“¿$Q”,·«:œ'%e³¶¾µ’dŞRş5˜ˆqæ
R0z{åU2@¼sROÊ@N¬££„Ÿî¦AÆŞ‡g°Bk±†%ı¼I~Zs.»s#´«“® ¶û›; Ï‰ôµZ˜qô7 Àa`Ñˆ‹Ùåg-¡NrZ‡ŸñİšÛo‹¼HhlhhQ®“ÙJ“$ÔØFÚf-NßøLN«øÒ¿›Ã×¹Š¯øHkM¿£Lm'ÎQ¶×pd4ıi[Ä_’CÁÁ¤UõRvYG.¸j>î¶™Sâaåp÷Ìt—²ä¯–Ã®¤ÿ×D§åî$äzü
/Àu^Ğ¶ÿ•e&©WÆáHAùğÜwÖ€9ì¼ k°SŠbuV[fî»@ªwšß¥2Íé•Ö,~]9J;¸N„£²cîÊ#Haµ4XYıòİ»›:mš?mÊ|òÂ~·"B-JıkuuÙ,cÂ‚Â¼í¿S‰/s>:#>è¼eBx5DÜVt³¹¹Ÿ\U3"IÆÆS	ÎULè©ã±ß4œÑmKçÎdÇxS–êÉè…dI¼dN¬ÃN4‰º~¬Õvo‡ÔOÌ¸ÂÆ'oÜÓ	±şR ò[Ä;$áe âKGs‹v¢„æ2À8Ö#P‹3Ra¾#˜`f@­BjÛs»øÔÕßêŒ]9»!HíqÆÀÃİu‘¥:œ÷¹(5G
¿öÅ÷*@Í¨è2a†ÀÊ§„NlıšZàyÑ@¼aiÊ¨û,"@÷é»ÃÂfˆ/5e2¿Zˆ´{ÁE`ğ›È)áÏaö?²AK¶|>ËÁ}8øÎ×•Û!ÉÔb>äj°dÄÔK°% {ˆØÀ,_.‰æêe‚Í°üW9})n}…hÉ²‰P|UÉ²ü>¶£ÒhÛ:R‹Õ«‘d˜O“à.ñxÙõgÚµ~<å­²›öÌ-½³3¡t§*íŸ¢œ_?>4kÉÇğ9Ï*„íWå’RŸ›Ò¯°\ov*ª6zæ¾8§pq\~ùSõ3Ü¶‰ÑsrH¨W•×­Íğ:S.ÿk¤¿ñM2».Ê¿å6Å X*¹¿Tš'U{„¤wÑa»Ñ¬…
¹_r·_·8¡¦ÙÜ’”ƒ<C’!=Úí“f6s	dtÓ'ÈL cŞÇÿ_ú,WDW®ãÖzCø4µ@5‹Ñ<}Là8/UÈA¿·i*¬#ç™{sŠ$dÿ7•Ür¥ŞÓuù¢.B^N­tàÛ+§(ü‡°n‘Sï[L¡ˆ	¯ª‚MšL“~ÔM;Ø—( á¯á ¦´ÕŒŸnnt^¡$·œºUıÓÍ×yÌ`ûÖœÀB6Ï‰‘ÊKÚÎòÙ/V/¾Å4s¡: )e´¨ğK³lı¾f‡nc1bJ¢­ÜšG$$Uì9ÙÜÏ‡Ğ`$õS‘ ]”Ùu9.aË«ºÖ¥ãlåB\>o›©ü&ÈeÑ™î/ª®ÖøôOxˆ](háÇ2hõ»O´iğxGJë¯;x0‡º“ĞÅ£¬6t±¸-}FÂ*$]UŒJi7ãĞâcëI´Š]nÆWGÆQHh‡p …òK¡²˜hıâ¶íÔŠ?Í¾ªddåe¯çåM³ï5½­he®¡®˜<¿İ?Ã5ôÓ¨˜Â'œÎ¶ë¿?é’c›­I6@Jy2ù’jŒG»±N„˜ì$Ë.õuy…KOCPz3¨ı`ÉKª#~p8‚ÛmÚ_ìv.brêÕ&BR¾M>ƒÜm)C
1€õğçüKˆ™Äˆ§Æ¥)°IŸ54sõv&,“ëŒ8äê~‡¡ÖQŒÁKñÅ§ZøeÆšD¡ªìâEà­¬İæş?Ï·üóxáÊ=&ò®D¶ A€ùòYWÚËºzİã_W‚KÇw[ßÚœ7F÷§]Ôæ,¾!€jÌ³DÀ~¢ ñå™fŠ–î… ŒW¨â%À4P2Ñ¶×ÎJl`:Ğ$É †¢¥eøVy¸P=àL¥ÍFz¼?ã‹mµª·:°\‰«N<š–W%N{ÆKº•ªÁHí¸€Ââw
3aè’…¸-	Peèdè™ş!'œRi+ãñª¯áVÛõy»Åœ ±cYq26›6ò=*SÍ¿çØàñCï0F×~©(ÿ÷:ãü)ê’ÊúÙJ wÈÂÇ#×M!EslùÂr/~Niùî$$1H¿¬p ïF Ùí0ë¶ñ†¿9şšE²E›øF4T³°İŞ@€!€¨c¸ü,Öîë}iéj[iššä«`?@)h\õy¦õky^åk±ğ½¯,Ë´Mÿæ£lÕLÄ«øœñ5q'ZWºI:Nà¹K¢¯ÀÂòä…~‰îƒO; E¬Öì_ScµEhé¼—P×…½ÿ\R›ê+/ş•-è½zW:~%xÚBş3joÆ¦üæ÷z6³b
L¢ˆU“Ÿş‹¾Æ&pë2
°šRŞ™Ì¦~uŸé°5o» ĞÁx„ç-òfíMx‚ìÃç$òJLóĞŒ¸Kâ­p
Õß‘‰±1#W?—\›~Pšä~=^
p¡Êƒbİ€FØİ»xIÕ,"õD–ÈÑëmÖR©Ä^Ô*ßßÓYI%Ÿ§dv•Ê¿úæ¥vº—Dø|Ï„½—@Á€ÛN¼¥9èX…e{‚‚:Æ«BõîÆ54Êy>™é8ÛæÙÉî­ÕX=Í}[zVº10¡e
a•´9ÈÚiŞ¼èŸ30Ø\á(¶HïyóËS\ŸH\S
X·©ù_éh‘nqc{ç<6àÆ	{5S÷NÒŞ4,}i†/®l¼ÔG¼×ß¡gˆZ‚#ƒˆõ:5¨è`ª½#«¸!ı« >÷´¬@XDÙ‡'Âş´våu\fnúËj˜ûÉ¹½TU0çëxû£¯hıC®"Àãu¬şD­Éñ°"UÒˆŠkİ¬–FË3@â­…’îšÿé¤–4K’×àŞ_	İÚ[‰n|>İ€?åäæ*ŒÊBæ´øcû|P$%NŠWôÕp¥ÚqNK8“ù=Aäõ¥’=OÀ&^ü‡;uòV®ìtd%„ÆæªúWĞ¼ “QıÊš8ÓÆëÀĞÚ¦d%‡Š{÷-pÕ:‚ó˜ùÄEv’?,µû£h!Ô`µ¤IONÁTfBÛU ®KcqÇ²o&[­—0Ì×W;^]º§£šõæB/½Y)Š,RÂğ=AN™6ç$J\Âq£•ÈFfjn'ÿdçŸ Z¾*œÊ—E4Ñ8+<4iY°…›¯dëà4’¬+$ĞcÒ7|:ßW™;_ŒŒ,=ƒ êÊ®p`£Ğ×¨¶zİÉ/ù?ü½ÛV%9Çí%t•MP9Ï.ƒ”Ö‚Íùwôke»¦ŸON‹­¯~Ãı§EšÂ'ÛaŸ½óˆGõ–•µ)°Ç•Â¾(´Ë]íNUuXPG	“s±*qÀ=ûG`—Ô>·ítLóºm%Ïgãd”U‰¸
ú‡EFø]À¯ÇwQ2î]Ì*Ï˜t#İµ‚/ä+²:ºkArİ¢—z¹äûxNg®v\o‹–bƒ5">Ö7ù¼åÁz¾w‘îˆÖâ•£'µ‡×’…¢’ZÜº[™Ìè+‰ÔY—œíÅª¢ÒâRsœs@n–N2ksÓÏ±ü2m¥À½‹ó$šlÖ@Ìr_(©€¼šúáu‰±µÌeàã¡ºZşjµ —W©ıÚ ×nhPâ<R·­R#ùrc.Â:k0V
÷c)‡v:ËÚğtİ1Ÿ®ÒWè÷¸3%aØ›®_õĞùÙÖ>ZªçÇ¾‹3/¿ÔLã\¡>ş“Á‹O¢Qï÷*n¯üá‰±%YÚ%òà|RµnË÷ë0£¬Îö<}³µ¨8°Á?”ÈÑíNôªÉ«\©Âøğ¢B	¬Õ	ä6¥G9ÿ„¾İl­úÔÑÎó]’®(ÙkÂ%Á€pùgÔEdÎÅÒ/N©:´¼o,/ZÈè	ã‚dolıÕ£+åDX!×	’ÆÒ³lÊàïT¡ïoÚ` ûgàCÙò£eÔ¿›Aì&‡éÌıgC(šh-ùó½Ås)ìcÔÒÑh—ÁßÀ\§íp-Á.é‚=Ã7¡îÍ	k™˜H[le§>…Ü¬zÙ¨½¡&¬…‡­kVœîÏ6óK´î»Ø—Ô<;úÏª"àíŸI
€®f¸µ€$½µ&‹"‰i})OF¥a•ˆ+š1v(@ß|Å›Ó‹a÷†ÏrçîWO6AıÑİğJAóïûhµ/l«0Ù’ü¢/}ÇóÎÅÅŒS€®0¥èmÜu[yt(ÿ!Û5ælø”o÷áOišCÙ†éªC'æ
‹¦öù$v¡+2‡U9o+æaœ¸gËÒp¢Ğ`uÃàû'º,(…¿ÆÏ#…7ÚkÆS+í¯š¬6ynNHˆù³ù­øMcü
²9Ñ¹¨¢„3›¿¾º KÙü| Û~hC„Ùâ8]ãÙ}½èo£ì÷ãúpÑ³ÌÂ¨±˜£Õ9CÕ=Ò³ßRó¹3n+s5H?hÎ¬‘Çå†4Êßjš´ª–ÂUä7ĞƒaT|±êİœÏg:F·éH§–eÊÂ:h[ë¶tˆ|;¯ Û†y–¤ÊtŸòvè3ºC“°ïé«é'Cíñq}MàÂ€QUÅğ5j©”åHk	)miS¦Íxä­ÛÁ[Á+ùFXi‚m.ÔkH“ô™høR<¯*«6î¢„æe|–·K
Ã"ƒïln¢	€üv­Ç¦×8ÿ±$Å§6 Øib“ìÏ…1èfï[|r”ä¯4ß„¢È ”«-F¿phvú5ŠH¥eŒ©pÆ°KM®5SzÔ¬buq&tîSQS£×ˆ÷~Pv Z*".v^iR·sêewÏoBP:óäÔP.S’ìFÜxíè<³•Ÿ3İ‰LlşxU±úMşÍƒÁÂ½&l.Z7Š&î…Or5Zô2S¬òÅát\
qõšVºU´‚óáñ?²ë^­¦Ú
v5VaKVË&3éw‚şH¨˜”âM¤˜qEëÀ²ûıêÑd 'P6;ç
hx#…GM®<_IŸ¢|ö îŞe´²)æ¢Èsş_úœÇ
Õj$éÔÔIFW§Ûû©˜åò^›µ/c;£$è.z~4Øºaà®HÖuDšUe¸êß÷ ×ú€Øœ ÜdW™\f8GÇ‚¦ÀÈéi5_$‹-öŒËV›KCõ¥íæ}€õ‚Æ¿ŸŞÔ)¨şİÓMó™“&Ÿ@
gƒÛu¬äâ² ‡ñ¡XaáLËù*Ş™Ş8äV§v<"õ¶VUˆÃ¼3á$õ<¦y0³ÆâScyµCœ¶¢íÖº çL‰—’8ğ®Q9ì n$ÑpÇ §ÁCzcØ>õpéÈˆTPj&ÓÏ·°Ë_{]©·OQ…ê]ìÁ”Möò`aÂÛ³½Éfˆ’Q¡Š7¿$òn(Ë°¹$bÓİ©ü…˜1‘Ë+	ëk<¤2)wÜYT¦ŠI¾ĞĞı}Z#uIØkL;	×02lºÇØe˜O¬nQ;§ò_Ü¾;¡e>LzW·5õC¢ îcoQô*ad)Š³‹Åu˜}°Ï“ì
z4…âñ&¢üE§)gÑ-¯”´ËÃ½?t4Ğ9›FÃ¨Ù†û­×u%ïŠYMXd+(«J¹Á^"£jRË¥¨/<£óû„"ç t‡…ñ:9Qëšu‰–Ç¡Qq[dÈçeyŸÃ°'Ö‚@
1d8bãñûTa72s	Z†w8ÄQZ0œò=Ãj ŠšJªÃN9¾áöO*ª$›ì™«ê
/=Ç¬;dÅÿ¯¶î˜9'¹¶İü¢â#Ù¼@Œ€—€À7~d¸ƒÅÈ,xA”t[ó÷†ˆÀQ A‚+›j©oşwUà~ËÁO¦#’­«éŞx’0ÄqC{ÄEªûZ~"2ëáSßpèú8ÈÅ¿¶ :÷OOËb:NokÂ:?o*@4èÃ>¼¶¢	ähÑ‹gB…(ÓWf¢ØáK*“ê#şx(O6ó´njeàŠ\éwVóN~´\§ãKu®,«ßovMFS¶'ëµµŞ‚Ş=óõi÷;8Šj`ÒŠ*³’5æızhayn³©Â½ôÆ|€ÛtrI%sü`k¯ÿŸ8ÕŸ^­=é$$YPş†_ly‡|ì`İı©~Ï¨,oÄûÉ·ÆÉw’ænAÍ ôí¤Ø°‰‰å…ù)¯z­y‹5_{}¸Nğ*Ø£#YF+ÛhÀŸ°K|¢@ÛôGO…ÚV³Ä„ÏYEóI`ìcÕ£×Ì9Ìƒ¹ÙÌê#¼i) äù†¢qÄçÒÚHJ££ôÈÜ­õ‚`Èøoz\†V¹È–ÄÜİÙ½+TQ™i}³™ákıi}öw3Üg—/Õ-)tè2D?ó¹í~„Ô‘Z î˜c;•C÷Áëm£ÙCÅİkı.Ÿ ÊŠêôUå-È™ãq6ç}ÕfÖ­Ê»·A’‘}Ü;=›š_7Ij²ãş,hÅÄXš¢ş9sWÖıÅØİkRV×b‚ÕŸ3Eøşú¬h­"ãõØº'}ˆú¥"8ŠäkÜ
	’ç¾›¹}“÷²µPÉÀø›^âÂ'ÂÃ3|`+e—¿®²åÀ-ÃÄ=MÓÜZÎ)ŸbÅüqæú‘ÙU•T+yö˜ö\¹‡¡ ˆ½¤ôŸbR‰ÌöÎYUç‘ä`tÖ4â¸N•¯ÿk¹¢È4K»YqÔ¹øÿùß‡Q6À]|¨o éªÕphã	àêhPzË›“îÀ¨½CFJªDÚ¢LQÉIŒÇ*'{=KİÚÖJÂ’è¡g#ğ*zõ$‚vù$°•qÂ”İÈ¹8 æéğWÄ!%&ş 3n¯wE0·Ójñè{ˆ  }°Z(ˆÏ#½Å6âaõämT±Œ“½ñH±5WÈüóñóovV‡œ•!}%t¼½Ö2×:¡á}¬y¦³‚Mµ2çËvåı|S¦5Kf|¦Ì¬ÁÅ×	2‰ZÄh«5ˆœ5
l½¿¦'…R=†€£xûùş¸Ê~›¶‹ì4ÖûYXÌT\”ÉZàq#§Ot°Œ¿ÿĞ®ü½Ìù¾	:•Xh|T,qõ»ì¼‚ÕÙ­¢<,æ”Ô:Ê1</ ¾N½ó9föh1ºQ¢qÆıé¬L¾ Õª¯Ü3ÅšmúÖß3WóËX•>?Ê(æH˜D(ß#W˜_êÜXd'%Âı¸³Çâ®xºYÏSÃjÆÀ0°ùÕµépÆ·Y µ˜=fÀ4[O°á¾väòµÅ¹@,kœ†Îİâ]NŒƒÕˆD ‘62=ûOÊ. ıÒ}ËÕ³%²cÉg-söŸRœ’´ÃNBˆ‚zÊŸN÷K(Y
Œ×¸‘x~,
lß»î-F‹/fV;ußøåÏ:¯µÚÃ…¥	f ÇËHLc«Ø¸¡“½õ&~øBL`· 'a Íù7àY)3AjCVõ<3J	“ˆêú·†ÛAIÙ7zÕsì5A˜+à(5pEjC{«à{×’Æñ]²wTrŠıäS¥†îvùª4´òB|6:¢³1½¦ }Ú>ƒĞ¡R((‹ó-x7ÉqNÖ¬Yê"DÚø¦WÃĞ’ï ©>IsÍßŞŠğfFwJwŞz³0€R[Õ§ 4Ñ‚èr<İ˜ï<ZÚYQK¢^cx¤°—Ãrãæ6W=*ù”„“Gb“Î,¯¥ÜœD`%ÉõíŠàü$18‰wZ'bqıµ®L^÷Å"¶°ès‚ïd	b€¦v™Ô1×Ù:™[j7x®RŒˆÌ~—5µªZˆàVoùA›Ã8îe
X›b|aOÆ»_—­¶9’ ƒ#Ş¾¸+Šs_’ÌETî³‹e8U³l’ (86Q;¿ú<Ü=2 şöéU„FŠÌ*Î¬§¥!ã½à´Á¼«}E|¤Ó[­¹‹‚í¶p.ùqO¥úü¹Væèw„²Ó6§¡óÃuE©Ñ¥jâÇw†~Á‰Õ°`vß‹@P‹/?MšÂ™Q—nİ;w¥/Ú2Œvºğl»at	Át—SìªdpQkxœZ`«2í6ºˆ$ ì R¸ÍR~Ëğîr·p…8É~Vï;èÊªh% ¦¬¨:¬°ßÂl)q«5¡^Iş×“¬D¬MÒ#úîĞ1[ÏåÒY¨ä¯Ş]„Ì%-È¥Cö‚“Wû§ î½¼GÊLı#h>šO‹álnoĞBPƒÿ®<÷ ÿÍœÈ¤ïVç3’oş	RZù rŠ è$ÏşY6§:"x5±†OÃÇpë›?ªVäñRŸªğ¬5eøV¤Õ¨´rœƒ›XÖUA]
ßtbå]=Œª/Ê‡•ÛêP—
ZY«Ô$Ó@çÖ²)—ñù‰¡)mX¢&#š›rl©å_KšPuÿ,ZŸ¹Æ¡ôzs6ã 5â3‡ñ´üãªæƒ¦8^é"²OäB{Q Ÿ	^5|t œ+#ÕºI‡ ~`Ò¥NÔÏÆuJå	3\‡	'òõÃè:AÿD‘bR¢$:°”úrê«äu4Ó¿ï</&åîèF¤æÑÃ½<ş>Û‚¡*T)ÆLLE¸ÇƒêÊDÖ&GŞ•^G@xí17&«üœL(§œI3v²Î¼4xsy?#Í†òÂ0ğWí,§1ÛVC©‹;v–|ÒMz§ïÊLkuŒĞ·Ü`™À„1‹«úº	% \j•*s¬+úoY»½÷z8pO~5šA]¿òQZ4…ºn¤Y;:´SäŠ4t[–Z&ª…dDÜ’"èåHÊ°¤³}Ubûƒ	Á[µûefw¦öó´ğ]=S×³òÉ1A}<‹<â¸–J1`²föSÎ¬2û5<ï-z‘Z¡)º€¥xÄä{«.´ªÛˆ.CŠşˆX6yÜ”™¦›Õ“%ÚŞ Ó0¼ÑÄU\x+pİiŠíşñqÒŒU–ÑÀŒdXuIÍ ¾˜_>% Ó¢™Ô'—õ³ò-ÈSnQ‹¢5h±ŠèY|zuÍVL$Ïß™}EÅvùãÂÌâ&…d_±we±ï’¢×@2Kİ˜ğI^†×ÕÊ\¹¥Z!¦7MQ5b&;ë(åí_x0]6¾Ê²8Æ“^åbVAÊ˜÷@÷–µ¾ÙĞæ°qáë’ÌA<‡xq$°]˜Êr³}Å²¢ZrZ(÷™†—+ü£O¤$EQ±(êíÁ'ù­´€V>GâÅÃ‹K:Køv¾–ÎúûA6/
?Õ÷vİ¡øáïŸ1´qÇÚ˜÷y‘xqˆ?[ãŞÎ_àã—Vã•¼ ­ÇÍü QÚ(fÙ1ãw¡]_ÅbŒô× ‰v³/¿Î`óÚVÆVáhú}t1oHÊ=NéjF£—¶`İ¸±±«RoÚÓôîSÄ/:–{yµ~½0
§İtù„ë€©8ld Ø^“jÅRÁ”Ÿ·qeÿÆÁ.×åŞ}~ÿkÔfbßûÿ%5Å¨tìŸ&2µÁP‡¹D~¬õ;§÷^8Íó2LÌªfBH‚¾7å7åSóE Nâms!GÑ«8„U°uEû.9?Üá»o÷”@ZŒ6méhˆíxÔºG,gŞé¸]¤5/¥ì9â`ñç´|Hğ,ñRklòø2:§bÒÃØu:
Õ8QÌòÕ41ENûl’SÏßˆ`WJö7nœ€İ™Ú³aß7µŒ÷éÍöÕ0ı®ĞÛ |Û§ıºÒD<I4 «*V–F‘m³f++R•€àã¢À YE<y˜†vÏÌöDìå@şŒÚN²|ï¸_Ó‹KIqù\OCvoÃ%p}:È¢­í3ª%h_>¶	0xˆ)S[ƒ~Úhúaúpª”E5~ûb<àÌã,Vêµ¶-bG‹w5™Z,½æmúfiQjº¹Üæ‡|-ºá”úè†WÅ	ªÏ•Ë‘)RùEaö?!†áFÎúú¸‚š¢`Cä™€å'…ıˆ$T‘Š1Û—°‹¹½¬-‘Í£FNŠpsó6"B(é(ü? ‡…ÀåÙÖşÒ· C=ËdİÕøågÔÈä‰[°ùÄOéÀ®¶Åqoò°n|ò‡üX$—i[†pŠŒû’5şõ¶¥¨¤«ãŞM»…äø"§¹°w<k“İ€¼.öû¡ãåÜÇ.N•¸†uußl¥J}„ÑÒùFİÚÍaAò€\Ş€©©!Ãl¿-ÎJ·Ê‘9ÀÉ"=}r,Êk)ø‘JX%„Ì£+=êñŞº£ÈÕG›’²x.õbktşW/*±«÷Ü7` õôÀ7FDÄ¡£&#¿úÚ¡&¹šKaöÅ.Caãb×áG…¸³‹U¤Şø ¨¹!&×Ğ9²šœ°«§ìğGšÈÎHgEëö|Õ%’ÄŒIñ~,ÛÙ¿¿Ëê»`ÿHˆ¥Õƒ“™oUZ;»¶sĞ½ıâÒâD—.G>”ëhÀ’Q¦rÚ¬c3XÆB[ú“ÂğĞ|V¼:¼yV*«b@¬V2ZõßZfG;c¿“Ê[ñş†­oq¡)r^¡©–šØM©°IÆ=€~l}Ù}dO‚_®¼Û²EÍöÂÂ{•nW¼säúOüw‘Rğ‘ªñ¡b3?¢Š*ò>‘)mÒÜXÒ
$S[¢;’çƒ2tj—2ÌZ»¯ŸX•CEË£ı­å@«ëêˆf7ˆ¨úÃ(ë¼¬RĞ…‹…F/DtYçÕ §@H•ÍZ…x’İÁÕÔ}tµN®Àù
#ø4|FåÊÿúÒ_~L‰v€³yù)‘†™O³¼lâ™ÆÁ|É"~ãÍÉii’ZjAÕÌıOxx2ĞôÀÌí×Ûa„fAõjÊ… ¾òXBÔ>ÑuXà  ­áÙ<µ¹c´)ŒÕjô›Î—•08_0§s|´~€oÿ=Á.Ò^aR»ë>GEcËW~àõgƒæ@CiA¡o.0Ÿ“—âú˜'—¥—®v@*yVú%yÈ'ğa%İ¯ŠÖÅH’İêI¡L‚£d^
è#6Îbø¶K
6'G81^R«ÿ%QğU­…¬ªi*ú/Ô‰$8¯Ÿ¡*Ù!jx=…CÜ˜C™Ü¾â¼âVÑE"x@Ôr¹š`±eLI¨gÙubë…š6›fìÓ¡Â;fíUÉ`Wğ¿‹„‡Ø«?TQµp"º÷…¾&\ãYÒ\©Û3}"L'ˆôPã©a5`ˆ[´}¹®‘+3Ïä£Ş:¨4
`©[&Ëş}¢Xgv»4SÍø„{-€ò¦(W½U³ÙĞíÿ&ø­ÕµÁrë²Gõ¼å.'Ÿ(æÿho£æXd–Ö-\øÊ|R;û”RùZQ¼ß¨Í] ×ø–ô]Æ`÷8Œ¬(à¿]&’6yùúğ—¹C‘ı	#“X$sDUø—n¢t0&¨}2^<äâO:kKr¢Åz"½q%¦¾O—ô| (+oXô~dÒky{âv¥9úêŠ;=£|5½Fa›jÒä‰TQk
“mrc¼Qejmä~K{$ó¿—L
Ã:ü·<£5†Œôš°/¨Fè‰­lUaƒùãämóğÃgob$ã®$â¢v‰dn°«…‘í!ï0]FjV¼Â6,+RêÙy*ßSƒ§~ó$úB¹z‹x¢„C­e8ä?§ª!Œ¯l(‘ü™¤İ=›ı¤?$Áé°§:€Cğâ$€0¶Æ5\hBô)!X˜ƒo’XDôæ´ÉŒ,î­^vy´ü|8‘)zzFx–'nu¾‡|êŒ¹cfX«ÿÕbFæŸİk€‚ŞäŸÒÍ;é9
–€ãf»J¾0"]Æ»"(3êpµ(¸èşA5Xîk|iÏĞ‰‘@Ú‹‚N°ÁÏe*Ü;Ô.,’ï ÇÀ1ìiµ/<-Ñ%ÿ	‹©·¥FÆ½éÏoÚdî¶“>KŸâş¥ CÆ÷Fâæc…’~ßºŸHãd¿ dD§x']ÂñGOø6…˜zÖ¬M$(ï‚à¦ëJŸ[#ŞãÃŠÇÍ¹“î{	úYİn0`qãøËoG!ä"ñãB#4JLÃMçWòäœ3|—·¶©m…wû¬ìD|È}GTŒ¤°¨~Œ6$9}eTÖ;ï;u¾ƒõÒzh1èà¨‚åÂr.œÇs4:MØÒTò×=e&‰¼ü<ÑA¡‚é¯‘Öa+˜–á2x:ÜÈÍÒ»©i®Hù(—™T÷£Ü-uA ÛU“ò5HH9KùlçĞ2V2²ÜÉŸ@$pµ
{7“å’JWõ»Z—ü'{ó•Zci²¼o.Q©eôÎkúUµVÓıOR3‘şó;¬ä¦NæƒöÛß¿F¼zfÚBß¬Æ³)&L°m2J•ó=ëL7(Åo×Ãr²fèŒZìäœ
O”LV"ÿÂ`ö;:WuˆrQí·Èô…sh…ªpœ	›:P¨M˜X:'ëµò•dyOgóÒ%~L<a/g:QZ—÷]¿IØ)ĞU
-ûXò¿£43ßkÃ~W-¡«;û¯9ıv0/-ïÿ7¥Îò¬~ëh/[aB]ôµ'x$Ë)·ŸK\+ğ;˜^ëe…wæ·l'a5ØM¶L¦A6l÷ 	nÏ+möšQ^°¬¤§ØÅní7ãŞ™˜ìÿÿ™^ÊÎ×‡|¨d¸NE:;6â+
lĞKêšÆn~¶nğĞ-S °_˜ÔÔâ¸aU¦Fz "Çz3Ö€VGğS`–‹4\À|¥
ó“Å¸öê¼‘çGğÂö*'«#_÷7ôØÿ/®{
Ñ“Yİùíu·œ¥0tËW*§’’S,NÒÊã—ë€D2ÏÅ u{Äñnšİ6~^ª+D ë4%Üòê0öî«NF×óÏ#£çPq@ª)Fİ‚ÒşI6eœ\ÿ–ef¯áNçØÒA¼ÅL\G&Sê¬Ÿ( sìÙ–fËã8ê›i>ˆHÇkeàš££ã¼C”‘…şÌí[I-yÚ•b:%ïÖtô‹S•è­èD*ù2üKˆ]eº¯g;õ±OHÎX·ƒ]^ê«.Öix\ÃÒ!fB>Ru'1¦• ]hD»{øLW5Æ¡~=-ö§L®’"ö>î…Àøéé°Pî7ˆ	L¯«{²k€@|ÈÙYºT#JTÜ0¢í¡ûI7ÎR–‹°Œ0;«ÉA˜ûÄ’«;0.C¥Œ.r}$n*ævÅõûS°âÖÍ™¸T†T`êœ[Á·éWäÑBà%2sø·]®öÛêî¦3ÂY—¨@®ø8ì'<Ê#Ğ BÒEh“ î˜¸¨K·–ù|Nò ú– wñ/éUXÖ¡ Ğµø«¹ÆÂjs"˜é-“€?LÉ§g1XóŠáGX¨îÄŞ‚Æw§˜·pKC™Ô,s.¼¥K¿z»ø|f@XFè5šXÊi•èn¤‰¬'ˆ¦bL¾™jq×lU]¨v-(@"ˆ~?v‚dvµVŞiG»"ë$ôLZ§M>Eª[ãÃrêĞ}Š²tEáE»'Še¦½`ˆzZ_VÇ;é	E:òNMYOâ¦Ò+Bq†ûW4ö¿·Û›úY°¥Ï69ÊbGPªÃ¾	åâa,b6ƒ˜ºŸşù´¯Šİoy@Ş”TĞ/ú4"ã£"PÇĞhZU7VT×&	á¥X*!`SŸU\2‡„ı¿Á–ñìtÜ<Åö|sQ™™<^Fÿ HëjÂ	›Ç•14G~Á¥Irlªï¦ĞÂĞdk wÇ_Ó6÷˜÷kçi"P^HHºÑ:'	#;€bª
*5úĞ"ÅƒÃ õ[*Eßà½£aJÉ‚6Ó¾&‡8˜—ØìE×[qY %Ş§åÑß™¶•½›¥DIH8³¨eã¾ ~M«hn:,˜­“¾ËWÛÄİpeK´8Y›*œ†z¡ì•§óW‹$æBCÚtn!±Ø<õk¶¾mÙ üàò-8ûUì¨zÒó›aj(Íõ4R¦àç^DA
÷#&¤øzûİéc¨ƒUVj²Öf4²<sBLî,çYxeV°b1Ûw]*LMUãÕ(ñ¦Lş~J'º–›ıİ€äÿ›R^ˆ&Æ?
èt	…2‘*p·òXé(MĞ7aG.UŠêBşrğjù‹f·Dt	gèükÍİ-•
O6â4ıèŞg€éšnjıHQaºèƒ´C	6”?uÆc½uß`öwé]çèø1S™ÅWG]ûÆ¹Æaı$Ç™xoÀèºŠuí0Zİ³ÅÑò?õøÏ§°l2¡O«äé0ZÊ?ÀìXC&ûDöüi…ÿV4ş”oI¼<ÌÒa'ºU^&©f Bx+{ÀÜøLËBB¯Ã_å?*¡Î¶£Ë=ññÌ21>ªš‹MëO"àù5h%«ÈËz5¨Îıí=W›ÿúxRà¹ÌyNódçğ=2òµ€hıpH`r—ûsCo£yš7éà<^;ê Mg/U¹]§UÍ_ñ’Âo“Wû0utp÷½Eu›·O„]…„Y²êøgN;Ş	oÀw¥~E5@®¶ô¬}¹gïI€öDz/)a^¤ê*L2’/ãÚøøÖëqëœ%…PÕßèˆò¨6ŠpµÿŒÉ/Iœ^›ê¤†^ÓÎ(aD{:ÎO[Ã€q«UßW¶0«ÎÂ§Ø—PçÎDÆåeş×6&öA4ô”Kò¨Ñîşõş)²24uÓ2°ĞŒÊÃ'KS67q$©­‚§
eyC§×‰¶AaO=ŸÌĞJ ñÑnBÖşå ÉJè/³È:…UxÆ\¾‚¢òµÅôòÍIŞÌÊËİMë³ã0ÿééGŒK¼…»Hì„Á©˜øBÕ…Xs#iw<ÄKğ[’†œ-Ép”YĞ  Ğ¢“øFz>+Ñ]ÕíŒµS¢–çF)D»W‡ê‘^HœºlSï8İ²:ç Ô‹ÆÓ@i¶t9Úc!å«¶hyw“‹QpÕË¹º#DÇ5ZYÂ@¸»F&IĞí%õÑî=DS‹Cö½¹Âd~Ã '=(¸/2Á…óóçWZÔUtÍ“=eKpGv…(Ÿ¯EõÎ·¡ì¹î·’°±>:,2èÔlß¤çnı:£Qc}OeZ-ø§«sşô8Z$QšDØvÙGÛ[Q‰‚"ÉáªÁ#èËgœ =E%¯W¬üËDÏißĞû¬§P%%TD1kª§&4>åp¢÷ıx,¤§´uLõ„pÇ¨?q¸˜ÿl—å{5(ÛOÉ°=³øºYê%%ı:h£jvKM¹«‘‹İÒ 0èûğcãˆ­"0yÅ#“úƒ	8ßxa”Ğâé"‹­6jn"˜qW0Ğ¬™Âª.k¶Œ‹I‹¸Í–vü%>¡>¾éŸŞ›2Yös½ò­®®{$¶S½Ô–¸«ôÁî÷5Å,Š‡ı…;íª÷WãU,ºŸälx€ïÅå”b7¯”©Şäx¦ŒûºêĞ á	©Á­Ò)ã¡C+É/ØX›m¹’ÛØ³>åajÕ¼2ã–Ú¢G¤Æ£}v.@ÛæS 	xß¼R‹>æZàŞßl×,¢HğS›cXæMÒqÔZQÅñ¬+é³6èœšõ0	BÛ‹İzñ_½Ş)FWØ@dD±•lêM½·Ç¾|ÏöŒºûö™äÅûlÌqÚ «b×Èt*ôË¥Â‘¨øK«aë¤ËA*ì››!€ÔúaÊ·ªæU	Òö­šgéÙ8JÔ¨!/¦'¯u†á:émßÿ¸^èĞQVVC~/¡'ú.:Ê˜»hË¨
ŞXšø8¢f¥«X`2=•‘Íj¥L•{º#ú#÷›^zš’ëÕIŞ¤M­ß‰mc•Ô¸ƒW¶:XVßV¶´gøinâŞSª 4/mŒ¢¤2TSË#÷`dlúdD<K¾<#©‰¤¿Lâ{Û&Şn/€’á
1ğ,*.ã·E}ÎSú’r }F'Ü£9	ğ[ßjNÛìr³x2*Â„*AX¬ŒO†æ#D”ƒLìãr Ú½Ù úI\s]ú;#§>`‡€Àß3†Û2ŸKgV) pk¿«Ói€ÅÏåÔzV¤¾ò¡a—£™F˜©‰ùâ;Æ§OÀh©/JZãSDiK¬ÎïqñzÈÊéb¦W¹6~ú#¢Å7 ªAaJ¼«Úk„=s^x˜ˆûê–çÒS¿‡©,7FwewGà]i@sOad. 7¸³Šp¾l±$D^T.ê	c¨iÅfe–n‚ĞÁé]†Úş.?¶‘.pTøèŞÍšJ’?#æG´ôo}Eºà !íÁêòÔLY#„‡³¢‚ïÂ¦-OTİx*‘Nª¶ï%ñPûùJs©®sF¬L3Yˆ…×è¢·„i©’êLWT×8Ñ™ısßz,oüd‚|@©¢DÚoRÛŒ»1ñåÄ•/äêÿŸINíG²:]VÕÃÿòU>c.ÀÓr›®|ñìKÄiFÉğùrÕˆ’	Vşb_ëÖ_íãäÙGš8([=²•¶ªÁáµÍI)¾±èø„ŸÕ\Š"–…›Æ\Th×) Ö‚¡×÷@š%T°M‰Ó°ÈÊEÍ7å=Í™zíCğu.cXÿ§üÛ„½»1LÈˆ÷Ÿ
ê,ä«¢Cè‹gÁèe¿^,–CY“¶Ì®'Å®Qõ
 éİ›”nA¤Œ¥bhJ³+l¢8A7¡<SàÎÍ½ó¶[—VPÖÂ48:'¼‰¥§KƒÜ©—9·×”_ì¾geºä¤Knuìy‹Å!“£D9±1jÄÄ©Æ	"ş„ıEyŒQ‹îºœ&Mùog\Óö«é&)ÃÆ@>=4¸Üñ+‡
 ;ä®8|j¸	±EÖq+O­Í©2ÔSd{ÎåäbDMfsFxÎÈº\–úÒ¯?";"ç{
£¾Át-¾©£¯Êû¬–¹^ŒgkØë“;@5ìG^"6L?-B˜ZØ½ÿ,|Ãç¢š8üó±…¶õJtÅj¬€’¾ Ü·k "vC0OqôzÍh»ìòJÛèÆQk¯£İ1†‘µz`Í» ÓÔ›•Š·ôÍ4ûòé9mIá+{^rà\Òçï€˜!o³û„ûQÊÎœ~(è?/4¦Aûf¾gÜá¯mª.Ş”övæ­`š¼ Ú'ôN<ËfqP£ÖÚò”ì;1o.9\Üó¡²Ñ–(Û¨áÃf%/Æ”„C £	z¶úkü·[Z~1šÿææŸ`ivBBı†mÖªî,	kºØhµäúI'GâK^Ëº©:¹âŞ‰-Å^ A$8”Ü-˜º'ôò~y”ÏÅ·ĞÇ¤¸ME˜B™‚$ÑÉl$vTN„ñ}úXÑ‡1J!ƒ·åõƒ›K:œ	œ
”wÇ“\+>o)ƒ}gkêêõ•'^a.¡/hcO)¹ÄÏğ“‰~n×o{	XİwÍ«íe¹¡>$ÙÊD—ı,°Í¾¿‹t†&Æ7¨Íğÿ6±á•©”‚¿ÛfßÉìÉÒÕœôƒïÖÙ^ï"Ğ—`¹Ğ™;	ü|à¥Şƒ®ÍÑÈ”¦úÆ z>åqğ–ÖÈüÅ¸u±¬‘Oê
²‹v[Dƒ³y%ïŒ¬ ¡ÌLÉ°şÕßÒò@lÊ ¿{ÁA%ºWósoe9ªÆ¿ ½ºÛ/¥sbÁtº5µŸ¥¦2ó×ÉY·%jBœëNbUTK^èØëÒ5:}2‚ìˆÂQ–Eèsa»+³Õ®	,™zêÙÎõã>
ÿ¦¡]Um¯É˜˜Ì­ÓÙëz¤¬³Ö}¨›¶³SŞÒäóL‡ĞNÍcM¿$îúhº_¸/“-À&Ø hFÿK#åZ»­Ïı-÷!¨¡üŞŞ"ksÄ}ğßh—*„£ Ë‡İ:"‡ÄJ-\±…ŸñT‹Z'¬ˆ’8*İ³í4²’5è€€Æ1Ä8^@ë[“_±mø²Êß`z FÆ€CÓ«¯Gv¨….?`3Aç\Ø	Ì/^ê“ÉÇËP•JŞª³ÔèAÍzMMpæ~”ı˜c&š™ÚãRÀÿ&s#¼°:C<+©l*kZ[ÙC`¢+ÉWşş3ç®¹o„ıÇ‡T50}9‘[„Hô¥‚£RÛI|P•Ü¶äÕºfÛcyD‘ÄÍví™‚|ß‚Ñş
ë6ba‚ï‹ÕÒ¾g½öÛ\0¼wc£ Û˜å!?Kâ†úw–ô¶¯6ºÃä
küDœl°ÔO]y
˜C+—Œr… Ì0}ú°Ë»
ë±H[U¬<ñŸ£Ãº¸Ğ„ïağ¶ñßŒs8QÃ8¤/göˆ=Áï`=ø¼eë}c’?˜±‡«ŠV™Gn™›uÂvBW\§(™ØÀ¨/"·¡£‘ÌÊc$K¹ïÚ¥MÙ8Á²ä°È~9+ï½‹N-ÒyÄw` SC»ÙÌÃ„UıÅÎ(W)Ğm¤‡eàAØ]ï5ÂÍs±má §;K„=Ó«ûÎ-çgJFÔ×šügé°•xlqß)ÆXÈÈ0fBÎ„ßY‹âmIÓºmdÊp@‰YŒz3Àl³ú/Äò¹ˆ¯ğ"âÁmB@0{±‰ÑÒ;w-[¢y[O7Ü<5\ñã™½ÿ ÇÛ&7¿¡ö,\Ø½nöï‚OÏeÓlŸ^`–
dÈšHk,C½†,İp©5ºtè;}:è¯z…úòì ¥päèKßİ•GĞ®ëcµ0+Ã†bûĞs€<3Ô}¡ şiO.Åí¡@iHÖd|`änlº4MSY¢Ì(‹¼8¯¨ŒãÃá7KÁŒÁŒk¥Ğu7ı™‰²Ìa3I´)ĞÈÂÇævÀìI™0béwU»QP’e6ÓA¤Ê›DgÌr¶i8ñæÊEF7˜ŸçĞƒé"üÁo›‘Í hÒT“Š,Ñ€ìº°ôSk æMXÇ/¨I‡ßTãºªº8¢ğëuP®nàïlxR'ñÊ£½ì\^^¨ õ2èB”£úš‚š2ƒÑÿğg¯fñ6ÁÈi$KU3àì°\ôïT©{ÆCáæ—ÿC‡kZ0Êİ.g²Ìƒ%q´u~½EñoUÌşò_ªüıY'®i éèj•Ï…>4Á`‡ÀP~†õ`[¦ÀºF‘=˜İ&ı`•‘´•ûF÷‡’œ!¥S€”O«óÛˆüL8ÄÅ·<qsìmb½EÉˆwŞˆ'‚75ğş[¥*ï³1œ şÜlÚ¢Øe;‹Ïüçü©5æUo3™ÄL5¾’ÏCú<œI3˜¨Õuï°{„+~¯Ó
Êû.¼3ÒébW8"ášÎ¯gŸ5Ôö‡rúÎXgÙŒx'¤ÁR±ğ¾ÜJP$¥±&‰Œşi²]ü‡‚
vY´¶†ŞªÁ&¯¿uµâ¸Vğ«Š©Ø	3M<I#Ö‘üó¯S–:V‚¨Mq:ÈÊ½ÿ¶5‘ uX¶VÃ¸Ó‚ã%O{Ã(iåÂ‘ñ¹
Zå#ÒÎ\kÿ(ªËà‡ÜÙbÃx÷
ekİ€À‰ ê#˜k]lisf¤”§îéûãô”Êguó¦ÕY2?×4†{¶V¢ó}TKqHû>‰;¶©ì•^§>ë,eÄpÂö"g˜ºî3‘Iá@*Âujs^[àHÃQ3Z˜$	~ÅÔ¶ì ó¸'ü—M´…8ÂÑ¯Œ÷¸êÙäbî M+¿õ€‘ü—iı÷]£2S…¨î–ºZË•Ó¸©ÀbˆóÄ[›£ÜûË(!êárdB´!z¾.éEŒû•LjëN[EbK<«E÷5â£?"†E }äl	x2Gü_Uö#Áë6&E#oe¨'©„•	,	pnG²"Utì8KL³…l8Û]º@uÄq­_Êƒ¾Á³]ÍÏX¨:Èùû½œqó×¨é¢™gÛô}ÉáE²ê’…2Ÿ™ó¡™vlã`oT~ÏîÇåßI:Ÿ­ÜCJsøc_nó£/i™"‹¬l³9¤
ç—HEÖÇ¶]lñ,‚÷™ wLíT´)6ÖÑÔà}`»%:=VÛÚÇh,™ÖŠ·Ù—’(ÑYI+”@a†jz’}Dt:ND§d7 µj·Í-Ö:5¦&kçFšk©—¶¤X»húA¿ÙÙ†>Ù™ûÓJŸß;Õ ,¹u{æ#”kNÒŞ2…àÊş¨›Àëÿ5^zÒpµ »
×ÿ&×íÍZ‰œ&NÏÕŠ£Ìÿ˜+E×Å?O~.a\èÑQdïİRª`((LÆe–ı¸Ç°wRq®ñ?§Óã¾dÀkµSRÑlömf:û4Ş`4tÂãv”ºç¯Ã£‹»U\ïÈ/JqSšù5‡ZÙFDFÜ[aiÔ ”¶9»WY#­»šk„NcÜ=kJA×AZn>}!ªPèï,YFƒÍwN‚²‘Ü[¼¬y\‡û«£PAÒ¯Söì¼­îûõ4-FGlşğFÍ§G½Gö]Ì<ad<4>®´åü `w|^.rf-s>yÕQ ÕNÂ'µÃÓ™¬ÛØ‰‡	}'ò:w~ûêğ›Xˆ),_p’Q8uØJé"e#'à8üµ²éHÈ¶—¢âÁÅaé@NÓ²	à]“(Zt@!x‹‹,åkÎ”'R*{ï'H¹*Î5Ü’¬È2Öî[ãlµCLûk,ïÍA*ùÚÚz5÷å¸3[õ¤2mªtSÑ=QA'ŒÔÖ{’y*|]äˆïw}ÓmøŒ,vaû›º¦(ŠèõÉ şr™×h#qkÀ¶±m…`R¶Ù¹©Ğ#P†ç%c’¤}Ñ†¦q+,ÖerSó}U‰b
£aå6 oU=Ñu‘¼³õ„fS(€Wäv¸jæqáøøRš}ö÷õJÎÀN[R­è&cY#$åÌ¨7¼ª~9‘“¦nKªbH`­7ÎûDlk¼‚§»CíY!Ë(‹ŞRÍãbi“ú.´™ 8R²¼)İìØâçßEJHĞü¡‹ÉÒiØIF%¨Í¶@~0Äÿƒ–aá@ñws›xµlƒ<TO`“F®N÷S"ı5,Ø8ª
—lÉ2ÉéÆ+c­fñ?º½ÎcS(›œ¡…srıĞÕI`½Ù³ŸæñpYŞ×‚ğ³Jì,Xë[Õ‚òiëØé5bGY·ôM'‰‡ÆhFÙá(ß‡O4ùG¢^ûŸ±¥`¸€.d(ù	È9Ço ¿eUÖÇ;}1D„6³§§êÀÙèÓ1“¡éAêë°jbìÄ:'3è9~>—„?µÖ0A à˜ÛÒD	¹²áäICÌÓ§v$dlÀwş»ö1–gJn;r­İVSœC†»£Ng°ÄuP+òÀÛ-2AiÙ¼h&lÔ½q»}™¦Jçè5Våg„Gã(© ²Á°¹EÎÆšİ¤îŞáüÅ5-¿[Çª¨+¬T%­"ó
XÕe“­™Îİ·wóy\äj“çÎŞRÊrEˆŒı*2(ÎNCg CL¶
6+î3/Øm66ÌƒuÊËº*ciúãVí:ÊªPŸ¨ú$Áì”Ó³Ñê¤m³DÜÈ;Zµ°9Úk¸@¶jõ/GëÒF–K,íÁì¤QÌÕ$x‰&Ø‰°jK%p’şàÛ‚€U»Ak#û¬lh—¤zÈTº>.Tš»p`Íç(‹]k‹2XÆw×/·şF_;O‡wÎe'F¹x'¬GdÙÑı;i}Fİ£6Y»»-e2[Øút D9¢GW¯jòå[P¼Àn%Ó'P;NÉRµÜÀ_À¡K©{,q¯i:¹s0·
/‡:éy—2ù¸Ñü8%G<#a]ªÆõ(rqAqÓ|äÊ˜××Ât{0ÏıâÆ%ÎmÊ½ürìt<İÜ›.”øU
£¶ÿYÂ²Š›lÈOÊÖşaäcáŠjN‹½ßë½Ğ™ô;?‚ş¡;êÙh—t˜è³¦¡9cà=-Á§7ÑLÊŞë€(#ÔPZóg!ã–&ñf0–×ƒéšãÊ¹èWÍ‚{ƒ<AİÀ1 gç·ØCŸóDQ«1±µ¯ú¨òS•:ï
7Á|ÕJO9ú/Su½ ÖYÈÚH%# yïGÌOÔ9@Ë§Øâ0RØÏUßÏåg&ñ³ÚúA´øİz/%Şíü_ø5ÙÌ¼nòDÔo»×tÇ?E»DÒ/d˜!–ï_e¸¥]¦[ıôj§£–Ï…¶ag³D½Lê–UÃÛ^ÑúÁEhjcé±“TDûıc:)Mµ®7Wkœ;]bNIfL[}sR¤sF hå’ı¡0[Ğ»‹€šq!–VÛ;4gûâZ|Âh4z™nÇ79ŒÂ°ñKú@{J»š=ãgØ2dØmo9ş•âµ2áÍ:|áÓÑÌmÑcva¥¦¯]9ú¬w5£Ù­‡d¼¥­ĞÍËVÅ9İ¢,KUxfâth·JCoÓÛÎãhı‰Ô®÷‰(m5#b`uc©,*˜‹ÙÇ‡zşÆ›Ò˜µšã±b	Â{P£jeÈ0]	¬ m•ÈO,ÒÃ€üR¤¯G€bx.¿o=.–`:ÿY™,0 Ò¥ }¸ĞÒµà€dR€,KÚ:¯#H—Y=ÂjÈz£{¤mT¶Wƒ=‰îßËïâgrqq¢aCıÀJÀyâlêYÂùgMˆ
á$HU?¨VäQP$à!ÑVgQÌifáDú¬‰†PgjU:‹²íF
e| åy¼¹˜„-­†WÔŸ[ä¹°$\Ò§BÎØÌ·æH àı˜Nºe“€[*°+ÅŸùRäs¦F‰tÙBIÉ]’rS†t6÷°@éãúÍ<LŞ˜A¨(©ÑİÙ5şx…<á_rM° 1š!ÂÈ§©§_ÉpzçˆÌ­©´Lè,pÅ?†éÙÇvh$ÚÉ>†ùıŸ=vpÅ`ˆæ”nìyıâÃ3ˆí“Eq_Luıµ
'Œ*‡ò¨àß‹!µ›­ß8u!A<2ıÁçÂÁ`Ó\¡hl»yT|Ñ¨M³\¾š~-ãœ8ıº×q¶¨ÛGÍ¯ [Äytn]±œÅ{½•¨×ŠÛ|Œ}Ov0N–/\zîê‚§õ³Ky´{ÚlÀ#™q–QÎÛ'§b¼ü1 ¸^¸òÉÂƒ¾XŠÎO/ÁÔß%—(+ß_‡¬WY.—ù­Q(àZÚVüßhÆ5+©£Û'±BXlA°ßÑB-æ¸âAf6³î'yJmÓÅÅ;dŒ#w×Úlö®ÜÕòÏèb†=I“ şLSh½©lÿÁŒH¦6p:kbÎ¶™"=ÌûYÛ¼`ó®ráv˜Á¸_ş§¶¤˜AÇÌûöˆ¯Û`]ëãß/£™ ™Ë%6­ïiS?$B’¿ˆ:>Ÿİ^áEr´Ÿ¼™¢ÑKZ%Ô
Øô%´Ûê"æŞ@ï-uYYFSd›Ü`WoÙ'Àoh›Ï6ˆi½‘ıÇÓòê9Zp°i–ì/êú¥ôÓî‡ÇÁrÀxÒO‡RâY¶áZ'”Ç÷É~ø2ƒy‡
Úˆ,ê‘2,Õ"F4ö¢dÉ^m32k3ä«x‹m¦u»´&ZÔĞ—·x /777ëöi~ğ¼ûÄ…¥KÏ9ôU7ëïJÏdĞ¥MkSm™mƒµ›a"-=œw@v/yHşú‚GN‰õyòXPÜx‹tæ8bÑ3T¤(¤-:É9œÚ0Ş-Jë‰œëCDJd¬¨øÈoĞSP+‚½ÖßZÎëqŠĞ©Şv‰sµˆ$f'Å ğÎ~§?Âƒa¶‡<cÊáOšQÅéÿÊ=£%ÍÀW®6Æı¤Ó[Nã+èåeOkâšÁ;W´ÏÍÃqÂÚİ•Ìu‚Fµ¤©ï¦š1ò=jo«ŒÍ><‚É3&¸˜^¤¤I0&é¡ iÏ¨Êìª%‹ÊXƒº:òû÷Ã½Ü/Šç²(“p•‘µViQzI†œ –°Î”‡ïTúÈÖW³Bk¥uånõĞuÜ.ıi‚+ ª` «£q¿Ùô­ú¹py‘M²µÂTB¡Š…0]S…ôFqŠà]ÔX·,e_eùÿ“|aù'¾ÆÅº-É"¬]°ˆfrÛïëj`páe³½z¦àó¿èwñ	Ê±9 ?˜¾—q—8½½µy&ú/S!¯X Àğ[%„İˆ’Éâ¨ğFW«ÏßÂ¹ˆÆß§Œµÿ¦oüñÙ!R%1©,ig³‚/wÀÚQ]</b!7F¯|ÏÓ[j˜kÖ§ÚòÊå2C°…¢Îû¥¢¬×eõ½Ä­œ?ÆHÅéœ²ª2²HOƒi©'ïoUgÈtŸvBš–ĞŠ)±ù,•J±õ­s:,	…mX0ÔZ>prs6u¶Æ ½2Ò¿bpåéù|¦y7Ñ9Cîñ¨ììŒ¾¦2ûÙ¥PLu²Î4Ñ‰üÃ–ë»ò#¿vB9üGSº¹;£P¬N­É ÂÚºkqAsf½¾bjwP©™mËqÄó¾MÆ¤ªÑc"dàZ=ÏX‰R\±…¥I½5f/>êşşN u9Ù}Å=ñ@„‰'ÿ¶ŸôMŸ£8€¥‰ìûx =Á[ó%èåÒ3‹*Ÿû¬rVìı¸E B/ÁÖËDø-§Ä‚ÛÇ ‡CjNSYŒl£sôï¿šm‚6«ÕàúF¾áqFË}5Ôj#YS/¶\º¥½gî!gVPÙòMáå@:ìvšÉy®¾Í~öiêh¤Â9 $e#ş@hÔ’(¨‚µài¨^şï¸z1†X‘4ŠP©-å}G"(ÂP®2Gè;4şxÃ±o¢ûåØÆn/İ¾tÍ!ğ›é£›ü˜ş~êæW·>¼OäÜm>dXç	{ú•LÈí¹€éø6üµ¯V¨²…Ôg}	|ƒ ×ÆEÆu/c»¯œ•ŸrœÁ¼½¿w~¨TsÔò×[?Äy†õÈ—ïœí;,È‹cøÖÕšk“;|ëÖ±”iÔ)~å‡a…)…iY%ÖDlçm iÅ€‚±uÒäÅïƒé­.#:ª)%¶–»ÿãvÎ{¯JC}®ÁæÕºïâl†÷Äõà¶Ö  {{ğÎÆ³ı|¸°\7%¤@ÔıÆ‰Ô±ŠìÅ|>)$Üû4nÍó¯nQ¼Ìh+£9ı=¾üÜq¦kQã4{:sAßkÁA˜¥â›§òÔ88–†T˜²Ÿ<în‰ù{7E½u˜}GÃ¤Ì@fíÿ{Ù@|~QPœ/çÃ¦òÇY¯ğ+U±ø«Núu3¬¯î]¯«d”¡iåìÅg¶ÓD5Ó‘ßB8ìOÌş=şé¯|+‚r¡ä› ãI¯¨‡ˆgäªÈzó¹,†¹Ç@*:¸Z¤ÌwúœJú®F4Ğb«"„+p(„;G§èDEÑ—£btdiƒ#ÉAJ½&å?ü±Wf-y‹¾-oÌpï²T×0Zø‡*#ÜT¤vë+:*NVd…ã”odXXWn1/Üßz„tçx¦’ªÀo¿˜ô«¡†Ş0:Ô¹Uğ4í¶^on\¦áÑ¯`ñœ|^2?Ÿ„¢¾Iğóÿ< küÖ-ìÁß?Ğ—„o
9Qºõa­OUOµ@êİÇ)†Ù],O#Ï^ñgNDÚšCG
g>À$Ûğdñ´Atq¡ë0^6ïõ&Ä‰¯½°ôªcÉò/´:U64œAƒé<œ<Ÿ¼·¡ø|ÒšĞdj-n ‹ii')µª<AaSĞ(u\¡ù"R¿×R¹«=S€‹qİı/İ2”¿Gk-¿ç+¯Jq±‰÷à•8Ó%zíât¥‘Oxr^#,œÂø7îÀî*™*é4Ñ!RĞ)=¸äaÎNNj$ç·˜êò÷Jë©ÈNoÄÕ·ò“zu6Ñ9–Ø@~U’²%/Ş€h;¨µm‘ÚMñGÕZ¥–=÷Bİoùâæ¸B]aGBNÿİ.¡
w× _yğÕt1vŠ)àèha[EIOáÕ†o`•?œ:"2%[¹áO¥›Û¤eš¿7%ØÏútˆT­İ×pË²¦nãP·jíI4"ï“±!Ç={“~ÕLğkáˆŸdËïì›^”¯·àó\B–ì£ ¦
@oCĞuH›ÈË•sP“ÓªÑø¼ïö¬Ü¾ ëGÎ´J‚]_D9OÈé%¬”¨½‹¼M|Ç)T,&ÌÛa¦P‹bU<áıA[Åà:¯Ÿ‚âô&xTğP_µÏæ-\–ç'ĞÁ…a,ÒÇ:Ê „]?üÏ|%šdH‚Ğ°+†Ùò‹8A®”ÄïD¢oNœdíÛècñ‘JÂúkEwsÑí]Ô1”CÌnv_ ÃY¯È¿¸‘JóêN·âF(—©HbûÃ»rúòÍf¿:£öúl”¼„ÍÜœŒ°ë]}>ÏÆÚUÈÍé*óBŒÖgûÅK)`^v®@?Ñ|SØRÉşËˆ±¿¥`É“sª™[/€p˜oÖåÜ•D  ßçõQ[]]"¸˜®V‡æsßœç+· P%¯uÄ`¨?üŒş\Úae»LhÍ,6êmhr†2f¢}-®¦‚T5­q#€g­I,¬Ô7Qª24,3nßr‹G6”é@Jüç5¢tÑ8sıÑsîÛöàÄ]cC:™Z‹K-~ÿ½</,ÊÍQÉn„Po‘õİƒhÆ_-—Th—cµÓ£EæÉ„TÔÅ’N×‚„ÓÒ&Lbö7…§ü„ìUíYD;ı¯¾Z
è4ú²ŒnB!Ä,öC=K×ñ"j¤W»™w©qH%Ğ°å·Y¥ho-Êíß€Úá³°õÏµMÎ.Ì]Gèù`Ñ¹6§È}¦˜Ò^Zä_ÇŸR†¦L¤êÚQ×<p!XõÎoœW£8frŞ5vØÏĞuìÑ‚g]~,3uahéI ‹ÂÅJzÑ{ E«,öQhF~à–ÉaWfFÂŒ5À8»ş×š,ãİqÁÍ,6.°y·¯É¦ê&na6ğl˜NàG_ü§œ rşj„q2Pg…˜QøÜ¬=‘báÓ%º‹u¢¯1Õó©‘y%]¥ò¢ ]'ÔÉÇ†Yp-QŞ]ú3ÈÚÒ
n½7TÛe?i£ëò»›IS  ‹Gñª]MÕŠ@Â¹R©EëzĞoEE\Y,½âİ™šq©K®
o¹ÚÉ¥GV`²{”{”úNPbğ8@Jº*¨BIå3ÒÔ™ASµ,Í›Mä’Ü_ıŒPPu$@ÒJ]ÉYYxìV!]ïÿ<±Wiºnİ:‚œ‹´ßBQ¿ÿ6×tx•äà§¨ ò¯é‘±ugG­Õş„(Âñ'Uƒ†…“i^«ó€Âuå2úmsk¡{§ğ³3¬»çğ#b¶NÓ,ceòò÷­ŸòE¦‰Êjµ®F¸õãaş#ÓVùFİCX•4hÙ?ùÇÁS«Ûby[ö.ÍØÁ\ºmÊ,+çŠÚ"ÒƒÉ5Î|º“~®:xÔQe\Ò+ÙÚ?9´ªªå·&hy–|„‹1ş¾`A3Ìß¾8ùé!i€Ì-Îâv]¤æs÷–²	Ï8uŞq ¯\£Âƒ/¿  {i8S^£<#r`î×Şé†çã‡½LÓ7‡'kŠtfÖ™”—«ì½šCFtæ˜Î!OZõÂ û(ÂWù_´ÊIåÌÈÕÍN¡FÛ2h%ç×!ae,9Ïµ=ñ^Í0ßû½SNöéWZ<­êkø„•ÅĞ›ı‘dæòZK„¾O£¯ìÑo—GücŞí °\¾\PËe‰h[d(ƒîkØˆ‡×ø‘öĞ¿‹¶-Cï!ÄÏÔŸ^	·Ğz’ÍÙlïÅ|ûG¯si <{yBF|Õ Î:7ÛğdˆƒzØ©SüdîmL4à€‚ú¹zB¡©ÄWÂ9úpUú8¬jÄrFMã(X430ïŒ:‹l¡¢D£v.ÒÈç"5ÚÕOe`BZgªã[BË*Ë\ò”óÒ‘1.·£¬Ü	YóBÌ< ^ö–fÕ¤¡øPZ ãüĞ6:‚gßÅïQG—óåÉ#oò‹¿JĞÆ,KÏËfÖ¿ehròf“$ÖìxîvËI§ÜÛ?ÿéÿïL½ş.T+}r¦Uzğ?È{ï–’*'İa#L·ıŠ,#´è«›¡Û˜H*½ÿdú‹p¦dRú4§ù=FD*ï„6OÜï=ÿëƒRøÒî€#ºu]”Ú7:GUÅi‘¤Jîºp	K°ÏôÊ¥íè   š‹-‘Eáÿ ò·€ÀÃ†ÿ5±Ägû    YZ