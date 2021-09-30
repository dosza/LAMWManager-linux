#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3126836238"
MD5="94f39d0c2fac21689100045337b5adf0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23928"
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
	echo Date of packaging: Thu Sep 30 18:42:34 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]5] ¼}•À1Dd]‡Á›PætİDõ|ƒ?¹”3@‹…Gë Ë|Y'ã–ùD»—¦I	ªEQ†L´Ù}[G·‡çephĞ[‹İicĞqŒ²Iˆo¡—¦à²ÇB»g'1dŞÈA›,ÈPÄpÜç³àú´LJ+ğTj|á>tø¹YãİŒÿğJ?MX¶§Úì`í'-õ¨g^û}:¦<Ë¤-•«Õò–õö‹¶…¾ ]Ëbø}2[n"U™D›bŞŞ?~$Œ¢Z»_È}Ò½fz\´'ÛNŒì¹
³^Øô€Öi^6€àğü±F>'6EDµ‘rjC2¤ş¨Årw­ 8î§Î“ú¾.õ”…£.–=m•qÛ¾{%ü¢	Jº`Ëşä~¹`_q´«ny(Ãk?Ax¡Í3¤×ç\Õ?Ô>’"ñ1:²É¡g†×åLR-LÓ%Ø¯ŒÁ\¶>_5-	2SbAN™IUUÁÊWus†Í“”Âöjÿ%³!ª eï
‰œ]³wqRÄ¦w¢×cMn%Ïpz ‰Ñ÷Ê§x÷CcÖ^Æ)z(<lUV%j²í½1
Ï/¸£åF^TÔ
,=ãccÅE¬Ç’dÖ|
‰%»~ Ñ„PgÏò}ÜæZG,óhŸúu90h¥åºéjô¤0Lm¹¤/º^Q/¨’6Bl™YºQà+õ–ººïqcÀ Ûá	 ¥ ëÔŞè¸²|âÚ]†gF,&3¯„l/E\¼¦xëzâÿ¦JHfPû‚îßÙ\ #ÚüÂóRDæ¨§ö
‹L®Ø8ÓßÈ&®(å@ôZ8!¼:R:•ˆ¬…ô‰c«»í¬ã¬İÍ„ôM”ß²tû=®ØÊ[»ò¯«EqW-9Ö0 ¦ì)ìRíãåŠ•çZºøQã¬|wF>Y8sDyúŞ‘×]üb+Kîó˜Á¢ÙÒCô¦°¦Î»ŸÜ¿#Tƒm¬È¦°UC“š“Ø÷
ä‹öğ7<~åüµæ¨C­L†e•ÊÎGcÂû¦`0S^¥{éX%éìã³¯$ü¾u¡o-2Ë@ƒ?6ŒQÊ›Ğ÷ôày}NĞÛ
Œ ‹lúİ	 a&Û&ß‹†Ò‚¼î6>©C`]]Ğ§BRµ(ã¶‚È'K]ğèÂëpœèÒ‰Z|ğà#%ŞÖ¬È8Oá¥D±%f“DUZìÆ.…_· Ã£7$ø—®\\â3Qì Ù/0(ÀwÔ®3½6:a?(†ÿƒu²iß/À°±8ö\ÓÂçÀé©yŠ ê^û@e\©~5öÁ	ì{u†ùLg\±(&6$PĞù©‡u¼€l™·8Ÿ¸ÖÎßú®=ïõ=OŒDŞ@Ø\œfšu;=<wPR±üËkêrëk4'Ój™¹Œ•ìí&¶ÿøEoâÊgP{Ğ)ÿ†„@UÉ‘ìd4l ®Ğ™ÂÃÌ¥À4’Í_\m$é‰å¡¹ê¬XX¯ì¯Ítõí†ÖV#]ÄV,äî	èêóğP4qPÙöåÀÈö=’Lù9cÔ°şâ|uZvï‹—{ 5AÁıĞ|1Ş)®&
¾ĞûúHlÜÄ»‘`ğt5å˜;@»Ñ°•ı²ŠRóÜg¯çÁ‚»ªbIŒİÖÉ€æc[÷mzÏÄ™ş¢cûÒ%Z†W=Mìà¢¥ĞâÜêÜn\yè½1ú'<«Vñ T6î®X,™Ç¼“¸ãœâÃOÓ§	ã›º_a'q@¤ÌìÀ.he´­´Šà	˜åiû³¼½/"ì(‚İk `§bXÌ[( òß ºMÍ-?ÜQú ®‚T\ûÿF¥¶²š+ò%@¦¸f5„EÀÓ˜:ªtİ\Bú Ù9*Z 1æ{—,X˜±Ê¨õ·(dr¥†p  í:T˜?Ì2æn†‹I4b32rÂ£%İo}K\½”d"*ºAN»¯¹¹ÑÇÛh%‹·PEn”qµÆ´Æ]Ù®©#êÅZ7^ÙbRÈƒ™¿èøúš‹Üá‘Æ§8]Yà«İ¾ÀI¬.Æº€Ê¹5—êÃ/RlöË,@)ãÄŠÃæ$­nÈ¡Æ·Mæ,A’3zÒC¬ÇåÆëªï¶¬›
£W·qª2}À '7’—±(ñ„E4à/.jŒ¶šºŠwf™Öu,#@›ˆßqDöœ¬C‡	ğ•Y=gVè\Œè¢Œ.¾Ò7A$s±h“²ıªğ¿¼Ã”š½¥`SFUc¾¨XB,½ oÊ»p23â”‹ÌUd’¦×ÃÔœ&¥Ï¯l0\£Á´ºHGÇƒ”÷ë`ó7R’§·hl_}æ]Ë¥ZÄ’	=0‰®â(ı(Ò&ç´qp{)Y—|_lÑv¯DK,¥y¦s`qŒğÊµ‘èÓ¥5+ZQK_è<?ˆº’½’6X¨%=y-ñÁ|ÆÔr_<»Îek7µW¼}í§¬yë:ÆL¼|üšeßÃ”Èİíé™»æõÃÓëûiqs¥»à
3Ó|iÚ‘ËQh/Qì>„¬´‡¹ì^–¢­ 7©²ˆ¶¨å¤˜ût§D >"dãtªpOş»5ö,7i¢Òıõ§3”òJ Xq}ò¶rY¿{ÒsUk £ˆTNŞpÓIT3ıŞä»Ê|¡|kÂs¢¹\Á:EVPŸğ5~@l+jEG<®ÁOlÛœ–:nĞwşà­ 2Á<Ö¸HéÚxUEùê|1¢‡Ù CÍm í+LrW‡¥ß¿èu®.vTsIqåIë0P¯švò=á-èMúr£ó›KÏC-weÀœ–Ã+ÜÈKÇ`ÁEw®b=DÈ8ö…fıªãÆj[k÷£¦I­­,ó¾Hö4#¶D§M_ÆúiLßwßÓQ‘IFï—Ëİl÷
ìÛ‘Ä`X(v&ü~şE…Û4\Õ^d`.àZÈ;{[P~¯zÖ0*ÕÎ1{¯1¨®…ªZjhºÏ2f÷º7¯RE€éş¤b³ŸÖ‡8õˆ³Ğ§ft¬Î†‹¾ÖBäyĞSHëTÉëĞ”m™6èè=0<,=*£şã˜l¹$Ì¸áö	p‹\’.Ìáb¨ö i:ß ·Ô’*ş[Ò³SŸJå;õ9`©4siäHÖ¶#z™¤	w†€k
½Uy)ğ<l Ú’.ÃŒ(Ç†‘@,~òy ;F½üâñ)ı¦eWeÎ¶o˜5GS3åÍÂFHëŠ’ÅºmB#È|]2»n6–ÒpbÍ ™>WÁtÊ?ÎkÂZGõó0(mt'Ão5?áÊ·Ó_ˆw¯nk!æÕ‹×ğmxŸcç¼G•:Séş=™¯ÎFvp YG0¬Ô
zoàDÖÃgRuê[ş‘6İÂ°¶Ët}ËR˜DÀ‡úZò/x¬3sJ,ÒL#|8¬Ù!*ŞáÇò+ëª¿¨Ğ§ícI‡¸‚û·~Zµ¢›İíÚvzxÌjÎÄ]‡Òíê‡ïVYTÙ”‡B÷7ÜsÍ¸“¦báwÌì}®S Î—¦¾†&x‘©óWlÏŠ˜ÑnWéJŸ(Yo °rªT«k°j“Ç`B*jÂqy¡ëúdÖww²íª=ƒÚà»/šå—$}!uoÛ’9hCßï,Ä|Ó&İÙ”Kæd¬¨Êå0
Kş¾şå=0Œµß1Şw’Í|8o¿ó²ˆxèî"‚-ıcÙ³¿%ûØç¢òĞß?»Şxa¹v(p	ñT¤çC™ë>*²gÌ„0@ùh.ü?è1:ÿWPÅâÈôçT‹_w¸5Ó(Cáu»ü%8=D_XxJtÑt¢0çÂğ€duöâÃ«¯ÓŠKhÎÔ£r :¦Ö]·µlF›Şwˆ9/	ntô!—ÿôĞ,Ñr(òh$@ö¦[æ®ıš;'	şµ4sjÃN*ğ(Ç®#yFª]um1ãÉ)û¿&¹¿	B…™^¦–DÓ†#t<’XzS¢§Ô±ÁÜÍ7ámj‰æù¹İ‹³!zP ”#‰a)eb<™Ù£§Ê¤På„nh¹Š¿:·lagww—Ø
1ü rí—L>úªe9E-²|ú>æÃ­R³UXU	şf•ÿ_Ízö¥3[‚H¤´ÖRÑ§T‡Jxãv•AĞ×°&íÛ©¹µÊò¨·—ó[´¿N©8= ŞC“çô¿ç¥4yš¾³04œORë†ÿPåò!&Ãæ7AÖ°Ò³Ø‚%„#gËí„Îõt©“­Œìı´‡öYïEíGB0ÏÌöºå*VmÊÂàoûÃõJ´@n¥¦ğşKw3.ÈIé·úÿÏ‡FŸÉÁA›\åô¿áÒl/+¨/ù[?ıé.zT®Zûxx²Ñ£}Wyîdy°î.œ§Z“?““XyÍù‘`½yA”†Tßâm/BÂÁègM{‘98€e‚h¨RZâ˜ßO˜8‡}Õ€o’‰ı»˜Õµ&ÄèCS	Gr]f4ğÄòôù!ªiLÏ*>ë  ¬¸ [!yù™ƒ¾)¸fêK" Ä¯Õ1Œ®À: Ÿ1;¹O^…+ÂLX.P¢0²hÕós»p)•W`©q‹§gÑu>*×„”1»t¡5m~'ÆÒ7TŒÁ]yÍÏy¢æ \úí~{ö9ë¶²³(ÄHÑÂT@´|*ÅvÃÄ©J‚C–û!7Ş%ÃŞõNÂZÿo[Ôß€íZ©éº
¼:´•ì™sJ"àCê8öG¹9Åm:fZû”a|mÂ!?ÎXÎ8ã*_^«‚á‰Ò®¥Û7¶DÇŸòáì—AìØˆml ‚&u/«jšˆh×+¡£h^Ò³Ãõ« œi4°1z<?rV¶3Êš„¸CŞ-ÎÁÃÅ¤N(@:ó]°˜ğŒá-ößdƒ²¾œWP«‡õ->[M 1éöXU*¤=—g¿µLÇXõ{˜úä£…ÛÛ",s3iÊØfy?”ëvwmWzÎC|¥#8«·Î¹¯;3ÍGÃÔN¨d!Ã‰ÔLA®şÇò…ÚÈúÇoåÜšrSL/I?¥/RkªZÆxEĞ}¤)k+)û)ù7-À³wıõÕ ŠÖ6‡òâô7šâ¬åÅí9˜›Q}G€—öÊäºãñtˆáô&B\îĞéƒwS{	µ$álxY¶h–Yõñ<¼íğ¯…CXïhô%c1g²¸HOÍfª²C{W½p³ªf'£š›¼ ¹:•^@ëº`sY6ˆ"áƒï¡Çğêem	‰/+Xm÷ÿ|‰&Í+C­‡ÿ°“4R®ãJ´$wÑ—‘<®í+ÄÛj°c»?{U·Ë1ÁGbŠ‚IÌAoú:’ó$ÿœX“Vû
ëò±=pñºIJ×¾ºÿ„OÓp	Ÿ\Yç7AìV\DWª'ïcÍß˜ F|´&×¦hQ16Cpz°ó“¾pá§¸…ğè=F‹<Ÿi]n	lÒ‡<|íç„o´oóÙ_ÖyvÓôĞUÖÈÜññR§!¶!eV4&§Pª‡Ò—2”@¶y  ¤pñ€“htÂÈùÄ¸}åP^Åï¤Hk|†ûGÂ¡dßµà—ûE‘Ù4½~D¼7?ìÊÏcÙtä¦
¡ãŒ&ÜZA¬Lƒºå<£Ä“@ı›îfÁ¶úWÒö´•ºy}B¬º+Å1½÷¨)xüõXùå”KŸqB-Oä©]˜ŞÇ¼ªŸ@ÌbËÿêòšÖö­È^Ù–cŸËJñ}H¼»rª·¶(ó_t½ÈéÃì—Ğ´¢ñÓ«¯²'cB4qÎOÜz®f:ˆqq§à°HË65øE@şÿ¼äÓ4·¼7 iV¯j·[°°‘#S£šíé€…‡[C©wàloÕÕ³+Æ8	» ï#:Åï£öƒ ¥D¢ÖÓ©G>ñ°õM-Ùìl—•{ :]Ò•Js¾¾DU\ÊÅan–*S*^³ç İEèÓãöÆm^1Õü‰°YS˜±ÿ†¾èë{¶k£şÔOaá‰óŒÖú7`‘Ì¨Î…±¹éJ‡X:˜ú\¯;fú®H_„˜X–w)ìBwëŞK§w“¡´½#ÒĞy%jÿ$:LîØ:›´ñ”PHé•`/EúyC?ÏF¤,¨@8	Ã“ç®ìÀ7úÕˆÙ¹aÛºI[…d*kŸJæw<!÷ƒ+í3ª€ú;Ha»À+È#YH¥Tá×‚CÙıª¾™ìÕacTı–=ƒáh‚Kòâ§d¯‡¼çŒ&OÏJY0™z ‚bÈJıÕä&ÙåÅ2œDt”f—-$rY•'
ˆI«1wtü½ƒY½ö²„/ÎOá›Şœ¹‹¸À¿„wÑó4Y°mømƒy*Ö¬Àç|Š³€Â”Ñ×¸Ì›4wÊhÊÄHÏ¾Mt6—1´^‘†î|80–/ªYnİ@
qo˜—È°>ÅÓÉ<²{ÏxÆ^1,º„ÁÛH¤
«ÔÌ- R­kö4Â¿r\]“­§°_áaô4DÚ†8'«ËÎ6	‹ô^KğeAD_BŠ¼=$ÌÌ4BpG:ñü[2ÿ›'E4nğÂf=oÔ¾[ÁN{S¤,/Ó­ŒL¯uõYVtOÄĞN‡Ã¯Ù£À!.ZÊÔ ŞÂ¬à5„¿¶Ô50Šw"iÃ¿ VC3öX­Ü­ÑèµÀ¾,Yµ?•&ÅïÙê+"Àdã„£À2Z´¾p´Z•ÉCÊ¢»x—<aP$ÂV«J³5 ¢½rÖái;1?q.2?Kçë1dCK€]'ø“?/m0U¯ã g!<Úäí­'}ß¦Dû:áÕctò„şMF(¬»¹©‰ÿ™¤şi9GíhÇŸ”©pL —Ò5"Îrj§ÏW„ LG‘(aĞKËX#‡•Bó£ıXHÀKN©Šõ!L;Î„Ìµ"İ§e?3*ÊŠ MLõÔğG'G4f£“ŞZÿN˜¢Õ{1è²ù›>‹Õ°Q%I‰¥F}Ü7ÇØDášk=’ê÷ë›“Ë¼V¡ó÷¹	T4¼<L³ÅÓh£*4éß ªÒKZmñX¾£p…Ø©°‚cå"·”Ì;*Ô¡²Áj ±Œaƒ®-­KX>ß»¬,Å…¢
ÍoÁKÓNj$ëšFÀìÚ	±îjr\ynêŞg4¤JêIÔ’ş,˜è»¶ÛÙ¨I “aêm‹İWbÅ±‰SYsMdB¡.	–!Ş XÌÀøÃ)Í,Î®Á,+íQ	¶ìFÆXyp o_&ƒ8—âÒ©â3¶cs3\[9_àm¡_"%/.Ã¬^Ò@¥v×Iobë›G·šÁÙÄxXùşßXÁé©ÔÌŸ< ¶y£ì¾“zBV†HÏçjJöYõZ+VHûg•-‘’¦oRhõGY=·AË3Hï¦pÁ^{f¶ÓI9pªí’ê!,&.€ëbØ±µ}lÕ×DÃ?s×Ó)ê_ OgĞ±õ¶ 8aÈÒ
UÀÄÄ …n¦™zF(×Ş7œ…yUáæíkxm(?rÃı^œµì€C·q§•IÓ4÷9uzŞ×7Ógè¢ÿ\
½ÃÖ! Ô"|‚Ö€DÒŒ¦”*…ŸMÉ‘-ĞËMİ5JvêFHêoõ<g4bì6¼}µÇcßehÇ¡éÑMÕkn©½×¾<BîöŸ„{Ø‹UiÆÂróiı¼ÊF“æ†~uÇhvæüXc:aD´}úïÊ"}½¯û¼â·êVí:lKã.½ß@a®Jİ)¯ŞßUNåæ„'ÙäÍaîg°›ô"Ë ÙÛıI°íhÏ—{<NêÎÁœ­A½£³‡æm’³êó°…˜\—1,rw¦ñY²&)~IyM`àŒt=0æù_Å¿/3Áî-„´ƒÎßeÁÑC°>û1¦ ë63’<Á›qSm€­â§“j8FsLÿ@ËZ‚‘×_­‚ë{à¸H°_\ìô/ş½ùo¦³Õ,]ÜÀÑ‹—’yªyü*ÛkjŸP¤ı 
Erµ„‡ÉÜóôF¬–MóÃ}$÷VÇf-z3yGàdÜºGoc"ù„S2	Ú}Âµpè³*nI˜Ëÿª"Î@&V«ÏĞ”ÙÂ›w Æº‚“ÏéÎ“·,Fé^k·ÈkIaŞ›'½¨‹¹£M?ÂÔIÎèrÍ9^¸C}.Y]¾‚9åÛ¢ –Qu.Ø™ôèÙ¬F·sßĞä·²©ÚÏˆ­âléŒd9K‰£bi‡L}ŒíuG²×[)šì˜,3ª û¥ñ–Ù‰,±‘¶Óf^upÉ>¢1³"4|Sdx°õ×-ˆ8¯FL™êŸu ›[ß,;Êj…ò™ 6›m›6¢¾?6;ˆã¸zöMø5sÌÄµ\óJ¨Ì—œW&©ÓÏ”'ÊtxqaIûDjŞÃûëÑLÈrM#¥ØN7zeP­ùl`ö)ëá ó,ÿTSÌğôšh ŒóøÖ´BÁÛ´•*ËXõ×2/)+4úhğû}QGİ­HâXÓ¯’ó.WM-°;W5Ë^pùÅ;
¿|äF§ò#Vé!å×EPì¡Œ_êAÛM˜—^y™`$ip—Ò-ó~ğîİ×^äm·P–ÛV’THJ
A×c$æ˜“¡iöök7g!oñ"±®aéw]·kÂ,\ZÌD‚.¹ÏtıTc—Rõ½&/àâ¨)M(|¸{t„ ›¸R<×î+hÌpP•JQ½mg›.mÔş2®àğ˜‹ïÓ÷2ÚÂ¡‘ÂæZW‚÷
Ï’ÍÂbİÈnÄ¶/j1'¤w—`E%æ—„:…şÉ«-winoåá(bö®˜¤î,ãƒ¬¢+Ì”L-ÎFÔ	IÆ9[’¶píÎ4­Ğ]Ç‘W[7õƒ~~”ÑWÖ’¹âÜ‹š²%T×tå
ª}šË•Iuiyİ÷I.™ÛdŒÛ5Šå*+ Tc£(´q¶¾‹ÎH•:ìâİ½üèÃ†ó,Ê´¡şeSZúÖ7rQ·®æÄ·¬Æˆ~l/Aq94v:$8VAš§QÔ«Z÷šÉ–u2ôvz.­z¿ÀìÖ‡\uóôä¤€B/“}«Ó@FÒÕq¥»äEÕ¹Ø¦5{|ò7WÄ8&ëB‰Û³j›G :Jb”“™÷wèir“[vÉÒ:L‚²Ş§¤ï½t»•’@²&^à­½ŠXsø‡”;ÖÁc€‡
P»­w|ş+};9ŒBM‘"BS+Ÿ´\úªÄ…U7°ßí’’¥‚äi	/Î„ğ³¸Ç·1Î Õ‘ú´Z?KNÿ ‘ñ»~ÆWú×hSˆ”Ûá©|-Ú3©,è<9„Ñ¥Š™yÔ0ÌãPH¬L2¥kê¨hŒY‘;Æ÷ë7öÃs-ÇÕ°e„±-ø«Ùm„/4½ÏàVßËÉ¬!K¹™¨ØP×f©H«•3ÓzÁšºçF{©ÈD-=)«:ƒ«ê¬-%÷gBùBácÕñ×Ö«T(=”¹.q¹ÜC.–' äŠ/@j•~¥ÅPtpÕ¥¤/:2^ƒŞ©JNv&ÑdëTßş‘“„\;l±&ï`!ÚZU6`°z÷&¹˜wH0ôë¾KC9†ÛÅ¸¶b{F¹/†¡®Ğ&oø‰İpß€SşŠ4 Ÿ±Ã½’_Ø¥”¥éÚ³¤%´oÑAO @vWl ­ß'×úkLÂ\lj›ö"ÀÒ`@Ş¥×òØµQÛÚòŠq”¿„•ß-ª¼êë»<Ï}ÔBß¬¦-sóô-ù²Ø	ÏµĞ©.¶~ÀüUÊ·ÁTË¸u4ÔHçÒì=óqS"¿Î™5Ê²³O0ø?Ğ°*F®.>¼û¡ƒ'‰ñé¡ˆú¸(0Z“µÑ"…\‡â;D‰õ¦Üo^¬÷&M$)ºSÙm‘OÅAÈæ±âÖAYI|mÌ9ãrg‘ó (QÖ-‡5´»Õóé"xàı—~!¤cÎòÙWPÊ_+!ÓNí	ı,ôb‹Á]Œ©n„ªËê
“ 1Æ ı2>çC <7MGÅÑã”öëI{˜«ÂİcÙy8İ—N”ƒèã†íznûxĞL¹·âX5Ÿ†òóÏ~˜ÖRæºÔŸ0öÄ^ğTÛq”‡»SŠ{ÖŠåu4sAˆÌá‚¿E ¸s¤ù5šÔO´F`ëÙ}Ë&z¥¯‘´ ;ÙMgğœäÑØÂ°
€gSÚb€EL¹U€ó´ü8KŠ÷™cÆdä—)?D™©1CÂ“´OtœÁÎÃM‰$Â×#¡<‰—ù`
@X“7»=êzd‰‰Y1Rà¤ÓX§Íü°4ğVVm7;KVj™œÇ(,JL” m¾v±'Å
Tg‹A’±¶ÎMJ«¬åzÈw;¬F@á| ³¿@|mÒ8GŒwjÒğÀæ%µ½'h#fÓ¿‚åµÚe¾'×È{H½k®Î`Ş2Í€ÃÑqx
ê6á•J®g£ù‡5ı
ºlCe°°Çùa
œ,Õv2¼À…L…û6œu©Å¯^ ÅW3xdöÃPVÇ0*¤×eõDåS~ğç7aßEÑßKMÔúÜ™Â“
;é>¥”!`Òè_ò‡3‚u–:òLÔ3Iİ^şË„Ò&Š[¿ûˆïØôK	_2FFjã¢¤`cúUµ×e ,ÿ]ÍÙgl¹†‹6:¢ßGÕ4;išŞŒ´¡"0iL°ªssmQ¿¨|:²E¥¬ÍÕŒy@ìê¬‘ûĞÛ^Ò—«ÏÒ•=êühIÔI§ü)2² m•7xìõ1©YFĞ»¯ößTŒÍ5µPµ=×ÏÇ8Jp1[Ùƒ›‰Jx^Œ¨¸MıRØA\{¦˜Pİ0©°Œ‚B©å¥s‘‰¯[ÔF¸òˆ0@}^Å5+§Vîg“ÇÖ]ü»ô_k  *^¤­>mnD=½Êbê˜Í¿‡ŸëÃŠµ?¤Û\9Â´˜¡•F™Õˆ¢ö0çì‹ ^ÉÃA>VÑªğîl0û°ì½*©ı‚R—/*‹„ fíûr3}ë¦oÇÎÜiùÁ†|PóŠ{<"_x{†6Ùp"|¶hÒQ‘¿´TƒpÉÜ·^×…6İû`‹Ùà{³„Ëùÿø‰7¾X‰?ş&ı¦Ü–Çf;iğ…!Ï[M¡ñß5t…{Î]z¾GÛ·³]tó…¼¨I ‡ó, E|ŒügæY_|¹ÛuÌègõZË[síz!×¬)hA)¯@
ØÖ~%’¥tç\Ó-ƒij§É¦+‘‚Øò›˜¼¤RQ¬Xc6ÿ‰™­M4l`*İ?fM½…Ç¬˜C/8Ïz[Ó¸Ì•1F›İò-eaO#cÇ‡¥Œm$áá§Hz¼÷³§‘[ èqd]È×oûi¹T"„—9Ü‹ÅêÌ­í›\g)Ï€)¯uÊøøı¸&m‘H¦¸Üµ¬äÈVª‰Ø¤"ÒÒ»ôùct¥¯9M”L¬z@F»ÓÉƒ¦ÿí/`ù
Œ½.»X)zãƒÒ~Ò@ºV‚Ô†/À šñC-!û¡õ5¡Üôı«ÑÒ_c×çÍ‹Ñ®u=ñşõë»îÁD‘(—œ5yNÊ‡¶=ÂNƒêíÏG¥›–óÀ`hÎ©cFx”I·¦ñ¤ıtÈ)4Å–şa=ÛæW-.–YôŒÈQó={8=€+¬Á¢Áµö¡Ğ•´£¶˜•Íö:˜(m¤ïæÔI"¬OhÀOª©›R5Ä×§¼‘ígo-]=‰÷Sjbâ	¼êD‹Ïì£´H=ìPéˆ£È6ÓÙãÙCÙ1İLN¼ÄXQNİá‡¨GëŒ>¯4™)¢«ã§ğ¿0€ŒŠ£¬›F‹ªÔÔ‡(çÚ'§½l˜ı.To¶Q^ó“¼ĞâÿúYJd/™,d!Ã+F¡Á`zUÛ6_ñuà¦ùàq²ı®°Ø(æ÷¦.Ù©µV|å-Ö‹rTX$­ğàÏ‡Úu3øbRXÃ‡ñR¦[WfôÓ…ÅÍ5^¼2UY7şÀûgü’‘‡º¢â³1«?ÂråÊĞ4Ã±^{œá(Qg'ë!ˆ¼ê¡º'úX– ´ó2»K²oíWoáqˆç,ëÓ!o§F®’ie…"Gô/Æ¡ÊcôXİİÎª?yæ7ŠgŠ"…¸NSJõz›aø Ym½$Ï\ÓÓĞ|Ü»ÉÕZc€`½* +‚l›¾9H((¥ÃÅ“,¸©Ãyè+‰®¬T@pq_êf21Ct­*ÊÉ7V~¦«ŒÑmZUâ
.Dw¾üíÑ@ÁN~V©l}VNl3_Aì\Áû§Ãl®¾˜Dä!V]ûp<Nˆ ıˆ9<T³;5w¾ÅÖ»\Ïš<ZÍJó*LH-ÂW"rİW§hŞÊùƒMíŒg»PşP…ı´!ôÄÁG@r0(ª‰öå­P¹òÒàù|lw²šYÄş¤ÿls”Oa±%Û”®á|}Ûü5ÇC3F É8É#Í¹Á˜üô³ÆNè.l†˜U!ø zş[x‰~“œV;aï:[E&üò'½y".vó
÷T†-¶…ëâ‘ŸÇÇjªWFƒÏxNİçxÂ;e1Õ{•ZišW0pÍ&ôŠdá‡V{Ó¾2pˆXL+£AY¯äz'p˜LQÆÃÔúÍ:ÂwÓ “âq>VHéŞUgYÃ€9‘V"|}Ù[Ëot×?’+®ü&Û!‘Å˜z¢×-x¶ÿdL8ø£.Åõdé—ˆ³K?Ö:Ä O±L?çvaçPÇ1lt4S0¾ùñ8¼ŠgGXÉm~LHïN&öo…|(9êìÈÁ² ŒğÆuQ ìù­.R‚ˆ!¸Ãsõ²O0‚éQí“û™-Ê÷zc¤ƒP¹ø"n^Æµ1Ø‘sØáİqÄÔí€|µºÿ’DKu¦
Ö‚YA\p×ğğpŞ	:Ú£¡¶giNK".ğî%½òÄÈ‘Êÿğ¯-:©wÑPòĞ#sé4)pö4ª£™ƒ°é{¬g'XèkİÁØ¥è!ÜG\æõË6ƒ£ ´ÃÇø{‹Ğ¹“¢ÈÎ#¤p˜b¼¤èña»+Á©4˜vK£[ÒHsÁŞaûìN	ü²ˆf¾r#öcÒšG˜ÂCVÂıÁÿEéy
”®øÜ$+Â÷W£²‰Ü sz;í,¿0pğÆØ¥ı‡~û.[<ªÖwÔÅIgÂ¿œ¨Mxò;wi}×ßäkğ6û1‘¿ÊgÓGètÕoæ2@€5im—Ûû€*úßGV5`NÌŠUĞ¸ÆG¹Çq:Ù²*ÔH›9ùh`×C×İ‘ã’ôu`¢	ñ6¸N$ØÅ‚±Ó†ÖßÿT6±ôí­Cï«›cWÏ„@ŠTÁŸ-ñ„’n5}m}GóLÁ—~îÀÂt0Q ËÍÅ„F ?¤mB¦y÷¹œ+ìãÛZò!ıÊt–XJ€Ê¯œk¿¥û.üÀe|€`¼œ{Â­;ƒa0ë‰ä­bAê‰õ<5ô<$CíÌ»kÜé±¸Š®ÕAËYgºš®'¨¯ßÑJ{şi.®uŸƒ¯Eû!‰UÒï»ºlDĞ:Øz…[Vòmê8©'Øè(† “`×µ6¶Õuìõï¢ôØL÷&îV ¹÷C"MjLÓ-Ì–˜§"ÓïıD}Å;É‘ê'“šü±eæŠÇYàAØv›ùŞ	µxYt-«vmß£Ôr|Ìò ñ¹À™;­UN¡È«Õü½°®vú5’uˆÎØÕßgøòySÉ"È_òìfÌ†^>ÀDA@H¾BÏ>’^	Ï]fÇÏŞà¿±ºfXNğ–tªôşL¬ÿ·‹Nô˜v³(9´2ô4«°J¥¥½Õ*9å‹ş™Yµ’_¤/,›}Ç×õ¿møÆ5~ƒz‡¯Ú§É¨
Z|P+¬Fuùy7„¹_åÃ¦~œ“Äo¡7d‰ÿŸÃûéx†çoq‹—áMãl\œT½[JQ_s™*ŠÂÇÜä3‹›öJQ9™F½ËÊ×r1qÖ_	³`%\ªğVs¸ªœ6ÊÏ·b½Í«eI~±Q¹˜qñ»ca£Ë¤¬Õ.½8º&«°I‰ze¾è"û€)*äpO}‰B]„áóLÇ.bÑÏÊï=>xÕXwÑdË®HğÒ1¹ÁP*	ñ›åÏF3Œ]€;òq˜WVÁ×Tuòr~øÌâ¸ÂìÂalÅw	Å†ÓY75·æ‹#[TÔ.BğûÈB\ÇíFéx²¤etÔÆødÌiTúT»,'èe©ï@ô»{³ÊıO C}_ÛÆ¤‚D£)w*ì{—ÔÒœX
æûLr?rKj¼öùÙ‹™sM=ÔŠ€¡úQ^¸n-‚0¨<FÒ­+õ¶×gºuÒ)‘` 7½á^‰*¢ó|Z#%èó¯Ä¤éĞ<Ûô1¾PŠ…~»WÇæ,=ri>šĞû­ê’[9ÎPğÑ^Qj!@x©Q
ÓïS¢Ü×ÃâR%íÅèf÷ûçÕn­ágQB
šHŸÁ7¢-ïÿ"¿Í$’áşoÜBÿŠb©˜>HrÊûlİ—ôJ@àü±&èmzÿ|wwq	‘å—ä´$»ø!‰\Ê¤`NZ^Ÿâ˜ 'âS.K„ƒDşä[uŸÂ]W¦fÊ5ÜI#q×è°€“CRR\fŠY2¦©¤‡õŒ8¾>lœÚÂkbEg£aa­·Éû@{¨Œ°É¿AªË‚—M
M€€÷¯áJ©,‹¹åÆ¦/âWzƒHPÕ™BÕiÑÒ´g6*÷ÌÔ05ê@«¥Û3qëF€0sNª†éÎeuS_x;±NÉÅ§Ç_q(»)EÂCW8´¶{EF÷âòCi?¿QáÙt š×üñ–äÚ*zoô»,JŠ$İ{y	·×øMUâyV²"œ9
‡ù”•a&Hm°÷1ÎGN<P#”Vhª÷WG®“&2zh–Ì ğé=ßãùõù]¬›ãşzPªîµ¦úsèõÖ- lÿğùÅ~Ù¬©©eÂâFö_t¸I–2Í²Tìšù
3pü@.N2Ô–‹ÅR³ırzJû›íÓŞ£tºÿ¶9…YC¸£éW3¨‡•ü4©äNyÉ?¤¹ëÏ“Öÿ6äğŒv¾Cnşf!é9ReT!œ-÷Íòì9•‹)B±4ä7`@µ¦¦nxçÆ\è°G˜/—ùF®„0¯RDbº	„
D'—·H*Í	éÔhC=¬Bó/<İ>X«F
Õ¹n>ÊeçAZöÓ,Ñéq·RÓ.hIn€:wúU 'DüÕ‚™Á¦DÚ~Ôß6;c‚-ˆ¦\g“­à‚ÇŒç±¦Üµ¢;à·¸¸zu¼Ç‰ª×øyÁšVN-#“÷”Â7‹ÑªÔ.g}â×GÊ§w¶´ÿ¼M€h*ùK}öÛ
|XC´é\ÛKQcåŒe0×roı [L‡hxğbnø~àâÂ¡g»9óØbÛ~ Ş‚/E‚ÙÂŞ7Á"İ¤)Eé½$SK~f^©Âz¡ş#Jk\Õƒ¹!¥»<‹¹½PÓBkØ.ë	bL£™Îl¹Í7o£™¾Û”ãô4Eyªb9§ûŒT¶w9:P³›î]	iäü#îL¹İ0Ï(é³”’Ê,Vrv¹]ç-DÑš)Û§¥=ÒñàĞHÜÂzÈ¿‹q;œ#ÜĞÒê{"×$LbgË”]Õ}Ì¢²:cw TâÇÇ­¦\ŸEî4Ğ9ûôZ)ieã“7Â¸ñÓK¼‰OkBDÚ†1¯µìf¼}wÆÓõbÚö9ßşù~„`œlÙæf÷z§}ıêº·¿~4è\VÀãSë¥FUŸ°u‹ØÀ"'ÇÖ%}+ØZUÇ¨¤ÿb/¦×tl(võ;šÑ;ë Ü8%µºk‘%Zs?&Q 6Ó„òÿ-']À´=êøoa:Y9Õ½/ìúe—şxä7ÿ¤¾zUcK¥Û%ön‡¾°Î"ÜD®ù+›Ìg‘Ÿ^ZúGQ ¥½d:4¼rŸ>Å~´k|˜‡È¡*€&/-^ËkºşäÂB‡Î|İãİÛ8v¹,äèWÅJiç¸?ŸÃÑ±¡Ãİıïü¦‰K8¯B.‹%‰³W¨æD¹ëâÜ ü£„ó*]7°_'EúLŞ?µe¢ËŞİ>ptïr>=ñœŸ¬ÈlÖXF·‹æq¼ıXıĞ
Çºé¿·a/#Œ€N©;>U£OböfaùŞ”1ıœ™–ÉSGïß¿ «×yO¬Jc`­QôÙşçI·ıœ‡²ßJŞ„ğ½‘2¥äÛ1cT34$eCÏWæL"Øj`|ïË±‰ÿüC?S…ïEæÃ–.;Ö¼-ûzQ4g‡â{Šqùx¡ÙÌO8¥Û‚-:uZ[£¤‰÷	9=M~Å×ƒÜ«@ )#Ò}*aÜR|,“4ìîüÁQ«öúo…Á¶sè-°èñÈWÂŸ8ŸBn0Ÿã\…³÷€²x±ãÆh©^óÈ¨—øÂoë(œ®¼ò·²ëÚøßWE6WDµÕ¦§¿Çq8Áñx‹ÚÇĞ¡ü
¤ò£
‘zP§Ã×aëè@¥Ã_LCïºİ¯ºâ«2=7‘|¿®â' -{‡‹ ûs± y—“ÒèAXw&a[—r[4PùX—
LDÄ(?…”¸EF·êçB˜3Vß##uGq…¸\I9³SÒ&6@£,»µò“ôK'¥Ä«Á²¨XüŠNÎiÇq– ß=gå¯*ÕñiX±xH§weï_ £YÖ£SÛML™^«îSİ¡`´a]E”!°ªÛí‘èR8G+]ç ;›ÈÑO³‚H$w"Ü^iI
.ç£PÅtT§µÒñ¿(*.M39Ï”Hş $õ•€ùí‘†ûeµ¼Â8=—l0·¡)~¾¿$¹A´.è»_hpmãÃX,š5¬ú)şºVí–KM [L’ ßOV¹/7×²•úûÎèdª„İú7ÑQnà¸fãüõ>Æ+ÎÇ%½ËçVr“e…‡^t¡f¿-NğRdn)ørGõ	Šuùäõ92%æŒ±b@ùF(\@}¸Ì&¬YÉA…;+v¾›­4¿d:sÜt¸cê¤À.ìğ¹]ˆ’"qÉXÌXñuyàˆw¥aË«‚ñV÷EMeÈ´}‹¡ñä«Óy/õøsEmÈG\BÖ)Š,q‘™ÜìÌ†FÅ\%ápYyƒ¦§wóÍóANDV„–#‹øAtº;KJè~;;N¯v3E§x©Ÿ3—áÁ•Ä--Û“5ÎUdá¦ØÜ…)bX}r§œ†a×Aú®fGÑ˜4äJ|‰Ò3FÈ-ª¹Êd­´-ÑÖ±{ê&gw·ºööÈy¶ùùg£2­”°k´ÌÆÕö‘Ï²¿b•½mù;ÒF_~jú"òV";´‡¥öù5LLJ/‡¾³Çmâ3·ßá¶¼XİÀëƒüKlo_Ê Ñ¢ñ÷J‹Ö­$›Vü¬Ñ¥:1êç*î3:Ò7ã¢:oqÃ¦SäÂCb’ÓÙähîàalæFö+ŞIñ¢_fe-8Û+2!ò†mÍzòºõLÛşú´O¦×ËÈX157ñ±F`­²¨DÄP6›¯•ë@vZR8æ¾ëc"6˜Êçp‰œıœ²F³{¼¤§¸WÇş ›°éà–>fh	ÊLò11U‡´rFÃQ½ºØHªRËêü˜"bN 4~Kqİ”µúúíNejØ³ó-u*ô›Xw¦l b@=ÇPIãiš¥³ù$I K$6¤k'®L}ÜÄ<7öJììiHj ¸~¯Ø‡Áµ+“3>6Óœíş<†ä™s¸BD±ºCãvÀA‰yÅª…y™ğo#ÏäwÇz*<ØSº‚JÏ}'s¦•çwÅÒ#ïÛ¾¿±e.0 S	$ÏãÜPŠŞC‡Ép¬ÏbZ)dG\;qñË¬ ÓY¸:ÓãBÛŠ‚È·§NI‰,/™t€mgDTd^¥9°rf(«.8N*%£O!A¼=3:õZF9˜û@K6îÚµBW~§V‹¥Ñn
ˆc^ï«ÿoä?
mKöeéì­[¦º¿ªÀMNB÷V»6‰05É+Šm'ğ`“à}³ƒ‚rqôÊ&OëÑ€ïtåH ®Ahj·úğSö`jä•T†˜ÎD‚Ï/CéZŒRCfØ]Ê#ß}Ñ4§]¨w£P¨
(æAÎÀTÿÚ[è\ı;®2g£=ò±‘¾çmçÂ ø÷ûI’ÖßF¦‡ùÓ¼<ıñ‘ŞFlùï[ycHÛÎ›·D/%ø‡-u§k:˜piÉÏğ°jqi³9Ó>aZ4«Ú–•ÚŒ•$Õ¤ÌÖaÁãåäß¯?[)¸Ô–Ûalİ£H¶Á°À¨Ÿ/ÃÚÖÇuFÔæ™(ŸŠ%ş
oáuş¥Â}Ş¿y5CŠ7'4á_3`²hÕáEÆ&©mÈÅ‡ÕÇnD´œ¢À%Ÿœw¸Å–PH'ä#8 œÛÑª‹ii‹Šéq/]³ºç(4„Xw>ôØ@ÂwÉº^Ü©’W€‹ë9õû^
… ot¼J{8¾¿t­XjJ–3§	Åp}]>œKµ=à„/m‰IÅ\Ób!)!’Â•­2•(Ñ8Êaë9>B5vn$pf"/Ôº×¥j³ƒëÏeÑşkÇ]9ÿ€èFÖï(j¹ß_JÍ>!‚“ugØeœèŞ¼ÑòøA¾¶Ä7ÏÔ}eÏ“^Ö’­¸(eJ#mçÓ¶NCÒºl½nXNïè\óM9Ø¦åŒt1°®Ál€v±šË`¥ÈN€ˆN½_xCOA5{Oe_/]î^<Kwã‹oux˜È¾ÄÚŒ™²}”/âï|hL«p:9BÿgÑTh™í®C<j_râûæ4:1Ó7V†k‡\y¤nì:<«Š—”l•ó KÓµú‚oˆ$@‡Úò¦k4t”Æ™*l1uÄfØH¸c6ÒÜÿ™ŸòíÁÓÀ|Ü´’)şA€©_Ö¬J‘ı³{K€âR¾Ûœ­9¬Â¬sºM|™91X‰åøåod«Å˜‡,¸0qÿ)UÎÔ¥~<á‹£¶Ns˜¹wx˜»Uƒ·?×á¸kZ_¥O†™Z®@7f¦¦‰C0¼7°@~]OE‹ØÆ»Q(–3Ë fr_ä3t@VØ´£›ø>i\ò÷ÀP›Ûï«¸¢Wá»ï„Ë|İôº7ùŠJùs4¡|í¾kE¡´sBO¢’E<-–\{óibÅ¥í£ö	ÕIöë­&ñÇWQç'4.ß¸ü×Q.Gë†CæDĞí£|™àìmK*?çË×ƒK:©¦
¾TŞUEA±¢!]Éıİ®r…Z5Ôà•ÆÀ÷õñÏÂ>FörçÎƒ©±ğµ[å(òôü“hRâØàÄEœ¸øN0Y¡’: q@÷vŠ¹9õ¿@<*@âAÓåß´6~‘ÄS³}N)¤ñš…à`7‚t÷!ÌX»ÂdjFv™VQ²möR:ï¤u\£xÿ”ášŞtÉ,/Õc,å;ğ1Å”ş¬:äp6™—9bÆïĞlKÜõ´Éõa3Õò8%KêIûƒß/¸N(’˜}Y·§6O
EÓ¼f€A¿ß¤ZÉ†¯Nˆêÿ´dQ~³±¡–V¿˜†eEzû¾‚X:Õ	Énsé“Ò•-«ß²™°­ÛĞRé	[:çİ×,ïÏ€¹p¥R°ß»ê¢Z’,¤¸õ«îÙ3„ñ×±!Ø0¦ù’Ö!K%ğÏ¾ºğÃàLŠyµ=	ÎÜå–kÜÅÍqHíõ³"”<9¤ áihúØ ½
Ûœ¯®&¬,Ä¸æeã´qõu†2‚ÎçI¥Òì—ÓĞ¸üÓ6R¬X4CiägX"ô5e£ÖG’IğŒ·’ÂˆvoàJÖ™aiÑİ¬å[œÃ#’ÏïÖ€3y§`S+‡Ê”¶=äİ’Êˆô¶4HÙ<>HÔ°‡ÙJ…5ÍLrlõ¨¨±‘u|V…™Ç”CF[´¤o¥{G°º\—hì ßvÅ½İŒãª45¨½"C2+øwp *”’~D ûŒºßh%#î	<†,’Í²ŠÀtu2^<ûW&ûl[uÜÕF7éÌQˆ´†Lï<6ÇÒNBAN’”rFB¼İâ/%]†–ÁŠÆÈùô§
S úpqn?š‰¬Z,†Qq#a/®…k¾<£UÛ¸Ïq“Ó©$hª6·X=H.ğù$4¬â-	C[­ó¢jOo­ñ<Á¾@ˆ¾¥‘Ö»MlP•™,+ƒVÕª”œ¤¼É)<ä§ÓQCÓã?ë£#Â×‘²Œº>L‡Ø-Ä[†
)³£‰m¥Ã´Šào­ØE´òÀ±`Ò“1Œ?DO”1#ËC£y!öèÒÔ×Ñ©opˆvPNÅ¿€P¿älì
ï”nÀëA>Vü}><w—åò>E‚•çøm­³3Ye¹ì¤vGã‡	úğn¤ä,¸ó ]¢Å&•Ü–Ÿ–5zaÀß7S——s¸‘¬ç\ßaŒnv|xsõÆ$saS‚Üœöfƒ¶TèkƒİqÑ`ğ}[P=ù@ıˆ­¾÷¸åø¡ˆÖY@’>rƒ2êú´—xÿ´…“ƒIŠÕ’Ü˜Å²ù´)õn–ÈÇ”Ø=–ë;•×ã¨Ó¡ßDPFD\e…gPpt&€3×ÑÃ{H^#uEà 0ÎË\\6ålœÚ„Í2,k¶·õÉkV°]DZìİô‰*g7İêXIep¾È¢wÇ¯8<HJ‹¶‡¾Äó†ÍvŸ¹¼›û& œ’¨ÊËwÁ Ñ'=ëÏ¤ºØ“¯&¨9”£Ÿ¼bêÌ,•'©Ùš|`_7Ùµğ_Ô&iøæ·¡O,¹ä+Şİäˆ/2…ùJ‘'±O;„”CIÚ©v½Ô,õ8bÔ+ª÷Ú–¼Îı/½”9ÈaÕ'€	›ßó£Ö´ji­µHÍÚîà–®++uOmsômeÏ9#;Æû¥‘X,"±31êp@ju8ğşñ¥gÉàwQÜ€ÀAæu‚o—VñúÔˆ—§-J
Gá`/ZÔÕ£•™—ĞÇ…ôâ9˜Î¹u[ñÇ]ëwç33\Ì=ù@$&‘60¶NÖT‚±¤:Û§Â?´Åy›u$Øğ¬`ºğNÈ1Bè±æH«×†Ä$ÓŒ]mæ0¹,³s¯§vşK{eıñû«‰®"şãLu
&
?ëLãwÂ"®Vã¯}qS¸ÿ³T‚=*ô“¶±i¼±¸N–…£ÃÉ…Ó¦7p\sy?ÂÜ"ì:>z–R"{D*¿ÿ•¸¡¯ ;›b	²ù;ç¡_üD GSf.€ÆaÕ¦^0˜ydÄJsû÷ÒLüS\Êd•UÄ^­"ó]ZŞ°Û3;çå	W¿¹n¹ñ°‚ìÕ‹ ev„
)È4û¼­ºt×‚’¼o²ŸP½òOD‰K-k½Ÿ8çpÒ.³ûêMW–· OkĞ;›=«ORkMôˆ"{ı^û<J661¶êîƒƒÿÎów×óœÒ·h'¾ŸJØ\hÕè²ÀÂâ(ó‰§mîÓÙ€£gêJğf¨ÓúˆÚ.ò.Ÿ¥¼Íì¸,öâÖŒE³¬Ê§6U>–ÕZ½y±›çìó4×à"&v]z×ã¥>PdYœj3JùËlkfŠNqCZ}Î'Wnâ×R¦:ê¯Õì„D^¡¹¹IÀ‹ñi.&æ®‡¿vWÁ“½\tl³Ò…pË(è‚Ìc<ç¾ ß_“"İGd÷5¤y§¶é%]OYËë¡ÑMMÕ··}£b<ˆëeˆ ìg8¼Ò@ó»ÔÂ”$Qı{oÉñ“YJ×0@§6á;ûÔòìIöõ9U³,Ü¹ÔÊ°³FvÄ|eoK%¹§:g°Ú•Ì¬s¼»­Yú›l†Àª.L”ÍBÏ£µ>‰´ƒ¤2õ•G×Sa%˜»	¢¹<š2TÊke'-Hr„©õë‰ 6©å)Ìkc3]xClğÜ2OD »FD-`)ÓŸMÎ®Å¥å+d‰ùuBÆoyV4ìúÇ2À—÷µøq)íã>êºa­WJÏ=?Šˆ¹Æv[¦±ı%}…­&Ì[>
	%>¬Rësê?wB­ëÒŠrŠ®Ã=+{b¸ª¦Cü:Óf¹×Z;qÇn\¦×AévùKCğÿèB¡|SÛç…*ëóé³€¼´Øì®¦S¸5B]¹ğO®©›ÈŠˆ}Í‚ÈØæ”,^Ü¬Ô²¨ÁOôƒ¨³îØà:ÿ
ñ ÂĞØ‰Ğ§°Ò¾(*
=Ø!átÖílÄ¾Kxï¼HÃŒ'ºEìƒŞ‰ÄZÚ ÇÀ|+å´Œ’lbııvˆ	×¦*Ûñ$-‰NjÚ©aØÊ\ò0tiQu^³QÏÓÀA÷‹n•W™µÉhêMròÜ'ÃFg)+aè„/ğÜÄDtJz•DØÕw?_¬¶EÀñş‘‡ëÙO?Ø|ÑvÈ{!"•¨\ÎVÕJZ¦Æ'Yà>@n”Óc´ŒÆ™·`l@ÜJ²--ıÒìoüÒo¦=Bv«ñÂ‚zÊnC(5uDÂÃNâ[‹ö¾‚«Yâ¯ø.ë¸69¹ÆøÀ8;HŒ/Š±ÓdËÓ?	ˆN,²	…9ª×~Âp\óµ¨7ªiLü÷ÎPgÆ…hBfÃ²/6mÕÿÖ~Q‹E¥ãP¼­û?úRÇ<óú§`<£7ÚUöm»jVüæÑ¶Q¦tpwY{’ö|mÎ^Ë73œGÏ!Q‚ ñwYA©©ö ‘ƒÒ’ŸÈ¡'FÈ*Uƒ—àÆáFe—(fù×0šˆÒ‹6É¥4Ğ¹Û+›É­±"‹ AÓéêËèıXÎÆkE2 ‹iÓ@*°™…ğøwåœígy;l´Š?áAmËfáôÅ*W¾×\“¤Ì 6!T_ûŞî/´CMnƒpÌ›â¼}lè™<«ü†!Ù}ö:>|-FNñZYFsp“x ¨ …Ç8à/›LÓm\ü•ãköË0°,1ø™ğàöÁF|fW]I%&¦Ü“Üíhõi ã™^3ıúş¢[7¬ ü×ÄÌ6kSjÂ%?ÚµzŒAºÓ\Ï‚ a„ÿ7èŠ~év9ß_°²Zœ„ ‘¥L ã<tvlÑ>Ô¢š˜ªe¡ô!¡~åí=„BPìƒ°âYŞgJÌŞœ0§…üÿYËíu<´Æ¡Ê^˜±ER†¡x•Cóº»a‡İ°ŸÑÌ>U#Õû?¾óàû}Zz{sö£iÒk ´Vô³5è¢‘Ï4¢—±ø`cJ7ôº­¿Nó;z.{å™ıwj<êg†¶í%IåSİûÔbİ?§r…«¹/K{ĞZ¥’øğï\rôÙöA	?²ÕÀ2`o&Õxtæc5@ZD÷gĞÎîñÍ~q¸Ñ®ÆÊRxä—Õ ÑPÅ#2Tğ¤”>§Í¡Íãü4<ÜÕÀ‘¨µvc¨İ,P¯×…mê¥9Q*ó÷µÂhä"­ËZ§i<¶¤®òA%÷]‘@Ä‚„ù€œ¤š™:"½«àí†{ÆßìİâØdOÚRW§JQ§;8Zï–³£§6é=Ë_Qñt×ôÊå2ı»³Q<<$Po«|y ¬·{®e…Àä¯—KjÚÙ3_şš‘(·µç,€AÕWŞ1½rÌ33C/öCgR¨p®Ä`÷ó— ©ø;ãÍù§…2Vo,ê7ñìä$ï Æ6M1´Ñs~º®ƒ„K·aş‰!…ü³'ùç$s* ÔÀÕzVËŸ©i”P)¿Ûs¨Ä ¸¹<ÌD¨nCëAR?AI&"™"Öhë(äB5+À‰K_œrµÕÄ#ŒIG­6@àÎBG˜«9*»Jâ"à»lò=HÜ¬êÁé£F¾Ÿ·À¹	›.ˆ•d²&p‹`=ØÙi«.´åp}_Üú¥}VËy±*bJIXŸµ´mâàd©´Òà²d6²*I®ô–`k'ÊP¬ü>¹gønõË^­A>n9Ç¸~Òô3[J¶ıuCmÓ+XM_%•P\E şk¥9Ã¼s½vv qPŒ½–`–_Ï’3w5©44µc,±^Jt«áºN¿QÔ¶ÄI{MÉ¼H«:æÆ}Eæ}×ÄÅñÃ\¦;‡³D@ßCÕÂ†~ëh†JHóBh÷eÿpVûÙ{gAtU¹cinùÒÔ
Xa¶[¡˜¥êÈ²v£-ÏB@®º†hô£àø¹ô¹BÄI¥˜_ëÕ<qÒÈyùH24‚ô
éò ¹p’Œí“Mõ
İ{ô(|=e¿}*×ö½½ôµV9øí®‘6RU-êJœpÒ?j[Ü§º¨	,@Ûbéƒ ³Ÿ+ş‹8ÎN°ûôù—ß¼#™Ä¯,hµmÄ„«[Ov}Ÿk¿VWñ2à j‚Æğ=Oì
¡ŞñJ+–˜Ğ–ØÊb\âiÁ¹YC7G¯¶ÎlôĞ	ıí&º”¡Ü¿Q¥‹{½ÉÑë¦›ó82¾$&l¯s(ÔVr ˆwâFEÆâ9ŸµÜ¾¤H$J€!ş[ğ5ÊBE\ ›GÙA¥‡ÒwŸôä$¿Èÿ8›öC³dá¤†sVƒ7pıT~óš´è·òÕŒÈRx§oê÷ƒÉÚ)ãRª+]Iµy^[âqSòæù…âÛÖgîÑ¨€Ø1†Fµ%™+•¢'	Şœ©ëT9»øl¦ˆõÿ×ü·[(†Êõ·•¢ì
HEÛ=ÓH­Ân.?¼ê²{cìM²v67‡0†£cWLI¿È`«Fşˆ5=ôqÃ¶àûûfp6¤8ÜœáÁ-°Å„g¡ö÷*•¦Xí!#4@T5f•Â+›PÊÓ ø´6Ù?„iÍìŠ°yZ¾0(Ìáöü»ªif9“Dûø=ÙVÅÜ¦2½ÕÕ;J¦”gY€N&¼xÈõ†%:ïÓÚßEİŠY×8Aíiş<şYIÜuµ¯9Œ«İ²Ç¿%h`‰½ŸM‘¦àHØ¢¯úğp³;/ªÜÌ”jskì¢JşÿÔ,/[¿õ?vî©iè¸ï.6T Â6àæugÇíåÙÈ Ğ7«P2ö!“PéQè¨˜Ù®zH£á²
fa°Çš2BµO9A²v²è7¾/GÌ;œ?wÌ1¯Ú&P[<Ëà(C	`ğ‹Ş(6j®ŒÒïÃ¯ñ+İBÂ)šF,kr™ã†ößX´ *Pş†7ı»‡uŞ^µ ×…F2İ"~k8&T	uI;˜²Æj$\§Œf²’qÙïcrßRõ©]¤Xb÷WÁ8øğ~\ñÇl¦É1ykOpP>£TL…°ÿûú\ô^À‰™CƒoqOıh|E¥Ÿàù+øğË5ıâ×ÿúëŞó¥~ÛåE	ğ5u¬³%of/v
T,îÒüÎæ–Ùæ(@±bKßmÃ)€şô÷-ƒöòæ&2å›¾câÓ»¦<Ù¯’’Ïû£Ç–—Ø¾$iEFnÛ
ûTÕ€s¯ß…‘\ßW.ŸÉĞ¿çO£4¹Z¢£VÍ¨¡E¥vSÊË÷€Au$ıp¶Ój¯*şÉJ¾Ò¨©I ~¦?Hğï“Ö8eí´¾ºzi¨Ôi Ò)=Ç°&8â5´h¿Ç½ÓÈNù	§üÃúg.Ú_P9:IJVz„öuÛîØD›-®ÊÛfÙF•2Qî&—®”Oæ~©iâÿöÉîëÈÈ:ëJ‡ER£@8¡˜ÓÛÆ´<.Æê=¸tÃŒ¨dmtSÒ4_Á
I×·ŒëåFMÔ¢]×¿éúÉÉ¹vJáQ…Ñ· Ö]Axí‡j oÑÅÌ
RûŸ<•\*àv zŒzñ°Ê
^v&‰\'ùÑ‘d¥@&C JYä;Pİç¹)İ)o%wôv²íòıÚóã¾aNÖnz#Cõ)'€„•Zµâ“_÷†Ó$rö-°ıÆ1¼!ïéìs4TUÀÔIhu×SÏO|5Q-Â‹$q/œC€)Ši“ğÎ\"éóíøQô/+ÑVXªG¥_³ÔSÁWÌJ;†Ü1¡_xôWx-ªL—«ÔS=—~O‰RøÒãë_´Í>_1€9%Ï`g¸o}{¦ÌÿÎ%.-°œ5òâ8¡)­ÑBÉŸóÔÔß“¨à}Czñ/^BÉÛ(=~n¬a|	)¢`£Ç)º•.€ûÂ¿³ˆìdlƒ&T–ÀÒíìâÔns‰
œIE•Ù‰ŸkÑ8ˆKã¢Æ:¯>á†Û};Ş_Äå Jøîûúml¬³gïá`po×Kär¾bïà {X±…ø¶¬¾ƒ˜hs–¡£¤¢º!«ÙÉä™hø•wj-µ‚øcØğ:V .@Å¨ÏbkrÄ
ù`{¶Âµôw§xçÒ½èÙUÃÙ¸x²ˆEí˜sƒçëˆóì@ÒØtL<XMé€M†Œiæ\/ôµFÛ”[ÀU|/#ì»œ'™:ÊRt¥‘RC—+á2›ÕptáÇ‡-ÀØÖææ”A`šíLh“‹^:í.ÔÃùÇµ°û°úÍ­|ĞõÕ'Õ5¸[C¾ØA)	,µöTÃ.äœdÉK‘¹/ˆ—,®·F…G}*½Ë4ªæÀÉé.ZMt/ásİA•F‰TT[ÄöŸn=L¤¡¬ÛÒ(şx}3çeíM×ò€Û{©ımÆåƒ
)şU.ª|[çcHÛzSd,‡‹à­“©Ÿ¾(‚Â5È<”2úô4ON9Šñ6‘(¥¯áh†,´ŸÚß¼Sû² G[‚ÇÛßi¼ë9dK·îØLıôãz5íÛİÎÿĞvïšÒ­ÕùÍ4¨CÕ˜²µ-(p	²(ÄPH²ö{"¢¢÷™›Èõn­¥Õå hZ¹U[Cå„öæV€BÏ›Ş‰ªéa§³{¦)F ênjp)} ıê¦éŞùˆĞüÁôÊ#
E”*ã]ºQÅæ´ëü$Ú¸}*‰º×ß°Òµ3ƒèWg?å ^e¾XÑCÑö‹ ¿)vÕKl¤ŠºS¨`!YôÉ;8o'z¨c<I‰-«Í'‰-³-óªõUí·2“‰0ßH»g@İrãÂ“Dj¸fâL8Sn[èsy>ÛwäÎÏ”‹µãÎ}"©‚Å9Â@çdá?hoÂ¢ %ÉF—¥¡ÿmÅ”úí&
6P°oç6àöüîÎÊ	ãÕ9Ãb/J/|n‘DUäMp…ºÓ)22#É	x4rèxØóxœ"¶óìJ~cÓÔŠè½çøÇ[Rz,4k~øDYÃ¼Û”£r‰7t>;M˜ô>õ ‹çÍk!`iÌr’ïbH‰ob³UÕë…Y²‡î‘‘é_gYDXfeŒ|•ÍW jcµæ¸“şD­å,¾B¥#À!€~l¸<	(YºşÒZ?€
–Ùy÷/R–X˜‹úe¹ uÅD'ê¼ë_uqãâM“[ÈŞL•Ùœ©ÙŒID¸m~ë2¢ï%ÙªßU˜æŒk$ÜJ¾*ì4B$¢™K#¨¥Y¦2"àÁ™ŸŒÄ7¯;×¦­ûgšØÄÅVnUÓåS™IÚƒG£|o`â–\`°óªfJüşM ­ß¶Ğ8@ù¬ïº‰ù'r€×”d_›ÅœÒWA1y“ù'­íı8R;™K‹<İŸy‹[$	xîzd,L1ÉÏ~\°¹ÇM[_,ŞIê!²O$s…Ö—Æ‰‹"ÇìÊú³ây?wR×Jmÿ1fS:Ø	:Ó•·ÁØlw¯&fÃŸ´ã!áEÖ¶ÄÈti ŸÈâÒ¥$›U³Ë‹(¸#NlHKÉ_ÊYÏ¡k›&:©ZøYpª~¨ï‘JµÖ¢áÎÌ@—–¼-C$ÜG ?ÍZ½ÔH’.J±‚èÑcCuÅWö‹³ìN?9ûŸ¬XûãÍŒ\lÜöÔ½“7^Î±Ê´»:™£ÊG5CŒŒlq¼Óû-äé'³gıf‹Çöãëb"ªa_<
Ğfˆ–¾¤¦¼µQFê‰£'¤èïŞ7g(ã«å}šÏÜà8ª¹´îÌG7Æòé|×•øïh®…ˆáe7‘^ö_0kÆ‹~Ö.§·âãŒá"¼»á”4àC¿-æ6¤^î•(êKÈjÇé¯ï4¬ ªXãkäå&¹ğ&´(ÿO±”œ¬ôİ3İKC(Æ‚]õª£YPıeN…ßÉB+r™Ò±á¦[ }L¶¼Fg/j,®ç
]ô‚g"><ÊñW&i“×N¼³½XŒ!î)·ÿ]ïÓ>´ bó¾’[Îy< PÜD3şCŠ€¡¦ÎQ$…¯îŞ£%EÔ¢ÍÅQÈÂ»¯èkñ|mîƒöŞËaŸ4Ä]Ügè·@².IX‚›£k÷xÀÔPÿ–Ñšd=éšŒªĞgÊ.ï:s:*Æ5Tôåî‹šqo„qíÌ§î]7wğµ`­Ç`G½–àíšù¤Ø=Q™ŞLv}8äTbYE›.‹Tªú¿€î’Œ\z¢pl›Áœ‘:Øi¶ğ1	lÇfXk‰PÀÈŒ'ƒşZxx- öëÀùÉŸF›‚å5<Î>HŞ¬§]b7Ùd2hº‹Ù¢YÀÇÚ½Ízí:£"«­ì•`Vº]I|»+¨±AÊêVÒÉ9bë¥CêAY%àB(UÉvûùJ…ğ­_¹}æ4¾c<®÷ğõnkœœ ûà2ìDË:jdv™XnÂñÌè0çwDaQ4Õ¶ÒçÁ›Joç|…ä¯ÛHÕ"\‹"tİF¤‰IÔyÀî¿ø‡µ¼‡Ü E@8jHô.ÂÜ†ÈiÙ\î&x¼g¢Zi¬*÷1ê‚«Zë…[º2ƒÏu>şj‰9~;•`1Æª6U©”#Õ4”½l6~Ö{ª{hçÂğ'è¦ºØ¯Õñ]k÷ú€¸)·—f@)„UKøhùº·xêãüÆ%{S jâ½ãwäCcÇ±¹	 ƒ}%¸DZB¦YŠ"pVşq§êÁÍÓp ³à™î"	 ²máÄßìuyÓœ2>~mÖscfö+ê_[t÷!×¨™Š>®•ìùX“XšÏ«l 6øß£Q¸ïÆÎk“ÿñ„àøsy ~¬-î-tÑ%ÎÄÀTïÛjpöğ¸|j¦}Ø0ş›MOzÜN%f4}l=¸õë)ü¥O ¾ŒÉoMÕ6c€C;–45h‚Eu£µa&ÿx¥ıE'#N"P‘~ëä	[•^ËáJŸÏuË®32ß’Ø¯†î6Ç“¦š2Òì¹?ôÔf¾ïEûôövf^Şğ$Ó²·“&:÷Ø*ñ­™ìÕÛXŒş+_İÄCü5„5«Ÿ(‡å#XñFNŒàú¥dªÔXebœˆÌ—	¬.„¯Æ#“j.Â,3‡C¶º€XÅÎTv¥s
W"ÍJ5ÂŞäkEÇÁL›§*9dÇımÿGÏŸ›ı©d¶ÉL§Ls²½Öp;hJ?Nõ“CÃ,i—X*²ø±“%9òn\9ëVÈ¯¬aÉåXûåDG=Ê¹¨ì}Gİ¯S+[›sÓÎ.8iıWneK™5KôÛ}ùå¨eÈ $‡ıtÛ×çš¤~®¶»ƒÍæêgÁ‹ÀùÁN)sOğVyÛ”SåëÙİbjÂ\ª'jÂÏ(Æ‘r|¶}÷èoÜõÔ²ÍBn0;]ºo¨Èod†\™UyÌR}Û¸òbœk	ä)Á¶bëüc,-¬Sã|_îy©0—rjgĞ~FaG“;	à•Ù+ı	7İ†èëC‹[.ç»âî_¡‰s¹¡“5Ï¯°µÃ× A®ÈüC@è…®\‡ãdÚ;JÈšMäE$…£ü4ú¬›™ñFk3P"Æn†TŸË=B‰òl­lG»/÷³Œ¤9N¹„ÇßK[°çş€j…}üâÈûhì‹ÉõQd\” ÒCˆ7 4VÈ†HÌå¹¶İ’tFñ roÔÃ ó³
.vQ3ïôB?.Gò3&=¸•F¬EÍJ‚]@ÓŞ¸a<Æê}Âëà²šş5”ó/È
át8)ÓªKøW'çhLÍ”pèA¨Oââj]ƒ]m¾Á—Q’ÀÄzƒpNºÛŸ¸Wt3À?8*¼JQaï"/ey¬&PñÄr¹Z‹Ğ¤G4¬ˆzÛĞÕó2Q¾E’Øù	ÇŒ<Ì^‰è÷ç³ì&Úx´9ö‚-ÑÑ7D/¯‰iÚOäC²·å¦€¼	|=Ë/ó„-ÙÛ¦ì<óúÏàOÀŞÀhâ¶â8ü¬óNÿ9ÙA°†ÎD'ÅfŒıœIj¡Å–Ù)¸<1Èİ}å`&dÎ˜óÁb(ù)ğ$*‰Å†tp³§’/:M€úQ?=!B/È-M¢^~°‘Ó)[eë¶çŞd7Á¡Ê’uWœñ¿íÃsX–u£×·à¬~ÜVøe_e+;võÉÇ G2Œ¿ï!~1°uçÊGAér=\,oŞI$Ô·«0²Æ»„ùkz[Ğ™×şoU’îŞÔ/€Õ¹W/+>ûèÛä>œÂí!;^.äRÕ’7£fzú®¶AQi]–.İ#¿'ö    ¹Ì*,ò»g Ñº€Àê5WL±Ägû    YZ