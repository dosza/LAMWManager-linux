#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1882690050"
MD5="3461cf7ecb631eee67fdc080beec4b96"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20856"
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
	echo Date of packaging: Mon Nov 23 03:28:16 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿQ8] ¼}•À1Dd]‡Á›PætİAÕ‡8[M6¤OK MLJ5w†êà’ƒGù·Ô- ŸB¤«„x]Q-Ñİ²ˆi\\ô»Ì©ß
L—Áv>it\Fvõ°;‚™jèì¢û¶›I°´{ª:Yú!yÍ
n*çZhPéêğ¥Ñô=¥dÎ9(Ô!K7ù|ü¿o°<,ÀÅ µût[&ÿ%ÄæH1!¶£MÊÂCk1<&¤Â–¡¬çMJGó¶/·búrD@›<ÉÅzÜoU†`f‘œ”õÃğF®r—[¹€b?Ş`·×šÉÆÇ¸EÕ>Ş	ÅOôã'Ç³Á½ DFœÙªíöÄ€	JŸ AoŒ&½•__X
â hMlÄ¯Ñã8q!eëÌ‹§¤úŞ‹áºséØîÏ.Ü —µ©måñpÌhfÉ;…{‹TÖÉ¥±éµH¸Õ‚şŞ]VüL-ÃRõ„ÃänV¿ì¾3ØùÈ/İHí;B„Â_â•ríaàÎZ¸_>ÁÚO5;»2ñ„1€ºışô+Z=j?ªM?³µŒÒ3«ŠÙÿù’´ˆ¨|Ôy;4:
«÷ñT[Àh~ÒE Ã»º¾!·ã—Pkà&«š’"Áù¨6şÜÃËpÚ(Ïg4LÌ6©€Qğ²62'ËkĞépzN°¿ÕCxzQ´Õ‹Aãè3Àyu={R—¾L»5€Ÿ–¼Å4ŸÇÏÒ2….»x²!Şló2¾•ôXÍ“!XİÆßwÜ>	Œ(-qu²aW¶‰jHœ+‚ªåÅHÏá¢Ğl1Š7fà$@ì Ï½!Ak#™*ã¦µ²3[&@a¶ê/rÜ*°8Fó«	"ö¸m—“6¿‡zÃ’@œƒ.j0Â¬íd…"¹Í¶Çô-_è°'	›Ü6ÛÎÊÛnŞ¤î‡ì±™şœïvsÒâWì0f
ŸÍd*‰ÿ£:´-—öKœqTyö^†	¾7óÒàşÍ‘ø€>¸b¯şá¦b» x™R¡†¤rşP@5ëg‰AšÅñ¨ÜM¢±f¤‘0.×¥qdT0­ôJNõê¼ª£/Ş%I‰6HÌ÷wB6³
ÌÌF";ù*z@É­®}&€ì`©×IÁ"ï8ë¬§»Ÿ[ûõ>¼rsÉh
îÒÎ¬¼|ƒ(z–/GÜeFşñW%*×Ô=®¶ ~ğ>ïÒ6SãaSš'!“’+ÅÌãGiÌwz±4"ş"r’ğ•C)ïP‘NÉ'nÅ•eù§—‘óØv>¢™>Á¥guëØ`Ş3+Ûs=ÌgNàfKÏ]Ñ÷¥å,ª­šSÓãIì“9áq 'gïì¾!b£õ`XÒ´ÕÈ0Ôí°ÚMA'»á”M}E?¾yÿé3{SZ»[” MìP¬«Dæ’ yi;ªyœgs‚Ğ?T/ÚÆ†ŸçØ¢±‚e;ğUáªé?Ëm¬Q=ğûPÂ±¾ênÄ[Àz¯Ë•¢[jÜà‚qÃšSW¶gz¿ğN<¨>& œ÷oÕ>‘eIh*W¢{	Ò¿â«›@“rSÿÇİª–‘è.“Ü¿¼_),Šç•ñ-`‹®ò[u‹l ø2¶s#Ôd<F	›’áaı\T*„ÖYvŠF=ŠIM²­ï9èyl«r±	0ÏğäS»ø†ïÒ1n(v:AKÈÇñ1@ä”8	>˜äb%=Dî¨¼BjOUayÆM"SeT0¡ÁÄñŠú6cvnHvÅó•ÑÑ[¸·âÙÎ¼Ï!ãUı°LçDÆì»2Š20!vSQçœ§Ç’QÎ¦Şkàv|æâƒsœòÛ“åF	KT¢Ëyq}UÃvÓ××¼¬†*…jîç/À)äG­-]B¦¦úâjéÉc¯–@/PÍ¢ß¡ÜâByä&íR¡7uå`‡ë¥ûñqm¤°ãe?•BqÄWÖe8¡Ù6R_54˜şÄ	‹VÆx•G4²Ş®URİ¨C¹äºbíy¶>m h‹£9r…åü,Xä®JûèEÏû‡õ.²MÚ¿‘ÿ¼vİù…şÑ	rAÔvø”EU » ÅH¯ª,ƒÍî&têÚl1G¿Õuº°~’)š¹¾E­â4y°˜k¥®€µa¨ºÚ&|«ö­æ+f-™èûİ3¾Ã™s6	û³¶0gá#ÿ}u?’Ì(–¯/ø_^0?$ÛyéBñ–—¶Ï–\TÒ1Qæ	(²håmŸPÓ4¶î±Ê—”î)7ˆï„’ª$« ¨½DZšã<À%ØÉÏ<ßƒ±dßÊ¸cwÉ5.nŒĞº&Bå[í.õ-ÿw„R˜aå•'‰ËPJ{+-13.ş-Û¸úá–VÅ?†G*‘Íˆº*¦æ¸˜’†¥†H8)4ªyí"Œ\ƒ~o˜Ô4+ÅU{:“Vü…~êÂY‘/q@~¥ÓRòÅÃĞJé¯Œ«µ¸¢ŸOáİó'T†$D4Œo÷Qm32“ù=*–\I$d"©-!úV@ä¬ŞÔ#ô‚²3ªQ|£Ë…rÑ$*Ş>Êµ`Y±FÑƒ.§ˆP9LØ…¾c]µz¬Ö‡¼h¹D%Aß:Ló<õ8çï&²a$€yGÉ!¹<SŠö˜ÿ¼$§ÒB*Ua‰Xí³ºöGÜó×qOou
›f@ó¸¢Ÿ3>ß$Œ<Ì>Äì Í²ëQ»ÁOûúTKE³6î¥3òJğ(Z¯¬ùŞù93ıi†ü|{Şs–·É|´ÔÇr>S±a©åRŒÏŸ?©y§ØÏ”¦>³_]Eœm‘!½á40³QK¡s¢6Úƒğ¨÷Ä8s€Ò&DŸÔç6|5Mt9TæúM63#·™•c²xN§ùÎûè´¼c²î´ÔìÔš@—ş>MMˆzÿx"A&pÓO˜)’¼uVhŠÍº]Ñ7O=?8qm%d$q§V‰Æ²€owİV,~€ÎñÂä_3Ï
Ï4ÇÍğ¡v&9†±&Ş±şémÅÿ‰SçlV"¦ÌõaŸSë¶•Ûİ%†»ÇO]Ş.ÙÀHh½2pw1£¦hö¥»€×Zù#j\´$A°tU#ˆ^ÔòP‡Vt^w+ô•vÁìKÔDÏA'±Ñ±’pën.vÁ”ì@ÅkÃ ’,Á§8ÿ>=`5Äı¶ÁÒBqTì#1„e,a†½6Âhğ†Œô	ÆóKQ2±àìhı`#ÏçíÙÙ>
$¥rêıÿ|Ì@¾â¡ Ë/qıÇ‚fS”uDàLVôĞo§©²áèz’ƒ¤8AQLÓ)]˜N.ş`˜Äö—¢š£%ø‰9å!S»Ù>'>³ƒ¦;_H¶2W©å]€­"ÓÖÀí‡@ÏL„`,;a	÷PàÖ—ÁR¨“|ÁÔ¥–Ñ‰$EgLğcx2”	CEÊA%X½œ0ìåi¥Şº/ÕåX¬úàcoC²®r[6Ån…–WSîd³‡Á°9&êQeÚV^ùë°¡ÃH#ûNoyèöàÜ²±fÅmA‡5D$>÷WF7£°¶ÎI
i¶mV ¶ûYc‹­NÃö*ˆY$Ã-×n§C?¡×ås:çãç‡¢xĞ×ËTÿşŒE+SıŸKÍèB“eº†À5N ¤èSõ4léeÊ`é÷¹[Õà«ÿ£QæµÆóD·nWüGP]_Ô-¾œï;Ol2¹ËĞàübÎïı4ÄÀK¶ë†0í[LÑSÆvX¸H:Èín€Ï3şÕ*8° X“ºIs'Êa\ñ¢ê>ï¤êIœë`®õXÄø]Mğ¶™ÄµıúÔñooÏùÔÃÁÙ&¹p¨CÆ}(r¦§â}àf'¡?ËN˜@6ó+äÜƒa_@rİ­Ù@Ÿ9¡Àéê± j*#–‡eó~`ddÔjæ›ê'â"ç×+Ü¼Y«K€-ÂyÑ9_@”±2‘1fU]Ä$~CÄ2~XÏ`WWM‰@…‘|À`’È=àûßW®MÔšy˜‹8B88‹T^×£Ó<oß‘öÈ{ã¿Ò¾ƒu Œ¼4Æ~ºrÀÚB°zË*™Ş*™væ‡„ºŸïidüWs,p+VÛ}EÿÁÄb8Ô-¼†zcµIrb†s`ÔêÕEt´Se—æ	J‰wæÿŸ»Œ7íôÚÛ™ê‚BğÜR8ë¦æó¡}ÑÅÕ _ì°u®å‘ğˆ_ZÔmƒ	°3uS3ÂÃ€‹ƒ´Š“ğ®OÿŠÇGB"8ÄÆ˜¸ŞtnÈãSW{5³‡`²tèŒĞÈKoKâ±Ã˜ª%.™Øú%‹/ÛKÊTBåOr¾ß­Æ¬òÒ1½ÕfùX<
,¶ñr¹^}ï@¶ø@ùò’¼§îü#5îÓ«r}ŸÚšBaÊs=6—Ä©ù¼?@:øßMŠÄOÀİYÑrDs|¨p¾¿î%Ó\¾‡½Æ‚Òá—=£‘İòYåE–ª:ç6Û¤c!òíò½˜˜%‘8^m©øµ§XGo;\ò¤a	8%§]¥-…Åç) n‡·ò¬¥è/ü ĞÆ#1öŸa<…‘-'+Iæ‚D*ş„bW²Ïªß«ÙllNA×Ã3«må…ŠG¤q¹7ï>­‡–õ~û›e1ß)!¡zœ/µLÕ:Ş‡!İóç%ğñ²W+7õP4$½#¢Ê˜ñ™ô?[û<ì‡ON— _=åßfG¬'y=¹’®ìÊÙ˜—ÏMUX®ß„‡+}’C(ŞéÂ6ó-$œš‰ÅzCjÎŸó©É®°OÏhU‹ºŒGÙy£‹Ó2{úÎäŒ±qÚˆ1ı{ÄÎÊ‰¹Yâá‹ —÷Cwx ù_àÃŞÓ/œN}¢¾±90Ñüšİ÷iæÈ!dWØ+ÒHy4¸ää;c/Õp¬—?IÍ$šB#A 6¿º…y,*”Ò0CWeoø‡Øö“G,Kıİ;KÌÆAˆÌ0¸¨”~¥mmdôÉ}4[Gê‹i%ËĞŠK¼f$ îÚ7åMÎ.ïBj8Ì¶¢Ú@J7—ÈÃ:@i 1¤ÃÑKäıœÊ.<¼‰™7ÒÿÔŸKš ôEË€ÆÇ(˜ó8‰ºj­`Ÿİ­ÜøİİĞhkÛŸáÎø’"czÎ7º´ÑB/ƒ#×õÏKaŒ4sG[êsš‰Ï0®ÀêšHËÚ»#¾[Óqµğé—|äÍ~ Ptx°ywj‚àÜ<Ìö…Ìhƒ1>ÔBS­»a­‚\ s¢F Trí‚7w'¤Á_!òEgh~»sá]?4%€	Ù#„âíkû›eL-Ù¸ÙBéÉÖîì¯º¦è€ ìèR##‰ˆXã—>© *\IË×MöÄ²‡âÄ$jkOKq£V¸@Z9²Âk9[%2¸
™¶ù:Uy…†šÏÇâ"©•hŠŞ¯µ2SÙïƒY(‹:ŠE¹áï‘—ı¹$·¿sC ‘Ô`”È¼òM'£nİçW@DŠ»k§øãÂ˜ô î²BĞ&ß8¡k8‡¨ÆÉ‰\¤¤’ZÖ.vAFa /
•–t`áÀòÚìÃË’–©¢x;}×cÂı?¦» EòÎG2èBæ@úĞÓ´t*#ó`,Qà–cš>¨t€é.<Cã}Pl«ÆQ8ëõrçdA¯ö\YÁF_]t<Éº¥’q¹}£«è8ÆMàP6vC—ÀĞ^õ ƒğÔ.5Á2ËúÁÚB.ÃbœS‹Èı®Æ„Ü§¨ùÏ?()€6"º_7w4ë®”àŞ»ã£«•mÚğöí`ã3¸ötüf³åälW˜—<á˜M"e]"=”2#‡zKKlä©çxZ$gŒ‰C@ñQ[ûaïè5İÜ<Ìäêƒ˜âşàÿ¨åRÌe#]¾¤î$°3®á6,Á…Xüb‚4^ˆ”2!;º.ãÈ$<Éı*ŒGT†.¦–ûeX™İÑø)¨ä¤ª‘1ÓUXÉî£ØıÎx!¹]ˆûr´1ÙkYïßÖôŒŒæáµb@H·qÒ5Y½,n}HëJ~õŒ;ÖDÃ™…gæ|ªEfYş©nŒ}A­ 
²>Ğö›³Kìšêg‚q;20[!¨U/s–¤0¸×Í'aD„®ØÁQ…  °ÉPĞbdÇèX±l%+P&Ë‚Ÿ¿ªBæ´GŸqôp½&Ó5¯jTÇ¹ñ×¾@NØl«˜:4D«ãı~Jp¦Õ#ØiàÌòŞßNH¾`¾ÓÉnÖ0‘ >bâïx1KO²µNxŠ Î±òÆAËµ¥;#Î—9É„âş
*¾Æ¿æÉPÇI:¿hr–3Ûcl¸Ë·¿È?u¹z¾hÇ•ºº¡³5b»)¸¦ëÊ¾œÀjÈØuƒ‹fƒıbÒ ÙbGK¯İÙÄï5ÇågHDã†^ÈÀ «Ôt.À‡¶TÿÁac1¹‘·õ–/V//@Ôš²5hTƒ0N¸jDü6ö„9f<U¾aÆ†Hñ®|8q™‡;O„ßlÅ¯ÑPÅ:š¬­PÍ+´oT4¿Ò£IÓ.0´]GÖUem
3`YFœÖkb-êèšŠøLÆ>+ù`t¤~…æÜÚ`©Ü&:{°@áZNb?a‰ôQ°ºfÁ¼pİ¤OÓk¨ùEå³6*Ø‰‹±¨c%_ğ>ÂÖLĞ”Cwº	vü3¹ŸÅ¼5Œ’õgÛ ®qìxTÄòFÈ,\öî´u´sï·ÖÓ¬a)şW‹¯‹˜ŠD`Ùg¸xQ?ÿŠ'Àƒ	+ÖFêYuæÿ#‘Ò[9=Y’š5•ıpÓ”|ê›K§¾#Û Ü*‘¸±\nGğ•µ`v°•[Uy?4Ğê‡®,ˆ	U½®)²ß4SòĞcÕêS.µÃz—Ş½ÑÉ³cÂ"ÛBÕ”„Öi9G[e¦š…sûSùşuãj[“D,ı‡İ&L¨åâ·±ÜàÄ{ûnÙÇ„¹,½C™ÁÈ2¹!§â·“7Øâ›…Ô-Ä@æ5kn5˜ ÚÓ±H˜ÁBMœ®R%KËw3ûí›©I~%C_ ²G‚ æ$l©H‘Mzû7¬ÂWOA€O÷’G’¾«5ûj~Œzà.=)É‡æN§î%rzÍ{G\Æ¥ ò$9G0Ş”À}”Ÿ w_slÜğXƒs]¬™=f…@ëSI	.ËØmrõÛÿ×A¦gª•¿ä™×gøW#:Øô¾ J%ÿè"¨rŸ´÷9!krµàÈÀØkÏ+*fúÍî°u^”}`ññQ“pòäŒøFN=m1,r^…ø‹ší›[Ú?…ÒWfªoÅÿ.êè.­09¥jú@DİÉke,æ2ÿ·r0y€H÷Œ1t§·úèúËy»<s‚Ñ6†42ë‹‡<“0´5éîÒïæ=XŸuìİGà(êp =¨-„ğZg³¬­lœŒäß•ˆhDÁŠŸŸû¦7¤‰«<…ANÔF…O0–wøÔ‘*®Ì\7£P’ÌuKLEc®òw½E²¸B¯¢0DÕªŞí~Rq—ØÔéo“0´÷~qbÎ]÷Ÿa}Ğ‚Ø‰á‡å68áÂT`MO1R,	­9÷·Ğ÷4:QŞ1'Ûú÷±ÿ~“Ó½(Ê„¼”–_ +ø›q¾RöîZÉá>2önúàÿüHÌ<ó8“û9:I®RçVRÃˆl²6iZF¬"r	´kÃl>Ù$€¬Üô}`³9“Öy³û\n	’)AÃ•Ç9ÌG Ù÷ö„»ö¡MÉmZÈ4ğ²œô"hşòu¢0PfÓª÷“UÚ>"­µ®/V³2·SH)Ô$1‘œóôFZó2ûTÔ'/Ák.].÷rguo<Uu]•Tê7s}­SzŠ=ÏÜ©ªºñéMHe²³Ò·ø€>ˆÉb)¿y_TBº¥B®”šGwIKwE‡ß5+Rû²úPãèöÎR
çm6×WP]Ü^Ä3ŠÁ]ß—¬ñ¹÷R/&Q±S¡óé"BºG&¸ÜT¿ÌSÉ*¢³ƒ™’˜Lòw^HwÌ5Q³—7#ˆEãí¹­î]Ûİ…Éÿ0Õâë|éqLÏT[MGĞ—e’lıî+Ş4'Ì¹r“˜ œñÚ¹d‘ñwŞ_ÉµùÔìì—Ã›ÔÈÏôŞt/¯ñ.$Ÿ×›é3†&lo`‹¿‹1òì£b>Îê¬vÌ„†—8 óÅ¹¶÷%­Ï<S±¦!b¿Àch	ªRŸC³ÈÁĞŠQ¬9¢Œi@¿Cß†ø:3O`µr‹;R¡ñ‡½Í\Ÿå gÉêŸ}aLu'¦´iğíQëé–Ì>ê~];m|Ô	Êôğ_h T¦úiE·˜Å™Ü£,{­ØĞE{·rVÒÂ¥§ö€6×ÀoI4’ï&ıÍoˆQfÌ$ØJILÀÿ\)©hTå¦µwÀ­ë§è‰it˜ƒ’%ÒéÔ{áù=ŠS8ºP†h”ıüG¿Fñ³y3Rí'
7XR{ª:á·FW¿4¹”s±ÆKaßç¡baÚºàñ]‚ J,1õ!EG¶kòY¿w¹ä²}³ôûÛ¨X‚h`Ædé¬¡³ÅÙ*j° öE6¡o˜’”PÛ¡mfy7æ¦h1Cš@ZªÃ«—¬;–¥t€¼ì¤¢>Ãzû_Š1^¨¥ÂÀ×eŠÆYJ©2X7ù¸Ú0†¡GExÉÕDS?Îmµ»Ue»îÀP•B,°L¾åş¡yßYvÜ-çb^k¹îEş*™”vï§ †ğHü%Sãä{hbµtK³èBÒ›fŒÈ[—b’m::åóíì<Sì¾œh­ß‡=y}_ò@†ãÈ¦qğÏkèÁyª‰o²¬’\wÀ7`ïâîÇmdÀ¸=Ö —Z§UcEüM¢{š
y=E¤Ñ±ımğ,û*Ï[d8õX’$F-Æh‘8öá¶Êz³!Xmè`RÁå¬	Àÿ+\¾RŠÛ‘?ø—oU€+’o±´|wÃ4r”+Hj©ÏÜşÎ¬4fÎŞhF»à11¢ˆÿÄ&8`<tŠ‘­k÷Ç%»wU•&/rH¨VëP¡uõ@½$³·_+9o{ñÇQ…	æ1PùkŠa`hö,&;ïvÁãı±ñ«ëlé\“g»Š‚–
RÕf²â¹T†H?àÖjŒ˜:u†q­µ5Â­}e†E¥]”/ØòfÄ º_¤)	ÁĞ¥ En'Á}¨ÔY,ëïÈ¼–ş†TÁ“ún—ÉàÅbÿ)à &‰Û÷³>R±¤ÈçOß”#ğW;ğZ8Œã!"6s” (¢¢Ù½ÿ·]!Â•è‹s^oa¦û.˜0§Ñ‚|¾Á]Ø&Æ©|	çU¥y-ñ#ŞK]Iyíç	ƒµùÀÊƒQP]‹¢,~MF9¾‘Î »³Ğ¬i äAñ7íDõôİµ¶·{z×`×C£ê¯Mez¦åqVÌ[ÓMgfWÏ£q‹öVEP'üLâJÓÌ4,`0
Œºhña¥åÆ#Zµ».!ß èY‚ÜÒÀ»jíC©Z7Ç××~~Uµƒ—±xæÉW£³SßƒÖV¬
Î…ÚSTá¨TˆÖÌ´ƒ,/:»Cœ—Ñë¸4÷³ ì¥|Ãìd‚È4ÉéÛ³Vò\šE“cF™0×oª9X!'«ôD÷F'ÃÅ)}ÆE	/àš×ç%[vë­1<ÖP,&ëË½ëllôêá4Öf<h±özß™Ò5/íÛx$è©,_Œı+ leæA¤„—0úä5o©›ÿR“K±íNÓ.ÀƒÖŸ¿BÀ/å½ÛšHœİÂxŠaÉæd!€uĞ¼lá9sŞ†hæ¤cŠûeò»M¹§ =SdO?s«E8¤T±Ã…(Ë¾"ĞÑ>5¶åîeÊ"YQÉ×5aúêvÛ.õéåŸSÅa[ÈşşO,OÂœ¯í8]%Ë9œjbrs´èè+-´v5P&Çˆk1vÓ‡z>†´ÁlSöjm[iœA{rH®G®‘@0¿ŞéÛ†‹&«²Û;ÇŒ(Š€'+­ß÷wK¥ K¡ËÚhğ5±tv!×Îèëa‘ˆ¬YHAno” ó{Ğ1¥%éøõ;nŞ±šûƒx!WÈœ	 ÷%ê·
'Ò'ÿáéuÅî©P¹«cA"ËÍĞÔ/Ö»Ú±†%°ÌîÇÎ‡îÀ;X;tÂ2?CËPîC^í’šAÏ»ÑÁùn‡óÎ5…Æ¥jZ±F‚Ùy¹ø~ë¯€NºFénåYHyÙôWå%HôjYè³ùŸ¤HÄÛÛ9§uHÒ2£æà¹µÒyÊ™2’È•ÆÍJÅ Ö¹æhÏQNâö¢zC·`šá2h§B®@R¥|œ¼[É—)8n¸£vàWKçÅ’®Dn•B~Ÿ{1R>¼À3íø‚ßö¸œŠ‹©Ñô·9˜àr–5Ë>ö u~::–ôÔ‹[kæ‚¦¨õN‹mÁb½„Í3“DS
:0 Iºtk¶0ñÚÜ7=Ç¹\k›o³pï(qüî"&`!Ğ…ÁôµãÛ>>ëÿæ~¸l:ifà>_»°]>È:».‚¹†ƒ¢$¯ÑL,»C«}cnıë7¿R¡ÿ'ù’ÊœF¸Ê°ÆÊÚ?™ù®´n«˜`‹“:hUê­ $Ám{>K™=%ëzTÍ`d€»ÏÍ‹¼ƒu›œ~›î9ğ	(ì­—$ñ×-tÚôÃ!M9wšz¢†¹©¥x‹0Ş¶qÍóïìœÜìÕÏâ]û|–úº¨JµİŞ
N	ú>Ç•6: -Ÿ½Å*dQÿÙÙA÷rÆÈÄùní¢,ÓŸUg]{&şÓ_0?(9êù!ÅPûûè.HÌÌ‹İZ{
é¼ô÷ÈÑ=É“ÍVÕŠX¾áŞÄdñÎ/œ1öf@&††8üÊcØßm¥2áDÛ ²¿8¦-' ›—µ‚óJJLäŸÖ¾À0êÛ6™mÉ.Y£W‹ø¼¤ÚïCsÒŒ×QÖíÚ á6úMğçË«´?–@ÜnQ§eû¯ıH­ÆS0a‡Ì9"•út¥Ó5e§¯Cƒ E¶Ñ­×Êm8?—ò§b-KDŒw0Ñ‘İ£WR›ä„wk)#wïz
oev(J˜˜ñ¶ì{;2÷I‚©G¯^Œ‰(\ªØ–ı„Ç"oËZÑë²n£J%+0.à(Úúˆv…„ìã'ÕÊHıìùın>®‹—¬	´oœ¢Ü7€bJ6ƒhÜ=X{Ô·_Q¥‹±;_oá®~Í«‡æ$ÜÃta©ï©h,·w²xã3uâÙwÂ3u3ú<‰nvu”+øÄ¦ĞF3ÂœÛWŞÑ‹0wy´r„d#1ìÂ7¨ÿ°İ— ’›èOmê‹)„>öEòy‰¯+oœÍÁ Ëîq¼¾OilJ¾gŠ›vOï¾åv†–Y¬±ÑŸS¬Ş%÷R
{ª‘úÑŞ¥NÒËh—sfu\¡C	2¢ˆj§kİö	¡S#»wáT>‡GÁÄ¹øĞG¯}”¦n¤I¾öşxˆhò¬ÅÂª][ÒOi-R5È_Ô¡\+ŠDIÁÄæÒ•Ü„D…³²ßú£´c,!z„½ƒZ‚*¥'YLd_´Û#ïJ#C•›î«cm0yü¤8§ş†[èJNœŸô3[lP%Óª‰q¬Ò”ÒBF\À†íâàg‰ÖùÃ¸$vz°%Ë<y2]?sr4ÍfAN3—_—y`+“æ{Y±Öœ0B-÷æR?7¦
Nk u:Ï,C¢œI:S§/ÂPé.ñˆd	æ¾(OšX>¯8{%†°ÆÍ9¼IK½Õúmàé„³ÇÑ¶ÀˆÊ|Ü@pih´e®GöÌªªİ>Öo&Bè›,óŸËyƒ¦#óVGçŒ¯ò‡éGÏÏú-ŞäÍ»¯¼’Õ™.BwqÀ…m• çÅp¦o[“”c=ã¦ò]B¸³0¡¸_htó{Y ¸òIRŒX¼9|ù;_îå’ë3¼îğ
œE.]È+s÷Â!èâ$êr[ ÚËo#ÏŠñ6)éÂz;[H—ÀW>ØÜu¯5?ÏŒ¼ìÂBì-	(d9IÀJZGØZC’LfÅv}Y¯2W]‚
İŒ¤H5,G«ıtí·ÊŸûË…é­Â¼á<8L_n'KÉæà À|»‚¦sœ]Ëğ‹Z7ø“‚âªåï.FË÷ÆŠè&J‹tÄÈRu§[Š–TÓÀMë%òúâŸ0ï9 ©ùë±Ò5C1˜Üucj/ªõ%v^ÉB‰, ¬ØwÁÇ{ít÷EÀÈ-)óµ46¿nÃºÜà]á^kÆ	í—sÔxô2a–5QqMZÉhâ˜&”ÆûıH×Ñ„±¢÷RÂxÚc´qr^­”>ÓW¯>í´v3[€~ÌòÆ5uqTp´İwvÇLxŠÂ<]]ã’öC°´"L°”rãs­g£äšÆ#ì/…3Q}…PÈ™q®ÃÙ³©!ËBàw?øiÈ²…6‘)üù]èğE© İR3×èhÎİ­{hÒ`¸İšÊ. ù™74Â‘ê»xÂ,>ş˜Du¢yÌ¿DÏsI×‡Bh×ßI©’L­â,X‘3øHààŠ6©Íá¡nVÌ|è#zË(sò¥"¥ŒkË Z<ôæ)ıGkÊ „Àh­ÈÌ…Ödd
WoË¾Ëø^‰æ"Î7–ü°0¦º3Şq{˜qWèÌò7@`J0ÒWæ´·Åôv¨şß  ¶mÇz¯&ÔôKıL´RÙ
Á ´6W¥˜ğB˜¶¦poeÙúÁ_Ş0„ÓV¼Ñ‚pŠÃ
å	AX^sƒ¤H»¹ÅÖÔ÷oíıÅÒ›€V·O×£l=8m•f–ºÓCt¶ »ü‘©ªÇÊœ.wÇê±ëD½RÈw^±²÷ÍzÕ9QĞ7bAœe«/`†Ì+"N5İ"Ê\œ¶zÙ¿ÃÔN²-a‡Ñó|Í€C1î“‚oàÇ><ÂÓÄàÓši.ÁˆÉ:	ÓhÂªœ[sÆÔß%å¸)Ë7Æ
E\‚îƒjâí‰E43§=!‚RIË«|,Î•fÓÛè6àVÈp¸’Û¢‹<UJKW-»ãíCâ©8Å\ØhÓÊîÊêÒ)üRÔõ&ˆ©ˆñ€½ıPŒîO>äR5¸——¿ÌlÄÊİxVÉ*mĞ ¬1Ê•ªAÑêEyNÂë Ó1¤®v`c›o„áØÕw§Å´E¿&ÃeÍkÁq1ü^à[!1È*
ejkÉÌ'kd•eÁ(æ*Ş †›•Ç;7­ìŒ|4%P¡ SèÆ¤ˆLg0:¶,çJQK[_ X|Â¹5Q€ ø…qe<ß59åãk§² Mr–r„5<Vš)¦÷0¡×yD£#ÃìS5‘§Ÿ;¬Â…ñ,Ê”ìŞÄâ¢\0Ú¡î¨šy$„ÂƒœŸõ|„VİÄú
Éfš/³$ß-çì/r®êçL\¬ŞkØ¤© ¾Û2˜ïñ¶Àvá1Tëƒm¶~;-Ÿs|ªÀ½wZáU‹ ÅÊµb…àæ5ÙÃÒè:e’hlHãd&½µË696Ú—>	áº¤¨h ºã^‘´úİ_øQC¶ÿæÕyb7‚ÌĞ˜ïDv^c ÿw¡{tZD9òRı¢;aßpÌæéá!éÍ;xñ-ãâÌ¦E->æ4hÌÃŒ­çBq£ZTj§hKoásÖ®²Y'xléçú—è@/‚zÀğÎÚ<ÚI	0[8¸®îrC º¸°ÿ¹Ç
:.'tá4AcÈ–*®ÇBÆïE(ä@e®%mºUå3º»$VÚ_íkC£m©€öƒQZJK’¥ù^ÓêvØQR‘Ò]òQ^|kl®V›Øèw¤N¬Éœ$wLPäòzt~³ûË	 Üûå„Ì5 ïbsØeI¡ã~Ï³:°Z.-A?¤´¶òØ†¤ı¤ÓCÙJÙIÀRÖË¥[ND°ó,öb¶ãHÁ¡yL›ÛƒìÃ Œ%QV‰ì5©rfËU2S}ğbRrNu—¿^1¥Elb^9»Ş_5ƒñB—¥8dÙ’õ*Ï$Æ¯™œİÅº•Xëöåµ½3ä¹1Y@
V-³ë¬&X¤ƒÄ‹í—Ä´zY½6RVi\œå,ËÊYIñ,ÜAÁ?™<sNò ù­T$ÎDÑ@Ò+½³7`Ïkñ3Zï©+éü²¾û*š^>R¨-bÿQè;;ÆÀ¤ƒº½«pø1P»tB_ı¢.sŸTËÂÓo¾›°\ˆ=„e;$¯3gT	Øƒñ§<U}mÕ[P"K£êÄ ÔÔE0ÈWt¥B°\¦aåıÿèlÿ” *ş"X±ôÉ€í|DA‰ı(•qš§aÅå?·ßó^İI;è¤H}¶.ÏÏÕàeB©ßÛR®Kõ@Şx~I‰fJA<(¨³¶Q°%ú¥ƒ’M¼vÓœê.ŸiÌ4Åºp“Ö —¡’Y	×ß(]¯_ÌrîÙu‹8ÙÕåvÇjóMÇyÈ“{ØL#Ğnğ=vâŠx7çPsÏb
Œˆ_B{ÎËgs
#ü\‹Å4Õ¸É×e•|ˆµlƒ9V'™¼'Àÿ˜2–]Gæ‚Fñ»CÆÍovª0®çlŠ`hã_"nß–Ni·%´'¿8²¦1gğİô³–ûó×M4èí†¦ÓRMÂ•FµªhQÉ±¤®‡ÔkôE±9Ø¶eˆ;p‡‡i+”¹A½ÌáŸ©jMÊXR“Z9š=«÷îøogUÍ.û`×p˜¤É›É‚^‚r©¬§†Ò§IìåÔÌGØ´ñ´İ—Ìs€¦¯	1Ö.Y¼#üD,)*]×ÇËHxK™Õ†[>‚ëXÛ†®êˆtÏo3˜ÔbÃW©òqÚhA$hIÖ±,`ü`Õ¤©ƒ®”'¶ ò{§ò(ío)2"æi‡ë$¾Æ#®&„è—Çç—ş0+œòêˆ‚Àû§WË…hVç§ÙC·ğ1HXgz¿v¸ií×’8&}îÄz¹¶é8¦Ã”ª#,¾SV¯ŸäN*Rz)¨²T·§Êv&çÑ2—_Æ{Öi©¡âj-XîñÅÁ]i£iÆaF	-Rd"dÜ‹<“{9¢O˜^Ğ–:ñà"¬Q°é¹«šÍ¾º>\½W­ï¯šàÈ¥ı¸yğ¡ĞCñğ­&Nx$èÅKâ#cCä	‹f@eÿv}äü2IàZÕdS
T÷sh6Ym^Â}	bxÛM‰CÃƒgüázh½Œ4{µp_öàäÂ›,yM1ñº‡¼ÛàğyÄëÙıÕ*,?wâ7ñ·ŸÔÇ…[ßò&¿±,¥éF8/×Œ.|3mi„£Vûÿ•f|6²ááFÌH­+—âàèù¿Cù¾ÊWX§„?=¿^¸¡M~?2İaúø>-<t\<¦èıú¦vÃ'Äiu7}PUÌÁ G‡ĞO",›—ğ¥[á†¾'Wc±¦`à#[ÜÁ¿Hqp	;0—3ú§OG6k‹öjƒ	8m³Ià~†¦Ì{ùçé†õkrÙØ*óTŒòê]è‹ã.ë5š"GàdOóÉç]\³\@k‡Kª´cÉ:z®+ô¶ş$‡U&UÛ0Á]Çü=Æ¢âcOŠZÏâÖfşûÊŸ4í F¢^á­K,®ÃÒ%ÆÓéz>šá´æEÓÇÓ3L9šHpıãğêòßá Ù¾íwÃ/Ôr÷Dàó¾5Ş×_â4]|YZ™š9KHğAäDç‹É\@Ë4U<~Ô/ˆ§Šœ@Ö)áR¶
ŸIà9†•Œ@¹)Tàm\<€-^~×âÏÄV*cE€ÛŸ<¦z->Ú*ñ¿BÉLj­e©Âªso¸èD¬ÈlÏèƒª2Ó "!Š¨JûÛÔ¬|†iøù/Ho÷áÏYcö$W‹şÌ_”ÛÊÍæA›§Óœ1¢¸²¬Ãgqâw…³uZÛ¦áÚ¶Äş´¯6ùp3ºúûÎæà=t”Ğk³ÊÚ¤ìS°ŠX.¤pzĞ5£É´Øc‘¡Íë$s™Æ|œ-S¤F©Ÿ ¢&KàhĞ5ÌñˆÜüV·àHKxı Aw_g¸÷¥Ejİˆ@Ø½,½_½íÌÙœ¬%UÓ>Dß(r‡-Ù	z¶ò­<l¹ ¿–	?äE‘E/Ç-g|÷fa7
ôUf•n«¤¨D6€^\ú.eè!S÷Š>Ü°xö‘mQ®‰œŸ>Í˜¦'¾"c·a•|ğL&0š¥ì“§Ú ’ô=\<ø¶ií5ç¢²a¿ô¤fT ^+ÜĞ
MÆ‚òƒ`äî§õœ¼	q#/Ø— ^_¶õÒiˆşÑ‡Z‘d"õU•Û†Æ›µ)Zğ„BîˆPø„ÜèdEÎÉÕ»‚n,1z.`ÎÜÙ©nê#j©÷ áÕ[®•÷½S¦$€DM:,¦z‚IÇâ—ú„úbŞuhÇè ˜XòwÒÚâ<ˆxH/¸Ôärùdù6)Åºc¶3p¦!¿´>n©n'™~’(©¯6ˆS9YPEÖÒŞ‹B¨ºcKÙígé!3½’ñİªì‘¬#\›â™Ö?JlíEÇm‘¹yÂéíd>\¨ÿÊ=§G °Ğçğ {€ÄÎÁ…Û¢=×z/Â!y~ä—›Š’iñÒ6“ùWTWëÔÔßÙÛ<£C˜³áŸÅK©xFÓÿ'z»ˆ|îÂxø…É| 7÷}‰Â=ÛPE•/èıâ‡h{&¨RÃ¯,ÊæJëbûQÒTšºU2À:gÄª5Î¾zŒ‚Q„&Á:ù«¦;`p;CË(&ÖçHÇø·–'S­»›9ª÷ÿ²á‰']EÈœÂ7•™&ycLÒN€×ù>m÷$q0KlÜE˜•÷Sı¶‘!”±’…©LÓå}¶ÚI›‹½DgØªFTöIM'®um¡søifÚ¥îÁvwy3I`EóÙ¡9åp€Ã	€"(÷µ¿`Wõ€aÌ€~‘åÅŠW‘Zİ2L!«àÆn+À•æIÖ¼B®8ü-¬rE1\-HÌSçí§V`ÄÃOøâX 9*Œ7-<u}Eô24¿ñfÖÅm^'Íeµ%ë$eEt³ë	¨öñIÁ4å1Ù^¡ºCüÔtP†ùÔ`ß–§¡JFm×¢·Œ Kæ1ND}çÜüYŒÔ¦ÿ@ŠÚÒy£tv€x7n¥„ÏU@€ÚË%tÑÀÅ%ü-~*ò@¼¿ÊêßC„ä£—ğ×İÒªğUEMzDTH+ÊùÈ¼eMi¼ºÇœjCŠã#ÇJ0ú/1f®(ÔW´óõ…KÊAoU7ëØN%µª˜ K=pqáJeaY[P÷1î²¡<—@œ³^|ï5s1}Ruªm`¹DiËp»úáìå‰ÄF¢îÀxåï`[ßÊÊgĞšnŞ›asG±{Á¼›¯ÁÈ,¶Í;õU¸Ÿ.Ş§}&_$ù¥4êBPá¹BR,ú±åˆ’ûŸÊBŞÌ’±'‹1oz·Kˆ7Êéƒb|Ï>m¬>oœ,a‚¦İ-UÄfå¯ÀzD¤­+3–½?X™ô EãĞ˜³}øô 6ÔíåŞ1L!;ôb«µ <şbA%›ŠÎÑ¨–İ5if²»÷‘¸HË±âYeEšP¬•£*·”ßÅnÿ¬mŠh†aÓ’âÊ0Şï½Aãehwd#­ıÓåùÅ®W‹y“wä¾/[™Ç2œqÔÍ“âf	T×7™h”±y.{ÏÃ	ô‹y w #!»¥²wObZ=B¢éÍ>Á"»’tNq82‹T”µàÈÀ!}bçAjï|h6:÷D• B„¯©uùÂÁ2ü[jôö‘åñèåkú*W*:Î¡k^ÁaË«”^ÒHˆ“~Òw®zî½¤Ôçõ“–ElçÙZyT-ƒøÁÔ°Q$±´ø¹ÁW‘smOvôLæjÇaˆáú5¹r¥Kn,ñW—/C;KgWÔÒ}qÎú ò,ÊUÍ·{›°®ù¢é}†™3:gä»P’álËˆ«'¢=?%cšC°vÈäFÒÂ´¥J*4‚?‡<'`ÄòÂ§ÜmÌìBÇÎZ£¨A¬vDZbwQçıNF¶®Ágcñk]Fsm±Ÿmë=ÒÔÆ¯Ô?ü‘=,AJ×Ô˜î&Ef±íØlüeŸj1às­9º_E GíİÕ“š·yâÿr`ù)¿ÅÒyÓƒì{ïÕòf¦,K’½¿9Ï§·?–A¥¦I½-Şq"MV¡ú›…ºfš†–ÈĞ1Ïğö˜õob­ÍÓk˜º&Òµ´9ø¤=Ë3*(8l`“[y°Õ˜Œq"¡»wıò¾q)r¤Í{x‘­—pºcDÃŠyÃ©+–Uàºí#ÊÏÑ$üH¢4¢;òIÔ§¼Ì+»3àÎÆqK1±aGmæJ¯Æ¬\>1R~¡İf"RQ/¿ß]^¾ó,ı
˜Ã2tmy€ÒAğW‘”…ªï}¾Í¸ƒ¦nü³Ë~+?±¯ßÔ¸Ñ¿şv¢¼@`<¼«™#ÌQü&¢ùĞRK·±Së#g,ı;«-BaWó@v	`0ò±,­óg¨tÄ¹ñ‹6FÎÎmd/öPÒZ—½&N–\ÑêİAr-GÅÒÒ "Îçd/0ó¹·N|Úµ>¹Ë{_D|ŠPs§íb+Æ——ªÎn”‚¾ÖäIú#½¨­ úÑ{²afèe†ô§Òæ;5­IOEÛ4^¢'NwyNİèŞ9©Ër„ÿuÇ®ú)ı‹â>3‰ñÜ½n»°R—Ãe&_"‡ÿğÊı›J€N‘©%£·¹lïR çù8bÉ„
3Ë#?Wğ“ä³Š¿ü´Ö½)æ°“›n}¼†åÊ’İ
¨k^xàÕìùdÒâ%›Rû¶öîÉÂ}	O°OG`©?£,¢su~D|á»wüFŞ¬a|ŠV»ÂìÄxö@'à V”2uÇ_óò3G~m† àÊtG¨ådÂ'u¼Fu ŞXùQÆ3Uf³Îœ™Z•É%Ğ)nïT‹²ÊXÁR©IšÇVá€Ì‡¿Ÿ¡làiÈ%©\à³V$fšøÁÖÔ_Q[*°šJ_IŞ¼ºõ «äâ„ĞXŠ º¿L”Xmp\¨rp.Ô¥×¶HÄG)¼F#¥ ¥A’6‚ır#ô6”½2»–ËÏ¬w£ş’DşUuÃåÆaZ]Ìªı5À÷’¸ïîÚ ¬PDĞ·uošLÉW“°ùyØ¶»½)#…èvµLõ~/š"&\ µ‰ÓŞÑ\Ä ú@ÈCx1(Ík‰	»®ÎFŒ¢ÁIÃÕ ]oŸÃ3!Æ"ÂK~½îo›‹•Í†ı oD®ŒdrÊeaŞ¿ıêÙóÅObfãrq‘SxÌ6éLØ]ÎgÏ[±*‡SâV„Û+vşZè¥¹+ÀÓ(ä–®šD
I·$›ÙWÀF°!­TÓ{~Ä¬}÷—CR)7áˆœ)ª¥ª2.=7Rÿ:7…ËR±UrƒWõJ–)¾°é.ÓÈh5Ó‹ˆáµÆNºıÙaV:?ïÄût÷‚ÎB$4S¶u{ MLª™gÿ1mÜ­ô^yüb‚¯›W±¬¨$ºğ¥}ù“&ô±³Ô8IED®P:¶Áy–&al&Œjzg0³1è´ë‰}.-(äïnõ…çÒX’ÒÛƒÛîlN'Xgc²wy®2Ä:öĞ/Yf7,C¤ä!ƒŸÕÃ‡s¥ÊÍ½:Î¸öï?£¶öy¯€	9¦’nXÃy—\îY¬öF%u
ª‘š©†ˆ¹£ÕM>"ÖĞôjR‡ÛJÛ †&Şõªr¡0«Ö5,@ÇgÄ¡%faØ&u§y®Ô|Ï77Ó8ÓŞ2•“œºÌê¾Rê$;—T|;˜“f=8_ïŠX×ùÓÚ(ijKWú|RjÂôé•D6á"ÅtÁà
±lJm¤!3øO%²T}“…$0zEo\j[›ë§€p’|[âpøMÕ×‘¼YòŞh~¼,ÖA:®Ó–—©…¾=30zòÄæœïfÑNäY`ÇğY˜Çö†VÆÆÊîÓ6ú@Öµù!ìœR ’8yÔ˜±™¶(jR0³{Í@›²‡‘‰8‘—¨Æ-\üioXj`G‘Ã±Ï#v&ö.Ñ0ĞÍµ€…ÌÛNÉ7ÉºiºªáÊ/½JGWÑĞÇ¸‡ˆ/4üº#´¿ı,òU±DÀ¾ÅJ:3L°êrTşDˆ|†ãb<*nÇXtÚ±õ
¯4š,YQ<%7JİÙ
ç™ŸÈEr}6°¶O\«r<7Dö2ÉÎ«ç“1nˆun+ÒŞWÿ|W6ëy÷i ')J¯ÏÍÚŒk$s§!Ùàxµg—ª¸Ô•ø³˜k"¼ouôÌ%3¹í
æc>ÃNO%/İJ#µNÃ©İ¼L„ôŠŒ,ò‘ÉlíÍïè/FH‹³#”|¨qÛô›\Q8Å¯ï¬Î§%ª&Š$HÛ©“üõTŞæh(k‹‡rúª/Ÿ²êÆ_Ë{Õş°(µÌ>¤~Ï÷€
/á¹·Å‚R}<yã±í¢5Æ’Vş\°“îP‹Ñw¨ÏY&kÅ‘`)5LX+e_ó(Â“Œ„§pª¡‘ú —Lb
Æf=—·À©œIğxOÂ#øƒÅúª˜Í×‘óñ ±S¡•kŸzï³5àª¤¨¯ÂFş&ãÀ®Ä+à,È‚bì4ìËDó‹¼FóTìôn–Z¿1•ÈxSÎ#Pùt[‡ $70a¾*.”ÚÓĞ¢N×\›ˆ‡çÃÿã–uÏÔÔ©ÛÊ9‘7L‰ˆç† sÖ>UvpÎ'‘°IÆÃl&#øÙóx şJı“3iJşE¥,qCoü§ ƒhF=5ªˆë€ñèè£t~ûPì¤YÇø8·CÍí)éÎ4„Ä®;yê÷6ıû+»š‡–Í_g×+ŠŸ4/“0Æ>*ÀW6Ø}ª„TÄr·İºƒòGÊNº¢Ún5(¨UJ“ì92òÎ·N‰ND#• Í0GÀOk’pwÓšF œ·}Rt[ù i¥)&VÆs‚s‘İĞez±‡f™.´Ò¤Ãi¢ÑÎğgÃqûtD³%üEäôD²5q26ºW<Hˆç.+ÌŒ±f)Èq,L	opĞm\h®ÂˆAéIèÌa£8¶á¬™µPà„øæûm,®ŒºÙxÕïÆNxƒwè@:g“­ËY×c²ì4¯PVıb+)•“$ˆ8µ ¤ê°Ù´™>Ô—M¡Õ†tğ8ÄÒû#ÊuäÜ6‚B¨Ûò|‡¢/,çH´£x²Í•0m ñÛˆÓû²³·™áØÚÇ«‡îa2£è~›
æœ
Â]¿–	¯·‡-e°Ì-™sšy×ÀÓ¿	’\îltĞœ‰¨‡Ä>€T(Ÿš¬Uàe+Q‡S´ªô  Gƒ©‹tîÅøW¶»Tp–m+=¸¤Â£%B“.,­Á2d¯…¿ø`IH¶esOû²fò.Pe"©‹?AÚÓ`;x ¢Xmdië=ÛÒ!
’ ÙõÏE¦yC^ÑqîÒ”JæVW¯%$–*y½ém½ÖFGõ;›‰JvdO®”šàšo	Åÿl%õ=ÿ5wlÆ—"æƒßştŞÒìòµÅı>h3A¤8ŞSÕ|`Uë¦Z<½¼îÈ-F©n<ÉC/DñğæöÌ/ağ»¡J3eÔšìK¯Éš	7-}+Á«}Õv*å±Ok™q‡7ğ¶-_ÈàeT£‚<€‹?…£MÂ?.Ã8Z?š‡‚	Ëu8P=Û{$·ød
¾p³.Éşá3½CşT³¡â~~ñ]ªáï+}È…^/
óœ•”¦Á~0á¸x…OÈ´-l—eF²yÆDªiqcÎqIçÂt¢r7ÓévÑÌ¡¢·2Ç¸Vm>òóşê/³ş€ñ‘Í	)Úğ¨#ádiµVÇËghæ –yşnt vtTÛ˜Õ€_-?7›Å~V7•4WX!çU/ÛyY ÷°(^}=U4Šı5º0Š°N0."ÇH€ËÔ:ÖDæ7Ú“yÇ7¼ ÎiÖ¨ù¦ ÕùDx}v²s‡o,Ÿ%2ªv‡²š1QÕÁş‡?WVwN•ä‘®á‰•¢ÌµæÔºôšhdòSà[aßb•0ÂW¦ÂŠ¹ï‚:Ô]k¿«
ù¥!u·G–ş^~,ÆøÃşOKò¨¹Á˜Ì$ÎFyóï0˜%UwùK' =lOqŸÃz–WÅ¤]Æ›¤x`“R÷¥ÓŒ‹ü+£&rûw	u!ğ–ŸÆ-V=m¦ÅJEˆ«í¬¬¨ßG»:­]SIÙó>è°Ü§JŞÿx0V5((Gk¶ıİ"Ä|ÏTn¿A!Ü*ÅrPpRœ3üˆaÏÒcƒ¬q—.lU‹kGR×ç‰!ÉÍ*`uk|±¤áÄ>]yZô-Œ¨¼Ê0=E‹lµµáÆ²%ğt[»AèŠÙ-mÒO®¬’~õæ©ã}ÄÀ6û+JøUÚèú<àš£ÊìU9‚CBj<Öÿ}%¨Û€+TXZa4äötr=¼®¨ø²™ÿºúy(”İM¬¿Ïœöˆ7ÕLß÷ñn±ızLÿ2|æ¸¼ñ0m¥äÓ¶«ÿ}¹FÄñ¤ó³°Åıç¿òU5Õ‡ZŠÈ)½=š±´sœáÉV×ë­¹,Qi\~ëIÈgÀÚŸòNvs±+ßĞ£ìqŠƒ˜¿%w€Ñ‚!»-NlÀzÇTÅòß»öô(÷Ùú–€å•¡ùŠ^Emi[ÉûlKÊ l…<6;iÄyåz¨Äg^ÅCƒ1•ö†]jğ,F-ãıõ© ½ÿ1VÄÙÒ¶CĞ4”S	~ä4ï]3à×i%xng“ÛP«äó±™X¹B¾ıóGRûk¸(“µRïE$œû…&»Söµ#ÓBULØ€^¯½x ˜±¦Z€¢µ_xÿ¬W<˜bµ“ãN­·,®Ğ¹Ñ¤mfÊÿ,hh¬ûá´†é*pv3u{†\}ÛsÅ—›ÄcfXyã5“²üŞlDÕüÊã/«‘Gvå*,,u¹bÛ†ö« hr<ÜeøXœ)… ›™W¶¼£|Ú´ˆ“”­zjùNòÃO>7  |sfòoRYá‹A™%ğÂkL£uÛº-”Ë•&ƒ ‹µ"®^H˜Òî4d–\HfÔ¾µµ¬Q£3„Şøeggt	ñ)Ó‚^`wÅ¶Ág·çfæÖ&Qf“hº¦17`5mûÛúÅ”íQĞ¬Ì­ƒj‚ğ#+òÖ”›ÍŠJ<8ƒó_ÌfÜ$AMÈ2¾)¹NîÔN¥Dœõ¼ƒd6°K\ÿ¥?:>±Ûr’ñ|\–²NF’åÃpZ6iş‹g×”I^Jà½]àÙmêŒ*t»ğ§J­Îèë ?†~â2¼;ĞŸ‡ûëNÕÄ™HçÆö/­1‚Î]ìp,¬Ì•,ùÿár6£y»¬D²`2¿Ğ•.Šô¬ãÅÊ¼õËaß–ÅI¶Ú“;"CzsÍì†ïÔ|¶ÉˆS¦î’íŠ°ØNƒªÕù!UR¹ú9M’"ú'|©¸
ài¥!·Ëep£{Ùã•R†Ç0ÜÖ®FV]PMX$^<³€$ìñM"Z±wrşù„W²³‰…IãqµN4;wÁ°î^zóo[Ÿ“eÌÊˆ·;Æ‚ NzZ­Xç2JÉKb´¹Q„œ*Á%41ÄÄÌí›ó>o³È?L{µ¯³´¯êŞ›ÊÎ£–?~hdîÏŸ­‘	ø”dOÓ¯­Ö§½ç4*ã)~ Ã|¬^¡Ê‚nŞËÎ	’,+²üh-ñ^Rş‡Î‰ä‹×|²È>u¹cS35ÈÛkí¼
ši!¾‚°ÜQ›}çÌ©¬>nyze¤4¾óú“u>Šl pŞ%¨\Ó)æ$¿ù´ngfÜœ‰ è›aŸF©—TQŒƒñ£¸u].QÜ•ßÊn€»yRuÏÁÅ%±İoIŠİxIæzqGC÷ÚEŸÍy~Í›é¥T²TêFí_1O`t»»m76ôeT/•*¼I0¥>½’ùB¼¬,j)*\C³XÇ¨8*½³ã›º|*¢©¬Ü‚‘ò¹Åàç?Sû=kÚ#øÛ­Ö>ÃU&º¨øêöUŞô‚mâ!$ø”\Uß¼ı©™ø+#‰i—ê‚5ög1¤É`Ëª˜Ïº0ÙÀè»qÕ˜“x»™†»P„§ı¼ZÊí}İ8á®'H'™6Q{Ş`ûøGY¡h«Éã|ğ‰ÿä*u“© "yùÍ«”àè`a_„»Ø,C—X%»ÿàF µhÓ÷|¤cSfn{Å‚:_-PÕ@ówµşcÔ¯TÁ9 È*L™â¹íuæ\Üä4Yk»ç¤ú‹/Ï‰ÔJòB‡åN›¢›”COC*è&êÇ
~„ÍöÅ<Íæ"ïÉ˜ÁÒŸï*éìÇæø¦›‰)Òßó‹;E†È²2qt9X®ê½Sã¾1ô
’!Ï*ÛA¡Tk_OİlÜõGeúñ­æ$]‹r{Æ¦ëKzŠa°AÛÔ	{gs„2:a%î_cš‡cÅècş€K@9˜Â=<ZaVÕë«ó»:³—]8˜x¶ê“vÌcM²ÂeBêÅÏĞ4W–î‰üˆK÷©y!öú¦Qˆ’\:ÚÓö0Ø….§Ü7+¦Ş°Ë½Ä§ƒJkÒö6+é§tº>¹’I,ÖêÄµ¸"çÕÊ”Ã	´„º! Ã[RÔÑ•ëµ.•Õ¯]\Kçà IKØš•eÈ\´Ëûhd.÷qá—U!®™uÔ•ô»ï¸y@·}i¿]7©»¤
…ïeÕ+¯œÕÑÃ×ôÄNBãuUË^Olˆ/[U°Tèß	í’±jD´¿ÄÑë'¿2?(ÙãÄx•¬däC}¡ßè«ˆÕ¢%^úÅŸ5ãÿ¯€šòÙQ¤¥ó½¹zA§t½ísXóÜÙ8¼ºü1‘ü›tg<ƒJaW@å½møªÓBÂ•œ›lĞb\*¡…’[oÁÍÿ	f…Ú<­èYb’WÒÀ¯äÙ2*gSŸšÓªÀ*¡]ÂĞ sòm¾TÀxĞ|'AòQáÖH“KYG ]&ïã{,A8”kâ¥¨ïØ “ák¸*ƒZ•Y6šcäI `3ıEQ³Ôƒ|rd´ÅRxù¼şi(wÿP8.‰|³S<3Øï7ğ¹KîpêFagÔâS1ş‘@JhV[Wè!’âk!z‘¤R-ôDZ'Hªv’›Ä~òåYZK]7. xßÇÇ;åİx®[H¾h Éâº Ó>«—-|åõ¹AUZ.¬»	A²;#Ù~‰ÎŠíûèïGF·jºÊ²ô4ßg&‹	s¨ÚGY<âñ'oÑ™>ß#^‹Ÿ«ª…¾e ú2ÜÆX¸Ag™áÀ\Ğ¯ÌJ“ rfæ*Q;dÂÔ[ğ(ßò&Ür:M1Qj{¤seAG]A.13o¾©&LàueI‰¡ ]Á+AûÀ€hßú‘¢ëÚå,à!Ix±?ğBlê}#cv€™Œp3¥A6aS"u¬ª³b³*/Ïzˆî%)lDqa5Î„ìÚ™–øÁósQæ`ßÃ¡Ÿy·œü©i?'€6cÑïÚsw/0Ô¤Ì­XÆÂè}MõáBChËî©ëQ5lyzÓÅGnÖG8øÓnëÆ+J“lñ'»½Û_INÙŞöú­,ê!¤éËºJ¨Ø¡Ì'.u3êYëHvù¿ê
‡İ¢à:Ã¿8
ØÀº&9‘	â¸Æ^mö}“?qÙ—éÊ®E²=,Á›W¯ËâáÇÒÒÔb2ëÇÏNùT"!%,—e½MÉÇÎ³Šİ~ùE)µµ™_–šç‘­	›àfl‡ êK3“(	RB'à€ö#ı/;uÃŒkfxÅî>Ä18Ãt±®ß—qôñdî˜×†bÙBY Š>åÏÚÍ™ 6Á¸_ÉJİR¥-)b¥ÁˆôuIÄ~,_ãæ»ÍÏNªµguÕ¾P¢¢&æ.÷3‰û<=ëWMoåe7ÅËØ »ÔF¿qr]ieÄµî ƒÉ3Ö»Ñ¨_ßx^tÏiœD‚±˜Ò£Ì)Êİ•ÏÉ=Ó1QÔ]şÑó*¯Ø#7}P|ZÌ+„J’`2æŸBo½p+Iêëd›”›Ä_l¯
ıáÍ]PH‰\»jQ›¤ıKn×HDÜEğƒ™³
ó+Ç¬Æw¾l(õ¦ü¿J#+¬@Î7º…o\)¤şSƒ8éµ½öÕÈ’„5âV˜õ”Øÿ aùŒ
·šœİtúénZbñşx]4S‘­õÂZ~¢èß«ÃiIõ"noŠ·­’Ä8¬Âç4ğMS‹mŒ}{Ås¼cç/¿uÒ	XÿÊw‚—­OÚ NzAô®æw	B¹š5Øú‚»ŸùÛÏ½MÒñ>Û$0´_³7NÂg8ÔcIˆj®b M*m¾uy4VG>:àjİœÏX›4?çjà‹Ñ4¼êßbç“‡Åº^µÂvá£t0šò÷°I¯oğÌ Í²!¸b!±Eãl[â¦Jl^şsOyşªò6:ä…!ÅØ! „Pê=U¢	 Ô¢€ğ~Kä±Ägû    YZ