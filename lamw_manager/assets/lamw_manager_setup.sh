#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1381913976"
MD5="d613b14565e7ce7b0940bffc7df78f4d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25808"
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
	echo Date of packaging: Fri Dec 31 00:45:33 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌâÿd] ¼}•À1Dd]‡Á›PætİDõ#ãäÏŠbøb ¯V'GüÄù&KR¾kmëˆ% E_itgKƒ‡<âCï•èÛ$<,ı_—¢Ô‡·3±öœÏ§’¸1¼Ù9|	ÜX}ZÌDûw$Ğ£¤»ş•{Ë‹ìj@ëPÖèß2˜eI³2›¬Ãªs‡ğ‚©•ÉQª ×óÖyæUå†²ÿ­¤‹…às“t>İÃÚË„qö|JbÄ‡Rp‰hRËºÁÓ6jQöY'ç¬Ït¶ÉQ¹ÇÚ>
udİÈJf‰ós6æö“ÏaRß»'Å»|XÈ°6ü+¥Rg®¸$ô…WÂ(ØAüåàC¶ÕgF\X¿g øÿN<HqmÀB"^˜÷±?Nh´HNü—?²Şf)k k3éÙ5?øÕÕwû	~•¶1³µDFÈù÷
4ö¬¤€1¹\¢È|r·RÒ¢J?Ÿ PŠM»8®CQw=ˆVó>I¾‰7Èf?«u»Š›BeñŞWÙ;òZÍ4BìTñÊ}8!¦ÊètÁ,90/:Õå½íñö!<P7Áû4ÎOî{šŸªo\£±ÛWZ–µII2'	ÑÍv÷‡+bWVnz[ãë ®-XU9=€c˜k€1†ŞCÂ¼ÌˆnØ+´Õb™ãLªfã‚‡ÅÌnıò#–X@é.}H.dN¼ú;Œò5¦5|ÔŸ>PP_#8Á-~—£n5AİSm*
[ÚÊ]¼Ş?&2—ÜÉ­'’ò×—Kgr‘ês›Š¤ş	V‹kÔ
lå]¸áO×Îæd4ŠÙØÕÓãL¸îù©àÍ³v<Ø’Â[]åıËÅüé@5^ÓÑIÃã§¤5O»¯ëÙàD¶ 
_ÌaÉœ•RÁaÚI°ˆöeä³nŸÊ·'PÇt¦`F”Eÿ+êwSÀD:£ì™O×Ú¯@fíƒ {Š’ëuşªS§Ú]Ş;T-DèÙÈj2ç/xğiÈæ”ÿ `zhRÍŸ4kéhÆáÜ2eÕWÔ=É9YG‹Úx­:ÊÄ'õñ'ŠQõˆˆb7¾Ã‰¾£0tê¬I‚7J¸÷$5%õ\Æ)Ì‚Ã½Ş„bÎÇ<4ªÈ¬‡Øé3¤}KX¼/>Ğh]X§Ã
ßtLz\Ğ ›o£¥•C!#zŞÂ8s,ekt•©“°!œæ¡®‹ÚØŒ}½Ü“!„­Q›Šú £ByA{gx;¿“°\ÛÃ'MÅŒv”kZ<BNÎœãï”®Aø×nƒØ=t’Ÿ+Îkg\îÉ×o°˜|MÍ˜÷hº°¦~VV~æ.‡?¨`1¬P*K‹eÂÜóY½!JÜğçyz¥íúˆR{ÁR·O—TŸ. ‚á0²£@­ôÄe+X–{*Ğ(Uh| ıMğÄq¥ÜùƒYPÇÉÈä"İRÄªXv¡û*;YÔPË:‰«3|ñİ:JqQcÄ¸°gjæŒ9ù8Ÿ@‘0èBº«ãåú‡Yé$Ê¥„;±Z‘±ø‘poïç5Pr3.0[yh‘Æ•¿Û™—šÜkİÖã…YA<?6M»z²"r¤e­–Ú±q}â—Õ¶h&a“M–CïÓ,à£YK¢­[†¾¯¹L<2ã[Añ×n_œ%U‡Õûµ)l‚Šb5.i+.*#E~õ.y 1H\ÆZÏhgL>¾rÔÏeVĞA#,íÄ¯\n»Æ|óhü/ƒhñnS2ÈªÏÉ¯&:©–‹#E€~ì|¬Ğ”»[AÅQZIÙİTü«%ÑÄAW˜cå È4ÜÍ®;‡ùmÚ;D2¯°×Å‡Î·oò	%4âÇ¼È‚±RhKÀ²‡ÊWğfå³Ø™¸ŸH¦yŸµë¡ínv«k™‘`0©ïkŞ­±üàK½&ÀW9Œ5V~Ş™P‡`Ô‹ SØüPšôPm‹vYuOY„Xê[o×vùíyİ'Ñk\Ï Y¡¯Œ«À!d’Ø×é›vP‚¤hk²”,xÉí ÊÚí8ÁZ#÷Èñ¿ì½O €¶Oü¿M{~	^	ÙX›1~§âØŠİóø×Glj¬©à›Ã5»à²m|Ö'J;b[¾6Ğ<-pÇ”3ä²£ˆê
åú¤-|äY |UvëÑ×o]ÜzŞ»Ò¾£~d¬HF˜Ù©•Æzø¡´‘ª²CŞìMÊ=Ü33UXG³ñİLY¿JubZS€Ò§Wçš}ÖFıÈ¾rzÏ­pLs£­1ôsŸÅgOŸÂ—0[Ú—†x­øa)^H5¹_lb™|ÇûÉ’¤öÒ2N3éİ!»HiG×ŞØây'ÛÃ†àp‹ñfw‹ÆÊİ¯w‚+ÿUS¶yóHiØ]/ôºZÙµVØ™IñƒÇ¼ÃÙÚò¡?¡0ËJ³¸‚K Î,€0xİ\†e:º‡‰§è#İ½Vy˜
ÜıÃúi·½àI·%Ô?„é…&×êØe?‰µéÌ[às…ˆœq4GPzçŒŠkÓ/¯x™è
ÖL5“Ôvã‚„FÂuyItøf/ü9Õg¡`ÓİŞ€‡`.+(èôÔ3œø5‚½„A ÇæÌRFàRL–*ÏEëŸ±}Bÿîuæ~t¥Ô<½IìÍHï#I™CÏ{voüQp®vf3uâá…€fUæyX]´~@”¤Íb£Ö¦Ç  ,æ¯1YíİÍuÛºÿ©32Zt|šèUÏ]…»-Ûˆ©h¯ËğÕ¦ıIk/à0ÀÛƒÇäPçû¤Óô³¡õdÚ©ÚÛ0M˜mûLšhí–ƒoÎ‘ã;a#ÃˆÇšô(‘’ÿ®$pk”F•aóa»¡­!K@´ ~¹«Ñ6Ğ2¿(¸@Ì®W8¾PÔƒ×0â½Vtq±evszX€MZ"º`,§Ãõ£Å_»^O©a…¨³£ó·›GêÓq^¶wm"Yp/XJÂ-ğy:´›*K®CaÖD¨ï™-LùIYx£fU¬>il™Oœ'œA×-…Â·¥üêLÊØ€Ø+¡t^ÌÛ#‹|é›º<Yæ´|ó˜™±ƒ>Ø'eà-_¶}›ëßDex4óU)³ü.ÁwW5OŠ¶kÃÿå9e §B0ªø(ñiJ%"¢ûX<*™ i"dÓ_Øgìú¬SºĞ #dxN¸6,Flªû©²Ğ°4ùŸFì­Ù¢ÃÇ›öBWc‹©wä«ˆ3Ó.šˆAx`ıâu¨ÂH|S²È±>İgİæğ¨¥ÈI¸ ²ñ˜q¤Ô\½‚üvØM×=eI§ xL˜ÓpİC»¼C^„ Ù]k‹yúj†‡o>âˆ½©ù¡2›TŞ¡ÎbòÿºÌ“õ×èĞrBò$Š•A@Q—ió;ôß²®ÁÖHÍŠ
èWãJ<ES uAh¡éÕß\_êƒLĞ¤1ı†µ_ş¾L0Ø€¡s˜xpa?ëÒõÀšO8'>èd•Ï%ñaC".C£ÄãBçÑ²¿e_ëª660ŞÇXºS°æ1²]EÉÖ¬oíÀ‰B¤”<œVı<m<e¸yØ[<%P@kŒ½ÜmC¾£k³%ˆ:2?ïöº­+¶ƒ„m7?ÏÕ
=ÓÜ„O•¹²…Ã`jXøoã¾Ô±Úz”Æk/»„jVU(C	8"A•Ã<ucS°x ø§ü¿èO­j¶$ ™vHÔIt“sğ©¶F–±ÀßK¼¶Mr«ïeÎe”Çc'1œ5ş-~v•†0H¡š}“‘˜˜4ËĞp8r$rmyşĞÎäli¸Ÿ˜·ëÇ}n\­³–İÁ/®'Îrİşˆ$•S£¤aVq‹%Ë}¯™ÛÈ´…qhî >/:~ûiYï¸U5÷‡<¶É.75e”…ÌÂxİe/êğ$“YM;érF/[ÆÍ[g¬g5riÒŒ'Á"!¢oÈÛj©Q\’oMzJq€ÄäESÅN>¿ìOB]–—}?jêZıù>3•+ªù(ªŠPC`û£BÎôr]/³çÜ>ó4×f)Érl„8ÔG:Ü  îfÑ»-Õóp@(EvòNöìqHD<BD¹rÎÀ‰—{JÖ§è{_1„SæäIßô–SWÅ¦¸ıq£”†š':YŒ1²›–~ã°Ah
k§ğÛw_˜Ã¡ñ56‡wı\y¿¾(\t%ĞPëbÎŞ”¾}™éké'¤t
eÆhBÙJ©~\åª/xTag¡LØ9ÔÌ¶¥^¯ÛuNÓc Â‡“ıp"ÌôÄÏ=ç{;§EˆiENn_Q× ŸÂSaÈ?ÒôOÍê€Ş"¨¨YÖ,Lê†—[a3óç¤èÜúŒ’õÅ@ÖÚ±e–ıê'Äø®‹Ç…„FÂiÚ°şcô¼FŠ¤HZ_êm»e0¥ÜÿWÆn<HùÒ;V±bû\>ŞÙCö)	±¨¹iÕè ïë 2úlĞ¼HRõ1¸±‘‰ŠÎ$Oÿ ,Ó­Œ}nM“J²ì3æáº~¦¿)ó<±v’üX¼µ×›Ø…0ÒQGÆ"Bhµ8¥®Ó¥„^‹˜ËğG@Eî$ÜbZl]jĞi ü·G"š4oWSù&-ĞÛ­!èqú¬àã°$¼zhVÅ÷HÊmQOºÁV¿ ¡ù¢[h\
÷³Õ(a¿{‰0(æ‹£ØÕ¿¤°lŠï ]ñG+"8{ÍƒB}0ƒ²0éËf&^q§îãÇ¿Nè@VüÇ‡	ïñÙa®¸Ïó^yCÖæTLå"2ÀÇ´w?ãWy(â„ÇŞ÷Ä"ì˜İGÓ¡ò`¿f.ó‡1Ã@Íº§ÂBçüË¦*öoqûPoWv_¸3îÉô^áŞZ×5£±{˜ğO°:±GÎw›¢¹³ŞƒšsA¨¼¬lnÔÏ¡^ßö¯á3¶LZñ¦·1m°vı±KY GíÁÈˆoI¦u`ÏG“È³‰îl¿zö5é‡ó-…òá-¥¶Ô™ïZE
ætê/(¤ÇË7z¸BË?¨»óº/bziÙ5ŸFNP¯6ZŞ`ó–éE»T¾
«ì)BÆÃ-¤"ù'4ŠbS¨I²Á:î4uıÂÙïºWı×<yèŸu•ƒ^ËTÕı#£Ÿå¤G[¼x†+‹Ëj¼˜í=õÇÄD&å?8µä‹õ×<Sß»~¼UåÆ«O<üÃ‚sõŸôtˆ(Mb×º¤ÊJ’]¦d«4d²Ëy—½‘XF&7È5ÕøºûE¾¼I¸~‹·ç‡û^[ü'®0Û±ÂK–[ ˆCî%|^×Œ®§³¡æ”å–„C÷×4Ct‘¹ÁÖ¥Rñt:›Æ+¢ñğ —›Go+=åGNR€fÇ}ÆÏ‡Z˜Jµæ1ü»ğ¡» ¡Õ&PVcÊÅåtûs›‹p6=àn:7{šËŒ/Ğ#ñ_N&Äü”³`;Ì¾ÆåÜ%0CÛrÄ0ã·û¥ÔpQÇèåÃÏW,F P¦2ùw¹G
´Õ%°-Mä'Ü<ŠAgŸ>É¸¶=´$ÅÁüÒDÎ#â¥6
KvÎg	¤ÜÚC@Ã³7Dx7¿Œ3'&	bíZ46'!àÈ„ü'i$UÅ2ÁRb1¢UVB¦UVƒÂŞN¥@^&V< ğÛ7‡n‚†G¯BàŠS UHû·Bêõ”Àr!@S…1Èk¢õÍyĞ“Ö;µYÛíÅ’òœÖÖƒÙ”Õ?ˆô÷—uÏF¿†ÜlV‹mø-ßz,c±ŠC-Ÿ&í\â3O«b$w¿uè,û™ó>€ÜİŞ:¿1æ’°ÔÅí_,$zwnï(°¸•Ê0~LÁîİ¨Øöl¨EW|ÉCN^e`6âçqHWJjMîyRû÷¸ø
9u”™¡OvãNù°>lù÷Å‹õC"„qjğ?4›ùÿ‰´¢9nŸ¹H'$Pîp×0ŠˆBvªÖé•œtq~ÔÑŸM9{æÆ´š»šö¸Bö;¯İ	Ğæøÿr¤$3Z)1§Ôuôèé&5†Oã¹Ü>üù‹Ï/>Û¤Rİo5hMü„rœ9H¶Àãßşe©×2gqxyÆŒ–¬ÑóR ;u_·é˜BW	; »jpO¬#YPÑZ
§ñ#N„É˜Ù9ëio\ÒÄJé@Èî™·tÜæãÛ‹ô™?hTƒjÕAË•Ş÷’ï­#?/p_º¾nléÜ<†›$©ŠHm`$5œ(ú1uÜÁ×‚şºæÙlhãVˆµ+±¾†ÌÑŠµUì€¡òHï5rÇqRµÉÅtV<Äv½/Wôï/=ª#¡o¸zJMtfA© fq(n=ójÆÿ‘ˆBbÉ ùøZu²”Î«q©Ã¼#”tK½ú¤ùxN‡lĞ¥ş9¢Â’¹šúãåa¡ú×C]j|àüWœ><QÜ0€*%©’µ._Ü#é§rvM1aåø>{±|5ÖÙRÂSX;q1¸Ù¨nQ:¨²|«áí0™hsL¹n…E„Q-Ê!ccˆáß×_kŞƒÕNhô¡WP¡¿s&Ã¼ÿ/ŸÀş8ÛÒU šÁ?›a“-‡n™f¯Ö£Íœ™vÍÌ@Ú|Xp"1”ÃşoÚb¯ËÔµ®EVÄèfŸÜ]«±
Â<<J‹é¹¡i;‹/g. ¾7ióÁhS…†FŸ$§öÁÖÂníĞ`5sØYÕ²Ç‰ÉÒÖ~|™¹éZÎÑÔ	{~øQ€CF“ÈóÌÑa-k½öë/†j;ú[ QR\ß›¨SÑ&Hå(‘¥Ïú~øáÁLÖ„:¢ÇëyØ”dmÃ«ËŠXuÏ˜¶ ²é
7ÃxåO*ö-°®úÓCämÕË©.vP)}¼á8Áééeé‘3·»9ªìoÚöVh‘ oãSø;5=9B%nT÷Xº=gP9Šúèëgä–G^­ˆ¡$”µ;ë¤cu4wÊ0uv¢u@¥‰ho…1ªÙ¢qAª3£›Õ®e¶°ÀÛÕ5ÔĞí”¼:uA\˜“;2ßÏıXšJöTójN‡áO8à¡z”„ˆ%
ş6¸†&)wtĞœf -sn!²§"M7H|QŞïbĞ`7çæàß<aIî¬özBÔ*ÕÁà¥ÉÉÜ5}w™‰ŒĞÅlêš”æ¬šH­òÕì#¨1„¸¸“®p_öÈÇ7gù$/)èoèÑD8şôn×„l©äë–9BˆîĞ¶»AcEf4.uºr=Ê4m=İqĞÌúO@înœ÷~¬ázSPÌh°nûıñüvş²SıO¡Ù0›Šâ upén†qŠô‘ Ç`¨-mYÜ2C?h›)°¸¶‡À!]cã8Bw,ÒnõÂup.Ğ¯òh»ºåÄÜqwº˜QºaĞv ió(ŠÛ;ºUÉŞŞºbmËŒ:ÀGE¦Š‚®K¾r¾Ø²Š5`Ùpl	^Û]T ğQ{´ì†|Å742—æÎfPé¿ÂwOæ£™ˆ·¨ÈĞ?=[¨7vßükç_wòöGºşse&båØÕ–‹PøÎÃ#}kÊµå¬V%íÜÆ™øç;é„„xR‘¿î1;|JÈëzjÁk—Tã‘˜sI­È¾ãÖå{‡îY§Áó¼Ñt±Ö«³éIïMa3QÆ|õ7Zç@~Ìˆ“ª\ˆç}Ş¶^Q"ÛI€tSış¥;¼ÛQöĞŸ§¿’Ö1¥ •º´‡/à-¾şè¼	“²UÅ„ƒL0¤{ÙLCĞ<éJ¸›§¥¹©ÉÀù¦èEÌ b{^«”h84„ã¥g´òÛÎúôR–Â$ãM.™èNuWa¤Co+Mæ‘¤nÖHE6/0x> /èä04Ö‚øèÅğ	Jó»¾3sĞV[ M®J5•H=ú\èÙT¦Ïh ¯ÑÖ¨Ó)$Ëàø[²_úãsˆŠÕ§³×‰ÔæÕ¤öS0d96'7I"şÖC.¼ú/"sĞ^3üÆŸkÉo’–‡¥£ñßß\b´‘†5ı]¼;]ÄØ3l{ˆ§	éöNÑ€„9õwiÊK”ü·¿6şºŞ†Äˆí¼‡›š‚çNNínüqˆÇ&è:À_R6İ»¦9oô¹’£œo ºUÒ‘.5Ë‘¥q—?+y2üõZ°ÅàJiœ‰Û-0 ÀjrøÂ]³ }Éš½˜Í+ã0°gÅü©¼T~¨ÂSË‹Üä(}±ùvNFÿ¶ékÙMÔ¼ø»ÈŠ]ê·*$O9&^QS$±óÆ~ĞUD‹ı¾æc«±^¨µ³w½@°oÁ8‘å§Ö‰Ò}i ÛşSA-õo‘@ÒÊûØØ¦ä'8>(Õ2ì.*èmƒ%eÏ®!îÜ{ªöB€B1×ºIy¼È§LöÀÙs®ƒ³8Ë+w´¤·Ur•ŸjÿÆÒÁƒÿ9|šÂØ»U
/r8*Ê?D†;DcJìïï†7ùd6Î}óY¥ÒkPÂƒo}:üÇBEÍeØ¤Ae¡PùR
ºA©¶Iü-0hWÚ)Ú„öD²oŠÒ\½&˜0ÔO~­2´
ŸÎ)=Î·!Èêy–R SèÚ¢ú¾Ùmg®[.€ÂßÜd)¯²‹"gÌ
ÍS‹Û¦~ ÿD­×åzôHaçz”ísVT=Úåt)±­Ö:ÑYÇ4é	én³±Ylok¥nî	=<É7VŸ=·[“ÎRFçïóDÙ©#ü?/W;²W–³šN²×WÏGJwõi7Ì‰øÂ‹6}L¾}Æı÷œ*púk+¢H«ø:Á£ÙV¢0%KTG	ñÚC8ZP„bL[ ÿlwªZ.Ëò,,ä:ØÜ’AúÔ~ÆŒ7«îŸ:ÖgUûºáI"+®2åa’àúXš~Aaİ¥ãÎ#4­H¾g§°!§,ººE“ ÷ezWİòğšŞ'%ñÁÔ?~u6¦}«…$lv0|>RB[¡íY#ÂìòªuÚñíEÂŸ€¨ë‰[jÏ: 4	íØ!&¯âçnğ®­Ä\S%Ë`ƒË¨úĞí,@ ¨<¥~dš÷½=Ÿn1­p]£Ô§%9Ëv
04È¾ó5¶«î­^,:ü1;>ŸîPY[ˆÚã#\7KæÊíÿs%o½djnOˆİHìvOÜ¸	K¦íH¾…b´U¥t.XIàq™·Ñ+¿6<û~~éPBG~ú®u+áQ¦DÚÏìİÙFü5öú{foˆğƒ¦&íG—«”¢NÜH8Pt2ë¼k/]fì~imP¹Ü'¤¿•‡¬Bx4W«Â?6ğq¿ÇÑİ‘ÅOØG1ÉÅ¥àıë·t´>É{‰#0¨~u…ØtBêÏ†x®ÊËêmÉøÿõéıâ­ógÇ'tÌ‚ú;¼Na|ù°//8àfÿßş°ª"ºd1È¹pgÍÅ­’Uë¬{‰4˜³öÄ.n!û’Œl]ÀcŠHp™M*µ´¦ppÄV"7`òÆ·¿5¨Znº=µ«×%Ğñ§Mšı”Ì>§J%Á2_½û	S©S–ÁıÎ-+ìŠƒ° Éoæ”ÆQÈ©^Ú%k¨v»7"î¢qn"Eá)s>{>;4q<ŞÏ%º»ÈILoö*¸mÓ²|}$lb‡1k¾–R™xt Gé"á•7·„=¼ìhRŒóë+QåEË¹¶c‚ÉCa0ƒ™S™ôêÇjøzzÏÅn¡ŒØo$À´à™Wª S0+©ğ”¦r´.O¸g§¾°ĞFà.g½T×–Ä£È=£zrÌ+„µOóm]¸UÙ;-gzÜ
Ô(ñ°Õ7mæ9ñf;=™ÕìçŠŞ³›œ¸	.·ÿ·00P#À ãÄ|½ØŠÕaÿJ÷ãô!)~ sÌ	ÃDÅñg-øê½¸–&õ œù©(Å<¸ó¢ƒl«­™ƒ?T›B¡½á2Œï)	1XHçù˜ÆÏÖî|m*©w»÷ÿãşK€T´^Š¢ÏÍ(R!¶Q®hˆ!‚BŒv4'§Úë
àŒpÉY¦‡M²§+ıÚÚ^4½¸ú„±£Æ‚-¸™·ÁÍ£uôgbïöš¸¸J’öİl¥›Á/»	qÇAsv#Ş…®Œ3ynH$[Çkyç —d¹vÜlSÀÃ«ÒÂ8ó®2kpîwˆÛ@õ¢´ùşÉ˜è1ŠCÅ4 }•a©3hcl¡H~_Ä,ï³<²!<Ã¯ãíÖÁ/k¢bĞŠ•ºK$'Ÿ‰øˆŠÖP~ŞUGÃÄJr?¬
&”¡J*WìÉk+ƒQ;™ÎT .É»¦¡äÃàóÏ¯×Û¬ÙÍĞ¹™G«×Íùe¢\Åö¡¹<¯ÿ;a|
HSRtˆ],úg•r4ß†¡ù¯€“øM‚#a9¤ô=/áKrt%ÎÍóoYæu•%2‹ˆ}R $8âzÖ¸ÈšĞAõf5>-àˆÖmsüNxóg…³4‘	8Fo¥} 
W˜O†Ş*v\’¤“ò>ÃëœOUàÜ<ŒŸ~QÂÚÁŸFºHj}n U¢‰¸İì‹¿úÑ“]z)ã´g³™bûrÙ®áÀ0ü½æB$Ü‚DÎÊ2>‘*/ª-QES¼ûª¡uğqĞPö¬kÜÿP%}mG–üÄLµĞï[zæU¾ßfW]q8¬(ØÀšk;™0ù)¿+ÛÏœ}Ş+ó¤X²œRÓ]â*ıƒhQ-‚ó‚Q…¦•ff¶¶iú_òMÚÊnÎ¼\|7w› Ì®¯><DxÉ}ÆmØ+TÍìN„ã-aádS~M‰’J–U#ÖJöõÚ´ 5#÷ª}ÕLš;D‹jı‡8×¦ñ¯n^n'‚R'_tìA ªŒëÎiJÑ»·dÆÃUÉàbt'“7`=u‚.ÚÔîKŸï›0:D6Ö"¼Hò©D¹Pè8rÄ6¹VGh…-C°r‚ÅÓõ/1;Ë\ËTXGªÙ&Ñºo®WOö¨ğÈï}áI=Îº"^´+nÉŸÏGªøÄÂ¯¯”H™ŠJD“¶@ã9+oÚåáÓª!—Ë‰6&•#£ÈŒ¶Ç¶J˜¥éÂP/íòæÜ:®C?X
gŞõµõ–gÁà©ÙœiùXmFUÁõA£Np9V]¸}/_ŠÂ1ØPpÆŞöAº:×şICäXEÂµ”¦v8J#X@÷Ô¹œD÷iwiªNüá¡'5Ÿ(ò+Şæ$cÌfş"í—¸.æ§Ñøù8ø Ğ4ÆË*Øªİ†DDvïkx)zúÛ Š¥8LÈJ¸(ÅÔ—ÌxgyÒ¥ ÷8L0y¦¬àÌ&Ê¨ôÃö-^şØ:¼°{¹quQ–0:µOHGş²*”8±GÆGãsÙ”ù¢‘¢óKşĞ‰)4’;ï-©‰eùàòËØË¤åAı°¡@ûõ3NÀÏ'ä¸Lc3rt6ÃÔçgêğÖØ:¾ùıø¡!lMOW®É!ïËt¡Îñb<ï\ıÂÓ—²8zj@LúRŒÆç›ş*›¤=«·š­•¸DÃ3'¹9‰xNnØ°Òña¾ø>¡Vø¸)Ì<ÁuèŞıÔÄÿ-%­~¾^ö(³Ó½ÊŸ´±•c^¯àís¶|:”ğ¶“Ë¬R^¬`Á@­A¯ÿÇñj¢İÑ¥lC«¬«“¹Üö68Ê)’	[-ÏaD•ìæ¨î8x5N$V}G	 |Pš“7®\€Çer?è'gµ·5~_‘é½
Ÿõs"òş’ÂªDã–X­™5t™yôî\èiüT-i2¸†_ìÎ:s8h§æÖì¥‚\®«{Aµ
£LD¤$‘ƒ¢šwíãr„¾GéƒTúŠ‹OxÛØ/Tª¡Dõ±][1a§ô•õ„Q=à®®¡×wÍ©*mÓägq­Şê‚‡
Gğv±®
[Eµ#)ó}»'?tZ—5dïÆAE·&°]òŸÕ
Ó™´åÍzÈ€P¥7Ó}ãË;ş`>ÅæúF&À3w±Ì[ ÑD·ş˜;åCu’Şù- öà°ñÖbß×Ú³ñ{¶ŸbşºŒ*Ò2ÁOÙ›şáT¨µy€X¿÷1`˜*-Ø””• ‰&>êªŸC<'#…—:êöÛÎ^4¿18äŸ/Dùy ©ş0}€‘Şîp‘/!„•_Œõ L†0ÏÙÏIö­`<:¡çÌa«6g4£’ó±‹©™¤HÏ9X…•uùc›ĞÂÿüø–>èªnı×#ú—tGpë}ïïãOà@jŸÕqüúmŞk!GÈ_>Æ@ÀÚ§|
ùï3wÖú€áúÎ<ól	­¥Nõ;­Ùq¦+DÚA
÷ærT·ƒg6ÕÜÜ”ÊQŞR€Œ“wÕ¡î 0S
wÙÒTFí Hğ@¥úoØv±ÏUƒ¸k8‘!3¬w¾’£ºVfR©w”9İ^€€knh´9ó<M¯i@…Ü|ÿ\¿½¯&i5†y‰…‡¶ò­ÕMETWí˜±÷EœÄ{¹ünÂŠT Jğ«¬NÅ¨ª£çmµ²Ğ.åòWO‡níßÀu2
Ğ,†ßŠ‡Ud²è…¢o¥.VL>£<~·*ç“!‰M¯IÏ&Èİ[•‹XŒà!G!ô‡1ÂR’eõ¨	N“,¯-›gìúeŸ*;,~hØa`ÜVèµ[[#iµ£œijJkãŠDıÕ€C‘ t¹ĞùD…ü±.»é›M.¿ÊÁ˜kñ7*Æz5BµŸA‘•;I‚kïteB³…Á™«Ø](Ó1ÙŠ ¦İŞõqÂÒÙNç_kS{ZÒ‚ášÎşlÁ™ı›<f@’®…{xÓõR*3Ş_G?Òş=YSJFÔ4e`.ù•D’.ÿàÉ~Mèf ›š]¹óÕö¤ùp¾"ûkã˜bÀ‘û±„[â‰ØUè¦–¿¸:»yÃ%ùx£É¤%Ç™< mşX4"°ğƒ#b9+“>à_Ø.@Â%•BRÚ¯ÜlHÉJa9lLVPš +±UA(îÂs‘k…XÈïÉ®MYĞĞğ´	ÖY ‚g-eÜÀ;êåúÁ›WÎÒÃ”ÿ0tš5Ÿ
B
ája‘g;í£	 e“Ü‚Ş›ÃŒVøüc‚/"Ã 9¼At)y3MUOçÕëôñ·(móòŠßu”~©M”ÿ‘öDúşB1Œ»1(ñ?Ûğo[:İ]<Í¨"m<b§‰£%42úëXƒàAT|(«Ştê´e|€pp°µˆÂÏ¢xû^]ÿ¨¾—åòâİÒƒ0™­ŠËÉÄè¼ P=ÅhÉ³µ2´èËF©h@å²h©-kí2"b˜x–›X5»·Ot<×€©bÙšåh¿2HjàPmÿöÔYì¢™õÌÿá#d7¹ÀX`÷ä˜˜Ù'üg{*P3bWÕâ™@U¼ïh}çSº…ß656%şƒej‰·‹Ğîİå¦å^Mˆ$¿Äé|@½ÆòKÓµÄ"{“5½èçñÛTnØİ¸:\z1Ñ³‘t]Z>ºs9ïyØ*ƒµÃƒß½×¸Óƒmq¹³EòÈĞëğ¶Í>“`7»¼wŞ™„XÈ¥¡øZİJ/¦)$"8 Ş±óc¨-M“»ì£íÿ;W5-0àè¯}D:Mì3¢Ÿs6Ş]“„‘ ğ‹óÊå¿.üº{† ¥UfŒqïVƒ#ûmZÙİGv…th‡ÇhÿÇ•GşƒVÆ0ôŞÀ½CæÆÚó!wã…:%£2ËÌU5>QR¥5Q ÕÙYXõKsÈ¤Kå=^˜Å8)¢s ¥Ú<3&n‡b½[i#Ï²ÿ¨Ç­*lLg}ƒ ”ªZt*2¢ßã!G¿³ôs ÆâôÈ÷8‰İ=Óçs§iGîüÌwxÇ¥bÓ©Ì|í2ÎÕšÄ]rP~›ŒzJ ,š]ÄO[½Aï3Ôè6<g]
¾¾Ÿöm×3$©!'˜.AæçÚìˆ‰‹SQo˜[PS—ÆK~ó]tıBÅqáóõ|á±l3];tã#İd{% Z-‰PœúØFï$mÛvŒ´¤Ğ\É½*û â„BÍ·a•Í»o8Šß>¡‘êÑ³Œ8±ubX‡•9|`°ÑLAÙ ëÖ,ów—Cª-Tòeø]q ¸şâ‘x…#\Õƒx”†h 7…1<ÜLv†6ÉÜ20C,™ÙâğORÈ3×£l½òsó°ÇçXÆè«õ33ã·DĞ4/	(ÊÊõù^óWoÕ39_óÀ)”ïòéŒ¦+zLDÕXFk·c¯×@û0®ú=§¦Ãh¥@ÿŸŞÂz¶^Ìæ?j¨u[ãûö]ÁÈH/“=¶v…àˆ‚Ö›™1SÇ=Æ–Ài ¢È@À¹¥bDarß¤› ›wØï…‰…Ã\(İwFå™?¡¾g Rÿ7ÈBíãŞV@Sõ>p8§öâ¿ü+%z‹MØ‚éŒâÊD¤!¸`¼°ÀŸ|Ãwü¸ğ-ÜĞhàëºdşoq™µ;=WÀ¤ûìAµ³ç ¤X2À	š{O¬MÊ)%ØÑÍ‘¥¢…ÉieUˆmu—{GÏ¸Å1º·ñˆÍ‚­n¢ë.İL¥×¡:=\Ù¾‚h_
½ê-<G¿G¼F‘ÔŠ»VI»6zyÛG®íÔ:Æ$>í÷h_‡}(€xv¼¶0ôì“âaÆÁôş†mn‰®É€ "­Í	9t½](wFÍ3²é'(ÕÔã¾3—ĞæœOİ?ÃzÈäræï¡Ò;"4hréHj<ÅÖ•Í•™­òÃúıï/ş¡-Í.šI½ˆ­;gH£çvóbÎ@ˆ(=£fdYñiú)Øâs	J¾/­-–Ü÷]çŠ«Ÿ.uÊ{¤úÒºZsÙÕ1{oÒñuæw‹Îc@çBF!@+¦Ä
!õ¿Ù•àmQÙú³¹‰oç™T„ÖÏõÁ‚ÉÊ{UJf—LOµG¼„gáš°X¼ÍñÕ¸÷šóä(ì\æ,ÅXw´°"­c¦Û?µ*¥`/•ÏE /79cÌF®rE¨J\ìFæ©-ÉD9`A2É	Á:·ŒÌ¹’ˆ…eãf¯I>9ÌÛŠFÉq{p5Ú&ÑÎe3©º/Ú‹?ºG±ş‡Ÿi“Ó•şSØõ++ç‹r“'*Zä Yú†O¿UéÿD²ã‚¾ OšWQD+c„îÍKjé‚ÑÂ³Íµˆü’‘Ô²5nu<‡ÏHk0Ù_¬±;p‚9ÏcıoßúÑ¬Š°ıV„ 2…Ş3Ñªı$tòUÍ@y÷ö`©àáó'Ÿ×I0Ár –m8Gé€P"ĞíP¦àíì­ˆyİA½‰Àš­;˜ŞvD…ÉxÖ4€Vå‘›`ŒcÜ+{Ä=¦ÍÚ}t’_»ÌLxšv•ò}1ƒRä†ÑR©]ïËÙŞÒáñ\å˜ƒË» 	¢gŒÕphÕ…Ø~{0	ú4^|ôÏˆ—gÇM6 rÙDS2½Í°$á ñÅ]÷í‘ÖÍëàGõ–ûêà‹>Ü„#6Ğ¬%A6Y‰¯0ÑŒOğKáâN‡º2êP¢wyã‹eu¿ÿÅF‚ª²î¸p»8²x5»å[#>uækÂË/÷Êæ9ÒŸİ¡«…× xB­ú$¥²»ü=p˜V][•aÂ«G±î·{ kYY8«36ûÓoÅ¤4ï½Ég2	ƒ„§\B8Õü“9§ƒé’·áSŞÒöw7f^<ºTÄ•m.ˆr§¿Ó-lª%Ó€À–zä—tC¹£A7|+$@Xó†Y»EaPš&(y¼¼.p|Ày9ûœÂÊ”ÎËÀ:,¥Mˆ»\Ó÷©D'jôÚÕ÷‰Œ½ô%1D®ÇíÁUÕ‡6õŠ“| k$]0yy#ä'«Å‹£ÇOß@Ï jû`Û/-™¸´mæƒ€@HÆíáMŠ-hÃ¥.+==úÃÓäæÎ1_mÆ¬‘¾TäõNKög–0pÔ°/gsR¬•§ŸÂ¸©ê°bâıİ´iËÜÃ¹r¿•êù2f¾Æÿ»óóvBÆšÓ«3?óúüÊª^øúIå…de*`xÜêkÑvâë
½”ãR†ê>IÔ¡“%ëcJË_i!æ˜ˆóú63ÌDæb‡Ì~è—ÆÃ%¿¡ú“Rëß…t8Té¢QnşšŸÏÕ“n
û™Lü=Ñ“\&­¥·Zé8mÊwŞc°!Ô(1ç4 ­Ş¡[5
xd“lOÂá%]MˆCä=â=ÔGnÓï:ô¾Ü:åœb(5jfú’ŒÙWS¯&ûZ+? Uj7à!¡œµmë½³J¤ÃWZ †GP#'á‰‡ƒ6`¤mÆõô5ƒŞm†³¿¯âwÏß˜ú#öÆšpÏáˆ¾kLŒĞª¾èˆ…ƒ ÿÒ‡1ãè±y1Úc“	PWîKhfZî.%Ñ>iúkèëÏ¬“9lW2~¸àl5ˆOô_!–¹îÌÓBE¯HÜg\˜€‚\HÅ1§YEË%f`— .oésx¬×	Z¥ø7uSSç_·[^d+ ı76æ:\aî2	ÿÎåêÏÄÕô+é³À«Š°¹2‚…(Ê**¨'*!QNÕ~ŒX&ğpÖVIAŒ£‚p#¿b3$~ƒÆzkí±€6¹„šKô®W.!ıj 2ªúğmÂ“ø¡;Î=º”å•»¨¡¶¦r”1k›aPcgHUÏIb1·­ˆìálßŞAÒd=fÉC[P©mb,T¤Ì¬¡—šâëwsÂ`à-øTyqT½‰‡*)éÊl†Õ*-jx¹lVRou‡ïôşWÜOéã­ ’Î–]ù,2ĞÏ¾¼ßg›_DÎ"ÀRçû‡Û"ø”É¯v&S:ğ(!ëe3\äƒCš'FóòQGÇ’ß*	Z^5¦à¾3ò÷[f]ÏÈ—Çª»^Î3o2Å_BgNó#±ï²ê8œ†w‘½‡	ZY*Å)°f.ŸÇÁî+¤c½?2ƒİ¾ĞÄ¾LÆèrÉòúùºÈëjìhö§´ YèÑ,$àù¶|@;«P£}N#èƒf¿µ.òÆöÀüğş/^µ{=?óN6˜‚'u(W2	6õèŞX*7]r>~w·‚s-9ZmÁQdÏ—ƒÿ´—ÓÃP§ÌSTÓ3 ŠÃÀ	ñÎ|„ûÍÂæMÓÅ ^k¶Ë†U’Xá‡ã±kT:¿öVñòmAª¸6Ù|šŞEó«' 0şp½jÄT¨´¯¢õ—9Ùà«Ñt£·—¸M1m}­hµó°:ïôVV˜>œ‰r_ÖŸâ—óS
D?òbÙÀy4A¯ï®€cmty’ÇÏ¤:AÆÅùMCúâÊU›ĞfòÄÖ¶¶¦W™™îaJVEfƒÍšd¯.¤mÕ&İ'O–»ìš«¯üXÓ‡“²“©©:‰±Ÿt²vÃ”TïÁIïå ÓïÊ¹´jHËÊ}Tœ±[&/¥h¬sWR1Õ~>Ply?é¨ŒØä1‡õq„r3¼C7ßWO…Ÿ"QàjbóùÕ9§ß9½ØKB¡ú˜nz..‡Ò0çÀ\d]Ò]h £]ëQ2#Ü3¿IYcÒı Ã×º9DÃÊFÔ˜N¸ü–nWp!† \ÉQ¸Ë™W·iI:~Ó%§šÖP_”W&D
9ÂÑâÂ°}0Œ
´GT­!ë.¢+Ú`ñ óéZø‰
&Î.´ÌñÆê‘#Î­ –U—‡¢áÉXÉé'ˆEJ>ØãRıM*¨u—NµBáIv†ô6œ9™gÇÊ«	jÎ:ª~‰|Œj*øßé	Y`V1.pïUÑ@Æ¯1Û…è³Àhõ6lhî­§7ÒN‹d:€	Ö„=áYìjK)‘ëÄ‹šÕƒfÍmÆ’q¥R;I’Â8Òz#'&ûæÿaúêi›9zNû,Ø¦ØWÄ»J—ªcKü°àPËKNÑØ³›‘•SL83í•tt6Ì•ÛF#ù/ ;Ë•:Êêjr²ÔQä8ç“»ÉPÂıd\ş×“
Jf‘úÁlHòÕèökÚ’*hM¤÷«±Âg%°ãy<ıû}¾nİ¸mçÜ×İ$ªä?}¨èVûšQM/ci@ô:fâfàZı¦:ÚôÛ AtÈåèûŠG´DÑ²ƒyæö¿)•Õ¤GÌğâ®š-o¨‚Q¼¡ØjHWã\l×!™q:ç›¤™Ø¥?	´¬Ş^VšîÆEä™D¸ÈÈzá%½]ª“‹•å°Ï4Œ5”ñHP•šÛÁ ûeÊm¢ğ|Míı¶8xNØß”§†\!ù¿—è^õÅ—ê·ÓöZ
êÈ»/‡pMìp
„jµıŠbåGŠ b	ÅB>]°©ƒ3Îm€À)Û=¹¼£ÔjÆg+©ôˆ¼Ök}¥o1èíc	u/1^—–š+ÒÌÍ1yéÒáÑ°  qWÌ,Ñ(İ{L˜ÇÆ­!Ô¤½"´k7Ğ]`£C¦6HÆ¿„·úíõ‡nYÃ>&—ÅQ,lîíºı§PÜqædœ¡±Y’p…‘®!B´9ñ)‹Á±œm¢Iõ´ãBq"™	q«é#Ô´¿ˆ'dïË]Û#Uæ#Â‹!¤@ĞwfÆ®şÄñ†Şcºm-‹ªô¯BáoHÖ•å602rG¶Éèæ:v
éÏ22s‚º#.RDÎ‡³‹+zß£Ë¬Ss—4šV‹¿Ô5"•dÓékNÇé§‘»˜AÌ/„¹‚û`™@”>àe::wpß§©™|²úüÓ"—V5Và­l3ŠË	a‡XŸ€°ò† 2ãäî•1Ô¦.7hñ^ºWfÊY+ŠÍzMÌ2éTr«ı<ÑŞËDdã½®«8›¸ñìÇşï2‹·±Q…·õê”¾rƒAÀ.“Ûím¶ƒ›…QxÁ)Ğ×ô_Å¡Vp“ÉşGµì3<F1™ØÜÒ(V-Á*Íùş^>¿VÍÂO#ÿ,Ë™‡úŠ¦jË) KH.CÄ¾µâÉ€.¯w}¬CËœ‹T#{±!y‚ŸÔÎÍùÇUõ›ûA«Œ¿<ŸØÑ7à.¹’ïÄÀ¨ZOê·”=ÒM4ÿ)ä…I¦öÆÍ*âÌ¨7®§ëXíø4ˆéF®M õêPÏ«4!‡ÖÒ•~Æ)>³kâê…÷à%˜ºB»hÛ†LìîŸZà9ÅŠ
aü&€„ts8Y%¯«=M@z9a!©fñ÷#1t·Q‡u·õ^“¦ã¢T9pÃ•„¼Z0×Tó Ap±™%	e—Òí¯şô!""¥E¾¢`
7¸9â¨PVAèêØ–­1ò0$éµúkÎtTËû3x·7AcöSó
[ùÇ¼ïª±mpgÊVx^(KˆY²yK*ö/@3Şæ“ÂV¬êiØJ”HåÅ´5-¦ö¥¼yWÔ€·6…Ò¬^œ†ˆ]±=#«¸ T«äyÔîBÈAémj¾?ò@U“%¦(şêsñ)ê¹Ï•šj
hÛ“ı¨ÛZS?E
vaò_ƒ•²3œ*Òëñ¢]³BŒÕÖJzc‘­Bgá±ÎwK‰åF„böqÉ5O£<0k6¸	Zü)sm…³ÍU=™œ”PEN×íçVÔ…‚Ô›äU«Ux€ÅŠPe<¼~¾©}s÷»…†úL3
5=é>æ¹Rb±w†XZ{Øİ[ƒÊĞ…ŸŞä!qjy1—“í!dŸ@Ès«–“Ô¸Ì¯_ F7ĞÀíµZ[Â\ä†(÷2Ğßnj›NÉ&ü‹«“ÌGn9¥?úƒ¥sPÙòûzÁhV[ZÈu–ãp6Ì_»×º<¢CíøÛ¦“&!lÃ.Bôùìä²dÖã20Â³öJpq/3 âĞª{¾‡å8³/eÒÏÚ+qu—À¶ÌÈyj²°­½èü F\ßÑÅJ{ìcù·û #>åŞ÷#¦yB“õ¾ğUÄİ²Ìı§«ÁşW	×%	N°”´àİy@q_Ÿ˜L|õŠC#í éÑë¬ò]"~,¬o‡âª£åÌ1U(õ%;eM¿ş E«Å;”WµágzíŒg^©Ïù¨,\¼ã9UçÏ$ŞvšuÚS9PÀ—÷¾9sF{}J{1Û$¥®ÙÍ`O©ÒL²5|BD±¿àAgiJZs[Z× Rd³2IâÜ/AÔNq1-!Ù‡Bû5.h’¬e•iİş¸À>[$Óg•ÔĞ>™[
ó°‘óóyC¤}€"c>Ù‚Î±ÈMn•Ã«ê[¦RZœôgåµ\ÖPOW)N—0)ó8oÂd;{´!|×7 ‡œµŠÎókÉá‡DÂ”’‹ë}ñÚ ‰*‹ª¶aî•_`€¦bµU£ZŒÍ’z÷J~­'†ïÊEägÈ×+°Jz·­ámÁù1G´ø®ìlFyšä3šgeo˜Ú%Æ S|¬ëÎÍûÖìû-¥Ë¸„e/£OªÏCnlš/Ø„”óªBÜŒ˜µÔQU…äy$Å$æ¼ØÑ…8I_`€‘å¿®ñ¨ÎT34æDvÈ=ƒ4	¢Z¡0_\tÃùRxß›Áü®£Uı;,î×@ŒyJœlÉİ8“|Ì['§Ğ_”<GU=6)ºã·÷UK³ùê/¶qÜÜ|¡x*\?X0ù°Qè{,q5š¹R×@KòğØp†è"HÙ5yÍŸm‹0 #è]©JbÂîHÓ²sômÉwyÂg¬¥ı±¬´TÑxè¿äq>!ŒÀDÆ*LÄ„å"2¡d”‡q+öĞLE´Ÿ(v.)¬¾±r)ªëü&Í™h„ÚE)lä§ÍÙ€ŸŒî„ÄYt‚`K]JQÁ¸/+‡'­ïz-Š«T.“! Ú$?i¹ö±ù”Çàm÷KxŞ$B;N!«ó²’Æânµ"1Ö3CwNÉts¼;Ã{óÎÜñª •öW5(=ÛÈXÌ¬|ø9ê{±±% ÚMİgìÑÅ¯Vá†‚È§[ :$Õt¤¥XvÑ$[8}Î|¤©işÎ¯8ñ%¶kÏ¢+	¡ˆ¢›_d©Ïi,jje1ZâÇ¬2§º#}i’³khİEôğ€äáãí€Œäø;ûÍ/”¹µ¶‡·“öf—§åÅ\¶‡¤S=îĞÌ†ö"Gj–t°Œ²ÔRzµÈÙm(7\v¹{ñí³_g–]çq<a˜ÚÄÕéG>ïì!‡MH›cClåÇÏ¸Gw=Ù(IñøGGKp?æ/ZHOY¼—êG+ÈÊî£Rşf³ß¯y 0Û`}î,¹¾ñI	Ğ	Ái•Â…R(‘·ñÚëM+Ñ°=‚3
¯ØÙÁ:ïûï^¸ u¯V<:*ğM`ÏWä©»°.9|hÂúÜøE+ø¥k¡ß¿ÅÕ¾œáç
NüÀ½üaãÍbŸö-Á/bn$`8Q¯wsU£»ˆ
nK~ƒFÈN±>¬¬&&
}şÎwÃ’;4Ö:âû¸è Äíb-âÆÆ€ˆâş³™¬æ'‰¥/È‡•+\UµîïKÌ–ÎÖ”w<µ/'W#Âº%jDAé5Üµ£¸Uè±	gË©¹€„;œñg)@X„Å†Y¹ø2–"Jjn0ê~±-Ö¼lhpb‚'˜ÿò!Œ>ò"Ñ¾ÿH€\LjŸ¦&M:|ğeúÒŠb$Öo¿Q2K1öJ­ë‹9ºĞßóøõp šœ bZVÇ*CV•ºfÅ5d¿…Õéˆ°Ä] 9NVÔ+~®¥v€‰2v3L£8áÄNÿô%ïCŞ…7˜‘°P‡—NC•kD‰¦9áb6[ö! 0Á&jÜâ%Ö,!Ñ@òx¹{”¬"Á5ùç”y¹\ë«,piH¶¹vüî½mmZ&nÈP×_ì{©WO²¡y˜SÚ`úûHŸñL•ıØ|‹¾\_#›Ú\®ğ]êû,LÊùÓ6.Ú02’™àˆ­Õ<âÚG±Úö}[-²O¿.Ú7ûS§òv¹R
ÒÈÀ€Qı3,‡ÅF#!—)TŸ¹PÇÍ•û“¿ı¥hiÔÁ,‘U$Ön9ı$–@˜›&ièúÕıÓõ¶ÔîÙk]ü*Ó)‚ˆEÏè½ñŒûêÖ"
ó@ë1­DõÛ×¢k@_=l³AçwäDæC)‰vLÔ¯ŞH<î•^Æü"$4
k»2k·ÄcÜæÖÅ!gé~hCÑnçæøY”±ª  ~“ÚWâ`EŞYMkçı‡¿^4ái|‹U<D¬SKn8Äµ¦ãxï¯ ÍP¢iıJ*†ääM¶Åz‹£¢êÙˆşk!Îÿ?Fæ¬±âL¡¢é³t…9µ'v~š‹cì»JGá¤„!õ%\¿¤ğpÓìÊú6†¾«aëÄ,Å7×Ô×Ï^Á{{Ûœ“¸3ıqçW¦z]Ò	¤‚¾A‘)|”ú¤.h1H«X×ùzJãbs‹‰{ QL$c,©™D¾r Ê	2ı®êœ•¸8BªU]eœ[ôIŸ(•ÒÁXX7
ª™‚±a¨–ãF­ãàFK­‡75Œdí°Ò`MBéÊ›MNSÇ<ÅD`ŞO©"}î Cz¡i ¼üÈ/RXåëßo××e¡väùá0íĞvÍhùìÇê´Æ)<(æí·Bh¥JdDò˜BÀÂ øg0•fÒAÒ«›B6¤š“0tª×d3Ww¢ÃûÚcÀĞœõ À…«#ÕÉJ¾G²³Ú¹è jğ_ğUfŠãÀŞİÑ¯ÜŒXFo‘.ílŒ Š]O
”›î6›™¯·­<éö[nÅ±N(¸Ä™ó+Òd=Ä5fÉZ9åY”û@’À›=avÛê•3ÜĞòˆBÄƒTu#«öÕ8L€îû©
Ô×í‡©+sú K%ÁbéT©_µ³tj¡>ôXÈVª<Y¨búŠmñX+ãb±{ƒ‚“+Ù6›4`ÑJâ iˆåŸ?ˆ—Šà˜³¹õMJ^’ú²[èÔÖã¿ãüd3B 4,3›ó|®Máöìş yvŠ›g±pº¢äÿ«ëio
,à2¼Àº (%ŞÕÔI¬ôìĞxnHå×kñ?Â•b8¾WÁÄ„Ÿ#'¥Ä$È*H(µ¥¶ª3F¤‚¿Zäªü}è¯¸ªßü‘äD]Æ¡X\ª[vòpg¿•­ß®ŞX0˜Í§$† sG†Wµ¹+``©eóEÆó©9RÏÏ=ƒÇäCÛìÃo¸é|øŠW‰€›×Úï~Ÿ§$¡Y²SáŞX2Ö5ÙÁgœWW»~í½ˆ?â ÷XHg‡µ¡1×í—Üï“ŞŞl(RÖ}Ddê7]S˜’Ö:Åd5@m\©•­İìO¿Âêæ£­§à&ü¬*±@ğÛ8Ãö |¿@+áü==FìµíÌÉOŞ÷^aå=£€o\³%‹DY¹ğQœ_`6'îOã'2b[fTn '¬\ÓøÌì‰ãgËKs¡	şEÉ";O4[ç€#ŠtÙö_àÜ'&­.'Dj÷'ÕÂîÇ%‘bÃ‰É#û%“Ç.bJãÛ¹¥Ñÿ£c$ãºÅâ~Óàµb_ÙP‘ÉÑ¯¨Ğè“¢¶÷IwP³É\¾Ò(Ô(Şøã¶s“?œàí”pDCQƒ­»ÚNIjœîØ4V‚a:¥uY@ïJ§Èê	@vlknôõØ“s]’]g…SJbt×«auB©½=ãõz2K~ó†ğ‡a-Ÿ@‰´ƒP8å)Óğ”PĞ0Ÿac5¯ñÒiœ>m1ÈòáC^H<û-©Ã#±?íÌßr«–]Ù¶^éVk…Ã<,ÂQÕâ¡9õº€ÑçìÇ<Ù3}‰¯ŠßŸ&Qÿ™å}Uë›\ÚâTÍ.¥8
Ğ İxNM%Î“Ø”Kıµ}TÊÂ~<|R¿H"Ğ2;™Iwÿ]Ç’•JıäÃV˜€Ã’.e­oÖì1%$ûa[7¾¤9‘V…©š­áJ•¨¥";äæÏ”ë"|(d#YW3*O<F$E¦N§¾¦×…ó%®ÙSªİ(E»[1ÄÁ•=_T:æØû|Şã‡™@2İ§Œ˜şÎBv&Ğ{.WY©‘úÒ‚L²¨ä (%swrEˆEü,¼z,„›Tê?¢^Ã ²eã£şùÿØlÌ%Xªóuøî—êU—zÎÂ(2Q®rñ¡P¤(’ì¤‚?Ì™»%g#Ëõÿ|>™s‚-ˆíIv¦jğ:Ç•Mxò)¦qğÅ]c“ş^šØ%ekSuË¦ù;•{ÉTm¸Å1…èÜ%ãÁ]Æe«ßÙ¡Ïá,Vni=JüTéI#mêëÉõO^àl’şu¥Ã›+­õläg›«éuk«l— fe÷jƒ„Ä¿–•/7À¨<¦’(›¬í‰Ğfšø0+Áé§+àXœ?šöüÇÀûqY¼)ñúUãh+ol2ú·PF:=2ç))Á,byi™Áá!4Ø,”Ø=vß}øx«¾èD†¹F97EÕĞRïÒ`qzlY^ÚõadÓ1å!ôP…|_=ı^0[ñùÂ+nñšşçÙ‡ Tó¥J®œiœn”8ÜáƒNÈnµ[ûØBßrOã¹ƒšgÙÑ|hê®][î‘º}¾*Fß}ÈÜïå´»_e·/+V)§aÏÀ¢¤ÒÖöşY] ßBŸíşÆÔANgÑ[Òé½Ëü°Ç>«eÍW–ï$p²lsqwÅlZ¶Ó¥±N%–j RzÎHãNéWrß-ä9œ
¦ç¡1cŠÊ)ÁYæ˜øı¯ßÅzöZ­¸oà“ÆwT‡NZ(ƒÒ][ñ\!
: gl£
 Ê^`7,_"íÏÂHúŸ[ĞNØƒšÑ¶^#*Wüœ°,”ˆÉ¾‹×6ËFô½|Ò®a-†rç.
¾‡KVq;÷H‹Ã+ Q®¤Ğ~kN‡ÿ(+ 'œÜÂ²º´ Òç)èQøı‘[ÑôûÌC’5Rt°6²zòzÁÂNÜLå¹ÀZqÎbVhÆnÙOØ£«Ba=D˜[œ‘Û?Ï{ ”x3Qƒb¬–i¨çu ½~oÊ£¹ºQºdUóxúÎ	¿9S%ã"1i·¯ÉßD¹æ*`Á˜\Á1j(ê{íßÇSÆo€¦‚Ùêš(çŞLï£Bü“Ü/¦ ‡P+~m{KOà-ĞòçŠ6SïÆ€/|úşÄL³¼³ğ›şi¸ÃÊ£5/£±zSåËlßâ*­iT@vĞ[<ppUÊ™!2³ˆ
µÿ±àëú‹Å *^'CÕj$ÈäNX(|ã{—D9ß™şLÁkU	rrKóşlrÇs÷lÕ–Òz÷¹æëñ˜9“ùnB#ú%C|j…‚ÎGvPôsß’Ôh_Ó€Ô!0£ŠÕï¬f¾…ŠîfåÂŠ(½ØêÄÛÎ± ÏVBÉ¾¥Ñdß#Çë¿£Lc}[Å2c<#¶îk¢ ÿ ™³Ç1ã÷QóœÈ»±#òÁÈJº±Òš¢Éÿ,±³rš•ğ+ªÙKEiEL}S˜³Ï”,™Œ£Ôáõëõv*Ó]ò½Š×‡¬¡ç‹‹¡Ï÷Ü‰äÙƒOÈq„^éş2Ç@”ˆrĞzWç³±½:{¬«OØußf¨g›òP\wª‡xÁDÔµ×¬Årmæ»w÷‰’ü›Q£vúh.-×Kíº¢qDá¦©…X$wp:¥·NR?{ ‘İŸÊï3V¢š]BÓå¼P/ràş ˜zNîÍ•fl–pµw2êi¿–âÖçŒR.çÉYe@à!¡(I‚<_±¯¿¹ŸÒšË˜’‡ñÌ¸ßé4p.aÁgƒQmõ¬:€úXÎ\Y7dô×f6/G‘«ú°İb÷PœŠÙpbæ¹ŒìËÇuÆ²è>a2$ùlùÈ©J–K¾(	=İ=ñlLÅK,"ï‰9ÛâÌÄ‚Cy.ÎÜ“6IAÃ{$PˆAŸ®²Óû/n:ªú!fºËâãª;iœŒ-œ—Ì­9ÑY²-Ruc~,‹NL.ÎI,Å`u²¢5•„¾ˆo|;Gê64®iû˜ÏrÕâ {ÂÁ×7‘ˆ^ËÌ¹wcS¶T`y¯İ6=
­Ş´L„—¾ğe m±™æ!l½¨K§|A…¨fF×ß­ÆÚÇÁâ[úÎşh,ñï"Ææ…PÜ›šö}ÊäĞÎÓÁ ÃÏ_i¥„fÅSòP¸V6PÕùÉÆW3¾vS±7&œ(¡Œä"‘WÚÄÇöW»fÉitŠ³T1]_<oÃ!kíc]æLc·¼çšN¬CnæÎ¹TĞÚñ:}e¯öñ‰_Ø¨‚Û¦ÕÁïÈOÅæ?_äé¼.ñáÄ”ÓÌšÑ;¸‚§¸‡z2*»]¢’.¶ˆ€ıMğvšá´Û¥-Ú7·ïÄÈÙêH3vGÚ;3¦Ç1=)ŸÄ—¢š7“©ÿ4%tˆÈ4A†m6´¯ÓøtlOí}Kn›c%RÊGz2„™[NA%êìO÷8u$èæ"³
÷4§ànKnGÁö+>±ùlnH\¹¾,VÂ¼ß³
®•ÿ‚Eo9‡³A~t’ÿÓlH9‡!ÃË©¦¶·Ş!ø\ j¹Ğ{=”&vÏ”ÇµÑrÔMJKÕ›-Z´ˆÅ•[Ï‹RòÂœóQN ‡VùiÃk¡!a ¹tÙÏª~‚¬kT˜û¤»õÎj6Bİ€RI:|	 ¹ŠğnR'xô»ÿ»õzQ„‚Gï³–“¸ÈÒP«ÌŞ*©šQ–êH÷Ü,˜^…›çz¤¸a-ƒuJç.÷'	g*ó·SN<]7BÂ‰¹ß¦pd‰—á#ù
·û©Åß£èã9dş¦YÑ„qÊ†ù„¶
:ÆUFP†Qbí‘"ªàiÓ$†áÀº•şU-U$ÕÕÊÃ¡ë„ÚxÚ™µş§j9¶äa%í'LèŸÇü¶FüÖÌàÿµ¾ïI¯u\Ò?øá*²úã	²xô^ã"„–Ól:ÆÓ?;âÓĞ†;Ó¼'‚xMš›]1/^Ü„ì¨9´È’]úò.Ø{Sç¤Ÿ 	È"i¡}vù\\‰Óšoë)jæÉ‚E<Æ´fJ×ĞÃ‡Ût^;òÏÈr Ó3Õ÷Ê¹³@éòîti˜Â|‡lU–s”1+éaqİ4—]ú7™š"¾mÕT·Ÿdˆ=ö9ª@zé®¯w(ô†3lZâÃ,)s1APº§P-ÁÙpZÒÆ©$–€äîV¦ŞÄŸÉ)Ép$–ä E)?cWã¹¾g'¼›i[ìóGG	m~9,Kí¯B-í9‘,íõÑ•”#ªV	Ÿİb¶ùPDB+¨
ÿ9\ï3$%$©ªîš¨Hì]n(/1*¢,ÂÕó<`“¤NGŒŒÉ­ò5ùøş8>to JñÎ…Mó'<µDjoĞãY1ú#Ø9åI³¦¹.`÷£^õmÂ±Xrñ•H &|½®µ±q¿ˆ«Eˆˆ8ä^*|ßêæbõ.z±ŞåJ-×H‘ö(óÂâ5­TÎí †ÖˆA!uBW&mĞ¡P9ˆ¿´^Cä²Ä¸G›SMNaƒ…ä£sˆª‚âøX¥­Ğmï¦¤¦ŒÈ¤‚î^8ïnº´‹éA§J}ğ—›p~±¦n¤eO|)ÍXëpØb«­Ë„¾¹¾J²j*[·êÔŞ¢Uí‹‚O‘Wo-:mµäimjé!6” ÊR«j1më •¤‚Ÿ”¯°Y—Ô8§XÂ<ÇşìkÑº¹0XËK6¥ßÁå®¨2ÍÌr³Ø·ÊrÙXY.955×W¿VÁß½3İÏCê§&>Ê^t†85íV€Ÿ€àAºræ[êavÄvè,·»¼¼øÚöñ˜éI¡umèu:SóSJêğÄ¨yùï"¬,İÆ@4€ñ$QöÕ†
th;)úO8[`±wyœĞ:ğäÜ—„áÊVj±¶˜×’
ó«kÓ¬SÄ·†	v”:¹1ÁœK%¬qßœWb‰kG]½!h§ğ±·l¯w7có>î:¦2ö&3„‘¿¹/KÄ}b­WŸ,;°•u?Z„$ğ„Ö{Ù'½’òşÙ?†5”z+vAƒ½\%çÖÒÂ¯™")T~lƒ+ÔşS‡ô$ê–áïqËñ3œâ«Å;DõÆ¶>l+‚}àšU­ô¡54ó9/f|­­ œYcİŠSŠ)v”zíŞ!™-œ%X§j×?È¿÷ÆÒÔxàëÕ÷Õ°:~xøÙ;2Ùaó-G>~ì‡:;ÌĞZ~!ioşDšïJğ¬oSìs´zGØ™ç¶ä¬Oº±%%Ú³?Kµ?goÜõ€tD~ æL•^+K<9ÎÒöG¦û9ÈFû)%§¥¨£Â—2®b„¥å]’<wóÈcÃù¥z9Sè r†ôßh©#ú&ˆ©~ 4àM\±!X“MIb²ÈˆM´ jmèSYßSy‚ê¯¦8Ğxõ.ÇJ§+0Qı«êÂ«k?s%ñ¿l3I¦¡ ¢8Q+ÇpË®)˜£q%¡|zßaDé™M4ïgÕœ¶ÕG2Ô²Ì>‡
Êb‡!Œ‘Ğ—±6­Iy¬-Îp“˜£3¸½HN¹}’¹†Ğâ"HÚï#ŞpÇÃµ3’ìğÈ¥ñ7ŠCˆJ`9õ{Ù`ã®zƒú8\x2
ŞÌ,`ïr‰œb"Ts‡sÎfğ™ÔONSA"9¾o±Bã+oÉ¤ù¿Ïa
»Ëí‡QvÅØÂ×æõ&êN7 ˜Ë	XSD×,n!oM¢Ñ>z®•¸UÕ`.Y.é‡:½òshë¹E
1wä"BçüA°3Aw)?¨=Ügeµ‚­Ô“UÙ5ê¸Õ¯ãvéNw)õ„—i_dùt$ƒÉ•“õuÉŞĞşŒ´7±4f\\ï±‘z‡ê+ ƒB,YÿR-ö­4¥Ro„E.éf8‰2Gßé©Ÿ›¾4ä¥`Û•)£­"Ğ…B¡Eqjb#bÊÈ–Bì,ío´?èl¸Æ(/$ÃªÎßÆXA;°Ş)»]ÛìIÚ]él	ƒâ:_•ä÷áTb`¾üuÊÙUC "koÜY¹V<røƒ©ğÆ_şÄÜBRÀü¦Hİ+3Š.lÒR;’èß5,0M"I¦)OÖ†÷aó-Šˆ´ 
´û&Úød7W A¥ÎÙš]ØóU°GïÇÅ/ŸgöáIö¯6oÀğ®P!20Ø(¾hºq®…{=Ø×Œ™Ğ>îa½ß.y.µ#ùş²¡Å™óXZòZ…ÏßíŸ_åÒĞ¤‹|ª—é&,ûlÕ¾-›3{Z»)ìæ£qÏ½o¤E8-‰Ê¶hIi%"qyDõıI¢\bd<ë/hn¬‚$7ê×ç·9>ZÂòÍ˜™„Å¯Y©@<1™u²%ö“Ôi,Éeı‡·Æ×–•(â–¥E&4Z¡ßvÌÅxX$­­
u´…lT±EôBÇá
}ğ|)Ö€ÅïIãáKË]›K.>Â N7{û–ö¨ëŒ?‚ş>dÖc´âñø{6?…}=­İg§ü'¶D'~u›æ±ZĞôO¤ø§òC`UŠ´µDıR˜¦d@xâ0-¢±›ä`˜Ø`_œ²9îZ—^ößX$Íç—Óò—%kqº¸ü»Ëó³µâm)¢~.NÑÙ´V7´L 6x	ÿv„Â~¢15
YÏ3=Mwf@bwÒª‡¢ÎáŞ·›ëõ:I©Q²J˜F…ñ–ó‘~–¥ü[N w.ˆº…\ÅÄ‘#…IÂ5ñ²z¼Ó€¥SÁ/Ìç„é`CbÈºìŞöå"ªi5üb}‡`_h^CÅÓ/—¯Rò`»§Ò8XâhÜVÛ×bHC/Ã.fÚ;Ìb)ïZîœ8>§Èn³IK=Úcß‚uï_IIæÁºğ±ÚYï¤Ÿv”Ì¡Å¹´ï?ˆAø“åÀæ}JQ€Ìá&
Ó©ÿ­YĞİ+ÃŸ9ë.İ9\ŒÎÃ70ê9[è0YD€ZJ<©Ğ¶Œ¥Jƒ£¶ÄVºÆ¶ú“³[€eûŒ9¦[ùxà¦0õÕn¥ÿéı÷¬Ôm= äñtÕ#^/ö :äÜ“Pı÷ÂAÚ3›€^–}¦ÑcÉ}'\èb«ÄÇ§ğUÌ¥ÑO’ŞÍ“ÊÎWïƒ‘M¿şŒÂÜÜ‹QãÜ åPÑ
ËùüL€ÄÏ¬6TäñûSã°eEÖ¾UÔÜ"ïéØoõˆŸ[cg¢IãüæÖeZ‡ş<ºj+&ñê§33(‹¦÷:€r@”#çÜ9g£,p3œO^K$‹ù¤ğÂ]j¡÷RdîêJx’è!¿‰û¤P”8&Æ£Ìù8øW#S¥°É}à­şvf
]ªs+Nb5gP5£t7Ç¯`[wDñö£éTpšb[BtabÖË7xG†á°¿ÛG¤û3Ï`­æ\ÒÀÉÆ×„úöa!.¡
ì§­{Šé0’/÷ŠyTŒäå˜v¼]Söš¼º9ö%µ+=;Û+ÓyR£b$z	ü-‡Èì+Ä@)Á$IòÜ_µ!G-6R„âÅÉ`pôı]é‡S`v~6çœRš>/­A¾§SÍˆø‘âªå	ö+İiäƒk³bÑœ~†ÃULHpµ—1Ïç]‹Æ-#¥%D>¾ƒñÊÛ‘våŸ—c4Pø$I™:âïˆ˜ûÈ§ë hú¤r“$[äo¹ØÉI¯wÒŒUÚ’.T	9àÀr	Eùâ¤×y«‘oüt©9ˆIÆBL0yÉ VU¶ÔœT…ÂT»ıÁÚÀØ—&
Y°¢>ŸHÛm=Öİ#n¤ƒLğñ4+YÏö Cî`°·M)şZ˜¡nÁ-«•àĞ‡‰"ä™çLlòçcT”ƒ>±Ùùø%;ğËŞÙ8¢%s¤øÌ¨×œ«c2új¬òë‡NµànHè¬´Åô'„ô;[B[ä˜Ğ	 -˜GÅË„ÓÌuƒmt‚¸å'½äš#ãÃ’fì5EE²Ê)t¤MÉ©€Vïí `D+mVQW§D’;¸Çºqº‘ó?šÈ¶ôíV87ÛàSkô©Í=ÇG¹µ/5àŠƒ¼Uwíe@z½/şõÌ¶í’é	+]Ptµ`ı¨šî dcX:ìØšõ;É—ÂÑp§Şø³J¾ßl6[;°6ŒÿM$óC)EZ—€ˆGí<`™ŸF™o'Ó<˜—RQÁ>…Ä­xOqÅ9Ôğ2W ˜Ô‰`¯DÕÉ3˜‰ëàø+;ò—ä{:äµ+ÏŠmÑßjçawÓ‡¥=ôh¾‚*<t
0ú{	EÊ#ë„d\‰ÔL›À¨3ò	RÄ94v%Êw!ë×i¯5vì$Û1´ÌK‹4ÿ\Ah+'õÿ:Ù¹ëv±	E¬·^H!° Šf«í÷_z'Ršñk“¦Â:g¤í½.mV³Ôj06IıSªemº#˜9ygÙ p>Õ±3[\åCUİNnH¥+c”
×c1¡·¿ïştøN\dt¿óè˜,FvßëŸ2¢°†‹r?òTJûÓa`=‰FÂª[W˜BğÁãÊËx¼À0ÈÒê¯2¥êÛ=ò£’€Gß˜ ¹yæZ×`Ş_D¨&‰Hóï 7G¡%AWm 5-¿|›ÖŠ*„òŠ»ìYL¼t[ß0¦ª	|Ìl¤½*k—tÿ‚e©”+Zùp¹Ö™;”Ä?°3NM8b}|®îbüˆ,$tn€C`nN6CÇ('„oS
ñ&¿(zŸà2x<Q¿sşF6.l²'¥kjeÒÛİ«´5³¯ïÏ{£ÁH)3(ò¹D<–Ş“¨u‘K|ü°ËšBı²çÎZ»ó>¾Â£ÌßéMq‚KıÖ¡öÛß#ùXPdTş …\
X€Y©îDhušşÓ4çs>z®@Î»°=ãÿ\ge#í§9­!Ng2hK!¯ÎõmëÍÚPQzÒêzô`¼¯@mŞ:2}&)«}xÑ;¹jA.e@T™~Ş	a¸yş£YĞ!ş}qähİıøŒÎ–±ÿjÅÅ]ïZ|t•ÆS¬ÛÛ¬ÜY	hûèyl^¸®{Ci:nŒ\ F±<»ŠàWÓ‘·Â&Ãs; h™t–—¸çÕØA„{ã}Òk3®\¼à•í¹ïÌ˜Š¿^[\êôÑ·XÚŸH’Æ¬ª2ÔH×ŠfP·ÒškM4 ¿ß¦Ë?a'ÇdÁÒâŸûàÚM
Ú¤Ô4)ÉD{ÌD+ˆ•Â‚%¹÷‘"vµ„:Ô¶ÒL‡xÊ6L'äáŠ¬²ô6V+SŠ’80möeo»õ-ëGà5
ï»èÓõÒU‹ÁÎt×¶%÷ù1/Ìù)¼KÙLüÈzI,ğÏ@L×Í—€ÈË¦í0Eï3j’&lã\u¥½	êtB–2É„^y:Â ƒ	¥+|ŸÌ[V=aö éA½——[¦Ï­ö¥‚–úGR„ÿÖ¶îæO4rd^Ğã-»räuù1ò©{Z$ÀK2åß÷Ã’÷-&v˜^/‹Õª>56tßâÖÄqí¹èj²¹%QĞôV»¹†hùDì3ˆ'_£AôÂôuq}6×\eêå=îª;YT\ô–é*ˆ¨Œxd˜Äi='48a÷¼ï›|™Çx2k@³4Xf¿A]hB½/iEm´Œ¹1}œOM¯ÿW¥È¿
ŸëtSYIª¯ÑíµŒ¶™Ö­Û³9 ·‘pFùIá½\"à”AOZ­l×Q€fh¡DıvLm£‰å®…#ú!¹”TÛ# MÑgØ‘Îpi•$g>¿
oõË¿>¡ËBWÇd…a4ªc$Îé)¨\áĞxÏ§LÒîŠóo_¶ÖXĞÃòÏ¥B‚XP¢Ù[¥9V´>c–×vºE¥Ûšz®öÛÓa¯}‘UÅsŸÔIñõ¦€­ûG0ŞLèÂ¡$BèZû’ZË§¡=Å˜Áî]jŸeÏƒ‹õCû	i…À¼-au¥C‘ª¢½›è¶’7ÀÏ{@ì—6‰ãYô¿'Û F‡?ã~è¶«^ïÄ®*AëKŠ„½gÕñF 6ş€ Š-ŒV~†.öFÁ×4IÀš‘’@×rÎwš®L<¼Ô¯k9öê@q3ÁKm]¸}Z¥¿üÚ0U)¼“`áÔ]¬‡r5õ®J›ØZŠYEšD©€ Ÿ[¬(3 ¬É€/ño±Ägû    YZ