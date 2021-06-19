#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2166914595"
MD5="98d837a59afb95032716bbee7396892d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22852"
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
	echo Date of packaging: Sat Jun 19 18:21:32 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿY] ¼}•À1Dd]‡Á›PætİDñrôäpö.ºßŒZ…ÁÆ&Í*
~Äá€?ÒĞ_ài&ş½4ú4˜oñ}	µsºJ]œê¬Îæˆ,W¼İuƒ×YÙÁT_63èî­eû¶u‚L>üÚ÷å>®hO0:ô9^Iöû0ü)¼Ù‡”P¡ƒ‰a\ãƒHÖyF‹Û“ê'ñ¼¤`Z®gY?­äN	ş±BdºÇ¯ëÓ0•¨­Vb1hnPúJ•\‡54°”¡òËôXk—Ú%':µ+ğ5ÏuüÃ›I?WBå°§()?r›	Ì†¸A&éJècŒO²)8Ê"BuûG‰å¼s4[*›‚gz wƒÌ³—Hä tîïÙpNt7
ÛŞ´9\…î®R¡îúêù»Ëº«`x$ü,–tğøge]i%£pL)ZßªIÈ¹b£GğzåeµèÂ™Kó¿G·+ÿİ÷bŠ×<ˆ)?”à°”éÁêQae¹½]LZ¿ÔOM‘˜—ŸôVš¼-G¢¢`¾!—!ƒœ®(Ä4¡mÚ2ëÚ|¶‹à“øBàuSP5«)éq(õ<Lá.¤Ò´œ’dVLI®O˜ù[Ÿ]HÆ7Ì Ğ£ºóGvh¡œ\\b­#ŞÊêÍ'™Çp‹¿ÑÉ!2Á‚°£İ6 ¸ïÀ9¨&rç$ aWñÕŸ¤±ëò4ıÉ¤é&CßÛšeuj·7€l¼_8¢Ç¿7è…ÿı^j3J¬¬kRË	#âùò}”œû(p¸øöÚ´*¹ëq´²ádÕº…#+TÕKÜ˜µ(±Úßıá¢¶dûŞÚ%‹0¦QşÍ<é¼ÂI(Ÿ}J‹=âS÷¶(…èG¾OT‘¨€«u“èİ¯i%ºgÑÊ`1óËƒdrœ¤gøùùúšÏ!$“ÕÅNÌ3ØÜÑ+å4BËbr¤ À-Üø“ tñ¨,°‡Çê‹¡Ş·i+/3?–‰G¬Säag©X¼‡êNÅ±Kˆñnk¹ùGº+vy7ó ÖøöŸb;ğŠJÏlQßJpö“Êiä¼|­€İ¢¸Ì¢5ˆ:”AŸ¦ß½U•:xóÍÕıçúÉ«ƒ.Mûñ_o±a¥@­£­\h¤Dî1ÛRï¼¡²K=t›Û c‰±Qû…ü¶p³‰1¯n²@~süØ–ó¹Á3É#J¦+‰©uZÚ&9Í,Ï£@b]å¥ÈÖJp	Ş9RíØ¸ÅU²`(tF
à¾=máê¦õû Iá&ç%G„2N0cîxT±'YÒeEjcı¸z<Á	µˆ+ü«¼)îW'(]p±„ùTkT}öiÖa¡Ø·ÌO+/RƒXfó|ÎUTÉŸGk~¤šã#êô-Ò€ß7ì¯`ÈVùÚq¸kÁoÄ
 ş‘7„«š~)ë4h ì•Ü¨“©“¡¢´k6ÆÓïdõâµ4—;2;£¶!ë7Oç10rGDHÓ«G†»K
