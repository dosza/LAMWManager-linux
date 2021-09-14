#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="153654526"
MD5="3fc10df0bf61bc42b44cd6c6309affc9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23360"
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
	echo Date of packaging: Tue Sep 14 14:39:56 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZı] ¼}•À1Dd]‡Á›PætİDõ znoŠÛ ©.„I±êhÄ¸“×5„Á¬jA6Ôôß^üB¢V­{+”­’Œ¸@ğ±Tvm3¼„~O ©7™¸ÁMaÕ¾rk…ô)}ZÎ¢1ÖbtD'	éö.çd­±"È™K•Õˆ£ƒª%gşJ|¿º	}w›f±;a‘J.W—‚ êfËéF—Ê­mÏ%éÌ„Æj3H¶ò¬¼Nvá*‡ÕîJ@ş½å«–É·vL'¿ç"Qı=:c)ÔøÖÅâö`Ek ãÆù¿)SªnÒ¬‰b4†æ²Òß!t½šÙt<ÈEğ—C}m'îR&í”İÿp;¿Éğ[kIeó@ô¹dØKÉ^Ã U¦põ-zaÊôÆş¤ü©o15ÛOê^æYEÌ©Ç~5®‹lÀyÑÅ¾¤õØdá6ŒF	,Oæ‘x¦©-”´¾®XşÙçTpqõ’şÿç+¥ûÑAp†ËÃ½!İşr’²û0åŒ Å‘Á¶l‚é‰y[š„ÿÇAdà°•e‡@UDs¯åu²ŞhôC½îÛ(ËÕ!"“[“õÑ¾FG}ı•,uÒpeîSÙSoıî½  ÔŠIó’d´¥ı.>*ÓW&ÔƒSN£Ñö¥°§âeø—¿€±Á×Ùr70¾w¨Ú°¯i,_–ÌúHGrRè>|ÍÉî(¬mq	ò4³JÖÛà³éÁ¾Ñ’jb	b©ªéµZ¹c_&nkÍ¥çÊø5pk\Æ/ÚØL_eî#e^İêNÙo¯é‰§TqN2¼­·¼e’‰ñ\óÏ²bÉåv§\Ÿ…EËí)¼tºP èæ³åHÉl¾+ĞyùDÊìc5Õvk$bkĞ¦Ÿåº~ËÁ¥Àñİ­`!s´(§!‰SI¯CÒº¼>:Ï^|ÆE‘&«å|MÁO$øÅñ¶ˆäLl…c„öë7ÓRÉ
’1‡TÌ"k‰ñÿcúÅæ°n+G3ş	X4òUÃR*Ó0!ÖS";uß:K´Ç°	‰£PN†7iÖĞ<®~¼}Ø“‡Êí¯ Àw±MÜ/`å¸!ÁX½ô“,©H­çğÓEİğ€uÀÿ’ ÔÀÓl»
ÆŒƒJYÎu¿Ü›Í•1Nç-oY}”rùÃJõLâ®Ô5¦$^“vJè9)İƒÇ	XŠ7RRû©Ç ‘» ıí?åÏç$;Ê—‚E¨FÕ;Cü³BÛÀâ‘Z¾Ÿ=á;ÂÍ£øGLs¼QV
¬¤m'#Ç¦8:´˜Î}†Ä¶p®0O™İ;-Ò³¥l“Ü¥3ˆl™qÜûmİRIQÇšjçi¸b‡v]ãV‚µ HÊû ½ÁÄº¯ òK<·iı-.ÛA—4¨d
8{wôÓ”öRêÖÁoı?ˆìíÙö„!>Ç}¸Ÿ/îàt³ú¦¶Ó~Ò>¶µïUâYù_>=#9áD`ÄïËûËä~ˆ-Æ™ò½Tñº+…¤ÕºïUÓƒyxÛpùĞFöÖ/îß¿–œ/NyŸl
=äê¤õ\¤x:7D÷ÿÁŸfRXnÄûúÌ¯8›ÒUNÉMÎ6û‰eúñÊ˜z³¿;q(ƒ"ƒåÉ‘Ü/¸%ò‰vZX‹‰4ıù+Ãµ;#»‡‰L” ‘Ñ¾QZbİ»¨s sÙwúùĞ-ĞÜ†´†•Ì(tÈúQ”ëˆz÷Bvİ¥pÑ×¹Ğ¤N]çƒˆœm‰Ë
iúä«p/hÕ˜&>Ü¡–ÔôpF¢dÅ¦”4øeÏG*ªÇšé¬”Ê${>7ÎG(†ÄI¸añyıc@| a•g_Ç‘Âÿæ˜P€«|9ek¥¼>Ööî6´`ºWóÆ,ÍñÇ3CAî¤?á·?‰å›‹-Â¾+ıÉß±¼ö“¯)êâ¢€ÎÄhÉ:8ÕäÚ-¸ëßfÇˆ#Õ0Î´î.Ñ8k»~œ“€/UsÅ~^	ÁÍéUÓ¤^Åİªü/­Íà¨ó° ù­PÈK4¯$p"d›½yrÚ¤ãŠã{­Wë¡qR£] çÿC6&©W‡lØÂò+sè@eûÏ§Xî³Î	ñº:\íì?éC¨üİ‰8j5\G‡™±êò&ºò5a§?'ËÅ\ÎÇlØvÇPÌy7ÊjeÇ€qÏ=A@cTÅ%x|La÷<ş…Éô”]ÕÔh…U·)Ÿ~µ5%İ~ôıÏ! ¡X.;Kø9İî^¾k2 }‡¼nq‡D„(ÈÚoWÖÇÇ¹rı¼S+=Œ™ıYé!ÈÊkg€FFb&í‡#b·³„$•ı¢7¢Î’0-îş_b¢Heãj¥
é‚i˜£uç^Ö(º3¶ LV>×ŞlWÅ™ø2 ÊFœœ«&xı [­$&ÕMk4%åÌ/9C*äëp×zcJŒâĞ½á2 ±Nå„ÚL	4«YLmpÙ2Ä¹%6<$+Ù2ØŒöNÅxãœR§ ¸¿Aw®Ñrá#vã­jKu4ÆÍYYÆßåv’™—Br*Š®ë”+íÜèA`·^K‘euY êÛDÄúa™;¦³R¥>·.	¤©«€Y­^(‚6¡¤§±ˆ*!Ğ`d9!‘%œo`DP˜ºšß3à_k…CO¾CÅ ”@yøó˜Vwo÷Ç[H*³"˜PÔÙ€X¢»èÈwéÔŞÜ|ªæwñX˜·”F“¥X”³îˆÅ[Ìáå.üÌHÉD¶˜ ÜRñÕGÁ‚;1%ä7-ú»\Î$nÏ²sñĞŒdğ!ı'•hàÀŠœË¾µúf<J&…´&Mot¥À9ÙAÉÜ€¦·¯j›TzF¨¢8˜0×¿	ãq>¥ii	
ƒŒ¦å×sns ìu
aˆO/Ì½å®)uš`?W*ºÃ¥]şú¯×ÔM¹ƒñÂ(™p¾Ùèq,—	šóÎ;jöEo}{§MÂ¦J×_ttxEIöx0Yò&~NøÏç:ñĞüZJÂâˆ|ŞÕ2SÖšæ:·%Â[zKóØ&ëGG&Õ‡C;+ÍÛlÖ}²ttå~-E¥m£|*ƒ™]ÌêCÉµŒ’ÒÊò÷D<bÅ[§•Ìt»_®_çİìuªšjûV´°ŠR/Ü ¯5¹*—>æEG'<¦ªÁRµÄ‰Õ+«A…7fRÏ§e,ÿxz&»/ZŸøïÆ›b‚ªİ“Úw¶`ÿ}©CûÃHÇ?bãçRÉÙA}73ñ–—/šÒ9>Ø¡¬[Ê’9Ó8ˆ1ÍïYò}Í&4·¾oİ,öOÖ­yËª?‡«RÓ~ÖkP„¬aWS	÷4…Œ§ÁèÖ‚ÎlR¤·¹·ìáìæÁHgèïáhwíÍÁ¡á”}Ôí·ÿÇqŒ©o¤€»áZ,©,(@ÉW)@K5µ¹„q? øä‡X™Û·U–û¿@’Nèx:ô¿|ròMŠ…ü‰’˜‘ÒòÀµ„(+ï' [-oéZ‰ĞÖCù-Ş«GÓ|d Ö†«Ä3Â@ûPh[b¶a£k¾+Ä…ÓZ&õìôë¢_¸w†”¬QYÖ}›q
=ü’àPOŠ}/vú	:uÙìèS‹ñYû‰n>ùŞJgY}à,”>â·F2éÍ‘™ òu¹6¸°†&dH¤…ù8›&Ä®´Š‚KhÖş¿;Ö²èÚ¹È¿ÏÈ°?Y›póõâ¬ÏE¿lÏ¸m±wíˆ×ùX~B±˜Éœ;ˆàköBûNĞCkíyı p°ªÊwf§"³T†`2~¡ïÔ]|uxhå´ñ:Ş3îaM_ai ‹ñKıöÁ1¬«¤§‚SÃ‡Ÿï¬^ÂôZ£1&¼:.}…Q}¦™ÇAêzüF
gz‰à!{ßËÄVÿïTv¾šdD§l¿ÿÓ«k®“ıèòPßö£Å$ùÓz5°Ç¼
ï÷vÎÇ	ÛÛü½…¯ÃŞ@ï©üI7˜'"c°Ôòfnxé†-àd‰p|Ãİ<)¾—ØÑçİ‹yE6t}äf›°°±O³iBh°¨ddõ7Ã6v¿(
œm®ø|¸Ø3Gæœ1½WÛÒê	e¢Êk¿ìu,=ÊìhŞñQ¯:ÎÁ ª¶¾l£WÏ1)£Ó…Œ.j¦ £¥""Èê…:ÿ?6i[Ü±AÊ2©gŸ}¬ÂOÓÀï:nGxÌ­´Ísš°†‚¡ÿnúó ¯9üşÜê=ÉƒÚîfÑKAK‚á;™L÷<±²ı7Ó‚öñpÎä†Rp÷¦¼çĞ0u¨±àêÓ_¯×l(²Äò¢—Èa[]ê9ùÛi—çHGó£ƒ‡:Ì€ã®âƒÔ·åfşY½k‰C|aBwœ‹o±˜7‰,`ø¬Bÿ˜Œ·F	Lª”°ş§/+=[7¨vrÁ=bAÔh¦ Í,S&4ĞÕY^(¼}QkºOûÔD"oæNõ^òÔ¿€xúqåÀ>òpoŞ¤½÷®Gÿ‡*JØ€í†ã’’„†C¿ÔºÍä½.-«1Hï¹íÿO(Ş9>%1šûş¬—®w/Ism‘aÜH|‹Ìœà†¶pÈW¶EÖÏ€D@ñî-Xrl9¶ô÷2x Xä–SÃ?h#Ï$¼YŸEÀà^Íu=rsØ
 Å’2SW ’*ZÀİ¾à—ÅEo	²q!êCŒ¿dj(€“ÁéäÃ m,uÉ­ÉÛ,0{¯‘eİs!ÊÂ>ûGÁÒ¸õï¼¸1fÁvêèŞ'¨«Õ××R¶¾º
æĞ#³!CÄ€vLÚÏêRà—Ş#E©D ÌŞÛ`
LîÊùxŞ·ë]?VGyTı><J0–>ˆíÂĞBç4ï›†(„vDu6ûI_EJš²UåœKZºk6ºœN¼ÌæÄĞX2Û|°RªÚ"<ÌFÚ‚²{Ö¿‡ø4ÔØxîãëN\F%>G;é‚%«=:šM‘à;¤æÉôËÎåö„0¦|Å¤SAÎùCL”½áûªˆ®•Ë-£kœáQL+Ê—U¤p”Ú#™’Ñh‚Ö·ª:İïnâ/!£hĞh·£B#¦ÊşİS\U?Ğ‰À¤õ@}=‹ú©J`V™¼…0â"Ğ±1BqH·?¤æĞ(ƒ±¤~–’	jtçq5pÂ†×½ñ½J‡QØİ	œ>{óg4?¿œã«mØ˜¾qîºµ;Å¿/¨=¦áuô9¥éßjŒñ}ÔrÓ¸ ÇÈb5<š)%Nn„go¾=}‘Î0QAŒßpÙ0+HRèµ¾Ì5G®¢Ê13P†ô±-$5­©'£õ&./‰.¾Ç®‰”@ÕX§í’MšZ%Œµ]\*Å¥Î.:Î[É(Ö˜—ÜÓ0ê°Ánª}sh„*ã™ær,—ô7İÆÀØ¹_•¡>qKl¬&¦äºÍRÀ¹°•j±TÏ5­íZ— \½€°[ˆhE÷(¦fVOĞÍ¶¬ÎM¢^GÍ-HTÒ±A‘Ş #AOa†.„·¼%úawé`y{drP.á§R\p*qò¾s_
0pvwm[°”Nº.¬#F/(_#bzç6µm$
¤q™i°±ûºI¦	Ùõø @bN§8ã†`ëöML@Ï¹ûÎáNÜúå‘|`;LŠÙ<´qb%Õ?G¬E¶2)§”pÿ¹M1-¨9‘Á2'Šù`¤ä	ï¼’1'Yøi’¥\zÚ':åfÖ‡/+$;,ıuâ@p¦!1çÙäş’ZrˆSˆK›ŸÜmòY]®O±×["Ù©¬müÖe1‘¦¦­Æñ>V¡º³må”,ŠeÓ3#¡±$-÷¥4Æhjô§ ĞXäšãöò.&¸ÛÊRôö© Êß2ƒ“×.¾ÿ."Le)wÍö
Aš­…ã€Û>`õ<cp:µ±>ü.=)Š´ªÄb*ÿÚ€Àâz(Î¶^Ãpª…`Ù;cz*Æ€Ğ<ÿ0\Æğ=}U†®öösfà°¢ß‰Ø{kì÷<¹Šö­m˜~—±j\F†¦ã!m2RÕ­7À-µºşgğ¨›7Llãp¾.k3pÉR°Ş5¼§´ƒ£¥¶o0CM"…±1lˆÂàˆú)™kZ§AÕòé•`ãµpôl'5Ëö3b	VÌ¾•H:1kŸ]İMRşª‚òº³gwsº qË#2¶8£ğÄëõ¼p[££î9Ø³\‹¬Œíÿö÷—kz˜¸´T–Ô®’…‹ª¸¡àÈÜé[ï	‘­>­ ìåVúhT£¥Xç;.ò§¸è¹aÁŞ D'ĞuéÀ.İq6L‡"V¾ï9øT0›Aı¯ã4¸âB8‚—ïÙ-¤˜©º°@JßQ_ß’¸FYê”×ÄÆ=	WÍzÁˆ„Jô›ÙIÄ_:îbiVà2é‰Bİ‚¹túI@6»€ÈM+Aæµšİ-C»nÛœ_Çë`aSZ`:«l¿à-ÒÒs%å|»”ĞñÈdU:û¸>ÁïGø#¾Ö?)XĞ¨\*±²+¨M]IWW%UWêû¯~al8qš<Íû1ba…XôênJ1cøIñë(«à±Ş«QîˆLöÉÒúÄ'k­Vû\ÃŞâ»M…„u)6r!¤ÙcÔ§w]4•.xØÂF&~s±iE²mÚ¾¾ûTÓ:"¸ „Óu™9¬’˜™Ç¬eÜ³§ŒR½Å=áÖJ{ÍXZµ<ç „•£ÒºR ueet‰e|•DOÂz`7l5)FMû±z}šç¶eW¦¾O9T×¬Í‹U®äóıg[È»ştj{ïµ¬’ 7C8¼Ã;wñìİé‹¼Úrm­"ÊÂ·ì9Û©cÀî¶Ë4ñˆÄV˜éö·.ÑIÂwE®}á?<@®S?¥î ÅUÖ¦ğvŠ0Ş¼áB–ğ‡>|>ªÿÈOx‹ğ}©%]Ã¬¯7Zè¼cš£üZ’¯Ú±Û˜Zç«VçB¿—ŞÏ%ºúE6%3…2Á
ÿOà2{˜·óqüÀ²ƒƒÌd	r½bÁ½¶HYÈİ0L7wˆô<]¯p0
øŒ¡1Z)—“‡›§ÕÓQêdki˜	;Ú"Ìaj„QO~_xìz‘­Ôğ	‰Ó~ÅK2ù™'›æw|>‹…ps+c§BŠ5,ÙåoÃ³VıÊgwÆ61Y@•º»+€/qÚèh=ĞÓû´„'ôz6 Ìtv¨]îİe‡>±2”Á5Æ,	¥}íğĞà6ğ‚ĞŠšÓvÅsë©°–•Û¤ãµ.•Ÿ¶=%xé›ƒŠvP¥ÎoĞi@ø0 È‰É$Õ!RêÖ©mDóY/¶G“v6NŸ>.îÌËJPè8?ëÔà{_Ï<îALÃ˜Q.·Ù2äê,ÂÈvxÛ»Ÿ2’ĞVøx÷
m9ávHæé=?~ZË4¯Cÿ¯^Ğæ«é›Ø0pÖt˜÷WÛ`›¶±‹¤¯àü¬uø`¼†l°=[„ô2p`Qn‡GúK¬_fº~#¤!1'XpíbNÔ4LU•~V©Ö™÷!m`#“¸¢'Y>´! ÄK#Z_oÓW9Yñ,)Mu”"%Ú¨NXOm{°N`„&ŠŠ¾LF•í‚@1äµ„’çÏsmê|Üc‘G	İİîÏX¢æÄ´ÌÕöA—Šèõ¡®uªÔlê“Å?»„á“w’C1tÆ{¢œv@Ã• ›Aí4­2Uçi8ë+å©¿òR„%Ä-øvá(ã"6n°p’ö‚OõíğwU©*­œª}K ¼;*†”ûh8—“—{nĞATFñûj}mŒf‘VÇ-8Å?#àœ›Mšk·Š¹¶Êx¬­Vx…ÚÏêì\úE°¢\ß¤¯(À2ù} 4UÌñjo-ĞÉÌŞQ–´èXıäS @_'¸ªö9ó…6Ğa ùQ6ój¦°G8Ïšfqµ¶@†µEYî`Éª¨{vs€)@0”‹ËG9x¢ı™–¤‰#w{o[l¹½Úíïì¡Í|·”mD7tŸyäVÓÈf—ÕÕÈ%ñ ß„³=”œ®½y.CWm2Ï»»ššı¦É1V$G××¿Äv3P@â;ç„4³‘hí.s–ôà]¡˜BW?ãÆP™ İäÇ§}…âÏ3PŠ6çìY‘,ñaÃÚä]Ääœ òŠvxìóLğ\#v÷’/j;úÇo×ö¼;õŠóÕ("Õ){u Q‹ğµíh¿=?†1#ù¾ßìGŸ|x(ÒTEÈø3GCÅÜcø™-UççÆò	µ'"Ç¨âxÜ¢bÒ"òT»êíåæwÎ±
¥E8½ù·ü9€Ğ:Ç¾È¸²†Ëÿ—Y’kQvÙuÁğÂ5Áâ—¹xç¸û^	«?öTÄ
€-ôü¦Û}²4jÖ4¸"ÓPùÛàŠ‚Ö}K ø‚u¢ÕKôÔ¥E¤4#èUi
£W@Í0>xÆÁx„1G¼'VÓÄ'¦i0Å'mfÀĞ$ò ¯¼;ğ™’Ú´n.ÿ/ç¨‘%Bøtf×ê¨6„ ªŒ`¶”!Êï?Šo¨sšŒfüÍ¶Ó!ê¦v8ë€©ë*Ğ†ÚëA ğ½½ë±èÓâ‹ğ—g-©Ô¯Sëÿãí­æëª›8zë™Ë¬/3ÀÄnN+Ùaò|¯,j@}MĞš\èdxÊ˜K:'†üĞôÇçRF`Ì´=BiÁX*w¥W¬k³5ß9ãüæ®(ıkÓx9€Ô©U>eê×–:Äİ4ÅÊoÍò ãè¡VÜ«wÚ»
â,&qgQ‹t^®áù¾Ê”øœ„~¡$Ê¤ª&O.ƒZê¿j'Q¸Ü7ZCkûœÂÚìŠÓ¤&Ö[ˆî±ìè÷V³Ív|ÌN³²ˆh¼óàr@}‡Kó[Òy&«×šƒÎ`Ê–•OEš3N“{Ebó¢i*—ôZÖRÑÕØ8é’9tËœÍ#ÄETû?1{UX¥u%!u)'ıõ§™ğBéí†,#jü/ûÑ•É¯˜5–—á!,ÃéÉ[#Êá}ã õòŸªséKŞ)7o	Şº,¹e¾}AzÈÒè¾ bx5HW)CégÉ^„	Œ(Éq*”îĞ¢]æULÀ›Ş0­iÔªœ¾ß´x*h¸™Rÿ²(h0†á=.º^MD¦ø·ƒ¥xyí«ù5ì”¦ÊlöĞÖS?(O.€jµœAÿ%_vš‚ËVwHïbÚ`àèí²ôj²Sa6ùâ'ıFRïŒèñs%È|&›@ˆûNä,a§Vpwái¨ß¸Iì—CÒJ6	»ÿßET|)• Åéså¢°#s^JÖÑñ7¾xõëš•ÌâZñ€ÇËÌøá<TZ çÀ`TaPğï.j!xÜ:ê¶R&7¤+Û¹é)Øï19’%!:#èÏurõ€’/òs‰c¯üéu@à
Bæov™«À]İÖxü S‰²	9cB?¦œ¦îDUL« ˜xØî‘6”J.uûN;‹«Q1qé-M!Dô>`É'úÓÍuªœ˜qÆDŒã~·Áå…xééC+Yø2&ˆô,A«F6UªcI•be³Œb0æqĞ:*Éb³€ÅMû»árq*áÜÅå¥óÌà0ùÀ®ö !ñw“ ”«{‘ÍN¾'+ñ¾!Òu_«™ ùÄsSõöL%¯H/€T2	†E\!şŒcÎı«GFí£yú„âá7 U{QÔSÛ¾1/‚^4ïÌÑÏ-~0–_á¶eÅÄĞyÜ´„d–²FsD6MìN£_b2Wó;ÏÔ9‹úù%‰PT›Â“ æq¹PoFjê…û*YÂ†Â© ºä6d‘zû™WßKšäiâkM‹‘ˆíºZ¬ÍQ®„§^NñXEğğ1öMĞÃt#r2ş;Ï&	@BéĞ÷›‘ËL. TR•í·†©@‹KA9ga—;SS‘o	ê/A(›À´ç9“g U@ÚZÉ&JßŠá½5¬™â"&!L:Â€åIôJ›«QPŸüw{Ş‘áˆ#şzæÆß("A[<33Âù”H¬%ÒÂı¶o¿*»x"£M*¿ôòĞËŸ¯©n”­¸â›¦§Z•¸Å :Øô "z+(ª][>˜Â£¶5€Šï_ÀÏ]P·ŒÈn¢¼
H²öÔioyv+Ó0 \ ›g¨Õ4â¡Áw¤„UÆN1¿¡	@?\%öí¢1\í¨#Çtî˜}õ²§Ş7ÂyFAhF„ì+¶‹¬Ñ¸À²6³bÖu\…ÊÆÛKvú«DÀƒ‚–’^™Ëàh¿v!Hä€+«‚|i¦ç—zfºJğõU`äe©Ÿ±Şª@QEù”)–o]Á×¡&;ûc‡V,GÊ’y$ÂÏ®ê“È4ÍaJ{våTD‡—4c3”MäÎî"òª§@¿+‹‡ÛuX§ğ¦\{U ˆ<@ :@Òlæ9í5Ï÷êuıÁHâ9½æ‰Ş¿¹<ÃMFc*ı³yB«Õs)"‚ „o*|ŒbO¬Ğ÷D©€Áó\¯©¨Àõ¬XY†ˆ4fv}€¢Í àÖ—d2=«ò6t8é–¤¶ğ@ËoêÈôáIà’éšÈèâñÿ›â«ÒÀ'‚×x"!'Dpå•Om˜4?cï‚Í¶tÑ‚»—2¾J

