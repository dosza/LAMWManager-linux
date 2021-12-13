#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3427824020"
MD5="77656fea032d602b77481fb8f9f2198e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23924"
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
	echo Date of packaging: Mon Dec 13 19:24:02 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]4] ¼}•À1Dd]‡Á›PætİDõ"Û†Iö‹}±‡F?÷TgFâîQÈğì}İßšmËNtR¹ïg¾÷’a5ïÆ{O¯12–ƒ?¯€…şÅ¡Ròi»ªm_KğıSBmw
‚CDGfˆˆ¶ÇÖ>÷eGÌòÀæ86fı¿]î–8â.‚Ò±"RñÓ¯O	cã¨Í£ÉŞá‘[.şaÙ­zçBZÖùÅCí2¶€"D±İ[¦!bä¡é«ÖtFCQkt”ƒ3z ö¹¦¸OU(ÒöÊK/~›Ïÿ9ÍA6D'P+ï1‘L¥Ã•›WÒ" ßí+2Ñk‚ç_®Î¸	÷Ïss¨ƒ°¦3Ëz2™Z¼«&¿E/Wü=7ßl[šeŠC#N* .°Äà˜P¬+<!Ù|v(UâqıAò@PÊ¡™ŸxVrìP‘µq»Pï/@ÇRÍ}šEš1‚{PäÎ«·  ’j<TXkSğ-Ñ™oI†‚ø’è½K×"§{r6%$‡^L ÌŸô%wzğ¥š-+Ùm}µæŸÉª?ÅnÖŞ¸û(Ü¬ûßS'×v€8‹BHØ,P‘•§ünSñŸºõ¸G<‹6+¾HEõÛÔ¤Otaé1ÛâJU;Ê–ÄàB¹Çéå×»˜óíÁ`~Ğ4‚¬'`Ğ×êtU‚f–™¶j} =íŸÄœvSE.<N}†è ßoÏcc€şãvj8Ñy´ã+&¨¨u¦1ç6]hÏ%¾’<ç³½·†l¾ÂS”°¢3¹KïcÊNĞ‚Àé·g[—˜0u#ªUˆ¦¿œ S¿ûËCØ¬ŸFÏ®‹ræ,,²Ã½šìX˜€?‰a"Û$ÆYâ?4§s»P‰šÈÚ	Ñèb„è/Å`'Ûğ4èÍ‘Î±v²X¸Ğo¼Ï[BûôBÂßªÌ­§N¸?kKàpğxí¢<>=¦%ïÕyN8WÆD2Zxç}‚Íj5¸ñĞwÈ
PÂÙ3`¿A„ç3Öåìú4ì½³5.à¥‡b]J†ÔÕgîjå¡à™›;CDGHí6+İy:ıÛ¦—û0‘èã5ä©é!ŞNŞ…èwA­5ªU¨ÙÃÇ¸ì¯×µ%´€xwS™IğpBzd´’AŠ:6Œâ(ƒ¾0K<Õ³]şûgÖ¹UoÔTÜ†2,FRŞd¼yÁ×çÊı(SékØzÂú+o»P"™¸-?2ƒÜa%×\²n^÷–xeEMcê†yU{ŠçJ†•æ=Ø‚’zµ¦¢l2|Äá^¿]…ÛÍÄñoc·›ÙõÏv#Úƒ²!6şêHûUP´7-yCñ¦üÄ.åd^Êl5ë®€EGø­µ}©ÃÓxªş}G÷éY[%ß/şp/1nÌŞÙ[ÎJHy}fKò*ˆ™M£u¹Í<eô*«i¤ì K^ªÙF×’ço€€yƒ2µ{“çh' ÙÄh¬0¥ß¾Á€7OGtÚ‚Se}Æ17‡eYÑ¼†ì®ç¡kÃœÒ)ÅxUİuPùŠª[Œ ¶ÜM‚C`R·$öˆ–öõÎÌQJÿ‘•
{’‹³Ô‚kç^ì}ÊOù'“°±cZ·U“Şãe§Ô¥ëúL~+ïPRPøÙIà—w*bıÖˆüäs…JÖdá²†¬fw°h‘7h½8„¨ŒÚ[J¤‘s(©SV(º”Æ×8˜Gí="–*Å« ‘Ô&`—Ä•ÖÈŞMğgq@ë!j¬ÚÇF\á¬™g¶2ø”ıöQóŞíì€^¸AÄÓ ø•q„ÖZ ­DÌhÏÔàúútû¾:¯¼¬ Ş÷H‹è²£-û­î8yh3)òåå QâÔÙ’âŒú¨…Rò8^9 $ ¾ùŸ~‘~Ñ¤o;M‘®ˆ¹#pJ‘ØŠì·ÏÆú"•TM@O#8¾Û8Éq&‰Ùx(º_J!İàÓ;óS$¹Ã›»ª²»Œ,î/ğæt\´ØS¶7zûB|Å¥İè†dRqÒvÓ B&p\!¾/ÊÂÄ¢{Q,¹5på™D=qöqé”¥B={kxç›ƒjÔ¹ÔÏ;vé¹H* Õıı†›doB«Jr˜`_'˜H•‡1+»IBâX+ÈñOŒµÕLğßâÃtâ¬ôBR|âPÔ;±9¸aÚ”zû¡PÖ?wáD‹/ÅOiå8±„_«‘œŠA÷‡Z	À¢õ`‡Q#Zc7œAõ|'ÄsâJİ³\H¸#™%-ÏºĞa#IvÙyoæöÔšlD	u¬à—BîŸÂïğr•kTíäİ¿İé;µ;ÜO!A"Øe_^Zy‡ƒ)JıR ~0…¾©jQ:½ç½N|õLõxõAóêı–×ö©|SóKòÔ*ì4­LlZQ»¦5˜,}¹–¦®=èÙ=M… N«'ÙÛÏá<3YİûÿÓI}Bc[Y~†¤ˆ*5Wñ.{°ÙRh’·6’ş¾¸>ÙÒS>K‰st/ 	.àCèĞ#ë_…½–åº4ûwÈ-¦ï˜ÿ›õ£T6tÏ‘s+{ÜÚK°øXnŒ;ä Šd
õÑ³l*\ÔÊ
)%5aµy­Â‚oƒã0Ş˜Ÿ"·Âãkæ/Îº#ñB	¨èÅè-«
ĞK3?Øe	–kƒºî˜š²&á@|²1 Šç®™q©ıg·ŞvÉ*crìZˆLğI±è–‹.šÅ™k‘P66hC4	ZÜsK	˜v&îs}î	À,Ò‡Î:Èy{Ç7B5Vp¦ X?‚¹ìö²|dKì)œAıKŞÄô	Âü*úœ·¹—öòşôêøi@Ë{û,ÍÚËp9½Á 5]“‘¼›nF!´Û¬^3Xq¬§±¯Û‰Ÿ ø·­p¹ÌtĞââ{tÿGF’îò'aøHO:’¨*ZQVkûêÊ])]í¦˜´Hê¨™Z€Ã–ØXæ7ß8ªg™U;@)r™ «Î_¤I2TÀØx6ÎşBTÄÛ$<Yô®å\î8”y|¸*übÅ¾
N–#ÖeìZ£dú{İ.LRİ•=ÆoenE?„²ÎMX¨ÑvØsXéÇ ÍÏOûë^9³‚›É ¨Ct‡äKfì=ş¹‹ÇWñÅ®V+ñ$F? =˜®;rŠ."eË8-Ç¬..pAßé‚¾È>bAg€…&	m§¯|ÙÜäNL	ª!eº$,„|Wè¹Œ°!•ŠI0aé{“dhÅ>ÅÀUöÚö}z lÉ«-¸ì°Õ}ßØNRıùo=òy¿%ÊGşjèÿ˜ìÃ>_æèğÕAjÀ”°ç‹‚	Ù–OºéAşS!¬¸0	ê""ìèÀá…',	%±Øeµ:›s]îa{·SÛÁ¹Ÿš3ÒØK¾NÔHKiÛÿîâlã“ö_ä|İR€¥zCÈ_E7å†O§tUy,»0,»kI¹M»*²yPåª8Q ãû]Ö.˜äË´ûDl‚`†W+ëL~‹ñÖ‚ïï–t—’vˆ‘87™A—î¹)cÊá Éâù!£&†;¾K¿ì H‰…Æ’ß²fÁ26º•‡²'{3lQbNG¼Iynn_°?Ëº^*ş”>ø6o’Ô"ŸbfK”} jÉ,|¯°M«áÊò¬ÅTê—†mÌ6àÓÔÍô¼ê»k bìü¸& ¡]8§×%5e}il¼r“>ñb¯eÕš«4Ês* ó¸[åb‰²™Ä“â¼—u¼Aš,›de{gI=a­çó•ü®Gh1Y]˜ƒÃ£QO’>4æ“´b84»ÿgŒØVúßÓÃPòîgÇd:huˆšk)­Šºò^Jˆk‘È“ÉKÉàó£nkÉhfªÑŒ8Ñ5[¹ì	GVbA¹Võ25AQUıUÓ´sï‰ií±O­K#½jƒP1ôíê»¥X ³ù½ôè„(Yùoø~á).Aç0PÔ›n½ƒ
ç—ËÀE†Ê"ó¥¼K HÙh†$…*nCÍ^µ.¿LrŠ,Èãà‚%^n<ëE^îğ0Úb:³fûNôç×KFE$Ber¶WÒÑ²´É7çÒ[¢ì¤0:È8”DŒ,b£ƒ÷¼lŒsRÎË¢‰óÔD„‘Ÿƒér4±Ò(áŒ×CÑ¶C?[í:¶jh\k~—Á·sµŞ£C€°ô˜é«ÿ£a×ÄÏ­Uks6JPHWsDCZ'±Qÿ5¯sq¨Ëÿ$${]‰Kç¶Øo9qô¹]3:P‹œ«Ã{–¤àdÔÇLêÜÿ¹7L„[ı,j
hü@Ëz–'ãÒ©ŞyÜAĞñ¿Ş#­QjÒÌÏà¡Õ¸õ†±tt=ÄOwûÓ=)ï¸{g o!w×¦İnÏJ[g˜mß0»	îÒÄ¿Çì»‰÷|ÕÆ“¡kİÁH…xæK‚}v†pÛ³ùÂ¢{ßã
róå‡øığ=KÆ
±ïeÍ¶œË]ìî¸ˆœ7)ºVäºÛê4?8´Îi“ß?Ù£àÄSî>0¤cş^º[Ğl2º<Pàúøì‰¦omlíâĞm¹N	_1C³[¬Y?Af´˜$°‹;	“DŠ…Ö›±õ{Úº¤mƒx2ü€bQót_ÇŠÏÈƒ5ÑtïÖ»˜¼ÃšD~x÷u<‰Èg"0Ÿ?Ä~‚ùvÇáõBÇÛ©2Ë´İa…TŞğTcJ 66iç€/âCWÊÚõœz^÷÷à=Q ˆøO„Pël4†Û6Ín…¤ ˆhr÷¡HO‚o3E¦[GÏ2B•¶|ŒÓ+9†+zÃ!ô˜ßƒOC0nŠ—0FÃˆ$..l_cßcÆftÊÖÆ>x¡]­××
S¬×Ã¸ÓÏòóœ ²²•_îÎÅÑ÷ÔvF»…Ö·Ğ1”Û0ÓûIuJSh/Û‚p¢fñû/X…ØŞw£Šcheé“¥èŠ0÷ï7ÂÖ9©Ç(°pO“x7›ålA‘¦'¦cdÿ ¢¸c0ıjõû²­¥JÓˆ›K§1•˜|€$‰²Ô|€ñAc%H¶«©´Ÿ15‡*¸Xe8j{ìnâŠ¯/’3ŠOæX\{FÇ¨éA	%íq!°ÄÅÇKXu1#vĞ“´å%Ší"ë~÷Óå³´/„\É÷1ÌÊĞÿ2Ñ¥T#‹Õ2BÏ˜`[P,\à!ºå¨é¾9´©ŠÍ@­Øì³•®©ñ<ªĞyòz€&ztÎmqé«É‚‡4‚ît?6ı)1tñç
.É¾87àşBÈ¶ğgÍ)dúj•(jÕûœ†à%íê[é  ÒıÈ¼C¬á÷M×Èş Ì`¹ÌÍ5Ñ»@«
µ}âËğ+#Ääš¦•Uø¼Í{¶OGšÖ{sHÔG©ìS1‘Bà„–oÌ72‰jøŠ‚ì™÷2Å/óHõ%½oîÇíZ ¤,õ#1,Õı<˜ñÓÏWƒ¿É‚óŸ'ç†6n^k®º¹(ú+2æ˜U<ÿŠİÚ¸²œ¡¼Î¢hb%äixMÕæ«Œ¾L6æ¢Œd#ïdå¼czhä]ƒ®ÏÄÔ­4–Ï½Æn¿¸Ù80œß.”Eµë/}?úµKûÒâš
K?ôïl#Ú‘®EsÀq¯ÁR~¢m¾·@&!FSÍQB¨¾T.?qó›EK4Õºü%ÂÚ&ÙçFzzDLq•ËqQÊ;ë¥«Rco—òYˆjN‘#-‚LRµ2T~AûG¾é)v!CD¤,|ÔuÌ:L¹•Æª<ñ¥ñ`?¤‡xg}YÁ ‰
rèÈ 
‰NµT^³Œ8KòBwüµ+5œ‰~×ü!øå’|äò†>Ù'ZË…›œ½â½º‚­Å jËå?õÚ¢Wù‡'ŸA‹½ŸƒšÈátU»ÄûäâJ­KŒ	¼ª±JXŠUhqÅĞï±cÓ9s÷|@”³¶KE÷ôcøz y>ÖD·ĞUèy$½†¶¬Ï,¼(%?d; ­«(¶mƒñÉä’ø›(°¢f¾2ĞVz€¬e¹da[G$Fâd:Ü¾J¹¬J?6ˆ™ËpôvÂIáBR­¨dT0¯§ØÍÅÿ}ìß¨!Ï‡K¨ŒrÄPù3i÷L|£ËPd6ÒÕî3aúb7á@i
¡¹m™SNµ²â$]Î}¤*’ãß-¼/Ä (…EY­œíİİ4ÅQt(Œz$paêŠ1 çÌ 4TN?yú… ŠÅA:.KÁB?lœ±@\¤õc},^ıkU¿00[}j–¯¨$ˆ<™HRÔ4i™&€V‹¤*0œÓ«/”Õ!¥eGû‚Ó¤BöÛ|¤[¸	qx=Ÿ}}?Á‚œÓ:­ksL°gjyU8¸fnFÎ	âx]“Õv‚â{¦ê•hïİóÏÍşûö ;½ÓZFàÈ•>@ğÔ‘Ç¨•Nßj%À±ÜÃõ‹ØM8¦Fòk¹»wË×õÛVZåG¸Å'İSH4Ôö¸ÀætB¶“ç,,¸ıH4W¢CÒ@sccğ¿
"Òcu¾Û7öG$ ç
wş{o?•¯º«d‚eVt¯uR x+¡¾3€~¹ˆİ©¶š4¦·ø,'+ºÔ—-±Î˜ï´‹…L“Íœ
i@Òêi^(oêòˆ÷µ-n«Ie(^gär,¼:ÕQÇÊ•¤W®‡Æ4ÉÀwh§vÁIpÉ·]¼Ğ!nt½ÈÚ¹	t vØ‡ª¢bkÜÒÓm®tËsµğv¨k <#äJö†W¼s2ÓåÏ*dëà-ùêÎ=æş
ÒÁl^ÙCÓ¶ÿf B‹dĞz%Š:¾	öÁàÌ±'_{>p.	mßšñÏö¶•giË­nˆƒÑÕéİD? Ì?älÕëq’ğò {yT)å­®pÿÌFÆ¦§q
Öí¦™(Ì5ÊP–‚·áXŒY^ß`¸€á¼T  j$â8“6GQOŞÇË)hö½ZúLÈ#¨õWª›u@Š’¼@Ê÷C¡hØ%£nm­ ¤z·%¦U©?1È}ğz>s¢.n1½ñŞç)ŞÚ3-ƒùéu>÷÷ø§(¥UëÃ[JnzZ>ëé¼Ó*P¤J€¾GEö²çP1ßŠhT>-Àİ:bDáèSk”Ù»0ó³Ç%”cváñé vİƒñ•¿A2ß.ËsÚ}L– ¤vx‚dü¶ğPbõ©2(
šÕ˜05:@ù=Ğ¿ßÑ4\´ôWTàfœÂ‰¸3¿j¹`<‡!½&²ïû%^c‚^ºdMû	ö0lÙ>¾i´Î 8’ÊÊf!,0äé^+£9vİOããSò+Ñ$`+ÁU)jÔS>æ¨@<Ö6>îµ~åÏJë„'h|Ï––;¨ˆ–SF|ù½mSøjŞ¾¨nVÌ^jšznp‡R-ãşú«l±Ö? Nb‹8´Ñ;Ê:e¨rÒzÛU¦¿š7/fñtun¼j¨#a n™„má‘·¡ıC…=R`-;é[¢lı×–ŒYV‚˜6Gº¼Íuÿ[ŠßVÃtÄ-ıÒv©4Ô4kÚéZ,™ïÌÀN„òƒ¤ÿÚvó’—™¨&©Å|T×â `ÍÃÓª@—§×[cÜ]ï8*ŠÚ®èd¼`n¡ÆóEV O;ò®êÎÁ®¹G½ÈÍò~l÷Ò6 ·Äï„IÅ`_‡Â~ãÿï	K$èÊËò…“Äöì¬CD³éÈ+bÛ9äÛ]‡œ§¸aïm)¬Ëıi¬GXF¯`ƒ@OwŒ‰Ò$·S1a³¨úG*F@6ûÿë¿£³n·sí,¬:Õá®^ïš›VA¨×qŞOùh-Wà‘: ™QïæWE¹‘ñùÔ	¸ÚÌ__3²}K\xCS²ú)”ùŸV-ó0­TŸ$Ü(L%ä<ßõÀgu‘<`î„Ë“z3Ø×.Jeo£l~×ºŒªôÓw„İ
@ú5zP»U!¡&–PW(ª¦p‘€,ñ+¥8€PÙÿ¦wuvh`b‡,NBj6§ÕDşlC*^;ïH«?¶:jº±Xô’Ú¦CtgqhÄò¶Çº@ŞØ²­ú²»}”+—Œ¶¢±µ€ìÈATd9P™C“H•MØ·P³0µ‡1¬AkÉØ9lœ¿üĞ†\
ş¬·ê&À®Hç“Â€h+{&ÖğiKö¾Õ”üQĞˆ©@ë'WŸiG½Zã 9²nåª™¶iÕ5ëöìËÕ€b»Rc ˆâ\ÔÀÔ½ON“#W%._¡‚¤³3‚k¬BéÈ?íâõUôJİ=9«À‚ì@Bä“0_Êi7ÚR(R?‚ç,ê Œ|•áycwöT…(ûFç ?.3¤à\q}h˜­uÍÜ#ûÓ“Ği¯ùá)xX\j]/ú3ÎÎ Jº³"e°ËıGó«›¢=é·¦Ù®ÌË¶’H™=2Jp1ì 4³›@O	äæ?ªÜÛè]	!ÏQ¸à©L
r?ÈÕU )¬sN‘:ıkR#µbmÍ­uÛÈé…ØåŒ€	ˆBİ_¤ƒû0\€)ìOnó…«x ÅX9°¼›SoüL³êÊÓFf^\~ïûV–Š×|şVI¹Şº°ó°³·™İ¥›^ŸA¾OsFÆH¨Ü“¨…óúĞô´‹÷ïL•˜Í»mEM•‰g;:GT’9wxy_ÅE˜æ.9¥A ƒ€: ÷²Bì¤ëã.ü«r¶Ü$ÌÌ & ıŞ´D ~myQ7ïYc5°W{nat»nã!}óªê¢Æİ0D1§¹ƒÆn>ò¾¦ İäÎ‡³lõÀ^-Ù*Fwhz¿THEl“õt/
‹úáËÈj“¢öIÙ^R‘bRR¦ÙüG±à%÷–œ;ùÔ`ËS}6io´ã½]ZUÅ˜œ¼ÄÃN*ÆŸì§ÕÌ.vV0À‰|ì_ÌığR¿Ÿÿ-İx•£F+2üyÔÛ>Ù.@_™U†2#È+*7 <ÌÒ #ø¨|0Sá¨eb‡Uµ;œ]ï×b§`I	Ü—İ1XR…{cô^q‡ºÆğ É…†báÿ€„¸qëëš7Íä0€šøÕ—Ú¹}"k?EÎ–²¥Î(•Œ>I«q"| Üì¿˜³×	İ! GaÃİ]1®GRŞ\¿$ÍC’÷YúµÇˆŞÀş…‚:%z9ÀD(Ş8N!¸ûe~™ìmìŞÌoŞ•’ŒÀtwèr%%ä_æ–jgo…%ˆòeH@]¤¤ÇŸ…½HQ”'Û¥…5Ç©j0¸MÿÀ¸yUE¼ *VúvEY¤Ó~oô]«öÑŒ} ú¡D¥º-Æò¦¬6Co¦4ÿ”\ü¥^7RÃËÁüÈ’©#9&3(mS‹Ü©½æE§å'Ì¾ı‘)ŒYÇÖ±›ZaÕK….Ã[7ˆ¼öÏ?¢ˆ¿¡°3â‡HàgµNB–'·”>ƒÅSÚ¥üYs˜Ê	Öì±îãxHª‚>mºNĞ^#¨·³/¼
øR8}uE¦tAŒw?ågõh¹D6›íÚLæb¤Sÿ»^‚µ[êä/ÃœŞüZbİÒå‡ïã-¾€—ˆkºJ½osˆÖ8—9“µÏL÷Ùå‰¿wé×8s »´Â_GØ@iÄÚ••¿¾àu¯êwİ­­\c;ø+"é(
ı$y„°6ÛVPÏ/Ñ†Âe İÉ–X ä”,^-œâ–±.’ãÇ6 Zj&œ„Bß3ïT	ÓÖ#¸ƒ'ú¶îùªRø`u-Ü5³ZW¶»K»`LÂ]=â‡ëö€và0;=0aDÔ 4#NŞ02"=?Ñá(NŒF?Í²õà6·ëTx(v]é_ÉVARDD¸‚
şæX äí÷Œ»*­ä»>„v¡¶ñ¨GÓÍ#ÀGJp;CpnV””I½PŠy|teq¢& °$Ü n4!`Hj¤¬i$UD4!´Éäˆ$”¾‰•õÔ—>©¸°q„÷:õƒŞøÙQÛ~^G[°C/¥Ë;ÆuÍì9C í\Œ	àÜ—'¹¯³^Ã†ÉÏĞênfWÿlC›ŞØ”u×æ]R)0	öEYÎèdÖmšãfİON—«­[qÂäqìõÊ?á €üÇÿ—¶¾²Èm…/ó˜Áw{
ÄÆ¯W¥\'Â	ÑŸu™[ôÖÏûé’LF™"*F—óâ¾ôW¨6§KlyÏÀBµ×£WÏSNÙèÁİmØÇÆÈ\k¾Tm ÏeÓ¤ú—`üÖçÄT«ÎÈTö†ñÇjŞù±jX'Ò­ÆK”²ïÀ® Ó\#	+Ï=ĞY@¾úlGy*~€boZJ,\ëEyœö$İ¿5Ó¿NXÌõ”Æ;4˜±ßÿÙùãÎ×¥&V’ág/ßµ
/êô^I
öp&V´;?Ò44OlLÏ6e•Eñß0º$âÇ‰ >21#û?ÿdc²C(´P¼ í‹RWÑèJı´¡7.­sî¢H¿èè¿ÛB$òé“‚>#ym3'@V8<é…l•õvõÌš(äÎªÿqÃóî)İ?~Y4b{Ä0@öMDlâ1àîv#€Ô5J›‰&FBñ‹Qêáıë$èî^·[’:etF”1€–\ék¬¾ê;“´‰íÂ	¸ï4ÍÍ}Ñ·9½Ç­FT¬Yçânï§Ï«½B@6,}acÄ9³g?TUìA</g>ºûÒDråùİ'ôs/§Y/áR²1æŠlã8k…ŞgÁĞM¤d¬Ò3Eæ¶²XŸ`ã{‡I®Î¥n½	×í½ÓÃ_e]{µ™£ 4«‘›†`ì’6¬”ÍˆFœ¼÷™Z1ŸlÆ“¢QnW2Æ·^r€Y@ÓaY¤ç™“i’ªX¡N·€¼×z,ÔÆ~dZA¸‚4P°VÀßù”İ“Åeb‘…F¸·&lôøğ<.nR>ØšÙÎ’¨fÑm&J«D×¦ËÖT5r±ûéQøie‰ê‘t:­@ä”Ìû®şiëC+±°¿¼lûHQ0R7©™v)Ö”5Ô_ÅƒÓ”ÏKJf›§”‚[ŒÖÀ9¹•æ •ifÆ%Q:×_©¤«VpÍO<ú—`HúÅ5ÚÒC! /±é}` çu•³’±tµqºB›Z\8ì+	ºR€âKÍoÜÛ5ágêÆâ?Ø,ƒÂ6åî}¸#ØÈÍh±Alv%út‘”=W¹@2{dv0nÌé‚k°p¹à'4õò÷ËÚ›…è»ÂíâÅ*E]ã\™€~“Û^{‰ËŸi&±Ÿ±±AVb†-ûû¨—ùÄf×b“—îŒûğ„§œïV‹×‘_•u¨Ï†–}Ìˆ#ÅçÖ”Y$ƒ"Ú$/$<xk§Eäe‘Ö–¤¼G3ª‘d€ ×EöQ~²w™/~3Öc5¾x[ËøI³ü•ò¯ÒBSòwÌi¥XTop~Â`¡gkB‚”›Ù×màˆBñÀGfØc®‰ß=´¦
`Ûÿuãş ù-¸NùÆŞnÉÒa¹mY~?¼ëBkB£î:YMÕÌ¦Gâ²Æ!]]£te|3¥®Ğ%‘„;¤ıw½úCFz#8dö<™ÏÅX1œ:1x˜äòèİg1Ä×œRn×MYRÄúâ¤’ÆG‘JğGİ5âc2{Ä<¢SUÜÒ[³FÙè	°ÁÛd¦İlƒÑ5µƒÊéeİõp(ôôî³ Ã5òˆÜÂ+¥Ë÷ş>µ_ß‹ŒS®¬,ÈöšØÚ®Ñ]éF…¹Õg«¿fıF¶h­84=D”K:T×¹§ï#d+rßÊNà¯ã7ïZi$  š.$Îxˆ‰²¥—8e¯¯ÿ‚ªuŸPõ%Úb¼M±w.&š;Äµkõ›á’„wPÍà‡©ÆãhÎ§êê§ÆC[ÆAği;Í¯Oì]O°¥Z4£i:fšTr²2ñÁ¬/KÌ½ãÆ|j0)ã¾[ßÉøWÀ¦ı¼“Pñanjèwuybv"(‚N0€¬UY
™uÜ¸¼Ë˜t‹G(Wà
‰÷ıÆ'*	–O_N!w>ÀÙ—ÆPíÃ®¾R¿@r ÷yEhÀÂÀI‘¯œfY$¿ğŞ’i¶Õ–QDŸq$ÀY5%‘uÎBÑÆÆX{¸ê•Îº¾3oJ‘á?2½amµ+jÔÁi]¸÷`E÷QH€*Æ'mTúõàx(”ÿİÏ}ì,TÙrõ[Bÿ0ÃACù¼ÖH¸P·Ñ\«jÕÓ…p(]f>^ "‡ïgÔĞ¥İ‘‘¦'ì¼4ÅßnÊ]" 9}xN]-&·×0Ø¿§ğ!iÌÜ´v?lF–e;ß|À†óùÕØsw]±›£¢ ¹#l¼h‰é#5ÊàûT];a+/‡f:>»–JXF®µ¢baÑäŞç5.ÿê.(Š¼¬|ìË¥›—L±ˆİç7©MŞ–cî=Sì9çA¢YşK7c”Æ¥ Ó’u–šÈyDßü‹Mø]qæ@Ö{_á)ó¾ç«U
ZŸD¸+êMĞªšsU«v)~¼EŸ¾¡€üPÙ›îß¨ÜÜœTşkÜç¡v¸ºc¯¾cØ‡¸2ÔÓ­Åı‘@í2Şé']ªÑ‹ªfvhéŸ‡‰<şÑ´¸06üD‚¶o¡TÕÑAİEGµÀr€§SÍ>×‘hpšx9Ö)±ï¡Îµ:H=À¹ç¬…İ„
%şøø¾H—¬_ì_VÏïğ#÷B_÷U‡ıs?·{éœøwUò«!oë66Ùrdv¢#÷ÖoH}÷ H^ÓÓ=®_õMş‘Åö!> ÉÇ}EÿØ ¥lbıÍàZQxÈµn¡Úe!;í0‡Åxß²FM¾¹6&–Tœ€ ßc6â\:Œë~öï}~ü˜—s½“DÎÆBK#ÏŒ„LN¾Ä°MfÁš;“ ÁÍE¤~Åµ	$SF¤wì‹—’Ò=kŞ‘ ré*„µV2ñˆ„K¹§ÎèÉDº>“?…yóxà!î:_Îq«Åøí<Ïz>˜õ|p_KÓ½²Z‡`³©G«E#ÉÛÿ-Ğô÷ÉÃÅí¹ãŞ¦â×ÆˆÔÉêŞ™ÖÕ9ïÿh€@ã€²»§qÀè„³e@ØôÏOˆ
… m¶SÏÿŒ<›x–0Äë€Ğ‚Ô$YÒt#¯×vï£
¿­·àJ?ˆUîé_z=k¼tßµÓÎ+VFuÜ;]°W)²F©r4ö›vÌ.Q2/A¶ªN½"0WÂzàZÎ•zz¿Ì¾¾¯˜É•çú9.[ª4®ã!Ä¡T–0`ºÕÙ–»…»°DeTWÛãNñŞw|?Ä1,=#n<•yfO7ş°Z«(hgô=DQˆ-VLÓÄ.Ï#¡[0ªÖÊÜF/™gàPÚÓÚ·îrÀœ@¨Yïˆà5‡øšaúæDó¾u0 Òg¡'¿ìã¢ÖLšFçó‰Ÿ>€Å@­¾"‘¯ƒëÑŠĞøo
Â^•ë¶–QêÌ¥’O¤…ŒšÖ`9»ædÿÿ¯¥naŞ6$š½Aª\†ü±Sè&øvÃ—šmœl ÷Ê%;¹ÿ;çY=i]%²áxšxîGÅ‡æ{x¢«ë˜É¿nƒÍ¾‹Ã )¡)‹Âæˆ8M£šqúvƒ­¬=oÆÙ){aì–½c²y×•´%Œ%ÍèªğácƒÍ¤–šnŞ‹pAı¸˜
‰G_\ûsdüÁÊşíY#¤H¼D€*ë°!fÂ©s¬àDkš \,•çmUƒ	kåæ\+ÍgÃ ¿g±,Şª‰,ƒıFÆ–ĞöwLEìR¼H’*ëèv&OÕ­XÏgøË/.¢2{$t{öæ’ª:&w÷rcãÁB¦ó6rÙíæİ_¤v²‰ÑdîuäÄÒ!l¸¾BÿrX—$t‘jÆ.¿~¡gÑ=áno4ØfÜ4/~¿úUV„İ7ë!oÅ²Ú°ÃáÏBÏ×±URÙ¸6Z…¾ê#ª‘©AœgµÆÇ-	ä8Š¨éŒ¢à_p´ƒ °	“†èìUŒS,¥Ê”¡á]£dÏt)œ+‡°‹û»ÓL\œÄĞ4¿â…ï))DxR+/H‹©‹ğ>"Ô~Íjç/5å²µ ü¢Qóç°èFH£1¡\guTû€n`;O'$DHÉ™?,á¼KÊ1§R'·Äñü¯_ZœK<7åbá¥í„–Cas½Æ[†àóïlÄ7²v‘DÙ±½>æZÁe<½Î3¸9DÄ7M|6~‰O%ê¾×ï:ÓisP@µÎìÀ€²áèì|–¶BrªgÈ;(ûôIøáSL|hŠ$äï»İ–ùƒñ¼¦(êb•èAL«¤iAÆr=·vKİ…Lx#‘¶î(q«&œpã"¾ú‡³Ö›‚ÕE¢ÚæÍ)6šy>r]Éï‹õØM:3¢§ºL}ig´F‡Ô7˜ S¾Ì‡8…Ö“Õ+¸0ö¡º“ªC0aC‰ÉÃÒj³™0ïû¯§Kà`r‡«Çˆ#³KÔŸ~(´ë?R(.¡a‡İÑ“|*<xˆÎhVà
j%‹CÕé‹Ù ÿÜšV‚?ëOSFsÌ5åÿR–NK äfù¡=Ñe²'oŠWNt'F¾SvE§VLëŸcàÄ—pÕJh|mYpÀ‘i ‘|¬ºcÅ¨Ìì’8Â©âôy œÌñ!EãYcQ9Sxó'çz–(©÷6e.e#Â…K!bó°
ìüG Šrµ´]4˜~¹Ç·@TRùîUÉüiÔU›ğsjšy<¾æÙmÒ,á†YÆ¸7ß$Ã)^¤ê®Ä¾çŒ¡”W ×ãÕ&ç¦ÖŸÏ0ä-»K¦vßL‚/h*Ç¨(Èqó–W	Óƒ?}ñßÙşcmŒ0Ş6¶ööîÏïáu¾pƒLÿŸ^‹›OVò9Œgó&Œ7~—dZDgoıPY4«/cHÎD©— –”÷0ã^‡zyB 	,ÚÔà¯
ÂæMä@ı‡»¾7•$
ë¨Í}ôß>\è~-€¯Sı'àwn´ A;h°ŸßJÏGÌï¢ŞÎŞÆ¬!jÇ^¶ı…#X$9$²s„•h£*4ÛMâb’ñÎˆâéR9rı¼RT	Î7Ì»˜ÌàgMô6â‡àˆD–Ô2±UÒ/DÂP¹‘èÇã­5à&´H‚Ò·x·uBË´Ó`ÆTşI_Ö+.Í‹zÚ–Æºf§¿ó¹l('RÛQı+œQZJ&Dl”‰}Ç*agCÕZå_ñoˆZÛHM1 Ñ\>ók§oRí†]¤øÚ˜F ²¡@ÁŸÔ¸sk'=åv°r	ö¬Ë±Kş$Õ>Eı¿ÔuêÂ+*ë(rœ‡ÔL­\ùjçMŸ{’ D(ÈêãykP„3Ö¢öIœŞ›G¶léºÖK-m™75ÂÏWÒf†M3A\gÙø¦xY“aŸ(&¯bX%`Ó oÖ÷jŠ§üÍô"ÜG¡&7TyøxßĞ`^T‰b¹ê‚n=»Üq¥×YR‡ÿ-¿LŒQßL–ûÖa*¨bÎKÂ,––C
³j£LXÌ,T£ûiÁÿ´ ÑM÷;&Ybº»åpæ›H‹‹» •c$íêµg›E×tŒ…â/â¾I6[¡MZ³rôMYéIN¨S¯öp’«+ÙEøİhˆWµ@‰DZÖîR­6Q©ÍtCnz±7 ‘œ«ÁÆ¤‡1ÓXMçSG×]=êßÿ.Æõñns¯µ+y î¦F UlOxù²ÂW¦Ü]BGğˆPñ…¥²ÓI—w$ãú‰AÌÀ®—¸:´sü'},dÛ$ÉÈÆœsıƒ‚QMùu+H\¥t3¦&¢áÓ3®ğAˆ’õ¹µ÷­´ä>W&¸å–|ë<¬§˜¼/H69¢U£ÓC­ÿC«F¡pêÄæ·eşŸg1IÏƒ
gqñõ-İÇÁñm›ö[®5T”‘ÚİÈf!á÷+‘‹s¥`smı×]o^´¡¹º·u/ë¡”ºvéj¯dk7“2HBAï2Q:È<9JsYIŸŒ§3¦Û^Nx'¶>ûÇÛ;Bkl;ò*)¤ôÏ?WĞ—šğŠ"©ğõİàÄß?ËG¤V¹kê†—ÛËKaúFûEí74È˜$ºËŞ6ê×˜1&o`¡ôõ8š…¬ıÉûI ˜Õğö÷ÊÜ¦ôXíPØˆ^j|¥xÔöO)ÉKf¡ÒYÕSÁˆñçŸP*À7M“ÿÃÅòj qÒ«3ÚX­5ù*äÔ¡'|HÒD% P´3ár~é!û…ÕËé•¨/ßèš'©£#ñ½aBº®İÂûì•/Z~ªİrµ ‘‹ÒÂ ›gøt×ÆÒ,é’„y¶ÙÌñEòù›bDGM'âˆfUo[Õ[_­>ÖŸÖl˜bà–¹ó“‹9·òo’ °R Ìf´AXå[f‚Iş÷©ÙÙb‹z½J+¦Œrä¼äO®VpCYÕzn2^¡åı­†eÎñººŞ½§®¸ŠVªsÛwëécà™†uÍ´»pŸZ—4bç®([`¨ÎŸ³„”fS¾%òUbğ!Ï0¦hXŠ»ÉL{İ§F×^§€·^ÓËD8ê‘™ûm¼')·§ÎÓˆ?ó¬z_÷ôAİ—!ÊÉ™eëcƒ-Ô~ë(Ïep*‡LV¹ê¾ñÈK‰(]ÃoÂ(¿!Éazò =Ìë¡:mÛgfu™âå5Ì@]b#’œ#XÖXÍîoxÿ­À]¦—!\lÖ•^Â©îÂL²v¯Ì®0/<»P³BnY°:ˆŒ¯Jg*ÓE`O¨ÿ]&\şÌ&¦EàÒ—‰Q¬­ø |‰–­Qk°‚¦ÎıJ²&ª–ıµ˜~©—ës±RÏ°A¨UpŸĞM)ëìW:Ğ–LE†o\òc ±ôfäË•‘áNc‰YÔ§\·2ópX^ßŸN×DxÂÕ¸‡µdúß `Ô+NE­R×\Øhİ›f1Gô¨«ıè¨2ÙiçtÜD@ô`j±‘”…ı¶¸ó¾<“wÈÖœ&´ÿÕ)ékÕÍa»Üƒ©ÛJ\Ù3?	Å·–	œ/]z4ÈEí—»h°Fù:JÓèM•­˜"Ï²(‹ìäni;ÊÑôÕ¶\q¬¢šk½ÂÂfV”ÆwjRCâŞ:0Dàœ%ùâ·a¬l»¦ócqş4„€±ebòúÃ­>r„ßšŞ(Š¢Œ‡L3çZ¸0â€‘t¾ŞŒlªƒÇi	ì[í²„úfUVÇ?¯ü…“*y©J¹wí!ƒ´mï+Ì"Àë}ª@Ú¥=1•“…Rú/€çúÌÙƒUv`ßôTÇ /kNÌDë£€ÊçµÕÀ—Òo4ş‰NˆÄî£Ò ÈmT1–[«Wvtï\§Òˆ÷ú/ğêı-¶bÚº0­ª£½Ç"·5f™â!nu¬ğÂ¶ø©OÛõy,C¿Š~ÚµeŸ%ÆF/eät!pËUËK­“¥=0Ç‹u%u1üdEÑZ6­0ÊÜTšxÑ8ßPHTˆ¦}ÂM…¶c½e#¡…€díN S¦À“VP°Ã}aÁ .Øóİeã}aìæïÈsíê31Î_È\N¬S­±QÈ»Ë¢‡™“±*s9¾ÿ‚¡¦ãÏ¹cÜSÏtó#ù™ƒÇw0U&ÈÎ²¿Õ[ûVÕÎ×yß½š©0B@Ç@<uŸ†ĞP©L Bxj5°}_©J·M¶§Z²;úT¼òÈwrLÊ^ò…ß ¦É.Ş‹ºäúEX¿›b_À ²]šdÌ'úÆ>i„Ë€-p ¯üéHüí@š`‚heRçF¶[}N{
ßüñÓş~	2ô^lğüfF`FSL(©+¹ˆb'™Åùu&vÀõ-æ¹
µ—ô÷'QNxK¬êdŞzÂ¨zWu ÒkPŒ»oXéoÊÁğ;ÆLã˜ë9À€wu…y1÷¥¶(HÖ?@ó;¼RĞ¶Mçc‘s6—ğÃtQD{¹ß:h:îFWxd_hY§ıd×2áºBıŠ\Û˜/½pr„Ëpï"”çòÅu¸+Å# MuTóß09Q½Ä=ïö‘Áø¬E‘]Nò…9İH Ö^ª«>R< Y$>%ÒÉÔoiŸóp±Ó~^Aë:<z‰0 ª,)!%rhÛõÊj¹"İ1lOÃî`z.ïß¶!’èy	IåÀ¼wO°ïØ	±(’÷pÔK÷{Ñ1}Ù|•] @o7hª²ÇèÄEÛıKÎ5y«bÎ4×¨O×<ëŞ$q]8Û¦äÿ¨&	S_5·ÃŠ“¹-â¦\2z}@:ŸZYÑ.ôÛµæd°ûÆ,0üqâ‚‚ä¶#ÂÜZ—C ¦n	Äc‹›©‘i§ë‡ÂJ›<[c¡wp¥Ğ™°Psê¢y¼.Ñç‡bayE$$¹}:ûØÅCqQ9tlw÷½7ïNºª`çXôëQ|Ü—+ÄìÉ×â_µQ³=xíLp«/·&û=?‘X«>ü~Å³D<š”ÏëõDæq`ç|R[¶áV;*cA$$‹	§b|j„¼ä«è•GàOÛúTåV`RÁ™âõì8î…Ã(-GäŒ M³ôOÇœ¶6œ"ıÄòÊ¨OşBhÌDCıXœ®ÉÊëLp½6½—ûØUŞx";Õt‘é0¶¥	 †nR«ê&û°Ieäeı@¸pwúoà›@/Y)>„Á&9#»šÏ$(Œû"/³¡ø@­Fo²ø?väcİÈ‰£ò©aßÍ¥Ô–ŸªÜ,tâ·‘è@=½1H¡9DÙ?Õ¾¹[GÔe(°¹wåH¬’ôŒCúpï±ÖÑµnD¬ÿe¢]££Ç m®òÇùÔ5m>§OJn<©¬v‹º}Æs^ä+Ób#RF“ARùd{q\rEv‹è#|ÀıcV°À+8¡¡«„<+÷Útµø+Æs©Í3¦$–ÆÊøz%š£ÓäLöÎh7Î@äª‰]`~rDIÉÇÊu²mã6Ç"Pî‡Š±]º“–£]©j@mÙ8¦¶†nvüƒ‹båÒVÙ¢ãÕEïš1)±‰Í)oX·3aœHbNtX³Ó0Î0¡<oüŠù7ÁbU²Â‚wu6**3¢g|Ş	ŒâºùÁW²È[¸+€Z²$¡î-®°Ï;ÕX­ĞbÎ`#¨r0©	Ÿã87ÿxşF»æˆPîŒÃëÆ¦8#`éw’ß}5ÊWFí¬Ë2?@’œ,›é¤lX(C’}È9}ìÊ›‹•‘ªÓo$Îúî,Ò¿Ù¿ÜĞí¹c¯F×,Z“	6]Dq÷Â·Bè0oQœ×¼D3||yBÔç¹ŞEÖ–êBaÃûµá="†ŒäØÂÛN¼ù,	BT²ï[…üdŠÙw_P©ÈÖ]O5ñÁÎÎªe‡¾½-†E¦ÔÕP0Ì®’+¹lAKÜhfÀÃi:ªNóş¦+)oTm}.í©GÙKg®9¹“v·eü‚ôgşPİì»w@»Q#7cBÜ÷Ïî`!Š—XyRt=kò—èi•ó‹±·2JÏ9®ÎÎi	wM¦&tÇ’/ú’^,·ğPºP{O.§bˆxËí¾	Òä€Õ§;ú'áFFu ¨¥zĞUöei
u†Ê'ú	NŞm€»ï=™kê< B’©"ã*—ËáÍ*S_çÑ3­#ÕdğHß`ÃØ¥’ƒ¡·øIÔ‹Dºå\›/—Oã`<ÔÙ_$g7Duã3^å˜>,7`qú@&<„d+V ~ªè¢’HÎGªÍÌİ¯hUÓ'l²*¥VşbèÁSQ°y*àåw½õ
HöuÛÅ¦Ñ•ögí‡>£'z©Ñ„FfÚˆ\BNÀºâk•A¤©×>¹•£òu‚b¬	>›³`0ìi2@¥X*	•´†%<:˜}ZX)Aùn5ãŒ	/ğÂÍl|ŸEZfºĞ-¶!Á"‚m´S
ÈİüÃK!Je§Ñ‹¼ÒP<ÀztØÀ¾R¤«ÆÛZğûŸ©K©Æjz|´Cwf‚uï®tu"«ª9z·*9Û=ˆ¶Ä&Z`5§Ï¸÷Ö²¢Âöúöw–©·Œd¨eŸ8E^´u½“*wwSÑ5kçà¶ª™¹U^"ª%8’#Zo
º\^-|O¡0"Î+›tï	¥g¡¦# ûª‹Õö6ı;v§-(u#TçùšÛÁ#*>Ny‘(I«üa¹))úÂ¶“DÖêŒ	ïvŞ•?RS:Å[réÿ¬h˜ Gq&ÍhÒ%;°L}Ps%)Qè×:Õ7–¢Ïÿ$]aÃÌxˆyy^›>¸ÜêSî»(Àa»§‰¬aäõ›¤ğÆ§U]@Ö"Í“uÚ-ü-uá4¼ª *õ‚ssÔ`ºX3j¸›İ¶…5,}Ï´`_ÎãìÍŞ¶pgå¸ü^>‘t(…:Ñ}pXGVïcô¬KıÏ.è¸ÁÔ{÷O¶»ií)HpY³‘£3¨ò0×ïKCïGÖËTMt0Ñ°™\¾aóäù
7w^*Ú{é³åÙµ/ÑZˆyâqqAbÑ×MD±WÄÖJ: ,àD¼ãbtXeNp&êÑ­á¸Çde-Ã¸úí\HÁö?éÁ#SñİhìÃáà˜]ô‘|®ƒÍ¬_¦´h¢µè,p U’õŸ½^Ä_@!+,”u=Vq‰a{×<	¬ïÚ.ĞRtÉ‘ ’8óÇœÔ²?'€À{€ÒìœFÆF¡÷ÿH†¥óÿM§(…wªLéÚÅ(C¼ÜX§ù½¹H9€v6û÷µFô—ïoµ
À8Àè›ë¯yò°lèËTÚ…t#º Ó‰In$r=Å†ÖÍuKÁ14/w%ºh€ùDY¸Š>Ê§1Ø<‡ú©›øá¼’hËƒ×X”ŒœÄË¨â*/C•9ád²nOyU´¹[0ºjûn‘á\ûš	”Wn“*ıæO
c‚ œ#fÖr­ÜÍQ·µ`Q¦–/x,«ºò2'Å•‰	
;å÷”´‘2•>7×VÌeÓ°Ò‘Æáÿˆh=ç\áÿ8ã{f¡Æ0â—ïÈIâ6'o¤T‹"šCMzT»¶Ài 0r_3Öt{Òº%E<T9ì?q±kp+ê·=qÕz®‘4z)( äÍ²ßË²BSêš+d<F"ÌxÏ
{ã|€Ü‡tìÃöç·ÿ‚Æ~{¨Ğsì£M‡GTò©BÒAùöJ0§ç~B'î‰Kû÷y–ó¤Hjìh2SèØœk=0QfÄì§ªã`F–ó‚çÒ–Saæ¦õézCVõ6>\È±üáäkÁ,ì(7ï=Õi™v°'×­@îU:¶åv÷6iWõú=Wu‚S [&l„âØ(\í5ú!š¿qµ]äş3
”&¿cW1İz~é
‰V—'$ĞrÕİÁšÎr4cÛLMèÑ˜u¯Ú"»i‰íÜåQ*ûF[¹ëÓÏ&1¾Øº2Se&ø¥(Û·µú‘4#Dş{‹ƒ¾F+
mü¦/Èd?l×~¸,G’ê´w2ûM¯©âœ;xí¸Üf9( Ï¯6²¡¯!TvŠ¾eË#ŞŸÌ˜áBC‘£äº¬N‰H1²¸eÿ¸Â·}Q{ç‚gÛ#P\’³ì-=Šä¬ÙéI''Å¬y
¥UıÁ·½4‰‚ƒiÿQĞÂ@7vc°c Êeƒ_îW&ã,Ö €íçPAùÏİl—Y¢Œ“iv6öXš©«:;Šå¹z”ã”Ç_zI9ÂÛ“wİ
‚^Ê6¾‡>ğ³‹rKÊÜÄ[É8[}ù~_^n
Êvª™å¦Î[2<ï±·E` 6 ]HÛæy¨|»’˜Y'¦¼]ìæ]¾–i h+Â°¸õÓÚ«¿˜o¸”„Åoé«cˆƒŞ×”TïÏ
àfRÊ«.HóÓ0ÇÖ¥sĞOdGÅ¡›ÿ³Üy£Eš¶ƒ¥VÒX˜uqëÕò5¥£‡ù!İğRHìı²¶;¡rX&…™Ó¬İaÊ‡_Àº=ÏL·ì_>u±š‰‹Æ Ã –ul¶gñQÁ–Îq¶\ŒP$½ûó‚pw÷ß¡AœÉ`s¹Äó«tfm Ô«*ö$É(%Îr¼9Úşğ†·Á¦à?Ú¹¡#ÚIol;š£3é Q²‘Ôn½&™Qğ€ü\1÷Û¯ÖiìÈ‚Rê&·éfV/Š^²I%’ré…éù¶³u½í­æ:ú¥×·‰a¼½]}ÎŒ—B1
Ê´Ü¾LmB¢Vºkê¸aÇ…Ch¨Udpşê¾HvÁ5Œ¨PZí•2œ×&€æv”®Ôã\w$~Ù(.›G;ÒrÏF»ÔsÑ!» ²Bşé—Qó|/Äzf=°¦'pÉÂ,+Ñ+ÎÀûyxÓıB`Û2:,™›ˆŞ’}ª“ä7	Ù¦È´ıàyi`LL&ˆHKµ¿Õ<a‰/x{‰_Y$Âó§ç’Íƒƒ«…ô¸~ç¡ıI#W‚©|VHŠÄO~·~>F@"nxö•ZÄaÇonx¡ùı
^#ğ/Çş¯k+ì+†YxH¼ã•+¬èÌ:ˆØƒv"‹§™’—k¬’€^	QêP[±û”_6;b
={ùoá~tãÑÚ,¿ÕR!İ¥(•“XUXÃ«†OßuâMu_ÍrÂ²ôxHğ_ÚLBÀÍÔ	ğ»„-I¨Õêø–¬ş„ëaugwbÚÿ1„/+=*ôKåöt³µyßä_ö·ŞnãWïUZyD®nïÏBÑñù7ç¬p1¥ò;àì3ù¿ÎÅÊÍy§-Ûé$KææÒ<É“) îÿNLœŠÖMÎ“tÿùó–Hgç
ƒW7ÖWùc‚)ƒRŞ+Yb­©Ö¯É#+º¼Â`š³K9BŞ?HÙ”[¼š@oå¹ùYq¯?¥bs|½ïàª{æ%æ³sûW£^å¶e[¶Ëm|ïöÿYoãL§qÒ<ë¿îa¸xnõ]!™ò©\2ŠK6àb´”Ÿ¹å°@mÔÊÉW©üM9iC‡ ¨
ù‡ˆ2’å¯¤Ä9ø›ü9nÕ ­ÅxÃäjàÍÙ8‰ö4^26Ô¿¡ğüMş«q6¿€I†‰¹C@0o¾V¶['¹Ä£Ê¶$Û—	˜ˆ¥ÌvªŠi¨‹w"¨£ò(~9B3cÙ‡3²>ü[İ>‘\	rÈ8•é­KoXndlP¦/^@ó•0›sf–çtnÌÕ9±‹åiÅ_¬/üóA,ÃA',
Õ”#+Ø˜PóD©›h‘Í÷˜ÉÇ²*Cf®;w‹¢T£ŸU7å Ñ‡ñU|w3E×î6âB>ÜÌaÍ`è÷c@å¬úaz³|jå§ØGX]KåãÖÈíK*8í®Zá4ª¥–:	Ëìr¥¯`8ÿ0&hŞÇár2B“uµÚÛE“İ5tY\t>–>C.Q(áÆh?½‰¨ø,´eù €û²r¢šc…
¹´”Q¿ë* q‚Ñ­@VİÌ½f~l|æ¢.k¹Ú/İkŒG*4eb;GÆ0èYÕkBÓêHÁtmÅÛAìôìñª,Rå©Ü(4å]’ö¼ĞÚbj2ô~>ä¶ó|š\G•£D`‚³—Lšı°ï·èC› “—¶¦„Ö¾¯×7²’#Pòrã£ÔcG€ƒ$«ğ\; İß“Í%¡á[	ğ™Íè ªh®ªo~­Ìz/Ú—]¨xvAÉtKñÚ¤~Œ ¾˜&å.“±‘¸P¤î–å;È9›¡78Ÿ“nê&Ë¾œİÊ> ‡ë7PÀ¼ÔÛwêú=Å®nú#’§w£êH"DÁbzVØèpÌ„l)¸‘+A"¡œ½‹şf6İˆ
PBãañOUƒ|@›¿`8J'eÈÎ=¾Púe1Æ]ƒ9<›†œ×I()ÆkYà HFTúÄ¤UÁÚu³ùÈŞ “,ÖeLÃkÂy¥yÀG\İ	“éïên3:[[“3hï$¨…ŸM¦ìL:¼Ÿ¹Vu©Ï£`¡š­Ljñ/Üd)L°4ºí‰l¦7›„N…PvvzzñKÖ´Ü{ˆFKOár}ò¸•!lä
.2Íàšfß“Ë—y¤7ìÑö3
Ö‘mö³˜ˆ>rèêó±…ë³G«à®´@¡0¨SgQ~ÍõM`ãt³PA*`’±õRqDÅr¥NU`eÅ®ÊT¿áˆı—¼Ô‚ñ)	Âi¥‚ëi¹{™–ÙÒ­¬åVH8·»1d‚Q²ˆîÀö/£¯°‚ãxBÁ(Nu ¶i…›!gÌú{¯i8ÍÓQòærpu„Uç›vÍ0pÈBÔnÍë¢+ÏE…(#ÓyÅİfDÚ="ŒW›\"¯Lı¹qÂ‚„…÷¬9ÃLšèÀ¢+ª‘WêŸ³z™>±—ë«İì«kÅˆ=ô»AÄº>ò?%í»|09šÚ]³OYjÛ+‰ï‡DÍ%×Æ¿ñc+‚´Ş˜bRı$¡[_µw5'©Á÷©„GùŠ—ÿêbkÆ$MGŠãVû‰Z¦Ë6Úölº$gàë0¬©9ÙŞ¥ŒÓÙlÒêëşÁt–fş®[êÇ*G¾Ìê1ãäDY`?şÕÈ«ôTŸêK-åıˆhõÓ@T”Ë*šÂÇlµ„öŞËÀ²MÈ!ú[J3•A'û	7áîiƒmÏfÜ†JèÒºÕœyÓ?„IÍâ£3†^rO3	3+h‰oû¹‡U£Ö+ğvÕÜ–J¼€¬ÀØ\×ÂñæÏÉ§Åî‚ª¿tËúWgSØŒûGeŞfïKTà&ÒacD°Ğ@Ğn·µ)”—Çç“Âß¸#Ü|@ÖÒ«ŠK.çså;Ç§<w[±²D—w1A±p»g«
ÆAñäcİíÊ)İrAË-ÌŒ`$xOH«=ŸÇæqkŸ—š¸&æÅ~,C»‡€»\]l´ù¾Å$}´é3ÏÑÌ:ñåíBKæ€1ÍJÈö:<~›yW\Ìëúº&p˜ô?'Gs\oXBÀ¥‰êKÜÄ6Ûz>Fæ?ÇhMj¡³?Ï°bµŞ©@lva¼¶#H®T¬fLÌ`,nš'÷ëòÂP4R¿ü÷Ë7Ö*‚ˆm‘¶Ò•Kå;ÒB±6(;îìŠŒÒ+…?(ûw7ª†9 k†Î(a6ù~N5W$\ ´RÀT”Ë•”<åe=¾ÕÖkæ`ï™m	R=¢ÿ,;ó®V¥¡@p˜ƒû”\¥¤Mœ|E3Œ:-3ÉPXŒ›ËApù!®¯0ªé•ùúÇ°Hçm|	?N lÎg˜/  ºyZzóÃãƒ84;6¥„•KĞ¶ürålovpP/ºÒÿ$ºÁ°ûıó‹4JKc•n÷İ}¢ö½-K¦f'¼7,oóÑšwQÂÃ¡›ìªşGRÁ’­ìm„à[’ÎÜ›‡)®¤rB¼.Æå$÷^”€Ée{[OŒ1¯İYËÉ6g{õàÑÇ0±)¼æ	› Øº‡£ŞÑQ@€C
Ã”@m-ŞÔ]B|`Œ°Õk›d3#çˆ±FtXıÈ…aN®¾Ş´gòiÈÅÎ
që>¥Ş!_ÑzZŸ{ëûİu¢¥—r#ægR52ê‡­.2x}©{ıÚ©4eò3CE1mî;÷94iâçñö?O¦#QÍÉ ãäFÉ¢l«xta7
s6A¶Ï¿Èº@R&êÒº›÷Ø¤$?çCör	Õ2ˆ)9N×Q§}²=‰}3×Ÿs?ó‰Á0t•“Lşö+ƒóÀ¥ò\•O¼4­×>Ü'‹
v•’;»V¨Oİuxº'–)×Í]u#¼)«0ŒúCL’,¦†å|ifS6“÷øĞĞ—À¹{¶VÅ–#ùt“Óip.i°Mµ”õEÿ†Z˜;J²—8™Àè5Dƒ\|¾çl@ÀÑEÃ=ÒMîö¹Q‚øËÚÎW&	Ù£½AİªÓsïQ£ß|Íkô¶{¤ÃE~ÔÛâ	µ¢ç]É!ïä¸ëBïó¹[Øò-
kŠÁâ¢Ï}Ä•ŠEÓq@=—´?]‡G „ ÛG¯¨Şd'\Æú‰Y^ëü//Kñ³—C`÷®ı¡ø]yUlº®íN¨ÍÜíÄ¬·E­¨
ôşo8´¬°„Æ4º.C“fqN’OaDÆ¶i~-ÁZíãÜàXQ‰•Y¦T¤•(š'EB¡¿ç%óZşˆÚÌ¨­±Ÿasb>Œh¦¡Wè¯Ô;ålh½íLğ.·—¾ˆ„îsãôúJÔù àEşV}Á²À‡òõ.ÀóR£.¦GÀë'	äkFÈ¸”éÑE5µ|Â ÕE¼/ÀêÑìèbŸ9õQkş-$§ÁåPšúâÚÄo5ØÁ]Ÿ­jÙêmÜb·…*G¸:s‚½0–¹÷ã¨%şÍåH”àø‡Ì‰~ëü[>´ò’9™­Š+(—6Ñ°ÛêF÷i	/U’–5µAÆeï{‚òVõ†ÖedÆ„ìÜà\¶R$iã~ü.Øb»Ü¦Š|„ú¤©¸ç8,Ìf$ìÑébMığğÊ¥¡§[\Ç¤Í`|0ìË –vh¤¾ãşo8l@HÔŞ£šªå™ì…û—§¤/M¼Û‹hb§êÙvRĞÙ-âé¯,¥ahvÔ´ñâQ„‚ÉuÀ™äZŠh—øœÔ~fŸÓ…mDÿ?°¿+fµê@2Ä{°Z‡Ï‡ÈD­ß¶¨&+´}+³Eb æ¦“+FÂHw]K”Çì¼Å5Ùs¿&kñÇª²~½“8íÿtq;(´¥à"¨é´¦˜Êí¿8›*úâËaìŸª±Y\Û‹àcë¦¨d¤ıœùÒ•M,©­á7N¦ˆäŞ= 1ØQtîd.IkÁS”Ñbı6ort\0j(Üæ •Y¨rö¡wÓ ßá>½Øí¬,v,Ş\€ïkÛNĞ&…{H»ˆò<	ª5|qÓ 4”•£‚êeÚÃÚéø‹¯¸/4§M|ét_.Ø¥ö¦=q3·/ĞÈvKô–¬Âû‚±_9á|Ú@¼mè7÷2>Âÿğ%ˆ;»:ï¢ø#/§)óœïaZ[î ‚ApøŠ­IöÆ
H°[¥½¼(.àõ¹whÃ¾ÿÇ»äîGïdjyt_>lŞ``¡:*l&ø
‘ùŞ[¢á‚[½Í Ï¾ŞLÌ7‘·b3P\æ*v	„`¡œ¸Ü‰ìé=÷˜Ós£§ÂÓ@½ã„çpõM°ˆ]ï++écX+F¬ŒªÆÈÉ¶ßıÀr¨[v£šĞ­·Îğ÷T3L×ô€3³˜$I¿õ¤Åe’äÇÌ[-Å,}¯d¢§".Âm{ßÑçœKLÙ5PÏï	?O=í©§)°°’¸<E‰¼¹ãqäã{Œi .Pß¸`ëktÁ>%í‘¤®ÎopÇûVóÄH]R²Y4©â±4û‰92à-ùêì±İ+wÄGad,	qøÆuÉ—O(Â Åò$‹×ÁëU<ÄÒÍ8Ë†\(_P>°“<bnµº4ø#„pM%H¸ş]ù@<‹¼	ü(v¤$Á1dğ”¥÷ı#{G„h°{'>Ê„•øê*øîñÎ}jÖšTA„Lˆ¶`ªz$€`Àø½Ù.:úŞ	)5ÄpoZJLWÁ­SY(®¥uÓÖ:ò›´—ãöŸşeŸ*è'Ók‡­±YR¬¼‡Ÿ›i@ğ|áµš–ƒo]é"¯2•è2]Qş‰²JöŒ[øTàf”y%R·oZM-I‹çÆäe´oWd!âIòZß„Ma©Y4QËÀ;ŞKÚ® jŸ½ÒMÑ¼ìÊºr«‹,´a¡lP9Ò?uÈŒj,wBbDÀKEÅd__M}İQ£%2w?€+jó°BUÅÉš6N€ïŞ@~¡·Ãá!YCóÅñŞF”¨ñŞ8hÏ==‰\->¾™şğ]ŞÇUÈ”u	ì8!6ÍÓã#ßj,-x¢LXÛ€ÃÈKKrÛ*É¹sdÊ:!ÍmZøÄ'*­£d?òÎy¬)•0r˜Ñ'ü†ŠyLèóN*•.ŞSRëãì•&~²âz@Ë =7[ó‘™ŸcX¬¸\õ¤(´q5'¬—Â|ˆåš”ûQF)s±T¾¨°Ú‚`Jt(ÙÑ¶CÄ1`b‹ÂÖô?ê-huC0`Bbç‚¤‰Z$)ò¶Ÿûåã©ETšG“Úé©Uµé'öy œ>¢X
º­è-ÊO@öqYİd„+Ù^†Â‚ÅT>tğÆãehDÓß<ï‰<ZbÜÆÔ"úV²%Ù’Ík€k­}¥¸ÕíÏNÎñ•Uı•|Ø0Â£QÉŞYùfctµŒa2L6h›LêøáZı6éö¶wÃ ÅHYÅ »­H Ç)áÇÓ.[…½S“İx&‹œŒ‹_…ïÛ›ß¿…»ÌŞ0{MáQ„›ØÍ›c;(>×.÷±ß¿	2P›·ëá‚(®¿hij«üÜŠ%Çn C÷t-Ä6† 6ş÷²<szîğc<²Oï“Zjµf¨áKè£Ã¯U bJ.©CÍi7rÄ2!¼1¸¼$ëÅ3~
sÿ„‡Dmw_w6ù oÁØzëˆØtñú@½ìıç€õÜ]ƒFDZÅ5¸r
±ÂDy­ê•Ë
ÄdnˆfÛwóŸtïhÈxæ˜…o%h²$å(´¸€dO€B Àa=ôï‰jÎÖ`µ˜’Únôyªi•*¦HqÅ™p‡Û¯e¯/4ú?+yxuÏ6R}„g8÷M7ÈÌ0,Åş(Æ ™PÓ{j.’%wÒÎH¡7…¬ãÔ
şSœ ëìx	?W´X[î\¡jû)èŸï±õÖÀëåf=ó!Ğ9ÀfçÛü¡LÜçì¤èˆÏB;„3¾û¥Û–}õĞëVòÃO»ÉY1
š™õA4ä­·¸½9Ä`˜GñGf!My„—CÉ“¼^¸€imƒÜµK¥èw×&iTò~»„8¬wOßdŠhÌì¶4	‹ÿ¾Ç¨ªpeT)÷wüªm<J|–ÂÍ?ƒ§Òñ=½ªÆÂşñ½yÇ7½m»³˜IÒæ0×:;¸fDS<~^I)·(¬˜´Ô0ªJ;ÄºhS¤×òÓ4µ¾õÖ9ƒ°Şí†ı#j«ïùüÃ°„²gz|å6Q˜Wk3ôı¾õ°O¾iy1R±5,'—*ğ©|ÒéâàÓbŸ^E (Å\†ĞrOïÏëÄõFIêR¡mxæÖöŸ­é%d¦r	åOJUñ&¬˜³ Z[7¨İT©¬¬ök¾áØ8d×1ÿÓ«t'DP±ÒÀs,Ù¡µL÷Íù!«ÌÛæ"æäcÂ,ø½5£¶_«l­íîM"liñÏjû+nØåWCv{DÂdÿ)ÚL@Ù­iË<ü3 ¯µ$u»8b˜Rjš
 l°".A£üœ™Ä8ÇÛ§ÃR*Ä±ÔÅ:‹ÚM¤Šº­bS'ÈxŞ×ùß'éØ©ÈˆÍ ìÂª¼Wvf„e#/Š¬İrØ`|˜Áª­uîª~Ê>ønV4Òçèıg [ªşŸGâG9j*ğæásnC¨oo,Å8I¯ĞÂtîzˆkÊ«²9áæ‘f’É$2©Õ)%ªÀfÑD„-òÃb:ß†Zâ}FLBëàF!Qs»l6‰ò¼”[LjYÜÄÁzŠİøéøºKÓFe¨¬p@P”ã |¸Ra\dìëåòùcAÑšÜıÈÜıY»ÔÇp·¥&Ôğe;æRå5ÇáM^Ø±~+Î>ƒüà¬üÆ"¡Îé{˜X°æ‚¬GóM³)B£h K¬Z>lIÂÏN,Å(¤dA÷ê¸‹T~hHD\ÉÜ*ûææVä ¸!Õk>–èHCN·=^RW3¡¢‹H8&›¶»g>»NÎ0É[ì¬kÊ^ŞÆ­†ç#¹.Ä¿t<ıõ±¥ùUÙO&_AzóËfa°9%[ØP±„ìo„(+²s˜^zÈÏ:û¥ñ„ÏÂ†ùKÁ!õ¿­ZÇ¹ÃNõ¯q¶5˜—Ñnm†ì¢dõûL‡ÈÇÓ$–r3o #Íuå¤/¤gN¶R[ùl=ü9¢àí¦‘“¼·-O¾
7÷Ş<õ¡’+_Ùœ]Â£àóóšÈğSv|œP,¾F…½¯É…Ÿa2‰ßQ0fÃ‡™ï-t”ó¬W´9j™çÅº+*Ar¡ûG ·ÜëÏB¦‹/™Á¥ÙøøùúE¥QE£%¬x‘pvÀ5à¥oø.X,*İè’"ì<‰‰²kãCPİq˜ª9ÚvWù	áÑQf×èSj½ïˆ+-™‘µÜÄa	=ÇHü½¥>ôöBŞ/zµÿb‘{ö)_±Ñ¸ŠôEcÀã,øŒrU#IıJrfİ‚~şªr,“{g®×üÇ/­bË<ÿCÁÓoÚÒ±<Ö=—¼Ğc-û>¤Ä°Ew  ğ¢mØøˆk± Ğº€ÀOæ‡±Ägû    YZ