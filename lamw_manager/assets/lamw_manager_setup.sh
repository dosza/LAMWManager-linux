#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3595563215"
MD5="29e4627ccab238702fe4efeb32d010af"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22604"
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
	echo Date of packaging: Sun Jul 18 03:58:21 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿX] ¼}•À1Dd]‡Á›PætİFĞ¯T ‡Í®N£Áç+@—’‰ËŸãsc•¢öÒåÂÄÏXÂt[•1á‹Ù»‹ÑĞ\Ä…K‚S=2>ïYFõéÆ/õáwM+F/ò	Õ¦¹ß¿‘3Qœ4„[¨ªhµKì"o:õ©İx`7à€£†ƒ-¢ìµ0·'&šbEY¥e€9hçÄG\êŠsPÕ§[®àÃrkC1Wz0·zEº@_ISyt=ß“Ù/­uëÜSxHéŞ4îLDåÇÅ‚ØÄŸ„üµdäü˜†HóİëõåñĞ¹Êë³>I‚m3Âó¼ì¢ÉMÀ(9i4yİœê¦ÊW,Ù¿gHHäñW¦Ïaªè]Ï
påÀ†W¶À¬ñ47ığ|±)U¹Ğõ1Œ»¤GœÏ¨myS}±üq•Ï1ÿlX«ëÖü0¦²²šv} .À•ÄÒE2‹ğ p EÙY`ÔN
UO¥ÉÕ(õ„üİ‹¦§%Î+zùË5û<Š&ÊäE›ez	@Ì8ë5¾s•RMLX±PxrÕ3±gzÒ1‹²ÏVê§)'Ù¨ÚYUï„ƒƒz×Ü…Û3ÿ†ıMÆ
­ßy§İ,L·T!ö[¢„V‰Ê–’ù¢¬ÛXŠşˆB•8—²Â
hâ¾ æ˜¬v”Ô¬èÕİa›
î­ìD£3N¥‡wíî
=Ù[€Ä±–Şÿ
˜ir´ˆ~:cZÿ¤b8û­6'ÅÛbOªlsßx´¡‚,kB£mG4ç\Æ*öNä%îª§‚Cåú1•@~,ê0šÇ˜İNça} ]øóuN¾Q)-l
Fº¹™IV\m³ u»ÀÄÅ±ÃÑ#—4Õ²lÔ»´›¾±¹e"¦Oœã *¡7æ ŸMÊ”kdè‡I›¸3ôÚK|ûkØí*²»©Øü¾¹e{Ì²÷c†np°'r}kSıÈâƒãs†Æ¨ ÀW³5ÅŞqZPğe«2&€W£:ª½)Ô—r¼z¸ïÆR»Ò5$@]±9ı.fì©Ô¡a±%3,ĞŠ[nÜ½›f„‡qöH*Ü„9cÛÆ0åzÇh£I0®|êi©S¯Iğ¨fñUµü¢Ëò˜G+'ŸÁÒÓ±™£ƒİ³j8¤@¸`#¤t$´=–Š‹â~\¨Î¯Œa½p£\ÙĞ4ÀØPüœäËİä.ÜŞw»PºjæıÛˆôbta•ªnÑa,GÛàò`UŸu©9/•åç9²˜
‚şFøÅÉEÏ7¬¨``·®H³ûÊÍÓyÊk­,pˆY“zòÎ¡…CIÅ…EõA*I·Ğª’Œ“nJxf"ğ¦ÏÙ×ïÎ»ÈY›ol{I®:—C‘— :FÆÌ—Ñ´¼¾ÆE&hô,Gu>t6Wv V»JQD‡Yn,¯§±´7îÏÃ¹Vk7¤ˆ(’$Æ–ı£ùó6F4óµş(á8
Cwo&VQöÔ.Ê˜Ñ³Eí0˜°¥K´B7tñÀC›|"’ØïoÕ£Ãæ¹ËäXuŞŞsÆ¸İNhº#×’úk;¼™¿–(Õô¥cÃ`*½Óxr=¡p	tÎä,ªÁRaw¿#qY#~t¥gë>æ†t&!­·àë«a,òœ½LûZÔÈbúš¢R$®ì&'Pì'iµ€dÌ.2a@Ÿ´?~ØXæ¢i_«Ô[-»ç8¸€8Ù`>[,AÙ¾AóäXìµÁŒ!NüÄ5 ÿqµé2öZ®’'ÔÂu ‰ÑmáåÅÂB" ¸%+F$}EªCòk}ƒØ¬#Õ÷m;tü‰Sı'ÿa"¯ì¦âó<õ×é‘„J
{5]#ÊJõu‹H<‹…¬µ}3=z´E+¢™´n¥”™ÎªÉËÿ¦ëÔ‰Ö5Á{‹Ò$>Ô=^"ß@¹(ğvUÎãnÒañhi€Ö²pÏWí02ÍÀ"_¥Õßâ?.¶¬
T+¶•9ØB»¸Yå ÇQ¿¯VnwJ|@Y9¿Q:´#ºrAxoì<ÔµˆÃÚXÛºPDìòX Ôäm€iq˜{ÈŸü|P&Œ$›>÷¿µÃñ{®¦µ"0â0¬ÄƒÏÅ§yÒ@å)ƒZv°ĞTÈ
V`}<aà—LV^Ìú«+ Y·Uí‚>…™xIƒ,RZ­óFwÔ-ÑêO–úæçFĞEaãë-‹ºPx-&PPÀ²pC;r£;ÎyÊ©Æ±é
5±N^ôgÎìóÏt®êS³C‹ùìn•QQî&TMŒ×¼˜M@Vf7× µ§Ëæd ÿõ@;˜pq°1)lÁ	å ªiN‡9m” è¸Â=Ö¼öã˜¾,¸ºàPÉ¢Ÿ÷¨ÒŸRmÎ¶;<¸ä¯Uat?@şÜ?ôzâb—4mpÈB…|ñ2#It\·,ŞÙØ‚’d.AÁ6şÕ
E±;á¢YU‡İİ\ñD1ÙÊ	¿‰@¯]p;å£OhB×Òš©:ò–ÂÄT¯4¥Ú3fŞqF,·ÿô,¦P$xŒ§Ê‘€³~öª)±¨_øh¼!s+9÷ÍlêŒŸl¯o²àsu9ğc|¤ø0ÁË»@iö’tKé„(éÕ£Tˆ:/¦]6Ñü_bûşV=q®Ò£äßğ	;ÃcÂ¦ºVLæl cìo’ã0l†C©Á.¾ËMË´QJë&#‚¸öÒq_Ê7{Hÿ†P_2#°n¸!ö£æ„Ä}ÉÉ^Ü¼öâë¯Êñ`…#±ÒÙÙ¬^/o"¤dîn 
•O´s¨ŞÁ°ê®­³ÙÄO<wqf7ò.^ÎÄ5¶%¶@ÃkİªãÔJDáŞÆ[Õ¼X¯ ıjr†	¹£PËn;|oàÔz2R™k>$—ú¾îòl&‚P{“ °-Ğç³l|Û ø¬½dæâA˜-w‹Ğ¤‰NÀØ»ú¯¼Gfy‚Îà5í²ßqÃÏLs?´éDcÕzùHUıÓÒ)*0õ@k°{µŸÀŠ©X/DŞ[{9>FéşV5×_Ôane"'ôYé¶ÛõÅÊ²/:™ûê¤%X†Ìg>Áoîœ}æûr|gA’#{|¤á÷Ş#éZ}aNàá‚Ü·76TÏjJF¬pˆâI8…Òz1„'y«X*x§è©yf¡O1Mƒ,-ŠÇ.uòÈÍİ’çâ½ze¥n6»øˆ'\(jq`Œdø¢´(r£SD >´>Y};Æ7{†Ÿ?™M\:ÜgDôî^&ì­[¨¬¢¶n„†v¥â¹l£jNÆ‡ş™ş¿Ã""(í‚ÍHBö‚–UüWWÒ/±Ö‘sI•¾dø7˜4?tI©HĞ{0°hŒqûÔ¥U£;Â"išf\/ßşğEÜ?ª·I‰Ø¦=nU¼?ú|üğ%®Î$ 3PĞ[Î‚€˜nÌKOáDÃT]96D³˜ÅêP‡k®\Ó•Û^B÷c„Áó‚ªvz)´QjüÌÁRŞÿP‹ã	fåÖYu„LG×Ã‹,3©p+ô÷Ä†Î¯=/–HSÖ	Ú;KCpÂµ9–xÉ¤o9ïÜ.ËÑæ~§A¦v)ÊÎ‰æ*‚£ò|9t^­FC­ -KEalN°7¹çéçÎ‡Ò€•-œ¡õ<ÈÛë¤ó	øµ£ã P26/NÑ@©ÇÁÁX(
àó^êJ¨§f0‘³y¹Òuÿ:¹ñM"SFÖˆÆŒ~?4¥.ıÁ¦C¹rP€qš.­WûD×rR 8•'|emTˆz%çK	}F…cÊâ’Ò#¢¾*)P+¬6QûÑÎc8qÊé½j|dáSäÖl0ñ=±¬;™ãLY7¹Õ²(W¨¸2`zºü}5Û‹¢*¨`A¥Ú«Y¹…=Ìrlë³-ù¯‰‹os‰õBã=p}d=rr¤n: œM÷`üÂ™)ŠE
¤ìu™¸v°şp ¬kİ‰YœƒĞ¤6SöŠ„ÌG± ‘—×áWıÄ‰%ewÔŠlönaE£h­LO¯±lód°v¦9Ú^lóãP~agy)È'ş’]S_li‚Å”rr´nÍ…uP¢´PÆvŒ|l2x÷;À}²>ô´cØ*M:»ŞÂÌä]5×Œˆº"#¾}Œ«n~¶Æ\ç!1ù8§¡P¢ÈVŒâ ıAëxµ¯„Ïœ¿í¯ˆæ²HEœ¿S¾W·ı™ÂyJØÕÛ€³gêƒ	$¡X5Nê6˜…GOŞ'ë›VŞÔ~¿¦Ñt05iæeºæf)Ñ+KÑô~nîèlp ÆX5Ç¿[·„`ùò	…œ_Âp\õï»Ò1B—<ov×O¤.ı–Ó­ãñ(¼ìÅ¸—İËv¶£¸;¹>Pî'íl4o+²·n5>S|"ÙQs»³ØŸ ,D6…­PE[«KÉA!Æ«Î0¹õœ®Êyª8çqN°ª—^"L½Eîá@+ø>dæ©ÄCVKkí…Y«Ê 4x&+Áş^L$áxTë_ˆl:Ç@k›§T†2=‰Ytß26 ˜`ıKÜFŒøS®Ã]ÛˆaãqIO/aóÇõ3óëyü™a÷aKé´s//mÇñBU¡¸˜jxërXYà'×b±áÔ×XÑD~w‰ÉŠ^•w¯)†9§_ôÛt"ä¦æŠã	Ë9ÌBÈÅ¬¾/»J˜:ß(²¥J£xOéŠR‘½çLüS;XqÁ±¥±d	Ìs\=Âíhƒ1N7giÛ¬Â¢AA¢¯k6Ê*½ï’­„VÑ»3#¦éftÃ/¯™ÛÂë–@ôF½â‚ì£Ğş6\ĞY6QÛY
‰G»ŞÌ|&™ˆ”¥úæÏùXˆU`«¢æ,$›ubôï&Ağ/ğÓNüÒ$­²ìA@%¿;.XQ#¦<‰:<i¡o; €ç7ÖPAÖï»))ïöi•(£DZ9ë~D†‹›—aB3ê~ƒèÅÒÅ¤
,;7Ãë´Uş¸Şl2ØÏÈšznz$şƒÏÔEû÷*ÕGµ^%
‰g`M*ÿ ¥}	ªÏÚ '‡…5|«ş'1º¸ê„Ãu8Iu7“¯÷‹¦¥§ÆXÄ¡ö÷jz„‡£Òçâ¢òp¬İ·]×í»·ò¥áp5÷‡±b3Ş»
ıWiæörƒ+“ÃS‘7tx³V˜¼’Îƒ$'(­şk"rø/İ M•=é±ºGa^€ÃH¡ºÏŠÛç‚æÓÕUq@İÕ‚è~j=	¸¹­ƒyìë/¼Ÿ còb*ĞI«d…±øIbJUœĞ7L±Y©‹¿ ×ªÜe{ æ›Íçp“ŠÀ9tÕø€ƒmºEßˆÙ¬ü°T °ª4t1HiìûJæËfQOŒGİë×ä8êæşîOÄèç+çK˜
•»q’^³•	j‹ñ½Vy¾ÅÍ®šz.ËŞmæŒ™ á8Şö¶‡8v†½UÁÛ}&‹|a ]OU-ËÊï¡Õóyyš ®Àf©^'L†Ï?ç•ÇãvUñJHî‡GvzdÂ\oŠ’²çáê"òƒ%[ÄŒ¡ñ¡AL	ö‡„¶[­m“ ¹¿pâıö¹¡ò°Ñ‚Úh-Ã4³B5ßAë$±÷÷8@+&QQîg…~ílÙ)¯ÿ‹‹‰´]¾Ï¶ş„2X9\-éëVZ=]"-„&r¦Öñü_Æ–fïam†j Pš¬n³Ò‹ÍÜ¬¬=ß¢Î–ò>±ù¯àÈ8§ôõÄ®ƒf~¨.:·©¬üP4è=vŠC¯^TÏÆ_é®¤Ö¬Æ´°ø‰]?£ŞaóHÈªz6‰O¿r¼¼ó¼H›»XsP¬ËÇHÚGRívšyR•Æ0>ên4¾¿ âwK¡æÁŞ7¡Øê—*—K[Êø	Ádfú¨…÷İpÈ¶/×í+ìÊü(èßİ"}¯INçÃ²j­çŸ.6ÏÖ;Ğ¬k×ú?œ7¥Â ™jÄèè=…Ck[¼ kco;C×«1\t ü @T¡&µ²‹³‹¦Ìr0Ãò–„mv“ÅÛğ@şƒÂ•©›œ  U’ç5ÎıÄz	æĞI<ò³¬ Ç¨uïUät‘6€Ğ®Gø¹Eš_U6ÛÅi,óhuIYæ±Jê×ÏoÜ®ğœòã‘ÍP†u)Áe.¬Â¬›_#m¿ëºº&s‚óNÖŞ8«’0rº¬»I¼R:Ñá“¼íË36ÆR7'²Ú;P„!¦$Æ4¾P+öÕÀßI
pqñwË¬µĞ‚…ÒQZLá© ‡İ-í|`{
óóÃ3÷œŒÑ,ÖãJÄ Öã\H„€ö«PŠ
ñÂ±ó³8Š°<±ìQN>F\õÚ LŸˆ ÊÉ[[¥)jÂ`Y³km€q'™¸ßT&:­nS*U“Œ˜r¡`æõ´Â]u¼œ@uyÍÒ[üZc{ËÄD?éƒ5SWï,Íƒ¦9N?°3‚z^ÕoTÇ4ô6Q×ğ%.âÒ°E(Àpãä$B±g	úeJä“!p/ƒsõJÙğl•ÏÚdiæÛ&!¾½@‚5£Ó‘jU›ÆİĞº’ß<ĞdCª§Áˆ:"ÂÜF]µ¡§ÑÈŠë÷P•õR­‹œŸ‘eLbsÅŸwtëØSÎnÙA0÷$ò0°'TÌõ¸¢,-±'ÆA!¤Ãşßf4UHŸÂMRçq"QÈà…,èá<,GØp›i‚±f|ƒ[3ÕÁç«/•î§©?*eD½-’i—„!sbñH­QEùÀ 1 2lïUòl•b¼âí6{BE—“ImÎYÆ«8,¢zJµ\¾âV¸wzyøÚ^RŞ8AËxáî…ÂLì|ÅÒ5X¦ê6&CÒšÅ#)ÏƒKu*;¤èÜ'lóÉ_¼l‰ ¥¶ø–S”X}p4_nÏöÖ4XÛ'bå÷ÅÔİ[Ë`Òİ·7–Ö~Ğo-„ë[v1mK(¤šiA®ã¼âjŠ ‰Ó™/´Ó)\‡¥Ó0ìZ½eLX[Nl±ª]œ¤M'Í"­{+?¼$©ßJ±«Ã”îuÕö’wf÷\©Ó.Î‰‰ù™kÿ'£"‚:prwM6ñÍƒO±Ï+éÙ‰ËêÂ#t¹GÈù „Õ1LPïÓàOuÍ"x­´OÊFsîf½¨ëäŠ pÿ‡ôeÅ8i^Ø¦2õğY·À»´DN|§
YŸ½éój4/xÀÚ¡%,ğšÂÈ¥ƒUÕfwÁ {Ï'¯“? Ã¦Ğò°sª,Ò=8 …EsNÑe¤)l24ÜópY\ƒºèbxçäÅ”Y÷¢A¨”uÚ¤6rVnŸÍ¨+ŞéÈ8„¢ Í ]áT =š­eÎîˆ
‹–¯_ÄŸ1úH!…GÄ,ôì[R¥vT–W mx
 ¿]Š6½7k,Åâ7°÷vür9†¹÷ÁE=Ö÷€¡ëåoìüª!ÆX¯P5+Ü·qÔ˜®ím&wV5ú~‚‰zRRq+–ê±h×©¢B1¥¾á2©ë²lFnS7`?P¿â²_Ë1Ğ°­L"$B*™Dn!C@X¹;¥„F
ª³$d^Éëª”|»yÃØÉ#ùñúûøˆùK½%¨²€6—•$Bÿq§ª0šs)%&ì¸³Xªs)ú¤ñ~Ù„N•1:­_MÅ¡†:š=k¼1+tšÕ^ÀÚY
µ4¾üÁ
1|È‰+‘ãï[„:È(˜ã«lëK‡¡È#‹“SëY©¥¯WZí+ßåÏpy££÷¿`û¿¡rˆRĞæ>_%Â>ãë¸WíîCË3Ùí‡¶8•Wu6¯i!cÈAFßByæÏëßïK1Ì/²–^LRš®/@Stş!¯I™gº:1:E«`9ñÔŠ‰¹«3%d¾3øÖ)1#^”ü=Wí÷Û}²Áº6š¥hS€Ş¹ùƒqDÇ+£#ï“V’ÀUa&<fŸ+-Ué¡3%ùÏt©P'A×ÃcbãXH†à\)^ó¬Ü«Å×A?ÿØê(æÙ™Íp·‰>ùQÖçLµ¯Æy¡/ù$vF'áğ˜g“ãş~]åSÍWr®jzU\SİÛDª7'¿ q!.ÚÍ¿Ÿîÿ¦-¼±	¹`ä³dPzé§k›Ÿ¦¤Àn
9è9{ëÚlÂñ=’ĞSpæ_b<aWKÕÜn3}ëÅ¶6ÍÍÿaıGÀ-T]d¥?é btÔ·ÓEÇ±ëˆŞ¥qN¢›‘Äsˆ`ì1ÀÖTõG%'ıH®ï¦PÒ¨ö°ôº=µâ013dêIÏ¥]M!•SH1gtÑş,ïj‰óæWŒç*İèÒ²|J	#/Æ+:¨—ùl2êO©Q~ÍÆáÇø}Ú¥¾:ğñşYuí¢.5‡ŠLV ‚¯96Kv­ğÉ¸—.ë×VOy6ÁyÀµö".ZÕÚ1»8;¬¦JÓ S³´{ëÊ·—P½£¢š!€ˆ"Ò}`Öª·èårÇ3ç¬úÛBÈ° 2ûóY‚µQg=Á"Ák¢ğşÊÂq¤ä`~[ÊÎ7‰EHİvjš-¹Äõ­ˆ÷àKpfìÃ %Ô;ìæ?­ÃëşU©RÁuÄˆ9§s@ïÑÑúïˆı\Œ[ÌE2_Ş/`gêGd9À5uÅı¾\,Ö6Y §ÚµŒÁbV¼9Uqoä_ÍÀñL¹ù!zn8åj<’‚Å‹}ÈYÈ÷çfóÈ­;Ë¥KŸ¬(Éps¨Áj˜†Ş”˜¹ßÌ$›P»ZbìLİ°-/Ì4Á˜Êu¢¼CKˆyE°Î;ìê(mÕj"»éRæ.2v'ı.IØ_Ùs3;…„Îš°>_-Ç˜ı¼			R'”(ºƒPp¬O}•‚|]«-—>©ºV]º¨bıi¿i1~×Ğ"ßVµ¶›±)â;æ9U¦zÜ‘ŠH1Ø'T
 ‹éÏA*!™ğÉ*éÍš¸îÃ½&+J ¢òlz£ŸØó¡„ÑŒjV‚8"³CÉç¾ ¶ÈKç;½Û©J
