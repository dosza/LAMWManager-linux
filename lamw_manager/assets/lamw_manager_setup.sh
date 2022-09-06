#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4146427114"
MD5="a03a61692f210940f3594bf61cfcd395"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24344"
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
	echo Uncompressed size: 140 KB
	echo Compression: xz
	echo Date of packaging: Tue Sep  6 14:33:37 -03 2022
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
	echo OLDUSIZE=140
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
	MS_Printf "About to extract 140 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 140; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (140 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ^Ø] ¼}•À1Dd]‡Á›PætİDûô+ØóVócòÕşpo318ø‚Ñ8Lå~zÆ·ô¤}¶‡‰_|8vÀáÒA¤/Õñ·_Ç9XwD½ÕÖR‘;ıŞ{e‘‡˜G¯¹•Üİ¯D›ÙùBÚzzh|Õ†ÊUÚKQ>KAn^hš:‘(n{›øğ%EHE¿9®Ù„ç¿¤$¥¶<=Rá‹)_©€+òö$Öà“Å¯TBÙo½Z•j½*ô~"´vb•q¤ì˜¯C‹Mê,PE ó e¯o}DhvÍÉùy¬¿sĞ†æ¨qãæİá·´®Ñ³úĞÃ:ÊÌŞ+upæ¥è5±<WB—rpbÔ–g!ñ?š®s²ççe©Š…¼ÙY6#Ï:˜ş»ËÎ„°Û·É¡åWÈƒ¡fô8àCÔp¶]á¯Ø86€—VˆÔ^3ö¶4&{ª+äíº4óóy8ßÄH/h~[3ß2ßN*sR/üt7¸|Mñ½qgÇS‹ :3Q´îYëì9âˆ¡gÍÌ»÷„éû#³:½KØºŸ >.±Â­_Ò Ôç·ÈŒÁóºÕ"ÍÎhTĞ©'¦Lù%[å6î‘š-¾È1o¤;ú9ßƒ\\¶ZÕ“ .¸…;+ˆÓœRÙ¯y±°~Ì«µE—&P÷úğŞ\Ä’“¶ÍSKóÃk‹ÚÍb4aç†Õ¼AÃ6 Ğİ ]­[»}Ds—è`
