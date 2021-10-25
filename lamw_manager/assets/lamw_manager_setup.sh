#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3370265660"
MD5="9ace486c0c77890791752db0a0f0609f"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24092"
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
	echo Date of packaging: Mon Oct 25 20:55:49 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]Ú] ¼}•À1Dd]‡Á›PætİDõ¿RÛÛ*lÇ»Ğ6§;ídWõAÉÕÈ9o7ÉÉØ*ÕàI(IáûfÇ¸ã§ıÄ@ÍU]½ÈH‘ã!òøÓ¤bQşÅÒM.BR;5ö²Òı8£k9EOpßÒçAŸ¦˜ñÅNûéÕ‘ÌY­Ç>âXŞŸŒÍ@Š»%+ò±Õ1¦någ•œùB8“åoöu7÷¥Ô
É‚M¬,Inø“;½óÛO=R7§ú5İ'm·Kúà¬]èç8ÇXpÎ”…§ò‘Ê½JnœÙwº‰HmØèÍLË|3„/Î|’ï¾N×f!cÿ¤ÂèÛÍ'üi‘ÓôÿšIÍ;‚†e5
b“²…Q*ÊLeBÉ#ÇdõhEçÆ—Ø¤tJ¢º¿”¾ø—5ö;&Tæ[¦fÒñàOE8éŒ‹S»eòD<åõµİ\."inùpï¢¤ÜOÂıøKª³İ=ë3â¨Ã1¥iÕ['^P5Gğh¥6–M¶›¡Ttó¶¯U-RV¥ÏÀ³oAOxÔA½m=\-¼>î R"Ğ/3½F
 İ³àC48Ÿ¦õ$:³œšã
