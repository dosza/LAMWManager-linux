#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="145541452"
MD5="2d25d778fa3a167b43e8c82df2ff39c1"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20708"
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
	echo Date of packaging: Tue Nov  3 01:52:02 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿP¢] ¼}•À1Dd]‡Á›PætİAêe‰ÜÍt'‘èì÷¦ñöµmNHµ­v]@k)‚{ –â¤e–L²Ùqi+ÁWR¥Nœ	t¬™C~Ğ‹¶¿İ*A;ú^ãTV¢Üœ09ë`ŠP:BÍà$ã9$3Í+ÄP{:ätÊ$)€T§¡bèiìj·E©ÆÌ1D’ğÈQORjñ7ÚšVûÙ[Úãá©«6~æ¾Ú$e	&ZË&ämïÕ{‡á~TR?ù§HçÁ›®7l¤ö_Óå
Ï·i¶¦Á¥¶¹M¹4¯!õt>œ°ú½iw&–¿×»‘–ã5 ±‰/ÜbôË£¡ÉQFC1ˆ”iNUìXÊ¦ ém2E³?ŒfíU‡ìIsFùÜ+œ‘$ömıŠ¢ë|'U¿@Šš¾Lj]h3R×uBˆİ
¨Û­SÀBÜ" %"š+¨7^tºí0[z¸ ¾Ö3BÉ›¯6¡œÇ…w;1/ˆ¸ı¸è…Á‰m¾^ju	€õ›×kğ[ìWXò+¶±§oc<¯O«ó]zÃßáMù©¢pA‰z›ğ}ñÿé¦ùY¤6¯HœmÇlâb[<0&±ÜZ1fQTâıÁtÆåİxK9çcmXw/)9æÉên*º îå,U_3¯'Ç•œ6îáYw#éua±HÜœxÊ÷ùñî·t%_¶åü.BTŞ*´_tş²DÄÍ_Î6(:-… áâAû×óò•Ÿ/ïO÷¢Ğå—|²~M$3PE)gó‡–ÌtègPÕÕÓÎöJq-ã/‹ï“KOËm{ğ¸F>´A	.¤/¹“fİÎÂ´9jĞĞ-·˜‘ß©m«U w*Ö«†¿Ğ>am¦§‘U±ÔÖ0@Æ"IÎGÂÛ·U;f´MLg¦·ˆzŞÂ	â×
 dÃ Ö»¿L“N3$ÓÈ+“„† Ë+JE¶	œŠc|ğ¬¦5«¹¥ëEè
