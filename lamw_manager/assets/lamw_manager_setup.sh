#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="913898615"
MD5="ed5b5a2cace9e88a723ac8e9fe04674d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26632"
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
	echo Date of packaging: Fri Feb 18 19:50:04 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿgÆ] ¼}•À1Dd]‡Á›PætİDø‘0¹ÓC¤Eø…^PVà+=Ç2ÉÈF§í·’#ˆòxIıØ„:5äOÇÒZ±ˆ,e÷\ŠDÏ’Ä»s3W)İl.»áùaè}Q“-Øwï=ÂĞÚ[i¢5Ìe—ãÌ†cëçá`È°w$nğ¥^hùë‰=·~“ddiª”_yŞé¹Jï›Ù*¥k
0´Îò8¹B,Ë‰Ú•Çq²9¸‡VšÎñø.§y‹ÅàXU~…+TqÓ¨™1ı²[÷Š™8è|tõç/QØ’Ô§§] ÷eX]ËşÒÎ;.´¡Ø 'Å!¼ô~0¹¶\Òš (‰mÃP®ƒÎ“ƒşß¾hY<šÆºEwk8YC§Ì„Alr¢'øD‘†ñ¥0tĞíÏÏ¯HgOŸ7¸\T7ºu¬µY©¸ñı´©o@€¾;p(hH¤$ûì’òÙµ Ÿ^sÀ;„¥AL‰.ö^;ñ¥f“Ú à©Éõ«2~$ÿó#ÏvQ§©î)æövhKøæ}plº"•ÒÍÕè~ËÕZ-)dì¹]ÕnUœùr<ÿê¾ã>ó¶cÿãˆYşHkˆ­Ëƒh+ìo†ËÎa²–Ó¦üYâX"¤ÇX¯Z–Œºg½ıÒĞ>-OM¹ĞY}!±Œ.gÆS)ò²J—h: ['9‡Öx2!z6 ¬µİBgxøI"€\ÑÉ 2:Çø&ğˆ†Š_†­ƒ»fZ^Îş¡ÄÖ°AZ°wù!~>°‡ìÙU·,0º«n¬ªx±²KwË
IÁ!{uÿiv,NZ´øÍàšóù ŞÅË²1Ev)äPl·|®İZ¼Š‹xº]ŒÕLö[£üÕïTfÊ½³ñŠ^¥ãb˜ë¥¢Ok¦âL”-X¸ÄoÁ õ›hEDEÎK-J|ÇË¶Ş:î“ìà-G§_Áç³Áÿù>U¤|\t#JbqN%™€1¢±ËŠÚÔ®‰UÅ†BÌOÆd³@..å_Íò¾YŞ•~ÖØÒÀR6X­b5dÿÇ jƒó3&_˜;ª0ßiàçÒ!¾R³S´øâÔ•ÃxO0Â¥âOKE}°¦0Ö{¥AL¶LÜ#AdgP°B~Â·«èà¯¸>Ú*á\sW eÚš%´¥vó©¼ø$ sDŒU˜ò>NÛBgê.i5%¦®äŸu÷cÙ|Õ<™S—w7Â êl½e\<İø€È;ÙjÃ½n™µËk1XWk«¹2GÛL£72ë\M, 0s4at¶Ûß%ê¶í“5ã‘	g[o>jiÓŞĞ¬…ŒÁ¶	˜Ãc/ë”ZÃÑ`A£5J·è5²®cV·àÑìp»n"ò3‰µ¢Øã1(ãÒÜNñÊ*s·ª	BôJšÆU}şÃ4M3vÏ£ØPôú"ÊÈ{¶AUÀŠ‡Á%U¡ØRèˆÜ¡6ôÿÏˆ»ñ².BİJütÃL÷×Ã¥Š-»•Î‡ËŒ:³ätÑ³ê†^Õ,ãÍh—¦ãØ9¡?ÿµ¯NÂ¥™óè¾q1Û…Pãuºg4‡8Î-2—Ğª6ÎÏTP—’*m¨É>¬şËJÔ‰3ûÍ¥²vjíLmJ¨™£’õ(=„~oXw=öB^#*îÖVwô$:Ö<nèlÑ…[Ú´’£Z¶K«w¹>—áß€O\Ö¨s£û$àáM|ï&TV,¬ésrÓ¶öíÅãEı¥X¬ ŞÈ3Ó7©]5€&×ìšEÈÜy† ”ñá3×…UiHÌV¹0Œ×yu¢‡€ obæ3š¥2Å2Åf“oŠ"¨|Ğ›Âi€Im·İHäİ0V)>ÂøC#€èîÔ‘b?®>dv§—!Û€P2N¼W‘+Áo{c™ı›#—|çbË³õj<_cfÖİGï5K$Îm6áÁÍglİùõe4èÈã69F©ú7¿§²Ç¯ZVÉ™6(u–j]$e»¸«å€¬Ğ§
~ Êun™ZøĞåü
ş’;‡Àz°z7”Úò½ÁG…_a‰÷BAá*UÓCİ¢±u%ì-Ó(îÖE¸ô0ph7NZfŒX¬IÖã,D¹§jl¨b¬Ûõëî®mC±­€u/Ìp8Ë@zEùĞ2_şä„¼Ğ`1NR>:®×©¥‚¼î5‚¤ˆ€„aò}êV$Ò{#âdÎ{“çûEÑİÌÍ¨ù‡É J¦avì·{•Wäçà©x†.UCeˆ˜šÄ{¹÷`õ»90#âq›ÅÓÿƒ¿Èe‡ZTdgj“”[æòöO’?‰»’ß5¨w9…ÏËÁfÔ–DÉ·¢P¨*Îf:ç!çD'Ş•¢—µ–x¤Ê'ğZJmLfşKa#™İ§Y Mà–j5Şß²ÌŸSÖH¾vÕLîC6ıHgtÇ³Iµ[ö}Ï÷c!ÈÍ&é2.O9¥­­]ıÙ8Ã¾›ç†u›ShZH¸ã×ëÆmQ±Ö»üš@¼™.zr/gš`"*Ò‚HBèû’¯ ñdëùÑßAğ”-Oş-úÖ>ÍmNËxy6ÄÈÄyºë«!ÈºÏµ„éßÃˆ|Ñ§&ãâé$ØİôôFµ*32‘Ö	f´Ä5ZZÆæŒuV9mã£bV¿î8YPI~ˆ
\#áò®Hæf÷×ßêƒ[=.'­;†CCLÔ ¸BGaĞºXÌw¾™Jÿ~•‰Ø~ŞRí:ar_ØÉ×íCfĞ;•˜>¢Æ„¦}µOt<!{»N¨sğp½ò{Î
Œ!t³ÜK=†}*‡„Fµªåá¯£…4}ÑõNÅœSÏ‘ß±’F½úÄ—jˆÿÚ¾¡Øß¨·”†ÎPˆÕ§s0S8•¿:¤PPÿ	›/÷Ø°õæõ/$”¦½%ŒşDøKtGÜ•0M08Z„”Óğ¡Ôäv.SFCÌÓ õ–WØíÌ¢!Íğ\,ésXaŸ…\¤´ Ê]ówrÕ½ŒÏ`’IŞHÛ!!Œó"\ˆ˜M…ôÑòYè|ñÀY°_Ñ\ ªå×˜Œw¶¢	3$ôŠ’Ì_9¯….YÃîØ¬7#j1ôD@›a>¯ö>€igfÕ\‚+¼¶:<	Ù.ëÓ”ƒk*œ•3:ÃQñøUê>6üc?ßë}˜Í¦`8úğú›b4Íft	
z0yEçeİYÄEÉ1¬Lz—Ìk?aö€ší(d}ˆ8Fï¼LvCëÍ³$HjqP|:2[20—ó89üœıg$£wßrÛ¸P(ì‡/G&œ85?á=ÏÖıçĞ?œÁ•–tÍÕ-ñ·ÿ¿½+]{8ÿUÄGIÕäb+T
:¾nú.*Uç°úÏ(_o’mtÏ½ .Ã“bOUén¥w15÷İÎ³¸¬5$YŠH œ¾N÷C#Ù¹zlyÇV®õhÒ`hi"’?° O¨ÁY9šõF¥œşë5Ú Ç 2šÒ#Ø‚¡B1ss.^ÂÎ(ø]¦Áô‡û‡İÔ°'D–ÖcÙÌBÒäLŠ¦Ñú²ƒĞJ¦kùçQÒ}oá1Ã¥±ùPJ¤T:ˆ¤÷tªÙíÖ‘9Zjú˜ü‚^éì­“øNÈ"¬ï×V"4Gg¶JY‰-¾5ŸJ²VÉáÔœMN«
6it¶‘’©òF"#êFí3ª«7	“JË3·‘§-¡rËÎZWe&ÊS×œ3Ş?D?ˆ»÷g‚ò¶W­¯şµºáó˜D}alÀ=Kv*v,¼X†ŸIÆZ¸T˜ŸØ¾…-®›–n3c€\›@äŞ=;s'ãòªşèkóî¨¿¨}Ò*­P»v‚iCĞıOXËQş
Ë¥v%û*}á`'sñ½D¸Ÿ€ÛL¶l!ÂÂ¡šàßN4‘Ú·ÂJg˜`ç¶7^#Ÿ|‹OêBMªÄó0rbÒîîäbQğoüxE•ïŒâ¨Äö‹İÓb™ ìÔ¥Fè’®¶Uå‘Ş>"%é ~G†‰÷k’î(/ª¨5Ó€“jOõşÂ0Å5Ş%xğ«›ïe–3p¤XîAi›k&T§ıGM±T|.ˆGIêéÒû;ë:îÃ«aİ¤ØUQ<¼là÷w\f“5~£dPrŠUóîı=r§^ßúöãæu‚ÜÄ0Ex%rˆuúh{r7X—.ÊS{Ä>ÀtBÖµLlñød¤{-I3(ÚÚCººİoAÕ‚±/ÿÉ÷³÷@â¹¨¯Åvu©

*	9İÏÈjãŸX5—
ˆ"Óçp?›µ+¨fO[_YS—6É—‘>ñÜd9ä¯[HoË¡ÜÍOBA 1t âŠÔ˜	ôµuûänv›8†‚5ÍuŠÚĞß(=|e%’ôyºÏÎ€„ÀnÍfß$‡l»M´Èk¿ sÒtUH÷
G¡YêF]?1ğ#ÄÃfÉ—üoª\Š¯8wòÄ[œôi:S¼ ¬¢“	zşÂz²¢æh\€¶¬?­rOÑ(´Ü Ç¹ pº§b‡óàBÇş˜ ~§a?#Vìv‡äƒ·IEÄI…º˜ÄèÅ!É¨ófCKæŒ79P?L
p]DÛ‡ö»p„G“u:EµÿäY
îÅØû«@¢;€±Ø´¼A¡Q1§i4U‰¶ ¡I¤a˜G‹-]ÙO,oc½Ÿ[S„0~]$f_Á
Äá†Õ›¶=7’H=IÅ(“¨P¨–Ê‡’Õ R1Õ;ş¾¤¬ğ£bÕgÖnzt¬1£·æf$˜7z®dä}¥&¿°PSı&]\Åµ1pß&ú^ 0._%†õ=Õ€0×zæ‡ªü×O«©ÓÛv­›:©»áŠEpv eÌÛ±U]øCL©1òFW£uÓõX,ˆ$¬Šq6LÍµùâ†L¦Ôş
NdÅp¾å~‘I2i¤'7ñn„ú>‚Ã&³/|¿úÏ{ˆ£§=Îøg7ñ³Qå¼\é´U?°T,ùÚ„åĞ-U]e«ÙÑÜ¦x<JË—+šÍşÂ‘K#vƒÏÏ=DÈ“O¾¿Áùe5'²nÚ¬ˆ¿¨ô„¿@ôê_dË|ŠdU ¡A”Ur·êÏ¶öàÜuiQØCøÈnÓÇVî  %„³É3wMÊEºâxËZ+Z|†yó³à?>¬ßÚ›ßæ³ÁÑ,fnå™ÚMÂå‚æüëÖ‘§ùiõeÄî´u§¯şµ§)B^ôÜ0)-„è3£`…a­Ym_Åî³vI*rP{\àùE“"İÓjILË†¿'`¢§Eó-ƒ?â¨¬9w_Pb¼! ÿqƒm N1|0. Éà,é<bkSfTÖ»*ÌT^(ûiQ4Ín ‘ÈàÇÕÒ1ßC,TN#
`˜à¿´£gÇØŒŞ Ø«\‹¶ÏÃ‹‰qLÙ?¨#õŒ¯]cÜ}Wâ0D	œî¹w
jW‘”n?K7OC0,A*‹öò{9ŸÛ/H`A [9×¼¿²Ê2ôDŠ–£=ŸI4$yôEÒølCgò3Rx÷÷ ƒ†ösy&H/BßÒ(§ƒ×Š0R…£I™l¶d˜1ë÷Wá]N•:‘ëĞ¨ILbÓó=xø“Åá2)Æ6CIT¾®OüØ{vm¶aDÖoˆºı„%o¸‡Üì›½²¼.n½Ü8ª‹1éFU—]|§í«ZTå~édâÊÌ†Å«%áiI+`ıóF¯(®-õág0kxgäØöæÅÛ¾™~iv±"z¬5 Êäò²¸æw%’ÕÈÒ8×N²ùè©pÕ^Ğ½~­ƒ…½+`<X€5}7t^¥b^¬v™å ÏÈ’hÊ“![XÓyaœìÒ¬4ìÑ€4rFb
/å	ÖûªÓÙÜÿEjß»Ÿ×¤ÔÜ!>SA_cî”ÒrûHÃ¹›¿{Šeş#4«ˆê¡LµäÚ—÷‹½äÃı"«ì*¶‡)Õ.WXâ¬-ìŸ…/ƒsİëåAğvÿ°_ú­ÎÚ.j×#@ƒ³ X²-•‰;OU9¬/‡¹™ äİIw0(Åá»§*kÄô»îC-vİM5éÿ·û9WİÎw(Ï¢“~¯gã)WÍ»°#ÃY1à/&İ¾X´då¡]ïÈ'ûã™˜ñî"Ö¬ZVÎÖÑOÄÍH[œxhù’•Ï‘÷#rş§åbÛ*¶u½|yİàVŒôó<„Öíúå¢İ‰ª­ä;ÁoûY-ùÏ	Å§-í ª»YnÂ¢¶êC¾#Â&‘™Ë(_õŠÁ§º«¸b£ĞO‹¾pÊ2¸çŸ¥¿dˆÁ—FğÅ£®¼YH­´¿«OèVÊÊîO&¿¿ñ@Á¡âŸïqÛX¿[j€›%ÈŸuıw^<‚6ìÓ=÷ôß¥ÏÍî…ŒçzõNs¥'³2á'm{«Ï|lNp2}¹TŠ -lVwcVép>IÚÍ@[ĞÖK>œÁFSÅxæwÙÓ+È–\ÿ"U?Y6ÁºVÆ:qœHöË²¾éLÿ¶,â¥_·Ê••¶ŠYİÀ2EôFËâE–>$aÑ¹HÚØÂS¥Øî³â¹÷_H!È‰€9-Ìˆ:Cın—È„Pvö|.ÙGÎ:°ñô¢··]$	áHƒ`Ğreö—‰³!%4²=ª:1W94ÕÅbé%Ífb ÖÀ&ÄzÎ?WQ¨A¿‡ÿ\±!%¯ÂmÒí'í«µXe“íÉ÷nÈ91™Œ¾:•¶"³–(¶úæ–K,v6«®ó§Ãcw¤)?Kl•WtGïbd@Öß¼¼kˆØìÎYŸ—‚ÌmïnÕÇy—ÿ0Ÿ˜Oö¢ğï­‚· :Fî&`¢"œD‘ªÉk%Rò
L¥€ğãÈh:¶à,üğ:NßñRÒó|<T„¨T€Muÿ	ñÀ‰…zø˜ÅŸïÛ­ñÒHå+TöyàJì—ˆé‚×»ó‘cşñ(e´¡7TÅ9Ğ¤DÜÆ 9¼Uw+|Ê¸;*#yôÉ±Å­¬%ÖÏ²6Ø}7JÃ?ß?&×@ å2[éĞŠšì¤ã­WÕÀ­øs†:%\Åâü‰èëıïš1‹ƒp‚Üğ!ÖO|»9› £æ,l„ªÁI‚Rµf©1èâ	=ø`uQÙê&fHC4ùˆÏ9Ì›ƒB2<¼ºCõò°E³ÛÃÈN~é«æïf<šVƒîì©éaSå;b3{Ôsn?o¸üóf#;,ùHÕş aºÏñy‰X9ökª€:M§­¢Nı_ 2vñ‚ %İv%‡oÒÄAÔÖÑò¾]×/,a˜ÉSôù°,Í¹Y´Ì€»¶#- ÙÊ7‰½ëå§6ç›µ#û¯lêç
Şús?ïJòæ*2‹ºÏÏh({›áÖ,ÂàS´mĞ<•YnŠª—ÇÅÖìëBº$)“˜r

°41Íy$¿ÚVşFì ™]>KX­¯YŠášÌàoßÇ9—†€ òŠÔñ_`ÔFBwk2=»
tMW÷8É«•—âÛyóë§ËÑ^Ÿ.eD–YıÃ¤Â·¾¥9üî¯Sšó½Tªx¸7Ç»=~„OŒ?ÛÏ¾Á)€z7oDáw.v;Ù´OuîóÚ9Iç/}­Ê/ùq³éù|²oô‹ä]²›:æ~ôçÓF¾ŠÇQ; ÊFáœËbfÍo¨¨µ+ÕãN›`–ŸJ"Â±3‰.6ıÈ†Ò!xšÕ€ÂrpÒM²R¹ñ±šâ€,Âlé6àò;
.*Ğ¾°œÄ‰ä%'Í+}°£Ã m‡,P·?JLî4R,7*ÈËàè„á¡«ıwú†«Êş‹lgı"=ímÌT[Ÿä’PJú“»®§ş ¦š§Ë Œ]‘Št±ÿ®ú6ë1Å£­€âÓz± æÆ÷{RÚÜ·høà'
†qmM^›œXZËÁÍG'ÜS’ãÏy'e[z ŠngÛy¥Åù§„)~x ü²ª´&èÅ>0ãL¾µĞƒeVPéO<Ş].§›|Œì¦Ï6-²¸JhøDÑ¸{(Ù7 ¸uÙõÒ½±<Ï ƒ6€7’XyŞJH¦qú£ı7Å@5wå°Œ”ŒóÀ(ŸÈ/úÂä–E îzÆëK!Ÿ \­;*¥Œ5›¿ĞG4õ®ÒkpÈñ°=ÊıØ
ÁÃ*[êœanô;XÄÖóz"!2ÑÉbSÎRW¼'9r#°›İ¦Z¬İ< wn£b‡k…(E÷"N}ƒ&˜g¥D#ûµòCæF°h_FE—„ÉUF›Ô{@WÙtÚ‹ÑÄØG ûÀ‘êÄ‰GÚ¨ —6Cä!79IÎ­cÍ<°ræ‹2Ú}t‹ kĞT´	°$yÄ\møŒÊNÇchMŠt»ÃŞº×`S{ş»ñ~ıDwmsúá„:*¡ÆÙxÓ^ÄÌ—TdC—(r-åölñõ=a?,…4k›9¤ÓJßEw ±Q¨"Óá%ÉëîˆdºfšÂy€ËÉ4“\Üí+«ÆfõlÀ‹9ŒN§*|XÖ{3ìçAçÂM{±s›.5©jàÕigf·ï<–a®²ïõ÷¤/T©ßÉ’œŸ$t~¦aòøáË³ø·ÇÆXïYTwï0úƒN2îëx7‘ÄäØ¦^˜¥´<Î£‚f KöO$¡³Ÿ2÷GãÈı¤0x^çˆı1«NŒÓhŞNçŒŒİÀÆc€9Òt¬£núÇ/Ñ>G¬§UÀ8|k8æ>Ù²’µBÊsäÀ.“;T¥æhÒˆ#±ö
\]šûîÆâÙ¬¡,_¢‘”G–¸Ç‹ˆnt”eüÑötj+§
Ïíäxh‘[^˜ú¼º!Q•ÖÚmgñ­:PyÎ:9"ØŠÊûBİ=Ÿ!X’êsö€œ—l|bª D¬0 ²A‰Urù&›¡<|IDu˜ß>Å‡Èœóú[Õ"‹¡áXŞ¸8¼	0Â¤Ju­»k{î=à­G©ŞJ¥gÚí®Õó ;T…¹Ü‚b{ÍÅ–«Ên5ßz¨%ì„BV?k‚³â¿uë3ŒƒïTÛ­©1†gæR¿}3Ò98ØzBÒ]¸
2¶ı‹,U¹À^üˆ¾¾Š*]•§út«=B!XÿÙª_—¹vŞt	öô'ú»	kqÀ×°Şƒ=¾bã!˜'¿ßó&]¤:MšÎ%:ó¹İÔŸùôyÉ#šğtÈ]÷p±İëD·ã;£ª't{¨bÎ»º)ü”fÚˆ6b¦Ü8x‰TKŞÇ¯.‡H€ìËÃjàçÒˆÜÔT!!Qñ!{¤îDœ!^±éÛ .Jxµ7çãÚÀ <cÅ6uüÄñÊ=¸Û[°T¥ğ|¡‰$¶hÌ üÔ^ÜO/ƒïMÆïÃTÿÏ¨äñ‘»"0‘8ÉĞò”Ë$^«$e©÷ş« .ö¾/ärD²*ùœÊ,¥ıæ9Õ´œyRQã=×’‘örùPµ×ÎèQ(»¼EAö˜¤->}“´>K²R‡­"5 qPyôÇŞ[XVLÂV–4±¢!;àWÑşªNlíÍ.¯¸™›8Äx­ºI©UPKs|9™»G2w±õ>ºòq‘ÚµF,Òğ¯wTĞm[¡çÓ"ˆ‡=Ã¹±QÜñ2ë£0@­ASkS$SDÚ­À¼èÀÿûö~˜QÁ(ÀĞ½èƒpßª<ßñ·”Y%–]wjyBrrÜŸGç‰,º¾+Á&9Ëª“ ˆT±¨ ÎÿŒ	\ÓŞÅ0Ríˆ‘µçX\³ÏçŒ(£%¬C[;ŒPÂô'‰8½#¥k€¨ĞãXB %[ùÂÓ›cjîÎc6«?o›ÖKüxPZ’¹kº&	 ™÷íå®ò@NëÅÍdô®J± .ÜCÈ¥ô§÷9ç×f]HmµÇr¼·gÕ&S˜Jg‰Â’ùrt{2ÅA•)^å]	W)£b¸ÄN\¯¼sz$ë½Òd>î«nŸãå9¾¼OæÀc–u(Íò¹ÏI®c¸ÔŞ‘[ª©paæşä÷™äòÉ¨wı±õ¨cÍ‘Äå½î³ 1GHXv€_9d³Ì–³éF²»í8¼ÂBXó½»¶œx˜Í×ú%5	”ZMD>š[Ò½ægši*W^Ç˜¿ë·/ä^òÑ¯™\¯&ìÓº…?ıi£‰Í˜õĞì=Çİ|u~Ëú)Ù:ú?>w¾Ë0“I®q‰¿	ô{îµIÜù¸BD§È4tFÄ˜ĞloéWÙà5û°}D¤ç˜tâ%÷ğæÕ¨ïÁËYe-¾²x¦8qõ¬â­«t|7*mÌaNvAv‚C"À l¬rÚÊ¸I^®RCOÀœ¤HvÙÑÙ«–¢_ÔÙ¾£Œï¯ïVPÉ9ß#ö8ğrG—E´à¦®Ÿ nxÀ®ÑàØ|Mª›n8&â°)&¸*Åoå¶ı­Ã>Ú@SQø=j¨™5t>ÇÚöò1³9^XmLã»œ†»‰%^H¡ÉÌÉIj½7Iê¬€»ı´EïÂév¼’?â	ô¢éÔâZ…n9ê„vOÀrsóûdhªÿ²‚î ì¦»–ÅüÌDavƒ®ESÙÚâœp›«æ­·¬‰ï¢…ô1oC˜İ…Ú;F•ÂÛ¾Y–;ìGk^c	Y0Ç!|#c|BáÒ/ X@uPáó¦
p×ñÑç,¾Ğ«öWœ™æÌpod_mÑ,…Æ>ÖÜVV‚ ,×ªa¢.éİ>ŸŞ]K¥íÁkmc¹Ûz#Ï£ƒ¸ÿÅŞË«…ºÅ-¬Ü­{i}ù„öGÇ/}ê²ƒ-†Ç³‡>\ÿ@.—ÔòÑ+d¾[!‚gûXÊü¶ÈLSN`õî0<oĞé—&ß÷à±(…V4Ñ¬`1üĞö³ô
te2ñ6¹î( W1ë¸ım?5”ÑİWmC•ñöQ¸O=F”M®“en9êæÒÂCg†<N†”…Ó‹DÁĞ7âN•ù¼¨XiZàúıdÚQòºãêvTefØ¥ö 4eš¾Í0:¨ám‹(0¥h¼0¾3	O¨Û*Ş7O#Kg£æ¡e¯±FÜ‰ÎSüíoƒ2qÌ]‘8ˆ*1…-óåƒòn¦N	Ş§æ7Ø´h„æ®Oêåõ²•„ ÆÚièƒ+ÒÜò‚µ¥Fâš³æ±J1„ÏH¥WÒ_R%lÊ<…šËëC^ÇR¦MÀ´)¢lînÖ–ßOç™Ã0±·SÅ;WiÿTêïØ™²ªJ€ßy½©dO¼s†ê;‚·<Ğ™–ˆËy‰ïjÖwzG5˜E?Ë¼JõJ´r|â dï'“/Ëï‡KßSèï(Ã€‚ºçÍXO¿‡öa6²¸•³L]Ÿ}Ò
ézşÍÄš·vBOô+Æ5Ñh¥ƒ—uUõêÉªw.¨œÒ2'f	ËtA°«ñÔÇPx¢8¨ı€>ÑÖ·aNòUQ-î>Å^rJrS:?îbnçKï¸”¿Zª„z•ÄHMŸ¶V¦‡ƒìÍqŸÇ3 Îâ°x8|¼üÖãin@Ã~Æ~ªÏwŞÙWRm˜æà	I+^;%2IİvÅm ¿ ùfA‚¶c«ÜêmC¬â@3:úÓj×Rš¢¯L®AXšÌJ=jÓP
^OÒ2A£KŒiV;ıV ˜èv”gú@=hXËÕ$LÈ¯‹UD-a'êøÓB`8\4ãŒ|\âéäa©3yÓ‚*÷	Ó–OÒ/çà0©Ô¤´4‰IóT²ÓvË›ã¼–-²Ğğ%ÑQFP9s¢¶92ÆÊ“Õ3P
 ü}ç]lk¹_À™/HQ’ObImï(Jõ¼×ÛÁaM‘Ö—Ö«/j×õ‰k‹qâ‡yÓr¹Wi’8İX¤òösBâoUø<”Fuâäh+DeHÿ—É"Å‡õ‡AGƒ = |J*–eaä¶½Ë$SNÎ}ˆ:±j2¬ëØMÇÈŞ2Bÿ–¶æãĞù:±«·ù~£:¸gtAD°|k—òqÇö2­Yy²cÈ‰‡¡Oû‰ÏV
4¾^€oóØP¹ŸîŸğŠ;0^Ú‹±Å@hs\c%>ÓuEuÓ}ófŠòAnä™ {?ŞzxÎ·Î­mÔÒ¶¦ÂÖ,¢-\pá¤›P²…ß!ê=ÂÙ’X¹ßÂ4ékJN£DçÎæŸ¿’hü¶r²‡uH¥–õõ±ÑOàs{ãÅ;b]ëT£C˜UØóZÛ²”ì'–RYFo˜wĞéág0Şy±*´öô‰ğÉŸ0ÛwÓ)Zî²—æZr‘~‡p§U„7¸àÛv+±••®/ù÷Wô‚‚ÛQŒ¯ÁÍ{-:mYnDçÌèø×Cœ?öº¬å†èw8%™á8Ë¨Cë²ñæ-¤“FícÒ…™cßÃ8Á6ø<¥£¶³Os´½³½²ôÆ@wO¸@O„ã^Š‘Ó¬RŠ„#q‘ùÙ@ÀºÆ~z[`ªÜÒ$)Î"õBµ×êcyNY‰¬O
UéR~iZ<5ÿ,‡¿¬õÃùÁ±W’gJÛ#Åålİæ|‘X7Qœie  š§È*)*q±ÁÊòYOv3Åò”Ú8ø›Öb¡ÉâË„$ó/×Nw	3¡WuÊRı<•+¹Ğúy~ª óÑİv©·‡(¾A[cÙ>-
ìÎ·“&«³Ïü¨ÂUÂH‹OÇ<ßãLüR$Ëbòş@59räºŠğ¹‡GĞœÇ‘.áï=$`k¯ß´ìvÀÜemš]ªêvf.m%/·ãf—¶f\¢_CÛ*ÆÂáAcüR€Yt½ÛÅÜ¨,5d!íÉ'¸ÿOÕ?¿ºŒÆæİò“ñ¶	œORårÕ(ÜÊ<‰Y3½¸Á¥[@ kîdIë»@F†á®»İÓT”ğâ¡„RR"Ãq8wFpùûÜÙ– ĞiÄÓe³ÑlGAu/5T™äÃòÉ®^ÙÍ@]ŸÌÔ<hP¼+ïLƒÚR‹mA5ªw†Bu;yét`°áR]¼dúß™g)±
º¢Ôı~*’Ø³D*¦ˆ…¯‘:{.¾eTùû	ß1Tœ²ß7w<RàR™'ôWÈ	Ã;˜z5k
®jKhÓ ïøNí F°=¬ÿ¬A‹€ê•eÏÑŒ4ŒAøqŸ=³*­,ƒõê,2cĞ÷1ÕœH½åƒUÁVBıªŠ³üpe¿Âï”Ÿ¿‡­Y1¢ÉŸD´÷[ëœŸ°	oŸ¿P·/ÚÖ#j1…º÷øËR.
õ
ÈšÍùeDe—œ•†Ù³gÏ"ñ¬ğ¼‡¦ S(å÷ŞĞ"£(™Ş3l²½¢Á&ïŠËœœƒyrvÉd—Bï¤DÒöQ\i^B.b;[C6ûv$P”¤PJ»‡D»ØÎ„×ç¿ÉÇ™Í”„€¬;û£ênÈŸ›LáÏ0œğn)œ_~à¡€=öêK­ĞHÀ4Q½r‹‰ÇèY0yB—íŒş¯›¦Ù[.Ïkõ¾Ï*û4Êí}SÖµcÿ;;¨Õ ,Ñú;áqNKî’£_ú‡wæÂq¯1 Ÿjº½ó¿ª˜È]ÁµKª£I¢†ôêüNõ6Á:is‰´ëæ…©…1qZT,x(èéZí'XŠñcŠm«¿ÌÑ+>h³Êú*
VÃbÅÖZh²Nú ½&¸	ç/¾xÅ|MxÜèú›ñJTÓåHÉ“ŠÒqÜâÃ
öŠï`øşuè‹â¦Hâ¸Kvd@ÏÛÚÓï¼|ßXvî/I¬[%çápÁØ‹oÎ	 _Ôk)ì´p-ôÔŞP`ë²*Pß½nYP¿¿¨ş›´ş<
‘'y“Xˆ¨ùâ&å™aø¢ıivÎ2ğÿ^3f½A4p KH”z¶GK&ÏëSè*çi~‘BÕw0°Â†â`™}æÒ>úšôVÛ6{»w|àÁl~YeÁïÔVf®~
Œ‘Ïƒ‰F"c‚O1ëÚoB[io6œ‡¾Äø¢|ªâ
úú…º÷] f2n•¯AÔk¾°%R9­¼)œlÚmàÒ9A$ş\€n Rú+Gåå7¿²ñ6­ã`T5WÃ–Ë)s´I!Éxo]f,µãÃÜÀı¹<K{˜RÙÕy3×F­ß+*õƒ`9‰@?¼n‚ÌXMòù‹ÏŞ6ËK×ä®¸n1*ìÈ¦7!çµdguœcšv‰¤™4
êægTÉ6$F•Ù„*ß¨Íõa[øÚyf(ú¡~¦I­yü¬á»ZaòõªÀ¸{õ¼I"½ÄP»%‰×şìD‰˜¶~·\Ôöä	¸>$ûÔİöA[‘}‡3>éÁÌÑRaˆÁ*§° YøCyV/„ 7[ì–87wÄ€z§î„…Ä”G7Û&Áê¥Püg4İÔPUÿU§Q*	v˜ê~§H6íïŞ5*Ã+²`r$)õ;…ÆÊ²Ôˆ–dœ‡‡ì‹Ô,UÍî«*`ÁËíÔDßõî{­µŸjkënµ(/ó‘8ét-Ûnj»$Õm0ïõjçÉCw‰èUÌÓLy} 25Ûƒoi¨†¾yøğâæÂÁo¼ĞoéD’÷sŒ[µ;Ãjó×Nj?&VQo¢àx](ÀòU<Üd^±e2ß1”^ä•Å·Ñí_äéæ<^Ÿ¯BH§­7Z-t V¶KP›r5×Õ,m,ÂÿØ?ŒŸ‘óŸ¿±¹yÿà=*¥ùó^Yõ5UÒŠa~áK	œ·şşeMÀ~¤–ı¤Q£ö¹g¥‘:k$ÿÂ®'yƒèWüãà£ÇŞÈ” óøŞO[´·^~÷è‚p\„št•c ]`ˆ¤{gI¨5qšSY?dGz¬Ü
^£Ş±`q#l#º`,òôfZ_’>ğ¾ooåxKq>¼²Œ|sŠ½ëöÆP…¬\²¬ö4—“(6ı¥¥ærşìl³4T¬›´+CK<$[.¦e/‘np2¾¡€U,à÷ë”©Ù.$t?Rƒï,eêàuÊx/X¢P3¡š*®f_ƒÁ[ùav»£ŸÖ%›nØˆhß­rºÍbıØ?–ÕeÕQƒ¦NQ5ÜĞF'%nQ3æí´Ú‘)²§¹3¿ÁdóìAà–ü7ePº·}ÀÓUJ|.×\ŞPfh;ÈWC(ÆKcI­0³‰H¬.GIùz½³Fe!–Ù )ØÁ9Wÿ‹Üö=´0Ç)­1™ü5&š:ÈÏÁÑÜâÌø¨=ƒ¹yµ„ê‡¦04á{J?4!€Èe)¸Ô÷‹Ù ßzr¬bßÀía\%ãN_
­Å†Yv)Iš(”ÌgîÿîŞÁ@#emı­{È…“¼+wuĞ¤Œc&ıÄÛò{(]¼«¦à£Ó.ëÄªÏAùıP·¶»^Øs³¡N¾À‘M÷ågTu¹‹ÇA4ûãâòº«ÈÂoöU>—N)TÅ¯ïÙü—jd°5›Tüü7œ§cBÙ­Ã0:c7hàãß•Ëı—ìŒ¾Z1óŸ.ğÊÃO÷æ°ŸË~Â¬ÁšQ6Ò»¸ıÈ 0Iš6{LÑ†U¢O‹Ş”ËÈÍ©µLÖHÏ¯¨xšŸ
xñ‡,ş+ë üÇ¸fl†«LgAØŒf®<¼¹\v .Ì.Eƒ4áóñŸçè›*ç?ajÎ+Œ¨Öf,ºŞ=@©¨HğT¾q3ú¥r×´¬È—tƒy$Óœ!˜Go˜œo‘I_ ÜÕÆìh½qÏûş)µ÷V&Éj€NÈ¬’šé˜v]MCíÛ,†‰CópÜ*ê·äæÀ‚‚'ì‰÷ÉƒétÕ'~¾B‡~™¼ÜN{NñÜ:#µñÊ«±döü÷XÊ{{*‰÷ãO¡
º÷e?­|W_²ågªi²o˜ğª [œ;©R»så
(m>Ö¶TÄ•{ëzhª.[3ÑeŞy6
	ñÓ~Yp:È(Q~‚ìùŠ©h;E…HãÆ@{ºû]G\sÂÏŒÈJÜ¢-æÙâ«M&•²ews\/¼ÎtôŸ>ÃÜtáÜzà¥ˆ¦ùìı4S”Æºµ«;Öz¶Ó€S[5½÷Ë>êQ<®sMìâ$×Œ„°Hì«™5}YËt£?.ö¡kÕzÚ@Ûóú°”Á‰v Ñ>.ñø~EåPúöİ!ò0ÚzSmk‹¹ “ú#ÒÕJ@h8ÏÒáI¯7@•-ƒK½i›5òÜ-”?/øÂ8îØ£½Gò[0¥1ãÂÕÄÒ8a@ö=`¤t3vêÙ{hÉÍMO‰¶N¿)oÁhlB"û¹ÂØvspbØK<¬P‡K¿£¼d¿áËˆ$#8k@&d¤Kf¡wó'g5Á©éà¦ÒÅÙıºˆù›ÃÒµü'	…&v	•Ûƒ)i¶™I@çÈÔkÃ®÷ÏØaİWÓMV.up| ÂÆôø;P¦]<B´æíòÿ0‘Èsî¬îÓº««ıìŞÖ[4…	Õ‡ :è9×*éwî „¤¹2jÊ@»,ˆúöó­¥?h+®œ[é–n÷m[£y}¿VR™håh¦îâ¥È ¯í€ÕÙˆ=QÛĞ­N™¡KğbOcİ p8xÃs[{á †½ 9¦ñMv•ƒ«ŒAÓÃTê Ì¨¬ „oĞU†öPòééôÏê6]Ã›?ÒÉÍR­eÕwT@?¢ˆ9U,#˜sšìÊ(u…/SïY|!ÃP­ésç#ÙÀIÍIO“Xq>ì©å‚“%%…7ôóyƒÀ¨7£eİqEcP¢6¶‘ŠĞ>»ÂÖb°‚»S8Ğ›gû/£Ù¾¡VX0m³L?{\-YùÓ½—0·c[–æU)g»åêåñÎœ+Q.$`HÕzwê¯V;Ğ ³ÙZ§C·[7±%ãXl«FD¤,–º…7í/àIs>İš'.á„p`¦U/>\Â÷ëj—gá¿„äZáÜL~©»MÄ.ğŸã£×2™‡‹,T‘‡`º¾ÄØu&n]Ì‹¥!5Ø}ı{°Eš` ·›íMÁr¿¹¬@d‚Â™úsGp©ÙVÙ´úT^2dz3Œ§¸z¬#Ç¿º—ÚüˆçJîD—dÂÕ
Œ”+ôÇœ3Rš@>SdĞB¸$‰<êêïæÜçV9I®Ü<'°²LPD{V¹pO4´tFßAğå–caÔV'•ÉbšUmúì;K:^ò¹Œ~ÆÓoÌñ~y«ô¨ˆ†ØÚ´­¤Ûæ‹G€,ÀICSå’¶càØÇómÍÁíıMÌ“È<MØø:“ãz\(UÊB­!ÚÄ(¼Eqµ6Ì»a3Tªvis°µÂUÔP˜¾³İÆ™ı É,úñ ¢¼®‹”sÖBÙhøÊÆ	ûõ}œŒÎ«İ—†dõô`"ìC\%–©<m2Åm¹:©­êiG~<Y¥Æşg7¯°ê÷ŸŞ}ê¡X}‡ó†\Òç*¹LÖ}—lÔd.8H~fºëvK*ÌØ#°>Á÷Õ£*N;pZ
×OˆLx |¢_v) yª{vF¸šfh2ZÕyÒ£¶*­wŒ)oºİÌ)~b›ƒÒ0Šº¿¦¢x
hÁ3Tö};ÑŸa0÷ÙÖËêQ¾w Á²µØ¼=9„$—‰>k%1e›Õ_œ¹u«À8ÀÓ ÄşÄ•ƒóHÒş4ÍM¾İ,l+KpUË0{šYôæüx¥,ø2Gzµ	“8ší6ÙVdsãm-ò¡âİºÅ ]h‰îi¦uØIZ°‡.‹dø‰h¹ÿ¿İYvAb-;m]KŸÈ~®K¼n#Š”[¡$¤‹3 &UßU¹İÍ°ºTFö%Wqm”œ.Ü3ãCßL½`?*Ò?ònNvœ|b¬D	6äùßd÷KÙR¦äN~;kü–å¹W6
=ìÒMÃ¸{ìÈiAôwì&|ÿÅ`Ã-7Î¦ğ._RXz2ã;^—á~Áy^­°Ê‚jeİ]nä#Ù[TN·À'áÿÌb(›ùk²l%k„O	vMô¤L)o%ŸõÙß~ûôá0(‡vt›½NŞÀ_	Á¾Á+÷41 âÇÊÃ;¸]&†µ¡ƒOğë÷ÆŒªı˜…¡ÉŒã™rŠ¹¿„çWqˆø;ÕÇË–†ÜÚ$…¶(Í›ôöĞ†¼ŸZ\SšFÍpîpg„EŠ¨S3O8è’Ë¹P \êC2…&&#Û«=I›HÅ’šä)õ?4Í°NÜ—dc¥ÆË†8àŸ»ô?,+t‡ò6Ñå2µÜ	«p%.½.kâÃE¦›Ÿ2aŸÓòmj>-o7e·GĞ˜”	y:Š'K*<V•ĞT%00¶ñ®ä’¤”Àø®wQœ–}Ùpxcı\kR9V¿W!Ã9P™¶39çóÂ;†N !jÇİLcöiîš›¤éÔØ@¥Y ˜Ë«®ŸÓ¢9ˆìdê_ªFœµÛèAv\ZyÅ
¹=5´Õ­şøB‹ú™¡™ı>Ø‡",ªÜÏï)ïç<Ü·¦N­Uüø…|i‚Í×t¾}Aâ}{¶œ¤uœÙ4jıA0µc4c°Ã”m_âšoE×BŸÙì^/JªÔ(Â´¢ÂÚÍ=×²/ËWË¶+3–n+œĞkO	WU‡Q¦àA[I ìŒ€+WÈ¨³T®ÈÇİHnî¼C¹Şg‘HlédÓÁ.Õ8¿øs3ÓSbš°·H6Yuÿq[ì»Uw¯”ŸĞ†ôg0¾U}¶ƒö²†ø©ğÒ6Ú²³ŞsĞ¦˜›(õ2(òş0àdc¼d‹oÑ¡­Ù&Ã*BçW-
öÔ®w*øçT—Í¥X'Ş4>Që¨ã"Ù+×™}jÂ AS¬ Ú¦kr¯ñ:€oúò5¬lsUá§W¶ëÀ$ÿ&Rq¿¸ª¶©­Y°ñ$­‚_BJ{KÜ48pÂhã?Kkõ8 Q±)(=V_bWŒJ*ş#¸Üj£ µÚñ ‹<ÉÊTÈƒ‹@&ª­ÙXXØßq—÷â yÌ~"ó[É‚hmTzGŠV‡×6Rxñûñ)†‡%®#»nŸşìöfgâ•Ÿ›×bŠ|ûeñ‚ŸœxHI[æÈg4pÒ<bG(é•?q™:Â›Ò]jn“›¢¿\_p×‹*È0º‚##odÇ<%›½€	jŞÊ{}H©ÿŞP"nº° ‚9N09×„È´\Ux€)R—[rÒ Kâı…<ë;‘6L^B¹oÊ{÷EJ¬1á{‹Ó¿»cšÑô«w\>\–vü3S½Yzµ¶@á(°?ñd)%²ÁeµaŞ=,d+åŒcv*öšÆr&
^¥IJÉ—3(	÷ÔÓ\İ¾²ÛÒÒ½\.²çdg›Îk'Ö¡`½ôé3¥4µüÜ› }SÔÈBUåp˜Ì€@‰2Û“BlÆÊ@O_é·Ê®¾1_÷k:qDriz5AĞ$—`Pã1€i"4H’Ş¤~ò]M7hÏîŠ^:İû€ Á—Lf—vÊ •X}¯|Í™¤úÓI4IŞmèÁ÷„eÉÛ´È“b>-}toía4g_$,ÀòB¶ªR„ó”$c®õú·É?L¦}9E È&a°wÎÌÑL5îu˜v±M»ı›CP‹*Ú‹K·…úVxÆu@¢ğ³:WŒı­á6wòôŞ¹0L…‚Bc•"«˜Íà8Öâ[0¨”nTIdiY}P–FŸ‰ÉÒş£·8ÏALõÉ¼?î{s	§J
÷ÛGÁû’ö/¼?ª®||òõ´ÏXáÛÛiûASÆêë‚9‹„ƒ[Øoí`]°Ÿ“‘ıíqÈEgÇG;öi•D­mËë*™şı$èInõ3>†#BÉ…xº=¡ÈëÄÅµáÊåê«’(Òhò1ÑHH¼Îr¤ÒCËNÄXV&˜¦MnŒ5±ÉÍHÀy§têè›áöQå…3ØÂğ%üÆóI¼àƒ€‚¡éÕß¡FLîx×ó+‰®}•}óŞLÌËVçxİéÌSZ=|7Èl$ÌÕy~İ~ÏË¨Tï	\T_Ÿ-öø`F'/öä]-,3ƒÍày6ñãAmÄg7Kü\PıS¯o;ó¿¾êÏlòsMPbW™Ş’Æ¢E–Ñ<ònBGää¯:D!àÑºø•ŠXĞ[fÆçh'Õa¥ÎÊNË_é}}78TÌ7¯Æª6IùÓŞ™½Q
^ö†Í¦@@¶ÆÒ˜$$Ø/nC™=ÍF­!o‹"Ğ>‚Tª`Ü8D±w‹ilÔ°%Lò^äC­CBÕ8¾÷…A›àšÉË €ùâª3ÜêÖ7ø•‹‡¹Fn£@ë¿Xô-\™ØW¬¡ÔóÆ<[˜4^PY¼€ö;Š¡E¨—l‡Û·‚¾LÑÖ÷D°r};ğ¾òú/ëF.Úv50vÁ'ø§EÏ™Š¸(îÁgâ’ªdëÄƒZu29ÿ¬‘*K’k4†P¨S|5‘v†ëˆOHïäzĞµ©‘ç…sïT{v™ôÉûÏİ»RüH"V6œ=•døè¨ıppt>ÏÅ×P¾ùºó:ÎqdP{ÁÉ Æ>õSĞş’…¦×UV1SÓòLS˜÷?:B7w¢ä¢Â-NG+
©û{sÚêÑçp…ÂŒÉ<÷8+GªV'{yôep‰wg˜¬ë.ïø —ã*fö7552'…rps6ÿpz¦&””€5¢P¬_Úå§7øU›7~É9 .dgı|¯Ó´D/8}÷ç´µƒÈİ]i²÷„–'²Q¢‹< R¯jhFM}Òá:‹Å«væU#3;§ñæ¶F»-ÕD¤§Ì&À.©ãŞ´uÙ™8Í&†¹¡T‰we9öB ÿÁ1D2Ï…n)=æ¸Á6I	Ê[Èz:z
ˆ75Œ>t[dœwIšš‹x¡«“ouër†•çÍ×äÌS4M‡	^½q–üHRCä(ê¯‰,Í¾l.2ìï1ï/)
R¼>zâê0i¦3Ä-WMZ¿euT¼Dû^ "/eT-WŸ+~ÓWª~+ Ÿ\Ì.3ı¸:M &aÇ†/«à7 Zì˜Oò–6ã&o”i¼ñÜ%\“Zj9‹?¨Ğy"W!İw§şÓšwpÇ£&=!]R¡$(¿9yó— -(öÉ¡ö4,€Û‹7÷%K´=­Ì>ØdM;æÛş¤BÈw£!†(wV‡‹P-Mr¸)ß¤Ûï·­6ÃñŠÿ+ÊC´G)Œá¿>_8{XŠUíåM 
ÛöŠ7GÆ#“åò,œŠ‹ºãw¦
úVø}‚Eóû³Z¡-¯7|>4ZJ*Ì.‹ü9ò¿/±X·@‰	=kó
?™©‘~^Cxj®Ô°èTmË‡×™ÁÜ¤¨knÙ¢À0b$ÁMüRÉdëò»Jkùq¬îj4İ$_±Â}³]Gó*8G-UyT¨°YF<Ïßî¶Øú•zBĞ­YĞœtö*åFŒ¡dW§9ù‰cd*ŠÈÕˆ´ºª"Ğf!±2 n$ó6K´6v7s>OşßñšÍ*Í8+w½/f"¿ÉqHï4Øƒ¬y#ïI$¸E~õ­¼PfáIœ™V¬é_oØÁkeQ&ƒ–^Xıy²Ïú(7ÁÅ6îÈlT^‚Ÿ -Ú¢Ã#RïôÇà¸Îg”¶œ¾œf£OËıÈYŸcø¶˜iÒ*Ó!JĞiéçJœßa—ûcV.ù#<F×9u
v´`šô1ù@Jnn\•C5ªy™q¬bÉšÉ„KÎ¢`nµ’yÚäÌ>â¹s.!Gr9™Õ€VROç³ ”ÿÿ°ÿbµ]xèD >rÆ¡W”F
ô ‘ ÄË´åŸµq7u†¬‘Ä8Ì^¶œrwÓ1¨§b¨YK'ŒA6‚yĞ©QLÉ&ø:ŒKü_‹­¾ô1Ê±É¹d³.^gé?F¨x0b½BhzlçÓp­{ÑuÂ}Şgâbdè¾ƒÏe.ıuöÑ™à1S$Ä¿ê_mi¢ò5f M¨ãÑ,÷NÚ›£w|°Í8Eóffk¯­í¨´2>bbSÓÌ<à7ğ€·âŒ=‹~XOÜ¸®÷‹É~(Lkç¨¢=¡CÌT[ş(ø<Sä²ÁŒ{„xËäÔ©öğlc¤õ	dÖ»iŸ®%3¨$”ßÃòF¶ÆÓ­>ºHVOxqŠ«I$Øğş“ŠÙF	ûtb=²g’ˆJÅ¹’†_îBxşáí°?‹Ë„í%	I7\ƒå*Ç˜Õ¼Ù³£ˆNJoÆ[3Ì´"ÛÁ«ºà²“¢s–†>MCÅr-o²u4~{¶+ÃnIÔ
èšÅOæìitÛPOÄ®¬HYƒ¸“¸|7ƒ\p77¥uEVd’»lÑ¬Üéf ²r×I|ãÃP<ƒ…îòXCê-Ú?ƒçµaw¦åâÎÓSKßoºÀ¼CŒÑYCdâ¸öLşA¾Ââ³µ8™§æe o·k4W4ÇÊ@+tè<Kpò˜à¶Q6w*÷(ßö¬Iîõs(sÎ¿~ƒİCí$FƒC„j?v‘8].LïËAu™b³,E^ÜkÌêÃ·¬AÓ±]“
¹TN°ùˆ d5ÔOO[C‘„S¡;E5‡>Åkê‡-–wÇ+B<¨×g‡ş:Q5©ëk…¾h.äá‡8µ«)IÅÿ´ïTäÜfÚj©‹Ê¬¦z‡U8»ùÏPà×ûı744ğå'ˆ=¡vïüÜ(¾a!ã*Ş´&İ"Ğk”-»l8Õ‘Fmğ­°KtEiÿPÄ©~ı•ç{F4bèóÄ¬‹5üYï¼ï¤k­¨ ò¸~¤ª5OëdqğXà‰$Ğ€ ²[7#R=ƒIã9©ãœäÓîËmzğ©ÁÎZ˜å/&ò+ØÅ àáØ 7|°&%Ë äè'—l<J/§P½q‘ûhÀ™¸H>S–H™ëãêCÛ‹ˆ±e;ÒË¤9±½ÀdÙ×™|(ĞHÇARÎFf®rrƒkïü
@üàdêøGáä±Ù…‹/Ê@÷·€
V !ì_~ì³ÅÂ°ÿ¾İzvÚL'ø{j÷˜Ç€íÓ¨^"’õiØF$_|*hB¬Új ³#ûg:Š¯Ó˜YSOLA“d9l»‡uƒ§n_’‡ÙìÉ~ÙkÀd³l¬•$)h$Ğ‰T½oÎÑëätxıaßu|Ìé­ëªâĞy«0½ò¦*¨3– MJß½›¾É(FÁåwş•»í|vy
˜L{•W£ÏàM{íJ€`¦c;VY]0"9³ÔÊÁˆ#»[wN(NÏæHĞ¸ªè-$¹º&£]Ş_Heş°(k!~ñ¡Ínš†¦i¼w*ÖR´sGšŒ.tÏb`/îÔûs-õEâåî\?’ÑõK£Œ¸œcc÷˜u°Lû¬Ä|Nô¯g¤-‘)3}¹<Yşõ:5³‘#ÜZß ã‘°‰6@İyd•0&¼íäµ8šñÄÁ²ÙåÓ‡Æ‹€§Çxo¶)›ì"]Ñu¢W˜Ã.Œßà[§!úâİZ²¸ÕÛ|Ø‹•ßı&ãQ’‡_k¬Ë"Â‚Fø[¦îB±¥ Üd…Å"ä™’ô‡W©HÁ6æì]®ıù.€ü^ ‡ÒOA¿„Åë‰ÑsÚ«Ü… =ØîÎ§ïRµ®&@-—³ê·Ë$›r]zÊXğ)ŸÖŞ/lÍ€BÙPi —àÇp•€¿5Î^äûì³"û‘tğ²–FZ=iWÃ³bÆ¯.’4¤¢.¼•ª7Šd•éRŸH’Vµçsn—V>€@7Iş©¶~½*dÂg›ˆP_™bé8-VìØ \4<ÙS7Œ\2uÙÊ^áAyó108Èyş[f„›*¬,gU4¯(ˆq$4OÅ¥ÑqG†‡EßĞ»z ‘ÑoÊ}:Qk0SÈĞ‡$T:"´?Øƒ%|ìº£[_âQâÜñq{| àŞeÂ|ĞX»Ëı¬P;„Hm'Œu¸†=ÇáÈß T¢·,Nş]õO‰Òj!ø^tuÈwÔ3Š¤	5Ô3e€°aK´‡Ê	
z­y‘¨‡\ÁÇ¼ğêÍ™3"v^s.ÇÊ&mËFÕ·šÈòHTXò1%¡éyÉ„RqšÚpéL™.Ÿ>/ø„«,e6ReiÌÈ7†Zëp$„v#VÚÊ—ÃÊì†½›w™ªhg0¶túÁz%´-4øgŒ*(•V+öğòSèHh•f#Äè»³ç3uv§Òá’´]³?ÎG)NVxd‚Ä¥Ï)}HõJğöxÖì¹xyòI]HõË6ıÈÉ©¬ØfnëæäİªlŸUØ™+ËÒûEVm11ƒÊËÇÌµêµ2=“ù˜á·e_‰!«ƒ=1ñ2
ua¯q¬ë5ı/ßÖcä„°²cŸ-SzÖ¼¼‹]Å6&÷WDõ¾¥}jaiúÉ¸´°gÊ‚ë~xK]Ê.KˆS@šxÖ¶=—w>Æw[.C¶Ø˜ëùä+§ÃhºÚíÄ’:‚¯ˆu€Îi€#§”6 Ÿzˆ‹K#¢‚v«m¨wßÔ,Æ¶(øçMvÒ9;eÄÓmäÃü±{ı gE {Í×=j–Ò7º¹Ãá’¢S5J§~B–Ñö°—®1g2ç
v‰Rºo4`
“Ø>6oŸ³ï÷¾ô“?"<êwJ]M'28 èlÏè9çW.Ÿø²ÈÇQ…¡é'7®2s¥§·#É³=ukR`Mâ{äôÚ&M¡Ä+¾™“B`ºİó;ä³$†|-/D×ŠQm¶¶«•ˆ£GÕÔcçAƒßqNEc/&·;¾HÒ˜:ó,I‡èæŒQƒàˆIØš@õê{E4ã)sÅœOp©V6Q×»øiş™âÄ=x~¤Hë"K;ÛŠ,Ñöó­S9¾4ZlåâˆA÷eZpÚİßØˆºbÆóúÚ$Sš¦^ßáUüxQ•-’4J+ˆG?>@²5rÑR 6v\/µÊgü«æÈ±’;¾ßdèÓ·ÄÍHp•àÚ‰9(0™B„÷|Ã’POùò75¬±xğdäpğT´.—Ës÷û,X2ÔB÷´6°SàÏÓ5s³½—ë© U ]§õ«{O0Æåˆı`aøIş|ã4XcnmÂ×^ía?š0gI\±·«¸H™Ê]ÿíõ¥|eğb[°Šå¬GaÛªòp;äïéÙó`ÇàÅŠ³ä°´òF<ÛŞzü¡ZEÇ¬İÚ|UduY®WïÏ¢ŸZõ4‡,:´Ê@Vn*ªå®áõÛBCƒñBG’½ŠƒK P|:GºH)¬OŸÍ!ŠwË3Ì&ÆËY¿ÔßR¼rû”‚@9Ï:¥êÎ°$¤g2¹¶çÓÂÄlaì£Q|uAĞñJ*oÁ‘sßªú%×7Ë†¡¢L4Ğp±p„z˜|½T”¿À´t¤òŞQIğ
¤˜ròî¹ã/V*ĞàégÃhckÊ&µ¬w>´ñ¨³|íªÅYä@ç¥Vß<ì¦cOÓ–Wâ0ÆºÂêé5#—¤'6gQ$„Œ °vÖ¯\v[' bCOãşí¾¯+‘àiu°KÄİë´4è³ÕNûÚ^ .lX.P-x];é™Ÿ×ŠˆÚè±§j%>·&Ÿ(¨tğCkˆ‡Ñ
Oâƒ„c{‹ù·Ö¶ªgzıx8§¡~ª^Àiî¸ŸR­^–ÖãkäeH¬ù›!­ÆùšğŠ¸PĞ8#9µ;“õ†uF púçJÂ`‡PÄ;%m·ÖôD"?Í˜F.=“Y€:Re{æK»Ã”\Òõ@¾_¶AUmĞÛzÚ+QÃ‘×8úÈˆ(‡€
ˆZt¹Œ¯¸²)y±à™^}yköàe’¾GMúºægŸÃ!Î;(ğc¶X;°ü)µ´¬´ÁdŒ u5Z0S`¡ÏEXÅB°+h^¢ºûB[ıüÂÁzêÃÿ(#¯ò2?‘ã!ıS1t¹Íkd™|øCÑè÷kgÀÎq¸Ó“eÇ3çeÜ|›v"IO¤1ÔË)ÌÓuÍî=XGµã\¶·¸IÛµÑŞU:Wss8Ş€Ÿ† 7)ÊS¡ Ç–j¹¯½H—ÆU_E,	=a(×Äm}õıeˆË3oL‰[/
Å{†T†¿eXü{´o†¶@;íôßqÆ›@mP·@—A.¢ú¬C²çH°ğfÖ¼	Q£xFûğ¨ËóàıLäR·ÇŒïÒ†‹ñb·J0GöèºHYÑö2ƒ(q…ùÇòuvIøm„0>³¯„ŒŒ’Ê 
ŒÏ€@Vş¾B=ù>½˜Ü‘€9Ã§‹âö{ªCçæ¼5Ìá:ÕW±6ú`×ú1íÒÇ«ŒKÛô7ÎcğO‡†\ŠLó¬—…|#‘l„‚9n9m^"Á£@õóXkZ è½ëv#
eÎ£… vş@.œ‘lNg»€èn¤9µ&çBò>L6-S4Ÿyczr­a,‘ÿ;ÇÃN#;ºë:(­1Uöˆ>ìE^œµõq¹üJ®%².	Å2CÎ+6/ÿ¯µ•Õ›©n>!ÔøÓ t›HîÓc;ĞD)ãÙ²í¼I‚6Æ\ 2Ú–¢¥zJêFÜ;§’˜|	ó˜¯ìsE'„{ëéuÕWtdxÛØ•~áØ¿MZ9ô É÷Jœ`ÛW3 
ë«’Æ—T3p:ÕÂ”&‰7¥ é<¸Ù|ÿ¶“·zwì\¿—®<d&Ü×ÆˆFÈÑê’õµê=à,şqÈTŸVf~Šcé¡G§íK¢5z@r5#–´ƒĞ…:By¼uóm»ÏåWƒˆ8dšÜJ(Ôáf”äËiƒX‰q7¾UpH0o%Uú¦Ö´Ğ…üšDP?å>n\À@ÿ>$»†kô°³‰#5²®G½E 6…¾F[æYû!°µçİ[Î¡X/>fT(3œa(*kBôá×¦Â©‚2Ó6k‰hLÅêU¼nt€úÒ5¸ÃœÁFìt8	„C%Œı¬_8šÀì([u
Ã"©…ícrËVHÿdÛjlô®šL"%GS‚n5ùR&´p–“€•nH¨dÏÏò		Æ÷«%^è~WÅ±İ!È£‚î;UëŒ\ò@öÂØsÍfs%D†ëx8CÙWØb;}`(¤“ªÖOdø¬Á«ÍÒr şYn›@óI8•yx7)¬®Í…HJöğ4é6É>ˆÙÏıåé ‰1mÙ;ºñ¡œCÏ¢ÖÂq¨´®ˆÛˆ"I°FjÉNTùˆ¸!s§)gxbÈ£îİÆÉånÖ†_9 q²›í˜µú‹M‘¯sB™Kn\ÿ“rBmµÎCÉ x‘Õ8#Àvş>÷‹ß"Ñ
¿A˜_¡]´ÿso¨íiV¥/b6”7ÀCHà³VéĞCÚ|3ŞË=Å{ğåV“+ãQ•Àu›µÃƒÆ'²é£Qø~r@î”Ï š¬çÜ¡PÎÂîÍÿ„¶³•^´XG6ŸÊÀ£w†¯ï½ë}šo­yúpçQŠ{"·< á‘ä¾¦ÃÔvsu¾Š;ıÈ“.3Qsœ=L¡P‡L¬—t6¶X›R½2e# @Ö&TÌ‘qBv'~—JÓZÚ•–fÅãòı+WÊEk=»BG$Y/ŒÌ,pÏ~pÁ^§½ÓL×ZÕ¬oÏªœ F˜R»(!—º¿ìuëµD1¦¼|glB8Í‘/·RÂàe%‘¸Kæx‘,ßü³Ã{'ín÷Òœ?]ÊË"“ÈÆµ½¼ÿKğíÁoM©I+-0!e^G[#ûÁ/²Š¤•g«pó)rJÆ³¦º­¹R?ĞmØ—N¶{ì:DŒÕ3_½ôÍ¨ÿŸÛB_bõq  Uâöà„½u—'jœÚš×‹ˆ1•ÎH‹rá*¢BRáK„<múßÇİcĞŒˆûüRM	™Àj´Æ[~ËX—À8ì5üJèEßüîVö7kòi5ê‹‚¿=ü¥[ë0¾ƒÓ§Ÿ¹>ƒ9N‰YpÓòà³ÎçëPœº
9T°Ÿ.+ç¢°pÿ¯ƒIò&g€_˜¹îıIV
•OÃ–¦TÁE=h–ÂA„JePè{¿òv·ÖŒ,¢y~!º£‰ÛF?€|¤¹_oìlÊekı§ÌÎ­ùKÚÄl®Î‡¿9ê¤Ó"" )·,i/nNO‚Ë‰ü;¿…2ÆÊ™d‰ıÀgçÊ4Gõ…×x•N«F:£"ı¢ˆ(Lî!óhÆlcÊİ]—ì‡jÂßŠFÆÊc¸hŒ ˜«WİmS¬•‡…€26úyÌHf±2 ØôÎ°¿°8©ş…ì!ˆ©¬s‹›ƒ<8…Ù{5†r?0@úÖ—›c1g´o‰kà„A
{›•ú¸éc­lVí›kû(h¦‘>Î]ÿ>W¶}·@šJ¹<PNç,JĞAÓ¦>´ÿ±ÂÜÚB*w‚u{Óév\ÆPùØ mJ€Ùwà¶rĞ•gCJÜúHø¢*8Eˆ4Xfd"Ğ<l×%‹Êgø4ë,jQ‹«bıy"çpç™ÓÜ_^>9ú"b²1â®!Ô.SË+áéÛõÁ¥½oŠÇ¶pÎÿ“QÛcÁ¾†6Ût—®·.yÂ½¦¦I¦Ö6p_?[dæLÃ6ÅcÈQö¹Á±Bó{ Ùğ]8×8Èpğ’³i`Xí˜çh~ÖFücœÈ?9²­ÂÀY·ô#öŸ›©Y3w¶“Wí‹:7¸«tq£ê§ÊSu7¨SR÷®$0LĞq±š4‘†TS`Š?º7­d¾;fªy{"êÍÙ¬wò¯¡°ïöÿC'—p7åëĞªR•«¤«»xd)¦‘fô3d¶Å~3{“«î…ë§D±(&;›¾êaRc?ˆ?´ğ´0ÎªHó&X8tá<Ğ3vLä†ÿ…2¾åYÄ˜Éæ—2Š“•
Y{œ¥¨?Ü®cÛ>r]_•[‘¯Ìâ8÷C¹øEZû&ãÁ®µ5QèÅï“æq0ãª\±_ö>£2¬,İ]z‚Âk¢e’PÎçØPF¸-¶ ƒ¹İ“¾7Sñ¯,•FÏ#Á°*õašĞ…ŞÁû¿Ø š4w­|ú˜iµÿ©Ïì?¦½ÑD©{ñ@iD.ÙÖS“ôÚ—Ö¹Ä-d…ú'Ø¹î=DÓr¥[ ½úÎœL$Ç>ÿ_ŞîT¿íÜ4?“ôß|{Iæé{ød	eÍ¡Ô=_ô‘0xAß„iáUş¬ï@#‘•+N‘ºâ›Ì(¯]¢—áÜ³hûv“wRœ•S°tµæiBôE‹`ı6Z_rÇ‘İ0ªî€q#ĞQAmµ))¬Èßÿ÷è üíÀ¢„ƒN©Â¸p)H£¨—#ûQN§¶ØúíÄšÏôµP]vDm‚
×öXEúıµ®ãİ£wÌ‡µƒ%E
ÁÔçş\çF#âlÈ±jw nù$:U\°i8†p“FÇC’k"ö2Ñàûrà˜ı­˜ªîzqÈrò"§<À,êp'L9œãq@VÈ%[ã½ÊÔÈÉ®‹Ì¾—Hİê³/“Û6ŒÌa©ÍƒÀÒ¥
#ü6tFŠ×ç‡OGõuÓÃÒ;Íùİx÷_>-€¸>o9lâ&ÄaP”ÒÖÅí!.=!«ÃéŸŞ=¦ƒWfrkSä˜²›å@‰½Àr¹dºŸ”p·ÃóÏ|·¢Ê.4ÊÈ¯“á6ç¤©—nÚ‰ÓWâ•BŒÿ»ØÍ‡(î ¥¿ŒØ~+ğ‚ù&Ã‰l:	CA&ì·íô
hVFM\|ß|ÖQkô«†¸/œ,Ê¯®@;ŠôùsH-GølÔf3AÂŠÏÄ~:WˆÆîÿGîÍä’Ê—5Z[V´;6‘4çS×O®›£C{ÕJµØÿ B!É]®Èåóx!k[%îş‰Ø“MYq\±æò#t^bg0 ‹¦JúÈWúŠÖşäUO´J÷üÒgÓ(G¦:‹h%¹h®?È©bùnÛ¤.ˆ¦Qôİ±µªÂnÛˆ2EÚ4»õ†”ÓÖ¼åÖa?-¢„Ï|2}É‹ˆ\fSà,\ÖÓ59›µ~i<±Ü.|0íÅØ×È¦2~µÇQÎŠAÎ†ÇØãÀ,rÄ—CûZÈ~Ñ®¨y\cf£ Qz.[ZÌR>I]õ?£Eû»IãšÙô·×'5E·ÏÒ}¿ ¨üusä“—•¸ç‘×yVŸDêÑ›¹f9ÀBŸSDçy/
YW:và	ÛZš.‡—§ªÖÌ ©%Q³éxÒ¾OÿXÅ=LÈ©÷§rzz³0“‡Ç°Í¯{'ö
¤‘¸2šı‘úş™“s0]ëÂœ&/—-‡Í [+ñYïD<áëbÿ+e›Cèæİnf4sÀZ/’×Ç<$şù–Öüûk¼ÁâÕQtş¨‹‰‘º–\Şóå—VŠŠS
õ¶êÂÇÂ#ƒÜ7Ë·˜ß—¯q§nºÇ§'Ç‰İ%¢µª¥¯š;ïß¡¨¬Õë÷–w}‡aòF	›iÒŞİQX¥0¯…È|´¸ÔK¦İOTm%–¢(İ'êzRXIîDh¹9I—®M`;6(%Eü?Ø«s0“¡	å½wZd4°‹ÆîSõø¶«eúdõcû[¼™iÏAäÆ&7–s]NCèÔüq®§“Ç™Xê€·ÈZ°Ü¸ş,ê>¦cöLÄèmTF°¤KÚ0uqH2…`F­^×¬øíjÅìë„Zsç¶Ä5<}°$È©•ªŞºï_–iËĞû¾¨ )Rƒvbëz’£Ù š^½`sN —P ¤¾.ŠGší1®ä„”|–-³.5ÖjH¬äBÙè `É…c{ÇE–­¶–H­£d\[¯®Oß-|"YK§®2Åe×áS¯OIÍØç›(Ù)“‰­ÆÓmQ3·ëò¼«©dºeì:õhşô¡–y£±SIBa‰((NfÉo§Âú¾\‘÷ÇKøV9íSğfxOŠ‡}YcºPÖf«Ş:Ş\œëÁ	Á!ˆÛö.k´(ÆÁ‘!|à*l;ÕCê24QjGÁ=Ñ“£ÈÂSò´aÊëÕY'¯óìQ¶óŸÁ&TàƒJæhN¾^C‚ğk©nì0Üûƒ
¢”MìŒFŒ?Æ¼ s.ÆVÑ\]vî¹©ŸÊhg×7óS5ƒTµÀ7r†š
óB–™’“ÿjZ9ŠákÆG• :qúŠdl¶:^9§ÄA´~t‘'hìıáz­ÚÁBŒß“†½İ†tà "ï½k¦ZM/R!-Ôw¥”ûù”<ãpúu[äÈ8¸ÛÏ‘5·€JlO‘ú"ú éˆ›ƒc˜X
ı2•ÙñÜ~sº¢,j`Ä‚´9òx³BÅaŒcA5™¶>¨6dvÄ…z	£ˆT³Öe+¦\*3d„~çªQUµ|]­ C†$a¡(ùYbë5]È{™™÷™zxGk¾›˜™ÅÁP;%³rwú¦Ò ÑÇTâEë6jw$²ŸP]LcuÎ4lSè®q>ï’f¢ ¬,=Ü‘©=úŒ’o=Œ:÷Fr£rææ@p¸>Ö&fÂïB––ßµi´T¥ö“$ÆlˆÓˆ¿²˜±<3Ì›40ÀH8#CÂ¬Oƒ­±,¥ÂYñbT5OFÖoõBqkÜ®»V-¾‡Ky‘ÂO0ªÁ´P+ĞQÂİëñÅ†ÊZ‚±ƒ¿R?2ö_rŞ÷$ú±S™Ë ‘i-ş$öçìË3Ü¤äE`É†(“Â.ÚÖ:K…§@ŒYê7õ4¥êóí3Y…<ûˆ 9cFQkŞÿ Í0§lNÚZ“¦×ûIä¨Æ:1ùîD	â¨^ØKŠÁÜ-	‘Äœ‘N1:LÂZ^cQ©l%‰x{ˆÖ[o]rp¸İøÿ[J«äÜıùmğ…iÓİ[À°yÌZµôKt”é|¶¦E1Ò‚]öÓ!·!oÓ±DóÑ ¶%yl-N¡Ö/¢n˜9OUW³C2ø¼7Yººuq¢øÎ˜ûñ
»’¹±‚òĞ"Tè5µqÈî‘Zqx/’„K\ÙÇ•,æ|ôª}ZsÇ6ˆR¨A¡1Kú1>ê>Æ%)’2GQÔÕÌ’N@¯ÉS.g¦aGM]U1r¹t+en1âŠ9=2¨!b”E¤gOËÖH¤Ïº›.™®ü^ÚnZ@±ÌM€Ë€£¾cnKJ7›ïh†úÇå<ÚoFó¹‰©R®|ÅßêÎ¦›¼.jágJ¼Ï»íÜ3ZÅÂÔÙ|X$|Ì–‹yä|§ONo-2[‰5„XÇ÷—rÅÕ^èÍ";ü'2_éyÓ‡¯Òà†•jw¼1W¼epŸULf®”ùœP×ÔŞúw¸3+[@rv61è°ÅÆ‰Õƒc(QeÖ'=¹:H7~	—Ñ>Ñ sÑ/~ªçÇº:€÷ .S|º:]Kkhğ5#éÚ_kjt~*ŞÃ5)ÅDl9SJP@M+ÕgĞ¤×'Á@ş$9TñØ3@÷mØ'<ú¦^4©5[Ÿw	"­0éQu¸õÍ’íä ˜38cRŒæu­vp­@X3
PHšúzƒ¸—ª?) ìÔ´VÌ„E»^G×Ø$•`œ£â†ĞGˆp
baÔÒKKk9Ûı(å İ·
ªÏ=Hïˆ/í¯ü±†Üœ]åàtÀ;Wİ-ÖŠÔÄîı+úÕ‚øXÿ<gc$j&+Ø’1jzß)CºX-«M¯½yâ(·‹~&!¨zØA“è"ÿßálwˆÈ±L·NŞpt.$ ’Mf…Ecítèmoõéğ°òëyO†CL¹lµ\_Gcœû-¯ xî7LNç:I ½ª‡²_:ŒĞ`Öº™Ç%âhJ„Rw¶8İ¢½
’ç(-:ğ7¬óİØh$:­Ïó*9“Œ²şR‘0ÚìåUrŠÏJä™õ¸ı{	……òlB‹1¸¼÷PsVƒ|‚òKÙI3“Tt×°#uèÚ«cFrVkà<NâhÄş7g8”{1­ ˜ÈhÈáÚ
&ºã·`9ç—Rú”÷|¬ó›¯HmÂ÷:ÙÊ
Àğ+‹Vw{0Q(¸N÷£º?­	ŸB¦!ê¯ÿy"÷Sùñ1¾àØÁ.}Rgà€èoßK«àÄ·Ìæ¾¸ÜC#SIöcNöZlkP(kôR²İ¢5”»EÁ¯@ËË’¦røË€“ò†ŠÓ7p¿¬£-^H©ü¯a»¥š‹ÓòVî!àc3lÙ!ˆòÎÓäÜ• ï +ÖŒêí½­åcT“I‡-`¡()N¦ä	ØG\Eš†xÁXıŞ‚P(¬DÌ)ı„O0úmâ}š÷ÕX¹YQ³:Ò:AÁ8&û²w±Ç][±İ¹à¡Ò%|>×¿/Ñ»³ §èií¼Æ3C§ô¶O.ßr>0%Î˜wèb®Tì^hıÓîdÆ›’ 1¥7‹Ö6…^36±Bdš¬¯5JØXƒTOÊ(¹Lr^İ½8HfP±kÑ	¬û…µTšÔÓ¸'æéB§š\ûEMn4€/ qJ¸öñ+µfê|ÜA³ŸğJÙ¥£ıFR¹5èvFns›¶à|é&¡Ñï¡¡ºm…#,{¢€€èğÇ*BvpoØôU„‘ù=%)9¶ƒLùgË€IµõÃşêÆí|ùëK°µï{Ã.·®‡|`+:…§ÔÉ„„S8¢ÃB´–Åíæ]JŠadrJ´Q2Ä·Œ“y2n¢ÀÅÔèå‡$¿9Ò·ü ŞX6»ˆ	˜[±Äø ÀQÈ/ùi]¯Û2'ÀùŠnM8WŸ­_`ı»ú“«ûz8lçÄQµ˜›_m8¢ø€©°şŒ¡ş’“ôe Àğı‚ş' Íòb£±RÀŠü´¬ˆq¢¿‹ƒ­]^µ¶TıÖ(ëù|p³é£$E Ü	SÌ=É#á"Z¢¯çß3_ÂƒtİÀÉRŞ(ÛÓ<ğÀ²óŸY›0À&¢á«0¶c™°
É%Ûsmf<ƒ;Ş‚ê]ÀÊµ,¼ïóeÊ£g„|âå:ZâCËwW¡ŞhÌ6’í‰d)¦2UtßŸÈ@ŞtÖ•0*·;gÙ?ªÃÉWM|O–`P÷ı‰p_Åw’Ã€n	¦¤?¨q<vÖEı‰r¢2EÖb¥Ø„ÛÂ~«¼
øìxòl¯
¢ÄÌ£xÈÆÆ?nñ¾ºaÅPIµ½4ß}çp"4 
$¢ÉHá]‰nÔ@6ßãœ?éšÿWÛ¡>Äf–¸ÉŠ’B¯Wµ„ás-„€   â€ğì[èÆ âÏ€“oÕ±Ägû    YZ