ŠCÂ<£šÚ4èp_
¡j“NŒXwÑÜu+ı~àön…«Xûë‰ˆVbÑ"JôÁHr14ÎRÒ“øj¥L\7K³:³­òla
oÓŸO|íÍFø­¸@-hh¡ù6N{Â i•9q÷bŞ™_›7Ë¬™9'xı_µRÑ\å{fÁ•„@¾%m’•Áhbí>PvÑÎq<›K™^*©V~
ÆÖ1ßÍórâÛ·c3Ğ)à1¶¢g5lâ±çµÔ²pëáW#¨hòJ [Èk…ûÔÅûÇ>Í8ó‘[ƒqµ™¡˜~ĞV„hc,Şê)2œX~HÌ•Á#9[ágÜcVQÊŞÌw³ÎA¯ú+ ÓP0kq7ºE!öpÆT¿x7èv·®ÌšÌóè{N‰ÿ–º
Z&‘H‚À4ıE†Prp;éÂÚ-*PÎøÕ%ôå¦Î0Î«&3î¸äò­1Ü¦"İ“×q¤å“R/‰G×Õ6^‰:ËòµéÀ,X×œV\‹U4ÒpÙã¼qOêıÎµ¹iÉ4NeM£
©ûi³œŠabÙÛzÊuZk3î‰a€k05Àuàš‚õÑ|á(ä–”T«@ñp…¹œ2n|%ò¹%üñ;•eÑÌ–hÍ™ŠUw@PƒİéüÎÍj¶ğÏ8=;â¸Hn,O¬F A"=£ş†ú¬‡sÅt|ë‹\b¶‹émÊÑ›^6ıD	İÉãĞà{É^«s¼d^A`˜V¢âŞu=¦ÂÀáœç’õJcV'ÜY=VÅğf¹Aü¥'pÍŒÓ
“+E’g«ÿ²âĞû¤9*x
©ˆ›\<`Ê¦~ì¨/ØË(Ğ i÷–a<_‚œ¨é>–Úµ6ë´ñ>Û÷Vq¡8kòï€hÖŒ#ÕÒ‚(Äd«v»ÒÏyW-ˆñØ*îo“A?QéÁ~Z¨á.¶ØÛ¯¶	¼($YH”ŒI»+¢i/D‚?O$X3Õ“Ó‹»ûÅù,@Ó[Ù6ñóS¹PpšÑ¤ádÕ5òÑ†Ôl4[¨A]OÖŸÕ((²§‚ôş§á¢ó•Â[
½üôøõ	×Á{pGßbCD)7‹‘·^m¼-˜¬´0Ó£V ³ŞÁ’6<¹eåõoª÷èÄ7½p–›Pø¨-à7öd×°&‡Pò8Ò¡N:Hà«`a%ğ1âL Óÿ,‚èšK«æÔ(€îËV1ö#EäÔeä°í•ÿaÚF ¾5vÉ—×Ô£¡°÷öÔ¦şe°B¬»ñªGu€ËYU{d„@'é¡ú|ŒÂ{p#.ÜîCËşB/	Wæª`t»¡>)u©`¹8jrF£cÓ[IùqÈµ'v¿z®8{b‡Ô¨ÚmôK1°¾T€Òé”)³>PË«3P”±ú=“üô/UÌ«±0xµ€1æçœuÎ‹kµAXìˆÜ¿Ğãğ¯Í5h~’«‰ß-¥ZB‡?R¿è–r¯Ğv§Ùşè€ï ğ¥çŸ^„V•vòmŠŒ„ê¢˜k¥èÂ*¹Ô‘PDSŸŒHû1²@„—×#Ç…·ü¸(_“ë"b\Ğs¼U{!„÷"T¤>Â_ÆªaŞi tH_ÉŸÉìø[¬. %—§Ø
W5<sæc½î)?8(«\X¥÷Í ëìÉóE}7ht—Ãw²A?×(ÿÂ«Ä¶ö‹İ(Üy:rÁğ«Œ¾;äb¹E#kùÜ ªz^–ĞgqŠWH€pi:Uº¡hˆşögØôßAmFòİPÙ›‚ƒ=ô¸[òœ/&’(wgCw8Z)l\…b-îk³(õ+BU®÷¥¬sbj{™â‚ØZIqçfdµ¿ê§ah¤cñîHİÕbu?×©üBúÎj{éh:¶ßˆû„lëÈØA2%""—ÉoD{;uú'ƒüRÔ€P&©àsvUELuZLwLskËßãã•7ê¥‚S-wtfIù?-ŒSòÀ-ğì9hÍHŠc#“$éiLGEwØh÷h¥P)Šû\p+°Á]‚À×ÔOÂŒÔ4u[V'ÙF?›>İêÅŸ(¸Ö½C$2ÌVé¼ÈF%Ñe[Êîkãò¹¶{”$•úü’x(K#ôõK+"%Ù-©™|
¢&‹:úOüóäVƒÍ=¨—ßnašoğôXExHÌMõOÚ¥±ŞêÎBÇ¹¤‹éÛ°ã"\Du#V[Ûvpr[áfbv³Ÿ†ÚwÂ¯Kz}:’×á@œ‰¾ÙñWŠ…ıêÆ¤‡åt¦®ÜWIB@u¥5³¢›ëq¶<M2c¬9i“"%ØæzÈª¹e#€]„Œ¥”äÊóï%ìCßnûô·ZÈ?xx\> ·w#.£6z3ŠÈÃ?¿ƒ§v,n€(·¼\¯‡¢7m…aaÅì©–¼ã±Ñ(^s„Ûlÿs``Ps*õÍfxå‹d-ˆ2ˆÒfÑõñÛûZ¼Õ2yò#˜HK2ñ\é)ÏŞŠ”ŒíÊYKìlÚ©††UÉ”] ¼™J3fbÜ(Ó±¡~ATËÅıø¿!@Î[Ù¾yk?SÙe¾æÙà	\·ÜJ ˆÀ¤[{âŠ¡‡’øÃ­P-õ¸çL?)Ø©Ğ6´İí!+Óº  °´Ã±ÀŸ\e¿íÕÑ f¹& Ë´˜]iú_ïë7s`¯4*zQD,Îq¢öM›ÚĞ>q÷-nÕ§áÛx1)
‚ŞÇ8Öè$0cD˜ÓÖ—SÊYşJ-¨³òmA%dYÏqÁîj£ÂFlL=vo|Ÿ³\Ô5y$ƒ¼Ğ	ç)ƒ×¼­p?öÓ7^	AqìÊ¿ïú÷â1Z[Z­fµëò_0~ÙzºWpı!wîv€ßÜå÷4ve ş·Ñi"ÃÍ?ŸCúVeM¯eëú0‘ÇÛ½R}KtwÊ¢5µöÿ„Èş‚ur1³ä·yÚ½F«÷UÃ$ï¦{y ±,)$¹"¤åkÊß[f¡Oî•°³"°ÕhÚ¬ÎÄ$=şáÒ†SãÛú®†¹îM­UKº^%‹‹dŠìê•‡'ñ~~;ƒí‹«-ûl²–*Àz'™	 ezÿ˜Z+óì$ë=A^ôOûC]›gïÙf´”3üh£*K=ë¬LÁ¶ÓqëÌ1ä‹sÜÿ…`ùç’?Ãƒù8ÙÏ±~ô¬ÊêÇ¢$>¦ÉHh‰µ/ò°¤»«êƒ>LdœP!X¼ ¬ÂèVy9hjÃN•‚SPŸıÉæÜôj"¸;Z|¼1 ÈÉZóˆ5´“ÒÍê±àBmŒVÛ•GÛß$¶‚12‡°Šå0ás¾±£â4’Ä+Oy’†óérÜ—¹C3¾¢W~»7äİn‹nõ)&ÆÑùFÌ„‹°¼¸áºA€÷¶èÓë[¹m†üH2½Şè)‰,²UùµJjrIœŒÇ q#JşÛ˜t’Ç £=R9È˜Â,Â¡;Íc¼´„+ùÍ¢Öhœ½ó*ñ0MO?Õ‚—tê2ú›Ğ&»Œ†Bu,Ïş¶‹DG™Yõ™kå“ÉUzò°è´U/áPW;›ÎÃ5Û¹ŸßC,òd9ã9÷µq~©ÏRî@Ö¸»ü_ª‹ÅÊ¡g»›İÁŠ([ËG$,€yıÙ†‹è~Ğò[i¬ä04şJÉ„]¼±á¹€kD"},A¯˜°Tİ q‰ê['¶©æ¢ÿ)Å,°;Ø+Wø‰ƒÍØ¡uï%•MFÔº¦ÿ:mGõ[;ËôŸªGGpæE¨!£è¹;Ÿ`0Ï˜¥¾1—à3Û®ƒ•æ=ókòìÃ4FÛÛÉ seŠÈ­q!Óq/5M]©t—,FİqÅbH³Ì¡²x´çU€¹'§ˆycœh’êD•uÛCì{áøá‘NP©3#¨3ï‰å3d§ãw›.ÄÉ½õkØRĞ`¼Aêo§Ìt7øp%ÕeÃãM•ğM´{*înşá&QÿL;çmÉÖ%İ·ö¤a¾P¢K†oYº†àQĞ–+3œ<½TñøÃ¦[ßp·©»Î(hô¸8¡íòåEÓıˆTà[ø;±Ê´‹wŒãìe·ùü,)-—ıôÂ>;Ï•²éI`„¨¥@G¶‚~<ñÎ ä"Iªä{BÂiØ·BÔÇİˆåbÈœÈœî`èææ¸QÛ3)šiÉ‘Õi$ÃxB‘½.+SVÊ·â4,§FO@ÂGRD]ÍÀ[(´»et Xøu`0hDû8ÿ‹œËCZ…¡†ÓãìÜ¯µíãäSİÇuZP*æ!>’”¿±fÏ£Û«õ¼Î;õ„®,œUÁ¤åp
Û«¹ŞÑñ€Uş†fod·i{òætííè9ëqGºÖôVêjíÉüæ
1·ï­€5[8Ê8r§ÄÒ(/¿æÆ§3uˆ¼ªŞ }hs¯äM:îpƒ“kV”ºÕmYéŠ]/½£#ìíc÷û‹Wtï¦¥ŞåBÈµüS÷ƒ	¾%,rí ÊïşDaŸ~"«—Yû!(xrh<¿â?©ô,³

Şÿ1úò*À9æš’òÍ‚fh€Ã‰Ãåú[õ6Ûy‰G¸'œ
É2øæ™a–ÊòµÚ«>Ë‰y<K†j‘“ÀÒˆÓLè~³€czD.se¬o^®…ã,bŒÎõ9p­’^÷xJİ¶jŠdŸxôö¨–M%°.’å$Q½¦Ù“Cj³f.G¬,p{wÈ3¨ãiÂæ?“ ‚¡}Ä©P+÷D';ÆO/y²êá°ÙÛÿ¡Æ¶%ÚfD Ğ§µ^Â›ÇC¤À52QèÒ„! ½†G\Q›sĞö}IqXrô^kKİ€ÁVñaôˆ®‚+ÔâãK^ïSï7–=Q|Î¡¯\ŸĞÑäŠ³^È©µ»¡5›â¾Z7½±6|PãÎ@„—ó”şQÃawfÜÆ©œ•¦²CÅrd!$©pä­³qº#(hdœ“	9éû‹:‘¢ÌYŠêhœE:ÂŸgÌ¬ò ã'ÊİCŞ$ÒÖ¶îEOYßê'+Ò‚ØmH­ÛÖÛ”SìËHë¸"ÿİ~í¦(ºÙ!@ëhÒ¯šP3l
¼–ç"šœà\x^+«C¡bÿ#*ã‡BĞ»êMbò·&…S§;°`ó)™f$©Ş‰ÊaÎ4 òû†630E„5[:9òœ%ÎÍ¶¬ı™©KUĞ¾†5Zí
}“‚˜*Î¿Ë¥k Zª¼&lãZI74‹·ZHmÄÕİnê–VÃÛ ó.¶ìh0S/§"dÈ¢:}÷ïUc„*;|9poì¨¥~`Ãå>dów€œB):¯¢ƒ´lƒ–ØC®Ù²Ì1íd·òT
Sí»ˆ-ÙÈ:Q¾äÍ®ƒ¨¢EJ„¹ C‹-#(f³şº+YK,¡®®°>…*^Í¿ÊÃ H_Ñè]‹"ìt;¡.
‘0€ :yÊS=ç!²
²¼‡´
‚R8r[ÑÜ¡-Mìf&eæé÷e®ëth]¸ÇmHg-–XæÈ ™0bÖ&¼Áµ²‡È*kÿ¥j€WKÂ«Œ«šHæ)iñùæèÓ›äEbjçÈ„V»wç§jä¦¡h@äì 8ÆH˜@F¼ñ¢E-ı;û‡ŸLZ’tÜOB<¯çYnõ
¥P{Ñ©—ÖªwI7ä¡úÄ,ƒ'h¾@ø>sß+LBBNO¾_şËä+J6ú)4u;\n~×lĞu•©\1Â&P…îÊr uúZ’cwÑÌÄÖ%SÌ|Œ ñ1§.)ûë3sß¯•˜Â¡e0­Œ?B„ÊT^Îó?6‹ğ©o¾rTO¯~v4¬zÊ6»÷1²|Î ?lÌìKÃhÓa“/Ç¢Îé¤¸ô*à„‚$Xÿæ0~_“©ÒıÅ¡G#øÍ<qA=§£ìQa¶Ö4ÛüRê€zùÒ?Sá/ıf¢l
#j‚˜,:8È[!ÖQö;hš²í¡ı%²K#›ä%JŞO9ÁÒœi&É¶Ú¤ıgh÷f±ùRkšÉàïLVä@›ËI)ÛÃD]N™ïƒ
ZÄï™FNşh,r±ØÒ$ú ÔëÃÃ©M:İc>=òĞÀ¶·¹XzÕ™’kìêµúÛÕPMn»ñ—üôqŞ-/kÙNÈÆ2,\\Ì
±ÿŒ)ÿ³]à&’}'Ö{‹?ÕJbl¾>‹Rÿ.†"+Ë§ÔvÄH°Ôd_µ^ÚP_5<v¥r6ß®+s’¤7ä¨¶Öö¼Àëw¹ã),	Ù‘™@;ºŠ›,gæ‚÷s 2â¨'4ØQ†æ¡‘?¾Åï<•F¦?¸òkã^îŸ~nÑÇˆÛHA›Á~zÄ´1î&¶²ó™Ğ6R§j¾d*ıökÑ0ÙÑzªaëˆ³3ãK=ÉµÖr+?uªO:AÀP™®°Õƒ‰Î·4V‘‹8ºœy }—áÁG,}`©“î0-]/b´fjÃ»ûÓc€Ë8„,ªä4X¡ªq„¯ë¯¥9å’rˆós`ÈÂlbà§ĞÂ•ò —@‡zc¿v}@ô­èü4
—	Í|-W™Š”õd­aí8÷´Ù’£e}‚x~A¦ÔpÜ§™aîÔÏ¸hJ{ac|hÇƒ“0Ø&Äò§£/}oşğ‹¯E£_n8õê9Ê†´% Aæp”Œ8‰3Nñ cË?v»¡Ñ9öÎÕƒİVÓ9Ol;h(3o“v-‚ ¤1›Â],zI'\Ü[–>“bız–ãg¢IO¿eO×~>I ËRö4äE†¹ú¨³×ci…ò÷jo-§úµÑ*>àX÷zÔTsq@p§d&â½D$æyì’ä\~~ƒô°ÅÆŞ›\F¨V²à†´ÌäÍ1Ò7Ê=¾
°>ë'ÿQ)ÁSL(v*ËBL‘ôG×Èşƒ¤ªÖ.Ö#éúe&cè·æC7¿À¼ÿÉ*_8Du `+ï8÷O1©ohÙmyE$FàD¾¢ù”SEã@DB`…â´¦”ûë¬°6h—1€ˆòŸá°y›Ü4qÇæ%%òò7IšZhì}Ş!4{Š¿´x*U+]`k«Á58é¤sØ<‚Ïq*”ôg0Yèô»næÔm Tbj,¼ƒ€Öß4S•9fz»Íó¾|Ù¨ÏÂİ‡ä)Um-5ÔŞ†%Ë³š‹¸Ğ0xGODnİ!àçKáXİ90KĞò¼;T`ØYy	ÒÈüûÊÅ@/]]´>^qÆÿ4ºFVSh%½û¡õıR‡¥èÏÕMV½±<ÙjşõŞZ³Fíw0­ÎkìwÑrÛQŒ×¨e«HD‘~Ã:cÓì¿\¢4Aõbs`	©ÿåÎè] gş±ô&^¹‹‘¤ó{é#SÖdŸ‹{–ÓzĞÂ;¡RoARp(qıT+3û“&bE5r¹iFk˜çTYmeçÒPŸí¿Ì#9¡N kğr_ÿæ'ã«ÂˆB¤ğa*åÜweÎ}_Nç
öÀÈDÿ¤ğrW‹í"z`MH şèæ&’·b*´{jĞZ ›LÖ|«o·8>™ê æ‘\ÂğıA-o}œ7ó~±	e#IÓôÉ¢¸*†T'ÒİÍ(YBAŠi=^ÀÊ¶r$OtÈJÒ.†'jªjÚÄO*O7•U$™Z¾qèd^0pa˜°?í½ ÿ|ÖöîW3…ã…•‘ïg!§iï şi¾‘jF·RÍ]ÀlGÚ[¼Ş ¼şëÚnÛ^º¿§‰&¥nJ&i*æ~¡ôãÌ&ô1+N½oƒæ·›Ê§|²Ÿ-sŸşV(ê0B¬‚¢gÕõ%ÇÁØu$D1_¥5W<•·rèajÂ}Ş‘ÈFlíX'a>±õYÀî]u|zƒí=ì¿ôqË9~06T÷Êç&Ñğƒ¢àŒ<h{ñ‚&§>L{ÌÏŞ³‘¤$S—,¥‹‹[z!²Ğ‘Pæ‹¡yÓ0.Uv ¹İ7|úê0GÌ !±+Èdƒ%Jçyhf¬¹§"à;Ç}:± íFb0>YE„`(­cÉ>îT	­!ÆJp·z/œ^Éo¡¡ÀÆnğÚ, X@¦-}tdàxƒŞP_)@}ô.®)Z¹PğÛÇ6Ò¯ã‰O‡G‘[À­;š`ƒŸí…^ŠtDŞ…³N!#ïo¼te—ÁˆkyÌÓóIãjù– t¶W-Ë9¿-‹‚ñßî—}ÙÚäà{`”+·­ñE´&şŒ±¿„ÿ{mğÌ]¹ßÌrJÂMn?Ä@Ó¡±%_Ò2­›*ß£r½»Ó2™[_Wzø÷0#kªà„Zä¾,Áì
[ÃÍ›è·u#K|gLsş:ã˜ßx¿şy2pîC‰Ò¥E^øÔîÙ%›nğ—§ãÔ5šØ Õ^àÌoàoÊßwz¿ªªŞzpØQ Ÿğn+úú¶ès‡œ2öùşÿAK4ğÉ>M*Š¬ğ‚E0ğ§‡kvP çü»‚JsÉÏ„<¥a„	;­e¤„L€ŒŠ÷Ôdú9áĞÌrı“		ìz)¾x¶­jl@eÁÿ¸_!­ôge F;®‘Æ*Eg6TY¾{$xX#éñœ³Ñô¦˜†èÎdÖ¥Ê£Îø®—>&´“0ĞAl_J‚ƒP‚°hAVvj*Ü© áòˆ1&„Æ1ôu,.ÆÖ6=HAwú¦÷Æ‘ş=°~Îéß8ŒúÌŞÿ!$Ä)OrëÃÎcYq†SkìŞÇvIşL¤“ú÷w&N˜CœîÔ—`Úg¸8VOô‹¹l`'•¶±8S›y-6UÒ¤GVÂ…ßë¦#LAK2+Ûl^=îõ=\ŞTQ(;d:6™ÙÈ>08´-H’ËİûÑ°¼†ğT‘¾Ìå˜;õNƒ6ng&Pª([œhjËÏEkû{ é§W?[û*ûŸ1}ıâé>ª$hŠvOu|ÍFr4­vÅ¾9¼ÅÄí2èœìonØ}öTJÔ„ŞÜ®öáQt-ÖÊ†@çÏåó{C¨D²Ê€æT¼(Fñ$ Ê†5µÍñ™~Ø@öú~ŠA~z¯õ¬’uúE¹ãúûî÷}ô²òU·Z8iU«Æã’ ofàúq™c¸*²¢…”°° Pfó¯ªVÍÀz(_Óûàf£š%gC:Yk2²peˆ™0MØ,+ê1Qffİ ])ÀÂ®€ä£ÊáŞî„*k@^85°d@œÉÒx[ ˆc¶A·È9)\&Ë;e„Î A!
X·§ ®sXÖÀ
üJmN5'Ê¾‚D.8Ê§P˜M ±-(¡Œúşxu*ÿÈ™b“(tIyzvÊ¨ªºâî%-SN3Æ£}VH-×ÜQU¾‰mÜï
rfölšmFğó•‡ûuå‘¤p“ğl­1TjÆ!CXƒ1VvÈşŸOEşD¢Áé‘ëşM…E
k	_Ú$ÍD½l„íêÅ”Æ~h˜ÌºÀA†‚mY¾œø.eU“Š  X,pŒÍ„h½–²Üù¬>2çìªW4‰j±Iâ¢²‘!ª‹Pt¢Kİ£@4•$¢ 1²8P¢1È¤ùpª
âÔQŠƒÍÉ"ùÌ3±$¼ó¨Ÿ©—ë/~c” §x—2Q¨åWj‘(c&¦ŸÓ”göŒªÊUç]îyÄ«N¸:oÛ£¨gD¥øÌ±jL=W5ƒéD‘’É¸Ì0‰®  ktún ,ÉarÕ›KaÃqo`P7oBY@9ª–™5¸bWÆ¼G³–tİÀéY¦ƒcíNé±ú•ÈªKÊÇÅ6a^0«ZºyËM´9• +_µ¶ÿ§dë™zÏIWÅF^cÎ‘³añş–ÁQÑ»lEÕ­£‘á™‡Í¿5j%÷l•LdG'¥të>.‹ƒdb.«Œ")nN<›P	{«•zŞ]xƒÚUšt‚Ş[‹$±éäLï£ĞN‹­ûØèY+Ån(V².¥XÜÊß¹(^qu—2½­Ï¦FMåØ
¶ùä›Ä¦wFì¥è°Ë•F,B$Áš˜Ÿ"e~îl×uæ,!ì³Ï2øĞhø:¤ÓP6 ÈùŠT	µPuïÒ›ÿLF™ –CKt	K!™+yÛpëC88…ôJèÎR·‡‡JªeqxZ÷—iv[Ÿ¾Tì¼…ığàšLGÔÑí™PñxÔ[J¸U¤aŠÈBƒŞH²“ö[Ğêq’»fìŠµÔc`µ¾º¹/¥
N' 
·ÍáâT”AêYBàØRÇ]NŞ‘fv,ú¾×\dæß…ò–ºímÔGİ¸H¬Wå—ş©–öôu wô©ıæ&AmîÙüãjŠ¬e½xô+Áiæ³ìÄIdíFÓ1/V³Å*‰şDŠ#ĞV4Ÿ´~ÄÙhZÔq¦‰->¾õİá}o15SÛèIíˆ[O^ÁZıô!äyh¦Œ‰…„Õûf¹îA	
QR P%OâLÌ±r¡ë‹å7ènøŒ·¸ÄÁäK`ıÙ)haËBÙÓıMÉ¨İŒU´õÉÿàPè^büÃ£ÉD’<³è‰5Ç¡Jû&0·ÉÃîtf{#1L“Ñ !BàÖàµ’êT®–5[Ù)än±5u3´ŠZÖÓ„Å£>Y³1-]IYCcÑPm,Zíß”ñ¢KÙÇu]Û‹«ĞF	¿·Ò¤^­á *µ21Î÷píC~›—ô#\«Õjéép•»¡&‘–0Bkİ(‹yytß|B#xêmØ6k^ÊT‚KîS»R;†ÿA1Ã—j)ùÅÈüV|TŸÁŞgÕÙ‘x¢Öt¢Ó.'"WêêKJ‰ÌÜ)´JìOG_#R|ºà4ÚÚO‹è,ê©»ğ­R,8óv¿›#Súåæ
Œ8ÛàÔpFæÃ¤Íü•öW%ÁÄKßÒÀ=æ=³“¢²ùG+ŞÛlİ°Síİ›Õ¬„›]^MêóRû!{‹ %È=É+Œ\ñ¦ğ¬!Y:jÇ5Œ+Kj pƒùÊWF3óPA%­»ªÉU¬"ûÌrÖvRê.˜ô8Í&«/`/7#¦sP®#{…k‘»Ç¿é®ê{gn‘ú,ša
àlxh¥=ôÎ{?Öí ¢ì¶ì.áU
ÁìÀÊèĞ8fK¶¥!†E\Îş&·nËìDfeOÿàöŸä|"Á¹“Vw±5J…;¯†¼r)P‹1Æ&ÌH«6ƒ¯ïVMx}q/Úˆ¥mabwi=¾İŒN‘Å3‹»•]Ş£x¤ù¿Gòa\’áuÈæ‘Aãmøy;N÷DÒmò#I?.½Ë?ê92E«¥ñĞ~‰-¥|ÁÕ?qi)e:+¢HvDH-àGQò”È
‰·’ÉZíÇTÑK"b´S¬ßÉïLü~0K¯HG³'³nt!ğÎœğ'ú©òü½×3{à«¼TX^ÁIÂhV+İÓÖÉgÏ‚}ør®x6‡Nln“&]j|jõHE@ê1 L—ÚW”ò× =µ!N’º¤¹Ïªx×ÔhÛL‡aşvo$™«%ÿo\úSõa@/ˆ2ï ¨¸ÛÈ°‘°±UÄd<HJ &¨°È&­N‘Ö¡ºuºÔÅëd™ÌıôT"?Ié¯EÉlõÆ‹\iJR¿‹V¿¼¨ş>˜ö!~Á:˜ŞÜØfxü¦ 7©Û³W·¾ëÌLø¡”†3¯íLT	;í.ĞaÌH0©‡˜j%p@ş»‡¸'‚uÄ0ÈL·W_óDå#©*ã ‡€¯hu†¼—ˆÈ`‘ æˆ¨îUÚvÈÙ’Å7œl nç—|şŠƒ‹å®
©şöÖ9Í@ú?Ëİíê
Tÿ¹ü †«[tÃRå¨n.MºlUò/ûÖÿ­E¼ªîoR6V"¢ÈÄzTUœ\D›Ä-‰~Ù-‹äš7ÇÏwCKWW:{Ôö9ş£Å‹oV±Á”8Ìl[&,w˜Ç	jQ_$°+Êú7ÿgqÖêÃ¾oš´z×_À¼µQŸÅ{¹ÊøÇïÊô÷~»÷i÷B"OÂºD±[¡+qn>:î	ã>MÙœ±ÙJ¦“”;»°_"Ù!ôÈ%0º¤B	Ì°Òî‹¶ÜZâv„’wb9œ$3Áå?ZQíà%ğø.÷
ë‚H®İz	8ÏdÇS‹fëSaƒk5½èÍ¦¬Ç³yá8TÖi¯³WDÀ²ÓÒÕ£,Û ‹S±x~8Şş,Ê–Øgëº$aì:q`›Ë:7~÷•oèhæX/œÜ>‹)®	Š{ezúõé—PF¾XDHp'‹ÁTU‡oecï(ìX~oÑ’jÔÍ„)µªïn@‘×>µ­ıÜ&„×BÛÏ»‡UX­	ÄB¨?üÕ<\r2Ríf ¶Z³£^KâéôÊ•ÒTtùµ4Ñ‹å¡“É¤ººÉh
„ @U°¦=_÷ó‘¿.ÛtÉj‡ixö7ªµ¢¿:c_¤_Å7ïò/ï–§Ó|ğØô·­à"5nÕÅIo¸x³Î>é°~b1Ú£•	Æ`clD0Ûjğ­vx
4Ñt«ÀZaÿæcèiÀíèëmñkGÉº/¹¸ÙåÚé…$át?CJ³”]hH+ª8ÁAa­æP5 ej¬B…˜qé~MÄİ‹±ÏL­½3zsà_Øü¹[äc±–¯áóD….„\‡>÷Fü«ô‘ÿÆrMƒıçıµwŸ5Úœ·ë|89³‡4pJ3]Ç¼6té´H;]0ÛcÒüoL™öZšñb%~ ^vÔì›h?„+÷©ªR-qNÖTÊ•›˜Ê·Ûm W}®àö¡ò(Õ.S;È2=~Ø¬?FŠøN¬Ï!s i	
>iÇp¥h¦¼—WÜ™·<¿mª)•¼û\E‡*Š§Æ£ÓÌmJzp3'gA3°´,­j‡Ohïí¤k¶˜Oµ¢Â€4û-ÉbÂI˜ifxâ?MMîÀ‘öÈoÉX@¦y¯<•"$í¤Ú¡¥«³¶è*´¼Y!UÅÔ)´õŞŒõe“J+³Ì?0Ñ·¾ëÓ¶…“ÔyiÚ?âÓ¦äHó¤¶Š’÷îMS°LÂ5«^ÂÕÏ^~»ù2¶¼zŒ¾M ‚ç•ÚuJòa¶ûiÓc	ğt;¦ø„dh‡§åÃç

1”Øbã3^‘Û1O)áx€?0-‰}_«¸€
<Úr°iSP×#L:õ›hç¬ör€!/):róaïsI©òzÈ0]ŞQHWëHñyúæ1ö©î
Ì
ûùCÑ52!;ñ’x+·F€õ¸*µÜF„×—PW¬PM.fl¡Ô­ªuU$²G$ùkDñŸºQ?Ş}ç.PÈ^èì£qíÑD?N’Än¦ä5';fı-‘ŸËˆÊñÒŒÚ3ŸCõ§¦ ®|cS›ïZXÔ‚j>ü±	Ä2R>Í|˜ÑÀ
Pwâ©ÂòUİğx›ÙÀjÈŞpÂg±y8á&ôÓì|»ÙÊO SCc±Ç‚î“™éGƒ>	Ë¦O˜Ïkq³,ªäv•gP©om2óÅš‘ƒò®¾"}ºêm*™çÄñd÷SXÚÊ(†ıHÔ«µÓ™$ØÂ4^ÿw©¾ï§‘ùåøñ Ğıp´1P5²Ú
áe~OÔP¼rò“²|Èğ³Í.l>‡mºbÓ²¤ãE$8oºœPÑ {ÑÛ©Ü¼ÑëQØE'fÃwõæ†´S±õßzf}Aj¹;“:–€©?VV2|‰€oQøê"ŞHÇ %QÚä‰ ;>².ôÁÍöğA7Ãâ}}X^"ıuC<
uÁ’hH¨V•¾*ôöĞŠ65X{©šÙ Á6+`L
1_½t÷v¼ÆU/ ñä^dXóv>Á@cˆ•Ğ•F‰](eR³9\çp‹%F6DÉüœğÑ	o%FB†no¤õi?†ï®WDÛOBvb&0	s±œª£\9ªæˆ¤±Ÿ¥¯wo™ |t†Ñ«wÒ’]ˆ@+d:ZàÛRĞ×†Ãaƒåé|0nÇµ"ŸÂıLÅ5{ÛNRªÅP×Uà¾!ÂH†4ˆ—óî¯ƒ²ínÊÏŸ³Ó;Ê®ßi#)˜%á5ó¬< ½•2Ëc‰miàÍƒE]LJgğÀË" ¡É•á<*v[%8GÈÔki†OyHIl˜$&½íÙXW±J®-K)K+ÉÌu;áÑ`:—íIŸ-Œ3>·#}‚ôÄL£´pÄÄ½yˆt´Ğ®fÔ¸Ôu_»mÍ˜Êloq,ñ|dR,Œ§ˆÕ¦`C´İA<á_1–:Ş-÷Û?‰ä¥Gà@€}#ñîuŸÏ¹8M¹÷$ÍİÚåT0Wî´²&ë£•øíşòœAŠÂ„¹8ÙbHøÏ¾£Š¬B3wŠ¤]uL‘?Í²ÑÛtª\¸ svm½ãjÊÙí¾. §`tîq#€£ Ó 2…Y‰ *¤ËÒpg ûijTøâx‹×›ç)Ô® ÖGçã7}0a]†:®”xíQWÓ®Q§N†Ş@b¬?+aCÇ•3ÑE‰nÈÑõ»=ÅàÁ-7º`_À8LğK¯8£]şÃ®yÑñp÷µeİÁH½ÕDÄ…Nµº7üÔÇ”ÿ²£HÜôì•è”ğ¢(|O·ï~cÑb7˜À|—«N9Ò„áÜNÙ¨L}ÚJ¦ñ¯µ~aÈÚqù®W#Ø×WhíÓ¾¢7ÔjÙZ–È”‡+ü—óùG‘…– €»e?¾üè¦Õ?jœÓ¼¿bœ
“tKÙ„gújL	ò¢²İrl	Ì#4—ú%U¯²‰ğuyû¿ùiÃÚ\ôY/"Cƒ¥P£j™ôçhıO_™Ùô'¦iYˆ];%Ô·øÀAÎu”Ó¦ù¥Ó¾é›ã
VÅº˜>aœs·Êı¦êù;{ğ
…­wÊ®Ìæù%{¡£’'dp›.äZúnÈ¦.
+˜ËøÛB\OKzõ€+õÊNXY@ÖtÓUj}°±44¨"\¢İú¨8"Ö–¶°ÎğEK9V(¹Uã¼ÒA,i?WpÇ	‰mğ^%”ôŠK,•æ‰T in}Øz",¸›ïÆ1 b¯Óráá!B¹>-VjômF(ğòÚPŞf“–ä¯s±/„£9Â¹N3¯¹$õt§›	Ü7ñ4|Ë+¾RhĞaÄ—W÷+©wñ
MÃZ•2œ\Ïâı7‰F‹øä)G(Ú ©;l'òöÿÔœà»Ïğã
[˜YÜ—³ÀÙƒÏÃ*{w˜ÖRV =À£ŸK—%	Æ@©Â/l6Dö€kEò
r1ş&4;=±Ø”Ï,³"ÀÇÌ§ö©>ç.}üCË£ªÑlĞ—?¾à¨	.(-#ù¯éDêkw`ã9ˆak:â´° éO_Ö(hCäÛ^£ì'|?Cxëì‹ÍÇÆf9\M±[²ËmáØb§æ
R;¹«
¦x¥èg[w‘¢{0¢vJÀ–ø|<öÉ¸åbğ	9láÜ°äÅ±ÔÖ`/~-›½®¤# º~…kpO~øş	ˆ<ÒÄ¼ c˜³äVŒ¿ñëQêğuT‡á›¸C	¡{vê‹É aæ5è™$Õû·Ò¡RDZ÷<Îem´?ºíŒ¦@ıLpøyœ e·÷6M`Î8ØE!ˆérî<ª¯ë¼[qRÏhöuùöm7%­R˜w´3ŒXÚ>gnÀ?E6 +ş!ôZŠó„ÙSá£zågÊY\£S1M€k`úêşöCâÚ,‹‚•à±+Ä,~ª½“Ÿtí2­,[Ò¹·Ú¿Ñw]†òıÌ"Äkï[WŞ§º'K¯ÏÜìîîİ17ÇGû»è™şTßwÇzÿlÍu€iŞŞ=œÕ§;Ø¢8N=ø™­yé• jÍ#¤ĞrX h3Œ‹pcğxe¨×Æi$¼Â¨‚C<I®û]¨:ğ5À~Êœ¯çØ‘Z¿Ë~ÑüØÒÉf.£Ô;7lOé]¦„K)»¬¼C—Áeq2n7‘<Î¤Øx™0›à•AXÇ¥®,ÈÚİˆ¢ÅÂ*&WşâÈª/Ã°iİDÀzÎ|ñDbÊòŸcw  ‹æ§gkr2J96ipÜÁò9—fr	Ozé¾síN>ÿ,2adìèÕ³à˜¬¯†ği§oî×ºSu§DkµN™Naòã°¤UJ–s¿>U×3$Õ†3Q»bÅEe"€Ä0İ–Ÿ7m'BÇCLŸÏËÅ/UíC–Ÿi–&eë«´Ş!…İi.Ó…­…J»`fÄ¢ÿÙy²@Y ¢à¥ê›±ë.ıÒrhB IŒaâŒ‘ŒÉ‰	¼eĞïå'Nˆö-ÿ›¦ãÊº™©3iÀmÙİÏ«Šä™Yk§›9.F5S8{ñŞ[±İèÌ6ïU@•JÃ$J³SÃ†%¹ nšœsù<n2è¶Ü_µšıù~x+Üì¼s}'Ds–ÎXy0]Ş|SZ€&r~Kšqp§¾f—E9ŒÿÀ3XK0Ì# ğO¾¬NàZ#j+©Œi—$8ômu\¸şp&)Ã–26r·e,p·0c5üpR0ûïk(±e¥æ@I”—ö,L—¸~÷<¯ŸohgO“P¯m‹Èä·ŞâËtŸFÃü'X6¦šGzÎhÊÅò†jFÚc6Gì²%†‹ ÚÏO!X,m².òßİ½óş}IûêwØ—ìZ®åDFª›ô´< ç½àwæDÀ˜ôãÕC‘y«eL¡`^@ò$[]Å­•Ø:ê©¢xY;ºÊ?`úîè¨W`[³*Ş×J~fš=ÄïN‡J–ŸK‡icz«|[w±˜1:{»¦³ëúqt¨÷òW’İ~çÍ5òë§_ÿHYi¹uÙeÔrO¨°)F„ûşwRR¾ Æƒßò¡*€:÷àÈò{ïÆv‚aYşƒƒ”_†!Şå
ÕÇ€5¼˜%G3äÁI#gnÿb|ëóvrÆ‚[J‡~Óæ«tC»;
°àå2ƒ
R"˜V/ÂTG;b üAv Ù÷^šNOñA3²(ÆŞµ—T•Ö›‚)ÁSÚœ¦¬†g!Äbì’\v;”ÄS6»å[!V¤Ëuç›4²c]öÀpb®¶t¨‘…S½ØØ-…Ö4½¾uÏViÂËN%M’?2EÔG¾/*f-;{Qğím`¤|¡·álXôŒzõA†£æiJi9}¦ÏûoX¤Y²2Dkß×Sk[¢è$^nïNLåVæÔXÛUÍõFKE%§^ùS¦}ptp\~ÊçYK¸Ù™7˜kák¹xÖşL ¾®hŠÉ±ü Ú£“&$eÙPPú((LÆ¾ XíÚæHûğù@n)æêô+tH!E\HıaDíîÙólNÃîXEO ªnÎíö¨ŸT1Ú'ğ¹yB«ÊÎ8‘ÆfßãÄ‡úÍvğÊÌ<q1ŒYÊÜ@KÄYã/ ?T€ldƒ:¨hÆşñ©^*D:s÷$úôJÛÅe‡âmHˆ½í‘ºz*ñvÏªäûGŞ¶<N…YwuÚûçóå¬äÀ£¨¢nşí02“ŒĞ<y¼°\®Qã<ğ÷ØlŸl±íTlíàÕÒÓòŒN¡÷ŞÒ`iùßaİô ¬Tü§/wm¶ô*9îë åâ{‡;	ÍR\eÔ´‚Jt×˜-Gót½4h $ñu0‰ÿ-ÄÌôxÕ6¿ş¶õş~
RÉ:wàtšùÄŞ8÷ÒpÍ³S	C4ØMÛGmóY¶W—?5ÓåúC	Ù×œ"H`º“!°m??UƒM6VçE `‰]w¢yàIù¤lQ‹«2¯Â:G61ø áÅš½rZlvîòqI¦~ƒ¶!å“yP§˜4ŞôgÀ\æ+ÖQ©8NnÃµ!"Éš'şÊn$.—L8™àDWÎıx¥d”­…¦òÔ«ıSÔ•'?k¸[Ò¶À{ ÒNı¯uûİ'Xg2ï¨Rça®á’²¼äKŒ¯îèV¯l êpß½›V/AZµ¦ v+± ŸbhJBÂéù&¯ŞVğs[Š?ÉGG—ê„‰°:´¤.ëñ‡ê¤„ˆÇıÏeJTY GØu†ş¢ƒïÜñõßê¢:bO%ˆh®±ßœìRƒ¯JPË„ö”`0qT»;‰‰Õì L?pCk’£ĞHÛq´±Tp[G»¯Vc5}3ûq¦lïŒîÓé ÷»£ZPlò>U/,µÏ€4‘tÊéèãˆYI}.å?(P·A"Àİ6Å‹Ş´55·3xŒ‚Š a%×ç•÷€Ï‚ü¿r$â¾¢=è¼e@Õşî@})Jñ(ı?©>Ybº‘»ßÒ+zË«vÑª¬½UwLó¢¿²àÛ¦æ¶JF
Qtc…T÷°YÏ³‚úOè¶Qbø}ç“>Œøö£¸¿UwÛTUİ³ji
Wëşh­3©6-×ëK¬(pÉâ¨€ëF”<39¤Ïe(Ô£&æ(èÊ»è]Ø5åzf…2Ÿıé]|
§ÅQpg¨)Ïj`ñTPry\6ô1ùı|ìOM¦A[9…ûs2Â™¶=Ná&5¾ÚÑ“ÂOê’áE¼Š¼™àÜ‘bû{­§º|e¿_ºÇ×IIÿİm[Ûº“ÔZ(ùĞ>—(^Ğü%°Ì
rØ¡×çëı¾Š‹xYx-üúŒ£P
aº"CzœdÊ¬ÈJgmlü8äÚ°~²[*›)mrF‰ÏN«,Á¤“o Ş¢<bä!ÚŠã_:±<5,ÛÔ<ú:II/ÙqQ{Î×• 'ÃàÜ‹%©E‡O±a‰r$¥°Ü[]¢€	Ã{'1»'İˆi_xK€³¥éMÍê%(@Ê,È‚15¾ı—ÍNÿwÁT64a¯›|Z‚Kf-£b¼·«6 ¡ì†©Ñ"£ên“oÄ2´v|+
½ñªƒ·Ç$†YÍˆÍS®CaÒ¨xó/êaªßğìtÀø8N?ô_İqœ÷ö‰Ä	ç_på¨u³uê	æİ'hfÀíl`bMgÔ”éæû¹€C CÑÂôµÈù—ğPò‘º°æ&íÂõ4Šâ;LsõÚG™g,›È‡ß³TVò‘íâ‚™‰‰`s½ÓA†t!e cşa&Ñ¨â^§GëâEœ¡òe1Bˆ¼¹z7$øQjxWKáF§·|)»v…,Ü¿ú¥XhufÍáqí’IT7›ŞQÄæõ1ßjÃAèÏ„`¨ïiL0ªqAóWT.¢ª¡_İevï 3îÀÒ‹"Œ®òóÆÚßËq 'u+§¶r0'ÿÁÔYp]‚uU‘û½`Åö@ €ÖÿA›xãU>&àárü]ZÒQ=÷…'Ö‡êCÕ;ÎG›),
OíSË ÎUŠŸôéİºŒ8Zÿ¸§Ußİ„¦_xÌ²¥‡¦8åı·kd=“d¤ÊR–æN8 ¹„_ÄÅ‚÷…Õšæ
˜8ŒŸI<y>Ì]Ht%ƒğYC"æÛ)j9&»ŸEÇÀ‹öîkTö ‰ˆ˜(Äö$İ¥ºĞQ\áX‹º7ï.ôò	—ëº”÷8ÒÃ$…#zÛë”á>Hâh w(aNªc1ÜÛƒ²ŸTÔ…ú5#5Ô$S‚–òûËFıœ(/öı±€ââ®#¶óÃŞÓ°´üD­Ôº
G~ÂªÁ¤àeĞåïÜ¡F‚–¢´Á7Â’â=:'4”I´>¸»®ÆJ6M‘Íà7Û %{ï™Zd&ÌÜrA;Ó—­'öôrÆÆ.˜Ë‹`ïÑüÑ‹Ö£¯ÉihbIÈdŠ$ÍUPŞ ³;Ãùeƒ’#áÄ‡‰BcÀºqÕÁ)‰~0/sŸOCò$›3?.£TMãîe¨h®2¯f‘¡¿f¢   w¼İ5± §°€ğòÅİs±Ägû    YZ