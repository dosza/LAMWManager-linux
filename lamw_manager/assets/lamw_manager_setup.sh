#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2744242830"
MD5="51fa4e052b4663cd59fa012226f9bfa6"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22704"
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
	echo Date of packaging: Fri Jun 18 11:18:33 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿXo] ¼}•À1Dd]‡Á›PætİDñrì•ewŸÒ¶¨°‚”z7óÓ.W‰ôQè¹IÄÊgeÏœ;¼È?,¾d\qI	£³tƒv"¿<è'št5%%~†©&Š\ADü›¯ú\Ë'ıÀ$|
Ä¢~IGz?@ÍŒvÎÛùŞó&ß·€ÙXÕƒr|üœÃöÓ-õ²~qÃ„2D;½Ê`+ÁzGXK„¢DEY·¥ÓH—1l^+œ	õ	¡Ğ+Òë·E9×.êÓ›ƒl;Ìÿ|^Zœ‚³»jKØPÚ^«t4YçÃØ²X!‡¡Åó¯êµW^0¨WÏ-ÆŠZHÂ™ìİnòû
®’$uÜ{-£?4­bÓk;‚æšò{¸â¼©2Êò“TŠ¬Ç.óÏ‰ƒ=:7Â¶ÔXXœ|Ë%Š•Ä˜£,Hx8îÒ¦øï£’XŒ’òÜİÆœ3æA0,¸dìIyîª¯é¨`\ôÍj-¦aÆà]«Û êœ²B/tã‘¹Øı±†-µVFºCÙ'Ô•j®(öE4¶U˜'¯ë?ÄÒ2Võiî•%>
£É“|–”UwÒ;dĞØÍ~é×n%¹B.•`y™YªmE{}¡¢¯Ã±ıUº0}"qëè¿l‘©æë`»ÉèJ„‘Ùæ|BP_ “o?•ÕÖÖPzğu)e`ìë”heEQ6úÑWù?‹˜èÅß<Y£ø¦2f>’Ÿ¶»CÒ9á`i°Ã³àü›åÈËİğ9Öch mAgSÚL!vx#êó…»ªM]y™³áDƒ/ü0¯mÁ£´w»zlHKÑP‡_îÇâíhÒ‹.¢¥óéÊ¡aƒ¾»œTÎ:ëbÈ<R‘iØ».0tRöĞåÉ3£-íâÿ™'âmHBgCš]9Èª#”É£Ïw¶v³ºî.bæÄ@_µ@|=2rOaÃşoYŠÂ9h†ìÃ[D5|¨óõ"[_ZE±'êúÛ°Lm¼ŞŸ¢ë¥Z>jD3ñ}°Ê-Ç‡Ír|Øí
\c9"=J}Šú;$ŸTÌmğœ¼$F˜r‡áƒúï¢)ü†•bXÌM×‹Ôğ³›ƒâİû›]l›“tì¤s«:9\‚-Î;äz¥æ\<ü*†Ş{]Ê-µ]ÔXcİPô{d‰%¯ú–â`G2Do^¸Ô½Ó^Y;ŒÎÆ0;bTÖAŠ@PS±€JLÑÂ:{ª#‰É4A’Aï«è;Ë•µÕ ¶â4~®¸&EsÉ!¤â¿|ò<G%äÄY¹M	!{ˆ0ÊŸ‚5Fu>9ÚIB4:÷w54[à_©ú-%U9¹‡O¡âÏ\[§Ü\ÛôfÑv>p`Ø
*”¸Õw˜„&),¼ZÖÀ@P`ùá—ªIbRz|±¢¦bP'& \ªer£rg¢¾14´p,úè
ÄÆ†3İFËŸ·ïáªSµÿilÍZ}C|ğR‰Íõqq¨Ô2•F6ÿ„ìjæˆÍä¿2te66`üÿËw7[š¢[,ĞÛ‚_‰yõègóN)¥œàí‚:Ô÷úP²p“:‹&ãix-Ôi«X}ò
ëwŞÔÕ9qıMßZµ½ojŞ\A!éİİÓ—4İ´å÷”ÔÙv¯0Êq4uÃõßÒê:.Şh°T17›X##8éÇŸÅğ×†ãa¼eˆŠ¸Ñ«?(€ãÿE»ºøã•ZÙPÕ§ø²ÏM“±|*·ûM¨fÉHVQÖ6ïû´xLzsÂ²ß´±u£ø¯	NÖŠNÑø>—ı[¢ŒÙYW˜Ã®”@ÛrOÈ<s*¤"&Š'Sy†Øh‰7œüÄïÙpo,Ÿ(»Ø6Uéµõh Š¡‘fŠÒ.Ğ
‡•£ís"Œxä:f.D·Lë8})lßÕº¶×prA÷ éN–:¾*êÎ¥É_ t	
+ÜG£/[FÉÉ÷˜ÄC«§ªgêÒ*&§K@l¶¦ŠüÃÖ›Åq…Áırp ¶?9`.#Jş	b@$Åµ”º0¿Bt7+¨[|®xO.†Ç]8ĞŠt5fa^£	>˜€YîÉ4öÉ³;™–°£Ş×I‡Ì©óà9@-c Ş_W¹ùÁŸ¨^àÓ'\÷Ì²ï_*Ã>vMùªÌ$^lÊÓkùÉÆëY%îKm†]+ú¸ç@æt›â´SgğÊÜ¹1ç-¦I¡jË¹ÅOH…ºá”´ıê ë†^ö×Ú\l5yPØ‚è™İß@k„QwÇç´Ğ¿ÄÙá™û4¨f6p.¹mÈİŞgËÁÄröœøñ²u"î ¾õ@§ìÂ}hyó÷Ö¶jBp|&İù@òˆİ·"©;œê`–ÛûšËltà¾)<5ÉGîº?¢¬TSRWß;ú.0êc ~»‡‚.º§£ÿªÃ¯íÈ¡ÂA™òèéhı—Oå»ÂA‚”f¦¡ş0¼sÜ$hì†ôõ|Xìÿdy÷,†Ğš‘–]/|ïÊ  q”o—­ïSÏºE@ò=ädÆxèÌJƒ=S•Ã˜ò­r¬:½&(ƒ°Ÿ§ÕÙKuÓ61³îStq$‹.ÂT¯|Í\î+L¤'Äš€#àı™æóànKA}w¦3ç¡bT(cx‚ò%r˜¶9Xuß~x23¬ıÛÍl¶§Ğ|òŸèÕÀ}~;ÇÇ)S™rSz¤l–5PR”uX§E›<?€ËêÌI•(Æ_‰wÂqÙoÉm?×]4•Qo‘Û¿‚øù%~àŸY†¿}Æg%‘÷aYªéö;¬Ä}a¡,J™†w}Û)"®P´×w”˜”Sa¶Ï$0¹3=1)Q7yVW	‹køeœÑ_æ—°àgÊaaŸ(ÀlòÙ¼Ã6“Dm]=OËZÖRCR¬'>Šş~gX§æŞKòë$‡tT	ÜF¶“âmÓé¢¢ $ÑË5˜ÈR7èã$!úxÍÅf ^Í‡›9_Ô×<­lÏ€ŒîØ¤QHÙL…çu¿v1óT0 4³c¿W·­	ô4†D„Ñ…ˆªáDDo¨ÏÕ%°¿û
eœpÂ0j§	fÖÃÚŞ,ëk»oK	jZà|ê gÃäµœ3ãSé™¤¬İ+ª¸fÅ¤uPØI¶ZŒüÚÏĞ£•©šT?©"ù M0'+#m‘#íÂ&Jî!˜ø¨öQN]éuÉ$2æ÷ñy|SŸÓÀèƒ¼SJ¸>’gş>™cÌK2(¶ıëA:…·÷lAÅùúŞ»ù÷êw˜šóÙ@)‡£‚ˆTX)$Ò¾Œ4HílYıı¨Éåº8‡îÒòÎ¬Ä'§ŠbÕëã€8!‹<Ş\8Tş¯²qĞˆ…9gpoW*<#„‘£CZòy§`ëÇ½¬H–î½2©^	z=Ãöš)+óĞ‘\ ™˜ú‚zV
¥=×Ó,ßš·Å †›l¶Õ‚»Ç€8Tà¤³ö%‡¼¸yöTåµ¡ìµŠÁÈªõ¦ê_ËåšI*(šj3MiŞóöºmÔÒ„tË&îİêãôê°-Æ|hí»_nJvKB³·¿¢ğÜŒe›òYbq§8ö}qº”ùéßPx`ƒÂ>|:¢­·X`]O">l |jïf*#Ù0ôdí³GË	l=¾(O{äš¬jÏÂçßµ¬4€•Mhn¶ŒS«ß×ışŸw_ËÅİ[™8!gŒlgB¤+%­oğÂt&ŒÇ[¦ü‹ƒ7-’×Œi}¬Ö­ˆvØOı®Yàˆ™—Q1?_ãG™Ü_µ;¥ Œ­;œêYøLkƒø‚ÆÅŒ"ÔÒ|ËŒT0æ×®ıã§¿í=Šp÷½Ö«“.µU%rE!ë¸—cÒ$¿ŸJ-Çm©÷vµ8fö¥1öŞz¢[¿ğ ±“\\P3¿m—ÑAU¤¥Á›û[“î§r¯`8ÿ„÷0v©4ÃŠñ<:ù¢(¡3üÜ,tc£ÅRÔNÓÓ(=ëbNÅR(+{E¡dvÿµ1ÙÄ‰”úU#ˆÄ®[³dª…å‹ÍU-â<Û“'ğôo«şÉE§9Ã‚`hP³N"Sv8-çŞ‚úE<ßóÎØ(µ$íÜ=K4;›sbÉ¸ÄcVïz# ˜"îšC ]y®¡.Ñ×l ~›Ş¢ô¿¿„¹b-¨9o5Ú
OäÎQQT5åa—bÑ8åy)Ùû›lloæRíéâóS/ºıä} ™‘E£‹°Ke½‹â¿ˆ8×~šh¶¾ÓÊmZ×87dázÅŠıÈG6NózJ—ìÉŞÂµn€vÒ²(ùTFêı¦Ğ;w¶hú%ÜªGÚåh!vµÉ=ÿ€mòm	¤bHÙgWEó°9.¾oß¼=ˆÿÀm//Nº ¼*÷±AÏ‰±LOJİ/=ü{E>,›ó?äùñÉ™J€¾pÂ†”U.°¢RsûeÏ;œOLÅ3—>ENn¾”Ú	L´î·òÙˆ¬ôKÙıèù§Û	ªìùƒíLõ#š3¤ï¯5$p-ã²÷?…ŞMÆX.Şú¥vO<·Ák*î®RØG•@t(rÀì·»åV#lô’"Š«ÅİşÙÇ¯¯)™x²ÕîÅb¹ }@t¥	<€ÏÏA¨òa6òó~¥ûŸ¨wı'úä2	ñQ?´+¿13d‚Yÿ%¥ML9ÜJ>1s%®¸ı‰#ıx!Û¬]C"'“Ä‡ ‘Ó‰§:?mFrõ3-?BÁ«Ğ—0È“l]3Y¤U‹ÚMåd93fçI¨`¸ØØ°u¹a>öÊ(·o‰VËHV[ÉÚ¹á,B½Ø4ıÙ¾ƒ£ÇKV0ˆïãÒ§9ıè,\ØØ-õß‹f>†R‰¶÷r@_Êæ/Õ6‰ú-PÈÉjÎØ¨èµ6Ùò-®'Önœ¹¼jtûœÖ@²ÒÒå:\œûeÙÿ#Òfğq7;²ï‰ç&,±Sïá£XÚ!J:æ¡÷³É×q 0õ$N%o<È~eÎæˆ‰“ Øàp³~åOmØxš3 p\÷Ò$±&ÿØGLh…	\SX ÊáB‰ @ED9—ásÒ'ËÚM$xAüuavñac$4U]YÂÊcÙ¦Îî¦İæ^\8‘±@ä2µ)kU´ô yPH#Z¨î'== m†³i]Ä™œÒïDã°ó%ˆ÷ÎSùš€
“9éM]í½ê0’w`²-úEuÛxÍ;…&YÁÄı
¥I…Uƒ„bY²&pc(?„¹ç'v,i0«y@§?M|–¡í¾!%€8ZŒ°şé)V º°é.õ˜V*>ÓÀ?Îî1˜ö 'ñµT”S_‹óEœ"añçãYYõ­½hºk“AÊ rQœbAtÏ"ÈÀ>¦x/Üü¹Aè`<¯ƒ“¿X¯;½z]Õ· gşèº@½»}èâ t­õ
ÔàèË²RçƒödÇ üïEµl óËtÁx–ÒWò>dÊW0ŞàvÀ×­¢šşUŸÆ_Xİq”Öæ7RˆÊíjl(É¸`Ù‹µ†–Çßányş7ÊœyAD¾Ç¼]rO÷@Èaèµ’	¾j±ÒEÒhA:§íóÒÛşU|ŞHâ³öÔ%ŒÚC›©ÈCÀ&Cg±®¿ÆæóßÄ£1M~ê…ª•Àºe"ı01«Xk'ØP<Ÿìf°&ˆ|	ªí*„ÜğÃpk†‰˜°ğL9šŸ™ı°£ÂıÒ»Òuìo»>á))pSWî¥”ğ»7Î‰/˜[—ø­m‹à—ü’úH×ÅÇá¼‘Ç>kDÔ¶"¶Ôº„æ^	Y7ü& mÏ¢_bıÀÿÚJ‡¸aÿ†ÂJÊ°ë¼%ÚGEÿˆ(>4A%ß+¢‹œ5tÎ£‘$_Ç‚`šV‘pŒFŠµáLb«¡èk`qp®±3?>éfÆƒJ•S5W·C;6 ÚÇÂ—Öêãë9fJ<ó6 äÄÈøÄ•%-Cª-kör!Å„äñÇ›Vş—‘’œ’|grMq4GvoÁ¿L£t^Úbâ"°‘¶§Æ¬’ëÿPß>X²,ŞDŠîº’“ÒÀ/˜R¹-xQc‹»ûJĞ¾GK™CA‘<yéI{ŸRÈ6œ¶ĞÃÌ£(¹K+mıdÚì…Gc®Bœ•¬¤¡ÅA-ÇGILÚ!)>íÒÉNîÊ®?sñÙ*É	Hš7Û”5ËÌŞÈ±€&Jšã5¾_m;«jyˆ¤eª-a²‡]
‘×W®ÌntÁ@(ÍVˆ2EOîSÛ*Ó¶ùaå›‚„ó]§`û¯S×B;6Y–ğÓ²gõÊ?¸GÚ“/ieîk¶»Í†‚cõ‡PïntóìrüÇ'p[§ò,“ØÛùÌ‘¡Ø@SÅ’GuU×bÒm ©éâ«'$V¥ÿ-íä|hœê9ø¤ˆHq.Òà	q¬bÓùô!$i¡ÙT0®)vdD´ü¡ÔÛ˜,Œ&‘	²}._iÂM{©rsºqvÃœ’·Ê‹Z·HíÕZ±_a-eàÚŸD³S}°Ô€o bmœ¶ÌÍ!jßÖSòònçeºè:„DøO¨ù,ƒÄTUá ÒŠ»}é#SsÜ¼_éh£±Ç_¾û®îØí’½òaßØïsîµì}4(c[å½Òî  ŠD5ĞœŞá èÀé$äïÅ&€>€µXpØ½%f#c<§i«ó¿÷±,’Åx‘l HÚ„kÜ–Y-w!ïäxµØËkç™8N©ösÆCİQ*JL”£©ì®™”Ğ·ûÁT0f_ŒÂä,ä?ÕşXù…“Áz$³ÍvfL
wZC==¸l„>lÙuÑíMvµ›¤Søù°¡¼È—cîĞ¶H¾QlOÿì·Ô¹VwFtÓII¤"2mŸÓ?®–mµ¬-&Èà’mV%ó=OYï§‹õ~2í|lª^tœ‹/ÍµO|ğÚ>MPÿsô78öÂ‘GèWrGK$19²›øs7ê…­Ş¾iÜ3‚:xw²à}"F‹;\«c<È\`Ó>ÅÆ`4ó|ñ¡¦êòİ	©òõß¢¥_$é!H~³˜ıBœsëÁ¨İSAic%\J#t7ïÓÊL¿(‚G³á!E€#ôBL¶‘Ê ĞiKYÁ¸dñóùº.êEïU¡bîãiS_.‰lg~-V#3R´B5’LN°÷ádÅj´‚”
6¼«+Œ5E¿C´b9uFÔŠ¤$!Â¶<´uº)­}‘—¹ÒP“i5•ùÄk}¦­¥ğ~™ßóµr¦wæk(C®È9,•ø¥BqxD…z\âd8>Vï÷)™üÜÿêŞ¥aÌ*øBt5Æ{™"ÂªPò§
C|‰oñ]ê¶&f#ÃşQ	‘²3B&$8&n>&K¼?t÷%YäYÈ'ÿ{‹)â:ïî¸+ëQ1FÌe¥À{Ê3v[¨F(Mˆ&v83rÍ¡ywo»ßsš£Ù³T›
u–qKIk~‘x9l\‘3çS½8¿³Mì_‡e
³f TÎé4,Áç7RµÊ¡¯ÊZ‡*ÛT«èOo‘0½ÔåéT“dM*“°mcmšŒ°kn?8š‰¿o;fDAw@k3î¡†ÈÔY‹à>^•£—S_A¯¼Io±\…ÏHc‚åI-ªßF.İÀAFí§JCŠOóKÎåælÉæJWC/ÜëN^àø–Ü‰‡:ã¤Ğº Y¼!ÖçÁŒŸ‘ ;QÁİh`%G…ºØ«ùÒl¤é®µNO–\g¤f·Ô8«;I7â}E;ÃõJ¦2ÿÅ®«İÄaljb€¬fÃU0zùé+x¹UqşìhtÅ@%k¹ÃŠTò¸J×Š7ØÚ‰#^µê}ĞP?±U‹şeæÉDÓNRL—±gªhÏ;üoâ	¶ş«o>T41 ÍşZ·åš6@îĞYÌ†.*øEl¸¦sõí›TéğC›!¿E,$‹•ÇßÚóÎ´Iø:r˜vvÈróùø0SëÊúeâišB,(õrmqŸË/\(Êä—W$ğ)(:rqçB¯ğ mF80p-—gK{Y¨oéïÍÌz|áÈw8³ƒŒ,W×dÕ@ÁøÈc‘Ì`Âs¨•ï‡ _]sÃ0VéÔk:M¦?$“L´¹«­ak“%ÔZ‡¡‘ë/xm mÜyYòÉÂÚ 8%åŒ&Ì_Pæmü×k8Íuv-§dË€Ğß^^ëî®Y.õÖíD3â®†İÂ.—Ä;+¡OIf¬Ï?P¸ááQ7«7‹&ÿÓáDMAÉ¹Üúui‡yìêá«wÌS®òÒ9%Â’ó}‚¯9&Øw½K²õì*CØçA±P2ßía°pÈİ³ZOç‘ù˜5!–{±3ÄéĞêı±óc.SB)ùÂ¥Ãò1óŠ9É¿L!êü¥Ÿø'–Úà59	—_xÓ ½Qİ{²mÀH®„Ø	ÿ?ÿäÎ~ó»©pÓÑ¨åq>ØÍS‡q'”	*M°¢*$Q[ğ§'~U9@!]”#ã„oœbåà° Eõæí“8j¯Ûşä^qDİ?#óp‚éS6-5E›ššş5şçEn)y¥¹RœWgµpı¥2¢Ù»:g†JYàÛcıqéùp=æoóš³ÀYF5	6‚Òe°&¤ÒÊËuÔ­ïr‘ŸÙ†!Úö±‹¯Uÿ­¤LT±¢¨v7Ö¢G|yv†l[ˆ&V hªäY…!aQ5IiY3Ü¿÷M1XLÑÆóÚŞÓUšüYe¨\cƒ¹Œ«Í5p°BUnÉ0T63ë¤ãzáğ¦øm@y’Ä$ÊÈ›½šçÊ–")¿n€EE¸'"Iğç–|òrÚªıæ)×8 g®  .š¤Kq¤&¨X‰WS}Oßp¾P ›~`É$|{jšŞÑĞµEß¥•è=S,rußÌõSXÑYÎ°Ôî@'–µ×$İõ#~x '¢Ğ8U£º–4Œ'”—dUĞ\–¾_k]ò²¾_oğš®+]Jˆ°şêbëJ[È/ Œ™î½¥Ö"7¤V÷jg c,ğ—:tÁ[´2¡Ä]LışnjÓ2èàïÖ]Ã‡x˜±ûnÎß‚<ù¹¬_jO™„qyè)÷§ÖÅèiû¼ßÏèì/œU?;şÃXc'‰1A)/ı¹ï1¢Xûğñ9"JåG§[~VáòmQ¿‘ YBtã[º2ßû‚¢ØÌvÉÎDãQ_¾|$¦øvL±ñs|İõÆ'”óxÎM® 4ÅñXè ‘™mbu¨?ök%êİÅö—áš	¬ ±8F}ˆÿ`Ä2Æáj=Ô­´]Íš>ÓòV¥Ÿ1@‡äİõo$™<¿ˆG6hjº!¨´ŠÍ¼lKƒı’ªÛCØAípûéİßÿê$r7	ìÌs2Dq' C]e-ôl,$]‰Ö‘İnakï‹6ão‡«;Œéş€jnµøõó”k0[/ßÁ•h	õÊp@Ó”ÆfF\-8µ*÷Õ;ô¡¶â×e}vCBi£1tÏû?9T¹Ì”/¶Ç}(öcÜ78I×±)^ùœ4'÷·‘©)>f˜+®uçRh_I63A´İùçÕÉzd|…=™—óİëmñnÄO¤ÆŸ/(PÖğvçúàÊ¸ŸŸlVe¯]8‹… @KÃñé…÷„¶¸îdÈ–¸ä)ÅÀ™!Ç.3û’ Š€póÛ×´ˆò}á]Ã&üÛÖä•:ÔçqúÅ±Ñ· å`G•1ç\•7ÚÌí½ş½†ØóõVï[—•È³×ÏZş¯Ù{Z¶W‘,ş™/ê'K/¬I(—¶\	ğÿÙs{â–­şíe¶`Ü¸­®µ•£‡ü";k¡¯P·lÓı@OU(G`12š§¿ÿL´‡Œ{ Z@R†¢n-Aãÿˆÿêäâ³LÎ:ê4 ıÓ½ÁÕ®'5œÄ/0ëÏ–¹<&ÌÖ¿'É©võªÛx$¾Q×¤õÙA…(®n"yEÏ™Üƒ)ªj¥ =GwhÍÂ-
4@Îf´‰ÿœ%0“_x£øÇÚê=¢û¼=¥îX³™!Éƒ™NáÈô·¬Ğ<„¹‹ñ‡Â\ÊKâßÏ£ÛAjÒ‡“}é Y—‘5…æBà°»|øÖÌl™şSrî€‡[ ¢²±õ¹=äøÀMâ.’šÖ>‹A	¸¡Ü¿:OõÁ)Å®6¹‚[˜¹BÆ]õ·òëTz¯ä6o˜ğõ½ÅÙ‘%ŒTÌÌÒôÍÔ&Ä¢2t{°z:ié=·É¾ÄD
¾À´ê÷O­¨‹ú¢ÒÅŸ[ÒÖDrî™c±Qa(X¯©æ«³G4jû@Q‰n¨]š©3‹Øx1¯\òH€ùg óL¤óÀıá»2jr?‘‘=—7m\¤yC„JC£Ş"_/Ëê+%
ä/hc~AOš0/òÔP>»Êbå4M¾‚ô‚C(ja°åaŞõ†¯]=æËß=Oş+`*P…r*pu…3!tà>àÊ™¤íQ‰‘N6¬ëİHÇ´ç&™m0llòUÖŞÑQb »ÁfwÅ(v6üÁ²–å7B½Ä]Î8ëâÉo©Á”¾m84b¹‰Ó•=ôŠíM<OkèehŸéÆK,1WÇKÚº©½£4Åo2ÓT%{D_š9Š{ã])µ\K€¾ÂŠî}›]/øëÃ{¿¢ÿ/[º[Edt­´Ä}ÀÂHV¢1Å]èúòÚÚ×ğN–Ê"ä,ÆÛR]&)Çdš'á‚Ægp7+7RAÓf2æƒâ¤Q;×çãòÃ§ßE ô)¶iw©®fTîXğ~OC;«}Ì°7õW©ş6¬¯²då›K3½\kn³€&ºÌ|=—Zy.Wä.|oºĞUYË,BßĞŞIìMø‡¹ßT>öÑÕİ‡ÔlLÅš‚åe8Õzo>\òô/bóŞÅŠƒr%Ä®) 7¿	¨°¤S¨gC€2†"“\Ñó³>×f‘;¢Üuİä5øaÒ‘"Ìbu«&±ëb¦Ûğİçt”ö‡j*š®ª'÷æ§ïŠç”Uÿm_å‚NEH¾ñ[·~ç«2Ë¶‰®Eö™»ÍN±¢»½²`OJDŸİFÀŒÙbúdó<zİO½íôshCæ99Í~i€ê•I\ò×©Fïwl\Íf©±ñ7vDŸ]¶™ˆšãÏTÓ,‘$Åú¤ŸŸÜm|9|Æ3²/`¥ùš·ôfK¥*¶sfŒü†Ê¹/ÎA
ùB:(òN?Zì©~&D#,M©£cEíÚPãqït³¯\¾C¿3YãØ,.d¸ŒÊë¦°©amF5Ä*êöÜ,Š-$dÀûÚÿ*b£ĞŞ|hPÄŸÕO#¥²=Š]¿–ó¸|rU
¢òiáU®?şK ê {ä“~Ğ2æ ;"Ô×ĞbVZï‘"ÒhîoÅµÌèÚœŸ¬ë*4eoê¦a[IÚ±Vç6©yœ»Š¿¤‹EØ«Jw’–}†>9Ã@ßöÅİ8N,Íßk®²Ô0^ŸC[M†°$Ûf"V	¦¬ƒ›İ×¶æßŸ]XáÍq‘éaå4¨.ê®ÑwN&wI×œ«Z¬³ırÉ®¥QB>ÿyå-+ô`ó½ïœ8çHjšG™ï­ñøé2ş:—ê¦ü[/"ÁÏ&íƒQ`… h6 &úwíçÌA÷×c\W„ÒG6j¸\À¢ÅCuÑíìy¾›»Ó•‡Tç·!£8nNå_[ª‹TCú*sû&ã	½+ğÕÊŸepIè¢ÙÅºÖ:rş1ÏúBúƒOÏJB§0×)s6aŸ›£§AÙ_¥]w?£X»÷k8ç«ãb¶¨ÜëµEWÍïöØ‚·ùò–ÏjÉ·ˆ#9ú¤Ü,™•¨!Î¤d°ê²ø	‰üÊëY=9›Úôë·©È^’°-Ñ±…íP°Ò]¢#º°˜ìÏsò@O,Â¸fsvŞûªxù#SEM{`Õe.SïU®7Pª«4bù®.3±ïøXxcaÄzaÀ'gªn ˆll?ğnÖ-,äƒÔ.ş…J>Ï¡	dİØ„‹ãDÏ­HfeRŞ;¼lGJ÷ûz‚šÒíoè[¤F³ó£°cÕXÈÁĞ DIiî|ÛUüñ²ETvSú²ZĞAŒXû¨‹Ö7éÎåøTB]ó\¯ùƒ6EÏ½civ!İ+=ÑĞ7ÌÎ¹ˆÍÑ}kæ³TV~G¦ñÜ´MŠ9“ã`eÕKOéTˆŒ=Ğ¥iN%ËÈvé]›Pÿ–ó‡E÷§¥}:Qô@ñ
Ç“ófÁr›'âßˆ/éï'-ğé_HßêÛç¶¿‘˜?T+çÂèñ’XOØf*_ ÁêSã‰(\9‘Œ×XÇƒÚÂ“TgdY#•«²ğ@àBôÖqİrßtOXãìwÜÀµ<¤¤Mõt,bv-•Ñ—)ûecçø:	W¸U]IC•lÕÒš.ÔµÌò¿}G¼3q]ì° rÛ[)›ÊÃ?£œ¥ˆí‹èdO¶ä <©#B&Óe×£V¼Çù”z¡¯úğk¤¶(7±ÜSÛı4W6€İİc‚óhø‘.&zD¼<k
Q¾(`Îi'ëŞÿ?Û·.e@‡@>y?¼ni˜ÿÆ|Wşï‡[DL`¶õUñŒ¤hsz$&Ÿw:H?­6‡"§M•®•™ökbbÀø=O´}qx{v6]ƒ€ì’ÑHù*ô‚ğ`Şvõ¬}Û[ÃÚe`ÃnÈâ$šß:ìË]§âàZ›Pù¶ ìg…,šÏ€q¯ç>Ñp¨Ğ/i—OèoÜn9ÿè¸/l6 ?¿Àf €a³ÿØçs%{d{F½L‚Ò9Ïh6BPÂ¥ôØ‰jıÎKş(ÚètÚ*>·*HİõÁÎ0Ï‘]|Íå¹¥#Iiw¯WW7¿'Š¦|T»hD¶EûÛMí,oYıàêÓïÌj:X×9ñ,ÔH_Ş B[Õ>û£5Ş(ZãæØÏ9ĞR"#6‘†›Njã!BJ­ë_Ée(Ù£i­³Ü>èôŞÚäU6Èøó±E1µ¾pWÒ²’ªG¹%ı-Ñ%VtKÚ–F 2/ö2“ÂúM´SL_ï“aòKx³¸Ñ¨EÏ™ˆ ¤fµ÷MˆÉU÷º«XŒ5M\g)<c[ğnœ\ñU=UŞü;‹ZCºDEØ}x’cÍ™g³‹Ş¿ÓÎ^Ãå0ÍP‡K~CĞ	$Wç
‘b‰îÑ¿ûQ5#'Óß¸’ª¬»›â:ô“›!Kı:C9…úês^s+^M‹#¶ì )KênóŒ'¬zòÏ¬²Ÿ¼’±è£²ó_Çìff0?D»#(_*ÓYBœRÁ›‚óÜ]UÂ°Õ‹0Á!+ò##ÅØÚÄ+
÷o7ÆO+‰ÿ:áÈÛ!½`-£ÕBçÙÆ‘*Îˆ>X°ofÆİ1‹“*ÒÂ%ÄáA1]n`·‡vÔ«¡Û:K{T½sü3–Á:ÃíF=?oªè1Ğƒæ7›Ó_(T5ûÛÖà%å\oî/	”ª…í[“º:F"ºfz‚›wPİ„èU˜\õ<‘µºİéÔsAr’ş8MZF'Zı•<Æ\2bb }n¾4ø*×¨ÁáÈU"<Ñ¶Xñı:óùz…Ñs*£@YçŒCÏ£ÙÄıAJq—Pp8AsöSÒ¼	cğÛÎW¸Á‚öo>Nî¼ĞH_I7½àSêa¦xpÇP&/C4ôËÅµeúz¿ağiNFöÙ#!æ65-½n_Ã¢\éxôÊäÊÃôº·ı9¹ğ¹™ØÕ€íãøš†%{®´k¿#n¦İüğ­å’Tú®X]¸°Í‹áï¦|¼Æl ‡¡fõ¬uÌt)`gÒîºH¦m	åei¸[0ªé«’’yª=Ô•Oƒûäú	j“Wz0«!¼ÁÌg¹â]F±¤« ‚ü…Sk?d“Xrj2]JÜütÜ¨zÌÍ·ßÜ‰÷©„Xå?ÒØ2t,cÂ!ÙŠÔ¦Æõ?¹<;äk}Û€0Ç?ç3Äe¹¦ˆ?BJ2RJªc	'œğ$QÀwŸ4 ¦ Ö h„Çy9@ Áì¼/Ù£Š"æ‡PcqãOíØ	¬;Ğ:Ö¡P©>OHÅÒêÚu2üTôtù3jÑ®¯°É{DÍÛt€,¬>HS ~|zÁÕ*±¶r—¼ùÀÈÉ’h^Û›i½P¶ß~'ÔCÕÃŸpIœŸ Ü±x¬6-,Ç‰á3ü°~ñĞ4ÄpeğÉÊwhVšW³©^öV¥#zFØ³sÚì&àV.a]RğVœü¬uˆGù"8“ö¼B$º˜¿fõ>)¤½=àÑ`t¢wKw8¤8¯'ˆsë°²ºåôÿê=wMTËÛ÷¦
¿Mê¯®[âœDéFêçzéã¬"¨ã«ûÖüŞŠ.}Èg;‹â¬Ô»ÑÉÿ­±¤Í·Áı”¡§D¦*!Z7–jp%o·öÕ·äÚk0“¥``àX±æÉ¯
µ%aOØÇÿ2àG	V|>~$QZ¦öa]í¬.Hb›7÷‡à[şı,×}I \é"…VóÌ—¥Ô¸:Ã¢¤Aºä}Şv)|è.6<õ°h.³Æm
÷Ù}ƒµa~Ú¹œ7`½ùbbfÿbŞÚ‘Á-ZË\Š$4;ô	‡Wƒ0ÈSı¶¦TjG3××¨§Rç±‚Ò+ 0âüIû1Mè’u“Ø¥édÒŒİÆiÙV¸ÒÒØ—ešRCıº+ÄÄkN¸-Uû¶ó4kd{“}/ãBá³J§)r¹¤î³´fÆ–‹6»À]Í+²uĞË4oıøŸ¨ó±#ó|Û¼ÆÍXÚíé•›N·«tœHôäB[Ûı¡+e‰t5¾ÖÆ}x«wÃD&²ù<r‰+IùÚšËhÈ£äŸ$sà@ıYoĞkÖÓ¤± TIÅaJ®SwÒeï6Ú õhÇP×Îgz´ÂÈfÖÚlÇKlF%µÔ_qÙ¡;|e(ÔrfT?ªG9Æô€
VıuNçq.Svo0'"Š	¢ú¢A­U¤ÒÎdÆkY¬\UŸ,àòt]Ö'W©Î²¢Ô“Züo¢ÊäïQÂôFËê’”.zÁk¹S;|°U¯¹G@Rt×Tr¾tşá	Æ+èçfØt1îµ¥?°FÁ½Vè¤L–*‘“øc³_x6DÕfåíRn¼%ïT|‹¤Fç®±Ü´ÇĞËö•S_-–ÒJ…—‹¤´ÔÛ°âE&[éˆ3(ısè±Ô!uéAm=º”C–ı0R­h¥†ˆçİd¨CˆHÀ]íQ¸í 7"1xÅXhïI/'N±âÒ+gØÛÒt“í«ÇİsqÜsDeu\–IH‡hÓ4Pvñ¶>îÓpĞ'Öeòm#òº#õ6ŸØ½=Å¼v‰gmŞ†Ï~<8!Ş„N–1†áAšóñX4wA:q?×å› <uÂä®"ödÏú6¶|Æ„£Ğ5gqNÄVêŞW@%-æ˜6í3¤ºŞÄìÍ¤¡;bv?ÈŒF©œæk—È½&Ş£Á&Ô¬,šyG”Y°z½Eå´0ÇwÚùä¯ø^)>L½Lf\HÒŸ­
oF·¨æ·ÈFÅ2ÉUú–qVøp”ĞhÅv§şò³KÕ²ïæÇn·†û•„j[vHJÜE¾¬?óNÒs.¬î,µõÆ£0†çºĞ/Š¡gyÕKşšÈPÏÂÏÇ®Ï™êdÂŸu&&€z-}>”gµ&C%óáB±=ÑÚmÃÊ8HiÜñÑº£xFcZ#‘,Kİt7’±öv€³ÒÊªD$IŠÔÃaøi¿'gôƒT&¸Œı¸IÅù¹vÎ	3Ñöí9x04Ï“uì¹ÈÖ[G•}Ñ)ˆm™…}$QØªUŸé)²ı®F	R˜‡súMû®¿jht•L)İG×Uæ¿À÷?Âoº~Ç›>ŒÅ‘Æõ{‰?ëø¬©‚ÛâëP¸¬3 ¶µnÙÃÀëÖ
éÉ°Æ®î½ ko×d–Ó÷Á²Ö—yAMAÖæå€6[±®çAÌXo&Ík‚‚³á=M-´‰¦1ŞÀt±$åø»ƒıĞ¦PfH`CÆ
›M:Ùğ¦í»ÚÈ=ºÃİq“IË.û„r’ğuOS¦˜N@ø÷êü?bŠ’‘„PÛ±ÎOë‚ğ£Ù4Ş1ïøqŒHª•¸Ã–V„(OÜTˆÚ
örª+ix¢õgØ¤×æP9Ï¤$4´ãƒ*bZ€IÅ8t{øÏ„²Î{_TJqv·4YÃ%«Õ­»p ?@¥TGÅßbw¬®¢ùç ×A4(²tfS’o…4šğã­ ÙøÖ”x°dáKzÙ+×‰»SúĞâoàwû
È`–(¦y!­ı|íÅ{j%ğ)Ó/Ïç>¢‹#éãWî?r¡“œÊ!ìÚ;©HÇ”ş*€*¦{²Izª’8}˜ ÓEÀm†Æƒ,°×qÌáhşÊ 11`9×P±2ì[Z3ıIóª 7¢	Å¦n­kÌ£İf`*(-“öˆÌ*g'qè|ïÎÈß@rú1uµ•&wq!í,=¨1|9t­m›ˆô²Å&L$©®çØDÜ/¡˜/Òôœ:Æü;¨ÿ®š5¡¶Öí]·‘Â¾ã'¹×=>Cg,˜çW¾%öÓÓ?…k»l8İ™WëÊxcëÚxó{]]…X4x¼G»Iøªu
Ëü6…Ùãs}Üi $äÃßR» ƒF¦	âcT$4şÑê! ÈYËdÏöQÙ‡ï‰Óİp8)iæ]…ñú’¿Oõu@E/´PgìptÍ–¢(aÄ#Kñ|¥B™»„k¸*³W÷5kA
W¢™’Fˆš›#ÊêÀôÓ¢]>X‹ÓÙ•B=ÔŠ°sYGŸú@ MªğDÏ‹-İ2Ì}søB. –*p'¢ªƒ\üÍJG*O*:”˜J%ÎÔV?ÕvBAİKƒË?ë´L‡P^¯»ÄyyídĞ8§ñ™<Ïş¯Ş—ãÿDBSPò)"C`Ç€Xªg÷E|:.ûc2·äşFğ(*úŒÁÄ°d&Æ×MB›šLÿó‹9äz?!ÊÚC´,à˜üääõ³BÖü/ŒÛò0«ˆL/å$„:…‹cR¼¹]ıÇ	±c_–Í‘¹<X}~bãPª¶Ê@µG¥`yè[Ñª¶›ïøªÔÿ‘8uº3Î3u8ìßZ`­|Ô–'LäÌù4j0+“6ˆx‘ y)-Pùf
I¥^™Ävr(ıMRÂªL_ëÑK †«p=	Î—?n!È`½m§…ñy–pñóë×!+¥ªy9H »ìÿÕ“‘Oû1è·[å˜ÎsXî©+ˆm$f?	è÷	›–ğ¥µUrq|=2®W@)şwÿ‰ÇèĞÒ|“·Yhšöi;#çÁûÏOÉ¡OÄá)Ê ´¡»“@P½,Ld’Û+	<ØÙ&L2R9‡5lÀüä!è¢Ì¬ßŞÄXñRM©€7èüói<mïëÍ.ÁJL'{&Èşªñ¡¡ñ!5‹Ù¦Ç	BPô61şŸwh¶›šºšxÑ1eÅN÷.ó•ÊWF‰áîJ=r.dÊæ„pò^ñœerÔj¨{##ÈÂ_Zq[† HĞFR("xå–W®ÖÛ)¼d¦ Y:Ë8+a>„€Âb®\áÂ‹8¢Â>QöT),!¥B˜<y½òÑÑ	NÂÕp*cÏ¥ozf{ß‚”
Oe'Sr‹iu|½ë:Ùğ­¨#çl+.CóØ|ÚUl"ÿ£Ê§ó—¾Œæ3Åªó®@…‰ÈÒ÷iÏD¡„YnåÂ¢œšÑÚº§ÀxúW3äË~`±À´³şKºdI7àÃ$Áõ$ìI¶Ş|!=\|§ÏÚ¼!¶Ù¢ˆFòş¬b2šM]ë“µ…÷H7Ï8`$q‹DD v§¡7
ÁÇ®T’²~ö’ÉéuuŞš„$jRh‘ùcH\­ÕÖªŞqTÿ]q|´”rõ‘d„o€ÉC–µv[—ò
ÿ]eìü@¡ÓlšUº†¸eæHˆ]"ºeßº¶bt(Ì0‚ÇLÀV˜ŸG7@?xWŞ1p”Ú)!îëÊ-FæÅ°7Û¼Y9¶½ı’èÄı|è6²7–¬ßàlJã˜Ô:Øª,Áì°}û ÓŠa^x ?W4µe v¤³£¡åSe66†jDÆj•O€"`\•=İğYöXvßÇßÀg*{ŸİñÇ EŞÔMêËA£‚m :©ÉQÆ)z¥s;ë)®?Ü‘Gˆiß‚qlÄq«-„9XEcB€CŠ\ø:o:__ß[ÕÙñUï²µ/Š«…ÊF'™•Û +Ù}8Ìåé¦3ƒí7Ñƒ)"¿iG¨hó†Œ1×N©‹½õĞ…Ê™]	ŞC‡ñú"aÔRÓu‰øÄŠØ˜¥eŠc,ázÜã‚`Û@˜Óc>¿]o¤šĞ6f.¯ÌÔædäöÉªóeôCtË®UôğºHXz œ0šĞÇÿé·ÿŠ'kBÜ¿PË×iÔjNqzËœ¶Úú$^v¿^Ö‡ğÌWÊÍ-Uœ©·iÎª[<
à³rlxPLBaâºj¬7é_Œv¦€³Š¼ğÃv")(6Â¶ºo5"‹]õ–rH²œêbZó›´ä–bƒ#´¿^û¿\ÅÈÓ;ã¶x’ãQUU€	`{ĞFµ²¥íÄ©ó1‹4—±”:¸|³ûz^*9^¥æèí´eË{ÃÇ Q«Ì)`®+p•7ˆò=ğ|=,®ìÙÉV3'®’5­«JL4îVÂ\;ØZàUßá¿¬]­W‘¯×±_¶T¢	Ú™ø®®\NÂ{Wo›û©ªkN0^k³ğéd11®-­«Î
éÒ*¾å3F³ãkŒÿt ¾É@<:·Gqç°+4îº”±QõƒìOVôóÂ1	µˆ‡Şõ wî@X›?ØVĞ6´JëBp´$Æ×Æ%Ìnôü˜|’É³ùŒÚÕQ0‘ÌgcqÊCdío3Æ6WÊ„NöÚÿOÒ4™¾¶Õ´_ Œ	_ŞÎ±Äê[ªÉä¦L‡ë8µ0K*îø¡ ñ¿Êy(&·AAù‰©Èpò”]Ì·¾!â×*8x¾.,#3MéXÂüü@Ğ‚oR¡Ec»:­÷mÓÅ+®ö¦ÚfÑ±ÁÎ¯Ö¢ÊRˆÖØ?ìh)O¸n\èH‡i€}SK¸Zxløã;A
+§9Ë¢Ú.Ğ¶ÉcmÜ›NGpıoC ’/—ÿ…XS»ÏÕè¿1xXº]ùr—{³¸W3L!OYûv“Œ¢–©OÌ²
©t)ıásÿ}˜ü½_KÎ†”(¶ıÉÙœ ŞÏr9ÇÅti¼fŒÍ†’ã“&ç¸®Æ-;d sàm¦qEŞúh@ü6«.æ²8\»‡ënRõ"1íµEr aıa¿–ÖŒQˆ$ùŒÑ2ZØ; '#,:¢g³0;bÎqR¶ óÈøİÔÖcHt|}¯’¿*0ú~å/vKìá÷3Óå2ùNrïvÑ±¢…1TR»Û>½R? ¢sWáÍD£Ìvx³Î_A%|iŒşŒÏàt{C‘±[îRXˆÅÎÃõZL©G†8s„¾¹î¥N8ŒM`S5#p¥1¼UòĞ˜‘)!uA¼ù'Ìeß¤]Öâİ×JCÏ—}a Áe¬YµY_Ü‘©©ÔõÀhRèÑä…êÄB´ŒEÜ|±ÚDØ˜Eğ¶12™}‘Ğœ€_³MÜÌ%OHè(>rƒr#;ÉÔkWiL`UÁknrGĞ"VÜ€ûeu/J&æ1ø¸İP‘^wh´ÓŠ‚ÌOƒàpoOYçƒå+¦Á3jvaßíüOëÑ´¬÷ñäDCXOi,ií8£ÂÛ}·?ö-»²QS^*«×goJW	Î•§4÷;ÖFĞ1+fí™’ÖtÇ!WQ4]säKuH`úWöGç	AƒY€lr8ë§_«•÷zä€lÖ^X3W	XyÅs—½†C‘úÛm|€;‚Û×´•i7,«óİ–ŒÇãzzÎ8¬ì
ç–[í 3yÎ=yC'åÒõºC(c„îÛ.0 U7M@½ª§¤ˆÜ(éA9KÙ.%Èmß÷ Û“”
-¾LÍH—]ÃØ¸1Ocxó
·˜HëşÄ/dô™g9lãJnöÄ²_²uwÅy$Àj’ç1ïº«Jpˆgk±²M8ÊpB˜T'á˜¾RÁ„,`ô‚«öÔñŒŠ5í¶v0¨kNî5éUT¸BµÛ$åİQ(ı<Tv‹³ÔË´»r xÖÕzN!0x©üªŸ™‡tQÁhSà¢¹İ!‘jıÙPàÔ¯ïÁ‹S	°‡>y<£’Ş¢L–¬ºÚz÷jlk{ÇŸ=f§/NfîÎİÕ­f-Æ>æ,‘ßuÌ,%•ŞM¹Ú„‡ËP·V8¢Š§ÚBMÈÒŠ	ÜªDêÃo1Ô¿Ù· Jï²_y÷	ÖLG.c¤óP›?,©“4WÉR”Ù
ÂaÈ’‰‡÷W7ÃØ³·i’CÔÈ¸ƒJfkÒ_Vk^PÈ#–Ìo«$8Î“¸hÆ“=nÄ®yˆÑwÁA'¢º¸rY·ÂÄ½@ô‘¢>ûéQ¤Jğ\lÓ¥‡ÏŠ^æ…û,µ5i‰Ô‚¾êí»Äu¦eá?mÃK›OÔàû`$·Jàó?™vy6Š{’'´é@Çí£û‚Öèe}So<ƒVë PQ×Y6 )€å%Êµ:ĞV/C2/ˆ˜hºşC*ÑEµÕB¨ã‡±OÊq1ÿ~°İHb•7yÍ)'…NæÖØ~.5JÎ‡ê,ó÷¸^Í¦ÆTşğEõ‹á3sÿŒ¨N\´ñìôü–R‡‘OŠ(ÂöªT8E´ñ÷‹h‘š ZÉ˜ø-}¥Ÿ\	»ÆæÆ+½a¯à"÷ËNh7}u$Şmıt ğ‰Yo4muüª.›=¯¹²çc¹"8ÿi¡‚€0µ…*CYôdzt°	âöR_‰SÕiÆqs–pÆŒ§&jdîÏMqˆecEšDÔ"¨48	ªPæ©OHH,“Úü[°tÊ34v­S’]"˜`”ZúÎª¾A!ä(fñyÙùá·:ƒğ{³»l-¶<(WÛúBÃÏ{Š	a©rÍO †<eP€.Y·håpYtoÏæ®œW³€ïÚÔl?åó¹ª»ó<H•#³`˜»ÖÑªLLqVƒR×¢®¤cØŞ²ƒEA”\25†ã]AŠ†È²	Cû˜?ê~S¾iMÈ¹ !©Vft±	•(úW‰ÁÊU;û=¿Ü°wpKşêŞ~İ(¿„3nFçÆJ­‹œÀ H½œÏI9TŠA3«2™gˆâ	¡©y^Õ	]Á@?èŠ
ÍDd+˜ÓŠÙ€H“GMÄÅ?e4é•UŸ „í RáZ¤ÚiØ6¸¦…A'O,©oEàL¼y›x†VÅ"†¢-ÊòÌM«Ù”ôpïÀäœD.ÿ{cçÕÇ\'¬cŒ2'½®]Uğl‡şîuïÀˆÍ
¡$oÑ,{FA~É‘>ùÒi}ÜàNLŠâs×çDCšfÄjùqèSĞ‡ò?ZqûldüjĞˆ<à½¸™É0ğ·]ß”·ÛÁ
YG¬Vå¯ê]„bÃ7i¨àC¥¸§'?Oó(°ì"¦ƒ÷E¹ïœN§ß;jÈpØÌt7†ûRŞåõ|e/Á„¬óYzˆ‚¹„nSÂT0{SµÁ'U+ó6Á¼¸ø¤sÚŞÄT‡? ¬ikjöÉÜ‚„üJŠÉ&å}Ç¹ŞäîÄ÷ê¹ğ4.ì©i”’9ç®‰9G#[=0N‚Ø¦ñÕYº€‡fĞ€Ü?E¤ë::¸IÉ4§~¹OƒÆl£ğÚåâ‚2X’6¬×Şöu~x†`$óºÍ§%ç8ùš‰Â'ÖËe`õ?Lîç_dâd—i
ÙÏŸÖÿ«b¡'‘OObAÛòô¢¥İÊæ&Gˆë#›G–[+Ûì¢ÑJëne¡§õ¸ƒª²ÃïÜıT8Bí!ì«U¿\™ÎvÏaş»ã6 .ç•6ÿ·G¹‹g±…e¸îHuİäÍ’·š‡uåItºoíéI³Ú 2Ï	û›ıú­ò²;nwV5÷‰²ŒàeC\ÍñK¯Ê–+®
ƒÄ¦&'ú»psĞª³#}3ø†´€Z[«Á¾”r†9ßµILù#¬ß­x™ÄQ’@ ?ÊPiCèi‹4ştíD3y·1³)è;k›Ã“cwmâ^zpÌ¤CÏîUÁ›Ös˜4¾J½¯}bŒ)é{j0Áçö6kñ&h0°ağÒZƒ¤uë³íGP.cË“wU_ƒC¸zÍşmAmÊo!‰¤5Nÿ}ºo7ğ—"M?!ûj/ÌaÒ/n¡>zË¤Âè…§}#ê÷‡[£¤qîôjÄ·*µÊ÷mŠKL!˜}]ô:j"{ş§n¯ÄÌ‘ÀHˆÈWéEï·` ®u}÷jTM´4ÅZä4mH‹0±ª´\‹Š~ÕÎ´XMXî®ÄRGBLõ¿¶Ql–¸ÂØìşeƒ=(;—Õß×«İÈáÏÔÙÒŸ?moæè4)‡½~«Æ™ä{«Ë9›²CºvÄ«;5;:Ó™ø(î›¯R0:bš²V&Lï§ƒÃ—ßĞsà#_B”Ñ„R·¯WÜz6íOªzdµóÍ8Jğ¬:3*ªùŠF'¹ƒùE\Ş—Iqx4ºP±$iä5¤Ï±\Ó=ã‚-#©#”’2ôÔpšjÖŠe±âÔS™ÿÿï÷¬u…ê§‘C£µF­PmBšK#«•3OŞĞ?…Mo	TœhÜš§?>f0êöª”?‡%Ûn¢ ½›±!›Ê]85:Ù!±h•Ü>Œ>:ë+­¥‡%"ĞÌü’|•Ñ;NÍ„õ»¢ı‰‘¬—ŠGËiZN0éê¢S'[“¾L‰5 °é}ì‚NrZéÒ9c„ššK¬*@BvgWSİáb”4f1vôòÈd£®zz-U";gå^³û©ıÜ+;ıR@®8íw)$Í´~hÃç7Ï `t³
È"’¾ÆÜÓkëc:6`¹á~µ”cs|å‹C|Ë´Ç¬“­yŞ0øX@;mÈÒäkç•ïURã¯Ê¿è…_¦„lÀåqÎ¦/ÄnKİ–f'ŠÃÖÁVš‰+>?0@!ÑúI?Vƒûõ$“'Ì_àyOm_¥—Sûe[^à…²f¡¾QßÖÏO›¥óFØ ¦5ÁA[B¤+œÿÇşa&ÕESmzê€øYK³?+cp˜à£º·³ç×ºfÍ¦–T"§$°ïSsû@H…ÂğMÆ c–>ÓF¥Ûn¡ôh‰êõ•|‡]Êo£E„_Œ\î÷7t£ë\G˜¶ŒÍÀÉşjT†cRÎ74>	ã3ÿğ…DŞË(wIL¨2.MËºâÔ}ÅQËïû[\“­©/ØDß	L#°•qÑ	Ây÷VWÉ9ÿÜê©pfÎ#üæ¢aÒ£ª8VlfŠ F¨şùît-Ş6‚wé‘À•k<Ë–Ö‚É7™œrÿÍHÖº’Ï…û¯Å­#Ã’ï&4Ä9ö&åI’Šhà“\nFÇó”§fÁë¹yÇ:‡fˆY¯¯ÎèÍ¥÷:ñnÄ‘K}Vò"#Á<…†rN 6ØEPç¬!ïÅ+ÒVæv9Ÿ2¶5fÍÌ_Ç’€yœÎÁvöó,^ƒ·¢­3\0|×(kıoÌ¿h”cÈŒcöÅrmë`£Kˆ_ÌbvÇ|1fDº¾ªóc³ü)vÃå®æªØûA°¼{•Ã…LÎë¬jÙUg/ù.WVl`·É2zïÊ¯»ü$+¡ôE»š5‘rÒñu£NÃø O²!Hız8ĞÀf¼ÑÎœ‘dïQBàx ¤déìşõe”+ÏĞ™|™¡` Tòª«ğCé:[‚Ş.7¸¾íÀÓOÂöúÏ­³¬…Fgq×´T
'dó¥fH~$>Œ*âàÄX©ÏMk§éúí©©H˜~İİMD—7MrÜ÷­Ê° Y•)ÊWK›œè°:†´š*_‰X·•¸°ÆGæ¾hŸÚóDÍäÅW¯´MÒ÷zÍÉ¹ïZt%@l!ì÷‘˜mî'ŞÅÎ‘ıÛtmXÿ/kXJSìdÔ×[&vù-dl-nK†8åDØC°=ÄÉSo_ê„¡¾íù‰Çè–½&A‹öâbõşP“‰áïÀZh+ëQÇÔ‹ô/:KzE–)mÆúFrb.yK•'òykÑC$#Œ*àû s_ó?¥ÜX}|Ù6 {Wÿúäˆ¼Û¿AÃQ{³[*p¼–¨?šèÍ
©­W_ViX%Æ¬q’ÜñS4Æ¯ƒî
zÁ—÷=É×Š9º]xI+„ôFÿĞ!óâiRe‰•R–u¥ dĞî8	ZÇËV#hù^;ÉÑN"+o”ıTÅ-°§µ1œ]¹l›ØÊvëB“%ê+’?(d¥yÍ‡Òí%Ñ–Çá¦z231ß%¶*êx²»ì{2AªÎ±v@Ò¶A¿B×Ğ‚§oG[Jmb¸)Fƒ2õ° ƒÒÙä°Q=Z¹Nc81¨
zÙ&“< C³Ó ¬ãÊ[^³xKu›n~L¶’g˜ŸZv½ìôÁßŒ#6ÆmF},$äe‹„¼ÓBXŒŞ½Ÿ[Z\á=:’hE“´Ú&½9R•¯A}ÙÙÔVüíXdÖÁÓï‘µ1e¼*}2ù”0–ÖZºSAƒ9ÎÀ'¨3ºJ¥ù¦şí9‰.ÔF6i`9a¾(ì`"	å/£7ĞÄÙåÃm#ş±,5v6ÌGå²Inº‡şq…Ö„‹Sç¬Âõç]!95ÚnN¾mêò.¶9à8zOŒûÉ‹+¨§¿ğ•Od¤“v´Î!ˆ¿ïqÍDj®kÓò¨Â'¦;wÜ£~ELìòšŠºîtRß_=!	¹¼Ò—+kE“[~j˜º£9Š‹¯ıÍµ*®n|QÊ¤µØá@‹öÆÆéêkOqf»…ü+ä^zÁÉWJŸ«³#SäÂÈ\şùmdsá.~R£@ºH–mÅÃH°üèáîMY;¶„.LMí
ÜUf¨Æİd(ÚİK¥İşÂEÅ¡¥’qc·\>eÿq-S†òº5U"†“ÌêÀóˆT`eÆg Õs$e·#4N;½yàS†1qI²±Óåp§[×º<ªoÿóÕoøğÍ#.ÇN€ADmVbá„]ÉÎF³0Øˆ÷i=:ZöamÅÁ6±T²¢g¬"nDÇÌÊÁ…zä“¼ÅædD¤~²áQèõ“ÿìÆ6}á¾§à€H&×KĞĞ«Kj„/E·?'>Œë:qôä1-mt`Ëî¢qé+?V©õÑÔ§ºwÌÀaô­C_?ï½_æ<pûr$Nú÷WÊÃ¼uÄõÏ‡–‰»­µ
Á¨1õyFaœvRÅ9˜¥’w®Qd#Ôl‰»×@&µI›&ßé~"YÚ°JàÓóÉ>9Ú+& mâÉ¨VF‘VwI DĞİ=¼ÔÚï ¹Z_ÂŒqş·ã„^Jb\‹N¯ÈÑ—ïÉôÉ€§MPbY\M6Ù^õO^œ3›îíŒw™>Tn¿RıÈø-€ÃÚ†¼!ûì‚©#Áì~zöcÎÒúB)?g”\ÔM½À† 

uš&qh†Ø´U‘Ö1+MYR[Q˜ÁR
³]z­÷ÿßı}y÷‡À[›\1 ã^FŸŞ¿&¿õJ *4»Œì‚‘vßÓ÷'3¬zÏÖ¢î»œ<wõ±ŸÅãÚ$!Èó©'=?}•şŒO^ö™†2ğ4mFÀï[i»NTûœ³ëûËôß]s‘d"`-Râµ’øyãùJ+äƒ°3Ü´Ÿ”cµSq{”5Ö˜ô+±ÇRlCú?ï9N”'f	æÇPÍ	\„šfq§z×£áÇå	›Š`HIñ¦ª¶£ğ÷0ØÀ~—îa¤ˆNsWF»Ù+Ø¿À	-3e-ÙÎW·în¹„ú¯JB|p!Ôa°¼–†eHsj#ù´±-ùßæ„Î¡àsd5y^ó•²Ü™Ì„M—¥õ(­x—×˜í‰_•œcqnøÚßfuÆ6À;¨‚]ÎBá"ª{·õå®J¡<Ó§½âÔ ¶.På%ûN”84Ë¡!ş½Bÿ„íÀ•]íUõˆ5(ü‡B¼åäc)æ›zš5g·_4 ôÚ>vIÈ&‡ß»¥Ü×Ô{ãÙkÆÛ†Âs MrÿÑãvÙ“’2¦©©Q]ıi© CWµ›ê¼Ä~*ùYú{—sÏ5ƒ+µò:2ì©É¯Ø•ãc¾Ào#«ª…<"ƒÔBèÖˆß`¸òãÁ?·\:&Â9î·]Oİ‚óPò}ğä\ú;~g€©“í“TÚ#‘M7UÚ³_@g#9X„°“øá¿P·hà’ŸtáÑÛÏ…gUãŞçu§{hİ®©ñÈß^'ŠOd*¶Å°m¤¥ïĞŠ7v8>ºŒe<».¢n­@ñ*¢áø=<Ö04SÜÁñ=‡ÿ£À}r`´¹õK<ÇN$dŞ&i†©×sÚÖ†²˜óu15ğ›­fÁi•9c{òwÜãÅ¨Õ´ÊíÍôŞı´î…€d§G8Ü=í\æ½¤…Jkql/Iå¤*»c:÷â[cóÆ›î;I¦:×`•%Í<×{	ˆtÉTMïa¡)]w+…‘úá;b}$°Êl]¿¦h•ïWıKÇá,uÀ”‘¥Ñ¯á e~ç%c1Òœ7ßw!3Nbz³hÄ…$<*ºÒ1† aöşA˜Æ0ÿµ[@¼c8IİÑ5G.v}¥+ã@2ì–-a´~ÇqìÚôù¯äu’¥®ŸGÄÒ’›±kH²…Zçİçz„60( ©Ğójí{ß½¢Ç†ıxO<œ¯<ßnüB4¡õÿN)•¢º3ufâ+`×µbÿŞf×¼ëd’Ì7_ègÎÛÚ÷«Ëoôª§ï#¢æ+—béH…çö›‹Â_3ëVºÈíNO‰xƒ%ôX Ã[Úo`äÖ¶:èÊ8¢öú¯.3SL”ƒêì ¦4fU0<â2âdñ2âÑ¦6®a÷·ÛnyEmÁº<¿(¾SÒoæ /#O2œô¤b³úZ¶GÇh{a„UÈ^ø{r%zÓELV‹=£xIù1«ëïjUÜS½_Jz\JmgBE~t åØ2ZXPjkøs@AŠˆ ¬1à_¶	qg¡{†¼k‰§ò×`Ò­a”ÆìkgÊ8váÓï¼9èMk2åo‘_j¬&İÅ@—ÙÊbšb‰³”ôD9<Ÿçş¦ÜEÅªÃYºé¡sn4F3KêÁ(%g¶\…ş¶GÏÀ›BÚ“h”ÍçÇQY)ÛıÈps¤>®Ü€ûZ9mnÚjˆAöf»“­ò£h²‘wuRÕ`)Cèò®'¸h™>¿ïçíU¿û¹˜nãˆáí=põ¢üIcÉmà;@ÃWNÈ‘Ö6ºÓÜÀpg\šÓ›«à¬±Rå z!¹&–Ş$«×ú…·[¨Å¤äíK=? ¢Gy9Ù?ÊI-âösèİEâO§ØÜÖi”·ÔxÄokë('ìr8mhOÁL;ÚÎ^Ço2¥ì³póí7LlC)ş1ì«³„VºOj'¦©îíX¸I?Á&5Í©bcïcIç]vIK°98İF¡f>VÈáÿî¢»(Í„–ß:Ô'(XG1:ÏÚŞT¾ÌC—ßš;â	'*Ä½–×M½q—ƒ£ ğJUå{àmez4gœ|¼)ZfB78,ĞõÒaIÚÅ#Wt*'%Ï+Y+GeÈËŸ£'kí½*C¥ÉcÜÛôÎïÚ³+×KÆXn¿Ñ·PƒßQ,¦æsŸW²'™ÃArw*A¿R&°§<WÛîR&Ê9şaÊÀIï•É¾C	Î![éÊ34oºX0TÇu‘™€ºev2&'ÄÒÓ)êúLS]­î½&îşæ—¸i:áç&ÕIöR¾±‚ğÉYAæYñ³HÁ‘ÙmRhHÌl=U-ëÌUCeÁñ˜"ÒŒ|Çš#èğhÆ‡ñøğ/ŠTèP-½éæ¦¿F0x¦·Çï *SÇ°H.Œ×Ôƒ`Rj‘Í`ïknÃóµDÓ]Ñğış€ÍRf{‹$0F<TÌ MÄ³v±L–"î0!JÌDü;½Æ¾lã¦::â˜XÈ	lç7âŒ²`¿êÄ­»ğïGÜ„8Ú°ĞÑÕdPÊœê¶–ºÄÁü]‡é:Óe*ãù<ZÉe«3XÿW§}-z…§<÷ğæâ^uX)Ä±=–kâÀ#ÒW0s©ıT†!C?‘Ñ?­5·ÅùòËİ¿ŠÀ¼bº Ï™P7û"µSV®ÌSºP§óuÿŠçÌ^÷aÊÏØ.LºAª¯qÜú¶ô_1ê¬ôƒPÚ×¥Èm'$y~YXp¯äp‹$˜åáÈAÑàC2³	G·ç]£šxR¼{52tğ“˜uúkóñYÇÑÌŞ.=‰{©Èï„hj¢OKÒTêlğz2şéHFwjeLqU¹h€Lû1Ï„ğï(’GgCƒUsÆùZaœxåÈmÕ…F8œ¼ilîg
¨ oÓ› B®ƒ)t¸|(!0êÖ°§1+ÄLÿÛd6V¨À”YÚğ6q©õÁ8•_Ÿ1Àçvv¼%>2[ùó-Ê«}…ø¿uKÆü´K2F‚=ñ{Á‚+ÓÄÒ-ÒÔ:õJÆèb?= œ®bÔ÷ğ“IW-{¸•Ê5ÚT‹Y¿Tş!tj¬â«b  `áôà°n ‹±€ğ)Ó>±Ägû    YZ