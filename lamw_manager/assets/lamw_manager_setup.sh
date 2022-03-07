#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2196165399"
MD5="7ad9181b0fff66385212b7d4a06d8d33"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26604"
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
	echo Date of packaging: Mon Mar  7 15:57:04 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿg©] ¼}•À1Dd]‡Á›PætİDø“u»®ÀÒWÅÒ¯Û²Æ";Ù¥P‡cÒÚm?<øƒVÃóE»EVşPñ~1z5H`^Q‹%
¦s9]}ôv¥£y“kÛ^mï±uà a† {> ÆÓÓ‚1Ş¶H¹ÚGŒÇ»ğs’Q…ƒ7‰{z"`˜‰Ê#şİ/;…ìş¨£ƒßÆW-ÅîëÕu÷«Z³Ÿù@¤é¹ß»ô3\„xŞiÃ Ä~À¡Åc#99q¯¸îX¡Ôô”$i,ól”_å¨à€–Ê}uÅİíø	+XËëßÒ–ı¨j$?J™qËnÌ3ÉÂr®ÎOkâK¡JZˆ&=lÔ!C¢?µï	ì“]¿˜Ó„š-û©UÒuI¼s©¡:6üƒh—N>¹¾Øu©İ€ªeäÅÈCÅ%Íƒ7o|µÂsy×À	ã’`˜YÀ£«pR`Å“§q<âäõb¹½qŠ_~%ÀTñ`(jí¿âÌörò ’£…/gcè9%WwØNî$@”ÕÆü	!ˆ6*¹­O·>ÉÔÛ<Àëleo=ˆëõÚZ<ìœÔ#ŒíWö¼ş< Ñ×ÌŸõBØ´2\ ïxTIú#L{b\k{YcP³è1Ïæ¹Š•;‡]ò!Ğ*ŞÌdv&ˆjUb•+b?7¾Ÿ‡‘:v–ÊÎßs++¥³4v)ªvÜ’2üÙÂ€éwÊ™ÓPš[XÅTiªn›fuĞú\nïßÎç-œ+­À†bJÑ¢ĞS¦\û6¦dúì}®hÂ?¸ÕŒÁi;Õ.±].,ìÄ?@äu{ÿ}š«/·8\7OÈ”§Y²ĞèN¨æ[6Ìh°lëÅ	
®QâRÛ©Ì¼g0<¥4ıãŠºT¬	}´¼²Å¤ó‰¼¼¢h¿yTYGgN]üïlâY1H*·6åtÇÍjŸ,_P§0kÍGí  ØÕñÀ¡¡gÎÕG?˜€3Ú¡8‡+Äc±ÍÉÊèû¯•ı+ø{ï¯“<Bú½/ƒ2Æ29q¯Ì¹XajpO‰~ãë¨äz«İúì%“ˆèEÚÇ1›¡†C•B˜ãFæÙj§r.zM„¸˜.ã6"ı¾Kâ ›ˆi…NÏø¨óŠ¼Ãª|E`Ñº—’%1¶Ò©‚Èéb+ÏÎ†dmû™O¿[eÑN÷½)ÑŒRïğ¯óo
[IÒV7fsddÂæc°ÙšbXÏ8úÌû Ù‚&åïµç¾åö]ŒÎ$À¢4«±‹
Áß—ZúZ}Áì7•ôĞ‹êñºÄSŠó¥MÏòœ–Ö¸XOUˆŸJ ¨y¸çjî’U/î¨GÙóQM º:â+™ddeĞŸ‡:ïk‰œ?n¨øp®ªØnèéç„|W	OÎj%û$j)‡Læ\ø[Ø®±¬¼M½ÖÊª{ªP´»øŞÔãÏj)Ñ¾¡Èæ´·xé"[Å"£ |bÓûÅßË§;¦?HƒG)ĞŒF}ÅñÎE›Á˜YğMš¢µ)kMdå_¡Ãşš³Ãƒ+B9òf8ÆQ¦¿ì´>Ò`\-%ôÅ,»“?2…Q(÷@ivõ2†î½Ät,c‡ßz:œ‡©Q\~®ô
‚oÑÅ†åzõÂø`&¥®©„VZğ¿3F‡géÁ%ó µ¾ŸVL¾hTÃÌjœŞ •’.µ2—sŞVş)²H3e©	_šR¾±:Ğpğ¥
Ï „¦WÍËôGÒà¥)Ã+ŸosÈ!ÍÜb[÷ñÜkõÿPœ¼ákö—]×¢ñMô·øì1iw†­Ñ.Ò>??æHÀsLR¡äØÚ6Ÿ‰FšÕ˜LºO†‚¾œÃ˜V%f?î Ÿ/=tK¦à}EÛª\ÌU'“P¶Ä†ßĞì=ºæ¹“¬Ãd¿¶!.½Şj)%Dk\K•‹\CXõä¡¬&ZqU·Zø»¥ÑÙÌzY~]!*èÃŒ\ÌÏØ:ÿœË.dá2ƒ¦3Ãÿí÷%ëz#bó4ùöôåq¼sÕH3&[+|’™ÒÌâlÔ	'1ïü¤?Õõ~Sãè-¾Ùu³&Xmï›+c¼W{êLób=9ã«Ù"·–Ç5ò I16À÷:¶”…ÑiB<:Ò]ŞÛGÙEóıÉÑÅ‹h{‰fÉmS+LcŞ~ÓâñÖíÏ÷2¬@uW`è¯ç(£î’´4Î¢GÚätš@ãnŸ}Ûëb§;n¦e!êÃäæšŞ½¹Väê]‚—JW‚‡ò±îY·†*í¹şÛ`*ÍpÃğ“×·Aúçk¼İŞ:ó,«Ü—jD×&‰‹*ô·ÕúY¤Ø–8ôôò¥æWkcæh3Ø‡mk9¡¬Fëû]i…\¦şÓ˜ØTE'«R÷Ífmño§xºxj İ.³dº&Hõ˜œ|¿ê­|“ÿµ°»Û¨\WA¾øŞÅf¬Fqò2Eƒ2İ©Ç¹ïù&—Ì©®ñ+È{·ÎX¦‘/İ f=­«ìPƒÂQSiÀíš]mˆv,ßè.‡İQm®"W~Æ¾—„Èéƒ%Íõß
œ²: øª“m^)İìx9§ºV9*=\ÓXÆRÉx×'jòß‘"RŒƒ»b"DÑÊRÖ|¥áÜõÅÔ}‰F‰Ï5lVà	oB
v"6r¦Ğcê^™XjD×‘¸ šµ9‡!zyãåtfr£æ%»á	¥¢Îxæ¸šmğñJw-ò«B{ÛÚÀyIğC+BŒzûîù!Zæçta¨„R„É´Ğ‡eÙå3h?.ñ®À)èL°Şò–2Èúªtù6Ë¦Eí	„ÒöIìÑ=\V{/²Õ v²wB€Tşf(LTÇOˆ¨$1ãå	®GDôÃ—e%3-‚+Ş¸š·öH ÷zÍEëŸÿç„ñ·)	·Ïõ‰Y«”ZÛy„p„lH@à¡}aÕóÍ¨”1OI±D¶f]d0ìÇ] ÔJ¬|cjL#ÀõÔAŠVÏí”®ôfŒİ0”ËÍ^Ü½e+Ã	-6b*“İ´Ú”‰ĞÈ¿çk‘'éÕ}_7tGüáïzˆü÷GpÅ+š"e?iÃ@¥Şnİ5ÉP*ÒÎ† *­‚XŒ¦œŒ|kÁûà‰¹9^ÿä‡³$îLîªô­•Ò.Ì_šÌ{Ÿj=°öõ¬D‚¯?¸~}Ç÷°Ş q<ŠgXæ—ƒy7ÀŠá{so”åÄ÷´Õ¡Ì¡ˆpÑÔŸü…ù±B^ûù\Èwq;¶i‰sıoÃUË$„:0§¥k6Ù³"Š†R?;÷Eô'È)	®Hc!_ôır-¡ÉÙis*p\‹>r/c Që²×fã4ìôcíÍT_Ø#Öî9`Ö®CT)¥¹;pªøŞx#S6¥eQ)Ùá¡xF2 |ÄØE½Š2á»v÷Ã¥#@û“Œÿ†İÊòÁ#½–C/ıƒHaD¯°[‹ïô˜w<~ÆR{•½·åÂUÓü3=áÏÈÈ{EÀFk·)ÄÓGµuaµ(Ïl”œqÅßXnØûmsıEífZPBàèfB» ÀrŒã¬«l$èwwÇ‰ƒJ1j´!ÿ# ÙĞìC×İ²Ë_q¨°+Y-Äà÷7ó.ÌŸ}÷ÁÆ|RiŞrT{‹ º'ñq?*U`Ëµ²€\_æbÉœÌcŸs#€wä×5œRl+T~nÏCÆ¾ -(Pkå7ÑßBçSDÅĞ{šT¨´?N“5+[×û»õœE8íz×—×êYÖŸuEô¶ã&ÇÆ¥‚)³…ğµ¤ˆ ¸Ã³ìŸ‡.ú)×E^×ªp;í…‚êò–%®ïc5‹
–on9’õæC™Ah™—
YÛğvç2ûÛ€JËd:1;åf3Yšû½³iÅ1ábÁ[ø b áÑ«+³DÌ$w¤oÌö2<¢S$•Ê5ñ¡  áëv#Ì´Öôì†U6A¶æ×L¨E=kOìè!™	 ºBÜŸxí¬…ˆ$äçÒTÙ;W$€IM¨™@ÿ¥3œÎ¥^<{¤Ş·Êİ+YDY‘[“£l2¿ÒK†5õbS×Hû[i4w»jº:ù“¹3_J4ºN(‹GKñ´t*×£ªA’ôîÓf¯œEèøWÍéÀ:¶ì[u±®ğ­ÆÃª\èÍÆ=÷;Tr^Ó¿™!¤XÄS~#bd:&Fü™¤È™¹‘‚İBf€~‹yEót$|ÜTı¬ñ8ÿ D ŸD¤¾«%†—¢Üj{WP~Ü\F}¡¨¹P	òØD2$ÃSØÁz"L9³:déÀ—¨Ö%Jî$°Ë?—¦|ÔÄ$Ó
Óè8¯%EîN”ï/+foŸ¼$¡ï•¢^…)÷=hˆ+c†]. È”{SgzÔÅpÈ‡ÕK±ñ!¼Z%ÄyşnŞ+ª!„½ŒÕÁMÜìŞä>¿Õl¹7HÅ³uºn¢°_lõ&ÚF~‰ñ ¥šË÷&¶Pv|¾ë€hL¬õïâäo¥r!É9ª?º£!6h_]ÈÎÆ«S	$…L€Ù$¡wãÖÆ¹§ÜÇ#ÑÚËÀ½ORjô(ÃAW$Å(¥k»H§àDİwŠºïPÌÚZRÀÏ]$°suT-„ÓHĞ(:^İªÛŠ~ ex'Rw§0OÊĞ z*OzÆ½›£ašì•ùĞ4âSœ]Ì/¦³z°ãa^î£Ç„¶åˆ.uò@VŞš÷Æ“qıËö
#Õ)òã,¯ë•˜&?İá´ÉGÓŸ‹»¤	Ânş«ı´XNÛàzÄë¾ª‚iX°‰ø &w‘ÈÉ/ê½¾ú'ÍF}©ø÷;Ë1SœÛà°o~«)­­­äMÍ<¼Áë¥^¸™nåä&¯¶ş‘xÑIdÙˆÕ¼é+àåc‡RÂ’4)‘p«xBú†>.˜’	Œ#Ãb€œi6üS.Ï6Ã§;ä=êt’F‰uW7­|–J+AhËÌ«Ñz‡ç?ü±ª'  ¤“m†CÕØpÂ5\qÃ^Ó’d›©+
ÒÙğ9ÕüªB$Q¥4keæ+PĞ/¨Æ_€ŸfT¤><}^ñ²»ÕÚ(Ğf¢Nñëjêì"DÕ´8Ë#¿öô}&ìº¼‚âŠÅ2Ác&jŒŸEŸÆ´#ÑY“³x{ª§j±S’Ğã]9íÚP «1'C â‘T¥WHAÇÕxu4NM±ö'¦?f­D*0cËúK¨lé,ÏÑ¡ÅŞe~gØAGÏİ@´·¦`ùÉNÌÿ
ğï|½ÅãÏ¨ˆ°öôÎVæó£±hˆú•U—on4Šo†_ÌİÎÈËXŸà‘¾Æ-kĞrÄ¢’6gˆÑÆîÃZ…ˆ†ÿgıâ²¢n<qÄ¼¨Y¨à(·Â¦û†aJ’¦Ìå†Rÿ;«lDupöwRËÔÙÔFL®(èDÄh’Ø€ÙÙTgÉëáñÚTKÇiLRr5İ¹UûwøâwQaŠ¿¿}Ó‚O¹ĞNk~ŸKüÛğ´±ZuI>=¢í"FiMV_¶‘CQÌ#ÖÈÁ¹>|Ÿ.—ƒI¿ãm$äj~äJ"±À¯¡‘Kÿ€Ôà«û~ÉKlìşQè±7wâœˆ˜‚@s‡qV8Nl|“BÂÔE^	¹şL¿µğ=8f/uIû²å3§¨	Uâ‘X{e¦¬§}LB±3Í'õİ2|‡ÂŞxé|5HgĞF½Æú®îñ»Õ¿Ÿô#ŸãZ$\h ËWv•¬†-­»éK@F]œõx¿&¢]˜»¨rdpwúz]YK:5FÓ¬Ø9àÛv'y®q-3jÆ0ú9°òl™çŒ³ìëâÈßÕä½³7©fQuêš]C-ò2èÑŒ×·Ï7ÉI° 8‘ı¥x9%ëVş·b$@ÛLğ^pƒ#aåOl÷okºiÇÁŞ
¹ugqå|ä$ÏĞŠKÊ  "w%A LÔ}tÜçÓSŞ‰ŒºTÃ?Vì¼@Vr†Â ³:Q¢g1€yÇš¦‹Òa@øÄZœ-%Cûj0G/yE?Ûëô^E|J`!Ïƒâİì…aäğõõkpÁù™®	æ³ÜÖ!x[ÄÛA-ù½søš.*aT<ÑVó’M,úÇ{oâÜµŠ8ÏYBlÜŞ¡éŒEGš?µ=îja€]
Ä«¾Ù:ï1S¾N“ 3§HN=uÂX´öĞ»š‚ñ995·QpªÙ×å«z,N»ä|•!~oPşVÓ—­Ù¶¯Zs]ç}I ‹äÎ–nBMTIò"¡’rKê¨Ş-åôoš0AXf`åT×™p¼Ìq`&3b–BK7gÔmvˆx :8Föjó*ú…?KŒ€K¹ÌíÍ+®’b.XÜPãgzJy!n×ÁspH‡àbæâ3ñhœÅ*“!üì½71k„¾’Íá£$Ú™î|¯©ìåw”îœ ª‘ß3Oy2:ââBã~ïdœ›+ß¶åâõjıõß1Ó8jŸI¿Ä…ä÷´ë1npc{rñøp‘â_[¡4<W×ÿ*œ_Œíü}¢à_	ê^ÜæïßyPÈOü]Ÿm¶¬Ô‡±´È™ÃyîR3îÉİµ¾ò¶”‡S¢fXS/[>ò¶œ¶íûAÀX:>âÖBMı[›{¼8MB×Aòã}ñH‚ĞäöEÊFHÇo"°#²ò.~®2¨C
nW»­_LËš“Í‡›ÀdïíòØ/„mìi†Ê,t‰#·wÛöŸ´Ë×¿9£–­J<±óR¡IÎÉÖUŠŠ%1=$|³…È0–ĞÎµâ…O2cVvö|5&â9›Ã<]âÃ?ÀE}ÕÕ«P«'Öá2Ô»Aú¢`4ÿ¡–9¦êépçró ò]˜H|¬n j)5Ú½ûŞReÅZ¯öû9xs¸>³G/Yí<]e_ÕœĞ|´:YÉ`úâ4n°úauÏjğ,œlªGZ—¹<ñààöˆ•GlVÜ°¡u8Îzgq\ô,bÉ—¦Ú·şmvc€ví,0«ú›ÑÅ(÷Õ N^bjwUbÙºk®ıÎ•=ªÀ÷gïëğÁ·Ä§chåß8R€_‘„ûÏİz›qÎ13·Äc²­¦çÇòù/\ÅBÜ½ûYYCÂ™Ø”Ò…“v°ÆD¿Ø¯‹Î›(ì 1Q`Íí'¤Û«Ş<S‡ïá4m4*‹‹EKcìªÚëm.´°¯^gàd71GFt©%üïÒ¥ÖÄSÿ¡*;şğp;“J+×ª5ˆE>åÇ8/AëSw³Ç*oîQfåoÆÔv©Dçşn+CêŸ÷uv
şÑş	ë´ÇÕr(&Ï) ¸6‡fWb^u*Gö“r:^È9ÀçÂ´Š¥Rm	¡kÔÈ+ä!ê6‹ß$ğó„œKõq%2$&`ÕOs -)Ag+÷om`0üÊ'Hı8-y¹¡$¸aZ=r¥45vÖ’áòMJQlæR*ÏÔ½ùµå,Y;2™F)r¦¬ˆ8V 
u3öãwÏœ0[Ærı¶¦X"ëê!‰h2æo›;ãÓ¦-«úScyR$óÓá»)Öš¸9„ÿÌÏ—u»ò¿×8lMÔÃçèÒûŠŒ(q™f¾§øCÂ…xÌù(ÈZË½¹‚$%^ñÆğ°àƒÔ$çPL¥8øÛs!ø„[ø©St‘{VâºOÕ·é\P÷'¤LS_°ä3ê³šÃˆW^š¼X,²¸Yµ'_«e­æÒ][øé¦êÎ#,ÏeòÁÍ› `ÃåJù$\Àİ!…¡2Æ£Wş¦‹Í²1Cèº5ğ.&«V+ÿ¢Ö¯”€ê¹4¹Ğl‡±õAc.Ä8—Gøöèì…İMdºY7£ãv¡Õ%¹­õ×ô¶ì€×0f.„›&ZêN;Úríiÿ–W}#S81-#ÅePÛn»î@x‚»H^mùMîùd`ñÍ²Zğ¦<+¦Gª}Èõ‚„Äœ³à¿&OYÎ3ĞŠl±ÌÁö¯È•%¿›öQ§¹_k©Ì]İ\c|éâ¹ÂlÆ.ªÖ&[SÇE•ı:N—}"._cƒ|¨ó¥ú°w¿øı&|ºpßJçF¬—|ò¡€]·hë—¦-€f|åØÔêíÓ¥¢BË‘®)#ì“ÉÎC®$µŸ7±'k¯‚e«±Õİ²¤†{‰i÷„¸Ş‚û""ÖªêÉKıÅ?×)·ù‡çëg<òö¥qÆ<ò%û¾«‚Ú'\›2“-õI#ùšpéS›Õ´¤DEĞ‹{¯t0;>ÛÊñ­ş
ê,F`)£Ş)>H*Øí_òıŠöÃÖa“QUn‚Y2•[¬1Ô¬»øÊ‡ƒHí©åmÄ vkZ/,‡/›Súì-ÖjöWØƒ˜Ó‘,,ã;Ì²“ìô°Ø¿^M•0ıâıdø=ò»t9”Eô3$oFß¡&´¶²Êõ.“	CÕeÇ©=nñ(vùs[GÄÚş¡púÀ4ü~ŸVÇó&ZğËÍÈ3H6+ÛAßÅ%B"G]×Ê 3ÁƒlZì®Í‘5éâkŞÒ\a”Èk¢8;ôˆ¨j·?=õ!?—yQğKŠâìáÎyñîØêO~•çò¦%¦²›w÷ƒğ»e\ô WÍ„Ş·T¬%™ò<dóÌ{™İ(ß?º^½8P ÌŒöÄ-Ì%k:ùUê¹£?[x½ä—"½´ÒO½ÙÁÆl0n—Ğä,y·cúX&â_Úä(K[Õë¡:ZWİyäà‚‹=NŸCL…=ÿcH$ÊåIv)óL(°`¶¼*&nºôV8wkğ9§"Z¿
CO„Ñ’óY‰Ì×=Ì`´Œ8ü!ã¦Ç¡	½0[ˆñ`k¢?¯ ;«¨ºß"sØ×›º8©¾k[º@?¨ÙîôÌ¡ò†¾Õ¹=´©ÊúërJ4er¥s©6ûÇ|ò°$Œ¶6!¾j…¥4í£O)- Bè¥J½Šj<è6ìmàHòJT½oZê#øéÑ+sµ€E—ÈãËPw7ıÉ­©(à"Í²<U#gÆíÔ)ÙUËLc³§0/‹€ÚŞıpQ±ŞÆM‚tòŞ9€·Ï‚äö\kR¬ÓÈ¬ÛÓ€>oCï\6pØx•à9OÖ…~¬·¬¹€ÈJ7z÷—GªÁëœ"i˜5Y~Ö“nH ¹ ¹ü„bƒŠ…ŒÑÎM·§ø÷_£`VèiU´ñ½ÌLo6Io_İKKØF1H£TÒéDè	¤ŞT;ï›úˆHÿ¤òp@8¿Y½»U³¦(8Eô<Î^—9? œ9YÏåï·Çìl‘ö•!}Õõ´’h°ÿ'tø~ÓA±‡!Ò6ÉèÈY3.hicº@¨ŞÓN¨ü¢$6|ñ l¹
ıf\²¢h¡>fj<—oÁ¨FÇnTdíóx-ŒöájSøÒ©£ş'­aüáä¥àÑLmS7p°Ğí™ò¹7Ê‰Ùêw‚5ÁÒTD~Œ(1×S®îW?Ê‰è¨,é¾Ÿ'!ƒ¨ØìĞJæ7j\hôOX¬]Jú<è/÷×İÉ)Ğ»9RÓNŞò&€ıê"–0÷§ú¦÷‚™âµÍLxã¢~—‘Ú¬4 ı¼0/Ár4:ïKÈ¾İ†Îé™­Ú‹•²n É5ø²ªR>ñoÖV~&-fôÌxğ¤hoA~°.Š2¯›¥zÜúæ.¢ËVHÚ^[~^”ó)I<Tœ¢PT<„ãÄ;ñ¿´Ø½–²áÚÛ÷b-õ„Ê_1@AßgÒ®Í£Q¤óÒ ¤>A˜¬s("N±ºŒÜ¾„ÍÇƒ­VRïã7|˜ê3Õ±)­ãÒR¬à#è
Q)T>öSŞ>8ü	¨ë¾	:s\rM,FI,êä³ùÒF5ná-…
ˆc.v7°òh*úG¿)†Õ™ü’›kÂÀJjë-YÄ<ËÑåÄo®I¡ÃD›ï¯öÏ¤ÕHÎ„²>{K›å'm)ÊÚĞö‘bC'Ğå³7î\#íëÂşéŒ³'‰º8\WÖ¾¹>‚º$ ì9gÛ„k=æ Z³Kø'¶ÖívÒÿÕ2 ÂBÅ=™\ñÍ@ïéw–‘?Eığ}UJ8È'>ß&k	t*~"!h6n`³İë×7ë²^‡âHcC;ıö}eêê§	0®‚ÛáÊ¶©cÈT¥=tòœ¹çdÅ•]Cü,$úE•2q8¡• ¢¼ó *ÖØõ×#ûíø}!É
^½Ã7cöü°ç8©MŒ¬÷¯|¹ÖFL7äj(1àôÔ¶¿|ròD6.'ËQn&  8vúİƒtšö„Írİmç]´ô½»@AŸìÏM–"É+¯?ydlÈ¦äÛ	­,ííĞû:·¾wÕÊ`»{›q¾qı}£ÑË1p^IHñ”G^ˆ°LkM6µq/:XÆIƒ´ÚrDe'™ù¼<Èæ] ëÚü4oÙ©%áÔwÎóx”Mškı˜ÉqûfSò´Q_1`"2cÚ6Š(eÖ¾6¬‡bâ†Ô‰Ù`¹ nÑMok'\*¤{lT-HoGÑêŸ„Nû½·z!ñdZ]ed'>©Ù½1¶:Ãƒ° L³ï'ÎÎ|f¶.*)z›ÀˆzK ÷µmhZ·È×Jc§áR;em"wz.Ğ´åÈŸ=Œ /knzµú¨Íc^¶,”ÏokZ¹ Z•“­~hÊ˜Š‡*å"bw0ˆ>×¾”»’©Gl¬nÔ–²sÖ¸ªGüü+œıõÂ«Ñ©^åI‘/y‚÷¾zLjK"ŞÛÙ~”ÑÜM3¹Èm½Ù.3 Ìé?aWÁF£é/£°®k€Hr™5ÉŞHQ|)l¤Üµ‘‡´¤isøÙÚ¼Å˜â o°ŞÃo¾ır ,1wd&k‘í¿U
†éWº BpJFI.ÈoüYÓÒáî¦$µ/zf›Ò1!å§3‡Ÿq>ÒRÊí2¡ªØõ¢˜xE’	ü¥¡«°×ea…¸‹ÚæîağñŞñô5Ñ,©¢KÙqb{?ä'`ûtË±b¡|¯nïNíú‘ĞCqr:‚Î”\LY´ÚsÁ¥’‹Láçä÷+ìø’€)L0‡wìÃ³G¢?—ØWkI†-ËJÛ]lVjç]¯´Ï3Gÿ
WX,ÔW”®%5MÌôSÓC^u••5øp s1XpPyÌR$4›9)0ÜŒ5yäğGÒ‡Ô(ôN4ÀÂJóãh)I‘ ¡b"ø;J¦$‘K9KD”ú¤
À´—íçH/t”ÙÉ2hñÇTã0dNCŸë5Ÿ›t[nR ÿRl®æ³Âù’¥[T@R	/ãÄV×ƒè(Zd±×r™·Écj.¯»' ‹A_xn›ÀŞÓ‡ì`‚ù¯–¶Íç(°hÍİ¤@í{¤kùÇè©P÷gE,MvXÙoöv¿’èL.V‘'ü”½×8³kjB¨)¢œNßè~7Vp§—zRËöA¢Ôp)¶äP‚÷Ôâ4ŞP¦ ’KAÈSüL;¼Î´}µí-¡?Ã«ôg0DY¶„µäi›ôa«(½»úğÿíÿ×¦ŠOr@ÀÇ~FÅá€nÔñÄ ^µùdùÉÇœäÓòˆ`QO3<™×ıd'©_Á„/TBgñ€X5ƒˆ,B¾ ĞÌHÂ“=r¥5y®ûŠ²ÃzòZ)…ıÿ"ºM‡]ìF©!9YVb$B9±$·ûümk?ìP	x±ãNòÄ‡	äày`ók:[I¬g{ä¢ÛØ«ä$?C¤?‚^D œ_X‘¾HÏ¶ésBç†„ˆ ø`â4,ü=/…»G&˜2Ù]kö)”1EŞ¥zÿ˜¬•§ˆ	ï[¥:ğú¬m’[áìoœ^Jè:Ğ“’ßZô$ÏQØÇé"Ğ…-O›3SjÊì–˜»•@LàQù`l½AğSHÂN,ĞX‹‹ôúæ„h›¬]­=ÁÒw<w¢°?4ÛCòuÉ(L@ÁøÈ^¡°Êˆ8$Îş`ÕbK‡ŒF¬õ´–š¸zQ5y
2¯9ø6éğ%g=q¨ªÉİ*ez$z<İı)•“ZÈòÆ]#fu€éãÕùUı8/.‚ÿ#ÉxFcx¼k³¼r2¤±¼¹<ûÌ#YT(a×‚CU÷/eá_ß™9DÆ~@@¤…åÄÉm¹À“-'9 šN29ll
"äØ¾³1ÂüE«~_ÒÑgZ¯Hl)(Lk8÷õ—iq´uVVQ­JéÁ°?ŞK*¬Öê)_yôˆÂ	Ò@-ÆŒ:>(LmB!†»½î.ø–^öÔÕcnœaµºB+>aÓô8¨mıßTU"$dTgØ2véHôrËC#U„tá¡HP‹Šçkv"’†×Wf=´ıuÜ³`*1ò=àF?Èi1øî
–6 †6ky,ññ¦²Sµ¾³ûÓc7¬Ê‰Yßåô[ŸşnŒªb’[‰òSŒf?÷šî„Œâ8¯›÷ ˜‹rFËİµñ”/õ…$4Škñk{^Æ§4yº»–Ğü¡R=°†{îU©üqüìÅl6ŒüÕ·@bè¨L¼æ;äµ]60ñs`Ylµ²t(m¶•hş±ªs?l?¤•şD[È(•a6Xy(
‹7L¡ìÍs¿=¤œW´ufã®ô®
\‰ùx|àhñä‡2§*åÕu´õÜ‡=gHÍv|ÁSÄSºEİÒÂ¸ãi{”;Jyëá‹5ï*¬\^Ş¥®·hâU¶¯A`ou–†E0Zd–®ˆ8&2ß•ûÂ‰Ì³“|y¤'?8ÖHİo±	N¿nœ7€Ãtªv#¹À &€˜-T(Kÿª x	ÍxGJ®ÀU¦Õç¢¶s¡Ğ?ö~äìwïsjz×7—Òº³¾ä+s¸À‡Ô‘`ı 2 '|Y–ó/©Â‡´^[ÌHŠëğ$ñë´"[õf§­œ^Ì/sÃ—£SkÏ¯-a¨a#Ş]×˜¡=£:¾’hŸRwau[b¥trØ*\‰A8ßÙ‰mÕ¸†ñƒ cKHñnPl `ç¯5YáÎn¯ı«WR“åâİÌ	Ór_£×3–MÙé¯EL+Ôe«ò×+–êœY@«­èĞ‡gtMWŒ\ïäawß&rR#ÃÑBÒˆ$¿´œ¥ÃÈ;ø¿»I>Í‹`}	×¿ëq:Xa~#À"S</  TAåÚÆõ~P‘0ë{@ó&ÖÅ£Q+¯±×úCÓrdÒ?Ê©WáWÂÇC ¥;½Yæ6d.	³
ÅˆkşÁ»DëE‘)]fšt‡²Uéı¡¶ÇŠTïµwDC§ÖÈ=RğğxÁÅŠÁpg*èé±·øO4^GkÓ¿ì™9?‚¶†Hşc—¥ÚÃÉHy•B€"}[” ³5Nƒc×	)ÉƒSå ym‘Av¾†ÇÑ[h‡¹X“6r„Åxº)^kÚ~îp¿:òS"'™Mü_Ñ­Ö«Ø°Öu¢{¬É°×Ó‡/àäô!…Tœ–'‹?èëÉä! ¬ï¸†;ÆŒjï¤P‚‚’Ê˜¬dİÁ>°ôíÇS\*,¯ùÇ€›)ÉÓÌÿzí‹yçú…¬¯‹Óş±g[åI0Œ¯_;ÍÊÈlÁ!„!aŒğn‘¾¢Ûî*j-Ê9™÷Úñ
õò±)f®pâ¹/€Â2YÏs²Å?q«ïD6óY›ªD` ¸À\t“ö«N•—4ŒMÆ§‚mmUx…¥‰EJÙÍ.ÏÚ.Eú]F òÓğ‚©µšrjÀj[#¯‡áP<½”zåº}ŒWn¬ã ] ¢›Z-DH$½XG¥Ñã¼æu¢¾©ÜçÒ¢è? HéqÎçêÆš
F¼Ëğ¯TÜeB>•©x&Ïzåóä©¦[¿geüÂ“İP¿5O¥š~6o­ªÕğÕ¡B¢[˜ëkF-åÒçäx8†«l¶Ğ‘=öÈ=xRJ‡TO†¿ƒD#L9c86h…í±˜}@SiĞá#‹ElÀæE9—g:ÙB ÿûõ&Á·—ŠúàÈÄ<-³¯&¨=¨ÇOY’¾Lcáƒ+È÷ªŠÉİk˜^ds•Ù:õÁé¿*(+0B{ª3hBl-g­ ıGæ4‡2¼Ô$o~Åº;ie7ÔÛæø?_NÜ‰i…U:æMNº‰×v(bİ‘n1^33Š‘ÚI¬Ç5™²ÆY¿LTºåºEU´iÛ×j`ƒ†›]×Íøµ…Fá×„³Û	ï/çş=ã¢dby»<ØÜO`i•ü™•b…@’Zêé Y?˜¸Jìà|³Èn«xH‚tĞgyş-şğº£÷é:MÅø.ÏÏÊÌ£Å™Ÿ˜,ò\û †jŒù¤z6>\§	OÎ»üò¹Lï¼ëB•X?ßJ2ÔŒø%Ú^œĞĞøÌH,aæ”{kåiê8İn°/øpİÖ&ÆæÙÁ¾¢Ç_MßYù ÊKª÷\¹÷‰¾@Ì•i/İ–JòËD’dñ5ö5öÇ\œ!peêL6YâÈhIù;:èìÍšKğÂÉXşD¼œ?­ÿC‡}2_¸T©UË${€‡°lÎÆÙ:êæÉ¤Y ©¶#xÂ\‘LóF~†ş„¤òuIÛ•6¯Ú0…ÎD6Ëí¡¸î¾‹üè…Z¹réQ "Æ.À=4æÇo>èª×;ôüøp”´ÂÄµ½IûÆJ{+Åü©ÀÜMw ãª>Š>>ík«ĞÖê°	:*Ğ¯,F2Õ~ğögë¯Ü!ÃIÀa–­]°Âb2Ï±¦uËƒWË}ó†İ c¬:A>C+é+¸˜‚5z¾"¦©ê¼Vï—“]q]¨äÑªø¡=ô&%b7¥@¥RiyxÚ!£òVDL¨µõ&àèb&‚‹ó”_ò¿*7¥õššnšlÃ´náŸÎ"’šä*h$úáiK)«#x‚ĞfÕdô+›DK´ºA n!~„-kLI<¶¼>ŒöòZF±e#ÓZÛ%Vrx³1o1HûvH0^[Õ¥Û`N–¼hŒ9VõU¹­„P¶9¥sË"Ü³ì€„öÛ7SááF?ÆÒKC·ûõ¡‘îNĞúbX¨´Ù·üt
“:+·Kögûìù÷Å”nàµÏ)ÿrŒLc™vÏ>9~_¯IÌåyÖ5¹Ãm[¸"›¦•ŠÉ‘%FTµ>ŸÂ¾7ÅvnìSÂ Ì}
oA:“ô,QYZìÚ¾¦é‘i€¾ìèœÌ	øì‰Nš;á^?w×V~äİòä‹ÔH¸ŒªNØ7vÅæy®WÛÂvS§`C;¾¿Kv©{ìÑ£‡ÿ©ÃÍ×<jårWÔ
Ò,M¢,4›âUTWç®ÃŸì8¼€AÒÀ´Vàjª¶Ç—`¸(åØ)¹ôâ²¤b+ù» –Jªw¼×Vs®ğĞ9VÕ¿…‡ 4A<İBÀš{ışí®{3ñ´¶Ò!ÎA­ m¡bwFœ³÷kLª +#p«sH}ßaräoi8”Y—|\ÚĞB‰1“d“ôº_«­ªsqÀqoĞ2µäƒ>£PröhOª­› XkŞÎ~Å=Ú$’j%<°%Ş,¶Õ,è&ìµuÚviä p¶^5¥òŒÕÀc‡y’,­?S¢‰PçĞ$ÑÊ`€…0në»L×ÓPYñ/#àl£»iáOëİıb×=Š‡ö)7é”3óË»H°•øÔ¢ØN½<ú8Dã8(æª~v“ªQŸbÊ·¿´âU%ÃåÅP6…ñ[áÛ‰¬ÉİD2VÎx}<Oİb§Å«¿g#së›>–›¶ò³Æê½“ØÈWÉz9<†ÌçåaE¼Îs×G~FåhÆ›ûluBµÒª"¯`ÈÅ¦³rWŸ!ÀjÀE´ç¦—(RivÈ½âÊI]1¨‚Ën¨T’¬ºaJ~íSÂb; úáş&Ç9ë‡jÅò¡~~abå¸µE£Pêß³Çq§öğÌ^òúw`³Z?)ÁÑ{çpCS-NdfÈ+­.Ùü,ı(;déáÊRÑ,Ï­Ya‰-7?+&‚®v»å7MÊœª`h2’åûä¾ïŞ>b¨€ä_zš¥ÔÒ¡íFB®‘~P¯ß«}%¬/óµ±+¥€¸½Qûüÿ¼n˜¬f«âp)ìM_™ÉÇœĞe"7ûæ tKì¬¬‹	İaj¾å|¤FâShıh˜“öz'=y°„cıªÆSmVÑã	C"tHÃ¹á²ÕõeõÒ§ùfd8>c#v*±²©!#ßd_ò‘â’O•¼ú˜ĞM.‹[.[œø¿~Áë«ï6«‘Sä¹šjMú‘á¶Ïô^·&:
÷MıÏımÇÒÙ8·ËI6¡=0Ş›Dœí®iJSs³ÔûÓ41Ã¢bÈ×ÿÂ‹Û0	½gZ‹â‹gÆô„‰Í,²ùQCşz÷`ŞéˆÃ:üÓCn"°¤S%=C"My,Í½z¬Nìz>”H!.Ft—‹øI0«nXï*™xßÔJ½8n$U£|3!ÜÏ7¾8Š8'IO_.%;Â5²Èã¨v·E™*o­*\±pE²Iñ×–w¢^FÆğ<åxüı£œVi$Š­´·š¤@xÓÉŞ´Ôb’8Ûû·§š=‚Ô#ıÎñŞi¼ îc2ÊoV ,ÊÛù
+fàûÈú3aj¥C@8Êzë8Öy)\±°çñVõpUéöfåâ$†ÌJ£‰JO[ÛŒ¢r‚ÕM@jˆV»ğĞ%àb3õ„î?éÓh·>zE¹Ï"'µ¡M€	Z#‹ß]%¡‰ƒh)1±@«6«Eu‘@Ù:£~€ºÆ±	ÈÅØ'}·`4%*VŸç¾ò¶¯ñy9ázı<Ë=ª?Lc¨¶t³Û Ñ‹ñ™fÙpsÒä£¥K	½]çæ ®ş“Ç°®¿£p@ú““	±ª¡Û?$i·`sáùTñJfÈ_|\{ÉÒÄ‘Ä˜Ÿæå¬À&tá¤è¯©"7åú×%æïœi¤«)–0¹é£ã˜;`ş)¼»ØJœkA.íK¢Ş&‹MC9ëÖë(b	£g—Ñš›D‹éôôjŸY{x‘SË
%R$K,?;åÊã‚ÆíĞäšp^‹‹¯7¶-~÷dNü{²äâ‚|š%Ä­bT³lFsÁ)&ˆ÷³X`ñÇAQC6 çHñ½{¡QLfß• ?ÊG-v¯}İ–xv•°‰¹f“ôqKõ[HjAAØÍz½\¢zÆ"ÌîãtÉ+/ïô4Ò@â3™`$y€ê?›¤ Â/òx@@‘&OÅ[V%
JİuÓ'$hŠ¾XNœ!¼‘-†­w,Ú§(L{¸”RN¤Ü(Y—êïá&5á±Ö›%ñÁÅN„àšõ çúGX(šÔæã<ş
Œ4İ< dùüÌ$¥Í=q8šPĞ¸õ½¦Ÿ†´ù×Œ2nFdf{Ô¬âæbyÖù „A¸åæw¸§>‡3çè3H­S²(Ø©*,&½hBås“±ÉCûG˜1ÆŠà)û#lã•f™ZÔÿ‡Ù×Ñ¨½'„òZF¼ıµc$9ØÏĞ½Oô6+Nò¡%h7U|ıÛ¼Z…íĞ_Gç"?Sº—]xéæÛÑî&fùéP…æKêxcì”:	^ğßGzw¥Ã“WÉßj	¨îÍÑİ‘Üà_Â!³ßàg™Æ(Ç”Lû!2ç©âzIºLêIè[ü~\ï`0»¿W<¢¶7áÿ¢MË˜–?°Æac
‡‚+˜ı”PP²+Kcœø©„„t3c‚ÊºFúIé`2¼B§7÷B_íaR“wû]D¸óög“·8IšÑûì©ORÅ's‰Ô‰ÿëô-ÃşgÓóÒ½ÜÂ}´öÔâ>_÷k‘cãÎµhñ7Ÿt\¿7T¨µ<]Ğ ÌfÉ_`íÜHØÑÓã9¨f?_™êĞ4ì©âÙGR-»÷°¢ã‘<¯ÇxCëöSr? ñ+ª‘nÏÏlşSî6,xf†åº‹{õb´pB!€ÆNuy$ºk'¨ëÍ¿¼Îp/‡éÈJÓ™¾,ÔU’
@şz%ÀÆ•K/3ÊŠß½ŸêWN»o	öùÏJäe‡e¤×xÏ4V²C2vm¥¿(n¬#a \úĞ1o÷§Û™ÌÁ‡z’&Éõà•æø©öV”^O(fÚJË—… ?nœJ.…'±4é³JF1­ËØ¾ç+”ß0åÀ%›‰mèkiÎ7‰à#Â–½‰ˆÂk†ŸùO×*ÔíØ“¢[_Œ-áıÙ÷ó-ÑÎ0¢ªİ=´tÀZCºRQ%’ÈvŞÙÅñUß¤5âíÍ°Y¿dß!úàRş„Çp}$ÁîgÜŒìD¿<ş‡ÀEÇ	1¿Hùª_ƒSàPÈÂìÕ¦¸tmÚ3EáûV®©º_HK°áÕVE¡î‘‘š‡$äqwÛJ&C§ÒQH÷N$m®Îk#Z½Øj…@\¨4›µ}½YÿqaîëÑÂ†»§³„ìÅã Ä@˜„’Ä÷`¶¸…=ÈäY}]†R6Å…‰Uh[är>ÇQÁÎ''ó5šÜòÿ^iV°¯å˜ËD	H$L¿n¹ŠóÙ¹`Æ’f¯ZÜU4â Æ	‘54cê³[$ òè":Aå“^­“L¹"‰ô½OÖƒ€ÚaÅÂœ¢ÛüQ	Œåx3º:qÀúsómò¯&É¯#QËšÖ¬ÿaèa³’ƒ²'œ6—v…ƒß†U”šø*9Ì‘âi+0JÓIQ½ŞµŒ¸¼ÉŠü;¤Ø=¥Ãfè\oË¡\-TWã­¢,ñ'PˆvÆ{"Ç4pÕİèÆÛbT£µı7’œ
XºBd0DPÊ/ÈVmgPT—‰ğ§†boõéÀ»0`*DFWWÌ³¼•»ãén@-ë¬Ğyè.šÎ—øMhŠ3Ë…3µó¡ñ_+F„ªĞUÇ`Ùø«‹°*Ò¹a’bm.ùùk“.âöªZ›b"¼'âBı^µ¾ù`§–Y°ÔbÔÈµCJH_¿Üy}U±©{âÒ,|‡›İù•[ƒÊtÕgµOeªpzªíV*â
ë¾a$òÿO+æ¦eØ²µ«Æ°lşˆ¿åøg<‹ïîná³Úç¸lQY»¦—F™ÅèšÊ0}Ê®X=]ñêÎ´ûÓ—kqu¯èËC"º¦Æ:«ú‹%ŒTr†´ı«³à*…Hu¼Ó›ÀÉ-xU2¼	Z¨ë.)ª0ıCFåÖGŠ {¬-¼çOüÕ¨¾¢kxô´ÈægÉ'7/P£İ‘r?°İöò™¯Æ…€r„ãns±†øhÿtEÂ‡‚®ü©_.}E©èeğ–5ògô)>Œií“?‹5ËL§JVÕNa/2Øò4ô
o‰¿kY6 -Ö¸GA¬„×Ã§s"¸šÄÇLşÒ²ŞJp´T±W™@3Å;×Ä˜Èÿù£[­ÙÇØ<9›«0pÕ³Or#/x‚zŸ	}Yyú.…ç_Uü×ÚxêQF^óº§YñlUZ;9•¡2”åeßØÉDöá¬ !¸
³ˆ}&)Øª½ĞR@o•›6¯
3ˆUÅå@ù42â6ob/Ñ)2KOqZ^"9‰H1í¬•e¡E–}‹~$nƒ—jÙjç‡İ:£æÒVà<B¸Ó@©)³;kNí‘é2Hì#<\bÏnhM–“Hİ7‘%®|ù¥ßÓ8K0$tàI ,Üw¨ã$Şñ{5ìÚKPKÒçMUƒŸ«‚@#Aıg½BNŠÛ¼ó[_Ï ãmöéÏï7,±m'Î%ÈGsïøÑ7„ú)#D?÷ZÕ˜sßîê´ì€RÁëfR¸'Øß°v±§”-öò	LcQñlõöõc‚k~mü!é XÀøEûÃcƒƒ:HL-ŸsFG€é¤&FÕAçß¥¦¤¹´Í+PS‘¯zGĞÁœ,¦#ºŠ—Q®ßGzõØÏ•’Öi@ Ãÿl©ì½d4ãHkÉâõW0îÈV&Éh:SGĞ¦cNËk	Ï> B÷¸ˆ[fã$I“‚Hã&ÕTÙh©K©‡CŠº74Cçš¹Üî5í^=ûŠXS%)F`¶Œ®CşF-:ØÅ?4Ğq,ÈïûÏUM´
kYÃÓÇõüŞÉ`ı vë±&o©T0¢P,”±0}RºS®ÈÛÏıgw|háø)fk‹"Ş«¶ğ+µµ¤)À!÷)ÄÀshñßÌG.õ=5U `í±‹»_ÕcÜbnƒ¼ì}qı+Š©0`J¤{½ìe"†]©ÒŞ.tw¸ã$@Ÿ{²¨ÁSäT3ô_Œî9ï	·’œûh7¦Ù&ñËã(«7{àp[g2¼›czNƒ»»W>ëÎ>æûâé UUE­3Î«$®EV¦¦2=TŞ5¢§<ÎócÇ­$Klİ¢ÉòÆ’tÆ™‰'dsÅ£S¼2<¡@Ü‘²D¨¹æ–| øÅ d`ş1S{âÛYÔ)ñ¥bG–‹ğ E™ÔT¼&8áõ÷­Dö…LQYLxºl¶
ap—wœï¿’OvÿH„†Ï¹‘ôÑ[¤M0"æÈvÉ/ZæÆÇİ£Ë ğBJÇH	É zX8áCåŠ3íB}sppüx£Ÿñcƒ‹³ğ(”Ç„9şæ»Ä|z•¼›(ñÜ3tşkYcÍ\Q¬’Ã–xUÿĞ°
l±t»Š·øû- lï ËrD*]—À	Ahïß¼h"nç^M#jZ±E†ÄCâŠ;3EŒÑÀcwÅ ÇRÿGä<ç«k¾uÜû@FÿAj`.xjÉÛÏd@Íeì“‹?äV|£jÕûœR…9g—È„ô¬ÀÏè*šÄ8äóDå%Ë¬¼'ï;Ì.öFypYğS·2dá;!u|×ô SNº¡Ù;–bìÍİ-X%ä¹=VÃ.æMnö¤"ÍÏ¸¿…Ô°{t-Q+\¤¿‚±B¯‡ú¹>rRáŸ£QŞRæ¬åQ„óûüç£CôéS›L0ŞÎlİ/¼kwà©F«+[ˆÊ”åä½Q{½ÆÊR+•¿öÎÃÅüÃ0´›*|yÜåÉ}Øïjù\zÛ-QLv‹ô
g—7_z°?V•­)ªîqµZ©xvğ
b¯¿ ªåIaÚP;Ûj>š‰&ÚÉbçÕ&-BÉæ]*Ë——K>>¸|Š˜u5#ğ()©âL<nı*Zà5"B„pR5¤R¡ñ?¹Ë†ÀÄ”Ä0Ğ.”•ıoÚÖ)ôäº’g‰äàËN{ß½J×11Sl¯ª ÜÂ!Ñt!KŒĞ2Tı©¤†Ôjq ÙŠµrÿ š¢—Îœ=°h6¥ÊQÆßü@z÷íPŒTÏû£4Ü1ÿ…›GG CŒjh Ça`)äïVŸ? „z»¿ïáó3QS/™ Ã©ˆ•)Şõ_mœCšÅ©æ)0¸¸U¯Ğ ÓÏ3dv`i¡Obk–ØÜ	Ã|÷sİ…j³ÏŸ¯}ºöòı)Tkİ@†KÓ¨7›o w9äm@Ü²EˆxÁï”ˆ%¦ß¹‘N-‘e5«[h¾•&qü]:ØXÑ/ïË¥·;û„{Õ7ş9‡$¹õ+`ûª>ÖsÃ
Å`K›(nC$TELÙS¼©õR•ğõXÍÑz’À¯CÃK‚.³Æ9‘ıÄW¬M¤¾ĞÉfhkbŒ¯e¨'ThUúÅuš™‹ÉºÀ‹."4·‹ƒ‘ÉŠ«8˜FåØ˜l²øQ'†„İQ_Î‡˜[mãS•† U“ì3äw%’†ê48¬ùSpÿ§A·1J›’á¦ùÌ,@ö˜Ö&{
ùDd%HÓJÔµ°Î6wÍô6MP>Ld˜ºş±6]ËÈ8‹+äÇœÔãšãúW}³`Å·+2…± ]‚üAQ\Š3}uİu`Pîé7óö¡¦ôÖ²GÎW]Òp?ÿ_æª]7[OwÃ6röÇ..>‡÷QZlÿ°‹ xÁêTi—§¹í#Wbş%áş¬gP²ËejşyÌ½‰°´˜½›é)*ÙÁ¢»3?àgI÷Yåó9"¿uøQüÜWdU45òËÜ·™X¤ı§À¶pHñâ‰ ¡¡Õğ¸#š‰B—˜ÀZÂ1®÷T;©ÉÔ¿ºKš™Î³,/2Äm”4½f„dÏ‚¹Ü2ä"\æèNB¨mU÷‚²¿ò—wÆ¡Lôâyîê½¹´ídÈbşÈ4²
'¯Cğdk™zai,ö¸šËï° Y›CÇö­× ûNhp¥Ê÷…ØZ1!±:¦ğb
c5ä	}<å-@v¬yh‹|3Ø:IélŠNéØAg Ò»\R[3à"¸JéèôY'©Y’–Ã›?¹‰Ú„:É=™õÎÙD#¬Sª–EVÁ™)].·Ü
ôïø–{×¤OE›GX‘âT÷dGÜ…gh3’¯Ë#šûV+Bi2hIâD¡~ofO8o}şÇ^¦}ÈöÇÀsÌyäò›Ş ± Ö¯:ÉÂë+¬SE¿WC¹fƒaJİı%Gu·ğE›ŸqŞÿ.1n‘:•+‹ú±Ûç‡¥¼ 	EÙNêÙ+b˜@ÈŠU÷…ŠËRÁ~æL`;Ù¡¾Ø1ìsüÚÉW•»‹—=X™VŒ¦?xsÛ¦hz’#YÄ‡,%^b –cfuhŸQÃá‚èo É{8î¸ÌL-~ñ¡µÄôø¬³†agÜïb¶-¹z­F>»ıGı¦•÷~Ø7&¯(úl} nIåù£Úşï{4Ãè°g26 @Q…Î¯^¥ÙKL2xm™Çl´÷¸¨×\ØĞ(2x«íA_Å´Ózƒ,h´†WuzÊ&ˆJñ®—|Ñ—’?î^V.Ò¹İÕI„ ö«‹YX­Éöş°{]ë”9ùí bØ$‰ÁnğÙ«šÔªÜ–< E0>%‡v»KÑ?¦3/f]ÄEO&ĞÊ¤Ü@§‹
æ~ÀnH¿_."!ñDûá¸’½„î“s7®0Mp{-vç×üãVs3M·~dÛÑâë§™6Ç=Š2V!üj›î(av‰ÛgksîÛªÆWAä°-“©v”1ÊSp-˜<ùv–µØ3€å{ÈõL'‹âzç ğ¡ŒhÏ,YáÛ-µŒ$íP=–’|jMU%(Ï9;æ¸Œ-¾y¢E4ÓéáäÅŞ¬$ÉxÒ—ŸÖÏÅÉncI_F!l¤1ŠˆŸ‰Á­¬ßÒúFÈşn’Îœ\Øê™»«
ê[¨ÚÑYş™#K”„-êÖTØ„Ÿ~d`ïù‹Nî»vf-¬21Ô3¨™¾—0ÍškŠùgÔ÷Ûd¿W.²üG%$èÁjÿpZRÅkŞ78MØ6J…ÎÌ›-şÿ¼È˜œË#oÄ*âQÊ9 ¯İS…~4´!•T*É¿lzBŸÍëˆäó'mƒ:ÚÌh‡=¾A “Fò–¯#8@JÏ|®ğ÷ı¿gx/%å”Êo8l‰ ;Ô‘•Û[ôG‘‘ÕD¼«ãâ[w&¡N…ä‰~®İºq6Rğğp¶+ÓÉ©*à§+İ0pÌÊé9P­h¿^’u[µVâ¿%¸»7lê³i]ıaÂÆü¹#èûÄ’RÑ}
o¸*q{Ü¼zp¡UQûK
µèdõ.ç€Œ¤,»¤*â%¥E%áÆÍ¯ƒ—KÄ`4V"ñ¼å’d¥O®n…’êá|ôß¬O0¹’Ú`»ğ²Ÿ¸õ‰Èk/€Â<.áõ®"ZîZA±·¦JïB|ô$Gdù§
»¬Ùğ$fXáqaZ&ên³(…Íú9•§QR”(½‰ı+ñ(z§' U^î¯æNnÔ£ìZŠ¿ıÚ#Qa(¾ß¤KöåŒ Cfp§|Æ9Rº 1ï+Ôf5ëª°5¾j<LG‰m‰XıDHŸÂQ&ñ bw$ÉU9ñ^÷ÎIåV!t½ÕŞÕp¨,WP°©GN?
Ç$Ødm!í‚íµlïçË¨6ÿ	â-_ nñä}£S›òhİÙ.?µ)i|û—¹H/ywõõ"GRK“¡?{˜ôÖ–ÒŞQÓI|ùı#“néõdó*ÿ‡üt1mvô·ù’Jt`ä‹şhaúÓ¬o4×ÊŒ¬r¯Î¶ŠCtX$ókÁ\ìyO*'ÁÔbšÔ_`@WOóÔBß˜&ƒõk˜&<_”6_AweKœôø¾úî·Ë9ÙÒÉF(Ík“ûã¸Iu†dŸÍ!@ñ‘_5Ó>æ›,’è†ïDk
[!àŞ ……(Í@«v)NâR~Oh]XÓÜDP¶P˜|¬üÓB£xÒWKî«ü·êAüô%«&ú"iQ® 6¬0Ö‹ápgV™à}üs´¹zÍû®=0=Ğ%˜a½SË––,*$AaÁ@ØNæ£~;›ÒtÈ\éÀòÓ©sÕ8• ³ı8­u%‡¼ÿËğÛÿù¨âZ½x¹/©İÆê–èª¯»(ˆ!HåU`òíşíh•‘y”I€ÉUÕíI¶•xŒ€â®îµ7²lÆ<™eì÷cßÄreûkİKí}’Q¥‘¤­õÊjÃõ"MP£§Nñd"…ı\à0ñ“ÕÅÿØ>²swÚJüu	ìÛá|…4½u ¾Ã_Y&àáÔ§ñ¢Fè„î®¿k!#ÅZn)Ñ¯ÄÎ~¡$˜½¶»Ïp\»}é;ïtˆ©€¢OÖß¡>ZşÌ=ÄR}¤İ,º¦vA’ƒŞº¼,ØĞÙÂV·4îRğ<uZˆ.»$ĞKST“Rg·òHKŠ ©EB“1¿viéŒDı™KËÿu-æ½íbwrÒ2x»ePû«ĞNN¿7¶ÿƒ‚ó9–thÔºäÍŠP£qlAkRŸd§q5ÿãO¬‚MÖáæ«¢—c$Ì2iˆTµ]ª}J4÷Ö@7ÿvë°BIK­OŞ9¨(„3Ïãr°¶›¿ÆØWÃß¼nÊ™kÀRE³I{­-¨sîĞ	2ú¾räêZÍº®èù—İ}[ì]aŞÇ©èÌè,„Ä«ëà(É4FÌS'Íl”Ê{¸V´p˜4ª-ÆmÇÕ7ıSÑ>„;‰­–’ÓôFjw·Vã‚
ßcW„ØÈ2Ğ2^ú·<cğá,Y*rõeş4ñ‹ú-âø¹Ê¡ô»(%ë3£?&µÄã	q}x3ù@³d™]r'¸Z3h í–øw(Gˆ’Ø&¾ëVÈÜ¡ß¯ˆ<+Ä^)ÊóÇ6Ú“WÇÜSŸ½ûæË ³İ@+’qXzEÃ%¼¢şÅd…ZRGìşèDâ·!Yó¯­øFætsä1İMAºÓ«Sw²A÷'
ç“Xæ{P†?œq+k’%A.Ó¤Jà·®†Ûì[x‘¨œê×÷FÙùzLë‘²–y{»ñÇºÀµ‡¤<â3òfŠ6Qìnì~éBO¹Ìp×}-Sá¬‚Ùbõó~†øcùŸ`¥4Îø!Piı-FpârgÚß›õf7½‘ZdØî§›Ö8ŸFğ–¶Áı3P±iÓÌ—àgk“ÂÔ^x(ÆîyP|f…ÒåSKká@p¼OÌmıÒóFŸxYêYõ¨Œúfá®ç{üåÜJ’nH¤ôÌ+ççoÃrC·’ÎM1›úgî·zâTè¥öfÔm?¼È‹•œ·‹h"?–|£3H“ê‡b‰<}×[j@%±ÌÔl3üÒÛQŸYO  ‡`bîzµ%³ÙŸé€ÿ¼¯õ„€Š|ŞfW&¹ĞÂ#–ª£¹
ƒUºévÔ7„š¼ÛÈ#o™Z(ô¸QÅW²4±n/o³ç2Ëb´D™ÛD0dşäÌBe9ùú.Dı@ É?¾áÏlÚaûO[Ë/·Y¦¤Å@ªëßa†>q–*!„N<U‰€åŒØi(@ÑÌ‡v	ÆåOécöPàWW¥ë$'ù
ëğşàç‘È»™#\\zuşåtò¬ù÷ìØ=]‡µş®ãW‚Q İ92ìÛ›ÓP3@4¼‘¦,åõ(á¨ûtìcäİ÷·hÌXõÿùÜH>Ó”^)Âİ=/ù$ÂØìg
cµŸjµ¹.ˆ±S8³úRÊñM‘;1¨â;!ª}Q”åF,Z‘§ª·Bª"ª-eãE¹ù“šn,d5ü+ä'“-pœ9v°!ÃĞë/ê"f]I%CíÒ pİï!‹G…Ê¬åˆTÙ¯}È…9öµäº!/ıÚ::ÒÓAjÈ3j}Í!^Ã*İÍgL¿t×¦ÿæ®`Çû‘Ğ©f<ïÙ!RıøküíÁ¦JïåIÜ?`1J¢¤HşÜÇNTÓi6ûÓ:/öæ´EH!İ“sÌ®óK¶QÉ~-qï5¹­²q‘°?LÆ µñGÀ{wh7ÇË}Ÿ…v3„.°3ZŠÊ±¶ì/ê:×zùr)q­µŒÆÚ×ôÙóUUx˜N¾£A”6÷ú‡¥`1>×vsoáÛW ƒ’ª}é­Ê¤<-0ºŸ€Ä_I¹Z0ŸÍN ˆÍHTzå¼ºä1 `KÚhÖ©c =	ı¸Zs QRfl´¦O(Î40ûˆvæ¥·YøWáĞìÂ™”\ışÏ*•*«Erû2e[Á8Q4."³÷j´}äzó
Í”'­5D:±óz7ò=¥H‡ÿô #–g9™Ä‘L‹Ğİ¤*¯Y¨	é,™dĞ?aóî:ÏÀ¨u ë8OöbãBÜÜä%	ş«Ùò=çÙfÇ İğAT³8óa”÷ÒwˆFßaölÓßá0ïHJ§M‡¹¤B­7bÃ"}òˆp|…Ù§kšƒ¡ç‚¸Ë?±[¿<(ÎÑc—1¹†½‘Õ5-ú¤ TÆ¼"²ğjqá)Éw{ÛM¤rFyTèÔœGJ­¥Qm£/ƒË	Ò¥ÿ™ù[‘Bè…&ËøëÈ‡8œ¼Àp‡Ï§+—8û0±LŸoe´¼|¼;ÙkôT4ÉÕšŒX˜½2YÁwhV1İ”½lÊïª¥jâ¤ºŠ6j°ÈTÒÑ#6Œ6+«‰U1xûm±1¹¼7¼Uù:¤Sn€Fÿ>¨¤5sûiU¾™Ğİ@—İSæ¦-XıN¨AÕß‚±„˜„·…’²ş{}NUk¿ƒ(OLq©‰¯_t†í}oyÏ×¾n©ÿÏMà®Óû½B1õBólA6¨¬ûÆ‚–_µ¢Bş°wëÿê°í#À8À€jÖûÉuîYü6÷Ç>(„Êvó óªĞë³Ñ¿4eäKæcÆ¹ØÜq’íû¹+àçüšxá¥'¶Ù‚\M˜“.g••šH±·¢xâ.wbøÄ1&É5pNTŸ¢Ø:[—•éb²Õ›_ù ‰ë'Î}KYSğ¾5_yŞX$ö¬éc">\åDä‰{àürµ!ƒØ`€->â)3¦, dO˜ZIÙT¬¬ãÏ9$Bä™P…Â®8¢³ôÍê»èªXÓSKÈ95uu¿Nn­§ĞjÓµkï©‘ÎÜbsÇÑï¶6ÍTLÛ8Nq¢ÂlÁDMÄêOXa£Bâd
pÑŒi·²-G7Ô¯|¥Ë½¼Y;~5^ëhç© ¨Ü8:Šrç—Ò38Ï¾,3½U'x<ñ½™©şm€'P¨ŸN`¼ê¿€tùğÛU'fG—Ûä¸MÂ¿Hk2&°'Sğ´ı#ÁÚ{q:«FÏB©ğ‹f}¾Uodc·mÏÌ£ï–T;DòÉFç9NF6î2læ­x_®Tˆ³§ÎŸ@Øâ§'bÄš³-d8Ã`äflc%ş¢ñ5{„6¶<Në}‡9)ñªK‚1ªüˆó/`‹¹İk©)TsÓ-ì#1ZöY—{Ò¡xŞ/eÖ@Ì´²dÖŠtüCrÅpfxFj/.µp}'ÿ¢Ó¬w€œ•òÜõìo|r×sóºÏÕ¢úê¿Ô‚p1£y¿ƒŞ&ğ'Â:ê›¹m¿Õiäói€éëi³± âéi}ÓÛtáğ˜2\yƒÇÅŞÏ“ÅÛÒ?[N6íÙÃ¬qœrœ`w–í§4˜NöKmh‘ğyO£¶2p9Öc]µê<É¯uŞsª`› “oa¨¡Z½“4É=­ÆIÏè-!hğ[Ç$@¼jW§¢sÒ…×À®¦e«&ƒµyILZæ…úKÎ¥2›aRÓAQšéWÚ’¶z`İµg<;–ÔËYçM|Yv…Êb×œå¡ğ Oöu-öä@¶ÔC"Ò²Bù°1~-(Ş¢PN|W©–´}Tƒ—‡±¤›ìkŒ\ÜÅˆPQo¡ !„7ëÃ“°
BŸİKCÌÆNò`š«<ã’òĞ/™‘==¤8úb+~İ¶—Ş(¨?%JlÔù&Fšˆƒ*kº+n7Æi}ŒÊš–.äóvÃë\~ö¢À$PR+ÁiîKÑ[,G´ÍÑ‚¡Ÿ’zyt¬öáX³ı³–j>#{ùúµÂıß_•£Qy5³½tcË¤Â]Ìsİ@‘ş¹÷ÀÍ(+A ˆ¥ ¾…“TórnÈ–ƒJ€ÌüØÏß7ŸPÊaLaü-.å¿îD:>_ıvçêÍÅ¤|s£‰çR ªh5ÀPáß–b%ÏÜ÷™<¹7O$3×'V‡oùØ—~Ù2 FGVïwBŒÂ×q5•€<Ò |-(¢Í…$¥*ØîÓìiÖ$x`+_CÄî¢‚-	šÊ5£&_0rŞEdğ Ê>ıÒQ¢ú³ã
s[îvÚ»#0–{¦¥ãó4İrj-\ƒw°ş• VÎ…»ƒB+'šp9¿²“~üŠÕ¿²ğ$G…›˜«]ó¨Gô©­Ç<_]z2‚²"™€fùÿß{C\öw€HSÎjxaÂÄ,„‹t/C-xğBmnü°¿ãÚæÊC1õ©„Ø”6ÿ‘ëa­R3à0–=erâ$iÂûÚÑ¨+!\eµé¶nJaä¸`PTzÃŸ`åçI+ ŒÜ?%ÅVEñ‹,ÄÏWÌû¸È_È!³n´ß:ÚùË*& n¼°°?x·ûÀshÕn<¢Œ?áÏĞĞú€ÏÜrµSš_íaÔÊDÆãç±†¦,öë;ç[g³´#wH¬^á'ÏPÕè™By½¦
3äÏ!zRH >VÃÓ\ŸçkR9ZÚ86VæÈ>Ù¼güw&4úè%[z?ò(ÒV–Ræˆ(Ù6…\˜¬*ĞÂê{(â«cLıéq0ç	Õ¿Æ
ÄöIÿÏ¶Úê¢›«ğaÅ)åÑc°BşdódäƒEô> U60‚Wá	Û:ªŸ¨*K ’¥aA·)X‘ş°©jV#¡±|²YB¦ŒÁßTYõ,Ç	+hTÈgıZ­2@#†ˆy&’º)fqD2²Í™í—´²Ê§Tûkˆ)?¦äyÑ¶¿ê@˜WÑ,KÏÛ5S%ú§+Á©Rš¼ºŞw­ó#¨ÁMıå[T˜h?pJ> (¡©97¤æ¾*½ tKİñåEç]Ô+m»!¡Ÿ,[„­Îş*q.ı-ÖCIä@ŸÔÉ|»»'€ŒÄ¢–*ò–û{Ø%J<¾ë×X×¡Ü¯1ûL–zú2ËzÏ¯ÆòBeC¦+­»Ö§]©’ó—Ís«…â¡'»JQ	ü¥1vjŠÛ|­?%'âH“P
Éâ‹×ò+böhÕAY¢¼i'1yVœ(wí£å/(a–Æ‰¢ñ§ÆuáO™¯ï§¶+ìklLÚ¢¦LQ(Î0OŠ,&AîvªÚC,zÎĞ¶Ÿœó£>ÔøŸJvZ6FÎ³:Ê¥qM¿ p¬=£èé«{äp“õ˜_­Ä%¢ÏÑå5‚—²~¡ô§™¡f²œ4…«â-tIÆÜ]©	Â1Êkúz9úÄW£”iµû3M«sò†M:ÍÿÃÁGÅïı DgÁ°zy0Öt‹$¾ši§tÀíåÎ!wøo¹FÏÈ;hB}¶QÔpÖ@Û9Êá¶Xé¡Ä8Õ)¯¼"‰°,×ö1­„‚ës:©Û ê6ù^»:Ûä ²ëšş(”vÔ± ˆ¢&é'”ÿpÅ¡ƒäUC a­=½H•Ó<SŒãaòìg3p|ÄƒD/7¸·…®¦º7:|-·»Î·¢éS÷ÿºÑŒÒ”µış|¸ÔrÔõ’eÚÆæŸĞA›ğ~jM±u¸yécÔIÿygv%åƒFìSq
ÍúÅËš³òÔî™¡¡léRaÈ\uojå‘»÷]ˆ”>íy­ XŒk%74Ìg:¸Ñ‘.Èó¸»Âúi/¡P±ë4œ:³3;º¹Ó¥¢*8Y(Ö¯¸’ï‚#@ùw«!˜Ü°mt1e©X‚eÁ;Ø~I7°ËÙ0®íÁ!¾:=½/ş[ªj ÈF_¨Ïó½ÑmW*¹“q÷oz1["c˜¼rşˆ×z Hj:z½“VÎÙ)!e.Öç=M0ŠştÑQ¶­œW_í¦î–˜ª™Øì+CíÒ¤ÕXIO»8âÿö-ZA,•0Œ&~şóèP.@Xâ”ÔbíP/â%j$Cg†mÉ5’ûá>­ôôŠ
¡»†­ëé{ÈÀÇ€<o`àHZœio(í{9£’¹œò!ğ9›Wòd“€¾4=›ük:p¹ÓZÆ _(tÿè¯æå,
ı}_Ù¢^œ‹1‡…{O£{|•]¹Á€’(Ü."	%M°|c€Î@{Ø/8»»µ.o¸_Fäû9Æ¸=ıö<”Â>$s~bÚp†YkÇ¿Ó÷q÷`¥2B¡gµÍHÂûÃûE\ìÙa—K1ÌZù<ò…h/ßĞB‰ØÔ†úu]–×¨Ÿ¥Ô‹<ôĞV:C·ê×ÿ¶œ</j?^â6vâİ-”¨é SYÇãÂXüÓ±JKİ¦â/u¬Õ#ÑÚ‡ĞYƒHç=¦F	ÿ˜&0ß/¤×8MïûFÎN¿Õ]`2uŒSêÂ\·w€ŠM.…#JK‘.ßcñÑ€¢™e²Ê&ÆîÒªÏP4€û­¥øç×Dy„µ“€™…äªóÈºÔ™ªçdd÷âé îZ£ëZ~Îüî‘-øív!
ø¬¾¼UòáL<`‹%Ènn™ò…ÓL Š«R¨‚­…bôæÅj6#NOÍı´){)kyTRÉ²)à °x[ÙıV™ğã¨¹\>À#™!©v…8à^å¦şícÎ`ÂŠ˜ç‡¤Tû\\mÆÿ¾ŒãÀQıhvşšÎøÚ±›"tø÷bÀï„ìÁ—D6è™CşªÚ4^ò@;?S–¶Ï:êæçDïz% ~9V­$ş¶bÙî¢.,Å]z2¡ëâÁ¼VBìp3Ç‘ş®{Š[#~—§Ô{R0K{t/o •`w¹O	Ëò‚˜¥ï¹¤	s9÷ÿ¹8/¯cˆÌ#ò&¥{Û¾Áş `ÑªZ•fÅ~…´ °ó¥–œ›g6l*Õ¹«h¹+oò”šw€œPß6e­Œóı_ÊÎxdï-ˆ¶İ:ßáÉ¦ë‚Z`Şu€ÕB’'­ÀÈÁ°S²É­†‘Ö€õ`p~ŠíM,wé…Ï;ÈXİ%84,A£Úéu*HäX¸t ZV!G ÿñ–¤å×CL9û¢7aräïÉwr’>ƒş’xV…!A½V˜´ÂbıJZXØÁhÒ;¤Œª“ÁçY™ÊA4¯›tW$à¾°´\^¿boz´GÑ¡ş\»”]FÄ÷Jz-úíçñ¸"…¹I¾xÍº3o0kÀV§$‘hÎßš#Ñê„•bcYÛ"ø­¨ Q™YTÃş?%2¼ØÃ™¦­B‘ 
*·ÂĞV%5
vdm(¸{àÕÇzz*½&Œ nG¦ ‡Kì™ø‡m»GE~_„ãµŒœR°WÁb¡'iZ¿6ë¶sŒ$©~ªàçeZ¶ˆç¥7~Ä²:leİÙÊÁ#YƒæÊğ¼ÕQw^İ+©{é­Şä&Fáİ‘ÔVİ`º[,-	ùZ¶(¶!ãNğÒ0ˆkUQ¸8VYËY!¨ 9ªŸæ^ëyû9Î	IìH7Á"Ï¬qê(‘_·U`]Ş‘²ePÏÌO¿üğˆ†ˆj<Z·«·Š­!î˜„‹ÙƒÇŠŞU”Sá£@VÚòÕ(#Æœ€n9šĞÆ-{^mì¶@\ğåR-÷£3šàW9øƒUÛÂ¸/›I©Eæö‘ÿH¢´ŠÆ²yôÎ ö%_/(ú@dÎ _Ÿy_­‹{g¨·—”pò$Äoxá]b3›\Û(0‡{ÌÖ0É¾qïÚ*'OB…Ò6õOó‰†«¸«ô3––JÈTú1”§­¡úTUBF¬)ùİvH¬ôK;Ò^Å˜|u"ÈÕÄ×Aæ{ÅQ¾DNo[¼´"‰¨áå6çÍ³5(ö#k¼%Ü::±#øåo€vz“	x's£ş›ä%W)İ®@“ºî¢Ø®« ai:
~[-gfÖp;9İ (HY.ò\õÀ)ÅIbÑ ‰Ìuıö„üã8Ki2>O¬›8qÉ%)¥øª”#×âæ»Újfbç™öÕÂòÚówÕ3ˆ¢?eĞh$4^üõkûs­ò‘4‹Mµ'ùÿèÿÄu =R¦îv0Ê«Ãzí6ª†£üŠ£ëÊcÆQß!+OÚM?¨}ñîàx?æ“)]’bÎÖ”›”@’èÖ
Ir Äâ›…ôş8CÜb¯{é&(8®±3>wnjÈ®ql¯®¹¨G#}.{òŠDS“'xOçõlÏ5e
Wrº»ÚGHüKhWhıúÜ”T¿/t]ÜÑ5	·ö’ƒŠ]|:ñŠßÄtQ’#Ï‚ø‡ÂÜ‹ÒÕå¨‡¥ aı’Ãb¨ófê
{xX†Šï_»çç{ek¨yÒµmÔ«|'è¸Zı³WÊÅ†0õ€--|a˜¹¨zÇ¶Fóé–EVìyÓ~»ï[ q•¶mAG<<_Ö¦Ñöâ ¦ËPm«ïi+âRÊ:üp2•«Pµ¯3¡KèåD‹–ìoÄE‘Ç9*ŒOß9vn0ñİõ¯aÿª>êé…ßı|O7âû€á«|3Øò;ÿ·{”Br~_B*‘ùC•Í[m}r¢|‹C$)šôÚÎ¯n¥ª–ĞA^_7i¥Í;=öğ=÷bdû±aú@e”o8®¨Ğd.­= Ñ,†ôã;/HËKš±Íß+NK!€£È£+€Ó¬æjá;TM€ô¹²ÁK„ßİÏßíÛ1ôûàuX4€´²ƒı±Aìk_àD6å0ì"MœylkøwáMìí ×$–ägsaÉ uÈù”Wt5 Ş1ÅfãQ\ã:Ü¨‡í‡rÒşı1Ù‡wÑB?D_¡ÔF)òz_í…Ü¯­¸Œ‘sÑÿu¶“€è©Pg=HD®§ëß?êìÇ€)!~¶ò.K	†	J)UèÍB•Ûèmƒ˜IŒÍ²’§ÁqÍPĞ$ì‘(×U1Æıqµ©¿Qhò@É-9A[Ï˜2oÿ-Ö/Q÷Éå?iNÀymÇl<"Su¯^ÿ×=Ì éÍU®/4QRŸí”ÀîC	m+ÒŞäİG—{¾×çÎğp‡¥W|ø[]Ã«’–°‡øÀÛ¤F¤\ãXÒèCPKx«§şø+4Hw¯_|‡Ô˜E-=GÒÖçk¾¶‚Èè©×Âe›lGİd ±Ù¹„C¸d….’-"@‰û>º©ãQ+R+x*>|¬õìÌô7İ¡a¢º	úœùC¿Älüyg¢˜*œ'6æú7j5-‚«„÷¡ûİéŞdğŠMG(såwáÛ™¬è\“Ğl|›Í†E¨ETc¹÷|Ñ`!f_B2JÚ´4Ù…g´…kJ¼
Á¸#[N}X*ÀKàò©\øí4cKnnÒSxWUÅÅÄ0jQÿfÊKİÉx ¨³!çş[“_M5²<ğìï*Zs&—·*u     adûıkIDî ÅÏ€Z&Ï±Ägû    YZ