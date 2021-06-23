#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1275924148"
MD5="959932fc8a0db90cae3e269e13e84f89"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22988"
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
	echo Date of packaging: Tue Jun 22 22:20:58 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYŒ] ¼}•À1Dd]‡Á›PætİDñr…7áÿ–Œ-mvı¤Õ$¦£<HŞ‰‡%Œ6Vh®î›ı;5®÷uÚ°M
Ÿ];î 4¤"üû}“A²Ì]h¯}&}ÄD¼ó3i¼ùVãKŠ•?+Ç¼@¹ "8ºÑZ
åËY|í"İ°Ëf³JßlkáhO+ûpãQåT¼ôMHëäC§,w[‚DçŸõsUcFj;‘ÑNo¤Ïo923ÛXR*”PHäà‘K+9œÑj‡²"ï‘†4?ƒ×ÔøtÿÒIÎ¼†%ƒy^#¦ºqi¬-0Œ0¥sˆtoä8}™Iˆ²2Ì4Í€l~æ¹5…ÿ/ìÑõ‘|4ß»ÜCğ““ÔlÊÏ÷W Yÿ8’ËOÜw$²<†s¡åH’t¬9d^y)MŠUŒuŞïs(`P{…ê^`¡¦Nj·”.>ˆš~í]¥\Àã’àH`Oà‹LÎdÍM¥åÅ}5q«†•%©ÉšÎño§Ã-ŠD}ÏÓÓ7âŞ¤õòg~Â™®Éy0¶¦¼§?#=kí]Î¶@k9C~°×ó÷š°Ìƒ±/ŞË^†-É1ºßŞ²7ØuåßáJ9wß«[ï$ˆ0Èú;Ëì×ÉH-3¹íˆrÊ¶ÛL”i?…”ş–e\}»ÔXÖYfä>Ú´#Iö#@]2¶‰L
èèı]ëlÃÔ.Ÿ£vyZBbÜİd‰šníÓ¡ó+ÓğAÊãæ©Ô,ê	n€wQ„¶¾S¡úaY›£µØ.‰½Ç½@ÑD?ÙÕ?h öÛ‘ˆb$ÔöÈYÌn&!|Ou5a•¿¸d•¹†‹w¿f&]xÇæNgÿ^®D“¿#éYå±qîB&T„á‘Mï½¬¼Å¨Ä¢wŒÁ°G.Õ®ÒO¾ó(¦'ÅÆñÜC¾Wä%'äõMt2ÃÃ;ÓXU*Ÿgü—d|Jáœ·AïOhË±mê0¡Ùãß´eJM‡ÆµÅùµï.±BÀ?İ@¤ÃÄXµg^¶ı(õ¢8&˜ü]H|: *À@HÃÀ¢pÉSXæ5V¾ÊÖZrµ	ìÆ›s£ÇàÖ¥´ı‘îâ™H€Šw^ÆEæ:2tyº¿
%*P^>ÍäıºäNÁÀÅ50¬ê_zércÊ}n¬¡ /¨Vl¬üBì‹ ªKUææjÏ‹° ˜Ä‘Á•C‰à¼v '»—R æ3µàş
Ö8u
À¶ÚÉí¢Ym`ƒ^H1CT> Ml¯èzpjK]ÉiQƒá.­FóíàÀ#"]ˆãÃÆ. ÉW€ÜÇF)?ç#5j–ú—îXIïø€‚ş¦Âèß¿.¯øğQ=öe“[[«\jˆæ°Y××+n^|^Æ&tõæ•1HÓ†¡JdúÅ¸Œè5œWÏ{Ç¹’ûñP:¶…KÒ÷ËTóğ*Ğe˜™ùM¥Ù{è¬d2o$<Ÿ23÷:jµ£İ:Á–™á‰İUj"†dJ Hü3á‘ØT3»¬¦Ó¾Óú]Ä^¼X<_á·OÒI@B5õ¢çœ'ïÓğb€'Ÿlx¹¾ì‚l\«ö¿M¦R‘Ã1áš„G×(6„‚qw`rOW»¦k¾>áöÃ›Xë•xMQ›ŸØØ:u¥btáıP•X§ägúª3dÜ<RÎæûÙ; …ÛY]ÓÌ']ŞºxĞx¼ç³“Ã‹º¦êg9‚¹51nÀ´ä‰Õ©6‹ˆ8ÒÂI®dœêFã÷ å…‚>áŠLÂSeìBŒÚh‹T]3qT3íø¯k’)½44’èšeu¶±o){–¶Ë$3=k
	yÑeT*)5/—¦?áÑr‹ÓX'®¨D…×{©1Wg"K\Éµ´SğFÓXr9 #Yıe3W{l™w^)>~œ$[äÔ.É‰ ‹KI™bÛ?ŠMrV_—ÍlÊ#O²c~xmN!Ä1ÀPíıª±Ğ!e™AHK¶?&‹Ì‘˜Ÿ*8¤K°şËg“@ï–õ$P‹µ{<†D#t”²Ó[¯ÅwŒqmNKÌT½ÕJ^ıÔóÀ#°{k¢'Óó bí}¢ğ½™×uoN¡ït“c¼öƒñ¸¦(»¡ŠèO8Î2ÙGc‡–ùœÑ™ü>x¯ªø8š'ATgH½?GÒAq¯rõ¼tY%z¶:d§+)è^Ë/5Ãs,®ı%Ò
ßÇN#ğXÙ9‹"ûJÃ®â«@™ÎHO Úç^Gs”Z¹Q­0‹®Ï~›ô"q±Z¶	s­ş=Ç¶ô'ºÄÃ«Çä—CÃx"rÕz°Ê„ŒGc§sm°×_ÿ` O_÷jw2`¦íù³¸aèµ–½‡ÊâWâãtoêğ9PÀT¦”c*.†F§`vÔû'¥¨ !Bß¤Üt}ÎÑ¸y²-CSY¨u-ÅÔŸ)†·Mmÿ(äõCÓ2¬¹F‹şoÍâí¥UhBOõ½Æj3Ñ­$ˆiu@ÏÓÍEñ"`ÎõòÕ:Ø­^ıÑDôíÏCú·±È³Šñ`­±ì„ôR
öšg#ùào«Ô}€åW§PoÆkÒè¿ÔÂUõAQ‹½¹F:9ß½9è¬M÷é†«j¥òGOüW%iùä­lÉdåZÇ&rKŠp–yö Ü>aÙ¨×ÂÂRGc¾«†)C¢Ëÿ†É$ÑgIäà·æŠÀD`©Æ"{
’uUåy§gm	:î‚–„âeğUÆ…Dt÷>Ö°;0Rj:N%_Ù³ßİˆş‰ÇÀÜŞ­.GšfØ!U€ÃKø˜u8Fu‚ÆçêÕL!Ü'1ˆ%êUÎY•i0·"Ãğ/áË*ï`[j™up0Ã°ûÌ»9,›¦Ï˜[ªuğ¿ùÒ.p}½$¹N}bò’ñ÷şHÓ­°¬‹Cª >?ò'»¼}"q>64T»ÎÎöHD å †™9·‹„q•Qğ!M	ø%‹ÙŸÀİw–'¸sõ å-vùª–ƒ~¦àªÇÊÎeÕ]ú³75_¢ÿŸÉ™mwS“W«$*S+¤ĞpFD~ ˆêÒ>Œ;ıŞÇğ‡+	ú2€Ê¼â{uf| .&Ã­´ÂŒkßGÎ¾÷ë×jx vü"+jpøN¤^ÒtŒlåÂvjÁRÆøDæQéÙK£(¿@†§5‹Ïğ± ¾(×Y|ş®g¥Vz£²nÎMpB°æ½()û„q(â4‚y½jŒ]¶~3v¡Ï§KœUJøıf;¶p¦Ì'æÊ~Ÿ5Ğ×˜OÄ4Pÿs™ÖgŞ¬BÄ†Í2kÈ(ÀÍÓ@i5üDaÎf+ùREIff':/$ÊĞ'é@Şìzi™*2‘iŸ/?føÊxà
N²,`Ãß§Å‹¼Üv…†—%•®õáíÇ)	“pb¸íƒ‹3s%ˆÄT‡2ĞR®Ø=T‘ôª*E¯@r€ÂhSÆäá_×Amÿ{î‘ù}^õÒûÿf ßs•dƒÍ´\åÔŸ ÜÈ÷üT“9İŒQÇŠqº¸ÔLO¬À¨ãÅ
ù@6‰‰_NÇª²¼¬ÙøŸº3äQüŞ[A*Âo,V›‹[_õr|é8FQ§:¸¥VÃXÓÌKM¸¤b§'×#wÂ_¹ıßòP=˜}~cÇëô?©Å¡şÓ]-ƒ¨Şr“ü@S*‚¶÷Béæä)õ†œA<kØâ¥)»@Ğ”äŞG»B3¬èóÆ*mÊİfrÑ÷tòÅŞÿ¹ÕÓÁ,¼—×å™€éh–‘C}æÇˆu²ÃÎŒŞŞ3éB{¨X“y^ë~ôæ ´h:
8Õ–RïÅ/íw˜Õ\šó½–·A•7Ÿµ¿?®ˆI	®;/uœWwé¦“–„à/ºãk·ÖUìŒÀ€ÈöÊÆˆ™qğğ@2ÑÑ& }pÎk
×/è!pîİœgboÏb"ğıú¸&zbdñó`9wxÑ" 8JWRc+Z¿9‹¿’«…Qÿ ³*OÑ`‰Oä#‡à Aìdóä•°=ÌMÖiŞááW¾/OÆ“;³‚iÚá(ÏõnUÅj×*Ô»=HrµÂÚ9öSï¦$êÀ¹=)°ÌŠå6Më‰'ÈéF·-LC¬Ç!-êBæÈë›íÙ–W0Ïyë§ú}7)} ¯òì¼1aÈ 8½şt6Êu ae	”×xÏIBf)üˆ#úÁ÷ÑûJ˜áà± µíÿ^”T·-ê‚Mõ˜ v”SnÁ×Ù²¤õ†ÿƒ!ö×Œè@üp&”Û¯yhª;Q¿÷f’Ât‡KFÄí}PHhmB]}^ç7Õô»ïáğnÏ –õ:,pm'ÓşRƒø‚‰˜.èÒyÛ‰O•–‚Ââñ*¢˜ ‘OjpßæJD8uÓ³\x˜äËĞ–ÙOéZšt^mìı>NÎ¤œµÕ'‚ĞE¼ª¤$Û]¤kç¯äùEÕ?—;5:~ğÎáÌ¤U–Öæ}­cnPVW’òóG3?8z•ƒÉÂºÜˆşb*BéÒONbDLÑµ„*XÿoxêI$ûş¨!!-'Vì¡;WâÚ¶à·Ğ‘³&i#-”ìõÇ²p˜G¢WÕ™R×FûÈÌ#;„‰jêˆFËB$ëÑKB½/ƒuE¤Qg>N÷å¸¥H´›‡¸Pa/ÒŞ~¤+áÿàİŠjÔ[ËpB«ïTÎR3³ ¸ç—¡-û¦şˆ^E1~šñì3[E¼„Îãp9áxŸÙmŞo 0ñz`!ÑˆRj²O—hWùA*ğc7ÌAí¶gˆVŒ×ú‰&‘´It`¨lfÒµE/T#ıî~éşr¸´21©ù(_®,l©â™ßÄ<›msKĞoH©ñpr§Á1b0~çÛd2Ö{f:~İËF†¶À+£îp«~8Òí€aØ&‚Úå6.ˆ«A'b×Ùô˜sWGÿÂå[äÿuix%¶Lâxk2P„Mñ·•7ôn'”\‰Õ©Ş•æÏá}µ½,4¦zÃÖÆ…NÙ¢b©(ÉÕÈxêä­ds5{o¹Qa)a³vé0YFÆ¨ØôCrG\_ßPÚ³_°¦•˜qßÇíKRˆ5õYQÈ·±Û‰í‹E@@‡Ùóèò¼ì}gN©”:PE’Ò¡¥èÏ=jJ•ùÎ9–tEM:lJ™àÌûß Z `Oò¡rÖßNar û´üGTï¸»¦Z&ôÃ!Ùì®GR\¥Iˆ<Öš:sÈÜ™»6£Rû0?Ç³Oîä1éìs)TFˆP>,f|£1ànLµS³£é°Få[w'Î†Ò=Ë©îó—o§¥÷æä0e,"üñO—AÄ2¨¼¢`{fiKš«ñUšã»%'l˜.m1¯ÍùLoâND?,A‹Z¹Õôº¶İe›Ğµ`E°“9læ¿²ŞØ¯\E±2qAèÔ“á'·‹v‡Ó ;éô¥ ¸Ç—5Z“sPja£˜Zft÷Ş÷+Rc¾YÎ÷¬5£E F*I/FÅ[D„şŠ¶ˆÑ1.Ù´ÿ©¾øµ_ò?ÆdÓ\[C‚ÂFáËqº®¡	šW•ExP;Gr+BŒSV•KmèS;„:oA€Ç5šğ°ÿt ßØŸ—æBŒË–ÖÀ¶0›!ÑQÍY§ m_¯JÓbåè[¤rUÅ95âÑ·˜€ûÕ¡mŠ¦gê’Rø€ı00³—+_²À5³û_>7V#>M‡Nk&–[´š£äëù~ñ˜,ä ‚¼Xm'<ã”ã!Û)£’á¸oü"3ß7¶®Øu†ú?Å¢ÿ~]hShªeË<pïO;ü¼ü%Ààeß;öŞ~­µgÃ¢E"’1ú|F@Àj/E\ç¹d$`M6^»í¬ÂùäApÄ·GŞ
‚Õ†±àÊªË—
{—SÀûş?1İB£mJp´v<÷2¹óØs:6²İwÚ«–è!¼DSŞ2Œ÷º^Î_Bd|-ı*E¨N9„Œ½0¢5äØ)5æä¹¿P1ïRİÿµSëœ^šè¦DødĞ¼O£ ’5)¯±i._¹tFuÄ$Hãr{ú#{ —ÿ;RgÅÎ­±Sş,‚ŸÚõEXØŸœ…cbŒşá8•f)Ği{æÁaíİIJ °cfrHÜãĞ¡ÒãèjàäP…ºZÀ1Ïb€”Yceª®ˆE_›P¾5n¨îéø²ÅuEáû° W‰P˜æQY4G	«åñjªœg5YÜÔñ8ÀÕİK¨DŠæ“«×Ñî%Ø~íäN•äÈ°D¡ïi2¢(š8êÙß=˜­Áó+Úru‚é@(a ka–¡Éò|V7¿ßy$mŞ'@$eÈÂ¹¤Ngåülhğ¤Êl¯ƒ(¸“¿£*éÜ0†¨imĞAú†€#ÿ=SM²ÉaS(òƒ%»+BaAœi”KÏ8…–øÑÜüNß¼RÍ^¼^éYıöÕ3níÀ\î:¡µÙ£„Ö›Ğ]˜0ÿÖõkiii¤Ùo²,*ÖÂi×Hó‡ ¸+ :‹ÑÔ9[&Üo¼Œ,OL6İebRO¹åÅKŸl–TgV®ã8£µ<5i’|”-M‚°µ›Õİ°)/$I1N=l…œîë¦L:™ì;j‹Û¹qÂ¤&š*xÏÉ@;Ñ÷ç·•H%ª^¬šë`q2®Ô-Ï”í®¢™,‹1¼øc}™aA³ÏhŒ`Ä)äÌ¡<m¸iÖw†„2$°¥f[AÆëø0›Q'‚ö5T^`Ïƒà¼LH¦"ÅÁckÒ©oÌóŞÄıÛÉ@pxÊO£uÏ3Š§{,`N"îèb^YU<8<v]öHöèöB“	ô¬¡á_‹ö™  Å³°Å.bÎ*•4f4º†Cd!%úµgêîP›œ×'€@Ğ˜{XI-ú9'8ï-osú° Øç#ëc
îiAå£~Ã±d·+Ñ¡1÷+l½36~ıdéáÕÀ*¼OòA_–{3½,Ù#É±²aŸ%|…Ä|}	«÷òô¿¯‘<ì»)˜PPæ×RºïÔ!Ã)ëWnÓÈ´:'c©™¨=œ¥`¹–‹1w'v\b¶ +Ë	Ä­Ós>üqÒ´£—Íh#z­€Í²õ"ÈpÑ_E@²°K³ÅÚêúfjm¬'{W×¬™qv(§M³8aeÓæâ÷†	|Ş{òrÂÔ ^ú0•V-„S¾ƒ>©#gˆ¨nGo~%ø<ŠìeÜKô£Jß»œjçHK+ƒ½eMeÂ_÷Ôs„ƒbbSfLãKäœ› üå‘Ä¡EÁš âÇÊtHv¾1“ÂÔ…	ˆQìJjò´Û„°¬ƒr\ò®í_Ê( oœ¿h)vßµ
‘²¡ğ_WšÄ¸ÁÿÈcÄöf$¯²=œô³¯†NòÁLRN@Ú’?¸¬™A¿{1’6ª‡:«rÛê_Å²ó=â÷´™xüïŠE$ŞÎ*ƒœ½4 ¦šúıç‰k^‚?°ĞDô›†²²”ŸsşHû³€Åf÷×†_{ˆ«, ~Åm£ŒE;Z†Ù‚9[*-ö;HÄ Ñ‹x“Ö–v‚T}r>/ûC}$;¨E5o]5Áªâ/Pë°J(Ÿô'”†$=¼™ÿ#ñO‹DÌµ˜Ú‘š¹xœ'ïŸ]H®yÀ»V“Á|HWŒ%Å yXœÒAUÛ:Q®Ç¹ÎÁøô±ú=»¼ö’>Î³Ğ?º{‰ƒ›+ôÃ[Óh{KR„lO™[ÎûqåTú€Ø…—Ç•ñV—ğı{qc¥“o™#¶P£Ù6Œ0ÓıÜ}º¹¶Ï¡‘ˆçôßÔ„ïåùÙ­•íÍ•“ü4æ·= š3ç¡Äm}ÆTY«‚ÊÑüµa~ÒF_ìÛpq_¤YøP¶ÜH—-¤à´gğ¡a§q†z<0İ|aª%†ª„*èF¬Pˆ‹<T‚ˆtşKBi_ÂpÁ…˜²ãg#Ôj©¤nÜ$É½L6\ÉD—÷îË2ÌâÄ;L¥ ›I‘âM©¾Wâl‡‰À±t,Àá²`{p|•pµìsQã(ü}µïiP™zÀ¥“REwà•e,ò*ˆÓG ±_„ªëÕ*†• Òe+n¾ÍÀÈMÆOÏÇiwQ}-”ª¤:Ò¹»R®`¯LĞõÛ›¥÷¤è¢Z!ú—‘ÆdMG4sä¶8Ba{ıÖbO¿«K$äL›	8Uä9©	Î—ÈÃEÀ¨t4Ì†Êº&ü¾h]xápİÇîú¾Åz]oIJ;lCh	ÈÜ
ñ#ÏÒF©	Q.ò¼Š.x^J!âÃ*k¬Gyæ˜A~ÍvéÅ•NJrs×Åô½PNxÓ‹¾3û’¯\•ã¼YÖó¶ÄÀôùí!@Àÿ^bQ õ~a¢_ÀÍ]2®C¬™!Ø§)ÌNÎ8ädğbUÏ¢±¢7 0(ä9ÌˆRN]˜‰Éî¯øGUûZ°8?ÎŸÔîöGŸf<£˜=¦¤Æà´]¸Qy`ÍîEÇ	„®ÁÜÕî}Ëz ±··ô}0´Sp‰°Ÿ°(x¨#Àæ<ĞóU:Kj…-aà´†İœø‚ >áÕğİ¿_ŸgñV«x¥’–R87ÓVem¬nIGª_µ8G#ıë0¯*£:p¸Ì/ì^éB9íìüçÎJ ëõ§Ï1Ñ,>*9›9ï¶ä57	×“N_ëºĞ‹ÆÈ	€gúmB–Y#—›_?üúI·pˆïìT¬©*ÃZP(™øï‰À2¯½õØù)¥„%wsÕC÷IÅu¼cÉsÈw‡:´öêŞôóv¼xÃH5ñúó“†³;7Yš÷µ­‰Lı,#â˜`?0ˆ|êfuÄñ‹"ÃjpÓ>Ù³:¹ù±BoZîZ7q¼WÎ:>1Õ®g,\S¢*û¾Pš#]Ô ú®“›0mÛ®)ÔäTKdç±½’%½·@9º.2ÄgÚ©ÙØ¤¯ÅÁ ´“êqºÉ!¯ÖìõåW>J·c"UO}İ•ÿ¿ÆîÎ¯·Ñ“ï°·-7ˆ¥‘¥ù¿›fç	ÔIŒ–æç–
©M±k»ñ·fHªäyF´ß,Ö¡>ûÖa÷Jù%S`fİ>1‚ÃÂŠË·ä„©EVzÜ©Öü¨ìIa¢ÚƒÚ%u	Èw_ªÌñWã«'Ù¥ˆ£lPúÛºÎ´˜4`¦ıBVT5Ä:–WÑrj2Ô»
Ğİ®Ö¡°ƒ°“4·»4‡×Éÿ¦µfMë×¤ïîv“}íÂ6hàmmg©èJÔF[àÒY@€pèbÿÿpq–™Or‰B±3åŒò¶×Õ4²C¦ …1ËÈòÆ.·I)^Œì{WµÓu‡dcdFÔyx±XÆ·ùˆ&*±¸Şn©ÇWÁ;…~@‘­X1x€ª'»ó›ZÚ5±c`årÚ™êßÇ´QÌd'g2È6åC47nwÉå}`kFÚV’«-ô‹ª¡:&mJË=’ëEa(·²W=ÏQJõlDqŠXg«úŞ½íòp'p‹›z²)¬&pıjS¯–(„böMÖ“ü¶[¤kùE°åÈ·†9›m"Ñ‰!_È|f<>4İÆt^Yø²æÁİá†”l4ÿ#å]ò”î÷‹¥FöúÔv¾ö'„[ælª)áÆ]	¼veZnZ`¨Ü*£ÅëÄR8|ävVjœ»ìôN²ßÿ÷p’ÍÙ H |^+1tT„^Ä¨ºMìtÖ¢åŞ6Â#­õo½ár1†É~lt«Üî–İoÂîØ&ÎÚ]éÛ?á6^êŠ‰¢åä$µÍMxâÚÄ´¹'jöHªğƒñ¤1rH‚ÇJc|¦Ÿ¡¢HdŒyüËåîº*¡Oo_`w9pÊåx.4K¥¹ûMc<¨<àœê}Lf^3'nBÌ\ZUGØ|,HŸRıšá‘(ˆüÂyŒâóÖøp’—Ìw-Æ*š<âÈë™âùË=l4² ½œç ¥"«ZuÔ³‚¯%^@ @ôOXÅ\˜|^YWpáíô®¡O&Y(Ñš8¹Ì l¾ĞëÈo\££2<ÉëÊa®p]ètä;§OĞo9ŸÁëAoq”x®'µ¤p¶Öıf¡g}÷ÖVø[7b‚Š`ƒ¾ßC×g¤!Ì¢ãëYîØšßJ¤s&w†u£Ï˜«ØÜ¡¹‹”ÛL‰icIFp0=,*âäë¯c¨×óây§\r˜}­—W¤‘›s¼¾¤3©›Æ[A0ŒŠrâõÕ50U5ÿ´Ó*©ËdÂ9û¿)3{:ô©8˜&ğZ¿QÛÒô.—áÏîë=Sç¢–İŸ 1 )èª#Œ½ “Ô¦öuırõT²<Çn3ƒV›çÿ[i,%mökD™bä²Î„W±Ñ4†ÕPİjçY²L0¬´gJóáÒgË›Bšı%ñ/‚IH_.©äM€¥÷->3ÏFbİ^hç•ôUŠº\)ñìÂ©ÛH8«õ›w§n„WÅsèø}Àª'Ag…s-é .­åAÑ£¯Wkšxu°´›Æş­L"ß]Ò¢¢ª–?Ûl5za„{½ÇmÃŠ™kôö½ í8—¤vn¨
Ô2÷{øgÎ7ªŒM)ÕqJ’½Àfüz´föîIÿ[”–øhÅ, ¼AÏFßœmôõÉ»¥÷…ŠIUPìmjê=Ó"
áôzT6×îÅ©Aô_‡ªÂsHmD¢¸qpLH#ä`OÉh©Ç\õêª™Ç‡ÿÑıÈ–™İŒîÎÉ,ëóXgXÁ'¾*Çåt=Ám«š¿éî#æN>?ÊŠÏ¼„HBX:s·ãwu;™2Ôx[k‹ÜÓ`SÚ³’·b‚@¶I›’'ùõ	m¹­0Ù%PJÉÂB[(ç‰ÍNWƒp_F¡ÔuH~l§®Â	„+H"¤öŠf}Ş”¥íüÄò+‚1fN7×<{>$…}‚~ø¤ùeHQ¡sœ´¼`GÁ+ï4ÆA-3ïäj­ån ˆÁ´Í® H/)_¬söÛ»r~í$íŸX`‘D;/×nÄzïôÊM”bTÂN‹T(v·u·ğìò&7ş|uÄ‡–­ò¥ÆR"c{Ï…0ÑüÄ¬4®ø€ßû#ô³ºMËaQÜ¼(µwOÄˆiÖO…DıÒ>ÔO[AA˜,%TI2õpèÃÆ8O;o¡~|Rô0,²º¡Öî1JÎ`´¥³¢±®n¦´®FİÉ}µóí>Pö7¼“‹œIöÿz ‰5mÆ[©.[îb)òAND™¢“Uü©…ãQK Ü‚^³np‹˜øÛšRÿº]¿g2¶N<óg¿áœ´sË1¶^—úÁ)8û•6ˆæ$¸áù›/£Ò\´F['<Ö}HY­´@Ø½<†£VsZİGnOg A]J!}Ÿ.ÁÏ‹>ÂjõÌõÓ	+j{l;‘f–Î<d›‡›OBRÉ-Öæès”˜×h¿
^-Æ4‰Æ›î,p‘lâ&ˆ53ØgĞúk¿Å€ôù,Ûn»’Ô‹İ¥mÊ
ñof$İâè#™¶Œ{qçhL¢ŒGqÅˆ¾K@H&÷eìHn?Õ¿Ód1°µ¹Äj‹Wî«0N¦3V¥ûø°àj¾PåìÆ‘uøÔGi1‡8İËöÑ_CôÊˆÓ~PK}òûpJ`ÃNk e^…»1		r¨¡Ú·$ÌAigîâª¬Ö€¡Ÿ‹«öZ‘ÄÉ›ü!vÔ9€ÄfÈå;ìÂ|ÿ9Œ† ÒË½ƒx¸Q‘üå8_#¾U¡$Oc¯ö(ûüiuæ‹] .H´<(:w0lÄ»ˆ^¯£ç£)KodxğG''Œ‰›÷ŞâÊõ…³Ñ;jĞªÏÙSÉÅ7A’”JÂ?ñğ	ãœ‹š0hÂYTw‰U½º	,µœÿı]ml+ıæÛXˆÑ0~¦>$áà—Éø-ZEÚÅ¦¾{[”Hõl²_x³4œ^8\ÕË»Ş˜ô¸tºŒÂG½¼h1@l´ÀtçœQwô\"şûW++óù»‡–$x‘R”R>ízøƒçÓ^Îö%¥İŞ£HGBû<í~ş 7wQ§–•fHàá8}çÔN(Ù8GG·OÏpÅ?Ÿ­„ÎœÙ¡•}Ş<"<}¨›“)Ì~2›=çF)%ğÏëè…¯ÔTš¥¼2sôø£êø`\:·ÜîÑ?Q¶Ò½™—­ù¿ìE;è‘6yÍ.‡5‹N”¤sË‹Ù™ğ©Œ‘Õ¿'HX=¦c¢—‡®Zk,¾ÆjÂï|«ì&màáöUêÀĞ¨›£•õÿ’ÃµÖ%¼É‰_}ö»Pà‘‰I‰i?ĞD v³×4lb'¾Tş–Ê*Ká0KI¥_º;é]ÿEäíq];Ó¬“/+ÕËL2^OF!½°Zmˆ˜¶µÜ® 8Ş©‚¦ÀøK¯ß“d¦lIèÏ­˜VŒIçÙêöK~ªy‹°‚I˜+N¾
#Í;P=Êƒ( U¡ÖĞbsV—O»n7Qê{âi‰öÂ4¤xbğdÖO?»¤ÏZ”ÀïËÖI1˜u” ySÚl#Ú‰â’š‰;c§‚F‚óáüéöG‡¾5O´tf e…°wø“XÂ¼©k2Û±äoûzuº™Œo_(e‰íNÄR|Îa©é[Ò<ËØNk˜=3A/ìWâ„XÂZ¦Kê”İ®gîÒáv¤ŠúÚÌùcm¬¢Õ‚ä>3¹œù‰&—M+Ú><3Y«Y°´	S>Èpá¦¸£ÉˆXEép{@ŠİèÛY\!ŒŸ®´×/É2Û\×_JáÊ>|bËJÅ’¾ßáû^ïé‡°`ûÚhÓçdÙ±Áš}~bğgş§…øYqß0ısÛ
­aôÍŸèƒ7~L		SßÙ'f“EÅC÷a<Ua%œn¾ªAñ?#£zh	ìı-	5jèIm`_¶¦ï—EÄâ8§öÊª0f:á¬–L”‚Ou2.üôîúoîÿƒu ?ûxŒÖ“OùO]%WäL “KßDşÈ¤[ Êòk¹Ë‚¦.tUO%cïÊÇª$"ô„ÁoWs)+¯iƒ]QQ­À4jÂr¹Y’›~óÁFÂç6ër¦“õTµ‘§ï â¨w’~ñzz4‰ÔaRò ÿ3ÿŠvqĞ%Gâ[¶3Od×+Tf·m!dÅÏ–ø¾f~bº%aÇğ¹&'Úù…ıßî‰(<÷De&çqrùëíÖ±ajV‚c—ÁWÿnÙ˜ñ¶¸VŠÆMRçõ|L,³èO'Åô¸~­bsqã_mÀÍù`z‘tš,ÂWÃ¦÷Ñ'Õ`¨2éD§ôávN¡ùI””r"½òaüN+Ì^/Ñ]HNJĞğ
Ì™í9Îpë¸›ìp^	 |]§ö„*^oeıåÅ*gŠµ_…œ´õ­ÆÅ…aÌm?4†U…i”®Å`†HÍJ×œdwÈ†dG÷øş¶$*£”®E÷Ô:ìEóLüóÉ£Ä©¾?:³ì4ÊÛå´¥gŠ1wÔyº[¯û†S6“¨tí-8wOòO÷´Àÿ¹ O?!^§UµÙOõÑ|:\ãŸN.„?½£ü¡Æª Ãi¿Ş35%L.K;’¡ÃpÈ©x´Ë±ªUO¼Ä$è¨d÷½AW–dy¼”6Ó
”êš5sš‘ÑO*· Kdî&‘8_ãÒœ]ùˆ®À¤Üˆ¤õWÌ7§²uQÄTgiÙFT­Sf uDxé£ò§`Òµn-eØı'`º¿Œ.ÏN”¨ ßc z|)©MËMÎS¢kPòšL^ p%`Z{l†¾—]¸å‚Y²¦8ÚøR°ÚÂP—‘NWŞ@N™±Ö`ú—ëÜ«ŠQsË^Gÿ]×Ó^iíU^ouÄ~T=nÛaÉEÎ-ğËPÿš·»’ùe$&%h©O¼QÂ b/kE¼[}(> UØ©Œ]E–Ç“î•‡h²À÷/Ñ4SAşzaØ°†;>ä¦©ûŸ™jÔ½tPt¬ï•A5Qr¡»zk±âû•–´‰vYa‰NşÛ“W‹8J~\FÏ€€’ÕuÚÈFò&§8…Š‹—R9±Á;çj„*Ø¸NEp«¶@ùîÖK©&+áòWÍ§ÛÇ'$7WK¾­m¸º9¯–}ûb°ws0íHW.„ªØ•sö‹'˜èŠi©;˜†Si¬úoÌënà]	™ÌÇÚ	8Ë¹ Ê¥³ÑŞmŸÀ;<Dã¯]ñ™ŞhxŒ¹µîèX ùH¤7Î5k,eeÒ©¨å-G»İ‘ ÅÂÎÚõÏou¼Dg
•LBıR'gÒëa~ËáÏs]~;<3y§¿†1ÙÃ,G1.
À{”~µNzU&¿Èî/ØS°¯.ü‚ñõ›”¨Ùóg2¾–>T®• °±‰Ú~Ëš
/ö¹ß¬R}y—äGYd—3âCNo¶×uğ=ï(²i>ÅğLµ‘UØC˜"C&LĞyˆ°ÿ.së¤jœş¡b}$cmÄª!e«¥¯M€«“Ó•óQ|]šXáú§õzh³¾âáÇë åşùË›å`i×f€<¤œ¶6c‰H{DØÍ]f×ë‹ˆL¦F€7g,Lkè”­“$™­h|tÄ3®ÒE³ò`GÖ)»ß-äûÏN1_{“‡–İÄ]İdä"øÀUC¹eÔÏ'º7Ok\ûX×kà«:I`QÔ›AY‡ÆbŒ&®’½Éw^„’ø›©Äm7˜İq<‰¤Ñ&\â&Ë¶1_5ıÙºVü¹ZŒ$YÓ°#ÇwşİöÛmôü:Ø°ï>’W;U[TA.z¤ÁÃ hÀD‰š ú'Ó?^ÒäñùòûŠúÎ†ÓhÅÁµ€Œ­•üî}!ïsô@ìH!´œİÍlîE%vbç  1Ğ0t:IuîÆÿ•gI×ßNÃÌI]÷TqüpPúÃRÊ5-sC_´K-Æ©««E™y3”\id/ğsÊ#÷vr@mßêäj/úå-Iˆ§B
³ı¤™åZÉS¡Şkí–;t<’kéÇHC”±^éËGĞ6—†!%o£Î "íÙŒÉ|Æä“_QÜNkBÆ%gPX0Öºû1K€$wÂŸ7a>!lñséYãÚôAiUÈœ¬V»(íÒŸÌË;oúoğ4µşBóq¹>kŒRgyBÔ”óş^/ù
°ê/_¯$*ÈŞr`Ş'Mq!%¹Qš¥;–²ÁÁeu‹¯8–¤‚qôbueí}îÈj‰Ûÿšsvèù¦ÚKñb¨HNàcõK‰è¤ŞT¢Ç øïXü*‘â5 '½˜“ ãŸ0ÈÆtI
û‚¦šñÇ'bíº8>PF!«±‹aE‚ö€¥ú¤B°lúé=.kÁ £ˆ
ù¦Â`ß”İ¸J<ïÊDñ¹ÁæDï…½G5‰	ñc®~*g`Húe0ŒH"Ã+Á/vÌªÏàEcI¹Ù×+„ÖÌ¦ÊşX­!¶¼õo¸Ôt*…9äÙoxH«¤‘Ëg“2 ±V”åì‰·@>[=¦, {4Íï§€O£8°TL¿Xî€C5â©…µ° ¹IJ¢1–é¥ûA¥?ò35³X¥»5fÄ¦I+<¢ÜLR8Äpf÷Šç+Í=¤·FÎà+YÔÎzVÎÑùÍÃºµ
6pg*9Ì¢Lq>«NÕ„;,øTCØ„RØİÉÀ&¸]ÌªñÂ›rQŠŠíR§·¥»º6E~EüÏÇ9w6Ü­Öoõ¾Y“|é™‡Ş,{|vqg§Òg^
ØJ6¨Æ­‚Å ‹¯U\;›Ö&]5ƒ0Ep@ñ
–Í/°ÿƒîm[˜ÍÒŸ"¦ğCêKzlÎlìè«1£\¡•YHª[HãàššîNO¤÷ö®Eî³&[İ2A]Y²e=§yµ‰ú‘{íPt¦ûĞ¤c*~‘
ÓÉŠ£[ÕÈ¬uÇsªßFS¡ââ f:b™Š®åäÓót‘sQ1‚/¹€;/’#&€«†îŒKAØ&"ã,Ï„œÁÄÛÅ€ÖÁXG²/cÿÌ8Ş…8kX3©ŸçøĞ×yu“‰ú9PùN…Áã‚I ×ƒú’éöì1c\`—5•ºÁq Hú—¦½K9ş*á¬\N6vä.†fKn·’wÅÑ‡µDvÏ' ­a<·ÛÌ\îÖœU±E×µÈ::¤è*Û”çzxÌ|p–´Ë}ªÕ2ƒ«‹máHş›]¦ˆ‡,sùBÑBi·ËÛ™$ä’4_İcô',ŸÂ‹ü†ğŒ;0É¬.YÆ: 9rßñváÙf‰±O‚Ÿƒ şñ´uw¤OÎş.’1È4‹lªúk$3†™iT`‹@vj³#%PejÁ–ÿ¹oûÖ¦QéVA.KÆ'€°qŞŸDŒè¯ãëÙªZ·–‰Nnšõ³’İê­¯ø?J<ñŞşo 1‚ÿZõ—şä]ÙzPUøhwdÑ˜"‘Ò@ı‘ZiK˜÷K©¾¸}$Æùƒì[|åI%÷ñã<ìJó*ì{*´Ht“.¡{{ÅÜ²™Aõ/Ûp»§Œ‚
iş³(ÉS³êu-d$*šu‚¸[İCWpEP9¡½q¡İW©q6>›a™Ìû}¨‰[z¥| 9k\BNñjöE›²H”Ì “Ï“ÅoWQ!€.pÙÖêîõª×íœtî£ ‡^´5|üğß€åzµ¡ĞhX¸h÷Ì)Ùb‹"Ì}¬¹İŞÓğÓ‹NUa¢8“Ú+a§˜q»oÓ–ï÷:Zo‡şc¹
,œÒ@şƒ(?ê+fB½7Ö#UBŠÿ01¸ÒŞv‘ôÕqÒctx•I‚Ã1Åh/§ı¶@]0¯ŒeWöäy<ÎÁŸW³Äó¤‚¾Æ—ÛÙXOŸ¥æUÁĞ+XÂî²²rá»AJÏ£êŸÖó©èŞ?Ğ«0ÆB„Õï«ÇËrìÒ7F­“—HB{Ù’b~Cù<1~Â kRF„OÙİ$Ã@,†]7½`Ÿ`J³´xÀpnôR5}>ë6’ÊS\Xv?©¢rŒÂVÿ¦\ˆ<·]	&­Èdâ%™Ài)tçÔ5k»ØB^5÷,&VU?‚çî´§F_  ™å‹˜ÌuÊ´zª„ïvÁü¯/6ß¹Å¾¶´†îzÖL§·U îzog¥ó*Á[àúf"lı„‡+Sš¹€BmÛÊòÀåéÃ ücB+ hŒÌ„ ©’* =°à—&¬Ù<3½5Ö³Û$Àmz3Â?¯-¼)?gè^o`†ö*·ëÑOÎœ%d´•„íÊ¥éÅ¾è}Ù­&ùƒÔïõ+$,“!:[Éš
RI×Ãfãrú
7Ú‚,Q½"Ë1dPZõ±Çã‚]av‡…ê/á•ƒ´(‰yS€ŠOßK‚d?šÒÉ2ï‘L1ÀáÚq½Ñ÷Bàbw„Ñö<¾Ö4Š#ƒ®>îş×Ú;£P·%5İB”;–k’?8Jüª³¾{k¾³ÜÆL¹}ø?òïkÚ¨kíÇ
Oa¸Ü„'­OÚ0ŠÒ¿I&Ÿ”iô¢ñk+G™õ?ôC²5Y`ŞöÎ(ˆrÂ˜õ k|§EGTªíµ0ıŸŒ½K°Xõ,38“ZD?ıÛÅwPiØVÖCoQ.µÅr‰~1¨Â{Ôr‹¤aÎì”s¼¸ì½Ñ[p{Ú`¬²ÒË¡‰`”İ[yÆ%éwd‹ş·QT`Ãğ>ÿ`ÄŸjâõM¼YNÿ	-A4·Šâv÷r}L©È=œÀbÇš‡Ö'¼˜o¦{¶_K	ìãq[²Ôf…pW£—„ÌRÿKŒø¤&:ŒLeÈÜùSÚ[	i.)²Ñ êj[Ğm*zóúí5¾RK5>ìÆ¬ÃÈà_®ÖGÔª"Ï°7uçøXÓo÷
åµ·!¯G'’ğöª’DhI_>Q£d|;]‘¹|ß÷sŒù+yä€«ô•Fµ¢³Y¡Gÿâ$ ='…£üÆ³?Ü?1¦éô	˜ïb{ÍId¢h¸†Çi“æÚî¼C&ÿ]˜G9»Ë½Ë@@×(²ŞËõ<œ÷ê 4iÅşw>)ñ§eT;”%Há–™ë
`+ö° ”ÑdZr¼ËCGì$å2\6lò 	N³ä-eL«ª”şÍ…ÂÄÜt‡…Á«¼*À",hİÿŸãsjƒÛJqE“ÉàBm|†\ªé²y2¿7•£Å©^Á·Sá©¢d:>ÏÿöZ²Šê»M
uÉIİ‹fÂ‰ G7soqÀ÷J7I¾@pèö†ªÎQŞdU]©8ˆ(¡m/œ:õ81^=»çtıeÇ¯óÉ‘û?‘3•!şiW€¯ùÚ£/Rå x;*n:``¶O „/0ş³`°=yª’È~şËë­…G§A[ÅO×	¼zQ"e¾¡Û„ù:xO¢—WrÍdÄÕA{Ğô•^Ä‚8|~Kù³²»S>B2‚WŠZº—`ÌĞ÷m`Š¡^¾ôöQjtG=_Ú²­E¥j+‹0±W€Ï•Ÿm‘{wìïrÉ›JY~ùèû<´rªÕEpˆÄ+Oî:ò¶7¥øÆ1œx¶,)ğçÕ8wÚb´y¬¼Ûx*	ÊÛ¼@ğØÀ >ú»ú?­a$ë¤L 8Úìı2õÈ†aPÑNB.ˆ˜-h’Î’u—y­áÛ5º×à ÷•¬wwÎ%Ä) `|;®á¨İ	õvN2€¸²q£¥ç_)TM‘¸I0zÔÆÄOeÅ—ŒºùˆŞ‚õùZxæôU÷mNÌÎn‡mGê~fÂ¯<ÿ‚ËƒX˜è¶Ç_Äyê*ÛÍÃÀ`¡€ÿ¾}"sµU•7ßœ„·É£¸g¿¶rì"p:¸Zõ ‹ËÁãÒŞâö s¯µ&D¢–íÎ<·å*ğê:¥B=G0á~­ÀjAk:X>6­¯:¨û”2á–<ä#l°¬dWÏõEåõ·ó*Ëï-(åI%Û'•GV|Óü°®Î#QÄÌ;QUat³)½£ÁU|@„Ìôo5ˆu•p¥®•P	¬Ğó¨!,0~Ã/ÇßİÁCù¬Kï#S.vÕC’³œÂ”×6ºG·&î1²éÅô:İ/Ò†"*`¯;±YR¾ŒŠÈœø”)!.½Èe8ü	ÙÖÓ‹¾Ím §!Ùyh¨!À7Ğ	kl²YÜ\N}›×@´;LşLhÓ{Àn³™oÓ7’ñ&C‘mOá{Üââ¤Â[ø!Ë¢¾Ì¼kŞDvô®j÷“Æ…e´(¢.ÕT*–U:´/Šé:½ÉqÇºqxÑ¹ >)B¡S“ Eºkµ8	Í{ã·Ìq”ö½ÔÊÔìº£~Å$O©„K¨ÌƒQKZ‰Ô±¿L|(òÛ¿™ccg‰}xNİé|>Xo=È˜ˆjâš¡­\?0!Ä~b
äG—EQ¼À˜€mšÈP„2uƒÜEF‹aºKFàS¦&Ô,ËñÙân]º?u§W6Í ¢¾†íï«xN_Ú§ÿ˜*>ä„Ü¨(ÂîÌò<œø‹&ícŸ…–T:jŞ¿gıÀõ©Ùw†ì2+šŞwË(Ïaô™Gâe9I9ÒWI[Ä£ÁŒ”¶„ÜÉHÔ©Ê”šìBµƒÌL4V8à‘
Ù+5>NÇõIŞ”×h"ì`ÂfGœrÔÅ~ë(à¾ÚbŠ;„N¥äÕ«µÀü+g•ı×z?5sT„·¸“×1èb÷;$ÙRÒ°8-N½VR]Ñ•¾$§ÿ‚äOlGYÅÔzXÇµ6áD‰sŞâE;”Æ'ÈäÕëö˜¼4Ñûæ>ìëd©FÑ®Á+=™võèò	§ãQĞÑ P{í%„€<×êßÄ7‘Z…æYı}À\=x¬JôpRî‹,wénèÚûƒ–Õèbß÷"İƒlznHfï,mH¤qØLğ—#½Vn]KWâ~èI	~F\	ó4’şD’ô‹0ùİÁ¶A}ë=KLFö¸ ÉÈ‹ßŠş—3¿lvÆ²BaÚadÇfì˜ÔÛ÷ú¹§Ê&Ü%4ä´˜Â 2"¼ydÛÿáMIà‡#x§©.ÌJ(äÂö›v¨”{‚2á&´.–âş¤ñ5pÕa¯eîË*\N„P[5Û ÁÍù„_ñ¯ßÒ<dX…>lBªñ©îQc[EqúoOÙ¬cÛz}ma²™H Šûfd=;ı†Ğu¤¦Ëp^q7¸]|4*Ì ÙØ^@ÀFbBm}ÀS|ŒßÃ¾³ÿç¬FÜ,õ4TÜP¿.³ä›ß1(7Ôç…qŠş«4ÅúÊ9Öv9–dkUS¹…“Yİ#§â“çÏ×ÿÜ½÷ûa”O/iä†½è_ÌgsÖ@œh¾eFœ@'á“tÃk×9GJÔXü{)aÑê-Ğ­?¥™}goMR)br=1ÖöpÇ_^a±M n7n¹h“¦ÂºÛß#ÇÖ{ùı¤úÒ$dæ!öàßÔôù•²ŠH/W-Î¥1’9‘Å‹VƒU;ŒÔğ‰VaÑİES`ÑJÊÍE˜³^¿qAÓë_ºÄ¯ş õXXzWı]Æ´T›¤°åWºdŸSTl–wë¹L}¢ÑÀy$øˆøŒ"Î“);ša\ôZÅ11AÅüæ ËØa­k²V_TÛŞïå^‹Xi21" Òm)ÚãÛH_2+áçÛ¼WF?`ªVîB:^ÏZ-ˆ;*'Z€('{ÒfYüÊ‡Ldû@Jæ+Rw«+ÔzïËåOÇ1Ï±@7^±­ˆêì±fŞ:É'èñäb§?4–DŒŠ›Å¹  †Æ¡¦©{Î8;aÑ™Z±YÏA‘	ËCw‰¤í¤GKwÕ9>–Ë­%Tü"£]CWÙR”óM")¢ V2ƒX>¿ò&z·şr°ë2áMGÆ$À¦•
EÁ·oœ’–g†›êóäZIği¬šş·EàV¯†öOÇ°ä¨Æ¬İ
)aàØ›J×Æ<+ßàp" WÔ˜öÕšîlXØW™Í±~,òmpü|t}á8ÄéÿeÙ¨öœEJn!2BŠ›x©Xõ?|Ü@»?!ÚìW•ò„(Yö-"×$«î¡­ªA·ºî´¹`<*~ÌéÊ‚–ğ©ûHÜN…¿z…d²îÓ½rÑ–b¯b…V)^kM–Ùb%ºtôÅ½<ÍŒÎ1¸O¢éÒŞ´çº¬±Eó³Ñ,›Ğ´~³0˜¨şjHø<°‘È(ïÇçÌ t9£~lj¥IáCúÜ/(?Jfåûÿõ£5‰9xgpóúaJ8y|icĞ9ñ"Jº¯A‰ªğª |·¤ŞÙp9k8{›Ùß©Ñ|›ï[éï4N!_Ü€v¸PêÁÔå0»Jßj_ˆgÁï°˜GoÙ i°–È>pò&lZç>ÇÈ+"6ÅåÑûş¥•YÙkkù5Eöl›Åwr¾ßFR–¡f~-Â%ño˜²³ÃšÂ’%‹-å #ë‚,¦0`ÜòEgSUŒ]°»Ûô2²FŠğá§ÕvöıFñS`zÎÖEÓDdµ9Qº†Àñ½Ê3Ùóûğ^€,\ÄBß«c“NTµúøø[a²CVÎMñ8_epaŠ…½£E¢’Àck»Ôdp]•*`±³[ä•–0”Ÿ>êÆlØÔ7¿œÌÅ`ÄœÁ	Ä¢Côƒ´C, hş¦N˜|ïk~éƒÑ„tHöƒ¬:óUÄî½M}Ñë:9±V úÑ¯5`•lìKp~]a¿ EÌ‘;1Äú¶à½éÖH»2)C—Ö@ÍÙÑÎ¦jÜ,>nı ÓT²YB-	ŞÊÌ³c˜²0CyË§§W¸Àiøg âª7 ‰ıí1óUş´´óKš+1«ú°uçJĞàô.ı›W”¨z@õÕ¦=wšfï@¾>Õ…×4UÉ¤-¬cvSg¾ğuò8ç {-ğÓ+p>n¬ÁÔP¯Ù¸,ƒÊÏˆÚàîŸÅq†Ô „ªgN”«|tà‡€Ìb0‘¡÷p?²ˆ¦İE…JPŸ!ãİù´/ú1H	;`{~Fá¡f‘Š1ÿZö¶È™ÑEß5^0]Î„NÕuÛ-oÿnälm?ŞP@vôª8Â&"dg¤ÉüôYj­ĞÔlIâ:¦–ğnaÃĞ£UÊ¼æøû¹ú'æ¿í–¾ o0„<]%6âÿ‹ÈªÏån¡Òwùµí§4 2Àd.FdÁ.Šüo—ÇFr	Â×c¡pùÊ0¤ü_ 2.KÖ€(Ş®²Yà¡¡$deå¤û)©æãeX#XèfºM‹ ê®‚q8¤\Î¡ÖL¢V¢¦êç_4´&]]¡àq03®q}²T·Eq®e›«bkLB®İ²Æ<â€8Æ,tb
é°?‡D¸]‹´.ø³áWö%l£å!×âY„–Ò¨+]ÀEähö¨ÙÅìñ9¼î,Úz.>ñéITÒ1Ex~ìãÌŸT«•…îâ¨&îà‡ıMÌS¥ØU!eöë}ĞlgcˆvF¡#eV»t•\îŒ•}zt?ÓÀØBª¦=2]Aª–LyÀØG€;‰]
vî
("R/ÿÁ§‘l]Èa»ºlKo&€äû@û…|OÛUøp'ùßF6Ğ²q¹ıÙáúËçRx¼¬ÎŠšmÚ×Yoe›mÛ{‡`U„wdIëñU4>)Şê™:HíTª)<j´HfÛè s#÷ ÚêsdAbÔúc£²1%íÖ€ìòÆBv’¿6D~j2Ñ†VM˜ƒ%íjk~àÂ¡YÂæÙ‹•‚ ¯‡ÌçÅûL[qŠ ’ øŒ†–Î‰§'£ÑÑ¢-<Üå*)²z¤á¾†AĞ½+ƒ3D³¬
`Û0ƒêswB`ş d‹¾±JÂbœ}êí	Ì?'	sÆg1·€‡ÔÓÏqX©FÎ2ÊNGş )¨§m¥|ÊYwõ4†èqõ±ûÖfòÙâÖæèMo`Î.İ‚r7ô¢aĞ°çÙûî7sÿuHR¬LŸW#Tzß–ùÂ
şp —øR–ÒòÄæyş>ã,»È¸‘mwCßÓ-XÒ„Ñ72ÉxsR“Ş/æÊí‚mgè]åß51Ó>1pÎ¬=»_¨-Ö‰IÀ“[˜¯ƒ¾•ºÍ# ”jàöøñy6Ø4Û…«—İ••Uìd±‡Î2C&£ÒÚğ§€ù‰"W¢<Jé˜g%›Á³cÊ†Y¿æC\l¢üf‹cŠ1›åìú™Ö´Š-˜f`Ÿ9Åİ­Òsõ%Š†™¤hÑ	Î{9O*3N·ÛLd
‰‹Áƒ×Ãä5ËÚİ·OÚù éSæª\ÜTJÙkñ9w³†«ài³òhµ¤–n$Àß¾õÆÀr9.ÊJ’¬Ø@€Š*G¬ÍµtHFóÂCš÷°¿Q>,@yw‡P³1*èChõ©ÿ×¤q¬ê¯î2OW$šÔ³¡¥
ÀéÿQPÑ'_½ƒ‡Ÿm[û’¬WÔ‚;ó„,Æ¸„wzÒTÏéõ/Íùn  g.HÒoœ›€õûõ9¼íÿ´ecÃìysî“H@R¿½,M?£üÏb¢à»]3(ÃÅ&ëËşİO#~ÙbÔ-„UiqKÚeÎŞïÚúÇùóÑÅ4Ö:~ÖÄA$9ÅtËÌX£'#‚kÇ‘3;ËU„ ŸHŞ067ÚfÔ%6v²8Ií1…ñ*éÛÓ<Æ˜ßuöÂ9zòc›ÊØD[ªZÔB4”JşóS¼íâL|w%İ²å/†”¤M™kNÑy¬FôBuî¢ÛtUûS2?%î¤ÕÈkÍù¢kyıçA¥ú‡œU"V8±#—’(òÖBúÄÏU¸‹˜š€‹'/÷àù+“ûµåÁˆÇÏmIØV×´4_ï’¡¥ı˜Í°ôXc%,&¡¬#Y¼9Û‘IÅKU›¾Æklgä-Ù2‘TÇ…”İ£dUŒ7ù7¸Zh€µÙÓ™u È}g1-Iº÷D€‚ŒGÊW'Ãş1l`*ešÀˆÏ›ƒíòë‘Â_f‰V)öèëº°òƒŸ¾ÄXü×ªšôğ=”XÒ”ïŸ€a%©Ö½ßPY3KÑ•s¨UîËïPêåÄcÜ¬“ó~ß·Æ`QÕíü©±¬Ã‰Œî;P–%±FÍ&a «)ÈÑ\±›:dŞ5uwPÿåóJVöPH¶7¾×V‡^:¹±5çyH~‡ÍÆ8'
Y%€L½eem»*ş5,~Ú+[0	b¹Âù%
ñûGÀ„‘^›å0Èt“sã@çÍ‹¦Œá1wè=¸ÛrcV¾ü8uÕsÒl÷«åwm7 bÙÕütvç ²I#kûµ…Åk²XÑ {Q°ŒŞ`­ŒHVæ¶‚à)Œ·ÉD+º–EUÉùdÿ¼;öúÔ×Ÿ4|ã°$ÍoÆkn!YÈÛÄ˜±ÉÛk»Öû\Ø¡¾V-&C5LûrÀáCƒD·H"&V)Â´”/F×ÆÒÉÑgmQÕv“jIÉ¹ÔŞ÷e›xxË–ûbğ¦`­†˜dÉ”á#İë4Y\Èp¤(ˆ¥/vÊ5 ³u¶B¦µ©›™±â&´} L~¥tTT°^ùótÎï¿—Ô0:PŠ›ª¢î7nn®ÚÿÍ9×ò•[I^hY!Õ`Â³ê´ëI=î¶7WT?cÈûÇ%ºÚÇô°0ÖÄ´I:IE™d,¨¬ÂsI3‘Y NátˆV“cÚI]ô„={”aABŠ£j¶”Ò(<RTú 
fsˆß‡®£wìmAüõOrpŸZĞ]Dâ‰¡ClJ™{ê³_!tái$AS:}xaß˜Ušc~$`ÁMóÍíN ¨"ÂìŠš’:}Ò1-:l$4´(K•¬ã2™ıJò±v[Zì"£ÒD5Ğò <g¥QÛå¾Pj<6.˜Pà¤¾ÛÖÍGñlöŞ¦xÍ{QD±[]ïËOq°µ|k·)®"ºnŞ=¬KI¤­èh›„¤~9¹KÊËOhµ-ç4NÅÈGï0»2¼ï˜4³}z!9(3.¹Åõ3F‹—=ÒõNÄ®û|åbÓ^ÂáÖ'³QŒ7vÏCr³œGOëNq
İXi¨‹—0xİÖÃAQvÊZ¢NZ²v¡S-q`R¢äzc…hAùôÎ“µU†÷nß„0_p¾yul#ù“±×ØwG£'îÓ-Xáu.F{úñÄÛ»j^ò>:Kmï¡¼Â™ ¡6š•’'Â¶Álà2ìÃ'èOC‰Ÿø9X…f@>ïä–„„İÆR*Y
Ÿºÿ$dâ^lgÛ·`Ì„(5ía‡ d8¡£Ğ#~IX®/Ò|u:>]Q$nK'«µ£w¨ÚP«;uÒéIpxõ3ªÇÄ·Í£=œ¥„ñùmÜë^w¸šë†Û÷†ÿdBç…IO)ø³îPøša§(GC•Ñ*£xk.IÚ¦ÃcB"Á’ºNÔ`^ç!ï}!)ùóaü IØfëcº	3­pÔR	§¸Ù-ºrdeUFÜR³!Ùˆ¸`" LÌ¿Í7C^°!…µ:%A¾Ô	't
|şÛ÷§Ev¼¬˜÷·ø·g1Ô’ªGá´S8ü¾‚Ø¼4½$É,r+œºÒkñÿX´…¶·W‚O,dÜr3ÚıyçöYµ*§ünŠ½G>îTVú)û¶ÅÀAjß@Wt¯™b}M,é
Ş=/EF|Ì<=Ü6‡Ù ~=ñõ<ø9àñ:ògUîjôÿ"müëã£%ïæƒS"NïÌ§.©n–É@Îóúâî›œ!•BzZ=G°~¦©	ßÁn¬OæÛ«û|_VÿêõĞtg4GÑ¾­"Hh‡$KW¥ÃÍ0}n{ca°nå6#Áët>}'EI²[SáliäÒßM9‘ƒ$bÓPß´é®5êÊî•vŞßO®4}ºDúÄÖ÷1tûEMÒ0”Ç$Ô‡„¼ó¡§ki‚ï?ıÔ­ßì+Şš~J­ïÿ¤Ë©ÖÿZŒ¸¹íË	îŒ’ú>È´	K*T‰D"b<ìtí–9B©µ'K 	´şå¿71¡HØmıÀ[¾Ù~š§.ïE³;îeè£ëÕî<J«jQÖ~|ü2Ã+¾m9ktåæ^FŞ2BÛñ½|7t…Š\¨$/T¬géÔµJÈ3¾› ¤\P÷—x8Ü‰ö?ÏHhÔÒ_1Ü0Ñ2Œ	°ëÕóY0|v¯ª)c‹ÌÜèÆR½¡äÒç¹;,ªãúi³olqÓâ=¡¸'YDƒ¶WŒ›ÿh9ÁÃRğ!üÒûª®	fP–Ÿí«ë-àr–Ï»Ú2p9+EÖJàµúóıj eÛôâ®\j÷‚ïM¤ÛC8š¤_v™ÈQ½¼QäæùRqŸ&gj,ûçëúl«v™.Üa‚š®ù‡âÏgöïrIè™"š´÷êØCøPåháR÷¼*'µšm~Í®ÔM8|N79y*÷¸³ƒ­1é–õL*\±Xû?Ü +¡¬}5»˜C,ˆ²Ï!†ä“a×´Û{?Óñ9W'l5¬×7>ê¿µi¶ÉVoœoƒê­‚;qF²­ßöÌ F3Å•1¾/œ
ğái”%©ëµò+6£ìÁc'·tÿ‚P×€³M:‚™EûG
IÀ>X	*‘"a¯ş´MpÀ¡Q8üuS7¡E¤¬4„¾¼?&U¨%°ĞHjDµñÛ¼i”xâİ¯C&¦´”¿®„&¹¿ÀŒİÙ]" ˜O¾ì#´3¤Î8QŞT¯±{45Âo‚­|!œ\MfB]÷y‘ét‘3£Ë²“Š'´&Ëª"›‘åİx‚+
‡L*&Lo7BD¥jö
G;»ÄÁ/šŒK£ˆ6ï¾	.âı­Ä¥¶ëÃ¾Ñ6IØ÷ivÂğ#°(eÀšsÈÅ¬’Şiä µ?İÒ6«?••r·pÊ.3Ìxóc7ÿ‚ÙK3ƒyÎ´şiF/4œÛå½tEtÔØHz»&Oè¡Q‚V<o^í®	Ô¿èØD®*ÎæÈlıÄ¶‚ã‡z}\˜z`‰ö-¹’Ãã>0b@=@§Ú×‘`\^]à®‚"\ÀjğaôĞTµx:J	„qÓ#G7ühyP.~‹÷—¸gt/°ŞŸ‘ĞÖ®@kQ\N÷[Şåé™:›ÃÑúç*¾›oH>VŒ@ÛxÑãcïjıÉÂØpí†‰ºÙ©ÂŒ®L¥N¸qXåQ_såôŸâù}ÎÏ‹®ŸèŞFÒ V}£	C€Ğğ˜x©¬J3ß?u_÷<ƒ­,îú …Üb¢
%¨«ôº'1Ekš'êàó\^–Œ‚)±ê*îösæ0òs¬Ë÷ü²>*ªòÅŞ3Æ=+‰¿Rœ>1\‚c­´³Ë4Ê=}@I¤ÜHFS¤òpW8œÏÀ,7[Å€±'mš–·“Ôëf-]Å.–âmåÇ@¾DˆÀBÁ'=n.ì´`¹‡ÀzsˆõS…û^Ö”DßDœ6(°qî!uKA¦¦¿OGËœp4$ J…=0r¢±<K¹ÉG‹KËPÌ#ÓXÊ U¨DZåÌ±J4íçÔnšù_·SX»/ÑÛ„läùÈ6B+Ö‡ïL\ülº–Š$ÀX7Hò'å àÇ%*iPi¾Ì^£–ÁãŠyöÛHrÇ5EÉ860õ<‰:ÖÂ‘~ÚÉ›C	HDØš±°cmDû'qİRÊªõl¬§vGa¢Â%q©™Ôiı8uÁGÕ4%İ~ã†ggñ¤*ãŒQŸX­iúfbW&Ô!u‡¶yÖhBç9‘i²ù~øº‰O_ş›¼”¡Ú"P‚ayÑc¾¤¹o)ÎÕ1S>QêT(ÏÌ:~•^™Y1Å½­¹úÂO•ÊÊûa_‹ª1s”š²
IxÃ+6ùb_”©høo³}_M¬³9Şß­TÉÜ×Òğ$¥ŠŞô.Lk	Î’ ˜¢"Ë˜GÜ¿vw2ªàõ–>öÏ=ÖÅ(ÿ›&{Ä_"ÌªÎ7¦æ €+°wµ	gİ¼Ïà^Äíµê±Y£XTÕ´kÃØ(!Yş…s¶£U=vƒõg½ =uÉ 1AI³ØÄTŠÊPSÀšL¯ës	V5¹ £
b°%Q®¨_Ú4 yªÌ8¯s¿ éîÉYå/Å·®6áòĞf¬LYc«¼yÄö(àlRúgÑ.õïÃ“Ó“k£İ'íG´Ã‘[Á3hê„bªYhD¬Ÿ},n8­1½+fa)QCï6ãş"J÷E¹Üî¼œ)$¤ğ/ÙïL¥6¾ygÇö'~Bé„]ó+™Y\©ì¾ìR—+íÙ>­~ùY/=ö¬³z¯L÷óÙãÓí¡™>*L@Pzƒê&:”ßY‘7òCªU/Ša\QÆåx¤wñ~«™+¬ªÓuú½1±|É` ¯Ô­şıöûzÃ+?„Ä|ì2^h`„ıô1\²ˆÆëß”m<Zõ?_Á{iX€B¢B(7NC<˜·ŸXÔÂ-.  š
Êq8JGìÅQ¢ìíú¡w_ Ãâi”v³u:¬T…4R…)ö(FBªéê˜¸S±k²I)€ëbE«‡1üóalÒ)íé¹:¦pÒhLà±Ó‘LË6vèe~lÿü`ÿ?`iO³h‰ì˜²G­}7È•Z„‘f0¦n6§©®”Äî»¶áM±4ƒ¿­š°ó‹åÇ´‘ó6e,ã8d]×¼)ŒüšòM™^@b>ï¿%S'»Ô>mêá¬‡kÛìKn¼1³úŠ´Ø ÕÔ¹^Ş/Ë—g® %uÃƒ=ïÛ$X)}Tÿ÷<(û1ÚpÙ=w»ÇYL•¹J@òÜ'€¡.À@ä±µGØƒk—M
ëÌŸàWáÏ÷ˆ ĞéP€dV±Á†uAİ4@cûşæÕlIVö9ù)œ;ğ×&üİÍ‹I¶²q·²+oHÎn¨‡|ê¯T´õ¢H·zíòş!J¯ÜÏe\’ÁÇ–-(lôŠ#²Í%ö:ä9¤…Vé$tûHÎ¿ğ&¯DWB£üÓGöñº¡¹°ı|/ºÃmÚ‰…F!ò­È­=wšZÁ|3åÃE°’wÆï€ıÒl`I±¦ŞĞÇc“€º`±Í’e<?­‘‡r±ò}pgøÓ§îé›â?ÔÉ«G:K]˜—Ÿ¡ÕTøó5xş#Ÿˆ`	È˜ÑÜà`©¢{¢‡v&-p™Ç§
’oïA6|<Ïbõº‰0÷ğŸˆ¨ì»+>ûA»Í3†9îgg‘È@»ê=’4—É™¨)IÚ`5€ÙHä¸™æŒ¡š6‡Û¡Ãl5¸…ó¨5ê…Œ(˜ŞÉLa2åaûg”  DdsŞO+ ¨³€À’jm±Ägû    YZ