#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2607082614"
MD5="955998eb6112f5763b43ee8456a765be"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23320"
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
	echo Date of packaging: Sun Sep 12 19:12:47 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿZØ] ¼}•À1Dd]‡Á›PætİD÷G¶3ÖëDõHd¼sYwtr=]İEğª£K…ÿV|=·Â£ÌÃaÂº®Œ^uYí(PÛÇĞÑÿĞê™,­—Ü6ŒDE:å_2Öì-´Ëœ›]™pH•´$-L¸j ²}çÓTé°cj‘½SF"Ä…×ÛDbSbA£C÷z’üdKÎl49KÀ„îªí]ˆ*ú¸¹øHµÀŸÛ»m³,÷öæÃIÎÓÁsı©Üê·MÔµAK¬©±ßğùõ¹D•±®ovTĞ*ÇÍ[Py0d©XØ¹A÷ó.C°fjU`óåf³.ÜXä£WÎÊ¥{Æ+fmEÄeóº¡nÉ³V(ömAFˆ Rï¹ …iN«ñ­‚ö²>EÏÙİ5* gMºÓ™R¹­Hs)xr{5)^ÜÈ\-ØEÂ-¨(úúP'ğETÆãğğk‹’s`6–µ¤©á€ÜbÙ3½v™e#¬UÇ½Mßõ¼T³q±Úì›`[6°F>¾€nÿ"¦ÖÊÌW6^Wó7µ29é£1t/‰fz4ï‚c”•eøkáÄ–•^:N&OÛ™ñ–8œw½ÇØOö®¸Lt‚]òĞARáıõKéÅÄ uL|êÅ šéµ'òö‘*&FÜ+d³/»Ê îµE}KoÜù¿{œY6vß…'R†zf=“ûÍ2% X‡ª¡óétÄTÃpœ„gm‡'&
