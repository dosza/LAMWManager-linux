#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1495845105"
MD5="2b665ec78381ae937a01d8fc8b820f82"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20208"
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
	echo Date of packaging: Fri Dec  6 18:01:52 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿN°] ¼}•ÀJFœÄÿ.»á_jg\`È^Ú ø-‚z+8Eş8¢İàKDc¸œÑ¡uÂÿûVq’ÈèëLçrV)÷Ó¢m²Á.ÿIwnÈ®[)vÕšd£‰ê 1LV4YGĞ”ÿîƒ7Ì§E’WÖ“>KY…Í{~ ›ÕW›.¾2S@úŸÃ¢ì:7¾Š„5"*ğJ*İ²Ï‘ ‘º×1Kµ.÷jC—œbfLàÄÏ¬Æz|@áBjQ¸WãfÇ_5Äİ‰û’W©„¤ûÖC½ÿ0°Çª˜W@…˜Õ‰À\È¼—[¿¨ŒK´ì8vóT	(?k &Ex²Ôzêx¸‡o5·7h{só7ÒCTÇ#*‚±»q¯FEÅÄUš¨ıo®
Tp}!¤TVl_Š-GéTP¦¿°ûÒR³Üü<©¤¦zõÏlAütVˆÊ†	m“+9¡•`Yö8¬]½›]‹2ƒ"œıä ¤yƒ–8¢6¼ëıùq –ÿV"Ë•s¬N¼®g!„/€’ÍB Hœ@GšVVyÔ÷&8èxOy‘bt× pDŞñ2ÿK–mhcŸâ/5]lúK‘1®ğdõğ©xCúB0Ëjü s3Ì(ˆ

È»IÂŞ‡/µ‚½¤„×µ|°–‹L#Òtkz±¬x–HÉIdß–	5…~ÿ22f4°°ÿz–¼Ôv_m+%ßØûØØÔ 3£)¦ÄÈb\Àu®Ö7ÇK¼Ç*ç»ÿªê^¡¨ØğçÎëd  ÉU“³9<ç¸ÿ°Ò:½~	Ù·F6Œd˜;Š NûñµAÎ)¤Éğv5©®…sš—%N-GÔÊõúf¯¿{‰s!¯ONj ½y¤Àl	0KÖõ±oU.Ê¾¤ı[ãò&:kzú÷(éÚ‚®7eê†µ*ô7%V[Z‡/x×k_¡û]íbItş3)ë—Ï‘4AÁƒÔéY6©Å.”ŠgNŒEU6(àó¼ wÜhQ¹…Kë÷‘pf‚B>>)ÒîE|ïvJe	ŸbgŒY¹,¸	ğ"-¾ ­§ãÆòÁkæ÷O%™îaØëM¯/è¿f"x·)×1É®}.OĞNö¯-ËÔ€9ávïïB4õs­àx3œ,yß…°³Ue5ë:­ŞƒŠÏ"bÕ¹GEÊ2ìƒĞÕq8m²Ÿ™FæMÚHÔÉM^j±£ún‰j+êµ—VÜ9ÖÑ:OË|¿ş–<‘Õ0¶mcƒ ÀA>$ì)í²iÓnË¤Gdp£åó$ÎQfÊ …Ü‡¼{ÂJGW/¤l#å>H0½vı{ ä@>e¨|áà3ı»\ª§)ßâƒÙø-ãÑşªYÃe©tt÷€-3IÜa™ãñOÏé¬@ª˜r_wÌ2Œdê~Hğ÷µ{LÃéõ‡”ÀÆçñÊÄ|•Æ_º} MıŒ0ı.#á¨ø"Tëe~´Ø²_[nÅÉìüN»Q6,¤İ¶ƒ=”óÙcY ÚfŞ9ôšÚ¼€cÎ‘ä@Ë¨óºwQ_b–Y,wh|†Á%#+Á#eNĞ+:µ}ÑFÆÎÓ3„şïÖ§ºh˜í=P×PÆßWÉÀv°÷t•F‡Ÿ¶Xè‹dGx¼'¶á¨ƒûÊÒ´âÇw´w
ãzù“€–<Ô3o—e ™P˜ìÉë\NÈ_’‘ôİûl[æäşù·zP
¬$–ËZ×>ØªS2ÎvCâ*}¾nªi¿½Ô€§ØÃÏ¾ró­ SÀÖìä‹ì¨ş;ƒ½¡cü4ñŠ&ÿªşçz_É-b×5“¯Öæ3¢‰9A®øşwÅÓ°³µğãï@3ÅäØ†2şëÓÍ’$u´§Åhï!Ç«/XöoY	4ò<ú	İÉÏLpÛb…mº÷Êã¡şÉUığZpÙ…µëoeõFÊW®ÉÊBí!™p_Šû¡>–L…±©ŠFBIÚ…{Á™îš§‰è^WšG¶?Õ¹rØDnNao•4‹¤¨¿÷Ò~>wó$'Š˜¼\ØiK¢…w…X‡“®è5šÜ~m{Œ£_……?hB¼%3\-‘]ØLÜ‰ôÒ(#ãJqúq–˜‘´4}£§¢$±¢Öå3ŠrÀ“rRë±ñ‹PS†·¨m?r‡ù<hF—ürF¶§Üıè”5`m˜0Ÿ“º¼Ò/í›n_ä®*Ş`9”HábbôXôÑÿ¬ºÂØqÂBK-ôzi9om˜º bÃÇ'ùç@’¾¥¬ñNK»~=©Ÿ,â¼ÏƒTËÂŒİ(ŠêÉ§–Ä ¹úà=°Ì-*Lô­ûòõœ‚¤ò™^`Ôi2Ui¾èS‘‚åNÓ=yşœÂó›xFÇÙèÒã±¿v\{se#†+dşDñü7N÷Hq=˜É%eõg+“ª¼{nR9ÎörõæÁF¬qÛ\!¶'h–î-ØÅ€ïVkíÈ¶Ot[¦Qi‘4ĞÈwI÷õÎÚNa˜H‰ÕÃz‡ìĞYlë3º·?"2ö›4ÁL-VFi³˜ı¢/‰•¢¤g›ÜÊEœÌ©Ã0½‘6ç€jÁ@áD„6ıvPËjèöÎS»×ÑÿI1Ç ·37úŠƒ3rk’Ô§+¤U±¹µæxÜXç…NÃ,H,;ä¯N‘[>ìKœŒÿ¶VÕO6<İUÆ°¼¡?ËíEñ @MÈÃdUõ­”^AşÏêÅX‰¦¬D.°FUm:]-Q„ZHoÚÑO•Qå¼\¢¾fú¨nE†â{}•Ëpƒèjµ>Ö›ğ„½«nuÂc'z*nİiÇª.æŸ•#‰ÎÄèìØx¯C¢c‹—‹q·:Ø	zM9`Ä¯z6Ó¦ñ¾ñäo¥×ÎwB’y×‚Ó»œOHŸ“:.‹1É‘ø–Ôà˜€Ò$ì£“Ù¢(ìÇgiÆ¹ĞyĞ ÎepJOÚ4dhË£ú8×°?æÛãÿ'Y‹KìYÁrIÊşÖÿhGü²õXŸs¼¾Ò9@­TGq’)d
NsaUP4m®øw¢J4šyNéÏ@;†˜‹²”ÄûB#e4á¶Ø{„dX¤¢‰®’= ‘âÄù¥Ôÿ,á³ÂxIß‰
»TïÎ‡|?Œıª‡€„ÙŠ1päî’Ø6ÖÓ`¸¡ËYÑ=‹îeëŞs€£ïÈ*±ÀœE<ù^ô—/ú]ïö„À»øüØĞÀ¥'æÔ[¤ªº[Í«·ğ-Ö2éôiÙ™“Øh0¬9™…‚YøK4 €°6j!ÛÕšµş_ €KÁ¾–ÍW”? ë]¢ç=AxŞÇsâI7^ AË“T/O§ M åÿåcY„2‘sÃN&:8¼!†§&ƒßªµDv/ñ)Iüüí¼(‰Ä<59ïz]"Ğ6x î!!â[uÿÀW}S@Z·®¡ğFbúÔUÄxgj_QîmhHÊ$PWÀdcˆƒá€®
(Cá<Ì„Â¶Š—kË9µ{ñ;]*ÿíå=èì¯3wòEa$‰l˜¸·‡GÁœºí'5üüŸûhËèI¸/rIÕeÁŞMÄ¥lk^QĞ-S)£VÈ, ÙÅ‡êámB0R×ÿ²UÎC…	8]Ç?ˆlcè¼3y;{Ø‘$ı¦&¨ÆÒËæõ/X·áëõç7€'Ü w¾ûû•Ÿ£¥b†šËªG…%ÊQŸK”nŒ°4Î*ù5/'„©P	á­Ú”ÂÉˆ8ÚTØ²òÎ;>ğfÈ9¾k®şlÃó4´ã(",lM4ÿ–Â˜¦ECi”oE^—ò¥e«üa¢¨ğã 0+†°ÀQ,Ó‰³OVÜ\ âÑÛ2Ò+Ø™ü¼¼çËÎ0¯—V>T4³2A‚¡êú–¤Ôßú¢™9‰èëıÿ,b,VÂ†¬ı½W9&éèo¦>ûÍøó‘ß\ZI}"ÄkröŸAØÑwÍ‘‹UÖŸ#ıÅİšà±¥wMŠˆ¿{Û_oh²—e¼|‚Ø]¥æ65S‚Q²AD>l`.<2ŸïÀ{Æ7_aõÍ9ÿa”/ 7%¨J|şëÛÜ[!)ü|îÛò´	1[·³àÃPşÒãÀdë-cÊ¦¤P’!Š%ºüÄ)Î³º…—nÄJñéüÕ°£‡#û¯%ÈMãØhàC5Ñ’U¸Ÿ)âÁGëóG ãUÅÎş‹°Ò= üÕz-
ªïËOª/Rõè-ŠBÎrÒ[XFæÔE”qèıY}{ÏÒI‰Ğ™"pfLt­uFt-§X1~‰ù’öP7ŸuáôPÉB¤vpÅ2 Õb›AU=¹?Ëô@s‹çyƒÛğ+u­ÚLX„TJ5ŠîóyÙ§=u:•2„ç2Üt°Éü›/pÄ¯Ñ.góşm±ØÇªåbdüì,‘˜iìk/Ï*A©³vs?*UEäŠØù5‚ïšLüà‘ü¾ÖÂ~ºØbo]’å„Hv5Ş±Ü€4“ÃŒw[,ŞgY"•1	ËxşhŒÓòŞ®}N8APô¦ıÜG»cîÆ,+±Â“‡¯nïo+¾G£ÂÇ˜Ó¼ka›>’«´,ábá .6Y*—6\s¥úãœªğ¾¯ÊDP9y>ó®‘{¬æêÊÀŒAv­Ô÷­ô:»ØäéØ„ PÛJ¸P¥Jéô%EÒqÉ9ôíˆ·F(¹?G¦ÔBß™	×é2Â•}«1´üûğ¿õøğ½q*Lüuú=ïårtKÍW¤jMÑ°’–§0î´¶!™/õáÂÉ˜”7ì ½Â0f*n ¸tÆ`8!èyD+ö†i3¶ñ<?«–uE«íS¯?Ø_àU.Á¾|ÖOc»S{¤¶ËJP_àEµ*™m„Wğ1›MpÊü·=«ÇtŒıhçøşc
½¤€ÏšÚd;ÎV†¹Ì¥’i“Wo»®N­À“À‚Y.¤]%xzËÈO¼Sô¿›^ :ÈeòïéZø±-ùœ.×¹uö«ı?çô‰ÏP¤|ÖÜ¿¯²=ä°³8S8ĞL' ı#İ½6œAG›–ğYĞf- vÆ˜/ÌõÂ¿ÃK©í—–--c#§=(4šµ¬‘¨£4a3'@'á—©]ïbÌgnNá‘fèù¨ÁRg³Äï”ÅtÍN ¾úéQÏPî&M¢F_TÿÃmŠzøfrt£ôÜÚôå·šª³L§¤·4€é¯qâbëq5»ónüı¶ß¹­’6ğÙJw™¢ï€Š4ğ1$f%ZŒ´5p÷†2æˆ^w“P4†aZ›İ¥ç›»ÑÀÓy}vX›)û¢Ê2™ øzÀßß›Ñì40šè7VˆbêÆ7BŸèÜ7æ(¬XÁ×l<ÆúyZÙV ‡jêä|ALP°³WT²ô$Nn2ãaÊX•)x95VŸ«4ù ÿ;–Êhº‘ıcÌÖ©lï¥ù®:õèËnÔR¤ÖEı®dpÁeÇçTã@^õî¾küÖÒG)ğX(à&'#ß³‡vyğäKƒ$I‰ì½ãl{`}¿—-#·EŠTê\ù»éwğümõlª–mE'(:¢?¤`î„kşG½ˆ„F’JzÏpÒÕ]éBşâ]¹f®y£Éı·¶ß< ;ëÎÁ¿@	¼¼©djU]È~9äVŸ·ÕûƒÍ{¼¨·¨!8=T'ğ3Ú”ÓuÇ¹·+øí½P(-ùûaüB2ë¥eî;2ÍCçíØB¤'tš–z÷ÅòŠhkRÄØëtójÙ÷÷
?ÄSe5ÍF„|(QUõÒ‚µZ©Sµäâ—ÓN3íwÄÛ&<ôÏË™„¹ª,AÜ¤YŞôã8Y÷T7s½‹ƒ¸Ú~¼7]g¥jYÁîË=w©öşò+F»3×-³}zÓµfäÍÖx’:¼%„x½ àˆ¯œ8¢¤ë¹½QCu#¥×Øú—oµS¨E~åÓã”09ˆ0CÁˆõ´¢ÀÀz²V¿ÏwÊ±•X—hÒ£`¦C!t–Èwô÷©X÷ö×t0&yn“Ã`ûŸ·8ŸŒî±#
v|»Éú‰	—NN1˜DµFn¤ë¢‹úV­UÊùÃ}Õõ&'|i/_¡ ’‹ivÊ±Ó-SN^1Ä&Ôı’Ò¹®d@:=Ë#6SP	ô„%b­™‡\âù¨«/·ôbÇZªÌñÕ‰Şj)®}Óà>JrÅ—oÇJÁ·4g¢ò¤ú’'È6KUG©Ã¥×-TÖ¦_BïËaóY¶³œªÊ#ßAç€²œ_SdÈ‘’GÃ$ÕPå,è>dó}–Û@ê<=n<}[Ñ+–×Ÿ7½BìûJ8ş0ÿB«áØÃ?ä¤iFæÑÛJ’w˜¦]b|´ßXÙá|ê®¨*hñ¹…›Ósš]p'ÚŒÁç&q	\JğSIOø¥&6Ø6Íj„9ôÙC#Uv|i·"
ÀÂ7>İ£ï….bÅ^Ásà3w“×äİ¢®;£›U—bòã)ú¿õÜÖ<Ù.@ä,U˜´ŠÉ±Ã	ûuãıòİ‚Ä€\§÷ƒ>Ø/@Ş‡qŸEŒ†Ñ)/šf´
1Nq”÷¹“İëôã˜· Ùe¹äm›5—áifÈâ!ƒó5ƒ'¤èêI¸ûBÙúhüÎtŒ\Ê…KöÌ
ÀK‰ü?~»´5XşÛ JT¯,H¹_	¬+b(w³‡æ|ù] ±De;3fu/Ä'«ÏÂ4Â¡10¿2)=‹ÉÀƒ×µÓbª¸€AÔñ¥ Rı“Ò½T/A¨}Ã…2ÅByµB¦àVy‡²káî
OGüyÈKˆ«ì#?>ñõ‡ªË­Ac“êö¼†LÕYäW³Jo|x,qÓ8;ÀëìĞ<ÈÑ|ÆÑ¬î·o	Á¼ÒVÍ©0,Ôô;%$^uÍÏ‹ÈZcïÔ¥Á®©Ço§sI~MÄlÂâe jc1Ÿõ-ó|´ısülLZÕ…‘Y‹5ü¹¼)/ æµgÿ÷ ¹ZÆ!B¿DYm-½×ãÔoÒˆ^W›U4< zO6ÛÔºÉ´;_Ûe†pK5¥cşİ\‘]Öàc#r»&ä\o¤×ñ‰Ï£!P˜ÀP×>ÉIr¶öNzKÅ¹çÒmX°5?=ÁF´©èF±â±G£¶µ“'™»fyyĞ¾¹Ë«O¾ØÆÂj‡k8Xò[Š„ñ}ƒŒT«5®Ç®³Ç^ÖZ¡ñúŸºkóğärçT8iãĞ*âœõ‚“æ%i;iâK< U<TĞ5¿'.O5¡²HÛ,‘ÂŠv7 ¾f§·ç‰|Ö¬Âã–6úik^T9zS‚H¡,ZÊ’ÁXø”µJ=¤Á© ÈÃ3[ªÂ¹<†Gò™9èz®Å3æpøS:°sñîé*\§4êÈêÄcB«‚”T*ğÛİ¿·Ñp·Ç5’ÏFıŸ7x:„v±ìv«¢d=»‚¸ô ­€›óãÉÃÍáq]Uô,ŠÀU@	$OHräZ±¥ §¾M#TéşŸÙÆl'ÑÂÕk)O/§N—Ë¯kÕ,¼óıúW£ûÆŠİ£&$Üß4Áä¦¶Š‚}’Ğìäğöó@;ô²İ¦-ªŒÑ7Ã|SÙ˜Ån¬@º9İÌL8ö&³`¤ËWŠ™(Z„êäÚÅ†"0,ªœ§³kfŠX¤”İ‹µï!p_}1 gt¥¥DùëÂ ˆkHş4K áqİ´‚ì×‹.Ş_!Œ«£ŒÇİKiã:?ib©{¿I1§„ æBs(Ó¬ùP³Û3Ö²O†¨‡ÂÀîJ*Î´¤µ³ÂØŞwX»N½
‰eèÚrZ¸¹ƒ‚İıx"4‚él„efuÜL®h„\b1ão{NS´î>^°üû„~1"ƒšĞu!^Ş	(İ½‡ü¶¸¶³Ú'æxw¶u•Şpë,ÈoGï°}Eymc¢A!³Š:eŒ[R¿g€
À~}û·Ôé
PğSd‰¡Ì_·™……5CÈ'=A[ÒÇï_á›äš?íÃˆ¿*Wo{/rôıc-	Å]×YÜ÷9*H?’zº7©¤wµ36fz=éï÷©•ÍFG`êÒ=önC¥6Vì õW±è‰zM|‡2š³¶{ë¡¸ú%.2¬gàø¶ÛıŠ©+Á‰F¼"˜
í‚
¬d"’ú>ÇPD?0Ù›·«îÊ0ÒóıqUlP!ç#Oky&5mñlPÖ¢„<ë<†uÖé74Ó± wæwVIªtçŞ5æÛŞ!)¨¡15UR˜‰\ó(ÒßKõãR¨íãí&İÿ\Ñï}S‹öÕ4):«èÆl+ïYù¬1¡xš7måLÂ¯V~çM~öTOCæ€[İzÿx.ÜúûK¸¥s©öÑÄlØäĞMµñßƒİ"·¤Ãùà]ÓÊ`EfŞIˆM°Ş3¹HçbNºKõ¦	·ï¾j*ğòìHšßÉT^ä^îC\l}[ €ŸÊ•ÃtrLÀ1sûK…·«Ÿf–E˜ƒp‰åo= ­1‹B0{¬†˜éÎäÊ,huŸ1¨óaØƒÜ6ŠAÙö 7>o²ÂVo¯‡ë"sqŒêË( @*æQKU²y1çÇ’ı5K|ƒ–HÛ¸(ª\ö—{÷‰4GG¼?x°…ı
ßN ªŞ«›XdÖûG¶¥¶cÏ¡ó—Õ$ÎË^êImw¶˜6”ÄFşkõ´Vx«0$º¦¦ U¸ÛQT]F.úğæQ#½K+Àä«*¸ü¢jÔDœÁ…B°ò[¾s3¦“g:­–ª•ÒVş±—á8wäÊf±°Öõ;€qrï×·ŞvûÏ}×Àz¯cRÂÀŠ|¢^İÕ}ƒD@÷IJqšIRGFjÁbïİĞP²oª˜Í3-Ó[,®Ç{Qÿ;8‹Ï$„‘}"ğÒø°ô:t×ìŞãùİÁ(°o†r~F‚ôÕšö!¶²óFo;Ãøµü÷Ñƒ®WU/špòP ÉDÊmá²ß!÷ŒÚ³x(\0C™
q¹ß’.ÁDiàÃçO€ÛƒN[[×\xgh¡¿ó*-cğĞQ	Ñ?b%êØDßafÆ•»—äo2ŸxâÜËošœ^CÏˆéµiê‰+”¦7(­ Í¿Áû­~"3%ar‘	—µz3²¸½Rğ\ÒÖ9.nb¢Öİ@,\†Õ7Ïï£ú4|£Ã7+Õ (Ÿ< ™k¦éë’ŸM@ŠÏ6)«Á»ùƒÓõ‰tı»È…/CX¢hÇQ³!‘oEhDdÁìŸ·kşmI‰ã6(µ™Ç¯¦§òé%TüèÅ*(Á‚Û¿Ë™Ü.-õ…5‰ ´xa?£‘æàÚ:»ßÙİë!Á•¢|áü¹€}MTÉ2Òqâ·Àæ¥úEÖè?¨"Èà°÷×wÄµÁYm}w.¬q=øõOÜòûğœ#S˜OÇˆMÜ9¤@z'q}Èo…|…_ı@
”»¹Šï¶¸»a—¤¸Æ›÷Ì[†°9rb¹vqäÛ<lìeºÔ	s¶ï×ùlÖB6øáŸî¨uN…%¸iSÓÉ¡/¤ì6Hü^†}¥Šœß¤Bêı¸z¯y MEr‡}„€õ³|pn5¡…5ªv	Ñ…(Êovk=•Lù\M–ì&A®Ä=Daî.L×Ÿ•&—`P†+Íöƒì
È(`G°ôr’¬disÄ}¦y^Ê¹zÍº{ÇwWÓSZ[­g(Œ&‹üE³^]Î¥Òğ–íÀ¨uË÷-!Ğ· ÿm.ŞÙ²QDT¾4ó‹z.Æ1RôÃ™7Š?Ú–¨#@5%`3'Á
M[g¯ªÄÜ-,-.NË^E Ü$B•„BáÍ)å10VÂ×‚£œĞË«ûÇóˆñ«œ!wèvFÍeJ^z#%ğNÄ`½{¡–ó÷¥öÆ•…1‘X¿íq§”;âıÜ5@§¯ó z÷DÅà@ªccı Ä¨+74q4½wOOÍUVX™-{	©ÊÕrÅo8i…%hŞÕ<kG««û¯#ÿfÄ;†7]™œÜŞğW¯îMë5‘À+XD’áŸ§^”„oı@/¥0s¸”ƒ±F4È6eDğ~ö®tšUş ˆ;ò:(°=€'>¾ÊÀÌWJ²KØƒ;Nµrî(æç‘PªîPƒ]p„r²ƒÈ–ïxŞQî;yÏÑw––İ„µÃÄÎŒµ]oldekoÃ©Ÿ¯AŞD›İJ:`k"ˆ­ê°òÜönû|S$ºfËèàW Şœ÷¢…aV¼½ŞÃÁ<L}­ş# ¼®öœÄ…¸›¢ÏNˆVƒT”t_×:¯Şë2=âğÑG~¿Ôœ–šÔ+ä¸-’© ğÔ7ËÊÉ‡Ã¤“:ä¥
ˆ.İ2„f–ëñsõ³L5RNàŸ6ÜğÖ6¤4Ü¢jäC“åœ–‡ÕÖ‡ŒªTã(v0:c€Ş	%™ÈÉ0I‘ÆMQc:|xH‹’+ÁÃşŒ•òY¦%ÔàGôU²e+¹\ÎêöàZ•Á;ª`$ğcöÉ´8ÑWyqÓÖ¸ñ¦½$?ƒìôÁ‹Ø­XâÃ\Ç¥s­¬ÉÄ–ãƒø
<Å?:ÅWvœÌ³ oaî£ÿ@È*Hà!6OÕçôÁ•xşà'ñ¬¼úçĞ}¿ïàÿıP„¡ëû»ÙØQMP€Òù’¢¤7j°n#Púo$‘£èœ¾ÑŒolôô ;T)™	’AÑéÙÔË”fÜ/ÕIB-N†–™9¹b.fœŒï=f6nCŒİàó|ªu¨#P¤G·Í=æ€NãÇç’-2İ¥°¿sjåà8‚Äiøc¨†K-´¸ÔÏ5U'~íÜÎà-°%Bıpƒ¸JïÑÖ$U¾È“^Ğƒ8ª’—m"	Ì\ôÈœù>ö|"â!\|×[Ö§s›ü z&Ëb†LF]Á¿wúfj{HªüôJ¶	Î¬àĞ#®‹Üïs]pïû¯ŒxÚ×Kzêì¿À`VEgp4¯è|æ¢´ƒè)2¬8Qµîê…I¹§–rì˜Ó(¢^LÌ¢¢teÕÙrâj±ÆÃk‘Éö8zuGöû‘¢•ì?Šûğ¹18‚3¸6şä®ö\×iò"4õÆ<Ø(¨hZm>ªÒüq½G‰Ä,TÄCˆå,\‡.Ú?õıGs+¤[ÍE9}p+Úãß}õÏoc~%iÜ¥„gSïó6™"Ìƒ/ ÍÎ	æªÔûÿ0Íé©Ãå±ó„Ò6U|#û?ˆv;g¯9<Ìªß›#n×ZÂoB‰W±“T^Æ
ª	Ê­å]~F‰!&¿ÏAx È*}-^Ú+rfÑbl¤oV#„%ÿcæ©Àiı¾Bd}<K<å¹ †SQ0gìŸ¼n¡U@şq!»“êîK=~èÜ‘e»Ô¤ÔrÉ·óªÇø™/Ë-¦bøMIÀN¡üüğ±9ŞĞÕÒ&Èá·:\ˆxlS-İ3yĞĞ‰q‘	áVL~4àÎ'cÌnŠ‘Åšğ‘şêÊ2¦qµt×±%s¿ÆmÙ÷[ÈÅêßJ*úF¯ş3h~ö•Ğã %D.¹_êúy>Şò ÂBMùtB}ô@£@ïeú§B{²¥ÿ²|Q^Ì¡7xyS¼-±jèêÍĞ$„îj8²À}Gº	ª†AÒ)û ƒzÜ•^Ru=x‰’)¶ŞªŠÑÑßH˜ŸŠ@åaõ=&F÷DûØ)txrşùÓ1øZFê Ú8ò<İm€ÔXm1üö’4%œ”K³ú4w¨QJ«D8vhc©ùlåËL“{ãjM}dÆü¸Ü‚sÜrÑÖc§A#&éŸäÓnîUwˆ”@°ôÄAÆ™Ñ¯İzë‹/f€
·s¾ÃJ»2º4—³­Å÷¨aòèhu1ù/¤r2×î®:®v@7Vûÿ‹êJ‰úè%Ò>^ ü¾b=âĞXKÕ6Ã‡Š)5»êì˜ÛE<@gØ‚ÓWÔ8³É$»uñ~á?Qcñ@¯RU +¬Ôb=í}”g&Ñ%M“¹Dœ›„ÄÌQ]VZ’8‘16YƒY&gùì¿>B¤+¤Íï{øipr–çT Ñ¿”[¤p˜¡j¬GŞ,Uk¶¹a‘Hy×`lpŸú˜ß/%-shß{7íKvˆ6gQá#ápÚ#½Ü¤:H`İ´ëö18phÊ Şe^ ÁşĞ$oY
Ûm0H]­ßÏ@ŞxéæC•ºáÖ>ú‘J3 Í®ÏÆHïwy;T®š©ÈĞ¶ "´z®>\ª"l¶¯ç½FCĞQÂç?³á›áŸæ\T!¤4ğiöÔ£°Š7yÏLWÜFMµ_‘ù
Ğ“rIú…ä£É¨G[½¾}3EÆíXX"Ü	µ(&rè`%+:1ªÏÄúÌ"›ŠªÒĞ?&C•ĞÒŠœ4»•ê ŒËÜû*ÖN¢°€ÍüƒÅ…ê1oà„ëí@"©Ó¯ğHhõîÀ%œa&e{Â¹Ö™ïè‘ç…ˆ›Dµ8E÷]á*'ı¿¾€²s¾upIàËµ¦=æ;f¹ÓV&“â«=Ï|>{Àj+[¤½Ir@x©ğÛ{Adíªí*’'A60RJ^:êP=ûBïjXÊ\X³õÌRD)Œ~ÏÇİze­Ñ±ßÊoæ„fÇ”`†À³÷S¡§»şñš«§1ÙÒ8¤WÓAÚ«Vîé„AüS3WÃ]Œä&tqïPew/-`¢îÜkßÍù¨İh¼½V¸e0n®¡¬`¿ØÈŞÑ~. p›ÊÌ£Îœ&»Obø9ƒ•óvÜãI¹Á2lş÷‡lœ›^_I×Ìw×óãÁ•öŞDÏ,áºëj-&™6ÚÚ¼zµÉÁ£–ĞÍ/A-A¼c×Os:oì+ÓšĞ6ŠáNŠ+W[Lş¹ş³Pwş9 jd"mFw¤ˆ Æ+AsŞsÜnÇ»U²7%æ&èôè£²3¦ÖKJ¹Z¸Úíyî…yìğ…R·)1ƒ'Š‡÷nŞ¼o‡~M9K’ŠËÿ·ôc»\ÈY«Sp^‚c«—~1©ëÀÙbL<$òqç™<Üš¿÷“o}ƒ\âv€\Ğ=7jùrÉï¬Ç˜$Q EhÚr3b Í(¿Ê]j,Ó.Xæïzv>I_mÊ‰ì†pÂ~6ÄÉŒ:ĞÅãB:„ÿ$í İÂ~6RÇ|İÖÌÊ O¬Îlüéƒğ[ñúéµÚÀ`ËB©ç&p5p(œÑ”ŸaşÔ€
0‰6Q.‘
9°âÜ¶‚ïÇkö¸ŠSÿğRÔòx¹Š¯ËĞ¨jÑ‡&°6Ã6,v^}Ôywò¶j&Ô½›r=[n0èòDÑ5'¡¼t!\H¨›â¼ß˜Lñh…aÏÏ‹¡ƒ
Ğ¼ùÔÌïH+±¤N!•¢DÄ`Û¦aÖdHì²X9\µ½<‚ü ç ÊQ]+çD6C“X×ñë‹§ƒùŸİ9ùrÚ`ØÚ~q¼Ò£Àù~~^‡;éÇ ¡Ë§MP½É„ƒ8ÒFÅ£V’bËåÇ {toÑé^÷ß¾¨AqÉÿ¬bíÚi°yÇ¡h ¶@]òc•emí¿ç›F“QšæRªcOt¸ÂûïSÉˆYeü¤j]ÕÌušQ‡µ˜‡º¸õ~Iú¿‚&ïíÔ¯©ëä´nQ[§i¤¬joòáHÎö¡çË±ÎW„ÒfŸW—úœUÚfˆıÀêPIg`Fe¾ ‡Y¯&ıßìÍ@ÎÓì ŞKSRÎ6WP2˜eì'WaŞR’yØ\,Ã Ô/‚`ã¯»Í®—ú1´e·ÑËĞÎe+"R3ÕœxD Gaû9V;ó²¡AK‹~¡…ç!2{*ğè©$Î$Õxëîó×`®Í4¬ àö-Ëª4c÷!Mlz'ÊNÚŸøî~n¹OÅ@ã¼ßvRŒUZ"W‰ê-TõØQ–Y~};¹ÔÜœ>©fJ&ŸLû«ßO´+\C!¦K×ÎF/f¬X¾x,OÚvN¸V%”%DFËØ4‡+Ûò÷bOï¤…¥à vÚø“úv2`½^TdiˆìŒğ´ Ó”?Š“[j]‚ˆì¬™M:^Hv“Ğ‚éü¿`¯î9Vz#vÙ÷¶7&4§DP%õ}ğq#oì­“¶9Ùd=GÃšoã«éÍ(UÌC_6–ú‰ÄFuìGïÖ}§cXJ¦™£_ÛùÍNw´2#Š VÛŒG›Ë‹`ã6Ğrúò¶&­1éÌ·FŸj\²“{~–Òy‰7§Ït¨ÿoŸ1_îúÖš&ì{wGÁeH´±›Ş^G‘®ê©$”g±È †1}ö{0Ê…p*ÿÔ´ìmö™sZ=U9şçTùâíí_&CÕú¸Û‡÷x,ıÚ2qŒôØ¡\ïÃÂG:ÊUqXëëÚ%ùëÀ3¹çbm˜…Ç	å4†	N%‰6ñ«Ì­K-ğ=ƒCx¥€ãO«gÜ÷¨†á_m—Ã“Ÿ	öNsÌıè…q<weò”IUY+7©¡Oe Ì)ß'±1D‰:”³£¹`û!oãøÕ|SRşÛày+á\rCB ¶m°y_ê»ôÄ¿~ êÿHà-º )BhÉŒ1æzâÇº00Š¢Zfa(ÆhÖ–è¦-Zs{hĞÍT3«~cÚ„µ-.£Ñúoa}·°¾Õ ãª25Ø_{ªpx^ö'ÑOœHÜ(£İ?ùÊ:¨»y/[Â^-G)1ÇÌE	J‚oëÆ,›¾yšRaëÁr(äÅÛÈ‰±«/Ü—BBÑbO•@¬*ÛvOÕ½Êøá_X¸ÖO’`ú$Z÷„œƒ1nVÖÛv/CrÙágGXC½ØIUG1NåÀ« ³|’k{ˆ¾†hÜúˆ¿"Œ7q±ûÆÀ¢ØFŞÿf€Šæ½UFØ#~=%¢’ƒHB†Xæ¨ÀÊàßšÓS8Ól‚g¼g~Fúö*[òÿ …?¾°Iˆ_Ñ¦dûù‡¡‹d€>~8ºØ`’¨ÏpyÒìÿÖwuºJ6,:É÷pd‡&½`‰ÄŠÌŠ°ìí±ß÷i»Áîâ
£:7«‰,”>[EhæøØ1ÃaädÖ-‰{Jı™†¨Scfö§ìã¢t3Êo•Ön¶Ë9RÄ²óÄkºÑ¥E™=öğ+€£Vu#2®›—Ä£Ó½q.Ò'ïŞà¼ïÆZış3›sßÖpõ:
õ4òÁ	ùC`ŞéC4éS\®Ù‰r=ÓÏrñ®LŒÇİ*é$êK¾¡¼ä"Ï€QÂH¼÷Œõ­üËu«¯îŸs}È­›{î<‹…¶¦1ŞAÄJßN1€}r íLüÊdîÉÓu*ôgvÍæ1-ğ9ÍŠ¯F·İä½…}öÏÜm„ªåß|i¿*XI´Åÿd¬İëK}@ëÛI­¢biznéÍªñĞãJÉıGfL´nHª­hñ=<PæPäÈJ²³`ŸÄ^½=5¸OÖfl‰2V–‹¶ç²õÍ­ò6€|>É[}zé‰hö¿F¶#)\Êi«è‰Q}åÈõw0¡«˜—+Ü<€‘çŒİŸ–?Ş‹u ÇAjDã-Ív{$Ó&JK $ñhñÁ±-;wÂí=Û—‘JÜ“0Øé…İ,šYB-c¾sHÍšŞeRN\.9­»‹ƒ°ãÑóÛç£±çr€iïÒf¦ú=ëçTÒC-´ùé#@¡êF|…#"åV©|lÙÜMR7«²ÂŞVmégOF`Äuò¢Ï4ZÊ”4anPµ‡Ú^¯{vºØ÷=õŸ9Uèí»âìéf’dÊH`Tò¥ğZ²¹‚ç­šäøi>
9ö½ªÍ]ô´Hù‘9*İ}ViÿkÖ!·1:
3E+ê«AÃ…–Ì'r»„	º®½½”F•š×'«JÅ«İ–êöqF×ÈõQJG¤mA(üÅé¸2¡C4õŸ3BÁšP&€”S!~F4ù€n"é-×JWÅ¼vÖ”-G‰ğÓÒIİJ=äX¨D#ˆµINèêÇ„Ä/Ú= óñq‰crƒM0Ãğ
~´‹ ¸“‚°ÇIöÖP_
I|úSÉ$doäWo/¥·¥ñf²şãn\È.‰x8ÉK”o4P>Na½¸{î—_grå–BßÃQâ"áLÙˆ_‘†Šßœ[ÌO‹áJ©#³L0øp}tz¦Tª­ãÌy$6®šêwù†\¾;_öd È{D ~OŞ÷½ÚÈıÜ7°#ÊZŠÿßNIÿp¾’'ÿÂÛty¯/§ˆiÏÔŠÅtÆ‚İÀÌd3¨m†Yƒ&ÓÊh-©«€‹8;¬‚cy}ïèYrŞÕ†˜ÒJñú~¯™,ª‡±?êÀaãö^y®oïÈ.”Àƒ“0y[m°&ç,Qs\¬®G°Ú•|ÎØFÓ«]ı1©éüöø2ÈŒmò_£´É¿b(cˆfZåòÆÑŠJTx¤‚)¶ùıá=¥´"‰#Çz»ó`ÏüÂx§^nz6FŞÍÙ¢]H«nƒÅuÕ-:—&à¬o+ıHİ~‰–;÷“ÀS¦›èxh7üL­òfııga;ª	ï±a„º×ÖÀø&ˆ€òÏš«æ„ŸÈ ¾
 ˆ[ıÍ8„¨¡Ú–æ9pé¾WHm:ÙŞ\ ™‰dC¹£ğµ}hÆRªÇaÖ«£Âz¿ºDt¬r®$¡s-µÆbßÿL§7)wfn|åq\XŸ]~Z°1ø€]{ßïlï0D>
8+âj%}JQ,3bƒ¡X-‡O~q^¿T`×M|ÀÔ„nUJoĞ kO5ç8EL¼	e”4®R´fÌŸºm±¶õÄhï[¹'ŠBÇ/z'+jÿqµ<¤ç¬ƒN)¨ù]ÍåJîª<ßœUô,æŸi¨„DêÎ•úCN¦<Ş7s{U}¤Æ/FA(\<Qˆ_Èº¤¤~7•NÕàênüˆ˜êm(‘s:ù&IÇ½7?ƒe àŒoÙ”ìç§bšvìGı9a‰rëØÂ¸3Ñï›VÉ·îşr`VÖÆØNE[²#ñP#NÙ£‚µlÈ5b»•×&ç´•&#p3²Bñ¤‡.âÊ¬	‰'‚Éä#5Tê•[®ÂË(T+ÌluL'$9Ew<¸i–OşÇäØ7K™[É]gp~LØéÖµÌ{Ù°N!Ê‚ğÖşeò©—¿umgÙ®áåTh‹,‰H‰øœŒKU%ğbhMJC!MSm«õì—ãÅ=Go~˜±kˆŸÉÇàç¶TgöÃ ŠDˆài¨”ñÊ Éğ¨=}Y!î3b`Ú(kAİŒ{W•0)ƒ²…š,` :ŒÙí"âVïz—Ù¹\Aõå	•$ÍM±‰cÇ4àñ½*¢jDÕØ:Ç>ÔK¸´êóÈÅ3É–B&÷Æö…|WW/„:!¼4n3z#Gƒª{–Õ©ø/ÀØš[µ­.Ä<d™T¬PÙÓ( ^üi6k0KVl:‡¥ïÉ›-À£Y«ª?pÑé©	c¾¬pÕæıÁ}‰Gi&h•daBû˜ËeëQÅ÷1‘ö½Æc‰’ïºA$Ô |	ta7E^Ó”¢›ï¶—cVALÌ†“†‡¯‚‰»§½Ü´s"×\¥¹ÎœÎ-W„‚ÆT‚ìÿ|ËÌ‘äÆÆ%Ÿi ¶³&·
€’ZGIÑ€¶c³>`–KJR½!4yû}_4‚¸Q˜ñ¬î…î÷uUíiõ¼³ìQ´S'ï&…ÏñÂh¥ez îµR0G›ƒ1RÀ!¹>bŠ±Í
û«J<R€#M c>•…e‚^kšíE˜ó–I³šË {w®‡Ñ¡Pµ…(­R¦ŞínÀP§Õ4çËv‘Î½×nNª‡—½+ªäIM&Vúã´XHèëËE‰mÇÓdê5âO)Q&!ë‡»Œ±´`Ë¥ÔI fj}Ï_*™ëNdá(MPóü9Ì‘µ’·¾¨†|tßúš‡„Ù.à–»v0™¬a¥ZÄVˆ¤u3Ïß‡½¤š ğ¸õ¤!“¯ãœk?“F6'<Aœ» ›U¢áoSÖ¶+‹b0vÓ‚‘U®¿Ú«]gç[Ğğß?Lfx¨åí9³¬²@@»[ì‰ŞL€ì”axò@›«9±k6Xô¸—–3·|şJµŞU›‹ldd­¯¨ÏQ!‘¬j¸ö[î%)^8	©qä@Ù¼Õ<Ñ87ÎuMó`)¡W Ù»I6­í`eãârpLHÙry6{%½DaÊñ}¯‰¨	ÛWî´1ÛqÚÄ—©9#b ötø¸EùšOÏğ¸@—…š£"-¡á{¼L¢àÊÜ2gî)âVÿ(5ò?r¡À¡|å.Ç¼P«kx.MÊ}‚«4D—şSü¹WRv!†óÆ."b3ë¿Í³ı´bÉ²ÕTL—‹dÇµÊºKÖŠxHşÙÇb¨Óİ£¬‹'•²9º¬óÛK­ÓW9±$ÌÖ˜ë‚;Ğz&¼…Ú1M7lCòh3Ç¾¿»T-ÅùÅKä$MJq®ÌaÚñj*Ç·ØòT±C,²Ù£.•ÎÖbõ»Ãbõ ,Æ¥½İÀS'ËÑäWì¾gî	œÿR–7vÙ(dó+×€ÂL JÈ>í'¸h{¥q‘IÃ Û§Ä!ea{Cqì üß¼’Š€x©´?%g¨jÇÂãy|¯áşª¸¶šöÜâ˜T
V"R1l¬•’Ê¾-…ä~£è^ÿÂÄ‰p¿bƒE‘qL·´|T³j/æ×Ì[i+6YÓf–BÈ¨¾::ù¡ k;qİ·‰I¡¡&Í='Lk_=è­!~uÌ€‘<àùi3m¥Urå,åò'§&«>Œán0ô²¿[hØ ¯÷±Uµ´9)­B^ö°h©¨GŒ¡qXT>5­¼•ÛšœX·Ñ½EO†ş»<•îdÿ\M‹Ì”fòpúü”{”óÅa`'Yh‡â«ï=ğ·¢Eß*À§<PÕÚDÿ‹‚áIæÁ½°š!áMKª8ë„ÛcßŠ·µQò/¤;ŞÒw›á¦P ê¿ıš-›nÆ9L:UÍ`>t •ì•ÛÆŒ+Ê(B3I½@ÏŠ[ƒ~ÔÔp+ee–/\a4‹P¸ù©r.”m7E‘©3mÜÛy¾TÉ¸”ªƒF“#ò¥–è^İÉ)Äh	ò·	8†Á·èç‹P†éF(U¤¤H‘™+¯V:ÉØ¼ß‚p‚„)WGÆ?‚›#”ÉÉ^¢ãvçsı[­t9}¹ßuiéÃâÓËĞ†¬ñ¼í;Q3…­x²ÖìÍ>÷ekŞµË*E#ørSÈÊB_„,ş0ò	‹É;µÈ"w”3¥ep‚±§FÖÅ¡4ŞAijò.×ÄÅ*BÉ‡3Â¦]º€×õ–5Ac/¤´T.	¾Øùü¯FP.×¢ê‹$Õh/7™õ…E‡mõ ]
e™±Ç½Ïã^³ÿÕ‚¤jğHyêJÖb*ú˜\¹¶ó&“4Aíö•U!¶Ñ/ŞgÎñz1fu{Ş;Eu8"â¡¨GyğßÂ
1-[³6Œ ‹¢KôÕ¸ç5ñ1é&‡:ŠK—·òO ÉœT·çº©¦ìB„^ÏZÌÒ÷Ãöt%÷½*Ìâ³¿”ÀP.•{àa]4¸b@8‹+?EøUÁF¬%ÙÈÎùÂCxn&æqŞã“ ÿ$¾¹î©wO§ô8ÊmÎZ®º…ŠÜ%ÌË
NÀ^åú2¾)s?Ào Âˆæh¥{#Cú
%Á$)üıP‹áLâÙ¥éWC3AdòyZ{¥):G.§°˜˜\+.©^ÅW+ÀèV`€¶ËQ©ÖrY?æ)ìq½Ø{±b±f¿ã`·]uÂ:¸Qß‘œï?ùà LL	·ÕE.·=¤–‰À‚„UCšd&¥0l‘øæéİY]ëz†–*ĞÉ:‚}ÓÔ[IeCo±9êJĞ£•
ıigSÀ°jHÿÛptÖ-d	×ÌÜ‘`±všÒğş’‘<Ê\A(×(%×>I¯gØÔ¡™L´İ(±'NÊüïik‡R	]ëèÛ& C0ŒFL%î’á;Ô©Æk|dùÎ7‚b™[Ã¼Tg¬	]Ø:bŸÑìæwuuÛ?µèÿÆ9:RraxòÜq¼m¿—1$ÅbËBZX?éßø[¬gW¿[?ÕÇIØ¾œa˜åQ&—â/#:äúuTzÌš–Y3p‹¤3½1ı…¤eíJÀœşçcÚ«B(1¹!E¯;1NÇ¸µÀF3‹Ù’m	cieâwšÓJ€®PFZ¡ÔÉÆ.ÕmÔSåUE·§+(ÒéòæŠÜF¢ÌH I}„ˆãæ!%?ŞŒÍÙ@ÇÉ$6x<¢&a±NºÔò ½EtàAùP	”Gn(/2Àœß.ÕıA	–Ø&°ûÎb¤FÈ‡v:êKø*QæÕ'm%—»@é°¤ş¹é½â}èúSl*§…÷ù™9àoHˆx†f¦ï¢¹d\š÷ä¡üş…°)Fö«Íqçjü C»EóÿäÓâö9”Œ99S/œØú59¹vR"À®oj‘¤Uˆ)ä0ĞhÌlĞçq#î†[»ÖB„`÷Js9öUGkäÜáı¤8ªa/§ôû`WÉÅ)„Â¾£OB¹İIxz¡%yèˆv¼^um€wÍÒFÌÖĞÎ÷‰¢uşÊC”I‹Ì&)?bØ!Øç€—N*NFC…G*²b'Œ?mq‰‚•–Œ„”/Ó$üÛ¯j>‡ÿäÑ­'¡gİ¹pÇäéáÌ´cƒÁaM\ÓÀ„3ª¤HˆS{/2,ëè…dbã	ª§ÁŞæWÿ…£w¸en™¼Õ±TŞ$ß³§·ã¶[àÖÀš‚~@K…m°g~´"ÑV*yÙ¶Yõ®][Ğr…Œ»¡àZ§ÑÑ¬çtâçÛ3ÎíÎyRzLd_ÌRL £zéÌİ00a
dœKğ6¶1Éï³f+%{?äv4;¤ÑqÜ#a–B{)÷J¼çI“`Øpñ?‡íÖ×;·	rmwßó£°e¾ÑÛõ4‰Ğ·›ŸLĞßÿæÃpœ}ó®=wJÌ}š×—øÕ§Ñø¹³ï‰3ò˜„ô>\Šå”Äğ®²ï¿¬GuXÍjæÅò"½¾ç×Î€‹æ¿jKL‘l´_…ÚFDL…¸ôM²ÄÒïXb¯'üÙÂJiítF²Gx
#šys! òÛM±eláwÛ ’%Ø–Ï0SÖO}I÷OÍÎëZRxÄt•Üe]6D7UXa²™ª’Mô)–÷´52i’'Åf?â"1–3Wj×u½*ÌøPö Q0yÑÌ=î…¶[`Ì†İöª J÷/iå!j@Ôg+ñÔ^6’Õ¾¥uKHZl§ê,âÛc¹ÒÆ{ª¬#2ÂKñlTŸ‘£JÀ9Sá¼`p.è¯Â)·vµ”-²µü@Ÿ’…íğÀ†ÎÌÙö½‚”9=GÆc­ş¾ÜH	 Ï´¦’DW®c‹¼h£fĞ…Yh“üŸƒ¹ÓÒë6¼0Ø®€ÇÎß÷°m@°Š]_ø”•†Z‚îù°»b·w$[ÍWgUÙ>BÑËB³ºÈ²—LÃĞİ|´‹š%ÔUbù²¬ÄqV{¸/,£"ÀÚ˜RN ÈmÿbÔs®D·ı&ù‘rŠ%N–Á9ôéşñ'm†J¶jÇkª:ÊLñy½±+skƒo¸‰Ã;c:äSä¨$ÄJ$Z V¨ŞÕ_4êÓ#ıÏñ6I¡²³œĞ‚¬aÄXŒ@„èñDšÅî¦/ƒÅ,¤ëå=C±Æ+
Ìö“,\E°œ.eÀ4s”¼I •Ë ¨ ;édJ¿»J‰üó¶j‹éx5GS¤7×`ÿÕp
UòËËçÄÏ¿ù1ëöœ¶Ã“N	}ÊêÍ†Mš vÅpŠtÒZa’ÓÔ¾×ÏX¦äYP¹FD1érm³Çbôv­[`zÃ¬4ğ¹ËÚ\sñ«àu¢ ª®ùrj:IàüIÉğ_¨Ñ&w¨RËzÙUã²êİ(î<óÌœ°ıcÖß‚RÑÙZ°‘‚hQ¬2!i3ñ3AëiÙ?*^+ˆcÕ´G5¥>ı,#‹ÏVèÃ·ú œÓŞI€IvOv©GàûvK.¼Î
€	í²Ö–¹DÖ[jî9€/ñ6Rçræ.lÄ`×EéK€²FŸÙ%Ï_K¬e`Dì7³b¨rŒÂ—¾D‘ ÉÄâA»“Ña3x7X½Šş â ­5F½³¿×A¹|ßø&nE_ôkğÏjÇ$ùÉ)ñz¶©Åh‹x‚0Û«ÌÊ’™E™+ş6ñkÙÇß.ŸÍÏWTíi€ø8HıQ¥n2@Ş+?•Ÿ½»°|s6Wk“cÔÃ×,¹!|&léŞûú6”äM[ìä g,
Zuooç^xÛ¤eÑé\©›ùW!—!'„3†<Ğåm$Š|6Dc²ô®†Fzz·ö3áù³¶ĞL«Ìë	Ğcß»3­
9ûúdo¦ïĞ¹dÕ~P	)%e¹.¡jË!2UšZWÂ¬İ4Âõú¡™ˆ*y„1ÃNŒ1í>cîÏ;Ä<Î§wáşŞo²OsWÌqå¶-§s+5 q
×’T7™Ê@jPVF	TÊ
D<Më¸öñ3*5ìØ–ÃˆÌîü±p_g¸Ù¿Û†³Ñ£Õ6ª¶Ï’ƒêüÏÄ lŒHÿ" &­E{A¼ö‘y“ñqï3è¯ àaT,"y®Í‘ÄÖ²#¡=š97ë >J¤şrÎZš@†±ZsŞ4hnHJ(vKC¼’Œ‘Cy^!•î@å0çŸ,6}4˜¶şşÛ™xLô!=·µ/CÉ¿UüëÆr¯R)æ<CzÕå®%©ó¸j¬š|<>Càq„¢_kp’ÁBGîú¬uS¤)«C¬Ùg®e¶sQ€í¢âRÀš¾ñÆÄfÉ‚®
N¢É\Å>;º«g¦©£´Åè¨Œw*>½¡ü#½gÆ*Œ=F!ÁÔÅ¨îæ)ÔÎ)ÅÈëágès=Å6H	+ÆJå²¨‚16Eğ2­Bbhê
ìM.¬©ÂOÍ”ã[Â¡S_¦‘õg|Æ•ô¡PÔ|úİ…ÊccP×¾J//ÚÑóÇéJ6«Uªì(ie{”î×gëÎ–K8ø±¨×XÄ¨íG)lášjUÅ‚”Ú’›³j;H({ócœu 5½c.±ıí(æˆéü·%œ•aÿÑ«Ÿˆ¤°í”6Ö++/ Ñ7d,›Q¬®øˆïÖ*~Ìõq‘HØn¿èé–>ªÖ­,î×“¿œÂÕFœE"I…áÕ í{^şL ÌGmÄ{ß°+3DºÔ£à]úpêeã§R/º¾
xDî'evefËho4M±Şjœlˆ¥oÒ™J=£¾ç6mqv…¬8.Şø¦Ö]ÍHm¦-¡œRë†øí`ƒQˆ²Êñ}ö2pÓ3s‘è[{@PwC
®)€YÁ#Ëßé,ØÔÇš#:•m¦b·KÖV^MÁBe£ Ó<¢ú[gÚ¸0ÄûÒ5,=¶XüF÷	Ô¼E·¥`vÖÔ*—¹Î•”´ô¦<‰é¡ù:«‰e“Sš'ºq¦6Üº^æÚËÍÒ:ßáœYƒ«Ig»]jÁ(ö‡9ƒx¸gH_Ã  Ëˆ½îSS1“Å•åñw~jù[ûNéˆÄ¨d÷àåÇ8ßĞ”àDv’Ê8¥J8ŞE^—•Ğ¿ éuBZû,¬nô‹:_' ­ä×O?K)Ë	bòf™É­ş’`ke¹]3{X.äªåŸC±4·\àÑşb[3^€o=Y	H¥#9Ï{N[™¨j-[úù­ô¨äæÔ!{›Š,ïÈÿ:…áû2FœfBısİGÜœ‰~SŠ'••X4ñ(´¢iÏ!écœ¥hÑN¶7ˆâÍÓ)›@³€…à`¼³Ò’¥Ãä{šfÔ2•ğ_?½½ßì¨Ÿ ˜y¡*ÌKU0UÚµœÎ$ÀûãOÓ^•ÍáºLœü‚RŠ•"­ôÀñ6ƒ„ş—xĞ—kµrªlàÇÜÜ@Vi¦ç²Üuº¸Ùê_xôÌÂ5¬V0âQ†D©è’’q.”(PÖij«yÔ’q½ü?†L_‡¡#ólöfÉ;ûÛŠL8X"„à¼mş_å¦Åı’™÷÷C"m¥_#ê€*Ø¶ÉÀ›}¦0¦\Õè¡lr:,?ÊŒfGÇÕWz5İ¢øNÀšÏÛpĞq—Š2«İgó¾ç']Åø w¤éX•%Ìß^¾u(Ú:
<îÃ/
Ô´Kıkˆ«S¶‹"H¯´Ò•Üá¥ïÇ­îÁ©4½œXá¹DÔ° :Òß‘«æ@c|†ÔTû³®€ò¢wXç»€«>Mtìë›²œp¯æÌ}&Ñ”â4Y¶Œş“ï3Å>/}•oÁ˜	0Ğº±SbŞ÷RİßêVûzæ«‚²Z…ê¸èG}FB¬…øY.D«Œ;¢Ù…«MÙe¿’ì€xØPHş6£htĞ‚\N#Ã¥ÅŠrF­'«-;k€{8‡I[_˜¾)ÿİˆVè!ß­‘"T­nD{?gî1#ûb'àÑån_¸²Lì´Vv¶]lç¸ËSÌ>üÏ’w¼Y iÒ({O/ÏÂÅŸ-*NÒº$>Ô½ÄÄ…˜µÂT6Tz§4²W[Çx T·ùé^ÃBVE^OíŒGáì_Äƒ !£Œğé›Ê„­¬`/IÔÍ3â¦4`—ËAîânèf lBqü~\!&Œ!I
6yEßvr=Ëä²,İe1—?šÍI/Ì4ŞJÜhx¤©hiÛ,ôË–-ÎNIÊÿ”{SIÇĞäĞí'°è5§œÊ€Vƒúùê— “€Ã}GwÇíyr,ÊÒV([BUš êe§÷Šú½ÌD Û›:‚²´€j’væH†Ì@'¶¿N÷dL¸2üc¥jt½ç&)ƒ 5ã•û/ˆƒUnfLÔu›ñêMÃ†"ˆ¸¡–r[‰ì/[„Å‰Î˜ûœà»1ÆKà=;Ë˜C~iAtØo¶Û7‡—ûòlØe¿ú‡³PKAXˆöIÆv	;^fˆÑ\ÖÔ®Eş3ƒ/hnäßªö§‰  ÍÃG³şÖ»î®v§{vÒ}£)èÊ‰ı©V}]€{ÚNZÎS}ÔÿCr…š8pús[<LÓÕq}øiÈ¡£GÂ+³qéÛpƒr¸òğ~AÅÍëiW¼y\’«p‹à*ø¾Ôeê!õ³n{|í¡j»Â¨ç¬ä‰<ØÉû@«Ş“lZù NØÅ§ £ Î$YcExhi¯KgÒ‹
h_ıä"¡c;_ØY/‰»f/ê…İHoƒÔóI‘ªæœGÏr’‰õæõ\Jè;Íÿnrèf¯ú¯l^²ãù~ÃÍ¯_´°9{Ö,–¸9‹^^¶ÜŞ}ÌÍóZ6ŸC…<¢ÊşHGş¶5¬I‹ÈD*ÜR‘Ñ:XàîÒn/]í·¶Gp¹ !Ğ;	é\WÊ>ƒ+.Û”@…hóV[ƒr=ù»¨t/ÿ4=‡_¬Nh­èÈ¯8ßqší˜Üã1©Ş)™¹ró8eÕpÂb¡zê\šFÊ
CÌÕz’“¯AFY75Ì¶A¬?±4n$S”˜}43ä æ+Àè‘¿ŞÜQëP8{5ã;3X®èÂlT¶– ®î¦M¢½-…•ã~†¢ÿâ,éŠn½€‹w:´-ÅıóØiı’öt®¬ î¢mÛˆBÍ/ Ì€ ŠŒ’±Ägû    YZ