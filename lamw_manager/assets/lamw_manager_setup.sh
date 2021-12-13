#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1493874499"
MD5="52dfc7486e2050f550248149b9c6bcd3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23964"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 20:00:30 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]Y] ¼}•À1Dd]‡Á›PætİDõ"í›SuÛcÈ>çyROğïŒ*úV_FÅ½¨Á<AïçÇuñÅ!Èµ¼ÓÏyMÆ	‚úØmTraÄ./%%ªËiË"n}Ó®üD³´È­ëã¬a'¡İT=x‘,¹~
i:0 çÄ“´=ó8E¯¹À¥ÖOj$F’,}5cïÿ^v'½ğ—¿G‘· ]°µ¥ğ¦şH~ªxÆjç—ªÕæbù•ÄSîä…,¡Y`¥º£%ı Ş`kâfrà`•èfmÊÕÑq!Ò@t—·ƒC‰dÌÒæ«½ö²Ñ9T¾lüŠ&La)$=’6k–£ÈÜ¢Scoû-›Y¡*·î¤<„ã­ˆü5[¥Û³òùw°£ŞC:x›³zæĞ>Æ˜¡L
E7á¹2Õ0Û®UÖoùŒÈ›Ç«iû¶‹>y‡q)è`ë•‰á<Ü¢º ûZUÔ¸!Ë‚oYÆ;qsyÄbL„bë>çjÿ³(Ş>â\­çVeİZ®)AÔKNĞÚéÙ?ÿÉ"|ÙÀ†ÊMOW>aA6«|*ÛŞŞÏÄyT³;µ1÷…)”¹
æ4•Cå·OÇ­A«µš2uÙ qÙ7Jçå¡¶êÈ¥réß’ğ¤£lZ^îúD–h1Õß½h¯J¨”[ßK|+¸rHJ†¤ÌëõĞ(@}p&£.ÆäÕ{ÄŒwZİ	ĞcRÏõ-od•¼&£TÃ6¡|«â3Ê^H© Í8*°ç­İ\ƒ?<:l‘œ—èêŞ›½D?à¾ø
ÉÕBtÁ_Š}mÂ@ıo–ËşU `†íğ=kÄOşæŸ{ºÆÜfO=CäRœm« äï0H$E­cLås?—}Ây£å¶’\Z¬&ìAò·@ÿàa8B?ÏŸ!fl±m’í˜˜:x$?æ·@Úq¸J£¤bq^ò§†vÀpîÏ@ØÒXF-=Á¶å«ñ'¶w6Í‚›qÿ1®àVïúÔÖ¥Ø¬“ì)'m	£—ÑªG²J»IêÁÄNt­ÎË=­/j´6‰»›q†~¸±‡NjvBwõ2»0‡%€ÿ–%^ìfj†ÆÖXª-İ-‹µ,RPû¬ñù=û4#ËfÀ±²ûàˆ³$zbDÆN¬º„Ãò`‡¨LjOÙà:xü>¥J7{ÿ£í;(lÓ'¨+~»ã‚A™ ú ¢Î­øÆï?ˆh³HÖ#8‚´Õ"˜h.‡E¢#
Šp³º£5˜ıMÅÇ$şâ”‚/@3kéxäøÃx…AÊòÿ2,§„hùZP/´ÆØdå˜H­!º§×˜LI¢Ï'çù¥WtS4“éÑ,½nPŞ<Bz3•²ªVpu-=fá°ŠYŸã»L)ß¦İô>ó!³ÈÒ·?D=ëAi²ŸU‚üTIšeµÕ:áp>škOà¸L’£ıÅm:mhD/¶ÄÆæ¸w@é…—P¨€½â¤¾L'Q‡‰ƒ9eÀSëK¡ eÃ{ÃıK7ß™÷ÿ4h!£1Ü¨šimêOGš9xs–}›²Årš±ëÂOuNC[ü] Õ…á-è¥-hY ádDáëö%€JƒÍ¶¯o+Ä$ZºÑÆ‹Q¼Z¨ôô!lô(aí5VÚ5è~>-;æ’øØ“UÄÚà‹Î¡1lšWË©Ê¿ëµ
2†X |æh¡•cÉíÃya6·åpEñX_Œ8\zßÅ_€;òı­[RËôlWš@:u¡¼‚Ğ&
­UWÄ'ÕJïÇê0,¾ÉÊ=7 ë/ÑÜï–ûDñ Gœæ×éş<½MòÆ²CM1®†§t)Éı·h0‡–Œƒ»ı™X¤?ıı¬ÑK®¿¬£Ùğv´Uh½÷ì†T–‰‡ÅòrZ’'À”Óí¯,Ô†*…!Éu%„sªÒÍ>*B2ô§£¸b+æí/~ÑêôHKíp3÷•z'1<š]Y°\äËÂãºUß9kl(÷›¥‚\!ø•(õ÷3"¯%v%V^š·z#	ìNÿTu›h>i° ¹hƒı‡òW)*Ûp¯Bqö›šaiúrj¶ãİóŞ„ØÉ"»Óü)ä‹aKˆ™ü…;cTn+Ús6ùY=èEş0&,_Âeú`!É¢3*r‘ï5ë”Q7“÷õı&¾×¦"¿îä™ŞÅÉ¥ÛÌ¸^Y¯ ™—å.›Ì.åd&/ˆ“$İË¹$ Û¹í€0 @3U>¸/åSù±U®Fá¼·ˆ pT9£?Ñlå¨lm¬=¼\(ÛúÀÛø¬ì]aÇ+[İ]ZQö¨ù·Î4£ Å5öXBÒşÎ*³¸Å°yû‰Ì­uRzá•øêñc=LöJ7šøcÊ¦ÔäïğÔ¶BÙô>îˆ"¼©¢VÍys%,ÙºÃD{„Ö›#·äœzÀ.hìæê¼rà®¯ëáR€ÖU¯Š]¡Á°ş9ØÏ±³Œ <€ ıãÍ1­'è×ñ24šTÅ,Ù,©=o49U`ÃB³­T8d‡àÏS¢Ó¡L’'§¨.nŸ®ş-¥Ùèëßü7êÕ?‡8h`©2Ë†î¯Ü¨û·÷cšNüáp¶òËQ€´CÍdo˜FÅ‹Ô[¼İ$o‰ät½æ—ÇŞéàøÏúFTÖ¨d”ä3Â@pÒ<úqQc‚İ¿}49i,v˜M2¸Âuâ=¬E‰§èQö¿û@šQö¥ìºóá\Û„îJŸÔ2\£õn÷nP˜è–îXèr¯U£­ ©¿çTú±sëZnn–#”¸¿6+1şõÙätHÂŞH¶–xüCŞV¡ ¶8–±ëø&êåÖ ØÍ’UIC~•D£Ü|İ®†ÓN™¾àÚoˆƒìHƒ}HÚız<³š~¦ÆMI¹ä¿ø`”šCYOLI4ÆÛ"]·©ÿ™dªP/ìV)¦i¿„U2/
«®º.SCPn‚¢µ+¥Œ)2f#Hüù;®úœ73kP×&­ë"UKõBÙ	´’—!±•m}XÆ[ƒ±å?¯ÿLÜ`7ûGlD.àÆüiV‘q$…˜Òå­d 0“|İòÿO‚ƒG<á«¶ŸGîàAˆh‚¥]…_Ûá~‰1ç%mÈE¤ïÎ¼XªP·¯Úm³–Àä˜ÔtûÂˆ¯å~èqïGxÌ¹U³¢(Q–,¬•ëjÙåúÂrgïzE7ü«D]¥hOñx£^&oIaİŸX]òv‹rSî%CişUä#œOà·â^ÙJŒİ9æ©I¦õ™¼÷¯Ğz¾Ô×Oô¥Óˆ‘ÀÙFÉ/!Ù8Zü‡6Ä>4>EÕÀÃŞô”à¥ßb»;.IÀğt†À¥_ƒ,¬Ö^2%J®ˆåøk(úc
ÏÂ=ğóM="}†I"i<ª¢PAï®èJVìÙô ;wÍ™üN¦=‚}O`)[‚s„xÏx§üÇôû£ÿ	+\G½ø8’\'@I"ôÿ©Xù5ûòñ3ãÍ¹¼£‡ä¡ÿ¾ûégá	¹üû†÷×­@ªFf§™JİPÂ5¢_2¢&h…˜]¬ ÃLªËËƒ	,qÊ4Uƒ ‘GŸÈ.ÍƒÉÉ¾ğÈì6–qFœM³Šæuø\Ry¾‘Û)mXuFıu$½\-Â­¾I.™]şC•‰‘¬NøŞù5‚ÙÜ³ÖHåñ…ŸW¤ŸòL½j;µ—éb»Ãi¾ö:M+1#ß=$ÚÔøieîËŒ¾÷ßM"ç8}31		4Œ	¡óÔ€ñŸ‚Gİ-2›ã•,}ÙtÜ8A3ÂŞ~ƒÿQÂÀ„ŞbJTŠÀ‰Õ"éL%Àê'ØcH!V4T˜å$¾Ó8tŸméW8µdõÿÒ'p‡K~§Åä$V‹Şœ“@˜.t~¸Ó„,2îĞÀô*:½WÖ4`n×ïë¢hK³Z(<8ošM>€n5Å›wWNÀ=?á¥«åjQeşæøÀ?Ê˜úZYd¦­Ş²Êc4Ä,Põ¥s†æMdğíÛH…šƒ§;˜y”`»“©*%€^¢‘?°3¨ÙFgµ.TzÖ¼«k³ëdÚH€Sû!M6Œ Ìƒ%vöHñáİ¤¸Ş¶S~LÈ;@2NŸhvQºKcç÷£p8¥jD^Ÿ¹Ó8âm	mY-×Ìh:P? R¬eyõ@·QgD–* Ml ƒt`ú\úAS©"L5mhØ[mCõuó’—îq¶XSAÏÆ®fió<>vAå~XÌkt¨‘µ5â¿§©A	<w0Õ¬\]Á@&şÊ×Ì‡ZÌ-’Ó†×ÇÇ(Ò]7Â8œÙä­7ÛÄx{Ä1µd¦kı"¤tàÜıõz>Îv˜şV¾Ükıb‚xe{Ã§äÇÒåqXQ›îüjÅ¶L||˜O\ß&pİŞd+õFúşQ^æ
Ğ·’—îÆr´ @ù3B9½yú·ƒl½:ş^üõ½ÉÈİº—“SÒº¯ÓŠßÿı0ØişMÎ0x{áİü#Yì>ıyS–¶r€çfïlP®'3(4_µ!±ã©,Iïá}$\BÂöÛb]oE×;:n½XØVîz{Qs`Ê4(
[©ùšÄç4¯öSÙ¤¶Ëİàç£œL¶&ğÌåp°v?ôÄé¤;Y¢ÒC¯d3ĞCcØcŠ.­Qv«mU­¼0æ½¹Ëóès¦ÊôÀğo®¡.?ScB…Tõlñuëú"Ä2X~˜Òß{ëÖ¸¡Î :Eñ/«ïvÊ€q»hi©XRWùv¯œ²ã' §K”ÎX÷–pœÇuL—^üÍa{{T–®RÀåÚÁqı=ë ù[ƒÚ9ƒ©AG’%`ÇK>8òY.†àNTêîNËß8‘İ@ÙµñtU„Œç²ğ*wê:¿†š„«Ã5~œDE“ll`>¿ù«0Æfy=í8+¼2ÛÒ>’QÙ¾•‚+‹Æ]šÉFZß°xN±càqï`>½¯/F/_¦»4¢åşšúù-'ˆ"ê,ÀI„ÄÊßêNÚYÒ¾¶jÃ0Ğïæ†Kp™*v›Ù‘´OâYüığøá|ËºgìÕàÔcŸŒ÷¸%xw½Ì}Û?ixeÑ[õ úÓËÓ2%sù})Q¡ŒMİ¯â.€®5v\9¿o¡€bF„«Æ>BµLUê”<)ÍAöH	£`ÚG²c
¸Áñ¼\PT”èßúœ²¡âk‡È2áû¯Ëu%XçŞ'BÜĞø*²B¿Ş~]ĞAôÔõ€I˜dW"	}G÷}Õƒh0£7¸&{_ád²Ê3>óEcªBñMœÜ³Ü>ú§ìcİÒ®Ùğã)~²Á®Nœ	EÍd…šø—`èÇà?'O•¢nh^ÇØ brÇdaGÑ…qñ	¢0øKó4aì*…éÃ'´aëOĞ'‰ÙÄrGÀ„ãÛıO—ÛÜ-5?ât`óõcó‹C‰ç	¢ºöKWÂÑ7 ±æmå®°† ’ÂW¦ o	v‚Ú›òY³.)|gì‚:·¼±1Å‹ÕÈ+á’ UcØÆCôÊ‰ÕºK©‘€Yµ--èsüpìnMFÔ™Ş£}oÍÙ¤kõ|kÈØ˜œü= „¶Ç‘•à?İr`pl¡	IAëou:Ã»Kçú'·¥ïâ{!ôH·–£FL„ª"¦?ñ¤«2mpÍ=æô^rSMØ2ºá°ò.Ë÷Úfş¿şe`†m™M+G»krH’i››Ş¼XRüºa/ÒS>€è˜Eå#?ís'(”.Ó#æ‰h²ö!âø÷”"Â0ç Ø1Ä+Ê:{,ì?Ûdgdb˜öë°—¦)-Ü¡Ù;VÌ@ÉI©¾G`ğM9~7#ùEE,#6§3NÊ_-%ÔäM#ægp~w€9H‡^ıJÛÊàË|okÿ¶Ã8¸ƒA›í£±¤èêŞP’¢õş™¡cù’jÏ+ëƒ2ã¯ò‰B6â´FMzH’œx$ ´;gëÃÌ
yseTÜæÛù¥°hHtÁHÑ¬T±*­¾ŸG4¡‚ª×\3øĞø8Æw£aÉrÌ,):[¡Ö†5˜JEææF´6§ÅÏU\ÆÒğÖ´ùã}ıK/GÂŠR•H¹îí!z}ÈÊÕO516:h„6¨:Y‚=Ğ…šÉaîÕ!“¿v ”ºLÊm”Ìê½µLƒşâš–N˜ù{[›ATé@aÅñŸÄlãÔø«b‘k³°.ıY"ã3Æ—õ>ÌŸ°!‡Ô¤WsJ‡ú=ÜmÈƒ‡îcŸüıb—O#%¾Wsİ4–ÙÏ¶Õ{-—„@fï“êÔ£0§Tö_¥h–Z´`Ó¾"æÅ)Ç¡Ïôâ´l²úKœ¬rÜoçÏ÷5ûüUQÈ¤NüLœ&ùøœÕ³Íøl!~…P5—²“”
±WèÊØş»Rr7 ÆOöêuk&P³ Å3šË°…ğ¢DÜCÀ%ÉF¯j†Jê¥QVéAX¡Íl¶vß2ÿ“L–é‡ùìSÚÓ#‘êA7JÏzc5|bóÊ¹»+å‹.üÄQóÆÑ¤1®ÂSìŞ˜E+êsÖRÄ¿Üİ?hi^ßû€w’ÀÔjI {2KüW¼œ}Õó@­g‡ßÀfÜ»‹Ü²ÓX Oºs÷søJ‰õ.ù;"Q,œ¸Å DÌªfK¡mÿo”£80-mJ†ĞÈ{ÙÜP’ @İg…ég× ê1^X°¢ùãš*ZÔÛsW''FÌLà ‚û¨œòøÕjş˜A„Á|^ïªD2¿ÙANf­hKÉ·|âtÛáïr^ZùfgF1=gêo¥¢üK¯/wªŞ/â³t§ßt%šÿ†¸aù­#´¹cu)©%F_z1GÌ’³mŠùì36	ò<i,i[-ÈöP~Àè’?Ù	Š¦uà€h¬´S6«§Ğ_ï”Œ•–[›kàtMµ°$í
jß#­pÎŒ¦¨»5³£!b0u¯¿Ü,G7\SÅ­dãƒƒ6ör+h]
ºóÕhËÖ)IQ8˜u-€ãv=n%s+Ãše&©Ó|©¦dQìĞ._¥°…=rŸYMd]4%B@ÖÇ³Gwo‹êp×µš–©Ù-{øËXe½y©'CJ<Hûî"§´p…
z­>¹äw’Iü0]úøÊT¡n÷™{JbÏòıPuS ¸şò³gtAy¤úö©\§‚ìã#{{b_5ùV¯zrQØ	Gª%²2NCM£t•NWÌù#-%üùŠB3“q’óVäÜ˜ïĞÓõnOxÎØk¶Ü|f{µgšºŠÁT&@¨D,¯š%K¶#ÕçOÿ|r¦ñï®Órª<Ö°|tV³3ö(tH^#ÄOF¹SUí“´….Öà²RÌ Wvˆ
ïEP¢Ã¼¨jdæ|ÿe™1†Ìp¿˜‚Å;Ü[Ğê†ËÚRRÖäŸ‡ÇLÎW’;(µNÄ^³”šeçìn¦«É3q¢^( FÅ>ïpåv¨vƒù(ªBF˜ù€Œ×4!®ñÑ½}ä¬Õ-v$"ş@÷ıûpÒä­¨€s*¾ˆ¨Õ¬¡Œ3¸P?ßÕ:€Ë#iµŠMyûİí	qüC3ú2±©\l”ŞdÇ9À«º¾Ê™º©,i.¦^Qï3A1*u“d'óù°Î¯BJ0v^”[N;Æ·´ADº‘Îûêı™IÂ bVzá'ÉOùìíkİM•øÓ•…¿}•¿§E¼Ş:p2d
d€iÄFŞú«J|EIŠ*Ä›=R5Q‰˜Ñbøğ8í¦òñß{Ô,›æÈU ¸ãPJÁµÏ[TE•¢¿ıØ xkKÉ2À¤RÁõŸ¡CüB¨17ª’´*¼œäÇ	ÍÉ¥8¢‡˜vçH!E‚¯&(¤¬¹{ÌØ•èç1†%1¼L#”üõ&˜Şá­Jºmı­¡M¶B²ÖsYg¼P ¼\ëæ©ï¦”CGmNBAƒ6T3ıAİ›LúÄjÂ°Ï=ïá0„MÜØ*½D½dáës3)ı% R'[°š ş°ï³MşŞr5Ó„gºp•AgP	ûá¿‘*†ëÕÉÊê/	q§¼eXûH%²G¤¨XËP-Çı¼>ğš¬˜Éô°ÑG°V³0ZLM#ù
¯D=3æŸ |‡¤aç;;»‹Ã¯6ßBC.Ùï?2şb_¸¥›Óâ¢ˆ~ÄÏæ‡Ûm®Şˆ©\‚€|)v¦UÁ.µF	h²ã3-¡âW¦ƒ[ocî>v‘60Yú
=8õSoçD QòáCñ2üi’ĞQÔ.×ør®ÃØax"|\‹ÅäÑwR_U¼×½ÅàR®	_ô¦BKOÔ‡Ş@Ü×—¿¹ ûË¦ºøQå—;Ä¡P^±5ÏÆwÚ‰!Cx ÕÉË¤»wBZ"`ŞVªƒ…À‡?Ê	-Óëîà#ÑÈMO|¢&“"¦VnV×Ù)œ®…0²8ËÔú;Š»ÈÕğ“~¦‹Ë¯óêòÁîÆÎlî^Ù9û“°\‚¬M:ÉÈ±
RR*<%A>%Ù<bÔ±SÃu ¤>y™—…IÍAp¥«åÌ~
½¿±Ar3Æ¬è³}x€„™6ÂdKKCÌŞ.A¤ÏçyšfÊ³/eyjêÂ&\!¾tLÎIgU'¯)W—š<&fÈ;¤Ï™Ü-’d ;ÃBr?c©p2}ùbth´“*†ƒï“›¨Höç¦íî²R²íñõÛ%ãFxÕW¤Y€¨±U—» ıTåË²1~µ77‰`ÃÆèÈîC:€ş”OñYèø‹Fwí4bŞ‰ü U ûh>*23pÚb+5ÛŠ#Éu?vÛKE$İ3¼u¿
É¦µVXå6ri~>‘ ]fÊôE*Dq¹è±¬‚eQ†T¯7Xv”ÌŸu©+™’‰Üßïß¾±ó* ÿÉ~mA5dkØ÷w¢DPëÚ'•³.7=Æ„\n°İp‘JÇLù‹]xfñµ ÙRMm Féišk¨³|+I‘µŒ²Ú}_‡©îhkVíŸ'•;úeeI?»¸ëuOüÏ§"ÚİOÌQ6E” 5áRì™¦TR×) ÊƒW¾®É’^ßê'õÌ€4•0ìüªÁ(õÕu¢­XCb&{ŒÅƒö~Õ{ñfÿ¨š|˜¯I?şşJšâëş}§bK:(Ã™3§Ae©ßí› +ĞÄAÉâpÜF\u {dŞIr×ßó”ãc‡4hæKÃyÍÖI®{6Ûf³gì=¡½’¼®J%mêDşœph›¸Jet1¿vÀÃdº~4c¿x[$bİ zŞâöT¦s™Í¶Æ$ßÒqo,ÙhÁ¨º9`l!xh/,!¤7Á>×)‘ä¸ãàPè©„½ÆÃÙÒ˜AöŞíf§åm&()V¢ Š“‘¿RqıŸXqéÚE½—óùex¤/$ğ	¿ùÈ×{İ¶<ñĞe²‚–Î{»øˆÌ³'“Wà°ºïpÔù%$Gï­Ç¿(ù‹=6] 0´ ï?}ÑY!•)w¬ôÜ‘•5,.Ğ=Üõb,DÃu¶ 	Ä·”RBõ°S!r™YÓÒRÒºjÇS­lbbˆO]~(fb¢ğ±–©*…{2¹	ú¥ÑRd‹»dÿâW•úŠV,:s²zã†î÷5œ¶=B¾¾ò_}h^ÔØc?@ÿ=ù]7§§+"b5¡š',uµ¦ÏRvÙîü<1íBkõx2xH§–r§˜‚—Ø“:éJó^¿ÂÈ.\]]1áo¡xØs¨¶_Pø#
­·RZÛ}?¦Æ*£&Ò
À.ˆ &³´3“>àäs'*æ›‰yeÕÙQ]@,º}‡sÒ©¸µ,?ÙGè:Û*¢}bª÷&Œo ÉyrÓÁó«`ZâczxLÿ[¥Îè›ÿX›ZMİA›¡új„2“34ÿ—¥Ãæ³)R\ŠâºD­†Ë‹€H}F*ŠÌø¸±:•¿‡’fğXÇaë*ÊIŠ»¢¼/f¼©“Wı±H¯½öÕßÚ—êti¥V,¶rS¶à˜@#Ïdï1¹?v‰±íâ-9A«ÎåÑô¹ñ[;/)ÇdVê éaL‘ıcímhC2¡î´ü¨ÀÏ³¥Æ)ÓG‘É[wb‡1Œ«IÁâÑ’Ù¡ÔæH©máÿÒ¿D¨¡}®ÃŠíòã£\¦m;)ëÕUæ!°º¤p•~+£6éè|W
ˆıCÄx=M`¤Ê3oËvÂ?ÎóõGõ-ÜrU	eø$Éù{Ş:h½
¢—÷¹7'äò3^±Àµ­,5C0ˆcƒî=…€ßÿ+§a/ ØégÎĞ¿¨s?òc\}É­œrW³b6g™NÓµ—jğW“ïd€ ½
7-o6ZÙÍoH¹s¢¨·šp>İ­t­RˆW¯º<U0(ò7°v¯OĞÏÒPù?®J¡¯± Î<Tµ»/Ï˜½"­•0ˆÌÈ¾èZ	ŸZ¬ÍÕQ~×›Koà¸ƒò´ÊˆíìO¯ú½ğp| Æ¢ò P;æë í%šZ¥g9³—ã›ÈŸºA_ñˆh*c4®‚™¹Ş7I.ïXŒÏxŸ=âiQ¡cr™óx
;†F‚™´á]Ï9Óù{9mp€µ”ùÇÒ‘¸ƒ$bü.€W0@ì‚Hèq´o ·YĞîñ^{  	Å(“¶dĞé0÷Xe@Ú¾ÜÀW¶6¬"^è¤ç, tÓœşvîšTìèi@”Úíù0+4g!®¯:ÇİcbÖ­!ÅÎ+Ñ°3júxçz¼ú2ªŞ,;X®•§n4qâEäó	}ñ§"³Ä8^Üî—³opÑ“Z4ÿ ¸‹Š}z¬eËÈŸ—¾J’•²ğ-ÆfGÑ)ÍQE6Å0ŞĞD×ÚÁé§#üO“Ec¹Â/nÿİ(²íá3¥.]PµÓô2x%˜{¦ÂãÑsL²°Úv™şÚeù„ĞJW„äÙ¸?Ë‰MÓ-EÒÈT#ÌyTÿâ¦8Á2pdÈµŞ&Xs¬Òæ
z‘»ŞÌ-uÂóßDˆ0LP\‡¸óv—8í"Nzö×/ùœgO \ù‰V8j°n&@õ{1^,a‰t›LÕÇ"JeŠù÷^Ï8÷‡ÕßH?jæº1¸2èÀûct%ªx=@Cy8Ğ˜‚~RÕ¥°­íjò‘§§«Ùaï¿!^¦41"WjLïŠû¶9c!‰æÅ¦^qÅ >k¥a»;Ï´Ä~“Âí.-FèTµw4ªŠ]‰ê/³tt€3AoÑw‰f§©2Ã-œ›f¥Y"ş*Ÿƒ©Nù;5±_ı¼OĞ„ ~gÔa—vU3±èêù·”ì2ïÏéóŞ*°¥£›]z2HÑ²†ããì°d”œSZmrK\ldş¯+¼f¶å¼qRÅ<jé° `ë?í[ÅIãœ9ÚMÁvAÄ812¾­ÍËæååÈÂçÎ|uKH6ã­Êº™(±Ô[åën¬úâI™,Å³ß~uà%ò§¦ıµ»EıÜü^ËQ¬·.¿#º:ÄÂO¬§JïH-"éG¬jbQ7•Î1Ò7îÏ’„¯Èk-åĞÔ‡]İ>yè\Ö`»Ó›EäaÎa;x¬Ä}½õNÛ„‰²BJÛšÒŸÎ=Ö¦,†üF9 E÷ÜÉŠä¤îU¸üŸßWšÜGyµ¹U$zò2´2|ÜV®x¡è‹MÁQ…†¯YA!—¢y	ïDO¿ù]0VrVÌeÕÈ'ı¶	„ù®ÈÒåÒ‘âBD¼¾…†“ÿƒˆ1ôa÷À¨Ópk#K7ŠnNùŞw'ƒ%Ó\¬ò]ò€#§«jÕ`í0†ŠÛÄ†ÕË'ˆbcØ)àÈ(Z%ÒxÜŞy< ].b2Ó4À­ı„†j/£EÁÿKxè¢Ì)ä<=)Ş r ’J®Ô‹ÛT‚ô¦YZAw¼6S¼©ó—'âòşå(DQYˆù‡å¬™ÅŒ İiŸxZÒcß°lL5æñI@Ş!ÓQ|aÏ®×© eš¯ÆlµW”$büu¹ZĞ¢ŒÎfh`*è÷ñ8&:ÌL¨æåg_Ôh¹€”+ƒ9*»Äğ—aÕÀ\‹1VÔÊ[t,* ímihµB‚RV¥Ş!¥œ]¤ğ¹SùXf‹õ¼ØLâ·E¹Û2»;SıªÉxb¢ñ+M¼?uLé9
Óñ
r"±İTDüsœûPWîÁ‚§}â_ç`&©}‡
ã|>ñj¾%çlJÀd¨Xn:.ƒ¿œÿcÏ£ô9Dò3¸éD‹&,Jú/oÕcïú1xƒ™BâMy1Âğ‘¦ ¬æÍp7â\„s3fÖ”cS.ƒ:Fh%¡2³%Ó)+oñƒò´\¥åk†„;!)'Z¦sø•!rWŸ‡çÏ1°Íf…r‚IºåÓíæêFmÆÒVßqmğDşF›Ig·ÎTÇq[ê@?B	¯/·Á3ˆMùü°0á™à‘:”)š»„ö¯ÆŸM¥;+PºİÎ\Öõ½´ºş›æÒ—Ó‚úè1¾˜ŒÓ7j‰\‘$zò@>}·õĞºÊGŸ¿1Éók@¼Œ–¡ºä-M€Öè,nñWsWœ¼‚Èáuß¨+ é¹š^›¬gwf¢cñ{‰‰ÍõüÑkÜô˜ÌÛˆ\Õ ÷KoÃº†TRL!a^•åÈÉòÉ›¥·­¸§­àÑ}eE-c._qt«£µ­Ş7œ$Ş*
7óƒ”¯´Á.°Ù”¦kòÉ‘cUV×Ñê·iÄ9‘ßâÖFü9µDÑ ğØÆÿG_wz	Áêr|aM›H‘Â>ˆØ™IQ”È+J~ëâjêŸ4Î:&¯üó"˜å€R–=·QJq6ôetÛ»l×¾Ÿ€‹®u³²TøÆ€åñSê¿¹¬<ÂÔZÁ|æÖÎ`ãƒ‹ñ!¡®Õä	İ#•ißÊ®Ù¶2æÙ/7×ÔøÅ[¼°Ém¸ÀË-’Û=Ü{l´Éñ¿§RëD´ÌTv®€PMÚòı#·ÿ²Ğş)-½ø-òZIÍîòÛšÂ±1¿TAKw§õ[ã7I´÷=Ä#ß?&ÿ+Ô1Âg®4gôğÏÆt´kP®ÁµŒ+}â%;&æhÊ8Dğ9®ØŸ:£ŞØ‘\üqÂªˆxÃëâôJæÁ{#¿Ê–&
npBGÊBÒTÃÓÆJ	<«ø>ïPÛS#ŸàñûÜ;_4¨Q.³q.ğmu ®YÑ
³»ø?
+o¼ß2DùšJD±º„oc¯n¶-MUJj¤'¿ú="Hûİí¡ftU
7&1´­º0ö<öÛÔ&lF	"ËT™™¬s«¬iúÙë§ş[Ø×K/Ÿ‰éaŸöd÷?æCÜÎB”bË ¯ò;[tñ±ÚdvézMê‘ü¶-Û¦’EYÊˆØkúµÎ„4êP°5¶;Ñ®_oŠ!z€
:Ğ³ÂŒgM?>š…bMÖ%¦Ç2­j×}û½"è%ÒÍ3]•P¶ô¥./—·-•.¥Şbª«/˜Vÿ†„<qî\Éª:/”JYbû×Q-ü!ƒêiM¶îr?ÉiŸT_ZvW
?
;¯aYÀ²¥uƒîÕ+›²°kB¾”ÍÌ[ÑymÄ„õim.gm_J0Æº;˜Úè”ìá×/»)TŸìÕ_ºW|ïQ·TsúD×åEÃOË×t¸[éü+0€¾»à3bA“­å7»”Æ8s8@sËlÛæåıšN-r.şŠ Û
¦CĞJğy5³:ùàâF5¤¤Ø…Úâñ1gÕÅ‚#ÔvûQÅùNm¼–ŒûáqùyÍëŞn²ªµ´•‰uI!D<—8C(W ±aùd|G³¤È²—õ*1D‰u'´#¯š"Úy•O«
EÕ„S0T¤9² VV˜¸5ŸLwñÔpB´ ”‰ÇÚÕFø¸æ+&»’Ñ€„ü_®Ëûµ7Xu1gÁü=›½~7İAü±Üşß°AıôOSôe˜öºÎèMbçb ’ÎAøö<’ÂøPÖPîäiT‚Øà_w~b!QíÏpùT›^d Ä
1DgJ+@üå}]@¢’5Øá¢CŞy–]SâBlÙGÓgÿ§Ô ÎôÈÇülsÍŒíÿ)2»Ì£ÕÕQ\ë#”…¢ÄœÅ€uâ‚N7ÔAÄ’Ÿ£¹åˆ@G¸õß{¾Ò,„0‡mbZsV"éĞJqEóüîUğ¬6>í¾U3MÄãõÒ¶ÖŠ64Yb®978>ë¸d{w`A’Y‚u~M$ß¢èÀw'R¤ç$Óp¬ëQNV£ˆp[šø‹|Jxéït¢À!”û¬ñU1tòÈÆ4Û:‰’ÖøpdæG¡‰H9U£/«rÏ:¿Ç*~K‡×©S]¢‡/³¢A3ÈìâÈ8)Œ‘ë+âHˆ À{31åŒVÇ±ö¬VÚ¸_Ì_Mşî#¯ø¬À	Y£ÅƒyyS ¨tDƒ}Rj-sµ{qİ*ÛÓ›ä·´o‡#Ÿ¨òüWO$Âğ[A…+ùåe)ŠT UÃìƒøéJâ|érı'‘€öğdgÜ¾½Ÿóes½ºV«FF[îS1XQ\Õ{àxÄı±é‚±ç¾ß›¼XÀUÜ°!v,¦>FåÉZx­=Ä’XÜaVÓ (Ñt6ËêüÅ†eJ+á[19È…ÉŸ—ğa…ôeOLİ5±À¯ø}.È’";NÙê)é.]X¯g/9øÇë ãgıOÊB‹‡É]œ(Éf^!Á×E¬+3÷Ù¬­šŸëée-dP¤q8Üâ ªYçá2%äÃŸÊŞË›$ÌLØ–çŞš)Y3¶ÙoûKqvÑÊbì"¦ÛŒäa²RbeßÈ±*÷!3e°#&ÃµÇéÂ[áÒÊb¾–?6R}Bé¿«‰.§@ôÓ€Ñ´t²_‚—6„á?¤À9Ø$Ç˜2¹’Õ{Œ¬büNìXÎŠR¯q#7×Wh XgA˜¯e"Òšÿm™V´>C¹²şû¹[ßèËÄ†rF­“!Mó	ø…ğs3¥—ØøJ´Û[i˜²’˜K¶é8`õ€U‹ÂÂw÷Q#ÀG¸;-JDèÅ,6Zi?2mãtÂ”SP¾™_ã¹ºB†İ×("ÅàÄ˜ycÂıùîˆê"yØ¿Ÿ+aÒèvü£ßß†:û;ë§Åûşy—Ùq|/¼äF“ã‰ñ4ËDıNd•;
U…SNÿiÊsG®Ò	;´¯¨Óã‡[ØñÅVø][›Ğz#DH)óÆ&îãÅ—ó2ÙEÌÄ>¹m4¬Ò|V´=,ÔÔëRåfã2ql‰Å:cËÓĞ¨ÙE®‚•Æ{µş9f`×—Z9Fóô8g€"Æ5dE®]}¾Œ!y"{–€Œğ¢Ÿ	L0Îa¾Ñı¤¿È_ÊÖJÀûÇ¬¹AÛ‚7¿\;I°†¤DÙ)ßÃmù,6v¹e…æ2F£››è[9uX%7'?QtÎnyîÖº»ìåó4.×Âİ6I¶NSˆq¼¹~-ã}Lå	òô‰ıÃM6«0~,q8²Srm—eå•‚Ğ,®„Ik/´„pOózÊ‰"í†5‘Æ'†:Í++n£òš"´GÂÚ2Rhh?ŸŠ<µ¦óå‡´VŠú$bS¡:.îßŞÜ|MÅ§ËÑñ¸ÑCØr”w—-˜óêHâÇHE–¾;h¬ƒ‡ •Öùì§•²Á1[ÈÖı±æ´)…½&–çÑ
ÙÚê=†R»Ã*	(’ë‡RBûÂêñşVîRë¯;Ş¢×Å&\œG ³03ÎŞ¨TÅ{ä*Ü\pı yE
:Ó[¹à`ãPï¡kw–ÏñîëvÅ•›¸eß»¦ZH7óî‡Â]J¹Œ]FÅÅÃ¾uº4($«Ğ¿-ƒÓb—İ&	­}u'¶«†”šÙÒfc'À™à8c„ã_Êİõ[
X³ÊŸ[@å2P	¨vhüé&Éòö@\¨øó{t·WnJsá$|8Â£á;pÏw°ÏÂÔğ ?şB¬Ë*; ¼VgWGÑÕnÔ¢l—KV#Ì/æõ…U‡É\1X±Áºy|+¢öD¾ OÃcf¿ËıØò1)íÔ‚S´8opOu>
6ói]cüW/f2zÑ.šµç˜  ¨8Io¹’²¤À„kab¨4†8@Ÿ‡"¨ƒ™ms\ÕÙHúàÃÚ2nñÓ‹¬\=¾…ü5FàCáb#.¸İ×ğZô–ŞàÁ´d/+R¼ß’å?K^Û¾±¥Ét” •B–wvKˆ#rcK†¢ú«Ğóºş˜}Ì5ó‹U4D£sÖ‡6Šü%…£1ĞÑ#0Ñ›,8‹„³Ô½¾'Ásq\§â·6‡j‰$„âúWÊÆfd«×ÿV G¾İˆ*+ ×üØµÎÙ>*„™¯ÿÖñ‚Œ³/gÆOÀlš…hU(yñòŸÀ>½´II,Ù}§ïclÄ¨19'ıÇº;ı±ÅŸP8ÃMı	ÔÜz8÷¡ßõ,›ØA†ãõÃn®İ&À©£Şƒ1œí'9F÷PŸÈÓà0iéùÕËÓ¾‘Æ¾A.M›ì¿"®8ô®”˜-L„¬´ÓM¸ö½3"ÙëN6i÷ñ!én_êœMö‘:-Ãö¥üÂc>Í›‰§-.Ô›'‰F¯ó-õ~­ ¿– Ö“OPŠ­ãÆ®æşº’çM×i†û0ÒÖ5‘6õ9¸ŠõIĞHûHh£S+² o	”¸g<w8ii«JçjSU‰İß®Xš…­±ËJûı,cê còà·í*‹ÔprÖ1t´‹>Tq~àë:PaçÃn`V˜ˆÇ
³÷x¾›¼…»P0Ï=.èüšxyùy«>Œ®¢j'Ü‰$ìùe£LP/-s_ÆÍå²òÂÑ÷?$sQ’¶:Ô0º©işVÔS‡„0íÛ¸Î³¯zØ²€Ù<jåÉ²†$	¨OâÉÎn[£äÉü36½Dßq’7d¤–u?ò«ˆõÙ(—%<Tc;=¢Õ° Ú§ğ-•öj„É±ÑQÉ³ÒÔnĞ¯Ygü]ByìYS]tIq¨ğÆsğş(ƒŸAÁ«ùß½£HyK'kİÀ‹¤¤AÎEˆß¢>¦ÂİI£¿dA¦UärX lö˜ä¡4¤‡è„BE)Òu£“ü#[‹lÁg4BCóùÂ˜8·Ş¸µ<ó~»{	nÀ¥}7d”˜u+£´VV¢C2»3—¾ 8ˆºğ3O³¨¤Í:Àçìtâ6ÒGİ?Ë'òSv#Å<8(%ÒÃ=ßâ3rú<¨j·40:ªØ”GĞQ5ÿh‡$œçĞ*´
\qõ¯7İPNÑ>ÂîÂ ÛÊLBâE:8ÿ=µxvˆn.†¶¶,:¼ÇgO³«V© <÷¸k]üÛ®oæe”³YóÉ¼t4äùˆC-Ã9s„Öd.ÖSNÀ²İ	RSåC‹Ü
üGàcÎçyOÔ“¸½~)ãJ1‰"ş¼„)øëtv¸Vë'<P‡îEüá‘ê Š¼+I{¶lëAÌP –¥œ¸LHÅ?Hàr °Äò©_{ŠÖs´ø.Ç`	g$à&ôŠBuúŞâ J EèÀs[­¹jÄÆÓ#Õ&OKÎäÿ¸¬ ¶öN)ûRšëñë‰¹OgVmÈef¾vİdõÖjª*#ík=+•üÒµ’¤JÂ9ë«—òİáûås”áİÕÇ»è¢Aäƒ«Œ^ÔûÅ]h¸¦¶¦,•^Â,Œ)Èÿ•1q¦
½Êj.g1öxåQUH:}ç-°ónüÚ³±ëa©\+ôdL;Í(k`<>ÑÁÏmöV¡í\¤äğÏX§!dÿ^rv€µ.É…”·ê:”ãóh~-_Ó‰ìùSX>[]Àá¨#Ç[S)[wÅ/vCªáY¡}ŒLq Y
Ùjwq½òMÚdµLt•†åš
o¡¢]·7© J‹?ÃÈL:êåögØƒñù‘åmáúP¡]égˆ§Ş½—ôàùã+C‹¹Qy",š#&´ÎÃRZÆí.8A-³bCy²ËQ…ô.Z—‚[ÅnG¬Ù­?6/—×bØÒQ&¯PnâŞjcğÌéø>bC´ŠlzÑ“-6*ÂnøéëäZ/4‹ÏÊr‚yêÜZĞr¯½5„çæ*Yà‡8 % J3!y”ÓùõË°ÏZ~úWM¾§p~»…a@’5º­é¨öÖF§÷±ÚÍ.•iô°y¸ÿ/Mù8z`©óŒHÈ@J¶ØwÊ€QôôYG×*'ö7¯	E¯©mVš.ÃGcŞŠCM‘İ©fWdÇWÃv#Ÿ×ğ‹-ÊqØd1¸w«£¥»¦¸üV3ˆÉ[@Jì$Ÿ0ÿ–[É±"$¼ºYfÆ‘YhL*ÅÇ~^Y?ü¶S{®ıæå²Ä¯…İWÿnÎ¹†øïc’˜ËYI£l$ïƒÅ€ï md{sŠÂV¸ZªX!øz0İ°šˆ~`%z–ÁÇ´MÑcİl´—[˜ÚC'ÆºÀªmí«ùìÃùnÃ] ÌÙ×	ÚR|gRgõ©^J½Ü1ÉÜ»/N¢úzêGõz—>%J™¨—÷Ú×’Ì¢8Ò,D¿È.(+":_à  ™ƒ‹4‰{§Øü‘Y^¯JkÏ™Jöš%…ñ¤7~¡ûk9 ø¡&ı'˜9¦fü‚v!k²™¢²yó<5i×hr’mdª%¤´¾<µşbOEç•Ğ¹ã’î2p}4Ñ|£XhøÌ
«I»…Ûœ¨ –3¹Ò""*!bia
İz¹ïyßõ˜ÃÁ®êZüØ6Xw~Äî¹‘ÁÇd:6‘LZqçê)mÎ©š4M÷ÁÀ¢éçPÑ£²CÛ³5Lê×x¶g¢”wš÷º{Élòc÷qT6áµ|±ßÄ¬L¿²W‡•Î?¥Ûã¨ …Èóêñ,¹Ù+‹yø VÙ•Lôè‹0h6Ê¯x¸lMzŒ&­O‡Ùß­^¤9•iÚ}Ç~¥<üa¬hX]â¶4O?>D~a•);œ¡!·ïÒ¡Y2¦¹•ˆ-Ë¾y›6ƒì…£A•İ®'ó	ß³ÍÏ»WòX¾_ÉÑ­ÑÒÙÂ©ˆÅ×Í:€	ÔÅRà->@à.5:ûêš2Tì´ó7*­h‘ïÇÁÙÃVMÉ‰ÿçkóÕ”Iàp¼á3fÊ\â]'+ÅéâA+§şÙÍ°6=/Ÿ·Înu’ ­oÿıg–Jjá•çÄÔ^ß,é@vÂ\Ú~<¼¾¬ºMıëù-\x
œQñyÇîÛX©†ÃÆcı4(Õ5Ê¥õRìt”=‹¦ƒWıŞ”z.Tò”¯Û'à£ó=-6ÃÍÄ <6ÿ‡yS:õÔ}Y­oq/"§mÉzœl7s­M§T×¦ğ1Ã ¤ïmß“ãØz‰è1HÂ	ö ú†/?Å&¨·š{=øÌá:À÷»g¸ŒZÙÖx ¡i¬l”bÓéşî ¹)Ñüe#dË=xÄT Y+Û¹ˆhS¦‰Û™ à½¸šˆ"¦…@7g/|=±¬x‰°·	k…ùø|6#$ˆ?Åéüà³m·Iu¤€Ö¾RP\¸ëæıD— ³äYåû½{)c»è~ÑÉaùîq™·&·+qœÄ°®Oå ÈXìBir‹ØDåÜ©Õ®ƒ
¡ ¹m ˆ…oZ)>ÈñÍ\¢ÚğR‹@È	;(š1­ŠI-ô‘>‘¹ÆÿÆ˜6£orÍ&U*¤³x.İÅUGÖoZGõY[K`ğğê]İŠÏn}O÷i;ó^> >$¾ÌË>û-ó_ékû´j»¸´‹xHˆ\H	­qÛ(qkA¿œ_­ï£Í9k–9çlZëÇBfyMˆ©;AjÈÄIJØ-G6Õs,ÌáB¦4ÀtoWÆóŞ'6àË)§¬æI>áË4i "#L)šIØÑi·Œf—n*´mï+Íí†8âô$ıÀà'mµ&ïæróãò`ãt.‰4Üç“pü‚Œ‚ÃZòT? ˜È[°`ÓßtSñ;ıª=~'b€H¾,öiÙÆµjCSõ¢´X¹Õdú{âZj|e” IúÅÃÑØwû#@©~&8Ÿö›ŸÊÎ`ª¿'~å-ùŸ.²š^2»l¥c°y(„
rÔn¤ålì-µŒ–ï§­Mç¼dÉ¥³L±aäˆ…<Á.24êäE;6Ğ/&@¨¿—¡¢*7=œÑ`U/±5½yôaRáÔP×±õÕÓ¥ë®¯W)—n‚™TâŒ„° 5§¾·Æ¨)û`DY•2Fâ¾¿šl$Ut2×„[§øBxGÑµb£º#õ,ã8µÉÍ´ûÈß äU™Šc®cÇ"äßÚ/ÜrF±VÒß	Ä)x""÷ã+×H¿E¥"‚FZåy'¼loşL©RèM<hõ©¿´5†˜…(Œ¬
>¦­™.ó?ÓIBTt†ê7 †Ÿq¸Ê£ÚÙT€Ìî‚2‘³Ü_vĞ‚ª¯Õ‡¶ì8œ}îµ¼??˜ùnÕÛ¢¢<çeA®ó
-2…Õ<[HŸ‰½÷ÂÑH¡ş¯ùºâ×L'G“%æÈEù%;í?=ÎSÿ6Ûs7—¸ÏP”¬¤=9ø xŸ¥QÀáèŠİŞé»ÿdÛ
:˜ ’ä )?øõz  Ş„g”puû\’¢-«Çzô_!6#‘"SõEa#ˆšvØ>Gßä¿¾B63'ş¹Tté®A_%á²ø²´FA@³£ùU„Ï£}Æ‰Sy÷l(.îA‹›o°ÄPMÇ-©á÷_yg	|Äß3ºV$_á[¯‚Úg´†´Mù¿Ùå¡LùÔYs–÷Z®ùOy¤D'\¬á;!Ñ!ëÚ 9…ÃòÌÎ¥+çŞíµûg	º)>Ô¤ĞĞ¨[ÓMJ5şË¡`N$6ğDÙ2FÑxÉ¦9‚S)vûZàTC3a’ù»x•ÿ5K:ÆÉQ¤P—€dâ¹7®,”2"Õ¼J¸iåTèjM$k&ïMM_õZÖX#Ø~“.Û:=‰#)ßÀ`šÛÊô¦º€c¢œ
ïÜ¢ ×àn]†•[ï£>DìüaíOpºe«=êØ}zŒ7Œ¦ğb}ù:¯D"ùê¶‚ĞşÔ5oàè¬æI É±ğK¼qèö`epÓj1¥n°Dè¿L#>5FH|CrJe9å![±ÍE·ó§›û*±%|l\F¾/ ı,¯'T‡9oş­‡ÂmËÓkT¹3·Yo(”øÛª$¬ÚÃ&5æí’´_IßØ³a#gÊ[©Xumò»ùYIs‡P·vÄl22„j?ãvEM"xÈÕ™®¢eP¾G¶iÇ<mä®˜ìãT|\1WÃ~­­ ®Æòë
	húÆı"L|¬_°u–î‘½SÄîrNØéH­âÚèôíV'/|ˆ+a5ı´şü{ÛªYGñœÑ-Y¥*˜ÑËëeëˆ± %ÿªÃ=* $¢(›VèKÿ"-€€ ŞäÔÕ1C˜‰êY;Å¤š±1MÚŠü'ˆ¿³*%ãŸ˜$ÖFºtU¦0qMß9p¿5“ÌS½ò¼~Ş±¨²‘D´¡_ál¼‰{/'¬ì¨§ıV+‰'´ûMÖ[’$ƒ½wwüM4¸1“û¾¾Âil&Àú;B|VLp	ô» µÿ=I™öi/`gîã…×…!pö"X=‘†m¾%àòxûØÂ`~N›ÎX´5ü‹F äÛ>9 Eä.#á5áª¬W_¢SÚjd–I¦ÕÁ5~^ ãKšhL¬¿ò9?cx®w”DŞ.ø««Ûì¬„ns'OlÃi	”œRìÇşÅnúÚ¹‡7S:c?¡¦i2Â‚Oğ ÃáªÛôpİ1ÀÑÊ6›¬Ôd5î„îÛşñ‹¾Èîå‘²WûrigHëÙ;uäbög4ñ¯~¿ªê‡¨}Vòº{¢·®_ÈıV\'eÔÕg’•R\¨ÔnÑ¤°Eİ1%äÈâNyØ,&!scÓOÕ,ßO£6(~U¢”¡$Æ+½(Euµ´BªØşd»Ñ†„q`vL›!CU£ŞÊP¶ºûµ1”ƒŸÇ²(,*lÃ™&y.ìVã`»”^î²ÜI™Gk"z¬2 €„ÓJ‹DJìeß›5(ód*Û’Ï$ÁŠÎ6p	oÎğ+`¹¿h;É‡÷œ¯£İHêŠ€ormug$¿÷=ùBõdø·Fn9ÇšûÿÌlp/p½Ù½JRº£d‚’8°FÏB¸ Á Ÿ÷EĞ2×AŞäÁkÙ;ôàMÇf××zgY³¢´ïæ¡İê›ìª­æ¼|av 7§„Ë×±áWƒõ@‚‹ÿ$Ùö#ü¡×egI™ä[¨\¡G5ä	k°~K^· cB"^×Æ‹~lØœŠàÔkÇñÌ’'BXj“ÌªGW~Bö^S«È”HË9ÂãÀ£¶i²U”¼jâwl–h–^¤ÌÚóÊÕl -ãa£"ù`!‘¿ŒZ*t’Ó0ŸÈ Ö]ÑL¹tû ”Xms•uq­œ>,Æ(õíö@$EyÜÊHdÛ3d’ïCu$=‘¬Ÿ•ÙÿíPº<Iá|¥ÅÌÑía³±õ˜7³õo8; Ì¬ÖÛ‚æpY·ÏùÀéM:£1/éÁÛÃ¿}Öì7Ò¾W¦9ĞBK2‰gZN‡RÑ<«A¾lè PEr"¡ç&¯g±™öíä-)ÉÌû%½Spd!f·Êî¥D…gi?ì!Aü¾zù³.ò+áÙ42ÂpB¸¯¥–Æåá\g¦£I«SW1fâÍgAP”îŒå›Âmş£h‚ùfBiìõ›²K­ççWŞ»Í,‰Áé¿P<œ>GDIE§º»lº£;Šº2h>‹#ß<ÁÆÚÑ9gÍçÔO‹`˜Bz'/„°â N7î…™Ü®® 4bUÅ–Ë´¢T¨ ¦å†,+>š³[àvW>JØôPO´°Á—IˆyoRæ¸Ì„Bƒ
Í Á`ÚU}?ÏH<	¾oï›§›åréíBL˜UOæ„E÷ûP•ı›œ6sXÔÈ”,æ°Ië8şëXÁIGz¶ä„uÍ>ÀQ¨ëJü¹LÊ¹¾S¯hø²=YğyàáwZÒÌÊÒ'Ğy‹f_ó‘¶÷d³à¾„•™ŞˆÊhÎõéÇ„Æ¡æ3f,MòqÓ@5áõ‹[Mì2ƒt ]ûiì½î	
¬ŞNÜÁÂ;PóãÅà*`ıLàî}n^F×è@¢ÿEôup‹ıv±¼®N‡DGA(M$÷U o¬õP+Öß·±Éê\õÚ A#àŸAP[ëS¥
L¾Fgc§[vmñĞ×½
},O‚Ö~»qbÊaG]‰¢nÕ†¾ÓŠÆŞÉAìğã#Œ²l«>I€òU¾][Á‹Ş¦»—["°€
uoİ×T„dM>Õ²ğä5]¸u‘­˜hæÿü‚NUØĞÖ”ƒÉŠP[Ê²pÆ­‰qüXIïÂXb'½vvÈÜ$aóËíJİ ©®ÕÛ#/éˆL™1¸™”¬QhêñÑQ~`]€5x¤úIĞƒUÛö‹F@ÜtÔûúW5ÂbÖFªr¹Õ£g||¥´œÅæ¹áôGW~%Ñ”2¸~sf­ÔÒjwµƒíúvÈ0mÿ1Sª¡J¤à`šğ~€ß'
5G«òhˆÑ fU:N¡áß‘ « %^Ò­]ÒÄ!˜ÖÇ4Dº¸#˜Ô·­QUbLiÇ¸&.aæª5ûzè´™qüŒ üs).ÁÁI(ÂCŞ]™lµ½aˆı®WÕ(†ƒÄ¾
â”z¨zá·Ãc·Øq¬Ş½‘u_&Ä×Ú‡*V1¾c+™|¤÷ÌœBN‚¨Ö¤â›`ë¸¬€dëWĞ„×`2P÷è¨UŒUô+îC²|ó@îc d[kè…5iÂYn(
ïµZ6ì%u>o×SºÔt¸ÙFËkR’½}¯j/‘Qõ<ä-â˜Û|¢fBG)ÿc$£+Œ’ØÔƒsy‚'gY«—Ã.Mî»¹+Ï¸‰9´½àa _ô@$Õ¼ê64€¨éeRÆO`gÙ[ˆîíI‡ôísD&âÎ•½>d*¦±2pÖYh>‘"×ú¤~ôCéç½·R¬ÉëúšK˜g]±~#àòb
Ç¼êğÈù¹ñÙ(âñ¾ö¢ı´MËGÏa|µ–ÿß¿J°
Û¶ ´±¾FnÈ3=P±“cùaÈBm„%Ã0d4XePİüwûi)wÛë´ÒöbQµŸ·ÑC’ŞÚPÄ7T:€°<¾Ê,€şÄì'ïëÆ	ßqİÄJ÷Ù'>C!±Jz*‚<ïúP–ì¤üIiõ…’ÅÿOJà¯cÈ-‰iŸSjpı§€/gI½yĞ;KfeÍÿ
hSòÓ•÷¾~vDc0s=hqÿŸ çf,ûÿdB/ kú	 eghËîx/`Z“å÷–‚1‰Osı!8GîÙo_bƒ®ç¹—$g‡`°XDßk¨Îƒì5ú[ŒoØqL39§¹kXLë£]ByÙDÀ1/$ÙKğœÊ–D²“ı„µÕu³Ü!™°UEš_½ŞVŒ+gæê/0Î«C€’æ{àåañ–O+cª•ëÀ Ü'ûü ßBh™?,³ÃgûZu Êô¦°\}íšuÿ|¬ß;EnTºµFE—¨4;™?Ô|ÒÉ÷CH è¬Ü0 R N¢‘á½OüRSuZääk5~ÓÖı+ƒ9—=„ßx¸V[BnÌùvZQ•şÎVK[.cË {TìJ_††•øvç¶@»Q bRŸø:¶ó¬–®»œÊ‘õÂ/Á|ö9Œ^Ñ×å„puÜ}B”a¶äôVºĞ@ˆbâ†¡ÖúÔ‹Å›Fò¹f„§kE¤ñêã¨Ç˜P¶0"»oTûì3
»ÛA÷oZï—›z}†")óŒ¯Y3ƒ?¡K³RrI?¼“FFşê!äqË îeR ±º™¦€)zTà³Z¨O‘_zs?Ö”¼©u¼ÆŠyÓşg`§EzGb•ÌÎŞBFQûK…¾ŞßéĞu¿"pÓà¶R†}Ÿ–'ûY¢g—º–8‚q¸ó÷Ï;µñ—ÕRó&š¾{BĞ„§FÓ$×¢ÖOqÕP×À­—Ë¼[Ú	ak€-øMÁY›ÌoºEr¶bétÂ¤% 9ml|Tãıù»±Ä(Z$íÑøüºQu ­4kÄ¾wÕn˜ …>mİÃäGdlE»;d 	×9‹c‚ ®ÉÀ·úÚ²@ÅC ŸNá
„1ÛTpXsÖ„šĞƒàa¬Â‚œ)òS“ı¾	}Éj:p ËSLm‹şÛıëz§ˆ•8;©ŸØ»ÉÉC£İjü4²Mæ²êÂš¸şe”ßº#´~"›Ô.LD•ö·"»Û¥ÂQ8aÅ”ú—cvû#ÇZ,tWègP| àìÕñ¥lscvA
Î§€í(Àl2å7‘,+î\ú*­1IZá5ö´à–ç‹†kbQ9Ë´ntñòÚÆHP25Ëh¿`A…ÿÑ,Õ0Ÿ½o¥ëz·rèìÅÍ@|ˆwh›ğL>µ!à¾›ÇcpÊ>mhÃ ?,ZĞÏ\ÄP¬”›êİ#­¤Ààƒ=ŸRJ5¶†¨L/ãj%A)—ÇEÙô¨`éJñ¯³M±œß6Käš5/È‘Jæş×…I…/ƒËu&œ` ˜¯×à²*„•lZ™¥¾v<yœ—-µój¸ºÓíUƒ_¹Ô“Èõ.²¬8øjnTÓİ|
Ó"¹ä¼d£}‚;,Å”çuĞŠA3Oôì¡[t‚„d¢Ã0PšØ¨c`æÜˆyx–`.FEM$ñ,!½à[îûÃö|c7xáè™†2NZ÷û,Çh†A‚¶P<nÿâÉ_åyìA¦Y3cF*&å!N:l`ûŒi#.ò27
ŒPÌ¾*€'w’ú|¬V×±E(¡Î£ë’y Q"ÕWGƒ7:WCrJÂÁ]Éívò’±3YQP% ÿ²!Õş2"u)jÂ5İHOÀ€ÌâÙ­İ#2ûääVÍ€cü7ÍöfhÁ ÊzÆ³LÍ®!F=Ó…à(€’ÆåÉX$±ñïpîÓÓ³*ä™íÆo~WşF`â|~8Ÿ;‰¥5teïíƒ÷5«L+ÍÖ \v3/Ó[kqª¼¡v±lÖæG÷OâÌ0‹	îœô~çÙBÌ5±°[HËÔ™3H“)Sğ<Ğ1}¶Z¬mH° É¼‘€ôÁÆ£×Ÿüm®¾gZ!P‘~d<sg«B„@¶™~ëÂåŠrÔèßÔggóê ı¡".è/{Q>v(yúŸÂoª²ùjéfiˆ"WçÚ=§[Èx¼è¸Tz6¼HİH> ãgb’ÌE¤Iö‹@àM¯µZòÂ×Â/îÏ®GÓbv†8lJœ±g¬h*¤*ÃVWŠ=úõpt©š…¨ÑZù»áQäPI„pzS [è‘ƒÁ˜¾ñä–¬ÏwDkæ¨`İñR
pqI#NAî¢é@\EÅÓ¹»X¸&¤Æû–f/Dœ« ı-	ÍÄ;²fE&)†F‰ê y€Ib|ÂÈ?öÔµ÷ÎŠJÅo—¨³|: :=±¿é5èÖ™Üpºó>Pñs‡M‘ì+çõÊ@şwû`Y¶Y$¦à«`ãjfŸñ‰Æ¹Ö¼&ä
î¤×LëÎ—{R$ñ6±AÂU	´¼¸u`W‡&¤UXµ ;·A
.€èã,ÚXš5¢(½"LsS¹Ô¢¹9"`¦ÜS)ÿ’lî¡QF{ò§4¢k%¾ÓÓh
·Av#|Ù6<ùdÕÈ»Ÿw¶u•†OŸ…ŞŠ›üPjAx7©|­!Ùì0ÉÚæ(Sğ—·¹]Æ„àPSæ›)¤òä`ùî×J³»m\È§İ+šœôëÿH¼”â¿—DØúÜw×¤Õj{õu¬SÛ§‚|‹mUø`=«®£*ÁÃ—MÌ>) 7Ø7ü×GÌàŸq(h:,aĞñ/aÚ%½nyÚş`*JíÁJbåd!L«@åB5†sA‚Õ1û K;/»ÿ™)0Æ©ş3\4…8P›“Ê°˜ß±“‰•D8cgStA³G²cZ–ÅË~ÀøÉJ1ƒ¦œì•b*}—“»Sı±ş(´|‰0w`kONL&2o¬½†¯.SZ2‚ÉÆ?ÙW…ìOv²òS^RKE¤e/Î­w“šVS¯ }Ôµ˜ş¯õş©R{sŠÃ—ÌÃ±§j˜ÒJ"‰C§¾tHæäl‹´{Áõ9Ï“Õ«´µ-˜â¨µ«C~7M®ºN˜Wå”Şåµ1›¤›¥E„%AmËCÇ›c/úd3B¤ËÓkæDÕã‚ şµĞÕŸUA=“}Ò6ˆâ¿|*çOâjÑ¨¶ÒM™>g¿Æ3Ô¡‹¿‰©e–ŸC«N]‰$ÑªìYÁ\„}í(ZyŒ³Öì"ªé\u¡ªÌHzF!ê½w/Dài#ù?A3(}APQ:³gáé`1¾Ü@Çr-0e­¥ŠõñLöÚŸÈ™ã„(2x€m	á g)~C2a¥)˜h¶ÇD p$w¾[õ#³yg{>†‹ol§ìfê¤‹Wæ°¦¥bÎ`nõUeùşÊE†mc0û¼én¨ŒoÍh«ÌrWÛ–VÑ´\·ÛñõÌÜ=Û äØÑŠŠröV²ì/kŞSI|Îî@~ßÒÅıK&úÈ·6‘rSVø¡¡ŠJ2
±¢)èÈÚçGOÆÏñˆu¦€:·Aˆµ\!6/Â÷GµvP†ã
¶
;­ø§E"’ŠJ²'ä…å
Š
“W'ÏíîÆªTşœ‰§6*RPÂ.¸q»b(…2s§Ÿ*1|ĞR€Úy"á¿ wU¼s®f:Å	+z‡ëbSÓĞ>¶×aÙİQ]t0-AjFó°fĞ,÷vns{Û¦Qaå£V|Ÿ1ªsúIU,uôxª¿7>nNõ{*d… ¶_w7ıxˆß3=zåSycbHñ@ÖI“iPe‘¦ˆóíèŒÑE¿ÖõÎÁ5ËİC¶	–]"“˜MĞp¡õú»¬y¥¤¨ë(=Ây¨ß_4W¸ã‡Öâ^1{„ÿĞ)ñ'QûãÆW×½2"8Ö3†ı8#· ÇÏÛŸGÂMØOH<¢Æ£*èé„ƒÁ•C¡?§A'e(J4 Ã&~‹v)È¦††"Å‚ÙJ²Ä¸šmp‰–qß q„è;N”mÛì"A—G¼ó#Â‘#DPtÙÓt ˆÄÕ‘¦£-½é¦OG^Ö,í¥Î†/­ª‰ˆ¸ÉÅ†î5QN6Ö·Û)W½á‡3•}ßj2S®ã©kä`ğ;¶Øœ‚ëÔ*Óû€áhôığ2‹üMK÷Ó@´©Aaß“F¼ä5ÃLø^iş[wÎ–B &àbÉü€cäÌM}ÙO¤^ÌÁ|D3v²ÿæŠü¿XÎg =çèA½mVqÔ÷¡‰Z"4áàÛç„”|%{›jÙè'äŸ{w—85æØ/t¬hìáÜ¨ı! /b’‹Ã,§®'ı5›õı…‹¼>0¹í§é×âYQ4®Ç9´2£Sfütå?à—7 ÁZáÄAf$îÖ·ıˆÖ»Nı{r]›,' 3f0§:¡öágËã~îÏ¹´¦ÙHlğşâQ†(ä C•âñ«Á‘>¡ˆ¥‡¦yºòŞf‚Ç‡ÄÆt€64ŸY(éX.9–½cNé9«~P_·èÊ¥Ñ@jpïÚ»½˜e sàr‚ @\ïëŞ{˜#Ã×4³´Î×K‡3ûÙø^T†z+mÑ&SèÓ[Ø¯¨K,5x{¬à­Üæ·ùx¯Ú¼B_»Â^t¦¬#¶äÁ“%Û¿zî}¦]çÜPCÙÄKz¸#µò?Ü{%S1‘=cã½tsQƒ×OvFcá×n~ü^o$K™J’ÖÅİ{N.Zf¯ÖãÑïïWP°ÊÒğ¯˜=ş]T#OôJˆ¹È’óúxuHOÉ(&=ÀîÎ\†À
×’~è~ùs¯ğõBµ¾õBµëTª3f—4“ò€>iĞc)›À`ÒbS¯–¡£aà0$“íxƒâª>š˜\sŒ6Yó±e¢a†Í(DÔ­Çë¡2¯f—`K‹Vµ7â§½°æ 9£Ñ<Ş™„¾æR1õpæV°ï—Rà³ORKÆÇH“ŸZ8ıa{G)ÑÃ1×Û²iµşË_]¬ıˆ÷?DÀ‰°ï.î°bafbÁén·–˜‰4yòl%â´¤2èäí‰çpÃ–W’{›Qa`6Ì.Ø>ö-Ç—GwM‰b3~÷œË2U1cGWÍ/`Û²¹e@µıîCÉ³†‚?&C	oÈÎù#·­¿¨«\cªïÒG÷JmwìÂ?{ˆêiä~82¾²fOy !øÀ¥w^—¸;»ŞbÅ²ªı…œ@İ€ÛŞ@ıë5?â…`9le÷õ™ó*Õë²’®åÑ‘¿cz¸°ı¬‹ÛÎı£&²ÑKß}mÊûÛÍVµŠÚ:N=z„U13±i/r<âšÁ¬À›3DzXv…bË×Ëá×s²òA”Uû·+’{’ıH×«hH*—Á¹ÕÅ7htÿ“Ts&Ì`‡ğÏÁq•óKK"É°O¯îUªÒ:§íu9 89jìÃeBÒø×£şşÉ+¬.Újë½&lÉĞIô­O3ŒˆI'º$ıBb1Néğñng%fÂ¦qVr˜Œ¡(Åœ™÷ú_b€¥9^"¾ë-gÑ¼Z@VTF¯L´S½¡r“d¶è#mÕ$şüÀGS*wÙè‹h4e¿}¹ÙĞe´ú·hJlù~¹ÁÓ¦Fïr¥6èü\>şm Áé¸Ö³:Q€m²‚ÃRymna/hãHz
*ûx·äÌe}ËrM‚¹äZÁ>Ø›¡|<dC2G†u\Ó½v¿36>-‰…K¢WH²71ÓŠœøLk÷œX
rKq^fsmâ5#¢zJŸUÈ3ºm—å£À[+òË€oÓTcŞbTIFÏ^
/“iİÏàf¨,CñEÿÍ³ZEİqDË”R…!yK8X\IÿÖÃöÂ30f‹¬´Éê¹>§4®KU¾HH×Âvä,»ƒ)‹|Ø¯ÛÄèßö·naH6Áæ²ÀíóÀ4.ÃÜ‹ähv6”Šp½4ñ]DüÇaå.c¢×OS@ùtúnÚvÜĞÈ
>ªYÍƒrÈÖØAá¢ÔÖkÃš»LT· ıTôYıÿ¦Eg»ìfVw}ö~ë×ì/¶‡¶àÜ`<qc$e‰xÉ_;fç·ã?x‡%=äœê¦ı÷LÓ8
æZWõR¦ßÁ76ÄQ¹d{İ—ê8½ag@í1°J Ïgb6«'¨¥Qp     j¼NÜÃ!¨ õº€ÀÊrjĞ±Ägû    YZ