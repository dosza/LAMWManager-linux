#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="899767966"
MD5="cd8573ac15f517a0e79042c2d676055e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20372"
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
	echo Date of packaging: Sat Dec 21 14:48:01 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿOT] ¼}•ÀJFœÄÿ.»á_jg*‡8¯Î°¦†O¥tÏ”¬RD< \[RŞ ÏƒÉ’b1@7uÖ[Ô¬·åuKZ(("¥'FàÕ/o\&	—~V½cC(úHıf—ràŞP£í xz°p¶šé†æbì_†u-@u{Ñ–bÂHˆ©Kõ)L$œ$­ªóîëß”©ê§Îó^Fƒå°U´Vi_”×WbğƒpT˜Â(¹»b“d˜£A¦üz_!SÌ–WJ6¦\¾"#Ââ­@°h¡F¿-îÿnĞîerçå1:U¨Šg£yp7¸LAuÇé›¥[±Í]!ÔÕèŞEò3àöyíÏÃiçÿ6ÅÊ”3P?Œëğ KqÎ$8r Èü€–Qmôò4Ñ›ZÈŠ”}FzÈE@m¼ï2ñçË›Ç“Î-¼„¥&AÉdÂó*Šƒˆ§øubdJMÉÜKr«¢ş…C€-4±-iz\AôôwÙ»ó{úgÅªh“$ƒˆqÙ6¦%²¯Xé%!7”xoŞlÅİ%ÕQÜ¾ôóÆY SòaDù%9WqÁóÿ±pÂÆbò=šæ¿M¢”q¶aª8ª!æ‡N“îÙ´¦ûFY>B¬ÖËş’ÍŠÀwñÜ\‰Ë£ñ#Œ’§44I.qÂ¼úË“ãHD¦³`xí)WcjÅµYÍD;ü#İJ(sù:BI›Iu›®•‡@¢ãVbóRÈí¿¾§ò¾ğ“ú'ã(­py»7¥Õr#y\Ëco‹rHie“z(/á””4
n4’ïÇü ¤5‘{—hÕ¢'ğ4¥Hœ¾|9çQ¼GéÜªTwP§§ú†›°º&(ßó?v(‘Â°aff«Œ¢fS'6’œÂ–¶’ùGeƒ[Ólç3$ÀîŸl« o’»„½`æ“ÖËi¿4•æù‰U6ñ®!Q¯^%MÛ®!¿¢õÀ/(›Œ%F_ï$‹@:¤…[(aT²Ü©Å†nRCjoüŸFÓ£ÿU²èÊ{=>‡?4˜ú—ÅÅn*úırÙø.8§Gúù»èšã'RÊóËü7nòXÒYŒ7I,“s+E-pêDH˜E]ş[ŠbÁ™ˆşÜÓÿî]Sãò8·/ÕW[ï»2ŠÅß7aªd¾Üá-Èm7•´%µM¼³»c8P‹@d&æH|¼Ó±­¿Ò-ˆ@F×!ºu±Ní/Ç­H^AË«p#fkÂËs¾Ã'?¬Í_Ü[Ã¶0ƒ¬Bo„¬-UØ%¾Âs%o©=vËöúÅ…°;‰|ß>¿ğfáµ1Õ4VÂôFJ¶‚i&)½ó…Á×ã:ÿ´õ»ùıe})Sg‡rsÍ—ÓåŠ} Êèÿ¾-D}ƒ~6»¿ìú@ÚŞK
ı²Ğ¾cåäûn:›Ñ0­ï,~JÀp>¡ò ÷KíW–¬òŒ<m»í¡MÃ¸¨¿…ìcÈl=±©õŞoqÌÈd®.Ï"„¨3NĞ>Ùi.‰ÇÛ
êÂ¤ˆd‚"êó·‰|½¹¶áÌ`^A]bßë	W¦ĞwTê»ÕŞ=0>ä¾û<PÊ[³í¤‹]"•áÃk¸ê5³°q€•ñ EÛA*Ãp–‡…ùÿ±”û2‡ØQ½•Oâ?áÚƒ) ò¥¸ÇEÿÂˆc›“z0ŸSúA€ˆš¤ì–Ê9Âg†Za×§Po;îß'@ó0˜—EÚºßîÙ)ø%[äĞ*fşä¹ÆêÔ Ú—lÅ +AbâÈí¶ª€º‘¦kÊD2_üÊ~ùY É–dm¶ñ_b…øœ­ì©£e`ğ¼w¼]½"ò«³µhÂ•_ÌMP›U¥ã6ŸA†;IŞ´<~}ñ~fµØ¯Óş¤ğKÿÛ¸”Õa°²)-ü)]„ôXEc.¢Ãâñ):¿-¾œ²Ê|Â¢ÈØ'~î·~|k÷cä>^40ƒgÈÃqùÊfO!¢\XRÛ‰ÏpÇl½Sô<ºC_"/Ÿw^l´µD…R¡@–.¨ºFÕÏ-,·{¦³H\‡+\YÜ÷¡8z) nbœVw®‚@óÍ£›œyşEw, 7<V÷X^£ĞU?SK:!*øt«%>ğëCê¬íS<@É†Ze çã1le
çOøÀàÍ'¤çéµğc®D¡œ@£¹¦Ó,á6{¥@/eù@Ñ³[Ï ¸ÃƒÙt¡½«-ÉõëH	lshª_ÕVÚWO&GMVÆp·fŠŠºM3WL<;úá©²réi´åÿÅíãÖ€‚ÒñïÒ{÷QŒî0ÜB‘¿ëæd~¹ıO‘Ò‰»´5Y{ôkB¨0ÏÙ¨7¨>¤ÀX'œş7+;×ZKÛí1o#`eÒa¿6ºÖ±L½u>%*ìK©Yö0¢ƒ%ñlém¤<eÇÒÌˆ™:†1õÕ–äeYg˜$¥*5A†È¸˜èn3ÃB×æÀˆxúğºJfhë„Oö0á—4ú„ã5\‰5¥á ëïAÚ$á”ìæK÷âÍhR yn«áªäØñê	³É—½â„+q)“«°?§8C-°{¬­äBëX-÷‚n:úŒ÷Ç´Ùtcœ×æ”búèTH:ƒ7AñàÏèo{ÊO™€Å¤k&8î^>j¶6§âo˜!smLÛØXOkàööß“U¼Eû½ù|6,¼uü,’XHAVÃjg¦ç™ö×¹fÚb?mş üãA•Ş(Õ¼vƒëi8‚l‹û–%8F!Íˆ\‰¦4ZÍ]¿Ù¨[\ÃFA0š¢•ÿâ¯”ık j#&Ì#¾Mãßøœº?wa­7(9Ödy¶²—ºÂ´P™(¬dK‘z– ¹à±h:2ß	gcÃ´u30º_~‘ù ÆªG©w`äÃdÍ{¬ÏİLÀ_µf PSÑYØ•±ÅìÚ³~O•5~· .SÂ’ZíT0mÜúŠ¼Ôóï‰ô
;î¬Lı;{_2È×oåLó“ÂÚr—L‡°^3ÿˆ­á[±ÿ'[!8›fZ¡È^oû£Ë¥øKLæU=Cx¡çÅ FêÈÑà´§›Úx;× G MÈ†@Ÿa1å]~¥õŒÑËOëv78L#w›ïr/òQ¿ĞÜ‚Tb^Ø‹Õ¥R2GºÀ—	k)şêŸN:ù˜ÁĞ`—1•_†o€:||PH_ñªùWİL¼‹P˜›¿ ‚åöÂí["c~RŸõÍ§Ïí^$´İ! ’¶A	¶£®§¸µß)qË]œåİº¿“çŒiÕ"wÑ–	%-m’×‡ÁÕög¢½Ÿú9Çîê.A9fû¹¹|Kâ‡8ãí&gAi[0&·â·Aµ!T˜ûŠk29–µı¹¶	z!áš†Ã=›ÁßÉP¸†ÜşKÃC§K:¼½à°/¡—â«¯Ø®©(]Pt¤½!rU4¹™Y2zjtÉA"îŒQ#!À5 ŒX„Ğx¤e{QuûÔl—ö6‰étÒŠÀŠQ;~$$½ç–Çñ%U‘sƒ„¾,À)ºˆ9Ş¡”âÑxç©Í£¥lòÃävkP‰%q8–bNî“i$îšÎ£W¶3s,©‘>ÍQx"½¯Ë±Ş–åd	ü$csƒÜì(±Å9”z.®…Ÿ<ËL~‡³«!u¾y¦£{¢õŞÛÒÚÛAÀÇ‹€#vu‡¸°Aİè[F½Lt`Ø"÷F@?•TUß·s)íÔ"Éh–Ğ~XÚåÉaG—¶ä5xÃ«í‰gº"´rúæõö£P*T ¦êê¨ßpü‰„=aI©’¿’ÒÊî`&/p.¬¸ê1/àq»ö[Ô5f‘İF‘5æzL(j5t#·Êˆ^ØÊWì¼­•Z™Ú^‡{8r¹:U¶[”™3æë‰ ßÎÁMeº¦;µ€Sñ¥i}¼>Ñ^‚~ ¾Ašjÿ·wù_;Il°‰Î}Á>Îz4öF¦¿ÂK“èp¸!ïÖÄÉòU zJî=
Ræ‘·y±á ÔóÔˆ³E4GÊi¾Üë9©É‹‚"p§V|ìºrÈPô_Ê÷›ˆIÜJŸòÀ£G B!éà÷:A»^[R— qîGËıíãsÔ}ÊˆamukéÒú‹°yJŸuĞ9Ûá›bJjZÒÔ1§$Ç‡ƒRm²¦÷‡[:ïõ˜%vW3ªZ"À´'bæI—3ës¼s."î¼ˆ²ÓÌ'ÓR4€w~>Ì-aó?*°Ğà)îZÁÀ—rõ»°Ä-‘:XÉÔ¶ƒ–Ã:î|ÓˆŞƒB¾­À3ÿ¡ó¶ûŠ¡†òÚY¨cQP¸òAŞ¢ÁºøˆÀK7Q˜ü!-ø`sU½FıQŞ‘?Gd¾şuy÷’íÅIBd·bl‚•ÔLkr'I\Õ;[)ë«RÁÅ(ãÛãÌœ=Á4’şı7{ml]qtj/–OO¨t¨i² \W.3ëu‰&t’N~ÚzÉ4Úl¼,Y½ãå¤–A`^¨¸lÅŞ¿vğK°a˜eã•\˜‰F¶B>ª(Üz™dXğd‰‰Mû/W,NŸbÇª£•jKÁÇÑ{wd0&T°ŞCq»Y=SÒíF”ÜKVŸ1#fuaËØÛX•¯‘iÏe·;¿K§ì,pï”³oÀYÊ³Ñ(Âö>`ì©ğç		›¶şSş7Úÿ¢jˆ—yÏtÇg ìÒz‹,GÄS=\œÿµ*ÉIIõA]vÀI ñÁ/º¸f	m.Ğ²97êz Ù™°Ğ DÑò1Å& ¶‘Å²¿L ”öŸ%ïub@]t«ÃZ{ó¤,&ü|î±!/Eõœ±Y¹’ñOÔ¾±Y×NÁ%ëÔ¿ôÖfÇ"±¿S–Y8'ĞH~4œ‚,xíÎÔÜÂm¨TÇZäµ×ïÑxh6¬¡~õŸîo=¦öÕØ¤¤nrŞ›üÍöw	ù§ôĞÊø£ätì…ÓÑ´†€Ù /x
¾wƒa;:r¸\M!rñÙ`[ì[… óTi+6¶£eBHé¤w‰'Tvukíÿ"O¦'š±+®Mf–Í^	xÈíŸÈ¿ºñ5½r=/m[U“WuZ3ä.ã¾à¨éú`fy$ÇeŸò¡=;Ü¾ /D¾@† ÏoŞ}d–Ò*ƒq1ó¦—°Fº>¯ı¡8ôäA½”bpñí[‘I,›Š""T$ò)L#å@‹®33ıOJ\elnólc²¹ßıÌ<‹\t~bìG[^J™ä’$ãvÎ;Å»à«:Í‰Ú€’’BUğ^¦EŒA¶pSİ¿½%öuµ´wÂXK6½·~\ç{k	&“bkm3-TòïB5]€,HQÀºY´‘í°éBd2MìES+Í„ÁYF|÷êÇÏ_6—™Ş¤LØnPåhÚ/qCaMv¼­Ø˜¬‘O
ÚZÜv1Ï$NîÑ|úŞê¤°&"9ÌÁqòXûO£~Lº„Tpíä-ÅDL–vñâ“ŸâÓ½²=Af˜)ØˆnÄÏ gƒ”—”Á]™ªåûğàéu^†™]áMòaym[ ‘DåøA,‰–æ3oWk5ìª5®Õ¬ĞÇ¤$Aµ³5èçDğÈHöè(íˆD¿š™BFíŞm© ïóâ•ğõªæ.bp@ìÑuŸº±ZGÁEób¥Ë'Yrî¦…•DÉ?Ñ¦‹àäAËÏ?0W¼n	 Ä8£)«ülrA€Ëk;Z¬dØª£¶'‰â<Y?+›GÿjBí„9cÅs«è?š¡O»â?ôD§iZpó<(^TÏñ¤‚C$CÚtmSCÁúÑ®@7Ì¼° j#Ù5 aÆ*[KDšµ«œ+~…OxãNşÊ—ı-ÏhzTTûnAç·«æ–˜£;¬¾2Í?oA
©Bsæê×f†İfañY%l°dïQùî×ûäG¯0qÃz‹cŞ™”fÔßÅäœKOI¸6ñ›û«¸û`8=nÇùàã¦ù]e<ˆ*¼ŸË38Ş	s®ŒT‘«oõ‘)8•·ZgÃK­Ğ6N
X¿œ,pp­5$k<97KpÇçÃO²Óób„s'q¼æĞ†eKZíı,†`zV†ĞÁß§lØ0íóÕ~—m$[ ´H¼mRŒ@ëò±0â¸bÒJWÅMfJ#ğw˜!÷.jå¡ÔAÚ5Û ˆK`‰	Ù÷)ĞIàß‡ÅâgŞÙòänºó¶qôe1=Ãé± 8,÷¹Ä~#ï+ö©[aŒ•¥a«™ıq7œÌì,ƒ7ËgwUğÑ¡Çºi§z«’ l ÉêîpŒ¹öçkå†S¶ÖH˜lüõ°ÍE±¯I¬åúc™Mtûy'B–ÅqZ‰J¹ôlEùÓâ9_>u»ÕÔ_ıò†^ßÛŞ¶™I
ÿJfÈeSÔ!.O»İ²ÑŠ´"ÉL’}Åôaõh±¼©|W4·˜šó:‹.k£»pª§qé	Ğ+‡·z"ñ‹—Ïã’Mtàl*Ä0—©{*#”1‹Şu‰‘Ì hEo€ÙïÌ¼ÄdZŒÒuõv«¶‚n¾s!^>¼qò(Be—c•0={>À›È¶3¹K¹;8²qîz`xœ[0+æß™ 'z`LiíÎ¯Ë? BÀ[/;|ŒKæÕfÇø~}ÿ\Ç,àõİ	ññ,¨ÅŞkv›€t×Ïvß»2˜ª#Yl´«x¯mèƒ¾İ´—éˆ,äpddQÚ2Ü5Ìï7›<Ñˆ×çÇ.}xzâNğÖ¼}ê8d€Ç5z bõšÉep«…ÎZP>C”è±`æ¤Ênş)$8áß&kµ5¨6‘¯dDâf6êÇ@Fù •E'	ß˜}¾' ¢KÎ{·ƒP0j)¬/úºïS~3¡8+‹£H«~÷ªü
­ƒc¹Q ƒo“˜HÚŠ6yú ìŒ“ŸEÔÈØÛ[¶ãL`=@‹’xÌÀGNjåÖt¼øà¥G²ºÂÃx®ÒùT<ø-–’{‰ªéà~~i%æMÇhüœ+[^Èöö„@S@ÌÃæcCRUÙ›u§3}dEÕ®ı‘×v zovŠ(õ•m¤)^]K×ÄÁ8u®‘·µ³ğÊW½ÖÆrXË]µmø¹Câ”[,•Ø8'zEx„öÌ|Şqêw(¹R¡I¤”Fêc8p¼SQ8¨üØØ%§
fB|¬}­Ä¶~K,f~ÖÀù˜êòÑ–E}4¤Ò©~æ–Ñ6ğ§l'X”ú5 8bÖŞnà{¸»a6÷£l½Fğcë°ŞÕëÛ'í÷†¹Çğ%9RÉóÍ¡5¹µØ°*÷†8ã2Ã9©a#Ğ‹¹Â;w~‹n`U„¼_|½±”HaQATk}Á(Œ¾ d¾ì²•ÁJ¼¢ÓË¦g*@'N„mßK;<UŸ{æ^PS-3#PJ®¯)i;vh%n¶mÅæÄáÈÓ8¢×XUöâİá|„±¡{ğ<çi¢]¦Hhm“†én;Ş-,“×ıè¢[~‡«±ÇÛâF›3sƒ{L"û'BÉú—œÉvl×àé–ÿ[ü/+S»Ìë^t~sÃJ@‰²#íê)şr¬I ¬†cPS"áÂ' o”¸aÍüò1^3ù]ö:ô6‰Ë_æ4§ÇÉ†+iÄ2ˆäB£üÅè×¥9?é0HUñí`bªxè=*ª‚Îú¢ $ü„ Û²á·ãCÏISr†nÜïŠNûè?½14§ÓKc¥XêëXÈXÛ–ğŠÿ­Wj’Û*+oÍ*‚ªı÷ÓäãˆÒ©˜Ãw„´m5ÆVÅ¬ª;Å¥[÷UM—¤À¸’wŸ¦¼ğ`¢cUMÁUÖu?NÌ³_.®¾l—pBBô´ß4éÎ‡ 3Ëüº#n©çÆàæëüR+äÎ´æ™°Â«ÛÅŞ•ÉêIƒÿ¥ÒN§b»¸îD”›ı–jáj€F Ì“Jd[€×Õ¡f^	kÈÁÏôˆ"Œ½7Ğ¬íô¡ZÇ~|AÚ5«?ªŒù,è§7Ndø‘18Ş‚ÍYÂÇÚ‘úÌjÅò€å†f€Œ¿æºİË’tz}²«Â•:[“yñ¯ò!šÈä<([f|ÎL"u-µæ@Cøùğxœtœ´6Ä¼†d£(éi÷Ì‹¢)-ß¸U»ÒaŞzø4t‹…ˆFñ¨uKÏbİ;ñ›BHıı‘bÈú\ æù§å×íıÙ‚PqÎÿfaĞ³øgk%.ª€Ş&x>ol‡C7.v±NGâÜˆáö«´#É°¼,šòfˆ­àÃÛ´V’Œ{tv7JkGøÕ(3ï‚ff›iLeƒ“ûxšÛwŠÍÄ‡:ÖĞ,xpŞ€S]4±T³1·şY¼ùå]é¯ÏÊ×ã{åB3ÀEcìÑGk‡ˆœÙEh¸hşİe*¶„¿ÄNE…e>:®m¯”NUá1Ûc•6Ïµ>¦SB÷†'dŒGˆTµ&½˜äs±
†™‘ÿôfÎSqœmv/I@úÔ—#B®è¨o4GŞ¹„@şqÖnËÑøeg¡8$ÊkÉ%’÷â3Xw<äcÔ)˜—:|Õä¨ªü!G‹´’œ’)L…ñ— W8qGáøğ7ı#²ŞÇT™¤Éñ(.
ğ{€ö§,÷…o¢‡B4‚K©âøƒ²4}Ò¬ü'G_Rœ×‡æ–e¹*ùÿ°Ló1Ü5ØM}8Ó	âÔÿ²NŒ¦½OËe•DøÚÑáùç¤+ïô6áŞ«ÿ<Jk·|øº—£‘ÏLàÊ-oÊrÒ­ó¿±óÑ^$”ZL@áÙàÜLDsòß
Ô¿hr3“rÒš}5ÜIÍıIœaÓmo@!àÜ¨!8Ö OƒÂQ÷Z¶ø7Ì¾Ø„ãMÔh=u°õ¸hœ)sšGØå*daí2ÜŸ´sÎá`s*©œP×¬×ƒ³kÕ ­«DÙ÷—CŞD|Ü0·El\Y:°A&D9Š÷­h÷zçåA…¿U†w“Û)«\ü®\«öëMØNµK¸|D»:JÎ ´­l#$´‰;§{ïÉ%[Nf;HYa\™NÕ„àDsºğg~ƒˆ†‹¬êxO+8¥C@èzEiv¯>—ÛNé–I4{ôIè"{rrÀÇBxì®¶şÿúÜYæòÉÿ%«7lõ˜B,_¢ûáÎâc…º)Óÿ~ÊÖ’71v£™>SXÙ$sZÛvY¾PR§(Fëtü#¬•-°£Á)”ÑìŠÄûÙÏßµšÎÎq<ÒƒrªRÂW­RöÀ½ËØŠL®¬Ù}æ*UÖ8+x–”¹ˆ£g2…¿yOöwl¿H“—|ïÛÓ+öWÍ µö;a(xÍ˜s.Ş—à›5ÇH¬,àgy–iX÷Z!Å~«„@“Àßá~¸ñÒ[ÜµŞ™€«ÿŒŠ_/òO/pÑ¨/É/{8X9{¥qÛ§YJ%÷OÃA?$-Úã|¹«Ì7m…4L€O+ÒÆŞêÚ!Ä»ñœ$ÉË3ä¦¶Òí˜­ı¿µ…¾é‘í5íìrŸpKğ*Ó
[çà;nH#ò40-/»bJ¤Ndù_'†“ [ãI™ÙçøÊ!{ºfQ£‰-$eL)°¬Z7øiÕ‰w*I|ºªÕëÍNŒ6«0 ğ’Ú`ÉÔıŞs‚æ{f‘ˆÔ¿âf•‹8XÈaLZäÌ^ä!0"D2a£¶¥ß”è¬xõd°Í˜¦¬GÓ\äv]›s^CèÕØíÅ®½~À`q¬Ÿ}Lr
 2«ŠAîOŠ:7±}jÕ¹‚•Ÿõµ\ârÀ«ü˜áÇqËC©¼e2ŠƒÊkÇI¥ÿŸÕ¶H-ÌÁîµó-]w´Òè—h(ÖŸVGÎ¼8$±®ÕW!ŒmáákµkT³÷…5Šœï§[ô*Ç¹aõ]]ÿŠÄrÒ1kÁ–y(T…«µ[õšÊd-ÄÏÃğ„ë[ TÑh)ÊÑÿïjKÁËæàFÉƒ#nÜä´QEóSY-GH‹mk*°«é°æ…Ò~¼ŸEñ­F\y÷»½{G­ñ¥ŸP¾À´ï4!hÈ¢5GÁ«F¤Ak˜ğR?°	'ó9†|KÓcˆÌD²)à¶¤Ò{÷—¼%£5õ½½iE(8ïH0T©Úä˜N`L¹O¯~CfË;¿÷ƒàİ2m²1«Ún 3³ÔNì7wnTWÙ’ˆç’¿ÈÁŞ’ßõBµJ¶´É™I7/¦`•[ÍC•t ’Ö
­WõĞ	´›\o¢Búùõ€ˆLä|=ê¡fX>/„¨n1¥,vK7Ùp—ÄB¼$Ãñáâ5D¡@wT™ï‚>İ–ÛzSÔ¯;*´Ú´wÖ5ª¡F92²­vô×v¸ŠõKŞSdı¼5­¾×Ñylyƒæh­YÀ¶s›°äñQµL¡ÒÌÅ×ÎßLI­—mÚùfåõ}[GšI™Á¶´¦V6öÃ2X·€xsÄ¸_ûÚ#È¨€À%í:‹…Ë··å»V€GıN=ºè%;EÍ¯yÁ¼xLd%n¯$µú ,3Ö%p³N¿ÙVÒ+…;|AİäqM6‡şåív”øxH¸Ùø'šüçßÎ+Œüjt“#$ö…I°¥4@p`¿nñj—&y±QôüÙÌaÍ$[V3­×¨2Ìİş•ŞnØ©-¼ƒƒ;C[ƒ^ıñ30j˜ó;şAfê,ÕÏPOò| l–sq°óÚQ’ŸõÇ´XÓåQĞê@$ÂV§î4ù#İ{áW*ÿÙä—€åW4ËD<D¦àQÍæp1jEirÓ×IQÅÕÛƒD[¶dÔcÊ˜/«ßdDIPö*şÂHL9ÔÍfU¯8äÒĞÂR0´g<ZàPM…_&ÛL|@ŒùL =_H &ÃæVŠ&0¾j®‚ÊCŒsL¼„öÆñ“ÅE;Úß"Ü+¡!¾P¶¥píµnë´^–~%$DêÚJí'O»£c”;Sí¿U?I?ØüéX².ûãÆs˜#ãGYÁä,b¡Yß0K(ic1­=¸#
DHØª¥™îòRX˜cH[è&é˜¿°P{ŞÃj<•kş3ƒD=—éë^ñ‚JN™ç+€tØ³ÿ&ñúÌ½BB–dó
Ë-±$é})—êÒN—¸"GnrìeŞ£D,4›ÑFÊÛ?³êmNşÖáâ¿¡V…ÇÊá4P~”ÑINöP´Ú|iïu„˜um7ùï=È‡œÜg~|!Îq³4ŸP=£¿s“io;àÒ°|&ÌPE™ü‚LÊØÉF/ª¶Âºù"â‡ÆºĞİÜi%Ã§HçXz“jáÃĞ‡ØÄZw{AN4Yª<Ë7•ó³yµ×‹2 62”Ò¶ÔI ¬ëÊ„JO0òë”äJåŒ6øliD ¢?1b±U!¦½Srá?ÆyÅõ²= Æ&E’,íBJDzdüú¢&{fZ63×":(@/#NeVİdÃ;?úA;ñ5î­¬'yZÃk·fã¢/ ¯ÂQL—˜]8p8½ÒÈøöm0f$+Ãu¯;Pc‰õ”8Wgö$0 »´m¡½¨™Œy€a·rÈuú)Ài*{b.kl+ô¦lì—ŞÓ}¬šF××ô÷>UüPÎ7*å˜§$¡SFa*I¤Êæ	mB¡wa}PV¶‹\$ø+Øfı¿ãD|â¸cá¡Ò#sØtí	Åp¶£Ë(¾ÀíEé·Œïİó}
À*éÛŠ(n¢bÛ"€LÌ‹«WÇWPîØûc8-_®4ó~DA±P*Ó‚<:€îá"÷ÍÆ±nDÏ;R˜“ €©Zîğo–)W\Ê“v‘DÓØh^yœ˜#âiåX`54ä$ØWíj_«¢ƒ"ìWìDn¨“Um'x`+²!!XÚÑù/£»®ìŒòqrQ£}ËA,-#¦k8GYÙ‡UTÜ³Í·š?Ù±	úmŒÄZFSp”¦ùm–á•`ğmŸBÀ'BÑNÚÔƒ31ù’’úù¢`¯5°ê>a(B'Jë[¬g«Šì?L¥nÏØÌ…æg~Ë]Jìë€H½ŠğûÆöÉ;5g,>’ÕÏÉrıA»‹Ç€¦§@G~‡^Å	ìo+‹;æİ/Î6‹÷9Ñ·UuÙ?ÁOqQĞy$	 
â~°’´ào³gedßÁ¼5
˜Õƒ„°Ïœî™oBmPø4©KÏ‹ïÖúß
d¢1Y¨ìAK¢&<ò~Ò%BEp®ë¯µğ$gßá–Lı“N5îéÃg!·+ ±ë ²F-âõ¨/Ÿ¯×ß;íÀIpÅ:@ğì¹Ğ¶ˆâü¨Û}^ä1Ç-Åjd&KßË¼ˆ¹ñÀÏ>‰•Ÿwämçbò‹Sğe+‡ª6'/î¦Ğ›a5ËìB§”ë	$š|È³MsÙOpÖ}úî‹Q“ì¶:Hì¯ï³µ„ã¼Ü
z’qÖøy½ZıJB}‚>mH:ãš¶qÛ¢t!»Œ¶w­Ÿo“<qFÚ|úÂ°/kŞóÈã%ÅjBGq§'WWÑinD¨†õÅ<%‰ÙO£@lÎĞÖ
u‹v Sİ5J×\˜jZ–c/üY·Xƒã&ZdjêçLD»é ıÙ-eO¦sô¯òAß\¥o%ıZİ3_*„Ç`©«`ãüø‚L‡o ^ñë§âãÚWmªg@²ÛËS4çtZP¬•´fÀ ìŒÿ”Sh“càƒ}Oç•ƒRÆ¶ÜvÓiùÚìæKŠX¼8´˜Şg@ãËD\oŞ'ê^Sfq u^@ÿõ˜G$Â¨¹bÍA¶^xÏDÂâÅ¼%î¹?Õâ0Ú;sEµû´iv)„ç^Â•/#Òs²å3`ÔèÅÜ_ >ş¿*ä#°eñ"ÔâWâ3bMˆ1`^v·rˆ2Ø¸lHÜ*	b/,ş<_×Piî*´™Ã·Ãe‚öuNİëA…Ñ{L.ñ/!y9¼:P
³G0Èø‘’êcy‹²5MÌÔÂ„;©J ¬P@¯T%YômÓiúŸ‹•DØ¦;µ‚=µ’øª6œ@´ø»š?010`xÅQÕBF¶UVõéä8“2sY?æÅ”Ëô¢ åLjOªQ&€Òg>xÛ¸¹}‰ùõ¥H†>({I0°®ƒ}×"Ø»áei“½=Ob¸ç<±g…~‡Q+™-ô(G¨ÅÚ»"°8ŠúøQÎËÑ9;•"8Ú¢è˜Õì*ìÙÏisfªç å$}Lp=*Ñ­’§Üñ™>®ñ ,~YŸÇ¥51j%fü¥¥Ó½¬	}a,òrùÆ
Òÿ0j½A'‘ç¬Ï^ç4SXh‚ivYÇ2•¿®#˜„ÒpÌÍÉº’CI\°TíNÂ,Õ´Ç8ÄÅ$çJhêÌ//cñJ7½d•D.¾1™®dº[ÙSí¥áÖ3QäÑk¤pÆ&•sQP®ÕâLˆ,º™yùÉş„Š£píÒ3cƒ×±VÒøHŒ3?G;)m%ÂĞC~0®_n ¤!.! 2o€"ÌCÛP¸¿A­o®@Çğæ·z›6õ[]‡	°¾î±¾o“hÜÚ~Q§&Mrº2¶g´Öû_ñ”íÔt…ZÈßßòÄç¹ãà!¸¹ú %ïı‚ĞXÆãGG4ß€Ù‰ò®ß±vÖLÛ®¥·¢kŒ¦>ñ"È|g¿ìé?íàY‚vÄGÕbÂ\oøî(#Ndù2eÓ2ü2ùœtÏt+ml8,435â26Ó\£²ÜS;\ör´Mv)şØ&[OÅMbsµö¢Š‡—ïƒ48(Ï)G#ˆHóÕhOß`şzŒ÷]”/B)šğGJ^–¹aNÿ¬ïHx²·ç‡ëYFB+(>¦½'ùÏ
(2ÁT·›5öwØÈ	”Vlƒ{Phu,ZÓ_Ëá‘œX
ÃsÊH#¿;^"Üƒ€ò1+júJHâ‹yØkv;:G}x*ããŸ¾eNTu"]¥î}…Ù2›×Ï\+áó½†3Î6Uï™¨oVdÆ3!2éÖPI{§7eì¦°ÉîF2§°y"ÍÁäƒIØe,7Ê§^ÖØˆÛWşM}¨ô ›Jİ¿;û¦òÓµyîÖK´İk»’²#¢"Ùï!i€„êyÉ"àBx•"3R†³Ï¨C8ª|[óü/h1ŸjXòfêv’9+Õü.âhåƒ´.W5üZ%‰QÚ J	ªÿ§òpşê©ˆ=$u6Rn×7ÄE_B¾Å‚ëğY
i~b™áB9ñ`îtPw£¼ÓF¦˜º	²A©JF¼’ciğrV“0Zá,£XVÖàÄw93 ’“h’Ë“3È´ídŸDÍ.¢O5¾A8«í˜…V‰mÑ%80ñ¦ŒNõ’éa¢JÇ!$òq×ük@ç…)–ĞÆˆ	Æmw¯Ø¼ln6rxgõC
§90ÒÇş"
SÒu½@œÌ(RÖÓoEvQwR¶ÔÜ fÉÒA„­ùÄxŞ-×’uI#YN¹ÖøåûL¿l	òúæÒçP!`!Üş0QOì]
LIWËjjŸF|±Gÿ¹ğc¢ñl#7Ú™úš‰JtZæ£•CR|ïÖ«>néöƒ“ÖÉ¿Ñp¥vBØŠ	¢‰´³ù+.ŒÂÅ[@¢x^â€†@§•â0¹†‚áÿ{#˜1æšÖñÉÎKYê¤À„½LeôdÉ¤»Er÷1à’£¶ò`ÿşµB"++¥Å)j—ĞI9=
N9ÿÇ”Müõ»Š¥eß×.?Î2¶`º[h†¿jËß‚Î2{×hào:¶ğĞ—lH-(ßÑ€œƒØ8}‚éVO3¦ÀAuß1¶ÊqNEa5&ò™Zˆ;]ÿËaûao±i‡5ÔŒ
„¡¯rmhıå¯¼K¥[ìRw÷GòÏVæSÀóRäÖ9²wS³¦ÙPÅAñõÉñõ$£)W	ÁàKx@ø¹¶9üÏ*°ÑãXîæn-ê‘‡-0êù±Ñ*äèfpJ=Ò@¢4Õ…‘{õ/Èâ°€¢/;ªë’JÙ&=£ï˜ì Öà;«ÈgF‡Ûá,Œ¡êTô>š/ËÀ}$y©(Ã©QD"PÇUÿaéªQ9p·<Î‚(¬H•#;JÊõÛŞ<½‰Ç«Û$Ã5¯²+Gê›)¸3 æ‡2&&¾Ï™>ÀRÖßØäïN4L«wUÕK”ël!™!
fª²& §$\É99mÖ„0$¬'¾ÌÇ8‚QïxAÔÌaXáı/Ù-‡
hÂÂ;DüN÷ri!Ğ\*|S¡ËKT7œ½s±DGŒ(ÛÈEµBÖMäÿºÊG-9q Û†]=«åÌ0ÕÌ_¦A»ÿb¤«Ê›mµ9ä¶{qkeÏ¾$B;…Rµn]Ñ”¢V¦µ+»
şÇß±”Gf‘æ~e“İµ<Ä„öÑ?mØûÑÙİîçe1dˆö1É-£g­ı¥zEàa;oõ¤«DkËÁe
©ºßÛÊ×£~mŸÅ– Å‹A]14
éum‰—Ycù¡“,˜I1Ìp4êı~20 ”!#İÆêÒƒdÇ1½åÏD‰­nó¤/_•ï¶zÀÏ4§ÌöK”@è¦7õ FÛL·|JËI°„MÊÌÚ¥$Ÿè*Áàİä—Q*¹[hƒKNÉû1\Ù3f€Èú8Om¢ÁP’Oò¼ŸqípéÇ®şÙjMV—1BîêÍá×Q–<dHÙ[´"ÃG 2QÔş3õÒù3î¦¡1Ñs^^A‹:²°BÆı¨‚ê©öÒG¾ä¾ÊyÙ£í:¿)ıR>ªÏÙvÇ“5İÉ˜M>²Ñğ‘%õšä
¥CòôÎr€ûê½ªà„MİXštš&¹ğÅ¢g?Nµ´ù±[Ë¯äƒĞÇ}·­iòºˆ‡ğy™ù¥#Å2¢æ4EÄŞ»mâw³»AÖ¦G&AÍŠuÖTØå©i˜ƒm’T,DğŒ?Æ5‘Âçı¹ÎàEaSÖs«yZm	k™QKóm¦ı˜&¯ª’ ÈÃ
¿ºY~	ùH¯–¨¥é™ZÃÕ°‹ö¼ÿ™KçîDdåpu,²¹gì:›çÙ²Ér„]²—\¨ó
‹Qd]j¦™x/‹DØ—/÷7ºãCcà­gôæ…¦èìÌ#nDEyaÀË¶ßwÙ†’‡êÆ³ÅDØÚÕ¼Í³äÒ(ÌêrÉEHYuÅ|bÃÿĞt°™ŞDÌ­KxØ]W‹g½( bSÅtúW*]¸²Óaj5-T›ª_A~pb&{'³GÚs¾IïßÇ.Öö?sˆ¬ªÏ”©k1 ›ºÛŸn¡½r•ƒ(ıÕÆ¤Vá
üÂ^ıWâ§$¸90·&ı‰:Ğ“ıÒ¦÷-q0Ö½f‡#Ùñ®ÚDÓ C~.:Ùºj·{$º«ÿ†2’¥î,/âtF	PÒZ°Û×1™ü†ñ×µDIı‘.ËQ¿¤ÜÎÏL ÿì”>nÕƒ@ó.LåcÍ½o"19V({¸NĞÍS|GÛX¢>h"”€Ÿ—ÍõÅR$•³œ!]ØùÒ2›KÉÕH8öÜÃ»KJ|ù&ÉeÑ¾ÄÇ¬EŞs(L  a!^=41‚\¤ÎArP•zR°*vèœñÉ«æ	e)Q¹õnV‰Ë¢H­+h”#ĞÅ2WMèLEKb§òÖ¡æt‚•qÍTÙp`[›@	Õz|ÉÉ¡ˆJ{¤AL8(õ±—$
âX —@e<#­·@óßò*[g(TÜ/ı"9=È7ùş‘ĞÚıâ¬ô>sk¸D'µ•Ğ|ï6õf‚Œşü|ôö4bÂ1‰Vè:\Ì‘x@Ú”Å¦ô9PMÄ!+z®Ï/² >ŒİÜ8€ùªfFS§bø|éá@Cm(ÇÎ°\ĞÕ5 $#êªÿŞ¬káˆ™“ş–€Eû§`¸\W›;`´½N1CR¹!ÉÄpVğà×€%mq0[K–Åàñ5\k^ÒRÜ®OÕO¨ÉãUa$äÉ×wĞQ+W¯	~%¢|a=cØ8½ó¢›¥İ/nĞõªû"šÊ[ØÑ@´§9æcŸ]mîZƒş¾ŸÄ)ßª´»¬“rñÖ_v%<4ü0Ö®¶C«`n±7s!¶ÀFÁ¸…ÑO–æ3Œ;'b5Ÿ>3ÚíVôoÛÓ
œSn>VDfMzë¥J¤qK	ôCdYêÕhã‘}Èğ_
)(¦¼qDS÷t…âšÕ¡ªU¢µOFhz‰/?}»68ÿTÿ0Aò*K—…%xW<Q–W!2Ÿa ÿñfÊ^ÂZ>*É$ºÈ2C/3yw-º†W€ñpà2°!t%0±éFZÇaõ×ƒöæ+`Rë-?Ê™1÷'G~ñóC;ìÙj_\lìÂ†ëßyªŠ7b&J,iÍ)”–Q2Gßd©VäÓ:‹[”IRÃ	Ñ±ıEºüıŒ¦5æ Z‚ÎÊ¯>B‹Ë)ká|‘ÏDÿg| ½w^ÃCSøü·0ƒÊO´šWŒºaÔl–X‰3g³©-?/‡_wpµNé- …£Å}¥Èy$ğŠ‡Æ‚úí„ÙÑ·J47t*Ü×—B½
ş¯Á|ıŸw4y	¨.Ş±ÑDæ*µÉ÷ĞÉ²º¼c0Ätgrô[Z|µÄCÈQ­ûDK¸‚!Êöµ¹V”–DØÃæ÷±
#yQpU9Cúg×"Ø³{HØ0']ı/\n]/+ìÀ¨ã4´òøk·¸º-z–|+ª–İúÅ-ÃÆ‡íà§oÿ^åÿbèNøì&]¤^ÿá’‡x-ä“¦@Ğ…}ÈÜ7F&ÊrBK
×›¤M¥Rõú·$pã× ‡û-ÙF°¢·Ş“eH/s¡_e>øòB6%F”Šöïş[[£°ª²®oN-×÷RLn™ğ¦ 0V3¾ogF2ùì².ñ<ĞBüæEí¼P Ìj:‚Tó1¾&œ–¡¨şÊìÔ,HH²Ğ>Ò*ÔÎİQ,QÚ9D5ç³ãiá*g¿6¸^‡éštW¸}ŸSb¼¨øòÍùlDŠÏŸÛ‚¶yš±|iFá§äê‰€·ÓìŸA»³(ÏvÂ>ÿû„Õª›òáürúØ¬cåı†ÖÕÒT¼Yjÿ=Ê=hkårª˜²È}øò5âÁ#|vó„†û5•-iÙŞ¢|'¡œ?Ó$×#8Œw½ó?KÃ|ÇkùÒoØX“tw¶–ık6Ry”~—Èw[*òH‰¢L¤7,Ò'v^ä’Lk8Â³•ó«e›òdÈ!Æ*µlÕğp:EA†©å‘¬]·µ{¡cDc‘…ŠÅĞ§Ì"¸ĞVƒv<…Ş%áÈÒÆ8¨}vx’ï#×ÈåÚè«x¶ìŒºÎ¤oeG3©@T,+ŞìÚõ5\ÂßÁT=ûŠ –À/ã„Pó&ğBP»Y´¦¼8ú…1#tÃypÍ~€vH¬¡bG$¾Ú=t]¡~Ã–ÙÍõ¼Ş½ÔÀ_Lv÷úo)9ÿØ¨‡³ŸÕêG·rÿÅTxÖ*Qïš=ÒTgãD,é'%7xV¥‡«óğ®¦‡¼±9éßcôLµ›À•D5Ê ÁÊ’"¦(1c%	R®­Õ|òÌAË…)9åÄJ[¬hıî‰?†‘ HâŞ2ï8—#iG=œ•¦Ü"³“5¡\Z$ïìŒÅ>£TR>Òı.»šùäÚ\2a²H›+R-íSèôKŸ7z2¹c|híqy‰İˆ@Í·­‡ÃHÿ5¼ypÉmèê®§VİV2İ¥¾Šc àĞ<Ğ(%&/FT¤ıd£¸Ó–’ùß´Ô6u÷_X` /„úˆ-Ë¥
Ø¡x¥%ÓÏ~—mGxËMé»…Ñ·»Ó,^µx£&èŒaªa¿Y=ä:e$íÙøüçş+·¹ôPÙ¼†™p”\fú¹ÌRì¤ÿ6JÙïÏÎ<æ0ş%¾M•§™[ì¾·œ"!v$J'(¹éî+¤n£/oÑs§£?2¬M,0À{œÅ?tŞAÀ/¾÷dnØ*·v™v7èş±R&ŠâSqãš×aÒµV&Û†aÎj£MŒaô¬Éyø‚Õø<ôş¥ÆŒ'Û¡/RœJTÒ³Æ“q¢Å¢<G¥6ÙÕ¿ûÉqtÄÖA•ïï¶WÙJF‘ õš1ñdò(zKw-Ï©kï·Õ¸=ó[÷@×3“]ÚAh±¤¼ØÈO0ìwI&Üä°½X¤º•Ï_ë•œŸ—õ /rÇ`ÄÙht®‰l;¹ùŞM¿ì˜/LˆÎwp,e*O/êÂX”I*+Wé¾(ü—@à·Ôòó7²À!«¬Ø8Ñ€†¢ÌŒF¨ÀÇ–gñ–VÍ(ûOû„r%Ò¬ÏpÊ•’e-*ú¿ò†Ş0Ò{Ë[

4"—ô27I«ÒªA× JX>7S‘ˆ¾}#›‰J¡„ÀŠ6´}*©A³*ÕAq¡Ã¬ˆy„¤NÒh+%oõcu]ú Q‘*Ùÿ*´œ‚wîåDøt†·.SÜ÷€lù¼]²@—º“@F[eN×Aù3çHÚ>Ç®4ŞrûäÊ™›¯©UEŠë2‘©½¿Â YÃòÔk‡QW=|àòÙ`Î*K¨&º\KY-»û \Ù!„ñL'YA¦  ÷¡ÿÇŒ	ÈöVº`ÿ2'U¬"=al¹FÑ‘_`kı½¶¡^‚*ÉÇùoö§»È´!Ÿ•.^]Ókˆ[Š+„R¼AâÀyoØN„z´SIM2¨…ıÁí¦èã]ÌÂ÷1­¿S:¦3)T¯±Ş%DK#\ßú=”c3HYÖÇç4¸oy9R·ù´@ÌÂNêc6»:û?¬1†tÌg8~;kHH°%gG„×cõmN€}Ûèğƒ`/lº€Gul»ºhET*|”"™5-„³œ}9•×3½8+O!Ñ¶„Òè1±|¬37R€µÏ{~?ÙXS€½ƒM†g«üçÏ$ânûÿ˜IQÛ~¬À.¢„HÌªşìÓÛè,aµ¬+QãÂû †ÂâI“¸£m×øÄ?‹ğ÷¯mÕºÛy-Xõ³P(­¶8–°…¡˜(M[X½í«™ 5JÈX_?oêËCoÃ†´^Ø¹_àŒ¸Zù³+xxÎĞ´1íúÇÜÑÅÈş|kÇ¼‹‘ÑB”:E¯êÒÛì2£¨œ†ÑNÙsï`å.K¥AÃøMÃ Ş& º›§ã£·†6ÌxÒ°›\‡VQ67dlª?µF‡&ÅŒG´\vª…»JTşğÇİğ:…ñğX8‡L>ÒD¾6ñ/îL—óª˜ö½”©™¯©çhò¡>›Î°BTÅ(ù£zG¼	Ä¿ÿ<ğŒ5Ïé‰â¸",º ™{e&¯Ši#ÜG­G})EŸ2>rüÏVG¥‚¯u ú°‡SºC‰O\”56	­xmš'¯ĞŠ¬Îw3jœ™tr†'8!,ö¬çÄØÌU-N³ß@av£2Áˆ€ñP¯*¾?ÜPTm­-go2Ú¡98‚¼‡0r¤q<Õrn«ıÂyÓmá²cÑØè+ÈÌÚ›)ßË¾ ¥ü'jû¾Î‡!«©3Ã˜³söúÚkÑ-ñÔFÈ}·\n„pº4OsİWB½”#âê¯yˆeQÓÎn”à\Œ›œ ìÂÅ`91}ª%yiÌ òÿ6ù-’cg9’â÷—™¾©Gµa‘Ø±GÆßªr§?¯Ïü#†ÅäÅˆÏTİ½ÆN·Ùà×¥k¡…q
SĞŒ€8J~-ƒ“œzÛ#¤)4ÎÛÅPé°ÑHudF>	¡h8w7ßv;0ˆ‡éqûÌv¾{}2dAÂ4ÿòùW¥¶<P{—IJáÎ„íGÑ‹ Peú†¬B.©à… ã¡¿ä¬v/ÑW¬fÜF
±fM	`I¨±vi1ûÂuÛ©Ã^D0ÏOµøh1VÜK€ÂeÏ+¤"ïÀ©ÖÖôT…—Ë­“*@%6µgW(öªM)NÓN{KWÃ®¾sÎ“á›—p`Ü•_CÊÓª)F9BW³h×E¬J®Ës¥Ç$¸?“\Xc¬ÂIv#ì÷š™GS‡4V”W¼émî)²£óŠ?Ö)ÇˆüSeIEÂÔŞLdÃJ2ÉDšv"Üh/|Ó}ª_¦Ù9Á¿$qyüæ“Œ“09ªƒ3z/“—«	GİİªãW<Á 7üsÅÉŸ ÃğT“N6ËS¹®ÆXÛºÔ$¸„.7)s2|èÄŞ˜ÇLå´‚Wmnr0™tûH,¸û`å¬BüÍ±o'¤Ğëô"«ÓW MÖ<W	+kÅšÿŸ?
ÒQuO½T2Îãñ¼Uæ¬/»ğúDMñb>0!Â®ëÃªÙ2zY:€/ö#¨ Æÿãa¯©ú÷ÄåNbOvùäª2ØfïZDÇRûÔqArWë?ŸÏ‘Ï„<¹âÊé“´1­IxÔ#Ú\Ë’';‚›±V˜ò¥KÈ«È„<„^¹uá#eôÂˆ|Œ¶•8¢èß ëŞIØÖÊ×;
E—ÿk{#uŠˆ^ÈKàñ¦ÇÃ¢[FÛ²ÒÔ×ˆí^8Q;éËÀ¨´Öc…w«¤»´B}	\2 tR§Ù™·º2%Ğk*¼3^[ÆBá]…`©",*|–¼_?¨—ï³saw°=ûRå/(Ù÷;èS€ıò{Ê¯¶ÔÚolÏŠ/QkrÕÃ “’íÏğ©ğe²L1„§†ª·&]z˜4ì4	b»œa¦!äÃ·«K+–ÜÎ¦‹o?®XF-öÓÌÂm‹ ’xñÌLÿ¬G¾qzåÙUìA½ûñ YQ±/†²"ìz±€a_9Æf¼,à,½.ğÎ§´MÑeáß ¼ğªNµBàË·ä’|N—u„ŠhG¤,ƒîÔô¸Í8ç,†T=“æëÜ–cõïä¬YîG$my´¼xï—“©”16£ÚgüJ‘a<+±mÇìéËÚì÷šb30emî_ÿï<@Œ&´à,æ[¦øÖîû¤†¶\ÏØN£"å.¿Ø»‹:~í¼•rÌÔıTÑEFäó/º-ôÜ44|A˜Àå”?îéß0–ù¼2`´/ò|Fü7†øÖÜÏVò7ÁJƒ5®©ÂïKä­=ÄÉFñ¯ØÖ(6‹6–e]}'Îd×N>fng†ø÷R7Ì,\<á…÷½E×<Ä•Æ ŸM}‡X6tU&»ñ¾«I à®…–ÛõÕZ¿+—i±¿HRçàœïïÔ8Õ3”V‚Í\9l_-b–¤‚h"Ô"–ó–Õf_C?µíJìE4è¢«ŞNRW[¹ OrjÍxJeÊùıÿ¡-¨M%ëe-"é4aÆ²»Æìù|\ÓµcÓ*®CõÊTÇ¶VŸ±89­¢²Òï¸Îo?~Ú58Úù$ÁÛ‘Û€‚“˜ùÕ&‹rD;3Fÿc/³\ê²9<°mz«OiÙòf””ÅÒ~¤¦YWÕ}PörZ5É}ÅYsÿ¼“¨GÆŒ	‰6¼?ç`1Uœ3ŞRo†€´ÆûiÉ,³§^¢2¢~Ú‰•'d*)<Lİˆ¶ºÚëI¤ûqLYıÚX¥­ÏÆü®Kš†§e³·	t¡¿OÿÆ—Ù?¿zeJÉ&Ñ21SÜıŞöY€mâô8–-6=¹.ÌLRŸ+ÅæLOsGª>úTÌz˜=‹!,&'Û<M×[äâåÛ¿4=/|?=›sZ¨ñojº¹_ºãÄ:8Ú„}RX˜d:ø;¼›•cK41ÖŒÖÈŞâŞ”)9w+¡røƒ™(™R8UÙï Ô—ÄUt°tXªÆÓñ²-?LA`Âù—£ß)DK„Ù9…WS:¤¦%e [HèP.vdcÖGìxWñ+IIªÕZë;è§ZÀ 1ZÍ%_½½å‰/µë8+)¨+ñyÇf‚ ‹ÌxRõşøf¹~³@¶ˆñ'£²AÊÉ±(KÅ_ÃşÙî›CT¥^Ñ¾ÑêœipxôºNO’Ò®7rå"²&Ÿ•]»?}óSğš‰YY\š¨#tPFŠZñš}üğo¬Ş$¢Y9Ø·AÇ‚>Í}—…ÑƒœúÉÑ’Ã^K¾Â¿æŠœ³¸0ä hZKÅC7&=N-VsèôáôzœT¡ŞVCœ6Ş„é.l¤v@CÎú–ùÛÕËÓ/£ ¿Üg•‘æ²;–'·Î¸ff|;ÎYé#f9OŸMF¬6qq0ÖÀPx4-orE¸À¨«‚}´ejGkd(Óóçï…Óa9;qnòRÕ¤V4â§n”Ùä= V‘C|×M2
Ú9Ô„™ÑaŞG*ãrÌ†öîXÚHP½G¸9šÓĞü-Ïi¹jYNróÉGV¯õ¹.º½ãˆd
ÄàÉÎ.Œö3°¼&É §›NmËö["zYŠxã£´i¿|´ÑP £Í4‰ötM¿ddXøIú¼„´ëŞP¶Fé÷ìBŒY“›QÑ*%0§‚›_KØ;ùÒUüSy³N[§ö9y`Ë¾l"ª’Ü»àOB[RôL'j{ıgËÎöb¨Éƒk‡’ç
H})³Ì¸W˜Ş4ßn_ÛJ—;0}­S¦Ìqe)nŸHŒnŠ·w9‡ÎÚS°7™¹µ“‰ª2ˆ|•QéÖé¥´-X½
¼Œ°çÇc:®S›ôZØùRüŠ®İt{®6MĞ_´€jÜú„Wx[J]nÄSß¨fºBÅy'‹"ówÄ<Ê¿^ÿsoŒÍ@fòØºBÏeÇÜkéR(j5^ÛTÀJô-`EùÛ%œ•7INMš3ü¼Ãvo[-µdÍüaŸ€VhŸ˜´ı~"=‰TFğ5®õ{™˜ùŒTeá!&íµíÚ+,™n­4lDñ”0ü¼¦LqÓlO,_?SY]7lÑ'Ã;}R‚zŠì¿ôˆ±Ì‘ê{eûè¼³ü»M?ñ•_¤sâö8d}À§ÜrËe“*Uü(2ÎUÖ>¾'¥ïét´u=ìÛ½iº½ã
49Ñ@†qû­¦Ö¬œœÚŒÆ©ÒoYYäî„¡òLÛğPgòCÙ+­É^¥ÍB‘Òá×¶×Z¿ë×½OpUNàğºIbl¨7şà<À(}ëH–ÿ/D‘Gn
Aœô¾™…HÑQıÿÕj'Ó+wŒI8şñfÏ›Eî7Æ2¸á&ãºæ.		d@çµ—ÒÑKoƒšînŞÂø&P£9M]µ¶Š\x0'Ä¤¹Ä¥@zã¼€ö=(:2‘²Öë§N	d·”v‹º„ÊR¥/ş¥Òc$~Á·V}LêÔxçú—}<]Æk@P?£àó;zŞ
©P^ÇÒ•GkH#_eÍMr§!äù5ÍdiĞaM3ÔgW¾–ùxÊzä,¦P(Lœ–¸µ>şOğ@t˜ğî
_æ«30—A¹GëSâ<Eîl¤6‡Z®l;wø!96H;ı@lÓ’™=´-µ1€.6Ÿ÷¦¸dôJjÌ3ÎAÛÙ4a˜–Õ³ÍeñŠ(GZKÚ6I±•#aœu$V¹©æÈşP›Ó$i¦eÜ¦ÓmiÄË1((‘ßC4ØF¤h§³¦Äš€:BÏƒ¹ „f2Ê~BaÚpª®ŒHôZÅo‚lµ½õ-Î¯g;šäi•ı&IÛ¹3Ö‹â¦@1¯)|!»Î¯Z›µ~¨¼ŞZÊçœW)”¯€,¼¢°|ĞRÖxWñ\ÇıöûöiFYåR½€L•NFU\eÔJ|•í\‰2Ä*Óxp_´4µØXÙíÚv`ädìHki'õ®È“$—û‹á‹RR¥ªtû‘÷$**¿ ²Zmäø@à•´ÎÚø”V¢^23öæ¨Â˜üÎ¿Su«±Q!·‰`2Âá1Ñõ€ÆÆo'¥"YãŞ|÷W"E2óa‡‰­E9¶Ìbÿ!Z«³Œ`”ŞD7=€0P$·c2,—…íçÂc†"€;Á›ªôÎ®Éæ.¹Ä‚ŠuèÚµ²:j¨dï^ÂF5z¶üƒw`ÛbO'—’hÇ´c—Xüšõ¯¬·4°*lÑôÊ›wd…¨?s&­­:&|ÿJòœûåÏ" *‘/Ö&HÔ¦GIËšñ3{_—yyçÔË]b\ ˆ4æ#îäxı7l¡|j„<å)ÔTƒ‘-qø v•Ï¸YJS@>Å²'êìÔn«Ÿ})‚Ao$Ñ‡ÔÅâç[â¦i (0M).%+dÊT_>«öÇsM¡}Ş4e@‘?xEz¥TRÈ¯ÜlÆ–-&¿Êy gr9/‹İ¾îsZ/*òvå~,:ÕÛ9†q:“æï}ğMß‚Yxø¡×ho^Î—9¨»´ÜõXMf qL‰’‘ È–… ‡NuÏToİ ›.Œ09=](7Î,ñ‹´1Ş‚hàùG˜ ‡¼g3±	OîZ	bÌ”’‘Lb\&ƒŠÌ˜Çáæ6Üî:J‘¶ÓtEyĞ£ÊÇtõF!Q.õd	Ç´z°Î%yc x~~2²œÄÎ©“ªàÇÒJÈûípI¥×Şü;ƒÂ·= ^'¿áÛ ÇÕ§%î¼}`õøvsMdÄàwP0\]Y/E´‹Z;+ª%PëÍ`h¾4`=C”ü:j{éo¦!…“Ü&üSºùñt9§UwŠ3nMÀíò|áG4/b@nÇ)û‚HÿĞæ:¾peAèÎAÊ½XÓ;è­¦şN+V²\t»µ}MZñÁİ£É¾ò jRĞ˜ƒîÈ]íØú»! lîYN&“Ğû»UÙrZ:~Æv êì%û’‘Úââ­¢Çôá+«…æ«h}é¯^&W¬¯3 :»!ioU:EPA¸šö-â“UıA‰¨Ôômï%Ñ2Yù®Ü¦œç«AãT:W5ÍĞ;	]Ã[EŸù×
O Ğó  «ÛA?¨ ğ€ Œ1¦±Ägû    YZ