R9ÿg_‚aÑÆoÄ}nâ¸´ŞÓÆ„çô(„Jq=Ô•´ ¶Ê¾jÉ!L+¯‹šQj¬ôôfeXÚlŠÃMF9Ğñx´VÁn´\ıºº=ù?C^à:ôlú°s˜Ğwd¨nadúµ’
ï&®¸îS}Œ¼ñ]~<£è‚Ê$Ã–VN‹Gì”6W[¤àäø³³TªïWü]š
šø÷^L‹g›£ü}şİj²Éh¼iÛØÎşŒ„ÜÌ—˜!¼6?åÊO¯Ô¼8zÚwK”Ú€1ïªÖıŸû6¹ —ÙÍ®xLÌì¢ĞbHš’UlpÁdEü/¸ç}u¤¯kcI\Ÿ*É¿,’¥ò,'ÇÔ*éf°0>¯½W;£¼€"×ëü 7«ˆØî‚¯¥úfîòYm§éoP #ÁZlŞÇ¡ƒ1;uy<=>\ÌpÈ)4Lâb/ØíKÆkw'f”XW_iÖå.ÔI¸üwÃç>ƒBÇƒPÜlYSÌ²ÃŞ÷$dBĞ+…Ç&İ*V‡~7×®)¹ÑÃ$çms­ËLÎ!õ&Ñ\õƒªÌ9b™ìÙŠ}’±šá¡éşGÙÉíCA1ú¼[|uãpõT¯ˆÆ?qˆ8Ä%ü OCüÃpxD˜Ÿoá*åÉ=½(ËÃN8¯jù]/ADo	­°Ù$-ú÷Ç:Y	dü{`ÂSŒ§°Ó¤ú™Â§;¹Šn‹_;P9èÚpÚÕÜiÙÜ4|±ªR¢dšêtd9¢º1S€Ãıú«YªNxFë$“`­UøOg]•‡¯‹¼XêøØıò:e«úQcÔ¢y¤3»Had”¿L™
×¤ù¤š_çt[Å¤—÷fş¶mıÔ˜"Yì×úI	N‰q»m&HÀDw…{éõ'Ç÷îQÛğ™Pl@§q
æÖ!e}†óc1­c$¶EF²ë|¤E^MÌùÜ*Bf…fâJÙŒ•S!Àœşğ_Ca`“Z)CÌZŸöÒ}ë»-#Äeiœ2ª¼QcàøÙXö¹Ãqô„ßà»Å=»†ùìwĞ6 Å¹$!µT2€*3bH¿Ä™ğ¬ÙÀQìLT)NşñÇl‹•5îùuDYŞúJœ….¦§F²ˆ¹uÎ¨Z7ñ Îå°šxsj²¥Ñ,„ønî¥,ÄÑø	(È@)¦Š•$ ÿ¹µ¥b¶rš¿ŞÀ$ç‹“ÚÃÚ-÷…í…Åš\îäÇSE¾•ÈÂ¥Éœa“o­e±~w¬fLGêB•»_háOÕJƒÙVp+
Ló4ŠRA«ÊCêeBş¾nÁ ÇÔoÂ†R£‘®–JõúP%óŞºÉ>#âŠB9¥rÈ³óşmq*{­Ëêù•Æ¡B%ØIå¨V@†€AI¬äá±f«êè „’j[Õú¶r2×` lğN5ïZEÕşFb	©<°ÏPŸ|õPğäB-o›¥àÎ´U&'‡f/üÑo·\ã4m´e£Ü«á ¹ù8¢UêÀølœSôIô£JÌ¦ü3ÇÛubÊ]¶õkMIríŠ#>#Œ".æí «
Û´ó‡ùMğWIˆƒ@“jT!1J„ÚˆZïˆ€ƒ›`­ÿ	óìP˜"{§­Ahiä=™Møõ?X\ın½Šş‹iúdõ"1Y3U‹CMŒwÓ>~s¤á4eÓ§H5w÷“Ë†jMŸ.û‚g‚£ˆ$¬nñÌ5nÍ‡»Üï"w[ıª¨ZA]iµ&ç–Gİœ‹"¿°;ß"Ùı%úí–#˜ã5çEŞÑÙÚr‰éÍ˜ÜßÖT[‘§—,ypºŸöps0ÕÓ_·ê&T†æ¿[3ceµ³_P§
tõ7ƒS_‘ŸP(È)-Áã¦¿ n·W–ÁÈ{©ŠœÆ™¬´šÇêùĞ5™½éëPF_${û"¾š®–,§R’H%v›y«Ña #{••JÊĞW‰Á	„y•%A¤=PW”(ƒ^Â\dñ´ÂH·5ïáDFıè§è`ìÁ$eµr8æ6:(w«z¤«›D‚pzñ!9Âë\’Ì‡µ+!ß/_Üæ	Èü»Ş¶;Lúeaò^tÑGf±É\‰©”²ÁğÄêŒ“ïax­İeY·ıãMéëp›•ñÊi¢ùÿËÆ¤aÔiïãhÌÏ
 iRQ<¹ËŒ¤%#§óß^óV¡kÃ_u–‰q6ro¤¡¹DI•ø4Åë&%A².…ô–Y>äQ°ËÕ¢fO¤,Eñ?¢¿¢áÉ3á•cô|+^+	hs-9§l:}E§YQÀÑ_R•Ì	š·né}ÆO×W–0[MFzÛsMC‘²0é¨¥2,±ekŠøÎâàaHøæ.šÚ+3NáE†sÖ:êK²›
×HtºxÈ4âàp_½šï²9[à¾|Äñê9Ÿ¬mwíS H…=ÕÚšÿß£L&Ry`ËƒüøÙ[jBâÔãµZ>_”ƒ¿—éC¿åØOØ„I'N›{ı•«7†C=>ìÒ0ônø¡×ì?	Íù[bÚã7-rX¹B`26=<ñ~ÍÕ*>Ä°Â´[–êŸ™’÷ö<Ã:^pC»ÛºŞ8äÍp<2‹|‘ŒèæìLŞØûwUÑç¥«¦ƒß¬Åè–¦o¼Ø<ÅH<ë¸µĞ³ÜP7vÆŞcµÄÁ÷yù_aZyÕfs:åjbÒÊú€–ã×-\¥‹…z-ş˜­5³±åJ7öW®ÊŞ°²¸;ÅAŒ]×—+ÌF*ağÛ ù%şIã¾·ßå8‰3gÏ¡Ùô¢Õƒ+4YkPùÌÀ zû7@Ëed¸‡î0·dÁT^¬àÒ¥Ó4ºÄŸ¤¤Xk”Pæ7ØpƒìD{î9~ÜPÿL¢î¨±%¶) !ù¦ïÚBø5ıF¬R|u à¡N±•ÀFs–p®2•µü]Z|‚Zb*=%úÓDªPGÚ‚2$SAû[•ş­¿?I¼^mÂÑùƒPîÓ¯y+:6]ÙÃ•ĞL¥Ğí‹¯sÏ¬F;ş˜>B>)‡ÛæpEÔN?n $JPœ¬ğX2²k´|ƒûQlÜXEDîß‡ëeåXƒq­hÈô1U¹è”ˆä4MdLÍ„I"eÛ¸‹p^Èê²º¶l­y·u„!K2ntùMôU	y–¥HIl©l‚èHŒaŸN8¡ˆİ{Z¦áÙÒ©."Ä¸ì;²UD†¼Ş¾é{Îê?ŠBÕë'H×æN˜+V<‘äÍÃšnÅ%ôãd­.:—¹ÎşÚ¢ò%óŒœk?fNr—½4>ö®™ä#/ëMD…7õ&oÄ}bsb0í>o1œgq‡oÒ™ƒ¥b•¼"i½ËTÓM(`eõâw±{ •Ÿ$ß¨VêN¶ÇÄ]i—ü¸/W¤ò^5£‡~CôF:¬ºƒWâ£"[¨qçWXxÔŸˆèª‹Ó¹íwwç¡\K	ºúÃÌêá»ôRáf5@F/$4ºn§`³·¢uôŒQ>dT¤/ù|ŠÊ$¶¤72ªƒ†¼÷’‹Ü ³Ãw.V²ı¡Àkâ¬ÛÔŒ2ºÁ±Ô û»ğÙi¡½.±÷şøàaP&€Èzîû½pC	÷(¹–6®À”õ|—‹8…1ı–s‘í9äbgr¬íææã’º*òFÙòÕ<hãu\]×¬RŞ”^k_©‹hB÷!g_S—ÏVŠHQ
8ù ­xiã7~z”¯ÏaÒ¯=÷cT(”29"“˜=Šú·nñÚü~¨ÏŒâk¥—Õ.,„´!àj3…Å˜)l)îô£x¾°ğç,ˆı]vød³UC6ÇÁ?Ñô¬ìÑe–ó~g¢Ë®£Ãy‹ÇÚ^¡fˆ¦TÄ"ë¸qd£WËC	èk«;N÷M¹2DKÌÕãçWaŠd4‹h	ƒ†Ş3ÜcèköÂ]ËÎÆkµ¥ßL5¥8®9W%”½¯éNÔÉ¬¹³\Ù­Nó%ˆ²M^Ô\6´­<ãaÅy‰½¢èü¦õûMMåYÄ´ÃÀTœ¬şyÖö™±ƒhÆÑšˆ£Î3Ç„]æûH¡«Á¼ •µ¿
8™Û…æ¹@q¥™«	‹´²³cÒÅ‡ÆÂšÄD%õ}è¨Bf¾GÆ)Nà*´‚êTãÙdf~wDYZ@ÂºëÀÑ—ÚÌôQsÚX•©q'[?¨‡f•ïZIsµ*“6´PŒhØ}µ*Ù­e€!×'w‰_ÉJ ÅÈ±N;jÑSEµÊAi–GÂ›/^5úXr¨}‘"ş¨Œ¶Ü€w²fb0<‚%’·h {ÉÔğ¢ê²ôg€Ëô×cZâSàMT¢vQğysWM>½¤aQ?Œ.Óà÷u\8¨ØYA0pşpe²2ÓOÎ)>³®Ã:°š”Õ¨§¥FçÂBX#5¹ñuIEz‘¥%é¼Ğ<şR¿ÂúÃPBpYO2NB’¡zø(Ôd•Ä®•‘úÒĞ‹ˆ‚"Œ~†8TZhıB#ÚTÖL£M½cåÂ~Z÷ûµ˜]1“6$t ×@pã?•¦µXxí#twiü²WÃ
İÊ Ãÿ-§Ò†@N—~MÀ'…eıØR³ˆ4LúWğ‘Â›¦l‡¿ßêhY©PÌV4×<¿ 7f±rv­§ÎéŠ±U7€C¢4MnÛ0'Œ5åQŠÎ1Sõ¼áÇÙ¸±Xâe4E£CÒ`®“Ö±ÈšVá¼šáŸIâİ»—êÒ®^uåºA]|nc*Ş‘pğn²ˆô¿®•aœS…ƒŒè_äÆ¯u¦;ç²r[•ôİ[×%•ÂbtîWùŒN±¦}øZ›\IöFÑ[oT©mÇ#é©6 ·>.1¼L=óÄâ] Õß§Òœ¾—cØ‡93àõX§µ¯İïš‡uå÷ËTâ®“KWKœÉÎ´5÷€R=ÃÈel¾|Í€ª}Æ±°i¯Å°zˆaİ}äÌâ .‘²½W©#Ç™é·}5Å¥hû¨'Rïm÷ZéŠÎfœr+ÉÉ¤Œ»ùVb	W¢t28™Löû_ßúôu>/=gğ9TÁN¿¦ÍSV˜Ïà‘Zˆ’;Ç¦^m‹ËÖZå¼r„±´Ç Q]FK„Š¥Ï°†š9w;¦@L—í‹DÍbĞä–„¡h#/i“Í­Sóˆ`¿?şš¤YêÍ¹ae.’ÇIC©"ke3EÖß|ì
dÍNæ_ŒWU§ÊÁ±^‡³÷H–z²d¿®‘>Gµíİ$xçbOğD¡şùaeî'áüÆemŞHşnÇnÒUlËNø	(ø”²E<NÛ³Ä=ªKÙÇ*1ËÖÕÓ¼Ñu–±¹à~Û‘×F<ÿIú“LÀE^›“ÀŸüGÉùQ,X!#ó2 µ{ãŠ3†!'3èS¼¯³²ÿƒƒ<¶8Bş„ƒ3ì½,{BL©·I¶3¯& â$#¢ GYl ßõÖâ¢48·ŒJ»£ éõ^Üu´ÈÔâA;K·£5Ã÷¥G&fVè>;.'y•=Ä7TO1Ü`Vùqc3èæımğñT4KH(
Oè\I/‘:í–£î‚µ¢ä?õ…($„JoI]€ñ2®‘!1`OÄŸú¨‰“éŒNáİ­OêßÔdV_>IH¦—dÜSrS·+ô^ÃL¶$H‚ø‚æm~»+Q™Ø}ŠÖF»GòÉ~©×¯Ñ§a<ìã;òC^´Üç<’Æh¤KF’il¸G#Ğ|ğ¼îK''P<ñãÍ•„öT}©zºËå'ƒµÅ.3û¸ÈH×>ë­eĞá ÔQ´j)q£Â';ŒÖÇ›ñr³lx¨!ÊVYuåt¥ƒ¬ã¹[EWÙØğì~âÑåéÜsj¯rrU^äœà2“’H¡õ´¼	,P¯#ZmFiª1£C`™®¾\IQça{72kPºB1"CÊD„&Ü•lÉ×Áÿ¶Wm{åZ{ÙÑÉ*ZaÊj‚
€·1!ÈøöAdßóx«2#P©zò[Òí…øğÊ» [d0
+:–çÀseßŸÙzq8ú´şÒ_±eİ4÷“ıáf‚Vãb®Îé3L0*gôs^u‹Vë›‰Dvãv(-Ò”üòeÖßŠáËL×îí˜n5 "8Š® «¥a‘>ö¾R”'İNúÒñÂ¶TÅ‘Ùd\¬,H¤x!i„6Å!äÜú‹‘Î'¢³Ñ%;Ô¦¨*Oè“TãÛ@‡’\„N±yQ:¼³ÊåP««mQR´–¿·Øß˜1H«šÜ4Û,a²:B K:O6?œËŸ¦µ5‘ÁÃ’ §è_fÉ*ÊEºÎÖ´ÒR†İ"õ)Ò6kXGÒ0÷(jÈ.§ÙşuÔ& Zê¶aNwÑ2Y,–DÒ}®,Œè¿ïn«
å´™ò"{&¸NGæ5<aÌ¥qƒiGœÆ%±Ê'm§Œ”ğ<`¡—é€’™+MYàJ´ÍÖU¾:qCj³	®»Â/.5 ½ë	ÈXëß2•÷2ØÁ`”ªQöN4‚ »ë¯üÅŸa“åÊq;e	pÇ—½Šı'²`è—ÈL”áİ[A¢ç„Æû:æLD(íWæ¹ÙËQA6B•°:O`@ íVnáh#ôÒÒó—ù¡Ş¤½(¶¦ (—v¾oN‘ôÌÄÎygâŞ]JbRpzö®Jôã@$C=T_?RT6—;Ë2ŸÑÉ®ğ¼ZŸ0¦aa¤7Ô\¨šQPÚV>îgÁ ‡Tm 
„uÖ„a³•˜ó.f§Èöü2Ÿò!Lªzv2‹½375€ydb4dÊàKmp°*¼¼¢ñg†—,¢^(}/ò¿)_5ÊÖ3Û1B_ -jß£AâEıdÍ![ú{P¤+³f”Kšª[¶0m—,ƒ>ã[oDYk[­²BaœÉôŞe4Äª£n@f =\«°LléÅ÷_iq¸C^ K,D"H…‚+^(S'y>º'‘ßc'aÏËÄ6ú{>‹5tšŠ,kp]µA´‘ıd)¼¬Õ?2³«‚#\•_­hå%‘"…w3mE5ÆXT9û8«WkP”Í#ºqÀ¸‡ ÇZ«Æ_Œ´WğØ?×}ıNvıÇ‹tª
IBáèè«ÜŠŒdTælt‡H0º"ÃU_G¼Í½LªÂ$¦gª¾æoWòIôRz‰ŠÂë§=w§$90uêd¾s79€¹¢è^«„6mŒ‹Q?¤ßîRÒşÂf0‰×mÆÇ#èz|'İB>CáÅˆû´Ö÷µÊ¨Ã_=wìøÈ~mC/ ò”è§ùâJHk^ÁÄ¾Œ"hŒáúªı¤S~~…ıñVä¾…ï9C­Â"”u·G×Ô‡Éô›ğ~`úÊ„/Ğ>j8LÿG¤?èb\!""ı6Ö1é¨WĞ 7`gl®¿A–úŒ ×öj¿ßhŞ‚,^ÁoïöàéÔY±?ôË=Pœ}Ro9–bÔI^AÓw•(™ıª°
 ®ÅŒÛÒ4–À…q«Ö*`5_ª}#÷ÖŒx½÷@:jÃa~6i©¬°Õ*#4Y:¿oÔÙ„Ë†	 3æê¾øì8— ¤úB€¬²(ÎBÎg#æAà¸»Û¿L|ú†OpÏ¼­FL§r¢ADìÎ"~Ã·c§bOcØ•|QHºûÆÇD{IBÖòşLv6+nœi GÑ‹]ta;G	Ì7™l7=“}ıÒ0Ñó9±ØpMÔ‰:òb€à?$W|şSm&	³3P®ù°±eh¯{¤wàîXúóÍM×‡±7›vÖÙ8()=-—“÷ßf’™\'û“§
'Çæ2ú{´nCıÚZ1¶ìÓ€Yüçr^ğ+¥À‡ˆO|¶\ mH:¼x0!EÖ¯ìéQÉæˆËc9ÌŒp.ÆY€€³hâ6|'ğóÉ=×‘ª×uÑeU’“¸M8fõ†8ÙKûË~ƒû«|š¨blójõ’B:üöhn…ÍWb°÷,au‹J²^ÀËËCoc‹«R7Ëj°¾ºÛBˆO^ğLÁç¦~û0H­pdËÑ«w™µ{&N-kìÇ¥fhÑø=;Yå$Ü+v'J.™	—©Â?ËÙx^ˆ³{-MPuvO]÷¾³o£&1MMÄ¦ƒñ_wï@ï¼Szø›âÀì–ëpëû™îå¡ÈÀÜJH€î›Ô'C„úÃ®Ô`Ø„Œşboo.U”äÊ˜c§FmÊU=É,;l6İl"6»´5à€B·Š|v*E4$×A/Um
 õ1é}^ò¦\ªò§¢ŞÙ$ ÁMUÒ8ŒLœ)‹ /6-(õÍ*ØC1)$°cY>G¦’ØÿÛˆŒP¤ÛCiñ LÉ±ÄkLJÕ¶ƒ¸§æûPÙKpå¶¦“¦^cˆ‡WJÒ`Ù÷mÆ45‡zÏÔsõà²Ãó7¡õ¤f@/ŠŞ À{Åç<~ÿ¼;¯ÑÙäÕ¹µb‚”E£ÉCÌuA(”O´4·ïaÁëÖÄ›àHJÉ†qÎ,ï’Î¯×sC½1?{ÀY"Ï[œ"È,ŠE²(jp«¶BÌF§Bp¹ø?¦Y<u¢Tü‘ƒràM‘Ëu!wÄmôëÏ“?8\ë·äªLoNùGR JÎV³j%šİÑÆ¨#º×ÂËÜ©á-“ªt¦Î˜`)iÎ2i¼1VËèğI@™=™"VDdoBcQœx¶T“ w-z¦Ö95 à’b¦<´ÏÏtKÜô'É#äÙ;_Ôó%Qzê*YU‹ÉFyã¶¦èo¼/k˜Á°œ²FÏ*&›Ó©(˜	ç*¡÷s–šºUF$ı†“;@;QE}«ôÊ,êµÿ&vş7åÖ‡Ğèdá£‰¸İ§½Gûğ&ŠtÓÖ*ŞûÊî)`Ò»ƒhÜäšW¥üµ\znÍº£¾ø©¾ûÂ7‹Úò©÷äİ	r÷…‹ô?ÍqJÇF¶õdJóğfŸ3‰~Ùdo%UÑÚÈDÏìî¤ÿÖE’O‡{k÷Á(¤êâÏo@ë+Y:_øæbXR>™Tfˆ?@›Q{Ë05ÕÉh9‚5ú;¯©azWbÛü'ÏĞ³òÔ˜"8m~ÿ»Ã¹:@=Í,RµÙï 	LS©‹$ŠQ1}(šò ('¥ÇÆ”&ÎÕõ•œH4ÿŞEäO¹hêü0Òeü-«©Ë§õI­˜¿åÎ¶ˆñ8Ğ[°¬8D-¾õ¼'ôÂ¹¨­UY§&ƒ'ò%¬›pA‚c6"Õ¯ËCşlFÀ¯.˜Ğ(M=Ì ı˜”ĞCRÈpH©/vuf_:Tl şşÆ]GÃwİR¤şõè\;¤J,Öˆ¼¦"<¤Ü¹Ê€ünË¡B`ODÁEuôıâä€œ$V±:Ÿt^§ÿqÎÒ‘lJ÷üR7ÅŸÛì"QÄÇ÷í€m+ÏA£	n`£L66¯'¥[ÆI8B$G²N’Òê	ı÷$MÛ–(éòê]Ë¬@~ò! ”º¬?í…/ìÎ#!¬&üé"¨—ù§„*¹°ğ•Çìn/€šŒŞÅ@‘¨Ë™eKægámİ2–Wwy“ÕªB¼“­£MÜWØ1qŠòrÍCX'™n\,Á««#÷ÏGD'Âõ¿¯Z°İ§Qb¼=ÎáëNi á~Ü´JŒº,Î1wtÉT
Œ$¹B-§Ù‚Vc_Û‘ûKt?s§ŸÚK"_…˜Ôl\ÛøQò­Õá—§¦ÁA Üt)7×C4]’®î´UÕ 'İFş? ÒğO7³]*BÔEÍ·ò»’”=¥ñLæI$öÈD0"i1°`-Z3¼ÄŞoÀ¤™w«2
ÆÿŞçË›°ùhe»ä<RÃé¢•8Â¸ókó °âãvz“«µˆßˆ1¤b¬j&‘V\ç$ÅeŒ­‚A±¬%¢S²ó?¯‘ª˜Á¡ë>¥Ì«M¼K˜0ş~l¢M5éG’Uö÷»™ÉRâ	²s›{~ŸOª[ëÎSg,‚a\c“áÌŸõ®¬~SV=r×D#Gàƒ±^¦›Û¦ cdf—m4 ¹*“GÂ?h­Bó‰´ôà1ÏV+Ç€óv1Q¤t	|Ä·šW-Êx]6‰vQtò‘äFÀ£Ÿ$ûõåqØSçÎ;b²$êˆ@¡†\ë'z&Ÿœê¢ßÕL>A’û&ŠG¬ ÜĞb¶›•Tnİ­ˆ7:sñ(q¶­Éá —(ppäm»íM3	R¸óº©YÊú.ËÜw‰Ïí7ªE_eçÎçÇ•>N{/[ÿ6ë­ìª£Ã¼ş˜QA“Pé¼0ÑÙy tØ}©3€D€8˜J9Æ)*¤tûnÜh ßê·í:'[ E–»fVíª0#JÜ±ŠU×ô?®¶y9h¸»!:|9F€M67kß$>Ü|B!°ËkÈ„4 ?ÈÃR#—H4 3Îß¢ïZ!7å‹ÆØ>A•ã<šxµ´¯¶ØƒŞÙTfY~‡ğˆm×x:ŠY&3Ä$ãÉMˆµ;¯†„¨¥Û­¹vş:UŠÂÖ Ğ›½—'N‰šøN™-vµ]Œms› kh'z> m²ƒİÿ¡Ê#d^î™ÇŒ••,è‰ÔÃw#:ºànÇ0|ÇDŸ³51ò1ÔÜ5±¨Ëm°×&˜ìX€VMŞwC¦Õ#Œ2"»Nƒa
»¡úVóÓ·İúúLÔHø¶tUZîÂ>Ø-¥àµÒëÊ€æ©'O®ˆguö	¦s¨,—×=áH¤d»Û`´ßŞ	]g¿İ1r–¦m×˜pŸ’Y‚.ëÖF>=çpî¹>owá‡ÆPd»;€H°vîkU!¢¢]µZ)¶ıÂƒ‡ÖX¦/<a¶ß^—•kÍ$ñ%]²rpa«ãÛãOr,@¼K¶V#§îÂB9Ú+¨ Ş2Â<AğGÌA¹Ö¸úÂ3”|Ÿç°NŸ!İ Ü>î—€?–#Î.J± ¢iãö¬0‹psuéèàbŒM±t¾`š ğİL¤Å¢¾Ñ‚-¤¦Ğ±53ÔUÎŠb6á%',‚öX5˜¾É$·:pÀ>t“T ´0RÇôÖ–_wüç ˆŸPm`6ÃÔ,™O¡±%6=li"Q¨Ô 6@°]ÈóŞ³YÅÒæò îQE@…Ô1¢iäÒ~.“ßßìQXWşÅSÁBš	"Š)ÕV+Ÿ[V)ò²JŒÆõ7\ñÊå»¡&š8YR2šÒ	¨°köâ(à
_\ÅéÊ*¡tÊº7˜x|UIÖvQ¸ü{e*Ÿñ44¨Š O`ì3•aJ4c8`>^1ª»¦iYûh#ÄhúÅ}ÚIµŒ?ÆäCÛQÒ¥.·•	Í˜wŒ	}Ã®¼ç‡¿×Ñâö=“·p'*ôw)k´;×gsq0ÑÄé§#[‹±Õz8á«ÇL‹Áÿ]¬ÂQ%.Ëß³ğ(3w¡Š?Ùü­„Í zÙvzr¯H¯¶‰À€uÌk—¶ƒ!g¿ˆu™=à:ÀQÒ®ï	äØø9½:Å&"}AU×Áæa¦¦¯û±&_FÖyXÑG="ãTI­jŞlÇ‘·?“jŒ3Ÿ+
³òñ½ôËho^‹G¶cz¼ËÊ†M·ZZ) ;& ´i|ƒlÕf`
æ‰/îs6{ó‰‰}’ ÷£}ğè$Ú¼51ò>Oö…lG÷@<mÚnp¦¼ëõvéØÌCÆùçœêN«Åi	xÏ…ÌFIt³š]FF%¥øÙ¨[¦E—ğØÊÑxè’Ì?84òh¿/ë|W·[tŠq‹b†„çQß™µÊD`óq"XŒ½í©¶¤×èÃŒ'§BG½S{ßEc¢Dõâ§‰’j˜Wáš‚8ò^îº§Û£z ˜íÒ‡½vÙ¦Ï¦M—ÃîstuìU¥Ì¹‡Ú}½lúVlÃ$oY‰;¶›}¼‚å|ÈÙ\³~ìsÃPãàzá™607kĞ;DRä÷{I0õµ1‚J¸5ãïÆßÖëQåÓ«—uÏY+“†¥£úğál
ßMË\êaáH£¤gÎ`Ò©?ä#+Á©°[s>.iÇ×.ÖŠØŞ7å,j$\Óéå˜€ƒÓ:	øğŞØ«ŠxÌ*N÷ïÇ†ˆ(‘öæCã®KşêÕé.0é÷‰Á™EÃÏÉ)“µ@ã'9Löü£û:ƒL(w£”1a*¬ØAûHm)ù	r<şoÃ'Â°çüiÖûSÑŒâ3„ÈL¬'¾ué¨íë;örÙ¦G§Íş“©5m“Ğw*?Ü$Úé…Z9µ¤´‚›í¸p<¹x…äŠn-}B
ã®ÉTäì;ñ¨|›¶”ö°%8 WĞS ¼
8DV¯‹òµ—0ÛGœ)ËÎ
%¯acR9&¶\{H¡BÏk—“cû4ã’a¤BZİËµ{3#…šÿœÛŸÔ‚+?iÎä¤V›²äSìé\‹Ë×5Ó¬pÓ7mÑt•c?èZ²?=aFgìİ¡wATçl%_Ô¨<Æ&¾æÃOí›°d&¬[ò”rÔÜÜÆÇY9öYŠªĞW;—·ódwO2‚.ŸˆîVş÷{û.t©°¶şÑz:™åùN…¦ç]£ÖEƒªíÁéîĞóEÉ>³šÀTË¥±„Tj^šdKÚ{CÂÚgƒ/uDÚ1Ú³¯ÆX¦–ÉåHW“!Ú·G§éƒíûiÒ9ï)ŸƒWnpøò^‡”
ÏH>ÀÇby]E5 8eÿÔ{Óüf1,,P-wMÈxLbÕ:Ö½³:[)ÄˆfSæ …í&Éø¯ÿ«ÍÙ£”‘R¢=9İ››7ÓØ®ëÖ†<ÿ£‡(å‰úÙâzÒ¸ßÈeü‰´´Ğõ@4?¢ôó?œy÷u+Ä§ÀˆÛKøaÛG=—pÊlş lëgàÍçb%šÕ[¡àÃŒN6)¯Fæt’ò1¹²ÆÛ‚K”)†eMİùƒ?á;üQé.¹6+ÈpšSèÀ ÷‘Õ%Ñ>–¹º¼!5®#t	Í¿KÜİcï…Üæ¶Â&×.,ú€/$v6IêH¶Ì\¯UÏ²)Ô_{É(œƒIŒ’ìÄò'Ã<ÇƒY4H'™İ*oú
BEõƒaELy6 ÛfĞR`î»XHD-™ëie Ä3Õš4-ÏıÕÔ{X§œUNPkìĞ’n3ñ=8PL	@Nï†Ô­ÓSš,™SCÑ‚NÅ+ ×Òœz%s‰ŞIÈlØş
WlT5½‰DÅ5’jS¿Øíi&ŒíÌÏO¦µMÀnôwß£ÅÔŠ«	¿µìÄXå­9¤Ëàw°¶‡@0V¡Ëÿ­\ô¬&s iÆ®·óƒDV‚ñ<y™sŒcûGÒ¦²Êp}-áò]#‚r§Òo4ø49¥¶~ÌÆ´,:Äö‡Oèoü;b…RùÈ¬Ÿcçz…A§11Ğ86¼ŒÖ-·zZ±_‡^P–¸JAQöYV#İFMüÛâàƒÖ´H6I©ã¿Ü@í¤¸ug·9Ù5v»¥	©óY.àL~^@€ü‡¥Ob±|Í/aÒd'y&»ı¼»"ÈÉ2ÿ%VAü –ºÌÉÅ®]Â¤eÊÌ©±ûéX¦ûßµrJú÷bšSgb;ÑáÄ cı‘—i;¤İlë3\Ç;é"TV`#X£S(²;H¤…à'Jƒç`7çWÚ&J0I‘ m!vHÉ3ŸâŸO ~mn$OT
jöß1:U{›Ë¤Ë·ò Ó„Ö¶y
%´D®ªİ?´fnÈ}ŠôYüü7ş7‡3acníşúë«\–ˆ‹=ú*”Î&AˆÊ­Úje÷Bf¾L‚–’‹UböY½5Ÿãÿzüäh-
æPmtUÁì®öëŠè3ã'$×„ô2IÚ@‚0÷RË=‚‡^£Ûc2À…±~_’Õ´F!ƒ%¯NÑ?kç4¸„,¶$±8àÖCZ*ˆãÔš1²ˆgİ›0öQ1m¸÷·Ç¬¿ŸQ·Ò”İŒId=üÅ(
vp¿åÆäéßZØ9µÆQ7÷,¼9á¥Y,¬Ü×Š Rä7$úÓ-¢Îq
úÁB?àVA\	ŞÁ;ë7ºi¹Àêİp,Ìù2üÔy¯Ğ:ÖÕE«oãÏbØ!­âÕÈ‡²£¼çfL¨W4ßgCq´kÄÿ¯[ü‰y÷²Y¨¿Á`˜~æu:¿×-8ô¥«hé+Ey”¶KgşÜV"™Ï˜ÂKÇ•nšQ»ÂPw»I=#•¯~ƒÇMãlàÉ5i3”¥~X×Ò(ó„  {k›Ô)>Hgé}B”Ş~Ã0 +äœöÆJ‚O^\f×Š}#y¥Ë|Ge ØºR˜ìº‘:2 NgS°	0§Ğ™ev«Õs{'QTÓ„"X?äƒ°û¼†Hd¤áõveàÙUªZÄXÀjuróˆİEP°Y5crPO‹0ÃĞ*š0Ÿò4m…øæÌq#…°5\ËĞpó<½ë÷[y€Î¦é;…îx2şxQ ó^Ÿ³[H»ÁY`ÆúE,(ò	)DŞbåAd &T³æ7§‡÷ï´wåğ3»” W÷(c§âÓÛÇ ZÛ¤£”–G=º-ûYJ¸ÏšµdüÏºrç~…İ`½Ù‹ÏD‰9¨ ƒ_` níFêW âûwÄÛ[yµ‰„Ê¿ò¹Ø*ém…‡‹q÷ö'£í
Ğ` WÙ#š9i|ºa:¡tšn— n¸Í‹ü¾ö~¸_Õ¼Ù ùC#RşÈgo6(4èùÀİ6r7ÿ›®é¶­Ï˜ èmwîN]³ä¨X\:HyÁÀò õJ(G7l f—ô‚£×êŸƒ9#™Whøow‹’ÚHS¼ßbÄ`“:ì¥Swrf^üb•Ş¡·‚
œ,ı¢{>Ó¸¤t£I`ô}a·ñúKm$Şmc²Æ~ƒØ­9÷ïöNb'Štş[§÷€klbRıfo¯;pÙ,fò®Û¿xë3‘ÆM‰m«)á÷qìeD[¨A†‘=Ë´‚'‡®MÈİŒ”B¯@î­ı÷É®U~½a–‹Eğ÷ãç"Ã¾¬¥şüºÜZvßR—Û–{²`Ihz»¥'¨ïÈ@°x{¢€>G%°w¶R¢¦½ê/U¶Í£åeÏ$/5¸Èã‰+J#]"QÙ¥Ø>Q°Z°Éy-œÊõ}˜ÆK’³èÂÔpÖÖ¿.	WĞ´‰Iqï00ÌqI6 °î§l
‰¸¸vi‚á­†›¹¢ùäYt	ÅÃSºñ®ÖF4DK,uÔEôñÿ £ŠZ*ÜCõ@:WHGèçŠİÁ*‡ß »{]¿HøÙ©Oßè<oRÂhŠ8Ì)Pp9Gmõ*/µ{}”„)‚gC¸Î’ÉË,I{ƒW;Ä£ÔK1mş\.Ïî ŸÕk·}@—¿ç	¨¾tx)eÀ4N¬ÉÉx¾²ññÈÙÆ‘à'=¤É¿´$8¸éü\¹qÚñü1°šY·‡ß@é8ˆÚÍ>­´(1|¢6}Ÿ[5¬ÍúeFô¶Õ²l0PÂÔşõ†àZ|–ÉL²é«9—k&@™®'*õu9éu¢äa &qğõ£-2ßAËY·
jø(±f‘~ÙW§¾‘ôû›«.©¨Á%h¡,Ò‘˜¶”Áêíó¶‚ñêõ£$ğƒû,ê¢–JË #cvàºëdıC?r0 ‹‹:÷ÑC¼^ï¼ø§ ’QĞq%‡“†
½ÄÇg3\-¼)ó†{˜¼Iíû0ù—á™ÕÊt‰•Ÿ€>8Pé{«FC½¡OZå
éz)=*i…–ĞÒô‡¨90äWÉ&{tÖUh¸è}Êu5;;ß|d›.eíy­Ş™…Ş¹ÿ{ñwdğ¶#R½cşİ%	Ñ©xOÖR}…%l£æÑ„¿l—İøBa»X*È“†[¡P¤D7¥hD«80S4:ıQ¯À‰ïUOf$ECÛëiÃ0]é7./²ÛÚñUèÆ±0 K-IÃF…‰ú\§[®–µçşf0kûod86€¢¹Ë»c=/ÅV¸å|N0B8Á[5ös½g2_È—ËX»RÙ!˜\Îñx@¬æã¼¿u±.á–bFQ¸Âd/ĞšC¯0ìÔ¾Cğ]õ~"<ìVp‹«÷´®Utç•´ZşâñÂëE@ö:m(ö`¢úÓvSx‘Ö$ó”GÜmÓêÅ¨Òx~Uÿ˜„°Å­CC“§ÓÃæè± @Å"Ë¹¯
3a’Í¥’+²Œ¤3¸œì=h®¹ÔK…W	|½åRšŸ¶ë­îEÏ¥îáz-PR<0ñ†ËÎNÓŒ u?­.°¿Ó„cså©,(wƒYKYÈ/~ê¶:£ÃÊÇºšt×ßúŒ40É±¿a·JÃÏÕb~î#¡Uo¥ºÙĞ‰DÚ{ºCñÏÌ5nÙ\Oß8fìDô5}Ÿ¢\çÄÔMrGh^3¶fPû¡…ûì&]„Ú,Õ(ªÂw½Àß$.¼C6LäXõ‘‰êÙN™›İTG”k£„Vjî•ŸuEì€âå¦'E¼=
8œj]—k1çÍZüÙ„);ªˆÉm¾¯s˜öÌQƒ9·äÑƒo‘éÜWgš¼iîš˜p«¨aZk’ù×~“¹?q>½Lè‡ì@}2{y^}NÖê û~êdĞ	OaÂQó´]õãÙc¥ªmg7Ä®Aşî’Yaûg„{Å®½^™ßÅ«)(CÎÈñçf2üeJÔëÃ1ş‚«€ş¦?òE˜?‘kòÙ™ïï7f_ö‚.´ñÀÅéÑiµMq+|`’ş¤DKsv1#p€×2m—”ŸÔ4÷—õá f¢O+ÕY ƒRCÿRi¾ı®qÏ²Mù UÅªbü~wÊOìAtˆ×z$›Ë(óKY&2j_ëáÏ3¿`Ah•«b¦V%Y±ÕE	WŒ¤RüùD*Ÿ3B²Õ°Ì7·şµRÈ‰}¥5&Æ•Lè[i‘ƒÓµU%rEÇ@Á¦;™ö»{AP7E‡´>ª—ysÛØÖYŞd“	Ü¦Ğ±†M/¶xû,ìi$q2Ôó9ŒDÇ(0ê9·œm3øi‡¿ÁmÖlÕ|(çÅ†ğXˆ5™H+Ñ¦<I§nóöÒâìJD ß0³U©Ày23IyÖ'Ğ½ÕÔ¯˜/ò©j‡öïÅY‘vöX^b—ÒÅ=Úá0¼Z9²÷y‚ª1‘aÖØT“f*öÎ0ñu¶dX{„ò óYI^l] ›Ê‘ÌôUÇ*:Rİlö1ašZI«HnU¶²˜œÿ˜º–hÎ¡ñ7ÇÒÏÎñy=]é7'× M.¾vp¤B5…#¤Sòèó8ãÈŠAhú{jDªãí¡!® 1;Lò¾F¬³wFØ±çğœh¯lA¿itpäÆ®¬JİMığ¡#¾®ûã-[û®ÇÕ2€×‡òYN}wRå|‚kdx·XzÎñèãIv	ŠÛ¬Â¯8{iÕæ¿²—`•üÒ¾aw/Â’ÓCV–ì`BhëIi	´ihÚyìte%èVœäâi8Oê…}IÜ£ÉËOëXÀaÊxš°¢`Ÿ$›'sƒnn„„IºW$Ä‰(@úùtÿôÏ¯³Ş¹û¼é®ä%x¤¦ß#{çœÆ÷ã­³°™ã#˜Ãù«æÁİÌøIµ–»öµÉßÁ°t¸O&Îügw`z@ŒnŒgfÂàHçÍğ‰K¼Xã€`G™´&·¼¹×#uW‡ìJ<óĞ0ÏÆ9ê¤ÄÖ‘u;şãN‰,-ŞB“İjÎv¯‡¹õûŞéæ%—_¥\)"nzWG‚3ÏŞ¡•Ê¥¢Sc\Ì´\»“ÔşGG•WØfŒƒ¯İ£yd— ´3”"Ëú©Gs¢wQ1Ö`2Ò*ËŒ©ÌgÆÔM8oÃd÷U#‘ïßÑ8ª6|çÍÇûÁEÃÌ»<1õ9åf5µF²0…ª¢Ô{ïèe—…‹Öv’¹c†òø9“èxÁ^Å•äáö²ƒÍEğMe¢Eu78®‡›ÇxD±umVıŒB»$h}İ•{U_‚èÁy^sœ^E¥®2DL0mÜ‡ù`ìÈ–Ø}	×vşDášï^æÈéÑÚçÆiùvHœCÙ?¨å¢ }†	aôÄ:¯ĞF¶åToÑ
\R2î>p7şŒ\Z¶s(mˆ¦2gJ fj¸ü‘? ş.eòšxná,'âP\Ÿ¸±cEîØZ1İ`~U?š\X¶/cg}šÊ‡A]$¤eDìÉ:ºùRà1ÇIœ7ƒbƒLO]sa3Œéä1#”ßIìeƒŞªÉıÓ¼:fe¨Íî]!Ó™±}ı²ı¦=õâ¨Bˆq{ÖÊòòÍµe ØæpóÖ˜ÀuÓ®ZÄ¢Z#ëò«ŞÉ½†²iÔ„cÒ Ø³!,×ZÃç[	„-·BÀÙ‡‰C} ëo±É¯V;GÃ}Í
üŒŠã¹Œ|»ÇŸ'–îè¡–Ìë›MEÅBùQX+R3şeşñŠãx$ÊTsõïl+’ÌQuw¶[Q:¥¬,HºõaøN¬ÒˆOCß$„ôå(à%0À×ùš¿—}R S «Ü¹Š åó%]E}‘o:Ì‹â‚‚n·¥D0¾P}¿ –Ñ¦¼4©«Ø0Xåå~é8\[	ìŸÙ3eüÖÎ¼Xq¢‰ÜDÂ=±ğ_CAö+¯2¬G™.økLœKãçÎË;ïC;l) QTH‘ù:5.J‰»wû—yo˜ó–UƒE•5fSsHÕ¡
è¾ª,OÁ OO"0½´37:n%¤—y4Øš‰Ÿ¸²òÀÃU§CöN¡.&›suÛ¦QSzTÏ}§I¤ØÜ*C„ØÔ*v,q„y›’RñĞŠ;¦’Mi°	ÿS8=N+ê,tVFHø@ÔtÅ½Á;?€ğÆ½«î;“{ä’×$íxY¦òĞéd(*Úmèª2j1V´–5¬Áè¦57ÚÀ¸%©ryó[püGôÁ$É~Éo²Í2Ê6&ÌHşÚ– ÿ'xßÌÌá7Õh¨òy-s“ —vîç¸¶itò!k|Ä
/°N|¥²Ua"Ñø¶m	{¡|'P¦ó¤Ö|1·rpêÉ¥Õ‰“Í„Za#]Š¤‰Ÿ-PyÜqmäPÄ5<¹®6,•:½ÖOò*§©e·äQ…¿dFÏ›»“ø“Ó”17‚Bf½ù|¸ÔûÂÑNˆ8ŒñÀ€ïNÅ¿åJ”»qSVçu‰(;~6éÙL|»Â2*EãiÁIy5EÄğ¢÷Æï:X°=Øú]v‘8=¥œj™šäìjjÛ®NzÜğm]kÊÉ U}|oÇ•l„Ã{ä8'Å5~şd5èrÿŒŞ@cå˜˜><×ˆ„¥ùAdõÖh·[1«8UÍâ3¨l=WYáƒÑ£Ğ(ÃÏƒ  ¨¨tÀ%D:`Bê²¸ÎI?xÓı$TZñ¦½ç ê5‰ùG\Ğx® ¾Ñ¡¾ø«ğÀÇ~HÓhÌ…	u”Zl5+^â¤ÅÉÌÍx–Ç6+¬	A¢|ñ*=EASåZn›p?Óq¿šm0®*+!î½¹G¸Ì¹ÕĞt’Kh’˜æĞ:Sñv$Íg|~ÁM9 "‹r€çäd˜'¼À},í>Ôƒa¼‚SÙ§šÒé ©³ƒêa”MÀ¡CÃù¨q&FbL²½"¼	M™ÜØC½‡üIŒI³t¯ T|–.
ìcÊ’ÂÈÆ¶ù}s´ˆ×fvã§Ğe˜ã6ãñúà,PøSO/‡¼$Şà:¢½)ÿ„µß%+NVt/È·7ğ ó‹” wÜœÇ„^Èª]/…o%Vašâ rM¬:“r¨ú"­Y~j‰&ÃÎHbñDÂmÉÚCG´SÇ}İŠ#¤mÒ1S4xĞ‰|¶Nrö²–xÈªÙòĞ ç©uL[ºõ`líúÊ9÷}¹…Ïeé7’F‚ˆ¨È@ Ÿ,CJÈƒˆÀÔ%óy’È–wq×JõZÑ	Ú£+ù®c#+¯yHVÎÍLÒ DÎe
İNÄFü˜››±*NM*‘qMhhÉ×®ÀnóL æ%•Ô™R²k”­—5ükš-È`éË!=D"Ë!RŸHQû>Ùô#ÁKãq)Nu³Ípv>åäŠWA¿¨x0Jå´Ú#É¿Zw‚mD•~ç¬Ò$¹në·»¿¯qkIkÚ‘·’È@1óéEp×´ìpfv9tİ¢[ÀßF<µ{½ğ¿¯É‘JO¥YKàŠ\#åv$°¡+
JŠòÃ%ç¡Ê{i²Â;§´¤Ãq¸®º ¬Ôf¹æ>‹ó¿.W*qt¶š¾	%³^RùÛøBÿ}â÷2*»® v(úäÎsÈOH•Id¬ö	ì´7%÷FO«RZI; ˜Î‚#tÏö‡f‘İol—³.»a¡HW„q 
[şBT‰*ø%‡öCöOM•é,‚$R/€É»¥½ãïë’s0ßƒÄÁQ•—1êO8zOB€Ÿ±L’z{sù&[¸à<Z·mğDJ÷ûOÀæËRÏå¬Ó“ZÂ–?8³Rg†§ç+o~Ğ•ofÿÎDN¶wÊ¹ nşÏ[ˆ†z[çgš[ÑÀ³Øn/E",#ÈKÚj-ˆK…å;¯¨T¢50ÉÔBÒC…Å@X:Rˆ*/WN‡ŸĞŸÈÁ•W@0İ€çkz<ú;=YOádOÏÏİ0¢(şÛ.Ÿİïš´xj½ßº©yWPşZ¿I"Jšbóú²<K}²6]¿§– )&¨ñ—ƒÎI¦ÍİØöNF6$Y?¿VÑ“{KtÎ]Ñö¶ß¯KÀ*‘Î¡/„ĞoÁ
¾wë¹õ¶ıNF&]?ä­ì~G‚½›°/´ísÅ8Ì=É<m‚¹0­pé’ \:7Â“—à»t€ÛlIWC¼;Û×ÖÜu¬õä‡òjhèô#(}¢—îc›ğ¡(ÆFë0wë*š†7×WuY*R’5Ôº‰ßGNdx‹ó›3ÂLdçäì3£~R¥˜@Æ'§Åª!U‹–À€hºs˜CÓ<µTµ ƒ.Y¯¾ú¬xªƒÅUc0eezIKR{‡%Ÿ.²Â«/½:+Qb¹\ş®{ïDÆê%@?Ûå3b•óR+Ô¶á”…¤àÕH›ªkfôóÑä·;r!ğC çî­àYû¢É§˜HÏ{QÅRP5´@—Ày[)BuZ-¨‘˜_­D?Àgy³ç(qóDšeÒaÛGJ¸I†©ÏÒ,ØY
Bê¶ŞÊ¯.ÏBØT~eÑÙùFõš®FÉĞe§Ë¤ş:Có&!™‘PË—,äƒvÙÖ2×<…¹ã2•ïaXà•üºÕçRzÕW¶ZçIñ‚ùî-R5 ÇrÕŞb~Ãl'˜Õ.É­´Lç£ıAå¦'oÓî9×%=‰¿4§´#ÙÕU?(Æ˜6FÙÎ`Ÿ“,ŠCì‰vR2
k­‘’¼¡›b$šsô<"çë±3üÈŠ˜²[Pª¿n\q_Èÿóş¯'Î:cv¨4Æ?’ÕD¾ïJ¹ù<Ğ ¥˜³•oíŠ’3Éá2ûî>œ.ªÿÿ*¤npMÚ›ÛfÒ$2Xâ£¹s°¬U2WŠp–UV;ÂKõàËZeı6=ì«5Îu-‚]y+pü
duµ‡|Y}PKÿGĞôº<	:”2Á7É…+@P8KÏ%A|ŒšÁû“¼}û¨•Bıq'¯È±µRèStŠ:2¶ü=AŞ[“8kYĞ_Püä¼aÓ£tgj‹H%ŞWOT€d2Ö Şğ×$\Ba›¦‰í´®B ²{…´²¡ ğˆ†Â…Q7ÚXj8 wßïWW/\0¼Kv'¦ ^´{fÛ—é¡Ä¯Ï½r·”Ğ^ı“•8/@ëŒ€7)S°j'P7j'-™™Õm(æh„ÛÇç9D®û³Ás0ßPÜ˜Æ£LzòJwH8êZÒ·ä.¾3B’äRºÎúğFoøü?7Lùâëã>ª›©“iU”]±qÍT¨¸bs¬Tf ÏgP>²Oœ}Ãïæ=2¾°–2ãm…æÕDMr¥à#1¼;úìİwåG ].Ïrãk^½9öªíü½±òN'nÀqOh†ş q`€Q¯{áŒÌ¬¶™Ëù"MdÖ‹Â×=™ì¯¦”@Ê§ÇàÅ-¬,/â÷Àª¾¬¾öK‰€qúİ#ÖÂàJÒPn¡J›Ÿyv›rgÂjVGÊòn>Z,ORDmêOŠI&Ó¹9VÀ‘GüW˜ZéDÃñ×QKT…ßÅØü—\Ûù¿„ïvªÏ&¾à.¨W=¦õ<¶ærWĞ	mˆAÍÇ…^¯GM0¼ÙQ E.dÏÆ¢úïãAÒt iÛœKÉ
¯ÿ¡ÊĞc…Ÿ~¬rééüT·«
áğNX8Ğ¶oÊy—`ˆ.F„ÿ”ÚÌ‡••·½•”‘Y€¿AUn]\ÓŠdcÜP´ºÃ¹bvSéh2"àH­¹Xøÿ‘µ¢5f¥Ó-cÀ8ëõ?®˜şßJ‚û“é¬á£ ¸®£7éñß$8ñ1dŠÿ^.ù(	ŸÜåK¹2»b“
1W\î¤ Äwg¡^N900Ó¥œzr¨8C8uBlnT\écÙƒ^¸îG«b­7\ìÿäùùá6âY*&¦äj™R9ubU;<&{@?ÊZF§d]"µØé ä.~—+¸Wfm4kF)}e?eµ0öul=Ï™Çcv) ”QõJ\KÑA„cjËEÒ¨dŒŠZ_£p æ“ü’Í&$‰s|;[úIzÁ†eû¾¾6wƒ ÊN?Råõûå<yeæZsˆ‚°(½è£UMxó—XSùt 46«,šÌ–˜zÓ£¾´ï|ˆ¸!İÃ[3GÂwhŞ…ú©‘.`Ö4?‰v:O: µû}c3•CÜŸ.^‚‚‡EdC·;W<VY0rz¡Z,Ä‘æ¬Ì×U&6%R”Q>ºYøÃL¢2®ïÊÑVQV°«?€¬³Äf÷I¶Î[b7°HÃ á#¶XµÕ¬×=äÂ‰|OÖ„£T^O œè(i,$mıÜ+ï‹J¤ºHå‰ó‹Ë®r±z+m{°Ãõ1x‡$‘KÂíÅK2‹{@' Æ]S‘Nß›®é~!¤ægœ©nh–"´Xş‹€©œÀ¾ĞÅ”äGAlõ×‰=Öˆ®¸»EÆµv•v>o¨ˆ×íÄJ?ÁÏDó_e	¾›9ìl#¾¦sºÆ¾)™¼‰¦kÅZ'ç  ¢!9I|ğoŞjØbˆŠ#…0ñ-õÒ‘ÇûwSûK}]ª
mşÂR($3’‚ô`¡l]ï§ëÎ¹ëé»bnë˜pG#ö6uøQ4Û–¹ªRÒŠ¶_1.Ì~•~P~êã'§:ÕìÁM½è¯SU¨~vrVºAş°¥w9¬\b2º°cÊHLŠæÑ–„²—ƒS$V&¨³æ€VƒÆn];‰Ä{0ÄŠH„Ô
yÎ[¶Š}¢îãRcJ¹ŒF·Œ (óløt`•²=ÖÖ¯Ã²(€ïå™å%Sf?F'\KÃftì˜8Îôz"6İE6ÑãÎuTÊQZ8·–¿TÕ¤ßhdiËMzH[”n¦‹1HœÁ¢'î›Ô`Õmé†N¼Ni´ˆw‰Ê¨o‘TuV}!Bì‰ÃÌíêÁ-«3pI5;·å7–ö«!ö“*™ƒè:Ë—24Í¤­ùıÈâC"D.'P[
?`¨ûêÛ†}N(5wgEõdJ©u€öjS€Â"‹Œ†ôŠºb¯ ;IIaûÌD2ãİ“ê Q"‰74q‡pş¯Ä¤p¾İ\Z£ÆMå‰Ò×¨ñ„½A²vñQ‘H‰3¼øÃ“óÃÉÍWWœt¹&R-xÛ…Ëi”ªMí™[i›šPUQ1°atFHTQT¹·wW™VŸª›ïÍo¿«Ü\¶˜:.$óO  n–1qŒ\Âådæ_»Ï!Ã‚93›¡óËuJ„É‡Èõ¼N8wÎëaä*›âpÓø,ìXÃqf×äJ”ı@V ¿şá%[±&*aîá
ßswá‰×®„mRrVÑ‘ñ`òXÓß¥Œ€£šXpq ‹w²he«¨Ştı¸-çÆïÅŒ‘t	^CÄ9 ˜fG±e»æA‘Íúm.+åÀç]ÁÆå2)5jO'ŠzoZù9* S¿U†¡0 ñ¦è6•ı±ÙõŠÁIåõ÷à*‚U±³`Û 
ğ½_öï—¨'NÙÊU0òD¼$~¸¹`bÜìÔŞUæ«ãú8§şÔÅLĞ7vÊáäĞ'Û`\Hµ	ô8Ş¦‹X|;uFêÒß†û{Böì¼Åå¡1àW‹zIÙZ´ :jäŒĞå¨÷šÚ«¡?AğÍBÍòÀ“ÃŠ…¤§eº7ğ2¸ÉÚ¢m‘Øaù¦Ç;ğ¯ lÒS+ã§¬8>°;¤)¹#·mÂMí6“	÷>Å+C¿f„ã`Í™…»€ÄUƒ@ŸÊoê6n· ÷¹™wyX¶ªGLÁ¯´à>Qãë9a¸¬qü±5t÷ÊğûGÑ0æåÀ…iÜEìV†ÒRŸ•ºGŞõYí)M"…ò;?nÍXåé·ĞåLQ`fXİÕ¹¸v~JDıqÈCÊSÄ<Ùd8.Ëš‚¸µûÄÈ†sË¥K·Ëı á£D5ı LóŞxuë¢UK3P¥hÉÌ|ô±!?b¤èI‰:ÁÑ`¡Ó’é±Ë¯Rñ/2höV]¤º»v¬Á‰Äh\D­Ø«}a=Ç,ÍÎwàÖSÊÅ"²Í|ª”ÄkÇ("aÍŠUêÈA¡`R.èuóƒL‚rñ·maÔ`¯çÉ>eÙeòTÑóÅ¶;F³E¡•Ğ²î”nŞØæí¨8§¹N)öx^¡jzŒ‘ØÖÀmŸ1€CæÖ3Õ%#VªãÀı×@©vÉiAÊ·p’ÕxšÛ¼ÔF&¬;GwHB7×¼›’³a¬¢hÅ!Yî¯’ŞK•…i¬áYR	§«/Ö©<qkßqrÈx§øF_r“ÖéæcŞÜnô!n¿úËEæY<ZÇñwWÒH˜¾B~s(Ù©’~¯¿ø&˜ø}uŠ3>Û-QåÄşÉ>ıĞ¬ªH'nÔ?bƒ¾yğùVÀÁ>!ÙĞ† ]6jW¦Y_ÒÙhGDC„À«ï] f°'ƒ›ygT®g[QKAÛU©=9¡m”Ï)v±GŠ‘wpŒ§ÿ?ì
Ûİ°TûKŠç`Ç’4TæƒØ¬çº¤´%$Ç[¨K_€±ûšx;²÷‚ƒ°'à¨ï[Ç7€¬“o›Ä¿ó®¨Yh¤r{‰¨T<,hßÑ×ÖtJş	Q$ĞâuÎ‡(Æ‚ü8ê\ÇhÉ#bUÜó?ú×!Î«¶{/w y9Ã‡	tá'æeï¿ºöÍPËê?|W1OEI6ùJ0åU ›’ˆ§N™ùQ>šÒx‡RiÛßÎÈğa$êô¡ÆáÑÁ™——›w³³»æ,âÿ¹K5;¡ƒ$í;“ÓÀÍ±iFìAH)ĞæWÂåÁ‘àhÊÜŠLÕÚn7z)š…ĞŸª¬µóİ:¤9z¼İãÒZÇ3i­ùÔ°bu71?¹lx2'}«–E!¯¨·Lz¯G²=´¾ã¬¾²å+­17­]Û63¾òIyßÆÁÓNO'=Tà\„—ŸÓue»«é•]î’çt“ş2#uœ"ÀšÅó«ê°`S*g§È®»„T®¨ès°ÉŞû[2
ŒâVª1â¢“aÇ–qwìï\ÜT°lİ(Ô‡\ÊÖŸwm?I5WeçDxNaÜyû¨Íl.GEQÙ³ò[Íµğô‡`'¯~²tRn•:>èa#6{°ì|VrÛ¹kªàk·›Á¨#tJ|eaı{hë×)pşÂ7<§¡¿›9[cIR¬bGÃ‰ğI/iÁ¥œ„¤sxa6ÃzK3¾$Øy•˜œt~LF&Wx›šNÓ ¡„7Z‘´`Æ¶ñÈİ½ˆQ*Ç×—å¸ÁŞü@	‹CK£#À‰‘tZ’çNûåDên_¿µ^z>xœ2[_ú€³mo¢	Q¦ öäk­,r"ÕÏ‘è%c¿ßÈ`€½ŠÆ;ÕÌU++½Şù!—õXÕ™õX°8ÚVèÓQFC±˜9u†mÊô;Ù’†_!öJ4\²F¨©/ÑŠ\¬(!`Ññ7gİ1¦Âz³ğ-ğÕ dÄUá<ã•G-çã9¬¨Ñû¦üŞ$éŒ]–d‘6-]»|“Ãƒ¸vƒ;+àŞlk×éáw(<¦ºß,áR…ùIïû%@IaëÀ,TûÕl@`‡ÖPkÛÀˆ´UÔ»hÄÒ-5G¸=Tä	X¹²_¼-&FPG}Å¤÷§§eê,* A-qi*ƒ‚Éà%9_7Û<`Ø…~;~|ÿL­ülÛ8µ‰ß.$ıÀÄwî5[÷“0"™fšÉœ•raˆ"í‡¯ )y™7Î¢üU>€ëT¡Uto®\(RS>ÆĞˆ“]	©HŠVÿDØ
‚K?Ù	òb9\LŸÚhµ›¦ê®Ø}É‹úÂwWÂZÁ£¯KåÔ1;ŠõØÙ'?5pCÌ*1˜ôÓ‹ş‡#µ“W§3Æúû©Ü¤!c!`Näm*tÉË¸Móö1g{$Z~;²¤æéJ×1?.µâRMxjÎ*7_†âïH!YYèÔjº°c0e¿Ô$ÛT?ok …]Šf,e03úó¤Ó¯oŸ“\-§qÙß~g9ì|láèÍØ¯ä)šÈ1ˆJÎ„ˆÈfarkÅ‰Y¹hm…D(*}Ljm‘¹fÇ‹cÏ±Y#¼ÏÓomµÔ¬bÓrGjC9ñ1X‹#,ÏôÚ6`\½„º]ÄÕ$D>ÿKzã5S6¸äš—,³_U¯–c0\8Xq¿04½ +ôš„†z šƒå|9q¨ªçNCõšM[%0HİÆ¿ìdÜñ¨ŒgÁÉ‰hĞ†qØ Š<ì³yx…dïÿ·‰š¤á`ıN×öğHJSOB¦`üÓB—>aôÆİ¦6=EoV$ö-òMHbş½ı£üP³&&”ªÆÊ^`tT‹½áØÎÕdÁ€r>@2O+é±GĞ>ú“,Én:„¡iCòš‡j€Ÿ@„K`aØ`XpGÇ³k,2—Ğ3¿bõÜIª`}©œ?±åñ~©yŒşvfÈkY+DVHĞFÿä!Çá/Û ¡‘†ES8Š°Úú ”ÚW
ZR¡½¬FKõÙÁk{4ùgî™Th»Z:€#Æv×¤pÃ3V„É¥Ÿè^ÑA^“bCf@)Å8Şœúùå™W§‘.DNƒ¡ü¨8âu(OÑ…jÑY5„aŞÙ³˜¯´´4õ6nlZmXyZ=L«´Œâ…„_&?f.Íà„³èÆ¿mEÊ$TˆBŞ%ã3l…|ñÏœœ„º—¢¬·ªøL=[¤åc$Ií³<ŸD;:”j6üÓ€U†,n£E·YMù “îsúAR÷‘4aø   4ÊSE™>u Ÿ²€ğR4á±Ägû    YZ