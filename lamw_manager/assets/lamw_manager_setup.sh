#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1033050163"
MD5="6e231816e42fa41473e0151db2f71375"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20972"
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
	echo Date of packaging: Fri Feb  5 20:04:34 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿQ¬] ¼}•À1Dd]‡Á›PætİFâínƒ½›jwÔÍQ#¨q¥@Òeè¦ÔVÖóHulãïÀt»-<<Òk:¨	ÃèqÙí¬R/5ÿø^¥Ò©‚Â)Å·£hhññ“*ÊCĞìGn¯Ôñ'ˆ·‹W3z~Ó‚ƒ1;Ô´Gô dŠ:³.Oˆ€»>¡Ù¾2xõV¶1 ªö`Éî·åÜôß„ñ’mû@EÛhœ2˜¢IÍÔÇ¤+¼¼UgMVÔ4’¹B½Ãõm8WfS4ıŠ—È•Nî[®À'1<5’(Ñ0º;Ê‘"->ãá}Ùá·€îŠ7¹âf%İU5'ZÎÜcˆóoâ)«K,TMDS1}`Ê\3½.i3Š“Fp/1oÄc/ÜJ	q7”MÎ4ó÷7mû&@-ĞÀı»Öºº÷Ù-ÚkV†ıóèä~áRèéÄ­Ö3ù YœÍ6’SëË#V<œtCGQMğÂÃ –.ms“áÅÊnİÔH¦b=]K–+)ŞÂIEOê›Z2B=×*6i2ƒYŒ!ŞÖMê°Cë_áŒ¡q+¹”¡š}ÚúÙ¶p¿“ ÜHÚçqv®jˆ4Ø P4İÖGqazû÷€8­rÂÎ!sÖä´Ù8*÷8âäÔœŒ¦ÀÏc™Qç¶Şï±^ ™Ïîïç'Q“š…y~"#,ü>ÌWBİ^ÕÂØéOÄÔAˆ½j…!u'mU'€Óáî¤+iÚøu1­rOàVRßp±+5X3Q³;] ØE^½' ƒÚÈ¾\±¨B_şÅ0§Õ‹__¼² Í;ô|å	%ª,!aFlNç/ĞĞKÃâ?ß;êüİobk¯°zÀ™çÿş7ò^1[×;p|drhMĞ¢ê‚,êa4§PÔAfHnÅàÁ0ıóĞa=
