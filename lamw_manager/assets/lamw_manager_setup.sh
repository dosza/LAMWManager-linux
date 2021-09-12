#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1574070342"
MD5="ce1f31545e071cff05f15f36989eeff3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23696"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Sun Sep 12 17:16:51 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\N] ¼}•À1Dd]‡Á›PætİD÷G§-W-ss$ËhMoNå`LøÎ[£'î
óÜÂ8$TùÎÓtTÉ†*ñê³XNëö‚M¦§åİN»q‹ºÏ˜"vÎ‹ÊzP×[gı?Øª/Ğ9U8å@Şs]¦øM'›yêR–‹Íäåğz¨UŸ¯Gf|Ï=¢Ë¹ÔÂÔá:|EºĞö?şsõpíû3èm_şGFŠ¿Ÿ^‚q•¹­›¤-*n	¸èOÊJ‚í&ÇDùòßÈ\×ä«‰¾ì}2Thi˜š{üª¥"iÒ÷=™G.hI‘L¿kú%­„øt.4«
ËÇÒ¬ô`o“L3T]\¿oó3!\X¸Š’İUÁ.5(ìXİ©Şb¯«ğ­ÁòRbgzÌ™õ>>OâlnÃ"it§éC–ìeIsbÃ>+äÂ¼l|R)nEî‡ò¬¢ƒJ¹Šö!™‹ex’l×Ss®BÒMãMšc’€åEîÊºƒæ–ï*Lp»1äÏk/Ìâ•Jºq+‰Ö;¬E"ÑF ‚ñZuPŞøı`ª½"—Œá¸´÷&=¦Œw4­ K ìøıÕ‡0#,í’·¨D)0ûK7Í¯ÄçÙ#`ôghÖ„ÙBÚ
ı¶t²F^³%8—Íw"Yš°cGÎ:Î¼†º0`”<¼0Ã•¦é+åyN\cƒ¯óŒ‚ø½AFm6ãÂhiùÙ3ı;¬²Íjg¶«á¹P%ßúµ@¨§ñÙ…ÿıË(çé;kBVXye¨ë‰Ãš^AÆp¦¶™º3¶ç^ë%êña<§qBŒ<š MÆÙfˆíä:h¡PàÀI F¡¡0Ï25£ 
¦Sà`±$¨~>¥l™N'=„'Eìy³0i+}Ÿ&&ÉF$n1Ší%æé¤_”Qü†/§{!Ä~‘%SÑ3Mä“¹¦O‚È;†*üùÎšérÛ.¢$-|¸“õ€,ª\“LQ¸€VÌ‰«Æº‡™¹	ë—³AŸîò›KŒ¯Ô;o8Y`†€¼äÖ92­ÒšèiİøÅ%Âb^Ü?çìÎoSÊå*/ıcq[œ³ğ.^óyà©£ûöÔê6Ï¨'(õwYO¾VN A·’Sõ#ê‡Ğæ¶.H•ujE­GYœX+`OÖ"_ég¤_K+şÊ,©;go›ğ‚¥$Ğ±ëÿdfbN®QP"A¦6^5ë8Bşˆ)bï­¢YrÈ-•G4dfù"ğ÷,[&êL(Ï†Õ}çj<¯2–¦ß–`õXŒ9ÄN;ä{ã¾tƒD*´KoTËõÎe¦*îRÀÒ !Û‚ËGù^©F?²p}çå
Q¬–á^KëÓk~CÉqä-%‘¬'Á8D)îwHû7[O¾¹oPä’<’nÃıp ‹;‚ª±şÊğr-îé¢¥¡ùˆ¦âŞLUØHñ£ÈçS¥TØ»Bƒ–Ù\º¬pÌ„şHJl¡¬£['5cáÕ$Íd×òÇ-”$—;#K)!Á&´ûå%im Oı/AÏry ÑceBİ&JZ&}wx@lkÈ3QëƒÚ$‚Òv¤Ş¶’ˆå{_"5ú!”W„—u“bş&˜ëöoÍÛ’)Ø«İ\ÕùÁQá:1½òÆOfôÜ@=D½Ï]%ä~ş
iûã«lc. ÏÈK¥ë››Ê±hÄ	qèP–øGÒOôäšPoÃn}†g	W’´®òQ¦ }«—S2ï˜]CE‘S#”èZ¬7† 3t#c¿y©´/Fr=Q\u­+T\Œ¸7w‚tİg¾t[ºªÃn'‰®Öş¹V K!ÑHë‹Ú¼hÔc*Ä-]½N»VïzY†
n†Âï*2Ë'Ír…A–YE›@Í†õÓãà
©^ı~–pf÷{ZêŒ³—yÄ¼ÀAÄl;hš²jl.™Ãèé+Ü´mn>ÊSÈÈ80g$ËMŒ™À&c÷h\¡ÀÏÒØnRIî×¦µ;Õ73¶!¸9ƒİHø;,C±ííÜy×5ŠØ¼	”åP6
òÏY¼Yš;øÏĞşŒğŸÍÉ`/Œı<øµmöyA´Ê¦5äñ»”!ôÀRô›I­ö®W¬ÿj›P"'é±æD™Ûyò`P¸¡J§®\+Ò>tH¢QğSªo:ö â’¢¡‚éQQO±a"Åzé¶>êğŸnÓìßºà_¤Ú¥ò;3Åßö­ªÄØ‚ÚĞÇ@
~ıòü-"AÚ}.QäûöÓ—¡Qçyç>aGr§%è]{¦MEH2¼üMZ°ym?Ì’\¡Ô°âÍ³ƒ‡õ:3CN»»Gçn]î…D	¬U­L~´Ô)—-ŸjpİeLD§ù£É°*1Arı|B©½T2)I³šÓ ğÜÛÃºÔ
¼ò·z\øÖr°¾äE"èˆí¶HAöûQçÔR69[˜çÊ<Èô4·\*—#«aoòKŸif®™şŠ²¥Û 	Œ“à6S\2N‚‚ƒ3g0)U$Å­ƒB]	4ÍŠÚgñÈoò^Xôwõ-$æü}¶|×6ò%Z¡„WgæEÁ„[MàsHÁĞÏÙdÎö·pWV%c"¢l¥%l{(ÅŞ‚óÇûÓñÂQ¼¿…¦Äæu)¹HÃ“_eùf^ûNù¸0B71 ü€‰)”ì!·W·|—ï1Ã~«ïÛ›B=nÿûxljÖ*óû Yã3Ö¿ú¤ßÚmzlùî±˜qÆÈ`ò¯”RY®ØCŞºá„îêKq‚Ëõ¶~šÏ£=¼Sôx*6S:šfC]<FEV~Şá#îır
x×`_¦KJ]ÁööŠãŞ§¹ïÖÄØg¹ÙOD¦±¶1²Ï[p]T†…!ßŠR&j7™[ë¥F¡×?99 ¢—„úHî$Œ:Wà 7ia5è2¡¨g,Ã[­ça{(¯xrg*Y¬c¥}Rç;•ºmI”O<Šn¨§CòLR¼ôØ:ıf‡ºÎ½²qş Ê‘ßÚä©‘&f?ªÔÁÊLæ~x¸a¶5 Ê¡`¯V™æ…hùt›væE|‡(Ş¾M§y$c.3%W^6¥•ÈÇ/ehş“|åÜÓı‚ßpv·ˆÇ9PbM«jo¨~ W«~Bñ¡Am‚—Ÿ$xò`î¼b‹Æ•k$ä‚9°Â/ğŒÅÁÁûvjSYflu-©–À„4Ô\½¬­Âàğ\õ·ù§«‡bŞ8´ãÅnQ>¿®oUR.<~  3íLNÇìÇÂ©~œüUÓP)á·7ÂÃ´~Ê»/)õX?¥]YqPÜ¯ÖWgãv$–Ÿ¼à‘q€á}mò¢=Æ{íeYp±<ÃÖpi´áŸ-‹A'O>oœIµ­{Tæ øOùrA¤Q~˜` Œ$Î²EvÖ2á°öIÀ:a%°ã£1"mé¹}&\Â*4fbŒ=u(—‘CK6ª°íZ¢°?÷å¯Û>ä·òÇ÷ªe®“_W†“•M“œŞî»îí±'ŒÖ*’$yñ.dü¹ÂB—ñ˜Fší$5üàpœõ~–)ùùƒ"nJCÂ?û»%“‘²¢Nd½ ¯•pÌÊ'ôÃßJØ®«7Ê¸½6ˆ5¯z²”ã_&ë•„!iÃZ
ª©‰í3+æ$¬Öó¤#¹	S-ÈĞzz²¦JyGî\å•pIÏGˆ›ÔKAÅóıTvz¢Õ=™šm‰-™§~Ä¾OìÂ‹Á—Ä«÷Wd¡æ¶Æ,ÅºŒ¨V8Ñ
yy‚–)ÕŒôG²8hÇçÑ8Ìã~šK*’2ì0£œ‚ÎóÎ!˜r­¨‚öÀéG'(;~ä‡é·‘ÂÔRTÿŒóóß¤ÿÄŞj{`!Aî-õ»±ùÁ-Š;+@Aÿy^Å¥Êe0x—gRÙu~JÖø }y.¹.¤£’ÑfsÍ—†¦Ÿ¤™DóÛãk½5ş
áÛ¤çï¶«jÍ©Éêå˜È¬ŒiP‰ÿqG¯‡¢;ÏqKtû÷»bKS¾¦Ú%t)s}×%Çò jSíÄŒ& À&.—/‡iod‡â:=³vŞ!ú_bÃ…Ì%åö*ÌÑ¾Û‚@-20`îAO:­í)“îBû±äûëoŸù’º˜ Ÿ„ÒŞ|°´~ÕSË7æ°Óê~A¡¿HzøÕˆä´šÅ¹†Îà"Î´ìİİ,ø1ş(^Ÿ­ÎÆ)Ô0s2.v`»A´—Z}4İö£
_Ln¡ñ8V\ÿtvBG±68•%ÀŒ[½àƒ5†’Ñ“i|W¯ş!×£×Xú'VºYà\ÑäÛ5m~öş—~ñödøéWŞ2Wi»'ê›ğ)£áœÓ¶Ÿ‹ÆÆpL«oB6ĞTÛ±eC¹©Ğæz•Ñ¤xèŒ'µb4T¼î#wèmŸŞWó‰²ç”ö¶-Åœ+MÒ7!Ñï(d£¡ cê-{]É‡ÌXY.¼İÂAÂ -Äú›—kb ¼ë.}‰k;Â™Ó¢Hó,İ »¼ÃhúÎ¨{Ò01“zjzæÌo!âpÆµªÌÄCjMuÊ%àÂ©j˜Ï.=îläæ•ˆ‚’‰+[!Ì´Q¯h/æ}K!n¨
Ş8I.„!a¹0‘[Á­i3åõai®+óór_Å?OüÒs}š{|»´oÀy™[Ñ‡'í–`Ñún«ÚYŒT.H	qàõ9…³4Á•Y×é3 ´”¶s-Ïúx’ãzİ/]ˆrŠw,&½ıèh İ‹A	!‹âGçkA¦>ópÈ“|ø÷bŒôğœÏ~¡ëÃÄ=µ0¨øÍ¦Åm°ç"ıÊúãœ=â8ŠãSB>ƒĞ#%¹Ä¯ºöpFœa³Û¹ó™®XÚäîÑòY¥'¹…ëı;â¼{JMÉ…%ä™°MäôòcÑónıE¼´ŸÕ={‡Ò5 áıß:K®”P`s¬ƒÈ6ÕÜM+|£”ÖsÅ´¨²À|­=ÁÙíxè"¸(ÈÖIıùÁ¹ëñFäëêv—{Øo4Z7:P5é ‘	XsVÆ¬ÀhYdîO!rŸí;ğ‚yèÔ˜<H¬¡|fi‘D"÷Š¥[[¦Œ‹øŒ{Äln¥&Š2ûğhA–´|uÿ¥	Ya`èeúB+„“Ã/*©åşLLGvep3²™*¤”,ú ®YÚÅO:AxT-¢hiTĞ|¼Ë7ôCÔ a‚ãĞœ;¦q"o‚H‚<£]UM‰$e%dŸ?$¢ò¬\÷zìkWgz”¸ÖMŞ>Ôl75Zÿ„¨,/êµŸ.”ßd¢cc|ØşŠVää‰şË%iØ°4ô–ÖB‹è!/âÄ ÑY„q‚™gÇFşl$”
]Òd Ù#÷*pÈ®µèÔQñD¤äòÈë–UcF„käôg»)ô\a2RÏ_ÖàtÍËÏKBQäxÇïaË­Íq¡ôÿìî”€/cwO.ü­‡h7V˜Ÿğíş×¨ôD¡GÁ­«0›ós{ 
ÈåS*úNÃô¸-ÆMTînû*FŠ?lÌ•-W\Ì6Í6­˜ê–!ä€È®¯nl·ÏŸÃ¦Ç$Pxäßö^ş¥Şïş:Mx‡.)Á?ˆûL§5Œ+tÒ¯š]ÊYoµÓ­õ«oÈ¡¢é°Ÿ|Üßš®¡¥®ÓŞí/ö’<¨Öt$Â¡%ƒY4PÂşÀE+ß~šñ²ºÌ"-éSÂ;XàíŸƒ>r¸‹#ÉŞˆH÷CWFÎñ…’ºé’´>4áæ3èò¿›ÅY‚l×JJívU„„¢[şÔ!L^†ˆÌ§bMäÆêÔ}_ÃBÅU4oóC.õ‹	Ø(hµ÷üúäìYÒmÏ.Eİÿğƒ·.6ğ±›/Ûèßî«òpy…Èæ¨g¨n§iw¦Í¹×ÉüVA”)~¶ÒÃV-}É£¬º2§^rQ”ÎöÿÈèÊ?ª1ˆì+…%!{¦[)ú­dÊ/J/}ÇXÍA¶ŸÏğÃÙ¼1Èbò}{$á±hhO6(¶Ë²w_ŠŠ~ô1*X_¶7Ñ,*Ùáºyœgºäx¥.¦ÑtI~<
‘Á>Ğ(J½±}m[ï¾`­PÂµMR™ò¼_¨+ÉÖa¦ôN79‚W1Â6áx|uI»ëâºªfäEì|ú¿#¾Ô€eC=îv“„¢Ë³ÓQgVRL²ª+ïğ`²vÌ*l¯Qšÿ®1ƒM1­3çâ´Àóü¼ÿÓ&ÄFR¶«X¦qÏøÀÔ&`Wo:	ß¾@G°bq¬“cÃ4L‚ïSm	¤H[˜Á¡İ•Y
ôön¿ÀsMyËó³yUJìVL,5¸Íõ8Ğ .úÛó–ê”ƒÎ¶šcÜ2ƒ&·tnêÒAW¦“ÏedTŞ¯ìâ—½H²y”óİî©k¶éŞš!Ü£Ö)%rnäkRË%¾À´s
~tl£–°Š$æaeé'æom—}¤aÑNÁwãw¸áÉüğÁ¾eÒO5L¯ìåPF4È’Ê–A‰³€ĞYä³š°Kze|ŠÈ•÷Îºª$UñØé†?\C2\k@ëyœÖéò×È-I{–Î9ZP	ë Û¿Ï2ÌX”DLOw”ğp9ŸœÏx¶I‰’,{1•|¼hğØ…@RøYSö‡Ô@@öÎãÑúƒÂ)ŒBaÔXO0â@œ6yÁµ4äukË)Gª…jõúg#<^ÓgRq—dkˆÓFeöwFºl5J/î#¨HJ`f7§¢W”µ‘AŸ+î«ÚõµÚÕD#íæcN$Õ@½Ã3f—©7ÙqK´~7.¸LÑ@c¨XY¤­R(MŒ}0£`®•-ó`ü4–ïïâ(RQK•_åë²…NsRQ,Ølÿl>Š¢^„û†Nfe5°aR0o¸t?<§ÉG$ĞáàBjÑdÀGÛ0™øøçƒ6ë’üÀİ²Â~7]ùvÓG69ò+-¯èH¨iG¹§¿Sœ×wÀ)É|€$™”ŸgXK‡ÎÛù¢‡Äú°æ,ˆä.£v‹.Æ7Õ|İÓ«³Óèu‚$[\4’¿ç˜µ¢÷N	 j"û¿ğdƒgµTtÂ´–m`0..×â¹œHØË·w&úµA^ğŞyQGZ›} g¹rŒ*—‘i¯±ÇMäÇ°ß)X¶ÀM›¾Z]òéŸŸêz­ç`<‡Y©,lhr…^*â«: úÄuËP§üÒÁ]¸?Ù°
lF‘8œ[’BÒ}¸+=~í„cu&b‹ä
éG:¢áCzã•‚†FÄó›Í¦Ô}Ú7‰P•P/óŠ…òæ®#{¯›!HÎÜ‘à›€­¯{gK°™¶´r¨†€tCƒªYãC[ÈŸpu±õÖ¦¯Øpl‰26¶|| |ñXe
–»Nê›¦–¶ÒÙY½šFd¸¸ßyÃêÅ &Óápßr`LöÃë¤Š·ã…åÿDİÍ…Ÿ¹`ØşHÌ…#¦›úåÊrÆ*–ÄÒši%éà©‡Sx=(1{í÷±â²Y)ÿŞJ½¯ÓÑz&jÛ£—ÌØ&ü‡’êa´e	ÿH†GvÉÒ£‰’8Ïöß•Ş.:’>>"#½>Úô\´÷ÆüfÅ/IK>1<—ÑºŠN”šU,š?¿Ş!§Pñ±L^S‹Ò1ÆF¹g‚‹,	gB¶åúÆ—İc`Iª;v¸óÇ B>HÎ9Ğú}8Úz7yQt ·J†rõ'"±3Î¸V±ä4<°Ó(/¸ñ±iÊƒ¢f­x‡±Áé:^¼¹şN˜+T¡šÇI:Å‡V›\i¥æ´}*¢Şú&É¤øœú>…À"2…OúíïÊÒ6ŒˆÜâx}¥õ˜Fãÿv2"œ”f¾ädm–$Ï7ˆÌI)lë±ìDâMñÙ6r–VGÉa¹§ŒÄëÏoøU¯P†É³ú¦Öø¼ı§y-1±+X§4Ûâ–†rùÇKˆÀ£Œ¹×ë.:í+œ Í 	èqC10Û˜9¢*'§‚[Hš\ÔT­ğsƒ¾YBœº
Ñ\‡`?¼"r~Køß´ASÃyÌÉÀs0Ô@˜›>n6vşˆ‹©½í1¥Çl+ªåÁNIıûÏ¼&ah<Eé¼İïñ’­çG×&)©ÈÕšmŸZ>7kp~z¨ñzööYî>úK(sVN	v^.şaYŒÇÇëÂ®Øj[Ü#ZÔKò.NÖñvŠkáœ­NË|`1¢6õK¦r,ôÉbn™	9ZVÇævW‚Éh	”ŞL+1{³ËŒÏ$úœÅv’ ô–uçq³ûã³vRMë¢¢!9ùºËsÎHØÒ—ğsQëÙrÏ¯¯ì= |Ë0_íY-¯XÆĞ–ü"‹ëPîSÅ“²…z]µ‚¨˜Ñ›¶ë±˜“:ô3xN@‰ğ}k#/9QonŠ˜â­z„Ê!
ÓÒ‚áãîŒ‚{T'Æ?©JLmWw8¿ùZ;ĞV"W‚A¹…šÍ¿YTm1úÌOÄñ[U°Ãèpe24ğ{ä$§Óİ…<øÛ	}+cêK¾¼gM»ÈK518¿
@1ÎÜè’šú³Ì×ü¤µıø½†ÂU×ãp·z2`|[ärà9YQC½)Á`H¨$‰İW•jºWÄË ,óÙ€ğ#égqéŸP%[ù/	r*¬ ¨m©/TĞ'ğªÆjN‘àÛg%€v»¿¸ôx}T®ö­Ğ‡÷]]OĞzÊ;üîÌ=Íºµô7Uh­ø”[¶€ôß»ÛljĞ$ˆÏß(Å.‘ÈHIït[á\/4F&NÑ5Sæé=Ædğ·èZŒŸÜå%}ôÁ”ŒA€ì”;HE“:1¾!”¹_Ø©Ôd˜K—í’+Ó˜ ¯x(	€"ëîOj A¶8¡9uræ§©ÕíãËm¸W‡ú"0áa ßYª§u™+Ğ»d~ú")3 ŒL»ÇÄFÁ‰|„-Gòë-À)¯s|M1zÒŞ	!™Šhİb­Q¿ ”(vã@‡Àú[’Æ71úÔ9›{»Ä3üÖĞûA¾Ö¹„1	9{fã>—ËØ	•µz˜vç…Òk0b¿æhÈRIëÛoŒOõµk(ÌÀ|7/¢Ò°p¶ŠCÆŸFÓ®*Å/ùNí8(K7„æ[_*<4¹¦¶<İ6Wt§SŸä°.¤ŠÍØm© ™ØI(¶T\=óÒÜ«˜
Zf.€“áWÓKÏö/ÜwéR¸&ÅB•µ‹¯45®¢éØ“É•a‚jÔã@jK ÿÑ‘ØıûÀ ˜Ç•èT²³ca£õùYÎ(<MÍ¤¯ÁÒÖÙ4ïÖŠ/^LF®âÙÏ—=›†¨B¤lü`CµHš„ c~|Üq?ë=t—)çgz¬SH\?HÎ[|Hí”*çˆ}ÖÇ£wô[Ù=›EtUŠl_z{{$D®ë|–±lZpâe9·î@O¬ç)á‹élÁ.óŠ?È‚â÷uL¸ÄXGÄH‰Ğøl¸÷'ê²÷9XüÿÍ/ŠÅ× ¼•LåíRòÊğr~
”Íƒ3£‹ĞÏy½™µŠç¡Èv*İÚ˜*©Ì›İJXåç½üxjpŞ»({-æ1~h`<>'Xç ¾§7WHXôªyê¹§Kğ-¶ßj#×œÕ§Ÿ†dsàv"¼§=—„F«ú/8µàyÓïq¿n1ŒóÂƒÒô$~ĞcVÜÍ×ƒõ½õÙQ®ñX–Áá’è}­#hÕåéÄUNÑ0™½(¦M‘Fz°±-Ç†4&j\áèäìu½O¨L8-ĞR`VnØÆ~û×1èÉP
ˆ³½\¾p¼Y~ÑõD½pÙÛ˜<(9ì»ã»¸¼É¾ÆF®0ìÒ—µƒ1Ò'¤{t2.œâ\ÑS€ƒe·ø‹Ö–+Ğé]Ôm#ÿz¯ŞAHK˜b‚È~'¸`+´PÉşÊ¡Í”a‡aL¾‹x™Ï…‡!Ï—Q—õ äW{Úô7ÕM=ÿüÁeR‘%ÎÆ¡°Æc©2RaALÏº5ô !NKˆ~+’ágÆ»F÷Š2EóbãgV©ıÑÿR%0qˆO©ÊYÿ6? ¶çû¬d$ •šŞàj5ƒø¼™Ê$éR¯ê¤—‰Zp®„ÓFö'ÊçuÄƒÀO-ÙFE3¨t{JNÒ4gõËöÔv5¾y˜Ì 2oN°¿Áó’V<–>:5_¿gÍU’q”§j?Ô5©NN¢Ó ĞÖãĞ¿P¹|¡dK'a„2¬$€ƒëP7ÚcááKzA1–âEÚ;s{7ê1\ûI¶Û—Ê$Ê£ÜN<=F¡§Ïï×‹à¤·ß ¶]¾4Nv+¡)æŸö«Dœ:Äë)ZÄ›¶Ë$ÇGè‡¯Óí£ñãH2H¯¥
fşÇ‘j«¤Šm2¸Z˜€Ç%TøŒK[»0€çê%~9§´¶*È¼hzJl êIè[‘$/ıW¥{¨[ÎWBLÊSôÃ«š—°Wí—#½¤vƒíFëÄªşJ‘,¸¥g˜qĞÁƒí±<A.ŠÆK­^f ª&'®˜¤œ3=O™N®£/Æ5zQ[/¿=n¥s¤&jß¥tËCZ³ˆ`W¹a»ğ¹'Wbø	Ä@èøm@RÉ½mÕ2Ø0œE•äÒ#™6|gôCC°Ö~x ínfôS¯läøèh+Ğ§DÈ³¹ì]ÃuèaGÇu%8zÇ¡¤ciQ‘‚vàÀë{¦ÖÀıeJaç“Ğá¦)¯4aÖöÂ%Ğzm8q®ü.W«2¤ÌéY–~q¨ÆkğWÔ“:ì@¢òƒ·s?ó?¦~^"úLv-ËJN·iIK	¥)%_,V¿o±ÌİÇÕˆÏ@í&ÄqYH¦İ©0üX &2¶ÜŞY‹k$dÎ¡/Å¸`E«©uĞyH¹y–¦ós$fAÔ?›Á…JÔW—*0ä—ÁU½l¸ºÃ1«\,½¶Úğª´gñVåÍ^y¦R³
FŒ“ù<ÿ9™´¾•ùş§œÑƒ’s=[å=(6/´[Ñ””“¼¹a?'Sk<oá),jXœ‰Jşl ÿ)¢“(šÂ‡Ú±Ü·aŞYÀ/—yÖ€ğ”GãLYÕn±5[‰@Ì§üv}Ğ¸’Á{”}âØ ì’g<•A&½M} ¬¬ŞN+…’ëä7áxê,ı_u:Üš, ÿæÙóŞ€•5¶E¼ñeşfi,ÙêiuıÒê©=3W­Ñ$!åŠo¼şÏEŸßä"µœz@FJÌ–A¸¿ÃP”†–7å‹ëmD(¼lş<¬uÈ™rcŸ{rl¸»ñ;xO˜qê¥LWÔÏ3“ç¶OR3‡r dÑGZ{èÅ1Zç+`BŞ¤Å*Ÿ)D”óå|Bµ.…nk2íÀ›Ÿ1â¡(à$}!Óq{I¤Àpu/Õ=8ËfMÈË’«g‹ƒ[`X°Iëb\.2Ey#º!M –%á|ÉÇVÓÉòPŸ7T5X´Œ1ÄOìØ‹ä/S¿:|ùÜ˜é[¡İ+¢Ü<Úˆ¾z­·Áñ+3Å´ŠIIŠd¬BBÔå±8Ğr9+æ¾ày\–¸øOFÏ2×T<sæµX>Hó‡Gl §y„Í¶Š³†ƒœ#?2¡ã÷Ó•Á¡-Ùo»«§+Æ…fe»¾Çõ¿úfíAÆ:¡«Šms4j°÷pÚZWq+uXgµæà¹#QIÎ¸ à@‰ê0¯ùR5w7ºÛgõšqPPÍ6Î=/Ñ§OK?ÛÅ¡j¢ƒ‘÷®g¨ıä}¡¡»H?‹>ÙÍ".FŒL›Ô}°óC	ÒÚ7gtow‰¬Ä¿¥éÈw	1–Ó”u‡5eÿ8U%„#±Âråj- ¥1>€Í„|»¢–O×8Ì°ÄPÁ¢"ü+ÙÌÆ<½\òÁG| ‚ş2;,%*°e½•074r6K\øˆcwrtc{ÓÈ9h~9â€Ÿõ²&?ÃˆpÅíR—]–ûz¡`Ø!ËÃİƒ«?CŠ…Q}?Õê«q1|Ï$]÷QØe²ïgùğ&_m4ªÑá"Nû¢æŒû:`q\‡ãµÊù!©‡Ó±gæ¥{£öU#{Ìl'” ”ûÚK¿îiPìız,Õ½µ|roš¶çyw¹Õ@²Ä"D‰°‘ÿe/é¥±“]şjaë÷#úÿ·È4×ÌèmË«÷1
ã\ûFƒşò¹†Yòbt{|~	åä,]fÓEÚzUI•ØıNmÑòL@3'ë¾ |ZBµlc
‡‘ú+&ŠIB¾¶zlş
¶İ1|¥J<RËÅ)o‡ÌöÚoÏ«¥7üÌÃ4^Nkü&Ün¶Ñx&ÒóëñïÛICbm„ ñ#ã08ƒ!¾›Hrè0uî-‡C˜•¸|`û7¦×i`ÊÄåR_šRİ;Òû©™åIÂGÛL†¦
Ò’üF÷12|ÖeÀ7a¢+óxÍ
­’«%^|¿hå„ ë¹05oõL¾²oñŞl•ëmœè÷Jîgÿ.F¥7¾<.õÜıx^HÀˆ]¼™qT¯eß,ÔšwìØ¥Vá²_˜¥›~ŞE ÿËowîºÖÖ{‘Ø-T[íwğôìµ`×d.€Iª~lEÁQ§qnÄ<YmßüÙÖ©š¦Ä·Y
òÓ¹"ãƒˆ©µº4Ãß¡ªƒNyÍ±Làiv {çázñes'psØ·•;QT+Æ‹F,-—Cé÷Ó‡K@WS¤Ó!ı´Üš…jü0*´¦‘KŞ#¿§8z”™ë£¿Âğ‘U'õØ«&êù®›Êxz×™'xÖÁØí$.Ì’’ín¡ôKHwOË
@g`$R'51PÀó#0ëÔÛ¶ŠjÒâyÑ¢y¨¢vj#*L•Íò‚4fRQ-<é\·g‹£}@¹p1ß[?è6¢q½5E‘ûĞ´ÎrMUş›vt<â¯¼®ş“ïw-ùßàş#b“È·oí»‚E&ÄB8=è­ÈáîÛ¯ÏßÇ}³*#·ò~ÑÜÓê5–¡ëçßéìËNË>ih°„¦gVNa¨ôlò…'¹ *-RNĞƒÛ\ÇkààÜ&¿P‚›!~yu¼‰tzíú1¯¦‘úìé/Å=$Mãk:•§¨Î[±LBôqŒÛøèöJ¶}åŠmq¤ƒ¼§D¯øüë×”‘Pê²-ıÔóˆ]{İµ'ğçKn		Rµ÷3c –»E#Ô}n³Û½w“+ƒz²Q-Ÿ…%­Ñª‡½Ï\Q¦¤á¤ÒQ4Çğ]KSEôE‰sÏà®¡5:uÖXG·vu£\Z‰ªœA›ùk§}?òÈı^ÅUg¨$yœçË0ƒ24;<ğf;7Q…uİŒä³¶›§,3soÒÏÔñù¡Æ¼1 °^`¶eB·ñ¤ÃqMô0AÁ¥Íåó^ZÉQŒ
 ŠqItÂL-:lw%>êH³5ìê%ìiQ\?»éJ¡~;|Æó¡˜O®ß%ŠDˆá[ÛñYçŒqQë»¨ô,¦œX§MœÕ³’6éŸŠ/Xÿ™ìäì”ÔÆRkªÆ#Ùû€•ìUç£êöÇ7AP=ÍfF*?ƒÈ·YR4óYŞxw-Éfói£Fùn#ø_Ã/&YÿûÿDZZ5K4ûm»‚hc[uÎ0Ãå—§EM	d„ë#eRø_cÃøhmuÉ¯aÏd[ Î6X; E0Œœ8E¹ù‚¤µÌK¢õ%–0·¨4Y=h¯ÑŠ’µh4+ßÄ;=ò¡à¸/ù›]„hë`LME£0YÙ±Q­6
\0…J×3knèAñŠàĞUkp5«läV5ÌíLææ2 ó}UÕZF›‘°6q’ŒûVJà(7§À³ùô¤˜m¯¹â!jw™ˆœÒ³LÎËa½5>9‘G»x|·‰"·&·îŠ%IÀÇ¦SÇ;…K«u”EÛ'0L}Qâ¨50Ó¬
%¨Î"H÷ÉËà‰SÆ'¿p!‚
´èÈ%{”6+YòÛå™ÛÄ•Ô/í3Ê"AZşƒlND³núIfÜXcwosÁ£³…1ôõsÍzß†‚}Õ]êe=RHq?C$x‹aÚ #×›İ®©4ê÷m¥¯¶…•2ğ/:æ¹”,°dñŞŒşNùŠMœA‚‰´¯t|gÔÃ·*Ï:'G^	Ã#²‡İW©«é®ç³Ûöµp«€°âª§n4M<jún”æmÀ•ÂRÿĞÔ,#–4íwœ°7æ:SCÓ¢H™½&Ww'¿R°,¢¶EºxYíÎ®õ{~ió/-enwµ‘j_$ûjŸtÒgı4•;Ñ°p2¹—òå\Qv¥¢OÊ@j5’L|ìı“Ã¹Í{çSZãì„ô}U÷ÌZ<íÆ‹@DÕä=7Ÿ|`çG<i”ºÆTx‡c–u~íÛÀîº‡òÌ’> \”ùÿTZC‰Ç{€«ãUkKi2a¤éX®›+zPYœ±bÒeh	ÿ—ÿSCŠÀãfã9 ñÎ­‚Ga}™ ÿYcu¶]éó~ôk­«O<v}ˆpû«·Í™b´æÙTPÀRÓKĞÚ¿ŞN«iyíz`>Ã÷†írÖ’KÍÙìuÏ³-±D£‚ÕÉ]ÍC+èƒ4ÁÿDì˜†¶æ.,QgµØ»•Jc­æÉ…p`^É‚ïßˆlõlÊ9Ç‚#£TÊÑ\È¦Q Uô=Câ9Î #7Afvü¦²n}¢ø>-!ÄÎsA°ë‹ZIšÁ¨H0Œ'”ÃÈgØ±jÚÙ…ÂôzÒ(3YlÔÅ‡Èİn»A¶ñ*KÁÏÅ}4-¿5•ü`ÃfÄy]­÷/ÄPÉö}a¥U‘ƒ[ıßÓ«Rìª®“?·?—úî´“Å«£—í,ô$ª|Ç&Ö·»×ƒò.£CUôÜ‹>`Ø¢v—Gaõùú¶eKÆ>u>ÕåU#á¶öÚ´Æ}(mÇ:„Š_‡u½-¥/@›-^«- çA,RI8[ÑyyÕÅÕøQcœšØW­ªú®X	g…t}ùãG­ğNrrT´~ˆ>*@ Ãƒw­Ä·XàCBú¶gâTã†o’o%#Ú|e¼uäîL`¡ªVB~:öc	ˆošœ–`åoíØşÑ8"ğÏÚ8ã-k¬Õ Ü…¬ÍZÚTwÛ¤ŞNãNˆc±î¶åÎ®-®&ˆì<^Cı<üƒs4i&xŸıu™I˜à#W3†Âã³¬wø©õôyfĞnàAŸbõûs1\)ß>Æ¯ı–‘!N@ˆƒnœß’"Ü­•u›´Ãê_l±@&é	‘> ËSonœK¼œëPÉXÌŞ”ƒu×½"¹$QÇ\èB·'–+£gÏò`¿©‡&’ßÆŒ~³A4ƒ³¶àØ€Œ;a(Cèö—´”‘2#ˆj– ÷›Àm¡@÷š;(ªStUÅ7¥#~CC³€$¡k}Êz­â@Ô	!üË«ƒ/qlk°®®)=O¡Ÿ°r¸æ3&^Z:i.qU(.4fü„ÔÃëÄL\÷¥Ô\ë‚ÄYşÀ¿q@±ÕºtÏÓAüd¬¥€¦Ğj¡ÊHµoÂ…* °|ìkœ½¥B:‚–«ëÌzØ”öÀ™íâS1?ó5gÀ£WI¬ÇU$¼º^sàÙ:P™© I}j5ÓÒş)°$ŒÒ\¤pÚº±ÔüD\†—BÛ{ì1oÇîw”%°%{_“PŸ¥O¿ßRÉ‰ßğ£ã8®»Û±P¸CËÎL¶æâ2SdZ0Ñ¾Cã©š"¦ÛÂ,Wñù‰ŸËmaÕØc¾,*ü4R×¼MsÍãv^æÁ¼¥fß?"\ú `qşÒ.wrùQ#Wqš$v¸¯K[»P^›¤¥ĞT. Vö‡0ùv`Ëfg‹L?t™fÇ´&Ôefš]©ïaÄSšÉ¨zgÙå†v `i{#5ş²zÜë} t ‘dÿn¥³…˜90AÃ?àİÍ5ÿ'étÂ·æ»”M×±Ëáö¬Òôi¢Ò@BşT,ŸeÈï!ÊÑâ•Õ‰v+Ä5ì*µ‰ş²ûoş3YZlı_ú<ìèìm’uŠnWª"£Ï—Ğ)üå	ó¹åª0`¦8ŞÁŸ›÷â™!Iˆ^
Z1¼Å÷&»ı2Å0ô–øùd=ÎÉèÁ…ßw²w+£ÿûªèÃËOútí¼îú&9Û§À_/º …ßiñ3¤d&QªëòôPJUlŠ_•g'Fs)Jˆi®®¨)hê~ú\Qâ[É<,ôÚîXû
_ÔMî¥7'ĞÃ€”OF ÂÚá¬¢ÉÕ÷[~Î¤Ä-9¯!ªœ!_­GxAYÿœÅôÊÍ,)¨9ºîÓÂ¤‡™ô¼™ ~-+Òõ²`0¦Oø¤¹ò5ÑS´WºÀ©;©ÂV3$®A)XŠÈ¡É´ğS”­Ræ[EóuÓ–C¥MÖ!­-şŒag±æ=@.QÚ«›E3¦ï Ø›¬›sÔÓläÉ}zwY×_ÔÙR²ËÏĞ8pÚ¥©(ßŞ³ĞMÆìëà5ÁŸ\èl‡„é(,\@\‰™üÓˆ©ÈK9f.†vfàPË²ÔßŒ9¿£ç’=uÂô~Æ¤ôÇıº`õEjES¤5å!8ÕÖÖÁEâÊV(ÿRlaÑ\1‡wñ “ùµ=-sâOåøêÆUPóùÙœ€ßYûöÌ{1[ÃEĞL²TM ÅØ$IÕÍ~nA‹ş–5õ;ÅRˆl‡î“Aƒ9Q7ŠğuOÚË b4šÇ<iC^³¢®~Ê2å’JaKDß: d” .‘çÚ°"¿ ÉØı¶>¼Mõ»éµŸÓ—¨WèNŒ$ï5^¼|}=tjİ½ NÂ2~ö®AŠ…a$k1âÁƒw/%V´s@×õ¨i‘TQ m(Bëbw€iÆ“ùx²ÛA¸oQ²¹BTxÍö¥•qN£€	Ò9rl?á;ì^xlGÉùPmÕ‹=e‹OÊc4=ÔÅ¬}#~¯íÒ4…©l,ÁŠøâ+3¿œŸ­ËsŠÚ²L@/x…{ŠˆËnœe½ºç&æÖ2âÂ/G^Ck‘¤GyİRM\æC¹ä¨ô‚õÔtñ½9Áµ™†¡€òŞ2–Ş.™³Ì.iÃß[vyõo<˜ÀEïŠ°‰<à•ş‰•£ûµÖ!ºLìËõnêŠ;¥mÆJÆã¸Úş=]ì©zóüåt­9·¬säE©˜!ZÏ‰T\7˜ÏÊÒçğ¦ZÔ™Pîò#aÍ£El ,ùïİĞ#==À“1µJu‘‡Æïò>ª©âû‚æ6èZV0g“»²i@‡% »Éƒ­ĞY­V,Ò°2ësæY!‰m—…ŞgXcì­€ûÂ™Î™ÄŠObX¯‹İ'/o¨Û!NVTÅ1†xx‚bF2æ0¾Ÿ68-hÙ7< ÒÎN«ÌCym~‚ò9Êù®ôcm\Û°ÈïNö[ ÷>ğ±…¾o¨fñÀi¯ÊüÛWªò÷Ñ-u^H[Sm<'bq,µ‡Ä}XGB,
óÑ-ğU®«foiã²à¶¼AvÄ}†%yÌR¯b’í¯é¤?&å:¶ÁtÔ“`¡2>ôXK¿:½V¸µ:QÆ+hQ>Ú&h% ªëzO·rE·åqUŸ’#4	—¿šÙ¨şº÷C³dõüLî…E3¤ÁzyOÅøî:&qÖŒ/úG1ÓO$º5wü$œné?üP£X½¹ëÁ>%a÷^Ï3Š£q)CÈ‡F±x4‰Ü“úâ1øl†9 ğÅ7%ÄU~i‰Î‡»±	,µCùvX?ˆ~%¤×5"ÄláF_ñşİ½alºS6û`À•=’‘A»MŞrwÿÖD³ã"}šwúöuÂÕîx³`3ƒÜÆ1¢«¿Á”9¾zÇ‘/õYé‚ZÀš©É9¶÷¡¤¸ÿn=zAwGõïêì¥Ï•2·óqsô):˜Ÿ:Øú©¹ˆ¾§`æ‹ Îc”ªa¯:{ÅÕ…Ûœ5³}ªUíªZÖí|r7ÎÇvëjÆ½¾¿á=¥{ZÀ†^ø¯eq«Ñ-Ä¶×óßd´|Wñ¹éíÒM²ĞP6vİªpÒ÷Ø=y«{ñ}Ö½˜×W‡®ı.qÑ	wñ!ô“¯Œ{\7Y<È®\ü¤{$v4œ~×ÜØEº–x×`Òª ~CêCçô^
i½ÇÑrØîYÑ*
À~¢úbXùHÈS…ÍSMlŞŠ8ñî¿íÑ¶K'äôdÎaõE+‡Ë’	QK^6^·:Ü*!ŸÁ*}Œq ) í½!;»˜³j76ÌÍ°§o.ä”xë‚õ‡(¨ïvµ›Zç`~¼¯ @=IeXÓf•A$rHIĞ›T”•nLÓ,A¾Šq/îıvZ0Id3¥0ÏfbÎLÕâ^õ·óÂúí3?U”Ä¡½\A˜íiÊ.r¨Ö©¬Ô7zµ*?€|wÛŠµâÒ©»¡	ÿ”O0™óÔyf»/4¯À-P
Ã¿„éo—ßÇšytUm¢‚l7¼9P_Ïò¥Øålª¬?$ÛÑ0qZ¹GìhOz÷YÏ~ú”pñwBÇä{FØ.¼u2N©ãŠè¦ç"Š!Ä3ÙÓJ¿©XKYj¢¨Hì¢ˆe=ï‹"Mì#Mç—ÍÂ·‰geC›×ò£§µş_Y˜©	*¸šÁ‘Oh¿LÊİY(WÎ©d'ñß…4bœ–/ê*wA‡o„—mçnKİ¢x{i“¶üÓË¢ëò0·Äæêë¶,[Dñ­Ujyëšáóã_VH:ÖöÓ_Xõ—‹gª_Óz§âî&x›äGŒ‚OHˆ´”­'OÏĞs™b¥×,·Úßvî³^bÙ]£ıİ’5îtócU.èø¸–ÿ!Á¿(V­>jÙùV		PÓ|.ÏQoZUT–×C={Õ$¦å©âìÆN‚Rô@
¯B «8Âódù  k¾ëèOQBÒ¿Ïõ+†×°[æše’ÃP½{…Ó?‹9]RQZ/ÍÈ²Ü;I¹×s†ÛĞæH…ç=†µ¥ÌwšÎ}MŠ'§Æ)*¾»İ¤üóÜÇü	Ûkd9[‡Nyò:œ £¾—M&X½($e^ENV¶˜ŠÛ$Ö¿[ørtáYÒbòî/ŠX,Ä¡úß~U42Ÿ•i´¬6–ÍÂÂœ@Mq¸¤jñ³Íl… ã½ıºdJ@vænİ‘D\0&¹?nëòäŠNßºí„óUEáóV;|b»SLğšß0‰|6J@×9şˆ97T¹“APŠäËèR<k¥»¼@ø­<ıíÖFhğ¿J¹î=ö}<%¬u×Õ^ja2^ÀÄæÓ]âÂaCp±_ie"«|„uXØë—'ßo…÷§øª•];¤L˜Şôí|¢Úå0ÿäíL>½è,;m˜êèø°ˆ‹I¥?Kû×e+{Ë°›>‹ˆàÍhÜ–†¨›Ö¥ûË˜æFS¥“¦n·ÏÇš¸ncÿt,9½ÖÊ­¹¨éÙ†ÕkuÁÈt#‹(2¡&²Å÷9½p?Äì£#¹ãSİ³e“ÿ@\‡Ú”=
Unc­0äXC(6iÛ‘ŒŠ”É¾eÊ2òP[D-1û'öµ¢á%7&cÖÓRéfÀ1¾×ÓWuÖYÌhë±.#ek÷²Áš}kfi/R3h>í¶9ÂŸæï]€»Y…^¾4|–^¦"Ãg×X³ô”t¬h&`Zb¥İó²èW¸Ê´%BŠÛ…È¿.òÃc@òEÀÿYæÃ§w@¼35^
lƒòÂ-$œ£==İğ±áµëú˜§Ñ²ó^ÎŠ[Hkÿê`cæ,t`T*èPİjØùêT:S2××u¹3>ùTüÀA —b~{[u‡“ Ğ¢ÜèqIô÷ã)Ñq1’ç¹a¶šŠ’½ŒÅ4‘ÓR¾-« 1R.ßM:zÄãWBœâ§Æ7ÕÎµ¥|7y¨—÷Ì…ë‘Š?$aıºfg—Ùkº-M§bš§y Õ`>Wqı´÷ÎÆ•^`cäoû](È„(ŞZæã úÑWF °î¨„úbdFàĞzPİ8Â‡o€5æøÂÔ w„RÀ/I)/ÌƒÆlËœb1ÅEPHV	+¥Ø›M‘{õåLvbÛIŸÛ9Äæ^"–DY:tÉáF}»)F
*›S¯Â^ö‰ıÏlyš&bBÍcÁ:qœÓëÕ1ïî]¤$§³ÿ+p.IÄ¤@e HÊT‹j4qœİû9³™œ§qÿHÎÔ‹€ô¯ÑÙ ’Z“Ÿ¿saS„öu`*¼ŸºğøILM*ºˆ~e	9@/‡Yœ”¥²Ï®÷ò<Ø¢d¡†^aõ½Ûè=‹XÕ"÷.ŸIÏºü^­{Äï®ªÛÃ(œ‡ÔÂË…·-qú"ÉF{g³9*uIœRtqôh¸Ø²ûÃ]å
üáˆû¤ğN¥„¨éš96K­Hk«påğEzH :êÖ‰°Àqq`¼‹uä)£K83wÒW5ş¾ÄĞ{Qì>“	ÓÚ÷Ju0£|ó<Q£°èÁ%¸g)EŞšş¿(p<\—†&»3cäM‡ÃÁMÆP]aOáG"aİ8ïÃÕÛu\/z2mÁ[£S@Ñ“v_Q¥Á[JuÅWVï/íH:±"¿%9µ#»Õ÷—áu.çP“Â´Ó]©ÂÛ†MÃiäOûH²²ÒÆ-®B¡¢!Ì÷d©L‰Q¼Zö(Õ-•µXA¡zlĞWÏ<m¡5!Ş²ÖÀ“ß¹?[¨XP%S$K”JŠŞÏÌĞÌ$¥¦Ø¥^¶ÃÚı‚múË{!?…p°á÷?²Iñ˜U³× œòhbŸdkH: e½Ë•L”ÑˆúªwÚ/-zUL¶$zW[[ÓVÑw6Îmû9ÓiáÊÙ{šÉ_¤írC;>{,-t‰m4Ğ¦şÔoŠ4MŠwŞFä}İ`Ùêb¿³ó”¶KÖ9]?MÔ4$¤‹HøÇßCI[º·LZÓ¾ÈÃÄvHö®‚ xîqö5s¶Ùj’ócA}¥UÇ†÷ùNgÄÀï›@eU©ôäûÄŒÈN0ta	Íˆp¥Õˆˆ±±Cğ9ğ@dYt?´WI›A‰1]Fû	»,‚•§%¿QTAîÓv¨8å Ct'p¬¿ğg°ƒß¯ÇÁ¤¥=‘‹áèwV Øpü†bÂó2L»f	ÈMXÜâÖzW¦NaÆ,º¢  ÍX`šntŠs¿Ï¦°XØµŒ‹Lâú~ÃÜ¬_n^MßÒÃ"4FŠ®Z.9xîjÌÚ"Àï‰ Ğ‚§µØ:"Œ]Ù®øñ²é¢Å
§¼5	î(·ğ	]énÌV6 æ°FÂ^İ‰QÛÒE(Ÿ'tïgÜRà\ó·™­mg~¼Nòráå°˜J9!İ_,½ÓL¯0;ßÉJ¶š^àPGi óUÿèê<t®k‡„<éş_ùğ0Q¿55;:Ïõ½ÛIwKÑ–¨İøIúgvád‹¬¶*f„|k×#©r²ÎPµ ·j±ïäãˆÒŒEÛİ2ÓØÃV¸P8°Í}‰A}à&>z=‚C‡	ÉÚÎ¬ó×î%]É>h}­‡‡Ê‚Í1jc3Ãë\ù´¾BŞ¯ZbXD´	Lfß˜mqğ[{ÇEOŸ‘SYd¥‰ayí(Š2©ê¢Èñİc‚2kÌ&{¬L'ÿë~ÿÎN+}AL.-½fñÜU5¤ögÀd‘ˆómävzÖ˜ù>¼-.ñí`ŞŸ%'Â1˜'q¨òß Ş+ »dÂ×“I{èÅ”-×Øƒ@Xutÿİ‹˜2i`áiûë”ª‡İ6)zzUHvËİÍç0\ù)=Ò$Ä€ù@%R»³>M´6C¤T$d+óq˜e áÿ²NİÊ®Ø@u<;¶…ïÂm+÷©Ïn^E²hFbHd»ğJ§†Õ"#÷ƒŒÑªh„hÔ×ÿ¿Lz(·ôÊ_y£MÜÀ­7%ª°NÇ*¬çàM¼r95¨"š”É‚óŞ¾Ú3ıeVàÜ•gåyı30^ÜU°yÿ$˜çU^ö,‡s_óÁÑ©ùI¤+·D#Tià `xS$iøH¨ãÒ’ä$vÁ™ÃÏªº{½ª³ÚiXˆ±ÓÚÊ‘>6NOæììªİJ°WCÌµr“’ü•Ì%ÌµXİ¬,&¼@şº6ïnW]z-ÃƒgwF€‘ª‘šhÌ¿5‘.KJyî$ S¿S~Ì˜)ÓÑÃ4%8‹6
9ÊL§/çATG€|XÜ§¤PÇ™Å ;CİÉÛYÔù°ü’°Û=ÌıÎoÆ¡¦‰ÖÜıaoƒ×"äoã¿öE§²‚ö¿r½ øPanÌH~ÿº0lüÄ³qi„`éÈÇˆTJ9°ŸpÑ7Ñ2aß{yÓ®uî€íÕW)rAÜ¼'=\…Œ©÷3…ûÄ·Ñ¢Ê¡ÒkÃÒéÆ²EÚÕdËİ»á¦ÏT¾˜±\Cyè£í“-±(öp×ª³^SÅ#ñÄÍ¿i;d6ï«–9ì®su(*;zW*I âS"‹PZê¯ÊTT)Àç[øi(\š "³xàÚhK}yœrÀª³&ªeM­°~”"eìØW{ÑÌà^W=q0Lå³f”çÉh0µ.#¿Ã:ñI
t š{€iÌPmù¥Ğ(eH
‚1yù1õ&X²úd>õ<k?üØşè%¥½[ÇŸ³ôet§o—ú[—ØD†óä¾?&íĞáp6s_Ü‡ªÏ®G¹‘°ì!ïÍ~G‹'±‘‚!Ö–á+½6ÌG<Š< òÚB8n«wªèÅ-ş¡ëÍ$	8´ßc=ÄÜ,•j§M°P@o'ÍşÚ¤jØáŒïŞÈ7Îô$¥YêŸy·2-¸õ7XÚ^'#–½Äf%‰Æ5§’+kH	!ÙÔğIO	ØQjÁjî³W»E‡Ä%iúŞ
÷_6kL+ŞğôT}Zm;‘<Ô0Ç·éyOw€1QD hì -üş»}«Úœ&Ò‡µW±{â^è5ÕDT•	•Éš†ÇS+ØÒpMß›Š“q¯öıíf×Wº´ÃÍËÈü²']²°F~Ìgè7v$Å
®¸jÿ·¢Vî;¤FÜfÿÊ’O u¦ñ³ÛU÷€&1·ëˆáÃ„!à}eE`\j^€Z.är°¸]BsáKñëS{;İ2kæÓâÜFÑHƒVøé%÷GwıJømT°°ÉM¦$=ó¼ÚUy[¶Š
‡a-mÖ|KUä5çÔÆ¥ÕÀÊr¨ká"¥&Ä×ĞDºÛ-B0Twúô~Û9ªpÀ7~èw•Ä‘^¢ë»ZtcËêÜí¦ø^·ÈOkS4‰"ª&3¡4E{§ö¡$‡™äëÅ [îegYuYºÓøÕ8ˆÀç8}Û·"4Ü¢‰!;TVÑÌY/~˜n–,ˆ:’5éUjº¥uƒ6…¢à=uc+geØ0ƒ€Û!ğÌ\îÏœRÊ ¿
ï¸wG%w¨œ¾qR¢&–Îï=!C`YØÑ°¸™bE¯õF]ò”»I­Ô>õ 
3\¯¡Îƒ1ğƒxÄel8!Dp½Ë-Ùùœ&šöÊˆ\$ÚŒ†™ÚµKw/c× ù-è5&’¿1Ëÿº+û_1,ıZJwˆÔ”ñqŒl’Ú0Í÷¬n§¦Ú^Ñ0cÖ/ò¶`ÖXë·(ƒFq/å‘G™Ï¥¥ó/¹3’sÙK6tç¤ÒÀ¦TÃ¾@Thif=+Lç}û‹^\ì|V*{ö–ôJ=õíş‰•; @}×Çóülÿ
ÕX»¦iüï-§ÅZá
×dä7Hä/«–×3G§•şoB=Aéw…²e}ÉÕlÂ¾ĞíqòD·Ìß^YŒ$£ôËT„%§Š+2¼Ao½ˆ¸.4zw+”Š§şB',o%uÍgòô@çÂ…tĞ@&bH‡çÖt¿ÍóªÑ¹¾ùÛ#FÔ©ÿ@àšÏônA—O{ä,€¸İËa;â#VÑU‘t°Dgãçq;Q"yˆ9~èJ¡%[	ˆÎ&o£¶+u¤k.w¸–@Ó®
Yn÷¾-‚ìò^Àv6Uv°¨Öí„ \‹MÙO©gÚò•ÁùPÄB4+Åá¤©“ªÃ=%‰¶¯Ó™²›ÖA@O”9á×óVÃ]¹nRgrĞğº’)ìà²ëÑë8¬ÌwŒ¾òüİ³&ˆ-äô“áèDúï1“QNfLÕéxöD2×8|0ş>—#0àDcå™•¡…²G~ğp3vµÍã44™Ï‚¯ešIÛ`'È÷9ÃÃH–4^]nEp•ù«oLnÚ/½`£V±{ª†WÄEqVÑµ€‚VIòøÍòçb)'AÎ¼Ô‚‰ÖvôÆvU¤ŠoŞõÚQbÕ~‚ÊÒÁ¦¸Cş‡r\VJ•ç/3€Ü£Ü¥EŞ®@£íÌô•Ï§Å¬WÔß8êŠ¢õBÄ;”Ï4K“'º6@ÂÌ& ÃĞ©³ï=ğğã$'UGßV’•Ãw6í³a@Ñ;CdÏväN”ô´î’ñ‰K]li[ç&<UÂûS<\ZúxÀÏØˆM˜®É2ğÃÃÛ‘—âHÂÔ(ÅSÎÏR;M®6{ïÏéª.–u8Dcx^[¸¾p3f ¡~/1*pîĞCuWôåĞ\—À¶Çzõö3D“×Ëu¥®ˆé±¡P%TBª±Ä{“Èíh©µƒB#j™Ÿâí˜xKè0V}VæıQ¼.òü¿j–÷!2«1@ä~lÜÁ4ú+¼fPÁ‚eq7ãˆb¯¯1ÊE]D©2õPÂ[õy'¦Sæ-½Å-ÚĞæ0b‚H¿a©÷92Éeâ§‹®ty¡wV	»¦< vˆ2ïtÓªŠóQNl#°Á1Ôú‰çE£=í¿IŞøš—ÇÁYBÿ ¹heB»Z˜¼^5MÕÊŒM>EKû7U|¦™[!p|‹]Çz›‰ˆ)8¯¸1@ö¹twá• Ññ×Ù²íÑÎÓV=ëQôå&«»ê‹"c¸¨e¤×ÈkÿÑîï¸=Í&2ÈÙ°ÔYìò HÑ7' $Åôl  ¢~I{šèŸãEã#Ss6©ş@·Š_·ˆ”hœ.á}£\—)*éø‹Ãc/H=R0}ø XH*XÓ«ìÃS³öq5 ‹ÈwZgØ.-@ëÄND¯¶äŸşÓH¼MŠ—ïØ«?)r4¬ÕYqT§: IJ 0&?`ù’ÅfyQö-<kV£WİÖt~˜÷h2˜3ÏüÌk„XÛÊ ˜v™˜d¸Æ‚t§ø„cNyËñ~ååŞ[;»Ÿè]Q1ŒD3½çI…MQK—£ó¯Å]İd"şJŞ×æÿ»O¼ò‰P‡¶ÓOÁ”[£YÂße€;Gª¸Ã¥Lw	VpQSz":b½ñîFË<Çäà	f`@Ë¡°¢ŞŒ«¢!XÖ ßy· ®ó±Ğ!ÔÌQÊ8œ<Â	{òQ¯ƒœÎÊ,|İ
ÿw±¦2ì$vU3xG3”}åÚ”??•âëº×²¬dæíÛä§¸“V/*ß—Bd¼1oœqçÁÕÀ hä§5Ü#‚q‡ôlÕÒ´#w)ÏÕ_ùVi‚^±VzTÃ5#/ü4öOöâ@¤í;‹ÃæÀoó—¬©<‘İ¶†—¾êÓÖüóï=úAoŒ‡†—«"øÎb¤,XÇæÇ¹ëÆ(ÖÍæ¡HÍ=ƒĞa‘X
P‘¤E7ìÒœØ yJ²(ı
2U‘¡ÁêA¹eÁÓ@«¦€§¢tË¤®"H‹e®(«¶™]¶ör2Í’®Øg/ÈL«JğâôáÂû¿koï'Íó<GF7ÂîÏÉ¬	Ä¶¦A )Vê‰;¡N;ï‹®¼øÙMxØSõD+Šµ!ˆÏ#ÖŸÿ¡´Ò9"@Dµ½É)@»©Ò—˜m\ÔğbŒ‰ôGÛ<„èî±d´É«êZˆë‚·ìx(aUâ1™×É:‘ÜÛƒ‚BÖÜ iâ-H¤ê†o|ï“ ùS0pÈôìÎÁ†¿Í=õ‡ô:s¿`‹É®`di›<Š~ËóQBñ®ê´!Tì Ü
…rét’+eà×öå0ÑëŞ€Æ}0GJê\ä{l€¶/³Å2ì÷ğ¬†ão@7ùz¬/ZÉ~\9è<Å­±cİ­!5€À5ğ¡;ÚéD!Ì]ÄrcÆß ?÷]‡×"x­q0êjr¼Ñe.àrèˆ&ğ¯­¡QİŠdÊKÆÛßgw¨5ÕkÈ_=êBv"Ò[Ş5ÕÃWœ¢J¼˜X_÷ÃYRØÕşšËÃfhM„Ñ
…OmÒ¹×â5™UNØ[¢G(ÎAA¦™gJtŸjE€H«‹Ô|4æ»ÿŠ¨óGğ„G°É™n(44‘wæ&Î‚™œXrír>ËØœ'¸%¾.4‹sc(R;prnmîÄàıÉ~<G×ù>^´Á¡¿¤ºGĞ×Á²ÛS9ä@‘¡ñĞŸVCˆà×™Hvì·qàh²Ja
Ø³Íü{y]Ä`HÄ‘Æ"®òí»V«<Í[‡ˆã†æ¼©«c«÷6t¢…­Í ›Øa‘û‡ö´fòw!>é±Şİ «mœLß'›16Ñ mâø	å7èù÷àÁœÂ®\ä:R{¼cş4/åu¸â€ºå}L$ì÷œJşûĞïiÈí¾6xİÛq¤hr®n,¤lÆ©};LBÆg%G%!L;=}cÚOÜŒI†´'²vZ(,ÏA“áÄñ
…$ |<™ı©ÄaUY!ùZù¥`´>@vƒúÁ“Î¥¢Ñã£-;‘xRÿ
…v´RÃ*›ù»˜æı¢Ò}Ò¶½¶+Ó¶Ö"¡X£
&]èî±z1½°½ıäõsK?vŸ=é	5¥ÕtËŒå _ÎF>ê»_‘Ó_ı›éœxÒw8è=‘A!¶S„¥Ã;†j(È Ú¹Å:˜–“şx\·›óa'L)ŸÅº/zŞÿMiµ’8†Wİeh{Ñ•G.^ø£m©9ê4ò·«<¥ÑµƒWY¼àbíÑ—˜îs-ôl·eØhÔ¢Æ®i±İ/Gıcƒõ˜ùÛuQÒÃ—9£ôˆábogoİ$yäOñÙJràòœs» J(™Á¹?È¬³Õ5#øÒñ:õK#
=H„šú—îòìO±º±k”´e$á“€yäƒDõ™œ
L,oXe‹­ê‚MtV[><âxß¬hë¿Ç­VÈ­ÖqŸçâewÃ/@1X4h&sœÅ*4µ*õ»¤£†f+Ùœ…=EŠb]ÂÄQRŸ${*ÛD©ñ]r‘±˜­.rÂEîU)¥Ï1‰fÈX¸¥ãïãiteZ²w¿ĞK	)Ğ]ndS¦C/ƒ›J+Ø—FÒ4©>5:Q[î*;Õ1´ä$¤¾ĞwŒvÑÇªÛn¯õL"FîcîdG­ç4W÷€”ÿ-ûİ­4SªÅC¿‚¦;&	e×#_4«|,Œm„üƒÂ×3¿¶+RŸ@{®ä°®Òf¦z‘ÖÈ=âO%¨-oø`UµğØİ(³…8†Û‘%<ı
.nsàäŸÎ sF§XAi¹ñı«ÄÙ‘ÛÀx3“yÍHXøqÙLw¬«yËE°ÑÍŠcEYH¹*íY¹LI¹a¦‹BÖ:ÏJ ìt‡Ä”P~ó2A«Uóµò+3çŸ öä·b&œÔÜô-Fo?]j¢„€(ıa p%Øÿ/fº™/]Ğt£S
N¢¼‘MªÉ§ı0XbÄ>AJ<¼ÂG®îdí2ú×%Ö¸ª9sÑÒc¯pÀ0özQ£[ÓìAEÃåğÑ¯è›—›iâ66ÿÆ¸á“¨C¥ß0BÆèÂ4mY T_ƒğ¸[`H_¶ºoµiÜJ¥qGšwÔw¼3ëz»Ía·&H2}r°Â’/Òl{
'G®0B0«í•„ø½äp ¾ìVæEsA4id¸ø&Ny%!o¦‚ï¨ï*ŞPÌ…ö£¹upë)~a‹D‘y³áojÏLÚyv¬ß©¦¢h%R`š¶T~—‰–0Øè[¥(’•ä‹0şxBÄõìŠ¦Ëí¶˜œ·Šï= çZ)iyqKÿ—¿p»ÍMqŸvÆm'}/‡Ç½™Uc›™mŒ¯I·h©¤3ÖMµ<İ3ÂL5£ÃµFGPó
`[û&Ë'ú1ëá†k’Ç^Æ¨®‡6³ivï
¦®^!‚!Ñ¸ó´ËF˜£ç¥¢ÔğG±ˆÙ¹@šğ+½h´çÅ;#ßN«¶tâı¨rWdi@°[v¬vÑ”ÂÌ–hÆ(Ç5é°›ØÙ¦‘\X&s¤ª7ş¤èÒ‰ˆ d,Õià÷Œ…R™*áøb„óûKmÁH³„}ªáš)¸»G›×İu"¿) )µJ`xjç·V×r¦®–1ù
eQUªÃÊÊH;6tßŸĞA 6Êå.C®!‚ë^ÁÇÁğ-y'-2®á¹ŞbZÊsNY(A´d»×ÖØeÛÙ‡•/fZ 
D¢ñ/ğO÷3kÒöwÖ+"ò3UìÙRÿöÈwíÊº¡½îöÄ	î+|Û¶Ø•üà]§©Te»ı§Sı‹i¹¨V¹¬”>äœµğ”äk}^´‹MÊSâÂdÜ-¬4Q–HHÄÿ¬9İ-]îˆ/¤8ò.w¶ı¿Ü*ÙI4œaÃæ¹#ûÉ>ºyZÜbL<²ñì=~!‚Ü@µe×Á:¼½N"¨“'\äÅ"}ùµ ¯È)\Wšhµs ¡i¹¢f`Ø@ãië õyåÌ¨ §×Eù^†}²éí,Ë'qâñ¢IÊÜ²-ÑaÆ	E†Ke ¨SWƒºI0#c#Yì¯ Ø)ú¬‘1öŞ“›ŸZ*-ºB¼Aƒb»eŒ "„&Ş˜*Pƒ °¢g™Ç,;J³R9íaä;‹mÇîwàÔÒzm~Æ0Ë>3ŠÊSØê9şĞ…˜8š–xpIlzJ_Ê÷{²-ñÇ$&™/%dfò…ß3hJm"©ğÁÏ/„dA×‘M¢·2ó“UÂ[ÈU)	é3¢òÅß‰bòµ/¨=çjÿlNó ‰âDâ! ¨FMLg‰+¢Ö¢úqï+ÌA™½ÑôùJ–j’9Šh,İR–®›ÃWÕ¢¡Ú:2îRšŒ*X	§—µjî¥ìY¾l¿7ßÎöš+)ĞñB©Ş“Áu\?\…ßĞĞÿó!‡õ®‡ÈÍ?Ÿ0LXR4ÁX¬zâsSx+B‡N¤Ëc‹{xî5H<÷ÕÊãîæÊ´NÑrá¤Ÿç²Ç0[œh£àk""Ú"¡*éV:Ğ#=A´s…ÙÒ·R·õÒ×Ë¨L¤= „~0ÖÛÓ2T|©¦µ#™¨š_?‰~óä‰Tú¦Í¤O¢­óTŸArAˆX@°{´®pŸ¢ò†Ã:ˆÓ"ò¨êè¢“&{ï‚×àn§9=Á¿™#k\û!ÅÜ±m­šn0ùó]b’şPÄ¹ŒgqÆ€¿É1&ó»¡#Õoıu´­–Y@ÑcÁ4C Líu#Àa^?*Ànè“AOûO¾OqÔ.T ÂÛü^]›¾ÿcózñ$:WíAUB¤VCÃª[™‰‚+a,¢÷şÚCä*W¨ymÜºÄÜÀ6ÖsnNv(
<­b¬İ?ëöşÿûI—S·¡sZ"•ı›”ga&PÒ¨A3ÙªÍ#ŸAÄ­55ÕO«rE^Æ*Şär5)en‘Å¶s=­¨ø/¿¡øe³9ÉğSÒó‹´ã¹%@áµs2èÅÜÄˆ éçzsGøkJ@hŸs	!!È9[ Šúºt•a/ëHV¦½V«ÉQFñï”H8nzòûÑÍ`¦¼Xû0KºE¦åu¦·ªÅË‘í–öÕ±%3äüoN#q6Æ ‹Â!¢ÓfóŞ¹÷y¢Ä?iNÌ•öùƒé:–º?ò
»Ò‹ Æõ¡Ë ãÓÍÇq‹bjÖ°àÿÃ…Ğ	pZª ‘`‚¬—¥¼:–@ı¯l`Â|uªsd×UƒâfzÀHØØL”,Z€pz6ÈÚE­	ê¨Í; l#Ìwi•1÷¿qHyQ0îd:ÓP;!æWT²QnWm§lQù(D'' §ø«W@l†:åFa!RNLL.½Ãä²Ûyo``œmzÊ¶?ï¤ÇùÖÍ¹Hk¾×CZ¸0‡DfUÓ©²È½^uç¼	xâ_ÜkV{	®D¢Z€   ¯Dé“iC% ê¸€Àä‘*X±Ägû    YZ