+RèäÚ7ëu !¨håÉŸêŞb‰ÛÇ-öO¶Ô§IIÕ¯Stü¸umÅ9°¿ç#OãÿkDŞĞ¼ßQX¼«-ÉQ¦dĞŠ³ÏøJÚDˆYsƒÃ?7¥c0”çîeg°V‡öQ×š]><ük‰
¨4Ø±ı»¿ıx8`$ÀÔé£¬®·!Œ{nÜ¦Çn·*Éhæ‘:!ñæÊZüVc¸TW=ÊaÄ‘®ÍGêşÏ í10	Kãş”§˜|ÎĞRl›«O6ùÛÃÿ©Íüßd7ëLy?Â_Ú±¸Ğ+IhõİåÊÒ1˜æ½±ø÷…¬¨ºÓñÌª#­YöÖü­íb£ELß-*okD6Å¨ˆHGóDHôo4†­šúgêE,©?'Ù8LiFÂÍ`|u%÷ƒ•E‰Ş¢¡PN;»¸(·=Ó•£~…rmŒ:^QøÒ–'ÎxZê6¶å)rQ~~˜ôë	“Çê9¤x3R*õŠ¡œÊÜKãV÷zNXğx’§†’¿b¦İjòãÕ—cØ»è2ÕİXM“ÍÅïë]bãvìrd~<sÀ«İÂBó.ÕZmÀ¹~DóËC’@w²G?äñUyo"'_\Ú!PğµğŞİ{— ƒ˜ô„WaIô÷à¸IhYß½†[vä2¥äı~;<«ÁK\i±°è˜×©×+@`3ñNÏlCÉ¨9¾dnØô\°ù1ÈuK±@‰6HR\Ş‘çaÿyıäøìTgƒ€ã¾îB4Ÿòå•Ô÷<óBP’a@<£İïP8EßRá¦á$ƒ–Õlz¨‹ÉégµƒC$#k…Ë"ƒ¸ïDM›R²tƒÑÕ‰ÃŞãÉGÂnÂ1sŞHT]D€š(Ò__¾eF5_pÔ®°Û8ll\'Ê'Å:ü‰Õ}/‡LÅÑpà%W°au|[I·Ö.*A*¸)å×b–%,•”„–#¼3×È~Õo?â]æşv¡ÂçÃj¡¯ªë‰ö¸g½Üï8EI?‰DXr­Œ~9|rÚ†ÆÅNøuC]7Ï%å *¨±2”p )÷çü)>G«Tİ_,ÍïdJÆsœÿ`£]u\!~›á¦5Ù»¤±€‹û\ğéßµ˜ÑEbñ P’ Ì\ƒµCäª“ä^ 	dJ‰Ó‹í®ÎãFÎ¥j‘JpŠ®z_•@AfB6U5³¨ÇÁ±ÆĞAdK}l›¶H-›ÍÊYÇaAkâÆĞVb c¬¾°NS‘ZnßoŞâBåv…fy"•«r|U³^üxÂ«ºI*åhs;Ì¼ó·‡ÚqÓM‹Bl¦Ê«ü&âNŞ¥êMƒñı{a>Jc‡{–4òLé8“ó€ë=ßc³Ş(7Wˆ¦––ÈîyŠ÷}…`ˆ<--eßhäa„5PŠŒOèÅò)C	Ü	vÄMxxâ[·‹9”Ğ­?Ÿ@®ÂEÉŸ‚]#|Œ/Œ–®¼Êöçt™Cù§?Åç)–RäûµıCM)¯MùQQsK+Øªzøl7è:İ»Ñä/‘.T!ZƒëĞªú¤ªÍÜÊ»`ª>å(Âæ›+`Òsvæ"6SæbË ä–•¬¿õ_y5¤Ñ×î·y5§a…)7éSIE—Ğ…×ÙğßÃÎœ•·Ñ»¦±	êW@ÿ`°jM-…—fÈÁ›,|Ø4Á{¤8XOÅ|É®ùÑ¦"ÅşgqƒEøÇ„¯šŠÔ{tÇj*j·$¹‹NgEÂL©
ÍÎ1Ğ†+;şğsş• JßMG¥ò”FÊÉ(Ù†]šä{.Ğ¾ÇÆr¸~šå|ºq³	¨”
ükJEÁ7!Íjm&…ÇÁ&RÔÊàge²¾6Ãä§õu„»6ÆG¦«à~bæùµ0ƒåÆÃd¶KÑä=fïF“â£)Ñ¢jâvöá2HÂòÊ¥fdñù‘j¼9…qAï¿ J[›XìÊ’CÌ~ûÉ Ïeá ”Œq°1XsêHæ¬v%k1Ûç]§ïĞ·çF®èƒÀ
ÒSñ?/lšKhNå±4 ‚Eãx¢¦H íMÿÍÊC Ş[ú²7¯Ö/bQÀ]ÉÁ+ TZNän€òHû`Y½Š¨!äÔj¤ÚüóYX—Æëpæ™y©İ5 åD|4bÃ=p…‚Ÿ¦q‘1iÅæ\ÉŠş¼ŞÉû¬|¤ØæşÏ+É<Û58×èŒ7_p‚÷³‘ş•“›ºî¨ej7†‰ˆ?RM²X‰{=¶?HaßñMK …:e«F¿Ûµòàš"¼Àç”ë†Æ6w¥®umqqıÕbÕYRv2@ëØ¿²ên4Û\#]Í‹ç¾¨ĞéıÑÒP,•ğEK_ø…”‚±%R…ıø×…lğ>!Ò¦³¬FÜJQ”åü¤ü¯ª¾T8ÖH„ıÖÂ„òCÕö©È4I‚\Uú• m1¿¾3>ı g?íäjİoJT‡&ŒJó1Æİ6Ñè¨i(è¬õT•)İC©TĞ@AéÌÚ¾ŞøoØo°‘İãIÿÚ_4m²ÊÉæ&*Ú>	$,í&A'r,ş/gK>>ã¨p£NsŒb'“±™BPù(æƒPk`‹±Cifrñ”ÎÖÙ!gdÙ£+³£œ—¡‘¤]l¸½!ˆ³(,ˆvwäç]ü/™şa3§Î½åä…Ğ˜àµëˆ·ƒ«Nf1¢$ôÏ©r¯‹Pb,çh„Ú(ç«×¾´û¹L6k¿šèãà ]¹¯2şI!$˜Ø £ËEª¹2o»²‹‡ùj» ˆÊÃÛµ¬ÁSİo+˜#¿¬ä#”½¦T&$nÔäe½áğ†Ò‡5sv{ƒ6»/ãƒ{¿‘Ê_pøÏt”E_ñ%¶kSj¢Sñ›oŠ,tZŞ'%Éº›soU­Û†Sª‹+š¯7HTÌ+_øú}	—„òW±†¶,,íë˜Ş™g¼²wıŒúÌq—ÈQèPĞûEß;r “¸ä0ƒC0^f~+8y0Ñ3=È!L9'*c}ïèÔ0Í/¶n·A`;¯k‚1ƒOH`­w¨Ğù= Oüsn¢Ñy0ëÚÚúh¿À¿Õ×1{>\l1ıã’!’sH¾¶ê†½b‰—fÏ?­’&€Zø÷JjêRöğ¦§ì‹É_”3ÕÈ%ÚÚuQ¦$ªç€—ÌºkA;ã]eØ7Ó{/ÕGLçY«	ÜìDšb|BÏÎ¸òEË@yÓß[6«;›Ê±úf'âú¬†ğfğØ`UXØñ·å'ã½ípycbu÷yÁ§ÍLÖ}
“‚L‹ı£5a}Üm2€†ãñ"¤Ş(,0kXc”İ„ò@Ö(ÂÉ}æCŒöÂÍª\IÒy;8Şt¾<‚Ö³	.AÑ4	Aû–x¥'Ä’º—i©œ£‹üÙC_±‰‰éÕ¥»¿fXïïëŠÜdRöCçH£–¿~Pâ&¥
pjªØ.6˜³,¢8@îÉá0¢zƒSÊ2\Ñr(`zB Y²¿>AV{+]¼føas]ËÜäOaU¡^È¬©>5ó‰l)mr£kjbÍÑÖ”Æerƒ
U\«­;•í,£{¡y…€Õ#h—Ä} çöŒ»} #›oòÀf±&†VjîÂ£„±1>±“Rb~CŸì²ôË«ĞG²±eÚÍª™mU5QÉ îÈ~cû²ùXWwş¯š¦ÿÎ_«[š¥ñ(÷cØTÅ!s¤ph¿±ÁÅ möşLp]Ç'1¦Áçª¡,KĞ<m¤ñnŠ½êÂ¾x.ŸÒXe'ì»¾¹JSZÿÒ2Î2‚ı<äš>¥’ğ¢VÌ‰)iÈ.ı‘W+ÄD›HKJ8î.š·¥Ç[ÍQ4æ›.¯º·ÚÛûÖ˜îÌ!¤LÏ¥ù)Èç¯ß[|» ­(  +©>uÓ·)ğ:W·jÅÂı3)ÚûŠBÍ)	 äéóËoÖSö¤€ªZjêVÊ}Á¢ÿ¿¡ï3éÁo†Ÿ©Õ´³|n×àÜå&ÏÜ1£Ri*p\#dÚ6]äG>ô0G9âtÌğÃ4îH
.ï‰jI*Ş³N0S¼°2´®´øT™v½1¤%ºõ{Ìëëê—ê},gµÇç ¨÷†9RJí2#lQGå+ 2>¿vÔ‡>½âX Ÿw{'IDc–ı+ÜİšKdçØ¨MÖF*×xPÁJnÅ„å=ØÔÓ¸/]& ‹×b€Ği(@jº)Ba,>?UÿÖ/´Ë-2§iC©|p’œxM¢=¿9æ©^ŞéîbäöşA_öQnã¥úÕš.IGÚ^]ı¦a«kñ@|Ø® aÊÀ«HìÄ
(|Ïô|€ß©5†şD£şl}MgœS»36‹«ËÉi·°j°Ì¢Uh;èÍ|CJçÂ”3­m°H‡üŒ]f_fSQqş-Õî¨«¿_P'ŠºmøÙ>ÉŠ{Ò#Oµ¥(j+Í~øêı¯xa![_n¥PÛhr“õ ?üª‰à›Ùd€»Ì×céª¶Ñ±wwæ§·ô¾}máÊş‹”¹ñ	Õ´ãç´.H­Zš§Ç](Ç°
ğëçÂÜŞäV½Yú'ôÅ-ÌdßÌ×á^È%†™;VÜ¼ù"Uâ„ĞØşÈjI\â9Ü3¯Î¨·ú?¿êT»™¹§¡cÕ#§ùd„““ã*™âSÀĞĞ~(Ä[ˆ!òU'¾[ÔB•b©ŸÂ	W±È™‚•Öü4Dßã@íö¦ÑİQÊ%‘´ìÕŞUR®ı šéG'²î-_7éeå0£‡˜UXX¾÷[ƒ™:¢díÊ3ÖWÊøMÌQLM·µß:ãàÇò…ö×½«xÈdL¤VÿœªÅspª•ü†›º®1ï—w‚,d‘jP¶ıI´Üòãp9cñÊáWÄˆétÙ¿8p@‚¥_Oz«\`ÕS’JÆ‡ú_î^ÏA>nTÖßä‰Ú¾\Oš¹ÒÓĞ)h¼¶¸-®ù©çñf-Ÿ ›½ªòwji‰ØÒ¡`»«‚Úg»rzñö“Ş‡f()	ØŒ¤ ‰ù~››XôÓ­‚N¸aF\úŠc —°³¿2C=»ç»Ô7°à]Ù8µ+÷\°øBz²³
î+0SMâéx**ôñ•îXó…€ñ–Ş,íl¹•m>Ê%0m“Ç&v‡süô¨sÑéœÙQK”g–¼lå:BÃğV_­k]•Zv„¥×Ñ
Ø§ Ñ\ğiBL}§,ùäĞØ<Ÿ|r>Ÿ8ª•‡Ş[¬C‰i·Õº‚aÁãÈMÕŒæ©nSï¡¥¯J¤éÒØÚèš7<u"ÃW¿tÌvş5–KÀæbÙ¥zøÜã²Û—<_Eñ ÌËmU_Ú¬©œ¶¢2ûî ú¸]3÷xóqY"'ê]¢=NÑ‹ro[eHş¡·6Éup0"î•pß}YG©ƒÈCã+ı?ZÇ" »DeclÒH®ÜóÇOîÔl^nwèÑ™¡c|U–ô‘”<Ûn.IsóaÍ§÷ğ‚‹ç³LazœŸw‰:ëÛÕêhò‡ßgÕF:©â¼5×›—¤jÌXŒ	†ÔÉ/Ü—ùËiyt59İŠbìCmÚËâ˜ÉJC™Ù¯Šr·Ö6İlnx¥İkE)ÔˆÏTk†€4}¨G¾ÿ	0-Pş=lÑ¡Óı”@i%Ú[Áx}ÜØ¤Nb"O`ZKÙçµùó¢ÙŸQDşvg{³
Î£f–à™V6½§r!Duğ£?¦`
öÓÓaf¥jC±û0ïµ»Z’Â„pîJ0¼‰±1}ƒ¥L²k˜öØ8;Õ8¦ÈM"\¥“t;	ù)U¥XÇÒ°–Ãş·²Hëûëxğ%éÏo™	jÅA)ÛX».¤!`nëáH)¯lH6‘²oÙò+,ûx²A™&çÂ³ÍØÜÑˆğ¹{6ic6*Z
ş£sŒC­ø)R;³›‘lĞKÙŞ^‡fÎBÅxë>^Aıd¢…óf½o?ÅasxÙØ`Uelûƒ7tVáËÈ2øÿ„]×§°Fı»<-İW€mĞ³
ù”Šï°
i@Q •˜ä$F+ğĞ„áúİ>İq…0ÊC†I˜‘ ß×™ ÀğŠÓ]Ê9…CÇÅ%ğL	}Qğ‡S×AQ(–pûQ¾¢É!2Æ~™¯¹”¼44Kwt»+Šl.oKŸĞ|‹ O<Å5àR˜ˆ9‘Ã¤{¼N¤}j[>—?2b¾˜ƒÄÿ–­Ÿ/`ZP }h(qmx3'†ûÂÌ\;jAƒA„Š°pÈËÖŸ½ì?õ`œJ)ûw‡Ö¿VÊoĞS¨S¯'éŒ^ÒdGs¤¥ ù,ï+°åŠŞLğ‡‹P¶ôA}¹èÑtöô	Ô¦>°O£ªô¨¦„ò&¹Õ[·ÉÒ†Æã‚ZŠ}ÉÄ¤’-ûK"k0·Ùc‰ºªŒå]y)Ïñ ×òe¸ˆlÛSš?Û·>Â6ÁBóÑUºÒ·71Í¥éwŞ »ÅdšbØ/å©T9¬á”dêWˆA­?Lh]¾3mgéŸ6Î+ˆÒÈÑüôJ³GòD†ÎC1¡(Œ¬.ìÄ¢©[ô4A˜ãŠşXŠ´+ÃœÑ*¤ROÎ½}.W‘ıK¥{(ü>±-ìgXDJ úaEŞ‰îöœì-ù^÷ñ¹ZpÌ®•«˜ñÄÉâİ+.|´á$æä»Ás	$ê9ĞzÙ.ÒT»EùíÏü”D;ºñFx[‹áÒáKİ:¬
 ÍtÍ­÷¹©½TØ&iZ²İšG2}†gÛfbtê±[òµ®ëÌ½C »7dœùï²ñGËÆùbÄk`$Z©c›¨UÙ·*°jF˜ÒØ[ ~Œìå‰cU‡¼…@)âü\Ø`å†CF˜­Uq–~,®ìCèozrÄ&;ˆ#¶{™aúÕğmœ2‘§î©Ix‘{¿êë ÔØp¿Êèpø®ÉŠ¾Hş\ÊŞg2èqØ‚X¸Êğ>°WPVËsâåxŒ~Ş›·¢ğ¹¡„sªpú-l+rwj-ÛNPßØSA±"L,r¥„X|9\ŒÆÄo{ ;šÜ{VÉ@‰Áf»4ù>(ãƒÁéOÛª…Şrå÷`z/6ih¦œÁ–·ÉŠÛj¿’şØ/j¦lJUÍOƒ®›ŠH½ù…Âã½Ex
–!,rì89ªæsnÿ%Avê á%·@$™İ,ók·æ²%åy‰Ğ¤-7DaŞ«%•}TÎÔµĞv_Ew3J„La€3-—|Õ–E2N4µŸ­‘-ªò}S®…¼aç¸SnÈ×yü¯Ñà#½i
XÓnÌÖf@¿’éÂÕ­şê¢]	3+„E\^Vß`˜ˆ´\Şš²b-ßT]c,Rç› ×"™üœ®Óv€ÂkºBe/èR=mÎ9`Ài‡j3­Š€<ndVzßÅ®phè\mĞ”OªFqù‰P¼aZöÆRĞ§½‹FOÚ ë‡Ø²ù<XwT]ü·©LrıĞ¢âëYë~"¦Ïİ‘	ë/F”ŞSq$ã}ÀWg„oß°ÔÈ1{$£?ĞÄGé~KY±>—ah`Ş<5ï¼€Ü°D;,Øy›¨»ÊÏ©ë=®“¥ï&¾ğãˆQ~^_¾‹Ì‰F2Ô~\Aí³zö²W"”a‘0Øb²#[tTD]"äÎ·#v%}	½Ìı	M0U'‹ßQíI2]“)dBªEĞá$Ñ$ôˆÑkTl]Ùu…ï?’¥*©}]‘ öy3¤]9i¹Og¢)(*;ÓFŸH¢‘ı™d76Ô£;“á3M¹4ŞŞ+ß_d™’É	¨xuçPnòÜëÒ:#Ì”*¼=^ò*z´9dGøÆ‰ìíO 5v»eY-¢kÒ’bÀ_wÂ"g†ŒI”ÀÂùâHÆ@éäAø¶GÙ²zì‹ÈĞòWŒÅ…l©6ñãXú–ï=éÈ» ê“LÃ¹…»%(jvfG½÷ãÎ” »YseDå Š€™wlh	‘œ©íFØ—ºìºõg·5JƒukB­—Â&K¶K/‡««ô!iÄ™¾¿Ê¤˜‰ZÉÿÊC$6$QlïûŠL™²Jc"µÚÔå8‹? §ñ“ëâÜÙ#ÊÛ³%Ü+µËzá¾ìÏMGe§t3©)6ö-÷e4«1ƒMUîñG˜Iã:´”*{Í6'ÆÚmû‚\¤a"wà|nbÄLa*Rˆ|5ÈÍbQÒ6f£eñù`(Ô–[êÔÿ ë4î0rğü<eÔ+.‹¡Y®éTr•¦´$ËºùÕS(ıO90ş‘õDS½:+-døŠê;îš"¼ÕBu»ŞòG¤m^¶åÉ²üGg„©“x§á“¤WuNLÅöX¸9Áô;-áß÷Ü‚·ÀeââøÅpRÀ:–Û'OÀ—{äª9C¦ÛƒÙ™Æ:ğC 9•VÔWöY ûÎ+o»siü´ã”¹1€‹§¸K.ä<¤Ñ¡õÌÿÊ5Ï~ ÌDHÍd½Eµ¬U
HÆb‘MÉZ}ø‡­f1ÿA0“h]Ü;JıÔ‘7ğöÄk­˜2t3ï
}¸«Eáuˆ€Òâ¾áA}Zu ¼2g6xÛù ß¬°«Hé¾c6úõ§6ÿ®Õ2AÜ4 ‘rxÒP#‡‘4¹Ø‹»u]™|UšÅl<òÒ«GÛV”Sö´—®¯¿oâõáâSU¨pÌ™)lVá³ºŸë™~¬Ú¾­ŠCå³íìm•=‡5IàÃDÙM¯QÕx–±\‡ßÂÛW7&`gVÌÌ&îd*¿,u_ûò–xHãŒK®^ç¾`oÂŠá¬‘§‰{<!Ş[À Ccõ L)}ç$ Œ¡¼º–ˆDÄÎß{?­Š¼xúæà0SZƒv;Ãê_‚ƒÅ•¥ü©
6@6¨f‰æW<„Ø=ZZ;î|Q	3ÿgÄ„¿ÂL"RjW,'ÚE„ì™‡ÛzVIaY«jØklV¾/6íI÷1)Òd©Õh„éî‡ˆıi¸aÎ·s––&/{<“'ä;£ZUfÙËgMæŠ©òvô!«ë0|
‡cjüî˜Z÷’"”ûu]’Ç50»
¿!ÙOµB.ÓøS…ô…¾ŒšFuÜRŠŞ"n{k&*Wôò¥DÎ²tÇ-©ebëà˜*~k¦§¾Ú!G-dÑÏÂ¼Âòn®£Ù•‡e`µ#ıwşö=AíÈÀä†&Rq.Î6ÒüÜf•b“àyYè''XEkÿJy³D,MbJ-î… gukÅH¸¤±†9;¿¾\˜D@§à€Öq‰é¯´¿So&-$N‡Ü"ˆ-e—ßÀÑGuF¾yUÚY» ûİRdnJ‹í=µ/@ykÎòá¨o…»hÚàå?­¾f±º£*KĞlçÿÌà@:ü”ÇY  `^P‹¶™Ğı†'ıâ$‰ĞÓ½õq•´¿ÇLÈv@ªk0>¾œ®7“©´Xå'“¼ÔÀex:­ÃwŞŸ@;è¶/XEô_ä$Æõ÷³E-SãÕ•Õdó„WXäÍa£àFŠhôgƒÓHNİ_½¦3Ø†J³hS½	Q²è4ŠvòÙæÃéİÆnÆ$[½ƒ>2®J|fY8µØ¦q¥<õbÖp]Œr(Yd„©^š_•†c[˜€†İİ~´Å_Î/ŠÉòQQô tkÑc€1nV²$Ÿæ†%¥ÕeÿÀÃFYO#–­âˆ³KVWU cŠ’i‰>àÊ×’ï4ì(ğ+'“eM|€ËYÃ–`¿ û,Ù.‰°›÷“èl‰>¶¶ZÖ“p‘Öwôt?™N,
t™¼Ùı¢Ù= «4>0ÿñ‰3ù¯8…çlè­Šuè¸ïˆ9%±Mpÿ Á‹€Ã›D7ãí#…¯0g/ƒã­y¯:â+{$_:}3W°ƒÓ›)ïy{X‰_ÕwÌûÒK™haÁ)ºÍ06  øÙIcŸğkHmÚJ°Ì‚9õ¼»ñûkGÉĞg…Ø­· „ñÖóó
÷‹—käÈË³pÓÚÏj[æÃ™“CŞËGeüîš¤îòj”§—}ĞCá…ÇêûñÑ1C?§o§glF¼Í¢— —Oâ±>EÕ^ˆÍ¯Äõ'g]Ga„³~ÃWW¾JQ8ö¿Âr»Ä"œR6o{‡6Œ/j°XÍµ:‡½Úº§qÛ5åF¤VµÒÁ•äé"å·ã°¥Ëw]¿v#«‚¿fõ&û¤Éö®ª1±u¥”CŸ³àX¯ 2§uƒèüy‘Ã0RÿiÈeõÆ‚d^	Nƒ’ÕŠÀ«V%rtöy)‚=i÷i`3#ä…_à™!"/èÃ!ªm2€x©·ì¿MB•RE·¢†–M@/0ÖùëB3UÀ]¢TköõÏFö|ü»9o>RCG°»q‰Z¦‚ús  Ârv?e25J]mºjÊúLlBV‘ä"‡KÁ×©ÿ  ŞVGÒ,·#½¬«ú\ˆfäıÇ<r´Mf+#‰î0 Vÿ¨ª‘îPb(_3d5£6Î·‹½“4àiîæøÇ]¿Ì0»Ÿ)ÜI~Îı¾İFt„WÓÂp?Gø51ì‡&±.çs’ÅNM(!€û²{x&I+$û›ÓØ¢ÏD‹X+!<ş¿¯úòNjÏx‰ 0HÃ"e¶Qı@“E×Á@‰©kbWGc-LÁyŒ—<å túzû}Ò/a[ĞFÅ7_µ [)9öç`1}rô”ÁSl¥JQó#¦F.˜“™5U”àìüôX²!ÿã‹#'˜ÒMƒüƒßôòì£ é†ÃVåhM=tkĞ“ã¢QHÈ –¯AT‰},˜‹s\-K(!¶÷´AÁFùÉ¿û|½[°Ğù>šzA-§Bk”ætVÈò:Lµ-˜¹Ú³ßë£»LÕÉñÎyá:›õy¤Ê"–ÿD~¤ZÊx¿"…YâÆ§­jìé_ÀTêMÑÄqæêªM°4É–ÓØ>|ˆÕsKQ“¼êº‚õedbŒdjÕò©¢”c3N¾ùPIı›c|¶Ö&ÃÆ…a¡Ğù¬*òJn–Ø¬tÕ[S7Ù4"âıöÅiäõR‡tWJèÈŠ3ªGã|ÚöĞÅÂW‘¤ıÒl\àE]ãºlXï~éëj!<^à‘X`m	òbë T÷d§2ôAâd$û¢|¥‰È:S¾’¨–X}ÅL¬lUßtµ\P÷µ§8­üó1\c/ØÇ<d5Ï‘
’Nî=DÓ8S1Væ°†»Ò=Î”¡>ÀP“¹Å'£’D{²2*óSctßŞ¼K×xœªˆ#1ó®¶en2æÀĞ¢‚N^ÜWMs¬íÇ$nsËb¨l÷&¥Ê22R†BšäãµYV™¡e“]dp1ÉÒu‘„ÎCÓpF%XĞòÔdSô¹üq ãEßiúŠ'mhUè$*Í7äP>q [lX¼ÑÒòZ,„Óws‚ŞËY¶²&š5[í®GUÅXÇ)z„¯æ_¾ò
îZÃøéã)w1æ§¼î—Y‹w’ ¤İ7†&$v£òÜ)‚&³hN£K!é@JIz,~Djä¾p?Fk}2Lœ?Åø³êÄPêï«~ÒWÖdI"†eÕp˜ãˆÙŸç`óñ“¾(‡ihÌãÆT 29åÍÆ‚3À»Qpó9‚ßÌ€Ç ÀàÌïYi&o6™Q'nh¹œú›©í²›%½WÚŞå„Î:÷IéŒµ/ÚZt®{…L]VˆpŞÀª/û5ÿe¨Š];Ñ|÷Kgÿi: ©< [&\ö£-j‘sA†ëBù¶z’'e
VãUĞÌUfeAàJ²‘3‚Ñš¸Ğ1(}ÃÙ³]IS%ÿ_L6$FÆ&Œ0r	gœ¾: gÄdA9ÖeCGÀ°_İŠ0@ï=¢æzO–Fç]U9yÖ »£M¥¾-,¶^Àm‹ô$`1f<´.;Èa§x¡Ñt¡n¯è‘Û#rGJø«Æ7J= F!›ªóü.&=Ø°"ÎiZò“¬óª6/Òo‚&<Ãd–ú;x@Ú<&à]àlu«è
í ÙBš´'T·ö„-ñ­´:§dfıîÉS&ø5c<feĞÉ!Éi0£ÿ•¯k x v÷¤-`‰:IÌ…o	8+ƒÂ}“ÉÁI\«2„-Fäğ‰p4¢ûÅ2€¿	ö_¶,s&ƒû4Q]İL¹a;ßÎ^?2´n…Œ¯x$ëœ“L‰¢ö¶÷Œ<˜¹Šcç<áey°ô ‘Êlä³(rc'úé€qIó(®§ÜødirKåÄüòví«¤¦ÆLØÎçÍéÃÍimü[SLµ›d£ŠàRª¡£SXÈuRÈCí…míÉ+üÒ¡l]ÊÒÉö~€½ı &k#aZıáØ¡ÿË‘âzd§³)ÈªúËÕóSª’f“Tmï\Bÿ¹‘-_eâi
F„ÿ-Bkk¥¹'TRŸæ³jD+şÂuU¡]Ÿ;Ë]×3P>¡ıÀ/Y#¥Ïı{æÃÜöd`~mpi»EÑì\w(ÿÅçlÒ§·LÒ¹p§	ÑÓ&’åezùÌë…ÉF›ÓD V‚ñ·­Ö}•W–£˜IZlZ}S¾T=a‘•w[ı`óïšİÕMu ¯…p^£™jšÚş';OWœ=Áú œĞê@ú×Ì$ş>ÍÏ÷CR	6Íå´ÈV9}ÖN0™+ó.€’Ùßz(ŸXOV;s’ä—Œ•ºäRx]Ğù½SM™úiÉáŒ0 ‰,btûJ“B"[n•*Y}ì?_Éİ3&^ÆÀ›Ï‡ŒÛèòâî Šë&ƒªİc†ıqû£<®·™Ó¡¤ùÜÔC’qèÿxw·¨Æøk=æÚ]p<O „ñõ¶â~½ç.¢wLãuPâÊ~Ñ·Ş²LôP~,¬;"õø‘AW]»¢1	ŸXšı§Ü†HPÍê _E’	Ø¢Ú_·Sè4ÃMxŞÇk+ƒMË¶äAW"a+±c-]¹ë(S¾)ço®t‰Á‚‹°‹Æz3ƒ]/!ƒ|¤ƒ[ú®ÜKÓ¡æµ …çÙU@Y–°É•ï¶¢}¤Çèev5ğ©.)ÌÉÌLÔ­[àõAÙp	Qü±q¬©à ¼lãWr¨Ÿœ¬:tOda"±–AU#êàæ©¼àˆí‘R8ó'ñÃ-¯ò&ÿÜ&âi@[Ô`À@)Ñ•ÒG=k>:OtGÔm)6p³¡ âRwO¡"T,©‡ÅQğ I!fyéÀÚŠÔ'‚*`¡¦‰ùÃ.H°Ngh^ïá`³‹ßÁzZ¶fdmÈ´ 1šé­0ıÇœ=º\CÑß:!~vNÒ\MÈ$œÈœŒ0Ä×êønnmÙ‰ø±SlÀuƒˆèÍ|wƒj}Ï@B×£!Äƒ¥~«0sÎ5¾;Úl¢ÂÑA]'&Õ÷Üù¤Z+Äi:Èå×Š`£
w	M&ã<†¢(¹ï†WgÒãì.­kq€ ]Á‰H½g¤éİ@ªÊ:ü“à´›yVM
"E=”§ØĞù>.ôõí*gK‰Sõã!P§AAàÆ¯P¾.ÛİŒdwó=Ë>ºÖ£¦fŒ)1š¿v¯BûÒÂC}3´¢0µ=Ú®+Ø`:¼Ã49MÀ÷z“£fwbÊ®ow«xÅ}ŒzæŠÔ¸¡>ÃşÆ‘`ÜíÑó\Ë°÷¿çÔÄÚÉµŞ¦ÊÔØçÇûŒE`UÕ”=é¹"`±¹Ÿ‡Äb…„äyÔj®h
×@ÃD7‘ùNñ„všGÎ–:vm“T7ºÄ
¯¯öN®K.ˆ(ØàìdçK7|Ò¼—¨G®]‹. è@±p¿Ü«B¢fLZ/Öê’RŠ¢3&He^ÿƒ_Çtşl8vŠRæK¢ğŠ¬öåu=ŠÇ`èªKrİSQ×†ÿKkKGë>0Ú&n&)dôª£ô8MÖc¨¦Dû(Ú3ATÊ­cŒ!á©%Ğ¾¨|à9w˜šİZèA›ššÀÄşM)³>—+-	X^x¿al”'µ:ÿà#ßX$µp³JŒ=^Ö¿&–üÛ³\7Üp&Ú·°1··¾Gúx6	D*İC=$çÅ«ÜÄ{ñ†Šû· ö
Òî70Ï8Ø+˜]WùgÍ]uøøı?d·7†#*Ú7…H@èy–â8¢„OQÖÇdû~«QWs¬iÚU½áü"¾Ëtˆœ£™İ™"?LŞ‚Ğd›”rqìZÜë»0í­dÎFÙ<æŸTk¥ƒ 5ylìGìJ1G<µ™Ó‘–CˆB…±_å
¾àRw7iş"óĞ?²äPÒ˜tØ¥*,AüeİS:İtï3ÜÜËÉk¯À7A ¼aqsõ¶İ‰€Òİó­â _x°u«ù4Ô¥^·¼…›-ùHÖ–ÕÎÆº‹„(Øî ·şæ‰~õ¼~úI_k¤€Yú,äHYB#ñ_`‡ı%u¦İ 'c„Ä*ÅÛÕªÉÓg
3 á,‡ìÈ÷Š".€ÓY%ı\´4İüšÃé€ \h.°Sï{c3²”¸ÃËµîúz ÖSìÔ¿ÊVÔF‘|vÙ+Â^BÃ£èd6ò¦„â©@5ı¢ÙO±â	İ*·»O·À¼»üš&v·ë»áÌìcHsJÄ°Ó¬Ø1Û³BİDÎëmR~¿èlN4?cÉRq•{9ÍD«èßaŞç4q8{ĞºÁóe5?\ÉS0Ü¦íkfÔºµ£}´—e9êš¼yd)1·›v=Zá5§½5C—œ[ü¤kÄ8ã¤Ğ_êÈCr=—éeMNuxkC>Å¢ĞH,ş2 ÏDâá2±^XÉ M¾2D0åI®)Tø@-UìUÕâA.T:îX\™´ƒÉµåúùD+±„µ7x÷£ypï#gÁTçK®*\&›§w¥LoR9Ao¨SyFGFì|=çTZ’Ô@uVn5…*˜RÖÙ˜‡œ®ˆ+ „(z©;YÔ×_)*¾p™‰ÊEÌ/ë ´w|¿„M‘õ)úi¢Çb0Ì™$*…3Ë®©½O;›~g³y·%MÚàü_§·éA…P0eBuÃ9,c•óP‰Ë]S7Ôfw‹/ºBT^2©nğ¥NEæO«·÷ÉM˜Ëh!J@#	¢#H²zlUÃŞLYÖÏyzn
¾³œÄ+º0É¿`éÊ×ö+-¼©öyïT>•#F¨@[‰‰AÆô³.Âœm:KŒ–¤@«àCijŸÏ$DQŒ æ¹ft+r¢Ä6{mşŸ1¢¶5K´B"r(Ö‘v†“´¦kÜWwõj~î˜ÔÅÂYÜE³bQÏ†6»ÊaÎÕ(.)Õ]^jiXà|Sun€2ïSıQÚÿù#`O+)dÕ"İÈF[ÉwÒ"8ÃXbƒ‡Á}¬L°Ò 5 #§NHEÍYnÌU/†ï ÷ŠG(d5hD¹rbKfË‘c¸/——3*ÆŸÀ›c·™AÜÌtc×G+4	Ö2ÄÓ÷iRàDfê‹&¿Â±F“ü×®x¹µò¥J±ÈíÄ&JQ’«øsJ)8¾M™óf˜÷ñ	M8dbOFúÜàòLRq«Fbèøí‹§R®û…iƒ<hHwK3WJÓsXÄ©XĞ×Ü\qÑbîÇd<¦{İM$Ei‹¸o=N“h£ h7¿ô :¨ß=Å:©¾ÌİšrÅM™jóµ,Šl?.)à4·ï-@5Gºä:0ºS4rzVY¤Î{É¨<8çÀ1’[µ‰Ú¼ÌaP¢‹<
>…œ³”Õ^Z´ÖÕDBcWô8ìå¥š¸W‰§‘å]&ğ«RñšÎú¥{q«zÈ>Âfw0	İ¤ÛúÛøŒÆ º¾şuÀò»¡	í0æÆ›Ñ•$ùÂH$IÑ‡hh¢Í†eÏğ€[Szª4µ2Ô°uçîî=b³
 Röj¢°ûÿØÿÃ=Œh÷©N¹-¢ÃéÍÕYÆtÍù;4¨BKs¼
T
48TyÆ*…Ÿı<›©ÈĞ7ö®{WˆWG·“ Y÷€"ûà”Qj-HfÚÔ¼NöhP|K™¡²(¡(¦)5J]Ãª#¦ótg'EœÖØ·‘¥Îá/·s!ÅÍWW7ÈnÃA¢Ü;Ê“,pŞqºlâ»:)ÇdğV×~ÖJÄ?¡µÒ4`a ğxÌì$åasZZÇº®øú”v.ï%êGCŞLB İe=*¸™˜ÌıS-ÅÂ9<~%xJHÎ]$‰:š¶<hÍâ_cÇ\º„óCq8sqˆĞËÈDİ5ƒ|Ì¯Ğ.ËÄ!Q4HRÔÈá To0Xê¼µ<¼&p=Ë*,'¢	”…¨¬^FâÊx0P1‹¤7Mgá¼élbÜô~à|›C@âÄÈ¨FÕL>CÿH@.<·aßò9er¨ßM¼Ô£§RÈ^¸7L6¶A²ê»»ÎwasŠE–C(ëß/åÿ DU?à„ÔİUh2„Ç7‡«D[œzH EÌõÏ¢0“´úû®¨îp±_ÇĞì¯ä/lÙNöWW©?[6ŸÜ‡dı½·„¾c>ŠÅd«[&ûùàÖ%¼†Ò-±;s@‘I¾¼Ôz-¨Ä–ÎñÕZÊ¶fD¶®ÿ”GxÄ[uR[VÎã®°®¾Lãz§/;İû ˜èìO—ïvcMLc 0hœíş¦Í«DJåHXßd, 1¬ÖIÈR€2¶<“‰ÊRMÏ¢jo`Ä\¼MœÍ÷À½Ê×İm1˜•QÜÂ•»/*E®R¦ÂúZ¼Ÿ~|‹X$¼"­´?Ãÿ\ÊHÔÌqï²z‚É>$W•RiGÇ“XPÏ²ú@ä­J…xé~uÓÿ’£zÿ!ÖL iFQÒ[æeÈ÷fB–Í>aS)‡Ş=°Ùr]Œ„;#VRKŒ€ä=§C½gHEo¢Å™İ‚Æˆà!Jğ¾47	Ñ´âaEâõ>ßûÚ äD›lÉ0°L¦™Ği4gzbOä¯A^(œ3¦3·ë…•G‚Üêÿ-­¯’OW“ˆ¯‹ÓxòñÌ$·ê÷AÀ~¹-®™®~¾·ˆI<ªsºÙÚs‘!tµ?¬ÅÅìÜ3^.{²ïmŠdU·ğ×›ÁÒ¨t5-¿Õ^#PÉÒÛHñ˜‹ìœ²\ãïX‡¤®`ıúdˆáŸRù/‰g­ş—(–×£ª±ã/€Sÿ©•4Œ`¿”í¨š¹ØİağÚæôŠĞËH­™âÒY‰ó
-Íif>N¹/Ôn¡(J(Ì<‰N³Šˆ‘í!$ÿø»OHxrx±@qÄ\ëø…WhMëFğƒK¦ı‚OT_(Ö„às¯|Ø;´×•Wöô=Tÿ©°ÚH8j®yU¯‰´éŸb<Shqì¬çC®g®™ôe1h«r†ÙàêM¹¦F10«±˜$óÊC‘ö°~wN¹AîÜGE“d1²—Ÿ˜r#q`vÇ}»ç†,è»Ñ£•õô3 Ê5-ÒÿRZŠ·J¦K,dBî~õï.åPŠË‡‚¤¨!SÄ9ßÍGcÃ¸¹æåµ1´Ç¶™™>@HcQó)Ó¾è…o%«¡ln‚Ğ_= š/Ó ˜Gò²‹+î\
¹B¹`”isÆ4eßğ.€¥ÛáÉ§Z?`BJT{dGæ°~%½¸_òP’‹äXa:!u©ó•äFi¿x†üùh†JÉ3^XèêÂ¼ú‘;A‘Úrp=oÇ1Ë<¯:*C ú–RúÅU•#œo€õ¹)ˆ{
_)«‡üCA„@û(ÚØ1«9l…(±t
 ¨`9V[^e	J#g~Â«ÉÖs–H]ıÑkL ¾§˜ı—»‡ç‘+äu‘v†èLó-³ñ»«ğ`ii!‚3Æ?ıö¨"æÖj'ãÇd X[¶eÇ†ñ†LÁĞ†@‚øoØQÁ~²ŒÛS•İ› Düş kVÉ—r	µ0¬å?„Ø0Ø‘?“>5‰/å6êØÑ¸Ùßè£ÊLèJö»Al†H í”-!^ÄÆ Ìö‘‘L^;Î`Ñ³®eíæ¤®'¦¨[ÛØÿYd9¡@>jØşn†'-œ&¿éÛÓtbb_@G%òU£¬²(î€ÍÀZ7àÿ‹ÿdîÉèUuê`k"°}ä©ÁÅ]¶»yãké$Ç–°>ôÑ³·"ËwÉÜ˜]fşhW_8©ae‚J˜3ä•N{ãùÌ¼Äõ1…s³á²+)mÚF›ëCzjÛ'£J|&:M_¿nå+X5WoÕhA@:Ñ-FÏvÛŸä­›¤üZìEHAOıÄU7~JEE£Ç†ÔiĞ&DÉBÁ‘1ºVœÛŸ—ÃAç4¢†ñGb©X3|ÄÖÜ>üW_§¼VßD7/¡–VSt)9lBCø¶‘›Ÿ Ü/a0¢ƒ.?ôb/‰ä2¯Ş¢½gÏèˆù0jÏ!í“!¯fK{Â“&Å‘U„óóZZ¾·Œp9gQoaÉØ·1ÒÌñsÌ¾qBU’qµÉ	0&”d5Î5æ=£µ‘Ï-Ç´2Bn«¦İ5~èúJTCˆ=uòKÆü•²ËÎÄáş”Ö;jf¶¹}š§÷_Ğ•èZÆ¼P§¿µHĞ£ºæwÍ{İ"ş`Pw“Ùƒ{õR´ __ ‰‹ã‹ñbóŞ'yXÎ.£ã²~PÚ²›çóízj×â±¼ëOnã3%¥:JR×,Ñ»7ú%w‘.|vg%e¬%–Óé©Öw¼˜œíU…q†Ñ˜´”q="4‘Ú§-3¶VŒ^Y¸õ2-ë‘îò #­Prï|O5ˆ©_FI ÿkÉÜ?©h®—q¾ğ€1C/ÜFÄ#‘û“}½BEö#ÚÍhĞ›.èum¥%œ ±†€_Óã:öxuæÌ¥iy;])KÀLìÕp@à3>§MÕúñ–KQ¡¸Ã#ˆ_µƒy‚wR£è²ÙÚÅV[!º]ÿVìåØƒÕ§…)RğBÙS½hñ1|¨eØ¡òÜ®À“°E¼‚¾Ù½/N„ä¯ vn$à˜/HBÑƒü,Ò®L790c7cÈ¸9¯?÷'›ÕÙŸD€óÉ†Ó@4×VAéHÜÂ~¢ÍçDCÚœá¯í\³‡I*âf9eö&Dph˜tòê@=/m¸Š·`,d¹	Eôï9(¬Ş®%¶õû£½•ì´ÉÑÈÉ7¡ß}ş‚òh°®#UŸÙP5®1aıaúêC¾rTÒüêmå9Rí]©Š}Ôû5Æªó|ê÷Q&B¸Åq$h(ô„®zÉhègŞø‰%Š=ŒëÎyh¡#Še1ó8ùäŸÉÚ}‡ËÚİ£¦åmRªÚ³'I~}ÉHü{t[¸Şİ<á…âw—Íıå5½=ş °œ>öQí!V(Õ9YLH½Ø6™¨ÏÓº”-öïù±cÎ¡W3Š/`ó•ªüãåR±ã+påêK¡Seƒüéàv1"¥>8åÄ5ÁêbNP2Â‡¶Hcç@=k‰7A¿]t¼a»ö¿½¼W°6!½Ufôz¸y$Éë²b HËe9€’X¼8†1ç¶şYru$ Š¬¬jtHN zëä‡,èL?ùäS¤'e=>ë=¡òÄx
ÜPİJ¾QëÅ“ñfÔ3Iç¢,İÕO F«BüãÓG>e½Jë
ş“À(JCağÚ ²n^Gúõ³üu<Pø= Ä
%êÖ‚fLãrQæå§oJ¬Ÿ\\ç^ò F#;ü­ô)/æ+ë6ƒEåš“²iÉkaàü)¸ºÒÖwŠ²@°y(Â%­À¡Ø,küˆ“ Ò¥0aµ^¾Q?8’ı“Ï„Ì”¡¦!F¸%»áÉåd3¿ı([ñ¯±YÒ"DÍF³¸¿å%ÓVĞAÃ—]Å ×ã¬5Gí-#:(>?OÑm³ö¹„â!ã´¯ox=¶#íß"LˆWÓÆ5^)ÚÍç«^@¾÷Ÿ9FÜÜ…—§9ã˜Ğ¸iV9L’e7 ‚›ÊÓŠ(r¦á½¨Í±‹ù˜×ìFêˆkóÇŸ6µ;#µB›œ¬µ«L`½w$¿ÀÊŸSä¸¢´ŸçqU¸Z„º‰`ÑNr˜(Ö¤akŒõí¼Ù5Ò‰,èÎEGpV˜äØ(-vx-I™Y›½@o^õ f7âTÔ†+íİ…Ò¢Í*e³òñÃ¦e¹kU6@û)FÂ¾ç{‹‰hÑlU)c}j
R®s.´>°¾uéôâeÍ·F	ö‰)äI_àpŸ:'ÈÎÖÃ’¨1ÍGpÙ]ÔÏ/rnâS7L‡Á$cÀq•5X&Á{nï1ëÆ»ö§ş„±‚°¾­û¤XUI_è“bb$ò¬Û-$©ëª­Õ_šğŞÌAg)ì®7˜Zd,Ê	X@>^Õîcı"7“ròn·
MÜiá°;LXp"N“µš~g¶Dš8f2wšßÁ7TRîƒQ&eŞñoË¸»T¥R	ÙL»}L¹J­Xr··9ŸJ‰«(nuÜŒ2
	®ª•cÛ=ò°ÍXà~‹²0C@Q¯;^³&¥˜å£,ñn$(?¸h‘Jæ†Zöâi°`4£=l÷/Õ‰4:î¨s¨u1:Zùµ®ùR¦ÿÊ
öHàa‚Õ& ÓœË€»Ş=v€›»Ü¡÷ß'±Áª©ÿÈ”r¹è/ù¹·ÖAÂIëÙQÍy§ˆ?3éXğğv¾(:!gŞR	yûE¾ÿV¤Y¨®ù°A“­Â”YùkàxqTîš´"Ü`Ó(Á±K:‘+ ÈÇƒÖ}pŞ›6°ÇëvepÔÕ„¦g'Ô=ÁÙÛf¶VBª+åœ¦ãˆi)åŞV@[Ã#(‚Ò1±ÖdŸe.®]ãœ!yEY`T€.Xø‹ÑÚÂCè¹—ŞöBä’øºâÎD8ÔEeïÀĞ+{d¢Ã¯¯AL„6¤÷zå—ı¸Ú‡¹317(Xj™&^¦‡0Â·ñÚ7ép4“kœ˜†ä™?ñšF¾ü¾Ú	/T¤1Ê1«ÏEW7›~|°`gãG›Š’;Û¨ÎõlÒ¿İ¯?á˜¿¬I°Şùmä+¾UÕ4ì;Ú‘^nûùîİZ±“A\şz}éî[àq2ÃÚ9sË¬â¢qc ;fJ© 4­òäÇÙ¥Hqpöx3.=—Rİ¬Œ28 mFRßÚm‹şëFjæBø1†bqbA•Œ€XäñÂÔ,¬zµ›A1=ÓÙõQ#Â|Qf—,†ñV†D1º¶nÀ>™6„Xt—†C*
c¥œĞ€Å^«÷Ûá?ƒ]m|ç«K¨N}SDPÄÜäv‹@–×™7Éo±HQ§×ı%»=Vf_âtŒ´şd)×zzü½fúUİzGk÷äPòÏ—ÔğôRİÿ<1/A"Ú55ôC8¶éù`bhÔpL·ÅævvL{N /ü_jBÎº[^LU¸* .Wà|•xÿ·%¹¼€„Œ(aÁ%Ç•>ôÙ• «<Oà,4İW{yÛ€Ábç‡¤wrL:_ºé˜\í®YŠº7
÷¸Måäc}ì
¶o¾‘H`ú…ÁóÁ#–o}OË`¨VºøzìÁ¼D‚‰÷¬’Ğ	!RüBÑÇD1ø‘ÅïZtmoyN½›;Uaú“İ4•-J-edŸ¸eí«l7âã±äeü9ú¢n^â¹ÅÌSKªö=ÃYğú„½äR[¬TZ4Åoy0îáÆ–"íõt#Ê*™ş#Sñìé2ah»EZZ5ˆn7}/à4Æ-&šd>İj•ú²KÓIK-ƒæh²†	dOp<™cq¶b–*ô êÃgÔŠ|Y`:ób+ç&nÛ‰V¾GİkL‹˜™${mEÉ›R!x£™XÒ{ºXôª×>ömËÃƒû!%øœ`Í!‰’˜A´8[÷èîzG#ñ¦Vîˆ%¨s¨Sk4ïö‡?âz°‡,Öq¡²ZšHZ†I–í=VãS)A"¼úôá&œO†ÆV®¹³,ƒÃÉF<v…¬Ş§«ØxÒÿbå_'Ô&˜4y/ûÒsÄ0:Í<Å ¼¶#.vßˆ2¨…äA® OØàGPlŒIT•êH]©Y«Ÿ^ÂÅhÅe³‘ä’ gI‡eDc [Ø¿\T}9î4vMÓ†Næ+(Y£¤ÏBÌdŒ¸]îµ^gÓ–È‘qÅ~{F¶ª0I ¥kŸôª|˜g€Íÿ>3‚â>2FQï²hÑ(DµùZ@BxÓå›ïÂP]''.4Kê"÷ÿò¦è'‹MÌTŠäùAÑÉÍÀóÛcqÑY»XÜm´‡kp"É.Éóˆ-UprÎ¢K~aJ@`„¿dU‰4ƒ¸ªv#Ù	´Z¡ÍRyµPËŒ!†«@?éwÃ»?ORSw}Ÿ9:âñŞ)İyek“l„m¨›?Å=ÎhßïßóMØÂ¯J‡Ñî¡8xVîÆQ€Yâpšf9Åb÷áÎ5PÇÁ)ß´gæÚÍuC…ÿ,µ^EĞrŞ“ò–FWƒnw*Kø®«9¡QAY‰CãÜ%‰·‘T——«(Ñ!E+Tü’V¸£7~<HnÁä¨^›·§j@ì)ZúıÛİXc	úÍ*Uñ¦¤`UL¤«¡Rc Dt>DØì¼>Ü§™’.Æ†²¾Ü®f~»Š‚Á(Ö‚B³<4sL¬æ·W—iš€Y™xèğc]ºVÌ¶¯ˆ.§#…Ï>{é77Dyò÷¦+ã\E[û¾¿m‡×ŠmÅñ…®KØøöU€9 ©Ö½QO|*Y—'¹ŸfAıi‰ *>ÍÛÀÑSˆ´`:u†!Ğ0êºŠÁlÅpLöğ2¿ÜÖÚAõaA(3rà^ê ¡¿Ho8âê½âƒ[æ¡±ÂV*IßŞhlÏöw­'hóŸ!ÂlàAa>™üöR³Z‰‘ÂL[Âç’\ı6¤ïÈå}Î­¯,1‚Ôä‡ûák\ÙÂ¶8rÒäg á¯+'uobO¯¨gÖf UˆÖÀÂ:İQÌ«eôÉV°à¯>)q µ´xûüw;i†%Q,RÃğ
B¥NÚŸ¬5'šº®ğKÜûÎÇ´yhVe^2W…ç‡X$?aö½OäWİÒÄt«Å†cÏİ´¿$îu3Ï„Œ½‹tH•b’héIw`}‹ÿ¡/¸pGHÖÃP7ˆØÒ'V`‰	9 L&ÓÔ)ûòŠşÎ5åšö¿EŞ€	Ü½6ŸFœëÒäƒ“®Kégåª@ÃÌS9á´›q‡£<`f<izSŸqşµeØÜ²RÉm(ùXWåÜêÿß°P”¢“‚ºšÀù²hpTÓ 0@.ecæı{¯˜;~èÌzªN>2·îÁÜu2õ-äD-ç-ŠÈ®$§í?ìC‘³1¡­m;‚²b:íkÁò¼$
½»¸$@İıÄĞã¾ÊGOœÃ[Od
ırå5Â0ıÿzÅãÓöx¤èó°˜¶XnßŞ 0BëÇ.â¢´Åú™Vş)¬*™ëüë¾·f¦Å´Ÿ.õ,õ>ÆúxÓé;íØv®éÍÿ@TïŠâÉ9e‹5à#]%"7o¤¬–ì=î«rÆËyÕøqh”ñ€v¤A2Lé¬ÑIí.HË½ˆ£9f/gÔYuÚş‚â‰5CM=Á$×`Y‚[Eúp˜6ÆQhY¾S•*BÙ®ßI}Ì†6èÉÜ:‰Rsà´œ„â_Å¬Fî~L1`S®—?e.y‚ü²,pŠ†d¯²»¬2>0:´WŒ¯­*\(§Â­^–3ğ9ßñußfØtÖŒô`xfÇˆ©	£]8m·mQª
õôÄ
`†}>«[ÊŠç€èÀ:º~p>ÀÆ·Óu/)°YÛU\ø÷§˜ÁËCF|å³IøeäÿÎ•|ã«|Ûø¾-é—Î¹OU™×~‘Æv¿ B²}™èŸI+'~ûK®ìoÈçı€_†^ã¦ÂûÅ$¨@=+äzuV÷|Føl™ŞÓtÑƒyKÀsôDLöGØÆÄL7Yöğ‘ˆ)…UBFOÕ7}»pİi:Ù"ŞCöLpÜ	KŠ$ùİÙÎ‰ü%ÕäÅÛÙEÇmâ8>4ÎÕ\Ks°ŒÉ$ÈUÜ‹@WP·åkzQ#}“³0Ú·TÚïC^ë¶æ59Qá¹ !=Ni¿T®úãb¶k~T 3uÈ8ŠD33÷Ô1\Éˆ$€GŒÜjn,ÂPX÷®y})*Íæ¦}«.$²CÉ–C¯ll	=¯•àq»ôQ	Î×‘
ò›näáLkÎ§zIÉº’È÷jn;•¬Ÿ$_^VÃÄ&$™‡¯ Ä(O´ó·¿ì¿Ë¤š%4k%k®Xw¦ö^³È<¸áš¿G4­ZÔv´Î°Ùz¢ A»wÏC:HwMô†ô
K!Ç´{4°®Şbu³™^D”êEs?ó ¢ûr³¶Bkå´À©ü„HÄÜÀ>-‰E6[Œ^ç©ByÖ0ÀÃ¿ÃôC¨C×Óã«ìËdõ±æ×Ah„æ¦{¡¹±.]ÍšëÀ')I³ºËÎÕ"WnÏá8‡<ãNûQ[W0ôµÆ†ƒaB²âÁR±_^o$¦F«[ä¹*”o9ÇSZ6L(pF¶ú{»|:‚‹ ¿/$üHdôg İªĞDëN~‹å„>a“æÕã¶“§ŸÃÏÃÌãV¯˜+;+’òŸm3'X
…­hè¿ bõ05+¾øÚB°Î…ï¼6 çÊ¿ö=Ô3^îxı—ûÄÈŠÏºƒ<Ş/ŞÉ[™?)ÌµÕç¹l91Õ'X›rXÙcßZ­G1Y~¸‹n‚êNPÌ=şÛÁH}ÏÌì*¢İ³ş‰z×Hu€‰
æäÕ°±’ªàgª:%³¢¸‚R2KNÒ9­‹ÀkÉÜÍP’/›ìŞ¡.¿±@‹  «ÉHà;†ÿu+Ø»‹ÍÚ—s›«M
?*¾W¾ÁÖT«25'DõÜÙË5 j—´´_â¶mZ0õ™Ñ€2£½º­^åÉ”ôÎx£"”¯GkTKU¨ßÑVU´¯é
êŒ†\‰°×À'gæeÓë²ó­"áGtŒ:á+¾t£8ØÉ\‹§£dXÙšeß.cË]›0–âÄTêNšPâõq§æ‰6¬MÏbÙ-š{|Sç²Á©İ6LdùÎà>Kï°rê|N\°8{ZO—u10Yôå#út6Ó³âFûû# ”l<<ŞŸh}Z6«@hˆqâ¥°¹ªãpXY­N…:ûjÎôä©ŞƒÖ ²©÷çĞ•%>6R›ïG'´¹çíúZğÕ4gü¹=jwT~À
hÈ”„a}:Y¥‡j«/Lç±Hù‰L–™%Ô“`ÿä6ç©XnrcoT&D0¹eÒ.M¬ôÔf@uÀ¯[Vs½Ç²ğæ¾›T —Ó1¶øUj¬»CGö%Ô¼½ÏÀšÆT—5`ÇG1Àüà§ñè"o¨e_E²Ä[v«—ÔÙm˜kPTïË´ñQ;¨áç×²˜Kç1#™÷¸=èÌ'+q€¦gÕ\ÈRT†ª,¢Cğ
<ã=3ü¯øª˜êŒ
¤‚…W2r¢ø0N®SÅf0İ*ĞÄÏp~‹RùXr*Â«¾–\§8âêÁ¥ë1¦’ÌËXYN›:í°FœÉWøGAôqHæ2ö£ìq˜®?BíÇªîĞw«XOm·ÌÙ‹ìÍ·x‰¹C¸-Û!D[¿ß­(XËxíÒÏ;Æ`B¶¹¯“8èÒxkí"oŸ @‡ÿÙ†?orlÀ©bÕñH¢hã*¯ïkØY<Ú?yš’&ıaòã–àãÊs¼{ €nx	îÒ'ò.n!Ò£ƒ'æãûµRtzƒŠZ¢‡½İÔ8ŒçBz›ù¥)«83 âZİa{Œê$Üøª”Ë¶$\+Ã,s85”ŒÎA/…
pRIÑşµ1fVr^äÖÌ:C‹å°_£F1qí4-ëÜ7$TÂ›Lílî)*!×}KT”):M¼v1ÎâbLØ¸ÓÈY¼”o¸-€ ÜÿôËVÖ®Û9]‘#p›WEcmTY¸i;“×‹á36(ıÀ˜	¢e!Û­ésœÌ}ä0Š?ºãy(¬“‘RùçNÒäL6bXÙMç–¨¿ÔªZ‹KuŠ¿Ç}ıQè÷÷x®W†¶MèBG—	ÛÉ—şÇõFBş¤	#¨£lõˆªó¼¥!xÀByzèTB:w>ü~(¡¼Ê´ûÅtfP­µÅ‰ƒœåy¼S¤!V 1›Ã»_§r›Çj.MÙ<DıkŞ†d\o’µû{àûíBS™şÍN4S-^(ë±Zi;2D1oy?òæ3u İÿFPÀ"åá±¼²6@"w\FêL²×öÄfÉCîÏ¼ñ1µ–²xîw¾f£ztwüÅÒ\Á~õ—^ ¹[êj\}›.ÉÃeãŸ±(3PJBRó9n‚‹ü¥]®ë°áú5ÆÉ°¡½¤o	¿Ÿ
&éCÍÜ  Ğˆ]øşÂOã|?¸-¤'6å \£µ]23¼¡*’´ÿ-x•Qo‚[M¥Á…€Œ´‹ş““ùº¦å¿D+bÎuÏ"èoÆànæ¹ñ…#Hxš° ~‘
|Ößÿ6C€íI^¹ŞCÍÔ|À•øª_8uİí¦‰~O¾½Éı²_ ¼<»a=}°çğì'[z—Fpîòñ¸½¬—®Kñ\LjÆn{Š¬#A¸ÅÛkˆ3vvÎ_Yî¤*—ÿó×“÷Òs:Âo ÷»R2V*xè½—Ü§)	Â†0%µ´Íj—”®ä³4¯Í15$¾µ¨~™»Û÷´k¹µ9è¬¶XG^Yõ-N˜vBÑg¤ÄéC]‡ÆixÚ“¿|£° ä!«µää\ÙùŸ)Màrù»h™·LJÅ€1J·s.Á9”–qŸ°êpÏ:Ü1XÕ-/ÿk\’İŞÊj± ê^~–M¦ó)é|G@ØüŸ:Cqş‡dù‘›“ô’É¤±<e_6eÊ:/–xÿ#â÷¯‰ë	×wË6‰L4°ê5DúE)àJK³¯-LIàCjúÖvŸ®<íÁš È-£ËºŸ¡ßæ+DxÑr:¨¡}ı¦²?Gixa/4uËà9Gø+í¢š¿¿’Ç2 »Gø¢ÖD<ÜLK`óA¦n‘¹‡Õb¶¢²ÖÊr7Ñ÷aÊõª÷Š~àx…ÆoªÄÕÄÜÖÀÁ£XıCy[İ¡åß9¢?Ê7ĞòÊÛˆLWoø’]h@®Ñä¿Ø9û¸9ŞŞ‚õ¨øVvƒq×XÑOËtô´ä›8¤^ôÍ¤õEFügåh›q{wïJü AÓİÄ2~À¥%MÖhnf#dUŸBÓÇ¥oF­M‚=%¯›êÒı“a"Ì²Éxhu;îi‚ª¿.¨îCwø°»‰Ç•:W™‚ğ«Û6ÃA¶ù:·‹¢¼®á4õËîÜÂôÚ1³û¹ÿ"‹R—"óŠñ~¢ˆì_ÔŠC07¢P£¡A¨¾6nQÇú><éÀSZìïÌÄO<ÁÆ/¤zF5S@™Ğr}âÉ[Î•µôs,ç
äZ×|´îeË“®|Æ#‰„tuıÄ§°¼„}WXSd@C„MSı&}epS¤°¿ÚT=q;„2Ñ¶_íÁäÊpĞâ\qÜæí]·s9e´íNrÖíÑ³1›/^qü¡W3s$Ã3©Ó›Óô#HŒBÁSİbzW eÚîKä?A@÷êšrôÖ{€PÛ¹øl¹Âbwj¯%;¦»x4f!Óı³È}Ù•²o&{;‰¦ëjÏmÂßT;¦:èk˜¬8Ô	­(Ò á,‰·ˆê	=[¿ËğbÍCËá/J9ÌØû·Ÿ‡Ù—ğTàj>qº­ÓÃ–}^I=-VğZnÑÎ÷*ºCÉ5k¯ğÜV«oÃËì£½!¼•ä»›ÖŸEò—‘k/uòi8Hy¤‘ö_1KüOFƒ±RËy~ÚÙÇ‘]‘Ú7–g^ÒàPı¢ı•µõÿ`T\Rïâ^jˆ®™Ö²Æîˆ5X—õ³%›ì‰ `ˆ$4uù&üûû_`´~Ìw¼¯æ;P,CÈ¸òïŞº¢9² Ê{š£´>”Œ	#ªÅš»ßn)¬¥Ş/| HNW}»$Î]¨¸RúÌ½LËÇˆNÔW°`1²‰–’n¯B‹y¡eª47Ì)+…§Z)@$°Ëd:Zq¯êÑ‹
!#¬š *r@˜C,cZN·$Á”46oóé«!<	mı„Œ%Y“üÓ>•Ød5§	øÔ¯ib’ö`{ëÂpÓrÎÏoÅ‚úİì?g–|æ­"x°
îéhú]ÀV©½uueLÈˆ½w¿ş& W½Ú­F‚ø­xR0Á%ä7ìïúû}k®ƒíùOş±oLŞ1¬fò0nÄäA¤vHfK å"ïŞx–¡ÇëÓaGÛœ‡gêJ´UPƒ¢LDíŞ÷DŸôÓe°1¢ãï¸üÃ£ ğÅBˆ£”ÅPcTËpqœ³¤!ã«6]—	!‡o+ã-˜Á3+A× Æq‘ÏÔ	&ñåAö™jæ,æ‰Ÿÿš9î2v‰åŠŸıÅÃÌÚû‘§Åû/šUDWœéà]>Y‘`0î}˜Ä·&—{^¨v)o¤øãĞjØÈ²àÀGRĞlQÚ^ø
ÂïLğÛY¬ÕC£F5ş²ÓÃÛR1õ—g
iãå
‘
jaUrY~KhÇÚ”²	|(ñ-¹†ˆtó]$ÖÌŠ±\Ë÷ú_ãÀ T1o-w˜fÌ®¬Ó’ÏÈ’öªè0í"ÛÖÛµ_é¬éèrwMEÂı/ûY€]¾ø;MÑÌ´påM‘ŞA`¿Ç“Tfôğ¶+@Ïh ²=ySö=Ô ôµ€ğÛ0'1±Ägû    YZ