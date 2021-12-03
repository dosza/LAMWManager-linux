#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1740403632"
MD5="e81e8aceb2c492721e46099c088a441f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25004"
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
	echo Uncompressed size: 180 KB
	echo Compression: xz
	echo Date of packaging: Thu Dec  2 23:34:08 -03 2021
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
	echo OLDUSIZE=180
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
	MS_Printf "About to extract 180 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 180; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (180 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿaj] ¼}•À1Dd]‡Á›PætİDõ!<Dß(8èÄ¿¥\û‡5¦ğWä½W“o6÷¬¿‚İ+{ç‡0;¾+ks+/ØQÿ‘ TzâUcJŒ>M§éà“iï14«ßÂdÛ}âY Ë«²§qÀlÀGi{švB÷Ï-“ÄxD³®”æsŠj=C»ó¶r ëCÙAvÄ$ìâ¬¹Ë¬ÇÙµ÷ $ÿ¯Æ>ˆ)Ë«†Áo—Ïäè–¡W+1#EKû.Ş6¥”œ9Š1Í+>Ô#*.S²dçé3Ç3Ú˜?â¸ó¾‰,g €¾z÷&Éiuè*@k­3
ÖxÍö;°ÀMk¸êŒ¤u½ 0å9?C$*ñÁÕœTág+¬à‹s‘ÏX‚ƒ›dwòtœFÛ‚¾’4SçãnH…—²*…ä4w#Øa¤¨Û°tü‚†ÎòkMl`MFB¦+¶Ö ÓüfCN
yt"µÚ®¨P-}[¹$-ûçvå®µÄÜóºMÄHÑ·fq×gš^Ğ#ú„Ûˆ\Á	·æOb•¦cœÓ¥m¡%“1vjÍÑú×L*•½b}6 °éb?ƒ%¶6êõ21Ö¸V…¾G|o+ÿ‚¨a!ã€¿ù3Yy'©Y“[˜K¼á­*İŸNçg¶eŠ¬*ƒb‰^êb+A«.¾çÈ—ŸëY_à‘8ôåÕZ4ˆÃ'®†0sƒ}H¾øJ<ÖWŠÖKµáÜ&[d2µ…8³Ú¯<›¦j8:ø‘Btˆu>4ílìTuoÓ¦²§üê¦-ÕQİ¹©Ó»°[ÊÙÄMŠ	–È´	ûIÆZb¡wv¶aS’ª»Ü«òQ©‚É’ãØwG¹(c¯0Yõ·qË+ë€~Q1ıòyzéCŸabÒ©Ü«Ón 
ÿ"õ	+zçşğöE9”!¦e}`°Íøp¯Ñ‹Şyà±7®Ê8O£ÎkX1TB–^Ê<èE¿‹Šştj$0ûjAK§>¸7ş×>¼-&!‰¶–{õƒûÍëÈıl´Ñ]˜{aéDáımÅ¨…%÷g)–1µƒƒ.Àxş^Ë¤©O;¿l:q11Qè¦»`=FqíÀ‚¸ÖB¾Ì#Ç†XœåÛ˜•n8ÖŠÇï*ÙÑUM›w¤%B	>nÅˆ½.UoCÜäZñÖ¼ğ®ÁMn€zãß!&u>lîİ¢?Ìƒœ>(1íÄÙJu{¼pRUd×Ñôwü@3kşúî‚Ê§4);&«¬¹Ïàîpß†à­uo·Ü€~F=gzÄ!9±•×BŸç¡'ÂvÂeŸ€®•4b×"ïÍ=S{ÕB>Yf†ÜRáD
Ê%:© jÆö“…w¿aÕ“üvËÉ;(XKÿË	«8¢DLG‚æLMåCtn¤al¤„Õe_lRÊa{ò4š´#D±ÆKAÁÔ«Î"¿,um¥,–U¯«ÍıŸ™i¾šÉñNsuõŞÒxû´í„KßV2I$´@ÛßĞpkxıŞ&•‹zÄVşÑ8øÔ6D°c cÕĞyNÖÃeféğµ¼ˆÛ`Ò\àßËO›”Ø†—8˜£; Ã€*=ââåt1 ø÷‚âÑ1ád·&M{ÏrQ]èHƒñ'n^˜æ.Lüíq.’d`¹x 1{ZâIâ„œ©ì©9<5Sz‡·F:ÍÃ­Í±´'kYÔ‰õÅ*ÕEç®şç9…6:‰Öp!%VŠ@ÏÌÑ2£(¤¤—+,•MXh‘iz®{¨ÛRÅ ¡z1Ó×QÎ`
j~˜‘»¥æi+óbULâı]öËÉµÀ²RÚªÍ91¶Á•óómÓnn]ğTIkC‹¾ÜâÚ!†5§h‘®-~Óe˜ˆì¶¤Ë¸µvşQ\Zb¶íóÁ³
^g€j©u½5j?ğ<„‚Ê†•ÀÇh¹3–ë3g‘;bÑ~ÈÓaæÄÖ›Šp€RáV¸dÏ”Ûco!5àƒòa*#gÃß<&Ê-R$š±|Bo± U³øØGØ…Á{„”7/ßˆ)½z– 0;ì ¡(@¢3€É\èûCWŞŞT‰=;
×¾0éKÀ)M­¾ô-›±ö™ãçòJ~æ(h\˜za[C`ºc³rŠ£.‰Ğc&ÇÀÙZ¢EŒ^ãîï”.iDC¬“†´ò‡=ò'`ä„!,tß_­W­Âeª‚àù‡ÑÀÊXónsöì\&Çs÷B`¯êÑ×¤REL¢÷?Ç>exxl›‡i“Lëû<ç!tÔîæ¥Uxfu%tÅ‘UróGƒêÇ­¥ôà®0µ-%w‹lá%©?ê¨¶H¹Œç¤/úÜ³úD^üş+UB[Ô•4pŸ{;–Û:T‹½ûÊêz–Í› ÉÓ‹R#‹…ã…ìBáko1»u’Ò=S•ã€Fl-4~†É	p¸”Èj¶í…`psÛd¬¡’ú¬ï¯ïC¹Cş²`æÌÊ?ëíİ¯ä3²x8¹d•Ä1ß¡¹Î.O’Æî6ˆ”L5§cW2ìù·…3ğ±™eL	Ø ~ô§HÆ6„=ñTÛßd+’	ÉÀ…"•=9ºb·‘òtóZ6|ÎJÇ”=9¥Ú:Å„,^pååí¿sê€”L/Ó'ÅÎè	jó™YÂ(Ç¹.Ë¤ŸŒ}PÁ|Ã¡>* J(„BSŒ#äÉF4îÒlVÏÀÑ©Ş£Ô×Ã‰Å€¬n»%$…ERHˆ†™Ò˜NÚÄÆ¨NÏî3SÙ|“€WÎ‘ò\(ëQæX…ò6ŞYÎ£'»ş)¦s…;ÔÅ¿*Kæjª ¾É?Æ*«™¸t)¢Í—ê`fÕš\ÙrT0ÚÚæùÏR%ÜÃ ÁLh™<„`•-O¦ ·”z4ÉQæØU­+?@b:œR›TAî1óiN÷²–e° ÃÙ´ÿWË$D¼$52ú.EsánŒ[ƒ¿ğÃuS„L>†©®CøjÒÅŸK¼ÈïÂ•¾ĞPk9Ä‰PÚ'i¹Şæ13k¡åI;JEû¾µGÊâ¥" ¨ÖmwÚš2IÛÕruêëÜ­¬ıgëƒ$®&ÊÀ`[¥ ×¸ò¡&×&ÊƒúÀô†HîÎÕ!&c¤hì=âaDª°²Æ^ÀjaÉVQIyá[VeäQIùÖ6œQëËıÛ5ï!kåUÌrJ*Ùª¨,6Mls$0]ölâ\ÏÀ·pŸ×l`£ÿŞexû¨T˜*G÷¢…(ÎmQÀòjE(M£‰WRõF/AÖ”šĞa¦öº Ã¨)•ö½¼±q_&ê Ñ¢ªßŠA8ÿp©äÃõ=5ŒÉîD•kus(véØi½Öëæ£Q8ñ¬•TO‰šÆ€Êoùlÿ…©$¸b ÿJ-ºhqÇy[)éõ˜{›xWMrqBI ›eokw·"œ¼Õİ‹ñY<Ï¢•”„\¶n³{R&÷`3âá9S›€âõÏésÎİ+(ÜÑšTDú_ûèp=ü'Ş@¬Š›:Ÿ¼Ö––"ÕL€‹Ä~c>Ÿa‘Ğzka÷+Mßå«3w|B‰@VXí|Y<bÉ€ĞˆR5¢£Ö…Bnõ‰·šÿß,3Š­¨µî+Ï÷Ïâ4
zÂK©Ä".rØFû²bä…÷ È—üËWT+ä)à‚"w«îÏÈd{¸±SÛ#¿EÂ/°êì!mñãå`™/™´7ö}@ğ¬éaÜ'ÒT!´x0}M¯JÚ$;¯j_ä*yÎŠ7=;¯ïV²
›‹ «ş	î±óo3¬=óÏa†>“Ğûrx™îª’ÙkÅİs/ÃxÇ^à^iZ­w†àœ¿\ş9FäWÛNIØ]ÈğtõúçèàL¡ÿ³”C~+UEZéhËÊB3˜¥„ƒ\ éV	5Ò
f¨Ïçšç¼$y O»—õp”÷-Š¨&P¶—F<Ø(¸~-ãq˜›<˜`¯Y„²Ëü¨l}sü×Ô%eã9mÚÑ1?À1o£8|º Ê³k)ç-ş’+gÌcHÛ³¢â˜ıÕ‡£µÆPLÂ¼ßT	Ôû¿ódûH›iÌé@„Ì­ü¶7Ù{€èñ™î¼‰¬ô#i†rlæÜYmŠÁ‹B›ß1o\À=œåK®X^òµ÷YêÓ´½x·€î£?¢/—w8¿ ¸¼²ÿ^Ğ´5İF`f…Y<•‡, Uı²©
:É'(1nƒ†N_ò:œe’™MšamîT#6:%ûl€Ê©™•¦DjùÁîPy*H¸˜f¼„§vĞÅ¿éµ—Ä)øö‡ùZ@«~eFŸˆb|ÈçxéËÀÕfù×!Š,tß¹ÚKj¥3¤^Ä¾ÿŒKş˜Á”ß¹7Ü]aEª"« ›éˆó±™g¥ÂuÀÉ:A¸¿(õ„aèûÅQÆ89)Fó.Òzœ³ø›[˜¡fUğÛšGl¡1't†K1ü&*rÿm°|èc¤”¦ ˆ3§³´İ»t1‰ï8V¨oÊ>u­·2ÇÑ×@$ñ¨sïz,–[F^p]À¼rl× kÇaTÖÑ0Õh¬ƒ‘e£0ø5íÈm:ß62Òİä»i®‘Â3ÎÚçÿĞ¶®3?§ìh—H‹ˆ<Í2°‹@?	/vçUY¬Yn‚q/ w*ŠM(pGjÅäÙg*lŠ¤Œ´™´ŸHöÿy-ÆGj¦RšäHÕ”oòéa8]£xºŠu»6•ØUğğiù\İ©ÆpŒPıÁª©Gs„$på~hñ<‹NõUß¾gÚÒk77œ³ ·µ›L­§zÀ'KA–şí·8j`<uº§®me}ÙÓN*ö ç¦Kÿòêf³g¥¨¢¨Ù÷®àîYIë×w¸¹º‘V‰päâ.›7·šÔõj¦¬õ¹{Òå:H@¹Œ§ğ­@u‘õ¤ÇôÙ°‰IŒ¥³ t{wŠå!gšß­…ùNÿ[¯ÛFjft¼Cë _o¥ˆxbZxb‡cõ	ø\ólâ€ŒæË•äà +|ƒ£Ñºö/Òü>y‰Áé ‹Í±%â0‘ÚIƒıJO9CWû?‘oaÚ»O1¥„—‹’ÅÌÎËä ~ª.oˆĞiÿİ;—õ°£—F »ÙğØB":³ÓİÏ…Â ^–”ù@ı'Á§C&?%cê×;‘•iØ!YãL†4Ö>ãuÃ·&ÀÜª$·¼È¡Ì§C­3 ğß¡LõZ£û˜OˆKıCUFĞYƒ6Kp-`2şF,â f÷V>FÀÂw58t‡¯æ¶LfĞkç] lJ·Ó1ÊŸó h€;ÁìÂi¾LJykßûàK³y•6.@Ğ|«kTùh•ª|’Q ,yš–¼¦¿™Ï “xbÿ—i÷-rdå?
ınİ„,IÃ:qÇ÷5‰qF8(kÊ›IT×Å0qŞ,õ¿“¦`ö^GÖ‰ÉŒ¤‡vnçÜSŞ^¦Ã¯‡?¿‘ÁAR³_¾Eí’[$ñ/ìë
í”éû•55~ûyö-–-Îòs${eXšìXZ€w®ªƒø­Ù’wk@~õÀ€UGM-UhĞZ"	¢÷Zp„¨i·ìHÙß
¦ÑÌ¾Ø8Ä â×)fà·e0Àm$y{H&œ÷å³¨CÈÃ¶eùõF‰ÄNë¬Ğ]×õúŞZ2²x²áŠlX¾ú³ÀµİAÔ 31íUÒhDŠ³ğf!8ä@›ÅÙ@¸¿#oi­œ|(]t4ÓnÜ>–|F£şªu!¤\/(·CXz[zÓ÷!mk*ÖüÁ¾yöe)¸ÓX«:¼ïç”…×#›GÕŞq4ÙJQG‹äf|?¹ü£Æßjä\Ò>{Â½ƒ“ü¤±U|#Y³=>Áì¶ĞÇ	'øÂÈÕ5uW3×+°W»G?>dİ!¢Š»¡üîú80M9¼rñŞA¼Ï2ï¯ÌæíˆWf
{i=¡«Šìµv¢±ÁIñ\u#­ÈEG„ü§`…-Î$M†7ÅĞH¤%XÓ­L¿˜zNìÖƒ5Dèá¹Üxv¡§êSùm¦İq
ØE«P—BáÄI	@o§Ù{Xâ°¾ÂêÚœU;ñíÆ#ê@‘ãŠ`9ØÒÉ…õ YĞx_£¸A¢ëcé};A©¯gYÎäİúq½“KR:Pf!ÙÙ=¾h§±l)Y]uÁÿCoÑ°ç§²3éª­™…İ±š×ä¥û=«Çk&0…S =øvg	Š_wùı¢?·7‘äMÆïT>ó>¿;l¢9~$¨ıxú­åu[Ûs¸àî=ò
hÁ†$'¡¹ıÊÖ€˜Ö‘·`ÔıE]-ó&µïÛº-áD°ø‘r2#êÀyºáWtøSk.aç¡‡÷ôA¥ê_½F¡FZ‰E²â3‰ÿæ•_AwWƒmS×¦F• ¸ÀuÜÖÊÀ$f°{õ±ÆH;+·ÿK/óúeÙ¤a]AlÍ…¤_İ„F &	è«W.Ò5¤à.íÙwhìÀµpãê®£åmŞ§œK˜‹^õÕem”ÍŸ[&IkCö\Øò n¯OU†‘Ôß›?Ôå\Çòİƒ¨ÿYø±—tMÊc†¥‚\ÈÜ‰æÇìÛR:+"zí8Ê¨$èó6«³½³3z‘§=7n<,¿ıü"\1ÁëFâ­m‹¢Ëå0·¢¾Yg-·™>ûµ8Q´C¶íğœ"bêKŒmïÇ0+Ë¿ù$‰ÇÑe4S€É³¦g@ñÂ{1d—õ“FƒÉÆ5#‚—J\ç/“W}µB4Vî3àò~o¬d¦ï‡­pÃ¥3eY¿R7[eá–&î)ÅÊÅº¨d3\,ß2lSz!k@ ä¥¤SÔ:fïb=DŠß¨=dçìÚÄåà‹|Z– L‰5zŒã<ª¿§NwtI¯M;?c…@Næ€;¶0“ZloÊ+‘ ±2¼Âö1©ÕÁ/QM‚¯şhÂSÒ}|Ğ"°ëŠeŒŠ×OêFXæOj‡Ej#ŞIÜ/¦ràäw¿WÃ0PåÀÉäTÆ+ø§r™<%İ'=ù©E ¹Eâ3ØšXŸ‡&BÅÑ·İßæÀI¦kƒ…{ÿùÔ'×{(4Úçld£:Öœ¾¬[\kÿO4Oß:¤M—«¸¿ÂîîĞcæ
jài—’‹¦qLÖ~ÜXæ~+7À‚Lã•DÕŠ9	Ê·»)© š»´ğ¯Şp"X..¦ä²<%şl‰_ø–úŠ8pıÆ{¶A\&º¶±¼ÿƒ’5s¸$fÛjÑ„Ah€ F ²ÿñ!™ƒp±m_cØ¡E3l¯V$l[hOzÄä¨»3èJØØóÅnùkàdì+IŒØó/LİÍ};a¯¶NqlV[¿ÚÓ¾TU•”ı·\;Küø°ähJ¸è5k÷k¬+û:)%D‹;‚ÔM ÃåÿÁe„dëĞ‚‰SÃnâ‡±fº÷ïjiŠ:}Œ’éÚ£ËÒÂËvÄ¾æ'˜Î9S{ïÊãŞê¼©WS]-¬<öBÔ»ŠÚ* x²\N¬ÔgÖJŒçÌˆ-áëW9hhñy§@èNkğë\tõ©=ıĞğsÈÃÒ º¯½7àÿ4^Bë?ŠÊ€áÌ¬×au‡-±‚u>+ N.óaX[„>ÔèÀ–
„H’W—âëh/íÌ »XW·‰+~‰Æğ´`ŸZfp€Å 2p/QÂRBãånZF­ªØç…9l¶x1£^î—›ÛïÛ%o¬W>A³ˆ(¢¼5,…Ñ"OõI»pè®47ÔùÇš“*%¡ß@89æÙXµ©?Ã/“ıÔßGŸaÌËåw¬Ì&LHö¶nñ?ûåKşsò¥‹
É1øCo%Ó] “–&qH%£üÔ»¶µxëØ8ì<6H§6Ÿs6ÃÄ6?î’Ñ¾KŠ:3:ìW@7¹<¢àYz’5ŒÅ·´ánOM4Cèt¾$õ’@!¬-'•NlèŞ}Ë'Jßı¡666¶º¯“­ûº¬E·m“î;%»5V´obmuu‚~a¥ş«PzÁ¥¡’¢À, ^yUbó4Âó8&MT$Í´¿ÀT”f3À@ï÷l¹ˆ!9ò,HááQÓhÄ8±0k¸çıWPIfÇlpÑCR'«’§?§gçñˆS…XØG&;¸G£éõ÷Ò}¨œ?ß½ß„IâƒªŠKıšñR¥xÕÜ©ğ{tø¦pı˜b¦09˜¦TÍ©‘v—ë,Ó§Ìx}°èË§÷Ä
ıqŒ(éc.|.QT™üÍºdå-¶¹Fçåœã$’á^¬óµ¢)z<ÜZ¯uù`nS±ÉƒÃwDÑæË*úzã“¤|ÅiU¶¢­Ûõá8˜KÿÀH¡.Gè†¼4ıÍLsş2°Âÿ×*%ş5eïqëŸ¬&+‰Öu‚rÌ±~}|1.øQÓÒ¤&€÷Å…4c‰ä;	7ùòàÒÄu¤*¬;º)‘ÅQ_gôéÏŞ´Gğ…ÓhV(ö~V­œa§M·ƒŸò^ŒñÑFL³FÒrº¿®ŞPvâGY\­o:˜r˜É.¥Ò:\ñ{»4\CìŠº-ˆ¥ºAÏO²KiîÒ‚®Ã#U £jãÏÀëª•¹AÑ8ôo]ãğY»AR˜ÂK=µ9½^§ø<C®eCá	†Xí‚±ÿP ÖóÌ«8ôÉ$âÎk(–Ûù«qxn–¶eÆ€ë"“ôa˜¡îÌÊÊFu4ïßø=^@0ô•™xrRU•Ÿ+ò§œ„BAêğQš“ø»®ù_«ãÉôè©z	Oå÷Züní‡g²JkõE«iÛ9jÛ€ä2ä Á<Şh AÆxÕ	.šd$ÄWû|!îMWPÒ¨ÉŠ2¸õ¦›¸sSÒ~üQ3Á‘L` ÕÆşz.·”Ì°Âu:¾/|›­ÏrÍ¿È4•İ\Û¡Ó¬âõ.~\8^¢Át¶¼Cz—k“±rÂ^V 8Ón#†¾½&·0|ñµåº®
tıA¦“ÖŒ^]Œ™i¼/Ucq²¬¡ŠÖÌ3°p
PZ¾¥7ÌOù›%/K"‘Jì‰ÛÜO<4 O¹c*Á·Ğù‘í6$Ì3N¶ŒDá.1"£?*-trmUd3}$³ÔÜvŒd[×cSî–ëFŞçu
äş7İÈS`¿4)Â¨íîlô,ºÏ“‚Ùæ~—Şf‡¶7|"vtAÄöE‡Ø>\÷	ÍÿLf¡•<
Á.¡Up¶¹ÀásZá
È~˜‰=0¼Á€À¬äyìå`3ÍYÇEIõ¸O ôCkÇÓ hê­ZU6şÿzßcù5Ô ÷´Ü„´è cnåRi3œ ÉÍaTÇö(ÿãó&øH¦1Xò§]”´“(Æ´ã"”ˆífkşÔ7Qöäcá~à/…á…#L?!¹–jé‚#Œ±Î7D‰÷l/çûı‡N­¥(bìéÏ~¶Êp¢¹+<UyÂä<ëÒÿµè£d0¨“™Š‘ëN‰S éÔÛ.¸2nŒÆÒ|úJWƒÆ%ÂA'ó§Ù%ßÂÕØ
Fî/ãï‹Qš&ƒ¸?‹¥?nK–¯%Á½NUÅØ÷±š:õÒÛ§ıÀÒŒ’€~b¹ÕhÖ­gr˜Â|xjĞâMÖI"¶°NÓ÷”ôğøÓEÖ]DìÄlœ‰ˆbm¼VLe3sï<ŸÔiÀÜ”¦vƒ­vçÿv}¨{ZDœê«»ß1¼cN@÷Ş.ÆE)Ş€ñøİÎåæzş‘ƒ±å`%7XßòP¿÷·­İ÷(ŠXVÎ«˜şB+YÅ:m|hÄ¾şıuÇç>ÍïyÑ¯]Vi±JQy0<'
ÉŠöî±ßQ	³¡è ÕÒI†Â	Í:‰ä¢¬º:oŸ–„UVÛ"n{’ã€ÄÉé.ÀÕ'‹æ'É^C¿‡Tc<"…¾åŒ@3Mé5
ÛkÉÑŒùØ÷Ì¹–’ÕJñ>øÑ‰ ÄñìQâ„>M¥kŞ«azmı?s¤0İº—A’’_s‡	ˆ¾ÁAoMèÑeÜDÀìà£nÀH‘ër‹b3fEı2†ï<¡Ú59ì¿# ¿fªŸ
`Îùùš³¤£ïfiñş,KÍ©Æ¨Í€aY‚öæ'D3Aö4_#¼˜ì»¶¿3 ”¥ş÷qu`^ôæ|#ÚÃ*ßl·DÚ¹âSHZûª7¹º  Ğqô½B®ãn2.¡¦­µõU‹•¸ƒ×ó×&ÁqÖºùõúÒ%€2nxs¤Ñşx®rPµ†Î‡«óèO.""é;Ek˜Ä¢¥®ˆw¯é>u®ï1(âqR&^GíÔJĞÎ9pò4xuê›•WŒT€¯E¨›pİè€’P‰x+U`õ:|.ã«ı’İáp‡9}RàùopöUo'áÖ½”N@êfÖôYa†0¨ÖêÂîÍ°ÈÅj›ãš¥dL'Ïµ.TËÕmŸzÒıìÓ“ç¾8É–ÎÎñ	­öXÛ_˜÷g s˜uşÉø‡&J ’&Äö±­RAÜ#ŸÃ´§Âdò ¼åpã¾—&'ì×ôÊs9àh¨±£Ümf\ó™:k§†‘O©ü À9¡§éªÛCŸŸA(;gkíÒ6w6Ò‰!f‚Š­­C9›’ëôŸôâ$Ş‹v£“'çiy»2öc³«>ëT‹Í=¹ÿ)¦l+h% ÑmˆË¸¡;ìgK{ŞìÌ¯ÙjÆyò„­cTİéc­]S[Û,=*äÁlÉ¤IêYf›k‚lÏR–)¡{îÖôË‚ácËgeœëÅ­WrÂÉûøĞC–²Bœÿnå´2èòj•à¤›¶ê1^ßMÂ,Ñu˜"¤•”öî+ààŞ8zV®v!„$géÎ2Yº¤áŠëì`õ{:ÇÓJ`â{œ	ñXo½å @»‚ÀáI¸´iÀo:AU™Ù;=`G$@øûÓK³h<dìİŒ­¿z“Ur4ÔÈğä	’Õnäªv€„"¡x}‘·şİvêÚîÿú£ûñ¾s6®Å%}÷5øUß!“7ßUXS›È4BÒâÁ–ÄØMˆ…°«5Œ‡,M¶rõ´5æÒ&÷óìØÂDï^¯+?.fiÚ¤A£ˆ(hœc
_ËÙœ"˜#%ß°L” õ¾TĞO'u÷VôoÈ3âXù©Ì÷7GA‡c¬-§K•#Ñ›d³[æ¬.r”]áûôöp“„(é¨ìò¹­Á¤ELy…P¢CkÉÔáöùH9t¿#:påÔÏ/ê òŸJRıj%‘á´”H‘éfiÜ¥ÍÍ“D.ÂÈˆQ]™0s~FnüÏùY@¤Í
BIeÆó°}\-,ÁIC’,Øw€6¾õë«¶Íìı"BÌ5„‹­´~Tä®†cN]ûo½]Š­Ç`£†„<Ådzu=;ŒmïYzÔP·†â.İ¯´¿ğô	)sÁJm¾„‰Aühª~ŒCóÊ9êOŒäDu&5çj·‘jê:Mº‘ŠTOeq7g{Ík]'p{_M»ää{CŒp¹æ°ôVja
àsæÎ+¾u²¢§¤´ªó0<}ß+jæ–!ØÈ-c<~?Z7b›…‘w[D>Q'°¡|Ò¸³¦oÓ¦G×†À'–¿…–Øl›Ú§jmOƒÉ¸v)_	õÊ h`fÃ¥¦#ÿéZ[p1ú—V²S—åïê–Y›O0›áµ3ÔX'Xó1°Í÷Y}rG¯{–3°„O‚«Wq2¿``%Úhè ã_N×V‡2¡çjéè½¯Ù¯m™±ı’§'ü¬&°ï±'à~C)m~:ƒ[$}İT´}ç²YÒ8¦>Ä™Ck^Éä‚Çtì|[75‚Å|¢[ç`R¨@í$&Â?ÈŞ«G[+,¸Yd.DäKÜŠöİ”®§6…ˆw…Odsö«©øD—ìŒD.ëÂ±muUKÁ'ÏéÀ„ÓË­0;.9t{Éz¨A®6/´ĞtvŠ©³™ùyj)‡˜ø´íÁ'éåÍœ10[yÙ›P?©{ÿıeÜ‚vğİÆ•ïoeğJçÅß Nå™¢jÚ˜¬ÍSXXÚİ*™Œšù--Ù­¾ÖbhoÀBïu²½¬ˆsûq?§lqFò"õ:â æEŠu l úM§¢±,Eÿc¬ŞÓÄVˆê-d^]Í«¿©z—§/ÈÉŞâˆNËmğAnCßjÚ˜
Z'aø§F6\##î^:Ä„Ş¡`Ÿõ €«Dìã±V$ùø€[bïpd¯´?ZŒ¸Ó+ÍD"7Åwl²+“0‘@*?òZ7ÈE$#-`Ô—ã•E-\éY•>ã˜Ì1‹urİú hˆ]´Ö&ãÉÖbISPİC¢€ªæÈ7D4Qˆ=²l7™0ù¿°~sUÅ2\ö©Ê ;ún}ÜçğZ–ø¢;-·µDDuş¾;1s­®Eà;÷Ì]1š
|{ğìôæû‘±['•‡æB²W’òùîøNF&×?v,$x÷÷‚_±=µ£¶Ù¸®ûU8ZæÚPKiÜ-#§%AÇ¡xüBygvÊ„µ=QR¨Ô%ıÇïdRÍµ]—È¬I­J¡ (ÈMeƒGŠ˜G±"´¾±qÅé» ÑG­ö§QÅŸ-ò·UBM2ÆRCÄ9œäg£ZŞGèû«‡Còä¬TRÏŞÙØn¤d¦[ËB•Ü¯-yJƒ(`‚È}ñ
-»~U<eQßµ"Sœ¥¿lÚ©ƒ
ôÎ¯ÂlïÎÖôÛ %ÂùPH	Lj_ØÖß/Åş¸Á×š£İˆ{²üØ;á¿ã}dZY7ëZ”Ğm¼.-˜‡`†E¿PÆFšªøôÉò/†£$ë™ÿZoSË)ş³$¸Ùµ¤Œ
×ø»ùl7&ÃG%4h÷Ü¶»0—lS<bèOçøè§Õcï,ï{ØöXĞÛIhïJ,ãAzNÉ±`Õ4×ÏòË7Áh‡üJĞûVêS§Åü¥dögzîfVµ¤8s‘W/RôTHèÔ%×ŸùŠ£Ñ‘\áÖat©ƒ¹€ª7‚´9.SÖ½{6Ú"jºàdzÏXƒ0"v9K‚Tf#º»q"ê%õCÈ‰]Q±!V,èáwpÉhs’†&Ltw!t­“nq,>Ô€üûw&E ù9mï·`FL‚SV”™¬ëú9¨¤?:2á›É<ñ ÔçôšÛ	Z†yƒÃÀ4v¶YjÎ®¨rCX™Öd›ĞÖİOÚ²‚;`Á!¬¤A÷Éˆ!-Edçãğ}…NìÈåJä¾}îrHÄ«`]=ñs®a`[öÓ6LY×?W÷rÚæçöFö†üŸŸòGä{CE‘9È>ä5ïºOõºPÑ³Ü7e©°€¨ç>–Ê«A²7&îWˆ¨»•€Á™
Ø`‡áğr™dm«öˆZ™ÖÜã_øçIí:n¹DD”Û³­T¼|ÄY=Å^Ö§äUpFÑU±éLıXóÃxquÒ›VÇÀ®Û5ÉšĞ–LMÌúd3Õ+¨ø°"İ	ÓÊ1S’±K±)eq¼‹TAzò—M»5ÓÅyÊ§ï‡ş l4ŸŒ•²ÙiA9_ÍGÊT 0bÚ­şO%àA…}ş"ØHµ…„Ş–S„<¼#]tp1l&İn‚¨LpW§âˆ.ï]š,mô“\Mİ›•§D[¶›âÎô™(}ZHYBPÓtÙ‹áNêª~üq¢iD¥ÛàĞöLb§!.§1&I‡K²â
p¥Ø£_fØ¥Ÿe.H×,j`–]RS šñ /„Ê°—¨è€€ÏÄyÚ[´ëßÔYhãÍ	t†;z®í¿ë©ïI÷x #9wİ8êòµoÊôrêú+RÚ¢À¨ßH3hï0
lª™0)ä„Y1YBcˆv™å×‘Á^¿Ån>…Joàt„ÔÌ£CbŞÙ}á
hô*œ¾v¿ÿ¡¾· zÏG
â§Ø`Cå¢`¬(šóa¬¿”yF>”d&Œ‚›
yôTgzÃÆµ‚:§èSB‚1©î…SÚîØá½'r½k®ƒ¡¬<ÇG‘|2ı£Lı“XIËÜ\ĞşÓWôË$rQÿ{i-]w9.ÏùHæÜ`Ÿ7mUPy6š”;jŸõ·(Ê>@e©ï?8’g?)¤SÆ…`OÀ¨©[ğ¾µvÒˆªLËcÅ/,¡û°“øjV}õâÑÊ~UÂ²T¦*GWcoŠ™y¬ÙŠ¸ö£[4øRÎÉÍy°šëWf–L÷ü3²;<Õ?;$©Ìäbå,T#Î½¹nm
‚ $2ŸREŠï•á¿øÃ(ƒZ²g”g—>‡û	ØR rùe²"‘@ Í&·Íá²{š‹Î}9‚m¬(/Ø¢ŒùÜ'yN54ĞDqÉ=hšA™4G®¯¸ìoég.º9HkRÿí›­ŠøG“ZyÓû†³Ä˜ª<7˜ó/úš4¹†ıÑÊQÑğâÔ*ò¸9¦Èİ½†NÍÌÆ³’ù¯înÙ­G#?¿/w-A–¸¢Û¼K^')¤ -E„Á­sLA-k£ƒäÌäWY¡ÍÉEk•ú«LÛÏ½¿Æ Ã…öNËôÌ´Ç½ (Iµ%—ô6‹÷xèˆ,R«Ã[© ·3«}ª–Öv6Ê[Ï˜;L÷¢šşÆfRæßÃlçWöˆ‘eœ3x¢¶şÿö˜J:ÌÅjÓÔ(×v½¼&Dìª2ñ(¢šÀWÜæj}¾ĞÊş)dW‰ôÔ¯µ¸•-†_Í»Á_ÒØÆ(Ÿü/²æq%SDêÉQWTgøPp5vZ¶ÔóëÌ€ÏøT¶ù£VzK±³¬*ú /-l‘
Ûı¼m:F®:X?ˆ´Ş“9áŠ"y–äD„|/=á“©Zãóêyífw\K˜º¸†9)êVİ|IÅÖÛW*›«¡FÂĞ[ˆhğ$œ)iR:¡HI[íÓ!]QÕô¬Á€š³òÉ›áJ|àÅ†Û~×Ñ„3â¼‹¥-š÷
~\ğN­E@Ö„^1uR/±şï#XZãÚù]¢¶å¼_~D¢‰‚ó¬àK·‡x(ašfåßXjRİ\)21»gT)v¯”e)NÖÂ°ìpÜQ*	`±z•ı-Çûr£ÖÕ³üs‚cî‘¬qÄ˜ŸDè-áµ 
ù‰È9ŞÑÔ£ÕSóFk)¬áıcV!õŸZİ)!5\È7²ø2qõ¼” ĞÚBâ·«[°qÓmqc]fÁeŞ:hª>ÃÙVµ!äLë‹>à4³tê/™.í¤•Je\ùİåmƒpÌ3ÄıËœğÅ\â2h¿µl¡™W@2
(ë¨»5È2¦u”·,[WãgóSÇœo;.±Aè@úÉY~øw’)a”’ÎVİ$€21WëÔ|Xğ[‹o,g]ª¶â ‡Œ§J8²—)jV!{bÂŒT{á®õÉ¼Ú€G©*.ĞF0¤ƒÕŒ¹cÊÌg©mG¥{ãK>ñşaaúx à8ñ¨ã*¦ØuıÙá¯rîE¤Š˜/iü6ƒ¬’Äà"3„È§ßjõªÿLKZ˜/FÎÓ©–éUa:C{9÷š&¶Á«ˆÅä¿`˜GdÑ€Ô÷Ô€¯eü=ÎÆ@A¾Pë$NlíZÒi ‰™oµŠñJÑ*«W¡û›nT^ŸxçA(Æ÷z4"¹wáÇ®}ÄÀ®Â±GÉËêM¹¨X9ô·Ét¨‰\¿ÎÜêç+'ššÅñ+ÃTìdšÕŠÁ7Úà?	¦Â4R7ğI7b;eƒo’’¥3¬ëÛH›cûqX(Kg#,Å³a/6áÍj}Ê;Î¥+xŒ½òsŠ"ĞP2^©W“·şjÊ—!ÚvÀÇF'µºT‘éN§ÏÏÈõIà7Äâ^\¼Â»¤]xİDû†éÊ((M›¦nX°`S‡şòs‹eZÚ6Ñ¦ÄXôv~Q‹íG:Şo‚/œh¥B|tá	)\Éw™[DN¢p(wGØ±ÕçÂB£)¼`¦w”º
ùş(—'?ŞĞòLÓwA’;•IûóÁÓdL¶Ì¿”ãµ&^Œ§èq	VN+˜5šï“F¯¦)YGÙ2mœm°Ü=>¯]	ë&ÇP|8á(õ]×:<—KºÅOs±ı¥½ãè@Ş§P=ÅZ<¨=ã+Ä¼ì(K¦·3è"”™m¤•wâû=ewdçßcVO°ï#É‡ø\×Æ~¬p`D²¸TE}çåí6iØ$uæ
-x^€Y¬âMn˜°AİD?(¾ÑUS~&åÓİu+m[Z	I—ş7çj­1óóê÷Œmf$5ç`Fzı­Öx˜!Şi\.çM™ô“ãe]d?›ñØ–éGSğFêd2¯İä Şòmäå NeîÎmùóhıšÜCj)º=ƒY<Â•)>¦yùÅÚk6Øü,TI6ªÍ7A#M44¦$Ì¾:èÚ:†Ş¶9«Šçyóñ‘œSÓ;ãäv8W¥ŠçP{ÕO÷%£â—2ã:ÅÔ2_ßgg¿İ°¥Şö“# ‘1Õ<œtnMH¢psqƒÖˆ‘»Ø‹mÃø¡å,æCàã* ¢_ewíS­,"„<áFâ°¯È…ùnÏ¿|ë«HãÛÊ*pmoPG9_ë¾|:_AQSâ2P‡h™‡%¸&ûíì•£÷z ¤†ÀÂ=£ÈNH5ƒú²l¥_D‘ÕA¡Ğ
RãOZ«Ò½şbÉ¾ki °8ü+ªarN†`ê09~OÒä®§ÖBı •¸hÔàÓ6.~»e“nÿÖH°¢LùÂy¾àÈ"¨jàÃ	5Ï£ÀSmEbÊNb@µãT9'Û©ÆÊ´Ş¤ß½ù©ÎæÓ£"— ¦	V™7GÈÜŸ~ÏÓìØlyØ‰”RHÌ¥ÃĞ©’:¥rZ,éùIâ“ƒÜ¢c’–o¶! ğôäyÍ"zJ ¹zŒGsîûßbƒyï‘ætĞ®y¿Y¤[#ŒÄ5‹¢®!ù]\†æÊ£Ùò
>›`4˜iv§ËÜ•[¾  íq¶•ÄÀO/·÷YÅ"jm ß] V•»›1Ì‡…gÊ”jéá›(7P@à¤Åã¯É€ğ»;İ”6ï˜Ğ¬%ÙŠi×#Rï@¬Ñ69`¶¬ˆbsÀ_¹Ù/`{>‰ˆåˆõ2lÜaúĞp¶/¢Åq_\†«:¾Âñ^’š*/4`åÍ'gjèògş\uz#Áf§)õùSse.|x~uZã­%¢@È )Â¿Ÿ=kû	•¾ºOThçìÿ€ÕO™ÿ	ÿ1ÚW7ˆr®³lfŸb¥! ­M :ØFL¡İ@!ŸÀ(G£ˆ¼4–XØhB8/·ÉÀµYW-ğZ#¦”‡ó¹ßël¸¶£:p”4<Ò§A&4÷W”p
¡+®ÔÅ@˜±˜&l‘2Ê;Bî–Éò¦äİ`µé5•Fj29åvÇş­0gëIıá(nŒşB›ñ›b5œVkê¢4Ò¢7ã<*ıH8L	#^z°xÜÀöùŸz©ÒÆEß ìƒ9PÁ|tn%j ¾Bİ ^b*SÏ`uœ˜Œ->* CSJÿıFÈG÷1ÕH|â…hĞC8
²Í±[TÓÈcìşè¸¶÷Å§³~ÿÿÀÑÏŠµûÖ1î½øî$MR®©ÃÈ/ı"è““öcÛ—Á]½%w%§>4º—Ü§å)7¨ö
W !=òf‡ §
aºº+•º<ˆ’j9yrPV×G´q3âÇJÊºŠX_êOâó/lp:ºU‰V¼}s52kéÛ†Õ^ÓÁõMÎ
ÂÁß&yáK•¦Æx‚+ñÂ‰†xÌßjş® QU§+Ú\KPé»¶”ÂæÎúLè‚7‚TîG"
÷ä èg·áO´3_*Xô_
b _è1§¡­2Šv41æËe„W=W!µ–ı×së(,¬ÍDQ‡p1•V¢¯ô„P5®#q·»š–Â^—/4x]0»sÈŸñ/­Ïı öÏÜ¼}d¶Tµÿ¦+F2°x@%×®‡—™5)N/´Q´ó#…+ÙuG»@_ù@PÓjšâ¥Sğ¸8(tEJŞ²ØƒÀ!–ƒ/ªã ´‚{Ã¥¶0±ÌcP+^ÑñZµs†Yn/JÔîWHŞ¸gpµãK0cÛ·¿qP	EØïJbŒÎ+0£(!àùh+füWÄo'%8açv–Böğ•rj:-á´?=(i u¼$b3|`døñÿ¢ƒ>{‘ü#2ÅÏ£7:†+;Òk†Õş‡‡ÉO[™xiÅ¿Îa&0“j”$¦ 26RÆy÷\`ÿƒÃ€ª‹ŞÈE‘¦•Kó3×š4pÉÈ.b•kë(`üˆ~Å €-7oö…Õİ¡"²Rşÿ™Z4ˆå)l#ùÅI4ßíL‹Ì7É£çÆ«Ú³\x–	Ä"Ø~5nx~®ç¾­³ÆÕBş{’‘ÕIø«³rÖíèkqÑMğ‰ÜK…ğ/Â/­J¤ÆèÃtUm7Ö†X_ËÙa[k½Zl›b>…²Î¶÷Yåzå€>/l	@6¦ãºÔ
¥ÀıÉëy¤îÜkBxz®‹©Z\“†®5{l.›<T¼~‘”¹k–@‰ r`]$¬Ãó©&GòÌ85G‚¯oX_'ß@ĞXòÿlœÆ>ğHº§
œ»ê	Î¬×È;Ñ7èÅ¹?Ÿ¢AôFƒnÑyrœ3ÙPÏŠsóÖ¯ÇêVnİÇ.lµÍ×üïÃÂJÔÒ›»íLæÜïçò$<2w¤¥ØÁU¼n"öÊ0A‘Ù¹;£´\ s=ıwéË­ğûƒ/a,Ãgó¬ÎdÛââçr—ÜÚá=Û÷¦èöª³e£/oˆ¢ï¸Qø±8ÌçK§èÜQñOû˜ìlÎ_[şO!Ï¬¿MÓ‘¬dSé©tâİa|ÕØLõ|`†ŸŞy[¢Xed$òÿi{n±(CfÍôÜÌ!¢f˜ğŸv)DŸ€Ñæ7'1®jì\¤&`T»Ó­×çìE[…#hÅ”ß[jC-VY¡~hŒ…Ğ)ÌÃÔu{ïâ²¿?4yiì)éÄf4;€,¡1o…ÁÆZja°[ƒù¼£-†dªÈfƒ-Š18+l$Qƒfë>7í±DˆúC¥ 5›ä9¾—>)TAHğ”PxÍF‹C«­íÀó,¨¯JuµúÕ4±;şÑõÆ³ˆ-SQ U¬Ô±íR¤‹@7i&.¹SÇßAø¦È…IŸÚ6ó
€(•Tã(7)­-VAOKà¸½PQ‘U„õ]h=ö‘*ÓxìŠx¿£ô›jœ¬×V±\ º@Ğ-‚§£ö½D×Üæ¥o(wO;Šš°áPÍ#aë>³(8lT Z-†ö.èSó“ÖR'¢ j7˜V¾Z‡Ò5ˆ&/— )ÂOr…%C¹8m£5Â­Ææ€±§(§á`íüAâˆÙ¡_Ífy1öjk6ùøo¡2ÁÆ,Ã·7×i6 
7n½ç««yè™¹ê#ı¶åøoó8Ö~ÖM˜&c»Ù¨°Mw¥êy_,=ş. ÜVîMŒøè“ëÅ$c„„sªå,Şæ,‚5îR<š_ÈÉ½nO¼> Aûl¨TºWk°ûFÙŒCü°Àb¢»
˜(NKXÏ¯ùßÑš6¸#g‹{H®À§ø{-0<#pÀÊm¶±g0¼5+Ìs™„Mn™UX:›4ütœV…¢#çü`9…Ê}i$Xæûùì-¸Añ`R&xkWÆ)PË©…û¹ATKD{[¿Tê—æPÕÔ1dòÉ4à’Ñ»¹¾KÛ»)r³pönÍ0Å	ĞZıH€$œÿ$|Ñ•ˆäy6Q¢
ªÕ/“X7>1)mT…¤uXìÍÇE$½îè¬C“9ÅˆŸ2&I½ i?‚h&óEÄdfŸ÷&®*ê-$ç1ÿ`Û ànç²~^ÊhÏ»ÛL"¡.ÈLMá3}“ö"=×}*ë1ò³˜ˆz¼½(^w\ÿSNJ‹tùpı‘ä®öİÙ{\Ğ»Y|ÂÅ’=sh—Êæ\Xô¥&'Øş}5áiNãªù›ªDÁU}°Ë%¾^>òVÕ@Ş®kc`fÃv ‘¨QÉX×qyrñä×ô*C×èE“ré¡¥|İ•Lw®ö’°&{ê;›5‡;”Ñ'²	4NGØ¬ô *éËû"Èz[ßşËYégùW³4ù=Ì7¤ğ"iGÈŞiÄ€d €`˜Èv*×[:ìÏhCZ¾}5I#4ØTº¯ È£W|E~ÏkÄ—ÂÇÿïÁÉ1–L÷öâ¤c—f+½ø£
Æ±××èÖ¬¶×;˜¥…ÇOI£tÀD&|ë­ Ì·}#aŒà—R+5QÖ¥“•ñÁ¥‰×–"½À×¸Ù×+…x¿Üúc	 ~uøÌ’ò1»¼U*õÙsrDÌ	' =áMæ†2,[“ dwé{‹¼VËP®…9Œëº%Ş¤Ğ=hDå¾>€¿·yy&oÚÉ[¥uøªòÊ”Iôà–÷¬R÷˜®Òd³h¸ÿÑªå¤|¦0»ïk®jŞjïMwÁm]U5¦Äª2f'³HÓ-È§ßºF^Ÿ¤åÄå¦ÑÓ.åBAÛ1TÔÈ‘e8©ôJB%5Oor1™)ßÂéoY0xŞ.ÏÀÇÖ¯Û xiµ´ªEÏD7˜spx’òHwŠÑc–í
b÷Äõ—Í¯óHıæÎM~Z¤ÆçNuèøû™PİŒ	jcØ=¶áü|˜Î3(å@[ÈŞ—	ñ]V¤ŞÅ‹–©¢‘]ë{Áf¡H¼=2=ôÁ›Ş
KG†‰Ã— ¸>~W~(–š|)”nÑİõ!}.¿ËSÇ§w7€ï'<R0HK$•nr[A^“à¦‡•¡P›ƒ#ŸP5°
bëĞ‚dÇ\á“w¶_Uüö¬l½|†SÉoK¶Dc V}öİ†u wÛXAÍ_ä×ôº5†:§éJ˜t›.§§äaG·÷ùÛ-æáŞ7š²Yæ‡–0ihCòSm•.T™4êx8Ïy·…»D‹Æ5ĞDùÀ™
Y“vK 8ÙGöÇù3vy9W‹‡[.£¬QD#Ù/ÿ;F’cqÖ%ó>›–ø%n²ËB”3G|,Ğ^‹„ ûXõÔ+ŠNÌGk?aD÷Ûsèa1ˆCyP×p‰à çØÒŸBÎ&ïøùÀtìÔ–MR6b?BÖGÒiZİ‹°m×Åÿõôï¦lXŞÔ	r|Š&¿lˆÍw·Óï?÷½lŞ,÷6ÏN®9˜úRæÔ¤îæãŠàôU¶ñ""šiYt¤û²!íà®øb‹à}Ù¹ĞhêøûM4)ÆVÖÿ`¼4¢©Øèñƒ‰Ÿê›}XìMŞ†¿)ØN™×•…‚Úk/¹%é†áêJkz`|dç0b¢uç*DEgùY¼[ö;>d´¸€#'cs™g¸ºàjª?îs&±dcÚ{32xC;@Z'¡"’—r:ïldRİM²“øÒQT	™¸,ìÑÿ§” ^†7^Ö‚‰ğFkI¦YŠ‹ÿ¿eú¬˜ê’Æ‚ÿ'`ÿ­Wzâš¶õ¡®„q—CJŒßrÙ ¡ı+´Îò(:Eı1xÒıO66FßØİ;ÙYyêM7+p	+eäœ|’¨íkÔº¡íE¯B#£ëÜT“ÖVezxoÚ2^÷Ö›VVõÉeæ*!¬÷()k;­²>9¤.3Äü¾:é~ZaÿòE´Oˆ7Æ±Ö:÷Ûòøô=…ö3¸À¯e%·T¡-­ğääÑÛµC–v„’U\¸E6:}âx~KBúB?¡Øel´$a:=S¤uÅK‹Q"³¤˜]C=˜bpõ(øşOkğ¯2`åïñqÌsÁ<òk«?ò_FÊ§\³%w~öì»‡ş4¦Ë­noIâŒ†8ìüç>x‰gLø`Ü=—IXëvu`”ÀF-_¯"R°Íî¬¨½E+û°	½ÚÿÍm+¾ZjR™óÑø›‹Ì¦Ó]Œæõf=éÔİÃ¦}n]C,´ÜñùÔ¨¦ãL]v¯+!§jÓ¸óÊ‹æ‚G›J/Ù€"NP¬Âaˆ~?¿Oço”H…/{Ì+'È¶•L\7ˆµ½x £ã)è‡dæW‡H-ëšÛ{­!^˜Æê:½ëhŠ‚†	b†+|pÑ‰wğÙBU#9ÍGg3·!2»†ºá„qŞ_Øõ‡¢Ø‚é¸eyŸáº°e|¯®Y[{éÖh–„#©~|<$èûå‹£m$"âíPˆ>ßÖÄâ™=\Ze¥º1¨"3úò<šØÄÏş\£6ÑèóÉ„ƒ÷¾“ÛHÚ$mao»OÜU3(
d•İôÁWïÿ`Wàm´aYB`BeWü¼N5¶l†cìøPêT_¸ºN¼¨èpJhL‚aßø%9’7÷üQ{x\¸&X .4õ'Dc{Z0; ´~p˜¦éM;].ôˆ¸M¹¤ÈmUàõ©1ç6húÖ?ŠídS˜y‚›xve%M¡(—[q§R6C~‹Ö×‚½Ÿv*‹t®¹ö•cD`_û³µ:áwÕÇÚD˜8—æ$
û´ÎqF¹uâ ›uİªäV,Z„îH‰šøĞ‹ÍÒm6¦+Úf¦X³£¶µezg æYdŒ“ŒİNêÈ·Â×ª%´ZaêÙ?«˜ÓóéwOÕ†"\©f”34õ·³à®“E£êÅû_o~l@ıİ‘\eJ‰
ú5= éğIÛœÌ ÃvìÈÊÅCÓúÁ8¥&R|cÛ»Ò™Jk>§ß¡Éíì°ˆWô¹£‚UÀ–c“´ ™7ßOÒâ€ò¹œ÷ºA2èÉäåº7óÙ¢Ú6zÒîópó½è9§…èV7”RÙ4¦[…ˆnÆH£×ğ+´ í½‚¶™aBù_ô>[_&E=<éÉåPò÷húè˜©IÃk°måƒrdù¿”1h•Xïé°™XjğQŸRYêcŞ6Ö!Ã#ånË¶;Œ†Åc ’plfâ0#‚À²N¡nM°:Ãpö’Ï#Ó3 :ı?^©,Ô'–Ü:×ŠÈŠº­:«]ş*ièdj_•&ÌL7O»Uã“Âè‰Pî‚»MLÔ‹·gK1oø&ÕWş%âÕJ*È-Ïÿ–Ùÿ¶`Ôvë­€n¢¨®~ï³¬hÍ½„ÇS3ÛJæë“‰¶§¤ÿ¢ºÛM-«n°ki”æŞ4‘w}^^Û¶ñÆ%D‰¿!ÄH7¾_8£x¶AŸ¥•5GÃ:€÷Ìgà_y¬%êÑM´,œ7qòÕ›ŸKPùö×ßÛnÕÿ±íq~ÿä¥½„tbEk°/úyq%võe{¦…Sºæ…£Úç[Ğ7ÌËRèn…ujT(pêKzìM8É’ˆ€›+@G»;-š(£X%ğa;}fˆ¡ ÙÀ!É”Z(ìm¶Œ{¿VïêZ:’®ãÔôÛ±ïÉaÕ¡x#À
›Èfz?GV^Å¬¦‘Şqí‘»çŠ•’9x£ì"ßœLÑ{ì¾¿lœÔb;>;Ié6·±=.]m}N@¦çğ¼‰¥¦Ò{Xâ-Å
xqDÍz­‚¿#0Æ=$ \2³çCÕÎ ²4îC{'É¬£›i_Ö»ĞÈ{³õñÎöäÿtGõ’ÕÀYpQxl˜Ä—NòréDÜ®ŠÆ
³’iZÕŠì]ô„©c]õS—˜ÏaÙ{¯÷Äûwr6¯äÎøk­áE~éÍ„8D”‚¾Î7Ÿ/ğ§‡jÒ“yL[uïÜH²|'•6gwZ‚$n‡At”x&½-ü’„¸)¶ó£%¥›İ#Õ^3ñ§XÊëI7Œ~YLQ1œO‹Ír¶ ½>*fXA`Š„Äk¸ÄŠ	–néª‰Úp¿i!¶¿=…)ãe(G	Ó~ÜáØ‹÷"‚PæË²qwÁÛ4¤%ö šV Jˆ\­C9\
zØRì-ÜÎà^×ëìı¾ÏHg%”sRúÒ²Á6%’|…hTˆYßà\›€¾xÄƒ·ÆâCÊ2šéHÅÑ›p¿h±ï £ı,ÿ¹á¡Qª£ë(åw•CWXª@®kYZ5e­å¤2¾¨<¾•ºlõeÎ*‹Lì¨©ËåÛ\3°Q£U±GU¹í°iÎØıR,Äö3/¯,²®ˆe Î/Ì¾†ÕlİÕ„W2íC&Ò@’ØÿXñ¥böLÅêÌ–Î’¥—ÀĞî*<r?Ú°Ü²„i©l;§8)4N²:`/XUÀwUû@âÚ¥òÆâ±%Ş¤¢«¥û-röîí€N”æRv•Oü9÷±iıHaÙ9 ­³êö_†šmêù“°µçò<ƒ3-´°è`}W'Ï4kÅÂ F(é	J~^ğ‹nRé:˜p·Ün<]ZËØÒØ]Ã1uÜø —º/‡r”`¹ë	ñ?óÍKûºˆ’®Št`JnÙŒÂ¸y\……dıªlk¡2Ùgv¸Ù$uÚÈÅÌ""GÎ—ß»g’ïb¹¸ëò¯‡¼ó
ÁD|Û|Ö±º|½Áï‰ê8şTé1«­´×æ¥£ó£1ÑGıß:Ô.¯å6CÇÁNµ.Ñê$Ó©’/Y!¿ìï¦|¢y±\nNìågPäò>ƒç÷e~Mõ“¦âk
ˆÕbe5i,hyL/AË :›A£€¾cıÀ©Ä.f¯œÿªÌqQ¶œñÛáŒ
]Ğ¾»×¯åÃd_•³sG?o|±x7‡´.kbŠ`]òIƒø„ÃäÅ6éK•«=?Ğ]³hü®Ì0#–«¨ôõ_Ş°”Ê¤0óVhWêtÅBe4î%3#¿+sĞ"¦²
ëÛ“68hWÚ¯×¿(÷wS/ˆ_!ºös££¶ÛéãFAÿy@¯F‰D¹ø•uTØ,îZÏÒÊwïùæ{:8dßDn~Ä3¤´Ø`Š +u»ØÑ|1`}ìca°ßøêŸ£½önŒl{©‘=Şã¦i:
™ØÇÈÛ à\wü¬Œ]R¬»™nîÅ‰Ö-Ít‚©(âe—2BÆ¶øç«Â±åR©Ê€…h]q_° ]åsôm½F‘T~±¡ü:ü"“Ñ!.HG‰^níW„ÓlçéğéÏ4òJl˜zâÃ€)è®<‘š“†%è°“Ø‚å°˜+í<Æ"+º¶FÜŞ¬)­úH¥ı·éÆwë(d-ö?x«Ÿ©M…:}tëFÇ¦îÃ¯™[{w)ò•ú”³¢ Ô
6«›–g¨·€Î„ˆ©ñÂBœyd/Ğ17ëæ
 ôÌè	8	³¹±-¡øeÍVÆcpŞ×ˆ3âù;Pkkî1wmdwÏÂ›âš]C±ÕÑ`a5:?°°Å$ú˜{	Ê@¢·­tr2¿äçãÈ>|°;ŸµóFp6™$º¸l˜aˆ,òJááMË€¹©r÷İÕ–¬²sûˆæ%3¹iÒŒ¨¸qAm•³
¡­õğa.á^‡öæ‚uA}œçòÌ¹5êQ1[Ï5’éíŠ›6ŒŒi¤=×JØ 	 (ë„´®Ò/`™ñDH$Ë¥ƒSCè{äÅ €8}Æ‘êÆ¢Ÿ•â7¯!±ÇëÛ€4a#<SÔBöÕ’¡·rJö–×Ñúô–¼ÑÀIğš×¨u¤—¤
Ë¦:•<JÖAíôWTuœGQÖİ=S¸¿ûÀÚ¼}“ Ÿrø›oHŒÌ…6¸¤Ğ¨÷‰ñ¦œ/2SøId1ˆdFñZ[¿ß°‚F(zÂcµjXÛÏ1÷î)‚DDÂ¼êb‹éoá“|f•Y«^y;m‘7gMîVQfjv)¥¾ó[0«†6ÿ9nk–OkwD@ZdXR–¿ÂÎ¢ıBB<]¦6hŠ!*ã4„/.¼3I¡£yãÄ“ÃÕ’P@r™f3ûQ‡¨¿šaŒ4T1Š€òI$¦1Õ©:e²‘«§
)lMûXäÇ ¾íX’vnêdf–õù‘èPò—YI)šøù=º&.î'­+z?c@òÙ¡wĞÌ|¿D6Årt—LuˆÏÈ¬ø¿–0ÓÙ&F¾’†J8ÿ™*ü0Å(â)k¨/Wé‹ŞOö­@VÅªn9„ù	„®Ô¹nâ9¦úT@óíí"Â|ÂüÒ;AYâØÙJ?!Ğ6‹zÏ.tq2­ÕM)$ï¾'Ïì*ÔP‡¨+[D£=C„ùÄr§š£&›/69pÈœ¼Èwl['“jyV ×ª·–ßRò09âÑÊ¤Àz:__Ä!Ó @C‘T8G%ø•#GÕŞ™NÔ#@ıB×SüQî°ô¡Û8RÆ|6_ ;Èà±V àêŒr‘]Ÿ³â{Qaâ/?â&å©stşS¶ï
i õ„1Hæ‰%bT
DZzör=]Ûá"¿¿<İëëÇD»ÇRñŠ
R²’#IhäËlR‚¼ÌòÕ‰û‰Rw¤èÆk’^Ó:F»ğ­p¿2à¼‰qTn-À–»e?à©†İc´‡ğû²ÖGß‹Ô¹êímÌd3rÄÜ3JD›7ï ÍÆ±_ÔØ}•d«X/^¡ÀwÙ<tF½@hÆAeœUw(M ×&J$]U‰Ã¬êTĞ O½7Eû*¸…:ÛLW‚iTüíÂ›ÍLD«Ér9%n°<Â/ûPo?Îøû²««Dós±ë²V+>W»Ôğ1Çh¾À©òXü9z-0 V£­‚Y't›[ú×9c²Šy•GÀk›s0rOy|ƒÄ…J|¢_ Ã¯cv_¹Y™¨ş‚×Õ80‚Ì%f0;-;¥{öşúU—Ræ”îWºì>À¼%.ºè3;óvsÖVîWpÇß‰},V;Œƒ™Fç…Î7ÂÌYDú7:7F#5²9‡Ú3˜6KÜôîà1ş:Ğ@´aÕMØMµÒºb¤Äuz€7â9ó£6#Íß4¸¨íôd*r‹Ÿ¯ÖnĞ›ûYÎ“PÉD›ı2Ìh£Ì†Á{"¶ïjÄ{¸wfr#Æ^UÇJ:Ù,6ªä[­ê<:¦/[¶ewº®a-é¯(„èÑ;›ıjÆÇB1 ÔBŞ~b~Š’XÓçb½Õ§ziÌD¥t¼Ö{“tl"P€n“ÑæQ=+½e…òç‡İbËÉÔ•wd²'…³£$ıãËYÂ<-«··Ú†¿T½k™…áEe1ğœÆÌÚ¨Ô4úó\e·mŒÚÑÕ¾`L%Ks.À3(®\u¦Õ(ëÛ¨Ê‡¡Låİgg ÃBßXÎşí¾„Ægœ¸Á86Æ. ,F=âdÄÙğÎX´ŠmSÏˆ!kÄä=HC¨8ü·”“m°X~ª„ŸÄ´V›3ŠüC,É>Ii“l¥_b×ôà>Ïµk)ewø:¹İ&g^®+7¡y•¥”h©0Âk6°ú«Ù:ˆcä^4”˜mÎÉ­ep·¿aŒWP4/hTL®YHtßë1^Ig[Í—£" ·zÖ8çÖœ*Jş6vZ‡gsuC«É@(î
c\ågka@ˆ3{<bxBv‡¸ç^O¹»ÚéÇ¡3ÀS!Öå„iopV8|˜ÊÛò¯ğ’‘?íyb L5¬ø\ˆphÆu‡Âö$.MÜh;TR¤t›Ô[1«D§	¤õ—4m‹›"A`A!÷j7jÚ!u“ÆürpX’ N¤ƒ+¥|]14NHÕÇåşÊ§EÆHÙ$ü
œÁA*,Nâ¸ĞXv|Ú	D²†íÅ”‘lŠxŒ©cƒ˜ÕVÀ×fAĞFAå¦ÿëº÷°SÌ=‚ŞhLVpÜ›·Væw÷fJ!Œ©J£yÆgÏk”•1v#ÖjË?¡5œ~#¨G‹ûGò{fÄs¡æÿZjŒ€K5Ì“ù|×óã·ô$¤vÇgAE¹R–eq€P€bÇ´×›gÏ6wÛpm3‹Cã´b
Şº—İn4°çıŸ±şXKÿŸbŸ©7+:jœòØÕ8GYÀÀ‰,lÂøá¤–ëÅ6l›X”®ñšÿ¶/÷'0Ôİ » %±ÔÓå¶šZÙš&ØvBìñuuòƒ¸½ Ìm	Ë@iN‰™"¿”j™ûšdõ¼:[ñDM1ıè%:mÏYßH»­Ù¸Ä½±°ÁØLnÛº/KJDw.yÓwY;Ëû‰_ôH‚Ed~pYŠš¦>²mD¶‚dN±\1Ş Ø1¯ƒc1Ó(¬r;Òt8­EÍN›ß9"í&Ó S!ß(cƒC* Ø…÷ÊÜ¦gjQ‹'Ù´EËĞkÿ«EàU,DÂV†âè·%z¶ØÁ»¶-Î:?š]7¨]™šC¦0ßĞCR^oRù£ékÔ,ö¿ó˜ı*¿` =İåå-PÛš;™¥İ»äM¥‚ûU ÕÆ¿™2V²ÛøÜ“%ôÒ:ÊŠíå`„]Ô1,šÆ<˜ó•~ş”uYÅ‰²%‘¯áæp®è-ñŞ³æñÕıæóI·–Â&p"íTø´0^y ğ<ua3`°+şé³áÀ„Cy4É–|‘D—i<õbJ®äTQïÙ¬
?ûâÚ4à×[;QÖÕ¼ÜM¼¦G$U»ø`™H§…9@ %¿ÑÍ
3²WèÇË/!ER)Öİb›V¨É9pÕ ‚&½ˆs<#\÷ËzSy¿	¾ª-–ÅSÍì ÿúîÖ_ôÖ!Çó½&>å`R»q–/Z?c9É–¯e‰·åZâã¹‘4‡ªÆÍÇ…LÊší)¾Ö¤èpM¡¶$!à¨Ÿ»»ZM1õ¨Â›ÑNÁß0“z8ÿÒ¼î/q9’	Ï:BaJbµW8MåH_(lñm…“]cø«¶±‚Œ<ÿŠnÄädGuôÑ¹ÉÛ1ô·8µ1ïÒï›­"ÀQTCEM7]¶ÑŸ€H[ºNŞÍ‰e¸¾Ùl½è—=îc Á“ğ’Ÿ³„*WÎrµjTó]R ìCĞRœÕ˜ò©ÏÔŸdi;Îï¶K]ƒp9½}ğ`a+­£¢å°Px}ˆDyÌpçÒÆ4¼çc0Ù8ªñüaL/Hï¿÷„İ=P"u[>’-FÌ;.P—]\wüÿËgL—çY&¢©gÜÖ¶ªÛŠWWè“hMç@ísç™ı!n÷l¹ë>™¦$›Í0„>-ÔÑUÀ±æz1îû/cL‚U0ß—iš…¾½)=²Ó€şÌ¤uëâŒëÊ('ğêÖÆ µzjd{%å¦º'/ûºî­ÕùèÅ^³¿AİqåÃ)ãÀ–m€Ğ}bÊâ%ƒ­êà”^|DÙOÉ[W¬1p üØU‡ú„Ğë¼I©Ç´ìÔß*|n‰[!;¹Tù¨‰35q""B¬ÓåjNÔª“K†/eqüq:Å+xæšÂÆêÁë‰ ôÆ5XâXC°wG°°ÏOÇ[5oEhEKói¡mÊÈ>Q(ú“yÖÂWaz”Ç,q7¼ˆøüÕ­)îË60VµêÁ»„;#d<ßI”å›î:k¢æy§h‘Tóˆ}KêÇAÌh-âÏvöşìGY}oá;xy]}Z¡(:k'× IÅ¶14!ë¡e”øæ{ìn:X_˜¶ì=¼~!=>ß8<¿Ÿ¦Ußc°?Œÿo[b™¸TQâ+,·É»	µ‹ÌèF¤sŸeâLc‘UB&¨à(ÍÑ¡ç\ñ†yº²w2>za#Ïù¡XÃáØ‘İ–.kk5ƒcÅ`ö€ÇÖ›A¨GÿJ
ôgÙÌpËï‰òèj£î39
ö“]™¿ñã~öÌNT‰À8 §¡‡ZàÔ ,aªí'ë²Áf2´ÿ€ù²î¸Ò=.³mÌ]‰mğiªÂs4u¶¨!?l´î'©ôÅxW£€—nfV¥‹î¾‚²¦AÉZ…sàÖªÉïÅµµCSÙ»c’Aâ×§ê@)<=š«?rÛÿR%Ú­¦£Ş±Û9æÃ²D4¾µaÇD±+Tvı_Iõ¿VŒéÉ½ûNø·_ähÿÚƒ	µ®³_–bp#•<|["dŞgNH/˜È,ÜG®›$/&qş¦ÍˆgqÓ^ë^©sÕN¿ÇNhÒëƒhq¬M—D¶Ñ‰îî©Ğ®"høJàI \6ÍQ´¶b†@˜ìØ™î>1×'ËM~h4&˜(üõÇ8a8tÈw¼şê=0ºòÂN¥‹CsŸİ½B8ŠİZûı]àA>ÒÚô=Å¯lbC´:Î9Öò÷(BE>r(æ«!qü2F³	šÌ¾Â¬äXù‹k$fÛñÖÒÒjIUa“8û„ÉSFÊöÒ+i16Eä‹n|wA³€.ıç[vñwVÜûÁmöP•ôzËÿ¾Óî·’PÚ6ÜÀ7½ªˆˆ,yÔP5ÇÖMB¡«I5ˆáº,ìªôæNŞ•œæÅÅ«†î¢ƒßs<v9µ ÿß÷É½l¦bº‰yşw/
ˆ1Ûn<À@„€ÙÍı¶<]åÖ˜qBæ{.ZŸZé;£t3O?^-Œ%æu¼…úZ¬º2o»»LW¥J×{r¦•pš§Ú\1è	?í?<$ù«É–·h=æ°q.—;Ë#Ô¬ ›Ø±Wq"#²xZ°-bálÇÀÖ¦f©Üc9+X@‰T»ÂêÒ_Ã½’ ªz³n¡åW¦­Zhná‘ƒòìM¹+-Âáf¡ÕM™›ì¥úÁÒ°yßĞ£¾nŸîi.aXF¨Ú§Ò×íÖh¥z5Tsğı.ˆ!úUî3HkÒ‰¬y$ÑÍŸÚ>:cªCGô˜9°ü«v¹—0—•ßğˆ)Üñ?¢‘VS©@Ê²¬´¢.‰GÅo5p3<¬BøJ…º'ù³9ª)ëÓ^1…"“²÷‚À+EB²,x™6Sm°W#İ«“›÷,\…–8ÇZŒ÷SÒª¶T«¿ãÁYU*_w4*¯(÷æRÔ0i×@§)´ß0ËF„%qrh>ü¿|,fë öó o\ç+èù®ª€+5
<RÚêcÅI"”>u;ø4¤÷tby‰â1`dfì)+À–Ÿ§ôÂé]kÒ± IØ—Ş¶›Iê@Îí?w!Q×÷‡Ğ @øöÒYÛz{„Î!ÜM=ª¢’"1P6û‘}äó…Ú1õe°µ#©ØäTï>ÍŠÿuÔÖİĞE?Œ‹ˆÆ"³2it¶®äaŞîJ»½ëè1çÔwAÂŞëE”§Ç\ĞªY«}ótF_Ÿh=s™İA/â®@‹]z
$DjøÚu£Î;sÆ÷Fiz^Èóòë"§%'§¨ÎoóÚ±²¶æ,"vô+§­µ{;¢¼,İ§ã¯LÄ•Ê-|_‘u˜Mj„²1U{ğù‘~T@µ4Ê[‰*@OxAUŒ4¼÷ŠH7ä·hhÉa6ĞßŞÌ÷»~\>èĞ¯“ĞåS¡³ ‰!&;&;*¹¨§´[âŠfE™fíô[¦˜~’ö|jo“NÛB‹­ÙNlõ÷Âó/âX¹İ‡¿¶iuØD¶›$ÚÉİlàH›è8NüõVŸ]ï±¸ËE9é|uù£fS¹NüO–af¶½´e¬§ÊvTÂPÆß$@"j>Õ”Ÿ@¯h±!öš:oif:39×…XÁ)’3fİÙÔQuÄ!<ØßÑµ…EØˆ`³UàvcÛªİÏ1/5/WdØek7Ä£ˆQŒ„Êe¡}w±´|o·¹ˆ“DV¨eTİIš`#rÜÇç¯ÈJXÌŸ ¶Ö$?Ría!Üø"üÌiàYÃë’ÁuãÙXÜ®•I^m¢FXf$’ÆÆ{çºbpµÌçY—¸µÜ®íªõ?ğZ·Øl•{·´ŸF¸rJè:øŞiå:D ®ìŞ/¬Áíå6xƒGåc}²ûëj±PòF”ÃÇ~5#9õïÙšs¤éŸöM£èzÕjÃQR%)^%‡×Å)ãß ƒ‰HÕ½¾c8*‹e’#ì¬1Î\wğ™î‡Òk~LŞGV"øÅ   ˜²¶0–T †Ã€À©±Ägû    YZ