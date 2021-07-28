#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2614094255"
MD5="e89182a68fc6b06050be170801e842d8"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23584"
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
	echo Date of packaging: Wed Jul 28 00:31:48 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[İ] ¼}•À1Dd]‡Á›PætİD÷»IAgÂ-×¿D|»âgbì!´õ	_¥UèjA\Ük‡Qu,e™¥äÌb@Š-nŒ0}6íH,Ÿ:<û9‡  ³3­ÅÓ'İNC	D_Ï?9¶RÎ1Ê'uJ~zO¡rÿ±“à£$'ã ÍØ_d.§ï”pO”ÑmE“†j‰0:—ÖÉÓ¦øæëä¸‡2@Ä€%tƒÁE¿
Êñ-ğƒëêlÌºÜ˜‘wÃ³g„@ïc—ÅÿÅ'YdÌW¦`µ¨qåTMTnèpßd;«¢|	›{Ğ
g”¼“ñ2V¾ÁZ‹œ©Gõ·úŒsxOÄuĞ;SØ¨â&æêO­İ€¨¯	öZ÷-Ğ•×Ì¨ v§p¬DÿåF/DOfd#IwwbN¿w;R6¿“€*}ÆC‡lùøñsçüøç;ş¶à}wcySğ÷~õzìµúÆ&Ô|elúÿœWÁDbÆ2ÀxDN8EdVt_+v‡"ê±d\´d„Éø»D`Y¼\Ë˜ø3ç "$«”¯?|¬ÔÛTÜ€`0ÅUƒSl¥K[F÷Ìi×¯ªèÿılø2Êƒ©W¦Q^h“,šDëÏ¡Îáåò@;¼<ç8V—	j'Í5¸ÏÆÉBi`E®Â÷_ùøÇpéııİçÕ =uˆ­`fŠ¢JÑÎLÀ•ge•eg­ÎC
ïTp{…ÓùÕ–¢Îé·è¿Á xÌ%{.“k•ï%ßeoô"¨ÜnFcÄZÖ¸ÕJZ¼J^3íTÚÈ&ïä†Ãbh jqæ5^E¿·[n<
!´Á@óo)sˆ±`Îz9¼]‚²êtiO6¶2FjÂ”«”zi¼‚²íß·’y¯(¡~«Ù\ˆ2—¸–†÷‘CÔÔˆÅŠ9È8QgS	‚ğœçä[Ä`¨a,¼ÚßÕãVˆMnĞa>ÒÛ´÷~tmHà<dÚV•áˆÒ~×¦Ş¯×³Ã/™2aqŒ-Mú
v3²(Tv‘Õé>@PÜy²ªí‡¾Ò½/z…xjjá+ Éİ'ÃSeÌ(³2¯ ül{ût€éÉEÃ‡ÛZ*DÜ(3"¿Á ˆc âıĞ‘×«|¢…õ8KS)Âo<YYZ,ıSzÕ{Ë_bFÒ%í!åèwñ6.§éÄ°T­/ÀYÒye»/îÖéŒ(ñ¥¤ï?%ükĞjêÂ6Ş_s¿I_ŒÉ†ıy¼ïM…:+ˆ;o`[Ğì[<cÄÀ½B…7Ø«Ò-‡5ÖáÏÊCQò8¿  æfÑ«$%f¡ËÏÉ°*ã19¹bİˆ3ãëRühFû¿òWl>ÏögPç×n|BÚŠµômo¡¯ ¢¨UEû“ŒğÓÄ’W!BRt™8êHóc^’™¿¬ï•mÂ
vã1jıÉ{_Øl¢”60wøF&€´('%$•M;0ÎA}r÷0(	ˆIEX«Ÿ)Søê[êÕr7ÏfNgZ™âb
ciŸñàNFÛˆy@ÍŠ·f‡è¼Ñ¦ÓR5Ä"H_`ïÙÂ)7D@µqÃØ6ËÑTúÒ?óEú‰øKDÒßµğGœ ıO§A®¶øŸ‹oyÂ.Éì¥9Ótz…n´mIÔ)M:y7VtYĞ<áÀX s:`s(ºf\àQ™VsªŸ‘àşÊ}®Ú"-	ò°bŠ+|-İ~ÒLø/ø.˜`_HWß™Òzé“-'½€E¢«®(YÓ|"ß@&Úöh®§Wã*äK#¤2Úi7¾èjS±îÚéL³;n­¦HĞ°tÁc—[&bì2‹Ä­İI°°‘İ%P´Ş+ÎƒornÖNl¿/Òg‘ÿ_wuUz¨Ë+È?kşĞT¦(äîw}SŸ}e†zÙ¢WÒıà´…¿í€Ò‘ÓÃÁ‹ŸâÑ¤ÑZ¾ ÏÒÊ¿¼Üe Ò¿wûÀ	möõ”r¸o±–`˜Û¾,
4³ÿx˜yĞcª,):ubáÜ•©ÔºXxZwùÖµ¦š„í¶BéŠi!¾8ãÖ'›ZY.’/"İõé—e$Œ‰é#]ïÏvšóI­¥o¾$$<¶æ[®–Î«ÚÊ—`¿>ÊÄ#ã½mw²Pï.š üÍy]hëz.Õ“Ü_×!xúÖÏçÁ…Xu&O®ÜGw Y$6ïË16.Ãx;jo¶7Ô¼iˆ€O8¡È¬¤J©*ûhG3°£h+JCAè¿`åEvåx{‰ÅòşL|Æ/Ÿ…/óƒ12·Š  ã'3¾x¸«v˜¤Z[¥{ï-ŸC“Ù#‘Î.É‰É~“`ˆõ.MÿšªH_´ÕşFCÚÏ
F¨ Àæÿ@¼mpâ¦¦ğ$”Êo±ûúÙ)È(n®Å%Ò£z#ªÓ0úœ›Îú 7”Ï {©âëD½µ:+Á¬ÛÿÕ¶4îÎâ²ŠYË!?&h¾;|ÿñ›5SrÍAwÜ!áIÓv½y§Ñû£5,áØ»¿lÕñ¹Í”5rÒ‹¤Ma„1,%”ó€ìÄ^e–Ç
’¡êc¦½ü0­ÛF¼Øù‘‚ÙvÔiSæÁ‹aÁÄTwÕ·[ŒNQÊw¿\ÊOpÑB†w7õÙn›K*]C»©$‚I/§q¨Ä½_æÂX[®®7ù¡fÅû1Š§w¿”™ÍÑÒô•‰’'
º_Ü4w{™5õÙş±ğyÒøpª<}ùœtT ¯ª{4‰K£iéE7Ø¿N»yßù¯Ôˆ±£Eú
Õ/?¨d“‘<ÂDC×*%¤çŸkÂL?4rü!€ì-ä¿Š…•Íúœ2öAñ=ü.u‡Õ =Rk|İşàÚç8/9Ğ×Ì#ıé&b
¦¯LgQ^€°7Wbµ89¾z3>
q2QÅûÆ)¾^ÒòÑûÂSğ%ŠK3F/U–7ËriõĞ¦ørƒ3Íyêuşi²ˆšrÉšlÇôÏ1Å‹©\‚–³	"Ø<gwœ¨‡]¸R;Cüw¸s«œ•˜JË5Êï@ˆóâş*[É£'‡–ñòBÄ[¯UÑğëRŠ˜¢·ÅœuÊ :Ç):%>"§›µg+„ó¢¹·\T38ŒE´ÒFZI®T%÷(™²ŒP™Æ×Ÿiô?˜?Şğù÷AàOh6ØªÈÙöshz¼ım³ûïØ–n7Xrpnÿ¿$
/mß^ëX¦¾nƒ70][NåViO©Ÿ&¿à¶np?¸$§*Zôi¿Î²ÈÑÍŒ1'ÿïÀ‘Q:)Í>T<„EV'u¡®ö#}[Ç}±)å]Ò„¨h×ÇêÎ>”TGÜòèû‹©OÈ¨¨·ƒôX:ûw-ÉwVEÃl<£X…V,†>’~CRK+cïÃ(¤[ª’-»¹˜Ò&ƒ6É3ı¡ınª=­(Ï¯òÇ0<÷‰fşÑE×·xaEW‡íDÔZ×7Î>çÁ9{JÎegÕBüB×N¯F©hôˆÍº›ÉZÈš¬·%î±ñ$”!Æ¶õ¤cîF8YU«t†yH”{x
«“Áe6¸Ù
ªÙ,Öìœİ R;n×Û´õI`JO%7‹ø„…/°…ó¤œ>…µYé=¾>;	Ï"Bz×]Lª.íˆt #¤›'áœ}Â»5äÍ¨)Â|ŒèEE?©÷RÄñà–ŠU}ÓØé]Åd^£aÜ’¿„Õ“7Å"õv‚Ùœˆ#›™æãŸnè¬Ã^\¢ÍèÌç7;Û‘ÒíN“•û5w+œğ){$û%¤huJÈ&‹„¤ºeÜåÆ>¬k¡Í“¾|ËcÒÈ,«x¸¸Üb;ôÔ¿’J‘ôû—»şõ9Áo]åœ¼w Ö¬â~Å­ÚN ¬aId/%ÖP‘¯ŸomuO-Úœ»»â‰¢ÀŞ:Á¹i¿·ğÉ‘FŒØÜ Hqƒ—ş5}~	}ò†ömQ±¯L\¾\ó?’`1€â=˜ÙJM›&8Á:™Ø±ß«A×Îbœ’XØ‹r—œ­RÅ%VÍÚ|²kI šùYÀ"âTH©[«Ä.æ«74ÍB ÊQ¢mùÓÒ[™è]$Õ‘q“˜}İÍ/õ
ò§%£H7â¹¥ı{²ÄQ
¥ô¢!y)ÃÏ¹³	F-˜ÉêJ˜@z¡<ƒãœèR4¤òFÎnˆŞòòçúü;ì•˜Ó!éP%Ö8j…wË×X ¯M<<LV˜ùÍ•XT¼U“i*Øn*´­$Øv†Ş§kŠ„3ÅT úy€;{üXçşâsyº1µºÉĞRÓ‰ÉÑ‡L‡pÎ^ËÕ€–y×FŸœŞëD®©°àÕšŞ.d	Jß0«_Å¿7ÂG?ÈÓ¹^;­Ë—¦‡™¨/-µÚĞÓ0¿C`k:ßñ³@o!èœXcîÕ22:+tSÔÜÒAÜY«Œ&,?¤üV7ÚŒ°‹%cpÌ®ùî‚p¶ìAUºhøˆ7=O«w«mè‚ÁæÊèœ¾)éM¸¾O™¿zâb–õ° ë)ˆ"Ğİi4nÛ¨2lqQ³Ì.õ“‚s,s¥)Àï‹b>Ö(èÉfÁaV“
Ë—½+ûUÇÒNœ¡/‰]­à’ƒ²U DYvu×]Œ‚êÎ¡(ayûîÿÌß¦œ&\ãš
Ú¬®ô!UõøÂ²ÛöÎ>OÁ\w—ˆİRÏLÕæ2|ŸÒuæÀçµ1’ÊÌÉ˜U$ƒ®Å„Ş™ÜÁ-pŠşó€´YY¸'™,‡ËÖ\2 ”Ímz{û’üıçUî&g,˜´Ù%=ŒÎß,¼6+ãŞ…Z©™*–Î¹1*Si—à1®ŠbştŒ)c¸D±©nØ£r#íjOÓ)ªÚtŠ¯»<RçB#d^ğ“[œœü³b$ÿÂşG‡Á’_	{µ.| ÁËYv+¢óİ”nVQ¬	–èc¦ï06Ë”­)¡Ê­™îh{4K	æ°·Y:«U¹Tn÷ë™ª&ÄºTãÃT¼'9c HÙ`>€*€ÛDª”å‘v‚­/0‘1uR~Ú¬1ï>\g‚ä¤MŠù[úÔ¯FO¾ÍUî§†XcxÄMëØÔ›®è†McÛÌ¨wCøò§´şİnû8•6l¬ShÀúeç¿ò‡•´ªÜşM2É(ó'=s`GÃ$ƒSõt8W‹L¨š<0™xÇÃzåU÷8ÇÆrÙŞëàR¬¤•‰jOÃ|çE-eÅyŞf
½¬?l/e´òn¢~»Çb£ÏuQ²îD°3ïmÛMq:ÀD•AIzuÌS{¯˜ôGÆ!Ìiö¡0+<
Çà{e9)ı~ŞÍÿåsä¨¬e¤c»iÓŸ•+±¼ÕŞQèŸÅÀ1³u,Û¼aÇŸ ,‰-r[¤yÚ2n:4NÙÅÒ±ó¤4}ô·àYTŠE	¿Æ
Ë7?áx!c&3§‡¾7*b­Œi…÷›R xŒ‡{ÙØÜ+õÏ¢g”¯!®)šÒ¥>5»–Èû1~HdV®Éeò—aPğC}?èõp-¨‘£yØÁjU°ÒğRº^—š~~¬
¤Ü“‡¼ÅĞm¦ãƒÛ½ıë"_Úéµow‹-¹ºÌÕâÖ£Ö†ÎªR€¿‘ıâ…‰û›VkÖcæsàçÂ„äl•+5Qğ_@èp:Ô%·GYòE¢:NW›‰8¸\·m0O¯C™ò÷É9‹G=Èk@-àT—\ˆ˜n¼2×­©,‹pBJæã€§[Ï°îĞ°s%I6ñü"¿:ó³òİø²RâĞpA¾0y:áç6-—ì°à.£ 6[©²k³bı'd¼óÃÉÕüİ:ºyrwÀ2]
C vŞ—ß.F„¤HW3kœMjs¤G¥‡Ä¶”gĞ¢ gu)Ê×²)hÁé™Mwî@ƒ–Y­«b‡â¸JQ\tqŒ©½I/ß#â7ÑšŞÖM´eŠzgLìônf¹„ŠOAúFIdùØ­¯üo
mŠÜ/G)ú@:1¢ñ^’”ôYï7¢Â‹¦ì%™'ÙÜ%wˆÆ]†¾“lğÕgŸ<9K¨ŒJà‹ÆÙø~»
ÊS©EÓ<¦Ğ©ÕÌN™ìnÓĞ
$ŸùĞ`¸°afQĞr%±¯	´y|fX’zJ­É—ÌÛ$Ù·“¦Ãe¥…ºŞÀQî	·Aî]+LèÑæîÄV]öãGÜì™$ÛµİÚ[Œ\=íí>_”Á LÏGTK³…ÿÃ¿ñ ÀÉ}hÇ¸v`q‚ÀØ/èŞF?TÔ‘ÊªTRxÕW‚ˆÇZV—çÛÑÙê×¡0šTËKÓêÍZÔkúù+'0+O%Ç#êYŸzE¡tRu·ÁdŸ·=Aøá¿æ²:õÃõÉï…f<Z-ŠLD)?,ƒNĞ’ªËÔÄ„fÇ	Š<;;UX¶AÕ[JfjmR!¾Ìäó¾‰?	£É¼g;Œ-oÃt9¤Êcx/;ngëØ}¦Êß.dÍ)‘lµşbülØUŸˆÖË‘ÑÊ]Â—ù	Ùé2ô¿BR¹„ßfœPŸ¦)GUó˜ÙÂ7NÌrĞš–+xz*ËI¦h"BÆ¤9(Î¸öŸşšÿ|Õ$MÂËÇ>¬‡£{Ó½ï@X¨ ¤¼™ßßû#,â·Òó˜äà$Z]kİ}oÇ,ü  fùg§È¼‘ªBgèÔ¢#NízGêOYkâ¦B!«é,û«n*’¾w_wÍbZÁêòwD%jC¶©± ÅW¡ÙMâÖm½Z	YèqD¡½UĞ‚ ­d&všÍ"*Ÿ†OìÃH_Q,ºŠÈÀEs6ƒZ$œÑpÀqÚ¡bˆCaf¿p$Â”3F$7 t3*J†ëEW
÷Vh”eÂq—é:êfÅíÛÅæøñ$ô¸~—¹ ì–ÅyCş†œÌfí­ŸŒ•‹ME()1/®»ø$³?œm÷xò‰ëDjqÀoó‹í7³b•è±È[É–= ÀŠPÆâ7Ô~öùQ‡Õƒj9ˆW™ÛÆPÓvHºş6&(MY	ğõ•EœáAÛÓäU×†S(²%=,8Üé9ƒ*ÏÂ¥õ¼ÑÌHÊ4‡ÿL1Ú¼8ƒ°XiHİlÁGbÔÉ«ŠN¡OA–A¿%Oÿv.,^™Ë,¬70ì~“øxENºåÛ†¢Ûúx=j€g»Ï´«}R5DHÃf£gœ©Çªì÷ìe
#¦¬´W$åå›*ßIÌ€)Dq]Gˆir&[­n; ³™$£X
+K–yõ¯¥˜œˆ\Y~è8K©²²—Ü»ï9ÍWµfQÁ„*K-a@zAAî¦Ü&w*Z`èsx—-QYY1­àÕLí¿é*k›÷RËË–Cçÿsèë7Øku»¤œl|=%ÿ§ĞR)êÌ@ÕÃëS­˜ˆ€¤ÉÄ_Ê
ŒêzÆ¨ëÔ—¬+xä§öşü·o)ÃvàÂµïğmÑ²+-íÙ¦
¨õZç½…YØèl`fvs^ˆhŸWá‘6çÜÄ ”t&Xœ<ôî-q1Sßè.LæÙ”ĞçCÁói"¿+0pîa†.ö8ÂÍ¸*@áiÖ:@[µæ‡ê{•w¿¯bNàÊÃî‹ªQÏ]Í˜#û6ì¿Y¬™ÑeBÛ
qjçÒª§}©I ¨÷ñ³>Ö9ÊÈš÷h®Y­¬–tÒ’#Ã'&–ø‚.™µ;›F¢ï“—Â±‘‰)–«®Ì·¼gWªÁ¹ä?î»FZ‹ŒõhüÂR  >“p±	|êªûğª 9¦¯:èì5kf–vß<¯­’Ü¥Ì ñšb¿¦Ò>‹i¢LğUåRÖûEI“ŸŠe`è¤b°	Àò7U)ŞŒì©ş6ºÅ!5EéûU0ùç»ÑILW²äG«WŸ*½'ò2ªzß¤S©Wİ^júÑZÛúp»!€Í˜DIe6áÏ‹2Y4—°p€á²°ÌÌqPçvR@á´£9\ÌHM¬•i¨A,¯½AyH­-ƒ!Äæ·ô%´ŸOÑnÃv
=õPÄÀkóF‘ìA‚äš{å]wæ¸pùÇ‰Ì©S	¯8¸lb¤õüCl&ù"Mégàöi1H "UÄ„fìüÁkvJlİÜ3mö²ÿPfkbûøøüâ$\®»Ä¼hÎŒh˜`ÊáÑÿ4ĞÛ„ˆ˜Tõ»aëå;TÈÌ•pBhş8Ï}I[çc*p%}‹b †’àosjaÜ4gÊ™Na°P»9I–	}Z†×sY¢•>¸¿„	Å¯
N¡/b;“}ò¿¥"•,}7ª^Ç·T£å`^™Y½X,î_ì¦?ÍùÎÊïÄ'géÀÚÍP®7O¹~½a=$rËK×EOWäí0Î›Cª©Ì¬Oª–åh‹Ò©Ó¬Ò7‡å±H7C”‰jšM»/u[VÙ ƒ*%U­u"ÿåÿe¦}×°ˆ·yaD•‡‹ÅĞ+*J°€ä1L&­¿ä#.{?HÑÀ¶Wá¥=Bš§HxrÛ|<$f
ÿv··•ĞÒ/ğÄ?9»?5,•K»tõlT×ØÍB6>Ñï»‘5N¥ @¨2WTºY0 êX-Øñ.EšÃÀµ5ƒğ­{•.-Q_5P¹uéÏmÇ10È¨³†rïàZâJï9•dUŞÎrÑ¡¹äG-m@¹Øç…S@ÜØ÷¾ò^Òàˆ;Š?ı˜87±*îéN4îß&ozN
¿;N:Î6ê«Ë?œ™âK±à"ıoÒe‡²¬O$<<×{ŸN›2ü.,íĞO”HĞ`!¶ 8U§õ\8Ñ„—ŞÉ{h"f“Mfïs¹Ë¤wS¢cÿ9§ü¯‰gÂo¡6ãX_³Ù¤zÿ„ïæ­&h©µ=³®®’ÕN>ÇmE5oNés3|5ŸŞ¶ë¸›şíBÒÑÒ´I†Gô»hÍ³!óˆ=¼Öqç"†úOûLçÛ<'i1„Ğïi^N‡uş\?»äV¦5cÅ¶auH(wĞW¡<¹^z³Nƒ-’Ïñ§´M?¢*VoSV“D4à
Òº
-HæoDì5Hn÷b+¦.Ëz¡g]…¦Ê`¨:#ùb`#»Ş±fCçB¦îÙ"ãØïx¨LÃ-7Ò’¬‹³¥£–¸Ô)Fù'qÏ®ûx¥H„lP8+‘Ï®ªy– g@ Î¬EY@G8	|¡ñ¶£S/^ÏµâCm~¼l[» `Wï•÷¨ê;Àî¢úÉB><2õ~ÔÂÂJ¼Ùš‘RÍÓ¤TUŞî/®¶uQ ¦ˆ¬3FÄÕ!EŠ¨&‡p‚¹¹pä6‘ğ§?ªvüµ+Šİ´ƒ¦ÕÌˆíÇ­6Ê$ÿ}¹Ö×$­-Ê,·ˆ}ÜÔãíÎöMâÑÌ›¸tÉ%(#ä*¬)î7bc­H<äAí”%M!à/ÌFgÀ±™ê#ÌğhFÑzøÃºîV—÷5†ˆˆ˜`®ÎÚ•Òvè•o<'O|ÅWe¸QwÏHDò•Õ¹¬«Û?MË%YTº±±üPİ\Òi°Är¿€HÀ'à¶Ä»f
ÍòV³4nŸò ³Õm{§ßC˜êW‘å~Û]ÉŒd.øT]ã&šau¾Jf¹€ uSûu¿õ˜ƒV»nMäûZâ¾YO àkû#k~Bôã\·½p°ÔŸÎëeó”÷Q™ï$èµ@ Œ¬£<cõë¯xRÑÄ¢ı‰äDK1#5S§Féÿ‚†Qˆ¼w¦RÔm¤L £e·[˜‰Jıü[¯ VDë¬h}ª´È_-÷qç«W·¾Ã5LÖÄJÃ¨§ºL”J×Ö·„ËĞÎ½âü&Da®µ=øı‡›æu.ÿy´†¼D.}vkğ1„fuŞs(ã\YUY©KuL¡^³…¨c<È#óÉÃ‡µäÄøÜù¶×õÆ*ˆ¾Î SFĞ‹İ¼İ¢äGm¸;¼Ş…Èšé,@È—y=¼X‘q¾(O9Ná}Ş–ë2bŠ¶FàÏ®íàîS|˜æÃP‰‹ø…¼”~ÇDt‹®
Æ@Ãvá•°MÓelg8šÚ§i«Ksë=kyWwĞ—¥ëPDo¾é¿òãÍC_†½„HMpÕµ•ô÷…"â*°°íÉá]—<õ-Û+ß©thD‹•Kd®IBåÈ%“ƒ‹îS'Ôs¨¡R¡y¶ö0‚WLo;bÄ5Ş\ëIuLw&ÈæS_L¿{Ş/òK¥ÉB^ú0MŞôQØ\yÁ½j;¤Êj:¼svl S!j«@àÔ‚ØLË2"ˆù½AĞ¡AqşI~Ø´ŞÅÍâ­kúEŸ$=Öê§@æK´)ºë¨çv8uNàŸàâ—>©´ Ëş‹!ãf¦ÒÅ±hHĞHÎ¯QwŸs:«ïT:üXotÈ9RZŠŒçİîÆ)?å—ùÉ-ı&T¿‘ãbL#&#HcNw€„XP»Aüî?SlÁ”$)ÏñAn÷e»‡Và'ÔNL^.Ø
ô¤‚¢k––äq1Ö°%ËT CŞ—ÂçE>kì&ß…O6c¿1kî­: QSPÄó,2àÁ-Q=3yã¡šìß3Ç.*èŠwöît¢kM ™‰j¤ÏëX7°èûO/à7 ÒSß@tŒ)-ê ºW?,–.yÌşsØÜ	À‘1Óo1@õll	5çŞl:ìiÎ¦>ÔãÑBQÆ-FkI(°î,ƒ |ºà­ã[åq$à˜¬Ú$Òt¿j’§ˆM:4ƒ"ÇªIù¨Q|ºÃ¢CØÉıò¢ğÒö[½ßÎA2)œÇeÂ5_¿è¹ä”$(¸lö·Á%eÁˆè\7LÕ¨.­ğ€óÅ¸JÓ¾æ”emÓÑhà)×`¹hBÚİWœšf‡êû-=NÂB9KğÜòù,r‘‚å™)®Ñ9yÆ´ıÎöv­*ÓlêŸp"NÓÎ†…!‰°ô– òI
öŞÃ$ıÒ²ó©í{bhîº©uºDpyO>Ôb».s³)æc¥’ÓjR+½!’ø:Êµ…”Ïd,·5¦ŞÀ¡ÓX8›˜¦Âu)†«Â¯îøNFÕ!ôŒ<¿¬À[[Ä>¶nk»ç²"6ü’ ]C=Í[`ùÈ)¹ùáoIwË'¨©¿3£yssÌJd‰/ÿSk³ût…Ì(ËŒ©4½Sc°G~|öVQ\ÂO„lu
HöÖ¶™÷>F…³°ˆq÷9ê
´ašx\u¦"âaö+²À‡æuÅŠ¦Ú÷Ÿ7ôFšY¶ª¤ÜÉGâB¥G¦ÿÛe·‡n1Àˆ!&’Dw@İ-ÌX|P4ğêpø_Ó&Fà_{ÏbJ±¿–6OÃÊÊt“øèKfbüHO”¢<E!Áß2íålZ.]¯·R]lµ¯­ÏByÎ^ònÃ‡Ñ1ÒërK„µ©05ŒSg4jï‡E@İ3_W-<ÿğĞ„ıç*h°bàÍj07Õ¥ÎI®·"eóÒF6ñ§énXB¯£ÒIÛeä~‹0
ùıÍi€E¤+_ìyŸˆF:’Uv‡]x¹=
Åœ7ò%$ôC¾!’+ éBr:6Ô4:X	nO$DÍTì†³7â*ß2„ì1ŞâØíïQ"®ÛIå3X»ì‚5ÈÔ`ÿ
nY÷á¼L.‘DĞÅR»PÓ@gû[en®\ˆ¥`"GJ!¥«pv„ÿ¶òmÆÃ9½Ê´jëI:ë‰Šºé—C^·Ş¯íñ,ÚòRJ7»´iø›d´óYñŸ÷ÈtÏOÕoá$ĞLhÅáõÆv‘>ˆ^\ßúÙ"µeA“c×Ö ¦U'©±GY Á®‹XÎ…Sö M‡¼Q+<ÅÔ–©µwo-†¤&9Ûı@µ=ÉG¤Ê`PÄ £wl¾ÄgÎ  „|gı	n¯S[6OQgÙ?cÍd6ìt&Æu‹@›½ÈÓ©8¥/.7×z¤”Ç~!‚~ÕNÛÙVì¦º™nN¨	ÍEŒü‡~ÏÎ|Ó:?–¡_É6l¤eãA©C^€öÔ^ÑW•œ¹ÓôJ4ğ(}dz
8ÿŒÓéü’K#¶ª]o%(›×Õä>Lş¿€Óp¢İ’¤ÿ:ÿŒ?É–CúÉĞÑÆ<¶€Ä}-ñè›-Íz-‰¡Ê¨¨=?öµ	Ie¼®­,—ùsl‘_ïJ‰tr!şµ51âßËÅVj0*Š— älĞØRµ—’
i™úÌ]å…n,LQ­ŸCd-l¤DMkÊ¼Ó!yVü4w+LøWiZÉTAĞ›s0„ttYŠ*q¡`­!ÂIPêéİ0©¬8 ¬s$hh›ìêâp!ÅyEañó`'„‹D¹‹óÚoÛdë&e(=BDg<ªÓwq•^4ÿš@\uZe»-X¨Y„ÜşÕİÙ•S…O²tu2'+Áë7Òé_ş„ÉÚşF—bšR72ğê'k¹o”/´pÑCÅ<.Ğˆhğ¡±£jN‘ä;3GtÇÆ_L!zÒuï°¶‘	j18h¼Yõ°J)»ÀÌñRÁ”[ş7Wó»oÈ]·±Q„œ3Í¡
NÄˆÍ	›Ÿ=!ç«´Ò®D·L¥îÎ€#•b†Uê5gk€^ëà€J~k¤62j–Ù`Í8wR˜ÍÓ°ûSUÚ ØHİûºÓçDs;ızôë ÌCö²eÄ™ôÀ§ãjpá4¬]bèğ\ª'ºé‰TÎ1áËıI_z–99Âİ¡ì\¼Zš›-†Úå‚£ĞP¯(Ú‘AÏozÔõ¾éì7‚çÁkTZÛyFn>èSZoÊsĞ‚ÚJvÌ«IH«.ì½-Æ6.BÃ9˜±^³dªˆ0Üp¿FJ"ÛjyC%Y–ä2Ëu×[jHÔ—+>ÈÃ§Ùü”ì»iUÈù?XSnbóèRX³æ|.–Mıôëé{í\”ùöA{
>8¦ºq¿ùïè
ôŠÿ!â‰Á°÷èÌÌ¡5Ö¦‚k À…[_Lå¢ı÷’Y®I4×è¨3Î`LÀò#8Â,çè*X&´B¦ïüÙRõ&Y´zï=x¢‹±mÉ$:!êşã=+%×öcã(ÕN
J½pC»Yşåu5ğ¦ğÄ§cj“o€z"êdºäæ
¡E;û[)V×t½X%´}î_fómØ
®]i¢S\y6¨ü¾Æ >üû×Ê”…ÔÎá¡RæBÂ€¨k™"ÔŠÖ—"N\ÙægÏì€œšO(bJ!?šñóÑ33îlñê&Í¦ıe,Çu7’#¾lXvå”<ÎH‹í,©¼¶ÏËÇ‰Jº<‘Ò§àßÙ'KPoÒ3.ô"÷ÏGğùF«Á"˜¨áFóåI‰¥÷®\8Ÿ_4àûuµ}Ü‰J§œº!Ÿ¼Ş­Išq7›0»Ègÿ.½äÄA2)è@lÁRc;¶ü1åÎhVñG;Dñ¡Ï­Şí@èşdµõ<ûƒS¹¦Dïs1ÃÄ!d$ĞÖnÃbŸıjåSÏBT¬'¢DíûB¿[ìL7ÕÁÍ¾°Yt?¦ô]Æ,Z1ıÉ¦‰cf±C–ñ›.­Øó“œv±nÖáHøÂuÚ%Q[@ÚÚmĞúÉD+ïLnNÿÈeŸ|6ÁÅM%8ÆüªÇ4
HëuQ
Å/Ö×Q…¾>~òøÇo¹ü‘V«¯×ÕÎ>	™¦ñ1ü“å¢Gaê?­B2Y'ßÛ§¢(‹Îñ'ú4S:‘¢‡<Hßwêo(~”M”O¥IîÅA6B9JØÔö&ë©&Làu-÷Ö™Üî51_Å>·È€É(:j@ˆ<~25à”å.:Ü«É€7[’à®êÇh‰u_2Ú«ñÛÕBÕkxIux;í›ñLı#Å¼â‚x&QÆIõc•œwHLÒB½-å61Æ#!>Ñ%ü^«÷ia	6e?c¹VïÉ>oİXŒ¢«©@”ì˜R–{ô¨:ïÉÉgÛ¤GrâÁ²¦…ú?*Ö‚M¯>ÑôoFÛ¹Á?û{ğ§ÿç,[(>GdO]‡#Å
¦âÌ}Õ5Zˆ
ÀÖn‘²¹²+øb¹s£g¨„#C[MO½±ğ„ş¸ïúY<¶÷|¡¨õKÓçûê¡Õè§Í°)ülæÛD¡µxA˜úaC‡	ÜúùÛSQY1ËS+–ôÖI„şàJ°5:p7Ò7…€¿€wQWuVBçMø¢ÓÖıÒ­DK'°FØaıWº)¶ÚæÄ\~PŞ3êğH~é¾Ôù?§“ÏÒÇñ •i¬lMÎ,İûÒª Bé»A#PÖß‰ïKFnŸhìB>Ù•¬üéÚ#­a3ï:¾ŸÎ„,â½,ÿ‘¶¬KH³Ğ Ëyğ?¨sœã† jÀÁ™¹=O»L±é5Ùn|¡‘VfSÿ
&ÑwÈ-iıŠru@®0ÁtæÂ9A\qê‰Öâñ’D¾ĞÕÂÄ‹RÿE— VBEÔ4Á‚&[t9Œõ­6~é4•³[¥_!±ìµè¤ 5œÔy(ã®ëúÛåûÂ _÷¸ó_ùQHd´éé=ZËh qêï¤OQ§E°+ßºUbìfyşâ”÷ònré¤ ¦9¸¢ÚŸ½';ÜkrCssQÀÂ‘KDKS×«oê†íPi‹¬Z-_ì0r*ûÛáÊ”=ğÏv/‰§á£¾á*uè<IŞ/Ò¼yêÏ²¸öØé á3ëØr[­’×¨•'–­¹ w(.ñ*?aEÄòJze”¿»s½“M‘GÇŒyléüT$÷Mq‡f½Hâ²ŠËkkİ™¿æH !½}ˆ
 \bµ1Vwxvô=zïªIn¼—6vU”º°65.ùzºÂCo¹÷—e\0Ò|”ˆ7½Ù¿ddJô%x]/CÍºI?qUxfY˜ª‹‹‡8£‘ÊÖ³‰,}Á€
l³shFòò½áª.f/dH\=Óg'&énŞÓge\—Ã¡¯bv»€¯e¹É¬ ÿ1ßrÑgT’§Œ<nRmEB±TååÀÉ6
‘*6Ï[#N·Àv­ãf¼ñ– O½«Ff›âÃÇ%”Áb}ä67Fzÿå-	J{[	Š„ì/L‘­ÏX&»î=&Òè@SJë°ÏCwoï†V¤2£Üc”’æâg·'æpKÑésuÿX‰ µÌûLKÈ}}GØìÊwÌX´QÑby‘ÄeŒ¸Ù˜Ó‰<Š„áSbeVåì»º]Ùn¤µ±zÑ}§´Ã¹ò>xD!˜vM{4¼ŞïìBÛì_ÉÈ±|ÉY‡Ş¿ „®ÍXèo¦ˆ6±Ñ“ŞÕµÙYÎ.˜úWs„OÂ]í¿Ûi™1º”8E¼X‚†«-D,ínex5 ©5uKf¼ÏÕ›âÄó	şî&E@¸º>%7p$’wÑïãdõ!ØîÊkÖó™£îÖh*Ó@È¤Óâ>1YXÉô¡?T@—§ˆŸ¾ÓÆÇN¸7óuœ¤ÉÀ`Ê°„¯4DNN0©ªaŒ‡{¤Åã;Høg½õ³ æ¨K&—¢8±ónUvBY?0;ó+Ö¤(dæ­‚=ÑP«r’Lõ${š¹%-ô6­Û1{¡0Äeâ)•:‚[şV	T/„1TV}é˜³N—~¶À©N£‡Ïd®:Póµo|9æâ’(¼
eÈú¾ÆÆsOGh7«Ş›¸¨ÙW Gé…å…ÁaSØ^Ïlkó
QŞÅ•‚j,—Ëşñ
ÅÒú¦lÃ£bö§r¾,ÂÏıC0’<‹;K”šO:uŠŒŸáî}Ìi±gùÖYıæÎğøïæŒ¾—èt=q©V“~³Sô(a÷6¤û±”„åŞ¦fû:ŞÓñ‰İ<¾ødå7ÈúÌPU÷øUz
ªÖäÍwñ@d;ˆôRG¢$,ùÚ¹«ò×!à.|ë„ˆû1ä»u¿¢PÕıè$›w{0Ñà<•IŞïì'nÜd™dÎº*İYÑ¸ ˆ¨“àäl¾.Xù×wU‰sÚuRIÉn‡µıµU<àîÑFFlóŞîRiz;	ÆEïN•`^EÖ1®ã2éTXDiÃÖ>w‡û¶é"
>¼TéËO«:ÕxJ§¦ôó4Wµøx¾<6!–9¬áÁÏÆ_íN½Ü„UŠl×‡É¸¬!§fCÒ?k—"uÏ†ëÎ>s¿Gk·=‹ùHà“sÙ‹íí=-aJJu«·ŸÈÜóMŞ¢5Ä+ÚX€ÀÔ.“‡—>øÃÄå¹¤MåDï8óûÑ‹·ùXŒßÎÃõKöö*âó±şZ¨¸ò!Ãì!ıT“tÚ†¶ÙŒîìˆº†EF×§¯Ücg==,ijú¯……¬¸¡&»Ôÿ¦9?@ûë¦ÿhR”†Ø¹&ÂÎ³?O‡÷%›æzÂõSsëï%‰j;<¹43Hg +ı®O€°±_ëú"âx 5Ç)ä½EX‘±È¾³‹¸€ÈwåæÆÇê°¤‰Vy„Š> @,[¬Ê{Q"9xÌ[ï¢½X?“Æñ1zÖ%zMu1¬Ã[>¡éG±mEŒã]m­•ñ¢q‹+øP€·(^]İ²ô¶IĞ
w“Âšlåç_ïÚ¦A†ıÈvª[¹0††XäD-û „aêfSıé*–+ßb&¬¾I„ğX>×5N‰»Í`cQ Ãâ®¥Pú$_àû½öelŠ¡Àì¶Ê¬M{q°`<tƒy
£iºÒ|\‘ÜÍâW¿ ã$ p% $ï0æºèÔe’	50ó6â~÷Á¡…\{Š<úÀœˆwâƒCê÷½°Â¤¯°M÷æu×$*‚êÒ¹ šü £ÍFØ^n¡Öst‹‚Æ4Ei›0Ñi?úD`¿+•£AZué$£yÛÉÜ·ßa,v”ñÕî÷tÒ@Gˆù-ÿÌ€LH[…zÁCßyRtÏ2æ)Ho]I„c‰vD<ñ`“,ö'¢j²ªi
nQŸÁ‹{Â‚§¨À¸¶w<ŒûìÜ­‚ëä¬ ˆ
¯™ıG6Ç–zaa.uÒ-+]Ôõïïì„óG óúNUmÂ­Î°$ÿÂ ®R'q'+¼›TeÊò_¼)\IyŒ»ò‰ç›ğ8ƒ="¿v£‚·OâzIÀ<îê,È)R=ğííöPß m¢ÂDºN‡ ü—‘•vcj¢ü÷¥‘$8ŞHƒDÂ¯&u[wW˜aÓvù±Ş&•ë&]¶*¦M’Ø£h2¹9e¡6A¨ÇgÕİ®W{Í
TqvÃl®¯;°5«kIQL§šŞîjî3'P`xÊ—Ö—U²é ï)ÒJÌ®ïæ°@|éÌx;ä~wj0‡½$†ğod5÷W,¬,p—Eğ!D_ö˜Dá¡‚Ø…ÑÖöFc¿¥Üf!”Çl”ıa[¨¼
ëOúHëÈSA©9b«Ş?¶7¡»¯¾^©zHT±ôdj3Ö]}Å¡	¸ComDıd"ú,‡’'²ö*ëÌŞéò3~qÃĞ	Åj¼":Ah>ÄÊwŸï›‘@Ç#o6m|œƒËÉÓ^FJÑ1àZ½nFŠ]#›^Õá–‚t5£¥ïğ\B}¯nÂ¶Í*=5ÊYŠãæ²÷cİgR±êá§`¯[[O}ğ•¥É@ÑK¥ŸÔtj#NXÄÌ§Özn¢…óµ½Õ>
C3º8jÓƒ.h„JÇµ‡ĞÉ×ê±¿×n=¡	0«ƒ³#"!îºs&D1û•;³ª\=™YçŒZ‹°|ÕşDøJu9r7›×û?cæŒ­k¢»q÷	¹æ-ìËHój>ğÖY³ğ]âúa	ñ/LãfO²¢z uÏ¶ZŠy[Ê™é¥1
Œ‰ûÉ2Ì1uêƒĞÔŞìÁ3Ê™¼Dš”Ó‚;ª¤_ÅÆˆ¤Ò7`AÖœ¾íı—9Ş faå—±SjOÒôÄßŸà¢5ÅÄ4„(¢Éê¿Ø	§~|‹“%“É÷¬	<¶÷s‡é^Û2lJŠ†¥ÓI)"²º§‰“©¹ãİa/³§°¨€	`4H!‘Ä„F¦¥Ñ¨åê¹ 0ıÀ' ¯J#ÚúZàs0l½ĞEÁUšÆşşêÂ^gZLÔïĞcœ^/Bìd¢E"F\°…í›*/Á`Bxü;X‚r´ZfÀÙ9¦÷§£‰R–k€õ4‚}s{W’ÖûáÄà5`»nj[•]/ÄÜDMû	Éá…]\f³Ô ïê†jCÌ|ë±3,qÍA@Ÿ¨ÕY’CØOÊ¸¬K[£t¬[QwaQÿ×‚¾-Ò”yV–}¯¦¤ßÇÅ8TW[ûë ıe ˜3pn[Œ–wÒı N}ı‚lûtÃ„¨e˜”¸ƒ@DĞ.ÙÅÒÓ-§²Ó'+,@l>i)Î/î_Ï—‡ô¸£È£<L«ÃŞ8 97óMñ¾`(E‰aWğÑ§W½ıt¾Êİ–1İÕñiì¿®$’«»Õîn–a\kf±ÌãÉx·†cı*0oC[x^üÕŞ_@d0Ÿ-A«ÕÀ?lˆöí‡‚o*½§á7$f°›x[ÊÏÌÛ—›ª6œª@DÉÄú\<•LıEğ‡Ÿ*Èlw‹j[Éç©½§¶\qåÉ}}ç"N\©#Ëœ<~£^÷,íÄ÷"`»4®jC’‰Á§.é}%M:8v¡Ù‹ªÄHSêGÛö	˜$£wgx:>yEŞx· E[ùæÿíÕ¢\µ;#Ûr×Ç¬Ô¿ÂVáø&ÂI	xòkáÃxÂÙfás‰„š×ĞÓÔE)eŒ—:øybÅ® 0¢*¿“£´@ê{ü‘Ğmi¯Ğ´õØSKòÄÙî’ùœÀ‡{c^WÕ$V –g4ñä)å™0HßxSEÌ¯³a •Fsv/hÅ-”;{z*;rOò4#R;Í}-»Êñı#Wö—‹Ø ¾ëÊc zµmƒ-8<”­¬7!#ïŠ1r2·ÌÃãrÊÎáYÕß`¯¾!1Î!/ -á²î’~œ‚†ú·ÜÙPj¤oe$OrÁ$.q‚’~é·J ª¾²À†zÓTA^î—xÀW‚Ãõé~ö®xÀD…o’Œ7Ôãâw ai‹6«DLÓÂï’dVvõürä‚3àïıíÕÈ«"-*áÕ+´f¸_Ü^Jò€û’ÔKÊ‰0k?ËY
òÚ)¢Ñ_Ü#gz§ÁEÌÜ ‘ôË+Œn
6§fU»òJQáH¬óch7a?Š'¦ë3¹;Âã¡iáŒôfÏîLìãÁÜ]ç62¾B;“ÌÕæŞm¿µåëU,&†ŞP˜O8‹èE²c®²N´dù´›B8F†ÊD
²Œ3”B£{˜DÄÿv
?ÍúDo€ªxâlCL"²)G˜.ºE®Kšã¦|
µ>ˆ°¨yúÎ.j^\ Vö¿HCÆş½†Ÿ^ê	v‹o6‰9~ØòO#7“¢‹›Èfí[ZÉÆ©ÚDÜ×Æ¦kÀ{G­ ?N"İ)	?µæÑby³A¿uäƒ/.êÙJÜ^„k BˆĞ»¨Ü4@éÆìÉ0ùªGàPì¤3ÜOI£ƒá˜Z§êÌÆ­ŠœÑÓ™zÄ'½E/9§ `xâ6NÏoøìhv-(r1º¤PwS0°ÆÀ<ÿ¡2ÊÄeÑCŸN…A%ï<;ƒCs‹€¤Ç¨”!n%^ìŞ—~ó³/&Dº¹Ë”ŠÀn0—ú,¿p
µ—<à	ª#Ñê˜~úê›Ã¶[,ÔUÈ¾Òûo*Z	îş{¯P&Ìh¥V)[Ã±Ü°(ÿò¸öÊj«6P±AüL …^úGm9¸–#[¡Å;œ:+‡#âĞ+âd)<–D3Ñkª”´çKB—¥‹ı©’ı`ùeWT“ §?'Ÿ	|vj¨ê«¨n©”Q ÁÍ‰Ìâ1Ü¥et@Û£2.Ü€$•†ù¯¤ ŸôøÖàQ>ÒûönšîÌ1J·‹šêÚWH}$­ïí©ÍõÄ~ˆœè›¶¤H°?b¾u;¦äÿ–']ƒÒNâ£Î``î¯ä:)ÕïcF¯ƒsY²©ûëÆ:S£ÙñÚHˆUæ^¾gŒ?ÎË?˜ÈöÌŒúÇjò¸"Å¸LE^¡º4$¶³®o$Y/VEnÅ¦0#¬Şÿë¸!°z:È”©¬B…3"¡ê—$B÷Šm´ş[™èÅ]»öä*‘G}Ş]†¶è%#FáÃc0îF“^æŞ®³”f%ZO+zÿ'Ş?<Ù¬ËwZ çb¡0@¿4ÁQç•ó5Ç ó{^®£¯ö'‚K±€pì#¬‰ …İBZ[FéØ¥ÒÊ¢éG"XÏd&üš÷x_¸D=t£ı,_Íî’¿\¹ñÖÉaO_sTaÇªÏ,pˆÒ“³õJÁJ	=šçŞÔ4¾±|¤R÷ÒlOµ™ãï"îSË4Rëï!CYõëèZm.Ò¿zÜ&"£îNZ+j>%
˜NñTä«$’ïÜÛärğÙkOI±gSóİ¬$_æá{`©v3º&œ³•¡–ëÉÁk
§É(g†›&¡½¥”Ágéá}ŠNÇµòşo0æIŸ^Í°‰İÆhªÉAD»ÁšnœUê ÷*+¸x|s-ØÚ›];‘d“À!\ªÁº0<ºm–fSRäÏ\+Şs¿§®ªmÀØ/,?f#±û;6¹&§ÇîøÎÚûf–æ‹aÌxĞĞG‘ó¹“’ÉbĞMu[Kf–oxˆ^mèó·÷ÑÈım,a§sştCP½löÍ4÷ X­iŞŠ¹][„dH•ÜI‡åšøî	‰öFÏ>a¥-d+V{^9*N)¥šmt‡e³­èqiP»äK{‹¶ï Ğíœ,ñ°CŠ¨¥%‡aQr1b!¨K‡‡’–ïòWoì«¢!VJm+»h˜›tf\«Àô^*.«‚bªoÖÔÚT{*­â©¿Ç·ô•D&È|Ï8Éâ0âiŒó¾ãõ ÜÂˆ.m£ÚƒíÖ!§0cPÇĞ£¶;q*ÖŸåùóF<ôtÏ–SWıjâWJ‡{Uy;a/'ZÕ/Âûù§ú];Rq8?cBºkVq!4‰0AÙ¹…4Oì›4ôôÅ4i¹SENãKÈôû¹†0ÿ,sˆ¨%é´VºÚÇ«5>üÛ)¡ûç„ĞdÓG{}şµß!íag»mà>5³€‡Ú#…Tƒ€÷.(ıƒ@…øšßŞğê ‡ª4írD®Nõç~}Ó¤ÿğ/Élù`$j‰y'“7ŞnWŞ½¾ûTw[T¦^ÍMT9¥Ï°¢™¡{>ÖÕTrmµáxDûµ|—¿d—	¹ôØ4ÈK}ğ_MÊŒv397]]èmLle'I¹Qş!ìqµ\á/!>qJÄA`~åœ°ÔÅV9%
‚}ö7ŒmºĞIù?‰]Âµ0$;øfêı2(DºC|ÎÓá»Òÿó’Vó}`Ã>y&7óŸÕÌÿàıº¦ÌŠétÆ/rLì<[ûV¨~ñ:içêÒ¿£‰Kì…»ÑJçŸ;bøá—¿ª3#î=ZªÒõ#æ şa,á³°ÓŠê (¯Óeeøã&©;âè_âjXh@±rBRê…BqÇ>Fú6ã¯¬ıÖ2ƒ2</eKwŒ.G÷cE•…‹¹6æZW†àÌõiJEpPõÑ"/üO¡¨ë‘¼)@Ù_¦,ÌÊgãÉºbçÑ-Ó,h3—ÁÖåy•³øÀJÓá’êı¿Æ¿Á¯´=œô(s¯ÌğqQ¡ïÔ»ğŠ4VLòD¸ùÖ?¨oá®Xdè:LÔê8ûÇš‘e6ìu}õ~œ”ĞÛ›/Ãìi=‡˜Œ5Ô6õÕNˆ#¬ªY‹ê3L»GégÇ¿ˆ±(Ø]“NŠı<F<[_€÷Í™Ñİ¤ç§´q(Ÿœ,RªS9'CáK@+Æª àZ¦ 3´PJÔxv‰•ÇMóOH2‰»ÒnÖã|jŒŸ@ˆŒ0ù•›ƒÒUü<çÄ£TğB/S‘4œ®eöâ64Â“¼aR¬[ÇsŞì	$O‘'´İZ
‡óJñ—9®åÒœYh–aÑÓ1gÆ@½`QsI8
äã†Ãë\J	‘~ÖS;«Xë8mª¥‹3«'ól?ãß¢‰R€P¡ÒQS¡Ñ–”wŒrHaˆåú?çzNóİ7‘ÙÎ%ÀÃk¯s‰GÍ3 Z`fl~™6U1©2aëqwÕPG%™PÎ¯^äx¾°<UòßŞ&Ñ?”/ãP5vİ®]—úºFPù
Ñ¢£Ïj 4U–™1äE$¸¸1Cº»Œ2J"'‚¦vò˜rÄ)½İÊ¯˜}Ä,5nÇYq`r>†j/ñî0Ú‹Ë–ŸğÍşú İSİI^b`èRYiàaïTØÆ[ñ[Öv•¤BdÓ¯mİ¸X~ÇP7frúeŒßÜa~ÿVöˆrjãM0³àôÚbİ	fqLâaOo§k,åí¤ú©†€^E¦‚U~a¸+6Ø½/Ác;HºMñ3Ø™QZƒ1=µÙ)'‚ä;òR6ŒAï-—JÏ';hÕJacƒJœì¨=59üğ¼79¿´^I{ÊÎW8ò+Şgñºw—î*­B¢Â:¾æÀxÜ§=3rìqÇµlU·û¯ƒÅ’Á7råêIW£Ğ[P§8”–V8Y÷å&Œ‰›N¶ì/»‰R„W†zsæ4¨Ğ95’¶k‚ªğİ1½ÙÎS ‰¾N±àPÓxƒ ôøÏ&.Jßj3ÍÍ:ƒMÓÎ¾$ŒhÊlØ€Ya-‘„LıÕ¿æeL Ó(öI%”Òx@Å[Æ—%Üæ¹Ú/l|f³a¼ºZÎ(4›p‹qÁ3ÀÚ±±²÷M‰ıïC4€9	XÿiêòNaÁªX1áx%hoûšgÜëÎ,Ó)¹°ëE©‘,áBàm%°³Ç¼¹ùEí‹’
TÉdtØBzÊñT z'è´+2š£Ñ‹ÍÒ{ùqÃ{¿…ùÎì£ñ£	‘Û†—J1ºÈœñ_c[zŠL²T¥\ÜÖ¶©Nªûo×¤¿í`—å×óxX®Î •Vfí(nƒo±k—üsYŒí'â÷Êõ®4Ø}Úh‡Ü);¤uÊ­ä@ŞWÙ>üNe1“ÙDb*ÃûÎ¾ÿó[›â…=¹,Wª§§q¯äUIs6z6 a³}VŞ¿S¼F>ÈÈÆ%bø—AVíZÜÊgû3C½ÚŠÊ(;m!8Tá!c›Cÿ¶±ÍsònÜ ¤?óYÆz+³L¬JH¨ã€Ò4àFÛ,<Ç¦AEÇq!†ˆÎˆõ”no$qi“¯•¦!´¨Ûš2©—nÚÖªìÆ ²	
c©¾˜ÚÄº4©2Ú6¿ä¡qß1h‚o/‚ê­hOÃ
o‡«Ñ’<¾b@¬p›B­Ï§ä	çF¿5ûDĞOg»yBQ •Àºo«F	Í.M¸JVÉ9X}{&º1CãoKòG­ñØ¾ùX—éŠª·ôÇOØ–ŠçÒwêÀ¼¨y«b]oCö—›V­Ä¼?í×¨¹¡²Å çDyø”£áÄ'rêeâ%oèÍ¨a‚BlÂoáìÒÅ½\û¨O"¢”Îâ‘C@'…Bcõ:›dêpñòEŒxµHsÒA½
w\¢z‘õE$6ƒW“ğB#<éÌ7Ó×,q§Úßÿ$z|pVQÖ¼ç[/ÀNYÅÏ½aºŠ‰ÑeBåW§Ï£Š].1©#ówzY`îÀóÏÆI¿ØWµW§‚†—@pô-á<{œÙÏ‘ÖĞk/ôşê-‘OÅ!5FÉîş±?¿}§Ùi`Æt|Ñ©LBÄ¬aåĞã
Ÿ		•Ø<‡B¼n|­²êéFËÒÃ]w$£Gm²êZJœ»Vèzøv{´İbûï¡ÁPq4dReU;·+l·õ:”}R–ƒQK.êÈá$g¯l˜ÉLj¢(¤[Ø3
Åk *$­5e ­€†WX‘>şrÍ—DrÓ&è]! EİòÀ½)±î4âcÖaIn}9Ü2íXääÀô¬y~^0©ÜNLHñCğB›äy~–…|OïŒ}C×mÕØG0@<ÔÄrÓ"®³AH’ûªÎWÆ‡2àºy=®˜°&Y¯Bà	˜Êtà2*{ËÀÛ"”KñeÊÁÃš£ÔÍß5"J	N91À
jÿ"â°3$×°P¼Uv†‡R‰ü˜h‹«øÜıÑöş'•ÿ½6¤G‚8Âİ“%ß,Î…wŞTò¥L$Ğù!Ş| b¾Ã.| †‹ãkVô›¾øõrNGé²Ûât„=¹³Bµ½~Éñ‚a*—vŞxô|`¼S¤Nj÷'|¡rhv+s7ÖñßíH¦ÿDVô–¬vö†
Å2g0™ü$üEäÃšÉ¯¤F9ñ›¥smÆÕÍ0´`
¦{
yÅœ,×Ø«neÁIvÄ@} Ëh5¤í®o6"˜øæ¿ÆÁU‰ö’Ymšö”ñ™!]›/šY÷ ØâÃÍ)5 ÆSFgİÁ§¹ñûÙ:aSïå€ànòZ•¥"İ4@ºµn+æDò¹N,kçÙ¼½®²4L\³ybş\ºÒœZ2Ê]^œº¾8Ê˜E¤îí£Ó,„õ–ïõIYƒßğ®·}Rÿ´L¢&EÍŒáôCÔ›Ï]Ò‰Š<¿1’-iŒŠ¦a6°X‹V¢oµên¼Iæ˜RmüR4v…üàrQ­ö>í8o}+Rn}&î¾ã¨¦Œ—XšÒÊä’/$Ûo„$æ=qM@?(r(ì/“ãç ¼”ÚŒ¿[’ôÊ“˜§ÿ±ûl¦TÉq ?ÊdxÿrFİE
…ƒİ».vĞşuàBzù+®$êtKi”•±Oë’6c¢âañŒ½´ÆÁôwÛÀ`?Ï‡Ê¬pÜS«y‚äıòÆ\Æ\¥ÿQÎÌ(j* cv‘é³>çIg“-…Pãß|ÏòĞ‡S#Ëß“%ë!xf×x[»L,Sœ£“ü—…µ¥×àjKÅõ\FËÁrOIÊ»ä²:÷ışJ³Ü?ôH·eÁÔè*m>İ;ÖJ:/£Ì@Sñ9V Ó:$9F• ã)z:Qunè,Au¹Q¤Ø'LÃ¿Ó†¾.‹ø5½×DŞAêF[1r¦$ØCd,›Rp“üxT!Ğ…g- LR1fÒÑ×ÆO¬ÆÍ	Pİ[jR·b¢ TØ‡{Q#mY¥ËI¥ôp.kşÅ‰¢Œm±¯l¥ïy}õ.ˆlK)pìrKµİÎ	j“bßº(˜3èŒø55Sg€/ŞÑæGÑgC6nıw—ì¬á!ñ¬luC‘mSˆ£k“µâ¬¸†ÉûØ„scËlq}$[~%g–Ã–*æ²)—~Q×#D%ƒ‹DÀ0¹µô»ÍhàäóCÀì1ç½tNv‰ÒƒÔ2;uİ)	È§†ŸSS[·öéŞuzØôª?ÁV<íş“Y°%ó¾Ò^øm§¶å*ïá}²EXË ER
V^OIññAô½¹XàbÕ\	ğQÜö«mz›“H\O°TŸ=4ëME·Ó7$äÜõú'íJÜÿnVÍn@•Ëú à>ºß!½Äzk‘Í<´,ĞK—~–<=`4¿‚¥”A[Ğ°ÊÁÑıPª:«
…RYæô+‘u†¡Ca¸â%™vAŞ°‹Õâ_ò½¶2¯™Hœşéà¬lİºƒsønÁ^á°PÙ«å×¨9“şNuá·Lˆj:Ö°ıÆnü mQGA&Éáé´Õ§4«Plgíê*÷i¿7#e˜k!¹»®ĞéÔÔB,oµîB‚f#Tíâ—y6Æ[YÕG(ßêhgÜr+DQßÉVÌ=&‘qâ™C…üí—×U³Ç» –Ó—ÅHö)ŸâQæ¦ƒğßz«!KqZÅóƒäsãJk¥Å;Xš0©›f°»GqºCQù(‡ˆza–¿„‹êxÛ›\ïQ°úÃ®<¯ÇÏ>Ç‚sÔD;dĞP¡—Ò÷–˜°k²µ77'WÅ›ğ¨ÈXÊ˜bÂñ€ßöµWÿĞc™0ñ@8FÖ2»~l›2*fw9Ï°D>»Äiğ†½D2‡¤êı‘TÖ3C=S,ï1ú–”ªÅ¼¡>¹sÚ|øá°¨± »ú<iW Wò†¥Q£åò½Àt‰\}¡fX0ğ€6óšºfŠY.ëè¿”nÀ…0gßÍ„,âÎ¢à6Á'(ôËDaË«–“™Âû…¿'bñ÷æM¯1Î^Ü›ÊÃÔnx³ş—Œ.|ÚÒ)ŸKıƒe»»,D¥%Ñ!NMg™m·‰¦ı]„D‘É¸A`ŸĞfú8b¿¶Ú8q(WKi$ùÓµ:›×Ëæ¸ÜˆÖ+x!6Åš¶Û²wº0‚‹3‡Pç±zùÖAD½ÎZsèÖ®„OŒ_ù=´ñ$4–KŒéî\¨älö»ü“Rê^Í”.6ß	/Üô¸Ô¨·?bù=­İß=ßØš›Ğ\ĞÊñÜõ6<»ĞLØvõÃQ“qÔ1‘ô åV	½ÿı¾ª{îšÿË!¶’³îníï1pçÛ!’Dœ|RªÉ³ŸÿA:Î{µ\4p¾;UFôÂ™}˜BUêâEµQÿ”ãW…2Î>–jè·²_²Óø•»ÖÅJÇ}Ûñêÿ,jO8EájJ;C¦£|¢pĞDvÀÙUqÚr¤‹±S·û*fÅ½‡(ôŞå7"»(°ÄĞB˜%bLuº‡ëç¦…¯ªÊ8	ô_CdYÅcl`FNÌ¤ñ¢HúUaGíc8¢”Áí_K¬ `(òçîó>_ãÑÈi‘¿fö´,ô>.~Âíx¥O
!ù	|T9™>ù*W‘e =Í£]å[Š$M»ÁÈc-]c ×ÜÁß)Nå†ª[©ûİ=»ÃØ]hÉ0¥1_½;‰S„¬é/ïQYN4ßTÁ²±|4v´y;|õİ2è$åo(ıTBæ£%Û{Íğ8å§b³Ïa	X ö¶ò5]Ô»iÑŞqŞ˜v–´íùÃĞ/´?ĞT¡1bÌTÍÿªi©ÿ21ö ùİSCäşš-äui¤VpØøpG=«^r™×Î{`ëó›+÷áùÊò³eì¦‹™Ú£]†\	^-$Û¹ôÁÕ~?ŒU=´}
^ÔÄ8DdCíNz‚8>(äº×ä,XÖZ:wjù›äMí¶uµ(^µÒé”ö+¬»¯	~c¦»m~,aôTøÑ@Qo)£KÒˆ½E%C|ŸEíË3ijiøÛ,Î=|sÌ‘!¹ãÕÁˆÂyÌ&ÓiaÍ·ø‹DhU°K±Ó;ĞÊíb‘˜B&©—ß	°†ò<ºÏ‚åîäI7'=¨¤Îù·ÑDx	İLÎiYŞW°]Xù…Ÿ’²¯¼ğtb]läùìÑn€Ø¹AtmïV1í*ŠßõĞ«DÌÈ±ûÆ•“€¸ïZ‘ñ\9&2ÉÄ’6Î“ƒ“÷Ósã}ÙH´ó÷kûÿcC±Î q©“îÀv¾”°ìPÌëİØÈ’ğ2ß­™­°Ä?ÍÀ!íCA'§©>»˜^3Z†6äÀKJ\I"¥%ü;¹¨D,ü{|ód†­ôÍ{KN‰ š95Á8`\´Ò–}á³W$z,ÆPôDÖñjÖ?3fs‰ŠÖOk}CÃØµœ6~g«pC‰"ñ„YL2‘1ôƒ_òÀ<e‹5»wU³NÄCƒŠœøÿÃ|c2É39³HS%]Më6¾Œ“fOmq7“¹Ëbhä{½S˜Ue/š§0ˆ™{ÂSŸÄÙ,B_ÊFÖªI!'Ó3åEZôÛì§ñœB<ûçK ï>ÿûãv–•Â	FÁÿ5\,qŞ½œĞ@“tòOµ~B’xsX_Îw)oÚMqÈûè”¦”ÿC{E—úİ«p¹4¿Å	ãT%°Wg¦¼È% ZZ-ˆù+M²d‹ø3ßMtYoUEÚ]6›Ãƒ¢ƒ,ÑÕ›€Å¥p‡Õ›ıwè~£—HÌ“/—ş‡Ç÷EyV6Q{à…x±{Ğ|¯+Ş°†rˆ ­£H6€Óo–Õ†áä{wƒré¿E;Õˆ/@şƒáŒî¶ˆƒ›œ×Ò÷KöƒèD÷g‹HÂs\i„­¤Ã,aÏ-£ƒÉ²]-:n½Y•®NÜöèáÿ$….JŞèüï¥Ş+;ŞNÒT&}ò"cÜ?-áß«$œßˆ4¼ »üõå¬‘ˆ†Ïw@Ú‡\©—Ú ¦L¡˜Î”K¡?ù­Ó˜aµLe¦-Â*ğbk@E¤4ş¯ƒsfY¶;0«=Q)B ÅW'l[bş¹+‚VfšL ±xŞ´??)›Ì(i§:‰6Là†S•ÔÓb“%§ĞPlb²›1Ô µ§O`F0h=ğ‹òOæÃ¢'YüâY¯êô‰D	€¿0›ƒc¦ô‰:}°ØOŸğJd>©kÕ°cÀ·°)½ù–§0U|:Ô‰ÌŒJ“Åşø¤Ø€U/õsëâ’Q*?c{ba^T¾Ù©{¦4¹k†Ë”ÿ›Äö˜¢¹O ynmH•ä¿Xù9£2E3H:ªÂğTsşWõ}éï‚^ÌÑ<„·¬Ô $ô	ïiáVßÄAàŠVê:¿ë'R­Ç+>y#lÇ„áØ‚íõé®¢h N›béPƒÈìÒÓ+‰æ d!îúïÕ›F˜G–”Ùø*ÒWâO½OV¦!;¶¿<¸ß ­©FúQUP“û9}R¨$²©Y!ÖGu*à"h[âïÚ¾b¡¨9ô	ªnÆşëæ¼z.yqâ‹ÌÍ´¡ø:lc
8ğ‡Ñ¨Hİ,Óš¤L½$´,ä¤4m?¸5½+n™„¸wí‚JE%»ß»œ¯šà)ÒöG5å˜sàoÔ+Me¯(oHåîñê?§jç|€êÅÉPÛ×ò%p=y»ÜşíÉèJ0Oı°_ÖÎ­2˜ÚT"Âİ1%]şºàû¤ÇŞåJ¬ó úAÜy—/*†ú™£{–+‚Vi»A2P×˜S”Ã5>€üàí‚‹yGWÇü´Àb†àY¬L±Œ;íÈjYşrœ¥mkù)ïkJŸFC.âwN=O ¯¶Õ˜Ôº£Á¶võL>ÜZÁÇE7ã_
oòr„Ñesê‡;H}™³¾“¾Åó¬·”(‹Ò.çÂ	GÊ¡àS	 z1Bƒ(‚?DØÛÕÌj'%÷u-9”£- IL9æş1ŸÁ^ğLÖHáE-w´ÕĞ(§`­“+µòà¢j	j¬hÉ ÌN.vwüû*¦ 3íÔk¬H4L‡©,Ş?Gmu(Şäâ”6Õšâ/ÍÕ´ğ]{oÜ)<ĞÓØF|Š7\Jœ),nØBkÌü¸¸%NªÚÓW­Í½¸´L¹ä¥!_ -$€ÅëºtxKÿ*ì>–²ÓŞÌæ¿EË+Ò	÷ùØsÚ¦^“G^ƒ»×Ïª†QCÒeN±høâœ6/;cøÏ6»€S2¤éïµüpRz¡@Î™ÇÔ -C€Š$ÿ¶¡q;­[pÄ³ÀY@o.€®-2‹°‰:Xc8«‚#ÏoõÊ~ÿsìAË˜¢}¥kj+ÅlÁEH§DñÙ$ÖĞ¸ËÅÄ…VüeBòsœU>îœ| ‚ \&âV{¼
ZÊ)¹1sÆIëEŸ&v¾[†¢\‘AùğKx£V–Äßœc•–…Õó¢7ÿlRQ¿ Ê%ºÖOiïî´´¥3z Æuo^ä¿oòMZ¤›
Î¹õvİšZèb(3eãMÁZÕ]Œ¢ECÃò1ËÎmEIUº¬Ò¶Õ©gw'a^b–ë­©IH\yyÁİ†•ÕïÜÈæåÚFÖkÛ#ÀooÃ7ş¡:iK¡¨mƒZwk]B1Œıs?ÿ¦	æE@[­Û|ó˜‡¾’=ñìŠ§cpí5Ñ$dı{ìÔ¿¬¶^°×dº!.ñq{g¨ü×~›m•/š,qÖ=usYäıS†àŸDåLÓšZÇ¤Åâí±E­†     Yò1+Ù /Ã ù·€À v8_±Ägû    YZ