¦Úc’ã-{‘nä›g
Ç¤î²™5nÈêÃ=yÜÓã˜yä³·uÑÅWM”'t ÄÿŸl¶áµê=agéa59jKî¢:T,ä‚	CvÕÿÜ)ø¶šÌø+Ø&ù‡d53Lëñåi<£Ï,eñæ¥(cqÓ£ú|TÙ×TŸù@áÈ••"X:¡E‰ØDò<Ÿ¥ä´2!¤"¼äí«+RŠwVÊÎZüƒ¯Ÿ~6äÎ*djø¶¹©SXFs.,Ñ·4ââ ÉĞ„#Gif©7µõñ$"Ÿæ}™3ôNÙW!Ât)ŒÂ9­ÊÛ
ÛWq˜û\o‘)Š‡‡ÁLU  xmŒ.1+g­BWhI°š7/…à™7±9ŞôsÉÎ€š=ÍK§mX¸]s´©3uü “†,¤?T[®¥*>©•àH'áTŒ3¤£Gâ`2¯y­Ùº(ï«	ÕnpQTñeóná,„×Xt'ôãƒ¡PİM†üu¬vjdşöÊÿ¢‚±ó¦—ó`+·ıûâQ¡ËË¨uœ,óF•ZIÒ:@×Ê…W[IZÎ‹Aì¼Ç=‡éˆ/­Å%>æ?İwÍâ^jc‡¶ôjŒˆPaLñª gİèfÒwi'fZC;—Î.¡0o€3Äz›‚rÔO=¿¯ğŒE\ùt“üQÔ_vµÁ!»muâù!np} C·€)s£Ü\uˆ¸Ñ8?,£ämş(.@Ô
™afìEÛ¡ŒQ|
#Ñnø!İbdØÙƒÙ›9°µ‡Ô	¿"úUc.m†€»:±nƒ=cŒÅ½à`æ×¯Áæ!G‚­Q,Ôav_ƒ ëä ¥ì¥påèÛõ¯f€×kÅ·ù$?%‰å¿sÙ–ıbàÎvş¡é¤†uÕœMÅÓ=œürL-›õF`şabö·Š‘È?6ÍŠï,8‡FÍåà;çhï?®¿¯Ç·¤öjÆ[¿Aî¿ğ¸^Íos¦¼=gîàÆ£Áë•1'8lÕö:¼İ4¤«yÀAËÀTÛÔRnøGø’.àõèª)§šğzU²ã][M!Hëw¿+i¦Ä5‹è	tjo5”¸&+¦mÚğˆö_qjş{!¨ôwÒ °‹²Cì‹w’Œ.œ¤w±â¢¼ƒ-šÇ³ö{4ú»j|œùì1‡ŸfÏ[ÛØÍìzÒ*ˆ«­­½s}Œq-9É­óuÁ×4$¯Ş«îU
/êDBvvgŠVÚƒw–fhùJ_×‚TÄDÊìC2Ã5¤‚ÈP±3ğfĞæîkoY¦mŒK_ŒŠZídP /ã¡h¡dkEû)åx±Ã±ûûNw­ÜZl*gi&İA‹„Á¼jÎşÆ`´§2÷ ºHx2w&V|Hu÷üEtœN¯‰^ˆzmûÎ¨:|"Dçá‰°úr•w\•Ñ›+-ÃµÔÒæqåkÉâşÉ‰„Æe§Ş%|ÿ$j¡Îæ<¡µôóp
0vrõ kÃr¢á>PBè/ÑğÄĞ¦“»8°i}¶ïzrÖ—LùHä`šEy fsÈØ+¡Â`¢É«¤ÏšJW´â"˜¸óÂê·ğ`@J–¯‰¬{ñ tQÒ¬n¿›çCãæDDú*º·ö.™-¾•F#‹ù½ğ—¾ÈŠVê„$HÃ~A¶Æ¾ÎˆÍ¸\|)>,¶¤ı7—¶ùça™–^„¼–ÆŞÊT>ÚvÃüèıF\¢«:ı
­Î=]7Eä(a?Œ¤¤è¤ôÏ.8‰,»€îİ-Æè¯`ùü‹;ø<€óØv1"æÔÑW¡½¥«–Õ‰ïó Ï*í@CŞ¢c¸6ˆON›1#cËRXö’üğ×"g-úf÷‚EÜwÍ¶ZÁÎ„ƒ”™°¬Õ)€¨¾¦ƒXq =6¼šöóšììîx¿çù³Ì<Êq"ÖBa‰HÔ.›Êœ»p$ïw…¸'ljİ¶éÍ±Û¢ƒÎ0WC²ò—3ªQ…)`Ê¸İ/ğ¼Ç#ë×ÀÌ¶‘kÈŠÜ§ È	ï7Ğ¯dc‡]›±4lK>:t.ñÛ*W·×ÿ¦ñ	"7b.\õ^ŒtæqfÙ…ûıíç&˜v Ä®8¢J,öƒí1<M4ÓˆsOŞM“{˜@¶ªäÇÕLsÓBÆS`¬…xY^µ¢èÕ™ÃAÄÏ~")ÄW5uXëş¢ú¬ßĞ;ˆu4­¬tj¬H¦íº÷} @Ş_{mC¯óÊHÇ/0.M:¤ÇŠ—ªv½Õ'ƒ:äêéÎ€İ=æ²cjˆzÈ§ì:N»‡”‚ PıèÍŸÀB2
Ä°–QÓr„‘±ïÆØ½êfs’C»³_‹TüvMîkÛ	o2HÄf¡Ï¶Ædöï®aÿ=×¹½®ü#.ğÊ ö¦…P12Á t²·“òf†*‚x¡$Àh	‰Óïn õIòOìÊ¼q6}ÈÈiÕ]¾ÈÖb‘ëqØå‘7{Nêò`„9´€³ ÿ$½	ÆÿÔÌO¡t9øØñw²…Iœ5ôbšçJ¥qâæYKÛÍ\	÷àüÀŸŠ…£z‚ØV— Ó
~İÕñoÂæ™­%1âU‹!YUè: l³¢g°€GàŸ!ÉÉ,ÂÃÅ¡PO •@zÌêŞĞæ¬®ƒH—•‡—ânR4äQ/82óğcêÑ`\ı¾"Æ­fŠïİ_:ÙÓ‘tƒU¨b·¦İİè=‹Ë#ã—±¡+}	}}Ç×6Ì°üŸm¾·Ûa†Ó`AêÇ2²¼zf/¡Mpµñæ¡Ô&ªÃ¥Ü×·¦YÄ†Jo¤ÔnSè‰¸I —ÔCxìÌÍò—ÙA9ÒË$å?EWbQcí3‘T«7Gşe?Åt3§”Ù¬°ö‰Ú?p2@ûõD†îwÓçîÒCqŒéŞĞ7!è#ù–Š±mw2ôVR¶ß¬ €]#@¥Ã$ôl0#›”zO¦îD9	ëú28æ…¾ŠîSÎI3ğc!9vİbï¦fO4án†+^†.ˆR(Äh5)ÍıOÛ€MÂ˜ÑÕ+ë»cËZFøîEİsÇ ò€+i<ö.T®™×àDkÑ6®#´l¤Ü?zá$†€íq¿ÎN8îÎ~½[V**ÁCQğqz¯b!\ÔL±èF(¼rßV¡ÀĞvD«Êz 0ëê ''ĞğÙY+6Qo>ñl¶äq7´å%%İŸ«Àu¬ˆˆô–"ªë?â‚Ÿqì×„´‚Á¬ÜåwV ÃNQæhga–1ºxî0æùLàKzHNcNÍ=d§ì6ÍT_Œ¾~è ÄÆ	ÃøG1K¼uÙ(52>²HmpÕúé¿§Çè?0ÿW~“nzÊÊš€¥û¶ò®âJŞ#´¶™ÏSàÄ_âà,8“ËÔµßØtjÀ½QœÁ²’ôç²ÍÜ²¡ş½W¯$ˆ2İ¾Ì&hÛ—_*Ó$İ|áñºi^ÙuG<1Š|®73‚ÎœÀGMÿ¸{i.Y›_jjPzÌç„î³êPº×cÁ·$Ìh¤›û;õGòHN´eÒ/"`ƒ ‡¥f¨‡œÇ<9gv•®ÎîüšjCL#3 ÷¶m*ë—ÜGje›¾àÊ¹®×â½,Eóè>ß’^½ÃTprÌx»Øÿ×Hñ—x³?|ç]ÎîîYMQ2«÷R¥¢á îëõ¦a!Ch"ƒ²Oâıo¨ùKÂÁÜœûïÚİRO\£”¸Ÿ±Âaù&ª•\9ırğ¨d¼â•]ôBıXI…sn¡È(»è´{yà©gä:é‘qŠ±¼4Ó¢vUÃ¾2Ä÷œ»¦éÂû¤<şf^NœÿôåÖj/Ş<?RÏ(S:÷0­ùAWîú5à¯k ö}g9›YXÿY|+£ D>½‹Ø^àu[x`hY[™÷Õu9İ+š8Ì„¬ıU‡ÙÍªD<oEúZÃ­Zé{±ãÙ×-0aãv½“ òêJqñsIrêÌ#šİæUı
-rĞ:ÒˆU/Jş<jÓü“´-Œ©B¾[­ô´{õ.£wïêÀ®wE//ˆ_ÿ“@¢o>#3€‡8*8¡w¦lÇ*bÀE$Èù	¡¡ñ{úf‘6[¬n='ª®S.l_ÆÃÓlş…W!¥œVû ï¡ƒõ$÷{ËZÒ õ™‘Ì4LåµAQ(©ºĞ~Àz²2¡(2íÌ»¹ &œ«çÍ†“IÁ¼”.*¹]mO{E›Uqµ±‡D2lc“jşÃ¼…Ì‹|ÊÈVR‹)µ’™ëÓÍåÈ:¡hè¡åV÷›Çı ˜ÌÄ	ŞÑsÃ¢öÕ¾X
öŠÿ6­À
šÓY’åÑôÅ†í7 ¦.™îòÉKk³E­¹fKÌ5LŠºJßÔ|"_“Š›H\“>‰°$™_.Ív®‚wÜ¹9IzÜÅ-Óº³rµùF?C}Êç½4Òç¸/Rš§ë¤]ğ´:Œ,ÍF÷®P?æ–ŠŞ®2MVH¹¾è£tĞĞş††zÿI0”a)Ï¬º˜¶©&ğre2_½™š¯r‘ \H4±4±^ô“­Y7‚oGóóÍ4›©v¡Ç”†U@LÇã-sWeà1i­î5óÊdÎnUˆxœ·kğJ>zëâ²Š©0¦Å7Óƒ9]xC*ÛßËÌxˆ1ğŸ¼^áh˜+æj-hU§Q©©£	Û*O¾CAİÊeÜÒÓìmløí_ù‹*½œÁöşÿ¯[ {ï½M?z.eÌ[¾{yM£7Ï)”a`_ßVe†¤˜ñ&·ºğ}e›+0÷|\»Ø1Áºô•¹Tñ›×Ä%nÒïöwº†ƒWBõÉÊ¦bTG5¢û	{.ş.	Œø»n@--irõB	ÆCOlô×ÕMA¬Ã?S†yGäÀY(ÛÒhÓğ²o4p
¸C°ò:Æ&“˜ğ'Ûˆ†rÀ¸¾¡ºÜ£÷V¬ÊÉãmZàK3")ŠWXM±ÑØ¡àŠ„½˜¸aÄH_ùS)mÜ‡ªN‹Ç¢†x”·5}‹,kSô]ú[[]¤•³m:Â5i¾>HµÔ›RïF½IvÈÆ§Í#™ù‹«¦QYŠ'ód’Jv“¶‘Ş³˜£;7¹T%l(ï`ú;`*"ãTEcº2l¶qrjÀ©!áõ&Ü&‘_ 3s¯ñ:â8q}í*ÛUˆ´*¸k]íÉvhĞ\ Ps£A~äkù]¨X6u?%•.‹4\,=ö^ƒ¯¹§hĞÀøh´¾ÉÉÜŠˆ†Kq±ŠÿW%$ñ­D¯×İg1Ò%ez`Ñ·…PJKË)áÒ,N=-3(à<¿nÍ§Höÿ›ò¬J†Èbp<ÌoiË˜0Ğ‹µŞ¸\®?‡<¢îÄä&^&'·®Â)-ÊÅƒN¼ğ;X#ñê¢"ÖOû9ãÛlâ=eÂ&¸Im±y0ôG£¨(PC7~™ÜíÔÒæˆP…ûEW\d[¼ÿóVÓ°k\JI‰ÎÏİæVé´+/«¶­Yë'!©Â¹uÿ-jÇ|Á2Rì6êi	#C¨w¸à¾T©ZóÛü´EÔ<-½¦©ÃZÆˆ¦ †h> NËSò#q¬¦r(Ä²¸qÎEÿ^²œ j-)-]Š‹_ƒÅVıŸ }Ï«µ!¡ü„fx›–f¬§G‹A "1ÇÙD§ƒ?èLdÌÊÑ{ÏkäM»7±Ç=(°ğfFzŒ„.«'	E ¾€@¥À s½£½„rÂúªÎBG—0‚rŒ£ÆÓqÒ¥Æ-ùÆ…{ù&ÒîÜğxet©	ñBîU‹Àvf{?Ê,íÉùç®{‰_Wfºğ¶^ÈwgÉT½~œ1²çCÌ3‚³‹6ë<srE‰´H¥9G“©<”wºùâêœIép¾Ô‹[íA<[”ËM"ü*F&#Äø÷§$VFÖT²(³Ñ'~Sg€ñy›çY^wd'(•­ı¤–+¾-4ÀëkÙbò`i|IïWĞåÓbÑ€
Å9u´=VĞh"àğ¬ŞD°RjÓÈÑvò´›»LæjL´üAR1¯Dçg—³èê#êyûŸßs¹ƒ]aÇ#eŠGÃrş¤€¡(H“˜I½ş¯ÔPrgOSw,_­×"ø_¦_qÈ³FÏÙŒ¾iÍ®öÁ³ıÔ —÷&wÜ—iëù}Äã¶òRüîS–Z‚ÓgØ(ñøY@Û¤àwHà£æñ»¬¿.æüö«º@õò‘ûàblHÃºl6‡1úw²™Ÿ´şâö(\ YÑ5…vOˆ8ä±âi v8?ÉåÖ²„™°__$=¹^f	×“¹;Sh&09¹
…URÂgşõë|éåØ§B®T;×‰ í ‡R?‹,/ #>5öÜÏl\iÜÌ§Œ	`XÓjUìÂÆÓ¶>İõlLªCµr Q-Å4|e_*!ê1Ú÷´p¦–%HÛ=°Böğİı±zİ'ÕrŒ£³­Ma˜Q9Œ¡$[û–Å¶ı’rµ<¿¤¥!ğù4nšÂÃîó½ 	üÅ‚´xtÙÖöR„6¨›ÉIkk·<¥\ŠlÔÊÄGQt7Š”^+!Ç>kŒ•ÀŠçê•aŸ9™ÃçÄ]o½øwpŒ·1fçâ„VÔ”ë4ÑlVä‹¯í¥Cz­•¡á¬@²0¥yEªõ÷N’£k´à'Ûó5”‡''1´*ÙŒ§EPª¸4²>jÿ
¬eø•Ó™ğì/yãKîö„Û…èß¥ÄóFEpz?0Úƒ9ñy
QBóL3[¯* šé¦rä~Ÿd|=™öÙ&ùºÛğüN)+ÒÆ÷Y_&¤É™¯‰šc.3ãzqY)Osü
¤q°š”­Å8Y!d­Oñ9Fj/–{§ÏUâÒqÕ6.0€tvù£Æ‡+QÑÒ{e&×´·§f²Ï·úò
’àì5T2mÀ(r_y´%™$Ã\êp;÷Å)ó)ÇêØ>äú¡·£X±¨ßì+åa{çÈŞkşC^6ÓûcºÆş‹xÇQíº°9”¨E¡Óô f3DÆĞä†Æ…1É’ÜË‹oÍÕ€e“sò;!Q>tíôsc÷”"{1åÔ÷¿q%ç.ÙkyË_¬†)âº2‰"Ï«ÇØ¶ùIk6eıtÇ:N$Ä¾å¹–áŸ¼Ä"(F½Œ™«'išKíú{ce¬dyphİôI³$’Ñº¿ñíK·(0ÛÑ%$TµR,+VÖ]ºˆõòi)Â#¾–»7²Fs	j…oª®Œ¢µ"ÏÇp%g¥óÒÙšÛçĞ¦¯|qXy`¸ùMÒ²ô$¾ÿU]I ˜U½´›¹\oûè™‡¯ï£är {qC^Õ†çy•¹Öõ«Az8‚s ?…Œ~ş£B’Ô§»µÎ<x“2«¿ÜÍT¾'u¤óâCĞŒ´Ã´˜O>¢(˜ìÏ&üêôæ¾`2?Ñ€7€-ÆFŒhcµB/déSPÄm*Ïn—ôïna‡öY8âh,NŒxüa)®Qê*íu$7{ø;ĞEŒî9yÛ)µgx»Š-5ÙE¦“ßğ_ƒèk3ÑßKz?“ÆE™v§ûçE\ k+'°îçb´<»]&… t¡ì°ıùaQòÃy=íc¾gˆáH³yş(hÆHÇ•=QEg|²¬X
”ÃHl&‰›åàSNtÏÍ’d-ÅU}m#-õøÇœ ŸàÄÖu$ÚÈñyÀ­`$y7ü0d2DêSQ‡Â9PT3ºµ9Çé7”GÈË~5'|ºà©h?»` šMÏN?ëá<˜>œ$@ş•³pw	=Mä.jKJ„ÃÔŠj¡TC˜>Ø¶Y3³rçİs	ÚfÄNjUrß}]ÄI4ÊqHĞGÑ‚À!ÃŞgÈıö!O(èÖ¯ñÒBP`˜	B¦RN¨toì*[›.ô¦Í|6sªì-x¦ˆ CË¿o?-‹ãNqpÂAÜDax?æğh‹R­Äîúôê»  YÊC,ó+”¢¦EìyoàÜ~i²x‘Y|¤à¸·”÷zNdíe’ÀRœ!İo»'1l¥È$Gü¼çn#…PÁíÿŸO.Ôœ&4®*#‡“}¤'¼Ø$˜òéûÏFÒÌXÛ•²g=5ÒC D’Î¾`lK2B‡øõŒòçê–J¿cupih—EóATådß%•İÕ’òÅí1k–†X¯n¤ÚCl¹7OAB@İ™½SúÇª“:ƒ•3(³ƒIC~MåeçBŞ•E‘sCÜ2´;ƒáL¡®kîÈ/.¦}r3×2"•Èôv4#ï¬¡è½+£‚Jjœª3YwXØv-š"}ğOŞ\½Ôg¼oßCxr¡h8$âúQI<>Äªy¼	2K¬À“~)C©¦Fòôs‡ùÄt¯Û1-FOMFíá³ŒÃ‹ø£AørT*bzäº5èÉ_‹4¤¦ÅûVïÉ½¹ùäV¾_\;ë×Kr³*)ëzqùóôa„B¿Ğe_ò˜e•·g.æ’lÜ§¦ìœú~ŸûÉ¥65%¸`o<­MşÄ—H¬nÊyõ”¢IîXvr¨¢ cô5Ö§Im:S˜§FËÈy“{´ãÇ[9ÒÂŞÙZn5Ä ø6‘("^ÙÃZÚí|“Ò1#ú:*Ùà=³üv^B3#ÉÒ
‡/® ˆ€¤½îÀ…‰<™¹ıwÊ~ğS„k!´³'VáŠï8•­·Z>À=+f8èÊõö=ìL*5¿£¾ IøS&÷#’eˆÿÑ¯©°õÈ
õo¾Í0Å9cÏu”=¨*á<ß2ìşÕrFº$±bšşuôüWû©¼á­óë.s>»RX$úEuA—6¿7šÄ„_>Î÷yî6°QHt"ªÃÊcÉ£Rcø¤3ÓĞXé(ê$v*ÛÁ?œufIP.RfåpZ7{a…°Dq®ÿ–¡Ã1n*f¿4§êo¥¢¼—k¹äJTh¸ù>œWòÚRdè©0Qy=ëÎ‹øRTñ3˜Æ­n*Yå…w†{LÅÖYôxŸEûEXã2„Ş÷_ˆú¥¼9líÈ-Œ6t•­´Š¬ÄŒ¡Ë1'ä²²º­¯Éâ@fC™ ¯wD×—…K£“‘@6|ïöÚ¾ñK.›í&l'‡Èaâ:Ğ„æ¬ßÕDk¢—»ß¤‘»Bo„hBJü8¾œ»»–~ù¬J¬Dc}Å–IİÉYÅ“F{úF"X’nä-wlİ¶G„l¿HSĞ9§íÇê'ˆÜÓ"#8ûâıÎr
Øù¢ÁVüOƒ:á×c™5“º	#lF%ÄÌrT¼ö7£¹‚ß&ÊB1ºí [’uıŒ[ C¬ØLÖ\b”!Â"†2c0ü®—*Nö}r2ßšµøè‰‚v($C&Ú=Ä^4İ¡Ê5*³ìäv%iXhúÚœÅŸfø¨½aH
àzèï¸À´‡x´ƒ:İ:ı3˜ÿ5	<%tóÙ!Ğ™½Ó*ıœuøÇ â›_›Ü=ífRÏGT#5œázWµ“‰ 3«¤ÛlhíñLØ§gÄoç%ÔX±:t-bÑÇl®ˆLZâ§À ïĞ& HG"Ì:¼P­ó^èZ#•6 V¥–å…í=p€GKwwyF2U·í{,°L¨6éCÀ†çš‚Ó¹Ü¶a·÷‰¥ÈéR¹‡¼ßg>Œà0X4!ÔSZK´VfD$b1Hd4èñ+ë/¢€×_æš4lKÒ pñj2†>lõ#ÛnciŠyÆõ† '¤cTÉEŒw‰ÛeŞ~ÚìbÑREz1¿Œğx8@­<èS¦ÆÌC³PO Á<Ô*(aÇ8
za[Ï·õ^f;wtÄ¸zEzÆÿ~rcø"NşbˆÚ·Òš2¡gÎoà¶ ¼Úà-$¡æ£¯\¢İ‚	R­?	'û¸{ááÕµ;qR¨t×Æ{yĞ¯$şìÑ¡‹Œ£¥—ûpX`ò‚Ì¤ÔÍjzÌ•Áÿ«8úuÉÁÓUu}úß‚ÖSSiû?;¸ ö˜
¯î&ã778Ä//J×ÎƒG…"şq\Dƒ·yÌÂ‡USÉ]‘TIHœŸ‹Ñ,Dôû”'ïª!psÁ|
åuï’ZÏ™W¶QNúA=ûÂÎ;ü}d$sÉ&¶xÔÂ\¬®ò6èãæ£O¹¦¼q“fµŸT—»tÆ“Â¯áŒVo/—uŠŸ3F˜:.…¯1V_YqºÓ'œP½½C\7cæŞü³·àìŠ“9Ûú 
8XçÂÅ’®*¸uypœOö[\€¸™¯xèq°ëÑ¦À–§LX^İ¬›"H¾ù°©²Gˆ×$õÓùù<Í­	qÍõb[_c¦y²6[c&A{Üà?7¨¤„C’]¿J…åZÍYš¡E“ºZŠÀ&øcÒòÔê&{}%n–-ëTcºÆô„q\ ábçb}z|P_ø 2*)åSŒ`İõ‚2@Q3I¥˜:÷³%.;ØJ(|¬ÅË	ì]¬Nzcë¿+Ô,ìúĞá…ª»·æiNV¶¹"j6K§7OáQr¤ÌNc½ÊÅ‚M®¤ı2=ˆyª”®¢0 Ak<WyÍİvû/ŒšLôÜöp}=LæMCzÈøÏ½ÛL4l B~¦¹³À”€Jîgy"ëFèİJÂã?~Zı-²P[+„&Õ›Ëû‘ø) ¢TÖ´ı*SŞ¿…üšéHW7ü.{N™Äpécüp»µúı}$¿‰ìÓlc9]b’Î¼»ßT&´ğ+Wµ<–Ôvƒ ao³´’—¥¼²]*Ú2#ÛcúQ	¨òÙ‚ğ	Æ”)fLºú30m‡v‚¯¥“êÀ-ôÚ{åöÕ¾ÅG÷µ†±­ÈÌ[RûòÔUéÌ(ÆÙ5î…KÒ²˜OHMõ®-[7óHqtĞÍáƒæ.«²£˜ki]Ó'ÙîBöi	–Dšiê0ohX“…æ¥
ĞRD !Ë‰àèÜkŠãç˜Ì…¼"š¶ÎbR»Y/´¯ r(ãÀÁò¾´UeñğãØ¥z‡3§NX
F³¯ğ–53´\ØV‘âMBäylSY¿5"_ßÜÕ<p PcÊnÒµ;<r¹Õğ…dºšuGIL)BB³OA}ù vÁ¾Î„Ğ$"quá4ı»Mî9i>´mìJUé®Äò?‡ò*£vJ^İ&È=ù³}—ûÎJM×aªä[wWGº2/Œ¾Ùwİ»Ç-'§@½"2GWø·l!»¦¬®&ÊBÊ˜ÚøšÇÚ¢«¥èmaUË<d•úŞ€fS²ï†Ï,Îß8œ®$ÅÅĞáÃ“>;fº-“•9P·`!½qFOmST4-b·…2›Íö)x§V–³¦*~Ùnºí Uí=ø´|Ï;ï¶Vj*mk‚ò£y»‹v˜e™l¸X^Ë QYWaõ¨…‚ÙZ*«w¬^*Ğ›ké‡»T¼e¾*»2ÅßâÍ+ Pí´ú+*ûÓtnúËøN¦L*1}Uíö8)•v	gÙhéÕnßÇ¿j¶€(5l¢j@Tûª`7Ô|ä¯	ÒŞ÷À(
Šı»œ«šy0ÈşÀ­w(‡V'Éw,r,Dx2F`ˆ(ÕH‚*ªm-õíb(&pÌ»84²Zøù‘ƒ8êŸŠKÔ±-3ÙƒĞÔZ±NRdŸâhŸğ´–©‰+µÁL0´	<q©9áĞ@¢ñåB6ƒÚn0ÚZÂEclnïRÂr{Û¿ÜyXéa^Â}¥D^"oì°/ç<À6NÚR”tàÅ—i pšYÇKLI œjtÙ«Ÿe³jk>>Ø£€§bˆôÃ£–ù†Ï>7Ø€­(%c—9O’+UÅò¦1<.ß¹:»“ÑÿÒæ¬Õÿ-­‚ŞÕÑûJ“ÀŸ°Øu»jS°Îb–?û/„×¼–Mk¾ìxÙç <íªİuÛ²0P‘½¶Qó$ÜïÜ“A¾•_låãD«î;Ò§í"&;DM(=î*¨2¦Äe÷8Úz<óÂI1¥›åèw}`~î^F+YĞñ¸ÓˆQ¡_/·Š«EâQ6ÊÍ`Æ•íY$(‹”ì—¼$-¨‹œh;hkŸëW,3TÂH+áÛ1c ãjÇª¬(DÎjû¨tÖA¶­?ªßdº Ë¼¶^İŠ'6gdÅÍÉqœ÷óš%h¬ó
û¿n´väyæªî°[š¡ùrÍl $·ƒŞvŠ9$í¸»5@¼ÔÖS…½İ"Ëº³‹-$x¹õI–úhCÆ¨¢©½h;•XÀ€…†´öh¸ûÉ
9L&W—ŠôÜÄ$'ßrİí¹·S³Óg¿,¸?!†|s–Ğl•ı è 1İ;—å˜_Ù{•Siˆğ{(ã:#h¶·«oš£ÆE¨üÄ*[7oâCGÚNyÔ$*…ÙCøu3IŠÆrßßUÅµnJìŸ«Â˜ÌÄ(LbO7~Vıò5-b ™Ótdõïqå êfĞÒZ©›Œêô´ıäŒ«—–ğ5±Nš ‰\zôDÿr99NofR†İ}#“ùŞÊßœ³«G"&|M	äIˆç·ëİíu{È´/Ğyùw¿Ì¨å	;5©â™\Éû~tÂåQ”¸İpİ&g£SzĞFååı0~ İÁÎ®äw¸2ø‡
G»K"uR§„[˜C¢=Ÿ¦Eô`Ó¬²JRŠÚ6X7sRUÊ†Âsô¹Â!z˜1±Œô;A€©R'à´Í›SXÎİšùKÓßñªøìº)2Â–6¨¨E ‹æ*-­Ùmü…çèóÜBîÉö«™´èÄu„ºd¹(h±ÆtÙ¢Fpíak¬uï³üß åÆRÍŞÁ›Ñ™16p 3KEH<¸íì¸ï]5Ù=Wí!zÛ×f­ë ¼g#[ynÄàt ¹õL)Ù¿†#?Æ•ÑNRp­Æºôî¥fú"¸h)ó0ÀÃItgÄ[·Ô+ÊñØ>ÚƒFg>9 €¼vğOTÓŒ”wÈ8¿	Gks¹WŠ;åtK+úÿ¡³18óÈº7›-*X :ó ÇâüP¼RŸøÂomºãL¨Äênz|5ö¢¯òñ Gı¦ş;‘LSO¨2(o àoî©±³%HñÄ=y”ÉÊÑÍ,èö·†ÙŸéÄi‡ÔÜTÊgˆÚ ©¢ï¥~§‰á<_Kû“ÑwZQj‹{õ˜9:•Ó‚g±oğ 5¤—./V@“F`ÄÕ~ ”²Ò†øŸ9Æ¯š¡×½;‰-ê¶…—mHS8ò¸/ÏüN³ğŒE’‡Š†¸ˆ¸Ë4Üq,sà‡++N°«®3ñçt5SwYŞş³\>MhÅLĞz1ôU{ú½Àšñò=bÂ#ÕÜZA†"™{/1ÙGÌrü“? )Q{cÜk¶<ˆú|i"8ÍÔŞŸ`»è„ùJİ¯ zm<u€äbVÊOrŒµ?wßëûº´=ƒ‹Zÿ¹Ì]ûçàÒ?Ú2§Zõ;åÄúálv`ºÊ ë‹íãwY;=ÙoäåŸ}×B»©‹P´,¡§›ï'¤:“ñ¿ÈğsÅ3Ñº|¦¾OHQ—&Şgèé‡W íïœ‘ùwÍ`´Âjí&FÀSm&Ê¹­xh/_—q¥¯—2Qšh1»7À`ÙªçÔ,(A!°ö†o’V:—ÃÈÂzL4Ú|)::tşÓ"¼ËôïëBLT-†4®´¡İDóDzn†d³-«ƒ ëıèR‰ê‘^npÂ·x&Š®K¦–ğKhÖ¨X™c,bÃ°4‰N©.Úb7È«Sñ-lİÙJ–©ı£’=ô)ïÇO¼rß\b¬Tİ IcQÖ\¯Äu9èk‹Y!›öuYüA°º×Ûø©…mîÃ—Ø+ıß6Ÿ×$m´ÛªW•XáºgB
’ÜVâ.ıh ª%T+YQå{y”ÏÄIb¬üôßªƒøˆ·XÓ¬Hë:ºçwß’TéYŒ@äoæZãÍ\?	Ò!"ø8›ı­,Ên>¿¿á‚˜+É6—-À$r¸â}J|$µöïHZÓÖy©¿M§Ñ-A°©OE³£jµ?}~6´´Úö"0ZÆñ±İ® ÷Ëï¥'PÓ°§ñ	-ØJ,Q½¹&î¿-Ö®a=ØZÛqó„ÚŸ-á³Éïî³2W};÷¡Ç‘o:´Ê!œ©CûKFùv'Á¥şß¦´,©µ‰Jo"–cf‚ËKb¬X² múœ§ÜÀ@"E¾Âëp %œ–(ë¦g
¹ÜÚ¥o>7V$ÃçrJ>ÅÊ­ èC ˆÌ‘ÛØ©.?óÎ#…ä|j%yä>Ãäàùîy‹^ÿäZİˆ÷øAAÆ=°À3*àTŸ:ye¢{DßhÌ0	³M{PLd½mòKƒ “¢B†ZDãÙLÇláC Ğ½¥‚fŸs»ZSîÔ›%“§?mÛ~ÔGeønÈ­6)©–™ÇÔ’aÄ8¶õöã%‹öYøõ¥†ı]–Yîªÿ•îdƒŸÆØÇ¢õĞKRE‘‹llèóEY?¢Ğ%éß'JÀÏéMÌ%ÜMJõÅßİ?!«ğèÖ¬=^ådˆÑÍ”FéÁÂ}¬ª‰YÖñbÉîª3’”¤.&ÖÿµN¾ˆ0úgÇJŸ{'ÒR…râoúÙº:ZeZ¼wŠ½P™Áïei´Çv—€óa¢âÔĞÊÖÓ$ïÉË½0”1ÊÕGôÅˆ5”ŠÉ-zÆI¶Âz^h±tRáÕ|Ô•*
\~¨‡²L9©¼ê¼29ì'E±ii– ‡º¢>¨ZI,kŠ\A!_?7·XE<$½¾V<½»¸œ»Sr¸¼Ëùïáæ–“‰Ò4šé­œy5às¿ãŠK•ÆÔ»é8"Ò7ÇÕÎdÊ® °îú9n’±o PÁ{‚<Ôø„@‰wûe$ão­Y02ÀWE._»Ù–¬ŞE/ˆôÉL‰jÈŠŠD7QH‹Êìde0%IRK¸œ“ÉQ}ğ:>~+0oÍm5SaÛ¢‹ˆ²|1İTÓò~R/sÔ§ÂÇˆ ‘—§øÙ†ñŞ&İ«üê&|á¬Ä?èĞõ¯¶çR 3Ü"•£q2-È%òÁªñáDÂàjhZA7¦òŠÿ¦€ßİq¶}y±qİÇd‚¨×øªÊÛ'X¤”¢1¶™w<¬O€eêúÉ 5¬:ËP™EÊ[xí0_® ‹7¡í³jf¡}+Iˆ³Õi³Q›K¸ïÈ­3—‡’>y ¡*ëª.»Ô˜G–W”;gz¦‚(üü»E)Çód9NÅ
tù¾ùoË$ |w{ö×”éVæO«k6Ô;´Ş¶XA§«HÕ±kéĞ¨ÈÒÀÑïdÀØ’EX ‹‡ LôWì
ú ‘5/F½Ï¯29Íz™Ÿ–Nü×mp”fó`øœ• D0FŞƒÕâü£àbšé©ëÂ'`è)‰CµË}6{>æà%\3g<úªµ»ÛdÄÓôR.Â›v0”Û<Hcm8ğX>Ú,UH½3ûo›ûŒ[p	†6®mSNÀ{
sîğ6L V}>W’®1Âéšà].ñU…),ÿS«162×åÒEfÔÊı¸çÊQÏ–‡9£‚Ïh‡-ª«SDÌ½V&}No,‹õ÷17¢÷?5Û±¢fÇP¬NwÔ'‰Àdä2òp¼£Yî¢s‚ÌU;gÏrv£™©†åÂÊE8ÍÆz€ÌÆÃ
Ò¡åx
Ic0îêu‘312Å{&|°w¨Ù[]úâŠõ]¥½-an¹Sí¢î“P\¤IåŠíôÃÔmîŒéF†O’lKS—KÖçs­Pï ëÿ”´‚é-âÕ²íÎ¦>×ÉŠª…h1º°œÙh?‡’I•ŠRr;®;Bß¨Â;ŒùûBĞºC–Cú¤Æãğ|úáT²²ZZY…|Œya`_JpmS‡ãj!½o,÷¼]›‡áàî{Š©/_?÷2ÑG>gp(;û¨Ö]ûa´¯µ7%Ü3ğHÁo]ĞÕJ±¿8±¬¢ú¤h®¿Ò±rn*UG)Áy‹@ñ±ôÙÕÆ7(»Ø„ÉgÒ÷Zß ´.GQ”o]4ÑRD÷;hŠç±ÆY àe,Ï†¼—2IÜ´±ÇÄÖŸ# U˜8GëğU•k…¾‹ö÷w€93á~å/¸}{‹-íåÙh[ `”äF„&)	+€Ù¹WzÚø¯8&]Ã³»!¯¦r_ºÆaš6hŠ*€Dbmòk9U‹„±İ]İa9ãÚ›ÜCJåy8h¿IßA:cqgwI)èë±bŒ¤V\N¼w*ÏøïŒmœûƒÊ­å‹˜-·&…µŠ±ÿ£jPth•y«*×y“àãa®¢™ì¾®.Í_"Ù¤‘ˆg+
n`»x+İsÑ±÷™ı% ™ti@ùT Å|kS´–ÏYgÕã7N±ONŞ&­-C)¹‡ªĞb-Ìqßº"
'8^•ïë¨¿ƒƒÂÜ»“|»¦œİÎIù¹>ÏpvİR©í~ÂA5`ÖsÊ!¹Ás˜RÓwuÈZÔ|^Xe;³­ÚBø†®ğî-^µĞ:ÓšD°·¨²½¬´´VÊE9ªëÖ¢JD}p> s‹–±ó {å”»j·Ç­*¡ä˜Is¾{å¾T¡“âº¶Àaæ T
‚t,€~Mğ¸3—nC0nûôšNÆùG²ªaıÒ±S¨rÇDª
>½¼”Ú£è*W‹¹å$t¤Å$3éà“Ò’øã~‡ĞÕìİæññÁn\°¹¥•bR„wê´NŸUXÎÕ­©ü9}«ÜË‘>öÏà®ëùR•IzDßñ<©5³+¹I¥®!Î–	š3$R¬@]7BÃµÔ÷Æş­®üÔé˜³8‚j¬Ÿ Ô) oûwìûA·’ıHR’àh¡Uæ™A*<¶™ˆJAûÏ\úÓ‰:z‹³%uİ)Ÿ‹ÏCÅf’©e&ÎXBÑèÑë-÷S4CÃŒÓ\™%«´;ÉÿÅ—ù&æ?˜ÇæÈœÊq“÷dÙLÆh‘P±D²èTPÍò±eyâZò[ö­fğõæÒä›×-KT™èÔ†¯%
-V”R;íò¬$xä8-Ô`ø/ĞsU1dm’ƒ@ZŞS¾ %,~å‡ İ3.×¦yÆ,ÊÇ_htªABÁÎ¢lIÒNË‹Õ\4îÆ»¯%cş^ç:5PÃãYEÁë5d¥$=ÁÎY|ägÖô¦Ù{~pÏ©VŠ§Pı/İÚ«ÇúŠî+`.ÿš r˜2j‡«DõY±ş¤¤JµÌ&ŸæÉ‹"ë£‰¨ïã¼ôÅ‹T2‚‰f|ûÍ R½zúû	ÒÄØ[
•*«¹Ä_}b›•9ŸŠ7ò¬ÎÊ¯OİÄ>»ÉÔ¦ÌÄÿ«ÏŞÜøÙ ¤Ø­…²ÀÀGN'dôz!lp-×SØııBoØœ…¬úÍŸ×Sõ=Ueµô÷	FˆØL÷¦Š®]_mZ4ûüûfºùk—‹ÑóTUëèÁ=Á¦çÿİ¶j1GëÔşõUpõk3ÁÿuÈõ~‡ú€`¼àr"şwÀ˜-=~Û—¼×>i{õ‹áí[hwÌ|¶ÿÊ}¨TÓJ€?&ÛçJ8õãNÃÈ}a{:i³ŸØä¡±÷·ø¶4XW ©‰Ç°ïšò/3uŒ“D¦ a%m·êPq"r\·nû/åŠ”c’¸V9Ñœ›Ñ§$†ÇedtGi×q¤ÚèH&x<f¬'—‘±Fê'rõ±ü *8-Çœæ@¿ÙæJİf@dÂ~ñ¼ œ—
›'I–û¡,GEŒ´¤ru‘ŞÉ¯ÄUÌFbÍÔÁLBÄ`¢ëï0Ì{ÕöQ†Á¥ŸÃ½?'\~×M6hrlß™îæçoŒOfuÖzÓv€s°à[¿\at’)“4`“Ç±şVÔhÅ+ù ÜâRgŒÑ‹Š}¦Kõ¬°“qŠä¨W´ÿÛ…V‹É®±¹ğÊpMe„Fäà»5ú…hÃ+å©è³^÷ÓNªH):"!%UA-ôl`9ıYÎ–¯æNÊ®->bJ`äEŸ—,¯ÖØÊ€Y(Ó<¡†^6åYŞËE]àİ.Ä&~e]Ànaü¦“µÂ&6uëF€A2Î-j™Q^ÖğÜxfJ‰ôûƒ ¼áX!ç¶lûßÂ‰è“álYDÄYÙ3hP3ĞsôíÒÃ´kv’X,@Æ+BÙroGz"P‚NÃ)@)a%}N?ˆhöÃv×	o1ğ”B˜_T¨ë,ñW ‰Éè0¥•4ÌËP™ãšc°†$Ê‚`²éæònlXŞ@èCp°ÍG~-¦½ç³Q¡V6	„o->#~¾U eÔ•nÔ–!@JMëÕ+ó¾¿×Ó‚0ÀÙR"’åÄÕ	ÂäŒd´*;=•Zö>yĞ¾L/FŒõ:ãXêŠp›·‹;—}3“ìb› x8²!1t|û0ëëˆŸõïµvÚr^æ÷èùI¯^c
Ç'Q·¼uJõ¸ˆ¯ßĞú|E$–¸ˆµ·½Ö
ˆle¬Ó/j»^áÓ–<Ó¡cX{‚1It=÷ÉƒÙw_e¬ÑR:ı0‹;Ëi›ºÆA†öéá „é~ÑÆùDÉ‚Vµ+VfÌv[õVòĞsj¨¹« ˜õTNkz|‘ä ›dä2èBOüÃêÃ`’ƒ
VÅ(ø/züuY®ì‡ÕhiÂ‘9ËyãD~0h]_ÈŞ
~:—Dİ…f‹ë°>È ê§œ´qmÃ*Ù‹§}2`pÇìaV#]İ#/€ä…ÈÛÏOÙ¡†³upáËq%YŒˆJòŒúú)™"½qÄ¿F|Í–Ùó§WâèUlŒğíÔu¼Íıû²Yé/œ\ç±ÍÀaÛ¨0\” ¾R¬D$<õ¯¼î0j"àìB>ö{P8Øï>×¡U”!€TÃ«ë–Í/¦å5ŞæºÎ5éıÔ÷sğ)ıÍóî<0,Wü
aü´ú+_…µÚa·y˜>?ÑöæËÈ“„£ƒçÀî?Œ6+÷º•äÚf0‡t9ç%½ó»Ï¯p¬×+ N§9WG’Øc‰£ÃÃãRŠğÇ6e€0œõØ–UÎ"•T¦şµø	;ï
ä_à‚ı³E…‘Õ†tsh¯±Ãâ‰ÛVQcë”,Ÿ"ó|åÈñ"";½´ííÅ6Ú1-I¢¡Ó›çœ:`£V
á.\ô³1elp’²˜JQƒg¢ï:*<ãû¸¾ş-ø#7¸‰D¤’Aº{Æ¡ş<^@°‡ŞíCº~“Ùc…§ooÚ ½SgœoFÔ^œD—8ì±Í¾EPŸm®î+Æ•Ãìí”Ù&.ŠÄ¢¨ïÒ?ŞQƒé5¶¡ı©t²÷ˆ9”êèpâ³X/Æàáí*¸¸Ÿk±ºâ0ëtÎEOSC¼]ÕÒéû|ÜÍµÖÅ×„ê­ÖÙÕ“T´øşóº@—x‰nó…eşıöM2î;Ÿâ‘ê8}‚éëú½âõY’`²ÅM++*™·< ÄaTÇšºîP_á‹Î(zİìön×Öì¾êNŸê@zO-½ä.=`u>ø‡®ñûmA™tVö©ƒü1eê¥º ­¢FÓõ
ZôZšÇË#Cû°%	†:¶°ÿ‚†ËŠØ8gú8o|åp†úÁ 1-‹\ åpÒ“3Áû¯\1 öÀŞxìôühÌÁ5A©ú$Ùóv*€ÎğŒàŠ›WnÒWãQX.'
îz%ı	›0í#ÛZ¤æÍdG™x«‹”t¼Z7|zu¼ŸNë­©Šåí({á[¨ŸtIöígêøC‘´:NW‰ÄHú\•HAí&İêwş¬¥"›ÈÊ{Şİ˜ÆzKÙ¯º:X
½±öÖe‚¬NÑ8ç«h=ïµ5GZù>T†;õcôüê9	fÍ¥¿İØ!$_CvùÈù¹ø¼$=	DË;¢Í #ÎTà‚,1¢´Fê6cL¦à¨byïiRsşóè³:É¹²T±sÉm§ë™‡Äşï:Ñˆ‚X)¼œ\„®87	,éé£)¶BlŒ	B’¶¯Kø`\ÕúÇ·[T˜ÕìÊ|°†aE Æ#„ ¨1—«p¨ÈE‚”Z²Ñ²ähCFH"/¢N­­¨ÕwQ`Şè±"ÜêWJŸÙê€œİ’î\e¥æó&•f©s'½İÌnR–Nl­sò:o#ù	—A¾¨"Ÿds>ş*.pd@OØÜœ^‚W¤¨¹¦#UvH«Ôë%Ú>¨¹+MÜ``ŠÀ'ÏÆ¹´˜n
Èä{™ö€Öü—ŒštLÖø¦jHÃwpÅ}xl¹^¡1an*ÁµdRÈÕ c-†	ßÑš÷*+7X#ŠË´ï-Ìd‘¹‰„/*ß	¨á£´'wÖhÊä¨—¼Ò’!˜wóeÃŞá"FK-µÓ«)ÕÏûJ°I”n¦t&¢¦˜bÔr„°ÖhÔÜƒ¿cØÓ*¾5üĞÈÕ05K¡€`=e”_|¬õ¢–}eä¬ÿ}%Ds’ãÕUY…Wù¨Ö‹áÓ¯°âafÀÌÍù5eQjO€ôKÙDİj6	ÂEsI–”«UÖß ¿3i€lñv,‡ëw"Ü]nR¹ k`†@ù<™¤ÈœílJeNŞ¿§Ü'ÀüXzã¿Ú¥MÏ=ş³âg(Oy:€&‚ğëq9†N½Cv6<$…±‘AfgÇÙ¶åÏ~óƒÍŸ¤¿İp<ˆ²¥e,ş¦R°PeıÓ4$ÊOêª /¡‡PhŠã™œ¬)‡­Nàš2J-x<tìİ{Ô ²7hKÎ¬nµÑóİUeCÄÌä¿›$ÛµÌ‘,ñö­ƒÂ¿Î¡c¾û<j)
Â7
'İ¯ÓĞ3nƒã”Ù’ğÛaúÓ8`µ^ŠşÌ.ãuÆçŸTÉ| ˜ñÎä•æÅ¾Ä3Ö²ÜC­‰Å’Q‘ı¨ÌúAq/5á8A©vF
M9ù£ÇÖIp«:×®ªù+
ıbV¢²Us…H~h\`û®ªØän.oc~µa-dvCİ<²×vÊ”ŸŠô[¶ø²º5ß!ıøĞ~¤ÂzİÕCÇÊ)èq}”Î:EÁ©Ş#/b\{¼—6-å£Ù¤2'Daá¯Ş'Ç×`æ¸fiŸ6$@,u¢«ò¿=š›õÒ²Ğh›}â–.úZŸpEÄüû•à bó(»6˜R~°ç¥l’ïle&]¦¯BJ[«‚™ ÅÆ…(“ÃÁn•1
ˆfi×è½ı`‚tû•9ÂY»P„J-z7&„´×|i~J˜ÁbãÈÏ½Úsê\5šÌ®>z(S%ÛD®`Fìñ'mÔ èõœ÷ÏĞ‘Mè4
šß	ƒòòN8â _Ğ&.?‚	9Bª;­Šñ&äıĞ3}ÃÖâs˜H_3üu„É‚ 41Í‘DÓ¡ã}¡ÓŒˆ0*ÍXºún]|×5ÿáËZ˜§©Æö–6OÃÌ±›h1©À²kXÏ'8ö”¸5âfL~ÅX£o€Wj¹nUî÷ğái™áâ=%/å4»_é/l5ñCÇ‘Q8¦Ç×âm¤å aèÆXçJÍğªÈdĞãÚ>ÒŠe]Rg¸ÀmÌÖVé¿‰yl‘îÜq‘â¬	GÂ&”&=`å[wBŒã}ÜdæW‹›İFótÁ‰GIáúø!~ıá’Úßš¥êşS'öÕ] {¡½ÑP¦{QCAßˆûÙU‡oó™’zíÕ+½W—Â^Œ¨ùÊ„u¥=›Š_ÌÁäê„ƒÈ‹N¯°pNsj©¼`zúlÃéw_Ò>rõ^RõÜ8ÌSÛÓŠ´ÿá»¡ÛÏÃ’ê;–6‰V{©UtB1HøjB¤5TÉÕİ3z0êäğÈ‹Èï_åŠ=òŠèº˜7gùtœwP–¹äõñ0xº$- ûE{JrçÿEğwNØóûš2Ôë÷ÃºÓ¶ü%ÎßóÆ uºİG˜= °å;:ü
jw„.p½è²ôdô{1H‡#³›âª 71ò*ï+´•`ËÒ2&˜İ m}hu—Íü½h ^¤8v/Q?v½gj¼Óq^T4®jé˜\™ô“.ò®ØµCŞ^£±Ùæ0Ò
–Üî$¼2@+BĞúıª#h4^ˆ¾mÕ
™nLø¤²xÅÜqóûé}Y	ìä³7ëÛécÏªã¾*€\ë.TÕ#ÃÓS1B†éß¢ˆõ–mÇZHõŠ|>“öZ¹l›Fá^¦Ã5(ÓÚ­ñ¾šˆ³;hé*Cµs “ÅTxÌ® Å{mÏb!şÍ¡ulßÔ€Í@%
ÄñÌl9ø÷o	&\–Tğ#Ü^D…€¨¬QP…A*²·<¤M[˜ö™¿¦öEœİ§èäïA=›4q §êç•ü«`$;¬I«’×Í&Íçp÷§¦—Ğ<Axñ'æ>€‚\¹/İÀÕ†;¼É~ãŠŸµB3/¦e×­Ã—h‚Õ“@,È¾ñ]4ù¨¯yÛ{ğê…a.ÙëŠş˜Ò5Ÿ!¸«T@ïÙ“:rÜî‘ÓØ°©–WÖ´½N€h–¾o³3)Ù¸šœ¿DL—«Å^àöÏ y*›KÒç=|”,Çâƒ6³§¡…1Gİl Š2MÄ°­Ë°êo,/ÄÆ“§T:#w‘ú(³°º(´äéISíÖFL(ŠpâmÖºÒ”¤^¿lÏD/ÑoD”õ©¦d¥P{1‚Â—£DÁ/”hü
Ô·É,€ÛLÛˆ[»~  õhÒ?÷â6İKZØİ¦Á¨oIê‘ÿ9Œõ”Ñ
(bèŠ<¨AÍ	}Ï\â L	.‡WˆW¸ëç ã#€ÔÔÍ=a0$lp˜soL.wàb2?ƒıæŠòeh%lÆ®FÊ®y‚¨9Ì&y™û÷µ)Ş3ñÒZ›”Ú£\ôÒİ¿##M@øBK¡×âˆKôzemîêä¸Û7@7ŞÈ‰8£ój‰90ñ£¤^}e°ªO‘Z4 ûL–Ğ•ˆÙÑ78É
W˜ˆÌX‚YÑ8bBù\kKnQ¶~Š5›Dúüìâ&MsŞÿß_pş&ëÂxıìeVG1r,„¥Óƒ™(@ï(ˆTÀ‘ê´˜tÌYğ1bó8°a4€æ*ÓQÜ8ùĞÊ±#2Ïm6¢äSõI” ¯±°˜úÏ” ³‹0²U01äÎßzõ'xb2º!}Ç†¦ÒÊÃRœ‘‡p«]•‰Ä
ËeZ‘ £^•ñ‚:j¦mn5è‚Ë¥&u%RW¨óEp¢"#ø¹èrhÅces AÈ¶ÿÖõË?&QdæĞ„©…ÍF°›Ëp_8×ÕR
4	²dÅÊ»±@T$õ„~W¯r*°nĞ³ÑLemà}5k ÓÅ´o³¦Ü3H=6zqç°I³ºIØ![ı|¦‘ò¡°Q‹¾paéÔÆ0•¤xßZZ7ÉßÜÔŸ·Hh¬Ğı=êEtÌï[k‚ŞüwÛSô”ŒšÓ<ìóÚÿÈ™Réšs´®æèûg9(¢€¸İÕ6!³õC@h«äcl‡xï#DSÇ«h?å©›ÔÓÃô=%\tÑX€ri(ñDàõÉÉf0_€Ğ2åFï°ì¯í0‘ºŒ¿ûËG¢ViVìõQdÑˆ’C;!VR‹?g4‰)Cìàrã…ÚÇúQööNºdÕŠøÉ{ ;*g6½Â__Øã¡:õ ¶üH"Cùè¢eN×ñŠö\Ø•ßEûãôæ{¶Ÿ8£ã1¢Ù[®"!MfŒóWï¡OöFŞ$2îåjUdŒ¡—ıé,EN#œÎR(
·aAÜ‡Å¸ªKÓ®Ã‹¦mfÕ%ûm b¢°ÖÍ¯Š/ãD„õ½:0`foª‡‰…õ	]´¸óññ7”0Öd`´mñ›Vìì¼©iÙ—¥šBñs^š•;4Ícßsïê	›QºBŠX“–Ÿ]7vB›ßY$cj¤-4 aÃKvVÀT'ó–«%ôîXGÃÒ;zJ;–ºÃ`,v×ª?®"ÏäÿÕğ]=êÑ\Ót5@ŒDJC¤Í_ÔíX<PeSô1ùWynÒİT»¼;gÓÌ´–»!(À‘Óâ?ÙJúöÏ>úÍ«ö´O„?5Oğs‹æÒ>h´IŠ3–™ëklû_¦ÕhÑ.ãˆhÉ°®7ğÅÅ…pysğc”†;2èEÅÆáñ‡aÿÉ\.uĞ‘Õ¶ÁÊü[;èå)¹$NdG˜Ğ–t¤]QºÆï£=Î§"ÄqĞù>läàáö5ãıE!Ø1ÀâI4Lú	\PïÊ=ğ&MBoÖ»“ê›Ó²ìMåYñ$›_É­ú;¡y¶…uÕ0íê­ì®Ï8î;„ë·ãŒM#˜²Ç»bøı”½ÿw<æÃéaË=“ÖG‰qøá—‰ÒÏ} ³‚(˜‡F„•\ªX&È^ú–äk7g&÷JWÂJ»ºeûûOõTê…Ê:–¶ H %^–ğ[y´×i9¯î=?RßY	^»
kØÚ_¬†ÓF-e,s:Z3–¤ıí¹P,ñNìé• ıÌ}ò;£­°Q²mø§y$†ÂI*jf”AèÈ†áhÇì­[ È{˜êòâHµˆ÷kÌ¶gC¤ å¦.”¶¯VNšğ]:<9¿qÌ9¯hÙš·Çkèà`k&™êL†Lì èuHëœ¨›©.2Ÿ.a²úè5(-§/|L#ádL^"§(j‘)S‹eY 3š¾áÿG‡-NÀämŒë¼7å-ıwA¶.¾q²O¦ˆê³œ›fSBoŸ-ÕqZ
×W*ß§_T7kşÅ5²VF¢A&NÏ’LÏò:î0e—Ğ¥iI*Â’@÷†ÉºiÄ)ô«ò £wb(1
Gw0+Ö–_’àº>{BØ›2Œ;‚otøN±¹[ìN™Æ…ÇqĞüÌ†b¾WAÒÒ´®gŠåG9ôË
Qs™d>Xë<±˜¹tªÆŞ8zu×ÓhúXíæ»”+´,%ÂìÓ&ª1Ë,•±«Û%ƒÃ¢ZzûóI§}?utæA‚tŒj²ÔKJ«‰"¸¥NÖ`¤éÜIY~,ØVXb£uD*|Š‰äÂuıíôA§-¼Ó28çäKiRsÊ‚zo©!§øuyÍişÍŞ™1eNÑ¥]ç]o6ŸƒrÉ‚ñ&˜d%âKf¡²Ş…šÿ2u9£È‰u€‚Q§ w¡3ákÁãDşı©‚ÏËO4ëj'Ò=ùPã,¹wƒ+{è€óp›ÿÑSÖtY˜lğ‚q4eS,‡­¦Ä¶W1~ô{F­vn×:A-´Wf-cC’Ğ   ï¢ö`oh« ¾¡€ Çu?°±Ägû    YZ