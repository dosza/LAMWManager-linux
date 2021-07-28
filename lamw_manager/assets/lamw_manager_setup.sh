#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1215046420"
MD5="d38831e253be4aee5b80a0f9c7bc9e7a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23332"
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
	echo Date of packaging: Wed Jul 28 14:04:55 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZâ] ¼}•À1Dd]‡Á›PætİD÷¹ûú¦R9¡ıÛ6bq¦Ù	kè¾‰Îs%bdA³$6ñ‰Y[İ—ÆY?Şš¶Ô["¢{¡Aî# V§ÈQ„9Ï4¶d²p£«ú]]aĞ£äµåŒÊ±‰AèûÂ—_i„•}ßµ•²T)ŠŠ€¤CÈ#2ÍÎDÙôm	4/uòŸÖÂ×`H/–šõ`¼ÎŞ¢]èïx¡®\ !Ú;®|ı *ÖfŸîšçè±ÄÒ½MYì`)ÇÃ5sR8UiÇ@„B+bišËXo‘*&÷fØÊÛWm#{·(~ŒÎı|Y§…4€–ûª¢Eâuu—MÊvş{©F…Â%¶VŸ7ßbQbd‹gM°wZ¼ósXÃyÀ¹wÊ}8Ik<…ÙQkeSWÕ–/«3¨ñÛ':Ö”paˆ«ğê¾Ñeˆ*î¢ 0Ú³œÃ–ª%Ñ^Pœê¡~ÂZ®Î0ĞCş!ÂUb0„ÊµGiO:¤´­¸Aùª ¼‰gœXt½›¬Ešæ„x'¢áÜ6c@À©á(
Îá£·LMçÍMùŠåè˜Tè£Âìmğ&&ä\åôñch‰-y?â2lææØõ½3 Rv+¸4«šİ|FÈsèØñ¸¿hz$[œlä_EâûTH£%Ø]fZ%¤ßÙé„ì¹é¯ÌS»Fhnc°v©Šõ“ˆYÈ¾kó)ÏÏß•@ãj!†SeVD¨¡h¤®Ñß"Ï+ØwKå½—1Zó	_öÚÚUÉ>½
İÛDL¯„´˜‡3Y”şHÉigæoæ7éœ’èÙ~}/Úr™£h!%wp’ö”Ãû8›ˆd%O×ôts•Ãá[Xp¿*1|"¡ÆjX}é_nè5HB¤åè@+È|v4ÆA6 ÿâúÒûôï'™W‚È%#åäQ‚É‹'Ì´BÈÂ€H=´‡¶'÷A&^`Va›ÓĞâµ`b¹¯ÖT ı^cáÚëÁZÆF9p.Xğõç²®JÛµ–ñø¬ÙïŠ´³Pesoc¹LŸÄxüF¢¤NÏÆpwl|˜b®î%£á¹› M­Ğ¶è¢²ÄÕ|lÓç¸ÿ’`w~@Æ\pLÆAd Kç»z¯¨ÔÁÃ1tø<’fn}_Ö ¶~Ó¤¥d¥<«²Ä>wkØ~t”<Ğ¼ùºğŒÅU©œM;ùNët¾k}Bğø¢7#³†+‰”GÜgè[Ü¾QH<R5%º ¹·¨±î2Oìˆ:•İËÄ]àEhê@ao€³+¯ÒI2úì5QkN{­©í¦<òG2’»™Iæ™½yÄ'ÊƒV›‡® òp˜µœšk”¨Ÿ&äßë°¸à©Á£r¼­ª>a·¶Ò8\šêœìõQÚcÌ™äÑvQÔ5ì7Ü®Z"Ä?†=†YÏdb{%@²Öö
Ò5ˆÕ™¤Û´gŠÅ6‡¯qË3"ñ?\HX#7ò1j“üØ…øl$Şb*dÖÌË±¤©GÜ uN[µ²|Cw§¡Š?ó‰ñô p³A^Us6Æ¤XÍ“s|âî%%A×TøŠİÒ7I0ôá!V%Ÿ¹t“kHUŒ>FÑ×Ğß ';ü¨%SDEì‹4ÉäUvìöü¶ŒsfÄJ h8÷ÌÇd²º;T©”ñL†Ã¥ô	ğ‚mñ”nKş&#îo“Š6éyG‡bı&‘š†*ƒgØO@zl2’Pv6kÎ‚Ä~Üskósh9iùx^Ci8”èQéP~×Èš9‡!?¨o·	sTèT|ÉtÎ„İ¶/P¥ø$SÇğ“®æò8©É!»aøâ¿Ø‚.KËò£jñóø¨È@’ÃË—‡Pxx¥–ìÅø¥º@º–ß#Ê†Dæzo7|a
’¯‚h.BRÙTg×±V‰ô¦±[Á¥«a_b¨>õ!›.„Cˆ.óƒé¬rœ\×ËQøçèaj“:;.nÀÆÄF@Å,ø¡¼ïÀ‹ßu¿VGÅ·Å64=‹Í$ZÜà×…mBÄíÏ0ÚSÎx}V9fÿ¤3/})pdÊb'ºjGĞïCÅKhsĞ¤Âé6q•XU:@.]ekâˆÎ„´a3®Ë‚# Zº¼U×úÀ’sK‚J‚¤ùŠ3‡­ä^’ã¶ã© B¦òmó2?)#Ş°¡±4!uÃ¾T~}_…á@S¡GÊ
®#v~£^}ÔÏ[+ºaîfó>+5[t«Äe5ÅŞ&µø=•_§aã‘tz†cE¡päC^}t„/h­'ÎÿFğ#kb#<-áuqºVSIv¦ßF`Û§{ÔªÉFWV`’øØ?w†rŠQ	0u¿Ùp\]zÄ&’ísŸ)·fÎGyÎKG]¦ñÜÖÙIxñí…Kä><Cî¹ \sÆµuMƒ0cª¯yd8€:jz @>ä²óíºÿÄ¶‚lÕÏbQm¾Ä
Òò­Ía‡PiášhÌTìAô§uÚ†C.<ŒûF‘˜‹ïâ"Á·D³¯YÑÛ1ô<³]ìy`»W1b*Œ´uNzA®ôjXªEÔÖh¤×[ı
¿ÚOHˆ.öîay+[KY€JY]D.P(d‚QñRúŒ¥.qò7“6‘äâÒgH×Ú§a˜ÉlÄ_´¬îë{™ÚÙ4$[_Ó¤»¼Ÿñr9ŞSĞ9ºt.Ï9<F”VÁpí&¶ÄìÃƒŒCÄi´ôıRÑÔ‚Ê;¹ÖD‘Òˆªì=£ê_nz‰8'YÕYÖ4Ã\íìcr‘,õ²>kóÅÃd|Å]¹Êú·ÉÌÉ+¥%&¡P¯ªm!2M!Ùd_Å±pq"¼Ş#«–²ƒayºöça‡b‹ŠÂX}_Š/ãı§ƒı)~ø†„Bm$ ıµˆDC­l!Ô3£X Ñó;v]G`f §’Û–9¬‚²«Z
È$KË¼gò'?ßÒa€¥\q‰©õ¶¦ïƒzÁÃ¾ß` Úö7ğ!­íK4tÚÅé¨›~¿eq6¬å0¯$%vRFP
2Ñ-¾¾¤N¦¹zÇ|20¾]˜õ¸"„kpVšéd[æHÃ~½\ZÍ½"së³B‘!K¹BuÈ ¥®×ÒµT€U2ÕÂ:)c;F]üVÉPû‚…
Í}wDYYïm
*³1¼|`´®ïÊC5WfÄò¥³ÑÄR'g‡•4Úlúëâ†;ŒGHÍÎRØŠ_àï‰ø›#Ö]E"ú_ı|O5Ş6‰„HÁ#CÑ˜²÷·,…ÚQûoÃŠ²:¥ÿO;Œ®ñ‡Uã€ç5H/ei°ãRjÉ¾¤¾fnô]lĞ—ô¯¯*I+ı'Æ0Õ’¯	ñSÑ˜Aº}‰/§³ìÅÏg¸—#•áÓ}ğ÷WekÓT¿“¦r&<DiÎòˆ_GÃùî`öìG,eqãÔàó—ƒ¿áV&‡~¦‰…‚°{º¢ƒ;g#r·şÚ-úf²Yˆµµñg×±Yi¬ßk­ùÁûIVñmiC6ÒˆÒì‰‰¢›g<:€^(Í»º|ïÛ¾€ÕÓìV3"Èiv:Ò}€÷bìÚ8¶o¼;¦Õ²ò´ÿƒŸxÍãŒkŸ›œ'ğ8å½E’©([Ş#£ìr#¯(ŞñÓ	Z©WµÏ	'j½ò“)ç<­zÈ÷ï|t›€ZO‡ˆ«›£7”Sü4ıYû¨A*#ì×
ŸÁh‚Ì:n•Nc*“s†Ä¼yöÀglÊp¹Õ¨-¬Æş`œ^TÚ‚À^ÌC l¸.…"w@uà¤*°5Ä*d4OÔîaP…LàµÓ£}üœGN°¦ï”sMØl Ğ³ „o	â´Š<’ÆÌ«”Z”
.r³rrÁC1ÕÑàëz¾[ta èòÕ%æ¤ŞÓ‚-a}Ux\å..ØØÈ™ºÃDm³ítTNÛKöK´0)³]oGIÜ)ö¥+¯Õ)ZW†Ëõ&šŒkğİ\ä¥6¼óô…úNö9dˆ’¨RÀoñÂ©ÁÄ'cÚ%ò)ábÃÛ*6$µkg(ä$ùfßÎ¼Ñ*5,’&
QÊÏHaİ¿„ùÅm„ÓşCpéËVã†`cn¨¹P”ÍûŞÇ5æE\y+şù~?Ê‰·Y½nz–ùiŞ¯Èê0“Pp9€'„åƒ¾›OVÇcê¹á]âçVHKÕ¼jŒ‚éBuM¿ÛÌbÊ…›[" ÉJ"\ÀB.`
¶rAZö'eMëTÙ ›>uH`´è›˜;‘¨{}†Õ­¬ÖÕ’Ùº¥ñ=©uV0™0½Òëc¦±¦àÏbJ8ûF|o”@-â|ûÏ‹°èµ0Ìïá’Ëò…µ·¤¬ÛÁ(ğ‚yÔç¾ÉÉ²tÀ `¼ÍÈ97hùa™pä['â•Ä®JÏ”Ã„õCši C^;àéº§!öT“-Ã8r(ñ=ôt4K[6YánöØeŠ>ŠTÂÿ}`G/Òe–”R‰p´ï&{CÅ¾\“QOmã©blñŒBş4ÕmµÌ©z0?øTsOÎÛÅõ´I<º%´m£.X*V‡Ã±Ğös§¼€5D&òuX,”éÕ›%UQÈ]¯ªm^¥ùêÄ¤ìÅß—@ù>[.öé8×ªˆØŸÎš­Ñ¾KÄbT›D×ãì’œê’­OÑÑà¶[ÛÍÚ‹Æ\&¿¹©ú‰Š#ü2i²"yp\®B™W<Ú?„3º åiÍä–¼™ÅfÀ´Ñ]BğÛšÿOL#cèl?ë»¦ÑÄ=’¹}Tÿx¯½!„>##¥¨¯9´$ªœğ¡œ›ŸéÒ@!¨Â°DØÀ.¯‘2
d?S‰^nüí
Ñs±'C!¯Û–Ï¢¦usçT ÷XŒ¤Ê|Æ“›‰
íã—ÁBÅ|«²y3;&ÙËEmñøcÜn'‰Ø2}†êÕ(Ò$'‹jdxÆNé® HÛR›ÙMË/ç™ÊşIû¼½OWi¥g&ëf5ĞKˆº±óéRKçï—cš—É>+kRÒ„SÙL1ªË©cCâ5ÏÇ.»P·v9²§ş&ÎçiKh8Œ›fé›©N°¬¹"ğD†z¸*WÀ¦‰óYº¾¤üæ‘ˆBƒ;»D!vèè%~ZñRà¯]Ê?4[ÀÔà„.ó¯ÆéÓÅÑ°ÿ†'×7Fü ÉÀ 8áå»£~òã»½Q7'ûÓi,ó%G“sÍ¾ëÓÂ*hÅóÊ¬mÄÁH	“šh¥ÿ–¿çyD[ßc4I±h¾®öˆx%g^)2©ò
w!£<‚MXªSörİÆB­P´t^4•ë¹|â˜vbº3¿‰×ªÜX»p´íÃŠÍï…õÜ’{:RA÷T®Ş¿1-ôQ~>Û”0b-N^ÖÉ0Ö:D´Ş£)èPË«™íe‚Z%ÈUÅÕ±:ôÑ°¨íÏ˜÷ºÉf'N0ÿwqjş;TBtñ¶wÏôBpgşÖU“Æ¡•ùõFÔ%¤ñ­„X¤âN#Ú‡ïŒÈH¦ÇYÂtä$ù€ÚôÃÓ’•|Ïš®M¸a<šNiÂléœÈÔ¶Æ.j8^Åb\ã;~êfô)Sh"“•¥Î!küré[b‹HÆ¤¥OÄ{ó5sŞ¤-©>Eo‡A†ÕµW53°Ã)—ô&€c‚‡h-A©.ÙòaúK	bÜƒÔï=ñ¡XTş€Gòa„ˆ„ÇäĞßgK¶òé‡êó	Í¥±%š>HÑ* „œ¾^ı0o¿&îJJ
9pİˆ°µ{í²Ş Ô¢ÀÄ#Élä+^ğo}ûûÉk„”ÎaĞ>âTz]qn|¨L007<ì2m'[Ÿ$QnÄIYg,­Šs‡yÊ#¾Û&ÚºœqÑ|Ô{ïh¿ßlzÁ 2ë±ôm÷’•×0—Ò;1Ãq7`b¬LYlÖ³¼ ¢~_‡Ş[†½½Ù¶bq8>í’‚˜«ìÑit˜qú®ÄEiÉ¯ı^$¨,gG«Ñ­%`Õƒ!ÀÒªv|­@Åaµd~qKîHdSWÕR¢G‘gCÈõe¯^Ğ_õ;îŒÂgXˆèß™ğfh¼ğÛ.ë0×G»èh¼EF±a¢Â¯½ç½¬²ó_B`¡PwíÁG˜¡ÖB&¾İÜ>;°µu­È»~1ªŸµƒ•ïÌË0İT	)åş:Úä -)„ÃòGÌ÷&öñ)¬ÄÅ·“óGá©áÛpDmÚ¬÷•I›‡$|ığÂ%$ $şˆ„}DŒ€1`Èã,R¢«µ4ü¹§‚ÎWÇÈ"<@6c9øfè¹W£#eüÁLØµÈ¶}¹qfíŞÃ¾55÷å´èÆÇ¯£3pt¶%ºmO¶—™ı%¼0
ñ¹ˆãÉåíŠx`«L ¾2~ÄçÿÃ%ì
Ç«•‰Ï£OdÚ˜Á¢LÌ?²qµÚË4AÏ°¶?‡»c’÷ıˆ³ "¨W°/O{çö`¶ô‚ Ç*<Æ³RÓÚ?®”?~	»nûù³”*s%­€z¾«™<q´YPÚ&¼œ¤uÁ0*c½ÃN9²Í]Í™~\ˆç×¯Ùùæ,”ÿà´¶R;Ô(—oÀ}QdqT‰ÛÏc×ı7¾¨ï¤^F£ú‚Ãõ‹nÕ‰˜Ê4nÿú±]¢Ù>úßGAbüP”ÄÎ‚İ(ù_rwDLl6	îeĞÁŠÂ©“éàAidİ¨>²ƒ¦½á…ıúÍ”KiÑ`{˜Î	jä¦eDíaXØ±e¸R·#:P
›ë€ìNZr _\Cl¬¿e2sÁf²LqÑl	/ä=ˆMC¦|¨‘ø õ74%Ÿ–Gš&Ñ!€Kî/>¬YE\T¸{v$ŠRE™Rß¯èrâc0ßûú‡êÇ@c§
:¥Õ9wÏ¢B|Ô™9÷pLèT0»óJ²l&„¾Ä@ßØXÌ€î{ê—-ÅşÉêó;S6F…ysx^‡8±˜
:…æ×ÖòÑ?RÉDÅ•åæoĞb±+d=í•0(´-`OÅ	yà¶uÍ©Ã™)(Œ”‚üCd±“ÿÎš¬•ÈmH‡¯Vã`püP«zzh5Cô\í²Ì÷Ô-3YŞìQ„Š7( ˆºSÀüÁÍ&.]vAÏ²µ{ô}J<­2¼ l¨\è§ñr)N…¦%âH¼m‘ü4’î?r Ä•Ÿë+5E=UJoR©çŠÌÏ[f‡2˜á@©ö!œŒ)#ˆºi‘(9Ö–ñ'ºö¾B Âƒsšu¼LŒ[4\ıR=Écñ¿2ÃĞœ «ØMö$R±4£9ÿ¢mğ¾b´ÆéĞF’™è,ÖxlèiJµZÊ*J—pÕqë‡x¨]à(ğ¯+0 7ç3kJ“ä0Œ›ˆ
Zwü­¨ÂÓÃ_ ±	§°H
ùËà±r»Íäæğ•Âñ§>Î¥1óHD évdò½u›’éiõ¢®?á¾¾•LG-nx]—7Î§T©)^¯ëd€4üi=x7›‹¸N{eÅH×¶µ©nô“ùjĞ'º¯û‚“Ğÿ5~®5qşşß‰Ó^ Í(Ÿï(cË‡ùaÇEmkõØ€xµ,HD‡:Å)y´ƒw=‹Š7ŒMÅÇE?œí—º­W82†˜n¢¥y—óÚfB¯J×‚TÃÿ	‡m+³…¼2ÚğUWËŸ¹.‰,g!V9>*v¿Å¢ `§ş÷Kèì¦›H&Š:PÃ]"@ÚASÕ°=(´>š­T	…™oIÇÀDö¦´y¯Ÿˆ{ Q+ò~ÎG¬x| èUÄûÓ‡a”h	Ûwƒ€·Éşèñuğœ»ÇSzôäì\ûÇ^õI8R¾2#v@ÎB†4)Ù8 @,ãxoyS-2ÚF˜1¬vèı“;]]øŞnÉl{cÒíiY²€ÿÂ… Ì±{2“ÖŸ-AèÙOê¨­ùÕY3âer”ñ}É/nè{ı¤Q&uÎÔÉ,K·$˜5- T:s$¿©:Ÿºó}	é^ñ œƒ9ïIwsØÂôİ÷<ø€ùıÖK‘ú;›óÒŞ^ûÈ
ÎíÏ‡òç~Úå³¸©ÕLx¦±·<5Ô
9ç_f˜j†¹~œÀ*cş@²n;?cˆÒ9ï¬>ú7ÓÖ>Ek}ƒî‡“X\–ÕZ°Ë’ú{gF’‘P:¦XS¯„ë½°8Ã›«Ë<ü{\ò¼ÀrÃ95ˆÔÁõWn³À9›7Oy9åİ¢• 6‚kÓF CÆŸ3ïHİ`Üÿ{nq(yoG­Ÿn›}Ñ¾íPwšùÄK>ƒLÄñ(Ëø‘C‚í Ÿ¦}zß¡ÕVi¿UM,Ps%@ñg˜±Ôì:æD¯$ÑhD7+0Yä‘}ÁÂ¨©šî2+¿WóÜU{¶¨½«¿àFœšìèC8É®ø\“<Ü9¨:¹ç}}ç.Ö÷–^ílë˜nF«“d;´48[§ƒ;1ûpJªêD}†µú*àH,¹ó˜”A­Á"Õ˜¢Söğ»3áñ˜yN®ğƒ­kgì2ÔETğ*¤Äºˆ!}H;ÌqóÇeæ‚Ğ×Ä½İÔ£ŠÙliÿz´Æ}¶2WÎ;œ8üFşgÈ@|tmĞü†¬ICÆÀ…¶òRû•Ø	È›•°¼Üî¶šC½úbºËÈˆ<WJ­dÅ›©Å"¸Ï-›ÂLØ0»…?¼6ÿ:4è+Òç÷‡È˜¼»ñ‘üÉ'Ú€FûuÉ€<²É
oÉ0î?pv§³Uø0ÂQˆÇH¥³¬ªâw^0ÿ-nOícÈ’ùh9¹˜~Iùá(è-“)Ğ¿+Z.f®.o¹;äÍ[•ïÂÂÓCkˆL”ˆ]•EşÈ(uY…©‡‹F˜‡¶Ø=(‡Ò‹Òğ­YË—Œk™-E¬²I˜	ï9Ü8şÒDKOñ(D½ÃŸäËîß<j<?—W±W%¢\MhŒ‹Yšı~M±4«<¬õ£,ù>İî™wµN,†‘óA÷÷„iâÌr$“w;UÇ@¹\vÁ6CFp‹Y9vÆJE#­ræ9Q69ãô(Çur%lÕ
hşÆö2ôÆÏ|µæ®­z}âê“×›"ö“j[î?Ö›°Mñ?òı6÷ärê™Ô„Ò2Ñ.óC§]=/]ÆO¦ÔÁãÑh÷k@ûy5Âµ/£$ÏCÌ‡_™û-B‹V‹Ó¨óë½Â,0Ğı¹pjs‰Ù6êÙKcC®HU!8È%¡¶Ûg¢¾íEk["Q.™ÑWÎŠ’iú¶#[Ã|sùôí8%ƒ/
zá*u£í:ôù8“º¸åĞ@{·,}­U*‹'÷èV—quRàèúö´u¢Š§Ïğe€¢yáXå¼t|$ÄtXëÄx ÙDÍ2œÅˆ&IZ”RŒKu›ƒ\Öo<;Ór+Ü¸\n”ƒÎ7Â°H¸Îüh$ÅÄ°\V÷‹.8m§q½#VŞû²HÆpL$„“˜»¼3PBŠş´æ¤äc]jÜÃ­iûÏEF,€
AH/NÌ&Jbb“7Ÿª¯µY›áÕ« ³ğ1å¥ü<¾‚¸ÌªXí‰Z&ÔõlzSF÷ïTBÂ!ÖbSFüĞ‹Eò¨‚OËƒ÷ÍFËñ‰ºóRÕn‰Én®Á÷~õ­Z H:ÎÑ€f­Ñµ…ö\Ò°l·0³`İv’¿_ß~¶0›hÚámĞ6*‚ı”wáÎı+è(„šÍÅ^¤^!-ôœEMO¥Æör,}]ø¨UzÑµ4hU|ÙÚ‚ĞÛÂµé G¸ı'ÏŠ}Å"2×‚ç
Æğw¯ÇFIä®×ıá>ùñŸÔô*8OÏ.ŒÚêZ|Î˜"3g-çsd›…L‘`yÇ Ë§˜W7iË0 .‘¸Áà H…cHå¡‡$Ákğàòò[¯ggK…?DÄyoD1º'”ø1?^_QM‰AˆIU~+›hVL:’rÍÒËìX…Ã“ä”¤¾‡İšò¨ ÁØU"æi"ñgâøğDtô…0ºé	¾™¶DğU»Ñ=p§Ì5€q•“­%NûC_õv
×ä:äf¥¨Â)L?Ó†ÊØTÍAÚ_©ztÕÀ¢ág2ûáœé Ÿ”®g`’6\ÉW]ƒZ Bú?+t¢ê?O}ôÂö2ÒÅÄ„á¹ØüFÅ–AtQÍÉÛ“àŠ†'æ<5v‚2SŠ­Ö€¬‰ Ì{†®ü­c…²™Ş÷üHóäi»ñáÁıäÊÓú¡32i¿…šó ªüÖ“½İ-~
µ÷˜1n¤'"±5Øyêmª-§A[â3 pËc²ãœ„ßF|Ğ¨[x@¡aZş>GŸpˆPÙĞòÜİß!LÃÈß¬X’O“Y,U}@8ê4[V¯Ã
™ApÂeÔfB CÓ!wQá,tQ›ı€!7
vÙ2&Ìr–h{”»4á¶±0Ñ’î:½n-ã1G`›ôëyß<½P–Š>è»]€íÂ‰	ÆCeCÍËYrÂ£Î[yok—}NÍÄğõuÀpt€«¥DîAßg  %ôqÎĞ«N]ç`šÈñ„1~î…;O^†JŠo¦«¾ëå“ú¥£nèƒBO@pÕÛ;Nz‘lèxlYåİãaã¯û:ÕãÜ¥QB)?é¢³áZJŠ¬ Úõ\ú~Ï ]²Œû€ø ÊhE9Šµ€ánRáÏ¨
ß·œÆz¯"=Òo¦á³‚[­u…$p½‰t¾ÁË[Oë±6 +[œ@ıæåœïJzO‰Ô¼4îi²8_“¤´‡y×Æ‘ŠmóÙ§GÜ‡ÂmK5Û>DšÂ‚|ÿ#å °¨éÁ‚¼}­iç¡eÇüt¯0ÖÍ5tNG´Î1†Í¼{êıÂ|Êm€~"9Ø‹R3Vr„äÈPÑ†âÔ›0D$’³¨S:LßÉ³tİ¬ÉzQb0ÅCÛ¹]Wği)®*\ëÖÖâ‰'2£0 ¾ íî‡·Ğ×ÓìËŸÆÇiZn"Øş~3P«·°h²Ò;"0—AöÊĞ„ŠÙ¸wØ¯kBQ¾¼g61ª±áÕ•(y7¾áˆİ+KºFf36Â¬¥îuĞÇ¯”Š}«CARãEÇQl$U-¸±dãğ%Ä|¡V-Ş‰[£5'(àGíkÄ&m[_Ê/<mÆÔIğå¸QíR½Mi8“¯(Jš à¢2…Şè‘œUl–j	Éç
	5®äZë²Bú‚	Diošª=ÅBPv$†	“àÊ€['÷'˜Ü6µçé¢º%¸GTúî¶7[e·QÚ˜ñÙ ”Éïj~ãláÄ™z –íIj;Š…i¾¬gÄc#D€+uÍYìKÁ'O0P2ëÓ‘Æjs"ŠœÃ…¸Â_GÅm#wû%¦>ëmÊ1ó³ê‘%GÁ‡ÑMu4x`ÄèˆP¦cš´'AÎd"X´îr”¤´{*¯kDÜO|µ•À¸áP6v¹¢İ°-ÉÖ$­‚âè†dúñ’: —£®ÏÇğaşo”>ˆnÆ±[ ²QŠÀªÓH}PÖ1W¨\/ƒ.W›Í8¾jŒês%Ñv
