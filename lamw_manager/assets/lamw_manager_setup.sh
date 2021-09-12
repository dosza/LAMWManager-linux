#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="771474376"
MD5="b9cb29f5ba94e005bfc7044f4bbc8338"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23716"
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
	echo Date of packaging: Sun Sep 12 17:18:27 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\a] ¼}•À1Dd]‡Á›PætİD÷G§-@€ëşJÔ(ïkd¯a‡¸·–Ã)R^M¥ƒ.üª‰v'ë—•„jC™p;U]È~¤>¼|o8!@ğ´#‘/¼ùD²åYd‰eOÅä3²…I¿¼[½JŠW¤òıûÎ•°–ChÏaä7Y©3LU‹Ñ&Şô%I}3(1N2¸éË0$Í©V0ˆùïÈ´JÑ­×ûa'‹²=Ú¼Lb4HØ:üÚgksóêÑ¬À‡²J6ôD¼É!¸\¸Er"è¤Ñ×óG˜Dà/Voå¦|À¾-SÓ8¹öJBqtÎ^»ÖMÄÚ#›®`¹ÑŒìŞù°•«²º*6]M¤(ª¤Ñm[fê
ŸÔkäR{ƒè{‹.ğ.áÅyu ~wù.;-<ÚDX­Ğá˜zÎNsF‹
 »Èàê\<Ëo-)òdfj‰ş;ê,ç¢Ö4¸àúãÌ(÷IŞ·°'–8‰Â/yşğ>äFÀû¿ğ%JKå_¤0j¢Mjš*_Ş»‚IÒ‚ß
İt¨š¹J«ÌÎ øs9XÖ¾k?ß¹A¸4¸À'Wôd=Ê™¦#ØG [®( aJ³O@³¬Î_#>Ï«}±h/!´uåùjE a;îö×Î´*[Vs…‰Î1A%ÔÕ^¸I›ànÎËû„~Îç®;èÍuœ1É·»±+ÊnëJîF{ésß¥Q}{~ÓÊêe¾Úşvõ\)KÊ?Oçƒê´ú»FaYPnŒÏ {ÂïWSŸÕmèfIçéóÀ‚?"C­Ú7/)†—p ınó{##•§®š»³ÌM@˜W9€ºÛöÏ93¡:x$ÊÌÒ<ÏÌ¾ßd7!p1U.}¢@ª‡e9±÷OÌı™˜^Vóà™~Öä¿ ‡ºûÂöáTçjÆºf%õÇ%Ñ¤ğ
¶(#ªyù}4òå¿Åı©ıÿšb 3]š=Š¹8ØéÕÜG>õa5¢×ƒ"ºÊãôIa³LZv¾è'ŸTkšÑš(Y¿çâ©–5ıq”Öøj¶É$qµR<şTòúıßôÕ@äK(–ş©C?uÑ×†Êİ5]o¬ğäJì^mzçb½ñ­œŸø¬ Şñ¸Mœ„‡õ€‚!ùıê‰9ÿ˜oÁ‹ô8şòÏÊ/7°èA\äd”šŒĞfÊ~šÇíÕ*ûÅIÌmz˜†Ã[u9Í«š¸-{ú‚ü¥ek¥Ví]fõĞÔ+xÁYX™e<¿QÎû=!2Ë.àqÄ‘WoXYÚ>r"©ÄÑ$ïİ‡.M=‹@;ĞàîÀw5«%9‚ÖÜÏ(El6/åz–úªÓ[Õ¾wÒ°²x¯’3úÎßzùR.îØ{´åhà&î8»j?" 'Ü„•¨TÇd+Æ0üû)'áy'Õ¶RJ3HTàšºÅÜ×z•ÚP$Ä` ¯şŞ¬š¤âå©L$„0"´ÂÊœÜ]ÙtŞ;A™)M^|Â ƒóã¹‡JÔŠâP­ÌÀV+Ëà<UÕw<Q"Œö¿:5±M‹n0â^¢CısÅ—tòSEZ4úH’:b€ªl½ñòÒ¤ÌÂ„ä˜AÛ¹IcÆÙAÁ>[ï= öh?ânw¤¶M«Q»—<¢Ò2DåUpE/nƒ'úêŞh+Wësè(†‚5¦?CÙËñ85‡ÿ ~äzyXœÇ‹+…èWZ
¿nİC0dÉJã.o¤Œƒ)Á€ÒYıÿõĞt7(Ğ%Şyq¶UÈb2(‚Tø56ôà³Ãä³?p0Háíc²là¶zç);ê¶`èt¾giÈ@a¦y³¯§©1]êAú®TÄ2£¬Ú\'ã¡#)ã”ñÍ›Ó>ÅÃHôÜÇ#kb;1˜ÇŒÃ@Ğ	?7‚$8móä1?>‘¢Vg:NüR·)½ßÓÅÕR'1z«M·‘è€-fD’ñ	‡?mŒí2¹%Ït,+­¼"íş¥ÈK°È,%„¨m3ş­üD«f>ı“hM…Êö¯ßÊ[»ÔŸDp`à„Ù6,Q!Ør¸²aoçTqd³l1vË'y¢r-êƒ(ÀÎB`º¿üGcÆ>Œ†fJã†¢Ç)	ï\Rõ1äDKŸóz8îLÛÓfqTÈe€·¦T?Ï ä“ÆÄ®œi$~CT´„\j¶æ4]HÀèÕ(¸mşHnKôäQÚpXªÈôŸ-D\d/gœ,]sÍÍòfIüñ #ÓSAu ËÚ5vp€Ø×¬2î]ß;PÆ5K$&ò Xb“oİL=Àõ,èæ"•Šhq2Böè4ı¢¾Y^‘ÌzaSĞ™‰:O¶—Qƒ üà<–=MG˜²£9*ïŒš‘²÷DNy‚ï†ÊRàq‡Btı0¼˜`¿ë}$ƒ£ñ»9HûYÂÈúŒ^p’D·ÔaKç-ï²‚'¡¦›U;üÍñ-ıÎÒ5¦l:Yuèáw²}3Œ®$]?ƒ	àÂ’GqßÍ3¢7õ.$øü†ô8ô¼!u°#yÀr $° Ét°¾¢Õ¢şŸıÌs½ ×Â`÷¤ipğğ+Eñ‡Ñ=¬ôG‡›MC…§w?9¬¾¼RW4¤o»¦F8ò7òlĞ{´”Ü.Cƒ÷¯fäµš‰×šÌ´aFƒ@Qâ^AzUî,„!Í£»^ğÜèÌWvåÜkí»Ùvt¶h‡ï™4¿,ƒ´]²ã@QáËÅµX7ò(°Ÿ‡àØ¡ì(‡y†7=7{£Š+8æí‰ç­Q_â¤SgÌr}8øœ~#mi×¾Í‚Ç’«Á÷ñœ¿¦ê§CŒ#E^[¯æFİ!nhõEH¤1-|èmÕ¦½ûä:ÛôKŒSÇ)Ü¨	ƒ^{¶^£Î%Sä«Zµ"é{’"™|>dór%ÿE5t"«rSÑ¨ìØPå"+¥±—®%ı½6Rë±­lª”L®XÒß"V‰{0–´Q½FÔ‡‹ĞªœÁRÜæˆ0¾eÍrKIEé)TÌ…b-„ÎŒçòï8Æ2ÆHk|[PÙROóëãı9Gt=Eï?¤†CåAôIE½hôü5¢à_ÌF¼ç”ØübY'»‰¬Ó6ï‘ş$ŠYà¨ÄqCŒ$ìì±ş´ ´ü|úWm/¯àl#çæ0°ş\ëáÜëI„çMµıªeeÉd„uÖƒÒ^Ã¨xUë¤'mLI4ßé¡=¿ı{JñN–|w!cpDVï5\#ÇÌ‰JàÆ¶ ‚UŸ¯èğ“ødySDí­à­+	z1—NÑI¬QÔ–zÃÒãzZ	LNYJß„&`¼ÅˆWˆÁœ:Ø5ë4÷}Ii,×FêM[µÙx,§Éƒœ÷Î5h4o‡óÕ6/	³¨I#á\ùT=’ñó£»qùTè¹Èü×£Ím{aÃ¡:¸ƒñÎµR1¿¯ÀÀñ7K«åjQc.§C¾şû÷LÁ¿-éxyƒ«©pIºÇğVg¤6'ºV¼WQÓrÃÖk,OD÷%×ãIVwAœk›¥Q0-_ßaËIè¬÷Hè¯†œ„ÎcñX[ÄıGîL:2hò°†ş×.ÊæI×Õ¾6|ÛCõå«ğh‚7[¥ nzmªG/ò`µ9Äw÷Í¢™ó˜|%öÙ7Åã5AZôÙm¼^Šj<Yú‘‹dŸ,}$öøª¿//ıÇûM¥å¬MN˜“>îD’²ççïb=l’z¸k?âÛwWjË2rRì-7İİ¸ù“gtkÊeÇO2ö‘ofhê}€l¬y°wQÃç
ä>/™P³ jßˆ³¸ûMpÆW¯××N.Ë´¤îiúQ¦Ò€4¾°>XY;JÜğTü5 -×ˆ½Óê0÷k¿›)=ÅŠ‰.;f3¯#ªâ–á<o- 4‘çİ œõ?˜gƒõáœKËÏ£ª:Ø…²ÙMÂì6w_Jÿÿ	æˆ%£·S 9œC.¾ç;÷FÇ^®~Â,J{d3‚œôÑ2‰³’vXNí=Æva^çPÄ9Ép’®WVÜ9w@šüL)çŒkÅîĞâcZs˜>‘ÆücFl3xË¦÷Â3B9¹{…†›Qóz€6(5&IŞ<v¤E¿zx¹½xCŞÈ¾GÏC‚|éğ†ÁÀ2ğÙÔ€=ï*†:^•/tÿx=Xv•‡áL¡MEY/ù‚±/šˆR
ü8J›ò¾Ë!°Óñ—šmzH¯¸¡L2Â`äÁç\ñÛ%´à€¿%?ä¹œÃæ˜Õ-ê&ûOv"OúŠ™	7+ÓƒØ´õj)CD´b¥äÔÿ+[Ú‰‚k1ÏVÎº›<?Vm+O.¼\îru§/A(İÖff¦'ÆB«Ï<ñ{à§cƒ­¥a~õÔqx
?ì_v*
1ÑjÉxîø¨§#†fê©¥Îô
ÔPBcÑì†œ¦ëzêdbÉ	‚Z’;àbv…†Ëqb<O@1bå©r-j")nÒMÁ^š$¸l‹Û‚Ck¡øª«òÉèDZ/Ôøi6Ø§²äqÎ<-ğBS÷~ŸÍnUG(¸Ìt@–…{Äêj
§Ãï€)P.è]Vàğ{Ë¡¯˜]ğZÄÃœ‘‹¥B¢èrej’›4ı`z8›±»ÔR˜dÉ­„²wÚúq­-Áwzü‘ß]P¨3v™ø¿@ÚÊBüêˆ(sk³—s5[v~¢ñŠí"bYÙ"jÌ›™µ‘!€;;øí‰³ìÒ’/Çı}ìâ¦i­gAA´,ÎKYJ³“µg:dU¾ÃˆŸyÈ1õø	ƒôÛô´Ê]€
gûRŞ@Šôc+ÔÁaª; Ã±ˆ‰g)V4`‹Äv£1Qs×*ËÖõíé‹r@zFG~:Çøó,P6’Hİ!¹ålbfñë·pPÍ… \¨pÃ®ÕŒ§OÅh]AÊ=ÁA´J–<ƒÒ’´â+ì´®8~"hºÇq‰´ÊÊšyr{‘
àÊM›„KsÔ—W¢j[g®Õ½¸à€-ÌåeŸ>P;Êƒoµ³Ä¹ïc¾wÚÕ‘½öuÔxCƒåƒÖ’¾•ÌWIRV™`êöÎ3¢›OÁ8À.’º[ï^=“Y¤H7ëZŸå±È.Ãw«ÇÆ<.3ØP'iÊ%ü{Mó'6ê^:ñ£°‰XPõk£ÁLË\>!ƒ¶Ø¥ë°ª¿ä¤E–8zDõ¿ £ 9ŸÔ¾íÚò{»#.7„»…÷)ÇïÍÔ÷-sŒ”Ïaä–ïmJ²\t‹ge½xÕ>Ô}ii£Fé’‹½A1›Ìyï‹Ê‡íÁ7ÚC «Éó ñÇ¹¯øâ>SIı’ûo‘/¸œÛı…£5÷û¸tñBÉÓ«Ÿ(cóÛŞ„psp7Rx¸ 9Ğ<Eˆ»¾@ët:ÍB6ëé¿”‚àûúSPÕ¸ìí`¦û•‹’?±„KŠ½“‰"¼s!Èó£? ô›x]›I'´ÚEƒ@OWç;Tù¾ğ?¾'óÕ°J(«èèKH= *—úy’CTA·t[>æÙıNYĞ g
Meƒ»O»˜rF¼Êj‡úÑhgæé/cï½ƒƒ}æÑ'|ŸÇ<—Æ²dJ©göWÚ*[T(¸f'ls–3§b«c‡ëtÛaÌ÷?ø‘(&â ÑLR^ÍïŞp<ıá—5ETVšƒ—ûròÖš^e¸ç°†)J«ñ}ış_ÂCü’¡}×ÖİÏˆÛµj]•?m¿;”÷>8Ãù¸º.¬|Î¨ƒP'Y:ØÁ‹‰½¼—ğxSÎ×‡şçn(BŠièêaáì…›õg¦ÅŒ˜ëN9^ºfÄ&íõ¾3JlY$K¥Š„5Š­b³Iè\•/ÁY(İ+É°}¬(…ë¯eƒô¦€ë/µ.|(êË7iñ,;iö¿‚¼ŒÆÇé7´¬•…›Ô›¯Å‹Ôï*Éæo óm?İñ¸ú«PB>UÄ1v
µ§û¬×% «~Õº6²kgd!6|ŞOªhE×‚ƒğ›rÈ˜)h=¾4i“Í„':>Ì¢X–tÏƒ¿=¢¹‡¥ù]<yÙ¶Y9%Ôp÷M€ğä¼Êä–ğ‹pnéQDr A};çnÕş‹FŸ=yŞBŠ„_OÓ›ÙA˜Jª»ÑßÙÍ?ë5êï´¨Á˜­±5t‹öJäê(¾Ÿ™YÉ°0(¹Hµ#¯ˆãğP5ÛÍRHó˜HØ1Ş‡?0«ÿzC¤Ë»½~3W8©Õ™eÃV¥Ö|ÒE6÷v,™í İÎÀ‰¹Ç\,gƒ¾N(ëZéÊÍcf¦i€F+¤~7'(|Ìï·j°|ÉK˜ÄÔÑü àª6&ìîvnÉÔµrğ®·ïÇÇWCÈå‹ë€ŒsCôQÉˆJ/;ìàĞõg;t¦?ĞaÅˆ<óêÛüŠ¿Œd?º2Rüõk9Ã7‘YßjÚŠñæ·¹=½H—Ó5Ü¿öxNÃ˜¡h´àxÊ!º¦`c~Iä4™mX‘÷£d#f¯(,î‹]^¦W5#å ÜIµA×İEÑåÊÉ?¼»=L?í÷(°&R4˜ B´²n×ıW3/'`’:Áì|­|§ï5…v¼¾–Åõ-^‘
½è9ç=®è!	¿áÊõÛ°©ıÙõÁ§„-´CHÎÑ&EŒ$„5t31èĞŠ½ñ€Šğ¢ü4cjÙÏÜµKVD6êÊ¯C_s&L3Sn’bO+öõ'š,|t´"ÒÙ¦',Ü8›™ø§Új[Å=W28á¾Z’± qÿWˆ{Z¤DúS¹ğ\sõ’ÜHx2Ôåç.(ÕŸRb¤é¦›Ÿ§³28ÈÛP‰N2SMÖ€N Vç»”÷ˆ…`„©‰€qîğ¬§c†ÜJÙ;R˜™HX€{¯“µêH8rhŠ¬“‚PÇ4:í÷z<©;…ÖO'QĞÓKJèÒ $Ù¸ÉÊîÕ­n{s6j¥ÓQ¥B
Tñc)²ï¦ÉğÚ,ŸÆb»®ƒ¿…w2šöv’o5ÿÅ¬ÙÉjG‚$ÂÏ|’í÷õåAbA%]VÃ©P.Â‹ÿ½=^d$ÿ’¥€­‹²ç‹º#.Ø¿NÍh/'J³Ï:Ë—9C¶¢œƒó§VÅ
CdëÌªÍ~@u†i,İİ;ŒÛ«I-j†—Vc¿;`ÌSP2:«­8 ı_»oóf•fzx9Ìñ§ö°Á\Õ¸ßÅ{fAö*Rum¾üƒ“WîÄòèİ˜S“¤ñÈ‡1páNáZ>g¦­#s¦ÀÙ¢ŞSP¢î…×^e[.¤Æš§ûš=EÃ²£¤‚ÊBT¼m;ÿÇ OÓEj$û£uÏ‰½W}UÙ1?ÑäI[.h}ò)¨LL+±÷JÔ'âÅıBıŸL_ÃkŒhœ
§›~cŒ4˜ìàæ
vPka¨h›
@u<uHÃ|Ò8v†=CV«†‹‰„Ç©¢àÄØ6öşú¢…köÅîÜiÍTö§ôÉLá‚ÏÚU’q 9Ô¾Ğk?—•YP\3kk&'´ş0Ï­z¨ƒ	¿ıŠØ`#…ùœ3şÖò§nv7ó]3ÂÎ=Rû¨]ˆeĞD:_ƒ„Ñì†%y{10Éâ,@ö¡Ì:ıFA‰q4½ÊMeËØ‘ç^´R2›#*¶ƒ¾òoœ¬‘6Ud¦qC#GĞ—ynLÀ¿rØZ ´’^wüb8²î‡û	j&ZM*×XÊ)	Á­Í[5şv}â¤„Fn¡7è_„nãä¬//ÿpH·Ö¤¾48ö:Bò[æ÷êü÷L²ÓFõ	ÙŒ]†‰Êeº,©©µR„¥ñoá (eº¾‘ÇŞv•4ø9‘æÓft‡ÿöÈbéûİ“É|W{&3ùêÉu.…ØüÔ#¢Ğ¬²”`ó¿1r…®¼©ã…F½×ı»=œx T:ß™R'øÌÄŞ†2_®Ü®áó©—?0‡ÆË@H/4Oñ|çŸpƒë—U¦'ÑÆ*O‘kÌƒõ:‘b-]Ğ÷X8cá-ü
~®÷ç¸ÛÛå&‚®ãD§±ˆt*òÙ ·Ú{‰Ùõ…ïÿ¯E§,i®MÿNGÂ-8Ä†tgó8ZCcl?¤Úé-MÅº`)Z©,‚±}”G¥ïíK>§¡ê­ìÕƒy·ª\7‹Aªßô8§<aú&,YÕÑßPš3—ï¥Ç—·@{|şûÿ_†|¥Ù¦c«‰şXRŞ-ç†·mBr¤²3ÛÈş×HÑæ½*ƒ›òÃF8Æ&ıË?=â]’	ü<‡A,|¿ª€Ó5+6.ÇŒµ bÊ›R¶¨†õÊ“{¹Áb‘{ë_·¸L-ğøP›]ˆ–®‹!–/ÒåÑ•¾j—2ø§MÚ¹Y¥Å‘„‰ÂpçZ	¦Ï#gÂ“®‡qÓ~@äÖ£A‰¡`i¸¬DÓ¹QÒŸVP	HÏÔ´°Å™º`®¾ğh8+'EÙâvãfw†êã£t­
BSõÿ–ZfDŞà÷ÈÃ¬ßÖôÆ…[ÇK!\ä÷jøD¶ñ®‹(ÒåtÈK—5¤*İ>/&^ÏÚ®èªæ üÒ¨‚¼7~;‹*ı3ü)§u‚Ñ+çÒmCÄ˜Ÿö“‚@¤o[B‚Ûˆü<vÉîl~Y- /ø¸Ò®uÊw¢IçÆ6öşNÉ;-û!Éœ^ÄÓ ~ûÈ-1Õo 
ò}à_£´Œã’ï¶«ù0§39ûqZÜX­~·6‚²Ú¨a@6ã3T<ëÎ}å 5äm¢ïÇFé`½a„	ŸV]óìÁü™³÷v:\ChÒ‚uÔK|éÎÃ}‹M•‡×÷A¯xP6ÛŞZm÷¯×ãµ€Pv ß©Du;9ÃB’²RĞ¸_ÊÎ*‘Y³.R=E¸æIy_)uä¦8Œ£‘nRW)·«°œq²Ê‚´&ßzEN(á¤ÉNĞjzŒ³ñØ1Z«·4b¨™pÀn¯¼{Iò‹û»÷-„§GÃV–N:UH)T›ÙÏb„wTéYÂÅ6ñ$ñÀçĞÃ>ÓZ9jàB¤ÿ
·rŒÏ‘]Ù§•ò¿ÙÌvüëv•¿ˆNùÏƒkÁ}¾’HsFV™U‘–]æ†mş/Û*4„Øpâ±…Ù»…²øš´<pÓèËkT1xbyáÀã®™€2/ˆ^]¸ï
©ùA×)Ê–[}Å[c)@ê¥…IÅ[•­’
ÿ|˜å™x¶&8Û;¿½]"x¾w‡Q•SólšÎK!õnÀW\ğì.èsÈ_”¶vV\“7ü–ÊÕ¾q„Ÿ:Ãá°!’ ÏÊ¯¢CuÏÎu9Âø‘ª°Ï’›I­rN}ö^s[½`*Ø6mqT¾ñ†˜°³Ds¼Ÿô.6—-ÒûBˆÍB§Nƒõ‰›ñÛšìÑêËÁcYaÆbıÈõûÅÆ&¶\çùx®@!°éT‹ö—÷$>fğµÿ¬V¸ö>7t)ş{1‡¿4ŒÓ´»ELwÙ‰r|«PŒÙ[kèá2ŠâısQñ…¸°æ8S._†CæJŸ¾ÛºâØŞ:uıİC­ÔFaX:çÁõâ.»÷–x>Æ~$g¿ÏšGAYÔÍ€‘	­FmUZĞZ¨Ï³|Ù"öUğš½˜Èìà©j=mƒùVôtredÙ÷2Ó››â}·L)#&ã¡ÏôŠCÃ?3³½ÕµS¬M&Ï9doç™ˆ<ı€É.@€ù|¿pô¯7rıùGÌ³(tnåQ€#Ñ#k´ZÄlƒâNŒÓÊh5x43`Ó´”|¦š<»ƒYaqfÑ•ñ˜mz¡Jõ8bĞ¥œñ½oLŸ˜×1Ô?/Ì²=å:‚’EKp©<ƒ ‘g0dS ¿Õ>y~jŒµ~.ÄÕÿ)†ŞÕ£­ûmWnÀÃ«õ7ÿV¬!öA¢ñ„®GÚ7¡Dú-£›1ÊÜ6½.óÆsŞg
g‡£Ëz}AƒÀÂ¼(ÉIj®˜ vÛè£¿¼®‡[R™¢¡İ£†öls¿‡dxÆ¨ÙG†h·€Bt³7êGsÛGú®á,ÓKb‡õ¨WÍ"™YŠ„¢ÖôX\µÑ…ú‹Ëg“PWºÊFƒßİ°Ğ eLKŠCô¼©b÷eø³×­”4Úa¼9D[èdvïÆ€Ğ)[™r=™0#£PJä#~—Iªújv8ïáÿ>µ‹ F¾”_/Ü®ä0^`m<½9,æSÍŞíM²á‰'XÎ¶r%÷DGÜIcv¯„rŠq—ÕÑø0ƒzX´¬ÒêcÈ8I3/ÈA‚c¹Y?Ú_ ª§ÌcÏ7pºzîã*ÇDBì0zÒIìÁÇh	w©·)WK•´~%áá±t,2«M]@ÌeÎÇÔÙş«lwêú$šş([m^;†Şd6ÚxÉDBÊ»ˆ{B‡·êèéEÏßĞI³EwŠÇ€É¶ğ7àB0o(ğs\Í~¹”Ï¥´è?~f(ú­é—ğ
âß°'Kµ2²¸¿Ş¢jƒ-´àÎ;¤L‹l¯Ì¥PaÛş/¤+ÉÚ1lbAèl4ãö²Š¤¨»·úL->²‹éïüêìæ`a-…øn¦úÙàÇ¡(ºX±’ß´âW[x¿€Àh¬Ë÷&9:Áh½X’ –ÇâØøÚ51V¸ûŒ®×ê —8"Á›f;q/à,~ELnnÙw_¦½ò£ñ%"ëÚ«,%ëDû#ÕzĞ_šÁ‘çÆØ Â6ãwí äÕªwèEµç™èõ›å_@VE‰J=G×vyÛ¥¿…9=Ä…èM5îyü	ç3ºËPú!è·ÁpĞ#i-·QO[É¦Çr·¤¹DšÂˆp?[ûbhás–. 8§+mŞE¬±¨ºKë¶øİ~Ñš¨èøğ¦5Ë3¡6ĞDó¾l{)î¾lNúÔsŸÔVÁ´ĞP–ôZìà}åŞRb˜w¢uÚ%àŒê'AeUÌ	>z¬„M‰>oˆõ(-Pk¥#»º0¥¸§Á]6¾X têÖ˜ö–}¥+¦¼t½>CÑ½DÎ§şômØİäìDW6@z¯%<ïz@ô€p©ñ9†’š–Ÿ`Ÿ¡Fzéd·<–çBiÿ²pÊé”!z@T3aäİ7D6?~¾aèãÇ¦ ŞEŒaB¤LtâXíy?ƒA	/:Ò¨ËV	»CT•F¸ÅÑ÷Eİx?Qæï!7·`Å´çÓN›T{î®À´º /Í]*aKïAÇqu¼[œ¢Ş=P(‹â’;ò“UQP9”j´‰ÈƒxK 0ù1ÿéLùO§bû;"/´{%†È£×:ô:If¾¥Ê6ız;(¦‘Å{1hËô(#{°CgfÕéDÖ¹<Úˆ`°¡ñ®˜Ahƒnò'ã€°œâC¬Ç«²“ğŸqï³S¹4±¢bc¸‰«ã
Ê‘tÿ#)Eòœ‹+¸ğB(W‰¶õ´_ØØDºÔå•š_?Í®éu	¦";ÚûúŸŠAÛ#n'‹R·¼L%^Ét=ª:#ÎáĞÍ”z¨rWR¯ÕÕçjô³õ—:k¨Sº›ŠDSÏÌ¦”óS±n´-X“1<EæÆòB=ªZş×@§’â	#Ç÷¶‹Œ´3y*=»)a¡Ö®¸gvê†.Î›1ÀĞ(²\mTßŠwÍ_nğ”6õ-ÅDnkÓÜe…Ğâ“aiéˆ>¢îQƒ75ö´Ö¹s®TÅ‚Jº;CÇGæ‘1H‡ıïíìmW¨ÌW`ØæxØÎ×RÇ[F¥˜w2õaXÑ
íƒ_AX¨f†„Şàu®²ˆ —iW°!ªvìº3é~,÷iF=CÉe˜Wå dxÂØ.FAÍªrÏ¤Ğèü½u+){û°š,»T‡¦÷èå)à'`•>\ûŠJ­ok­ç†œJØ5Ü¨Ó(¬F«ú$úöêX25ÊÁ|yïÈÔßÜ÷X„#é}94ÅËÛ$|Í8²ÿËç$xáSécl,rÊ\Õ^»C3¶Õ^âj€¯3*ói{ğ‰¬Ö£ˆµD'–œ¢‚Yƒ®ÿ{¢ç\VL¯šÖŸğÌë¹"9y‹©e’»æw•ÿi‘ùı5£›Ö~Ï@Å\îˆVë»œZ^~ø=kAïnÙãD÷éFugÜÂxQŞ^İNx;³_tc:QËø_›ËJùÙ°üş›zjå°¦À}Íµ?y@Î½Î,r¬^FÄÏyúa®}"Ïş*ûÔ°±†··‰¨æÁB»ÛÖIÈ¤Ò†&uO“\z\„EŒ_Õo}!Â¼›Ò‚®8–ê¢÷áiÀ@á˜<çäíÅ‹½„Ïø…áÔ“Æiîu”HyK‡Q'ŒJNß'6h…!&JÆU—ÑVË©ü9?êWÏKé/xÇ['>kw)ğI Ì\<wæ®ÕùG0<7’¶RnÙ6÷Q¢¼®_ÑPÛ´{Ş‰–pôııßøOê7‹é!Ö^>ó&
J–•ÏqT(öé8Sãİ•¹FépÄ.ìÂ¬ŸEÒÜ4ˆ¿P¬{1ú·â%İ&6)˜ÙóæŸ°wƒ{‚}_Ì7Ô^ªÉU¯’«*³Œ¿Ã T"©s˜ÿ¯uÜ+uæQ»¿a¸Ş 6†g³¸‰"ı&’7xüĞR0KÏÜÚ ­2£-·3§îçKU.¸1[jÊOåš@êÛ¤6â	Æé§“N$°ü¼ç}>ªSI¼€,´Î6!K2,İşÔó´¼ÚŸÑóš4ë“±¥½S&S[th5ª>m xùßA"mšb³£Ì@³rw™V¡-ƒô¿İfKïÕİ¢ùm„ßÑ—5G„7›GƒæÊÛzk¢
¢XñE´ØL%‡íXÏõ1ˆUQvtN|72µâËÇ–$‹|Î ÙˆYâh|óêøù»Vm›;hœéßQ’›c©{V“Ûš­9P1r¹ª7ê‘/*ìŒ¢to Â= Â Ø)o,›ÜÕ¹Ü©I¶n~…Ê‹Yï™0“#äBİÁ2e=%¯à¾²ÖiİÔÿs˜ÓËQ£KÒD™ó—zŸÉåuë#xJûpÈîo±?PŒ)²ÊÆ#iùK7‡ˆé¹ÔêE"4I£‘«š$?Ä(QôqÌ^åb˜”ü©îEPøŒeCîfâdé½ö*ü+eYŞÛÂçÑÔE‘Á!åJÜtÔ>”²Ãß< ¾a·¾8Î¦åzÚvâXÃzS3§’ò™J¬Ršz‘¤o±ÌV×ó(©şÔûQñ>ìGÓ0¢W!)àtı®¸TmØÉ$7ÂsŞÉÖ³³w¥O²8,µ—·Ïx˜yYC™›ñîĞé	‘X1”ÿÿª5¯³¼ºÌ?"wq<jã-såùj98¿M^íh~À¨ƒr‹GH®óhA_y×öÓºÅÑ*úRkÜG’±3½ŸÙ	¶î0Laé'Šo½éQÄ–³fjhMMŸT„©;gĞìE!J0]@(‰-}á?,zİ+\¤LXEà¾&%õ6 H^b“œŒ_Òàd„Î"9(t§NÕ3ëä„ı·"ùu`^Æ?ØçcB#mÿ3a¶*Î¯½´ÆóFb¿4QÙ-åG$m¿üÛH–Ò–5[ˆ2 Ô]eÜ ¾@Npòyxéµ«‹òE„¶´>oÇ¦VZİs`WyöĞõ#É1»~ßsô<Ö3İNVïŸ¬ulUàÒÃ^º^”L~Í/“˜¨ò ±øQ"Ôp‡OAÖÍ~g‹g¸!^kª*Ãƒíô‹¿ö¸ù¯°ä¤ï‡¢ÀşÄSw^ğ #']S¯Ô¦jÎ³úèwÈT=PuÇÃ[ÄÙauÂ¸3½¬ÇÁxÉ´ˆÅ+óÛ…Š7_S¶eË@çFQ \F›ìÁz,¡yÙZ‡Pu‹¸¤<(¸D–EÆâ\Îş <“›x…Ñ>¯İÍà,ÄŒÚ¤ÉóSÜ˜+gÓoäqë<0ëe~’ ÒÑ*•cæ‰å­N¯—B,åJn?‚şï*Ì“ÄFq/MQlÊFXäq²À¯`r†d61V'=Vå¹£E7´Cò`Åø4yX`óğG	á–'ÖéèäÆãÿ>+Eá8WDïØ€7óÈÙÚ³Kö4ø–u¦Ø,Ø“Î~·˜õßÂw¦]Üş¡j'­‡‚~ÎœòwÒ(µü)†ú†÷ñ¯'º¹ÙJÿVY@™#³æãg§˜òé ÏWè¯¾)ÏH 5´”ü¶LŠs3šÚÊ÷ÂÇÙØ\KEe¸	($wu=Rnx-®3æ1(HĞ;NEgÀœŒZ~!È‰Õ>µ![å«’ŸË¨|Rø.È|­=Oœ,[å!w*„²UB·TèØ#¿2@Vçµg¨½ëi¿ÜÄ_›'¼xÈç‡ºÑ+«»¾f°ø"A5mô«nÕËœÍ°ˆ­u¾ÂG^zi Ã;{³CûÕ„©­¸hN7Q…KxaàlÎ©ºpl¤³êÓ@ç”Ì¿yiéİ}‰Ôğjc“¨Ò¬“R”@2©Q+I’[ŠY×>Ú²©]eÌÁˆ~Z­èXJ–\Và&9Ô(`×*n8˜[iñÿr‰F	†fË‰40RÖ­^C
¦Ï°Q‰ÉbF¤jg¤Én
Å9eÍgCİŒl¿¢f
ê¬l¥U-ìtß°ÅÿOw‘Î–İô-fZ&øİbùz­[Œ H>lU|ı‡{ş×(²Ëe‡sÇ#yŸ²V_ó?|8zgÜ4	WóûCô–¼&mÉÄÛ”vÌÏÃ;?ÛâBòiR(qVùÃØGï;½óalñº›¤Üy4 q†•OñwXÊslã4Îé‘§Í_è6f1^èÚy
0ƒhTaĞôëÒÔ^b~Sæ ßåQïXm|$m*f}$2Ëñ¥Ø7Š>|Ô’+ù\’«îI@¨==•¨]¡	‰hÈoÜÊá¸Gt
‘É_üşá5~ri57×(«¯#MánÛ‡Îœ•1×8<bã¡ÚÄ÷%20¥ÿ½r¢±;ŞÛRXÖ†ÿï—‡Ï°½ {`éE¡\pÊFTÃ=Üt°wØk»5À{e‘¬ˆ ¢:rSã¬IjP¸"ËYi(:œ×ü€;Ó”iÓî(]À~÷KÏZzÜî¦ çS£’5}NO%-ƒ§|B'ûÜ	5ƒH£À›M0Ş'È*×iæPÕóZ¾†¯uß4ßMpVÒÅƒŸ Úi°¢‚Á•ºm®ìME^ß™@ƒˆş(c µßfÑï!¦/îm›÷ØÅĞ@›T,¿g±7ıs¤_MNå’ jÚëyU†›‡•¼%wı§ƒd•ÀÅíÌT±V4*„s{Cñ1F—†àSõcÓ›ê"?ŠT‡qÁê­ÊŞÿ>ğ…´ÜCÙçà!UÏƒ;ı™óê«4Ÿ>}/_»Ğô96b”pÄòqËèY´ØÆ‚ÎÍÿ”DİIğ´r8½{l~·Òñˆr‚®rí8jÅ{_Â$pˆT œá“ÀçŸ>ZG:ÄË%ívdûçPéÎ¢Œ¸Â•-0fqPRwÕ«r# LgÔ=®©_7¹§Ü6×Œ©?ä>@Fµ	ZLºê’G—ñ.#¶Ğ]¢Zæ6hİÈdNÄKT|S`óy®xôLI¨iûîõJxâ\›Ù½öA ~<§ôLƒ;
#Ğ>–74íYæ¿v+ûƒi ®Bk(·†g_Ìj;«¡¤Å5@…G‰¸ŞÙ^™_ju#c½å|Ë5_|ór-!Cg†|n•PåÜ¢Z» ‡a€éÂ:r¨¤uGÒA´Tr¸{ZüHF†^©Ï	•WÕÖ oÑÿèáúıOhâq’´œùE¨ìÒI¶/.Oá7øDVuÅ0BÃ–FöxOXˆ8„PÙõm“‰Á„¤î£ÙôÑsÇÌ9Ô›Së¨Ïì#MÊ…óêˆ)Şùjuğ•&‹|–ÉÄû‰¯CŒ7Pë Ô­Ş.F´ß‘\L^a9Ÿ(‡ûØ$ Øÿü%Õ‰ŸËÆ=ÑÖWğÛo$¯1­6¤aï%p$š(µŒoô™Vh<aŸ¡M	*}F;¾ö¡õMoCÂâJöû¿Õ4ëôÌ/![÷tÌ*_eÉ½6guDáĞÏÜİáÌ¨¬eşñn/	íM!gyX•â›x5fcá$Ï_6†çåàœXzSîH b±…Å¨9¥éqªÈ¯V¦g”e¦»4¥IÂË))TšŒšÉk Wèxyë€»s„õW¬à	ÀD 5€šöRæ-mú›$œg°å8ò-v÷\rKZ¥B=“iéÙ’*¿Nµwãa«ª|¡ƒ8½‰éUîHÆÃSánøƒ'fP{€ôº÷€»0Ö'aŠ°!‹íš6
Jó2§1@V›*`ıDÒËŠßIü7­!pÖ‚!•Ç¾‘•2~Å§Có×*‚§ÇO\LN=ÔR/9µÙ3í…«îÉïKá¡¤Lğ«JÊ  _×‰¯2&%Ña pö¼zó?Z–)•æ9 e”o×ò3“ÊV\Cl‹»¼ZªÂ0•G¢½ƒ!—nÖq×uë¦\t ¬V+û™ÏD_LöcĞ®ÿ")]_›ÈI±ü…*ô/³ÙÇ«œoZãy¼\’—é',ıH,ÿ2oö"SW„Äò6-¢Ë;uÔ•4—ì÷+æ#é'£&©¬!«Å‘‰Á‚]û˜ò›Å0ªm"ëP2ùQÒáÌËÄ"YÊÏæÎf¥Ç…ïø¹é·ğÍ8Ï9".¶B(V—ktJšGÑµ$)™SÛ&Úâ{ş3Ô#àÎPÍ¼Iƒûõ Ç;…? ‰Y®Í¼é¹(q	0º>‹ Ÿ%‹ô/çnGfÇÉb²¯?	-dZIBÒir1\@Ÿã?iTiROÍ¤ØÚú‡¹öP9‚i,Úç¥]…â3Óü íÉÎ„:‡	3U«™üà±á'n5¨ş›^ßÕëÍP{B(˜8¸}Ü“ÄÏd}x¹xÜÙò@}&Ğ<xÌ™™OÇÒ‘üœNb¼:lh!ÿ¹˜Øi·.üøœÊ'³–x_+ìn¬ì¡İ?UZÎcŞ%TÉšd’M¥·RÈëjuÛj”*zõÑé(òÜË;ùœıĞVÓ=?Tá°g%½$ÛÈ´×#¡GV4Ò¥ÕãK¬µ€%z!¶›©ÉuPâì½Òs.wè‚xÔ¼ÿÍ˜ÜuY ÿ-æ!Û›XOiÁğ¸ó½IİÛ¼]aSõzíÜ•å$>šSÿÔOu§Û„™Ù\‹¯tïëO–„¬ï><ap”abtF­WÀÅ’wh€6e!Ü= …«¦ÅoïŞ¬b®ªV
/I8èxÏy!gRŸIŸeoÏ–Ë®!¹[µ¸®÷/Uqô#ãm¤	Mk"Â~ÔÎÛĞxïè*é¨t±AÁ¤–ÆìWbQ‘Çÿ›Êh›DOÀx¡#q÷GÜECËHè³ñTĞ¸úÓw¤ÚÍOÿãn÷Ù E¿é·¶&Q†‹İË-·¢½LAæUvTî¿U4}1P0e4kƒ™€3‚iÍ·ZGy«5 Ÿª$#$k.o!@¼1™ÈCizĞeNù)ø¥×è^r}E|Kº#&¾wöêÇ[]-äv·ö'/ãí&ŠvCÀ@WürÔäü‚*÷ö
Î@*+‘ÜH¿ãğ:ÕĞT(!¼úÏ5‰CŞ`Î–jZ5!ÅÜpL˜\M%"îİ`Qã‘9ûãòÄ´GŠ”ïïx£Ô"¦¬¿¢#ØYˆË°™U¡±T)ÊÜTÉM,_ˆ™,¬|É¸ımşê±äİ8'öx	Èpq/iãbËÎşP…ÈòC2è¢6–ÑWBl5K6&­´VÃ§­â ¶Ÿ@”Qÿ‹Á‡ŸrŠï™jiÕ¼Ù-4™™»Äo…«)/Zhu?2»G=VzÏÎ‹‡Cii]Çlâ|F„N‡½{ñ¢—‘sí
Õ}šşÀ1ilï>‘†E,ŞÆŠO‡O®%İ±9X÷è$r\§K-6zE&[Ü8İHoÀÉüéŸk ä´$¼ÍK#4¾ÅâYMÒA‘¸'½&;Ze*š¸òØq(Í)áßXğ6ğ“¬ù·ît^”U¸óXj5)ªş¤d‚š/ş©bjH8
‹Úægbr§ºrT¤«ïÎÈü{Æ'B‡¶ÃBt¢¯°Tí JÖïóı¿oíSÜi C‡îİ#ÍéëQ­)5
6¿Û"ıS® ÒkéZ1fşDã®‹¦:q"ù?6±DÅ²ıu 0*:Šp®‹5ëDf(¥?E‚'<¦óløĞLlšAk`!”¹³:3™Bá¸'Ón£:©_›¶ë*_”„5š>Iş»¦ëh‰ytYÔêI)iQ3œ'U<Ã.fõâ"YÑfÿë[šä1~™Ps‹m0³ŠÒr˜ã|ı>¥=Rûİu#g¼"²LƒïI<Ê\5oËí
š_çî”ız^—Ìs‰.§ö'†cZu–a@09ôU–'©÷´v~mò~Ñ‘£*›ÈMV½üJ6“°×ÿ_¯røë¦´”â¡ù¼ê³ß~´Ìœ	–¡£©l¾’ÇMÆj&!»B/­
ğ5‰Áh¨¤Ój	4ËíO÷]PE™_€qŒQÌ)ãUïU<QM:”Q"Ñ.<+jshÛ,%ëÎÓ¢t›CáäÅ	FZmÛkifoYéëòKµôßBã[,“cÖGØ\¼½XyXÆ£i‰­`:aeLA:‡O„Tcd\•!nhå€;Ç¿o\˜r5Ev˜ÿíªPş1M(Ë
%§5Å»µsc¶ÄD^V\‚îÌÏü€_&Ğj¿–“SQç 0UÌRQ"8‚Yíe†®¼´CdÿwÛµkVeæi¤ŞÃ#$	Í:¸ÒÜíåKZúÍæ.:–\÷dºøA/ ”Ï²t„Üü\\ª/âOûdaGšÚy´¢ì ¥ôÃ—GfÄù¸b_=Ö_hÙtJuËO üv
¥|Àå¸a1ç3Ü†àúãà÷7M¿âÁæSÖÄ·kg‚Ô«ë?â°"mpF/
üş3}˜Eÿ!×ê/Œ½hÕÖ ?„#á]…f"=¼p;Õd±Sì—‡t_¹(øÏ¤¨ï$ÌaÿÔİ2?v4P“:D|îFÀ2Î„=÷¹R´*{†o^lCBˆ>:68<aĞÓ®7^ú-
¢ó·£— Ì=‹³??ó¾ÉŞ&ˆØ&¥%Ôµ«¶ºb2Æä²0u\ˆ~OÅ.ì+dõh­æ7zœ²OŒë9¢ƒ”²€C×î¡#{Ê\™´(´#6^”x@üÂ46 t^Ø~¸Ø;'sOâú«pœ#XÜtß‚?¡Ù€Ö_°ˆ*Ñå¸9š.¬²œ}>¢AD_—Ş\@×¤ÄW2±9ßË…Û±°h± Ü:ú4mIË!0G †GM¢Ú@m–VS:Ïno‡ƒ‹•÷ÖµºdÊcÌ¡Ê7oYWğ’L”‘–qMPÂì;0¼æîé	kğòÜÇ¼ÛGqÿÕ´,ˆ£%Zäş‰Wj²úâü‚68ıoû¢²i=é>ˆæGõÏ î°xG™Ü:£bş7©4ÊKú¼
zs¾û«q„o‰ëÌû£–tÕ£nçÅv¦ÀxñYÀâEë%Ê`Äm<KBú¾şµ
0V÷š	)ß=oæ•C),Ë	K@néÑîÈ-_˜a‡ÍÊ…Y½©ít—ÛIºYÆZ.N™Òf>dé«ê")b¬xK¡T:fîKÃ´Á¼Fó"×zõk18œ=•=j—İ‚ê’oïEåßEàİãU‹ùAÑÏÃ#g8›C¦WôåÕ•tñ›O:5ãsÃH|°	»~ÒI…y‚Kği'é–zÊÙTäªS‚|ùÖØ‘ÏüÕT¨ô]ëÇÏÜ´YÆş,ÒªWâNp8¦¯`yŸ«HÓÓ
÷Ğ°f@SÕğj-Ş
f>„åJÊ‡”AÕB]	HëoÙZïÔ;úX…sÛ3Ã©×X
–Ø]À6 ÉœLNşùn´¿òík0Cö¸2ü»Ïdtë,nª@¨9é¾ª–]õ0ğøH%jº×Í¨sÆ©EIúÊsÉL	d)ş²¡®
Ò“pL1ıâÛIÈ€¤ën»M 0ÑXq)fìT6mï“-jÀœÑõÑê!=c§OFy@· Ò'ªÖ²?|'Q¿&_¬o°f1„sRJÛQ5ŠÒ··ƒÑÙÑ;½õX†üè¾Â±°fq}CÏ”HÅ¯Ã‚ÄŞ7ü.õk³İcwãÍúÿçÙd¾¡•*=ÃzÆú-Ñ$7±Ú:#?ÏšÓTL0ÊÌq.«ÅÿœÒõ&¿xğf°oá«¼£Øô—b™¨/ƒ;:Uwş·©ã¡¡g;OYoÊ˜F–=ª…geØŸuã}4ö!(*ZÀìĞĞÖ€^¢§-6’#¿Û}¦^–Ü™8lõüƒcÂû´<>Îˆ1.Zd˜ò1Ğ¾x¾KùÆA5ö¾y€ÁÖÄv!j…/¯O-¶ÃŒØsÉ¼R¬)>ã¾’cE$ˆÆHBÙ`%†LrPL¦X€ #µnò‰¤Úa%JóU3±6Ï’é—)<Ğl=[‡‚¹İ|´ÚĞA ^Ñsß€€F›wßšS­$Š&fpl}Ã²²ËO0Îù.(bäÙf/IÀÂun’®=3*Ád'òb¯ìŸ¸xÅ}¥¾•„txÜ•(b!Õä.Â° èÂà+~ç–Ÿî°¨Ÿ<ÕM[H‰¤ Qõc9ö¼<p{úºÏœïR~ÆëC‚Ï¹.ˆ‡Mé;—ˆ<Ê­¼H@ÃÏ3”`“‚ò\ÊË:™Üp!ä¥›lm½HùÓIÂ&NéæÒÄ”İ)€DP_Ğ!ĞQ˜Åù%‹‹%‹Å¸°éå¤„x¹pNÊş9”‡À¸–0ÔÖ±(@8ÇpÆ&ŞH]ùÃP=,!. °&¨³O%ú®Üšd6R–½ıÈ\“×S5 $é„'q|}ßPKÈ
¤äŞŠê÷÷Vä"3œÒ4è“¡²NJhĞø&üXß¯f‡Ô mÑ	d:ô¦b
À_*SÏ?câ]‰Êàv³´Á„¿ğ}'M’×ŒfM® L“Ap=ı¦œm¦`¥q9),Í:¥=(jªxœÀ¿¡ÔMf&Š{‘Ïxı^ÆªàF¤Bp@ıqõ6²ÖŠvÑ. •Dñ®(««ÅÊõ‰©y±/îß[¨€ ó>ïv9‹&7ó‚oòX
‘G{ÃÉ/J ÚEL›0ÛíªæéóvE1çË1¿}otCãËÊÁÎ|>F/B¥‰ú!ƒ­6S£ÛÄ­-G4L[1Ş]Cïe2×.„Ğ„oÜÄ}ó¨¸êW‘[šf Uüß‚y©‹:¸Ÿ.ô(£Ù[í»£ ÚBº—øü^š›ézÓlx¹¹yNLOoy[uåÁIqg	BØŒç6¥DÚªàê0¿Y]e¹¬Ç@ó¥Ş^0­@H	Ú ìzÕpˆlL—˜İ\7½I]˜~”Å‡I}äĞŸöó‰éRÊgÓ,R«¹±óÊ?Qg?¼7YÑ>k'=ŠÑ£±êe`N§8æ¿’-jŸ]í.ÉòÁmÒ²Á­i+P	ìH†’‘¯ÇfĞÛ¹)ŞêRÖ[IH÷p‹Y¨
¼ üüeÕ/V^®°"cœ™Í¤âû‚K¤‘LB;šzƒ[jBã	Škï&¢!İö€¤ı´â„x!góq¡u©P5:`™ª¼w6&ó«¾ñæ\Eê³÷¯q¤ÌıX)œò?I€²³øë…ô/ÏuÌÛGj€ŞÕr<jrØu·qH¤¾ÀÖH>ûıˆ1İÕw3‘¶œÃ¥¼è6ÄáóH¯Fú}Ñ
Ó&úîöÛ òi:ÀOİT‰Ğƒ›"-Ú&é0gq9²2ÊN\ÔËšuö4grÀÌøÖÜûwl8Úı¾0‹-®*!^Ä²¬VtŠ¬ËYğ‡5zwf©¶n¨S;Ë-Ü@Ñ¦yR·ó"£—Np®ÊÏó7Ÿù\m‘ì$ÂÕ.K×S(_'˜
•—ågRµµùÛ² Zeƒ÷c_@{½-£!«äˆ}ghL$JvM¬êÁ¡<rÚ½ìÔ-¸_Ï S¢¿=‘/C2€;ñğíığ·æ *«kÇGÀ†JßÏ‹Ê+ÆŒÒGo”®J¤
Ÿ\)™ˆGU;ì1%aél,£lÑoĞ£¥‚ˆJßšxÛOıÓşˆÌ™zÁq(7ùÏ7ÆÄÁaşs.Ì¹ôê¨ÿŠ¤ó 'tÊçF\µL²Şr&¬­	iÊs Xæ"zÆE¤è$t5´¨>BÎİ®øŞŠú\ePSñÛåF—>e…LıF¥‚¯Û|-ÂÌp€Bû­3
G?e gª?¾Îğß1ºo›dŠ'3a©ã<P^gú6ÖÔÖ›ŒÁ<øğ„i@»^ãJ¥eZP}§;­ ÕX•(hëe¯¼GOI‘¸t–õJævUä„i$/ÂµûK·°ÊL…]	¤`Œ51€Eˆ¤èU'¹¨WN•<æw-ÚuÊJI0«7eøOr] ¿±/0ğ«c]XNüü–OİC¥b±ëÇv˜Ù‡úÕS~şb$íóaÍÃ ğyÆK²JØ¥õ}¹o~[Ó¹Íâäığa{PÑƒÊ7{n?BEÌ·Ü…[xÓş¢9NËT»WU_¯m+K'Z2MM•Åf8ø_.æÁ6/¢UÏâJpıwX=÷ú€¾ÊÏ²»{hš7­¢R¼®¢õWO@A4WéÃ®ÃÜ7}aBPnøm»|U-'¨ÒûçªÉÆÓÖì•
B(<©›­şÑX|;'³èÖ‘]Ò^.Ô$VÍÇàC’a&2¤™pA¿¢Lù>SC‰yôEÏúÑŠùcnÑÂS'‡¶¹òò¦‹(ëIf)©„ªš)”¼ŞÀ´S¼ŞÛ”ğğ£@e‚lÁôù¶%¢ÇD–1 çt“c±Éó»à bÛCAQfÆNø»0ç$ÅI‚³°Jà·²“8Ú£‘-ˆ´wôÚZV†)$üÙfç'r±ÉÆËï
æÑĞuP]kä†X0@Ü±L~öZ¶·•ÚÄZr+4á‡•Èlö)f¼Ê6Ğ Vyßöãì¾·şì>G|ÃñûOéiªRxf•°m\><ã„~îÄå»)+í¦Ûp À3ãÕ„¢¥ÅLÒõ‘ÚíëEÏÛ›ÀKq0æGè†èû=_ÁDY©fÇR\ü–t®13”\Ì!«éa8¿-EÁ(ÌD´ŸÓ2})ñÿ6hô%£å€‰n•§|T0Dò!ÔÃ×l—¯Ğ£3ÈóıÎî?×Ñˆ ¯§h‚gó™—-[)Èsş	‚]« í½(gñ2İ6ı¶“¿ùÎ€)ó–¨ö
}o#»4fòÙ`æPÛeZ+À>:˜(‡
¢ö¨>
ì'4õ~Dé>µg¨˜äÿƒ@İñ p,‡‚JšÂÈé’ùi7…Ú
~ ÎIÔ^7ã ¯ÛçËÈLPz<u‘]|Qb´©QÆé;eÛÇÀ7]×ÿ`Ñ	®!\#ú5søÁ5^œÕ[¶Jí]ÃéÉâW,Ù%ú†	0`Í/² IÔDo³çrNı8wåÆ:håj¾ÙÂ¹Â>´óS<#Á@5ÊİßÆò†áf¯NâSL÷Ù±Nä4¯€MH\êm‹;LQ&‰’¸xGÿp¼+ åâ:¯`µ*Å`µï;ĞoÌf»,%nîq½rQ$ßÖ£'˜q-ïÈÿôLnÔqù.ıTÑ­…zE<k/Pj¬‡Ló§ã6TĞ4ºô<=§TˆÀ;ÛÇT£ApÎŞáğuÖ%ïÂâ{'k—Õô¼ÕY^"ùW§,4uğ÷@•6Ÿl1C[Ü»Ûûü ¨Àî3Ìy³è;ãòÓºÚ0-pæ<â”Ò(~=ã­r©f /c˜öîVV†yşlóbrÕof.Aì©hÎVeòÂE÷ö{½¤l›##õƒ)sğ2¤úå&]Óo0z¬mbóîÊşÉÎãÊx4f÷I„²¬YVá QIˆWÂî$ßãqe~ÛpY€5È­µÎZtåôVšíà>Š‡D¢·~ĞÁA½İ¦ö¹çHÓ0ßˆÏ&'LhUY:ÁµİÆÇÍ×JöÁE¤_øF€Ïÿ”ª;í&İ·èÖeMì¢gë\ÜØ1ºwy¶¦ïª7{›`\ËäüÁÏúƒöc€ÍÅŸÀ‚ï =ó]
²ÈkåĞ—:ôİ<°êiŒ´
‘Meµ·áÇl[ÆÈnæS™»ïRÎ)ÈnÙxõ5™§'Éøg şµÔbÔ:<»2n÷‰ºbºvÕ£¶ïW]JÍA®¿ó©Hò=İzWí™½Ì{Š¹¥ÕÙ¸9:Ô®bHH‡›pîˆxzÚ¼arêãD4)…Ú5º/øğDHTPHÄ‹©¢A_Y=oòQræ@²š˜a†D°º~G fƒXÈ—|Ã’CdŸnãAŠ–«cØóÌRŸıCÅe¦k<ÏRôF.-ÈÄVT¸LÑu'nŒ‚6:	ŞÕõëŞÚBŒJ£vø^)²[ôCC³ÿfFö(´×¾¤aÖëá8R:^†‡lØ£ü×YQÛë¸onpüÓ{è°Ex°T	ö.•¿N-$ØÅPí)¥Î¬ÆÇÇdÚo+šlªOÔ‚Yó¦šÅef[Û.4{šì7yéŸB;¼¡Âi^\AgÉbŒ.ğ’ÌÉùHÙCĞ‰Ÿè¼³Äûp\À'>4µò ßlôöøø˜~Æ³¦ôÎà“²BgáÊ¡òH0ø5k'kxIŠv„;e5*ƒ‹k<ü±¿‘˜ÁÚ@¡”§ßèÜ4¥z©¹EĞsìÔÂ»¡£‡F]I©œ¸Şs¨ªâx˜òsbWk¤Ò)‚à°aP[yÏN”ŠªoÃ^û #¸šFz#<5ÅÅÌ6>]G´Ì€w¿—ŞCK‚®t-¡ÑÕhÑ[}ŒO<Ú:è×ğ³èÓŞ_Y—ºª:Ã˜(–æe*“ûµUÔZûÄ›mª2/»²68{"R¨OÒ8-}½Å¿O€En2âIšXÂ¡ËõV\•ë­F«†Psb©¼qS‚ÉíºË^ç½îV§~i³FPWÚĞcËƒónÍ¦1]·]fQñèÎK•~?hÛ'Rİ&EkÔ!@ï¾]É­kIÀ¿]7‚¯Ñ-=CÄ~:çc|‘ÙEgØîEû(‹ù%²p§ÄL\’’•FEˆ¸¨"ÔoILkŠM+>Ú£I6œÍˆTÄ(Eæ.Oµpi4o–Â¯ÒçË¾¥*`F$ƒÕ®’ÔØ¾«Ú¾µïqw¦x:šÌ®ª“’C ;úˆ%À´!e4n/²AÉ’ü¥»	°Â Å]6Ä°ño>ùÏ<Pÿg}ÛQ€%ÂØı€ÎGAG'j˜¸úat$cHßŠö.6şşâv¿Ó„B«-É´~V/vW aòöè¼Ñ¬~ˆ_ªxC´Ì¯S\è]¹ä¦bÆ¸•ùÑsÄ™™‡X°ØƒÙ6Õ\î;åB{xÈ"™|]¬Ï†bû±†Ê+
X«z¾7u`z«¨ä¸ˆßpÑvœı5ôwãÎ‹™MLš«ÖÑ)ŠË‚a7şmÅQ`•£ô®-
¦Ï¹ŒÜÊq8÷bà	¸ƒ°eÓ
ŒŸÌng„†Å4¦ÎÑÂ×Yİ,Óœ´<DÃ½ïê÷2œ¶?şı÷*ÂO‹‘€‚)c€õŞóyém³é'úâ­Ç ‡6®Y˜å(ıùx•yÂ$÷ ˜Pëoğãÿiê¡;oŸíšøLÕ•‚ëUhî”Âb$-rêæÚDs=ş66cÓªQë«jÅ³Œï@Æ6+vt3İıY¡´Âà©¥Ä£DMv¿U
aÑ%ÑÛ‹'3Kõ2m%â´ú±Ë¥0kil5g;AÙw/ÃyvQH27¿ÉÒ4Î(Zb¥voîóp?N*Ø,Û‚^º0”úÆ(óóoûf¢<¼]€QÆ~šù¨käĞí\mNùc"˜ÍÆÙîpíDjNÊ¨_V"åšµ<°´ù·ûWÔ®“A—	˜
l~À%Æ
Æò“ÀÔµşø¸fŒd°Qs”)s!ëùâŒÂ	ëå„%ÔGqÂ¬1ƒJ â½Óü2LĞ;"ıBñR54Ç˜%Ğ; ¡ßÎà¶t€v,#ä
RârZ©êeÎQiÏeƒ‡ÃNóâ¶È~ßˆx

vü‰)!£¦í|£ÜÁô]œ5ÆH ÉE&ä”<"’'o¯ä»)_|Ã}/Ï– lá$Â
A™”Ûù…ÿ¶¬ IoÏÚÀq_s€:È0‰x¥ÍMÑñ!+j
I8@ølMõWD'!Ùg‰&@ŞcÖ9Ë*µ,ˆYø¾mèGÒIíö¬ÓŒX)°ù¯z£5sœmä€x—9í¿|Äiwë‚UÓ 7ªu29JC_2Ş§…å'éÜ{¼‹º…†ÄG5¯0’_947~¸U°Ù)‹+½\Ì»Í»^²J Ïƒ¯lÊËş«é±D"P
í=ÌÊà)±pØèËD‘ö¬Ïî½+B0ö-}+œƒMêié-Ş@$år^7;]_{%ZSŒZÌ»Aæ¶ÿâ|sšÜÉ;İ‡’daéîlG"ü¥ÄãÜ##0h²eíÌ­fåU[$„´´¶é…ÑøUáP.œéF¹fZ Ïm"4WÃÅ¾¬¡{óá•{WPYY7„¦»è×Dø·&˜î›½Ó=ñÛbLŠ–®T_ånsº”´+±…òåÿÈr e/dUcl*ìBÒø ³{Îñ¼•¹µkvï™•iÇúZÍ<"à6	¨Çb@.hØç gX|@2š^v	BñI>œ
)Œíá¥F¶Ä¦Š‚Æõ÷8`xÛÖ4%³=&!ÍéÎ› ²‚	ÁFsz¹Ø=ğ¾&²ÎED&] 7¶ï†H
`?÷AÁœmúñ×¸Ô½İAÚ³	²£]	7j|I*p¸´»¤Ì²CS0Ä„ıP¯5î'ÁE*ë£ } Lám Û?Ì­/ã^]úö’Œœ€ö0aàhÔ”ÚçVù˜0>˜R¬?îBê¢:{É‡œUQ—óú¥¿0ûN’_ç½•ÅÚì¨è4DñŸ²†µšû…¢<cNÓ¨¢`)uìiÀßó»sDãıûı=ä
ÓøL8XÁK6®*È…ˆJé¬â¨’<°Ä²z	øH|o°EÔ¿r_0ªaŒ\: XmvH*T¹ÍÈÏœxm|ŞZ]R	ÅAF4£Á…·İ Š­©9zr¾5B¥MH%LÀôˆ´§…]¯¬Ÿ ¤I…êIˆ) k”â„âcxD¹’{L$*,[OÑ
v®£Ñ TÎe]jó€´æ‰=Şß5Q… RÎxÙ®J	­H±`IpˆÊÂƒë)»òZëQ˜çÏ(9>İ³âİ@ÑÖƒWBd©L\İ±ëaÕ!hn•…µ¨'ƒ{wUéuóª$^H¡SÏşòæÌyE×ôÈñ‚œÍTå‹\~¿Ùi6ª(¹é„OŸŒÚ§%xnÆ˜¹Â”ªÁõy”ß2zVÖÿB×+¯÷ïÏ©Lq@X6µÖ-Ä:´)ì¦ |ÛÔÀÀÕÀb‚ß8ƒVA¤º÷º{y’<à€t…›5E¨æPæéUì\‹uÎ¤G1Dy"P‘øc<ì©†)µİ~czr™['
—bè€hÄ§û¾„İl¬üÛüªÉÅ1øùMhI6Ôå|~J)½ÎÈ˜€””qˆÈMt6¦«£æ×|¿¬7x‘1pÕ­xUœi×?à‰Ú@ °çc–ƒGU?ÁµatÜ¨¶Ìy)*ûE¶/Ä¼E,“ç6uŞ˜Ë/ÿ{Ÿ1“<Ëy^İİh“…ûÒ*Ôq F
*gOQÈ9óÍtÁ©¦B÷Ù -¥Dª÷>z_àì2µéq9©¡s$ŸUí!‚u0¹)ì…e{ÚŞ¸!L&ÿb00QÁùp*ínƒÓ ~N¯4
ô$™F9M[7¾úôÍ¨‡ šcÑâsnUëÁòGFÏO&•½IR„{È´1îæ¥gë7š£÷èRªñÈ’_ÄB+{ŸÔ'§ŠoÜÖWAÒšcÑ»b'ë™îËßÿ×¬sN9ÓC7†§QBƒõ)q¸LÚ<dûI©‰IÄÅZIÏıÂ3¤d*xn0¯pmÚæ³R¢“q¡.]ÀKÓÓ"	Ö—#`âéßß—áşÔ0f†Ïr÷ğÅWx÷)2€åß};z§ª‰±!‘t'dÍ^V{…Vı`°ŒÈ\5?p¹6Ğ6fğ¦ÔKA~}XÍWÕ<‡Cˆ\š7zI*^&¼şã‚XõmŒèJSšDj’?9%2^³0ÛîÛ¶ÉÎ´.ŒîÊà›ØbılÃĞ|g16ö\UµõE5ÂÕs§/`P‡… ·ÄE8Èj[&·±YˆÜíWh%w°ZÑ(°³9ª[_¯ì¼££HdÏ]¸gÛÄ£¤7Cá;/ËL·æ±
°øu^%1ªZER´v¡}kHÚäÈLi¤PL‚×d‘ÍÉ—ò%sSƒş}÷Ih^Œ¿}‚Om#/Í:×ı/eµÛ´‰Pı°?şŞÚe7¥Ü‡g—P5\ê®
”xa.“Üã3ÌÊiJ¼•á"Ÿ¯äkM”šİG±(uß™¡öñÁÁP’·Xä¡ó¬áj´
h`b´¿ZÖ˜@¾Š¬ğ+.yï‹õÏåô;háâu˜ ¹[Qà ó^‰»Şwi©Ê uáo›º7üMØÇE>Ê¾¶²ö`nt-2¢zÁ* ê¹9ç³Áv&,jÜ‹G^4Ÿñ#ü—èæáyİ^ŞÃO¢ÁÇ#bÑÁ—Ñô¢XŒûp“T"WıŸË2¼…S5†ŠÚj“¿3Ê$ûÌ=’¼ıÆñ³›k_H»C}ı ¦í
Ü^ÀPQÎÉµg'Öu8Pi•~±#tm@S|>éºb³™Q#:¬ÏC1º(I=eéZË¼ÖM+r:›ˆ««Cğ»dÒ(£óÁ³²‚x0«Çp´«Oñ‰ªCû,Q&¢ÒI9×sºë§çjº}=eÆ³€¶£İi4TÁO; Öf†”QÂ¸En˜Ìï/è–+Kšmà6¹TŠUç\$‰] ”y3ö`†ÖåÀb,Ü%.½gnı=Š…À­šŒE÷‡áh¨!%ğFÌR*( ‘EQÎ÷ÙFÌ§íÿî–aî*^0‚dÑ|ÑóxÙ?±§ÄrÓXG ÙLÓ)ßQø®â-'·TU¸æb+Sõ^^¥¯£Û€E’Ùë0Z"ê¯øòR{®nI:šÄèf~[v²Oª4X® fùé¿­”Dö”)2š B–Rr¾ßû•Œğ·Òlâ®jY<ÂSä“˜µ&|9ãô£îö“âH§ìhü®ğ>àqº­Ä¼?ğ –]Ù²!U¢µäÄRdMØ¼ö @K=~w«2Ym4B¶§¿ÜF–ü0VÖ+*g˜p¦Š+G¬©g9ø6ƒÎÕ#¥üÉjÀ—ÓCÌı·9yîÆ?N¤Sa¹' YNZ\ïPg{ŸşÔHĞ.¤YİKçµ2(@Éê EF+>s–ÊÆh«âK¶®Y‚Ü“¿q€‰ùï²ºDU4BÇ7ó¼(İCôÓ”ƒ\í–ãeß6tË™µğ”Azá‹zÉéî 6Îø® 7&>èô¤wÇÕO$ºM¬á¬ê_JÕx,¦ŸMåª§Íúå„Å;.'­ó­nV†qdåWÆØYR.PQæâªì*Û™RùKÒŠÛÈBz¿TSç5ò(aò#g6Ë8­ølñÛeÃJ!ï* ×¤…LÊUşı5	CgG)ü©:ÕU‰™’3¢d@]¯Ø—½.ÑYÇ{DPm+[G·É=)6ÂÉò¹á³ÛyÉ¯±;Ùpæ˜‰\ls‹©ÕŸnTSfº]æ´nj#VËÇ2¥¢U~’‰x*êØpÚmÆã>
Ë=Ò%™}ñ¡Lm#=eÊÈ1bè8ê7ÚFÎÃ!Ò†ÀMúaks‰|B´š.I¡ó^z®İ9Ñ–?æ´L»‰›%<Ã“âpÉ$s­©İĞÔ í°ÀÎHPa\òe™Í]cd»Húşo9é[¥.OÎhıîˆ„°ùXÒ|İ5Ø½Í
•*Õè2_c[ŒvhYÇfà.Y—‹‡Ó     ÃûæÉ
ó9 ı¸€ÀÇ£ùF±Ägû    YZ