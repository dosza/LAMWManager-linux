#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="233045781"
MD5="ca1ac37cce5621d656df011600252637"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20372"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Mon Feb 24 23:59:52 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿOQ] ¼}•ÀJFœÄÿ.»á_j¨Ù`½V˜Ùâ/}0ıÅ›àWŞJù|§îî›¹ÑiÀûø¦´vŸoMî`âïâ –Œ1½¬ô®ºgVœ»Ñáª“WYŠª›~J@èÄÊ?QiÅ¹±Ì ˜TNÆ;ê\S i?>p;>¬f>›ã2®i‘İP ‹ÉU½+lïÙêØPô¥BÀ è¨ïİïZ'´©.Ke£ÆYUÆÓFh’Ï÷+T7Ô,A,'?âÄÇLë„gú#³“+.#]7û{XØ®
I³áæ„w£–Âª9(°È½5èÍÊ«àbÒl‰YòÖ2{"§8&QvDql–Í0Œz?íB€ó"„Œ†O­…•‘èq]*5z¾nî§(w‡¡
BôG¦e‘ê™¹ÃK‹º„WÀÑOpÎªúšş â'OÔÂîòyü-3f'“ì99 ®¦³6/,9 ñs#ª"*5›lCcì¤pÅ$"ğ$:ûl/f%¦¨	ÓGGî¸.¶Õ®wB©@YúÜUú¨MQƒÕçä)6ÿ¤—› $×—Çåì¹¨˜R<ZàcTœ)Je¢_ˆ‚›X&%C§àm£Ìe5ôÖúoFñ7¥0•WØ‚V>ĞìKˆş÷QëŞğ=°û/êÖß $à‹^ÅÅŞÜ+G_Ì  ÂÃ£4ãÙ¦rn&…_«ÛX%GÉÿEÆ’lèĞN%œ@Ñ9¾
ß o²©ùöú'Š*4Îã~@j"m2}0]„`¬So$ÃMÖ¯ú­«çd¸>Ì„›¨¹•dCI_Øï+?Ì‘¤+¶×ÍÒQâxÄS%5“‘,wı§àX#>çHÿ>«E¥tPg{(Ü|MÚİê˜ƒ£ˆ¸}’%6'!4mz)IÓ3ZEOêì&ô	=·¨­É[ÿ3:ôL¦µjWûÅ1÷¯‰[ôiÇšæÓ;AïCìÔ€U_şÊ¨Æ¹›bZ$w‡(eè¾õÜSä«WõßŸòápa‰¡é˜rY½à,hê2.|™´Ê#eçC$EAÜ8Ë$Aœ’`¨?¥ŸÄ¤­¡NW-|<1ŞõŞ¿ 9õÚînc~dèM§¦ø“_(d;z—]ª\"¨ŠËQ%°ò´qÑ½([ø
÷Ú úŒmÍDê‡CÉ@2ß¬¶z™/,ƒAE!ÌêÏşòø4ş8ñûb´€Ú$'\DŒ7ë)O}ca-·ÉkÖõ®Á¿$ç¡b«w#ø.KŸC…¨kF¾^ıCi[À×ÌGLE'y~ØÊR8›ßÉ›}öãÄKMªãqkaíÍ'yîVÓè3şh3¦}Ñ àãGåD¡Ù‹¾¿Î3œ8 drîŞİÑ;AÎÂÛ0ß|¿|‰òÃ~ ë?Ü‰€P2xÂ½ëMÄ î¾¯€Û¶¹Ù²Qrjö?ä›Ğ4›Ñâ§ÇG@šÈÎ*amj`X4´· <c¿µúBsHPB¶—¢ñÂú¬£'ÕxÊ.x)Úı¬:\–,½‡›x@²
®±÷ÜmÑ&Ù‘¨îlïFÙ×Ì§ªQeŸbN%RVˆ «
–ÚY›Ù©éÈ¾JFúOè%î˜‘y…ó³İ‡Ü8E	Á•”â_u¹ÜP+a<M§Û»ÔèõFÂ~eK¥Î}ÿC9DY‡;§Øµµ8fà­‘,éoi$±.<2òe®5#{Nèv€'¾J’5Oaä{¥6ã”Y6‡ˆˆ/ÒÓ¥FÎ\ïX©P}f[y½B[;L”P+·ZXRm}Ë.ãø2±:k–Î„ƒY4K.T±ª£@pb(9maÍšÛd""Ú;Éù§0œòrò%~ß/¨0• Ök¨ÛÇ~¨¥Rí‹#5iìíX…–óNğÔtJÄ†Ñğ› *%…ëùE^—nà!4ÎÂrÆ¿Ã„ÏjHİŞ;’ŒY‹E2Y?MŒ€Cù‰ní*égpş{“hq—=gâazŸ[À{ß»â’^™	OÓjÄCƒ°äm’KõÙÒFjü'ç59Ø·Ğ¬ÌªdÏjYÔX$‰ALM·wêîa7†”ô–`s¤ò^è˜¸t­¢6ÁêØ‚hÈı†¤GurlÔ“ß¥Å6Òt€M/Äs63`ïq=Q²%ŞU\ Ñõ_>M.µÅÿ2H?Æ‰ÍÍë¬·¶ôºóm‘3êïZ™Òçú’f»Ó¹dåÔÁ<…Şh:—‰§7Ol±3Ğ¦ÓCtÀWŸ‹$«‘ı·F‰	Nc7#±oìÜLuO}¤Euã'?'!pf‡aú¤ÑL°CºÄ°wéö¥XaÑ6cÓÀ>NöJ05#Ì›seêÔ0ûÁ¦("Î=U¶l‚¬ŠÓ6SÌŠ2¬ÕöC¨¾ægë¤F2Jüou¸:¶şÄ|1Î‘Tt ¼iãä»~[IÉ’È÷éµï+OñÌjP¿ú™š™|Í,ëşÌt.ú.Ÿ½ßRXx’‹cİ‹á¼Şã$å¡œ©1¿<ìĞ»š·íËr}iÌ#<â©`qN·õ1ëŞ:1`çë
áh	ä[v0™î‰¡õ„HNãn9Tšrƒ4GwŠÕø*=(å*‚ÃSbz4i«ëw“Ô¶5BÂë¢ğô˜¥!Şğ"Ã¢=Ûè$AËr=¾İèÄ¥-±Áòñğ¿€¼Ie9nÎD¾“œË%ù£Ğr/ÈG½Ù»›*N…[NCÍM…æBlæğ¤¶Ú¥]ïìŸª'6Ah >g†u10F.ëS@A?ì¦sjZ:©ß‹¾Ù
Ÿ†‰5{êÛZ¥C“@UâBêœüÈêüÌÊÄÙáÑ
¶» §*ÌP¾o”g04˜;½í•ˆí½Pà³X«à¨î:RQsç¥Å$Jˆê’b„»J,œ'@ëºÁ­3FÚ"7~bnÀIG‹zúw3¼ˆ!‡Ó³!O³Û†ÌİM']ê­&˜Z<µO¤¹áÛŒ6â¾fhİĞÉœ(ÉÕŒJıhyçŒ¡åŠ˜èÿcÁƒ¾lœ¨T&’úè*¬¬™0HŠ\É«Àã!ÃUh^Ò_Ï¦‡p!j¦¶ÏÊé‘Àá›ÌvÌ"İ9è"è+eù•éöÑsƒ¶Pè`ÖTÅ.§Úªáğëµæ¢ø"N#yÃÏDçaÉDnL÷UËê—RÛf›…†'ñp»+Ç!.j„‰,ÔŒa¦ƒMÏÜÑ^¿TcnƒVu¯Ù#5”­÷[ŠÂzÿªP¶a„UçÇ]ıßøM‘%t†uñÉOyğ¨2lU¤ÇŞ«X	wæWÀ¾Å:ÖnÖY}=Ò	åq¿àhÛƒ²)O÷Hèöúå‹ˆ	1ÈPæ–uİ‡Dö4 aúØ\øMáÑJAOx½³ã×8£WÄ3©8Ó"7ó‹|ûÁÂ©¨óKÀ6¶øV!g•ıüâ'L„ÌKŒYŞ­-ÛÚË5{»®·ıB·A÷>&œ³&§`?.>¯ª½âq×Øx•»3^cìÕåBörªP¡¸Úiˆ"Ùˆ¶£Õ‚C¹ÊOc¾Ù÷Um{itô+=$ïƒUo#Ã2h%2¢òEÊ¢(òŒ\y×y©-~áxW€KÇ7‚h‚Ç6‡"G¦¢6ğ:Ü`cx¯jõ Eå
Ùëÿ›îÒr…švàÅçN)ßÓnÁC[&ğ¡ÃæF½tûG‚õgıq»¼ÃĞá³†*·XE&·qp¢‘sŞ+ ![*º~=WL2>J~TF†møªYpØ!VyÌ’Op7äm~l½y–>‘ËÀ;Ú†0æR¼/Yá’œEú¥'ÂzOGp¤{pÙÔÜ¦tÌmu‚¢S‹RX°äU×~“b>À‚p²*`›aÎeökIo–Ãœxf/€FpAŸB0#™–Š;ñÎ»w›VÖ›ôWºST‡m{Şôìˆ”èÏjj~ñòß¶E³Ş†ghK|mï¦¦ZQâÉ®Ç¿ëSÔÒeRë.£ĞƒÿJr
c!AÒe#eú¸í.Ğ%2çÊ0^¸§E~à‡5|™òßB¸(°ÀuIêÍU›c#ó+¬íKáš™Ğœy¤'í÷dª·HØ—œ9ıˆf8³»619ğYşjk¾·MĞ`‡^ñ9œ¤EHöº,Ó„™5ŞK#hÓ¬ãŠD˜	±ë…ª?QÏC²mg&†‘¶/…ñ|*‘á¿1í˜a
”²‹q–wì­;•¨ÕŸùÀŞçìÈÈó !Õë%…~yZ ×ï¿ ·LiH¾™:>ÁÓjGu¹3uNvÚq2êqï’&/Œpú¸½°ìî¥%7d{ÜÊ²ºíäG]TØL°¿ƒ ¡ZY?n‚Å}Éùw¥~Y
XoN@T›9Ï¿É6Ï»*á0)XR>#½tÄiPa"ç%ÖœîàGÀë“ß6´-£UYCQù×·dX>«®€w«Q%¬Y§9v"ÔÇİôo®,bó<¿F}*óZ³æ‰ØÑ·Î5â©L3ÓIa]ÀuÂÂÿÒ’—‡hãxÏœ5[>ï.?+õ¥QTÔ©¿±ãÑÂñtc
"…Ô/	Ï\µ¹ÒÏlO•§”×òoá!â1ÜBz$µR¶®´3-O¿D¼-¾¯
œ°tÁˆŸaĞ®´\»VXJ¼)­Şºø!Ïê_)‚ÚÈçÈ;#Tó½~ƒ©¶º·»uÓ‡|¶Ózú/J	H7¸õ)µö.¦ l¨«0Jáş|ZC¶Ü×›;¢~]Èûf*“ôBœ]	ƒ©a<Ÿa|°lªG®&ğÍwXqq	±'úéâÒ´}”+ßvƒµª¢x?¯6/,>ÅJ™B\%qd{ cI#ê?İ=Óù‡§×cmC;ÈóÛ¼d»œ7ÅĞÀ3Gv¼Øˆ†nÜÕÅhÿPøÌÈ‡„±_´0^«¼Ò42¸m,³ï‚_4¼¡f|²j{Š=Gæ28vŠ„lg32~¬0Ö ÈFé®KêGƒ2Q¹ŠšGkˆkoÃ‰Îãñæ˜<¤6³GÉP_è@:ûÎiê5öJç†Mûu‰à¼·gR¡?w×¿öo%Ÿ·©¬>*x9ì»ç2›æ£‹Øù3+t' ±a9DY\è×6³¬F÷cØŒ“H»_5NT˜L
9´óˆ;¼7z°'2©^ÍX1Å„®³Å–P!©áÕà!­ÔëVï0íİ?/ct]@ô,&ÙfÃ„Àê1"@˜»ËdÎÂŠ%ßÂÂ÷vŒ&S6eé”‡òD°#â÷ñıª×7Xºm~ågasûs\Ş|î»^¢]_ñ#†}6ï?ú~íhm ˜Ae©úÚA0æYCªKïùwÕî¶{íß†˜›9ó0F®Ë ½*B Fú}b6$lT6^„q£Aµ€üÖ—	âz„A;º$~cökëÄ5ÃãZ¥vJî"[!Üq~®åu3Y›#­ŞY…ØNåNpe-Lt_;°ŒQÏk¥’A~Yé¼h ÷˜œk¡]šd!Âv‚›®ºëk<]gîOîÖ»€ö»jĞÙa“âµ>…çô9(¹WtÁ£â¡ö©6±9›R|#­w¶³×³³jCÁqó¡ßeXq£òÇ-
Å‚/ıu&…-#Å$Ì]XY°ÉÁ*Lº<õ8õî+úOàmØ.jNR¼¿r£uçc3s¤‡Lºö‚¨ªDªgâù°õZp¼ïÌ›«;oí9ŞÖ,k@ºş8b¨ˆëÑÎÕµ9Jç©<Ğd°öùŸæTÖÜñú‘blz´Y©”Úùğ³L%³i-Š™yµÆşZwÒ¡GM÷<ÓpüÑÂÉr˜ë5â562šx‘ë²Øa˜_“Ğ^÷	L±éŞ›=ln“¬è™X‹B¢M.!“áŒí³
·‡µÚMü%ÌŒ|’Ö-şi	ÆT%˜çı¢ZG:ØÀ±ÆÚ´Pöü¿y¤©%Ë²…Çmİv“³öSÌà›Á±n;ñÔ)´wÈÿV­WÅÔ3$æ4$(¢¯<	Cî¢è®cÜh1¸f ºJGÔÄk·<-ÊCÉ8J£ò0íÆB+®c»p-pË%#1=P®€0nøNvÔÀÈù«ì‰eHNójôçúwß	ÛÜ·ò)9æ?56œü÷ÒÜiö«ÄZ˜ˆMF‹åIUƒ¶µF•"{’b5™lã/–`$hÚLù Ò+ÍJa¨!Ÿë¶€«ÑìÜq£ÚÍ
O[€Ic8İ¼[0$VÛµnÇÖn˜ö4àîúæAêã*bÉ©%l>=Ó7Ò€øpFœ³.MÅˆ‡©³zy`ÿ–€<>ySÍ±Ü«–Aé}ÌÏZAfNBÚ?^ûÖ´/e§¢¸ºWªâÌ¹C;rı£Â.®¼ä%Æ´<–ËIXšê¯Ğè3ŸÏ»½Ãğş2=Ä—t¢$dH?ŸÃöZù÷o÷¯<äõİœUàµrï'$¨d¾½4ÈxÖèÊ+ºm»4xÙêµ“)¦ş?eJ]æoë¥1†uè $ö2U’·C¬098·rw¢®2ï™Ê°Ö›yê¼(§Ö7(Ævr]„Ñ·!Ón~‘	B (rbğş—Š¦ª$¦ SèN²éàÙk.¬œ§pµR	œŸ”òäöøç±z©3Ø"À ğ¤JÖ±Äárù"KlŠ{Ìx§ìR?!£*“ƒºğxgeÑà[#aˆk ŸÌ}´N)MsÓŞÕö‡GPFÎ7}3ò 
¸M¯Ÿµ]*ÄÈ>¯Ãª¬(tK™¡Y­¬¥Ì„¹
%öšF.kU,´©¨Cw¡î®ğ³ÏàÕ-J¬9¼7ï[\§šxs;Ç„óDg+Hj²xœeo*YyÔı–%Ó÷ÕPG)*^ŸZè9ÅËİéq½XòŠîRâ~sôÅŠ/„pÇÕsßn«í]Í=}>İ2ÌO€Ì²d	öº°N¯TÊÅGİ¤0Ñÿ&«%Çí/øù=8ğQ™yØğFÔw”MAqİ˜QR.˜Iûú³ÿã¬QñÄeù
÷)HZ‚åèüINÓªõÉ”Ê:„øyÈ2Hã”D]F#âKNš	„ç¾vPŠÓá°ûbQŠ'gäÑÒàÇU
Å|áC²(>¾¼½9½Ãìİ¤@ZÍG&¸ ½OığŞhàäì5Ç‚'ìĞÀû)CwUx¹Êï?¸5yn‘‘e8ùÔPãÆQÅh H²&RL4º˜òŸcuòGˆyàš~ÕÔaŒ§•ÍHxäÉäÏ°D ¹z’’¸q]ï¹yh@›Ğ]]Í-Ê„¯û \_O¸œC=öXÅÿŸ~ô(SÖ;åEm/:¡h‚­(­Ùf²¼½Õ]7%¹ºî#{ú7bOïS‡ÿƒŠÛP­†¥²¬]°sÃ[gEôb—#7S¶ÎÙ‡³Õ5Ö¯§Ï|;KƒuSŠÂôx­1òŞpİ‹¤@<ò*`Ã‰YŸ‘J.ë·„Òq·–*¹(Bp(ÀËJ¤/¡½d}».\³®G3+ã¼+qŒï,V*”ÖdšCvsüáâªå?\Ì\!ŸJá•’¢‡\$®d'…ŒßÑ©Kÿ×Š?>eøEè†Ù¬"P|¸Ç†¡ŸFğ7c&ª£™E×…ò¥A65*ê„Ÿ6éL^šĞË˜?æjæº§Œƒ'†¦áÓw…X)šË´ë7ffëì®sLºµïéh3$tâäŸûëÉ±%^]Üæû×ˆwÉ%*——Û@z÷¼ıÕ^E^Ö4á¼¬¯·ùâŸÂ„äeëg±<íHÄ[şºçåœ÷¼]êKåœCˆt¢ü0ğaÕuÎJy…ÄÕ4ÛÇàjO°yóEÊBE]ë;øG™ß3?„ ‹b,<†´¼âõˆÛ?LÀ~ò¼wò·÷¿¾Ù'-úh¢â‘YcG­IF4V{³gÕ³†,©¤…‹?!xí[7ÜÚ
v==’V»nè_4HY’¦t,G ki8~Ëã·ÉÒ•*qÎtrÁ8g_/1˜¹d	TÏ(“FöWŠ×áå)ÌÙ‡Ía¤w¯šÜ4Y—`›*—m±Ì½<I85“çºæõZÌ¼‘`7ÏC°S2T‘ÏŞá¤îÊSè‘e•|]‚v[pªëä¼?\GŸÊã³-Fõ/2Œr¿«7\=I1ÚÈV´m 4_êQü­Éz/ûÙñ§¹ÈÀmk9\Ê·‚Ü{q/Âü‚äÛ|Q2«,…yRâ·‰(¨á)wÆ?ÅÊk Ë.É'ú¯IqãŞ¸ê×)z7	¹:æşÇNÓ1Ö¢öûì~—°­‰ãÅı
ÔJ"&ù¦eG¦G›8÷aªW’L™kõ}]IĞ†V#eŠ†óÀŞçğºÜ64á¨½…vVY‹„}ñ"Í¢½¬ÍïyºŞ ˆßc¹àë—Ü¹4Íg—~Uyê!#ı­4V¸'UÚ_?}Œ»üg$G€¥ºßÑyš¥"ë½ªw#Ê¬ØĞkƒ™+RÎî0!8•9_2¤îÒ®¬”`x#~Ód×h))î.»jâQéqoî7ÓtNÓ†Xf1ÿOÿƒ)È)è“8TKru N.H•3(ö¹›{x^¥j¦$r&ágÒò¼5it½áÊÄ7ŞHp¾#PúõØØBÁ}¤½°NZHÌ¸µ@©uNº­:û6ì‹	Ì¢Ë÷Vƒ¼¼Œb“¿;&×Xğëİkn!ÇËúÇ,ŠX«Üß™«bÍZ
#)µõ]Ë-z™6R×™¬Ô™‘F­ûn6§H½€¢ËŸ%„b+[}ªë‡®ôõ¥/:šX—¦BEP,‰%s¬Í—£S²;,4/òö‘@+jİ]•	öp0áå4tû/Y)Õ‘=úĞ@¤UÜé¡s÷YÎôÍ¡c|¬$­ÊÖ¢“i…®m‰MÎ¿XRXmGî‘u´gh•Lä‡!öÆeD™mZ‚&~oöG2Bºu)İ=ˆğ¿g}ÀU•cE÷DRf”oRœ˜]¶
M\ñÇ¿ôrë¥m|ì9ÓMj\>‡˜€7z«¬# µö_XWÿŒ=â>"¶C+¥4˜ßW“Ód‹Ø›"+!Ëe Ö·F´%i¾Õât"–zó 6Á³’féE¸–q“ÆöT·“ÿõn“ğ_î™Åµ‚\z¡éJìkçDEŞ“L8:çÔ)dOÑ8fÆu°§> ·pƒqXÓ34 ë
gk¤mØÈŸt¥.pÕàÂ¹@It=ç5ò¾¤Ñ€]üÁÙàX×ŸpJ3ŞoŒÏşDm
ÒÀ¥F};†¬`•ZÕ*·?/°Ø†ıÃTsŠgLZIiĞ»DT\ ¢{GúLr¤¢ÑqîÆè)éí‘X İn'Äè=$ƒzÁÎ €¿ŸæÌÅ§÷TáÊeúû ‘]xt@1·í?æq¸Ì›A}Şß(å·w¸LËÿ¹h®{†¹éÂŒ‡ìi{>é-	Éî@‹“CáœÛtSD1>
™s«¤ëˆÚË`¯LIŞ¹;4ŠmÉK9Lš®.ğ ‚¶ çÑš2Ìı(å®Lò		ã)Æäúà³/×Á_ŸèíàıèQßÀå6{}ÍE?ã:9ÕRje`½@ÔåmĞ[ÊäÙlâà‰Š‰7çéxæ­ÛÈ‘Ê/Dè’¨¢¬U™Çe¬ªSŞf€òÌG¨€;0ç®ºğhbğÓ²Î„#ïˆ4`WöóGC„ÇÃ~¨^ÙæBˆ8:EmÒU4üÜÙ•ö™/«¨è£±£+¦-IoëTt‰­°BıYzk¢,ÜŒËL´!‘²vãcÙ)	†OXŠÑ%Dƒ/ÑFK!%o¸Ç^„4R#IB[ı›ì&_V‘˜ -G¨’ËF÷ŒÕWÅ±fìš°wv¹knº)yÀ÷Ÿó˜Òˆ°·ajH—€º–è‘û³>âˆ.˜-â­³è_õÙÔÿ÷Ëkœ»Õ¶ıùTe4knİ-ØˆL.®AõíB°p÷tÒ4˜K(…ŠÀ]Ïk‡ı»D2Tò“&ƒúgŞD’5áF3“#g~¹rv&Œ«¢ûéìxÑó4Y§FtËß|F§ed¢"&cS¢1sRl™<Vğx#‹ŸZÂşˆ	µRÙàÂG?œfu3Öêá’F¶¹¢]m—„·Á³TØ“W†EñĞšålÎºõÈc 71½¬¾s+3Ûp›¶'nŒ¤ë)îd³‹½Ó~äÌIbJ$¿kî¬"yœ‘Ú«GBÇŸêÓ“¦èĞP¬÷Ô+S{YJ×ïÓ-AC46òİö
üÍá!UP¦.wH¡o«ĞÚ‚ø9¯Ù±h4ãÖİÀ)Ü-e:Ø·l/i°è¯—ztOkŠ’ù#8‹£ĞOĞQÌŠMØÛ4hÁO­.ò“c†trBªÏNÉİª•İÌ¯FÀ±*(%ÒfâºØë]á[w13§ÅD¬í†¾lø¦eşd9€ş ŞhŸíjHçoâ5ûôt WpL`Èmé'³Jñ”=é'‘ç@#˜Ü(Iu“x*åáˆ€È_2„MÕöiõèd€€ŞŠíñ¦v7ÿ8ÀÃ§\ò™—²*qOŠ TYèÊU¯‡xÿ§yææ,<İ¬óÎ^´w×ˆ–—"Dâñ6÷p‡ª¿õ†+
ï¼Qß „«õ£-ğr«ìFš{Ã@s0«lŠZ~"ôİÃ¡=ÙÉaºWN*Uz{$gıñæ‚·\£5†}E…ªıKb¸lmø:í‚²7»r½}b«|âø44!šªÈÑm¶Õ{5	­M—3¸ƒ¢ÓJ"±“F¾‘©©³Ş¢Š ‹éÒ_óÜí¨öÒñ¬u]›Û€e>î˜òfdĞ%úg\pYÜX{Ø	ZUüà®Ckkb
zj™ŞW¶ÂD¶àw³	Øh?ÿxÕKfa3ç9èûÔùE¥¼Æà¢¯mºÛbY.
<«Â	Ï3øO˜oŞÛüï„ñ/µ«=r‡ä
ŒmcÎu†Z_ÕUÁ5Ò|J¿,5†Î—{åòÜ­œ#©RCªÙî«÷G«!ÒòİNRGŞÑ5}Iàó7ƒÃc"N›5nhsëÈNS)Ş¬"S§éòVÑl·³-¹ÆµëÄŞ'¤¾G+•Ö¨­–½ŠWŸ…H®,\¸ƒñ©ÀœŠh_¥QnóÏk¨ğàIğ¶œHI½Ú¡gV³vwÂü¸ÖbH
m4M>öÔĞ‹7’sÄ¥‚¢rñ­ñÛêsZUµòƒ#èáÓĞ$AJ!<€cX’Ü$t~=Ë¯>Ô&=7èÆÑè%š½3 "Jï.¤3a†qkßèºêæ=zbËîA=«u°qÈŞÆaB=	%<[Öh„³L<?"3W¶šzî8iç÷n İºElòsáBÊ| ’¥Ú9Á_(,EB¹ğNnıë¤Ëà0bÛVê;õäáÆ¬…„€×÷´­­Ãb1[ûZK¬‡XñÙ3·×PÔ[[0P]ãò-tiîfK±õ†ÍZÈQ¯!PyüéÁ‡r¯S»Æ´#˜h%»×–|Ú•-ŞBOë!¨ãœ–ûÂ‡’íZ§ÀTÑL^üN„G< 2Ù,Ğ}»LEÖémU÷Ñ«Î¯à¿„N‚Mcs1:*uÏÚä@³…œ¸tdÑ·+¹½?¤,R-`>Ó½VSZw!°YW]œ“&(Ì4dp±¼‰\nüğ3Ùù­ÎSXXbJe+ƒ6>W=W·?Ş–åeîØ.Â¼İÃäÙœ>ct|¾dÓ‚­ÄÓ=¼ş;¤£k´ø}ıTw\ö»"ölJPÿƒvNVæ$şIvBò'ut*Ác(óÖxËº‡aË‘È^T8°ğwXn{9	4¾ZÃD)"˜%Böy-@‘XŞ…—Hä¦dtÈªx7 `½>"ØÃŞ¬¿Òç{¹}‡8Øí@@Àc­ˆt‡:’l]ó‚´Ûoñ-
ßAÈv¢¨3˜Y„ˆûdÊf«Í•ÂõÛ×,Œ‚÷s™µ[£Û3‹k,ä_ONœ¶ŸË2}Ê›ÙÊ?Ë{Wó,ÿè4ív¦º‘ñ©§.qœ}$—®ævß\%/ıBúÁíÔÒ’¾Ö»%vÜ=£ë?•´pú!ÀÅ#¤vö?÷¥”™+rÅ
˜:¿
VNTj*a©{Añ'×Ş;$Ÿµ÷Rkbå¯Û’ôVÃ;©ÂHîUUêûc¨.7*…üFLë çEß‰ŸİÈšø2&‡D²(ûØkaZ>^"öœ&•^›#Hõ«„^i½©­òWU·œD¥®boƒ@ğ»-ø4UĞ—(uGâ> 'hHd ¢wÒRÌÄï÷X+Ş2ï%—ŒîÓ—ÀEĞp¬DZÓÉUz½]çÃñƒéü½TyGe¡ÌŸ°(¢Éo;3¥­hy në•Pgá¹ø_»ª¼´VÌØ&©ÏÃÊÕî]–ğ–cÇ*¿–†Dìf–g—!Ly|¯€„Í~Ì¤C7>'â|;^^H¦T¶Á²æo³v-%|{ÎQ#Ói¼WhENj 7j^¾ß\Ö÷y’?>ÁÑŞ}psZ€/›F™ŒÊÅ¢=5•Ñ=©P ŒŸkÒï¡Y¯Fñ‚J­-ä½‚İ¶,ûÎ]ÕÆI‰H¾Ú{Å†R-_¬˜êƒT8uã·vk›9å2¢VRTêç8o$ÒÑH³&9ê'gÆnß:ò6˜{W
Sı#e©˜|ÉûU¡WÓípï¨’à³É“­‘–¬gÜ'÷7l8zÂó¦?ãôFc:\—Ao[k¯½{˜h|GÇJkÚm.®sã«t
ûb`ÏÖ—&î‘Á+`Nå‡?# ÒÉ›ÛsºR$öŸ¡…ö7„=± §şìÜ?¶«eúƒ2FÜ¯PÅàQĞáš™qXF;­q§´FŠ‘•pš í±¡¥ôœa0hÀ<•î›©gÎHd¡ÃÌ9=ØÑŞ“à-ZD‘&$`Å¼¨wÅïTI.íÃ¯qÙX·dâ¤Xc³d×•ÍX¿I¥ì,¨HÅşJvŸE.y9Í¾p[ØZ¥,S”–õ;ª¢(bQKß¬ä™ñı…Ç‚>îÄœŒÒ¤IT«JRÿêly°üoÖ`x¨ŒEµ]\>a…/$²+u=± çT»0çGÃ>‰!i’µŞıwuØ)Õd’yÜ›ö™bå|K<Ê×ÌP*G£…|brŸAäœ0[/kûî:7áâ…O¾–Ä¦%Õ¬Ÿ+jÊ+#ë8€ùO›[5®e0]rótÈ|)Uw/ïZ¢“ò	ë5µ“Ç”R¢ª¬Rldt˜#¾î_ô—ºËä`…ù¦ë8¼´'ÙÈƒ)Ë‘ ç²1E
ªåğ¾Ö-‘˜¡guˆúÅs"*øÂ*Û¹Ú6E°;ñ‹ğYôÓûÿ}a‰Ğ8Ù«æt?úúªpğçd7µUÛ8|TÚëO
$(%® ³8Şî0ïƒ
­2{ƒñ–ø¸,J’Ğ#Á/«…µLô–¯90û>ç|¶Ö¤(¤œ^÷*ÔßË]òäCÖì7m¦Aœ 2>â$ÚŞäK”8«dõVé©HŒz£Gænû˜4šìÌP¹bó^Ñø WŠ"G±3òæ·¾ª•,Ó¥¢–„Ëï>Ú(À÷¢şU†xÿ$ëÍÆ¢ıŸ`5EÕÜÑ.®Oˆ›t–ê0»¹4'EÑt·DŸHñ¥‘Í­N—|Ò8†Üœu´OyCI£şåW¹h0z
İíÙÎ÷0áE)SxÚ9×ô™å[âéì:ÌIO_ßMc=ÂÂÆ~‡gÍ”FœÊ.•‹*7ğ7÷¿S£ğ@eo»æ<jjÈù(ÏEºï¨Wqük<¿9}Ÿ¶R®²×÷Á(µÚ
rGoôúÆˆˆjû ëÖO5eì=çá"‹ußI¹kØŸÓ?/•Šˆr½Š5^0¦¾=VsaR’Òc6B6ŸD÷“²KAƒ‹–ÜÛéQ‡›MŞ¸eå[ÿ“ˆÖ™íÇ¦X´]EtŠ; ;İµce(¾²|cö£‡ÍÓ˜®FH±ø‰ŠÓ’a½_Y°ÖÃÎ8ØÅ´S¤“®ÄŞ ˜,Ùäñş+ û¾­Ë£0ÔÕjKhûfÃÓÏé²ÒF`6€vSIÄÍÒü8NiÈ:%ø½Í3oí!$—Ö·ûg|úRRÄÑÀ&ÃùƒãÂ£ùº 2<y\œ#Ë|Zò]«üA;JF’òÏæİ½o(SÚ¯ø¯Ëa©ç¤-(pâš£/]·ÏİÔ[ÇSºücÓÊo1üpH¤W[ÉšPH’Ò~ˆ/¯”,ÛI2²/kÌï
c„ºy¼[Vtá¤ÆÉa&¨øÕfDú¢ùOîºé’ågßÖèMYìG\œqs3m+ªÈØIùô›nÃö&®°¸³:QÆ[rï«¢·‰wU\‰¡>©¨2{2ËêIË…´ˆ‰îîS¨n´Wş9ì|ôŸb×ƒÿË¿Aš:Ê9tÈš#×š|Ø¬ˆ+‡§Ü¼7Ñ“
.:©?ãÒ]®é´.PÚèğgÓ@Y¹z’ÿ´Ùİó–`¾rU:k+§Ú©6}…°Ğç¨§K…òIŒ—™wÌí^;Ö¢PÕU™Ã…ãàÅªlügAxÔ—[{/Œ&­üD,iø7IA¸ÛÕ”‹} C‘)š4)FdØé"PÀSjÃ‘pÆÀFÑQ¨•î="èÅ‰±^*xvbîFú&=Æ¦ê}º¿zÀµéˆ	Mî£‹):áas²¨Éèì\¦özHÚp³İ5ü ø»äL^Fí÷%AÈùV¹²åÊWv?jÇãcªÀ„pÌ¹>1,}Ê˜&aõ}j¿X\*|Ç«'Ë”¹#Xáó_ƒYm²	/u.¶KnHƒk¥uÂZñ­–åˆÿ`Ã‡‘sí¨Ğê3
ô$ó\	#¾P{S#.»ä9•&»×ÀFÃ³$•úvûGn'÷xQ<~-tìD—Æüí/ûÂÆ-ø›i¬aÁ;È>xJ|§yãhBùÜz¼Åi¸‹è<ÃçF–BØ{"g ËÓº¬üÁM­ÒR6mØ±HsEDDË‹3&A´ÕõÒú˜cï+£¤=ƒg|¯¨fS§™CØ4.šOîÔ|´=S•¡ÕGƒ0€ìŸÍ^ÅpßjÍ+‡`(ÆOÚâÖùNMµ¦x¬ens‡c¹\—h:İ«séxØ¾/ÿ4á-ì¯Ò G-×†Ù"úvˆ¹ÌlUÍR¸Ï¯¾Nş…yúÀó#°ëb˜ŒäKŸs%¡ïOH¹9ş1_®9Ò€[^á­¼mŞÑ×êåÚê3„Å¼–Î£ìØ’³Øé§Ë›eÖSÔê¼¸ÔÕ.¯¤°Ñ(õCB™JAkòú d 0¸P ~µ!‚ªOÔ÷ØØ-×´ndk­äD€´üÑ<@îï¸4fÌ²^ŠÕÍ¸3ÉAÄ•îMĞ"§ÂÿF¦ÆØttì¢ò¤i“º& õ°»(6ñ«Â«Ï¡)u¹[meNW&›s?•]àú[êd{z’>ƒ ï.Œv•v+Ù.câS—uÿ?¢“…ëÈ-ØWÜqTK¥´†jå–Ë(ˆmb`ÎÈ¾¬á&=Šk{#xkRI$–Š€¤€õ:ßcüÉ¹È'Êí¼Eçï›±½oÀÆr_ãÀ&G€Ø@äg©)	/ª¿#ºÓä¬`İD-î‹­²ÛÛB/|ÄI÷ÓÉŞz]—åÓ“ıZt„âR«º.}„˜¦”f'ŒC™?Ç%ŸGë„pÑ…WÙô§H`âØl³ß°QÁòcªGc'Uš™œ–ÏúùÎz]~Š©K‚•—w®™©™ç—l©f\“ïÊıˆ#$ºX¼<T¥’^´Ú¹‘ °4±srƒì=ÿœ$	†Ï%
‚¯ÉŒÉÛƒ'-dyZÜŒêŠçÎ†òÜß<¿äwÔTÜMJå5t‹Fq•À©½ĞÏ­ÁÆ4âWRª”	'VÇÅµBFıMnºBjÁó–­®ÿşb6%€D¢À&);ˆÙ´¶-ï¯Ô8´­ºÆ÷÷cN$ó¹Z"ƒ.iI²Æ8ÈIÿ®_¸Î¢wsg1¢';T„=¹¹{¡½ÄoÀ°@\ˆ}å•käT^ÿErrEyÛEêèåÃk\ut‰i­½÷iğ©½4Gø«ÊÎ4pˆc;ÅšºéJKaõ÷RİóîßäÇ2_Õ%vªj[fúŞ+æREï:ÒÂ"d°0´|DF%5d{èÈÇ?3kÉéÈûÍüdGÃÏ¢ğÕD´§R /¶¾$5®b' øÕôhÄü;30?ŠyO•ÏÉpª`®ÿ+–Ä0}&iãP)kTkßñ³¤éUFİ4»£hJä LÕ¬˜<"ª“ $KOĞÅFœ]»²é‡Fd|r®­›?Ô=wùkœ%é¾Í%È €G¢!^íÚ#y±¶’éhIáFœfÁ—]’¡U±°5$¹É©7•«æª¨0wˆ¬¹w£BzÜ»<Ö óxçGK˜	Gäf¢ A]¯QŠL8ê¿ ªBÆÿ¶[|H/ê}€´6aSå»Ôáà³h8â¶e•"oËVÔW>cK&ı«Ğ~}=ØWş£«ŞØY_^¢”:€6W¶T´wz¡u+L_${.4¿ëOmmSÀ4ö#fM%­òhjB¤s¼èNL0¯tşÂ›ÜR9&=ÿá®§÷Ú'FM)Ÿ· ™¥b%GŸºc¸Ú
c
+Ø8C&é S¥ö¿ç¦K:aa¢mãÉÏJ‡;Az•ø-§39?¸E8\›…ÇíLcÖjA~ºêÓÏ˜šĞ){WUÈulà‰Ìı¶rlÁ0ôÌ(lïı«säHlYDX3gÑ6²Jë4%œmêT+úyã°ºğ€FŒ‘À*»j‘;‡æ:Ë«¦ÍÏí‡úıL‹. Xªv¦<ÌÈH(.‹ßnªÌM&Î¶Óñğ§gİ‹ì'¡éo½´«KØU°r„K[5øÌ†jµ~ºöŒa§Åo–…¾t€$’?J Y0»5v×¿†fıf.TIj¨l-Øõb\¯¼Ì?ú“:­Á„e`7”«lû»å` }=Á¥q˜#ìÏÄkâ‹“z#[¢ü3ÀjgeÓşL ?dIsWøÙ>âH_ŠóèmdÑkL/ şØt„­bŸ¨KÖÊ²šyéĞ ZwfÈNK¾ßB!¦‰mÓ™ùÿ­;`SXR®K„·w™øŠ5q\ÿ¥ ./UUÓ¢±®»İù{ó¢­ª?¿–ÜË6E.ëí÷T÷M®5«uïA+ã2Jw³ãÛÖ†«ºğcÛf‡fiMæ•×İtCŠÔ=€ïë	z§*kÖKåmu	QXtˆ²] ‰íğğĞšnJ¾0Ì&€nÏr‹ˆ/ªlIZ¾i¨,y"Ø®è[p­wäKê‘~_Å K£®ë‚\eÙâ^ÁÓzl}Êo'9Eã€BÂïåiXbPC‡ìNyÇ/jwñØøU¿s›½z¿KÅk•S¶„–rlGğcmµ³«.îµn5ş¯9Çõo›3FV«‹	øE:lC>Ò÷/•L!ñx¥TÉùTq8ËK‡A£=M;=÷³]*Şvß‡¼ùTà”…0«sÿi İÊÛŸã	cÀÄ´ıyù0W÷‰îñ	vÕ²n.I~‘*+mg›§^Dô—G<:¤±#A8±Ğ|°‰¡Ä¸Øº©5† $†z¤œ0Á—òr1ˆºm›M *Q)¢SŸ¯š]e¤Á@ŸÄıû‰kä)7§FÇ²ù{Ø73´D1MÕâXÅ”$#Ílzb„é²º=Ïoñ´@İYjÎ‡Q„IX‰Ğ–˜4ê•c©ù}rË„²IäX>‹R=—Ø`ÍÙ	².+rĞq'5ïŞÏíaüº']ÆÇ‚Àûy{o‘á)¤uœóørn^(hƒ<=±óK ğ–PGøEµãöÍyÙØv99>–†gJZkq2ªHÂd	|¶õáƒËó6 ‡°4 L±Mïì€ÖĞi× ­ÁBpdlÌ¾µİ
Xç£)n}kœ#5Äâ8O&ş‰ÕÁğõy¡G°íU¸œ&ÙN
¡°HøŒ„Š__ñ§]ñW¦Ñ-j8Rì?zÖ7O”sBÇ+îü;ˆ1I†_r~’Ca¾M«lÀøA›¨ë-LC»F›'Š&Ãö
îÛÅãU¢ Ğ8zwÓ‚1«x©ÅPf¢"zÎŠR#ú××»0y"Óp,È âsĞ§tÁzIáŒE1NÄv†5F‹ÿˆHº~ÉtŞ«r‰øŞ˜Ba¯˜è­ŞÀ{ˆä4YÜ¥œ<öóh¢Q¿?\Jğ!²> “
ûz–é%8ßKÁ7B¡ãÇ, êËjå¦^yÚ·'cl¸Ù8@_A'óÄü[1ºµB'Oh²Éş!òCSFB«›]H²Q’^wÿê¢ßõÀ97` Ë$úÒÕË~º{Š4ÉİƒæÄ4Š›E§h~õ0X–Ç.7Ğ${y0çsÕĞÕ1xµà	Rbºô)ÌŠ	HœG¬ˆ:ÃÅõóÚ—˜Ü§§Êûúi+¾9²——ÉÑ;W—à6YÂLuHÀºĞFt¢Û8M šÛKÇ9¸Ó<KÎ‘ù¿0şÿx1¸Ğ¶ÒÙ¨Ê}67%¹›_U-?u:/ĞmÉğóö»Á´xın &ÿ0ñÿhá Úrº˜M÷<«¯jy´¥
½IãÂoAéƒİñÜ=F“m<İìh®şFáìÃè}Bàäl`/ö×ÍLÆ…ét¨smEdîò¸á¨êmÃéFÚo{é*ş©t•‰|ƒ½¸¢a¾2<-#`¢‘h·êÕCúcË|RóS²N54|sv‚@®Wa`M¾Ã8İÿ]|.ÊR¼\"YĞâZÁ0¸´ŒgÏ±¿ƒ«,Uìx“WÚÍ“(¢Œbé° 
)‹´Õ4æjí¼i[EÿÒ‚KqÇŸúôsjCû€zÁ³í}û»Îø|–›zUga™ôj°|ŠÖ¾µVa4¿;>½Ë.LVv¹=÷¨>‰|9£uúç2†KúáM›˜F¸-Õİ3[Å‹0±)«áz´ùuµ˜ûüñvÛêç¢Ù8AOqMºÉë•ÅNÿ³j¤$€õ,ÍÕF,zI¶Uz@²ö^<F5¹6CÂµ›‹³Êæzã* Ô®È[)¢9Ip–Ì6˜¬øJ‘ôàô+
Ëm÷ès$O\¸?®õß¤l8%ş¹] ®«yYO4;¡˜×,}*ç¸ja}®6OâüCócF¦ç{#mè> ”ƒ›6“‚¨zş½wïàÌÎæ³¬„°Z”dÈ|¸SPı#^ŠãÍ`v‡ïàbè„%‰(/†«/š>6-#şª½°4Á]>X^0¥Ø¤!pn¼_™×Ëø
ÏyH¥WÑƒüÈw³áÛÊ%ö+ğÏœh,É,`ùLI´õ¸5Nö~kn»Fb ×wî÷Z¬mº÷lB$&•İ˜+wƒ * ğË)|MÖ%±Cïmì$gúºş&³rÿÜù'º$dèòç5=‚”@ôh Äd÷i/ÏT;5Œ‘E÷Œ4-n0 òEöƒ®»áeÀXóõa.
3~^6BÈ¼>ßha&İòV’ó ·¼FâWŒwB´VKF“¤Ï²½…£øªÆÇİùÓË–j¦uâFSb€º2‡X\ë —dè¿SJ€¯Q°V&ï±wš7¤Ì¬ˆ&Ñæ÷#ªÈI/x[øº–Šåd\A-V0b/YyùS¯Œšde¾ÊëÎ=&$!nWÊ‰È†s8¥Â ú4œê°Ëa;¿Ìg}Ml¼àK¹íô†xªØî +Låç: ø¸Äšóü:òÁ|íï&²f8§¶»ˆ—³ñ~BÇLAğQaù¯ÂÀ\Ä „‰Ÿ—-K!íæüÓ-ü›“ã”)…,e½^]<Î•Ã#-:&ƒËxÈ9r„nºâ„}[÷:nÉ×÷p¯P“2ÆE~¨§©n*ÿƒ€­!Ü#[ÂGÙb/Ï¿›äÇÂ,é£XäòBòîZQûK¢ˆv¦Ã2ÒÚ@{J¿G~&ë÷¦€¶«ƒ‡*2œĞŒ…Î+ü°Ô	'ƒÓ½Ñ·Ì<Z1XÚ4öÊÇ·[yÖ^¿é¤f,Yfà„ß˜¥"‰Ñ2Ïá\¤LÄuæÉÖ^¥N6UCôÀw3ÆlÄ‹AOğ¬uiM,4	ò~xñÂÑ\z"¼úe;€©c"ñò2ª$x*Š‹õ$^€“Q>O¿À·ÊæÜpÕGÑ÷Ú=·¿çXæ89ºæğkõ»³ßÉŠ’«&?i(‹Üí—¥uµ°d·kw1;öô	0‰h/ågÑ3µÓêa0cpwFã[áÖ–ÿz¢tzè,ğ|Ú4›N<˜â%4ò
™š.(U?¢N¨Ö#7uW-Ü š»´ØpRŒ¬›Pbc§~¼#ò·&MHÈ«£ğä@qØ+\“ç-–„Óp›ôG'·³>·pÈÄ£ğ¹í9Ãş¢+a¹inôeÓ2h|­Ìd0ör(7Ğ•|q!ıB‡²ñ—n”³âÇƒtà”«¾ß¥IË†_Áé†]1f+äè®ÛìïyHš&ç'‘vï#"Ñ$Æş7
âU!{>j˜zŒ¨§ïªå|#•”É=×¼GœHØÓm!ĞüÏ´O—âiÔ~ëÙÎ°Fè¡”;·‘·;æÂÓˆ.r…šhrüûAšzşıŞÄï:a§œŞŠãd™%ù‰9´+Cm<CW—OnN¶TbKm8.YNŞj"?*k#¦\…¹ù~¤eV&«1½.ğÜšPêÁ•—`µZø«ïRC¾|}Óf2Õïp¨dyøËlMõU‹taâœèğhq*E‘éÌ T7½q)é_-ıÄİJ–Ÿƒ¢”F.û°ÔxleéAâ÷hòÚppáÄ M‡®Dg åôÉš0q‡™}nh4‹©R³§Öhs&cON`y|?.w>÷×2€˜¯İúK©‡éNĞ-#jä¢ní“EòB%¿¦÷˜.i˜ «†´0™%Õ:ÈJE(¥øuñrõò@aBÔ!P~9÷¶sí–éÖq'²üáşHaÁFË-UÏo|—ƒş¾ÜHÓˆ6óó9ïìCÕo%îdEİ“¨—Ò‘<à£;LÀ [ÆÊôWâ.ßîôşdåm°ı‚¥®FÊ©÷8–ôÍÏil§¨¼‚©Dá\Ï[µùºõÃ ¢—wu¤¸ylùh†±9(Ç³¹°+d_D °ê©CY÷ò]èDÃü·. Óz8Fñûbu-™Øu5ÈBAš•‚‡	e…òÍàEXeNo1è‹)W¦^1|4jùpÑŞË¦~
qî±Ö²ï‡¦æ`ÃfH	±t*-po1*Â3êq• ³¶,péøev ëJ´??æTşœî¶qZPlË3Ì#’-ªÕ@ôGÅ;±ÜO¡Z³o:©/ù}‚éÀqMâØ,˜IéÕ+e„uÉ‹ì; büÒ¤ƒŸ¢Eâ›“_mŒó–¦¥zë3?‰0£ÅœòUÎßM¯Ö1oå~í%;“ş„”D+ä«e+XìÓ«m×ë”ÎZóÉ>²}GñP$„ôºaº{ÿÍ%¾5ĞÒbT!ÿ[#%-BÁ‚× Î‡ÿ'±›Lã2’%xJ‹[„²ËxÀ86ˆ‚í¡ÅÜ\aÎ44	_,ne™Ğ@°óÙc/dŸ÷CÿiZy	è§3=©¯ ş9Ü¥FßŒ€1gá–Œ0ÒØ£½†oÄ>Hã$nvà¿£¥q¯„*42ŸİÑaœú¡àö€ñ
9! W–uº¾}³4½–O‚´dòfK˜ĞŞ•Ê„6 hŞÃ òàƒæ\azÕöŒØUGhLp£aÜvªAÑµ(¼BpÒDÖVÀ<),óŞõ^²9	…ñÇí™,@1›é9Ìn½@õ<{˜ËâÀPæZÀı0-7Øı±¿ÜÁŸ hB¤ÚZVÒ«,·£Í{ê÷g²ÈSã†œMõ±R¤ıê .0Ë‰ñ|ª(á]|…zRÉ3ÖñKfv¿SJ–&ÊU›ºGWc‹BóŞ¿Ó±£6¸æ–şP>=¿^ÃW~¦„ò’¯uÁîşçBæî‘õfw!OyG‹x\.ü©¤
Ro”uˆ—ˆ"ğz]LA# Ædiƒug.¦àJi16à`¤!¼6füEÕ`ĞBW)’¶L^Y7º20^tèw[!™QFÿœnº:BıÏä}ÓEËâeá¼gh
ú„ÏÑ~¤Í“¨ÜÜl	â/s•¯]¡æş)ÛÛÿÆ¨-ˆNô}?8Q5”eŠç©’n=âÛéR
ŞKR¶p€×‘†(¸,Ğ%îõ‘‚‹Âñ­…V	ot!÷I(ÊÓÚÍ>?XH¡¹?æÙ£ëÕ&#Øª$¤ûuùĞÔNsÔVì?{ß$Ô¶tÿî÷O0ş€EE=Ô=¼k<Y«»—ôÑöË,‚Ôô›ƒ?É÷ho"ğ$>?Hôvİb0=Ä‡pè¹3 :¼<Lã·-l(ß¹z!ò#,ıóš6èŒğl`¹©A §ÃoÅm*‹ x¾`ÓAY®9¬!¨§C[g teGRË®–mĞà°PaÉÜJãĞdE\õáŞAv¿É¾şÙòlëñ\X„s±å°à£ĞÇ ºNòzR¼‘aZÔ3Wá†:<I«êr ı˜ÁĞg8 5¯³Ï¿èŞ|¾yÎ°-@f;:Í;ÔHOäŞ„ TZû°¡YÍ²¡cŸĞ+û•Òµƒ8ñĞİşXœ=Ãg‡UŒŸêŒÉg/º~â¬äˆ8|I¶Ë²díG%i¡D—GßL×Qdê— ”½²jûFEæs™ù
H'Ã)Rœ’l4Ú,ğ†Ì”abLëƒñÇ¢œªD3¨Sè’Z¶tÙà€]s¢¢F6¬Ş¶J
NQÍ«>CN¾€|ñÓ°ÁÎãÄ¢}½¹¯˜ÙlBî¯É'Víü:Ü zªx…§^ê?¾¹°®WQ°º€»@ÔŞgÛeŠsÃƒŞ—ëŠ3–;}VY;§ûä¯®%áÃÄ3f#ÖX¢ñè¦)8s^€Æä;¶A †½gq7ÊÔQ Z‹P¢Æ>dÜl[Å L[ 4¦9#¶|uÎ6â; S-‡9IÉæ1>çµÃ§ìÃìzÈ¢~»š¯l#ØıÓÊ)9Ş^¸ıçbf¾áaÊò)[’îp/…Án=š6Èz´-Ù“–Iï-¾Ôz(Œ?éãATøhµqw$Ãá$3şøs}Œ§2¿Î26m=&;k½†x,#n»^‰…m‘E1¢–êGJ-²² we¡’Ÿ¯Ùš`€İŠ&¾ùÉ&%YTV$œ4€DÂo¥©ô"š¾IDoy9u«j®á-) êİøíğ ØÒŸ˜s#Íò´ÇLş–ĞúBö1Şè çĞŸ!Jn¦\H-.Ë¨ø&•ÓFêùEÑÓß'Ÿ"aN…îqx"­
ÀTd†Sã±ZÑHÚ¥ôïîëFÊ‰yÚÀtŒfè¨	ãk!Ü%äğ;fÑ=İ
ƒ?o‘Kı#q¦ĞÉÌZ^ÎÅeõ4ˆ›Û°ëí$Ó†ªë(1t—÷™8ˆpÔGíñò„ÂëÆØÇ48<lâxKJß½+å$ºª+Ò@šfïĞ²Ïİª¼ >}Ô
Î.Û8Ğé:f<7uóşÕŒ¹§;àR7‹¦ğƒÖ-%]cå”FJ¬Ÿİ?ÑÈ^§cóºqQA](–óé¾²4¤0°òonSCä~yã÷n' oá×ôÆ~şb$¢"şŠµ—n”ãuÚûª,¨pØ‹Ï¸c1ğ­4ÈæœzFuh
Àå4-€$Ÿ–z+ÅÃıá÷íÍ±+¤iÕf¥‹cT4á—b½ĞaÃğ]vk#¥†ÅV<ş€T³³•®ÑlNï[¬Šâ	ò2§ö™7F¥ÜÏÂ§·Ë¸FÖœE	äÖç&}ò=øª{ÊPrÆ‹îéO‚ô©Ë”ü«Ùo \ÒhR•ØÂ:8Ì1ñú è8«ƒ{n|¸0¯€šå[5Šâ!r'ïW-^WEÿ(‹Í%¿y	£†¼Ò(&nL½°iItáU²TK³Â>77ÁÌbI±ãŠØğœ»ëò“qi‘O&*D,QÅäjÈçœÆÙ_."‘{~¤:jAs“QÚyĞODzJHş/V#^‚ ËŞËÍQÅ‚Oª>é¯,RE]^â”ÕaÔ‡î5ÎZÈ0›/J{oáÍ€ÜÔš¾ˆÜé	­ˆç­%‹J ŞŒ_a{:Õç„²TlËQb'A»(KÊV	§Kœ–ŒôÚ“u¿u[Â¢˜Ó.í–:¨¶…¿üöĞ®iÍ‚Êş(¬\…àZÓÊù{a®kHh«¿?nrâÑˆŸã£“3Rú˜?ÏLŠ`D¹½(‡RøÈ;Éše›‡›Ï™•ÿğZuíÜ`\áMe©ÌğÅuCrûç$-0€³˜PØª5\î§mğmé„føl¸£-‘iä‡ÌœÒ3ÀÕ™y†+½´1¯OÅ@œ`ğ—suŞÂ;äûw=…˜=5Ú…@	OË¼^^Î Mìİz…‰ŸÛüÿ@ÉİöOùƒ­ÏÍ,F_QÎ°ö&õµ*µ- ªêËeÆQt‚ïæ—¸q¼nÙÄØ,­„÷7Ú<«t½§¸X~ÿÄØ'’È¿aÆ!“4ŠiŠW|±ëÎ'í´Ø©¤¿A¯=œ_E6^Pö¦\üvÑş™3¥õ¾ÁNhÌí!çHxpxæ©¿Iÿc2TEP™Óü^pæŸ0×æ=Y¤¹NŒş•+Â»AxE–^pøHï|æh§ÚÓ^PjGA°¯üoÇDâS9›fî‚û‹Òœ)iÓ²*?õŒ¯³Æ
‚Ü\
ÍèF$#Ø.AY&²Á¤aú’¡ıË …Eğ7@šÀ´Ld2TŠ
POJ2çÏ9ÌıckùB¥ëÀöAk‹,£‘OÍœoõş‡<Ô+CEê`Úº¦ş³00œI×µ"îGËv§FfÔ°ÒºÜÑ—„³G’OÕ¹HÕÀ£KKÖş>´Àö¨Ñû®÷˜<™ï¬dgñó“ÃôXˆ…é ….ªÙJNE4Y‰Î°ØTÿ”DÂÁÖcÎ:>¹§1E–-EY¸k|òÓœ…t£•±©ÀàÚ»Ø‚Ç'oÔ×ëÊ%v»‘È‚Í£qò¿£¯ ]ÙÍÈóUÈ ±GùW€ğ²‘©°ôòyêC<â¸³mFÇèû:ôåÛQóöá	£§=f9Vßû]Q(½2#½`Á”PaŸƒøô¾[ —qB”ru‚,F€”—é• ıói-x2àY4¸rp;Œ‡¾1¡Z5¨~eC®qD2L³£IaTŠ>ˆ¼[5¿O†ÿøBÀÀ¹³¶Ğ³€ÜeNàR—u
ÆVûÈøBWÇuwFøTÔgªËş2-ËŒZ˜…Àcnï1[Aô?:F4®?î¦{ìÕêÔÚf8ÙòÕÛ”0·àUKnÀÙÊ—D‘;®_.ªÁsc)É#ó#¤7ŞŠ¹–º°èagìª&™ğ«z‰hZgqê²ç>Z&/âûŒ„³ìŞ;Ä1ƒ"È˜O_ÖŒğ[`Š–—¹´i[™«Ï`dŞıRI~H•iÚŠ„h ‘¥,lÀ»©kŸ\Îû£ÆÑ¿¡*p†ÂµÈN|ıI4gêmu›ˆÎ÷Ô-ûÌïÌ—®C
ô`•nK\ N™ü¸PSe,Ü–ıÎˆMeèÁ}ı–U¬S}í¢İÊ€X&êB«qŸªÔ¼7®ïø®Âh‘m(
£İc¥üùö‡$¾	`J¸}º=›¯
ÕÒ"iWñÂN d©=ä˜¢ÎK›Mj!Ä^Œ7„
TI7º=‹xÚoA~¨)É‹rB\ÌB»<iòDêıNş7.‚AÈói’Îw|T‹{—œâ	&÷
]ê*™ÏïsÆÖ†×±œ h@—Åsª’8ÿĞT¼$¯Š     E_Àñ]Âx í€ É T±Ägû    YZ