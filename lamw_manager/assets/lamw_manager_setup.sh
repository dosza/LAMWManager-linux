#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1367021318"
MD5="90b7f16d84cd1ea0ef6f74e37ec54dc1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22976"
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
	echo Date of packaging: Thu Jul 29 03:00:13 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿY}] ¼}•À1Dd]‡Á›PætİD÷¹ü3È+güDZ¨Î\;Â÷Xd¿Š”“®›k|š[Nı’Âİy8Jæh¢a]Rİß?.&:åt¨ö?IZº~çƒn‹øó¨gt	;ÿy¥$¯qõ*Øş0[-ÚE’‚“¢¼É
Ûbi~íàPëX}/“nÃïµ¦¦8v'¯´Ä"„?=P c©[VSêÆfQ•øş”@+ĞzŞZKÔo@!\ƒZ;¼+)n€˜­F[ñ¿Ä§µĞ—ï\wJïzšğOî@VğW;¹?¸L ¿¾}àâ'ØÀ›m5z¯ÛTáòÖ3ÉBĞ0Î åØf­/Ša«œ–¨Ğsv‚¤”UÌY@Pô7exƒÚA+{*\43ƒÙI‡=åÇW?Åë=ñãã^=Ÿñ*ªîZV›CHiy§óÂÁ­Ÿ¡æƒ×Á¢7¿ËÇôÓÅl¬8Û³°C`›îsâALtÍ:ÁIT¶mÇ´äÎ AÃEzˆ“‰·Ã+İ”N¡“P´­F«Í>RÈÿTE³ü¿e%»¤ RY«‚#–¯§Wúô5W¹ÚŸ9ğXí£’À"qnÔ´D»úkaÁ‹};®zŒÄ\‡]ºH¡PS^Ï«òm0?o"¤ZÂ»uWí—ÕuHL_7‹(öÛp¨eäÅñå›©xÎucTù›Õ2‚@? P«1³º«·ßzüRƒ2´Ÿè÷ÀÀ°0_åîÔ¹|
2şğ-{ÁÈ6¾i„#Y³Js\I·‡ñc°{DË"µä²ö°¬O‚ï]/!À!¿3ÓQËãøÊMqJX“b;Iúj]××ôD“ ¶ò £ŸÓ¹²0v"·ú?'Å÷™Ùá«­L.ÜóëI|¾ScQÜè›Øû+NB[°$¨rG´öÊ‹O¬JÚ8¼¡F¼~¹ÌC[Jèq@>ÆÛŸö¸¤C+nÈ]í¶ äÌOê6@›‡êš p„èå\ôtdw ¶_6¢ôP?„é{Ã~Úç‡
Š%KgcÑw¡í[kØ~ÒW#üyå\½» a­ÏWÅ9,ÏG2 ù§7ªmûÏÕnÏwn79quØeípÅ}¹ûA%ÍÌşç·E\…{DÔË{nqã*BkÉàŒéO ìq¯ı†æa”\,M&h®'ÉC…=0©4úfX÷¬K=&óÈEñ3âú™½ÆÉÏ\wPä)Sè³¡ıCÍ^2Ü_
gEÔºp6+Ë¡˜še ¨M}eFrêœ¿‰$ût7vÔÕË²½7}ºB å“ågA^ 'ÄæşˆG#ÎE®¨Íñz,@l¯M¡ QnZíü1Wq^³îÈS§2[¡Şşõ%Q²nA„…xÆ$¸2Ò³*_ÉMÏÓ­Hü`8&Û…é‹­Ã‹ÇÅ°1«»“X'`á7×ÉıüH zşôruC
¥s©èWü1ğOÓMhnoª,„ö×iáÒœ˜K/àì®_¤fB*`/ÈÙ*óÏ¢¤“>Øú<l/Ñ[Dq@¸³¥ıd7Æ„Òõ»à)ºm“:T—scSÈNŒµÒ‹ŠxÌµZà`ìŠ–r©Û°=ç˜–fŸĞ*U8±İ7/Œ\ò9â²Â˜¯Ô È„‡î°ı@:Ôº¥ña/d‰"Œ†¯-xæ»WªíjgÂñÔƒD3oÊ\Î"*PI#fÏ×²N¨Ş‚s²H*¢|ƒùË¨÷Ğ%_ğ‚6dçoÄí@ş‚70İR©qÖ~bT^@®}z&Šêrl± mù%¯äÆ»]˜áb'«¡-çñÂmÃQ´ºäÀ"¾­¬¶”K‹cí€0–~L¶ypÍI«qúÀ$åG¢"½­?ƒx·ÙêøÄtg¡<×\‘—L´U[¥Ù{&Q­9wV€|vi°«Ÿ˜É´M@qÛèøœ`™‘…”Û	æhLoÚé…kPÉOPQNâ1U#œ;°zê~^G˜ˆB?nìLË5«ÈxKi¿Sj³Á—…ö¸p ’ŞzœÜœsADÖ$yA#eşş¡³ˆÂFğşfâúy«®öFL -Æû·f(ø¸E0ƒåçø]+Á˜€ÌÂúÒLÔd#6g&/‹Ü@&Û!‹Qfì~Dd–…àLŸUpàôº ZçãØõæÁİ;"nrIÏ$b†©İ€¬õ_ûôŸ‚›qı?q°—„ç¦úşWµÚ :£;éâŠŸæi‹špF
\w‡©Í/hî‰¯U*B•¶a9•¾Â*n˜Ó˜ÖéU˜Ùÿèµ¤öCˆ€I;®ëLA¾ß^`yÓ­Ã4§14,ä£:Q1ÓL»€$wÌ@nQ'½|°gfÖÑ¥3àí2f/”ı€(\¾4Øü4K¿Ã •Ÿ¦j´J«ŸT/BŒã˜(¡ExîP@j!JÀx Ûá&GïE…ü•MŠcÓúU°3šHh6ièUÎİŠQH‘Æü">I47”ûnuÊ½¦ ¾¦ïÈ˜W©à1'õGÚpŒÊ1ÎˆŞvãD>Ô]‡rô‚€«&G;¨¦ï`êı†y}KÔxdwdcÜonƒíO…ıF%ïñ÷c?=‰\½OÔPÃ©GcöHúŞz6.«`0FeÀ]æ¦
¸P·Ñ83	ŸK&ÙşÍˆ£,¬wû°İ Võr!dÒ…Éäú¨} ,ÜÁˆİîr°,Æ«‰”Ë}‰Ÿ*Y¤ÀUŒ8¸€o”ü*É$‹Ç%F%Òw‘»î†)¬âù~l¶şyQJÃ§ÊÚQÅ“—ÿnğgyiœ†wÅ»;røX.ÏíÓkùM›2±÷¯—Ü&º8Ëf-iú;O\ºHú„,oæ2¥±_’š}­–.Ú½0+÷œAğÖ¼]F¯›‡ey¥ş÷úd”U“ºQò°ÒºÜ-<&ñ€”—‹%˜xÙ²ê¼|]/bº/ŠÛ—5½ë›pùë"7«„FäëšÉ•Lu• °©|œÄ±ê1‹á'ÆÄ²¬ğÓê÷~1KÇ²‚Ğk©>
K,†\Š#fÒiS-QŠì§yâÌÃÇŸÓ”Ô™^á¼P—MÅ¯²yÁ{Ó˜„Y†#¾5-Á0vÍ@°|)7€ËsşFåÖèIÆã‘næ4‘ĞVãX˜06QçÇ&„D°3Øâ¿_°—Éh“®}á´W/â%¨‹î¾Rg‚õß >hÆnÔëyHó_¾¢Lƒ¢àÓ$â‚…	F[Òƒ?+/AQùú Ì%>"/,’)@sL£$¯I¾É,»'¦ª90Ñ‘‘]º¡SFz®ÁPl0ìØ@UÕï0¬§w«Hû-9Oµné|øhİ÷A<q“·P][B’—qaŞj"MX«}7¯¬ø.4+]%"„È.U‰ïÜÿ(qÆ*@Ë9w¢ŒE0íÓèÌ?+µ‘b;´®+;pÉŸŒ”ëö°@X)ßƒ.½©Æà˜@¸ÅT·ïØºßÑ¿ë­óˆ¶l"İéY:³-]•“>ÂóÜéøíd´½äIX:E?kHmÖ¤7&¾P]G&r*ÿvd‡åókÁ `HÇÿ·ëÙËµÿ,!Ü¨7$Ü˜L
Ù«i+¨?)¹~èì*)A;ØèÎQ¢—…b.šZ˜¥%÷(…ÈÅ?½QœÒ8!nÓ>ÇDà@óÀ·Ù·íî@bÊQõz"#‡ñ¦–)•îN‰k2­×ß\‚§ìû?ÃÎ|%”Èîßuñèâë$B<®‰îmr›Kó¢Ø‚‚£ÑOé¨ÕÖ7ñùvÄÅ†è:Ÿ|ùRğQ¾ö»zUÜšÓ4¦2Ÿ{=Æ«3îÇğ{Á°iÛv`Z#h]…dZÌß”¢Rä£"	Å`É§2õå5Ä7È’"ÁŒY1~ÿÒi RD ­¨Óˆš0*yş–IRoÒE¶5s¼MIhşÒ‹„ƒö"…S°£ø€LßÎ4‘qƒtÈ‘¹ã­¹w…vm½cŒÃ…F]=-{µü¿/¦ğÚä^ö(1eµ	°‡š82^jÙ©§	§C#Pw˜…”€†¹E×¨2¢¡€d¦ä”ˆãÍ¨XE{A˜ æ>¬Ê#­f#b±­ì• ¢¸GÃ²ìHíêõ ˆ:ÙUÁD_R1Ó¾›z)f‘—.ş ¨œeRÜ!ÌĞe0ÕPeü$sr6bû…~ñNÒ´x¸æ.W€sUÌè…ê—í÷ös˜íèÔŒWHYÃÏÏğ¸õNÙ™€í/FŠB»D±1h4“ûç4¡‚-¡1¾Õ±‡¿ï„€}·G»b­šQu`5³ÀŒÁëêëàg{Z18QàPmªaÎvÑ×zsÍU@p¯Ì™¥uÀÌ¿+mB¼–^¥Ä‘€„Ô¾Ì¹ÛS%ˆívåò±ü|&™3½m¹r• 'hmƒ"ìºŞuùô^8²Ú!	ñæo3“ßÿÍèçá.ÑonáA¬„«fÇçŞxª€Ti½DEÈí6>ÎzäMÛ(ÒwŞKTæı»Ï£ØSÕ,$†RìqÕ¦6·¢IÏÑ±z#ºƒ>"š•ş˜ÆÕœeïRÄ¦$Ilš1Í¾ÍİùX¦-­ïÑO|™3b4Š!,ÑÖ/HĞbÏË›ga¥1òêÆêcpª~9Y+‹“D{HÌ½+:Ğ*örÜ¨*Ê{m×k]$K§Tàø0D}f¦p9•£`èy}¸×b‘ü®VÎöõò'"¥‚¶8[ÜRi9—ïİ¼)bŞ<@T7Ï‡}OC?™…1yÍ©Y¦›=³/›:õÕ8–©		î~ö4CP·ÀÓPİùs_P'F#GÆ“c7aäe´)±÷¶.Zşüg/*¥yø¼·ëOÖ$ÃĞšûi]€-“àë–‰Ñ0G\;á	²05SM;j©…y—]“År%¸j+ÄşoCh¸³/9ÎAdÔ…ç™äSå×ï‰O»ŞW[›QYû£v‹4vã]ñùC;dQûuøQmï=kÛÛ{iø´xà>ıoÃÖréü9[¡¨­}Ü§\Â¸áóòı6ù
wÅıƒT_–¬=×b÷WLE‡™ œË£ÌİÀ£g)8?^½ŸTÆƒI`ÁX•kÀ«ö	+>1©­w^3çêÍ.óS×‘§¨és{cãH¡^O¬ÄwWšO°Œ«ÚhÚ]6:‘¢8­İó[aÀJZJà¤â±?ºü±(ó¿Z,nàî‘[íú±¨c¥ÏØÍ6RUßkŸµúîP]ıì¥œæµ“Ê\¯u»)×éè*ö9<”å°”«Oµi¤¦¶BÇ„K+€}`úÆz¯3Ñ;ÛßKyW‡#‡¥ÒÉÇÎ°hØ1ñ‚Qˆ¶>¶Pa^vûCrºÄ,{¦;(Du—„Ó£È|yÏàÃ–Ø	ÄGLb 5(ô]‚}¨¼À$ö¦Ë#OÏ3L[ÔÔöTã˜ìy+#)†ŞB‡ô¬ºäÄ€XÎ®-*7|y±AmñÜjQûlÂ@»^:kÛmºÔ/f89ê'êşƒZ%bõÑaÅÀ‡¨Í+åå
2¼\Ä‘^ >¶ìÊ7ÿÃrÑËJğ/ßwI¬Ô†¢€XK¯¡?É¶Í7âS3-×<t8IK§éTıd1ç{ßYÚÈÕ‡o¦HÓaYiiİé±?aÉÊ&GƒäÌV‚uºÔ.BÒlH»Í¿vñ æÏó::ğ Ûú 6Kèù«.oÆ/ÿlÖ!ğt¤ë0g»«œß4ªÂÛBM‰ô2Ór¿(7œV–ĞE˜ìP|¥‘hŸö=85àç"Baãš”²®*?7š£”îs¡n/$Rà{ôC‘âË,ådP×¡\IØP_oê$ş{MÆûÚØUØ`Ó’
HFìJÜN'pœ)aÃÑ-Xà ws†Ú®£uF.Ş0á…vi´Ô0)¡Í£ABih-”i|œQı¾ÊMm^&è
OMp·=ûx1!æ)È:é#âÓp*,-«¢ó›\]¯3¤%ñé<›Š85±êôÔÃr{äLİ°î I0~I£3Ä‡{Ş´ĞÊR>_Â<Àµ„&·-NfíX‘¦Ÿ ‘Bó2¿"È½@“šŒ5Ï,ª[cÆm²lÃTùkùÔÒ»ö}ºË~zGÏ¦÷¡qkXvKx³ÃY]y=ûKªªH™ÄsÊ:ŠNÈ-]2 ïO‡òzœÓ)S¸CˆÆ«şSp7€Ø½,‚:oÍg™¨ùË‡_{yğ°tS¢ğçœÂ0Ï°`Æ`Çp L†n31.Q„Ş^ÍÃÜê 5GÒŸ·ó†—ìJƒ€©†€s1AöÒãi¤2}i×ÉWû•”!ŠZë ½È@ğÿÑnššv¢°¯—n»UF7°fŞ¢±RëŠAÄ&,	@×)º«Ê˜7‹àµ1½	§ep#W¡Åå³lªD&ŠÖ¸ûk5%9#Çu¿½ñ~ob±$¦ °nˆ1ç¿#Ç‰y.·9±zFâu‘	RûxÏÁ6åÆı¨×ÄF­¼±Mpvñ’'mçÅ™ı?íŠ$?ˆZHÇ€×’ğ/QHúÆŞ¤ÿËâQ—º³™C_È$eìêL‘¿5(!š@fÔH§Kë4·¶
t'õÌ8ğã`óàXp¼y9'^y§1«æĞ—í‰*Ã`§7ÏtPj§Ë·~ït¹—Ñ6.Ş&š¶™ËòÒQzá6ƒ8ûBãª2Â•&7UN½&i·Œ>'ÔŒ'@ÖÚ^÷Iü,;úúb[¯&Â;TïaÍÇëR›8#/ÀÏì'ä^+]8\mÒB:cæ˜|œl±Óz<v®j¥Tÿºµ“÷°Ç2˜ÀøÄ$Ã~'–ï·š™mj$`z×¤÷ÀG*¤¢fÅY­á6«MÒ—¹q¥Cİ^qÂÕ²CÆ±Yßµ”Èb#!MVDáq…§¦ÍÁW®UªÇËÕ»ã×=w›mÑ§Ãïã¾ÿûM:”PgÇ@DÌ9zEêé¥Ç‹/½*'„¸}C³Û,–á5 ”[T/aEA\òª'"M'pÜü¤
ÇòsFèÍßN;òçbÏfˆ‡à·#å©ßI^äñçÜ¯²*2!£T0´~EdQ×¾‘íÆ½	­6dI‡#W`‰ïMzŞhü,š~¼óã`"<NÎÈ)çà²ˆD2ÿZ‚·˜/ßôœüTZ¢	>
õe¥°ÛŒ×§¢úC&>—»{İ›¦fÑmıüj>`;,Ú#Äø/\²Q\¾=uáHÖ3h° ²=)“ùX23™:Ö\×É˜kÕyÕï`ÔiøOŒ¨S×åQ 5(ê¦Q_*CD®DàÒÆ[ß>8oŒ7Y¤Å·Cø8äj²(7ŞAãcùÜò‘Îé8/¡…­ÊQ7ñ¶†C„n|>Ñ•³ÍpYã²(ò—¨r7Mw©—şì|ı‰ÌÁÙÓ³¥GáÚ¢Hãêaswfí<Nzİ,¸¶ç~5E£0“ÏÖ36nN¤’ í—quÊ¼Ïxl@×mLË¾Z¬A‘H¾å|¹Ø/Ò\íŒKÖıgïÛTêäàê÷zİŸë§}†ÔÌâ<äO_øxû°Æüì55ş‡m\%[»ÚÜ>söªàzéŠİ¸”àiÉ8Â4ZÓö™ï
@¥aWó’-¼K}KÕQ"ó+¢-éùN95øŠÈ–ŸÜx°#é?ŸP{À+—Eqvÿ6¨²–úUÃë‹®áÖ€Uu/öü.Äyˆ#

Íõ®Ÿ‚÷Æ¾««Òä"~ı˜‰¿ímŠM†lÑV•l˜Ô0-e˜À€§ñËr» b'wjš
2h_ßIh,ºœ`yİ}•BmCÄ¶6LOÔÙ°ô_¤Skº¯#µä¯ _!£ĞµŠ	[û¶¾FC‡=	‡/Wßö,¶.ıJ™BÃîĞÚ„¿0kÑ:á ¹éCşöi»K¿{WmáÌ¿†+)e#š µÎ!tv"· ˆù.ÚĞ¿|ØŠKí¬ò¹:qğÆÕ›‚w ï NØs,{¾¼²-6©æ&vüËiÍà
óÒD˜"ºĞ»n‡QuâDPF«şSLĞºm‹X  ã›;»8~%ï–Zşà€‘a‹_°a}‘qLdEQ<êf¬`ßıÍ>‹LÎÕÅ£Í` c®;#9ZÌ ü7á˜Ø‹Æ±ªš’o}Ë"Ò®ÃXà¾¢vFXîä“Î*hÉ2š†¶¬¿f×ÁR7ˆ'’}¬ôÿX‡£g39gµ®Úªî!Ö4êÀ¦¶LLĞMâ-·£~Ì;`‚öÛšS<*NÓA”ïÍJÁ4áğëf>ª‹÷(I@yï4¦Y
{&q$p×²´n ¨©¬£ZõYpm¸@¶É²JÒlØ:Û[C‚;caB.¸±ş#İ¤®ÆUTy2´~Í®ycçÉÌoÎ­¸$å?8Ç/¨|È"XºĞ—!—Z]…ç(F¼ãŠ^ĞbÈáºâ.rÍJö2/ÕEeİ£¡C8c©ßsÃÈõ™£xÇg”@ª3ğïÛ‰hT8–ñ²4(ë©õ«öW©š4ãğ[©İÉÊ‹(;œEŒX~‡mÿ¡~K
Ì½	Ï$Pà@Õ¢ªßÌ9Ææ½‚“ÏÃNÈZÀÜ*çh/Í3pL‘6Òœ·u}äçŸÇòX§«J*şÒ7¸_7kğşïäXèÆ8»<"c%0v¶6Ùò( Ñ°`Ì ğó;ŸŸ“Ò­HRL,"ıÿ“Â/cà=ÙC¸|¯Ş¸Lá1£0HFÃ‘ÀQ
ˆ¢z0UR œ“†×dY{±o%¦ìä®8N)Ä"¬µS€
vEV³³ ~Ë·f9¾›õèIîƒvJ0ØS¤!½©æßaÊ¤mÍÔöŞ~«•Tr<Èëoõıu ÉÁYè§D”3t¾R•Ø7C?¸Óè\R¾¯=Ã¥ zòÊ§¦nø/OAŸÇaÂBCN¤_&œ´q&ÀŸÏŒû\*<ø(ÖöRRh÷Æ”cb	«Y½ß¸/Dö>Ïu¡Ğğ¢p¢qÛŞL™”ÀGeğF,·’‚ÔónÔB1fÂş|„zÈÒ¼5¹º§ÔËõ-^„/ƒë›˜ËÖoøzS "ÆÄQÆ0ôóëŠ(’yŸüÖ ÛØÔ„1‡+IÅÜDTh½¾Ïv‹„’rÒé2ğ¼_´^së§“+§‘8Î˜:d4D6ˆmA›c?sßŒÓ^ÀDãÀvÍÎÊt­1¦Q=Şmê¾!ë#Ï×±[ùüæ ¶â‹@©Hæ»Ó¼{iŠ
gPoÏ÷) fp¯NÜŠË&f(1MOÍ3„ôFÓ~®'Iqı ´4áÔ&º…üo‚à¨üdo(²u‰Ú9”O)¦½TÆ¶IŠ.º`§TÎ8$æÜÚÏ&”÷ïŠÄw:FÛH9±ÎM`˜§2óıÙ5ı'“„&à@ö£úßv³DtévÂásLQ,6µóó¯„7ªp)Oi)¯€æÁˆêœk›?]Ö'‡İ²÷Z:ıXÇúD¡·¾–>é·¶ß7±À€ÉywHâ[&) ·›maVeÛì›ë€ûzØì*íçÅ–Q`—["§N5z·Ç­PH-”œY¡ìw#
µP:Œ“U°wL¦‚¯÷‹Œ¯­\@l€s@½á®¾–Âê/¬	jÏÉ²J­†i$Ü(Ş<Öï”ûqípjÁÁVj2»YÚşÙÚ½ù]Aõ\«{uÚ×mb/T¯	›œ´~dy>›¯îumÊhh´ëĞ4‚Ş*DÖMüå:İòÌÄŒp8–òÍß0ÇæTë—±!ÏúÀÂ1Ì{éÍÅå«"x™$9Õäğ‚>_BÈ²£
Õãë·e#*ì¯ŒÓWGüÒ+¨İkûîµZÒE>iè«»~^DTî.ÀÁ²^êª¨}*ïÍ×u[u#øêĞŸÒí]ã*Şï1€ DğDš±TX’™nR×ÿgU3(ÚpÃ,üÿ­Fÿ™öÑÖMä°tí¬bu´È<×$ÂúÓDy7p}·Šœ3‡DùŠ“È¥nBÙ¶»*n/øo4­·‚znî^Ç{üT%<ÖÆ«ÙR€æ¢†Õ—[Dƒ8‹Ã@¸’˜ßèú3(ôQjKõ×¸Ôm’S0ÓQ©Iº#¡Ñçë3_c”‘Ô“ÿºë¶şNŠÕ¶ÈJ+‡}7Ñ‚ùµ{­8O}ÖÆJû&xtÂ«2é÷,PÑ|ûIˆ¹²äù¡Ë¤jÛ!ì¯1>Õ6s†s¾Ì],ÊÇ €J©[#Ö´?Fó—JŞ¨@'À§9XˆF^u¿*Î­˜ş&DõÄy„¥³øHÈ«äĞÖj}ˆ^¯+ë2%û—­zµgb|‚_D0Ipg¸¹:Y'DŒ ×÷…&Ÿoë­Ü@¹TòªÒù@NGŸPaÓXßÁ¤öDjÁW¤Bl«d¼î·¸áÔ£DóÎùÃÈÓ ›ŠÅ+Ã˜Ğ8ƒNâ,3IHõäNÔşÛ	dr×-š½PX9ïIO²e‘q íã÷ÖZÎ¥Æf—ã†˜¦ß@òDé™EY/Qì6a2Š„‹û}IÈ®—©ÕÚœ~(y÷aÑÇ}®ãQ¡‰¶utâ §–6Íˆ{nÖÁ{Ñ}Ã:éå)Cwkj3MR†´ı@iW­Y$ÒŠ]8Eª¼z†ÎmMMÔfÕÛF6xsË?káhts³a»(õha¹ù})sâ$ú®ŠAı@zkPHË»êo%€_CF6·b—í¿|âÒ¾ÄâVçKƒãÊÆŠ•ä‰bQÂôûÇÚü~iÈAÎƒ'^Ú+µÑ½<*Œí…^Ö®Î’Ë^u­÷È2¨å–ºÉ:'ß§uêq¸.Ğxˆ&<]HFõ?LÁ41lË%h,á<·CùVüY×õ–SÖ·íô\.±i®\ºSàÇåŒİË/Ú#ß8“¢´†²°õDĞŸµí¾ÚïĞ’âøÈ.kª™R$¢¢y2Èşr¡naC§@ÃÇQqÙwB y>DÅ”^'åøÃna›–ÃÅø¯Nd¼ç$ÔßùÕÁ¥w Xÿ1Ï¹<ÆJÆ,ï;cr‹BO#m<*|vU÷;éC©çeÓ‡	}5hq:à%zúåêŒÓœ0¦Moáp×õßÚj¸õ0¡º×ç
WİfÿÈqÆ~=‘xn9’òŠ9ƒÌß´‚%¥gmÈH¦›€ûPßºG	,™şd÷D¯››€lqwß!›^ÌXUŒÃ‹òÔó¥³ıÓ0f¶j›+á}ÖºÂµ)¡¦SÙµ
¿UÍGM(
	"ê\¹qhSÀu¦m”cp®C-÷RWœ*Ê¤
ØöÀ?ÆôÚCÿºÓ¼%Mh)"`ÆÄJ¿‰”e»˜H, ?2#·—Sâ‡Á~¤ ÅÉ™ÍëØÇ†èl¹ìº»µé9VòÑQøÌ§òÏ$*‚K¸OòãñÚ²Nî{™í60„a¶w c¦4ZƒÇ1]^õÌvxØÆ2O(¢^SÄºœ}?o
O½J©©´yq«/…ï²âtò€1°
Qn7×AZ`ÿ›"Û°6üµ×ÙÑI±‹°Z6`Ø?4wBÛ¨Oã‚÷;+wÄùyAd€»Z›ìç\uTvºñ¥ÕgzØ°]`ïGsî47÷ò¶mI•>¯´İg{J3!bU«Å*ÀL¿è?)ìğNåÎ‘$Bå´Šµuu,§—o¨"wEVÉO¥Ğd¢š <DÆº¨,[^¯‚_ƒcëêµÏöàá[¢»w°j/044/ƒn[[é{&íWR¹zÜ¢‡¼É™Pf1 "¢·7ps‹U½-C»@ıa÷G¶)rşƒ‰ã5u¬âG6š)Yñ°ù"¹ÃcV^ì+×="ƒwæMÍD<*Ræ¦R²‡m9‘ÄTÌÔÀ3WA®?œ<|+¬§Êš²Z¸~¨t£sHBêşU‡³bøJş­p
«…ƒæ»&C…ŠUYJúÌÒglNı®]Ü‹Ã¥FÖ|0mòˆC+ğR]w¬éÀR÷=Ê[^'I‰ã0\ Ì9gï”äÔ–|up³\÷Ê8¯¿]í„“,4ã->RSc7_TNXpX %Ø3Œ7b¡˜ÙaU­´›«=‡»mÈ|=#^îDî)†ÇşÚ
2\Î¥·ÎÜÀBáä„¥¿g3X›¡+cüÑ‚`Î‚;¶}q¤ÆB3îDáEÊÚHÎìSVôÄ]I›6Jx×ØÖGGğm"lŒâÉQ hè7Ö=Ç‡İÅèRt$UäKÅñSJ ÎÌëdäøş]-ûæ´
=¿¾‹ñwÎ6×b, ùÜcP-N„–1"V&Tˆ­¸E$²Õ¨ƒÃJÓÕç’~ùU×Â³‘DìÖÏwƒİâ¶NË8­(!P¢ìûŞM¯´TŒ^Æà©å$©*‡%]¨ÛTìJ8XªT†9<*óÄ4:‡Ï—@ÉbeÍy8û +nYyTé[	®kÔÚø¾fèWÅíÁ(ğ¡Àæaî³W[,ÁÈ¦H˜ ™Ÿc;ß¦}^Ó¨Œ“ZëŸ&Ş¬F×¦D‰µ™ºE{/CÀı[WÏFb·¼¦©:FFFâ{Qü0X¬5lÛpõèS)`Ãˆ'^~g}ÀŞ¶Ér˜œéIÜ”!Ö!”˜ Ä«Yk6a±Òn 6®Û	ğê”ÅJ37bG.Üõ]Ÿ
:xy¾5ã‚iù Ìæ2°Œç|w½‚éØ”Æz;=Œ*Ó8‹‹ü7UY¢>ÑN\S\Ñ¬‹>ççKºMQÉyï§Ñ>BÎÎò3E¤bÉÚ•(†
fåŞ¥\ÚµuX´ä4)#ïªÆ°ä(€[²÷›•ûÖ¼Ì°Ò,Ê#L«$µ±ç	–& ×yÒ
Şc;E 0Ãz‡t(OGp¨á‘ÁÚöœÆ²ö ÙL¬1"ËÙf¤³Hà³ĞG²`Ÿ	¡ m{f&Œ—Š§­Oîâôy¬Çjõ™¶’Ñåà•hĞÈìÖª×b’VÜOFèk´öÄö­(LFut›0«ˆéÀH Ô°ãµ‹¶İÄ#Înb‹†±VÙ'8XÄ&sºÕ¸UUó‚¬ãõ>Á:\ƒá‚R ì<––3Ğ¼˜¦Ôcÿ†¤MÒ;ÕT1Ûb@f§p³éÒàPŠ^;Óºï5?b¯
¼/ÁôcÖuÇĞ†.âx¼!Û?úZ„gªsOÊ’¡Óï=dA“×ç±ÄËÛ„_,á`»œ&¹´ı¦Bfè++P`U‡ï´ïDºec]x3Ğ;ùS¬§VâèöJ—³G¯u¶”Î‡?éIïÚK)£Zñ”Fk\îŸu(5D*Á°ƒv¸/ÚV*A=*à|£#bÓpˆ‘g¸ün úôuxCæ}èÇ‚rÀ9Ó†şYÛ<SäfU‹>´Õ ï54ÈÃ3ÔŒšsù±
*§i¦ì±ÿ0¾ÒŸ>[´Ò¯Ñ•IĞâ†Ft/Eè\¸ÙºË”Xª÷Ã´FIâ\Wwûñ^¹Feé½íjW.Ï÷¾_£CöºŠµNEøÌl½'Kõ1!]Fµ6§şzB3‰
åI)z%ìÉÍ{"¯µĞOÔjQ×%İ¸XJèKæÙ°½'1ëµ÷OYWÅ[J Ú¡\^Q‡ŞQP{å3”¶IÒgß“µŒä˜qr*ÆFå~ö•ùOvÓÏ°|ï¢ª3åaIıêùÆ,
’·#àË9‡zSÆª˜ss,Ê¹”S‚èÖÈ…ˆFëşádø¡çüğ%Bµ—ğP`&,ôÛs¶'	 "ÈŒ¿}dˆˆ8'($Ç$õxC•¢,³"Ø§øxwe·rºáµVM;#•OVI¼v(ÈáÒå ºF«]êMÆÏ	ù…UùôßU]ïävRæñDnpÉ,ºT¹.µ÷ÕÑì†}¾©Vw Ğ®ÌãîĞh
»­pX Qœ4ì¦¹QWéùq•¿›ıåkŞŒ\]P\©ù
›$¸İc×…Á%_Ò¢#±›‘HÒÌ>ˆúïw•öÖ–{ÈUÔï©åhNìd:kŒË*ìÀ|Ôñşxß-CŞG§$ˆÀ1×yp	L@M!˜¤Øº«Ÿ-é­®K’ÃX9}Èú²tfM«7€?¦]0Ë£*ì²·È?í¦\m[yJCÒŸŸ§ŸúßæŒ_Ø%ÍáÄgnÆ5Èva’%ÇÏçlA£Š« q	“•ïHÆ5ËKµA2
¥XïU¦Bö	ÛÁµük´Pûê":Ê“İRÍ˜´¼”%C‡<ø#£MpW¿µü¨şÆÏäh¸Zü€ÊƒY;ÿàÚ¨ƒ‹«v¤ÒØŸ®›ªêë“ÙÎh4›dD¦_.€_º¡v$&êwôÕ›ù>MïnÙP!UõAG'š„4Y|É‰3à„Q#Íäï@°gVÒÃJvÊ<-c¬3ôr«Æ6AJ´bB‘’‘5+o““å)wbtÃY¿g2™öŞ‡ÜË;–Cö†XuRXî³k¨å†q²å…h›ˆËk·pÈ{Š«”»­ÚùóÑ»ôõÔ->	¯â_¸„ŒÈUºk¬ôÿMÿ*lr—ïÅv*ô?9k„Dhb–+Øn—|ÇÄÈp7¶Çö^ƒ•şîçißvÀ|.äôëËi\>ÎË“ùç°íWìíñÎ
ÃƒMu`:(IGDÜ¦‚Fshİ&Í?ê+Îè­5Ì ä›L"”õ3C[ÛÏê‡KØ;³g<J|÷
O ·×A³õNÁ w€äi(ØˆkUO§>Şcò?ò~›cÔôjIˆbºÂ×œ}PÌfhp}k¥5â³ëï#áñØÛ€Şö!½ÇrİäYÓ¶>3NÒç8“™‰Àe¡ü4%•˜–òšğ?ß©ğ*\®½½{9Ë‚1'‰œŞdNPMkN!taG•–KbƒœC$Bg±ÏAò9ÄyãŠëıSÔmÃPh%Gj+·P° Ê…²ô=W=ñQ_'Xç¼ºrÚ„b|ŞÌ‚HFš{p0ò`BÆÏ¹ûé÷,¢f¼ÊPc#°KSéjÁé÷$†V<éO($f¢Ö!=¥ªJ­£ëØ’5¾ğwZù ‚NÔ -üonbÄÂíP;q¶¦.›.úJ*ATŸ–$µ=¶HŞùC€ØåÁ¡*0\ßªâÍÏ#l…lÕÉnƒüÒ´0›¹Ñf³ëv£ëÍƒãç«Î57q¸”—¤C,w¦£éi¨àTy3]YH*\@„tP˜èw„ :¢@ L›'¬Iı"ç©j(4—•öÓ¸œŞÖV
ÙjS–Ÿ˜tA#ÍP¹qÖóÿ³4¬A×J\É+„é„$[±né_G_ğÀ×Û‡d–D­k‡ÔöÙ2Æ¬Â41æ;¹œå"5®ªÏ< yš«;æ×Ã/ôNÂµÛ'şë»]»VlùÏ*lÔƒœ7ÿ>$yg«ƒg¤Ô@e[r¸ÖtøÈû/şóÂ•y½RlÕFÜ0gBF·0q}›>ÆïÂm”Œ)éßŒĞÍUcO	“Ä•G…~zl8ğù/tç/»]²}2`5÷‡Z»XF<.~œ„Ù6Åêz‡ÎuÅÕG"äÃoÁóÂ~a9|”÷m¥†>(pdLj§[P„Õ–ó©l’z‘Q“‹» òÚ­F	°Ò®%ï²=°6Ä…  Hä	C\`(%Cl¤Åº
`ÙI`{zdEt®µ…9Ïvh>ğç†ù¢XIb­ÿ{eÍ›ÍrM_ÀŒµHòÂ¥¿u¦÷z¾Ù“q"6ëÃë£âŸ(»£•Q“´
Ã…ÿÕ€nrc>Ñ×i¤ÃÊÚêìÎ}¬ä$o^AØH1Ÿ$é¾ÎY4´Àå‡–RO–‡Ûø_î¢5Ùì#>"Ê¬®èÜÔ¸İHHYßbuÅ„áğ×ZjâİÈ¿åé¨lÆ<LÆşmË=ÒM¿¢WèoæöÍ8ÑÏ%-‡¯…jˆ¥*½nC“[~)q=#Ú“Ó½xÈ¦±A,èZ«KB‘¨íï„$IòÇY/\¥­„ûGğ«‚Y~Õ¹8›VÆoºJ¾ÙUı„¢e}Ô“_şôæ™4¸AoRÿFZó3PLB«çfEc£|ÑµRÚ>¶¥"æ’D)‚²f.PHÿØİ2ãöÏÔt³­ü‘ÈĞƒí].çõkÁætï…˜¦;ÓbV_ÀÎëÕ?¦¥f”ßJ+]¸|WŠ¸nQ—7&äÅy#‘ÎŞpíô8Ø+YŠ‘Èı#è|u„Ã´¿›çxAqQØß®7ˆ×çi8Ó·ôtÖeK,t<¶÷P ‰Ñ§¾^ï<¶`ÑxÜ9‡^&~QÌÆĞ– 8¶’j³Ïó¤n8ƒÕÃ¦Ÿ.
ì¨qµT$=gƒÔ"r±:<î˜Æà£ù`‡üšıRn‰Pô`Ip	$|]rc-×Åf›¨Ş‚ï‰W`Æ=Toôú„¨‰TŒ,M´7Á£óó{…€É-(>Ê"³C†ÃÔ‹G˜¤íªì|Ø-.I™3Ú8AÖîç{Qú›™†"M,HŠİ×Ú|“êÇM—!l¸¶›=oA‹i=›‡±}»: ë¼>A€İ|Crd
:iX}*Ò8Ô»Ù3~ø=/Í_õ² Êr§1ÀÍYÕ°S=¦ÇïÇ£YR“ôÍtÊE$¥Íçl—V-¦G.ÚBŠdÖ®‚‰r…n:ÛV.EHÔ¿<¥)½) ”Û†^/û”»2/%eCˆÇg?Çgh)y¹í¾&£cº6òS/aÕãı€ÕÅPH=R“TvÌŒÔ'_ÖÙLÄ X	GpÆ·B8· ÕãKLÒË<OXÀöÚ[ç]–œïµ7#¥-æu²
ù´/Œœü¾.l—Fú^®ÃF(Šd"t…ÀÇczøRI8ÓŒ÷'‹ôí1g‰Ì†óâ¶<»/J!ÛhHm“ï>xlã j— 3ºÙ5	aRd«êİÍ}pA÷,rŒQ®Zw<6ÊînRñI3»Â8ïët)“Ì·0V	MšJ59_¾yMÙ³Pô¯•€>ÇÀfÍå­L<"tPËlIÿÏ’™ã\MP<lŸöğj	Ët™%úY}¿ZL ,fó È”œïßóŒúçÎ×xö¸èuØæìÈm4œ½d½Ò‹â£Ø¬4s÷¸:¶à¥ˆdêƒÂ6-vkDÜˆ®¢âš«'~K4fDÛšxnYÜ¦BPÉk¶ù>sû2YÖ=8°+°ÒZX2mÍ”s4	UîáÅ×ŠÙ?X/âÑ‹ÿßì‰‘z=]Ó’®2ëáKUì&Æ”.0Ï™.!wCšsš·Øè@ğŒ·­"ı«‚3–›P€ıaè†+…›—òéRRşƒ/üâûòèzDß³)/¬ÿo×Aüİôñ,ª è=´ÚdŠòLİ½Üöâ¹¼Š­ílLüÉG/d\ÑF%ÂtúC.¡ü,,wÜø?\_jìüCŠÿ«÷b.,ßØJæÄõq1V )Ü˜A›¤êòóp«uëQ&k—«µ]óQ*D¥ÓtÑŠG–ıÇ­Áô­ÙÈÀU	…Û´³ûşˆ}l¦ü†Jºò†Ş]
4¥TúnÏ€åí¯øHÏ¥Z£C´³š¶u;º»JÕlgOªƒdû35l_l.5‚‚=;ovnÔ¼İ\Ş|kí.òdĞ§ä2|cÍ¢kD­$­‚fáÉ·¨rñ>¹!c¥ÌØµpì®ËƒŠ¸ÈAÖê%:¤eC‹”rª_vRŸÔûüröWr’6ó`¼©]ÜğÂ	Ñd‡˜ş*%$
^ÑS;É¯.7œLôîAFŠC2ï)8¨¿HXçÛù…ÌÏâËÉ‹E9ln†®YÙ%ÛßØÉoufØ¡r‹®?5çÿÙ!ÇÊ¼k]¶Ùe>ïàG…¼ğİœÔB^bCüv©Çêù^ÜíØx	*×®’.f?í€ãæBÍ¶eŠ»Á~âsÏ”×†Ã?¸­Ê¡Ñ#ÂF÷š¿t‰À¿á+Îç%Z-‘ÿô¯Q
ŠíKğ3üö¦úæViù¯+x‹ v…Ÿê{u*4nf¼oîÖb8Ğ„+ÎÍŞVÔ¹ÿê†#’”ú®üóôkDà#jÜîÉ3NÀViTÃYàˆÏŠ‚«k<“×ÕçV7©²r|ªØ…åÜ‡¿é)ÜÕ}'›XÔ<Ue*›© m?3ÊøWLGí¼7c·z¿`3+s¯•KÇ«)=ç‡´ë"3¼ÑRC¢¹$Aª†ÛFI»“†¡K#HáW—ìÎ^â8É>ıÎÀngoqNìk½°½ùmÆöI<Â+ˆq‰ĞÁŠ¼q¡cw0"&|Và¦½Š ôáiÜÃe±77Ö{Àz° »üXnˆö2m@¾ö3EóÁ¯U½O½™0PÀn6iÒ›t€7g¿°‡]®Ä‚5J¸3S\Ü³ƒJL¸¸?+8‘„äd†%N,ŠôWÃ+”N¥Â§İëK¦_i19%ƒ€RIaËC}
?Ñ‚+b3,Æu·%úRD¢XàÅ»œCü¹ïÎx]—ÉPÕÀ@‹~W-•Ï×Ÿyçøk!’MZ|5-H˜ü×ÜÄÑpøŞFõn9˜š~ÀC>zö×“gÓºa}{a3…Ÿ¥ÌˆŠ
^4gÛ÷X4  ~+»ë¹±G"¶tÃO¥¶û:ºn5‡=s°WûxúÍ£Ë²+ù&Ú:«_m^Là»âT<f4íÆp"¤À{Ú¸É.¢ôHİõibDˆÌ¢—Sî¤,dúŠƒG”AêÎ8ßœüIp–q™1&¿öa„-kš2ùÖúC^é÷”ß¢sO"±µ5öVCG	ƒmc‹6ùzPz•%îBÃ¹÷ûĞ…·QüWYó´Î ×èS6˜zFÎú€á(“0úªZe §şàÏş3Y.èJc¾IbÀn¦Xõ€<aÁfFõPh¸©No¿¤Iâ)zí|°ÈÔLI<Ñzà‚µw„Ûè¢»æ.É«õ‰ê°GÓ]ğr­*é‚Å§­ÎklÆÂÅB÷³)Qù×	±NëÍ4Ò³hÑöxô?¬~‚vÏ¾f[¡9ş†9Ìä~+¡ô—ıaëucô	ˆÎ©Äµ¡V²Zuˆv}ã©¶®±ãRjß-Á®VRäû›†ßƒ«Ät%s}‘î¸{CMùá‰9F£%z¯™õò~ü‚ì*ŞßuÿÒª
÷í#
¢Üµûî\—¨­Ş9¬ô\DÁü²Üÿ5w5æâDğfyÊ÷2†]5K]ˆFÿ{Á¡‡Ğ'(_WYøóÛcsFlÓ«·l]8ß´õÚ-†ôaÌÙè4úçµ»:Ğ)³tißlÏ‚98ôêa¶8´×Áì=õù(ü`pYÁšønlá1š5u“ºt5¾-şáºíô¡·ŒeØ¨yĞ"AŞ‘p®ïæ\YÊÒÑlkq²±ş¿µ&õog~Y¬€¼2g) ¢IÈ™Uàœş†l¾¥ZŠàv—~‰ŸãÎ›d)~zË ÿ{Œó(ö«ZA/ªıçBÚ‘Üä»BEı¡ÈvkĞÀÏË@ªgæ‰ª  ĞgÖ‘òèŞ¤¼ğ#5_£ô[gì×—öî`$n)cñb3È‹,C¶~M÷¨hq3™™6ÏÙtÏŒõï6hß´–ëÁñsïÈº§ª°¹=y"ÅªÌ¤¶İ Ù~GxíÅò¬&z’h[Ö€ü8ÖĞG”Ô¶İ«¢æ ¯„+·ŸÒ¡@gÁ.Êy?å6d&Tªp$ğ]‚DÊˆšìÈÂ¢¹}¸WÌ3NWSı9G ,ıœM8…~E×ë¹Å4¬~C/×‘ŞâäH'éü+Ü}zÜÍ—ÀSÂ	0"Q7ã/Ø7yj0C	nÒõ$î‘£LæfH¾,^#¬l‰3Í=×^uå¬ÊícPŠÅ%bï>ô$Û9qoË×¦uôr}tşMÑISÎBìãÌ&ˆ¥cÑİ‡FÌƒ<¬Õ²§¥ŸÄ}øºmÓj‡7£m½FØ½­ÚÓéa.ã(£&ğ÷kÑ	Æ7uŸç
ûjæèïÔt±ú);7ßèä»4¢	E'…ªóv •àT•XÉRôA·[$ŸÙ$¹;]ïs«s“€ï ÏZ'Cn²t@Ä®¤n×Na­M]£¢V”1ôi¡€½¸àAŒ”á4Œ¬±H·96/«UÇ¿TJé·÷ûÎÛ&ÊÊ$±`kNßŒPcŠÄÑ+¢Xäì	–<¢LX˜@iuA,s%*¤Ü&Ì$) ö€xyZêîÜ+š€E¥ºÕ%‰£AßöU‚*)Yy.È‡‚ßHR/M²Œ~Ø ;½ùÿ2¥ék+_Ş@-cª¦¢.àŸâI/(òÿ»-gê¯cƒß¦Œ"€öÎîhDXÎÆPÇw*K&±ÇYc —˜&<p­’†Ùüæp§ö¸æK'†XÅ!µ;1D˜Ñ\BØfãñ*$šµ9yh0ú<ŸÕ(„x06¯ınÕ°ô€ôÕöF(qAä¹Š¨\ğßVt}m“Šˆ 8ïÑÖç((ˆWÉéÙË¶jƒ`, s4u@Šô–ÜÊKv¿LşIË1"Í‡E¾,„=ûbp§r;Ä…4Yñ‘ÀDÅQğ•9»»³„›€®ÆŠQ5Pé&ÈÓ¾Xˆˆ³L³W$ĞD(Š Ğüqx =ên°á	*ÑGC·£0I¤
ï(ã¶×âûªË”#Ê†Éÿá€'O7Z¡<ÿ~OR‹"mÃ(5SÆ¾E¼?aË=ã¢—^ÙÀŸq›`#di’2‡?EL÷‡ŒÆvp¹>åa'µ>3N]."$Aá r­˜Ëpcö¸ŠÄÑô)İ¬Ú“G{9 uNZ73Bú)Ø:Î<ÎHrğÛ»)`Œ™†µ€`½" ¹q¥¨–Z¥añ¿X—ZÉ™ÍÒÿ·DÌ=¶£4ÆÎ	*ßõ„çoeyÍ'\·ÎÇu[Ùbˆ,†t–•`?®¿íÓ[UoÑ	°’„bÛ›V€b~-éJ¶ö‚sÜé!Z'iÙŸß© 	d†­¼e¤i=Fñ[³">|ĞÕQMPà©şuÔfQï˜ë¿İQ¯æè ¥Âì˜¦ï÷Ã¬ÎÆXX’!¬H•ÚÍØ %¥‡Ñ÷ìÔÜj¬ê_©j›¨À4
½o([¨-±ñ|ÚTrÕ/X2.G$D3ø)½à{%ŒšVİ½á‰¿$<Ù/şÔÈ™b5)ZEÍr&ä¬ıÎ£LEJ‡¿F²ßİµ×ã˜Ñ«íFÓWÊËõèò…øêú»çÅ¯»Ğ¯£4Ï9@«ÑÏ…”ş*ÑGg †çy·ãÑ5ÂA|Yñ%>€òÆMK 4¤!h¯Ç[?è°?"lüÌğ”Œómªón!²`ìø ³Ãq|VÈÃÔåS¤ïjËÚ¼a,ÒægE1qYjıƒŒÅ¶’%Ej…zÃDåº›^é‡°[v§”$‡É9âŒå×˜¤ll‚+ı\¡
+²¦ğïB‡Nv€ÁBZë0­™#MîH4ûE•¾‘üùÛ•çGÒĞW/‚sEÜA×7€v¿âûéá,¶‡»ø6JØ5ê>2ÀAG¸98–H—îFË…Bìö›ÄB­ r4ì)‚Ğv¸Ùmk¦ç‘ŠôtÏ<)Ôæ¸·mŞ£ÀÑ«Ÿ
o¨^úÕ­T+(˜–¤G‹õ/]Ôüœvø­ìîür~Âcz“xŞm‰`"¥mËæ;Så[Ciy×K¼(BÿÒ	ËxOpe¾èe]ş|ÜGêèXQçş•YZóKğ-jÈÇ?†»§<Ğ£íOŒ‚Ë“_ÖõøÀ>eÌ"L’ éoí¶fê&§:Æk‰»/^ÎnéÂš’¶qEºRÓ ^Ôl·P”ÄzôÖ$Åá uæ˜a9"}øeúrËÃ§èál”¹‚ÃïXğÅÃ‹±f„’…¥·œ¸º#‰uS	UFCKd`ëèÅv`À§V#ZU::­ØUùì®=L›­õæ‡HFƒÿ˜!a˜UÜş•FEFx2ë/Wşù“¯¡NÈMÕ'YÍ¼Çmåw~6Ş„¡{>¨nàgØ&_:Àâª­ë*š¨…Ã
ÒY,°ÆªnhækzÒŞ„İêšªsáƒeÑöyä +ìMc|€“©:ôJ›®2H.®4ß§›ş~»,ÚTÆ‹æï²Xñ@ù~úœ¹¬÷g¿àòVzåb×¹ûÄÛQvP*êSF¿º³ò »<ı(Xqü$Ïë†“¸áÚàD5rˆàm©;ÏR4ërı™Ñ:jŸ•ƒü]?{æ!ô§†ÒævûØ}¿å@%Ì1= óWÏÿ–,B•Ê‡å¶•“¥F#V¤qí@¿¤-áb'ËÚ› J4÷©ºi¦ê_ë·ïx°W_=1Ó|`X‚í
YÏÁ;ºö*Û[_ã¦¥>‹{?3Q9ÃFQcùäèÙV3ˆ‰®é‹s—Áÿg¸•÷étIuŠ™X/ÜF_»—ÁuÊ\Ê²M“KŒW'UD§šuc®“ˆõ^n¤AË¢)ïs+AßMÑ†;€…Ø¤G5Q‡ñhJ&”Q;46”§`$¥X*ÓQ4àí©Ì*2¤÷h¡K¹´ìï0Ôõëª;*÷ò¯j–Òéàîï%ei|pÙï'›qtğ(F·]$6–?ÚZÀ_Û³ Z†ÂØÒ'~‘V+„×¾7Ïß”&FQå.{˜Ø¿ c‚ÃàƒòÀÅ-ÊûsĞ½°¬2…¡¤YYñ—ÇFå¨‰pÀ‰ü÷’§R¸$½>ò
ß:
–iÖõ©±§<›„ê\©–­Õò˜6ñ!ÄOBY:`çÑcc×Í>Ï_JÑë—ÇäM®ÅìãçE2§°[ÊÏşôÖÍwøU£Ë@ÛWÖ2o4¦®¤w}’W«ÖejİñrÄ·6Ì—*<Œy]«ÚtsxœE!¨DıM–mr¶Ä¦‰Ó2ƒò‡’\¡$ñÜ3‡ @ã}—ä4Øe¼:¨à%œ@Äyn•Ò“yà}®Ve-‚şPiÒ6,Yl0W3Ùí¡q‰é\Hwbö™×¼‚Ñ­Û7>5øÀÎ†İK…‡LBó¾'¨¨ùu—^£3%ÒdèS´rÒ·t\HwŸN+;•‰6?£0âTÀd­4©Y8¬ä\òN1ò…ÖîPÕ“‘¶¿1ml¢ó‹eĞØ©÷µ4$—üÚ½Pê1@ÏÜŸ9Ö·gèDâ{½‘QîÛ	à7v
RVÇáî9älĞ“ª¿ÅZ’6‰A@e2ŸÈÅMæ:âµ…ïÊ@mYw måy œMY—!BnMÙFéAYJñÆ†}€2b~"×ß¯Ê$A€%º†œ&àÂ	®>¬Ä71²S|[\m[¯P¬İnOAS·4ÃUMü?î3@|=Dƒ\ş‘L`7v›*÷VK	ø"4ï#.ï”²‰^ÉÉğˆV.Ybë
»¢Ãm$(¹)&ë¯Ú1ó÷Ê5şµ) ] ÖÔY¼c†ÇŒà|ËLÈ/5ÀÄpˆ¸¡ÏÕÊ€ô;ø% âŞÉx&(ù!uó®oJğüš¥ú)luùv`‚MÕ$sF+Úå‡‰ëÓ§kºEØFöÿyUÎ×[í^oi•@Üô `áY<øşğ%öº¬YVFß­½ù™)ß‹d`áç !Å ŠK¼¨Å”íCàŠ³úÛiËpŒ}¡‰ÜœŠ±·°Åà!
†åsî½‰GA›`ê<ƒô)C²½ÔıŠUÈÌ“÷ÜÊ¥Œ–­¥Ã½ÔâÂ¿mÿ1†Ìwv÷·>¥!À¨•Â,a§É35_é‚0¥¹¸å,^_(-pcDŠ4†
T@lKï3Qõ­NÀgÉâ¡6sggöie[¾·{ïäCÍK¢äNƒ¡¦…
óû¸BÖşVÔäùg	ççK¹Ï&L`à†® m!XĞ4[ÔaqNSœ°<¼#pÂH27³>Uk9Ìr1Â¤8p˜b
s·›­z¾d66ËOôIfg0qªNì˜±Šå}•ÁÚXdâvøÉ.wsÏdqÑ`Êöºì.–®˜»í*\Œâ/=5¸ßª…ÊÂ·"¹Ø,;•\J’"o::ÙÔ#ıÍ¯¢>{ş§œ+u9ñ;ºra×{O¨#Ó“½XÓíÙåIF>~¦›UåG2r‡ú3Ú‚ôØyc•!¯tlBy"ñ~u	@—tÏF‹¯6>’HŒ})¢ÕJÂÍ÷çïgÒg±´¯ıÜ Cş(ÃİÓ~°–?“v¬L¯&Óş `NCø8JS3ÇMğºà•"•æUO{P¥Q´;&ÅLbûƒ) LøkP¶Úû½?TÏ`+·ëMeÑwifä¸SüFÉÈIåŒZª'yÑx–rW©OÆ]=2fPy¦/.œæTaĞ»¼Cl5½Hºğ'éÈlM$Å/â5.×OÂñ[u°.(V´¡ñ”Qí_¹ìŞ…»«iI~§µØ#†ÕVZ¬>ó–rMM2Ú¸Î31ğhK
°wŸ±Êêº÷[_K/Y›tşÒ[Y±¡ŸÁI4+Yßn€’ÄÄ3dòÏ‘ÅºÅµ¢SsÅˆšò@«YNšUæÆÁú45a>¢ßÚŞ]‘•G•@†øÉÒ$‹†›»$`OJ“Ø¦¢»É¤Ô*º9ÍSîşºÃcßÚ'ò®í+ã´Ö³§KóÇ‡Ë†##îjí`›'“)õ¬“`Ş‚T|ëóØ?
’pşT†ˆ~ÄöØ@ÒÓ8Ìm.üTv‰wó½Ò²:åÀ°µ°gU„Ä¼ùVˆlØpÅõ°]¤S£ç±“‡‰ü6ó³‚¼„¦-.˜IšŞ~ôWÍ†2`ŸYÿ>9$,c$`Â=?hÕ1@EëD‡aóoOQ¯8uéaœêCn”5'cqê$Ë@‚yA9¼±0m3yÉÈM˜Ô/Üm±”Z;*gƒ03jˆEj”&ìÛ;Ş°5iŸó/Ú±±ñOƒ#Ò1¦P‘nsKÖÊÉèãxãƒ¸­³¶o*7q¦Ì8¤ÄºÌDª5ğ¼É{¦ïÎ^[YR4
²Yëû‰o9+I[ê”½ëØp¸G”{!Öİ¥qFuØ2Õgxü×º¹`„b¿gÎ‰,àUM0Æš;ÖÇ7€TÇ T<PÊè§½ğñ?X‡˜6“Àğåëx½Oı›»åÊû
'EÏìçîãr."Ëz^”dĞâ0e(£{!ß@×¾,í°‡}$5ÀNï›3×Á]+{Ã¬«ÜMß	­÷}Ëtì *e<DÃÿ/Æs1Ïe}{` )ğ?ï³^+SÄ_?Mõ\å¦œC,=—M%É oÛÏ0}.ßgkÑJP@å¶jè~ór!‡EãR ŠTO¾¶×İŠ,Ş”Ümn‘OQÉ„hìW„ iäçºÔÃüö›ÆZc¬^ª›¬£°ëŞdšS2JÅ3€O«Í)ºt&”ˆ¦±Db:ÿ»ûÚO\¿](…+#{'Ú –ZP'=şèÄ;Œ	ª#Ô;XÇŞ<“Õ´>[t”\º~`Û×>î˜œ¹Xöå³$’ç4ª ©¿Ñ~ÏÊØôÒÕ>×1Š°áÌı¤¬ä·9,6Ì\ÓSËØ4²|²´ù	”ßP×£DQB3Ç×¶%„‘·’rJL™JÙØu+˜ºÂ`+ŸwO6ÙWôNÛ;?´¸JîÚ¬»^Š7PŞ+"÷çğ|--² Ñ©Ï ©±ó²?>ÇóD‰E²vÊ¸$â‹f¢‰9M'¿ó*Ü‚”UDO=dú£9õ›ÅH
˜à—³ Nã8:^Œš…)õ¾j1C©l}Aœ½\üö¹ úµÂÛó[\:ÿåŒgHK§æÏúåÙa´a%£¹_eñ#EGŸÜx´8­B.ÑÈC*æ4µ[6ÛMş«Iš°0´€²"NÉ5şË f—4’H¨9œ8œ…üI$¦Z‡aã4D›±7™	®'# {m'šâ–¹H/ş¯N*kpÕ2SalÄßø¶0é.Ğ]S'Š_E©a·Íêtpóü’û"kßIí¨t€â¡ì,1Ê3Ë%ù®ïÛÑˆ*>kY÷Ûä;YÏ`Zk’rJaõ®i#¾}Iü…ÚßoŠÚ<£óÙg›À»örÍÆ[£çìD@5XÏ±QÎ·
¢ÉÊO›CB€°mé)`›˜yÔ±„œ2ÜÀ¿ }éO³95ZÑPí™ãî‚àœ‘}¥!^ôá\b(¤}Ãæ4£1½»‡·ïEÕOPtIıg,ã]Q‚C\3ƒrÚFñu°y+ÁÉßô4b×ğ
–>¡Õ–ã³OrM]Æh,-ïfÆU¯Kı¼³Îªë šÊUĞçLl¾ÆÕlÈîÍ¤ç&ÇoäOtU
+Õ»ÎoiîƒÜFjs”³0Çıî9k“akğutQæ«9ş!•›q¤&bË%¥j40Ê[ª½W¥ş¡Ô4øø+š!JØMö>MÖÑî*¸-±S[’ä8á‚±,P= ¿ñ&ÈßµVÿÀ Ñá·Ù,í5åÄ'0‘¢ğ¸yÒN‰iü×¤ ‰J7ûÆÄdS®o-ß‡kùÀZ:òF\mÏïÛ|5TÔOi»éô%L=ÜlAODnƒ3ù›ÀâñËH‚*-ÆÌìVE~ğŸq*ÿ&³²ª¶’úm4F›ØğsD¶††pD\Æe“~L×ÒÓÈı‘äoŸZ	Òwc46é6ïú[a·ÄÑüë§¨›?tPV{Ä6ÍF(Û½âÌ¦e·ó\¦>šBlYÀúï†w&K²ëû{%BJU
µ‘Úç
°ëËˆçÛÍ¤$k•£%z8-½ø¯Ñó6’ü1‘S\KÍL	È¹2òJ¦ø(®˜¸ÎmˆÕXí|÷äÔá4Âújzã´­Ü„°÷Ìˆ”r3BCnşm<ïCG<?YRr_kFPsñ	Gh$Êƒìéax¦SqäCÈK(Z%wÁİ5€Ì P¸aö,š0éÃ$¶•õâ¼¥JzúC1“	Ô0²§_²^+4ÿKçÚu=w…»±sê€à¯ÌmJöù²˜Õ·“£ÜzµlŒw¡Ñ 5*‹ÙÎ˜PÖ»I™A¡|'ŞlN’[Ï†è¤æĞ·°¥ jèÃc|UMü—;|ÿZUâ7ö£÷Ëú€Ã[-]‘`wõÆ}A‹¼MÁi;É€ne›D‡ëÂŞC%tn[|Ï‘™v"g3ı;tÉxDYÍƒL–?ö²§…ıW­/lÑèš
÷‰©¢r‘î8V«ïPw÷Šgÿ#+®&Û"YßQwğ.B€ö‰ß2Á„|×Š²‚:½Yy®Ÿªû1±á¹ysxÓ§#¦3—}u›+ËìGyõ/-=©.ÕĞö¬W˜gÀWjaØŠ‰q‚¸*Œh……Ôiœ_{ö{|ƒæŸº¨ê‹äÎzñ½Bÿ%–„Å·[¦»šK±QI]ò7òbë	‚¤¸œ ”c2_„;'êß.²ú;ï®¤œûØ:Øn@ààó$PğŸ/Ã‡Ò£j›*ÌHİff.vYãv÷²rĞg)§pƒQû£H¡ÀêİÎ´:à<èÌöš0¶p¨bÂ'Ïf¨ ÖöÇe³Ü†§‚‚j¿UP'¤â¹v™ˆñF‰ïkå´PYj_­uñä8é%u¹GN'X?JÂKo__>ıÍåM¶+Çº²Ñ3dÈí£tÙÆ”i¹“„2‡¼±™ÿØÆ
µ¿>¾)ÔÌÏ(<Ybª³¾ÂMü£ØÈ;zÃ&»Ë,fş»ü\÷S/½HÚø<Ô¤÷²E?˜*Ñoa—­˜d@¯@s>Vpg=¦}ÛrT•gå“(+>ƒå2±“4óM“Išœ0¼•g×7A{GÿzßÊ9E%kN`w"Ú!†äñª ôù¦©xYÄ”İpxOÈ§°+^÷é<‘·xÙŞÖq{¯Ëß_B²”o–|öJæós“l€3Rİ[¶¢ùöÂ¤ÃÅ›åâºÛ­©°·n®gjÏ»¼Aiº”PÉ¾€bë„àÇL6aÄš>píÑ+p°§l–›N)İ€µR§@¾$³„L„ãˆå²R,ö‡…à'ÿ †]ÀŸÈT‚vÈËhÓì×°nl£t<X-ì¼¨µ~Ô‡èjX–¦ùQ–G-$cp8ÿqK±i;È´üªQ†¥S9%ŠÅİ?¤ §XHğÿÅÿ¾Vuñ°qe«µÿÒ[ŒRì;#@Rß,íQÊ3ã! ll•²Ö ÈW“’ZPIQëtªª¡ËD`/YÎˆÑI¨npÒ=’)ğ¥e»p…û†GsUûaƒ ĞéÍ?ıL9h`%süGùE•™0;™xx°¹q&3š&Ò°	Uíf 6ïğÎªĞ)v
+ ~ê?¿fD¡"¤èï·›¤Ï@KÁ/¥t$£ıÍd¸yğ"â«W»î£bKøık»¦Vá®•§0Q0	 ‘ş…oÇ0Ğ’N¡y²«°,o¨cŞ¿Óë¿µUçŞlöZ@¡¸²éb5DØë‘Šš*ä·"ù%îš†ïŞ™Ö$±KÒ vK ©°Q'üv7Œ—XĞÙˆ|Amÿe²K56ûÿ­˜„F	–)A+ÇşÇL|¤Õ£ÓÄˆõr“z®û5²|ÆÓ–d¥ “* ³‡bYs2Å£¬Îzå5›Ä!§5óÕÄ†Q½m»ÙÉ¼ğ¨Uøßö]TPB‚!?˜”‹!¼Ì\y-G)ò1{'÷¾JµR9QQÚ.ÈO
i‹¿9îZC¥r 2Î¥Me£ÚÁ{ vùõ Ñ GE\i1cŞÓ?6é$Äqï%„œÿ1 ¿·3“\‡BGëµ+F¯±8Ø2¸loŠh×U¥_Ü:ØûŒ;ŞQ(ñO¡-œÅŸËÇy±7›è3ûó­.oÓ8Ğ”ß’IŞÑL„çYxÛ¿ñV©…•ÙÌ?ÆŞÄÆ/VúI£E¨¦KÖşlÙNôÕãLÒ€sŞŞ©…¥ÂqÏ£¼ª‡«. zö:í¿Í—ÕW¿>À. a®ºÂ[øx[u)L§¾z˜Ù@]rERÜ÷ÆwÂNEK¥YS1©%ÁElx>ğœAÆ…z¤ÒcŒŸ*‡¿óc…r{¨$ëÕ’9ØtÙôn†ğİ1Š=/…KÉ€Æ±ğ	‘e§ØRôù°½#’[Ü{¿õ
™Ê<1N"œ_»fÆ^`¶¶àÇpÂv‡õúÎƒWZ?Ñœ£ÉàypÒ ¡3OÕ`§.UÇ<Ä[j‚‹eşz:ÆÈYÔ:PUx—_:™‡AüeÏ0vTaÕcæ^ç•{|Óqy&™Áó^#iÛ†’‡2±p÷~çe˜Uçî¥DÃ}yıv]6¶ôİ¥Ÿé)ò“hû7Ô[5§     EÌiOÛY©q ™³€ğÿÙ
±Ägû    YZ