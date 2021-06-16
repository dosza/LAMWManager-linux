#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1867317896"
MD5="7d70d084235e26a187548caa29975ade"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22348"
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
	echo Date of packaging: Tue Jun 15 21:56:18 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿW
] ¼}•À1Dd]‡Á›PætİDñrù ½Ôzïß2ú"#b/-¬İ£‘öİ[¦Û½Lïh¬fÜ°‰qåî1XjX:^´u0^¢^»¶äh‚æ)ª4“ò	˜ÊÖ¸NMÍ²öx—¢_ bK,ìàú8®\e8(Ğ1?¶ÔXv%z½wM·~Ù#´?åKè"[6ıĞ;f†E²ü@•e¼¸	ƒÈêæ;®’¢ß¶º±5h[â»tÇ>¿¢ÎÑ	n9ƒ¸ºÇtÏ<`põ!l×û–&×€šÛ]•`âÌšğ¾÷¥Ÿ«<—QGIÅ$‡pÖwûÎM¨µv×ä.—Ì´2óÑ´-ûåôSÂtO/ÄƒĞíÈcÂ¡6„c×~*Uğø§‡æ™÷íHïü›ò©7™ˆ,‚~¾ãéLê~2T?ÓZ–Oç‚R½G[È ×Ó9pÏ‡ ×Ø‘“ßî{ˆH¾"Ü)'0Ò‰Í$ˆ,V‘ë¡Õ°İß¡“RğG¡&îC¹Â|«:^:fÔRMÕb´]–Í@€Y²˜xÃÔ2TFsı8øÚ=%¯JÃäû ´íO`Y•`çÅ–]@%Öã7KÉ¢OÜWL•9¾ƒõ$dsZ½¨r“•v=F·ÌxI·å/êä<HW”B¤v…À!ß,T˜76™ñÉ¾j/™[‚,ßcËXI'ÎWm0€…Ûøºêúá-¢Ó Ì“WˆƒG€tú:e/ó¢oè:¿˜’½¿õEı*l>.I-/	¯Âé±•×8ô–³,RøµP²Ò#¡¸IäBj":ŸdÈñÂ÷Ä3ïàrÿ·öòé ñÇ8!¤Ít2¤…øëÙ`‹y¯Ú¬' µ4…
V6ÿû@ML â›0¨û?Fƒ¶é­XÑÏásQÕ¯!X‰áyİÎŞp/µdÕµ!A¨Î Fàà¨ÀTÔH_Dq8yãà.e…Q>éPr¡	ÈüÉØmŒéÁÆP©¾&òÌ( 'ÒŠÅŞš‰ui;Á”äÅŠŒêÀ§4Š‰	ƒáê÷'DÚò=kUÓ~î$zƒqE&EÎ"ú‰—KtÍÖm1U~Ö^¶‡É)ıZzD¬Ô÷1-"ysïMJº‡N2ÃãÈEymYÔ'îïÅâTxºšc'F¬éàûô©{J¿ªkn˜®Ô´ûŸÈ?DsReiW½²&µe^çnxyÁfSÿa†â®7iÄ¡Ü_Õë‹ô›(—¦ ¥²Îg¸¸qš/Ğ$Ğ`Rˆêì´híö8iàs]Èºè4?CdèX‹ä¢bÈ/2~yá9Ìš”êo5Ú)šı²ÉÑ;ĞQŸíÕşĞÈşe»¡ñ}hdL¥øìfÊ}<^¬]ÅŠÓxßPÇ*&:’œæpR<'Ô á…5mZ KNìì2¸>õ–`¼˜H§ç³/|A2,¬	|³&‹åfÆÔ
ğ2‡™™èçKËuXcÈ2i¥ç¢Ñ¥ë†)ª“8‚İ¸oƒ¾Àg‘ ×oLˆi3nÏÄ•Yîñ¤[mE›Èµ@©n^{¾‹WV^"œÍù\2,‚‘o@§+Î×/J77êj¼l•’nîä3ÎŠ7jÁgZ¯©d¦‰#´ é™ujÇ*xlšPDÔ|QìÒÖ¯v òöât°¯G¤™•|ZçúšÑ‰Ğ±ª¾ÿW3fŒ‡êKù`Tå9Ë/0Ö.;^Qì¥Tó5»Jmu+z’Ş)î­x¯£µßbãsq‘8ybëKâWVõdCÜŸx‰ÌÀêõúoÅ_„«O¡œÑCö¦Î'Áê3•üâq£û“x5îcDœú™\Xí5C{ï«~œTï1şjò#G›·Ø‚ì	ôÙ™=­²3`‘A@Lç²&£xráı–Œ4eÊac[ãş…_ø"ÄaEâ„’+J¶!K1d^>ÂşhüE'íCº7[™l+GSg åÿ´µÇ«nå]Ñ—ÿ—mµl©/ê*°÷I`HxUÙ¾Gì:êÃïHÍå¿™m}¶@".·\ò–q6¡ÿ\ğl±ù¤¥`‡“®š=º`£z÷è«6.„z;ntkg4c•å!9õ°p¦ F¿||Pcæ}Ğw»ƒ§Š—–vßpö/©‡2¥|,Apzê2#6©¼~"Ü@3í­½Ç6`C®‚‘Ëwµ€‰şŒ)3SN7” `ÔÂù32uã2 <¤lC4âoÕqtÑò“’è3Ôù7¡{ƒ(6¾*òÇ¦İsıò†ójfWªJá"øG)æíK]…X=
˜·¯üû>'¿ÚAs˜DRü›IÌØ¢H[ÿg–5RÚNçR<^][“·a$£VB]á=S÷%+ƒê`a{ºhzûÏÈÃŸ¯iqÕ^êBzßI‹¡R$Hò´.ÈÒwe¯áÌàöö†ES¦ƒìÊÛ“î@¹*XWåœŸLQb¶eÌ/Á¥NU,ŸïH•ì€cÂ&íÓß:AVœ¢®Ì.£B½wBğÖ{ìò5‹îNK°C´B”gÜØÍõsïWYŠ£`œD·dÊ<±~î¸Æi5D¿ıCgV^»|¥z‹®Ñ}0„îQûñnW.J©±b_0®WFúàÚöÄÇÍ¦hÌ­’FÚ½¿È;_ü€’Y[ÂÚ~­Í¨Şu´ªí)q¥WZÛwåÅ“°¿ÅÒún±\m+‡@ŸÏnwµU—}Ús¸3Œğì5â2N
Æn—ùü+7yŸI#ôZ/ÏğoÄÂå‰«Œ„Âh©GX\›)®Ær0­›‹«7˜À’Í•·ZVÆVëÈTUò<°PÆ®!ûaÛTÊİ5ŒÀÌœçş2b-ÉqØ`üüÌ	e,vI¥èÔİAŠìJ¨¡8ƒ€tˆ	4#Ãqpöuîòe%Öš9Ã4™ô“;üoÑnÂ@}ï#Ú*ÉÜ•Zv¹Ü;ìö…¼MSX!ô¬¶r.O&öÛ#.ôù–.nñ‹›Aı7‘![éL7H1û­4$aşÇb)mÁƒ2Æ{yÿëËÉøRR‰Lp².ZcZoi4+'DNÅô¾ã98Âw›ùç…‡™JQÿÚÆ õ7ûZ[Ü ìİâ¸Çõc$Üù?›4ÆO$Óõˆ¥€^ZÃÓzWkã-Èˆ÷¾Íá5w÷øâéÅÆ|}r•Ô=Vö€œa]z
fyIë&ek6Z®d²VA"<v}JUK»ïa^)ÛE}æ|¼n˜L—åØÍ$É"©>¿$üPSæ5¢nÖ~¦w`‹Œ9ç†gEÔ´K¤¶)bÚ£ÁÂ“ïJù8Yd[ı"ø‰ÙRœ¡ôTªÄg†Quf<Ôà ô¸ÑmLCÊÆ`H=÷ÌúL^şH¹	¶hh¡öñá1`è<z 3[,2r˜9Ï¸»'ùMhŒuñ¸]«•ŠåqI®8ö1*ğöèú2Yæ40Gœ›ªBb"T%Éd¾’‘/‘mÑ9h
À².¢uñãZr±	OJÊl°‰@­¾ucÓÿ–íJ¬1âö­ŠA:¾šM’d¸îù84ÚÚ&›Uw]ı:ˆ¶àxéVë—§!R0bù5®àGˆë•ÑğİÌÙ>«ó"ÿ"u1†9[‹Ğ^ûNÁ£"™M^ötK¬ß'„,e¬(Rûüy$•}b‹±aO9´t˜TrKAyZ§%ËC;>ÿ°‹´ÄNïGn0á ‚xen‰úˆîbãÍâH/à{1\¼Â€RH-Ù!ázêôïöäßµ÷d:²[İ$X•ÒÛW”)FRAëVÏõ¥­ÅqÎ.4·~¶n¨¶ê>ˆŠÉïk»cÊÆCª®W"1Aì\)üdvx4ï[‚jâ@Ï/$™v¦&±€Ùc™ñDU¶§ëLç6jkquì|_¨À“{>Êğe]ùÑ\iÓ¯ÇğæˆJôNßx)£ ˜?•>Õ#êÙ—‹2¼ŒÜ	ùúšâüâ?±50å!]9Dåğ`öw"‚qlYÏ2µtmjn˜@òUúJDE¶(U5?G52—w„tŠ”†ñ¨K2¡ë	ÙšÎ¬èĞ­å#æ–Ø3;¡ N7|gò§úJP¼ç½­9÷,@×Ÿo`,qV*7©¨œö*Ëà=Gu'†¡J-èÔº}±N$ê¤^ŸwÌ·K± ı‹€µæ®åŸüÅ¹ûì2ŒN5•£ïz/oÄê¹Ei›Ç :!æ]?İÆ)â¤¦MS|‘ëcL‚öîÃĞÅ e(IZ>-¬Õu{V+»ÇÄŞÌgôä	SJtÏp£àëÁ®ŠbÔ/Ó3n¨PRg B†5Å‘åâğJÀ&E‘©.£ÇÀÃ>[	z•Úÿ‹Õ7Jj¯ÑÈş¾AIJ´í–£ŸbSnË¡	ãƒ¥bAÆ€Ø¸şóMƒŒòLÈ2ì3ˆÒóÁ»tFGt1CİÌñ<G-#ËâÅ‡½’f!Õ÷Ô^îÁÊ${4×òW_¤6Œäœ– ˆ‰xO”SeÔŒì
ºç5 -wüÒ˜*Ûœ’9ƒR£ôzJ7lç¨ú´®½‚,{Fµ4Ä`}H	]%´'eî5PuóŸÚx›´J¸Ûäİ<ƒ‰x_™>¢RvfeJÒeódzaÌ®Gd aÙøE¼KŞğ)+«<„jDÆZ|¹\Ö9&úXzİ°G…ÏÈwŞ´:ƒ­E§a'&	Ï%Q}tÀ²å²ª.˜SañÌgã^ñËßÄÑy¦~ª4›°s¥ïZŠ[ñ´! ¡¸quÎëÁ‡°†÷L"É‘Hfå‘q%ZÅ£ÚĞõ†ó¤~Çš4+‡ô/3í	g»Y`ü@ŸĞöiÑQzd7BÔ›ítsd¼‚¡_•çÇ?›°€·Db'İÏGÊ(RWíœ#!ÚPÛbOüA
áÌÀÆŒ¾¬%ùs1Ä/üæÄ‘Œ®GÀŞ¨ºVÍY”%£À·ÍÖ]å°
ìX3ír¬ó¤\Üˆ“ï-Àì¾ék‰ğI¯x¾É ¦«-ÔI¾Zgz9Õõ•J?Å{À§šÏôdª}øØ·õ'ÇíLüŠš1Áœ*]B ®¦nşË‘Kj)4Të5`É»òjÑ‘®¯ccc4°ßL—]p 7È$)su$£|è9Õİ¿"9z˜¿(©gèƒâ/³ÎMâ„N£óûìèÁşw¬P^Ó÷'ÔØà$ ‰«o?±7^j“ÿ]`…MœÌ½T€ïJ3Ø+ÛÔ¥JL;wÿğ’Ò{¼Wô.Ÿcå“Ã'‚ÿa’Ò½aŸ¬%;n<Â
ŒyÅ%ˆç¦'. 'ƒ<±ö*e\Ã`e“ñİıFØŸ-=;Yõ<•{³pÈFøraj1ZTl“ AÈê8%sw]Q.·¤¸Ñ-nVv²6’
ç:Ào÷ÈT™¦j»ÉF;‡~°IqT3ãŸ?×Ö®²œ†iĞ×8»÷—OIzgZœË	¬3w÷T¯é‘ÿõŠc1iŸpÆ(©àAŒF²úRL3†éÀ%3Är©²`n¦p¯]'œ@o|
›ccKD·T§ÄK–Ì¹àâXí„¹ÑÆÂÆ1Qùº2KQl¦û:R¨¨Š‰ˆßÕ	ş{Jòá/1¹­éhœ‚y€ĞàÂ‹{³ì(ÏÉ^£ºÓWM<šEZ¹¥£Ï Î+ˆ2KÁâNr€Ÿ·Ş,•çj+É§÷:øœ"‹?]T'€ÏÙ0ÊÉ,…H…ŠªaWÚ¤¤”Ò–[y·Uè&ê¯õ¿Ñ³ïƒ,.ætPæüvsFÜlW–ÈVdôŒ4æÅªX¬u(1g7¬5(à%rÏmtÔÜ­8ç¢BÍÑÖşõ#F÷•…
’ÄôÔb%#g3DÏ-,JUµ®ëAôK!N16êÊ=×à*O}=8°@nxê¢ñé8ÒgMB|°h+”‘Íô–aéç%Já59Fºá¤,7|0;É¡6)¶UÂz=…Œb2Š­<ü¤¤æY›.,$•	h)PÍ2Yg›¤KHó'»" WÂœß,Ï†ÚÅÎ4eC'kMÛ?êúJ§G67Ró	˜,g¬×(”&$K“Á-²RŞ²×IÎsHwËÉš‘ï™*j<Š~Ô„õmã!)¶¯üd3ïÉÅºí•¢b’É¿¸ºEn®,¯Ò23W¼ÿnœ!Ïé§µrsÈÈZÿÔÏboj”Z¾=åwÓÌ0—òhÈÀÉuæwk2ˆ—iw ¢Ì¬µH&î)m”4¬Ï'Uí	æĞKmøû°•¾ºfÊHŠtüˆn]û3ÌñÓÚÛ=Hş¤_Uîèş&)}ôWÚA	ÔÀÁ²3FÎÓ)]Üó÷u,Y9îîÁ^¼}ì‡¥YœR4‚íh¾–ÿÜ€|ğ‹=ólu‹¿Tòw"“Š=ØÜ’7ó[#_S¬[V]¸ _sĞ„LXúwßI•h¥$ö”8)é  »8à~/SşÊ \„¿Æ²SIê4>eúàˆ|¦Á†ğ”AıÛ#zEzİø„o¨İ£c÷BÖ¿|…I¼Ó³ç\µ¸±àªÀì«v[&Ş ¿«èj½ğKàÉx_¯(´¼Øìb¥˜-¡‘§Z—6õÆË2ºÄxyQU·I‰­q6ß€±Vb(Õ½á%Äb™W-ù¤‹¡QÄ=Õ¡F¡|r= Û›ì–EŒ<·¤r‡êğSa‘æz±†8bÌ-Hjeh!·UªÆ/ïNv	LË‹CŒÓÇ¥\Ò±¡Â1M‹3*Pr‰0F\^Û(Á¼@ö?©˜?ÍÇÆ9Y«°½+×>@Aë¹&H”óLã€»«1u+'Ù##1”ÅM8–æºŞE•q~€Øõû4ÖÔº!¿ü:Ì,“ËâR4oñê¾çæøù5¤© âGÉ—L‰·é1^Qí~¥Ù	©~ÊÑ—93ŠLß°=fLÇÀ²§Ôï6æ2NrŸ~÷¤®’¯ŞrJÈ»`ŞÁuåÇU8¦Ã÷'%'Jg6:cë—üë3´½±øÑ—”:GÁ¦'¢¢-ƒ*=¤d?‘7E9ö¸’.ôQïBRL;±¬×«™[ü&goµî7«^¯İ+n´Æ7ÀfQµ•!ÂúLi]ÅİôŞ"øñm^X!;”Ù8ƒC­Wc¼Wƒ+ß¸~_ÕSïG³AH¤4ÔyW´yDxŒ'İ£rı÷Kp®hÔKÆ`¶¾~ö‰÷–×ãQÖX>ùËo'ÜãÁPZİ©Yh5Á˜Ãì€ï\{mrãm2ÿbĞ„jĞ8€¹x…R;-OQ(çCSg-kJª£KÓ’d‘3¨5™CúªÚ%ñç•cÁ•Àdn@y _å7!š@)ÕŒbA¿Ee3\áZVõÖ:×Nğ½ÃÕAí-ı
eDò/Iï¼Úò-!?º@ ¡£MÙí˜5şêO¤í¯èì­¨U³•ø¹ åĞ5GØ˜Xbê$C?‚qNÆŞşõ†ŒJSCÊ.ŠÕT8Í—$I³*†î)ÿü³¨\¢Ù¹ØKJ€û7L.Úº#¡<û/çâ³KÀ£8ú}°Œ:ÔK */1şZ‚«sæFfßÖÙ8´	Âæ%xrhØs¤v‡]xeQˆGişªÅŞô_~Öt&"•çhàŸÂ¹p T‰ipXç4ğ×5ÈØö’_ª€Ğš´¾ì˜uAĞˆÃ›'w½±÷h–ÃUÕ¤ié;³;‰a¶{&|:8•N±¾âaûãC¸@M[|?üÜ9E-â{ã0b¿å´û¬²+JVd- $1@¾\ÂŠ¸e9($Šâæ¢Õ²ÈLñ9K¡­èìCXª»ôI&u8„»é¸€ª­¹«dĞ",vöRïQt}È£Páô´=7„á4‡\b¾({i?WRÀQ¹iô«Çå^‰ÿŞ¼à>0*mÉF…ˆĞğı73×”rrÃF5ÍØ¶t{ahÂ¥İ	øu7ÅaDPdàhaÉÓ¤{äVDã©;ìp( ‚i~µq÷r»lI@şK3hÜ»3Äv7•¯¾ÑO3¤*„æ¦*«Úßh]È%HM³wu]™ì¹“íNÉ<µ.YŞ´N¸Ìı!+&fñ‡ŞCµVwì¨·I:Àq•VğÌÃäûõkûQ©Ä^ñõÜÕ8¢TŠ¦ŒÎr‚In‰ŞMÁ;ı50OÃ"¿ú ìd£‹€@É­Á€–Mğ©½}9;w…Îÿ½…%IöÀ].]o¸9õMMW0cu¿8£09“x–vsMv•ØØ;b+¬¸se`øø£şğ!¼)®¡S^6óæŠ»d¿](®¤dUâ;Nà÷Tt>y"úF|”Ê‡¢++Ìmí¤À„¡  ÿF…µsŠ·Nõk·İwØà1N…èr9 |†6˜ø„ jBÙõ-DšÇ2¶3ä÷¾6E¸?›û@ &İ‹öÄáùòåşçõÆ¤­´Cá~_š·Ä)^ªtØué `ÂC»Çœ¬›âñ¸% k•[%»vûãìoûJSI’)²›–²B2iº7í·Ëø$~h²Jéæhí2D©RÙÕÛÇZ'6}AtÌÔéö¶F?òÑQhÖ2¥–»şQÌL”´ÃuÏáîéÂ"!cËÓ-H}òø\
–ÿ¸ÇëK<D$-tÏ¶‚UZ+ç*Ø’Pøä®DiÛ8¬¸³Şè¦œº.êú]p.×½68)‘»uEâ¶Ô8¦»Ö.ÅÄ‡m-c©l!‰\ÓpoÂûÓÎpÆ5FıÎMSˆ‹ÃqAcî›Ï È8Ö¶²}UÔ.ŒT­ÿ>Ãæ/ä4…¹+äö=î.‡#WåT#'5B›ˆùšU³ÖE£gÁf´k+ğxd>¼Aª5À’ú0xö"Ã&+ŞJQèÕ|÷›ïçtv"LŠ…Œ¢s™ßìmr–õ›ƒö {½FĞ±ÔVêö1ÑÈ,-ëª!9:FYÔyy4rm¢¿r~ 2s Éeé¾ÿ8§fâ×Û_üè[»l‘’ÁÌÿö1X—ùÖè51™hM~êÏû(„ìë’êä0J<íŸ®Üv3úÚ\<6-*¢Î\Ì¤$eÕ™n8U{¯˜R%ı m'˜€æ““ÉOªÇ›‘;H©vÒ,!Ï ÎCp¹ªä¸ó6æÄİğjÁ¸c¨r\¹ìíÈ3vÓ™İ;õV¬r¬£µ+»N†šuwMÆ±*µgmâÓÕ‚\ä/ªm²³"Ó·VÜNg°5qW¥~zØï«vØHg¬˜/ƒ‹ìñ1€°¢r{]é¼µ¤Fùï·3û”Àh{~ÿg¼MÈ³¹OÔ”Ÿ‰¬¢&	Î„îËêEY¸Ê¢ˆ¾lŒ"ºK{§ÃùfğçOŒ™ê=% üy©Âî‘‘ÑnÚóéõÄŠtíJXÎüN×„ë0“”«T„È9Ä Ùº~ŸäFl
Ú“‰ç@	^b8db`j][t‚°@mÔ1Ş¨©3-ª›Ææ½¡ÊƒZºÇ²ËKr€l†ÛˆÎÇê”Ñër±áé©Ñ¼$[×_İZ€#˜ª{.ÃQÔx<+9¹Ør`çÅ0RBÏ)ÎQ1“	>µ_Zš‹(Oº‚2[İÚOV©“ :5ù„×>ähÒ3à_,f­•¡LX|À¯>I»Q´™–arh}ÑËd¸WäBRËZ
ÜÔs’İ[èí~\Gtß ¿ùµ|nµSdš<hÚÑ¤ô|êtxğı/«P8Ù´6‘<{aú"&ç]Š…pî­EØ"®¥"ƒrƒ%üö½.İÒğT
Jó DÇìˆás{¶ŞnYÈÀ;±ûíy]&ê¶@+Ï›¢‡NÆ›·ñêÌeeÌt¥İulë«„ÊÀSš¸A9•Xğú¡°GFmWó±àz0,÷ Q]ÉÜâI3a ràD«ÚâGızFšVÕÓq"È–Ÿ3	0‹Ø<›ÙÕ×&[3Õlñ¼\«{Ò“ôÆ¥„C¶y^¦Öô¶IDI
%
³ü—£T%UK	İÆ`óğ*ºfõã`§ˆe§‚åH-üÖ9,¤hÿÇÁÒ	úõ€¡}o¼'>ÿs£LíU0¼`óÇ[Hz4×48\÷Ù•³ò¹§£ò¬~ë-;œB¹i
#wM«Ñtî›àX¯®ã·è†j°&,Z	6|ßuüDh"ºQ@4Ù<¾ŒĞ¢@øÑGùX(kñ¦€5—£}€¤Î[Úœ|±*Ì¡ñÀHá»İR‡–U¶pyõˆ~8*â›”Šœ¡İï[€g3Ç¦\Ò+*=QşÕşÆ®ÍFì4¥¤Tî•÷.‰ŞÆ(ïíÉ^^#Ö›H©ÄÙ?æÁ>('ß‰ÒÂÅc6UG2bÚÂİl—+‡ç%…Q?Ñ¥ÜØG‹§µÒ¡´ğİ€3Ô†yã„Äú4åÃâVˆğòRu Ì›] –äè¥›³R±ô¼yá?]Vö?¿fü²MhÕ–Ş@C—]Ó9Ñ¾Íà„_;ºo·Jo·È[Øù–O:ºı¯ÖÛ´écdc%mWØâ]¦ÓÕ`IY?p$Ü½J*âÜïnÃ£ÂÖUcŒ{ËglâÜàÚşhc«©ûdœ|
’…»üÕÅJï¤üÙ°{}£:…OŠ².—{s±Åšöo«\ş†¤¡ñŞ«Ò wgûpãJx²İÇ„j}ÓŠ)¬Ú¾©Fû¶åGrú‘Š%Vh†ä’	-7¸ÕŒ‚³Ø…t?ÊØ…wEµ`?‘r:à.EÇ;©>ÈÆ·ªDA›ì«úıìÔ”MK‹)0:©¿ ›5,Àéu4v¿ÌïÊÇ]eLD]¤GBËœÛèşIàÓªùı”¾#Û™Ï8ŒA¡×ƒÌøIğñ©éègœq0ÏDC5‡üä°/ÿĞ~^­(Ùj_ÀˆãàÛ±^…1ÂËGëHëÓ'9Ø_Û='o>h÷".Jã´Œ?(öÁœÊ}1 ÉëB”rÖƒÁÈ-Ú5ÙRWAªFõŠonã›<eºcÊYş,/j¼ûåO*)p®¹N*c7‚á³Û•ı=_¸ô~¬@‰r•ÛUí•ì›×êÄã˜v1©¬j¢6F¨¥âyQiaÈİ”Èb8ßŸGrÉ+=}:¼„Û<8êŠ.¶q%9üüjßióçğÆÿ¸3Ùpz`Êıš¾/zZ;F€29ó™İ¢ó¬XKh´I¶İû1*’Ÿ¬¨ËFeÒXø÷ï}CÜå÷\€…‹ôšu‡‰WîÇJöaº}à8¹ß=40Úòô
7xKµHìº
ß¶™ÒĞˆ××à}“«š&!:{Ób~HïÜ&ˆ„]Aä5 @ıEÖGæë'*’¤³é°ÖZ˜zgÇÍ:6”FgEO®eu¤$õ'ÖnKˆDÎk“ô–Û¿]E¸Ol³è|æÏO¢tz=±å‹½C!×¯ÖŒÒqÔ!¤Ñ¶@¸ ½‰RÙuoƒáÁ§°%|áwqL¯Ó‹oÅÔhgµQb_s@q+7?–ª‡`bŒÓ
"ÏXö˜FH>=ÑPºnÁ&ùêK§ÿIšhî”mxk@Oİsà³r›{ÄĞ-¡DmşL+C…ñ «³÷ 2·pÍL±¾ùéÏİPÃq0ašsìd¨lm€9RgùëZLÚ¥ãîh¾$ÜŠ„fô/ÅÈuMKXŸëP½or÷À÷P:«DÀ¤*ívâéÿo¼1f¼V`Ueƒ´›öšxÛÿIÙJˆƒkêWD_ÒL$“oSÁV ×ÜŞ›wrãÕ`ÌÚ!V
€	ø sˆ‘‹J|ŠçşªP1GPiéÕj²Ù‹îë±0Sç;ø~L`QµˆÁ(Ø+2€”‚à&×[ÎmàBœM‘%õÛqÃJ¸çÀ¹.º[EIfºİ‹aWåöí¦c€œµ»fi¿a21Ÿ[8C®`ıˆ
ÑydÍ1ÚŸ|)Œjr¡°‚ƒŞ#|&§pôçX¼¹¤M[†‡èkCÖºÊ£¸`äf…±ÿÔSŠW–”¸´Ö“q¿>lfÌ¦—•Ò:‘/­~8a*»©â¹Åšè$Èê‰ƒxq½Š ¦ã2t#êEô×iOä±cg
TÈE.k½``}ş‚t/O| Œ}V³È‚4wS|ï[ªŠ£Dˆ~äêEUZøN‹Àõµû Ÿ•ßÀ’Â Ø3ÿ…/¶) D¾¤È}£êQ¹Vtu:I ÔŠ} ]£Î…h!¾»Ö;ÔF×Ê¿çÍM3Õ™NÅ(µãE­ÛúsnıØ D(>è©çiœtˆ®¨=%—@O‡ıéßÊ„MñombZšı€bD”øÍ½bs™E¥òı’d’ ŒááO
ªeÉ³â˜Ñ= !œ‹a:Ñ~KU`’!‚Ì’N{÷±'aÀêfÏ„Ä<2ŒV•ÀAz4'@ñºwØn&¸³R$læÅq‘l{Ã ~ÉúØş‹Š¨-ºıV	O™5a7>!³ScòóY¿ÌWåú´¨*@‘º“”ìJ|2ÀfJ{pÈ=É•$q¢'¬‚mœq(J ¡F‚›o°”…³©/
»pFç;yîóÁàn} T¶'»°Ò¶Ú\}ÒHÅ¿e‚ĞÆxíåNè£¬)1“häõÏ˜_ŞŞ 7g]¼·¬ŒÇúû>§¢S‹›³fgğpT¹±ª„Õv.ÒwaGæ	g¡óñIú¸ŠÆÁX”ue;ÿ±½ÕP™¨
µé¢uiÕ‘×.Š&ª×ï›Hu»Cñ„ÈËÿÑÜ<ç$ÇÓÕ~N‰Ü|ï•çÌÏ,Û|ğÒTÎèv†ïøÙZ[übÜ•$sórÌ×>—8[M¥
#ã3Toöö‰kk‹ügï+o©Åd)’uGI<º
ş‡“È,Î¶âÕ–ZòVcì„<ùè˜n6«¥³(ÀÇFğ‰û)ÕV0/*’|n×h©0—¯0¤:Ÿnq—@£wCUÓ(Ë®·
©•â$¬ÇÂD$Âà§³İÏÄ~ÏVö¬Œí7æóŸå‰í05«Ü}ùû¢ZvèúÙ5è‚ß‰–¸OHŒ"fËš"³4{3+¤ÑŸ€$
~‹“~çƒ¸ìİ=4”ËÔÂÕ³X? 2K¥aV÷è‘o4ĞÕÖ˜¬·]ØÃo˜(¢!ga‡Ã^CôDk»Ğ€–ÈÖÅ¬™ \h½~Ş@“:‰‰À¹NPicÜ“‘€ğf¯i·¯‹ÁÊ®¥“ŠPÓ³÷ QD—º|£ï~à=Qo~lÁSRblj;5[Ãö¼„çl¸ÒÛ”¹gcùñæ¬°Lòs¢ºò`ºA{*ò/y)M€:–æaLíshÕLRş(&*˜6Ğ¾t^,"¥ •Âk”UôÓ“¦Œ½¨=©—õ/»!
` uq µyoŞÄ?¶Úe:Ê‡³©ô¦V
åÊ>:ûŸt×™²TÌ\[,ş{=Ê´~ú$g~*ã×'BP'5²Ì3§ç'ÑvÀ(X
QŒy¼;$:?„[ß¹ÆúÉRZsÔ¬f3^®:”$¬Ä¤ëàê‹‹m|vX eıñ†÷ôw‡= @—ƒ½íßCÉ¤“}‹G­İĞ]çµŞ”ê¤:É ¯~%¢:øçvscÓÄu7/ôê} Åh`ó;º¾IÆ‹:¥Â`ÁõÔÁ6.›ã§9+ëú¸ŸÄß~Ù2 ÃæVÿIød_“üÅ"ı¢aÊ§z<ĞkŞ(gñ;Qê#Óu¿¨Üwİ,Ğw§ÅòR½LÙ¨9lúÀ G›gE™nGwÖ!¥ùà¡ö¥3*æ}Áráö/¥ ªx #®Cisó¹3`­²…wÎ`©ìXz)ígµmò—üu8¥Fôà Õe özkv!l¤›™IÀª%‡”fˆ±B˜`#²óÎòßÿÑvÉ†äXd?Ğ/r  õt

cqÿyé·î‘˜…æ*.[îÎp7ö¾¿8û
4^¸çĞ#ƒ
wV„bs[FT…âˆÿõg?§	Œw“W–Š\»Åb#d)¥0|ŸZ4!,k8ävºZ…çbÌE°¹­“®Å˜M)Şÿ|fâål’Ô_6OËe²©¬ƒFºÁ92£Ü‘û—D=$¸ãQ§0ˆ€/oµú¼Q¯K“Ø}¶`T`€à¡åå®tÀı`–œô\'ŠgŞRxÊ¤}KããÑjw(®/¼/ÃıÿüfŒŠp‚3>€†AasŠ>ÿñÎ„pı½¨µáÖàLšypS#~¢ó‹°š¿`V08Mˆxş|ùí^âTÊù2ñÚéõ[FªîîE+ü5}ú:"_W£,h¸÷›„>ÛdfÓZW8¿ã½^tê£7QÿB,«|Ù2úÍÄZ÷½Ö½™mZCVtNa&åO•’Nw—˜kÄ*b*µè´KÍÔ/7> 4ÖîÆÒwKëô"Å@ìñà‚Ş6ïnN7K¸»gnB%A–`l–‹™	åÀ¾4^ÃÕ# ìÏ]à	(è€À@YVâ"b¡©“Ç™Aôq;…Q­?nWPVÂL2-¢4şÈëC3LU)òÂƒ€G”ªàrdÛ*! Ÿ$;ûK§Òúy>îËjî4ËK¸9¿¯]ú>µKšğ'#5Á–æ±Î¹`İ%+9œdRaˆR¯–C1®O¤tòøºY{Ù©å»ˆ/7T¥—?G†#8š¢ŸÊ}üGı§ÃãG½s‚\<öúSnJİ'±èÂEİH–º;?íoÉZ.$”¶mão{7á„G›¤*Æ°Îs’ôˆªn…Œ4\iu0%Ÿù¤jdz”}n|@©_#&Ï´8ÁÑÁ,vô½]¬í½‚.æò4¨i€{Ãƒè7’ï—d»áRåœDŸ hˆN'^ÃMƒ(½¹YŠW;NçŒˆgMêE×R«…ÇÇ+½¾é|ó&r"¹—†”Q7_Éù€õf6âJ?D?x(Ô?
 ½{¥‰M^^B-…’70˜`*U0&P’©NYÊ;Œ^#cÂ¢vCÚ\ òhj}çRØ€gI¤…»LH›õôdAá#Ä„œ œ£TÆÒ©ç[¾!×ÅèÜ–áQ1&—bó#õu{¼õ·ä­1Kõ~ø~É{%ã¥RŠ’Ø}Â'ËKR„	òª”(t½­ƒÇÔ>8l Œ¸ŞK#©‚7¶–‹‰å/‘ ]~5O”kR|ş† 4^K¡<gùúN½mUJ„¤–ä–wèĞ>oõÜ¡!A%#ŒÎ’† ÌwG€›SUÍ¬I£ÈšÀûùFQ£Ş–§2´Ş¾¤ e¾‚;ºÕÉ+		÷~ÍrK¸¹yªU:Cî4ÌÉ‰¶´Ël\pGÛ•™ C0Î$ğh+iîi"ÛU·uDgÜ–ª¶"LÏ ƒòÓ†nãS:Â2ƒ1O@NŒøR464VÍÑQ&eà€ÉèE&ŠFD5¾j%2Æ­ìe´L“¦:ZÁB¥Ò‰!^á(œY!mÒICz19ş_±üÎiy{ø˜úûîï±…ı×£º–“
I0Ø[Ü2).ÔMlv5<¡à|rÁÿ<f}S¦/uó¸å5.¢‰îYKÎ‡ßÃ :Dq‡t¢!¥Ó`/"-nlsöãn6ŞwÅ¦@ş×†p¿¦ğ~t”ïŒ{Sim:Œ—wU“°¯ÙN2ÀÜç !‚8H‰tªŸÍ7IpñVæ)|rVøõb²È#ìÃœ:x¢¿-
ƒõÌLu †!GX>Ëª		¯ÓÏÚ
waí	C¯@…êL|*&Ì2`ñEüÛå“ğˆ®7àúeã“j¹wüÉı”íN†$c§µ°’`…ì<X5<³y1÷¦öêË” [6©İ¸¸•Í»h;UI3Ç'j†DBíÉ%8÷îGpÄ³hÄòÿ¿9eX.¤±ò?Cn²f%C CJ3¬!±QÜ'$]#§FÁ<µS‡ƒÇ²3ë­ ‰Àÿ*LÂP„;[9:áùjØÜ€,IÏÓÒ&²ma*À„¬·ÅAM½ü S‘¤À×“Õãû;.@©ÕĞ, 	Â
jÒÈ´ıA0Äò“Àî“ºå³DI[“|¹ĞÓå#Ş¬¾b	ÁÌ«xêƒS_Æàõ.…„øvÉÆu„m'#OœõO@h ¨¤°œÇvªØ's'×”P9]7¹Ÿ¨A“bŒ®Êş€Xûû;¯ˆ/ÉH€ Ñ²½x}ì»7Q?ˆµEdùL½¤tHŸàBr¿K 6^;Pí]›Ñë8™ÊÉœÊíuã
š\µ(" ¦ğªt¬_?Ï¶è˜~+U4ÛÊz:[·ÙD½k²b›Tyâ`–ÒğH>¶Ç¡"âÜ©
æ|]N5zP.	Ñ—¹1„6é¾ú‹óY£ yäJñ®‚a›iÑqÈˆ._ké¢G½Ø
/d`ë²ïxƒ¨r÷ÌxÕ
«Ô2¹‚ªÚümë±~ów3Ggñã€€P|S“¼¦ùUUû‘Øµ‰‡¬JFÔTâ7›~}ÒÚ&=èÉğ¢ŞkM_Œ!Gçç”¬dÔƒ°d—äá]d>ŠØšÙÈMY×ıC™×‡–*•¦B'¾>ºâ}øF÷+•ÊbÜüdš"Œ_|,%™ñ
ÍëS¶Ÿi!Åœ‰DÈ·òÍWŠ»ÛÁŠJ—%ZÅ8Ò8åÑô@ƒ*ì‹Ò>*18=Á3x¨0>÷Âèëøıã¥>áô¸¤=~ºªS-¹ºĞ-Ù@^5óéK 1>¬ë³Ÿç”AŒXŠg6\ät¥åÚV"í	…¡†ÙC• ÀÜËï8µø ü›³P|ÍäÌ©P€6Àb.İ†Ñ.å”çq-†°±T{rJW{±yÚÍ|Gl€ÅÉ,–Ó$‹Én"Ï:Óù®*ÓD×kı8~ÿÕ0 øÃ¡ıÇÆ{{õõËg¸J æF£åsQİË*éƒÚsÅÕÕ»Ü<Z i^tšè°ü“…ì,·åæÔ|7`LxàØÇÓÿœ®rT†¿a/F…ê²­pm%ëÁh+ó[ôU¥øzÑ?K^*£@äY¶03mùŸPUâ'N—ÀºGÃ¿qğ´t@57|µš²NğJß¿"EÏáô×Bb³S„ÄãˆÏÆ1¬¸Ä4@Şù‰ñİsRãã”»=´ ôèî­ÌúÚVyL§®f»Ç¼Œ¾O¸ÂG ˜Ã†$\Ñ7~ò{Ó-°q¼ıÖ«Ã™lëV¶ïCCx7±ÛVÅ·ĞÊÎØ¦Î!X¸‹ì:x—†¢oG.pxÒ[)üŸø±òdğI‚ï˜»®4i²<í„M,àkß)*
º»áç_¨Ñ€ğşÒê\6íšbHŒ*¶­C#ñDú€;•x.ÄNáíJY9c¾¸¹EÈÛ¾ø¹9+æBŒàãıâ Ú	UJ]ùBï ¸ï3ßÒ©J»œna¨çušºiäKM?noø±0@Ç7â¬d¨ÄKHiòŞo¿¥È503xë¬İ<Å™¡ö›6œKŞÆ¿=ÒÃKË§³–ıÕ´ÄéıˆËcA`P£
?7<œy† ß÷ãÈW­uß¬º¡
\Tzÿú€"3,æ%¤ =ÓK¯™1Gn6Âl0m.çfÒı!É˜qÎ|®³ZCõ°D;.ªÿ^r¨9ò»¶„n¡P^à|ë%Ën’¾4{¼s	]¬u“Q]Â…¶æKºYÿvÀnYe)gµÚÙ¾»)6{MøµfrËª‘9Œl4lÓ6²æ&jƒ¥@9£f1A›Ûf­wß¶h‹ãú¨h9iÑÓg6ŒeŞ…ÎDÌ}?ß€K¬Şû¥a/Ö>Áö8cxÜğ›yNPrÔ`,¥©¶M©d¯AÃˆqˆ¶öúcõš…¸6Ç9Üù„é4÷§H*BïàÈŸv:X¦Áã•=w-¥ÊÚsDÀßÁz2¬È56MÄÃ+ùõì¡¡»rB½&ïaèGO°†eÅ£ï"ËœSü`Õf©DéçIÁ„È6¢I(DèŞ +Ss\Û–Îà·Ü;ûb¥UqmòšH^LsÉbòºèG›ÒŒ 5‚¦ÿœxß|JoƒN¸¯a7ºW£¨€:j…½™ùx¢#5d‘´çC^M×Û’?ÄŸ™¢Öf™…Š_s2¼ÊÖô'tänBf6kÜï`CË·ÔŠVJÛø	T¦Æ¯€oĞ_«+$t…[¡vD¾èêàÂ>BÄˆ—ßJ¬½®ÖA1‡‡ÌùDæ‚‚2{ˆOàÌ	ó:Õdvq¿X@aÑöù½1±ÂE© <»•ÛcÍ‰dİ²kâØ°õÒÜ‚È®E>ßDG·Ú>Ú[Ÿ73WCé	4Ob$²›Ÿf€ Ù(k2]µˆM^Ñ{y¶]Oâ¢µ;fK.vÖÖ1)Sğ­g¤æ{Bs)(;›ÃÀÇÓ^SŸ”°kq—rQG'j©ÊÚJItÜ©¬dÛ•ãåyMË
3~LÃZoÔ•ˆ¨•BUÍgXÇÇi
ü§gÓo~©ˆ"¹OX˜Ÿz‘ÛñëëìgòâGÎğÁÎÚQt@Ğ4z=23ÿÂ
Ôû¥–è½#$çp¸o«XÉ83ù	‹ÂMDÈ-}‚SmaôRX{¾®ØH`~Zü4€ÂCûß”íÁ>ô‹aDÇÒ:;íW95ÁÙâ’#H»”9ó¶ì,ˆüYäpˆÃpIÿ*ìÔÆĞâ¤FÃ›ı2mrvœè”m#lS	xÒ¹ÑšKrÎrØ	‡}äl´ƒÈ…†‹ÆçºÿëàxŒ	ô>#mbÃA/Â|çï¦¹H)ÚYíÕ'µÕÿ
ôUß£µÎáÛ,Št,<*Öî	ÕÂšT{¸PI‡íóEı/m…ğ•GÅôš¬ÈĞÈ´Iõgú.º–°7–¹à‡UšŒ_ŠÇ>™øwË&ÃÆ1kzÕ7`NË~íˆù²n„¿=eƒIìí\yx,`;qĞ­³$»v7“;a¤_ ×”Ûh£ù»h§ZÃ»ìê´
¨O¸‰|ŒI>Ú’ñp%Ö‹À¡¾Ò¥ûÆ†¿C˜hºÕ“UfpzæN‰­€ìM}9)~ªJ¿È–]÷Gtİvx$õLhBßç’L˜{(ên>à§sB-eÙß÷¯¥"I~>3?Æ {âoªÓ_Æ?ó-©u2Œ·¤^ÎÎ1ç`-ã¢×-Örê'çj)Â‚¤/öÕF‡¬Iß“Ò^msó,ç8Õ@äÖ£9!CyõqøüXKÂUµè\(¶›Áqè6Çx€š™r¥_ Å…şÄ~YŒ3¹KeÊÕZx+á¡×oQoÿNŞ=Cá×¡hnôwæğ\ {¨¨w=S@P~¹ß<>Í)`XdôÎFpûÍ!œ‡¨h¬ÉjàyeyºŸğXEá-î•>nÿ3†·Pw¥†»:²nç\k>‹xŠ²xá	¿ĞŸ-ğ;ò%›—ë%{ëåœÑi°¼Œ.‹<Ó¼¾-©8>,bĞ/\4}RkÙÏèc˜M˜}ZÃ:u›cçA*ĞÁÉü3¿‚êóÍ½"öÂÜxÙx;2™Ô3ŠÂ{fÿ´¼ZÁ'Å»©>Ów(„14>ÀÓ9ğk“$QS-L&ØD.:¡ÊO•l¾Î½º¿·`œ®N¬©5T½	Ã&7¬Ô3}¼¹¨½±|±eë-i{]©–û&6ºLN(Ó±+z£‡"qá@
LLßÚ7£ÆÒpõcúñğ& Ì6^Ø¦bk¶œ¹W±ÚÇîÉíÓ§üæékÁ?%³õëÃwT…ä<©qv¸Î%¼şÜºqT|rÑÂãÈ”6ÛÄé_úÒå#İyEã–·õ5ô›4ZZÙÕbàFùÅOjªtÊÊ+²p*än||¤‚ªwÅ\˜t£FÎŸ)äTš­¾&GÏÇB5¸êŒÇxkf†Ÿ·œ€sçÃ^ªj< ±ÈÌ”`5l8‰ÿ…áÊÖÓ/=I`Ê¬¸y-ó˜:ã+Ó£÷
nE­¢@êLF8è’î®ùÒ5N[İ«Æ‘{™SÄµÓxsÆ 2’ƒàşI
Y‚eŞ£lüv°è}1^Ö^MÇ3ˆ×™à —]ğjş³›»w?qÒ³ÕŒ[ëÜNå7*–¿¨†fÿ§t­.ÍË%*U¤d^O¥G ¾!2gì„ñ±ÊöÓùıè–I˜Ä²äígû;7!ŠŠmÛSq½¾â2ºZMv2[Ó¨2íÁİá47Ro£ì_—>Â8á€‚Õ¬CÊ–bKTnŒìüÿ”E‹Š¯° ¨ÿ€¦‘ƒÿ=Ôß s}ôŒß‹‰Rğ€¼F]g>o–K`­V™Kt‡ğ\0ÍÌ·:çîjv
õMØİw ĞØ¼¢–-ÑğIÌ™±! Â²ßÈÕMSa‚vpŠîíçäïä;'|öÁ‚ĞéŠ.¯èÀüÑ`M&Ùš
ìÿxbÅV ‡hñ®ÛfÖb!JÎ¹õ¬üîÃëø·"Û¦2ÂF˜Ä¡€úô\
Îü@[HZº:¡˜<fj]ÏøÁ«ëî	3S&èsá&1O¡¼
ÌÂõÔD*ñË»şoã5ìj(wêLf@³HyÆ‘ü²Ø±|î£õœ|Ë¨Û#´Ü­ÄÃAm5 Ş¸´!µç—áN{b~%ßpM&«]ËÍL‚‰v³ğüaD™iÜc`Tà÷Û¼5:ËR±r£”5eÇcó¶ßøİWlV÷ˆ Ïh”é¹c‚x2ohÄî Š#âG·Q²4¬§ú<¯½GÀÛè Ìà´1W…(¬Á–#áğ\+T%Ì­Qùoü^»A”Á©f‹Ÿ„î7£ÜZÅçxIåZ[4ÚEÎä†ÒL—¼acf¦Œ˜¹ğõO¡æï·ı¤•åı“étryÆ,÷s„¹Z9şFQ=ºf_"§×–ü=ß¸XöÌ'ÿB‰¨•Ú¥‚¡#ÈãÕJ<#ŒÇ²",™‚ş”<î'6¡vé"6Šè%åA~qj„ºÃ«öøÕ„ØûèkìzÅşõtÈ›’¸ˆ¥±„ĞKR;s"‰ì'Zuúz_ıÀÑ{­ÿ\ÜÛÍß©?o8r!»Á¨sTßJã˜BÚW_¨-½‡ŒdÒàÑJL²†°Â0”;yÈVNÊ]}É/¡?
¨aŠ^Îf™Oo;¾ ¥k9£ÎVùqwLÊ&xÆkb+fZd‚ùH+ƒ±zñ¶²lxØWlLƒsØ“”J‰ôÔÄå]a7`æm˜Êg›…LöDš'	ª»“Ëá@pÛgª»=ª¨¼nSÑ¬ÊkçÈÎ÷ÑùÄ5Ší(ß‚ıˆŠv>(ççEı¹·áH#Mù¬Yî¢9x\…®²e­B‹­“{‘óqz úWÊ=üÄI4^yûR×ur—œü‚:¢hx\sqÔkûê¿¼ŞıQˆ²ÁA-;Şu¾,X«úöŞõ¶5Y©œËO=»½Šü2ĞU,µÀÅU¾Ø'‚)Xg ¾vã¨¥<‹ŸVí-åÊ„ı´ò®Òˆ/]Š¹û5Ø1şı9â™[ÑçM#lÀ#™¹$5ª¯lXÈ÷&*l>1r"K/
(tä7ìM"PÚàøÍ®Õ@*ê(˜, àkVC /*è90zXIVkÖî¤Æuƒ­Ñè´šëK®TİjûI`* ”w?Ã.·}³`gZÆ£ Ep€–ÈLoóÁm¢S[ïæh>»j4	Àèğ t Ã øeT¤ÈaºÄ5hüíµñQg'b.çxÜ‘à‚% aà¿Õôş"ê#ÃÙè×ìwh8S?ºW.Lm+~Ì¬ğúÙ­Z æ[4o¾¶"iËÍ©¯¸ÜÂÛ«wß21¸×màmdÎí$X¾o>S+tam™Å«•ºŞPÎÅ¾ 7ğ¾(âj’']¢8ø´™ ¶ªDsCø»Á×›˜³JeË¥Jı3ì±’¾T˜Î7UóµY £‘Ìoˆn(ÔgñÜÖ	T|ÌäğG+¨:`ÔÅwIè  ¦ˆä	ï*®Un7[´£¢»K8ä?ë Ëæ¯­
ó†=Ö7@öşìÃn8ã>Ä‰sCòšƒÊ«.ì73So ©ˆçükŸDŸ	ÙRû›3/ïÉÿ°’ÑB–¢'i©G¯ì¨™>D-ğ8L©¼„|vÍN9öÅ1xõ‰Îz;8'[¡®TÊy~VZ?RNFmƒK8Z Ò*gNjT†×«ø;RÔ7®:w¯}{MKÑ~f®ò	ÛydN\ƒCí€,wb§İ4Ôâ"sBÙ-(ğñlßòàC–tJ \‹õĞS8ÖÖÊñc$tf3%ıÔ$üï…ñLKZ8^	oá¿²¢
§§ø¤%OiL·‹InöJñ¬|ú¸]™ÕVâ‘Ş®1L)Iä—q2p`«!a—ô!X¬¦sÅÕ&„hÖ}æç­ÅñyyàşÅÔÉ¨ü¸›½¤œª»kgqgb£hè;è0 †¶,ŒÕı]½„´KDì(•V>È’ÓÒ¨#~„	Ç˜?²×Ç¥ë¶ BÔà“Îe‹áÊíäx%oİ¥–IÄLCÁ|HÀÿÜk6Úi³ºl4ÊNÓ¯>ëôW€M6µ£Áèîø¸—‹æîßV÷9ÒØšÔZåÈ±YÊ¸ØıyÕÄ¶³§’2€-«"ö´ÖrÅ³‚Jù:0Ì§ÕnPÂ[h‹Í¤èYiméLíç£MJÏÊ!tÛpdpûí¶iÜ<]=ÁÉ¨‡Ø‰ß¯M;Á{/¢j '–íØc±î5Õz‚íİI\S‰™Á täØ¬6pÜ2ßøÕ	«ºò1úÃ`d‘o“ÿí+ò¨1Ö@µU•`æèöµ4Ê7%ô6/šy’„ç‚*¾İ2)!Ã”•Ù´HÑA,{P§‰!œ¹'U†Ë›‡vˆ=¸o}±İ\R—Ù‘!Š>ªpÒ†xBÇÌÎ¬~$B/Ø¿£ â¢h´¹£–^Ë¯ïæ1eˆ?h¬»òÛè©÷iJãj`±æê÷§ø3ª"¯%UXª“ô[şÒŸÿ’‹İÓ$AÍm¼x{¸s„»šÑw<•A˜T9W8‰â€ÔO¡ÖT6Ë§}Ñ ˆšo-;áºByÜ%Û°úB$/+>è;Õ¶±@ÍQC÷î:”ƒØ/µŸÊ,Æg=¥´ïÜZÄ|l'i-˜ƒQ?oc*,ÌD™Ÿõè÷w?7äñèöx,ñó ÷µi#Ò¶&´ŠÖ³Ú¸áŸ¹Éß¾ƒi}ÒMÓßwùò¶Y•*¨•b™e¯’zLÁ“bY?*¨\FÎyç¸íX«Yò^¬¥ĞgE$bši¯%4”yŸÿjúÌ…¶HºÅ$-úOTü’<£XŞDwñíTñóé»ê‡¨Ca…êÊ_@ø dM'Å½âÉw‚m¹ADC‰×*ŞŞ‹hkj?ım£ÒÑ¥\cßÃ¢ËàX$œùgÏ»Ç‹¹÷ùuµäh[¡ı±K”i7¸aÈœŠ™@Ÿ“¶\Ít"]m›sÎ´|ŸK‚ê¤«^”÷êoêj«1ÄğÉóƒö3jÙU(Ğa@[Dàû6ú³@cIçWïı’!ì¿ø“?}8s»8`¹ìyT@`QÛ]‡^ôLõ†OĞÒGV¬„ŞA3&®bÇÈm¤Zzò9‹šB§aóC*%®Ñô?„†”°ÄM¼Ÿt×‘ÒÁÿ¤ s  Æôln6²İŸÀ\BÅQÓ´®O|ßõrFE+wŒ£‘~ç>Ÿ¶T½©œ5‡„Å<'8_TÂm¹Œ]/òå´ƒr4Àº+’ß$ù›f/:*8$ñ¢‚¤>töÕ¼œÒ¢á±EFˆâ­•Øô39~—|ø.³wî<n`³¾¹ŸÌ˜²ïĞıä@v·ß¸02¹–&Ã-CÄœjC”¦ºˆVÕª¼ò8øĞˆ37Ş]ß®ÒhLĞnãÿojHˆËÏkîÎä%M%L'”e†N¸¡óŸõZòm>„_‡üŠ oJZÆ0İ‘i½ä3TóÀñ ·ıÒvùÁ[*Z$Ô Í&ù…bZõíşô1¹„La¿2|à1	ÖCŞvï	–7øÇÕµ¼ îİYRUˆ^,Qüxü‰°eõ:£“[U‚qTí¿çÃx÷uŒÊÒzqÚÒ,.H½Ã—¡xÑ {m¤™¿ĞØW±04»»	ÈÍôC=3êö4fd€Ş]G&4D¸{".(ƒÄAŸ ‚±Œ1SˆYÌáî×>ŒÜõhºÑkÙÉ€¼8ä*ŒóŞy9¤z(ÊÜr’›Àîj‹şãİ‚ñ•óñ¿8»Ns˜ÒC›ÑdÆ˜08_¼ˆ1ªëÛâ8 ÕO¾Û	Şócƒ¼L"ûØsğFÄ 4£“­ƒª|İdµUOB­RFDw|)=^ªÁ½¡íùVSöÛ¯÷“òƒ5no÷b©&Ìp}¡ßçûpƒç{
ZâduĞ¥ŒkoA*LñX¯œ5Ç¯yà‡ŸÙÊÿÜÁ¤t>æ‰ÛNİ«ñgBàM&+ƒU¿ÜƒApqB{„Hé•ØOBs5Ù^^Î&,Ç	ìj\çóU˜LZú ‡q)jâÉ‹óQ'Öƒ1äâ7M@8.dáA9JÜĞŞù©¼xDÜ PLØòP©g´ÑËrGÃ(vW ÆzÎäLÉ^®Ä¥3fkÜ±‚7ë7ğıÌP#Ÿ2ùğªóôpšQ”}µ%Š(Ğm¢à¿„…Úü¯?¬G]ÒkBşl
a¬ù6`–mÈa›{)±X3ò½¾c,àåFêyqCË²SéR9¥E¯üG{lÒITtù ¿µs~ëzYG1:÷«qëÁĞLÂ‰Î.ŸÚtœÔ¡ügr.Í$‰ÒWƒ‡ö%TAÀ_+ë rRÃ<Y¦é•Ë9¨&·¤İ#ßPàîÖOÀâú17‰çøh/©ûõÆ
 ?İ­cMc¹Ğ÷›ÆìhzgMÕákÀ5h&ü,ÃèÒœMœšÒbßV³° w‰dÍ1¬ å“¶ƒ>N¨Ï¼¿…˜$‰­8«¡íÛŠ"*fŸ[s H§Æ5Æ‹”!»ıĞŒ‡·ı’m;¦£'ŠŠ¢[‹ìn.ş–ü=~ã#L:À}ï‹Ø>µš™´#–Aª/uÑÅUÑÛ„ÍÈ{|™€©eê¼Í×u©$¥Æz°º$QÀ'’%Î]?hÃÛ£	úÁ#İş,ÁP_^IVZ0©)³&Lbx¿ÀMg2ZA¸aá¿ ÎÂsNÁd9á’£+˜fĞiúX@õqÙÔîaBí'‚ÒœZÿ÷mò•ÜNÛm&`‹/hÊ»wój;Qw7VFÈì9åcØï­Onı!ƒ-Öã–Z×GXÏB­…)b~Š¹ç<'1_‡ï?4H<,Â[y?ÒH}ñ¾U)¨=s ùMxó¾ÁCrÔ]¨ĞâÁh˜üB”˜÷5
ƒd ’2UÌf©¯@S¢ßÈ—è/Æx-_Ë{ğ?4hÖxİÎ4™¼¯uòèqšE|®› Œ9ıYMÑvı	÷Û8V"å˜¢d¬O¡iµjŞô„¯ì"³ÎLèã—ÖÇP<Öjjê›å¥¼;•QY÷úfm@:gÑ»ã"‘3%ò³\1ã	h‡Ó›¿”(™É\bº0_|„”pg
¥v¦vbùÕ€u_u†{7îrÚÿ:YÄ¹ÚR›=Šnµ¹Œ³ùT6ˆB»±ĞŞŞ•İ-¶xq3QÇvUs ©AJ\>†G+ò£~Š5®ŒÑÜÇ„ç›å¿×DTJ¤8÷+Ë°ôTK€nè)XúØ]çÖZâAÏ¹şw¸Ñ2“BBªËI:bé‚ıZf?ïê‚<y•<õcPóq?6¥û,2I,¬àæ·á¡ËûÁ½£ÚìfgÀ%rëË˜;Í´¾`³$ÙŞn©³²cşó3uÑbgÚe7¤kM¡Ä§Ë’Éu:÷çã%Åãì³Ûtú{ë¬ì5xg%uº?ıàè›îÕ5ö•O£5›RlaCÎ‡M‰2wém»^n‘ Ğ¿ ±²„¯ ‹yF›J}4Å¼…??_ï§)–}‚üˆŸ¶ÕFV?“á8¹¼DmŠ"ÌhœTìxÜò€ø,–W'Şá-Ş[Ç¼GHQâš—²,›bp.t¿°¶SêœÚéös¼t}ƒ%Š¹Ë_7TÛ„A[bš€^lZúã”õ,WT*^t—*<ºi¾÷(ÇÌƒWò\·]'MuEÚîùaİ<tr^w'hşª#¨.(¤ 1@×L^."§ñ–o;úÏ+œß¸ÍÌL{­
ñÕ~5T†Ç¸¥HÉ£cğš7l‰;S6ùÃÉïô9¾ı(ZºâPk¸ßÀïßê'˜±º¸7?Ûj7™]fÚ=¸¡ºÒÚPzÚ>›ˆÊ^*2=¬ì¤E:ö5:À}€)©+{:Ÿ¥ß‚Õªä ÀWŞvóg€Â”´0)Ë!shn`¤ä_kw–ğşL|‰Ó^MÛ$®±A<ŸÉ¡W4–¿ÁôıÏfLÙğ ;?t'èQÊâlVÂÀñr÷<IıòÑáN3¿ —gß‚¶ÂB¦Šõøg C5ÚvYuôE`JÈ#/£½s(g']¦Ô•#ÇÅ`µ;uÔİåİo¤˜c«„„ØíMM0©¢Õ~¹Ar¸`IÔ©Ö£ã{g—^òÕp½neëDh\'…¯I
Ìs©Û¨•ºY¸óŒ@?!üó¬ºô‡±µ}}$;<¯wi–©ÅŠØ91±øÃqë D«’ÜıÆ„ ”òËyb‰´ç<6e¡&á“…~%o"BÎ©Í(ü»š¾%²„u§Sˆ­©Â¨Ek8ê¼:åCC¿dsÄ,5D²é„
•¥Ú98¶¥Åi#± QòùM²ªï¬¦$G>x|vÉ§X™Ü0aÖ”‚—= œ `Îâ‘8ù¢6œÜ+£wÖ‚ÄİáêÌ¢ˆ?ı¤nù‹oàüWuHãBB™;|´^ğŠ§º©¡„G*¿kpÑHî5×m@â^öÿ“‰Dm­ª@™–˜Ûò¼#káòÛøòyÓ(6ñ	gÛq‹Èàˆ€6o,½œı&5;1¥ÒX…¬}D~{–üCã:†M‘†g«!»`åÜêo‡Œ	²¦£;j\ˆoÄŞÌwm—$*È—² ëŞ“=g£ÌU¹Mİ>˜UUw­²ÚA1~#%øÀCœonhÍqp’;'’6Æqác8ß
(…üY5•'Ë6…µ<ÒŸ8è85¦ÑZÅº’Å`ÄØ!Â}‡8®ĞÑ¦ÄÁ«İJUËï~çF(ö…ü÷é½¼Q}šœ(p@ûöÚ÷ÌtxÖË®åf A\ +ÅQ³3¦Õ$T‹ùy÷+11q÷n+iT]ÖÓ‰èSÕQ{
o_1}ËCÿ(GÕ»Ôòôé€•¬upŞnÕs¨œ`@@FYèÕ£Ç,1Dü+ÿ±¿úÚ?	&ÍNÀ¤}²" µë®t¼ù€øj¯»@Ôİj"øÔ‹¤½°Â§ÈÀÇ&¾$â‡OYœ6Œ/ +:+Œq=BEıÆæ¨İ®Ú?æmÒ/¼ÚÎ‚©]w?¾Á¬JøDˆlä±éóSH­H¼ÖˆÍE–©ÊÙ³¾ˆC¤»?E§]iõÆYæØÀ’Õ }ø{~À±¦ t(QgÅ…Æ)µúôÛaÎ?»ªMŠx1E}\îÅ†ÑBù1IÄ_µH¡ANÕLz©_C2šHÄ¯ßâDM…œMY®·E¡  Uš¤×VêÓÁâèÍá~áœ|—§Öñ˜¦BØb‰p1*UÃ0Ëæ¿Ëá'.ºH‘ˆ½{6¨’@‚š's0ïãõ'‡ƒo3ØŸ½Ó)j)Awm…bª;HîKÏ,¢g†„ã® U ¸˜g.Ú¤ù¯§Ì“MZLË½¯£¯bÚ¶¼[„÷DøOUO8·¡Gg¼Î8ãô€•»Yµ¤TvG²A°IÚÇ`½¤Ù¡
½\”ÚÚ/ôîê!nğO ßì>X^0º`ù:Eç@#D°Ñ÷ó‚—AÔ³ÿ¤ş¶¨ÍyÛ Hü5ÎE"¹.•¿·‘T#ÁùzZ>’©[İxŸt·§]ÏŞ÷yñê=÷rÑZ±»Y'Q	]MsDGôü	—fI[Y«’'³—;ñÚê¢D£3\
	'ÓPØ»õ˜—ÄŸÔí­Ìğ‰PÅUY„<äëÆ×Âé®F.Â‚Ö]¯PDŸ´¤rA3p†Á~Ù¹Ğ¨ï‚[ÓqÅB¢$ˆl-èVå
7îKì<AÈ'IüÒL‰ÆV¼3a`'6Û×øhÏó!µÎğÁ-ÈíkşÏLŸ«•˜•b¬ú,÷9QÑ#sZ™;¯–oÎõE-!±‹lÿ•äL$9¡P<c¾DÏ3$üåş×ïÖ˜l ¡Ööâe”¥iáÚJÚuñÒ±ß[›² 59ŞĞµ„ùı+H¾ç.JÑ4ˆnêt™A}–:²'Éè,(ÄYª4$ÿÌoï/”é·ØqG”­ñØÕBú¹,(´u¬¬‹ ÑkN•Üo    Ö»ï\â¶Ş‘ ¦®€ğ´?Qg±Ägû    YZ