#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2080498477"
MD5="06698b276188ee8960f994c6bc1cb76f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26028"
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
	echo Date of packaging: Wed Jan 26 17:11:26 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿej] ¼}•À1Dd]‡Á›PætİFĞú˜ŒÑ1L,ÿß{Yµcşe8‘7DuwT‡iÅTi@°ú0´£M‘o—Íçí´aèàS‡øşo‹ò†ó$²1YÉÌ7ñ2Páøx×Í³DmP®&óÄAëf¸ÇB²…ÙŞ‘°â¦4µêÌ½>kœ³Íß»”¤kw½ûŒk%ó¹Îd¥Âlüoùªïåø,¨;9¡Åüt´Cx­¡r<rOÊÅü†"d«l–™=`5bÔÏÌ
€ˆiQçgõœìI8s1ğ-µB2†A©n›©–Ó8%İX ”;]I¡{T´|!ó$É´›=Ş,§œ]˜FI°ëŠ7QÆšø©_P|¿í¸MÅÅ>¶œfh‡g!Ç]R0“œz=Ëæ30‹9[½àÛ5%/ÊÙŒÿq—«p<²1Vÿß
œhüvÒ‹ Búk`U!G’µ|FC”œÔãšLÉıß·<gnÓƒ"O ¥0 òM§&ûê-Zä<›ù¡“«îg(¼<ò¸|á wCûF0ÓüÃ%ëKpòœÂÖ|«“Rà¿jÃ¶˜…ÅÃ¨Gù5	¤Üwö^¨>Ù_áİ5’æôã'oÖ‘Œ˜ø®jÑ#¾·¬¡]¾”ë§M ÀÅ@\˜_àªwòÕ!\(ĞK>yú°RV¬2>¨Rgï>E¸&}f¨‰¶¬Ò3¤ßG[Øp'¯ãN£.Â‘ØÄl÷I³qníåG™.û³v¿UÆs=näş½>³ª]¾â¥è÷~©µ­¼÷‘|î›Ws7Å.¼D1Õ*²È„D/Æ“
kÆ2´˜JqDö?ÏºÈpÎÁ9ÔÁîjMû“N}(zÈ"f\æè”>9V@´ªAnÙµÛ"ÃÏá‘£•ášE;ºZ Ö1Ï$ Ô#+$±c,0
~õ^U>|wÊ€ÎFNJÿºôÿòâî,ÀXHùä,Aù˜×:1•B11Û^İKQ'ÔÎ/x1ãº‚÷Èöz-¶W’¦0Û18Ñ
_e×IşS[¼c[r¦½ÃòDÀcõİAü^Ã„^€uÔÃÓ÷^€Üµ’e@A–ğÔøBÊ¥6GŒÀñ—³¡Ü]E‡Må¬/i¸-¾è<¡ÓJpÙ¿8Cœ“ÿQJè?+ağæH]†ªú	Lã"îÃ7c7»†[KÛFmdòG‡2œª?˜ÒÆñn«—`ä·[+í¼G+¼-‰âJ!O’gÆ^²<ù K«å	ãÚĞ2”lÇYBÔ4ñ¶üöÕ~ÒŒ¦!î8.Ì|ÌÒ—åBfVn´ˆû¹óPuÖL[9¡Yş£'®¦êO%PºP,Îˆ2–‘?ÉhİøÕGòLºO‰ÙPÆ`N`êéMmĞş)lş<·kL:F®Îû&÷“ÙîªkE¤SV!bòÕapWf£¤%-n¤ªèçiˆ!Õ; 6¡kĞ,`X¿òÂhÁaöìšnR1ø’pKŸıeê
UğµÑöÅæP¡:¯ègú”ZDÉN¨jaŸãŒQÇE¢u|âªwTÙ	ôÔu,ú= TpôôşB_d3°´xsÄ†"ÚDT^w¦’ım9ĞTümä#à|Hƒ™DĞŠG°‚ >ƒhÒ;pÉ·§$˜h[Á£RŠÿàµ}Lğ—h!1^C¿rm»!ŸÃ’ãØ§¡Œ¨ìQ5TØº˜Sªcw°n¶‡)…
vÍ=‚.æ,Ì > +¨Gdñ.Dú^2İ´Ã7®ëÆÌ‰ï_P³U`fİÚpÙÙñÑUœa
®Œ©âÇ™Zş-ÏÓŒŸšò½ªÊ´OGE9Æµ»rõS’½I½µin)R'ş¬º.|Daºe9…p1 z„¯,Gókšo“.ÆìŸ¼æì·d´ÁdS¦:€Ò–®µçÖ ¿ÜwœQªgU!£ÚkïFOàŞ‹@ù9]¾ë÷“óµş(-p_LÑÂ‹(F1âBÏíÙÑŠ¬´Ú6à"RC«½$sÂ^y-kÏ)PÀ8ïó»%ZÃÕ—àşkeÅ,
s'é]î|C¨]ŞAï©²N\¾–Ã†NŞ«_&‡Â”üaºTãÏ,Fµd¢ùOl8´,YˆJx4HF“·šÛÊ>€†x•õÓO³	g“ÉÅÑÖ‹Ápa€¯-³’ô(³2½ª—
ÄMíñ¼˜š:Æ#´;b‡ùÿ¢üSÇšï÷0-ßû;2£Äû~½¸LGŸn‡õ>|øçƒırÎ¡µlÉ,¨¨¥ŠFö¶2Ó=BÁ¹pø­;Gv2uJøö´¿…d°â«şÇZRÔ¶gQaùQUG9b/MT}Æ|KQ‡¹*í¡N†"lç,§ëµS¼èv´NM&ßr^	h_ì76Á7{Ç;²w$fâ5ù’ÅP¨Î›M<ı|‡øƒ¨ZÁ¡Kl&Õ¯Â;)<|îÏP^Ød}Nèœ¡êÂ€HKi² }Ü-y}#ëÿÒ£IÜ¸²å+y=Õƒ„gSÊÆØz±ÔÁ›ÜN}
ˆü²3wŠëú_ÑÄÕÆS£ó3ó}MT±Nûîåß£>Ï²N‚j~4!<R‘kĞ%¦šKÒÇâ3Ö9"è7HQ¬ğeõWÄ'ßÛr˜L=h[„{Ô¬Éjş%
`¬*<õ’Õ>ˆá¦1gK÷	–U1‡vö¯B<¼¤ØKÈÆ]J‡-®{UPi2ÑØZû“ö´ß™T[oâÌSÛ_\¡~I…¼)¾Øî‡lh/…:ØáµÃ£+¥úŒ1W¾P¶†è²èïnd¦›qÁqú”r‡CprÚ}2y’º‚¨we­>SŠ—&B”ˆ(˜úÇON7aÈ…å@ù¼Y!—p—C‘°Gb~0ùC¿§$o#šQ^!sfiÂŸQ•°Î'rHfá3éŠ£7‘ïÑ¥34NŠ—¿âZüc“ò¤·á‡]èˆq-„ßÏN5DÖt'œ
ÏÑ|V#Â’4ö1YôbFó8´jˆßÈ–	N£ECÈü,íÉTÆÎ2(^ç¬u–íR4ğÏFA¦İüí èHKÖNÿ¥’pMvşÒ•«>1!¸°TäœªÿC§máóGp¡¶£ÓÏb®8ƒÀÀTÖ}<æ(óch:’Ñ’3C*•Ã”}Ã}ÀA‘º÷¡†‘Ùs#ïdiâ¥—¹y@ş ,©¶áåéÉ5”Å(ëïß´ ÆML®"ğpï^tí#c`ÏSk`â6ØN'%™ÊÑ@R#P\×Œ„Çå?(¢øÜK–HQù‡Ùß+{âIÍş!Íè“gäı6r(/À[›¶G•Ğã³—›Gz*ğèNhÎ´ªh@
¬{ü²Ì=€Ëò/bQ
AâºÚè‡ŸÁ3í‡´×RŒ5Ë{D–,Ã#a›ıbD¦Ÿ(èÌtïH…­¯(ïğêÑ#	Å]“æ¥$¤üïiÚÛ>-ÍÈçoñœGfş}Ülóº,İZ+I	Ñ—¦a•Òá˜ÂtÃÄtŸÆÑØ½­?'+_é’Âüñ›ÄƒFj²Î:(‚/º”Q«¤ù¼zÿ¸níğUš¨:á>_¯	oÛ¸ğ3İèvİ)#GGòç”¾íŞ¸‹1iÔzW^¬˜;>¾·©Wsb¬¸ÛıÁ/]G6«ÚpjŞ³·#>J¹ØÜ…¥} ®ç‹Ç„6êjò 3PàcOt\q¶µóÄYÍìı–¡ç#_œ2…ĞòÆBõ€zd„™ò™k¦:ØÎò|)|eb‰l½ÀÃ¦»¨çíG
Nå’ùË¤&J±KĞ’ÔóîjK8·›“ª[S©^HÌ2…gKÆÒãş÷X‘Æ(&<DGäÂF¨·é¤”„Ì¨·öTKMs9¦„Ÿ"i¬Ç|Rƒš§«
H¦bœ)Yç#+G4±ÏD}ÎPp5HLs:ÎzÉ™äR¬ë2õZ¢M1®Ww#}ˆÍrŠr%¹”ïÑîºSaïA ±Í!2C's8ûî?k½Ç›èa3¨™	!Fd~"{@GC^ÛüÙóQ†A€´0èax™Ü¨ØšNty +¥?ÊC²Ğ3¦‰%¸ªZ/ĞîÚ^ŸÍË5Ö8¤jVn¯O¾)ƒ?I)$ÜnjÖµ—Lâ‘„8¸uÌcå£2W°¹‹›tyân¦ÕDiòÆ¶\6Ï¨ó×ıÄõ4å	:¡‚@œEw“ƒÁqTO›‹qr6HY¦Å²õ¸•×wZ97…QEµ·ê}Ğî˜’‘hiI`eî¯ò'»äÖ,™%$ÈÎø¶ é„ep¢üîÄ©Ä	R6`îµMqr?Q<kæÉQM0Úßsı+¬~K
h?æÕ†áõh6¢—k7R.KŸµ²Nt”Ù}V)õõà=Ãäeƒ“ğŠ¿º&k…şmÕ²şhCËI*€òÚHd½¯_¬›jp²‚­Á;Ó;Äœ5…;0â ³m
!ûo@îô^Ş‹w†Ò…«³†ÇrBĞ'B\Ëß¼ ì14
¡2¯$A¤ü~[$}¼C¯tø—ıîŠOì‡‚§óñ™Ã¯ŸrCãZ n¿Ø‹àQ5˜1üì¡¶x‘²$‘qSÙ› õË-õ„%·-‰À ¶ø3ÜêÖÉÛ6éˆ
üë^€Ë¥QšIöĞõSgVºÔ'NŠx¶õD0ÿâ¤I#Ë4pwj[só\ä¡Lx³¢Y]<Ucc@ã°ÄÑ¾ë«i8Ù#À~»jHşu¾I·Dzz\m+F£Ul¬B^x«U§òH³l—|óäÚX?~?1RÈ^÷°x@^›†ŸJëãï½Ê²g^Éÿ¿á§qâd‘BTsÚIÍGñ3 AÆ{0ñ4£÷@°ğ;Â7ÌŞ¤?IÒ°‰¡“çá‚OÍ Yc…èù,ìŞ”zu|„ÜÃ4|a3†0‚ø$ı·t»àEZGãbıbmBA«ğ)'~·øñ_ñGÉqEÿ2½3¢‰Ó
<ß@ ™r¢:èÜYuòï
{ìn­=øhâü‹i¯G}—´±ƒsÎ{Å2œH‚Öq
’§Åu­ˆë £ÍN´š™ dP˜ßJ™Tf^ø5Pœø!€`erâcåÁ¸Ë{{›:éºÂ±_0 ,˜éì¬˜zñe:jì¿Àr²Ö>uL? \/C/ NêÒò5€¡JMÍC|€é³ÄUB‹@Ç‹j*[-‘x¢£0ƒ µheÎº®¸H¬UER@%ÇÙ¼¥y½´Ök>%I^Íšâá+ Êîtf^=ˆA–˜/ã®#È˜¦ÜGgka¡ÒDI·Ò”bÀzE˜qŸúo™ÕòÆb…Zµ¤ğ^HşŠH†À¼˜]?ïâ`œù8œA,ê„$îÔş!?Å—k¿ë“c†Ö¹d¶lu¡¨×©Ë~
âGà,dıEY éÂª¢\Å;öä°lÀÒïŞu+HocÏá‰¬!Z÷BàÃá1Ğ#Şvÿ³ÎzÔê^F¨¢'ˆî˜uF/¥İç‚ÊW‡à×Y)‘!çÒGá}5üóíƒu]êyä3ß½9 >ı¦J»>İBçó»n¶B›Úqmy¿ÄHên™RL z‡b3|³(7QP–z@wØú!6II9ôßŒ;„q9]½ ·Û+‘“àZèº•0‡Ò’bF^Z_<<åÄ¢ÛÑ
3?¹›Õ©ùWÈ¸Åés”Ö7˜¤çƒ±Pi±ÿ	e‘»Åg‹0rjÓ’ñ[¹& ¯dÀsÔ	Ä¥ÅÃ0^6-¥qe´M¥ø	†b‡È$>‡ÏìÀå„¶mT‡	Å‡‡SŒU»J1=Ì|R„"Úu·j‚0ãc|¢S=Q’ŞêĞğ&äÏ¹ ÁzÑÊÅ&8«‹páïˆ0]ò“CjÖ ıÎ!ÚÿA6c{2êN™²	¥©¨—ƒ™-bvşp-ûö×ÎÕêàŞ@E™ûAû¤ó–æ¥¹Nä•Â‡7ùúåw½9Í?mé²aª=¨ËB½›½ø¤2«qY›N‚3Ö…‹óü,‚Q?8%Ôå^Óuü­ »¿ããõéa=ãk0Ğ!í¿ÊA¦“ÖF5EÃj”?æ	1«©BN‡‘µ˜¥÷m‰Ï=½¢H¹º öL%£Ï7¦QŒÙºÛ1¢|»®ŒQÃºyãDnN'ĞÓ»ÍZM®êö#o¡<şÄCq;]Ìì¾Ãå>İ$hP§ÛØôE‰r]åí:gbOè1'üÀkCúôÄY_)Ú„êxŸ~ê¬_ ‡³àô¨å¬Šfƒ=lÏtŠ­‚áØÜ@á¦Õ³6$Woˆ¹2úPK'’¯^aİŞä<Ş[fqúÒ <ÿBêÈ±d­å8¥+ùl3cFZK @ÓI£+Pø{»gÌ¦á<”u$!j—
±•Ìi„Çg±J-´¸§:¬•³Y ®Ô:İ9Ée‰£t­O^öûúß_ó‰O¬]u¤Nr®ãmóşSÚlÙ~*hå¹¼¢Ù-úÈ)İKxCHØÆœÚ\XX!¨”N‰}®î+a¼fG´Æ)'{Ü©(ÀU3‚²{+šÂ‘¦Éó¥1~¬hÔÜæÒ’áˆs>¢#j´aw—7î©¶î{Tê0	`Ö…ÔXŠÚ3n´ğkcn/$—jYUNŠ´Å3ÉÕŠ{i8 °‰ğ×õÅN…ŒÃ²4èxñpm.šæ ÂµV>ÙÈÌ÷ÕZÚ@&†|W²¸ÆÎÊûmÃY„’’ó²Ä H•Ÿ„Z…™ÚKöçó:ù¼x	²Ä§œ¼¹´œMt(Ğk©œº‡±¬ÌÔIÌ‹š„Ş±OØÂËoŠ……Üš:ù9_ûlXæ@P=RK±T«cT‘I—º«F
€uvè³JÊ7å™ò0mBU‰¸áØRü<Ş*pœšy·)¥˜Í‘ä_üÒ2eÉ?¶ò˜(í‡«Šføp±Ôsv7L‡†ëq3ËæÇl,iîİø>Ã_¿kğ§ÁÑ¦^.¥JOş9±—àø-Ë
(·Ü¢×,z…ÁŞ­ö8¥''ŒO?ã­«œ#®/Óæ¸ÛzJX£©Ú	`Ú\¿=ÙCL€š(™­ÿÃ{n¸>!Ú½ã£x„|µ:m©ß¬h<sÔi«;à¿Îï™ïn¤Hˆß<Ùk³/€bqJ¿¸ç[ì.‡ä^é?oÃÅº@”@ByçÕKOÑg¶‡¬ñR©öÊÉmŒ'H"2ù¡Ö±2ò•SÚøªCû1Ÿ$’v‘A[Ræfzp”(KÖñÂã;dĞó
V¸ÅM,JCŸÔ0qŒ¯eà¥n9NÎç¾¶×‰ÙØ³$ş		ñEcíFŒiÒŠÒ§G;ë¹[ÍÜ†Ò:÷Ö™}IkuÿĞÑ°¿M#ˆ3ÕV’3™9~ëLöjr,¥o×—"mj–BŸğ@@¦Ùq2
°LKv)“é«¯wÀöGS=ª!€ß¤h$¦˜cyê®>Xô¬„¬Ô¾Q¹Y[Iw|WùHhşõNp;¾'—7J7w3Í0	SL*ÃNNv¢^İêúBM2K¨B(„Çiwjw52†k’¬^*¨^®Å¸vô§¯ixgT¶“d­l şÿ$÷³SN/±ñáÃ`”!ĞıÊ^yƒTÓÎzÊq	‘‚ºç,ù÷`6XœõÊi]ÏlŸg—Ş>Ø©­$¢¬1TŸöxß”·…‰íú¨±®Ş] ½Dljf¢Ë0ÍQĞ‹ÿ
¼ånD:c°ˆĞA3Ã'+‚6àAÈ„ı¶¦Ù]˜Á9Yú_ª«í4}˜K«Ã«¹©²Õ"NúÑ=ƒk+j° GwmÈil 2OQaÒyÂÊ­"]ÿ£v‰^É7EC­æËÅ]1Çi¸N…uXwjp¬ÌìÕß ‡Z¼$8M‚œ±³+&Cå[ j ñùZ2·§©9Ü¢!Âì×< %òlä¸ãz¶l-ÅÕoèJÖ£©ã</ï )¤„;2ÿÂjËø¹Ìe˜}›ôæxvkrDŠ}i¬3a!.ïˆç²0R3Ò§.óe>ÓOv«V>¢˜²,Ä×ôû}®<Å-wVÉKšÓjç3¾VkÂäçŒŠtÁ7[¿XNÎ…üÂîgÎLU/Y9_JŸ¢Ì®´	#5‘é“çDEC¸¼j×äı]ærfq*‹…kmÔTı*;r!avÃPÈ}`Åß0–·R"¦±B"7·A¾§á)ô8Øê[ytbİ­à­¦˜Mô©›zº”*;ğü/…”û$î sLü™6 e"ìü¾ª;+°EØmôˆçÅf`ğWˆ'°eÓâ<òê„¨¢,‡ÆÛÖFk’A†—öÜ)ë%ãÖõû»Œìøu$R×ºrş”T/ş4g¡Éu¾Øûî·]>í½ÚÓu„ÉèĞG¬ˆc¥Lsêóè²u,’v-t†0íP®Péæ“B]ŸÇÇ1Jã´ş1­ˆŞ/à
cI‰uÏ‘èH:úÌÂ…kk%“^ò8ÆÄhvÀêãìycOÊiôìu_H âÃM¤ü
‰Î­¢‰œrÅ‰ÔkÅ¤/:R ä®T æôğƒ¾ÄC~²ÀØ®’tŒ°šZ'‹¢ñÑTSeOœ£h.c£ùE¿˜Bãeµ€Ñö·_\cw)üŠEÁJ@¦âåÊ5k/2à3A“t+	œÃ0tœ¹Šµ!9s2p£1‘–úÌFD^}l¸³îìœŸ)W3ü‡WPòI{©EUä]!`Æ±oÓ[³1Öæ{^·Å|F×Á{F&E{YçGT3,1¼Ât1i™«‘wußÉ—˜% Ğ^dWª±µ2S›êÚ81	ãìí)ÆÿsÚúQCŞ>‡._ìeC‚p–7\-Åì^íAŞˆSÔ­÷ÍJ«ğQ³v,Êé`š)û!ÇvñëF·í÷§¢fg'-˜£[_"åÁæÑš,[¦N’Õ@5	w³{¡â vâ¹^,¢e—
,_«{×Ã½È6º!¼YÂrKI).Éh02¹„ÌJt¥6V,V{@È¦÷Â/ĞïR‘C||m;JÒã1a3Èq­ë¸9†z?ª –eS%Î#ed'ÖB^…ã™Å³`°ğälP2R·?ÍæÊ“ï6¨×ºGk˜ÿ9/¶K5–_Æ+KxiNWrÎ?ä¸ÚëíSÍö:í2ÑÊÙíuB-M8yoy`y?àFÑpÆ´.Ú°²õm*Ãñ*°ĞP‡=Qê¢@ÿ¥FÒÒ(!ˆ¾pñ¨6˜¶U%b˜ù5ø·º/F*ç!Š®¬åC¥@~gâÁ#ú•!ZâjÓµÉÏa`Vµæ”œ¡­_ ’Òª^Œˆó8mL.´†Ë'_nv8ÌdÌGÄAûˆe˜ııø²
«.F±ªZÜyçD’"l•q£R§‘
¸›CtÉx‰Îe„®ÙÖÎ	`+×z:YiõM¤¸İP:fNSVŸÚ}‰ÛD¦í‰Ê\[àLîøGv“ç˜‹ÙüÃü¹™¯)E®0îˆ^Åÿ¬·ôªB»pìãktEHµÈ+rw!÷qÖ ÿ,Ì³ƒªÄ©ü©äÅ–/Á´Ü„9¶VzKŒ›É4Æ¨(ø¾x
Rzïõ¿`÷`«¸‘L¾Äœˆ¤ôœØ½İüX‡BªGŒ±&GÊ—Êíòñ¦oA‡¾Éº#“ğW“o=‘vœ§XjÖSwŠçŒYê ‚Aœ¶FC7S_â&0u·9v)ê=ÖH‡ÓáøJbış¯§1[Y€«vÎöbzK.i¿ªÂz½İ£ ~;NĞ^z8'÷ZX‰æ8øiGİ‚‚ªö¸šÄ‡<Nù¤£ûÔ0X—FuPG¼ëÆÎ#C`GTÉÔ°ÖG•m2ÄW´Âí9CêQÈ=æx¤Yìé’KB«WÓ²ı&aÒİ]²¡-À=*-âÆñÇg¦F5uZûÂt†˜#NÀ
ZCsĞ·İ˜”NxfÓì A*Í#xt5‡hF0xÊyl,Â/¥Ú<0/*’æ¸V}tÄ'VÄVI{Lã£˜wªJ:2´±ëÇThxøç×cÑŸ0éß
Jø®ê²áU]÷ÿÕ^dµ_Ä7¸çp ¸¥BáÉ"k|éÈç¾ÙMÛ½×DW`ÒjîP±r_EÃ,riE»—+Á9Ó ¸
;›¶7²ØXa½y²2lõÉäVWU³‰,FÊa¥%wÇÃ¼>”r1Ô„HÓÆ†Í}%¬&ø¸KòÈ½´ ­»Íéü†úxíƒĞæÑŒ"¡€È­€2W/ß¾6¹€ò•PİÜÊ‘“WmæÒQ×çe²	LsYJ/AõåY7Š$ ×±üÔOòïùÚ.Twø²ò6úc¿c'Ş*DÌ9FŸcmİÍ+'«E@´ o®ßı“½k÷	liÍ
"RìÏ	Ä€„óÜŒ Ôp”äkh¤ºr&„Cpâ _lw,¨õš¼F®¿ x¬ïMJ²[œå„];oÙ]ä<ƒV‹U§¯ç:Cgq®‘»ÄãŠ[qnHŠ_n>°õnœ[¤RöÄ‘ßv¡¦Gõmé?ÀSƒĞë7+~ë<§RBM®¸çÁNÚjõÀCºæ3ÊºbĞ©zs©»Â%	0¾¿„ŠÀŸÔ£¶ãİÔ¾çHPÌ”ö6qm´eÌ…ÑÛä Lû)y<vÈı3§+©~jº¨R4úª§V¤r„F¸µ}&´IY7ó­âzÿ?‡ŒšÑeIlV\h$–+Û"&9“O¢›ioÎşFØ‘sóZ$ß~{yu§àÈ[ğ8t+×-Lê6¿l†;v“š‘®¼Œ‹[á6w2‹£ÊU5
Şİrê)I^äb	[°'Œˆ@¨@fŒa©ÌKµ÷»ó8æŠ6tÚN2¹«ú„™Tgcxúz>a´kÁ§HKš ¨›P?aÌ‚‡bºhÕ<íusêú†ÕîÎ&Tîíª€TPv÷cX.NbuL]ùN3ÛeÓÿ¿b„jYBÿ"u !ø„„!SGSÖú#jÔYĞË,i›ûŸLÄûÚV€Nm–ÆUõ¹lSH{è/t,Óäñv£ßË‚hù©ZŸy:ä©¸ƒğ¨gĞNãŸò~–Š»ÿa;İrd´IüS8;Ò"Å¥‰±îğ&;B5yNòĞ`¬S¢@aÿâw?'Ëd1Fòs´½Şš‘PÖÍ–¿ÙrıíoÈO·ÚÁ¨€{ö$!—„ıQ·&;$A ;pÍ‡º®8GÇÅ°-öúì—Æ!ÅÇæÉ‡š©¤°‡!ÿŒËÃ?ÄÌæ# ›÷ÈÛF•§"6<›÷ŸàU2íM~L?œ˜µ®¡pŞËñx o$ì(/Â»·%
›SL{Øcˆ•1·C\ÖD¨²Kâów0ÃÊ¶xWÃUŒo™Î²‰=²Èb[™úÆ­şí	
…µ²dĞÙıôôƒ«ô_¸À‰èÓh°Sn¢(XG“!®iÇş›´Ån4å©uk¹hŸ9î¨}Â×eÍ/8z6 &)ßÊ»¥Î¡øôëLkE+üãÂ‚r³®aÓ¿PZ^º;h¹üôÜ/¦Ê€¿šë=~ÃC„JşOïGD†o1U1ÔK.xŒÎC¯Ê—¶H°’Õ¿®¸½ïŞ/H›5_~~é)Ú!åÒÍû 6dsÆ8QˆB.š™xC:¬pà4 #êåóMÚt¸ŠC@¢’®F$);>Xº0ÑÖÙ÷8«ùÚCË=r*håôFWÖ™R¦ü¼I:r¤,¤ıyÃ<7ëÆZ‰µEĞ¯*İsÄG Oc(IÑC2»9‰¯bÙx NL@4¾kÈô6¯#½À 	ù¸ ¦Ñ=îd@eq^Ñ’à@y—l €0î®™$Èä ‚ìë³ÿàCø“•­½µSYaÌÿÁísQ“b+LÉãféŒ¹­Un}jS ’9àá­åtöv‰:*(wë]S^ªFUİf
7ÀO‡šB…(‹Bñõ‚ğî§Uk˜^jOækoteeíj—,Añ¡W±ÁV†°‹íL~b†]¯/‘“–û‚è´tö>c“µø-·>@×¯İ+Ê–àwJ…~ ©û' î¶T¸R„cOÀš?–/Êş3º@¾SÌ¾²3œ4¸üê¬?©,ı;¶T£¥¾op§vqzrkşF&S4µlü¢ãPV “Ëß’DCå#‚>áü$4öş‹Aînr1Ğyütòe°5häÜ¦î'›#¯¶QxñIŒd\!ûns¹a”<C«aÕ­£2Õ¦Ã+Òæ¦…×ÖQbøy¥ô¶kë5Ù¶áO>U³@¢¿Dâëqœ‰x#8øÑÊÚ’g×¥p¢Š^zÄ‘Ãşv”‡ÔnÅí‹&UQ¬Ç˜ã&÷ˆ·êàÁºtÙÛçC'îsğ”ÉãÕ>¼Ü"Ÿ6Dl°µ^õ!Ò§ïô¬„—Ô„O)õı‹Ö]eK¦!±k®V`Ìú°ï‹'á$Æ»1…şqşùî‰É¼ùCx‘Û4GÛá[²ÿmw¬ÿc…LE\¡úbúÌªX[q¬sßP³ö´öÀ2«jdNtô}“¦5iE7†®ë¿W½÷¨îo´¿£Q¨Tºß+„ïğk4×Cˆö‘É®ùgğÉ5øo“‚}‡½Ê¢`ni^•ç"åW!B]È†ÉŠ–9izÅàú-ŠyfØÃe_–´õ?w«®;ñ˜ˆèš”ßX]Ì:.Æ‹û"ğ×‰LTš„üÉx‹Oì‰¬·“Y‚¼77,HáÙs7“Uuü@Í±{m‰ _TÆ*¼‘	`†.ñ…@¯p²\)VëâõTŞ»Ìî¸ÁšøÃd’+°¶(ØYXH0uò#õ§‰Q	>ÕC$SIö•è€>${:`"‡ª¡É\® võeî_3²š¡ mÃADqGàå½J4ã]!ÚŒ‡|\”Ô{>«€Ûè+ærà«èÖl3ÃZÕ¿ĞÁ,ô¿ÕiYT%äñêKp(µíM”òSSö†âØ’&Ä±Ç-ø+Kßû^ağepYUBGHğ‰Dpn¦ÉÑ,T»6a"}ÓpìõÀ®œ÷\3ı
Ğ—ô˜‚j8=8öTñÌt³8Ãô¨Çj®øÒê}§qvÑƒ‘A3ë,½ÉU59[ûÓñ¼+ÁÑAOƒb¨ÄU'Ô˜eÜ3 Z}¹ï+ÀrïÆlVYÀvïÂd%¼ÁÁÃ	¨ñTMãv[ËO|õ	³R¤–Ïzß«ÅXWO9p€d×ŸrFnE‰êÒ&h~`R,lÄî&9X»{UT:äZcBO`¸Du³ˆ—µèooH¤¦;ï÷¢yHÍÂêolèƒ$¸:„Ø{àß¨© éÛ©QJ•IÄ£¨?œ!ú)w¥`qZ­ê«i½™ñ(Ác·üé‚Ã%¯³Š0ô¤vıË­ş8 ¸v4¸pìBD­¹V_@­ş-Ô«ñ2¾=Kr´'6A˜ënUukê3e´‡í÷¨d6À5ı;ø«ÊZüÍ¤4À¤A\Ç$¹H
…™¤?/‘¡ÅşgV©!«*REª±K¿¡õJ!‡VŒş}2>gn“
^E?&½|p~QòØµPôFZº§¡HØÏO*˜v«8Ã»†ÄÿÓõ(²ü€PÈ©FµıÕÁä—Ë¶YFOéØç¹õƒÖñƒIßşœ¤¡Aî:İ¹(‰Oø‰û5õ>J˜^:¾Ut{ë=š"õ¡¬%oˆZ\°=
lsx)5ÈÏ‡äÚ)ª	éd4Ùb¾æTwê>Ğ6m•µ:Ãou;¤(3Ô,¿‰+4ßs‰ŞµüV{eT¾®9R[%“ó7åuğÖ=Ë«]¬,ÜÇ“Ó×$Ám2Çl[ˆãÅQ¡D&şŸıeAÌJMºËÍşÜ´ÂÅ«SoˆJ‹`F@¥Ä)›eõ4¾+'œ#sYéÉéGÚô(ïéêÛ
Ä¿UÄ£ËIç}©ntªÓŒ~û„ß°ZG"ßXôªT¢U¥:a5W;gä§‘$ò±}8,%ßŞõè§&¤+¢ï4`-‹ßwĞ‰à"0œÅŸë'dgy@?Íl“×±›ç÷—	—5‘HÌó™g%ô|ş•äTŞYÜØF¥ş°@ØìIş_ÊÂé1™,Òªu|†|"|‚ãó÷[‚Ù™>®îğ¸!`¹>mô´7à|m¦+lC® ™°vvHŒß¶sÁÏˆk#ÚúÆ<›cäùˆ0BúßÖM1ôÀö@¼íß”I@jÊÎTş¸¯4±Ax­j¡¸JH¬d­ù |ÂËœÖ\T¿‡,~Uÿ•ş'!†QøÄe•†aHºØ%ñ(aaĞ ˜[ûùOm…JD	Cw:t›X'£["£¯ËÔº
®¦–Ï©N*x#öØ&ö³’²@œO}ç”«‰f65ìoŒ³í6Ş¿T3–¾JÑûD'}â¬;\ã÷¦¤NNhÌ
œâJ®~ïˆU,Ö·ù &©õXûºÀô âX–œBØâ&Teh-çÂ7œ	¹~¶kè¦"¤æYÍª/M‚iUº;\HCgåX*½vJqA{æ£3Î8ók/ò y]¡VL4‡ú$)<ò]	ˆıËv5†w(èn¢Šn°z¬ºf¿ËX¢°¹’…°ÌKuDú¤@ò¸7rKv­üEÜ|•ç³äÏé"–z'‚ÌT,¢öÈ ~é§¶ï„pŠ]ú¨2 vMMA[7­b8öPE–YÁdª·”~ñYEøsÀ°Zgù õŞ^Ñ¼ØUø,çµ,ò&"qŠo qÈŞ¼GºäÈ²RÔerü DËÅgâÊTNRBˆ¾s„ƒJ¯A¤æ »|ÚŸ"Áè‹Iaù6…óÀDt^	Î8zH›hÏ„q<=€f¼ö°02—qªĞ_QÂŞ¼‰ll|ŒæÀ³´8ŒÙ}#Í™«—¹¦´z¶¼æÚbpm\èÀih-—}á¡dnä_üÃ)=‰¼M!St”ÆÒ—»X¦*g'‘¦¥L^¢‰ú”0 Àd1Â£Ì>NSš÷‹0I¯†«iúôJf‹<"H¼øp.¡Ûåmm’}áÍóû5ó^2İä‘°£ggAĞñøªj\/Š"¾ cYš‘H‡ H§í±'³‡Š/¦·
LØ°xÓ0ã5Òš!h°«M.Ñ½ª/5A)IuĞ«!X¡pàFÆ:@÷'x#ërÍJ²¬¶è™^nÃ”i"Ä˜È®“f2äc™B™7úÂãÄ¥©,)Ê¶÷ ÕC™JFÔ€Ëûº}—`òÕ|Yÿwƒ¹dº$pËRı—Hp>ì(UŸ˜Cµ»[<¦™ª¸W ş³;%o·Š#6æÆÆôŸ.ñXjG+`Ñÿ·äWÎMJFA)ià°øPÄæ“f¹•ÉXsñğyù B,S!$ÏÔŸÍb½¬¸àaNv¼BxoM–Œ¶rØ.ÿ]kM8Öš)PÑ?7œÔJÉügà|75ÒÏæ…0ñîQJl^D51ÅÖäŠo}¥®5ÈŞPš¤×TÿU¹H
’óSJº¶P‰‰M¨3)7”ñ‘·éZnDV8dT)æİûÌ:¾¥WÇ‡Óœìt !·kO”lÑşÕB3V&ğhüÇ“fo ñİ=z­TÔ ­Ù3æÒ²ô@•!ç}2œßDge9ñ®šŞ#LXïÛ8Li¢ªïAğSJõ…€àKqÜóågÉË
aŒ«kçÖtSÚ™h†œÆÙ Xè˜÷Ñ™@júq‡Po˜£A-KÍ7×z4©öy;ä°6gù¢Vòq1Û­0YøÆ îàºF+¾U‡ÎH{ÿ!b];X8b”oeÛô™Ú?…©‡(ëË©<Í²È%X»øXû ˆd‰#)%ëF‹+ÂòIìÆkrÊ™TølÍ&WIÜ		9â3ÎzÂˆÙn¹ëş^ü¢§‹Ú5BwÚ83Î6áÜÔ!ÂD§ÅAœEGb=-Ù£“ +ğ=û {G(ÕX~{)8å"ÿå5$0¿‡rMŠŠ°Œøş"NË’)R‰¨Wkş.`Íœ:Ç%‚ÔÌKõöC<ßW+>‰ÜŒõS—Áºívãp ²v™”ã“ú¡qã‡Q™·MQ†	ÃÍ§=Ğ¦;‘E—zI‰?>k‚NÛÚò¼XÿŸ*ü>MáEø;ï<kŒ·DV2­èc4¬µ²!*Š4y²H*†óÚ¬ş~&ûÒai`©Œ¸+ı83V„T‚îËDÚgã”A0s¤,<pa·ÆŠ}Y=ŒĞ*Ö‡BÓ£ÍĞM#ÑÈ&§LYË¼2y»yŒV#©rØ´½X@ŠUueœƒxß_ÓœM½%>æ!àúÓ›óF—¢8Ç7ß,F°Œ
0(53^qÂR¥×•a”Æ¬wùâYÂ©!„®õ®‰	?»èSñí²™Ò(3¥9y…cÅãÆŞĞIØZÓWÒzi¨y]U„§MoL/‹é²–l´]»r%$§æ(÷_2gVxLtÕü‚pTìbû+4ö©{a? ¼Á¤	‹ZÉ{¨ëz²8(õ4ƒHdCBĞ]WAGşõ…ğ¼ÃÜÎî‰€QÂ
­‹í1ŠûLm¶6Ê5ø”}“V~ËkÒ0½Ş*K.Kİ].%ù
”’î¼sà1IFÏ¡Œ¼^Ì<T~Û(Àqßª¾¦Á¨ïØ·ÄhNêšGm~T+s
–¥ ã¢aˆ¥Ì¹pÜæz$X\|YµP[£têB…QË$Î†@²ò
¨h—·ä1®ò7õùeîÏÈAáÆ‘üÌ›,WÁ:(Ö¡•×s¿Ÿ/ùİ7‡NçÄR®%I7dÌiˆ:yó‚Ï²È*ÈoNëäi)ÊRIGğ¢Ub{"eì1Ñ¯ùv~:pkS¯dzArâùy*ÕjJ¦w|©/9„0Õ¯ÚM¨±oÏ¤aÁ’S&JÖôÓ¯`É…3÷Äb÷ïuI[±¤A¯Ûı'@ØbE½ÒòaÎOrÍÕšÜowÈ© %ù­ˆë™²´Œ
½¯çù”Õñ¯
!!ûªş—ewäl±ÕŒœMz©ÓmÏ ™ğ—N"²bø‡c]ÎWïxáÕ™O‰ âgTåÌÚA¸)éµ=«PÖ6«H^6!Ï¥tR¬½ÿ¿./&?é¾‡”š®Pñ}ü±èÂı\Ì_2@BC
¯Î5«$Ò
¼¨î¡ş?é^s `÷*£ƒ}¾Šm~SöÒà.È¯¼ÄŠ®÷Éã‘XCxc~<ÛÖt,\ÃÉZ…éh„>^åOóÍ³*€ó“t2g8ş®[öè¡í€fû1„ÒİBïéä°õ«²4&%{Â Ü‘Bx8ô­ÄØM!XVó”
ÅœrÌÿI²û\j+ÉŸÍvü»§t¨Á$Ug,yÎ§×gx“8Zİ'BÁá0„û‡Æsí®nÜŞg	
*á'TéŠFEû@ØLa ïf··Å”¨ô¿IvÂhD5Ñ“u^;–uòt€©ğãjH¥m\·XÌ^K×)Å'-yÃ§-W¾9êlÂSzÕ½:£\ˆR`:ZT¼ ÎZ¾¢r»ƒi‚É²ê#šìQuj,r$ë^>Xs¥^XrnÒ(ˆ²ÏÅ€Ÿ¿ˆÚ÷|LÑ´ü;³ÒÏ !ƒYâÍÇF3)ó{ÜIJ¸²Á¸
ª6±Mİ²NÕİ‘®£6ê5ŞWz?'Æ’Ö ’ü(DŞ rË:ï !&ñç<9ëv±1‡|^ÉÀ‘ô<İw¤ŠÈáş]SU}¿ïUÕ©û²À÷,ix'é‰!³¦\­À{¦"oãEO®jš~—p6y2 ‹W‚½äÆ&Àwµò$õÄªÆÌbo^,4‘á¹•÷¦B¨™Å7(×Áú5b»] #’;|æÑæ ÕÙ"•ÚÄ©ô0CûÒşÈUì<ešŠ¨UÜĞIsr‡å»yÿñÖÜ Zfæ§qÙ×+–Îò<c7E¹¬€½€`î‰°f=Ïc(15ÕĞF_è[»K_"$N­ñ}²1«h£n”z¨Y{Ö®8OI‡_ÒÏF0»´ê©:î8yõ‹ˆàf2U|ê¼b¯©ƒø€)¢;'/‘@El¤¯ô[¬óä«—ºíÒä`¿;9›3ùÑj]®ÒnÙ]pÿ
ù|Œ;ø€• ¢—î2ó¤ÜÒÕ= s¤ûÉ{¶"0‹dúÈ`k‘E&@6(@OR¶™l“7’t*-\ô–OÏToà’)ëtö»bä¿ä(Y@…§q&2•«6  Ø¦/c°@¸ÚNTÈ™¸“Ùv¦xÎH÷$¶O§0ªÍØ:
LyÚ«©Léøª¯Ÿ9­„,Oÿª.f}YE,l?k!Ñ§³ô¢'9D¸*Q`BD&§L&\ç© íCø‡ZkÚÔf¡ß8C®ÀŒL’ã<ÓI7Ä?´ò¸<>¶×İÌe?
~z>kfŒÇ¬#²~"¬Zµ@6½')AÉŠßôí'™!M´Ú\;v‘¯¿55³†ö™¬­¤#•r:ŸÍÉ;ÔLÖø‚î”M ö
İ
‘Ç¤™«3›¦–ÑkáÆx² YÈ"ã:Iˆ&1¼A‘Ìj‹Sºÿ°l…1±Â‘‘W±óÈšnÜµ>áÃjƒ¦hªD wÔo„ó,Á²´f[-ûÚ7²WÕj-´G‹Â!G– {$šCïÛó_®í•Ğ,â34!±AU¸%®S~Èâ—>¡°ß‡Ü»S7}Ã|ú¨‘åJù¦í»‰;1-Ë,hã45üù±Dc°Õ¢\’ËEîƒU Æ^*Ûù"~H—bàÃ@^Ø4X†V÷,¢^Í–èùğëQ5„Ø\ÔcIÁÜ&M LÅ7v B‚ğÊĞn‰g%¢%Û3[Ã†XøåÆ|¼õJj­€!qX­}=Îœ`œ4â™¬ÑõÃ?PÕ§Ò—ËTÂ]˜Äe+xÂ’¦òÖJ—[äØÙ”0° š«@7$ã>@œWÙÊ.ç/Õ„ü^·Wçş¾—÷8¼ŠôÂR-PJ—%+ºî%C€¼ Ñ«n5U¾ÁŠ¶rğüşpö~÷’ï>ğó€qd´ôÓ[½´U³ŠÉœFP?Åt’¡'gCäH„Û×\vè„iÖİ‡fU¼³èêÔ˜Ø\üÓYÂÆoòíf¨<æ6/ñU™ÓìwØó—óUÖ†D\z´y°®ŞÑàXün¾yÆ¶ùD)’4|F@aÍVjfØuÁØ°
ÿalÅâ@ÛLÁå‡|ªØ½ >2ÕV¯¨ğw!ƒt]¸œ©šÓB&YühúÍ¶	ÔZ`1xàïoÚËc…
ÁdŠÈºh@{7MFŞ¡RtJƒØĞZ[b+«P´šş1¬"*ú}|(¨é=¦Ié¨v±Zıµ˜P|ô?S¸
TR,ˆ]ù·³’ú:••W\]I÷”9Z  ³ìÿĞcü;úâƒ1ö!2¼?l
ØAâ‚	‚NÕÌc²P…ø•ÓÀ+S²ºi¤ó„€±ÉŸ.ë*s»»£’dÎê=¦—™‘_pŒÓDHdûå÷vù« tĞBN_CäªÔ•˜=v¹àšÌƒæ¢T4ú¡©‡vU]‰O²£ i[³İÀM(PÕÔL|)¦ö›@æg‘éÑ4nÓCuGîõSr4Â·îjhgM7Ï†Ş{ ş9jılÉDç~zfßhİƒ+Êöw‡ùşD4ûè¶ØxÔrh‘a*Iâ³à¾q­àÏNöOæ<;ôfçf|çÉO§- ±XB‹qT(KÄ‚f‚vPµ'gTŠúñâ^×åôÆ 7M…/¼Yî$ŒRijÉ–-sC}SÔ&Uz1]«^VhQµ»ş›@™°f¾,–4{qVOQıJ—¥¡”³!½YE?‡„,DF"Œ+™Âr6PëgäSø¡Ì²?»2jèt¾ùe3¼ìAò€ƒ÷EÇ®Á.”(Òa°v72ù2ÂÂ0øàà¥»sCC^÷¹ˆ)îgPn½Ëa£·; ã`rÈ\¬³;wÃ|j(Dß‘&&h‹|$+l;¶ªè^°Ûšy„õÖx[óöe(œ<K4V1_¨ÔîÔø]¿m4Àè¬(w‰ÄËåU–º µ;ŒÌGo¤zÚ´–ì$š§DLkÀ2Ò¾,¥Û=©ø Ïä	õrÙ‚ÊTeøJyiêÿ½Ëü¾{Éi"á`Ç¹Á‚İT!l}I2hÙ.<ñ%9GhÂe÷÷#ßøóìÚ±#”½›H/c!}Äù6hı©PZ£ÃI€ÀBb½s=)›
æªôÒŒºf®ÆXŒ'´{ëá¶l‚sÎ‡ä©¶”µ»ÃëÓç
‚ãT±e¬™¹Å ÚXjr ¿·cBJr¥OÊBF9¬b³ğÁĞ4²'f,1,ø‰h]ÛòÃ[ÔuÅ£XÊí§²ôÈ2+Ï…í_ÒØÚø×Â¢$…ç†aÃĞæ‘bµ›·ÃÔÄV’Ôìˆ¸º•ÿáM…e¨	JŸ4>¾uªpÄµ×Êu,i»Ø–ëÅÁö0ä¥LÈ9!xVçÛ×z¤xîôî£X	³ºÙ-ÀòúaÒp]K÷¿Ac·¥*R¸«‡Éi#ŸùıÅVõ¢G8«Ôa>éãÆÂ4[p;~·üuX”›BùåÏÜ¢EtÙ‹29ƒ~©†æl¶'%ÅiLÉ ê6‚2ú×ÉºbAÀ¿.İôgÓ÷»ÆhGİçò?¶J
68}‡KK.ú=¾äQ‘ÜàÙ¨Wşzå*ÌÀ©~ÍH~ÈŸöûûé´6à»$d†\ÒEàhó™AL&ş
‡³±+j´²h_„>s¿—™ÚÙ.‹1ê·²áŞ/,ö›Ú×bé0|R1ın—£¡(SÒOnÈ<³`ì2fÛ’÷„9Œh„ÆÆİ@€eç1
Õd`Û—:u@ßŸ†7‰tíB¨kÕó¶mæ«Ağu#/˜$?[yçö,UUÈƒ± dfÄgP‹¦cI9Ë…Ø¦ó^oşÀï}r5ÑÚòI|AÇ5¼Dâà¸¥Çt!b?.¥7ÆÛøõöMV˜®ó™]ßóz|¾Şë}¼ÿ/ÆGÜu7v¿Ú‚|eñ;Ï¨ÊŠ’ÀfÑ@U´ù`¯¬-RwzºuH<ÁŞKA°Í=” '.,C¿Ÿ2Œœ€2¸Ğ›ÙÕOjµŒK£`ÉÓ&EZ¿ï²'ªw$iŞ‰nqîg¹HdRmû¦J?"Öp¬VDp.8MÆ9ï’Ó;âa× |–ÔÓÁ¥¯ÌW€—rp)úó\xÂÛW;óßlO¤m!æ'Kwñpà$“Íò/&ˆ´“,&®T÷»pé´¼‘qL3É§èÎ¿ğfå#Ùàeõ^}¡äÑ©›v(¯kĞœEäÁTÆı2óˆ]Cu' fmÉP^dÖEŠz†O_ãÒ
„%Ö»–ådc£?º%ZŠ-{`×BëúÊyUœwÉ°Ã¿º‡·¥Á²©Ìzƒì˜}á?Ø‘ÿ[>3}F´>æHˆMN=òJ’6jõÄäP+ÒÅÓÖáNØ6+í 5="|¦£i¸¯>cOÊ·ó‚f2×<˜jŒµÊ1Ø#±Û<A(umöšá4Õ½¦	¢¯Ö[‚ˆ!çÎeàRóª!Ù™¦÷¶Z˜ Xa9N5¯ÿ	zD=Y<ke'Øb,ğN€ã‰J!,¼ûG³ëÖÄeø1ëmò75CònWÿ7cù6:n–CÆ¥£èrñ#[$¹ø™;YÉå^FKıÚÖ&ãRÚ^¥<ĞÃ²öª¦ÃcO­¯ÊNr¬pO(íó }mî4t–åŒs Ä¾¶+œïû†™İHÇ/àü’Ì¶¡ÔŒT.,Ğm‡ ®Ì) Mµ‡\³‘—×zWlÕ¡†–€…‚Ğr`‚I¼‰"€Zkÿ$?ij¨7ÏõâŸ
e¶F•æî‹¿åYO“;©Â#á[ä/ÿÄ÷7ß3ÇH„”~ür¾õt3cšŸŠ¦&´ÒµÎ;A¿İz<ór#‹úe÷Áİ¬9•ª°ğõëmË®ùN­'±ÓP>İn› zeÙÂ?¸Ç—u“y.›â´›½Õ÷:«ˆÕê>"?èĞå!âëàºË³Õhò7!¨Pü&•6,$½T1s¹‘ç!.É`ŸcË …UÓ)æ°¢+æü~ğ>)á&ª»øbû{¹ƒ*a•˜:@.&Ù
ğah$ÍXnœÚ„ÀbŞÁn…3æùàI÷ø•Uk)ş¶8<Ó¿cç»,ÖÒ˜#ÇşkI„Š˜Ü ±·DŠmÑ¡
 WqÆÃ:
I¶\‹°0ˆeİƒ¯W3_V˜	)#ˆ$û…kŞ¬ú¸ŞM	¿›Qô°Ã–æ«2;¯ÿÊy‹kÔ"@cïúáÂ`)yÉ#¶œWõ¼åHó„H[áæ†N*Cx†Xòƒš`
Vì„èã©JLÈ"Ìl‡b;Èªõ „‹œBbN"ùbæ³¡fé²RÊÁ¤¿Õmœs¤i;*ÚîÈ®®‰•Åô+Ë8f2Ü˜;³@OöÁdcü’ÿ ş‹ZiZ^Â^Ê[¡ÃßÁùdHğJ‰·%/æ"§Ÿt:…ìá1ª^Ô¦ÇY«h¼2=¥›äƒKU¿üÉ€"…äjÜ•hwB'k½Êšş´ß”ÿíáfsmDÂ·Ü•³ï¼g2Üoùnãö¨z·8"z<*\|}Œ’{ÙÄ¦Oq±†i%ë´·¤÷9WÊ0<LÏ6u¬šDK8Z•¥ÔÅã€™ñ¯”¹Ş=
'D tüèÀìê›¾“×Rm—iÚ›R^Ù2oş mÒ¤á3RLœ	:8ø«½çSòøM¶-ŞİZ¾g‰ØØ­oØˆÔ:¹Ş¥F«fS0“7=$•^X[F<ôáZ1I›Ÿï‡øµàg$G¤ËE[]È%¡ò¢b!{gó- ¯íÃ-h½}›ÖÊ´™X{Å™çNÀ$Ï÷ı¥G\¢pŸÊ¢–!“(Ú†¢ˆ”øhş¦‡JÛhé÷½ºõyØ G/•M¤&€±Àê›õŸ}l£¡KŒJF—ÿÕÿT¬åïÎ§ßó5´¸_î«‹şëtdüCÑ¨³±q‹ÆÂÑ„÷õ›8a$ ­Z‹o ä˜Öã¤2éC(£áKB–›Å’ø‡}ˆ°¯İ¨lÊ [SŞ¶™lØ
e1)|ğ-s´gpI-/8ŞÃ{3³‰îú¤•Î•WœĞ[ÍBÍ	-8¾%6’L-Çâ©¾•}CÛÉ„)J?ëT#•ñ ÌÀ¬t®¼ç-ÄCä¥_Í/ï1 .VP)¦@×D.Tµ2U{sĞ.igA²@¸®¼Ë×>¼“bjgÇ8~iLL>>Èê	IñÚ¥{˜$h_ğ~¶ñ&»f)d€'‘ÈË1‰Ê´ïl°q¦ø5_5.Õ•!Û¬×óß¢åjÁ_•™Ô¥ó:5Õ!	ÑY[9ml«˜‰õF·D=­a@úUØNƒúìãt+­(cŞX1ût}üÏ<)A|¼"ƒ‚ÅÖ^…ycB©æÙ*ÂíÃ—¾Ûb@	#²	J÷]O«ÎuŒz¢WŒ$ánˆF’fS—ï¹ÔX¨ÁeLÜ6H#	h'
sAâ¬ÍãÛá]˜8ÅÄµ¦§{ÇEÚG;ƒ^ØÛ‘ƒ<Á¸â:~+ gçó ’¨J	Wµ9Úx{nmÙ’²¼ÓÍö‘È“êU‹fKK§ôw@ÒU±úîn%†El_-n(Õïjû¤éöˆGqCùĞû=CÔ§Øzëa(§Ğû•Ÿíœ éÈÍÑÁõ€€q´ºëhÏ_¢`¾©À`VG9Ï¬:¤´ßõ_1Â¿:´_Íe£îíy½­ãbn e™r¡{€ƒàü4]†–·ë9Ş5Ûk/ÈŸniq£I ş4ûA*˜ÜÓöÁ  b½\òGßÃ†jê öQG ä
y@ŸÖoşÈ&2×.çnı¶W¥d<6¡¿·¬¦3›ó˜z4#bfGz{YX¾³øğÍç´Ş\<_Ø†|  y’M¹rL³ÑÓ´—©:äg3ñ·˜¢÷°¡5g‰&ÙÁ |ıˆ”šñá¤PVè*°îRKÒõ†3õÅÃ®‰ ,(Ë©[_LßZş U,`!3.!k@ÖdÁîYšÜ{ù,Ï^®@¤ò1ßñØ|3ˆ¤HqdôÆÄgi£ßPà¿?ËıE9	İm$îrÂ°Ëè²ÚùªSk±œY3sbßÂû&è¸5TE³&P¿İY¾×û¡ +=[kıLzüzV(œÂ>~7GHÉ·èL'ô\¬\ {ˆÜ›S–Õ2‹q’À'‡¶i”®*÷ó£®äûtZXÙä‘nË5Q<ºÕdÉ’ú¥ï©_øk^$ßÌ5³Œ\MÃòü+Î ÃËÇŒ+­=k_¿	†Ô—­5İœaG³v.sùö à&ûï?
Óx :}¥L!õ.+ªkÙİ2äÜÃR½¸ìùÎjÎâ³@tjğìcÄ Wgx{çŠÃÁ™ZKXÿÎ² ø<Ø\L=˜Øu#Bkµ˜ašÉ#ï’µ4|¿‘É7Æö¿,ùVêóÒ`-~î
P¸²µÚ#ªm1)¼Œóê§§·ùULb–Öb¹o‘ŒÓİ«•)¼LQœhi”ú;¨tÿMœ´Ûæ3&¿y=ºà…<9ùl¿fØ4èç?üëÃl; 9¡ŸÀÕ WO`˜ZtP
ÿŠ+A[NêN0\â–¨8å0R >9É"ÛÈ·c²ËZ?D¨kXÜ2Àn`ãÁ¾8¹Í!ûÌ°Ã­•j*ã×j|Aü¿Á¨¥D½ãEÏÏîdø`6™ø³ÿ¿‹ı –}ÅÒÜ-ÙorÀ3¸·šƒë!ºË-èWéaZ¸Xö{DjhŒËĞîN[¶£}èˆOíGqyy§áê8{°jæyg…,ğÀŒ
ƒ ßƒ˜@túëÖªö‰;ÓØµ·BÕ¬WµûdÊ¿N¬6Pjhê’éü¦Ú¯nG*Äjêıó¬ò‰äÄßøé’ôe/\Ç=õZšLŞjŠØøUGƒ#Út:öG ŞÚiÊkŞ
Ï#jÿîŠ«ÎTÛ ÄŸVWšºT[¡Ù„Wf¢f;6ÿ³6_7ucš›fÇ¡”®¬ù/á˜u økeMhØ%Éÿ¥–y½?ã|êÔßë¹»ÒƒšJœàìƒ˜ü¹´İa¹ŒùŞeî8­1ÒÕ— ›åbìò%> ã~‰6¨xUú“6ŒgĞ<û1ˆÙBN_k+¸‰w¸‚1È˜÷ )=aÒ0ì½ÏËo©Ø²gq1’ÔòõgË‹Š@DG96Ï±2{^â!¡ÌÌŞÓ©m±iïèob4‡J”Êsén
¹H±î°.Eéá–êVhà+Å¯ÕcxÇÜ” >ÃÂùXfxú[š¬Š
f^0sö.àU#Æ¨çÅbšîX¬~¤@Šµt›Cg
 ]˜
yMÌ“ˆ–Yòümó}è ³î¯¦’‰ÑÏÕ½íûL¹„¯‚!À°3³§óãI+ÛQ	¹ÇÙXXtÖ+óË8½¾Z[·úÙuadI|
ª½±HSBÕúã½˜]¥Uø«î“*šçBø
·A& ·?`FÕnQ<m=4+…²ådexúã+áVÒ‘×Zjú
HU§76Ô"›l_#C2nÊßkmmŸDj(XĞLY
§‹BÛ”äUßBwûl”¿çæ÷*Ô¥Açp4"?Ã?ˆËËĞ É¸„Éñ”_ &ö–İrçz S#}ÏŸ×¡­F{RCMOâÙò`oà;^¡Wå:²*Švş+ÕšÁa¦
•íL_¦m,	PÛ2dC±v§ñW|p	*Şt/ŞOÛ—–µ\"F^“ïügœ˜ÌâL×CuÆ©o–Åx“SÒ€NhwÕIõ2áCêXì¨*W´¹š²JuÜÇ<ºn-­RÎY‚ğ$Q,pôÿsèE»Ä–œ6¸İ®CXU|
vÔ	úXòWË\ º;Ypç8Çá¶ğ”À#‡M|yˆ.üV®Oà43´™„§Ê4ÇÆ¬0ètÃ%!d—·jüé’€†µ :-­Ş Y·Ba4%r 7VèTÜ…Õå¨¦p%šçÌûPu²KĞ„I˜™DA,fGEŞç5©š/Æû~8ôpêcM±Wë¹<8[Pƒ–V,Ñ™’Â00²Ã9ó³ï+·®‰kFµ-“ò3•‘Nk”Aœ™±EĞwDÃJ^«PªuKı ®W#u%éLüàëá]Hp;7¼*B#%ãÒA¢3- ‘O£Ã1Ã‡I·(˜RVëÔ	cª1«aBdå­Z%¯-,íóÇ[Ğ€÷ñu_IÁ¥ÂØy(JQÈŒo"7i	¸äTAíYÊ!nÖû!Z‡"¢ÖB.r‘Ã¼
BP˜J”A†‡!æçø>ÆoÎ¯Ù“J°!‡^!Ÿó¯[…tGÅ Ö8ÁdÅJú)»*£|½ûˆ"´a+‡¿‡Ÿ–-¿Ö›Æ9™Ÿ1HÂÇÛG—á)«Ğªbİg¨1¬ŠX´­¼cç¿œà?Ÿƒ	´$"?Æ|Ê’Ou÷3áácŒ­”M+ë$ËR…'êÀ>f^Zç/u<¤œÁ&ÓåíM1(y_·>ô…¬ÑbŸ[ò}É¯óÒÊØ©õÔîÖ=4}ÑšŞT¨¸„ôX&i•É=¥{i_ó=­XõÕR×S­®k-|RĞJ_>ºqËÉ›â&)‹Ù6Ûi}xê°FUƒ"¸äÚñ,|ıo€ëØjš¤BÂg®»Š©«eÏùâ$èé…:¹Ñ‚ r¼E±†•­­Y èu—æ®Çh(÷|e;Ej!:y«…Ià{y|¾”,üTÙVUOÔÏlnÀ"H­$®,›§cÛ/>UF”çÏU˜Êî·õú<î{
Vs»AD‘Íõ]c5Cö¢Wl@•"ğ¯ø¾ZtÖÚn$xn¾›˜aÎ7Çó÷o£¼\cf­·æ€èÊ‡p~!%ƒš¨\an&Ã¨9Æ‡¦±„
ïÉ²b9HZ	„²µ4a^ÌÛ;÷¸ÔŒ,9HÅ#~ú°8,ÁÍ©–ÿÔggú5CBšÁJCÔy‘Ûg[ˆ…ŸÖŞú=oQ4’åKû@èÔ/ÚF"¶^áñ&ÖMïî’“1€ê½?6‡ˆş8)ˆ^ÄØ{Õd†4©YÂOú« D¦¡°ÉbQv¼,…àP« œ¿i\wtUk¯ÛwÜ±hÌ‡rã/—J´ë»ËBbˆ't:ÈªmÏM±Zeè;w¡^Zì—i}"ÑmG7,’ºpÆ÷ÜdÏÕ}†X´1ÚWh½ëÃ‡Y š0ŠJd2ôéægV.L+Es%¢ÿ€i|«[£ÇØØ7¦ÿ•§š‡pYÕo¦næĞÚNŸDl©Üu¨}‚Óqeæ¸]ÂRmï2t3£]>é@?OmÛ™şçëÈºµ5Éù“ru	°+è”>Æ(ÍíÍq{Ù h$†pÔéÄÎ­¬€'õ¨"x¬×’#ëjŞ©åğ¢_ÚBÌÂÃf!9k¹E­÷MVÿ[Ş¯çÜ0t0Yª;çïÛæYnJ¢ö@Å”Â	ƒ¿}5+È™ÙXŸ¥7” ºí>ópŒ Ó	m^²ÜÕw§ëXeèQ¶æàË±:‚èy¶îÓ‚Ãi¦üÑ41Òë*¾T»î(—É'-eÅÜˆÛÉ>B½
×¤ªáîL)‰€û©tcîH™Û~˜H$ì7W‡ÕM]­}\¨Ä_":†ÀÌ°‰iÚ¨­ÅÉ@ªøÏWA]c?±şOø‘3V*mgôQı˜&;AJÚß.Ò9³ğ*ã‹}©?ÍÒhDÿÊ=rÔ|TêN;‚ö§¢¯İœ–hÿ$´ÍE`‚”Á–9LX>Eµ9¼Uä8µ(Edæ¸ÚLô^üöbiéçŒ"ÊÁ™3œv…P2\mâ§|óTÙïKëßµïäc0@¦´ã]NZ©²!˜k÷yë:›µJ1/7M-Ü3¡j­CHn QKk1×`†Ñså7è<eTU›½^ÈĞÑ8zÑº2İ
æiFtØ›´½v`pä­š`~È?}I—h"›£˜¼nw*¿[pñÎŞ\ŞÂ2›]ÔÇ6OëËÍ²²]ãqRG¨@ºÆ«9aˆU ïÒ%îÉ¡h9z–FoŒÇ„Í£Bp;sÒW8{â’™\qš9V)À3'˜…oùƒ(XúõV„ıÔ®ì ¬än‹ÿ»X‡IgÂû¨[¸ªë•¸ªót¼“ÔbJp+ºb÷ğH_˜&ÄáoÛ7È?øøÖ§ZMfbj¼!ƒ‚øg°ƒºãÏVºµeÙ›Šâ¹³-ljŒŒƒÉÃqšğ
[r–KøåuªÃl;Æöç‡²Rå#™|Ên£z}¢U¼ı$äı8³_‚oV^9Á	¿uyø—™¶İ+ˆÓš{©ôU·K?Ù`ŠÊ¨?ÀúN¨Úß§RÚA¤>9…‰o†{ğ°L­B†|!ÇÙ/:#ô87ª£Óª¿È"©Öİüõ—ıòæX†'Be0YåucNîŒ\}¨¸ÑGR%–”+W9¥!Ú0ÅJ€y&Ø½»‡¢†x›)Ğîù´~X{KC &ğ:Æá÷¿¢›Ù_µ²Mñ—ø7á†1Ğ“†$F¶Œ„©ŸF€<ˆ§«/3€Ç0M`i-'D4û~F]å¯o_.öïŒl_HÓ7Ä:œ»BÛm'.ø&t˜
Ã
etÕ	º“&ê’âóüæ8šv÷/.Ï+ä ”šGK+$%¢ú’êÒ}È_”B}Òüºt¯ü”£i×Ö›Š—ˆfâÕ–ÒÏˆ+‚W÷½İËX×lÛ˜íq<à}ÜNá»ĞÃ«*vÂÁãA¹F€²Bÿb0f—¨F€ÙË;RãŸfWXÖ.ò.œfªvzıÔh?¾`à´Zg50	·ÀÁĞVi?Œ#AËF€§]†ı_ ¤J¾Ñ%–ıó¸%œÂB@ \2Ã‹xM<³ˆ¯%ÑG—8“â‰ÿ¯«÷Ç[`¬ØõK**Şì{ZQg~ınª«|AP¾a–¡çæà<)Zf‡9Õì]§ÎE—ñômœ@>©Ø¥ .Şb Ô‚‘mš!1±ŸôÄR¡¯ËLçÒ“Ú´üvP‰ÀÊYı,
ßmHêZÛ»ŸwR£‰®SÉî’ÅDŒÓúÓ¸Éõ<ş–väWf:¯"Òj`à&„õ@üï£|d'¸X–á>³1árı‘8Q#)§i-¡>t@öÅ;ŠÍÃı}A<¶ê3‚„¬±b95Çıaø-¹Ğ ÏOå-¥ßyÓıDÛS%2Æqqu_·§f¯ËÅíÁ‡wcµ±C~Øñ‰F‡|Ó5èıÔ¥E¾"^O›ãîY‹¾âÿÁĞo)tkØÚÛçæå¼ø~­û/«Fç` ÂÖ¼Ë¡q‹SW´ÛÌì‹#‚ˆpâìf¬„ø¨Nd/µ[Ÿ™"}ÃúÒw:
e7lX0¡²DÊçš/û¬\7wã`hzAìñ]¾Èî¾!ˆšÓ”´gñHlïöyĞóZá7&ä³Ïl|'ákìrUËXBF¿ÁVå.à,£0ëªĞè”qîœü
¨exx^¤A6ûƒğk‘â#¿ˆ¾6Ya›£ §¼åÍKxgM Sˆİ¯s¡ë:v-`	­±Lz©×ò·…·²ƒÈhİ¸'Œ«´Ô¦ÀJúZJMY`Qígk8
îÆ^}bõÎº³y)W2Aü¸N…gïêñBšM8$aVÃäËA©ê;ÍqÈ3!íËp‡Âõc$Èa6!ç©/¬;ãÿ? 9¤²Ï¦Gx8T™„àá7lRµ¸‹`-àVõmæ}Âµ¡XI–[«½&lzD’ñ^üB€éî¦üftBPÄ—Höÿ2ãcè±´¥!›„i ‚£È=3Ä]v/Ç¶©L'ú3Œï…9uŸë¶òß«sÇëgŞTü—ç‰n„0;JÑËôÅš¼—ï>€˜ï’²Ó4eeì&U¯ö¡R +ÌÈÚmQ}c¡Ëğ¯Û6«x=Ÿ7ç‡qˆÊÇüEIÂU½-! ®êıëƒqÕ³Œ zx$Bn7$l"É‹÷k¡
yHõeò_„æT&´lÜªÍæsEfv@ùÌ“1uÃÇ. ÀòÈåoå¦p5ÍôÇòEïğÑ‰ŸWD\ÅI>¶›1û‰Ë6l•ÿrfêEÍ?aãëP$¬³d'®—ŠÖUNæ§ÈŞG‚±Uøğ\D÷Ô
$L²€ƒ…8y‘¢+èÅÓ<S\ìÑËÒŠôÌ:¹«  GÓş.uÏ²Pp¼É/£¾½ç|	U¦po¸vGsvôu[QÔLú†1ÎRÍqÓ{G_¾“ËS›’ÁMa+ññşkÇæ¸Œ=,OxgñkYLãq-6!—tÒö&´‘#CÛ09Wè÷ÚÂ©ñI¹®Ÿ*œW[á¨¾
Ë,~	Å20ş-N ŸjK€Í°~ª~øp4æH[‹± $C‡ÃÈ¨c„['¸©»,3ÇNm˜œ·@aúºÚï”7v„¹nÒƒ—Àwƒ›Tã1ñˆ;·05şbXqÓ‰ÒİÛ,[ÖûN4âT—z6Ò³ı9á5Ã´@„cLâMy^ß<®ÛÒûI0sVĞ"÷¸L™n Ë²M”<ˆÓPæ¹PcëÇ,ê¦zÒõ%K!ğ¼;6D°û-pi5U<
²½Û©»şh9ô««Úìã)†6İöâ”\™Í­œ§ÑÂ8V„9ã~0WÒ¹Û¬ÓµÿR©Ş&T‹™`ààûä²B£Xñòß^f¾€=5BLã/cıfªHáƒ*ğ²'ÀGÒI¸ò>ò9:95Ò¶%!W%cFÚè½n+³Á©sµƒô™«¬¹PSR]¡nDº¶Xg$`=Ù8îmÊƒ§şdĞCã%¨lğte(åG{8»"JP'1Ñ^Àº ì„!œĞvb://Ô˜SqepLÛ9°é¼~€|tÑˆPIÄ²£u"`|°ÔƒhKĞ…-àVR„aó4`Å®³_ÄJ‹ä'dBWÌğÏ2Â¸I-V"J™'+«AåAJ¡wï{<Œègüã‰fgİ¿í`EşÕü¤ÆÓ˜âı‚î…ît$>ÿ% O…¬
Vö‘3Ñ}ÍÇ &j–ÀyoëÇi~}´‘Î^ÜÑ=ªÀøX0æZü ÷<‘œC¹C 7ådDÂK¾´óS8AR¦Y‘MúD‡eG¤W;ÀÍ™	˜bLâ•>œ¬Çr$İ¼¼KË”÷ì¾ğŒóBFPœ×]5º°U QÏÂİ+zôjêm~C5ùÊçÛ™M‡³”ûUm¨]u\Ä=1ÜšüeÔLòÖß£¦ºø”jğğöÅü5"•Àùá‘(
5êmô)Şx5;—¢ÿŸĞù‘³˜õ"«Âño%Ås)$ı–{’xáMeÖÍrõCe.€&6FDèUN§Ù90Aİ^¬İéğA–áãöWœ8ÀÅ‹Ø3æ¯œÍ
¸>İ=‘ÛÇ9H:˜s²ÜZ7”XHô2óc‰oõiX+x"	š–—¢åŒ[ $fÚë²‘~J4cÉØšÃ“âØ]š0çÕAÒ"SGWnçÖlÅíèÓæÒ1mZÂå>øû™¿•ïø6‹¾:¯Ukly„§¥º]q=ñÇNŞ=İÛSæ¬7õé -¿Ø›ÿĞÖ”´3…ï‘h£¥_`«VWÊ-o\Ö ×:…t@ğlif	ÄûÑû‹È, 4JæŞ $¯+|¹¥–•èû—œs~EğtÙÌ¾†ev™a†&ŞÂ¢¾S Ìá½Â/ sÜä&p·;ó‹Ä®Z0Îì³02çzŠ¾;ÜX¸ı“\µî×5z	g|gäôÁd<vÖÉîfuÎ–âtdŸy¾ú+Ï1qñh‰7ÈÑå,	cu?³¹ Üz o×Q{’|3ÂU¤TlÖ±ız{L W¦Æ7Ñ{ÎõTƒsˆÎf(F?YU•j”p1 ÊxÈO—Dd^2Æ1³¿ãà~k¨¥_,é¦9NÑ “f£©fºòjP>â	Äc+d†íAh—m-ç”[fY&ñTò÷‡&8Tá¨Ô5ş£}x{ìJGà@ãnÿ»Z¾…]óG;?/dÚãlÖ¹ºRXä#"çë9y_!£2Zb Q1;ÊÜ)|Bg.c}dA’Y:Nc<@{ò2Hè„_-e;]–®­Pu˜w_ò2Æõœı¦š¾~AİQë/öãÑ¯¡ÌoÕàêom Q"\0%r“S÷´”ÃSn;˜IÔU'yIuáúzİÕl³¦IœŒ[6pwÚëÚÓC¿YaQo†¦ïüV~İ•ò 8Àú?dæl.”ş£ª'sÓAö)cuñ¶ƒ‡T.è5xÇybc¡ñ–ÓÏÁiŠ8H6~øÔ2m£¸½Ÿá›xş/ÅÅÖrokªœç?nTƒ±®Ñ5³Ã3•ŒyŸ«çÃ9/Y½Š.1…<L@¾}ˆÀ¬Š]ïz£G	½ºÕÊFØ
šÏ`gé™Ô¿¿6{ãŸWşÇ.âH&I3-÷9Çn›6÷Bïo¡ş‹hH‡¦äšP}ÄgE.ü;8…<¥Ÿgƒ¨}ˆÏz|4Ø¸>FÌâJÌÆEñ­vçdĞÜr.”ty…@Í!2‰=q&[¶¥Á‚J Y~şš¦Â4Õø	3\³rşèaV?ƒ£jği^Û¸£¿sü0ƒ•ˆ‘’4®Ô>ÈhøÆVÆ²éI º»xİ‹Ì )Vİ¶Z\~U}»¹
ŒûÖG´ö%[]²Ì©Yê*]©ròCÊ0Èæ}¦‹=ÿŒ5é¥§>îƒŠñ-5|ÇÛlnš×¯UA¡v¿ßÃ?z;Z„\ñ'S•nñ2C¨OªùH°p‹Ë|>”V÷ÄÆÜŸ..¯ˆéÕ®‚uW[Æ*Ğ¤"¢à·ş˜0,îÂ4È2M¨œŒ¹ID~IŠR"³îd ‹$†ŠÀŸ´Ò__§¾”¿#ÎÍ/Ò\=QÏ>Å•#0ó7zvÉ·…{ 
¡­Ø
FÆÎ7KnÅÉo•4Ï¼=0Ô˜’`HüØ`WxÕœJvæáMÈ‘¶·šÓ±âò¿¥XŞHşOA‰®:’É›¾¶c9z`»Ûcı)Ë=õy®a£	íTƒ”oâ?°ãÔ_À7íµAšÎX´·Ò°B¦Tà‹‹+'ÄÍÕš›õ6V8b÷q±    |¨#úÂ †Ë€„j³±Ägû    YZ