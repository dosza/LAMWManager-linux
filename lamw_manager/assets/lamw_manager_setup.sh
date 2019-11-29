#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3613009939"
MD5="ee77db822dbcb1d5f1dd3c5a4ebe1d9b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21492"
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
	echo Date of packaging: Fri Nov 29 20:44:42 -03 2019
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
‹ j­á]ì<ívÛ6²ù+>J©'qZŠ’c;­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»7úa‰À`0Ì7@×õŸıÓ€ÏÓímün>İnÈßÉçAóÉöÓÆ“ÍííÍfcsóé²ıà|"š!,Óu¯n»«ÿÿè§®;æâb¼0]sNƒÉşo=ÙÚ.ìÿæNsûi|İÿÏş©~£OlWŸ˜ìL©jŸûSUª§®½¤³-Ó¢dF-˜ŸÇfè‘ÃÀcÌ#ZÎÂÄl(Õ¶Œî’áÔ¦î”’¶·ğ#èRª/‘çî’FıIı‰Rİ‡»¤ÙĞ›Ûúf£ù#´P6l?D¨Ñ%ª,í*±ñÍ $ŞŒ„Ğ;õŠ¿ZÇ¯`zT'£3 hp€I.Ó÷i@f^@TÃuH³]%§ÎÎÔ/ÂI…^úĞ¾ßyvzh4’ÇÖàph¨µÇjÒ€‹Æİ“á¨utd¬,h.‚·{ƒ¡¦í§ÃÎ¸ÿ¢óºÓÎæêœŒ:ƒñ¨7î¼î²æ6Ì2~Ö>7T”«B†Ñé€•ê!êí€NC/¸*ò¶9 Š=#oˆûVë¿Ú×kÅµ¨äİîœ«TÊÉÇa0¿ÃèˆZc]ÇuîùÛœ||C”™­¬gq-7¸„p…Tƒ0 ùÖL½ÅÂs5vFùÖ((Æáæî¶E™M#ºğl‡²G×D©$¼ÒÃ…¯ç¡ëSÏ¯U$X¬ÙƒUİÀ„í3:='€±û>bÏ"Ë#º˜Àæ(à”Ñ Ë†Ğ(•©†S}x‘OşJæõÅ°ø·Àö3Ñ-ºÔİÈqbªk"ß¤‘ì&,¦²*vM¥"¨ãs8æœñi]zÑĞÙxÀü¦
 ğóÀv-£¶	;<=ó@†P7Ô„µ–€¨å•”NÓÌÚ¸ÎÕ®ñK×S´ú©øXLBÏ2‡Œx°Ã˜1~ƒÕÊ›®,ã;ï ˆ
™Ï@S”9Ÿ:µ÷ù²™Î ÍL*«jXKíRMgDn^ç€(¾],:3#'ÜP ¤•í0ïÔl"áSK”²ö8U*YçkZ;kßslĞ†v(f„çs;äsúçô’N	u—d¿;ìµ~5jñòºu:zŞtGĞ–ı&ŸNŸà*©å,[‘½\˜ü€2T#‚İ%ôÒI½^W÷jZ)‡_%®"r§è„´¸~\1_i,¥¨#\$×(©RÉ$!ƒLM
ÄJÜËæ¦°’n+oŒ‰]˜¶›Rªà'«ËPÏÜ§RÉ41X5è|ŸDš(s"Ïo•?f0™QrÂY©È&ÀÉ‡åğ­¨IK|ı¬ÿÁ‡¶;'CˆƒCjÕÃËğ3Äÿ;[[kó?Löòñÿ“§;Í¯ñÿ—ø<÷.Ğ&EŒælÒ®Ri’hs¡ÉÊ¯(•‘Gâø‘ı6Œ]L×‚ñ•|j)D¾1:À¿:NÀK¡¿*æÓÿ:*@8şŒÜ¿#ÿonnnô«Ùøªÿÿ™ùµJFÏ»CrĞ=êø†¨­wÜu1bû•´{'İÃÓAgŸL®òQŒô"²0¯¸À‹xQaÍ£°àê{2gÓ…LbŸ€,<ËÙ“@0Ãø¸	%ÇÂz¾,°šßûfÀDT'+Å‚ğÈ¯‘«Tå!q„O4MŒ¶¨c/lL&w®óœ2êÌˆÌ#$‘Yà-À€ k:12Ñ1í’³0ôÙ®®'Ãê¶§™¢‚’Õä¬æ­öVƒ|†ˆ•#Ë/}Óe<¢=3&0^E™ÙƒÍ™N#éPàL¼ÕÃ~à½éó:‹¦ä­~Ø}µÊ_Òşó’Ã¿Yı¿ÙÜşZÿÿ’û?ÅÂ«6‰lÇ¢A}Áø6{kÅÿo>ıêÿ¿Öÿ?±şßÔ7Ÿ¬«ÿıg ¹ aê¹¡	©áÈ ñmòï€Ì©Kv BÛ¿ˆG­Áñò)ÑI«5h?ßÙÒHËµÏ¶¾cWªé44!FÁøğ?±<2ó§qgZ&q=Òo¬7šX–[~ø{`›K›òb¥¹˜ØXğRx€tĞocİ¹¢ToŠ{h³p<µGi%Øf,¢u—†XfXÈOá€õ¼°úX=Dn‘æuõ1 ¦L,]z18ÀØ	/»îíñaG¶]’cˆ¡HóÇû¤Ìœ*)9ÍŒŒ'õF½‘Çs:8ÃB5‰ÈØÒ­Ï
‘D1NİæØ¤õĞœ3= Äã'ãÆ¸¡J˜ Ëø¨ûlÜoª±@wì	äPU	¬}p˜€!Dã¤Õ§³yå sÔi;†zëÄ/;ƒa·wbÄK¼YzM©f\G[ —¶îµ¤­[—½Ø€$Ë¸üagšæ  hs7ZYWZà¯rq ‰!(Í\yQ3¬ôx
ñÇÕáÜ•aÁ€\t)yûx“À›á‡‚FaPÀaÑ%O-|N˜½˜|ø§cO=>w…àÉä†ñ™Í¿ˆãİ¾øÕÁ/I¹„ßëØ+ğ	SÅkã%İ•0¿@ué¼î€Ù¹8³§gÈíÅ9¨Š&cÛˆ+åj-7H%QÕÕ³“rÌEjë¦ºß\÷[¢Ãõ‹"½RåozÀ=UÈwi…„Ÿ+«px‚„G(àdqºÑàôäIùGa±?ÇZ$+Úf½¡MÀ5¨)Øx®v½Òöí[íñMu|ƒı¹ÛL·º'§¯ÇÏ{Ç.ìÌ„è–Ç	óğåÉ¨uxÃcÉŒ7uy¯ê õùojÉêRA,>•ËëÕ…Ş”`Ã£X®KñA¨DTÅAO	ëVšò$g¡¶º$4öñ>á•õ£ š‹È‹ ¡˜ğpEy†MmŒsZÁBœò™îœfçö+»EJ %ë®T°¶A¦`áÑûŠœËÉüGR[&íşéxÔvF†	°×ªf!. ±s¤’Ş0íizÃ¡ lû õòi‹híÙËƒşË'*I„¯?èt_¸3Á…*_nÌ ®Ê$nIU¤’İIÄ±w:hwG%/r`Í½Vl4~ƒ¿Ù~Âµß²’î½ïO/w¸,;Oç¶F.^ƒ`Ó÷nLÀE:Aà»ä Ğ2iÿ5Y}j×'½ÁqëèF%ÂjÙpÅV©d‰%‚¯¦Ç¦µRíW1´@§©ıv¹œ­…ª$ëËØ¿
$ŸÙW@^ÖÁåÌjõ@: lá:HT°ËºĞ
¦g;[¥úpCV²İÒnßCL>‰äçµãùÁŠ´—Qw›@­½Ÿqy*š”$ãÑcf‚¥db…›r'3>·MøX.U?nûä;¶‘#9ÙsAórë^4Ç·ş°Mä!ÙDTµ[Ø†™Ã4¶xæyá0LŸ+[rá…{©Äím©MºêrpÔ:ôĞh¶Nö½îş8–£Â§0âIÈš›-Q}‰ÔğÄÙ%Ô$.·
99Ï+f„¤ôå¼-‰)¬Ê—Gb%võ³l\©)ŠIßœ›s*<î~ç uz4‚o”Úö‹$a·]‹^òK/IHj×0|Sã}ïn>z­¹€2áğ×*û¿}ı—_3bâ&Ó¨eƒ+ûÃÊÀ·×·vVëÿÛÛO¿Şÿş\ÿ]`éW3…ùÖIz\‹ÏK$şõàe¾ç2{âP^Ûåñ 7w±Q‰×‰ËJx]­^ÿ2Ü.)00üvhã™sDÓPªq%Ëäw-é’:ÏÚ¿QpÈ ×±?s‚ß` ^K\Âpÿ…\,Î3Ñü ÷	|t:œßÏÄK"j©'ñPæU¦µ€i ƒ·&×Aéõ=†»lã=ÊÙ<£	á”Ü>?®$QÉÏ|÷|İ!uM›Öş³Ğ;µè’s“?°İpFOŸ:Ç†¡Fl¢~OZ£ÑàÚ¶^R×ò‚hşéeçd¿7øú{ûCmìììÀÃá wÚ7Tß‰æ€W}ë>$ä¯²Q*ŠñŞq"?Kßnj1¥uŞ„40,ñ.’€—1C xZŒÇª\C(–6Íà/‘½ôPƒS1ÿğ¹îyÏ˜d%(¹-*©Êâ'WFäŒ7_}#šEÀÊQßÏŒõKÍË#DU.'¡Kb‘Dì!`å3 [TÓÕÀÃ¶~šf<BšÔj÷ ÖNbPå6H ¤MiŠ’<ÆyŠxzm%? ö[ÄõÈx7©9±µ¸ûÀ©¥J«»Ö¹î;fæjÁôZ«N&‹×q›4À˜°'As¿-§Î<Ş7îp‡ç@.ù^NÔVıGİ(¡Pİ¢Ê—Å*•‡ÚA”ßø³F^À1Şb9§áÃ¡?ş„1Aè<»J×=P¿7%«ƒD‘Ä¶TA³ğ†8‘äDGX„J…qİ8²]j»x‘¹€“3IˆŞ4ŞñD+/<åŠ»QgÒ3šÜƒY_3;¢ S\¬Ğ\P\Ø0<÷C…§ïÍL-qğĞ‚$Ãµ8Ç«)	}*Q%êTBÒb}\­nYXt…^?ğĞùq"à‹–øØ°h¹1(	¦Š¼Ød j13E< U¢Ïx˜Ô@ymÿîÖ­ı£@"÷øÕuÁæ…“ü%¢ÏÓ=ÇHŞH‰'Pï?BxQ 	*«»­Öd¨Òsº”ø]–ÂÒùnK{ë¯®bŸ¼­{c¤Ó¨ÉOàÅ~&dí>äÑHÜ4dÖr$wà(Û™4(ZjP~"Æâ~ßŠ†ù$9#—ÑT
[˜W:àEyf‚®9¶šø2ÇzH—;Nñ{RF(&ŒbÜ¿Ægî"0à ßÃàÇŒ^q1Jµ¥yo&ı‹ÌÀöˆ*¸¦¥7õ"’¿ÔHM ÃÊÌ†"*™½—-ÇI#=q4ê¹ÎU|}[C‰ôU€XY1ÈÃÆ\¸±ãÕ©±(O!»Ğˆk*ñØ1‹]ÆÂ³ ,¹°3ƒØÛ‰Õv÷cÃãŸ[ƒÓ!¾äñì¨#ŒqRHYKE:UŒ3gÍ¤iJu¿¬7Õó²Îx-kz9‘¢2¬ŞÉ£Â`Ïy9|ı1Z\¡›—`Ä	‰HÕãİ|/	  OyôÈ6{öOµëªÄœ7ßİìÙß}·äF?qhzÉ`ö»9Àâ’îf?‰6XWÜAì)–µ.;Ä¹s.‘é»
oGLGŞ¼+%—ş&vÖ†¹}t©jQîàM‰-‚˜”«Pšrê¡¸ä#ô2=]HòÊZùé‰ÚugŞ.î©*ÊµíK·i?¹ğ‚sæ›S3÷Uoğbáp'ƒ‹ë±­l®˜u.fLúOòı`ÎŞº‡àåš³\gïh,emF­Ğ &>e+–xgŒ1íÏ?s=G½ŞÑ0ƒZiâ€'ûÒ©ôÀ;åË 5iSc
!mŒl4rˆb1OûıŞ`dÜ"JªØI.›šÄİÚ#üÚ€Œ_¡iÈT,ÌçŞ½±Rãëb	SÓ»
'½Q÷à×ñÂMqƒà›Â‚"±·î-ò%:3á"»¤L¼Şºëe+ë»§\Áœ½Ãİ»y‘Úğ8#ş=ËÉÙKqÕ<úW,î­Ë_¾›ÍcˆI¶,Ì&ÔFÍØzü¼ch+–\nq%ºéûNúŞCV§ü@_Pë=Â¾ÁF¢”3|ï»e@ÆÂB–/åÜwbá”îIñÂ^PİõVZw¹÷h1oÎn[”‡Ï#ìÌ€¿ÙÍ¤ƒ/¼¹‹zb.¨‘m‰ššz{Zì"|DµsI§¹£7ĞB‘»iHğÂ®4‘Qi<1)÷ñ|òUåğ.cËI	êNÑeåá`"X½nCãQT±±`@W‡F>nDƒ…íš13AÃDÓ•OV¶o1Ú )s;RpfÛ[…†syÄáèÅŞáixmÏ‹{Âîãš"ÿÕqÛ1+²û¶““ÒËP¿ÔÄÂ=ş/ë½ÖÄ?Q(ï³]¬t²r Øœo	h)"!R¥XŞ8Ï÷L=‹Â¤y%Vù‚^­±˜!jË{}±äĞA@iükOpg/Ï¤7-ûi^íî¾Ö^ìw´XÊ’v.CÊß»y—íßCùxÃKÓ‰¨Q¦ñÇ×š¸[«á[¾@­¶ïákÒF¢çø¶Ò„­w[ããÎÉé¸;ê'	©Na{!;ùî’”ƒn¿´¦AŸÃ…x¼ß¾õúü<¤€€txSÛÕû€ÎÒ÷¢Î¨ã×ç®· ün©i\ëìŠ…t¡ñmÙEí™8ÂBh!°
v)‚ y¡EÄ×ÏÂ…SGC“Ò–©“°Ùéæ"†úåÂù(KgK|vøebù‘{ H‡ÆlÎF„ıMfïÁ¸·áõKHEÅY@êº'](e§ñ„ß7•`”…eM¢Ï°è@‰’)mßc¡8±—¢tÏ±Æywk¨w»duÅceêÏò§E0¹¶¨VÉ‘½Ì² , *÷jy˜USV‚,aØ{si&‘+3e×bß/:vjµë^¿sòD¿qñüFá¾·Î5saALJ>nıä‡u#7?wPªš´…æÂ€D1GÚ›ÿ‚°
= S:¡ÄC0Ó=ãÿ%KG’ñ¦
”<9H«"•¬ı:ùù­¿æ$M%6±öàë'œ X
ù)ÙØ Urd~ø‡'J` ùÿS	H6w.­]ç©/d°ÙªK `Zr¾''®xK¿BäãQ&¼àû§hRrB/úÂY	ceÒ‘÷*Õ˜µŸ üÆÿá€3ãÎ"JRòÇB“ĞŠ}—–î_0ïK9$uÆ±ñ	öçBãU˜a†`Âgà‹j‰H]"Ä6VòÒ¾8?°zÃ_‡†|† Bpm-0oK;¼Â°Dä‡‘ãÄlæ!\š»ÂihlÆ‰tRq@ğ,uÜB9ÉîÇ(F#Á¯ìƒïŸ:‰æI¾jlK«"«÷ş;wŠ»êDÁ¢K.N~tõ#ª®”1Å¿Šg(„Ÿ©ğ>”îàñˆºæÊq­ĞÀ™R‹'¿3t&oñ]åµYwZÇÆ:è!XËœJªåÑÏÚ8œ¨%¬Q%ŸCnG»$œœÖH¬w<jr|•0É¼‰Bî^ÊZdÙY¥²š”bTÁÕ‚~]^‰ÿµ„95ŒÏVş©Êg³ †	·ş¦×Yô¿í}[wÛH’æ¼¿"rJ’×$EJ¾´dº‡¶h—ºt;¢TÕİVˆ„d”I‚€’U.ïÙ§9û°/Ógf«şØFD^	$HJ–]53ä9¶H ïñÅ¹¼„Ã{høªï¤H°­ÊjâCVmØÓ¯1ş)ËT£5Û ãüöÿ†	ĞúÕ¼óôkkucFD©ô+êæ¶(™pğ/[Òoÿ›]y?İ“¡¤„àX+ïl¥ GeoôáÇ¦ª/ùk¤µJ]¢IO®)à ³ë yÇ`”İÔ¨¥â*½­¾ƒÃ¢;>ü+ê„¿'$©öÆXÀUŸ,”ÿ2H¤ĞX­^Ãsàh1Sƒ¼½¢1§Ç{¬Lø^ùö°{²Eµğn[1˜övÅğ+®<ÂÉ€¹pë¹ÁÁLõ[Ø'[ÎtTÚ³²ÚºQ­NÇè|cŒÊœ´F×ÍUOE. R±6Êèn©¿sJª+õ³·XõÙõÁJ.Ñ¼œØkNe9ÿ
o7…Ñê+n›:7”Í¨ÊM…nDéèsI(gTMÔÑˆ6ˆB[x0z5²7Ğ®ZD:ÉŒµZCì°k÷ ZkÒ{m–Š‘\Ô“iR¤ô2¨FùD†Ü˜¦5™.ZŒäîÏ&ı^2šÈAr!]3<ÿ	x5ìıÑ€Æøw8ˆ8b	şà3ÀI_Åı°–.ø÷Apq‘şšNÄw<^6ƒq¿çÆ[ıA“ë]è†Ÿş«yã˜ß÷óÿŠ|ñµ8}8&™Ÿµ(ş‰?Bëxñ]Ú´¯iU,­8Ñ¾ª$ƒW=yÏKˆú¢e<Áådæ²6Iø4å?"ï¼wÕ=úîËn¿Ã>Ê¿,‹ıã„÷ñ§8‹„ÃòŞj_E¥£÷Ş“Í€F¾¢~…¿Ş`@_A@åO¡¬&Ğ¬øö	!ôM¾œ&ê‹(~2ôqƒ çºŞhâ·ÉÀŸĞßé`:ßˆJøW„aÁo0pXçİŸ$áDü‘ÅŞx}ìb4"¢@J‰b\İWé7‘4™h#CŠ[;‘/Ò“öUdIşÚ?CDrc4Aã¹¥—Š¸-7³`¸ILš5F1êĞç¥ò9ÍÒƒmF{*-F®$ñ¥ä8©}`$û·YK<Dî_lCÍ«›HPÖy9Wês#ÎäÙàÌ4G@]T:+ŸÕ	DTÂîÔïTß%Éª›µÆÍÔø•»#.â¿XëEù¥ÛT°ğ,Ì.T·™UÈ§¬I¯@Ÿ
‡)Mà¥NzÌ`éêè
öå!"3Àà'ş@ßÕñ@¸ Ylû„ºy”Ã™v{Oßõg$XR6ûÜnƒ˜­]K–´Q\enhTªlclw=9•b#‘Œq‹]O/µa±J³’WÃ×Ó¦Ô„"Z+wxN}nÏo&Ú7™ì^Ë*iêöIÑL!3by‰/Oç…0nå£%5n8† È“Ø¢éÅ‚‹F½p’Ä-¤G7=õÁ5« ŠÈ¦K—â w:Ö9Åµ2ü…P‘°ş{_Uh&’‚Í¯&Ğ 10š1b‡¿]ñ|k÷ğ~Øãl¢5ëX!`S—¥öÜùâ3>øZ%%C¿{šB¡}t/Œ‚Kqò1t£´›œOÇnm†€åûªadSğx6ëY8½`H¸ò‹i!›ó{+B›|Ûà3ÖÉ{D»¹ù–úò"Ó™/ó×)‡Ÿ¹_-¸‘ŞqGÁ$~²éÍbn7ƒXFa	sEs*3æ’¹lß3Ä¦a£ sHá	Š‡'‡Òä^äS;¨ØYÅ”ø&ÁĞèh†×™ä|İÎÉÉîÁ›nqJÇÉ¹XßÅ/h/Œ?ñ—7Î;ó8º)Aåô œØ²;¥|ªUÚg+Ùì†Ò½×Ïê•<TL½~‰çßò0Îgİ¶—HûÛĞŞ[¹Ù½,NGyŸ#ÓåÈğ8’G³ıîÇİ(ëm¿§â¼¯Î§º»2Ï7èn9¹Ğó
_!çùG)·£Ìj6©úLÙ`Ÿ9SĞ–Ùs5«ÓÖöÌïô>p±ôëšn’rkW±»yŠY\ÄîİClq1Z˜™èui^Ü´ªæ²½Üı¤‰vFx´R)nËRÊê­ƒä¥»÷c¶bås{0§t³íó;å']cÃ,jœ»fÇ¬@'¦øôguk«ˆ¹ä¨@cøy;¡&ÏX~†ˆä€ápÄ½¬DrÒµõD˜cU,ğr64Í©¼¸Š-4ÊXmŒµr@o¶&ájı,à>ç]ãõcò²«Dë|ßš‚W*›>{2Ï©Du£ZŸ]'¤ŠÜÛÁçÇíã¿¥Ë­k«’¾ÅjÊÕj8P—›+Z½‚¿Zy¸¶’yAQŒ\ EÅ¬¼½@1 $'È
\$ô,¦ãa>_:~+ú¸–VøC&û–b(Ñ ä9J÷£JHÇŒ@´wH”İ5ù»dL¡-üµ½-+¢’8ß™Wši{iôñAEGÆ>}©È"˜Ö—ùñÓŠÕf¨`ŠmÌXeºÉsqFdhcDxÍõq9[Yi­ï¯±}åùŸÑâXú¨¹Úº'€~8 &ÓrOO^WŸ¹~A½|Î"ÿQzŞ_Q8FüC?‰éì¿Ï÷xm)^·?sëïÂ‘_'˜›º0N“ê_ı+$|áŠ²„
‘†oì|UVÏJ3?¯[ÚH¯×E_tK·ì	Öh5ñòÓ‚C^0W=/`\¼˜m±I40ù¶Ö‘¥|nbİ¬‡*M<Bqî¡ZY•…]¼®‹aŸĞögdû¥»F€¿ÀtÖgg2`Ï*«0/ßûÑš[ZcTN©Ü˜]€a¦àÊš!_³0_Æ%­—©6Š(Ø4¨	i›·m?ÖÅÂÊ¹ï0
§hcO6r¥èÏ°t»xÆi}EƒãÌ qÊ›â¸^¼†>jÄâ<,oRb4’°“¦Ù”.¹¿äy‚YlƒŠ]8ùãù­à¢Ÿ=äD¤_jä›€‘ßø"#¢lÍrökÆÿkl47¹ø_eü%şÛ<ü·«ÿm½Ö0ñß,èoF˜¯1‡ÑH²ØnØ.6fşœ‘«B]Á™oèó^*¼_>¨—¥$ªù:oNùÍŞáËöû¾}¼‹Ní]^í«pFèò)£Tß9Şé´*+gşÛÆöFs´¢B†ï·;{‡üÕ:¼ÛHßuO_ÂFüm{_oªÇ7Ç»'"K#M.dU5–w=£LJ¶i$lÿıtO°™>çH³¢™ğ¸}tÒÛ;|õ]E'·~åqËÁäı%n	x½–>õ&¨_Œ“Ø|Õ÷úï|z‰G Í8ŸUX½ˆĞñg<p5'~Ò%C{Š…6èyÃ ÎL±CJİZøı!È`¬
'§r@tç±19sÊh™D€mr`ìãõ=¹İQXa¿ÿ¯l„@„Á˜!Ş s2ÈÓ©8E51MÙ›xkàx™­";píl+3—B?ÖüÁ¸ì›çÍ¸ ·Cı¥©§\%ÍÁÃ‹É#†V¡ì!â2X×•v›T™è&š|¸;+­&*‹å’i4†}]8ª_„Óñ€…k0|D?\;px(r7ÂFÁãÖÊÁáAgÅ2fæ¹•fş]8<Úf§(4+Í	+kFÂPÄåAV‹uÁí9ä]}%}-Å§ŸW¸ïã€—½è2f|(a\åoIŠDèó ÕïÑŒ¡L´e%°0à¦­ÕÊj¥”Ÿ+8AÇph]¼â’è6ÔB…Ò7x‚²GkuÍF€ß|“D˜ŠÊâ´§ZKÛU´ ùT†éuÉZUZù_ëõ³z}ZÓ¡îE
<í“àElJ<rM©ÌåCq¡‡=Òæ[¯ús»ú÷õêŸ¶\3‘´`ü!¦…y¸ô?0o858!> ŸÍl«ÒÈÖ·e;)Ò	×6æN84Â;“,¶ÈÊ¦{´·{rÒÙéµÛÃRÅÌP6š¨tr²ÌA¿í†’åÅ¶ gª¤{’ÖÑªä0}*l7‡çzÓ¹É„M“på€>xQäİ ‘JJä½@ZX£Ğ4*%ïüœNicSI¿ón¤%é’3§¥N¯2Ê™…E-EbA^†a¼ücTªSÆ¤ô•@ÅĞ¤/F¦~ƒî>EÎ„RiQ2´å kSŠ¹µ‘Îp{ÂºZ•Æ¶ú­V0¬¨ô)ß˜pİ·*ê©èŒ©X´`.™Ôr°bê¥¨”XÆøØ6R†œóp¢Ù`†ô$’×«‡°Ñ0^ÑG&]Ãái²;úM… &Fˆ˜ô“,ˆqï¹'9Úw ^ß‡„íİ¼ÄošÀÇgNÎWbRT¤ÁÂãÜ4u˜)QdsbøyœÕ™šYşF·.ôÊËXÃ?ÊùçsW°,€ôµ/P5)Z`Ænš•)—Ë´œ‡¡Õ5`”ÎŸïÔ}[¶ùPæ—Hdq!¤£BÒJu9†ª½7L£’Œd6]PÂ¬k·#Ëô:öófFÙ315ÆĞÏ9)İÖ$«ÍŠ¢2‘M"5n•õëèû­wƒ[ÒÛg‚¦ôV']LËxßÒû?”·-µèvÎµÚXÅ§0XÇa˜ÈÂiw1[è‚5’–ĞØç›H£‰;
k†R©@È›x:›&Ô7ñ‡!GëÔ°ÌDdq²ºFŒOî×? Ğ*ÑtL¾Ùœ}FÁLù¥Ÿ;pÜ‚õ]«Õ„^|Ó„áÂÿéÌD\h ô!3¡;N>ÖiFgA~é'ÚêhäáÉa*ØÏıAL¢]õÂ¯2®!©4gï³j&ÎÇı}c±ğ-«¨4P¡SªÊ–´0‚hç#í iÜØO †ìàÏn°“è†!JFôÀµœ[‰¯ÑİtÄ(Ò| ƒ²Æ	ÀÄÂ§s['0Î“(ìûqÆ±~ Qq‹½KDä”õÛÿÂ5z F‡œ ,L#r©—Óø&Ã§Ös‘&1Û†É9éêÚ)q·b|ğvıGù~ÓQøú’Î""`Ni€é’k>ÿ¦ÁÊşø_§¨¤ÍaAub¡ô§•öLYÄb "fŸ¶¼ ¡ø	•÷P(•°Um*QtcO†©Õçgâõag©;
GÌƒEÜ?ÑACÕ`Lq®Vo€8áux]½)¶(AW°–MÜƒ¥ªÁ‡ê(ÀXN—Ê†«`ÒêaÇ‡AŠüXMTœ]8Ú¤bÛ+•F§À)ÁÃ*.îb‘ş–N•‡8c¢±<‹`¯æÌu]_Ñssk?±ç¼À’UÜ¿Ÿ…§šD éO˜•?ú´ôUâÿš¸ÿØïÄÿyü´™ÿ³ñ-ï–ñßïÿı±-ş«Sù‚~^ÉXïF(wQ
ø3Ğ‚åhæ'_)²{yùh ûº9ûÎ'¬DGn·qsˆš_0ğ{h&Ô²c§~«i>º—ú–Ü*Åuãä‘«Ë¼«Èø9â°Ãá€	³&&Åò¬±•U.$TLæô&¡¡Ñ‡”ÃC[ôú€ğ›u\ç*-Å	P¹lgÓrÌk­zŞ]%QÊ¡vwÎØŠ¸Ü®À>D41ËRã–V•ó·Õë£ö[<rs¥dAÂr…XPÄDPÍbZş<òà—¦ÿ7Ù¸ó¶@i”B•®¤º©¼„¤õĞ×¼R#^>×…®ÈW÷PÃ‘æİEú3²Ñ’eqlR ›L"“ŞìU·NæÖ‹ifW*Räun 
‚hØM¼ds	›¼‡SÆvÛùÖM•%R?ürÚ¥›9¥O&%K3d¡ñé«ƒÃŞ›Ó]¾âÅ©¾Ş–'M#–fÊ_U!O™#YâáÑ‹FŞÏş>¤æûíß~û¿°Jãğ<Bõê‡©[?Ù4<©Š‡"iµVYeoµY5¶¦s{q™Âcnı‹< ‰#§~!Fš¡Ì©ÑªZ5£*|9Ğ'ãHŸªÚBre(0R›µLE%dÀµoò·ÔÆ•Œh²0V,E\Ë¼âPİÔf€dä-%Æ9~õÎï¿ïZêƒ­‰æ™.î›ú¹šKÌ¸ùw{ï¤s|Ğ>Ùı¾£â¢)nÃ	Kó
ËÁëYŒİ4#êlÀµVa•íkİ[G´/ìš¡M'X².UXê€Öw,m%/_D1ÉŒãwá5–%ømÔÖkëæ`°9£qĞéìôN»upgj5Ò àÁ¶ãŸô}½~8ñÇÙù‰Î2Ş{ñô™>3ZÍ$Üî³*üŸN'í·[éÛû|fÕ]RøƒÁ6~¹¥…n–Í}&­›bŞBğˆMcÚìyŠFãŠÚL	g3¡‚[ù`ï¤+Çˆ{ rASÆ¤“ÜÕĞ†c©Ç5´¶Io?r
y¹Û>è½@0½.š”º…ŠÀŒ™µµ‚Ú åÈê9ğSìè2×V›¼¬±¥r§Z¼†G·ÈÇÓ3‹iÒÀ?¯ˆ ×¼Ç¿öø¯F¡†wiY½‡2@ôtpæ‹h½æÜ;ò"úÕsî¯qÒå ›±7ğ‹½€(bÕoÿæ…rn2¤+[#B·Ğ¸¹¯!^ïN	Œ¾7Lâ,­ØEœQµ:™F—¾Zª>„M…ÍOØh<¤İG,èØOşrÜyÆHÏ~áM‡‰ƒ`(yñò•FBªó’w=œ%¼öæìOg‘¿¦´dÆ”bróÃJŠŠ{¥*P¹%D¶ P»`ƒKST¸T%Ìj®´§!s*u…QŒ’Ö®R=bjYr jìG­J€ÉÏÆİ$œLÍ£-~O!ìÒ®@ZaÃ™Î_Úß·¹O—[I“©ÚEd†¨qÛ¹æ•ÚÔÄŠ*E³©ÚÖ¤fÍ¤Fé”¥Ä2ğ'±#~ìøxwˆj†8sŠÇ²JF“ÖJşÇeç2ÚÌº)ş2«÷Ú?ìo
™2{¨ÎÉ3T¬b‡*2Eò\ÈÒU¦™5Á¨)5:‘=g’ n¤Háˆ„/Œ™ŸÇÿ2ìmI2çäiÿ=jt!o[\’Òmß)ÒTòü!º¥y•gÉ(Îó<‰º Z¶Æp‰ğÃùşñ…d’Õ+Á¶V³µÇÊÛı^†šƒ}à×Œ ¥8iVxÉ°Ñìîì s¶º@H³Ü.‚’lv?,Ë&ï86Öê¨ìí¾ìÊó¡ö¾áşÇ©$d‰I€Œ· .°XªAvÂAˆ¨ÿ#?‰Â˜¼êøO3hÆõµaöVÅà=‚Ö5ïòC:ívz6Ì4¥·¥©ÌÔ›+ª²YN÷Z
°¸¹Uá1|%Í{66KãTŞ–Èªfföv_uº.ŒŞq{¿‚7ÁªÕaĞ÷Ç1qÍqØ£8*„²£ĞÂ_òG/ ­^å°¡é0‡µî·Úo:Ç½Wû;ZÅoaÅ´	—é-· 1îg[Ô—û*Ù“íÌ,º)hj•G Vı^á6­ÕøİFKÅå}ìVR_6A‡ø”Ó{+EÑ6_Ç–÷\´|ã'º‚u0Ê‰/ºOÌ%ÍAÉk€Š°%Dtù>ò4¨@3{Ä­
ÎeÂ~E¶rÜÙë´»zàéÑ‚IN¬½F[S{ÅæåÜ“Y‚1Ú)ÎR:¢VGGË€¤3»›&"(U¥¨Ì:SºÙñsÍİYã8³Ô{¹k6¡¤(ş(¡J ŞøÒ¤r†ÿ¡ö[JH3~Z…wR¼ÉR†lsxjz~Ò•)´ñJ.Ql¼¼şĞ–©x4w©jëL6ÂdvA";ø®@/Áx„à/bÁ8‘~-ìK AD)eêÄ3£ò¹Ô“/ò¾ÌƒŞtNøMßk80D1<y-cbiç…Ë ÚÀ‹ÖªÛ‚ôèÊ ¢/èÁ0K–,sQªYõz<A4#ëpXv³0/˜ÂörÎâYİÜ_DlÁhÍ§¦öéqFdû
bã`zC£ÇÅ¨OÑd:âŒpË¯|Tï5³š,å-Nö|?^ˆ,fŸ1ÊrâéÓ§¬z|U0FúØ¼±°.£y™¤ç¶u¨ŠWéİu›V‰ë}l°ìÛãä$
.ÍëóÌõOöx[%‘¶µR	7±Ø’nğèª8¡íEÍãö|`äMÖÌJk×Z+¬Ö¨U±ÑŒ©-Æ	m¶0Ô3ÇXßlbÄÄ¥	C	c/DÃËxŠ-%Ó/fp—é¨ ®
T§_Îî·ßì¢LÒ>êíìtşÚZge†&~„GRâİ¯4#ã:ÆØM~ûG„hµBéfj‚Ã ùy´-‰Âá+Æğ<É•Ø€“ö±ÑsU7ÈÙ	d¿W¢¹˜],İÿdÆ[S€3^iÂ&»f—46¤˜¡mÖ 5Y¹K6¨Ü|¡Q!4¼„nAÁğÇƒşÁ´—coØd«ğÎÑ~M'ÉšCÑ¤¿ï	¹!×<¦OÇ?#±}3ï3ãhËÍ‡ò`ç»Å(:£)¶P«wİ0¶Èe7“ ‹Ú6Psµ8ëæİT¡ºR2j¤8½¹=(}¯ßãæ&ì‰•BšLÍ9¶ÖLÉ–ùi:Û˜&Ë–
¯Ş)(¦ÙÙ…%x )™Ñµƒ‰r²İ×Ê—ûµºÊº»ovN€{q%-òá;ãmMGo¾ É}Éæ¹«`˜2¾"=ã¤6m•ÎXÁ‹lfe:­@
ªyµYİä±ÇáŠk$ÒÿH  è9)úÔõº5×šµÇ®-‘R‹a8ßÁ°v†—C¿”D ­%†1éİğ]¥'Êãè„5˜OkÉ0ü-·8Ñ_nh´AĞ©“ŠNÅœ;7›Š,Û’>NiÓè‚à/Ùg©H¢±H$ÈÁÎ¹óûóy€Ò+¥KÃÁ;¥8úşÂj°=âvƒ ŞÍPˆßSß¾¤"uÃ½s¦¡ß`Ó›W~4ôQÒ¿ö‚ä‘:áU×™+ºUP\€@<Â¦®Èƒ±p¨ŠË$GtáÙJD´cá‚Ñ»)–Åtë´œ8~—šÓ[BËLİi®´ÙJMÜ˜æûv»öÍîñ±¯WXÏ‡ÃAÊŞ5µ´½'ßÃï¡[ÄĞ×¸ÌY{rß›Î‰[˜bÄù÷x—¿¬«/Ow÷ÂlaÁş`œq³xñ§µİô0NHÎ±KpøÖ\r75Óı`^FZ6/±½÷“¿ E½hoò¾GÈ/h‰4g´„˜¸¿{ XÚvâêAC’›ËŞ³1í™•±û!™Ó»Ğ\šÕ©Q?R.Êb›V÷XŞ–7@İ#?Î*Øª²U.•9V>~+ãÌ´òÑºlÈ‚£óªe.N432¤¢€jó"&0à¢r|Òáá~ftãVıÈĞ~ÍíÜìü&I^tÏbQ˜&Îjãİ©ÁJ%3U/‚’¼¸g†"÷ØŸxA6#3å,©õ8sUüÔÕilR[ë.Ç-F~ÁñK¥=©²ÓKM÷„kµ‹€£İ•.Úğİû¥õ–?Àó²ÇÃòX&M˜'æY GäK/Ê’1ÀÈõ0'ñˆ­Óïù· Úªú”YV¼(²Dñ³l!³~:+fÓA­²{á·;01×cíês+ıÊªÇ…İœ›¯ TšŒ)ËgÚƒÁ€s2óOŒ*`"âuĞe–qp\X=a1ô»¨ìä•¾Xcºù7ÿó½ˆ^‘ğ¬H¯/Bc›u¿²åµXé›‡Uÿöé|Ï|ôF=£G*ÂàÙy*K¹Y#jğs!K;ÍêJl!@Ğ‡¿×XY( ä,_T|å¥Š
aÄ0YÆ¦Ã³°LU¹,‡2–:bxyc5´GiÀfy°¾+ğ9êhÆîQ’`ÖÔ¨´˜©‘¥ÅÖÃÉzµ®#Lø]gih
3ş9)*‚yï1Âœ7~ö‰ÉzË¹@î\Å˜0(VÚº”1»—¯YìÄŒCŠ‰Á< ÷ÈÁ¡¿/¶„PÄQÂÁ€#‘P¸‚ÄH˜#BÊ@ó·‚j¥ºO³]`<0•eeTş¬E¤7ßè¿R¡JğMmXà#"ƒ	X6úHÿ·ä{´È†Dí#/5…# ÷ü‘1ŠcAXŞÏÀğOÆn$ ½&g{l	íÈ']@o£·Ş[Ï¸p¥]]07+CsÒÆpIX"İ®-›™¶Ü²1›ò|ªj×ªŸ‰çæ´jge+Ûè÷a®*3¾³±3Ã…N½N±ó‰ö¯œ‰‡ÍÏN±q4ÜèS,Nî©$‰Ìø~’ìÎÏj}ñ‰›ÀŠIBˆtK²¦WKNÃ··&Ôm£„0iO§c%±»ÍäšÎ Œ.A3Ô–&»“à¿âĞ¤¥ÒK¯éE[tœ"îVUaï²»CvEa¤l{çeü+‡.H|œÅ½ğR²¦Ö¾‡×c?]Zù–‘Ù£>Ê®(Ú›'Hš±ìJf0%.u5n-vii#”îÆ„“šáá…NÜs}q@~ç¿¼$ˆÒ‡!>Ù\+ıdÁŒP†íL[1»<÷×%³ÂVÁnÁ”—ÄîWº2Ì©ä*q­—¢ú¦dïYÁ†Ä­’nÃÛ·¶û`Ö›ó,ş]ËÀE¡”ŞRRg¦dÅWX×¬:3ê³;B40­'SÓ"ËV33:Ù=ì8_b÷0ãğ‰h÷[š¹–Åî_Óo é¥ ¾ü±n²Š8úA?uÇ›]z^wrî_ÔÜAx§f}ú×İù&š§G.»®Ÿ†?Y¼©Ú.P'SÛÓ:Ãô¦ò2ööv_íôÚ¯N ŒŞşáNàex´3ØùáZl©9°Ê¿ÁÉ
Ùˆ<^±XJÚáMŞÔÎ©q}Ö²rxî'æH|Ş Bş":©Ã´¬d†R%GL‰èÈİk-¬”/·‘Œ
7í6l»!ÙÔ¡—Œœì>˜Ûé¸QıåF$â‘a6BÏPwW.ğvlÂB9£´iY†Êğ¢ÀCcw
v€Fï(oñ"ôÍÉ¾eYqÖìŠ*â¼ss{€íÄĞq	UéŒ,³9»–uƒÌm³ÌëÒErÆÉ+–0·‹ØöOwÄ«LêÓ†ş‰ÿóôñãü7ü¾™‹ÿ³Ş\â¿-ñßn‹ÿVï§oEqãä(7±¤x5›‹-i¦v}}]»
®¼Û“AöÚyTÀY¢ŞÅ°?U^[•à+EÙá¸
í«*j}%T8|&¯´Òö¬®1¥"èOÁÖ¿bˆù	¼ïpÿè¸s´÷7Šä/QE…{?ïtßÒ×Wø$eÌY˜¢Ê¡= pÆg‚¾ëšıM¥hŞ+şV=o ¨0E ±BsÖ%ÿèŠ2Òö*#:‚,óÚú‰µZ¬úı¨Ù‘jÂ8-0— ëTÀYlªU‘C)°×AœÏª¯YÑ2ıùâ9ª·ÊQ«ß¾GÖ3ƒÿSï|X“Qü•ñ?›§›OrøŸ›O—üÉÿïŒÿ¹aÃÿ<yçcPÖ”ÒÄ µî$Æq…R.Hgñ×	ù–ê‚Š„Ö¸Œr×ğ`R%Ò€fòÚC×SE#Ïiˆ=¯óvDqò€™XQÂê˜ãÁáÉîkôR?ØÁ ¿J£9“àâ¦ŠHékR?´x˜¬¢öj)é Éı+Ô'ÓYò¦jwÍQ’²PGköÜ¥§|ÜŞı;Û9díı—»ƒ“Ÿ,Gâx–¬~ÎÓıÉ,îÍ¬Œn÷×7½öI}º--|ï–ˆ—?È™…h/]Çªpi‰d^şĞÙ{…cáó`šyL¿O&e[5
&M”İ³ä,9
¯ıˆ<Tw¼qàÙáVzyè”ü³G)5‡·€«:ºGGT÷YòPÀ®ı‰’áƒS‚Šb'µõM¶wÒÍ½x–}Áï„÷Üá¥õ)•MC. Â^‘ì´ÜË1"¬Ê×Âıo4$=5¢ÆSqY§=µ€^µÖõ,*˜ı"åï‡ª;\gæó®ßÊÅ¤¿¢§°¡ïQ*°~^Qc‘G.‚Ö‚ ÷‘äì~wrxëòÃà…²¨ŠâñÅb<<:ÑZg@›¸d>ö“ZêÕ¦£Dç4©z²Ñh>s,Ğ)zq[ †“nQÃ¬K©dwõAÀMü¸;IusccãéŸp·©ñI}¦Ğıeı\½ÉxTµ¢Æ³s=×íÚ"íºÇ§£•ûI4îÃ³'½'›¹¶‘oÌ]3+Ÿ¨YE€PnõzRkÔ®“qÓ™9¦]}0›Ï\EªycöĞLæeŞ0©­#IíVÙ­•æSL¶Â{2ÎeÍ)DİÑ@wÖf•E,PÙ˜nÏ²ÙgÅşT7?İe˜¹y&ü–:¶ÑOn³*kßÎ˜Û›u™³Ïìf“ú9Û#avçªó:G}¨ò¥Sµú¨D²Ù~EÌ~™õ(Hõ0{4c(ud€”7\É»é91†ŸF=ãÍDV e¢Øo‘âP^pªéğí™Ëˆ–‰¨`¦ëíîtdªğè1—” ãÃƒ÷ÕX¨bñ†æãeávÓ…ıÉ(QkåErÚQşä÷t)«bQtE…p<ñú¾ŞØ4%À Ñâ|_ö;§½İ“Î¾‘Ş.gÕ½	ŞU‘qB¬U‘ö}ÿS«XØf­AÜÇ|..[+üõŠ£9T#IZ|`·ÖüÀxÑ§[UÖÀÒUMüİŠ£ùš§ô%Â ×¼	FFFÒ:â¢K?á ãÇuşQRECêlŸª²çêÚ‡Ÿ]G÷5‡­ã¶Ys1¯5Â(1Ù	©ÆÓu;í=*Uğ~½Zä{CU˜ğ&OJòQ–©(8Ÿr¢˜3cÔSÚé2^ä ‡.š<1­.±œ“n°Ÿ=É¾n¹2¬€›Ş†›9ëõ³Z½÷‰•9ÿÂ{.D%8“IˆáVj+tÖ{ÄÂsøy¿Ï1²)ÆpÄK0ê•ÁR=LêØ±}´Q½×."ßŸxgHƒ
ê¢©õÄ»ŒëÙæÂŒg£X¦$ŞZÿâÒo‘<‚@Ø4¥Qòö´ßÉ1n
#KãASĞè=Ãk–’ÔLb‰8™T~¡µg5ÊYrÓ¶$ajåña·Ûkï«ã‚.}¬P¨%nQñôEŞÊ³WG§R~BëC%MIg"’ú«:jïûÚÅ˜ñh% k=]=õ\&OGÇ×»máyveÍ)kMÃôÖÆ-Ü6 µPû
ÚãÎ·àŒhV­òö©úKÕ	¿6I#%õŞy.s&ñˆ?éaQµáä=  3ÜTùÍn•ÃåÚöoT¤²CXËÜÖÜûj²ø™¦âîÔà/Ù^î"\E¨úõ‡jãE¨H@ûŞ»ÿÁÁ±|ÜyÓù+û¾}¼‹Ü£ë8?÷±ÂÅ'†:ÅäÆXæÄeˆõ|4pÜ{4ÜWØZ‚óFuà_¼w~™¼f¥~ÁÁc|8Ÿ^hû^…MùÖÈeØHß~HâD~÷’÷Ú›Ëwıª¬	÷Ëá4ÙH¿Ñs×Iah[îÈO¡ÅÓó+®@f#ï½Ïøô‚D½!CPÍ0G^Ää‘KîŞàœ]Â?ŠV	5ğ`kxØH™q8w¦ wÉëÙ…§L(9Lø÷ºHŸƒìÅĞ‡cÒDƒ¬ÁÆá¸ŠıuEaUôì¸§I¿}û£ãÚ0Ù-]”şÅ\%óÒnôs²$öC{Nö¥(–Ãzª$€İN¶5/ÛÅƒ÷4y8÷ß¡^äß‘PFˆùö½ó ºYûS}ùH"ˆÕŸjIP&.P3i+×==B2`ßv ™Çİ{Ñ‹²ïÖE¾Wšİœ×E]jš³g¯|ÅM[Jg(’Uğÿ­ŠuhTûMSjNÒóZ]Ñt®ØŠˆÛç‘7†ó
ğıàpü”úr…Ù•¾ü]˜¿„Ãí«â·š±}ËYJœe¥¾ ²Êo¹ù¶gƒ…¬<[É¾ÚÎ×hÜƒïBüÂ!w´İ¬m¢pÍd7'ÙÔÚùN²iÓÓë;rª)"²˜¿6ö u®DPgÂc¯#­n®ÓÍüõFƒ'›ğ¸ºö¶èÌDŞ?¸A÷06ÍfµÑ£üÈ†AŠXù]Zƒ6â¼5Í´5+Èİ«¿Ç$2	/„í(×¾Àšç3ßŒïÃ¿Â1ÍÎ’şeŸ¥wWo=ÂŒL½ëéâs§óém8É¼â¤™O1j³z»%¯Òf½i3?Ÿ®ÕĞ-{ ;?şõ?d-ù>ñfë&3…5æê8¤ cŠë¼_ÿ}~ušùMQ}'!ûi'Ê´—ª½™l•pÂğ>! ³¼+/â=9f lm~kÈ4höHCkø†ƒWğÔ¨Ëç¦GEµ“•’Ğ£ÂQ /W!©f*.ÎêtB¥ãã¹µ:¿õ¸Œæa£Pa:Ÿı`ñ™E@FÆì¯•­ÌZÉ¶…åV¶ğìÆ[j9~{Ø=ÑR£.õúàtÿeç8»Xcm›`iæZ²€İìëµÆ“ZCV†w¢cã³qÚ—ƒ0Á:Tİ¼ë¿ş{y£@7¼Å|qµk¢ÒàóiLV$â„QI3…ÏOÛ"¤Ç¹Dá<£ıë¿³İL…¡è‡è„y£g§EˆvX©¾ÜÉ¸[ö¶Ç¹ö¿†¿Á×µÿEË¯¼ıïÆæÒşkiÿ5ÇşëÎ`©ßÍŒ›öÇ†Çü™LŒÉªè«Øûò,qó
§èÓ=ºÆcÑú¬—ßıs–+<üä8\n•¸å¶luDAÇÕM¢q€ÉcXå-’Áå½h0Í½ãª?ÀKİEóÒ–«ÿD…N¹gõ»)®uâ8:Fh_Š#“şLZ&è¨ğğÏ);*Ù'ÒÛŸ9ò.ƒ~I 	ÍÊëL=%ı`©TnĞ“Ì$mêÏ93cåzj´ÒnfñîàÙcz&ÌLà÷õ[YÀÓ§„Š¥‚ÔæzG1k«İSøNÃ¨7ğÑæy€VçiÏßf1›ÜŠÕ›Ş YÔj5f¦¼¬]™o4lQ²ˆlr(&rÓz=¥><º§—p§.ãÖjcî™¨yø"‡`U¶Xp‚˜Di9›ËSÆÉ•ïEÌ«l”kñ]´Ø}‘wœv«cS:ÜŠ‰3*ŞÜ;Ï&êfJœïıy ¬* ÃÅJ‹att<¥ Á“®­ƒœÍåÕ)[E…lU$¾‚Ö~òvZ:f,êS}2éx"@TL¨ ^NÉC©Ö48lPİÔçšÃ1«ÆyoÑLÜf–ÁÊds!$6)Œ|
ûK°ãŒYZ‘±Ÿ0üÚõ¦èœ0lÙ—P3x;x:–p>ôåHØ£IÉ
ôo´+)ğÅ)•ŒÈÄÜqB?m ÷à5_™Ò³®T&ÖN†(ãšÎéÖX§xÓrUˆ!8u‹ç“ŸyÁ¤ÉefÂ/˜]-O-€m†‰ºÀ6ëÉŞL bÜPt†>‚~{ˆ'' ¾=ÆOQNÖUóÏ¤KıoÚ}„ÚàGÊ†r¬ÕŸJGÔ."¬{æÄÌ$TŠ³â@Ùzæ2/E>‘?ìÖF"ğ~û?€Øà#rë¼9ñµ™„‡¨¡9€G”ItˆíÀÎ¸¤˜a}ñMS!ü`QxzLÏ¢‚u§euªÄ…Dï”=zşÀa,‚Œ1:w`¯BØTUçÌ=àáÃÕ|Ú¼ùóNş&°‹å:(Æ;É-p`ÓmR¬È<§KÑÏ}äû‡ABÕ}‹}ï1c$˜{«ŠÚ¢ÌïËÂáÿ #6’TÈÛxè#®š*•8”rúvl@Û©ßy¶ƒl~ÓØTÄ°$Àëì.=Tm¿s'YºgK´‡œßú¶êß)6Qº^ºÛPÒğìÆgé‚¹Jš>ñ#¨–JÜq¯Xc•‡ pç’û9¡D:?6/Ü‡Ü/P­³Häá‡V’âR/èéÁÏÒ1-Á¹VÅ±0tXÓPfÑl ñ1‡So£¯“nÛO`øåùëiÚ@!¸6-AZÙv&’ë†HÄ{†Ô'R<)ƒ©8Šœ7–Uš¬²É*O²áŠxwÌÄØæHnß›øq7‰Ğîª¬éE¤¼˜I0ã©6ñÆ2@èBŒ„üÈ¹< ·+¦B-DP*÷tQÈ¨¿4}mD†ím\¥m¦šê‰Dö%&sê7˜Ù×µ=®KLÈ¤qhÜ²äÅ2Mæz÷"I.QG±ŸšF™FÉÖS%ÂÙzšÅ‹1Ûik€†£’å¥VfZÈM­ìTğìÆ¶ÊˆÙ[$Y..lf`Û¯ÌÛ	S:£Ëc%dvE¾™Ä,V%ßGiÁNÈ:¢i‰`ã~Ñ^¨Nğ¦»Ù­)/ƒÚeÁ=×(Íì‹œé2WŒøÿÛ^.ÑOs]øE„–UcjÚ¬%ù	ºt­>¨üéÏCoì_"„Ğ•7F	LST{ùÊ ïÈ)†’Ê·È•ÚzU{FAR•/ÄÜ5–ç±x	M|’	2|h2b%åï¡ÑÀQ$XÄMVÌ•ÅÅm‰Xåú±×wşúÿZ}öãú­cş~2÷?Æã§ÿÄ/ï¾Öü À¯¦“ÚhğuğÖ7`¾3óÿxcóÉòşï«Üÿ™@]œzÇy>yá”ğ¶ì¹?za¡øİó:¼¡kiçÉáE•\ßú$ƒ FªÙc«Ê=KŞÕ¯‘2Ÿõ	˜‹=÷Ø»È¿HéPu‡eÖ‚Ğ}±/~<¯{/jŒ9sZäõûş$‰YROLšv<Ïd3ñ´Øù4áàÏc8å/_T«Ïëâ+jÁÜ¾¼aÍy^‡q:Èü K4T
Q8b­­zè´Z-1 ²’“³Œ‚¶T Ï$ò_”ğz–ô,^vÎ:ˆ¨¡›©ºŸƒˆô¢?§“Ú!-J,YÂÑ×4ú–†YñÜb8f4C¼À‰BYQ;fØ6¥¥aA‹:QU÷Ğ|Şy2!Ük/¤¢ƒH"ÑÖ}¢öd®*UP’ÇqsŒ”Ñµ³”fDQ×¤4Ç¹Ãœhüı¦§dŸ‘Á6L÷0:éeŸa'Ä™Û?-?ÿ?BşJÿrg€;ÈÿO7šKùÿ+Ï¿Îò¾æüo¬odåÿÍõ%şÛ×™ÿ3%¿	º1¢²ÚÀ¬|k
îÏ˜‹fu¬=½dg.#T©&ü¥Y¦ÑÁ¥ï:µî·ì ½ßqLSİ3•4	3›9eéîuw»ÙšóÈÑP1ûÛ³‹—ü¦ğìâøGúyx„?»øs0'œhKdMÃË¥4™,ˆuú¦Õ(ÌªtëªUgÕ3.sæŸpÕ ñ<•Çš:ÚxNÖİÔ»N÷Õñ.5Ö1vtVCÛ<°‡Á˜G·~4ŞƒLptòç‘KGx&ËZ7?RFüÄƒeHiÓ¦ÂÕYU7HRÚØ'oXö¹ÃRCÅø:™ñbBŸË„ôM‰Åè;™¡d¬¤’C‹t7šë8ƒ<VšmÓ¯çƒË¨*2¦';	|¬'3¦Óx`èyø|É	…\ÉI¹J}?K˜º0KÆÍ1ä°™*FşÇ_~y+üÈd“¤˜Ší‘]#qp›}ùETz*Lõ©kÂ@ß¶X-úÕE,ôYó%ÇNcNqĞñÛ@am(@(‚7¾a„Û#îû3Kt•Á‘1úátœ0/VªÜ5Şz¨÷*Ø²®u‰`k´ÅšÒl­ÈGƒ‡]g—›k¡Í†Ş½£´™xäQ÷0)]í3ôe~Äb¾C3(<"cÌ³pÌWÛéÉ·‡ÇNšou@za¯ñ/ïÂdç"„Zs–çÿVòè­ô•±÷ı)Ğÿ>ndñ7?İXÊ_Gÿ+7MØjÂqÈ°æ×É†
÷Öc		$À†i8Ê-Îyé-±‘4 ¤ •ñ½I_Êíîã-§ô<ÂËÒóağâÕC6Ó›B¯q]¶0%éiP)‚8}ÌÃµ-9U²†–ÆYŸä|„IZOn5u(@Ø´ŸY j«¹ï#¶^‡¡7`ióï¡­­Îo1ì}„	õâ~ËÃpq¡0j¼SÏë0WbÊŞ„HvûEˆzêÃ‰?Fò£†gåÚŞé˜³jnšÒK”ô¼³€N^Ñ˜"ÁÛëàmzğl¿¨¾9«nÓŸóŞ5íó*û½Ué³ÚwŸºò™õˆj¤8ËU¹÷¨æı=”à‹lUl©ô•®Òıb®Ö»ˆöRtwÅyı§•ÿd,`8høñıJså¿ÍÇ9ıßÆòşÿ÷¸ÿ?ætÀĞ>¶‰Ááy…è<¤ûókvá{	ùÃâ–r>	ñbjsE¹¬
^ù£s¨¡ùä#×\1¶äƒÎ]ƒóNÕ2—Kï –Âjëë·Mp0°:ÆMá„eÇVÕ_HıAcì íİÓ>2Pç”tÄ¶æØCÍØjyãxâE¨TP&‡¨fEŒ­x:™7 9ˆë±û ¼6'cí`H"u÷Ø>:©£/LÊV‡aÿ=#÷½$îtÂ%8„¢è4(³¾BŸ'ŒÈÚç‘Î¢LböòFƒuµÆÇ7ş4¦-) ’<Óós|Ğé˜‡]÷@‚'4!p 8èøR÷@ƒLûH@z)¯§´MñKÛŠH}©Eµáe×ô¬rŒ8_œQZå;OcØ$¾ŠèüJ_’¿!Ê$¯wÿÚÙ) SŠ©A†T´r’A½ï_\r©˜vdñç"G;¯ƒ@uÒ›'É=§IÃÓ'-‘@>¨%!0Ó’lÂ’<nÀ]’ğ…ù¬h]Îê°¶øN÷ôËU×^ânÚøÓÖ?R(”R[/ZÂ›İj]	)ÎšÏl‰¸G+íçŒãÃë©ş†A+Ç°C<·HÜi~¸x6LJbOótI§éò(5Ò±:õ(™LjiI}—"IëdqÌ Õ+Ôƒ‰ÕÁ¢¿çdÄWŒTŸ/‡ìxçg´¡Íè'ŠY¥V¬éíã3òZ¡©AM””	8º=>832P$Æª`iˆxõ´.æûvù 6K>ğšú~ñjo—í#ß»ôãìÀgí>‚¿ ºƒIÏfÇêlfPôíIG›ÆYŸhÛ<kìN¥Ó”DØhafhß»au&…Sî’AmÂ”­Ë/›6 =Lİˆñ’ÜöòqKwò>ÄXìÆøïéXíû¢ :øˆ·£ /1|;¡F#£–ÿ<‡ôşÿ¾¥şÅåÿ'OŸfäÿfóé2şçWù<|øÍø<lëÿëâÖjc?dÚÅ?ËçÉÿoˆ¯Ò$`‘Œ,SÿÃ‡óğ!šÀ7ä*R	AÚ S1a^ÏÍ03ep•gfJÃƒùe¢1Îz)¾U’;]¿*ÎócúFÜÆ¦¯nUîçåVwğ¶†)-_á+¹›©›ÿÑ
Ñu–¶J]“-^Èç»™_Í8©J›cñ¹O‹‰ŒÉméŸc4!;!®ï3°iñÜ2fYü'AJó—Aèi
ì3f”!§E€4(#˜šs`¡M	Y`äQT’Šyš–L jÍH-n¡ù[+ }Ã"ä¶Ù­FlvàZÇ´!Ì¨€…%IÚ7Óe`b>–¦&Eíş,›f"K9YqÌ?i§"»(2¦CpÏ&+v’ëò1*ÙyChX¹õdvîÂşK#;µ¢YL–Ã¡š=ÓM®¿¿¥íŒ0Ö3óÌg„f)_ñßÂ)ë{cQŞ u_=öô£}/s¶7KÖ/5É“½Œ€xk©Éœû’ÿCè5FtÄÉ‰«¨äıšş›YıÿãææúRşÿ:úÿÃ„–
M=l±ÿ:õ#
T³²<ÄŸGxûˆ¸D†|¤VÊ7¯‘ïóÅs‡á5#(-¥‚bèò%7¿åîºÊ( áoi]0#‚[%±A!“¬A¢8ñ¸ïÅ|â|[‡úq§½³ß²w•ş˜?ÒôÁh
Aè A?€"nR¸Cı*¯º¥fëä–Ê¨FÆ£‘áÚ®ı¨3 ÷¥Cÿ9›ÙÑŠ‘…(#TÊ³¶~Ç{(Z*iY³JºITnş4x_}V…ÿS°—0b¢¤Fã×ÿÈ¤m4ŒÄFı¨R;â*µ.÷]°!“¾*ñ×g¿şÃ(ö”T.¢IŒL„É¢]Å€doßàŞyy}¨	ÙÅFÁo/ô½”Ø?MR@÷Á£  Â‚ ÍJ»ÉJllæq8Dœxó'f9İØ¬¾c]ğÑî¼7Ñ$f­mò¸*Ñg…Ğ¡şt…nïê€ŠºJ“¥©¡–MbÚiy¥éï»L?0TÅ©nTÑ¬O1Aj„›‹-Qª?(*ä„”E©õĞaÎ·(œ§&fŠ¨A@zspZ¢±*é¦PìèĞFÇLt'³›öfÜØnâ$¨ŠÆûıi3«GĞ‘±sê\¬,Œœó£2ßguH_‡™!âò°Ú «‡¾Rç¥iC¶Q¯Š†xuÛÆ3sÕVoò¦YZAÑh†ØM¬–F²ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?àÏÿ#+h  