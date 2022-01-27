#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3419496199"
MD5="dcb514a3b359ef8ab916cfd3e732d627"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26036"
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
	echo Date of packaging: Thu Jan 27 03:05:14 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿeq] ¼}•À1Dd]‡Á›PætİFĞ §O6¨¡›2+Ëzºƒ%(ÁuÊI-ò¦ì˜RÓí&Öº}¥ˆ:Ú©½Ü}áÆ*RtäÕxÈèßŞƒ‰H‹ÂÅOû¯ªÍTj?vZš†Ubè%«n›­!ÓF}=Ôä„“ŠfÓòcän®1ò{…OÈ¬	MÂ÷ÒÉˆÓûxÒx'{)pn¾'=	…÷«L-`hnp¥ ¶ ¢Ó¦ÿ	]o‰ú§M€ÔO»“Çí*¡ñ´á·ñí+šM¤>Üdå[|)ÓÃÏ°*BŞúVö¸KOeŞG,™Mµ,„ş€|­u-ƒ3YÙRşÙ!˜RHı¯şAÈåñ&îŒ(Î¨;ÓC·U9õx»î|ªÃDwR=*“ŠV<âˆx· H. wÀM%%#Ö¾á4“Qºõèçgd&Õ9. &cùzi?Es@É³2	÷V²•‚.?N1şk¿.ÛHïüÎ;ËÛ»&B'T…‘0
,ËiÍ*|ŒN‹¶ôííÖ—ÔŸC”©E=•¶\„•>náµ¤}(§uL}Ÿ İ şYJUvÊ!³µ’.(óßï–™áÉcxü:|¹âE™­7Y£M¼§Šıí:Äş<I–í uœtÅ?‹’†SE’6:èÓŠ?DZU~×¼KB5âµìI|Nû ³ó;FM¿˜ŸòIá÷É…;ğÓä´ÅØÉñxƒEâK8 jÕVX’ÿô1›IÿÉPG¾IŠK:›—DM%*SQ:5£º¶Ôö ŒùN±êœ„M½£?Ôn×é´Û† sÉPµfµã³]ˆŠ‡Nmbí[éFŒtÊIY“nÌulğ0IB6+¨+R°ëd‰N,I«~úk*¯Š…~aÇÎµYcŠÇ^Îu7ÓFáA/¼w©9¨vä¾§5(m$Å©)ğèÍe(>B°)‚>™åİ<ÌÉøÃOX™bAÎ'Ä2%_·¯t]0—‘œ”ÇÂA¶lt¥Ø%Q8T¤#D?ÚƒU.¶§îí¡Aâ?YT•ªx' ’r51Ç¢f'ƒÊ9·ÛÓëô@à{ãÄBTÌ8¹‘;IùÙš¥•cn	Òwk’"æüuZÂ½éÉ‚]l£­mEK†å]á"Ê²ˆiÂ‘	${Â(\Ãpœ9ÜQ=f=‡ÌW˜ñ‡ÉI©3æÍQBóOäûì„Íüø¢&ıë±7Ä¦Îú—ınæØ!9[ëDaë¬xô™<wEVTÖq/¿ÆÒìi²¾ª[c|oë%0Î˜½…QØõR“qK„×ôoU¢EdTóØ²„U“ùÙß?&W2Õõ‹ÎğR´ÑÑé	"v~Õ?¡ó§ò?€Š3›@2 ‘°Òœw2å‚wèZ€ŒvÅÖ§'½º~K¦ ¦ì\íˆt)êÅqXSK6*Ö§ås*³¯ıü12ZL±YØœ¼èÜn”)Óë Òm|£«H)Yc¼®BGéìv6ŞõVë =“‹é2¡ğè: &K"BYÓUlû£óëõJ—y&Q—Ê—ëV*xT˜ıï'!×ôo»Œëƒâ9µ@Z03ûı!÷G>ñ	0Ñêœ2£#:É˜}ÔÚ†û9Ÿ.ÑÃ»óU¹èqÆÁ yµÒ~Îİaé-¸#(Ñ 	#ìRgœñó¤­buŸª9|4ÃXí\AÖLqxä#9™_ÏP‘õ¤¿J^ïMNuxÎªGB>¤Kü\–ë‘j>Ê2Xuk@vç‹9z Z”_Ã¸^V¢¸¢Äâpä»‘pİd£hu»úÜe5
õí©ÔâÓçÂƒô@ğ¿xi’¼‡‘\ö¦zµdÓ¸ÉHxà¥ é¶|ó§±˜âæ/£¡ÚÑ( "ıfµMÒô€í.`ƒELŠõ J;én¼3÷æª¢İg­"ÔË,ÜPä[¯<
öúQ_IQeüµG?±qîÔ¡İ·‘æ0%W‘†s³p‰ËA=j÷¦úÄí®ŠWô“µøßW9ÊX_=ÄŸ:o³„5ı3½šÕïÎ4™<Ù¿kVGÈc¤fì•±ûÜL—“x{üèÏ•»ÿ«”y i†î\Ú?Ò’°#/&èJpõ¶)À(úQacr€¹¤ìO†æC‚P6ñd(İ$ªxÃÊ6ÃĞéRdp¹{üÒ6"õ'˜ê-úş$jéİ‰„UtŸp‚GÃ0Xc4\ 9£ß~AÃKVŞ\_egUô“h%.ê:~GÆÎ(2ëX7³„8àJ×
è¦eÌÂÇ»YÂ|l’¬
 Jzè
²NbjÍjÖSá^eWèW.zw-§Â U†(e¹Ü!Ä8A‘P˜Õß¬+û0BJTp¸°»Ò{*Xß"+7„¥ğH]ê.|ä4‚‡½  3°åïéæøéİ78ğ$Ø³’¨Ë^q$¨BšîÆwpı[¦EÔJƒÀ{Å†UOIä–Nçt•bkG °Ê4Œ2*H±Ë½\ú…¼Š4ì­qœ?t€–£‡¡NMĞ½eò’ıœ" Â›­°"t^?K‹¶×.åWØÄªnµrÚKûı`pJÛ¶?IÅç	\B¿³r¹*è/JÒs‹›%+{üşá¸ \ÁÚffœŸ‰öÉóĞ'AeË—¹0­äÊB,×N›Jç]î÷HÆÕòÆ{ğ/Ô®kğt+mÍßv%	y(“è¢Šfô}«ŒN_sÈ‘HÑU%ñÀ‚Íëáw‹Gğåœ0æäÔÅıue"²-+òSÔfkLtw½!óÒ:âcÃÊú4™XˆÃëiÿ#{ŒøÏˆQŠ wğr$CcŒO®3æ™Í1=¼K;XÉŠÉ>‡”WşÙ0“ï9)ÔÇÔ5`u[«„Àù‡‰¯zrE‡Ô¥3%ÀP¹H÷ÆP¹RZÍ®z¿0†Ñw;ì§´>b—R™Î Bü%ñ³¤­š+¸¿m·r/¶˜5«¢cú’óQ-8MÓ}İµ©¬Õ‰)P<k(€yÚ›,Òÿûdˆ•¤Ò'L»¡_G¢9”UMU¿‘í°Ï	-=¹è„İã~Ë$;AUİ¯Û¾…P?’ÚTÑø!rcZà“ëœ“b¾Û÷Á¶»í9±çÏrİÆHò†qú[cÊÒG¢Å:j¨¢f­vgÔÏÜ„&‡LÏó52{±cG#Tî/ÿÛEKgB<çPø<TÌB/ùe%§kªşÆTPû‡“šE5zó½…ï‰A3çI—Õ%°V¸…QT§şVr?ÅµlBößÕ¢¢+B´s­Œ1¼vƒ–‘9ø‡Az^]Rlÿor’qDü"JØ*êöü3xş÷Ô¹ö	ÈÓSQ²ò5RØÀªJ-m£t¿Ö/İí:	´5‚-”$³#ßàR_h!±°pˆ ¿Ë>Æ–Ç¢5w/pÑÊ¥¥+sØÿ†C"ÈØ‡¥OZí_^ó—ò<0ü¥&>™)—9;ò©CœTÃ'ã"Î(s˜Eém‰.½ïuƒ°¿ûÔ!4KùTª·½ÖŒ0öë¼¹vuí¥0J÷ÀÓâ­Ìê^tÍ'ît–¬}Š‚¥	W¤}tA¨,·¹3…ÏğÂ½.xTß-FF%ë=­XtğcÀíJo™+Â'‡eSJµ»£—<ãñŒY32RóÑU,‹w„íXÚé Æ_ı	4§Îæq§s’JÀÍÌ™*€¼¤İ?Ü_p.óÓŠø¸ı¨+E1Ók#Ş£Ì½0Ş›~«VìO{Ğ(ÑN+CËèßÓ¥*¸Çı»°W_KvMãêw\–ıÎ3f§ÀF“òPx{’J‘²Šª%ÏÉ¬ºÂİÆèÚÙFkn‰Î–´Lş´Û9††DÈ.)´ª>BôSwÄçŸöé‡6(âNÿ8|âÆğàıOñÁ8:ÎİÙPô!oË)|÷üz—CSÜËş­Q(^RºT­Z±Vã„œRËrSEÊÖ‚D“üZ¼eDm‚ö— öJJo[¨Œy5+ÊÇ!E6mÏöšë”WÃê={ŠµÿFvS	¶‘DKí¥€÷%{¿ºfR›ÙªXÕåç€a˜g`”ŒŸF¾{¾—ùR9’òÇäZûĞ“?ä|ƒ¨şòS¤vÅZõ?£µxàRirPsYY9;5ÊŸ?©xÆÃ¯m ìä}`Oeã28<XÚ™!K'­qt2•ê¶›ÍS€d‰vhè\¹(mcºÎ~á“÷ø÷ÍnòêP³çT-Fãc)ŠŸúørâŒ´õ@×”	Í¯)ˆM$9¤æC'a˜Éî`äà©èY¹v÷Ní±RóÂSËQñ¤]»Væ—u\|+J¿mÖ0J`c‰2'ûº¸â×œ¥4‹½PÖd'ê {'0Ÿ„kKqßğº íƒˆùÚ–Cƒj*Ö¸G¯qOß‘¶wNuŞ*8ªî¥Ø¤ÛH·Çğ4FÈáaÅ>Ü~Ò-Ÿ¸·nTÕ,^úï‰È;;{A}pm²ü2—Ö GB¤n ´s·hŒL¿•èÉ60f…u<Q°Ö«bA+Ïç¼ÈuÃY¥Â±Ö¾Ô7¼w·îÈ}r=¨Ãh5ğsô[/lœ¾Xò;}~.ºÂa™ÄJ²•ªˆây¨èÍØn‚àßWò¢µQã“–·şM.[mD[Mo)jåcÏG„M¢©ƒ‰b´ù’Tç{k!}‡Ô‰m³>­	³Ù5Óæ¨ub˜û9u¸Nñ…Ãø˜¤UóK¯uyy>’b¬pP.DóìÈ¬ó ”£G‚uıÕIŠÅ_Åƒ2êÎ¬ğ—åjÃVŸÿ#ú¦}mæş'B^®€¤söÍÅÀ$ÓSš`«6	.î4EhôÆÏ=ğ%Ög5 ²Ìş­I•é`8©^âqfèáPÕc}é€¸ˆ¶'~ ói•!á5aÕ0‡•C Øê…SÅP¬4Vºqì7†0—#‰É¢†aÔ¦YMfeON€øÙº$‡ŒÌé qD'nßÁÒZ›=1‘bıúW–ci9Q¶T~„p›³:S8OÏÊ›ö¾8né¬b}_)´<´"±Ô8ûtq<YüDmbê«îƒpàÏ3‹8n/NB%€m»²Ml^"EN•ñ5Ïáq˜iõ¦3¾œ•º×‰ÏrûNçÆì³S?ræÖˆq³»VAÊKÒOíâÎY´Œ¸qi›ŞPs9çÄÍ‰´Pö·²pÁZLkÉµàGlOIãp4„‰X˜¿¾~ÛêÊ[ûÄl8±8Ÿ&ËÆ$;º5¶Õ]º<ŒÇb_€ò8”CÜ Üİı‚§»Š,*lÜc™¢x|ÌBJÎô¢ıÈÖ¥¼Ü8‰‹¹©•L»úéùp3ˆx¼£•ç&m€BŠ|¸;ììd.0[ö&UHüf|×™‘™‘-h]ÓmÒ8:ä}LŸúÀÄâve^¯¿v]Ùf3O }\†D)Ñû²;”9D¡ÎNQZ}gªÉ.psn£—“­r€¥MÇC€o‘³Õ˜ñã ¦ºçhrÅm.Åtêe¥ß~Ãúïü‘?ó[+­3\S J‹6WJĞ¤Ì4¿w!ÄZK…Pæ<ÂÅZ"˜½—ü<÷È‚‚)í3i`õÚbTmÿŸ’ª†§îˆ+7Ô„Ô3æÆçTE}M‘ñº_z/¨¬ØôıÚŞBxÊÔíì§šPà•¸h’e°/ió‰––/Q3E¯ÉEĞgê´%Ê1Î›Ümzv¶½wŞ’8RÛê-ljú<…¬G3ÍÌÃém-2 b$Î›ÚI¢Êª>J‡”3FT3Ñ+ó˜d¦ûè±ì>†
LÔF"Ëi-î×ç~q…NxğµñÀˆ7)±€6TÑ["3NÑrÍ{ÉŸİ¾ê/#f±„şv{l9uRW§¯W?ä›g7eŸŞ&òı6ä¢QÇÅzM“Q#­4¹HwraØ×Úì>~2Çñ	çé‘çÈÊç»íôo^?Ué^açe5ÖëI^[ïmhoa·>†•™ĞÂ!óMÂšRø—Ešƒ	Î1u'S §ïg¶MìÅÂ¤şBÚÙ~NÎ~™yØóyÄö]hö‚ÏætoL¶?0¿«’VjQƒ¾H9¤j‡?‹‹n¶lMÂFõ&¬ÌÚšßà·=àÛ-ç{†oÏE98±@ĞlXø)‚¢M+y -éL_ J]ƒ]©¯Orè+‹Eí¤V†Õ&¯´ÕRä#NÕš‰‰Îgõ&ÌÙ£¨ÂFİaSXà©àæ]‰Ÿ—Ûë•y-…‰Ñ!½¥Ay–®èıˆNÅ_p¾ÂzòÀKvLıÁW ÚÊÂ6›¢÷b<Ì&@¢*¡ùúÚSÖÆhsxÔ»‚ÛKş“Ô•}{êOq˜OÛJ¯;şrå¥šç¤p£<ˆ/4ÏCó,Œ4›â‹‘; †B¥<3†@ûu”¶ÄZEí^‚Sâ8™>Ô—*¾ÉÏÎ6„xx¯4§19½ Ù¹tì$»¤
;Ë P(şû2í\Ü˜Åi(jì—7z8R0ê¯)ó°ìº(Ë¶˜ÖıV Å]vƒ•´H‚Õ3Ä˜±Òêÿ$Ñ!ªïú²Ü×Z/y²kˆ«ÿço…š%l€¦P<4N(åtÀ	”a³,v@9àã'™Ğ,_z³£,!˜!Å:«r'@û~Œ5\}¸ H²†R–ºqR°ş³Ä1PRÏ·îñıŞ~ Œ*®÷hIk,ÚŒ³fTRìn”šz|œCÓï6m…Oy\ŒæÖ“_{ô`€ ;î78ŠŠ¿ …Ù¤#ôcôÈz¥ÿ€o”×/lk‚º;9t÷æeçbGÉyÅPˆÊmÍ¸ ßGü¦ß9d%Úc“4(*}Ø~aäHŞk°0‰é|$nXŸÓ­ ¥‚ª’h›ï °‰¶UÒÛ j€ºÆkƒáD›¢j·z–…Ü Òc# Y-°À=¿·ı=M:¶rV¼¦~LW(—tK‰“©N!óÇ‰êEí‘kĞÒ´ZŞ­ª@£ÀNØXU£>wÒ¹^©ŒÁ†APá3ÚÅÿgp>Ë_xx÷ˆ_GEÑÄÄò‘H†u:ö`|+Æí_<Ü0Û›ŸËÅ‚°:¢Âe…ufé‚rXM4±¾|‰‚_â‹ù“úââšnß6hÒş‚»õÎ»
ã`?¬®èØ‘f“·“~£ñˆ· Ê¡êeOXúGÈ–”q[ZtXÿ†Æ¿X¾°»u.'GLP‹´tçç(³HoìÕódÅ²İ¾7×:—’í&?µIÓ”ãÊä¼ËÒÑ]WßÑq5®ŞòÎÖşt~§ŠEî=ğ…ïBEÜy'Éé{|šPŞƒn „ ËĞNL[Æ·ËûQ¡™¤~ªK¨ãƒÿB¸‚V‹‚¶ğ‡‘Òõ”“”ZkAXâWZ”7ÎKÆô{yÂ0mâpŠ(WÇûä9œÚ,> e¼vãÜÜ+ÖY2—¿?µº=Ÿ’áNl`Š-Mtãù_úáããŞü:˜Ÿ°«õ4®œşşİ—	D
vÄ3¹y’Ù¸'ÒbKE…µD¤—PÖ©{òŞrCĞ)>)´ˆ‹XA‡7C';*Õu0g–áTšïVSçD¾ ……Ôßs*ò€îá‘ú‘OÇğÔ§Ò¥FH²'è7‰+òPzìéO udáç «né¸O‚$­Å|4ĞPKÄPşÛñÈ¬¦€g‡x˜òš<WƒñÖº3úèŠ™R3f¬°î™áu¡t‘©ÂmmŞö!"Û[d…Ç}8½ldt-êìÔºñ‰ıš¹«|ÿ‹È`8qYq©À)½\s¼=Cyx%†JÜ MÌl;-Õ¬PbiO÷¡0àÍ—½cmáÌÃTY	HIÌÜºĞ#%¯¥HñÎJ¹øfjƒÔŒsfğ»HÿfÒ´Cˆ´QMYF¿‰îş#9ôóª—bâîS§‹†D\=RÈÌyÖÙ3¦A3IZ}Ya’ßBQ(À	¡f[|òĞŞõ¾­şÔ7¶¿?½®‘{>m.ÍŒÛÛÔƒÕÒ>2SB q]÷=ŞÄÌÑ.c\†qqU<	ój$*')3ş­Ëgü½T"¿ehH‹Ö‡‚×$JïG-4Ôˆ{²c”|­1VØûâò<	Nûßå
,3¦:o'cøH¬|¾55°F=&IHÃŠj}§&Ò¨
Ôæ¾Ibâ{|;6v/Oí•IÌG»ÁN‹«•2ä €R[±Kªá‘p/³µHTr„¦ÌŸ~á»•»ºíÒ™lw:Ÿ|oh§zw€Ú Õá.a{‰’“ˆyUœ¬ğ¾ôùXXtTËSÙñ$ößÔ„aÙºD”"ì(,äÏ“ü€„çSşG8åEE[‚.#<‘ã¶ó3Ê­ÉNGG%°›XB¼8=sC5·?éLğ©ß¥|IÉi?·‰P²xAgújÙæAT¥ÏO4YK ­ğ¦+­YFolÏ}sÑ1obv0=Å"6?‘ôÉ™‚‰¨KƒûÆSg.,Ÿg ÄæÕh…6lœÛ‰äaA'!q„|{8¿»SzÙ¯ „\èN½$p4*›æ6ŸaéS/KÄğ½WŒn«fGdQCYr•«ºÛDÎbP„ûÙZ=ÒygšJvÊæ¹ÀqGB~)ş~Ã 4„¦÷Ÿ>è|Œ“9÷@Ùh‹qÌPÏ5‰Ş×¼?®ñ½ïÉ^§§(^*£q¨N×lyÀÃÖ_˜tÑ¤9A,_›‰iæÌƒµ*Ò˜Oå¿¸Wî~ÓW{MËÇ‹©¤€ h÷Ò!?§e9(Z˜FäŠÉ›¹ş˜êfÿuá…˜«”GÛƒü–Ô%Ìë½Ã¹ í\D¢Ñfë…¸A*¯UcÉM-–$Ço)9-€Ä™Í†›ı·³;ĞO@~¯\şµ×ÙöL¢GÅt‚Xä8ì‹cb/jRÉ£¹ğÃ,b~‡¼B?HšR¤Øi2 Š5–ábŠ6¦ZZõ#êOq5R€×ÄB%¶÷šhlíºR¡.Éşrû-ûÌ£ßb*,ûz
Ü K~töIxz©&e®{@iôJ“Œ #B
ë;V”ånÚîç²#Õ±‘š3ÛÚ	OxÄbÀ•ëgŠŠ‹ID®ô‘Gf~âC¿lI€Û%»c¬S^¸ÔŒ“Æ”(í‹¹¹ÚÓ@äê&øû5Pš.ü÷¡œsCG°RÙ8Gl:D*§HÜTèFGİ@µtb1è¯µ—@{gª!—ô-wŠ¶ €Mû²b®™ãî[ÿ§±Â½ÆÓ^fŠğPñÌF2÷)<ğXq‘À…êÚ'¯êSq@Kò¯¡3ÄíÂØ–‘)îõDO±ü0áû4`@±·•.[&ö³/‚œrõjØ3øqfYbƒáˆ9©ä2úÑNİ–`!á)x*¿„ñöÜni°&¹„-¤
sa‰Sz£	À,£Œelå+I'Ó5Î¡dgeàgx=E¢êú‰»ÛÌãI«•i8+EñJZç1©=õéöKÂ·ÔÎ^æ ƒ¢*X·	Š!ã}Œ¿f?Áø'{å.Ú<ÄÅ*Ğ±‚†å{· Û|©ıâ`X»<şX?<4Ä sJ…ê ÁRÁ&ÍHŠ$)k9>ùü>¼%šº»d:„,¼6=à¿P3pö·o3Û¤‹5YZ;ÄO(…”è·àïÁŸ7bÁX§ş¦gó£ùq*mZ`İÿÊ$k”@ë÷¸yŠãòn	-@I€z×gŸƒ}i^húçÙè"×–òSLf`+ÑŒ	G+ä/=ÒtY¾²LÉú¸;"ÛdàX·A•·~ãÅdRX6ÿÁ¥õQÏpü:!A;&¦¸5*+­§ßIB"MSb›yÚ.¾?4Õcùœ(Í›Õ3!*E>s#N«ûM¬¢ô¨Û~îHÈÇ…JG¨1ha/IEâÕA~³òqï_	lÛãPC@şçˆ@ª>ıI7óŒñtÿ"§¨^’pLş˜©p’Yñğ·?¿´’„&çí±-Ú\çb,ğ-ıÄÒÿ}„
)ãµ’
N\b‡Bä>0¹)Îº‹n†{ƒfAÑsXºó©¡çûõø¹”uŸı¼œj‘àkj¹!uÿ:D>¤ğÓ8}.<äúyx3X+«êªç}§¥ùÇ^B¡&t"k|„Ñ2¹Æ$)Şfnû;şUzX ¦rˆétĞ÷=À!‘âæibo&QrüÏ®ã#Yû,Õ2³ÖJrDÕÙï=:Q‚Èg¬Ó¹,ŠZÄ'Ğ‰r³Œ,ëCYùÏT†ßûlóşäL%hÂyš O–´6”’ ûHš…!ÑÏV]!c|ÛğÌR¬Jc`-uS¢ACÚÌA{²'f¦º~ŠÔEèHN¯ş$ñ£nİ{ëÔjCo
8¥˜B*6?a’m ¢ ´a4|œ`Tä!‡•²¶`£Ãd*Øø÷²	²Èƒ!èÄ0ıŞô<õá¬‰¦FÊ—Q‘º4Ò_Ê‘?¡ÑÛàI‚QªÚ–&Äò:Îõfï°Ü„¸cÊ«HŠ"âÇ¥°Éÿt€Ô.ïœÈKä®ã¾•)øå#{ Å|ôj“Æ¾v|Y§AVÕÒË>„-õ³äœ¹spÚ]Â ÇÆ×'èw%'ÛwzB„%.½iŠØÁ
Æ´@ &İ§¬ºm[w×¢*ch“Âkñ:ÜĞ˜;Îß•ªzá¢v®ƒ³òQ¦½;ğEĞep‚|w9xf'?§zLS„¤:ÖÀÙ4aìK¸çïeemPvÿÌ±5èˆ?9›s\	WPüxÆŸ¢”‡0W=rvKÔŒ§<‘g40X·I­ Ÿ=Ãø”h¤â‹–ÊŒ=Ó4ä±HM§ÿÔ˜Pƒ®™ÑÜSÇ¨å3®‹"’¸›ÿYÂ¤-@R•O>£ö‹ ã:E$Ô5Qİ[I_ò|+‹ü#İ±p›ÿNïÕ!v×™&î‚ğn /+3¸¤¯uó­a85ñ„°¤†s»ZŒ1jF*“»ÙKüŸ¶#PşNÆâÉô§şmÙé…íÇÜÈIÔhVŸä\î{´©–ÌI(@½%q½Ÿëß3Ó×8£\_Ü+øqÎ1˜øpníogÄ}.Âz•]‡Nÿ²şRj¡>€áuRÛİ³Ì|2uöÕN/I'œ­T!ÚtX´ûÔl-¶Æ¨NZ5´u>¿M	˜#µ›Ñ†“067äKS„1®G`)ëX²Üûü´7Í°ÜYP9%|™ÔI%X™ñ!`—–ºc§Æ×µOd¼°Ã/îûÈm˜²™§p‹‘/Py ¢´ƒõkì@ŠÒ.3}‰ŸeKíxì±6<Nxğ·~V…TÓ¬­{½ûè1pÔVù¨=+J7*ê¨	Æâ$’Ûï¢7£¾É®º"K)üTs³+«ƒ"U;•³öbÅ)–
8ÓÜ«¶ÊNÚŸÑ»1şÔp3!Y±q“ìA1dÌ7†¢±¸xÂÇª³ìq?vUgÀ[FÛûh2Z°B)­¨¨ ÇaBUÖ£Ö‚—ò<•ª%üÔ¶ğ„è½3c?j]áß”4l"Õ¬ÿ,®D@—‘¼}À6O((#ªğŠåÕ¢0œ€ĞÇró=/o¸‹¶'Noæ
Ö£w¨sÜt’F !u3ÈÜ9ÜÔjí):ËÉŸg7jiAú—$ş›M	Ü×Ã¯š×º‹Wİïã4ˆ,ÕrÛZĞ‹W@Û …—Â—ó;qÖè³ìÂ·!çÕç´Rl³q°Šg©ÅÒ•†‡œèöjãIÆÚ]Ÿ ÂyúP­Z¨Æ»ğ?sÏº±¿Šò$=F Ìz‡ÜÎëàjLb²¸İÌ†=~—&E5àĞÏÊÃrÿøšwGT—İ7yéÂÕm„ò7ñ&úÿà’›Û÷t$ «­%	Zp%€…:‚n)[}¦kà¼¿hÛ(˜ƒ%úoZ~|iávˆ;‚ğØ"‘3]G1»¸¨nóê¶øˆËäµÁ@>pBvØT#Jòè·Ò ËéŸïÿø¿‹!”‚­,ÚğBd¬Ú;
¼‹Z<¯.Ø;íƒµ-•§3Ö…‡ğîSÈ /ãælb1×k—÷G‡”o\æ»·\*b_¥\‰˜Î´‚šk€Bk§¹an	kúşfCW]bŞ½+µèèDÒŸÎÕà–È?{'V†q«–Yäl;ìşïƒôD1 ¤¶ûï°ÏÓ¨Æås÷wûµY/¡Ïqe àÍÓ‡ÎG!7í(†®ìjNdÒb…n™€³((É©0¤ÜïZ¼ûğa€6^
¿»º7fgØİ¶v¾6İı=4÷íĞ9ŒîÄı…;o¿ş/Á‰)ÓŠF 3‰­k]Gö2Lq#_~F[ö­šG¯“²‡»Å¨9ÅúÆÓ\Û˜:÷ÉLÅ›–ò¢£ŒF€hAO’)‰¨“Üi8‡RI*q8tÈ%‘¾&_Z'SÙ„[ÅÂwİ· 1]&h@*2*¢Ş´oÓRgŒæLT¦6c‰Ìa ¢½€Q^˜[asaá¾ü£íI˜íW€4çïU¼Î[ù¯:B{²"?¿ uçSn‘…g_ ¨8åñÒĞ:™	#ˆÎÇİRCäòõù;˜®CzÄ@ÖK>u¹8gìE
÷¯à‡ùËVsÑ¦£Õ—ŒI`@?1l0s'keiªè ™`Ùå¾´<¿Z®¡ë¦t²ú=šáú`rç‘îdsÓCùeP¤ß=+oõÆé·›¾!„>İÿB&¸Ç}q¢íâßM}ä1EÈÓq˜È¿İâˆr"d_½–Êx¡GO¿¡ªëd« ä[Õ :bŞP$‡xrgÆÄ­©­¸ÑÅa«EÅ”m6 \ö4òK;AÇogµÏTÊ§Ï¢â}â.úŞğµTX¹Qí}î—âŸàYÚ+¡êÀK´ék×ˆ_ü|yF}€‹A¤İ¯NG-@YäÏ–ˆmG¶»"mCQf¢òúÅÃĞYñş‡…Áê’ì£îxwOLƒB|Ú“±lV½§«­÷eMN;~$dÇä.Ú¿‘«›hcJ\s¾°bÕjÃØ¶êçêPµxwÖ—¢-ìÁã0Mµe~Jxej"f0Éë~´á¹päk£°ŞÃ9p(CgEl‘v¹\Zõ¹dQŒ_ıNNM¼K3OËÚ-¡	·™4X&#P< '
F·ÍêZ;Ö¾'êuÇa­ceeÅ‚Í¥ÅÑF}ñêM‚¬ö˜ƒ¾~º6`íl‹§­2ı”R{1Ëè:ÍnOÆ–mDÅ°'J¦¹J»Çícy–XãDOÑ¯yXS4luDq”ôvöqX¢,‡\Œ¦jFyWfİ9¶_áÅ#P“U\»&P4ì<!àr²±«Şšœë2¡5ÏJÔëQ%é$.;äâñ T	sÊŞK´
ÇN®[ˆ2,ÒºàËÕÁë§¹ó
¾fJ»œüUäFÖôaŞ½kîOÖ"Hû?ğÚT@^âipK‹fQÈj¸SêÊ˜¡¥ÖLÛ+<˜.›æÓ’%;E­jD÷\Åµ_" âf6Ô‹\¡ :Ä¿$-°e9-«røŸj¹™‡—ÆDJ“¥úLZu„{6ùQ@KÔ†×tÇîSò£A¸ ¼»~QB«*4ßD‡0²@½æ/è²âÒe”ÃÊ\‚'ùŠÍÙú®UThE©¶xÄA­Ò7(„×À—ué£î€Ê¡hÍRç=SkXU¢îRF¥
O©ë:}(•6i$Ã¤FÆû‡[™sa½/ıbU†$ßîºšÂ¡6¨âÏ,¶_Í·)KÿìÀ—.ÁH2®úënãu˜ËI;ñyãl<¸Å¯ÈnQ¡1v×çZP¯Ï:RÑÕŞ‹ŸæâÒBëV5šiÒƒ­'%%ûy4rø§ERPpÑÕ>{ôá¿æˆz‘¦÷é1…š ±qğ@İ¿Â8×q–ëàIgKß©®ÜL…ùšVW”e)fXÎ9Ö·åY“El4,ã¦.YÇÍÇÅÒ¬XË_.z_1„ñı¾nó(:©Âµ>>>"€õ$º©QJ¯ï¹JÄûFİWTáı-¿Ğ³÷ë*Ç_“¡L@§gKä­Ÿh¸Š„†ïĞNcTƒTRWe¡é“¼ù9».¦šË»d°AYÂÃI‰«K<ËØÙëçFµ ¤)²·½Ü› 3iiëOÖ³í¼t®÷‹’!ÚaFïÃbŠL4} 8AÕ¿:"àà›M|Úœ@Kw?­Û[9º,Aê;úÍ‰ÑWlÚ©mvßE“`šæ'Äq–Ñıÿ`rx©Àâ»"–Ú=1™Ìç›£GÎU}¨eyÅtùÒÓ«Û\B:!¡$k‚:2Sx‹¹ÿƒ´q«ÒÓêólB¥ÈÅç^ºk2æµ®Bt[íyª­ÚñY
Ë,öpm„¿„ùÈ}“ÄÄÛŠnÓğ–kv§‘‘lép5€à€r¡ä×èÊ¸ëÚC
=óñ}lqõù†“œ–QŠavLº	¿SP52NŒ?ß²,µQ_ûÄ²‹ø B£¡¢ˆ8üç–rE
ù¯^üåQÀ^wıĞ2~ÔCµp5I£Ü¨\ü$uZqü“XxÁªÁ IÁÚµ´™Ì(<ê1B»å>2ø¿õQvß²¶ÙKÃ[îâàtï®2lAºŸÓ('µ]gÎQ	t§èã˜ôl6Ã§¿ªıéK,fˆ”Áşû7JœMTë<Õn±«vª&fJKHV:½2Ş#«œ^?’y&RÛšEt Eyİ¬ƒ~Ú¼ªâ§?¡°Ñ]æ=‹“ıÄåOP‰ÕµYc.»öw²—"Œ™o²© *¥IÅ‘´\°ßÎ\n­n‡}pÙª6Eà˜oÅt'âíéİ	Õ0ëgÙ)÷n¯ñ!½dQBtÉSûh™>%y(ŞØ Ú7bÌ÷ÛQúí†åcÍçñP&W…|lBå{\N:¯ëëTÊÔ[—æ+œfÈöú§8H_oKÊAìQ-“ëR¨xµşÎ¨g ù±Ö!”¿I®f.AuÚW=¥·++6Ê·$²a»Ä×0•«±á¾1Ô„‡Ój”Z‚¤’MXî~¥ŸFÑáşj
,h!g¸X~ê,m@jÕysRˆ\D‹æÃ÷UÀIÌ1°¤SŸ^Q•7äg—P¥dËŠê^Ø;|l6”©n™f1âôÉ+“®HQí±N¡BİNÊ§<4&›¢D6íUÚ&ğîZ}çä´ÂÒ£Aæş¶ãµ)«1LØm&C9"£™Û@ë¡ûjô“pÏ—dLeE<{nÇ¼cÈûs6 eÒ_`gdfTCşÀ`lÁ+i4\£D· )çïK!Æº±fV‡ßÊs% ¸Wš³kCÅB3TÙn
 é}ˆ’uË‘j¯Ôe?>Ø_ªËñD´Âì¬‹¿qaÖß™vçîF¹Y‰šŞêQ ¡÷-@hiÆHúS»93
ëéÿ‡¦+ø%Mt®mJbx)X¦Ìhkçb¨Áæ³·jéyõÀkn•ÔcÁØx4…	€Üß™Ù‘ÏyA‘ÄcUÿ—%¥ÃÑñù¿|ú¼i"Â`ß’ˆ	e,±x˜—Lì¬ª6H®Z*’ŸV¢öÖ[]>kÑgƒàL]\“¿®ÉÙm˜MW!éàGÜĞ‘¬Q­i—eôˆ¢a¯¯kòR¦ùÆñ3„'MúÒñ?UQº¢¶Ë‡V–çFkÓMrúi®Ş?‰èñ¤-ë{ã¶NFÈƒ#¸»>0W_uû¾9ãV%õGĞiïp_´%[SC¬¹zlh¬=ñî¢3"„@B¦#í‹ƒ;ÑÃSË,¡^Ñı7Õ(}7ÌgÁ•C†3Õ­ÑñÍË{æI¨dø¯ Û{yYñPX}ƒjØÁ€š.;aÆkL><\>ımıô#O8ö|å÷‚Qöé—`ªü
ÂĞtK¢wm¹Juq5„À€÷m:9åƒ?Ô‡M’x“çş£NtÄİ<ÿÅS´˜P·/ú¹ä|Âì1].Z‡\(CEÌa“ñUI~¨_Ò\ö¹#ã=üjœX÷w"ÂÌaåë
m%Í>R`Ha•¿h!‡Lu—èIà!y#36Ú,Å‰fæ¡^Í'÷Ÿ¦âı"?÷9ğä-âŒy;9ó´ vëºgà£HşÇ è$+_”íê?ÊÒh…¢™cqìÌF£7€ÔòÁ]?¾oßÀ(Œ¿lÄ5ïØ œ^ÕÉª³½Z/v—zCYú?"ß{†}(å$Â.5,´Kû¤&6Câü:¢"äÓÆhi¼ÅÌş§îşôİbÿÊ¡_'4¡§7TXo¾>¥øa–TòÉ0è*œ40b7¸½:+CöD1SÆèg]'¦EºşPÌËÉ…9¦ÉZ=¦–ü•EBu/ôDáh»¾§¶>3ÀĞT&`§á=¯Ì™À-E×eá¤ºõ¶ıy‘×~€{¶4AÇá™J3Ÿÿ†¥>4||Ï PpŠø´ !jƒ9–^™•GíKÑZnêi™!Ovëœ¨Å¿Fy„ 3Åµ©Ä}‹pU\ÅµkÌãYÍ]ñbë¨ıŒ¾á(YLöÆÎ’Á…ü¥Èn-ŞW^¾?iuèÅK÷9">uò"çiMRvKl£ÀÁ‘
  …ãÍÓÈ¥FG×}ÅK35*ø^Õ¨ëìoúYcßËyÅÅ8ù1 g5à9DTp
¶Ê¥!”ñÆ®Ñä ÜŠ¨àì1x¶ìdY›öÔÍ3˜VL0*mzµÀ¶%>­sÕÓbaíe¼Üƒ€Õ€S	uF8m"€9$Ó?cÁ4g[Ö®·õ¸ŸÀq[„œ‘‰|º¯›)>Úrwg§!`;[}}ş] å)Š}wkZ§„f‹×Ğ=¸:”ùöç\J~r·°[i_ZwÖ›vát*¥ßÏë²¬×¹/¬t‹Or1ÕT±ñåë\dK>™âæûBpRˆ„<L¸ÅÒ•_å_•ÌÁş8ï¦fâ[ï[$è@S W½&¾J§›ŠËÏ>´.~0‚`]h¹¢&bv£ë}òÖÓó÷	 âöâN›™J
|Ê'[Nà÷ÀhŸ;WPx8n¡{•H«Yj§ ‘Ím½R Ò7ñèI&ÄP3÷ ıBG~Íá€ò"¨ 4Y
xBÃ©æ¶¾£¾Å=\
vpZ˜.H£JBÁ¶[¬—¸ï¤f¶ÇÎÜcVëÜbÃ!Ô ö²BSÈK‚£²O¹+xGUt·ø¾ùö(û#v$%ğº‹	ÅW¼V´äm÷Õ÷öÛv=Ûn¾ız 0›á¤Š‹8j[¿Æ2”ïîØ#¦„ºíp•ÙÇ‹ªe}yšË™”Î/f=6™©¹É¯vQFµÒb¤ñaC/WHşÑ/jØó"F|Ÿ	  h±2zRcZî¨ejGºK…Xº?	¿¥ñYÆ©ĞS[Í×:ªæ»é¯Úé°`„ı­ã	ÆZ‰¦Tö—+e,Ê¾yÇó^Zå½p´¹õ\CZyY|òÑ şOÙ^Ò“ˆQ°äU;÷sâ•û4T!:h€`|‹DáÅ¤ŸĞ£MÛåQIÃâMÇÃ7%?U„¦úñúŠôlØdÿğ×Áç¯Ú¹ù
‚©°¸òıÏr$–…e‡ûuöŸ{‚ßôğºw[L¸YRFÚ™D•Äfv€ob.Ä—ÕéLœ–Ø2Î‘>­P„¸®í»|€¼ûûî‚ijÿÈäO„_Îÿ½>À^!5¤?Ä¾(gßèYiªæïq2PÆ'¨§+¹W5ŸÆ2nGBæıÙƒ ö{_pµ~¡Ç6Äÿ‹š2#<¶Jÿ^6³»2TŠœuÙÃç–GÕ¡*Z¶5cE 	î%S„Ñ¢¤ÂÑ¾İ‹nèÎ½®Ò¥˜D‘±N“XÔ'kK.$òOM]Úêô |ƒ3JM)1 û Ä®>Îcï‹œ	ÒQJ¶y<Ò]|Ä!'‰i®¨_Çé±Ë¹“>¦¥À&»%kL+BŒê¢pÜŒa0è°•ğğ=ÀZLyüEYˆZõğM¢øA×~»fY$zS?"O•_öò?9…ÑçÚ8[¹P™ï·¤pG³Q¡õâÃ ‡câûºD~e­ ZEÑÂ›j“7Ü`ŞÉrìî{˜E×\É‰Üyø¡ÚxzV:3X§Ê³ËtæáíXFBó”ÃôñDÂ49ÿ¨iîºƒ<€ö¯ğ“«1<„'È/Fîåt¥ãØœL³ #™Ú@ìTöq®ù,ç¾á‡ô%":D)Ò	ØÂºµP:al“[õ ü+œYÀ³t?¹Ê@§ˆxÏ34©É%ÀÿÖ “ ºµgÜş6Íq;ŒÅ+İÏqr·.ü–v¢İ.i€2ı}Ÿ—Œ6çßvsÄü×kË‘ª&Ü1üº³$%vn/mâZ$Á/!XÎ£ÕèBÔ%.qÊùıy\á»³Ÿí´üß+@0nm6¶Nıäg®IóâÒGæ¼ZAşÃ®–‘}è×3˜á`OXA]nÛdE¢i I•Íy!!(¿>jÜ˜áézl&¯¯s¯X_’i]Ì¬&Ÿ‰ê0‰¢·Ã½[gdE9Lnİ“™ñ·K‹àE>Üfxó{î&cÒAÍO¼ŠÕSÌëÎã‚{«²•Aúk*ühŞlh«ë&ÕOŸë^•ÔS‡‚	ãÄğmòÙñr˜6+ˆğ'êMĞ†L§w5ig·ğÃPµ@¨ÑEçºèÊüİÔsïEßëéK˜‘MË]uäs÷tÄ{©®-¿¢µî|<KO"a,DX²q6'Æ!T‹n.£>¬Ê»‡èíE¼E îåtæ›É¯)M'ÃzÖ.ÆGÃº}ùü_šä‘éÕNØ`-o£³5f0"–h,—¾Í¨5ñeçN¦ÿRo¸Eö6ÇŞàíÆ~â™„KN!<4$]éb›-–•µ÷ Z½´ä›'dm‘kbºûĞ¬~Mi9Ë£yÂ»ƒ8ßìéšJf_m>JJ±K4ı%ôå2¾[RC…âíËö´31…@ÙšÍp¦Çñ†´*¥×‰PàW>Õ¦Û—û•üi¦JZú×ğî}ãô®5`!š«‚(j^÷ÚŞÒ°P% €Ëkjâ÷Æ9ƒ=êÅ¨B  Ö%ıÅ¢f;mG,´“z;rS½Şú#Éh›z×B[sª5İu'Ğk!¶ÁU¼FÊ&ŠÛXh®{ÀQ(ôœÂ8Yáë8"ôjÔ~ó6äAq×Á•o8ŞK¥k :K“;y\fÉ˜jlÆŒGs¶¡Z­¨éÎû—óÙÄıRó É‘l¿‘ş}½à¦ÉgRdz¯©@¯T€hrt5mk
p[Í¹|Ç#|NNxTû%Äq˜^¶ğ.R)†²¨Œfwõ0©G	õ+¨GS¹ş'…1¹?£t©|öæ²ºÂiT@ô:U_•åÔP79[’õk-?³Ñ&!±)PÜ1[ß¶§¤(µt®ª	TY¼—|¸‡¯oè’&‰ğÆ|Ñ×l%Äãv’ÚÀ‘—Ú!JS˜"3ƒ¡6Œ›ÇEÉT#«K]êJî ]î¯/xâ¨ÄŸÅôÕ–…Û«4UÉÁšt	¸c8ìl	~§¿^ È-{½Ê•pª&vÆ<Ğ#ÿ?€–ˆÊ;ïqeá­2Ç¯¯yˆ=Ò.„Mü§ÅÍøï²Ö[cÁã¬›b·ìÕÖ£—d«ÈlújbYÿ."šŒÍtíö¿Ÿ™Úç`Çq:4òUàPô¼!Z3_¦8¸û¡«_?®õŠ“ÛÏ‚LVÊ,ÈÁºé—eä7iĞˆ<šÎ¢[Pt÷a1ı{g*¾®àŸˆi‡]/ºqdÚ8’;¨‘BV¥˜ê1vï<¿µ¿èà÷üÂ¹Iú+ ‘óèbLZZtÈ>Ì zÒP4`XTy²÷ÀdgÀj?_}‡gÊuE^Ûzıäïæ=ú¨ì9Ú‡ˆA—³äwqÒå°Ç~Iƒ­ÛÂæMéıİ²¿eæ'èİtáL!½_bF‘=ÿ¹g-lòíjzîôc+%C–À¨(Ï(VÈ—ïàf»¼Û4}üëM¤À[„-û®ó–<V9.ËÌ T©Ó¿Õ/¾–$ûf>{ıÖ™ŞÈ•sŞ!¸TRùN=+r8§ÁzúìsÕI †ÿæŸ‡?µÀdLCö&ÉÔ”<e÷Ÿ½ZuäkÄ@é¨… =uëéDo¾È¼‘è’âaéÏhÅ<Ê{o}îJ7ıµ§[ïçŞ}ØSÜ¡H˜OPş5ãœ¡Éªoç–]'"ñ'€B„äòŸ!á³ı¼îaNcñË¾êóÂÈl¸>>¥ÌÎ²1‡>¿¤©!“hc°=lŠ•˜ZûÌ²·ÖOb°-´ƒ?dcCãg‚ë¡·n=|-æ$Û­äã(µ¦İã•ˆƒ».ªxîšúC_û—0ı«ŸJöÇ ){¬ÈŞãÍbëî‚²ª¹a¾:f€’êÓöşˆŸÙãÅT×ÒiHx…gJğ©e³µû`ø¾>üİÑ˜.n7XH’^\½Ø$¬r=E’J0Y³¾!(gÉ«kG|ª§Äˆ	+c€ÇZ$ÚFÌ¨Èõ–$€zN×¥GœøùZşçI9ëOJtmè«l>ƒÿÑİúù0y;7ˆ×°Ê5M÷¶Ş¼
Ù“ıRß‘ÌÌÇäÚÍ‡AN•7‹râÑŸkö÷Ç<‚²ä}ŞÿHæsŸ8=N"™g­¢<ätëK¨ş„ªÄJIÄQÊ“œ-raY®J•†©Ä1{¸1ãªj,.…iNr­ˆ=ÿ£~Üü§õ2ÚéûuyéÈµXÎ£ê&F_`d>·ÔHÍ‡eÅäÚHÃ€Ÿ/ğ7¥2´é’!W¢Ğ~õ¶ÊZf9v¯”ÃX°p>X_ÙjS¸IûZÏ æ&cşÎ¼æ·Dë³µ	şk?u[DÁõ±6äµÈ4Ÿ² –”÷Óm ™>£ıX„> ÆüÅÀ]æ ËÖˆ/%uº¯bÏƒ×\úŸW˜€jë³NéwPeî X½D…Ğ`Ö¬21XëudÀµq<Ä»ö˜€‹çYIá¦ód;Š’mĞ$.cûİäÌ˜0ğçg<ñ? Ú¹½…0B6IÒ±ãçIIø¦¡@Vë›ß—ÏmáK½“ºõPQ³ =H?Í]›˜Í°>ğ¿‡}$N ş¥¤Bß—@ß«1¶=˜` ÑSöt¤“j™sß·ôÉı:Ckø¿ŸB"dÆÁOÔšæ·X>
^'šÁ?"„úØ<©Ì‹<§ü°ĞÏ/ §e;‚6Ş°Xî5(º¹(:î†[†T™S³ú<ÑšÌşnÓ/í=Ç7B'82ëh"á=ùÇ3gpgV>ŒŒ›M1³Ù¤[l]6wêE%SÓÿÊ…@5+¥Øy t4ËÊXÕ‚¡Ô€¨iĞè2áf}¸œ›»ZgÍ±íéÇŠÃ‰5ï1T˜2Ú‡CäœµQõi{dñ¡&ªØ‹P½ä#ZF±laç™;r%"éãÌ#Bòı¿Ë¡¢6ˆˆ@ËpÅ²¥bÜ[Ù„¯S„º‰¿måÿdg‘D˜q¼}™K4êğĞ¢¶œgæö˜ñêê+§’ò Ş¤²íÙ©øY&\QxRwœ`%k]3uÖŠ²è‰ÚidqR÷½ÃZç‰ì]Úi}„•íäı½AİÕ'e,‹h+$ŒH xq sfzR7GÙÑä&_™xC=7)$nÄ­tÂ”ëO$G¡Æª¯
	Pç´OS÷>€MÓÕ+:´ŒW 3p‚Ÿè3•Ì^<Ã¬Wºµsz‰¾R|¢vwŞ ·{…ˆJïîV‡pÖ’z=iP`Æ<*×uÅúyU¤’şçåF'½/7e3ìª¨}³Jßå£ü	D»€t<}2~ÅgëÖø‹ó¬O èá‡M²*à”¾ôšDmİ÷`'O=½4`×©#½)Î¤¿TÒ;Ài>‹u•¡©¡ã¯:Ğ®tÏİšÂb‘<ùı§Ïqüašm‹îë•¡¿-Ù¨Øü
÷pê`¢%‹tŒjl/Ü·İñÀò?xeór¹1ˆ:nÒòÉÿnM3m°r‘Â9á0qˆ—h°êÙjM5\(tĞù`ˆìßTYøÎsõtúäıÖz—C6å†ƒŠü¢e'Ñîp‰BÁ‹OğI›|½]Jù$=„ ùõ×¦nâ<õç‰Nt°÷ôâG&.gëlÛğ’© H0V>lË>iùí8Yt	RÉU×ÙÓ>¹#f"°Ä¬&¥÷^^™ä„<;”bıİŞôRoœiw¥ˆö‡~q…Z»#LrNBnLFMšäº¤JtÑIŒ`Ç ¯P‹úz{«<FK]mÇ¶×Åy—•¨RÁwØpkqîü;d+¯901Æ	ôÏ`ƒî³¯$5	:RXg¹ûCCj.áDFX÷–¸;EG¬™«tD…kJ 5çÌhÜŸA¬ œÙ„ƒ”5$½'™Ì‰Ùh£ì›º_7Ÿghl´r„d?ˆˆUËŞ-ki1SŠ1,W‚›ù3î¡QH[I#Y¶ş÷o ­¬·xx½Ç =X¶F´Šd;—™¹İZõä5'É2s¦0Å'hp.zİÃ-Œ²•¼æãdO¸ÔôKµ„XÈ‘¾±œ¸ø8t2MÛŸUÃ#½ˆ–±êU§½Y\8T†Æ¦ãpıÅz…ò¦CÇùß)û¼füF‹İ‘v»xÜ¬íÈ™¯šN`Ãà8ÿ;1È+5¦ÇP9(_'~=1­ı4±¯Tyç,0½iÆôéÖ•	Rn·e­dŒ¢l«ãQ÷m`’5Ä6ïÕÕ¹Åü*ƒé‹×¡¿õ ~à
(ë‹‘›½ı[01·)wy¿~¢K[Bse?hÅiyûß®é‰“ò™™úÄÿG` 3EwpGCfNK²O‘6—Qı¯í`Íä·¶›%âÕ!%ôjàg¡•@;‡ı%nf€öíqÒÈG”]Gò¦ †ş\YJH×Jşïè]ŠMå‡]ÖZh*q€>Üä9Øu7zf–Şe²!c†è2%©*’ ³kº{h!£‡•¦4@Í›ó&†b)„aAR~¦æƒµè,eP&pæ^xbTÊÄ‚T†È¯b¸”&ozUksŒÆå7~Í¹y›@U‹§ı‡K{RÚÒÔ4ê@tx>FYÄå±ııÑYpÓÉÿÔ°•M°nÁ¯x¨¸j‹µ—~Fçjñ§hÉøDJé¬n•ù•¶Õ÷gÅ«{pY´Á9=uã"öX¢#Œ)1Ğì{´P¡Ñ5ñ:ú8ß+_ÙÜk¯m åûˆ`³=o¥èºÔrât|6ºGØÃc­;Ü¦ZH›á(ûó<¬ovõ.ùLôª§²µÅV6Jço¬›tPFOî$q›á#4ûï+êJDMv&/¤"ÿmsxøï‰h–ğ©«sÇ+œÁ—Í×­£8œüec1¯UÜ¤1õE*áÀ emxÜ6cfĞ ÃÎ~Ûc…ßó¼ùHÊÓ#nıåĞ¸N´yV½pƒ„¸œ€UdPâ ëèi7Bî-É •(³ìÈeº¢EÚ€å%¾u%M{ËV}«ÑIwá>ŒÊíøk€Íš,øl¯³¾Ó¥lÓäõü·àwqhÙˆáìªs®S/ÔSwjOh¯¸Ó;r™ç)êÒívÇ€ºÖ– B¿e’²ñÔ¥Õzèç+¦ª)rw¹ K¦ƒ‡!ÿòR´(À«{±yH;½ïBÑ·»À²ö*rKçvæQ!…á°Ñ-€„+/û	—YëlÄ@4§Wª@2Q3€L\ı$Hå~\Ê¿bò1×Î:_8ÓÆ×Äz¨_be”4Æ™[™E™,Ù5õeíHĞí„)ğ¶O¿NÅŠ+R.<³&Œ·i ²qàÒJiêğôaD¼.¬¾ëáÒ–@*L2ò²¸®¤qÒà3ÑÅÊXƒU(êÁÁ:fM¦<ÀÙ9n¨ù^zsí¾‰AŒšïªUÀ‚¸²ùóø	Jó‰Î%Ş]Àú»eg-©;˜;`ÏôÍUÚ÷¯W(í]ˆ6Ö«Ÿ@%=ˆöÚ£â˜á›`¿B¯„bõ¬€v!•ÃÅ+²­æ–Ğ¿P~®ó[PêÚE>Px;ª±Ã®ü.Ô9A4wÛ×Ho©ù‘>AŠ"\ÔÙÌßIîx›Wq¬6Q$zßòš?”öÑîERáMÇvÒë"3¥Ïo4ÿ«Äu•{çk|±å#W™ëË·%âè>\Şpv:)Xogıó¿3åÎvŒT>Ë¿,VcÓöÃÔÀ¡m¼u¨ş		Ÿ¸ÇŸë	ğ¬×3c‰Ğ0©ªxañğà-Zê˜«XúUĞM¼zˆSŸa’b~m~U1Œ>ÃY:É’«î€; ¦Ì0Û¾åâÏªêßŞµÍ]¨®Ûœ,îÃnYM÷´Î=E55‘¶åµ… …eØŠŒäİò¥ì‡ÎDâ¬JèıĞ°ß½ë˜èØfÂ\`|y: ì¡†RÁ“`É¢ªÊµ€M*ußŞFbÛ)kóÔç¦ç'ÖDÔ<ü†f‹ÕÉ¯ÆeË:|"¢_ÃÄ	Ù8°FĞL†=±{=¥'Ñâ.# 2,>­ğñOsØ*³Ë
ƒõ¡#};"å®úİ•‘Œ–\œw[r³A½æçˆ/–“+~F¨£÷ƒ›Æ‡÷…’—Yß,a•H]¥)í(ÚGP8àqKp»ŠKã/”³‹â/ã •‹5iÜyZ¬ròfå7º(®‡1H—we÷ÆİUl|«È+Ô4‘G\èGøî=¬ÛŒä/†#jş
Í\ñBÈÒq)Ô"{wt0cÒ›2ÔL‰£qÂm‚Õ¥Vğ‘¾Î’yv
Ñ6™Ó‡ÀÇS WKôGÀEıi%u¤¬ü›÷o½å#:¯ëàçW^›vƒêhØ2~vÑ<ùöŞ4#\Oıä8vª	WkèT÷Öˆ"¸®LôK¿4ˆy¸…?ŞuM~¬&`ïYÜÍueg©ƒ§:ŠUÏÓâ]ÌàóQ~™J!cò²uò7Ôë¿#¨ÁşÅ©à;‘b•"x\·³*º:É­œ£ÚœJ”İë÷"Õ‹i'ÈßÁ½ıºÁpHl\%Z+9—ÌÜG¡œƒhÙÊ#ËASyì ï‰Qşfd˜_;jõiõ<QB`4?sW­Á5ÕÚaÅÛQãXÇ¥6à¥_ãÕV"ıl+=«Õ5˜zğ¢ì³pÖD7{PXæÙ#ª­Ü¿`&RôÃÉjë®Şt³à‡”ïÚZÇèïwMÑ:å²]JŒ£.-•Ùğ'Íÿ"ÄQMÃø™îê¼Á¼¬X²+o'»n ÷Í<	~$c®è½S?c-&pë•w½hp³;BºûFërñca·p¬Úª„¸†Ç0"?Úc„Wç¶´ïKAC*ÓÆ¡>ÉpÙÛü€”‚¿·É²÷õ7¾ SÊ]ˆ9îv~Å	uÅ™RºÏ`À·ßSS3âìC2.Â_ñdm‡½I‡1¿b}/ÉØS‡Ğ³÷µü‰Z2=b]Ú´VŒ¯».„·¨ñ™½ë˜Kƒ’ÔPY·²¿]îH8-ô@)Õy…Rú¦Ófæ[‚–Eûq7ßEh…*XÚ?o‘,–WVU4T+ÿN>½—ñDÚHj7GRK¹†«=×‘<¾›6­²6y°é›1
lÌñ‘ô²Õ¡¼¥ß›Ë¾|<‘.ô¥fB–¯M¤sôÕ™5³”mƒOxIIÖy£ùÀ@Y^fJaˆòD.Š?³ík³ˆœ/Fòo‚ÍÁGÛBbû@r&ü¢Z6òR‡¡ùfoÄÖ9slN’?˜;Uhá§Í=Å,¿Xç‡}K°1|êÄ7vc õÊ[+¤›Å®ö!¨æ@"‹Ê~ºj Ø`İÙ„•"½9Ïó¢V@‡vàğMÍaaùàõ¥XafxËÊ€Ì%„ô,înA¹ëÿÂ¼v±4ÿ;²×WqŒW‡ñ1]Qˆév×.@,Í½"ß@1‰*ß˜±|‹ñ9Ş—d¾€*è0G ;—ò½úEŒ2wÃË©¨]Zı ÆİlÆcŸf+–·İ$ÏÑçå'n©Ì-oÊwfêúnOŸxøİó2öåKƒ–é[WEzøá‡+NóR~H7Ùvhò§4åŞ´îˆ–[ÿº( Œò%ÉÓ6ãP‚S˜tEıH€ú°1­“)‰Nòc×Û;-déjóM|o]‡ºîê”í¨*¹Ñqˆsî‘öJ!14¯&?	_†x)©w×XÂÄú cz&&Ád_ë¼~Ÿ‰*~rç0IÅğ-Îı•Ëÿ­#-ä=ı¯™8s£|Óï×ÖÎnô^lãdÏ%›Õğ|¸ŞÎà³BúÏ8‡rËŠb5=ºn¥“Ì<ßÅWÁ8uZ~Ëq£Bºw~ä	Û­ã:˜K£“'ÒoE•˜ ËSË,{v4âóÀÕ6Ìèı³)Ğ!âƒb$Bµ7ê0	#LWü÷åqm(:‹/+YÇ h˜k©7í¹Ñ‡İ˜@¤aŒURªƒ¦ª¦ˆç0¨<>)\pÖ)÷T"êJè^ÔBÁ%MA~™,˜k{ÎYw§”k9JXØ°óX©:™ÉÈÃ³Ùn	Åï±Ó'×ø÷NphÙâ`CŸ…¢ÇB0B8^È%+ßT ¸ƒÌ±ïtß,oµ>
"À*ÔB¥¤5l'v	¿ÈîE4b‰õG¬Jü[i08Šß®àÂ’´ªÍ)§§F|^‡»æ:´>BåGBAÀImÔKoÂZ(é"Ç_T¨-ƒ_`Œ­$F69çâÇ¯¾æı3MËÁì#Îã± }&UW±V[‘SÈàúÆcô¶&àve÷QŒú!ÀTAÅßÍ¬½À§ÿi±Læ: áğßŒ0˜7J'Xç.Áõ`+Põ¥6¸§ßphŸd¥Â¹h×xÍAŒ­ü+|™áê$*)jXVêQZ”¹±<EdÁ·ùäNkı	(ætqÈö·}oc6E~–yœf‘—ˆîÇ]1°ÍìoŸäœHk”´@‡ô¸›6+Ô"Òü6[+Ä˜¼T=¼»C^!]Ñ(OnªV}İu<Â) Bå¤9KeqÚ'W¹S'cÂÙà-İïÖ^æ¾™ò‚½'Š,£î002O–ûÀ_rÕ-Cö ñ,"–Ég]êª®PJ—ná0ı¤¬… ÖİÚk%Şº·[­ëx—¾ûbåô
Ù3ƒ3Õ³»ù²­JoĞÏä{N‹wÃÒ¢C!_€‰HİhqºG~®sìôğc…ôª#íªc©ZIò<8Ã=ä/=òGveu¡nÜ.7:ĞÔ=‹×YnÌH¨ÛƒSâZ“3Z2}ó¿iÀÙ(úŒïD:“ÂSê|Uv×Á]İØ$pö¶³ü[Î+µhrPÎHâ¦Š±+ÀaB¾13h2¾"gÆ[ßŸÙ+…Şµ*¢â" We
ıCˆ|¬ScµTñ›ê-‡ èNBÀ°u˜ş{Ö|òøÄ…¶¬¿[ßÕ¡_¬¡(3ílùìfĞ5@|”ŞJw¢’ç’–ã=×pnÛÁî­Eï\.‡„L¯]CQ¾š\§J’YÆ_®üKJ²ú´w„ûk—l\î|“”ÆÀø`ÉC]p8EÎ«ÃZ˜}Ù‡:åµ31îdG¤nf))ÜSô@|ÿ7¨yBû5U±z"~ı«ÑT{qå[–¹º·åFSÌ¥iaîF^UuÖI£æòö¹>å9#»µ]óT½|tà:îN\c)Õ÷sRc3%L³D”½–x­»]ˆ§1DÊß4Öµ/‘·zSÖYÂŠ=òâÕ+h>²S=ÒF"?–Ûv%)S@*ğ0~ü
Şl
w[Í† lä]½r­½ïÒÕİÕû²wzª,ôiåH“´•Oñ:ñ+—K*,Bê¤¹ê=ò,e«µ—S‚î×Eõ	PóÇnôNmÒ ÎE-ùo‹i¶G>¤ÇYX§²Q õCãLYşÛJøjşt>üNj¼¸EHw³¿=‘Ám7®ÓÕfÕ„Ê®DJxõVö?Q\¥%KiÍú Ì)qçñjÜEÇİğ¨a¢tÚÍºUdr.P„A’}t¤ñI‡6r yAT•ñë‚­Ú!°1Àbº…¤ş†]!uğ–fh”5kõ¶ËVZ¼i«t¡ ïF¦³¹ËìsdŸşÅ.’±Ö!kÓü/s`M—	á<Éh†‘Í¥ $>;›wšµŸ	&NÇÖpÁòÊËÀK:êaàæÑGÔ
x© NæW˜Ÿ¼êš3•Ô³Q²)»EæŸ{3×%™D%XUWSmçƒ-1&x¬  øtØn¨£³óì.e7EôÖP3ªä¢ã$şc¯9ƒRJU„uV²g}~7Z)$O„P&±á wËc·í^‹æ¶U­‘(ßFï¦ iqÀ™T«RŞææ'òbb°Ğ×–Ö¨(ò¢ñ«•%§á•Á:ïÛ3úÂ}µ7é¯r¬PµèàKšì ¤rsÛšWåeç¦ZC¬^Ï®—"ú=#M£)Â‹¡Ğ.&æ©w9WÈÄ°É´|WáÅ¤ıS ‡K^¦»û©óÜŠÖ®o bê
_·L eé‰»ìùŒQuÿ„ø÷†«BñŠÖÂUuµıkº»¡g»²Æ“»}Ù0´€kÓ©Z¦}oR)sKÚPîB…ì ş |¬0…˜ò­Ü2ˆ¥-¤vFûå«şhZf`4Ò2±:Ë^—Ø0ğ’—q |Çc®´‰®0Dºãï)ñ°‡¬Ä§_ÃG¸²›>pÊAÎf–¯Å1.yÛ¦Ï7(–ôRšÎÏ>ˆÍ¦ópB%Zd‰†¡Lİş	sßA•@_˜¹s¬”1ëşkn¯[Yäµâô£û·9rm­+ü”P1mÂèeû½
e|ùQŒ“(€ô+=GĞ9aão&b” <ûŸÊT9ãøNn …MØí±%ôÏ“Ä3PlX—I+lÃ'¦ïÚ¸ĞöÙ¢ø<l—*ÏBH3Øşvõ‰V[q°£uÚÈßù›lbì…ãH]1 fîÑ"ğ®¯ç	‚ËPŸ?wDS:çÈ-5H›Ù«xßbAúÀIƒ K8d7#26¼Ä‹3@qÓı«ã8¨¦$ü_lÇĞ»i8â<-„-”‹oË'ª°êO!âûò)ö£“Ê¤Y¾ZÜ“BÙùŞœŠÁ-mbîºAúCá‘ø¾ëHmcŸIùh:’•Sy„ËOéí¨[G¤l,=xE1´­>Ùê†ÜAeÙöFfÅå^ı¶U&Õ‘kŒŒo‰ºŸØt™ÃHLŠÎlE¾HÈ–_êÊ~æT(r™~¹üûQOSL.hÕHh÷‘UbK"ƒfŞıc‘El—»¯FêUt$wx¨¦Ô¶Tƒ.{ šœ·ÊÊÍ;‡Sp­Uy°¦¬…ó]u&ıi+ïâù;‚g~°ÁQYˆ4Rùf°#][	–Ótò9® ,øS-ÊeÎM]?*µñ<FÒE%‚—g ©gcÊ‰IKÖ‚Á[Ûqa7d·Q“ùçf	ò”vÎ
'Ã¹¤å@ïÂ‘%)Änà†&Úé¾Æ5c,Cµh¼“ôô—mŞcA¬eôf÷ÁäH]n„¿ê´Vpã¥/“Ğf>iÀ‡¨”¾Ojlö´¾ŒBÃ™<İ!~±wlLGƒQY“›îÚÑ˜›ÇUù^áGQ©ß³ósÎœÍPQŸFş‚f•P4(4µc|ãïtÊzóŠ÷+j"h³}¢{ 0r$³÷¡ï~e?nÁ7³ˆDh”ªTOø]†æY=Ãèfmú´‡íÚw_—	q»P“5ŠÒ´%ÆşıÜ¾`†±J”ÎnâI.ˆkßzÓ’Ä÷õT™âòx&6ÄDuÍ–iD.´Â¡¬‚b6¯_ú´ì@
Sá¾­älšªãëŠğ™*&  4Mš	¤J"&mXÙ›ÇY
RùB|w'à
9³‡)^eìíjA¡İ¿"¯GæÎ6|6³  ğMÓÊrnš|ke—ì"|½%*	™íE»üğ|>‚Ü——kšÅgq{W	¤¶ídÆ¼åäŒæäÃÄ¡+A˜ÅõGö'á‚‡9K¤š9n`a†G{G#Ü¼¤ğ5!F¥ ÛaÕkÌ•ş¿Ø‹sb”™ç	ıO\LHÜ½<?ŒÓhKœ9ÉÌ¢kôFqiÓîÕ] .Æ†C©ºxÁõkşÜ¾æ¾yÏ^¦	bÀAPF´u€Eà½Æ™]×Nü¼W8X~?[1ÓéM¶j'–èõœjTYulOO{Rgº\g.½ŠÁ[òqíêb¬›J¿d‡Îœ’-U¨zmhš‡5:JHávË{K6Y,m²& _9½v¤D"77E‹“÷0+å&Î·‹}ÂBŒ3üE YLmêp/`€Óğ®{QÈ‚¾ñ¾RÙ[4³¡Q²‹9’õ|ßïÇğcãã~Ş7B¬q–œaËŠ0Z_;'î³²K
|¬Vô>g­èôàš(²1RÄ/ÃÄé†â¥Ş3‰÷}3P'¯3Éƒïg5òÀÜø‚…¼şôç=ÎãJ5•Ô{(Ê·TT‚­ái[T<i»¨õ‹…ß'W”,ü‘ÊšÖLñÁâ Õ„]q…‚N€gæ2nö,ïˆËŞvøæwp(-æäS²ÆvWÈ†óŞ˜Ëã½e6­‘ã
'ÅÕ’(..ë¼şÖUò»óúŒ×Åyv&"ÿçp0n­Lbîn´£	`|pC°4ß§~
q¾N¨‚3*ÜjøĞ2Æğ³nQå~š<é·5=.~ØµÁN}×y‘Şøo!‰X‚ÃÊ'XdìİĞ€/	ÚËf~Os¦‹‰€Öèrçœª?İ.&]2Y[à]•Mæ+ÿ5Ê¶ÕÀçrú"¦¬U*”Ù‘ïşƒ“ äÂÚGù¡bG˜å…£ˆ ‘’“á¢\§y`¦!²#ü>jÔ“¦ì€y&Çmf…¾² ³¦}‘ë-QŞÊzúyM9@Õ•6Éá‘ñÿÙN@ÑÚ«edŠCÚ0ù6CîAí@
<áıúË´¦ÒêAÁ}aé¯4'X8 Œí	(B)[¿ä [3Ğeˆ;½hŒˆH»6ÌĞ_Ò:aLlig<TÄZ5ã Ùø6¡sôaÛßvDÃÿr4Ğ‹¾=‚¥¬F˜_q1Ò7¯âoÒJù„Äú¶Çj`GÀƒ’¬¥
RşaÔÀ›°ZD·vE¡Ò•¸±#V_
z	ÅË5üíµZú-¶KÂŸ¹Œªó7D€+aŞçj†²”Ksr#º÷ıß?–¤ë¹iğ]RI­Ü¦Ÿ­{ÙH6á§º\H™¦D53ÃxAÀF¡>9GçŞuWÛ&À®sùı€Ñr—c—Uæ›/?µ‰O'1Í«~»!Ç'Ì„Ï'7ĞÊİŠ¹ÇÅJ*—Ÿ²D¡µ¶.¥¬Ø´$úôêL·}8…+Ô³Ó±o—ú´dïÄÄôÔ Ô:ç®î=DÚNÅ¾üÉ­¬ívö+^üJÇ³|¿U	ûdàv	å ®P‰Ø£Äª%'«kwËá–‘°"A”£]V1ı=S"®¬î:î;€½>õ&Tš‰a}.Ôñò‡Q•ğñù…L’##´yæ¢ãË=ëÎÏØCgbñúİ¤Ğ&ĞQ›$«KÍâ…¹!©‰I·€’™@
Ù‹è–QT§½\op×¾Vum“[?Q«Ë
%óšv²ãöY#zùğèõOLŸøhyú óÍÍ©×ã]±|8Û\r)WY!}V>ÏÏüœÒ6@?Ä‚µÑçh±<fâxùæÑmï]g2gÍBK¢&ëJOa¼né˜ä»>¸ÇÃXÙ}RPÁmkaÁ¹½bv)¤PMÁÎ<O7´,W«êç²Œ•ŒÜPÈ¿…È,fáv®×F§NûQ`’á®M.EùÏp´¬ÜK{Œ‘Ö m0ÕAš¥ú³±adjt'½éÑ·½Ä3V»ßAÉi»ú¿ÇyIå¿HÛ:­s“*¸–¢H×{¡*Ù€¥ÉÆõ„3PKü±›¦TçÎ‰;T 6Ş¡Bô |…êã³ú•´ı–©Œ1ªlMV·j[ûø´¹3iöàÓ-9û)_ñ5‘ßÀ­N(l¨ïäB©Vòãã=C)ı[b ×ví„Ö4‡2^Òqÿëc€8`0—b%@8B»ßªi*ıuû1!øzÈº „OYï%Vù0µ¥j0†BûeÏw}:Vğu¸`+	ó¥ißÎäeVL>¼JLK‰šæ“Ş\	°Hñ!²ğMu)[UÈ%Vˆnç¢,¯âFGTÑX–:+)XBeÆ“FƒeÍ4‘ÏFÓ`L
ª=¾`èØÕ©Õ~/²ùgÚ—Ğ,™‹Âx8W5ñ¡‡×îÂ<˜0˜æ<-±ôB6Ü…!\ü™ç„B`w'ı˜èËƒÜR*€ª°¨ƒ;Ğñnhª_JbbÜÍ:%0ŠÊ¬ëY|
H£rBóvƒ	Ï&|÷G%¤îôA¿yàÿ
}JÛg!ğt'‡4G˜iNÇ±2’KÄ£Ô)cnŠq˜ØŒâ»JÌ—ªJğGö„F¹|ytãòÿ®»ÕŸ‹¢†ÏXÄ=µ%ÇÈ£>´>éQ™õÚÎ¥eV mÇSÊ1—oY4îD‹öÍÿ3»º«A+šÚ!ÔÃsOÊ){#;ÿ=` ~¡iR£­òR¥M˜„™®^èÎ“}ätY²ÖQ‰åèª¼Ph"íÔ…·Ç¢d¹×§MÒÚÁ§íêÓ ÅO²òÆB›YWS—ÙWá•÷¢Ô˜¬ø ¿ŠÀµÄ°v.åÖT‡%ˆi
	]\] Úˆ[éN'“e9_®Ü==3ußí¢˜ÒÀLÉ•şsk®YYÖüÚ©é¹ĞP¹ÖáI—ß9ÓÙ1’E—™47«Mcbšq•:<²Ò4	e®4ş›œ?)ÊvñRüß‰P §÷8ùg}X˜õyaŸ}üâÆBIòèø®yY8"s{“Ae¦^ê†ì	Æ·éØì¼BÑwÚW‰"Û¨¹Í	J#ô”˜a‹d¥“ğß<…Õ:™~NŸcÙ“T6µ`>î0¹"|%j:–˜D‹º»ìGŒØJÌ¿(üĞJŞ¥…zÊÓøiXWàJ;ÇØx¸íu~Kô#zP£¥ì”½?|ÅX%€;6bnkª.Š%iô1ÍË!~>:«´ã.   Å‹˜^MdbV    D†céeñ£m Ë€Üt­Ù±Ägû    YZ