ÜuÃÆğßEè;²õÇ]û[¸¼8è‡RJb½l1üƒŸºàpÂŒ¯½ú·¦$cP·]íº–ª4f=‡ì|)O¯¨	]Jù€º”QáÄÓ]ëÓN¥ k÷97°ÅZJ¨:–^ìR_Ã>ŸEc 1/!àWg@'¿î›€jğ¦Nü ‡5®ÀÄ9›]·²ä6Qö–kïdU£ÇDêU¥ÿÜW©˜°R8ÍÍ ™ÕT2Şª•€Â;éÄ+5ç:t	·“DÙçâó*ÃˆDyÀ“ğÃĞÃùŸFr±ÍÆó1¥­´ë>­š~}-NöPÅA/„Åïé·ÄC½÷êŒs9l…½ÍêsÇ ³‹FM»ğuÏwÎïnÎ½ğù)-°v:`E¹ZË$!Ó'³Š«c’Y“N`‰&˜|Cë\GG?Ğh†Ë4içi ÑG·ytT’„^j‚‰¬LÔ¿ÂôEÌµ°*<NÇº	ëXš+ëDÓ-Y2DgŸôî+¨¾P8ûòC¯ãŞô(‘R?[¿\£æ(œ±ñ´[yÎ†V‚í¹«^óo77Ê#Ší{¢è$55ÂÒôlºépËŠ¤=ôOuÒ4"ªRf€¼R4Ëh×¯î v±ZêÚø–DjA»—º
!l4nğ¢9ßÛ\cş"&BàPÅøø2·¯Ã›&ıvN¤¯ â^ñßläE+CÒï¹»>V±ìlf»	&dÏ9TøôH`^ÿÁÅ2WJ]Ó®.ìõÚñÎÅ»~[G|“ay7¥€³dÌo~yÂS?ÛHL{ë,ÿ6î4x‘Or°EG<ÿLÌ8RVrá†:¬‹½ÆVØØûï<ù<wÑsMIÒKÒ$AŞ7z‹Hq.ÅàÔ$
Uo’y•NguI·²Ó»«{Á¹¤¼8›^4SÈŠ D4¡J7odC7#0»·jÇVş6ïXÙ@ÿf±ıåÚ^‘ëH4vå{™ş³Â@4v…f«†N.¶áŠ¦wıoÛDn”H`†şº&gŒ1ù˜’)”}—ó
to5ÆšOº„ß5ycCeµjI¥› NÉæN:š†ÁÔ€gt”Zôc¹HWq@–‘!/¤‘>Š“q}v1vÃo«;¹¢Ëcä;	è3;;‚*DKÖûÓv‘éÑ"ÎéB´GÓLl^ ˜.«wúI‘ÊQ¶ğJ<Ôi:»7şá¼tC$q!î ³õÔê ;îTDµÜñË³ï…¯9¿¨ı¶bH~:p
œƒÌ
iS(~0 É§¾ÔÑÍç»Ù­ÂsÇ­¾–ü†(õÇsƒ4!Ó8Î­$ãYĞÑ™™ÆkÁ±$,­™¬‡8óÂÙÜêùÆö^Ì¨µ
y¶..•È®ñZ:¥>QßI£6^C¸wàˆÈë×tyÖ<õ”èĞø·¸:Ë¹×@ìX›ˆ¼ÍªÂ°~?<ŸÄ½0~D<­8&ÜÌ­.Ó¥CJ!¿7 şc\EqQ'şó¯=ù°Rï+]¸ŸI=ìèı$}T(šÂàYË’f,fCªÏ‘–ë–ì[ªçƒÈe«ù	äº…-İ‹²ÄwdO=9¦¯	<§:´XD±}Ô§^veıÆ ]Ñá+}BcN”K•€¨Š’ê¬jÅ}”:b'´¥{x·_î1óº1ÅI]Íd®ùN}!êã/HÛŒæÃQÈÎ±ò)aDèú-·Û)¸‰Rz”<HÃ3^Ù!4 Õñç;’0ÁBŞ©ÑhÚó¿37Áà@«<*<½Âf£<•õá¨+@.DÂ­¼<t¢g
eœI2wğ²<l]¢ù+äÀV’RLIUó"šîKò!G>Ö€"¯º¹¥¢NÄÖ‚[x®túÇ	şÇãSsäÑ¸+]â	
O'-·7Ø	®z‘üŒS…RjÌîÊA`ÒÎE¢ ŞYØ—¯»dç€(¦KzgÛ<5$ç/şñ‡a#[úÓ€mÿy'QZ"av<ğ‹]®/†Ïyï	–u>iC“‡c¾%Â‚Îç¸.õÔæz>¾Ã/»‰:°]›A]FEù0p©`!B~ä}ÊÄşXï5i7`ı[±ä}Xbª­·å­‘±•óFFÀÏ}‰@‹!œÊİQ§¹­¬o~ƒöûŞX*±SÎßeÔ¥Ç¶Ú	6•æôeöTHËE‹5ÈÇ¶î%ò‡X,‚P‘.Bº7‡<Ì@Ö×5­øNûÄmáêÕ@kä€Šäİ¼ÕC",Oàe¸]"PxñúHsÊGÿPğ4YŠœ@ [OXYUÉgŠ‰Ş#<>ªtŸúçcèeş@kÓdU½e¥­üÆÉ; ƒÓ7P† Æœ€‚LèÎ ¶=eP«ŸÈM>G7ºdïÊ’ZcP²º‡™bPãd,LH¨ÃÖU¦X©İ£4sÉÇùğ3
SıŠBgÇi‚™ÂtÏkûù[‹LêŒoåx¹zÿ?oZ²0?¯“/¾T&ÚO€Ô&ØÍd´À8qFo»9øö¨†ù3@:=eàM9Söh/–ÆŸ¢µ$1Ï®"z,)©2ÄÀ{nüXTg@˜¾Ãn°uÊ¾a–¿~Ş I§TÏ"Ù	“œAù½æ÷Ë® òømKŞg‘İ¹Ÿ”h Ûbme’®hO×¤ug™’N­z:}ƒ$;¯l¸†´=ƒ„X¦šçSZ Â"XËÂatø™ª%FÊ±ao%Ã¢dfrİÁôÑ÷‘†Ø¢Êå •DAÕÊ²Êú,~„Ï§óRZ9ò†îî8ƒ±Í–DÃï©4
FW9Ê@&||0ÅsrÙJşlËÃ‰—ÃN5ˆw©Üáa{%òÒõïºbû²ZÍ:~Ô‘Ó7zMÜéGfÀZ¶Y¬tŞàÅM´dÏô°e\ö&ÁiÀ‰=å·˜º3‹Z‹ÏhˆºãŠ'§ÛMùnõÃÛ–=/ÉÇä»ô­Ps§³ÇT,8’ô±H>hL†4ˆ½r"›0®ß3:WİY€IUXÆÂŒ%ô@I®g`ÈÜ½N$xáĞƒc". ïğş=ŠSG¬U€Xå ÕLì8»'G ZÈ&EQ­}‘	ÊVëÜ°m"l‹ıî§Á´hÙs-« $:U/üûô>:nÃBÿ0Ã@ÙÁÈ«æX<İk[æ|H‹­Ğ×ä"àõ‰½XÊdMcŠ;¯h+×/dÍ¡‰ ÛêQH]&ğ|^¬O#¤p"YJ²ÙÄ“«çäs§zÑ×E:¥tV·‹ŸaP–m4Ê®ê’·VÓ—H†<räù›²âÕî™Næ3ÆÌ{³µõyËî6vöeæ‹ÒKwøÈp1•EûïØ¢¼ƒÉB‹î(ˆ~ÃON‰ ’í(y¾´õùQkêÒõ	ÔšzòÕıF¨Á¬qİsíÒ³À­æ˜œÚ"+…†í!¹ óèïoH‡\s8ÍÅJcé¬*,†jœàÊÿ?‚¾mgÉ$ø
¨=ÓFk]¤'³w.¯DkqÚlíPPãÕf–äÇFLéÁ4ƒ~%íŞ*[¨z\“?4¯#S6*rğ{RS±Vw€$¦×%—ºÛ1œ§0aòrØ>bÏ4{—Õê¶âª¼3Mk°d‘²ú!^²?DÔìøå.Ä÷æ ÂgF¬|• £E%‘2r31òNŠFƒ^JØ†ñ?f 0v¯ ƒÊ#ë(uƒQıóçCß³v6LúF6M¦××ÜÜí2z	ì^«f5şT$¾¹ÕÏgşú±3´Ş+Œı]XPè*ø ¶µªÛ®u0İx)sºˆ¶
ûiR'ÁùíÍ­¸êÚº…ÈÉ÷C.mØÁf<`+<³}¢H×"ô—©±M¢“‡oXd…ºÏÛ¬ÎcŞœN°1 şÊ±Ë´]d^‚ë¼¶¦"Ç$TcÂ°­›‡ ÚFQ7­öf²éØƒ¯úiÿlD/Å)1h%¾¶¨ùÃ%µ;! ·ÂÕ·†›[äd¢gv‘r‡ Ì¶X`M©+Ü¶‚P!Ô•ã:ğ
ªí…X% ³/CB8®šäÀdÑå]¿íøÚ¥Í äÅ¶]ïÎ²ğÒ•ÇÕ»*äş/îñ~fü£n®%kÚ4‡ÎÔ Qw?lAÖ
‡â¤µ¾Ëº]K?˜›ÿ£×êLÅYüÅ¥:±¹béñ©úŞXšë¾beïíÔíÛ3n½2L®öYMVÔèİ|óKÃK‰mµÁaedVf<¸ÂJª,Ãµ;Wo¬`şVQß€;ÄŸ‹æT
(HN§úğ[ì˜)¯r£Va@V@Óõ§LFw’m	ëgG==,dål²4RÉO±µj\Ú‘¨»/ŞYÿ2½ë”@æ@”«}Û. ‘x6Á(j¥MrúìÅ{ÑìEQx`ü¨‡¼Û1b>/À.áÂ®)Kğö†g·§+ı÷êˆ¾Ÿóúƒ“	µ%Ú¥í½~À‘‚oßQÂæä­ÿ	PMÔ™¤İš¿ùCúº½Áƒ›
p72;3L°Ò‹š²ã¡ÆåT¢¶s4ëÈ&ø²;ÿbN»¿&yŸ²èèXºIPiŒ²xµÕH[Ç¤¸±ÂKrğÛ.DHİµçe	éû¶[+d;ãgv&»sÍì‹©E¡·x©¤¦g\ú'«mÒ(i ²cáÒÄtšÆş®{4¹Zù¹ªòÖC?E²ÃBªZù±î„á‚×í¾éåù¦yüóç¶ÂHu‰ğmuÎ¤0O¼Ôg$ÀHÿ”†ñ<Ñì6K“SnÆJıvö=Ê´¯Ä×
Èr[EÌJVr=¥cßÚüTÉïCwK’,CêEÂÃj†t¶|{1!d£Õô‡rçrÀëKİ1ŞD‰Êë0Be¯1`é„Ñ¦ÁqJ1‚¥¹3šsè\kÂu€°ªCCØAÈƒ%(¿è¢÷Nzav§-36E{ä÷ßÒoÔÌº,Ïøğ·?!>€jä'\øã™Š0z<Ñ+Í{²îP¥
­.·
k²Í£è¬<ƒ]Ç(†RúÎÚ[•©7zA"6A;áõÍbè™f
t[&{™ÄX²[<†¢¿|ŒäTŒùL^A
©Æ^+ÄOå*µ¼b¡,=´Áw<v Œh‡ªÎAäÊO›qwW@ÂZ! í¾×¯EM –SÆUµkõğ•Pjó½'åÍs%Ó´ıEùó¤q)ÉC Æ¾[Šzp÷=àJ•lªÿşúÎ
™ƒıæùDŒİ¯ğ\Ëù(õR†ªã,ÁÂd;Ï¥¡H]jáÖéKŠÏ!s¡¿Ù\ît”å±è’Ä(“fn½ÄŸ'6~; ÖŠ0uã,[ZMÙNoú&ev“èMÒ”W$¨óµ:9B8Å @"7‘{e¡MaJÆOqÑ,â	G_W,ÚÂÃG\ÚØ|/ÆºDÀD¢¾&8ÈmMÓÿ0ÙsXf¬<ID¡ÿAã¤`€ÄgÒ2¥¢¾¡NsE‘«{`h „ÎèÜw}ƒnS;’ğE¶AÇò+åî½ßô÷‘Ÿ§a†%B—û
‚|èé'Å)aÓ„Ÿ8•—L4æ€İï0¶Çı×OåH¶}T‹Œ(™âaIA·ÆÆr†Z7[ìåzŸÆVk}&¢:R¦¡j±½ı¢ >˜„p¨yVZ‡ï…ÑM"‹¹. àåÃ¨ñãr =<ÓŠIB/.è£1‡,ÁëÀq¯
;AS`L…È½â•]8ºÏøyšñ-÷ˆİ³õå¨D£·Sxui™¹ß·×:gSáuğ‚_©¯ë—*&ƒ£Ş4]«ê{°VYö©4ÊäÉŞ!À>ŸßBä\%Ì¸jãÑfÅĞ&­L
M*1Ê¦“›/:®€óSKY±Ä¢n=U'îâ{aßÉ×¶/yNÃ:€Ì?”ª… hRòõ—¼Ø¼rjÁ¬’ÒV\»rñÙZ“Cm¿;v[JÅì>Tó™}È‚.‘27×yÔ ¥²¢Z(]ªZ¢?p±l%h g‰Ô>Ä*ˆy¶vs+ßUPÇ‹W8œàyŸXNÏ¯Y&ê^DêLókıÓ0ñi»ëCÄ¢bHÆŞ AÒ„¹]ıÿ*£ü[i®ğb–›¤b±
s¹fDtÔ†b÷1U?Q4;g%©àcßò…«zTw:;ÿeÚîşÜ®Ü:”qá‰6à+•™(‘®Äk,z8ßÌ1€T»‰€»ÔIòW³²Bò!ôu’BÏı¤S»Ëf÷>×<5ÅÈ1ùODš€­hÀuÊèùÅe¿·…pÌ8ÄöÃ~ı„]ü–ÆÒ»ØëyFCèozHœ@°b¹n,Ş»:óƒ*fèÿ›(6z²cç{‰ÓñÅ B¼“t$?A#.ùÁ¤YXjoÆ
E>ÁpÏ‚ÿÍy	ªùñˆXI}ÎÈ£+mõ¤ÖÔêÌùöñõGÔÚ‡á5t–$ï¯ >€M^â–/Fm‚“ö/ŸêĞG;Œ¬•¸RWÄy„nÀñÀŞ9áÇ…üÙSkB[n¦GÖäµP¨Ç:ßÕ¼	€=Õ“°û1¿ gªíc^Ò)Šâ•)ÃRÃöŞW»úB>A¾›Ô[ŸS+Ø«øÇ‘íy~‚<t/9€ÕãUûÊ”ÊÖ:wƒÏ÷pW2†FÒJÏÍ4×§¨©ÛOo¿õlÙ6™MGÚMÖ€ü£,.(æ3hØWàmÅ3X1f‘³éqßşÔ°}+“§ŞMwˆô„0,’ª›¨“ç‚úäï°Xî"ÊÑcm#´$FÆæûxÄ–<YÃÜµ¼rÆ3çHólBü¬’Uâş|‡h˜«+÷"
¢¯³ ˆÜMÉ|ŠnrLN|f©’6C3_Ep-ıÃ¥ÌfUØÔ+‡IÜšL”@·3zoc‹?š(—¸®y>WÍ‹ù,Ô½_8$9şŞ®g_©¹²=¯Ä¥®‰ 9Áï3|lÊÍh¡Ó˜ˆt¬u«îšr×‹Ê¨í
	k¡oNö ãÎûxŠ¦ø2ÊQa˜Ş[Õo7÷$­–P¢g'Å<$¿Ù:gÍšy<ñÉ\òßĞææ²çÚàG4İi%vçw[KšßX/‰ƒ,æ÷Q	ˆjÄ¸Ïİ3N,ÔiÅ<Ä6„ß¡1VÉ¨²¹òL{ó}¼açÍVĞD`?†“>‹,ˆÕÙE.s¥¢ºõU ëEYES`‡¾Â?Gü‰ '¨ÌY¥Ct< ¡òR•Õªª¶Ó‰l–JÅÿ&İ©–xH«Rbù]ï'$wøÖ{©Õ›ïÖsk‘^
ùá|×_¹á5†ß÷ùoø¡RÍÜüGâFOUK’¡NÁAwµ`,Ë¸HOiùï\ŞâÄ*Ò,>¼Ö<-ã°D/ É¦R,ÚÂÙâÆ¦·Áw½[š´ ÁšÀyãƒCè³ÿMbÂ“ƒ³9™‡›UşíÑeÔ±tÀğ>€Áìæc•%yŞ8½±1_Wì<
Ş×š¶B÷:¸;ŒVÓ»,¦Ûâfî×<šù0ätzl~\_r½ˆG3«‘I0k¿úğpï~”¥æ)Ş°?½ä¡ÿÔ‚eßí2<æ-©×È~ËÃê1K•¥·9·ÊPÁ¡]¨mÒ¿Çƒwo+å>;"ç£«$™Iİ©Œ–|]ı
&‚¯œşpîï{¿lÑXƒ Cÿ)$PÙaØ'÷®¨<%u—L!é“öÑP,®nî¤_‹/¦kHÖ#"â—ì/6ÈûW)ßš¬õ—÷é,T§:5ë´gş@»§¨ß#ıä]6A¨ºb"½ŸöŠ¾4ÜZÜ÷=F#“¥Òù‘¡¼õ»?»õuBB0øPuj·Œa›Æ›õ-°J”…I¬“qY¥'£›)H¦ƒÕòwâÆ`çD¼Je7Ó•¸¼²û7×‹†÷ŠPóA7Uún7õ,Íák#¸N_ñªfş€]ªæÃ‰XÍßîxfÛ\P_=İÛ¼§âkÀ‡5?£œ±‡ºy7ïğÍÀ½‰DÕØé-1J¾lØY/Œ,XjsÁÅ3	Nä8Û·eO4È˜ ôçŞD‰²®ÖÛ\	Ùh¼N—ıŞ?° µC‘üıä&y¨)I‘÷\”³ÚNã!¹ã9UÏƒ­pFjâèF»¥ŸEŒêÒÉ¶ê®´¸…´Â.á|LCtne©‘uŠ"¶¤{íó“n
Ç³œ¬y\×½«Núéhâ)öD¶OÎ„ƒ¿'d3ûe¦®Ÿ!ÓØNZÂñGn!î ß™…<,ÖçG^FIPÆà–í¸2ü¤ñÃôŒÌ»iİ8~ªğşt6VßIª İ¯ŠË“UZiO<”R“øû¦¹ûvZ+Í"À6ğà-
ã¾¦SùyZ'e¡ü ø²£¤”Añ'~ìµ—ü¤-‰îé„H(qR?®Ô76VŒ0y3Y{ Ògş&&ä˜V³ÄŒ˜/.4`pÜÑÚİÍ3†¤İ*–'ìhÁqÔÈ…YÆKÕ­š¨×Ç`«™° à1‚ÒU­#‚Z’qF©½Ä #±¤,VyhTàÆæïB$–œSĞ;Nš2†QY¼å~©
şcöFşOˆàÎÑ~F³Ş>¡Û¦Şÿ–*ş)ë^¯~êDïqp ïŒ°k£òÓøŞôVªFyâÒí	îu4ŸByñ‹Ûû»Âê7Ä!íNºÀÂİŠàM+G…[/­‰Ûsm«ó²³6ËèBşÓ¾‘0ªIö ¢Î&tÿ_‹AÑ>À‹VÇç²÷²Ÿ¯TÏõ:¦L®“$æD.°*eÜqË—ê“v
,ôà\İ<ZQ³ºÏ™Êˆğ]ÂÎ½[9<QÂ7âÏva Le‹Å?‹qkéë,…¿õ'üõ_{dCRöî¦-Ÿ‘­¦È\ÔŸy®8¤Û¶~9’h¾7'ßA4£Â¢ª)h¸O²´U€d¯Z¼s;l|²åìï¢Ç#ÜÍÃ×_Ü)àÄPİ–e¯€/KÑÓWÑª§Bş%ªŸ˜Õ&ï¹¿ŒÁk<7'©£:ap¹ª8"AiåÒî0ÙO¾ñ«û‰™b°6Ú²ŒÍ¾Om·D¡¹íÁÁ?P=ù:ÒSùUÚìç#«bî‰Æ/>köVºÛ<cÕŠÀDsÊ/í¨&6`j%Ìh²U³¯l‹{¡)Z‘ßè#	*˜÷î–dtæ[äÓCCÕºğMÖ	tçè"´@q?–½[üB ãá&S±£DŸü‘EeÛÿY@2,giPÛ$ZıŒgypQd‘lt¯Â~Væ² Õ¼;p2º¯éºqLáT0”•€[Öl0Iö®eA:ìÉûª¿¤İ‰Ö×ÿ’O¤‰ë Cgv"/6ôM°¹AÅ•ğfMÓT¬t ’¡1t®1’ß¨ŒNt-ÖÄ°A62–2œ¬»T–¦8eÚBÌ{ôZj¯–@â“ş¦Er8‘zÑ·]ÒÄtl6‘GPİQs3Æc›Âş¥%cúà	ê§¾1œ8~^ê\áLà ápH )Ô” –€}7O»M¼Ùƒh»¼HK[ÙÁ1Ø5NU¶ A›
NÆ|dX§ÚÖ2%cè*[jßŞñyÅ*Els‹Æ#¦š›]AÀ¬ÍyaöM‚¢å]ƒ2gğ.6¾åèqû¸ ş­Y1„´ù"Nd>©Hé«úš X}àLRõ¡ÜÁ(`a4˜#pœ"yÂ¡+†²1.bLòO;4kj›‰İqYt˜ı€Rì0T‘eI>:í·Ê8!o´fVP@0‚şÅÖsä ›à‘•;§z¾Ü‘ıHR~”"yI<-%æj®›ÚoM‡¦óyVÊ%œ÷ËÍ&–­¤ê­ÚD&Wå³­¼Š‘-|,RYUM
/MïOˆ—>ÊËëÉTmúŠ–7h–YZoåß/òeÖ]ûùìC&ÿïô˜¤}¤8
´æ-²Eƒ¹‹nˆæÀH¥odMÅ•Å»•Aõ„ç­õ¢‘Å–•t-—O”„ú{1ÈãSû|­Ÿ·äyšVôXªùAŞeÁxbî…Á'jÛ¤$£ ù:½Y@ÜU¿ö@·DÏdmºT›*´^„ZkÁejÉÏİÀ7ñÚY€-sÛÚ¨”Ú³9ŠkŞ°.(Q Ÿ³b¿Äv<$ÃKØ#oÈô‘äÚw:ÔèO“„å’ k	j˜ıò¤6…¯C]µ±ß8àF±Pv‚ÜÓæê´‘äÅ’M?¹ÊæÏİïI<ìş¦²ûÅqïF
â=‘7ëˆb´°k^WÚ?W½<[¬ŠhÌOîÚ=É”ÿ¶á_f Ñÿ¸¯Ú=è››¬Ğò)ŒÌ©ÎçÂÙÏz_ŒRr‘Î\™WUªÍÄ,¼JS¨¸Ô2å»—èÈéè„Q`ÇkÃí÷ƒ¹œI0¯æ,!‡ ×Ó­U§p˜3¦ş™$¦™ñSÌÚz=JÜ›*âÿI²‚àp?‡|Õ$É\–qô&V®ëı±Û+Cúº=œ¡Ï/pÔ{y-9+{èí: †.{7lÕV3”çïgé ,mšQ@yo1AtèÊŸCc6¥L¸µÛñ1¢ë¼Õ¡Ø‡ÂzE`ˆ&J¢°¥ë€¾ÃÚõ·Saó
ê>î«<_]Š0Ş=Ø¢ şÏö ïI²<tõsQ¡BÜ½;.7AÇ.ÈòNúL!ƒë»zú®ù°—ˆûñ=–Q#QÉœªJa@ıLä™óøzH,Ù€Ÿ56.r1€˜Òb˜O]×NbC:1,9}Ê«´t/‹¼“û2=siÒ"«ûEÈ% ‘âÒÇ	xÅªIöf”æµÇĞB"yŸŞYˆ5è½TX©}ïƒ+ö"ŸŞ¾p¦³;eîM¼‹ «.×óïÀ¬º=ûÑO»×½u»n+˜ï9JªjÎã	ÊÓUîÁJlŸó8MşIRšg~@…ı6œ‚¢åÛkšÒÂsuV§gò$uÇ7™¬D}¯TıGzŸ8Š€?÷ƒY…>ñJ ÚIœDÂ 5Y#ğs°$úËŒ¿^¬y“ïß2¤äìå³*Ñ?L¹DTÒ;™«šÛ‹vñ¨šYñŒW†AE9;!ïA&íÔXGØlİlö]†‚¯‘ˆ,òÓó§-Œ´6ÆÂ_Ÿš©¢ÃúÑhQíÚ¹OÓ¢+ÂDjæ%åğÄ€¥ Öë}÷^j8xlªêq{æÇÏi«Ó>õ¾¬]Ôí&ãÂv¾ãÕÂi¦jÓß5Ù¶²Kè¯ª±µ÷NÄ)ş«ÿÎ2öÇ	|Ğ­Pï«ÁVîğ¯¿aÊßò	#™j›9â˜§®´?¯ıcø²‘œ7;¥
ôAŠ³õ«0ğ3šÉıOZ!(E” Gï¨íS7º-µHØB.;Ş¦´HMƒ¢òiièaÓ«¬¶İ,Ãª$zt&ÄŸû\Ro¸ç“"ùã¼&@nŸ«é‡£Ì8Ò@àt„©ÅÁÑK˜eıÜ¹Øk×v9 :†Xã½îÂ·İ0k¾xkHõCf°L„€ Dæ+ ·Ô î€ğ3‰Ş˜º¯²O¨pif®™?ŞuB¸„.vxÁ_MgıGÂ´CãiD¿*9i©wïGÒ¼Š„Õºá’B‡¶<±Ï¿kE¾7åšïT®7#ƒöÖm®ôû³ÒiøOŠÈ+¡Móvˆ‘[såe+yÙ5dóı®Ñ–5@A_Mw1Ù9Å¨<&× 9€§¡˜¶¬©)}i•4@…í¦$9ÈòA-`úŠgé¡ñZMfˆ¥B-ZYÿÀ<YÁ[¶ ÷¤~h¬r”AQµgûP–p²ä£¤l¸½•^AFøèP“C ¾ù«~2£×§‘òz´¼ÖZ!/*Æ¸ÎZÈ´µD‡FàÊ\Md
Ì”€ûƒ1‹eˆ±ßûÕì¤ÊPI˜‹h·-Ôq¢­‹ìt´|7i’UëUËÙém§€h ç•â†êËw'_„îa!ª“m*(Ğ|n÷(B¯´8Á¹E4½,¶¶†ÜêşßµZı©­¨¹g¢ÜŒ˜ZÙÄÿÊòÇN"”á%],è²òÏe|kÀÂUÚ™Î3Läì ©M°qÃ¡=Ôpïÿ!_y+é çÒeP zÅ×o;[ÿlt‘¿]l·Ô°İU³µ¿`;m\çÔñb4}ñ6Â8¢?ã˜øËÍô†Y2bèüö…xòˆ¿0õz¿ÀãĞË¢¬›$x=ÓùZé|,‘Øú°Œîû!Ü”½SX¨#(ğÂÖ¦ÑHéÅ°Ÿ„Ñ&Bá'vîÁË€37ÌpÅãí¸ëf9rjÄã¬¡oæ°õ®Ü¥óa6¨_Ü¬à•€e†ĞçG©İÏH®gD<È?Õ¬:™R›Šµh˜­Âšw#Æ¸6`É­”rùQ…S™—b‘«Nnš°ˆ˜©¤gyùù¨=Á>UÔÛJöÑ*ÚÂN}ExŠs’JéD<—
ŞÖ[•=© ˜\yöÊ´–âfU>.qÅœá®-ˆ4’ÃÃìOû«¢Ö&aÒÜÇ3æ—ÏüÓ/e~ßêQps‹5spUëLÎ:5µ`8«‡gws2ŸZ„œk`éÓ6Q.™ò½Ò[Ä–M£sîH’q¹GEŸ6è+ÂÕQM,õÑ¹s0Ú3"šîÊé›¥Êúƒ÷ó2­f„¯-{ÿ÷Éù6{Û“vG3êú\úiûJ„Aªÿ\2Œ¥‹j«|q¸Ò)ëƒæ¶`ùïñÌ!)½ç\‹è"–~Ë¯½ˆªÏÎØ§×¶jFH³Â{åŠCBÌ%†D¦PVÀˆ[JRÀë4ºµï·æÊş÷È[g‚DŸ*&şrÒ†Õ3´8A |øø®>Œ=ÇPË=pM•©f,n/å_Œ2àÊ‡sâºÊµŒUÀ|ƒ³¼È(¦F¢¢"¢'kg419Ái¦®[_û?:ùÕ<Ü3YÂk†'¯É Ùô½Â¹¿œ<asŠ]DóV»1+$&lŒ,Ø©$:à¿—ªÌ*äÁ¾³Ãè2/_Šm<šNU4j;şÆ´ŠŒ?)`Ù/sÊĞ/X4TÁ×úV¥ß8Õìi¢Æ™kİ|.PuË²)ÅAz/—ÈA¦†‘m=÷ªFÇ…í5+›$†[Ã¿é×pñb¤CŸçnƒõ,ˆƒEÁo4hã$)Ü€)§ÙÁê(İèÀû…üä±m“ ø5µôHoÆé\ÒŠñŠÀ—òö_>‡b¥å&­Á¯Š–ÿö[Š&ò.,­ªûu­†µsc$¢»I—	@=:7ğa9»Ö¾á{–¥	¹Àã6WtDÃQdy¥n	/L\Š$k.gCmÅ(JkçÅ-W²<'c™•\«*qâèœÇSp—BS!&7ƒ¥‡`‰‹p+5‡ŠR­ŒzgÇÖ×—óˆSıÜÇ|âqu(ÒªG(uúšöw¯¾ûZÍÛ•agâÖ/©OSærOx¾¤")¢ŸÊˆØÛˆQdÏa)_Òp®÷{ú¨
ÊÏÿ·G…f"¯Gx*WûlŠ°®pPçFœÈ4¨§<6›!²;rÄ.Õ^ı¢Ë›×ä×l}w%f¦cbãï[w±7Sê'İ½TÕ™©Y¾SÙÉøúP1¶²IƒÎ{*akóÉ$7úVæè¶´kH“åS
Zx‹È!ÁRrÀ uØUíH¾0ÑÏÄSşÃİYíÜhzù~éxv·¡ã¥Ö!ÉM:8I2ÿşŸ}ùµQ¸îéy_bºÛ„/OÃ™"ÉL”Öy©&’ÍÜDLC$ÜÄ¯ë¼Ûì!¸Ït±:ª×kÇ\SáÌ˜À4®5H¦£ÄHw¬Tå;¶ß>’¯KJ–_s-|;8w÷Ô$ÕódİlC,MµålŞy:fĞŸÄfe|=`H
@Ÿ)²GŞË_îD!OLù—&‰B—ÆÌ+zzÊ^?•îhÅE–
¡¼8í»7\<,­O(zùR#>íÆÉüê{X”ş}xˆÑÖRõµG ÚhCßäŒ}ØT- ‹ˆå@L©IÿU¢0î÷a¼sŞì#1×ûdGu«j}|Šyb—åh6qÀ»ÒP²ãœ\ë…­Oá{Hæ&¢lw§=£†!¾¡8%Ì6Î†IkD÷oQS÷w5ò"o;mš$Íï¡Üj†7ÛÇb ÌÓ@Å… ©¾âÃaÏù&GŞ?:Å:%'$™­é‚10X]P»‡<({xrÖB„sßdobµkĞé4_‡«5²Æê!µLÛÄa!µn3HíÕ¼4
$Ê,ö–…/Ş|íóí;OÏ:wÍ%C|Íöv,|¨¾ƒx—ÃY¥òcL*º™øõ¢×¢îÌå'!„>¢¢–d&ÓïŒ\ñB8¤.9vQ,o¯³[`äÉáşY˜{˜Érª$íº†ˆJÀ<èôëd;x®-;ÍİsgîK¬¤‰Òçrt¦™ŸtÙËªÄ8léş8!$á1„!!˜1_"ıÙZ©N«E](lGGw˜'ÛfëÏhñ©ô“ìGï…ˆSúìD¯ÅRäû†abdÆír®i’ß«,äğD}‹jŞJ}g¶ƒ @Ÿ_#ìS?è}­‚÷ÅÃËNøfdkC,wŸEÆ‰Øc×€û^ ‚³¬}4¨nÜk“)£QŸ!ŞmÉ®àäá¯Ã²³Ö1V@bÑè Õ¨üÓ":^îö‹Ê”­ìúk\F½½¹‡×(˜0ğ8+È y)L&Eíò¦å`ñå¸Sù”ùÍwI¿Ïp=DjıágV-_ÎM:Üu3<züÎ¯÷åv?ÛMS}L$ßË•Ğ g¯ö?Ç¯ ?sjh·Å¢,¬#ZlFÛœ‚dÀ°‘—ÓÂ†òƒa·Ñ@ôĞ¾IJ˜bâ#yb‹o’ĞyD1ïı)$¤øñÕo¹@×[6'Ac
ÊäîDê„s€f»¹‹;`30òø"‚ş“à`Ë–Y£Èj‹×:u¶Â»¨Ì8ul¶Ì÷-€šj¦ÉÂ-3fÕ3ÛŠ<Mó«ÜsK”=‘»öG<ht‡¡›G%£”BK-[Áò¢oíWıÄÓ*H+-¹½MøüUßü²ì ¡Â¹‹¤–j;àhÛÒ¿R|Ì-ñIHi%~×¨î<‹GGMôæñ(nœaéhbyü8—ƒ(úx˜#Ğe¦ ™Œd•(=SÈv)}²ŞSwE„ÿ«7U>­;ü›ÁVXupÄU®[ÆgîMöÃLıR-FËí“Å:ÇeíQ§NUB¨myN3¶“ÌÅğCP·¡‹"ˆ›0LD 7òÏXoxÛr­º`úü/‡×°²Céº ŸÂÇ5¶öKx.%YÀ8—4ôC…GÊÙĞ9ŞÍk“«À¹1) ¬NVATÂ—÷œ#À^õÁG+úë#¨‰‚qç›—ğƒ»Ç+Êº2FY#´Ú÷èÈS?N®	Mö2ÈÉ ªŠÑ¾¬Ê°š¬4q~*Å•šš„™C/ØI½\£©«µ(#ÚMû£FB²µ_¢ˆ”Kâµ­¿¼†jm(_RU¸ ‡‡Å_Fäf3üJªq¯àÎ}W¿äà~b-Ë‹ÍÏí [*qìÖØğ€%§ªö]Q¨‰¡mÿªúM›ÁzÓ&úXã—`Œ¹˜ÃE,9™áwv¼’ûd£Àrßp¿wªÕQ|#øN ¢ ,û,õsß’Ôáe³ğÅ6ì6ëÔ‹ƒó7 ÅÚ*}«ÆR:¡F0¡ß“7¤¯še$î	”€Íl„2Ñ(¦Î”¢¦6û†ÜÜ™á‰ÃE_«µ‡éà9Ïˆbvz‘Óu†äÚìà¸Àı„ä¸³TÇ›FPİ¦­æÉÛå’ÑİÛ?«!T}ÓÄ¨“üÈÑ©ôã!ğ¯»ë›»…‰êĞ$ÿ/ˆ˜×vg%L9±N)’L¯1@I™¼NÆBú”üË¹æg+ÃôgD#VQÁ¡Z¶0rïë
¢´ûÀºÔ\!ÑÆÍOÒ,í>I”Ïè*)>ËlÆVÁºÀë ¨Pï3†è ’¯ø)v¶ ÛKÖØ±¡{ıÉ&UÛ¡;4¾:qúéótînş>wŒ¢Óy êªåÓ‘zsÇHß1ñºwÊ+çrçeò‡´1?Ò¾‚EËòØ«‚F´$şZ$‡e™·L.¬‹ü–öR‡’ÿŠñ8 -Å4ë™©ìÿ™¨G4µªXœ»ÛêXJµş§qCÛTbN›ø¥RŞ^wó\¯ëä×ÙzÈgIyjß
”\N}ğ#¤™½s	Ü»¹84ã3”üÍÕªXF¤UÃ5§»ğ¦—‘ÈÀõ:.Ò8İ1ğ0Ğø™ E*4ÿ‹$äåÔÀ6CÛéƒA~.eiw|Qš'›ë}‹›ÄÅï]Ó£R]O¬t:Ü{¸ü&®W‰ã…«)„·k „Ò§üçøÙà¦`[¶A28´ºÙï‘ÉtòÏ`—¤ß Ig¾â`.ÔÄW•?{*‰×â6ÊØ¢ıQ¶ƒÜgÜƒË6Q,ÕQhOoØ(ãwI&¡Æ§•`W$¤E¯j V³öÒ™¬-6LÒ"ÖUğ¸æ+”aÒdµB âkö$	şÓĞ_÷¢l|9h«+N~’=õ67ÓÉ¥œ!Ÿb#XöOsß7[E5ê|ÍHú²N®“„û´ßÔªÁ |ÙX)2^ñ@W@O}õ 9Æëã3l¨§9ÊÅ%ØİâŒÓB‚B¾àéÅØ|ÛUŠ£ ²·Út<ê{÷‰T€…€à‡ˆn­é’~ÊÔRÉú/İÌúè2HßÑ×}Ÿüd¦‰,Q_™hCbo7Ù"'ëK‚ÍU$ñ«h3v7=@U-ÌÌl5{áç$ã ş‚

$k¢²_f¤~ªŞÍğ(1ºfqk$´ù–-›õxÉh*Š	Ô¾]ş~¡]VõêV¬yŒ–ÊúğÈ:¯—-r5ı¯ÕàâfŸdöw Èˆ-ÇG²ûİA¦_=ü‘m3½¥ŸÕöÊ,Hë@ôT³bàY+§íôÅ]©p%Œ>.[b[›ŒT§i,E—9Ë…*YÉPÙ"zµq‘ş˜*¹Æ¬Ùy7ŠO˜~ºIèµvşL2d„ô• K·^ÃÍ‘ƒMí2UÃWD¬¸Ôdm=émÍÊaô3‹ˆÁeÜ$ÈÙ— pé.Û(çø\!>%ç·8v(>4ávobú@±É9v{x|åbÂÈØ„.%0®†PÊ(ìcLõÑ4Áêò¸õ’7âtglÔ¤È;$gz/a¥Ùl‡šÁG"…#!9}ÈÚ¬fY¯v¡3¬zæÎ’sÑ[¬÷¿	gÖr“ÓN8£a€ì¶K–¤yûÓõhçÒe`Nsq[PÍRÒâSb	u?5¸û~~-f¶Œf˜½à6ÀÂ›ãÀv÷ÎCˆ¾_Á,ÉŒæs/\j½M|Q^+–®¦9QÊAÆh‡L&¥eèWAZ¨Œ·6Œ­*5õ2@‚s¨Ğ”5È9¸——m1jiÏ%áJ¨ò;|•=‚h·œQÔ£I&lÃIãÌåòI
îM)ú.zˆÉï2`K)
Ò8ı{ë4àØÎ¼egÖàƒŞdÀ…Ëæ³°y 'Fçèq$Wé, ±7z8£‘Ü{3ºT=EM~¥ñpkÊ:çU•f #‰«›Af•<r{€ğ|‘óÎÑzQ˜ÉRJ,nÓ€ˆÛOüqksÓCD³<cXìœ“\0»~Xåd-V¢Ç[ƒ>7u¾pµÃİ…’Ô6DÁ_J™Õ]«³ôÇm YsÎ¸’Ö›po¾ÜÚgx`äÃlYü $i¢=İ¥ñL @az@(LTfå®T6=Úów’½ğ)ªŸ nåOšR–ê¢»_ˆªg.Ô·<rS¹qĞ­¼aëz~‘ªêôø.QÙ¥şaí,ù çóx!"
8N¨Ö…@CßY›Gb/ÒI°S¯5Ç<Zá³!…³„ÌãÙ½ãíº$7¿h–÷yw(Íµ˜ÎĞ°èUv¿fËãò×-€/¹¶<D‡ÀY]^ú^,M©ÎX&Ÿ:QLÒ*7¢Øòòg­7ëã‹è»HwqíT€½²ßêa	ê|sÉìˆZ,.ª¦ı•¾M±sÀ‰ü9Ë¼€9ıÒ¡° m‡¿_fâ´4Ì§õNTŸ^³X\¾X\×­Èl9Şê´õœEcû»†_’=	èPÜï÷ª|7YV‡ŠĞ¹¶Åª¤ŠŞ#Ro¶¯bNJà#0Øè‹†ñI~èYˆñz¦~´ôYH“„5
á7Uğ‘ƒõ7¬¾Úl³aAB’W®¿œpj¼MãUr#¢dˆS¥ÕªhĞM:íšE¸6âhøËéFjrX”ôt÷Õu6W\e¿—dx<ˆBæ`ÁÑïh¯®‡Ú…    Ulùá2Ar şµ€ÀØı8±Ägû    YZ