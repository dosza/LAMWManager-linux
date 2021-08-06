#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1728290349"
MD5="2078bca69625da751087f4cc513bb7be"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23832"
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
	echo Date of packaging: Fri Aug  6 17:18:46 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\Ö] ¼}•À1Dd]‡Á›PætİDõê Çœ[²”\eÕ5æ´Wé¨@§ÕfmXĞ ºo
t‹Füô=œí7Ñh ÎµçÀõIÖW ‚TBd¶>ş"Ûa‚ö [’U´qk.€üt`•rLşé¹-¨µ] DX$^sJåÂƒã8¨[˜²O¸!~±fá1dæ¶;^ĞÌš4``ÅÌRoWĞC8¥µ¯µÆîÂ õlßó,S´ì=F³Fq›ÇˆÖÇ…Çôn‚ÕZ9{½ó4Ùÿ©?ôÓ×ÑºEˆzCTe–Âs¦ƒ×ÂünŒ¨ŒÉË2xö,FÏ'·Í¹<"¦‚Dû•l3¥—a×ÀH®R‘î!]İpj¾#‚#R¹ê ãçn¨¿¦AÖaÙúÇXÃôh\¾bë	TáZ±«½ÄŠ1,!p\$2ítaæLËD©Ó‡Zğ®ŸÔn7À%|`ÛE¹GÌ¹ëøóR(˜‚W¨õÜìÍğéÑ¤—Í‰‰
ûHnt¼İƒLsíÏÖ¤G½@ëx=Nµ‚³B`”bIñé9°Hrvş|×ßoh¨›Ûvx›¯éEÛ\>	Ş¨¸,F.YÊØ=cÑƒh'JˆH¾~MF“iš—¹˜Ô½ûF„8ª]1¦şcIÅ~ÈÿW GËYœµCäù›‘l¢ŒXn•?Hİ]'EĞ‰(ÑÉLJ¥¥h–ıÑ­l›óÂÅ~"mÆQ4%Ú›`ƒ™ï´´…Íß>x,º1òã»šUT·[Q¼²°k< 5Çw1ºl8{ú÷ó¾	;””Ÿ@·&¤4¼’<ŒïéGk$šz.q¹è½B°‡‹?“w¦[ä¾@­ÕÿoÂRíÓÒp’÷ï~yj+A§€>¹_F`ÉÎ·RwIp0´h©Â¤H¡sÓ(É·¬ö™&]¹\dÎÜn\-²ÛĞç5’ò¦ªÁ¾Vé^°ÔïF?j@ÑÃ(OuS£:ÒÌT/S×Hé@Öõ?Ub§kj‰jBè…Qòèåºóæ}ƒê³pŸ|¦?ÔÊAÌ-¯f!ˆ$#“¬Úß!—Fp¸¦(-è4ËäPâ­nÉ¥¬!W¡Û<ŠèZpXABuıˆÍûmaùZ&Á®{E£¦ˆÄ5
SÂ¶Ö×ïúìh]ªrZ»©APÅàCG†+ßL ¨>x8kâÂ½Y¡>Ö~Ë%b¢t®Ûw”_AÏåì—ÔsZÀ¨zŞ¯4Œ:/ğ+ó:ògŞIïÚ#Ş6Ø}®o)»İë:•=ñp•ˆVµÔÇa¬STOô¼ØÜX{µ.‘ÙnƒN°H%”-
ÉoUIí.ãş^•ˆ¼ÄˆÅ¶òê‰(áWÏqjı˜„± oàë_bz’À>Nyó8YıgGÄnø«×eÒ‰5¸M_`d]U¤	Ş5½R:Öd³OR7ÍåxDÑ]]à‚´Ñg7xºnª$A(şÆzÆß€Ä„gë¼9XìËüüLÏ¬x°ew#å¥Üa•Ó9Jàtƒ]Ë³¢ƒŒ±µIYã³K¦8<Ë9ã¯˜„Ş€¨xÈZ£t®¶‹½Ñu!İ¾D¢Cg?OÜ~Œ!'~ˆª=ÏVHb^%ŸírĞ‰AšÏ¥tŸÒ ³"c–xC‡ğöWbuRzé¾Åªë³+<¢OÇfH•Sxö? A5½’	;¤ßUQ5È*=hæ–ı« @–esnHYrkÓIJsSY,)Ã‚­GÔ‹½K]À©¤¤mh~ó9¬Ø&½<¸ñtğJÂ±|ğ“İD¡rÓâğcJ‰\¿H{qÊGØ—¯:İ‚¥Hm™ìßÇìˆ¤Æ fBôB¬ı;Û2ƒÙM£ˆÇ§X´FöÇÈoÌWGz:ÛyôPY³I?|@5Ÿ•©â-vc Õzï¶«£3ŞÑ}‘Ox”ÎE§ Ó,u°ù«¾7¢ïç	ÔŸ¯qz\ínkÛÈŠÃ/D0Lôò	èzüÿÏFäè¯q?xÉVnq/R‹í÷¸VÛävŒ	"P*Ã…Ñ’Lx	…¶¬!o¾-ªÿévZ[$L­˜}?ŸŞ^‚£9yÓ}Â¸+³B£*„¹ ‚Àr1Â9ÄÀØ×üãÓÙ“¯?^Âºr:È ø•¿Ğ»p¨õZ^€ıÁŞ•úïÔè€ù%H}„7,Z·®»ânmxÌRØX/L­3óªMÌøÈÂ³QŒZDùµp<¹„¢)œ^í‘J§t&¬dİ1÷½ Yt¥y¥@rÿ+ë‚¬¨Üv“Û‚%’[¿¬½ysÆ{@_8¬qé»‰aJsï†WBVï2ğŒO(¿`É¾ÍfÂdd5VÓ:ñ±¿ÉŒM0»¾¸à‘”4ˆêGAxWÇ
*¾Í|ÿ?)üM4´o:Ş5Å ¦M
™ß£RlG‰‘–&yş[`æs^ÆŸÇÃÔ8/¾äıgÍQÏèºV6<QD¾lÈı|p¬{YŞ&ÆjXuşº¶w¸jnQÎIÏ(µóm«}Ëcœ"'.ÂöYÃ‰uEJTÉ1å…#5)­bà³çWşsINµ“£S¢K¢ÉzÙÁíy¨8º.ŞÈÈ¥C ÁVe2~ô¾¢¥öVHüY6EgèŠ*ñ°qhwáPí±%û}zQçU»*$†ÆŸ˜¦Ñ^‘ö¬C’„d²DpôvGùÚ,^Pô¸AÄcÏ¥ÖúÃØ¨÷ÿäî»`C,J}êie×˜?J?ƒè*ü"¤ãÚHş8;»ê%ãÏe–¿d%Y!O†‹ĞAÕe×{ĞŠ¿Ä:²¯zÊøcLÕö¿K€C¼}|¸×¾$.™†¹Ôè†çÒw¹…Nu’Äb€ˆœn!gßöƒƒÔ²ÂO}¾M®gI\ÖÔ«y¾`<z'¬æR1ï2^ûNôeë«÷xó>ƒªË¿†‹	a ÑQĞÆLÚm öˆß«]Œ=ÒŞe »z|{Ÿ‚:ò+	§»	w9Et†E¦'ó—Ú²¢ça\à$£$ÅÜê”}œmí. ÛU…BîÆvæ¦*Ï~#KpeÚâàt/ ìPßY†,K+^³nâ5Â‚*¢û2&¥îØ±J:Ó¤„?µ°ES¼!â¹PY>Üâó…u3è™'/¼+=ÿ»ß|Òlyá€éâ¶dÁÁEAÏ˜±ñ•ÇŠŞTHOôùÁŞQæ¢r‘ëw˜[U®ÿCÊß]G«c2u‹Z U£ª7Ô+Lş¥^†‡mU¤Ü£;Ì.¸(œ+ Â¨ô›9óAÍ6„§ÿöÀ?ÁÃoËà¾¶Ç›‰üŞ2|TWÇÕ;µ*ÔÈ¡ØŒ
<õ™ÌW'Éöæ‚7mÖå•ßeîË§C{nnÉ=Á}™¤	9ìxğå”í8Ò!M–lEaã‡Ü]pÓÓÌ¾„„ŞÌAœÅÁîıiâòÈL õş5[9Şj–s÷¢)İÎd‰–˜é…T÷®âê	ø¸¢DHT«š'pı¬ '1¼ä¿Æ8³ÛŞ›S™àD¥qnc’csbÔl3TódW7` „¥¯²™“)ôÌ=gêf¬kûbªØ8±k¿é¦Jb%Z1;ñÒ‡¤¬ÖÆËº‘/½@±Ñzzş=\XÂ7ãÇÚ s+‹¢®,pÄºìÖ"8Öêö¦,OÕŒ1x­ç´{z’í>”+F¬,}³å°¾"QÆ±!¬¡5š÷½ ¦pñ<ša$ÚGÉĞÖÃ’âY›«Œ”6E9â±èÒ82;¤j°¾*Öğ?#Øv[OS•–j\x á¶®@Ÿ0”—İyâ cÀö8íõ’^™›¯û]Á·)zü^
İ9¹@h=	¦”†Î?jNÀG±Æ¸›9Dµ•ê÷%À1™¨e»÷¯æA	X ÿYG®¼'H‘rm¶Œîƒá]×2£eïa¾Úæö~?ˆ‹D?èËv•ì¬ñ¹QePÏ€(jGFÌÕ*Ã‡Ğƒ‘X/ã¿¹dİÓ<~ê4
êø¹°Öã2J“"¨›Íè¿ôÁ²/y¤·.8Qj4•4X7¦±:¡S	±É8šÈÕbpş¨Lö5˜“æIµ§Åèæ‚
÷$1À;ù<1ˆ"‰dö²ÏwTiû	Ç`(è×*)Iˆ.:`K¾ÅØóèÄ£}¤§½zíÖ‘	5Ş «7^N)¼øM´`*«&×¹Uƒr¢“½¥×s¼\Zè%˜-Mvö(	höïW]±CÅŸ@a“ş\›*ÀEß¿š~†PseÊµÔÜ{|	7õDÁç‰¯ãÅN@º éî1{Eæ ¶ZÁ®e3\æóm=Ô4Üø0—ÿh"Ø5]ÑÕëõ¶ÅöVxG…×à\ ÀÉ±’¹\p·¯mDªÌÖÄÚ¾æÙõ‡&mÀz1¸‰k
>@qèœp¾Oâ¸­sL‹j)u¼9ÑÃa’Aå*6?Hz-‹ã¥Ø¼åS óCÆ¯ß¿<Áµü¥ŞN;eö+‹¾ÚÓfÜİÌ¿y4†ÄI‚ù®ün0yÁ36.VOWŞ¼¸n³b@ w¬œ»¹İÇb`Ó£ÁÆoXPÃ„¢›AÛ
™£v=ıeBaDZB1Qí‚Ì&Œoú÷mêè+“c\ó¼–;é—iíúr9"Ñë»`ÎŠ¸_Î›Èv¦wvBÅró§ü
äÃ&sT¢êT8À–w“½|Ÿìµõ.Ê­äœs²5vQ$`^e€O€¥ZMÌèè^…!+õàòÒ·fckÚæëwÂĞ°·OjœS5çû%VH‚Ñ?§ŞIIı¶ZÀu„ƒºA.öyäÑÃ™aÒ…5íÓT¸ºCÅq`q/=½™´œ
_Ü2ÓeäÃfb›=s´„X €—Áh”dÍşŸBÓ³ŸSó”-¨çè%hìşÎ¢†PËö»z_û×ÒÀÚÚˆ•PJ€Çòº9¡C±—P_|P9ƒ`VÖ'Ê³LaY±“mx·V¾P	Âœß€¶÷°u|ÆT¬Æ¯ü¤º‘ãÕ&\<ïøZ­¯ç®*çñ†TJG*]Z¾ƒ‚•Äzv”ıD°‘X!¼º"Úó²g™sºöáJ»zUàâ›¬°Ÿûw×«§äÕ=’g˜l¯£Ÿtê'øÕsß†HwÆg&Üª:yòĞ·ôCB¢ôª¥Fş³g¢Ğ#$àçƒYBw&KJÔBŒÙ)5ˆúÉµØƒœ¤i—òf“††—ãÇj§7Î¸†B¸qÁK¦Ãj¤‘\†ÎOP—ÁYŸø¤·õ<Û¥zš“)µR£/ê>¦œ&ÏÅîX
9@fôWpZwxşŞkí±?´½G« Zàè´‹ô&b™	)(í4é…0+RL|{.ªÑ¥âğtVlòöÑù}%"¶Ã	¶ØO{ÿ'Ÿµ÷ªˆVûi<¡F-ˆö@M(yxíÇßt·8}(´®I¼©&yÀ0Û’é¬«ÍÒ@ÚÌbàÌ÷ñ¿’Î;şZÌ® ¶Ú%²O“ÅZCw–+Y=WhW¦ù0èˆ‘ÈlJ” ü#íÍûjóà××Áá¢ñB³‡+ìD ÛD·zÉeæ—R%ğ ûCÓ])^iv¼,DA°½¯OòIåæ•/–‘¥1}Iÿ‡¶ìÜÒ>nl¤gZˆûƒœ‚ï0,zşë9	M†¡Ù0êİêÀjŞå‰ #nCIš¯¶œnÍ$c¥Î—ãaK_j×ÂzÙŠÑÃQ~qóÖ`[5K~ÏZ‘ ¨‡ÇzJÈ}×º²aQ8h¥1Aå•_šÊá•8£× íÓn–£ÊÊ#½¿S $ƒ'`˜%xyõ½¼ĞŞöb‡Ğ.ÿa®êÙKãæT) ¥¸¤©ô4Ûç œ‰ÛÛ>é7µ?qw İp˜³ÇãùGrÎ®œ« lJwŠ,3ÿE«ïê…<ŒÕ¹4„Á4 RÓÀ¶íø‰€4¬êãğ¸D¾¢û ¿õù˜Âş)·ß/Y³À§cÜaE•`»\°‰A.Çğ€û ÉbR=M¥©Æ§×ú4eºc«Ñ7™Ò’7K‰´ÌH	˜Rhh¨Ïã_Ve¢p4ÃÅ		ïÙ_^ŸÆ¥‡~Ö"vQÏ»xÛ[o@ô¾Ä>Ï´u¥>­½BD-%½…« @ënİ£N@Ô¦RQÖ§9"OƒÇ~Ï=uOŞ€iXœ)ò2ä8áL}+¯±Ÿ˜¿_$p—Y)ÃyÊ2ÂRóïŠhá.Š~4šLn¸„psŞ6¶Öç§ïÁ@cƒ0~öæé›P¬íÈBÓ$3æ(Y	­,ªö*	ôœhø?´Ú/Yø`_*ã±. ñµ5üE<d¥Ç¼¡ô[-Ç%ØÃ‰fÊ{Œr]ô“Ş ê£¿qÃ·Å!ÉŒc÷IŸ0EÙ›9eìİ>
‚5ÎÃ¿- #ÏÙ`;Ö•4óÒ9´‡FóëÑJ[*Óih5ÖI!€'ˆ°ûĞö×šœ†òşÙd/	ı	F1]y°€‹`ÇP|¯:ÿlšƒ]q¹SÅ{“Æ/I	7k>ØµJÍÔ"\-/jí£¼íÀû¡`¦œIÄ˜H8¨p\ÖqFH®%ëÿ§$òİ€ä§Ò½k}à&%ˆÚw„ïÔŸe{Ôûqö£Q€í:—·ù»h${o¶6Q—¸ÑâÙòÊêŠy&õs÷Ìİ‹Õ2­„JFGxS¦; Ï•”ŒfR‚¯b:¢¦Ï â»äÁá”á‰ŸD‡?…}o«Éî»>6ùíó$.÷‚w»Åôèó™‰ÇEü¡Ñaib$ª5¿E´EıÒY®¸|¾Œw’9…kµşàtŠˆ rš`Üãv¶§1hh•¢{Æœ&ìõP(àivÉµËjT:ñï½ñ,œ•ÀÏ|ªXŞšFŸX«	¢¾”)à5µ+ù /§ìe£-†œx	Ç6š‘bíî¿úÂCô\«‘xøÁÎß€7€ÙÕe.7R4m}•èüÃú–Ö®õtÇÊo±¢¦QØR*ızğ0Ë;:®Ù¿ƒ:ğäJÍÿ8é ´9”¥p½¶ÍMf—(|¥wG§j#ÙO	t¢ÜÁw\¿ß÷˜Ñ*‹ıyr	?ÆŠ4ÃÎ)Bvùq­±åLÎ‹ó n	S=€š¥ÚÿÁÜ¢Ş‹Öªõ@ãy=WAÅşeQ	Sãøß-Î"o¡%G [Ò•cÜM€Sz¾V÷gğ„šhæw(>àvVå²V«?‚6´¸"«×l°ï)Ÿ‹}Q€ÈeI<½{’WÙ€>²RÚ×Õš‰ßa–’¤“¸8:ç‡.¦ïÔmYãfTGÚ>î|ìï¾ì¿ßcÿPM3}fÇL.Ï)—å+=Z?@wB@Ë3ìz´/¤ÔZa´üWW?—},’jr½)?ªÖ»‹šD 8ÊŸ¦İYãaÈ{«©PüÃ·³§'‡LÁi7NÎ÷~pi6£ICä$Á¤±§€¨MI-{ô…Èy¡CÃ·¤İjK•ÂNÑ†¦ÓÚÎÌbK–^%4é~:î­äU‚Õÿ#’“9Åõ–îJ^ÅÖg
™¨¡x%„1ú:…6_6I*Òëa”2Ê¸Æí‹¨§bÇÈÅvVõ*’`™ŠÁ^œo1Õ”l/ó[A ëåš/ÓÖá‚Ã±6ûĞ3s¨F&f/Ù»Æ Œt%\ÔU´ ÿ©Î E±ÕŒÛÔæÆÜÛ„WÙîØ Â,{©áYöh˜Ì+Ii§{LÆ4§Y«?º1¤ş€Õ	ùmøê8«Ë=Ş#¡z±Hÿ fËïµæ&|F’æªLu–¹ÿâ ;
ß%¥Ó15S…µ#İr e¦ 9p&¨L£ÄAññ¶H5"•ªÃY&>ŞK3 °0=Ì®ş0§Tšô¿~4MáÃÁ,Ì‡`ÖFÓÑñY©£Å‹LÒ\â¬´M…™Z²Lq_¸«RmºanöüùSTPíHAS·áÄw¢Ê›v¬DùJ<‹+W_9@şddãBÅ$_7¿u\&ÈChL¦–¢Ríy™“€Û ÂYÍ§¬v¬ìİ€ñù¿oµş’à£³ŒÒ¹TbÉï=b%<z‘åò¶'Ğf`”h¿EÀ¹Cé·Z)ßd,ªb ¸=’¥JOhAœe˜ñ×Q5m¢l(ÉİËMú‚AK‹.^ Ænì’´,ğ£ii¡K<+¤b™¹)§,›eç±T¶ÃÈ‚]¯[oğ|zû3°ÑLÚd2ä²ğ‹aûãk¸´¨`±B»N•µÜu‘¦80A¥—GI‡×i©GüI3…€ÈËúÈàµ,
>kå	!‚§Óë?Ä_ÕåÃ:ù Lˆó
U÷b¾±®«€]~´ş¢¬j(ßßà ü¯ºÀÄ¤r«Ò@!pÑCÍ·ÛÚ‰1°­9söÓ¢.éø2zPAÿïœ¾³ô’,?fğ°§ˆ?fó¾ğ_éjÄ[(M©Rnää~,Æ*Å‡Z¸+`V9Ù\™ZmQmËU@X³ïãzıÛßµ:T&&Ç«S¯Å‚²|Â…‘äb×¼"^R®È·`áÄôÛ½X,pú™b:JLÙõ7\iDaƒï=>võñ×å›1$q(•µ`¹&Åèûî’VønØSxÒäâl·1I™xÉ:q™e7gÚ1 W._BÙ}{÷+ømÅ{ªÈë&¬–UF\]t©…:iê<£’>Ó%yShr*INuç'Ó<ı`§¾¤- è OÕ¨aB«û	îîUÀú¸ù)¤¾ ‚-ø®FRˆzuŒ6µL31S×¯ÎË}~¡5ÆıV/¼•‡›Êœ3¢?ÎSµŸúÂÈ³FÆÎ¯Üêîü.Csé’å­¯î9åªâ+õıƒ¨Ÿ’€@Üü
,L‚zxxÿ9K'¬†ÏrÆaŞ­¨âª„Cg¿fû$q¶j	h¨Í |FÁ¦VJ0¤’ä‹Á8dK…5HÈ›îˆ®$%Æv”ï·÷ £€ƒŒMÛ[aÄó‹f’ıO8 §“ÅîI<V†aÑ=íJ¯xnjñ=f	C\ûa•ÍxZ "7Ì–Šg´-­~Qi-´Ÿ×ñŒøıcZŞîôTï¶ªi?	Æä¨ëÖ÷Hj=Dh’¿ÒšZ¸³0™í¶N´*J‚+TxJ‘¼ZÉŸ¬ãÂ.A£XsK!š}”, ·õ“eÇ±wPì¶uõù"â=,KŠ8Mv3º8M]&…&×k+N¸™XÆ˜ÒÚ†F¾„ëö ¦†êB`ïyÈ¬€CÌY÷õÇE'?€OA6ã XŠ aÁ	bQX,‚*igªãö]$²s!”íÛRG‹6vğc¥|x[çeC3R2ë&sû.Ï•êJ±¿K€¿=²›ô‹„Qu¿-_ÕÆ*}#.â¨Î[ùBf…h^¿­ÜŸ
™Õ–†=ÏK–>2£0ÙïœÃ¿ØË¯…“Õ<€(|ƒÆ¶hrï¦í? é¤‘§Í=4!*mšU! —¯5AÖÛLF~q+ªyL‡öÏ¬›Vÿ%©¤)ğ¿íXÚ£Åúvç’goçDÄ'V¸‹ûu^Ç~œ?m¯_¯cü·ÆŸŞÌÑ0*Rh‚½ù2ŸHlİ Ìoª½—oº‘àÉÉn–NÚ‚øOıSÎp¼"1­ W‰ïˆIi5!••Ëó’»?píÔ•é¾crªs9V¤y ‡˜ÚüR·gã6ßLáÄú(vİª&¢Æ9ş4”ı3n¢
ÉE·jVºÜg¼İÜ/ê¾Ü‘”UÓÙØêq"¿O7/­ˆA1‡m´¼¤, }¯^S~{;%ä¸.x|µiL†[™PÁiË]|¡é~ñ¼APù–¥îŠô¶òTíj3‘ìbƒÁn½La#ò½89»H™Fµê7¯y'ó»`ø /Í!MÑğ~‹»2ˆp(â)2 eéïm©+xM’zk˜·:ûÉ–Hªï+\T•ù¹y°PÔ÷Äôn=!’ÏNÚäÁ3ö€2Ä]:ÚÆ“Î>GVbÅğCœÜ¡ŸÓüfx’ÒÀB¶¬¤J`×5¥±ÜE
¶÷˜
˜ÜõÔ@ÚÍ),+>"ù»FëSÜNàªSiÊh›4É‡=FFÍ¸¹*E¾´4ˆg¥k(tR¦"œƒ£EQg!Ÿ“Øç2À¤¹XjÇVœÉñ,~<Z€c¦1xÏËgÖ‹Æ ,,høˆt>ˆ—pÌaY,sK"‰@‡c|=Ûß³àûûÖ1fí*çH€l¼Ìä#­’¡O9ĞPpZØc_–QcLØ€¨Îõ¾TßM„z¬¸54ñL¯ÔzÕóîñ]J©ZíõätQŠz) Æ˜š•g8v¾^cÂ0è`Ü¸Ÿi>ìáıSÍ§Ïgi´kbÍï¾n$§ŞÒMÓ¿av+yHPG‰œ«2 â1ü!v<è‡›o’ê‹÷¡ÁBá<¡F %hsËZ³ß…<(l¨sß„³ ›ÔºøPkâ	çmñ0aŞW>x8Çírù¹ÎvjkUA‰è¦lªƒVßÂ¦êj§)0**Œ›.'¤f	-:^©M0PŒø†±œ¾]Za¨f…å¢¯Š7òáÈæH—šO³XÂ–‚ûÜ|¼ê†Y°e%ÃNçÊù[°‰C)"ÿş³ò»'ÚÀˆ§z¥ªXÇ±ˆ½æé¹ŒD½nè#®5A»×4­à³ĞTÖBı:f¤kÂ–˜HËıÌüæŠbq{_?OX·ËÕˆ‘‰Ø§ßí^^§€‹¯t8ïÌ$îBÈî='¬À?´B[ÂŞÂ‚`•i},FÑ+4€°ª î¥ìÇ
<bœ°f¹®ˆ(ÿEŞ0prq±JAÜÒGåæ]gHÏÑcFOûFÙBOd[€×!²JFïüjwî,#|k+Ûµj8KƒH‰-9‰¢>eKîû‚&…1ä÷.Hğ>.U?î¿dKSü:¼!oê˜¢î¬Ö©]ß½}Ò|ì¾Œ,u-+¢Ò&è€ê3­iÅ7Ñ#å?"İÉR4‚õUĞÙ<²±
ÕÌï+Ë“ê#£_Ÿ-o{Á]Ù¯sÌ®yFÜ•ë`ÂÓÃB…b&v­G’Ñc×ŞìJN¹´¡]Cn2±|¦µêñ/9Ü[J\v¾~é™Iy5b-°ÁƒdC+Â›yxö±ÍÊe%ŞI4¬d÷Â¾Mkë…€o´ë3´B¤™0Ù>‹0ğjÓÁ&Gow*‡#”5«0í1HIÂFõ Ì× |‡G‚ezq‰Ü®[HÔ<~÷b¶äq+Eú¬t>™¦ÒRamM¹Š^ÒÛ®Š¬óã38YÊë‘tHúÔ™¦•F"÷š,ºTïl\Ä2n¥“£ïäuîğÄ@¹•¥	›×ÏäƒêŒzx•WZÉŠÆMwPAÒ¸Å„–n($À-ÛYæÄHÎ›«×gö‡·i”@tÖ*`-™¹İØŒ×D]­D’ ÕOK4›¿Mé¡ÂÑıHÇ'™‚\¾nè:^#!\Qı×?±1®z–“ÖÓÔİ ZşN·C›ˆ /‚`]²qrd§:ë¿W2w~i4ÆuaZ—¡ÒÜhª«öÉ*ƒÀDÑÃ^}îü ²<°Ïbf§İ QaÉ‰»
ÉŞ}ºãPÉQ„Åa=i¡sˆãƒûtœ…ÄşèI«ÄÍÒß2òâ×)!oQ›JÚüêTQƒRúƒk›S‹ï¤·Ø7"ÜŒQ´úeĞÌ¤w˜7 Åø¤o¶ÏØa­İğŸ¡,¡akgƒjK	ŸpşŠ OKL±½Ÿÿ«/˜Î¸yI®÷'?ít±¬úÀj*ô‚óÆîóïcC§emÿÓŞêi9¬{VbSCs¼«€Ü1sˆ³®y8ÁK¹SxÍğ;Ò¢
ƒ‹Î=Îbûd«5;µ<5	 5"6úV•Eõ®®Šò>û¸àMD\¯&“û<áÄàöÃÊ‘¡œ9ñéûˆeõÖFbKã}íR/·<«RÉëÖ];`ÙC‰êfF­•õ8AÃÔUÆ¡°Ğ~ÉTí$u]t†‰s:¯G(¡³°S³~gÔ'ø`‡¾]LUÚ ç¶…¸YòÀ/.|Ò"‚oª–bj´ÑNpQí„-„°Uñ€é/9`VğÆŠÏ»Øøî¿ªÅ@:?vÛjÈ¥n†|  ©ã}zìškŒ!­Íx¼—º€©YO!Tò@&ÍŒá4²]¢KëdMä2Ãç-î]ú‡v³¹”O'ÔVéôâ6Q z=_4»•¬Ô.+X0N(î-XºœaÄêÂçA¥X§kÏEÀ$d}1‡[LÙ9¿ŸSIÿ:·[–"±Ÿ¬I¼N {¬²=ï
´vêLÓ)†6$Zxz ñZBbmÔŠAâ/Â¸Ê1¬´=m,–ĞıE»Õü‰}hbO§ÜBÄmô.mD	#Hs¨êhµ»Dæ_§"À¼©^=rû·Ä %û$~µè ¢hÄU­ŞÚ^u1‡ğCôN=/fÛÍ‡¥1Şü3áL|–ñ^€4ï%ÇaÇÃuø¤7ltëu&kÃZƒ™'eOC‡,¸AÒbËG5¤ úq9ÉUŠ(E´m»†||äÙvOL|æŸä¯òˆÔwÅÓV<MŠÇ?˜’h*ï‘1<ÎjG¹4¨qi– L&ƒ–
«v¬|‰~u®<à/eÁ¥&Û+¿—Ä[^ë´çq(Ãï¦e Nv§Ø
.Ìº¿éÖ÷Ô×øaóÑáHÈ@}›¬yr´ØòFeÚlÂh0}øæ¬VbFà+B¢âå±Å!­Ó›b·Y›´›âÿÃu¯sĞLÀèX§bZ×¨éë»Ôşä¦ máA_–°¬‘oièÚùØ&:j/ÁX4"ZâF‰imu&ñ™ÖâmìcÛ{KI³±‡)Tñ=­öÙ¢»îC3ô"Í=8‰.¿Cı Ïİ4}ß!Óøhæã7{Ğ!›ÑAâå¤Ñktƒˆ8:Á¢Y“Cõ,”…©›‹g‰€ºÂÂRmh8áˆ¹—¢:ÂºyÕè``ä.^~O
GÉ5´Êe†b›ßJ{/¯‚ $ù……ùœƒ¿†X;´ãpÑi}(m”ˆÕ{Ñí½M*õ›øŸ^­œÃæ›Á¹Á0˜Éé×/aÒ«"Ñu'Î[„›eFÎ ‰™ÔR¶g3l›§ÄĞïNáªà&á7ÌƒCåÛ˜‚¼Ñ(\t¯šmqée0µÈ9\/´!Q”ÅŒ[tÿÔœQ*\*lÇĞ­ş<–ĞµÊ0/Ÿ%Ş>f¾ˆvH×Q¬gü÷8õ¨İé?} Ì‰vwJOsş6¸À³y(aÙ<Kú÷§#¯ıªLù~]2è¥˜Ù·ŸÀ††M®'„q¡\ç£b7È·`D˜vÍDÍ°±UZsšïPD	öäüĞ€q^:®/_¢¼Ê¡Õô(²[¯p7ë'´IM¦Ğ¬ç¿—ÄõT¾ÁØ’¹ìCq8¹â
?‡öéôkYçøw¦\âÀcrq;9Í*¾rƒdÛ"ş¡vh=pñ»¿:/J–“èÃŠEóyŒ\nv±ÿc[‰‹ò[XR¸É¯Å"¶ó^z`xmJ"p™À† RK·Öïa¡¢ v'…vÊ>ùÅnP:çÆR5R¢ñË€Ò„¸ür¬Tv–ß“Ä“@ía8×w>e~"
<ó¿ÃC„­š@2Ø¬§¨Û|ÍÑ©33‹^E°²~Z$`ÎÉrRùàa…Gı´tôuj#Ïˆ!ÚX‡Æ9ô,cN–2xÂw¼È¾m'U¯‘²…bÜjfp|'Hì¿€­6ßx«¢9ßÑqóÖT8ÖËe¨¼¨ùñNèD'ÂI‘|7ù–|Şm]…Ì‡ <g]˜3¨ß¿¯2FØ6¹”´×?v'*Höûg*¢§Ï4´_ 654;×_å˜ÅGé<ö˜gG“~¾p+XX]•İ·€÷"OEü37Ç![Á!dåÎyêøÎoMp¡¦¼ä{„Ëjö–cÊD;ô×¿¯Y«EÊ’µ¸P°BqƒB-ğp“1{ƒîÊ<!}[èáÅa¿Ã8®İãÒ˜¸á»ÜÅ{ë}ÛÍ¢Mÿ÷j¬Dùº5gkå™¤Şù§õŒ(>VOj{€Ğ{ @ùóúgÇg[ÍïÁ$ºˆÇ5vÆYa+%Ğ3–Øú»Q—Äï G6è0ü’LoEÓJû¢à^*ŒQJÕîÛ¢ôÍ^#âsƒ´phAVáò^•8!-æ%´ğRéò¶Ô¥Oc#ŸÅ_Ó<ô†VØÅ›«1¿,Yõè= Ÿ¡ÊüÃÉÚ”‹Âİ•ğW}H•bŞÂ8iÀøÀÇk×==û‰L*æöÛ–B)£	ÙóX,®*D`\@*Ci…—4q<­pq[!oZÀ¡“K6H¸¸ô9 †éqö±ætw¬.ˆáXåB÷§X½O}¥ ÷MK«å&%Å¨K]ËX&ìÑÔOS  91«Yi¸ÀÑ6ú5ûË  A\mííQíP3I°ÊşÖ¿åüàÄ…Rsó˜ôl2u¤„x!5ÛUºşÊÍ*ÑÛHIC{ÒÓMBr Ñ~¦aö—‘PSmÔ4î­lÿ,vCÇı9Î²z•›ez]ÛÒ=Á«í351â+tÌœ‚ŞÆyäÁ$ÌøWŞ*£ 2!×5€lü”¯¿n…ƒÅÔL›·–Ì\[FœÂ„Şf:7§½Ué×‘b|òåîÃ»)'ê€NW)‹ª®VY|9*D³¡´y…‘^Å|f|şDÀ¼ÚØi‘ê­ôµk0…÷©IEn2¨ø¶æe2æÅ$MctÆ›bK§™FcÎî¹JÅìXZ’@3’ ÆÌ>¥yÚhŒjå¸¼çD0j?M1•<OÚ)ŠÖZÙ‰÷`rc~ ñúcJ§Ğ¡ùª	â«	RaÕ~CråzÓ+¥ÔÈl62¤ë€wä “1öÑI*ªÎÛ„îı8¸QãfM¾sõƒnn;ªê‘­,’İîDd?	¸rpİîzD, ‰}ä6DÄkLèÜîw&3ãÉÖŒ„Ç*4–‹.³çáhfô§ˆÛfºQññ×¥ı#O´ôõ²¤Tôé¸^şcılš/«ú›t2ÆtMØtärß¨ À·kõù›n@®të\?	í×»­ÒÈ‡®–Oô!–òİ²:‹ÁG™­PÈíğ£aÃÖ^MTš³/ÇåLAôŸq‰E¡½¡Ôóx
v"’†•Êÿª²|í*¶+ƒÅåÑFöwÁˆÊêvœ7S”G"Y•3Â—+ã#½Fm_v†y¼rÁ]g*PJ9›pü9¯ìëÆ†±ÉµĞœìfm“MƒùÇPßd÷ûòÂ”Ó]ŒÁ]‰ÀGh<­ñüÚ8e±a·~7 î Zd0Sq&Ãzr	Cx  ÛÙ\!¨½‘q$ş‡“K0T1e‘®ä®íÂœ¢–Z#ŠaŒ^Y­ĞÁ%ª‡ìŠY±ÒbûÓ„âcègN¾ÒèãÖç8Ô'ß™p½ÂÅ¦8šôvç¦ƒ„­Šüs»±AŠø§–³Šop+¸q,ı=pO¦âò'~¨Œ¬Ìê*á&?ü~+,Ø¥ÃÌŞ®%™¬I\WL›òÃÍd8ff¯Ì‹G‡T:ğÑ¼I}ƒ§§‚·ÿ©u­ +|ş‡¦Kì Ä(Iq,®¾Áó0­5±¡Õì©9ı1” ÇÇ
1hc?†é@à-QS½RÇ”ª>>ãnÚ´'ğ>$Ú`´G0°øÙeÃÉÒ«4C‘"	Zá¦m ìãÁ€¿²-s°-ãİJîyY«ÅİæF»B Æ£´¥ÔŞ^ğ@$µ}/QI,Ğ‚Áï–èÅ¶DxÛQ¹R³dÊ¼V²!v¢
õ Ÿõ4q.K˜¥(ÆFAF#vš7ÈIb7ûï\ª^>ãóå£Ô5«&àº«
a&ÜÂ V¶¦Yz3´Œ’«âá6—ƒ Î:´2à¸2¬#eÑ¯¶/5å y‡SÌã=³|›€¨HŒ†¶w_"òòªÏâun´@üÖy÷¼Srs2şpC¥¡lúEÇü@ ÷ã%l]B	Ñzºk±tÌÛ“W$f¿—âíxÍ¦gÌ
å‡ P]›|ÒÌ¿:fÖZÎCõoíçõ3›˜şïC`óÇÖ¿á—N¦-¦„+¢-ø†+×É)t{‘†B ãû†6±:kbƒŒDumç>OpäÃÇÿSÕh®x®†~>ìq¤.êÊgï‰pÓÒq2Tn¢¤Î—±¥à^ŒyÔíŸòMşğ¶íéT¥Ê‚;¦ëghë–ŠË&—ÎÜc×Ñ±v›v€¡ £ÄìÇBDOA’³òŞ`¶#i&§¹´ÆH•ø’ÈûÛQğ®'´,‘ƒRÅŒë7vÏåêIÊæbÜå(RõU-³3û®&èŒèí+€‚• ˜7à’F	n´‚ÚãöğM•°@ÄâYj<±œ'âÂ¶VŠ™@Æö8ñ;ãõM‚¡BJ¼ı>CCÜrïì˜+û•æT¸ƒåÄAóğ)zf³ÿ•˜ùõÑB_ÜµÏ F´‚¡ B¥ó§óùw[¢†ŠÅ¨Ì¾6Ÿ¬ÖÛXN«1¬÷RŞ€Ù]ÿ ´™Í/èlÙ˜½g…%ÃOo~KlÖxízd°ú¢åm¹A8ÿ£}ÛŠVÇ#ÜÃ4ÃãQÎÉd¾É5)ìş0³nõÆ¤LøìC%lë…Í}é¾±ß	İI¿î®¹,pv²HÓ6êÛ?ûsau*ÁXgM?İ{­xwÿ#!ğì¥ââ¯ÅĞÄR¿Ï½]ğc»"«d}J AÀ‘×ßø“]§~«½ñ§Z!Ü‰gËšâö|ò/Ë×[	…;ª4UYÜ›f“Á%ÊLŸ‹Ü#\Ú^¼öGf¨Ü”§tï[ô3^¦ãušÃ=WşO«,ËTFDí×EF'£i»^e]ÈW»Ç›ÌxØ7ëSS`¨6G­®êµ<rí=®o•^MõêÑJ˜/KÁbàÃµ2
ò©.uó?vYÄbqô'ÏÓó–í!ïÂ‡É\«k¥ìÇëíİò *¢S­ÿìŠäÖŠ7†Ñw<•ÁCÃÑióíHÛ¦Mq$ŒŸ$øIş®%c”ºSÓpg4Râ¿šÅ<£¿:Ç>àypºüüí ¯ï˜N„L¯#0}ÂtôD ê!Hÿ‘KéN¥êNêˆÎp÷G">ÄßñBè}¦¥(švĞ2ÈsŞ*»…Ğ{#2§‚âd_ŞI`;á÷ıC˜Hì)ïqƒÃAË
ÒÅËÆ„á
a4ğ^˜f¨M?\¬Ó0í–•€´ß´»åwµ<ô}öèN58p®ŸšqºşîA¾®±9ÖİÛFdÁo`ßa¢_dm™thÒO¯bÁüÈŞ-
‡èÆÌ!óîYb©Şd)íXÚ¶’›@
Èq?ƒê”ĞOl±é¤–ÇéÛ¿ƒ±dMm\›Ş‡SŸy½Ú_áÃ€ ®öã¸ªÊ÷oÂŒ[Y›=VÃN|ÔÅ§ˆø?iƒağ®õÇ=Cš·ŠÿÈÍ-£ÃZ§ôÂÂíÔ1b¹=ÁGc”Ó³¨şRª™›./nó‘‹¶á RGæü²õQ,™Â¤Ğ$ˆK}½ÔMY˜ÒRû; ÿñ¥Ê•s*G9(Ÿmhn]+Í°¡+×Ú‰ÍÓÕ†‚µHl"büò­fóPqŞšû=ö°o]uÑc2Î„ ïy¹ĞvåìT¡<,ã‘ÿ÷hËùåß” "»İN®4úáLy¨Qx°ØOœ¯’Ïûtj(Oé0Š™ú¤%Å?Òr1òåQÔ×¿ª!çÂ1ƒø-I@¤˜M®”¾,Wî(qõtÆåşğ½4¯4 İQchæ-±‹>ô#ä”8W>Úosªì@o/¥ ï·‚N°2Üc¼ cØRópáŒx€©w·ä´U 
TwEß>Ÿé´¥K˜CvöZ:…0jøRÖw.4ã¨¯wÈO¬S÷qö0w™ÈsÁR¾sr)vdoşp6pp£¥Fÿ]ƒA£ñĞ	PæVºmº×9ĞE}Nñåf0Vs‡µÄrÄŠ4ípCßß‡"'9 õê%ı\yøæœe€`Ÿ~.-Ü‡ìIów¡ç”ıÅ•>
çH cDŠÛÂ.WóiºÉß¯CiøoHxÎ×5æBÍ(Nˆ°uÃ¥R™ÌVÈŸ ¨ë8<Ùæ‡jPú¡tm&Y'_6ÿİ¢pk!ŒÜéÎdŠí¢Rœ¤¡’Nô.Z–UóŒŸÌò-™’¹z•ÿš°»GYºSlÒåD#¯íÔŠ@‹Ë.Hç7ÜŞúšÅXMÈ±AxH§–ö`:o—Úx:ÿwæ®UoMÇÔ“–•j°Ëb™‚!sNÈh®0T¡í‘>œ‡cİ°c³®ğÙ'3’GŞc_{ª‚Ç¹?‘÷yÚQÊ$ìFñ0èE;äú^ÇtÛ¤Ñ>û9ì#M[M(…//¡8ïü&2+”_fõîô¤uS>ò~…PW
_ÊÁµ€…ÉÀ
†Ù¡ÖfmÆƒ]aómxÀ¶Ï#1N½¼—êÆ€¬W9y‘Ø„qEº¡rCƒ¬¼†úm±ïšh`ËSLÂîñp˜qÔš…lÓJNòêş"…öí½Ü îÈ-‚ß„ˆĞş­´m²&‡sW® R[-iÀ+ˆñMuBUñ
Ã;u„©45Fhì+¡Lkbß);»ı@ãï<cM»Áõ*™ÉØŸNÇŠz+ù©ßÆÜnu£Ã#£ÿ¾:ˆ.û‚×ªG Òãİ@§,~¦ ‘è­9‘ıÏÑP¬Gq§â‚/ìCÍó 1Æ±QÖ`Ëˆ­;Êˆ¥òm=ZEâÛ’'Q°O
åeÉ|¬§~#IÆNqbv¾s8êo`iAª«À+Äzˆ,q3®úù·KÔó­°‚õ¦²MÿM&FAU…R13.î¯wOú¶’reXv½6«ìq8Q‰Kì•åÈPHAòøãu5m>½¾[Òù#ÏÊIŞâA	ßà>\V£-è%šªâóM €¶'>U–ëÉÄiR‚¨ÆØÄkS;jKå])‹!b”Ó©6ÑNU>Z`åì×©œc gÉãyALwÈ)ì †5ô®İj óFñúÿ–ò€æ}>ÍÈ$Dâ“®å€‰'*8ìş¿«<w_:¢7<şfPÔ¿s^œe¼„-»=‰œ/A/Uõ¥¹ŸÍÙ‹hm	ñFaÿg†ÅX\Ëißë3/æ™àùì±€“ıqÉrc/Ô^r„»Í®ü,XŠÕÕŠQlTkY™ÜÜõ‰ â¤
Û²ôL$ak>‡Û}ª¶ìÿG3$ÆŸû÷;«%Gn2–Vñ×¡n¤ƒ—ç‘&¡qPƒÅGæ58,XÒ S3&¾Ó˜Çe?M9¤·ìŠ—êËIRÈ‰Ÿ)‡8÷Ğ“«ùš1ï'#_%B~‹êTˆıúiP›œØ÷Š>(r¼¹GèÂäi®Ğ\[=æ“ú¢¤ßµõw— ®	¹®Sà/ÉÃKFÒÑêĞš[cdÈ9ÖªÿìI"¡OÔ¦ù‡Ø˜ñÂÈ4RüÚw“è($óCL9…µJä“”*$46bgİ¾J.Dˆ¯Ÿbş½&ÇÙ¸¹MÍ„
Q:#nj™ÁDo¡2Ş“4é‘ÑÁi3ìwıÑITpÌnRâ+N&a›ú·ğV­ [Áä%—rèÉ¢š>(Œ$–YUMVIÏ{éÖŒH«8Ñ0 ˜Ù–[°]Ê›ùÙÑDâ1
¢¿wXySçhÔ±!‚sfO¸äcAä÷/Q·ÛÆ×ô¾Ê<?7À?¥;’uÔ:¼·3p*Üè¬$Ë.\æs©/YÀ;·Z¼:Å€÷åä@3ã¡áB'äù1b¨SÑS‚-oñø¿°‹™ä¥96°ˆH:iqŒŞ|ÑC„RèËÚt_6ïÖ6ppŸÛFGNç>)7¢K :ÃŞkoqÊ’1×¿X†Aód>r ú­.Ÿ5Æ§wOÓÕ™s¡¬´åÓÇa¢6ÀÛİ-Ö³Zãçâ¼˜Öøe+>Á)Ÿ\rYU8]høH, ¤Ÿ]Ó_”n¼=={Qù6n5Ä‡à2q47:Öåì¶iT¾)ºnòï¢"Àğì•³÷^4‹²N JÂa{njÉ¹Sş½¢~¸U7QÕg¿ì
bùW‘¡
2óÙ2È¶óìQ‹¯M Ø?±-‘>šªÿjÆlè xäWŸçÑŞ‹œ‘‡·êr¢úUJÌ¬ÄˆŠ<<TQ~ ?zgŠÁ¿®–æÓ…J“Â|ppE6y¶ìïÜ³à§,¯ëgJ››AuWÑ§|FïœcU;Œï æ×ÏVÌ"q‡!‡™öõ\âÀlx _¡ÊõóDá¿ÒFHp$>Lšîş§×‹ğvõ€l•‘L‰i‚NX™wÕN­çôû~å/ß8ÉO÷I\u!6J]ş!&8h%S]ö9;víV–<‘ƒ%:C–!kfbndAá^w&»Á‰Û9dÌJĞmO#÷¡²û‘ƒG3Ê‹ÎI)Ú-›5ë—]Üö2GÕ^H6çòBeìâ…°eE‡<¶u¯eğdİ[ØFMíi	FEõ‰™ƒ¯3ºûJ§@“Ìs.rØô¢>‚ËÎ=$ièav+älìn[3ÿ%Ò˜Ãp±c@1p§Û¦õF‡¬‰&JÜÆ$Øƒ©Y­æQİOš¿ñ	RzÑœH›v $SÊ…ÿƒôîl…  ‹	ıß±¯ÜsØ\¿Ç¿Åº@,*l‹lÍŞ9Ô'j©áTkºİúÊPw¯d 49GY¶¦ûd®,ã¬P˜níY°¢ùMíÓG$?ŞÜsXR³G]_“˜qq}İ§Ë.tHj¦80Õì>”Jµñ“§ß¡dy{çx!ıÇt£Ò×Ãõj½´a#3¼!–Åšê‹j@ı„FÚÌµˆ&Ô-fæ^±×òwÓW´¿şU²²Ê# =ÅU~2/’9ŸE°…Ú¨*‹{ğ·ş6£ÅĞêm¬ÃÓÎœ¦úe™Î™zÜ³t&^ßèm—¥i9""Ôgú\€C!A7‹H…ÿöÉ•,‰ªRz&é @ı¤%ßÈ/Á• a‚gWbqÛXÿ¡¬åĞÎ,zşôZöéÓÇìV#Ïôckø¯xÉ³)Ìpº½ıˆ¤Ög®Øå‚wiûL2|mYÓ&4œ;~Ë\Ì‹³ğJ–àjf ­å¶Íµ7Ti$˜lëÛŠ¦î¿‹††­³Í/Ô^V¼1›(Àêk^ù¾=z°Ó—ËI9=¬¡V†íËé£‰•Ã¥íW¢°;gEÅ((Íúm­šáÔöÉÑ%“ßc ô~Î$4·§ôQ2ãÔí«.9Âªú™®t¼’ç¦·-}Á òQ²w9ƒæ9Ê³Ãp‡“t_Tªª>†éE«
_åqœhpô¼Q	Û/32+®IRGÓ7»«üÇ‘²ùálÌŠÖPI>‚…ÿK QõŒ?‡cX¾ˆ÷>cZU³‹dîIµ©w%&Ğ~%-èSæ‰2GÑã¿šİ…§ìl»°œ8÷)´Ì=Uàõòb£($l]9h'PzÍí‡¶ïÌ~Ãı#Ş×YRËã¯êÎŸ†XNœòÇ¶T`<æ:û-A¡EšgıôE˜ı‡à v·‚!Î7Ä]Â‘XÆ‚z§z«é|¦•vú ªĞ!0TëGx˜]n6GEèj2-½ "ä¸•B¬·ıÌ•İèË§4Ç~ò¯H»?íqÎn SÖ•ŸÂîğlîYoXÇFCt˜ı‹ @,O«Î£ûxÖnû§‚ÛšiºŞ<Ú¡.ŞoIc±q©}1=¥Í;¢;¢»<PÀŞ©›¥Û…ò‘ÏáO/ˆ…œz©€ıÄ®“´İS"Xˆ†ÀûÁªucfò9cÚú¡uÊ$ıërÎC¾œ-åò[‚ÁI¬#å¼U³´i÷&»G-0j­ò‚H&ùÂ ì\¬˜¤Î~ûàõ³»«#ƒGLıH"±k7y_GY9·gYè‚Óùd£Å×¸a™HëÇêÏåZBöq"
İœÂÍhB<¹ë¼sÚ#€¨K¤¨$:ÄñàA±ï1o4ÃÇss¥Ù$Š|ÕK:ôbÒ)‘ÎL˜¬–K}C¿'ùÈfÎmb„A¢Üôã^ t Æì¡^ÅÎ7ˆø‰fl-íà|iîŠ+3‡ ÙàÜÿ…èWÍ¦œ”ëÁh]çó‹yòÒ7ÁVHb°ÅF`E®6¦b–†‡×	ïå'z4 N^ŠîŸÁ°ÙvkLƒjE•¡šæ9NÇ%ÿ0'/F]Öß^–{6Û›Õo=&Û=Şá"4* ¤tÏTêu\Ş¯^vªÿNXß0±òÌ©ì%´.´¬i$ÀÖx€Öo˜µ’6ë£Éó	Dr.q&;ö„y«Ş/ßmuFíÂ%"BŠ`(ï÷C&mO¥øç“@ĞbgNËh¾$]òå˜Àí|€~ÑyÊÌ<™›²9¸b×EÂ¬”2£4°úí½1Ï3å– õ5âˆ„`=Öt?yP˜°_ş "gÔz„&t^­˜ŞÜ ò­–ô¯XzMv%¢y™ï”Ü˜ÃP´¡X_P\^']Å…>|tìQBV3º‹fgÙõÖX=¸w1Û ñ—ğ°Ö Nñ>Ög¨zî(J÷çæ-MD®ÃÚ­€	É»¶µÁ`ƒ¢ÖRe)k, ,“×«İ¥©×%ë7¥3+wÑÁ uŸÙ] g}%}5wjl5’´ü³@u4÷ ôDí×¢ä£ù$[:à‡äİı´Z¼Û¸ùšg˜’dº #Íéì#”ze«|´<„3èGQ¾iäI¡û…_ïŠ2tX¡ÇÂEÅ6Zw$	şRıÀß‘03ÒQ«ˆÎêğûÌbD-tuûĞ–˜
ÁŠX—¾m$ß8”/õú%?ßºßH”ÒŠfx@7³ª(àCÿ%åô„}»§*À©d*ˆv]WÌ/Jf¿4äQÅß|š£®kËczê[´¤©»õ	Øh&ëı³l.÷}µ¢i¯¡ÚÉ†7¿€/ı¦´&”q(Â(¤–€›Èo{ô¦áéŸ…~ˆûí·„ûìù§ªeı'c–}Ää<NJl¸­Qœ/hò¿ü‚	øW•å"ßkõb ½R8æÇ][æDñF&	½Q—\%kpËLb*ôCËqTª„’»N–Ìü—„O4lótóaúV”J<	ÙÏÑA©›tE‹øÉüƒ3e˜Q8’î±t¨äïú¯U˜¾ÀHÙL5¹ hş‚/Ç³¾ç×pƒÉV[2€3.|÷È)%õRfıO@ÃÜ‰¼¥ŒBSœÍ»>I„‡ZHÛ×€ Sèg~É¯,W]ZöSø $™ Ù_*¨Ñ2ì!ªı›èfLûÔo®€£Aº±¦Ÿ,`?c:uñõêOcŠ•MA1pûÜ†ºc[,2Ó	I­Áë©;Æ.®Ü—¦8Eİ#§RLÃ–â°ØÊÇd2á±)œŞy“y{²ËIª_¶È 	IŠá¢Kh~İ	Lª1@ÂÎ\TzGlİìİ'××ƒĞ X"íßµT³Ù‡Óqì*™Ñ‹34cîËa £Ió·’Ğùçlu;M3¢{³HG8Uz€-aÔ'¥†_&{h!>ÒÀ(kRæ`S‡¸•wK3gQA¬
Ü„¦k¦ §½ïÆ}Šnz†˜¸^®š¬!oĞ>õ¢6½ÃHH)‡X	’:­Otp_‰_ÂçXUSMßƒÃ’bª/,ìœÃ½˜ü‰Qú³ÃÊŒëA=TåÂwçİôMğ„ÓU‘¬Õ1«½y<Ä¤É@¹ĞÙãÍÉ|¼ê"wxƒT´	½ØEé˜\ı¸ğFv's6 ­ ötÒºû;zaÀR¿@ºœ$ªüGÁI¸†4•]Ãl™
¥NX€=›vNË©íŞLJÖiv‘»ÙÀQàG|
±©ËI´¦øÌU±%LHÍ©“œï=‚œ©=›¢ËÅâ!¨BZ"2¹Ÿ>3 İëo„·ËÉ!ZûÉéÁ,Ï£ˆ¡{4‚'”VÒUÖ©?<owáä”Y¥c)™»_	¢ÚÌ3H¿RfNÔáF½úÎz®&/(e½"$–üqi3½U`Éå–»6&Xƒ¨ùÀsõíïÔc£ß-SsHÚœUQCÖI.¥µ}o@z wŠ—7iy@İ5T*ğÅŒ+Zâ›™zX^©E§ĞZ§ÙKµkÏE(Á™äêªT\…OŠï{OEt²{ê¼iÁÊŒL¾»	Zúf‹Úõ_Ê#Ó]‹[lü¥>>“~Şã:”6n ŒÑ "%â\ èík {èÈğ:ÅÒKA‰ÀêÉ]÷6ÙJÓA^nÖ'ÉM¡-M{•I&Šu €wËúD3ê$ƒÅé„©Ær½oÔÁ1rÉ°BİüGâÃT­‰'ZW‹ó02¡º>—îKGjíÑZ{°ÊÌû‚:_o®Ö±ô©”ï\oM?‘UáşhïLŠ?ıËÛùüTµëÎÏáî¦Â4Í1+¸¦êô€‡e}ÕgÕT—°æ¿\PU…(H®ÿ¼]ªÓÈsÙï¾œ}Œà¬XÑYÅÇA`â_ªÎC†2·ëÑÆ¦IÒpâği}wf’ÑKôÆ™Ì=s›h(1	7Ûİ†e½,şú©·®:­æ91_EøÄ˜6ø¦”28/î§ Ø&!CŠF9€·4+¨ÅÕ‡$—MÂ¢^	úH]£…göÿûŞå:A¿„ß£)yßey¬3&ì†|86sb²D.%ç„2CÜü½l<Ëè‚nXÏËYÒ8†‚i_¼Õa¯·šöTD”ÓâÜdàR"<ğ}zÁH+#ÍájŞûuáuÔ…<Uğ‹ÿ>7alxcä2 Ì;Jğ M%ú Ÿ
²~_wg£CÜº’™X—ÏñEb Ìû‚ô¹ıÚ³;VA² ™mSP~?Ï#L¸¸Ö‘Ç¢nÕ*£?ä–Öy}ùMÄ™nîõôÙU5}æ…¤yU¨"şAbªx‘²©šıYÄU¾%Ò ‰,RÉb«z†ŒÏˆLì-óà_#YüçmEÑ¯–$í•BšH½OÈ¦Ô'Rà±¬6DÎy<¹_K>æõBPag\¦ ˜C>œ)È–ölâ’(ş–âè…¯ç¦ÆD-€¤ì &VO¦fówßäÅìT­ø)8ÆOuÕ÷]´-?¶ŸÙ*´Ç“	A,ßp?¬…8ÂÀaÓ)ÉIía_ÛQUœ}–;†õC,Ğ8Ü•D±(9º§Œõ‡³Ï/äeÎ}-œ´«º¬=ü9âßzu˜{û ÂF%Æ|ïÈâ'ùsÒòxùÛ3[y‡ÜÑ ¥‡a§ºÙá¹Êt²¸F¬5›“¢w7°Æ+Š»E¥Y~qÌæ@BŠÌB•c@‡¸‘FÅšix;Üh=x„¾Á®G¿Øí9Kš$rg²¦w‡/Œî>ê»«v¶OËÙLÁãvq™áÙtHkYpÅı28¸+U™Z>!o	»¡ÑÊ6¡ümë$¤Ï¯*%r*%(oêû(ÁÔfHÕÀ‰ÇëAúæŒÁË|†Âg7YqIµz=¥¤è;îşvQZš¦9>`ã¡Ú‰k»ÖE½Šo±	Íi¬xxX²d•“:[Í‰wXSyõ×ïŠh^²ÿævÚÈæeÈ´¯°e''ä´_§®Ê¹wÔ´Ç¥‚ßY' "‘œŠ‰ø“&J ïZæ]hùPÿªGKBr3ŒÎ7Ôˆ})Šˆ±fÙÕ(Â_ªM6Øû†³/Nƒå ¬¶Ga©÷o…Š‰ì¬ˆz]
p‚‘ÏØépitîS Êš¿®µ£_Äì7¥\‚¼Ğí„õ½ªô§„æ¥1<bá ä‰XÁ#“”I%3x'¹«Òï	¦;Ä Ë_í=A²²C^ÅÀ|;*Ş´e‘=!ïò>	¼Aï—:}_ğ^&öö¾×bCk²ûÜQkdN·¶Y³üÜÓUÂ@}«£ŠS%i0óJb*†ÙmçZI¦A_Ğ¥0w%(Ş)ÌXÏ\ŸÃÑ¡Ğ*jF:¤yğZ­Ğ«QŸq›ÆQ¿ÈÑ4”	ÒÇ•FõÏ PüH-PÕ©UÒ.!ÿ×iU¨îvº"•Œno·¡É¦œ®v½­mJkÏóôX6¢peµ²ûñ´
Y÷˜\ÓÀ}ßi\ù&]\‚¾´ö!"ôYÿL²7)0ÏMF¬cHS-ìö[4Q÷‰R‡ztÂ£HnF•/™ j·¤ ´*ß$Äz{ÇbøR…fMœ–¬O ¼ikR)Ü)ÈLä¶íb|I$½x™V42®píDEÄÅ³íS
t€½Ë€¦ªûß2 AI¤ó59MìdíóŞ¤ïÓ‚k5HAXöúã°¬rj¿‘ tm™Yı.¦˜T-™DFI»O×i|7±-[­’G7Ë|¨€µ§şä¾ìpA"|¡xıEbGõˆûAÙLŒÁAá®.æg­è9Ò'íĞk¹úªÛ İíĞ#JÙWÔqø¾„i=š	´Ìã¢µºÅH~=^ğa§êïdæ­º0`(VË³v¬ù©­Ák%SÂPª•Kkš÷ï±eWK¡€?¡5 ÂˆÖ6J9;Xd†Â%Œ‡Ô’ÈbójªjÉ2
xø`ÿŒ»¿ÆxF¨øh±~ø°Ò®çÖMÊ°kEæF
s+?8s¶ã.Dá#4?ºôRÇº‘_tf¶ä{sˆ¤ã8âìh„3)–ekÎ9¯:}½ŒıL‰ 0i;r)ÓwİŠ¡?ší¨—FB5Ù i¾Àxrš®y[W²	€ØIóµ’k?Á˜Œ(ÏD NmE_4Ù û1o>ÏzFŸ$!ÊIytOÕñİTûĞ¬”^-,ÂbG—ÿ»~İ¾º³LJUì É´‚0nîô)í³—>C1Jn[Ö›kéC©có¹—!a9 _rUá•‡u^IFÔ¨ŞK{o†ğTçíhÊá¢56Y6Dş:–	 4ö{[I0ò·ÿc<ôè’p\õ Qñ'XÉZÓ”…Çlœ«nˆØN„Y®ÿIV`ÿ7>„‚*ıú1{ûTAŒ4ÏºuëÇ¥ß‹#-f}ró¥‹ø*nÕë±H®œİ}0´dÖU?Sôôø	åa×k kùâÓ_²ËšşvÈ¢x›İ|´ÂˆëC
1Í%¼”SØ$£ìCşß²ô|µ
Õ×¾	@T!W–A~arƒª}ÛçkÏ„Á>-%=#H%¦€CÄx™•Iıã;§v*ŸøãÕzËzFÉÒ¹­ªP…RM³îY´©ƒîd…˜ßg·Öû™c³VÂ….½v=hb—ç`@Pı‘F©XH“‡îÎ_ùÆXMÉgHYó—;0kŒ¹¼`ø¢1úˆS›'ÈOÒ4
/ Këòı‚„Ô~^ò†9Xdªí0	uÅäş`;~GkNğgTæc¼cÒáF@Ç¯>ÏS—I‰³iN¯‡ 
F?Lf§¿ı×6v&‹@Y-­½«S9¦?cÕÿ»(ríF¤ÌİİœûJx<yá^X¤›_l›FéÛõ®ƒoõJ•‡§Ë¶œ?Å¢ùhW>dq"uS/RN³Ä¢‰ÃÏ¼ a5ÊDcß² 1”ê8Ù­uKáRÛ£[Ìß£–,ÁaãøÈë€,\Î`a…ñÑF7Cç(¹È‰s@ASĞæ‚B9Ô-ë¸‘µçëCîkÃw‚³öñ—Ğ”À$.a³ÒD,“®sp—Ä¤7r X&LØ8
wÇÛ3]Ñ»ô>m°ˆ¿á*0F7Ù\&#•{ßXéJMòO?Ã.ì¶…Î´M JòÜ[Ğ(äÁø‡w|L]U><02:Kaiª£ƒPÄF4èlÂ4OpûÁ ¢Ú÷s”ÇIIïîiÀ´9¶Bˆ¶¸Œ=xŸÆ—áİûØáWúµp¾'ç_¬Ğ g0D”ŠŸ#ÏZHx›°¹ìmä!«#-¬:ÁhşÌõä¬Ò4}¯›¯9$¾±’[àhÏŸ½dË9Ô0¸Dâó "ØÖöû™çÇ­â6›×GZÃMh†QÃ™6Ù…©AOóòsõ,csMf:*†µ·áå9sÅ°_FGZ
ıG´$Ù[ªòs´cğ1Aë
Åƒˆu„SÅüÔŠ;QUçÈuª7*íÓ ŒQ>©ÆøE|/Öé~ØÃóCIÓ€jøÅ¸¿ãO%ÌÙlÛû×ÉbÒÛE@ºªÖÂ%û a<!ôš²Ú4ìj@ó´«µr™ñp¿º—}/
7»…Ò%"xKRP&HWs–kÊH…à–Ä­›g »Õ½ĞfôÁãÏ”¿Ü×›Á!/vÛ¿Öê…”¹UÉ½RÈÜò6p‚›w¾ö‹»<Òæ	ëV)0]ˆs-Õ$Ï{Îj¦¶fÁ§ÌÔ-Ê> :Üd@ïUoÿÚ±®ë4ì.ùãrÑŸÚòÈh0¬xòot7Ä¥A/eH÷È—lš1”V_/>N
i{dMì±Jœe±×¬¼®Ô»;É©±•|ÔnX÷ªÜõ{$Ì‚¼&¶rvıÕ3’/ÙFÛXÖX…ˆ2ÔL£•È|ÇêÆ$a(¯Èıµ k~g°ŠÛqıF,0ñ[µšd«8õ\|¶#%3NPAlÂ´k—œt''1]ùKûhÃ„Š(‚>b¡Ç„‚k‡ï ş^'ƒ^&
bào]ûÊzÒVİœÂGŞsDagWm4ı¥uvç%õoM÷äÿ ©ÎŞW‚ll'fşé6§,Ş”LÎäŠ9¸)²%5P»=µ&½_Sªíl*½nøĞ˜§ş²>¡2¬âfêØáÏ®AfèÇ§ÔÈ¾g%ì1IH¿ÇºÑãµÆ“¯kíånPô†«ÖE	ƒ:ü[ÄT5V¦`œäÔó,Çó¤ì· XîxV¸G/eù){5z1ùÂ„Fá£<\€Í½	ºõoËô=˜"–ÿÑòN@sez*?F÷™	ÿQDÛÊ‹µF‰a¨9½Ç˜İ¢Ù®‚É"xÌ‡wUY!Î¯QT5æ¢Ä²£~
ğìfé´¬áI,¢¾·Èì—ı¤)R”İ£$/»GİæOùöµG€¡v¸o¸9«IÀ/Br¡ıv…xŠ`@Ê(£GÈ#öj:Gc¯¿D ¼g\ï·Ã†>À¹q…àL.œµóS=’à->şïœqy]@àn@üˆÌq<Jˆ.½uNL1®ç¶>6øW«5´ï;u9dósÑù¶\ëb^¤îÄ+¸«6æ¹EÎ¼rô,"öÅ[¹húTÇ¹‘n¯0éØ÷*}Öı¬.¡îÇŒ’zã£è™£°èÜ\ìQóÄÕ‘x~XÆ¦x§ßƒ"§ gn
PèæÈgñ#ãØUÅêcKÇ›gÏ®áÌQªËW3Š£äg†4Ğ,§F´}ó¦¯)`8R«‰ãx|qËìzMê»'¼£Ø"ØüëZÈ•^ˆÄL‡)!mÚ·/Ôì'¶7.íğº—	ŞŸº–c!jdİsÙ×²ÇdWU÷ÓàJbAV8,Í«a2RèÏ8ª®†J¸JƒøVk¼ÚoŸñ¾d‡M0^ö1æ¼“yz>[\_«t×P%0€=¥ÀqiG!Ö¼(™|Cä¦2½é‘4Ù·Xlï5·)nN/îëã%â.ËBé§Ó§FeÙx7Î™LÍ<öNá÷FÅ8s8u|ÿ[ÀRŠ¿×ONÁİº92ˆê¬Í¬èºüÑÿ­—DQi€“ÉHÖ“¢fjïV#ó#œ×Jˆ0»¦v¶šèõ„ß®¹8xû|ëÙ™±Ã¤4¬uSœŸş›®ÁYÉÀ÷æPš…lDÇOX^|«åüœÕ³«71f¥5¢ƒz{œç0ø¾iŠ¤@üñ!¦NaŒYûx*TŒ\Í¥æ+N4	r‚)³šœÎ ½!¼j$ˆ7¤êıwÏšDù *Û%­WåÖÕœİ‘Kzé:›€!Èû¿ô—Œ÷(.%«ĞäË×˜4I/÷Pü×Šß{@—H"îw½æ™'(eë•V ;4Ïä°™œ¸£ÖGÚ'Ÿoü¿,¼`
5´Q ‹…ÚMb2ò›¥×O	£M”¿Z ù—ùop¡^¢NVò©³D$“…	Ïmy#‚ìËN–÷8-úGb¼›j:²­$äºP³¤kxôò¡^¿-	pw÷Dö•”ÈÌÍQ_X>%Ùº«ÓUÑØ2ìT£vıAù¶ˆ+§Ÿh½.û¨¼>#eÖ¿¦ÏsıRZîµqŞVJ÷La•&[À©^êş_±}Ğ6ÜÕ(Ùˆ˜©°Xg/0]oOÍ(zÒÉökÛ‹Gâ•‘vŒLÑZOÇà   ¥Ü­V ò¹€À¢8ÏŠ±Ägû    YZ