Sˆ~Šs’†GÏyZ‘îãñÍ{ÊßĞõ ¬¤óÏ…-ÇˆwœsÚP{EÈë‡EÃYÏÀÉ;¡èôF–@ê¤õhñt2e#ÑZ‡Àa^Ô¤~|Mèµœ—€ñbíº;iš¦Ê÷L§şIÊŞ¿…\¼™Ù<jn-w6{…Â!„İœkú—‚‰zBráĞçb"8¯j4÷wj£^£ÚüULäåöô+±r­„S¦ÙÜÚ„s2Z‚vpš\–ÛÈä×ôœßK{å[SÉdÄ×Ôí÷¶Eaçhß‚ë°¿Ö‰ÙËä”m)Ñ¾0T<Êô€Y¿¤ªÀ¢z!7v¶[·>%–ò&®¡ğî”iL’*óÑÏ(«ù7E€FaÈü¾êîÓ ´Ó)›½Od½3lôE™Ú€$µ¸ãŞ4ØZ!m”J#ó¼ëRÑøüDl•D¾øœ}\U)™Ÿî¸—Æ0J”¸%ñã|,‰©Ä’ØĞ½,‚’V½—ØO¶ÆL_Nãî¥v­ïöRUúï#««Í2‚™¤š]GP±³g
Í¹èé”F•HªhòŞúÄ ’j31²Jª;8'k
ãnZ¶š&Ñò&&²3ß­qÈ¸ª½v­jÈ•[W‡;k¨@Âƒ£*ÄĞ·Vï}ÁFAAêîWƒŞÊGÁ{Û¬>Ÿ¼NÙEÂ”Ùd9vpKº“ŠD¦RÂÜø„»†¾æq9qÎ;ªXÁş¡2I;×:Óåiâ24İZ®Z•´|”më‚œ­ïã
£Po®õlö_dşÉÜ®"¤U[´P¾[ªDƒ‹–q‰LæŸê™á‡H!›ĞT)HæpäÅ]w?Š4©´Ì*x¡¿d¨„ò
9óXB-§­Oû!¾ÃS¨ÉÆàFt ;ä~÷iÕk€f6Ó9~Ì¹äˆu4.¤-L¢Œ‘à§á /xv,›WbZh@AõOK¦	Æ‰ú>¦ÅXÖ—ß÷39(»¼¬„.	fÄ.t[QŒ[á¥ë‰PZÓ`Îr…|±y(ò{j_+ø°qÆïÛŠä?_Iú¢QQ˜¼w£ßøäËÙ‡;+)¨®Ö}õynŞşêåjPŠìƒkkF‹¸wlñá9’ëF:ÎÌ–UP»ĞI=ßˆÊ´ìA®èÊé¸‹Iî‹$²Iº`†Áo•#Y¶tÁšïãü‹—cã_h¡sM^.CÃvúÔë&ßí|¤½°W»,²éæ/#ï­ÊXvâºíH?†ÿ;Àç„IØÊ’ÂpÕ¾4lgj5Àkƒ& òEv¹d÷w–‚Ì7F“Æç@Şÿù-(c7€Š«e>WÕÏ³ˆËÒdÇ<:j¼RKa9ï‡&×WëL`L3Úàë½,2óÑ7ßè)oj•N¦XW¾ûYêî‰ª'Lµ±Õvú–ïèU” å®¸J.e8°bëbuašqĞıX6I¿…ÖaóXŸ”U÷ü­Aæ²é-ßà<C .[€™±Ë“¼:5h…Ò0Ò.
/95 ıİ­€\p­¸:wO;İ:E“p÷À©V¥DMz­¯&X¡¬Ñd„´édk‘·„(>kÍ—cMš¿=ÄŞ¹ÑWxsùOâuü\,X)+Ïw8V²8OİX^µ”Tx”_|Àiiª.«¬§–Z˜…1¨fàšÌûéôºun|¾U]Ÿb–#¯€"×jÎårÉİîŠ¼3©+Kåûöü.÷ÜÙOÙ.¿¿ÿİ2P„=c}ÈP²ê©Ì´bEö…°ÄÆ
a%Q14 sÆŞı¤'*ìŠ¡ÿª25o¶âàµ«ôÊQ½|…	Ô…å6½´²ÏÓ­÷RUa¼ÓÜ$6UoßT¿‡éfjå´ãš9›‡éÎcj½Ğ3dÔˆÌÑƒR—UJ\xF®ªb²Ù×A|Š|‚+<ßSìY–å?ŒN£N‹–Ã“f'ƒ´Ì¯˜jW3³*¨ß†áh‘¥ä.a,ğâ àîdq¼Ñ[Rf%oy’j}ï|jfoQğ¿p:WBw®6:Í6iÑ×B4à—m¢Èä9|Vß-è[SXæ;J<Àá“x˜‚¢˜öaÔËË¤Å›$•c>c×
vØaua…˜}é’
À±gä8®fİc€F!÷#òo9ptÿÎhl‘>yÿ¸uX‹Ü„	UqÃÈ‡&úA>Ö›^/¾Q~p|$Hun"ÿ[:J¶doæÅÚD°a£…)-RÄB¶•+N!Çı¨ ê;ø¬Ş…ş%Ä8apÒ˜¡‚góf#÷z)å<¤bP&Dé½Æ©eZğc¸HeYĞp$c¿õï%Í>ÚëVR32–Ø³ûG#˜–NR§Ç§ïÚNÛû¦áºf®Æ0Ë =éùj¯R|Ş˜-DÍª”§ªÀpm3zÁàGØß±)ûkVJ²Ğé©¶i9:“èÿŞFŞÉyG«ùª¥$(ƒé÷ÁÚÁßã¢øÑx,†PícÇx†D÷Sa//+;Ûeb¬¦½ùş§TÊtâ8Òs}g`MÇóùyùÂ°å½¦»G.[X0Q9nl­3šW'Ï¥Mpy2ü9ihª6ê²—VŸFcl’`å7JSo±‘¥Ö,851XxÇçù‡Î_°šwÊÅü ¤šIÛ\5>³áüáqß>YZ
ĞâıII«Ş@]ƒÅÎÜ°‘(l¿ÉZ0©òÔïd†SCº×êÁ™×ZÍjÚiÓâ´Ş’K¥'@¿s‡B% ´ËG6™‰';ØÁªÒR®L†B-H ¬˜[©×hÍ™£ĞäÓ?JßFx®Óò5\ğ¨9šù-wØ©Q–rãs0¾%D¢¿\„!éæ¼><îºdq$R+µ%«š#¥93Ñ­#. Zq=f¥xÌÌY^•S\Š!ŞĞ¬Ç­ùÁ“\Z4Lmˆ½}©ÄËcñØk‚:ÍîVımP‘lÂ‘Ğ©"dB½Z.ŠÄävçÄ¸l‘Ó-h¦.¥§	ŸC”@›ÁŞxKl§˜=ÍŸ>t¸=áÜ¡Ò¶=òŠµX)_Ø¡¸´ĞDÂİÀp»aÅ3>»¶àR«-ºge¡‡Ib%<8İV®A ½HHlÍã"gÖ8õÙNáS—Û5KŞ+¨'r×¹Ø#Q4H69œÈc-hÔÛĞ>­úH¸“”¨‡]c<7oÉŸH÷yg ë•8·t«Óx£fLvMzİØ®7T=/=Âd'®XÉ.Œ6Á$á¼prÜxÑ¿íº"Ë^ á1“ß¡„CâŸ=W%ÄÆsæå£Í¸‹ŒT•½æÃAß}ôÅ‚‘3»SiÚè6ßwdúº•}ú/äÑÎe=Ø,äCJ“&†{xWBÀt[g
:ÃtÄ×³aà1yêªI›ÆY¦HYØ±(pA8¢ığMÙvåÌÌî©%ò0-àİ¤³%v"4p‚¬,‡)£ñµÊ8šM ´8'gÌm‚÷=!lÓs(ä`‚üètºËÅ:²ëÓÃûÖŠìI0€OŠç_P61vÔwğœo‹B’#™¦W:œfÅ°ÌÛ‘iM|`:7Û$É(ÈŸx—Íâk5‘áêF"±û»áí:kü@9Í¶ıËAÉÇ-×R=­òR¿0½b¸YÂH,şBcZ€‚&\/,9Âè(F¿º<#@1¨ğqá®^´›¸TÄzDÂ7ó€c™µ«ñ*^€·‰Î^Fäƒğ%ë>_wîı/öJº´­å©š&‡Fy™cÑ	>Ø{ùüŠŞ2•À‘…ÊÄıIf+ı™”µ¥lërÜ	· Ñ`®çåß˜ƒÿ‹î¬ÂÑÑRå4â˜!úÔM“åÏ‘Á	Áºd«í€Ößpâ‚IÒ\¹VCchXˆŠ>*º T¤e= µ‡OÅ q~V5a<ÌqÖ~‘oX_2ñ$÷ÔyÏßüÿÌƒç½måıc­Y	#}„—Ì}şÁ±'ª®ğ3¾û'QĞAEè³è¡Yøwrã™P¸×ŠqÃµÆÜ!ú‡TUVi6)'~àeîMà¶:Z…àÌšŒäXšˆ}«³Ş`¸Ör|”†Å·ŞÛ ‚Ë¼ßWá:¡ç—,İÓ#:¢\ıÂ}fíº@ÜTHÃ ’Fk¡yåkr×"¬áWÊ‚%?
0y)Z„Õø:lzÍ0©Ü´ +Öúzİ	f~'ıÕ˜“‹É{ÈÍ{k¢¸Du™cM	] t¿°¥ñËÁ‘ÕÎqò„|ê·Qbª
r¥C÷wö£]×L,wÿ2êËj'4<û‹…š\–^¡C+›MŸÎ"ss0É“ŸFáK&LjèñRÄŸ¶ÄínÓ‚Š¥—Æixd*kÉû€’˜“+ËI©œÑÅLc¹#*CaY’\šÊ Ú^ÿår`Ò¤·ÖA”¾<ö9|ÂğB³ˆPŞDMlšëêoÓ•'37PL­¿HÔĞ·¯©FY½˜š‹Tl­ª‘K*âºõlÈÃgã²•†mKç+ ºÌ7î~"TGí©û2PXñšU,µ‘`Ó•›U»š®qSÒé¢º¯%ÕzîöúlõÉ—¾z®ÁãÏM]^êô~Æ„LW”/ºğ‘=1¾P`—Í f2¹M"g08‡¬”í‚á¢;2­Fõ÷?ïğOšÕæú¶kfÏ«uÁÎmÚİIOÎht!c/1h…­T k/aƒŠÍ)(IÀ$„JĞÆùbÖ´ßŸédeÚÁnÑT:¡Õ¼­ŸCZßÀ^¸ÓØÊÙn=“…UØ3¥Û58a}(áB¹İmjŒŸå`íw7êë&sRz/`Y\ìœQÛ\ûWua˜«ÿN¥_`}E0ƒPAĞÑéç Òiü ^R¢¨pñ¯ˆîv¦¢PóEš€sâóö–Ëë(Ù±ui¾v“‘³ÏÁçÒ¸€ß¤K_ŠËÚ••¶f.5êüæÈ&¡uİ!÷yÌ ¾¾wíCpDgŠáæÚùF1öÊß¿N~Zv³â{Ñ'Ì 3?§ tKÑ£R9Ãrœ4èRÏ¶§¨)§Üápò˜<^”!ÙèfÉãŠ)µ9ì¡Šd’Q%ŒÓ:QVzaŞ[ÎÓ$w™2ÍyvG_*!¨y8hòüªãZ*†Lg
Lçã°“[Øfvë]»y4š¾Jí‡ƒîüórq—ü§®Ã:Ş_ißÌÆä‘ÅZQşØnÂ?ƒE´4\4ø#p?+Ìeº8¼ö=‰ç¶q^Ù29 •sO»cW‹=Ê"€Ôâ'"Nn„&—y/Ú»:%]—)¹öíÚFc6¹¤¦á­•ù>–‘M5G$ûfvë5ûïE©ß‘ŸˆÙúpIôŞ›Òm-"$îüÛê¼CL¼+òıñKš¡ÜŠ„šJÙ4*Ğ[ò&×^ŞY½}YPš©f$UeáÚ&mĞó¦ƒÀq†×—q*üÂ h´#`Cß@|ìPÑİ (äLq>	f„—nY•Wî5×¦¶»'0Öà¸_	+ÒMúğÅ@
³§EÁÑçYÅyÀ?¿1ïŞµa¤ˆ¿|
-‹¿şàÛ5|U×÷ÃJØ÷y?¬ª£¸7!_É@‚ûÌ—Ä°óıCçòò °
qà&ØB÷ÒˆªñÚÆ2\‘‡Åk7{«ƒò§æ.pnÒ«ÄK	á«©3 wš 
Z–ıƒ©Şuıw-{±¤ìyduTÀÕ‡Rö9«üˆçF¬OßŸ¯3"c$Ö.>Í¢"ÀéÙĞ†õÓ{'Íê`ë´b„¦~Êj/Ù×F=ìãBÏÛ¾¼2•ş3†ß ì'/§öğb'án©ş½Íõ¤ÙÆm¸¤S§rì»Ç´±6°ÔÌ‚ê\0j¡E·WG4-âƒëÁT–İÀÏĞ[ç^†JpE“ÆcZÓQÀÖÀÓ¬Ü”Àx¿ºí¶‚,èœ)1;"ƒM²E;µì›¢«&‘¹…Š¸g¬È¨È;-Œëœ¶uèˆtX±ÿDRÎÿÅvVãà“O=éŒŞMù$ÁÑ\÷äÑÍgÙÊ»A+¿D¨ÖÌw¡R¢V*ÙDÉ|ì?šuz¾Œ´6_ûõ ^p®Å¼JW¬Ï9¹ád†9¢a¼BP?c7ƒ¡åØ›èçÙóı/ïz@"ÊHàq?z“LF/lHòÜ·q~0³ˆoePÑÆ ğş¨¸Õ.‡‰'ZY	…O”=m¶È*c@3eõ+KMâ:!Â#­ó¾Úvºçı±o1ŸV–ƒLåcu'àÃú/6W†õqšQ ßr4c¬=´EÀdIf éfßÑöMlÍp¨™£'òíìOÅÛ†/…Y z¢{{È“Ğ‚°88NÙ`½YÅ…7¢4†v±D¦%„EŠ7#Mx©¯É¼ššhÊ·|÷ıäYH¹Äƒ´¡Lv”Ä…k×-d‰ì^7êÓ´¥ÎM‰Õ(O~1ì^ŞZ¦>Ou…(t<(ÕÇ¡G}@.zÖ³í_¬ ›Íj˜XíRF>Æœéh¯!`¸«¸)•P:95Â³:=¢QIÖ»c1¿+A,Šc/Y<‡M‘¥âº<ö¾dŞ¯»àkqšR'?9=|g¨"vø¬)_,o‰ÊÚÙŸ| I»$¼uäjä<½ş#çÆ¦ä®D¥ÇÕÇö>OªUªî¦r ƒùgg&õû#_eaèº>N´õ¿QNŠ¯|×BŠæËâ‘÷@Cc@Íö*rÙ|LşÒÁğbğÍÙ¯“ı6aÖ9¿n™ñ¡øÃ;æ?¡A.±U_qt—¢5Éë†]¾y‡W¶şKaŞÛv…³ç‘š8Û¨ ~ï‡Ó€Y3jÁ¿Q@`”„±	®2Õ*‰éó/ÇB²CìóxL)¡‰ÃA–œó—~| çƒôt|ÂÄXN¯Ö’ºP¯^8üéî¼¥ÓA!”6ê !òOæI$­²«ƒÌ|­:Î´Ğÿßø½mKÄÑ„mBq™tÍ¬™Z45êÔÄv£ÀÅ5ÂDÂ)uøº$-X™;dçšÑÊ·b—3Û[åë¡½w MJú[×•è^ñêŒÎ1ˆñËÈ3ô öjnÌô·°n8%#'¼`®áĞNÀf(‡ƒƒn×rÃŞE@:¬ÊkúJN¸Æoã‰ir¢×÷Ÿ×—m½#æ>>Š6¢Ğ´v2"æ"4 ZBŠ8¬Ìv”Œt4íÖK‘Ur+‹ò¬íàûœš°ÍUQàlÍİÙb
•ì°Ğ›ÏÚlï^|+OòÛ"V&mçTª}Nm§^Ü«ß‹[Ş(öCÂ$ÔìÿÅ©8uKæ¶!t.M½ä¯_bùC†>nÁàğ)ÒAÜioû‚Æ©àÉÀÉÜ‘m7ü`1–”¥$ Ïõ	h
cÊ¿ÙÆ0–œvT*ÇG-—D½)+B_$Ñîõ~?Næ«¹LêGİdác#.\ŞĞ\Ã+G"Ìû€gáÜ9¨†LCùüWÆ\IOTñ†w¦‹ˆÙ¼ƒË—Jq‚Æ6Qï¶ò­&Ë&ˆix(ÅpÄÛL‹ã4ÀÅ63˜\`´®zo Şˆ‰ô6¢˜=0‰Éîå¥ù;ÎK¼•á“Š˜Æ	¬k“ƒ9öhÌVÍ„r&§Ê³ıò;±`¡—ášSŠh
“V‡Oß“îa;ïÃÉëß»ùâ;^œ£f´‘Øx¥|€»Ø]iÈ@Ù…e£3ƒÿsâ¤%É?®z3‚¾¾3¼$ùYOÓ_ñ/ø……[Õx,Û„ 2?|•â»°lmá[® `ëš:-'¼‰>*AgÁ¡;w<áãPÛ©j¨>‚ÒÃ+Dí€>æ>ï2Y1NnRtäœä\0®¡kè/mÊT
™£ªı8q[¢[ÓP=6ôÀĞÅ²[ÓeİWº9Â`Ê‚ªu+g/³é©dÔÙx iÃóÍ˜Á;`U“à‹Æ#n"–,†øÔğ•ên1?8¸çà*YB>Ò5T[6µì‘»8Íé5jf°ÎO5œ;œ” Fıh„K-‘ ùØjS1ºĞx™3üqá$åœÅmˆwÎš¢²1vx¶ßı'x}Š/ÍjlNÔIÅÍ)|l+TëIsay?=ÔlO¢¤GÌ)†u~?»{VØ>§ş1VäÃ»†/[Iìö«TÚ¶i*-. ›3ªRró¿"F=X,ÁçãÆW	§ÆE>œ÷àoLò{õ÷µ2™¾ªŞ/ìÉ]£J)˜#ÃŠ á6ğÓÑ¹LŠĞzBºËv ÿçUX ä®‹NüUŞ—ºªÄÊ"¯;Ûfpã#2i Kïü“çjçéTÇg‰ÜF6ï$U½ìB×º³u^(I¢ú›“Kñë4R}ø¥ç³>;±İ!™>)Â¬işsÅ™b…V¿MÅ}\[jš¡©€‹“+r¼&ˆW|ïJ™c-Ô’3ÉÙC13|P'¿.øt“¾1Ôª8é—Gª%ß†s;ßå,Á@Ä‡—D¿œ„3|‰f’¡îŞ„bcµÊ)CB‹lƒì$Ù«˜õHp„\*ø´I‹QGÁ£?ÏIn{z—jeŸM^âR®-¹Äìó‘c:[¤ôƒğ(ìmõi§I%÷^€p?Ù]3ÕŠ&¡î@êø´uªEåG*Ë×{ÀÄŸÖ/nA…\Í©§CL‰îSób©9#)¥’N‡³şëƒÎî"c†>qPzê6§ËQ¸no<ŞØ¿(Hä·ó!rç‘ÅYÁÜÒö­o¿A&4Kë38c­Œ{©>³"VU²ò¤°{)o™:Y¡äï.ïó®ìC‰â5ÔØw~¥Ë{»N…¯ƒgÙŒØ	7¦½I?Ñ»ÜŞ¡/ìdó˜„•ğZxı{Vı8‡–ìJM)¨´m=™q×…SE0ë(ü-<sAÏvXËşqü¹DÉ™MîlúÔlioÌ$&½¾šØÓÆ•*Ü«ÖC'í Qx›¼óE´ß«jàWzbc¶è\?RëZäó.Pûõ `km	ó~mĞóÉ‚Œ¹:õ	-°~„ë’I'%ÒşöÇÿÙ°Z Eú{“-ı,ÆK´5ïë/ñW³Ğ&p”–½/ÁÜæ1x*g=I>~å¶‡F;T¯9„•Š!´`Ú/œ¾0ãWRùR³úM ¿ì°oOûğg¢—±w(óú¡úä~õAıõw¥%Új²}È.=;^£¦®/I6|JFWN>½ejÚºëù]5 ³`ÆÅék”Á´£oièÅ$t
	ş­³ÊR¦^åú1j2¹Ò Òv<¤1è}Ç%“úş;W¥Y·–ÍÎ\9ßÆî}¢4Xe>¶æ
ÙøTôú_Ô^+µáwe_øŒÇÕÑI’ó‹°…ÚFØ‡U9@²Ò£>rÒ›”05Ö®¾ˆ§ûœCÁn¢çk©%Dğ6„ÖMªän ‹Z"DŒÏßBÚ‰1MNØE±“ÅqßÏ½•L~wş

ı%4½ş´Ê81D6(¤ó”f¢`µ	#òLïÁ%ò¬½ËÄ¯[˜fªÄ€•%{ßjtÌÊ7Ã]*ZºÃ¾bØ0]&\_·Á¸xØÁ"šŸë…yı;î‚—É{_É‡<„ngW²‡°a ÛNú2Šk1­Şƒ—ôÂOÓÛ¸õZ^¹×.Ã¢ÍöA°“ô|Q‘´T§)q0l¹Ò;´37G tÓ \í…^õØ›ÁÎ]şMÑİ£º1æ‰r6“–îD¹ÕìôÀ`5İ+šç¹]Åm}ĞæXjŸö±ñç[R–=¹(%DËØ€DÄ‡¢NÂ ¶=ÈÚ:ÖÑŸ©%+ME†Ú4Ú¤,àÂùxa°°¯1#ŠÆVØîN+¡û¾uEìø ÈœÍöØ¥éçC)í–¨Üœü¼O³üa¤ Ä–ìıÔƒC‰ÆÃm¨Í°óUt £ıĞ·51‰•ïì:L²ˆ“°Ïg•B
JÆÇ3¢D», ÌwÁØŠ)¥›s¡İ2ßòÍ-(ÄLK öWW›R¦µÄ›FzğÀüv-s²•”kKq¹ÌmNK%c¼Œö‚Õú A(‚Zİîè!Óşï;³¦‘xom`È¥ß½#L¢%®i{*Ô]©w3˜¤¸zóL7UbzKB+š©¢**(;m¥>©HWÓ”}?‹lyà¶½´Ò„ú]„æ³m'‰‡œ¢bR±H3óHâM¦<={30}-dÿ@«¹yú g4ı'{vr¯ÔÙ!MŞ@‡ãÚÂ|7‚Ìğ%Îq ôãYä‘ÑFÅëœï¤ÔWjøY&CA÷ÿ<?^çv¸fÀ4ÜA ¤IíÊÕƒYBw®âÙ—]u]Å"g¨\Šš¾æ$u9~köVÔÆûdr?ÁZ×(t?¸ÒÜÛ¶–&ÒÒ©‡Hb@U}ÁV/`Ç6a¾×ÏˆËG£÷`æİÄ9‘jIT¨R¸ä+oOˆC2³…‘ÑAôØ»ÓÒ_Œwl/n-]wKWfªİiT²cÙ®¬¢ònƒ?:h#®Œ_ƒß*)Oıy`~|ş†!°Ò•÷Ûî)˜_ç¡)‡®íã“H%ÙX‚—!…|:@®c4wƒGÏó¦Šu[Üæà¬hF¤™øT&"nÉQw>âVü+Z`>®²Õ<œŸò(›„Å¦x/ E_Flm]òå^ı#»ã”öT“I1®%Ì±¾”sÛ‚-]º£ßb“œ›ÃÊk«àf2óÉóœßƒ
›Ê±Ê’£ÎhxyÉÖŒ§Ey¦'_çÛEÌÅ	¶w×`äx¸{_éÅM|wC±õX×„*ë†$ÍïR2Ù:3ûAnÎ£?¶Ş³¾*Oş„ÊõÜ&„F}Y}hfùs~68æK8U€QÖë·–Q¾Şáµº"®qoÑ@‡À8Á¢J„,ıuè¼uÃ¸RÜó3
Ç"¨~ÔI“…BÓÍ(Ğl½dù†¬W™Q8ªjÛvŸx×¨PyT{×3Põ~m/Ûh—q¿zÍ82–ièŸ{â÷˜4ïõ'%.øYB_¢í‹ßC¿L#Áœ:vÚ¦Ş•6ìó#ÛÕzÃÁ©&ä6¶¡I,Šyáöß¨ÿaxY\½²©½„d‰ö‘Ñ›1»­¨âÌ¼tè6´o^h	á8¯Ğ9RúD (ê¿>öïÖèò y)Jäİ¦ÂnÏYVÌ…¹Ç8f…Ezüß#–7æ×È/4i3Èÿ çD³‰t°åíÌ$ÄM+eÎÜ%LãO>Ú¹g~øá²ísmBİoŞ­ÀlÕ¹†‡\é«Âûmßö”Š° ÔÍÉT1Éã0æS&­E•Z¹1íMCw'‡‚ĞÍÚÑß8cSSšyG„e9è²Ei„¾H<‰òˆ+r¯ç(l2ƒç›®--ZyUFu@3Ê‰p_ş¶öŒFzKè«ñÉøülXtİ¤§hcZº=(¿|©äõmeOj}N­L(S”g7iËö‚/ö‰¶ŒÏÅÛóf[‰HïøY•óTt»“®ÚI¦$Ô§D"R‹Ëû¼¾[F˜ÉòâªbU>W’«ğÆ¤©KwÔQºÊÂnÇV&Ì6á*ú…Š“h
½Ù\mz‘*öƒ?D™ÙçPş6AÂÑêÂáµ¨; Ä×,ÈTSµ*Æú†prÃ6 j»©Á£ÿÖg,I “#hÁú·?uˆá`h#ÕgÍašFìÄ½L~e|İftƒn3£RH¡z¦€ƒèh°F4U¿ø¥iìÑ«eĞé‚ï“ºµ€'¾
«†	Mh4Gº¬!'qKL½ˆ"IÛ]Èó3%#VıC=³ÛpŒ‚,¼[òê¯	ì:±¤zÛj:<mïÂ8ò+-pa3X`Âz¼¥Z	«pWE–“ÒøÂ%u‘÷Ò³(ë;Ğ@¾¦…)—ÜœX¤ÀÀH“.î¼Èy‡ïšt@éÛøñ‘mÇkêç8K„õ<F‚9àÒCä%‚â*Ø ~èªÂåà“ƒ‹>À6P„å }ná¶œ$¤HåNÏ–/Ÿğ…#Fs˜Â×ıú1¥î°¼¼Ê^k^²Ÿÿ¢P;¥Ò«/îËd-]íQÂa#°Rˆ©l­!Ê	u=¨÷fœè<‘>şÅŞ]¿Ğ[Èo5'"z.±.Xw¦¢1Ú­|n›×å·O	oÃ¡àéfÔ˜½t|´ZÏb¸¸Á[¾T ¿ĞÏŞ8D¨³ä½Ó9kÃ7\¯áª\‡b
…A27Ã:õupYPîûb[æv±ÛŒ+¶§[õ{b
Ç)²ù}˜£õ7Fê?2pÎs¦»m9¹>	â@MØš”û%	îº™‡X¬pÏ;eæ6^Î"‚ÉË¶è1s`ïÚîHÇÙH¶vÌ(s|ÇcPğ*v“'Ë§ş°î4Ú¯àÄÁ¬Å]°M·€EıiKî¢Ûıôlµ	$ÇÙšöWÊ–§š®¹Ş+*×FÕ”E×ŞyK±5E:W…‡›gıíÚ¢¡Ç&È,{»¡XKW÷ˆì˜MÂÊboÆyHLíä]»NÛV"Õ¤÷xÀıM³{‹°¥®>á­;¸‡Û~Œ_gPÛhÏı©Hšô›bã´"Ôåÿu{w6ıÄyuº¤Öµ!Ó;Û˜¨‹Õ&™ë®fH¾6õZÀö{Äë÷jW/’-ÃÇ¤ñ÷«ù’‘W·ãˆ~m|×Ë×/µ"yş§pG­@wßØ%¥öÃÆC>cxÜÉr‡õ‰BìI6Üˆà–ªrŒÛëıú0±ÛF\í67%UÜîû'\Õöœ~*<ßO½oƒe#$gWøØ¢L!INş°Ê7F]¹´B8üÏdŞ
hµõkôa =Ë›Ç­ıÇB^¥/ØÑÒXõ|© M;.?ô}çÌ>öh"·ó³ä¼@æ$1íÁÕyry` ¿{æ­ItŠùøôJSÊ
>|kÉŞº°&§ı1…¨DÀÒLÈ †H©®9ç‘îıH°—„Ğ^ÇUObØ7:fÅÂæ=jñšfÎºlD‘£<ù@´h3X×•µÂ/)¯ÿòê4)ó£ªĞıVzevĞgêóKÓã´Ú7,‹3ÿşÊeÈQG¾ƒ"÷ ãYæúÂË6pğ_P"²r„>ZˆZ¿ß§ä™õo¯ÕQŒÌ<Ö ÅÊ§Í{“ëùV‰OS§½º©¬õb³—¯$øv4RÖöê÷¦«š³¾Eço÷&?§İË š_b`‹pWK§¬ú–i(ÈÍcªA¥uğ­Àµ&’ß¹@'vÙVıêâR2È#rjü›ºtëX<l!„÷°„ŠQîåJÿZ#¤ àXMx£¨%Ñx"˜r.¾—_:MÆéÎ¦îSP%BvÃj3º­y‘q¬¯çÉfëA OqmHƒ«L¯zgÍU·%j¹4!(H{>%àıš¬Ì2ùfk¿ujTr¤!é¢p˜§Yóh!P2ß —y9
Õò"îcPZìŠò:
ÿÌPxOÇ‡æ¯gÚ€—©Å¨I7>¡ª…Óã¬n(¿è$€ßÈE–,àÌMjVZÓŞ×úÔı èQ˜ˆûòÿ÷!b`sìgÖ¶bôü‚t¬«hp~ÅOGß<ü]ÕmB‡Ï˜ 	«Î\,÷h ü5eç›xöâjCP×gPÄ™X2cvÁ+¢ÔHépş{ğØ”×›àÁM(˜ÁÿA¾ÓIÇEj™Á6ÒD†]°Zµ³é Ô™Ş…ªğU"BíÉı²Ğ¶ôğ‡µæxÂ#æJ—zĞ‡aÆ”ÔÃ\…	ğÄ’×êöãšr%É79`–¤U·ÈHFi5«QÌ“ÕÊÃ€â¯>ÌÍrr>WÿRÑ‘Tdt’ÚÎ¦\ÑÕôĞˆH?„‚)9«€ŠZƒÌ ‹’»½ŠK©°|s°Ée•NH0/Sµ v–eıÃ]µc%ËLw¸·ì@©%&u»MÙÖªhÜûè.møpYµ¶ñakQ×—–’¡`}#“á²‰¥«ÕİÁXá§PÓW!ô„±öú9AB+¢'šìs/ëv¨ÂÖ;_
L-ŞF¯gãm7LıNƒuÈ–ëà(²^mx^ZNŸMõ]çA#=#;Ç¾{V;pY‚ıËÖ÷§¥	·Ã·êñZÂV¯~pY4oº*zvğ27ÿ¯b$½(
Ÿa¥»Y’“C'~Š®Ù?Yk/R^‰œª¯Ñ{ÙÙ1`|ïHPò½^¤_ Üayó„B®l¼jC0P€ğ;eiş-;¦–jfïò­"Áñö¯Ü0~ÂNë)Á%Ê¢ï,è‰ÙÃOÍ1ç‹Âıİq<^ªò3ÜHÉ'™’uÏ°(c5à–µJxŞ«p¡ìKšitìAw0&›Ek?SuÕÿÿwŸô:‰Ü®¼ÄÍ²{·Ëy>Œ|íÇTìMyÖ~¨¨^¼•@$RĞóeS B.Ì(“Xº5ø;‡§Ïh‰à%«×PH¹,ñŞì²IlÖÁİD[,ïºgÔqÈËòpP$¸4„€@RiN—í_Í$„•Àâ–ÿ½šºUÃ«FOñ1Ò"4F;ÙˆÇ¬(ÇÌcÚ¢¼‹‘ZçörË:)Uû&šÚ+¦¢€¥Ó{³v¦xsÎƒ°]g¡´©ü:pïîn¶5›:h+Ÿ¤zíÒ*°”Í›ë‰:?Ò’Ğ„lŸÃÔU]ŒÜe;¿©ÀÒåI n \‹ ±h')Ç+´y#épî&I:vRâFÂP$W†R‡Ã İyN‹\òˆCÅÚ‹ÌÀï7Taúá–=VÚŠfÓu"+>~§êİSR"şÍ¶ 
÷îÎ)©¶U¡ô-XBŸ&‘Sp\ˆåu˜-\‰\æ[¹¼B‰Gd,[–9Ejìè_ıvSM,Ü'üŞŒl~¦\ÿgŠ™iVêcKeÍÅåÌ@-Åu†„{Ÿ¦ƒ.’=bÁbw˜v1–‚Ê‚!Şx3÷¼ÎõıÔä6O=µælºøîÃ¨PqÁ9ŒWq¤ì2e¡Ãß…4©Z›1şèŸ”™	œ[_¯"ìˆ©Î†Mî¶Ï('AlÏ›6T–¾.uÆ%¿³˜AŒQSû÷ƒÒ”}ËÄ¦k ¿¶iÇE´¬UÒs`U³f”«XÆu!Cjù¡úõçËü¡$šçÂg‡¾>·uÖ§&Íåœ=±ÊZ12*=*ô¦€Óin€I£ôÕQ«àgıƒV¶NŸÍé5#¿)·¯öèßºGõ%ÌŸSøõ“4á¦q\æ°)÷	-~× æö
Âd´ı#ÒbÁµë’¬˜p’A‹ÛóQüÏï;gŠİ5€T¤d1ò€¢nö7ë#JÚâê2äŞ#1—³1|dD8'¸V øºˆvÉÀÖ˜"Gt'æ >sDû_M\Æ¯«6ù²ç\fQvÿê§Ï.©Ó1)u¸µãì_íünk~m”Ç/V¹î"¡ZxèÚ‚ìoIú—Û\Æ5Fª«W¬º§íö´nÎ÷Ü‰ä¢¶Š?‹ ‰àªtFJ@»@ºP}é’4TôâPNÉäÿ:'­´çr[n{ŠŒU±n0Âte Bã~êÅ~˜ôœõ¬‚ãïœäOãU×ˆÛ£G¬ÔÂq¨¾Ä#ê0u.­í¤Ø®({GwËêæ9bƒd[wÍãùÏàÈwí)(Ç1-Ä_Š Î¨¼É541ó“î =2=¹AzI˜÷—SºWğİ‰Bœ^ºõÅ3çäïŞôeş¡±ˆ ¾Ğ]á•ˆ@µô0“%ü6JP)|õù‘İt…Ñnª1œZm‡7
µ£À¬ùîFEò²œ8ø i¶ˆLÊES,J+Í²S*ã„²¿ı¥­5°Tºôû^v,¸Vë‹Û¡g#UL‘i¡ùä™+l¾y;±ËeÁ0®•Âéí–¼cÅÄ¥ÜåëÖîH´Ì·ÒÌn9ÒÅ¶*ÜÃ¸2¡]¥Ï•[?İ¡jöÅ£Ìßä¢õ4òŸÏ3W"9+0®Ûì[z¨ñ;EDÙ<ÎÜÌ){=ò¤Âuâ/ÂBÎ6ü&qØ_ú˜ôaú*¦¨¨ìD«½ZËÏb>1ªw±—âïÎüÎâÔ_XÔÊ×µò ¯é¨è‹ƒ:_Ÿ,¸‚c¿uQh—¯È:iÏ—")Á?.mÇPLÀWª£›/z%UöQrñw€ªƒf›eg”h¼°õs({`SëA‚LTÈÎ\~x_Œ«œ`Ïe,ô{½æ¥v2æÎí„z:7£`7³z×¬²îÎ™^´"Ú¨Ğ+í4áq(öê¯I0Ø ö¨¬…ÿy!ª(+Sµg „<pÄteœS—@ßÙ•k «¿ûšóBLGrVyïáÿCïîĞ¿¥. â®fòù;?ò	}œíiëQ…ÚÆ™îïi+p‰ÚX6:ót$öaXuÏºrä,e¬ú
£«?="ÕÙ±¾ -Ç+ØJ¦÷Ö‹ïj€A-X¼=0Ÿ¹šókN°Ô‚%mDT
:ôpwÉÀšµd”Ä'r!?0ˆğ ØW”fñ_¿6>q…ı¶Ìm`«miU¯øÍ)—¨N¸uõŞW	&œ'Ã—ãÌ¡o?/†Ú`ÂÖ§”ãfcY—c”MYúCØhbµ˜>ÙäË+#™úl@x?Há(|‰Ø|ğU¾gP_q–vÂÄ¤ŠÂÔ“—å÷ıcªxÖ»£Ó4`õ¢ãsÏÀ´q/7í€©&H/ñÉ£ËƒÕ#§xU»ê)õàåN’¶`ÿkOô–VwA=¾İœÈœìQ@jPÖ)emÍË¢w!áçnw}Ù?èæTîs§ÿ
j¾RŒå<™_yîÅyd'ŒÌíXÚ°bâX•JWLTkz]p…?@ÜVjÚô±„>òv4ß·Ë‹ÙVB†|›¢|­€1K^Ú_(rRÿû ˜VÏ~0ÊyĞ¦H8¿kÿ]#oó£64ì=/M*zK">TºŒ`„V¿•Òªîf„£§Ø0£ù¦1a´Œ-D]Q¥ô_5é kø Éô•ödrüæÉ1t“-vÖ¤´+Ã76åƒç[ÎzpÅ_ŞaS×g(‡õ8ËÍPÕOïßôºº¿W¡ttÜßT[±vÄ¿;Vÿ«0J~ÓòQËJæHì,uƒV{õ¼Mì•“àìğİuMTqEbv(®Ö¥îH‚- SØûÀx›uA1Æ ¿ŸË$%‚Äı>b:æîO²NK–FÆ%3ëa’ßs>zö²%uXÙ-©=[ÎXBš¶eÍ·CÕâº4Ö ûqÙ‘×1™¡BÙB}§ ™D‰S-À,,6„gy ¶ÆD#›·Ì‚åãCár…<·]Ù>$v(ÙÍáC‹ÚAàÍçiRóLÙbYâÂÌÆ,=¤>gÍDW«(
e·”Lb}]°#ìsbòC„£“TÍÆT`Dû=ÌOÂmÕÀ2oU‘æùÚ¥ç«™=ááÉÌ£~×¸1ÎŞ˜øYtyÁª’å^'J¶Hz¡%(à]ÎŠğÒ¬iä©S?€¼ÖîXºƒó“¿7ª7¤ü/ßÌE”*Õ³Å÷ı¦Ğ›d]"_Ú9dœqC#xÒpÇÿ…æó…¯Ú&×¢¯±Ë˜ğénO;v¯)½ãPıg˜)¨	-h1¥æîÇü’ø×İ{÷#PäE¦}İ½‚r›"óØ#od—Es5ªOEsÓ‡‡0ÃGÅ-µÌ”{ô”5ñöÂØãK'ñ(5ù*n`5ôù­ïf.’R®Ş½ÒĞıO=°kµkû‹È—TS4\.>è‹”’¢Yê•ÃeV54Ä¿Ò+Š4|.’nU¿Ï_ „/—ÓÜËñ*Èh!€Iüá^ø)2xóŠR¶!X#0A¥ˆ,á^¡xÿK–9{ƒSÒ{Õ;öWäNìmô.ã1*J"µ³bsüÑ—âC8íş~ÜÙ_;=Wº]òõ'Ùã)¡pwóŒåTîI__Ş¥ÑC¤ƒ¢”«nƒÀxüËœ[O-òMÆ×s¶åÎv÷y_Iüoë7Ø§h\ˆÈ²ÉÓõ¨*·ËVLŠ¬Ç.1æE‡£S¸¸§NÖ|>×ªÄ3®YC!c¯euİõY°ÛçXw¸jÛk¬é|·î‹Ïëc"ø;¤´ÌŸ_EÓ?åŠs3ê¼úe¯Q'˜êçó£õø¶š³Û(°Ú˜‹¥™nèØë<•XBl~æ¿šv|¨;qİÍpÈ”š)=‡lÜÁWR«t½ä¬ş	¥´Ã£&–´ToïíJq{¥pÇ¨~2ØáQŠª¸(æÅ;ˆgÍÌ-„ƒïm5kÊû}8ó3uu»¸­álK’…8^H~.ô<ôªU«¹Ç.ÊÜrSFR#b#¯˜M^!®ı#¶b×WaÉ¨9-ZÛ5N¥AF6R½&äTX„wä|LÛÕHHC5Í÷0`^U?ÏÉaƒM=–53ùù½C&É{ï1î>¨©s7H	sŠ¥0s	eú’t-A¾Åš²VVa÷lîøÀ˜,î¡ú#GGéZ‚Ô
-ğï2B=¹ÍYI“Ó“•†O!/Îqñ; á9‹ÇmÌCĞƒ@ÛêŒt­ĞhF.~°À¯åµB0kh8…¼…ßà÷dM¹6¾C™€–äQvQşFNì*WlÃÛƒ^3±¶ÇÈñv´f–TW,B`û%¼^l5ò¶1]A£J:\Ô’0ÓˆG£:£¤¶,KWşAåÏ¿sÃ‡¢+àƒP7’šËü’¨ü`øœ:„=M˜]ÑÊ+/”{|?Rü©m¤;—­²5¼¢©ÚÇùà6½ˆŒO.Záººm˜éfõ‘¶\Ñ|ÿ]1©ˆ8`r@óß(8HY)‹D¢'SıUécßzÍì©r·RUºŠJÍ€û®¥>½ÆEÑ]5İ[ÿ7í¹+ìo¹–¡jÒ1^Š¯åÄ[œÜ{í"@¾ZZUg¹ù50¹è]9³,ôE›Ø–×±jR9cÏ—>¯ÙØÁ=4´2»-ÛWÀ¬H®ãù£×¦?†çnçõšG™ˆ—2}ÍøÉ–æÔiÉ4à8c—Şû}6¤†ü¤œQo›	× Ğ¾Ásaı>eááó˜ Ä«œ§ò‘Œ“bÇÿÕğÕ(.(Ë.^à‹C¸d®Ø´YÅçÕ”2pBÇmÕ$íµíWv~m@°d@–d$¶zAHôª¬ul@˜Mp,ifÕnĞ°ß2ÈµZ¶Yí³rîAÆ÷Zõe¡JB‘·úGüV¸
‘NMBv+÷ôxbß_åwMİÓ[ãèI02 ÎBGVô¥Ôºõ€)Œş™)Q¡^JD®å’Ó‰kí‹;-9!¹*‘‘çÙZò–*“¾í€JÂ¯¯ê±é„&]LfkAai‘Ë¥Ù»eztè·)jÈLıÿ—ŒÀèª’äªì2eã´.j&íĞñ	=gëi.	¹cÙ¦ú+CœkŠÙ½aÙucÎœ¯Â§Nt%TÜ²M¨.°Œ³ô…8RëëÎ]ÔÓF±oœˆî±ªö•|E£rô³€"ëØE·‚M7ú-¯›ÒAâÁšqek²]@Xš˜À îrßÎ‹ªÂF{[MwéÜ†­w”Â×h’^#“Ğ÷«dçEg!p½-1grÇëz¬)?­ä.ÓµG‘ 0ˆlÜN`n ùrõÊˆqQúÁ)L:T«g9ì¾áò6F£…¢¹Ü:Ø!ôÈ]Ã)*RÒÈşÇøNj²Ç¾b|˜Œ²´À)`Iï!­­Üÿ¤sşd˜ëlˆIZóø¾ıáãsqüğ,y{5ªÒÓï“ÿÙ–øØš³©9^Q·B”Cãp}¹‘Óÿ	èuï¼2œRëF°w[Ê¹|KGÿ™$~‹°½
Àäü`r5}À•FØÊŞ‰a<¨z’½Ù^œ);Ämø4ÍA¬³b°+†¶Æ‰Zæ:Öôç£ªèÙÍ;â—UIPƒÃ“íl¹ÍY^€ìKü X§€Ó·`NQ,¶Éä†Sï»»x°”>ŞGj«µêÊë2ê;Ôî†åÆ:TItû¡ew…}B{:ª·Dwşá»	½?sËjsÀM¼Z¢>”=šÀ·øöØ£eÙ¥“ fªÊ	4e´Öæ¬¢½8‚ã]YAy©±<½?_ÊZXß–ø($„÷C¾1K³[¾PÇ0‰Ü‡ øàÇ¼ã(¸;§è49g"h:©‡',„çí¤l´÷oñ—SP6Ü*ÓÙÍ˜Nª+§‰ï>&TİV5€zu‹ƒ}t
4ƒ³Êki,'I†È+s£xĞEõ=Î¡ØÕß—î-imãt›£NÈ~İT«kào™®ªEÒÉ.ó.Y–©µŒÁğuÙ•p8‹K{~ù¹ìäŸo6¸ñfäğE‹nˆ§{®ÇÎ*ş<’­?Ä•Ğÿ…|f¨Æ;q… †õÙy×Ø§·r­	OOUC®ã-ÉUbÀšô7vÇ°O7ÉÏµ§0ƒ¢4Œ÷N4Û•ßÙ_ÛğNa¸ÖÄŠO€\¸®«Rh"q3U¿J+@§Wê¢I®F+P)ëâÜùîÓ1PIxÃàQvtâM"YVœX„®[r×qYùpıÜˆË¶®ÔW#\Sa©ú¸zÕÄ?&Oæü–êPÊ¶.¦âEK9 *¡Èh±ãğ•ä…I”ƒBMÌMçRx—à>PöK*!Ÿî‹|ğ„Ş’+Ô[Soˆ—c“qm „Ã>©@ÜÖªl¶$£9gäæ6²Ñ,_$“OCÀ!™GŒg:xÈéÿÜæÏÍÒé´Z•êØ]$-ÔÙJ‰ÆôK¦8ˆ“$ÚÎ\›ÊÚÅÇ‚«ûìÙ9ˆÜX:&4,ºdÀ0{k:BI²‰¤“+Gº%„Yt·JR¡‘<l&şÓhçé`bk4—?= ßƒ_("ï)ĞÎZ_¾'n,î¸vfç1UE™óÂAÅ¦>·ºI…_\dÙ”·éÂ’9§°ˆV5PE,©`¨>ç*òZG[w±'¡Íq¡<ôUfÌç·Mõ¹²ğøë3tÄ;C@^®şôHÏéÈa11Šu<‹uì´4Éí$±©6?I›m89O.Óôğ©Ãöví)õJ™ÍM^Ä²†uAUc9¨?§ÄZĞ>LÚİÒØ¦<áQDmOn<G-2«¯–'z ÏüìÜ\}í;à:Á»˜ó™‚iœ4oÖ™1`c8O©c”²¥İcYŠMå‰‡Ì+Jâ3ÕdW/ÚHqİIÃkİÛÃ47¢3•ùêböÜPo8h¦BŸFbµãù$tdHõéyô}³À9ÉyåC7.m-—‹uTí3*Og.…Œùæ¯ú¦çÖºL0Š³†~‰fnáù'¯/Ÿ@_üæÙ1Ñ»#(¹«b97¡¾IA¿3mòUÄXACy³Ü/÷õ­ò3œwÙ9Ö|»‘S¯oú©è…¸±Ğ¨›¡ot ªn©›@ÏÚ€¯¤OÅ³µNÈ‰ó'$8å;OL$EÕ:g§›ç·’®H|ÜºÖ¢ú$¢-ã\êÉ]5JPîbVªd*~ğ=kRíK¥’ƒ«J	ìv8öexHúQ±MÕ‹ù¶¿Jqáö™3,îMúD):‰dÃø¸2Óç>4¸{Ô[œÑ­’3nÙX’Úeu¼f@YsèÉmßàuœdÃ+™ [4¬º®I ìZĞñÖØ]77FÎÁµ¬¦¬iaÓ£˜ëxºì!sO*DÜòšåö0z`?i„¿<|~F”ZVÖpË;7¸ásÂ%GPÛ…å[ÿüwıxâ4+ñ@¾‰àº'ı÷¹õ6!Æw—ÒÏÌ—íÜÈFÑÀÙ' E¼kZ%6Á•°\äQ\Sav½oìîÌd5îĞ–İö@é=Î¾.+ò94GB–:~Ï{e²0®“®ÕÊ&w0@n­“ÆZ$c’ƒÀ¶n”ÈG”K:ª‚	×k\iG/æÏîñ‚¬C”äx63]aËu-MlÒšÃÎ`ëÏYÅÎ,èÜËàèêÖà"Ö£ÁÏÿÃà«f(æ±Ü2Dñfs<6OmfS|íïj)mLÎ3©õp3
MCä¾³êÅ¶R·gô<bMş«ˆŒrLŠ©B Ac¿ç,‹RÒù_oL…¿®Bªoı$-Ş¼Î9TÉC©
ß° À}O¹×ÍxXé´˜|ı'+¢@ebİtˆIKMr$—¨KŒ.=œÁæokE½9s‰zÿÙåşUØÏ¬º‹xƒ3úÎùÃ2E§ÙiU–Ü^^Çn<¦)™¿CÇ»¹rôuªB­ó3g)KØ‡(¤uê-E›ô†e'Js1Û±ÁÜi•"î¨•ôö«¿/šZÅ<µém’õ÷qo‚-MíylÎúÈâÚ%‡Ÿ¦DL”aˆ¤› N®R’”\J¦§Gu}Ë4øĞV]İÙËÖFílì‡ÌÁZ†([¦Ï¨¢›±GÏ–}Y…/¢>7Aad`‚1[·¤·Ãd»7ªi£d"ºìºR$`ÄÖ¨z´pr‡kCÌJ°o¿È¦är†ihõÅ¬“A dö`$¦•[p ÆÈµ³™/÷ûÀ$ä#uïcw<õøf›¯õU–¬äi´ŠguÊK«Ç¹ı ç®Ä¶ â\cª]Ã¡^aõèøª¸{ê@ÕŞùúŞ¹8ıÕ®›U«÷ú^%€,Få×^A¦´¾ÔÄ§¢Ñúgv4ßßÄ¬j¾‚c/9ùFÀÅ|gjJ¾:AğÛÔ#uÌÆ9Í×[n+¶øÄñs—Vòä•)v¹„µ&ÖÄó-¾j™½^Üöi{ì§şàûàÚ!Ax½\cşıÍ”H`àùÕŒ4<äñíÖ€ ³İ+>æëàpÀÑ³LeËejÛGÕû¹:39YÀæa
êNAYù†½¢Jƒ§¼¨NËû@AÛ~0/Œ_È;OI±š²Bpî¦ñ")YE”=AkêœáK“×Qÿ-ó;8Èg©.®•÷ägdıN™±ó‡Ó­ãEÇ®xğe†¥«1é#|¼šrø@O¼Úad<µ[• sÍ(2‡uÀueye`«)J;]g@;.YŸİ¶æóp•'¹»Ì øºl®~Cå{‡Q¯Õ~·ò±Ô˜ßc0Éà°sçtMbè>¼lgFªöHÚ¯wÖYu‹te ÷'ZBå	Tª¤N!Í®eÊU¶c{¹E8
•r²á7Îè[YS^~Ÿì+ª4e¼c¯Ğ f|1qªÇ1éúKrwVg”í§3Á(!~˜Éœòşä7ı8™;×r7”œ00Ó4E¸<r‡yr%~“–ÛÀÈyY„l—Ÿ?	Ûú4‡ç0K»°±ÔËŞ5Õü˜©7®cÆÉ¸•ŞHÆ4v}vjÈºEÏ†Y&à§0fVË$­¦l;¤Üo¡ëø`úlÁøÁ'ÉL(ï;o ßßìyû»Çæ}Îe Bæz(Aµx|¦Ì„‚"©L±‡øë?çî«‰€n†Bô¬-âß# 	+Ë69X3^MiS¡ñ Ğ~(X(Ş~éƒ\­u¡riÏsmğ'.àÒªtg*etÌÍ”í§Y‚w>|Ïfób¸AP	!M³á(¨Ë(p’á8ëß{Ç’ ÕgĞ‡îŒÓ²ŠØ_‰6ÿåI4Uú^a{Ê.ŒœÛÁá+B¨yJ;k?*àá…jÈ‡è£Õù“R³Çu/ZZğoş½	 ı¿‰ãVÀÕ%’I¨$pÒ¯AÚ;•³{(ıZĞ²0>§ªá&şI(½Ê’ašLÛTrŠ‚$³«~·•ôZ³Féù“
ù:.-2Š
Åà£èõJÛ<`,G#j±¢ù«:ÿä
7œÜ€Có·@QÜ`t€e·Ì(úzÎ7Sámô^d¹ÉK ÜtàÓjşt>í¤D™	ÍÖug³%‚-t“r×bTúì¸TÉQ~†ì=EécSÀ® N¸V®ô*ã]¡‹îB§°†R¯ûónØ4}Wã&t6¼b@D©ëÏ!ø¦¿y…ò¡}%gÿ~é3¾Õp°™ÿMÅ”1|
;şŠ˜?†`F+Õ÷¢7Šú{h@o¹÷,úá„+ã–)¼J$’¥^û8åº¶(jN+u)Ï‡jîWššİõ×X–I§à°I× Û·­øCÏ2¹a:UÆqs8íÄş‘ÃÈ©ŠÈskaIËúu!–SlZ+ÇV+•o´¾ä‰Ç°¥«h÷mn_o‚ãS0’?±(>Ä€8c„	/oV/6
k•_1s+½‚LÅ4Š<¼í6¸&ÍîDäş9‰;ZíûYÎOü–¾ñ)Á6-¦° ÍÉvµŞ¿ü(;Ş»èCSGYzøa0à+Æ.	±İ¤Å Œ•áôïÔ¦Æ9	÷ Çô ~~Bıb´CÆØX¡ÔÅir¾{l suÂÀ¼Ÿy}-ŠÛœ,É^~İÈï`ƒm[jA‹çÖC2æfÍFÄ“)µfï/m¡°º;™Â‰’òbÑxo‡—4„ÆJîQ~ÈLÈÎYF‚m‘T.éöd\"‹-`…ñ¸–hÙiŠr¿Ôîü¬l-,¾VÀ1’T´o¾õLÙ²„ëùÎ!\è/•‘Á –˜”¸0îÒÁéêˆ1óGF?óe¤Sò±›bÈ}´ã1åœÆærr–W+(³’$¯Û-HckÏ<â,ŠÆô#…Óò  ‡Ô:"®06›øÃÍ%Ó!	¢Nï1íĞŒ"»
Ğš”>‚íMBĞÃµĞß5ÜXÇ¢t#üİSf( hGıVÒjÖ¦T¼ùîqXZƒ'¸*‹ĞìYga:õÛIÎw9¿î€%sß÷[EGåÄ0G~vÿÏ·Buw	®§B¥ÑöC‹%)º·©*¹
ûg¸®½¯#•B5¹<3ÔHP8‹pö2xº|´UF\é¤^%rÜ#Õåùæ6>É2_8DràFñ#®nî‚%òä$Ä?"©Ù<úQ/qn\?éLf2Ÿğ]w¬Í \%úiµ‡ëÛ ›¦zBºÜVÛ{»QMõĞëÙló¬cŒ© ¶i,âñ	¿ÀhŒY½¡J!t$–d~„Gó»¬*.ØõIÎì+ïBìğİDb˜´!\/bJÛ~o Ó°5Ìú¨ºÆ<	ìWœsV5ö%ó„&Pö ‹~¼Û°‰m
ÿ«ıº$èóKY6\é´ûÍÚ¬¥„‰c=x×t´«L?'1Ä}R[ìã_¥	Y&2 t—0ÑqŒu
n„‚ûF!‰“-‚Ç6TKt´Óğ³ÛÈ%»ó`W'“ÛLıq§Õ—„ù|Ù³"Æªn‹?IÚí¨¶(lÇ÷/ÆB§R™ªÊˆ¡á§©êñ¾}ÒTÊqçphÈ.Bì(ÌÂÊU«g-Yºº¿×³Íh˜{eŞ½±µUeIBcQnÂ¢¼‚Æ8¼…ôF±·ÀS2¬ş¶ØÙ"¶’¥(9å¤cì{¢f1Ú|ëŸéõ¨ğÕuäy:Cá¨^ıñzÉÒBè¹óƒ!Ùy‰¦šRâŸE§ıô}·°â t*}ÚƒÚ5ô³ê˜ÓÑŸâ†:ıuÃñ«õ¬–§èUÍ—4£§ulıå>ıÿävAÈ2¯¥|¤"ÆÛq”?Éã]±Jyş½•2…{náCI•p7©˜0N@Õø¡)J„û‹öh†O¶@ÎŸ}*-Fb9FÁÖ~9@ë”guÕæ1ÉTrï,’ÑØ U…¤¹ìUs™wÇ¿Su”Æü—“‡WÃ7BJb},‹sšp‘K»géLõæaVŸüòct"Acß‰&71—×“]\PÃÔ®xVY¡™!Tk#a:>ÜV¢¢­”ûÿP ,]I~Eø È£€ğ/•?­±Ägû    YZ