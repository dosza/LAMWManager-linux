#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3865205926"
MD5="2af1ac3add663113f44832cbec6b9507"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24540"
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
	echo Uncompressed size: 176 KB
	echo Compression: xz
	echo Date of packaging: Sun Nov 14 20:13:51 -03 2021
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
	echo OLDUSIZE=176
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
	MS_Printf "About to extract 176 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 176; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (176 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ_™] ¼}•À1Dd]‡Á›PætİFÎUp)2\Zô#ÚWÆêeyâ"ŒEü
©ær_Áå¹î§²õğ¦ëİ*uUÀ8d/S
Â¤mı4òo˜>—+­á
x@@¾S
•J«L“—*é•ÿ³AˆŞé‡VŞc%i…\ÆR<¼û¥G’|Õ¨Œqìµç5˜êü×ñY$E¦_†eãnMuFöJ9Çîh\ƒÕ3ƒm©¡Èâ%›˜C÷˜IBV1_WÜ#¶	¯rêÁx”< ØÓl5¹ipŸ‹R‡ç#~Íİğó0úè¾íûÅĞ–×Dä¼UáÒ§‰"]Yl†H¶—cÆ'ßÊIÉ…«i’Ë£n Q L€ò‘f–,[Ò	·™óL~èÖ6xL[šÒ®H7¹/ğ%gÎ‡SnFg®m0.åYRàÄ'‡ÂI²Pc# Ö=˜SCçj^Àî0¾^Í,¿“òó¿òsİ]+É’¦Y ÂWÍ	ğÜ¤İ/1¹Rıf×£„‚‚ùù–láß¡@ĞQGXĞÃ–è‡oš×aÙÈtoMïç‘	 ”ÙÃae)¸S%/U"í&Wå·:ubéÒŸn` #î¬Š5>¢hËzVÙûˆÛ96Cy7tyÔÅ¬$È‰4QEÎlØ9DtŠg%<íìv+ÿ¥è"n¯ôÕp >p@‹*NëìJkûüÄ‘hÈ×™°üºŠ Gç¾’™´oÕîñŒ‰üìM–ÖÍVœÃÔ˜ÜUšp–¦t)°aj²ë”/VQ½±,ªM6tƒ	éQrù°>ÒÉÃªÑò}¨Ñåurô7¦¥ß£éø0~~ıRIÁtú^³Æ‹/*ù4£*ˆb„¢)ÿÈí\äÒ$0úà÷µÈxñÒ†î[Ë„_‘ÉSÿşon¸íŠ0ä¢,iÚ­é×ƒaò Ûßík=@ƒNW‚xÿ)êO,?(Œ'nÀd2»%¸bi"Iüò€„4¬ùáQU|"nñm›×†KjWè­EüŠÂ	½²WQ¬Tt-@p/º(ÈbˆaßLèG`ÛtæIŠ]És]Äà·c =ì‚ÑÍéHOJì¹<ŠÜCtpı_æê°}ú1	&­“î¸4÷Ó$­@'5¡! ú‘-Œ£/¸1şÂ£9—w0tiB©ÿIòdÒh…b§š€Ô5 O¿Y$nyÊd[WÂ©²‘ğÚşàtØÊ³d£8Ú“ÏÙIÔÙvÍ#ìŠÈBƒm‘{5ù[‹Ÿñ8µ§%Ê…Ö3f¨iÎ”&ãCVH"ÏæPú€&>6MÔeÕmå6¸‡:ä#&êÈÑK¿94	sUã7{qsÎsÓ@6'Öü€ÂØğ{<`È.¢Gu=–•R|¸èü>.şûÑÚ0Åc{ Ê1g€Øª¯Ûé÷{ÄÂ@O{ÂÓğÁ&(²QnÏ&è²ˆít„/8ÏÎL¨	g‘»€ücŠÔ£DÈû›üº%¬f…›ª¹€‡Æ¢bûÇCjAbWØ§Ş L¬J¤û·0ÑtBçïİKrpu0Ù‡àúQş\]¿AF¢tÇæïnáı„é$Cví\Ÿ¬q2+9ÖÁµÏ®kãM:O´I}‹~û]Îš‡³’üÕÀUw[RÉ®rüqMwÿ´äÕ­uÉ‘ëİ±—õQÁ,ñä–x¹éÃ[Œy4ÌÖ¡1„{ñ·ûG ño'iûÄàS™ôÓî%I®U`DâìX/
ì,^Ûu$E²ü¶A9/úÏÀÉtxÕ‘€£`dNÀ%Á†2L3FrÉ˜?°o ïÈB0¥¨u+ïùÕà8£îÔ9¦yío«y½Ìæó·^ÈaıX™n§¿Æ±M#HÜ#yz×Î, î¥€~\"È' üªŞ¤Qåí>ÎÑÔ¯t%°³0ó{…g !»ùö¯b;İ³C3|V†î%$¡wK´’×í™ÄWìPÉòü¾à
ò+R€şpoŞ·Üß˜oŒVF¸ïg.©`ö•qƒ°îuŒ?Ld<Eç#•.`½np#8Öã´4š–ÍºıPi(8²–'ù-'üz§¿w\éV :={ ñoÈÖîo$=J«G=ú²›úîe`ivhğÕÇ4$&İ0X^Zöª@Œ(³ïŒçºÚ¯'%á¾Û§-¤R\æáEÆ`»ÕÅj6ŸÃg÷ÌÉ1§ÅL™’ L\¬£ò/Q™¼E’¼²å°¨X-çÈóŠØ‚F}pTÜ„/×ÆÅáäBYƒD½ù9n8B±+Ó°–áR.c/)pò¨áô,">
TKàZõû¤mÃ
ä½ıx•7T
ÈÃ/•¾‚azÙˆkÙñ?ùc2­ûAa™hØ¬P€õàÓ‚¼F|¡ tÄ‘”Öâÿ,$:Zí+Ê¨?Ô™2DÓF ˆ{¹…–VŸS‹3G¾³B`Š:îëÜO.AßĞy‹rIYItÇ•¶©–Í&üæ• Ó>©s›!ß@‘«ºõ·W£w¤æè78Mü¨2À5F´ñ\ Ï[Ğ.@A’ˆø€n)ºä8ÁöjÓƒ’:<(êÛQK|*ø,’[eóräQÎU54¶ç(6Yï“²Ëˆf×üå v9!yyËXH“SÊ ½÷ãB®8&-ôKNÄ/ß|üóÆµ°…?0)øÃÒ\¤“f‡!ò©ÃÈ1ëÔ­¡©Sq›,îa^f,kï€Ò»©ÃRˆù¹9¼CtŒV(5¿e±KBØ·dÍ-ÿóó¾{¿ÉG.êŒ¼ƒÓOjüÃ2!I®>(®œÊ¦{œIäæ•ù†¨têæú>~8d™½¾$ÅNn«.TÓ	“~^¿[’à¤Ñ’tÎÃıOü%‘("kL8ãTLï0ïe‰4‡Rxâ^÷$™÷iâ]rÖË”¡KÈ”
²ŸÏ¢˜¥,s~òŸ5ªFŒÒie åìª`ŠLÌRtß:OY¡ÜéW(P,4¹-\yw¾6 ìŸÉ9û*{1&³™Û˜æèÃ¼“¯Ä9ı-Ëx­¥rI,Ú!Êåá ~µVó.>[çşÙOn òyfêÙ6 öß•0)?$é&+Ì¦~Û'8¨kşGÎñŞ8«5XY‰ë©èôYñ‡njèÜ@h«:fs`6D“PA­–ŞşÕ{_8ÃCÇùÓŒ9ã V©ùF&NßE ëQB|(
ûŒmAKz+ƒÏ!Â}ba®¦ö±JÖÄ÷¸ê§a®ÑWL<‘€@‡á‡6¨Êì>˜{ƒs`÷c²usp2-¥Z*ºdø²XtºGÚAZ2¢c™ĞèÒ/Î·O/++ÙIü2 YBxÄ?¡dà$Bÿ5Ek’Xêk˜›¼à³ÿız>!K­/„òŞ(ç­uÌ¨¯m"#[cÇ@–TXâ-ôy"+ä¿è âşFÏ.k‰«.¿ëköÍ±r#3Á˜n’İM‹´ßvÈ‚¤Ë©0óEØİ¸ó×t¿O@{-U8xå}¯\"O Úæu–Äš,^>« ¾uBÎ—ª²Ï’\Û~Şé}ë•2ûCEhrQMò:(­2ñ”o%{œƒoU—0!KB4…H=`ƒ«ABgÒÙ©@"§q†ÈP­n_LøÂEë{œÁ¡yÖ£2¾ââ«pÙşÒ¦÷sŒ´¶ö¥“‡ÀMÆ{0_Bg†.0‡B&Xë!Ê"ßòÈæ,®Nœ³”o7E_n××âÊ/…Hb†Ó_;û±·K©}=GW=Re¶§gw–{º'›¬çM!·Ïv+4È:A~w<ğÛzšİX(ˆ3hÜ¾Î›8¸÷[¦ñÁg0¼,4ÚßkBSOB]dÅƒŞ	L™ÕG-ŠZAq’—†d§eäÊ3¿ñBÓ=ŒúrÉ85_X_¨1ótÈö»X‹ÙÚ¦M³¯»kn,XI<“hú§§ÉÂä°–*‹»èÇîE&W3)¼H?·„…ä†$1D3İ¼ªEKZq6ğ¼v×˜YÍT³ë8W´+ì*M¢øY”×Z5Ï»3²Oæ|ÖR¼píê¬ì2Ù¡Qi#•µÔ¹góÛ¤öYkÏ{	a"½‡ZÒ[]İvygRğ1”û©Ø‹Îáÿí†‘ü…l;kvĞW÷³Ç‰ù*—¸ïè­C‡µå8e`fF`’‚.à]ß(bí*')ÓÎGŞı6b{Îhº"ˆ²0¦KRF•sÏ¼sFĞ´=‘È›†=
çPøÍ€ìÉZà5<NX¿ë×Pu|»ÄÆÙ”;Ôåc«‚Î'¢Ã’/_9ØÊ\ê¹TÑøkJ‰ƒ0½½½5glkÚäX³3¡”WM<£;Á¬ZÂ¡J8¿ó ºÅ[‡ıZƒù-g3~_Üà¨HM’Œ8e``e
D «á@€r»RƒX ïí’Ï±_P=‰r{Œ6â1êf?pÉÇtÒ˜ô?ƒóùAGrÎ¶Œ–à‹”‹|õAGˆPÎoY<>DºWÏ„»Ô#Ø°½a’Ùzpøá%†$ÛaC”Şf;·¯lœ-x˜›Ùùsv&ıíşšHÑ“|¯.Ç>|7Dú¢ûÑsjûòì!gŒ°¢şZÜÊz¬§Ø/Rá°ÕŒ€4q­I—¢½#pÅ^4P·6ÚA\Ÿä	½¿ùMJxa:<ñÆÑP‹`âòŞ©"Ê„·$TÍu.)Poîbk£(€Á|¸Mı÷NOªêçÇJvÌá®ö b|__HòœH(+r1"¿¬±=[»gÑ¸?İsL…ãb°E˜;“Ì¶Æ`¼´õx‘ı¯SÍ÷íĞôÛo|¼B±²†àB+4`Aïg3±6ÿ0‡‚Fe‘åâ]&$lÚ:ŒÅƒ– RØ»–EêXÄæc~(¿‘Âd¼é$ÒßvtD§Æ¾In¶#Õ¦Ïj$A‘&a·«xê4$í8D¡É&ƒ’¼‘?oIhçãZ¤Eä£B|'>gçóÒV™Š$GÖÅî4cák³ÌÜìiƒv A#§°ñ/©è‚1j<1Ìp9HŞÿòP”˜¸§è¸´v/´]“ß£'%Ñ‰$-|“âj/%ÉY[È˜÷WÇÀéo/ZĞ–È/ôêF÷øŠËˆôaŸ!Ô¶Ç¡Ù²Ş¶®Úì˜0¥Çr‡3ÿ‘Äß'{…ÁÍá³áäq$áS„£‡ñ&(ÈJ=´ní‘-æÛœ¬ÿ—”Û¸~şqX‹«Äÿ1ÓõØ‰•ø2<5;½lŒj¶M‡-.»rr¾&'&ªÕ+¡¢ô|Ó‚©úmeEÓ†W”ÓdÊq†ÒüF÷zˆ}º‚6ßh¢?Ş°”­¤r
&â€®”8ô~b219(¯¦]¿›ÉÁ•Ñ»Š·²ÉÕÄ/t}‘UxÀµ7©Rîh¥‹vaBƒ<¿SçI•Şm»Û¥Ø¸Vì—¿t(!»Òfc‡<ŠöT•WÒr€`/´§Â•ùOÄs-\œ¦(5r1(fí­ŠsÁÔF8ìÎàĞmó˜K:9Šÿáa®L>a]ÁÆ¹rï~bÆQêTM×öN÷˜L¯˜˜€7¤˜'l9è†!Û£ƒˆJÍÏ„9ÜÏï·šìL—L‘õ'¸7l?Í~Û5œÇ›¾Î¾HÒ}³ôê>6zSPì³vf	Õº½UúĞşBÇ0éĞ;>n)‘IÒÉŒËC4–olW¹—ü(“T¶w½„¾·”È®4	~B‚ÀñWÁ\Â®è™4…1àH‡ùë÷Ú³er5ˆ\À›½tFÈ¯Nª›9:nvHßgc¬Û‡îWÿ6Ÿw,İ…ñ—åoñ.¥{î~‡ÿæ™óÁ‹õú±áQ½úà6ù¶*à©ÕôK¦ë±6m¿§¥%çŸÚæößGşÙpìŒJ¯M×å¹c;G“,ÚjGAtƒ4ğ?R÷ù«KMdrjçM Â‹âãÙg2iË˜*F9´	)„ÿD¢,î}9¯'^zA¥¼œW°ãZ1Ğ‰³ÕŸR€@`ñ]˜qV	0;pa=?Ö¿I¥@Ó9§¤•{ª/;v#cóTâ}r¿²l€eù±Q†GĞäZ†;6,›¨¨Ãf>c†ı?Á<|ül¬×éÿ™
·û£¨	ä,|.håÎ)%«-¡Ø"Êû#j¸"P¥ˆÈ~]$k¶.Å|P&Jà:Ï_;?=ÀÖõUruÄ6q€LÿÅ™ß¢Âo\ì1šĞ5ÅÆ&%KÁ¡¥v½‘®-ıA@±şÊ^A¯¦Ğ§šOì‘·.«µÉ·i+y‚µ.t%îÊ¿MëZÊ¹cºCOŞÈV6ÄÄF¸‹‰ÒZÆsí:rbg2Z†Âìô2`¨ÏêûæÁÎè\şÛ<ÑT59‘rŠÚ-æJ¦tÜ'³J;İÈöÃ¢ƒªÂHœŞHƒø–¨ªU@ãCõÏÁµÇújJ×nè÷9°¿VYV¾WR ÉÒ¡Zv<­0B4°F£”Lhv>©©æsÚ×É”ƒ„WRÇ[ú"„ƒjÁı
kd¥’ƒöÃ@ü Q¥Zù;]›çb²]«—CÎ#z}ã/Ê³¹=j±( ©ÆÊ5eĞü‚Áp£ªS¸ÿOe83}vñÂo$«äÄş!5Ilgm©#[û^ =›ç¸‡h ægàKCöï1Ú”÷EÆCJ$ì¯Ex<ì§j¶NÖìŠìH”F ÚŞ"Y`Qº¦«Õß¸³¾TVZï%4ÉRO(Ñ¬Kô0»ËœŸ·p&‘¨?s¬ÀŒ	×Z.¯±ù„lZŞaÕ,¶„Å”ù.WØœo´€ÃmĞÒÙmÊÕ+É·’Šˆ8Mç7Â¢iŸx3:óØ,YœŒ4DÑF76ãA\oIÎ¡=DÂènGyE‡€j!ş“‚
Pcå[l2,%s¹ãf
¤½©¾´s=ÇÛLà:Hi	¹2Öş÷éÙ´[77ë…ç_ok—¼Š~®Ü#8 ÷ÊÆ;ÈŞuJà^	ùëË:¹{¸ˆ_q$¿H5bóÃGÉÜV4n&ôºZ&ôS6¤dêPŒ‚üÎ¼ªÇ<b¡Ætøz‘Taƒ<º|³ÿµÔ÷%™è°eòqs~G¼‹ ºú<şè4Ñ¸ÚL:£µ¢R]R÷°(¿×öë »9¦N˜š¾E˜‘Zİ¦NÂ‰Ä_›¹ÇgÎ[ U}UóĞ4ŞçqUhê&V™V\!mM“œ‘<ËAÜ[Şà·ıGÅ2^Ñ˜¬˜aƒ;«Ø©õ7ÊÿÛ[k4/6p:ësB7–îËÍïûS3ÿ&ƒWGÅ¢K3Ò›²Ç2HÂèrã®úD@Å¢$	$Q>kÄ9Ë÷yD8>w×–XêKİÛ‚­E² zZê½BŸâ‹@´š)–Œ-‘RG£pÈÜ‰QVøÀïàCQ€"@Fü‹ºRİDïo=Dé~=!Æ	NÎM,foòzc6íJ5ákå±u.n—1fÄnMˆ»5B„ó	JÜá9§
õÁ&5â“V•]ÚN¬:¶–|2êª¯Œ†"¡SÒ	ŒÍ6`ùÆ¹„½I½W
Z¦‡œâğÓ³v,g
À\xPÏxn[ngàÓt"Ecõş]rÖ˜.orD_@´Œ‡NArîóª]¡p›k2Ÿ7€·Zy¢R{ôv®ªŒg:§iíeû« p‹¿èüfğÆ›XÂ é‰L'ô\tÀm Ù™ŠàÅòğ·‹iæ¿WJU¸Ş4Øßİ©f
U…tUèzS´iæ$^r«v™£E¿pé~¹‡/¨Ÿß6å˜Ê—­N:­˜
¾îj¼– q‰Ş"Ê"­ëPâ*‚ºöJÕÈVF©­ıÕZerYa?Rm®Kã¼cƒz|3İ‰¨‹›Yğä–t¸®z6×†Iÿıf—)Şâ.…u†_ÚÉE(†r;Qæ=Ü^œ£ĞÁKÑ‘cÙX›‚ˆßÓ¡ûC£	%–¸K~b.)vmÓŸtve°¹†¿|èê¦ÂıèCJüôP@UC,cÉå&—Î?ü	Á8C‘¼Uê^}¾MèßæğOc½Î»Òo£2.ÎÜr™-lœ¦ Ç"6„Nı$`iYJ!ë9¼óİ‚}\øCÊöŠ8íÊKa¹TƒƒYÊ‰Âç»¯lï£‡?}ÏUfÿ¢@x>Ã½ïêdÈØÕ¯Á¾82kÏ#%‹õ9còŒ~b°‘×PÀ?mãx€ÅÍgyæE©UH˜E½_ëW¶Ì˜¢cû«ÀinA?G…˜â$ÍW„ÃNéS³éuc^³)FÀQ»œ®RiWã‘éÉä]›ã‡(SOu)ğW?»gL‘*Îoäá†!0ÖÕÈëù”Š4~ùí.Ü¯9,ø —[õ+Ò‘Şvtq-ñêà”ŒŞï‡/¬GÊ¶òö<ioo‚¹'–ß“ŞÀ:¯:KdğJtñĞ~Mm=ôDÎ•ğı1õ@4)1qòÂöÁôŒÛ:JwT2aëÿKøİ(uòÁĞŞ„Õ+-¬ÿ»5~""Ã™ei´©èGG¹ñ%£² Êë®¬8ˆ#S)Yà{!àª™=@WŠå¢q>I¥¥è<ÔWcìÈåE‚XM1Ëù=‘ß€(¸xËî“İN‰\*B“Ãâ„H;{FCt’_Nw¸ëUÚ eı”TMj¸k›$™Æ<ã³^“‡í®Ón
D‹Âİ¹,îö[…ÜµÇ'>äÊ(B»FúE•Èù³jí˜™ì	á¸-Ã÷‚ï°x´­ëNÅµë2Bù_æÑ¸•—Îo_XJr¶Òc²ƒ()SÜPŸp-‡\WTg\Rçš_™Â ËÆåşv¡°Ò“ò¶Må Bğl6æÃ&Àq\’Œô….¨×2›-™çj,9ág¾Ë\£3¾ÍHu´!Òë«éà
z_
20J®ÑU1_
(
ÙÑ¥x±„!ñÚùyªû{âsGÄ¦éÚÚqö“7—Ê,gÅ÷™ln XGó%†öá­5V0êê"?3_ß£zÛC^ë‰'çŠ£’$»iê¶„Cğ›²¡EÉêI9º¬®µ$é("aÜBÛAî²Ûƒfúñ€¶¦şß¯hÙØ&	£1f8VĞ­â4Ø§{ØØ^Şi¢Ò	Â£WŠÀHÅÚ	Ü^¾F†9’²%¾2†B¥9èmúÌ>B:rÇ2Q!¯Ÿƒ·+gïúÅ7LB'	Ğz_í®ÌÒnÀ…à‰ÆLK«Ü—(·Y¬.²g f)ÄãY/¿ƒêh”†£ËX{/_ıÜ%8È³ø,æ‰ğ™:ÁÁeïx·K‡dD7¿_úGÖ8=ç([g2¤­’´ÍëÚ’d?¼Z@]vûÅ¥ì?}‘YÁQ®¹»âw\5¿)bÃpù½V0ÈáŒ¢Ÿb.ƒ&lJÿ
:¨ı"{í.Ù&ö–Ö/µO}VÅ'Ê"{=Afç«ŒUÿ2Tg08Ù–z‰%ÑãÊ¾{Ìç}èzcÈCck­ƒ-¬[Y0Â<úÓşes*:|}Bèöq*IÅm»‡/H)¨©qvã‘î3ÚÖ7ªï³˜5FõhºŠ¾X…¬ìŠØ.Ş5ù)­—œ<´)'døùĞZ~[/ Ÿ¿ØÕüRR>œ=]»N€ÄËÒ¿´"îí„ÃOy£vç;…ƒR„ë€ËÁÍä¹?ÃåÌÁšGòi}êÖ.™ít~`°cR½/ÅüS¼ú…İ½WÕXî‡iphc¥ÿ Xšk¤ï^Z*7x¹,Ó¬Ğ/eP}|:î¾¡xU1Øzy©¼pë£‚‚¼dªP^Cì ¾è¼Á›¸ß˜€ªÜk?š˜›ã{U‰û‚P|"ßjIõGü9‘heGeAXÆ=ûÜÆ²Òî•uš8ºÏO³÷ä¼´Óğ(<ş”7¾è#ë–9áOÒQåÜÛ{ ØHŞBÁ°æ ‡‘)PhÙÛ 
ûÕ +ùí®¹tA²£A(êŒºvåÉ€D^"„ã…=­ßWÌ«ÑıçSÉÎ^W"Ïv¨Ïz¯µc,óÖ‘2”XØß»…EÓ†EËó”¤Í¬`–?à6È53yÌW¡
\H˜ßˆãÇıõÁNx^ãmµ¡¼‹‚Dé	¿‚Èy?²„QrÛo'CÀø"Ãö›ËbGfÏÒÙ¹dg0·G7İK±rY7éÙ¼*÷Qä“ñ\Ğô\œ×ÖÌ’æ|‚¥OLA£QÓF(Åª™ä=>ù¬ÖQ'½¸¢'Ú¥ÖÎxÿÈ4F •÷ òÆ€´zOBH½Î.ë!f\£uOä¥¨/Á%3É´2m+¥Ô·¯Ûì³Ñ¢§'‹EcwßB´8/b‰ç•ûïÖÜ#™¦â`ÒúëE+Ë”¬ˆµ”İßuJ²ğTM
 Î¾Ôx>©«„D*«S½Ë‹B=ºË6à
X¿İÒòêÕT	¥*âÃ4¼‰ï1X^ÅM.!)Ã&õM(ÓfMãe\Ó>e–ó_¦Ñ¸ÀZ¤äªxndŒ-µİ°|é{Ä×JçR¡½ËÃ{	ô&˜ŞÀ×œúµYÄ†D­<î·3jÀß¡šU¯ğ5aÉÀ³wŞg °÷
™å©µ¾ïÉ!¡ù*uO·;Şb–N”Üšó¢UÕÁ9g8Ï€éıÈ95g`unµ.H¸¦xÊÓA¤7Sv6tBä§(NPÃğ3"’„Ê–wlñ#à§q/İ?™øğÓsDÿğ	¶”şûe	j ÒEŸãšf÷¾u4Ëq#AØ2ÙKl„ÏÒ¥“íÛá`p§l0JÇí+A9Ôœ“óÆËµAÎÑ/5ğ¤£¡tg3Ë>™UZÉãGH;`…bÆÂ?ëz`æšM)”“ğ´‰+ÏÈLåd¤Yyií®¯:ÂDÏ+-‡–ÆÄ6~¶­¶ğ\û¾ôßMùCeQ§[Ô(Z˜¥,DÛ¡ªä5ÏÅ óçİÂpÃÈQù¯kÑÂvhÌ›\Ò¶’zå›^ƒ>ZËf7ød—	ß”ˆ`ÿ¯—+İû—²NÇäŸïeCßªìà·Tå‘ìäà›6}f•ùQX×ğxnNÙPBsJW§Š3ª4µ Í’5÷p&0 @’"`©ªD°Œ=œ•6™ï£õçCË\€Ûåp&¿ÛwıèëX0œìe¥¸6qHàC=š¥
WÃ~:¿&×Ëx§ïğp“«YĞïšÅÉF#vN ­{¦.†ñ¤´¯=F¾í#v„Å™¶†Ck6§Ğ©ÂÒ9Q«¨‚ãÃì¼(ëªèVcYc²tÍa¤Ñò†7or:M•›&û–rx…ûùhÀ”;¹TÏk«¿/¤ïCQŒ½ı{íMtÀPùËkV3ÆEMQU‡cñŞ©1‘¿*R˜TÚH…ôfÆÍÃ<Ö	-ë÷vz¢]!¼vÀŸ!=1æz£“ a1µ»pZ$ëêVîw@»±Hì8>vÒ.¿Â^»cÜíWŞ
¢­Úz÷Št$Fù	ÖüÚ$L
7Aµ:ï_5ÍG§f“âÑ¯A¤w¸Íoâº´1äfw»LaoÆ¿pŠœä¶Ëõ³½”‹Gúpò­ÜûôÄŸß!ÃdQs~41ê %Ùédqß¹[@_°Y8?×¤bŒPåÎÀëû±~¼5„¤èêgíLÓšTr"
¬Yê§G~8`ücûş2ÄÃíúËÔ^7Àâ¡‹1 Ö°
d2Š€È€¨…Ó³1 š§ÕŒêû’&6„$i{KuÛzİö^z¿‚-`âT‚Š8@‚OèPÃá6íòr†€onºèqDVÔocú™ZëÉü…:ûÆùY¨å‹ÃA™d¨ïàpÜd`¹ó¤Á(^şñMôÍŸüÇÏ$Èuür²4ÓkÕ•ÊÚˆÊYˆgÈÈ.ˆFL÷ß'³t1kÙ=¥Å#¢§Pç…`¾»ï”mŠ%ú5Š+A¯`¥s®Ì6 ‹Ô_«ø½¥8z?é‘\WZ¦aêÍu–“Œ….f+ßVú„­”í y-8ƒ4]¬»#^§HÛß‚frÆØ›÷¦T"şúZ/4j«ÜÂlı–¶¾­X)oà¼ü'îd‹ÙMº@ú*†º«ì	‚átA/ºñ×V*qó¼çX§Í«Ìƒÿ9–Ã.İ¥i‚°¥×ÇÓƒÖÄ«T„§}å@ f4–_è&kÿÄQ›djú³úx¿é/šÃõã4‡ôÓÈ’ü¸†±ø²\±<ı#áI,Kø{ô ¦ğìFíàÃ¬$Fev×€F¦Œ¹ ıª9ÃÒ9ñx¼mÏ±v
Ğ!Û÷ğrçyçø¸—œ„ …‘¿§“ÃiAËÖş*kÊ*“£,Mä:·,½ü§_dc‰¼ o;Ìè6&ş×›™º0^âÑ²ğK‰–mêR.FBò^2ÖÎá,3ĞE‰Nu}ãH'g—Êr¡{#pÃ³LºÓkìã1,1ÔáLöğB0™£šX0ÿnŒ/¦•6øêS/CÊÂ!ÎÏ¢t‘‹¾–:ÌëóÒu¦DFÒ\Ò2DéĞä&Ÿëò(€şê¿0á$òKµ]Z|AôÚ„“ã	Aä	Nàïcİ|‡($ğñäÇ™9†¨9rŠ¶Mü’o^L$wÒgŒ@Ş'Ğóôå£e!2ı£…A1 Cƒu˜œôLéç©ê§69¦Œ z]EÑqÛ5¬áHÓ[¿vöÅû{8¡âC¿»ÀîRvî ¶×©œ&¼Yu—¾\îĞ´iMC YèÀúédTjâç¨á‰ãPp	¿oB&úÔBü¾;x}^\ÿÀĞã<eQ»ïÌ¹·PË-MŞ:$-íŒï3ŠşkâĞíà„‰}>×_pf<]*åj"‰Ç\Z"1Á¦|Õó0Ã¹gíZ@yî‚ş×pf¿•7s1T4ˆ{JğaùYoT.¦¨ÆWÙ>:‘Ç®,ZİÚñ£Ï„ä©¯Ä™0å¾‡JË¿ğ "Q”mO§Du
;ãíIg'>Y.–„é±YºsR©¦Jù‚wÏúäxn¿ë´ùãM+?Ğ9ÿ[Í‹3ÃhUcFåéìŒ©@ğ‰­+¤Yÿj…]6ƒgx!±gü€óJ©Ğ®›1¤Ç	1¸Æsè«ºÛÈ»W,F’­5Aşïî;bĞµåŒĞù@å’ÊL_@v(ò3$5l
¨ÎÃİQ%°Å_f*Â×ÚwÎB}õ¿×_©üù$«—¤·`QtÁI®d.úåjŞ« ¡tÙìóQÈô†¤yÜÖ®¥(åqûşâşv#0“<5ƒù¥ˆh Á„İY¶¾Ù…€K?JGüŞ–ŠAóJUÎD÷p
ÖN'~û«äHsûÛWÃ½aöZB_ŸÑâïYå,,¸¼¨MíWh²õâz¤z6OE§ÚéVfbğU`ÄÃ\åXô>W92¸r%©XŠÏ€ÃÚ×ğ~°¯qÖ³y–$v^…®@æ	!Ó±ß/:ŸûFbŠ$Nr§¼¾Å™Û5îŠ~äÓ&¾ -kè´o˜­¹-k£@Øû`cˆZ÷+áX~&#d_¬KYvt†l¢í¼ïŒ$rV'€ŸÈ;p‡¹»çêKÁÎ::c¨›°Nı£Sí3•²îO¹&Îİš¾ÍSxÑ‘ºöŸÉ ÑÁ`‡[_˜}Ú{:X›ï…§®òµä	E‰Ù÷[?£>£lÜ{ãO÷#	rº§dk¿Ò–QÈ-á	=»›ºA˜Â”S÷v›¸9µ°¤KcvÍâÜï­{&Â[=_‡Ûƒá™hèe_örã›‰[à³ËÁB~–ˆ=\¢“b­^è¶râãéH:…ˆ:¿¡íDF¡ğ¤ƒ˜ú®$Ÿ•nì±~?{¹'´ïDÂx¾ú¨›eÒw\“ÉÃtä§µoÑXÑóûMĞMGãhËA‡˜cÅzåm¯ÒøK^%Õzñ›xe÷ıT#œÓEg68C¯Pñ[dt~FÎPàŞ'¹	õHôöÆ”ŸÎĞşáÕÄ¹¨ÆSù²vœ³*•Ò¡@eÜ˜½	˜«üUÒùÁ]³¿Q™½†‹Š–b¾šxù%kU5Smî§ŠåN!¥¦:‹šçö³Òê7í|Ú˜fğà…o_‡dlu”¥ä–áƒİ_¯ä¹bˆ™½ô¢	UGÄ/ªªíñÔoZt›ªÕ‡ÉX Ëd Ôµ`=”ûÄŸfÉÓ\¢Š`éCL5´qGX»íoyøÆ7õFK<ßO2t½}ĞƒüÀc/6ıöÈëÊ²¡	5¡‘Öÿş˜ä~vŒ²„3Hƒ?„wÍ[]Ù{ú(’›*oÃÑïÛShdyv¦Ğl!Í‚b½ q™vƒ#ãM2Cš`‹ŒGºĞû”ÃÅxuî´ß‘M…YÅ‰Zm\ç–Œc3™GŒP‡ß2*ñ¥íø˜‰‚tk!á’tÏšK)ûpé¶“=À¨ÒÏ&ùñO$Vsx/ã”9¥4i–M$ ¨³€œ¤²û¨õ(?ÉJC¢‰‚şß¥¡a§á[$‚‘Æ „}çÁB¸µoÁö˜¾Z$¤qñ—ù)lÒ÷§I;_L•iÊ¦†„_È»æ'’5V+Dó·A¼ü…ÃÍĞÑLÉOMÿ?sÑà€%Á³œQ#IK4U'3z~üŸ¼]¢Œê\tš²j¤MRƒÌÖº<Á7dÕúêO‚âô,=9©FÖ×`U‰ÜÇN~‹´3Š¯Ö´ÙA4gHGƒC>#QZ&•]f\\5'İh)Å0¯'í6‡0/? W–vr„‰åàÑ~ÿ­R8µf«dw3Jã=uaÍCÖ(Â%nBu=ôş¶ò¹6C¿TF×Ä	@™LŞ¡ôOüÑšBÊÉçHvŞHaê•ïz«<goÅÄ#óÍe ™½ÇõÙ!å4äÅà*P7”A4*G
¬%è1&ĞuIë[ßÔJƒŞ$p¸Ä±(ahlB¶ÀòÎ¢.6De¥<àGQªêéÜ¬ğh•ÄşD&”ûêìÜ$&&c&,à§W‹ÔtòËøf¬ÆCÃI>Ä]½rG«¨åK4WQæOsoY8æÈ1AŠÁbw;ºÚ+.)é­ª¨
1lŸ1úÕ`œníà¯³c‚%?)ZEã×œ°@9í7è3°U³M¶ÂÀsÌÊÖö0ÈÄ°^Ç«ˆ¡ªŠ·Ô,)ñdÓM d<ø ©…|t©3†ÓoÖş*ç›âÖh±À…OQë­3Æ4¥­”¾M¹ââÂˆµgéW­£«Wù{íQ
®dÉ·Ù~/`pìt–‡MÍÅæ‹rª_(<òJ#iğ´è›§Dc ¦±Á[]çw|‰«ÍJ'ÆÚ1­7˜hfé7ÍÄŞÜ÷}5Bz!ô'Mé_ı7;—¼?#¬v¡£¬'÷!6ÊF„aOPÄªnÿ-æ¼&ÎÜyéáæJŒŠ¥;Ï£xˆß{ô Ì¾—İ²™ÀØgêªøq¹t N¸T%–ø½
`Yuz‘#š©ŸqrİÊ·.Ó°‹Ä[+œûÇw˜îŸ² ÈÄÍ™W(—ø"Ùx´>Úç¹ìñ!n-ìB7e°b”[K-xW:8°ˆ£òÏ])íÃV¸™ÅÊr³œö{tùıÑ•k2´ 'ãÕs§cU«^;İiÜƒ	'•Qˆñ‡ÆÖ?Kó“ØJ[=²Ôzëå5UÂ‰qÉ.3ÍgØ#¸Ê8§³©ÑcÁ]UºDçŸçGujNF£yvcßÿºüzë[Èt`é³ø!Ç®m£ílĞ‡ü·ù‹F‡X¦0zpœsˆ~è†Ê+;³0ËÆ) ğ”ã<WkšZzÀó8€FîĞ#Ÿpüí«7S²Ó1ÛmBÏA{ATø[¦˜<v¥~“ `3àóÇ…¾M@,øQcÆ§¾9Osú%£Z,Ï¹şğj±º ïüÎİÃÑBT``Ó ]ƒç0{¾àFí€‚=‘	ƒŠD™1ZzíY%3!KÙß R“½xÇ3\B™Å4§ÇÔh\˜8—¯¼–ñL= Á 2GŞ(ŒõH
:¦`¯ÜeHwøV©è~çìÚş¬}õ6ÚÈ×§ÂøèUñM‘·Ù3‚*O\H!øR4:„:ğóÄ¦ú~ûëŠğ,+Ög¨Bßä*ûîQ&”H9ÛmœŞØz›«^rşõNA8G”Éì‹¡$G	ThCÅìM Và¦ŞqiZ‘\a4-¼jé$%KW|Í°	XíwÑáIlaÂ¦ˆ²@ß& >à‡Û	yN6Ø>6F+JÁiÓñ4ÈŞ(ÀqªEÅÚ%ÎÀaÁF¹m¡Oã¨Ñ<[d)®UQ*~ÕUeàct®6»¶&¯İFÈJ&Zà›Q˜xÍköµw&*‚¦Ú&)¼ãúÌÆ‡Çm,Òi8ï÷À–r†dc²ÆÚca›ƒæÒ7Ùl#ÄßíÚ8n‚`aCCÚ‹£ï¢Ûªn!Kşè9†Záâƒ;^E6Šõİsa$#úPÂåšL·€ZÇÆæúˆá}"ZÉâÑ×«»ŸB†âÑsÍ2|*7ìuAõ;SëÉmÈÀ†àÒw†úÇøŒt%ûÒ-Bpş”TÇÕ¬GyòV‹'ûh„@$]T1hĞúÿ˜¤v5~ÜÍ–Ó$¨r˜¿'IËaõëzÿŸ¯şaú S+ä¸áTŸ¤ë½CìÌÚL-¼Óïé@)L$WSˆàpüêtHéí&U6)X¾ÊúÿÔX®OiQğOvéÂQmzgqAaé}£tÿœ/\‰`/øyzs†+”:«O³Ÿò_W)–®Ô©"c ‰ÈÛ ÖâS£”Ü«*pï»÷èÓEnŠô¾†­ ×eÖëeÇëJÕöÕ’Q9â„£‘€Êcb˜1®³Ôô7âfQ³åÊ¡Öt€må^®Ûr ¨¸Û½Ö}5ÊÒ¨ıÜÍˆ…]å»u>y…1¿7*íRçcÜ–ˆº©ñcãZsUÓÒmVêÍq¨k¸ÏhYYwRjŠĞÀÃùÙ.vÜÖ¾øx9c%Ï'ßI!¦ÍòñR¿——ãŸ&Àn•yxˆF¡’ÙÆÃø¬©
ê¥(#M÷~·öÄ”èw‡ÔUÖh›TòÑMĞ¶ú= ßÁ‚®ùÉõô,îd8ñ´¢¼÷»–ÀzÀ£÷é_½£S•ÈL·=˜0•òe&‘M´ì'œÎZ'JWi¡vkØIK_®×kûETáéçb¡ªé—ñCg›ißw¡`£—èÊ]5½3û!ˆÉ~rÁôôºäˆ•¶øC°ÛõSx‹[²W‰RÎ-;×/İìÏÃkM9FÜŞÎâ»æÙïÏ»ïŒjä|RJÅò´b'v/3¬¬ÛÁn•#Õ?šá’gs)J–‹¹ÿÌt…YñêúBƒêu,ğdíÕ”XOƒQmæ)Û:ö_ğDÊ:°/5[†bÍà– ¾×X4İÇ$r2!J=°¥¼_O5¯ÑEô¿œ€æÓ"Sut7Xhyù0ıYÉÇÓ‘¥†ˆ…zDã•‰òEYì¬X*@zdk2Ô¦–ññÍ÷HËáxQ&VR	ˆœ‘ú*eÌ3y™aóÎ	iäHayS…¸Ê8}ĞØ‘,¤´y¿Æ¶³¤†, ë;Ñ>ÊBô€c½CdÙJÖs¡±#l·ãÇ¨1º#¦¥hq}8H6‘¹´ìÃ{¾¨‚¯c²YwÌ»ûÃ˜ö…Ã0BªÔŸ"À  îÈÇ¬½é~×Ë0[Y&b}uH­m×şEÕşŠûlfëì–çÒWÂ×'c«T(ŞÂ¡ÉlĞGÍl¹¬ĞÚSwKxİP˜äöXlÏŸ—†µˆ„2Añ†¢é"QxùØâ[`°'™é^«UÃMÄŒ¹f¦6¾i¤¿B¶=4»/û=áL€ªñÏÔápOµv+Ş7t|üµvº\åëT\kñ"WP°X±p¿€b8G7Ç8¼÷œ˜€øˆFZuLàHûAe,
:/Ô­àGö»'ød-ªA¾7’ù¬µì©Ä†w@Wbô½¯w€t¾©PÜ­]ëpmkäîoBo-±ôö|äkïNt Í™\ÁT.!kıˆ ß#M¶@Ÿ‡Ó3˜Kÿ«çj!PÇ¸o¯h%æTª~jŞœóò7„)Êß…Í’“Ç—İ¯è¬ÉØT”;?˜
`Kÿÿ’2Ñ@â†X“””k5åÒmBäüT©„&ÈëRİÇDMd‰KÎ¤¯Ï{*|>òœUdØ'(UNR°Sí £ı8C[‘—.pxı8¼”yrĞ6@X|»³ætÉã+ŠŒbDäq€Ü…OÌXo^:$,
õ·­ÇFjĞuù¥˜GúYHyqLä)EŞXÄÒôªM¢Y…F’h°)Ç`àNÿ¡ñ‚í+Ã¦ÚÏõ ¾¿nª…‹“Õ¥Ó‚Ï’æøÜ:0‰{ø±`GqşG]ş<¸µ—XÔ—7«Ñ¦ÇO2p²âw¨ˆº 1Á<9¤£d'ã„]JOSm¤—g'»oØ¤Å$ÄÀZ3{.Â2îbOÜö{«Æe‚Ò¨IiÎêuQgÆC:ÌËÂÁ¡\JêÙ5Æ„é—äÔy©Â6ow’¨ìg?:`šÈÑ°®ğZôGßUŠL@¼æS¯ªÁC–Ê½—Sò¬ülh?‡<ÿ#ÔIÒ:İ¼`üµ"0Îÿ]¨‚\aîÙD®_ÙºöÏÜ×R½cTEÕµ—Í¼ñ7Ê¡î©¼Ñ€püMüÔ—‰PI±¯¥yÒ/DOÊÄwòtUöa#LuF`MµaØ ¡@F”ô‚{qŠï{¦+%‰(¬Ö
Gw@‚ÔâÈK©8p';ë¡ EPg÷öšI
”ò^±›GƒÀapë”®Pş “7ò¸-ÎvÃeL’‹’ºµ€Jv¿İWxG¤mïyWwØÅ‡H|?oûÏš,¢@0„¾’HŞîSkƒé!É;Á/ìLÿ€;xª"c“ß—\äad	v{3´îxİüwüø†aQçe#*	O)\C=Ã‡¯<G­.ğ•Ãlf9ıŞñ´(Ê?5°–ÉÃ´¼†¾ŒKmrgœÎ-¥üâ—i^í\$Ú÷j$•ş:7…ĞßˆÄÏ¸ÚæùÈ3p‰ò`˜m[á*£WÀK}¹¬ÉfÀ½)/d†F±Ñ¥óÈ´:Ö”W§?Z<ñMfœ8P«cH“c\qmpÜC
Ã=şÛ"<TIV'˜(`ƒõ›ñÈIc”B›g‚z»w{Y‹UOã’:B[ 9ä¤~†8ïmM®W€@›=p@!†M:øøÄF¯ş&ÿñ	RW†Z
Sô?Iqø-MjoˆÎTg$£ˆ¿8ÔÍş&V©9_å¹OD®ÏÓÌ-i7Xdƒ,/ùCÎÀö<¿ªéH<}j• 4ÛF1+v°}CÒõÑII§]İnÜsEJ=*?V}°:®§&îO£rçKÔÌÏğã%F¡!	ŠÀ{jR¯ş¸?T@Ÿ•°¨Œ¢¦yôÚƒfx°±¬¾ÍàÆšëu¥ €y—å^fs‘\]%ØÄœôzŒªqİ%{Ûá––ˆ¹ºîµÓ£òã»´‚ĞPØêHt¸–ô·Çâd](K[×m1üÆ	cşìÉÚ4Nuõaû&X“*gõe¦Ï~€öÔX3c£«"RtB°d@FÇ•·7ÛÄ8¦
m+-÷à:Ø“ŒÄf@wWAäèT`f¤–×„Ã¡|ÿwï¦uÀlF2iä4„µ%ô“ïçÇ"œ9ˆVyn(oÏ·è†-Rƒİ¶[Ù(—KegcØ²Jh£«.º>»®ªêV‘Ğ¡0Óê?æEí“m8ïå‘>¯^¶ÖˆeÇåÿH¨	R¤˜ÌWV_ ×-Q~´7ë`‹•ÓºçjJ¥³§g}%§[J^Ud9iKBs‘Ëj¡P[¡‰ñS$¾1ØƒÓĞÕ†m†S¹Ä‚Ì“Å°˜{’H´[ÙÕ»/ÇĞì œ<°ˆx0,Ziá
%ql½¼»ûÒÅv`pWåRÂˆò-cÂ=±ÓN¢ƒ=­¼[gdÁ°d£:û
Æ„{ÅÌÌ+ÀÃ¡™´ŞøwX|Fı'¾M€~-_’ı'dPc‘ ÀÉ•(N_Z”[&Wtİãì\ó¼·SêRg™Ï)ŒÇLS¿V)ßâûa¥¾¶B{ö RJ UIM‘$_\Å`áÖ){
cP•n,jÁ}¥Ñ…{óäoA9°«Gs³Ê”–·¥	ƒ¢ßèªµ"x¥ĞìµÌŒ²¤tÖa\‚R¥ß%L]fc »Ë
ƒïT†¦j}iÚOZ¶ò9“a’¬étº>bY‹V É„ÁÃ"+û|¾¡×˜°ÙF¼ŒKújÙü,ë3œÕ*
%©“à!ôÎl#GOa+^äğ+Ü‰¬º§êÑ}B€Fû‰=Ø£¶À)/%Áî`ŠèÕ’äXEÏSæ‘PêÒDW²ŒÊ ñ’º¡ŒuîcÁg¦Bâ³FÔ÷m3ßóxòâ<©Cé0M§[hFÀŞÒZà[æóÅF.ÀùÄo©Æ¼°2ß¿ŸÅÑiËõ­xK¾‡ØM»8®…­:iuãPİ>RíŸé¶<ú_÷ÜğoÖTí*›¨ètnĞVLQgûÂdh•#ç•ìa\îİó8Á}’²è§ZÇ×?Ôù®C8&©‚ÖìîTM~¿ÛDIJ$Ö‹Uq_­Òî3ÃÖNá¾óSU]&uµÔBèání¦f®Ûó~&¢KâE½í+åÑõx
ÿÇ÷
GÔ¶[HîgG‹Àß} İ§lï&©äzTh¶@aŸ•F#Ÿ")í– Áß½£BºÊ¸.İF¿NtMü}uq
·
!Ñúm–ï*öZÀÃ²°l€L¿MÒä)@¾[F<Bdğ|IıáÛ½m"	qÒç^Ä?ğW(äİ-Á©˜Ó®¢t"—™İöQY;ŒÎgl3´d¶ BÁ*Æ„ho¤2»ŠD‹H¦ğeK×Ãk‰â9çÂV¢xÃäÖ˜ XÎ^HY'.y9Ø¶•½ÆÚ?Fj¹{¸Xg×C¯ßèc÷Ç|§"ÁYRÌôg×‹¬¾!îo‰²û—ñ[FÓişœ¯•%ˆŠNÖA	¥â`cû²No ÍnZ›`0†v†JÀ xàF¥j…
™Ù±3&v¯İºùÛòš`rËÎ„t‹ãÜ³è}II`¬b­2"œİöxÍçŠ8¢Â®à_+U¥ â’oĞ¢Ù«øãû+Sú©Gx7£j¢ÊQ•DŞl*NP)·\¥‰º0f¢á½ğ÷Cê"¾˜Rû
´ßË"×©4 X‰Ï¦Mì‰{zÍ¸Ü·Wo¾)‚=Ä9C~¯\ ”ìgòè;«,0¾>ôEN£¼$%Õ9juÎîì‰\45ñšÉä+¸(!Ğ|ÂCVİævŸ.+˜h‚ÉŸto¦ê©ÑlÑÙC¢JÚ65Ëp£YÄN;¹L£Zb©a‹wåŒ=Şªüpè¡ßûÜû—8°°0]ŞëÜİ¢Œ¾:d=©hL=²­…£^ufkD¬'ôÇıù'¦Âôe»-Úå–O&7û êZöÉšá'%ëB—ŠËÇº [•ê¦nöÉ"—âMhé:xptq‚ÀC{KE	êj_ØÀ±W+9cÅ×š,,unÏ™·ÙJ}Õkû'2Úr­)Ğ³°Z26²,7‹ƒ[SVÑŞÒjŒRãI_²d¨«¬ÁYN¿“õ
	ŸïÛb0û+ì%JØE'úîLÜ-Î•"€ó”ÛÚC.À_wV›X—QT,6ƒ]Ò4á‘HÚÚBrèQ<uÀIò[İ³„ªEø©y%ZíòD‡ùzŞÜ¼©“G	JÃ¯7Î½?‡öHŸ˜Î//¹¨'ÖbÌs4ráBDwõ@-iHˆ"7b,æä±3@­µ”TtŸ™ÉoÈmL4DAÉ­¾¶
àëß¯ó±xå  	 Ù³¨‰Õ“ìB»×'Gsv3a Òcªè_Z'T—u¤bÎÔvbúFÍ|;ç‹E|öê'»7áiP­¿-›á.Øa™@Qìty´Yˆ§iZcIqGvékC0ÔbÄÓÎãùË‰Ç†'xRM€âLû7"×Ç¹£*<Iº€1pxÛÄ(—,øzz9•¼ T ©Œm¢ÁüúY zÎLaJç2ÅÑ©ÓbŠ0e¹`Â\*LòŒÿŸ„_$Ş‡^¨\}E	ây½Å.©mÁnÖs%kñ	E6âk¸"jm..‹Ÿ•wyDCE@"¥<„×ø¢,±èÉO>-é•&pLÕˆ´Õâ…õ|‡ºİ6›qƒ³¢ƒ	vøèFFDÑ‰æ˜j #w\}š?.Ê¨Î!iVÜ`³$	ù}°=®c$¤mç)ÛÕ¢ù×o§"M€/X~äco İìôhg
÷G gîUäIrÂu2@ÃÈğ?qŸjÔ@k;|i™Á)ì«Ã¾?0İy‰ö9´ª™#”¤—•:éÙ©ÍoÔ°xI·7<©Û¦3_Åğ&ªúºöİ¾wçÃ8â™WUt4¿j
Bc"şŸ¤9EÏåP|®)(wO~Y¼9)Ö
H‘ ±¾ùsÂ¬Ú—Õ³Ç}ç$ajÚ¯5ÍÑ9
·FÀn~>Uÿ@±bNğyÀÙY™±L ÀjK×¾‚6ˆ¤][JHôT`3Óo|ÚŒEw„9ğ…°ÚLèÚÁÚçJıãuĞXór«!_£ïÍäı1º£k
‰fX˜sÌ’mk„0.aoùjN1GˆÙSi©™¶fP3«Ş°M }^;ÁM;EWRç4câŞğ+ÌôôêxaÊ¦\
]Û³'‡%ëxÊ‹ü0·ægĞÎû@"f)ô®è4\Šîïõ—À…ìfF	fQò“ä÷*,–:¨y	‘É×áöSÅ£p‡.ffˆ*E-%jb°exZ_Tç(]1#ÍùŸ®ØJ›ÍdHît$štêqqPšt+‰E÷ÅÏC\9¸+MCNUÔ";qooŠX¡Ò-,AQGıbİÀ9¤®~r.İÎ‘`0*)Ûè‰÷Ã¶q(ú½¨„ıYƒú—^ViïÍ¥56k_uØOxw,/ên|—~æ.7^…%Ñ¤â-—
0îtÌ]µ8öÃ¥r j[¹¶~Ô£Ÿ¥…aørö¿%%¶bmĞÜt€'h8;ğk‡ğèâMŠKïO¬NÊw'~:GÖ5›_ø	OĞ¯WúŒµ0!ñœ†â|o•“ø!=¸ŒøÔR'ÍŠ•N%†öªØI†sœ”ŸG—9pfˆ59Xbç³Ş8Ä¾iåå<7¥pÜš­t5ÏvqªnæEéÎƒ"¯X¾4‘ …µÎÏBİ_ÌzüÏoˆlî¾‚Â
0²á?+ù„ÑFqÅé´.5õßËÑ
mâ¹È`£{aûÉå*~œŠìY¨šñÁ;|0`*k½6B5Û\D•¯¬ƒ!yè­6NNc	\oÍŸ:Cş\ow]L[?ÛµÍj§â·ìàÕùäò”ññ{•>ÜoæLB˜÷{‡È÷…3WvS‡<úÍ>óÍx€–¦*ĞcmåLšÜéÁüqÚÇV˜à´2"J¨«æz8´˜éïH¡L_ÖPƒÃ¼9Áè0'/ğâ÷ûLP—ı¸)€u0Î~úÅGQó]ºW·5ÃxàúÆú®7ÏËk&„>^K²ÚQÇb}‚_ŠmÀGu6Úk ë'İÁ°tĞ?bCøÑ:'6#–ºc·í¼×¹H/‚SşP?»²ŠaÆ4dí³j,Áú–0î¡;K­ÀF’?O¨¼â	)$Êú&Ê‚¡ÄZ„Åçt*
Y4ƒ{âgóÆÙ„…Aã‰€y«‰z7•ªˆ=DYaŞOá‹²±Á„àG,	"úÃ,ô9j–Œ?¨|ô;YBú¨œŠ–ıõ &¦¼öfäú¬Mô¨£İƒÕVß÷û{k?şÏQ•¢‰idîõ£³ã[^gª£D
ú„Öze¥)9/áTï@'®Âİ%mpdÅí‘I­"Ã9x&é©àö_Ëj3 çLR@I,Œ 3¯Üt1=Ïó¾‰Ï=ı2;3#^Bâ¬üè­ÓáqÃÿU÷Æõ³ß.Üîù§Nƒ	Ú^EZS¨’÷S‘‡)”ëNNğœ§Tı~!>GQX#”\ä")1¬®Y&DuHbíõÑAyvpvãYT×ÔBq!	ÚÒ¦¨ĞAäQ»QûŞÍ¿„;Nm•yúzuğ §'OH„BÁy¢itXšÊ¥=~1å$µÈ4Åq#Ë:¹¼+0È-şôœeÍöFùjÓ£ë.è
´J.wóhë‚)¶|ßºc#¶ğE^í!(—d=Tˆ.‹é6¶Ì£·\ïÇq½Ëšœæíºæ¡ÀÖAOYÔIoÛÍ©CµÎµ]f~¼êµ*#‘r9k‘Â÷ÄÈ…â;øÖ.e’îaèeñü48À¶Sù©¡Nû’HAI³Û„Ôí™,¹?e	át)pÃ®¼]¨.xD¸•ÑZ5`‡ãî0V‰–ÜĞH7…ö7vy@ƒˆ‚5u:Ğ¿¡¾®T™‹RÚ®zD$î ¾·¦•ºd­|¦ŸóÔ˜Ñ…Ô9ôºa•/éU°0–îğæåó[ß÷wü_†~ûÃµõ@H€ŞfÓ+¤ƒ=<è$iÒ99qé):¿ÕÂ9‡‹f<År[‚ÙTH%êà~Š`ñ¡€Ï¸Ê  Ê£à’qåo ïÑÏ]={'¼;ÁşŒ!­‡b‚q[ä1¶•A»Üëcç#É&<õlÃæ­½OÉ‹Ç“}7äi`¾2ÒÑHŞÆÖ,E%)#äÀ2şljº1Ìíj Eu®«•­[b/Î•1w]ši¢ZmËüæSì7'Fó«8k«¼vd·Ö7rÄ;ªÎ¯ÿœ ŠÚ÷ht„ao’òlfì®'º&ø
kƒÛûåPFà˜î7Ö@ÚÎûCØ`»âGéÈ7L3i”	¸ˆ;7}÷øvGÏ³£ø¬ãa˜Êqı®µMØò‚QÏ,/Tƒ¿ÒôîÀ»ê°úáõá.Œ÷”!WîÆJ``ûÃéˆ÷ˆ.pÜ|şËteî Ìëÿ|ÕlRˆVÑLOP“cÈ¦Á˜}ÿ×6Ã?M#õöVn§VFåY›«wYµ€æÔ® ˜Ê¦¶Ù\[.’§?5ŒÒ°ëfsh±AÔ¡±8j!P.•‰êË³^94ÃÄÆÀ3¾–&ıT;:ü8%€nº÷?&ëê«¢dP)4.S†=ÀñßÑÒFÆ·{ÆÌ¿µäö`ÇÃ¡ò›‰’YTH®ªNr›ƒîW{DB&rø®a‘K¾Ş´ŞËtñ„Ù®HÅnÒ»9˜Šµænèè^cu\sÌLÈ¬zxq{c¢(fLúÌFÊõ™¡‰y\fÍùüšÆÌ@¡üĞ¨ÛSnœÉ¬
ğB8´XWú†Z4Îuô{@;µ14ˆ1Ö}Wñõ¹O+š0àoëĞA¹ _usPÿ²ĞùÍ¸\ÈìIöÔ*š¹ÓŒTñÂô4ğ7±¯ƒ 22h@¹igpŠu‘…z¿…õvêY÷R<º+Ï‡æ+GgæìˆµÍ½õV‘É×_vº  >V§ù üFÖ³Éo,­ÿNÅË”>uWÏâ.ó¿×‹¨Æ[$´c&Óv#ñ£ hš’â1ŞKxDg¡è£ŞÖœooHL^à´BIÌHn	ßı}ÕOŠaì„¨H°Cd 8û'ğßLŒX5/.’}ÅH¯óÆÔŒÑA -ª”zÛ„ÒµW3<³î7†%\‘Kû%.Ø»¢şb»x.Œ=xü	Áø²¨W¯“•š:‚ó¦„ˆ“HšëÁ»®TMĞ}šÇ?q*ği17Ò¹–˜/Cø½¤èªğQmà¨ÉØ„Pû½]şÀâg¿ãÑ9Fz›½ØZD“³(±*Û+‚3te')O
¹ßg?Üëìaë¡¡×róÉMšuÎåğ9g‘ÉzSº2WÃzyÃé•	ù!Ã3‰b<]å¶‡©ÖIÿĞÕ:V|¯O ñ~x	i‰qŸ¸Âø–6^qqz‘ëÔ z@xPµ:çªàÛ\:@ŞsÙFyV…›šZzZ}DÌÀl—-m^dÆNÈHÖt˜¼]>ˆqüñÙÓé¼+@ËŠ:k„ß¢EIŞáöªXœlÄ© Ì¨¥P Û\do°ĞWíé¨€¬œñ–·®ûrmÄ9.sÙZ@ı"‹}‡tJËŒ;PMƒ§	Ûn“X;÷)ÄİÛidóZhòRò,µø8Êõ}°€ìˆvÊÆ°Â˜oï$”â¼Ásù´ª÷ÉÑ¡Zß|ÉÊyB/W%Û({$%ú¢¦Ö;ÂæŒØt#€bQ!aÉ¶à*–=õ¥ŠJxŞ¨ÊÍ€Ñ>y²½¦´gç+ªóU8› ’lã3" p–¯¡`(?a	?«ëL\•H†–Çï®¿·ÇÖËè=gZ±b‚S0÷°º!J;ZÀaRXãRybïİ¯øšçÎ1qÔÎ¤2Z“¥×pº‹‰»x0 _Z ìùÌñ×ôº	_ßÎ|Ï™9,“•ƒ„dg@DÎ.èå„K”°¼ş(Îâç_Åb3êJ½†ß)m46wî×ÑsL§y5JœómphÄ5!@4†:œ'‡ä=šçFP+Y|bqmêYeÁŒUî¦•Ì½<EÚkÙÃÕ¸ıV÷ı~òS?á4™ı› ®YA{÷æzÏåjƒ;d5Ç€`037š|b]ègš)Ê§‘æd’`z™r*”Ü2]ƒí.ñ0Äs»3:Æ0å*v^³X½B²$Ö#àË9.¿°&²šiÇZfÀÈ%QKÉV[üïÔÔ›m´ÚLºåµÖbYïÁFè£Š>DkU?;#Bç+Ì<Gÿ0“&6ÈP«îÓÕm¢ÉæJ*¨ÚíeÂ3œkcC64i<ÑB€vIKKŒ{5æƒ!¦m%º›¢J»j
x¥«ˆ=ï|à–­xÊ	Æ‚RtKŸ5Lé@ûEÖz^o#qÚ|*†§(„ò“ü°_nûĞÆB™Œ²…7Ó„“yçşTŠ>õp\0ËÒ¤zÂ•»‡†ß–ä8¥5Î/-HtùåÈù•=Á#Ã<	/éˆëT¹À»OR‚Wöš^sªèbêÑ5`ä¢Îöl¦Ï&GÕ= :úö³@TgîÈt¿µ«]TYà]hæ½¾a"á/è×*Áğ/1|«ÇISg$t9k÷Ô9Šşbºåóv™³Wµ™×&¤ãã#ïœìE)ƒi\ê2dBeËš[í®“•âfw<Cµ{%+¡ú¸¦Èá‰ŞÕ0]&¥‹²¤j+Iü£mx·$õ1:#Ø›½Í[2rùêŒŒş	_ˆòì¨z·&QzU!Mëe®‡®±ÌE@·òƒıC9Ù2;©ØºµIdÏc
ó)ç¿¬ÇgK¡ò¦-ºåD³Üâ'%}„­¢+ù[- ycçÁ'j®…ÇÉ
ñ0¡/ôüşZ+øS’e·t¤ÆÉ1ün[‰(f.Ü
Fèÿã½U_‡×Úzópâ®Z>ö„owö	CşÿX“¼ÁŒÂXˆ@ˆN(m‰üä†iëDF–F|Œ(SímëÑÁ‡#õÎŠ=Í*˜fµ,ÑÒÄmb|Y|ÿl¹o ©z˜*/èe›xÓº–G*
b3eI)Ô4÷[8–4Èë}’cÒMå0££€9¡@j:ù™Âã?,‘vU€P&åƒ(g:ñLì¦ıã®0ê\ÍÏUQ'ÍØKIOK$árm%K$_ŸàóúÚâˆÅyÁ±(YpİÆ'·¸_ì)†ıœ«',ZÖZ»kŠ.İ†BÈÿÁ§ìW²Ó¸†ş˜Ü7}Gdë“#/ö¿Ú»ÿ»¦i`ş¡Rê’SZ³5×{µ¨Ş"0Ş(#"äçÛhãÚ•maX-y´–JÎ ¶ø¿—lĞôÒåƒx™´ZÎãÖä¥@>³Ë¨¢ûìÛŸ—%/,“îwI7ü¡”ûKIŠ€Ú9´ÒØ¶9ø‡P¢õö•\YeŞ$x#{è9	Öñ¦ÚµÜËİÖ¢®ÁÆûG#lr‰R¼ßõ
·íò|ò†wGM‹íWYİmMÉ«X“Ñ¹KÍ’ªß/Ù§†I"tŞp+ì›ùhnÇ¦¹OVªœÌ4.mKïºGÚ°¨ˆªÛêÌÙŒbªOEêq˜:(Ã@3ó±nHÄpç†+ÏÉÛ_~xû$[º+1È–IıJwiZİ	¸n¾³£Š  'Æ±çµ»µø½ŒÍ‰¼ÎK ©íÁ9¨¡#tàÂéI²â©/P]Í‡T1Uw³Ï)FNT°<gKÄFaÌÇ=ÖÏlš\ş=ß˜‘K“‘['~¬Âÿç½]âxs×rÅÀõ’”!MŠ@–ª- Ôìq”!#ê'ìí]Íø8à+ëV3Ã÷‡±ÁFÿÒa¥^Ky0=Äù°Äò21Æ)QuÈV0’6›Qh’Cã‚Lk72+‹²t'PO‚iÂ€·
Óîı¨.j§ŠvÜî¬õÀy$öß‡B@,²Lv“=äa¦zÉ^ï‰Ä\°¥' ˆê'§ÿPÙ÷­L'2G´éî£«âì#Dr>CªsK¶€`³Æ÷ó ú–Fwsúú³7üêc*5ÿÑš"5Éí)R?ûıÌGÈÌfĞı]Jã,â’¨³FœŒÍVO½HRK{ùÿV®¾¶ê¼nïşepˆN¹a¬‡ö#!yëÓ´«>YX½ù_ÁÕîáGŠöFNëÉ¤s3”¤Ù"%ÔmÌ=È«×ZÂ™aç¾Yª/§§„¼éoö¢ŸOƒšü¿ÿ¡ÚgşÖ²“©ËğäÅ…ÛQß››õ;
m{ÑºëPÕ=·î{Ösòpkù¿C€ˆ§$DÉ‚[×Œtˆ]èÏD©ƒi—Oàã8]ªóeŞ¡•ºÏÙ‡yvü™:²~ŸÍFW·w¡/A³
¨KX‰×Ï¡1.ÜÜ¿R!´şM:ÔÌ]['´Œ‚œ>Ê»ÖHÓğÿ,„kXdv’1Sˆğ°ï*vIiµY¹üÏ5®?Blà=°æˆäØ4òö MÉ·ŒÒ /gá`	ƒÙUyw6¹8öF‚‰ŸÃ…YBòE­kÎ¿ 30…Q¨hwÚşvµòµ7Øß;G"‚èW;pç¿ï–÷,[ÚúŒ"r›Å‚ººqçëÈ²Øp¨ÏLÔ¡dùîóbÚ+–µĞ›8Ú6ÔB1à¡¢LÀÅ£¬·¹ŒÎ?äÏæÆzÎhQ8E¤Ã¸F¢u¶H_€èiñi$š¸;g®èİ³*â«ş4Ÿ"Â¹¢ĞeêE¤FbuëïRæ-ìKnÌLşÜ±T­,®>µè‘×$>ÒÍv¬½)oóñ	ş>Ğ^Ò¹Uúæ9@G¤œDGŠ.Îí˜ÀºÜ…wçìq3MÅÔ¥åûÈ´­HI•ÌruÆß}t£€ş¥W“²E=ùÖXUÚÕÆlŸÁ5lfd~od³>IƒP>2Ğ4r×B’ÂûëE}N]¹‚ÂæÈ/=¨Ø‘Â*Õ/¤€C}ÑæÍÈÆ×4ÏÔø8ì¿YÃ=¢m=áJM<í­syzí,îV³0¡E²Áı‹ûhÉô5`xL|Ì¬vÓ¡YÆ ÁÇ;‚ş’£3µ+XÂü*ş-d_‘-ïì°Uä?ÉiÑ$ñ-×:g©ìu<Šü¿9,â&Œ®µ¤‚\xar*ˆX „5È¤çQVƒû¬/¬íÜ´=)P§ÿÃÛmŠ(C9(ÿõ§o³«S¾õÊÏÉ2 úE‹t*úøã²†©@Á’?o¥YÑ¹Ê¾˜­%ªAo.EûÓb‚‡Ë4mAa°Pÿ³ÿéx›òÖbŠx…Løc«'UŞ	*FGsú÷)ñêéÅZæ—w«#ä›ã»DîÚCM»¨öË'­Dş’O|ŞÈÃ¢`K¶×ˆí!¼¬ÉŸYıÔ:ÓCÔÿj•ßmßôî1Q·Şc®”°ğ¼/¥¦ĞúQ›z`<•™ú9ıµ¯{»<ÒÚäæ/·–/GZµL4, xÿâÒÌÜBšõô±¹…*Ñp£ë8¼ Cªø¨şå9£¬šà{hÁDä'k$7‚×¢ğDŸ›±× öjûGS*Š*ee=Z×âí»:ÿÑ§²Ôúö®›l2/áÊ³Ÿ=ª9Y ÛL˜2¶qˆ®Y!A¸©÷=ø]ñš­ÍÜüCè¤xÃÊ°z…ô…RHIÛ/…ª1@uà@KÓ"şSOò4à$»­ƒ-¬“œÊÒË&)nBˆ)ñOæ–wVIİù”á[añ;Ö¦1ç¤am—Œì_cgÀ-™'\€­™!yï¿PC[H1ì~Û·U…ªOH”¯ªDf¨ebh=¦Má{¢T[ÀDœ0<FSø1“§‡dM"´W¢ '­&7çÈË)ê{£s¼bµS<_ğ4õ“äb7c©Ë1'}ÌÁ<%¸Àêğ˜˜õ)]¾G<Wÿ>Øï”Ó6Ş_•_.qnX'™ØKjo ²¢«t áYÑ	tè˜ãsL´bÙç§TŞã­e=>,	 T6şÚ©õ	Óf_ôşZŞ§×_Ø
pšo³1SG¹÷ñ õúJu-ê9í‹œë¤@[Ø
èéïÓ+êbyÿeuQÉiÓèÌüƒWvÒ¾ş'£ª²ê­öSøC¹ŠHnorxëğT¥>ß‹‘éM6ÇQ7ûš†wÑo-R=-LÊ’ ¶Ã’Z¾ĞmÏ!ZMíúÆõÀÊ+å–I|Õs2G…ë›SŒraŒ¸ú(>@xûğQcŸLeZÀ¿QmuH·	¥å¯çw`iuõ³[€e/¨á‡]$û$ib›à.w;¿Ç³öÑ/ûÙƒ4íh|Tt+äü}Ù¸³MıµpB–º¢Ä‰´LÕ8“x„z¥QC¼?–¡â#zX%$n&ŠÏ›}føD;:¢º|¥˜A`y¶Ë Ä½£lÇÍ& Á}bH$mÜÆx‡ĞW]A–ZòƒÇå~Ï‚C ¢rªgİ˜Øy:u© ‚3sĞ}W¡0šÁÚ†Ø5ZLôÃ¾Ã,nâ0uêÆ:R!;ŞÁ!à’Hª7¤†RÁ?|§fWÛÄÿÒì}Ûsy€‡‡g4ñÈd¾]mäúüƒ¢AT•Ş!AÃO7rõ65:³Jª‚¨òO\&s‰1G]ÏtØ‘ •Û²ŸÄÑ‡b¡5ƒ~HPœß„A‹`|ÔÙd¥/Ï“è°ÕŸ ¤« qzû¯ıÑ
=Ê¥¾6kşîûLiªô‚¥Ô1À¢,1“±Ì»í¾ô[    âcœ µ¿€ÀÖ÷Ò±Ägû    YZ