#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="753068703"
MD5="8b7844fb40489e7aecc620084585990a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26016"
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
	echo Date of packaging: Thu Jan 27 17:08:09 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿe_] ¼}•À1Dd]‡Á›PætİFĞ	/MuØ%_¼¤T™]ÎñÏReS²Â•²¦$Ï–›:‰ÏFHÑ«Ì6bM|Cï@¿úÖİJZƒç…ÇìníğXÙsÈo'Á¥,ıó¬¶˜QõHÖä#|®÷ŸË…¶Z5l{ƒœÅ—Øø½¢»š|ş#2øoSÍ>ÇÒJ$AîSîˆÑæôcÓß‡ƒU®øR¡% ÉÆ†EWÄåëµSñ’xU¢ëä“xk?#©Ñ¦˜RØvé®Ãœ#Kî—•oB6l6¦<›5VÖ4§íó¨X„ê{Ş†(ù›trB5ç‰yÿ3%y¡$©;ê7”©oFoãÕá´©/¬şkŞ†î*öÈ©ê×tËÖŸ¸¥€V°‘ûs‡]öà:¸»Ğk2„£…9ÄÈ¿Jõ=¦\ì=JôÕ,Ó!­­WPzcAÔš¢›
rTÀĞVm P†–VLWú]x¯¬×¯oy˜9ò²>aêöfkÙFô½&¤ ˜%èËÖÚVB~vL`ÿÔ¯6×7Ti]áÆ§/H‚¾?ÖŠ•“Èj£®½à®ŸÙHøÏ…¶Ÿ“(…	~ê¦QxcäÑY€(»ë½B\å^`·}1Ñ“ÈcùâêsØåj§À¤cb#[k†òë§Ú	Ï{iV¢½%şlv¶ñq*ÅëÎ4äxó.•vˆº°ßÔwÙb¹_ƒB`ÒV‹œ­gşÀ8.pĞ'FŞ½ÆDÖtğâåâO|\­‹ÖíÎ‚ÎÓ=ÀÖ#í/¦¢]ˆú »ç€x:ïDc°DÈO˜ÔMo–4óo‡+¯ä
­ö»4“Íøó#ïùt¡v¾«qE×©.·$AŒP´«` ¢K4:H„»ud¢0äf1à4ßÄ²›ˆH¿Úf?ûÒš¸c÷¦ÒÍuX‘PÙ•É±ºS×€Î.flÒ(ÿä%… DGNq-T85zŠÃ¬_”,ÄdcÎ¥òŸS×,kuç¥É¡Ê>·woÈ“rİn4á÷|(ş±ğv¸’ÑÌVE˜µ'UpéÎ²­‹íâ¨Í}á¡¶³ôĞeÍöã¦`ÁÍ2ãüıL¶ƒÆw§Æğ<Uµ'ÒÑñ¿í=™ù³fÑñçÖîQ#–':¨zÎ6„é”¢&±ä|B•Hs‰‡Şº#£ÍAÿš+®†ïÌíd¼nmıÏxœ ")¼]…Æ½D—òàL&ğ6÷Õ)|(ª½/œå{É§-ÒiÃ=Ğöç™¾`+“–2³1·Ó´!Y,0€wR}1,¯ãÜ–x3#2JT„Íe7*–=oâªÛ¡`c-Şy#æm9ël¡ÿ5³û×<†¶ o:ˆ[º¯O¹-?uÊ¾˜Û´ ÓÄ.ìY9: Ö¶
{;ÿ[®¬ß¢¼ë+ÌÆè[Í(ú©½À}á+¿tÊ(×Ï,´£s1RŸå-­ÚĞŸ(˜U6Àa3Íae™ÔæŞÏËÌÄğJûQˆßºkŞØ'T]z€FæÛÚóïúÎ0ˆÚi×JgöØ²zh”:|YÏbæ‘(µŠŞĞeª›İÌÆÔäªzâÒ,œ¿a£6¯ôuåşÉùÅıö¯,ìô¾œÂ4s¢}Õ×Ö ±å¨RI·>ß‡mRT‹h ¸†MÆÚƒÒ#Y{¿ZÔk’àÃòì¥j(I™Í^èV¨¤âÕñSwUá†šHèaj­[OÁ`Rå<‰ ºnÂµÊ§œÄäkÂ4ÖÏnwØApóK‡i3$îÅì7x‹;ër¬@/¼E¥ÏÂÍF6ùÁ+UÚTOï/¯X‰æ¶§â+$~‘„ŒbÿzâKšÖ#rR¶¬ºŸ™M\ÆRXÂÎöú„'ò¦eQ
Éx±¾Ì»¥).ìLè`„}.CRi¨ªÔüoa•$ı£ õ¶góª_ş®œ`S¸[²}°$n¯-†°”¼kšô¥4”~Ë]¸à‰H!.û©zÉ³Œ SŠñ“Oşb£âm}Æ1•VÙWğ§¹–,æt­¨²jû¿íÈ•ú—º¢\,6ÂîOş_,ôpº»'H›—®w†AÑ¥õ¢±èÍJ»ŒÀI)Ü´²mÚJmrU'|^1Zê±m
XU´µ¬ÍqYÈqÑpÁV$¹ÜªıĞyàfKMn`v tá¦KÉîmçyQûdñ	â0%\W”ÑKn¥/J»„Ùb¸¤±Q9¶Ó†
`˜øíÑ/~,O~ v8§YÁêæTÃiôAˆÅöÂ`!•·•àâµ”–,)sA¬“š+	Î6öq¶Â!« Ğû¬Â‹‚ˆÄXëWI ¤ëÛ‘?³àVŒTIOŒÎÏA"éİâ@w¾ŞÔX¨|Õï§p ÁFšÂµ•½kg¦¤Ú\ZôÃœ·U>jĞÔHº?LuœÊsQa2…Zø @8Íæü3oßw„µ,€Ù¬Ò'üıO|á«4ä±ˆ­Í†¼˜Úx¢Òıé8·´iª¾_İ"¶%ãF£†>	csÌ\EÈ•0`³ï ®£AºhOs„ä©xôG@9ç(¤KÿóÆ„·<ºW†İtJn6åòøvŞ»–%E7÷LtŸZpI¥ÅP¸FKD/fÃ¼AR¡.Ì€Ô¨¿[YÿKI))İ…\ËzJ© !qÚıˆºÇIÉÉ×
AÅuÇ²¯G,",b%½B0* cíD5{æQz²Ê‡+æÏQ£™m%|(Ğ4ŠE™Â>İéû7†]I+çë»ŒÀùçXxŠ)Àßâ«4æjŠ¯ûUèËšZyòåi[[ÚP€òm1í¨$²_»À;¬êğİˆİY*pƒEgÄ‰reô¹–8öøH ½Ã}ñ¸ŞÿÉ0‘@³à|V]2Zr†®€Bâ<hßó3w9Rå«Y³ Hàà¼dã¥ìsH™›qÎ}ÅAz‹çÛÂwbZ-ft'¶!G!‹È6ÀyW“/Ûq]|'‘PK% ˆÿÏ¤3Ú9ãlü×bHöİ·P’CºbÔ%W{ÉÆè6Œ“q‡^—N.%DÃYs°ŠœX|Põì©¦§aW¶ztöå[±"	ØÉP\;!9.³¹‚=>^`8~JÊ÷Qsİ„Ã¼ÄB˜Œ{Ãµ’hQ½º¤÷qŸïãæ¶¥3ùLGuÛıhe4AœÕñ9é´ø7 ó¼gÙ´†ÅAÈÌüÓˆ*ûrşª’aEBğğ¼—vùFÎ[ñi.ûE7:«0ÅÙÛ+;ôxÚ
X²påÏ„æÊ«ğ‚‚iwzz³R]<'Ñ±.º„¸>Hnä²—<N@àö j¦1
ªÄ<©6i‹oä)G(ôíëşÆ«ç±áƒkøåØGa¯mÍıÖ²KÏ³}ôşÎ&q‘æ€·ókuºEHh²‹¯ğn™½‘yP…””›}·ÕSKşmM]ŞĞO½£®^H`Çâ©ãƒz§İí{ÓJvéÛ~ŞM¹‡†•#Z`ÀŞ?Cs¡³û¥[™DÎtı–¼6Gœïßø±nV˜ŠŒe÷eD½¾È ÷£é©Îæ~Ğ±İ³ï5i‘µİ­±T	Ç³¸’dAømeş–éÏ£v1]ı€G)_¢q*·ì{;	í¹Ú%X`04¾—äÈ$ùS]v1Öeıøˆ:·ÒµáÛ¬¹¤W~’"‘§ğPx®ÍüÃáES+ÛÔp¶?ş}ñÚÏ¸ÔúØ²3˜:>qPŠŞŞä”]VoÔİî8$$SGÙ7Òš¢Ú­¥î×Oüfµúê¶ØÉs4G)™P²7D^X@ÖÑ©ª´úo{1•Z^kŸ£„ˆŠô¡wãh–B¿íÄOOêmÄ›èGIl©pºÌˆ^i#˜ŸŞtuÌøeêDIcõ½ª-nDkáğk%öáú_èÄíÛT§)‘—´µÕâ] ×,3í¼Ä÷dä»<ÀÙ‰õ¬#±ô-’Ó¶ö‰…ŞÄŸ»éş5ÃPöscU/ï-pîUt„7å‘%ÇB_¥õ~+ÏéèiX†e:Å&MÅúÍ˜¥ íÑKûÆÆ,/ï«Awü>¨9 ˆTèÇ°?â±> FŒku%1qÙ½4¦ØV—²tNŞÊº³=+KÊk7•ñ†<ÎõôƒÍÃçl›!/7’«<…`İw+i*¯{bs2òø“Høˆ,õÉ“ĞëÄêh¤\>ÓÓñÿ©JŒ(w„=2¬ıt:¾÷ôºapİ™õFšá•CgÃÚˆ_™–~‘¹öÓN)®-.3VB¬\—xŸH¥In:—\y(*$\¡/N^mYIü‘æâR©™÷Ì–CbMd½´øîÔ9IµQHk‘GXÉîCò±Çûuÿ¥€d†éŠâç•ÕTêaå»cdïbOûE}øSŸç?º…ÎoÛd„¿Eü×Ä,Ä›{kQjÖİ êmÚÈà”½[Ó—»G sÄ%¶­u:“³Q9üh®ô„•Ô­Ã›øFRóûØò®7úCï¨MH#“=ƒ—u{¹wn\&'í½P?¡K5ÅÇ÷¿-Ãä'ğ``ÅÛãûˆ\èà‹b"‡•;R-ÅYóî‘Çö9ñÁÿšû+PéM… ŒfÙN`s„óB!™QEï1Ö6lú	M¥8éÖ·Ğ¸½‰”yRƒVÇ
Öò1upcÑñ“ùä	îPŒõ5¾±—-Iˆ°Û{11åãªS~Èøµ&)Díl¢çû¤Œ3nË·a_áYÂ ?ü5%/´mğZE­övèxªËÖy–,sàJ) ×eŞè)Š:H0@‹ÀãnÂ;¶½xBªª"ÛÙYÎX8±­Âç¡Û… °˜‡È­ô•ˆø¤iB£N+yb—SÌ²V2ßº¢(“§)òk¢Ñ†e<:îÙ·?kel–µÖ˜Éó ,½Áf¬aÜò3/;NÛ©˜ÆÉ±gÑ#ÎîŸ¤ì¡âìñI¶úßn¬9"›t8Ñ—™Õ—L¤	O6İµ4Ê™ŒòñÖí­?'áæZ²ˆ€róæÒ±Š3¥m¼öbÛFCğfúÎ¼=××ÍV‰,>mÂWÃË<Eri€8ÑD >ƒBTÉ\¶©ºUëß¬¤i¯½Ç_“î¿P:Ô.à…µÆA]–ˆè8
ïæî4É”u¸^²øx
Y‹ëMÙ\Öù”´g7yˆ&?¬Ç2Ã³SÍë”ıåÆ†~¦^}LÜO7óå(ı—Ùtueów˜qàxøÒxzÑø]g²…—'¬oŠ»Ç"%Öa{¦Õ*óŞAğ•Í#LÄÆ²u¯ŸV.Ù´ªbsz‘€Ëµ•xÑëìQLéC.aøÒOéûòÔ÷
X[KF0Ó“ô’@£â’¦¦'Ê¶V²Wøc`ì[÷Ş[¸ˆ<ª`¤ª–‚éŸX}à–â`$Ùõğ¸s"C±Â	Ù¥ï–ä›Ğis¨rÄÚŸÓ/GÏƒìS*%Ò!ÈV¬Dš4¬5ÉÏ8Š\—ĞØ¡Ç™©…ëwn‹ÚºŒù
Î~ıf´P¸s-íÒû$Ó#/ZÚè‚P	€8o*p¶´Y]ÿj˜ZØ=!VØÂüéÈ¦ØŞ»9©7oÛw‘ ™B|ÃËcø¡ÃÖ¼ôYîÛniIœïÎÊ,Ø"€E³3É‰:‚Î4­ˆ&âeµ*—ûÁ Æ E ËECÑ/\ÑQTéN©M6nŸ­pŞè?!|T7°›’zù´|~—à1Â¡qx{»Ş’c”¼†#«Á9(ûí”á'W.?¦u[Ó	g#‹z¡¼ ×æëÓMàrÕtô_İ®ş‚{öÓ2œÀ*ÛÎÂ×É>ûsFû­BÜ?.¥Iz¿±º1mŸ{Ğ*^¿«TFî´	‚×³a¶®â^‰Ï>Ã->ïÅc¯€“LÅ[ı¿~¯ñ·SÌ×ÕüÂ¥8í4ı8½R%Ù]ûª#E³“ß{>´hƒ†f\-|\×@-=\Š e­7ŞËVœn9¡V©×<ù9øŠ‡ÏDc5rÁÊ`äÕĞòÎ„6šĞâ²S!í
 éÉe¸5gÓ!%ãÆnÏhBó|{Ev¢)“½&‡Ñ£ÍÁøÍŞ‘J}İ]±¡[çsc$åi¦™ >ÇØòp„²ÊŞjrš½¿áô,ÀK{¿.4~Óbaİ]û‰a·l<V‚Y –¬’™<n£"!—µ³µèF|¼zÊ¯XÆ›S‰ğ×›#â™ ı­ç³Î7?fvDäË,^zıòxÑŸÁa2øè‰.°ªÓç)²óãí·.F`Ğ­‚D¼ ª®ğ’qšÍ™ÎA‰"üQ5„ı¼“AGDi˜_®CÌWTNuĞ-c®'DŠ«‹¯[1ªH0hqb”{Aèª§¬Íj·–İŞz!&c¡œt¡ÿånª€ø´Oi©ÏıùQ´O¼Ÿ•>«ØÔä>}}†QVûâk’¾#1Â%3”}È¸?êN¯¼µ€wÃRk4¡pıÌ™Á`B÷ÛFúÚU™Ø¦ç|ú†µ¾"Õ™ò‡D8ß'ú½[%tm²
áø•C±aàT¿ˆìÀÔ§O„	üºŠ}yqzƒ_0¸ü³[ì4	µ†q8@‡1ı)+YO`IÔä¯‘c*Îí€,iÅ‹Ñ_Ç:Éx­)ï­’õd”M)Vï=-øO¾–)²İËè“pé@TÏ§#qXP(ùnè¦¯øµIéÓ(/ü¡;êã¹cL	ö´E=ğ³f…[³æØËU“î9šÇ!A[b˜ .À€f†XÁ(?.#dóŒeŠŞ2ì`,„xÿ/ÆıoqÒIú¯a0ànšÊl“ã5Ìğ!Ø¤N-avñBgÓ¯ç’WadÏÜSiÄ®ÿ''ßaÌGĞá´kr‹ß°Üzô\ğAÏ]pù¾ĞæÆ£äypQ­¢Re]®†¥÷óLW«¸JáöŒaŸÍœ#-K8+Y•g@,Ü_«ª¢‰ìy+áã³HÄ0{u£#«Í/Ü%¼è.4ºë¾VWÃ°w˜YKjš²<Ê)Ñ^Øì˜TwßèhÖò;ÈËSç:ÍŞ»X@Ğë·Ú_­p.øÀ4‰Jğ…xÏPGÀ”S§?ŸE/@,Ğ“xâRëö0ø«É˜Y·›T•,cd®½4lUbAMş~,=_—Oˆ£´¸6yË—Â¦_»9™ <8»@©vJ®7±s•Û›ˆ&Ç’ 
$À®Æ¨"²Ş·"]Lî‹-rÎxoæMÿpèÙºó—ÖJZãF“×Ùr*Ø†`›‹ñ¶ç÷ËÇ'§b&«Î?¼ıÙJŒÓe›ÄÔ$¾»nÃÄ©j¦ŸÒáÊ¶†Ş…FÃÍ´u:Àˆ‰¬èİŞ‹ÎH¢éHO¶†Ô’[iÀÇ®Õ«)dÚ òljƒKE¦›Ã¸\Æ é´`§-é–‡„¤AáA/œ¦%ŞNW¾i¸güí9%Á~m¢¿«zÀ-  y§»Œûö2Z1Ó!‰ÇBTÌãü,%®Ò2d—kRiÎcÄ‚‡ş3D©²gQ4‘—í	á²U‹ÛÖQìF(Y‹˜Ç1JÙz\êfAßz|@XØ ^t+½â²¸Œ,Ğp[t6è:YÒ©ç¤S,4ÒäÏºl£¾¢È²e<o6VÊÏdNOrf^£™º¡àü|=:é‰‹‰o¾Æ—ƒ^”˜NË4Tb±7íŠ[ˆ>a®mİÇ¤Rô¹ÂG·÷Ã|åÆDG¬í£PÆˆVÔ"@áeŒ_‹ÿÖ¥KËT½F­§mU4azØØÙ¯“vjê—üºšéåVÃ~ÉÛB“-¿ÿÉ"^|’ÃØÉ0{ì,IÔ«±4çoœÛ>äÆ˜ÌxÍùŸ×lò}i'‹smdè6ÁP‰ûs2›F|cŠ¬5<^´š(”k¼Ÿ<å¶ß”nˆoî):ĞÒ†"S/vr½jæÁ¤ÃOf,U®mH]¶ÍAá³7,æÎ4’*LbĞ¬üP({ «®%ıySö¹Wö¨Ş=é¼Ëû¹ÒhÀrØ Ï«bÒE÷Â¹?ãxÅlW1lá €][óQ;È¢]s‡¾#íDãéÒhc©F98âLSpu³œ>$â@£FŒ5ùCíNÑIÂDwŒùÀ`xz›ùW['›¯=Â­"'}6@LşEv‘Ş4stV1T‹ß˜ÁÖâœÊãEjÎ½ğ±ÇfnãÛ¯øgùŠ•‰Ú@vœîÖê—ÿæÃÌcñüQÖå¯>{¤/ÑÇßäËæ&ËÀÍ$‘ıèÚœ1ŒŞ*¯ ‚Ìèø	¢<08À¢\µM±‚CîÆC%P^Ç£Bêwt}Î˜·”ßŞ•‹íWRÙi/ú>
×ú[üV^`·N%¥Ååcùã.¥UbÊ]#»dHFIƒF›$…û™‚>ø6~qİó#¢Š8DÈjJ×í‡BzÖîåA´¤EIÕ9öX‡ê‰r†wàù‘¦¤Tüêò©Ø+ñjÊØ*Ú»„\†-¥+KË'&
¿f•ôzu)pÍ‘ßĞ¶Á›ßéªÅÈÇı…p1ÏÀñ<6âÂq¬tüÉ¹x°émôO÷RbÚ|¤®’‡œ½;-GFIêm!krD*í\7œ±|&W`cRgorV‘‡^H&ğşù&ïrà,6‡àÈÂƒÜ4\êò&¼…æ×ÚGÒ«®åŠç¾ ÜE¬ù­!gÂç{Ş‡';bÿêG~ö¬0ykdÿue¨/ÖşÂ¦éç©³_J€Rª¦¿œmÔ„¡§–eÔs1®<)öŞò$¦@{,^¥n™øDÃ†U&/ŒÅ©4ŒQ·(‰[€-/õwø4|sióÛÒ=Ğ7º„˜Ò,ÌŒÿÿÄ@˜Gô«< k- §i™B‘±í€ù²Â±ÿ2æ¸ÛF\jê¤ø"b)bK…[rC A9³•^í½ÀÇ¡düIĞf-_Pèôf“hâ×á§ï¶›rU}™¸1Şñn)˜Üë%ÍHúız†Ç‰³	!±$ùfùI|é-Ù7ºy5’m)UÜD¦¡çØŒ³5Å'^zŠøêÕlCü’5> Oï‘QòXŸ¾×cˆïÇŒ€B^^]Ğ*¦zxB?É¨Œ@Â30dFá+HÚÿŠ³+9ó4”“UÂ·.‡ÂâlÂc¶Æ…sAh&]+7Êîßá‰FC!
ÒòZ
ÆdN©M9Êûİ²¬±a.WN°)#Öo×â|‚.Âæ”·Ñ%àûJªmrKÿ›»¦ó`—Ÿf–Ù2a[3›îU¬Cº¥DÍ—»?Ÿ|Ÿ±»×ÜZ8†z ˆp6şx~¾ÏçàCÕˆ[‹@,NÙú+Q<OŞîK‡Û>r$oéU4ÆS(²Á\r§¶=­œ!ÖLçøÜèÍì1 ³^}¯äÁvGë0ğÈ6ö8§’ß`ùB.‚ÉIŠĞ¹ºZnIuDbHš¥Æ/›ê´ÄY}åb5¶PZßj†±c¢?:”dªîAğˆ}OHgæv[’¹ÿx»WìIĞ©êÓøŞåÒÊ {Ğ³<\
À3G	¿¿ÔgZu€íÔ:·Å ?âZ‡Š¡5»e•ÍuŒá0…ÓÃ4ŠãO*Beã{mólœœÑğIÁQüâ—”ûÛÚTqA’t¬’– QÛq‚h(uÒ~¨Óe7!Œ¬Ê;™ef]»?úıjº•¹ˆx9ÁW+fVôyŸV„OÏ^«§í‹x
ªÊíz†­<éR
Âª»çÂ8ƒd¬îPC8G1Ü2¢z‡zM2W¶ò²n]¸4vûå	ÀÊõ"ŸdF¹]îmùOj¶°—nøoğK½ujª_‹mDO£}­–É\Ú—ˆæç†¤KºæŒ1Èi‰©zX¹Áê|¾ñáiÓxSCô)œÊCÙ“HÄóºaÑÌNØµí2ƒ#1-ÿ° Ñ˜@ß1•¢S±y¥åÊE’¥zw]ë”û“ËôG67¤÷±1òÛÒØtµÀ\‡§Øä>“ø—Y[àw	Ê“”mÆH+§ñe¾1’¢ÉÄœbú²%ÙLÂ.Æ®XM?…Y¦éî˜ÿÇ]ïş	¿ÙX”z¿2Š°ÆUÈn»fÀH–Ä€Ó`â«»ÊGªQ*º›¶¬]ÔQÄ¸ìµ^BÏ’å{Dê¢¬¥kıNrûóìk«±áUª¶òØ«æÉ¥ô@Vèa!q¨İ‹>4OlN¯—b:?Mk€ ÇR,Ï·$Eœ‘MÆ¸t®7GgïÉAši£ŠõI)oïˆ†„îmæÛ„¡-(«GH³ïhS@-¿À(Q¥sÍÒ˜§ïg–ØºÈÃ˜RMåÍïo~ÏZ6,şCŞş=ÎÛj°âlÍğ'/µû8ìµPOz­¢æ‚”íè)äqøGD/·—Ù®üòª®È	v²œ˜ê%ØU@(‚*	;ê¶)g5.07½'±€ƒFP?M¤µJãa½‘ìÆWZÊˆÈ(}PñyP FI ½6=T—%¾5Cºmkê
S,œ™¦Fu—¥öŒÓ”Æ¦Ö·a]=š8SıÆ*œv­Œw¼â2›úä
»YÓx5(x9Ï‡3Y`Íš‡#¯ú?æ9kG¥¿”ÚG7 ×#Ã`À6¶™Ú,ş¾Ÿz´Äy±Õ¨ÍÃ§6Æó÷¯àŠí"Lƒ'‹¯»-RŸÇåxß^7bÅíŠ×ûj²ÒÚFjwB, `ùŒ‹ËŞêÇK"åP÷øOËµÎìvĞ\OR;Y<iÎïJ*†’ª±¤ó‹v'cl¼u2}{ƒÈûà]‰„&l?ş6PöTkTÀég°€İ$µú³î#²TCÈÖ·nwßŠ8‘¢•®¾‹¨“‰¥i€ñlS“ç¥QÓ˜ÁZ’ÍHnÙH#¯èA%áüİÅßÖ
¢·TşŸzvN§6.Ğe•Ò*
Õx;-}#3bê¾iH«â{“àĞúõÂÒÑ€­SL'ùCèm+ì 1å¦·\¢µ@I½ô;™c¸`Âòá¨Ø$¶E††'‹Q–*â´§O5êxVy—ã
O)©ƒNø2di/ 0ÓñÊCqÂ+
±â¨÷!ùŞçr¬xg®ÒĞÂ÷˜İã=ëSRş
QQS»¢D!üÕ,]´jù…‚mok>ˆç8 i_³Ñ}4j–ŒCŠÎÍ"bŒVR×à 	B‚*õ wg°…À9‹GŞ×É±"£iÀ¶w§ÎÉÃfêĞV U^#]«'fŞå+¾=á7<†Öm®‹[‘~ÉÔ6Šñë|Kø½¢<ú¯1K÷ pnöù¾fåna­ËÇüÇ¶ EÌ	aØZ€É£Õ|?Ç„KÙA +ß48–»×RêàÜÅ¦¼©|‡¤JW˜aayêÓl¹<xĞñf„qå
2œP^éáââ{íúRgFˆë†)ˆE¼ÉÆÒ@R“Øf2©çqÎàíÀñQU=E[ŠTõÑ)èÂ6¾]e½è«–5y•ÃÆéd3µıqŒdÂ…ä‹"º)Dä~rü/Ä‘>½ì¡:I•êÙo;­‘^¼;ÀpÖWt`"µë­Pßë­Ò[¢ƒºş{€çºc«Æê¾
Â,ì2ëtÆŠb»FìÀOğP¨)ÕÎtoI¨î©ÏUE-¯Í3ì!>8ù¤Ôï‡?T²£G¢<ÇPE–ÁŸÆ*sKá‹±èÙºkCß¹Ec‘¤ö]¿>âuÚ™GBNtÕI
´˜T…Ní¸Ü=kÙˆå$/(m¥©¾ÊÜ>-œöº¬;…®Õà}qg¤&*c3“êû‘­D˜÷¶™IS±ØCÎüuˆèğø-[üE"Ë†AŸˆ¶ä;ŒW|„^/ÓúGHÈØàZ–±ŞÉBşT×WÒ@%a¬ËFİn²‚@;I€§¸:zÛü(G ã¶2®‘fÖ¶¹ŸÍÕ¹R]Â&.<=ÿN€ƒsèÕ?ØHíl/NĞ¢Ë³I¡âŒ4M|=WT¸Ú³ãûûu7+‹¡H³ì™pk˜OxÕbÂÈÁ×{şM^ ´¥’Õœß/AczĞR™÷ó¢ö]†¯Rì!&P>«e—¨¦œà-nÉU œñIM]†7òÆ,Q›’9écq.g,TĞvéIğhy4€ ôÄ+L)mLSŞÔ¹­„6O·-/³2¤ıA"pQôìyƒLö7zd]z6-yÌú®ø0Î®¬»õ© ‹aœüÎüãÜ*r_.¥ô	Uzè’aºš]à;
 TÅÃ¨Üsºê‡õÂˆÀ¾^ë¶c”³Ş9­z”LÅ»_ş¾ƒçg¯šÎ=Ğ®äBßàæEâÿÆç‹»§r/³Ëo3Ù-Š{fàCº°¨ˆÜ¾PCX)Aê él—Ü„1xÌı’!£S»ÿ¬EKq¦a‚´‰R½8 Åd ¤°Œ«?Ğw7‡ø)%É½1ùÔ–Jğğx÷•ğ¦óTAı<Ä7Õÿş(©ÿ‰ù“€,¼”SmÅnÍ<"n.Ç°­ğ}?J](O ;O²JØ'¨¬9l»cÁÀÆÉ ZpÑTB‰l³CÍ,¦ıG^ÛY´àæ»ÚÇì(‹¬cŸD‡?\]/‚—cLcıº¡T¢4CbçûÈáu=ôÛœ÷çSÓñ·Q©eb°½â¨r¹ÌÅŒ7ªóT°¹qh#&,m0Â±i/ÊÚyû½6îk…£„õ»p*Ê¡æ:J;›bh+e3ì<ç•wÅİl²è‰Ém…‚_ëĞ“>Ö4Œ¦m#53C(ÒV7ŒDN“GÜC(:-r<İÇ´Ãr|€:œ1ÄVµ˜-ıbËÍkÖ¤ ™}˜™o€VÂĞêì²ú+^_9nØ
&1Á´wàBÕ<Ùj}ÚG±4ÂƒF¼¾<]M]œ]ÒõPêc4àÛØo^Á€iªè48ŸŞ^ı³jZV<^c©Únı˜ºßşXkÇ¡2âokn_Íø½ŒémW×—Un…&D^Z-ÜV¡i_â0OİõÖFÃ.·N¹CÉOÁÆdà	>ä0¿4´K:Ï«%%³‡´w3KæÖ¬jDuôfsI‹/šWáëÁd(_YDr«Ê~ú|ì“5CùjCòFË_¿oaÛ¥J«]®ÖCia¸¾!£B	àî…^U 3BN§)c
ÇHŠÁåkàŒ± îeNK-À›kàEeô,(ÑĞ9J£ö`!,#ÂtúÌÈw/ùb@JOZ€bUlí}"¤lv™¦r;m™¡àİ"Vk÷‚ƒï!¸×z4QÌ»ÓÄAht²\5:*-§3Kæ¾üë—ëvÙ‡A±ˆB¹Ã#é¯Ccİ=c¯‡´ ¾äh™«Ïzlê'é_Ş¬¹úsc?¦®íñøQ*BÔ;?zæFâ“’o±.ö×xÅoÉŒ³+”cB*ŞÛ¿«Ô õğ^îğ£>³]G%7ğHØ¤Á'~ß{,5(k£ù £¡`şÜ:lLBÚhîÏƒ–¤AŠ|ıR<H\¬§øş–ØÖl$FR¥mz«à†f¨İÉÚ6å¯\·‰1…JUCq¹ÃP¨¿‚–5#ç~‡˜9êL]&‰ƒ*rOó¶Á[dlÌ4	;NKà+‰óİ¸ì³[Ïp;®Ê_G?8¸¨Y\Ü¯§^»¤E3æ[ps êÕj¥;Æ”xÂ30‡_Ÿœ¤ufV<ş°0¶.Õİdğ »j0°Ö<tÀÜ·%„WâöÆĞ=eIuMîÁ§¾Àk+cŠ0ü&^ÛQŠ	h¦xA-Y/¨È5‚²ı¶ÄU¬)%¯±š‰ğá‰BÅb% üõ¬»9¡f¾là‹i00©ò…y“:@ßc¸”="ws`w„W3ê`„(¤f4æl£ÈŒueĞh4x?\¨ÄàÏe;˜ßö<5ÁºÍ‚Ş-ƒ<ĞQ  pê[o‰z	Ğ-ÑÅ,ù5hy´`yûâ¤Åşèps®=1X)‘ºQ,ë³gÅN¯	ÄgŠcQ6ñıáÏ®Ÿ=3¦GN¨(ûc8ñ
†´„×Ş’â€a¥œ$Ä,h3Kœ«yÏ¼ìç-ñ^LïÅlı—£ø5ZÚ
ì±JpåÏe8!çÛïÁÇ7S|‰“Ù`ĞûJqSœÖû…uWÁ¬½ ’‰,Zª *ódRêÉySÅ.ù¤?‰WÂÀ<ÔjLzƒYQ>‘œÚyˆ+ãeÁ­ù;
ÂéŸFJõB{Èlçš LCN©a°ò{L¸ÕíÖ´ˆ%úŒ)KkÑ«§³¸$p†úÁ±S‘®Á1)[Üì ÜÕ±6DÀ¸ßø!U'š8_xå:ZæéC:Jç3¯2­¬7³¼“,æÿ¢FWíƒ ºzàÇ·]˜ñæNÓĞ7(`=)³cñq­?¿Qı¹¶P´)[$M¨ZŸXd0;¿')CpyKL¦½@ê/U¹ iŞ³¯š„Xh•L˜‘ò¸ÀÇãgra|^Œ ‘|h+Á3;Ú¤îÄğª7Ã-¡„í”‰¼‹¦W˜ST¡ˆ¸Z¿1±¡é•¢æ.Í‚‡]²'Tã“RÊî•(¸J^OØ¢w{ğëâx¿²M³¤ñ–h…	²°Ğx¤‹‡&ôNÁ²H0âq–m­õ‹®°­û0¬¤|2â‡$é©èª(³M?ÀË{Ô¥ª½{Yê`hqbHÎQ	*X:§vñP™ÇWRëF·ëÙÉû°d9ç
ù“Áü.N§ipq¤şšÊP”ş¤óŸT|é.ÿBå:4–”_cÑ4ÆˆXV-L
^Ñû½4¢Õ*WúÉ)x.fSgœšG‚Æ±*¦rÑn¬@Å/I<‚VùNIâ9«eA~A#<TŞiµ’¿(¹½rÚ~ 3Æ±X»ŸI<Ü!‡™±gøe«Jáê®Å0?Ğ‡Š‚nğİ½>QY³Ù£ªiÚ±È]ğñ1‘ÇÇg¶ÿ5qèXéL¦¬åˆ`y}l(^Ÿ–˜9şÛ%íÏ\õ1àvÉ·ß0*'qŒ9Ê¯B´¢'äòãø-“üòHg&á-§ó”¸Õ®®~­ì
¤;ÂïÊ~‹âÙÅVXEÄİ[„æBÌ17¼¡aUd Ÿ¨06]›!œ¬… )‚‹õL|æí°¡I}0õøeŞ“NÛĞxUáoãTH˜'tŒ:gé,Â”9´İLÀ·­Vü©÷Í•"aæâ=îËİB0›¥äš4qqGß².x˜†¨‚Ò¦½=òÌ:USÃŠ6ì·òk=ã“š?­€úŠ²-¹Œ~Yº5d¶Qj¢ñè°…2lKw:_|ø„ß÷ÙÙ'7P+:ØŠoü$ÃûM©ÎU’ª±7ûOka®úôTsÊË"Z”t´*Ø'‰<&"góà™PoË§$L“÷µ´‚XRØû»u1Olè”90Õ™šá‹8OC$käqŞ2iRŠ9Ä[<Ã·8IÓxıÜğâ?ŒËIì‡]Ìï€ÚD} †ã?F)ñ•Ú±à‹®©éØ_ğ‰/Ğˆ;IË‰)î»â:÷¢{H±O¾“—À‰!ÄİS.ìaA×M»é=²m7¿s@º³Pp9²—ÓW®ü¼°zş¥Ò©4'émÄlVIÜÓ¤ÄÀ³ûJ¯óœ“ Ñ»ÿH¼ˆÂç JÈÕ[ğ—4²E¬ÿóŸãZ0jM•Õ}gˆ²q Q/yŞ~Ğ}ä‚
Zˆ¸¡…u¦§Ñ®lA¯Öö…\òˆ“ªŠ§P†üÓZaáˆÔp‹³ĞNÖ]Y•½:¦,ÍÉyò5n‡”-ut±V~Œ÷\Ô™"½ıñ¦ğIœê¥Å‹ç' ê“Ÿc/x wWëLe«àE$5¬ö—şÃñfÁ+$‚ôåñ¶¯#ªı_5Á±[›õ%`¬®¼
ä ÿ%ª3]¤c¯I™3£sp>­ê£Rè—ÖY©nDó¾ùÇ›¡oP•FĞvñÕù5Æ2ñMA	ƒˆZ½›Gª™‹ª4`XOR‘rVRÚ_zšˆ«.¾Œ3È!±¤"¸ÅV¯][¤Z2‚êxâshÉ¹XlÃ*‹ÉÃa®G#ê/š¨`¾¥N1
7¦«„¥¯Ë `E¬½EË*Tq¶ö„¼–èuäE÷c¨h/Ğ¨uzú~ÁxÖyØ×ç .Øq"Âç=á¤|Ì†°"æ€ßÉk­}ÍjdGÔ€Ú‹¥¦\>vµ^Wœ‚ŠÜa&LLiôR›¬:/M±ñ0G¯2µÙXÓ²ê psïÖ¿˜óêĞŠ¢XÆ–QºûˆN®9lï?Ü†HT¬íÓ‰ú—ß$¹¸íG6ƒÙW½ºàîAÛ¯w4ª£ =ÏfZ?–XûæÔ‘‘÷$¢‘V
¿lX‚wÔ¶¼ ~3¸ãÔñxá½Öî>’PCş ²–X4‰ımssÅ_ÊKTµ0\gëß'?$†qF ÷	¯ôq¯€ùfÀ‡ô¢d‘•ÎW¡Ç…”ÛL`!w”Ã¯›(…8 ¥5Ië˜Æ×°[vÁÀ*R'ëülùHpé;“Ïw	bÆè_û*€mÛ«¢”ŸoûÿHXÍ[°QÇ´Y¿ıÀÍwvyÒØe5Ò,é4³åy)jÚ¼(RÑ³;¿æJÄÂRôÚÒÿmqÈ¦•·¯A<à\W#¸‡Æü^Hg¾÷-sx´xU‡ CXÈ}R_}wÆdùXr¦»UüDB7ßqúM{³ÊÄ¶É?ë\µÒ ‡»spç
T/êíÖŞ¡²îs€zŸ–†dx3»Òƒ(¨B”ÿ|D(YGÆûÆƒ"Ä4Bl,»KÕC˜M¡"¶‰«ê¨[¢Uf€lº/|zz¸pÿÈH+Ö…Ã‘KÅCCJ¦PRÄ°™™IK¦×Ù‚ÉJ G§òòÌ†+JxEµ#EH<©/Ç(6ÍŠ˜ÄåändzU{ã?«ŒğV’òŒ¿dc‡³Ïw%ğ³×YpºÉ ÈT×Ïd¬Öæ‡"  £ÒnBzwŸÄm+ŠhØy=¯ÀŠv×“O´Ìuó½˜<’`R^’'qšI•òTõÆrKvZ¶vİJ	¾ƒwøøÓşU­ßVUÖç*Îg¤Ô¶`…„"ŸÏˆ›rÔ=< ”í)á³8°€)úV¾dç€b)õtRÓa4)7ŒÉ ùc9FçUöîfÏÈ	tm„±†?q“š–àè›’+§eˆK9gÕ‚2òÇg%Ğf!ö(ÔÇürÓÜl‡lÖ³rÎL#)Of#RÂr·cÎ6éŒP è•9ÕĞ^¼;¼À¸*UYvfU…WX [Ø9Óÿ‡|9[5a'—·ÇmŞ ÄÎúÚV/Ò+4)Ùü¢7–dvS2K(7&1+˜%J¬ÊrÉ#ñG„aé»¨\ZsR{M5.7åŸxh	Ù±İ½•ëÑ@Mï§mA4+òU»tUïi{ë9<´Í=¢)ß¼=k/jƒ  #½ Ò×2—gÅeYŞ©~Ê´ÒDÛ‘ÁÍ³{à
X»’¾£SÈ*ÂÏı»¥b¯®9=“¤â<õ©‚]®­Mg«€„:¤Ü«4r©ê×p’[S6–	6aƒ“%…ĞöI º‰³›F96B „’¥í¹zï¦›3°Så|ı.¬„[¶¬–¹óÛ_íA;N^ŸæU´êÇ|Ò°‰Âé×Z CÏK¹WBöÎÌ­Ó+H‡”'U¡€K /ZÅ³‰á~˜(ãPÉi¦(áñ\ìBÕè‡½šRd {Å”gT¾¼^©Ò¹†§÷Î½5•$ Îu¹74äÈø®ª*\o\ª×Iáƒ5áÌ3¼Ùû§sî¿òçœ;SX€c³éözäOTQí3L\q:·÷­ñ-_Ua?©0˜¦Ç­`Ì`Ææ­œ]Ä¬ñírxÓr${“AÊ$]Û`‰áÚ‘«ûÕ
’ÓÅÅò¦‘ÂËÑ‰ä=;•ß‚_Qm×¢r8Qá¥÷µå·úì{\daúP©p#Üü±xŒŞáÅù(µ¨õF	şş‘“øÈ˜jQ4İPnÂ¿¹Ÿƒ71‰=µÎ6"FO¢ÕŸw ®–ÕìuîÕIUÔ s Aoüó¨jJÒ Ş\ì_Æük#¸FábÂ³7– ßÖ6ıËŒi‚cE< Õælã$¶××W¤5O~.š:¾*|1ö_Hú.İ¦ã@yÙ®›Ñq^ëZ1–àHÆïÅRÊÓ‚c'ç-ƒC­©¶ÁŠ÷ĞœßúÒiÒgÖşóbŸ¹«aÑìÿˆé“YïwH`tÈ¸< ôyñ[­ZTs™UÂÑ±ü³­ø1 BşSÜWÎÕ~@ØçëNJ½‹#;Ùs¾ÊÎ…«×”ic[¢Œ¦’ÏE3mÄ¥äfÖ–ÔT²\Ê8ÎNXºaß7Æ¿‚5áy˜q®ÄÊ?çô\è’·ÿf ÿqŠ-Êï'Œ=KW' Á$W¿`—ù²¼ñ«Şfù:Uæ‘l8Lm½À]8x*÷ÿeón¥xñâQï®²Dç¢äQÉÎ<¹]!H:ƒ!
j`×N¶t’
÷cuW$¤7'XÆ İõáã9»U§d3ÒC(ªÿ	Ã²Š?!%zDÇ¬V!rƒcH>ëÿ(ú¹HáGĞô¤3àï’95ÄúÛÙZ÷w[âü$üaEvĞÃ€ÁiC¼ØÄJ®Ûúùëo£…ïÁË?„÷çTšÆ$lÆ€‡Áœ°Yv(îµ¤¤ş{8T_ô¢¹I* "ã&—(2Õfçä!Dë:øÇÔ†oñÌâ4ÇV:WutN…Ëºóğøğñ—õ~ØQì‚º®êË²tÙ‡6«c?Ì£{}QÑ|HÚj‡[P£HZdù-ı,˜G'¤æfü¸^@Áâı\I`§Ò§°ı¼_Ã©GŒŠb:„:!O8_Ô\¯¶fmH!CTb«ÿ&N;–'_:<»‘GÓ`š9ÙY^ÍZ¸Qrö€š_û@4LW•y}QHÄÇš¶V øåpÙÚ.%çíƒ?¦¯=‡µÖªÊ ~ÑLÔàÆ¥Ù ŒQ¾GÈH1y³ÅxéÒ'¿M­.ªo5jC5€ŸŒ¤ïç¿ğDX‡ã×á“èsÊP%A´‚+\—;gàª/ÜÖíYO«9^Ğk»º¿Öğã?}gË-c;„Üªy’Ûß†çHX§<K¦RÌ´TkflÙ<Ë--Ü½6Ó‘º.ëGH	“Ôİ‚”‚óóâÊ2H¯Qj¨çV¦6É=¤`f9Åqn<&CTÊ¿¨½Âä6,°7R
q¼
~5ä`É$¼÷ˆÙá;£IYP6|=A¹y`è|³»…ÅD{©8´ÓKrâQq®-HæïæšK”UÒ¦m·_rUW™°•7¢Ïé_"£¹fn:~šã.Y+µ@ˆ"}&ÜZy†w†EIYúÎş·ÜR½áqlÄıû¼VÛO­sâ„ÔĞ ‘Ú19¬^¤ó%Hx´!Ôw<aÁ[Şys¯&Ó×Íˆ’ ·—Z¸«#tâ·İg!^¿—,}Ê™®O1Z´}íÅø‡ŠzBĞxâÿ&24Şo BŠ–îSÕ¹yh&3Ò[¿ËóZ‰dÁßCV–ØHu*=¦+\
½œÂİû2eñ˜‹= *½›@ç²7˜4ìhjD1ÎÚä9(~ÍËZ‘sH©z˜CéœÒÕD0w{?‰›¯-	¾Œ†û¬mÆWvÖ§´–ÛO‹.ñ=–Açñş)ìÌµ’é.‹™‡ÄW.!Â¡Eçœ$Ì¹Î>(›_SçTtc+ÜwK©—Í¹İıÉühä­H”TáîÙØ¬¿cm~,1&4ÄG/nXˆMå487yo‘ç¼,y—Ñù:NÇ}„uLÖóÃŞì³‡G•"V7éhaFÖRR-~7³;“f/g¡r†Ç'–Ù”Sñ*ùÔC.ë¨øBôƒÿÇN£û,PG’dê[1>‰¿-¼B,yœkß<ƒŒº3.{0NÇD*%÷7<Šaê»œïTê¿óôEAŒ!iq×yP¦o8÷‰:à(÷©Ÿº!˜¶Öî˜ygÆÚ7´fMÅÌüˆz
Í4‘Ø…ı>Jó»Ûñ4›Ò*X¥’—¿\o¦È$ÜJj^åŸª3©6J¡bo…A¶s¨in %ğ®išî>ÑMiÊ¡PÌ­ğ®ê ã¥Z_çß.`HVı6Nê2(ö®=Îdö¬BVï½‡\'tDµW©ñŒG˜ì´jP#>URî(âÕ„cÄÇv…„¡Ge0ä˜lùTr^çô¹\AêÅ]àÎıùì
Äè˜ß„DH‡ì"¸8âqÙğ
¶IÑúPí¹êòªÀ6ö•Î—üvæü‚Iê.ûmbHzì9ç³‹³*8¯c5Ykÿ!óG—LrŠ[ğÔ©/uwuÄâÚMäı­Ù¢^düJs¿YD™¦J"x‚®!|	ı2œ.l[{şJ†æFÈ>ìÈ9üŞ!7e~SêæéÖOF³=·!d Y ß»ÕÓ÷1_ÆÆİÜ†ÆÅ!_¤^n¿A³æÊ¯Â°µ=äæcb“¿^´;9©¬•b˜‡jetCÑ]±c¨2k00ı²ho×!ËºoÓ	¶•&ìİ46?@\D6%k~-[9"°=¬yÊ*,»œíP¹òç*K¦çºl‘;è¦'»iYgI<¶´7ÔÇÚ+Ì%ÁÏ^8‹ÇÔ¬‘#7˜øª[dl¨€”_°:ÙKçìOâœÆRÁÆWâÉé t_ìôG“ù+“‘ß[N´ÏMcùÂ—ºáÈÃ¼TÙX„şúÃ×£#¡Iæ[S·
ùôM æ\Ã/Ç~ı•Æ Áğ¼H.ïëœLE¸€Ç×¿n”İ‚Òö¤ä{õKA{Q«Ÿ 6§€T´Îæí„}g>/û&Ñ7k.İ&êÀ=9»û¿ÅpdJÅ<sÓ°SC•1û—43È›3Ç<^‚L„VçØÀ@‡vrô­´dîÀÑÁi:•è”·K>Ê›ºÙÒ:Šl¨jts›B+÷şÜµè.9n)¬7ñŠê.@lèwÿ:w l°A8™¨
`lèi RBşÓ¢bÈåõÒÁPs*G€X€“¡7£{şGLhMĞÛy¢Øh×Ìm¼uúè%M¼³Fÿ
änÉò)ì´—fƒ’(Ù±Üw`È¦qñ‡^¬e
NÊ9ê¯‚a<ëVZS[À‡›xU"³“Zâ/Ì”>– Èœñcân’ó7ñfİê=R¦Ÿ•
5w£(*^şÕ,"êÏ #¤g¬Ã@ms{Ó	ŒD¤[äãœz"ÏätµÔKıÿˆ[=æ,ÏÉÈ÷ëËÊ*	Mò:İÑ‚E8cÃ5cŠàU}$×…‹z0-¤Ša•¾-oPøh•û::¯ìY—ƒğ†zWxk`_
Ö¹%3ˆS\aƒ¨·^”šXÏÀYgá2])~”úğ
ğÃÌá×gPpO¶éVQ±à¼‰xë6T„v¤Â¾ÈàhlÛjYªYüÁ³9Æ#aé“.KÑ˜6²óÈ !@˜!¹ S‡äAvxÌÑö=&¨â”Sê¯38š¼¤ÔešÔÜKä>#ª.ş©$¹ÊzŞO›ÕñúÿˆÑ_ôIÓA}E>¯¢³ZÁŞÇ…2óøİÎ!”xRGú3<Í>Ñrí£Eo=5'mğÙmšâheŒ£³şn0‡Ü‘FAñeíX—´ò}E¾ûäÕçØ4¬¾•±şÁêÕ±ÚçGÂ&k_ƒİæ†Ç)ÊÅìÑÉĞŞn^|*MĞQ¼¾Ï`@à*5Äï„ìğ¸ÄÑá
òFAÂ•×BŒÏÑÜ—¯Ã9¬‡ËÿÌ0O"Yî¯ÏPßO©¹–s(J·#Rv6&…9œ©¡¤ogad‘ò˜¯/nôó­[ ÊêvB‘ıÏªˆùºƒ!cvŠ°{`ÌÍ£pyÿP¤ö^Æ¯éJ³²ù¨[ \¤pÆ#şªA¸ä€Ğ72‡7Bæfî…×Ë-„èD[ÂÂòkº{ôÁ=8Q6™v¸\’3¯ï¾¸@m†«SM¯W<ÌcÈæé!{?aP×ğ“Ûœ^ïa~ç(:S@uDQ$ÍÓÀ[Hózƒ§şfíÁ„@1øs£ä`~îX¡|ö½Z×@Wøº2í›B‹“@UÚ«¶ŞbÁêÄ³ªMh1"¯ÅİtºŒy“ îN!H/øjŒ}>šD@¢‡:Ùyg,']İ<İ †n †Ä¦~ €#)rêHù¨~²ö>-ñ<WÁ*%é´ú»ß4Rl”.Øe2GÀ RïYÑ] öÛvÜœm3ƒæìì›	úöX]'91}ßÛ5şòzd…œOXÏCê¾”,îÖL¥N©÷¹u—'†Ê
pİ»ñYç_jÃ	ou*Zi†c™xÙÕ¹ôÑİ(YoŞò{İnˆeâªÇÍ¾ŸA@Ö—O™(RûÌyÉ”êêƒÍ/°g{óIôøS°>Ã~_!¢¢„B¯‚\ÇŠØ*ÿıWîBˆ“­ÌÌˆãÅ  0U‹Ü;ïÊY1[ŸsÕônù.á{)2’)ñ]«ºKÕ‚µ’]j¹œÿ%˜Qy ­	”éNZì;Mƒ"r3\tâ’PrÆ]©øDü}Hëz¯Ö2;5Ø4Îö'ğ@P£Jr3mÜ”àÏ7‰ŞŠàO<û!æıÒ²”©êV²>£©êüz&}¶+[xi–NõIe!{¾Î(¬’edò„½›È6C¬U¥Ê\™4SùÛ<“_ÿ±~OL]Ô±?>˜Ë>¬*ú'u­é£ˆ…ºàÃ,l/î§WœÒFµD9Ac‰[;¡Ë.ï·TË¾ª(š.Jhÿá2}.”uƒ…Dg$!¥Äµû.~cxP5^©mÁáHş
z»(a¦ôº³û'ß?-”[ë'º„dõ‹q«³=\üêk]\ÉzŒñl°şòÔ?f’%»i‰ã_ğ—}|ÈlHŒ¤n9e-ÊV,MdØç¡$¥eğ/¢)ˆxÎimßÌÃà~ãRçQ¹Awk"ˆ5¼R•+šGÍÓ"¯wgçê»WèKEÄq³ñ«”×£èc!JÉaR°‡¼î{	9‘ã,WìñcäF½mmYÙ»ÀÉ(ğÉ´2¶-³í#¦=×k½wTS-I&LM« ÷Î½1’‹Š¸ó=t\«ü¯Ó`DV&Z6DšV¼P6xojQ#ëî÷›/™È¨ãI'´ˆ·w€Ú¡¡y_¦İ5ÿA›ıÍuè]\B#¸µÊäMX›j&L»e0V%½åíĞ¬Ş 6P	æÌA—umyÎ_	Ì–Ë”G$U6Ğœõn,‰KÛSš¬L™¶˜ä#ÔŞµG a“ nbè.å†clP8ó<‘ıâi/ gùÁŞ#4Ú¦¶”hGœÅÏ¬oXÉ4ÀTæèfûÓw›IÜéş²•ÅKïÜœ‚+=yüÃÌÿç¤/NšcNA<¼q~w[Mñş2sÍ+ÔÇ´bDğu¤ˆ©W}× ¥¦ï_Ã“@³u"/xq5Q3½ä,Êz9±ö4…×ÉòØì+g4Á>ˆƒ±®ö¨…ÉĞ¤q|HÌÉ9R½Îi§j-¥…òÛ©$2W+Y˜}ƒ¥ËZĞÖÒcÌày-å¨§òïŞå²ãpuv²nÒÄ•è–†f™Ë­s°­abwúœ/œ®Êq×éIŸ=÷ù»*ÿ6—;a3Æ}±4u³M­«@ÚĞ	(İØZÃäÔÄ˜ÛğNTfœW„êvÏÌ‚¹4€d…P‚úÛ	-yó^b@o-Ö²º·€}•gÒÒ™‹W&¤%¨XSZdu>{Ø¨Ÿôğ¿÷`&ÚõTd&õ‘
Óû9Æï’û•7^4ÚVL…´Ğš¯yChô7ÓiØé´ù	’óf"Ø}nµÔÁãa¼›Wê8>C6+Ãl Òv³e·²Uù£ø”rbVc°Ç“es²YLqš…)(H6ğé"õşúyú”>mlZílJñíBÜĞ¸äš%™Ê½KúÊëÇyi±®#p?§K«O[)ãºsâÍ–R’GGó¤qHÆRŞMŒdİUmH“D&®{”kèfŠ‰Â_'P8E¾»ÔÒ%îßñ¿h¿SàèQ£Jö9®QPıæŞÔ"ËPÖ,tÿ5q·è­ë°öùôözlğo#Cîj±GÓštµJÔ¼JqF1Äökä…Ì0¦–Í?c°P³qê[wXú&ï6?ïv¼ÅüçæŠtğÊÔ#_SLÍâ®k	íêZQâ*ŠğÒ+íï©3tY¼‰¼]<”Xíåncä§KĞºçÔhÓå›ëé°^Ã•MrÑhç¶Xs‡¨„^€Xªõ–¼ÿ°VjDÑxOkÖOtÔL†8˜âMôùí\“Ààá›J»l‚$«nwÿegWòycàáŠ1,cÇF³ñğø¾êªªA¡ètÑTLO­Ó@‘ ¦÷jgcƒpC4ŞR=BïªóÿÃ)EWE úó–°Éä–aƒ”gÇšâ™w>Ñ¶…ÍÑŞzNãÈÉ×aG¸ÌåH˜Ç©™ÿ˜¥­û§*†EÄLaÔyè&ˆG=•úÓÁ˜ô, K»™¶¾Ñ’5—DU Ãô;T°Ÿ«ºÓDmÔ°Ø±<1í¬1{y§©A¾è¾FJÒ¯<Ü§ñ(®;«EáSj¯¢jñ«3B‡¿ĞêŸJœ(de¥¹¤côíÅ6LBöÌ…’)›ìˆU¸eN‡ù¼[y££cI`}¥¸·ò Ö²hEá£JƒZ£:Şæºø…R˜‘‹mşjr8±¨å*k+Ù ¹›Ö‰ğ‚üÆÀ•©ígŒ=©Œß€«ÄÊrS/^–;<°Œ4élrzU§]ÄÀ.Ø8Ã(-3‚,Xi #tƒ¶Ê—°Û;ğt-™×E)±ïÖ9ç?ÒÛ;˜dmhÍk÷u3ãyõaÂÉ±ÀŞ{Œñ <³fŸHØÜÌ ØşÍ^ë½©ÿw¤*o»ˆ…bÁ"q1|î»ÅvKûëÃIı_şªĞÄ4©¾Õ—G¹z^Å«ã7ÆÉÃÿéÍå9«²¿ü¥8ÃrßÉêLy„úşšJ*Bş°¼ÁUY6LÎJ?O_ ¦$)ñTOøÕ2›:[>Y»@o’»õ¶Ì\‡×ÎÊRÊº<¹Ä‰
>3†¸İÒòj4ˆà/Õ_âA;uP}±d<Õje^p(á†j„dO|1ì¥’#¢ÛEH"ÍÍX]â€	!üõc˜uw_übH=IÀ-6bÙ«È[R‰ÿô9½ƒÎµ?ÀcùG[qvó<æ4ôËv­ƒ¿$óˆ‹°sòw?}Ø/6P>/[˜¢&¿‡É˜Ó|¡#yãîbAÊÖ[ôõÁo¤è2iNÇÿJDbM<˜J)hP"'£•‰×óL4;v¯¿#Z8=³"bw6IÂÖ3
#¿H¢$«w{‹›s1*3P¶]?Ò‹Ã"•ÂxyO¼8}ÿhÎü€²>RS$ø¯–ku“U®İ?*QH+ûC—ˆ^¶ØDR
¬`;½Pÿ=Ko±‡S™Üdv9½~ò°÷$&2çrŸ{Œ)ÿFLHoõÙ¨J¼=éß6C÷%i‚/æ¢Â¬½‡´ëräZfğVMİm
†9-qDUËæ}ÿy'H½ë'È÷O‚Ïxëó”n¬	ñÌäÂJ•h‡Åà»çùz(%iĞÙìÂtâZÃĞÑ…ZE†:¯š^Å„ôc•àK1¥õØA¢FpÆ1`Zû"pè{Í[ú[ïzK^7Îàst«J£8&:kéÀBºÜ+í>Jzµ`Uç3À1™‘m	KdÜ4æ®pæ•ô½BVG“]A¼´~ì­é1¡Cğ•=.<V°ŸÁŞ2©_"a^ Sv$;Ê¤lòŒG)óJçœÚX“Qï/í–³EÂü†Ş\~ÁäóÕÁW¢<M³³Ò>"Y2¯FÓò
¾Ej·¯·¥ÀÚ¯ÅB~é¿å³®Ùd@%øwb5Åè^tù—š0âuTˆO9_É`Lø%è4À'Y"[6³›@Ş4ÌS€=ZÉK¼\jZ–ÒNÑ7ä©(çÎñN0Ræç-Âøt·9;çNÙ‰i™ÿ•ÃíS¤ ¥ZNYCënÑÏÈ§-UŸ¶3Õı¸á€Ö½û"lá—;,Öw+øÛóF´b82™’­ûPÄ½Kº‚qXKºD®qŠQ]üôÎAoE"˜VR)”Ió jœ8€ln|¼jb,¾–ô‚†ß@ÂÃ«»C²¥QFİçUå¿îgz<ÅË}õ·ÏÆƒ#Ğz<ºÕ½@o,F•Â(\3êÈ™iç{S5Æ;òO^seA>=…N(%œŸ``	/Zê.Vb«šŒ)ŞºBfNzfd,VÃF]vÂ?&ÈVXë‡ÒèN´ÿÎ6ä;J'÷ƒ[_‰ÿ"	DBü:¯Ñ <•¨Ê[|YÍugÇµy¯Y*vi¶Ú…Æ]y›l ªtz›¡ÛÃ"‹ËºÖ²>ŸAêõ¥âè1ãS€n6¼izƒwÖ–w”œ–v¢İëWï™Í4zùÖè›•äºÙ6ˆÅTœˆx\ÅUÜMŞë ï Æ›ORÑ€‰6 õ$(ûtô°2€ËàCÎÎùû:óò$ıf÷ê½Úø’s£¼òîI¸¹h+ÁxÍô§ÌÓÏÕö´ï«JL—\ÔyiM_«%0«‘’yMµ$HC¾ĞM­úé‚ìrRñgÊ®Üúvè˜‘•ÿ‘BºÊeC,9_Zi?™¢İâÛ}Yù1çÕ©§Al…Ï?³íî÷Á­¹¢øóS¥€”ıÍAr ¢ ke‰ù9²–8î6ü~¾dqB¿¸–[Á5—§ˆœÙ¡r‘NéƒŞ×ñWEéòv"˜ªX˜±k]%áø[ìêê
ÔdƒR–ŒfásÈ‡áÀâquï±®Ädƒ¢Ñ÷¨J¯œ@5§\€\âlãLá`gß2<Ò DVˆ‚×"ºåÈ°QI‹¡
V¼Õ÷à©»ªí#ª+ $Ô™u˜^J
(E“DP&£ [|S5Í’‰”†ĞmÙµå>ßşßı’Ş¥c‰Î?ÁäËé…´Ê	â³n®	ˆ=údI5’
ƒÇ„Q`Æ#	"
˜œ¡†„f|ô~–®`ÑFP—sR!†™<ôè—’EÖÄb®Wtß×ÎÎp+y™.6™«ş	8—ó—f”3çåÙ—
”êíÛx ¨Yà¥Uû=“ôzƒõÖ#Â®M½¥Dá&]z~â£/ÂË­^‰ÈşŞÂ1c8è¢v:rÜCÑ=Û©ŞT9½à”vËùV±À+äŸQÚÆã2í8ÖÖ3VÑºÆÊz±‡*Å>cSø™iC,K¬}6ÔÓÌ<‚c V‘ŞtT/õN· å%‚Æûƒ4TWn¸	ã®h«ôã8ÅÜŸ$ffè¥é~ÑZ¨Pš›_pcÏ qÇ×E=(¼Êf¼±¸è¤§† è'¬ÿèSÍloSëª›=qæ
)Öòè^à?CúªÁ_¯¾°CÕïÊLHº™á8©f+®|®¤­9e‡¯ˆé;aEFOŸºlˆÉZE4<X µù,3s.ÅT“X+VvqÔ2­«EÖšcHİ]I¯•@"TedÉúØ”F&ÊC€îf"fßŞ™Njƒµ”0»Ñ+"ºDZ·rgÂ:ÃŞ!U•à g÷x{t¤Í H°dg;¤?üPûîsÜƒ;#œ&DÁÛÈ­–±Õ9]¯©•ª¿CÁk1@Šl`0¬îc^ ‡Ğ&€Ø©ë†cÔb´Ñs|ĞÒ)~é¼Ïò¿©Ÿ|’{¦H©÷‘–“Ağj-°CWxcğlã¦B‰³¦™³˜1Îñ,±v)ı™J§ïnÉå?-	pqhï^ ±ˆf¼¦p‡÷j»&sÁ:ÊõcÜC¦âãh„¨÷F¥Å“V¸ÊBÆkè±€ÚÀ‚ñĞdÜz`ı\ª
±õüÛ·ølÚô Dè·üÇş‘“³ı“PY"÷à§÷¬8Mè§‘ú¾¹ƒ…µ#æjÀrî=¥nÄD’”=¶–šJzBPyÙ˜õšÃÃ­„ƒe0ÎtyëŒô}}ùÏ:/q§HCqS“ôøç¬+Z^p»ß¹T$ÿ`ÛğÉfMNF_\Æ·&¤©Ø&,'±LSÄk”0ŒAèkæ¢âà<8O>pA«¦™/q†àA>t=ï»gË_™š°ÙkUGUÖû%aFñ„×©óÅí¨¶¬#	x|àxC’	ıP"š%]ğí…*!Aê%«% §‹`±MU‰á»<C–„ÑzIôÖ¿°W³qşéÚĞn|$Gfì¿%»¨b¼J&Yí#[Ú—E”rMHÿi´P‡y¬Øİ"å5]² HÀgreA-ˆÖÌ­îş‘·Újú‚³š«¡©·Q_£*²ê?±ñuCÉœ@2h×Mu“gcËß–\±~LÙA©xTûu{? q¥ù¸É0nQG9˜ïÅ˜L±d¤g¢3`ÆFjs5ØFBóõJV •¹ÌÆ™c4	í{C±ÿên5ñK^  uR£ë7Ízä¦'5»ÏĞPWÙ«×òÓ¶ÏY‹W'ü.Z|‰H±“NvÒ”×çp°6½×ñ#Ë;z$„t’ëŸ|š2®Ÿj]³Sõa,8RşÜr²•øE?°"ÅW§‚9-†šº%4øe6Bzy£Àã?…ìıœ[uZª¦«}K¢}-×3H8áñ;Ä•(«I•ÙM¶úÏ­dĞ…Ş6U›h£ŞM"ú!|@<¡b&ØÊ7èò›?9!Òo_|üšç¶\’ñ¨ÃŒì_n_)*ˆH9	 =ÇuĞÈ9è˜IãÈÌâş"­w­¥s©KÅ¹ ‘%&±‡Ÿõî	äø{‰a(XÕú”U°óõ&øò?†×L‡Å<KB¬TD…˜ š^Ä¹mVF¦wP_8Ÿ£ê€áöùøí{d"°›	ªaG,V/‘cxK–È¿k	›BY4ßCÒ#ü²Úm‘V&³+øÀÔœØ¾ÚÕ …©í¡ùš¼éüIwír¤&°˜Öq"­¹¶Oû OG`~9ş+uEá  5a¢ìÕA£)sûgï(kÈeu;»1¥İe€JYÑ«Ç?Pæ–.¡ù(Døò!}6ñUêÓÓÒp'GG^
ÌÑC•+û@}Ğ(ë©”ì®æÊ~:8cçÓœ¿bg	ñ.s6(MíçóÛšæNGs›F…'S†zĞb˜ßz)\3?i„ŒÂÉá0`æ&W(jŸÚù H¦‚ÊZfC>€ë¡,C|ç°L]Ú|›ÚpäœMÁå“æ?«Xrƒº&Ğó'6:ç·uuşé»‚„½JÄDCèd6ÚåùF} i8Oy×!x•/µ:ßZâ&¨´8‰ÑŸ>RLô½;…
éŸª)›¤¦çô(§wQÁóÓãUqTŸØ§ù§nĞÍFA¨#ÎiVxf‚¿¨?@•Ííxòr€¬/·k)b	›9ÔfdËÈk%ÄsÛo|«Ùt‚©‚n¡c©Šä¼Hì£-2ï÷Å ÷„¹œxÛk÷&„mfFIcÄ4ÚöiÎ1¶™§®uqãêOï[C]‹ñó]Ö	dÆènp÷â\ƒl?±jtè¨G¨VÀaÊ¾öTÈ		¦%eŒÀ­)œKâ={H–ÔQ¡£IîFçr2Å¦ìTe:Ô:ı/Öø"R°hËÓS†vKÙìŞ¶Ø4VJ8×ÌLh¨£§&±ğ“àEÕ
F¾Æİ;u¹‚™3ÆqÕ~A…õZ•¥é9tâEFøWC¬-©Vóú$ñÈ–ÊUğ…ÈF.²o2Zœ¸ô¾,›:ç½<îøı.´ıÖyy;‰”Ã'À¾ÄÈŸë0_-¦x€æ94¢ó¬u‘rH¤µ+~{2Øó‘jú£‡#SHÒ>4p:Z]¬^>áOô›Nf®RÁÅ³·ü¶„:I»ä¥ëeç[Awhvœ5ãÉêHŞ#"l“$şèØù 7¢^T¨4İœy’Î„N[=—ê¬ÏvèbÓ*áL†*)Éë­ÕıA^®w"GQÿ‘¸\¾½Tw_Ñÿä†{ZããKRjÄ8/y×¿¯í¢¯¢ğòÿDméâôE¿U~ı/¿½ç÷´ÖÑç‰KR¢ñX>Qa á3}vx'Ğõ5¡¨ô4EÀ0EŒÊ'âŸBŸñg5;À{Kü®eŞF»eÅoÛß„‘ˆ-Dô¦4³Nf‘rÀäR‹1eÔ2Ñh#LVFÎ³4'P±]Ğ´@Ip~Îéä»4KE®8¬‰
,‘/ÃÜ)®›FfËgíeü'ëÂk`°åB¨(¡\FçÒĞ)àÔL·!k\a¬ÙÁ 5>>«PœÜ*ºÙëŞŠÖë¦Ş¦›2\õ¿‰<Ùˆ9L93¯,˜æï*û$^qOÛÛùÒğö@Zw¾‘eÛïIÖdÇ i#İî/XçÙ ¤Àm¾t¶ )MquYc’K] øõ ¯pX°îß‰Öó—î‚À+u™“s¦¥Åb6¢‘¬Š„ŒÈQ‚Şæ@[8‹˜qC;ş…_ÎU^Z{F/ğ‚ì'ñXıïmƒ¤#³â	y“¸'!Ò\¦ŞİÅ»ÍO@fôq‘å§Ğ´‘´¶M¸,èd­ÿúãuİŞ™·çd¾âu¸“Éã‘Û4.Xçp'Iïœä™–²œß"öÛª–ùzheÁGX ¢m¬Oîœk•,µhÄüÇ)êTü/YLå¦pBT¯QœÒ÷ôWsãşg!Û%4³¸˜Ê»ˆ3¾ºêå6HH+…V•g›@öŸK4^ou¨Ö³§S0æ–ùz©Cªæ´h75$º±@äı×:m§·­CÀbèHÚküÚsì3 t¸Şé²=êÍÄ½âî.p†**¤ƒÑ§Ò6µÎ«À]’«* Pİ.MÔñık¬ÇÆJŸØ€ÜU†f,ğ¤×·Oô^LØÑñ7œRšƒ­91²ï?„ë'I½~é¦üq­¤Ä¹mó°ìÒÏ-ÿ—ö8d·{‘WL¿,åópg…¢Ä7JK
Ğ­pb•œˆ¡õ*è¢—uÉp”YœÊñF.s\—)“£FŠt‹¥ÍM('/?# üev=ˆï~z0¦Í;uèç?íF9ck¦5åiÉ~D<#„²'#È¾FŸÈ»ŞËÀø‡n˜ÿÄÇr¸Z‚LL)­]Ş»
Ğk÷t??Õ‰Wêş«#ú^A€æ\ô=ŠJ4iÖîf¸j:H)Ü¤àµl“Ñ˜W•ÈÇ£YC+¿(÷ÜM™<R­y¸¬~Ú$Èl¦Ûó—f¢ó9{ß­šM4ò’=òŠfº ê$¨2F&«®ĞJ±<‡+´Q[ºıI0²ò©¶0‡·×ë9…})Ì€Wó/‹z®æ±Æ7jr£@0ÊØ(\ƒ	Æê+©²æ=İ×&¨ƒ¿%Êğ˜qÁ9‰]Ÿ“SşCN³ù^tc2Bkf<;­/¶0şuû/òúƒ÷Thj ÂUlÿO(‡åaÔN€dG«3KéÉØÜ_–ıQ†¹JØQ;¢ŠSd×˜Å[:—¿jšÿàLm7wh×ã¹§y×øÖ}wÚÂ·6eRÊÁ}5î‹”ùœÖ<¥¯ûÿ7+
M2gXcQ‡9ƒè{¼á†ú¼_û6d²‚
i‚mY•@‡œHÏşhé~eò¾¸ktQ÷¦í’ÁŠ4Úæ^K	²y~¿ÇÿˆšA.Ğ	MÃq75LĞMÉªj {{€™¶ãz´ î7Àº<³œ€½µöÙİ„§<ÏXŠiòŠğ²1÷6•/º³WáîJ,SR¾˜Ê±6ş B>Š²/œö3æoà´Òğ–ßê«n¸]Y<hä‡Õ[|Ô}Æfeack£fÉ©´"6";äáÒJ©ôpÚf€øï .t.;n—é‚5DêL.û³Íßó¥¤Vÿ#šGUÄ]F‰Ö5ÖÉr–<‚\|´ñš8˜?×®[´ÄÑ•‹ÚèĞù¶Àœ¸õtOªùaåñ²ãÊzØ´c˜ğGwé£)¶Ä}œ.B_¼	‹g÷Š”Ö|î[-DÌ’`Ş‡Ç15ÕÔ¨N2gaú]\¦o©¹vœQâµféº1f3ƒ‚,Lè;«¯ÛIØ2+o3wx}©Ş¹s	ÄGŒáŸlcİ…°WRÔu¢ç¿\PítÏ„æ6út§İµ4EÄª]ÛL#‘å–ÙCøŒ’U¯ÑÍÙğÜ³F4™®¢¡‡(xéOÓª2Ó‰ïB®sÀ¦Ô¸¬ö´Û®iîí/wBb‹&‰ğñšıayªáİvG½vJP/†úo@v ˆVñú±töÆß|†”WÄÉuvfYï¯<…j>ó®3°Ky¦Îv«İ‰¤ßf^o‰ÎYçŒîĞÙx@¸-*ãŒA°S—‡\¤ ÁKî\¡GkùÃ[ğ9c_`KäÍÿ>hB”	Ûåa?Wxp>ãïvÉƒÖD#µ¢‹rÁ&Å>pê?<GÚ3aØô¼²5PŒ#Şœ0HÛşİ1ÛD°Ù$ÁˆÆëXÁŒº(øÔ*şˆ–Ò|g¥TÌ•á­hG~MD¦é8§‰ó6¦ágİï8Ò˜çtj¢ˆ–_]¿İnXL<=g 7õÈc„+6÷•0}B¸WÃw”Ï;Œf8
jz8¶ÁŸ•E¯[åìzïÌ„t	®ªº%ÃŠ´‹5W*<ÆÔfÙ·˜µtÓ¬Ô Gw¤°oıìÜ`10:¬2JF“İé)Aš4ïPJâ*å	š‹óÈç›Ûyù{å¬Ó>Œü¸VpI„œXØİÄjšr]ßGèìÏéG¼x`ç#ëiYß›òs+Ù:½O.+½ƒM°ROÑy½A{ï TªëwmJUf_Î‘€~®Ù˜-)„RªLákÅFQ£©P.¤’$„/¿ã”é±^*uì[íİäı`Õ £ìYk„Ñ²â-$[RrI%èáìg{ÂÄ´Sp×"»´nÕo•–İÄYàI«ÛŠ€ŒKE–¨—=“î»Qã©Ôğ%n“¡È|sh½6¢±4ÄîF´S’ëlnÅ—~–ë®W`ÎÁ$¼¸ùspÂJ®àRÎ“ÊQ-$L¹›¢‘•¿—‚ÊcJ\*ªDò„úg± dR‚çZr©
1ÇÕ   Œé	¨¢Ir ûÊ€°³¶9±Ägû    YZ