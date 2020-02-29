#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4224347370"
MD5="fd48117833f5d82d5e1584e58a729a63"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20584"
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
	echo Date of packaging: Sat Feb 29 01:27:57 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿP(] ¼}•ÀJFœÄÿ.»á_j¨Ù v§ó^íîš{}A¯¶¢nFNÛ®Î¤‚¡ğ!lIæ[¡Ç¨õ™]IÈèıu[›,Q@ºr§Ÿæò,Iı~ÑØ¥_T%Ùœ¯±ãqVRÒmäaYiş=øşµÙ¾f§ëb%Be£´K€èÖMÃÊuÇ;}vNÿAN3¯.û®úÿ‘aÎÀ£ ‚#¶\¢nŒú±‰t„&{ıÌÌQhÔê/ZãdÍĞ}Iå×qÎ'ù«\1™.Œ»0i…$‚v’…oìÓ<nG5wTÏ))5ÉTÏËWMîa&}/Ô(Iô‚Á”Û"REbyæ×Dû4wÑ²«wßV:í÷¢¯ğUCeEgXvšÖ.àÄSIÈC@Ô_,ÄCÍ´Aoó¡â8i2^øi¡JëE¡àŸ/t9‹&Ù*k>ÿ¢HTO{0“dO¬,?Ñò¨ö%¶„ºm+áQIWılÀDË©ÀSåİD?ä¼¯Úàè%ˆoÈ†ÛÈ7÷Ğ=ÒM·b(´rüÂ·s³‘=†=i…©¸ıÄgsjÔª8j2œ¿Ïôáé[é]¹°RË}”¿Â†U;¼·JD*)ìšfó7.ëV¾7h³ÀBç[³tëÚ#ì3,åŒ¦Ã·ÖuËözº»ô×G‚gC?Ú*{u4_¦À—ª#vÔe/‘‰ó¡nñïçÑš+e•(—j+vs$E%Hƒæª0OrBÿız³iÂS­c]Üs›$Xî¸ µ¤Zù—0úRfFw0èdÎîIÉ„‰Ú(u!oœk‘±U5x ü±¡Eâ•ÜZC0Æü6?R¦lı—‚Ø9õ#ùæ?„ã@o‹ÉÊ8Õ¦ÌV18˜²O;¢İÿøæRCà’Ô™•9ŞoÛR²Xêt·ËÛJï|Æ¹ôLOß× úÔ#6¦µ7ÀzIY¨çòK_ÓCî}BL É‚½ØÂk?="ºU×‹=Ó#ÈiÍepyT×€D%F0Uı¨£ÇÇÊ ÁÌÊ³û}œ™ûÊ1/ïN:ª®LF¿°…V¨M®— ï–©Nv|ÿQ6!˜l³_™ÚzE¨Õ¶f#e ŸSLWœ„”½EÕ¦‹îÅÄäKÃ# êHÊÄmRH˜f¸›¡ğÚö³fVs›7ßù!’~új­heÃ7¤	›ªÊ1êşNèî^‡¦´ÄÄµ¡ òÁrÁ…u:&o•å8¢é_qËaTj3`2€V\]mR¦IBt:ÿµòœkf‹m*}‹£Î©à«rÀ'Í”¹Î|ÜLéPJDò9>Rî>İÇ‹­tÓŸ¸¬YªœHò‹àz$í!~İ mÑ33^Õˆ,ÇÔFÒY óØE8¶º i‹E0îTù¦ğk-ñÁv¥ç/Qj•ñ`ÉÏ.Ô,o_¤ÙÃ;ğåS’5µmÃ¢mì'VáUÕÿÌ¢Ëx^À¨Ç¦Ô
