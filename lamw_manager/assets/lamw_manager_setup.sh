#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="133346406"
MD5="ea1826e4d7eb42f516232280ac7df40a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25856"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Jan 14 17:38:44 -03 2022
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿd½] ¼}•À1Dd]‡Á›PætİFĞû“ïÒÊn°å“—¾8BY“üï|É£ëkêÛL$ê¸>Á‹oiŸDm¼‡õ$(0„VóSÚÒæàí×®cGÃğ¢M R
ŸÍ´WÙòşZˆƒ{ºV©¬,*pZï±)ÍÀñ„	K¥I‰ö•æ­jc–3Fènf4“î¨¡òŞıtÙx3£’O¤İ¤{rnì’§ãÃRıÍË-·2¢­0ùo‰Q¦3İîÀ<©vBÌP`ï»+rQ1?JfÌú’–"ÿœo’sâ{§akSV(7%á€lÇ-
:Ú¼3¢ûE«lÁ— ÛgF?MgÚÃ™Í«·P×RĞp]²—×ÛÜR€Á|!¬ì:X|E`Y½ô¢SBcl)*¸‹gepÑëø_,p£\¦uìeK™ø Tr=·®fz°×ŞäÙMê+îÒŒRôğäÙLEÁÓZ¥ÈùKCÛ·{mE®<W¢ÚËì	.À^ªRÀ) .£E,ÕÂà¾şŠxıiuE&½vÅ×..¬ƒ0Å Lğ†
b~äikVï –4.XØ>_~Ûæ	*ô;­›Ñ£[l{šÛp’£/7¾”ßi¤ ‹‡<;ôKvæ3[ş6ñ‰µ Ê]²­Zì~lpmU„VD8½£SÇ„›8ƒÒ ¥i	X6¨6e{t…„AğG•¦@¡ŞEUù-Wšã¹ñ]”2°¼Ãİ²½Ç¼¦òãLÁ´S{—^àˆa²áòûEJş¨	ı¢pLœ³ÿì[L”bñ
 „­i»qÁw0qÈÙ­@üKòLW­»ÊTf\¡H‹Â¥l)Ú7Q©º¡o"Âî4Ü™„ùUÙÀôüøæ¨İöo˜]X©
$¼bä×-ì8	<ío²ßHÑX×k+e›³æŸ»Ü»«Õ/Èüü»«9š¬A°º]pU‡öY‘ñ2´KÅ	S&õ»ı~ö-ñ/HİzÊ÷#Â¹>÷oÎFë&ıú¿»µÖ]KÒ‘`)ÎO‰X`ê	DH1ç2$¾'Å–Ã«kÃ«N6÷ÁÔ_úÓ\f.•N=/ıFT£”ğî!™.¼N**’İæfmX¤şšQ£îZŞz«RÌliN”Mm³¾#ïŞIÍ®p”œJê°¥ös¨ÓBÒ&f.{Éu91DÇIÚáANõÇŸ4/ã¡ğ)„÷ö•êİ$‹'ZÈàY_æ€;frF)•Û´Ğ}îok•Ë6çNÄ¨»\eğHãò•º€Ù¯Ù»[°Ñ&s~{Fô=–NL…ƒ|3²]û6| ÷,É«~c¯Ã&WÛ \öğ2èßıç„}×Z#{B¢š€ööÕDèXÒÄÑ—M‘yl!T@­¼Om’ÜTÇÂİß†vÎ›ùó´'ŸBs‹•+à×>Œ–‹öä8  XzwşÔêø3	·´éCXZšûÜ?Îé&œØ¯"* î³I«vl¦}na,ö8vèÆ€$UR)ù(«ˆ¯=¡\}/gš_”åä^ fÕE¯¬Ò ËKø&“+_jydt5JŸ:6JNkä–Š1i=åúJÍKŞõ³Ck“MêƒÂÂşºuóªÁ0,©*+
¶æMg‚XË˜äÄ‚?R•Õ‰•¼Œ|]›ö)W6Úé Á¨UíêX¨5ƒa”rHä5ÉÉ€¥ú'm)0›8/óå{ƒ{Ÿiò&ã3ÿÈqÏ/ Z¹ÃK‰z²Ôõ“$C3)m…åç İ3Ÿàw	«	pÌu1àSæªç,4¬”ÈcñOùéX¶{“	 1Œ¶ M®”‚|êSfüW¯–ï‹HjĞAÙÿ*ìt–±³cõüªŠ˜s•b¤"W‹è÷åÚr¶Àºìñ!p£lê!i††™îßº³×·`ÁZ{EüŞçCP¨KP˜g€D%ÛA˜“\WIZÄ;pŞ¡èT2ƒmİN¡E2µYİcîPUE×ôFÔù8¹ñ^Ô¤p*7èr*¦©|È¹|°\tj~â˜*m¥l¼yiiá[A>˜X}EZ²€TÃıÌØŠoäŒª#`¤Ú‰ÜİkA‰â-Ø4éü!Hò-¾µâEİr†‚—úæàn‚ƒëÖ&*Îiæ)Äñq¶{-­;ªés¸Å}ìŒµb›b0àsâ¤/$1§KhF´Ñ>n;ˆp–AÈCµ¶¼-×ã/€CmÊ_ß)MóB›…Ü>n†VH9dWP£ÿ—øs²v„t‚à’T°)¡®š)^Bí$º¹©Åimî)¹À÷–2SÃ%
ÄcÀØáR±İK™ª°ÄÒ™‹I¾š5fÔœ{Û`˜,êíÜ~àN0hw`$ç	-­8İÌw I—SP
:øV@x!PªW!ªà#÷¢¯"ZY‚ñ-¿Ï¤îšì”ŞPóó°Zïiö'G<ÇÀÜØ¹aZ»ÄÛ{¡3
ß@ZûB.£-òzU¿|ºw¶@$ôdêµ“.4utN,f.¿ÍoÇù–³Æô6pDˆk]æİ3ø‚'ƒŒCGD¿8 `TY9R@›hˆãf ‹(yG B^2iT$Wi0×åk\Rÿ»ûë«ªX€oÆİ1`f›ºp?:Y,eÜaôúåùŠÅ¹L”öŸÛh™®Lù1Z¥Hmó£‚hØŒÉ‚™¾Š*µSNi8‹÷Uí;")NWÙş|ÃC9p&…kHd³µ#Öçäâcä9ÃŠ’YÅ¿·öòPAVù¸	ää!8ãŒ2iù¯$ğ–­Ö‰? h(qö \Ç ¹SVÈWæ1ğ©`óD±Bëp×&6óˆİ©2D3$ˆG¦E ÕIÊƒƒ``ˆì¡1AL“Qd¶¯Ç`«ÍËPT,hI¢ClK+¯=g@½”‚…µ¾$ó1$hÓ:b°‘Ëló˜<e”É&Éu“ª€dTáŞê6áâór[88Äy®Me]E"\®Éîü·ÕÜ¸§<÷ˆ\céFÊ¤OxéTQ. ¦ñí:?vÌ}-yüzó®¡³êS@1{åÂãåùIÈBSA}7Å¿ìFø¡V”w1šà—nÎH°mä™T-R.²Y,ñ«x’ÕÈdADÆj7šÿ]Ã€~Š2
YºCôÉ:ˆW7…Öã$Ÿğ.N$ï%aóœÌ¶×(/HÍ"C3ÂmSbOãH`JHÙ%S$8/dMˆ‚Í_°‰á€ırfôúÔÂÉİ.ë'cq'G#½zÙ 2š‘ç›gÂ‹[@¿®WòƒyW“i”Ö´á‘"&ğx.‰Îf“öE`÷bı¸`5LÌRÑù`†dÂnN„Ò*:«ÿ¦'ªÍ¨ÔªæÉ§m£+O_uºŠÀ‚mŒB9Æ#µ1û¼Ò2BN·”îYó9A.,	ŸşÒ<R´ûãÂ^xqàÖ:j‹ËbvÛ©/3-UeÊ9†l¸¦·Uø0´ßËbğ17Zg–çû=„Äºª”Ô®-‘WÛ·‹jL*(uN ?>Èeİ¦ŞÑ‘#Èl ÏÏ8ú™*9í^aˆ>(§)5n6R˜Æ’‰é‘úu!¢©ç]z5eÜ\¶AŠÜj4;ÔSŒ ç& #ªUí¾°‡rßî†û®İ¾yD†yªfÁG|¸•²ÆÏÏ×ˆy¿Á3V€@øe$vaPÉ[TÀ	±¹L$œWCdÑİ¨´Ÿ?|#²Ezï ã=’ñš¯2+&`¤v ›ny®a[Nd.¯Ö‡nrmÔ+ ÇÎò;NFc‚d˜N¾B¾›Á%x ïcÍ›]êíˆLi#D±¾È±vÙ2Û­;ãÚŞ5XE³‚` ™ÍÃ÷ZN¤r€ÁË¦_PÔˆ0s˜i2f*xJ¤ïÔè­ãÍm¸¡âí{„’ÆçÑæyí³›wñ÷|±0G¢…{Q6ëæÕ1z)ƒî:Ô	|¹,5ô˜ãˆ”0Øõ>]òT¦µ¥!;8âü@ÀWÎà¹)yñò=”‡ÂŒu¾mşKå¢Ú~ KºçVJ¤ Íú9 7‘q§Åtö¡ÙA©;>ıñ9sıÊËŞ\4ıebÎÎÒ¿W"ë±õkŞ»,¼„¯›½‡ºtI—*‹k“Á[óÆ}ÑG`
;&wâ‡ÂÕó!Wá¶<·ÎÚÕ`I´^ş9çrêK“.lü›Íei£­ü¶‘°ÌJömEö¼Xµ<{™É¬xÙ‹pçöó`çÃ¬ÊõÉ¹_‚¹H<IAuÂ³À,ç¨äK>ÒŒÚ¾³æ7 ÊëóFy®­³6ßÿÚî2r^g~¹Ôç¹´^‰ïÜÌGsg…Fo
ïD”×µHöšGpÄÃ]h4v–<)—k9\ÜxqPûN¨Ø–<4TQéÿÊ&CÃöé5¨;"\b”G0ÎórgVÒ#Y£è
Ğ"8¢œ¦wÑ|@àÆ‚œ•[¹®bI{¤ ìZ)XG´±ÓÔëâág~„åQNÚë¦|nñË¢}¢û¢èo\±Ö÷ahv¯bøŸNl{„8d>‘Aü:xë¤ë[5=#Tà¨4#Í²³>óSÃ£	ò©$¼\–¨BÎ2•~vİ6h–¢/ ~ VGÛ8FEô/ÿì†I¬QÏZŠ´®bµSôåê.½#Ûöl6Êş×QH3¬K˜¥™š:]t%/íqT{=»%\¼i¬şgíá4Ït:Óä­çÁÎçŒ
ÂŒ—JıëƒŠU1H,ºÖ:°T_­E—³²ÏF³í¾©Î¯LÖHİ‰,í›wBÉêdˆû {ª¾3#Ãö×1aºÅ®«·¾­rœŒvTçîú½Ç$@c‘¹NLëı´Çõjù2 s.@•ğ‚ƒŸ0»ÿşã•º1³¹¼êjçì*Üm5
Sj§èönãKQó“ø«ùŸ+fûINH^àå	}o®-ØŞ–ğ±äd½3f¨~«)å<ô—:!eFÚˆ,Ë_°²‚Ÿš½Éø ÃÅ–Tmê£"¤Œ”ıë¼IÍªF_G~’5¯lÖİàmy½Ê0Ş™™>«¶zşHù›Q
ıúr|‰U&!ù×éè“‰$ÇŒøNlîDğ v>°`B¥ó—œÎñáåv–ÿ÷¿Ø/?–ŸOÉ÷E‰¤¼„úú§ôÓçâ#ûÙçÏÔ)¬:XÆ¿UŒÉŸÜğï‰5,<&J³Ë`úÎİd]F ì& Õ\l˜Ô"\ÃÌáIÖı¨d8¸=–À#J.k@L kE…+¤[RÉƒÖ&cõû{$n?\!¹e”<¨)òß~Ñó0“Ø¹î±Şâ eÓ.î¢ÜÏî DoóÃÊ¹»rµ0º¥VŒ¦ên0à­ß?W}¹uO#Yüp("Ôw_cKc;×ªÁ&"×dr)—8bVÉMíÆ×VÂõJîÕŞ	®7(ÛG˜‘şöw5³$9*E€?Aõì”Aìyv^¶U¯Í½ÇûË# zÜp™RNB³ËIù(‡6y$„&²Î­°ï€(úkŒ êG!‡0ŸÍ‚-$ŒWcİòÑAÌ@ŒÀT¥r:4ÈôÂ4Šc9g†ë¨a³Tè×İË°ÌÖvks9ôd6—n¨´ríH““G
îÙ¨t«²•ù™¨¾Xj°ÿŠJ»IÇ,ûwËR®KÃä¥Œšª+GÓ.n_¨¨	d[–h|à‘uøx`›ÂÖZ¶»£M !¸Dvoÿƒk ëç‘«¶ı”ßÄ,®XÑr£wv]èÓÎ"Šß#ÉTèøc¼Q
½ºîÌjµåı‰ïşúJ˜{]^àÒÿNYb“~•7Ú*gš}á^q»‹Û31[IZM2Z‘+iKøÜRVtjÊãTà¸[ô’òÜ¹59œò—|>ö’ÿø¥0ØÆémŞÂ_KÔºÔüU)mœÇ
cÍÈÕûÀ›õ„ï7‹Éõò1­v"nƒè«¾£6ÃY.÷Lg.»)œ?<QökPiÏ[:¬'‹.‡——åi0†’Qà¤éøÛ˜ü!XpàQ‘ˆQ¢>V‚*„gVßŒlKq.¹J¾Jş•li1{=÷Ş
¥—œ‚f_ˆnW_Û³‹ò4õKGÓG»ig5M˜¼5RZzQiüg¨~<ËöÉ|âTvyÛ…N-ÿÆ¡f¹“.HÄÓg{UËŞ.‹sÉ÷¦]iäÓÍñq{‘YvsMùV².È+a}Ì!¾ª•hb˜­6v'…AßÔó™+5{ˆ{s÷¨å)²jO³‚+~*\_ª·
Ğ{GËiøT&¹¡ XÛtªáÿUWë7¿ñülS.ºm/Óëô0ÉM}AÚÏã’í®ÌPiÁ®¸P	ÌÂ6»‘ïR)?I®§?•ó£<áW»õ{^¨B®|[òÿøŸ„IÀ6ª@-ªo8ëu&	ç$é!ê]ÕwÏ®:fRßºí²ZÿPãşŠ`i^±l˜¸À4™Hi¹¡2°¨*¾¥-‰ØS
_{åÀàÂm28
ªå¨mşDìO–şW»~s-Œ<‚k«¤‘™5WïgŸ›¥f 6¢Ê„û‹&ÉàoX|oŒ6Ìù–]¢çóˆR=¬¢‹I°”ô¡ãŒÚê‰¹ºÅÚ@J©»£‚«â00¹×'–²c"AZò™Ëã AJ‘ë ÕëÂï°·+;0e}2Ö;ò Us??ºìTÌp0~9gÃ”æùtYTÒ@ÿQ´”T!rîàyŒà0Çí’†vÏõëœ³¯íJÕ 6<I]Oß&®¬‘¾]3…tô&4kiï'æ­'jØ{‚Vò}Ûµò²+ØÜ“ãsÆw,ÌaÃ8!Ş°·¢Ây'†2(ºÍ¥«|+ÌûT(8åŞEÅ7Hh‡ºkoeªñ¹!R¶Ö‡$‘;øïÎg<Ôê½õ¡"Ğ‚/í xñ
°KQxP”ˆ6òÒ×uîQŒ"LÜM	ä…x©ysÖØş@ª¦‚oˆwL T~8œó!±$DÅyÔ ­€ÜEänÍÛOØêY[O®g];(WÄéÍ§År5´yòŸcr¼ã´LkWàº»Š‘Ç‰PÚWÆx$½Ûù%Y T2ı™Üu×óe–£V®êJj*eÿĞnÃƒ¤ë5ŸïØ‰OtE›dH÷6î]O­ª4€ÅT°7ŞQ4m ’Ö±˜œïß'½öò:ûê@¦§Sd 7İõ ZækØmî UGFÑüâ€T*‚_±ÎŸª¢¯ã7Z$¼Own…-ù«³Oşêèğ!=j½¿-VQ;>úÈš£ÔÀx/Ç(P}=O2¯—Ã·å²©™j¿ Âyğk‡NÂøôİ]	ŸëÅIBæğv¯Ñº€g:a:„\ Ã¶6ÿ`S0Ôb€òÎ	‹uÜğ<âº..Y”­×çÿ—õ4Á.hMSõa—Ì¸MK°ÉFS
çVQ.¬ûp´ÚƒôhÖóÁŸñæhúóëA¥¹üDGĞW1rZÔ?ïù]LÈcëÊg“2BšfĞÛIT<rı97@†‚‹iœ×? >#²å¯WÖ±Ú­>+ÃğÊ¡Gz'‹})ì¸&[ô;lîg$äºh“øeĞAë\4s·¤v0ÜºÈ3óMısZ™¢[X ·_¡È‚·
ˆã ç’OÜ¶|ÛãªE,PŸo+Ù3—~'@POšÏåò×ešóGiìñïÿyèöÂ\Á0¾O—'Ğ/•uĞÏ)óNÊc¬ºøÚTş=~«ÿmÈîÈs`¯éw²£CgöT·û'?}òMğ ­ğÄ¨ŸäŒI·
É`]¶+¥+^@w$™©d…V…õ¡ıÍâÿ¬P-MMexš|6±p¶â?|pMy{m>Su[J•©š\N›<–1Alx}Şb5¾|K¤oÀIÃé~M¬ñúæÙƒäk)úØ÷)	^$şŞ¬yú¿ËúJÇôèm£yh×!ß$69öhÂh4	,ljÒ‰QÄ©#°n½)ãĞéÇ¹ÚâÒ«ª»kŸËN
õ¯VÕsZÔEC¢H^9vYQ)Ş˜™vüìµæ&–ZÜ2KŸ3¶wdÁ³œ*°£ÄF´	˜7_«HH2É ¤¸{ğÓ¥ØâŒÍœv§l^õêÔö<å#®óú WYË®è`¤bÿ·îï8»Ø³]ñ­ô?ÁÉ@F(liYxº•GÄH£CD)ÏóÈJífe#Ø&‡àëÅãrä5ušê×¢ÉÂJ›XøõS}Û°_6éúŞõœScBëä‰ò=¶CVCHÔ¢Ğ-á”ÁC6±^L™ù]ë#ÿJÓÖÄuRÛÍçv4tlÏüµµyŞo:Îzí—8Ö¹}±LÖ°(²-Ó³z¡´§	#al”şşåüêÆĞ¬kÛÛ?¯[åôeñXw±ë\rù{ ²5­ğÕµ 8~½[ \tp3wü}Nıª.™ËgW·Ô.(DGQ¸=tö=©
¤Ó‰3&è™ó†/ÓY­×`'©Ü
wÖ®–Œ¯4jd½#™¼„UÚ3ŠåëãxÎÙm¨˜}nVÅ@¡:¯‘l={vªÀ«#ëË=æv}¬%–çtPŞ—ÇÓÊ	ÛF/ªïµ»A §}NúeA\ˆáo•" ‰C-‚QŠFKKµ±Ï§Li\Ò§{"Íb{2|Mòƒâ•­Rõ*ô½ØJü¾ŠÆø}*Eh¿ï´k5|*D‰åÕ€“¸DöÓ¨/OBx(ÒŞGO9æòÅsgÈ	IµT§N$…¸q›fÚ8¦êYä‡”{JÄŒ‰ù(v”“§ø\³ÔñN3”Ğúyyò®q}IË
S“¹?NªrUHÖ·zw-uàáKõ)š˜úâ{Éo'Ÿ	‹üD'')8°¸cd÷;üyÓ6×çxÇ	ÃË36zbN\öó*~Õhye“W‘ìëZ¹:4ö÷sí:fı¾ßkI ¾$ØØÿ%¹AôRÃ™Æøñ3Æäœ?Y¿ÃkÜiÓPß³QLªyĞèõ>ÖÛ¢	°o¦`‘1§â \Ú2ÜõBË]vKæ¾zdÑ¤»¬„§£Zås°—ÜÏÉÀÈH³ô`Lâ#l•‰[|x£
Úê‰ìy†ï^G&IÅ
aIO(µI¶Kİrº‡gGQR¾&TğZ[>i]§\D.›‹1R>µ4j´ë¢æ 8ÚÓİ£¾
p”³ˆÔ¨{˜˜>Mî‹“{L$TÁH²Ó•ˆäáR_”ˆû˜{E3‹"â#!ë³ÛK*â+×.°}ÑË02DO‡(txÇîW¨°™å	’´UşÔ2>ıdÊÛ†ËT¹fïƒ8j<£BxÔ¢öÜ6iw³®ä¹¸Mzİ8—Y6ûÅáyéMÈP—!ğ‰Ö‚LÏ?®ÑÙX‚u)ödœ/oŸ¹Ú$.M¨²O _¾ØĞª=¬‚(Üã°fåc¸#\-:¥¡pC5"—ÎHcĞR9JxcÂ±†üéø#Şx†c—qXiÍò¤LI°©™¼ÿGJà´*ÙWqÁú¤/WAwP³*{k'ØuŞs)9xf0ïÎ¡N|Ú×5	Ùş¹ÍªVNö­î#ÛhSGßéLàg`¤Ãæ›ÇU×zÃÑ©¾1^&OX<œú&ãú™Uí%	!9Èí‹ÆŸW?JÎÒÅ~A¾ş°AZR†`Ÿ "9=k¶ª‚ôU¢-½ÿÙHgÃ…-¿hÑZçæô’~g—o³MÔàá
÷Í?÷L`^~fµqÿ—sMıPú¼›¬·Šf)?‹„ë8xS*çÆÂl„Kûß­”Z’­…G³¦j1· ™Y:ô}úR?J9OR7k$zc–8´Ò@åhy#2¸+ü<|×Š•
ÕÃAx¸SÛ»ŒRdtIşækLcK”UÍB¹rÂxf…<)•,vóá!ë|à‚½\A’xb2ùø/£c»§4j¬1Yñh–q«Ï´×mXS]ãEjBÙÊ¡Ã\¯/g|íZ²¦µŸ²@
€İâk4¼W;azQÑ¢ğÆáÑÔ¾W<sbØ´ğ`ß'WyºvE»vàë…%€E¦Ø6ª8Ô?e¼™ÌTl¨K¥ÄÉ 7$İ'RW¾‚â<¼FêDG_ò÷Ø~7õKÉı¡éaÊåİ)C·¤7¹A¨•´ãò„ºÉÒù¥|öóÈ³-ñÂ¨Á63êsÅè‡xsdèv!v‰¸,C+«•€-†.‚TcìnNÀ¡{óïÅ‚ºÊ Qß¥Ì}c(ş¥åƒkİë}>9c*x@&®¼¶b“Gjâó9íº
·è$F§s)0Äï/ĞL7b s‚İËğÏXÇÛàQÁ†<åßì]/CÙ›ÓÅ= Éºàîå´9Z Œb­ îß‡j’
u°Î¨ ÃÙ¯™;éÖÃ¸WfM„å
;P–B—?*2‚ŸÀó—ÉÑô³^h–i n&n|Aı»^åìŒ÷ÿf¬¾kÁ·n8³Ä‘p¬çÅÌã'm*e†İnø¼›–7XiÓ‰úÛIĞÍ“3OåXl¯@§œÈ+“İÈA=şn~„¦6ôI
É`(^¬ÅÛİ!„~G¯^G%Ï7æ´§¸,'ö§Ê !?ïÂ[íE•¶†¶óÔT\{È=Æ/hS Fc3ŞµŸ±ÈÜü…—‚FœâS§¹z(¸6•ä2ØEQ"rl›çfÆ5yñÿ_Ø.o òDÌÍ*<Åù¥§İfƒ"GV&YÔÅ§³qºÃÛÖxƒg>pUÄç2ÈO]™€ğ–ĞÒ^"/JMµÍóÄõú–è.øƒ*htÜ]lşØÌà´ƒØ\bÊ®!M ŒşR?Üûyª¾­¤<ğ˜	~!™ì‘ËµÂ¨.vİOxkí{äfN¤WÎën•“úĞPyŞ~?À yTPØÂxêf7ÇN÷‰r{êqpÜ¤™Km³o?o¸AEÓ £0"ã“–FÌ¡Ná½[¼Kœ²Ä;h7˜(ú¥«Ü´ÍôS çO£/ÅGŞÎÏ¶şÖÀûT3Ä‘U>ùPáÕáBõ§¶İ±ktBÄÔ4WYİĞõwD='½/
—ªGÏû$ÎÊÿE‹5„üo±Ä©²+ƒûíÒ~uocâ*¿.á§«^7]İ(±å„ öÿ×ıÁajºÛê¯æE4ë©óÒ²x—½1\	µô³ÉÍédxågOÕœ~y"÷¡À{OšäIá…)şÊ¾€n‘jšò¶o¼ã.G4c'èò„²”Õ¨¿í[¾n…pZ•­¾Ïıš*_§¡Æc“Xt¶WAbÇ_”wŞ,¢Ó+B’/¤îß5âCI¤vRéV=ºØ®4ôR
‡aÌ1ÆëÃ@UØşl&¼»™O#õ=g¯\6Q©˜z8ßu®'½öªø
°úÊÜéµ±ˆL65,‚ô0ÓGÕ66:U´l™•+Uw®Şí³MYa¼ô0¨	©4™gˆãÙ•½Î0x1•ƒò[ÿ²üF„T·ì3ª1jdêÑwŞ“@¶ılÈxÉÁ†¼õ î1¢e±Õ®¹Ü€¿dŞDHw-_Ë¨’ÑÉ³‰ÁHgÛ8ËòW‰–ÛNîZpÛÑ~½ë­mõõ_R	!ÁÙ£Ê$‡fÂ£©õSdØ›‹ ½’í@òğnP@}$6¦¦AA½ÙÀHÂWÆ®ä²Ñ	RÄs**°5SÕè¤Øğõ $}9	ìFˆ]£Øô¹œÈµRX·W…öës-`H9nf!2‡åé!ŠWÜÁÿ*dÿ¨â)¼ßİÊ#s÷›U?FãT¬åŠ, œ³Ci?øLöæá7ßåÉ•A$¡bñÔ<Ş.X:%Æ¯OGn[Ñ#¶DE«æÿªvÄjGÕ¢l:…U22Ü°Î"¤ÇÔUMl­aï ù'ĞÄˆ,OÊĞ_ê›ì—Òx°\¿»åzÍX @ ~±%|Ô˜ÙÏÄsßb¥	îaJm¥§è%GãÕ}ÀQYSÏàÓ$R\>wZ=™z®—&}ˆ;ßÕ‘ä9£Âe6Q·Ï‰©Ş,Ê¦“—jÓ»E`ä šÆºJêÇ›lšO`>p®+MFş]ŞOdÈy¯e?d†g«0c;°jm˜='"µÑk—êÚê1ÈæDË„Şu“ÛŒ|×[0˜–^oÃ¤·÷Æ–¤M‡È+É?™ÛãpågÎ“JLM(±.ßĞz3RÑ»şûå+ÇA‚MO[5{!£ú1üÚ&8ÿ`ç’#°ğÇ¬Õôó®9­÷SêHãé•4qğGšGüÿ<VšäĞ:ÆG¹HÄ•±P9åÅ(vü#Ü².÷¿ˆ²hÖ’3`CJ®jaRåu–ô°<ŒÁÊÓQ™SºÊ}Î)­P;J«ÇÜtí°“ÀCr·0ë8¥§`Ç/ÏèQúÒGÂ)s(¾×¯;	Hj©€OÓºï.—É˜hú	}è‡üxˆº8¥PØL‹É1)œ‚wJR4ŠL¡·‹ôÅĞ6~q¤»/Aİ4MøTØss:µû5ti!”áw¿—+Z|,™ŞêjÌ‡{•¢â~¸1;’~fCeN>>âÕaY‡Í'3ùsÓ7+Ó(v!n¦Ì/¾w…"äÿ}C¨€_Â›Kã‘÷ÇuÒ2<®FñŞ|I²mN÷õ¾7ÃË³eªÈß÷Aí›ã\Ya×}^Í¶ô•Emœ!Úw(?p]æPB»$N6˜5“K~Ç£a-ÌMË'†ëÆÒ–'Ç¾"8Ğì’Ou"˜ºÅñó¶'kãx£=KkÀ«­ÀÍoèn•»%C+?]S&ixöf0	,SVÿÕ9…ù<ÇıÖ­ëö!ÁR)ñÒğµß%Æ¤À$F¿Ñ›û†ñ%öşÛ½§X¨,ı^#sh	İÆ·Ñ@ò]EŸô?f¶pIˆd<PWŠä5v§Íª¯W?Şàõ,ˆQ# ‹/f4ş½ëÖ(šÅÏÔãaâXàÍİõ´E L(
YJ3 ©'dZ›—U&¡…Â·?ª¤G›ùJQU”zåÚÕ]È5·tLX¯-jcš{âr L#€¯˜–gr³#OfÜNÑ¶l6õõŞÑ:ÉSĞW5A²gïâ@mm¡éÏ!;®¬º÷êKèLM'ÍNş_÷¬ıÅn0e"å{½:á.ƒlåkm•dxÙÅ†ƒŸîò
¬
ì`SÄî
"ˆ+H•Ç0¯
ûÓØ²Ñ¬§4É i=ÓÓ'¤¤ğ®¯a·ğÎ:?*>ûªI…ğ¢zöêE®Ê…ğ¬ÚÊå­İO‡¢t%ow`4‰mšóB–0&ªˆˆ^:O;a^EØÃ£æ6³ƒ8T-û>‰7+/tğ¦÷P'"á5Ãh¤”DÏ¡Wb5mób
“f‰iä Ûq[Ki»{¸NæÚª«µg:ÆNg.góĞ£<^n—§N’ŸaŒ˜Î#5^«¾‹ ˜ w‚*ê]$³ÃändZ\çß vD×—r·ÚêšŒÛf²ç -é¼nYìWõ²×s6=ÏjóX “Iá´‘F•;ğÈOhxNDı÷,ÜC®ÖîÄ‚hÜ²Q|¨ìµo¡‘ÖúÒ¨P
Õ?á\)#úGÄ÷Şµ=¼ôƒ—ÏËx8ŞêD6”ö!^ÓË“O<“¤Ú¾¥s»¶X…æš^ğOİj*l²NT(ˆ#wšÙĞïó{84ÕUÃ9¶ÌuÕ8XlÆE·<¿=üê„>§i~X.x-Á"YÙ(ÉéBEÓŠ%Wl§ıãú¦8ÖWßÒÍ3ÓİJ›Ÿ4?³£gº4#\ãk–…C·'ÊñwlúŞyœUiOm,ˆ2·qA°|çJešSÆ™×x²îİ:yK0&?<ğöìâ{Ü—lBQ
N£3)C#“0ú]yâà†[ıÎ¦ë•¾Éoô1o˜3àCûx­+5¤*JæO à¢´‘MÑ²rŒ^ÊQÒ…)ä§àuz6İƒaà%Êw”ï¡İĞU
/?Ğ=Ê¬—HÎ¹Qš‹‘ãw†Ë]és*dÉè¤ªf°ï{¬hL]–tÍ4Ö ®êx_áÊ+¬ºA‚SØ=\Ì‚ö–`íµeœË´Êîî¼Ì ]ØÃGÑ_åiÑ¸ñÓ!	õ—m¥ü‚áµ<ß6ØÜnÊÄhÀÊåwÉıÉ^ «Ş¦¶qìöF•˜ßj]¸äqTôÂúï7¾ÇëÉì™”¥¹¼9Ô®Ì½ß[ø>NKûV4ŸIqóÁ8€¤ëº€œÿÂÏS”„ÙÏÈTli³»3W‰i[šßVJ“FÕfdEû,şh\Øãe1Ñœñ¹‡ií%|³ûkXåHùó ´ş8ˆŠS ËSdémhÑ¡Ìf?a´ùòßÈß‹û¹¼êRôìÍN3ç³­~]VzQ?Â—=¾´ù¬áiã\q‚	ØóÂ€ß7Ft¤°é÷’EÍğY×§ 9Áÿê§SU­«Š;
D±¨j<–w_"Ôª@¿ÀÜÿ¾*Pè¬,öJM-Ã*{Í'¤x¯wqäÔ(~XzÇñÂOaáZ’]t¶uWKœ‚¶‚İÌÁ~Àï…Ú,æiÉ Å9M\ƒˆÎœÚş× +.Îmzû‰Ò‘rÉ”)–¾F—·ÎMkäôO, ñuô03O¡h¶H@ß¶»¢¼ú]	€òòÅ–´wäâJ»K[EÄZ# óoù7àÁ·šïOª™`¨÷ÑÆá‚æ×èùrí7 æOP{ö‚§æSr5¯ux««pó¹=T_yˆMÃ
¸3ĞÏ3ò	Ï?Á˜ÙdÙI„ ºóNÉã[{ºÜ/¢€úl¨¡ƒ46Öş-ZÕ‡ÌW-À•á­ıBj¢‡êÄÛø‚ØñhœÜ­Üiá»31`;¸3ç.HBgn´,kPÙ÷³À%=)†ÑCñ•Õ(˜ŞÕ»´¿0Á'7>u¸JL²îĞ–âÂÛ‚;…ËÕÇrÊÏÎà¨É¾SFñŸ¦É'TL–ÇûM÷ÓeÀ"Gº¤m‚Ï+ÕÌ¬úaö4nÖˆDäoÂß½ØÉ•%ËÀƒíÔIÛy¼{Yì#bŸ5tÃöâ4ÒWÓK†EİQU^†­¢”£k0Ñ_¶h|“YáÁ)’Üg‹m×#/<ír¢©­q@cÍuÊsÿ†ªóïhZ¢—Ùe‡ Y›„3âT_6ª¡Mb&å!âñŞñKv½šDód(;4‡MhŒjV˜.™ÃĞS9„Â6Ì¢cvÙ· ^¼<İØ…ü:8ãPü.†÷Î HUØuÍ™_‘#åAı¾¹4u-•©HPM6ò¸¡vEŠ¯hYk‘ÀeW1És}/1ï™š*±ğRu=x"@VRf¿Û0%ùU‘š–à%à8åÒd~”“n|5 z§%«tÑó¥ZÂ“«qÈ­šiÍ|¹¶{íU’û¥’ì ¨æÄÉfL™"Ç$ÏêÅ0¤C/nkQo«¨Şâÿæ‡ç(Ïó£ussş95í³~eğ”I
*Û-]O†ñŠ’ÄÇU‘Àé¿!tÄ1ÃÑå˜G¬á4r£ğ Ã1ÆLf|€‘I¥œ^R4MJ ‹dĞ!€Í`¶»ú?Å¡[¼Qšåû4áÓay»ï0Ôi=ó–ÅnSé¿1Ù4g¯}³·W
Lx ş5 Eì‰)ı‹˜íÆb Tø‘‡Ïîu5h“†È†4‚4LôÜ Ã¬›…Y`±hã©ÔÇüôÛ‰èyB<îE9GÊCSê­EX…_ sÙQu…ì	–À®šõ€ïÅ÷QÏï­bnN;ñ×]ÁüHŒòïmş¹#îNß‚ÄÜ2Ş tmDÆ”jã-HâWõÒªDéÅc`e+ÌóÑı»ç©‡‡¦DÜ½Ib_ƒÜË]WMk—*â"—ŞšH5Õ¯1YXö$,çZãËeäJ'#Ñ¬„Uä¤>Ü™
Ól™“øH¼¸iëòC›,”<Ç`¾7MîîŸñË&ÛkA
ZzgÕ¡ğÒYÜÁF»Fey©01×fÂ\¬â‘ô"ÇO©KQ(ı£²|Ó qT«ÕæHA¯u’ôÈBh¿ÇØè¦KêµëHÙ:Ãˆ\r{[¡7°doÌÑñ”s}lÓÙ³˜mÑ²(­ÅnÂÕÄk?QƒƒqEÀê`kÇP0ÖÏ$pÕÜnÇôĞ‡X6’RY¯ìÏ%Q€Dï.Ød€X¿fÏS‘P¦T~í…åúT£ëtŒ„÷¼^ªX'zÏ’ÑJÄéÂ3p€Ğ‚¡y]ÿ>nÖUÊéó¢É}3
'‹Šñ²[$Í¢ı~=âd¸6—ó"KªªñÉl¤®Ø‚6šJe*ÕÊİ^•ë¢¬T„Ğ}Äè‘Ä‹”?ú/×e# [q—	îøº¾If:c«ÒÁ–wYf=wµ˜—Ô6äpÙ1GB	›;S ¹7gêJ¤KJÏ%ÌWu{ª×ñrÊ©#I‡ê!o¶“àŞ[3çjEåf§P\©›æaònmÄ>ù\$‚Û´=Ó†767*¡"ávø¹|dàğw½ß¾ì@ıT
şˆÈ™ïígå‹%åÔ%†oZ/yˆè}ø’§Wu{6i-Š‘‘i9,á,EKü¿0š½ÈÑ|3ª‡÷ğ2„îôòÇ±²Ô@¯öºÚòŸ‚•Wo„×9r‚f³Æ@j$:]*9h7}Ïvñê»sÔ89„Ö'¯X$UÛHéBãìz´M’§µMD†^ÏE_”upß™&‰ìÒYZÌóÆššßSbÉ˜–­A×Nå§.Ô»µ¤leÿìõùøçcµ‹G]Ójà¤S„‡1£Ò*ƒ«³E2nÆŸÔzm(Øa{©wZN3íL˜`Z¯ Æ‚Èa0È96ÑµßşİÜœzµ¦¹$ñG`çİ¹Åo.6Áº~L2¦š ê`L“W^læ³ô=Öiè»T…‡³ºVA£(Œz_ü®õLg§ujHÚHmºæ&wP‘… F82Æ5çzÿù×KFÈV¬éĞ|cÊ_¯ò’¼oètHïå±–r8;P5(£R¢ßó[Š)’%†-z^gäeéÀf&¿¥ÚÏQ=_—qëGŸqu¡A±%ààøÄW|ğ`[É]¡™ÉÖ’õxu°A,ô
¡î§ƒŸB6`‚¢VSÜfà1Ã÷XY0‘6ú’Q%êø@“İ€hù‹5z-R,'¦°ma)ÃÌ©“	VâXœ•Ê/48»äŸú^÷³¡¢«cú­eû²P­ÊZ<ïÔP³ÜôFïòœªË!²Ê½î¢#ÆÆ,I¥»cç€•Ôšú?TEc0ûºS‹˜e£±„Ób¹&6¶ÀÊÉšÆs\i™cá™¶}ˆÁLßq¼\LkÚe‘ómPeÆĞìÛK^R=¥¦Qê-®Çm‚çW³ä~ œœPvW>Â˜¿ñËÁ¼ÀX‡—ŒQŞÌ{áÀ¨i0´÷ PòÃÖ½ôˆ‘Z›ƒFÛŞØÌ|ÃL%‚RTò•ë»Ú‡ceügõÚËu–IÆ‘.+-'-|† u^ù=uÄMta—[g`êˆàVD€!kKUòÓÜê¶ßAèæä^âI; ”äšöœ`æNÇE^$œMŞeŒæÌŸ7\æF±z;†¡ãßN¬é£lÂ•„’4¶/Ò³¢¾ú…Ÿş’WLqX³•à;[±£Ël'5²be6›J¼~Ø!/€qˆ"nzG[íÙü÷g -Et¾I«k0è}÷@%¤5BŞPC 6dã»† — „›3½Lÿzúü!lªÏ÷ êÇC‘ó[u’M C°·<s¾ÿäPjWTØ]‚sË
ok·Ş¼ë¾•\g5<ñé¼|$ƒãÍ²¹6,-.ÿ X›Ú+ÇLÓ¡_ÌÒŒ:4(|î˜˜­ÖîæÍëyƒ@œ»†¶ç“¿ßãxÆ!SûøÓy&ÙrÎ«:¹Ÿ¡èÂ`¬‘ZÄµÕÍè Ú+’™{ºå-¶õ˜ŠØZC¨'šxP²’Æ¶úÈê7Îá–†Î[¸]s¬¤„ræéı¨g£¿ëˆ0±¥örÃÛ¡Gá‡áÛÇW.ù·•ı…p6	­ÂB3&Ïèk{—O<ÇâÉ=˜²> Êyt~ëËÁåUD²ÄûüÁV+€«¹G5RÈ÷Å6ÚVƒÜûÆ€˜º¥‹ğÌšİyÂş{ö|T±Ë‹£4ÚèÇ% õáZ´îIqlèû„)å¸%ã‘<ˆøî“râÕàÕ…ÆºÑ#}RÏ¶6ÁYÍŸ.AÏvŠå2ó+¸&Z$÷'¤ŸòÖšöä¿’­ø€á¥sÕŞç=áÅ|)9<C¨IøÂŠ:/©Æ Ğ2åğ$cpÑÏì’TpYÃŒ| ëp›Dã÷2èãºÓ…—LIü?İ5"XàgC"5„]À¬Şpÿ¼%÷.VÇN;~úD¤‰<¶`J;ÚåXµi¥eR3ò³R2Øİ±KÍÏ1–ú`Á¶KÁVìŒµÄÀ7ÀrÚ&"7k/æn³%	5Á¤×€›Ï$`1€¹³ÁdŸëş\T,j	bí±'äQÊ5ÁËoc#g‹ú›pº(v°˜ğ2¦…1/˜Mg~	ÿ‡q¥iÕC¬°\É*äê ºµM»~No»œ„ï’ChNq}ñıš‘?Â›èH7s«nX©¬4ö†9?_¹!Á™ÕQ¼Õ™†Ú%RPl4Ç¶°tŸº0V¼2©:¡Ø”†SY~ê5ÿ’À«'„4|ç@pì…:¶Ì'f"÷­	6¯-¨áàšÉš,`Ö·!Š¢1©…•"qçbŸZø£¹ÊŞ¿€cbB–'s U›Ú^" û£¹,+-`ŒYŞwicVõÀVœASC¸<R=ÆÉšZ­¬” §¦r‹¾¹²b:voÒ,eLıßRÖÇ>×Œ­?/Xqšw;Êç‰EÇÏ2™²Ú3ö§¿Åïx¦P4ÑÈö™PbÕ‹•Püh6·5 JqÃ-aı¦õË°*ËJÃyÈª‚°Oîù1ñ8]Ë{‰RÉÓb!”íCüõC–v8t•@rRÌ¹4^Å‹ëõÏäYX*#r/íUŠ¾p‘É[?TÊá N‘'d~öç€”
œôj%7ĞtQw·-ê}“‚Á±Y.ĞtDEsÍE¨de›Å¸ótCtÓã@ûÚÔ€˜kypQ«ëõ÷)—ˆÉ×•r'ê`òğ^&	³‰f[­ˆ%­ß9®c+‚wgBD%TlEUNãqlç‹ç‚MZt}{{`ì+¿zô4…VŒë0¹¹·|=ªxÀÅ”ü:u¸z§„8ÁÆ%J£ÆÒl1‡#ÿS¥ÁÅİùsS2Å­İ¿·†ÉFc¥?!$Ï²ä%¼Ğ_\îKdæVîË³M;x>i1¬  gÙ|štÏñíKÒÕÔ³tÛ7d„'€Ç;9’¼áOe•Õ)xÜO!réß J•Z{<<
ÿäI{…ŸËPÈÆ´ìƒ|@QÍ1ØijTaùò{5:æ³‘xo¾ÅçY´&\Áú)HÆ­ÂKòT]ªZÅköEƒR¯y¯lÚß-çâ'M	V
^.U$hJHÑo7'µY R†]aßæÛ;‡<9}UÜA¬÷¬(ÆZâ2ã˜½Ğ­/ÂQo§tT<Ğä†TÌDƒ;©#]âj0öS"êç+¸
^¦œ•ŞÓ®ñó‰…ê÷õÛ„‚)2—»^ZB9Ü„â­²ÛZ8DšR0MJâU”­g‰Â¤–;ï0ÁŸEåW ¤ã§9ÀÎR¯Ï¤ó® 5 Ş9“ yõ|±¾5åÜxN5”ø
ğªÖ1U$´å•Ÿ«º‚QëlLøP™TÜl‘*m¬‡¯(l÷ì9ùtÍºw9>ïô[uKÏ"h~*ë{ålˆ²–\ûé×ƒÊûE­!ç~ÕPg…N±gq­›;6Î­p8gÛkpJ÷Hp>Ks§æ«B3Á­ªÒîÃ$ƒ˜órVÈÛ64âî¾µªLÏÏDd¥9/R`•t[uvª ³7Öµj/¼ã-qÓû¦q¾÷õX=ß«
zGuôÖV`ˆ?nL|e÷èÓ_sq…×ˆi1ÍË:m£´ò&È’AßÁƒñ§=³ôşàw8y‡›\²‹x¨ˆß1`ïUéz×¡»ğ…Aş„9p!Šy¢[ÍUê£mwÂÉşSCúXÓàñÂ‹N•BØÂŒÖALSĞ…FúŞ¨
„bC½˜ÌsŒã«"†wÓ“;*İƒgºü÷—›JPğß©ì­zÜ–àøº,íGšÌ5Cöšú´aŞãŸ|ÿK_&rXú#§‹şL¢}Œ±_Å“„Û·TÖììI{œÎ@ÚD¿‹·>J29ÜÈc-ã˜\íIí¸	•¥¡²åa;rÊƒWšZâı 1œw±.Ğ‘Í:“Í’í¤k³µ(¸#½¨¨9ex1C¢ÀºİÌ­	õSyÈ]œ¤5½ 7kğå~"d ûHï;]f@¾rÒh=j½4-È±Ê.™×´¤ÿ˜Õ!EÙç¥–—t«k–zóc†°Ñé\ãàw!°€2˜ÑpvÚ‡Èå 
8—â‘é÷ãB²P=N^Êöø•GÍ!ÆÏÿÄm6g‰À5şº¾éªäD\»È…K0&*Ê,5Aì®ùõ–ëµîcÿL~éß/ŠÃ‡n{æ8òHFfÄäoR†-rïÉT$t•ĞŒq|ïü[£S
œ S–TU_’‡Œ¶x2Ô\®‹Û¨ª02Ù32H6~ûm/áI’	û¤T.A¶÷@µ|m^cFåqÛ¾ÜrÙ“/ôõÒ9x¥5äi*¦ö\[ŒÚCôğÉèR°ZP¦ıRbƒ©Ì8v
<5ğEnZåİÿmFÖ~ó¬ÿ#O™ ¯A~ö¡šL×C%zs#ŒC…¾ıÖrğÒ×øE¿6ü”İîeØÀ¬µT¨Aô3qkÇGXTÕ³0n•ºĞ÷zôC²—m×R-1ÀX7"â5¸Mà3¸ƒ«SÕRŠhİÊ9ÍÂ§`f*ù_ÁÀ=„–k.@`é\ıÓy5mÆK v÷î¦|³Œ„ËœÑ4˜Vï!á´¸{ÌgØ³{BÌzò ßÈ:DÏaD—° ¿Mf¯ˆºLişßØgN&hn7s†R£jÆEÜZÙ
o[Œëì‡ÔõUŠ&"õÎ9÷âïFfÿ-á -œ©[ßÉöÙ#TØyÑ÷Ü±jt„!ö†/ÇµJ
TÔÖ”œj]—-	V|2Ùoë‡>~m£ÀIÌLÅ¨$„€psƒ_á,Ñ“‡Ä(ô!?wò`¥9]~äò.N”ânÉ»1ßõ5OXÄèx°ÆHİ>Å'ª'Ÿ¹¿åù^`±¯ªÕŸwÇØÜ	Á,¢²YiAû¾œYşš9/8‚#^Õê:å:ŸlÇñŸ6ˆÀY«q´™dÃ
wn¥ËÀ	 ;[kÕâ+F¾¡KA{ÆWoŒWÃæc*}e;ş.PÚ¿Ïœ*Ï7æhí¯¦vURõ©H£şĞÒ BpÂ\NÉ}kê>³‡OŠ©‚õËÉœ~èw4×‰´¤(ƒ>NãáÏiIjì9F¸'vÔÎüLyµ¸¶¢N¥…õ©³rái	±\mD®¾‹ŞÊ¼³² FÌ(»Gm\7ñxÛËUl…Œ"“Ë]«y}6D"–“}¬’új˜öaó¥¥h¨•»ñş"¯4¹,«ÉÏŸçjÔXêrÚ	Jj	¤Ò±Òxd3ÆsG­5ÔÊĞ’ósGAozL´ª:ÀqíËÒÓ%…WB–GÜ_¤Å¦…¤Bëí™-T÷9P¸â16Ô@½¸t†Ñí'ıF‚s8ª/Sîmz&Ö(È È'R8[3ª3°ñ·Æi-3ÄÄ— dã—ó[÷D”s”A§gQGKöì®xÑ}ŒÂ›I×ô˜’ê¸ÈôIµÜZáŸX‡¥­àÓ†*yÎï4ß }çö?³JÔP£Çlk¥ıÎûhÍÄñšğBØnøÏ_jÏØ˜­ëIû# Û[¦šh‰€Ï·‡[œDªJÒaoå~ÈLÍØków¨Ø	¤|œXûêWçz3ür«‰W5¢£öfÁU#Í¹ò©°½ÿaw¨ËÌ}J®³Ÿàieùêß¥_öW€É’€«Âc_îé0	=ÊE?ğ£’ÑÁI7ÚïğX•h8xI' Ç$NÔg¹Ì#èú¤ø˜y°û‡³‡28YÎóõ_·«D8­¯"/zì*@œSØk'|­¶Ş¤º‹<¼”£sáOQÏœ0Ã>Ö=¨ì
âĞã$ÕéAøgÌ±ırŸ!½kÌË"!è)É7sL) ²KúhÇ<ÂSá:„¸Ğ¾7cÂSù“¦Ú«aÌÑåj¥+Ì·h{Ëİ}%ÒÅ‰
µ£xë'­°iÍpcù¸JªÆÌn†Lw3°×b‚=Ò»éV-¸ıõ~nÕ³^cÔâ²Øa`Ü¨®{›ß@åG¦EBË¸½&ÚÄƒa¶Æ
Òãœäº"şşQW. üdrÓ¢` –ëÛÍ”½.Ø—6F¼Õ¼D¿‹•‹ù‚>Áİá·é\Ú¸lŸî:Ik--ík’h]™±ÿl.6¼^²û±Š¦†l=`üãz˜ä*ğ­Ÿ–Iª5ŞG¿}‡/„Õ¹†`#ğ»ò‹4c5Fèş»&Ó5dN°¹X¨/° ²N;\áz2Ö:>Ì*é]ä‰Ìmµ|NT¨âwv8Âç	“ôÚK:
<+ZZ~“8*w³?_¢…ğ	Ë|*z$É"ˆb²5Mbün*r„€Û@%%ƒåz¹dˆÙ#²ìzYöAOœÙ®m¥7OgÖ†´¦~Ê`\sæ£Ôğ‡ÃL9¤W·g_Xvß¡ [Áv$£Pf~^{j7{"W¹Ù%ÊB¹gì·Ëïõ2ıOåÇ¶T1wwQÜÁ_wˆ³FgÛU®´W»ß;/‚p*ªñM²áÔ¯(ycÁuLŸ¨¯G“4Ç£\K´ˆG¾ÚÃJb[jrÄŒÕr³©#o`èófã˜ş½m7êB’3i«G)H…gç¨µæBh¹‚;·¨t#ÂÍÏv‡i˜kñZåRsş°Ía+‘RiÓøk*Pk LvûÇA^LÉÏ¹µg_Ñ+.tµí»+ºjÃ  ´Ù–n,!„òßi…¶ÚíÎ\ûŞO	Ğ#¥æÏæi§pÅŒ"ƒ(a©ÎµnÖjœl´åYgÉ†[°ÿ[nÉi´íÁC1QF”‰ó9ü0zòê&Õ²ê	IÒ¼Ûí8pcdÚ7œ[Ë´¦QÛ¾‚tĞM”~~ı×²'ÍÄÕõjùÔé¶™Æ¶[ÎÑ½ª–ä×ôiĞÿ@Ea59X½õ]ä‡@­õ`zÅ`|ï]ˆ-
ÆÔ7<¥¨‘8?’R?%Èq#t’`²È¿¦}ÃÕËg¡à¥«­¹×5`C1óöoznRU£¦nJë6†ó¿áUOGÚî~6áCG<T—ÿ›'*ôgşè%sä|~y:M÷ÏÖ¤ËM†ùÅKR­íÂËJVßV‚°P„&‹ÀÏø¬db˜qqd7¤¯î8æ™m@hBÚ\ pTu‰#‡…ïLd›'¾ëb	o¬õ»›E>O©,&qCB3î)ifa©¯¬¶eO[“#ÛHË{
f'|Õ¦˜«1{¡.3°c&õ³¡Ë0dEˆ×ĞyÍ-×I§ëŞVçO™Lù¼5¾WŒ9"Èõ{Ôœ‡-®
Ã( H,æ„'°¿ªXÜºù³
–·JqåÏÔPı¥ÜzÜÅöˆR	œ›iRnEËg§_Á’Ï²‹ïª¢·¡Ì1ö§gäIYå«»ıçŞ¯¥P}/TÜr{j¨O…ë(è)ôÊ`€Á5µ(X^j—èNL`*"ÇA9|…áDW=;1‡Vhæá’s'–ŒDSìYºğô†^È#æ¼ğ]Ä2H6N™:!’yJˆ_¤ÌqÈS—íQÔ<ôá­Æï‘YcÖÚ¬TÎÅPíÎ|§nÌ‡0ÓÿzÌ¿ %‹ÏÈ?şïp‹ãÚ—ü'ºwÙt=U!V‹°ÑrÂ¢Ô;¿ğ^,¨]r¿Ş{ËÉR«ŒtÃË)µè¼åULVà‰>¹ºïT;	Z­şcfÊå­á!0ûº¼Fƒ½dğOXÃHs´¨²Ø3„ĞkÅüûƒ¸†ğC|ËBÚhÁ‰e&®{MÙ£—Oå‘ĞĞÈ±T;¦Õ|Ğ!È…v@Â0(¢ùdÀv6Kv¥•¯	Ÿå<şÄâ˜¥3¸÷q$İ)©å¯Ï.P›ok“óDDúÂwˆIƒï	%ÃËLc”SU›AÓ†#Y3÷>0öà•Â’•i²X¡ñÙ"@?„@èZ’còšíà¿&O^ŒeQà˜¶î©kJè½r5©İGşÇ£LÿÿË~p",“jyşó¡ß[U&ÕË+˜y²Ô1¯å" “áÎhNÜ6üì<AËØòÒ“m”R”ñì!¾›á™`ŒÓ;2Jã}yvÑûi‹œıºİƒÇÌÂvŸ'¹§s8 ªoùG“¥?(èÁãº²k'6â‹şv‰:²t V¡µyñ6¿äŸ-àZ1ú°5~UËe‹t÷Ş	Ô“z­ÿÉÏ°ÜÌÅS_â¼ô1·`ƒYÁ¯%Eƒ¥8WÃáŒa	œ7·#öşüh€/°‚¯ésE @„$ä¢ÛãíæÕÍ¾¡€Á‰ê%}G·=@<5zİ’ÙB÷ü‰_Â±2/èÚŠ€ü\C^¼é‰
'éº}º8½õë!R‡Ç¢ô°ZfZL(?KğšÙÌ“ë’OÔ˜¨A”#ğâªy;œö¨„ù âáF©6qÏ&ıMòb¿3Ës$(¿›Ÿÿ‹({JAÚÃ¼ˆ Îµ{»Œ ¿àš‘ÈóÂíÎ;›@ØÜ|yYÊüâs6qeÎ˜2XŠIj3HÚ²A£™ğ"Yr1´·i<ş£“>ğÕÈ¬ñÈxY,³‰Éí¸…Ê«<÷©üAV®Æô‘Aä¨â´NU¦ÊÔ	îĞÂ“ü}Ti<«ÔHÁ³Å˜¨‘¦zIÌaÿ0lÚì°øtLámË‰<Ÿ)0¼?k ,lÌ'¸x,Âş! Ş:Ø~eóßVõ¶ŞÛ*û5Gœ%Ù6ß3ñš?0	?ÎˆIãz¹æ›”Ë=ĞC•™Ÿ(›.3YØ©?yÏt ©$ÆÊIô"P¸¢†>÷O–åLö4·­êíâŒ¹RVé	ç¡ê‡hit,ØÒ€—ÃÔrß¤s»àÛpw’ ğnYª
—l×á&¨,ÓaÓ@”9#‘6Wú	Ì`;9aÏ‹Ä²•ò.’Í,} P•ß.üî XhòÍàËm^²'T(¦H²%òdëÑ;˜ßŒÎ·Hz±:a ~€ÃŠº ²=ó´Ä ¿
[vÎ¤Å|îˆ•É¸‚ïjo”c[±·f/NJJz%ˆÛèâ×úày1i+æµÉ–Q rÕÑŸµ(Úÿ`2ìKè\†’Î_˜åd‚…÷Rô~â­h6X”ÿË46CF²b“ğA‰Og±)e·’ û'GÏY-”^Õp!êd¤ÍW5ª‡²l¸(çwµ¯´ÎTş¿á7ycÊ2Úº“hTtÓo _ù ¤SÇô2úõßóQ^Mvµ;(s1Îˆd/&R–oÿy„ )t2Ñ&àC†¹¾qöë‡M¢ä$·®¹}ö¦¡]É9Ïn]ä"Â–¶[wH±Oâd‹=çDÄšE:M%r„T·},eÁı­LE±qyÔŸ”Ğ•gÄ^yŸ‹ip/‹“¦°\ûÚçg/l¶´²ŒaûVYüÂÓjèKú]éÔ²ûÀ ­`"6ÜÂ‰©ÉÎåt¹Ãû{$62¦<zÄûĞÁëß
ATÙ4éJ”H%LÂl¨QÔ›$ §nÊùİzh^F°güÙ`wx™ôÙÈPM{º(9ãÌG›_KÚg²IO@ßPŸRnPŒVôä’¾s¤âÌ8k’9ê“'<“h`Tës– VGMg
Ta±èwcÈÛ/
(ÑALE˜ÆÏcP`±pÜÆ÷ë¨%&·’ø¶ÛNÌ„
¶[ÏîÍ†ufHtwFÿÚ‰#2èzHy@;´÷ªEAĞ”Ím^ÛHÖ!ãìf¸ÎÎ5¾·õÀûrWføI|€å'Ùé¶Gê/)|úK¼¬ˆ†/Ey~<(!VÂƒ´T	uOSVŒ%ez´ğó¿}o¶Ó	W¹J,=@P*fÉ*6ˆ÷hÇ56¬ƒšbdQŸ*]Ë+)hÄÏ+C}§¹8æd„¤O[Ø¸.u'³9À<*ùÊ-ñÏ¡÷S{ë?Y–
B8àOXÓ‡b³}¹eDÈ4õR‚“aKúFèË‡§j•¶o3P#àê£}9¬ù¤diÕ×ÌìÑ“¬1Ë·vöRæ²rßˆĞ‘õ“uDŒÃ²cM*àÇ_oe«’Æ›Wˆ@áÖ1‚»Ö²ò_ğÏ­Ö°ãÎyC·#¸VÙırg¡Ü?ğİÖ5¢ùìrµæô†wû9r±>—c`c²8ÛÓxBæìÛVDÜw6 úô¹%”À–¦á<‹0qxì}ÊnˆE¾j oc™ğíî3T­á¾ ¸{«•0¦(‡úFÀÊ~¡ õdHY<{&Ê2¢‚R RtRNC¯{Î\í}*š¯†Wß¦ˆÅ£ÇÊÈ¶÷K”¯„àZ^Tì9«!u€nÿ> `èz®ñ¾	|ŸdmçhóÇÂb¤QAÿZPó÷?]?H(mû²_I3ı“&smı$a@§÷‰J•ÉùÒb¬AÁ±^^€²hÀ¨IáÅ%t¸iœÒ]è0÷CFö²Ä…ı^jW/bá”È'ı.Ñ¬¯Ke+5Ãd~fàwÖ‚JQ©?—ßıNIâşéDu_tåÎ¢Ôw|ŸÈÎ7$İË¼W#ŸXîİqÉ®ĞcM_­uzRÖ#¸)¶ÜÙ¸ÜyRÇ7L˜İ_æ¼|r‡Ì7È‹
.¸$Ö5¨£³cVm–ÙW”ì× ûÎXRR7ÚTPŒàw
e#cî9$uˆğg4f‰`uæUËÄ&Mõ°mIg2vr²¯àßàâ½v~ØYŞ
çI(ìçDH<T›£AÇA6&	#–oÜz´H¶upÅp¹‘ˆÌ @`Z}>7%ñOó„"3’oªš$HÅRTTó°Û‰ÅO2–o¿”GÅ*ö¶£5îÚ¥$Ú¹mì	‰µª`ñ]œè]GÊâ$å.e°S‚X=éî?½ï­ÜÑÁ?tCÕÏÚ‘¤‰ÓÌ017ÚÊõÜ’b¶eÌH8@:ãÃ‘Í¸OßÒù"cÑI¥ö\Ü‡uÆÌÎø(\ÂaÒÅú¢”bß7Ï|	Ç§zóÌ…áG:İ‰¹ÒHÖª^¶¿¤‘Ø/=,»ìUÈeK¥—~ûXƒYsa[ìæ›ÜÎ‘A İãM9>]-‚·—à™ÛóêŞ×"ğ8m8``‡-\¡L&-Ğïl
Y¶rXéT2&êD‡ÙØü­Ü©0×}Æ·a&Li^©¦&¨æğÜwËsÖl}>á’®¯! s0Nj[ê”á|«©’½w(BkÒî ÃcƒÿzÚc×˜0”ÕÊ"ç›à©ÿÍâ¬é²GçÜ‚NÑU^J"e†
	,ãFw¿î;Ô®á+Ä÷^é£DR´ğàcÃ[Ç´3_%í¤:’ßÂ]¤ò×ş6=KõoÄ)"[ËWñÓ Ø?¹Šîdõ:;İ#I=Ê=÷ÿi{ØÜ
Ó ~;iãÓíâ».šĞ¿ê=ÎPJä;rœº§¨ïÕHå€M“´ãkÃóÛ’I"(=Æ¦Å_$Ù3+"}*ˆFPÙñ—¡Â.irQ@×R_<İyÀ®ÎŞÎ†8Œ3Æ'zSœ³tèí®‹ñÅHd½Š~´†:0Ozaäâ†gMègP mU¥À ùş½ñ”|•æÌ#U‡W§$¦Œm0ÃRaÁE»$¬M>J½z?DëzĞ~.ŒjõDé—ÑbùM?fJOA?*ülš‰ÀÔ)İÔ_OICe7÷œ{…Ã¦#à¤ïº•!càˆõÅ¨ÎôíÒ‰I’^Y´¹[òP=Îq@aï>g“FtŞ5Ê–¿e·$W[Í:4Ø’iÜæ6ı[ÎŞGÓnÙ±f7cú÷uj·zPÂ(Aò6É@~T>;Æ"ÌÚ?-zPv¯N3k+F»Yõ^ıØ ­ÃÎªó¥=&FÁD zĞ1•ÿ	 OŠ?~¶ÈÉ´yÅÓ—F.*Y7çmÈ.›Š”KTc¢`kIú[§#f¤d<ù&UòÚ]6ôérsŸ¾…\ZÕd[JDMßnöâÊt¯şĞù¾¼(a—o\}>G
ÑŒˆtcğ¾§å:;DÛBÜôÔ¤AË§@fÖ¦Fß±Õ0Øk²~äv[còDåıéÃÙ£•ãÈéÓ¹¸)Å±-a¢ŸDò¬&Loˆ·ãÕ±aÕWÌdW¾n4š1§„%@ºÔü§y¥ğ{A_¦|£¯İÜŒşÀˆù3I’ÙÛ-òŞô4ıÑÿÏüØgŒìÎ«J§8ÏäKY°êh|gRh[Àë ‘«k¡5<EÊ¿—EÓÓyğlD)4È@ç÷æ@c[^¨i¼2ÊØŞ±—j\Åq‡lÆ¡¹“KŒê6`,D
¥
†Mp¹õEÓ@»úVîdiY;ùtZ½¤ÃÄ¢Ğó¶Íÿ:ú©‹¦)Ûk™˜¦aT÷¡.ÓœQÙ?6ğâ±íÿ|©ü4pú}Œ¿CúÈóK¹ğv‘˜sÂÎ®§uè‘ôxhzƒv“%œ«F›ó6Í¹Ü§xò•Pu€’¸˜6ŸAKw{3wr—X¸T)*«Ôù\q÷—ùÊomı­.‡FÚ¨r¼İ©!L8ƒY¡¥`¾àFãË
'îùïè‘è=tª	nPZóÏËg]Õ¶hÀõcÑÉT÷æ	ÿ‘“9bÿRb’šı‚İù_4¸×orœØ’’#øtôyùÁ±È‹“şc©¯z…Ìáú¦’²Š%Ôq–ìûw«ë)*h>AëT"ı#‘èĞtkè–rü¾Éñ2â-b8ÖŒH»uóv™~óbbÚ‡‚ EŠ ü^cT7*y=­('Ò¯E&Y¸´ûñ¼ÉŒ¹~¾WØø3^˜éF>Ò«^œ?b¾ü³•{«P–7ş,Ç:Ò¬¼(bT´pä…xÇ²”¾·©!/Ö’Gç5Ÿ¤'è&fc²ìH/	Á•Š=œ¤şKDF%¶5Èb(#ƒÂ£®A8€İZ‰¨9Xæ‹©´¿µ" 6Üøv©§ ‚5ÇDv¯ƒ·Ls1Ä´è2×É/œ@µQce©–UyüÈÕŒH;dï‡GùpÀ­6´3H›Õ¸X²¦^\'ÖÇå·ÁqÙµ|¨è~ßÿ9%À[ûFÓ6­t0B{#ôD‡ÜVÇÂad'ISIÜÜZŠ?î«4øhZÊ[+LÔ)J0ˆ\ÔhÎõïÚCauüÂ¨4;ÈïC·VKÆÃ!V( Çğ‰àò@F:UÇÍôÕÓŒ¬^n3ÙÊCbà¢t\D WtØÆx€kĞ¯Šˆë=XÆ-Iı­ôxYkO ’djDˆNfJğ‘‰øZ)›ÈĞU>PN!dB7çà¤†ƒÚTv5<4t.|æŞú¸†C÷çëÅ¾)w¿#j5ãï AR¬¤”¨Û¸B¼ßzô·ÜztÉDrR^}++>p|¤´ôïÙÚ6úš#ó›/ÅÎ‰ºCã9Æwïš±ôJŸIÌàU0î¨¶¼TgA¶ïT‡}QG²Íj'Ü	pYê¢÷ƒš®m“£©D¿EE5Ïõ	 áe˜“È„DÂSò÷Šj¯o: v¿ÊŸ\·Ú‡Y‚Üín
®¬2âäÀZ²­	*ëdšËvx—é	`’…%ïé%aH?˜>âpCÊGê}Éæ\+³»]ç%ÖÌ6lì¾DŸĞŠ{Î?}Pß'ËsR¬ÎWm‰À™A^ÓvI$YEja<Úª†/¥ë‹KÁå7ğFÑí×À€™‚zåb®{<6cG{öÌà´šù¨¶·ZĞ¶Œê¿“Ÿ¿nûehg ä”Ö_;±t›‰¤Òé[6Ç‚§…À2-ÓlêşukıóÀénóOTmÁ¥œëLSUL&äÍõTô‚ÊŞ®Ó|3€yc‡ª~ç¶:mµ©¬Šü·´û&ÉòV{Ã–YÏ|E'~§ÅÙÛ¦Û÷6€ˆåSzŸ¯¿73‹Ÿ·9ßŠ>EØšdc&^á 3×‡f&Ÿ–qÖàU¿)üğ©„Ó5UÒ»Ù¬&€!'œ85]kjÿÛŞnã¿Ô1h\±“ÈˆXûí°zª@ŞşäÆè^²hDQ U}§M†òR(XÔÕ«bï<"#ÃØü#ßùÄ¯<àşãŸítUmUÁ–6ä·»™ùp°şN’”6fº:¥°?ôÄ‚°>¼ûçdå¾ùÃSr½Ãb>¹™v†ïúíÀH®bHÛ†È…ÆÔúæwè¹‰»fZ¢aúæµhû<„`FdàôÆN‚®\!²~”ÅT½G~@RÁ„ËåZeJj«ÉŞ¼¸¤îÚ,·ş'¨r³¨ÖŒÊÌ3èZ'ê¯ªSQÁí$Thcu¥ğb b£EŞ‰T¤ç¡yŒ;a)‰\ûIb'â½eŞZëËJãİõˆN Íà\dıìÚíNWğ]©Ÿz!—cóxĞïÿ,MÛ?Ôá¼›öM´¸@b¤.|£Âd>ë0¶L‡@ª ?äJ Ï:ÀêZ,ú Ñ&65ÎoÊQ÷©jGw‚cA®ÎsNU Ûˆ›XĞzÅc‡¼û}ßÆ¨%ÙŸOæKŞË‡<g¥Y	wHkÊ›Î(gî/G„W1™Ù“Â*¹G€ŞõgøYÙÊ“±ïê%fW›„ü÷Î©&+fòo—<'0aÖÊøpF­	á_"8‘ÿ}]ø+Š¸É¿@wSEÉ]†M7¢Ş{ÊëÿxğƒÖ³}~R·OĞ‰\£
‘Š°võ_¾¢È~ÚÚ4“»·éz‚Iü£~&zZsÒ«Ä]¤9õaÑs0˜Ö'úv¨QÒÔ¾„åYl N
ıSKÈ• 9ÅHÎˆhs05cÉ5§¼	:´ÍïÀi:™9fïMaıØMµ7CzAs)L.şu¤¥ğ±Œ´Ñók8¤$§FdW’ƒYdâÁÙ>X6v8,!ö‰ó¿|)<³jsn	_={mƒÊtw¦Á÷xÉ’…äšZ`~H;º'r£ÅHOë”>Q5ftø#ÿÍ|Á‘[èŠX“šÕåƒùË„…­=]Å¹Tv±?'§"·À|'Æ`%÷‰İÂp0LH[Jè¤1¬şÙS´p_Å…ÃÂHuÄé=K„øòŸ’‚^âÁJµo÷Ÿ‹Š)*ÉÒd-¸Á¹zÑÔÈfOŞU¼à¿|H˜c´.-
1š	f0/v›g¶)HûD<›Ô\r%Oñ Vµ.3xæ[Æx'îO&ŞÙÎà›û"!QœéÑ®z‰TöGôÔ5¤`pñiB_& ŒÙ0ğœnËPğ£hÖ§îĞ·Ö[(‚4H\¶,
â©Î	O"õÚ˜!Ø÷&àÊ`å¥øeûS7`	ÀDäe…«Hn¡Õœ¸"ùà´$AÿFb¨32¼ÍÍU·ı•v2$sÌÀ·sf`uJ¶Œ0Å¹ôêk:§NøSa»E-ZQ9,ˆ•`Øª|j,ây¨²jöB14lRËW'ëÊ¸'p¼›ƒãqY‹–°1VòóÊ\ÏÉiNŠJ‘ u”±ã¬¼‹Ü¼|í=.à_˜ˆ=’ßP0òèQ¥· HÆ”ÒÕSR¥ZG?2¬SòÃC2'úš,ñ"¹g#¤ÒÊsN§KNï…Û¶µÈEµQ$µº³r ubÚD¦"ıM‚n¶Uú?	ìaŞØ6¸5œÏdC]a²M_ğÔÇV¥Î¤eí4XŞAU-EqıéqÛĞx´b¾ÈÙ§½¯|f	÷zkKZ¨(qTËU¤‡éHë¤íÚæntÛé$D³n€eÚ»_×ş5&Ë'	‰{š'»CËé_–<vòüˆr5:ÓR³¾~ŸxŠ÷®D9”.h^™ÙtøH €6èÀšºƒÈøûK­7x±Ê£ÌFuù>9LDÇ±·Í¡vÎÀQ[Î+{YŒ·°`Ÿ=.¢8Şıˆ‡N)Å™ìeÆ3Å¥MÄ—r9p­à>b©f¢İY„gäìşHø\ÁpI”y`nÜînóD9Çj³Ğº0Û­ºa¸,?2™ï˜kLófàÔlÛâ´ü;Â'hõPÑdeZc¼Ö=`‡”Â­™M‚Vï+˜R”˜›mPûféMrü¦ô@oOKü£ËëNäÈ˜\¼µÃ“ ‡akL¡ '»-¯(•-/9hv‹õt7b}Óµ’×EÀIeyİ?GuËD¸rìjYhc¡
ÚFü®¥43FÛ¼ÙLf‚°áøºw›qÎ#cJ1À´1	ğè™›˜€Èók§¹=Iã½ægmn¨œ»­±?Æ6MØ Ø’­ç­¼²p—¾J6í>IX±€£ÙØ‡ŸL™ìd´Ñ$„ŠÌ·aJ˜h‰u7gj¶¬¡v —­“í‡dÕÖ`=ù9È™J) ØP% sE†ÒP%~â-™Òÿ\–ëjÀƒAÈáÎ½ ?¹ÎÉ”ÉAXõĞ‡F¨PÆ…ZË·J¹çÆç†6óÍ³,~ä7µ…ø·²kù|œÀ˜YÕ £†¢@¤­^»Ğcløj##Fü±ÊìŸ¸¶”»~b
G`Ré(ˆ[cE@¼?Ìg˜r*.M>ÃwRâm•GÆèû ¯+¿eç½3‡ÏïàÙ×ÆÓH>ºÌö*ŸiÛ`µˆ PÎ¤Üú‚ g'´.°–<ÉBàúş“$Ş‰Õf¶›-[­sås     Ğ?Î“2 ÙÉ€]mr4±Ägû    YZ