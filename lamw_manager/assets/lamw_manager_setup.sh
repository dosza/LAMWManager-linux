#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3900370764"
MD5="4afba1e80713d677640d0f0d6e594913"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20300"
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
	echo Date of packaging: Tue Dec 17 21:31:39 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿO
] ¼}•ÀJFœÄÿ.»á_jg]77G13á«Ñ]Ü%ê„gcÆég³VãsÛZ‹È—ìşŠ„]´7Ş?Ô T(ïæ¨Zjå~Õx½éNv¹zKñâ˜œ#Œõ0»·ÓìhH;z%=Ï8ˆùZ^*À}€ ™>ˆ_m Ü•#Z:L o4jQY½BtçXÌæº"?îÏ”0öÎÂ¡ãx&H«u‡r §É›îI¯<? )3H'w†«£c‰¦…á{|^WpM¶~AŞw+õE(ùo—GÏD…•ÄëÔƒÆQ4Æ¡50î	ªîğ95=Áİá7âós¨à!†ùœĞÅ‘~LVã“‡üP¡O¤ÍãÏÜ¨©Ü`§v¿vë¡ûnØŒÆÃb$ Ro¡#È¼wÂ¥¢â"¥]ß},µy»ÒO¹Ñı­1L|nàŸÂÄsESŒ»Zo;æ‘¦b¹,³°Ä<ÇófUŞ	\eœ@>¾Pí÷·-rù8ßu­ºuX\ø€U»ÖœÙ€¿Ç¼h­ëª¾‹#@å`2Krm9wˆyüè¬G-—h2®öK‰Ø¨È;Ë.¼ıÙ´LŸä@¿yº—›8GZÌñehœög²ùËúé·Ş«%ş\_;ûda~#à¬^^°¤óJŞÜ/£ù#ÍCe˜2æ¹å_œáò d+ÕƒÃÂ÷‘¨ˆaøé8&³A‚’Gøßß¶ˆ&QÅ·øG1£SX›Œ Ÿù(A„°’—I71²‡ÀºbÏù_ıG	Ïà;Ş£Í“xÌ1`òÄñ´	‡š—ô€ñ$ÍDl¡b[«NÕ¦sÂâã1C6uÄK-k²Íz¿Ÿ½9ˆÛCT7È©Ëf]Õ‚7ÇßšHùğj€®2/2Û¯çiqŒú˜å£Ùo=Ô´ne^Ä— ô /²^b·Ë‘AË¶ÍÅ*L1ƒ°ugp $-_ï[!ekêëÖ4Œ:¿_©³>¦Ø°I]IDÁ\¡:Ä¸˜Š¸}X¸¨É÷LC²Õê'pƒ{{1ò›ëXøË ÎğãÑ‡;Ä¨úœjú©®¹4V¦-ÁP–€³Bá°ıUİŒEn×êA¿W¸%™@d:µ<Ñ`Ü}ˆ"3~ĞBşŸëÛªe._j1§,qTïQlsÁõ@).åáß´º½ïVŞü´¿ØQ´÷Ä#(±Ê¤é]W™Š£1NNFàı,v:ú'}Gß|GqÓzh³”Lô¥+·ñÆ›K-qÕ¦@‘íÔC)ìâ@ÿîùè¨uQoõ…s-s¦63VD+şÀã/.¦Ì¡<ûdò¦
Æá˜<ğOTÍƒO^iíâì8i±ğCX½FQ9qb¯Ó['Ü„eúXrâ2ßÅ=‚è `HlËì~,vÓ¶s<—uõ¢©E6[-Hp˜PÍá%QHì¥ÙYäŠ² +¾xY"%ùéÏ¿MŸ_.Nè
1£.BƒÃì÷òŠ/¤^g²ĞNÁÜnş~Ô‘Õq&(Í
½´4½qP6GzÄ–1$85® `VEtxî¥¬¢–ˆA¢‹B=Y—/ÄÃ]­6»ÁxCO:­ï÷¼Ã¥RÅ‡O.$·
OÓêŞ5óa†Ì€¢ÈÉ½SƒïŸDä º|½f‘”¿óƒñâœòˆWİJ¾û´Öé#PŒ!·Cí¿`ìİ¸¦® ·‹õ×J@…‰ª›¨çS5ú²]‰”é”ßN˜ÑCĞ1E<çëì®s–Ëb-ÊZµÍ%¤ÖL¦7ƒ†DwïÈnk_WäïÑKXá—;R #e¯?Dôâºo¦¶ÃÌc©VÁ­îC_xlˆá3~À›#-NHzÅC¬Ã†ßMØ.]ˆˆW£ëÿî&â=¦™ÃJ¨°Ä·¿¨	hİ=t•WO&j×ßÆ¾Ì¬v€X´N¯¹6á	ñÔ¿,:Vù™Ôx·ş³f<¦3yMşó	ı¸VFñMÔt0Ïï0YçŞêŞHğfR÷ZwFÒqú;/¨÷â¾4Eı@GÃ‘öôùxºÏ P¦VÔIş³;¯¶ËBİPÅÛ\"s~Òv«X#DIQ-0˜©¾ÀñÂÇ¬L![`ÏöZRßÂ>ò˜6ÈÚêRë3'‰Ø"ğÒ¹é7›å)^g^*çõü>à|×7¿ë
,Ôf<¬ºh·öø)\Å©^" 
„mŞnôÒÂmš\ír»áöNñ«¯G¤7¡AyäP¼³ôWXScİv:aîKD“¶~ídgíB/z‘•Ô™…[Æ/ (”ÈÌÇ½wu¤f8g7ø!SPNº•ˆ»rı˜–ÂÁ×SŞÓe&åÕíúZZ‚Öğ¬VwXŠKÚ/İŞÅùñ¶Â{fµtYXë„JĞLŠq3vû™øÃæÀˆKGKúutÇ_ÇhÛãïE"‹î:¢)\šo~L¸üZƒšsR	%d³ú=»D¨©5 ÂÒ£ÌŒ#Uú¡=µVP÷ÇòiŠñ›YMEI–ŞD€á—€·–(j½­ùªP$Nó­WôPéWêÑ7i¬Gß‚ ¿2ª÷ĞØiÛÃüÛØNˆz‹ççLi4kÜv2@•láà…åv[Ã´€öË0 ¶ ºôfê]°‚«øÓäM-=ÁôÒÎ’ZÕşµS6()œ[!XËÃòòdØ@Ì~7boSšBë	‹3{ˆ#÷³LÕ9Æ¤»<.0Îò ÑŒ,Dfá²°Áà²da>k@Ì–î`™Ü¹Õ‹R&¹åÆ:ÈÉ·Ó²¡?‡íŞìá“%>ş¼mC zeä†¡0z4_æ¿Ÿ·ÈQiÌå7#ªqÜñG%ö³”³¢¡¹LBÖnqqH*z\£ë°
¤Í3?¾3ÉVLˆvµ³µäšš,m™äli‹é§âá,ùxçö®ÁSü6„j®]¯’Œ©°Ï0¯Ús
ÆæÂ†ğ•°+…L”VıSáE#İÃÙW!ÍÉö
íuÿêœ„Z¬´.ÒføÜôì·U0gj<Ö}¬­¹²´Ó“úèÙ¢šu©¿IÜ½ÅbáìŠĞÍîËëY2íâèI
òQ¿µ:ƒvÃF…3~À­ô„K@Üè h aªyëáel×@¾á/nØşªˆyáuÿ„.òé?HêĞ,Æˆò¶hK˜‘€õ53kÖµˆw¼­è×ó1ú5õëã¼ÜOğ¬Çƒ›7gÆÒdÙÃ±!Eã1/V±¿ur¿}#UÀª8Tîtö’Ñ7Foãäšj¼U,òˆCƒ¯ë@d»^6®Òxàú0äøBÍƒCÎ¡ƒeÅ¾ĞZÊS®«‡z©¬gïxOŞ…öíıÔVªşßşÿ"^üó^jE*Zcwß¦†‰r£åß
Åö>‡ÿÕ­ßFi–PšzÀ÷×o8V’Íús™¬¢ó°/]L;Å‚‡ÓİBáøxánå­¯d¤¡ãöõõu°.uHÿĞØÿÄq L¯¡”<Î¤zÿjtYöÈ<)m!UaûyF ¬ŸB	Óel{şÍtÑ(o÷k¾<çÁk’ÿ‚Ë½·;¨>ÊóÎ:¶}¤£?…€ã°øÀ'…2„;êÀ+¡[«áÅV¡m-îw—ñ>ßI0ÇˆŸšâ…MA,ºÙnf„ÕH\ÁuOŠåYê”`ô~Xø{A©2L26Ï Î+#É¤2ÇNn®9¢ j%ª4àó<°…ŞßbÖ‰,6Èş`–å	ß
Dğ]bÉÑ¦ÂıN¾•k?·eÿÌ¯,ûpK¶êzWÜOú"_…ŠĞlwC‘%Å[ïğ™–B±³[ Õ³U)A³12“3ß½J<gJ.¢ğæïõÀv”ò=÷¨G «õUDÂø%,	Ë<V³‡Ä• n¿v–ÿ›ˆàét“¿W\˜àäofØF~Mç>¤©\o—Y¥Bïn†ŒBnŞpbî\¹Êr•M ŠÂ²H$ü"€b^Õk7v)Ğ[›w`—%:eÉ;{1ë^¢f„¯É?ö ˆìº;rQ|¼Lb_Ò”Ag»zÔSkıãäSTKÕş—&NmÔĞ'é°º_ÁuºïwØŠ`.‚Ú“^ôDé¨3 Ã‰Š5¸OÜdÔ·Õ%eÜ[¿N!~•­ 
”
<LQí~Egå”õšàG dŒÎd=V\XZ$„µÉ>G=«uF8LxFNØO×!x4Hì8Â9Œ.	 ƒë~°â¤™¶s¡lÏ/Á\lÃQTNıfeéeXHIFåÈ:º1×*½éí|3U‹Û¿·"/$©/ê(AóÍªÕ–Çs€Ùigğ%äş–«‹•Ÿ#;ìÉxá±¹Ä-³±{oB×,±J'ÔMDU©:÷âZÿÚi]Ë¿‡~u7ä*G#,ZùG¬Á¢ˆC;eæ 4°vì‘Ä¯)ioXí™Õv§ÙõïğDS'ÛSüåuw¦M¤ÓÓzM³ê=?ãÁjÃ"
o{¾È¦s/ÎyUËÅÊÖì[®3CQ©ú¹"ÒOäz%£êïMÔ¼©x¶Š™7Ô^,½J‡û¿CÃœ5Ã¢>´‡Hàèäín»DĞd?ü•"oGEÔˆäïÉBü@t¥QI°½üÊB=nµÏì†ìæ·ÚÒ¹äRìû‘‚áÆêpJÜ*¡S½Üû„Ê‘:i¹ä sÏgq.¤Ë3P$•äTøÔÜ5{FlzX¾ZVÎ`2W±ç`€"hşq€Ğ¾È©işi*Ì'A‹ˆ´JÇWñM¥k‰¹b&KÍ‰¹{%„)Èï§³ §bmÃIV‡/ô¡¡R3X›x;67n‡{¨Ú&
¢‚Ñ ø h/ƒ±ŸCV¢?|'¡Ôk[â.Öşbñ0ñú%$¿¦)±¹7Y@Wá“ûs@”î¾m§ïK™]µ†K-V¦—j¦ß
¢‡¥rK¯Sš.„97@%âñM§Ñ@÷OÖu¶¨*Å!¢À®OaÀ(÷‚İœÍÔkç1ì®à÷G%x€÷ÚåßÜDd¯ñXòÏá.Ú>Ò¹Õ‹YuÙº‘¶˜‚–d7xú‘‰?¾C‹…©('ªuØ‘~·í.':“j7lWI³%Şw•ØWÓ#ç}ˆçÃTõ¾9¹m:„Ëfİğİ9Rˆß½nêİõ­ÊŠ}Œ Iò÷ğ†p/76Wç§äş‘}÷ò›B/Šye-èc
P¯
ŠokÙ§LÅ¢®—{~¶µÑ€Tw)±MÁá(ã ÑQG¦;šD•¿ö–0¹
“$¿zÌ•ú`=A%fOIÕÊMÏİ!@‡ÿ;ğŠ@Ft^Úâo
S°«{t{ù—W]8=%¬c5qÑõqlñ­ûÓÏÁ©!á-›mCÁ(FY¿Ä°úØ‘!4Èä\¾€Ã@ï Î¿é²[é5Œl,7ÖJú{ªoÁÉù{Ô´ğ$I¨”äOä`+9Ù¢ê4±s<kE»­y#•'ï†Úş>_”nûÂZe_üoÛ¼}ò_GdÉ“"Q3Õš4P:{ÔğÉ«;O…²9ş\˜Œ30@]è ¨dÎ {Å! ĞZgS©JU·]6Ûq½×œgó_ñZó3Oˆ“¾à£¡¥û´Ice‹1q(Å4@)XñÅûb@dÕ2¡"¨‘qÌr­ß–ñ|vé%‡ÒKßÎ¥[cXcÿs^æıÚÜ‰0ĞÅ©e·SYÿIèÄW>İkÌ“.ÖR0Kkœ«­p	Ú5§å»©¯µ'½Ø ×¤ÎFÇãD¥:7ÿ}E_8¸·›ÕÍ”ïÿ&0ÍÉ  ¬[pü–ÊÊ9xü T†÷®0T•\47gì€GÊå]úÒ¯5ã¶ ±ì ˆ³Ç2³İ2#¬ªekƒU-ßÊ]ÑÖèñöû+À%ø¿
¬ÛıFÖ3R–Gã }™Ål={@3ğ_Ó A¯–¥êYÕ¥âiÇ„•;
Ö·_Gi<‹4‹“CZ¸­SK1Qz{¹RgV‘ŞM,f/é6B~Er–Hp	ÃI‚cºP6È)„À¿ÿTI3)]ÔD^³À"ä¬GsBu,C!ş½ïø·7“‚s"fƒ?…ıñìiÂ³Šu@¿:ø0`Æ‡M|Ú0BcBÊ¿y?!æèå…Ó‘#­ìt®ø©JğFÏAşÓ½XŸÅÚnåMIË‡×ºÊ£‰\}S˜¡'?GÓ{Àq}{IŠbwFŠ¤éÇw°²“5^88Ú­ÙZu¤*§fÄÅv1ûlE7‰İ§#½Q-M‘CÉÅé9ıÿÚş?…Eî@d_BÒû²7eõ°”İÈ:Öây"a`©%ğfT£NS[Ñ"µ<Z§ùB?5‹5~òµä(…x–V…pVğëºv™Ù_…ÕÕº§]˜tÈgOÛ®F— øjA¶-¯JÒDó¾q„4ĞvÇí™ Ét½ì¹„
÷ÀìºOƒI´Ë©­o%ñıÕ¨Ç”Ñ«ï…[M+7&’SO†ø¯ÉWÃœ]¬Ù÷!| ké[»Fy]è0µú‹ßµ(1óŸ„ˆÏOë_öSÔÿÃ¡Pµ†²Q6“IeçƒzH_«[\Ä¿=ö¸
®ÈRßZúµz•‘(}ÔŒS·N™å7P•-"_¶gN'ôÌ!Æ}}½ä•<*Lßf¨’SÅˆÍìcéQ"k¿×
~”’–S„lª1`>æOìQ?ˆAx°WÕÙˆıîşég†îöwàfC09®o4F“m¾øfz)Å…³ƒZ¶Ur‰¬iTL9şÛY-/N+æËúÏ|ñe’]f»µxX´`”è}M¶Á’°IÏnŸfÓ¡¬µHÕ/y±şR|¨~…U^ìZ<Ê-h›<¤0;½Kß	=#	ğI#¢`8µäÔ€-,kÿ¢Ÿ°ï÷Lé¼\CV'_ØË\Ò0}ª¶†x KZaæÚfWœŠÚ:bã¦¼H³_Ól…ƒ5KÒõšY»î^l«õÖŞ(R[˜ÜPĞoİxÿ0RoäÜ1\ô#<ó/ßòç¿4{×£ÙûğÖhçu‘VI7D‚6ÔÿÙàİ²pƒCZ\jéeÉ¨{Ê,pûO©PòiÉ ‘§Í€×=T2Jj7v_"çD[TıòÿÎ­_‚2’$ :¿†¢qBT#!Ù¹ÉFJ~MøŸjøÍ@ÚÍ¢R bmi( xÖãÚ5'M½¨`&ÉŒÆ·ü|AòyAsœFt—ÙØ´Rÿ[µÎ±6Ï 1Æ¹ùyşÖjv[¹Şè¯x_0¬óõÙ^‡Ô‹°‹–•#4•›`j~³“éÇ‰~¨!~âÂîìoâ'åw„²œq2²´vø5»Rğ8v"ÜtÂ’_Z@Sş¿A/pü<êstÃ…Ù}A¼Œ8m†Å x3{7ÌRYÜ}2×0Rpµ~±FD¯9ÚÕNø“Ü°qçæfÈ"¨Ì¨ò’PËÑÁ&Ÿ(iıR6V{çí³Wh•u²¾s”L~+8`?Ù,bîÉÄ?@0e•£·Ø§é^¥\]¶ù½M,ÎvA“=Åt/İ»ƒ’@6ƒğW_‰NŠFL`ùçW,Ğ[jVåwa(\Ÿ/n²QGäôV¹³´§¢(zYÉlğÌ!ğ6ı¦ø¨Î|bo6v~AÊ<ĞìÁ«ïÙœÒÿIò oI …ú/eÀÖ—gÈ^Ş=ŠìØur¿µ³¢ìoµO&QOñ€möeZÁe¿"
İ”½DUG&ŞÎ9Ïÿµ§+Ízü¡÷r[>‡Pg¤4ÃêIQÿ†Z½ÔwÊq/÷Èh'UÍ’Î¦z*y4-¡Í‚şy
Š*ÖW iVÓ‘¡ÿñı„)¶¶Ä½ yŠf_İÀÅ¨ùÃ‹õ-+aı¹ìNi|ö18D€Ì¢ƒŠŒğ¦œ´Ó±üÄ&œ½ÙÆŒ¬íç¡ĞU!ååSòAûêÅ…Ìç–R}Õÿ–æ¯ÊGˆÕÕ‹”äŠS:ôÕ©ÄâÁE—ÓjKë³Ëÿ£¤MEá…Ğæ=Ä°LõÑì3üé7•WAØ{‡GöbN`^ºdÜÒ‚õ©ı±šâvHÿÕ—'p”ùx6ß±ÊT3À—P‚Ïò ÅñıÙ9­P€™Ïø²Ì™R!gJ`Nª¿~fGÁëzYI0ÿ”º±L_jœ!p\Ü¿öº
	%^³Gº_cÊôÓï©Ki¤”™¼ P§
;ÔÕúÙ‰ô¦RìòSk?ó®1ÿìçÊ:Ÿ<Glø¯$’»¼1‘¦ `úã¹ÚMG@lâM¿¥û7RøÜúdèRÒ´zIE~ #²x*ß÷-‡$çuìDO!Ø×üö¯î–Vš+7ø–É±K‹¢ï×}ARŠ£Õº“Ùh°íŞ•æ—H‚…!Ç"óûİgQô€¢	˜‹ÊrÏQ¹¼`@Æ´W³A+Ä<Tiÿûıx#p¼$BU<ÅÒ"|ZÁ— a6bz›±ã•ëî*úpÏfkÃVÙøkİŞë'uÙA‘6:GĞ…áéØìÂ×"U‚s;ÙÂùq§·¢ÙB—€÷-ÃÅZA—SDgPÄ87‡ Tæ
ÿ“àqÎi:}şÈ5=*t‰<”µ<"	ŸkÕo4Pb£‰'Mri¹øß;_Î^õY^æQI¬­Og‚”0S&Üy"ŸIİ]¬[Ví×€€Xo9Ã¡I¾jR,…¨…"pµR–ôÜù<Ê3’Y‚Êš[¦Çq¶ZjKöŸîÛ [øíĞ/Ñ0	=¿ı½IÀ¿Ó#ò'OØq[Èº_DÕµœö·kóZ7OQiWÿ‡<?ûŞF¦!ZDaVÀ:•”	ó£z»7¢ùaî‹fDq]‚©s7¡uµVDE"‘ƒû,}İÄ]_j‰ôñz¶EŞ "ü=Ëô…3jÑ¿H1üxt›nÛäHZ©àï%«‘µ’oPP•¸‹°OZÔôßXÛ’N;ì|?¾,§¾ßÌÁ¦ï-ğÜfˆìƒ:3âáñ¸Ü1¶K<“e¹ vî4€—{ÚÓEÎÇŒ–øŞ¢êeBió»Q&.½)è›l=báŒuA³ÉıòQ<‹€1*¯r«I3(ø¹ïe¦øè´«.õ£^€_Ş˜Såë¡º;‡6Õ¹®?£c`FiËX™¥®t\ÄfÊuo…Œ4Ø•äHi š!!p=æxÆ-ß”è©ëšµµˆ/`‰FP×9ÕÉıuuÌyáÃš¢ŠN"Cş#M&°^YÍ|U®—îÆi™){ñ¨|Û¯¯ÀşF“ªx|c$¯9m&·óşãé4 4‚§
¹íáYá—‚q¨â6îÔKÒ¡(¸™¤·\yiò=F,¹†93•™ÎŞ¼×…‰œ4°ë>üüÕ¼)pêüÊ1P
|–vŒys¸a…Ÿ ıG±¡°:pñ³ç‡y/7aIÕ‡ùLûv;™^Ş|Ùµ—vv¶çI–ø „˜Ö°Ş%]3~¹…ís¹ŞòXbîpÄ/“³Ö_IAöEß¿¹Ÿ+·A£…Nº$¶""JÑ3NÂ¶h5ñãocÚèî*;=ŞÆ-tc(OlwxÃ’©f<oªªš5ó
Ÿ^òJWŸ ’Zö9]‚°şÅ×íäóÍ¼º³pï¯|-ùki‘S×L8•K%ûea¾ÚØ™î¥ˆDåÆÈãü#'ĞŞ¬Ä@Ù$ge‹fœQ9S?Í%¶e!9mğg¢m!Ö¨ñ¹ø’6i†ØîyœŒ`Ã×7ÈîÊÎF)Ø˜'B`t_y†ÑÆ¨xB@gõ»HIáÛm&ƒõJŠWËN[” ®±€ésA¯(l uAWé?ú®#C0N!7¬ó°˜°}7ÖiÜ?´˜ı´;–¹ˆ<tÏ]ğ±¢#¶©·Ğu£‚<xI[|])Û’)]½a`GÉ‡¹S©¨±£–Í$ÂWB	ŠÑ[â§t¢ñ? ¯]|¯†VónÒX_{ÙÇŞ¥€ÿ93ª$¡Ğ4­<™»ò¿¼è8‚šØÎyªØİ×fÀ"è®ÜI»]dó“@ÎJp„ãÓ¯Huì7.Ó™¤.7tU_ kÆ­GĞº>oOÛe¬ïs¨Àê$WvH0Á³F²3/pjnÒ	Ó•Œê~^ öÅx÷î{w]g±Œ°ÿ*¢ş¥ğ-OÚ`of? '1Å/ğ†2èaĞ)i’M¿¿¹ü*Ğ(ñG5= Œ‰µ¤z”Ètáä³°-†¬š}+SAxi”Å°Sl'Z»‡iÌnÎò»§?ìÔS O:§aÌÊV›_HQ2‚¼MŠN÷A5 À!ğRGÓ&ˆ§ éÈ¯38ĞpğéÍõiäq`¯Ñ·øsŞÀ›İ	€)FwF}5ş_XÛ±)‹¨Se~ñf|ˆGŒ‚m*!Š• ’Hâ½RÈ &ŞÑaãĞL/é¢+EÎu­µO?%&/¤ñ¯'şäË—¸]Ú'g… Á¹‚ÿşù¢1aK\dTW+¼–`ïx¾›±¸•&Í[=ÈR¼­˜­7ø778]˜bä£±ÊÂ¿î+U¸İÿ…¸VÀD¨X®	U8gH¯%®V`bN­}¡å¤ëS^± «…BÚË[<3>"“S£E˜5˜•ì£Ê²£W†yM˜u¾2ÈÊ/tÜ„&Á#ËÒª·õ?¬ˆÅR¥ØC íĞµ›_,öPz†Y«ĞµŒø˜¿O¬œr š}B­9Ò1ê
(¢ÛçĞ-¢ĞÑCV¼(_»TD³èO*ÈPDèN‹üæO{ -etv-™):©núbcÔ˜†àrDgëş\…‰¨&¹Wp+ä´PuÕÁ}”ü¦8D´}H>w_¹:}òŸüÚ{.	_ñA1"q†¡ÖAÌ¡ŠÖ³Ñ2è‹¬„M–ü’pµÙãv  5aÿv—“6ü±«úµ±¡§¼®=ÀÉçvü
ew’ÀõiûÏhvıŒÇY‡åüÿçÙˆbisb ï9:l8;÷ã‚@²ÆÕ+Ğe;¸õªië¢Ï;¥ ÔÛÈµ}R˜·OèÊ€’rÃÊKí†`hÀ$:Ë¹Ö½#uG‚ 5ğ³Ü¾~“}äè#·cœø^/òS HÓSUAå_àlÎŒT~ç+÷³czzZ¢Ô4cuÂ¾vE{¯¶ø%¶4G<îi¾&o:»—ÓgS5’”q¨SÇ0T¡¶µ?±ÙÂd¹¾Ipà°åi41é	:Oå@›M¼îIş•Œ‘l6Jw\8F&$1jæøÑ6Šnleõ™“¡İz¬gå¼,†à"%e¡A¤º°˜‘cY|ñ¡Í?æ„_#)Rš&GÒË0f¸¢eWjßÉ×l²–tÉc•ìï?¬WDítÖ&¥ÂŠİÇ7åîèªQ1gòA¿D‰1 ¯ãâ˜—¹iÀµÆff%àŞ'¡MâşÑÊ
’FW:eàå
ËYFjÚ‘Iƒn-}{fçÌ¶şò¬¨zÅ`_áÁ1¢‘.A<"¼ĞMYèÁ­ãÿ+›q}N>£hÄ\Š®jÿ€ºrø¼ŸLi,’ïO²¼ê(¥5NT=x}(¥Ü{9­zèÚ¢øÉ}î:: èÚ%T§ªËÓåŸul¸‚®N2î¾ÂÚù‘!7.—ñ¡C†`ÃTÿ¹…(QcNÂdË&Ksz Ã•×NA‰Ÿé/y€³•úóÙĞ|Ù0}8.[äÆ©kVYìëDüœSá™ª!“Ï ö½­p1r¨ì'Æ¡£’(BQän–°¼¬ZqtG‡’?ÎJPËì{	~³Taâ(tÿKêƒ8ñÂşï€uG¬ñäÓg  ¦ºqhB,{ÔñÍè‚sşüŠ“;Ó…P…j­io{u@Yæë¸h ,}/î$pÙë3LYÈÓÄ¯—Ø£+äRø]õ‚Ú§Çö¤AEÛÍÛ Ù
›”Íÿ€
4<ËÄRÄßÎ4fªe"²)="‰İÁ¨ÏÖH¼WŠ.õÍéÃëd–²l°wóybH†ûJ1İìş5Ùƒæo±œBXTXVÌØÔš! ™~Å‚Ş¡)b*]Üšşâş‰L:®õ¤D„üºj4¦†Å@à§÷úüÂ¨Té¤j}ş¬ïv%Uõ2Şîææ“»ég‰jé0Ñ<:èAp3µ{¶¥‹4]àÇHøJÖÁ	É<-\,kC¹¤OÎÀĞŠ–9÷ò6P=dè¢©ÛõÆ Ğ4Ï!4C[¿XWˆ¬ 'J¹/}Ìî)*“¿ÌkmƒÄ54—WøÄñÑ’Èê'ŸíÊk©ÿ¼WŠ­RÄN¢…ãìŒ	5Bo(Æ1dÔ³¨ÈEnçG¶7Õ†š½¼Ã@1ú|=òW©ù'j'ÛË¤¢Ñwv}“¢Ï]Õ®a›¯'ºÅšznşR±á21»8û=(ªH“-*¦M 6™£Ä°¿.°µÎŸ7’C‰¸Ìb¾Ãq8…W_ó9ï1#Ü	 ª† k¯Ó/®ŠVEŒâ¬iş­²8Ö¼¡êÛ@›ÇDÕ\©¼2äükkvCˆªòµÚ
 c`gj/H}*YÈk¨İ&/ğ&3ŞOW¬ÔïS¾R¯ñ‹q@l^êc´K¿Ç¦»—ÄVóY½‹©¦'õp¾˜?®7øbÒõÿOã3FBó4(´†ÛX|dÕñ—¾Ã¬îJ.ƒĞ¤1ˆ‰gRQ90‡ÕK¨®!Â…g*}ø ç¢tÔ4ƒd¿^GSî'¿>T\(´Êoy,‡?{Şî’›¸Ñ±Fnì¿Yùï¦ i@o3tÊéìx$*Ìù¤aÆÌ†§Ê1iZtMBåhp¾üvîKFäKé¯Óí:h'aàçäJXìùÄ˜ğäşƒ“gÔQ
F5ïP7aâhmÏ«&'p'pÀe/’€+/ÂÕÁ_ÔÊxc]I÷¾¼—YtbD
'ß€è’MŠXŞã‡4–¯_Ÿşœ˜D¹F;çdëyŠêÔÉ)'k-Nºúªl4Ë¥%X‚½0õ8_€U°cy$jŸoí«àÙgMã°Ò©	Yw/“µ\‡´3¶ÿÎjÔİîÔğe+Vr…ÈYØŸøç··£?Ka|ew#aácCê½£âm®«ı]sÙ¥ƒ]­òĞ;TÛVÒóÈD8HY¾ç“¢|·&páXÀß¬ÍÇÄ8v	&.ªØ}KªÓ÷A…˜í¡èÕşÍ˜›+±œÕI%d;jÎ!®_uˆ¿ğÑƒ‘†01#m=Œã
Av3ã·‰%RÓafsÚ0‡L2‘Ñv´‚@b„`kBt4ÅI5ôôñû®Ï6ä¿®m5	)3’ğŞùÉ’‰ÿ†m¶4Ë  ›f@®*	L§ÃdÉs¬RÆ…Öfä_¸K¸¡KÉÁ‰£K)äãšÊ$#Fõ6óĞÚÁõT±ìgnëXm»)Õ9Ì´2>¼£yœS
âÔÿD_˜ß/Æp¾c¾f‰û0çœ%½›1ÅE"÷[œõL‘õ‰ÇåŞ8Ÿ v\¿ ¹“ë¿…»ÊíqGFBg²qz-1rŸÙ1C·vˆ«\ñ‹?Ê×+æy‡e8å²õN‘­±ZŸ tò¤¾ÿ¯5X@ÙÛâ6T·À ö‰oÀs9kË©|(ï­Ö2©ÃûŠî[÷ZH\BùuŒiPğHĞùû/ÿ*XFO‰Ì›“9AGUÁS	½ÅÍuÒh¸Û£À'ƒ«@óŞ“©ÃÕ³fÔÒ¼õ«§œ¾DIUC'¨'{Œ¥ÈÇÃì–Õ£‰«jÑbµû}ó$÷÷øƒ‡c×»ªÒ%“×8Fåãºø’Á¿˜'s®´¾’½¾®|Ù¼Ô)µ'¦7y¤ğÿY÷ÂGâ{-'ƒ¸êà$`¦üQSc0ìı†5{ªµSP¯È³¯[[ù-ˆAáèØ-‰&°zÀ~Ç|£6y‡#ØÚŸhû±¶Ê´Ú™¾b¾3&ïç 2‹ã—‚4àOÇë¤EGA‹·SİÈ¯4t«Óéào±Óâ2\Fı¯tË¯¶â4ù¤IùÑæ–ıgÄUgWO8áİ–B; _oZó|;çNÊDÙ —”É=3kµ	›;–ÌÌ|šú½ê½’ıjË•j§ã:‡rÈ-Ï*ü¹n‰‘l·¢ÌGtN»…ˆÇş—LbğU¢€êõ×ê]ƒî’fUş\³	SŞ'0Šm;<Ôİc^`ú‰O´µ¹çj9»º—İìÕ**Ü›ğµ“Œ<ûÈ$… È¨àë=Å±
®oŠŞš”~	_ ©Ï· Ï÷9Ú·ù4¿h€´Àé¯	øØ0$÷öÅs3V;vüOƒöh§Pm­åM„ÏÕ5¯w¦·ùi]Ş('³³(Ïê-Dı{ŠC²}ğÄ%­ªtí‚Æ†·ó¾oâk©-DW0æĞµ>n_ı…’¸'­&[İ‡¶²2{Y‡ùÌüœĞ½ }Õûp öD:f/p@šOPÜqX '–è-•ÒùîqhY¦“^„w*FÜàİ/bç§Ÿyt<Ø.c`ƒş×ü[g!×jJÍ$>Ô±°ITş#k2]şp{îp÷–:¶JÁ–±3`íª€_— XÊéŸ„~1ÃUşFÎ3ì²L-6â8áå,Qmï”ÏÖó¢Ö9/ãdnˆÓ[06¾½nÄèzìõj¯.ÔFê’
¿ĞĞ½æ»ºö‚eaª¥÷27F)Kş2ÿ'7Ş—Áİ’²Mi ½‹á=ñè:3Ï€#¾Œ!ºû›ºcà¶ü2%!¾i¸Ğ†F3
¡4Ì>ÔÙH¶¤I}u ­‘µ’ûğ¤óİŒö.QEw4GƒápB¦N/’WŠ%›)95'ÜÍ*í]îz‹røÈ”ö“ü¤ùV ±H#¾zĞŠÿJ¿Ävaƒ)_2&kìèÉ7Ydn[Ë¸€Y†vˆš¤uZuÜµ:ˆ%“'âœˆÿÒUøÌSS,³Œ­%U-YWe%B‹q–Ë¸+´j¡?Ó`Ğ6ˆò»Aá®°ŒwT²[1g¤›jv‹Ú>“SÈ4yÒ’LTø!œ7·ˆ¬ šc½¨åtwÎ‚G¤dºİPÂº½ß¶-ïâd®„ÈÌ„+ÿ'¯M7Üı ÚC®ÙÚeë{D*Íú$Ûã(1~ùJÔ‹*+èûúRsôÕªà¶xL”ÃÅ× qñ'Z¡İqÆ
Y´y-ôË›†\ó,y¥¡¹tçËô“Ú4ˆÉÂè¢•j$8cÕVcØK8T€g½røC/VKÖ`-ó42¢Ë‡Dy¸Ò~š’¨´ış*¿áÜ`ñ_fzò#²5†.¢y‚g”^22ı\4îÒ}·6ËZô ãó?Iš$–Ú &|ˆÏíåíÀBí§^ˆ†¯[Îäp‘PúÃLİ—\Wn;º±¢*è"J2É=5÷!NÄ‘ÈÔ%ÁZÔ÷s“(Ur¬Æ™ßU%J~²Îs…v]é†}™v½U‘ÅÁ™Ë¤HVr¢ó¥9_ÙUà½ÿÅ<šÃµêìİ®Ê*|3Ü›ä-‚¬À“/èC¹0†ú×,^tt‘<“ùf ‰ïj¬`íîÅ9â€:	Ò)1ĞŸÕ2´…ææBñµ%x‡ÖSÁ<ÚtfPQQØP¤¶Óp@Ü:)3˜×àÆpâa¦ª@?_ïU)Â°N(Xc$…®İl÷T#‰q<,]èTEÆ3“·HP‰g&H~Ü6Áú—ĞnWå£ú¢P”ñSgc‘ˆş¿’îœ hœ,wV"=tç x'ÜqJ0~S¢¤ş˜¬·oè†”a"|^Çg¬›fc%Œ,THq3¢d'w3D×Ü“jÒQ–5WeÊi/#wòiÃíì<¼Ÿ†¢‘A˜".“Öw!ióÔY¥³%'¸äÜµB8mŒ²‰¾i"6ÇeGW’™ğW ¡dãb†Ó'gÿ´±•n¡gÊbáÇ·3bŸRpœ£ÁMwz[†:k„ê’Á,Õïb®ŞÁO=¬ß4D{1gAŞ\2G€»“)~×ûz±Nu‡x‰àoX\PŞYì–Ï¿ô²¾Æ4şWÏâêz÷6
ÏÔvx4±^¡ 
³"ukñu‘—ÓÀF;G½†ç¢^º»ubi°ë˜iÏÿéè“?è€Ù®V	=¢ kµcVuƒ7ü¿êeal-Í’ÄV,»d0”¦…×ÀC\kh‡.é÷íì1ªñÙ's5 Yx<ì4u¡ãWñ0xÕóEDB0õJ:®âkB‹Z’ö•ÿK˜ñ¢øtK¬‡uP \Ñ	pİîCL{šİø…
dSv%½òk¿Ö&Š0hùè×Â1âYôèÌS	/4P|Œl|r'Ÿä¾DÌ)³*+ö÷Må¨âƒßÊ1D0ÆÊÚÁ\8|4·¸‡+š	Ô]µ¯
Ôå´>q¨OJõ´5XÇFÚµd•Â²Ê±+qKD"š®=ì™‡/•5?§~ü&‡êHü²|—Á0;î¿ı\“rGLpiÖ<é°@ı§X˜L9v©;•m[‹¿ÑÛ¬AZšåÑ•­ÏÂœ*®(‰–¬Ú¨Î-² A'-mÊeôòÒ¼´>ua>”-È÷t`æZıÅïö¾œAùÍÃÓ¶™ês¶òÔ3d×3ñ)yá³Õ&P-î•,4?ó«¾+x½-o¾şø™ùz|·vŸØŠªŞõAD81œ ”ÍÆØŒCÏĞGÿÏ[HhSë¶Ù ÕˆqTÃÑaÑCëª{ûÀ~Ş^y¾É„Dô}á“ƒz5EBäÌvÆfA…Ë¸0
R@jî°K(òN»ô,àÒŠÜO¯«Ç%%È5'w¬°=N¬K6€	’‰gåŞŠÙœÒ&‹’‡óŸ]îtDèì¼ªÁİ6 ÿ®b.?²vŸÂ[¼ì¸æ¹>.FxìÅÓÃ”¡ªbùd­şL€?£‹ä•øf#Î=€îĞ[¿åh‘¯kÀG;-N“ı¶":%‹Ãc,+¢QmÊü[ÎO	øİ·<¶&là¸Ú¨ÅßëI-Ü1î;éJ@@ûàÏò,î Â\¤‡ª{\(¥îF3İ#èqÓ«„4 Y¾b/ësÏØŸ·/êaãúMº{Š{‹‡ggO!ó5QË$àºÕìƒXp5µN‘äFÕ°å=i×H[¹ª#Lüäôûk;âézÚ2Õ9qe¯ß‚]{šC‰]€ò’kìf_Û(•rÄ½ø3Ae"Ø¥s§Áy¢pG„%,î6ÔìÙŒ´ñO>®Ã‚1†î›*è©û}¤ç^CbtÈá?‹C	Êt,n`E¡oÖ'ì±óÿë½z0=€OW“µ»‡ĞméË’ª»R`{™-~'¶%ß°=yNV+\Ğ÷±È5©¸Î7w´¿z×²±š[°úL‘ß¼ğ#_(ÒÖık%Ë°)»g0EV) O•$„-2SúE#í#³§>[Üé¬Î·İÇW˜pª17o/¤,kN³ğd½yê*Æ½:¤gãz)4Ä Hû‹Ód6è²õ.I]KRÊÓÔè;4šEªgÿğw~_‰¢IÌ~Èİ(Ã¿¥C‡®G^N·÷Wu Ôt
÷„{4|ÿb9±ÒtÓÜR²oÚ÷Ën<üKhAyËÈ!t¯í¡ùÜ-|÷
CÓÉÆ¦_:ï5RZ£ö-¡4ÿA*àhŸ(BVå\ËÖ¯+"Í¤êä”Éî®ıÕô¬	_Eg€F¾9ÌyÊöi$|R˜ƒ°„%ëûÊVÛ^äõ§â—
“´ÖmóV‹ÛKõ6œ¦R[Î„l’bM\Õİm§ãÃ\àE®¯}N93-@-EŒa®Á”³öùLJ DıqÚ»Äaô†…"ù‘`Áw|ÂyÑç. tÑ¬+VAQkT½æÉıç‚íØe¯_ğğî©¢âtìz'Éåƒ„Qà0MÉÚÂ=oÒ%Ñ©‰ÛÒsU@S¾T¢;ÔŒeR)6o…#Ûô•´ñ3…ë¡Â)>6Ö©ûm“.£ñáµ9êàõZÇ``—G ¯#f\û?.x]ãLÂY•Êbç/ù‘:C~®ß¡9°s¤0ƒp%#²ô3*½Ky§ûa8ß»iz„ã,ä‹ty¦5QŠz9¼ ÊÚö3[­ã5Ë;ıû”„) 'Y‘Æıí_ÄqÌK—eê,$%Ì!Èõy,9FOÉ Å3ƒ‘¡¦’'Ş…äv7š¬êïr>dxHÏ8uYg‚hN}Ó.ğ?Ùxı¯ı0z[\­ö8¹(´Øpõ.\‘"r0B–/éû3C×:ï"¯¯ `‘¿|"n¼äyª-»ú°W«d;é/¯w¨Dì@8×ïª£“
™?´È"~$é,(ĞVªL‡Şy@ğKø×'a:WC,K5²§ŞğLº•¸ÇıeE§]áÎ¥
¤ËRekX`•|BØÃ$áÅ r*B-Å»ëÄI¼ôveJ•B¸A®;B)ì‡*²˜ğ‰À¦wÂßlVKKš¿k@©©£#ô·íX"†–Y&iüÇ6ƒhn¡ "":eå>ˆøO(LîO0'yJ~á\'HªâJe8oJ¨P˜ «w×k×ÍşoÙ €ß–5B±#°°«¤TœtC_¥,§AùÙ˜Ÿ¾:Ôº®í,U¨9ÛÇ¾õ«÷é
S¹â¶º®Ü@^ƒá”åæ¢“²a°#æ¨9óİ…><Á„dßˆQŠ)4ı×PR$Ä©»pÙ¿4‚ºÔ@±ŠBÁ$5\„.mı*‘‰nq3x»U¤Eì¿
ŸØ5şåï:
‘
ô…5¥=UÅ4Dÿ»aòÇ^)'©¸8_ÎMïõÊ„JĞ‹¿ _ºk%ˆØñ3VY–6ˆºì-] ÛRzî¶—Ô×|ÉIĞYÿé¸( •½—®œaİã
‡w]-gjÙÂ¼Y|`õæp­wÄ…W_†©¿ç»†g²¯Í¾eT¿òÄcË!4õ.•6¨JMè Y¼YÇÆå¯…ÂÂu¥ºˆí|kèËÌ‹EL€"eKßÖ¿´¢.¾ıKÁã=dbÉ_`ÍÈˆØ¼7k*zwˆ±Æ¿ËïÜ©ØïvZÃ­Ir>¦Xdö$"ÏKÙŞÇ	¤ànşÖ­»`HÔŞ†Æ³İÃb(`!ÃPdKºØ¹rñ6Mê/SÎqåÅwØ7]yq…ZNıäÌ&{®…üÚ!UNèGÊg‘é³4h¥¡ÔE“ÊrÅıÙ÷ÓÉÉHT¯‚q)ğÃi`#Ú·Lt\ñ7—²g±’eµj¯uûnÖùÉÊQ!–&àzºu¾(3×".ø&ÜëpØ¤îvˆ­Ğ¹ªPÒí¥~ù÷à¼’e‚H»”ô`—
ìü„f2¿¡ô†ö3WÏ–dÉˆ†ili³ıÒµ½X^Œ›ÚÎ0‚8ÅjÇ…’Ø+ĞIXVVù.÷¯¹kıa@Uµb¼€‘ã‰³L&r·,û§Á
Œ7Ÿò(ÎÏñâ<Î[ıÆÁãÛèbÁrûXìîB;Ç¨“Àë*µ@Ğú`¿£bNä„‰Gy÷O®×/z xí6 ıàQ­xYş‡`ò;9Ë[CÈ¾C›?“x%W¡9jÃHú”ıg]ë wŒ  4)äf³vÃ,ûˆÿ¡pÌ*"À¤ÜúûfFÔû¨¬$ì¥)O÷¯µè5%„÷÷’Hò#àç«İû¥^ÇíÆ‘,Õ·¾u˜U™¡ÜN‘ÂíßÉw0Â½KíYŸ;cI|ßí²A
„%·VY‰Hå¢º-,ÃƒmŠò5á_V«IØëS'=Ù10[Lm›[0ŞÕô¢oé9èc¶ü1!ÚŠg˜ŞŒÚØ/ ;µ!±ˆĞöŠjîÎ9×°ØF±Ù¦Ø°D¾É­ÙBÖq‘ºrùÀ|BÙóÃ*‡€p§-L4×¦•Óœ°£;™'®ƒ¬öiwC·mzÈfaiõŠ€ÌısÛØhøSCÇÀ©”¢Ê1avòq9õwüp|l­¤¹÷fD¼İ˜©‰mÔ„¨¥ÄcÚö}b¼¯µ—G€WÌf#ø8şÄ^²Ä.L^W…M7tÔ6çªc‡isëA²ïâ³0“e¶%:’Ó¦æ²C#>ò¥á&iwxàAø1ùD€óÈ¥²77Ü¾Å†¨éæQGİ#™bŠ­šÔ{.¦«ŞHîØOY¤¤m«1û4wÙû 5@mçe3Ì "Vòïb™]	5ÇVœç¯Ù³-A–Ê¶W}6'‚ŠQ½ùŒ´zX9bä•I$ì+3YŞ°İm˜Aÿ‡ÏZsÚÙõr˜¹Y·Æã…àÈ·zÀ|p0Ø¿Î!îDÁS0qšê§»×E³ÜÅlcÎ	™Û1i†ãÄ0Ì©S~º*«Æß§ıß;1ŠéúR‘ˆ]BóOÁÑEš[‘«Ò2ƒzq–,TŠK/íxO³UÚ]lßès:Úk_ÿÙàöŸiàİÁ™=aYöó>§á2.§Úy‹“Ÿ5_dEß1¯¸
£µLU|;á"EÃrsı„¸Ÿ®ı†à,«nnb³A:,=ç·pºu¶Ä9…¬å3Ñy7Ï_x-m`D±Ã,4bšĞ¦y‘ËÜö}°B‡ÁwÕ¨İY^"}İ˜€	7=ÉÀb»%mâHª-7™	ÀfZàÀ*#šˆ¹€N>ít*!ÑYÄÕö€Ì\7æ@·è,ûc±‹1n)aßî÷m÷yZ•Ú£€ÁÏYÎ¥2û4òìïÅŞŒÇ<1AŠ
Jwb~2¡‚x	@íò¤ ·eÃµ.Yç‹TEäëçOsş"£€¥¥fÁ²htÏÊD*7B¦÷Ÿ Cş¼4dL?,¢çZ zn-Şw–‚"$-ÊZ%ë„IåõˆH8#ğñ,ç ™›'±°6÷ŸšÜó±G,Ê¼z™§D•ã–ø6l[Ğ¦Pîf‚$vâ¸dCÆÚ¾s¦«~A?¢Ä ÿ—x­ÊRsÔ¾­­¥PWºî¡gˆÃ´ËE¡")è(!*åø}Û	ƒË?(¤552]uÙîğ¬u^!¡²wäñd¹£õ?ÂI»Ho‡EuéÁ˜t¯G›o(‘På¯?¥n¹$i{E˜ÒŸ@”Iğ±yß€!m™gœxd£‰•`è—ÀCï•5uŞ•‹öK%mTJf\„§}R’5Ôàò:­‰£µˆ±˜JôQb]Ğ'¿d¢8Ó¤ÆªÆôìJ«9†|Çß"Ëå>¸ƒ»òªrî£åÛùzü¢$úx¢™”İ³+L@şÜ¿q¼PĞ*Áu;u~òL¶>C¹¨öà©ïØÅçM†0í 6ÒÈzüİ7qr€z¥•Ğ=(1İë}ÑÆtz±ÏûÌ}^1“äCÊw$F|è¤pQß%d¢iù"4õi@J$¼ã¶@×kTØC‡Œ¸Œda’øÍußİqğj¦#ËÖş½ö…¼¹y5ib9«‡õw¡LÒYt HLèT@tTu>Nw«ée†>¢cåwÓ$­1zv¦ÛÍø*æ¤L;}¦y@k]. ¿lñ8:v:RPÀÀšQnıJ—Aß»çó=•™Ô‹}ŒW;¼¨?Òùü(ò0&êÒ'
«¿‹ÊéÏ³ÍÁ“¥šßµ8V]{ıÍ
 ó<OOŠe;tkÏr‚¾32ù~*ys#‹¥ëÀ_Ş¶è©nÖ3‚5ÍSq„ÎS1Õ¢Â!äÓ©UAZÑ?êfê\r’ ¥ØÂ«±ÈF‘¥Q‘ä©H÷İkç›/.‘*ÓBp×>ù#ñ%cD‡ã>[U õÇ×ŒV¬ÆjöÏüÏ.1Š$^aa›-ˆÖÕ6ÄïXl ÙO{œàH9«µş ·mª…O#»‹A¬§Öj·ïxYùgåoğåZv=Ö Øn_\*¨¼³b’·áÆÛ,@¹:ôÄ·xÎL-ªEÇV$d’åìvcà°×Vä k—èğm?—èc¡zy¥(ƒ=:Ù]˜P[æbƒÒ^2õĞ²ñcãrlâ6ø‰´Om(ne¦ğÅŠˆHiöUiÜÇZì7Ì]:ZäÃNƒBB™ à4ıéäKcãÊvÒ ˜J{ÉÇu@v3²`WQ¬Õqõ-£œ¶Lø(¤Äd‘J-J"‡gÆ”Â­4õÍõİ5Ïãå\j‰Ş¹ôYËğ¦h{ê‘ï@-ÍJXÔ xë?	¿÷×¤Q\asÁr·a80*ÖZåÑmnW Â@ÒIŒtä‹6/Æh[.Ğª7‰“	Ü„:_aER%ğO¤îÔDh„(´ì}f$¸@Ä<23°}Hnëáù?wÑÖoğ/4¦äoÆnìJƒ¯ê*Ğ©¢¶4xWÀƒáöœà×§¡…vE‰®4›ZC|RÖ¤pŞÁ?B‚?`§8İÕ¤$ÚÖ.ÕºF^Àßêó¿øæ‡£gÉvfB6E–|‚<£0íÈ½İíŒ˜kÔcÁ3şnTp) Dê-©ÔlÀ&GÊOŞzëu”Ô*>ƒsÙ»qF[Bz¶Jšàõ$+Æ»ÜéëÿäCÏ6NædTØİÑ¦75µGÏBV÷O,°Ñ“9/È&]m¸ <‚?T2É=$–$2Ê1åÈ¶QlK–wËœ¹cüˆÆÀ{µ-bGv÷O÷ygj­{–’£\‰cQöA1Eè?™XíªÏOÔ%
ïxíx“!•¶æ&s«Ÿò‘Şvc°çE¸ãÊòÔŒ‘Ú]KŸËã&ïFàø±†Ø¿
ê:r::P¹T#ö×İ½@d»¡ƒgß;uÓ[s.`%¯˜JøÎáeÆÉyb‰u*•Qü
î§×à7—¤i‘é©„ÿmúıXy
õ k½ÀjÚOVeê^a£Pı™.gû¹ùÔ`Œ–ìÀk½» ä ¼+5N ÿ†T o²éø©–[o[•Ä~x%K¤¨À&	€ÁÂt•õ ‹AŸÖÿxºÂ	‚¶‚½(óP •Á±Ã(8l§‡dš‘Oè—éƒß‰Q'O«í«±œÌÂ™c€|ßÁÏòÂıVÒÕixä÷B—é)#}o1»çáóÅï_$’8_¤´EøduØàŸñX{ğ]SÂ–ôq†ÉÑa¿çµIıÚ}z5_æŒ¯	CãoGù_~ø™6¤¤Dê0yÿúäQ˜a±RPƒMñ(…ç—œûgr–EÏ×«ÛiA­…·ûÀZtñN®4f¨“„>(»3í½c›eË–ÈÕ]l—©À«oå|è÷¸7¨Á+Ô.T‰"œ$£Qóz* 	ó¤­ŠÒE!› GX½3_¿¼([É5¶5ÿ”²)f®Œ³7W—_Õ¼ãê"’Do:•9é´½ºC8d\Ù+ô©ŞwXçç¤;W1¥öÕrù½³Ş±» ÂI3F©Ùt©ÅTiO+Æ\‹±İ_Šÿ¿âJ/ªPòW‹à:' "ÉÎVø_øW<ÂfĞÒ Mç— ”ûœZc?u°ôÈ‡js˜H¡‡£  'A,C2~§ä«×x­’ÁIJ¹%”Vw¬;¶EQq¢»"âz›Î‚GÌ»ºQZ*ÿ\€UÀ˜àÂ‚äïK¹Ê&ÇÎJàŒ–¹{Í¿ÕUÊÕÃàŠ¶éëSşğW©ÇÀQ#£Ÿçáñ-—ßiizûM‡«îÿ™˜îŠGÆHñë½*´PŞˆ¬úS}óş”étB¼|X%ä_-­Á§­ç*úİjêã`ÿİÁÌá¨işgv^'Úµ(wÎ‰ÒŒ<c½³öv5Ië·o‰c8"T'ŠäŠÿÛH$¨²jª6j&OòYdT'ĞÜèÓÆH÷ÑgãôjFÄØŸ2Æº½šE/ã„Ò9©{š_„ğ~“4VB–ê´íãÃo—ÿ6’Å»“ˆñæÄÑ„HÊd÷KKn8ğĞ»™`-Gã<ºÒÏ|-Ç<‘‡Ğ“=ĞhäÄ³ŒY¯s¦¹-tOVå<¢h‚dÕ·„Ğ°êĞ0Q|y89õ0ˆªòohYR¯•YDdMµƒ|x)ç]3œÈŠº—¢ >Œ¨åC»ıìœïÿ±N¨JŒ3~c}ã2‘àf9¡Ş¨'şû7
Œ‰Æ”¯’ğ*^Üê€/6.4Ì9Ç½0Â2ìæ9ÊcrV!6QX¨Ğ«n4Ã]Écª¡wnuü7¦^¸rÏxQ×ex·DÆ*› @”'‡®:š¡¯|;²£Ë<G¡”|}¼ø§k\Í<–àp·ZÏîÎ ÜUë®4âFÂu88µ€‚íë¥)¢úì õ´ƒd˜w£¡­Q÷¤Ù·pÕÚD/IeHV'!ªìäÛ!û±¼ Õ¹²?šàë0Öz°íæßcsjòME»€_ÖüÈÏ²ùœ^¼xõŞÙ©½Ö»ÃƒaCşC.É –_\F™Îéc^txİoì0¤ë‰ÌÀÃÏ2úEF|…‡D¾NJŒv•K~ÃL~’*çfã®¢	úKf¹;Úm‚zqPÉWûøŒ¢±È¸Å‰:	=ü0ÒV¢²\èÃ”¯Ğà°İï´åœ¹Õ{}š—IoÊÃ8:Hxw"LöêÁ¥îß°ºgÁ²İ-ràÈ‡0®Vû †RÎßşº³U'ëäEWÑL°¹é¶Æ	´¼ö‚ôŒVˆ{Nˆ<IÛq	¯úT†gíæ©~DkëX£R&¢Q [ZØÈˆ¯0_=cÉÄ~>å”G§d%Î}´{Ë»rëb¯ëĞ+*h7Ğ;‡å=ÙÈÓáËE½±;Ò°Sw2ÚœÏ"8©ıH\ÓŸ§ˆlŸbôw<–à1Y3÷Íâ ~m(aÖ¡oq$O»†²8¶Wgşuå¼µd^‹ú!¦qú7„™b§eõJBt$
H(ûRÿß2é?,õTspïö‡™og4** gPóıW~€ã±iÑt2’ŠÜkÎd
eHÌÄâº?tÙrÊÓÕ8Ú(Ø}éòHPµ÷ ¹ÛC»Æ5wƒ/bêÒ2h™Œ¨èåXçR#ÚrÊóâ‘,ßi6£’ûÛé#S dB†ë/2VC«.R¼çüÒÿæq6‡-ÏÅÑñÂÜÿ ~ëñîuŒ"ä€ä.™ğoi7mÔ¤S(ÉL#ÉxàCYÊã$6Ãw*g¾e;^z¿şŸw0ïOm›2åúüœyyxÛ×u®­ùÜÂRËv»ú\²ƒ)R"ÍY²iŒEÁÄËÉ¹û©–£@rŸ²¡!Sv¼7Tà„¦ d|Ğÿ¦í#)-DˆÕÜ¸=iÎµë†…³¡ D×’e„Û’ È2`g4_òŸ‚g˜šß$ìôVo¶]ZÑÙêëRü*üà	Ú4›U§.œ`7;Î/³¦Wnù¿NûTÔA.!e>mÜ¿şŒšŒgAfB:˜s°‡s­>?‹”$¥O``vÜùÂüxñù&¦z³’„[u=ŸWjM‡û*ß
ÛI|Ùà Gœëk´Ps9ù*>{Ù@I¤3¾zW¦Q±<.Yh äÏenÎ€|ĞÜO
8&Y@ó3!@\"«â¯:’˜˜îØ¢ó_NÜ}3U,kâöyÈAnCÊĞ‡g $Nkõú·2!¶«ve=™•Ëf%ÀƒÚé—ôÔË9<$3¨SôÖDh]ñ~¯F½ï2¢Ö…«Š³ãNêS÷›¢¨¥ÇB û-Ú$|ô¬ß‘ùQÅæ·K0:h|¹- áıÚ_ìÄÍÕ¢‡j {b*'}É
¢/IÏîùˆ€ÄÒ
|ö¤´ÍcÄıYãIC{~Ÿ´õ8PPI…+°Ï]¾ŒEî3„>&’¬pØB3{uƒ‹¿³=	©Š•?Œ»÷»"¡Î¿fé4gµt™Â×R3€S!~·wxÙ/a¡RnrÓÈŒçeü\€„t|Àön JÉøÁ}eo%(€®NÇ\H'¯8ú×ÓÓE	ÕáVˆhD<ßö¸7îXœz£1“
Šlè¦ª™{¶IÕ    ì“ÏcÃ[Lé ¦€ fÚË|±Ägû    YZ