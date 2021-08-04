#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1498050723"
MD5="e35feaff014b5148317eaec28062b3d4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23252"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Wed Aug  4 04:54:31 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZ‘] ¼}•À1Dd]‡Á›PætİDõåï²Dû¿@ï#‹á—Äçâ¥:u¾¯ Œ3MíuçÇ}ùºh££éx“Í°Ì5¤+¯Áq`9$f.±õÕêüä}r©õL·%» ¥Ğª¨­3÷®:ÁF(©ªQ×ˆ†Ì²QW+şV(¯²ÅÀçºÚÇz³¤°8¾7Æ!ƒ»e¶ÜJG®ËJC‹CPv”¸¯áèeÅWd54¸t³wÀ¢(‡»iùmSlò®C*¿@Qà.
>Æ@tĞ‡ÒGg6$àfèîêA”Jó2K«ì™[ğ”>§æ³}Æk:Xx«]Jµd©ş«ç0™îáÇüîæRÇÌ÷h¿ß }l½û·`³Íà@„Ÿ:¹sÎ òg@ª˜;K¿ĞX[jÓio µ¡rÜWO÷‘vû245@HRDZ	±~…Öj¢eÊq¡œ›Q¬Ï»xÜ¶‰“\Kq‚­pQõ›ºb2Äñ½¨­të-á‹%h×x+n{Åí)ÌËğ:H¦´İşÄ®å~ÕJ²pœ=Î¤y ó¶8Zâr“™}ÊîGÜ×ÆÉ0íßº¢&€i";üĞå7çšéFğ0ò-†fè}).Î3°†‹Ÿ©ò­VmıÍi¿;¨
2G=õ_FHMÅaduÙ¬öŠâÓ±n+ğËóJeïWó†}½ûQäûxóaéÈ§üĞ3iœzıËŞ¿ñƒÖ,‡ûäË9‡vÏœm#/&ûØ÷ßv7ÍÚ?Îî°^Vï”ÒİE¨z{æK³ã2}+ê›§J›ˆ" €mù&¿‚æáB
@j÷!¨K£-{MĞ£A}*»Éñºvå)RWÊšæO¨×’¢iL¼¿cr…jªœ2µWÄ©ß†ÕO±f!‚èÀ#]Ü&¢xç'f¢uû:òç\ì´NšYJ¶c’#Q@Ö±Ş¨n’£Ej¡‰^ö1úïH2ÃÊ2kF¹†ìªèY’ë$²“¼`]¥=ùŒ—¸Ä™i)ßõÀ^¨¹[„ì7íuÏÒDxl3j„c&¶áj@€!Hq<[t?M|`Mö6{e
 ›×E=M–M³¢ã»¦6£h,«öŸÿ˜o Ïó¼UÀM\iğéØ§	'TLqRásâçXİgóÌ´Æúàûı¬õ}‘¡"øòŠEŒMIÿ·%`Ô’ÛCx×iA­ªí˜Šå6Iè³Ã ŒjSşw˜‹D´¦Æá?ÌÜÑçÎ¹¢I~lÊÚæ‹HíxÆ×½.ïi·ì¨»JŠãW8öáí÷6wm‰3\–m“È›/¾Ó²BWÆœ+½Ëb3Ä²TN}T;*IÉôù£ûP‹V”×»ÃJ'P3¤]Ö$‘æ Î’çîÕŒBgï”SuXFØ@•ôyRwğ:÷gW„‘u-kñ‰&y0Á|zé2/ˆ0°d¼ÑªƒŞd*ØÉYrD¶ØÁ÷âøñS,à½;FšÚÓJ1œF¾SÆúÄ'¥”*réSé†i
4Ùï»ok½ÅšÓ­œ¶<¸^ßüR9D-9¼%%«5ßVÓà€ùÉÅ„™Ì²LçÄ`¨±LDÌêÖ[öd%¯ÑêÛŞ¢³ö ŒÀóãR™oL•ïTYÍ1d†³£Ïm†¾%[îÃ¯3¾Â%°¤áTex‡AÒ`Z-TQEiò	úUÁ#FĞ'ğë’>PßÅeL&7ù‚9}şÁ¥ÈŠ°ğóäïı˜Îßx2Ç¿–İ±Ì@bRú¼ïÉO9xúÂN’¹PË~º3«/‰(^Çèy¨ÉÏ8ójÙõÖDS™2!‹ë,=ùĞh6ä«q@ûXâåInËÃR—ƒ³g®´âÃ0óç\fe¤lÜº6R§¬DBqx ãvZ>¼¸â^•øÙ”"
Lßš­áˆ[@„˜“ZÔ×Ñ©È%Ñƒfo§G~Œx,‰/Z¾ "ª²ëèê¸ï]V—’«D}vˆÿ âFàjŸweÑ.Âô©çPCçdQI³šË+\œ¿[vìc«n‰4È5À¾¾{™{’qwvµ¾Æú÷şá$šx–QW3íšêøi!a‚?<ÂÔpKÔxÉnÙ÷Rñi,åıTÚ‡¬]»_ˆş;ªµİœ•X)“|v?	ÆDàm„Zn¢ş#8k!v?*½4–³n=8ªAíÔÉŞ$OhK¢©şÔ7¨ûšĞø¥jyK‡²—ÚÄŸ½tÿ1sÌ´èM,>/ÛTÇ{.e=D¼¹
çĞÍN]\ ¥j‘z$Tã˜htéÍ­Oti^õUq„Â¡å%¦`º3@U*”Ë„O|‹[kÊHÂ,×µ*4B5Îƒ±e¸~I%İ5pÖI
15^NŠ|	Íƒà2öã§ÛÄosÊ
ÁQAÅ®SóH“Åµn·~ÿ¿/¢Á™É^Z)4çe	$"õúnâ(ñ§KCç²Êï©w“H¤g’¨%±¸…*³]¤ºş‘D+@åW7$°%çë†ÚŸoÔèÁdµÂ˜ëS_´„(2QaÛ?ŒmgmòØŞÓ¡É¿˜Æ¦ª„½CVpÆU/Àí©ŠÏ-Äcıwm,º´´ä§_aÜ“Ìùôq×2_oD|¯A§¾…ƒ=VlÃ@{xAd8ø~¸{ÃwäÒÚÔ
ãDoå²‘Æm¯Z²ß?5Û´Ü°¦ÊQ+VÛæƒE2nğ½„&}0yİâ¨+<ÍøE[æyÂ˜™»·e‡,N•ÉšK¥¾“¼@›iIùœiÒâ\<=£û¢?Iš¬QÓøôKacà.X‡ÖL›•>çVÛ'Š†Xgš(XìV¹!°E"İ‹¡‰=ú>”¥¸¡”'>ïÓˆP¿¿¦kÜÓ´k_è
W {ãÏW¯÷t6şDb=¨%µƒñdcGuÙDó9!&\j›JóIÇñ<Xîq)£çè\Æ†Dio­÷djÙ„Rš¦ÿL
I
úr”ã0ıHKnOÒÇ¼şlªÃÈZo~e¹u|¤mÔû—Ó¤¾?Ø¢ÍÑè‰C†…×[	)õbÎ¤À#ó[ù1¿?#F©[mÚEL´”“‘ëÌ,0Ø2N•÷ñ‘Œ¸´XOàMlp]0¹átTk‘¤Í‘ñ´¤©÷hB¢]Ê!Ëp¢ ÊeÃMp¿å'qG*ˆŒ,Â€ÁĞ_Çm*E €œ©2_áHrã÷OIKmö\VK²/ø¸¢ÂÏƒbìqŞà+š;¿kZÉXwŞ;³Ç5÷hñaç_àùÖöÀS„O.¹ç`b™
—È‚¯~¸5©¸á×§Õ„¢ßšG¥ è|ÅûV$ÏGğ…bŒ¹„»êp­!UÍ¦±v!L?d}»JÉêõ"±:UÄ	1BznÛhfÃQºÕùøU~ö a5ÖEŒñXØŞèÈQ¾zñZÜ·†u-œÚ¹±«æ&™cúÁ£frVîß­Åq‹{–Z¶ÒE²Îõe?s°ø£¬BÀjÙî:–¾'kø˜)ÓësûÓµïp¿“ÑNr{&Çh¹,z@Ğ`Œc3m2ük$½ÏÏº{Eşx›õ7ïv™µ_ãd~ZVÀïs½ç áúöĞ(?óİGÈÛ­ÿ%âÃ:¯>¹§bÿt)Ê)şıÌ’NYÚo—<r¡“7´÷6·|	±JÔ^g)êk›5ÕÅVñÉÛ;zòÇ¥Y+ÍØ”­åk²æzJ‘¬¾¨æªãh%s¶¨¦7-ÎÊüöi	†dÁ‡¾Oô¾%ssÂº6Ò—Ì%Jƒ5Åîƒà¡l-Ş‘é…ÁÉ{ĞŠ©à¸º¯ÔkE-‘»†Äø±ëd‰Dê²øÓËs2Äı>½&Y
+‚ò/v2jËd!œÿ˜ñ'½Ö³QÕdUÚ¦LînmŸô;lB4¸CLĞ®´bh±37>™CNZR°Ğ‡ºª0V¯÷x²U'4S¡ÕTû%¥ ¥„†ñLá‰V7‹ÄÿÊ¸`ƒ¯­ş§Š¯B´©-²clpvDc0H*ØÀ	Íå¶¾Aº2dÃo‰‹ƒ™œC)-qâ¼ÄÒ¹`@Ú÷ØW€[Uø%O…*Ç·§“°œ»Åõr‡®ôÂ^ÌÓá:Tı[×Ã•å¤«¾‘‡ŸcFŸq¯´•ÎœEN?ãÁg›±cÌ’a’ıŞWybV”y¹V7ƒIn*pŒ}y’œçm8ı¬î~ØÌÿ”EÀ´°Gá]·¶öfô+«÷ùƒş‰ @	s5iñEë!Ä2üº,ûo•F>½4nÎb R"²ÑBQ$“À/æ?Âô‘eìúº¦wUçˆ,!)2¥é4^{"ÿ(Ç~sÜ*xØ%Ş¹ %IÂìåNíÏ$ûø#8Yñ2¥…šcI‹Z°öB)V	Ó"c2¹a½&û}WúípñüÎë¨v½¢ùTm×P[1 Ï’YçØ/UyY+ZÒ0.k+”¨º³ßûô£l@Öcrô¤©İ¸ğ¼Ø±'XqßOoŠ²BÖfÏB¾¡;XB£©•My¨â³acëpq.¼ÎN)æÅ[¿v~‰¦ëJl[.úZĞ4çIÃ³ÖXbµ‘,’†ŸÆ6ß~ï]´ÎSÑ†w] õ™– 7j|`:Ş¸âCşD$úèÍŸk< N¯;Ô_%æqÌX­ô|™–cE,‡)ÆÆÌ	+ Vš3UÙ°ù­.A Rµği­Ü9R­û İìüÜy¥ß¬Y}25İöÆåehÅ»İü¥ü‚şÓÊhÇ)ÈÁ8‘‘=<ÛU,Müæ¬é‘%.9ÀÓKI[X}Yy±ş\	Ô!ÿí†ª›¿ÊLıœwññ­ƒ¾¼ º½,Ô°¾a{“¡!5ˆA<§‘_ò†,ÀåëÀ-ìÔ®iû«Tt€Ãt‡Òj•&›Šd9şäE}îV_³,Æÿ_$:wÖÆ[MÖ'ñ2‘æ=“eƒà¦òÊVÿ¥JŞLOípé^lî„ÖdKõ¹‹î\Â¢ú~ì•…‚áB~:|2õN'Èx-¬YZŒ„VpÔ!«Äx‚ö‘ë×zûCƒ·÷ÒÁ"¥•t²L‘µğj K	6{ïÇ-îØ
F™fDÁ‡è İˆ›ñ÷¤"a¹*ÈÕƒ¤JÖ³¹E¨;ˆÊyíkâdñ£	„d#LxBÆ¢1‚órX +
Ò3ìv¶Şm’L¹KnÑÜWitC¢YçÛ¼oªëxaw‡‰×Aø½)hÌÕM”ïÀı0û°Úñ7;Ş`FÔeàBëZÑå×­<±™‚ò­°;Xc…ñÓ%Ç›0š-=–š£ÖnÚí&š£<ZÇî»£‹eãk^t°÷	Ão`şÃáecÛ”íZÂ¨uSÓÀc-Õâd½°æSÆßÎßºêr~ğ¤Ã7|ï§{˜`ÁÅM°zV0Ïúfxê¡[(6U–¿h{S5.ÅÆ¢‰ö…çñv Åhÿ¥|„ªö,y„ğÜ™ÈĞ3ä[\ªÂ@ï9_cşâ#[ÀÓîi%ûˆçcW¦ÿóÆ9—ôªS+?éVB¯¦Ï|iËîY1ÎéÕ­­wäaÖ¤ÃrV½ş.=ŠKZärø’ûj%ş'^í“Ş·4çF=Æ&«r†?òğ
·Ş§ dt;.0Ä9şZSÔ¾8÷‰ÛÁ‘Éu
LÂşîR‰n@ã¦Ş„>vf@£o²Õ¶F®¢›œÌca.ŠŒ]ì–ÉeüI¤CøËp¿é«‹5FAªóœÁúñáÿ–à›puó;
82H»“õR;€g†MR%CğCK9¥>DÌn ^Ë:n«™FC}NÂï9Š*pèt*­dG[Õ~ô#@=ÂşŞ9ÜmÈ•p%¥išË¤¶~ıoèŞ‘îÑ?8hÌ¾”<ù×­±7¼ï¼“>¬KñU
Ö˜ëşõ§PŠÆ\Ÿ%NËÉk²}”;¥±RÓöµî<_‹”·YÛ”×7üşñ½M~{copB`ßÍ{5càæVa(qµ¥«¤ê_*eÎŒ,w=nyìïÚ|(N$k4Ã¡
{’<³Ep±Š|Ù×ï)c	ŸßÙVıs6„â,ık½Ü9¯D«Ø
«øçq9ı;Ce¶ĞİkH<Ä÷=CûûSÅø§3	É¿×ÌUá`Ävr c¥µÇåğ-:=l2Œ—oêGkâÖ{Z±Û_ğşgÎæ€.ŸpjË£a…­Å†S§fâñT{ÂşÅÂhá~¶Ğñ6È–'hF„î<rçºF©âá¢[ëë„’Ùm)Ï]ˆöï~\BDG†f—$Ş¯3°„†èh9h/¹r)å2Ã›¨4t
Q'ÑºÀ…W_1ÈµÒº¥¶›Fb¯sÛ[3³ÑØñÄÓS4ØÃñĞ	p¡ÿ­ôû/Tvr¾'P§A0\ò†ÓÔö!ì*a™“W¢6ÜRÒs’×¶æ…_(?ÃÉÙ4Z ¸ÿ²2L"œÒsıÅ¡Çq
İw„¯2{gì³A£ÜÜ÷•Á%\ú«ümËP£´À1)±Õ *µÃ€©:Yl+Ú"<®LÏôóE£ëLş•	{nˆ‡,âêğ4Ù0ïıÑgi6µK§j$‘›øq+YsîÖå¡Å÷Õƒe™ó¢İõÄ?sÏK·BÚp;~·IèEsá¼Ée£¨y—íÑT5¥EÔCúHàérœšaòj‘°+èX£:p/¢4µ¾ .ç¨jÛ²:RÔÂÂd™„tæØ…l\±¢‚	É“Ñ†aÚóe&ƒ&pûo>?>>ÍyÅOñ»ÈSª}¶vÚ²·÷S<Âñ¢È£Vßõ³¥g‡	öº¡?ê²-½±ÎF0ÉgEá`”Ãßn^ùóêµpî¡÷­.èI j’R/ù¶¨“;8õUúYÅLèH¦ğûÒ·ÎÆŸ©²£udlC­"å’BTFÆ£9aÕBl^üÎÇsºvûİ=ë É?uÿ'DÉƒzÑ—¬ãûûV%Ğ¸¹­2Sï’ ’S±ßú„Ëi}´…„ÿ\ã†ïql+Wr´rC¡»ÛÔİõó$ñ¶Ô}™Ìâ3Œ‘}Æocéé¸ùÌÇ~İÔÎ¬AÏÆoE(“±TWÛÂïq°i'‚şÃâ¬Ô`7çå'b?Òñ…#5ßí¥ÿÂØ§fwTÌ(¡Jàß6$|ËŞ½©±ÒŞ­sÑ"XÌ¥™¸Ùz'lÁWEêoÏJ¤õÌ­çŸ3å§¶ò«„€ñº"9Ú3dnWÊgUğ~ bUlªgm‘ì*w³4~û$‘r¡€ ´8¹ù!S_–IÖ_Ö³Aì?GQ"ÏRnµ¤ÃåC:W½ylZLñz›GH4„Mæ?Hİ†g×¼‡¤­ô!f[F°HÏZÒüŒí ü£<vj=Àlàü™ÄPàÁ6nº\„41‘2Ù€Õg‚ÇÛ\üRyoæÕ’ò3Yé!¬€ô%6«ı×= ¦Wíø	S FLz¶‚Y«£óÆ@—Â½eRy öäğœD9÷u§Ü@íj\å‡U°ôÈwÓ…TU—=eÇ
Oºï§%äBês¤á@ÊL®Gaİ`]†ÀZÀethGî«x”Á+Chåµ2¸¤áCe¬ß?ç²Ñ¼¶“=÷¥7 ÿ-‹°÷Y³oq,fÙ•x™±ia*&øì{K”#‚äj‡œU`Ëşšg±jšSœÚ©ƒŠıà¿~‡z9~,	íàÌæ÷|ê¦îãºnµG4˜!æÁÉî<•à'¯‰)Õ€¦ş¤ƒx\@¼Kr–ò„÷¤È-‰H
ú=21ç·öW8œ‚Cu)T ÒèiÎd;éş´¢Õ¾y$G0øô<‘Ê
ª[dÌUéûNç>‡!âÍÇã_Êößpá‘8½·õŠ÷Ïºk¥ÿ•İfkf æ]•Ze|T,!?Äß˜äbËyY°ÇH:K ^°¡ÛjfşCÔÑñò}5fãw¥Ù½½fªÙúñ¬%ÏQ˜xá.£hÉ¿mÂˆ·^ÛºOâ8åÇ˜ùW…IZš¼:ä¼ñÏ» m¿Â*‚™>ÒgDŸhù2œ¾™€ÑWúÃmØX`Û æù»:w»åWò–l›H­ŸC?û³xO#Üd'øôeUû§¹baîèõièõ¬õZ-šrcäÿXuU/œÑæ}à(%Xm²-ÿâ­}U£tkyÁ‰Å_—#‚g¤g«ÕHùVpmò-ğ^Ttd©°¶£ÚPW88l±—§?7CËvfºíVà_¬‘’#å6fa2[‰JÜ®[×ìW"Š‹ŒmŠáo?<ûèê]Î¡
¹2ÆTiPySÌŠ 
¶V—BÉü!A5µÈbPMƒé
R¥qFÛA™¾qÄ\ÁXÔ¼qIoiïD½]§,Ôºú.ğ©Ë˜ ¥ü{».IÖóú«³d¨ô©…Ø®Õ(,«¸Âseß"Œ»è°'®ßŒÙïRıyïëı4V<ÇîePşWƒz°xs=”™U“¯b¡=&u¾Ä¸ñ™Öê³^¢"OàãæÚvòy³š]„\|Ğj‡—ä½RÌ‡q;¡O	¹ÕÃ»pÉêñ	BàòäóHBCHa—É ß¥™]ˆŞƒ~ +]iÿPÍÊ‚$½>à™.•PWò19‹`å‹î×wy’õØ€jíŠãßŠùÎİ®N¿ÒFƒ†±ä¾?|›="4VíB-nÔ¾@£ª{(7HsßÚKnëk²õ.Yº™àücÖí ªìã*âyš¾ÂÙ]Àè¹¹n•£}Á}9õhËF»‡Ÿù+á¾¿!ğ"ÆÑau~ëÏ“ 7‘Jt4­Ú¾Ådx¹×pír¹G*
 )ÛÓYDãYeíğ¶D»‡<&ÙPt‚FğcBvsõ@Å«µ°âÅ½{—ls}j%ƒ‘ê³»Éb" !Ò6ìÑ‹)†9ÓEfIĞ:3¨¤»*…5J×H#Œ±±÷3ñd Qê“¥†)Üºã¥fEã¶$J+Ú½2¼íÏÁºDÎµ½¸m¤2÷Mµ$ÄÑØ?½”{üÑ¼Á6²´­-˜’neD "=¯Ãbk?nÎÃŞ25r?óxR¢Á¤šAy\*b[³ëg (éó‘ÖåµÅecuu‚5=oĞ#çxmY^ÚSœ¹œâÚîÉ¼ĞfTËğ¤¤.Œ%‚-å
1Ôè˜ö­d«$;×ÏF8jÀ‡W\5ic.”ÎĞògØø5KÃ+â&“à¦ßbé*JvH)ÑVÉŞréûìKú?kOä’îŒ‚ÏŸƒ¸şÔÚÓ(4Îa£2¦oıÈ+î;JÏÎª¿êØrŠ^ÉÀW÷NºÂ±)`ñ”#£Z!¬µƒA¸Á­†Õæ	›ÛÀqÈçG…úı¬‘Ëº6äÂ|# h.Ğä¨ÕØ¬şÓYÚÌõg °™(v}©ûx;HôÙ¯¨À^zó±µ¥ñ5“ù€M3,Î·c'ä>´yM¯;ÅR‹”SQDè¶Áìb½k= º1©ƒl-;ƒ"ÿa¿Ã$Ó…¡z6`€™g!îà·÷e(-qÚÊ\ô.·ŞKi/Z¯4pGù”’ut‡…¤ËØ8ä’mvR_TD´VÑÚ7ğaQÃ¨Ñäy&ˆh:™Ê[¾ëÈrYGR·'ÕJÅrS¬ üz›¢öÎ…#“ƒHLüg¾†%¸#è[|8ŒÃ¬¥tXÁ”8Ì;Á´:¼»F<`ëÔ®5µ$ö‰ŸGMôöÍ]C;£÷8ÉRúœî¥&™Kİø¤¸0Ğíí„N‹íÿ,ªLàıP‡{TrãŠÂIdå¥¹-ìIŸ;¶BÅ¸sÎx*Èî?õå)"{^„'ùy™tDÛÒK&›‹]([ÿ*¡„ùïC]È¢Ô;’§šõkÓoòŠˆ‰”ËY¯â¬[Ìèlbg ¤ËØ1%+¦•Ö²¤¢Ü[ïĞğ(WÄœ³?‘Õ#,»Fƒ'¤èI"˜¦ æø!±mŞ±gËÀ©¥V÷Ãq«é€€õò˜š¬•ğ{Œ®îZ€ òÃ=¿­Åû†*hMÊJ§ È€?«×QÛ •®÷ÿ;Š¦‡6—E†¥ï5JJÇÔÀ~=ûwG1óu)kjaYOCÿ¶<:@•ş™ã[:³ÑTÙK‰†Ú>Üiaí(Øù]Az!ï†å²«:tŞ_Œn ±‹Ák™ìÍ
=;s”RÄÛ|ü	Õ‡Q_~Ã‡ +mO8ù%2Ö®/(Í³r•¬Fr	ï™q©8=NcìŒĞ¶Ÿ¹~ë8I~‹#Øî¸ğû[RÕ<"¸âŞ^z!qAÚŸæGZUS]ır­høÆ!½>yÏ§”f^Z®m†Äö§¡<¸c»ìlô4ë]J„š¨‘¤¯_\A?4aÛ…úÓ“ óQ)Š|ddfz“[*D@Dâü¾’U¦ ÑßFM=Pk«ö‹­~¼Ê³ï^Ñ¶¶ğ³k|:g<Ü®ŸÉºCƒNé¿k;úŠVÃşÖà¿¶Zm,’Ù[’R>•i¥9N†~ ~k±ñ=…ŞŞ ĞĞ¿Ó´õÚmì«í 7ÚüHÈ÷.øà$%Ñ,.h÷fw3uÂ•–=0ºiJşo×Ã±ÔÕ@ö¥AO±Út3nSUäç˜›à;ƒˆ¦Ù¬¯1—ˆ°@wERjß¥6&w ö›b0/"ã÷,ÛñØÍ©3ÎÕ†MM÷‹[<úD•ÀîÎ‰rH¼HO±%ãoèedÏ·Áäê™ÙE¼éäDW0…xOÂÄÕñ°‹é`kÜMsœÑp ÕGıx;a¥ù¹ä™@-®G·(¯2K£Šá1‹ö01ÓaÚä êt¾ŠÑ¯Ï1@‰aÔY¿Ô=F!ì7H.Â³É¾…îsÍÃ½ÆO€Br2W&	Ÿbê¦—û
œ/hQæ„Õ·’%“`u¹Ú£õG	5&$Å3åŠè¡ceDZŒ¼9]Uú¶ULqAÈ¢úo$IN³ñ¯û†xe@ŠsüIÿ	&Œ¯Í0K$„Ş‹“ï]>é}’RéSIûJ /†×A«RÆ³ıáÎ¬ëm—óè/9ÄO³é!ûêE®F4÷L–Ê?±ÃñÃıİõMÁ®Õ{ÔrÙ_¢)\GÓÍ¤ºFQ>ğ#!¶n@Ì¾‘ß[?8#Âàª¾æÏ"¤<çIÎìÜ¿/Û# ¢R„:œ—¦?=¹YYº¸ù½Tè×İÜ´_ÑK&–å'~ĞÌ¤!½jœ5êmŠ~‘I)iñ‹Ş;72lHß}	9U¸ê”ü¸¤ÿd®»†ğ>½j»ÛáîF.Û½¼®*–Òsì&ÌåıjÈU¸Œ+©_²_[‰¶ª*æáğõ5Ñ¢†)1Ö‡Ï
Wß±µ~ş}\Û“M‚pá¾ñÔ‹Ö/ÂúœMë.ì^·L‡BŠÖgˆ³ÒR
¸rìš|W&j¿m&NÚnîà–ƒÃbånú6‚]‡Bâ6İœ(ÙÁëxèØ_dqxJå;zûª\§<M¦8mZŠ|Íë+©ªeá¸È°³ÆnZå¡â"_=iºÔi]mˆË@BğíHÑ‚~ö/ªØK:x¥Æ2Ë²$Ív§`V^<ÃY·ŞwşÓjtdÓ{kŸØ\¿D£¡UeˆŞ–ŸïCz­œ€±»ó‚ ü¼ß†çŞµ±;ö-«39ÓxÌkì£>YbFå¨V¤û—~ÇCºUÕQH–&v»‰{ƒ-á÷Â[}n8xl7 ,·<AóªÊ|í”>g^ıS ùû‚ ­†''3ÌÓ7c±_ $CE³si?šï¤ÙM†ØE–Ôäó˜™êÖ ˜ìG‡Å,åyMµÜıì`<ô¬NšğÒ¨J°	8¢ÅŠ¤1ƒĞé2ô¸&¢úŒ/©	±@•ÎÃó¬é!D €Ş{ûÜaÈ$}3¯p{;6äû¶vÈ›ê¿‹1¡‰ûT»¿F[¸İå"YÏŠÍ$«çƒ$Ì+=²İS×<	,‰;|)¬Çh£sMñ‡Ä
îÓãpÀ˜2©æÖ}k–j×°'¥¶›{zÊÓˆğnÆÒû›¯èãIÆò‚Úêø! N=´;X×ëzu;ªŸó‹Ä1}¦‰Ìyï9R¨ıaÁ‹xZL@c=Ö»p® ^ú”˜†Kß°’-«[•§•„İ-%k?ñAİì[d¶—‡·ÿsóÈCK ¨ÙW <¥P­´)*2Æùy©í½½†¼Åø[¾MDÅ8¿ù´—IÍ`ãìâRƒ’RŞ4Èå~„Ài$“$<ŠAÒ'€·=“È‰¥ş$o7:Å~p¡8ÛiZ£¾©åêF³_Š‚2Ã^	"ÃTBd‹şcA¤ûyÁ@ÙzäK•ïløß¡r¢yóRPk³ŠMÏ—‚#¾(›t8ó÷fc/tg¦-3¶"O-±ZàO6":qÙ!ı­T3úCqv‹k¬ÊC`E	§5¼ÕàzöF¤™JŠé¹	…³‚Ğ–{ïˆºÉb&%ëd¹›pK'ªêˆıÊŒ“>&&‘¢s"ÛY†È±¦G&l6ŒdNSs[êò?­¨Í–p{åœú­pµïG6c…m_ŠµÇŒ5ô±~ˆ¼É¨ÀÒŞøX.35?ï­Òæ9W‚}!
SIK…é¢4s5^ÿ‹ê/â-Æ?œ`Âv²tÖ•g¿ë{$DåÚÕ9-€ùÕ×RTÆ:À ²m@¬Ouü¡áÒd„åg –1yÅ9Ö!ŞÏá.QWNè}ìÊúü™&­;ô¾¡i¨$º†b:<+Íg“e1¼*U	7gOK³ùÈØß"âdTWv˜ÀÖ9Gsç2g‡ëÏ@áUÙ~›öŒmIX¼ïKØåfÕ}gå‰˜4‡ØŸT._õ!nÀ,Çl#0-†ÖŞYÄˆgÑ2S+Ä+Ú¥f¦¿˜ü*úíŠòZ$"#¦ÇDCÎe>‘øŒš3 ò‰±Ê»ñ·©÷Úƒ ºâ×r½`ÍJlrŸÈz4©ù¬.•éÖ(9 “bøE²ûŞ‘Ulqø©6D8}¦sÂ˜{øUlÍ"SÕß@ú7{Ìó//Œ¢w¥“IxwŠ9v ¾BR¢<+'"ç¾ì˜ä@8ˆŞn§¥¼¤Xçƒ 18$Ôğïši˜ƒuŠÛÍÌç¯ØÅ>ÆxãaS‹÷¦'IËã=qä}8[DTíZ½x¥y¢‹m4øa2?Æ¥Ï
ğ~%RCpZõB#7à@f%RR}3\­ï¡¢-šˆ«ÖoøŠ÷…•v`$²ñÆ«/†[§K×/Ïê&ä·ÙRÊUQÿÎ]M%ëZ×x‘Y;G–ñ¦´ïON†W!P·,à y]°è•ŒŞ©€J½‘¹š<Ü‰-¹óİšçá[èH)ˆÿ`9äA2w2õ> ŒÀİG@ŠÎ¸¤ãs­R±¬]Æä¿"ŠÇ Pÿ!êÿKaï¿K!?<ÄöÍVÌR¯TÈıDÎjš†]d´ÔÍc)˜¯Eó¾qêÂTöÑtşû(õ4*êá¾º$é132_;´÷Ÿd¯Vô³ğWÛƒ<|^my¢b0Q}rì:£
šqŠ‚—”‹,Ú•Ù+`˜bwÛ“ì®Ã±„p¿¿Âæz]2Ï‡»sR,²4U&Ïüåğ®sÁ»}&—RqnqÛHTXÄÂ<¨…ÄÊoÃ±=ÔDe÷AĞeÊ¡±ù5îÑÔN3¡lO]·º7å¥$A®ÈÎ4\Ş0†SA[q'qÙx(öÉÏÚòĞ#å!(Œ¢c ¼ùªÉœ_Ï^øÁÓ#àpÛS€ªúç¬O&»ó×ùÃöåKŸ_`únydAúŒ^7ºÆ‰úÚ#Ã§,ûÖÆ´uØ|`÷‚ÙCYÿ»üòQào¹_#Ğ½ùR¼…é4Kõ±Vú2Øí€ê\Ücòœ	dôäš¬'LîSÂ6F–"˜¹Ÿ35wzW‡Å³ìš÷Áÿ™‹”.z¯â½Ñ(PŠÈ—Qİå(M
|¼s~C[šİ>=ÔÙÏİêøjJŞD:Tã»G¹"y‘´h¥.Rø9¹yäëßlLøˆÊ5RÊŞüàõbÂ5zfy¥–äé°ı”8ˆÈ¬™_t#2Æ´ÍA¾ÕCz|X¢RKŸœi6©­‚j¿Èöaä{BmMçw\¹C/>ş•6Uêø`4Ä[4¢ã`ÚiÌğØ¤´l#E!Ô/Dşšî/ãaL!±eÍ´báÅÇÚÓ“doGÏİ1Ş¸TpV®şUnx;ùI<¢HJİU8ç*æF‚¥bŸ˜„‡N¹•ô§LâÓè|¿Šş‰aPİÑÉ¶I¡	V'>äŒR„´ Z®Ô•“hE•¨Â zğ±\6J6]Ş½°f(Wlãb:Ä­ëƒ¢ÅVì‡ÈË6àBìÖÏu­º8ˆıC4½ìpÿHï¬QaüèØR|€>C¸8ÇGÏ™ØãüÚï‡ŸPìF:œÇóÓaúƒ¥˜·{j0puÍi·Óõm«YA¥aà6IŸ4\qÖÆ°R°[pş-³r¨¤ëÜ4äxÀ`	ÌÉ˜êÀÊg}äÂP0Ø»Gn-‚#ñàœIæ€1­UÈ¥9‘öÚë7 ›]ã#ğ°ìm€aVAN€`n2âş¦cƒ9¼?Áš—)Öú'ŒkÂÍŸ¿U-çÜ6SiÿuŸÏ%N‹.7/Ë¯%ü§Z7%ãKE8šdÃ=ÎğmªOáU’W)½d(¹Ï’ô£ş^»¿ÔçÍAJcJÿ’Ù—ıòVmU•«óv#=e`iRyùòzïei…Äz“Ğ‰ÍB¢%şµÉ0‰ì»@~ç·¿»`Ï2@€¾ãh¯Éàt—¸@õt%Àh¸»Æ¹[Ù^vç†ŸÄ$º^µXùë^
<J!m3>;Ç`)2>úHódC€B>ê±´Ú¨ÅÓ_V”é¯j9H]š¡eWñæ…3pb1²c:tXùFE'ã×âšoÉÆ›‹?rSŞÌÔ¼ÃÜîD4)½‹<zQüé¼„`»Œ”–jtµøP["ü´åÏ!…Ü‚e`œİPúêä![7{€]¨×£Î[#‹I)òé‹âÄ{Ü6J-Ğg¥ö$}e;Îú€71P˜N¶TÈo­+’*'ù2$´0x2·»ó¥¹:5³|…]jc%­aåºuCWU®J©ZDÖyàJ—. 9Z÷³€´_°ù]Ş§]m¸98,a·O9˜|±”áá¬€âÊÇî¥ËHóÂ£ÑeûB_=ÿŒ2Ğ3%œ§D¥?	İÒ€rĞc…ªãqÑ)Tç‚0áÃs;Ï›¼PFJ˜ªy5èMcši c‚	qÔøxú„8ó/,Ò5Â%?w^&/‡&d³ZÑ6ç~UT©j§òvt¼Ö‡Úbæ¼Êüû¤9Ü®¦õ²yw³Q¶-8à 9¶jíğNM—5f÷	1JÇ™½‰änÃ¾z—èq‰ä§¢èòƒúõõ¼Æd³OöY'"ZMæI™sşÒyP`5?Æ¯p/‡½ÑËaÿš}ä8.wîèë0•v<@uƒ:vôí†‚Ç¬]{—@ÛÄ!;áËˆİ]`DlL4å'RõV­?í«ù‹­„¾NØŠY°LÕ à{ŞtïD>‘)¯Í|˜
2ØU“LzÃ/İ_ËGUÊg±ƒŸp5Ë±:`mBvÈ‚¶åO0:¤tt@“©¡#Ñ{C¯.YîRwO–·’A'¦.#aê¼»©ÒoÿDÂË¼ÙÀúXÒ[?°x¶9•3&ÓÈ²ÖÃªK«1´ÏO_R¬ ñS|Nw¡Ë<P`Û¦‹GÉV˜ õåß¡Ö²½•°V9%:˜8››|ş&;ƒq¨ŒgõŒëg=Ø&¬U­%ïç—ôYÚ^€Á\ÀSK™¹$İ5+û]¢­—°Ë*h!#¡±hÇañ› QŞs§J.â
×+%-•QÉôãç®˜VŒ’³²Yƒµõ&«©$Ìsh•İQåõ9ímà§;Ët`è#8òÒ%ç;¯Ñd]n¥-ïê~êR\U¼
Â¦‹šUïÕšü?£
Uö¤„›È’)”­ŸÒ?àÆNù'™Õ_Wræ"ŞîãÁÆiw+õÛş>Ğ´’+ÉæÊ–D#mõÂøÑw8dåä‚î92‘„ù¥²tŒ/Ş€.Olgİ¶7Âg:Æî²B<BñNã%JRaëÆºA'PÁÜñÒÔWK>Õ!”Ğ'¦	œ–w÷CàÏ]—"3ã!7Òš‘‰Í])Wf)‰#êü +Zd 6Ül<NçĞ“±ïğ	èÈõ1ò_ -Ï+Ã“Íµ&æˆ3É{ç”İzo¡R30é>KzT/Êûê%#ÕzÆ~ÿ¸ğ  ldzV‹]AÆ¾è%-Ëÿu‡Ô×¼OTš¦&pníAv®ÉHñg©®/k”eÊx
1ªqÕQouÄ0rKÃY|°)Ú?r÷Ôgâ¹rNyJ^VQG=s'Ä+qæŸ‘ñ ?óU€e$µÉ!üRïwİÔy İ ş‰UE·s†âgÈ§ì56ø—²ùÛ¦õxG;yëÆ_Õt¦IMù¨ÖŞşsgƒÉ~—l\Y0·_+É¿¾f…,,z6yEÆ`>h^Ùëfogú1L	NH_ÇàâO@9Àúz«‰€qÍ6üi|“ä8ıc¨ÈëyÆÿµp`)£#8q.Pbih¢İ¹©&‰ıÍ-àçÜB¿§ Šã#:ÀÛT=D<ÂâsÒ`~2)†Îó¶FÕDÉb˜˜÷Œ×=ş&eÚ,îHhğÖ!§¤ºÁ¿¨O8lÙ±ÇàC"ä8şo9×Õ¡Rµ2O4¿ß#dUòe¯qÉØ“Q95Áÿ’yB…²×–ûÏí9Î,–å,ğğ‚.ñü½HF§\`áºãô9<ıË™o&X|g’­&ö¯¾çG&RÃæs*‡]®á¿îã<.¬ûk’´~P™tİÄ•¤üTøY??†³}-İdîÌjÏ, P»)Äß­H‘0®£{Ãû¼©s	ŠèüƒŸÜ]óÑ_ÈcÇˆúxØp¼$ÁsòØÒíK
¤>¾3ê–µŞâN"ı¹µ³ <“³O¸¯ûŞWÅ<~‘­&ğÇñzwút	™ƒJ=EÏ§Äß\”Å‹^×y;Š>«l›ä~bDÄ®Ì:¥³Tû?Mìz{$‹äM²Dü'›A ZTm>ü~O¯s‡"}å÷¦Ñî- Fƒ@µIûÉd8TÇÁÛ¦  ¾Vûgî‘xŸeÕHœoáªM¥Øøk§ïá” r´>€’ó8&7¿YÄ)Ó*ãÛôh)KĞf¥ÒÅ˜|€5wLîƒÁØ÷°0é*5ıÌ¡‚G™O®l[åO
MsãÀ±fÀ–Nl°¨b5Â²­¥Î	¢"ò/Òâ“·	Ëó<F¼à¡¿hyvbÛb[¨By¬F/+nó7+oŸ“Å9²“_½|èS% l>˜‘ĞT¸‹FêŞcù4ln9k—Ö™‰<É½Ìº5«ûXúİ½*õqŸ¬œ«¤i*?új„xfÅ°27øq-ìµÊ²ş*¾ êrtÔ£‘Q|âëNÑ:N¶ë<Å&b«g®Mún™İîœ8-ø7q"^Û/ACÁ«ş&GÈ$Òs’Š¯3çxœ‘&Í§D!7±ì]*>Ğc!~íG û}ğ©tõ^<a
2íV:©yÀêË}ˆÒè	ğÍW	¢l Ò „ò6”ˆ„µĞ+¬
 DAZÅ–89ø;tI¼”fŸªV–´µIÜx(kh¼r¹œ‘wTl£ñÂè\Øä¥}^2\5á.Ôû‚_á/‹E2ùWlêkTE» ×å,ÑÅ¹÷R$O‹1Ö4ò˜1ò_Ä5Ãÿp]˜Ÿ½Uú]kFŸ4ÔAˆØ/Ÿ4Ö:Bmt÷ø¦õğ§fÂQ” ¤Œ­şºœèÁcâàXØºN­ÖéÂş%aï1eŒå‘H|CáP&æ×$Sûi4¨Ö–Ó)Æ‡pn*ËPÊ™SsdD«3àG5àu	‡G†…2sûæ(”J{Õ)Z£!KÁ¹‰WY™ÒÁ<8SlÌâ¢¸AG¤ÕÎï>
IÉô}6s™÷ëò¼¿iÂAC¦›Ÿ‰ÔçJØ†”_$š¡iÎ®a^€¦Mé< ûdÖ?ü¿zˆ›*ål	bO‚¬ED;”™`€—BëKğYqBÜL·+@&f²|&l¹Åê/ÕÏæyÇİûÎAâÒ‰OÍ™}ÄŞs‡Ğ+CÏt±Ğ—¿J~OŒ$N_X{PÎ(ŞÇVÄKè^qÍíiËLi/Ä„ÏM°<²»ØÉ"Ã9Şnq£3Nä…]¢+‘» ñZg‘  {ecW©­M‘jIƒíe'cÔ9ÑÕRàtÔ\LBùÕ¦ùKÂ,Íß—S8!h‹sğ'#>­B›ùM³Qa[`÷BJ—aeQo¸p2Påù„Â¼&‰O¿ÛC2wœ*ØE]9í€AÎá<5xzB?·±a·¨|©1C‚@‚é¼r·|)´‚éJz)Ş&í5¥yÙ»“|(Ò4§Èß’ÏdĞÇü…5–£®uPğ™|TGçÇO2¯L|†³´•ª>ÔOé L×EåhérKA‡×C¶Ê¶‘©oØ¦qCQ½ûõ{`xûGö#È‡!¬lJnÇ#ÅDÕJà®ÊÏ
>Xò¡ˆSàw1êõNP¨^ê7‰œ¾ønoÜ*vfŒR£Ù@ø+´]Ä»eë±¼î=ÔîQ7|Ş}Í¥¯€ØÒ¹^ŠŠ£á‡ñi<»Ä¶UJ&jí	Mµ5À5dë«2_v6W-7G®Ê˜ı›0¼iSÖª‚h§MÍ›cÏÓV×ºV’µådÖøü±f.JGFË‡MJ/Á5Xï´b°éåããÅç„4¹Úøf§>’Ô6ná;cƒúzš4â¥âïYò ÂÜ­i?Æ>¬ğ>íÿo¢åşßKÚy­	%ãId(©áp’µÚcJÎ½~ŸÚöÛóòkÉud17ü‹©LXN¸£Ö€Å•Ø+2q(\2ø†ğ/Š+é‰ä‘"Vrş¡Íø~ì…V·áˆÂO0
ŒËŞé…¬	»õ·˜Llœş¨ÿßßlÑ.êà‚auÆÒÍ•C)Ë(@{_ª^ÎÆ!/tpûqÿÇ‹«âm99×&´LÖB¿Ã”'„# à}ŒğÀ‘ØÆëÚµ$ë•à}€Š¡Éq`0Î€jds)âšù_˜à^ªJa·R(úeK0éXDòM±Å:î±ğùFQ+€í]Éï!bCPi”ğÚ¥ ßäea.9õvîn¬5üå.Î)î:ÒÚYúD“ ëÂ"2„È>{ë¤#Ö…¬¡şİjÇW-0ƒTè•Œ,“N‡Ù·^HÙr)8kÊ,„U¿
°3 H+dúúdÇÙ¦†jÎq?¿E'N¯dÜM©Ö‘#D|‰£
ÁkDVÙñ’¼d¢DGĞ€ó|›wÏˆ‰[ÃXŠW2qUdD½qÓ!~LîŸüäiÉ:76Ì2|6ÛL‹¾ÒÀQô¡! ëŞë©pø*İP¶¥}«Q‘Ï‡ê¬µ*ÃË8;/%a0”[šM‰y=i_rÂ›ÊPª7dMŸ`b0FÜyK¿Á–QÂ‹³bbê°J¶¦ø§½î?b½ñ!¼wóúÏiÒÎ×•µ¶Ô‘µXéÑWt Ë>½£¦äs"Áz„ñË9Ît>W©2 h^«ÈÈu„IôIÓæÇ)İ‰Åğ;‰Àj;}øÖ;¥-\5G„SIôZĞé^hR^'OÃÿ7ãq àŞ¥ÃÒÜ‹ñ8ñ8B÷F-<Ç_â›ä.=‚ßæ¿»mâw%úzödsú“~vc*ğŞ­¤Òpğ!(ä­‰K@ş„–LA·)~ˆæÈ<Ø™‡ùçTˆˆ¢=Ë6¿dbØ6ˆôÒŸó‚cx[—…H"„‚°o´IÀv±çÜ•…i­®˜eÒÇ¿ÃÂc!èw«‡ÅŞ“¾å›Ê÷Üj2ÚŞ)²ÀFµ´‡@9d™`tçrn²=ªûeèôÃÚÕ"-Cåù^Ÿn³½ĞòkMŞ@sÕJ‡`"10ÆÓf`â‡Rní’VœM‹eıùó.p‹ş¿vàb
]ïß)§
Ğ´ğ+ÃÓ´ñ¢×A”™ V¤ƒ ~ÏÂÃ{u×‰cÏ¾ Å9ºBóûsÈ4½št÷Ã\fyİ5ëi=~àAè­*(#Ñãnn•_ãó°5òİX¼ÈVqò£GM·àò© RÚ«öÏƒkƒ¥vu™ÀÓrmî3=:K»Í}™¥»…6–C·®f¬xI_Æ+Í¥Îlàu†ÜnôoñÜpc¶#œj´ék¸*éñ¤½ä¿İdóÆ“Î”B&Ø¶Éõ3ƒ[ı4`114ÇpÄ*ü(ºİ¶å^ùtBÁr*ˆ«Ÿ‘â1âÌaÎåˆèx¯W'*ŒÏ&"—é·ãV‰“ÿZ²¼]Ú0ì±­ÊÍ®A}ù´iÊøÍ•gdù+Á=‘0HÍ¡ªÃæ»Áf‡5ôe·ÿz4Öb”Lï¡+òºgŸ™Ôk†Ù\iÏ8m‘E”è7:Û_éà‚¢ed„^b¶To«ë=ä#4ä¢5uJÔÄİzêT4(Hİ¤ë«4;:¿èñó4zh?ªå`í“ÂÆQÓ„ÈŒô ”Ùº“GØÊMáËê-¥	Ãèº_,éÓl=ƒ™ûÅ0mv3|0Í¥©)zbw&Äö™ód+<$5wëÂX'{°üùÛÇ$&aD½[â ıÇxİLƒFJ*"IÓÓWº^âŠ$¨¥õeœS-©e°Ç¯ˆ,?¡‡ş|§|xÂhÖ>·yvç5Û‚ğõLÅùØ½¥k}Œ;N^¢–îâÊ‰U™RÅg¶Ú/Œ>]qˆW,I¬ú‡ıl¨v…¥®Â÷9wKváD‹5³²ıÎŒÀ;ÙÏÏŠÓ°R«'PM¥À%Àt©hÄ(Và¬_™I†UŒâh?âhl—‹naüÑòÏ°nám>2ñ×	¯âˆ-†y­ÄÇ˜]cR6¤ÙÏ¯Ñ±¦"æÁÉyî•øKÇÇ²e f†µ¯ø™°ËiÒJ¯àP’6ƒÁ9™‘hø—\’Ë³}Êabfeİab˜`ıoİ6"“°zë´Ã”G›Y^¾N
s¤õhPÎâÕ˜¡ÿ:pgÚ9–¼Î¾½ø1ío^1êkní3 ª~Mr¿’€üAÕ¸hîˆ óĞÄB ÑX7¡¹Î=¿Š¹i$v¡è»5İŠíD$'7¡(ƒœã+¬ûº©wü*ƒÇñ<ÔØ»û¼’À´kiªdü(ˆ<°,ËĞI-*Ç.€VO<î%ä ”H:Ø¢-gÃ³6Ã­«wb¤Ï0n4póï¦bBi9½¤ÄwRÚæüü‘XË@¥)&‹LKóBP7NáôÈ%jÛÑ¢ëR9ğ‚1§=K£ºÖiÑ®|â0Ùà‹³µˆp(û!¤Êqäïk[#ÓİÀ[f—m‘Û'>£cñ/æãÆ½°·¹Ò—Ihæ¬1o®´{KĞ!D½ßğå×tFI„‘Ÿ=tîÏõ0á|„™ùÜlËÂÃi­OÊ£z:MˆSlã5‚ şè-µLÄnÚÑ5R×Ëò{ßÎ>T«Uù–)CN¾D7¡I¶ q]*èqJ€÷ñ(K¨’0Âu_M)d&/ƒ±]ò>fãCGâ1ú{i€ Ş;YArKıóØ¤ı4wÕ¾¡>Cå¾“­øMx1Æ†„RƒŒe±æÙşunÃÎ=ĞEÑE•mg—&éj]MzQÛNĞ\F‰ÆÄÙ¤rşµäWÍõeÛîô 0QDN“!ß
‘öè®yšxúîÃvBLLr¶+5û~¹(L›Nõ}ÜîşIu:#€Ì˜—@õ]Õ<µ+TiÖzÈJ(ÀsßõI+EØCÒšÆû1s†‰&VjÁq]£ eğJùlI:E°»€«OÖØ‰NıÕ$ÅóñéwT `˜)[ß¾H¾ÄÍ‚çºráucÏùÄJAè›8·H;[¢£ÎË—Äh]”“@Øı?¶ÎÂ½]Ú¿x†lßØõ›*ØªO¼-œLÆn¨wI%óü1ÎGŸüN¼Œ7íáÓÅGÜÀ>ÊCÉÊ0k¾ÇÁ¾‹¾F¡—8œô3½4?O·ô7T’Ú%eR—ğâtNUT'Ïƒ=½¼qï¬MùÌVeP	µEFRër¡Úº#q]%eh)q»Ú@Zäô`|Aõ[d÷Â\ÑcÉUTÿŒ ÿÈ‚Ùßƒ´yÃup¯Wn±òïu‰û:h f2âÄtè¼™!|NœêD™jİj«õ)$—Ùd	^uAaCuy»‚‹wxeÍ©?À_-aE¢ß•5éêÕ”ˆÇ7ìz¦ú¾h­"‰çÚJ™¾¡Ìô´*Ze†ûX|äÉÇøì†¶€w•8‡ç_¥JwPü$ÊJ(/ëkOiÕÚ²gë”ı-ğÎéª¹§ÏÂ§GŸxº*¢u7h®#jHR·«xÏ]òEˆá›ºg³­Æ ºAÑúiêW³á˜É ûÅó{•ÚÿHRTU…Œêã4>‘¦ËøkÛŒ1¬»ĞÀ}æßµO n¡İWáLî-ú†u«’UlùW„‘B#H÷ı	jÅt¨b×DÅ5“%däjK³ù÷ıÉ*,8w3ÎÙëÄ­È~ûUäJo«‰»Lâu-#¢·ÅPÈÉb[ånì1!ºÚ•ƒsŞZ” ÿáøxû“xS®Ú]6c%µĞù•K*/
Šx~.TG®ñ?x¦}5hık^$÷høg0ô‹•m _:ë½9Í Ü1"õÂÂ,d*Tµ¤Â¢£¼¢:´j‡5jÏÉğÉLÛ‚™¦üV…>Æs…w‘r˜ ¥ÌÎÅ…<İÎr¬•nƒßI;İÂ¯(§†6'm’jÈÂ&•ÁR–e´Å=(Ş&êÅŒÃÃ™ı†òM¸Úò:P€Ç#½Êš™ÆÃÉíÎ¿_…‹l_sÌûC‚n™eÖıUáô~6!jÊÆGï« »­¿¢ÂÓ™6ËOÙw0õI+OÊH80+@Æ¸€]ıßàXYı%Ùgb„f:Rs±Qô„†jiw­ÔøÃßÔ¯ ËPfø«³³cr|¨q>
'ÚTÈ÷H=ró`Y<³~<È–ñ2‚¬½„?ì”ÂÂÄ.â=Š *Áœ“jP=u ÷68bX/‡ÂmpÀŒÖ½“ª8â‰§5‘£¸¥Z™šNª•Ï‚oG»¼k#7Æg¨—+,äšĞÇ:Úï¿(è±ù0²ò§U*ÖD|T)¬t¯ªJÅZxÒ€‚ë&Õ«ÆŞ¨Y%Û:¹ÿßy°271ª×óÉi®Ó2€¾-eŞˆ‰DdĞÍ¡â®ÅÇ¨¯öùÿqö\NÏªÃ×‡r¯t~EèFâŞïC9—¹kNÆkoØTä¼^‹ğã'ZQ$úi#J+ ÛË:[Â¥,±‘öw¯gXD”@œ1"ĞL’kARÔoß€“r|èÁäb,@¡—X¶…v'-KuP\ÇöE¬¿VK³¥ı0N³%j”óxşEö®Âë‹ñ|ã÷FµSiã!”aõ'æ%n:hÍ{û>…ÿ\x?†”.X,Y[Cì——Jã¥¼EÌö@ã\=sşí±*-70fé·[cp?†#Ëi½ğıZuëU˜âãÓ:=9é×³ˆv‰·†tÓ‡M«‘¤
¿œºá`ÓüÅ34B‰ÓÃ—Ö8fyŸåWåQ§
ö=×¢ü¬UOQK|fS&äší|PÓa7iµÃYãä_ì¥ƒSÆîõÎÀ*ˆh®„˜àahÛ=3% WDÎÿ«éÕ‰†ªß3†6øSm‘ÇÆfÖ.¤°YÂ‡·SòÉ+YKù )-–«6°Bµ‚IËŠØAÑÍ\¶ş
¥ê1A’.ÓJ"”ù~¤lvØVB°zõ]<¿EÁÏ±ñ™pÓ©e]Ş¦·wş&ºäÊ#(7£ÛIê<ûò!ß\9à¿mˆRÑ"*—üì¯xÒÆ‘T¬ÉÇYÀ„‰ªöì	(‰M1(¡7ãvg˜¡ªJx¯nP¡™ÉHè¾·ÿÀ
·Øÿ‘ocEa8ëPµ\xD¶6”1øÖeú’%âlÊ_Pl>ƒòó²àîÑAdaÅ<EVp¢ûwÄ&Y…+ ÓlºB0©•§‡k’ÇğÑë—2@³EÌ!àÌZ‚×wµ\q2zÍ%Âİ ôZ„³ıŞÎÌ#ĞKddbKtÆlÆª49üK}| mpaä±‡Å«eĞŸH˜ŠÂSŞ€ûA™æ(ü‘¶@¾f¤ÙåTjŞ.(İÅÈ”­óìæwøóEaßÁS«ıtojdüñÊY ×pjß0ô;Œ°fÅ­‡ûÜÂf%R‹NËú·µ‘a16ò5Ë'âPØ-”LmP7†°ãn0±É±"éÇË†®XtÎ¥]ëÎ¸f:ê“Åœ­[¹êk•W	" Cd)U2Ç¸ @‚öÛZ\¹;
ÖhpkÜC5<Â(>ğÀ½Û«(ú$ <Tß‰Ú>¥¾Û;£.( Ê¼äĞR¡İ`fŠûËŸõw­Ù,ã–oX\¦“~eÃrÂ”`«4Ëë:’ˆ†ßÉê†™„
\-je–ÿ‡·»•Æ·v/öù-*ğª{¨·áß'QÌ¡?Z8ÖHŸS{•úÚ¦k¦*(œ÷ÜÑoæ;ìP@³öV{U	ğ5»‡,ßAt‚ÈD­’Sœp¦Ë¨Éœ{x‰¥!Ê}Õß’¶¦‚+øñ¬(ÿÄš1?&wÊÛízudf]"ºˆÁA¢U1ÊÀGÇN„?bP¸Ñ^ÕÅŒR²šÉÌGƒîcÖê1õQaÄÿ¹Õ.ùQšM"ã	…üı–(ƒL9§«úR¸$‘>”.wa+ºÔÃÒ1¶üTÁƒÇN1¯*Ê$“Z¹±è±DóŞ{+)dŒØánê‘7İÌP"à4kbæ`£&ŸìÿaµWiÒ6Ş Bn¸¿¡MW‚l"XcãĞVé	íÄÑÎ–Ş#]Á6c:5ğóûÃ=Ëä5Aî¾ Šà)èTn~É^ éÎ°=³ìêw¯‚Û9f¡ä¸DÖÛYÎsà¬;#~€u\BêÉ5g´>¬kô®›#ÅÇµ­ÍFf/‡—KòkÒÁ›ø„Ê'{ÑÈ2Ôc£\k öGß›ˆ# ì´&°”Û%ìL 4äetİ?Ô,ÆQ‡Fã’ij»ƒ†1ªT¹m¡{ãabj¤|>ı2‰sGQ1•‘¿ëúï´ùºGÌŠ•ŠNzÃÜ„?Eÿ«æä<ÿiığ¨Õáfs;¿¶=}›½q2mš«”ì8ù¦9{+j:õ \Øâ“`«…R#G-ƒœIç¡UEEğo>kºÍĞ$ÏHZ?ä–†ğFH¯Ún=£ĞÚ•áš ³h£ÿn="¡Œ6¯ÙCQyßĞı,ii\b?»Á™ÅMä°§ØlÀrŠmç´‘"XÚ#àªJ$¦]s Õhš‰¹§qÀö ĞMT0®!—AËyšàm©p`êUŞY¬Òä‘¤¦	`î!İ–.âàõ]î+˜^,ä5eq¹Ö“ üJÛŸöE¸)7®¨tØH»B£RRÍŠ7£d³"Å”x¹uÎîR=ÙwóFWÓÀ¹š2h àoÕê…êY_g§J	rÚb®x½T½Ë<Ï¬^ğÜšÔ°ùÖá¬OöxµcÃÏ!c1ÔQl%p.öu"sQdí<µ~í…ÚYéQiIâ¨`]#Vé©è¯¸s£sˆÎúM©´_ñ‘ØßI,…ã{/¶«×Ãm-/ãdz°·xv2K ç7'Âè|?D®zîï2âb´×%Jö
Ş:ôŠ¾ı¯›L@cß³·½Ê3\M]cÅ<ù6eªsoCâÜµ0W¨ñ³&©*
©¦ñZˆŞ[ÁôÎÚ¼î#DQÆİ‚ì¦FcV`ñìd:+º,©¶î¿Ú–´ÒUîÒ(\Y.6Àà‚İXTÂŞ¨‰Lªú`Ö3JÜ)ã°÷*¨+á-áò¥£V^ê¢{ñU[¯@ó¢H ‰¸_ Ş)[¯Î… :'®±VàÌkXwZ©zLpqgµ„òN‹ÅÙİ]¬?…	/é¬“‹¸‚î©L{)Tß£³ÿ3ç²¸Z¹”kšŠÔ&]ÕjâûÌÄ [:AÊ±xn-m˜†Å.jQËíjQîÕ£wëE¤÷P³{’Â9hÎÇä´qfˆØbÀçZTºçCŒÚ»s»H-0ÓJµÓET±M~\ÉÓlÁÎ-‹N&Â¾F×
Müİ…—;à:Å–øœLÓîeœ‚y2®¹¥bÁ'8àî)Zú™¨Bhíö8Õº˜ßÀ)«ğìZZéòÆÎó.GÉ«‹qö¨ë¤){Î°›ıl×ç—‘Š5—r·­1?&ÈJ1šğÇU ’§S½|Ôy½[¯ûvÜ—R:‘Æúä‰2§!·´ıê‡¸ã:|×˜(,H`¿ #Gä†¢ö½®ŠdÄÓç™äü>ã¹,dİŠ¹@t&7è±Û0±§@s¦ÛÇ0Ÿîáõ!¬Æ!	A”òBmâ…<ßŠÎnÈv&’İgp]0÷ŞHgåİŠ|Ö"]i@0ö—B¸ÊH˜@à¡µïÚˆôÆ~¶jaØfÅ^0#„J™Ò&ñòDLô¥,®¶¼Mø7à­Q®O­Õ_¤.VÕªL~pERø{!¤)”¼Ìá œƒ:ĞZßC6åX,5jz -ù>!pèãß+rabuØ¿¤,™Ñ9°L4î÷EHr¶b¡3nqnú:†ëó¼&gç_Bî‡3ó`ªº[UcEñ¼Èl#”É‰ïM”«Ğ>\…ëÚªâ~œG"uv»ÚğS,öƒ§¿Ó‹3ôQŞŒ('áŞ8Äµ÷`ë4¶7ç>Š»°Ìe”£¸4†ÇgFšÉ–¹E¸¯Ex8­ñµóEL`ŸûR:ó'&Cuµ/[j©ùı§#Æı÷XÈ÷­LâÈíz÷Â¿5y¸,[©F,ºÄ2r5ˆhø‰ÓŞiìÁ„²fçlğbn R¸!Ü5´Áı»iqO‡2ƒzÂ¤—W+Æ$óÄç0zş£±Èi"µjfå½ÿ•(°1ÏxŞ?­gLŸÉ ĞÁPõ»Zß6\tn§[0©Í@ÉlB™ºÜÊ7µÊƒœnL´*ã6s–xn5â5¯2ÛÊé’Õ¢åoÓOË†¬Fô4šğìyùğÎĞË†+ğ['>0$¦ˆÌaªa#X‘¥”’è•UÃ‡Tø>ñ€˜İ{5Ïv?HÓ8r_*Ä
 [ÈíÔ„Wî›1çÁÚ'c#L‚Yúºø§¤´4X¬dö#¥¬ga2Ùšu¥BÔÔ}—M¼8ÑhèXÖ eåmµaÉ ±°—?Ì¬_(ØğVĞ,*¿™µçÙÕ&^ËG	„²ÇŒZŒãšâWq]‰Y‘3æº]óWj¿¸ãi0pDì,±ñR(+ÿa†PBq/WbÍ°¹èÖÅYÊğ$\™.¤(n|“·¾x}…m§xvœ§M‘;^ 'HàÃ«Õ^wJO9Y=[­æ	ƒßeş†1‰Š‘‰1D¼ô&x;ÂPç&ÙöPŞÄhİ¿‘©1–‚p<Å—Š¬VCŸjx”¼}^5É„"åu$9]‘åÍ¼5/ıÿ»õ¶£Œê®lAö™Ê®j@²Á´ş¼¢vô
u_æ¹N–&Á¯£ŞkwLüg¥êvßüßŠÂ~,$ıtt…ñZv‚iÀäĞ9ÁE [Ğ-©ğÁÄ2§Ú>N»)HLH™|d7‚Å`/ŸÜ¸.ÃJ£"AôFÈ‚	ßh”¨Èƒ
øš¸; úY'àñ;ù4 ¦mœ|šDÇ ˜ï ‰Ç\FfdQ
kİUZ¹8ËS·E‡RwC„æãÒ‘Ö¦›`¹‰Òo¹ş(ŒŞ åv¹Ï#F6«ìèoñÈ‰*&®s>‘÷9›ùZë×~i9tÈ›º?Ù{»~r:–<ÿ§Š>õV¢ÿı}ºÄ‡ñl{s Ñ¶Ÿ½6ÍÎ!Ô}ÿ)¢šÀJ÷Q0vüc•'iS¢§cÉ	 íèŒ?‰
>ñ<,†UzIş×9MX$D&¡„?²;bA1Ä+‡W\yry.‹›„½nâf…ÿÙ–c%…aÌ¼´>ÈGšÔl¶„¼‹X´Ë]o­?	l1›©ç”>(Ô:Âpv&»ò ¶½<Ûîfhõèu>L:ïPaÃÓMğh®é±msWi®ğr`CsÔÕj%ŸO‹,ä‹B›bi@ÖÅßPÍÉ£#ìîy€<Ãhç{ù±&yu„”˜¿7Î²F®¨ı›VÁô»$dó3¦¢:¥ç|9ş{Ì…—ãa! ÉSÈédştúíeO›êŸ…t#ñß…GğäÏJª-oLâ4kê³ÖUù[Ÿ]Ûbt¼Ğ¿÷ZÙ*Él÷óù½šn"¸W5ÚÅdB	tÅ'ò^<«sŠB“ÁİéJ¢Î9˜ğgğ”Êpàój7‚UK(™‚tµw²¦Ğéåáè±Úèâ„œÑ ‰Û(Gı¾¨¿ÑãúviXŒí´Ärg“’__ÀÑBTîãÛ3¥Ø5ëkå¤y­ÜÓ(fËÑ,ëÚBu~p~é=	¢R
Á.M4Óù|Š {Ëÿ!ó^0Ş!š,[óßhBZß—·³5é.öøô(	ª§G!~%¸çØBğË¬W}QCÒà\UrÉ)ÌQÀ?ş›½oÒqUüŠ¢rsç`è×³¥Ï é$¯$¡U«eø2|')>ğ>«}Ú9«ë¢Áf4?ó´UC-Xy["8ŠyÏ>ùièQ»ª-f$Íµnë"o— †?°îÇıÀ´1€ò•ÕæSÅ[)O€ß‹¸€¤Ûš1i«‰²osã’Bèâ}×$ï8îĞÁ2”„¶»º)nÜÏ ‡F´×_Ô“pj¶Ö«©wà;ìí¹mGËËİçæ®uô~Çy!ØéCry¶Mäâ“S¿]n&‹o_8µ¦§XÅp†Zã—"à¦ìQ¾e¤í;]@Y”ö#=Øù=ëø£‹s\\ËnÄš„$éÒ|Ùª¤Y,ı?¡ábÒëKŒ½/¬'%^¥wõò]›Ó©!ï>ŞƒÆŞèˆ3àÙDºàß3•VÍıwÎ?z4I<ìáH:`·0!§¸ïäèøŒ£Gâ&œUM
Ak§bÖ’ôÿ”’mTäæOÿí÷“på#òŠ?•ZÇÄmgXşWÜ9˜ñ§K0{›,¦ø¬›"âæËe!}”ª&&o|wgğË»ÛĞ…xb 
Ä\vî~.öqÓ*co,¹º:Ã£6a0´º„¸E7¾0ºDk¹¿*Ï]€ ïo=š0Óz)§Ûöüà™'X,³İ¼)m(z¸2«Z–lÀp9ÏÙ™•ıY®a†ëãWPÿÿ\Ôg¼JM…2öØ„Ô1E½*%7…[PZ…5‰Æ9·½Lı¿È”­®<‚¢˜YUd´@ÿ!û8[¥,6müV¯Ÿ’ì¨0µÈ¾ê¯3’æg>ÍàTÆjƒ ¨ş{‹Ä¨¬$·†GS\ø`0     Ï†­¨‰è	¾ ­µ€Àoç²±Ägû    YZ