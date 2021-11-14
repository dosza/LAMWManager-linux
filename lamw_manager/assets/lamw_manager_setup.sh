#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3180245651"
MD5="3334643c3b8b40a7f0340a0237bd85c8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24528"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Sun Nov 14 18:39:14 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ_] ¼}•À1Dd]‡Á›PætİFÎUp=×øPİc‚´¦Ä2¿ïmt¿g5Í—œ¬Ä”`Uù£–w’ıÓ´LNøyéÅ“EÿóÚÊz‡š£ÆùúTÕÆdxiÕš¤jPùÊe³Å›™ì@ûˆLË|T‚VßQøˆ}	€6=QÛÔœïuˆ·ÀEbiÉô®ì%ÖÁ†Ë³;Ë)¡´„z¹â/fUlû;»-RÀÁ{Öp«ÿrD#7Çs=Oş}Êöoÿ•Èş)6º©ı
“hE,²OÁDt‚ùGX;´ş-ícTRÖŒ:‘şçı»éàµ´ÍRš¢	s¬×ĞH¥‡ñî—Ë=u¸T€Šf±m8$.¾•÷~N“Ÿ‡†İCoº¾”ÿª÷²Œ}ç$•§ï¼*Äòú^ ¥Âğ,a•[®·ìV?IÃÏˆöÿ>r/“ÜSVôÈ‡Ãöşh°ë
ZÇq¤iQkI›CNÊê­ç•ÂlÆU%#´=AN2ÆÓ+Eate1^IŠ-8juX|Ìº—Î	ô¡¦;6G ~m`Ãä€PÕdYÄæa)±–Ÿ»3jrÔ>‡µ|~ŸN¬e”8èxMÜ9m‚càÕÃ²l"ğÂ¦›ØÌ™x£P¿„ŒÙ¥ÉÆõºİ¶ã%Á‰1Q¿¥ªŞß2¯CĞûyÎ[^ÖıOè	¿×|E(€"42úÔÄa%º›èşş$Å¸),ï@rR&ÙÔâ:06{S!my­JX1G…Û›…~3»äÜ® sF>ëI’¡ÈûûÃH½
!ª³æ¦tÜ_ºbòİ+{Ñ§²µ‹ª Kærn”I+¢˜ñd«à2Qˆ$úêSTêè×'¿”O`?øÙ:é]˜´+g)Hº`Ï‡B¥*Ùà8şúTGì‚î¦gG˜`?À£ı9i1ø˜˜¯…•Q¢¡€pÕ‡`î™ªU1#Pj¸¬ˆ!Ã¼mşØwTeˆš\bŒrP™¸c. Üå¿KtDáÚ¥\2«R4‘Z§Ô–ÌŸ‚>†\< wÚF%TDöd`Š8Â)vj5¼=¾¨8S4³4Î—aª(ŠÃöØ›)?Ûr£«e;èïİ‡Üè=»ñe-b¥óßO’pøO0NnşS™g£Š÷B³1ùxcHÖ)I³ˆ…g4ö.ÎÉËk®bZt—J‹«C((f¦£À÷d=U¡!¼Ì3m#cÌüÇÅ×Päeè7Å«ó™êır9Ñ|y4pÑTÍ7ÿ„¿_@g€ì}–B9º;÷-³¿­Ô¤ïCË/+şc™¹Šo“`Z™¾‚äéİH¶í­_•)´kÚS6>zª€4İodVÖ{~~ü|WUöpË&=K®¡~Ò÷,¹BsbÁıo`­“)YË×ê$onÓÃ—´ÿpØg×—û*P±´ó¶¸QşİTEwé®Ò×vh:N­d˜ÈnE›pDíÎF¿\İ…1)«TUÓx£ƒ}s«Dçå9ìv—Å¿Şóò˜kö;Ne–´A¨18‚™Á(îë•¤œFW`yúæô<¦ªDqxß>éu7©ÿ˜†!>Ê0q?u×<Y†LÜÑgÆ½ÑŒ~yúf0yêc]~G,ÓoYœNkõıJ
¬#ÉÎ‡¨ìZ$'O:Mfİ‘ª‚{˜&÷lÀ/Í]·7Õ¦«~i#C«‰*‘lÙx4ü1[È<!¢{¬˜nÙMéMQ@DÇekc‡­YŠ‹ÓŒ¯Ä,Öät¢,¹ê°x$u®Ë¾‡
“,:!´3¦O™¼§°ÜÙµ¨täNe$ûCK0Å›CCB³ÿêAÓÄÔ’¨SÖ*Ä=Ş¥zJ…‚Ë1ŸÀÑ ÏÑWº¾J×<øäÓCL‡£3ƒ ï	Ÿ¥²û¦²:A‚0ÎÉ·?=¶ÃË+àsÙ“,\UF»š“|²ÌG	M}PìŠÇ»Î)Fûz.Xõ?—ì4¤oçV â´nö¢tºÈÛh+Øêô31å‡q>º…½+œ™“`(éš^ïLáğö¿‹äWy·¹m6ä›/`Åé"æÒj­Àî'÷ğBOa
™`Ïµİ}w¹sp}í«{ˆ¾â€eÍg‰#ÈàÓ€’Ée•¶”¬İwû€İi/À·*r°,ÌÿjñÙ^hDÇf
Å›üGûãåØõ@\$¬$Œë+Š/xó?¨VXÓ£æ©ïI¡©í/+£Î@:–/’Ûú$ĞeĞıªƒ€|Ôe(¡—B\·gGadPˆïó«e3£§‚Ñ0¢+u¾o4¾/d½ÏömÅIP…ãüZ˜‘e=§+øíÙË…úhvüİ¢Òœ]ƒåİéŞ’ÈUúæ„ÜDX^’*]^áhö`v1ûØáµ%N:Ü‹If6ÜÚ‚¿Nş§§'‰ ,]®„‚ï1•"ˆXjë|Ó{áÚÔ/Ñ²c`[JÏPÁ°h„gƒ~ ÜÃÒ 3Q5qµ`(a—nª‰²ú€	ã>,‡À“
¹,</£×ç»HÔ‘%Ûÿ;?~µc¡š…º}Ì±ûÛüüZæ%$ıZLíË(•jü`ÀÒãt¾QórUè¥)yaÌ–Q.0ÔÃÉï@”áÛÊ !?F¥˜&±¹åòwê½?EŞğ\‹©XcgºŒUt!_J´s=é¼…ÛaİPp¼ ˜~\Ô¿F¿ô‚,ıwÁ—€,;„"B… ÒÌúÆQáÍclë?®­bqí;@Ùı~>w'ÉŸÄÛkÂöåË`[é>v$[ƒ]¿1Ù=L‰9ÏìÃ+ş@‘¸Š.¶İr*zÂa(÷lÀ¾ebl:oîøš3¹^şYT¤SÈ}ŞÈ…áBÉP‡¸=ıšòÏë' ×£|ñ+}2¡`&áDg¦T†æ§çÇZ,_R—PÉñäÄ"Â¼m±*û+½=RÑsàÜQÊõf†)¥6G2(½Éï°;¸CuZ¹»Ò5™ªŸâ\IO¿gÂZ¡ÇA®(a2iûÄÇ¸^uq°:^’|V¯¹ñRàçn|/	bÚuòD|á¥Ã5Eër6$Æá` º´UõÄÆ°Ÿ‹	¦›"Õo©¤Øïø×iL¯²Ó:Ì:Ì>ö|‰şà±^ÙÉ4:-ÙC¶ò×Òl>“rôcëöZ»o3¯ƒïNç&£²ïôeÍ™Nª–*qÑåä<ÂˆÊ’\¨û{\ÌÅ”€Ì©í7£ÙŞréˆ‡ö™;Á+”y*¬0W›Ş`<üs’·ÅÄ	ë7»€aOMûQJTJwhÄ^(.ë4VÔ±| ´ªÕ°0Üâ¥ ©VÿãT&¢İ0íÀçî ¬G2‚¬¯—1­õ»`Yœåñ¶\2ïà'%Z È‘¿¯I²ND}ëó¹k‰,M–(dßÕ¸€œ]t§ß©ÜÄ1ZrÊ™Ó¾-Ëœõ·­\¬8…Ñí®K­*”p•O­’´½»Nè]A+Ğú˜Ó3DhHÔöuãÍÏĞİ%“Å\NşºSğ®P¸â3V¼Õ²ÔºÁÂP$îSAË@½À9®ŸŸˆèÕrm`ŞÎò¦sËªñÜL5Ô»í‘µCÁçİÆ†ÁtíøıÔ¥‡›*@”W²°í\ÛP¸>;|TÈëõvtH«ã
Û½eèÓQí±¹%Õß=»–‰1Öşg¥EŠ´.¸)w*nH«¡ü›4Z$pDœ¡ÙzÍH;3ÿ«}‰P»ß5HI!ölş´i£i¿pä$šÒ¥ß14¦S
.¥‚"ğøİt;hn\';ÒCèÙğ’Á¯à©nˆÄ§‹VG¯!²Ô8vÄùxÅÆ}U·RBCö
Õ:å¾Uög»íäjÕ§–¯«Üö	Ü%z™Ñ@½àp¼gÅ8{™#x’–k6®CN^˜ô¦B™•?ö7Ó›µú*ëÕE&üJr9Vâw“–Ş~¢eBér‰ˆê
^æ&¢@Ün<9Ø™y“w¯ z#Çh¾óSÄCÍS¢óp$±v—i0çQùõãâ±„2·ìäS°jªíb\cı„¡i-à…¹ú†›İr.RvãGŒ9Úy’:¼âÔšBeG"&ÕyBu¥ÿ°±ë+È÷í„’ØãÙ–¦ë¤F¥JÏ>İ3^Oëd—G~h9ˆe¤ÖßÓú¯ïâ¢¯&’­Änh…I×Î- iñ¾¸@<m	CK‡BË¨šÀ×¿`ŒáPä¼zN`CçîÿğÄ‹£ñU´~ÓX‚[(AN–*%vKˆ¤É§JÅ~|¿íGJŠtó´Rëó‚«) è ™ZIb,:I…ØG	¡Ivi¥d1}üÕN½y0;D ²ıƒ(ñoö$k`Ãs[8œs;ÊtÁ±×ï\ßÈ],4)hJ·Q@+yU¼B”‚÷DÙß‘cöÂ3ı¯¿œõÊ»	M*Y;.Õu‡´UA!WeoÁÀ[V#34“RSuFû/Ÿëa{em&JŠ àêT×š,ŸKíÚË4¢÷û}`KvnÄ½xm}Dîí!Û'’`ÍÓiÜÛ°»ØÖ‚ÒäÙôªbìİ~­f~‚•FıİD	§°&õûaÏ[¨Ö4ª¹;ˆ {&(ñô/¬ú]†}ÏâˆÑñíEùı³ÒØË`YMäÌŠÔi™¥¦P¤)ZŸ1bå÷¶†j’{ú¶$·a°$Ÿ¬¤Xa+%IçØ?îÑ…RK¡Šœ0DäÉ–W’³ıX4mƒÇèA,Qußô	<¦2ZiœğP”LJ8İ·ë<8UÜQkBUŠ—"uUw÷dv¾^¯…àP‹Jll¤N‡Ojk¸œ™­bÉ7fío.êm C¸ƒ.¾c*ºÁ;GTßâìĞõ1€3ª"Ê™7HHÃÄŠ&ÛÆ·°Û8È;iµ÷¸os.ÑEê¦Ôöwíì97gáã\¥Y¹uÓugËv|™¿6ı†Ys¢§·Š0î’pç`èìİL·H?~˜¢Y¡3îÎgKªØé©ì‰©½¼Ë)	a¤×ŞŸäğØ†æ. ~Ïo¿ufûb¸5GìP\?]€ì$[rW#™SÇ‘˜¼ ±Á#PàÌ‘CV)&Ç?àİyôxd¯ã‰ŸQ’TÌêÃÄ\ñşÓØr}Î¾w–¤´^|¦Û8k©ƒñt;Ì×Tµq	Ï 5Šôs™•—‡gÖz… ƒ¾Ã˜"«à]&ÍRcªpw-ÿmœóÍ;šÑC	«-5#p è‹A³¹Z,­Ô›HÏtÕœÚó¯$âûE[ı?@C3>Üç¤Cg×Ÿm67fğ=q÷Çª‹¶íKNÇ“ÍÆRÆ­}ŸÑ“öÅN–ŞE›o!tONOïEN;$şMÄ!ĞĞÑÛºÍ{v$:R×$ígƒÚ*vŠº6îNkÿÓ'ñ´æ„iÆo+oŞ	SÏT„ĞLæNïÑ¼ }‘Ğğá®Â»%áÄ?UM«D_A[áÔ¡‰Qà{âF„ŸGd®oêûÙ˜Í8øüPºÒÛ¹¼JÚF±[Ç…8ä…ƒÓ'ğ2/^¶	;­”;÷±Œ ëÑR¨AK8fÈ¸©$5E„OG”ëÒpO¹™ş2b“íùctÈš^Çˆ1û‘éG!ĞMîhÔ¹ÁLƒ
×/täsnyhè¼õ}¢ÏEù	s‰²Io<ÿù§{;Úaâ~ÅNeãáó†BÎëIñıD Å˜é-ı'İ‰D½å[İĞW¦óGÊôåJŠ½$§Õ@	Êıxh`/eóWÃ¦Aâ¹æíyÇQ5ùq%êx2òß6™â xc°ƒ"KWO]ˆılÚÀkğŒàANôI‰¶@>F?+ã3ºdë¢ä;Fñ"â´z(q’¾Fh:]aãj&HòëìI©Èç¿§6F=°&\H$Àr‹‹~:Ù“ÙÓ4ÒÅÅ4-öUÂd:—™Æœªb6æªdE} İ‚Ö#¨‹ãèIOè^†›ÎºÀQOåy?He$ñõıéjaÿŞÕ®EçåÎ~#ä¾Gx º¶Œ3—ò*‡Y½æ¡™Z5)å¯g¬œGá†À«KMÚù¤VÃíÍ˜4³´ì5Ú#úü¿dªĞ÷¨T08<ÊûãÎ‚-o1¬#zíeZş¡ç´›ày²wfÃÙf˜Ó¶CÍÚxli‰¾äğ}*øäñ¸ì#4«ùÅl&Ã:«Šôç!‰,)4'¦Mø(YË‰Øx¾„‡XáAx6øDú’j=u+HÑ¬ç¨ÿú‰«Y~şÊoäİ"!ÕE!:Ú§„Uò07XÆÊ1Ş<M‘qDÄ­¡¾È]:w$‰\Ş©ÍHôë›´l·n;ôßt–¹¹xº—MáÇ	e‡öÃÓ^Ğsu«MiË‘ ?uÅlJÉHn–-nÊ”a“ÉpõÍ0é³2}My¦Yà!:'dF‚ÙÃp.ò»^æ`9“VÿJÌg-ßxQå„F+Ş•CnÔ4:ÿ«¾gN…EãJù€·;bÑ<ÙûFdù‹å,&ƒ´¸­; Ø’¦Ï~í÷ÊË˜>
ŒÉæÙ„ÄÛ?ŒæBËöéh~ı@9Xğ&{<§A
âE†—Sxà†-4İ±ÖòˆÉğà¤ÿË4„t|+&§…§£Şïş(*?¨|İŞ’‹?¸ QÁF#º¶È,r¶	÷@Ü³¨ÚQ¶Tí{ğ€	}áá»|À°‰%Àà?Ë¹%À¡è+Ö^l±$WÿœñBrH¦‚¢;jĞiaPâŠ´€ÃÙ»‹–]OèşÊjŒl›1€wPC65µLf«£îÎÅàhÔÒ×¹ÓkV£A=ƒ-„~ÂsßñÊ#e!´_Ÿ°b2°5õÉ²&Íôàœ˜#/‘¾ùÀN%ˆMä/ÓÿTAµ_º~í´ÇÇ@tÃë¬ü“YTGšM¸b´×­Dè¾xÁç°å‚ÖËİ«âŠÃMØH_G–»DRøœHË³XûBÃ…{É?ƒaXF‹û|b	âãíœï'ŞOÃLÑS[115GÈä8Uëó/¿!wï«zVŞ‰¢C€˜ß'}L\”fÉ´yÙÑ6yKsY‰«å'C)¦wéÆ³áÚÛğÆ’ÙâÛåĞÄ£í+|~˜c Á )eqñÈ1Ù€ø„£É¨¬HV<Â-´§ƒY•’cÄøÙ*·îíšköKƒö#ß1–Q‚§ñ‚·M‘"%£šDg¦9¶HAÛkR™Á8U¶­ Û¹`‰(Œ¼MØUˆ“g<êÓÖ€æëZÒ[‹dã~K¢W#»‰ªËš/®œüî¹@c.áÉ\µÈX3Í ºöÃÍê×YÂÃÊªsÜ„ô'Î%âöI“xbùlHØ{ÇGŒÌ)!ğ«Ë.5Q*§¼½"ÎK˜7oûwê”â^ª•fŸæFÀpåy¶h.öÂè@”¯«õ	_„k†“"İÆÒ*ß~ÀJûÇ	HkÙdaÅú’Ï¡.'h…*ÿ“¥¦iIB@2ÿÈ¨Hœ9ãßËW4ËÃX?-z¤+uéüòÿ®ów°aòÜ¹d•²di6Z'äAÍ—ë‰‚tà
ø0ğ1¢/ˆXßó»)ô¼_Ğ³®„ äÃMô\vÎh~Å,¥¹=Zƒœ¸v¦3ƒH
«ëÎúé¥³Ô¾ş û¡ş‚0£.&«ø®,ÿb‡¾×zWg¼.‰i	Ll%šlÓl©£ÖéáDnâÌ–å‹Zé#pò´ÇáBGgüÅ'š¯ÈÁˆ	Ú¥9Sÿw.‡jÏNóã¢Ÿ¥gÈ0øŸFÕÇ×d«y
Ôÿdõ2”øÔ4ÿ^-•/;h†’±%ëŠ¹«„Şêû…ğÒÖÃd¬¤XÅkÓÒ*!DÜ1ÓSgôø!®u_ìçÊ´µï£OŸ”gq’t2­Tzg9ó
(ã!3ºğÿ^:=Ùêã'MÊ#©t¶dœÿ˜c’&è/!ªÄÄ/„.³d.W»éN6‰ÌÑP/ Ì"âÚÇmJÀk=ühmaK
ÔSta6İš¯«`ª'Åà#g#¬@§ïÒ#ˆ°íâÙ¥'@­IHë‰ÃÊX~İÅq“TW£ätjµ„¶,^Î¢3jé!Öß«.KàQ{¬û•n¸ÛçOpˆç5©·:§²0ÿÓŠµƒ:è\Te‚ën¹×•?§r' éØ¾4?MËxÕ†2`*JRhÙ%•Ú'½Kº™‚‘l*±á­ §p7gÙ?JÌv˜Ş]ÅGQâ3F³ª™¶yşŞ– L‰ É/5q5‹6vîûšG‚ƒÚ•IÎ”ï¿§‘=š{1T¸c²DkGkı ah\Üò	¡g8ß÷#y¬®¹ÈW0	õåZê×WğjŸ}¿ˆÁ`gi=Z½OxÌmfÒdV '9awÄ¸v¢ö% vÇ ‘¯~8ŠŒù¼·ÒfË«-fõ>xdò|¢Íè{ø·É¸”"Ø$°‰ãfnV
WŠqdàkC†cƒåà#Ê›©õ•ªYÕ´IV k#RQâÜOÈí‹Ÿ`ñ=Í0éPĞë"…úïT+’>Bhw'‚I|ü*? òæ-´¿dn	¨gÊ²%^.KˆÍR\½‹ñşRò`^WWDíB#Eº³·²å­Ğ¼‹GS–\àBXl8TèØCÌ@0Ğ7X€€S_P˜»rîHy]0Ú›oÖIbû;¦#!×IÜB”íğO·ÊZÉ<µ­Àçç×{D¯­Úo	ÑÔ^ÿ/ç@®lP)æ§Q}µaôWË©Ô/o×mys=n’-„²“Ö²Ÿ¸[—•—ş#Å&m&Ÿè\õÚÿ*e”ï¤¿"ÈõÚ]Õ‡GPwat:ÙŠÛ$!ÜÀ€’ÃºÙä˜F¦Òi'ˆ°*Õ5.È¶5æÉ	Ç?‚’Ş'Æ3°ßçŒd{­Ú‹Átäc¥N&?Qœ_»Zf3±…9º­şoí}ƒw­îªŸú9"å;,Ù^ÇíÛŠÖeTÔ0]]Ás”røQ‰x‰ÅC¢·Ö.q‰„
[Ù-4®¨ÆGÔqÒCn|öÏƒ&g”®¯eá½Ëè$z˜Q0µc­‰¢£%œS`i(p] sß¬\»Õ#Ô|¥BòŒ‹°Nf?êVƒKëÑ"êêÆ²‹$÷KTE3>Ì‡ï¿Y~jübØ%Ş¹w¡æîq™[Íæ‚ğ7
¤÷öù†v\ Ñôª»–D±q¯byyPj‹«‡ë£y×*é"ËK8Õv7W7MV½wòÎÒ4îZ¼Ëè¶).¨Oª€·‚²‹+S‚èÂ_ß|@%KştAC‡¶êHw1êúĞÄT@HçÈÛÉ÷*’É  ´JG0Ç@™ÛÇÃßÔşw.TãÇÙÿær2Ì‰õ}¦ÜÌr@Máò4áÓÉæ ˆ :Ş=îIÿØı^ö|ğ5ªŸÅB0?ĞoJŒw	ûîÃ(\&ïs9bFO._ÉgLÈ5ì°öd¿¿Ë¾i*¦öHú½¤IL©7öIÉÕpO¬ûàüÿ°†"f”!}úÃÀñ%A‘:FĞ×Wâ Eº™üf‰/‹Súj;gÓQ9Ä@^ß$òjç/UBs5|¹JŠ¾y°-Ø%qÈè°=Æ˜mrÒï¨İ'À[&éûTE°„®”½Œ:KŞw8{V¦œ| ú2ñÛ¼«´³§ÂÃ^„½m€½‚oF`|¢×w;5î+òQ©ùOGû<v(UÅ4x™FsÓÚ|G¤öâsû1ƒaEÌéê~®ıÕ,ùcÏŠ$ùô{\€0>Á^ Ş³c´`.í §?uÙI¨±±“*Ó¼? Ğ>³3Œ³½ejæÅT¤Gñ1ÁÆi‰_Ï8Ä!§0ÿfÖI_0ï™ay»şÔyA]yD1€Ùº VN¢Ú5ÿÁ&X•°m5]`š¦qì6#l½¹ÅòwWs;7J¡™•d†CsËÛåÜL[´?d§ß~P„Ü;Î9­èğ•kb(`^x=“t,L©ê×µ¼h,)*–´#øpªTøùƒ˜“K}!6aÓg‘?V<rİ‰IG¯HwKVÔ‡‘–ÔúFÈÕ~ÇßÍ|lğí×}áA1u;ÅøwË—Ş>ç‡ì˜<ìîÒIÉX¹İáÒQ¾ß£&jËV»Üùi•êòøt–_—2vD‡a¿”îcY®£%B›ã²ïÛMµ`'AK¯`<§$ºÔëüŞ·ú~´ÀˆıÆí§ÑÏ
w6c&1Îd—ÇwW"-f¹†£şE/*B™çŒ]Œ½Ñ¯¾î£‰",P“o
AV§J‘ÈÉ4>+ç/ó@fÊÃĞÌb»3¾„21iw¨›)8³ÜŸ‡»Ğ£³¶oXÁUŠŠö†t0yêñ
¡ãLeÕzgiÇGYé>9+)¦ŸëäÈˆ’ZÊw,äÅ”ãğ«íw¤P¶K¤kd
ƒÃk~2ˆúÙğ(t@-å²áUÚMiEÛ‚şş•-zo¦4GnÚ*Èë‹’œ”DÌ$ò^¤Ş‚¦o½w7ğ*ßA"½ÚE=kÙÖÆy;íëJİMIYv»pî¤‰œÅGüm9P!Œ.øzÉ¾âÑÀôóWÒjzbÆdé‚® ²mAÊ“fÄFê˜•nu/ªQÃ¯Ñ 0©#’Å7}Ş‹„ÙM8¼^HGrAŸÂ1†^!´%}otM¹ƒ…IÛfÆ1‰EÚ{®¼×>ĞA„ŠøP½”Œ:©ÆÁf¾è¼
Õ4«TÂô?r`míôsŒFé»´ä&÷•õğ lë
—Éòİ(Ê(J-!%ùõn†ŞÚ½æQà"6ûÄpN6Ó°Ës?ÆÁgKS0÷¿Rf–3Ülé¡4‹e]ó°È}ÕFK‘mÙÖC6·•¹=‰§»Ãê¼§dÈU´Æ&#
*î 9òÎÁMıÚJpƒ­}MÅ wqíŠ‘U{Ò¼Ğ»…_?
¾æK“p¼›0&†,Ü/®˜ØÀÖîh¤ĞÜÛƒj¸€8e¢'Jõï0›š][èÃ¼oö…TïV"ÖNÓûş·Ë¦äN4ˆ-¼¯Œµ4iqO)0üåÆ;éÃèÄpûò)vÕÇ«¯Æ%_¢ãÖ)q	÷x€Ô91Ak
š ×­^"nxFq oÜ,<}gßÄİív¨°P¢´p-µÉ_>Ç¢;MEIĞ…#sêMºëéf½ÛXJ¡:vR„=<~óÒy]èr¯ÁÙ~
ÁÀ(ËÅ+Eb ï1ÅH?oÖùÏ‘b…[Ñ3KÌ	qïsì©X8ÔjV¿Î:·û&¬Ö3ºİV<WF;ÊŞ@ÄËvmG¯3Aá¬H†«úº¯VÅĞyØÊ›IŒÁ'ïfZ*;ºÄ\Ìü­ ï
¤¬z ê6’¼1."Úãüƒ¶­~Q8Wãª[v±m-Ö:Ìò™Z¬Y_X«1­ê]a‡%Ø:-TA Ï§fu…˜?’vÅpuä}w1î\wï1¥ä~Ä§çpëOw:}ÀuÀL€×ôØâ·Ç˜€`!ÍúV/ñèè¢¿èùÊpÆyÌ˜Ç¸CÂ2³®ğªÒã
Pú Y;#Ï,$HºQÄÍÿ?'·ƒ~E™r»œ*7RñÎhR×P´b]¤ûÏgïğ³Q­aàÚÖíŠh¸© ¨ƒÂ,\¶ƒæÌ?á„ QQ@cØÓzK Ê®ÙmÑı¿pÆÕ»³¶Æ¢8A)Ãá&Oa’W±Á¥|«˜K$1]wÏ7º›48	ô(sv¥%wGĞXúš#•@¼ş¨IÂVKëÁ.MÌ\©¸¯ÿ˜Zç³gå%m„–Ÿ“Ş2oÉ¹û’ıÑLqšRNğßìÌ¢5V ={‘— ©;|’n`Æúy?Y˜EWè4¬²àÈªı|MŒÅÉ@(VE9¡ òxëi_ü«·RÑÚR-ƒ{2Z0Ñ\c¦:1_Á&jc;”aw[Ušœ­`± J@“’‘ô‰¿¦9¾gàôğªŸú&£P6À\;ÌÌ×]Š}z¨{­7´.©lşX'6SÌÇEı5¹còş0÷@ø§ë ç|”ûäyÿnÈÁ]µÍ%—iíPau4ÊÀ{JV‘çÕ”m÷Pñ‰GB»”•YipÖ€E§ÇrÇâ’÷¸òÙ,CÙ•Í^¿ƒ
[ŞFÂÚfœ"œ«4
Qâa¸€·oÉÊ’jİøÏà\ç,ƒÔKÆ.ïı{X 9ÜëŸû²Q±N32RÌRÜÓã_ì‚»R8B+ƒK¼óæe¹u‘bIS8€œ£cw³ñf©¹ûïB”„Eöõ2'lOØ=ì_)bè‘±¡kÜCRrp1/t@¦$KŒ<{•CíèL‚¿p	ã×yûDÖÃw°r9ºà…yCàjï¼ªÎŒiäte8A	ŠL…¸ûòZç™h·˜‹—şè|NGÆBSµÎ™äò`Õ8yWe23èSÌ¶˜aşçûÙ5ÁsÆ9ªsgsGüóšNöÌ¥’;%ıvV0ô´¸$C¿ªU’¤”è£Â4ªó‰ª” ¦‚?:rÀšv®uQÉíU×4t\å Ñ¦ïñ6¼bà®’ñb¸³4Ø·wåêİ,Z¬»ÒQ1†öĞîìÌø,Ì~ÕA;¡Ğ^!B•%Å”Ÿf¢³Uš}Š]‘ìa,šë>™ƒ°è$Ú¥u¾¿â™¹0Ë˜¤!¸€V!·’ƒñİSbª¹öIr³wH.Ökä~•cœÎ§…ÜG§äÖgíÅÂ\uBEPş=OÄİâ»"¾@4œ·™c¥6¾wı%>JíÇ5gÌ\zô—+BW)Ë 3LsgÇÿÔ=7¶®€8@7 nˆfqfÑl‰ëÑç÷«cƒøM¢{FAt¨İR‡vTÎŒcÚ£ÕµFÈx¹Ü+QğâZBOAenilÜpŸB4²0¼£ò=JC·'şy(ànÑ/ÎÂø}ƒH€7ñ$P#VÑ'ÍÜ§)Éfm;‡ézÖDÏ+IÊ:7CYDä=ÄÈêå”§-a¨éÙCİ|Ho³˜š6áœ+¡ˆpÒ ;ƒùú“%ñ0áqˆ©{*³úÌ8t	#í ^¾\w]»NªG­£zl±S4$SP5£O~5í@ê¡¢éÓ¼Wÿ¦\ŸÔî	PúÖšáB<
«Pu²œî~'D6ß]`2owå—ßZø	³Ã©ğ*éyÕ²&.D w-#/’«”“yÌ)ïbuşlö8hDùôqˆ7feB3zĞ>¾*“½!]¡ƒşúõë"¬İK„­ßPg5“º¬'­«))Ë½v7Šÿ/2ÔÂ`›ÓKNÌŠíoôxR5+›çîÆÑñ\€:š
„ß_=[w‡h;(¡ÔD­„0ïûSık*"ş]´‹jõË›¤g±	 ªA¬„ÊR£>Bö	ì¿‚Ï¶ù…¨!(Ÿ¡¢ğ÷¾–1„%õúT”¶ã¬w÷
+ËÀãZIÛ/:uâ¢DPPò¼å§¾»¬óly’[,¥#/Œã·=¬ãş±‹OîLÊHjø!|ğ#h^8Ñù± †tšw¬¾*é©£½·F”23¨?Qi»oĞs»xxÿ¶Tì:‘A¤…@äÃ°Öañy¼»1O“b
õ‹y€!³]evìI[TxáŸ}¤îÂÁ*Œ‡ZÎ4­ÄÎA¸:ë;áÑ_úEKšö.Ç´¬OØ•s’û<eõ·ÓNÈU'B%zÆ¨qZx£¯(şÑñ1[­r©‚S€	óHjı[ˆQ«¡5Wõª®Ña6^´ƒÈ²£˜ÄVQ€+‡mÏÜ:OÿøA„¸wDiº9/Gù	ªK}Yˆèñ1“äêßs‰ó‚Ï<¦™X®Ğ[²|İ—õúõ¡Íxğ|Y)w~Œ~Ş–Êø¢Ìëo|D/Ñ=°ò[şËìVÊÔÕí´‡ÍbMá0‘C™EI|aß8Ö¥^®>eöóNşoc‰ıĞrÔÈãŒ^öt€bÜß3½S¥„)¾°}ê'ÑÆ¸d¿F-ødgº.,ı‡œtÑ<¨,´˜¬ÙºYHaÈ6j15W'Ü+ÛBEÜQXÔzadõÛl§g„p*1«Š4É˜şœ3!÷XYóÍd«DP1s€˜Ç%(òªÔd†;õÈZ0AjwUËø¬«£ß»x®ÿÈ–ü‡úl!qV_SĞDŞÉÆÒ¨©R6_@ûµÆ>\¯Âò!ĞQ¥¿cüÌ^ÚSå¿yì6rĞW›%á›µı…C(*ûúy`õşeÁ'|LgÉÕuøµÂm|+B×Î
iók\4üqõT=Ì\âî\II¹ç$:JŠŒ'0È9Ñau–Rú½¹ÁøÃ¢!ºˆP=Ó•S üøwÎİ„BR¡V¿Dg”.Ìu Ÿ…ïßrg˜zº•¤§*Fk†G€­ŒÑ5oaí3s5
úÁ2óñì¦%W´-+m-ì÷9ïæ™+LÿÚŞ×¼]Xõ/P¨Ò~¡ıÍ†k‹…l&¦;¦øPÖø©{~dqãöğÄ/U®G~¾ú¤öp:(zn%EÖÚ¢V!‚¶âBX#‹«ÖO¬%%Zá¤+z¦‚¢Sä£gÑ-×“œ$£¼ˆÆ‚røV£+zšÖ$ŠÍ–)¨YQ`Õ¤`[ò-*>|?ğ™ =‰·­êŠÓëÒÒÍ>ââ£ ıË8jîHÒ½J|çc÷¬Ğİd…N´§AüeZé±—ô(Oz#dpã©â­d™h‘5:ØÚZh%Œš€HD˜†rÁÄ-„¤§?ZûÙ?È¢}5ë}4ƒö0Z<‡¼‡›Ó7“‡´¹2š^‰-ş¾
å¼¨Õ<O[îdc¡S/ïhÁa~éÌƒŠ×_ZÊ2âuétêÏ¬<˜–İ¯ÉæË`e12‡bUˆUºò¿Á¾U’á¤'­’ qéËh–ÏYÛE~T µÛ "&(t0Æˆ·à:0é(éÒda«ëùøÈ¨d–-ìĞsÙ!z{ïÿ íM-ä†³¢_òÍBP›ÃfO¦^OĞi\K]ê×¸Bø!b&"NOMÎÎÒ0“ÜòªCüL36.Y
éc/åÂU¹Ø¹hÇ¾³“ŠÕ?²Ì+g¶Aå7l¤£ş}qyx ş—¸ÑtvÌ+øŸÏx£şr,#©z¬Æµ{İCajuôUd„·¡Z<Ê¯,W†ÅbÑ°uD#õûƒ…~`T9æÈ–4K•0¦†ì,È³ô¦+9ã³÷;ÛÛHê	´ÆéŸ›öèzœÎ‰ú.¦¸Èã:î¯§‚hp(P	ktÃxÖ'”ÚHKTvÑQGÔÆt-“of—± õU;+@x¶"0åH¸j<NâFèµ:ÕŠ
UÍ¦_bgáÄá9–õ3[ôb]7}ã'Z:'h)	ËÂ¦/I‰¦;OqåâpÄ`C5Ü‘DëJ-³bş28v…¹ÿùÃıÎ>ïë$Èúè];}1
ÆàK-64—$êİM² Læ>÷äsÅº¢ú’ÌW×’Õ\“ıIvÌ….äM5¯¡ÊH Åß…#LLè\¢§J‰zj¹rº-ÉV.•Î÷xŞ—°bP†ò6â˜k+}øcD²Ü/p¦9ÑG;’/)ø!YûgÄQXól¿tYÿÔYÄ8' ¼rÆ4Š·÷mó4ÈyK;ldÄPiJ­b:Ëü6úøGØ÷Â3ËöËÃÑ¹dÀêFÚ 2¡ŒoßU©(jHX¾Vleı«¼Tßeë|ûIO”“EıéAM¦„İJ;å4×ı@òUT6€%.~v“ÚÚ›vÂb Q4êOòÈ\[—
KÒé«#a±.…xX0råÆÛL†ç+§€²bi”Rä¦Ã“ú‘6Tyâºñ{ÌÑ9ã…éøÜ¾”KìN`§ô¼ÅD˜$73¢lœÚ
Ü>¨i`àûg7:pgp1QñòÇhÿ¿öåpC'ä`¦}©öú$íl|«&÷ÌÕ_EİtLæ¾ä÷_Úm~ƒ¾×”dÌœœGªW µÅ'¾¯JİÏ;á³ãk„1-Ì(¿Nª’
¥	xT¡Ú4	¹|h½Ë°íËs¿PâØ7âe)ıúä¾ ÒEßÒ½"`QÌMJµí v?%rÆ"(í_#­·lá`ÍÁ@;9;¥©Æ¼3ï™P)°´ÏçŠdQ/‡gn®µ
šs3$7i­«:*2fâFk(0;“`¡²ttí±"^Õì)¦ôMô¦Iü~¾¤¯ë=^B	ñRW"0´«…igL85ê§­¿²‚ÁI7”åòuëÂDÒ5ôû¶ƒÁsŠ„¨é‹Ê½¿Yç%!SÎ`¤1çÄq	¡®f¢—6}XãºğœÒ6I«Ÿ®æßãAYFŞÈe÷õÎÈ‚°]%]íR‹± rmcL;‘Nğ<¾ûAk"ÊĞß(*â’Ó©ãrS³$}åßÂ}4KNá@6+7†ÿ';d)\Ç8 S]&ï¨¯’`ÄfR-5ë’PXÂ§FqV‰ïõ²ßì‚46¥õZ!…u­cÅb´¦ƒ~¡òN!£h”ëšÑKZ£ö‰¡EWóÈBîº¯N"µ=JJÍƒ:_•'Q’Îè
vñqiØ´ÏĞ.è-÷k£X”Zh©9õçËFmO¤;°³ä®^ùÕ¥4œÑEÙ®_±vJlEtÅ‡À…2UR7àÿdÑK/M‡‰ìn+äëÏÇ:ÿêm8eMĞÎQë¿.To[ÜEÛ=¯ÛÌeCŸÅ»"ÙsÅy
ñÎ2:[œl¾ÊR {+¼LÈ§5ä]®9hn¿Mñ™õïÛ9J˜uîŞ*«yÕÁ?‡(æØ„9ÜÏ”´±|da¡J]’X%â³èOé-Û!Aá×ã€õá”Ù}Äy—¯L¯~SÁ‚. JN¶9!ı—>G=ò’øIZ'ü±}êºÅ¸fT`»ruZ!	­_Ò,ß7N(#'÷ø3ßœqSlrØ+—(f\m‡—„›Fß	ƒ¬L¿‡	õ’o¥·‡¥ªˆ“Y—Wb•oñÂcß?Öº¥>· ZÛ^J¬úÒ´ 		åŞ#õÂéòˆqğ›ƒ—7F7.G¶Â0è~{:te«RùWøxÀo–*øÊ.M=äeæÏbÚÅÛpl@ÃL”Y1O'hÛqÇX‡ˆ|ø´Ùt»š¦©ş’IòŞŠŒmzãÔèu³4kcæ¿Æ[M8ü£n.E°ñâpœv±€…P‘ûp„«±ş×¡¿_ÍÉıej¶¥©š¦t>ƒ·®ú;s…ŞÕéS$¤Âplä·	ÄWNŸfbõ‹Aä"“BóvM"CE–2}~¢ }Ê
CtßĞ³–¨š;‚>ù÷0rÆ)ì˜¬ÁÍ²<ñ)Xy?B©¨j6›‚¼ır^¨ßlı«ü¹Îçü»44#0è©ı‘4í^L:%qÄ»ö¨4Ñ÷$8=!ˆP´ê! z×N+a;D,‚¸wç{Ğ/ôŠØ“Å?X¨î,V‡ŞÑÍ»€µŞVÙ²M^6isœhí`Ş=fşEvSø(è(¥[!.Eª E*fº2œnO÷HUÑüErC;²ü*ä­/ÖûHÔ>5€Îè0z7M¹*¤<«“É
¬8ÖT&ˆMÚ,ÎJÁŠ¥û¼{·xõÁÌY¤íîJ¢Ñ ıx·l;œÔæ¥±±W'_íà!/«ùú?qór¸\)¦ÿ¬Øñˆõ|×	¶ú¾ìùy«"®Á¯f8®ïˆ¼´‡¹D5ß±všã+÷¼„á]N ´|n›*¿åŞq­B}7óÉü¨‡˜(„yÁé¢[hı¢{u_w5„EˆŠÌ²Z¢}Ê°†êB4F±`DiFâŒ'ƒÈ„ıI5,Ù\ı‘íD÷WSp&saü&6ú~v’èÎ\şyãÊ<šÂ·üÂÊ$p´«ÏŠ$ãgŒÈX.zúycBÓ³¯±÷1¹u’FNvêøä‰òuJ&Üäşc—İjÓUHÚåî9›:ÉÖ‚8o^¯H9íõ+Òş8ó~_fvªä”1=Z`RÀY¦SÉ75ƒ:ØãhÆIvã-¨Á‘ó}ÿ¬[÷NXÑ(‹×õbÄû¤zşûsŒÈtx»İG5l°‹s ¦RÅñóí¯2Ã_å'>Åvæâ1'/~yİÇ%ä÷2	ı€Æ‰b6%zŞjİ—Š9Û R¶O+@7kæ/¢JÄ;gíM18Z‚­¨Ûó¼³ÌÖ19İ5bëëÕÀÅ“:1)Ü­ËVü-qÖí]ší½•k·	 %x<š–¼] ?æ‰œ"@" _n‚	µw«ûûx—‘ştpÆêÌà08û<M)úrè´ìk·µ%CHŒ¸U>T1&åÁàÆ@ò
[Î¥£62O¤
{…ØÜ¨éß{©|ôjeĞ?ìºIâKİÑH®ß†³m@LH¼¿oŞÁÖZ*E †tíWòº¬´ø9¨×:Òneí4J ÙFdâh„ıu±KuDJE/6Ç)“ş;°¿Œœw&_—)ç A0xnv|`3ĞåHË¾šx¾m1,„)ÿO.‘¬w‡¬â.ÿCü³/jÂjyOI9PÇ¸BÍŒRØÖ¹ŞZƒÃ\ÓÄl•ªû¦‡¬7?Úo©ZÍÈı“ûùšs&©YOiÈ6=–}YßÀ¸i›ílå±Ü;Á92İ±QÆïüÒ‹!~[şvP6O8†ß#½¬³²‰òlAÎÖÍ¿ròš,×>•0ª†	"Yí#0˜ßÛ^îh0§¯ D¨#s×÷íèPŸ·ÆÉ[g–*})$Œ’ƒ¶j`Égî!iá£À¤˜dÄ'L.]J©3Œñ³)¹I(Òá/{ÿÈá§uÍyƒÄIŒˆ–&¸ä9ÿküÈRmşé†;2æ/Úu‡…ĞU©&R½"õœÅº’3–¦›MRs¢ú®Nöö»²Û$æ"Ã“v¸q»¥X‡sT¤©âw«w	·Š *&|yÌÍ†Øi ‹ø®lÓEƒOßg4ß©Çg:¾ßp>ä¸=ñ•ëOû­Í™ˆ›İ¨ÿüƒ×=I~T?´ƒ­Ø8e©íšl.lr¿­Zr¸c²Ì ÿ6[ÎÇE6y²ä‹Mz6©’·“EX¶\=B±0ì=¿å³ÛEÎ“ÂPKw¾ú–1!¥IØ\Q·ş@uâ·£0»±î”%ÀŒ—É«/Ğ´Ï*¿}TÛ/wŞ>b«ÑZ¤–õ†Së¶ä÷áœ³°!Z%y¿Ó«=*Ì»3ğk-5’¿ìãh4Ãø×Û×¥	àà„šA{ud€µÓyåK¢ÓŞH‹ô/ßõùĞ„+?±'÷
;ñüäë¼Ä@ÜTPIÛ"ı¯cç‰ĞÜ=Ry[nKªÀkøüù!P¾E‰±>¢œTEş®¥§ğ‹`.A<ìC°‚|	×í`"$M{Çƒ•İó§ÀÆ?¨kÅvB ÷‡L#sØÚNÍÉ~O¶
ƒÃ
)ıfñç½2A6¢éÔ[”š':ök¥…ÍÓOm&·±ı5¶¡»f¨}SÑú™Ÿşõ¬,e[©mm|!ŸºŞh!¸˜°ê›ü¶ĞÕ6&–­Ş$’îªÜ}Ç|}ÇpÈœq÷œÎD¸
†DS©U$£(¬
{´sÔà<vÆàôÓº8ÌEø}İx9‚p'İ ¶Ÿ/ÑU}«Kä2ßç¼Çä¬§œ¸á>­4×‚ê&îµş³rÍ&Ù¤mŠFJ{Å†E§;¬­KANx:%tHN¸#&®È€LÜ‘ÿS0-kX;W”zúD>xËzâFi±¬¡ºVÉ?gÕIoÔx‘
ÅGŒ†ZÏ‚<ìFKZ{)£”œ µxhË:3{¼Câ6LW†iÂí¾¢òN™Qzœxä]İí:]éf¦¿ÃÙÊak? öÈVP
,”ˆÁ|Àìü·éëİRÛôê1.j«Òú¢½/.”—bNŒf¿#ÒÆR§È1NÒ¬Ÿ„©ò®{ØµR< Î5 è»˜…éˆÔ)ÇQï°33=Å‹Äùï.F\5ˆ=}6,ÁÏ,™{è+ä†¥“QÑÉsË£f¼bc‡Š¬¸¡à’GÇÑ`ärØÀŒI°öÎ\•P:C”ç³5ß¡şšV–XxŒm!SÙöÛ0¬Qnh¶ò÷«¶ªŞÆ¢#.oöiı•5wXÅJy|\£ÆuÔmDQÈ°Äàûc»æp.**†	ÆjÍ–2ã,²sæµ›s¿_/‘KyÕïO>2·s›l$EÂ·ì‚r·´/äÅ±—)6“ÓYùéÚ%=[ÿ,éh’´Gòôy3±´wßz#N€WÀÄõ{$@[n[ÆHôI£áğÙ	ş+ıj!©õğ“‰ÒÉ-8`vb±+äØ,¸ÄØ$k$&ËŸhXU‡1dıŸÆ'¨…wlÉ§»™ìW/i•-Iƒ:#â…R€ë#©¥“kÀÙœ17Ò\+˜$k}¥8ò–,ò“¾ú—O Yw™%¶~gHŒdr—/Ì$EkgãªúX¸Ö&„ÅÕN®0±&²J“­/1;”nÑ|ÚÑ;8evˆ¨O*<m>˜É¤š–+^>-zİ¨L’Gåt~³å…|.Ñá÷4Œ•àpŸ«Ÿ	Û‰…õ ,, íäª¦À)ğPÉÀ€¿%sà¢:S*(41çºëFrƒÅ)‹îÚu¿|gW¹m×J:v h¢ßo>ËŸ²–yTxøx’ADb>3p““Á¤0CÔİY
_²If"æeïì0uèà üJÏ!9Fó}sÂŠóaG+(*&Âwh×>Réj'j|Ûí±D”Y€-!BáÕÁQy $àæg.¤Æ¨W·YÉVo¾ìê®JZ¤–e	§Jü—%7Ò¹f×¹+÷zlOqp:ƒÙ’zß/	Jÿs„‘U'¸İ²“ğÆ=ì  ¬ƒˆ	tyn¶Š/=	WŞD‚´ö°Î ï¨$ÿ}fÑÅu%Èr¾ñ"]ÅKÉ×Àn«H+ãÚ½€¯u›=Ï³¦Ã“e^º„Şedü‡Şš§Â:äµ•
Zi·‹E|w”ûm*Å";k—¨±¸ZÀÿŞV¶Ÿ[>R,-E¬ßé+n¨”8ê»³5ú Æ¢¡
Bú­k¤”î6kÁhqh&MâÂÆ}'4ÙCÌĞÉT& ÉMıĞ~ÿLŠN‡%ÖÛ5—ÊpI-ğò¯üªÌ¿İé}ñ÷Î®V\2\·íŒyCá¡ê
µ¼+î¶÷‚2ÓáÉ	3Úv¥Ù©{B1ö^ŠêmĞƒ½Ì÷Ü|Ô2å	êçFNeí!;‹úOßû?‹)+ÈõÍøt@Õğ_ª¦ÉÖŸëÛ¹˜+7ÿò ®³m´ïŸ§vxÕ,SXå¬¤¨ND¥ØÀfø
Ä…×!Ï–§æÑ@‡›<Í?Ç%¯˜ÇòfZQfã•Ñã›°)	%ä…ip¾öR>2Wd·¢3u(ÉŠKsÜºCN˜¢ü),–¥$… Q]È»ì-|Ø	]ı0*”Ö(•>M×ø
7›c±Ù-€Vôí¹ˆ+l_ ´œ§C#á4`OußßÁ–hQÂCÍ#ANSH¯êæÿ­x÷:èYó)O›ò»€1±Ú¥¨€+Ól4^\ÚhSÂÁ.IèÂ—…T>x³J5ÇDğîäÄ¢Y}µ]O×.‡×ÏÎ0ª–óÅ`ûKò$ÂQñ„“#ÖêM¶t`œŠV$R4ê>­X“çÇÊ+ô5P?Ü`ĞÀŞf³&²´÷­ppQÍô>ØÀœû‚ÊÁ(ªı×©Væ«ãÒ\¸9gJJÄdÅ¥!7;y
Ç~HÔ¯É­0cæmöáå^e*µzïD•{°9óQÖÂ¬Qñc|È™`ÁñŞpòåVc`ëşUíÇæw2´¾¢zÒÓ&dÕŠ .óØuÏ(/ß¤ÏQÅsn9V±I¶,•X»æ»L³@%%qggÃ€R÷@@TˆÖd}ÜSÒ˜ÕÃ8!ÑC¡¸-_?Š€m8qâIW{¤„œhxXÃæâDy9ÙMsØFZ2¨‘o¨e[İ¯Ónßç"4Ú]‚ñ…1£Í9TŒ™O#O&N3Øˆ73È+„_ÔºÄK7ˆít·“D£ÈÒu@ø!9çjVh"25‰çJÀìæ×İ¥oó½
…jy¯ÒEz¸;­LÀq´üA©·Z8PÔQºJâ08¥Ut‘«=Ÿ#TµÇš'j$×5èàóû´CÖéR1ÕâK§Q#O#c0n”×«“HÇ¥yåù)ûHú7 k!,l	1ìö{höD½YÊ’o^ZÖ0Œõ(Úş´!l¯ª\LPY\¤'*úäİ`¼ÖÆÕòÛÜIS`út¾O†qH/û¢©Ë-ŠçøóÀ°“ÎçìX~ãw…&˜’[œà”NĞh„b‘°îEâ™€JXª¢Q8ø¬ü†Õö­âøä56w¬Øy`¶ıÎLş¦Llöp¥bmL‚ëûˆûPCüŸ{×½PeoŞšb¬©p}†rÂRO%8&¢¿ıâSM°n{.>÷l÷^Pé/ÜÊ”º	7
R£iîE-³Qÿ:/İE³ß»-©Ê‰•!_@ªßí!Õ’¢Í*Êˆ”¬DÒ•ú;ûv†ì)‚ÎÑTv>óÖ”ĞŞŠ­áHŠ´9[ÿ«•¼íèÕgØ=¦ëQâf8
•i¨;Ø!ÿ,lM1ÿ°V¬yéM®\wÏ.$]íásãM|<.‡Gâ<0…Ëê‡¹Ú<Næ#?ÊbàcbÈßLî¢©¸>%GœaûÆÛñ÷«79òËÉ2î¬~½Ë¡;Èñ§W¨	°JªÆq…–<!š¶qnïÔp½¹TwR!¯Qã£»z ºši=iymœ"¹rI«©"ÛİT>ĞÛi“õß½7ÚÃ„p›Í‰™€bZ­;±Å™fHØ•RÒŸEaû‰„òÒ;Ó5†œö‚ŸS2 áíeL»‡Ìo™ä1$Fäç0ÓëUdSÉ)´B¡’ç…ÈÕ¸+|Œ9ïzhW:œpşµ=|ÉÖªÏä‹:)8.œÕÇùˆE»ÏËoVßàÛÓ:Ol.àPI5ív˜°åM%mmËxbYÑR/û9Ì¬§efÊscV ²øÄ8½uk°|iûoYûo"7×ŒkñĞ êó1T&ÿm"4{€ amæ,¶»a¡'QUÅ/4\|ç—â‹œÚ=:óâËâ=Ã5Á)Sõ¤Ø¾Ÿ—û8}ÛŒ¨İm¿…#-ì%lcŞjZ+äÑ:?Ø‚Ó¦æÛÄO}Ù6«q<„u„€}÷Œ$—ºÙàFM¯²–á¸,• jëõÛ3]v÷è«œÅW×ìKî†wøgôÚb ":š€2dğYrÂhwÕ\rE½pbj{«›œ»ÑÜÄş”
¶tÙ~JtBo
V³^EcĞË]]j¯º1	nÏ¯%ËX5“GØÚNÜÄ‡(•lh[Dz”Ê‡Í'vËÖ†Äó–A"ôÔ ·9$váúdœJíŞÁÎb¬{ôüvbòŠ¬¥…›ävõ‘F´ß«·ÌŞ©šâ³(|¨áë²¶~;L‘tj÷5ï¶ËÙªÄÅ"«\¹íçM€7€¼Ûİû1Ó™FÜŠÙ«#‰ãía²\¶#P•è¹/U°¬6ÄWûó“n.nFz-ˆß;Æùş{Á¨~õÍ%úŒFşGóˆs¬Å{»‹³ÒA*C„!ŒÉHf¹éŸ0Jì÷ŠYm„ıËhf´ĞæñtnóGIŸ±‘½§‚/ù«M÷™ğEùƒPŒDˆb
,«îœ‡ˆ=Œ¹¿Ë&ÄfÊ(‰?0œ1WAµä ¿[A:S¤èóÑQ¹ùf½ñÖ¬lv,”€«ÊMè]ì=O#ÕHFUi=G€Õ´b¼¸öëG”Só4Ÿ—:kz^m¨=x+Sv4X+.jK©¯Ú™600&$/ã·=kˆo0jVnüçª¹Nåø­îµ‡ÜïÆ^Ì¬él¦t‚àDìkWp“#¡Ö)WŒ½º¥!"µGâ.×˜!Ñå›¦á$ÙU2ZµJµw³XÃ§·Õ±ôˆÛÎQ’ç‡×%b·˜¾}'…Sö,ŠÛ«}·Fßm<‘”Ğ†;2¥uê>şgìœÖB~¥ÿñ«æÏõ#7¸mÊaìXrˆ8 T@³|Â_X}‹¾|£ª*¹¼×}§ioú× °äA&q±ÿ\ê—ãu-ğYép„€&’è‚(Ú”£Æà{¢Ïìó¿ì¸4-¶àhX÷„KÉ¤UÎ(GÂut_e)*Èrœ–oÆ?~ÏÚÇ×€[!¸>"N6•ƒìö#¸­:iíÖgúÛgbœA²Ê•%èúT5×eGU¦A¦Ÿ×V³À¡¾Nº… C·pÓX—vaÀâAÏğ‚írjºô2ã(£"“ÄÙ{&•j»7mşÅş’¼'ù]^ğÒ+õ™Di5” ÚÂÖ€r(»Šñ¹W+„ì°èvJm¤;~«¡ZO°½D¦­.!òÌNş ÎµøÅ“æ(‚±r>]YÉœPZu(wê¸¿7º:ñdê€‡@üû«W(™±õjˆÄ>½m³¦±J@7’Ñ+]ÿz¥¬ßsn²)c
ã;¨:ƒ¿á×ÿ¶ ±éLY/5%È&|2#•…˜«¨vªŠ6Ş/µ¸ÀÉäU ¥ZOaï˜”Ò p¨ø*QR1v&\€Ù¡“3Q Õ‘m”Ÿ"É¨^uÏŒt¿Z&³DÅrŞŠÑ‰gû:‘bR¡+RÎdK¢fÏ#DÚ„TøÆ¨µùx©5PËk ŸÀèƒd›êLş!
\[eRÂ…ÿ^µ’>ß‚TºâÈ–8¬³[Ï)ç¨i8	ZUzë¤nãÖ-MÌêË¬ªH3XåÅšo¢§Ö>ŸâUí÷ZÙnà·à„s:oçy-'Î?ç2·{¯;±';TäSS·Â‰9.GÜÙı3 VAø‹M{3¹\ÏõMZÖ{7Îèp²GvÂf+œÙëdF*ØŒ2˜a0ü­å?…tWùëû¦…æ²~q¥¨z”ÓÂËÇŸÀÚF‡©fõ‰Ê›ïV)5&ú#h<3î$Õ”ËäJÌPh-Üöà=o¶PèjÖjí?ìéùİmÅïp¡»™~Í€€LI\Šó.£´tG‚$è9Ü@‡€ù9:“Ş,¾¡¤-|+^ÁNÓ´b¬ş‘İÍÎ¡U×Íœî†­ pS#8hŞ)ÑÜ‘ÄÕLê‡;pá“XÔ}§à¶3QUçz[ã ®õYˆÜOˆÃêÕİb@æÄmÏ‘ï; “ÿSdq¿q¬ æöŒEÉ¸—ËÖ(sƒª²ö³XBFp¾9°%27@‰µåTq8±n™~hœ¶°Ú<‚–òÎ’<†'—K\œìµ­„0 ù‡¶†~°‰Æ¥x2!èl¸‰˜a­xõÛæÄÜªˆ”ÂõáIÊ~¼mu£ÑÕÛ+Ï¡¾ï¼v"Ë›“Oaô@|æó>ëOQõL·=—“ŠØótİlåï`Z9J9¾O¿¢¼hyÛ»•ğÁïåõa+ÚÅ|âÒÃ»,(ÚXe%	Tş°¿Âê‰*ùf'„Ù•£èH'¬TĞ[±Â÷ŞxÂş"§V‹%ãtzÏc€mÛ'7áÚ`ÙIÎÕ¨ú×8‡¤›<\Õl›€–“Dh¼£_NÍõ„–CMT#ù.ˆfpãDÒLbTsg³ëûoLA¶·?ä4³_Ğ
ÕØè52)½zûv&R‘n"†Ü°NÀæaRøZêÂ‰Ùûúna$-=Ó†Ek,ˆi+GÎãGVûÒ%Äxğ–)ŞwÅhXçssÄQbÉ$¬Û_«aÚú·ß˜t:ÛE¿6É'rQ!QX/‰ìG¯q0qûßœïU¹÷ÔBşm¤tÁÖĞRp’ÚĞ\ºŞƒ[Ÿëš™¡!9<ä*HºïÛ(`ïŒÕIjÈcb¬¯££+ÿÆpU—Â,«)Ô87¦pzRü‘$Ğ?:?~Hy5‚çåğlºN}úi­.{ÛZ#Å˜¹ã••ğûël[×Ücw#œEQädŸ=‚è²3§“'¿Utp1òì©l&ñäJx-Š'æ“aÁƒ‡î:5]ag˜ö–¤J˜Gå¹Œ#¡Ø³¶sAŞëºUí’HÌ
¦Ké_E`÷ã8€gL¦ßè¬f}‡À#E[²èm wsrwıœ<¾ŒàçU7ÇK®55vÌÿ¸Ş.ÅXu/ãš÷¡¬bQñNÃşä¡:å	ùñ~	ø]Ê j-*ı”ä÷U©Çn‚;†nE2h°3'ëDÔ)_xô¹ƒGÇâ7pÆ-(ÆQÁà	W=æZÆ";Ÿ;Ò	{³Îl¿­‹ôD ­fE-Ì¦3KOòK×Š¤\Bï¯ZÄ°ïğV¡ÈÑ&ƒ¾4/ìJE"ÎÖI¯	ûĞ"bcÙ¾.İÒ°,—(ë’oÓ&»u•Ëòì€LïÀñ³|Ğš3So}9û¤tÖ€Á<Ü ,}!hT]şè­@=éAÁD˜ZDv2p¹ä‰Ù{bë•©§s¹„4Qm‚9JYîPï–Û3†7†ÊÇÅŞƒ6ÊwK€Âk6É8z@h}«\ËI,)ÏO-9ËSã&³ÚÿŒ=ŸNE¸qeö¢m³º‘™¥ìÚYßš™'>[U´Ò¿ê½˜Ò«CÚwÄH*Üy«®¤L";c¨[¡i˜œ¾Ñ>Ì¦ÏÌÒ
¾*eò-ÜÉ!Â\Ö¦I,ÿÉ’fÀÿY?ÒJôìFq¶Ÿ´ƒöV0àx}ÎÒ™u‡_`«]İC”'(ßîùQw¾+YDO$+¢
h¶]'hÆ¢g¼ÛÕœÔ=‡Œş@ÙG
…ìJÈ[2<‰¬€ìx§°òc¼Ùúÿìóÿ¤x<}Ë?‰T³¯P´î˜5¡œş®)rÁPùùrÔ‹…‚C´JzÜ:ÌÄ¨Û_	uÔcáKW->[šJ
”ë šÉ‚ôê®u”dÔ·;å`‘‹è^á”$[ÛªaÃŒ4rÌãî¯-ÂÊŸxÁRY­ªÌ†Oq÷–‚Hä´!1=N¸¶Ê—zÕ>v¡_"¸HƒäF{õ±¬^S|sAsy¾ó/ŠE¾"¸Í&ßÅ)®í™‚—¢˜Öó±dnµş¥¬ÇØâuÂ² >7æá×sªhOCe6:Õ²Ê¿-+Sò¥Fú›È$ê‰FÃ–rPºÄµôPğ¼GlÕ†1ôu×vS•Çå³]c8î™H‚ÓŒÔñÅ	ğÔíú¸‹LŞ&¡ö1ŒÖo\ïd|Ÿäÿ]m}Ø2¾b¦Ê=b¨È§mkì	ì^21.ë^ß,düvy­NìøòEd³^EÛ\E[U–Ú¬N®2ÿ¹d.võ°"ku†ö£(™Æ@€Ä'\˜}»QÖ(|È^eöqŸ°ÿöß.m¥ırşıÛÌÔµ|½1(ãıhşÂ.H²?-Ş¦¢ã¡ÓÛ›İÉ†’"oø )YyQ ¾Æ²2û-Ü`ÛØië<ü+}6t}gÒ·½ŞÈsèiİÑ8]ë˜
HİÒİ{ÔÛ1¢îÎV)^ò-wÇËW<¢+ˆB24ÌS’ş;üÑ¥/Šà$Ş·w	Ì[zèÊ'ËhelÔ²‹[V #@‡òĞ ƒ%¡ä¦4Jì.2àÁ„JÒÀôO\è`g“ßƒ‚£ë[‚BÚ·Ó™Ûæ”åI)Å€,Cì×¬wPå4ìØ'ùÚ¼ÿÃÌÀÑéìª˜óS«p“‚ç¡N°6?•À8´ TS6Î —Ã”ZÛı5ÇŠŞ3-kÆ#Ê™˜Î|”ñî@:‘õ§øï´{V–rp°×ãOõe£$å²RAŸİH+ù/á·&Ak„5¾…w	ù“©aåğ$/û5˜¼ ÈãÅr¢ÿXX´8A+¯†‘¬ÀW·Êlœ²Ò^|PóyL"¢‡–â_dæ.ıè=7ËùHì‚-M&BøÿÏĞ"‘âM:X²ä¬ÿ_Ï'2?İèºER–ŸıãÎ`Íİìd° ó±)#?QøµúñÙ7;¶.8Ar–¬Ã5DN¦£‚«€5Oö–(lÙs^É¥xt¦q;´.N<GÜ{¡|s-ïùŸõÎ
ê	¦O„ÄC^Şz‡ñõ®õÈÙ¹,-ã¦–¤“ØÕÓŞê1%XÍòO…ºhè´ªğï_µ¶A¿ş¦Æœ¡øDÎ˜.Ã\3&Üù!±p]µé»	Ñ'˜ï,ôNH>¦´oÛĞ5'†¦!q=]©•a’á+Àk“º¦Å-P‰öÕjFv@*kĞÜÜ`ªOPÇ5§É	Ä ¨†â»PåÆØj`o€k±nÆsÙT‚·å_ùæ<÷máº Û¨t¼®³R~¬Bƒ}K4¥) Æ°#Ôõø"~ô¼ï)Ã“½²W?’-ìŸ‡æ¼
ê¹ÚuËNâîÍŸ…ÍŸ/Ñ˜ä]^‚ö4íaÑ\–Gö˜Ú3{Ö’³øµ´Jš¿û‘¿~CŠ÷B=Gy8ç\¥Á#ÚÈ“¼¢¸_£Ÿ¸‚×_QAè›{€QìÎ©¹CV'ödM)ãS‹ Ğ×½<6Døáw»'œj‡>µniÕÓ5O€	Çºyø$›ír	ÓK·¥Kr_€æ¥åÙbğ( ©Ù
õ»l»_g÷/æÖl ’î%~ÎşYiïX­Ù.T^£F"”¨òŸ|….$°‹T|`”ĞñÅ>ò6«¼Ã¢œBUš 9¨qzŞé‰õr­İi#õ,í€kš¾¤å‡]gİ…,¡f³c/Ï\/M/O’¤šöwáZ!Uî{õ»¹X¯
m5›]ìJú2¸°:æ¦>õ?,	}Ô©Ê”QrGİ}cĞ89pz‹´¶ÂÅ |âò^¸ÿ…AFm,HÁŒæbJú1BXR@İ_hyı@qØÍ“Õ-ºè×Â&®\Ëö(}“ù+H82»T[Y2°Ç	¿\İ×ælë_$Ï.«Sœº_‚%·ífÆQòñ¼¾¸øC´ÖŠR‚i® áÑ´¿Í¯AïÁ÷™bmzâá?zú OQ¼nú'ùş-9â˜ÌP°¦ò	ÆŞ!ò‹‰êsj` _nÙ¾Q}JíëÍW†Ojó¶»õğ#W™†O"NC à¶Øf«ÒìÑs˜&Ğ6„âi¨„	²ê˜	0bš-5WfR¤9òÔ‚årõûnş$%C´!£xü›î#:¢ÿç¦·CÈê€Äö’©²Ğ•Ö6òµR<ÕœQgN‘_¯àö½;“^ù¸¬0Øp-©•š3°Ñ_À·^ŠZa1û“x"¬YØ³Xã„>LÈŞ6ı0æøK DÃ@¼§SWr:3Ş?<×ÀşoèQÜè~6˜@úkF´K®xLêŞñù{+ŠŠ_–ùyö/¨×ª¶šÙ¤›—!K¬ÕÑÀrIp’0“#ª$eGGş„%f¼R®¼º#e¹‰l°¤v9ÖCÊw‡ãÆ“½d^FK® Š<uqù¯˜ñÄz~"&ú’?âfg¡‹Y,Nû íÛ½G/=ë&¸¡…nçOQäPÎìêŠıåYˆ¨ª÷Ñ±®¹-C;SY
ªYÄ<ÕÚøw8,[¾Ä+JI)a,ùŞ€GŠ~åÀŠ"¢â÷¨ÏˆÄÂØ@³Q\P†86¯•§Ñ‡ÊvÇ®Íp‹åC½=GsŸGë«†/J“Ÿ?²oçq¢!¶¡j€ÿ9n.W|²F™3»¢ù¹„¥G„!NØTƒøú®°$Êœ›G#‚¾ìÂÄ˜lçÕw ·ê>0†1u>Õi0†E‡õ™Œ«a7±Ç	¥aã.*'§€¹…Òğ)ÛMrNË¾ä¸•Nô§Á9&¿¯Ğåù•Ñ….,˜ßL­¼È)`TM_pxJÉ98ß$d­@d¯%¸›ĞÊ:ía“Êªù}&÷c"U¹uJĞÍé$’Ñe¤-ä
˜âÅ•…¦fÃqÃ!	cÇåX‰Ií¢›¸†ßMDä%ÍØ0–’TÔ37ŸíïhŠ~n kzÏÏÉ È‡cÚmPk¤ÌßÃOw7,ù‹Ü«%ôµ(ç¸ÂC§Qn>ìâoK»Mû‹t»¾§ŸZãøY¥=Ş0ó™Šl •ÿmKX"êÃ“~1%ná‘•x?FxÛW¼Qrè”í‰•44îœjíö3~)ñëlñ“òo·åÅ™ó¯”’›*ÁT9/¥ÊÂ>†DF–³_åPI}yêvçZÉ> œğŞÈæ{Sn]±ØNV?$•sé:Å¬vá@"CrâÛ£ê¢§¼"~.æ™E‘ŠqØÿ^‰Ú‚ÆÈ€·'³N9NÌ>šŒ«Åe¡\íÈµ„÷=?İÕ€'ô"y<ì‰`C%ªÊJ¿â_­è$Ç&;ë²®Ş§¢œ?
ç¿üÌDB~M‚3Â%›\d»ô}DÜÂs	¼2–”)}tV¥Ó‚•šŞIzŞNV\Æ‡v+üœ3¤|Q:ÑÈÜFÀw¡$Jü‹’é”ùÊû"r±p3¥kÏ¤@N$uo}"ç”…©şÆB¸é+š·B|àU¯± ’ÒõR¦1póŸe$gtÜ?Zé7Ì¦’ûlîleP˜ËİÃ‚w”‚‚1œ×®Ÿı	îy´úÓ…b¹x—ÅLÔÇ+¹— «et©š0?±Œ}h[ÍüÇfKaC±%Ëğ™ÃÔê?<æWP*ı2÷ÿ] û¼oC¢yQR((Ş™ym§?±eB¡s6¡kÒîolOÊ&¼Ìex£s»™ÿ»¬5W=¬iEÄÄ	?’>*n´YLÇ$*$$RšZ•Í³ó£’kæ)D“-#hFÿ¥oŸ“‡W?İÊï§2Ç;êÃ(cÇåBc+$¨’òãE`çGÉ¹ –Û”vxÜÀşõ0¼ØN=¸ˆÅBÇøŠn”\ø`ÜCôàûâo8obRÌ»1êe¦/cÖOáXÎf‹À×‚‘…J_³ ÅÚûÿÖC“a-ÛÈ†ñ	XqnâÙo£».VÖ¶“>á×¿¤!x÷ Êïhg¸oXÙ¼tú*ÆÀ4<(òÁI ÕìWŞnÙ5EŞzç5_„•ËõpûoéÎºI o0”;ë>|($Í±',§o ¢!°şÍj÷O 5Ğâò/E²‡ Ôß<„bu¸d?‚İZ±EÑT¦u+€kHPİéì¸$Oò;ÍÌ¶¨v‰ ßo>Òï²°Úõòt»¾nYûÁlß§ˆ™Y®v¥·HF8bÉÄğ7(Zx	ÏFk´ëròq+‚şÇÄ×ÜßÊĞ²Q…´èWş=ÿ9€¯I÷çu"T3Æ 9\:ë=.ª¡1V][é¦Uİ/Ò²¶ªBˆ½Ï¬®0á7I[:¼	"“KÆ™^ù†   Nµª÷_ø ª¿€À˜GRå±Ägû    YZ