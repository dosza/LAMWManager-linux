#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2251700966"
MD5="828498abc5840a697102610a24eb9baf"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25672"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Wed Dec 29 01:19:20 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿd] ¼}•À1Dd]‡Á›PætİDõ#á‡MâRÄ²Ø	á·ìÀ˜{ïÜaƒ¼Ì!ˆ=6™È<?÷gä\ŸaÔìqGqü&ş¦kFÿ¤ ·íÙ$7½†V16ÕIÏğNºÉCs&ş)ÍwT¢n˜~T›9›Y1_Å’@)›¹­tYöÁ¢Jı3½Ÿ0X™ÈârOö;2æ^‰JˆòÌ¢Ã3û©ÄÃ³¡1PˆÄâĞ‹Á«Z†"9\û*iÀ¡Œ‚êx–/x+çT3—÷Ù1ã:=™¹:Ş Õ˜^’O^‘¯‰6ºXS/ÅxvÿÜÕÖÎ7pŠñáçÜY·(oÛt-ëÌ¢1ë:ÑT_ñ
÷ïRZIyá˜h˜?–wøwŸ¼ùèâ‹ZĞš¡Ò÷î1w‚ÿf¤ ±T²‰íóğõÚ9Î"âåq6aÊC…œ„¥ €tR±/¤'áıå„W@,éó&½˜QC“Û!¨5œûQÂØW'Õ÷±cøe`rCé9cŠn=ãƒ¼kÑl’İ¾¤¯ğŸOÆæ‹İ;SEàL<'<Jê9ûeØHñ¹ğÄ5øùI Sc-5É4ÒÔÇÿÔ“=„x\gX¡IM©ùS¥­P^“…ÖıúU²§
¿:~ve~änŞ€ÊÈ–cz‹ß£ˆ^Ovx—ª´é²~aœşw¦˜¸—EN)#ù5*’ğ²ä—‡v­'n™ nTH•–Cqf¦z°¾“¦Eª#‡öGä–1û3Âç$a€Ç²wüª)ˆn~š~Ô€©Æmb€ÏGÄÉ9Rç•Ê&ÄkÑexù`9^FÌ†±^Â;ÊÍfbÍEáƒTÅØÿşcƒZ
gRÂ¢¿…¿åò|ò_€xfj9J°Ş¿$‹Rğ†¸¨’/Šúyºã÷)}Òí¶°uˆLN.îy?'«w84y ÿÕhoGs#|4­ÂvºÇpcÕ³un.òßÉºõw_à\$†¸©&[¿Âo1;ëÂ`šù¤:Õ—B°Ò²ój~Ñ@/Á¬‹=ÀÇR¦§´IÔhw–ÈKÓ°ìƒÈw{r\>:t×³·P2'ú/s4GT;Ö5ÇÜtĞz$Ÿ¢jŸñÁèĞTÚ¬È‚ë5\kÍKÍ>PÍGüÒHKUßÑî›:œ‰étA_ò€FÑ0‹mÏÿ}Ã²·.f0úpJä_¤Ï2öw`›C®FtvXäÖBj­¥T»Ç6!˜
ëË¾E#Ñv§Î3^Äênz«ïz.Ò½$Ëåöô~˜Ã¼]}“£ÛY¦¬YÍ=–­1h«Bzh†Ò¸@ğ0êÿàÁSHX*ã©“)>$¸¸¦¹Õ™×ÕfSõë:‹W)Gx‘9õ°¤¦â#5ùV ¯éí¹å!éù-$‚XsökK!òwÚøÒæTQWwÉzOíô4Ûq€ë&ïÍhª_¨Â‡7é±Ë·Ú’ê*Cb]<ÜO}î&}r6t¯f×%âMæ#0çu`$¯è®û„¿Î5…À±ùNZ¢8ì‹õ ø/"º¬-ZÔïys²i”øàÉaX1S¢Ìxøâ#•^$İëå*XùËĞ‘¾ñi¼oSÛéœ”¯š	´†º•ï¹W¦Óú*hYÔİÖñäÚs­B8´ªJ¸sqtİ9µˆKØ‰g$L-Ëï…¤€ï4/Ûg»{Nàã‡êñ!kı»¥œÌ—'ÏYÀùAõ¾(!Œ]S´ÙuÀ|<ùÃ‚BÌéñB©îÇe`ÆÖ!÷¶â¥„ÍÛ‡j|¾çÛeà£†HO*Úê<¿wå_'ùÄ
Õ¸ÕNYcj¢ìúY²®gg&ø# ±(º0#÷ô$¼~[nÇ˜L%¤­›•>ók[ÆñG´œA1Q4Ëƒ’)XÕi(?4×êr°•ï4=ªÄ2w©!¤Ÿ@,¼s“.Õ3Ú+]ï²qoBø|Hx{4Xµ¦;vñÁ’]Á|}Î°óÅ¥2üÅ½+>Ç/!kuzR'?±Ï÷ùˆ{¨Ï›zÀpÅ	ŠŸIÁÈI4Ÿ"ÅÄ}ÈÌn®ğäÒŸ/»JcÜÚ=ÔdFŠ©Š^~<Œ¡Ğƒ»ßf‰`ŞY¡LÓÓsØF­Föif¨úëö]4™$H±¥teŠÂ
:åº÷MXÅ0X»L:¦±dĞ)ñ‰q’+›´¦¼éÆ2ß)Ê‚».'áîÃq¶ĞH°ãmŸ)Wëù—¤¯f´u{Ùœ€…‚ì-[y:»âÀ~O3‘4u\aÄÀù“ªgDÂÙh×
Ú‹A,€=XWşO
¥»Âèt`µÆ?‰`±Î>I(î¡ç(*EHï³»3µı-«V}¸®ª¹¶+àç“²…]Ÿ^ÏÑsNåîÖ+«Q¦Ñ¼tÄmnqZùní ˆwåkÁ’»ªâZ’]ë°Og·È!rê‹Ò– êP%×AŠôaY»îğ Ò§L‘Ã£4RÂ>ìıH(u§euï0Œ-G"÷å±Àì¾eõE¨YpòÕoÁüM;™æ’u÷}	q#Ğ´oš¾(CXvÌ® 	 &œŒU/£:¯*‚0¤#rÊw÷<K¹íË!ƒ}Ô·İ"A!åºs6*@µßc«otíIdKßª¹hÆn¥”]{%´¤#õ±g	şğ‹'Yü»ŒîwÚ<û(”†èç?Ï ­H¤Öˆ,‚´¶Rïe [o¢» »²Xÿ8RåÙÅ@£˜)D¢™šHJÔ‘]Ôlç/60µ/´¾èÁÜé{rÂ¦§ı¯ÿû¥
¼5Óp;N:e×ü¯VvõQÉĞË#é<¸t»WmÈ;˜„¥ŠšL‘0“‰dV¦/²¸ı’„u6pWSÕZÑá¦UĞÇA÷E\rSşnI./÷3¢“ã—b‰¼*xK}A¹Ÿù\>ı%Täºn&‰ôÁÈ~ëë_OÂ£
cSšsX6Emm·²ø0|Š`Ào›ó1ÇöâBFAI)Z³š¶¨õ.§ÁÆëê‘ôd×™Ç¨ñA²î Ô}m4}·MëÈôÛ¤ór¥n²ïµ_‘SB`ˆm=•”¨2_D¬0E7EeƒXxµL¸ÙyÈh‡÷ø©Œ¸`š®Ôºôz™Y·.‚kÑ …POÒh4–ÁG5½‹æ¸ŠõğNÍ4üéS“¹m46=˜G£jbÚç0ËÙgƒ¤œµË/Xç”Òµœuø;P¬­òxtW±/àù0C ğ DæM¶[Ï.ax.å"Ÿ–Y9ŞQ	hT4¥Ë†R»e“’´]7¬öm÷R3)0?o*~[Nîuœ¹Æ¡<‘Xä‹éÙiÏ¡ì ”Ë¶Ädgwu+1ãA,ÓjTšSÕ¥«v	•#„osH¡uc¶
=0ÑY@ò~sá¡y U„‘Kfß+TXsö‰x2	xg_:Ô
s5îå#ŒÎ³ÚôX]M3Ik	UYˆ,W)†£|¼–•
|‘KÓEÂİ¸$«·&6¸×š8ÊÇ¨@?Hq{ñxFPFCËjÓÒÀP¡Àè¯>|ëÙ2tVkÖMÖt…„"¤WXNC74Æ®H)¢ ¸ö7ê!Ò‹¡r‚yÂ“m¾o$8…Çsr¬†´æõ71x¯l]íN2¦æoJ¯Òl°ÿ´¢öçZmw.AàR	pƒ>ßU&øŸÜ`Wï20FÎòMf	İ;µN”€½txøüœ1p‹@³m+·§»x©õ’Ù}÷éØ<û£m{Ã&hkW8	oSºÍî5Ù‘nÖ˜6/ĞêÕËÿC	‘ˆ2Ó¶\±ïkz6V©-eÎÜà¶IO®‹:,Õ Ÿ„S£ÉPµœ^¨ğqş d*ö¹:tg^œ+^—E!æxÅRÔ²KcÇ®Q¬L›ëÄHÑ/l–¦"âõ]ÂAB…ƒê]èÏFJœKhÍHh\ñtÖàŠDË÷ ÒY¤æÌ†pú³VåãN:Ë³ù*M3İÑ§ˆ¼|A!¨’@aï-1ı[ë\ˆ?Š¡„+[GfT6”?‹BB5	ß–.OÙì‘©™ÖÃèp
Õ¢^í6{°?Dğz ä×‡¨é·Ú©ÏPÿ[ì(Ûxéƒ.K?ÿ¥òC 
È^PtRËÿ*\Ï½êı›§‚ÅP6Äî*š&$:±{b/RŠEã±‰ëÇÉq‡²ÜLiœuÎS)‰£ÄZƒ8ìJôĞ+Ë‹p YŞkL··Ú¹‡Ú¯òoôÒ¤p™	o²†{d2¿ êÊt’d¥ÁwI	¾kíßâ`å4›´1W¹Lf•ã®*ûĞÜ·”^D<“°?cÇŒ5 HƒÉ‰~8÷ğIZi5ÊrŠdÂ‘g”‘6º<VÕ|éÌwCÅ¸+ÉúÊ)6Ãğr &*ëiùdCaì½Ğ~YÉŒ·ñ‹;»ÿÆ.ç«e'‘'Všä:-IR/ 4g=8qÛ:uÜ.]‰€XRÚ£º“
Y§Õ8¤Í×í	}‰w.-.h³Ê4¤*Å„H¬’6ƒ…³‚•7“˜be“ó´_©É-ÏO–OÓóWY/¥TJpftPíHy )Â08?ªXğLÏVÅFY©®$Íû€¥°áP€+¡ú˜«ê‰·ñ'Ùc¯H¨Š„8Š»Üwtaäãÿr+#áölS’28zÆFE^Ş)'86jE¦‡b»ydÛöÛLØñ­EábF Š®#ã˜òØtá…2|oœ‹Ğ±«z·PF»ŒÉŒõ@şy÷O\›U¾–×umvsÆÅšŸ}·5yï,1•©ña5ÇTFkâŒĞFæÏj¹6ôTr±1n”Ü¦½ùşl#Zrà‡Œ¥³Ëú|Å#ow¡2Š\Ú`èu·Ô‹=sÃ2öjÍü»n¯JWïùy8µ@§ä˜°Éh(·ú=8\wªWßY¡H$'¯º˜HnQZ+¿yÁš:-ú8…•e}BÅ2ü drâgL…%:¤—ìøó¾.ÊÚù}›ƒ–÷áºzá6«ûŸÏsøpÎ¥¼~ÄQÿÛ×ˆÃu÷g<œ„¨c¯ÜßGfäx†v:kjğ3r®äíÊÅ}HršÌD¾@7ñ°Ë\ˆËF<ñ^ä§2Às')6ğ&ÿ„²:Œë·Má4ºMI½Äƒ1Ì¶,W7^Z¥ Û#¦têq³`ĞC=íG7d9H§[ı¡ÚÌ¦ÈP‡yõÛëwÙ¨¥\¡ßv‡¢ı>^(¤ı}õ‚ù\T<c·™Jå~w=¿¢NİáÈ3€óÁdwÁ"H½÷ÒUË yeßT ÃY ­¯8ÿÓó°ÜG~&šÜõ/E‹Qh¹fÅùG‡qÈHUÇ±÷Í´ƒ:›’Hm{kLHlPuÇõƒë®±^ğ1aVEq†µ‘k5dv®Eò3´ÙHb_ÇÃ7æÄ—H3YÈ]¢d8±5iºÙ ZCZKÄxI_œaõ¿ok±Êœ¬iŞÆ¯ÑzÛhtÄÊW#ËY3{QH¯F×ÍcNûú£ÿ¡ˆÂÏí†’d¢ıªÓ£Ğ¿£]ñ\ÔĞƒ=zÁNÌ‘‹q%“)P—¬Ã4­TŒÕK#‹´±aÿı‰õÊƒiËACì	'=ƒïQâºÄËÏ6Sˆ¼9ñ+F(7`•]·Ÿ¬³Ÿ¢õ›>†Ïšıƒğl×ü{fH#+ûUßğ°Û¿ÇÑ¸“¨şíkÓ9r@	!Ökò:Ï¨Îøed4‰{ÄÙö‡+úŸcÏ³~(ÎÂ¡Q¿m´¾Ü1„–ªßı¨­ ï^Nªì>h-„äeÉÅX¶É;¸\sÃ¢eYÇL¹œ6&eºÍXÕŒÛŸ³ìP0Œ¶£n‚áÉ*Ü¶CØôúBj‹RÆøqÎî©Ê:5ŸJ”òœ±6×dù*Öz¤^[ÿA¹É¢®uæ¤Ee~-‡Ê}i†]‘2#ô3]Ñ(3#îséª}”R$@Ôj/:‚®Æ«U,+n©÷éäãÂeB¡•ºì¾Û®Cõ½;H10‰vœ˜ğïüüÚaVì7)­ã˜Øšt¾EÂìıVü@Û´ í HıÈuì/±SÜ¿^h6‹Q¾ ÉÅ…z3ŒÌrÀ ÷%õQ¬Çpò¸‡û1¸)zã|Ü›Ù£µ#ı’cÎYÕ”sÅÓcÇÈ	®ª.?Êîd^ÔúÕ–¤)¿ô³kP{f?­mèYQâÇk+ÿÈ}ŠÕÏaí×oBö4l§l—[ıø’AbØVµhÅı¬`¬…<À	ºÑôvi\ÇwÈ•Â5]	8ı“Š]°Óio“k›RD6“Ó¹5ø ¶ •ø0¨	Û¤Œ‘ƒ„Ïló#Æ‘zç—öçÿ7!
ø’ôq—K¥0:Jš!sˆçF4,š]uãÙ‡7¥µŸÏ= É²Áİùå0K‘ó8ß<½³4öìôË½ÌTçFM5À‹
±©ëŸôáb"ú”·&ß7_ÒÎ¡œxmãè– Ğ˜.V…€?áwKQÜQeoî³Äê=`Cè¦¡Ê´©š4Q4VÆbeÚîêšğ<Éß¶}KHÎÀ¨ÊY ¢ÅTûª“_C@ëıİ"bşs@}-$  È4	=¥˜™HSÏÈ#¼Ótm0;0ÃÉÃXn¿Úìqq@K 6H”³òßûóºZ§{@Ú‚Ãª¥	<kª+nHuˆC5†³õ8.öÚÊ©¤"ÃÕRT÷Z4,' -ã)ìbú¸V	¡sÉ(_•D]7Öæè®3SÔõÑH2BĞ™[ÄôŞ2ÃyÎ¸›Ü,D$µÕ’ÚµÃæüüş¼'›¤Ğe¦ÇºÜÔK(U‰›”Gúã‚{„`Y“?ƒË÷†1şYW‡ƒóÄÖè‚%_,ĞåÖ98Nşbòsñİö,ìÃvŸŠœ0Ï3İRÁÄ`ĞˆÓep{|bF5p˜Ø%…è{ ‘é|2±Oˆ‘=Rwj?
#dŠß1×ß$¯—Oû>Wq¹|°5““l'—J¶Í}Îƒc,,LKÅİ¼p«iW::İ8³h¿ş‡QÔ¡ˆ§Oq¥óÍıÉÈéÚÔSèEäZÇ¥Wı­x1ö©sš§Êënä—Æjc>Ş’Z7Ná”Hjm [‚ ¦ø‰0sÛA d=zÀóçÀ˜yySbÍnøùXÉø^/±ÔpiwÙRËôÓm€ÜÓ¾ÃZ©ª ‰p±D)9>màkaî(jHP7½!U¦è¿‡Ğ-’Qgÿ„ò×t%§£ı<Mğ´Ú¾Õíÿ¤f©LğşZ¹ä ñ¸PùôâÜL3áB;£;%öÕ£Ôu	k°pâsgäômµŞÊ‡Ü!O¨bmHói¡T¨Ÿ˜ç¨ÍÎÚWàhøõèë…y­¶üÏS–ïv8ÂU3ŒÒi+yÕœÒUj&€£†ïFña®NF$›b`uÔ²ªM@Ô±F&÷§\a h{Ğ¡êl9Ğ¥ññÈŠæ¤Å×˜jÍçÆ(¡Yıá+jC‰e¾ëT=°Ñ­‰‘+;ï—Äv…^œ¹ÊÅÛPDk~pÄ]C8–ØAÖÔ ;Öÿ§EÁ~ù¡°¶zÕ™á÷´ÙušT³.SàeO7aM‚÷¦iA²U ²£%ı Ëíé3äKóq”[¦˜0³÷»¯lÀ´º¼Ê¡Ô·Ÿ$£8·c°”X–…Êò‚åÛÉøí_øÓé%Ä²•¡ +®³é#!ãÕh¸±•4SÑg’‹nñÁ|Ü’6õ'8WÏ58u}5hIF‘"ÀA`öš¤(Ö‹9?@9¼Oÿ@q'çkñ7‰Á·`ò_ñÛd|¦@Õ6M;›ÉÎPwp²·AÄNØÅëbß¿!tÏ9³ˆ­ '¾Ş¼~|µ5´ùŠ€(Šò¹z–é–ø°^«Gg´?(6Á¸£n‰ÿ0ÏÄb‹©Ôùdáx‹mt±­yhòï†›O¥,í±BÊA’mPq®{—(HqC{]@°0 “öØ„,îV¥ò"UK2)=¦‹–wˆËŸ’+¯5„ëóo4›ËuRÀFNØ„jmèd!—ôëHÄ"pÂ+ ƒ=[½#Ëì?Iõæ,F]rjK#²…©&ˆH-h;Ùó¾EC©­"
¤i34oÍIÈç`†S÷éZÀÉİ]ä|	<	<J=~_¶f«ŸQØ6µsÚE_IsŞŞX;WV\·EH¤'ækˆ„¨Œ¦8V xÛq©PÓ¼²ù–‡»éJKLAm²èP×÷’–ÅBeM\›îÙ§»«Q…USŒ¾yW‹Ì—ÿ7ë
f‰Gûe.H¦Í ÉÁ¥†
&<Ôœ²7J4å9F!îã!§:V©Å1Ğàª©5Åò‰ãU#º‰6$VDõêäÊFÂ Ÿå°ŸïÁÜåG¤a0;P°Ä„ÎVTR<aÆzW«•ëŠ¦ àMËO¥{÷3Nú÷>áÛÄå(ğÃ¬ŞªV¿ˆTŞÊÇÄıƒN&2yûØ˜&<‚ö6rÔÜ”ôˆ~hwhÿdDŞ1ÏÂ/IU)û×;Œ²šP§ÿë™”VÙc„÷ïu¿Ä³Dèá@Ÿ’İÁ§EwàWvYêZ06&jÜqú0$ñø7k@M«†÷ç(@6ègWWr‡·œQÅ%ÎmU%œù}’©“G¡’#°Úøöh¬çékÛ‡ÜºÊè&·
ÉûµPe}î5xêµ®XC¿ŞE®
šÚùf@$PÇ	Š·¡¯¨2¹I8‡ŠÀxEHÕãƒ®q‰G¬¥ŞPä1D|·nfxºx_ –Ï ×ÜBbõQÏì›Ğ ˆ£åÈşHíÈô":06QlÑˆŞĞûE”¡šŞŠ`)îŸ>åÂ-Å`§…½'2‘Z&ˆ/òn©‚ïl‰ª…ÛÉÌ·EÚÉ½­½·Ğxsàÿ»GgÓm İ‘vºëD…<*?ñÜÔ¦Íº­L`nãÎG_"áıROC¬şı$–JñÑ¤H´`Ğ0÷ôÉÌTŸ(¹ûGh[k}ŞT^wˆ ­LÊ¤(Pçwhø‹Àğ˜Ÿİe^šÃ–Èb1Ş‡ØÚwş—ˆ Ó[­˜#^“<Pº\({v4^•ÑïŸ6=I.Ç™©øp›à©Šãäs–ä•Ÿ†ds[I{±Ê›‰›šGåŞÕXJ,ÏX§íty@P=."ï¬O:`ÂçLCÔl½RNL““Ø0ì–Ã ĞğØ(ëZhş¸WüK&LÅóV…Kí2íäl%e‰ñ-ÜhÃXy\™¤¼Î9}L$XßßğÃ_V ökÖ7½QT«fX¢­B}B`8¹D¬}‹S2NzE“3=ÔÆõ¡½TL$Un¶è¬ÄíóNú!¡Ó%}ş)8›Ó‘§Á‰»¡¶µÎ1†
ÌQdG3&ª"‚…ù›Mª¬tv{IF|µõJü¥´›õÆV3dIÄOK†Ó´>ÚW9Şød¤øÌjjr©*ó¨'z‹’×R*¥xx†ÿÁ îJ—3…ü”0§Æ'gd–ûe"DkÎÀ&†ë3‡™[ÒFÊ4í¯)â>ùDF:}Kóòöpt`ŒnšËœÛĞxL„ŞAÅ‘+‚[Œ>
ã_l³Ì²& VvU«Õ§Ä¿'dæm/(áÁÅÔVø×TÄ]©şä~—
ÙÛÑ“>:ñäÎ|eÆ5İãfrEnI¬ÖU¹><<BiŞ'›¸ˆ»B‹Z SDQ´w»ıC°'nÊœ7ÁZÒ;ïŒŠ’÷¬±j›î$4†n•Ì+¹š/›İã¶ö©Pgâ>024y÷ãIõy'	åİap;~øäP™\œZ`A±~)¾XægRÎ•§zºÂ#7°ûóXÿŒÃh]=¡q¼šX’é~ğ’i£±ìÚAqèÅ¢R5¯®Ÿ’ÂÕ¶Y²ÇîúŒíufuoë˜šç"Fbá6a‚AËØl*hxÁpß:K~‰Aí¢Í´38~]+û›HÖbÄyhoé‰m1åÂ':ôÖ¸P<šßtÂ'2Xeçxëáƒ{•E|ÌG*…9:zÕhä¸£ÏnÊ~œ(‘®I*ºG:Ø”?m8´³¼Mô'Ã %É8»4Obl£i`
ĞÒ;£Ùe¶"y³Vi¶€ì‰ı€.Rá¼§-ñxµ(Â;T^)€*óA¹ÕŸË\"¦˜µZ³«mcjÓ‡“]^¯™EáŞÿ=?Q‹sÒu¸nô C¾ÛæñF÷P	".Áhsù|ò­(è·–«Šäï§wÒ‚ãc*4tğo¶17(ÂI-æ S–s_}ÔİòÆ‰œ„i\|$Âİr‹°<»»¦…U…9e¬û+õM=-i·Ÿ CX£×´«p¼ô—# ô;ïeƒÆÖà<n]Wæø»É,ôò+Wô Kğ©g%±˜M}À(\ˆ¥§“ô‘Úi]Òö™I“÷ÍÄà´˜Ùe $¢™Øôû[d3ƒÕDmr²+›ùÑÌ²?‚É§DÓr‚È<ø(¾wŸqnã*Ü]äìG µzázÏÑ÷‹Ë7ë+×¨ Áfèâ¹] Èï­Ñëe•¤¾å¯¡oVÚ–¥ì
mÍ-˜ItÒ½ngÎ
.²srGŞ¶Ìä@²ÄBq¯tW¡nŒí«æÛÅùZ}ÓİÆÍ¢7Óá®SğGÃÍË•|È'§ŸÅ™uH‹pT…%±=Ú¹6hŒ×½Ö-¦—:Ú›4î<Q-¿L]¥˜2…L¸jà
Ë…JĞz¡ø¬‰¤<˜Å’îE€Ì˜½“!¨Ó®¯+%ä»ş·¯ı@ ¢ØƒzMW<&âß½Gx˜(éL«)¼3cÇÚx	´ãmrëÚë8³i2­1û©¾2œè]­#˜2	§°t#ç‹L_t3¬¹6‘pĞÎ§Ñ¡}9˜²µ ¸Ó¶%'·:ıÜÄÏ	°õæğµ‹ÛäÜ8ó
	Êw¦Xí-æ?VèıïúQüdÉy•£4%<	]-m˜Êc”Ê‹`ÄÁnK–NªeÌñíaF‘İ7J	úDd&õˆ"kµ|œÛì‘ÎõVpOš€öH2–#Û`OÎœ®Ñô¼f`°foyÀ{cqcZ.ëÑP|^/\]°ÚÇ	‘r€çŸBSÓº>ÿÊás¥˜P}6ò›c¨‚%ËOB}n}1 {¿Eõ q~Ù^ôkík&IĞLCCHgƒ­lkugI-ßhT,¤°{í·a7-ä˜O·ÃÕûÎF$^^¼“/ì¬e]üF4Š#iˆŸ÷Ü"6P›·"]õâÎ…7úè%ËÏ× ¿£Ê²(>‹%‡Âj™ÏfØŠ‹gVÍ»[6²`Ç`B[%ê2­à\{K9ñs¹  Ü¦ow{Ÿyøg«=3ºz7Üö¾&¹'ƒ¯h‚6÷#úRoLEà>ÊGe±ÒÑûLGãÿÊm™§?À2ÊsÿÜ“ĞóÁ³Õ
x÷ŠÌ""'Vó^¹&seP.3ş=ò¸UŠÓîa„¥Šà aŠšøî{œxÍøÊ¹'“ıññãÛ¤9‘TJcPi¥xrú¶ó$Æ¥p´’vœ…ƒÎ€1Ê™6ĞEkš»Ôy„ PfQ¢kyhnçHCìzÚœ$÷±@Î©ØĞ&­+¼ğ.¾eÃU%¹Ï±,™-xkNX¦×WW‡š{Ò>¿mş-—­`¬Ÿé‹ÿy!#Ç+ØH±$½`>6!~3L¿vt¿/“ç3+èî‹l]«®¼¼g¡Ér ìÎ…e,²Ö‰Äå5²Ü7öÜ0¼<)"®¶ıïxØK3„dµğ¸s§üqÈ Æµ_³YøÔî‘nˆ>j)Vqˆˆ’nhöRóH©ıx„†®ö¾Öİvb¨æFS2¡ÿ‡­z¹§/üd™-šJÿd=nj(´æ§”¬à‚òóÿ¯LSÔ!ù9kj…´M‘hèxğëHòæßÜæ9®y…r]Qu`Étõ@À¢Òùªñ¬ÚBmLˆE•õ€X°ÆP%$UmÙ¨~`Y¯cÀnM÷^­»º\%<Âó~ZENXÎØêV
	¬ôÜT6ø:¾h€ß®Û0~Ÿ+‰ñjMeK¡eµ­lÕ‘/yšš»u€1ğ¹Ï÷_«íZzŸÀ;˜J8èŠ:$PR Íá{¶ŞÏ½(–”AíÅe›lbÈª…äKùvOÚåI‘/{Ëzn}×¬‹øgí¶’d{›Ë‚‘O8~p>ÙÄk"[“$=)¤†ÑH[¥ÙVİ¨,K»qMm>œè#¿&ÿ·§ÍJÛÛh¹{vgÎfy±’ºpjkH¼ _A4,]Fp°òÿ¿B´5îHq÷¢a)Le¡ê¤ŸE¡ƒ‚…>’HÄ®ğıDİŒ/6ÑÌ’
Şø<«ûßË?"ÛÌÚéqNÙ3à¤yÛ­[ÕkîİH;úQû>^“÷Êksñó¼”.TfŒ•	@`éluÓíÆôm€4¥(wßl[Ü™ôH-hAW)ø]¾€jZJõy<¡Ó.îÎŸ‘˜±¥ñ5Uæ¿ïÙ'ğ0’\ôÛ³Ğu£-IZpxÖ}~W¾I&¸ ‚GÔzvQ1gşèµíÿFKÏÌy~—îŒî
,qW•}»sıêÿå˜i»÷ıB7ò|>DãP‘!·Ÿ~RFspìÉYJ¢_ésé–’ÙÀ«XøÆy@i_íÈK³é¡M`¤¤‡»c>£¹{Ú‹qİ~ãNÃ–a"ïq¯“1Ì‹òĞÇÍÌû]Šä)€z°a8Ñv<%ñÓÃûı¦UŒ•»ôF\:)ıˆàšÅ`= ì^£QƒÉµı>·RsS·•İÛƒW $°o^WÌÚ2]Ê©.~O‰ÂÙl…¨õH 
¬BfÁ¶sœV^2…ÔS™–òS Õ?èSŒ¾›@2ÕñÚ1€3úkGLØ'\ŞDÖ×’éÛî»Sï,ÙWO‰ĞyĞwƒ1šÁ$N"¯v•L}\eSNµ¸¥åZ]‡à{7V)I&îi™_Ã6ƒÛR#5~’ôöÔUV-°c°Õİ}˜£cØĞYÄJ¤ÛS8V©;§Åz…d¡<…`şP–˜¿	Û Ùcf‹fce6÷GBB…z%O«À®×*a³Ê–L…|›Ç\{™ï8íy›ğ, Ël¼ åÒwß­¯šœüú=à…*K•yI§Ìˆ©…«Şıß˜”Ÿ Õáğp}~!ÙÈH=Œà„}Òê^g`’0ï w~Ğ(Oá—fn†ü;%ÇåÓ—â=5m%'ØúÚ#£±ß¦“İò’”Å\3C¢¼¾íà…¬É!†éGï3`óOnÛçØË­a9½¼{6`åìòë#ƒ‘M<(ß7($¨•£?ßå²z‘FPn!õr§2Ó™*®6¥´Ä2oÑ¸Œ¨·aŸ‘€£3¶EÃ…İ’L¹h«ME¿†nše~¥F>¡×¨Ÿ
Qœ>b°ç$ş-§Ë’7ŸP,¬ú†	síıRõQ×%?áÌö(há•8bR'˜÷¼ƒZS©Çä|—!çé5GdMN é;@We¥œÃó‹0ĞhÆy}?>÷ÉÅ#«è«^ğ8EİXKğÉ«èò%è¹	wuPcã€ğ,)bú&	?Ä†%"
Ù½†ÇAâœˆõoš]”æE PÂ‡¦»cQÏOèÓåeZö4e5áíàK—ùQ`®$¨\”qÑW­ãNrgï¹PáÃÓèu<ºÙZ~€c0Q<'"(2ºà%uæ­mÎÎÜ—|9²¹'eA°ªğR¯6ŒñHØ­RPÃkß#d3!ÑÑ.¯À¢àEÛkÍ}±Ê&	ÜŞU „+k‘O¶	Ş²seşrÒâ&Œ!¡FäŞFKËG†%Êg¶ïgêwÚkĞ!CÒĞcJ˜…Èå[€ù× ıù•Ö!¨õÓ×4'Ì³Q˜NZ®fÑLÄRÇåjë	hæ1·…'²?Ô¨	@ÅğğMjGSN•ãlÈ½şz:šœ>?BÓ9Åöäër¾í£Ü©ˆ‘x˜¼\û4Ír ":Ş¸¦£‰X*×Ú®Ó÷ŞÖ ‡a3\ü1èVîå®PöŸÜ¿Ã<¼<ö¥{\M¼VÕ’i;ëU‡óäÚf[¹U˜_$âÿöË®¢YğÕ Öj&Ëóq•î’^'¯‘+SBŠû]Ü@éâ#¸Rä¨K¬­ÿhìşmê2#©ûWÌ—¡ÜÌ'Tüû¢]É¨Nö,Ñgü~%Ã'A“.ĞŒ­o1Ş-ÎìÆŠE¤.‹Ê´aŞ¯ôe¿µlg.ÇqVŞğÓÎïœU£‡©BKˆ>îX².2ğéBü,¼G†Éî¡dOœ6¤œ¬×‡x-¯a9DdïºéwRõ†=ñ›f[Z¶ÚêXí_c£Å–Æw[Üğ“çl÷.v·uÊÕøíÆiÇíDô0âbråáFïãÔ™C´ÄãÏ|¥×Çê¾NÎz–´årŠÍ_I‰ùş×
ØÊ}¨˜du>Qëµ¦ş-BDÓÂ9=¹İZá×·s³`1mÿÍä±´MnV'ókWÆWÂG,ˆ§¤ÛŒ™ş÷şO-tÜÃP¾£M[ìÙ÷0ÿåTĞQÜ|y	z1˜+Ççs)¤ENCõ±kÄ†ªgW‹İ“|R™ &ô=€XŒ¹Ôí3h6€Ã	Êëh{ÌÓC½¨_±\ƒíU"ñ³”»ş:ñxUFkµ[iw¯Ï~D½À¯,…Îe?/ŸóòPĞ}é‰URÉmšrcÒ}æ‚Û‰iqî¡È!y¬cí›Z*“K\Ÿ ×ÔW5c¶±ù
ã—h{2]¾`ÂXKé‹¡ª01PG ²˜#t^ıáö.Á÷ª"ªä6)!#(ÛvtîŠti¥uÔ6ğö’¬¡û¯ûi¨¥k­_Û±ĞB¢­3i:@„=’®8 ÃõÅ®¬ØGj‹Æ3äD»·¸—ãÕ;Â@!9`*D¤lE¬k%ñ]²_ìÄÇİD›"°á
ˆ;ü%`¦kVã^¢r'32ñ¡…=ÅÏ}6èıHÖBwª—ƒh=ØãåtïæJgª*F]Åpy#é‹–ÖL½è’`f&ç~+¿İ¬à´¡¨KJ»cXkÓæúRJ>wI4!Ğ½2Úáz§Ó›/‚iåXğ¬ğSÉñ30¿–ÆÄQ¿%¸zi_ rî›$h½y-ˆÑ­ÓlF”sİdW‘O*ds|ıŸûù~)şÑ°–ò÷š\–`Ë½J‹
àÓúäk‚—ZP"aÅš4„G&¶Ï†ÓÄ­r tº‹ã<ğ<Äîm¤¼ù qî.å(/'.•Ûñâ2r©ıãIW°L¦ËYNX{ë€…¹öôP]ã‡Müšh—ÜcÕ&*™yˆFyÉFàâÅ”0¶´òy22õè=;4ºM_ôFˆ¾I©pkğ-¿€¹ÆÌØ•…N¦–W/:@Ğ:‘ˆ[ÑÂ› úgdÅRèŞ~OÑùO[Hl±#£ƒƒúÑÊb°³8Yz9à`J(*@æNµ¯¸z¡^b]½v\SFİ¢ó m4sŞL6½£;Ò—Ò[½”Sxñcµ+àø«¹ 0@‡fH´m?ÀÑÛ*bğ¸~•À™«ÉX®…ßÓŞ×ÃããA5M+ogŠD,bÈŞ‘ã)¯jrƒ“ø‰!¹ÇÀí5;¥š6È"01¹Ëg¸)^
¹iÆ¨¹0`ø‰ˆKØÏÍ'¿süó÷qİMl5¡–#b¯Ñ‡^¢aüYH8%Ju‡AÑİ(Ã^Rröê7+ö|U¢TKä™³š"Lg¾“cè D¤RÍØ=ÄogÔ†‡â|jÀmÈğ·ôéÜ¿ñOêwÃ	¯vùœ¾·ÑhË®÷ Eñ˜b3×‘Â¥¼:BG+¬¨gçŒ¬úhJ¯x6ít£Š@ˆEßLÀ(Í><ê_.V”î•V>¥Ãâ ­ESÕXçFCÑÍ_aô€:€ı¶nÑÆ^ÃÂÎü¡<åÎF†[šRœRƒkš[—7¾H"sCH¿ã&l}ütIÏèöÜÌO'QS¨Öİ9`÷1‹9”‡\óøßĞ¨U>Eph–ñ»„q¤f¾7t ºí„×)³—2}¬ÆÕ8¢Ş0ç§ù¢ÙÊTşi¢óÿºx%(
|éDOöF·R&Ø`™ŒÂŞùÏb¦d™–û¾Éïñm•èrlˆH + µÚ•ü»¨ìÒ¡Ïàòy7Ìl+5íÊUÆÇ °Å¿à;æNİu¨Ø´\µf_ÓÌRVtÎèúÌ”_¸¶Úâ4“Œ5–Æ½&'§!–ó.ĞØsÌÛDøÀÅ¡²â=¶¶¥qVıÌık{–	ò¸ÎcgK‹r¨“âü³ƒ«ÙHr±Oæ‡Î1ƒWpJ¤:4ódt‡€ñCnz6„¬Ã®ÒÆ©!Î
,a—á7_¯íça.X^/¯,Tî+‡É£'ÂàWä¢„#¯˜Ñ¤Wì¸—è¨ÄK[Iù´—U¢è¹X&ıìƒ#2òHDBÓi\“\Ğ¶óöĞ²şj³2²³Aè»Q[]=rÂ…_Pnƒı4¢nì¯rŞÖ_Ä&ş¬=Å7»néÄùù†…æ#XcÒ¡¢¨ìr¿îQŸuñ¯û§ğ—×*ø”Ô5–›xé1>€	/úËµFí;5ŞÒy¨\Aœà…#Õ"æ}BIn¡Ôlø­+>g²ˆ\–A&öG§zsU˜R“
D,0…DïîK¥õ‚8Š(kO@y1#ú²¶Z¼,+ğ”4y­÷(âr°<Há¾Ô~,ÎÖ‰èFÃm]Û» F8J2+oã–1ˆÉœnu0¢è`Nˆ‹¡VOä¬âÈUw£Å]à ÿ:]¿&G{€@áÃµ¢5ÂÉ[¬d^3ŸVĞøUµ(cg…ÒŞÁx†XqQ„yÊ
V9pZçgW~$–á¼£Q8ÅèÿTÇpfHèãÜf}‰ÁS§™ÔÔöÖ±ˆçË*?¹ãi· ßÒ¶rFç‰n°Tí@à–åÆKÜQL‹HY8—Ö	±ëkPÓæ+æÑ¿“ı,ÛK™e„¨™W8¬ÛûD3_\£È9cÛ4&şá£…¹PĞ±ÅfºY´§æÚIaÉÎêìØL(Hu’„--j¹Ç¶’µ0lOhö@âÍòi«qHl;o(òî*É—£çÎ7E 	…h8ŒI<¤ìÉß~ˆ·wòÊ.¶¢Ö²§Osb^{@HéŸoF7ÆW‹`Éı+ÀÉ²
Û/`U7çFËÔ$é¬§”W!B´‘œo¹ŒÊ`BKü[jË
h<´7çœŞÂ¿ş%s~İCÑGg0Ïä +ï‡ùmGŒ(ôìÜ2Cûı¿_Ò°¾mSM“Ìuıh«urØ ²óÊùŞ•¶tCç::Â˜û(×íÌt'£—iW€¥ÑóÄ„î­Øëò)¥õS¯´Me@—§’Kİº·hšJ°»øÊôm$®{¬ã“·UÃÿoÁXònö²˜ÙBì¥¤d…˜ÿİoûÜÉŒ^Òêı=uOÊ*Db÷ôSäg´˜(ìÛaÒÒÓ
·î³Œ‡w³=¿àÖŞ.LêöŠSâ„Ù"°€›/ÁLİ ô›u|P4!4S7ûÍCVhE—T¶˜­ÉªÀÁëº°TÚˆñ+“V f,º®×:{¾ùã/ù­‘ïML½#",äB,æ	I=°ÖXŠ1ÈYèˆàdµ`+—^4M}cŸ-\Ãş­*Õ:t³ğö³¯ÙsCÓ5¸«{™Ö¼}µ‘4¬qŸlí¡AQ„>H¸¥ è›‡bìw¿éø!…öF´ö>D²rh×şéêÀÆî÷–
˜‚U¡‹Ù“è]5VŠp-ÂB(WóqJã
3¬<“iëxñIQr»ë{TfURŠ`fé,o-±‡I¤ÍÄ0a8ÍİyrÆ#@£" I[ÜèW¾7°”!äªC¯’w™B9ËßÓ± ¦Ù†Aı'‚ŒÔı8MƒÁİ±õÑ}2p´D•Cš¢sI;˜è>ÃXÀ[²¹)<ò²  "<ı„UÎUÏ?YpyÊ£wq}´p³5”SW´æ“uör›æ*+ã¡èiÉ+ªõ3Y,@ÈE—'êçïNï§ìú6·ÑšÀB£µª‰ˆò/aìª^œ8s!‡²C,G”PÊJç)˜Û’)¿Ä›éå|om¼Èåˆ~Û?$+*Dx9c°¢[7§‹*‘…™rdšç¹QŒÎ“7ÏO—¾§fºåşéƒğŞ1sàÒ*Øç
œSÕNà}YI*º¾ã–ì²`öpˆƒÚX[=ôB¬ƒFÓfˆ©âú@ĞPòÛIöòpü>öR­é¼¢Råo±9±à	•#•(Â;Ìğ‰Â$É¿c½:ß8²!G&má¯¸Üù»²qWQÿ;´IkQKDh«‘W¡ŠTÒqqê™0GÈeÑWQ¼G	A|Ï?î<XºàÈSI”\>;T^İ=r|ç;›&×™IÖ«óaåıî`u¡P«L.ığL›ìc)¦íÒ6>iClwíÆ{—Nk.ƒbè³fÙfD³#ãÎ¬*›¹M Û·¿¨—Nš ”“¤ÊM~7ì7çîNuíŞnŒğK´	½µDã¢¢0"¾ó’s‚mÔÜÒvVm;Q%Òe’¡
Í5e<² %Àè¢ñ&Ÿ\ƒÊºwİ«Ø+´Àùµ+=ŞçŠ¬’L­\‘ØÉ¤#T¶c¤%‹ê1ÆÜ”YsH«âj–UÑÇáW>ÊíA?u‘‘‡9fì=ÎS,¶Ípû™²ww”¢åjòÁ˜?¤…ÚêêØUšEá—£UmÄ¦ûû‚ùt™¬5$Ùü&âB¿@a?õeh“{u?òó?V½%¹ıV‚v‚Ü‡–©`ääa>£Oâ¼-İF·søƒUÊRi§µ+D¯õ	Â­®"ß!üßUæjkí6vz{èFÕ¬é~(öá˜ŠÎgZ:yÏ¥pwÿ­÷ÛK­-æ+œ&]Ø˜ Û?|TY&¢ ğà1#™ñŒ=ú„øt{\—’'¼v¯ÉóIØ.ø<™óA“7ğ¡ğ.Q€°¸oa7:^-^;Ğ”bËœ¢
©ÓbIry@Ğú“ÄÄ‡§3nşxwv¼jğ*!Wª7±Ó{r‚A“ŒôıÈ*ˆÃŒ=D˜Ä;g²èçË¼ÃVİÂAïãÒÜ§æÀõ'vqº=Ì	3x‘¾'L²ƒÈ8Ó&ÍÊ+®),“"v¨ëÆYş(7úmZ²šØOGŸĞ29M•E†¬Š['•ÍÁ@Ä' ù[–cXjVf1¼İh†Ä°CçlÃ‡*ûWŞ`ÁÏ4Ú³«e6õ?Š?ıHŒÜô=`–úğÇm§[º´FÑå 6`dhÍA÷chF‡=’Ÿ¯3:”köiI%Í±bâ8ãµ÷:y`Fğ†‚á@×\'×‚Šâ®=ÛB\QßåÃ7 ,È¾îÒÛŸ–héĞjø?œ*Ù0Èîwä•³Æ•7ü)MB`8ğOJŒüj6FüÅIÁš7r½¹V_t‰¨ŞVñÛH,²x¤*Ù¹|	1I¤Ç¤qÁC»^6Póé½K&@)\.Ø)z 0+Ó†òo—,®]&Rp:ûd Â9aÍÂÂVÁ:Ö- §Á¼ş¿“m?-ùßòxÔ•›;ù^Ó bû°Ñ&VyŠØœ×jëµTyê`Ú8•àåŒŞVÌKˆx=ßIJ‘ë"!@.6”~˜‡k[?H‹Ì½ßªu+M,×øåSPá¼&Œ²ÁÕ0$Î)ÓÁÃe èkÅòf˜ô
LÑÑç%u†B.X-é½yaí#Í«Ò„œò¯¾{mtó¨Çnèü¬²ã…Á‰à‹ø)î('_ìãá‘$¸Ú³S!¢
Øiz‡ÀÌnBï#pânœŞŒ9Fj¯Ñ—¯Ş®°Î+ö+õ+ ~™Ôî»YÚ%áBiˆ­­[ıôq€¸Ùk¿]½B©EêRöKAqš{\²eø,iŸƒÑ`Q‡11)F(HŞMÏMÌoämï4‚³SJUÓp–Õ½¬s°‰¸Uô[ç™ry­ïo%ÖkOóA×ä(K%üÈWÂ÷ÄšÅÚs<ÌA
İcƒ4A”²z[yŠ‡ÁiBC
%!È;´”Ë@êT[õÈ¬ƒÖ	µáƒÀd©Ş/é¡Ç×ïÒ†vjT:‚ _ßÃÊÛ©¯†á)9@QíJ‘]µªààö„Ê­:ÏE°£?Ê«G2Ş`[f¡zÚí™o¶	lU~&ñwí¢;é^Rà5
½é§Ì™¾U"LÚûEƒAŠA
à•É_2*Y’¼¼w6}™‡«x—o/?­Şû±[êHus”š"í°ıÀıŸØ–—G8øzzç¹î^Ó}¶"­ƒ2<ëE
”Íú!LÁ;1¤ÜıoÄ¯`•Æœî~*÷w1IÄGÌ ”ä5V£ìüA9A4aÿVú€ÙNl ï‹
~™€8ivÙtë¡4nˆ.j‡-ñ×Æù5n|ÛDÍ+Æ­o!À°>ùy–Õ
nZˆ" …áP€¥ïXë1…î%kˆvX—"|p¡ı2.¤C0Ïµ-m°/ÙñšÛŠ±çîÙxºQ†E©*=&îS0¿-p˜¥5”ëQ×';iÕZß,iºÈÏÏtí”ÉõŒ*Ë/s ˜×—4üÒ	ìPÚFÿšü¡¼;á/ƒR£\¾2JĞ%ßfp$GÙË7ÊJnKî©|üîÁ%q)ÔCƒßOb€Ë`Õı6ÎK‹„ÿWC]q›X‘nø´rŒéĞp1V@7­²OR ³’}*é&kLh4Èƒ t;ÆIÂL9?1”)–ïR7Âç(Nû¥«á¶¤S³80ztmÔÃ6E¡ÊÕi½Zj€Æ}ëPåğ¯ÕÓ"b-ëÔtä¨‹•*9˜‘vÜÁ,ˆµbÉó…Bj[qr™xËXB§D.pñ;£bâô
Oén)qsİ(D$(Ÿ‰êÚÎ{cïhŸÈ²Ÿ*Å+BG«Üß pÄ?ì$O¿%zç&KTÿ€-\,÷ÕUs‡KRIœà¡ôxéÆNQR‚ÎÒ¡$à vÌtŸ/¹>ÊL×ÄlŞŠí†˜øªÆÓ²ßë¥ÑXe¿$V”İ‰˜Jè“š4Êä÷=c5×†xóz*ØÅ¢[Àn1áİ|lös‚¦S¦Á÷]>k]NtÃC9é’}6¸] U’SĞåTjÀY6µĞ<ì4ƒ"F…›4Q_qN­—Çê>MhÀ×°'ìË†;iUß›S²ñZ^ÈNÖ
ftÄée/ìXšÑ;7’­¹:üi*ó˜iıbN$»GAn‚ÃáØ–• Õİœ¥àĞYó<~§Eé'É¤k”¿ø$¦ö½h
¾æïŠÊ“£ğ¼˜pLbÑ‡_û5d³­„™å›¶Bıöƒİß2Î58PtßFÍ"ğZÙœÍD¢ÉàËÒ_VÌBŞ!3D§0^ïD±¸©øûÀğ{´xÙ	7®·j¡ú†^H#ìÃx_{Â˜®Ê$ßÊ_ƒk-¡Ö,UÒòpQrV³…5êe{¸Ìmı+¤-’ÃgßÉœsÒø”Dß¤Ä¾É$bƒ¥°çwû*,Q’GYÀy‰ö#–õ¶æ	¼Û|ˆ] aBê¶&‡í©A-âé÷º‰Úy	0ÅïZàö×š$!°#K8v+g¥Ş9‹
¼ôùº¡‡â;÷×¤Œ^ZgÏ¦hfëj™Õä<ÙNærÎºãfrV-+Ç†*hóv¯Æ²&Çµ\Ã+Hß*ctå;S[uªÕñfB(á'^M÷ÚÜÔxôFÊ¦š2á/MI$ ñ‘o>3Î0¯°ú­†(~^xÀÎ Ë#İ5¨»€öYV‘›ö ÊÖ*¬è±\`Xaò‰twL^îº3—Ü‡T¸8&àrdßÍãfòúï<áƒ|°½˜!"<…*Ö¨Ñ…»Bƒß‹02q›ÕŒ °ßuØT~Aì&úRêHÈb=Y ~¨ºÅÒlÕ+°r nî-ÁVÉĞx4Şâ¡™«áHÙL'%¥ÈğTj >yõCÍ˜t"J»âáÌÚ@ğQLæ]ä°Ïd+oV°œëÈ¦*Â=µ>$Œğ$uPO°oQpáˆÏ=ëvÛÜUP·şŒH€¢˜ivå:/¼ßtF.é0|èö23Úİêîä–ÜÑ€ôE%@åıœ^ê².ul¹’¡5x×-0¢c¶^óé‡­å’]”Ìe•Éî":ñÔQ\+“WR&ˆ”plª†ı°ñ½›h"-Ü`¼Í/éie3°L$–Ù^XujºÙ éây´î"Oxo.óÅÏw'„’Ïİà’w!Ì_ïªuz4PÈo™ğ(ëú2²º`GRñ*sŒ.#Ğ6ó•³BZûÿú^Mú¸•Dmè–¼/Vc÷e™züSæ0‡KízM¯ÂµÇÑluM¡9âd~-qX6tacW¤ÚfØc!# 9Q÷)ğËáÛó‹EPG_¿ñ[yCˆ]¹»u1c~Ä>â>¡JXü=AGêÛïŠúò-£Ü—Ã"*ó-ÍĞVSIË—øÌ^±kQ\a.T‚â’¿É´I;dú3Wßjr~öE¶DU9ù†¨ê‹@®Vq‰V—|mˆ‹eÎV9uö¥èÏÊui	UĞÕŒ‚Ú='×Jµâ¥Zƒx¦ûéägíqÌ¥ëDêRE¿5ÃxX‚Ô÷JÿóØ#;rS:l°bòøÉ€;zĞJ{õÙÑ·Z?%ıp^©ŠoÕ
üÊEˆÿì‡††ñ®~$ãx¹ ,{[Vª±©¦«c] D AÂ‚2å“J>óÿ/ì,ùïsBt¢D3ug›Öp ’½ÖÖVñ%÷I¼ÚG°¨E÷¶‡ö·Öa¡ğ±ÉÍƒ—Ö´™iz¦•»´ºÊ8¶q°°˜Ñ¢Í‰ÚÂ|ãîŸ*ü´Õ¢êÌA)¶•¼’ÛôWj5lëäÓa»™ÌMOÛ~UiìŒY"Õçß²66‚ˆ‡şÔÂw~±*õ¨’Ü{Ì@ãÎ|#	8nAç”ˆƒ¼ÈKûÆ{Şì‹şÉcJ/Àìm¸NV}Ér3¶FU^4C(%-@EñH»J?ëªjÿñ$5¸i2¡9<ƒ« iñÏê!}¥7Ò‹Ïd«*İá\·Ï¿êÎ·Ì¡H‰Ïä5ª·‡¡BÀ³Ó³Ø7ËÃ{RÍ•µ®ÆJ°ˆ±(S¯`ø+óÎ
®.Å$°çÃ.G§¾şëÍşfÉZa\OÖ¯ïm]Vî¬95Xó‰¨ú²Ñ¥‹7®S ë™ÆÑê‘ñ¶Söõ`ºR¸dÃ÷©Ñ’®6è*øÏåàË¬Ïø',™¨g€9ëæ4Ãº‰Û›	GâÚff™¦„3^Àš*°âİÕşÃ…Avç‰ûÏ¨µ&\š÷“á4–Ï*xfB©é÷ÚîÄaÂ
à¾Ğe*ıËõS¸[cÚ÷ğÎäåÄ±u9hcùƒà³grV ‰Ğíö²Á|=§1£÷'_È¶Å®¾2‰L÷ìÓôeDU÷Dè=şµÄËıãğîoÙñë>W?y°SV#'Ïõ¦Ëö.Gë7”QNøkLµL>JÄµĞE+ø6ş`'fé¶Eı[V3kµ|) óÕ×´ Õ{èï]p `Y@Dç…2;G"˜Z§¬Õ_¦ÎÑC­l¡7åJeã>„
Æ+Šæì:l+Ï³nÃ©Š^Í.¬—ƒJÇßa•†*6;/‹9Øœª!Öü&K`ı«'Û	ª Ã!ĞO2NJrµ†÷VêÙ€\Ÿ‚èv{Ñ®ÂÇ“aZøSË¨Ç}ÛfSšÎFÛ$5Ãcê<ô³ƒØsÙ‰Å‘ĞÔŒ¤Êd8 ÀKï5oÊ—¹|”pÅ ßV:Ú ­—Üê‘y|û«í-J«ë´s²‰~Š!•WiVöÔ!çÔ‘Ò'¢£IËy/­‡–mUD@Ÿ\i4
ÜoU¦¨*ÏPŠ,ñ‡7[—Æ¬&ïA$k‰u~Úüä#ÿé#ûêÉæ#…„ï\—öÖcßF7ëzÆIº U’I˜ú¬€ßG#–¨YX™I à,m²—å8õ7×²( vld(jÃ¸Ø»B*<‘›½èÈ¦ "½©`EVEüI2-šĞàÛ'J\sã%ki‘Ê#,_Í,VrG,içõbÍ:ÃË%‘OõYÃò`ÄÂ¸‘\Ë¿¯¾¶GÔsTã%ê+†ğ`Iö5({eÕĞ®æI‹İ–FñŸB˜ç¤‘öğ;ƒMÓf@4¨ğWİÉ+¹¾®1¶ıPZzùwMÂ4j»ó‹I@òöõªUõO JTÚ ±… à÷ÚÎÈ†é#ò#³NoÆ6Œw²äËlÍh@:ò¨‡ÿù×´ŞhÌI”Œ!{ï Ã»¿AÒ”YN÷V˜Ìk\"Zdmmå¸§‚â¦[R–{œL˜.¸cgMÒò¨¨¨BLæËI½œ)T!Bç}xÛÂJTê]]MÍÈ'€®ª±u37Wp ¨MõL…?¨;ĞÖ² °e”6æ¤×Îy;°©vØ{"¦‰óµ}÷vÏcød[ZÃ`T çÔE‡Á÷XFİ;Ê¼;|Õ°Á9(¤9R!öˆ±ÖéKtQ®cFÃlr<x=_Ä¦nì‡Ã.uÔ‚Õå&ƒ/*Ä©Ö5·şt((l©ŸêùáÊ<eãT‰Ú‚ë°¸Ø8Æ2<u˜h{Ô¡:hÄ³Mµ£‚éR`pãÉ&RM~ÍÜã` 6‹´&ö¾<¢Ï&ÜóÖ¯®^
Úşo¬ÎUfìÿª^GúÔ9òÖUƒ(aÖ¡±Xw1hzWÏCıQ¶”a,‘â˜„3ët>ÓÑæ Ç3‹D³ò$°âs1ÔdLìõƒıñv)÷k³ëcğ0a/¸TwyÏø@7ÏHĞú¯6xéJGöÅøzÃÜéjtöñêP$¥MF‘`.ÃÔz­ºDù@JM6‚¦EÊŸ;V™|–®b·ÇKŞ”š­‘Ñqº÷_Œ,ÿ¤¦\õ¿|Ù&ãq-êÁ½¦SˆÖA½6°bCî$›²$İĞGs `ç¸è‹	ÈüRŞXî)^àeëâ·xo«ár´B%„Á9! ç~ŸT©³İR/zº>¸ü^;¯¿İ"ç3]Àñi]8û:6Ú¶æë~¯%_ÍöFZQFĞ ÑÃl¬~A¶jÿV¬M¶ü.ZÎå¯5Â¥ûÆ+A×-p×yö¯}¿Ú 'óaÀS¨	pNá/}·ì(±èk[é“,×sÔÕb²Ñ’–ºò0ÌCIÀD/óÈ.,!1”@²ôw?…ö‡‰üØ…J’¼Şe›1´ËYñ:XI‚8ò–½J,•ÂæÆ6~KÅĞNYˆ«J?ÿ2W{÷e½l{pïp¼pYOdá8Ö”3I‹ù˜»0ónz‹ÒÎj´kùTE:µ LĞ°€9.íÌO•ÄM 4‘°ÂmŠõ0ğ~üÊ1ãQ‘-İá›oé«Ã|·“‘Ñ›:BÑşi`oJ=IÏˆöY„ü”AèzYŞ³êğÓ9êl¡l@0pM=ds1›YPÂ8e£¡¡‰éŠ,"< C,½7ëSéÓŸ0r[{¢A„Öççeú™†5Í@ğ—LCô™~NXÃ]¹-½.Xz¸48«f3•3ïM©Jl1ªÓ¡÷~×©^÷‡U†Ïû¢İšw‘1p
º~àn»å8¼š<‡\h~Šè¢¨ãY±·†_›ÄrNsNV6xV:ëû.ª“P¬&$Ş!:èJÎâûÖ§›§«sû¹ŠÂÌ”‹>ÅİA@ c7|şuêœîUºñíû>Æäñ_òù•ŸJN¶œJ°ÿÄk°€?¸½¥%yß2èKç¼ç°öjœNúGî \È›(‘póŒÄ»ß*%»vGYauèğÀ™UôÕ,ª¬ñGØàqÂsÇRƒ@bÉv±ş¿„âË²ˆA›»=ø‚ƒdÁ!DJf2Ê*IÔ8¢	èM#Õˆ2÷Tß’NnCNHöÉ˜Ó˜ŸôÏÇ›£ÇÓÑ>æl.E1:˜_Š‰Âó´¹ægŞ?ªJ}&	,×±¬‡Lb¸:{¼WSnÑ¥§Q¶¿j(NXE$m0b@†exxzA¢š‰ó¶€ßR uYúg—ÕÔg‹?¹Ş«yzæ™åò Z®oGSfyyl÷$Úad›ãªf3PZè\ÚˆÎì¯\‡ñÚ”âÄ´º†îæÃB(åøµB-…ÿ$x©Î°íÚÄMÕXzd®:_Ï&96; u¥É¯R³RK‚K÷±‘„kBsX‹ú'‡XÌƒª5Dµ{ 2ˆ¦­a~ÖˆûCºŞ)dó©	zcO‡H\,iÈZ‘%o peÎ=»"[Wîé#çß #1¢³„—-‹eï¦N4,İ–EXL^¢ûåcg=¡”§ìß¨¦Ã)±_Ôv^A`»w&ÈÉwÅf¸q#'O•NÅH$4²tA9Í¼ÌyyKSjµª»SŸxˆ‚¨Œ¡±ikÓëdâ>¼í@·C˜[ù$x8Ÿ~9*³ìÁ¾ög?.Àu YbaïW{!1¼KÌÖç(ZI5¢bîÛ+W¹µ 9âpáàã‹1½Ù§QS²„H·Öÿ™˜İxÕH÷¼Æü,–Æò{9yY›İœö˜êß·kQßÓ	†ÕFx¼³{¯`"éX÷8°òe¶^=ÜŠùnH\õ“J¶¶ù—Ôß).q¬¡rş“×+ÎÚŞUÿ^}NB¸r·Æ¶èCËaÄù¼ÙÇ¯ïŠ”6]ú¸máöóæln.–ÑúµéñöQxŸB¿¨šÓµjƒ8Çú1toÜ
aaã¨©î"!à¼¹©¤üã›€=¢¥Gä®Ãƒ´Ğ
Òbbnuh`¤,È—EG:Ãi”lEf®kÈÔ¯-ÃÔ5d±«½Œ>Âµ¸‰í5_N:\3î½bb¾ö…—sÍP”èÑKö(_I%½BaíÔç <F:ü<è¬¬{ç%†Ú†ÂyÁP¶xHÍït±›!Éi„³•¹4(%™2rşĞ¾ğ[ÄR“‰¦e,¯£2”‹4€²{ÒL$³ÆÎêóhã;¾úÙéêŞÁ×¹|9¦Â^ñæ]±ïòµj¶\&/Â»¯  ¯ÅïhAÁwn%,£–Í”Ø¼8Š‡€µYµÊÙ_A>ù$#ƒx/YL{røÛİhS®ŞNø‘¼ìK/A”¦ªwòµ‰¤áJ~GY@áÓ-¨ƒi}¬Ñ‡ÇMY¢^Ü¦ƒ€‹{¿­&d2¿KºŞÇ„açX‚ü$b-Ü¹3á±Ûp©¢:SÍ‘r§kÂ “älXË¨~R’úı-+ğ ¢Õªï…Áh™Íï&§^b£]¥¤Pª1JÕ Ÿ"…ç¶B6;,BLÈ¢zZ‡Ê¶zX©®C½ÌÀ5Øb•Ûm-ÇM {H:óãZw—fœ™®°éôç6Z3EñZVà
T7Îœú„ØÕì"\W½^¯´u2NvRo!E{Sß¥Ùœ©+%`üš^ŠÊI²G4²èÏdğ™'g½øwùÎŒƒ^ÁÕİLõî5ÖõSjÍ—7Y_¸"bˆN¨Znà{Õ»<Ú-İe‰#©.ŞËqE{†úKÈ©CNo(Á+¬Ñğ×İ]Ğ¢0ˆá+õ¹¯ğ¾9M8pá’dÉŞ´}}c˜¥jåNÁ^ÜÓÏŸz‚Ğb!<Zíú¸GlÿÜgø“ÔW£úùækİ¤J×Ïì3É¡cyK"A¾ê*ıoŸQçÀÈ|Å‹ÌÚ4XE¦½iYÃ¤§²Èáıj3MMUa|e¸İiÙ9’DC´øm,áùV˜7Ôc„]s¡ó6µô­cröUºåÛåñX´pœ«{ŞˆŒcŞhhaòn¶ø§AI* ™€>°Î×a1ØƒÇ,J”|q¾’¸DËåéEĞeâ™Ø(ÓÚ3¦:&‹·o¶tİeXæÅ==NÖ†í»Œ,~è²¼z#4æ»Q~S0FÖĞ¼Ü5r)£Ë¾‡rG«ßNWÏk3ĞÖ¬zIªÖu•4­—)T1~´0S®©åÓÂša/¯ÓÈ½ìtòş‰½1w B#úk©	«—•nVw¾±,Jk¸l÷</­ÑƒTiñ"ü‰<:éSÅ{¼»7m%ítşŠ0”Lÿ–i»\Ú™Ğ|(‰-Ø¡Ä^ĞnïÜ­g1ü»ê	BŒGœ}Ä1(NÔ~ÍíºPOĞ{Úß"UıÿP³ŒÈzËGÕW{ŒwjÃ/u­×Í‰ÚBùÑÇ?pÓ¡ cã…½_.V¥›ÎÂ°/N½*1µ\Rg+°Ş¿s¤±áÊc1}æ¸±c}BCÄ‡m~ÛmÍÛ<Ò–RhíKıtr)cÙïA™ l¿lônW@wÅ(KÌB€©î_ßcÚq.Ö?)|]r{â¼‚ÆuÅÿ:*‡=ÀLa’;Ø5åZa(ÎáòoŠ|…ğ ÅÇ–‘”ÓËOdìˆäÛ¦ØQùÌ|uëluJr¬3k˜OéÊ ¤·H7bœšÆ¶ŸÄiNJ„®–4“s3¨Bd‘×¹QÂØ(.+&[ˆ·$¬Ğıs1UW®Ni Ix6_l·z.ÍBgÖ1²23Úãq]WA€3KØjÇª÷$õàşˆÜ»°”aªÑé–ª@öBfXC-~€hº(@ã¹ŞQ …œe¸tümÌİ{ia
Ãiû_Qî¡·ôu;>¾›º‰Ê5¸¬ÁK#MdÁ,¹Ãå;ú”€ChFuQDD\Ë•(ZQâk;U3Jjoò'ã*ûšØ»æ¶0'Ú n6c†OJ*÷4àÕ©ĞxÙ/‰4m»äLÍrG¹5Ù‘pt”À÷ï=™\J¹7R’oÅà%ù.xöÄœ A›Òm9
?<`³”¦xĞ÷v©Ø¥7ÉÖE'‹š°HâÕïÙØáKş}¼"^×„³ÀÂm¨™ø-L|± __ÒİçK£”ãá"iMxK¿•L•¶ª#‡ï0GqÅè”3P=}„§d‘àIOô¶kMrëEtX—öØB¾7İ›Rz+"¯õ€ƒ«ûKoTÍ8Õ‘ÖŞN¾?ßsm½JÀ>Úÿ‚-¬‹¢Bá_TèÂ¾X¿“œSçÃÎš¾$F§'œ¸ø‘Åß4ãöÉ$C'ü¿IRZ´›>Hà¸­¸î¢c°7ù%”çÍø®.ÉªtG?Ml÷IÈKo¯47ÑÌ3‰‡Óõ¤²¸={Ï
gË£64ˆ„8gE²GÅyMıˆO<>Ì|pïşn¬Ë¦±Í  yêíiJOªË’•o˜­wL­TÜ`w¼»«(ãÂëR]B~Š…§ÿ‘ÉÇ‰ËA‚£¼«DÔuÂîÙuÂä[RÁ¤m?Tùq»”º}ûÎqG\ƒ¾xVÈ°Òìïxê™-øïWüşğ‚Á•+Ä1„"=šCeÿyC­B,J£F×–q LŠ´G8T[cKŠµ”ç•şÏX^‰î= -^Ç˜"ákÄQ³¸ÄŸVì¢É#ÒğU%‹6E›"\ xİ4“0u`¼˜•ËW8ôº7ø?ey½5‹ÿA5íjÅvT+Wb-fq"_¢3Û¢÷:[Äÿ	Ğ%¿Ô	4ŠVò¥t¡åÊtû,¹’ûGEš´ s¥c†ÒÏ:0jû¨Õg
Ç¤6	Sı‡	Ÿí~õíC{SFfğG0©Çô¹‡2–æúûŠXfîG¼Öô1Ü9<­ÿ¨	feğ,ÿ©Æ¬ÂàLAÎR¿”‡ËQfÏ@¸‹vµF†Bš¤?/wÖÖ+¾‡…:ïp˜Ôêä³ìèT',ÇP\ „L¥3|øTÜv”ªéø‚¹ÿÄßj	ªøå!ÌÛWA©E™4 T†ÅIåÚ±…°B¯ÍõË óŸÍ¿\şGÆ7º­…¶ÁA+>–¢©2Òë¦|’}O}Ÿ)¬µ?L#Kå¥Hìá}~Õå:´ö×)ò‰’ÍÑr¹ÉE³ù¹¤C=°U†KĞ	 YüÓT÷$ŸT|Íbª˜d¾z¿h¸¬¬bD„òdwÒ	Ëïˆ@Î8M-½Ô”ÕEO°&SWYzaÅ™-ã—&ØıÖ^³²„¢¶”÷Ü¦Èâ#¹fƒz»‘I¿êÑ»Ä«Êd·çÉ077N.M×wPõ™¶‚¸¾»+Xú-A4øMË˜`ÔVÏ0—²™oNN>3Ó Lk‚ém€õ‡ıv™Ïs…ıhC\´€ú@½ëW9ÆhçM<½îÛ­kÛŸR<ôóù‘OÔÖxÚMÿÏR~­›‹ØB£¾ú7 |¼£G5>9¢?û„[8®×yÕÇ‚“<ì&~r·,¥'ˆ…êî"èRw¬_ê;íhE*Í÷>GÏ{¥9B3¹h„ïñÜŒ+ğmì»!^º¡2Ş´ Ğ	~ĞNÃ±z•(  X|³"|€åÏU[uq0;A­aèW¼İ=Š›(RŠ³Æx˜êKøZZn1DÊ´§G?½8(åaJ	î&œ¨¨[Ö|.¸Ãáˆƒ×x)Bö°¶$wdÊDáñf¸Ê+Æ`_ÎéÌŒL50„Â6ËÙ•ay½¥S+ÖÖ!Eh¼óI¡7¯oçRå;x³i=0yŞá÷™>ó¾¦·Ãm_è‹Âµİ8-U89îhÜ©±?gRÖ´òŞO!Ì»4(rC^B÷êMïoe|åÒDddpxÒ¬ò LEÛÊhM¤N±cı#ıgÜÆsàêò"(Ää
7ÄÖ•Â>ôzöØ^€K=Ó2†îØ?ë
‹â*|wa×•Ö<³êà&[YyDkv!	g 10äKLıXL[ïÅÖË’Y§Tµ2´Dé?×´V¡~˜‰.Éİİcp*ûX ZGçôTEúE"É~Îß6HÏ›’ˆã˜Ó"‚íªxî÷FéE˜OçâÒ´0ûd’µ#G’C¶C¹-ÑÈÜìBlâ†ì™ÂÜ7ÚGìƒ¦¥sÂúş¨N7¼/síìès»ûc—uSó÷q×(ÆcÓD'v\‹; ’‰lq	Ğ¾¿úèt¨(×Ùl®¥»gkdì©›DC9€k’<Š›Ó€aJâølõ¥°ñì<XÛƒ_§œª6ƒ)N«,	öÆæF¢®™@KøLA´Q)Yß¶ûE­*z<&Û…G¶ÆşšÚ§cZ+òšˆ¾Îu’czò‚µv@1®8Ü‚·“C–{	øìå5#G¿ÒÛ§¡ÈuFMà%[® =~Ÿ¨¼r‡Mf½~ÓŒ~›€($&fc2ºn‰f–VÑ	páópê°?ô‰"¦ç¥‚´9±é‡T‡Ğæ‡iv8(™ÍWûü„¯Q*´ßÊ­tïo×M?d¹™_uÓıÇr°æÜ07(pÿÜ²œU1¡§äzZóÿFúû=µ
,ˆ& /A'à/3ˆ5¯uV®¹¶‘ğÆ+t¢„Yœ©ı¢…íxòÃF¦:¿rCH[-èıÛ2¥œ†PÎåŞĞkƒûh6ƒ?mä˜D”Ígà¯F0qø¶ìßes÷CS”T7’"Êü²ğ!z¹5Š¢f¢¦”ÃlÇ$Ùz‚‘^K[stiæw.áòY£$óĞÇ	‘fjõÖÖ…ç{¸ØŸƒL-¥z²Ø7êÈÍƒp˜÷ò,¹ÎÂM£Ü¹Sˆßí9x‡Ï?cuc—ôÊeÿéûu³RùÉÊ[Îk>EdöÀcğ£üÉ9è§áÆíÎRÙ2²r_¸˜JW-œ¸¹„sŠƒ§¿SjV´b(¤¥8Šl}İ.RAÚõ|’VQE@òÉ+"ZØ^­ó01m2vhB<¢£N¨âÁPÂ<Š¸ã™¹ô5›%Ïï k¤â}^[»ä2˜H’îPV «®ë²oË³óÊü£îaz¶šYÒßƒ»9;\ëE¼ÎYÖ˜3N:
F˜6òTYŠ
 ê^xÁZœÔ 6`·Ü&…×F¶” ‹èŠ8£%ùq€ó¿aÉ€³ª¯ŸÂà~$¾¾t²NF¸-],¥{YÀ½ ê§¦õ(|?§(İ`â{S»ˆST7a0‘w	IvÜAÌJaKxÀü’‡xŸnÏÅcªi]Ù¡ß=ğ;«Jo3˜ã¯ ĞŒß¯Å£‰ôx,÷^ŒeˆüfŸ G§\ÜíP]mY»Ë;ĞxH]#k@HÏÑÙ	 ?8U˜êœOÿ¦{å H!ªôÙÊ ´Šã;_ ±û@LÙÚ`\jôù’5¨”‚á Ô–ÓƒG·2§ƒ_†Í~^{5,÷"UÔ&µ§ğZ6WáE”…ÅÚ€mRê/Mk˜gmKG¼¸Ó¤ÖBú/WàtÚ#)}Å1.İ	ä$¨óÈ¯ *²±÷şñ˜jõÆœÇah9O¤#š'.“0ffïUc/â0ÆQ'»9«t€’ç£uLºÖİã÷™’$6–#M#ÆpØƒyy{z?5ñÈ6ÕW¤—Â§M;†î}fI5Èa‘UúÿHö^ŒTUá´Hó­·«Í
š÷Ò€aä	”¦¸
ZMfCëÎùX‹Û±<è.³_
zeT.XM”ŸãXímÜûrĞúò²5Y‡&CÉú«æu6tÀ?G‡ßP¨Pèƒ>=õpó •ÏãôŞ¹Eæ˜øCãÏ	‹°‡’”Ä»ë•]õH#-İâ!ù®©?t,-¤ı¿Å%‹ãb†Àş ®ÙŞ{'?sfêS’b¸    ¯åä/# ² ¡È€AËcî±Ägû    YZ