>,ó˜Œ\ÌÔŠ¥•¬ü}&ñVîG9õÈ×7¨^#…0iß00™Ã­Ó€'ër¢§„²õb{§êÁsø„é_‘şY‚PÏŞLáç#câ áS”SP#Jl¥@ˆRsÿ
í=Áú¯8’
î¼~XÖ‰Ş$¡?zMÈ§)YOÑ›V¤fğƒyMáõ¥q3,Õƒ7Ä¶Y9š±q3x©ô&ñ‚É3…fFJXµÈbè<!°áX[£WÅï›±s6+ß¾E–¬ÍÏP©içg}äè¿µØàkØVÑ»ŞlÄé³U20ı,BEùˆ“ÀÅ)_|ZPåHü>¨¹`ì>§+·öG±¶ö±%ğnãAb:cëJH+k¦`üıÎ¿.Ÿ7|Ç]~ç‘ˆ‹š>©"^’=:Œ ‡:XPÚ'%Ù	›YP"ÌccSyp—ê¿ŒnHö'¯Ñ¢¡K“`Í¯Å¿>ÓöÀdgœC&gd9³Wã¬ÖøÄıÕš@S,ÑÍÌÍ×`5j&«ÚµÇNizâÛ“éÅë9}M©
¿àc¦ï–õìÊ—h'ğ‰èTñõ¨!R|ŠÑr4r9Èqƒñ]	?d–Tloú®ŒÉ”…yV)Î6‚ú8Ågàb€‘X›iÌr1x–,JÖ¼JIĞ=¿³U·,TK©M¡apP{Ãªw]6FÕÚ˜w/±„CúÅ£M8Qv†¤87rØuØÂúd8-ØÅÏ aFÛV"Š‰S "1D•¾‚£6ßIt>•µ¸îÉ9ñÿ¿Vhz4†âŞÂæ&‚‹úÿ¡7r¯
`,ŸL^+Ëoàì–eUÀlİØÁ×²zÏ°¦O¥öùgH×¨ıñKê ôÑÎuzÜí|æ¦F'¹PyM_rœ@ÉÌØ…Mj­]ŠQ†ó¯B	ªo ¹±4{òH}Ù	sB.sx šD»ÇY?ÔˆÇAìÊU®ñ€ Š"FPÆmú¨ğ%}âmu]ÓH.$3Ğ‹¨ÍSùïiœ9ä‚”\†DÁ4–éZL*Üö£0.YyçF*Ë2®•v›p¬\G£±€ÄVÒĞšÕjÊ9ğÉğ ÌF¾nAôDú¸à
Œµ§´LÌ êÊ_›Ü:T38ørÕo­=³Sğ;dôŒ”‰€-±ÉÍmÛxZœ?éˆó[à
¶¦³×n-Cv)á³‰£ÑĞÎTA÷ñÕOŞlQqRQ~3Å¬rON¼…Ó³¦ƒÊ“/…v×>'ºXk—eø¹¬Ú¿O×·a˜ÅÍs¢Õe’ÒKË¢î{F+	N3m-
ÏØ²ÒÚÅ—Ãš|¿lA ÏNõ•ojåÿvÆí˜ÔÊw.| »ã¢˜³hĞ×ÍÉ´qÚa³zK{ãusî+
H Õ«“e+OD"Øha‰€ÈÑw*x|pu™‚küpÄæWìÏÍÉ‰£^êö5tŞù&[RÊX¸p<¢V6¸úè6Zg¯ Gˆ;ïã^Ü|—`]QÊhíÃw–èE¡±l\Ã ²Xı«ÏÓfÊ»á «9İa±W{È‘6À²Z¾#”T!¶m[–^ŞtÏãƒ¨Di`Ö|{M6_eM‰Sş•Óffò4ğôåV Wµˆ¬AÑ)¤µ®—·H9	##=—š+ô!7,ˆ„ÏbÜRq{)­²Ø†-‰¿Ó=Hó Œœ@CÖÖ™‹ò*&ø?ZØ._ã,nu(Ä}—HR]r5ğ©˜O`Üo€'ItñùUN‘¬Ùµ’†İsœÁÒ•“¥1MNkè²:MP—¨¯­sÊ–HiîkÉ\ÜŒ§Íxî©t‡;ÄØŠ1t VÎı‹#Ï?ŞÁâÔÂI:É
#O$Ü²ü9‘.d¯®ÎÈAä¬!<æ²‹Àò7®aé ±„ó1Ãz®â²/|Ùoç)~Ò¢FÉ–ËMhğ˜ŞªP/¢ü›PPôXwr¹ğÈé%3%+ÁñpyDöÚ ~EÈÿµR[sNiû¬õyÌziîŞ9óxŒP«ùÅ†Xx—ı_/ ïêŒ±ìÙ"‰kÔ8lô8¸wFQ€]™ÃZ´¹×gÉ½îĞÀQéì…éC¨eÍZrğbÖ
<%‘Q>A ûg8é™¯bA•)*¤šÕåv£û’µ Ìê™s‚ñXR“Èî3taáVíÄgj|&ÌØÿïrÁõY}'%(ßú	Rñëİ[\4[ÑÔ‚ÏÈP
—Ú ?”¤Y+\ñR³	ãøÊ„Cuç€g™
Yiããâù§ó5ø7ÿôH‘ÄsÔn®K•,¥Rî¸h‡Åİ¼ƒ5¾±	øÏ‰ôÊ·§øÉˆ†kœàÊ±ğ<ì;GÑ›¶sqpøZõ^²³ÊøÖ>5i-c†#ŞVAĞØ2/>Ğ1ÕÇèœ™© ˆ7á«§‚BJQÃ™Rè¬k«íjX˜¬€”Ê¨q”>ğÜ~ªÔ‡÷ú¨Aó^­S¦³*iC,cê¸Zäø˜Ÿ)tŒE3Íú?ı«ò£ı‡Ø5‘¬$N‡íT2£€Ôã°$¢'å‡qŒ+·øŸYÊJ“}C`§êi1Â;æ	©sñëi?!ÍJÒ´Uñ«:"Anô÷È-Nô|Œø0ø«bã™ASoÅÄ4«u¦âce™O×5ík¿0 &k3*æ:Mû|xÍ(!ìÄ¨IQ`?Ó=H¿ø¼ckå5 ´İµè³9‚\Fªœ¤ë³™P†óæ1SğŠCiÈ J¤¾“õ\'(ûÉ½¯lvøâ×
’¹&é.W:5Yğ¨T	š.µã#Q¯¾Õ¦ë
H 'ĞÛƒÚ>ç*ûºxo²¸F6”CNk#% nğÏN±x‡hJ`1DéŠc˜ùÆJ3úF\8¸ÿ+$àÌ¡k#ÙÄ€°ıhëÀaÓÉ§©n3cp¦†—¢í/<sø¯à1p#¯(˜V]#¯Å5 ¯x¦—¼ç”06Œ8Ò5©åiaM§y)bÀØ¡V£íh7àòîŠ¾›wóqoœ7ßÈÌœw"gEÕwfèl¨Ksí"ÌzéN‹ÖwÿÄœ¾n’ ezjOşá`š%›Õ>¦Vòí@‰SyHÖVÎ‡WXŠK³ÀT*Ğs½öÂ^ñ“Û£ 5ˆï¡áO€æz'œ {¦–ãç&ÕH™9ˆ6J2¶f“—OÈšNŸ†´ÙE6äNÓéø‹µß26A–{“dJƒİ^D4ãÂ§ò±ÌØˆîş|ºiıY>Mjÿş![Vß ñi­î{[Sø7FQ ¤Th¨/nDÅUg‚Ñ ?\®Áğ¼®Ğ´€Ì‹¥m¿Še…­äA¥°Y¬ê±ÁğŸV¨àñB²¿~ùs#çÏ¿è*¨ˆQs5!‡„íºQ€—t¸9÷t-á¥M•Ñ-×FVÒò\¸¥˜ö Tg1“bÊµõæ¨ªÅø2ÚÂÛ÷FsA¦ãjT%y™T Ç¶c¹2¡a4‘s¾–uB^øI¬Sô0wRšüÄe‚¥(ıBï_è^$N° ü İ- 9 ù©Døİî ûÁªõ¼ûºş†>€Ÿñ)ğßƒ¹·›¿n± ä7ùr÷Ü;ò_–Í" íÀçE³’gAÊ·qG|ğ¾‹»]ùØ1ÓtkI?Ó4	DQNáŠ^¤ªV`.™·ŞMNy;Iyî€Qšo={EğlÒÅĞâÃëØc²²àx‰RE¤,…%‹8§'ı¡­éW•VHgMù}Ê»ÚÁŠK‚¬MËĞz˜4B[èvC¢]ğzÏm4O]_$,‡í+E
‰!W™'€+7D•]¼Å=EzäÓ«[¨UHÚMS€ä aÃ
UàT›Ì[ú6Çn„·ƒ4
İ¶q¤"S¬":º“£IĞ*õĞİ¨Û`‚‡«ğ34OH+DE½L8<Ù£UÖ÷@7cP¦Gg8c¦€‘K{,§pUZ·²
ÊôKÜŒä
çrº[,`]ú„,½;¤¶{÷ü0­ˆ¶ |ƒªj¼ÚoÊ†v´­¯\rÚĞ~ÊQšš|,ÓÈéz&ËAtjêŞg+?O:[U8~¶Õ1Æ°aÑ ?¢±1·jêuYaÄû³±®j1·mäĞ5ìÙ¬ÆD;´[G½ÖûøEÊ˜@C/´–‚8šog­Ró¦ˆ·2ÅG£×®Ls&«•Ls>fuÔMºàå›dÂx¸ë+?ùxfa™°‰ÈZùk{g¤"‡ÇJ4X!œ5á–>0vïËÆôMÖGhƒ£ïÂÒÒB'ÌùÎ*ºhFÎıšgx/Ò‹¼5âñä“àá¶UwÏÑÂNğ #`D9²¬© Ê…DçDÚ$¨ƒ‘R½Ó@$ƒsKø€lÂÁ#›¨újz$’E`%x¸ Ûb|ÔWúR½N£v«^¼õr8
AİXÏøÁ
ŒÚR±O¦í.{æÀÄ;Ôg	Ùø`›Ê5-gŞhèwXïvÁ¬{q)Ê“a”2r¨Öu­%GLil9¸ÿ ,8óé&³Î	™
9Ü~WlÑÁ8:Rª“_	½,_Ë¦$Ï	'+|†asš­wÜPëÃËa’\tŸ”iØÁ¾æI×ÆKR¥¡a‚"Í½©›YÜ”+âMĞÛ©‚xoK a‘"HÙÒ§ñ€
SnModŸÏ<»‚~!!¡9¢2.¯ÿ?ób€Óu;™-ä,NZ¹§ñê‡ĞÎ?~ª’í GÔ«…ø8ÊU=fÅ÷ír‹a˜õù 8o´Ssşºœ€ŞgµÓò1¢²‘ËK£Ï¿ób”KSåš~Ş„C&=ì+nBË?,vK2´‰† xÕ˜«oáM}VJ ®€Ô0¶Öb†9Ïï¯”x³©»GáàG£ïƒ§Ğ]?û·¸®JŠØİ°ó©øâ¾¨2xR‹yGp€ÒÖĞÙ7lœx(¸†ØÆÙ£¸ü¦ñ­€5YEŒ¦÷Æäô+=jGXşLşFƒŒÁƒ[úiŒ€¡«ı¿Ú¬œ“êF´³5Š|-Å.†,’ù‰òE+ç±V”Vš@Ö«n:Z7^d‹‚_ÇˆÁ:Y•«Æ ‡ ôp¿‡şå¦*RQ`‘`2~Õ“èIk Ô”Ü°A>ÓëÜÌë.l“Î`krJï òñ…ğUï7J\ó¤êbç©Ìğ‘­©±üÂ°…_à*G€`†\Ò)§v©»¯÷~MÎÌy™gµ¾l‘@lŒâÍ/È‰]|VüævÉÓAPé€ùk:Bí§Sô¼zš®i‘ğ	ÍKóYœñˆNpÀ¡œ§(™4ıÍx×Ú&Ë€»ck•‰{=ÌõPàˆ(ºğì‚5Õ‹“I±¯Š¯ûYI¹qKg²ãe"ì5Å':'3T'	<“Œt šĞêÚÍ"g/ı€GÄTk¼â‡¼u‘ê”}r*•Êø>tñÉc˜]İjñV1ÓIGÓ\C1O©qBZH×¯­QÊOA•séH)B‘á™ìy’SnI¹±u9İÁJÑZË•ìÏaü°4Ù|FŞBxØ·ï‰f½³	ÇCH×’MdªäÔâ¡,j]åºÜå5Îs­Ö,ÑpìG–ïZ:ü p'Í¼éjò½Õ=ı¥·&˜›k]üí|>ñ?xR$ëä;J;îH™æÊÒŞ$æ¯h9’ã½9Ûµ!İ‚pSZ'D7€ØJ…!Ğƒ°@A;R6ïêP.¦GÄË•%ßqY*Lß-srJ¯§Z"á\V§ş^•×'¢Ã9¬[-tÒCÕ•¹î¼ş>	TÈêAè~\+¶# {‹‰êÍSÃ:FÂ„*Xa7ù
¼²´[ÆO'Õ¨+Ê^3J-{–ˆòà8è«ş¼´ÂtƒUÅ¼W–1ì¾ì_iól3¬‡º>·8­šëÙÒm6ê5§’zxàM3½,?‰Ü1‡ÉOöãjK‚|ë4VFá0À¥Ña4YÓ·ûÓñxÑñ·BºˆÚÄ0ôß«•hŒG]½Ÿ	å~ĞÃšCò›\£hëä^uŠIü7ëÇM¶HİÎm€”ˆk=a0XÈ.âßîbHaÒŸÔ"+E²>çÃzÒ–C¡EPb^Ô’ÅZí ”9zxóşâ¨ë³ÉbX“Y¸3†zÇ.mÑ' —ö0@OC‰ë?á³"ÌCâWM /QRâ“U Ïœù!°õ•³Rr=\Û6óéªL©t×´;z>›8Ib÷œÿäâJ™±‰¥ÿØü|ÒD’ÔÓú”Msöõ-ªè×ßè¶ÍP/ùÑsåÄD<ø¬ãn¡üQŞ'¡‘&¿2Ëw@ê™¼¡æÃy­¢oÆ{rè­Jõƒ±s—xõRşD7	¥†?UĞUBÅ»:4>Ì'/°“0P€[Ûjî„jCÏºV‚¨=t*ííÈ¶ú§j#rÑ8 `±WO,
ıšhTè’²lñ9^ŠR{o"°½XBªW{Æ9QÊ:íÃ²fzîP8.Lñ×ÄºyoßMş`	©&‡‰s¨0eT/7¦(› g5òŒ%n¦ÉâvÂü‡Ä8©Qˆÿæ»Dä°.ıÅ÷53Td‹Í]QÓˆ›E ƒZçohçUƒB	¹¼¥Rg±D’gÂ!ƒ¯3áÙ—“ÙïxÌŸ¹kËOÂ/@Ì«ÍpËÊ.&ô¹Å–Â‹gå¤•É„C¥ï6;&!m)àok5É¢öŸ*Ğù;Š‚—IyW‘²Ç›Wki>(km³3J«_ğŒ·Q«Ëôº…ÇïºJcGÜÖÎa¹]6Q63.Ê3êOkã>b–¨†-cÌ¹ÿ—hç/YDº#xe²+ƒ%ª5¸¼_UØ(1‰­B} [Š‰·^IHK×º ô¯u«T©x_€ŞAõñ5xÎ¹¢Ùú¥n"V4ºMµ?KAß3E‹…ô[Á'sX+Î6Å7zS¤¹`Á¯ÅË\=VrBà™ØQxúLØÅç1êó…_,çŠV¤¦÷Ì\hè,ÿ¸y^é3Q§¢ùàÀ<W·gª×í0®&'G}hºè2{u5ÅiI°4m¢Ky|°ñ»xlºç¶z¡\º}Ğ(0!cAt§*ªéæN)íåÁæ+ıGğŸ&†Y&yO`œe6Ë·2Ş»~£é®Âp›½«’’Ñ}¿×%ú¼ìMCj®‹.Cqº«/!Ó`IQ+=™­ÙDÍÈü¨”†ôU¦|çG¥í=MYèeRö]•áï_BğXŒÚ
ZşJÿøV¡ŒÃø‡ZŞb€K«5™rUÈg|SÜ½Ë.J
ÄˆmükP„Ü*ó¬‚Å§ì-b…øÛ~8=öî–âo	Ù·‹t‰Ë|ñÌk[ØÁiqÚ‰mR*cš™úÁ¿ëîM–ŸÎ~ıwP$oœ!«T%ñBFAé%F8	×É7·mşCı0¸Hˆ¯#
áıÀnù(FÁ]xó+CSÎ?Îí58.€DM‚Ú|îMÒˆ€u"!¢2%!ö—D Õ Ù:`¶³8ŞÈ‘–uàœ)Í0GNq‚p¯é'0cÌÇ ³;Waq# ÌäéKp>¼5­8ÔïßŸ‹DÇÍüE°üäğ‰€P`iòF¬#ÆzöŠàj +tABû4Ô‡z¾Ñ¨õøN  …ÙçE8iÆhüò°ŞlİÍÈY Æ¯b[©
/7/Ïs—êbÀ`J- Õì\ºdB>ü‚}f@3­qlùè¾ğ'CÏ	`+Û%‚9S8%@®‡ÃÅáıÉ,ğ]‘¹“OV·jåzíCüœf‹‡ÖÂpŞàe›ÏŸ¨Ş—:Àdš4ŠÎ €´…Ò¡ò‡Ñ–P,^ß#=Ÿˆ¨Ì°`AoÌGxóòS‰ã(g–„N~©~òCß;fóQÑáåT©ğwæó‹Å”Z)˜eMBñ`zBPù´x€3€|­ÅWÃ$ˆ©Ş?ßi:8Ä#hd÷WÕ®9\@z—ƒ2ø~¥¥%NKè›ŸÄ‹pAk `S¢‘7í÷J}­îÒ,êúrÚnİîú©ÂüS‘j[b­¥t{Ñõ]ä%eçÅ^\V†²ë…ıéò½H[$(Ú»R}^‰®îg˜e«ËYÙ×±wÓÜåv¶"¬AÓ“öÈ­7®Ã–¿7˜ú´CĞWg1{C}Î¬µƒçö
Uf`‚ù’g[×çÓ™ZSº]5U“AT¶5fËP×K@Ö8FÍ7s’©'ÖÂ#çÕƒšéÎuº‚Syf_ñNy×mPïû!€Ñõz×HoBMÎ¶]qÍ=•×uJÀê¡(bÀp#æ¼¸ 
Ï+Âm 7æĞ‰Q7Dì«>Ğr%¥|C¥é-aÛ Y6÷xæC ¾YIŒ•ôWr²»ÈT§EæJhüÒ5ËÁååsü/$'¦Ø
‡£~LÆ+Í9Ù¢½‹>¦[,n,K†ã·‘K’ÕÂd{ßO3”Ùu!VÙTPãš?è7î”:’ûsYúÚ‚.hØş*Í;C}‡µTpù¶Š_€¬-8çd˜P0Bú˜oÇUÔå©r0n-µ‰ñ•ØÎ&è›ÕDİÕ^ìÚ}Ë6¾V¡zœ`!'&Âßù>>¿ytI[ğ`…B»È\Ñgöå1ò>	E´WG®%;·„£]…¯kì€á0S¤>ª!æÙø-rjC ùU¬q×dn°ƒ¶7ÊÖiz©¬é'TèåØ
ISŠK…VTwßóPÍÌ7£¥j	5Uíç‚ò¯†Ó»ï_¤IÄeï5Ğ.û×f8'pv;>Î…Ì%éá7Á”±¡µÛyÂhÔ]\ft)cBzÆ	5ÕÍkê³Çœxª³À>Ş›Ñ£¬¢¶™ªf%šmFƒÀ%´šşF+LkÚØ:(ì=JxÄÅ©oœ¤,Ü=¼`ŠBĞ¦N83_høÔß4‡‘°Ñ´ ²Í2Bkc¹¹ì¨‚y6ˆkf‘!'¨5LïÇAL,0šéºŠ!ìF†Ü«‘”mÊ?şÈ0Ö…Áf,»5¯7­7Ëxı”¾ó`_Ñ¤£,Xe¦œY¤”LùÑ¨ï=ï-­^°¶×­ç+Àó˜1¿OáÒâÍ$Ævèôe«ñ Ÿ™IĞ;Q«€fC(¶Èße38ŸØw§«åOäDNûŞRk‡„J»›Dše®Øtì§Ùø3(}ö‘lĞcøQæ^éÍ”ˆa1¾t+>^ŠÛ­9ñbtm4Ñáø,Æhú¢8
Gb©İ:Û ~Ö–v¯¯xã/<®kÄ.‰Á¾èT„µ5~p*äduóŸ¨Ëñ7ÊİÃ<Ô}z^Ö¨t{û¼6»óûÅ¹¥¥ŒÚ´}¼
¡ı' „+©Ú(érÅ(Óû<4%›¦Ë«0¥V5Î[Õ’§R#òÿqÅ‚œdHÏ•.f¥v¤ìvÜíãs¶&ñôAåİÎtÀÇŞOlPŞ%aN]"lH`½^E!Á¨WÅòöÍäAÂ8İ.€ôÔH.¾®Ü8zmû=r|Röµöm‰Ğ+«>‘n¤¯7¿53{ßZÚeŠÛvÎ§öJ‰3Ûˆ
Õ¸¶,D±a
,úa¶TY¸½	erR2j@Š¸C±Äë¡_Â<øˆÆƒmÄ¥¢“mùYŸ×@—­}'z¼fÒZk…Ìc‡ZœrÔú¯B“Ä¿¦*Š§8Æ²îE.t’MTÔßû•êÏO‹İ­ó]ú›b'm%ÇA554®ÉÃÂjí£–ÛI¤²Ôw'ug[á'x*_g"üëõM	õgÓ‡$âŒ!ŞéI˜ûP÷<·âŠÛú+\“E”öî2(lxêÉ²¿O?áª°(k¤;‡ã¹…</ºíª)¿H¥ÃÚMCˆdi—ı²rÁ¦?—±áÚÅUW>Oœ.â³¤ÚöÌùR#ùÉ¸
à‚^oæÈYq¡}ä…
è’¤ şj™G„à-äü(õ„Vè6ğ$)À5ØšöÊ*ùÂòè ‹TA¹1-Âó¼£ÃƒÜ	ìÄS·•9ò¯Í<çÔØO!ŠV¢wJş+’æ¾Úü
tiœ­Ìz«ğİ q.;È“:uVG‘TMÑ«`+
ŸäÄ/À^b'jÊÿ­îç€DÎ!ZP¾5¤T6P"ŸO¤ßß€ u ®¥Û0P(hüÓæÂ‡-¸lTxtªÇºx(•T½îbä=…P–MD{ÁÍ—g¦œ¿[aÜÏÛçK%°[;î£’gç•àmWõÑ%ò(n8şw½y&ş‰ç|Â=:ĞëEß:¾Ï½È¹ÃªiYĞOÙÂ_‘WˆP{	NûØ—ÅSı¿†]ıl»m†áìGËN…ÏdzjNBÉ¼˜¿£ÂsDåÎá‡{OÙ<Ø—Ô¶şÏ[©J‹_‡Ìc29S—¢µÑÄ¡1Æì„5Ğ\²;5À‡¾pÜÁ¡¿â;ŞüUZyQüu·!+BTƒó„ñ\Ù2åñ8íP«!Õ5QDˆu
¤6^ˆ_ƒ€£°ş~=5ÊƒGÀ=<éa_v”Iãiwí8:ĞÛ Ä»4Cæ¡±(^J!ºI–gğŸ^,,‹ªƒ¥÷ x.×­è-‡ÓwOqMŠ÷¯ğWugntD3kP?!pI¦D’àÉ½SC5•³±ê½#}ÍS@ö÷¦b>2m½œ™ë‰¾¬nÚ:hÄS)kWXå;ßg2Š¦ú‘P›Åö[›™Ç¼®>¤ø¤ê¡L¸Î°Ë«8µ´ÎçiÉ¡€¸ù¯ñıƒÅbª& ‘ñ¿VûêÛig§PİÜ·ò}.,Bé5PN{ß9·‰Be4åôäú’	´½4]*ş‹zZ‘Îä¨¤Ş+OŞ›lÕ€áéWV£Ùus¹0ærªòqÒ5†@–=cŒû›ü=Ø"l&(”:XHd†ôÌDá¤Şpga—İüIò“Qa”gÌ„Pã3+ımƒnøİÒÑW’¥­v¶Vş gUŞAé±Z×ÎŸ±[nûôUÿV›&ZîQ—ÜÔSº•]ˆè‡
ÇJÎÍ6Î|‚qµ>-<ĞÂïštùš‡»ë^Å„}®Uçõ¨W}]\d¥¦óÚ×EÈ†wJäÉd6ğÑ[œj¡øœÜÌÓ´*ü§[6A)h,4Ä‡	‰¥6YOÜ&‘)¢},ïK©óÇb‚#ôGd=@„tuHĞAÊ=4WExOòûÀ‹)Ó„/–”İ2È¹KëÕ˜D{²~\y|×Î”!n¶B@áğX×DéIV—a«¤îdµ©Ç[Ã±Ñ/À#˜Nïiuc×ßÖ k)=`­¿É»2„ÉÉç!ÿÃãb;³L‡8ØB©V½ÿĞÀ¬54„œD‚â6&ïì$05 xÉµI÷—™§åG¶NgŠßHÑ4¹“‹~`ï®âyª©»fòMÆ©şã/oa‹§]T
ÁOÚ²e œD(³õ•<ÚzmX#9r GS™Ç¥|EZ=DQ‰qe;DT—¢Ë
-îº¡rñ™&Í}Eï`Æ>@ñHä9ì…éş%¿D^nı*ó+Rp. ~µ ¦N9ÀC¾+<fòdpÂ¶ÚLÎ7ÖUŸ%TŞ-‹#Ü˜xãgé	±äªŠùK(ƒ—à¯t][f„:-<šûïLN+êJË_àDl½¼a˜?cùh¹¦XgòÕ£ÎÍÿå„¿L<fÈcÊİCĞ­õ¯Ï(»Ëó¯ô‚rĞ$—îËŸºæ*ğOªNK¦ÖˆZÏ58æÅ—03úoÀ½joƒŞñL¤r¡pıåWŞÊ'»#Ô'Ëğå'±H@2Vñ3Gq·n¬¯ÔPàùĞâ0”ìŸÈ/¢¡¤h¢>dÑÏgñÿå•§Ig?ñ¨_–¾HèeèâV}º©ßi¤$ÙYĞBŠ;Ã»~Üˆ„råşğ7ÎT\hîM§¼³YHşæ´93r¤ÿ«#µ½AÒ2Kÿ1¨hÿ¥Lõ¢u½<ş:÷¹üøTw‡KVCEÖŠsáêË{„,ÅÅØJe(½ÌÛ"A÷no‡dàdòĞÈÚ‡	O iùÙ	P’é­KºÖ%œÖuhè$5ÎÉ18;ƒ›©–•ÿ»˜ªÅÖúHF*áPƒ
PgpˆŸ´f'ÿa¥°#j†ú±áEÈó=°¼ˆ“Åz!ˆ×¦ÅËTŒ
àòQ$'â?Ùep¿œ mÅ
0f%WŞ?Œe'süÀ“hÂhdy·Ò®še\ËÓ­JTKş¬óó»¾›—og›Àíš‚Ä'B»áK¶eş›Ò—¬<»ëş[®ÆØmuÁ›õhåWdì |RÌV¨Xø5‘=/ª•œ8“Ä—Y‘×ã¿ĞøÔ óÛw&»7¡Æ±”Ş$»ïô:ZifßNCí!¶¥¦'!¸-
V>İc
dFÔB"¸èO}ÉÙUÂãÕ_)r]UòO±k¡ö*æœ[ênìÑ™¼lé¾ŸÁVˆö¦ƒ§[é¤]hœªˆÂ¯¯—n¢Á#Zt¯¢+¤Oc*NMzäèAÒØl»ï0GŸÿÄ ïnK/÷w{j3™1—jÊŒé’½«Tˆçó²i§ÁF‘üèkö^áémÆZõ†/Ô­-­TˆI¼BXåî=ö¹2½†næ$›8Š_«GÕöF®×M‚²2ÿÄïÑ[õVX&NşŒœÑ`#1éÏ*”¢/~gø7P´b©‘5"ywìÆm*o²j=Œ‚bÎC»Á§İ²íˆ:¿Å4Åˆ¼9]rôÛ8~³ì—ÕE½|J ?5 ù}OÅ{%àí<E.Ü©YÄwZÕ«8üœˆğQz‚Ğnór½™€õ 9®®ùC%XòDŸßU×OûPK}ŞEÏòç­ê©€‹¨>³cÏÌ+2e…-,¼¨âÄç2)µÒ°ŒÒ\İUCz†ÿr‰±‚céJ'Fî÷¤Û!—!æœlÑ®6Ñ›0æØÿlÜ†˜øÅdu¸€j$“ “Q³u4õ€e\©z÷¼!Ë0”ÛÔæíÒ¸®ıò0 šg1ó8±`”A©êÏÇä]İû…wYCÏµPd1êäj¥4Ä5"ÂšŞaa4R>˜U×»sÃ·ÙûÕkŒ«~Ìì¥§Ewº©œ%¶ÜÚõÒ6iMšÊúÁFÇ7»ao’ÏÈKtlEoékO¶5=¹[;»[pVe…ˆşp1JÅWºPH”Ÿ°Vh·„}CìŒ+bõõ’õ)÷<R-}6qƒ°˜"‰Ñö•ûh1–Ã˜SµP»ãóšÆDÀX#5Í‘dv-Î:ªá•¶óJë¢}xŞ×‘%LÕÛ”GˆÛ˜4bì­´=CÊ(PoS^Á¢21 KÆ>çIAò=D€o7¹8ßoçùAUÀº¡OÎbUÃFı½Çƒ²²„Øo÷½­~=Uİë¯eûh}”BBEØ‰ÌgV¿ñàKÀü°¯ÊÖ…_,ÇĞïî¾”øßkkí&2¨¨,	ğxlLªç¸nÄùì–ÙĞ¨~bX€v3uñÒWıÕ¦B×ã­¼B°ød:‡ŒÏìV³æNáàÖ£±‚±4)ælÒÔ;NòLÈ³Q"{t²ü<’itPú<ºµÅAÛá¢9<·Èÿ÷cZ˜ª- kŸçUY¸•‚ÕÔÄ”'Ç‚ù›ÕÆûK$##xd¿˜+ŠÏ‘«Éü%»xGµÈ©Ã,Ú'ÓÓ×¬Xöé3ğÉŞİ&Ü†jh­øáíG}üp¸]÷R±ù¯ÁÜ…Ğ×”NjâÊó¾(ä[µz°u,|ÀÇ¹È UÉg@³vN»é#6ıËzTÅlˆq¼‹à!’ĞÊÍ¯Õh xDYå°Æ¼‹Ic€'sÓÆûDs»4<ë+ˆœr{»Ğ"jB–8^‰ä‘Òskelù´ –ÂJz/´Ş`tqDızO÷|q¢Íğ²‰Şm½N"–,î8\©[h <;ã¬ñ¬¢oÏ¸R-$ÊC}Ô}˜Àt‡§¸§äöÍ¦®„¤EÇNô(Š¸’‹gó6?’Ü)>øä–È	vÇË¸¤}
ü9øöìnğ##2(ÚLs´ıËîğ%?åìnFÊ"“¤š$º¤:Ë•:Ì©·ã=Å$8ãTíoÙƒû‡9]B§ìašÏ•&¬RN™ŒàŞk”öò…µ©'åµU¶^§_ˆ‚šÂ–\—èG©!·Ö2]¿ïU¡¼mrµ¡…wäÉêŒ)@Åa]¾w8²=kà4œA}6q•£·ÿrºÆC®ÔÓZ_öWs|—]åªA‰ë$E6õ8!ÉŸŒ®p=}6³ N%²ÑÏ¸¿Z®l´8´ ¿£ëÊ—#¬[i­â
ÖÁ
÷+§Jp–(ø\óu‡Fû—¯e1€Ç¡@€íğÁê©‰UÁìÏûq¦lôäpªÔÑ3×Æk&ˆJÏg•ÙJ”'UÁÁÂ38x´¤aØ9ºTIVÒn¸³«ÆÌÖqXvJ-:sıûNC1lõĞ\.-mM±òbfÅ_Ò?P¨Q¦×Ó3l&"Ä´Â¼A™áä»<²RV*šÄÌÓ®yîBĞEå=×3B:(«¡´ñO1¨ËP½¾jÇİ™1E;Ö£yÓ4QåÍœGv~€cº` oS¢”4NÌ3”lÚìo=›fXôO—ÍÌZ¤ã0©#¥¥Qª¦àÈÿ¯Ò9êÀU¸&ô)¯øÙg\Mà!úÔ‚OGÉµ!§ÉİPÚçPÏŠ¾KlëS)ÕÒÙ³­Å\¶WÕ,“ü
çAc–»wQ<¯½¹ûã0°è=)%-éË¢/Mú–d48H‹rP*Äë&N üáyD/N@ë¾}ùÈ¢îişò+ÚQÑ FZ‹iâ¥·äK^¥·’ZÁì[åœu¦õ¢ƒL<È$%Å_cãà±Â~(º¤€w€„çpsï£<¢Ë÷Ëmä‹Š*˜Ğ–­Wv&Üµ1ûHA‹Ë4€&êz¶¸ØÖ†ã}Â&R:åîúIƒ|­$S#q–¸ÀÖ¢_9„ıùâ¥1-)Zó7ÅJ,½?iÅ^lwP6#Ÿg§Íİ¸Œs¯›æ<±{[©Åp˜n§SËh†æßqÂs‰DÂ^}Tm¹¼Ó
|TÈÕ=;sÍš2WšÛ¶İqbãkêÜ…A	^Qöç‹Lâóu rÑl²ûÑ€Å]É\†SŸËŞ£ˆ­q™sÌÎq`VXËİ)hI´î.UáCUÜ0õpä³ë™M„ë¦Oã®=—L˜Şhü™?\#E¿¢^š%’‚¶;Ğ¯	©Ê6=ìAÓF°ø]}ÛÁ[¬ŠÎWŒ°$„4kÁ‚Lj;ãëdçûË”¹ØÂïâ¤YSœI0jÜ§Iıiub%:Ó¯û‡CqÔ¯„6=1îÆ$®³§ya§Eƒ|}ó™üÊ¹OÅAÙ¡òÈ¦o-0ª71kˆïè­¸ÜL]’Ãµij³	ĞaŒ½Õ8Ğv9ËAœğw£¬V±˜nĞ†“Ö×l™Ó \å‡ú¤ŠuÏ
@Â¥®{Ü‰øQ‚AAÊÃ/‘ùˆBêÆíšë²â…Rùölƒø–“¾\æ³õ²a¶CDÌZƒc±´·)ñ­÷¿¸´ gÔ„lİÏe–-k0oLÛ&L¢ÎE]êN¿ë.Ö"èÊÖ¦Ibê~YüÊİoG\B[²¶·‡Ÿq®wÛS5³Pö
¡ùÎÏñI„İş2ò‡¥
|><²h.ü‰İ¯²k[ßmnô×À‰Òğ"«n1‚ªêÁ\–îÀP€1sišß/ºñÌ…'×€›!™L°x­ãu6ì. åº2Š=!o…Mõ=ÜBÔè¡hhj:¶¬^ş#ì(¢æyrTáŠ`-­AslÉ·Ş|Ê—²s/àqíx´+™`°K'¢­ícOnÿÊÔÌ)Š_FêH5ˆÚÉÎYX€‰+¡˜4İ8u­ñÛãñhíÇ~†Y¢3RpZ4;—‹Ğ°²W4sÉÊ$bF§	9ÏŠ´««Ô#±› F6à %BBk%Q/~ßëíÓ ±MªöëÓ½Ñ¾Ëø7B²6¥êêÀ}tõóœ)ßgï÷çÇ•£¹cK¹İ“+oŞµŞ–)Æ½Ù²£ı(×£Y$ìâ;‹î|hö”¹H™(,â¤¼4½Pb‹©X¶É
°~¦f½w¢Ìé\Âã¯Ï‡”ÓUc#e;ÌoÀï¾“Ã6VrQ¸¶^ƒ‹¯?ù”P5ŠAğuÂ^à”®[X,óy\†RD®"Š£O<ÎˆÊÛ ¢$j=UkM:’Nà@ê.»ÖL„¢‡úr~º©}W`äâ]›à6¯=°Í¸0¿ªĞL:Õ­Æ%Ö?Ô©ıK"‘¾!Pn¿’„¡ä=©3®MÖFü:g*u’½÷RÚµ¦<;Ê«Æo7øÆíU»¸ÿ§¡cvtuzÜh
bî˜—ø÷Ã,ãºŠhbÉa‹ÜàbŸR—»½d4±Èï=†û–O7uÒÈ½»4´pÄ.Gô7¥‡ãµ†6¸écÊÉÎWÛE˜Í ÒObW½td\ïÁt0çL†
k¯|40‚Kİm6¥JÅú‘¬ç×çî2rUåùº:	<>Rlİ	Õ’ˆ«¡f_áîX-f0Ÿ¸V×Nå‚ÙªC§Q/àªö2Ñj)£{Ü¨2§/À";LşøÜ„škuQH¯D¥¡Ú—WÅØMÄyÔ³]+Ñü$Í¢Ğñªñ0ŠÖ]À“Á2å1 »‰icO!®ù;ŞæUj1³¯
™‰ô¡sº°dã[ñ°á7»Åçüò³ã”ñÚkî4Zh‹èw›(áUòˆ¢tÍ¶ÊÌTE¼T9qIw”5$¨ <1i:yMI7–\Æsä^‘ş¡KÙd­Pú¯Õ°Ö+óæÎıL!m\¿åÖk¯U«“·¨BgÉ”•€€˜G:öïŒŠ{=†àOV²6^ûÜ•s»Odƒé7ŒÃhd½/¤k.%İ©~şLv°r_Ê\µ¢¬‘è@aíbƒëÜ+j¶í#æâ#_û°»ÑCh>•0òõ$Ö§“Bû^B5@š§Nüöú@m¬M5œiTãÎÈìÄºK—5%'m)Ê^Çá´5ÏOF‰³k¡ww+Œ4JÎ°®LgŒ1šU¯ÂÑ;Ğ.–Òõ!^q.ÃÉ($ídÖèXôvx´}„ñD!VRé"ì½*ÚÚ…•ãâô¦ì~Ög 5©HaÈÔZ’úP=[[¶ÆZ¦Ùo]öËmböòŸ[’ë×œKÄDi&J¸²‹Ës³W_æÔÚ¸Hæò²›)…¦Ã©ºÙº0†¡1÷¤³ãHHåÒ[Z•è!'‚äğ¶õÿè÷F“1š{Dµ&dáŒˆlmça×p ç­À&æÚ#ó>·útuŠ7Ìu’×®?÷¬İ<bw‚'H<m«£A	ÄU vÑŞ
ÖvP÷^Ÿz\áEÍŞŒeÚÉ5qO`üÂFëTpW¹»²<…]YÂóÀkÖZ^A²îº+<öY´iäOÌ%yE€­kY;Bâ“¯ˆMoÊµ7ş­ëÜ<ÚrÖõ5{8i'>Åc	qjÉ@$“¶å-EÖÌyº·g«kÈèr{7,‡ÆG¢“\´1e{T×€bYø§‹øb‚·´#=`,ÂÚäŸò	¬ìØç¶ÅóÍœºÉl=MşWTó‚8*03°F´wêBâŸ\äÔ“Ÿa—¢Ö·•ªhÃCû$y²÷Å'›½S âÌùC‚.ß[[
088‘³af#­·!ôU’RàØ†BûÖí_.ÔÉ éuLÎèñ‘¼33ßô-Ê{ğ»À‹`‡‹L¢Êïû—Ûüjj”dHRß’|ÄØX-²Õ\„ «uíeï©‰@µsÑ‘[ÅßÍ Fõ‡‡0'v§æQF„Èƒ&xÜTo5Xd ëw}}¯˜i+W¾o8ìÆ>-†Ø?pææB0®ÒaRšÍ¥¥§‰U'ü	à·µ©µMèÁË­o„AaÑ¸ÒwÇ€5&ÛÓ£OU)YU8Ú„Ã•ÓEú¹(ÑİÑC;rcÁ-ÿ¨Ìä¼&CÆ:T³ñiŠcÙˆ9?z¬X}'‚‚eõUˆºHW.bˆsÊşİé˜ÔĞğÓª¾BÖwp,0!¯Ô$(¦ú}¼|ÙõÁ¨b±İ[FıÄ€E…s Òéç÷€we:™3røƒé8qa&E­!ñS$4¶÷éä+å·ÿãzş™:«ñl›OUÈôå4Ì‡»áìÊí~”³'ª¡C>g|4š:uÜgBÁ”¿–Ï SØ¾»cq<fÈVºyõz@Î ælÁĞV°Tò|¶â†èPÊ×äæëÜû§š©‡k©š'3z·_tr·ÒIœ½©J(âGd3U[×´sAê¥³¼ËCuÈáÑe¼ZP®Äc_C»õæu
{M–*İ©!ÍŞãã06ìöÜFäÁŸÊ4do	>Âa<ÀÔ`&ëŞn v¼³“´D/ÖzĞ«e©Ÿ9V:fõÉ\,ĞµÇ¿!bhj€½j‘«T•\ü,çƒø&wÕà„ğùÓíæĞ½Ù>Œˆ*|·Kè®|â ä·)¬#H$~“mÿc&5´}¬úá± ¦Ìf=İiÅ`¬Mø‚².Ñsš	A° %İÑg¿QKwpx…ç¹,<à‰Ğ0…­N<¼:™ğjŠl,ø—ààÿ
³w+? 9X€àÑÑë¯|jƒ”•äº{˜jµöÃ†à+:I&Ğ]ÈY&oŸÍCEÆ«P‰®+©´$ÔµòÁÍOêù-€Pqİ|~Õ`”ÉŠâ_¯Î‹cë‰0ä6Ùï²øf¼WQ`º2âà¹sÎú1Ü¦ØUYÃÅ©œĞ{Òïwï^§¤›/YC(øê xaƒ¹³Œ;‘Õw÷US3½‚‹¿JÈúÄ¤7ØVY^ã‹wó’Óäymq ¤;$°†Â¼çı vä%QØeÕæ·Ş9ñp‰PÒ{7Wî'úáoÀ‹Wi¹S˜ä^!¡!P¾ª;¹zÆ£wº¦íÜƒ‡á‹…•”Õ
¼"M¿„¼>øÉ†ÜŒË€û$ĞKoå_ 9Q:²7ä€…â6væ«Ä*9ã)oÓ¾3Ùp’4ëFï½"&|G-)”Š%ÿ=0{u)úp>*äôD‰LT:_šãC|‹ud{cé#yG’ƒŞ(æÊÀ^¿yí`Ûóí#7ŸpåsA„
¥¿6Q©Øâ«¨¥ÿdÄaÖ¶ÏV§Øõå@ùä+şk/û³Ïµ÷L·j„wzóúÜàÄ:Aiî¬uäf·<_ñã½TÉ¤¡,å‡Q[ìùLÔ;8³&MAÊ`ªK?ÌÜkâR²ó 
RgŒL·¥ZÜï_¶Ÿ¬s‹§@X¼Ûîš™EÈ^âkòBéªX4ÄĞ KAœËè>ĞÛ=.Ğ>Œ“²Ïµı‚=øµ¶ 1?óX\Ï~˜œB­É İØóíi¾Şè3S³æ'”ŸîH&4ŒDgó\½4tñZ¶†¶©‘f_¼$û
'¬éuÎà›ùÙ¡·S¨Ìşòrh<®œZ8OQ"ÙóÖŸy¥¨C«¯gÅãi‹’#±‡á… ElºÜMÖ,Í»Kï‹NåXŞ;÷B”8ˆÊ¤ı¥|ì³oß’hâÏç€…ì£Åi(Öï×]øtcí,À*îÔühYuZGÖBíH3Àz•§K˜ÌaÅÉ¶.Œ¡ØWoáf OŸI½!	¬­Êtƒü¡iÆSŒ}°?“sFûj×ÁÓ…­¶îJ	¶
és[‰—i\vs ªÓÂ/Ìà@é™©°Š˜“T¹óàì¶WÜ»enÆº‘¢…×"jSQ›ñÆÇoàˆq~|
v*!+QT%•áß„œõG›¿vúæ5ò8ÿ¨Å³úÍè¾y¬¦ yÎÔ±†¼Ö½ÇAšèP¶24zQvé9¨ø}Ø&däy@Õ±œ³nÂª	úÂÀˆD×5ËÁìæ —$®¤yÄFrHä*cß¬r÷¸'æy);=’BÔ#”•±¾8”`<ãEç¿g¢tl#µg“Šñs§|°@?\¹Âğ‚  Š$f¼¿çxaØ$"cWúùj3ûfÇÕ>“øÛÚ¤^8±8<ğCİjrgû’Ÿt62{èÌ²Óİ*¶×Î‚z%3® aU}bş=ækNÍÃÅÓ}°µ\®MP€¤İ\bAbÄaúì*¤ÒhA5¨÷Æ”’Àš Ôò^°T+škwcvjá]ØÑ ÎôÖîœõÁn?\7WüÇÿl0†’øî‹íÇW],¬S¨3tCı7áÿĞíwQŸı¤Í„¯µ”µ–²ÉÖĞ£oÍ^ºt²D¢-â©]óÃu;×_”'cäŠ	µü;@Øœ$Â
 RˆR×Ì¢©ØHm×ß†ëı¥QV×m°GÑ-†¬Ñg@–Õu	oÂÑÿ¡ÛZy^R¥qæÆîûÒÖ*?9¤-™©Dø`-L¿¦áN—{äŸ2
‚ê«úHy9¬÷õÏ®„ëOêÄæ¯,ë²Õˆ¿Ç—‚\}ôşÍ=t0¯TŠw&¶
Dìó#–ƒ¬¤ÍB¤r¼Š]
¹êÆg²CÊ§%ç"‰£|¥)ÀÄg˜¶%	 cwÏ§ÓëÍº„¨ úŒÉ2'Œzåz>Yä>Ù@ÂmYo sÜÏiCĞÇ}Qleˆº»4{j’[6t¡U¯Û16Êˆ°Ñ†6øuÉm{a÷7nš şZà‡+~GáOüHÚn\İÃ¬Œõ–°¥OäÔöŠ–ÆGL]ÛğNF¬Ğ‹ø€Pn)m¯RxKÍºÚeo!›z²£aÅ°ñ×Ì¡IÎD­ÉëèÑn¢eC­Àó·%—–5ÓoÌe¸®îô|‹òÈ¸û:x”TLp¦ ]&rúÆp>¥^¢Móá-^ÓCåşx™õ{Q¯kê
`›?ü´ÛÏ[}¨¥t2Ù/ŠÄextj'ßBìP¥û}f•¾¶ıªˆ«pÒšBoûÊ´·ü\tVØ¿3æ÷±9dO@¦cX	q×”é¡ÇœRXênX 8bÁ—ƒÉ°úÛw3“ä<Ôéîæ†–djnqÓ^‰4„ç££½ªÎ¦Ä¯DvÎB§?œèôÃEPĞyjWû•b8lÏ¹0%ÔîÁQÀH¯–‚-ş®I{ëÙg"Ô~°ÛK–ñ­Xu@IH·\Ûy.=}æg5ŒéÀdÚ>\é$ªnØx!DFƒ,J·¢5ò6¼CÔë—¥3¿•’	9Û*MêE­Ø–nË1CGÇ
w ˜´~{J_·¢À½Z»Š€$FĞ®,uùcØ•×É
ô‹UÍ#ÃøKÀq±b
.æ‰‘ië´ÖqŸIµ1*–ªÎ»Ş…ôY Æf]á`Ú×]ß›vûÒóÅà¿½–ŠZ4àç@â‡Ò^	@„¨ ÖW‰J»wÍ…ğ»·ÉcÅç!º£Ú_ Á¤S4¼üHjêxî]c¯:q£Ï¡ÑZ)ôÀ¢¯=¹Uîğ¦ÂHGYÁ?Õ‹^.M*Ûº	W Ùçğy)®@_zTR_´øñoN{âC¡Æ†7õ)ÕîqASˆf‹¾åT~$ìÃ|,ÈÂ< lü†b[høu‘-ú¡¢*Ê;²¹}‰–>§D‡İìÖàÃ†hnÓx¯¡:‚Qkü$–¶£Hãé*ÑZ=D°ß÷v€šÅi^qˆkÅ›%Àãs÷C	ÎÏf©IWûGQ	$@&${5—¬{B1‚–84Ùhb¾·ù£L)Ô¤…p/?Á§ûà´‡)ä?Âèh¨.sĞ;èãÇâ­±‡íà7>\q´fQ…:½ƒĞ57WWlI¶æöÑ@Ç®78Ÿ7ï ³.à`¬ûÜß¬ë‘æ÷»ê=hˆJÿİkæáÿ‰ø¡òf[¨Âù‰Ş<ô>WÎ¯ÿ;"	)¤Õ›ÎÊ3iÊá ÆÂ>ÔşG4Ü†
×ëô‚Y×.MßßÅòß91ÖÛmğïöˆ–5¿{ÆZ@`ƒm6‡y„„O©EUñ7^@°dUJêz‘Ö¯W¦1-tK“Ş½è“GÌ““Œ3u"±ß!—6š[Àïÿ@¸4»_*Òİè‰ÓHö'ôÏª!œĞ¯ÉDDêà%oLïÇ^Äég	pgIZœAÈğ¾Î8…Â§Ø5çíƒèD“hÕœ˜*ÂğhÊ73Â_Údp‚å²ßKXqt½/JˆùGĞ¦ì´E®¹Òâ3ºä[A}Ğà3[/‰ë9.ü»§ —˜¾€z¥dFjŸ—ígHQò¥eÈgu;´@œkf3ß ØÆï‰z	“4eïl¯]ÖÃãè…g©iá…ÏCS‡º`ĞÖĞs¢nàÛ.
cÄÉ9o&yPN	"ÎœT|®üa¼RÄÂúÌş‰­ZBu*F1ayºÇiR©÷êúøŞJçÂ¨H9	ùn&0b;!„kµ¸ä”ÀÍÏ¼îu¾dZîaèa¿5Éñînºèíƒæ	Ú“ÑTÂl¸§vhfÕ¼Ğ…v({!Fx5Í©µt•¦«á&ñ›	èiuk*Aq4˜¹WR©…¿,‘Á“ã1¢…>l»=‰ÒYÌE›™p®ıÃä§€×­d˜{Î¤÷·@‡­n™}(ùsp¾å)PÂã@–dk.Án™ò7†#©›Îoù{Á{ÄÛ)7×oYoÑÂ9;ZPİ–¦ø¤Ş„ÅVk@¡¹uì` k„Œá‘oc<5D
W+Vñ$ù,á©õùó`ä’Ã—%[?3 Õ:BéSâÀŠø+ö 2üæ=¨´Š	¹M@†-¬#ì÷òYÚ–¯‰;ÄÒAvê,Ú1xÎNÂÚ*oŸ†‡}CâZªHÀzóM3²Š1É)L%p>‹ßË1ˆlÑ¢j{ï¢­D¿¶"€oX;<`.7—Af0ÕwœòŸPL¯Óğ›ùah¡]¿ƒK^HÑœW¿k”/€m#À›	p
Ã1ŒŞş8K’è8‚—£W’rÃªP5	ê$ïÃVßˆºb4‹¾ëew0Î\å¡“ØİçĞ*‘#TÛ˜Tß‚}[Â›Íû"e ªàQj»ºGš‰å‰úä&p÷”mú'BõğCâÚa€Ù´Ğ¾ßzk:ÆsÜÈî¢A,Rà†Æßè‹|`ËÙ,\µJkı€˜FÓŞ¯m÷EñÜRçºL0Lo™î>Û7ß£§å¨=´”M^X*qfN±ıõg¿	¢ÕÂ@¨ÃN”Z¦¤¼NÉ­¯Ñ)ÑæõPø,Ñ ÀUz"ãÏ7Œ~ı-TU¥ì½XIR”sfÏÏ:‹€ ğ:<6á¼';ÜPÔír’(Äëo˜šÕEmÎ÷pv{™—á”¸E¶"!½ò„âg«—²•R‚·iY;ˆëC½ÜÀÍ&µ@™MXP„q),ª–¸¨åüuŠì`R~§7‹Úcóh(0AY2kh‹¡‡ö‡ƒ€>xlGFd¤ò_4Bœ¬Ã1[>®«pí«Z~È^%eg¨ùRÿ@6rQD‹ÅËâ¹KˆD}T"ç” 5¸­èÜû-¦œ\,T¤†?ô‘„Ÿ9ß15¬I!·fÿãÇH¼1³¨á ¼jRÛDĞ—†C-ÈÜ)ƒ&NÑØ'k¬.”`Ówoí$$(ÛäËˆ+
’ ´:3P§Zô<±àIyMB™vOqpğ¨PÙæÅ`åóá9(š#}îù‰V)ßLD)È'Å4©æëŒ’Í§I™Ş»]øY|ĞHÕO¬Ìxw«œ›~§ë°U(¸WRïëùƒ&x`zË Ä[™'›şœ†]äÂWß¡u‰E¬”%Ê¸Y"›3o¢Z½‚·¶MAp~'Ÿ–yHßÍ'›q½Ğğ[D"÷Nu0èLAâ…hå¥TÂ>¥Wlİ>+ÛàJÁ«FG:¹ûtŒjQÕ 
Yeí²•QKxm.·³Òd²øûV$Ô>YßËNØZœéI0îÕ<5@2+ó©¢3’#ÖR=L0P=un/*Œ`Ì‚Î—oûxË¯ºz%ƒòÍæ?Ìı'“Z]JgNÍÜº™Æ'•9óÌD›81ë'«{³U¾|ã¬BÊ×H4Wynmtp‰…Öß#ÅÅûß)a¦X|Œ~÷O¸qPjıo«J"dLÙNhéÖ‡Ü`Ju7I—˜ªfP™Ò¶$äƒ¤·áXå1åİã_GÜÛÛ€?)IbÉÙÙrœ¥+·á9NLPµuØ•ÃE]]¬I£¼ó®0áx0¶¡dÕK^]üšPö²…Ô]®ƒ
´z!„œtç·Œl´µ?+§î¿û’(40#" ãĞDKä?úäøLì·Ü¼;u86§—iÓ­dL“æ0ÑˆcènÚıXù² ûœ:qÚM¤¯ÃÒ¨iÎe'Fš ßíÁÉ’€ğ<l_Ÿrº¡'ƒæµüyÿc¸&Œ5®†ß`IvUEXœ½wtænyF¾İÏ=İ×G|¦Æé»;ş«?ìßşB™¦‡Œ‚İìjóßœ™¹Ò~X'¡[‡hÿÈO¾o?^
2m+ò’ûø9`¯ÃzßÁïGb9óºjÌC{ğ¨|	 „„Ğ®cIy7¸ÊİRPá˜/« ¹6›X |B:.˜sØšó Z{%ŸşÄÊJ7ùVæÒ°×ÌÀ®iş¢ÈHæ±g¥<ÇWwÚÊÃhˆŒŸ~fËÎ ®äşÎuhk„‡¶	à´éø7ùÖİÜÌØƒwM!z„Gêo€tVBˆ‡?ùŞlÔWH8¦Ê¬ZA7ÄdÖf‰pšÔb2ÄÒz¯Â>’øA©ŠĞHˆáX’4À4YZƒñ‘"4ÿóküğ¡t¼²ã/©™¶Ô4s·çÀ0dº™‡PôTÆiÙo“Bá~-ÌøÊ6äSìü6+‚´\Š¯óÄ×î~Œ˜ÁbQâ°g ³[q…¿Ye·ØäÃÁ[ù—òÿŞğgIe¡|Ée ©•*»XqìQ"x5bïE×§E'œbğ;¸	cHyıHY·¢ÙæÀ~ZmSâ:çæ£í·=7Vhéé¶[ïÅê}xÉˆG™T\¢æÓxÉÙ<[P^Xó~laÊÁ»®e4¦¸3,xÓIUÏŒŠ²A¯òäú²£¾=ø¾öxzoÄœ˜ *©\ÑY¬ôˆ™ÄNd¬ãäªÛ‡+{$¡SUMçÆ»gsPİãú9b”€¼$¹xä=¨4ójæŸB5×"*ÈsûÕ7è‚ÄÔ„Ìˆê£À°iìc!»³AÎÊü®Ãy›òº/#Wåª/A²›Wcï¶³)Ğl¦c·TÔ†ò7Güô)uÙÄ@4¸eq0ğQ…•CƒÇÉ–G®yY™£ÀzñÙµ¬í=l‚†¬	B b€Õ)şg¹ƒÚñBêÿÕx¸A†B¹£lA‰˜õñ*2Ëïğ)´Cº¥“Í«ï†ÛÏÌ„äKMj*Ñnv¾ˆÜÏ'ù}Úm$)ô
áV‡h/sqañ6Øsø¹ÅbÑñ÷Ç!Gæî5~@ß–â@ÍY	ô¾”8p·˜gÚùÎIV¬‰ƒ!dç¾ÆCûñËk‹Ëä*jã0¸°òŠ\|¸)[QÌ_pÕò”V0Pß³ú;¢Ñæ§if}¬ñ1úvo¯ÙÇùÅií¾ôËMJ¯Mx{¢GÜUA!ƒ†5~®cçk>skn-›ÂÙµÏí
‘¤ÿøÓ©=MŒ,v[#4ç+ _«epQ(qbúéBÇ·%¬ÓA|)f q «4,ÈóÔW¢²¬Ä¦Ç_¢e¢U9æ¿[]ü”›Ï‚Fnºj²ê±•0®õ’Ş<)Ì@#­–0j1÷‡ÕÏ ÕÓX¼Ò²ƒæ¦1wˆÓM€Y1ÊşïC«&—Ó^„iwŞÖ·­•„†Ó;fNĞ¢Üs˜Í<iù)ÇL±0@c^-=Æ©<¹Û×¶ËûH£Â4Œ=ñ$‘ÿ
´ÖØ1•†9OÙI#HÁ!D	]°røß‘œZøìù:;P…Í¨\(«¶òƒ_îáè˜É§¯†àCw£c¨à¬ü¦u£¶ ˆuëÓÍ{Ú3‡Tç´úÈflôÆW¶­Åx˜°åMw—nëO‘,õdé-âÃaÚ±–Wïı§¦÷ou”©@ÍÁ€êè /} İ?2ëÙº‘0èøƒ'ìÇûr¶t^ÇÎ’Û&ı%²g'2ÏQÆŒ[<ô'P~Q~Œ¾O¿ùìugØZ˜wéÜ…Ò®ÅŞ»²‚Â(øB¹èÃäßU$½¤³gQ…TÑƒŞiĞ¢Ešöcçë”ÔÀPiçÙ¢ıŞE±#'åå*ğöT&ÂıùØ”YÃ6Yñ¹Ív•]Bjàù#XL¡élÒú_%§âõØªçâÈ¬ìë{ªR`ì’	T®çDøI¢§î+èÈ8yšÍD-„I%vş£ÿS½ñâb~ƒfí—•M|)¥û“Ôp•¢`™L†’)Æ³\,.L/a¹¢›yÚ3û ˜MÂº%N¾Zjô™Rv¨ÿ|‰¢·ş7ÜµĞ.qÇ¹¾„R´'dï}wc™ûóf7ìÆ$(SöÔ-U8É°ƒéÎGúÄCòŒ[7—®ÔgƒùÍ²Ä<¤–ğ=Ä|³ª¶İÌ\×pçìá€(aAÖùXƒ!k+EŠÁ @q?˜°™|&>\×ZhÙÀ›¸¯½óä§é%ëØ9Ãb_w’_ááX
ùJ=qA°<iÇ{oĞÑqŞ[ülYšlù/Aü§“8©;ùóÿµ-Fÿ	ıcˆŒÂJç!!8Uh—0…<uV/ƒÀG	±şx íŸÿc”!Èú€·€ÌÛÏ¬ÌcÔ±Ô:g¦Ûô1Ça({ÒIÿ!/SûyÏÇ7Wm!ò3g¿ƒ2JË<àn˜¡}È#Ğ'ÙÇº“u$ü7Õ?/£ùó¼†6=–”7üı+¬x!pü`ÒS¡p¢g¨ÒåÌºÉËGm¡Ëúï0£èäÇØ>$E—ÔænRL4"D7 ŸfÁÇ	ÅúUdß=]·ÂÕş4÷‚GŒÅ5W­:•ğsä³*“·ÿ„Âvú	 ŞÍ4’Âã?—ÅßÀş)'=H£™
Ï<ğ 6ZCÙ‡ÅPüª©½çb¸Å´aûÔ¹º/1,a°Ú	ØÔxû–5ÙR€ÒÕñû‡ç¥ Èê%´ó¡À±À¢¬¤Äş…
(µl)|F­>BÅ_©;‚G{\€öÚ©æÎ¢FŞ)­"T!S¹_“t@Ë*ï´*(êÄ.ûQWÙú½ä”ˆq+	08ë·“Wm ‰¹,—(æˆ Çµ6ô%0ÄäÈ.Í(ÈºÜÌéï(«LßÎ¸ÜŠúi:ÄEœQ?ø†Dàú«²
¢¶	İ¾mC Êß‰±ÁÆ:•ÍOOŒÆÁsÆ"_ÒÏ¿g‡ùUìµ kƒ,§gã?ÁÆ0mŒĞª†|‘«	t Mj›G»¶Ãx
C¡fv³v"Xœ¬PŞŒğXl	äÃªk"EşàJn¯0şJ9‚˜åîÓWñş§– ğøĞ=P&Ê
3Iİ¢N0-ŠŸoWV#áä§î\’æØÕNqÆª`»Aä´«t ıoTñKŞÖeÔåú#a¶0Ì$HñVãÓ+K-”u“)…ÌKWÃÚİ®\‡ ˜QEõ_Ş 7k}µşãÎöÏwáÜ&ûär#Lû[bÃ”ÈqÑ#oG»c‹?lû@{J¯GÒw[ZÕRÇgYîÓ£v{÷¶à>@ÌÅ‘ì90<‡Ô_­Zg½æ3o€ğœ¾gèfi!¥ì3Nì*çäÏ×Â<MÄKÌ(ÿıß²|°ûE“ÆèÄ oŸ6/+‘¶€yÑm2ŸQ^gPÄÌ[ DÎŸ—[
)öï„0°eáÍ ñ3®Œ,µ`¾;™ÒB•ü½·Øeõ•û¯LQ7n.™o÷Q'w'gÅòï+÷zÍèĞ¢Œ?¸Âa™=ÆÅrt=*+¼S\n ès—¹Ê¢Apì(.ıÕîH«’o1<—ú—«”zÔ7`g[{6i™D–?¼@Ïy=B¡±ÔßPeÒ2ì97¹q[˜—†ïÊyY3$Ê6
âï‰æ3£Djpª "/³¡UF‘|©#‘ÉÀIG˜ºõ>Ámrğıi«§3a_7On;2–Ğƒ[#U¿ía#Üz‘êÿdrV"lû%u¡¯±İºH¾1íšéeòÒÒŠ)ìñùğêŸHÊ>â¦’5ÿôLÈî4Ö«I½ŒÂuHİˆAœ.pääımâ¢ /ÚÄÂÎòNÄìn’ók0Ñ¢Öš·_µT|t°D$âëØV‹ÉêVWgí|³˜ÁöÓq$¤ı¦kK‡! )WqûQ5dÄO+İQšnM:ìÍ)B?ïÕkğÂ™¶œ3z¿W
ÔP–š6Å…õ)7°ş÷…õ5\
/•e—”‚İ4Œséaö9Ñ`¦…uÁ `k~
\ÇÙ÷ fÅ¦I5€–BZtÄ¦[{|ï‚®ƒÀÙÅd™ï+¨ôj£¨áuoiDI…’}¥Å²şYZ_ƒmâ±‘¸úiÖÄ¯~)×&è
s– ÷hÇÙR¶N¡Z'Š£œ0æz\æXÑ÷µ+°h2Â™2ªT¦«àIGÆ¡'äÙ}úÜ¿2-rzR¼WšV¿oƒ­%-rHªµij±Õ°ÔŸuaö,.Ï€“|óÈå?“æJ˜Dxâ®Ó„ÁŞÁß|s¡˜tÁŞŒ“bÏ¼şêİv õ+Tfv [z(µ(ØÄá4­‡G´0.ªkŒC« ç¿9®ÃVT|¤ëÀ—$ïF•¦ê$%İKç>6™l¹ônwPp¿È£ìï¶µ•éÛn50üZ–|=3a·›u!aD$’)´åDúÒbÀå!PÒ€"±êr¤ùZV2ª!"JFŒ$Z˜»?ÈöÎÑÖÂˆ™oåÊ¾@p¨”`^Y}nHQó_pQhN¨Í,ïãğ—‹¨ ZO¿*À¤-ùo¶pKÿÂÊ>ÅsãÏ ŞM4~|¿ˆb¤ò2´µÛì³Ï“{ş´oFÒö¹ª,qµ%z´Ík©‚’Ç88š	‹„@âîç‡„àöÇŸ;êéb¼0 ô99[Æ¼}¹0hÅKÄ#E¿GiÏŒø+idêòø\übÌ·Ïã¶‡
Ü.GäªÊ©°a†ÙÓeqTû ”ÜA±‘ é±A¬ô4H[›K\ÌRRRr»`èïUı¸cŞÎøû‘pÇ™ÚÈ*ƒ›Û\sG¤Œ°&şË•—ïÊ®,Ó»ø´bo?á¤:Ö_æÖq‘¼™Å6†äŠæk®-¤óñ*Ò 0{aı wÃ¼Õå%§ÿ®¦_ºV[`©Èñ¢5ºà˜ÍL;óäS„¼;¹ú7T¨-Ï;*ñ—‘»C)ÕCqÅÍ+$ Û#*Ú·M¸º&ÕkLµY0\ßú6ìŠ2Vs°ÃòÂÉ:§Ì¥ILõŸ«ş–+æ÷\"×[t¸©ˆşKø£)w)LzÊ‹nZi˜÷¾¬ñQÖ\û~]ù·¾¾3Íúç/âƒÛ†È1%T¸:>-c]3ŒOfÇ[(~×³Ä.HCöÔ_%-n©¥T„¦$Zeõ±¸g1¿½hà²nnq4Oß&‰›>¨Ÿ¦åØ30p‘ |{© ı^¥·ªPÛ9æÍ@%{5¢ÏrÕ´}¯&RÚu}:¿²±b\ü3ú-aŠ›zæäÁc|”DWÀ6âp´Øğ³­8—U„üeÀ;oèö„p@b~í™Õ•ÉQ‡À“üÛ1äWÄ.V¶S±f_ßg­5‡  ‰/‰§rÍÜR@Mä4f£«iõm°±1‹ÜM>t÷4ßãŠºß’§[‡Ğ>¬d5iºå°àcßßH+µYæ!íÅ¤åd«"Ûpş!Çÿ¯»WCØµoµwêÏŒNh7s„¿7³ã|¶õ~ğsàİYnk(œÊÃ¤)û©FT:¢hç!Àn„Ñ7”E4Äï8´9S%Õ&!"ªDüÎ‘ßXûb§¾VÉM†²s-»M|ß\´øÑÅ,VÉ4¸İÿ«¨u˜7å,íŠÊRçİ³ÁQ¹Õ;­†Â­«{Å‚w›´µ’+IqÛì—Hº$j©ä/À1Çş÷hT9/L‰SZBm¨–  ,âs4ë¿¿. ô½€À}©±Ägû    YZ