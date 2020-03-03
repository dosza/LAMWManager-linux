#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4183087518"
MD5="396baebd81deefa203f9e1e988569d47"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20664"
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
	echo Date of packaging: Tue Mar  3 02:54:02 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿPx] ¼}•ÀJFœÄÿ.»á_j¨Ù½îê’aWòú¼ß3±û2^ö´lÿ4¾Á‡ğz=Ô"4.±vn[sÈ`H2Üß ?L”U}VB08´©d½ ï¡mb(ú³İ$(÷Uú¬à¼ß¤lÂ¢’9E¸]É<Co7W%¶Şç	å]©ZDâ›¢*‘fÒXŒò7m[,++“/¢•p1‘›©J€;XêÉY¡èa©t–º×HIòŞ°®-µxr|©"i¢–)Oî² 4e¹Û!V4ØMŠEQ{‡ñ9X6uŸe8üÒıÊë¬ÀnPÀVüe÷õ5®“‡¬làTémºj¢E‰¢©¸îFÚlÄà‹Vú <ßÉ«<OÔKÅ›• ±/;…Òv2$ÈÛäQÜùM†:Í„Âësé¸g¢«ë8dFBIxfáûkWèÁôU·â!di
^;O­"¥ÁëXDˆDh6‰íú0 ¼X}n?v3CMYª°LOâù×î"Ût{DĞ™w‰ŸBŞdëÆ¦ÏJíh\³
ìTÒáp$…ƒ?âuœ
r‘†qÂ]00%àÆ4à6A—~¤hnÖl^	›P²s¹Š³Ï.4S“Zy‚lÑ‹}$RºQ€4õq<°™©hyà>'r«õ*ÑÔOŸ÷™ç°f†ûÏñ“—>b¾ı¤¦’
‡å`pÙE5ˆhŠÁˆ¸á›™C©¸eRe>ìø—JÏc…©½&v!­>OLÄø šåYX“Ñ„ìa&7øõ‘KeõHd9áÆ%r; ÕÃ%§ÃØ3++Bú÷ÎÚtêèSEzäFÀ+…ºyl‰DÎ`\WO@lmıu“jq@•ÇKD»¬gâlMJ‘(ÿ‡hé¢÷Ğ";Õ§!0_™½üˆ
y˜¢sq:z·Ê³®8 aLö—ÿR#:G÷_.ªUºÄ^]ë›2fzD&-Ç=Š½÷ëÅt÷íÔ±²}ˆ-gŸyßß¸òş»Ûwfú‡bDÉğáÊ3ÜíC¢Ò&±_÷§Â!’°}Çº‰nxy¯¯ä$"şåÁÿë÷u¢_ÁUoıº)˜%©†Íí;ü2 ‹LÁÍµ¨ˆÑ—¦¾
™%ú¿ú@ÌßœÁ¢&éì5ü¶çgr+~úş&æš¯¨MÅ›üò* §Ì·¹éx oùcR½JÒFa©´`UÅOø`NvùŠ’}OGwœ‡„p²Í•{r_š?Ş
9/qªs;#hşÊ•¥>î*Ax÷‹ª–Íß­¶`†Ù%G6Ë¢¦Iç„IŠŠÒæû*>òVììo¦b­ÍLBª<œŸvğœW
q†^1Ui=Ná9‘õ2³b½x	 ¸-©£VÁË—ÍènùW,´¢Ù¼d`œõùÔW+€ºIŠRrˆ´±Kÿ;…lZ7bí";ê•ŠÚQtlğgQÿ3ÿ¹~»‰/vÀ½nQ}Ëâå$´ö&Ì·5+ @s]šìòq0YD=lş¾‚_têàT»¿ûx8î	Aü¤êúÆó5Yíô&ÿ–ÖD¸?k‚¿Á7²Z˜´Jƒğñı<bÀµI:ŠÑ%‚^ËÅ+õ¿³ÇNÏIáDõ–·Š"·×“£7„À5s+¼ns^4NH™i=!	¢…q·3-ËH—NäµÛää_yÔ
k²C'RvÜè´æİoÕ|†ÅÙ»Ìİ•À¾„Ñš`•×ac‘mÛDHäFŠê yË4P‹QÅ.z#¯	e€G¯(,Şbgt§#İ Ù¨ú.s4Gw+hµÄ-ÅÔïË€¾£‰JùòÊ%¥B)sEdY/)}0Ê-c…ŸÛ
F­)7lˆDâ²y§U“R‚£~¼@­{5¤4½·.	q5¼ˆÅD%ş‹AjÔ×„0>¼‘›Ÿq8ÈI:ƒ¬Å=Ö£V¡–~= ) ‚ËÊ£TcRªduN=,TXgUºÆê,¹1“ªŠü4ÜÁ‡¦ÍÑ2¤.8ÙªTšzk\–Å8²ø§Ô @öH*¿ä¥q¹ÙªñâÿªÍj.Œ¿lÔóMv2ÖÓ2ÌŒ-ÄÒXêé„Ú\™9¤õ<ª*Íxà`T¢ÜòªŞ&şHºh/Š~°»ã;	8ŠçGdbœÇNí¿„¾Vå×˜êõ(û”1Ëª'Jök™‹¢^zæ37‡{ ÛÎ§¦P”ÀróYğ8Å;Ãü¹&Ì¦2é/â¡”Ò\íâ´aP2±Lı­Kç`Dğ&Ç`ıX™Rx‹2Ü_7†BVİØ[‡8GjêF¬¢d][ëË¤¥}€lŸ]ÏÉ=eÚŞ6‡–zÛ,;‹Å§çw’:ÿÇáO±sæèğ×jØÈ÷¢ûËYXõÜ{bqÌ¾ÇíœÕ¢œ–±ğúo÷zÎkpÛNŠî@«%}H˜İ9„´ıúÚ¢å>]Y}à°}éH›œu«,ÜÂ:—…º»Çş£½»D)Ğ|&PÜ…×ùÅf†±4şÀø$/¹Çwş™ØÌéÛb£ÀIl´pj­eè–Ä=ÚÆéI#äP:Æ™Ô*,ı9”:ºÜÃ&ü79şşóC™ëµ+›»†"ş›îdéGÔ|õÊA°Î}ØğeÜÒ1¿DdÙœŞA[Ğ´$[UÌxèıÁñÔ:ñ…üÁDï¡l2â@‰Vã.³P¥Aç¾§³•Úƒæóô€tâ;í*X`¿
KVVû¢ºGÃRÙ®ƒ€ñ
pºâ…×f\J¨ˆèÅoP[^”­ªgZ·s²kRïQ¨Ÿrcvº—†7ì1ëk­XL®ÒEP÷‹hÜvÓ$¸	ß:TBx±Ïå«Ÿ'1Dùsiä[ÓíüúÙmP;«ı¬ÏJjÎÛÄ„§SrÑÀXŠPÇ¹ÔOzäFï’uG¯â[{¨ ,ãRõ¬¿0åãÉqÚŸèSÙS8é@ÆÂUò:¦äbûïJ+ü%Ö´kQÁ5¡‘r"„ü UĞÑä-°@#‚Â[X`?\9ŠìnnPúkãB©6§ìOĞcAÕq°h¨ˆ_Ï¯¨YrõD^ÿGø¡á
lÈIÁgÕ÷Ó4Z§7ìÑ»ö§â¥‘;Öˆ)6óÎÈ	³A¤ôÀ –ÓRT“ºD"ÆÛÙÎµ›»#àÒÓ¿\»éæ=âj{«O¾~¨h7N»
XN°ƒí¤p®PJÈå]8@T‰8Û½q˜×€KúZp{l’Ğ S¯ç¬|³ÀÏSàk?y˜§GÏøÃ¡8ÏÜ¹„âR8wÚ*†Ú7~>Ü_ º("4å_yDK›Ä?úKñ-›m!(=à5È.(ûÏäÈ2æ©íE(ŞæŞ-¨_ô¨z¹¹]÷b?O°Gû³ÚdÅÌÉ¸StÉV„³±ï§¨;Øä1wmq0ˆñæØ´I?ı7Íî›#ï­ÎNA¼ù°—éÄÍzèâç¸¤~Š™K3ãÚ?­Yö$#1;ù£  &)t‡IÉœóä¼kæ0‰$
Ş¹†İßCp›»t2òşˆdHœÀÂ¥°D
¶üÛ4Y<‚Ğq¼ë#…Í¶ªrÍA k‹Èã ™¸%ÛCÆBˆÙ&~]ÑexxPº*¦mŠ‚Sèú½ĞàA[Ã”ÚZ®úıÓ›ÄD6+o…åÑG¹`÷œ—cÂ"\R¹nI °:ş”#úm?úú<şF9¶U±EÆ\9nIÑÆÃB¾ı
C ºšıÄ\ğæ5pîOOİÒ	½‹a@$œÇ¢¸QşP{‰e¯Õ`Ö/x²W¨fñ;}VÙ:?|Ï]yÈG«"{P)fõîöC¸Î¬INŒıêRSv¦(xã3ÒÒŠşïİmëÎÔeU ¾h ÖÒvÒ")3v”w’ôrşhõ…˜Ÿ,¿‹ú²É¹¥fRËƒÔuwº|şf€zÖmgÆ¼”GÁIUq‡P~ôêîâÜ}|ø0›M}p@6I0I˜+‘8\<iÁ}&$ë>t/Stêéê·Dn±<!)ß€ü&ñ¤ĞĞGSCtådP2GHuÎÔs€é"Ğ=ÖÅãjMÊ˜a<bˆ‹ëIº¦™wÀ²'¿Ë·XûªB3ô$Ò@s
q¡mfp»›×_Ø0Š¹6x95Ì4€$·éôÅˆ
è2GùU-&§9;?©	ôè&¿
$I†¾l¬Ñu`¡ÌçŒ½„œ“ƒÕ/%:±ËZ¢ãœms«#Aœ“³>U¨/”N/…
4€¾é2ÏS¦¶4[	/ôˆVê¿¾lÚ¬'’í2 „ÙüŒG;²ÿgåÅ})Ñe‰:ğ‚ìd|pd0?õ„Ó4—Vã=£/JœìäeZVæÖ‚<¦İçZ¶wÇÖ–TaûÈtWJzhn¥~únŒœB»#±__Ã»VËŠ­¢‹DğûĞÇbBI…î†•)ÛG_˜É—iÏÁïëî8» ›¦!Yg[†w¦,z¶p@SòŸĞş-†oA%@«ß¿8µDc”&»ó¶I&I¼3íÕ„K6âl­
.¾ÕÎp6@òoıÓe‹œ‡ûú?‘ÉÌ½9ôæ?FëŠÛ'åÃR×¸xÁÎœ›êtï  ff`<çÉ‹"Œü‚ËhSHa›}~U¦›æ–@ƒòv0Ù–M~¯Õ“Ÿg†Ïw«ÅÏ‰}×ã¼Õ>_ƒÁ¦^^9¦Ş´97ËÄûô¹İ<‚$hñô´¹Àç3Æû%fa»T3–j%é;Á4xEİ•ÀğÖ×$§ï«ıR©áœØ¯¸Îl­å£=r¤³ÅO$xñ¾DÙ/şòVGNj ú¥éİë¥®Í×ìKm ç~W&4…ÄÌ˜4®ÍuvÛaä½5 ›Š¯Ìÿdˆ¢ÿ,+Oğ[VÛóu\ñH‡¡>I%… İj\v0#¡H]AÇÍ²˜"8tŞë7ÜƒL²ûv¿“Ş—ø'8Õ‘à¦T5i2ƒ
^%œR¨L
&}yà‚T©5Ô²èPµò¬¸÷×ôjÅCÒ[1Äóo‘±Ø0ÿ¸Ä§‹—50®–Íaóş%!ï*:GH—‘rñ”v5÷dTm¨Şòä©å¬ûtQWB/¡TçŒ€çïãÌÇ•=ŠÀ& ¼:¼póÜ·ÎH»¼{Ú”¸E™x)7‘ÔY!&Ù§J,. FĞYÄÖ2÷ˆ˜oxØxÒÙXLx•‰“'cZ|™C²ÏiL:%NG’­¯Şfóê‰—vºy½Ğ~¯'»İ.®ƒm‡ÊYü¯ç¨ah™šÈ…YMÅZ!†mQ£tÅÀì¾á‰š7úÙä±'©Å$šZ¢QLÊ/ÃÁÛ*WŸ7Fí‚Š¬”’¯¶úy³¹U=­N³×¯Ò³ŸÍ,ª›ªËy/^–Tø[XÖ° ˆP %ÅÒÍÒK*«pz:*ÀP)¼Ö*O&“iŸƒEgvõåñ‚>ÖjÇçbî©àE\W±sğj¤&TGèË€é¦Úc€ãˆe{TFJ´¿ùy=–q	”ğë¹ÓêçôkxDıt_Ö³¿bc¯VïlŞ‚‚¼„?zCfø5 Ä6Ë. Ì7Â#Ÿ~ªÃPEõX<¶Q,º4]B¨n—ÈT¶ÃM#yÿşså •™`/\ÈÿeYx¾ëõFÍ/¿—éı Õ#Ä}urÙ%éAxƒ Àtc@êVcM&7.ÅyÄñrö¢èBf6º¯f¨òh!*LO¿šºäï Ö©VV2/AµÕë@6Út€gº5!eÍ ÊÎEèC‰,åÔ¤·ViX”ÑŠˆL©’oÿÜ>XíJ·ö›$–} á¼1‰ô¼”Î8,³#y¼Ux¬VW ^`v)ÆÂJ¸ODé	•ôÆ@æ›ó;œÎ¾¤G˜Ûğê —‰êŒõš>ºXÎ\hé,n•í©Ÿ÷kœ$ÇBËqép33x$†oC[†yÄuQé.şû^¢½_»—BŞ‚‰®H‹#>@´qİBKïü<e(WØú®DlŞÌò£ÒªSë=kÏ$÷&¯™ËŒ¸*ÁÀCZ31ÈÇ®Ô»Ú«Ô.R9ôƒ-…¼œÕ®HäQDäÆ~XÛå‰ºƒÁ±ÉÑxó)€ ŞIıĞÁÛ¯Ÿˆ9Ã™<ê€58&°¼}7áğI; ì¦E*¤R¥²C‚­ ƒá¥Àëôt…¯ë¥ÓèÏÉ?iqıe<­â¸J¶~qxm4yá½lÖè¤ï®\O)ø”=ÚÛH™V×Ô–ğ“E!UWe_/Õñ5Ï,­Z@/gdàÇ¦¢èFCÁÏR»D¹öL’±JÅz»ùPCú+¡°3Ç/‰1^}v«nœI:Â»c¾œPQşÙ-°ßá˜RbõWYo_Hjæ»—T§'p¶JÀj3¤^UÅğÿ‰ı‘¯!¤wf°5À ì¢RúI¾^œ:“XøàGØ¦zğOH°eå’ğDÃW«±°_óÃÜöD•\æµu ËÌåÍmò‡Qp)ÒM
~ÓFíÏTêPüÁÛ¸Ü>ó(4@†ƒ÷ÁUKå4.·¾üÄÇËseTBgB§À×Ô(p†µ?x‡-™ïp ğÇP”¡ê€
å7hòN'›TøùaGô‹ÀÕT' ƒÖ®œ¨¼CëêÓ‰¹k¬N*c@ì†`JİŒÛ;ï£s”}ès˜ß ÔøG¤f]÷êf]®Ÿ‚Ëñ­Şãë²?ÜWH4–™ìtB{©”vªğš'’¥]÷7PYvU/	äZÜ%j8‰¼±3¥ÃíYà
Š«à¶`p$ãÕë·wœAÖ“”ß¯Š·p[èØ©_cF-Üñat™.TÔÂ°ÉëHîyäçm®øgEK$ŸT×KÌSÁêú*&2Tö›æ Ly'àe´±¡¼x5I
^h,™ÈÌÉà›20Y*E7ˆŠ¿­¤úÀ¯¶wóé½Ÿ8wa¡©‹{WGNµ¯˜äêÜÀç~2ØÀKçÖ0€×hŸV Go’şã’¦Üæ@Ÿ©|ßo†É¬ôò¦¯\ãúÖUË(üi«W{Ïk;9èOº¦œe~&í£"V¶ûUOÕó|ÈË1È˜„Ä İ<Ëëx…áÄlŸş³oâÀ®sø/7Üğë¥Ï•Ïû1şáfwßìÕwÚ"È²6A	¡.ÜäW9iê÷o¯¬¶lSuim‘4C(sBÀN~±†™œ¯eA_Ü¶Fiûbà]ÔÂp8€Ïüæ„TpÀv½^`ÚSéA¦äDñ [B¼ÛW
sÇ÷Tö•øŞ‡>ÿ&Äè÷‡Ìÿym×l$â9S„uØ½ôpå'¤{¬>kÇØÏ­T8*»ğËîÈ“|“æw!ú-œDÿæes°4Ã=2;]İ)‰"5v¯PMs¸GQuªi¤É> ˆHÛ­lTÒqü7a}í]‰ZOæ½ã(åL‰-À®ÉOğo½B®“‘×t»¯RÁ‡¤œ$f,HlQ‡è:}—Ÿ‚u¤xÒBë¶c¸yû«âÊú¿è¼Öfğ#K^G‚_-™WôbíåıOŸUÑ+x­ñ{œ(¿LM”e%2³Ê"’„¾g|ÂdP?½=«m0bënÉTxu{k¥ª±ÉÓú§z^ƒobÅzjô]±éÁ²ĞL?¯åF7*³"ÚÛ[CÖÿz?Ë×H<‡%QJæ_ˆ$ËM×±€7$÷Üt·g
‡ôÂ¸Mm«ô^3HºhÅ¤³Ö(ğ%—ğ¥©D½x‚]…kù.]A³®høŠğ£á,ßG£´£jH!µ‡¨À©yL¹S¶=pDÓP™¤z…áM‡p;;O|>UTñOzo
úÇä)j'şı	D=šıeõsöóOòò¶šÉ’8?§~%O²ÓÍ©Ñ«C²ÂÉXb»?Çñ€Ë¬wBl¨˜<‹°ù„ =€&7+cBÁfj†§+–k¸Ê»ş„¾’õ f+ôãYÌm.{¹jY×ãéÆU—^W@¿#m«>„Èó•íæÍÃ3(ö]€™7ƒ)t©‚ş&Øğ—R®Ê6yš]U'è*w
lL§Z×‚›¦*(ûô¦¡ÙMCn¨7K€}¡6üë>Á8ïÛÉ`u¸bçR›î¤«É­·ë)skuáM8YÌª„mp¯ÛUãÓ$‡oÃÄ_2œ TLi`ßÔÚ¼&·=@Ù÷Àæ‚`Ã¡ñâ¢˜ÇœĞâŠ
K •¿”fnÚà¢ˆEÓ †fHjpJÇ’‡[)Ûî]³ßYyú—2Š-Ğ÷4^èõà«7¶¿ÊrgßQ·IA´)!|3bÓÎÜ6zÇ¤åv“í<„/„ë$øí'é¦¥µ8QÆioÈC¿=bTmTtƒÍI™ìBC2³‹…Eœj"`6QQŠ}ÈkÀÿu·¹Xñ 6~Şº“=ĞÄë˜‘ˆ^ÊW&£ bše÷ï‹Ã!İãg¶{-~S%¦àm)~W
-,»Txq’ÆIUDÏ}zHÆ;Šj	_h ½r“¹—=Æ%°˜v‰p™¢Nì¥#Ñˆ¤9xàDñÿòÑ©¹[‚aÅ­ÙK`È—ÓvÖ@x¬c]ÜVØ×ÓX…	B 	*ié¿/ˆ»öİRãlŞØ şsæaıùµÌ‹€ù#€c0K» LTØ±ä×6°$=¡ æ¼Ì á6ÃÇw+7>Ë!¿·†ÔİŒ¥Ù–Ûª‘[RÅÒÏİ¨™gZ{ÌQe—÷­zĞÕsı[ÄÍrÀ1 «¹@üìÕ~Ğ0“b¦>¶İE6l…6{”Aíªõƒá˜ıà¶ó˜†Ûõ½¢â±FÓd³,´r'×ÕçJÚ³.ËªæmÂ†a<%fç2Hß¤G¿‘eÿãµ¡xÄÆ«¨ßØıÖoº0$‹ìëÚï¸½÷8¿&¾8D[†2”ã+¹ëïMYÀê¹iN«Ş«Ú¼;!…ö˜=?®}H‚ª=ú°·#A†ãK¬øFA‹ö&¦ı"†Ëo2)ükläÔıNÙæ }{úéú±'d«º¡±æª4´àÆ#f_4‹~%ABA–âdÁ›,ÓèDL¢PÓºguÖ¼GëıZ¬.Ş¿ÙM×ˆtÙíç©qOÉtf&DQ0Ê“}Iñ#<©›È¨ßÎ8˜gÌwOş“âJ 1?Cà¸•Ò
¶EPeÌL++8oá‘U/Üî²áNôÁgÊ†/ß7`,‹à‹{98x£ò…¸F}=í…/ØğÇ†ê:)5bì…ş$»­fzNXƒIªÂ\Ô_376ë‘Ì¯Æ©<µ©uÃ¿÷û¦&Ñß#xåayNR6<Œ»¹ŠQI£ë†<ık§mª%Øä)äGÁ¦…ìl„°Í”PÍÆ;h¾sGÅÒ‚.1B¡/•u!‰ú^âp­ƒ¬¼uÅÀñ¬¯û+p/
Ë£øÁş°œ„[A:‹‰¶TW!¡J×-ew1< \ovœÒ„€>UPìéïº´¨ÓxKŞÉW<Œ£ıY=Ÿ•aÊ°w=D¬êº°ÿû>—Ïj‘ä^Ñd=8q–ù!@vË(şİğ§R4¬&,‚3ñZ¡zÊ«tĞÜ£’E£çì³|ÊÉoÈÇ‚'•â&/bQ‚Oş/I•’wœ½ZW¹sÍÑÚä±(¸bçàŒ˜çğEªªğ%¨C¶¤ı3Ö¨VOÍM"•—ìX2Ìê«í¿í-Ø˜”Mø2ğ‰\
¯ù.k£ë)Ñè7˜“$ÁˆXo\Ç#Dù¬‚€ßl_.v–.9(ä¼MÏüpx˜}å e³MA
Ôª$¹kìsãİöâ–d-JúR¤±‡1—£,½¼à÷˜>Kée4Ã~0¾´cM8àÙFÆàg.Õ²V€±BÕcóGp£©Üœ8;ÖóÃ²r®úLª0ûâşÅN¦ ÷èôH÷ue,óaIn;¢uï‡ŠrÇÎåŞíVıõŸú, ÓKFåşQ6yƒ›Ã—±ğ¨“aqÀd–ÚŞ‚hÒ–“ñW
¶Ú#FtˆX®3ò™äçraˆàØ£*B{sé@ğÀÉ¥€q¨³1´Wîc}G‚şdêLb
Ömíyµ2¯X$š÷¶Œì_)ÿNH+ şZıÜm0¾²ù³ Ö§ÜÏ’7ß—ã%N§	¯ÚÌØƒ¥Gà1ká=UßÁ|Ïù:DÁêX fºâ‡¹ûTLñ.H @§vsŞL.>±±b‚†˜b—V<dËPÉªãÀÛÇé¬h¯Íš@ş6ôÓø¨ğ'±PAI~­(@8„w—·1*PàLQ½„²ê/.÷ªÔ|­9Xø¾Ù‹ë°G{PˆÚGéOaÁÆü¿ xº-«”ÕÃg‹Ïä	ÎşˆG6ùŞ£‘‹½-\°>ÿ¿Eóƒ„ÀĞ‚Z
-ínŠ—šôí¹ùš#„ó¢´[€@“‡p¢-ì8ÿ-Ö&jİ²£²‰ïÉ$4}2Y¨ß5,Ğ6GHHÕ›.g;T¶wÛšTx2xójd¶1Ï`¾›{m–¿©³­ñ”î›O o{‘“=»<J‘Ez¦Æc[V©à3e!úCø†KvSÔJÕ¤8K[.ÛwÜÛ.fÁ•;û(°q¹„dWq×ûİ²f¦}F$wPM›îA a¯…£’ŞÔŞ®YhJïâA` í“J ÒØ­áwPÆ}m€=¨8v@Ë×+ßDÍ\‰_Áß¿U—“<8†•·°+.ü}Iñ	 #W¯İQuÖá­ªkÂğı%Ùïòª(•4üò¯İh3Ÿ+8ùøt¸b$ö‚rù ãOüàÃ+Ëò¹º[‘¿vV•»àË˜Ö$óÙ[¬µûªğ’;àH½Å+içµØò“âZ2Z°-cˆæÈ¡ãñzkÍÍ€¬ôâS1®´Kàf.ğÙ1go‘] ~ÌÆ Â¸JôW`?PüV×ñ}»xŠ¦ö±§…[¼9tß%QàÒ`¹ùË€ßÁÏ†ÑÔûKË¤"ÿµ8ÉMµB§òáEjhí^òU÷p$`
şvİ!8Ö›‡
Êæ”w-@Å†•0ğé ‚1²§·voŸó´'ePa=zíÂ=ìèÓ_ø8ZÇ@¥¨bÑÄ‡ŒĞÆÀß˜Š¼ÀƒªÅ§è›¤Xd”¨¼µuÎÅ".	¢–Œê|ÊÙx8¥¡Ç ŒˆP­¯ÌıÑs.øíæ70xYğ¹s2«¬çÈ¦"éÒõZƒÖ‘ar#‰u‰'äÀ(ñ6¦A°1íÀ¿èå¨š™:yaÏawyät·hn[ `F=BK½ĞC®‡p'FâÅ¾Vp&Xíƒ>ÏoÛ¹g²áG¥Ï'çPòo°² )3D£ÊéMüy¨ÌçĞ§Èq¢2÷W…³£w‘"}?¤/ÿÕW«‰y¨®=PQİCú"3f,Ú¯1ğ€8Ã‹aøEgëj°PØÅô'Ğ”ºË2X~W ešCø–œQ3t‡r®çYíˆz>î›t˜zÍ‚"Qv*£fCä~.wZüô»4nlg4ÜÄ©Ê¥`«˜ö¿Ö¥ˆ˜r!.ÌãìÄöâ"¸6‹Õîéğæ\¶r+šçYÄéÙÖNW†›ÉóğÒ¨~SP[_íË ÿv¼=	Ó%°•6ñÅt"F¢ô/ÖßÏ«Ï;ÈÀ¦³_wŸ¬œ‘F)îƒ«í_ì*é§ìyÁV‚V„W¾hœYá‚USÉQpÃFÄíü¬‚½ˆÎR?©¢¦kêÑÄmiJ¾c—j}P·rt6fq‘.+°Æ†nHnıç^µ=A.U¡ræÛL×úÁĞÔÃ˜R°x¸.2W¬€*
øÔÓ‰HUãÿøØşrïÊß"ŠN¼İQ©qkúh8&Ö§¬~¶'!Èà;üthgÏb2Zºé-YöØXd6˜pÆ¾lµ–Î¡–0üVœ¿tâj?GzÙ¾~}0
ç77@/"9fm–ˆëq¾‡xÅS_›íñzŞO‰tê0ŒÛ&ôY¢Ÿw¸ø+Ë¬+óhÓ6%"+ƒ­9U#!ø…‡Úö÷ÇŒRaAC/<¼àc…¥	õä’›÷†+oãŒVj–ŞL Ûiù·£’ÎNšºYgİ) ±,^Èào¢.óøJéËÙX=ÏIÔÈÜĞT±™ÿÕeµH\]Óî‹¢,_¡Èä4añ…‹
>6á(²x(‰LşdçDcCc*,´rª’ş[íÎ2YáRS’rÆ…3…hn&+.'>úŸÈ"—;„TfàH¼…ëˆÉ\Ê¦ùEÂ pƒÖË+3"¦§<e9Ïzoëñ¬—tØGÂÜg|7/ãëîí¯ÿ2a²&	šèmF¦Õ7(±µç“¬gr«Õş”ÿ(ØÉ¥a!ÙÚº–ç 	0µ‹7_Î},S˜™œ±Ru«Íãm ¸-b–tnªFÔ~eÑúİA´:‰G‘eŞ^Fò´)®©xr'©¯ìiÊ{«[hxBÒƒlA,IU!şqä;Îzf07î\õÖ¾¶7å¡üôs!ö_îDğqğ¤IX¿dèhÃg¿ÁÃqD^Øv¥‡1ßóÑøºæ·¥¿Ç¬Y?èµvãKÜ;@:>ı$ã¸ID?]÷¾Öo2<"ÃÑÏµÛÖ‚ÎåB"¶n{<ŞÈ–ÊøìRÎsy}LA
rm™—µÜÇ$Á6È8+8ò½^uV¥dFÌg%Âyä8ë§k¯ã›˜
œDßOŞmŒŸŸ£lL^–’gÙé&ƒ¢ıE9æx ¤ëèÃ4ìÑ¶Ç&œ
í~8A¨=’Ÿ€ğµ¿öĞzĞ×V¦¾û’Ê÷ vé´x#±8Ë&@rèTxÙô«…§H(©›}{ÖàC±÷£ÓbOsë,½İëAr$ˆëÆµW™öq›HL#‰:×„,(a°8‰Ÿ›YøœêïÓ?Û-eˆ•Adìù¾4û¼Oññ¾'¥ltX“âá†£vj‡¡ªq6®ïíÍ5ß^‡ĞX–´~òEŒİFªù™€²{cÅk”5İ4JXØ$¼0»ãwá@¤ÖÙk|Ú+’&.ÖuDÜZÛ>e¿ßÑ ûA`¯´ìi7»5‚»í¬Ò„Xä¢Ğã¡\ÌmTHÌÕV›û Ğÿ..=ôËd>ì<ŞÖc„ÿ¼Êòí\Kãc	¾Ehˆ<†;8nadŠ±ˆv*:'q™q5ZqÜåUË+ n¥ÛÔ³xKY™ï#³˜-%mcÂï¶XÜ›²”¥ØWŞka¾ğƒf Ç%òâäWúûW‡Ë1U~÷8æàáö/ÒsRQŠ“Ì4vµ®aDûß¢S_dÅ>˜Ş³aÖ0>ÈÃ{Áfy€ÛML1ñvKNè
tòôÿ·<å®ÊÔ¶Ê@ÿBÜç“|äíË€EwÙÄ¿ËQíp£··ïO÷}I;°pVXåÊ¥×Ùiî¢®>ß93¤QêüÇ¾HoóíN©u5y»ü„¯ºæñ§fkçêP4ÂÔÒZhFÎ5¡ºV%câ×¿àİgdE:³±Ñ÷ DqV.¡\‚ye1i{XwÂWBç9g–¨¸º7Dí!d§Rs˜0Ãã¨5…ÃÆU–"ˆ )’E¦d [¤q9’ÎT•m¤Š¤r†Ë¦¤p-¤(î3V•ĞÚc	¬Æ8rDğ¾ú$y>^X’ã £:w-m®¥H’ä>æÕxOİ0ñMk›¦¨w¸¨•Âo'2†î£Ëµ>’êMq¯š¯÷|z%•£ª* ü†m|Š2È™b$8|ƒ‚ñ@&h³ÿJmò©—³|¶ èaQ!âÛÏjÙ85M0W`˜
$Yî‰íÜ`’rÑ
œ=Ékb%ÔšÔ<EøqŒ-Tïï4ÂNñµû«ö¡Ø˜ 5h7I=¼“Æ÷ËŒú%"ü»éîs*ß‰ûe½[Ši#ôÁŸ@­Ô7ˆÇø¸)Ò°¡p„FªÈ{=ì«öqºÿ™t‰=cŞóÑm.Ë;}¦‰ş:¦HüáN§›ÔÒ‘U»€Òû_&²ÇÔ ‰ùÉ7üHÌx ğwäúk>£k|´‰vØÁÂ·RÖ•Ñ´®Ò‚4¹¶^M’[®N)FMÂín†ò¶D½£'Á­f¼<·2’ôQåûA$h~àd¨’	%„iEÓ·€•İš9ÚÓ¡oÀ<"JUvÖ]‚ç¹¨_^âÙ
„µã Õ­â½šø_)¦`Éß—e/4ìù.ş9Z}ŸÔñŠoP©ı‹'ûAë	>-íœìP/! Tì:ß¸¯±>MÃIƒÒ	¯DßÊ-‰Yõ+ç¨Ã­HÜÅ§=¶_‚ì8clÔÏOôµ‚İÀÅi‹W§®´wDãÁÒñú¿6Xc$»¯I…
`ê·ß?4„ûŒi#ô¡7‘·ªúvšÔ‘Ç
EL¢n-ø•
4WqùQqi¦è§¼{Ûoûä‡ÇEé8/Î-P,Æ‘ßÔ¡GøÂoº”Á¤Š œu#TyûXãıÁK@+-X_
­pæG Õ12²á:º<´_xÅMF×!( ßÒÌr¿¥å!¹Ó7=ãì[i[ãw—F7¼ô·wxÕôpeÚFOì[ö™¤qø«5ƒÁ±ê 8Äç°ÆÇ±ôG22H·Åô)äsFKJ°;ÇfW¤³„Ÿ]Éóõİ4W‡oƒ`¢¨Ğß	ÍÈ¦rW¾xDÀZ*_°Â{‹¾À¹tQÉï"µZ;yä’ó¦^€£7†˜B‰#Ft;%wåÖ&K*ıÄ¿àöÿ{7B"ÃäOìOÁò‰'y3ì*ã·iá>z&R2¢Ñª.Q’.Ú{NS2±ùªttä	<59-9ví¤$”ú1šÜËÜh>Ãã¯ÿnÄäÎ_]ØC‚Ûz¥Õs-«t'šp$:ÎjÁ}tÒx)z	ÔÆ( H2,W¤‰úê“Û8ú(v	 $±üc ƒî®A8Oáçµ„5i9èöœùÖù7j8sç¸!"Ó!-üJD_W@5@¿J(¾$Êæ:>¹yß‹dm¢Jû{¥!ˆët½jøT–¹V‡šTñ°$3P%æ
ècrSŠÓ-ûØÿãM›©t¥niãSnóµÃŒó}½ëY8P§ïóêóqÕHp·fòğÿZÆ\ü‹hÌÓşÖ+|u…7‘T|Eá‹é ğ—æQÃu3	i@şqÏ§ÅF©p'8øØõÒ÷¾ÃÛ¨­8À²Ÿ‰^ŒxT~Æ7ƒ¯³ßÊ[¯J“¨…·^kàçVN£]–}.!ı>HêÆ¾d}‘;È\€8~ÊîüMİ \mg‘Õ®Tœs\ÏÜI‡Ø‰ìÿÛRû‚³P‡µ-W[ÓØDyY¼ºJ˜ª˜)¨ÃM+E²tÓTW+`|eÍˆ?¯€ 
Ï†ì£|ØNasƒ_"ÚiS5 E§Aã­|æg°aì&’b*v´
çì^Íû Ô)z®èKˆıoÅt6óRÔ(˜ŸÍ¡ wÃvÃ¡¬I'6à—vL*p x®u}7ßZ¼Uø+?ú&Ã•|ÒØf"@o§æ,º—<CIÔãlHqÄƒ`I×÷ÙOÙdà×ŠJ)ú…61¡¡h@ÛœÏ¿pà¸|GµEz4	çúy>ü€>´ùIœWÆC~˜ƒ£óéc äğí-”F©iˆt®¦Øºc5ñU—¢É]qG9ù^å1$Æ}ÛaÓĞx/PZƒï-xåVÒˆ¢‘G·Ó«/¼L~ïÓÜä²¨Ç–@£İU6ÉO¨úí"\¯€»`€'ë Ú·g¢a?x.LH`Hî4l	  cù÷¹ÙmËÕè8Ôb!IÁ?¤0ÑCN6Qæ·40Í¶r]‘,èÈ‚}ßìLÛkâZ8bm-ÌËV8)å‚4‡w`Ä™ù¿Dôru5ü‹=~åD0æ^d\}C9ß€Çö ²µH ğŞ‹öAÍcøÕİ¾Hj„Ò‡©c2…4¸mmbiÙúDëŸtÀ †5ŒÉŒ1<Z·]•™˜Æ³c7r_ƒy‹ß¡å't•~û-4%?ÈĞğj¸‰ş:
öÿ°Ïb(XêúÔ)ƒÈµ$íw½_#’lÑ÷¢L!]åt¢K%†V<²£9áÇo:uuÙ›ÔO¾Gü‹‚[8GG˜ØßÏšCE˜-ç,1Fá¡0*„Eû.³à]öæüå…ÜX øm[\Í]±}eŒxàÊs09µá­ß„kä!Õ™xu•Ü­ƒàÖ”Ây¼C}¥\›l
 ²c‰s^¹Á)´Ü¨¥<öêœ£lËkåÑ”°–;„¾Am}.v®™‚`i¦Ä¼)Ø]Ÿßüˆÿò Cucë-=Î˜"ÛäoïÅ’7·É“:`ÑìéUT½ÆÑM,ì‡Dà÷÷éÄ¨ãí’İçñ6.M°$°åDÿõ–‡©´|0‚Ú@Ü·E«oVËÒ²lñ#óˆÜF¹Uˆy,ƒØX´„ŠkÁ0Ïµ0„¶iÑPºörSn–yfK~Ò´Ñ¬tÀƒi™P!UäœhäöLí°ï&Ót‹XÄ#ĞïÍ*ƒ8»ôîƒ®ËŸKSÂR´]Dìz»"<úèÎıl^¥O!hé^"ŸQ_XOÕ-ìP\†Âå‹Ñ+yO¯XyºÕïÉØóÒİÃlÌx@°ÛÕ<-ò¸©â\ØJÜË£}|?CW’xüd…UÅn¯n¤P‹Õ¹˜‘õ7×~©´‰³S­º5†x2ëKğø‰NÔ´ë¤Á8¶ê·ëW<Va’”ş¨ÿ]tÎ’êØw'æF³hF-Ò¬ÀÆ›õóˆW}÷€İéütÌÙ\ú¥İ‚˜9Œğ8Æ’³.­•é´äç+m€DÿÎ&qŒ2GÒHŠ¼.nû…ö)ÔŒƒñmó“\à3âJ(%æø[›o“ï7Ğ¢µ!œ>6ê…u{R5G2»ågªf«µÁvzœ”:77"©öÉÆÁ¤"¸Âñ–˜«¥Zƒ¤)#(5AÊÇÀ0aÍ)C ·Oâ8Ì¬9şøY™A’\‡Ïrí¯l_¡Ú›ÃÙ\ ÷ñüÁ·/t.½âét˜Yß˜[sfE–¦Á£ø4
‘lõJ¾4ÎsôœSDÔhh}û¼4ïNvBÉ¢u	ê¸­&£2ÁfI:……Òê.—È*XGÕ÷Êö–;p•Ú‡B;¤5×ÄóŞÜAŸmmåTÌïi×€m9$øbİa1‚.`^µäé/çÌ ÁA(T®î4$˜÷>(™ÍÍE†I%æö–Ôå¬@,ùzYÿÚ£ô¢¯ò½±ËçÇ¤ıƒ­\şÌ¥d!Iª#ÍAÑæ™v>KP¤Ëöd3j“M¬TBÔ¤çÑÃO ‰/G.É”ŠÙaô7Û¹ÍëÒ1Z#J4†ìí`ÆHvH[¤•^¦TÕq#Am”l®>‡½F,Twş{»Ö¸Œ|¿|"“ÿ
–*ğ Ú˜ßIáQLÜmûFÍî"bêì›)©„¶CId:œ:8ù‡ºbÌØ‘P:×Ã	¯·¬Éñ5hæ»wúö/ì¸\šfÊ¤Â…ŒŠù»èÂˆN¼‚NÑÖÏñàEid½ƒ$I…M(­¡MÌg)ŞÆDàî‰§>¾¢RÊCT5ßË³àÖ’VŞÖrÁç”òTTO•¹UöD69ÇhW	ÔìÓÇµ
?‹¼ÓÂÀ®Ç H¶R˜Or€%y¢xN@NG‰|Iê1¹=ğ{ü© ¦úW‰;ì] (}‘é@Ÿr«k-«à1\ÂzxÅÃ­wh!©,€Fæ;§.ÔˆàÏµø†Slm‘ãä.èÄ§¼é`F¥¸²ÁMì“m~QXóÿ8ËX4oD³À¯­—/\ddªØƒˆÑÖ	w(¾?8õ7À£ƒ Æx…%=Û*2Xûéö³Ş$A/4ÕÔ¡ykm¨vËmJÑg°çzk»éNi úÃÎT¥hÓÂèõ;éÛ¿¾í]ò§a˜QLÄ²Æ ûíÏ¼`,Fkº³~P&XW‰«Ü’;“šõÀGÜU¨‡J=Lıî¯<ÜÚ›¨dSÒ=L€îÿS‚Cˆˆ+Ï©é¥œXN~şa.º·ŒdqKW/ĞÌuBA¼Û€
¬u‘À¡J-DbJi'H&X¿T¾¥;¿ËŸTF›úA½
”¦ªÑÏ—?o»¢Zµ€`W1ğÃª¸~”ÉEW üV x¸(„ß¯§¬ƒš^5Óá–moYjöÑ3Ëµ*˜•Uy‰“÷¶Šîm·V®ëÂÎü¾	úàrŠ%í Lç‹0É4©øÍ‚NÑM€„¡¼ˆHÍrƒ8J[;_ å¿„ökTäZùµ)ı që´yÏŠ&ıtAûM7©"/mÓ|J¡fÑR‘°••µoÈY_Î’cƒş›¥rXWîÕ	‰ÕÛ¢çÄö\§–Q=È¹±òê¥Æ³ş³á¿`f(”®è>ÂZÊÉ>ùY(l÷¥W¸_ÌÓåvágÌé§šwH 0æîw}:s'!4ìù<µQ~©m~©á€ÛöS¾~äWjp¶²Çh`³e´y×&õ›ŸDàÀş·Ú“œ°GıœN,Ô½¡%i•J®ALÑ=Ãñš…U$p@äØ&ÎlmÌtò²˜Ù[…{Íl¹bªÚªY­¸-/> ;KšlÏÆ,¼zD ´0¿šzÈîDQ˜¨ÿI¢uÀ^/kÈäŸz2Ğš5E•›“oPJôPOäéYËFëiR1D‹ÎÔµ£–}ÖØ1*F‹°Ä˜¾û³Ş0k¬áTÛ‡“i~Fúù~0¸ÙĞºşwî¢¡ÒI]¨°ˆ¸,L¬ä¿á(úÙå±N¢(
ië$´¿–‡ù’–g™?¸ñå£ınîaî:v;õÚ;§‚& ÔËƒnÊ13.ƒ…Ü«ŸN¦|´eÀwRd¿aıï#¼™S¿f±1yèß[›˜&á’
xF	:h\NÕpÿü8:ßë°Ê¬`+>j%)jß]/†H’Ì6ó·×	~ÉSÂCä¶22Ü…1epTÛ€Ÿ]*=ErÍ<ÜO€ğ¡&€À½ÈÚï.Pßá4"2Ú*Wõ÷æEš„]z	ˆ€»¦².Iˆ·k±dN©åæœâ5]k+Öh€807¾!ÎõË™Ê×’‡Ãıò;ÓCæ…~¦üÂ2+»ÓÃÃ—!‘-@ïÏšâ²£ú)Çrüí3hÍâG¿xØ¯Ò´î#VğhÂ‡ÉÇ`ØÌ³%>ÓPÈ³¼áÂ.êm”õV›Ü>‡ó×rÃO¡‹Dìd¾l ¦nÿAõû7Ëw-lÒÈõ!#U.É×¤#µñªƒ~bÄÍj§†.@ÿ(ÿŸ]ÀEÛ'¢ÖQézmO¶‡ƒ—Rû„"#Å¹Í2ÈÊî¤¶†ÊC?¯T|<Şbïs[gÑøÚeÏÍ¾7®4Æ÷3n+Á[ÕBÎ‡]?¦Œûğ	¤šàªç€àhÔ¬¶Ë`Ì7ßV>àÊxÎ]Îëöé\‰í¿÷¬°D·N‘a›•Õ¯€P”¸J˜3Od"†ZƒM)Ô¯®¶É£¨F0µÿúËŸÓŸ7HŸµ¨MuÎÈ*‡ÉFùÆ ş«§*a'££qæ@ÿİ‘­'øApG{Ù !r·S}Ùçhôeí˜wéc;Ï
–éĞŒ ªTšKæZÑ&Mg‡0Kà5½†WPrnšB{ŸÕ`v·¶<?~8gTš¥-°Ñ;#?;uÙ^¿»•
¹$³a6·xúş\ÓÄ{¸±Î¿ŠÁ¬ß{ª[>}
›½3%)ÛyY¸î…Uì×~!àÄ(éÄÕ|Ö˜Ô’õ„¤Óà:K~¦;Ñ¼¦£­Ö¡˜dökcºÛƒ˜Š ×¸ôN;Aş H/$·3!´Ù»šüaIœIjDší2|úó~Î{¹‚± X®.ŒÃ´V:¾$ú‹ |“a¦Bö0,£”½nŸ:K,ÊÍŸ—®"¡á©É:m¨cäööL®ÈıÔj4Ó	¨ñ‡µ”>kÍ2×¥d˜)f:Á4Uä ³´ —¼¥¹S¢ä‹„>òY5ùGşçñ§x%÷sµÓ˜ŞûøA©tPèm³ÆU‹Îäk\”CíÖ›R¡(m7M©k–…¼ÊÖZ™î¬¹Ğ­cFı}Ïäò-äkfát´|ù÷/ JÆ+³ÇÔä¼Gî±íÌÑ˜û’›wøP=…Œ·éOûÓzÊë¼'Tî!oõvù6ßIe#kˆwfÏÜ¢t•N#„$öA	y¾¦çÉ¤&ö `WMµêÏ°Èo4°‡İBŠX|Mlp8³% °P3ó‘d6(šÍzbğ¨5æ´gRËHÑµÏàLï²óg+bqÿTOøÜ›È¦>)«öTÛ´'à—Gyo*†ä×™h¢ TM¯Y¥]ò½l³×púd¨>üKQ™8¢;’şƒ·ü‰€iã6-Ú¶À`¾äÇ!ÕvRğË"ûÚñ*ª†¡÷¥•JÿÁöoÅ%…ğ½ûØ¾‡\WvwR÷Å$¹ö‡°÷…ñc†aj,ı„©öH-$¯ïºyİùöÃÄ®;ŒŸMRÔ¡[$"0§®áw(
ÉHÔónQÍ, ÃÌã~˜¤OZ›ÖX–p“–  )¨<?Mf¬Úù›¯¥%¹g¾¦±l74&H1§%¾RÔÒŠãı—7¼á.ì‰·
ÓD5¿mù$$#´çİ!œ}¸'›Â¡Ä,ÿ3äE ^P½ ÂòÊLJôó?P—iö×Åpò“ C\ğs°9 ÙŸE"‹ªTı@D—oS3
4èh¾¡Cº2~7Å¤!ûÀLÆ!8h·Ğ ¿MÜ±±wl“‘[%²CGi¤Ñ7g³5ÔZwÄS·Øİšš ™¾%^“%·UÉh+‹ó.ÍU>dlù3v¯–Ó–Ú³Aôüñ¹‹İb?í¬Ñ¾Rı!ñl4I#æ= $•?ÎŒsÒ[ÉøğE?èuy¾®ÒZİğü¡Ë‹HKŞ«”Ä¾sü°§¤m{¢M=½JúŸ§zÈ\Ÿ¤QªåÉá±.:®Ínõë,{‚À0™ìo‹—ä¢`Nª 6]ÖËq>êQ™A³–G"jüs¡äÍø5©|È9‰â]%BøL¯úuìà‘D‚Íî7şDM*°¿>yEt»üõ¤k‘úË£xhù†æ®éãOkğÿèe9yéÑ Š/~©7Un¶À°•Ùàj)Í9İ¡W¶*'j€¢°½Êı:z<³“ër	ãIlß?ù*äÿ_ ·uƒ¿ÂWÎ"ä<UCË™ÏcØ?Ø¿úM¡)T¶-•Ù©L$¨dà½N	pvñH56€…è)G÷«ív?şLş'Í‘_3¶fã”8Y6i1•´ÛZsî9dšŸ}'k%5ûmBüÄ˜$Ç¾F`ïÿ¡-7ÔR¼S*¹ù¶½¯Ú\²”1Òš+5ÛÃæéQz||ëkX_úş«ßQ?(À³U>›¯Z¹rË¾ä:ÈİïI,çƒìñøT|^«é7ˆH&jñR{·Á­«Şôw³.í°'~¦)?¹ $:ÃVî­ÇQRÑÙ’4Á:À/¶ºÇ¤6üá@Ó¦l¾*UîkÅ&“¹vB÷Ûrä°ŞÖšzi1hÔ’HO‚m«Å\ø¬ÄV‡““;¨òäÈ p„Õ}N¹î??€(TÆcG‹¯¾H&¾åÿ¬}ÍÒ˜ï.±¦€Ô‘ğäÛúˆñEn©Ï)°E™•“Ó—L1ñ"tf‰\c£;‡wBPmã#»7á{vlKbÆ{¨GÖfŞ==Òg£x†ûü·Hâ±o $(0EùajQ›Ò'5Ú'Ûã	Ö¨¨Ú§uéKpMG7ğÒvÕÓ$
1:èõÏpÊSéÚ+,ÚÉXb€{G×xQõİËu†HÎš¯¶¾Á¬Ò;éæuÀÇÎ7:#Qœ¯dİšË§Í^•™¦’R\™û'ÎíK;cüEöjs=ÔAÎq4‹‚euVJUĞV$}i!~ëC  y¦ãÚğ{ÿaõ‡3k%AšÁ‹†Œ,!ùt¤¢%’`ˆx'nÉÇá‚T¯”Öq„™ÊÍ¤ŞÍªC7¼–.(…u	ârqÜKO@t¤Œüh4¼wr–a|Ì;—¡-@uºİf¼Ş‹±ù·}WÜ‡úT¡)³i\m±¢f\%¿+@àÏ¹m¡åœ˜ÉÉ7®è{“€ŞClu$Ø¾]BvvùìIW®äj0]~úğÙ.÷¸G,0¬xÒ³­A-‰Lkøêz,fqDJ0iŒÃ³ç†ö¡rzø!Ez¢:²Ó-5‹îf Z9™D2ÄzŒ0EJtéoÅ™jI…/»<½ÅC¡sŒcøÙ†.%¢¢üısÎh†¤õ0‡Ë}4õP½²l]²â8Ë#T ^ŠÄ¥Ó—6¨“7ÂœfÈŸXWİcR7SgOø¦ÁË§  È?#¾Ï–ê„VD›Ü¸bL’%¤,ObkS\,’9W¢5Šàœ"¬uV†\„ä>Êÿi1…5Ö…d¥hÌ€1(R‘´lk*l°/òSûOÀ"•f²çØÌB£)ã³@”pïi: ŞêwáÊh^'Ú,1ƒm£Ùú"êÔØ§O Bdá9ûms†¸’Œ	¼Î‘ÈÍÆ×IáoL
¦Îò]ÓwªCôx‡ŸãíÆîX!-m*ùn °¸Õ»­H!×üùÛî m#sªıJÍDf¾WŸ2ıq¾¿ĞS’NãcmUÙƒQ±q;élEä³I©+6ÛEîãéxÍ¤—*ZÑæñ
HWÁşŸæÎ¶‹‹Ö®iTŒä™;‡ŸHÃÇ›ş.•ÛÜ—fÃÜmj’ÏUûºs-•E¢‰aµ0>ÕÑÿCŠÖÌkYÚËIù°W»:>C.ãlwN¤ùB¥ñ#öjü†›‘qræ¹…Û6Ë"eêj…a‘øKèÊ^¹ï ŸÂüÄ°ªë›õô<…ÁYìAçÁà—­õ,„ÙKh¢Æµ†ªĞ•ÅİZ†ğGUŠEù<p\3#t78ªã˜5õl#Ÿ•ÈÎ¸$Ğ+<¸İ¾íË»ÇŸ6JÈ‹·WbÃ‹SG¥FL0“!Ëğì'™æÂÑd×‚)KU×î¢Õ´Ì¯‹–1©c8™ÕÍPF.Pd*xª§›K9 \àÏQî[
LÙYyswí6Ëƒ1¬š„ƒÁİ×ß²’¸dªê½¾¶5¸DÄ"Ø->`kêoDíS¾b°2Vv[/õ.VWö¢¨LÑ_¯âµMÈ9º=lÙ’´ö¦I&}^‚>o¥›L¼Hö•62“—a£O2g*ÇjıÆ&fò1ìp*Ã6„ªJø0"uÜ›Ñ]¬Í“ü”‚âÎ/Ñ$»dÈùŞ+QUÖ3C×G ©±ÅV-Ÿ¬«9ô.³WıÚƒ´½¶<ü›Ğ;ó”Ï™¾5¤›|c„oÄˆ´Áèze¼m$ê5¯45©ršcÌÈ“&ù¬\MwE0+):5@ÑÅ é†|{CğÈˆ ô)ª Eí´ªŞèdÑfš!ÿ‡=_áJ!§Gã6¥{»ÍŸ{¨©=•¡wÌ:	³waÜîO¼:;ùğhßlªèøK„ÖÀ”X¹8ŠB³ _~Å\[Â#¬V‹–)öÂz%%l*H.{|:[ååøÄİb ÃĞ¦òé-¹uÜR†bêïIf¬ƒ©7™Şl%öÈ§™|5İ…C¥]vk­‡h’ªø¨>W¹³Ï¨Š<²†GšÍH…¶Áİ›ÜU‘ÜàïĞ`º:Ïÿá²çÒHp«(Û!X¥„û­d€‹üÍ¾½ûöP+ ñÏ‰@ÖÉ;nbÖ½—Ü´N–rS»ñä‰&´Vòlc„¿G8ßšzQHk²û×øX)SËgQ†.ëŸh;dúÍÕ'ÑtİŞßˆ3}›ÓÏñ ágåP»ı®Á›Sù\Ğ@|·ÿVÎ2sT¾!¿ó•]3öğÉ>d/¡ÔFŠk–·Ÿ×Û
úë»®ÇûîE‚÷Ñ¯Qäåb{ôo±ü"N¿L¡É@d(kŸY˜Rù—>C¬4(Í´I|ŒcC©°ŠkàPR”ÛjÖæ4C“İ'‹ÛDwùG¯%Ÿb>–Ü‹¿1ºğQ1Cp¥ ß%E4L=YK+LQî\ÒŞ­#RElTÇhÀ->mx{^0İ¤¼y`ÆÅ0Œoú3„ÚÜñØ/‹X…ÿ±	ÙÆŒˆ}BöZ2Ç¶âß*ípó cŞËšÜ“èE\	ŒFÿ«EÁ‹¦y¶?v¡X†’”Èz­‰ëÏç«$TÙo0Pà ÊÙ_.*Qø­Û¸&hR¢¬+&‚ûÛ¼…àôËä Ş{å3®¹µµC9Ñ ¶VU	lhü^°Í‚hğË[7[æølbœ!­‡û±ñ(óNªãî½ÓQ®]lé
š}üI_ÚÛ¤ğ’@îæ(üÅô;™rĞ'Q(šíİÌQˆ.gD…r\%ÕÅ·^ó[Å)Óöçåmú–ù{{ßİoeO,¤Dá²{Îáƒ¢ÂM „
Ê\)íŞô˜åÅ.É¾#bÔ›­ƒæ– ’"tÓy c®ÅÀı­RtÏ"¥Yû¦„<Y“Ø­×.5Fv_Ğ3õy&#X‰ÜZ@5ãIÜKÔz+ŞÄÄŞåb“% ıç;G¢LÃÜ9±àØ˜d+şÈïÚÛ×ÛÈûÜ*¤Íts.›±Bµ½›|¾ÕŒÔ(PçŠ«‹”‚mÈpÿ¦] Y@©”H”Á8ğ"™I‚B±":ä_­ö×[o	³hÓÜb¬{dÙÜ¦7§Ãpë	C‹•Äg´»U’ïÁíÊdèá(—r._#„~W<ëwqƒÄ¾ôÕÎC·ÆØÙ.I™ÁÔ%“7 1˜‚ğ™à„m]õšìÿş#s× ¼dE‚¿ Ö•Ü"×ÏVfú·%ÍœÊøY Z ’ŞSP£w°z‚C4!¢ŸÅú%’´K-Pï1$¾Él‘.³û€ÍeŸw®^Ö‹„—Ü»„oÔ”ë=ó¥}@0/7²OÀlñ†E]ºP F,•–©c„ÃSË†ûÁB@tg-?¿îôJ „yÑ«cğ{¤¥WşC ¾Õ'¼ŒÉvÌtO^ZgÏyãú½5èXQ»^Ù"K±ê—[©Y`èûîhà‡/ˆ‹‚÷†Õ´‹w’(âşaÁfZ‘BŸ»óÑ0¥¬‘~X&‰ì¥§.=O×io|D	dI>óş~ñC	§z@…D/ú‹—&(ëŞ[_¡¼roŞ!zÌÁásl©(¡‰Ø³‡ô¥+³>Í<aşßjW	â1‚7*v I2 ^	¨ñJ?yr3oïÂñÔ]É^ò÷¨`©´Û-mã$0¨êw<‹yË Fw³íÌê&wÖj=ª5E¨-™äÜ¾™Şzª®m«vî–M
=¼k«Y#,lg÷ãÿkEZ1-¸ÀœW  jÆòa]"Pp0Ş(%4şDª(…ÿ7{DN™´k:WØñº5ö¤‡ˆ˜Ú¾QÎ­šãÄÀÁ@¿«sÑÆC¬^Eöáİ‘Ñ˜K0ß±“Í¦tbPÆsJË9âÂ§úâÑpî ÖP¯¢2v9¡^¤×2ŸVFdÉ÷>[?àÒ+û×n"+B¨í/¹'Ÿ,E?éã`°¦¬ìsí•Ì9Æ¯ßU>ÎFE6òO-˜ÕÉ>¾ûdøßs?êÆvÈ~ÜÇEòU¾Hr!€Gôæ2ß‡ç
ƒÿµÄAÉ yÈK-£,‘…E°%g7Å“¤²«UE7‚>¦ò³¼·íT/yUìÍbÍt{Bdqâ%ÿogCÈ8u„Úä8İ±RœÛÕÿÍLHc¦oñÊÓxXìöFéˆ_‚é’íH¡¨l½L^«º-æ„%kÏÏ|xxY$Çş¯MJjÿEyûó½@(&©—m}ØR äÖaûìÓ«ì••BŒŒu½½
éÒs5ôâ
PöÉKğE Ez@
°{EV<”şœ^^HÕ#4YVq/z8„ïM¬RwMˆ_ßYüŠX«ÍHhPJJ#e‡ÙšêQnHº%–ˆí3õı}N¦æ…³Òz@é‚Ó{”¾‘ø€’Fš2Ş.^áZØIE€–è”ô}ò¨Ÿq`x›S×¢púç»|¸:Ö
†¶› £Eãò&šİQš;(Ô<-(¯óÍöRâú$¦(’*çä¥sæ6"Sm˜ŞKÑb¥|°åúG£g£uE.¡5ìVO³ƒ¤ˆŠuäÇ¨l9$Ö¢f¼#¹Ø¤Ô/€-ı3©×½¼Oflä‰€D)cÎÉöuæù2*‹U¼Ê¢óÀVrqo‰„²‘(‰D  Y³»zOê“ ”¡€ —S±Ägû    YZ