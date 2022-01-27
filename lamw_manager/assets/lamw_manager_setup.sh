#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4054059475"
MD5="b011dac8287cf72f6db20c624384a4d3"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26024"
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
	echo Date of packaging: Thu Jan 27 03:31:12 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿeg] ¼}•À1Dd]‡Á›PætİFĞ §\0kr­Âïc²e‡“Ç‚¥¯ÁˆWs™É2Ó”l]û
µËº…M–ßâ•Î.Ã|ğéÅé3©³ÚJ2I×u.9·Ê/:"dÎÅlo°ñ!vxq…³°šzÚë¦ûÉ€¾Ïu›*ëÄ[kÚ%«çÖ‹Cp;Ï­ñ€Ğîb¼¤NŞÿ‹…ÚÀB‡‘¨ÚôÉ@æ.²ô¤­…DPZé’7ÌøR0 rè¡‡6pöÁ“é=ğñÔ=cÎÒ{{RsV	}WâèESO9Šº¼‡¶ì¯ßìBIö{9(9|î±·*EnhH;²ããB ğ¸qEDúHÿoI¯2s'âzŸ_†GÆ|Dş%”[t	Z—¬¬ñßj¿0åñ+(ŞÍ±óõ¨ià£­qº4Ô¡bY/¶bIÌh½=.ûİêŠŞ€|ôÖq1øQAYÿ¹FÍaá†›¥ÁáÙé'rÌU-
‹›–:™$
Ö™J‹ÔUüNë &0Ï5Üÿx­X•ß‡&ŒTµyÈkkb}ÉG‰SºÚ¿ˆ^ç‡dä¸;İ€
y¾.ä0-ÆŸıÄJ³ì6ë•ÙÖRrâ4 ëfG0;mzPYTÔùf/Ù¤ Ó¡áN
 ÙíØÓDw\#.ì›â#<\ºÂz	ù„ÃüÜÿhÕİ¾p¶ú§úî?
