#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="174917226"
MD5="64acfe7bb2cb18a06d612723f85f69c3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20820"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Wed Mar 11 14:05:29 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿQ] ¼}•ÀJFœÄÿ.»á_j©×úëëçÜ«‡Î­‹Çù–Ò¹*¤ŠG§Xè¯8›ÎôØ´ô†Ğ¹f*Ä7wgbúšZã}Nk~ÎÑ¾LNä!Ù'ğ!24Ãó…MÂ×ô@y»%¬K‰Síş¨oP@xÿÍk”ÚöaÊ¨Ï|ŒÕp-Êh
ÃOŒ*Šq¯­¡E˜ù/bãWGíi^ë„'ä„òa˜±ÌÑ•pQùAd–%cWF]3àóıèŒÑõQ#Ö–»÷/!Uún‚¹÷Ê–5áe"Ò¾ÚãMô¤Ô3¹6d=	 n„:Kt~‚½¼AC$+ç7
`
Ôv¢ÁdïnßuHí²õÜ?\s>hoR•°l2‡4q«QÄ“iƒ$[0lx†ì•A2ÃÁ(¦™¹Î›¦Š]šÈÄF·-ÌĞkpÄÇß¼²-pp¸Ü†MäÑkŒÑ-ú·÷M$È1·û™ğœoh;îÚ›v­ªûš§‘Ì¢p\í]‡7o?ÔÁYùDqCø L¶FnK«S&¢y J@Ä²`÷_Ğk±jªIT:Í
íñ9ÿIÑÄpîP·Î’I»ä¸xÕ¡øêÙÏÆ ñIF#~fÔãÒÃ-¹	HLÑ5hŸ$Ğä"Ÿƒ…QÍ%¡?ûk¸È®bãKå3šT@1ì[Îìıµ¤¯¬2…H<;èzÍ)‰Û©îŠˆõCü{(÷+P®fƒ&ŞUÎ8 ’è¡Ä\µh­ÆöôQo›ú–.OëX “µ+¼3Ÿı,–¤O¦,éÒy‰ï‚Ş Q¾-UH…ÀgZo•ñ“L%Èì÷€ÜµÙ¸Ygz`]µs‚‘Ü1Òaë€X1Ùv4M‹97³ §˜*¨]Ø­dßÉöh®}¨ ]—f×?ÀÕ~ Ø?#A4_^6O‡m%sN»ª9éyéå›½/3Á`û…ßˆ\.Z’×5‚•Eà”—+Ô8Ü-¬Ä‹•–‡<tá[w‡¹Á4¨@‹ôN´«­—ünlú.§á½%DtVÍLá–‘ËVævâßÏ2’]ä>.«1³Üºç·	ÿ²¹âçYCW1‘öd°È0náã¸5šN†åëèu¹^ORóœÊá{úuvpóX›=÷z+}Ö
—ÑòÆ¥ªüïÂ–Üpnøx|µ€bGy"ÔÙìi%O»Ô÷ª‡ÈKLo{°²ÚCs½ô­w3ÆK#¤)vÒ-jtJš¹ÿµõÉJwêíMÄ.²{4Ä2u«… 8'K¡ÿ
Í»±ŸS°æğÈŠÙå+ßÇæ–,5Ç_—/~B1ÕâF-7hO®[vÜ7öI):zÚïsÄB`òºL›úû‰=à6q2İ_Ä¬ğkù{ªXÖ@Êû+ñ¸îbÃÛª•ÈñŞì_ò0—Û€¸>h‘rÂ…´£
B8;ãìxUAÉ!~–+ßÒRùÉ¨³0&íÑa"/ùñ¨mzîÁ´6}âÈŞaóQ•W­1¿o+÷ïùóE½ŒO&.Şé„s~Lâÿã¥ğiNâoUV¨¿¸xx$Ú7c8ø=© 2ÕÄxŸ0‡ƒƒp:ôé%X(q<q6±@¢(Ş‹ËnööëÕVAÇ¢Ò=(\^ıëJÉƒ‹©o°&ÅÉÙvãâ”Š—¢0ş’˜I—:›ŠÒ4TZv,²İ;î‰ã`±DgJ…ä1ªŞ-ñ™Lßÿ(S×§a»P/¬Ì>BÒçÍ†ËºÂ)…ôÊü3KXãKhAã˜3áïBœ ½íE”ğ™<®.r+Ê0nÜƒ²ç®àÔ‰Àr?vğ·Àz‘A ÂšS>ŸÑªØX4x~o‚Z6Ô,=L(X*ezsr“¾&16/.¥Œ&×hºàD}­=¶<RÓäõ¤«U>™M4êšª·shÄRp²wTÆ#œ{ßP³MiÕüÛû›3lƒ•Z·éQvY-¥çûx¡šùİ»ßµq·	•µG8ñ½¤!íì4ú¢PŠ«Í=×>¤7ó éÅ  VÏu"u€5…M×4[F;íš°ßî¾ŞúIIÁŠ¥6ÆS"X´ÎáË/Rã”‘
Í™€4ãÇä³#œÌ–ıSáñn54­y7	²ä+†}C~|}uo	Ö^’o)ø¹±¾81Êf‘>Z÷wÒ	D( 6ÅW!«¯ø}á}"Z¨İH<_Î“ë&è™yo h~ç¯Ç	-[úvç9	\Açÿs+iıÑ?2.–ôì¯Ôfp¤¦”—3}øàùJzÖıíªé—•
ˆ¡GÆ1±ÆÛjIü‚2Œ_wR5Ò½"àŞÔø×À	ëx§›ã´T/ÅAôrÑ×Ø[~Pj¤™•ÁGû°k®·âştMouƒz;€9w0"Sáñ àä§Rıc­~ûíì
²®f@Á¢Ëöò  X)[Køé›9|ìA‰o{'`Œ±EñN—ÈÚ'‘µhÎ÷–tÉfÒşç„ N¯°Ù {|üÃi« &­²,¿fÊ5ppêjnø°WÁ¥•‚†.c£=	í‹ûA“Bnø©w%§šI‚|ÿe/óXUdK°Zr½Aì<h‘„‰m"¤SÕeQ¶¸ºˆç&8v\Z îWˆ”}1GşÎmD¾|Jƒ b*Z5ËZ03ßš~ä¨`ñlÕŞ"ß¿8¹}ñë=ŞÎ¡3WuNe¢ôE2ˆøŞPğW…Ú0mù}Q×D9'étığˆ²U~\ó·¾L?)Q{hİ<îP9›»’ÌEşÁqe/)ÎŒúê° nx÷uêİ_Á£/wë=üšPHNB)L¹m²y¿|RçúÒÆYOüÃZ­Q<Ö…ÆÒUx]ZÚéÔ–m02·õ[} ^oÈø°†¢ ×a!9L¢¦cF3~#¨swPÆø)©ø2Ì¼”dÛI;:#§ğùÿï ÔÊ€uªoë‡òõÇ}Õê NjÔ;‡<tiÇITêÓà`“Š(HP :)"eªdÜ~˜êÊ˜İ®X±ÌşÚ+ñuã)ÌÅÖ3\7_ë3R]é£½vÓŸ¿r
÷ë8#VÉ®½¡q’_ñp-Åx/_~…í‹ªVCòŸ‹Eœ`k0uô.1M¤+Ùº¿ŒDTöUt•Õ_SíN4ˆ0ÍmÙ°TìNwƒÚñÃPyÍU5”XÙh„ ’AœLÛH<(} ((ùıàÉg)–w“Gş50_ A
İLşŸRT8=¥~
çè˜bF²:ş^Â(˜=b"`úS³Ü¬ï
0ƒ½Eõå¥À3t†?üW>ù¸p(é:ğ@²—®CæÏaü„’w®¥ºíêò1Xen²jC¸Ÿ¡xq:?„µ×Éªëw¶å Á“±Õí¾&h2ãnCmë9%o:Ò·‚¸:o¦\–£¢RV(ìLâ@ÖZ—-í~ğTÅ¶ÏD¾á£*£†¨i_ÛĞcÃGI‚¡–Ì]£Ën6–ÚUİø>ús\wÀ=#;/—Zş!¥2Şó³¦¡2xò±|àY’Ášëz‹7oóGù&‚Ñô®çK›": 'WœW·p ÆµÔàs±—}ı/ëˆ‰Ná0‚n°uzmo )L­S5v¤7€<f7…äôÅ¾œLßØ^ü%Ë'ĞEb…nŒÀ, ğÅ	@}fß«ÄN¿z¦búèE´(‡(×E®>r,¶éó½fû"NâO\8Ó0"ÿ‘AcÙ/Æ7!;ÛŠŸ,Aí6o“Ï@xàA4úİ§Y‡‹fLhY,·šUÆ›nœğ¹#zÌâÀ³İHä2¥«ºC¦şéxçïƒ¤z.`zÇÆşÃ}(ŞI£7ûœü™Ÿ‚j¡¡=L±.6ÌÚvO¡]‘Mı)9sw€‡ğ]³´Hˆ@&¯Ú40ê>uß-“`z€ÁórŞÒË´!Jzaædc,ëÌ›ÎS7šPç:W
(5’=eùGKVÉum%ˆêg–CwZ™«iHvÍ_úhOåæXæ™™Lq&0oYGï—"˜—Ù~"ºqõ›3š½çk5 ß4îÃo¨ÊáÜW 1»ëÌõ5æ2ş±BŞ×xLœãH¥%ŒL	 É6aOWGüªŞ™)d·3»` }ü¸JıºY»å…dC?Jj²~tr_à®JV¥f­£01 «ëÓ¸©¿ıÉI2¥¿PÙJÓ :»¥ëûË^äpÎ2YÎÕòKûÅ—pCk$èº@øs€oÿ½¥WÜ„„İVs/V¦\ûëQfyPeË,²#/·Áäg@\·B•Ü÷b”â/ï˜í­ 5sZ©’œq2iüRGOq’rJgı§@]û´ËD°æÎ¤÷›6W%3ì¹êãÚÒSDPfâè‡%+­âëƒ8¥d©UğrI{Ï™„ !/Km×Ïµ»"	ù
IåpüòÅş%¾ê`ÆªãÛØæª  y-=Æu;®•Ÿ  GXÉşKÆ3OÕ¹(ÛĞ±÷›³PvÆ¨”¢–ÍagÀJ¥àe47Æ>¤ËZÚS¥¹›ÿ¬¡ÍÓˆ¸*vîL"P±şL Ée4Ha	¿Â3tïcV ™¸UJëÅW¶Ø÷ŒÙùŸ"ñómñC/™¢Éa^ïr~p¯zcĞ>ğAÚ\@H·Këıaİaî)æŸ!TÚûSyOãÍßdã¬ãˆ5®é½¬„!7EI¶%t” å0°ÄÌmÏöªguàğ0I·`ö.ucªsş¢\Õ]3ÒIW¤æ¤¼RFÙ¥OQ“¬Ò;PßDÙm>¥šQ(=şvd¬S×Sdû)ƒè/_@¿vèÆñšª`Ô$7¶©‚hõc0±¶´Â¼q2,6d‘²AÒfíğ•à‰F…İlIyjÁâcÜ¡2ş¸±¶]	„Ã5®`ª5·¤5,ÖŸq ŠGÂœéùÂ5i^¾‰amtñ×ºÄ¢Å)‰ÃäZ‹7Å–tÛ:Ö_ÇøÊ¼IŞGÔƒz?‡M)3±Øô…F£yuù0~=ş„İ~O`Æãêuoû[ÙÏr µİ±’kµğ ´÷ªÉ,_’Çœo7ùü|ÑŠhGØÃdBØ–ÛxH‚DíöNI(ÕP)òL¸úâ	9äè¦õsEÂ—Àå,„öÃéYQw8‘ udåão^óÄÒ4æf§{Í»vïì¸~n­Í7@õ´ËRGPe“1R.¾6Ã7|İtIo/‚Szñ,éìİãh‡‘>®5Ô†¢\Ö0E+«:dÃN±¶ä1x#ÿ²¢½¾áB¶Ñ2)hP’b~OâNW –³“eW‚î*ö7È’q}c¥l*J–)l¯Ršé-¸*I]û¨¿äg­ËÙ:jÍÃÖ^*´—0}úšó±ŠLl99‚œjèAN ›¤ŒªadÃ(Ó;6QfD¼½nóóØÍĞ†§œn¥¬íhóÔvÒÁ(C¯g^(¦À¶h×ô›`*M÷X¿¦HãN‘Ôÿ¦°d,•ÌH1Â	¥³¥€_‰Ğjá{> V&³
ÒgÛ£u½PÿdÔ‡h’J¼{Eğ¦Ì•Í ğzBjóe¯s©~‘±ı7øtÆ´?LÇı•İ¹¬Pf÷¨5ç¸>Á±³¿iÕz…ğS¾÷¯¦ºIµ¤ş¿GB#%‘obà§Kv—^x‚­ÿÌ‘™»LñeÈ¡=²|¢5dıDMü“q†?¥Ûê ŸÖEä¼upıR²* \¨=lä"¥ù$f¥rÿğÛ%üÕL¶çlØ¹.«ÂÔh]ìÎ.ûMCš{
ù.Ôß¡ÈŸÖ^dÄ¶Şd®ô5á®êW‡ƒÌ¬¶l|cYË¼Xc™	…+K-¢˜½bşÚH",o0"+9«sN¿¦Å-Ic#Û’·bZö
†½ÚÉc âª[HŠH¿W¦xZlYõ‡É>Z˜§›À’‚<±P‹íí/$ó<;¡Pƒ4] Éğà²™™›b7JŸÌM-ËQÓ¨I„p+®]ØZƒ9Ê×ÎÙT²Á}€\^ã”¬¢‡{¡Z fL_¦Ì#wÒdXo4çvFŞQ1§,¨—’åW]\Ü:{™¾o4¢ø§Qş2{ƒEo‰ôõ%‘/h>íXGltt°rXK	>ˆz,8À+äÈhÒWÎFöíïô¢H8Eãäh ÛuÉ’ì™ÕƒÄÚëlÆobĞ¸8Û}ÄkÉÜ°ßØnA¸tå/ÚŞÑß¤8ú5‰ÕQ4áı¸¯–ü°ê.jyØ
ÔóP¸µv4Ïõë7#}+a3ùv…Û
ĞîtÛ|äÙÌmS¨,Šİ9C‹«S6ÉĞ­4·}IÎëHgúÿKcMÕëqo•3¶‘F¯[ŠX8zl@Ê¢æbQ‚~eÕloXÖg´tİÊÛ…FX¥Â”óÁÊÿ~Eí¨XÁBq’Û!k6ı×FoÓX„Ôû:D€Q%H•PÈÂÕTóç(ïJş¨Ò:La÷İøpÌD5UÒ¹ôsîW¼í	ø«¶ŞèŸóK®=eÙôÚ×»§îíóègß›ï,ÌV{zÊÌ¦Ğè,ËLHÒ‚‚Ôp­«£Õ\“ §şÄ–Z/:[õÂ B.C¯Å¨Y…û#Kl{‡·)æ„œÅ|Şƒ3ğ×s¨êİtrKÕMZI‡¡LüáÖ@cªÏ_â;´³¨Àòl 3¤à·Yİl;º¯É‡QOü$YI)Ã»dzéZjÎ‡mz­¬©ª¼xİ+š¡öéôV÷[H™vM—®KI7€a˜_ûÈÃÀƒ¥#L×ß¸¹ïzµÈ¦*¨”¦Š@á7ØæÓ{ë5`s¤N?K©¯0¡Ãàaæ¯¡…ºÅˆÙ¬p³H!„ €ÁTœ—ĞãS‚¨‡A`9·¬ãlfÎÿØêáğõ'-ÕéÙà¤D'+“±ÀÍ¯Ü"g¾mGÑˆ	£„}J¥3f]D.Aü *I²mj½„9ÇØpx¢Èú®RÒé˜{	å $[‘*Eúıj;©Hº L÷I¡`bh¥–GI¨øJQmËÓW*»ŒİıOïVî–#`{=İáš{ªÉ 9ä'KZ~(/¦uäÖàœ’5áu¶Õƒ)ø„Æ=†2Ê1…Õ1ù¢Àà«Ü@ó% VíéÔìBÌ³ˆ‡‰©3-3Õ(œÃ‡ÛG£ÖÓ¼xì­Í>‘	’˜Ëõç¸³lo w>,—	gLy	C,IrN²Áì³*>ŒVï{k@€éàù½¾Ë	£v¸ÿÌª¯ºo2ıy,Š˜k·’E¬nê„œÎ€ÔõÒ•gù?!\ës¸.x,;‚U«Õ×æO˜0í<?‹•9*Vâ­;’#&ˆ=€ä•väEÅ;'!ÓNÊPù€pr?í/¾uà_"òzw];U„ô*ï†ã04à½f_/©pÆ{B¯«WÒ$"˜dÌ®U¯5r~İzÜ°fwšùå!œ@_ydæ£y›Á†8UèülHGP¯PuYy+–A.îë2ÇaG­¾œáÂ¯Ï3~Aú—]âév¦ù¨ ¢+…“÷Ÿ?b‹0¢c;®ª®òl‡ÍdëJ
oQ0|PÛ	Ñ‘raKöÙ‹dƒ!f€¿•İÍ')b]]¼]=Ğ\Ñ¢ˆPÜÿ ¦˜ˆ4bp|÷ãˆ³ˆê;¤¹2x6f…“½Àôè%ü¼­˜Øh¾ïœRQ[yİœ¬º`¦QòæJ÷™­)F®ÀD¿Qp.­jŒ;W"sµnÄp"ÎÄz±1 ]¥¢Úÿ2»Ç­s:Æ$ØˆëyeÃ
ä”$œPa™	}ïÚğE!õ™dL”uŠœœÃ™O^ÒRL‡•EÅ`ûå~>lœKADÊ]ƒ˜R¥*ÖÂîÌÕ=bâjnÚø3ëìùœ”§éÃ®R Z"üØëVo[4*Òr”@°´Â»,™R­ô Şßi¸:RöyƒêÑ;gTIL?«2ò´¯˜†¸'J‡eËBğà^¡Á@¦ªê›8µÉTc£0¥¥¢}¥c—µÃr_ş…òğQ / Êd÷¬µÀÜ;8èdFº!“wÒjí¾»G„fP8Sg‰à9{î8ü[hâlœõÁÙ
bÄ #ìá{¿Önê‚h~TÛ¢Å]İ}’®¸o«{¤3D6kfn¾òÚã¤òrã°dUƒ¾ŒD}â…ª‡ıIakÜ©ãˆÌÖ­µ‚™VÙ5%{SÍI å’ B qø8‰+Ed^a8/½ìˆ¼ÏPUş„›e™uµß^78Ö9!;i¯9ôøqS09µÒirê¯Éi]ê˜Oû´a2ı'Ó44‹Ö\^2pİ–È%‘’8ïÏçŒæáX@õ½s€Úo—ñ¢P1P-Vi©›*6"v¢Ê¶Ic%wE¼zAMæ£yœÑZˆ>·¶R=“9ÇÕÎeÙ[3?|µQÚì. o“$°]½ª~…½“ ¥ÇÚ¾ÄâaT>&Ji»Õ9ò†á;õPÜœ¿Ü‰a¨ÌØ'uu{7Ò')&kÈîµİ¯ÜèFØÜÙÙŞ5ÿ–JÈ#¶}®W‚
»â³˜ç×‡Y¦öêñ é~kø¡WTqöGëJ‰ƒ¬YYJã»‰0¡¿ìJÌÍ¶ñ$_¶îíîQı¹­çTÅEÒõ’Z44qÇJ›8+#í“îsIƒ\Yê×0%T¢O°Õ(ü1XKî—®Z0éñ	¥Ğì`>Rì˜×¢íéœĞâ"^Û£Wÿê†ñÜ*ß›
ïåÏÛU'œl5ŞF™ ²0nZ
<ü”ÈrÌ6¡¦îüôšM’Q€·æÿ_rGö¬˜DU†ÅÂ%ÛÏ¼` x<9´F/¡/}ihzÔŠ”Y¶ØSÂA£~«ÎíFbúòû&a’0Eã?[3¾®A¾2%R
$ˆ˜5­Õæœl~·ázàÚ44ÜÚcåfënšÉ$œQŸ yz<ı	ÒÙ’;:6Y=
ìL¾LÏ-a¥#xÖÆÂk)ğÃgÎ’8ãU9•øã'eR©*²ˆO‡^”9TV)^3ÀÜ‚Ú§d(å™ß'à¨Eø#'ğ©&›ş¬Ô"kšš'¾Q Èøl/Nù`~V•x5iùâAyÍTa]¼3‚ÌqŞ£š!›áZd¥ÕÅ{òBäP`2ı×h»_Ä„Ş3<^G¨ØÖ‡g5¬×k¾öŒ¢LpR4~ÇNœ1x¸ìW/](kÿœ 3…Râ¾‘ˆå€Çä+éØÈ5ßg¥€vœ˜_d/7lÖı­™Ñ£²¯ı˜R=İ
ğä –òO­="4­•!ây-oÙ(l‰[Œí©îK.ñ¢Àä[îTâMToˆ¢q}äëÅQJû-/7OÒ‘ÇH	ş„rÆê–lÀãü÷©÷¹@³îÅ³uÅ¨~M8y=Èq=1DVµf7y™B;ãıe{.rVÁèk!c{õÂÍrgº¨Ë3o’ı«¶©}éÊ‘>J¯üOMï~ƒël»oCºËz±iw&c¨¥5NÄ/¦‡0gÿ4ÉKÜDÀî>’JŞ’l¼+§=%M‚Ëó‹Ö8=ùIôæ´ò¶$R´Î7„>É{IòÒæ…®›J±¿÷}šĞíë:B÷FUFâoÛTÕÌ¨iá÷egyôå]¿():úh ©¸F3lò_†px¾·c¹6]ô`Lgî€VÉÈ¿{´v‰¢¥6á[÷/1ş>‹î×'cgÅ‘²½`¿ÆØ°yfö,#RI©÷ÈÕ–íL~§ ÈÙ‡¨xª½¬eƒ§¹‡P›+ºLƒq“	¿Š=ø½ÆíÂdğd#ÄN­,êgğØæ23zš£‚A8 k¿ÚêÚ©4àUØ˜9ÿÎŸNªã[BÉvMKíšÏ^¤\s¨ÆÏì‚ÕÌ4`BcÌš}‰î
ø#Óöº¤ä‘ÃÚÔ_ÁT<qş­„PÒK+‚»ë{Î&&8%ÿ±‹şòJı³–Ù›¦¼«díB°=¬;ÓDw¿"Ì]'ò	j‰Y~ÒÜ¤iIˆ*·(3¿†¿â‰$n E6†6#ˆ¤…—_0ÊàóÔŞéµ‰X¯g€=¡2—Ë—ìÉ›ûpšÃ"sÒ1r½cR˜3Ñ®·õò¤EÍd¾XÒwî‰qzrkÔÏ5jÄÆk÷°â ôùıkm|’ŒÏ{‰.zËk$"†¸M y3âXjÎû˜íÿWêÒ0FçjB4vşæÈFO§—‰€nZå˜„`<‘ôIë©CöoaÖa‡÷ˆc@n¯Î@Š–àtÃ’o@Ãi%	Q'‰ZBc)ÉÛqÍÄ-tõ·Èº·Ïºæ†¡Æ:ï÷š¥¸ /§@¾ËÄ¬J§²Ï&¼<Õ&(² ÓP,²cDjpÎ¹¿UàN„Õ+Ï‘°ÓĞ R…——ÔtÇ‹dDıpû…]¦$$õN¾üş‡¢¶ı²^‹(~TTc×\²khÜÚ’´ÖºÀĞ5$çwÜäl¸æ>Aß7¯ŠN[X’á@îy¯ğ®r¬Äg:+ÿ¶ÉI˜;õYbUö1ìòöÃB€Ø{&ùq:^à
äxßö¸ñ´‘‚×åÌï»d¥ÁµYT øõÆ_~öt[‹EáŸ$àFé4àOZÎ&ğeh¨|ëšƒ—û‹Í]üó¶®À6ÃXˆjMÅå„vàÛØ½º1 `Åcæªñïıdzå¢3îM®©õ¨×.pŸ<ğoJ¿rw‘ì¢©¿ò=[›ÁÎk±-jÅ¨cƒíg¥Ò¬Àõù–/üãåxÏn¶NÆçÒSTÔeêØ¥ÇäÛ½YœVÃÉÎİƒÿqA‘¨—©2K˜ÈmÚBI¸)$ÂH¬rNéÒ2jT6£³=Ü[¦i)È*¾ƒ•ˆ A–céüf4™ô‡"*nÇÏÄ³T.¤F¸¿çsrÃ ÅQ$b'¹D+şOÀe1k@d]Üã†Z†E$Ø²qÄ½é<_úSß^a8môzš<­¼ÙXûğ<,0ÚÒ)` ºğQ1L>6Z`>Òˆ YX>RN#$ˆì¿13Û@ ÑIó¿(îUm©FóDÁC0öÜÇgQÆ!ğ£kRbÛ÷¯ö¿¬‡’o^iÉ¡6¬§ W@uãbäj°[<ÁikUÆÊŒ¡¶éÇ02dI%sC_äÂâUë¤b ²ˆ(®
ÿ©EÈ–«$æa—ˆAÃÒnK ‡ÏË$¿éÓ äÿ›/GìehƒXú [!Ê¼d÷¤ò:Ò8¥İâ]$KÄ·Bìñèş¬q¶)ëùŒëe9Ïß³+Şõ@@nOçÔÅ}J¸ô$×ñÓºc%î,u°Q·×ö¿(‹‰¤x˜ª+IºH‘H; &ä¨ó¨˜ü/G†ÉÏ<¸Öµşşæ_jH	PMAµ+¿nô¾×-­,©”İõüÄ~fñ®'µàp—è'gzq{c¸
¤ƒ'¬ê¡¹27‘OûµËWİN/ÜÍ&Ùw”]V,@ŸrŞ^Äj5Jè9_ş±ä’ÎÏ+÷÷MòM6Mk z‰ÙN¬›ªÁ…ÖkXvr’œÂg~¼jG­Mk(T‰ò$®å{†S!Ò«£ºèYÓ l_ËR¿á]l°<îUv.àÙ›µ§ÊëA§a«]ÓŸ>**—ù À¨“ğx5ÀÓ­$@{¬¦Ò7ë“IÃáú½Ë#‰Nì”¥±v'67ŞàšÀáòo,HàŠú³ß•#oÓ–W¨±!”ÛŒ}K–«™—oí8dé´Jî«<°4:0ã­˜‡D²ai:s†b?dª®¾póÖS=Š%dÖÕ–Üäßáhuã8ı8fç <U~ú½ûc™¡á^f¦¨IŸãÿû éÂû(¡Ÿàßò_€^Ëå1Ÿ"‘’]DğƒÓG¬/@¦u“("úç+~ƒo 6‰Øs0±Â$jÇ€µßf´(±0o_€s²pM…ô’	<xa–.«)·" '1í29óËvŠ¬†“t%ØY]·-ñ’ú}'ıı5®8¾räÜ÷`Ã¹ğéB®ûøåK´ÿg´­teïGØÉC¸ÁhƒL‚Ò%¿¡_ïĞ8T&ÕŒ¾şm>!†o4ğS,Ò„€‹°ì
Gî¢ÆÖÁ<­ûŸ\òÖÍï£±ÂR· jBl*]óRŞŞ«c£[¶PgÏ^á@dÑx±>*µÿ7€Iï3´œææ Í+MíÛ~Q“‡‘ôñB„B[Á»$©ê¼8}+4!b(éBs·ã
Õ`:®DUG0ÅWèŸœfåèo2ôW¶<mLé#å	C'(æ"y|’q0…àjCZN1!¾+¦Å;DJ_ñë
böâ™fø6ë«Ö¨j
zi«íÔ–p4!‚
ÚøqWí]yƒ;x46MpÏÁŸCûš£XöRùq%¥&ÖıbÆFÜD7I±kşÌc}YÈº£&
¶(!R6[Q}‘gQõ4êËIòº>bÿgNXd¦F”¿.na[¹DnÂ–WVO¨=”ZSÔë:òè¹bŞ@¨¯‡<”X5ŠN€NYŸÛÿÕã:`£íjíà±éŞjA.~0(D°šš%—,Íæ:ğÒãTÎs<¶h£€æi`}ÂŒõ# Ã´xcÃı@ •/ª^{pó)¦ü%2ÄR–E~ŸÀpJËTÌ‡…ñræÇí¤¯}4³‘‘³áY–ƒwkÖ.1ö”¼áŠæÆVJÇĞ°ÚRCª×ÁÍåÄ5„ï@¯¥û`ÕX¥š3‡´âe1±««“Z¨Ô=h’Ê7{˜Ê—Ê·51B¸¦Wçøµ€?ï3Û!Œ‚uœèİxØ¹'NkÂ#kBŸŠİ¤“·Ó¢ñÁ òJÔ½~Ş„jKl®ÅIİ+Ùƒk‚oƒŠo&å83û2DÖñqÂä ø“.Ó¢Å¦‘°¹|”®ÕøÙ>ˆÏÄùùO¥ğéœ¬¡%Ïb*Ì"|p¶:#îJ Ø;¾qcağç’ yF¬}‹xüHø§Ïˆ„Ê;kW:"Ñ)ú´ÿ¯CèŸ@ÆQ‹šûns¬Õtã$³ƒÃuÃãBT¼„é^ı…Ó†3H	ò‰¹Îº¬5ù£1“¶––ÌâLhPH(a>ø&3ç¿Y‰–·k+\’h^UÛ$XÖ ©<JÆ˜Ñ.}!Ğ²KÅ»Œ¡>»L‰¤¢ÔµƒÎ¼Öíû?ğ° .Vü4*†¢ØÂ³{,ÿ½Š?A¥ £ñ¹££®Ï/¶S‹HeJá)ğ«õ–r‘]¾ŞÁHg¸Sò/à–T Êá¿×Ö‚3ÏDv¼ø-ú¹œ:}n÷—ğ ô"L{šüKêöV°ÑéSw€Q¾öµxoüM›ÏÖßKZ·tŠ)¶ÀCÇc:„ËL›óòÎ+‡6Ş*Ì)+<£(ş~çF•ÜœîŞZj»ãÙÂOÑnM´ÃÄ÷ÌY®FG¢%,'61_3@ÊÃÉLFÊ‰•„ç3&6"º´Õ¡Ë'/eGS¸­ååÛÿ³@Ú«åNØ\a<_åAvÈÜx†g2xÕæá×©l]"ÜƒC0VÃ›6"ÆL»I
1b:!šäú}ã°ƒX=ÖËİÔ .Âİş–Ï¨³~-%€øƒûÔôzW0‰^"ò‡8ŠIÀ¨£*-C!¡c°’ÄÙá”_O_E0¢ïî³1ÙÛ‘)[Û¢—i ¼ª×!‰ñî”7¨œN0´x:TÁZëÀëèTi¥†„TÔˆàì0jH†î»¨²:|·Bxù3OçÙ¯É_ml»QÉ©³¶0˜’›@ŠÔ<¶•}R¯Ÿ›ìñf—Çı€	FÕ)&’>eñ\*‚¸é»4¹rÊwG»C&Ğ
«ñ¿ƒL‘YéS!{I©dhÆ}±D-¦"6iV‰°V†'‚aÏ\ü+6›-ˆn¶ã­b3;6:äŸNäì»”.âó„S9°ÃŒÇÓÿÎy/”^–¸U‡B‚Õ/44|Ò¦t÷hF©º¼ Ú®—¹›j×cQ>é=™¤ĞÊwôMöÇdjÆ¬:©“Û%ŞæV¸'©`A8ğŸÔ‚–$‘§Um™l‹ø¥&¥ÛÔéÄĞú,pùŠœMj)„ùŒ§Ü™”¢<ëj‹óôá¥`åÉâà%³wÍ iˆ›ÎÏüÆXÊtÑ%ã‹ô¯€ÃÔ‡@[ªÒ±À±Ä—'Jk i@i:ò®±f>nŞĞ‰ÍwÉH—~/,$½ĞZV:i
§¹<â…NÕB¨Xö¹Q—ô}Gmv-TÅ7æy¿+¨$B°r'K(Òÿn¯¾«/f¿şxbJ…Íkß×_Ì‡×9®”f´™}ÀNM›2ò_ÄJõÊPj`³¡-Tc“$½Ò©şØŞdßáı*ÍíƒjVÖ3ìm=É¶A’ì.÷I^}‡ì»‰®ëœ o†î?×bV±ZÂ‘Ù¥ÖŸæñÏ¹.«Mà¸§D´²³ÀûªŠÃ,|™AËÖ7x)ÖºÀÍ4	|„(º·U20ÉÃT'%WŒò® —=€à•ÄËÕàĞ0ÒÓé³µĞ
¿íOHm	&¥¦y,™«ğœÏÍ°)şlêTë·ğøºW½ğ" †uÂàQ¤„Â3<%2&—êŞcJëãk÷ŠMÑ9AvÈKãd6.ŞZ¦/ƒ”í–r!} Dï¼UT*"ÄeÕÏ˜Î/¨$ï†¨^íí˜æ 4¦»Ğï)SrÕ»í5Ç^Jz+a&WéÌZX…b<jì{í-;R‹jEi«ëÀñ‡ÉŞ'/9~ÍÏõ‡EÔy#b¬ãù|„e”¸ÛL¦Ñâgi4ìì+¸…¯4‹ ”'Ÿ¡»ˆò­[´ĞÁÎ#’’×qÛ#à¥´(åÖ°ÚVâ„”†ü•¥ıØ¯=ã­ÌñR´óhš´-‚.çåçMZ,·å™
”¹îQŞzWµmq‹èŒ‡áû:è”;p¸ÒÆßÿ?Ô Ú‘"El*Ã´d2K^	ÛÂÀä‰¹F]Á's0ãa??vKt‡¯Ÿ€·¦ç0¹¯W€ŸHÏ®nh
ëkƒ7>Óï
‘G€Ta`™{ıÏ
…3úè"Éˆ„LÈ¦M£`ôKºĞBpvoıxøñó~FgßV xègçÉåÇêû÷Í–Y@§&kâÈhE÷{Ç©dÖoNíŸöµ/‰~ŠĞÃS½›È1 H¡Åø85ë"yë{f:PÓä#³YP;1çm«%,—]À²FK¤#¯§"lé”{êÑMæ…šXE|C–@E)sÜÛIvj!…/sc#!İ)·›MÓ!:Šoˆ‘ŠpîˆG—pÈ‹0uc™Ì®.ïˆ§Sw|¶\¥Ó»„Úe÷vÏ%ğD ‘AÔö¼w„qûâDàzÔğßMX£ïü	'ISŒıX~À&ˆç#¨7ƒP™Ô;ô]¢7‹ŸÀ“½Ëğó3ğ3I×ÿ¸¢9y‚kaÜ°’‹´ñØç¯hRŞ]y/U[³Iãåm7šÁÏ·6ï˜KìÈFéA;Ós'¿KÔ¯'¿Û0;øŞArŠêbdsĞÃl˜)ïÎS©ì£ŸE:Z[3Àã›lÙ¦‹†H¥5àaÓ®‚4Ä%?JÊÙ;x^+œø#ÁÀfšòñö[’ÉûXüÓ¬ÉzÎ¨¶Ìş(¨6; d€±ªğùiİl#fiÄVÖO9ƒ/&7ÀÀ%kR)àº]ºB²Y4•°RcÓ£n<C]­Ìíûfù¼Ê}³¥RÆOËXÆ:>ğÙ^-Î®w®WAn ) ÚE´´¿íû—¨ˆG´Œwtèá_)’¼yƒ·ãC¬ÔjöÚ}0 R(½d>qÙÉ´‘&õ¹BEn³"¼şê~˜—A‰çc9¹WÌİcºßÇm!LG¡0—Ñ,Úôu”ªxvêëÏô˜´Pœ#¨êtv#çWÒ1Áº³/*ôDœÏY­½§ºmá¼((‘ü‰}é½ö]ØRj¦Ã|¯E*â•Í$Œ{í{š.Ù[f¡ü!·V®ĞÇz-D¿fòc*§™ä"jq„>ã+Ø—#àAxj<Y–áË|ˆâ¤õ²âExêd«“î8«(ˆØÔPPkôÓÄıNE$³zEÃy’M?5´ò*0ãÏ?›,")ù5$RN"<$ñÇ##:„7Y¨¡›)Â2
-NĞCÙÔ“	>ÔÚ¸v4#b2O&ê'JHo‰óNò}—J¥õğ.¥ ÚÈ~wU
}®¿J­Õ”`X$1úWŞ ‰lá¿â.°°3!,Otÿ²¨¨<ä¸ÜÃıyùBW‘M¯Ü×©æ'Àd‰9
…Ylï>èdI×5Ú(ÿÄÎ³¯ ã+Îé
F¡yÒë·&Öüå:sšëRª
N}4rÄ†ÿŒ>¤ØqËA§ãqhT í Í¢å¯é³tu¥­iJ„“™ıÒ¯£ôMÜÓÏ&ş!Ò4õ!|bÃœBö[’_#ãNbÄt¿şX; QÚEku¯Ù:»…ìDnPp)#¢›±G‡ƒè,’Ñ
æØk(,å¼…H`EÔ¦È+9ÿ8Ã-¾¶VûÖ!§O?É+Vlƒ.„,®GÜçæyü‘|q¥<áaUõ#s2‹ë`àÍb+lFÀ”9ÿW§¥@GÅÖdì 3-[U}R‘¥MzÓE6;Ö4S}4®’¢zóùÿ«Ö¿,¥LCCxÒ[[ÚÆT¨·õÔÄ`qá¶ËÁç (úŒ ,Qj¥kSı}=‚‹Û…ë{vôA*ÃÆWTW_É-ıu·9$G	$vÚÌ(h—E·Ôiø=ÌDôñALr›6|„Bÿ¤¸lßpµgÇhc£5	Ï¾lgz<uYßúˆYFÀn¯§ßÌÕ¯^t*¾7-!¦IKñFÒÛ"? î¼éxı‘éä¿D#‚Ì^Y\-Sï;­0RöÛ(¦˜–OúæšfS%f¿p"·Q7(XhEKáø†nĞl­Ï«6ˆ·ÍXBeÇŞw¸¤Û{øÚ+€­ÿ!Wü a{uë%³Ü1,ô¼&‹ŠUV#æÎ¤ñW¥°:~LaÈ8j„F&NÊgûn,¶à÷GÖRıvµ;ŒX2<¡€´ÿ’`×æ*e¦Éùtîœu¯›gxOª)c‚!ËôL{•™xú™Z>Bş-%îñD½İÖón§i_Ü¬9İX2×j•‡§`3WNg«T?ĞÇşÌÄ‚J‘`Ï{•E£^§²XpĞ¢³•9[÷$\R
®O´}Ê;ÄLŒª,IÌ*÷Ô2È¢·×IªŸÌÒàpxµS?ÅŠ7PÌ­ğ^0ªé½{ğ²ï?A@˜ƒ‚zÜğM¨õíF–¾–Lç¥¹|Ø¤Ó×3ÒŸšÀà§m1Ë#nÛ¸-2Q{¡?Rõå*ÏÍ¡=Î›´BJg“Ç‹õ¬òèÜô…¿‡R(°Îà•l•ÓCşvË«ƒş"ätnÃ*L¤s8ŞÛ	bÊô\› +¢×mµ¸Í)Ù‡«jÜğºãX–]¡%iÙ.§ú¤ĞQu\ÎWVqï€ÖîğÿFğß[ç_©Ë3=M±K~^‡[H%Ïÿ^6?º!ÌG^Óo_Ÿœæ:Æ=÷aƒlLd~–RlqºmÈ©0«Œ6ØÜ/«ımX“	wõ|Äqi>IÂZ‚ûşo]E9Gû` ¢ ²AâÈı¸¹D„ãïJÜ‡oÅE«ô·–=<˜Şß ÄµÑ˜®¼Qz~}é6§³9@âÏ`óÊvw aµÊ=)"G= ã'á’ÇØ¦]å%dÜøŸÄ;='~÷ıÃC¡z¨Á$»EÂ³±é÷æh” ){@²Û$oÖ ì†î×ê5V'ü*™˜¿'Æà
ks%–Â,
&˜AAJßênåT°@šh'(¡a+ã!°ØÏ¢X³s7Êö¤&›Ÿ¿Pì#«åÏ Q‹jˆØ ÷ÅcÑTƒÎ=Ï•oOÂ|ìÙ
ˆOÌ–$a¾Ç’Íp=ÒG;šjÉ’÷ÆÁÑ?ÖOÏ `2‚2ĞÆ-Ä1Ì4“t…ı‹Ï/V¯­„Ò&ßf\``ÆİC<™Uh“©Hã9\ÉÕù6Eóèqîöö$ÅŞş‹aÒ¥ƒ0õWZ­6	À;,g7.ôHş“-üyrÃ™w6™äÀ+ğBA÷‚§ /z.sÉ¶öÌu‚äŸY„E€´Ñ!VéÏN"‹ª™‡•ç•ÖŸ÷/,s±»â5<ñqFµG>×áã€Àøé,ÓPyF>¸=ÌéàÚŞ¢ÓFÛ"¿r™é6ãÛZ¦î2èY‰¬ğajÜ•âÉÁŸ½IJM=—hª3ë›[AË$KrÔœÛ•îÆü¬÷ÓIH]oÇkbİ«°ù`o‹å—Zm¬(‡Öë.èVn/e#Êcg··(6Š'k0îWÎõ¥¤ş¶SÿtX†Õ—YæĞ†b„£5/³öğcÎ—nPÆäÜj˜_X…/Ô›a¾E…A,z
ÈhâBĞøŠŒñçì>ÀÊ«¶Q¤äÓ\ÿ&ëé4Zòğ)@şY³G³1ÍrŞ.#ä1ŞDZNN0áR-!úƒ›G!ÛpÒ¡i…fšeLÎş´œ?ŞXÖ«GG§~x¢tİÀQ¾Jr— »>œV}âãtÉg$‹yÕ¯÷¿1šõR2öÎ…fTëÚÛ'ˆ4ãˆpÌĞÊ
î<;lœ¡{²Î'*øA@/uL¶©•¼oÜ,ÿ§ ÄF²;"Î ßmõåCş³Ûı_è’ægœç*éf²V±SP<ê>W0Ë²`ÌƒOÖä +;à&jæ‰9„Z-Ígı¬FÎ/?şsÜJ³ZlÁ>Ì4†6ƒs€–j‚®ßÅD®„	 é3X¯ğt«22"uö¶úÌ¼—éñC»öîá0NË¯EH£]4Ì½1“ Ég£/XKÄ}GìèÄ1öU Œ–Aru¦Ò†¤ËI¸Âù·òÕb5M	¢w…v¥¡aI×ğß/çÒõ	$¹/}¶w§µû_pµkã*á&czÿ¨£²ÁÃ1z]ŸÒÌGÑM˜ä’Pt¸Z.-w†‰Ÿ6f 3’õÎEúM3É	¾ÀşfÒÕ"xg±¡÷ÆrÖÎÔ›Šºÿû£î ã²ñ´r³ôC9ˆ	ğ¤ñ†ˆ„“*İŒ—ìBèq.c!ÎâYÙú‘ĞÔ°&aŠ*+ß	)õ4"a3ZqÜZP÷ÙÈ]fL8mô1•Š€B/Ìí™/"a…ş>MoÏÛ`•â7Ó“˜İ–Oüb¥xKĞëvÇü®'fo™ÆE–¦¹¯NMë$‚ÔÃY×–ê"%Á©’Œ›\Œƒ¸ ¬¡?ßí?‹¶<d~œIOöÏñgq”kl3¡š"úR.øÚ-ók}É[¹º/Ô¸_h½pi¶:ÂyÛ»\ıœ¡ÄÃŠBåX€…g­ÅBİöxÑ<kÂŒæ&ßoi§zlE°´tÂ#&­LühS£¸œfÓ{Qù!laï¾©nÖ€ê­¡ğÔ!·3OåÒã‡½ƒ‘yU‹ätz[3fêÙ!Â70Øê4Nù"—XVdÖ´§ßé¬¬¯Öé¤:Y%’V.VÈ‹6ú Dúæ¹NÌL6ädQœ_³Ÿ¨óô¦’ƒDZ¨(Ó¥õ\6a0—.Ug— „¥hØÁê_eúJbıÇˆæ“{ë	¹§€[q¡V4K×‘HĞcN=w§‘IñşèêNsWšX¿Ú´,e‰Âœ8“^[IÚ¼}üÿ¤—™ÖğWÍ¿’Øªàï ¥8_Ü"Ö×Gr2·‚€§);ÉT›¸Š1ÔÓ½ -5¥ã#Ès³Ì‡[Ï£ÿ{…¡0½2R&J&"şVúy¢,Êv`]ÇSy£ã}Î@–û–ÂX<o.³Ã™ÈKZÓ®Õ@ß¿ÅZ…‹Œà†l£ëêIëEªL?E†üĞÕëN–~ÛšæŸeÇÌşÃÔæù%”ãÎÅ6¥á72Q6‹~ ™YLÛ‰ñN×Ä	¾8iğ«¹›ò›¼şHOƒäaÍådfÈcÔÜËZ¾¡Pµ8²ƒõ"‡ô+^sõéØö@Û<)Š_ø‡5ã2 ñ`[qŞïüL@m˜"ô[‚Û¥õ­A
Ux·GhàAÌÊ‰)0}•5WÇƒ`w=Ïid+kã,ïâm80¨Bù­¢³»8BX_^o÷HÛş“ƒA-—®Qˆ ®Ë.Ltú>? úX¢ep
=2¤F‡Şïõ'—Ó:½zÏÍ&HVœDg1üöeìRùtgoOêöVZpÑÅItß°K¢b°‰ÕåX]~úiåt”qÃó&¬¹K6?+a+¾ÅÈù#t¨…÷˜À¤v«oé—Š¤¤D¹ÂìcÖÜ‹)LÔI'ş†Æv£Ö¶ÿœì~¦R¯Bó*8’Ùé%Ç˜â
m_l÷—«›>ÔøŞ¤–N+ĞßaZLM;KS>z!ıĞ°·îÇ–W>”,yUÆŒ¨ÊÓ­ú«şp «Æ?Æ `1}îpr°ò?ÚíÁS ˆ‹»õWño÷¼Ï,yÑİŞ£Ù ‚krÜö)t[&F]„Ì¨Mû…şÇ%J qå•	èx”'¶Yñ*'h-Ñv€Gÿ®‹Â×q«òÂ4Ÿ,“¯·Ğû¤1*hH!9¤G¸“ûİÑ«ãÛdB•=x;øW×¡Tö©ÔNZÕ{ÎÎfİÛT·†ë2~ò¦È„¶ë¯fç4’b\µÂ¨‹÷ Á¯¿ô4ê¼b–+ˆ1ëJ²IÑô¾S	³O¤²,£iv)/0n»{µ¯ªÓç<!C¢$¡úlÏ5m9góHf>[SàßéƒØ¤•êôí¯¸N—ğÁ-Şvmî,[B»ÁZA/Ì%2«ù÷>Â#;]xp¯Gçº²IMÈáÑM¡yk¢ËË4Zõ€Ï%Ã¾ÿ˜"’{{> tQp^Šo–J–œ\ş™!•ñúã?qVØ–Î7hßÙ1RqñÍwŞæz&—¸Ú—ªßª:æbAû®Ô‚ø¶³ö»ßbâøD%äv—èÂ?´¿Ì3‰V@›˜H¦MõÖì‹òÖ²
ûv}zÁóÚ}sŞÖå.Ş—°5·\û„ñ9	ÓX”ä«ˆ­ÄNô!/,5s>‚.üÀlı…A˜'4hŠşï2RŒ0qW3Ç¥ˆvSB±¤‰ñHÑ[ÓZFêê_¡LFL¨§ÛA‚½­Kzl•z1&[df6=±POV¶’C[Çjìª†“²İcÄ'“ù"×ßç³_œ}ífÍiîoIr=€Q¦ÇG¾i¸.›í%Ô:CR0tÆÑuÑ±‰ŠP©­ıyÊ“5~@_ŒÉ?%Å2#ó´á5ÕP‡‹±²ƒ²Iª†³@²`NóûİBcÕç17ÄFBÏt¾®.¦!ùİÒÂšÀQRœ#PzxstÄ¸‡$ü‹j+›}U\;uı–ã¼…_Ø›×Ú}¦vZ±ÄÓ¡ÁW:[ÇYşŞæ3ÿ«×1l%;Ëç‰P/òùH ÿ,‚gæ×üK™éu­¶Øµa@-[¾ôÉã‡~¯¿'$úˆÑ»a°*r«“xtV›9³‰™B'
vEDA°õ'/´ş|nWëVö¶Š†YÕC²ÚN¢§“3{#‚ÂVÈ<ß»jl<tÈÇ*&.½¤g¸~
µ$»™Ã¬‚R|eÔdç·Q—”^â¯…ÑÆáü|è‹e%¶ 4@kAÒrRŒzª£Ë¢Å[ËÖLDÛKÖ^?£¡ã^ÍêŒ)ñ.mØ-)–†H²:ÿ¸­ß@1H tô€•â“QĞV¶ ¬°ú a‹ˆqOîÔ5cŸ™ÖÍjÑ—zçÍ³ÍxéàÏÂ%[Ó—{¸ROÇPÇŞÊWtÌ]ãÓùÇ@ƒ?ê×Ÿ©ïû"B&Û†»eZ
DÜÄŠ3É>xZïòXé==Â,?#¡¹–ÎÈ¯R¶¼h<(Í±ƒşØ3¿x#+[Jõ®¥\ çáUş6¶†9µõµKä’³R{Å…ÍÀå4ÏëÂÇ˜Öœ[‚ÆU“ †$XºÀäåVdKˆ\±%ô»H’İ½MàòÚŠÌ†ìækëcÛLbÆûNØ¼VÍDÇÑ•5$+ˆl[8ÏÁ¬´oÂñ4
¿3’ú Âá$ùÁ­æ•¡ş-ãY9\Uã»¿¤:n˜ÇRØÀIAkÚøÏS$Å,ÃUŞÙ>äãµ>»p-m= —í*ˆ êòqt3µ‰ãNF¾ód³™¼"ä2éóF«°gl•Ì(R·¦tµX3Ú–i>ƒcœ)»ÔM«’ö«ót‰Ós¾À§EjÌRIÔP“ÏòŒà*³zó¤ğeL„›ıÂWÊÉDæ8Tå<\ãšÔPñ·êF¶ßºËMÙÑÄk£#Û[B¸®şÂ/2ÁË:+ÆåÊ>Ü¾on½Öè£5„x‘vºòŸÇ;¾Y^÷§®µ1–Ğ‘³¸ë,İ(! ì•‹BĞèiVá›÷^Â»nuÍÈÜ04wPø˜ÏÚâAˆ_™À¯igÄè¡mC}yıñêÎ}qëz`§º¶	˜-nNaxm!3,éQ~ƒ7S¾°Fd÷TÌÆ|°èO˜Åw,¹Âšş$4XOF'êÊØªf5ØâÊóŞ>£>ddÄJ„ØfDrhjFG4<Îß¹Î}ÔJ±'>‰£R„g¯1üñ’èĞÕ³ŠÚêvo´Ää/náŒ4!\4eV2{^~Ä€Yõ|J‡Ç5lš6,¾y°×-Ğ›÷ı±0ÑÕ°?#bs¼@¡ìD@Ö–Â-‹S8^‘!&ràÚKW’Bœ‡<yÓs‚›5Õo*æñrİÚNÄV4´JÔdûD%?GFugÎ,Õõ­/¯4+fzJøĞÛUHã•±”XJíøóòï„ÍIÕw«±Bø*ÓCzË¾à›IÍ·ˆ&ŠÖR,¯æ5½eS@'¼aéÒ!˜Å=9:iÃí Ğ5 lú5ßÚY^—œŠıšfşváç½4WPŠâ'CÙªÈşõ$G"[ÈšÀ¨ğ’–_4}2öñc"ãuªó@ï%æn1÷zùa@üf­‰á(aúş±ª…½¬°)×/2eÕA¤¬U©Oájß¥3†?¤µ×ã–œ9Ê‹r"õ(Á7Ó]`;¡x—¨ì¹–óñ’‰µŞBíÒ²¹¯–¼¥i¿Ré1a+SÊ8¡5y'$áåó…Š\yf*yØk3`¼î:KıØS””VWW_Äã¨’&&UÔB¢2õİ:aÊ¤ÕR"5ß¦ ÙÆ’›‹Gnú< ¥ËX_…gêBsRëçÙ×ÚI)«oÃ:˜«ÕtF\¨µexJOû9*jTÒ,#’nşeãÛ[„èN·I"616Ó-pÀ¢‘åL%”É:ìî›6»öÔg¢Í±d¹
SÜh%Èµ•´W•v).ödIğ½›İ– tZú}¬®;ƒëñ@…6+~†‘èfCĞÌ4£ì:1æa1Ê0KÆşFØid>v0YÚöEãìBøÃÇ©ÃYLŸ†¼¼­J8ÜğG?3\ŠY„-»šPDcÔŒâåÍ¼Vô`-“3	u¢'qPø?%ë^èÉ,¡ª‹Œ¾l:ˆœnqÚ`9DµÆªuìcæ@ô¼vQOyà´2U¬0Äc¨°ˆš‹4ôõ>:‰­©Ë´ó6ü,ë€ãÂñ¬9=´™‚U=NI«âßR„}¶~Œô¨&ä…òf'Ù†zÙ37K?GÆ']ÂW
˜¹×§lŸÙXXÊ!%ûˆ@ÈìÖÿò£ÃªÏ>QáGğñAë‰{ÔK2ª u®ÄAùŒH¨¡É|ü×õé—&lÈõË­Ñr“cêşöº’›«"…)|8-@ûmürUÙM„TêH£—¤
L¥¤ˆÕÙ ì¹’ŒÃ)¤‘ú#;“Á>‡³aî•˜üB_ü‹ï„™œJDXÆ/øú:êwÑld‹DŸ¦éˆ%M2×^Äó)ÃC«•qŸ½&àØ¤£ï×K[Ï;!F)2&Ğ>Á—ñ#Ãºîßµl}FÏºrôÃÊRyj²+<®-Ç«²<Sø’½FiK
m9)‘›)ı`Œ/Ê†6
ŒO­:¹Y!=ùN“áë¸=RL÷¸Yª{¢€'rcè¶fÍ&¥¬Ì0rÜY>MkB6&ˆºY.`r1°¸ºè9ã’ï;L¶m¥çé˜7UvÍwÉ®í²Š‡áaÈLdc±;˜ZÎî¦b
ˆ–ığÖdhê3(l´Mãô: ònÖ1/yG8S—éfğbeVçÎrÃõvç|d÷‘ºÆ_Ñ®^÷„ÍÖğš%.qSØsòy7^û‚úbIÛÒ‡•€	§)±ÊU]H¨E-"ğt¡³“;±ñ¢I©²û‰k3È>G¶´ë$ÎÆìì1À¥gğ”9}1Œã¤“e¬Å[¶_êßiX\12\¿^{wI›t˜áÄ4/˜}ò¡²©Íº‡{èá‚|Ş¥ÂUGŠÄZ	e™ÖğËÊbşÙ—´"@¦n
ì–B3!Ç(ä{«ç¸*2 zUêAÛÌID¥Ix?·ü]á]dSUÍ!¶Ü…îäéå³óò~]¸8–0rj‰Çõù¢ã]D3é»ÑÉ”R*š¢Èú{Á¼æN€à«9(¶A4OM;©ÁËú~Xé—Ll¡¬îŞ†½Qáıöæ•óòÊNÆ3ö"ñeLIéBÅH€-Øhê#%ßàD%œHLÂZ´èqÑû7ÅfÜ<¹ù^ò'¡†ÇáqcGÂ\}V5îÅÿ–‡‹eP(”ùŞá‘¯CÑn`¤CË{2ÂÂï—ù˜J®´~ƒLop·˜8ô¢ƒÂpg9ÒÙ6O½>¢Ëšço'‘òø6–,ˆ²I9N\ˆòÔÛLÚ0^ ô]½|k:ß?Z0Ş+}„
õşè’œ¿tJpO-ÃÒZãŒAØn¡ÇÎŒw ^.#ƒ)aõù¿É]k Í*®¢=B,ÈÇ)ÛHê‘–¢Ñë­½M›İôÌk|¿Å\•·Î ·¯ÍóV'ñöƒ€kiâÄ3ëbaj°"‘JÍ {¥ër#x <jn¥eq•»›÷È÷µXÕ€WÑ=¾ñ»ÀBN!aîG
òqQu`.A‹ Õ†`#xä_°ğº/ZF :‘âóê¨Ãja	cL®”iéxl¤¸â¿XrËÿ‘®]'ŸIiŞOšÅ?Xù¢"íğ•ÄÍ½ \3‡XÅIÌR2ëõ=0C•Ğ«aeY Û}rÛgÎƒ=~Ëàvc¯e}}V×V—ÁÑƒ|¬O:9œ¥Eßd‰;ªä-¿€Ø¸£4Wo>ô‰ëE‰xÂx3nR3ˆŒc÷Jtñè¤*RßÎ oæP]»Vƒ7Ì\È#Ìù4ˆ>¦×éxRtÆ(±¢(ÎûƒÇC¶îB¤¼Uù+×~ù@ğ)€ÃrïšŠ 
­.ŠjHÒUÈª­‘iã9Ø§¢«[<ü˜Ú4<£¤”Y°ö…Z˜<$âÔzt.½VÒ»J¶6hûÓƒÄ½~è¿9.ÉOÒô«½¥Ôç#$sTÔERZë¢JÏj_†Î­GóÕÊàe‘ˆ•ïCª¬‘&ôaM…u­+)~M]­$m*nîT'u«a]æ¤%'tË<:¡#Œf1æCşHh–YOÌi((Òƒ½°dI‰¯„R÷Y=qëÌÓ¶>º5²åFeœjX­¥>ÊEƒ'“íÊNìÇs‹ç°Ÿÿ8fçööœ–º'úéÛ\ìT¨ĞjÒn"6<{`=Z³Hï?Ë¥Ù„ıÇç&7Òób$ñJİ´vÂŞJ9ty{X}mB·cı:Ğı¿àE3§Ãúµ1
¢OquŒZwgò$ ™„'æ€ÓC‰¤™AßËæĞ«Á€Q®KØÇ»§çP{5§uÃ-ıñm¾²kÇÚ­ñ@nd™=cçl ­ÇQ«¢ã|ïİé†¶BˆU-nòÔé{ [ßôˆéjRRéˆ¶wR(jo[:=qM½B íBüH`8æ¤x®ém¡ùq'€ÅÄ¾õän4û”sÂL—òtÕ“9Ò&”Û.?3,ì¶rNİãS»¢ş_óúàÉ­=+	ÕÏ(ØšèŠ'¼7êÒáx\Ô¦Gh«aj8mïS¡ˆ<ØÁ}S€XØWùt[¯ìl$¾"ôğeŞ“µDğ¸ jÔ²çd­Ü—–9.>CH¶Öh:VİPàGyÄ³xâH‰îœ:Yª€ÆñšZÒtåå3û¥JCüî:yˆ±ë3Jz³nPIfÆ¨}-«–İpû-Ù‹N8‘Pçö)ÉQûáÛ‘PöaQ“{ØçR(GÛuKúÛûG“’éÓ¼Hl¨2·¢Z»g2¹]Ò—eñV×˜(j¹3JÈ0<2··(W@@G*«ıd:/_÷oã±G¥êCØì     ,¹±Ñ‡ ­¢€ "İr±Ägû    YZ