oıÆhS›ønc&{İj^ö¥[xòy0Xú¬ÙLVày€¿Ù¨Ó8–—uœ¡2AÃ’È³Û)¸ŒşÈõÙŒ¬©ÃæØ»Ì"¡ÏŞ±>ìiæÇĞ¾/\hJ:õ$24!Ì%0|vò\Äê`e\¾+Úø†îİ ÌôwŒMíÂİ®Y•«ÁÑXìyƒ°®
¢¨S™ÉĞmæ
çŞ­+ğn˜ë«åGG´û4l÷ÍLfğ„J›ûn¥XÒÈÀ“æàøãùD†œü4j>©Y~ÒÊZ^+¶Lå>(£h„¯‹o²,‚™ï;m	ºÁ®À• ë‹83Ìÿ¦UW“[²ûyŒ3Q¾ÌJSœÁ¦¿\pƒyÕJå4f÷A(Ö·Láqı°°ËîõJ[»¿ ¼£ˆë‡O¨×vêÕ§Làm|éÚ7è§Qû‘Š#±‘ÃBW{×€u„a(¹§ò2TçÚF	¢"û;­]Æc=PÒ.‡Ö8ÒQ&ÙoÏOµä‘GÜ»kÓİğÔ%Ó%š¿ç•£¸×ôpÙ7Å?:ãÊyïgTøİå¼¶Î ‰Ab,ÁŸ2gÓY:?3”-M“ßú	mì¤'FÜÉğÆÖl‹½üzWñ—¤ÕÉJRuÀ ÷sÀ·_B“yoqrÂR€ìC(<Œ"Ö¤îA½Ğ6fŒônfà2.± 	zÆí±„u´Êì‰ÇÖê°ß]Lmì\¶búÜÊu·È~ÕEÔÕËe”{©»ƒt.i`IêÉ/Î3Ò8ç¨ëéb¦İMâT.rI$T¤!Ş ÿa/¡«hEîW.8,Š'Ù.ƒ“èáÒªöi‹A®†y¶³ÃMÒ@¹`—ùó Ìò©uÊk
5®CQ†Ödg?|èş` "Š2Iq†¼ØÈgu)Õ¡Å*ãËœûã/–8º¨´¹\"6JåÀ,”¨÷ğõU‹ü~)‡‹ûU
VHd}L_pœ2ÌÕu—Æ”?™©'Á'¤©ñ=ŞäTE;n²v\wÎMöw^¼læ%|=Ë8Ÿ€È;Ú–Œåİî´ÄÕ*g¶ùîFMâUˆÖÏ•-Is‚twÁüÿ1ìÇÇÂ_T`ÄrlivTê8uc'xHnµ¼ 7?W.I |ñ.=|ò ’ÇzoÀ·’Z«óyäÀúƒ´¬O„†iğ‚ñSºŞZ4û‚t:i-PGï¡ş‰(„Ğ½ŸûO~´Ô\¾«d1 œ&w)†}·“«‘ì%*Ü½FîåUaå	µ¶3Â@CiLed¼i™P4S›ï_YĞ]×Téa¨+ªføâ4¾WÈ&U\Ù†9åªcpÎg3y¸’{½=- 0gÆ×|œªç0ñá¼ÉÛÔæ¶úx–‡$(ÿòÍy~R
“b	äÊŠ@»­ÑÆ¼FÁÂZ39áŠ·Ä¦pa&_ØV>ÂgğôŒv‘éØÂ«ÀşruÀñ»ŒS’É$çÕC€D.êíb¤EAq[ö0ÊE]¸ñ-­É,}ÓúæÍÜÙ‘0T¥ÄAù ƒ=,“À$©’ŠÆ$ æ“mÂˆÂë™Â‘¢ `ã}Iƒ5äFïbou$ã$ıU.¤S2æŞ¨8WZôğQ4ns5Xj«&2)t	–š!hUX;%äYÛÔöÑÊ³¥Ó”=ï.4ø[¬DĞé¾{µ/
gTHUÁÎ­‰1…Éøà…Qyrqúdf·½Š¡J¦!(ï.Ş¤3ï½7È ‚'  AôY±€>ˆÎúº–ìÜGñÀ^@`§;ä•Ø‚Ó›3±Jr¹S¯î4tjŸ_²4DKZ%*>?‰òŸÇCePş}iü!Å"'u1Å8)Jr2ÛãÜ¬Ù±ÔŒdÌ™HaŸZJÑÕİÍ&=èâŠ²Œtuß…‚’oÒ0+An¥N‘vt¤Şaİğ<9IøÊ ãğ«Ü.ç¦ÅR}i''r¥²O*v…@»ÅÓ¥Ğ±¹NsâõaÛš%÷ıÚ(w2+şHÿ­ë$¨ÕßIû/¤Ğ>î(š›àß;åd*œÉ”ˆ	Ö³…½…Æ]hƒ"-øµ‹¼'ñy˜ÄÑìSÎ™÷ïBpÜ\!îbÆ C”ÿñj¢Ü•Õ´€äı7‚¶á¢JçÍM]ªû]0Â¦§\İYx»šÅaœÛ~³Q±'®¯÷¨ëõ‹¼sÉ±ÎĞÕhºa˜I€u;(à±iÍm))
;xÁŸ©GD:jI_9Ò	È(¥…:öFYû_­·@şEsÅ²(æpÆĞKN¿ıáj,°äÄXz–nÙù:bR“>îÙæ:®›ğıò˜ÚÒğ¹£óŸu¹mJ «Bj)5èˆBsÉqÅ˜ŞÈ-àÔwÀZ
E&¯qš72äJyN)išDß•Gÿ(QıóhBµ6òÂĞ9Ær†gO¹ÿBÁê!o)m»°›}Q®EÅáÃ]ÑEÖhœÈu5M‚¿Ö“|e|ö¥ áï•úœ	˜Õ@¶¢gÌ¾ ûúŒ@râğÑBt{ŸØçùo¤:¶¤ï›Y¯İk(štâíèZ„[•`æóñ=W:»3Şt¿è†p{LU”ÃLW`ÏøO8š5Æ€BÖkœ•®Ğé‡xïßëkÖzvO43 ²ø‹,e´1y²ƒ£wÍÃáÌÊô{ÛòŒöŞ+öıã"`2:³}&ãyøİf­=BLz3ö»#£ÙÀì¾‹E¬¶ççvf³`µækºà4Šºî	h›H"<eÏå÷-ñR‘ "c`¬+õîHTA¯á¡’àñ'§Ÿ;s÷Î,
õĞ4	¯:ÂøÊïa÷8Òà0C7©«V¢Wf‚l!«·l}B
UêO1_0% îÑwE¡™™{I”4- ˜¨<5e{07[Œ¼ .+-zw'LÄ†3$¾Ç=ãøıç±AãBgˆøÈÛá÷‘‘ÕŠ*ns+« ÎÿÆ>…ãœc#Ò,‡2ƒ¨Ü6^^5™}4J¹äuÀ”t½½.šmÃøğınÄô†wğc}p;	Â¥à€ë‚ßybœû©™PihsõÏ•dÇÏ³K[˜}@­]Ÿ³zubŠ=ÂI˜Ò£sÃô~Ó%ë	ÿu{·[=G¡,Œ7‡Eø`J´?mçœ÷¡¹2ù×Ù%3:¨äEL&(¿DMNäkaËgy¹99B-b%Û]Æš›ÄÓ)ï„¡y	©-2¡¬ú€ïÅÔCS”7İÅê3U¶­YÛVg'ô^Qu"ÀUzúH~¢†1¶‡a¾€k·;ÁmtqíQğzusL7 íE`@İÑju=Gş¯ÆëNñÒåjÀU®q€‰ô°¸ĞX¤’#ÄÇº_1’ğv·0
U8İ ÆÏw2$}Qc½ìœvÌ=×2ˆ¾6Ú,Œxí¥¤ß‹y´C0v”ıNÌ£B:[b•ÇÊ
¯·1óª‚bÒ4¯|8%«-Iƒ–—°Ì¹O]É!D3õø5Î¼qS‹ÓÖ® Lë·Åí[	éEşå®ì’Ş;ˆ² +ÛR®Hp’•ò/Û¯€RïR¢/7½ğî>ìÆH„çoµÕBVdñäãSÛĞ—peFó	hûYŸÚ/bˆÉ,÷°¶Ú>zuOË~ÍÆ..áh;ÍGášà‘jŸ³qMŞ|%]øÔAÓÍX[7êQÚŞ‘­ÅäÒ¡É¥å¿`˜ 
ÒÒg²‰ûê=:¹/á:¸´(o«3Ê‚û¾Û 0ó[ºÈˆ—ªW(ánØ|¡³—Q8º”ÍâFòr¹¬Ÿ
ïîêpbç+Š$Ô†±ÕY$ÑIïã“Ä)-O‰ƒU«!±UO
Eî©÷æß5Š ,ïFR˜&tR‡k‰Ã–hCPW!ò*~Ä%Nddâ¦Y5bïnqcJ%c+¤BøÚ‘ƒ?SU–T/ƒËùs‹å ÷ÖR·]N˜¥İ ü”ï °ä8NV3¿ŒLœŸÑHæ×Ì0èe,6re4x.ÙÉœÑ¨]K¥
xĞòµWØğÎÊZ :•ç7¾ĞvRí™år83h[FŠµÜğ‚;8ö! ôsŞ±3|MÎo¾½–`Î¼çıÀFY4ÄâÙÍl"¹Z¥ÄÑ„FØòç¼`ù‘ä¯:3ºôó•NHõÚÉ4WÛê–¨f›{CÈôl¿»­ğ-#<ß£æ\Y¾Â²35ô –S$ù"Ë9ëšdNéÉ¥XÚ3"÷‚zÁá1vÊŞ‘üYõHî§ñâiÚå%ğáœëo·Ô“øGF˜İhIí:‡•€UHÊ ‡*’¯ˆöÌùÓØTÔ¹Œ‰˜ÕÇ´.9çskÂ&z/¿HŸÎ°IWÅ4î}ãl:Qóé¹?_˜8ØĞ¹ìÊÿt½nAÄ
‘ø7Aª‘Uš+Æê<¸WÎPmìo4=ÛïÂÛm™•ìû_M¼H1ïŒÌcfÇ¢P‹k­AQî¹„ŠXJî1k*°Õ«ˆ$¼„×wĞ_Ş©ü3¾İ>65!HËçÊ46ô^²… o¦¬Ò@Ø€>¢æ¡9OÌ¸a?âzÓnÍÒY‚Ë™òÛœ×z¼’¾ÙàÑ¦ş	ú”¶O	ŒøÙ°*‘¾¦Ÿı1¥wQÅ6Sá5yÂ-ÓÈX×]i˜æš2hTŒ½"`úà¤)T 9ì·åGìá"‹-5ÇˆãB)d/øùã7˜ˆ"İ’Y'µÎ@‡¼-¹=O\ÃïöĞoëEY£¥DS>1É*àk!,SJód¾›Å@v ô«Ïš¤n%)Åvë•]q™‹ğ8ûÙ©Åçº@†ªo•BgX{ò]ïÉˆşzZ-8‰y²·ÆÛûİ1õl·ş&ìª6$õÛƒ/3F8R\âœRÁwÌ£	[yœ?€b©ÂgfvUşñú§Ÿ®’Ú­n4”Ñ"¸Éâ÷5}²œfÁ6mZB*”,<Oú	V9l²œ5øEyYÏçºÔç³HQ'‚ßO¡QkóëBìt½8Y¬Œïx¾€‡(´Ö<£¢¡}hÂ“1ÓäË0¥K½„Yÿ4
ØÌ§4€É^l|¹òÒI]Gİ{k2BåLo(ïkç<6>	[«²Î}hÕôe'WĞ‡üpÈ?Ùf^P=ÊxsÜfï³>£ øv×\ı.ç.ÖÃabÃ«6s€‚óü2ÃMÔúÿGUF3?zø¥ìÑÃŒ½gæCõ«Á²Å_2=®??¯m"«´;é?:4ÕØYÍY¶r¬tåS‡°;ÔÃàx7.çp6:œÀPn;9væhFIØ‘‚ı5ÒÏıM¥ELk:7øŠæğêÆ/¹
.\¹˜Y©/Ï˜ĞÛ_‚vG[hõ®¢ê¹¤í¸ò™	/¡ğƒU$÷'wÓèÁ;K¤òD§s{G„oşÜ‚Æüx‰/+¡Q«	&.ëR–¥Â±S/)?*^àP"N§ådñïÛ	‚AÓho¡¿H°_,äª!x¥”,`§ÓNöxûÜÕìè¡Hæ§>[/Æ¾…¼‰5[Æ&°ÊY4%FEaäè}BJ-£®¿I/ö;Ö½ÈÌŞ9+T_<è!µ4/©#ÔÿôHŞû“!¯kò9Ìâä/<7ñ²œ>DR‹,Ä"cƒÿ%áË&ÃÀl<ßò°è9b2uFÄÏCÉÒGböWAI%É¹Ö(ÿ÷,vÂ««ÙÒÔ¬jõdŒ”¹_×ı†lÈnñI,á_ê®Ñ~”í³P¹ıê'[§J\Ô©{f•ğôX+;·aùÏÒQo¦|–¢ª :B”ú†4,˜.tpŠÈ
jr¢D	o]¨@ Èe˜ûlàJâ%ÚÄ™™¸Qò
£¿_kï:åü£Áçìi­CÀ0¶À¸Û,ÇM9.¤˜fwœVXé#+GcØ( 47±²O…â{£¸dïº-Ä‰ôPÔŠÊÅ`ÿišôaÆä¡h ›ÊÚ5|,lˆ£QëÖ¿õˆ%UÕ=°†íÑß»r’è¬:12BJad3piÉ7e¼ßœ?£…ù4Ëš_‚"š*;x(g|‹TVİp«ĞÈQUØƒóÕÌ«î9‹]£PjLÆÁòB]CX5×O¹Ã“-…ÙIz<éàøÔéDû^Nj¦µDcë°#Â‘ÿâl7¼ëéñ%¹ÿOV–J	­<áì†>ÈïU:´¦÷ëJšaíè<Šš`,„–·N›’vÈf”r/>ñÅçË£š{[›Àü?v´Àù$hì0*¬f£+–­îQÊEè"èÚk(lKğNÉƒë+qñˆâà^ªï¯úôkQ·ç™â{Ï½_q_…\>0Š¢3úéó}Š¼/SB‘MJ^H¢5W4`»Õ÷‚ê•R~=Ê?!vßä¡°À|ƒ,su½şAÇkÄ×Ÿª©ğü©Ò)­ç/UÏŒnA“½“ †0ƒ¾¼Ò–F|ÿË†á#.¦Îlë/Ë'¶·Ó¬P†BóUß¼¡Â´2Ò­3ßl½,MÎ¡ÔDvX¶/HâÊztä8âÉF•9bZu¥UcRÃ7aÃ²PZó‘¹İ``İF“ûñDvÅCo$LïÀ­úcu¸FÀ¨jš—K‡ò¿ëºÓNÊ¾İ¸»-‹«xÁô0Õ¨í³6şIP/µL2™»Sñ§•P&Âõ0É:¡ÉS ’„ş-EtÅQÃŠœL²‹YF²SY[{Ä¯/ŸO@3„j5mX½õDæ#!äf¸0úğ$´ôàáë}ïÛ¯@‰ŞwÏó‡‹ğPÇ/¥:]ü	2&/<Ôä?0ù}~V+„bGÖ.p”ÑâxŒ9;FSkA—_ØØìy“¼ÑqcYB•Ò±½ÇŠX–f¼­	¼0›ÄZ‘Ø)å·^†ìx°öù÷`ô@ız¹ÅäUÂ¿=ú`!DK7ÆKŸİË[]`ZÉYÂ‡h$mø¢“]©et9E³Q¿£“S0†ÎP¼Wiwl×8èí×lh[$¡M;<£ØeGoú‘¥W‘ŒD_¡µZ‹=?çGT‹õ'9k3¢œÍj>ô¯¿ı…—şsA–kşïú/é¢UaZN|À-şkSANÉWÁ
ÉY¡§xbWÙÚÕÉHg%êØcÄ¦j‡½4=
aNûÅU"jÅå¨~èúËˆû$D0Éõ™®õé"wAB»êëVk-Ú¼@¦<69pÄ•Â]K<ã®}ñ)>Ïß0’í5F^WÎæÿ#İuÍÛ¾7ÃÿæD±rvº®¿ËINô£Î1S§};Ó=,'¤-‹ÊvéÃ±& ¯èû—„X×1hd6ºC<,ì–[ğÕ3‡™ÁÉ+9øíŞâ‡Áö¥År(Àgœd‰¾z]ÜfKnN¨Aô(´‡R=¢°¤u®R–>nñ˜â×\Ö™ÍW“`yğIH=QÒü‘\œ÷æ)äe‰Ï"z*Éršƒ#v"7=+Fø°…`Q‰­Ş|+#ñZŠ-–ŠPx%£!’š“+¬÷² ¢’Í—	`5×¡1?Éìz"y3©¹Ó}!„ü@Íh>}@úìuZ©2 qÁ“gÆ­i¥ËE‘Ïr¨SˆĞ8(AqÑ

`Ğ½3â¡gÃy
DTd^¸·­7 B4‰^Û\ MéÅA-ÔÑLnPyÜÔPá¶LkkXÎşÓÙoİt
[ZdjA§.ã…M&ÉÑ²±°=ÚŒØRõqd~ ÛÊhŒœß‚ğywPB…œêó'rmÎ
  çõ“Ş±ÛÖhI–ÊÑ5WLÜ!¡‘ö¤¬u@¸ÑÍ!„O¡Å¤7£@Òğ7~ŸšWÎVŸM8ğ4×ûêµ]§"‹ô°–ãÆæä#×	4ó-á=·óšäÍqõâöÖĞ‘™-…ˆÁÑ»û–koçÃ‚‹blÎhÑéHÁöYFT:òx¶0°>1‚«s…p÷ÄÁÕíÙT±Ú:Öz=Á“È+‘GŸÄ°–Ÿ&ô¿6¦î” rLÂeŞn]¼ÍìOûEÉØĞy×}İ,ª(ñqËÏÜ5İtåçë>Ì@ôÀ>{¾²èç¤Âà@5˜ëˆ Qöï‡¬£åš¹zEkUdYOV_„ I›Ş÷Ï-M`C,QĞT'P¬ëOº”<‰°wèw‘ü5'À$ÿGXÜîª:Z.ÜÈæÇBU(ãi/Dz?òMfğìÍFÕŒò[]P ßlÜÁöö¿òÕkŸÛ‚•ÄæßZ“TÛÂy\+æ-¿è“ÿL1÷ï¯©óÈÄo·‡6ıŠ«ôÉ•¾=hà1ãM'Á5R	šflBƒ›ƒÀÓjÎtßË ærG3ë	\Ãq"ÿ=PJc¨¨“±Ôj<¶‹.ñŒMƒR^Q¹¥Œ|óè£%¼X È«bdk`ÒV‰7üº …ªƒ?ãN©ÌE‘d¦ó.üÖşéqô]Ë;=sJG–3åVû«lF¼Ce–T½ Ÿ#¼Thz‘@|¯ i-«kñâ×>EÂÙGAK #Öt‘Å›’§W £œDÏp©’t,òs}Q6––:úÛÈ.ß%ì¥Rè]_ok†î™€½M¸ı¢r(­oo
;Ù0šÀ¬+2ä‡‡ÖÊÃRõ>Vzä£¼ùäEëC=Í§2à×*¨¹ÛŒ¨Ì0uk'ˆû$²¢˜/D¾…ûnô5gQEÛ¸3:˜¬ÃA¶ü½ı¶Z}­?»¢£0$LÆíªÓú‰ó­Y£Q­Kh2®ÀEìÙ­¶÷*Î±CçpÿÆÛç¡g‰ƒƒº{’İÚ®+„‘¶H$‹Ğ“„ÎU¡ëbNyT~'%*‘ÎÅşízçm±ˆ‹<
õèş‰ëî¨R§r@#¯7U{#Cº(¯Šï0£Nwsÿ—¦ù•P&&K¢7ãÂ]î¼ a´çR"	‰IŸyˆ¨{>î¥FTo›R¾¨—3vÑ½ÏÇÃÆÃ[d+‡GgĞz ågÖ¸~7,©D0k¤vèÓü.¶œä !YXö…-ú÷sŒÿûÍxj/;t0]“§ñ·ªÊĞ@µDŠ©Œc®6¤—’eÜÑ±$+Ş·;ô¨†µ\cà™›èv@ú_0 ¡rù§Índìw]^Ô^1 :±õ*Å&Å%¦yïœ×ïæ–Fƒ T¬¶?¯U³{¤ïÌê†Ş@æ]Â2d™MÔŒµ¾NãÂ›r\ãMá#rµx3'FÈÏ©‹n[öØÒÍ4¥¼øÛûTbî˜eË@Ö×áÛhr«Ke#«‘u„l3g(c!U?õêŞÍşl{ø{İÏ–11h¤¶¨<*ÿ B•†ú‚ËúSV=’pZLĞÒ´éZzMPQ“xŒF.<¶ÁÊy×ú»6%?®Ø—ˆWb´9v{û…½‡;òJ«Z0d×n¹1F7²„89Ãûû r3ÜLçAk$ªªÿ‡½#=Ò˜]»L·½gˆf®¾x#£¶ |vO—¸‰ºF‘IÃıÄè@Ó5øª‘#^µáu5Ñ§±Œû‡TÿLş0†°J‚‰ÛãJ¸TE¯b]Fdf
`ÂEÁÁkNaÁ<ôÿ®9Oã~ƒƒ/]æ`m‰©×÷ì{ ¾u»İ54zóí'Ñùª3åBc×.·¡S’`²z\_Áqb^QcË¦ê´ˆPÕJD)G`¼ÈŸyæ£•ĞƒEMÕr%ZUH×uĞì4˜]+Ahöê2É’šA$…»TÖ‘ï-Ä^”ÙD•E¢»¾«4x­B²4*ó‰j‚ì#ôD9C4N7È¤6¼pgğ-*âÚÇj@ãG¬¸(ÁZUğ`ÿ«Áréhà¿cô¶‹ªÛ‰Œ{?IÏg—­©ô%lÑæ•ˆÁ²š·¯b©´r1_ó'7=êqùñ^—;K…÷O Èzı¤`¯i²Òº»Î­¢„Ëq¼8ïnÙüÈ)±;È§<,'ëeå“³	´¼ï4Šó‹ÅWÒøÍ$’£¼¬s\kD.àt<uš‡!O–ÛF@;7¼VK©Cd„ÁgPTÀG-º/6€ìşáİÚgI>O—€çíÏqA¦­õ,Î¦8{áasËbSøµJÃ9géç–M&}•:Ş÷ßeƒ)øHŞ½ä¬çÊØÊÓW`bòJ»™*K k¸:Š/«›HÅk•èû¦ô{>RŸùš@S2¦Ê 
PÃ‰éõQgçÿh+G¥	²İXqElLL·#p¾c·>Pä>‹»ÎA|2ç•È¹;Ír\#³ÏXD?ÊEBÉMÂz¦ãØ¾¹ì°ÂnBV´'Š;ş\FÛÂK¨ß\I<ZO:sxC+–~	ôIÑyùº¾]®û9Lj¶#Evu¾%š)ŒR
.¬ÁøG<Şy`•2t²(÷5‡å”KÅT§åMğ’ß:X™"¨
ÿp8îs….Ë=šD%–§cóxe Âñ7åºãR5Åbù2t<Qpˆ^éwëÌœ7ñM·‘‰M»<•n/ÇbbèËA?}¦LJnÊüÃm Ó]LDì=éÉ°ñOÊøÜo¬i3w·"|h99pUÄ¯A×]1ÕM·q²Äû%"Ú¿Êé)`“Ç½#dRÁ!Da‡øZl-»Ù)ÈOîì³”
mt/+“ü:·ĞLå×éÕäÇpÀF«|Û  ®J—ú´B†AaXÓ*ÁÛ<Då&Cû<Ûòäİa¦[ ËNÏõ’«ûá3w'X«£ù¼ODŞ ;ÄœÔ	dÍ\\@ºKmP·ùê¯%ïNf3f&Ñ’0lãÛB[Î”ZÙ‘Òª×|üÃ‡³°®!hd©Iä ÅÚ™dW*ıÆRÏ@íÔìK™_¹§Éî¤ø¡‚¸‘&Œf°CÃ³lÍ§<è|ÙH3À4õbb$Â[>zN5 yõe\T?IÄÆtĞû¢~Š+GêªEÆ¿˜ö¦Åº›:	ÓÅ¼{;gº`æ9“r‰)6N²Kğ“gmDt°ãÀximˆŒª¦—í_k®uãvÅ¼/ïöÁ#‡Iƒ¬ÎJa¬nh.A²]í¸âN‰ø‡˜Ñ\~\´ë{óÛ‡jl­Gã†D,„l¹ôˆ$ö¥ƒ|ºº>Œ¥
@º¹S²† ¹d°½:'faN\qOeùCrCãÑÖ6×†•6=à˜cE…¬z(²¿ğÇNÛâ5¥?F2ñ">Éë ò2…ù§y§(–û<@˜E¨Šúâš’x<¦o±cSP×k-ıaÑ36Ô`™ª=kTÕÕ÷\â5	ÙŸQ »5à¸§"E±wXĞ]³20JnYË$	¯V_Cˆ¢<¯ç…b^>şiQÊ‡ıé»œV«x?ÿ+ËXETª¸‹#5¥"5LÆEú{ô¹‡ó^ğî]K•×ÙéÇ'l¦%mÍCD‹¨Oºäí5‰ƒ©ó*±‰Q[J°°WÙŞ0YÅÚFñ­ó@Oó‰ caí)…Ô<ÇĞ Ëj*èlæÄrÃØÖ“~gBÆK¼"­èq#y ı2~p·[‘Qq1:ÔÖŞw¨cl{=ø-¨ğ¼j"
ÙøÂcô–cÁ
F„tã´±›ÊLZ¶„“?üQ”£Ü|¼^A/†ı±ª`s<™}Ùã¾¶¿^CuQ·é«5€ëâ–ö—
€Û¾E·\‡í¸µ+·ccoVÇö@`;¹›‚evFˆ:=E×ú0Ò¿iàt…ûV•¨8¨ÕÖ ÈÎ„dnÿJÄæ•w¯;Àë0Ú4È3øK'På19|íìıŠé=:z}ÆÍÖ—q¨\uK?Boñ ± .ãT¯WpÜĞy·ÄÆ_ZJõÛ4jÂ%éá‰g‰©l‚7!%X($˜êïõÔ¡¸Ìì+“fj†qòİÅÉ1Ì£
%õPU/œ¾Ö#mk cxlxÔÍT"³¿Ë§“J§?Ğ>A—mï˜ÌHØNâ_`õóœp/¼™ÛÒ ƒV»÷xî™‘æ:û»6ıs –KSáÿ¬ôGpi±¹´?R¡F—v[×R=á^L–Ÿ9<õ¬\àIbÎÅDÃï®ŞV¾a\r,¯d<r6
=‘?w|"Ñ“}9P(ïFY!k†O¼&;ÁäøEiPÕs3ÅËîşÿD‡í¨—–;àP2xÉî¿&p»(¥[¥ÛáXXÿÖ…B—7$±-äö.³JéW9L×ëó³„º4}}‰y—Zbúª÷XŞÏ’æÃş#ô(ªñ„Œ6,Ÿö“ü¥)ÙıudçkBf SØÂ‹Æë B1$­!dm–Ÿ«È–ÉaÈCI£É<pØ1bWI}¯ÊRšõæì\(\ßmäòİc±òÔrjIğÁƒNôæ±ÆîV=)ì$ªâÙ¯YÆ
*ÂkØòeÏ5ıÁŒ8|8ùñ*ù¸¦în²~Ê{™1º–0¾@Ô6Ú™Wöû
Hù<UIØÉ°{Ki·ö¡b±ºŸOp]LcÍÛç›Ï\Ş·{gN'Y€ñíóÀ©v¼UØU²À~oxIé1<‚a¥)ÃluuŒZı`½€§ş’Í%ÆÜgö™5şAäf”*sĞó²‰€Š°?âY‚¶9Ú
ÆvzÒ\¢ŸPå{ñŞál=Õ^TÔ¢‘ÈSÁØfFÑ1"ğÂúÕ­!*	\E©µ&Üzá¥*ëO§da/¨¬ˆ¥&P+eI(®J•„9‘DE:p'r!Ğ #jG¥úù‘ïQŒ/ÿà<ˆwz	ÍO€İ‹#ú²ÊÊß¡:?®ğãF¥hÛë[6ë}µÎ6!»ay"V QàÈäŞûZzc²Nšw¦Jâ§Ä•÷ÙˆvØ¿‹oDŒP€š„ø‰K7N%´M„ÙTêÑu³;Ûñ©NäÉùL€A1¯ysÊ»©fç„3R¾âÓØ{tz}¦İÿ½ç›ç™’åœo7ı—¬ NsP_G)*Ğ¨Ãó¥]*«tæÇ"óEÕ¶=KÖßˆ·fÊ´iÈ¬¯Ş°G‘õ&üş’RÌŸ·ÈöÂz€¸ûTKİÊYq=İŞÿSPïs±Sû8Ù¹a«suÔãÂ/Ò‚öfü357Õ²I)8L	¼Jãßì—ùFü‰b0İMºgp ñÉİòäbMÆ3!‡e{Añ’œL\!¢=guŞ \;íOl½&çmfoùÚGäd^h°ÎøóÏ™R±¼? kÉ¤dßˆµ~Ò@ø¤øl¾Å$ØûÖ@ öÇ‡¡À
:˜wöÓ«²_ÅXP
Æ¬î¹;êD×ê–Ê‡=[Ï˜:qõşÈéWé
ğÓûrA*ô+7s¾¯	îLI–›Nµ”/õ³áÆóYEî­wªøĞ³É:k óT¬&0véøğTšÊ$’\!‡¸)àäŠ¾¥¶Q1GÉ/W„UWÅÕ§\—"5~vëÎË²J¹$CÊÿğ•§j/a,¢–œXb6´|«v—³8¨jŠ+óm‚÷»
İ%â>Ğzş
¨GÄ2é1Dwı‘«·/hrÕÊÿa› ‡âŞy€KtsÇX³²ŸU€ •#y¼Ó‹pôÂûEbOÕÍxœHo «ÓlQ…¬É	Æ
‹©n|#ÎÏú¯U´ªÒB/Á	âEyvFİœ§ğnî¼æ£m0Äy,ŞØòfbÔÛ3>s$iÿƒ<LJD	İø¡àvÍù%À5¤vü(…FŠ;›ı.æÉ¥¦­Ç2‰„ğËñTÿ€ßâÏ"íw˜Ú,æwš_…QEê]Kâ|j†–Wù`¯ªRk6²Ï©y‚Î)$’Ååë¯—+çâå…8Jş¼L ¾ªj¥^¶şŞÏú€ën¢—„ Œ‘@‡¦o£Ï2¯;ëE)\B–6Úº²Eß¹ˆgúPŠnŠ„üŸ´&traàOqhA]yJëÀıíx"”-E´ÊtÙ+–}½ ìgä@‰e¶cßeÆ\‹S€íõ{Ÿ2€a>‡%}½Oñ
 }nS€Rùÿ ß9²a|ïƒò‚ó	Gâ1ğJìë¹p}œ=™¨Yñ/Ë›$ŞÉ~¹.€Ka¾ÂûZ,)ôëê£Õìàçá4l»2÷¶Öı°¼q€õ¯N‘†#À‘µàƒª€Õˆt¶XÛ¬F3‘¨*ÓHwélÄVÏøÃ‹Ÿn$C@˜áÎ=G°HV¿ßr]ÿQÓK+äáGQ–%ë Ec6S)ONL+NÉ:ä6wb{v`ÔÔ¸Yú°Î÷ŞU+Ğ„“2ÅºYğœ†ÏúĞ…[zK±Ù~L÷ê÷eË‘9bÄdò@¢x8ú‚„»‹øî¡bÒ™0c*MÇÓš´R£ğıÒéã–ã…cÌ'‘Ã}äxA[äêÓĞÆC¨Ly¦¾ ÿıÎ¤¤ Ÿ°“#D×J°*! Uä|^ş2ƒèe§Î‡·½
cà9ÎÚRZôjb²a”%ù½kòËı”Y§,:YÕ:¤Rì2¸
Ş±£	zô™¤æÃ˜
xè¹W¹^Á@æ'ôŒ‰~T¯°UÓŞs¤ü[ƒıòœcÊÂ—~6ÈÖ9Á*b<ìx2opcUˆqcª˜1Ñè?¶(kĞuÎÜ²LÙàkîÚü´ÑiªX1¿?\†N²'š5×½Ú 4ÍÄóB‘nç®ˆ„c™H8•&B‰“îYO¾pÒDö‡ŸÚ«ÉÚtT^ZŸWøğA‰_c€ufëöléC]{1'şl”dgk<ñ0 \wájÕ›ó~UØÆ{;ppië»oHSv.ÁéJĞßR_Ã;×3e¤tô»9¨F=Á¸›î×˜ÒÏCXfÍŸà»(k¤ÚØÑ*@¶ñı·Iscı“.y‘|ğÒuù:>Óâ.Ñt™làE§Éìm„G3ë×q3©]lëÑ¸uI®\ñä.?É9Áé‘î ‡uğŸ×ÙóÿÄ9˜>KêëNB÷{,\üÿŞ=f©a²ÀoŒ‰@~|çûíø~®gï-›ºEG·A&¿~_ˆ­ÍKØëTî3·Rë,™FìW„yzã¢S$-9†-4{ñnŒ™2qy¥ÌhŒH1e¤Péó¤-‰8¼ğµÄ?ŞEy0³¶¤wü©zòƒ=„Vif<âRúC¯<ÒC ©‚“¬D{ñÌR%¦Ÿ­…§²ÊOÂÜåÏ¹™Ê(íÍ×„’LRÃ ğ¢pQbÕµOKœh›¨ÏŠ¯â´)ÿ¼Ğz ±îÏ/vo%Í/Kí†¥Ê#ÓV¡Tˆgˆğ¿6zGßx®ÿ¤›íµø§ ıC"Ls9È[¨ ±³ı³ú•#—êÒ÷ÅdèxTáu^G”Wš~RÂw´¸øJxîbn’Ï­°¸Ù3wÔÜfğıd£Ñ ²¢8¹ti¬BAğz¾(NgÅOXË{úg2(h‡ÅŒ ´s\&„†Şú³ÙÎƒæ¼y²zæÂ°±GxgüIçÇÖ@xÄCXu1[¥ÚZ¢18äšL·EZŞ¾!»,±Ê‚jò¯r|FSúÑt>ÏÆ>ú†œ½Sñæk“¶ 0oÎğ°QµVHtnéœÿ¥]Æ™4Î+feø§Çûˆ`·ÖŒj¯mv¤šWWÖÖŞÏÉèÊ¸l‹¾·ìUF¡J<{Æ±hˆÏ–ez/„Äœ*…d 2©V¤üğë#LÄ·güÈ“çÍ	w„™ˆbZ9‘@n¡ƒ´ÉÅ²œkehá-=î¬KÊMˆÁ•6?sbˆšyê1*ÕÑ*ËSâèÈ]Ê=¹û¸Ù›4ÍuX¼oI)¤Øô¬Xâzı›äéí…/FÍ¥"ŠÜj*Ö|X&uaşbYäŒE/' Ä@½Htèü+/rÛĞâCäÏÊ97yy²Òvæ@·ÎUzêÑo#¾•Ílãƒı4‘EıP‰NÇ§'}Rƒ¬Fo¨•õ‚vgé6&öc}ÑlKm¸¾Şû\€ YÓ£Tøts¤>v³& ‰‰’Ùîí×ÕëÆ=€ÿ’Ô3Ø›Ê¦ƒÿŸ¡ˆ<O¥æk$ë-Dr0·ŸäXæ³ºÉW8ëÃAŒ¢vpÃ¯iZN‹Ş Yjg¶¨”U} nE‘˜_‹aŠÊGqô{Êãöæ
M¹_=ÇdÒ/5qm’ˆšÄ™!-9íòO™C}9”iè¥eB§Üì$§‰Ó±çVä“QÓı\±Äë¨¤ä£¦É»ÂRiÈ!¼f¶@V-€rİ¸§Ø*-^û)ìnğ|õ²»PYL’ƒ>©Ã
&áÆ\* fÈN˜O“°)QŞ4HDÕö¸®õ>Ò-j³î!¬3C='gûàvå¥¬Û’J¹îòÎÊ¨/IuÚtzçÔ‚Şf™› $ï”ºz/mq¥ùZQ0HÓú í6:»µŸô<û`é6<Š“{{WEîånÎwóé`pïw•uù:Èò3_ÏÎxÆ[§fS·zÖ2îuóÆÂ¥6›LîšöJ#A9ÊŞ~ë~‘¬Ôo@:gU–0\;EÍ€~ï’Ö{-eçäP€h±Õdı¾Í†-Iµ§ÅKAVì}ÀAàëĞƒ
²oÖ½>ñPœàö¡ƒñi÷úå%SZ"	3E-¬üQ0ûy[I¡Ò‚?rƒª¿<w<%Şx‚±Òe^i°ú^6*;Ï$ÿœ0&ÒúChc"~Ú4óFN¦fT…„…©³ù+¶¼ÒÊ˜ÛïÊÿ1‚LÛ{\}WŞ×1¦»ÒPc26l(ZbU^O—ñ7åó;ºĞøD0D¬’ÎÅ¯#ZRm¿ÊÊŒğ¡›F®¨ş‹ÅODÎC+ ö#iĞt¥	ÀÔz JnÛZ)Ïe"-H!ÙmÙŒ0‘«9!|£z/êF=’}ì…R u-ºP¬-l0.†×ª«ëÅIy¶oÃB¤@‹=E–ùªjlëÌ­>½êåW,zCË9l1¯«tØškjb“&0áb<·5¿gÅÊDOB3­%b9ŞD2‚&;šB2R¯][Xf¥ò%êc®Mù§ğË[tá‹÷šiìİ@I£8áÖO¯Ó`õ™¡êN’2,ˆ+ì½èèâBZÁrzI'(Mğ¦Œv”a~ØD{Û|gölffwÁUÇP’˜“¾ÑşÍ+´†mŒXÌq,‡<Hôîd“m{$io…TÙºº÷õ.QvË½]ğdNIQªµ×Û½’Á>9/Á€ÛšVÏ2ğxÀæzşç&Nè.ê[/ODÕ‚û"Ç‡cS–#
°Êî	:÷qx—j¦­DcŒ¾ˆ^'pâ:“}†¬ğ²ğcï2.Izt	‚[HjX—ìf¨ôòØ«¯cÌ'×Ÿ‘˜w»CcèSËP	fŞ’‚
R}e=éLYÆÉI)Æ¦u÷Át%æ	­¼?ğë-ÇªÌ xòIğIo÷ş6g4¤’Ñ%£ö%@2¥)íR„Íuo”Iù_	 fkQ^íx®'Í5näpeaÍ^?\D]8ÉğåÉ9Wrß9Î§ÚÇNaØ8™ißŞt]êÒ¶!VFíw:Næ¾gR–-tÌÑ¾ÿİ¼¯ —´²å5—7ˆXhÕîxúNeuê¦Èu©cI8‹â”F*êØ*¼<VÔƒÊ"´YŠŒyu­-a¦<‹xké(¯ÇpÊM¨FDq3Ã’y#…ñöyhÇ˜ÍköFSşúñ>M†¦{d¬?­]˜spéâQ?¥€Ee³ª-‹†j¹%WŞşÚ»-MHÆÜ•¬Tcg2»ãn-óô%‹Ù‡Lj74¹±=R×NİÈo	(Zh#í¡xõĞssO›õ¶Ù®§  ’›ò'*ÓÒTéVÌKôËÙÖj/ {«ƒVÀWĞÛp.tÇE‹í"Óş…v¨«Aõl:áQ))‚%aNQµÑ¡W†÷YŞÂâGVÁ<ö4I’)¬d©7±²ö_ C û€2:–‰£€–T}˜}~fb}¡Ë#òUÿìÿ‚—=î’·1u"dz™kÀ.!BîHÁ‹æHò&¤½šJ@`ÑLµ-R!$+}£œmj¿]á mUÙùö…mï˜Œ]Š™©íF—ù&Å–µí¨6$íc™í±¤`N‡K=©y´Dq¡ßB‹\g&¸	½ú@©(æ}<³]-è€Y/~ø¼VAQ¨ï†?r²ˆŸ®:£ğŠµpş¹1)Ú‰ÿ“í(5ÃƒŒM»ıÁcg6Å3’êà7è”ã*9\‰Sz1¦()]¬™‘şé*lFW\v³Œ@øŠ€n3ú¨Ø(uh ÖsøLN«jw‚g>Îd‹:T6eoÂ"Ü#ï62„…±·rEI,Ö„£jaäD¤"»²Z4qt\/âj3BÉ&A?ÄÈÜp®–ïÒp “F0ŞpÁr ı~õ¾|ÂQU½L!â˜Á¬Wíöz=U.#r"‰Î¶"	ÓS÷nP,(İxB W¥–ï­®'ìŒqR»Ë§È”Ivb½Â³ñå›èvYŞ¥è°¿>l‘Q·¸²Wq—ç³;0§ºÚ¼údn‘ÿÉeœ­8æfØàZQ§+J¹~ZÖ$U¨cªaÁçlÄƒ¢mÆ.¡`ˆƒbC¡u‰õrï ØP»YÉyiÙvÿè=SV¸\£¿ñµ¥ :÷²só$öFÜm <lÁ!ZÚ’NÇ=g¯5®'¯+Æ³mpÌ1Ä]Æ¢&IÇBÈí&]ó&\³°«:	ü]ì­†Ã×«vş¿Úã.İRJ«ûzÚ"&¾Ğêƒ<ò´ĞøåœÄeÈ”Æ—pÊ·jÅ¨¢º¬•!9Kìô&’SHgˆï.ôÊñˆoTdğO«ÿ…áâ³±iüÏäÖTA¢uë¿lªhÛ	¼^p:=ktK½šúa )¡·6m2Ù³ãŒÛS‡×|—.º¹œŞZØ
Pé^Ö®‚UXz~eµÈë[v¹±Ó!°÷ƒRä´Ãé+e4¼*ç[$OˆQ–„¢›ëuto¦YŒ¦¨ræ<r¦Ù†ğCY{_İ¢<Ô4[EQ#	–v7DÈ›¯¸âm˜M1Gµ”9?^·(ßGyÛßºfU!L¶GªÈ¼ûËCíºÑùkI„‘@ÿ°Ñêv+ñ©ªÚ'¢£”ŠnÂcïŞ‰¶pÓğíxŒ    b‘…e|ºĞñ ™¶€ÀêP¬j±Ägû    YZ