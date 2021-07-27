#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4135448582"
MD5="2b1a06b37c5245f6934dbb47f3466a04"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22676"
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
	echo Date of packaging: Mon Jul 26 21:10:52 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿXT] ¼}•À1Dd]‡Á›PætİFâÉFÔAÿiJ3Œgâ-Å@
Ç”ø!aïÛÂç‡dÑìç ¬ °’pW«6I*`$ÖÕŒˆ5ºÏäêsÆGNó>úB1¼Áæ¨VMêÉrP9kçx ´¬˜–è*œ‡Õ§9•?Õ§§ÃQ›Å‚[oéR!D*ŞôåM##÷.ÔC;·¥Şi„\a1Ş[‚˜,³Ÿùk7’©·]®®Š¯İØ¹Hv­‚ƒÇRoØc+·²ZİÖ†û’ìÁn4{¡0Úíà\+±°ŞÓŸêÇ4k‚–`¡nŒ Ïq¸8eâ`Wò1F½i©—H®Ğ…ĞÅKÚVT®Æí¶^NXú"ªÆ§V–”¢Ğk
ñàXµÆ§d£!J§ÚÉò÷Îy	SËÕƒäC§G‰Çè‹ÑS9_÷W
ŸÁM¨úÛ¸”k¹˜š’Úd¤VMJXNB¨æeñ>qÇ°\¡•À`­8¥° 1.¢ş-ì;YW._›»È _Tr¹ÛÓzâÁA&¬¤aÖûq<È½°ÈÕd2)ß‚ÖÉ°=Âx&F{JŞÎş¶‚k+œ~’n¼ÎØ†¢£"¨‚4QØE¸ãë ‘*Ñ¦Bb#Ğ?"9Èô€» ö8©i'sÑ³Ûïz;ŞivÒä±µ.6÷ü\²6&¡.‰|¸2J©t²‹$'÷¹: Q¨/¾Šñ£SA´·ä4GEºy¾ÿœƒv(ê|§®½šhU_^äUöÖ„pûô¨a¯-æ „€;mS&t\è×Îò½qs	’!Gbü×ÂUš}˜F¢³¦ë<mŞ˜‰áí›zÄF+ËÈŸôlÓ!ÛLoxE)rV˜Z9ß€ij×¨-‡€Îÿ×ò²XM°×™_!Õ†©6–aéÒEÇ’ÉfòúæïèÓ;ù"şuî¹¯‘^ñ–Û*LM9È}©¿nß°f„ëT.PßÙO•­˜GTˆ{w=ÖoUdÒØÖ7dê]f?z›1‡Ïû¡•ÕñÕá½Ş¾RÇºúà	"Ì)­­+úyg"YÕ2àêğzwñ÷ıÅC)š¼dı×œ€PKÆ¥}¼¼eæ£—nb
0u“Ï1ë<,pÍZÁ ™1/F´Â¨ş±£^]¥¶Øqz3„§ˆw,7‚¿A¶+fŠéÁôÜ[›‰ ci>Àˆ£Öˆm³•«qbò!P‡Fl+vÃÔCáÜÑ‹
ûÂF@³›T¥·¬a·í“İˆ=¸§	
òàÎ:$„5ûîYM¨Ií­Ûƒe’¦*QCào@·H1¦›…B³`ø¬XÑªÎ+İr¥â1òÖj°*lY‘¯0l}ï:OFÇm!RÆ´ÇMÙ‹[á¤ô‚fXC´¤^	C¬Ô¤ß Dıcëq„Õûb§|‡17ƒ •ş5İoÇÀO¹ûÒóŞIs(šV2">V¯ÃÔ!¬§¼ˆ4ÂvSçÅàllÜ¸¼wÿ³Iç
˜L
ÊJuƒB%¼ÀíçaaU(ˆD“)J¢óİÒu-üZGØÉRíçÓú#Ö%äy¼‚âKPÖ’·9¼ÇŸyfxG¾=Ì§9óùšÜq@&ïésËÆ”+Åª‡R·OJW¦˜uÎv‰ÊúĞ^kZqyÀÒnz´Ie	éËêJn^V’Õ×ğQn-¢h©şÏ)£ƒ0¬¸f#ü„ğ$m¶ÙeùMïzµ¿öÒæSL²8X=°sûmaJ;‚äğ¦é T÷’Gußİ§õ]„CY’-J÷Ÿˆ¿Å’4}bÑÂGr€Øæàò|h*º³Ï‹ÎXÆOyÙ>úR:–Î¹é2µ‰Àtù´÷©ÇÀİìt§ŒßÓHËof@©›ƒˆEv,¶ŞIÆãŒ{wñÛ¡ZåĞí«Å2­F)íĞ9~œkJ"Óës@QÊÉÆ>¬Cê2cw¼[@êI}~±9XlÛÛkÍ¶p¦Âu½1ÃÈŸ'Q ˜¤†Ï4´…Úa òıÂÂ™õúh¾+‹:ò²íƒá «4šfÛu9Y\Ş¨ŞVÓ²–8xï8ù¥ªjıPg¨báh…D¤ ú¶¶ŒOkı`ÅÂ…ùÉ†Ö±&µ•f2íÊî±c–Ôx87ö ÿ§¦}…°>¢‡Mz4Ë»@°xÏx©Õæf+şŸjy©Ë Hj;…Q1}æùêÍló°¥EÚ`ÆÖ <Ø}o. æDßÑ£«D¤Eš/O|xúUn0wm'm‹]¸#tÏiêÀäû	Pô*Í—Ê=€=Ÿ«ŸTù°¡öŒŸ+İ%NìUEVø}ßX÷"\0˜”ØÉ®«İ wÅpYFãÖ:ÌÆTùw€Êm«Œ6o\gérá²vÉ&·âCunÅË¼i‹%SãP<A	Å>ví¹ş¹›ñò˜ÇxxæéJ;Óxv#6g_¡DÛjÍó‰ÏZ½â=éÒÉ‰éöÍ0xhWÁïÏN<^yV§ş‰9Vš“h8pÄÄ5áÙÕÖP(÷¨ïGdÀWï°F,´V=WxqÚ´^7.şdòõoaGÀrmH%cFà<{åFû9iqr¯ğëÆQş™Pƒç¦í‘“ÑDn ×/ìŒzMÇ ²CZø*÷ôz¤¢Ğ¡ø	GHgæ&€[è8ãĞ¥©ã‘Ñïí*R2­P)	 üA}xY#˜€iAğŠa5!Sv¡vE%˜ã¦«t¾0#V†±g»ÎmÌ«7 ¹lS‡Í¯¾;!âI-SX¥ñ®ÓşlGO¼4U	á^€bï'İ¦7Jëåkù[²°Nëı/Ş`*u¥©¶°8ñG½%ßXmrKVğÇÎ!~ú‚9É3Ä=CÅIû±6Ñ`O1pz¨grÑ1œÕÖ\ IÔ—¢˜İC°uª2<ókÃKĞ²Ÿ*ãW³]BeãÉîªmgÈU?_aÒ¹ıë¤¹-‘„ş?9‚ußÎ™¨&¥»Ó­ªó`¶<óPºZIğŠÿO_á/cŸ²ç	Á˜šòß–g]a!:e%+²†Ûc¡bƒĞÆøwòH×ıôÙ`˜ÿê'bµSš	*½ftE!”ˆõŠŠö'w6¦ rjÙ‰N½´d0äE2é¤º;‚•š¯ŸKâ§wázjÏZ‡eJZÓËËn3ãOÄê =ßÊr®i
ï!UmõY®6%¥¤¼TRdëÁ+"€;SxäëùÒoŒœò»ÇAÕjwc1ØÖ_/¤?é]op:@Ìêš¸æW»¥ÿrT¿2Ÿšãò¾»:k€G=~Æı¾¼&]ºóÛÃ=bÓRYDÏÜñ›´‹I¬;_l,äÃ›QĞ€!œùvqT¨?ÖâºJ3äÎÿ9	tµ[Ù%àŞ+[êÄHOOŠ¾/¸<~ß»Ğ5®Ü!(P)ö.%;Åî$Vh¸Ö×m‹«Xuç¡şé§zEÆ•İò4Ø@7XÜoCæÚ¯"şÒöH»9~«97xğĞI¬å®SX@T1ãfËf˜<º¹DEï`È\Ïì3	‹¬fi©W—“©‘4A_5s0/[0NHå¯XÀxÑ£˜ŒuœÀ"t¿\Ö…¦>V½á†us¿iÛYù×¹Ñ[’`¯!¦Ÿöí†‰Ó2Æ ê2ˆÓ¶º;“gf%ƒ,ò$_ÛŠ“ğIèˆ¢ûm0ü ›Œ×Y*"±}ÙÜßà1yØq\6—OjnùBbPjÆğÎbÓ–dU·–%.Æ¡ø¨H—/Z^ûÃúV	—*›æ@æ öôÀé¾Ÿöij¸$dR›IÏ”“X³™œ7i ^Ë(¦œ!‰¿§™ß
Éê=dşxi–Ub‡>QT1AÁVò\ßÓq’NğŠm<¹ke»~±*İL£{4oR=ş’'nÂzNi½ ìC ÒÜª2…r"	Œ±Û¦8tEßÍÚÇú«ØN9{’förÈ•´ÚÜd…xªİÀá$­xˆ¦Š%EõrŠ°O@ëE\°]lø¨P‡U‘O¾KH4<Ä0œ<G©€Áâ:Ô#'f\Ì"º6úgù™7/)Y÷‘¬İRœqF‡îã_üØ+kã|­“ƒß: øòC,O³íèƒÑ¤{hŒ®ˆÛ¬ê0©şlct¸/Î‘Oñg“üĞP:Òçu|¡GxÆ5PÓ£*$ ooôªŞò¤)…˜¹^²Ïüé2Ïº'¶®]%t^—?¿fkºoSå	zF]l‘úì›­‰QUI¡P¿ğph§QËÅtÈy‹Q\¼áøÑm"yáÈo;ıYWR0Qyw×™wã1ÑŸ¡°Ok°¡’ôÿê`"İyx[ß´AŒèè÷¹ğ6n~ásÄí®
)X§Fµä"áFJ^û)]»‚ïı)ØÓ‡<ó,|85òb?S—ÖK*+Ö#}údnŸ§mĞõML	]²şfÚ1Ä µÕÔ÷„Ó—’Úx¤}>T,¢G±½Ì©Ÿè(ÈuÆÿBÎ9³{ô–Ï?x~rW×ÊüF”ä¿ aßİ¥ÚYTã$©³@ƒrBî{†8j(1ÄÆ*rNnã´,†ßm£¹ÏşaÓub6˜¡Df;»ı®ˆ¨^Ä¸pèÀÉÿÆC¸9!%ÄD0¢ÑDg±Ş»tÛH¿>öºœW,Å|+hrPƒxŸüC×p'FèÑI°)©=–i¨ì~È¿U[é˜«‰Ñ)Ñ×¤mX?îvòÑùMÆoŒRyÔ7Ğé¥väô.İ÷m%Oø‰yëŠóĞ-œ"Š”²Ú'´e€ö)düÖÒ°üw¬§~¾6!ßE¥^Ä¶
ü-Ü	ˆäNq[Ï0}¥¥ã±	nÅN´—ƒz™Üÿ›SL¡^'{'BôKıRe¡îÎDÕ‚sõÕ@ƒd––±Ş/~ÇÜÊRO’gÄÊ³ê”H3–{²fHkˆí4‚N±‹œ9gş}]\•!YD!†®„ïÇ Tà•¢‚@”İ„¤6Fò±´Â<'Æöú‘Àf;‘›ĞÓÆÑFsêË’ÕŒÑY-ˆAÜ^¼FÃÕ19³¾Õ¬D)^ñK’ (<,’•: †wşB@,2¯¼fİ€—j)û(êv‹Èiâ’?äF"ú¢ó®úÈ­L÷÷‚¦Ïœî:Öû«+e<›@¡à›ï‘µÈŞ.¹o ´ê¶o¤J¤'Ìk¹®Ogº »cşé¦`Ù’¬s–aÕdQùˆhz/-½øyƒ‘.ÏŠß$—¾óeÖê~(è2vZX¶BçŠÓÄ4±ºXIÓX.1Ò[oby¢ébÇ¢(}|§ÔÁ¨Dğ0³pÎñ…	Ñ˜Œ9!{;Wñ2<¶`ºÜ¡ZüÇU’	»0DI]!–rê©dÂë‚ÁÉ¦,ùq&RvÍâ7‘pö,öíÈ¿À•'Ì<ü•8 oÁwö¥»+SåvUÛ¯æ–êIõ™·j*-l"?'È›ìÏ¸×Á!ÜÆÈ¹é…®GŸ7íFu_òğ²\Û_|= iË=«i7ãËÓ÷~İÏë§&–õï€Î²š¶„‘7×‹õôšéğ"jz%j¾Â@ÆÓc»¾Ój¯Î‡Ú¿]âç¡g €RiòÀ›g„C" µ
ñ*‚BëÄ0^¥µËY<V[AVªßõÇ0şŒ¹ebC0ïõ¿.ı”“‚(Ø?§:f¹>zÜ,¿À0™‡>øÙlƒq„ºÓh[aä•„àpê‚ı1&¨“>“pS/ÃkÃk§dËì>·jTBìğÚ¬<\•>¡ÃĞ“ÇŒIó?Ì/øÇöÂÒ<A]”¬Bï;­ì>8PíXàYš/˜ÇŞâ3ÑÚ_!Œ;b‰!8BéÓÍT
½	ı ×p¢âæÄ\: ±¢KLn£ödÅÍ:•(™cƒ×%¥{j#³Š¿XDô¤Í"Yv„/‘[¨M<™`,\O¿'äj5”ÒÚòl•@àE7jZö¸ªH7rüŒ‘@zdÜİÂßf_Øˆ›ş–xhpl|¨ÅCüI7qÌN,sL	’ckÌR¬.Ì¯´ãâı1NíıÎÓæó»ú,*”fd.õú|k0YY$‘ ä%÷	Z/DÅ¤ÄzíM²Ø±8F¹õ7n³rnïĞ‰&‹À]LÀµ9ş–Õ]˜xÙÏe¯¦%ÅArMõåÉÍ×È:¶ï¡U’aˆ|tvÉ¨5ãI÷yÖ{òÖZFZ{ÃíÁ05•äòY¥Ê†7 %ı®€R1ŞÅZwJ4ÕPÖ¼ÍM‰êÚ¤eµ‡üğ®â®:È<‰¯1ÇÎÿ0Eº¸UÕ×gÆâ¢gÇ€hiªµËT/ïziv(X)½XE¶C˜qKîd_^,²)¥\¾ğ½‰ÿ§}Şœ“mÌ(9ºÕ‚ğø3¸¼¸ÂÃÂ@}­s¡¯}Ú‚Çê$Cg9øÖË°£ñÁ³î™²ièş&à,n¡,¥W«	™!˜ˆæËA,Ö«À<™ôÊp^–Â£ö{V?nßµÜ»Kº¹$J7»,ç€ĞÇÜHòÓw}Ö‰ÉP^ö°½”*C.|É„gE‚tv¦AEqÓ*â*{Ÿ†FOà‰ÆYÄ—ŠŠïKôuTÒ~üŞ¢`0L~™Rl|ê÷Y‰Ç»¯Òx!ê‡oš>HGÆ¦9´àòàSvCM¶·çqpIt­=A=9şb9npƒ—–S&KÒÜc³Cgÿ­{”!6åIdïßB ä -Õ?_u/}Zñôeƒ"p—i3Å¶ØÂ$GËx+l¾GŸÆ 6´ÌE“*ğ“B¾õ/ñˆÃLÈ¹k·QfåœsœXe1åŠ8¯ôîg{ÁAiÊŞñ Jr7luöúÈˆ .úûm”şáwù¬Ò.ß]6‡eJ½S˜ÜOŒ¶B»»ô¯aâ{!LK®^w%’ß3soô:¶„;¥”­=>SÇÇÉO¡Pœb(d±×»(R¥íÊŸ%dÀ¡™¸b¶¯OlÀĞ¥t"Æ`Çà†Ë¡I¾…è[³Ûy»³/F{×}g‹ÇX z]‰¨C¦ÈÜR+qÿöİK#‘È»Ò)Ãüs_ydEF™­:¿p`c-½ëœ9§¡¾fgÍNæ­ü„ µQˆ	Ëv/e¤7ñ~êêøŞdAóÎÅù¥ÁÓ‡°[«}Û*)‹æÒÓÄ•£WÌÂ2w¨Ñş[}rÕ2*šË	İ$ÿR—eçÎ œ³h ­(ˆÈ
JKî†İ1vä¹@Ï#k±ñû
=¹şw<X½İ€ {pÙ„2o¤ãç<Ä_÷›;Ó¶Ğû5©E’ÃæœëjÂCÆûoĞ(h…í¨2ÂJ§å¡‘L6ƒà£å™$>Q[…¸S3Ë!¹ŞítÕKòÂ„8»÷á(~;ö¨^‡•–õ%ÅÉØYÛW‘„v‚Q“‚3ÒFõS@-à="uâTëïÖ€wÜÏÖ_÷jèH¸+g=e”D^ûš¾—&šz?dzµèáß–Ç±s}…¤üB½å­lışµ!‘u²÷'æ¶eïœIlá8‰xÜ2s›sÔêÙÃù¢ÊL}5–a32LÁeã©í[@„‘^îsv‘ŞÔpÑU…/WËŠmñQ´ü}£7ézwå•(˜3R‚M]œ…vè¸Ñ Â)OŠx£8ãÉrÓyQ’jçE“Á¢|A¨ò¼‘y!Öë¦îMì¬°÷SØ!}¢éqafí‘ÖDŒ¥áãÈt”ªËùrĞÚÁqÈ¥¡Vf€
›qÔOøoK‚KñH²y"Ğ÷R-ß yëA˜U‚ûbsJfìaWmôGí`}c²ÏÍ*D½#J‘>
œı Ut!á=±¥6¾YİP|&6Vk$1È~>"ÏÃ¶ÆàxÄ‰ª?®C8
·ˆŠzb¸İæsõ®l¬2)¹M¡Öq\’æfœé—˜½X´YËøp°ƒ‡'‰2|£0KßŠ¿å~òîV°çeX)<šk6ğãwx¶ áqŒèRt$‹PÎ›’oBı>â\t&Ü!6S7È¢œKœûÎ:|p÷!ke¼MKŠJÖ†ø€«$ù0ù,1ÂNQäÜg8@O‹œŠí…B¾˜‹(€o¼ô¹dñ2$ü`BQ0³¸‘ÛU…×äæ_ŸŒÍcŸ†æÚÆƒ.óöÈ(ÿtö,' ,M{ó3Š$”PmUåîı^èş
§á°2¥ëÔX5wXãÌµLEóÒH;Œrˆî¦Ñjä¸‚¤A7àò2–¹Í~±oÈ&GZéx¿DIÕÒ,¡Ø{ÿ?8e_$¼bzÍ]ğ)èø—ğÒ—`¥G†2ƒ„³ôPv şHí¡X°ïòûRRz%´,;Âï;Õª@½Ëšîf½««:tÆäCèì‡X
~ısl ¹šÔvÜxçØ nyPàÂ½¿W# ‰ÄıË7œ/»¼ŒiŠÚ÷ò­Ğà¢Äj·¢~SDds4ıy¹(&¹ixQßèúÿœöúå-<%Şp’zıd&´Ì]Ùw#TîÏèøÃøì´ìƒ/"7èZ¬µÂ,éw¬¾,lê€#"CÄ_o¯£óHC(¾îM:×1¥© ­Zoåš½İhRf!ÛÑD"ftDš™wâíO©ßK:ÇÎŒÃ•ë!tæ»V?¨Â²q<œvÆ#¦.lê„0qØy$o‰¨|ÎX×æÖÛ®ƒ¾ø{œğ²6œ7|P»¡\åTçaú™€'ÆéN4ÄŞo"H[¤Ÿ©šHa~=]¡Ã†2èxñuDïÜ?2=R<{Ú{iv—æ‰hŠÏT†h€TÖï•†±Â¸XÂ&½væ…~éÖ4s6ä¢ "`Y¿ÊP²kƒƒ*9rdØM¿(&
'–ğĞ3d©V¨;­+øÂdÂåˆ¨¯	ş14G«l†ü­†±)™Jº²Šº!¼`‘1ë Öß@ÈNËÓ¶9¹”èü½šl«•’8o«»%0èkSİ¿µÙ‹ÿ¥Må÷dåÌFueêsN²!”Ë’cú°›Ì—ìÄizÌlšï*/7]H0¼ì`;Áî/»j7Òeyá,79íñ1ù0õ®:Ì¤H4d:ó÷[š‘é»ÙJ?¼Á½A?Ëía²¬ıí(Rc
†Ccõ£›ıoa8ÑãøY×ÛèuıŒc9?İ–øOşPkóY 8‡|´şQàˆ7{dQDÏŸáğQ*¹lVœtæ>ÿzà‘ïÏVPE2ŸãöYXê{|U'£_&ÒeK•e¨IÛ~üŸBSø´š–xZË„3–Oëƒiuˆ–ìfºËù%T»zO%Š¸m6B±±¦Ü³n©?iîwL¡Fg÷8ù`ÜÓÙG;qvù-¥®[j^/ü¨\]Rß¤Ğ<âÂ!Õ/²âûÄt>À3|É)_‡™ØEUOv;Ù,ª‡_„	äø½8q)°¿J#¡FÉ¶…Zë€é`n‰ëûH›1l“Jÿ0Småòò¥ÿÜ¤Yp Pq6Ru[ÊÇA`†ÜÃx "¦Ç1‚tÒñ{ĞyÀ;3˜ŠƒX\Ác'u	l9 mr›‚“ç’DãhfÃÀğËDyÛ!‘Ó¤A²_L™*œàO™‰ê¿-AWÈ™Ç‡È*\ÑÙO=İf­ÍîíîÿÌ
å éœ8Ôù­_M„{Õ›
qˆøÍ{œu+*Æ…!360vG9}Ü³svµ-b&á„˜ìméÿˆ7¾üf<„÷.Fev“AÿÈE„È
:šJ#•Ø+;h§J¢³…?Ly…>{¿Mñ²°˜¹N†MÖòS)˜“	ç{¥?8ºwJøØœğ- r×‡°ÌpÑ ğ3_ÖŸ7Á3Çç|1-ÓRQıg"SÒÿÓSr›ÑøpòIINSÇ¤Œ-…µî§yRp]Xßä²gf§^t˜êç‘q`ÊlHÌı»ZúÓËûø*İWËé×è¬eÜmÄGÆès–fTH†À|ãÿiû]Cèz LM{ï‹O@¶6'ÇĞöûˆ÷ç p•HHßôH}7h÷vç \c]‰VŞéT1Lrån¦y
Ót‰u-Ò*Ö»@‘mâ¨	òR<Í<°ìÂ§şc³AbpÀøŠíÒÒ´2Gkàÿô’˜ïb¬>×Êàü¦·@p>K(Z-ìJ™6ş—E-j½OÀëª×£î½bĞBš’¨×;_R¿	8ª'Ïí»åtI
º‚ç 
¿—‡Ğ"öGSNZyeİcÈmÔ(H¨_tgÍ­^jè¢G|À“æ÷Ò¾İuŸOÕ”3ÓuL±@öÌ—™fí\ôçÇœ+Á“O‡ç¶W‰²ÏcGóÙ…xÇÅÜˆ·a«áâ@Wê=ú©¼î2&Õ»·Gäáùå„6ÛÃ¯.’n]‚ã¶7¢3XÚ>Ö GÈ~˜t…iìÿ™§)ÌgêLäš©TWx5ùäYJäšnÙê_…ÜP×)¶é¬ôaá# X;±–J¶]<¡ÂMåuÁTï¾Aï÷Q‘Å×!‘’¢ŞyE×ÌGı¨ËXÎ¼$•4ïÿÜëS%ğ…»ˆOšEZ™óÿœ‹Ÿğ=‹[r[>âÙ›ÂĞÆ;4bÓèô²vRĞ×„Úb‚ˆ-.5ºZ+Pò‚œdÃïŞúQwq¨>Îœ¡=”lj-"·”Û‚Æ,HıA¸o>o‰à”
÷}ÕŒ“2ûºR\4%=0ãs)¶5Å Ş€ôÂ×ô(JNºî
Q yãa•Õ‰ï]”–XÍ8Co´XáL?Ã3ZÚºEoßa†î)§~Ôß"rö”æpe
Ïú¸\cÇı_¾&Š	†İe’ƒ*ğÄsqÙÃ$$v„¬SÑC9ŠÏrñ7Ilµ#NÉ¾‹%cÌ7ŸXÇ?—Ç‡´e<EßX@¼ú/s? „¶‰0@¹7 ¡¯âŞ6xÑÖÇ]‹óûy¶»§}›‰n(ÏŒÅ(¹Á
|ËòF ‘âs™9>’'c:5B¡[Ù[ª÷Ô~»ŸöuÓ¹á`şaÁ*4;Yâ°q=_?r==YÕz„Ä'“î|>ª$*J·ËâÈê&¡FnáØ¬c‹ì­¨E>Z›fÃXLœ³fUmş,]şî~A>JJ8Ä/ÿïÀ¥*Óî\mFT5¥€İ™¤©-©`éÊ:øı›06Ş Ğ‚4!Å‘QíÎj…™]Ù–‘I¸Éå4HÌñNò6‚J‰jdºâPä%°¤oÔŠ¥B"ËĞÊ9ú,\¬<†nFbèÏ˜¾Ğ¼Ê ñ‚öP´‹ô9m³'‹ú)}é+P¬]eÕu‡$é¤mÀ©Ï¶Ë•™v¤·åıq§ñ]5=ãÉºà¡¨}ÍŒÕè İø µÜînòœûUùFõêµsáUŸ.YœÁùx:U*qû/}s.Î¨¾é7­•÷õkøAtåÓSj4MâôËä~ù—öëKñzİVI‘ƒh©5–¹`ø&yØ·†­CoT„ŞCÀ×ôAB‚¿R•vô¯ÿ5?FM{)ó¯GŠíˆRşµšåcä¦.Ñúºæ=ÜlÅÜà(/› ÍÂÁé4—¤«ëù°~uÏ–ãöƒå ç”¸ÙxyQY—ÅK+H+Şê;:ÕÇ/`ùKÔxfi˜úÑošP†„ÕğV( lj‰h´aäqÜSÚãq7OƒõF²“Yl‚åVùã¹¶gAX[ç¬ìúüßö
iµ\O•™œ’>äcRb.ö×£ïÑœİÅßFh=}Í«ùPÁäæ£¥¤SjıWÃbñtÚi'ã7:D¦àEzB;{Q´"¸YÅ}!ëĞ‹X³£~ì´ÆŞ9^áÂ¦ôB-¨"D³P$C²íËwŸ)!Êa°æÖ#Åa%á8uÙO’ÒUå—Oífy2Ö07ı
+rv}Xíq9L®Úf÷zEBàÇ$B½WwãqÉĞDtm:êx.d|]´ƒ¿ÑO&õÃ@"ÛiiBHPê~#g aóÎÎ°·~EKYŒßä[Uè.\¯Øù'3³=›}w´Ïrs24ãGßo¿ØvÌB¬JÁ:pâæ1„½ù3S ‰6|‹üË7ğÈÙı‘ºI £IFjÕ?ëZÉ®íw«¾bÕJg‚ÅàKÍ%şÔ=écLÙ¬”8_LeÃa'i†?ÚUnÖóÏkÎ+ ‘×ì™,ü=np×ú¾S4æÙš/nË;5ku`K×”£]ä¡^@º€uŞjn•®üf!”ÛÿÄ8Q©š!(0Ô1n|Á«ÉÏ×ÉØK9âã2¸!*u‹w)>ç—‡ØŞ±»Ò¾áİaM¶¾’7¸¼CÈUáW0òåå’Êü…tĞ¯VaÄ/U9×|©ÎcvíÙ»ó«§€¤ÃQÜ ¹&+»	(ú[Øüº<£–šm©]<kWftjMİTÄ'.ˆël‘¿7ê3šÖÒÈçd˜Sœş‚Ù]Üój:kÂewo«®›89NSƒz’¹’?ßİ)z†jşŸWNâRbG½¼†TU”¹K]7½VSgGi¯şÏ§ß]S°òôø¥õoãáRæ”…t—ìÖ´ûŠ&äõ¡'œ¶D:gEğ…©uHò¤½C1¢T? ê³lÛ  hÍ>šÉpcJĞx7œ‹Å#tR?ÛƒÀº›u¼y¶‹Hµ L¥ãI"ñ»©&DµÂ¸s>¿@çÊñàbòA;Y½òC¦İjQŸã{â’³İÈ£\ÍîÓTd^ÍV¸@‰s9r{Ò¯Á±ÿİF­h,© ”Íó—(¹‡]k#¦PÊk‹- ‰ÚÊN¥U¸J(Gè“ê÷1Â
4›\7şÌÒ§î§™”ÿæÄĞJá
éÓ×¸ĞŸ)óMW/‚ÙŠı
×ó7´'‘òOKÛ+Oã©I•ÛQ¹'Íõ@c\4Átº„¨\¦a±Œ:•\mÌÈU ı w“ „ÙSdy<’S†ó!˜qfæàƒ6GúÎE0è•ˆ”ã†å>ßJSg¢ğ¢©Ô‘È Òéz«›[ËVYd¡¯"~w"W:zúƒE&ãÓTb¥’S¤®x9S‚nKáèqgÊ>ÂjªÊ'ñ„Çê|±¤Ö§.ËœmIÆböG-tŒxİez¨÷qOu-@Á3ñ÷ã%»&½æ£àğ+îY9‰ü¹èO .Ak”|†˜võşŒç+Š;>MŞÅÑ¦¼ı%lS1»K°3c7A÷/¤J6€œt7=û†·Œ9a î£¥»S!“”ÚD‰;®¢±õ^õ©£JİCJ¾+ÊriÊão$Î‚nbĞ*€ ¬øÆ9÷ï5Y!c§jË*^U&:uÌäwÃ]1%Oy~ŒyÁ=òúvĞ4Q~E?SI,yîó¯ãkkÕ]­f¬Ô
'ÿÑ90Éæ2UÓÇ9òå2ÚUày•ÂçRÌì­x±cjƒ®<¦äÁ•ƒfNÑÜË2â<3	æÕ›”sİm·À2 K“	(1OİmWÜ%™^%¤–FUã ÁÂ°Ò-GoU®â+nêrÛ:g)ù«ú}…œYÎˆŒ"µ†@Äépœ:E º!é -anŒh n-6<ªÖÁÍC¤iÈĞŠfG'|e.àŞçã0MT‚†ïw
Ì}ø%˜é÷´ü· ;L·&Dƒ(Íš}äMîjƒœÇ#LC_„Kb2È¹ˆV¥TÃ€&ßèæƒûBVQPxw©šY¥ŠBàÇT’‘^‰5—±_å_VÄ®é…­…S¤*î¥Ë…ú®ÜÎP5¯˜8æ?)ØAÏ¥±òôïÍÒ:J%¡ağr¶s°Û¼¿º8†Å#"y©“%ıbjÎè­9
 Ç)SªÉÁÄŸÆ™)g
'No6ªDcP':r©EÛúßTH®vÁ-‘~>X±>{uùQ™pšjÈ°¡}3Áï#P¢™€·)K›ŠBB`½—0Â×I•ø$§ZŸXË½Ò	«Ê€jŒå²à^V&Ão°	Œ>º\fOöôn‡?¨JæÌêi‡vK6Á!ùß›åŒ/YI&¶rd`ÿÄ¡1^«LÔøG÷[ÙîvO¸å$bqí‚0~Ù´œá¬ùãv‚YéÁŠŸ».eeïé^iÚ2à„˜Õ£>Õˆ¸^u/8)]Ÿ8Hÿ«8¢òß!éPYµ›¼GAÛZFê¨ç„.²qå§1@ºq¦0‡/êÎT"´¯J<˜Y¨­'ñÊk€–àíØ‘ïä.Ñ48Ïè: R†‹MÁÉİª,¶-¡o?LX¤Ítô•¤0¢ÖMô…³#·ç™.(´ *L},ÍP2 ¦t Ë]³Ï­†ö€dbÂıÜŸn¨âE\ÆÏl%ì'Ïmú·–§¤…‘x ¸óÄi7¡«ö·'£‡›NäíË¨C6Å—˜#«Y$[4³ÛfYNĞ™ü3 £õ9ØÁ"!=·+ôøÉò©¡++|«yìâûgsB…ìLLÃ]¤oÑÙ@®¡?xÂ¼YZÆ·ôú_|mŠİ,›eŞÄçŞró ™úš3ÿ‹ø‰ÅßÏ~Q)G4òğ4¾¹é»Ô»qÍlÏ‚«¿:Ï`´üÿOï	•¹Pn,Ë'îi?4YâHñ—&æ*?Ï‡ÁH´ÅUNâ(†Ç›¾­½‡—GÎ¼(iÙ¨‰^#/¬«ŞöÄÃ³ç#æ¼×ÅJµßí8`í!åb"¿5Áå°h¦Ïï½ı˜^/D ›áşÜš#qHÛ­ m+×¸4_òïÏÄ¤[Ş]f K‡|wå¢ºYÊŒl2‰•¢Ønüa‹¥’68›B®óıšâzw
gŞ‰?Ç:¡OE8u»L^›RèHkÿ/ır?–ßÈZÈg¼¸€o
³ÅTjªµë«½fè£±Pµp‘¥p¢ÂUà¶‚Ÿ¿¤X¦/í_¤¼Ğ2u Ë‰ÍHÑ Èb;À²ˆ»#šR—[v”2°íTÊøÇ÷uë†ø~Œì\­BÆ¯ù»yñëëR¦¼D[–ø]|8Ä[ı	ËøÂ‘CHàq¿:	ËOµòŠÇQØŒö€K®Ä>=ŞÛ²^6vLÁÍK!pyÑ“Qšoâ'*‚Ğñ"“ `ÜÙ‚Œ•‹R+I4í™=}÷e6Á8Ír^Ãh!1ö@hı2ÀG,¶éŞM‡‡›şB«²>çn¼JÊÀÊs.*YkÓ[&$ÿİ:ùå8Oë…ù:¹ñáÓ4Œs
UGÒ¹Çè…$KxèZüŠ†ÏÎA©€ÏV`~S1‘a,=ğ? ®XëI`ÌÕÒtıuSj]åë´ßiúÙTOòò€¤lÂ Ú7ÌdR{JÏùä³_‘"}KyæÁæ :_=°:lœÉ›€wPö<W]„Ş…ğàjşM>å>kªY5ÍO¨`cC {ß½ÚìÒÛÏèB¸†e±™,Á¥Z_¢­ØºÚVıäºÜ;Uæğƒô£W„™M‡\ 1²ÿ‹ë'Obmû¹t¯Œ°úPDË026×ëÏds“Œp]	r‚8 G>ã_ïzagicÎÙ__¿qÑ7ƒ¿kã÷áZ0a	?Cx5si‘Ø.SÒJ¬î›qüõ™Ö{ùƒÙyª(îN¢ªé4V–pr·&Ô R˜ÄĞi ß$f{'n’²‹«Œÿ%:‘†ˆÌº·ç[ı~Ò0àQC[âè	‹…—9ñGBáÖŞ·èº´ñ0qĞ	êo£)(Á65Pi	13§~šÈ2æ¨í±]õÃÄ>0Náİ•šuåÀU:»W‹¢IsßÄ˜ŠİdÆ&e½º0†¸“§¥ˆ^µ€R¯ÖĞï±Ú,Qê¼æP‚î%,p»£¤ñİªà–P<|^rùZÒòÃÚµ Êº„ĞÙr»JÏ­;§?ÓQáó£1mÌ«ÙØÚ}şø:IfÁ%d1ôaÉ#˜æf?Â³õmaÃKël^^üµL£sÄš±¶ v¼(aŞ€Iæ4á
ßÃUŒwş—'/Œ‰×BÆ‘!ÿšrÁ{Êë-'>¾÷…Q˜ŸGÇwÍ‡$@'á?Á®‰€V×Ñ?ºúÚ_O ëøÖõ¢Î ¡µ	æ"û¸V\.7bPÛ JÍÅF9Ó5Òí‹œb[„,OhDòÌwSÇ²d‘T`ŸB<KGh²¡7‹ì¡È/+Ş}UFäì,`ğÄ’³¥ö¼¸éE›í§bE
ÖòÉwĞƒgRu&'°Âş Ë5>i˜lqTQº‹f`"àh¤7#Q?ÚÆUSãûæ)·É…¿‹<d”Õ¿ğn»#óBà)Ï[„7ÒËDDáŸ“ ×zw”à+ø3"˜&© R‚õbçO‡Ğ8Î÷ÂF(;Øm¼GVW^´ •Ù€‘Ô{wE|ÂVÚÈ©pú&é,.àV¬>˜Dwü?Ws‡ycvDÇ™; 6oVÉH£AGtYá¹‘Ôjùâi\8~™¨F#ñj0GªÓDFÿÁL®Ow	¬9ş.o¥ºæ¼„bw[ÊİM¯ÂXĞ]];,éM…ˆ5?2ï¯mq©¤Ëy´R›z–ìøÇàşÓV@»/T$ÏêxUK„U§Îçj‘Ê³8£ğÄ'`˜5ğ_âqßÙ*Öå=% ¢«pñO+iïŸ;Bt…¹†¤É¼±”üy_½\1 Ú¢mApˆÂÇ¸ûÌñãfÊ$ ¼‹@é´½J˜oYFÇ$¡ü_ˆ/ÁªÆ×0SKÌ[6q~¨šZŸUÉ²G æè‘Ş‘‡Ü2?ºæ×l”ZûrÂM6eOŠbÚËmØ¼)¥¾Â¨É®vŸêÉÛS,_ÓT¨ô6šÅ9˜ØrÂE)7AL÷ç52æR0¸œ’W
Î{÷g‡‚ÇèwÁ§s‡û;®c”köë”Ò¾CCÒœt>uN’m]R$¤1gÌ³e)ñŞdHR¢0ƒ!ä‘wñ~L©	ËàÕ2¾bJi7Œ”*ä3—Øb)	‚9ç‘ûÛX©–˜ ûaÚ²ös_îEUpÑØÀånLŒ
m¶c'÷à°U"ÔÑ@›÷}!¶ï¬š*‰|­’­»z@.«ÆV¬ßZu2õù2¸+RšĞ2çîÑ+Qëk,€6N²2<Jv—uH*ŸP.oÌÑ^°İ¿[xT«õğ­Ş •qÖšoÉ§Û ÀÊçªÄjQÉRGeºcÿùÑJ£…ãìÉ`8Uœ ÎKKJ¥ÁBf:á[ñ\4NqÈ}=ã¸lëêµ4,¬*•ğlV a³¾DgĞ åäU–+UÖeÑšôToµæ\*àeğ©}Ô<Áø¶J¤óÛ—Wi¢ıK%`éB$Q&æ0[;İÊ¡jµÌŞì[ø}CŒÔ¦ıÄãÒ%°"£ôI ‰ÚCª¯ ²Õ`[œGaì¯qú©Õ-7V¤0Ì-ù'¯øÃ²gÉX)ş–2b¯Ãvö­¸Åaéñˆ÷[¶#óJÚN>©ènyº	oe!¦^;ÜsÒHö™ğ\ŞMFã†o/0ó÷Mtk`1A±à·"lÒĞÇêûáƒÌ®-¢›Ú%¨gµiiáÙû©‡œ8_ËaÂêĞL°¼ÂÔ;¸T¦8fqÌU1–ÀŠ8¢±ê°oËDy‚‰Ü—¯k™h«	^~6%3Ü©(ØGSLÍ6¨6Zkmô“Şùòâ/Ìk•N*‰¯Òûp€Ë¼¢-§ Ù‹^jÛr¨Ë=¶LóòmŠ¹Ü@è‰„;O•D[CÜ€ò[ÀT‘¢„3~ÛBšäÅ&¿Pˆ¤Ôï2Ña}¦¶BŸ|NûŠR}³TSk!øÒÕ³â5²ç’‡d¦ P)7M—â‘wÑ8€vDË‡cğaLgÕY">?'ˆMXPF‰<QAúü8>Ìc5ƒµ@:]Şì¹„{9Q¼¨0å9Ò!Şè©{vûŒÕà/?øJRºÜ¶ÕÓUÕıg)‚M‰š3œOÈÆ¨»ïRïş5¹ ‡qÌ&×4[R ¿Şcz´oâ²FêÉó›Ûo”pìKu‚£¨]wüô´›ÕI Õ‡…Úbuµû„—*‚ÖĞõ{‹Ë26¢Ø!0ı‘İ7îZ%Ü¡Õk’R¢Ç‚ó:3z¸Lú–T7SN^öÇ×˜@KqÛ®€såp3_ËtmL'â7ibëÁ}+
ËË½yêÅÒ¿<2/]‰½3ËõJ7J.:ŞømÀí›ºaëú>ß·õ£~zñC	å¶=5™âúJÙÔYà ô‚<Ó/Î†FfBÃà¼ñj…ULs`ô°U x-4‹sÄøÉ§=äfZk|sÏ‚~¡]\«G÷–ÔZCè`T@c#œâ{şçriò³Ît›¿gÅÃ•¥—ùü¢ÌËWWÌ ‘*ŒpïŒø×ÉŞæOóQ°sß/©Ä’Õ=0¼Õmµ÷x½šşÊÁày˜.^ƒı(?º³Èøym~3_‚^5†Áq÷#I êúâèõ»É&äñkyÕ¢ë-¿ì&í?Ìû'«Â’lœŠ Šg¶µ`}ªu¼3aëÆä™d¹ªús¾'I€?-éz×ˆ¬Ğüä8ß~“#ìBÑøİ§ğ‘İeU¥%gEË•¹K1‘# €ÛÊ5Y-Ö®Be;IYœ;Õ)’Ñ×ä*Õ—G#¨+JÏ_ÆéîéJEüï3ƒ¾"†‡®ë¡æ'NáC÷Ê¿:Ç€¨½TÑ™Ï@Åê¨¢j æ=¿à5À6øÉúÕQ8U3®ˆM2‚Ày˜ä'¡"*7]Q<óÿ?ªU·.´:İ&½Ç[;³©;ª)®•+Óé#…_ÙfºöŠ'm"h·´Í+:½9Ïå±($;(±	ëÓ—!­U.ĞÓjíÁ’a“¿müÅb¼'#-rÂûB&iPÙCåC+H(~ûÜ[ÜéÜ„ÚĞl$«ÃrŸ/¶±ä%‡áø¡¼ña} ºs	Ù#–LQÏ¯Áj¤Øc¢>GA¿¹ÁÁw3E™9_†İ:cï*B¢“T@ïWß©
ÂÎ ïi€%¼#`-.T&x›İ%€¤á}ÂOB˜~â°Hêqfµ»I4 y›ç¾˜%…–¨ß+è®
÷-ª$Z›‘+¬~¯ÅFÔ=û“’Ô°HdƒÑŠßÀä¡ëĞ¹ÄÎX‚mùÃÅ=oòà8-í´©Fí[äú<…cİ6Ş@Û²‚Ÿ%WR$l¸å{G™%ú'yÚï¢pnÌ§³qCØüÁÅQ5ñqÇC[Ä”$KÇUJ:ÂF1OšT›Bõğ Q÷æ3]™ 1h£/4P³oúD²¦NBÿr¶éø¿wnVgífÆÔâ©Š†tù.“ıGÚV'Æ/e†q‡CP¹=¡Î¡V÷JßÌÉ˜F}ï4˜G•Î MwLVÄú>ƒË?²hŠñE"’¨Ÿ/HpöG{ù”\_kÂ²Ì(jåÛE»şãTŠW‚gÖª «Ğû”çıñ±L.|is­çÂB1{’aèŒÀ?oÒ*°LùÚßÁ†.}'¾ëºÓÁ”›8«6úæûÔ`|´˜ºÑÅÕŒ~æ?…¸¥<Ñ[Ï÷²h·vW?y@-$S¶€/…‹rÊÔHÌ©:M<ZåDh[¬ñÌ	yÀÇÌÒİìH‰+	lFD†Ñc;Ë¯ÿk_é•sk‹[_AŠĞîËë˜ËÊèÏÕ£\^u‹=ŞØmûÑd )ê¿Fï>Ê²¡Á­äœĞ,î×Xj4› Ç‹>6!¿CMš¤`³Ï+`¤_y´ÕmÀPÂl£¢v>©ìÜóîI‹È›j(<ú®yÓ»­–ÄlB3²L_ÆÌW(£1Q=ıp¦İ@9›—ú×?e·Å¬ÃĞLa@lül>µ3Ÿ „ß?NØw!L¨«‡$×¡ÈK0LFÔ"'|üLĞQÔ©¾]{ôG­U%ú‹€lõ¹ ğLsµ†!Aş"./Ğ%´¬kP°±\DnsğöL³ÂU§´OŸ…šÖ1í1ÊOÀ‡ÆÒ¿)YÏşºo2!ÂŞÊÜfYÛJFà:¬pßa\ ½¦y6˜[R¶ªa¹ŒµšˆâIÓa,Ç•…Å“Øq'»æ5³)W‹¹ü§º(³M×Ó6½Òú‰OARk¦İ`¥f=şÕ½(«&5¬ß>1‰M•Ã†šèŞ	áA×-j¶Üñ'…2™¦ÜÊ0®ğ.Áğ;Ì£@ÍBÉ9Nƒâ,=*	$vHªrİğvM1Öİ”—	¿I#3VG|çnàHŸ#M•ÙE9¢”‡½VÄ3		*WA2ÀTÆ¹Nq;©kîVhrCü-”z5ƒCì*§(S5ÏŒ-[(N#ÂXWbèN·ëò¿d}ÛØ î¼2Ÿ”/ñi¨Ô©/2€rÃR	gSø¡æø£nî‡¨q#•ÌÀ9~2S>¤î!ŠW{Å ‘òö Œv­kH6ÁëÆ 7Œh•‹÷ƒUyÌõ0›Œ´s~’†~ÄĞÇ9¬±¾RÓC*ıº‚6{PîÛ¥
=&ïg¦pÒı³M8X\ÙÙ&…!Î>	Òà[ä (kÒf*4´ß\i€;ü]Í+{Ëš7Q…Ñ¨Û;pµÔ[êš?ø¬ÏV› +™>'af¡iÅÀı¨ëMõœÂ±•Æ]8BÍcäéÂ+İ'Vı§¿QŒßŒw¸F &%ŒòrŞ°•@<‰Ø´¥qÆÑt›¶½C±æ]Ù8µ#ñ @ÈºFŠ„²úœï|ÿ ï©îÖ6È;ArP$Š°–Zgq±+±Æy”h=ãËõ^ÃG–lÍ"nÅ=¡UJ@¢ØV£|òwã½ûÉcç£Àó¢†
äªo¶Ç`‡„İ`‹"4†ÃŞô?„ş;)æ´–›Òì®ºÆ?e‰FÚÁ‘™
 M¬ÕŸK¼ì	æ{VeØ_¬„[”MÍ·ZH?/â8{Ùÿ?Ø¤Í\sÖİe”c¥ÿ;3«jŒ¼R9"âó„u›Š`émÖ+[ı)€¼½~84ë:ˆÀ`!°}|oÊ“»6ˆ_ãº S%?ˆÌÃJİí@ıºèÊ)\Bˆ~Üª¨¥™…İ-cJáµb<M.‹Ü²%ÿôüã«‹ TgbØ7¹Ä‡Ì_šŞ×‰şÉ;•ù¾¾¿Ê‘¦bø·dï¬¡ 3~ÅnÁ¶{bİ¾&_)»?f=ÙA‰D(Y-èÅOQ|yÈ+öjz1ø÷§Wçñä£¸+\MÊÿ”î><XÍ’†{§¡qI½õ'dÇDHš~ì}5ó“À¸GİlúN+«ñGbOF?Á5xËHŒ½®Ô™ ±]ó(İ:-b/-j)æ 2„øhF® *±Ø)EààZH›İú‚ZA·#à7Úl+ay·Ÿ¡@v g9ƒ#jD:`"2Z«‘™‰{¯Ï¯ó<£¸Ñ*É÷šgPQi†'ùÓuxòÛ0BÉÌåË*r
\!BanÁ†¤¤4Ñ¦übdz÷,]¥™§Ÿ–œ ñÍliF¡ÓNîXšQiø{R•ò~¼€“0Ãâƒª„®n]ˆ†g=!`BÒ)K‰âÂû™eW¢4¢/:†».f¨	WoÍÂpa}Jéç?ôÇ>l5MªŠêÎx¼2Ã"]zÖvçì„wÀDs†$ÕäkêP0#q1ÌWÂÁÑ^Uìî:åÚ siË»^pİ½‰Åø)ı”ŸD"nü«Ëv9¬F2óhfU‡j˜Ä§;vséM$µf¨—.qÃ%©Œ¦ç¡Ÿ¹ÕM¥—CØX‘Gj
Ìp”qi:0¨—İ @pÇÜ +¶ı 6ƒ$>™k×dîÿ¯Èı×6ÄêLPÿ6Ê¶»ïˆAÂßX§ãì‘Ÿ¥xşÉÁé+%WËñ.ñµ›okA†½a&îéè2z_éÌ%«…_•†*ÃZÉb¼áÜ„ì&ñ?êÊG€rÛ6½Š ê2w,+‚¦FH±½öN‚ˆÌ†çIŞ&öwŞ"lgÙ$ lÅM®º'’Ï
1˜R=·ÿ¸‘à	>¤ä}8âı¹±ÑàEÕ k%›úŒBÅïaß%²¾NúOÍé60•°ÓÅ´ÇÒåNÒpÜ>”Qt79©	èÜ< ‘~0N€ów>V×»¬¨×ø)ÎO{8Gêyø;¥Ï¤*N5>„R3ô¹Ÿ>²®TŸœºÔZ‚µâLË»<U×ƒ>·.¿)4éÆ„Ğâü0Èt’ïüâ‡p~¨jˆâ'ZşZüae0„$‰ˆE¤víãŞWƒ»ãûTQ
¹H-¢“KgšXæº†)Ê@£˜2gxüi½KoÖ—¶ª8×Z¶h XµäF u–Ñ!æP€MÃ“š?SüåBµc„˜~_ ÔO-…5áİÇèšº»"[fæé– Y*"âLÇJ±ƒ¯&[H`›’³ñ¤h½µQMJcwÒLŠçävFcË8«Áñ˜ÁÁÿ}şèî¬ú3ç•¯¯Y3àkÀ®?ÓH¤¶¶–FpT/êªRG¶è·7¿’mO>Vâï;æ¤9=<\Ğ66-ÓïüIÃöMµ»Vg‹ã“tµ}•}éægMŸ¦Õó]r­`µ†y°Pëê0Q›ä*IÖÕ_Ó‚z:ö¿ÃÂUåäšFÔÓEıä—aW'¬üÓ	•øışâÅRÒ5¾;Cş7Z 3ö+¡šíN¹q5TşRÛª5ø‡%
.d@&}ËzçìÏø¶k(à…<3¦:ç”+xVw2úòŒü¡!q´'5mv}Kûd+ÌËEfÂ\‹1Z«ZöÃ¸´7”ušÏ6	Ê7TH¢ŠIsòÉm×,ÒdóñÆˆ÷fó8ºÙPˆ…|¬ßqY‰”‚‹köd¨™Ã×Ñg§#¡ä`¯ìÌgğFÙæé%q!¢‡ƒóªxœ¥_Ä|òó©ghU‰çô 2|!à…¬P¦Eîºf¡ÍŞL‘öWF·?³[ŸÔ†«y[’$qEŞM&‰îEOn^#ìsÍ&Ãº75U»ñp!‡˜í}xèï,TÿGü˜Ûeôm#IŒWÂON"@s"ûTc`ÿ¾án^@wswEÓ¶_2†ß°£ü_ë-¡m†
¹?ùœ¾CÀnJBi;š]6<@.ç+I‘òÚOî±XèiøBócqò¥:pe¼&«Q‰N¾îÆ®{…­^Bzs Ü¶dÀ­í=UmQn”Ó:ı¥§í‘¯˜.(µ~ÑŞˆU	‰;U—İZ„(‘?útZôs§¥’¶yÚÌzEÜ~Y‡ …æĞkQlZóºòï)éŸ€®pOI*™:Î¾ùçó§º33œÁí-fÛyÏZÌòSå§Ä#KkSTu¤y—ƒú¡¼këÎšÉjfu[?ş éÈ£ò~¾PNçF’Kû½UßFN‚;Òh.'+¥Ï²~Aâr¼FëÃú‡¾‹qšœk]_ÖıÜL"şİ©ğı5µêLÛvJkˆ¡îDB¬!2àz—qaX*æXÄj^Ç>0OÖ|>T«>f'éJÛûx†½Rÿ­cV÷X•ĞH¸âIÎ_c*Võ‰G÷åÔEòHç¬ëàî Ù“ã|lì ˜`’SÂ[W—QJÆÃ°Ä°I¢BD+¡é;»sş•‰¦vºš7ax‡y÷µ2ÀÊIßkAâ¢æØ’#àĞ‘“İSğ)tATgs¹µŠıçÂè|­Èô¦dæêo¾XŒVzÂÕ~í+ÔL.×AX=Æ‰mÆk¿ÑˆÏ4§LæQş©5,%¡j~CAİzº{J?©§º2h6A¤‡wÜBşyùX0‘,ĞMe;%a0œ‡>+z@EóQåã¼(Mçâ/Æ;óùu(Z¢†"Ûó¾‚ŸœïŠ¢·&3 ñ"Á§èï9;+ã©™ÒèkK£t‡6±'ßŒ&}+»Š'4YR‚˜µ‹WÎh†WÛT«%@W*wóÄ€Æ%Ç:?è!l©aîîÒ8ÚËˆ[‰X« 1±î”sÿğ¤½¸’:>Ù‘R³‰Ä k‘Ó{ ò,™hT7—3Ş=Î*°†ÖF@í¥Şƒ]áRAŠU!,¼¨q7@m2„c¼ğ¦3Ìvu —™¿– àH «àÓÜ¶­í0!;O÷|í¹9ÒÒK}Fe¯)ä?•ó¨À¡Ö'ø(ü¸F9æW5¸˜ˆÿ<¶
ê‡’14„ÿ¼·ãQĞù;eà‹!a†
ŠMSªÓm¢Ñ[`Ì”ÔŸ°B¼:É¦oP§<Óá^³/´r‚º#‚K4ŞÚE1rS¯Uó)¹`ªr|¦ùÌOœÀ2æ@Z']¶jJ°%ÂVrï’Sá_GWÈHüqÔƒ$Ô¢è±§jCB@¼ıÖäÚ.ÿK½MÀŸ«äjÜ¤ß\å&Xu$Ñ–5$h½lkSaD]µ¯Æ^uŸ´µĞ›¦Qq™–9õçaLE!°MÌjR¬&±|ÂV'…ßNl'·Lú60ìiyCÒ~qL¿ÆN<S7GG‹yu-¼ıµ:Û€ğ²©{|khÔù/¥LÑg±cˆéFÓğÄm1İ|¹fğMËÃiü_CƒÚ®qßOXKÈ¨¶s`m·;Dü{.ÇÓ¥/Ã£ŞÛ1¿’vI—;'K#Š	ægÍµºŠÆ
Ä·|ß òÌˆ3òOÚ¶÷Ç*Z%Õåm¥ºCÉßÀÄçA×tòù;"U²ÇÔƒûÆd+Xßj—³„Œ4ËF„¤¿ı„·?ª)Ä±á'—i=dòÄ7¦+-\Ó!ÚGT§ò"ı£1í5Ë§f@cù¢…}Ë\©ïÑc§‰©Pn¿DáµêG<¿ÿ-d ğ¬MØ“l‘l‰ø!ªŸ¢}z|{*Ë)’EQ‡ÁëÚµ_HX)Ö¥_ûÑƒßUF…§‡F–	”b˜AÎCì›{P¿ïaá2C›˜ËÁ)†äNõE‰.a×'¤5L4wÙw­hZ<Îúú¯óhÛıàˆcœ	,šm…:ŸKS[rÌ¢PGuö¢³:Ëø,…É–å¥g°‡[…l>akÚ
âÃT’ƒËÏºAÇ‚3ZNA÷ğ 	Òî„ìÒJ4’KÎ°%ºƒê†C=üßèküŞ6k£ôOstÁïåì3õ‡ïûG¬çRûI›î!ƒóˆ…“É²éXÔ˜®)™õ¾ÑÊrvRl™5Ã²C¯y)@k¦GáLÚlIº\d›5b1È&£°¨k¿Ô}›…çLKŠFã;Ù\µAxş–r“q©¶Š3])K ¹°¥¯Ô‘d0q>˜¯Y<õ!–5õº	ÚíÙW(pˆb‹`jËÔ4Äéb-—ı>ß ì i2ãşùÊ€´z@;V	·$,uEú¬”ä}e÷F NâößŠ°)Ø%Æ›ÿ0Tp·Îı4¢ğ­(!Ê
«·em3â¥î›0´Fgº`ŒıgŞìLxÛ™ÊfĞs¯Êÿz¾“XcïÜg	 (™H\7£,„u?4{B‡éÖı+”Å2(µØ¼V¬Qı0îÖ§(/?ªf>i¨Ô_ÈçR•5é©!Wğ¾ı(¸•QÍHäßÒpR5£ÖÆ¤»g_úã^WUÓºö”XĞÑ€A?â0*ò4ü aNFŞşéÖà×“¿õE“ Fw£µvós²SÀ¿òF§†‘M-ïx¶65D$b54¾üĞ¢OiÍÚüÍd0#ÇAÌ&‚¨"]ù›Ãä‡S‚yëØıÌ+ä†2<u¸C™!Ÿ–ºÚÂ¾ÇşBöï0H‹qNØÖ ¹	êOsÉã½©€ıç^BKõÃâ„Œ¬¬¡q]J…CjbíÖÎP¹J¡+{›§ÌİH)€ë“ ª~E‹'M€­x„¦œ@ğçÔj®_;š”“¯;{¥ÊYkî¦oŞ7¿FO_˜x³Ÿ
O®š:˜8‚¼½¥f*ä,Á	0Éd=O“Cÿ)ÓçĞÎoF„7!å7íÑXvª+ö7‚/{gB{±ÿ Lu°oÔcÁíæo“©Ÿô™Ó~åmÎ—ß–›LÀÜ^.’š¶f©üİ}v&…ÿozúBD¢²Ï¢vìÉ`ı,`À2¼„30åÛ†è4Ì&Q³Éw+Ô©jŠ&ÚQf¬ü>;æÆ~v»ÊöÃ‹Ø­œş¬\S“Kèıu(h«‡Ór{kŸ›Á(G[eß%BtkÔ4:HÈ÷±'µ¾ßRoC<Ú¨ÔÈ/ë|UÄ],Şú…-§£t!Uûå›^‰L~S^´Ú »x 17Îei‚W¼åSÃ
¯Lçïß9‚;!áÎ…Yğwï–Vü’ğ›\V"¶Ÿåy—¡úÅ?Ş
±ú%w®Àğ2äÑêOf¶^À ´Äu± œùÄz² wìùLá|ƒÏå'"ü“·¢0áf«vB¬óŸ:úŒëCØCJ¬@ŸCñØ°uÜÄ²„Ö)÷+õ‘9®\?>új”fYc±Ù—†8qLá-Itú¥VuÀB»
±Mñ\ƒ	ñV!Oø9^°$=¢³ ¼#”¬—‰L$’ÙÄWğÑäğU?#–|âl÷½KhyX@dŒ|5Á||*s·IÇ
.c4›»LÖ4£4•µ©	ÿim5¿ëà]Øo²y“æg»w'x^/ã/ô-½ÿt9)9@}Ó'9›‡Èìç¥„^:·¥Ş˜DsÒ~b~³F3?¥“Ï;B°£¯ -Ç£=QihµU‘ZÇ,®ÂU^-õu-ò)X
ñ4wšgÈõy5>½ÌÊßRc¦0ü¡ª+x<ï¸?0”ˆ”öZÃ{‡(r¤&ÒÓÓW¨ªÔk‡sµpXÈ…ÚÆH X)!x@ğ…¹b"“˜áéáÂsa´ÖQü	Iüß9½ãlË	\”êÊˆáñ„ò£íã$ øÔ}üí–ÊBäu¿B¢Ö±;".ßöZ0^Ø„ri²$H	k¯!+ ”B4hŠZ/ßÊ¢nçôÊÕ-i¿Ó~6õ+²1;kŸ€¤Mònæ‡pvg.åÊ0õ‡ıá0B0bOµÒæføè.¶FÕüºç,ğ)¼&8½…‰Şà´¤qêÃ=ÜæK/¸ív*Ò•d ÌªA.Jrì‚w%@î3eußxN•H¼öcÚBıÀÿXÈyîSøEH| :Dãİƒ;ÍP-~D¤["¿4«'­Í#«ÿ
Áì¿…ÓÒ«bO0,£ñÕ”±Ãq€;˜­ĞHuE/P-/İyØÚCÄ7çµ¢™bí¬âeJ	¹«'5<æİ)6}‘6Ñ)íÇ1‰Ğ“›´VÃ…—Â|¶ñ­0ç#HìH˜CNÔ7)‚e@âË¿È
dfÙœX­¼˜Ê,#Û@u~+Ê¦ÂÖLf“z8+QH`®å7ŒÍÿ .,Ê°÷¤œscöÑvÕ$89ŞˆAœ"ŞUaØh¹²f
/gA;6P*‚kÛÕ]u‰'eâÁâúŠîªz^ ÚVµôVcÇ`9Ì‡UÈ:ÒÂÖò2“ìÿd¹Ø-°0W)$Ÿ øZKkÇ”Î$ÿUü'ëw-ğH–ëTíÜvg»ìLvçûgòôÆûÆañİ$[ I—ë35¸ô7è’ ZËéCo;Z±ö—g)C
á?]NC†ÑÒ0Nb8n(ºH_:·fÆ™.~G!ã¹o<Š—	ÆªKy”I­:•Û÷Ny½è¶»Ñ h±‹—ÁÛÃë!1³Ãş3 |Åí_T;"a{şŒ(§g·ÕÜ,ÑˆqV¥o±o¶pÔ€è*¿Â®u„Ö0h3››o°ç(nk«j,sˆ“a@Xé0|dPÜñéˆÇ¶5]şÙ­~8Öóû`^ke¾pŸ¥èé1½áù¥Ì}E/Ì"‚	{'ûÓÛ–¬ÀÔj˜ñÊğ w^
sÈ¯˜½›DE¨€ï}Àsg"‹wQıÂÛ 6¸ş¢…t§XnƒoiÇv„l9 Œ·®ĞŸE'í?¯n£¹1´ÉA=,T?$ïÛMÏŸëãÂ}¯ê€O5ˆ°Gªïcû“«BÀ£0ßÉ‰å PaÊæ‘8ò1¡YDU4I†! «¤÷º÷™ÄìœÖJ3ÏZ®Œğ©s8ˆ.çL}…Òj“¹jh‡Œ-LA^Lì9<eäÙk¡EÎ‘ƒ×PŸŠDlÑhg9Ñ1›|íıİÆ8áĞ<‘ºƒuJ8ªDÅ µ/ŸTÿå+Ğ;Cz¥€ùLešJk°¦‘,¯§Ş›¤8GªNĞâ¾–¼²;ŠE±h.!,Ç*Õ°ü	cúæ:ètŞe;4é"2YÇ¦.ÒP042dÌ‘1i¶m™²Ô¦OÃ,î?ÌHÑÈÀ–Øv±D›ş}§EÏÙ¿‰ä…__ Œ«®_2}ö²s—ê¤øŠÕTÿ"î–H3Ì¯²ÉX6‡øX$ªUÌò«$FS]ŠØĞ\!FeËGş²D¾%Ò}MfwWo‰&uY|dš!ƒär«ş¢I4Q¼!>PpÉDá_F†®Té)"†¤Õ6Ğ,bInjo0ôúÍ¢jdÍ!VI0(BÌJRš¥4qhHP¸í_Yf·u—RwlˆÊ\İ‘òsLŸ…üÒm¦RÊ­ı'l‰íZûVé[Õ`0®7¼èÊ²üGø2.ìA¾lİ†eæ¢“†ıó_ø-gîÃ–Åäû¤ğæo,Ÿ=8{¾'Áh‡ ³£=SnÄ˜:§V÷r·‡Ô›İ+Fdlq¨s”§¼?DRèZ„Øè¡_Ùu¯w#…°¤d—}ŸƒËÇ#ø4êçà:¯Û’5ğ»ã}ÑmùÏ+ö¸òY4 ¡ÛÜ‹]GHU`/Cbl§ÓHµ»mšl?ÏU´(Á¶¢cK|ñôòµ™ÌÅĞöµ`MfwÈË˜£zYòYİß!X›%J„_.™Š²–mú‹±KÂ]}4HV£½$Š”9S}1(¾F.øÆs›3PÁ eU¶ª¹Ø®ô*M¶uôQÊ®İ·À 3Í¨½æ‰ ğ°€ğ½ıVb±Ägû    YZ