âí4?m×3›¶ÜÇiı­Ig•mÛ°Gƒ`§	òiêWÿr!2[¡Úµ:P$l™Uö_ìl~gûmÀ((Ü"1obíŠ`¹;qqé3¥g0QV|íæ†½ô7œt\†ëò.Á^À\8,øÁ?‘ıÊr—é¥‚ñÍt&FÄ #ÚÄ€ûâñ'/©mö‚ÿ\êŠ=Öş©Ÿ½Ë
)jÆï¤åVäÎèæTgÜç²š<¨Ø_'µœ³ºsnñw"YğR–¿…™'½ªÔ_^Øn}“å$fÃĞFÒMª—ÖŒ2Mÿ})GçísNN¡Øøîjih£Y#Ê8H©Úÿ<9\yÍÁ¢³#5»I¼¶,Ö½ˆ¯ßµ™/­•Ûø Û
®H™óQ2ªï¸„Û áÆÄˆ	ZÒ é5Ç„Én“Ø7‰Q÷Y¶Ä"ÄŸç˜õÚº }	ÌÑÚéæSk%\E~‘1ã°£^ı(†ãv
y¼JµPá˜"(ıô2cºõQ¤³’Ü}x&H7kõ	DÓ²ü˜Uª03a|kL¿EILæ
–z2?-”öı¡«Sş±ƒİaúgbëã=}µó'ÆîÓ–Š„tKcõdÍ>,¥Ù-ğ˜it/F.9éÀfC…'%X2{—H48m>ÆYÃQ`–á¸ë,İ¾v°y£ÏYXvÕÎÅ/XDaäĞûÊC^¥Çş–p¯i×ä8ËµÈL~¸²~€äpĞ­„VÓ<…èJAAO%*ËùıÓ‡VÆµ¸¹—‡§ Øş>JÏ¶!-==Xèr¿-4«MÎë=Á½ËşWAïÄÒKå‚`éƒÉ¢‰kgÓÊÍ Aœ¨fSÇ”ßEWõ¼–FL¤³>®¢Œ/
Ll±díéë‡òw-ôà”˜šˆ=z{úÙÏø$òÊ”øÍı†ğ¹ÊnÚ.W(˜°ƒ…|'=”° ³i!ñ,›ok37'*¢Óåöç·Èïeeû[ ÊïÙ|ÕºgÊ-‚£«µæDN£«3/:qòjàêGeö4$|¬‹/TMé¹Öèâkxø0v°¯\Ï ¬Ù=T+w†‘áWÁÆo'’{õ¸–‹,ëŸ`õâ¥{óÜEFã·fÄ{0Ğü•3XŞC˜3×JôøÆc³bp’ì¨®¤•<²ïrŒ<[&*Gv÷\®O£~}O–"ÀğI¥usG:nİ‡ş±¬ÚÂºYBËÔÙİëÉÔÔ$ŒEa‚+ÍàˆFĞ%@5~Ğ¿í«„+lt[qáŒ°CÔ<wI9úªãè{–›c•ÄÚìcS8,ª¢ÆõFğìy{Ìñ^©UØS3U{D0Èœ°uVr{‚¿?ñ	ÎUùhşƒõ((
%.Â;_€ö(ÉÿëŸNÁe¢$€Z…kòğ±|•‹½—A£wŠO0Ø$šN"„Koêe¯a x!¸='õU Æ7¼àVÅ^9“/»æÒÏ?“å²Ef·cü¯*|Û…sUÊí#Á§>üµ{¯kŠĞs6¿äœŸ†Ë(_~.‹ÍSØ¹¾>¸alşä9x$4CùçHk•1ì¡ìÍt§ıYòÓ1Ìêât¿ÿ%rÉ¦çO‡/f>JSøNvÔ¿ÿO‰ßÁ¢g6ÀC‡”ğN„±€ÖsI‰NYÊ°+½ÇŞ+»ï51rf9~¼fIr£VÍÈ}	‰Ño;C³GÌv
št¢é–^ !ê¾9"¸2¦ÔxÍ˜á0ä”0 àC˜+=EdÏ¢])÷7ÏÄd`<Œpİ3+a•{¤ !F­š§gMêÏI6¸~t ƒ5ÒA7{Ô[Î‹2°Vó(¡ş‘uÿk+7â˜x.7Ø+î«ı'B÷s2ûø.¯-£‰¼$ü€¿û¦±-Ï„ç
ØaoôO xtG|–æ:´’byÜŠöA·.ßi1Ö¥aOôØh#ß†î8ĞÖ äÔPª—@)Zƒ^IM•şÒ…@H6|«ü2’Aó´‘²:=¯ µı€s_^"Ù¤®\’âüš™'­ã'C¿JùQ3kîŠ§³!ñf6-5ï£Šn…´¬¢(Ğ]S—pÊùÒSDp]¶Š²†Î°çĞ‘tô¯N÷*%“¼X);ŸqØòÄ`«fÒF’ŞüÀ¼¹’45´U)áW•`Ö"9biŒPw#0R¡kú#rN>tƒëŸ¿g€Ùï×²„oBÎ
«fbàXmÿééIîªf>¶L`?m×8&{`¾â˜ÃN>Qq‰Z%ò9šüÃgş)á ‹ÏNÆê³S‚,çà"[03¾5¬åN…õÊî¶ó8ß&
á¬Hnº€+ù|Îo‡oÊqw)áX‹OS­ùmEzeµ†–´WĞÈÄM&Ş^u#t`ÆñhÛÎ¬‰±‚!4 #Êç¤[À}È#j™¦¨SÄ @¦~ı¯räšC‚@$ÉgìË‚¿{ù–“À"}ÅsdNxpoğ\¯bÈ"c€#n9,|Äßæ²øF2{…Y¶Ö:”µ©ë¸û„Áæ*ú	¯ºç ]wô+©)>–sÜRœ™wì„æ²A­;oo!I(EúƒåK{2Fï‹=ß)j şIÃ¦éÏì˜pÀ
`¨F1pKpbˆ¬ïòmÖ1“MºEĞ«»ËßiCá"ğì‚÷'^HÜĞ…ë5d'%ª|¶‰:9Ï‡-bäjMôÛµ)EğØ"h~{Lª¨İ@$İÇ3Êü{ÉÀ©ıÈ·£¡D¬µ™]~¥ÆôQaÄÈäo'ä"âš3L3ç‚=‹=€(J‡€~o§ñ˜ï|Ó{†£y­¥Ø–ì9	\f»kF†fÆí€iˆÉSîÊ@Sî¡:e¸‰» û-/´àWÑâÆ¼¦<ÌÀ¦˜zº·´æ”6™mBÉ<¿b)U\ı8>ê1©>HHÍÒFj…´NrÜÎºƒ ß¤ÈSô‡;NÁìîĞj‚z0£4T·Í¸Ù(ê'Çò¬ú ¡ĞQJå `E")àE\*½Äüx²˜QĞipæÒR7•gA0ÕGİå2‡¿ç?ÃlxˆxÂéL²v¦ÀhóUÒ£Œ©UWLS+3Ÿ‰l*‡cŠ¼9ôåp÷¬+Uá—Š£‹Óí"Ù®ûï'‹AÙma?qƒ×SïŞÎ@”nhö\ûÁBímˆ”méÍEHm_¨±öum™Ë:ì2jéÜr€xxjë›1<Œö““R/'İX³ØâĞ"š5w•Å…“ƒÒ8’-Èô¸ß#–ñ®·«ıÉÂñg˜OUSAH( =²!pŞÁ'C,×¾˜÷åLÏDº/¹àzµ°(‹¹«]bü)*Á Ÿ1¬ÒkeàîÇpÏ«OÀì*»·€êÛİÇvÓ)ˆü1™4Ò¤×Yô÷Ê7ö2Ptè¬)F,ùÁ(4xZ	àœ¦Œ~«Ñ 8m#üçOwğ>ÉÑg°¤N2»;¼Ÿm¬Q$¯÷µ]FS™S'
ğ'…†ƒË¶ÈŸzsû¸·ÄíÜõ4‚V¬¡ûg:NÅk×§:³U
íasŞXÙëg1sØÀtz
ğ®Â×ïóT\Š{ôÓ¤°r­
ml$Ç§¯	ÿÁè\Ç/ĞiŞ°#•­<xì#g…/âà„³	o˜wSãÇA€Ñ&v-K¿ô¦›¡ANæxÅå]î±ç˜æ€‰ôAd|ÖŒ—j°ynŸ‹èeBÈh^#¼Û¤)İÒ!ªáğTËj]ı¦Î4ª¹ÏÊ8¥¯í0àùŸŸâdôOc;c@üÑüvĞ.)Œ©‘Ù«‘¿HZ3±à3èøPOEˆ.ë«´n…ÀÀâLÊ8íéHÔR+Ö´Ü±^ªûìC•4Õ
_*e(V²"@¥ÌFqµ3ÄËµ²ÚÛiz7KÅ¡Àxú7˜ö&ı*!OSí‡<ÌZ‚Èk—3Y#vozSA¥y
„qŞuJ»h5ígŒJv9´Uüh™ã‡S§—ñëNq	™)M!Ã <›%`xErtX¶­ÇÄm8í~ĞîûxÄsy“úĞO™üXÈììËÏ-˜k4‹›9À*“h•=YÂ»z3FÃe*Ù+r±ãqGÍˆ¸ÀÑëçOã#ï7+ÔÒÇ”	•×¸ÓŒ<:ÿ®9¼T&ä3Æäô;Z#£"½ÆÙÁÂªv´,VfIJŞ›¤f‹Å÷uw{À~ì{lOóï«ƒÎƒ,Šä+×\¶w¼ êA…Â/å–i÷6JÅ¶‹rxÁ¯	tUåF¿*èÑQØT0óÛ•øÓ†7Ì®A¸Õ¥¼±ëèË'ÿjõrêŞ°ÄUÅµŸŞ‹™zj&¼DKf~L>*=÷Õ‚—kì¹ÒO:ÂYÜL»'xÈs½Vat<·ÄzÍxÍ®±„¯ôzGßÔÜb¶ésñıÂié«=>q4Iæä#¹7ŸRAxÄ6ÛqÄ/õSÄKö=³8@x"ºgŠ$ÂQV£6}êÂØ#Õ<¶9uŒíAÅ	"“[•6äÒ“&N‰~*–q¦Swx™_ó1¸š¹¦,Âp1£åÓÀof1˜Àíç³ÄÒ+RÌû·P¨ZPŸÆ è‰Œ²\Y³
„öşñ1±¡!Œe«™¨K tsÙµ¸Ù@pb‹üb&{E¸İb¹òÖ{´CÜ¸Ù?mcÒÍe¨îÒ|H@N]Úèâ|êC@kî‰ËYˆ.5ÇU‡ğ7$ÅufË£‹$où÷`ø¸ßå=‹‹8R;ĞDKt<ÇÍ=R]°¾µU½¬i5ÔÖÌÌÏ†~ı5Õœ²gªSÈ€uzTVºy†ì&*%¥~Ğ´PŸPƒÖÃéºñÊ{`2§À»7c+Î¤¾Ğ"ô»)½ÖİN"F¡'ˆÈ@bÃ\ËjºÈ–ìçÜ®»ÕÔ²¾IÈJ_O:ì¹æ¼
{…mPJ2Ğ¾duu@Pí¼í_EíÈj‚6Ó<Å¨¼È]”Eì[„µ‰/Oäìq :8¿¹Py,JbšA¤ù'²Ä¤ønújñ’ğM¬ÿıâO$:­aüãèáR÷à’×,Å½eÛ,,·Ñ[‹^U<?Ü…T¨€u½ô–'üÔ6Æ¸@ºÿL¡Ç$__‹öéñ
S©îzÓVª6˜Ì‡kúò0¯F™iËàŸhºV–š'8Ûcé\›HÍEÚR£H`öˆü‚w}úˆšPÕg÷]İ
]"¬œÜãûLB¤l¥'ÑvÊeás†m¥Ä”Á}“&©ë–ã#ÌØ#¥¸²?Ê=s÷4‘*Y§Ş×7–Sô+.ñ·çõu›‚sã?õ·cPÇñ„G‹°)MŸ«v¢Å²EtñÁKv¸›óp¦·²´·x/¾¢KéOVp“<4¹AŞ/óOˆÊñ÷l…ú°¿›DzlÖ\Lˆ‡mhşoòdJQÊd·¨ÂıÉ´åÈJ…§/CEÄ¾êZãŸPÔ,ZşIø>ŞSÏå¡)z‡bÂ=ô„'pLÅœx¥ø‡dÃå:Òê@Ü©«[6Ô½€0¤"ŞHd&$­i#ÜŒ/ìã:Š¤¬õ’ÏÊ¯—QE:DæA&ÿVÁ™ÅL.ò(9ö“´[––øÙUÌ<e¥5!èB8MÕÖniŠÓŸ?|÷öDUÑït{//NnQG³9Bé$Ix­JxÄDtTé9ºXŞxod¯†ÀéÑ` ßb5ãCÿIQä[|Ã­T–CfmïÔkÈuC¸»æZ0ÒÆg’³z,üE&ƒÁòõÃÙÒï£—z_l‚Ã)¦V‹kĞfuš]!—!KÌ÷éÕ°ã…j¢`X‰WäÛ­ÈİÄœAZÔ€Lìog”áªvıfÖ.™uDçß©üiƒ®‡ƒäR[êa—`Í5ºPgëàíÈ£éÚ~$ÂK–ÅbDø"Yºr+‰ÓşÆ7C;…i†‡AÙ«§4à%_?mùÍ…¿ÊC“6dÿ~Ş•eó²¯¦dıˆàÒÆAyZá¹W½šÇ§mQ›;&]ü,Š ²F¢ßÒğÏ’¹7øĞ¥e–c=ÊR¤Ôß-‘u0uK1¡i‘G.t•õ iÌ6è³Hb"µİ«PBw	<lBbfãPl* ¹o1	2<•Ôß‰fœ"Gâ]E¥F0¼UÍ¿ÕZ”ŠFU<e/(K…ŒÔ¤Â­ØB1MásPV¯L§ó£¤ÍÓÂëNÊ¤ãX*‘pª\pü“uÇxClã¦5üÚŒA›„öÊô·€¢‡mcö¾Àîü>ÌTÉÊßÅoNGü4ñ"­rqí§ºFUÇW`d0zÂsĞX˜kŸn($ÿ±—^Qœg‘ğr9ÎOŞíšFi¨	ÒU+š€vô‘íH€]Ò\Gaà3$_|’æíîw±€ñEkY÷›|ŸÖ“ZV#åçòƒğcqq^9ctó¹øÃ×«K‚şÎıK' RÈÅu‚êm[^d6f©o.qˆãd2Ã2GæW¶ÅgàdÈ\[˜Ğntşx|nË£f1kó]ãò#ÅjöD˜¬…ììÈ¹ôĞ=,—–A’‘ïÌ	Ï~Ïÿ|Î§ÜfDß AIŞ¤™ñK»K5ã°Q„Ç¿,í$y‹"È›œ9ŠíÏÈ5P	åßzÈ²Ï¦¡/¢ˆönâk1°ÓD…²kò
’[LüD6¡’YÕeêèâåís ë›J×*jËl?7„ƒÃ°YÄÉ½}´o“Ÿ¯ÏÕĞÙ§£ÑŸû%V»3eÍ<JÂ¬×ÿ0ØQ`álQPøöš0–Ò>™G3»ïÇ› V‡šÓR¨ù ­¦àÇÔÑ7ß\$
´b‹¢rq3í˜b#÷ycq)"­C£B&ã]+4BIÚUF’{AÊ0#^ÍNmA‰RYwSP	€#&›?Ñ!ì¢i×jbÅè X>uÈ² #„³v‚/vêìá‰½ÍCµü™ŸFl}öœÇ—ìü2÷²9#bÉCH×•‚•õŠHÙ‚=f ¼Vù¤‘
,lÒİ—ä¯¼m àõ&gÀĞÕ¨A·¬ÊL×ĞŸO`!ª™-ñ6]!UjYëhtÄëçÃÖ_ÏõÔCkšJsÃ›‚}b·]æz·wˆIG<UZ=dÜ#}Éô.”¹kyI08t=4sJß‚Â—›Æ.Ñ?!L $qPx›tC½:{;”ûÏ‚}‘kÉÊÆ²îh«
…¿Ë’\Sv=cI‹rfÿÀ‚F“½C•'ífâÏköQ{;kÊ¡RfÎ4ï¬@&˜àŞ¬ÃÂ¡LcN|„5»æµsåƒÊ>L|ñîT)jeù'fÕ.„¿€ÍÈÄt—º†ş]!›ôMìQ«“rØçş–Š#„ÉİåÌ3º¦Û9 –Ò ]$ŒIdúÂ.¬|WÄØûbÒh’#ûù¼ÜëL%
ÁœT &”¦:CÛ©†è$@ kÌe,ÛU†<‹JÜPÛønÂîÕ$[âzmÓ òĞµĞ»g^•Õs'z[,9´³=¹f»hç~N›^WØc7x¾D#«;ªí²_ÿa«ZAŞt4ñ"¹şÚğÏÈXwøò<ëa ç4û€ğøM!É¥F*‰ıàèQõ,w–\HI´âf<å49Ruùª`3¤`B6¡ıhÀÿô%7ª™™¤ÔÍßwñs@ŠÑœ÷G“€M"?ÊÈÙ¬ÔÃìÍ$	Ú{i£–wø•ÍÙ;¶_Ùæş[K]¼Á5	½øs;kÎùúËÌ{[ñc/Ü³³aBrï©GtşàÿÛâuÇú2ùIx>P{µ[wé?Èì±1~].N1V² ê“Ç®{S–T»€0{Ka¼¯-a*;o¢ÎEKØWßÛ9œi¸°³´ãæ%¯'¼V"õŞöOIÍŞÁDdyZ¹$¢LÙ+¾ŞÚô™•üL_Á"«‡½&w!ÁpmÂT‰iáFqpçšl¥ ñ/Ûwn_›ùúu…¨ğŒ]qs@Â†š^°i;±êúgDä u‰˜İÜf„£³8$	Xú¡âéWé÷Dmñ‚÷»XEßş¥wÔQó“ğú8ÑmÆo4k¨ä¼¾:¶ò½•¥c$Ş¹ı‘¼_Ëƒ~¾ “[ûy#Ôl€“¸õÓÌPı»uQ<exĞµJg#Ú-ÈG¶MçiÎ™á w£GÀÓjÙ}½*l:'”§iz*\¦ÿëEH›yÎÃO½Ãt¼Îñ3_Å$;1Ãåê u¹ğèRk:òÂ÷‘1o
1ñÇ`G«$¸2)%?ÄÆÓ¥fÚøÇ·ÂÂ#‘èAK[|×åàûKÇvË•iHˆ‹¨É!³³mgèÃ¢`Ö¹ãNš€l!š>­r»|èèÉŸPŸú|ã± ¿P)c+×`Y‡+@!o„,@MØ}ŒK\„+­ÇFŠµ×Rã2³”²1‘ÏF-Ï¸pKŞy¬ÑôiïLØ@lÏ©œîL|d•L1ŞÉñ€§àÅ³Eµ^³ˆù]Ø©&skDïí "²¯M—Ø)‡2 [~ù¦/Ñ-ìãxÉûT‹“zˆf~vøKß²¢$vZNúĞfÎúÀ÷—`¥‚Æ2CÂ9;òf6@#òèİ²0Lˆ–'}‘Y37¸´ä÷Îõ¥É!Z'€ƒ3gcä´¥å4Ö…Ó[Áü–"ïf²<éÕèÃÄ"î .YTÕÀÏÓ¼ˆ= gO4"¤0VÇ`¦Ï@ÂI°Ôú)b6›¥>P òò£„wøññ®òùTo{ÁÚ¶¹Eôğô7Š…6ÈêŠ*ˆ¨Ñ•ŞÄæB\Ô–ˆ²|5råFÙTvf -µğFÅÛ¶¥c!ğü-*e>Wë‘­F“aŠMf¿VFg~ƒôåĞ_›¦3Ù÷¶¢‹æ˜®~Ûùe$¶#˜T¤kT4TTÿã*/°àùXÿì’/6ÏEĞN¼òP | M±³ÇHjÇèÌ,µÂ\’&d¼rİhÄ[èı¡\Ó°ãe5\®£Âš³Ût@—Äìót`òøš¤;EÆù9_ß¤5Z°8.Õoº¤UœéLl¤.7´+Ä!AK¦¡oŸÈ*‚pšlG˜j¡¨æCbœgí]Æ[›q	E‹ñµ•m‚˜&h7‚)2v³ë[~@Fm{TthÕ\Ú¬§Ğ¨êZLª]´ÄyípgB5=p4ÿz	à.¬T”Î½ká46Ù?»6óU3
»y‘ÑéîC$pAÊYâ?ŒªGq/áŞûÌÒñL^ª,[ëé/Ûfqí¬Ş¥^-öœ€,ùŞàøï<Ó‘í»Æô%,cï·ßiæâ8ñÑ_ŞZÆe¯ïcCıN	Y„°•`İG]ZK‚¹`"l¸ê4ÂØ¶´İ‡q*¯f@§P…v%õìïè–S%3ë
Ú¸jì†ñé=(¨>\°AŠŠjJ¦?:Á>ã’±sÈ±Ø»?Ğó¡”ŒvZ…ç742õ;:‘Ãîèy .-Y;cåÒ„2»_n1wõÓĞ¹Áfo á‘7?Nì‚Ø½r`ø`3_ËuRŞòQ1åRü¯dS÷ñÂ¢CŞN%ÓXßÏé ­X­N¼P]şÔe€{‹8¨Ù'¤„11º¾›š€,÷šËü­²w5h—DÌ’¥ÂĞ7Tğ•XÀÉRkùdÏJ t`ëwÑ2(¿J@1³ğª"n5™³ğúo€¹!Õæ™-²Md(4†iyZ¡zOİ°0‹?-ˆKªğîÙ%¸1V<|¾[õñq‚çÎ«+¶±]“F  Ø·am‹Öí7zŠR_#@Ş~ù=“ú9˜…æ/}ÃMé×CI„µáQB)pP(E)Àôzu?ùâBæªõy³/|ÊqŠÉêTÛ#í³‰E r‚akŒE¾²ƒn$ÂòÃ˜ñq¡]€šdŒ^ñ»¦>·äqa)DcA4%ÚâPÇ,¿\uZMÊç:åÃæ…ÄäÍ×ŸïŒ@ô‘Báˆ-WS…Mc˜ÉŸüÖõ–şqAàë‚i#„fş/z@Cp(´p MªY4¿'åÀ~Ia…¹o^ë®ÅœäAÍ±œ™”™\ÕSì-Í?¾ôt%ò„ ±ş9Uí0ş®â,+É(}À5Š,5gå…ÔV÷àÀï‡yÇ_e*°û”7ğlml ë
·2[`P‹Pd¨Š(j	¾¾¦vSœÈ,œ£bmÿzœî0N2œüÑe¾<yù˜æ¡åõ+-Ö‚óÙo¶Nm Û]C‰¹\vmÄ£©˜BR(«wŞ bôjôÀq`Ñş%SÚcû¹äa˜ˆ¦¾	Øş+‰bÃù9ŠÿGóeŸØYW~cúÏ>¶*6°)5	ê³;„gƒ¥ÆfôÊ’Ú;êØÙÌ„±•¼ÍIÒº]íéôTIâ„BgC›„¥îT#¤ÓŞÂÆ{…g¨®î$ÃüÂ³8_’×»$0p	ç‚ö5Øœ•¸EI·ÕWoY“Y£<dCë£iïÓVgisŞ†-Ğúğ­ƒhÎÜø‚Gş!rdáêÙzbè'áB?$a!Qñ$»K^ì Úé„ û+;§*ûpzdw•\š
Ç±’×%³120BàC£>%IÈ¬ñÍÚ¯ˆ_ìv~Î˜BğnÃ ÷ó†sM°+/Ë(,¬([ °´JG{§Ø Õ$pVİmåm6yäÉãF`FaÜwÂ½Û{ºúÛ‰gu
èúH€n= ŸŒ*‡ÿYV:µ¸åçR¼µ™Cï^zo²+‰VfkÛ’Â’ÉÎ¯I® –<^Í&Æ^ÕŠØ
RmØG§:ü¬hødÎ l@#/ZHMAø¤ÙÊyFªóÙ?…ÿ]82GÎœV§ë íÉx1úwøÊ˜¥£«y¢½c5é-‚×ÕJoè‹0t³l¶é¦õY”RBHåÀß‚æŸI§ßd¿Ì«ŠÀ÷Ş¾g ãr<oêS=pÀ@L|û®ì4"|7Œ`G
m#j_#‹›0yÃâp4ŸV,n+ô¯X¥ö‹Ö€ŞRg|5_U",ëZ(Åš^m8 ß,àû¼ñFìbÅ%o
FK¤«Ú–ö[¤2:ê1¸(Íñõ¥WcÈX¤^±º³ó\8†o².Ú(o‰¤3ëÓj1a¢@²õ-b<ØIk/p¿#ä™ìäd`°-Óh’\VÕ´åŒ"ãYDÔu —i´&îJÖvÊ´«ÇøåÁ”db¹{zƒF8à[¤îÇGŸí-ÒIŒ¼şà‡u¸mÂÉz
af ö½Z9ü}{«ŞteíÀGÃXj*…Ä ,Å$­w(ê5’PÉgÇL•iwÀBÌÓöÍšá‹ZSà6¡#&ºh&É%Ó²“CL;qMÇÃÖò©Ï,“®»²µÅ\Z|o†%ä£ßş¾g7“§	.–•1íü¡Ë\O¤8Ú}*#¸aÖúk§³€èe@œTî‡ÆWTˆùäu|eÚÆ€Ë¾}Œ|£mY¥¹è¨ÍŠPÄ£À¥ü¦ºÊÇñ®Úè¹\c¦áb’yÕªcy'_û´¬# ØìnH²3ië®"¨O”Ê«\Ï}Û~#¹m,1›åaıB=F‰AøuPñEğœAL­ûÿ‡™drÛª£¿ƒ˜ÁJ½^ğù£’>¶¨>úÔf‡0B+)@œÃ!zÌ-¶Ï¾ù1 *1®Z²}è [ÄA=WOØôße=¾ã£ •.7{|\6äÌh€ÜB6†-šùOç¶Ø»Àå¯5Ä™ÊÏ§¼&LñÊ+¡!ã
Ø+^¤7EÌ{ÉW½Ş½ªÛèµ"§?‚RÍ|2>ïÅ¿å¦âT×i3ï¬
ş$%j6ğ"Kr²åĞFı_®\¥{…N˜î73¯Ïñ7=9` í	[6÷‹>¼ÔÚUÔÀ­1ûË\¸ë›.”¸^{L×ßĞ@?Œ(MèŠµ]†Õãš&,ºÛÚ­Ó¹ 3³ÁÕÄw^š!2,ÃÚ Ó8§Väh|îå¡§]=jD;AÙ5äï›¡¶¶j†£pòà/yµ jh%½t—‰?Úz³lšÜ&ë€S=LwŠ"ïÚ½m”ßßVöçÆÎ.Ûó®¹Şiš\U”84R¦œT®UgAœç1–9«>©Á¸]uËU„XİK~"t¨Œ»Áóò8Àf»Éã3´qÉÆ^gË©àÄ¹®¸¸‹±} mîÊcÏe)W~<|
–á€|
V‡à­ñ½æÙÙğ¿ % 8 ¶€ËâäØ{ÊÙ/óHkÔù›…é²VšËT´	Hì7¤kİå!a2Ä$Ãu„ŸäÕw`LÌ?"–ğçJæg›ñTV
²È€Ër¾0S$Ù'õÓzPj¿XšŸÚóäyhÄí4&ËÔbÉ{IBA1ş‰¸ãf­¯ÖäĞîÎ3àlí÷…rõP?ÚNŞJøÌš§f5§vÈ5¬ÄÆï˜Éâa5ÛÀ=äwòÄóŞÂÕo~ÿp7ûŠÀ
ƒÂı‹İÊ\Èu}pd5A*±¸ÔµlªEæ€t–C=Í²5Cj&†3Riá7øêAÊš65„< íHÓ±ìt\ŸÉ°j5k5dÃ^“øÁï,!e•8ÕÔC%@I\+nOí„Ñ®„¨Sa¦%ÿóùSôœâTrXYãB2®6fÜˆ·¬“zôºiª¥Ÿ|lÉ"ÓĞÛ4¬—ÌÖ„d¤¶>ìıyÂXÛ¦¤ú©‡ØD8ZÅà‘¨ù]±íNÍ)–˜@‹ğzÇğhUeå±S‰™ ásX‹Ç\£Œ©¥ØXövîæ…Û²û:iÍäÚç4ƒéêøü×¹~Ónè 8À$+Wÿ¥¢ISû}!º8ãá;TÃV)^%í‹„¹—…´jP5Ã\Ü24!ºE”·æ@n§…Ì-Êaõ$}Ëåöä5¿b)k¼ªÊñI-á§KA-ñËf	lx…m-	Ó’8í¶igâş±4²ç&3…,Ê•£º—@F„Ó»ê.ùì91ˆ™ˆµ‹î;eã õˆ©œŸÖÔ¤şA{¦Õ@u=âÄ‡Íò¼²;¼]IISõ®ˆ5ŒS6c*§úW³‡` pà|ÛäéÏL¥¾Ğï+8ãN7TlêzsU‚Ú:1ô+´},Ê¬[”Ç «1øÑ»½X°*]‰Ç)DHù+ÇèşÑÁó°ß&€5EÙÚ]ï’î›èV#|œwÌoàFâğ«Ääı¤bÆç˜‹•±t¢È;‘jy Uó¨³M4’£AÊ‘u6ÿº'•ÉÈÊ¦WĞ)ÑóÂ?ƒfty5pşû—¿ª@Èr - ü¸°ùC;ãYÃåM´D:¿“¡ñ÷4àÅ+ÁŞ/ÀEMÎG@4ÀºJšôGh Obw,øË¦dÕ+.jÑ(ºêšYKoõt2*#$H{J´WİjPÂˆ;„IÎ
erkËU 4í—J±&ôÛ+z•ˆøêP´%î¸}ŸÙçøŠwÄ89RR«ií4š6 ¯JÎ¦‹‚µ×j D…÷¡¦Yàôf tF™ğ±a|;¥0Ğæ4D¿ÙÃCö‚Ô©¸m=æDEé°gd´ƒûéK2”HbÕBLºV½¸ÏyöGœŒß%nË…ÓşøE5wK°íßå6R·ú¬„Ïå—”ã¡bÉEŠp¾õZélÙÀFğµºåzı•5ÇÉwU+˜ï 'W·gqèáX«ÔÒqpy–^óŒşï¤[Ø{È~İ*”=öåâès«hõPúæ˜c¡+@¾î½ÚPPWF3:Ÿ*ÉÎÛk,lò”?”ô½ƒ úlX¸òŸwØğ¿woşûarO$ĞÌßG<R¡&X.ôÕ)RÓ^m:a&Aw³ğZŸ¤Ñoœ‘™§”ø‘—‡µ/Š0÷f&b;÷şàUßÆÖFç´à
‹üÍ]u5uÿ/gã·§—¦¥†FÖdŞ¨È$¬úuÑ,‹1½GfòÈÔ d²˜Á^¶áÚíİ£-ÎŞÇ !İI£í&¶Æİld_ë²Ú,F]^ò­‡2Ñ}r#|ÕÖzıjF®§^÷êY˜ñóÃ2íÖ\MC”:mP©Ëè+Àó9”iS`ş¦ç“î]XEM	CM+vçU}ó¶·MGu|cÛE,â>Ò¹öŞ-¾Øãhóh±ø3"×Ú\Öv/`šo)®·*…©©İÿõm1¾fÅW¯'n°ˆkh6ëâLóóŞ²Øf†à9©;¢Àæ¢Ş˜v%Ê'’|‰Ñídã/ûw´ª
ÛN`ŠT]Àx°å¾ ûĞ‡f¯ˆHÆİ‡T‚®:—AÚÿÑFèî§›{R1A_lƒR ™,k»ÎU¨p¿±\+¦õî;ãó·-áâ)v¯Vº Â_S%XÔÕ›ìÙœ@;¸æ’¸,¢£{ÂFf™ùòVgÅrª–¢u°—¾9)Âş¬"p;íÌT©½A'ã]zíz<è®ÚÒgrÒ<ÎŸ9^¿¯O[Øn± övüej&ƒå!õ™ªu¦[;½@{MË
úÊ•Z¦Ëëï{¬‘¡­º>—ŠiÒSğç+íf8šòC	$³oºV¶9’’DÚÓJ Á`ò™G ®‰Ä”àS09yÊl¹/FÚ#y’[ûÅÉ~l¯Z‡~¥«áZ¿Á6ØÚ îZò4@×ûm~m/¸Üò °}ëx™Ò×«Y3¸3ıÁáÉ©*˜º¹L9-']2íµô“øÌA%L\© ¬’ìœV,öC Êà?ÿõJ^êö:Š„ç#¡{'<~ÿ“™&)àôV[‘¥v&L†’4n®“^×Lì'¶³)6ucî7Ôã„QÕuø“7'orÅ[›Ñ¤Ÿë> {ë,	¶Cö¬«×az:½M íŞëŸi,+×|„„Ô(¶yw“ÿ+¤,ÙŠ³ĞÏŠQnZ³‚Ó6ÚxvÛvuÚ§Ú±a´Ê9'zUßƒˆ@#/‘%`­…½2ës¿áÖğ'§‰§Éëâúóå§1½B…4èÉ~cº&&Ûÿ½´,Nù]Üä=C´sşvôÎ%I£È´:t³¡3ZD6ÒD)ŞN+Wùó³É´C?a”èf…»ù[œ›$z¬(]Iïƒ|“´u‹>ûüq³Uşû3‡ªl#µµk¾!¬ëf(ãFã–—[û)(È	"ÈÿÛR-0™è*¸‚‰t¼{e%§(ÆIîÓ#a‡X}eÛ9'Œ3ß¦ë±¾š $=™õ_VT‰ÈWbuOÅÿË6İ~ ıÊ»´@ò!UTÆ`^ÈS_á}1p¼É÷•í‚ô™¯š©¶räš:Æ9¾ıxä‰ˆıOñ>¢x““Ò"âºf?,w5K*‘æ@Mmî$`üæÈP"ƒı0öuY§÷‹E‘·²…$qn…¬bÙfR²Ë`õáˆ…°{0DÒq ıÊ»}Aâ%™fV_6ÁÓ¶tB®:ªA§ 6U-§Í0@-óü1öw(£ÒHvHšÇ!Ê²{¦>LBTùp47£@	¸O$'üš?lãÌ¬ªÅ~©Û_ÅèÂUŸÜB¶c¡lMpàa£dìL«Dßûé¹š™!P‚Š£vÇ¶£BúÔ†O¤å¨g!_ŞaCõQípñ{Uš]øãO.•¼X|M»m÷™Û~©jÿ‹Ã@0œ)¢‹•¨Š;Šå8ö"BÄ”÷*¦½ÂüÔQ#×ÏX;²ï‚iğ8&!(m+‡+z(iS±-- û®ğÏª[Ğ{’s   |ÕÂŸ­T¨ŒT~àè×ƒŞ[o2ƒ•­yOWÂèÄ+&2cä7áeê©‰ø§»¨Ã8t"¿ÏyÏyë"-ößÌìıDàğ6TeQ7ï8æ0“íÜL·î}‰J)ÂıFÛ©ØÁÏ`·WàWk“bÏƒêÑ†¹xÏysñD}¤‚KO¦øBÎÎîíEc¼È3ù1FmB^2)¦ÌŞ=§_	F*Š°h"ôú#±úö¥«ı_æÌêŠ<ê…L³¬ÍªÊ% áˆ'ü»M2ìñÚJhd—d.KÔ:w²Úµğ½;¿™;‚fû”KÃÄ‘'˜ÜÁÜW†–ön­5«ĞhÍ]º“Òí$]ª–jû‰ü
=«,/yŒ§(W‹U%;Ê–ke.1Sí‰©àt´OD¥Ÿ
è‘ÓQH!ğoQ^'l

û‘‚†“å S¹£M¯Á€ìË5®Ät	ÙÁª²
¬ü´åæ§Óè§/ŠÎ/’íÆäAmI®Ü@|/ÏÜí|´B¿©Á¬±¨bhM†Ùçá-–
G”å+PõLÏW:V°uòæ¥gÉèÊ’qdï»Mò­Àûˆg|øÿXÕÔOmÚ"ã²•¬¤ç¾_¤œ@›,…sƒû9üéãpòö|O+sTî;š·n°`‹ŒY=CP¬…§§;„—BÂ!E›»¦¬;ßÕ;…¬ª¾3ñ?€ÂÁè¿|Zë3Z[
cºÀººN*J´[èA!§ 67ä6•l?é¯ôÍ×Õû
Íµ7Úc—ôª­pûµ&!&ï—´G[7ò-ˆôæærä„fÍq®üò²@/²–$î«|Ê‰&^#è1bĞúVóZ7®%+{]hÉçÎ?D‘UìƒšLÑ‘Ó ö
œ†çqRÁeZob©u7nJÏD˜(—ÎÉÛ‘ş]YUœ3˜ot¿Ë¸NsşâY:®(p9#’ÌÚ¢<;ö¶×j{Àxn_#E{°”>)~ªú·í™àGy+6éÌ0OE²ó1+o†q	K’ÇO=,‰u‰è¢Ìâ	~£AıE­‘§cH$…ÛÙ%…ku»@N?©,‹"Áù÷Ä X/ƒxÙc²‡d·
J-x|£Np…¼øÄØF«"ë³YEËv©µÌYs¬€Hù|1U%1ÏÄ@n³‹2A°cÂ¦UXš(ŞEz)+tØŸ—\F¹q7¹’åŒá­¼Yº8L´17¯Ü²ê4Íg³%±1aÌ_Q-*Q4î•(ü_aq]½Ğ¯ 1îÒö5Û”d#p ÍÃ«Cœæ§»Ğ-¼‡LZë—ç¦¼¥'u©ø '2^ÒYN5¨ÿL…Züğß«“ÁÜ†•3<Ù{ÿNs¥îª3H¿KT0f D“†,1ÜÂ|ç†µ¸×wºôúkzá½cyÍ“–”ŸÛ_V!]º° mBäq6Æ›BŸàzÁ ËØŸÁÊœ¸‹¬ˆ?6|î»°[šbŠk£OŒªP]Ÿû"üëáè˜ù…¯ú`5+­®gÓÄd¤–„ääjõ¾¨…±ÀSAEI‘Š(S^ì¼ıÅ€a3jìı/oÂ³û($0r×0;Y^¦Köóƒ’Ä¬#|Q1~`=¾Zó :#™;Aß
;ìˆ¦PÒ(¾	p‚[rBXÁœ¸^+Nñgòƒ ƒS‘¿½ÇtØ‚QU@‘œäC‚r<:&¿¦GşèšÅ­\5Eñ¬1ƒÂA;yZ"Å Í¡«?öi!}Ó‡¿\İ«P£¥M*ÍF62ô”Üú^Æ¡Å5¹dšã¾†1Ã3®5-¨g;Á‘Î¡Å¬ÆµzB#&¥<A›}~½°á^|ÌÂê:ÒqMø‡h€ï¢zXª¨Œ¬¹¢Éå˜ïåÏ6ÓF^Ç ïõœ>c©¶â©–Èq…ÔvTºjñØûá
7İÄòdˆzùßkÏ¥°'2ĞfC©œ”}‡ÀH¥m£ğ|ô}|é£mı?7õ¿ é®ù@ƒŸôFx*ï_ìo‚]RÂ@TWõåê:Ù§Î¯º&(d+}X<¹—õ£”N\ĞÁPÜíªı¼§Öi)ş2Ì¶ñbéÉ!Gå¯nä††Ëksâù³¬
iŒÃÎ6›åP´T)<VÍÂD,7æ],JÉ%$uw[ç%é¢GXE´…ˆÿñ+š'yl
Œ#b°Rõ¸tâ¯›Ou«ø˜.níN†ixp¡wº¹K­wRƒ+`K‚_Kƒ¨ü¿š$½¦qßıkéãÛ7V÷ŒÑÒÌ³tİìmF‚%Jä––Ø«ÑœÕËu0U˜½
»1ñy´i‚;X9òòZâ]ˆ¤‘ÍjÈã²ëGh§tÆ¦-8’gÓYñÔ-æ¡ŠxÉ`mø³^aTÂTÜ’­¤±–½e\
ß(œoV	^üN±@Ÿqcr7ƒùüòp…ã ùğŞ4†í9ÀW ;]ü	¥Y¶7{+)TiQ²Ì°şRÂ^Ïâæ¢êÎ\™Y¬$ÕT¹ÁşkŠRÆ!~KÆ™ê|[&‚64×9-jâµÌƒædaªÀ{F¹/L.!²#[ÊDû‡ É®uŒ6*öºYè¨}İ­¶?_W p’Hâ{ìûñ„4EWú•Ş”P«ZkUª¡¤³»€óÈB^µ­Me7?Áoµ>~{âÄåV6Pô¡¶!JU³T“Üé «ÆÆõÇÍÕ8Î­ÑÑS¥FÄ^1ï˜‹øºE-	›õCAt‹­±‚r&Ÿkeè€D%–è"‘4ßıÁªbTy¯Åpi·d¾;Ë¼ïªOÔy¿2±LÉöır÷’Yf¤¶õÅ®Tb¶œêqøªG¾İwq]ÔÆÙE½Î5ÄÏ‚Y%F÷ıºa|Ap¹¼i\‹Õ~ñ²Øª¼7"RgÕMˆğBnØGP;¶ğŞ7õİ¾\›ÓšÖâË< úÅµ†@×¾dX|H€•,@—ìêj=Ö›P£ßË‰3§e¹¨ù¹Sò.Á‘’\ÿS?^p¢BÃlp†[8]Y¤-vÄO˜îõˆG„ªr¦ ì³şüDm%¯\eVfçrH÷~ì:´fœŒY³XÕÈ¾Qàëzú&ÿ/ºéh×ùæ¿/ô¶ˆ ¦(#N)§Ş'ìd6ÓÉÀ¤€ï½J#_»±Dvæ’‰$|—ÁÅ%ÎÚĞA*2ïû|\M±2ñ‘»?KfÕàno/*öî¯«`‹ã)‡•‡gñWx;ƒ™Ö9¶Ğ­:Áß&ÅÑ©d´‘Eå'ØÎµ³*A˜î/w.Çè|( ““o®¯À(32¦âvûÑ "V›\?}kÍue´~EÄ‡Q“ O²©ÆrÊûp»ß
âª–àì›ß¬]DDPx»G\›ãÂÌ±e
?c@ê¶õ¦|ó÷VVEAS×WÛ¡Œ“mƒé’ã‘ä…:Y(‚±~UµN÷½FÕCı‹úuà½McuŒØ-óôëVœ¡˜L´_=jìÿS¢áà)£\:¢uá"xSÈº%®snå©oefùäÀ–ñ”Õ•KT7wÙŞor³Ïœöş96}éYT=õ’Z ‹†™ÒÀˆb.á*OT»4ò-·n\.ı¥èrˆ½öñ?±\w2 OOòÒî–ê§YjGÉ9´ÌüğdúûÕ—: Îåìo­¦9ßÉ°û*İ%ãkµ1¼Eğ·¯·|ı­èé‡:d6õò!š_ìş`F%YŞ¥³FKS0äºØ_¤Ä‹´¤\^ìüìÛŞöˆ¼N1Tş6["×v×ææ£=GóÉ PXÚŸª®†“o4{Í|R9¨—®e£´ø~L.£D›)´äLY~Æ bhÜÄÎjôº‰jÎ+™ıQºÄì”ßĞ¸­é)%=U¹S/í»Bıì1"liİ–É±ÖŒ“}Dé¡,´/~Ö“ÔšhTëHœñ˜°DB›=Yõ±Æ™úlõD„·:*ÕÁĞ—g®bÎ—5RŠMúƒƒûØ‡ˆÛè7PĞÓ?sğ-r¾ã1DîöPÁ¤î£²ú±í.@7öş\e’XiBG˜ëˆy¹¾«° ÜMo ƒ_XˆE5j%Z½[Ş÷ïÌ½“kAÆÙŒMs€78ViŒ¦T"Bí?ÀŒ*J!,ÕJSÆNûÏ­B‹’+22ÁZËnòYĞ€R»Î-Ky9ïµÀzœ“û)MÄ‰PŠ-!|ê>8òÅ§ öYÆ‘(üŒ`óııLò$¾Xî2	Æw²=3ß@À
ê€r–œå0VbS…ï|*¡U..ŠrÛ~G·gÆÓÏĞ£‹–=ü^‘–Š¥OÑÉ´kÌÕ›ë~€clÙ·õÍ¨ãÌ¬š«kå7N«ÁY¡‰½8Ğ^o†·s7/;4˜¸CëÛ*4VD`c¦øàÆ=4Ì±×;.Ö­% ],Nå(ºG[j fÑÊ(6_<SŸÇ˜ûˆ0¦(sôÅ°™c›ËÚ9„»ı“Ù$jŸ"j¨Vmbö¹„áînè£{‰‹Ø8Zµ *Ü™ÿ½„j@;ø0€¢Ä«}ÛwËI7ÖiÕ[[Ënşš¬æ©ƒFše‹[óGò25¼¾D“Š±Üñe¯Ñ³Å&?it©¦¼±şb¶Ÿ/®,ÍíÔøù9 „A+EG:qOŸÚûîÈü î–fŠ Æ¤Üã÷ı	ø3[ñ©—&¼wÉş è¸¯kÈl*
>g[°
›ö¹DOàÁqÊÌšu„¡¶ĞBF_°Íg”™Œ@ºC&Î;‡QZã¥„Ù‘à·…° jÕ†^B¼¼ÒÊè!}àòŠ3un¦Ì¶ıîÊk¬ÖÜ¸+a¦Ÿ=Ä²ã¬ì ÕñêÛ¡Š	by°Õ‚XéÑjİ7“©aNƒrmµJS1åªÑ6°°µëÇ›ıNHÍ´?‘İâ™ÿÊ"çMÑËgF8×²óH­Ês”òˆAÂ¨9‰ä$w(€ôSoC‡¥‚ ‹ãò¤Lù¿åØæÆ~ë‘,Ø)Ñ/5ÁĞ ^ŸÏT±zdÛu•+xiôÅÄîi‘Ënu*s]¶‡ŞÁ´H‰Åßª„dÅNØXÚß(d~ø£1¥¬/«¿–}\QÕè0º'wyOStÕ¬©»•¸ArÓ˜eòø¥¢Ù–›rFŒ+WMysâ‰0`ˆr¢ƒæéW¨‡h¿˜Åõµ,~õ×‘­×¥îQGkCÕÉÅ3µÜ&Ñìœé¢ÍƒJ”î‹~=@KÈKOşõ å€ò+ŞGÖG\’ù 2¶n½Kd³•*áU¶.é©EŒ¹Şà'XØ›ó¼÷×äxEBœ ãM>QvÌÁ¯Ë²ií^)bôòíîY#K|‚«0—ÜÜ‰kt0ú~§²ò|óèLº®é–é0.>cQÍ¦tËˆÒ±…/Ÿ•b~(qŞÍ (>ëæ÷²X¢¦%QÍÓ`çÖ‘yq5:°“½ù1yJ­°PbŞ.JŸï5Rtfw@7QŒR6~Ê~p¼hŠ:Ô%q"kÁÈæâI*S‰û<ºä¡ˆç;:}*†ìó–¾>úuÀAĞÖ«¤áC"«T ^Å¢©aS¥ÙZaŞn”Pm“
j)V’oÆ“¥'ehİ KPûÎ…öu=Áãx=”İ¼iYXšß|‡A®‡óeWJggüy-?‘y+&Ş§4ô=úÖœÓµé–#àÁ—×AÌîÎ¦wºPæš‘`Î¹\6-7r"=3€É|bSø¥ÿ[A},Ë¬²’å+ÿ›G¿03ÎT•±Rh7Ù'¡%­Gühšõgãı®oİ³&›%Z´«¨²ºÏ…|Q³BBÍöJjĞØ74Ğ8p`â£!yœêüÓ¯´Üÿû¤Š­Ô‰ò\h}¢¥ÙJœwÒ+Kµè4ù„Õe“PÆGF[ŞªÈ:‹Ÿl(sóC+¿È_'k@M¢¹*u$®jÆ¢¸ñ|7#w>Zš£8 b{H/æ|IS„½’§$õî4zz¥t‰ê`Å™¿Hê4Ù}±ğÏF*¶7ÔÂ½Oğ¹ :ÂI¬ó3İ0ŠÄ£{ HEÌ¦Ûì&\µp&UV‹]×¬JÉZC2+ÕHF–º ò]6Çâ²0=SÜ“èáÎívL}ÒO‘ìBsóº,w1BZCØblÄÒ 's”¯ôœò™1d¦à#¨#®«dØ4©7 Øæ‚^Ó [º“¼ôü6ubˆz)¯ÿZ³ãYo–ÅÎ ô K{(
—„ƒÍi_×Ë¹2‹B^:]¢íœQü|}åª0Ì,\lÎpß9u²è>R~®íKõƒxÄ6%ëòYZFE¬ˆ4Ÿrn\r™KÍ“ø0ÌxĞ£°#(6&Š[¾…bÊ,rk»ğrM¦ª+ÍhÙû'‹”å@üXM
 \gôa,Ú¶Ã$¶jT2ÛEÓ­Üó½ıı·73x­Œe£í dû”Ih*46YG¹×²iwĞÊF8Úu¼´\ü“ÔĞ’ĞXXÎ‡@Ï^±?€}ÿæ<îáh‘wŞ{må=.µ#hmá‡pĞ-ş£ssoA©Â;q_Ö>¡2(1úÁšAEĞCê|­Â e‘D¤2oÛ­‰&Ø’x›\©!Qé9	4åÙ€2µÛÔŞ•h€„—‚ëvÎòû&£6O”5›,63¶f<\ÂË\ºo|=´ÛpôÂ¡{½DüawÆ”nHV\ÕÅCA¾ê–#ml¦št3¾
›a|.*A@)£7šÀwDñj:İLYâr«€[•=nAö„•ù°‚ï¡ öŞZ:E?ç9Ë;3Ş6µ@•»
sE;İMª|ŞÍš½É\= vüSy´Ïªƒ,}È¥>DêÈ>ø^Öé[kóÁˆW
Wƒ&GÍt(f*õÂÂ)LEtÇ	^,X î§ÊpœÑ¶§c¥½·¨b>eĞk}#˜nRæ­Z­8‰%ùSˆJø_ÆÊr†‘Lvd÷zl!gĞsDˆ€üÊ@à$yÜj©¿ßòl5¯bãkÁ'Kè–&Í,'b-¥ÄV¸ÛL8ç¹*M{İî*¦¬™…‘şND´½ºL?ß…ö+2aOy.•šR Y|ÉêßœkJŒ¢jKõIRS,VwƒñÂk—äMÉÏ¸¾?pòkŠèaÀ{`[Nš87;üdÒÁ[;H<ªEå&£]\ñI5P›ÖâĞŞPBø‚
ÈÎWf¼9UN‰½îxÎ"œ'ÏUÅc¤HgõÎ.Ö%=vnØ@†æ52§iÑwW•±ª©mv¿j¤Ñ¿œp‚^ø$ùî;ÁİØ ZïBïz&´âÚ-_J7–Û£{ŠZ&Dœ4{L44Ô³å£V®ÑŠÁ‡Uo‰¨$‰'®Ÿš›ö¬LÄŠy\„^-3ãp>Ê|¨y§x5ZHd“îŒïUº‹šÎ²ğ£4T«·Mw­Ü”Î½½ÆîF	Ø¶^Wv¼îov¨Y\şPÈ7ÄKC2kİ×/¡”Ùtãé\j¹é®3$í/<T—øÉĞšÉ%TK·Qh€r¬AùG6BEpÑT7ÁÊØ~ddÃ…Ù“œø©•P[êš*?ÿ@@öV7¢©7ì,œ¯aÃcÿsÌlœÃ¿N†erBstŒÌççÅ0•ÀybålÚ&ZŸº{ hTª_Ÿóğêfñ!4!ñT"KQ	u&ê&6ƒjíŞ°/gz º‚İ~²°şåq24BÏ„q¯*Èpì]åÇew×J4Ÿ“N‘[:„zşe•…¤ŠÁö¥¦®“Ö"«ªf?.=…Ç…Í+-83Ö?dAQ»§?¡H™
L-µ#ÅLûn\‰Ï1ö£-aãz+¯RúİÒ#Iu°[¢îÅs0]0„²¥Ş@©MÛj¦!añQ<~ëT,ÊéBH)<ã.VŞ
¥¹¤RGiSShIÆœUNé×{©ÌBt•7’Åø%«$ /Ö°¹tuû¡íC½„Æ®LšTÃr·Ùé@%: xB—àÒÏÉCÊ	š)qWYMûÏ¿ïXYˆ	QèìjCêÚÍÉ"âåEœ#˜5°ÿÀØ+C¥mµ©@¤isYÊêµ%\|iØƒE¶õ R)µ‚ÑÄ×ß‘´îêD”Ã„!$á't\’XŞ×z{Åo¤¢ ÆcMy=3JÓÖ–ıFN”ëúéƒJîR»—•ôòDìŒÖòÁ1|»8ø)
±r”sÏĞí=¡(cß÷Iu]ÙD°C²ÒpC0á²E¼£ş{Ïª¢ğÄZnú÷Àç?+Ú±½vÓÉ¦=<‘¯PÎr>;içvG‚`÷'DåØ…®Ö]8 ‡RBÙ/E×¡ÆÉwµn€êu¦æÕì±™…]f~‘Ûò5@°¤Ív¸(°‹JÒ)ëBŠ¼Ó(­D0á™›®‘	ssé–…3ÉÎ#O_L(Lû{€OÍ56+ùÎø8Ò¯äqêĞe!\¢:×˜p\d¶[Àna}ˆ{F´ÛÕô™y‹Wîå@t›o»—¸Î	î‡ÜŠ#dEj¦¿c¨ôùéÉÈ“s&Ë2pf/šˆÓİ“àU¯PRvÊ¢ŸËoq8¿põ„@u‘ÿc/«…‹V4¯Î¯¦¨6²? º4ô ¿×x CMÎç¿ ßéĞÛÌŠÁ´c¤	}t;½…®÷Ú¾Í(\¾ßj‘/¯-–X$õšÈÚÃ/½íft2>¹Ì†WöGƒò‹h±ùBlãêåøìU:`'Cg…ò[dÏm·Y°Šú¢…ú,dx[°ç€+»ò„¸áˆtX“Q}g£" .…p<(Aóe%ê¹&$æ1×_ÚÑI3	ìÍ|Pìg"¨öˆâ, &jİôN1‰±Š0
ëoönyöLÉ²›	×ùsğ^Œèò+‹Œ\ÇWÓi:.DËÈA&cR¤` _eÄv1.•ÓÆ_=Èãà¾`$ã•ÍlÏà.ÇÖ©è’{-‘Wó0¾ÄrY0£Zÿø› şşyÚ¿4b#‹`a¯•É‰—@Ü0j!Ã#CH 
Å|Œ„^>
ÿ“>Ô¡?â÷ı¨™à€(ë—Ëç
mEE	´…6¹¨ ­›(º†%dfR÷•çÅğ_Pş$Sj’îpé2¡Nrds6¡ç;léQ-=½Ë;YÂk#2Üö–£}À‘CÍé'V%)äÍ¤¿²C¡xZãîè¡uàæ ä_Œ}ùÃÑ]\íî&'Ihg	Õª_c´VkÂÊ­*\Qç§?–oİ„'Vy™OyÍÂ‚Üì*SõÊÆ’aæw|Ø¼›wn²8í¬öXàêŠ>QÛé7SààkáNÙÀ^şQN®’U…(?,(Hy©k:rqN}ªï¦îÚ<’øQéü &ÊõHĞ–Äå.ÙÚ2YœÓ>Ğà=İ<Uğ]÷cH®³_Ï$n¥¥ö¸ñ%Wt¦äù5utèï¶g¢ê_˜KÔKJÓ¥§¹¤ĞÕƒnªÍ¨¦‚²ÑÌü>`L9“hN:¡ób¤WWŞ üY;TÕš‰\t¡sİ”ÂGN®ÖöUtÆí'´:=‡‹HfkjAıOré`Şˆ7¼cuâ~Şõ( »|,¼uÃÀS€¦ZV 'â‡Vj*Ër•1	«-ª±6‘jşMOßÖÏŞ<ÉØt°ãMSôQL¶W¯ë·±¦Ç†|lë?ïÁ8ÈU¤ ã%üĞmïùò$®æm(•]KL_¨ö¾YÆw“ÍÚåÒ`Ìö›Y) ÑÜª¼	Qµ³‘×F’ì4=G•PHxv%%ş¹â•ÖŞÜ™-¼:ã`¾çYÌ5vo¢ğ†éî“…QQê¿ëá 7Éô¥âæâ‰Ï¤òeá1®XCıI]>¶ÄVN÷§!2rübkã!B«Ä×_ß¶ñF©ówåÅPUÀÍª‘¸ÎË¼TÒ6Äó~æÆ
˜ŸÕÙN•V-Åêã€n‡½ŞhãõSã3ñX,2ø›ª5ê—IR“†ƒèşjDŒäq‡Ÿâ( °±¨!!P;¿&¦Š~Ñ.—t<“•ˆ¿­ˆVI©Qö¸¿Ò:BgÑaÑ%Gô7ã£ƒÀ‰?ÍØ$*NÑì*gĞ	ŸÓÜKÕA„ùºÕsğH“¬Ì‘ö÷Ôe’<á¬ßĞÃğ‚?<bF}“â Y_>V?ÄÆ.ß5ñ«’€·œIR27#æˆ	¯ ”ßÙ-jèpåÕvµ‡üß›ÔÀ¥µ Y[KtTVO‹#L<J{‡¨Fy~ÉfU‹ ÕZêär¢›‹KĞŞD™ÄŠ¸-ƒhhá9d"&NÚ>Tîxë«¤¤kC„fÀ¦‰äŒ(Ø¨ d˜_nİã>Ğ†[qhïn‡[×Cë°t-9Ö\Àz|âÆ7z¾<²»œ!5$É0şÈÛÒ‹ÎÚètE:~ß»t!C£A;!
wx¹lh¿®ûg)	CM0‚Üv²ô*ŒzA<5€¿àmÄ±½DÜ{¡'œ€SˆgïO†ÑŒÜAo~s(N¤é]UğQª…‚¦ønêí¢¤|¿$Ê‹®©—âjqù]Â´ÓŸÿí)•!ŒƒmB.	ô¨Õ}×[ˆ%›)
>l2‹F¦‹ŠR"':e’‘$pÌ1ƒ/áÉÆ£H”@—íÓ1|¨Å™U]û,„qç„.(„r“-– ‘¹ÿäG}^üEáB4ù}«Â¬heäÈÒ°Ö9æ‘GßMxÎWÇÕ¬é?VÖ¦Ôe
y~ì·ddà DL_ƒÜç÷¸•ÒªîÈçœÄŠKQÿŒô«îFc~jâ!ğºšk®Ä½ˆqŸ|^Şû!ïâÓt’êé§'~ÑªVé€o¤şdŠ H"»¢.QNƒˆ;·æÚhW3}ƒ4ãà†«¤°Z4{tJ–İîãêú¼¹½ìåUäA(²¾êq¥Îeü	¾)"52‘<™§X÷4ÃL_àzÜlıZú;|Š¦QÀß°sâ9^u?Âz˜ß^ı‚6=êî~­ÍˆÑ‡·İ‹0€îÌ‹™ò^˜”åÒ‡@šË§2
,ÂP+bªØ9¸e"¸?ñd¤IßÎ¿ğ>Ï¯î£¬dKiÁ15%÷H¸^ÅÒÿA{¼Ôö…i/°ÄÔ2/1ÚG{¾?%’'Ç$Àyxf”ûä²> ğmèsF!OQ+lªÜ˜’—&;¹Ì¤#Æ¶tîˆ•?Š9½T%—¦è´Ï:ÁŒRbÂ¼Œ¢Úº›Uï´'øÑg$-üÕcïHÚƒ’-( |ÍV…ÚÑY¥fø™,’D”k‰+êì;>şxçÇC3—S¬C´³lÄ»oD|—ŸãŒæ~x1şìÜÍOãKct³•Cœ£>&T2„É‡`è."ã²Ú)[œÈ{Q>CCnËr€¶­Åk7à]DşÊt™3­¯Å6pp1£2j0U.>öÑ•¯·I	=ôœJ ø5Ú˜N×`†¸kË³Zé?öºÏ°³!²ÕkçìÌ<Ê"e!*èó›òñRÀÑû5q.¬K	Ò’ñ¹ö|ãìæî`ì£œºÀô\íë—a¤Á&‹ÄÉ|Odf°íòË7Bf‘1NgpårCçŠ[,,½è\ğ‹s·¹t“2Jø«¸°É(Şê„Ù5şO´ÑŒpùŞëp8¹Ø.HP‚–k‡JÍÍÚõ6b ­kGçÖœmxáı¿fÔ/Ù“‡‹·mVˆ§¹qow`ÂêWâ®O`§ÙLˆ\×eEBmuBÎ*g,&SÂ«Î8ŒğyÎû®S<í™1ˆ–>$Ã\«· |«Ql¬êŒtD4×vxª–™å½´åÌm6çªZbĞˆ›ş¥Í«ÌÙÙ6ûVI¡‚×Õ¦Ñ¿—Ùô*±×ÈÖTa¬'PÃî§Z-Õ­ÄHÃ2ŠG=#ŒOÆlt]b¶v'ØgÃ~˜ÀsZ‚‡Õc£¹£Ú‚ò?–ñÍ"Œ…©·ƒ 9#Ã|«ëÀÓ›pOäq üJq¿á;DŸa'ØÆD /ñS*Î©KKe6rŸìè¹d0Påf©Ú„¹{Ğİ™–›±şIøc„*s`Ìæ„s!6W3ª
/5Ì¢»ùÒOR5’çHz:PgŒw ıs¿Ãì¸'Ç4KÆó–â­]ˆÔVHˆùùÇñ„a’FÑŸ2_|óq…©›ª†?›$E@MĞ©
ºÎKöºíJ—û­Ûu'­¨·1È‘ƒ'nÖ›-.M¶ª'Ü Õj'åÌ!}æŞ},sÈ?Û
®¢­¨ÏkÌ.¾Ë—Â9•f…b,D²ILæ6’›È%û¿W?w.»Ğæ˜ÑæpÏŒ¯f9°)&å´C]f"¦F eÇœü ûå ½üÖ}jx4S­¤Òv€‹ï÷¬€Ê³eçöû¸¶97?†i¢ÍÌx&+J«MÄ)„\~[ñŒ+p2%i73"‘[a0ı[¯×€·Z¿õŠàùäÅâµ‘ëØÂ´l1Ó‡òÎıƒöÂÅf…Ä5Ûòr	Ñô®ô [	™f£·êş‰äÂ˜½mùJœïÔÑ‘Zc´š³>ß ÎÑt:ßüÅ¯Áúr`|ùE°E®«ZÑè&ıHlÙéÈ,Ló>°İ§Há(ejä‹;®lú&]	ñRPox¹Ëí’áøµT¾4CWËSƒa“»¤OÑUı*Ö5ßğÔVÈ‚:õ°3kq”¼„lQ>bw??OÛğ‹cO)å¡(iHr´Qå¾¨×s'!­¬›­­ˆe’º’V7õ)Ìùmˆå&ÿ;Sšû³ƒ *ŸF}6mG7d¼1ü¹Øsy<Hq‡ G ´Flíè³ú¯_F}Ã”|%	m¨¦¾TZæCõ÷Ç`_¦¸µJ„‡ºT¢©}Ááq“Ñ÷Ç~Ör½qÌVÒ—"œ	t4JÿˆgÑÊïqÅ+"é#²,NC}ÕÌ—×Ú2$òc¨ü…äSe F©à/Õ¼q\*õÏ¾ò_ä¨”‹ ©2ßØZF×%øˆäÓ¼òé]-Ã—\V£ÙCËÃ£ä‡s¼ÁĞ3òRtZ<Ğ¾jÃj•ïÆóÿ7T©¶[H[0/-İÍSóöÔégá5¶£Á®Ã1tCdök(H®*©]…NÁÎ)’I…”·j®IA¡d’bsGç<7lÂƒ»*<ãÊ_|æŒ$±Gÿêù@*‘°€5ì÷á~Êı¨p®™ftQÉÙòÃÍÚDK]=·…Çp'ÆN¬É·êJ1A…u6K¼¡Ş3u½/ÀàTì†šTTRUØËÍ²ûéÒ‘ƒq/¼î©w2É¤ú•¹Ì,³öD/šGÈŸÂoô¾½Â‘ËEî/8& :Ó/]Š>/YRç+¥çqJşi¢z#lşßvMø¬á…0ŞÔŒèFÍ¿ø¦>ø«ÙYÃ#çŞàl¡À=ĞËú$kC·§ æ¬hÂã£Ş	š`EÔßj´à20b¤L~•` M~f ø°¶tşbÍÉ?O!ö46NpŠªOJ?²‘İÂywua.yÄiKJíÑÉ<V“S	iÕ!°1 YF@P§‹°®Ô-Øü¥Ì›ÜˆTŠ0'$¤ä"âÿcÃšÆïÎì?	]7—|ÔAX90ˆ£ï*‰ˆ»Æ©ãˆÔü›Dz†
øsRşZ¾ûüZDéyˆİd ¦²©Ò0y3zgxæoá¤h¨O†)×œ¯sˆKùŞft@ŠN7"›ÿr"oÖšOÔ"ê6§4A°u^~"tY 0û+|ŞÈñï^°ôcÏ8knÄHßVNŞ›5¾¶"·4şÄ¦8<øÄIÊ®êA\ÉvÙ·hŞœP’¹Q‰pJf¡°0ÿÚ	_çÖºq}8ÏÈˆZæ/nG4÷pÁ<{¯Áø<X}ª¨ı‹	 _Şıo38Ç„ÃÑT<0U€x›ÛÍŠcSÁ­|zœñ{VOÀ…§‚oàêÂÄ#ï„Vâß'³É[´?\vœyíÓ¦À5aúZƒÄ•õè½ûâ+àØÒ[öICËDn^ÆX3xNÅ¦¬ĞÔg ©µ„âò˜N]”×¹¨dæÖö!_´$şIJòvT•:O}RÚØ ÛËæ¶˜	ÇVAO‘kºuwLIÑd•'åè¥[	H¬DñM³qträFôômrû^‰ÊÉ8°ƒï9Ş ŒÒXKX!X>ßö%³7ğ!%Üz'Ä<Ì"¥R½ÃÈq8z6Õ·¯–Ğ6 )À	±Œ¸kx1Õ­°ÆšÂŠoáºâïÌ‰rïPëØ—I3Éf{¹Ã¿#Šcî­–;ñ›tˆ».Q%œYé¢¹ËLÓŸˆæ½w—0ÆW{Ô§|?_Õb=!ô·*¦ÕßØI1ŞŒÎÿYM”Ğ#Şúşáª¯˜Ä¢a¿§å`§Ã„p‹Ğ£¥›;†JúòCä£;ıXåşX‚‰' õW)áŒ„é¯~3; ˜ëV/:aÍ¼'¬ÛØå‡„ğ<Úw;­=¡·kw(­¶ˆ¹œÆÔ¨mO9PL‰ñ½ó<« µ©Áºt4Wªi}X3m%E.ê©u°/ƒp'<ï{,NPÍlà“iB} <£Dä³Ä8ÕH¿:~.¶LÀºâĞÑ—öÂ½%ÍéÚçêw°×.^Sâ…úî.fµîüU5Œu¦ÕÆØÏƒçIoIÛVøÕQqNÑœ†gbq1¬-™…{²×Q;¿©x=4^9á
T"Ê)‰uÕÅûj1$²œTØŞ¢N~ši,W¶ËzvÛê˜”ß«VR
	zK×$6’Ş9Ç‡gåvC´¼ÈbL¦,[^ŠRgu1ßcw˜R+2;T–ı2ÅD6^AÔWë$Ó´Á›T¾¢AONŒÔm×2#&µW¡‰pÄÈ¼	?Ôb-ğ«BËÂSlnı ç£H:~c:ßÑRg%÷¶XésTV¯_bxê¶™ÿÒe\ïÿ)N[µzß‡]s*ªß7”jeùà²£#)_ß›Š¥,ÏmÒäËbIv¥‡qq°ixğ#3cın5İPiÒPı$ÕèÖ´¡¹… 	æW$Ip$)eš È¸¸ÀÒšHŸµâ^Svÿqô5%õë–(ôUGØÿ{°ßØ›K0?Á%˜:w•
üLÂÏ‹€û
1zù¾ìSı¨nœìûvº(ŠwÙ‰Ã½¤ĞÜGÉ"G9ŸFÚ(/£ÿ¼0ôù†"”ÄTÈÓDh`Çé ]ßÕ%ğNëÒ–¶è¨0Ğ9fç)ê©0´Èu$îu¨³0&*àLä©•yG#0.3«>ó8òTúàš£+Å¶Şn ¸Æg‚p0àı#¢Pcê1ßÊ†ÎÖÑ=ğ{ß¡ºîª@œ®à’gïüYÍ•f|‰C§Ş¨ÁeÏ¤	iúvÚïw~Ş4b¾İN(CLKÃútçWB"c&¤t¬_úß^ÊBÒ”;í,r'F q|qdëa/Ğ98ÿ”œo¾D
®‰â»]‹1¸—\:îƒ>“ØD2F“«ÃOéğá„DİóÇÕŠççõ|W©­·Ô;Ÿ–MD[¸´’ÃÑ£Aü·1ef”4aJë©QT»lYNR€ã®½
%ÆÈˆt€Â°Ğı˜é2`a"Rp˜;;{,9dˆfŸÇ™&T@OŠ[*R&ÛRØyà™]øŞ®âMÓ|†”ŸLíƒİŠĞÌ$6¿`»L=c@ÜZÜß¡jñ±2b|'Â¬›d‡ıbAeÖ^©úôz°¥»ÂÏü	ÁíÀMË0Š+ÙSˆe­c˜ÕÆAê5ùwÌ	@èŞ’×BOSª9uÁò¡Ì ¿ˆiû#õ˜TsM¦¥Şùo ¢aqèı[¤®©ç.òÙ£Ù¢jØÑµY’<ŸGßEcó+PâÇFLû¸?Sl±ägÊĞ!ò	‡]ÅóÙï«ë®?Ş€±+†l™ã§µ§¯ì€&og„KKÙeÃå°‘°x2Ëç_Œåoå¯Ñ›ıÑWRÙš[h!!4çÆ'¯Ş4ßF8ÎÒ„¹º8çiË's™~ç&ÅeS\YÔı.HˆĞ'ĞÜZQ9J_á–Šê!…‡·}qş°,úÉ¥kÄjj‰ü
‚üêVI#µk¾¯ïæÆ¥h¸Ğ4NU=zwĞqÛ-ë÷®ƒ'ÔÇÅÿkÁ¢7#|Ø$†¯-îÚ˜”s„á)ùş|SšÇ‚Ç¢>Ùš=ÈÙ MJ!»€Úob½…’áˆÃ5¯)É=Q²Q«NÜ§ºb,Ñ¸Á^îÖÔ€:I³²cyË	Ù©VÜò«+~Ä“õàş9wj¼S3R»w9sã¯ÚXÖª&GÚ¯¥GÖ¿9¤d¨–cèŸ>ñaû*z[™\ê3Ø+°Ú€øfíZÕ âDf^6Í•gŒ¼èğáº¿ÂŠ‘dxØQ£$Æ|œÚ$K§w[–]7Mo³
z¬o 4øÃEœì™E¿ññ`®œoàv´‰¯¢öòødóEÈO˜+[ÚEYXÀÙn#šÔœ…UãJƒG™Ùa!ä|q ¹6£•W"}ƒıŞÀ¼®ÂÇ·³€UDŞü²…k±·SÌ%-‘şÓi´tbU±f]Œê¤3ÈÈgÆ‡Tª‘¹(EÒ\s¯¾š7cPéKQÕ½=ÂÖ°	¦"YËgwîº?¹ñj*ê
d¢&Êñ(áäŠše†R× ´]Î$Ò‹/e;ği"(Àz?µc÷ï³Ô D3âÎ©Ş×ïÙ·ñ£b¬31'P  Ûv¾éÛÀ ƒË€¬§ã±Ägû    YZ