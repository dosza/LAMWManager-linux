#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3859790559"
MD5="e067eb4cc67a04b23e94bbf80170aaab"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23928"
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
	echo Date of packaging: Thu Sep 30 18:36:15 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]7] ¼}•À1Dd]‡Á›PætİDõ|‚ §»·§ş~–s'ÀB‰'÷äŞ-ú+àQÏñ •e»&F*ïÉ²´mÏdË|v®7«»İ~4Ö­TNó	19¡ÿÁxNçô?ºZ±ƒP˜`0$7ÄÎìáí‚³V"Ñã…°øöK>àìÊa×Ãß2÷å¾Šë0ÍØls½áu…k¾g2‡„hlUÄ;†«äŞD2éO,ê;íÓU‡µL5¨U©«ÙËµLõ—4…Šùºó¥,b&ÃŸÃœ‚ÇèÄßXdg®D¢²¸D¾X@²mùÛÒŞ÷X‚bã³ëqôÇ»c¼fï,ògÎ(—wDÑÔ;šŸ8½ã'îB(`ş•ƒ¬Œ59N$0BƒÛœçŸ1Ç@ÜŸœ8µ „ëãâ¹ïpz·è·ĞyU’e0ê¸©Ğmå/Ø»¶MÀ©ÈfÍ¤ÉÙ[_à–úÆÎÑh àª¦èSuˆ£cÉ²*¡o(ûŞ3ÿ§{©Õ›Èvü9‹×+—w,tdU¥tÆfZç×‘X¬bÌê„Ø¡Çâ®ŒjAsòñ–:§^gAN¹º»ÒÉËF—7µD½è«i	›‚A©äúFâ?‡ª¶‹pÔ dG¢˜6#ÑfÀ‡Yém¯Iş]qguÛ÷3/„À(-|ó'ÜL°¬f©	ĞÓcRoiJFÁtI†Íj'ûtåY™™Ë_Gä¾IpB }şšy?^ŠXi½B2wÌ{=íÖÑqtÛ&ØµÀIæa®Bb&Æ§À§Ì­‚d	œJısØ(r)‡>«PÒ¢g…g¸’5ÔÖé9ĞÓí£hwB³ˆ#Iä¿éÀW¸.!ñ3AœUûœı"„*¹×\Ä¨ÚÁ±×|~%Ât|7m£ğ,¶Â¦½ó(¨
¡®eæûã}òáËÌıìı—‰Ñ
ëÄµI	ÅòtV‹`&ïTš Á‘¯ò—å–1hú~y*ñŒ¨OV½ªüi"ßñÀì yLæºC¦ú'û×pU£ÙW4jªÎ×ˆŞuÆa©—Ÿ²håvZu×S…œ
®1Õ±gµÍšÄ‰¡Ú¦—w[©D‚ÔûŞÊÒÙÆTçX¬+“VşØTèS±FKËğX3ú]d?ğCv¬ñ¨áa+…›)Ipí™¬>1yÜ§³Å¤	æXóÇ[ÖUHìÏ£DåÚgÉV ` à°_Útç¼µ)ß»fdÏ`)™cH ³Vä·åWp‘Ï:úü`óLùË^J„ƒ‚èc‘h*L¡Ã§Íâª>ù2MiPZfÎÉ[¯°‘µ¤‚ú–Q6ì‡;ƒãÚQ6şò•f v‹H¬?½ÜABÍ;¶Ôl-SEM’¤EcŸÏÑ­7Â?ó_Û#“q3xŞ„‡˜‚Å»Ú½@¯Yÿ@õcˆr-Eıí“Ÿğ-øÙò"CA¼LN¨sA*Êß1¢)@¢cù¾,º€”BÓGWLo:·6aR="è"G©O‡Gû_ùƒYj9[*•5ìÄ+H6€	hIâH²—ïĞe„møÜáeÏ	bR<Ûã‹|»¢âÒÒè ©WCÁ±É$1¥ËB/wv†tA•à!Ç¦ĞûÙ¤-÷TÉ0j¤°ÑŸw[K ½GL`šŸa?YŞx™3ÒoX‹Ş¥‚ºˆ_òÑÇnéyäµ*‹~h¸}L;iê°y&Ó*‘°À¸…tNŠWÑ»UAı|-TlÕ„ÊXbŸ·ãv88–œÓs‡¾Õ­õÌöÈµtŸBÿ²kE[y§êĞíoG¬ßæËÌ$}Œ™	¸¶KûˆÅ’¸ßUÕMˆ;ÒŸ
TI-Jk’ÓÇJ„©”Ã-q_.
sçŞl´rnÀ…€T´è2Õ‘Ğ«fró1I$èŠ]Lªöœ¥×Ş|e€ã°G7h®ˆÙâF‚r´U;ŒÒ]˜¥b–ú8‡À
=ÔÜûÊHf`SÊÃ‹†±'4cÿDË¦XM§Á,IÏdù¤ñúP°ƒ}Æ4é¾Áù­ÙÄRÃ¦;¾ğø'DÍh[¿LÜTR÷j=M–æÃ½ÑN6~·˜{re£ƒşV2§%ÚìÔZ£²où•TwŠp^^fd*C‰FÓE:Ì%Äz%R!‚­äç#òM\ßp».-Ğ÷@¬wß¯Òø1	£ğ{é`ÀyO)-¸êê¯×L2è‚¢2zdæË‰2uvËS[ iƒ~“²ÂÇÙ[×uÂ‹€-JŠ2{õ®'ÒÔ›±˜—’«RD¯ªºn|3ÊîP¬ÓŞá3µIËq^RÕàsd×3áßYX‘Mx±ï‚»U÷hÒåèûÉŠJâ`Dh_YëGË#¾zo‘!1ààa†ô¡Ïh¨/[~ùés>şrØóÏrœŞã£#Z†ƒ_¤eİM´µ×<ƒØÀH…G’DO¦şêPÚ%¾Ã²b~«ä`Ò¬¹¶êÒ…%n²hó’«29ı"¬)„ş<i©a¬.…hä $ñywÈÁuF‘jˆØØ•Mõ_TY™™AÛ‰ÙÍ®_F™Iİ}ím£á¸ßĞ-×ˆœ….À¨QK¨µÿ~ËßC-dåy3“:³Cäí*şŒõİW
ÇšûÑqns#³õ¼ÁÎØ1ˆy»¸Õhä-^¶Zí”2L—ŒE¿ÃPzfÎÖŒânÜÌÉ–‚õKÛ¤õËT~+’KRÌ»0´•ugí’Êô8ËÆQ–ØĞL¸²zM%&š×KÅ<ï˜Şáğ¸Tq'hƒ­u!A¾Øšê¤±EÀ_÷µ™£Ñbz©ÂLÀè1n§‡X/ÕÑîXáïèrrÀ”—,N#\|ø‹kÖU
k³Ñ	¥T§\òt»ÛŠ2È%€œ-mªñM¬]w+;–|îÆË¨³;º—×X'íÚÃ·Uõ¿œd\sâ¸t³0ç†_Er_¡^dŸáëÄƒ›œµÂM~µÙ( É=‹Ûê­ÀtÆÓ¼¡™6vXş…òÁRwù…o:RóË6ÔÈ»±qP£ YŞ”îB°…]xOÄ7…½˜–tN‘j±$µ§q]OkkAÄüŠ‡æÑ*›ñnÙ“« èÃÏ­yµ/u×Åğ{W]â÷* y1ÉEºû¿*Á`Œ¥Ìß~ìf"¥®sµsÆñÂo?•Rù „{yk^ Óm®cÕÛùï3X»¯5i9èr#«é‹³ñ}HÄ0ïvW•ƒ=q |ïÕ(…£´óğ‘ˆ€=ÇAÕÈhúGJéÛ‘0#è°0J‘†r"y|ëÔö1?æy+]qğ}øN¹,û¬£ôòC‡2VäKCF~0şCB;õ!Ä„¾SÛ¾$©bÎèR††xA¡&©ÇâÛ6é€Ä‹a?ä…ïÃ—’©@Uª’} ¼Ö%1+‚N\zóT6%ê•ìsTœêX‰ û§ë[fR~¼ö>Š5Ë*}ÍkZ•µÒù3cilŒÒüícV°ßütwRŞuq¡F”M.a¿œg. Ê”›|ÇÂHCŒc•Ò}¶©Î?óErş¨–§P&’2¢Ø9ğ¢Ú‰æ\´)Zïü«²ä °Iºt¿±v§‡Ën^fH(,˜nyÊÀ '‡í†Í4Ò)p”[ˆÎ¢Ä(ê¦n¶“‡(.şÙN"›N¦A¬sïClÖ2Á¤[Q~V+[ä|+¸ )f…Ü6tHÓ.Ô†dM	üõ¿ú{éäù—-Q}à+ücrcmgáùİy0Îñÿ×`òÛgXnßÔ¢—Õ7ÀGH;›ûòöwü>¤hÌk|[ÅğˆöEU™Àè 6nÉkÌÖ™„H÷×Qğ;Í¿fø*cumğ€Dg¹^ÃwLRrë–
bœÂ^8´/ù›ĞËe!¼·øÊ" 8i]!±²ü5™™DVZØE„[çgfk.Í¬Õ¬õª#†’fÒ®ÖL}tƒúà[_¥^Y•‘Ø½`±‹VC½ÒyíB.‹„ĞarTh'ù4S|(™»0üI tø l]:ÈOÜĞÑÚÏàXÑlôà×fA6 `~z<Òbeæİ1Y}Q¸RìŒÇ?‘èzq›h\øö'Èœ6Ä[‚ÇM»iÇy£¨„„ü}şºúgoá\+•S~XC?à{C¦ÄxQlW½]ñÂpàG‰m`5y_Ÿø×æ0¯'ì]Jy\AWŒ¬¦Úç­´tÄÒèLíEJ²}EÁº,‰uuäÙ©'R˜ajúXÑŒ¢-çä½KÅó¾n´¤lËÑvóy”ÓŠ5RæV—Ïå”3	Ğ¥™~HÊ(¢¾­bL|ñÁ3õŒqIóñò}’g-è±úü2A²%lÜİO‹NSî¤™ÓÎ¯IÂñq]WyGwÇ¢lÎVÑCüûy|G,5yÓ9HS:£d¿mÊ‚)ÏCë¦å&;ìî†™¿Ì21·†·2Ûò¯ÎÆKÆ<aAÖİ’tRú±ûKüÏ¤Ç^bD/së»##Èš¸é§½ÄîG9±?«ã—~× …Ä×_:_¿)Íøğ¼Ë"FË–D™<åñ‹ô‚‚¼«Â²ÕŒ–N#-aÔ'8ÜÊê²> ¢ˆ b€ÊŒìËÑŞq't¥Ud/Vªlcfş²ûÒªQë	÷5ÍfgñöªEúŞB÷‘wÚ6ÀÇ±²ƒûÚ´ğ|°XÇÇ ÖkJ€İ\OŠ‚¼QØiPüëË‰7ø(ßÊ¨i2Oÿ	œ±º«UY=–åÅ}áÅ(µJã†6š)pz"õD\ä¦bôãÚ
³zb>¤˜¸ãåİöøK¶veDºİ&Í˜ÎJG,ô_ßõÿeŒÓƒhÚ6YÉæ;á.·Âë-C/U£N$SÖ È8mõ|JÎÀW€kaÆ™ÿ©z?¿´\ïŞ ¥«%í.TBeeéUÈúÀa{À±]J‡¥V¶\²¸Íw­¢# ì|ğbşï” 6§“8yo]…öŠ‹èOàƒ½Cùx hâŸ³~Úµ³oáÄaÂ4¾¿Øzs"Hûd¦iı1c\ª1ğˆ3@°7‹è·˜Û\1§¸Šò+$	x9®¯_Ôu…Ùs~P'íòä¾Z´_øˆ¤!?ô‡ã >-®Kª†;˜»Ñå¶ä¾:KL¡+¡ĞØ¯ª¼ßbÆ–°¨×QtH]ôPUÃB
lN­M;,¸„ğ¥‚¡ 9;¼d°´¨à§Şá4³–Ëò0dÁl»;ŞÎ¶g­‰z]ù7åm?¼Œ0\ŒFµÑlß€ŠF¸71]52°Üœş¢kz3H–Ÿ–Xó#ÁØëãŸ‡€ÔpCŒÒ3'€où,êbxn˜$DÆ€7Q§˜ğµ4}“^¥†ÂmÙ;²é€/s
µãkií¨Å]•_Ëì4a&£(,-nœ²[| şâ\±·xğ
}|º¬WŸ8c© 7•$EMãÛ“ŠM7*ô^¢Ïq7óµ^U{F˜Ù$QĞ[ÙÅõiÂJ	&WÓ^ZŞçó¨ÛÈ¼ı¦ícá’hÙŠ‹g5GbDœÀK”„eKU7`Ñ5EÀ—øªŠ^şÙ9Ä ub Ò#"ì©”7E
mşj=HOÙNĞı¶7õ6šÎ{$/Áµ÷7Ó½ê¯„ÈÈ[qël¾á,^p¤áÇ÷àñ§ÕÉ»µ½í'÷Ö?£-oâ„Ö•Ï‚'ÏšKy}P¿_’=ë1êeŠDDÂmâ¨ú|è
ê:Dœ1êH“ØX‘´R¤…ù|Ì·ÁPKöÿ
šÇ4!M¿ØBîŠÒñT4Ké:T9‘ææX Ì¡ƒ´IJ¶&ÂP‡!7zÅ,Vgªè}¥VûhÿÈsìŠZeDwdTXb¼êˆåN¾ÇËæŠ]€œ’I“gòPÊl^Ïª‚oÉ)b<çjÓİ)°î¥»FúlÒ¼„§¯Û«ØÚ{ çæO†oun³ó;=„ÅXÔ‰‰ÎÇV¢^F]í˜¤ZÇJ"¿Î^ø8Ìƒ=˜#+LÓÍÛ_âà5¢4£Ügæly ÈhF¯×U|ú>–=Ç!}Çñ%æËÔN7d‘9F:Á¡Pér‚áŠ#"lbÛœ9©fG%ªN“€Š>kGãÚôi³êrU2±fë&àö17Ÿª^vWJ_Ÿ]üB‚–ı1QÅuÖ3ôŸD³©
k¼ ¿U|°ØgÄk<`à-N½‰é àÁ	4º¿Äë6å@Ş‚‹}×G£öc$Ó›7€NĞÙGÎ¶:î+TÖZFXÕ`›vh9ş±÷}[ÕD¹‚|ÆRÆy©ñ,Uœı¢«¨ğ³”X«Õ„Ô‹ˆ´ ê9éü÷ZqµİLU£“»İ«ÓçĞ© ·ŞØùÕÖób@T€¯aQ¶%­¿§×*º}<g(Ø•”PŠX­'¼Ê|ƒçŞ’¦b1€xé@ÃèAñu…Îˆ¤ÒıÜÖFËšŠ_öQ¬i.ØFK(Îİæ6EV°ÿôÉ!©¯/"·„¿g¥úœrUU€¥“ãÂ7ÿxGPôš[é”ËÌh¥˜T”Àór® ™0[Àq¨Y†Pw©…B:®Dˆ4Z0»é
¾±@ı ñcÜ
q®q€Ïå€hÌ1È+ÌŞ‰˜‹L#¬‚)6Î²Òÿ¿(ÃµÊœ±*Ó#ü<º6l×CC¹Q€§ÄŞë´ÓLXéè¦½8‘ãş„ïİŞë—à9©YçïaiVWnø+J)Éùs æ;N¹É”ÎÚË…¡r;¶ôJ5k_“Iä¨«u1ı€5oÁw-èîÉ¢	…ÄqËéœ¨†¨è‡ØÖá°ST[ˆæá–1aïY/ÖÁÁL‘õ’~c»@®Ër½`S7*¥^‚¯IiÂÖY¦º€¹¯ÓœyºwÆÛL>“r«]q©Ch™…vÏ¹+MõN.Å>"Òê¡0û¼z¨¡Î÷áàøC<òà{M”$ÙR†+HÒõhÓ†t †(`ùÛ6¦z±k4Øgr…^­7ÛÏ	ì…¸iœ
o¯÷ÖŒÃ¤‚<~†›æiâú şE;Û¸èpLQ#f·›·°.”Ó±ªÚnK´M7À–gõ¹Y–„UxÒ!\||!×–îòïfï_§Ú×4šª(.É{õò¸9™C::»µ±ò/ıÅ…wô0š>+ÿ¾t@}Ô8¹*—b5~4?·N¾Y~v®ã&¥íäÖÜ»™=—N«’Ø.g—æ#±Iëa¹y0.Ç…ç´EHŠNšÍ•ebsfæÈí`Šù—@2b^¯R¯áƒeÀÂ¸Ø×4’—|JşCVã3º§w*±Â Ê`K+î `±¢µ†E×ş4ÖİeÏYSjj&ëˆéù±ƒû<Bá~Õ3@ö9;7sÏßëå­0wB8\àªø–" h›«@ğ¶ÊÑÚO_ÏFÕ*`&•h'lÇuÍx^ìÑí‹fDíÒ”UU*Úù'ì.^ Ts¢§3K˜eI6Ç=­IÙŸ?`Ùt³çÈV‹Ëş5_©\÷ò‘»]¥äÕ[gàD…u„kœÁZõiê1üP°RöO(”%GO[ BÑXìº›>`·Ô‰$piŒC¯t2HÚí­ÎßOOÚÃ–®–"Õoÿ`oA(!U†0C½Ë•{&7E|«•|Q£Û-Ì…XvÉ›!z{Ë+Õg‘#Ë}¦ ¦«»Jç…v†ü§¥é‹Â‡.«NÃã°}ó¨:šô#äu…†—p¨Zn´~²{ÃjhS¦’Ê·]G¦rNq]NC·Š‡„Òû]ûÄÌ‰´Äœu%ºÃî˜Š] µÍ
Lûy x¨n÷^´BJçy´š±o‡Ä-º^å92î?ññmÒ’‘—¶æ8ºÌèò ¾DN®­‚[ÃŠ_—½³:E¡¯Üöóy|çjıx2i¤şiÙ¡‡Œâ«ÚV×İ9¶şÊÂÖ/Kp>çã 6¶05’ |²w ¯Â.ÍìW•ˆÂBÆ–[µÚ²˜9°Ğ*	Ş'Mİ—Ï®³|•Ğ¹|Ãõ›W^
âr:şÔõ¤>%qDdÈ%b ­+õ+Ú@µ˜>#aP:×÷¿]âPÚ•Yµucû*[$GÀ*î&–›ãŠ¬áº„k4q>™`ş˜w^uQ@xm@í5ÓÄ
rÅÙ,ÿ€&.x{ ³M­Ö&|éÍ0ãÔ'Øœğ'VÌ°şf‚ˆ½§Z·«ôæ¦ŠŒ)HXäÑ×²ÔØdM§÷²1!cÏEn	[$ø7rjPêà÷ Á"…W¬²b©GV&Öx¨JvEĞ¢…l”•$Æ‘p½XQ7î«„‡É HË0]ãÜ?ÄiŞx)n“©ƒ{{½ù¦@Á—é„‘\ºÃŸˆÿÑ²®ãXÍ¶ºãñ¬X‰´M«S"Öå%K\5	¹ZUU›¢­f[Á½e00Ÿú &r})ª3Œ½)ì¡ÂÃ\4çCŸÂ%†â!NÆ_ÿ«¼L0ÆÇûÍ¼³7ã¢ÃÉ`ş`®¡8©Q‰±›ìeØa—À€g•!‰¸”†Ü>¨À/ÕõEŒƒ[Ä
ÛYŒ ‚ë»ÙjØÄ±Âö\xúÁ%K~•ïƒ)”:¹ĞLI98@ã3²&×¹	ŞYvû£<\7­4RøÌ¼x¨•áoT™SDøòÎsç‰»­oŠ²Ê-™bpİQ¬ŠásÇúuâå­©GX€ìÓˆm‚Whá©’¹øD©©’©kMíS]É|W`TT’Z)E"‘?mƒ±M€‹ò”Då›ögâŠÂæ^†TN"—¨äbŠ°/d\ïÿ,™ü”Í° õÄpR-üW„X
œ¢Æ¶7/MGMñÎL27Vº’ÁôÇ?”£¹í‚™¥üÁæ±†ÎªÁ®@¯“"FèQ4wpÿˆ™ :§ĞÂM$}Â5­1îFn…¤i*{>6BÀ¢åº9 ·c¦.GmÒÏ˜ğÙuZWŞsÍ7Êó_96xè«›ÈÖâRŞöGwç¿éƒÄv>€Æ€y,0¡R‡q$i+¨;†ä@ìÕp-F"-iM!ü%56«æÇ‰í	9©$‚†ÖÙ †zHîhhšù‘$¨Ô•~[²&Õ½s4Ø\²bdbg”ºŸ pqŒg™¯¡‘«B¼ş¸Ì<ïvĞŒv¬|£Ùë}[kŒ~x÷•òSÀ5g<%…/~˜úwóó+™8—äıÆvŒÿÁo(<D¥’£‰bıäŸ	ªG&”Ñ ,.ÕKâ»}~Ç2ÔÖÕãÉĞøVŸV§ã’óéX&mğS™_àXbu¾†LVìŞx©Ø÷±Tr¼ahió…+µÑØß~Sr-Ş¼¦Â†9ë;3›:ı!]Ü´	[ÅÇ¸7Z}Óüz¢ù“ò5ÏQŠ7*U¥Öpw†1(fë"ì((E-¥ğN`O9Ê¦u.Ø„cy­®i}PtZ±´YØ8¤6tê,d%-éVàøW"gÍ½©ÂFØ÷}Işô2=Ş}ƒÅœoÂ1CƒqÿèÓ«Gµ
¥ì*^ö€'¸Ê%3N
&¬î ±?£Æu²O ÔáXÎóh¼­â,0rŠ3}ş4XvÒˆ ¹šÙ¾Wåšµô¹,5ñg#„:Ş­ö0Ë’.ÖÍå”aJYï¬½ê¹BäàH·qA·4™¡ùºsn¾\ M²¥Î€3Å¶iÉ"aÇô˜Õ}° ëÚ_ÌiiØT‚™B¹ZX$ä¹·b¢ùí×ĞNCAÁ·Ê×ùl”ÂÇıB¬ã³CŠ6…õ”›…ßC±V?‡J¡mşYù‹i8‘ömÜşDÂP®™SL«£±¶Æm$
s’-c)x[ämX¹®sòHø~uN-ù÷AAVÂ
ÓÍÙåT- ÇÄìÃº E,f²Bş<B>£º›Íôl›Fğ‡|Â 8\“XfÍ¯>Ùû
"8šÂ„
N¾=vö1òÿçCMíšOÅÇœ® 8Aâ=TÆ¥¦M[ßj¼şÒ$ù´¢±Ëéb–×PÜÙmrq:€‘Øl<%^€«D¶3È,“Ê­Ÿ ;ÂÒ9±Rj£À+GR.¢LÇO~f·Q³=Ét˜$ı x¬uŒa¡ÿW>&¬¤b,ÿÅgáƒî:%`oqS‹dÄÜab½Òà¿+s1z6„¥w£K: Û­†¹iÀ£ôÇÃRĞM°W)QÜ}5™b—nTµŸĞz†¸[Ú½ûîF:æıĞwğNE·ı¥+ŸÖéŒñ“‘ïS2Ã±.‰É³.w¸ú(ü7jr™2âÍÃSˆ€Sq‹“Tşışš~Ñ$ü•Ã¡š¦ÑH"ªÊvD™;4wøÏÁÊÑç|T"É”òzÓr€¡urvİªÇêä"eKÓî(`ÎøèÉq’Vuá0ÚAC@ñ›­ƒz™9”âêÃNñh‡ƒõ/óŞßÅãŞ‚²EÒ…Ÿ2â60G=d…’b#­†ª®Ë÷”^±¶WLu±M‡ÊE¢XÅñ‰\bX‚@Æ„”ÿ¸¢ÕëaÜˆ< °½¸üÔê-G\:†PÇ»¢ë¯ÚÒûÿh,àŠV XpÁlú-ÕÙ*öwA¬"ëq=OH:Œ«Ò oâ0BòZïõRwâ(~ùAN8>UDš¹Ao¬£˜4~ş>•ôûš\§#GíUÿØÍ'`#£ßˆïÓd'«†›Jõ¼à—cœêŸúõd,Az¨ºIA>ıî¨Zgö«ãŠ)ŞÀfk~è*˜—ÆÛ/«òï“`é°ñD&!—Ã)S´-ræoºO½B6ßœƒíM­À»ËDTáÕ´k˜E†9mÓrJ8³N3¿åË•wáVît„1=]Â:wüXİÀ>¥}·¾¢Ôvû+ĞTÃ9r	Ãßêw¥ğÆ;e{ïFe†s Áa(«. ÉºJ)véÓYÆB@º&iÎC]	àG
±¡jÇ%º¢ì:ıÎ§ÌìŞÂƒ"Ò0i‡wEjµS‹Ê™F™-œÊæ…:ÛZ‡ùÆ=y#˜BØŠZø’AN•0©øÊp& ¹B­Š|˜mü	iøÃ®-àÛátÎ“}R—]¦¼O WAY·1•ëğ‚RAå«Û*Bíï6=5Í«!
+íİ-7Û,ö±¹ŒÇùvUB6°¨¥‚ùÑÍ³|±Ö™’5ÑÛßAĞò¾°82§YFi_.RrõmîrCx5¼ FÈ¶Šû0-«.éw½rß½ƒš†‡bpP“sbd¦t-cÊGéP#ú–`˜ª ¤­’öôêAÍË¯c)>kã\íŸ÷²Wk6£QOóo6>¦Ú‘Ä@ŸwœİV[M…ä+ÈİgrŠÖÌ&74Mö`ßıávB­´ğW¶KÇ¥íÄğ¦&sÁgÚ5CóÔ·úÃš.¿á¦ú¢FÉûë -[~ü¬Oeœƒô ’)ßUZÔö%™Õˆ½Ğ…O¦k+é–ĞB˜ÔGb| ‚#ÎÒç€Œ<Ëá’cÆÔŞØqï3j‰>³°fÇ‚ß|Qì!OxèğBº1‡ªNN»î…j6àÉEmeÄ·’û0¡öxPù5>…¾Ê/‘/O\EOX%’€ğIÏ$qnËII~Y“ÆEU‡7(ş€˜ù ¸qåS 6ñãÚèR‚‚ªé8£-j]òË±rÉŞ£9Mª"iCßQ
}m¡øµg¯ØXœŞ`QWG9–dğBJˆò¦ÔšŸŸØXd¬Í§r²®’|*t5&kúOœûjª«lšöá•Åµ¾>&VëtEI¢VƒT‘Ü®i[‹Ë‘„ úûZg²ÆŠ–Â¨¶LÜQ5úßhmoL°Adê»&’ÔÔì’‘y‚ğXÎcc2¥>>xB¾2óÄ“­kÆœ¹dı‰¿Uvš\q8Ğ­ì.Š[¼³…µ¢‡š¸ÉÆg}P0fëˆÖ Ü|§L¥)ë–ñûÇå0.ÿü£…$4¯,Ì8mhk)qÓ¢‘åŸtNL«´DT>?™eV8‡ö; ÅÅ4qÔ1ÃÒFÇ~¬*°Ÿ”=A°múğÆ–jöì®
~ƒç[İU«nkâš‡ˆáBƒöÂB¯lì’–"wEßK†ïŠÔ®ş'î€< 9)öpıxEò1Ü£™NÚn“¤²ÿ×JRjTÉ’%5õ¥!}¯L<	0B!d ¿u?i#òªC½â˜e$6ú'uÀøÛV›À z3ĞíA ì¡Ÿ`BBú©(ú²ê|ÁÜ‡jJ„ñ`J[š\N,ìÍ›Ê…«úâKz–…}+‰2©†‘Í¬Õy€â5?»{ìQ”;À	ø\åkPMp]€€Vä|ßÛ]§kÑş« Äw×ÎÏVÇRIcôf-+WÔ—“ ®¦·>ÕYàG‘Wmcj†dğ+AË!Äzù{óün5TR v™f!Å”0!rªÈ÷¥h
&Ë7[ÑnÉ÷$ë¹ænÆµ‚¡»x
6{HJŸHHÌ×M1˜6<øxöˆÁ8ƒc¹ë‚eš)qó![<ãïıÚÄ£S´ÀÖ±÷~½½Ö}XãG  Q…NÌ¨¶(ÉSS2¤WJÂ €½NÌÅÎÔ…a´Ì«ß"VÀmŒgê>MI9«$r©óPeÙPQ{k.¯;bT´y`×àc.¹î`Jó€LT¾@´q£8Æ­úºË^³¬8™„@Oêx(A`dtEt&ª¯y"mœÉ·‰(‚óFYÅŒÎ×ãšÙ×ì#±¦ù²T½ûD&óqcRt0xúŸU¿Ğ6-3%BÌÛáŸçÍ ÏÚáæ(.nVæºášIş5ğkø¢‡gE|rÊpÍ<G¬Î(še†¥¯pªïÉ­-d•A—i–UŸ½³, OQ$	¡µ¤³3?,tˆ
-¦Ï%H­;ÑóPƒ™ã—ÂªÿğÇÍ2¾Î-ŸkÆ‰NGáoazHCæåüíˆØâJ¬û¨ê$]Å“üÄÉDèbô{¦³áaŠ‘jšBŞ¿ÁT@ÓÄ²£%£6æ-MNâ"bY&<{Í¸+=>§uö:Xè%K‹}HfÄ{ ´éïõ]åj˜Ïó®Ûîvì'¼@ãßu®ŞãòÁH@“üÉˆ5Ïš¯p·¥¢Kk÷‘`§¦ZşvÁ,=N‰' |Äû¦?”b¡x¨#Ë •8WTèÎ\äCì4Ñ{d@Èt
>´%ñ­­Û…SLñî¹å¢#ÜïvEŸ©×E;®¯»pkvÄbÜf¦Á0ËãË]NFM
E¸óğ/lÕâOĞÉQ•ƒUàLğö~AÂ
Öç&ğ­ôtøÒ±¿æÊ” ãú÷’ÈæÑã®Q"A­ùFŒr®”õÙ€Ç#:£.¬_í›ØÁ%•´:Qé1ñ{µ!¹öV	šé[íÓ/:ŒŒ6Ö0ª=s;üÍ®f^Æ™Q·‡îãàKzöÊˆa¢]ö^÷>*ŞR½m–2j"=$ï\lâ:?1…S£Bÿ€åœ¿
İ›€c]h'\'KVvèz|}÷pì‡ºkÔ+(óN\Ná–v/DÒÌœ™©Í¿@@$T…C
4dfĞwµjÕõÊ)`Jå* ìÅ´õ}y]D¹? C©¿†ö“¢Ró•á“[ouK×-òøÜ1¿#-kÁÀ¤ÿkÎD/óf4[—¬y}xöŒp»[sJ³Ua½œU‹‹[¯”× …©íË/_@6PÀ~ã‰}ì/]UBM£]^Ç;)#/1G×pëÀ„ŠƒÑL×Cm}Ã“:ùÊŸş	o¥?F§SßàÓ£ ¸3u®L7e>¨îäŞ|mÃyãç®™xEéEñT>æãadö¿Ç¬˜–‚xî#mÌ…4Ñª+5º‘¶lİdÍrÆ|Ùk‰Â@¢s‹ôv|„~Å!¤Ÿ²Wgv 	ŠI_×õî#Ê÷À„ƒÕˆ¶½Ÿ‹»ÿzS8ezŠ…:·‘Æ¯ÄÿpÇ;ªV"İ
æïû‰T"°“ïÒhf:oÂÁÇ[hêÖNú…hå/qŠøEsõà÷e¯ùÏª¯çŞ8;ê>¡ëê~må:KÇµízQ=³şÎ^<v ĞDlÙMÃ(Á®Roóš¹mjn•xI…væ
v<<xLOo[Ã¼9®YG ïzC#ÔñÊÔÙ]8­KÛß*ŠÂj,ÍØ]öMLóö1÷Ïˆ¶¦Ø„äD¬•^†˜L¤E×yƒ?“²/P kË÷5\ÚÜÏ¶€=½zHÁí}Gù" p.şkooGrT*ÖØ™¦1N•äéÍ™N³(A@‹ô‡½DqŞ†ÙfœÙÔr“¦z“TèFpÿ†(†4Ÿe…Â—|öScj·à©“·Ôğñ}—†ijFnS×èò¢\Ä¥ÃLŞÉ‡µÑ:ÿ
oW]©¼î6®-úo?‰@nÕN*x}…Û…*‘kßÄgÂ`,İÙ¼bËt(I•ÃÊ•"< {€nøj7Ts˜³ŒHm‡½E‰—Ğz/gÓ~&ƒ0¨zDìÿÎÈ×on¿‡G“º¨¸)Ÿ>Ë(MïCvœâ1;=ÔNIÇ˜HÓqÁÂXw1€;º˜,Ïğ·˜Ù§’­E§ˆ˜P5T’›e¤L"„½æÛºE›‚suõcµ©óh÷m!œ”$§·<şÖMp †ß%üàù‘–.÷ t [2tk`½$3c%–<Ø˜’Õ’¯B¡eüI¾Şâ-˜w1Tòı5cóê- 9-¹¡…ÎB¤r+.Òu«Õ¨ÒÛëU?ÉÎîXåÉ¬uá,{]ÍH¢™;äíj—·e¬#GÊæÂ\N¾iÒló®ìW¥?·Š[ÆªzvöxÁ¸`Änùr’×g£—„äİ]"²GQ@—ÀãğeÈçI‘ïÌ¨ÉÌå	D½RåiºØ Ò„>í’»òßìv@KÑw9à'Â8kˆ^M­q†–;®ë¥4É(Á¢9_èDVÂÏáª Î¿‹{’ü/º¸7ñ+îíjÌ~~û\W;GÒâñÃ‡·R«²§7b4„pAÈZ¹3ğh&Ó™Ô)*Ïã±YËSñ@ÎVqPìN„£+QåçŞa˜v¿wA\x´nĞŠ Ñç¥všY‹—PĞJfùÏ˜©1ÊX gje„¡Qà C‚œ›XRJa8ñÈVâ‘ÿêWŞÅÛm¹ †4ú×ªmÀyó\_h³ÈâÄ9ŒY[fXŞˆ¢óÓU¿è<BæykÊñ®ìËî{¯£‹rŞt·õÙÄY	µ®WNw„~È¨k²ÚEˆÎpe)c}Ÿ…òë?ò¥“ğ4RÙrèû…°G˜»çZ®"%H¢šš?€5üÀnÏÔ”Ö<ëmDrŸ<†vSPzºÂ½ëòÆ/AY´ûûk#±4<íFHµ·ºqB³}£ğ&@«äs³HbªÖÙv‹9sdË¢éÿ¾&—„Ğj&kD…è— P²‘´
É«†I7…^d|¢3MÊÅÊËæŒ“”–U˜iz…¯ºr°×õô£+ß{Rd¦Áûœ‰©ÉÇxúÿÌb¼Êîø”DDs× ^û¾.ş3  ú>ïZ±ùZÕ›BáãR¾'ãœçzóH}çéyjX)Öço´HD´‡fX(ö9P’Â9}·¢‘øckxÆqN_}@í.eNæ»¾>İJñ¬‹ó}‡½@‘…û6>ñıƒQĞı·F	î•Sæ	š<fUhü²g•AÊZz©øhzãoóƒ¤ám>Å™MÍùV8+äçİénjÚ7$şé5„Wò«Ò;ø÷ÉÔ„Nğ8tÁŸıô'<İæPHbùûìø]r\õy56‡nWĞ]¹Ã;›Ùu±öK_S” ƒ>ïS,(ª§sÕ€4D†Î?-Û"Öjê4ô%\æLYd«ØÔâ!±[‚şÜÔ'½oÍ¾Š!y2Œê7‹òÃìÀÍ–‡¨æiÛúûïø÷³}Ğm„lj¾¥R¥I- ˆ ÏÚj”şË9
DÖ±w¼²8	áÑE}"=s[„Ä‹ô›/ÄçğáÏ÷9|B†ôÊE6â‘]¶nUBÏ¸/-&0¥Ç?u‡›NÛCGªû…¢¦:ü15²—²
Ç¶ÄiI8Q<šğ<†á/\²__ŞË£—·[8>“(Å<·öÉFüËV™: ùÒ$)O‹è”ã†öÈ†ŠÄÄ’šÔ‘$¶:a¡I—éwÌ^›€hNÌøÀ|m}yÀÏ™V¢V¤ê¦>Şvñú´w=8½•VnÂgô†„PÜ/ˆ•(Ğò/ÚñeêågL[İÎÍæŒh›-NÅÆâ­Éş‘ÀG«Û’|-#x²©UÎ#ó£/¦¼R‰Aµ|÷„pÁ[Ş†Àèk.µ³£ı;„ê¤Ç¢–J%G£×dQğ„M©¹vFNK÷ú>ín
S¦£KéÖèÍá¼µz¼âÕj?¡Vãòõ
Ğ hëÚºI?°‡ĞB³œ¯u2ÌŞµuQns¼l!K,Q¬ô]ÖË:ˆ~Îwyÿm6bùçûP]—H€>Ww„	”²ºFy	3;ŒP·Ïèæ$Tº9’ÔHï^i^S¼\|àkétY9h®UsÃ"š®“ËÅlrN×¥•u‚†˜Ç­Ä?qÜ©¢Â^ïÖZE?/™ïõW÷7ğï™Í{%‡¸ŞøÕ@ª¼³írâ,Åz;Ü}ë¥bjè)?³§`‘PèU•°0äİºù<ïôMÌiÂoÿñ@ùéFŸÄßšë²a-©”ŒV!	6<0¿ì«´ÉŒòiàøgi‰fhÿ14O¿&˜vö¥­?Œx;ÔÓQlLµÉÇéCõLúóAßªá…€l‚Ÿò‚$°øÿ½#9Ë¡ÖÛğÚR]lVìoJ*Å¥«}-E}>Iffnñİ—$³}üıP€|Oå`â¨&æ’‰˜wÅEIbéØN˜ššÅ—xp¼«¡|ĞVÈÊ‰ö'Ğª†«Ë1ª'Ä‹ğE%¦´û1¨ş~2ª jëå	5şiŸoÇ†æéğ\úyèkN. ,î´6ìÚécÅáıÕVoDÄŠ!4‹7v*¤Ñİ#Ã `	S§ªñÊÆúäÛ®3°úÆ[ÑIW9!$šğª@à*ÌÕ7Íl:S¾î9ªÇ¸¬øúó …éöÈ[êš¯ºP£¤2<Ò@áó† Ô:Z­?DQ 6Âo]bˆÅ™0Úê<©×¾CrŠBl·-£+UK×|Ç³îõ^’l**6Ì±:¤Û>ø:”g¬&W†pÓvv~û¸é§uŒé'°²UVeC£÷Ô3ğ«ÑsŠsR±\Á …Çç)³ûP²2P>HQ
9…Ú<]h‘`Ÿ¦è>ˆ!€”Ãv¡½õCšvÌìèkv¢ViÌº4°¾kMYë%˜ÈêívfõşÍòÈÕEX¿¹àÈL!üOH´„ŸcÅ7ÌÜ7bÔfEÌ.Š)Z4&‚ı Ve»e©GÌŞ[Ù`Â“¹àm¨¾=ŒĞı”»ÃpÑ/S§V?»á¢ç1iSÜRÊ(;>«»ÎıCÄlòŸaÉˆ­“Í²)Á§Ó/p;ü?PÜ îøî^Ç8†ƒµ‚,˜c€Jí%Ï'†gNRèŞñJøÖØAUªD'²_: Û[CtÈâô+Çäj®ZŸi%’üMm*¼Ïüß Ÿ@õhr[jş”Qä\ğvL¥œuÊ Ü²0cïHŸïU¾D(È›nÈ‡¹fî^T¼n…IÂƒ¯ÚIySjÙqşµéjS^9“0ÚéÍ:‚”MMŒ9€‘åz( jÿ¶Å“([è,º(7dV×°+o-ŞCÒ_à@wViğN¼U>ÎÌê¬Â+°LC'è¾Êáh ¼ã'“›ãz¢LşRX•î#¬²R®†ó”š{ª[—txĞæØ1P|¯,h™£éh‘Ièğ¹‡Üg5÷G‰‹ËÜ…è‘Ï>¢a¢g¸˜ğ|Rÿèø¤ĞUòá.ıTşÿ	ûiÖ¡
y«™×Æ>oõ¥î%÷E.õ]7Ö‚Éúìˆ€FÌÿâO0ØR–$%ïW@«D¥Şnä±öqÌlØ	«æ=A?¿[ë9*‡§³—‚0·ÆDØ«>ÀcÛyæf
­ÎKuÒÕô!¼ş}¾>}*÷©ëß­÷L)‚ãt¯_]FüÜŞò<'Ôß×G£Ï¤ç¿òÜG‰BmµµiNƒ'“D’	›¥K$wéåXãí‡;	n»ªGœqUËéwü.ë6ñà`‡–L€H™ÕXA‘ˆgyP“ì]ï^KR·‹ŞûèTÔ…éóÆ¼eŸ4ŸÎÄšš2Â1Cu˜ÄcÑH&Å©üò3÷E¸6˜›ZØß†iÌÁ§½¼íá
5“VTsJDu¨0h9–IèSŠ«]ªËIsø4l7ıÃ ¥tÙÙé©+L-"R$	œıµjÌòkçƒàJWµ˜BêáÉeÏü¾MŸ;Ó‡c<ÄNXßÚ ©PÆğÓg«š¼kÖñoÍOùIbì¨ n kÕÉ±¿¨ÿå dê½hY¾IxÜœÑKõ!æjØİôù ãàVÎâXÀkˆğ‹í?W¦°Èh
Z˜rL÷Ú6Wio<#èU¨¢Ü5ï¢œ‰ÓncW+œP$ş™B]¬Ë&ìu9 +j½ĞA)0n}²T©£jÈcıºyJuÔP*=ØšHš2D²6h!9ô"‰§ŞÁ$îoõÏ_oN7›Js€k1À$Æñ-€·&oå{_?›ôÿÁ¡¬Z¨y¯%B§ÿÕı3…bÏ%Ì[ËÒ%®òb e¦ONO„éñJŞŞXYà~ºñ„'íÿ5|P}€”9tÜfÖ”rBqúg÷+÷øl®şË f9l–¥oÊ`Ú'YÃw.5Î.ú“Ãi:ŒïïıHøBp6~ÌÇ6ÎÇ'¼Ñ†bcQF~L—ë jÜö9g—TnÈÚ¨ lâ ô-}ÜOç=d$;j¢Ê†) ›-ÙÆà>t ¾8éå˜È3ñu{s¨ä¼[ 9Ì‹Nòø„»-ğÉC™¢±N=ÓxĞqÓ¤ıeù‹o8æœ¡Û8R÷İ…ŸÀ%£W‘q—n«>¹ƒœÖTõ:œ‹
óåˆêF‘`{¾?3ËRÃ| K6›_ã1Ìãİ'…Qq`Î÷QÊ™îàK™>Èø÷)d·|¶(0©EGhô	™—> şv	ö@ä-Ê…'` spk¾ÅğP4[ìügÕî
I)À0ë9«¾§“P’ºâñ<M9îÉÃ0yƒ?_·O«3Ö¶Bp”®Ğ±u&ÈÖg;ä¼œa}näš˜³˜C?ä",î ÆŠÊ¢‚Ç°]«“v—
ûó»Ş ÓÌÜ¡öïàWÉ`§¢çf*âÛ1ÕÄ>z	¸Hª©ÿt1¯3Ï§s¬ &?Ñ 4…zjœáø|[k2m„àú5uà@öv×éiÏFè@~0U¨ÿç†È!¨]òÿ’4 ²z÷»&¾àò…X‡ú"Í˜o'2Å8ÉzÛ³şêú3 ‘xŒ4ö×<gƒ Ïf@koÌ³|nf:½kÃŞRì˜É„şc°REna÷?='ıªdÖÁ%C,ÓÓ‹só0úÄñÌñeaçªÎi‹¹“Æ\¦	ûŠı0Ú"X³)Ê®+~NÌ¨¶V)…<`„·uÒÇc¸àÛ]"'Õ·÷äÖ1Yeí’X;|İkH÷§ßïÆbwÅéê>Hû‚îèàºg5g˜fÎxZV„~LÓ>:Ëhİ!øZ?pTÃïkVÙjA­¾aŞ9Ë(h^’ Ìİ=o;Ÿ6_¢í=á7•¾]Jô€Ì÷ãÄ!‚\‹6;(½Y}cfê1J[!Û¶á§aÒÄBÅ¤
².:KµÒds&"tmŞR*¤}öçıôÖ7°Ğê]ô-°Ÿ»ùÙÜ­y9º.Gò‰‘ü|e—éëdE´£åÙÛœæêÆ‹KeâW­ „c±æíÚâ|“ÒùkóÚıábÃî·Õ,˜Æì8<¹Ğ#)üG’ÌåÍî·q%WU›®«¡è|65î–8­ë0é~‹œiÛ­X#EV:0ôÅ›³…òæªX‰T‰¢òÀ³è„}å»Ø.biÀ‘ P
HD¾[s}¶érb:]^•ÿæ±,ÍØ!´,€nŞŒ£kkorw*¹¾Ë‡8Ãyk_Qô%ªÅ²AÓé&¾$'3R~ë9”È|è: oŸ@¡É¡¯×Íî©£¼MÕ ÎÑ‘5O. ÖÌJ°Ê²¦Ù$Õ/¿å7¬'±øu€Üà^?ë
J ¤O»j
"`Ç–WÌ§uö>İ•Û*ÿªqçU Â¢ûè²N}ÂodÅ/W©0yåvV{œ«ÒÎ›Z¶9ª†Oâşj›ijª÷}7Ö™ä`ë>A?VŠ0Säqj„6;­Õç²ä¼)1¾yn–^?utE×@ÎÈÊ•Õ&&PÊŞº»^»Êg}@\Òq×š4	4-us^‰[Q&˜	Ô{CVèI_ò,Ek­©Ò¼uL”—_œ¬»jVÁ‰Ê‚…çôÅX¸şl‚Æ„àOFZí›³iĞÇ¢ÊtÛØ›Ÿ|UÙùÕêQùì@uä»şxÙØcr¯W´>CD¤®T²®sB˜#¤fƒÇ%m­¹Éáêoi5;Ué¦HÆÂ½›OqÈ:n³Á%¤‹§±:!–Òs)‘nà
uÑS¶IÁ,^Ú`xCÈİµCy¿qÇ1¨7Ó‹ÖÈe›F=oØã{ÛŞ¿gG¯ó¬=i&ö³PxÃ+¬º…/’(c®WÕ‘·]ì$\æ{>€Ø/*ü¡éÃ®vÉ—°YIÑàÜÕ’‹BU³Xr‘Ú¹ê£KU¸äoaã@•7•÷d€’Åò×2clá¯8ô] k_°Í rîSÙDş¸xjÂè¤vEÜCw+ ±ÜeâB¶|¡2w"‚$è°·Àr[$
ÊD9nœèˆŞÌ¸ßÃ;1Ò°²oN	ÉÆ‡—M•‹€ÈÈ1²˜¥¨~Ét7ÅbŠ¡ÍßŠâ­0‹&\<®¬Éœ9Ãg´xî‚¶f „ û¥úb1„UÕy­Ù&¨hLvAIUÑ63x$Y{é\İ“ÍgÅ¿¥!ÃÒîµ^LŸª8Éâ¿¤éÖğªP:€jf‚-¸ÍÜhƒám+bŞØ³ìÛj“=ĞÛ	Aø`ÖvÌÖuªø#»ÖÈ?’X¬.Ô64à»]\­rÂbRú5™‘ıö¶iØ‘£¨‰c(N+¾‡¥¦¦4fÄ#µ&„•¶2ÎaòõÎDãV{ÌÇÕğöÇ„x”1ûöın¼jó†	)ÈÎ˜_%Üc1Æ6 üJÅXõA:ms|½1®;t Tp¾5Ş´dê½Ë‹çúå¬hQ¤í…Û¹ôÁÚHğsT…‹iX—Ü*à„ÏN[q6ØFßÚíöbbT×´˜|ÒıHÑ©®ºpòQBøH°
è"‰Ä·»^˜åÎ÷—ÅšxXu…”tû¼_s§‹gÑÑä2X@›àÜ¨×à¾ QCoa…õÊ Š´òË½ÍVœÁf†¨v»X—w—G !øÄÓjGä[èöÆWbèV¨‘Ù=ª¢N•wë ¨I,ÍFv¬¤Œİ÷>¸1ğ[†O°BF&„Ê«Ğ¨k£!‚«q×9İ´È6@LÁbí‡Ò6wK<™vÆŸ„0„«¹¨Í´–¤{ç'v{‘ò&o¨°àz¯^ÿÊ¡\^á®ÉÎsÛÃ¾k¼í­ƒÇc`äB'ğ$ñ(`J{S¯J€hHé¦,ØüdáÊbºÅP1€ö9œ¹XúânXÒ€i÷Ñ`¤K×X?Òziùş'Êl[$2/µwfÍ_¢!
ĞâÂˆ";x…Åôz’Ï%{,ûFUúg“w$ ’ê!]‹I’3*i|W?~úüË€/ŞySáJà²Ó‡ÀvEÆV=ƒ»Èñã?R/J±µ("'ëPş¤snt|µéŠ‡aÑW³jåô^}nÓO­ïØg>°Oì^Sè~»®×‚ú„VµôİmSMÅĞÕÀzÁ‚j™`3•åR4ïfÂÏZåw†¾ÿÈ*½¹I€ŠL_Jäì%µ•2×ã.¦bİ¸4¯c‰;yÏìÉ7·"ĞÃáM›à¬ÉñésÁÂx‚|¤ºi;\"oOtŸS\ºú÷·ÙËcÉäãM8Rö9:…-3#î<[,æ¼m³íÚ— Zòâ'D‰âÊªhÛvõ¸7xJæq•œH{˜ø+óÉañ{ ŞPâe2‹»í*J5ÔrïK§Iˆ,ñ¢3zè<6ìY¹æÓa)mà’q¡J^Ä€©¡-¸rº(z^æ1ÍÒpùäDO°÷ûÕ¬IQwäı0fŸÅªˆQşŒ2å`åÙ¸>’šM}ˆ½Ç?LíWl\eÌêà¥œ9zÌ[-Ëìôğ‰ÔJÉÊşè)ş’_Ø;úŸÀf7ÀĞ­·Hœîè÷<¸şı_wá‚úšA=ØÕŠ<‘×¥Ã~nñ@€²òï·àe êue=T^w"ó3ØkQŞóôÿÛüvŸiÑÔÓá›X=>ôÕç.)Şfeì˜Wcª$=ÙˆŞ˜_eZÂXU*‡« oMŞıQ°b|d OÿÅ1o<Æ½ CQF«ßJ. DäLz†s‘•†RâßrÃhca®~§)¬+DB ÔïÊ,%+•1S”ÙR<4HLú„ëëUB/ãbğYŞ‰ÒÀeYWJmó")Ï}š$Ro2¸h*åSàÓ%Jç¤ñvGLaB^ıÅ	ÅõÄ¨½ú	”ÚüÊr0OJN#ş£œ+àÕË¥ÅGM|ÛşDÍKÌeü†M$•Tq·¼CÏ&'ÃÛ+£™¤‡™×7G°Ág(;ÑÓdJÀIrø±ÜHÌcuÀ`¥¡×dæàÕZêšm#_–kÌbzÓz@´¯µI—Y½¬^¿š™ÇïFº‚™(*!ïyD³GwXJv£³D‰êQáß<Îíç§nÓ'!ñ¤3/ğòJS6°Ãğ44K¸<oŸEƒÉ¿º.İ'Â`ÉKb‚¨ö—&wW£¥`óÜŒË;º,c.43'Ñİ„—¨4ƒM4	Â³Z<½"­×í#¼¢„Fõí'„1(¬›O8ÓzÖI®õç×"py.d®/Zôl ×8&Èimió\¯NVİøkf‰ñÏ‚õ¼•ô…·'F4àµ’GÀéµÁt|®3¹òøPfwm[rMh8&èËÏIZV·‰¤îœõD9õr¡ÆF{enfˆ™>&”¦N?IUà¾£nÚr|ô|P}Ÿ½¢ÔîêOq)ê­è¾b·­ôm¶ÁV²•æz å›:ÿ Ç^m#¦şP”êÍjT›ê¿ÀHøÙjõU¢å› ¥‹ò¬àk¯âFŸS¼tÕaSÈà›áOˆÖÀ³×ÕbÆğ­²•“I±ŒGuÇ–ïC[«ÙÊ*¾&3¡¨8Èl.¼¸O,*,òéÕÊ²+å/c-_	¶÷ÅÊùÌœÖ­ø4yû‹^®Ë*vj›
ÖQx3J·äèWst?&KôPĞsÃE ª#ë¯Ğ“lñ¼Y´¾ÀÜ'
¼×¤j/^œÕØˆnÅùep7h×CE›oì«›eÀ«ËÜ½üĞŒ”"=ĞŸ·ˆ|ßíXk¸¢Ñ ğ´¦Œ4f õw\,;•ùÂÂ¢³—måÈY ™,ÜdàÍ“xıE
Y !dJ á›°H^ó`7îš¸ªWV–ÿ(_Z[™÷22WcnÉr¯fÊ;¼åìñH€ÂZœ“§Á’Ëm<á´uLîÿ®[Í HÌ.ËÿÛßü†ˆu%dñF8ÂñRµ¥áRãsF©¯ŸBéá'¸`…ˆ›/0Kğ{‰„D’j&o×æ1Â"¾ØÏhE•lEıÒØ¹·€*ë™F~<@Iöe“	„àJDIPÇxÓ¹ ½âòfİ6/w…Óeç°ã,	ºİ¾ş,”JŞÂl½A‡ÎÈÓ+Ù¦Ù?0Û€ïºÜ€–iÀ'Î"*o[>pÏ2Æ*Uº¢íåEcN¦´%ö‘´g?ãx™úÑ´b=àk¯gq$Yäªš€'ªRi,ÅÕ¥âN¥Û.ÿâD¢Häğ¥In{ÜtŒu?®ÃªÀ÷·14¶]<úº…[¹<©ho©üë…7÷ĞSGäv]ãÙ J2]´äŠ¯úëixJf¸Ó£†d~¯'âÁ¿İ•w•ÚÆ1mXlI‹'¥ßáÜ42åq" 0úâ¤™¶¨9Ê->ğÿùÙ3Igû	ñÍKJ]#èup;²•klƒp$/RÿĞ¯d`ğØñèsZPpı:û`&>?qı“$ò&ÔèÎóÙ[51q)¡ÌñÍqVèPóëaÑ~€zÏ‡—J,ÿ‡ş$˜Õs3Zåá²ÿ¹{ãVXV‰@C¨['Õ=šl„Iè,ßeÈx!Zp|†}æÙšØ½PJOê’|—| œP²+KÆ–5soÑåÇ¯…/ˆßÏ}UA€äÈ¨VŞa¬‹‹r……ØnÇix½	uNš…1@«ğˆFùŞÏÁÑTì1Æ,óœ¸¬fM…/œFĞ§C3›5‹yšuÊbkÊ°+é^1Íçï:ÔS¨8±bĞÀeh·2á”Èß/ÍÃyƒ ,á ëz=|@“Vy$~å+°NøJ—Q—ãËk8	û‹ÖÊ*àµx‹åRƒík‚ªü4K¥zñ$ è&†§Ò×T€fÁ¬
¾P.@âÓ•·	2]î¿P_KE¸Æ«
VKïƒôàä‡{ÂûVzµaV=šÌkÉstïÔz«xZØå­×-¹ÎR¦á-Oà7ÉCéÔfÑç£ñ°F=#ıÎ”s£LFIHåÜ2¾y6•l”“¢6âÛk)C%ÙcÍÁÜÑe;*^qJ×ı}O{²Î•¸o€¡í}ó°Ç¥“¬†§eÀ‹§XËŠS+ö!@+½Ğ$+æHÁ-ù'§ò‚¶áÈôpëe_R[ÓBÜ–ÈR]À“3¶ŸµºËŞ<\7gäLgÚ´Í5K#N2i„y öÙD4zY–zr4¨÷öĞú{æä´Ãn)–ˆ<°Ì4ŠŸ¶‘…G8êƒÌrÿ˜^·tò·AøÙ¦öš£j:½ÍÌ²Xô¤±Fæ“_Åğş ®–MéQŸ—ÁCBøtiªnØRP	×^TÆxäÛ"w9â\ÆûÑÏRrÅé›0nûmÖ°IÀ~¹ ¬I=á››Ú¢Vâ¾õ‚M£—Ô¶èÁ•»ƒT@5å m(Ú‰ğ’b M³ï¿îÏÒËjìéÈ¬Qçºİ½ÀzĞ#‚„c©áú{p1Vı ·M­$3^Y®¾	{ôhy1/èÁì#”ésIŠäÃvíÒWZ,¾ß¤©éà‰Ë”‘§Ë”èúFƒ~D9ZPQ¹2fèËL…G.A}‡Õà`·«¯*V}ˆØà˜8½S4Õq5*N,›¿İªÒ8nïŠá÷‹6H'¯Şi¢Œ<lµŠ•…À øoŸo„ÅŠV%$šà0ê>å‚É'ÊÍI•Cºª­M¹Cª5E¦;‘—é:8qÔ°&Š"è©C¥àş½£'AnİÄ¼Lù¬[^°1ü	äöD†©RBøŸŠÚŸ’â0ò…²«,tV.ùotÈ4ìáñ3^±Îˆ0~½Ÿ6rı{d&ÉŞĞàFtÁç±ÖÃRÍÕÌ@Sã¸…*ßq$ëÎWŒoşA˜´{¥Z s/êîûVœ‡òÌ <ŒQÍ\Sññ÷ošH¤ÔŠ’î#MÉ²	”€@;!ùN`¥h\±B™(È‡¸¦ÛÙ "ûå2–\øY fOªËÊÅ·Ä’Å«Y,Ë#ñ€!ÕÌ¯ÅnæĞê{¯O}òş™6ÏÊg‘Sk|3óşºÜ3®<ÚjB®2>~ÊXwnŞÊ):ÅàËhf¶tË¯7ËÃ9Ëp!¶,¿"êSúw‹O½~&O—*â~óÀÚ#ô?=6õÙ–ş	uÇÔµdWSäŸÊM‰Ï²¹2Bq¢¦ˆ$}Uˆ%äà‡¾ëšHVê ÜÛ|Øš,ÉßùğSk7„ZXñŞsLí@<¦)@4¾£E¿8§-ãO£SAÍ¤e”Ë?ğ$úOÌ$7™ô¹K$¥.ß3E÷¯ÉÏ÷úìw°ı]¯Àäœµ(„3¿;ëN/-s¿‚œ4"]`ì©õŸê„hÎDÁg]Ï°^î‚í%4ú®xÜÍöÍ’ä'È´ıK-ŒÄ…{Í
ï¶œYPü¿d°U'ÆbU¿KÉuIÎe28SÃ`òÍ‡U¶¡+7!—x˜dapë(úY‰©vÿªªªU›H+¹•J±yhSø£YìlÂÖfğ,§§¬ÛZ¾’¤Ô¢5ÄöJ‡ÿÌJBŒA%²"{Œ/¿Qee¥‡çqÌ’…÷Šlˆ].z‰ÆÆhã‚Ã{Ç‚q3Ğ=*¶0zRf`İ•k™
@‰pğ:ù§|“êüM¸ï4ÖçİÑèÄ¶t1:®³OÔÖğMüÑS¶çúİO,©aëä52šØ—ü?O†„1À4Åué:é¬÷‚Wşô-J÷Z"	ò®âŠaŠ(Ìòãk‡›‹‡áÆ"ˆWü†TW
dur‘´tÏâréğg&gë¿o‹j^èÔ+´Z!î&uŞ=Œ³p5?ZŞ—e”ñ ‘"yç
Ãõê$Õ¶ş%ÉŸ+ºKyå©+5TÜ¥›\9›ßÊ.éş+Â¦sã÷ïïb¢ıøIDØ6ò,`oÈà´¹?üA¸}¹²7ùçn!nåu'âØñ–C…ÀÇ$=fÚYénµ”Ó7Ú¿† ööØÑØ]e…«NU†!ı)Ô!’ ÂØ¾îäŠ?„·-9ŸÌõÓØc¢]Pïêï²ò0ƒÒ0…F¿Ïu/•üòÅS,ö+Òr¡µáUˆ—üñ8YZ™‘9…ó¡L¿ú¯^‘=£¹†‡;<ï>¾¯£ù£°×öŞ9@	_
'˜¡Eßy˜c—•=zÄ£şc¢‡|m”à‚>Q3ıÆ£j¸£ji-i3Tã&öUÇ8eò´CX<£]1d	¼Ğ@*ª½³±]{|83üĞ¹’HšãÑ@ŸñÚÌm½B¤aîT«Ë5qâ_r–(µQÓœ¯ƒ: İ™_%•ƒÿáıkOidáì‡AÎ©Şi†SÏµËï3šŸKÄÈêÿ°ò~¤¶zRç*ÕıLğ,DÅ¹pèµîô‡
üíwP£ŠQRIÛ.€¸¸^ÕäZúØ Ò$vEœD	#…ñÎ…g0éŞŸâM„Æ6(gg¤@^‚Ë‡ ¾nŒK|U‰vBÕÆNO›ñ«j “0T@â/‰HMQWüi¹”•¼Šå±£4vL‹u$’Ê–…b¯|%`›ù–§KlßP’ÃÑyFıü4”„k×­’êLˆ}Dë1÷\©A¦YÂK‹J<õ<†ü#uO7j›ÌÙ·kË›”É¥AücoÆ§?ı+—™:ÿŸ)
ñ§å§€× C} ãæm¥ëJÚxÇ‰Ä©P¦ÅK|‡àèâÈMğîiÎ…ªde`v=´¼DàQ—¿tÊLÚ"m»X"Np¤ÛÔtŸÌSšh¬Í¹y™ñ½3¿¬dkÈ ŠD0°ÁmÙçÈĞ“![„‘*?ı§ƒ¨[ÿ–üìu-UÎ¹îZ†CàD´‰.äwí'ã¦8o˜5‹“ˆ9’kvNÃXk%Kì6D—…]|ÜVóLYĞô«®`JÎP¶™VE	›±G½LÃÕ -—Ÿ%«Ç_Jp>mªãèC¬" ”‹CeB¥€Ê„é‡2¬õ`ú„gÑsä?§L4HKÑX~#zl#u™YÍğ?qpæk¶à›š½%ñƒíÒ÷hìûnÛJ4%ÍôˆÖëÉ§å^ØË¿Âç«J1’‹IĞ¢UövŒúl’Œ:H\X„bw9¾maÚ…çW'ïÂ_lÄêL¸Ù#'uj*â€Æ¾³Œ àNú”4z;àÑrü7¤åÔÁÌÖoÿğû¹
%¥õÒ.;@|ÛÄmãg®³²®ïàK*ÌĞ†¥‘.ª¿D|ì1:OHD2‚kåóÔ·…yûŒãÄ$2âè³äï-ÍiC¹ƒQ,"Ø¯áÈ,IÉM®¥îY²cšzkqY{Åyí€mÅôÀt®{tb	$$YŒúhÊ~P%Eø:¾]VáÓ–(Ø‹ïp$¹,æ¬\Kâ’zE½kVƒ¦Õybî“ÜZÒ¬‹%ƒ#eøÁ¡îûm^ ¹£,­3}òX=*+k^åØzMá‹A:*ĞÜh
ˆ’_$õe™„™â«õÇÅib¤§gñUj.*½´†A
y  eGé ,»0ÑÕ‘pdCã1şl$ŠéègÍğÉ!-¹,å5àt¢Æ|xBMWÉ#V¼Gè!ƒI•OlÃÒ—há%åişw±•]ÀÕ×eõá!©\;#´¹Ì’‹@êCŠú[oº3Ò»=Õiˆ1Ì$Ùl¬õ/Øx©Të"¢ÑFB~§·îR@ùz] 3OCsYù#_Œ§¬Íj;x·˜œ;jc:Úgx°†Œ7l³;(%]ÈA\3ƒMÄwˆ•~éÁ —R˜rşèÙ›>ÖéW|}ğÆ“¢âıBÈh˜X½'¸fHc>,x£4Q(³Švëq—`I¶©TrºFn)s3I<¢vH1¬GT‡Ú‰£Ln}İ8¾›¤út6Ùgšºòmoé¥Š"0õs>€|Kä²ûÔ§È\·[6·•§%
#	|bœcvéÛUyõy ÀjÁS«ÙÖß5¹ê’Ì&C­•wG0°Â#4ğŸS”~ÀbYÛ"kë-õaÇ_,ciU•¼xÂú÷_SÑ–­¢p
qûMÄÊk	å¡ä°`vÜ³7ÒdÀÁ4D“DŸ¹e¼åû’À¹‡
@˜ñı¶]{É…‹.ƒ;-‚”ò0Âğ{a'BACáı§)¢2P«·°?á9òTThx­¹€8;[ZøV˜ô"ƒFÒiı+|û uÒ–¸úÉ W¬±Ë©sz™ SkSzUU²Œ&àø„’Û½p£ûS>B4‰/<TÀ™Ü¾—[_De§wM;Ğƒ¿«¹Š èÄûöc eöV¹R:ç@KoŒHàW
.m»b´sS®‰Êiz×oFå®İ9¹Æ­;*V-‹=Rl	ş“Q2ˆBa[ÇêNéœë”°ºÄò÷Z¢›@6ô%;p“Šg*2¹šC|ÓJ¢½†c)àÍkbuÕ³+6¾¥ÛrGÈ*N“©EGÄ‚ÌĞïš/`2†cqälÚ)êÔ@”ha4Ã{V {*ej)rK#]Fœ3²ò~S80<<!T›ı.ü¤éUşqN‰F{‡ıcö’ˆj7°ßÄİL€©Œ^7€RîN©!ñÕš€Ê·çâsàK—(í_tñšÒ–ì‰ÿ\#ëòÎŸ4
¶pÊñ>»{Íô.Ú,Ç±İ"Ä8ÂÄ	‰ÍXşÛFnÌ…lØ7 ®Õy¶X¸À§µ÷áÓt»QPòœ—ùˆÚ-˜J }ëx5~áİ}¡İ³Ñù¯×îßO¥ª/i7´f¬IÇ—Ã»-á2CĞ±FÆMÆXiÔò+7#>8}P£İ .·«ê‡üd|›pâ»fjúŠ¾Ëëd
†ıÄÙÄ«C&8Ö$ÃSuÀÈ•ı¾.úñsáÁFD¡õšÀX„Ó€Õ|m}¤p„Ëm8ÌX5™5Íä ³ÿRIÆêÜÄæ5‹¡Øa¥ÅWçRíyâ_•–…;@,íœ&º(?ÓïdFIˆîè£XgœŠ­óÄÉqĞ…1õOñ+„¦jÀ\&‘õLš ˜§ÍĞ7^7ˆË¬dVYl£ø6.~ÿ™³IKï;ôh¡Kş¨ÕÇıÛaø³w<5ÁROİ†ƒàüÌ¿³ç¯¾yš,¾&Ğ(–o¢ö—ğ%‡K©}d]óß~pêHÉG½ä–õ„bve`ù¾Ç¶\‘¦f¹?
®?æ`XR,œ)ŸŞ•&ü?uLe‘0¦©UA×08H%]Š_ gC>§š^tSê^Ÿ2¯fGVºŒ6Õ1ƒ{QÉ=–Qp;N#ÂÄÀV„½ïÓHãF~«¿Yd†ÁÚÍÒ¤Ü?¸—Ş¬ZŠóË¦€õ< GĞçy·€pÊ+ŒÍ¢Ò8Û˜ØzŸÁş¯bÓ¿ Û[,Y*¨šó§NäÄ#ö’îÏW8€Ô~ên2lÂY "#®6­á“£.kó\–uy¢—¥ìLU°#…§²¤¾}«°Ï2ªO„£-;Ó%”Z7{Şm×%±)u[û¥£¿ä„_¤gk5Â%x»D#ZîŠÖÂæ› ş¤P [Ã„÷YTù2üß#snÔæI³ò éU<_Ş@5À—wÿ8ß@h®·e4¡Ë’[p5CxdwL¶ˆú ¨ö54TÒJ£V3ÅŒŞb™Ì   £€ªCCã Óº€Àá”Ÿ±Ägû    YZ