ÆâŠŠr¦Óí[ r{·uÂ)l¥<°ûà(·ÆÃÚÒÆ0 ¨ãIİSÊüæe³â –ª€Öó½ŒÜìq_è6ù5˜*œ“9Å€!¿uÅIïó+™4Ò/ıË˜ûNÈgN9…È'‡½ğœ¡QÍ¢ÑT
8ºì¯²«÷àƒ æIÉ­°<º|cU={¨Ğß‹Tê²]õ*F¾`E€}İ•±`vb¹9}wéÍo]jµı!Æxwèy}p=?èV%êL|ÉY+©EÇFKÖy{Jştz‹MO«É¥í)Òp6ÙÃ¤jõ’4¡uóÖ¶9~ø¶oª)™˜ÊÚÖò)S‘Z5àó\¢X|ƒÜ0ÑÇ'PqÂ/t#ì®Ù†(ŞñN¥Íd(àY;ä3¿TùÍ°cşÖé—^IQ–Í’9fû^ ‰Õ™*E½pmõ#
oÂ¦»¡Ğ	T£1•²Sıƒ9>“çÛ `Ô,tâ“vr¢^úR/ß=£Çë³Qı°p/fd€Pió^–ÌöÂ3ã¹½Mi@A¹ıg­¤nuÕ`W{ÔRÍSŠÀÉHá[`¼à–ı~kúúÔ€xp1ãøßÕ€€ş †ë\Øâ÷`ZD>D™ë>õ–	¦š·ÓÈO\ò§³tEµ÷âêz|Ci‹¯¹"­ş“òá±<´wV=oAy_“4V`¿~ñÃï2è{O@§:;j³²‹Ñ¢‡ú$¨ıÃú¡ã,µFˆ»à)Œ­;§)/ÁhØ
,ñ¾‘]²íÜ;<÷\c¹Ägì¡ğh€?3,2öI†•µfÿô9ÓMÀyævÃšÙ,ab!Äx‰Ä<××B®a`mûeTÉa@\OÅîCì
ÏìİI;›ö„Äè;ø*Âh‚¬öµPŸ{,í×
¢Â.ìHü8Âæ	˜T1¹Õò'ñ$è#ğ5W¦}05°Äú¼rï^JĞô'§zQ÷I÷ ¬%õ±€œÓv)àê8<J¿.ÈxùøTª!Sø'–³Ô:+Ûr´`,D˜H)´²Ö·râ%Sóéå^Ÿ§4·§­ó´y¾¯=ƒ_ÃÅõÛ->’ŠÆ"îï†€¹„° UøøA' é½í¦×œî=À|¶µc•pÁ=PJUkÑÌÌGoïÚÀ@³,zòY¯ÄW ¦Soœöc#X¥ÇM™N)cQÅ’ô.Z“`z¨Í¤ü>w{…?šÄÿq9—î©tŠ§Ş2M‡•êp¶/†æª¢Øµ&`èÎ!ìp8ÜbAk¦OÔ›çî&‹ŒU0f½é”íù¦dğl§¹/¼ø>†‰ùãb‡Ïl”­I´Nà, û*‡ò¢n½G)oY™Ï5[/Ø
`.éå>ÍVêı›UKâ‹m§G£%™èâ¯š×È8TåÙáÇ-kçv»±.ÛZ?ÏjK~n.Ph1gö4ë¾.°”Z'JûÆúì•LK× Çf€ñĞÚ¼N]Ù°Ÿ2›Kbr’#Ü=²?J:,úÌdàš•:“æ%§XO¤>»Mı3]°O#İ¤4³Œqv	e!´8iV0ÒŸÇV¿òø=ŒO>™øÖÚeŸäûˆœö’¶-w¤îéóĞˆ{ïDPpLºõ^‡}‡l¯êöùpæìV!ÁçW†ër§³÷ÏîÌ±“¡Y­ÈgeéŞÃšöá3*=kÆ=	xRÀQEª7e¸ ³iGòx1iMİleZ0ë	?dÊh€©ê­şôv7±R)+¹”Á¤/•ËË`dta7#ŠnGlKÊéX ñì®î°¾f$Î¾F,^'KVÎpf÷™†àQÎ_uBO«ñ¡ÑÆ•å"ÕIØ»›	ä¿ŸS}Şsªjeh“îßÜsÙAPµÑjyLXÀı²™—TØûØ9Šfİ¾İyKK;;~ˆâ`‡Xßi>uºù}WìÖıÉlÍ=ñ%õÙbY¦eÅÿR{öÃ‘_M.D”¶˜›Ìõt«×‹ö‡¹m%]êõE¢'c±ÍTãn¾Ï›àAÏ~­§2¸ÚØødúAíUÚŠAÄ?GGı&Á›ÍËÖ¯pW©O^°?téuš‰5µOâ!Cmpí?5ÔCÛcËr¯‹•TH‰ŠXÏ\[Ös¦[4_yHÏ±qâÀŞl‚U2Â®…65Æ›Ÿ 	ÀÜ›>taj4“mèØ¢gqšİğd~R‘ivNçŞ|ß\JPçP¥–LÄ¨x£›ŸÀ®ßÒ\¦jøc{Æ2$HbŸ¡²_„EÎh–µŸZÓ(8’±Ó­‡¸>/ş½C{„¥¦d°¡·_+féĞ öÂ®uRkaÕˆm"ax5Ú/Ô`˜$›íÿ]¹wÿïqÑTıDA;µò$¬q£42]üÁƒRËu”¥(“½Ví^1Y¹~ö¦û9ªeĞ?"“$ı¡`aÁ-”6Y›FÙa½›®’"r§»‹ˆ¦­>2·q4xâ‘5İ‘Í[y5ĞZ(6ÄÕ'¼JÀbl¶$õôatè¼=·aqtËM_oxˆ¹BDß·âv¶LNLÛß†.vºkã` õ±~‚L¬ ûGq(Í"u©tvÜšAnÛdŠêïéªcáF®ï÷™äDğ”)ÛÛ-Ù—w´C9Äîƒ”i1ª¶mÎ]ÿÊ©lºãÉ¦¦kûñVŞÇP§çºš¾Û¾V¤\-oÙ7döœ ¢ ¦õ}R˜áÒ¸İE¨ïÖLb£]6£b_RvrßµUàƒ”uü¥„LRÈø¼íÆ*Ú½¤¾´­qÔZ?“:!–å¤Œ”<ó]a§áº1¨iã1Ò‡N!h’í2.„Š{±I³to–z¤v«V®hùxbK\õB‘	g6¬ªo]´3‘XZÍT·—Rˆª4Ğt94¿V+}:ŠüÎŸö_ŞææWHİzÀºíßĞ_3ˆe~·L<Ç‰à™‘d)UF²Q9Ùï Hs›»Èì‡P^€ÿsgæß=ˆ½ÑmØ”kâñŒ¤.WèÇC;°°py²ä‚å¤š{KÂRJ¬¢yÏş‹
yÅcG§÷ßJ†eÒÀD£+Â¾{.ĞV¶xnLr%¦ÒÅ?îù»².PèŞP’ˆ”íŠrãÏµğkQÇáeû3œá÷@»†P‘I•ME0o©±é1]¼±ºÃP‰W˜Ó]CrSbÑiËÙ¿wP¨eÍëV¢xˆ½ŒÅše8VûØJ_y)i%Óêâ¤:€C4†oÑ¸·Qv4Y:WÏûC•K¬‡’­—ş_6t$àRäôòwè§¡6¥şõÂ·×ğÒy‡@ m"¢Ø;©7\Å)Â%ÖÛÅí­jJ²ãy1jrÊtĞÖ-ö¯ 4pöÏ…ÎJş7yx´KG`Ñq.ï|Q“šJèµogìK’n-™Ü]I×nxì0pZ ĞªğaqN•µsb*ø˜ üp¨J¿3|SBT)İºe¯¼2Æ!¼5–W~whC’"?İKÏ|}·£ ™ğnòÉh¥!–4¼¯d¢x¬©¥Ö©Èh70wlJPV:…ªB‹cb‘Œùk‚Š×6Åıo'»H±²Äİ‹UıÜãô	âó#?êè3³G—)Êá©õ©á@LõJj…©‚Sé¹ùŸà¿BÅDÒ™¾G•–D]vÁ½Ãaw53ºÒÍÙñ§»å\gêsÛlÕ<\äBä%•íäÜó­PÈmĞ¼2•TÎªOõ÷ËU)pÿšP'Ré”k
»Ò£QX,9Ï]‚lüöF—¯Nâ|¾‰&ñ?E –Ë*B9#w‹úiC^Âş¹şZ^*İ
úŞ¼äËd1^º¸íGšÁËE,k6Ê8G¯$ú¿˜d)Ep…çE~E^q_İ —}K!Á*¯à¥‰@‹¹Ï=jÊ¿Ô4öNM-rúûdµŞSå¬”·&nUaÚ6$ŒäQˆ/(¼ïk§ná‰åéÿ}ÔX,fø¢€ùŠÆ=”AKa;ï¯/¿`Ä]ïQ­Gï"ÉÌ,»ªÔZnôeTkQÔ^¥.¨ÎW[f—z8ì&}ô¥æRÈthË˜„Rñ S—„U(²ëÆgK¥Ü`§BtıAmå÷¯’Ë	<èµÆ¬8OpÚ|8™K	Q'2íEÙ¤ú,<tkÜ'$-)
ÅŒøn\™w˜q¡/Üğ”Õ/8G” ¼¾qx]TTIu–†Òİçì2˜Ö¹ğ	ÌÒ_dã<·ªöœ1ƒ‘~Çpb2ød#bL™EH@¦Pœ×ı^9”(˜4~/†{»
Ç^…B«ÏZõ-hf&_¶
ÍKÀTĞíT'Ì©X»W„~3Fzv˜Û’dˆ¡ßèK£¾T¥«ì;³Kªó/`3”Ã4”@ºÿ)¨=¥åzéUî¼´5pd` uñ-ÔDu´
oŒT “”KLNZ0ŸÏ¾z{O“ÿÓ«ŸbØ0JŒÛ;´è=‰²%­òSÿ™‘Á~¢§B=d|÷gê›ØF.äÊûŠEşÖïhJèÌz'äsÌ$÷è·ù¨)aBì¯eOâ¡ÕQ~QZB…¾ş<(>fsÃÇ4à5q
/ü'½çWîlFf¸ş@¶¸à8ÔkåÕv¥í²]^©«ÅüÏq‚da¶V&"KU §“|¡›ªLü9Hû»^3ÌàØËÔk´My*gsGÕ™„_eoR»«OŒg4í»Ä+9¬Ğü”?LŠµíjÌG'ÒïïAy5½›XlóÇhY˜&•jµU·Å§42´=÷¨ı_²®¸Bıkµ˜‰ô•8Ï¡1ßHã1`~©VÂ]PµüP2‰òy—Y Ç‘àM Ùp6vÈC=ı/,dMuÀ€‚'hX™g&ÿòƒ‹ËgŸÉã ë'£«ß¼š±åäOâ”í«RÂƒƒ…ï(¬`²Çù¦é™X:KÏxO³`cóÍ¬që9;ÁaÁŠÏ	£eù1Ò˜‡‹àZÇ·òô³»š¾wßÎJû};t+çLVR7xÉÏ
¯ŠƒÕºŞ*jrÁ%…oÇÆ<êi|R"ØWçõæâ6U’¢[)Èş¹„é_l×o¾öS‡’Ùá…CW}KÀ]ĞGsƒw¿IØš> N_æ˜[½b÷RÉâ”õ‰øEAI¼æj½$ŸÜ1Gğ¦P!2YM˜úV¡WÃô^*—³€ŞuÔ=%$½Fë“`yï€nzMQQI¦sŠ*@°ÖaA‚R¯îµøK™šÿ$Æ°’<Ì¿oN¹‰–yìÃ€R"ïĞ¶,ÇTìS6z~ ¾U¡ÓKV.èÕh6>«’^ÍƒpÈsg(¥^Téš}N†ypú-)e‰§’ï÷ú»˜‰³#‰4ñ@'åTj¿å¥%ĞÚmÍ«¾	)pïnëhw¬Lá¿BÔ½¹_İYîG?œv¤2ó,±—Ìè”xuå ²¹¬Ú1´	5ªEà˜ß ;!8
­<ºÛ«	
·òæ˜ÕtÖÍò•`Ñ*±c%p¤£Ğ¡İˆ)ø¢ó²='Dâš*äÏBÔº
¡û·‹˜È¥÷ùCZòµi»¤v´ÓÑitt•†c
3ö¦À9¥š? Ësz)ÊÒ|x_\,	BÃtÇl»´:XtÆ{yZÃ{`²˜ÒæÀæ’ãà²»•ŒZí¦´8ˆùÛQ ¶¥¸®=Køm¨l…ûƒ¨l$Tò/Ë¬¬/9¹TY¨¼n!÷lÓ-xÔ½qf×òxé!³§Ş<J<ìÙ!’& ı“-pwi~êlù†ÏÒlÃÍÕ Ì‰Ü¡Z:bŒÊ§’¥0ävµÕÕXú<ë+d¤wŠ„)$Q!ÿòü+Á:îR”mÒôÉ°J³E›ÏuSšW9H ãPT‚)ùS	ùûÂ¢)¢¾5-Ô›:ô¼×ß/äÙyVé ˆV,CšYtˆÙ¾ÂÈšÜÇMÒ'[”	SïèƒdûTœ¼@2V¢~/ª³†`ÎÚA)UiçÙ5€söJv	ä½7¯2ıõ”v{‡UIØ6Ô¤6mªl wA…V	{½’
ò¡%:%\!gˆB2ôÔŠDâ–—8'Æp\½¸ÑV_ïé7uºEŞ<E¸ÉJË u=|Ü£Õ×1z Vo}4ô&Ç-©ç?óˆbÜÔ»|é&ªğí³ŒÿÊ÷/¥z;ËbğçîMÖ“w¾õó›%7ì¾J8¬'wÅpÓ2öÊ—ª/LÒ[7H¶Öì¿_&ÏÎlym\ºa˜˜£ÓépÔøäı‡ÚKğ¥™÷(¦`dq o/ğü^X ì,ÿ^ZmYAMì÷CWıvë”@O8hÿç³!’+Š3‰fêy-i„ÆEÑF­#‚1XÉEäÄ5ƒtâ]ò:Xut_‚¹<æ½¼µÄŠ²ï¹…ÈŸÂP›74XÂ´ÛÂå-q BrG± Ë8ş¥ì•qôËÀƒÚ·”Êşo ß¸ĞgÛ 
@„øX)›oc‡93k^îi°1Ú¹GŞÏƒ†İÆŠ4í1M2ï+eÍÓFlã;î	ôåMe¾áqªÕ¼@ˆµ¡•QP5Î¹–33>Öï/¸¬b+İu0Ä¼•Ş1xYÓÛNDÖ2è)ÀK¹X„G¨
Ãùyš¯j´üsfÖû‡´°Ññ3áè õ¤$Ïiz°1Lô/ÁÏëhBˆÄ†ç©ŞÎ‰wòl‚0Ê¯èëˆºL{Œï¡{%¡Š]ÈcSQ&‘=»UTU¹F¹^h@£?n_ke/§¢w3úÍ;6n¸z?“QÅ2¸X€çŸ ªlæ´™AçZ)Û³S3‹]¡Ñ‡+¿mD†‹_eÇ¾aµ¢€ì¿”Æ¤şñ®	>eòçY  Iæ @Šš%ñ4	–Œ°ødı9`“Â¸Ñæ5Wtô-'–SAç8~Ùæ¦VOñÕb'ş )72²³áÒĞXï4Õ‰Ï'6©X“)³3÷‡¯¥3ÌÍÚ`B9ïYâ‰g3·ÓŒvòÈâÇêØ ûz ÖVh	 MR
Å”ùR"ã+“êas=Ãì/7i»ÉÃ;‚¯é …àé	÷ ”3ä{Û«àxş†äB\Q3×Hö‘bOç\›¸ÌùÑY~A&]0ZÛP-iŠ1ßJ	y¨6 ó;t;®à¾dà&Úœ§¶Šùí0ºPÅ ¸~gõïµ	¶öhV®—¦Éjäï8r€vhÛ®Áçuë‰0ˆàô­¡ÊƒbÒ^¡bö ©.ºÿÈ1¦2
{²ŒIÈèÅ8WOƒ8<,Ò:gõ$]6eZé†¼EşèS·WÁùâ­jîÅ÷‚Ä>Í»QÉwå›ÏÖùëQWœ@´È¸'ÌŒş;·B¥çxæ5ioV^q[VR ÌEºè·Jİå÷z)3zQ*y¬£ØéUÉüÅÒÀ@×<z5¹—×Kİµ•à’»	•=&†Üjµ€€ÏIÙMÒ£;KBĞòÉğ_à'qµÃ[Ø$™æ…irÃ2¼à11‰ƒÌˆÓx<•¹è‘-Wv¹nbÿp¬±u„¸*Ñú•¹ymşüğÃ³“[-i×ºŒ·¤¶`Ù‡ïçı¯ááÉü4bİÕ”³×*éˆ£|¾ÎweĞÀ*‚~OWµK-#¡BûóÇäsb‰u\x‘~,e¦-Ï.|HıÔïçZg* •Jaı#I
+úhitæÂ\SL+ùÈ¿u±DC´ô¢İÓÑ˜¼İ”mâ|`Áñé÷Ô ”ÿPT3,£ŒyçüÜÊ<¸xh"¿uO½!l¯÷‰ÎKCâÚ=IÒ><?ísËuÅ¢k3,@nÌ_j"Ã€tCR9p“”ªUWÊXñ‹ïBVÒ7V9z.ÜTÈU4íRë7ò/|g“jZŞ8iêç\h:µ	öK…ö(X¿WYÏ«Õ$¯[£ Ê–Õ…ò{wîb¹„×Ò"•Z}¬-«ú¢­Öo®Æfªyq@Xão=r;.•ÁwµşßIgHG•ë”Só%ïCßhékÏ7?OÍò5 ²ô |ÅŸÁÌí³6 /n"±•¿ªtW<–P²ü™z†¦‡ı…øRäy¬G?ò§cÂ½Ã*:×½DÆ>‡¯27JØ0³Ü¯Ôïw;…Éí·•‡£_*ÌÒ÷‹=ÒÚV'£f‡¤"øĞºZmÔ’ZráÜ yÌ°‰"pj%¯ ‡ŒşSËöùÊ8ÆËÄÂ*ÉL8B­ÓcëŞL¼Nª»ÿN¬i„ºOl+K>$ã©!¹‚g*Ø'ó»w“™Û'r40Ö|¬¦Ğ*	S¤2	áĞfvÔÏäß…ëP—…†=—J­Nº—È¦èò ìªvkJ°¯ßˆ4Nádø‰§DvnÄ®­Å¡$ág:ÚekFÉZ ”ØÍºR –Œr´ƒJëKütãR™kÒ1%C ¸0vÍÆ‹<iéßo½ÂKİ–à7Sù<²€F´›’`ÖÎ>r0ÃrE™]TÎ'Øù¿[5ÑÄa§Æ ª­îe´˜j“İ5FM@†¦[ÿé^{ÔÆEqÃRÙİ!ª†Zº™äv&â-#›;ØVéÄSÄ$W€\¾Õeš;ßà†ÃÑVkÍmooE¡Ö¢'Õ>¢$.¹7UA¼üğ(›û)†ÉQ§†À) ß`K°5Á5h÷ÊúÏ¶üéôlÀ\L»n¦äèÈZ†X®¸ 2Ù±´¬Öø‘…» ;öJÚ:†Âır,S`Õ¸-Rx^¼iş’©ï‡±ö¥Š7»´_¡Ïè6U0M!dŞşGÏš@°Q>™Õ‡Ğ°·OP>špl†è{Tc°M6¶¬ÑCŒT9bk‹¯ºÍ¢i‰fáÍÊvµ‰ y|Ø®[ß+á¨1Ö‘ÙB›ÈÍáÆöó½?r¡±
“Şşf<m˜ÄkÎß¿ï–0DK½°cbŒÅĞ=ú¬>³¯M¤É4f7”û@Úá¾å@2¼xrLŞ"¶ĞÑ"@°à´E¬=nQ.rC²qÖ²¦¸PÉÃhÂ ñ[>R£@÷šåK@k$X¯ñã•¥z;ÿ‚ÅêÛxG?™7ÜÙroÀlSkô¥–#ƒuº!qkZÌ
-µÍÉ)Z
ã^9¡t‚v\FùïN—Ø5˜“£¦4Ÿv‹Oø8{l¨×ök&×ØšÀ=Nè?æ ™Ğ¥[†œ÷bô”yø#ö­·íu¾™•"ƒ¥nfoIi²>«‚S¸¶è<\k©c¥DÖÖT½¬(­µ|İ£Ù­ĞZbRSz­2·÷x‹şÔVvp;­ĞÈÑV!º<œÇÆ
‚{Ïå;3–dĞöû£ ©2H-¥­»¥§š„²ĞqÁĞÂÒÍòÄ{xøY}9ØsÕUrÙ6ÕpcƒsæT{<UšFœ´)`sƒ RùPÓ'ŒäÂ>‰ÈëJ&“­tV:¥Æ@%ÀÜ>u²Ts›‘öDJ°ómxÑ¨UcõH¸$"¡,Âñv¯»Ài¸`ñ( ‚“˜éõŠßŞNãJŸ
ÈÅã1¨ ÕÉ¼ˆx¨Ú#ıTF2í|Û£.Õ=u©‘ã„>
ÕBÏL0CŒ\ÛÃ]®ª{1O‡O&–Ğg“jd)…ùlA¦Îç­súàiq¨ow´ƒÍi÷Äºö‰…˜A6İ¦Â{úVÿ@’‘ì!ÎEğ7ÙedA€¼À,±SÉï¿\;:I<½qµª‹ğËéün’?û‡S‰æ˜ıqØç7#äpÉxF–LJÈâ½ñ¯bzCğ$0vC|2hÒñ;&AQ&h1áá“èFƒÈGã&UÅÀDKÖ	§;hNÌÑI%öì“oêT³Ëy›IñÍäå-
é1”‘¥«5S	ŞfË*cªPŠ–\¯Ã]u/XyãTÅK³„¼¹jAF)²Dv™Ş°«#›^U†4>ƒô¢ó‡äJi¶|[ìCUM¾
Ú:©y¸ÁüVK–ÉW¼y”}»ËüZßƒÿ^jÙjİDœ-ÿFşÌyÒ—”|0®¥°µY!öÿüAÿOò%&˜Âbì±4_êÒ`°N)ê¬69ˆßŸ·Ä.÷t¿ßÏ'
‚ù£şcGœ§ÿ¡ Ù=¨ŠéF'e”/Ä¿ÛÉ+”1É¼ÜİÜz+\¤(”K¦oé:ÉÏxò\7ÕÂ;ÖÌ0{'Û«g&úÔ  ¬¥Ù#Óß Ñ1ÔøÍ_m¢Ìg~Ç~<#›{[Owf¸-¨â³}‡Igş./ÈèM\ó†+qÅªÎ½÷œÚÂX±Ë“şš›-ÍS~ã‹ä.k{"vf‘ãÿeü†6%0ájß÷×šQŞ¸½ğøPwQË.¶-èW‰ìESo.)Ëú,i÷²d	Æ;Qøbì>kq²\Ã?‘¨rõ-˜>9-ó
x%¥³2ƒ}!#‹ºjr@ßğ>>o/x*ğÆğ”z’„17~(ÙÛSQ{á1æÏ«ôT­•LU†­­ğ;_0ä’*Ÿ€ïÊyo]€ã©	
¾2¥•,z|'vc6pDsB)Öo¥u(kX­ÿ÷\.°pæRumKŞ¤>:€ÓØ¬×”‹–ßWÔ"ñ2şâ+ƒD˜‚õˆş›µ”’/)\(„–W€*\VødÅ\3öyô Î©š=éÛ"	ã)E{b½¾6LJ\û³À}ÙÌÀ‡9¯)3åShŠõ¾«pézqV» İ<æ¯xq™"œÍ[%™ºj˜['ƒã‹Æªİ-W½‰€•ZFi=Â‚¸yS‰ õñ¬~ÉÍ$ªC©šS«dı\½S><pÓprM¶ì¼B0³2ºÆÙÁ'‘çPçGJ"6[#gŠêã»­›‹µÀ¹€ˆ´x,FÙ×jÇšÁøı„Ãpâla+”§3ÑñØYù÷2)Ğ£€{ 4øåaTÑqËR¯Æ WÚDòJ¼(‹‡c…ÁøŞxV7±-R<…ÇO»l—~ø£bh?Ã»Dğ²&•ÌÅˆpŸõ…†ÔYãYfK ©è0™€õ‹ÏZæ<®õ;QKœ<×fJdcî„L™m‹6ÔÅ”¤Íı@6pÂjfA…«–< ¦mÙGv;u‚Õæ·ŠhúTŞ7äSiŞ'¿­FåQªuAQÁ¯ZËR³gsÜgËİóÓbâRò÷XlÓ³uDşfœÈ¯ßë!ÕyÂ¢úå^¡ˆ?©ôüfz;ÇƒºQa}Cª4•ä·¤7=.’NW¤Î\® [â%HÑ,Oµ-+íæx£ù7‰Á°aeß7`ß,*Ò×µ>5ƒ=õæ’áÉ,) :IjÅÙi6z«Ÿ–¿Q^;Ö¿ïùÍDòë«lö>"Œ¸\öhD%Ï şÅñÊWĞ·á»š]\é§	ËãòÈ]„ãôšyˆ"¼k;	´»ŠèÙ¹zƒ¢O;vú?^
â~öô)óŠUß€µNr¡aÓˆiL3DŸ½­}€ŸıçIÆïÎÚM8¥XŸí·ßßÍU¹«¬’ò`²5—IÁë·’å	…¹SZh!1¾¾É]tuM›É)¶N|Í¹p~‰¦à½˜ö&„İ¸äßŠÈÆ+ØUĞ6v©l-gİ_‚Á²°Ò µ³ë£Ğ,¨6~ú›œY¶Øy?G	Ò8Ê›’¦&20Ù•ª>MÿŒŸî´SŸnuç=Ö?çc«”ŒK—5’ól”ñ“­†7¥¬“LºÊÀÀ z¸í‡;X¹˜6ü/KìUÌL»t2O2Xiˆ`F’(kQà»DŸb8xIîĞ«^ `<]ŸíÜÌŒö&‰­õM;İòT•O;ŞPTÍØ#XÎ´Q{ÃîiµõÅm½‚[!ŸA–€¬Zm˜’ö*ÇÖ¡GÑø®.u>8ñ DÌÒïõ(8aÖL˜í¼‚èl>!ÊH5/yøŒ6b÷»¯ô2(|-dzİ68¸;óNšZÿ|6“¢ğà§•…*ªúJß‚ŸÏ¦·B`[Şiô ç¸#Å0¨§#ÏV¢Ô¿ğšÖoÖqöòg˜ô£§ê«§ü©wÄAkh=;–DÁdı0ÅİÚ5ÍŸ²ùºØ%GC±½Ïô.è'nìÎ)ãÆºgíš0@¸s·Ö¶?(¤ç€É¨!!5{]¢³&ŒÌ½ãL“ õÒu¤‹7ùk’¨53q%­$^¼-179ë-LÍ¥,ôÁB 3üG-n¾øI£œjwv‹p¢˜n£gº¾rW¡}P§W¾ˆ/¸;½kJF™8QW‘$¢ŸL](_UJÂ™¶öPğ×Ä“ -5|²€<ƒ—£T“¾çƒÜ7çOÎ¢uŸÁùFK¥h±=¿?êöÛ“•ø›3IÈknA“ìŞ@$³múôĞŠ…ÚRIÀñì>³ö"El8àÒ€I¢Æ+³vúPH­Â§¥Š¿Çööƒ¦&ló=(£Ü\‹@Ö7;+zh@ S±·|ûŸœú]èGÅàå¨«ÏntuQ30@cÅ6ï–“"2¸·«DœgW ñÌJ÷—ª±?‘›ø±ò4­\ô[×Ÿ&~°HÊ
ÿûªÇ]‡C©ü<?.ÔùÓ.7€li”+Ï¼[}w=1À?¹Á©øg÷Ÿ›X/„s)}ô^>-9çšÜ¤ñoåØS#÷B„K’y8qIB.;õQ§—	şO^°è	²¤üŠ?ûÁş.êŠl¤¾ù¦†Ô€¯†…(¢,}"PU¿b¶q'*ŸØ²»Ÿ-ä(Oo,?cn$NFTwõwËş°‰„×â+©©?˜1ë}/ Jú¼6fg±GzßøÕøq3u+u/ÙRt:ª«"HÍt.œL"ü+CÈlÖG›.¿ÓÂ®sO%)SİwPã7¯nÌ“ìzRos=.rßC[¿Â†––@Q9<¤Àáq£8µ7¨£PÄÛëƒN¸x±Ô/’¨ó›µœôS ÖM\ÕŠ0M,ãÆâë§{m˜Ö` ,ì„nàz=U±N Ş³ÏËãOÜnMR´»Ñ€Æh]<Ñ<h•„båJrÎZ×SÑ¬æ¤zôbBLßÓŠš±ÁÃĞ+†‰,üJÆGûï¢è37ò7¿QH3"›ò ÓJ}Ã•«8(e‰Î”r‚g³Šr†c®É’-…"qM;m—qµúÿóM­½F/Z“ÉõŠ€†é°d‚t:°ÿïÂrôÈä	Sçnu’ ˆKB"âÔŸéirÇgrÆ,òpjf”Ò‰GÊx„í(a¡â"ğ“ú‰çæ¬­Pş¯R‚?Ëm%bu«â,9³,ª¦]öÎV"š½Ïôfµ’¹ôupwÌ–(S3ÔšˆCB@6—ÕÂ.•‡%·¹Õôûµv¥ãÖf+¦¾ğ*æ·±­C¾²ı7‹<Ê7Ô+†¿[Åü‹"ÖüBÑaƒ‚g
Û÷"´o·çâïj>€(fîNê@V¯§ôT.Ñn©s.‚™½Ö/mR¡¦‚^	ÂÏ³&MaN”D©ì¬‚Îie³ğöM%8/7´2ú¬‚ìé4Wìc]â[¡ä{Ü 
ÓŸëšôÄExlºˆ$şPSÛĞ>ûXAzæH(È£“NÖ¸k{¿’=®bÕ”Xì¡«OÕ¶ã¡{ï—;Ró!kÜÕgü¡8²„ôòTÏ( ‰¹¹èà7È0İİøÆ¯^óâY´lÑ_lYk4€gÅĞ(qSQjÂïı)C†9×±Ã:29ß™sÉ½)ætzš½‘+²TÑ9yH™9Ä…jh<ãÛ¢FQOíÎ•Ù­ÿÔ›7¡äU*c|%[¨çLY¨„gy»ÀçÅR°ÙÃç>àËÄı³¥F˜ÜE.“pÚã¦\xfèÍVGÉiH~•J]VÔv‹•úİ T¼d_âgæaŒ‹‘4%,2h[ÏCfS™Ğæìé¡n¡DØÃ‚Şÿ;§CD5Ÿ&ãº"9rgŠ8’¡Í<N¿²}¦G™Á‰‹3÷’‘ÎVŸ™¿ô÷­W	–¸\¤DøyâUĞ÷yC7é’yÙnAÆ…*ñ¤ˆÊR)V	óÃI–÷øóÒWXÓŒH¾?rù™,Aç·¡'ÜfeLKkûµhD"3’‚GKÒ2ÀNôNÄÅ QËv8@:Dşï¨–0Wmò¤¡—ú€q;¹ö˜a´zÕøææÏà0y Ö²TJN.T«’{©„Cš/ó«nzñmh·åôh¨aƒHÊ€»VcXêyø„‘fë…cÚ&‘Ã¹µİë19q³Åz˜R®"B$îŞ;i‘.óìë’”h”¨*æÒ‚LR äZİ8…5Sİ=„Ì^;eŞ‚	KÆÄ×º»‚ u´."¹,ödy•0^b)ƒ*9ø€?Ì
;ôÜÅóQO€l1ÚèÉÃ ù¹•ÊM©î¯UÛYâê‘¹¯@í›Û“8|3ÑtVi¬Rá8‘û–k·–h1ê)}B$b’¿–-|€ã0£ûAâEi.GßğšÌõÇ^äXiºö_`•[0¡™øÓI,‘Y7Ò€÷Ä¿ B»ÎİÉ~5V;X{w«qMZÏ—*28j™¨¡ò¡q?`a3œ˜Y¾ßTa›(Vˆì§?ô·#ä	ªí1	dqÛ¬_b&sï:÷7YHG®ßÆ²…¡ä«û\n±ù9 |<wl}¡ÁªÙø”âa"ToÉï—„ô†iõÂf‹òâŒV•Cÿß(sóq8~)RMc²1ÌÈ<«ò…ÈÂu›Ü¾jY^<ë`g•<‡åüÜçœXèêÆ1>ŞÃZwÙV©…X^²CÛ;Ìz[ˆ£LiÓ'êï»ë¡-ZùºÏ}C©ÎPŒ“EV)oTøœÃYø½Ùl‡Èéœ*tú˜ªƒ=’2ÿ¢á§åy#¯˜CNmBê(¼Vî]&>ßê`{làÆ³ˆÌ§:ü=R-ÌÓ’1Üâï)¾|ìíK+(†lk0=D=»à<(îAŸÉÓQ87©PPlàJô-ÏÒCXï_¯›9ğYK«İF±
óË’ŞƒGT'»Î<Qm^x•Y0û¢‘Ã÷®æ ¡ğÓkŠ|†‚–ÊæÃ”tÏêàVÚ\3ˆ™1¹uüå×^™{²+rC„„HÜkk”/Ø2õ®òd*J¹¹NZÖ‰·ËÎ9Ópõ8ÙOÏBá1´hÄİÉâÎArÿ¹Ñ–Èc’\($ıœø[,²1cæ@úŒ›Úç¤?x‡Ú/|Cõ”@jˆY(jàbÅ¯ÿ¹8­ôÉ[Gæÿ*u Òk¯%kòÜQsˆ(“¾ô ¡#ÂFó¤²ocš—dXrô@6d–f ›qw¹)‘*õÀ(­kÃé~e®©•±8±öÓ|ß@ÅTz§°VmÄB£›rÎäˆU‰¿[B„İ–ııqLâÌŠª:È*Ò¥ .‰5cœÏ¢»ı‚°Ü“VòW"…Ìİ!š³¬2rÃà’±ÿp³R1ƒ*÷Ô'@d¬
a°_ŒÀ~óZàˆn›nYıÁG…À‡Ş–.$uO`eêPÖö`°éšQ¢ÁÆfiã½£cÃå;w&xv©Ò âÄœÌé Ö‡ÿÙçõãóS#«ºŸäĞ£áõ´v·ùË›¿@¡*5¡Ûàwxzëçfˆ|H·­ù~Xş„ò[ı=¼‚«I,‡£Ö<Duş£
½7š0gÊ—zÚëKö]ñãØµ¼]Ù/L´æT’D^ğ7º¢ÚWæûúÌs{Å üàêî‡(©gaØ¥!çpºŠúîş1NpÄÎjúßKBP²pÒN?¥±ş~ßì8€=*<4ú˜Ö?e³ŠT­|z€şÃ•Çm)QÒ§ë³[ïÃ²1€·bÖ¤ıµ¯‹Èd—HQ©—ªc™…ôwÃÔHš2d´~qçFá“M‘l6ºÀ€¥lïrÓià¿„ÒV ®îcâ5¿3â=üÍ0QĞIå’§%sËÅİŒ	,•„táb˜ÿ`í·ô#ï|ÀüË²–•Ÿ¨
`2tC¢kN1&Ìˆ~EØ| “3Ê·kÓ‰ë¹Ù!/’ÔÍC«ƒ¶eéß¤¨˜R¡ß’û™Ô|vİx£èæ~É·ÛWx,YTs©ÌĞj?±Áæ†1*™›Å™§ní´õh«å|’qŠGÒæ=nëÃhj¸ø¥’°Z\µ9^ë·{làó×§do+ñä£>ÿ´¼ØøşyDfâ×-Z¥öõIö® CÃâ·™‘Sğsµç#å3%HY£nM¤á™QğyõÜÈ`6V93Ÿ‘ıZ=˜f0©iI–Dm€øŸóˆëñ™ïH¤²€Yÿ>»¡ÀuÇH}Òw†Ãp®k&ƒ§V¸`_q*cg zÀ,.ug„<ÈKÂfÀ'°·+"ÓÕs§ÖU7ÀÖaZæTÕae`Â]é^ÆÑ”ØŠ"†¡Jwz'¬‹G|læúÑ…êüJ„@^—ô¬±R…İ(jÍ_ö 8Ï×¶P«ù¥Ô|E–dşj|rİYÊg—ÅpŠS“‰øa½ƒÙ§]¢s	ëc{0ñ–E‰C¿¢
:ë­EÉ(KÉ1òùEs¤k^”ÌF»FN”æg§úĞX-GÆû÷3¹·U	mæ@frûå•,¹•²ß·™a€®…¨¼Ö#Ízı¨‡xÎZö÷¥{¹'Kô$s0'^Ï+òÎ?|ş×–ŠÃVÑ‚’dÎ—w]|&“£!d¾·²8ÚR'âV“*Ó&ÌhÀ÷á¢%[õûá`„_ãæŠ™¼‹GÿVâî€Ò&YÜx:ŒpïğÉz7Ôò}¦±§ĞhˆP–×ŸNN;à°L	Ççmêô¦N—VL/¶¬LhÃuqZ®X/ÑD{OãV~†H”Ñ›jÏkÁ‘NP.Ô~‡!Nš3èM§´Ü1n¤ìÎèC&€áäiø$•J(@áİÏÀ‹¢2em&JMKàáóiË,Ë$!ZÇÁÙİaÈCşz´–_¶ÑÉ®!å;%Ü$.lZfÍ½* ˜ÚÖ•pÇ2´G„¹‹üº™ë9U –ÿY217Ù‘30âÆ'|£ˆéİN7n*Ş`£@×²OrZlƒ¡_·ú€’S/û¤Gø©hûÇŸŒŞ|{lA>¸5B£ö!Oº…ÅS*ÂĞÙ*ˆÂl‹RõÕ7ÿ4rbD¥Æ²ıİ{’~("J=KêMáO »ì£@5ñX#›7|‚ß}<»ósotÿæog€TÇ¿ShígSyÎW•š“íğÎ©îj[·•Ì²ÊÕnTHâ­u"şR¡c¤¬<9íéì‚l1ıSœ+&o9œøìôÒ8°gŒÌrÌNÚúÔíƒ–¬ûS0[çâœ•Àhà Ã‘NÛÁd/¿ªÚ;)¼5V _’»t7œ_é~B[õş‡”Œ©øc#[ü/ŒZ¡”,ş¿TY„daÀ#ñs_©ÏÓú_Í¿îœuî4p’b³“óZ7`®V#ÏÖß}Rü5ø³êÏâ¡s®s¯éÉ³†nyü<Ÿ–Ñâ×)RI©±‰kQtàH®äÆUPG”‰¿'5ŒuLø{)¬>©Y¼2´ÕV“Š¯•‚««fËÓ¹Ë.E¤Æ…ÚÌÓ0Ánaåªí‰–96ïeÔªœ2°§+èÆ³Á-‰§pò’«ªê%ÚŸ!_Ä%f`aÄupx>Ÿ¿œô·r§Áî|Há†}ødÁ¯Ç`¨M»íØu©ªÙ2Äí_+ckó2ı!¯éwyµŒ2˜vô C¦¼¸³ÜU“Õ«¦¼ŸK¯;áaj0¶²»‘BšËŒ¢²ÎxìÇ<ªSz€™t”éL}ŸãòL%ò	£¿©<ë“ÑTR‚Œİ¾+•{†ÿ;*“â«êã,ÚQÙ/aId®F±hòĞ×©“pQÓÛ=/kZ/FSËå6P”¡DqøµAéK†ÄçŒÏOµWÓ
²»wÎ³³=-…Ô^ÈF5_y_²ŸdÅR½‚6Èv[È=¼õ½b†èV,lí{àIÏpæ8qOX)¥pûœ•‰çÇ†'äİ6€şÉ˜èÁpÌã’İ¥óÇe¥bÒ>Ã:a0œç'¡I–¹¨úÑ¶œ$;öbŒ°ôébMoD4	á0XˆË«>J ÇF‹^³>Ôİ°³9°§CdñepªOÖ ß6“œYú–¶«ÖqDºÂÄ¸ãc1`zôÔT×ïïù^¿H„oµ`C_kö­C³Ş;R®şé®IêÜ9	ˆD8V)¢¸
ğ9ÓSíüßÎ
°.ğà+îœ¢É`ÃùùüÜ+<˜W˜Ğ¥§ÏVİ÷nÃ€ø‚B–Ş~C‰‹æ€]åâY˜@>.]’ôpl6’V¡k™€„‚Â]ƒj®Á[7ä“Ç]›âá¯ÂÜ4˜Ãè §EÊ'/´×g¶Ù—ŸV€ ¾@ôv2ÚÊS­yÂ{ºÌ_>÷¤*»˜>õ	—^¹‹€ÈüB¿®ıãCoÑ‡Fn58³{¨á.Ó­dŒV¯³äİ²í
¬^tÚÏ¸‹5€×šµàÆº4¸^`×–¿Z[ÍññÃ&ßıhÌ¨G‘~JQƒ[~2—ÑÜº _’şJ‡|tGsÎ3÷¦ãÂiZ\‚|…à‰é‹2}Y_‹Å½tlâÎ¬Û-_xíêëşY”g¥şÓ7ó²üåÿÉ;h1€`h_jş'8²˜äÀgn¤5Ğ¸=°ğ‚C­¤W^Zõ¨„2‘qY/ê­½áFªÇÛ_±Œ¬ÿwŒı;¡xåE‰î÷4œç R«Ş$ôÜœµ¢e¾‰’±ùÏOî_ ÍœñäæŞé ·\jÙòTn»5”D»Q–+^§á‘â»k+4š†¢ôPuØ|rö0PPA—Õ	ŠAG'£ ›Ø®Ä—#T®G‹jĞŒ7×<SÛ¤õ]b¥æn¡¬…ŸÂØ‹rç¡„™2,Î¯–Ü«u"qÖ”SèeÉPwÊ¹7Ê©]?ËÚwÙsOvãêºŸnÊÑVãªà–q?Kh5´]ä *ıÁÿDNlç—‹ï"ìy¬Ä)C
ì—º§°{Ï¯3647šÆ„)øÚ17.•†æˆvÿ¾Ë’ßİ”Á±^y¹˜7ÍßÎ'bb.¨!]X7%]E g
ÅEÛLÒpImÜw^ —‹„óv50¾™"–G|G_a ±ôm@¥õş¸x±B±/Xi"¼*ÎgƒŸêîn¬Œ„ ì¯»QÖĞ,×¥VjW–×ÆŠİ`ûüa°Iå`‰Cì¥6V˜™^Ö`Añ…õ†ŒñçÇágË½_' Y”[™È¬qúñÅj‹Ô®ÚÁ |Üu9D
êÇy™”†Mû|y·yù`½Ùô¥İóa½9SkËÊ øÿ±è¾ª!¦*p’ KÊ†("m»ÿCä€‡ÒÎMÜVzwí^R˜Fş—gµ³•lGºÂå¡ã­üJÆ?æKù.^Æ	áƒß`¥
íÑXßí½Ú—‹G/e"¹×sÀF³TÖÙ¹ğz%eæÉÙ/Øó~U—¿c¿fOÀÉå•Á˜‘³åÅdD¡Ÿ €›Áe Ûè ÷şWømÓíTüQ–¶•h·bÎkëáı%ş.>UïQ˜&]FnW«É;Ï:lÇ@’.å`Ã:ÊEööß±RMû2	†Îïo”ãÑ„ÇjÊ"»öşòœŠ« ø3èì5Óee*0Ñ?e‡Êú1’a Dõ Åîvx÷ÜŸ³¸H¥§³˜-<Â´{}``…}­SËÂ±8ñVE
‘Ñ_ô€.œİ©4&ÈÊB|ƒ¬¹ıÌ3ô¾ÏÁÿUrÒ(’Ñ3…¬¼”“õˆO©É¸Àñ–<}‹ì$Á”¿iÓ…‹N+	Ùö¸bÊ)Ïêï_½B/§\ÛÛÍ~‹»ùHÕ	œê [?iFü±énnDoñ63<R™_Ö—hsè@ Å@¹“£–‘¨:wme,ÔL#Oş×¾»îˆ&YÆ”µC›¥o0UcÛIıæ‰fÏuÜho>}û+Š¡ù™ÆRv~êÍCÄô¡Y= Ñ	¹¨Ï„sš€Ğ=¶/E®Áøñ¹±›¨U>i`îKgA·ŸÇTŒíìE(áq±ñæªd’òúLKNâ¤‹uEõoFûšÙÙ
düøÔAtØĞÁ«FßÕ¸\ş=us/ÕÅÀĞxÎú…!>QY!ÅÂüq'Sò?è‹.pŒJ ç|šƒ¯|0³üÎ=EÃ)Å{Aì‡Dû™MÆ…8jõ8ŸÑWÍĞnÕ:ƒC§w'kŠ7­W€öZ»Ç²‹ykg^>+v{¤³ê:äøãË„sÑv)Šì»Sô'ò"L OƒqŠBÑÜÔŒDÉf`o„7‡OB¢i©]Ú;}ZÎxÊg5AnüVI¿L©ïNÍ!ch›‰ãšáßDÚ±uÄç‡¯øuËr‰_ÚLZ£¸Ùç1âƒq2ú8‹ûºæˆÛ	ú [8\K¡K€n‡5Ë5=}e-üâ³“²éX&"
<Išn†û]ŒtĞâ(ÕÙ9è)…nÍm÷WİŠxùAJÒ€¢ª–V2CÖm²ì¢nnJAQê5§v”ó=ƒË%§á6,’’ÆL+ÚÀGc*jŒ“Ó†0ú†ç|ÜÈ}´QhaU?vÚÀY’Xº‚Œñ„ÀsŠ4²~f~^³%Ig`Î‚¹=ñ·?wô“F®[ÈÌqËÖ¨–¸ºÑà¢`Q×)²"ÎÏø±Nƒ²qlk‚ïá\µ|m'§$L.0æÃQÍÙÚ©¦s\Œ‡äêWƒÁˆ|É,9Ç¬joÇJ‘`¶æò;áÓIòb t±àõ ödšVÜˆ.sû”ÕõãË›]ºÈ•#â4Çğ1C8U)
†˜¤"@cŞifï†\n²ÒÁv¾ ú-˜ø:8­`ğÆ¡%t°œW×vz¸åÔÏë ô"õ‰&\êgQ&bë¡JaÖ•ğKëà7¥ÀZG«jÎ }ú\KÃ:ëÎe˜õ£ŒÜoæ(e,åuÚ{‡¦“a-ÚÜAŠÈ(q{ĞC.DWBĞğœ0°u9zÕ/°3ü¤h–²9l@‹Õ·:§Ş~¹|ğ|–s¯#Š”Ô¯4Ó³HËÒE‚}fÃMˆš_§E‘2W§ÿ~SÙŠX¬¤ÒNe18a,'²Œ¿¥éV
Ÿ{~_¬ÀÑ„£×fœ­ğŞ¨]°P@È±<z9+c+œø@wb‘hE\]œW¶˜Ïİ?´[*Ó 7àAŞóVı³,‡ü†Ã:'PÜlÙ7llvj”Ê˜µ–”Fü÷é‘?ÕéW7=×á?qÕ=ÜËÖsÿ H2(pTPë˜¾ÁÁšX#Ê!jÇ”ìYºSåk ^¤ŠdÙR‘»ÊyVÈ/n¡qÈy5™¹¦ß+r×÷Ş¾a—,ÅKÚãS)+¼Šn²ß½“?hæ9Á&[Û/lx.B‡7ÅÇméáV¸ÆÈ¶WS¢\à k ]½Y¾ö+….Òá`Š.ÆÏĞ•£Â™‡–ÊŞ¶nÈ@lÈ¸N0ã!:=«ÛğQÃÈ°ëi•ÊôYµráB¶7bÁ%Ş'.x÷ÍêÁ'M¹Ê×»xÃl¹ˆbb`ìªsÿ6'–WÊ†Šàé|V6=ş$ñ óFŠÔÔ~¬®‚r]ÕõÚäÌ7×|ğ- ÷H¬{
ä¬X­¤üêcˆÓ*i‚©È%°ù®ºì‰A±§ÑºÒÍ ¡êî¶u8]%ó÷>‡øG³	›aRZL†wj°Ò{ËôÙ™šº.¨º¤¹×Aô]±ö©“&Ù‚İ-ê;s€¡‰jYdUMC#0D;ö:®PŒä--“W#y´LÃl8=RjJ¾—ÄLãVÃOO0U	N Ivëx]Ô‚GkÕ²àÔPÛv›¬ƒ	°F¼k Ğ1]'\AıÎòeÔtLE”‰‰œYuzİPoİ¯¡ÎrnBXš#^›WÚCõ{00èrp«§:TKöç²æİN†Ü¨X¡Ä±f”Ü£{W’+ß1b“[@&W ìh¾âW²e¾&„®>‰uç_óÒßŸ€1`;İ²ÎÛñØ	R}tä]¹Šesoç3D‹Êš×Ï†6]¦-“šu"ÇGÎ:Î÷õ+"/_¥'tÅ¿u¶­Ë
Î¬£ùgMƒAôÑÜ‡_¤A:xVÈ1> 4C½f–j¸ã¦á5ÍÉ»hÇİi†?ñh6¸·!×"Be2Œ—“3-‘ëP^?F"[Ï¡]Ó°bÙË+l&Q'İ7YS§*¸)–cï·]™ı¼g¹kÕJö8Ÿ»–¿Ãvò¾¥'8Qg¤®¤Àf«y°q›çŠå\EAùZH–‰pLù[¶üáÍ,Õ–‘Yë {ÿ:Q/wÁ
ÒE¡2(3=.½2#ä¹GUlD4›aÜ¦h%ö«S0êÔe)æ zeH×ıŞ9¢”ÖõRnÔ¢d¨åZX/p®‚ÜÌ€{ÎkX_Wàä V®d—ÖkÖ÷:d‚ıšM½äğ0!~í!Š³¨¹u”¨"dá"~ÄÓ‰²qÖüaä6ğƒ×jïæ•~q[ØèSgu°øIÛ¨î9ßu­WtÁdy¡OÀ<’Æ¨ÔÆ¬ÊÙìÑé	RĞ†ŒMä€¯œ "1|j~§ÿïÉPê$×P"/«Å[¹“å-ädÌÍ'M°ì¨Ê÷‚¦Õ-h·ÖIåï’JÉq_ıp×VK×"}µ{€yùŒÀMaş¾–JcĞ€ïû‰hêÓ»ÅcÜÉî¸ä¤õsfØÀQµÎ¶-14—î¢=J	Z4Pâ€V£a9şİ}l2ï“sX(ºê²L9Øz¯mpc¶pkÌƒäõˆËÑĞU9"“„óç±opeC‹ \VJÿ÷Ñ#NìÖ!wÃA²1Ç5v,Ãº5:–1œš •mÜ/×?ÉãúólgÁ9’ám4‹L×“ˆ¾Ae&5Ê+×ñÈk&Vwˆi±ÍèzTÌ}9ãBÚÕÓú¾ƒ6@–¡ÎtÆŞxïÜĞÏ ÊµbGw,,m5?ß1¸>í¦:l,·/Îƒè""¹×R™56ŠpG.' BÍ/|ıÚë ÜåmÛ„x$¾qÂÎS^^*H¦]–ÌìRÏE§‹ÚTyïòÍ_x+[Z+§ê)plÛ¯†´Ö%Ìû[¢VTï„;MÖª¯ÌœˆƒÜ>Š}ÄŒ}Ê¯¦6‡æPÇµ^ù ÙÀR1zQüU¬1¸È†ƒeúÎ‰™İ=NÅÜ»ğuFîÄ§*U#•,ß©)¢Ô›µnô.˜ê
	…2 sÈU§_½P}ù’šÚ~…Ÿó·sëµIğÏŸígbdÔJîÈÍ¹0uZ@zkñå;r '±ÅOT÷°ÃQR-`ÑK;2D©0ÿ*·ÿ’z~¦>oåÍÂX8ÄcŒØP9'Íœ‹ÜE@«€˜“/ÒƒTº_Â¸µ‚'AÎš«q¦FÌPu·a³MtÉå¼¢sró2JXoc†ì3¦Œ}Ó
p¦ÿĞ|Œd
€Œød`)Ü’¸8¸ş;I§ -Á'¥=·O_úN`EãjËŠí²ı¥¼KHqï²mš>–DU’üô)ô¥·)°"¯¬,ï¸$ªæxQ?³OIµµã7ôÚ!·záí1èºCE¨NònfƒUìÁµn‘äI§ä"5¤›õ¿‚¥å‚‹yùKÌyÂ=GŠ1şD*è0çöÏKâ`ŠğsÃ‡p
¡á[7LŒÙ;`fŒÜx·¡ŞAM‡¼a¡ZËÉ³±ySwvçDû“(F#æ®':€ ¬3ÉçÃ½HÚ6¸`ev– şã^»MæzR,2f	›–.1B»ì¡Œt¼ı?½Îh¬>u£ˆT†.Óíf¿ßrÕ“TµxyéŸè?§E¯ƒ|_gXgm p«]+7ŠHL¹:jøsƒqW	$ø‚ÖÄé¢Ë>w$ÎŞb)” ´kE^±9Ï!š;è¯—I½R¶x‡3ˆ˜Êóa›Èw†0º9Y¡š.xÈ]Ú*Ô¥d°Ş§4Ìk¢÷¶‹}k!+¤İäS~8z`&ÔöT4ïà€I]âkR`£ dğ½À[5§J'	)aÚ¢¿D¹¤J)”’AiÖg,¯k2–y¡+Ñbv
{I¥šÿ8pÅøáKĞÛpì¬[]Vè×~5²?xô!±¼5–¸<Ô;¶§ëÈí™ÆL£4íöø@h@òÙ—aşªù}Ú°ÆÖc†¼˜¶f[Z±çgì´C‘RB	«†ŞîÈ¡3ü€%2²æ‹((½¶q¯ò_k°Y°«oèlÑ;áˆ/mõzÔx6Dî³Dßk×AÓ\|æ<“ÚX‡1êOğéOšÙ×®“åŞ>8/apŒÇ­ß Z%ñ¢Ğ9_Âæëş˜½¿'J˜éb·k˜OàÓ(³úûÄÚğ1øMRÔ¦4şPlÖ¶v•š+È’|ØÉúÅ†BÎ°¬hŞq¨Á×ÂEF|Ü–ûøú8·úbôíèQ$Ú-)ØäŠíûËŸˆµeAŸÖôæ`Ùû×º‹)Wµ]«¬ƒ"SÄ$—Z›Ì(’:r”géÆ¹}ådwË å`ÕÎI˜Rì†:	¿å[Á|µ]T¨w¶i{õBóxĞü~Ql‹­køğ»° ;NP¸Iƒ~…ÙßÂ>xÙ4% fûq‹éfÊ™«Hø‹%­‰]áˆæ§Éå-:j ï¯”½í–°fÜÖ.ù`Ø)@–ı.ZCîéy˜L ñoÙ?V Ä € Ğræ'±Ägû    YZ