¦ıçN
ÊÚ<0ËØ+t6•j£Ì"ç6C)†–o—ô@F¥³Ù›@úúP¸¢bcß‰Ä—ú²u ²6ÛHtk’©H»á«¢:ú{*æ#Ãö¼»øN»®™mC€Ëéìw!á9éKÒ÷Ì¯
:×í4CŠ¯ï>ö?&JzòÙíHõ€6MûòÒÏ'£ºšÔ<j6êF5RÕ¿¦4(£
yëë’/½D:¶ìè#©hĞqÑ¥¾ÓÜiáXœÿ«ıRÒĞßb¨Kíì¿¢‹„w>ø9Rï˜üMÀhĞÉPˆtcUîå"ÆâOc r±ª~ı ]12%‚ÉvÖ€Ãéƒ{À|ítİ	‚DÊ$_í3ïXÍÃÀ˜Ù0!ÙæRÒÀÿIZÔi†(¬VoÀ8¹r»ÜíUT’Iù/5ºÂé•ªPW÷./ L»2gÓ„ÜYÂP—è<ëçŒÈ-ã$uìC¢9 >69d•5½;õJñ‡\¿îP¥¶£ø—?/
•ÜDÛ¯İş‡øAÎÑWõÒ/Ïesİ"Ê‘ş12â R.®‘¬GõßÕæN}Ñe™¡‘œëµ¸{ÈàE°­›Œ’¬.…rndµN“¹7@KOŸ5LNöã¨¯å-èÒe¸,ŞçÚC©¶„­7ªNnvD å1¡ÈänªËÈ62éî	p=,-Õ+gj°×Ug˜_¼Û"^¢rÀ}–VÆ&k°¸•$ºZ”sÏï›„èÃÉnjÜZ8s<C§-2qTûÁ5†AB…Yã8·ÕxN7ü—¤Ğ\ºB¼¹ƒb™DŞ›ëZ]-O7ÅÓÒ0BÅ.q¥ö¥¨í!åe*qóJVÃQ„áhYŸTó”E¶™×<©¡7–/wûÄód?6ø<oG·ôP};éÚ'¢bIs€C×70Ä[¦>àãYß7öŞñµ¼ÙTÕá~õ‚­0EÖêvÑwâ‡Üºù?¯¹CM’å‡ö.:xx TVç”f_æzò%Šá¿ÉÏ!
 ]6¢’{AçùO5Á®n¾1ıë¹öcFŠ#
ÁTïO·V½M9ú¤87‡ª§â1Â< ¶.®Zqó4¤ —G£SZ#MÍ»ËNø²Aêò‘]ô²ŒªêŞ‚ŒêË¹†/ıv8Â4×ôWf£tpüÕrŠµôÛ~Ä£J‰ii©Şº9Ø£JCv~İ2 ®B·’÷V8ÙÑªBÄò…>'ôâÑ†¥òÑÂ[{ŞVv
ı&0³Ã™Ï\Zt÷cÖ˜ÛÁùBC¶wÕ&QDç§šˆÚ*x§×.ì•ÿ|*ÑâÜ?:­ãwƒˆÌ–ÁN bšriCB/=¼²~Vz3Ô>„fÑWØÖ*ZôG”Ä;´ğª²kñGÃˆÁôŞ•¢p\å«XÅĞsiä§‘Q ×Z×Ú™I¶	íØCÒR'²vlŸ57ÇêÕD/Ì^­4$¤«Øæ8%T«,aÇ`A2¨Üôü6ëKÀ¯²÷;_ìífÇ¹Q˜º[Œ»…à‹]bÑ”—â€X½T‘íFv× ¯U^˜Âß2Úìl_Æ®sª+£ù=^¡Èä›*2ô‘RÚâ3S©Ÿ¿«8¼¸Ãw I8RĞ ÆX×0Y,À9Ìv>ú|bv1Ş¹€gÌj üÉb#‘Ò8VÒdókª»Å¨æieî6²Ø(9¥{$+”oÛãgöĞVæ1BècZ"•ãIEv}™N\/8'œ!}ÙÕÌ8;@038±úÇø¸:¬l›¢µšJ`w­ÑN<äˆsÔ)öâì› ÖL¼~E›*ŞHÑšòDZ¸”q2c:
¹Ì– 0ƒè$şG•y5yğÈ‚H°ûŠ5PæÕİVà•®¤¶fÍp¨÷¢ıŒ;,kÊ¢aeÿ“Ä^ÿ›\â¹AÔ>poFVäÏÔµxÆKö×¡|Î»n1¯_+ßæEn¸íP¶×ŸCY°ü¼©¶^0Êš0
û;{'#
„Å®ÚÌÎlQÏï|nD¶7çï&±rSX°è²»j®S”!»I"¯6	ìr‡²»l1÷¬ßkæL§Sˆ€8£Lg!5ÎÏ^ëîãßy<9ËÜ€GH4çª†¾ªŒ,ˆ[ïay]!AË¸ãeTÄ¶ÃkÇ{*!
¿y+ğKrFpwCŸÄÏe>öèá§pÑm¹ˆŞæŒÓ2İÂ˜bË+¦+ı{òdwâ²CF ÿ?æ\M4÷í®TÉ›i½'VbŸğÎËçùŠÂ¹İ¼kÅ›6ÓÔ^‚¼ı˜ÌUãó¨ùR·ØL³úoˆg–B!;œõR‘±Mè=¨:\´ëc6ĞpFßË]­ÌÄıG!Ôÿq6ãY·²;¾¦¥öŠ{‘÷Û‰7$¸pZç°ÜÔ[$8®'Ï|IA –å2ı Ä,nå‡b# ‰š³.ùãÃÙ
,¾
ÌÊ$ğòûˆI28xæèÆÈDÒ¤àoa²g¢‹"¯MÑaŒË¸r+L‡VÆÉÙVlnì2™Õ?­xi®õÎ¶ôdËí±—Ô ­îG
ı²Éé@Á¡ö[³›€i/ùãy-E!äy-VcN¨jsáfQ]g |7µBùl0Œ./¸L\ÚL>æ8»0VÄÿ‰LŒ'ÂÈ‰CËìÍÌuîBáFœ3²hÏ<ë£?íK"4çfN%Jyë9s½¶sB/S?3GÖ^zKÕ.Äò |×¹§¹ïåäN»?“¿ÚLê6?x…‡È'» Ÿå’âx¡¿}>{à½î—+Mâ|× çÇ¾È¯¤IäĞ‘Ué£»”V4­jp÷…ù
³á8fÛ‚¬Õ…#`HÖ±¤Ÿ.ÃùH\†‚õ]Í%E&5÷„ÖRçÑIíqœ™[b’4§[yšÊc! ½4í›rh¬âŠSmQ9Ì©V‚¸ŸS=)ÄÛ!ÑÖÏh]TÔ,m}(-Cyà²èšC… ŒDYPs“q#	,‡B6D€[ò£À)ñõ¡Aıò£¡§7ÆQ
•èôJÅ¡NŠË£1ˆ'ñ#óÖxÓg·‰ØœWV.tWšşç œÖà€Qé›-ŸVúñ}šƒŞ~sV‹áëÒºp@˜"I§gÏq¯[~ã)è°`Ì`>ğ\)ÉL&±aXÍmDwX²¤v~ ¤©"ì÷K!v)£§‘}e„új¸VûóàmÈ¹ŸÙ”ÆgòT§(>tSkJ:–Äæ°‘åÜÓïğFP³gÏÁ#"’n:³ Æ—<&»Ì˜L{W6…Y²ÕjeF'[1¨è/ ÕBÔ*¦oíH˜ß·bõ|t¬ş/,Yà«K('‚ÒÛbG]UÕ@Ö¬Àts‚ºùöè[û2ÎßtÿÊ'ªÓú%®A˜Ô®C »ù/³ïa»Ä†ŞsŠ¥,dõÑ’âê”gÆ·Å›E­Î¿rã"†á„Ë P±*m+"ı´İ'S©‰>h‰Ñ÷76[”l®}.úºsfeëÃØØŠ»Ô•FCµ<é0Îê]l•ñWÿÇ—İŒK.ãpVz¯åX
Q‚ƒºˆ‰½ü/°¥O…×@@÷ññN±1B/„™8´¬ïò¡Â$+N½(ÑxİŠé…§ïR†(:Ñ«Í§Ó¶NR3pMùÇİI0‡Ô>ZáÌæôNÔfê +1W9´úã¿¥ŠÃ*[ËmZ†Å+†Wù*½×=(ıRA`$,AÕâJòbHÇj€2V;µ—öØ± @`³òíUÓa©˜]v·#Bºqœƒ«Ë[9hÕ·Vôú½l{0t~ÕÆjsÇ=úf´ÖØ51@Ç=§YE¾•Íöx=¼”ég’RUõ•X¹Ì³-àvhv:Ì¨<W+²Èô~WÛ‡p¡ÂZÈ…/¦í$ñĞkEU¬¦‰­
)%S+ò¨0ª_IÓõöè°Õ–ş`¿+…öC¡_¾ûVh©näªã?Œ[†›WfxMºœV>«ŞYUL{yÎS•¾>éX\3KÆ=$T·}iAï~8…+¬¼nj,aîU©ĞkK4›¢¤Ö|x}7Ù£È¦ğ?€/è¹*¨fÇ~¦½7Şq¡4®Ì'3jP?˜©jİ±çA*ù§Gµn#q	¤y§˜#B^şU³UIß0™«BTc†’Asîá›“Ø€{ıË¨ÇšÓ^u<—C¯7À:¸%Ä‰u}@´¹Ï+ÉËJAOªÛ2^˜!{r]3iØî…ŸJ	Q*Ib—İğßµ¼ˆğu(cşÁÆsß+ºEímÜ‡”yyw¾Âv}z;TÓi×ÙØ_şYEŸaÔÒ³Aæ¿ÜôúFıê^ài#«#—¤¡£Â”oÇºÓ,èáî?áslÏ§şÒ¸`÷ ŒÔ`é/fÃ·£B“¶ú"¢hQÖ(—èIÍ-”T¦2ºÉõ³OLÒsîuªH9m±ÒyXÚ;Q<â½~45ş®ÚÀkQcÃ‰Ü]²œh„ŸEîûb£Ö¿Cu+2}z*d¬Âl|a"C‚ĞıüÌX	?'Ø¨Ÿy‚±ŸÄªùü”Q¹æ%íñ©>>ˆªC|1†ÜA ÔÅÅ<XS	t]©}*Dz¦öÅèJ‘ä-0~xËªeÒ1kúó-JÂZUÍ,„š!hIm¾]'z©°û^@›œEààhDøØ¿ìO;v\û‡÷.¶¡ÇªzFJ¨Oûš…E&˜ç<çøÓô±yƒ[ÆÔ9¶ë =±u	Šõ>ÜKW¿è”+.ç?dth7²•%Üû‰CLîÄwú8$õWäœ™O‘R2­ÏÒİMDï`˜îù×§ülÂrº/ö±¡şb9¾ „Ê¡† EãFİ“™Uö9ñpJ}UµİŸâËùx7^¨j-¥‰o_c&´\DZ¼(ÀğsOJŞª·h3Æ\lÍ×ÄÉİFÉ-­ ¥püçÀb7t^ kĞ­ÕX’¸Ú¹,¸Óİõ÷§Bs°nšwDÎ]wj‚«÷ã4íˆÁd—¢?mCé«T¼qzQS!îV?!… ²ï–ìFXucåÚˆEÅ‡Á£]µĞx5‚˜ØhËP¸|è
ˆù×À’v`¡£bÁI3jØ›ÑÆØt+üC–ëS³
Ü}ûçáğEµ…%¿rÁ,×éSI—ä×¯¨¨‡&Œ#§*ë‡#-@ºÂ»Q¤¹;f«ÆÅ.ŸqËÜ¶=8AîŸôú8xèpSéz÷†%zágaì]Uá±îÁtŞ©é 4Ÿ‚BSr^ß-ë’¢±.äh
Öóæ5Ş¾c,BÈ×G?Vy¢)~3¥$â•Äå]r†ŠV¥æ Ù,¾£LÍ¤0pa†gK½Í‹€şZpêv«ŒôI±ğ.ó§r£‡­áêDú[(à)’ó@ÕA³Æ¶Ÿ•úç+q£	¦‘^²ç²òq“ˆD3¯¢.à]R7ck<Å©Ö5;´¤ÔÙªĞÛÃ¦höW~1ÄooÏİº¤*G}ºc¥„ò$‡CÄW„ ·yû([geÊÿäiEÖzÜÅ;„è„ ¤¬x™æèÖ1Xê(ÉüÌ+©¸.è
‚lÊkäåÓª6ì5AÑ«ßÏ¶2è…ãËNSŞ…ù$ÎÖ¢ÆŠmÏÂO{èh7Ÿ
ÛëEøïò¿
(/™Ä*E~–
EAñê#†j\P±´(IŠm7ùMj»gFËp©ïÙ$wrW:nOµnêçcwÌõŞÿ—³¢fM,¹ZN*ğË(—Şß²ï}µ¶¯™ÿ-&aõé^çôzw«—j:[)Y\Çg Ó$à8¢ŒÁÈN¯óm|PK5-šœõßÒ¾Ş¥g¨L¯ŸèŒº¾bg"RØôHD–E³š¥mcüºwªÆÃèC;*ëü9tÅryXì@yo¬´v&_´ÆÁ‹*H^ähĞRÜ°
˜2œp*Ğ#³ìsp¡Ê„sëíœÉt¤Ş°Ğ_q‚±…™XıhZè@½úÀîÀÕ:f´X.Lo–ÔEP2³ÊxŸ|ºbO›OŞ©G.¿rÜéäÜ‡í¢sJ»DÆíêYôèã
©µR#¹Ì|ÒZ×îCröãşİ«¨*İT½táÿ,êóÛ½©šôÂÌº/ÂËâŸgÉ÷XÅĞ	f\‰ºıı—bÒ¦¢’}œ³¬Kj£ñ9:*Ê;]Ë‡˜€øæà_¿Åëôú¯›ˆŞá“ZŸß‡
së½’k1\1qªÜ0;'7Éã¥_ÑšöÊß¼uÔx­±øªÕ›$˜dYÏZÌş+‰ªÓhÓŒN-›¥™îsßO%ZS²1äô—4›?ÎğŞaÄW~]D;Îyµ¥>¨CÚRIzji£ÀbèÙ'ä?Õ]ª<e}²ÎgI¦Äs):1—¡ÜkôwÎ¥L
õ\ÁÂé½¬8’Ÿ•nâÈ×©¡”»k‰/ÙÃ{øÔcÈş´7oB¨1ölíXÌ#‘¿Ä;]_C$ÇÌæ=sûNn@C*¤Ö‘¥ñ\~fwlş,ÉúçoÆ.Üê’Ñ%ñåWB¿Øés¸ZÎS¢—Æ*äck¯¤´èè…ÿ¾×'&Ú¡‚oŒ-¢üM¼†6Ã1¦j5<¸ÆÛ?çä´Õ®hæQŞÈ%<_ôÜì«Ù×¹‚•ªà[ÜÖ +ˆÊÎiâ´-Du¾Mjsh"¢:ØË3¨<BïšÖëø¤„JgœMm‰{·ŸâûÏJ(òs¨ã?@G’„ø ‡c0<XK9NF©×(]Bk@¼?ÕÙ[G¿¢(Àƒç(³Fæ3#µâÑ€K6C=ş(Y˜‹z°à<Âm¥ÄYqÆ~ş«?8
i°ëeFo~ê`Æ6+°YGª’®¦ìRÒ”PÉ«ã”işæ0èH#Ahƒ)vê‡Ô;n9âxhU0òu+„;¼IM§›‘5wjÙ™ÈkıJ ARó£¿µB_Ğ»ĞÔüZÅïhÓ¸¿D>ÀûÔ¸­:æ(m7„A
¢eôŠF“¹xûğ”9½«C¨—‘Ï.XkÃJ]7®V©ãûÂ84ı¾*p¨‘·5F{´©˜ø$ĞK9æõæigû^š%÷Y"n‡EL‡¦lÁ9€£¤	»Øì^Ï>MÕ pt_—Ép®ğ!t›+)áÿq‰Î’Ê·LàĞãÎ‹âµâ—"c•doòt‚(¯(¯µîXÓmË¨@ÌZ¤¯—áô¦›·{±ËT÷5…[=tZC‰Z:ğéËÍÛ\B%sV»u‰ÈñÕnwĞ¿Æ–²‚C
ÉÕ®,˜aDà)1¦U‚‘§¹ÏQ½ÔÉUÕ‘ø–ù“ä
Àè¦LROû«*Ô¥E¬kˆó3îò•AÉSıCÒ¿³µuö	!:Ú0/?-¬íÈ×ƒ^÷ÁµƒÕ[jğ	%xG 
¡øjÉƒC¹.Ô|ã ø«†ñu§úÃò/îê‘‚¶%‘‡ÑÎÿòª>¥¼ÕBS®^·…s°Ø†lŸˆÏ’/¨üø§,ó4ÖåT‹Şs¯t¿¬a‡”@Şÿ ©<â‰m›™0€ëçÚ@píaÉ¥Ú´÷ñ‹=[€úèÑd‡hÈ_È# ˜BÌ9"¹ò{a‡g=ÅûOrĞóà*_¯Z!Ğf!2Ëı¹èz¶ã»øú‰zÛgtMN40>úwõY'@f0’&]Ã'U¦AÂÑáS`Û9Ê°¸ÏTÓø0b^ş­ğ¿y‚) ñàÕf2›‰ëbíÍ[¸ˆò¥'ÂR.A"£§ª`¿$/EëîÉÉJ&‡_";uĞ(gyspƒµÓTá–íAZ§ôlúCäz%íf8×‚Óú\š37à÷î‚ê²õËKoVÇ¼(ìI¨ŸüéeSyGôrğ’’~;X:_g5D~®8Öa¸ö¥V^¸eĞÑ…ìelg¼÷Z^×Í~}6Ò«oÃ­¬,&K1%¸qUu8”³AŸş¹¯'vz9=aÍĞD*Ãæ”è|Ğ%ïå(õ)ïåÑÄ‚9û#¯œªbâÓXwNXQÑÜÊ}œm±oç^-øL¥z˜kš¸Äà9ê-…-8€ü*‰şF…âğÓığš×½C¨²èj…¼÷O)“;BIs\^kúç³³¨¯5¯¶ñˆq,†q©WTBGSÃ(/ ÖÖ@qúúMÀu¶-`=]·Ê’à_7ƒ 4u—ASŞĞïüòT¾àûËEÿT—kn±Ä¶¤BwV´1‹ƒA.†Ñ(¹¯Šm*ØŒ(Ï/€Tä¼b„gQ°0Ül
¿5üÌ•2XÖa¡?k ¡¶Tj½˜ºîtŒS¶¨ƒŒíZœŠÉèa^Ê‹|ùRvÛå†3á½>õ”…Øïo4Uyu¨o<ÌM3²ş@‡bcJ‹Õÿk„1N†]p›‘F›n	d cR¡°Şƒ*§Îè>Ch¸zÉYuXù®ß¸œG­—y’Îkâpå:™$¸À’CÕº‘¡3ßJÙGá“wU…eÒrî3uC"%ÔÅÄIÜÆ¶€d=‰õ{í‹ÕZc=/%/è
n¦îÂDÓdpÕ?tP¼APï5–ŞSé–wúƒ‘ó.‘qçì9Ê–m
XµâÆœVüA5„h”ÃíÁ¦U¶7{a–K'vˆBBßi;A€vø°‹Û>mpb­H+-Ëù0¥·sêÛ €‹ô3èÔa©9óœ]FœS»B¾+|´–+±FãQ¦p”«œ6cÿæ)ŞÒé…Z©ËrNX£jv“¿ú4–Vé˜`[£XÓ8‹Ó6Ú« âK'Ò=<¬ÅÂææ˜tË[#d¯†ñ†ÇaÙRS¸ê±á×vkƒ… Ñg›2Ê-7ÄóÛ$è®?/©Š:7ŠçS¨9«áUïÓØğSsu)¹o¦D(Zê¶†<’¹õ~ó¹}f!KBsî…vŸm•€:Äk‘UÉ•Ñx$¿Ÿ…#ì-h*…?&ÄÄ¾ˆzByD“¬ßRÙ‘ÿº{ÚÍ™™)£2#$ô6»‹àı˜¦Ô‹<î$õ ­ÛÃYs§r˜³uø‰FĞ¨“H“óÂEJÁæÒKÓdÎ+WÊÒì¯âşË0›íÂÀS˜ı.8ÃÆ=|D‰Kû· ê.êwöœ¤ï¢°½(Š—ágf¼üé’€a<½Yh¤H·¬\êš]àØåMéÖ^{ö¸\Ó%2,Œb¬aÓ‚×•ù-¯¹>1TB1Ïÿªã+ZÛcÄäJ\è‘–¥XƒÅHb [@x©¯'³“APÎhu‹Ó³üå.(wä­>¬<‘l­¡ƒeYïŠdéí©T÷{2µ5<PÕŞ<
¹/;ÖE?omô×Û-Úˆ:U*6gğ[÷àu Ğ{KÒX®eåıEöË!İÃÛ
ÈAS¹¬‚¹Ï“)ÿÒbe€¡¸ü"4bÜ€—ƒ·3M6p	ç!€™q%â1‚VHÁ@á‚*…aÙWÍŸU£F„½¬“JÒ3×Š”BŒ¯øœDèqÂœ'œ¡yÈxé¨ş2)ü–œo G;2cÇK¬Ë­töü¿çY#¶1†¡¡‡Kx¥öH Ö}Q|aS×6åÕ¾¯Æ#ü±>ÈÈ¤ÕĞÈäÃ©*Ùrğ¹®:™oöœ÷ú7í¼©m7ş.´zÌj$¿½ç4N5•p¼Å€„½É÷·|ûÀu>wÄ²"rë2t¨1)†b£Q"–••îY—xg'`5»—ÓAÛÍÒouò¶'ÏSÉŸXºõ%$j¢ÄÕ¾Û¬²
Îµ0úüË¹<·"35Iå{uÿŠıluá]ÂJ»İ³ E•@qàÈëï#µ_}Øî	£ö6´†‡ákd‹	V•Üíg•[{½Ü:G‰´vÛ¡:{B‡µ¢ë<htgW&×„#?şÎ•"‹Ï+£OšÃdKºF77U=ˆ_MZ¥}ÁPD×T°	¥u®°şª*Ä›X²‡ÓO‡å´Ôöømt]D\E¦Œ[38£Ç4D¸KsEío{$á
îW¡_sØ¤ËÛ¢˜û©mæW¿«2ïğ|âé…@”ZÁÉÒP‹R+*†Ñ££¿¤—ú6âù%UÊÕ"f÷éZŠ«hA‘k¨¢UĞ±–yšõ+sX{Õ+ˆ¨^6¤ØVF"kÔnÂš¤ò‰á|Qõå¾~ ®r!cY¶c—˜©ÈÎòÕÙ|Ü—è	W»2»õdƒe©ˆéŞ4hRË¤.Úø!ªKX…©ã	ªˆı2˜X>ÒÚŒ#dwst
ßÛkÀ"²«äÜ¨×¶]ù‚îs´¯Ô%XrP·5 €¯¢ğŞ9"ğû®¾ì}yë,˜+¤çÇã–_i³5@Hgoõ—cGdëz]P–915ÂZ(ƒkØ†\Ö§¥WBÍC€ xl5õÜ	W' šœ5ÛÍ<İlQ@£“ã¢,2pÔ¼?”İQ²’än@r)éÿ*Ã3CNÁtº7Éç`Iåwìïè$	vŸ½·Ú¡ıï.ÁöŠôtÛ0Fí]×|ëw"‹th"3“lj@vW/š‡›ñt' à5ş¨k_şÒ˜@myAwºÚ§,rì<†Ux¬L—¯tTæ-¶™4Q˜^üÄªÏHy¿™Êj¹ì^tGæğh@Á›Âùb|ÎJ8®ù b÷›¢ÏĞÔ€£;‚C"ªÅ 	ùD‚j5³ OØRŒEäGG¹ ­é?\qi›–`-ÜX]Æ]ë/Gëcz/_Ş±jKÄ^,¾Mo·-š›^~KV¨Ç%ÔW—ë#ßh—”¡ß¯¥7™QhÚÈ\şşÙ©Î!¼A¥ñ‚b÷Ï*)ÆÛ7UrpDm-RÎFğê}fÅ“ä¿öÕï¿¹¨‹³ã|[»õm‹ªÈúKà¿Rş2o²èjjµùC‘Ó;öøtáò	.J”éZõ¸–‘YQj·˜º¬& _zJÕ½Âm‘Ğ¦e#PÛÀR­ÿ]üŒ[c¢û=ÚùY¬ÕEÅ‚­áã—$hŸMÏm û½KsN¼sÃoÃ™õ±˜À°ÖÔ¬pm°ì!-
oÁáı!~ŒÀUısGv³
—·Ä’j-üì7.ÜHòÑZ´¡s=ÿ¾‹}Ûav}xË“5½>RÇ¦;™ùcˆİC–ºÇš£lr¼‚ı©,•Ï%´ñ—E„¹ÓÄ—=€ä,åznjòÅ‹;é¬ú8>E“qF&¹µğ±¢F¹G“—FQklÄ®F<§µœ±kC=áTç¨LÛçbíÛLPs;k6÷ğ¯Ó‰59ôŸ/ûLdºYzqå^Öb‘±ú1ˆ9´•`î¸rI™EOûŒûnÍßiĞ«Z§ØíôFú4óÈ|¦Rå1øZ,a€ˆGd5›àÕ²ç)ê|¿öŠ8‹µfÎÕ¦FGõşTâ7+Y1 6¿Z^ä‡€ş­@V˜ÙR–eG‹]Š½²°RĞ 44 Äº¢GØòoë×J[8«Q‘Bú«8-='xr(	Ó¾a7qúÔ) ä¡·’ôªg¦Îjó³‹@iXÍtü€Ïs<5¤£¬5\Ü‚d!ô¥?òï»p0ı&úèaß
Ğ(«Å“ætOFˆ•»‚ëâŒ®§÷"X}®z¬B2)¸ÿ
‚»µ0¡™v”œw ’e¨ÜÒôˆãÅØ¬ÜWî
{vßY=ğùSîhşF…İ2åğúoUòrûÀÀß:÷4Mzò`ù8ønz5Û!³R‰¦HÕ ½ËÚßÁ$¦$\´)+„íaÚ×`°5tëûSçü{q2ÈäÛšù Ë”!É0ìIã¹LıÔøåmşk$]TïÇdú$üIùÜ[Hnˆp™Jõ…6	¾ª]˜ [!wĞı#hz‹º›İï4_”’CbŞ©Õua ëËŒc)EásEÎ$¯è7'JÓœ1o•Gã£l¦ù>à+şñÀ´Ò¬Ôw¡±4ÄK”³œ,¼Î	P6¤Ö¶\€lşvÌ­—óŸäæÿS\®<Ó–aÑ\±·Oú%VÇ¶£›)·è6‰4ƒŠ&4•¢€d¦“tâTğ˜ÏÀ}xzºqLÿ¦›±äÌÁY†ËĞB7áÀ†pe•Pé¿›é
ØNOs¸ÙÌw³n‰æí7	1<rı;î˜ZÂc0˜%”0U§+ªpŒ¶ÙyÁMxë™«¥—´—çÖ°Ó‹,r%|Ğû²cábqt¢›7:;g¤]…®R@F+’şñ¿ P¾Kf€lP¥nlÀ:Ù3&[´²LC¹î¦5õîœ#wË±EìœÅaËM5yÄE§‘38q5ü°¥A_g÷}¦ö4¦È	`d?šÔñÿ{ãø“äLOu™àX÷ö¬ü’¾¡_eçx­u<ùq[Šòßlçî’×÷÷ŸŠ„©Ó“_k,7V‘ˆKÔeÄ³yW}±¢ØÁ¬¬lTu ÉL‚²&dËŠKGÿÄh‚ÂOõ‚¶è¼ùĞcià$‰Şl—ã{ÚfI©ê  ÂÇÛ>R=cÛ…{HaÕE40:FØ•'\°Q{Yğ;ò™øª””$K*ıEçsIUÕuÀĞª]lzÜ2zpÉSª…Sş£tıD»»’¢ÄŸw¯J7ÆêîgÌB¶€f~(=´_±Á'“;Ğgj ãYgçüH’|æ.Wá°öyÅ”,x²Q30–só¿<”¸	¥˜£À ‡T…‡RpÕ{ñ<¿Å:–Á `Ac=2p3QR…!~@^²[¢ZÊKï(Â*ÉlÇô
Ö¡«ü¹³‘Ú˜ [~Ê;/—µOmXPÉé^ugN‘ÅçÇ¡®Æ¤İº×@Úù	è]L«†{é$ì»@šÍR™úÌ¼vÑ»7 ÿ8÷ƒTÒŒêÊ·wg*ËòvVÚ91L®¤ è	ö÷ÉÇ 	/Ò‘…ı‘_ÆØ¦Ø¼&ê½Ak™ı;^W©ØØKrulŠB›Bßöª£›,Â5;¦S‹[¨	ä^0ØÉ‚=iúÇ
B!’›Gu1¤äæ÷İ-ZÕ•´ÁÓ>MKİÅl$ o1áş4ãO¥Ü†?5æìzÛ†ÃæX!””¥#Áã>NI5âeÊØÃkOöy6Jt>ÊwG¾ÚúØT}æÖçÁC„°pxêMõIæo4İaYİj„ŒVÖ²"óØ³ÑfÏ
˜Ù L»+¸ùËéÕÊJp½Ùü`Û¹Ğ©é&àúª¦¯’‡ßØOE m¨n¨w¿˜ğÙoòÑş7ZÒ’;Ju’ÅÈ°heù
OâbP>A-(;ÔÉ‡¶qò_Í»jÖ½‹Şì²Ú’6\Õg^@şC³ãÁw‹òƒºÊFé™ƒÉÌ%Œ1#/V½½š?úüé©±©½Ù$¸G1›\&Cwèl"+ËOõ9ÙvÇ¥uÜ>¬£³GL“L]·‘xÇ]uâ¸·0Ën¹¼AëodĞc‘h|c$Kí +ôª‡©şØò˜úºŠ›¿‚ìJx8˜} z.*z]Lo¶æ„ä„MQ¯2!ÌNŒ¿âĞó$Duf†»–2lgµÄšmGÿ2¦ÇÃQã<+W-ßö¡Ë~n®Ÿœõo*0uï’¢HòÈm«©C‘ÒÍl–ëìøğ5rÅôÛš‰F­ÇJ1„½ßM<èw&`'F¿jÒnğX94ÇAcLfÅ§Äy¦Tşß×ûCì”ŠqÒÇî4A¨î€ÁA¨ÆĞ¢9‘)—U{PÍR¶KLÉYŒ°%ßd4·¨Ã¬4–î:ñ•@óû÷ÈÿG~şnxdx|‚ß©Y=ò„bLÁ}üT‘lk‡uÄ;§|Ÿæé`ğÀeã¡×„5ğ8°Ñ(<"ÅT‰Vô˜Í!Õü¸3âC1iç,ø¶XüÒ™O±1Î’)nİ‰VAöèÅ=mV½Çéÿ¹6ûëYw¸ÿŠjş¬ßütÒÁÅO;ú¦„OùdC“uæ?Ú¿ß£øÒKë	}…A\d3¬—«ÒTmŒ—“‡­ZŞ/’B"×ÕEÛ3ò‚.op6RvVàÊ„ˆ4šíßOxêìÌ•Lûj>«ÇîdbSJI{Ör<MOìûÊ‘Ô˜yªë3¢‹ra÷IşTã+ò€²c6pØ–ìªúÂœ£×™+çHP¹j›îÓF[9KÚ~?¶TÿãêçV¯°zh¨¬ïùû£¬Ô¥_;O|Øf½FwWõá>'CÙi°6öÎ·
_æğë„âRÊ,èF,M©HÁiİf³˜³ı>ù¥"Ô0(Ç5ø©,¬$|0¿İš0¬ô‚4ş-&Ët¿ÉÔBÿÒ^Ÿ]¢¢Vâ¹É”~]¢Ş\R‚Š‚|äu\ŸÈÁDGÿ°GŒXô#ÆàìÏ6`ñ›qõïp†-?(€¸Ù˜ãå ï)´'C9¿yœåØñä£$ªÜo‘Ö Ø±A2@İ‰§Nôí¼¨ùºƒ1¸T_¤™3éŠ½€?á†èË•Ç¿0[eG‹—à˜ÕüÃqí7êÄÉm9_öˆ‚¬‡Û¸'º6aC œT¢²VC7ŸW.“cƒq>] i½Ì2ÂãÙŒÿ‰‰"^«ÍãáU‹‡œ]õK>i@é-Ø÷õ¬ïÈ§dÿƒ¾Éó«7¶3¿§Š–Ù—_uê‘LoÕ®¡
Û«'}³0À±¥‡aÁ}o¡¾‹}bo=yÕ9Æ—•ş©",õ‡²Íöo2àa@Cêèc÷ÕR4õq,.lÎ›oòÁ}†Æ)’é•·\Üc8ÆK@‡éç©–O*«¨Ÿµô»ğ(ívVms™?eœN¡¶1¿Xjp¨ 
MßôÊœ:ßéÀvT×´Üë‚.É~×È¦‡Am˜ş];D/ğ“ıãSèOù§”³6ùÈ›Xú¹Ÿ;“"xªÈÇèÉïgÁ)ÆS‡8>"—šæ­ÀEµbŞMwˆ%:Ì^ª…£JH9¹êMÎ¿ú‘'(Æf£ô:gCŞª?b›XÉ ÎB%¥bÖ1‘ùIÎ•“¯­t€S—2!J0	Úáë¡tİ@«æMÊÅªm7
 ‡¾R?³¸°àVÅk3÷‰ÂÛÎø|ÒÜJiîŠ‡j3Ÿ Ş@!CAßkù= /VGş4~€ÂÏL:&Ä•l¤ñ¹ºåRáKtíÓl½òù¶ì‚¶ğš¥+¸—Ú/@–Fö|o~ÒyT¥^”ïÈ\Ìæ€ªcF`½M{å®n_oüö¨4ºÑµø7Öô-eĞ‰¹øf®¹2æÕÚéó'›)£gÜ^	¦yİø;	ˆåSÂÛíœ Ø!7bb‚•Ù1ùM€şVuM¯[TíÒ ì˜ØWYv@ »’\Ÿp°ybCÇŸ‹ˆÃÓšrÄ1&OòHJä“.é=Sfi©
EûtJÖ#$Ç_@uë|æ¨ŸÏY,Â…ò?«@7øè¯›Ó-¡lãÜD}ÂƒD0`‚º'6NÓ¿pü8à$À-2Tû§hOªÔGxVDÏ*¨÷×û?Qk8®Yß´«Ù"ÓÜD²0Ü¶µ¶@gÛ‹&ÂKÁb—wKµOŒ^ûó¿Á¬1ßmn‹œsµG	-RìÄ‡ˆPZ«ŸÍşQëøuÅXj?D¢ àB>AcuØ²fiŞ¦ûúòbİ?ĞÓ„-e~…,ì7û‚JÕşx?Ã¸ÑG“0ä×·o,×òb5îÀeFIµKyª¸X#Auƒ]ï}oİĞy*;|¢Tç[A(BD‡PšhÉÄìÀm39ÙæÔ·¼˜oşšìøöz–ı¹¶Å»Hœ¹°ßø‚’šQ-)VÔcĞÀ}³oí†iğEÑÃ
£<<+:Sƒw¾H®Ğ¦ä†âÁ™±é6J;Û¨/ãw3ü…B2Fë¾¤*ÃûL%;×ŠJ	Pn‡)67WôxÿK3 =K5ó’ZU%õÅ	ÏÈs´ŞÖÉEHÙãû)Î¦`¾¸øÈdè~+ÉğXÖó[DÒ¤Ö›ûÁU„S‰Hh{”ÊgíÈz‰Œ=Ø˜Ç¹Çe/M^-“¬åØš¤õi]óµ)`ö„7ÉÀ}iÄÊN‡ğƒi­N³³á7¿ö“pˆûmş‚Ô‘x”¬Çí‘æŸ…yÑ4è$‚›ç“Ìáğåºµ ïSpK_”›Ø­Ó¬hu8_\¥ğ7ıhU!h8P!nTèN ²³l>Ú¬µŠ»^xH ö¢AmGŒè²Á¯'pŞãíĞ‘1ÿi€ğÑ‹ØÀÍİ0ŒÁhV3áOc¿A¯w-°ğIz’ş4	
Ñ¦Íêy;ò©A9;%~Y²ÙêÔ-8`C’dx’§w
2Å[Ó­QÍµO½“’Ôâ‘°Ån¡»W­kd›ä3èu÷X<‰#¬¥L2¾Ï}æ£—æ˜Ğ4ã¥D#Î­81…á†k9,[Ä¨z]	C•M×öçª²Nğ¶co›İ®¿«!ò“"¼>üÙ­ŒB‘Š2ÑŞÃùªó“Ø–¦íÍR¼ºn0°‘8££å\E³yÛ8cNX±ÀÔ]`ñ’¦ˆ_F-Ÿ^;‡x	äÇªÎ­ÙP|µXuikíES„Ğ»…@›ø3³‚§'$ÛêQ´è	¬f»#Q°C»ÀÊò©´ÌË¾Vä5@œÂ(|»­÷]»új€<ˆ¢ekwnº!®œñ¥ŠL÷º:Ö£ÒâÀJ üh¶/+²¥¯_qš»¢¹BĞ»-Gµé@G'Ü?¯ŸÒ=¬7z´Ò—²"›1!ŒŞU»Ğªô±‚‘qø–öµ­:3®ß€ÅğåÜ”ôzED ÷OÆå@½6›â?êûPåÓú–å76œàSêpndi©U‚İ‰T±5<Â"ë=œŠuô;¬Ëx‘<gSxÓP÷bXâG›ô2öË“ÿ‘˜B‘§40GÍ™Š7˜5:XéòÉk¸ˆK‘éÁ~9¸ÒœÚ1ÏW60¨Gô€‚ˆ[0¼@Ü9ù– ê‰õ¤ğóJµ!’İ @0çÑäÇ-¬w@½ÎÉİaJÌFè©ÿ‚9¢)”™:á‹QIÆ²®gõµ\¦ß–ÂETßĞÌ¦iHfSëo§“¡–dåü>>—–qº¼éÑZÉríZ£Š}ø–å|eG¾ä`bÓ Ì™:ÉøoÇ¯–3×&PnÜG@3'ùäo"~†ú+R0‘(d»
œ€}H×|Æ\k†n@Z[½Hxí6™i¢P,«€²? ¯a[Ú5P[×0PÜ¤Û·‘¯átD2PTíŸO,gbĞ	‡xHéŞ¶ÉôFç„Ø]6N–1e’Ä¨¤ÃÑ&R¶"ñ˜p¶ğÚÙö(#Ñ¿“ L¬vK9Æ-GŸe/NJãGæ×Š7*ïÑĞ‡DpjÚ^•˜ÓM$µ¢P<ğÛeô•º4y§æ¾ñl:»{Ğ§GØİ<ìó‹ßqv~Iëe2% 2.Ùƒãdg‚[uaDÀõé ráAÔş¾$i ŒïÜ¦hı›´‚¤(ùÛZ“+÷oª6¯Šñ=ìjğ/ÖR~aŒ#,QÑòå±‘YùòAK£:ÏI¢ÂªÍÂ.^XÿfJèw¶¼‚]¹±ä—6áe¤|Š…)uÃbË“Í]&á[%¤&c*Ä¼áF;Şy?‚lÃ~ÁÙ·tZ*°Ptui§¿L	¦OğôóA’'1/NƒËâ2Á•ò!Q"¹rº,üÅ÷<Ä“„„	ÛS,€ğKqëòUš•ÈõÓ“/9âCBz¥õÖ¬ğü€¿ì¦/·‹g!ÆqÈœ:€»ëºt¼uw›åÏ©©ö(\Á¹ˆIéwmiÊwÎ
×:]‚Ø´†{¤m¬ZèBp|Èr/K¸'.øm{ü@¡z5 °ÊlñÜz.Â·‚úÌğ€ø5@!NN¸IÄ§gsın¥ËxK£‡'a1ô†)Öãy!&
¸‰n¬$ô]Î•¿ï·œ>eó*¥¡–\õd„êQİâå¯®©uÒ%l"#~aç½Ã'qÌ†ÂíE8^ÅÜì9Äå¨iàV56KX,Ræ|i‰¤LhBO{¶¡÷3z5).!¡Îó›.«ˆútÀ‰‡ŸÛÁ“J’¬ù?ºÍ®“œéˆ­=9ô|/ª°¢ÒgU3Ü™P$¯ıäàî!¼~ç¥5ë¦]@±Äá´ß>/Í?mğ†Eı±Û¤cĞù4Ğ¦1IëÁÖ¸ä|;¥ Í£4Î‡™€ƒùË¨YÆô?f]C†aIÃØ=«™ª;öé[VÍ ´bõµ\è½G±œã9¿Ÿø‰Ü·Ù:MV¶¬09¿w³$]éRI…?´eß„mMÎ^TøvòÂEçâöe¾»ÿØ/"p³ê"İ@Wü¿B¤ÒÚKñù ÎU*;éüVˆ“÷¢p{ÄjŸ:³ë«¡,"¢ÑïiJxÚôæÿ
È“1<n*[ ~ˆN„fÀyæûØBÔ´“íÁ˜¨ò -	iò^†]»;÷ú,› ·bÅ¿™æ!èe—@AXôZ¦lJ,ûI.Ú©}dŒ€NvÚÄˆ·çéÚ©X–×èÉ´‡(e[èœ‚¾‡pB×${h¶xÕñˆÒñıûf°wjƒ|‡ûµkı¿k÷ùYEï•#ñy±G„¨( è76È
J/cÕøs|¾”`oaÖ—L!Vóém-¦2éaÑw¨u‰¶»öš(Æ¼?§•f±“ïd”ëE"æ³(rÙ¿ˆ8vŸ!qšĞƒï	%ì)é+,ÛÉİ•e#­RÔBÌ?Ò"™Y™¤›ÿ+£±9;yl©AÅäÈ˜16!îŞŠ.ŒqäÈ™d€§à
¸á#ó#Ëëb†VSóñíS¥­ÒÉ)V²4„idZ¯£bb·ÎÒ«˜k’Ô€}¸àKÕ5µªhˆ$ä“„†>iî™ÊößRt”ÒÿÊ4¾`7 H7GœóÚ&¡:P—òNX>nÜOu¨Šd.7ÌZÙ”¡h¥Í7Iq†êQèú»%t.@"¶ÁÊÌ|ó…·cİŸîMO)}¸_ê“é¿ÊÆ¦èÒR´á¿¨Ÿu6­øÅ.Ùe%ıàïÁ¿3c£`§b±ª­v£WFw˜Ës=©ù‚ÿĞ`ç®“ÿ¤w|ú……=ß}eY$ûy™_|M»ÄĞ1õCËšT:Lnlk2cƒğ¸j‘	Şçäd:Iÿ¯ç­ö¶_ ×H¯µ–`Æ®t»ô®ÁO©Œ1]µŠfC?<i»(*¢6eÿ'Aàe#´0åd¶yn¼É`¾uóèTt&¥s¶ÍÉ{‹l-û­úî8¸Hkz6îkZìÕËì¿ëƒ÷¬áãDCé(U§CÄxüw[ÜÌ£±}RzÃbÓÅ{^bvüÔ»M™µgÂ¡>$3&‰oÓÂRb•Ù9`ò‚ªÑê„’´ö¨ífJİ!µX¿ç<Ğv·	ÚÁ¸âıZI"ÒË7Z8õ8gëUå…È˜hC¾›!¯Ã…E[¸ŸƒK\»ÙKú‰š›Ü8òúğz`H©ø5ÈcÅ[ûVşµİ
»Ñ
LÙ	¨nóÖ¦*±|ÖÃyv8æaZcç:— »ëwÂg•ÔK…_‚,{7(Kã+Sô÷µìprÉ	œ¦É\ã1w.¤Î˜Òí
,I¸ğÜî³ú\… ¬wÌkƒóØ ãÉ`ÕXGşKZ Mñ´æÉÕ?˜°<åˆ½‡5fœ]J4\ÕƒS«›ÊÙ~_’Ã2Õ¡u3Y¨ÎèßfÍ¢›À:BaáçÓ-6bêÜV2ÉyÇ‡¢m4;ƒŠcldj¸kWÊ*xU(Ög 6±º4D~9jjfŒHÆµ9MQbŒ:‰Ñ»öü÷ñ{±Ñ÷¡$ßÕ‡Â¡ÜxèÚ@ö@|­_d@|¤ëw–e¾¬MÅÀn^³4ñ¦j L¿ª€V†W¸£ÉAÿDñ9MV6¡¶­ğå–âÁP´Œ‹ ôrSCòÂcøx‹ÊæE“
nvgâÓ)ÛLşP|ô²ĞÇÀ¬¯©U˜|J
ùáøQvR|%å.Ä;[ô¶.I˜ µZårû^k2[½5¶é—§¤ß\>îX´AA©BÃ ù ¨I¦o‹ée>Y•MäƒüiLF]ÊxeŸ‚á
,FÎ‹ó)¹?y³…o–ÿ´ŞÅ2r$Û©|h’¦h‘Šg“Ëæ;†+ÖÇa^¿èÍ#ãa~Qs§kñuœ[´ƒDx2Z) k¤aFı¾m.8×âåU+‚ÒC<Gæ
ˆ*ºá;ô}ö2‡CgÃßù8PÑ¡JeÖÉ	şØúÏ	,Öò•“Åõ™é¾&n¦>íµN	 6E—œz#'6>U}EG*}w©g¤jŒ:p§mWóÒ(–H×‰ZôÔoòS‹ˆ-ËJ¼›t	 ò–¾SQ‚ªj…èÏpm²éÓ|µ)3Ö}!MĞàÔ¼’Ëo`êhÇ5ˆB7O;Hm`+£êÁ
¢˜Wª^r ²‹’¿K‘Ö3<¤Ú¯5î+»ßø¦Î-MRõ²zş•áX30ÌQl¾£ğIz˜kë
<Udä õÈ·I’è‡ ˜‹%<ÿIeÓá}ù‡~7®TÙ¿5	KDÖ°‡hÌÑ°¶ÌªuXÁM(Èï»v¨ˆ©èIj6Ø	H˜”˜}âpêHDcl–ÌRÍ1,´T®âA'Â†‡%R£RŒxY”¥Â4š³V}İ’:X¶ QJÍ¸;c­1Â±9Ê/¡B(ÕBi@	f¬l$‡%~3—j…ZNU¯ìf•gÁ!JyLBTöÀfÄ>b‰&­†K=k
I‰1+G"/­Rv¨à²]r0Æ¶C¦û\´ [†Ş‚ÇŸÅÂSx§ŠxÀn¡.?N	Ø!!©|“üm0—K˜Sù¶şdˆ*DÄøjocñü«Ø.­5ÖÙ´4ø¡‡m#_8øĞÑÉwï`]÷˜hr* )k¯’È¤,ÓëO[˜ÀÀ–úÂ«3×¶òo•ÃïnĞm{éHóG‚¸´C b³MÖÆõ®I>áV”_æRÛªâ®ñ«Ï0–*‡ç]<a [{M-]Â6áƒÃ[
=^9NeºÕ^ ä,ÿ§9põ<Cá¿uV£FÜª„9w-ôİ<çp%›– #)†ñ{.®æ¶ôbÃÅRİÅñ©Xºqš§í²ˆÓ¬+º#@BÚ…Û²O×„4å‰t·;z HÈ*¦Ÿ	É2aŞÙŸ– ûÛQo…¹cõ:,¢Ô£Ñ=¥oş`5“fÆ^jAZ;~>W„Á¢ÈÜ@QÉÒ6¿’ ªİq³âÌÏqš¥ ’ÉÃ[¢–	$1ñ‚w„°c)$céë y¡ª^İbŸSáD´çÜë»»P(åçûŞÈ°"²6‰ÈôOÇ|.áÀ.“ù…»aOáVsVî`C
Fd;HŞí$E»%Gn5îù´ÿmÇ!m„0€€í]–ÎÜ»Vµîÿ:ë”í¤Âq¸ø†Õ‡ÁO™û’Ô^'°ÄóP±ZnÿGß÷ÄW­tµ—µßÑq¢¹ĞºÍo®E‡)şRlŸİĞ‹Ì/±İp-ÌoÔåyQÜ
È¸WÕwê= ¿†8A¿BNªcQ)XlÖZdÚ¨îÉ xÜëÑÏ›áëo’ñ»¶óÌ`…¦Â+{4Üµlª'ĞL~¼P’-:/š¡”‡„€.—Ì÷Š²`Bš–eTŠîx'ç*cŠ«>¸¨–Ü’Y^zeé¸—6óåÅ0¥äÚÀL‹Iv¶®ª B%Ûğ×ûc’—‡ÂuGÃc˜KêáGÁ†ág2ÔAˆQN¹„³Tà>óIÊéçH½ ¨;¦’p;í‰Ï9©A³î¨`)œEÂÙÓ+ö¯\„FSñD¹”óŸÿ¢[ÔI–PÓùzˆWêäÎn|:-ï±¢6«ºÊN‡
`ŠmŠPûfË0 À÷TSZsÇKæ*ú*bT^¨×?¸Jæƒ!oËÿÑråşV)¬ädÒë[Ãb2sÉTşkÅÕ‘r¸ˆµÂ@‰›Ã‰»'—Cü£	ì÷ÎV0¹ÿL¢dõîø¶zşØ-`È–0	^A:Í¢ìíµ+Ô[…¶¸ÿ:ö²[mf}±Ë6jQSOÒúÒ7šéä[…ÔáänD§¦h*ø3@³@¤¤>{ñ¸w«WÍÅÌJ« ­;—!I{%À“ v@&ÀD5 ›%”»§ÿço‡yºìE_Ÿï§)Ğì3ÚÇ7#µxà¯Ò7òmV>÷K÷{É*Áñ‚ßR_šÚø\"/>:6ã(„´Ğ¹JqËNõK‰/îæFäFø“'À&úX®X‹O°·ÿ°WCÎš·lî…¦[i1UFĞIñ¢Œ¬¸=[â3­[7ŞíCÌ,e	Z]İ'£R;Ú%Ä;uÕ€ÏË¸q³Cø-_V-CU¤ŠU²²>MÙ«PóÒÍ8ø"õÔG:w'<ªÖµàJ²@dD{#ç*<ô.ø¯Š Í
T¡i Q/…<²è†Ç‘ÎãTuÅ³Á€Lç\»U·ªHA‰å$M@Ù¡‰åì€£èVŞt¿É2ó…Gÿ‘‡¿i$òåÆåfË(q*¦RÒ§@¥eGúÅş•uá°˜1Åh‚€—œÇÚN(ºĞ¸úeß#ÆÒ€3`«?ÊíAPşCÔ¶àØáøíêŠŸ>ÌÎÈ¿^´Á£"iŒk¬”.´i@v~¢Ñ˜Hg#ï‰îtî¾4z&P¸L¦à¥À‘ü™æ3nkW4ob²÷C¤Ä;`Ü6Û¸3Õ+ÿUR}"@+§/H3yzÒhæ¹ATö=f‚$ç–ÌÿQƒOõzJ¢‚Rz,æ4SNÅ£o¥Í¤]î2Ú`<âA3É›sµ—áñêalªvF(3^œiZ–À…§ì8¯#»h]•Ïqâô®óÕå½ïá1‰¼i@eà!zæ Ú»®2K9çÛRÓ¿á¥Ù\?ø+ÔAø7gÍ% çiGÚØóíÿ+éı{œp÷yHÉ]4Q JoŠ÷¬”W.wåDó‚5\ ‰çUlÓj­Ş,T£Œc§6ïi³	p³?‹„´JÙK©ãVa>Ë¬vmÏÛĞõm\Vöİ`G:zØ‰ê:}Äû1(¨6HHXDk$ÂY^†£Éb6Îÿ!¢\;UB…ËS
±,U˜ş)[² ¦ZĞÙwë)ZïM³µÅ·ıK­>œËù+gkK,ÇÁ_ŸKÑÌ¥géä>í­ğä— ¶xmªK—À™oL„F®Ë4dêÍvŒğf©ÌÁ”±R¾Ö™İ_‡6³×¼ÿÌ–G<^?XH&	äU0‚Zw¿¯ÿğêñ¿âkÆ7@ÖcZàš¦ÖhqİÚãîã€Àõ•’+3MŸòÎôˆ/ì­…ˆtB!í¸Aå†í3i
oÍÆ:yÈ”:ÊĞ8Ël;ÌÛ&yƒø’âmé §âš9¨+îô
“çt¸(<Dş¤ğk HE›C²n-%æŠùÍliœ€ÇØk¶k°%ªö$€‚ãÅ;eVì¥pÔ„€Ô	ÆëÅLğõr§)5\—HX:9	òÇš|wSà˜xè}¬E‘ä™-áêêXND4èÒúß—Çÿıp[Ugd£pÜ}¥ç	ŞLœ®|›Q+Å ]7HO+Šc;s³‘>†âúƒÏÆ‡ğÄUt ïÀl‰*`Gg³ˆÍ=ï˜iÒáûÄ9!Ôñ­6ÅŸ8®7!h]³&KÆÌÃÆ4w%…2øƒVñ£ÁÕsÒô„H3glPj%—Ké¨Q¤ÀÃ­ÛÿQ“ºG*óòF¯…ˆ}\`iES_frcí(á›ÂbÚZ¹KíOá°Dq¶ÃI5‹U¬«»6,M= Y¯—òÀÛL‘"ÿg%eD{5â¿Ê8*èU·Pˆ«­iĞ¥ÑÔş£Û±÷$f+ˆlÜY[¹²¬¨W?Äşpö"ªÂqÄã‰®Ï»Œ§tÒÄ°£Ç`H»Fk6â÷–GèÑ³ùl–^ul²cïœ€ã¥sÖ7>“Íß›¯râ¤pÍÄÊì×ÏAšP¾‘”ø˜¯Y2¯{íİîÄÙMa?ïÙŸê»3„BŒruD•wà?.Û =VG#î*d•ã‰%Xèõ£^‰Æ¹ç ó11ov]ağÙ­üI^ô~âGDhr_iÚš\ªßÙ³Òı¹¿ºÉÕ¨°¸a«óhÃ}âZû„ÍÙbæä—!¾][ï‘±ÍS%ÍÜ¥d³hBuU½ÈQè²Ó°ÒP¤k£\»åÃ¿Ìwş|Ø'G;òÿ~5¸á­Ëé–+|ñóE;îŸ‡á¯¬öŸy€"gI´+jĞ–S@@4ßPæú2»¡TÑš[Ó¦çî)ë4úğŒUGEáXÓ*M¡hÂ8”ğ£—©h#†6ø²C;.ë–ñ/0ªòµòıà]fÊ‡‹ÿ•”ŠÎq…?«{dÈúˆ®¯FµGgáb#±40	‰ºÕnÂEvú¸¿ÚóÅÄwîq"ëÏ‘}Ñ¬QZœSj¢p·À %]§ÊÊi›‚Áâà6·&•66Öİl Ïì¶Úy›RÏ®Mè©ŞRFöº§Ù_¹ÅÂ{İ¤!Ú…Ğ$Ø<b)ÓpcØHI–â¹jœsNİÅ5%˜W¨gÀã_.Ê|ù“>.$õİ*&2mF5â6jÛÅsXp?ëŠ=wiQ^‡Øy­l{¡ÿ—)á`ò5åUÛ«ÀÁpz}úE!•`œûOµ­*]¼{Ş©E‚&ÅW!k×´(¬å‹c× CÆ‘Œ{•û(­Àáğ)Ò¡ƒa´õÔêA¥Á8³8´Înƒzqô)»†İÄÚ8Ö…¹ªñ3Š™P„/ámØ$¡†Í(ŒÈ[rİ,iQ#ú~u(6L@Mm2#û[hÑÅ×qÏÖïÒ#[Æ€Hn'Ü†‚Ï°}Bç´LLÇr´‹÷Cw›W~ù"Ò·~Ø¹Z†#ì©2ƒ;ÎÉdšyk7†=0Jì~ÆÖR2!ÖØj:"}¦ö,ö‚5ÛÁP}xb…µ#ƒoTÉl´îŒù‹:ñÓéAÔ>Áê'Íy:…–û³|¡¥»êŞbù¢Œûû¾~QßM¾Î0z›X¸³;(óÇúEBxgöø»HPäº,YÂÎêı‘‹Êwf±{6p/½"V¸×` Í<xcvejz“ao©¦¦òx]wÉù™ŠEN£€Zuqó¤eÜ‰ğ€òÀ\'A>gœ+ÃÛ!×§`F$YF!ç5À›Œ-‚Ê]¸Ãê§°Â‚Óa“fh0ËƒiéZfÀ,Hš zZ[r
;òl×(¢ªÛ&ÅipğEe¢‹ô?pñøáÊG^^¶mXR8³Áq7©ï‡MÏŸ‚¿Ì|2 éòK±87x¬Cy¬¶‰[N%™h»êÁdœ¬¶KYÀ„l`r’-]¥PÄkµ`g=|YP||Ø†¬ëìí 
E+Sm»lGâ4áşœï€à3®6Ø­ú&–`lÆ¦¥#qŞNß=œÎ`ãÉ`]…V\[ ­iaaâ„–¬±óÑu'öt³ÆâWzpŒ­µŠNÚĞ±ÒÇp%àÄ4É†â­¤Ö?³Ì5ë‰i‚öÏŠCçj5… ¯sqêpmŠ—ßqÏ„ñ•½JL¿È%ÈqÏÙk7%\)Çÿ,~Úò½ê&Rrrÿ%©¬!ã:‚T"48ªª‹KÕ“N¼ŠÜCô¬/:
À•ä)£ «(DßmCD?%dƒÅà)R'öIPR?)ûG’°½É©Ãû_A¾ãø:‹~íb&~€ŒA[­Ö•oÃ|ÙYJ,1Z/¨ég¸¦®¨½* jCò©Qj'Ùöô™©“J4òÁ9Ä¶óÜ%·C§ïñ
Ø‚Kélè2••¦<Êd8Š
äáFÚ›Wc B½C`%ÙD>Höˆ1ÆCkw#8Ù…ûV©ä¶tcƒÄ±G9ÆxÇèã‘+³ÔÒ©>‚Ó yQõ’jœÖI»Æ°Ùõ+Ç†"ê‹+}Õø¡A8Wê¨v¼Tfğ±N.É º9r}âİ) ¶’H!§q;;ÜËhùE¼å¾Ë WNèÀ‹ŒWâ`!©	Ï\'¡|¼='œ¬Y¿}H vÃ™5›VƒÄ
f; ˜=	fÜè#UrQ)½ÑŞ¬•z¹&Û/vòäl¦š•ÚTrÁÁhş¶¹‰ˆfBÓmE3sIV³Åñ–9ùï´‹²¶f b›€çmA—€Ú¨B‘ù¤¡hÙ'â”¼‡•ıW1…ftÖl|Ë·2µM+%İIøh÷é’^¯„ÕŸ€l¬¬9å¼UĞ+Œf^•êÔ[ÀòDÁ¯$ÇG
	'7C¨¤ÂÄ&ù1tÜÌ8ÿ=#B(me’ÿİ/¾yúü„qÒ’­‚÷ñİm-»İ¥Çµó
¥  ,Ğ¥ğKp0ª:˜´Ğ*N¥—ĞMH£hA04Kvöì£Öãu1‰Otåk¹v{é×5‹Çm0¹9¡5L^2q*Rß°üjú®¥®®0"ØAİÒ?YåAœÇã?‘J)_VºÂÙô{(‰™D6n]"v•^`ëÎ}Î¹x|e.ß›tŠd/É#jÅÕ`ÄŸÔóô1:ƒ ³vT2¡ÎMÂÉÍ²œ±lÌ0l¡/OÌdUÉêU7ÃHI­¢§u¬¬,a#çVÚAâ¯h±•†ôm¡<KèT¨ó”Ãèƒ×—4ÆhUêÑSy*/Ñùš;Â(ìwìÊÑïZ+³óù›sõ	¢¯f,j/8°FPYkîÆ1JÙ~QP‚Œ.&ºJâ4?ùH©Êƒ…Š´tmhíV7õO á,5ÈÌĞî{æµ——N€èÏİpPñt¶agx{@>×„¸xÎ.•\¹4½ÆY[p¾³Ù9©z%ıYÛ^‘å‚ƒŞJ†‹]&¿‰ÜŒ…÷ôÛqI?JÑ+Ğr`•ü8î—È”o¢ärßO?Ê[Yl.›ĞÙúYkıöÒD®4æ=?GF>	œtË6ìMw]tDƒ=1©Ïˆ¢Õ×9ì¢Œ\›ËÏ¤CˆªŒÒ{–UäX4êuP±U›$¸0P$È 2—DD›‘NvK×'û€şAƒt©ğ)äöµ`¤»4ækâábì’+şQ…}®Jn˜¬^¦½øÚW(äZÖ,#$D…£Lzï¾Ïğ&ƒ‘îM{t—ÙçSØÖ®;"Ô8Ìš«2#¸Ø8uö§AS,/Ôşœ÷hO3éwHÏîlD(y¶;aïo}1¼êò-°±Ú`I,]á›†]>/ã4mWÓ‰ôM@¿)(şe
8ñQâJ—ÀÇjŒ{å2Ïè–¿u#xŠ}¥&Ë4=FÄeµAfİÆ’Œ¤úqŸèW¡‚àHÑ—(Ú”{òÚöÀPâã; ô¥w¬—+Æ¬~–ÈÃm¾Ì­D25o»¤xtIjíñ71…/Aèlİ|wÂ^j_n¹et8n›T9]æı´$Î–İ3p°Äb™µqB5EÖ‰$nœpªË¦„Õ±¯ZÃ›IE>fŞt4¬øÂå§i4Œ(2wñ"T­eâ™•"·/µÁ‰®ÙÊıcãc+İ£Ëã€L«¯Ok[¢iœ˜Í ÒW@ã$ìbx¥€gGP­®t`E/è¾H2Ã7l±Öà„r‡¾ŒŠ© %ìp¸M4wË=½V'2U°]÷bEF÷ùæ´Å]^Æ²ÿŒ×x|ç}^±¦íöVF>­wŠUjKQåÖ2|âR<
ZÃØ6 ;Àe` b!£Éºõ9\ˆê×à=õ_ñœø`^,W±ÉÁ5@ñ/Môë[w¹Á—Ç”zÄ·ÚêÊ*¯ĞãRLã:F¦`Ñ$$&SùI«±û×¸ø~è”2©Á°(6§ŸøÚŸAWcèZ—Õ)×W3ş¹v×î³x£a©«`f¦Zb^	"­%ğÃüi4}¼a³—@ÿ™Û@¦~ø†¯»E=â®ßX²¦œø.9zÓ<Ñn­CşÀ—–@{oÜHhÉ.<˜\³¡³ÔŒ\­‘¥ªg÷]$Ä¡WëÇ3h¹¸< ŞM‘ĞA'ÆŠ„3>$ú	5ñ¯RCHàn˜~2ÿœ2ıòyıZ@Sûz6ÒÿfşµfXõì1.iïè!'iö [G¹·ê„í…@z-:’jhÚ'u2vhÆ‡+Ó¦—W2ìüÔpÒ•ÏŞrš7Ìæ4Ğ~ı½­<¢ß8ZçZĞ3L`ğ,‘/£#Oß †%FŒ½Ä:0»zSJğ"‘©qî5w (}İ`,^‡ºş4ÕçËv¤¬l¯ºãYäxŠİLT0Õø˜d°°ê#ê
#º¬‘@uÙ"¹iÏùèG±î¡órîQà4	õ[eŞ@ü¾™}YŞÍ.‘6ƒ	î¶<XTÎé(E|/ÿîN”œ¥jÖ:åàTÒTä¿tg¸—Wg6—<ì¿6zƒ¾“‰Dgc;¥Å®y=ó`Š~>'—‰9
õŒõ a1Ùİ2èoª·R Ñøİ—ıZ?	İÒ,mŒ³×­«+z«Õİ¯}«ŸÓm´GPÖ×š9_1Xº5i ùÔ"ÅvÚæ÷LìuÜJjïy+ş–¯Ecå_»‰,|ò¢×`…8'8]­)úÚ&^^içõ¥Q×<‰½MY‚IÄ	M{Úr²‚¼˜²t™q,RpÊûUåDD„4Ió/øŠğœÉ ÙT†·nö£<±ö@Iyjšß©ãÙ£D?ñoÒ; »Çêƒ-úƒ@!NHt”.¹#h91g;¬àwæ]=ÆiIá“nşúG. s@Ş.*à¾g «J…«Xi>>kQ=`ò›ÔB28/¤ŠŒ{€§a›=/DÕn“4Ü4‰ŠĞ*0uğÉE°©kA'#&¥Ã“3A‚½Èw¨ñƒ †Veâô×Ò¿miëÊ¢t‡ºFmªŒö >¨¿›b.À§xR{"#qgH^UØFµ!äIæ–À%¥âé
M¿±‰”­$ó÷•+šèÇš*<‡]ë;şobîO‹“K~òw€àöÈ
hH¹ZÃ‘"u#5]òOÍª„eõµª¼:÷ûæ¦pDÛq ¯'¬TSi
+&]Fï7A7:Ó3J¿ ¶øVj"kìüğFÈ÷Ë'xë­ß¿Év9a%TŸñÍe7^óˆd¿šûèûÇåSpáà›Ëå1åGØ£¿ÎKFQ/¼›š‹ÄUõWœTQ…Xíıd¬úAq5^Z^ªM™†j}âÆê‡ @ã5m]!:4š|¶›o<Qgº'd]¤ªVØGí¤Am÷a#Ñ3º›³²êÓ.6šU®\^Éê¯¨œñW¯3€"±Ã£80MàÎº¾™‚‰´ÏMö}Ïìâ°H‹( \ÖOÆ"ë¼­KÕ÷ğ£nUal/q‘a9FRõuëÀôpkÄ¢ïáğEµãU4ÿÀÂ
·0øæÂŠ|^˜\E½\}ª¢v2ÂªEPQ—&sÏ‡q—&‚”Üh\\Ëµ:Û,ÁyvH&sƒVIİt‹Í³³ŸZéı(4xü_¢³UÛø›`Êƒ’ÇàzüTa¡O¼¿·åÿ»YÁıô3ûÀŠ¸Ë“êË)5Nş"˜ùH=æ¾›nOEÅ[´"ŠN#š3WÍP¥æ±— Ju…dˆíd¿#ÍŠÃ‰	6ÂIÒh;æYËQ«P#ßV#çF«ö³zH[”ˆA@Ùoèµ\Ã&€öñ*.ä‹[ ğàk¤J,…Ì(6†G«\m2÷Ÿ¶NÀ2ó,a³‘šO¿Vë(R4¤¶ì¿î›ò°ÃİtÒSóyA¿«²ï[ MÜÚêCëÆÜSéÚwuğÓ9‹·À.ç°™¡‰7±–Zä&jp¹¢™²œL„cÑ Ğá6ÉDìSÆÈiì¬ õG —çAìe+EŸ³ênİ}ıå(À«ƒÄ¬…ƒˆ·»•Zİu@uÖh&ç¯<­EY €¤:e9ŞCú$
mô]*v.ƒ¡óUm˜/¿fšLC6”f[Haš="ğfzîYÎv:I{:Gda0*Ò%¼Ó`¦Ef{aQóÆk™ƒÍz—nQ›[-ÙÇ-f$Ôhlª7¡:¨=ÊÉƒæ{	Es¯¸É»^ìè\	m‰‰,_¢¨„¥cÃ[¥[°9á‰Ø
†—2¶ìçıœŸSg0P(1×œ)å£íÌó­‘¸Ÿ
xˆÁİ´ïúÅş‰&8PÛî08( Õ™–|ï&»X1]±;?p‰ …¹\	‰	Våj®Ìz¸K—Åìd“]Ù0lÉÍ@q    @òƒ±·Ù ö»€ÀÔ)k±Ägû    YZ