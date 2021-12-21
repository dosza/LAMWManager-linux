#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="10269062"
MD5="96883f5d1fec291209d93ab8b2177e74"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23972"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Tue Dec 21 13:08:51 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]b] ¼}•À1Dd]‡Á›PætİDõ#Ü²ÔIƒ¿Y¦
 B…iœ‡Ê6B+¿;&Úì»«ºGu"û˜†ë²8pe¸‘VZú(7J ÅÂ A¿Än°;f)îŒ/Çõø-1{¬¥ô=İ¸Qœ’ÅN9œJÀòWç6ôµÎ²üeLAKÛ×Ø-`é8EŠqÿÃ;}¯ .çmT8‹»oÀá|…E¼œçVóú#Í£,;ò—ñ¶ŞÁæ…yŒ¿‰"^Äü1lÖ‹ß¼9: ôüéÒ]kâı3%–­š9`jíU|Ôbè^d8Ó³è	Ä»ğ+‘İù7Æ£glºWK—£ç‘,iZº^¬»ŠE§ÛG¦Æ%%&½¶ ¿Å"ü@¥„òê²"àñÔ;Ì,¶vZÂä· bŠõÏ(áCŒxW²o%s¯Ã¯oe:Ü@­ÃwÃ¦QJwf'`ÂÙFÉâŸÚX¤{‰ˆ`Òïe$<à´:İZçÖÆûŸ7NÂ¯LŠå%»1:¼ëÈßa8Æ—ˆû?j´N±¯XË;D â|_€‘åpufa‡‘Tç”0üøï
ÿæ3n53úMõpH´ã§9…è|S@ìÅ”l¦z:ÊSä­×ÿ£*ï…X;¹W÷UŒõÓ&œH‰Adş¹`v0-Î— ĞIbl®%J¥jz™Æàé0÷ºkîì·`­÷BÌ‘¹’ğ±C”)ıkŒÊÇ#ºq\-Íçtğ¿Å<à ‚FAÂC¡¨—ª	Œ5Ä+†~õ¤zA–”ßzÁÑBËFòQ„ ØË×ÈùHØ`F:ŠÇú^¬Ndh‚'®Ä¤[Bí»R@v¯Àõú«Ÿr²¡$ßîñ)·g`}Úâşÿ@,ø#d‡$]çñõµ¤‹üIì:€ÅxC%pqÜ8Ø—ÉôYæµó˜ËßOŸYmÀ*
ú½»ãdYµÏi0W°Lï$d2«8âŞ0:,ÈlfƒL ×¥Ù·Ç¨P|“á»‘ÉLJ]¸«àDKÕ=ÄÉum)Şª¶ÓnâÈnÂ¹‘š²8Q¹?gÚäË&Á^-Šïds7Qb(í†’Oİ±zà.«Ãöœl…¯úÓ?šf“¦l0®ßğ­*)_(öoç×óFKI±ÔÛ%‚¬@n×&OB#lEã(¤&Lıì¾ç¶ÀYN„'CÙ²Úw”Eô×İ‹¸{=+•[#³EjsNoMÄ|İ½R§¸Á|YCv¨ö¹:‚Û
Îë_B´ ¬ÌSl˜´QvËzryÈqÁx‚.=âŒLoÛõƒ9]Çì(èQùB3Zs'‚º6`ç°¹‰J¸<CJ\Ú°8X> Úç)üé¸J{§Ì7kÂŒ˜\(GnŠV¹0½HçW˜Š¿ú‰bÀ\æp
ñ	Æà¶ËŠc}õ%İ‚Æü0ÕllNšC“6Üb2&ârÙÉÜBqF#"V{”VB-4‹ä«è+6¸ @%­-ÚmøÇ‡Â‚.c;rÓWw@¼˜éÆn—pÆóÁWDo)Ë4o0akáa‰ŞDÚ9Z«3,¨±½Á›h…:_"œBm¼¾Òª˜	PCSl"‘>|æ"z–O*–øç(¤´o.œrYGé=„H+ÌvÎ*Œß[±íÎ|&YfÎ*Ü¿›˜õßDêg»î…iPlRa•®kZSŠ;%}gxK©É$”{7i8Ù´“)§ˆWà{€œ@o³ªˆ˜ö¿äÌ‘K[—á¿ñ”è¬îF]«Î;¡^¹ñ§*¯p"”ByÌÁjb%(ÀÀ	´æÖ'q/{MÅ¦y’º‹'ús³B—o‚“¾!Ètä*ô*k(j#Î7ÅÈ±ş$5P{Zì,«Å¯œl¡UÃªôzêP×"|!æß©¯³–»Ğ˜mØNáÈı×íÌ	œ‹Ë´~W³©ŞÚÛNHÍ1FX¡¼îøŠ4ø
±Æğ(MeQ²„üq„äö›HÔ+aq-	HÓø8ì]KBÿîÚ=4_Î¼ºíÙš_ÓVí¹GèŠ^ŸbÉhB!—aÃ·^rU)»áÁû<O“LWúÄ€ˆ)@ì×ïä$6Ö ±Zü		dİá*eÅ¹—/ŞÔX&XaYVû-˜®y*ÖØ¨åªüâŠá†G 7#ø*Äëfaİ³N/Åjç´›Rü±ä$ÃÓˆ"ôY}^ék°féÒšŒ:²©†b
“ˆ½ß]ÁX€Ğ=Ã[Ú>YnZ“Qû‡§K5›ñ—jdU“~GM¥WÜ:?¼ÖL:Ï*ªlëÏ›#zañöÛE¨Y[oj"`¸”¤Ï"Fó×˜ËVa®·SúIEeŞÊR€m+¯ùk:İx³{Ø[dœNŒc
¶ùÜñ 
ERñK¨;¬Ö%ıaUÒ„Å89Dâ$å-ÉéíèŸ“OcÕ3Ğ5Ä(tŠà}@y$³˜ÆVÄ*€´ÂÚN$Á4_&‡œ½$dpu¨j_t¤q$×(IÍY"£Ïî&Òd”´šç{fèÒ]xnmØÎÓ“];@X<çºÈş*ÜÂüúÎá‘ŸJJi|Éd6ø Mä:bÁ®áT–lÊ¼öWñk´¥°3ˆ£¡ès6u€•û¬éÙcz.îÚJ52ñEJvkÅ‰#«"æ¦fN#QntA¢hw¹B]sQIÖxï
”êm˜=…µñ76qp*@4Êªq3|ç2$hPšÓ£©jì«9®ÒÍ8 Ó˜aOöp£±§+²Ì´;QçmA¬á+¯K±†T ò¶òY<›Ãf|Ú5…êj½ğ/\²PaÃtwa’ŒLSGœ™÷_"Û<VÙæ“	íôU¬¥c¼‹˜ıı`?Ch¾@ıŒÓ‘¢&ñ¨©T<ı³‚ñÛjB‰…euå„®¡Ña=%_N¹¢Å.Ä#7%õÑ sv˜T²a“d Ô^tB‡MàpÂs0„hP ŒHá{ŞŸME±åv…aÏ)÷BAwÀôÀ^	L=eM-‚Ö”$ÁNR‰‚o$ı¯½©¹²s~œhk€6gJ°I\ÀÀº´«>KZ|jú‚úÁw•v~Ñq?@¸ôœ½Ó ;-£´ş]ãÄ…²Å? À]ÿï­ß«$“‘mô B99Ñ’óâW
<Óı$À.úéİöÍÖ
¿A•J©
ÌAI˜aanA|ùŠ28y~ş]Ší[İ=Ùíø½[Ï1ìªQù?Wà1‹¹±_ˆ½TP€´ã‚-Ï†È}Ã·F‹{§ºxb]¥«¬wµQr5V˜X›Bß¡oÑ4JşF`Ã(íÛšë¼Nnb)TºÏR²V
{Æ~*eG9t^&(ãÄZŒŒçÍRõ²Ÿìg²(l'¸|—a%‘8Av|i7ÈB(»LİXâÊˆq¥è´}èU8k·%e½ií‰6+İSLU±‹•/àIôD°8ŞËy ™C¾u`˜.zÂG‘‹›<N
…EIô¹ş5Å¤t='»›ë¯ÓªŠ<n°é{nwä÷k¨Ù,rï9	Ä}m¹S+ï¿.? tØëÉ^Yÿ#6O%ÀÄözÎV:úÇ{ÑÂ¹W+·±ÆIr7¼ùu7ÒñxëŞ„ö¥ÃÚã£AAäÓÉ„Á ü»iùzñ‡öñ?ÀÂu9°5’ÌKKìÉé7–0P¯õş—»á¾Ì(FÚøø+g%jAA/ÂMºÉÿ›¤ù%—#S+hÜã³2úlCQ¼S	ûnµb9¼æ6d<hšªst2ë,õÂò‚µ¡\5QEåJÃ¢_H}pV)7ºPõ`éW¨¢MÉÃÜÉåyªzëföÔ©¤ò“˜€ï°¡ÂìÒ\ ÆtL>Š¸cZ¨ëİøJğ<ßÂFYÊ®q_ö{éƒD *Ê¥…Æı&fe)$òe@´ñ;·”hbÜØ0—)ñŞ=„:1Q1EğûÏZşå¿Ñ¤‹ z€,vj¥‡Í*A¨«ä‰¡=m·Å­›–«”Ãáá”nÁD}à„Yf¿X7(‡TÊ×ëZw:'¸´\/‡c¿){§P0Z>´qv*ˆ.ó-Şë@¢VÉÍnx']OCavÔ(l“‘‘¾yñ`ÙÆ2JàÍS¸|¦l÷T¥ìº(^™¬n®.=	]eS=4ëµ&õ,…D 18âGMi1®ßàÂÔ•CxĞú3˜›Æ™6ù,ùİÜÌLûÑ‰W~½½¯\ ×NëeâUß3”’ıœ&eÊY±úÀ¢,Ke¦Å?t…T!9óhN+“¾m¡;Ö‘o7@ÕOÃ­‰ŸB¸’©!‡ØÕ*ÍIñ¦´ib£¿r9ˆÍ$$~'éTš_'¾-!åEcÉ`õqåÚqÿ‹" ßVU¼G¡š|ÖÄäzwğDÀ-‰¬— Á¶Ÿª‡¢g¯ü¼=«gí…,ğjÿ#¯©xù´¼d4-(Oøä!4ŠƒQŸ;Ê½§R°ófA¡¢Jã„ò9å¯Ù5Â \É^ßí€Ò£ÍücÊG%ïheÏXÃÅqº9ïöMF3ò8…/¼vë•÷¨jƒé~Ä6fp2Şº#-ùë¬}Ñ_cãÒÃ	 ã›il¥Ãì}ÌÀs] T…Qú7âAõ½c‰‚´àØoÈp™’ş¯Š(Ø´,PcÜôõÆëà¢AiE¯4ï¼ö,%Wíp³#$P‰gú&3·öü	c :ûW>Zú DG°H\:™¿ƒ¢¿íÂaWÉ™Í{$¹Š[ ·Ô?8Ì<ÌöµEÃLêÆáîmÜ–÷ÒI iÀÎû©TšíŠ¿Û':ÅÆìG(•ZÎ+eZ~UR%¨¡#Ë•²‚äÇêq‡b/JøJ±_Â%ä¿9~Ç·—Qé4|1®…7æf—y×¥=.h”‰ìÙî±-7âÏtë/$gW!ß)ù­ç3h.$T#Î¥¼Õ:Íùøx1u;°DÑOHŞïÆâº7úîcé»ÙK¼ÑËÓZ/FËªàÈ¥=¡=§´‰¨rt8£ zSîc´a®9?â)Æ¬'£³qşOÛÛŒí¸Lñd^Î­îØİè "æ½ÔFûóİ³ı±;Âm¢Zb¼“k£ã~¬|ÓeĞ}è6àöŒwUò|Eëd#•¸|…–rVÕÙ&£`“˜1^´·	WÁ†‡T«óH¬oĞ­kSºèöJ2m~¹6ò©Î~Ç„2"Ò/S;gæ%5l8dwNâQ}¯ ­%B±îG]Ë3‡f]Ù÷x·!—Ÿ]ÓÍèê}zä‰ÓŒÎœ¸^\.XDä168³¡©3us„Š%š³Š=íÅ› JĞå"v ™V
A[}Ì¦Ú©iå7K‡sÛTÚÏqC¡òµ—(f7Áw#í;¯èøî¶ˆòû_×¥U|ŒÓè•õLjoƒu†‹,£a5ÍŸh›Ä2å’ésĞBæ· ¢ï¡
(ï½],Jè_@}c¾M”ƒIƒOÄ¾¯'ñ‰¬¬ıÑB?LP±G0—…K^7[R>ítög†}÷¹¾r!~Á	ÿB¬£Á
UÆ9<6Î@% =úkÚFĞ%+V%3†»mtù®*hÀV’§ò1‚¥œ¼<ö5ZÆO&Škÿ1¾Ì_«ë5Óqby“\™)”šÌOôè:ğÎ•Ó½kwz2~÷£ U÷ uóJÁzén+u—QpÎ'oè&ã pL×†‚İ!°¦¿—>\Ş\=Nº9¤û‚ë¦uW÷ ¶±¹Ó)àYÉ7	>*Ş˜~©°wüº˜JƒùA¹F"Xà9p»›ûV˜>,ˆ“ûéJqN°†2¿.ª}ŠRaUxÒ(±zÙ™¾}ìsJbÆYÊ'¤æ„É>&JÁ¬Å¯Hô)=¢ÙÄe±¨#­50àpz J3FAKB´?Š	Œ@€ı¢UªÉÍŞê˜ûëş	“ceô<t1ÔaÛ†l¯ı(ó¹Š6Dğ8N¡UÿP²É1.lË},=äSÛF ©,øG&ˆ¨˜-2*®sƒşV†zJtğGZ-Wƒš±)şaCÀY…ZP  J&Yç'mÁõĞòÿïH²ùé§VÚÛ)Í‰b”÷«Kô‚7TöF“Á M¼¿±ÄbÅ^çP¹-bµBÎ‰ànDÀs´©zt«KV¼~‘¡QG»ÜĞKt‚ûZ—Û™v‰œÏ¡f$äëjkB”ß.±±‚§}ìıßìâò„µ×¨E§ËºNˆJV”~Ÿt Yê1ÍŸi8Ob®ï#DÅ†	µg5µ\æ™×6 .J2mP±¼à&•iĞ¦ÕsyG˜[¾ˆ ”jZZ³MÉÿ>}ŞĞë6‰kJˆ©_ÌĞÁÕÈ[¨©8txJd¯±nõùÕ &EwÀtuÂTSû_G°†õÓs%ršN¦^©A>ÛUbÍ3SF3_—í²ÇEÚãu©Šœå8¯JëîMK~¯S¶òTe4«†X/ (‘uÔY+Ÿ‹CÕ=-Ó†÷¶ÿBI^C5—-ê¼ ¹ÂÀv³íG˜¶-ñŸâî¶tUs¡ö¿²~‚E”ËÌÀŒU^¶°ê3£4È°Éò›[¯Æ¿²$7P²J&¼&ºÂWB#[ˆXQ_ÕrdšÁ1‹˜•c6”l|¢ï¸,2fº@Ş«J2ôUısó½h@\µ¬[¿Üc<îş}ÕŞ¨®ö:AİÃBT®3ãVÚÕY¡Ô=¿O(Å°°úŸ¶Y W,0·²øø¼z¡äá/AùMèï&-	
~oÂcªn@`ğªYÈn~¬|hR^	tôH‰]$ìFŞÿ­æñ“49’«é÷Ã&÷v[ÏÓÔ•+DYX§€›{wçòøŞIÊ^—ˆøÌ#7™ò9WìÌ£©¼Œ4ÿjR`‰¼‰+ª·<P¡ÄĞoù+·<†ëSíà}32^>_¥Iİ^‡ÏCË9:qVYİÒõGni¬#‚©b‰X¹<àr«Áôa™A-àH£`ÚOñı‹¶;‚ÅºXqäÊÏ´ä„h)”n”½ÒÔxm*„OSü
›¨;)©¼ÕÏô
ó–íh¶ÁG³íLˆÆ¹yòx•	)ö–és¸®³<g7ÌŸÛø³ÖDÕ:ˆ¯á-ˆ¤ÔH,Ãğgóåå¨Ä¥¸uùîÆ½'İê¨~½bw^wX?äÔ²ã¬ÖnÈiŠ=ªˆ¤¤¸£¸g!3r·åãN>»ˆ;™sE’”;[a…	ö€¢¹ÛË<»:7€,x‡g“`é^ûd—OÀğø@õ‡vûEoVYtoµ’Ní…ß!+±—¿i
ğàWÏ×ºÀ¿”)zo^Õµ .w:1»œ*&µ3ÀÜkxÒËeæ@Œ·àÙ*a“(0QÈÕaæÿô3‘V P°Oã«†‹Ø 1¬ur9•¡å]0¹]Ç´Û6@?y¶œş8}ĞûxÈá•ˆº¬W.DÇğ.Â.>b–EbbÆeøe±SÚ]1òS?M„Ãx€h8öòj|ÀğWÌHsY¥ó›ÌhoN»¡g©³3TréG´ÂÒ1+ïCÖíÓ.œÑ–R!7û£Àh„^èôgÑ¼…,O0êrÄ
¬î­ÿ©ÃdoF–¹/
ŠXE}úHMíùT¤Ñ,—şù…+ThE@|'ï+¿¥Şò§v’]'m½néI-£çk†øXÚä?Jœ*Y¤àW[>®gZŞÅ-“_v!{o¨>Ì¾n".ÁJ#w~LØzî6<ÿ™B0ë´ıHuTá~h?ÙÖR,~¬Û•ßÌDN3Ü»â ®IÕ'¡‰^ Rv<h¡TÓğ¾q¼Æ±?ÀA
!œ‘˜›œ"kQNHRäl6f%A\†î·ã%}2Éh S°0î¾úÌÇæŒû:¬bN‘–Õê{ÖHÆ(ì_]«!n”_~zİ§b{øğ´Ó£°¦÷©|2Ü­İì-¤…èÕ““1šõÔO@Çb³¼/©Éæ¶üåßlµ|ÂçË72»%À1'@ÚæfÔªof“ä4bTU·]ÕŒñ(|i¥è~ó›ucœÿÌÚğô V¯•®Ft:!I>/HUÌìËÿìÉx”Ğ±Ø&ƒe	YW×ùXÌRfÿs8+K´GşË–À§­Ef;d8ï¸U¥|›Ìç¬Ñ¾LÃù¶Ìâ;m7•2Ú”Ã4Ÿ3æãUbR³æÓAª~ÄvÈÜUğ
{K†’ÌÛ¥çüiŒàÇÅ•)üµ2şıÉŸ ùÚ¶@×¿É°NÓæú=¹°‚¼Û(q–şB•°Éƒ©Ræ˜B· ††İ'{C‹p´Wó´>´wæ×&e~ì*VÙ¾fßµÖ±, %_×cÃVÒú¿”ID—K-—D|¦Š.îŠ$Ú+Î"U5ëÙ,ù<fœ2 ôÂâEG¢·pÌÔÊ4$ıóå>UË¦¸J*åbsµŸÜtZ8×Qõ#ì)¼Ñ·°j 'Ïıí‰ä™/ÃSÛÎ.¤
£×’ƒŒÕœ|Ó !¬±ºƒñ®¸áÿ\úZíÿ7!§X$Æ¤bY~Š:öEfN‰øâ\¯Ó±K3XæŸ^-JOÑ=àä3Fˆª’ X#ÙÄ½æ'ÒoÇ/(£ó8–¢ïè¤C[#€4åeÖÚ–­d£Í‰J©Òã!ƒ!ÑôïV/åJ¾•ùq¾	ğ•tÕ÷˜>ÆçÒ‹ª…N}hôOÓ((}C©#gº
k_é#ú„¨äXn® *œyš÷%‡Èp<2¿=&¹}FG'yŞhÌm3\8cĞe ßrí €o©ØÙ½¬KSÅÜ|•z%³q‹šºş´ùìl3)1 ÖuãàºM€º9Àjié²cå€h4oxÆñæ-0£<ò1d?!¦y?SªOö
&·@Ù²Pš‰ó Å2TíEğ]Àôµ™éˆ÷ONú@ÜŠB…*Ä€ûc}†÷Éú˜¦îRèµcÂ)ĞgÜy¦øWE8_ÚŞCŠæ.¯JŞ²˜{¨ ]k±%Èh =aüñè×'/ö¹‰–0åA=½®SÚ°›’ÄâF°2rQ0œ'&7gğ`ıPçÑv\7¬Ù“O*Õ)qTXåv»< n·Ã”Ò6ÑMñf@cMÒ›_Š¬¶øCçh!Àˆõ vŞ|ïtT¤¢×ë±9®ä‘V”!A©Ó#9X…d;‘n Ÿv·™µ«ì@œC½£]kšÉÀ"Íãr VH¶¸•[>ûéñœŠÈGbÈ”›C²@æ¼?n3m2ÏO)µ¬²¼>ş÷	ˆ*Àùü£‰T¸:¡İTŞKåÔ¬ˆÑÏ}›Å«i"ÈDvôÃ%’€‘y!¶Ïæ@Ù‰è.Œ³é„?eßx˜k˜Ü'öjj¥‹
çßv[F·/Ifmt¼&Ÿ³tYfÊ,TMBÑv<ÌEÃ~…¦ÍÉfıQ™pò¨?½²°.ôË³>»Å[ª˜yLëşt¿UŠtâğ]G*¥¾TU§FkUƒ µùè
}Š×à€ôè²äîE•ë™Qíˆ©k;Õ£*‘	¸±ÔÙún\dê"‘öÇ‰ÒU•¸¼È¶Mpã ’ÍŠÍ§e­áÖí“ÿSN+ƒ]2S‚³Óc >®'€¤€ê“¢ö­<FÓh´¯“"¨ºK‘æ†û….	—³ƒN„˜p5vƒq›J¡„-•ï7eİıªæ}Z‹“@*şÙßò…¶9¥Áy³¢oRüÅIİ+Ó‰ÿ€öÀ=™hË«Á?Ï/RDkª¶³úãŒ1rÎUÑ…ùC38-VB§WŞåó|¼=Ö2Ïl¦òF†À=•úMm¹(ñÁBv@«uae¶‚EMP8ı}¢ôj:)Y3'¸)€Ş–EL,Ëº¡IuT\Ô‚~AOÑ6Èø–XÈRñ3^ÜoX´u2scâÕÒÑ×ÖiMˆ(ş"Uì:QµE”íD„è6?#n-ª¯:CY‡ÈcDúLäE‘FfÏó¼QJ/u§§©¨<¡g¦ŸîQÆ?¢Ü,V§§~º ˜Élo¹š-§f„¦b„]UÊá^ZfTğ­&D0zßá¾dkK5"¶š­;^˜¶‰éïã˜¤äéB2$ö`½ö1÷f¼H¥´tîº°Û_à„®6 yF=IÈ÷ÊGÓôJ‰¯cæ’–9ÉŠ9×D}·É¿çÈ,a]ÔêşXöÊe6Wı„…W'èz¸Tã^²H\.½qÄ9S«lı¢V^`†Çì–>—ÒÑb!,D&!Ü =ZÑex—8Ä%'–ES/¹òQ¤¨±&°ÌÆRïè"Ól=„Ëk«gU5µ2¨Ñ<
Š‰ ›4 Ìê{ÄÉ~Á…:•½K)ãØÍ’Kâ.(ÉO¡Ù	{ÂÕcÀ'ëñë+İD9îr#n’ş(ÌA8¢Ò
Kób"!Ò¾Ú~ŞŒ7Ã¦çlíŞr¡%Û¬GuP§õyoöS‰8É
?¼Òv¨²D…^>aXŞ±‘dèM<]Ğçk·„—á6PÓßE\ëmSöHÒü¦ŸÜC(Ø8˜ww¸Wñè&Ê‚ñ?ÉYê¼O“d'}Ÿğnw(6çâtr}™o€â=B¢&,¬,³yŒjÁô¦u¿¯ö¹o’nÁsq¦gŸĞ°3³¸s¦IÙ‘7ÜU‚ñ:¢Øï_6Kò'?$\©%èx,İQJÍPæÆš µKë±3‰æøzÊ­=%Ñ¶’åŒ9Jû—Œúòc…ñÔÉañÓæ·àx–†EaØ§lÌD²¶6h0¤–°"X2	SàU;¼·ævÖn÷kl÷Çu7ğŠÓnÜj’Ø œ$í·*‰l¦øÊJKı’_x²j|‚]_‘4ÚÑ1ƒ¿Y÷Ä›â­İF'Q7µÜŞ–¿Ôù¹q~ÿ{º-yƒHu…Wó7@É‹¾dşÓ~7)§:.çgSQ|…hŸ4nô+Z}UXÊ-B’` &Mp•—_¢¹wYóbÈ:(V4$HG	#X#ÀoÚv;9	ZJh8µbâÓä€®™èÜ¥LÔBoîW¶q!Q•î»ÉLyRX´›t^µk•1Pe/Å9{½ç™vÕÙ{Bƒ€¢ôP‚e,Níi#»Qú üĞğb
İİÇÒ'&Rİ»âiÒp‘‰½uR¿K“½S4ˆŸ„*+B­Ø‚q¤‘iˆOÕÅ~“O©Ò]Áƒ	J´½ËÛØNËo3’ÔÖÌRöò¢³”¨†æ¢¿‘çA©A$õ;_ZÕşæ¨ÎÅ*çÑ´äiæÆZ¬ŸÏ*	o‚[ôOø,íjÔg†´ L"÷åâ~h K£ê­ÑõIŞáfŒ>&fšvs§÷Êä<2€¾P’©¡wâÒW7»­–sâu&CK"O,¨!—ÁÑë¯ı{Cg–š+øI62¸«¡Û¦u¤å¥ù t‹É¬ >[Ù™ş î`›\î¾nŞmaêã†UÜjw˜ÏûÖüff”¢ñÉ=ÕP]b+n¶ÆÆ“VC³9±­ñ'Ú5¹Ê‘ßHéâİĞ„–.ÌÉ˜Çy$³	˜(&¾9OQHI>7J‚!NØ‰®åpì¨¸Gõ~¢h‹	ÁÕ‹6p¥ ğâˆu²ÀDÆ™0ÚÆ´êwéızFÏ—apµŠ-àÚ5‰â­ñ–Vwr±Ó«›ıM)‚P»˜$„ò®fJüBZŠÕ[?Ğe$"‹$B“{_i¼	pæ1Ï¬©ãó±Òô3Ñ,0™ı¶Ëä±cüB]ì¯î¢…—úü>Ìğ‡Ëiz¬VâLH·gÄÌL‚M'  5 àºÂRÀ‚QœUBŸï|şÍw†{˜‘áDõ†­gÁDïÿÍèæ¯©¹¬®	:\á.UÏôö†oR©ıøØˆ‰´Ô³yS˜ÌW<ò‘:ã v‹ôoTşù«óyí¾{ï>şfEª@½Ñg«ÈÒ¿úM8‚]°ìMl\ù- ·é«Q+bèâ–&úû±Ô¡o0Cª9Ë9¯±`òñ“¨|$?\Z/Íİ'g×p;«jUÍyAÑe!’êõ.Ì·ÎkYL}Ö>˜NºFíş¨ùàq}Ï¿qšhà"%M
œ'¥Œ8YÆŠ-½£ßàÆóÚşúíÎ»³‘ N0ØVpüG>mcEÓ¡åÓ°W.#Ãï(>wq]’ôa>’½±Ã…[k ¿ágLÆçChî\dùVéÆğ2› Êâ‡‘¾¸>F›xÇæ	ööNÆ¹J:ô:¸4XHí'£@Šh­jOnsJú9RÅ—¡«öD¿%èLÎòP¬¥en$…¶ßÀÿ?+J	%;uœİàq½CÙ4¨‰f¸ÔôÅ_Â=:t`;7^ğRqñ+n´Ü¢X@ÎæNC°²xcûjWù]öğ:™ş]D_~ş6õUNˆrwÄKµÓ}æ?œ8×PÊd>É"à4©ğm/çø4UT_ş‘á³~Üäß¸ôÎ«åöcL+¬²åèàQßZt*‚n\s=TB¹»ç>ÂèR>c©" @ßÄ{k¡ébÏ½xò·nXÚûmÎ7L«ÒŞ•¢.Y¨1	î;ÒHçßâg¼.&92;›„8…ÀêõãGo]†I\Õ%[‘ÑÛ+Ù»†Çõ´ıÂ‹*Ïc†tßL _×	\dş0K#†XI9)_F±ßT›£ïu(¥,%\Ş«ßRˆeå
Vx:ş¦&Ñ§bÿº››!z$ó[)ïÜ%¼s” ËCÁå¹ZƒßóƒµŒÌ7ÈcÑ¹>ßšöœÛµ¯§ä‹´òe.HÖO%:8™VS IÊ†ş0Ù…­ É`ŒVPŸÖ|'N•AG&Èº
‡vñ"Ş®"xÁ‰OSê¨^¢â
$]h§(ú¾Öç‡šX•g<ëøµ)Èi<İ‡4îğ_½~”`äQ]³~ˆ¹<…åÆUNmŠÿ~()E‹Îjcş_‚Ábˆhn‡5´ÌšŞ±ŸÄn.ÏƒA–mcHGĞ-gâw¯ûãzÜæ«FãE.Oîß_É–—jñí´UŞcšô+¶€ë´tÿZWºÁŸ\u_	ÛY>'óİ6"ã-X€ğÁ¥ÅÆ+M;®+Şpà8!pYl4OÌyêâDÍáŠíxò]¤½yâıéIª…²+Ş/•51ò6ıÔ6h·xÉ~ÏäŒ:”÷”V‡·­°œ›“µ98¬ŞJM÷|ÓpqPé]²ûƒÛ¡(9{²êDK7Àà6y>/İÁDñİ®Û‘j-¶çü ÂŞôÁSŞüÎ–Z"™÷vkja2ˆu+²ÕpBxë¿™¹_âŒ|î¯u¼‰zİ”%xıÜ{¼üéÁhi½ÕPZ!°ñ
tÉÔ[ƒù1ùÌĞàÀ¾ÎTÇ¬F4ÃRÍÇÃã¾0à&Ä,xMJÚÄ6qqÒ›âÀÙ5”$*d4J¡Ãsj¶2^h³ê¥ğã5âèçÍ[L¨ÄËfÓ"ÁÑPƒ¾¨‹
ãÛ:†KêÊ™bş´ö“¯«—k>&ßÖz†¯õØ‡úÖ©ÆŞÔ¸N¦Ëfv QqâŞYæjİ*H‡cá,NFŠ²‘]‡x §±>wµcáÒ±ĞBlç·™ÖPŠ¤—&^†‘’¢‰Àò¸~r4´vV›|G  ¼$	Ş¿Nm–~S˜Lï:wÅiùñ>H¼®ä]­N¦T¥¥¨ôúÅxèãš¥Ñ[\ô|
ÔyhékÁR?0¬ˆğÁyŠŠñÀ²yÆ.ö³6'	<Cû2É´ãJ^Ûü‡Np9zÚ"[poÔ˜†nyISlÏ¡©„=a9¬Z¾gÁ›±¾Ğ½ìŠüäGp<‰óâáZk¨`½1´°z¨ôH¯siå.S±<­2&ıÎb‘‰xuú¾Ü–BQĞéhZÇõB¹}»JA’–â¾ğ£ØVî,VµZÜ9­jh‚4àTóÚƒçb1ã©‡§ä^#ÛN'[·`aö
-"6   °&0¦ërz»F7‰AºN…Ÿã±=h?v½s@(6'mÏáĞÌŒÔ°ÛÜıé;¸5ÀH¢tÃ}Ÿtº4Ì{™¥†@ÑÚE¬r9œ ²çªÒı‘óáÕ]F:¿_ùœåÙ´1ÉZ‹³¥mS‘~UG»3c¢êítlã…É•öÈ?í+dÌ·¹7İ3ª†sÏ²×U¿MgSØ : Ğ’}Cek„¨ÿXk\ùîíc8]éb#cg
ÇuÕx8è£/ÑÊj¦QÀH¥¹’ïı×ºÀAò»»¦Äò=YBblT's9Ã‘Uèí‹¸/¯Ão°†ÊÈ_”?û5MXrõg’Äô;êöï‰F4Œ”ˆ 	–dC‘bóÎã÷½|†3ëÒøâ”œ0åğ¾(¹®ÀZö`>í"¢¦s
;UÚ;¼˜™nx¾CH”=šÿLØœ±_a¹pOÆcğ“|½ü§b¡Î&ƒˆ£mËû[Â}7hÂødæ8ví…„“öfÑyŸÂ+zÏ%	İ±À/%máìó™7‹m>Oa§9í>?¦Ğ’uJ!sÃ6Z¢X5‚cæ;¦ì†!ª¤JÇ©¸äôˆj8ÁÂ	ÜÄ	he_ş}]nú‚e6ığÈ‡øQæ‡-Ûãjyîc›öÏkš~rCo¿µîrX|*òWTáüŒv)4øRe“¦š“3?Oå’mÈ<gÔµØ
UªÎøIòwš2éÜ‚Ñ–üß¿’¬ÏÊñÜvÑBnØß3‚	ï¦:ˆ€½}ãVF 8qYUûo£aøèuí~Ÿ §²ËŞ4ÿ“UÎÏz¶×L)ÅQyµ°t#Ø",7Á 4S¹ùèWà0E];R%öÿäE<\¾d<çv!Fx™B{ñÏ¾õø&MHc¥-ÕŠß3s>Òê­Ru¹lˆº}h]¹‹ÁcPéØ‚ºÏ’ÑLyA$>/º#`Í‘“–rL‰]³Ó¾ÎÀ-1;j8‡±™ËDŞCÓl–õÄaEò[t“Àˆ)U´}&`ÿúÑ…åç
Õ‘fÕY·H`W‘"Ã‰ºÂşøš|¡•QºòUÇ´À³TõG8G6Ko—ÇV^ ı‰÷ĞDè¤¹|:¯œÆ-	£½ìÃÖê¤7½A<Âi;´ƒ;Cò¸r„uz;(U†ÌtB¨àµQòŒWİr³c¶k³š,ïI`¯iÚ`8g¯.ß¥SÆODÁr6P?úÌû©×ÉÛ'rÌILøewÁÂÊa^çœ<2ÿÛîù­8Ë*ÆéQQÀqné§.Aì†,éKZæøp"	õX*¨K–hŠboha) ™‚KOÈ'€«`QÿĞç¸7{÷Hˆ%ø%íÙm7êh vï_-[åJÖ.\€8csnyüx£KßîÖ™ƒ)¼aÎ5åè+Lf˜1Oßíëêœù!h™iØíÚÛS	(0cZ³ğ¿×‚S0¬oîÑ‘~ƒ¡é·I•ñ{	˜^1œÓ#ãNˆ¾ ­Ç4 fÛqús4T´n(êÂôp¨a"éÙ#Üe×/’Å¢·Ãõ“›
üö˜ño®©°¯Ç$ólS!ØOo=nñŒp°Êí¼…R»{(·É„³Ğ™;a«–)6L¶q³	Œ8[üĞ¯ªÙ*	‚ÒŸÈ Õ²qºU‹zÇnv3LÚõ…ÖÙrcßñÒÌùz„•7 .WIf9íÿSàëpJ4ô~{íµ€{5Æ"<-Jûq¯ŒÎİtÜNöìŸï;”;MFÆ&Ù“N¸]ôdSw¿8
˜Ç³tŸ‹Ö¯e7‡W´±«ªNp¯G¼úçÕ^ŒŞı=.u‹È/«¯JÈX0½-ëY²@jŸyöŸ”° vÅzQ†3ö…}¿¨¨öçHĞ/9h¥‹@¯ÖÑ!cW*
F´ ¥¢úÉ ‘×Lt¢¿¥9ÀUáŞâ\¹Ç¢
È¿³­~ä‹{ğd¦óŠ¥5EZÃhø÷¸Q<şkGÒ»§d —¬jj´-V	ùHåK©zÑ3«"l¾×Y"¤eKØb‡25aîºq®eæ<{¬†UÇ§.ëìSÆi€Ğ-wPˆQÚ¡=¡Ä‡¯J)›z<ÃÆùó•‹ZâÑçS”L)¤äõ„ÛÜh†”’y|´œmëüÔ.ÔıÚ¢t7›«ÑEÕ`ïÍíFïï:T4m„&`ë~ñ¶* =ù˜ìøı3„bZ‚ıdA³®qK z<oŞ«::ŒOÅ¦>Š aı¶	Àü	 ÏCî\5æß D	AY
Ò­UiÖÊf¬6Ò»ŞúBÌCNqº5X†#Aİ1ÂvGš/¸{±&Q¢/h?«ğjŠ·!ÙkÕK°¿8©,Šà9^Eg™kj·Lrc-:"·Îÿ\ÈÑOp¬HÙÏ`Ş9PvÒWİAC´n¯3‹ä i/—´brIoÉæ1y>F¨EìÛt(xúè5›RE{Õ16”w@ÒÌ‡wr"D)$ÜW:ÖòxÏ\Õ€,ÑU­© IIrfÌ	X[[üô5Ï™Í'¸îmÉ[²âÍbö¸b„•Œ‘*†L×õ×%Äs!i‚ÂfÌPÊ®’
’t†õÈ(Fë.Ø "HC’n¸ğ‹ÁËÓsVJ Îz²h(aáå:Mçv.;êü€Şg1O6‚nú³å×Ow Nøóiâmª/õ#…‘1Y_¦làdµFR÷ê®¥Äğ[ê€aJÛ4¶ô¹s#¬@\5Š\;ù+áà„B9ƒ~Àš(”zeµº°”O	4‰7• g,#¦‰À
†½v ªGf‡«şy>%œŠšÖşRH?JkKÛx“”^¯»m°dN »ÿ”©¨ummúª§2ª NiˆÎ>ÅgwIÂñ¡ƒ9ø›8¢«A…{…™.övPïËÄÇ-%Ñ³+rïüÂhŞˆzŒ»P¤Q”£ÄçÜï„d º„â¹Æ´„-¬
¾œe£–èkµ ETxSôœÃ”[ÙØEİÙÌÅíP˜ğk!™ñò¥ÈSÕ[3cNÙ¨®bü±L9ó ÓÕ‹	m ä¶@?s¼€Z’
#ã·¯‹x/õå½â¶ÎÒYr~‡y™Å\™c¼‘­½?¦r•±Õ‰±Q‰ö0W‘:¹·ø¿Üë•Ucô­R‘&Åİş·ïªW¾ròN@Ş0êuÀ¢85ª”9ìm!!«åö0Ş:ìKAÏ¬°D‹{èYCÚe“W k~Æ|ƒ:Äæ
²}6GáÛ›eWwÉ×õÆê´fÙ›hWfšÂú¿BJ*’Yì.AÒó4²onf’ğ”¸DµÕÇLsoïß;ÀÔ#:İÄÑïN¸A
ÆYAvƒdñ%ŞfË0 ˆ…eÔ×¤á˜áX&8X¨}{ßÅë-]hPàË–GÙy~Î1B9ôÏS#ı¥i:ÅğŸnÌ’n&Ş-·N½Ô\E×¸Îo>C²Ç"V–ò©ÿÉ¦@¿_^Ü¾»¼{£©©a$óxW·ßö\şªøD–YnwfúöÎ‚ô¦¡ukõò$PÍ‡3tq#À¼³àIä–—V<Jûc‘nƒavàãNÜ‚ŠÏIA²3mä¹ë$­µå„7nÎ_vd}ÉÇ36´àz(U¿‡¿x~†=0)Şb-dÏì	A¸œš¢±«TemEùúVn…bÒ,RcÎì¤Ÿ¶ (a1&¯Ô"nË¦ñÌ¿Ÿ_ûgä¼Nà¨fİ©Æ…«S,ÿF‡UĞ}îÀGXsvDGX¤[öV{D-ôß|).|ÎÃÌSŸoPœ2½ºeüÄç{|r}Kı|ˆ+g¬òËVu\ÕŒ5Ó°Ÿ ¨'¤öR—ùøw y‡UL ³{ºDiZ[D–®÷úğôT‘cı¸çF”‹4‰×„+L¤0ÊRE¦ÎÃUªç¦Ñ¯Ëè1”û…¬=æWÀd¦¯ø•S0ë¡a#VíTª sc¬…mÇj½Üp½¶ƒ£L\cJf_ó éAq¾:L¿$4şºö#"/b Un±› «ô\?áàùWm
W¯G-.U¿ûß…‡æn8u*ªGÊ=5S.«sp]ãaG
èÔi©F:^Ÿ¬Ò­,Ãë#z¸V%6§›{óHñ?ˆÖ×¿`ˆÅ=fXCˆ@-Ø¸
;3€Ú	ÁI¡=½ú¤¤&KNÜ>U×Jà•\Æ8IÚ}¸€1u™$—xİeNÎEic@[ÈWÓêë¡U‰È ò~>‰~%}ñ®4)HÒI¸Æ1ù!n;a·ĞÖUhôÀ®.ìÄ{Áä‡Ï İ+ràdáĞ@Âé)‚y¼zÊ}6ªø¥\"D]Î‡Ø‚MS†&ùÜ¬œmÄM››UK–|€zâ”Æù¬r‘€ß\£`3éìvá3wÜ2*´´Ò®€k%G7ÊúDÒô‹dä~nbö¤•«´4ıq’]Dº¬6™aû«Ösv)/5jæ¬0Ö„rY†1›ëeqŞ2®µöš+Je.^)
ùU¬âÄPmq±7í¶Hh§du	ˆ:=d NÛ\g»r6XÕpŠKl»<ÛUCüx”–fâ#ŞrGú•ïÅ,(¢şòùgc¨0…ù™š$U–&1–ã¯tS-ÙıÜD6ÙÖqMªßá‰1™È²öºÀÂc~ë¶—·W“Væ³òóÌüÈ)K½ÛËPëè­Øë|1èø²Ão6úÜP/æ¦Ñ¬ç3× è
¾ªê+•øãD1)±-ˆæ°Z[°•Ú½î`£·ûrcF`_¼ÜÍù Ş%Ã‡ÊÏ Ó™<_W&UewønË…ø±uXFÍ’ŸT‹ìÓ’L'0ò¡©ÏìàÌ˜ÄÖP>ÄN‡tHİ±Ã=µ¶\÷³³Ìy/}»½úˆ%ì´e¾tõ ıp‘>Êmœ,‰$¦ÁËÒ‚¡âïèò©Ä$½˜Ó®	
§ŒUï÷]øóCn¼¾ı¼b¿õ›,Zˆéü™µæyĞ…@“h°¤Š­¦aæ ĞÅ©ÛÏk±-ß—¦¥ÆÉJá‰¶€Ä#àêº|Á°òAÖ2x¤›’SRºùŒr÷»vÜi‡im_ÓX“ÀâÁ§…‰Ä8RØ+làw××9án¦™»jğTğÙ¯`ögî@i‡ï©¾¶‰àF¢µ,NÏ;9Q®½Hq_·’ùäÈÔŞç^Z>]ZúÜõL“2un&0½‡Êó Âo7)³‘^»bµ]™…´'a%{ÊJ:ÿß½rŸ
W!ñĞ5x‚È…(Z86¾À~Y³JÆd¾qŠÚRÑ-¦‚…'¥ÕhSÄ¥u±µ2·fóŒ~ë;JğÕ<îÜŠPe¤hÂ¦ŒøÁ
 
nk­w÷RöoäĞq<ï\xsõ‘şæ|î¤„îÅy‹%÷%LíÃÖZ? –nB.ñ™Ñ,LÄónšÏŞ%Ã ¾Gj÷Ì±D+ˆ–‹ÂİÖP«Ü	0Üøåù˜ßÃiØs»X 1ŞÅ¯,o±iıƒ&—@ß-šGğ³…H¶û²'9QÎºø$(ü·ÒH+è÷±ùe“ëÙQü=l|x£]±¤¼~C3İ3´oA¦&6ÿ4ò¥¯úãÜÊ2ÃW¼õáéhõ°]"¦âô†ÂWæ7¦¦®gÿdƒTé,øV\gÍ[¬QQxÁ:¦zXt·5eU`2„®…“¥Ï!‹ë·Hp¢¯ÿóÄ0â LZ”ê”RŸ¨
¶ÎŞ‡1Íu~ ÄÒ‹,ÎŒÃ¡¸‡U½ğÄª7î*ñ§Ï,Ñè‚Ö*Bâ»ËÙO4:2fIagÅíúûÏ½ĞBlø.-¨ $\ÛD}v2ö ^D·ûºüº?°'£Ú¡An">3}-N7öbj'ÇÊópß	èĞæ@;IÍí‰OĞÊ-(Kaì›Lv3sk~ ¢Š-[ÛeëuÅ.cç“áÇ·N(0CdÛÛ1oıëo¼H¬9E¾ù(Ùã­cûSrxòÆ{lO`§^ë× ’?êğÃ¿ç9»ááûŠéäFÉ£mY±üæèIöñæ`°ıSÃ5kºÇût'lE.{¿ø@<Ø¸°‘wôÆ‡qw¿	æÙÎ¦Êõ#0ª_SUncjD³uAU¡ÌaükçZ²³¸2#Ío»h‡–Šèÿª³À­cÁú¬—	GxÅLû¾‚hã##uÂÁeÑö…§<9MYÉüù6Œ5|Û2ö æ wæ7w¡ÕàÇ&!ZBî&«‰Q`¼S>%%útû† Z˜0U<¾™Èt®Kæ«S¬ñıœqFëp_ñ]œÈ˜'ùÀùÃàGCÏ“^•†ßmíáª¦‚ÎÂU@ri„2vHä”:©-¹4@ùï¤…U·xËr_õ¹£ÿö#»§%oËü Ç´E(ŸÀ æmZ0¨¾H\†£ÔJEaª«x¨èR*a¡ôN¸ÕíéyÛZ&|F¢k¾Íï®ñ)ì™skeiVÈGSÀKNm‘¡µAëVÒBz‰/şdšªå†õj«ğ ßCm¸±sH«82«ƒÀ×à{à &ú€1£\`²†ãıxê#°›}íOÜÉÉî×B6„Œ·#ìyPıW­ÒjĞƒĞÂ2ŸSÚfÒ»pŞìÙºí8)–¡=xÎ?çà2¢Šâi.ŸTÁ
‡©:¥îÿÖ¸ Ûcô¢Ğe³òkíåæû[¹ßìjÑ;_›aKßLÅ•6¥½öªª»3lF`ˆTO DÀá>L{Û'uÿÈ¦/JœW–°òß•H÷å™4¢Fo[@uvø?|Z‰f›Iœº—…´Æ‘ÎŸ:Fby‹ô%¢åqø®íØ°W~1}[£fQ7Ğ¥ Åz¨Q«=°…c=RK|ÆÄ÷A,	";é² [·õQ„M,÷İ=ÑW§ı*ÇÆ³G«å!sxyEæì°§#ı{7©Ê±×´É}w(>¸‡G»õZKâØ[B‚M€xK{Q4úh7óöMgğ„Éj«QUYÉcæÎq9®ª( vL¶Ğı€µ„™Àw•ñVàiÇ|IÇ³¹qšÁÿşƒòP²ÛCçš¤[>åJÕçÕËğøÁŒÓ`^kEµªÈzy€˜ø!!]-ãİÆm¥d÷sAÚÍKğ°35_dV=S4C9›i§3>ê$é2š¸r)¸‘nàäEÙÛUN‡yö4!MV·çÚÕ½£;ÿx³%usÔšÎÑ²ª±¡ŞHŒ'=”VÒMVôÚõEÉƒMà±lñÉ»ô¼ñ?jƒuÌ¨£;Ìo£äû}Ú0µbÁ)2öĞÓ±eSà¿7rşÊ]™”¦ZqRÓZ`UğÏëHÕ/•©ª«aˆ#xt‹NgJˆùÃ­;c»ü‚^Á“ú$æÍ½°ÅÂ˜ù°V•¢%¯£Y”.ÀœkÔúäLÓ•@âM‚q¼NhÖûıIIxİ·túà«"ØÌ]¨¤,MÄŸC‡çOÃDÍKkH=â±‡LêÕ´ãÌ—ávÉ?\AÁ4jÏtn«Ê³ ¿À£ñ?Ğ™5<îğŠiègK¶§Üw”û¿¨®h•3j¼y³Èıìa»Ü°{ªù‡œ![AèIßRâY£¸Á»çwtÿÒT@5Ì–VĞZğ<Fx×ÇÇWË1ANüÍ›Ô	4XøTñáM:nÿ ‰#µ2qo=Å¥<Õã0s'ë2”v<\¶ÕVWlŠ¿h6¢Ú„[ü,St‘İ¾Õ”ÖàtŸ,Ó2†‡v)RÂÏ*ç¥;vıü¢ÿòóĞj|Â£Çv"è–eäÜ¥öriØy€g¯<¦²±æ¨Ô‚ õpBW—?Éş@P÷D½»eiån<{©.D]zºÙT—+€–E)@ùÒI…0Š"-QhÖ‰œ68¬ûöS±¢!_õ0x-)%uˆÛÚ=º‡BiD‚¥•š*ö°>¦,ê>áxov>‘0©ÑĞºşZò1ÃtONÉÂ6£ÇAŠ‘º§ñ DÌ’öAäğ¹Ä˜p‘°ş²’Ï¢{èŒ(1¸:?4ƒŠ_^û„‹ğ°,´Ä}Aâ—½ƒÑ~! 1“ú@º¢ÒŒ>Åe2í¡¸Î“ŠKÿfµó,e?wáeM(ä®’i^—z!ò¡$¤è;'ød,é¨Ñ«0ĞWT?qÕšÔ.Ÿ:3ZĞÕ†wYè¬%IÚú¹§“u”ÓØ•Ú¾cÂt‚ñO-ÉõEO{`~è÷îÒÂqÿi…•£RcdˆÑ›d2ÖÉ*Hcàèµ¸QÍµLâG¥mT|®@İSå$Í×;xûë®ÿå¾ÚyÆ«ÉIT>lBTN˜ûUXÆ±lõe‹YŞ2¼û·V·k{ÑõÎqeê±ŠÍ•„aéã»p
ğN‚óqŒzÁ&:ÙXE¸Û 4Ã~©à‰Û#¸9F³-ièøñ‚Äô<–WS¬Ä%LŒÌêä#\`x
ª}Ğk0ª‚‘ë¼¢Šè*æEŠT;¶çÕ‰ÆTnÖµÎyÅ>s³sğ!=óõ>9Qäı ì$gC0¢¹òòÓú‡_ZéãµaDè$‚'>øfóBCÂéªŞlİ4Âù„’©™&ÅBÂ‘!Í¬GJg‚D|’`˜Û”–9ÌèŠZ^g(|»ØŸ,Ù&ˆ…`øˆÀh&DdO0YµoGøÁ¥ú)Z@ yàCÀ˜Fô·ş®º©O±Ñ•æ6_ù(.8õ†ÜÇ2ôüH­yJDp´”8†g´`ÖŒ“eŞc7DÛíş>SqÕµ7½D	äª$ï®·Úm ík"³ÇÕ,IO «Œ‡A)IŞ?W)µz7ÊÅUXÛ„“èIZÂ´Ña—§à !ØåœÈiu}}[?œÈ«úŸ—ÒD
Ü<sİÆê¬’¨nA JÒ<Â§Oûß§+¶;Z„_ÉŸqWÁ*$¬ÅÈ¦ÿĞé¦/¸^Á_ÆÄÕV@=nƒğ¨}1üO^@$ƒŒÓ„…L¨³ÓaNˆVÑ?÷÷…xtøÅØº^İ\2æ=à—)J°š@çİ$¡•Èç¿ìe¢±Ÿ~ßYäykN¨n§-ûi¬fä–”¼8WöSå–„9£ëWI‡h…
j*bo_´ Å=ÜÓPIJõÛÇ^lû6’Ph•Eë:Ô‰CìxQ‡İ@^Î5”‚ne3ŸVÏĞB[­MGUröÚJ(FİX×û‹îÛ¨kON^ôİÕY#¡¬ü\´Á÷¬-²°Fz
ÿS¬bB:[ˆ¡ê,¿=áµº·Æ0"-Tãmff!İ9xıêX1±¢‚M^ˆ²z‚…’6W™ÀSS!ıq:º¬¬$._gY@,Ø50{r1„ôÄ]Š,û¢{Ò:ÊaşLõrGdøt‰E¥µçíø¥Ï?—-ôHPòwµÒÌx*
„Şt4ÇÆ0ñ¸U
+|Iñ‡Ç“Š£ØpÔqK’3pâvÊyéªÚáäÚÔı4IxÑˆ]©5)ÎÕ(qÕ«ƒ2ì’…k»Y6&)J…Ê_?á ©êù;²ú+…Éu¢ÿÜ~ÑY­Ç6£Nß²“§¦Ä=Zv"Ûx}âVTŠjVœK}K$"FèôA2wç´¼ÿ\Š†5G_¤eS‡³óG!W9-ÆÅpG±1Ôûİå*[üs~jQî¨œ–0Íâ•#«Ñï ã&ø²À+Õ3T¬/Z/VyşÚ›¼§%Ö¨înm>ñú[¬CõNQ‘>‘ÎçÅ%¼BèC¯‚q[òõ²ÊD:vº™uc$´ƒ²9ëœ[`¥%ã¸é§“|Û¥ü2·ÜŸ:±"·ü ,ü›†}÷¢ƒL—UpÌÈõĞ1ŠğR•’€:B³«ÒŞ´¢Ø»ûÌ‰ èÜTÚ¾ Åö
;¾Hm¨T‹Î" Ûª‰îHôl˜…1B|ô_(YĞf˜g1gªO¤C«}Ãô¿Ñ7@Q%Æ¬\s5Àê<¥z=:.Ğ?®ÿÎ–Æ;M½	ˆŞMPQsÿğÊ8háÁí5’©7¸üF=şlÿM5î9`uIõµL>X°{3´]ò§Õ
È×Æz»Kß€û‘2U9zïı¿•’F×ó*çtØ¬,4$ò
§ccjO»¬rŞ§6nâ¤tXÚ\¡c3—‘âFÕÇ½Bµ™sPUO»u}.˜Œ…Dl‘²‡HKt¬O«o‘Ï[s¾«A+ß×B¡M¦£‡&a¨÷0ñï0g®°”ò*ıÌ@hz™¯cçie&ÚÓ†×ƒ5•Ö…â¦Ú¸rz¹7;)Õ>¡úËs~U®O·÷&0äƒÏ9xÒ&Àìñ7ØûC;
ªò·0òÉh@*Óœ$C¡Ê†6¦’}dx]‡tYUš¯ÎëÆUçØ¼{Åø®ÈË¾˜§Ş-D•Ğ.Ãğ^ÊËõpğù#“ î+!
ÏVLëÒÔ‰(•¾üËz:¡J´åÑÃÒ8¾ô°<Ñz/e™…˜À±3’l>L¤£G@5ô,?Óâ¢†%‰ÿ>ß$uş\W”¨?"ú7)Îè-k´vw³àør½ŒüD ı+#%ª§á<Â{~ÅÏmøLSæ}¦yÑhåõÑ“Õä¥ÃË¤/ÛÉXbÂÇ»4;©Ï]ö™Â BkÌ_`Í£¾[V¼JY”1}ß™…äuı,úÍ¯ö(%>ªÉ ò¡ˆÒ>ÛcĞ pGêUÊ*+$ëÆÎP×yz9Ñ¢uæ”…òx\0K0L¾èüî‹!dÖúçÇŒ†ıÎY­¹htOºNçt‘håE‹8}+S0‰„3ÀUÛK~Ïœ"Ÿ¸(GÒºº_zÃ4ç`PkKz˜gsö= )÷iù©Êràû¾ÀÜîOÊ«XE‡ê$±ˆ¿yÏåÊùpTº~„mÚVÁ7u&NA åCwäÂß2©@4	ì´aMÈÚòtàœ
Éí
WÜ†y•§0#§ñzãô¤Ë¥·SŞP´‹ÑÕ’n:`©ú	j„Ìb q?s¡ÄÆÕ!$ã_(¦ùo¶±‡ âşêNèëÁ³ƒÁ–©©‚<‹¦^†EÜë^ñ¾×B	.b‚	;bQ5rš9–ôÁ}Ú”İ¾,ğÎgt5z=Ş0-L¸›„ÍºDygÒ¬ÜcLf6şEôÚ¨7\†sç ²ùÌ‘?­×>-İ&7xõÄhœ®òP¦1¥XÆ[MÛÈƒ
í]Ï9…n 3€>¯5ÊAØÏ/ÅzQ;ñº·Ÿ¦!‰şä0L"qÓ®3Ój?»Pß¿¹€ì1ßºÛ·qÏÓã¸¿[íT—„R2‘îù@¯Ë›!¹®^ÇvEí“Üt5€Ç*îFC<&ÑKYïCSòg¸}S$óz‡vlÑFz¯I:¢ ”U#XŸ×$Ä{¯á;º¸ëÕË‚çØÑC—»õT©”£ùñ8gNr§5nŒºÏÅÈSÌ]õ@$i"t•îßvXfv=â–Cì÷•ï`JHì3¬¼½+ö8O™Sw ¶Ã>¾ÅMŸõºÊ¯¨¼e÷{®8Ì’5rqıq¤=p®N6äD}k!¾MÕ?ójÉ^öÛ ¸2µC¸Ò—·Cªª!ğ‚‘oüÿãİ¿Ğ!÷yçÛ»ÀD,¼Œ^8%M÷s+AìÔõîç¾!áM©¸û%à‘â½‡•¢p×öÉçúb[”ãõŒIéWˆvs¹Ë½®)iOˆú{¿'2aF–nwÔTvüs¬œY©\)A³±`Ê a@i¸ñLËRÑf˜U’vhê1¡S‰W,§TCD›Z¢EúU¶íîZ8yœò1æ·*ÚØ*MwÑG4Ù_íı9İ³€±P‹×®ösd3qƒS?[¨ÇRS?§úófå¶?6)˜|Ë|Ì|d
Ô$ŞEÌDvj®ƒ›{!øğr4ı¶g=]°>ïr¥A	æ9!~_¡İ¤•Ñ˜Ò+
~ºã “™ó†q9m
&]J”Tš.ıf1‚¢1öÍ‚(‡¤Üø¦›ë©›>†=I‹p=@Y«±hÕ6DƒYpfMÙT41ÀI°üS]L_vÒ£„QÏ$Bbsš-jÔs¿z¤šc€ıjİ«Pı5„m±óüu°ëi¦¤oÉıäøƒÈÄ#4˜œ§”ÁC—Ñ9°lÉÅº¡qŞèñ‡,Õ¦¿pbFS_ÒeP¦´°İ
ûÚWßFÕ XãeFMÒs‡D›Š Õ¸£HNëC+ó”Ìx¤Ë[ë’¬Ü¼#AÜæ ªüCÔÇ®â”%r®æhz;OgÂ‘ìÊ Gà¡ßLâº§ˆû+?ŠŠ˜Ï?Ik£rf°¥GÏ(Ì´½y­/¦½;—df‡eªòÔ5ı¸7Û}ô-Áì¥˜Yh®´3º	bŞ#Íß¡ğw—^O¨ìlvM[Œb»˜”‡ˆó¾L¥æ…ä–½±X«yÚ›“&i³cŠ§>Ày7é ŸÔWiïcâÁÇ’HñEüW Z‰,T¬Ï0V|(œlğh»¼b»®Gşe£äÀ<à`´…@€®ú»ÎwQ^öO{ÏJHkŸõâ}£Ì}ûkâ‡=7­.„ÆJŸçuóêÊä?H!|¿»¹îoUw7g¥é½>,©CıkPZŞ_&hO¯G:å);_éı"F"\–ƒTÚf‹×…+Ú^å©õÌ1 Æ£q»/kÍëÑq:Ë) -ÏZoãK#Ìî­ƒˆ ÛS+‡İ¯–ßÁ=ßŒÙf.HÈãÖ’’Ô¸úäTo		ÑÏÇû/=ÅÚíÚr" n8ƒZGÃL²œÓçºnİl`5h9UğyÛ!G…Û—0còèmÌh¹Ş»Ë‘øå/js5o‰Ü!êH£¹5˜‡
’¤<Nñ4~@­b÷Ùò‹Ë›	ßÓÖ¢æ'2¶ĞÙfMvK^ Ïy³ğûßÈ[ A°•´•=›B¡rzËòS›Åå¨´·®{£\aQ~Ğ¸2öñä²·ÿâS«&¸<(Z€Ü£Xïh¶[âäa£«Õ@”.9¥B'÷:UƒLIæ˜Gá{OaL4İMg(ãdÿÅ¡)×hèSónnÍ¿§A×Û3 g!†<Û&€Nç™÷¬—İÈ4‡šU“yø$=%Š‘k„Ç¹È<SÎ>7•Dü£{Š»î²š1Òè„å6ÀKá¡Úß»¯î˜.YKQ¢Â£éX
ù¤Gp
»4×¢4{ı‘:<:Tùò—µëyYÖQ«*İ™Í‰µî°HiÛ*éèÄI1øM-±ELTß»‘5»¹“\[ÜUo‹lÊ÷ş4á2ÕA\ƒàz¨e ‚«ğ57šz|Æ½÷gĞ|¦ÌÓÂ:š9]¼ãR)Q†³K­t'7è$øÄå¼Év‰6EyFoP˜¨†Øì©ÛÅ=]™”ß·Á0ÌxzXİù7Tù4@ô
SYÓaÂúx¾h/²‰Ê	¯÷ä‘8Ó½*Kü¤GïÿÇ8'Û³e‹Ú°™¨ôäqç€	°<âé%™ ‘í®,¡›áAæù!’q2ˆ4¶~X•-[CÈÏ¶òL^©@~¥óVëk ˆ#K"è3û¥„j$â+ãˆ~ØŞm!í2f˜:¹(Ä&L„>7î9É¼êmÑoÒAewIEO<ì¤}ù¥¡‰xÕe€wh«Â¬ÛŒÈè›ÇDP[³Lô`û«¦i×$à7—&àP\AyA"!æBÖ‘„şq]´wŸ Æn¼+´–xDEg)omİÖÌÚVHx/#§Å
³ëPÉ21Ri9fµºFƒ'õEd¶îUĞÓ÷+š5Q^Yo)_²·$x&Ğ,@Tëm¾(<=Wøçu	¿˜«\Ì€„ºı‚ é–Ñø‰´‡@÷¹…Ê'X—Ù]'Mˆµ‰dÕÏbV+lÜOî€»Û¶Š\Àx˜Ëb@äl˜ˆ¼Îãî¸à…fÎ*Ò‚¶Føúáüà¼:ö^ÕkØƒ÷(ş-–ô§ ½Ü¼ÅTsMÜ·c»óFån%ækãĞCñ`N+6>’r_WO d…¶¦	æ£$Z³LCák:ÚÉWà%4öù>ßZ—e"ZÍFœÁİûfŠrU0se”g¼³ówC!·|<šıb«ø-dİ	çâø\ö{bú«†1õ¸÷;w%‰¨90ÎˆMÚ‹	'íµ¼4G"Æ=Ô÷µn5<]Êûı_éåó'o&)šw>y±5ĞŸ]³9ãÛe®'^M|*:„ÜŞ”‘Ö íVGôôIzÌ$zFõ¬®šIİÉzs8o{6?”.\>’vì…Õ™n˜I-o-`lqÛ ğÅÈäz9\N nhš¤ÀŠK1D±?x)û ´7è†Å˜[ª-Vg®}{PÒ}ÊÖ
2x
Ò@i(ZºÏñ-(q¥”¢”S´·Õ=!è˜	ï€şV?a ±º2ƒ—H¼Çİv!¼ŒÃBMry²yèSÕ9`»]Ã¼‡ëÜ²¥bõÜª»SÃöëßMı#MÏz´´’‹îÏ¸Ìöà¬¸äW´ÂŞæq³_¦ì÷P@Uq»ğì1è¼ …ºXñîuûİ¾}Ây İª‘&Sá+Óùğwê‹
›Ù\a4€ ­]š„0t+än=[ğña£Î×‹¢u äÔÒèu{w^JªKÏ’6f BèM’Ä6‹*tWª\ªn2;aüDò#Ã2ÖgP±+ís“÷×ZÿEÜ]UâL£ê2¤f"q˜2dBºß‡çŞz¹ÔD7©§›³z}ĞĞÈ–Ä<ù·mÆFùù»86»cŞê.¹ÜÏ]Â=goµy~x¼["8Pó¨Ó ©|ö•K ãev”¥Š—Hî9|ÃÏâ“>®Ù§äÎ&H„±nXà6Fı°ÀäÛŸËÑHU³£Mgš¼µ¯MAĞEAÕeÜ€Î:]Fí—ìÊå<ÿ°AŞ°¢zòêê´´ Ïã¦l³&„.çUtñ6ô…k¾Nh†%Nqå†Ğ#Å¿ß¼…¼½D‚b›:¯äC0+>Z_ˆşSBJaÏu	aI\Å/&ãAÍÏÜP§ş»,ŞÜ×O¦ĞØ´L€§M’¡`XÎuÿ•ÓgÓà`Mõ#äK\Ôä¦œõÆWá±#:RåXğë.—•ÚyGo:Š»/g¨ù‚…naŞ-ŸStˆÅW´ºcÅÜ/†ÃÂáš‘@ˆ:$UÓ¤xâ%jb…SŠöÚeà€!ÎG-…K7mNÎæÀ\5µ}ÉwŸ˜^.­ˆ2†z2ån€°W¶¯†E•Ü²pÇnu§ÛÓ´W’4âî*V/,'ß‚êb.·|¹@;nW€ç—èõ…1båíœ~ èWU9æatµM¯h6K/ÍÖ½¬üB-¨úâóËˆhg'b¡£±Ğæ;Ášb')‡›~ô™‘•6\®ÏvöB{#;L§ÇÎ;¬ÃˆğKa¸”i(¼€EÇ‘é	<Gœ
Q£›°P»t¬y~,–ç\ïŒ@k’Vg'GPy
ªG9D0ÃêğŒÂU±Ãdæ¯]‰"]¦ïK®	$äEu	ş†ªêB¯¸­Æ
ëœ¶ntÛQ’EˆSÌÈXIƒè;„ñšğ;Ú'„Üı8ñ‚ï³â$/Jø¹	/Lû%:xŞïı—ÖshÍœÍŸÕˆZøÛñ<rºzjpšqnä6ÎF	ÔBE¼=ª¥Àöº4y¿î
HbĞeÎISoè=Ğ“sÓÁ§Jq•ù—›@¸[}]4‰P«¡{Áù9Ÿ®*@İÁõo€}¬'ë‚k¥õ
×xW˜Í’+q)]©Äx¥Õµo%B–egiø˜…âÄ1Æh¢Vµ*tê<AjƒlÎl²óe‹*æ'Ğ]å±¼ö³—3¤\‰¬º®7$•şİ÷Tşù®6š^à€Š;½Äè•ó¸€ä˜ŠhšÒÈ,–ºÌæà°Õ¾sì}åÉ³ï,uŞvÃg%´õ@w)Ôr…s8}’ÿÏ+1ˆµ ù‹¤~D½‡h¯l<C¡âƒSeıŠŠ¯IÈÀ-œ¡Ølnpj¥ïC Æ3)ÈÁX†À>™wºS)Ç.~éî?Q
=ªMıÖC7¾2òáfG©ÆÒS<0b‚ÍæÊ….dJIÕKªÔá}‡¶éH—6Î‚,^{wğüXó]dzİ5ç’&ô9Q±ğ˜úùXwv-üYİ•\Ù2AeAP³!,DÇ4ÖÕr·gıÖô‡æñ›/âx£ëÒ¨çh&pœéš‹×ï2iØ®ljıÁÛ,×F@Ôğ!ày² 	!©WHË¸¦u‚¿%36­ö[Ü:İ ¶÷?wƒÚRÏAŒxjáÑ&	ß„g“«ûÄ•PIĞª4ï¹QM¦ÿËVŠ€²ÆƒUké9ËXÿ×–ËSóÆÔ½¦Í
äE–ÙeD¸W]^I˜ZR/&>”Ú#j«Õ[ÊJàÅÊáŠ—ÉÜÒû#?ñGv“D˜~M°V¼½0ôf™   %%'HÍI˜+ şº€À	‚­º±Ägû    YZ