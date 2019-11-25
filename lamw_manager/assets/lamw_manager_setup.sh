#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2572347823"
MD5="4cab9cedb432f1258b19b85d56cc3a74"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20580"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Mon Nov 25 19:10:44 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=124
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ dQÜ]ì<ívÛ6²ù+>J©'qZŠ’c;­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»7úa‰À`0Ì7@×õŸıÓ€ÏÓímün>İnÈßÉçAóÉöÎÓÆvc{këA£ÙØ|Òx@¶|OÄB3 äeºîÕ-pwõÿıÔuÇ\\Œ¦kÎiğ/Ùÿ­'[Û…ıßÜiî< ¯ûÿÙ?Õoô‰íê“)UísªJõÔµ—4`¶eZ”Ì¨EÓ!ğóØ=rxŒyäQËY˜ØBƒ¥Úö¢€Ñ]2œÚÔRÒö~]Jõ%"òÜ]Ò¨?©?Qªû0b—4zs[ßl4„Ê¦í‡5:£D•¥]%6#¾„Ä›‘z§^@ñ÷QëøLÏêdt`0ÉE`ú>ÈÌˆŠc¸i¶¢äÔÙ™úE8©ĞKßÚ÷;ÏNFòØµöXMp1ããÃÁ¸{2µŒ’ÍEğvoĞ1Ô´ıtØ÷_t^wÚÙ\“Qg0õÆ×İQÖÜ†YÆÏZÃç†Šr•¢@¨1Ğ0:°R=¤@½ĞièWE¾Ã6T±gäÑ`ßjıWûz­¸•¼ÛÃs•J9ù8æw]Qk¬ë¸Î=›³“oˆ2³•õ,®å—®0jæ ßš©·Xx®ÆÎ(ßÅØ!|Ã<ĞÀ¶(S iDşíPöhãš(•„Wz¸ğõ<t}ê¹3à²Š‹õ {°ª˜°}F§ç0Ö`ßBìYdydAØ…œ2tÙÚ¥25C¢ÓpªÏ/òÉ_É< ¾ÿØ~&ºE—º9NLuíOäƒ4’İ„ÅTVÅ®©Tu|îÇœ3>­K/úa@:Ï ˜ßT~Ø®eÔ6a‡§gÈê†šĞ¢Öµœ¢r‚ÒišY×¹Ú5~ézŠV¿!U _ ‹IèY&ğv8 3fÃo°zByÓ•e|çQ!óhŠ2§á3P§öñ>_¶ SÀ¤™iBeUkéo¢]ªélƒÈÍëÅ·ë‘Egfä„
€´²æšM$|j‰RÖ§J%ë|íOkgí{ÚğÂÅŒğ|n‡|Nÿœ^Ò)¡î’ìw‡ı£Ö¯F-şA^·NGÏ{ƒîÚ²ßäÓé\%µœe+²—“PÆ€*pD°»„^Ú!©×ëê^@M+åğ«ÄUDî‚×+æ+¥u„‹ä%U*™$$b©IX‰›bÙÜVÒmå1±ÓvSJ|âduêùÀóÂ‚ûT*™&Æ«Æï“¨SeÎCäù­òÇ&³3
RN¸"+ÙÂ8ù°¾5icÉƒ¯Ÿõñ?xáĞvçdqpH­zx~†øãú5ùßææÓBüÿäéÎæ×øÿK|{h“"Fs6iW©4IÏÏÇ´9ĞdåW”ÊÈ#qüÈ‡~ÏÆ.¦kÁøJ>µ"ß‚à_'à¥Ğ_ó‹é Fîß‘ÿ777·
ú¿Õl|ÕÿÿÌü¿Z%£çİ!9èu|CÔÖ;nº±ıJÚ½“ƒîáé ³O&Wù(	FzY˜WÜÆ@àE¼(„0ÇæQXpõ=™À³éB&	±O@eÏlÈI ˜a|Ü„Çca=_XÍï}3`"ª“•bAxä×ƒÈUªò8Â'š&F[Ô±6†…Œ&“;×…yNufÄæÏÈ,ğ`@Ğ5ƒè˜ÎvÉYúlW×“auÛÓ¿LQAÉêrVóV{«A>CÄÊ‘å—¾é2Ñ™	¯¢Ìì€ÁæL§Ït(p¦NŞj‡a?ğŞôyESòV?ì¾Zå/iÿyÉáß¬şßlî|­ÿÉıŸbáU›D¶cÑ ÎÎ¾`ü›½µâÿ7Ÿ~õÿ_ëÿŸXÿoê›OÖÕÿ‹‚~Ï3€\0õÜĞ„Ô‡pdø¶ƒùw@æÔ¥;H !Ší‚_Ä£‚Öàxù”è¤Õ´Ÿïli¤åZg[_È±+U‹†tš£à|øX™ùÓ83-“¸é·	ÖM,Ë-?ü=°Í¥My±Ò\Ll,x)<@:è·±î\Q*7Å=´Y8ŒÚ£´l3ÑºKÃ,3,ä§pÀz^X}¬N"7ŒHó‡ºú Ó
&–?Ç.½G`ì„Œ—]÷öø°#Û.É1ÄP¤ùãıGRfN•”œfFÆ“z£ŞÈã9a¡†šDdléÖg…È¢§îslÒ‹zhÎ™P‡âñ“qcÜP%L€e|Ô}6î·FÏUX ;ör¨ªÖ>8LÀ‡ ¢qÒêÓÙ¼ˆrĞ9ê´†C½uâ—Á°Û;1â%Ş‹,½&T3®#Š­?K[÷ZÒÖ­K‚^ìNO@’e\ş°3MsPP´¹­¬+-ğW¹8€Ä”f®¼¨Vz<…øãêpn
„Ê°`À.º”¼}O¼I`ÏÍğÃ?A£0(à°è’§‰>'Ì^L>üÓ±§Ÿ»BğäFrÃxÏÌæ_Äq‰Æn_üêà—ƒ¤†\Âïuìø„©âµñ¿’îJ˜_ ºt^wÀì\œÙÓ3äöâTE“±mÄ•rµ–¤ƒ¨êêÙI9æ"GµuSİo®û-ÑáúE‘^©òŒ7=OàŒ‹*ä»´BBÈOÏ•U8<AÂ#p²8İhpzò‚¤†|„£°ØŸc-’m³ŞĞ&àÔl¼
W»^iûö­öø&‡:>Š‰ÁşÜíÇG¦[Gİ“Ó×ãç½ãvfBt
ËcH‡„yøòdÔ:¼áÆ±dÆ›º¼WuĞÇúü7µdu© –NŸÊåõêBoJ°áÑF,×¥ø Ô"ªâ §„u+My’3ÇP[]{ˆxH‡ğ‚ÊúQ ÍÅ
äÅ‹…	€PLx¸¢<Ã¦6Æ9­`!NyÏLwN³sû•…Šİ"%’uW*XÛ S°ğè}ÅNƒådş#©-“vÿt<j;#ÃØëU³Ø9RIo˜ö‹ˆŠ´½áP ¶}€zù´E´öìåAÿå•$Â×tº¯Ü™ŠàB•/7f W
e·¤*RÉî$HâØ;´;‚£’†9°fˆ^+
6?‰AÈ‡ßl?a‰ÚïYI÷Ş÷§—;ÜG–§s[#¯A°€iÏ{7&à" ğ‚]r h™´ÿš¬>µë“Şà¸ut£aµl¸b«T²ÄÁWÓcÓZ©ö«Z ÓÔ~»\ÎÖBU’õeì_’Ïì+ /ëàrfµz Ğ
6ˆp$*	Øe]hÓ³­R}¸!+Ùni·ï¡&Ÿ¿DòóÚñü`EÚË¨»M ÖŞÏ¸‡<MJ’ñè1G3ÁR2±ÂM¹“ŸÛ&|,—ª·}Hò[‡‹È‘œì¹ y¹u/šãÛØ&rÇl"*ÈÚ-lÃÌa[<ó¼p¦Ï•-¹@ÈğBƒ=„Tâö¶Ô&]u98jzh4['ûƒ^wËQáÎƒŒSñ$dÍÍ–¨¾Djxâìj—ÀÛ?…œœç3BRúrŞ–ÄVåË#	±»úY6®T†Å¤oNÏÍ9w¿sĞ:=Á7JmûE’°Û®E/ù¥—$$µk¾©ñ¾w7½Ö\@™pøk•ıß¾şË¯1q„iÔ²Á•ıaeàÛë¿[;«õÿíí§_ïÿ?®ÿ.°ô«™ÎÂüë¿$½ ®Åç%Ïzğ€2ßs™=q(¯ír„xĞ›»Ø¨‹ÇÄëÄe%¼®V¯n—~;´ñÌ9¢i(Õ¸’eò»–tIÏçíß(8dĞëÆØŸ9Áo0¯%.a¸ÿB.ç€™h~€û>:Îïgâ¥GµÔ“x(ó*ÓZÀ4Á[“ë ô€úÃ]¶ñålQ‚„pJnŸW’‡¨äg¾{>‚îº&ˆMkÿYèZtÉ¹IˆØn8#‡§Ï†¿GcÃP#6Q¿'­Ñhpm[/©kyÁ4ÿô²s²ßü}Ç½ı¡6vvvàápĞ;íªïDsÀ«¾uòWÙ(Åøï8ŠŸ¥o7µ˜Ò:oB–xIÀË˜!P<-ÆcU®!K›fğ—È^z¨Á©˜ø‡\÷¼gL²”Ü•Teñ“+#rÆ›¯¾Í"`å¨o†gÆú‚¥æå¢*—“ŠĞ%±H"ö°ò-ªÆéjàa[?M3!Mjµ{ k'±F¨r$R‹¦4EIã<E<½¶’û-âzd¼›ÔœØZÜ}àÔR¥Õ]ë\÷3sµ`z­Õ@'“Åë¸M`LØ“ 9‚ß–Sgoˆ÷¸CÏs †|G/'j«ş£îP¨‹nQeˆËb•ÊCí ÊoüY
#¯G`‚o±œÓğáGĞÂ˜ tŠ]¥ë¨…ßŠ’ÕÁ¢Hb[Hª YxCŒHr¢#,B¥Â¸nÙ.µ]¼È\ÀÉ™$Doïx¢•ˆrÅİ¨3éHMîÁ¬¯™Q©	.Vh.(.lû¡Æ‚ÂÓ÷f¦Ç–8xhA’áZHœãÆÕ”„>•¨u*!i±>®V·,¬:ÇB¯xèü¸	ğEK|lX´Ü”SE^l2 µ˜"*Ñg<Lj ¼¶‹wk‡ƒÖşQG ‘{üêº`óBˆIşÑgéãN$ïH¤Ä¨÷!ˆ‡¼(€•ÕİVk2Té9]Jü.Kaé|·¥½ÎõŠWWH1ÏOŞV‰½1ÒiÔä'ğb?²vòh$n2k9’;p”íL-5(?cq¿oEÃ|	’œ‘Ëh*…-LÈ«ğ¢<3A×[M|Èc=¤Ë§x=)#‚F1î_ã3w˜p€ïağcF¯¸¥Ú‹ÀÒ¼7“şˆEf`{D\ÓÒ›zÉ_j$&€aefC•ÌŞ…Kƒ–ã¤‘8õ\ç*¾¾­!†Dúª…
@¬¬äac.ÜØñ‰êÔX”§]hD„5•xì˜¿Å.cáY–\Ø¿™AìíÄj»û1ƒáñÏ­Áé_òxvÔÆ8)¤¬¥"*Æ™³fÒ4¥º_Ö›êyYg¼–5½œHQVïäQa0„ç¼¾ş-®ĞMÈK0â„D$‰êñî¾—P§<zd=û§ÚuUbÎ›Çïnöìï¾Û r£Ÿ84½d0ûİ`ñFIw³ŸD¬+î öËZâÜ9—Èô]…·#¦#oŞ’Ë@;kCÜ>ºTµ‚(wğ¦ÄALÊU(M9õP\òz™.¤ye­üôDíº3o÷TåZŒƒv‹¥Û´Ÿ\xÁ9óÍ)™ûª7x1„p¸“ÁÅõXV6WÌ:3&ı'ù~0goİCğòÍY.³w´?–²6£VhŸŒ²K¼3Æ˜öçŸ9†£^ïh˜A­4qÀ“}éŒTzàòeš´©1…6F69D±˜Œ‡§ı~o02n%Uì$—MMâní~m@F„¯P„ƒ4d*æsï^ƒX©ñ‹u±„©é]…“Ş¨{ğëxá¦¸AğMá
A‚ÀGˆØ[÷ù™p‘]R&^oİõ²•õİS®`ÎŞáîİ¼Hmxœÿåäì¥¸jı+÷Öå/ß‚Íæ±DÇ$[f“êF£fl=şNŞ1´K.·¸İô}'}ï!«S~ ƒ/(Èõaß`#QÊ¾Ç÷]ˆ2 ca!Ë—rî;±pJ÷¤xa/¨î‹ú +­»Ü{´˜7g·-ÊÎCÏçvfÀßì‹fÒÁ—GŞ‰ÜE=1ÔÈ¶DMM½=-v>¢Ú¹¤ÓÜÑh¡Èİ4$xaWšÈ¨4˜”ûx>y†*‹rx—±å¤u§è²òp0¬^·¡‹ñ(*ˆØØ0 «C#7¢ÁÂvMÇ˜™ a¢éÊ§F+Û·˜m”9©¸³í­BHÃ9„<âpôbïğ´¼¶çÀÅ=a÷qM‘ÿê¸í˜ŒÙ}ÛÉÉ
ée¨_jâáŠŒõŞƒkâŸ(”÷Ù.V:Y9 lÎ·´‘©ÒF,oœç{¦EaRÇ¼«|A¯ÀÖXÌµå½¾Xrè  4~‡µ'¸³—gÒÈ–}È4¯vw_k/ö;Ú	,eI;—!åïİ¼Ëöï¿‡!†|¼á¥éDÔ¨ÓøãkMÜ­Õğ-_ VÛ÷ğ5i#Ñ‰s|[iÂÖ»­ñqçätÜu“„¿T§0Ï=ƒ|wIÊÆA·_ÚÓ ÏáB<Şï_Œz}~R@@:¼©mŠê}@gé{QgÔñës×[P~·Ô´@®uvÅBºĞøƒ6l‹¢öLa!´X»A€¼Ğ"HâëgáÂ©£¡IiËÔIØìtsCırá|”%Š³%>;ü2±üHÈ=P¤Cc6g£?Âş&³ƒ÷`ÜÛğú%¤¢â, uİ“.O”²ÓxÂï‰J0ÊÂ²&ÑgØ@t DÉ”¶ï±PœØKQºçXã¼»5Ô»]²ºâ1Š†2õgùS"˜\ÛGT«äÈ^fY
P•{µ<Ì*‰©+A–0ì½¹4“È•²k±ï—;µÚu¯ß9ù¢ß¸x~£pß[çš¹° &%7È~òÃº‘›Ÿ;(UMÚBsa@¢˜#íÍAX…ĞÇ)Pâ!˜éñ‚ÿ’‚¥#ÉxÓJ¤U‘JÖ~üüV‡_s’¦‹X{ğõN ,…ü”ll*92?üÃ%0üÿ©$›;—ÀÖ®óÔ2ØlÕ%€0-9ß“W¼%Èß ¡rÇñ‡(“^ğıÇS4)9¡}á¬„1Ç2éÈ{•jÌÚŒO şãÿ¿p@™qg%)ùãG¡IhÅ>‡KK÷/˜÷¥’:ãØøûs¡ñ*Ì0Ã
0á3ğEµD¤.b+yi_œX½á¯CC>C¡¸¶˜·¥^aX"òÃÈqb6ó.Íİa	‡446ãD:Œ©8 x–:n¡œd÷ã£‘ŒàWvÁ÷ƒODó$_5¶¥Õ‘Õ‰{ÿ;Å]u¢`Ñ%§‡?ºú‘UWÊ˜âßÅ3ÂÏTxJ÷ğxD]så¸VhàL©Å“‹‡ß:“·ø®òÚ¬» ­ccô¬eN%ÕòègmNÔÖ¨’Ï!·#È]ÎNëF$V;5¹N¾J˜dŞÄ!w/e-²ì¬RYMJ1ªàêFA¿.¯ÄˆZÂœÆg+ÿTå³YÃ„[ÓëìÛû¶æ¶‘dÍó*üŠ2ÈiI^“)ù2’éÚ¢İšÖ-H©İ3–ƒ‘„6Iğ  dµÛû_öéÄ>ìËLìÃìc÷ÛÌ¬ª€I©ÕŸsÄ[dİ/YUYY™_NOå#¾CÃWı$E‚m–W/²Jİ~•ñOI¦…(Ùç×ÿ7L€Ğ®æÂÓŸ­Õ‹¥’¯¨—;8n dÂÀ7¼lI¿şovéıxôN†œ‚c-—½“å‚•¼AĞ‡ MU!^ü×Hk•zD“–\R:ÁAfWArÁ`”İT©¹â
ÅV. Ç°è:? L¨ó=!I½°7ÆZ ®b(à s´Pşó ‘Lc¥r>OaÏ@™*DğöŠÆwvY‰*ö½üíA÷h“jáÜ¶b0íÍŠáO8\x„“sáÖrƒƒ™j·°O¶œé¨´feµu£R™ÑøÆ•9i®›«BE. R±6Jhn©Ç9KªËµ“wXõÉûÚ`9—h^Nlˆ5§Òœ…¯›BiõWƒ€C+ÊfTå¡B/¢tuŒ9'”Sª&êhDD¡®Œ>àEô´§‘…nF2ãzu½ZçàÚ;ˆÖšôd‹¥l$ç#õd)­*ÑY>‘Á7¦…iÍÃM5Frïg“~/Mä ¹®ş{5œıÑ€Æøw8ˆ8b	şà3ÀI_Æı°šÎø÷Apv–şšNÄw¼^6‚q¿ÂÎ¯úƒ—»Ğ?ıWõÆ1ïçÿÿùâ7JqúpM2?«Qü#BíxñMÚ´¯iU,­8Ñ¾ª$ƒW=ùÀKˆú¢e<Áùdæ¼:IøTå?"ï´wÙ=úîËn_`åß	–E×şqÂûøcE
Âaùàµ¯¢ÒÑïÉF@#_Q¾Æ¿Â_o0 ¯À òP(«4+¾ıHL}“‘ÓD}ÅO†>ĞØ¹®Öøm2ğ'ôw:˜Ä7¢şaXğ\Öy÷'I8d±×^»ˆ(R¢W÷eúM$M&ÚˆÁâÑN¤…Ã‹ô¤}YÒ¿òOƒÁ‘Ì…gĞxné¥,nÓÍ,®“f„RŒºôy)EF³°ÅèL¥ÅÈ…ÄÀ¾,9NªŸÁ¹ıÛ´%âî_¬CÍ««HPÖy9—ks#NäİàÄTGÀ-º¨tV:©ˆ¨„İ©İª¾sº’U6ªõš¨ñwG<Äÿn­å/İ¤‚…gav¡ºæÈ¬B>gUzúT8HnuÒkKOèTFWp.™ ?ñúñ¬®ÂÉ¢Û'ÄÍ¤Ì”pÚ{âú®‡`	7¸=m6Ü®ƒ˜­]Kÿ&n£¸ÊÜĞ¨TÙÆØŞzr
*ÅJ"å»ü"µa±J²’Ã×Ò¦T… Z+wxN|nÏo&ê7™Av«e•45{†¤¨¦±<Ç—§óB·üÉ’ƒäÉlÑôbÁE£^8Iâ¦Ü£›ŞúàÄšUPYdÓ¹Kq‘;ëˆœâY.şB¨ˆYÿW?Uh*’‚ÍŸ&Ğœ 10š1b‡Ç@DW„ïb°öî ñÃß&š³®æy1qYªÏ/>cƒ¯U²dÈ÷ñŒ@U(Ôî…Qp.n>†l”N“ÓéxÀµÍ°|O5ŒÔb
‚go=§ÒWW~Ñ -¤s~gEh“o€}Æ:Ùqh77ßR^^¤a:32p-røÏ«Ò[Nà(˜ÄO6ü¡YÌÍfË(,a.Ë`NeF]2·€íg†84l`)<AqbÚáÉà‚$¹g¹ÄÔ*vV1Kü`¨t4ÃêLî|İöÑÑÎş›nqJÇÉ™XßÆ.h+Œ=ñ“Ënœ7æqt-R‚ÊéAş8±ew–ò©Vèœ-g#ØÏ¹{7®ÔÊy¨˜Zíï¿¥aœÏºe/‘÷· ½72;²[YŒò6G¦É‘aq$fÛİ¹QÖÚ~OÅ}_Ï5wymĞírr¡[æ¶BÎïd¥Ì2¨é¤ê3e»‚ıÆ™‚¶Ì«Y¶¶g~§ÿó€cXˆ¥_Wu•”›ŠİÎRÌb"vçb‹ˆÑÚĞÀÌ$C¯sóâ¥]P5çíåé'U´3Ì£•²Hp»XäRnUÇp°hÄ/İ¾³+¿µsJ7Ûş)R~Ö%6Ì"Æ¹mvÌ
t"qaŠoö¨kEÌ%GÃïÛÁ%y~À
ğ3„7 § ‡#îe9’Ó­'B«l—°¡iNeÅU¬¡QÂjc¬•c r|³U	Wëg÷ùŞµ0^?&/¹ºC´öş÷Í(xK%ÓfOæÙ$‘¨®TbCë³Ë„T‘»ÛŞiuşš,®Ír‹Õ”È«Õp 7—µz	¥üpu9A^Œ\ EÅ,{{` HN¸H¸$èYLÃÃ|¾tü–Ï´q]Zæ?˜ì[z‹¡DƒçX’ğ¸ŸTBºf¢xB"/è®ÊßK¶±Á*éÒÉ_[[²"*‰ï;óJ#m/¾!>¨èÈØ§/eYÓúòç÷Ÿ—­:C«PcÆ*ÓU‹3âf:F@„W\—Ó••ÚúşøÒ`Û—Ÿÿ	5¥š[¯®¹pè‡ØdšîñÑëÊ3÷O/¨—ÏùBä?–·Ç—AQÿ€ÀObŠó÷ù.¯-Å«ãã'ní"ù5‚¹©	å4)şÕ¿BÂ®(KˆiøÆŞÈWeíYiæç5K)êyMôE×tË‘Ø­*^~ZpÈæ¢ç”‹Ó-6‰&ßÖ:Ò”ÏM¬›µP²‰'C(nÀ-TË+Ò²°‹Ïu1œÚùŒÛ>Aé®à/l:k³3°ƒ'å˜—ïıhÕ]ZeTÎR©>» CMÁ•5C¾Fa¾ŒKZ.S¬PphPÒ6nÚ~¬‹…•sÛadNQ!Æ:ŸÒmär!ÑŸ`;éuñ„Óú²Ç™Aã”/Åq­x}ÒˆÙyX<&Ş Ä¨$a'M³0(]2Éï	f±u*váäç·‚#ˆşæ!'"ı½F¾ñŒüúï2òÈÊV­.g¿¤ÿ¿úzãÉãœÿ¯ÆÚ=şÛ=şÛü·Ëÿm­Z7ñß,èo†›¯1‡ÑH²ØnØw6fşGáœ.‘«\]Áoès^Ê½_>(—¥$ªù2oNéÍîÁËÖ.û¾ÕÙA£ö.¯öU8#4ù”^ª¿ow¶ÛÍòò‰ÿ®¾µŞ-+—á{­N{÷€G­AÜz×=~	ñ·­mŒŞPÁûí7#‘¥&—@²ªK\Ï(“’m	[;ŞUl¤áiV4‚[‡G½İƒWßu‘urk—×ÜL>œã‘€Ïki¨7AùbœÄfTßë_ø‰W Í8ŸUX9‹Ğğg<pU'¾ î’¡‚=ùBô¼a w¦Ø¡¿Œ{¥n.üşx0V›øCŠ!]ße§Ô1zlLÒ…æ#áu›¬ûø¦O¶xäkØï?Â·è!:a0¦ !dN:5'W'¦~»¡è ±¸Ç€qGÚÊİyÀYS?qÙ ôcÍHüË¾yŞÈ¡ƒÄ;jšÂË'<<›<b¨*Ê"!ƒÅ^®c·I¾‰¶3ĞàãÀm\i‰QY,¯	•L£1öÂzı,œ,ŒXaıtríÀá!wŞˆ%ÁÍåıƒıö²eÌÌ!sË|½8Üf'?)I+Í	ËkºÇP^ÅåíVs€Á•<ä©½$úJB\r2N?/‘À/yÑyÌøPÂ¸Êß4’äĞç^«? nC‰hËKØ×`‹m®”WºÈR S]Æ	*+ç†«° DW›D[" *”¾A2$Í•U~óMf5´**‹Ój-¹qW.„d¨ôİ‹•´ª´ü	¾Öj'µû¼ªãß‹( nŒ¼Ú,qw6K%Î4ŠW>ì±`Aßy•ŸZ•¿­Uş¸õ~Õ„×‚ñ‡\˜æáÜÿÈ¼áÖàt„ |6³­J; [WÜ>‚”í$÷'\™»öĞ4“MRã"Õ›îáîÎÑQ{»×êtZÅRÅÌP6š¨tr²›ƒş%Ë×nAÎTI÷(­£YÎ‡}*l×‘çÂÔ¹É„¢“°ï€>xQä]#‘JJä½@ZX%4*%ïüœNicSN¿ón¤%é’3§¥Nß7J™…E-EbÁ½}xøÇ¨T§„Ié+[ŠşJ'^Œ›şé5š¿ûäNJ¥EÉĞû–ƒöN)×z:{Â
ëj–ë[ê·ZÁ°¢ÒP~Záºo–×U¨èŒ©X´`Ã.™ÔrÛb*RÔ@’-c	|	l)C¾óp¢Ù`†ô$r¯WpĞ0^ÑG&]İáiÜ;S…À;Fğô“ÔŠñì9×;:w ^ßÁ	Ç	Ú~‰ß47ˆŠac.]bRT6¤aÅãÜ4tì)QÜæÄğó
øVgŠkyŒ®r"è•—°°Šó‡SWl+X 	q_ ¼R´Àtè4+S.—©NC«‹Å¾–ÎŸŒoÕ}[¶ùPâ/¡H¤–q&¸£BÒJu)†ª½×L£âŒd6QÂ¬«7#Ëôö·ÍŒRrbj,Œ¡Ÿ;s’º­É­6ËŠÊD6ÔxjÖß¨ïj´6ŞnnHo¿y¬Ø¥7º!èlZÆ$—â¿*\jÑÍ,nµ±Ša°:a˜ÈÂiwÑ;[è‚Uâ–PçëM£‰'
¢m†RÒ@pœx;›&Ô7ñ‡!‡ğÔ Î„»q³º¢+"ûÈßJ4“Õ/º;çèŸQp	S~îÇ'ã6\·`}W«U$¡ß4`¸ğº3Ñ.4B<œĞÉ'ë4]¶à~î'Úê¨ç¼ãÉa*8ÏıAL¬whõÿÂß7® ©Ôqï³J&ÎÇó}}0–•U¨Ğ)ò_eKZèÖF´s‚îwP_nì'„ZCÊñ§0O×ØQtÍ:#zàZî­´¯ÑİtÄÈı| #µÆ	jÅÄˆÌ·sa\'0Î“(ìûqÆmı@£ˆì{çşˆÈ(ë×ÿ…kô4@Õt9AdX˜F <Ü¥^NãëÌ>µ–›ˆ4éŒéØ2ôĞñ&HïÙÎ·5Æ€wkïeü(¦«ğÕ’ÎÂ$cNi`Ó9?ÖxşM•üñ¿OQršÃ‚2>HéO'4*Uì™R“ÅAEÌ>mo½ !§
å:7[XZÂVÕ·LüP„Ö=é»VŸŸ‰×‡“¸î(1!ìş‰$ªc"ˆs¥rÄ	ÑáUe:ö¦Ø¢íüÁj6q–d¨œ+£ <+Å®‚yJ«‡)òc5Qqváh“Šm/Rb.œg	+¸¸İEú[Z~”âŒ‰Æò,b{ıß\×ô=7·ö{Î\²²ûw³ğT“È*$ı	³ò Ï÷n{îÚÿ˜ş»÷ı¾ˆÿŸÆÚzæıgıqıŞÿÏ½ÿ÷»õÿ.Ìû•/èèç•ôõn¸r)‡?ÍY¦~ò…<»—&‘
Êp$ ™³Oà|ÉJtäÆ~ëW‡È ù¿‡jBM;¦qj·šæ£wé¨oÉÁµR\Ç1.¹ºÌg‰Œ#Î ;˜Pkb’c Ë[Y•èLBÅd.jmH9<´Eä Y§ñÈu®üÉRœ •Ëv6-Ç|Ğú 'á=Ğ¥Kù!ÃîÎ»á×‘ëÃ‡ˆ&fYjÜÒªrö¶z}Ô~‹En®”,HX®Š˜pÊ\XLË¿·üÒĞáÿæ2/^^ÂÈ!•R¨ÒåT•g†´Ú|âš¯?jÄÜç®Ğùêj8ÒÜ²»HTF@6Z²,M
d“IdÒ›½êÖşÑÜz1ÍìJEŠ¼x8~à»‰—LcÎL“õpº±İt¾uUe‰ÔÿwéN‰IŞÂÒYhüzµĞ{s¼ÃW¼ˆ‘’ê-y©4œaiZ ÜñUò”8’%Ş½häıäñ–C½_ÿã×ÿ«4O#”„ Èp˜šÕñ{M˜“JsÈ“Vs…•WğU›U€ã¯¯²U}·ï&ÜçÖŸ%»$@œúÛ	24D« hÕŒªtòå@ŸŒ#}ªjÉ•®ÀHBÖ4eRDL@”4´ÉßRğ¶dx…I·b)âZ&Š/@õ(›’‘¯±”çøÕ…ßÿĞ&	ÔGÍ3½Ñ7ô+4—˜qõïÖîQ»³ß:Úù¾­ü¢©İ†ş¦æe–ƒ×³(»iJÔY‡kÍÂ*Ú×º·†h_Ø1TC›N°d«°Ô­)îXÚJ^¾ğb’#¼Çá–Åø­W×ªkæ`°9£±ßno÷qwkãÉÔ¬§NÀƒlÛ?<èûZí`âÿ²ıe¼÷"ô™>3ZÍ$Üî³
üŸN'·›iì²}>³’-)2|ëEpŒŸoj®›esŸIí¦˜·Ğ<bÓ˜{¢^ ¼6“Cµ³™PÁÍ²Ø=êÊ1â¨ÇœÑ”ş éä$s5T¤áXêqµmÒ‡ÃOœB^î´ö{/ L¯‹*¥n¡Ì/£fm­ :@>²r
û)öºÌµÕæjò)=ÉÔmÙØTÊ¢fŞJê‘Š=2‚çA[FX£‹¾ÀF7ÈÇÓ3‹ŞÔÀ?­hu èzí0Ÿh¡†‹´¬ŞCé½z:øÉ€PÂ&a:2á†Ç*œ“£Ó)†‹æĞôØxŒÅ^ÀäNë×ÿğBI8ºÅmG£\}ùˆ­L‡ç†øÌ<%¤üŞ0‰³X¹‚ÖR¥2™Fç¾Z»¬<„ÍOX¯?¤£Qì6±Ÿü¥Ó~ÆHŞæM‡‰ƒA0Ï¼x›‡|¡‘^ô¼ä¢‡³„ÏïülÚÕ÷¯È_UÒPR§JÃùM*…ì†ƒ\•Fá¿[ »]pú¦)Êœåê=WêõZ•ºB9G±’WÉ,ˆº$·Gj–Ír€ÉOÆİ$œLpÊcü½Dè]¥]´B‡ïˆi}ßâgn9M¦jòîÆuøb˜{®SËªM·kKcé5Õ%Û–ìÔÀŸÄø±íã&Ê@âŒC,îh+MšË5ø—5^é¤í¦àĞtéßm½İÛoöÆŸc\fˆz3ÄU>dŠä9¨‹n3k‚'PSjt"{	¦Û‘"ÅJ†:f~îœÌĞƒ´%É\b-¨õ74÷Ñ9Ğ-ñXK¯^üKSÉË‘¸‡ë
€ìAÕ¹Êøù‡Lù2Éjå`K+ÓÚed'ƒÈ1Fğk†¿S{d–gÊlY¦ÀA›põäHj¹óèìI'6#›åØHS«£¼»ó²+¯eü†›=§˜Ån©îˆÅ"úpÆBt60ò“(ŒÉ˜ïÿ&4óD·n<Šuô9Ò#D_S[@l5Çİv0¹
¨4òÔœ¹úŠI!šQe+›å¸³ÛT8ÉÍ2w,÷ÇL±'c³4¾5Ê÷ÙAÕÂÌì#PÄîÎ«ö~·İ…Ñë´öÚÀïãÍ¯R}Ó~8{ä¾…ÀİašøKşèå«UT’šîXë^k¿õ¦İé½ÚÛÖ*~k¹ M¸ªß7İ‚Æ¸¿¹Ø¢¾ÜUÉtngfÑAS+Üñ±ê÷2×š­Ì€7X*.-ëc·œšĞ	:ÄPNïÍ¼ÛŒ-ñœi|ã'º\E?Êú‰/ºÜ˜ñ…šñ½’<aKˆ ö}ÜP£ÍìÑnUp(ä,n+ön»Õm×ª„ŠêLîÄZ4j³Ú+(Vp((çŒÑNáÒµÚWZ´ Ùİ4@Á¨*ùhÖ†ÓÍŸk–èÎÇ™¥ŞÉk¶‰`EnO	ÌÅÕç&•3ø·<:Cí7Ä±Š\H0
ˆ)¥ø*<£ônØâv÷Ôôü¤+ek#J.Ql¼|uÑ–©š»Tµu&‚üŞ9»àµö¿+‡0î˜øÌ†è¼0N¤å{Ä¨FÑDJ@™:$ñÌ¨|.õä‹¼+¤7í#şÀøôDC!¯¥+.í&p ˆh®¸ı!p®ôı!ú‚6³xÉR‡3éT%ğªWãa¬éŸÃ²p´y>lĞ[€Áç,ÕÍñYÄt½pjjŸîŞD¶¯À%¦7éÙq\¬úM¦Ã!Îç±°üò'¯)îd)oq²ççñBd1ûQâHOŸ>e•ÎeÁéïnóÆÂºŒæe’ãÖ¡*^¥·kÔMZ%î¢wq\À²o“£(87_í3¯NÙ‹ûMÅ?ÚrÔJ%¸6„€K2pÅ£Ëâ„¶ˆªÇ5ùÀÈ´™•V®µZX­Q«ÚF3v‚$'tØÂPÏcı°‰ıom¨†%Œ½U;ã)2´MË˜±C¸L#q•<ıMx¯õfy’Öaog»ıCs•jzø^IYˆO†p½ÒÔ˜kèÚ7ùõQ¢] 0$u	¨iˆIäçMP¥%
‡¯Ãû$k`ZÁ¢çª®“9ğ~/ÏDs15qº™ı“±&gDiÌ&÷öfç´mH1İ1Ü¬Ak°R—´\¹²ùB£B |	=¾‚á…Ç}Â´çcoØ`+ğîÑ~M'ÉªCÑ¤¿í
¾!×¼¦OÇ?#±}3ñ™q´åæC¹¿ıİb‘[¨Õt÷nú5[äIlEU*¨¹š{wóI¬P)7j}?Hásg<P¯¿ùä&ì‰•BLÍ9¶–¯[ö§öì)`v˜D™¬Âº;ovö`·áâR\çÃ¸ØV>jûR,g{–ï>”ÆŒÎ«ÓOÔ•:­òZ -¶¦ˆk;_ÌdÜˆ$w„;³Øl¥KH
ãd:m…ÏXı‹„%ºé@
ªy¥QÙàîÒp³K$;’ØĞs* 7j<®6ª]["%RCÄƒaõ<Ï‡~¸/	šZ*cÄş»æ'RO”Ç«0çÖ’aø›nq¢İÜĞhƒ S6#LRŠwıÜüm(’6:lKú8¥_£boÊ†¥ìŒ¶MA"Aö]?¶ŸÈùRºÔƒ½³t×æŸY1ÁG\ÕXÃÂ´â§õ›—Tø |Œ ©›8Cx˜…!ç•}¼%\yAòHİäğìÄİ*(.@ì ¡Xd_Y8TÅe’™¼0Õ€l¹):CacáLÕÅËbEíœ%¼EÍéÛ¡íéşVo÷Úã½ÒÊcšeŞÍÚ7»Ç_c_3†8°†ƒt{×DĞöh|¿“Sqá
A_ãüi-yÆ7í#·0¹;ˆóñä+˜GÖTÄËã]Š[X°ÿ6Î¸Æ·xñ§µ]÷Ğµpİ±KşÖ\ò45Òó`^FZ6/±}ğ“\E½hoò¡G`5¨<5g´‹¹·³¯XÅÚvã¢Eƒœ»½«ÍÆT¡dÖõÔ?IÛİ…Oé¥YmáI‘õëè¢[lÃj¼ËÛò†cş¢ñæ§Y%Ğ¶ªÔ«—JŞ¿-ãÌe¶üÉºlHé‘
«e.nC32¤¬€jó5â90ØEåø¤ÃÃ­àèµ®2Z¹¡V›Û¹Ù)ø+”85gnQ_Mgµñv©±•ÊÍTı=–ä£?3„Àâl°)¿Á’Ho®j?uõ_Ú6©­u—C-ã~Á!W¥
¬R-Lµ…Ú kµG„Ãå.0Ú„àR§Ë`ÇyYãá5ÙE'Ìó,#ò¥aeÉ¨eäz˜ãx„WÙi„ıŠü›ĞmU}Î,+^”ğ²¢ö³l!KºgfÓ~¸²gá×Û˜˜«±ölº™~e•Na7çæ+ğî&İàrXœÖ`0 Åœ„Lº©Ä£òñˆh"ôf\mWı+;9dX Ö˜®TÅ•ıA/¢(¾ÚÖ éuâE¨Èc3HPêÇÃó²Êâ_ÿ!¡˜¶Ì(£ôH¼¢<#;jÉ7kÄAÍ¦9¤§é‚A‰MD)úø{••tøÂ…ÀòEÅ—şPŠ· ±Q:9“q,oº<­Q•ËrhÙ¡£/¯Â&ıLpÇØ,Ö—Ø
|”šÑ†”$˜USZZLMÉÒˆâëd½Z×Ù|®³Ô›†é²‡Æ‡…È¼÷fÎ?y‚Äd½¥œïw®PMè@+[í=è˜İËy-6¡âJÆ%ÅDè`a–{d“‚håç@[ˆ›(\?á€ ‘‘H(¬Wb$Ìáx ê\AµRT¨é=0îKË²2ÊrR“3Fÿ•2UÊçpªÙjøKLeñtŠû¿ş#ß[ø£9c$jy	¬)½çŒQû!À¢8ó~‚M ïğ¤(‡0ÒĞs¶‘™€ı|’ôÖ{k½µŒÕYÚÕs³4'mç„%~ÒÍÚ²‘iË³!ï§ªv­ú™äfN«vV¶"¶şH%æª2]R'03¬şTtŠ™ß‘èüÊ©‡ØLÕ6J}rÊM8'‘ßÏr€İùY­Ÿ¹b¬X‘Ä„HK*kzµä4H~kB]¯J0“öt:òQ»[L®éŒòJÁèò4½#ii²'	ş+ö¦º´ôÙkŠhIe0àSÄ»¬J tev¶Ig¤È‡Ô¯mm¿LÂãéÁ‰³¸%ØTSøàjìGÀ¢KáÒ"<›¡ÃÇCYş9ècóIÓıŞ’éÿ‰s]õ³]ZZ±JiBqÍìá…vçs}qÎyN¹ƒ|²±ºô5ğ‚¦Û™¶bv3xî/ÁJf™­‚Ó‚7(Ï‰İ-we¨bÉUâZTõCÉŞ³‚‰k4İdo/<Úîb³.8œgíß¥¹¸(”ÒA,%uf²@VHˆ5Í'¬3 0»#XSó2UK²53ªİÁ‰ó{œ¦ë@Ñíâ~CÙ’8}àkú8½b˜ëê®ıôS[w|ùØ¡°ÀÀ»Á¢ªÂ 6C°æÎW—Ğ¬DrÙuÁø¤ƒÔcËâM•PÕ&Ö‚º™ÚBèÓ›ÊËØ;ÜİyµsÔk½:‚2z{Ûm¸‚—<Ø£½˜ÁñÌ/×âHÍAişnV¸Èë»†¥¤]ŞäKíœ×f!+…§>ìÄ'ĞD¸?‡(Câ0-«Lb)ì#¦DtäöµVÊ—ÛÈÆ…›z¶ÓôñÑ¾ƒsFNöÌt\!şr%d¨PØ>ÊîJÖÃY(e$‚6é"+ÁA^x¨(O®Paù-^„~8Ù,ËFœUÙ†¢ŠvŞ9sk€íDÇq
QéŒƒ,sŒ9§–õ€Ì³TóÒErÆÉ+áI1wŠØÎ{4¿¯ ÿ¯J0Y(œú¿‹ÿ§§àÿá÷œÿ§µõ{ü¿{ü¿›âÿù{ê[Qü8¹'
ÅO©)4kÕ.ñlSêü]]]U/ƒK/äÊy½zÕp1«uÑíS…×V!¤RQv8®@{ÃŠòåE_#ßÉ÷Á´=+«LÉ[úS+ö/Â»ÂAr°wØiîş•œ¶@$Êû0°÷ö ³İ}G__áwºv`ÎÂí"°Ÿ+0>„Ğ”™*pÃG=kñ·ây“ r…^ñhšÕ4A*D—”‘xéÑÃOĞÖÏ¬Ùd•‡ì½¦Ğ«u]òÀœãXy‹¯ÛØ2¸{U*";‡¦R`GÒ…‡8ŸU^³¢!ezøâ9*7ÊQ­İ¼GÖ3cÿ§.|X“Qü…ñ_õ§Orø¯ïıÿİïÿwŒÿztá£SŞ”ÒÄ€µ$Æ‰q‰W`uã/ãò/¬Ú­qéĞ&®â-+½ñKÈMçµ‡6ÀÂëÀµ¼ô¢›}agA'˜‰&T˜`sÜ?8ÚypûÛèäY‰‡Çaœ]WÕQ²œ&÷ˆVÔ^-%I ¹‰Âyº˜ÿÏT&ä®:êÚ!dûš²	·­*uZ;cÛ¬µ÷r§½Ôæ“åÈ+1¯À’ÕÑ/ÍºA'éşN3+½ş°ı¦·İ:j¡!G·©¹oŞÔ1ó€œé:V)‹KK$ù¶½û
Çİ'Â4sŸŸMÊ¶ŠgLš(¹'ÉIr^ù™
o{ãÀ²ƒ!¬ô òĞ:ü'R:«o—u©î“ä¡€İû#%Ã€cBãbõ'Õµ¶{ÔÍE<ËFğö= wˆ´†RéĞ9ä îuç ˆd»éaWF|VÑÕˆ¡âåSµàŠ5×ô,»;/¶Ôåï}‡rP\gfx×qùlÒ_ÖSØĞ)pX?-«±ÈƒCAk‘ûHrv¿;:8„uùqpLYTA0¼J¾8´Ö3.éúı¤ÚŸzÕéÙ(Ö9Mª¡Ï¬×Ï†^Ü¦DâätÔ0kø]*Ùmz`àú’Ü6§²±¾¾şôO¸Ÿ¥ÆkhK´vªb2¦mÍ¨şìTÏu³¶H%ù1áiå~ûøìIïÉF®mdhtÛÌÊÀlVÀ”[ÍªTëÕºëdlfiWÌÆ3W‘jŞ2 	4“‰Ìkùc!Õ5ÜER»Š{s¹ñ“-óÌÁÕYu
á4ô£ÕYeÑ¨v·f@0Ç¢Ì«ëònÍ²rÀÜ<~K­é'W –µoelÌ:Šlfv³AıœmŞ1»s•y£>TøÒ©X6T"Ùl?"fGf0
d.ÌÍJ¢!İÎƒäbzJÃ£	zòfB\dVœ·¸â{Zqªêğı™—¦	ma¦ëíl·eª.Ğt_|Ç‡€•XÈµ1 ½0ò²ğ¸éÂùd”¨µrÛ¿$>í0
ôû	Úà”T±Èº¢t=x}_ïšÃÑhq¾/{íıãŞÎQ{ÏHoç³jŞşHÓ#ÖŠªKû!	aÿS«¶°jv3\¼ä6—yô²£Y¶#NO"°İZóÃÆ‹Æõª²:–öÔT5ñ¸eG3úOéK¸Á®zôŒH¯5„xEl¼)ÂEÇk<QRA­ôlŸ+²
÷êêÇŸ\G7ú‡£ã¦Ys1¯5ÂÈ1Ù	©ÊÓu:íÖ.•*ö~½jä{CU˜0ëOJî)¢,5RQp:åD1gÆ¨§tÒeÌù]4'2xbZ]$bÁ(=<á<{’nºÒ­„›ª˜9kµ“j­÷™•øş…†ˆJ/ <“={-W—éU±÷ˆ…§ğó~Ÿ¢[ŒáŠ— ƒ3ıâz˜Ô±ƒ,i£z9®E¾?ñ Ï‚j¢©µÄ;kÙæÂŒg½LX¦8ŞjÿìÜào<ã‚B(ˆ¥^-òÊtŞÉ1nU# ¡Ô{Ï0Åª¥$5“X"N&•„_¨„zõY•r.9©¨œ0µ²sĞíöZ=u]Ğ¹eòªÅÕÓQ«¾HöêğXòO¨®~ ¸)i™E\e@WÎŞ·¯]Ö=~‰*°Ö£ÑåSÏeòöxØi¿Şù¡‰÷ÙåU§¤5Ó[·pÛ8’ÙBí+hŒ;?‚3¬Y¥ÂOl8§šh|6T&ü~>8äÔ{§Q08‡39›ˆ ÒÃ¢ªÃÉB¢€g¸®ğgò
G$¶ß(Hd—°¦y¬¹wÕdñ3MÅnÕàß³½èÜGØ{
W?ôë«jãY¨H@ûŞ»ûÁÆ±Ôi¿iÿÀ¾ouvp÷è:ÎÛNÏ`+\1ÄaTä~İÖÓX;©‘¿ú¼ãw<{4 ^8Z‚Óõzeà_¿wz|€ÍJı‚‹Ç$øx:=Óû^…ùÖÈyXOc?&q"¿{É-æü¢_‘5á¹q>œ&ëé7
w¸éüñ¡òX<=½äd6ò>øŒO/pÔèûÑ2D¸à8ÓqäEL^8çîNÙ9ü#Ç¤Pwv²êØĞ6Rb1Ÿ)d2!w!”	!‡‰°_ésØÉèårL’hà5Ø8W°¿®(¬‚f2wT lÒïŞ½wœB…0»Ú’¿Øœëd"íTG;@bo[;p³wlX3E¾<ÖR!œv²­yŞ.|Ğ0‚È\¼r}àGB!æÛ÷NƒÊFõµIä#‰ ;„TJ‚<qh˜IÅÃîñ!’û¶ÍìtïDZ,Ê¾]ùYivs^u®iÎ™½ümÉ!KVÆÿ7ËÖ¡Qí/ÔM©9ÕğÏKuhÙ¹l+BŸŸFŞî+°ïaÇ_G®/W˜]èËã
äÄ<.·¯Šc5Ë…¦Õ³˜¸ËJ“ˆ|dâĞtómÏ:‹Y~¶œÚ…¯^7v~
ñ‡ÜÕv£º2ÂUs»9Ê¦Öît“}L‡.X—ğü”SM©ãÁÔøÕ±Ÿ ­s!‚º[0~Mh¼ı¡±F/ğ×lÀ_ØÕµØ¢;™RáİCßD•zòã6\Äò¿¤5¨pÏ[ÓH[³Œ»{å_ñ…ÔAÂ3¡ˆË¥/°æùŒÅ×ãÄû¸ÉŸpLµ‡“$„Ù°ôíêG ñûª€>·ÛŸß…“L¯ Í|ŒºUì¦|BJ˜õ¦UÌüHô¬†6î©%øñ/ÿ”µäûÄ›­«ÌÖ˜«£3+|ÔlÏy¿ü}~ušúMQ}G!ûq'JOšª=“ê­l…@×ğ=ñ/ d³¼K/â;9zÈ lu~kH5höHCkøƒWXÔ¨ËçªGEµtHKIG»ˆQà( ,Š«T3•7gu:¡ÒññÜ\™ßz\FsÈ°‹^È0”–‹Äâ3‹€4¶Ù_+›™µ’mË­<máÙ•·Ôrüö {¤¥J]*zÿxïe»“]¬±‡ºM°4s-Y@oÎŠµjıIµ.+Ã·FÑ±ñÉ8íË~˜`ªnŞõ_şÉ^^+$o1_ÜÚïÊ#Ç?>I‹d¢Ü„<bP*	b¦ÀN 4á (!â£œJH£Á9Ú¿üíœa*ÈæÑ¢õZÏN‹õ6°R}¹“¦¼ìsõã/«ÿ[_ü4¯ÿ»şø^ÿë^ÿkş×­À4R¿·“ˆ¦‘Õù7©“VÑÑ÷åXâånÑÇ»ô×¢µY‘Ÿ
ãşİ~vÎ·J y[6C—Ô]$â×‡ãJŒ:Ô8#‹ä1\¹/Ú*ôÉ†êŞqÅà£î¢yéËÅ¢B§Ô3®úİ`<qp5ÖÅa^
&MÁUÀ%ä„ålˆ„NàE¼ó ßC”W…ª¨as³ÒS¡$\Z*Õ)$óæIz8Öf¬´N¡FË!íF<ÂS˜P3ßOÔo¥9¡O	bL9)Îõ|WêºQ¬0D‡Qoà£Îó µÎÓ¿Ëb¢`¹e=«Å#:Å YT«Uf¦ÖĞ¬]š1P+iD68®Ù¼½Rƒ(İlN`Dçqs¥ŒnMBŒÈÁ•,œÀ&QZjgør•~’e¼p>v†r-† ½/25”Îu O‡Û“1qGÅ—{'c&FİL‰óƒß#€…¹¸…n1&‘Î  xÓµuosyqÊfQ!›e	V¡µŸŒ¬İÃÃ¦ !‹ú\›LúŸDw©—òPªU—ÜD¶7åù†µëpÌ*ñYŞô6ã€†™e°é\H%‰ŞE8Ò0”	ÿ1K+2úH€Ş]£‚†-;ì%ÔŞN@Oœ}9v·^²İ×“K|qD!#nbî8¤£pd7ĞóŠ¯Li¦¸T¢­Q8`8İ!Ò­±NÑ·©å©½œëï'?ñ‚I:“ËÌÄ^0»Zšà(õ€mz l3r6Dn2úˆ î!8ŸÀK÷¿E9Y{^Íè>ã0µ¿iõ·„_)ëÊJY•†6('»ˆĞî™ã3]PEÎŠ¥ë™K¼<ùDşpZ{èÂûõÿ<BÉHà€ÈF:òæøWgk[@°æĞ2•w,Ñ!¶'‚`<x:à†3öÅ7—„Eáí1½‹Š­;½(«[%.$ŠSxhù—Q°26ÆèdÜ†³
1hU3Ï€[ºWóiƒFÈ#&˜(9–ç ¬÷,¾¹ ÕMI9t²"ó.Y{¼÷‘ízkUïM,ö½ÄŒ7`­Ê}&°ş1/‡ÿƒ”ØˆP^…ã¡ uªTÚ¡”½cCÍØJø³dó{˜:	£K¢åÎî¢ÑCÕö[w’¥g¶„ÎÈ l©şc¥é¥»ÅÑ93yËpÌ­SÒüğ‰te»´Ä÷Šy1V~·0.¹›šA¤óc³²ÀsÈıªuqîœ‚úJÒQ»TÛ‹†Zzğ»tLDì\+âÅX(:¬j½¨6Ğö1‡So~G[!'=¶ŸÀùğóÏò×Ó´‚qmX¼å²­ŒKİu‘ˆö®O¤x,Rà¦Jà|†_Vn°ò+?Éúâİ1cW˜#áLº}oâÇİ$B½«’V¤‘ğl:$ÀtŒ7áÄ“ÿ!CÑîGpz^ç>Ï]1ä“m!‚R©¸¥‹‚Á@ù¥ik#2lm³à*i3Õ¤ $ˆ%²/1™S‘ÀÌ6ì³­ùØgbBfÀ¶¨í–%ï¨-ÓÜ\o_$±ÂKÔQì§&Q¦Q²õT±p¶fÁwÌvÚ Òd÷RëfZ¸›Z·S±g×·,¸PÌŞ"¹åâ² aÑÉfPP1ŠÍ¼“0¥3zœ1VBæTä‘I¼°Åªä{ÈÍ"riG4,î€Üßµªü…éöcvcÊË@ Y@ä5J3û"gºÄ#>w&€m/-Ños]øE„–UbjÚ¬%ù	št­>(ÿ	ÑıOpìŸ#Ó¥7„6MáÙîå+G å—!§J*ßÂWjëUIUJ|sWY~ÅGhÚ'™ Ã‡æF¬¸ü14v	ñ@ãseqv[ÂÿC¹~ìõ¯ÿeöãÚïZÇüüdŞêõ'kÿÆß¿ÿ|©ù‡ã¼ö5ÍÿÓõõûùÿÂó¯?§Éù__[¯gß×ë÷ø_fşO\|äœ ;^VŒ™êÑ·&$Ä3æâ³*kMÏYı™ËU nl.qŠ2ÕˆnŒç¾ëT»ß²ıÖ^Û1U5NTÒ$Ì(Q–îÎşÁaw§ë˜­9³¿;9{É%E'g÷ô]øÙÅß˜ƒ9à["k^.¥ÉdAÜ€ã7À—eUw+Õª“Ê	gó!œ54ÂÓû•¬]GŒpÒî¡®ÀØm·»¯:;ÔXÇ@r@å*|Œ¹«ÈGÃàƒÏZ‡Gp.¹j„¤¬vË#õèÍ…hX†ÔşÂ´©¬œê¬(	‚ÔJÙ#kö–»ÌÆ†Šñu2ãÅ?Ï„"Ô%£ïd†’±%•Z¤«ÁÑäXÇ™A®Ù:]z^1¸Œª"e*’“c°Ì˜2L[ §çáóy"'rı%§U§®o³”ê†®TGÆÅñrØL
#ÿşçŸß‰ï™lRìWˆƒÆöÈ®‘¸Î–Ç»
…
U-êšPĞ²-V‹†Ve-AÖ|É±ã˜S4B„a#¼má(xãkFvÛBŞ›Y¢+Q^:è‡S¸"@¬`åWyë¡Ş¨`ÓºÖ%‚™ÑkJ³µ"u»ÎW=Ñü„½)jGi3QàQ÷0)‰vÚ²<b1‚Ë]3(“…ZÄbt ×/ZmÇGßtœ,4ËÊ€za¯şç‹0‹àMËWçßî?ÿ=ğ?‰ÿ“U€Ğü¸:|Aü·µµşÛÆúú“{şï‹èÿ™@fN5`c‡”Şˆ5T°gÁá9pN6ö¯Ø™ï%¤‡§ğ)0‡d/RuœKRÌ~`Ûïû£S?zÄH/­ O^8KÏã$
Çç/öÛo»›Ïkâ„O‡ğÿÒóağB¢ûpŠ"¦ÎóÊ8²ƒ6aÕ@È9°‚!™²‹×#vğ±k0í£$Õ£)=3¶Éû£Ò"ìáÓI5¾x^ƒ£YÚ:rÕhROÑú`8îÎ±şõ”r~ºkÇ±j‚#)AÅU=« Îª¯!ƒ7ö¤+ Ø
®æMâ&şø/ÛßÕë«Dæç5a9ş¯w~hoL !Å‘±`7Ï&ıÑT. Âq\„ÑKn$^aåÃ4¹Æ´g¢¾ò6­ÓI_š½ä<¯ñpêj uuêè¯ŞŸ$DcìY•Íê¥FJÇ]}”rÕÁõµúoAÍèKJ©®ä†AH‡*ÑqXã™-WÎ"İoÆ¡ôTE0{$hAê$ÄÀ¹‡#F>åÄ çéC¡±%”É8­:«cŠ-•´A“HœH
Š¢“Å/ƒ¹@»ÊÀ .L¬<tq2º F.òa¤ú°€¥Ïw~FëÚŒŞzB¡˜jÅªŞ>>#¯•a ÔDI™°¬Üåƒ3#!´W¤×ÀVgïòiMÌ÷ÍòAm–|:á5ô~©zµ»ÃöĞ!Ñ¹g÷7wãuƒ¿ ºN¦f9e–cPôÍIG›ÆYŸhÛ<Sê¦flÊİéyÑ5ğÌ¼?l´°3´ç]ÃvªQÂÂ¤pÌ_©!C‹»5ùeƒÁş®cÖ¸Âìà¶à"Îø£©ùc,öãûïñXb¢ ´ı‘±£ sÏÑ­ìF#£œ{>ù¿8ÿKö®¹şÅùÿõ§O3ü£ñô^şûE>~3>'[úÿ:ºR_åLü²|üÿÆ½BŠ„ÉÈ2õ?|è8¢¾áV,ŒŸO"_ıS<3CÌ,Ë¨Q!üxøP
çW”Ac/Š$y›Ü§¹ÜMíÓïÓ!†K£fÖvë|,Í©D®Zs´hq°ë‘Ù8yèç{£+” Ií% |5ß­Ìti²nsÆÄç.åß8q5¿E.û „±ó)®xæ3$æo3£$ˆdñ²“¯§)¶Ï,(C)‹XUhĞEŞĞ9•Í`!Miç] ±/*ÉFÃ<Í1>ÖñD2R”_(Ëg«”oˆ÷oº[1û€Ş5)š×:¦!	ëÓ(ñ,&@ùCÊšMQ¯f°|7˜µ‘Şú™ƒÈÒıƒDòóÇO>:È.ŠŒéÜñûƒäº|ŒŠFvŞOE=™»°ÿòEÃN­øÆÁùæâ¥C<uÌ{ëà5â¶JïP©h‘“İ_lÿÂ@"¢;Îg\A!ï^æğÿµ§YıÇú=ÿÿeäÿ	­>šz8•ÿ}êGä¨*f%)ù8^ >Iì›•Z|#<ïF¾Ï×ãY8†W(Rˆ ´@”Û……C–\Oü¦»ãJ!ÅÂ_ ºl…8e™°
‰b”lÃŞğÜc‘fÆæ‹]®uZêµtË©(iHítÂİÊŒjvk{¯dï¾ÛR»Üóš÷‚”ûÃ³³ @×©º½!”•—wÓ
³urSeT#ãÑÈp‘Õ˜ó¿ôbè?ß:·µbd!|<¹´ÿké€;¢Õ(W æp¡@%Â?>TUàeìa‰¢ÅC.Zì’Áæ¢e£KjYâ/ÿd¿üİ(ö˜DO¢½È¢G>²èˆ4 Ü÷x‚D^j‚DFvqœÄ×èÜZ?Qé q &fÁ£  Z
‚`sï$Ë±q¤ÇáÍZâ	L‰˜¸ôxĞŠuö¸Vá¼‰Æ7km“7P	(¡&½’(Oüé
#>¿at•DOÑF]­MÚ«Ê',ÀGµ`D>(ŠRô´#«¥æ-ç+»×¸ÿÜî?÷ŸûÏıçşsÿ¹ÿÜî?÷ŸÿdŸÿG,ó¯ h 