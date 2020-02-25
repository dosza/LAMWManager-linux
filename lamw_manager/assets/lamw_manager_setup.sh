#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2108756504"
MD5="f0fd022a84dadab42aba13e50b91c3d5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20412"
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
	echo Date of packaging: Tue Feb 25 00:55:35 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿO{] ¼}•ÀJFœÄÿ.»á_j¨Ù`*Ššáj‹B2h›“ú<•½¿Êös%÷½†™£ŸÄ£”:öÓ
¦*9T;­%ÿ-€Ù³¸u·áè7û&Iû®šk‘9²õ§ÂJ´ÕqÙ–Ö=»A‡±ÆZ¥œ!½û¼6"6Â4\€9+ì‰TRPî	ˆ|Ü"äü xÈïCé÷”o™•:Á"É¬C»Ù SqsH	#–%|‚§kE}º)¡rª)&|X¶o]xC
ª·Ñ©‹ê—=…¥~z3Â[IÆF%®5-håå£‚¹óãÍÇh†›ÏGËÍŸ¯¿Â~@]hÁºEÙ ¾çôa¿×
j4æ„Kİ&ïı$w›„D$Êv+L+h_wô
ù9ÛST×„”ÛúÁ'ÜRE5¢c_‘5fzĞ}•Õ\Oğİ&ÄÀı9§4³[cÿm´“92;ûeŞ™&xy)ÃØúHÍxKNö˜¿‹öÆ¡J{æ¯¼—õt"éåÖ®ánÇÃÑ·ÅDª•„+ğ6€\»ïß¯Ãå bmLŠtx›ÀÕJ‹|wÜ/„ä27ÄäÂ”Vˆ¾Íq‚İ37Å\X_´ÍûjeÔÕ}4ÅV{Á\ï¦+32VÆ­i0Ùêúça»©o´ãh@U#üîşô_“RvüéØØ*w·.¶g8¸åÔs6ÿ²3D>üEßİH
t—{†Š¼(¹ÙH8Å¢	h µ•å“úÏ˜Œ(iºcéêGÀÁçÚÇb[Åí¹Y"*¦ß«VÅÿÁb=Äô<üÍs*"L‚¥äŸ½{Ó­ÊçÔ”8òusuw†ëÌ6¬å]ŸšävS„	Î&ÇG õÿÚw,Û Ò‡s[/,QºÈ, îO£ÁX÷Ù:î¶xSmUêW‘B«Ñ3Yx·R,èìï6_ryÚƒBm™ñÃØ^tµ%ÂÌ¡~	‹9,<eª¸È
Y tküÖsÊN±ÏË1-u©µ.K[}İİYÆ5üøü¥§ÆAğ›Kñ¤²y	œÚÖ×Ÿ'´ÿo­œ¿"éŠ˜¾t¡sôº,À#ø”}Ñi O$‘’_0İÏ5²ÏmY¯ü¾œkQQçkÅ›úC,°q$h¨è=±°W:iE0Û˜ÿ™s"ò%-hj}út×ŞĞ`FÅjêTöv¶]yíºü¨&1éœ=‹Ò1C¦±Át=WDÄ…Üh}¬Ø¼:bIM#^¢¼w±§«’ŸÒ*)—‰*[ô"%†X/èĞDdß°ÿUt
“Dö÷m›Kgz°kuKà]N­¢qs÷Şº‡mñ9Û2YÌÛ©şïÂ|HÛƒWz!ÌÊ¬jvÇV›nP¶¼„˜]’œGRıµ{¿¼›Ì±<ğ·wcõ.xÆâ¬¦Ñu#ÓO¹x³möàSÖäÌ]Ê]Øù‰pãé¿@V”/p«Î6(“(ßÃóÃà½ö{§{˜fş£#]Á¶é4H™:DcãÈ§°a¡a7O1Dğ¦‰8à9L±x¤pW§á¥Híaè®¢Ce\¸Z6§)/îŠí¤ÀëÀ\‚¸S?.ê×>O¨ î·ğ¦û+H½x‰X§•Á¶fnmæqé„­.NÄË4"7m‹ò?Ô´Úø\FßJÍ²AE¹õÀÊBzç ß!½kM _^ítâ1ƒ¬FÏ} T·a(Mã}‹fÔ¾;~Úğ_Äç«‚F†¸ÏïcUÎçfÍTjyânÿíƒÂÜA£ğjƒ`c]:„†%€/ÌM\‹E¸ªéÃ@1Ê™$–úÔ©<lqyòğtFÒÿõ“úX{ü‚ùë¶Rhmœšc—¬³ß)T×DwÖ)¹häÜ@ìÃá÷F›Ä¢M­#ÁIò*A¡ÔÖj×H…B¯Ë§VîÆ¯i8—wØğÃí+VNOÿÃQ’ş`™°B)]ƒĞf¬gì›$ y¯E ºªÕFş’Q2`U6Oúh‰Fi/Òcï¸ğ„ŠÀƒ,éBK°å”,Cb_|*öNWê2ù¿w8²İŒ&»˜á÷¬5æpF:éÇåv/ˆâü*€Øõ„uÒ€F¥¤øAkëš}hŠ3ÛËD­æFáb#	ÜÜ´ØM‚™¬sâ/Ø´haÄœxE÷ˆ‡y9o³g#tgÌéè	Iîö’é†„•Z¸}›ß©T%€¬v@Ë™ø$`ud{—Î±îgã·g3±¹8Rz'7'J«`ÛØÌ ôëV9s£P–ç·rÑ5µ }13‘Ò­óPĞùRÚ{|ä2[N¿ôI7Òÿ9^dÜ/ñîÁ&rÌƒ†öó›¤”Ôåò‡@4¢\çÔ÷°Sòó#‡ñòˆ~ t"ê*Ö ĞİSá/Õ"øÌùb€W)XU­I†œeóºV­ÎıÌßÏuotB³Ï¢¹È1³îtóÃ³Ğœ™}çg@^«²«Õœ­‹?4æU@ X­ıÁˆ7’è/VoLeõ %×å!€…«ª©€"ŒOÖÖXo%õ>”\tİ…àY`Q3³=Lâ1ÎòeòÙÆ¿ß‡‹¯ú­Àj„á©œÄ0Øì¶÷…Ş^F(}-\rBz(I¤´‘WNóŠL™Å‚)Ù¹ò‹E€n2}W¶–§&h4•˜œ6›ÏTú¦ñf‚?œÕáä’\%-N›êxôı¨Ò¨23„Ştq·¡d˜_ñtò¯½³ÜÊøxDM ™ªÃ¸ˆ‘»Ï´„œ?õsoÁêáµt\_Fa§87P²
¹ ¾|w_31Kƒ,|ƒâEƒ›{ö›Šd\"0kğ?rf5Ôen›ÈöWôcµC€ bEe‘Š,3‘õ|×r½7Q&!‘aD:yˆítW”YÓÉN00Üõ‰,£€34µtgqİˆn:GBœf‘ùÔÏş?ø!:ä ×ÍØêè€fûp© Ó*V¡¢dœeÿÒ³ïõaÛş^^B—ÂªüÄaFdü’É¿§i¤”¼¨¬Éi#q½QL¦d4ÂÑı•¤«›"-?bÌmƒT¡yÃğ‚™"ÈûÜï]óˆ¦¤ÀXe8I† áN ~n{¦Oæ;¯ƒ¿"¶şÿ‡î{¼	Øúa6	kß±­Ò7‹`-ä›•±š­WD'Tl„ØŸ·F«9m[ß~5Ò«ö§'³Qz±£tš ‡éF6ŠsxßÇÏûV•m_‹”¾ô>›ÈÒbô`Ò/ÿ’¯×n§ş²Åo‰–,8WcÜàc¯QÑ¯¥¥œJåÊ¸Ré“  wŸœŞF­6¦	¢hâH–§9İP.ß$£Ã›;ÿñ]/)‘Éß†.5ÚVü¾UBÜå6íßd±7l°Ÿ’jËnkdÃé(]X‘àœ§å·ne­ÎMCò€S}ùÆ-:æÏœhcõâ…œ“<EQ8gpš(ßGÃ66òaL?³qD,¿Ğz7…®•¿®ñn¸¡È’3­W>Á»Z¢t¤›šà·&Ÿ‚4”€=é†ãZˆı/Ø#pÙ×ïd¢BğÜXŠ·€4f]…wWÚDÓÓU
§™’TJ±ÛÀÍ ºı2©$:w†ãD	ÄÊˆõpkwcDMhx¿weî {M¥Ş*qãAFJ¤")	ø@£^Ğá‘Ê1Òänü‡Eù7ÂlR“ÙµƒtÖˆ¹âíñ‚•J5ïL
]ìeQµ‹KiÜ?<dañM!¥É[ûûêF÷z§x†À¢ÖhgÅacÌQµ£W}=Íñ×Pw Ğ[k‘=ŠÄÍèÈ%`mYâAìO(\C¯Á7o§wÖ>Ü I"9dv*.À¨ôs«±Ïív9ß-E@ÜÚ¿ŒgÇù
ôÄÉÖİ±:\w0=Y›ùÕ}aİ?¸^éf.ÿÕ¿§Ó¦J(|˜Ó¿”“¶Xc“UãfF¨vZSYpÔ‡{…,½iğï
ó5eƒ]!Ñ¸ÕÇ²äó¶:&S‰üAÛnš¼d§Ir2n›“÷ŒD98ÙoAù3Ã°†Xa'/Íudã‹hK€¯°åÈƒ²Z{g™×YàEwˆ¥ÿ¨Û"MÏf'&äÑ3MVáªuıT8àaJ¼œƒ£°çR¢boÉ¼‰™å+Ğëó#>',ÄF<<æ*¾ şĞõµÈ¨×äõcšØM<†)il0NÀ¼í?åŒ›î¡¸7+‡TK:×L;­{³q#ûjŠÂ47(ŒoqQÙ‚šÃ7ñb‹CkXùN3¼Ã’•ëÏ@—èäË$m˜•(~«<U%Ä®ò„‘?©«PîÃ›)wp´b˜˜ıªŞeq²ätÅoÌä*¿R²ŞÍ(ÆÖŒd<ä‚	©Ú¸»(MuR/;ˆ‚ó1ğ¸0×ĞÏŞ&‘Æ[3ÇIÇHÓ÷îÜºò–£j´_‹Ks½¼BV+¦ÿÏ€–í|Æo
£‘CËz£¬ÆºŸ½ùó 8]…h8ÿ'p*ö5™	…“_>RÉ”Š”óMxHÁDÂÈ<oÊRD¸zğë ó4Œwúø¬=¢İ6‘‰sAOEÃqın	aíâÕ€¤Šîl±ıBy_¡và I~Î:â]w{’èH@WuQ#ø¿H7=ëÿ’/ï´#ÿ1Ñ€íT¢Hi•wœå¼¦dì#Œù!ŠğSÃJcÑˆïHë¹‡–„ñÂ3;IÆTPÎ¹Œ€~–K×%Ö­øádj›ñÆ!¹Äz˜Hi5ä—ÇÂ A‡vâ‡Š 6ğ3À:Xšèôì<„Ú6¨ËºRıZ5d3ÿ|/ä¶q!ˆ€š¥¬|I3amŠ9ı¤c cë3¤-V¼Şãâ^¸q-árU¦KH?Lf“aWkcğ>wCóÒ—y7<D!š–Ù‡:
+'%:3€u^ı%_w'·tnO¬ÇÅşâ+¸y© “”Á9^ïÀW}á·	œ—L‡Y j1Q¥·„†1oø’°/FŸİ©OŒêqÜ¨S”°÷Zl…¥Ÿ`´™î?lÔcB\×8|6˜˜ãV@Û*h\# AküüVÛÃ°ßâÏ!.¡BV…JÌümÂ¤€ÊlnƒÏ¤ÆÄõÂ-/–çç$Ê­*ÙdV74µñHƒÇ[Õ‰OBàÒ3…¸‰ÎúJİzÓæÍW´s?SFGü‰—FGx:ÅìÏ9¨‘éIFå¨•a‰X(<—xj …"—9£‡q<Vat\Æ}i½ßø¿”vy1f#Å-ªÿãÂï:İ½±¾d‚şw=iúâ·k˜·	R¢×¯,õÔêw-íFÂãhC¶>”.üŞşÓ
Z0Ô}!·ßŞ®Zr.OnŠF:ó
l˜ƒnlYOÏôh™@l¤¦@_œöYF¢L°Ò.ÚnñÀaNÂ(^	ŒEBGMñÙ,$×T|r¦–y›, ²6Áv¯/È>gÎõÁÃQLã¨¶´¹Ö'Â§ï½ö¢šõÉ1ñ¨!0Aº3 XÅ³KÌ‹Ybfªy‘u«ÎK•¤ëŞtü†NôÈœ«$ÿÚ3–¸÷näøRgd;˜÷s½ìÌŞ>ìÉÔCQ?{cœÅ|ugg?­éô2[÷’š‡—‚O¥"¿ùˆRõ§¹x•>§&–Xğ “âåáÂcmR¢ü{#°Ñ85t·µ€M±h¹(ª”)y™ê‡‡&î™öT6@\/lø%a¤ğ„fR2Öô {éÚHó)í®¤½	ßë@¾Úë˜j«”¯	vğGA®Ëµ¹Êõò†®ğY‹gê‰ò„;1Ô77¥ßğ*[ï™,çµvârÿÔtá?‡ˆf­ŞC@¢r¥Öiü¹CŠ×(sèh9Š\%å#|£:cÜúUº‰°Ò‘ø“,.ÓRWQøÛôw…*¢ñO.™1&5=»^#àJÑg›m¨M¼Å˜oŞ+‡šÜj"ŠkDÃ³tÇ”bƒ]€ş·ûşÙBÚ…Z¹]’LÿÿO˜,k“hâ bw uÔÔ˜ÿè_Ü©+¯ñwt “ûQ•‹µNı
Óè·Š-ttº¨üÃ¤Ş
ü¹ÕH&ì]ígÙ¨_ƒ„yµò¸ÿÑdHÑ5IGW6hÛ¬HŸÜ´W²OP(§.4a¶‹AUØáB‹Ä"eÁškr‰ë%,jøo†hX´¾wÇ‹Õ‰?Dû”lB´r”OaÿNhĞ•^‡Huùz#	9±b®˜zŠ*ØßwŸœ‹
šT%íéHÌwL»%AÔ±oÕbT ôõ†¥n-2=•`â›eY48÷êW2˜5ÀC³ÚHT	jÉ{àì}{*˜q"¯ÆíÈöà.œÊ‘!€3æ+ ª»ÀNDçÉu2‚(U¾ymgxÃ8ÆşWK)S‘Ì ù7ãjÛÛë›Ù;§Õ¢xc*gÚŒ¸´€³·å´`Ü¶è±b“6	£†dÅGI %ZŞè°³1™]Eb#~©`$îgÛ ¼ßrÉßøÂ»Í€Ù@P0â3¹4+aë}$…ñrê_QqÀ“v·£,ĞP¯^<JXÈâ•ZÍdo@Ëæ÷§G¬,ìS„È8…³ä¹Ò§KD¦Ø)|æ|èñİ!R?¢Å@xcGJü âÕ5Ì‡ğ
Ÿ¯ÍÙ|¹ó)ÉñFßJŞ•?£È.ØY+I¬\ºœ”Â ‘s5ıÚì¡š}@5ïv†ĞôS›	·®hï¯di„â
WôG"eËo—,.o4µvæN¦ªÊĞfµxÅc"ä·²^Ïì+ÛY¨§áŒğï1¦á²&…>ª¿§8ú©[áéÏá[y§¸6ĞRü„²š¦üÎà ò‚NşÎ%—««›Í}…óñG.z× r“E¢.¼W€“*jœ—fQr‚°~ô…Û:ú¹ú
;P¹#ÎvÍ$K¦pÜ³c“«¼ë‰M)`—¤ëM/#ÇØÆ„WÅf/pk|‰İ™à±Ù[XëPxK4—£Ef{ò/Rßm¦Õïù¾óu@ÊÑ0i'$Œ­ş{iGï’fôO´ÀZ“’Ğ$ã7'=ıÌ­½¸^şn`qÊS(NŞ{z®÷ÂsøµH[¥zßiÜ@•!wfÕV~=–S0óè¦Á;éñ#<ıpu÷7"Âÿ`•nqwó­òÌw–ÔÎ€oIĞ™¬SÖöfìî¨ÁÄWGDÆÃÏuêÀj#r±N›q} Å2„V;eÇà¨Ø$¡/YˆïÖ-ââÊæô;í¤ô„Nõö†a¼¥4…4T7Zd$é  ‰É’¶½ÄÂÄ›ö
º4›œ:ÎÒ$şÙER}
/[*eÆø%b´SB°V[ÍƒÅ“¶0g*Bé ¸om†ïìEFÓ¸h¶­Û•Ù”úã¹*RÿR®YTÅ$O²"£Ä9‘öƒö*|•^­Ø,ğ†š°V©É[uàÙè+ÓŞQ(MjmƒÿMĞmk¼ ü½Vg0gşc?İÍ`äüzš§Ğ3,q#Mã\¸7
9ˆÄR#0‘…6ÎºÖŒ!)MÃÕHæÄÃ;[©Õ1E@¤n‰öÇÉ°pR€‚ÎòÂyI¾*aIŒûiì9y—'´	wCĞô,[ƒb%dy?Dñ¯%•§N¿¡èóıï#•Ç™fË&Şt~3³®Ô³²ßî×fc*5Ÿö§î¾İ—·”%>öš#Kmq¬ó¹¨rT‡äİùÏ‰S¬¿üJ7C)[…ˆ=eWò-—.4úÂùÈCªÖvŸ‹ÁSË§ë°@ßmştÅ{„¾ˆxÅêJ¢7½™5~¬\\ŞĞtÑª¡/›*‡.Æ;X…ºâı1qqãuK'YSò6õôİØÂ£ÔaC—’Mrå!‹ônQwuì¡¶‘8o@KÌ1Şáª²lÚ¾ï¥I…ïè>”_È½Dåãè€|ã”ø~Â·ÙÓ¦!^ı™İ½E SuÁ
x!ANxH™u×ÍI¹0ó3:U©p³Dæ7Ä'(ÈĞç§Ú1ä•šŸi@p(`F62·ä.s9YU‹±ÔÀvï|t{SÔˆ»·{hfc@‚íÀ£†wP!–6ÙxäT…Z^‡‘–.zìË3u¹å;~~²kÎA ;49>)ÅÖ)ekëh[ËÔq>ÜĞÑÃœÙMß”şİL99{_×êµi‚t€!ÊqĞÄA‚Î“©KÂIPùR%:!CØùñÿnÏ„”b—ú0 ¹:j'æ¾ÂEŞ†oRÇÌxö‡¸µSüÿ£à¡]Íˆ"EVg)”ı?PŞé%pÔ¾\:ƒÉ‘}âmR–{ÄyT”¨«¾Ë~ÇßÌ;6—œE>ò=æş>Õ/gé¯¤5‰$ÓiÏoŠ£Ğuô¡aÚ”ºšGÀœR“°R|Vü¿ôÉö/˜†qp4ÖyÉû§”İ„Ufi´Å•Æ…-<õPãgÒŒF°>MG+NC§Zëñ$ÁzTİ‚ï­hÖÒ¶nicÌ‚ş_Õ˜yÖDFW3‘.R«MÜÌÂ¾MW¨aÃªğÖHw»¯‰énKs3‡5 ¶î¥RŠ\’yÉÊ	õ¯^ÏÁbÇ…Š+Fi7à3/ÎB”‚ÇZœ8	EâêÅ0AsmÎúÎĞŠ#„¬œY‚Õkäÿ)­¢¿†aÒdS9.
O!á6$'/Ì¦Ê(–¢[i+fr9¬&C&úAÄÒcû?¤ÿìÊa}³-Ç°·oŸUº‡„›üøÏ\öØLÍ&jEĞ\Æ³)xÆ7øIØïO»	´•aW; íñXèÏüõ9ˆİ¯)ÑÊ¼AQ›ÙA„wWİ:ºFƒ¤‡‡j•ŠÔ´FKj‹Ü8¥Ë&"¨î!×ø¼Ô<åĞd_£1j#”8<iÿUs©õ‚Ñ0`u<–æß}TCÊĞd“¥š5ßÉ‰Qèt¿š<2pÙÊŸ®}RTİ`M¢Äëä–Ò¯@ïúgš«¶3W n÷˜`†ÍWàDâÍ5€ğ;xlŸÀÿæÀ’ó‡³Ó©m€gKÀÄÑ¯‚¡|M‰›¾ÅdÃâ`mB“¨CsÓ1¨ ÖMÏ§#©ùeHŒsèxÎ´øímB­²p³¾¯Š_*ı™ªóXz„mYqVÁëŠ9øˆCï¹»Ò«è«?ëCZÏFY>º ƒ™)3}ÿ|œ\‹,û·ûİª°;[0o,¯x~G%LR‹ÑS~}`äÏN–·ÿ…]ùx40ÖMáò9…m·W(N7mh©c,e—ˆÈ†{œë&|A¨ãš‡ Ç`0†7Œèe½NIs/	…ÉYI^5ß³|vèN—b³>?²¦¤¡ç®ä
y“©HËƒygâÛ<)ìİ½ÃÄ?S¾ğA$òßæb{t³u™ÿ‹ëÎ`ŸÄ°ÀãhbMÓÊˆÜ.®~J`¦œ'¨u6j'âa5÷R¯>àù'ÕãZû!s@J*?åéÄ³†§iÇP'Efàõ-Ó3:Ù%©(LÇF±–v&uz8rb§i‡¼EŒÔ¯³›ÕN¼&Ø˜±€–Í\\^C-'ûIEğÜüp@½O¤7!­p/Ú7ä¼C¶ù ÎÌÌÛ–ÀìòS4ëE¾b9û”³ÍÎìHM—sœÎä;ûÒ5ÄC2v«
‘µ44¿¡ÌÈ¤Å9’a¾û°"1h4İ¹]&f¥ëœ÷¨R5Ú9ûxëMA¾Ãşš­>¥RXÖk¥8Ä:>maˆ7×ÄûkŠ3rL£A–×>¢zÍï(‡¤;­švİN´èesH°ÒY—dF€ßš¹|M‰uUöŒ[Ï‚Ñ53±:p¥µƒsh©æcS-´S{Iš_°l4YD¢<=È¤jÒæ~$¦æ\ÁÈç–`ı=@
–‘f2ØBp	·Ü¢	†ÃHzOFh©O›·S"Şºs(z°f!  e­èÖ âŒÉeWà‡¨‚3¨•!iŞ¡šoÓ‚à±PbP-Y š¢ßŒeÇÅ·›1?8'2„ [1ø½Ÿ;úíQîŞ§¶ê4)C¹}½š8'ÃÍ»i•,L¯i‡kØŠé$½ú7¬¤(JÿÄæÁK¬ i1å3bf\9ãşŞÑ3Êwrœö./Dé¾Ê3ªtÄ6‘şáUÙÖD²‚ÿÉeHÁ ssÌO»5Æ,eá„7/GŒø›Ú©ül‰hU DÙéŒIré›œïÃ_t´_;xo'l9¡’Ÿ äYÜĞÌ•÷Ë ø"ß.ábíÚÉA¬œq#àò|c‹’O?·®ËâÅzäA^üªËª”¡ÁƒoïI{ŠÒWó=«].ú¥×{×°&HÙ?<`45/”jRyX2\J)£,	·NZ­¨p÷¸Æ8¢dKc0‰xÑ·×'N¼ª§šğxá(½áß%$Ñ3ıÜœèXŒ+ù‚„:U@Zå7T;“Õ.+Ó¯tÙ½KK­oâ[fÃL\ô‚_&OI8€¥ƒ†úòLEòœ	øÏz[_Ø"f„ıhŠ‚²Ã„' û‘æåæ•—Ò È¡‘oQc­aa¬Z[ïKçJ©¹¼·™R‹úÎÎĞ)÷ÃÖõ¢ ow‚¥º}`•îyø2®¸Ûúö×*˜Ğ»_çÛbùŸæ×3öWrp?ÜPi%&Í:Î¤lE‰èÅR`¦D«ÜSéC5²0•À€$KGD&¨z+MôoO®kaåI{•÷i&ÓŞFËÄõàí·rº‡aÓÄÚş‡j:9W¾P#¦µïöNı—«b`9SÕ’zçÇ8Iæ1È—Œ”ñÂ
(Øñ	bGHƒ…¾İÅtÑñ"J5ÂSY#»æºäÙsÔ”B*Øuò?¶~°Ó§ÉˆøÜ(öÉÔ»$ünúPÖò:]~(‰£îá&Ê ´g%£f¦ˆg¡e‹kı¦d%w»ëM™tFğ ’uv"«
Ìa_?ê|á3Ì.†i_š¾ôæÚŞ“I…ƒ“Èì–€”1-«dŒâôhğ;å~ìN0ÖŸoç¼ÌlÕºr{bVø¢<¦ù¦6zï­×°5yÚ€ı”ÌJ$EnİS\YÅU6ŞÎÄÒêŒ¿«ï%È¹³—>û/Ö›¬¥§¸ä
»ÈH#xLiƒÆeæeí-’¶ƒCÄ’÷MR)”/‚°¾„m%CŸG¢¹ÓœıÀ]ĞtE4‹!çGè´¢(}IyÃ“ ;D;Ré¬ÖDfvXüø.Gp5E¨ËCœ€;!‚ºÂ:;â§á<ş00–G¥ú,isã}á>êq€ Mñ[0VbE• œòd8i¼&?ÒX'Åò§!óğ××j-“®{::Í9ÓFEÎÜklq¸jÚesjÄŸ[^TEO›z/â‰:Ÿ¥‰Âh›;DÈ¯ú7ó2¼w&v)µI™}ÉB7vgÿË#2ÀÁşê¹&œN‘bûëêé ¾=µç?¢¥íë™ D|ªé­³;	À
­JD	Ë0•Z{1lã;B*7HúFÊ-ñC}?€fuÓkgtˆ©ŠÉ±¯¸‡ç´K_ÆûA¹Û¤\–O?dRÙÙÊñ™hwN•¯
mu5@YZLïV%O:­¬Ëü0O4ÇµTå‚‹œFE`1G ¿y#ñ¼BâSûæ_ß/q%ÆñõB·=ëÍó?b°q¹²ÙÍÈw½Íz‹nÌŠè2ú·n»q0Hæ°¨}ûÖow¡2s•{‚¹Â^6R98×/uÇêé¤$q7sŸõŞ(ålß½¬ğı]¢daœ æ”~Ìã_Y6İ£LxdÏr€‡mŒıÒABî—îcÁ?fëmS+´d± t}àÆqéáMÌ®PôR‚C:æ˜@
´ı5,Ğ(çdØÑd®âO„BJı€ŒàPxJRm†>ú	læ
„ğ¡8}’‹@şz„ãøX·n”-hçVô?úF_u½+»sFŠ@_»óÚe\í¾ã§vÓ¹vŞFãyV:HÎ`ŒÎ1¾ãè{ÖGG%º_‰åù•» nW|Ç­>(şî{’>ãs ü(”¼Ö·şô¶Ö	)ÿ`–Ÿ#·ˆl©Ç1–¢¬éüÊ#şø^N)0t¸ ³Ğ	×)1Í£\ÙtÏ\<µ[.¾å ®|ËßÉGİh”ÏÚ=£“Do÷¹Yñ>‡£aÃBŒÎ½Q‰v2n”ª…qï„R„*‚£½–4¡äIÔTºEm5ã'!Kû	ò
ŒÁy¥Uó˜¯G™uÁ€JCÔå‹ï3í¿‰£õ;mÿÓ‰Éî9/¥¨Ë‹K!„-f˜·“õ”¼‰Úpï•HÈ,«ò¯Ö¢·ìgªwÕúºq‚Æğğ¸yŞÑx0–}”ıÔN¹å–	â³øÊĞgBPòBÇµõ!Û
¹–‚É	Å¢™(öfĞ•ùmÿyP;2ç¼û«¹½‚<óºƒøıiìzÚ`˜q–{P		$&+'È“/ü¶MK `÷*aŸ¼Ôu»6¶5f[Fˆ)äyà/½Rœ34¥5njOç:‡QÆ…½w“¥{¾¶?˜Ù`˜Jkë!Œ™È©8R:¥5#^·«îm‚`ßè¹Š°àÌ/Šà£:kôó•	ĞAd8´‚‡ÕÒ0×Õ\£D¬”†ùŒ¥ÿğ#0WÁÔ¡zÎ«äWç°j?¼jò/áÕÇWõjœˆú1yb×¦‘åËò”Tl¥øÄÕl–NSäA°ß­×Ú0ß¸¶9ÆÌMëı5Ó''‘R	¾t'â+-ï¬G}ùeÛ)ßJv7ûlË¶Ş‹Oî^Â§ ã*Ó6íeˆ¤„Úº¤’æğä›bË7Ää ÿJw€H»w¨WOkÛê0!×ØS²üÀi„íåÊ ú•Umú.‹/ô:w;\%áãqƒB!—áU·n  eÜÈ9
	ø§ÉÔVÁEÚs”Ä2Âßö€Å¥‹O*!ÿ%™Íó.ú
‘ôå‚}£“aÖ]JOeiŠõŸ’Ñ}§W$¶åüÑa‡±4æÔ»w³ôÓâœà‰èü/ª]®âÎ’…|Nøà@åI­"$æpMø@À0öHE4†/Øf­O)óQš³#àFDë~'V¡õ+‘á~VËİ7ªD R§Ã ¨½ÀîP…ƒ,‹sŸ' ¸í//£º–÷ÿöjMlCO¹Şî+±7Ê'±&.©ænÎ]{vkemİ×… [İ÷İñP ìIoì~êğ“2Yº$aµs[	@|?Š¡Öx"€÷†@Òƒ²WÇL2²v]¢!¢ªÆıã9ßm¯è¸<`ÿM£ê‰´¬82ãí¶±3¿f>ŠNã&Â|uë”´6¿¾Œ×Rà,×_ùÊ¿Mò$.›YFp$Dñó'ùô«XT„KŞD¢´:wmâûMJ.®óù?9‚!9™±­É€«B7wÑ.V¸‹£û¡òUƒrV½ÛV€İÌ‚}ˆB(ª(›ã`Öğ!Ï‹ˆS2ñš~…s¤ èèãğ’8ÂÏ{kŠ>p!‚ñ(Úîä8¯wäÔ’ˆû?8‘kõÛ3á:„Ó—£û;y)Š­.Ê—åğ‡Ï+@fêt"Ô®+qtFbÚÚë6üV€@d§xÎ|lÄãDÃİ]ş*2ÆÒÀ[})âì¯=ñğıùîà0—P ²ØB)éím÷:(	Ğ§Jê·ÿÛ(-å;EÒ´=ƒ¼¶0ûVÊ£x6¦×“½ER²T¢C¬( 9RZbáô´"-IL?fŠ<U’²¯¦ÈâµëM*>cïi÷ü—ïÁ,çèójâ- oeÖ¢¤'£Z¤µA)+‰]lúÆ:ÜNÍÜñÄ–Ğô¶tiP¹›+Gxz ÃâC\Ç<¨Hœ“WÜ*ta«ùÇ•×TùwfÉŞ§÷ÃÔšjY:Ô ^M£j(õr¬sBÎñgş°}Ö?äúœ»²UBWØÖMî yáâQ!Ÿ€õ‚÷ÎXK^ WŸsÎ|ËG¬? ãM·È )h‚9mªÀ³¤{%êjJƒiQ„g£È¤İ¸MÔ¯ùà»ê!Íå÷Zê(•¹A­¨—xƒ6‹aO|ác¡mo_JøC/†tÀÆä­q‡OÂšİ‰œU­L=$VL±è÷íÎKà”¯$[Ä·BÁ$ËŠshkê?Fjp®]İ¸h¦@ªs<sM4lÁ”7œvâb[4BÚ²¤Ì/r¹QP?—‡Ùİy}¢]õR`44ã92+à±X3¼*<­»ŠHC¤Y©UÕÁHwêóB¼>¯’NVÚG†‹
F›iÖ>)_ÜÎî3”G¬~A@”f'Ní7 úœÒ;Eã2™_OªsH‘É.ğ%'jw>p¥°é.İ{…s•{Ô,k^Å©›1¡@×ô³OpiX•×Ö <}ğ¶¿ ¿2¿Öês©ÎB¤zŞ©ŠÎàÁµ„ó¤k…QşÄ œÌRçÜ™{êËàTg'¤İ6Ô1x§ø"[Ïz¨7í"ö`.®5w¾àÛ1ÎŸùirICØªËE8}¤Îuc|zu!ê"U+A<úÛ[Òá•ÍLµ‰Œ·/>@èù­DáíËëŠ‰¸}<ä(+éÜ+hÚ· ²äA¸”‚T&i¥{¹;H‹• Ó‘ç³ uë3†}Ğ#šLÊ™òtÎ]="àædpÀÊöX#Fv_d	v‚œİŸíÇzù„ì«‘íØ2Â¯ëEq[„HÕ7À“x´~ë+·¬ÍF‚’Ë ·|Wüé™<WTqJV§œ£ŒósªØgÖ9™µ:!‰ÿz¼c-¨¨p~®"œ…ù-lCD'ìl‹é]h©C÷Á¶@Õ²Png2Óí<Aíndè»²ê "-XÆ½WØÜù|––ÈãyÎèP;CÏWíwOŠf<vNx +ßİøO]Ûæè„­ÿ°‡À)]dÕµÛ™ë-#GĞ´ºG½+iÒ1QØhÈYò„U¡ÊŠ)‚aT"U¦@†'
ğ]\ü‰Şpğ”h3½˜sÕóô/’Â*]Ç	dng#eã¬+n¬CtØp­B¡ùU?VMú6GÈb;Dã©$ğ	HÀƒ¶<üV|œ Õåp`Ş´µğÑN¨ª]¹ùTé¼¬„Š¦ëš‹P¥	ƒbKF(fÑ#ÑøyŒœıò¹i¨Á<@€³N>‰·1¿4ûG=İÎŒ.~€dpİ^’Z’¬î‡Àsİ×£^¬`¢£÷õÖNğOÛ:69:O2ú-ıbKòéğ˜Rå'Ay†@õ/$‚
{™¼ãCïå°H:]cVó…¿÷ÇØ&ÄW"ÜW2Âù™Ğà«TùÚsP`où7rìúë—áHTæ{äí‚R YÅäÖ³QZÙù\gŒm[¤ÜX!{Ué¾_‰ˆÏdlÉ6¼–ŠQ'ŠâìÍÀ—#]Õ¼ÇÉsmHb6ÊÜ2¿vâ<h_Ğ¥ïê½Öš×Âıó’{™U0ğ¨šØ´0òhßaDâ8œRìÆdŠ¥IxiCŒõíÄÍ¾j’·}›kÛnbDRbqP~IƒTç¿×E­,ëyfløz—ıOgÖæ~Poí_¬çúáé¦”(ªÍ#;60zRñ€@‚ìæİ:¥€¸û"ô]ÄRL"r›£PmJ³Hñ¢¤KÒ”fóÂ£kõÕ0¥»¶<Ú$d°“´_×¡£à•°Öõ×’™^"ÆGMî)¥ÏU¬ïŸ‹¾Zé>RÎí•»-,;#lTíÚºs¾zŠ×„mãæêv‡ò77ùöÇê1HÜ¯«Ø~„hä~N~Òğw ’C¨FeÂH}@ÔŒF›ÍL_ñÇ,ü+è?04Ğ‰½ñÂS]¶2Ğ%_×Fjª=Ä¤Ï¦‡•tñX{ªê!¨GÔ4àxäAÊïÿiJ]"8³Á.A [ÊƒŞC´8¢/sü~—Zs®yá™‰àrµ—BúŒÅ¿¥Ò¸Ô
¡öÇÆ*B¤\3˜½.FT…HJ–À¢%º©ñœCK>U«ÚC“owÈ|\R‚]Jú¼f_ôxjSjçEC}›•¸²È3ä‚òiğß¹e´¡ìk0“Áıd¿z	v·ÏÓ»s,8qô‘ø=o<ñ«ÉÓÒjÌ·ÆˆaÃWómP AZç–ƒo'íß…ÀÍQ£¿;Ÿ>€«££)œ. ?¿†0•É!ŸÅ2å5×Ç çÖÄ_60Xö>ewáÖË˜€¦A=¨½„ÂÈ¶¬Ö ¹.!ÍÉæ­üû…@X%æ¥+^Ù ÖÍDù7-s—’ÂÀx2VTÏ~Ş“šÀéüBúÛÕí–p÷²‰¼W'‹QUMş¹ŒOn?ú%¯õ…CÌœnßƒ+½M¢É-Å«ø	_vBˆ
îÓaçoS‰J†g»ÎL0şiÏ¶£5q7Ö(ŞeãéÌH1{´½œ•ÿ®CöwâÅ” ğÀ®æ)ÏøåŒ9–6)ÙC
[ÎÄÊ˜R:#œğOneu[Î²V†l ¾ùƒb€SzÀÄŒBrıxÁ‡S1QşŒËÃhüDB±ÈæÌL‘j(¤T¨D®gÄ„òş;‘Î%0ş!÷?¹â¦Ï[ğ×Dº{ú©‚°4‘æØ|ìu#@ngáBıPğ°aï©SjÒ¼bàÈ!/•`  ÑUå¾êPWg>çŞ4ïg«©.Æü¡Â®ê¯©óõÚXh,±Ö,j1µP%Go8ÊÃ•(Sg£“ñpø—lJ,{›BZ™…ESĞ‡ËP	SíØLşjÈ©Î—“¦J·RˆÎìv)z§ûóôÄäQ5Ç¤Ğ¢$6êÕ×Kºäë‘‚æ­•ƒàÕjeˆDÏ‰İIğ¹•±A“Œfr¡`rÈg´G¡ÓIU?¡#Ùq/˜
l«úÛq¸í®¯Ä$(ÿ“*' 
g\›™/BÂvx6BÇÉ^Ó/Î)EÍgÓXy‰½¨´i5±<QÓ÷EXôıßÉÊ¡ÁûÌ5("&¼!çîÓv/YZE=Dˆ5%ÅøIÒÇŸÒÖí·Dë¤5üÃrHYK´¸RÌIİñ=Š‡6-•ˆ¼@f¦­Kú4&ù½†–xé#Ø†62ãZ‘U9D=Fı(Ç®/zCk/Æ#™f/ÍÊ\_ÅXIÆ›35m®BD»Ìöı»võWE•?`¬Ğ)›¹ZbVQÃc …ÿAÙæÍÒ)Üîå×‡ï[Y¸¦ƒÉÆ  Õª(Î® .¤³ğ3÷u¦ğ2+Ö-ôÙ„îö¬´Ğ7a®^ofñ‰FõYBI@›P¿İrN]–ãŞGîÖ{o(‹n´ºz=¶É¸“•ñrÿ?=ê®¼[!ï¤ÉâY‹6ß¡cZüyÕğÄ”âY½]÷Ô;÷˜Æñ¥›ù°xúzz‘”&à .t…íÒ
‚]ê3à¥z4à€³;³ñ_·¤<8ƒÄïkwé¹àI!şSk?–ÂĞSÚ¿ìFna¦K‚mRàVrñ)bÁŸÈ$Û³©j:ÅŸœæ/’yÔhQf –Ş¹IÅO4M;º¿•I×1Ûî±C¡ñÃ¶ÀIT4¶Å4›eüKmãm?µKO(vÖN_Ëy¼ÅÔÀ—'3‹Ûà;ˆ4ŸøUtOvİ–³¸–ÍšJjì.uñİn¼xöûÿßµçK`q´¬÷|£Ãeú¿úĞåØáx6Œ—6.–ÉÆİš¿$ğ$9ÆNÃ	¨ï[Ù³£û<˜ Ól¡ûQé)Cn´¸\¦Ëƒ^é‘(ê©ı|i4y¹ÑË9$ÿp@»ôƒô;ËÈjM`àãÒÍÅ0ğ`ÒuqÌĞ5Ê;D³ÕC]PÕî\=æ§´.2´È÷(zœ"„ñœôï£røq±í8g³~©ix	B$#zz$#÷ü¼&­bHézˆÙ:lŒÓ“kzœÔï4—FEŞüyLª¶QR”93¯è{Ÿªö`×‘ZËLX“ç]…K!yÜ¦Ü—ñ^k2·Àñ§¿ó±ášØ­5ör/çÂlšDÂ¸¨ö.1üpz ÷ZwÍêö¶~Ş¶¹U’€ÉCèÂ9úh‹Ñ¨á61ÆÒ‘mÁ-íRí	34‰ô7nëb¹İŒ­ºLD[¼b\ïÎz«šÂª•=T0Æ×@¿`ÃÍ®L	ºzºJıj©¡;µU©É,p¬’d°G­:Ç#;=‘E*¾ë;<™/]ÑJÀHİJjÇ¼KAâ!pÃ\&¨ğa>îÆ:É>ã­–ÛIğUBœ5ñtì¯N9ßYÔ -Î`î5'DI
âÙ È	†cgK1?Î8Ñ´?m¬ß>Ğ0ë œ\F ÊÁ“ÒdÅÆ8#¸¯A’ÉÅÛC@qxkŸ5×(%ÿûÑ§}­ÿn&W!ÔH”ñ\ü$7çÈïh–Àá¯ÒSİ
¢+št|j(âùÆNãš]`Õ½8nö·N|Šaé^9Iı'¨ux¨7w u¹O/B;5
 %R“œ9øø§¼ÏÁ¤ö’ Îğ[ö¬²Ï ©{ñ>ˆÌÂ‚z™1Û¯ßY$ËD[kŞnY›R³ÚÉUjÛHÓûŸ›Y¼TV°m6±`x=ƒxY!§J‚ÏÇÜ+—¤wN+·óè™Ü‚†ÙµûöeG¡
¨WÜ ÿ/‡¿AgG×òÕ0VŠ$%««áq$ïÔ^çò={pè24²ÆXOtæ^§!¿§f³ò½H+ 0˜RªCğEr‰©në2¬œöÃÄÖ{Õè\vÜÆ­?ÕÆs½´´°œë—3Uä§‘xF‘¹-)µê¢Bì0;Á0TÀâæV-!ÊQ„Ü+ŠSr¬%½¸6ÖÁÕó²ôzòËÎh¾ZÃî$[rî‰â\n6¾ƒù#7q[tEQ(—rl•¿3vÓø½éç£ºÀ ü¾%è-ÔK¼"µ‰9úÕ¯&É¥ÃÇø»ç€·[_€ÅaY‡· esGõ^—k–×Ù½‹±'M1ş#Sİ$¸{İ£7|ÙÛï´»™İk”ÁXØvµ‘@ÒÇe¦eç‚P£Şù¨ª©TeøM$Blˆs.úM÷ù¥ÛJç!@ÀJ“®Mghõtq0RúNasëä3áCLgıàøİÆ8²C>a˜n\<'Âjà…¿pÅæW@œ”ıo.ö„Ğ_r"°ZŞvƒtgñö¶È >
…kòkQ9Qè1¿bN€$l’ÙédÕššâJµJiŒ)@ËfMX¤:ÈhãX£$“¦İ’•ŸG¾­$	<;M43•uº,É*7(õSÏqõ#Dm{JM„8ØêJÈ6/UiÂ¶šWWç*`Ìi±çÙÄ}y1Ò«&Şßóı(UÍbP5ãŒ~XŞs¿xøÄ»[UÀ4½Ÿ8» ™ø–”­6ü÷(ğêÓDË¸
ğˆ=Z?2\íı¨r‰ä¥Õ@ /eœ­¯—ôJºıHº'ĞÚ2Í³„’‹Ú-Ş[uzhø	ØëTÒD9£Ñ;Æ[¬¤àÙ‘ KÒP˜âv½ÒêØõÆ¡bp‰› ¿DŞ×Q‰çÙ^òGB×lâNşû,‘Ñ§<e´‘QıÑ§€Áï1(a â9ø4%l”:>7_Ñ
öŠÌqœqx’_—+|#»{XÉp¨Bç‚àÂeKÜBú©Ş‚KZÔù.ë¯ÿN£à4«ö„Öîp›uáeÜtF…Z1ó­É™‰¦Ù©z”L=´ğü^`T%W#£B^Tã"øN=–¢˜ó0$6\—¨ƒş‚³åÚ†Wr%ÅÉ›ùàr?•±Ñ²áºÛ»ò”Q[ÆIg?Í®ú{m\]ÿÜòŠ`Nf—ç3QrŸ:(´9œı{A¡J%LÑ€È7Àˆx^øˆsCåc±^Òàé†w)bè	©"ğ!ñı’†õCnøÉ_+ç°¶>k=öY_í6­ÓßãÙšËÿN‰|à~
8³E€›X«s6^èî˜Ğ©MÂßiU: !®Îh¡
·¥0à`û4»ïQi,Ñ°«7åûAÁA¬^TõÛ52L|8Ò‚®æÅã
ëÍbJ=*ÈU-c·H"bÔŠˆÏ=ÕV º™Ê‚–DcSÄ´¥WkÅ$ i¹•¿şÙÀí'É£mRİm×@TŒ¾¯A&˜n^– l”ï³HrÕVÕÚ>ğICêeõÖ8³'M¶ a!‰r*ñBjÂ…Z¤Î.7V âœG\«Ï¯E‹áÊZM˜Î,˜^9dX*ïíĞ)/^säî|+µwî×õƒ/•ïÍ‹şL·U,½ŸÑt*—`ëT‰Ä\„R«ôN?Qñı-¤Èm×·*äj×Q¿õNêa˜uu è_Ş|³6Ö^1ÎJß$7 &ÿçè\Ë'ŒÊ"<xçv˜GSöúŠ'u_ÛîÌM’Øü	 ÛÑÂŠÀ¤èYLM´‘ÊöYG=Ä´ÔE»"Kïu+¿¼ş>„Å–Z{3ÄØHH
æ›+OÅA¼¦£Äâj.·úE·Qê}ÅRªÂè^;iÔƒ_%¡Q?_•§Ñ ¤/‘ Õ–…š¡å"h\C™ü{v_1Àó](­úAœ~¸ı\\…wñ$Òæ‘ÛöSOÍñe‡ ˜5ÓÄêY¼|ñù‹îĞ`…ø÷`Äå•ÛÜ_íŒj:úxĞ]áÈ±á;éu=·ø:ÿ*<ÌÙ¢`ÅÅÿp²Å\MqVù¡Ÿ¦NÍıª¯÷ciê:Ş&h›àwj:¯Ö+¢4ëè8¯ªs7g{0RgıX²k²EØ˜9*%’‚ÔPRœäyIÍ{­X£%".zÍCsÃE¼x"ú€VEêç4­rÉæa¡™R†½YçmÿG"ò‡n¡€»;"=ÇÑ{º}8Ö Àâ.úÏ®³Şªx;âJÂë/ÙÛá'‹#81áäPzäĞq×1\udË‰”gò©åÑ,g¯éA+2®)‘é’ÜW¬T%›Z_÷3%È-òL‡Ø†³z_›ãlp.´lxã±›–ÑëşW3%.šO¢9}šxt†…å‘÷+”4T-“DYw–½H=Îàº:O(!E~Åu[)U¯„Š™ÍüÒÚˆVÊÙmÒ+Z5œNdXºŒ:ÏHÈ¹`¥©·Ôíòé[0öùA;(U¼÷aï-áÔóF»$¡î4‡k"Şæi+oéŸ–„ğvë	@Àç÷¤Üòi½ûI#vô+Œ„€×T¾{éÜzqV%º‹÷‘X@G(N¶>	/¯_‘¹ÙvbÕ
™+ƒ'²RlÔÉÁƒ†ûƒ^B-˜z’‘™5È,æM§Ãqïñ‰i0¿mlf/ÒüJ ~§«-:ÚÁËS®ğçrG4©õŸnİ«â.FKFJşãØ{:Ì·Ÿ1áËECSÁf(†Ü=Ûı4µŞŸæoV»
œ“.};°!’H¬Ö˜“‚:ŸŞ_ySÕ€ap“ìWœÃÀ-ÔOSTûäú¿±ñïğJD )‰ü-Ø¡ìã…™kÚnLhÒ)FóŒÊ
Å©úô@!@~¥(E
u«yœ &—š…ÕézçŸ(‘ã{Í&œ+É›æŠ#Çb‚¼¤ÖÍƒq`“´Ñ#Sg’Z²m¾›²!pùbãÇ*vÎ24ê6Óö—ªÌ %ŞgõàİÆÖ~ ø	¦ıo›S¨NUJ,á)ºËJáˆ‡\uç|Á~{p^ö´ÜÒËgEéK$ûÒËS×P>òDŠ.äÈôd­HĞZ¢®âÅˆ›óÕÊú…ş].GFÑLW×–Å÷Ş öÁõ2>Î¦ÎLVTYJ^ã·X¸.	ß§†|İÄÄ£•gˆ@JÌÌ…[Dàµ¨Ô~ÆÔÍ"œ<6Ö{÷ÙQ0EGı·×KmeñGDÃåäÒ‘[Æ@wW>çâø©BF8véœG
ƒ:=L‡7ß;úRb<&¦ï?éb[ÍoaRó@wäU^?Ó™99«–¡ôİ'¶àÂæ)šK¡j³Â2ã‰âfám¨Yâ¹×åbû*5ç§É^•
<½‰É×K¤¹—şş¥Óh™IRdõ+9WY	[øÃÊ!Ñç<:‰<¦Ø s GD³¤×ÛIj*3Q¿c‚­±Bè‚í/û¹ÃÅW!Äó›>´™	ÂÍë=ø×­tƒºÓ3ıĞ¥'ÅÆNo÷‚ÖŠ`1¨æ—Œ—ã}ÊfÖ§‘Ùå ı4…Ì{¶!Ë›^}ğø	Åöï¶Ó»?R¹ÒxÌĞ&·IÓŞÚ7¨÷:€Eô‰º¨Fñ›ûàCˆ—Õ}8‹’?’cÎ-§Ëä`ºñe4/¶)Œàòp%Ô> g(é“1Æ:üåWĞ'à(l£Ä­ÎÍ€†9ç—`v®·8)PY¶ƒïMÚ8Ÿ…5=€‚äïMEßÒÆ`ÒMàßëı›â!d¶pŸI:üMzÇR’T7-\˜×ü?×”àòµĞ§gÄ¦é‹PNâm õH¾”U»_S2Ùí(Ì"Ç¿‡]8'áD¶ô9ıÁÍÔWsLÁ.›:¿²¬áƒnG“,Né£vmv4À‚ŒvìvoØSĞŞ¿/ÿ®ÀœÚD½êm„{ÇùKöÿ/‚^‰‰ÕÂ#‘(g]ÔJ[é8ÁÔQ¨„}y÷÷l#hR±’ØLâh(_ˆøX¥e4Sâş}“ˆˆİI¢-L‰{YÄãñÃ¥¼½¥fzè ûşª|;º1\¡w8Mı¾"£Îpz²>ÅB^PYÑzJåÇˆªÏ4nıº1lâM.ÚµS¤ÿ§Râ˜Z\ÄO²‡»¤š°[8[Âm¦¡ÒX¹ÓÛEr	«ì¸/ÑíŠÏ<0µ/¿Ácã†C:Y?°Yú#®4–%+Ö¬FÇ{ı»¶ïµdÿ‹õQÖ¸ä°œİ·ï°VÀ©;6Êğbbéñø´W|–’ä²	7béî,üq.Ëˆøİ£>¨ÿï©¦iÕN»"5‰_ußßç«˜|[[rÿUèÊı¡KÄ…L¢ÂşÕb®Ÿitò3^Ì]äˆ×FV«tí°tCö€)1OÉÒªæßTÓv¦¶<+&ß
Ôµp(®ıYƒÈn%˜™M?Ë©q¥ŒÊ4K$ÃÅï¼Àº¤•r#¢4ßeˆ¤ç<0ÏÔ°ÊmèÀäÛ;Êö°:Ã_1‡ˆH>Ù…W1M³£u…Wô‰t[‹m	£j
l‘Ice" =‘­Í‡û‹G¬“´®XM	Énş ÁÆ7˜°5jn€¾%ë.u¸‚ùl£~(	­2X¾QYZmz{ô%WmÛ‰$/ ¿…0Å$sJl5DäÍä¨°P( tå=«a=«Ä²,ŠFw„ûñ1-.«›2şúP­Â\cö7hmÉ]ÅœŞ…Óo­‘ùÆ¦«Û6yŠ=ºÂléÌF_nçitĞùWjú]Ä?í†id°<}ÆUïÇ×
`œé¦«”ÏkZVsè¿‡XtT“·”gÓÏ1 ®iáãÕ×³1G@áK#k.ü˜³Ÿê¹©s”`	›2å3'Dó8*ÖHqMÙ­+$F;¿Ûºy@wcúQáÂQˆŸÈùÑuYN êÒ=ËïÍCˆ$§Ş—­qšˆîÎÊqQúèÌëı¥ø„iBkuv¶{|¤êŞ	V³¬E ì>JÂæ#ÆWßn%´s#%ÍKë<$úvw'šÍãØ¼C8á»?¼f^….ê~Q1…(wƒ:!.†şoE4	>ˆÉ!×À!D÷ç±äËPL1ß"z&‡^«W`¶è½o<€cË$¿x‘éùD	+|¦#¬ÌÃq²4tı´÷–”–h¸zÛàÑ}VfoÎ2£Ê\1gµ£^ÉJÓm{ÃŞ:‹È… ¢B&ı{\¹!Nh‡!®Ë½/‰0­ïMÅ“.Ñ°ñRrqs:õ<ìÖ¹)ÃT<£±A²E_ÓÂºÓ/7Él”[Ü!R‹(Dn¯á«è/áùæ!4éhï;¶:,¥ìpíåBM‚ã5¤Ì¢~9 VfëÕŒI™G	~¾Ã:·-Ğn®v“{ Ÿ”V™º¤ê4Õ’†9{K&÷¾×ÔèàŞÀ±LòùôÑ@KxM@Z\"sÚve­ÒÂ€²¿½œÒàïö3Ñ…,^‡y+“WîéÇ¿.>E[Ò;Òé¢™©íš1p`µåşÈ¥Ùˆ¢8¬
c”pjEâ‚«F€E”¶½Ú§Åƒ‹şÂ×ú•`ÎsÑ¥ü”SsX–=W­+Kè:SÙôùÀÌ°4ş3¨ûë48µ•ŠbêpÇô2ãœ?‘ÄóWi¬³ë]ğŠéÙÈ~åzVwhæ°ßM¥•$‘?Úÿ7/ë—&w,—Ï‘»*’¸gÔ)qfı'ÃÂI)·ñ2¿â|¬–4‰Ä\"œs…äPNÿ: ¸³ù83˜;'^ÀNÎiª§’1Äh•Gv<¶(WÃØš)“g ÚCdW+NĞ²È•Kİğğ.TÓ©9çİbP])àAâY¡É·Õ\©Ú”òv¹1?¸_€}ÁŒ"ê(•Y~¸~>$!Q|–Œ ÇÖe`±r÷»jí]*5„°)Bb7J¼ş&m[3â] §èD4ƒ@wÌ@­¾9»Ä—áŞ§¹ø¨ÔšXr<\sıaåã¾å’‚m6Æ¦ŸC|Á¦H¿œ>ªvÔ`l©]4 …¨Œ›¡F@ù·GËÆhòSñ…Ãqø˜§^,ôÛÀPá<]«=Cpƒ ¹İF(Ã¾^´Ö2dïÒ",Ù‰^Aqì¢Ô©w|ˆÑ€]?>®Û&ò=øtç¿<áiÉÿà;¼×F”…SH‘‚<¨|·9ëò†ö8–ÙP‹
Pù¯ættZ:ò+î˜|¨>Ôä—$Ë9˜G¨´Çd%’·Q^¬Q{¬w4¥êM"ÄMTw¢m•çÕ….ş”.ğƒåéWlá½êDÒSŠ°lïÎB‹Xÿ™¸”rT-(µ8Sğ†1TØ'Ù?±’³`Â²ó›-’^»¬±ø‡‹D°U#—OpNXD\'Õ®ãå$ú!ş$ôu(Íï¨)–°µpZ&,‚úüvBê#ÁÀC˜R¨É‹Y™µfV(Æ™ÖÔWÁÄ¨rIùeµÅœwÅî£ÕßBÜ!‘¸{gˆT\ÏØœ†Q¯Üt-:(ï0ŸgT×4‹—7Â1txq‡ígXN›œ‰,9Î­útìÈc™lïÔ…¸\*ÛÈÅßÈ§{A#ÈäxiK\sFU[,’!¢ˆ‰vR\§'˜å?¥MŒĞŸ «’Ö·A!ƒ–UœımN¤oKä;Î–xñ²w~İüÉZ¤é(`A›ò"+6İ$v«‰XFêUÏ‚®¹ï!Ãà¸ÜĞ±?áÕ|sá¯dMÜíÅhì…µÒ.j b;(áßfb<×Q¤§e¤•=€–Rí00S‰´C8L÷Ö‚Û#ÛSvÛÿÀı2«àŠ=u¬´NÁüd P/–º>ÕÙegÃ‘7Wí*únLßTÎ$Y­ÒY‡È¦Z'$¹%Åì*:ˆÆMßbÛ]/r´»˜PJ”áœ¶§GÄyŞ
¶È ¦kVcf7B¬øA9¹µ¦VãÄƒ~ÉCù´éÒ>3èzh¯ïr¾ò­¤x¦óp²¿ñœ½õ ¾÷¹åú£:$õ¸›[ÀğD÷š[¿?7ÀjØıBûÉ yƒñì oÔ³áµ\+Ë ³Á’£Lã­†'j^Ø!]¨ÔG4Üaê"{‡Ò  ÃYşĞDW3Eöë9–}àå.3´'¸o]Âã¦BôùmïX	#‰I]MÓıÎùhˆ?…¨Î ÅKdÏ°jwˆ7„9ÛBéÛıĞwC®1ZñsU¬²·Êİ'Í
}; .›«|}MÇ)Ç@h«r}£â±ïI& ,qK§X£pPw‰­£õûóF¡D@Hÿó(X†‹"×¡Sw¤ÁĞôƒøŠ€©ueõr G°G²ˆš;q…BkGˆä+±À˜$Š7ŒgUÒ€SYÙ/sßâí„ÜùGjÁâ¹Æo)•2J7ÚCìI¿lÆÇ‘Š¾sèuL¯^j!…9ºó´ÆnŸ–KâÊhH1°\‰˜à£xX$í‚¡¢`có¯KÒc]ÿ¬"™u¦g*Cà­cp¦Mı)|Û`¸}¸¥ğcß,òĞkà  ^0%ÙUİyÏ —Ÿ€ Ş'±Ägû    YZ