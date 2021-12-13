#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1998190382"
MD5="9ae7865bb916268f1b8b962f7cb821f4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25536"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Mon Dec 13 19:32:28 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿc€] ¼}•À1Dd]‡Á›PætİDõ"Û™ÕQ/İÓâ%âÚèp\Ï¼ñØ$"s¾Ãõ»2Åè‡zò%:Ãİ}–Cş@§Şû³”ÁIÂÙ1ê4ª³øñ¬Ì×'P|ñªÓã¶\¼AS7>İÌ®fsî.­CƒŠìØ?“ÊöV`¡×M‚PL+'–‹zë|A6w¹@QØºÅ„áıÆ¥#y¶s0EFŞÑOÀÙvş²¨>
K#âhwĞAÎ»¸çá{'DØhV?ğ&ª…zş´Ö›#& 2ç–h9êIºñ•'(ı–ƒ›¬d}.ì;ä¡ã©¼ì°`8ÙÅÆX[8Â½½ßçE¶Øb†¦ÂKˆÙå¹ÏÁŞ6CÙ©_!yõ=¢<Ù{{§áJÿÔ@Ä F[Œh¥Õ·ª–éR€°”Îæ¯OmÂæY¯\àÚX=¥;NÊë1PŸã˜'j¿ñ8‰R!­Ö[3­e.úm4Im ŒƒtÊ]ğjpÑË+±—zU¶%¾ìœ'ı2Zh¦[oäp¦T=úMfX8¢¦<Ô5õp›¿‰.Ñ7SÇ.¹< ï÷ÀbŸE\[7wPÎÔ~˜H`Ÿ%¤9¡,#ß	,–Å*‘Å	mÎÃcŠ²§hií;ÖŠN<HÌ•}ª>µ’*ïİï¡î=`à®¤ÀI<´ïg6‰­b·¹€h„4¦³È˜Æêÿá¸Yû2å\U¹‰4{E}Ö9]Î‚©Ÿ|¦Xp“³„­aÍÚÛ…|×-ƒ;”Ü«/`CÔz‡÷.°Ç(æŞR/o}§oƒ_ü€ñ:”AF3:…Î0/x`Ùñ7wr8‰ÿù¡1Ş¬¤:Jõ‰0v (òtÎÊÅQcEñõæŒâ!×‘°×b¯·T§jAº¥Jw˜ò't‚Éİ5ÿ¥ö‰\ƒÁJ„ñ^ğ7Ğ(Ñè®u™´P"äa]Êâ]+(Ç20©­¥¯”û6^¤nV‰mµAÑrtvr¶ñ«ô™Øé•­“=[·ı½q‡éÌ·ô’ùÜw*/,õ/®ŒÕ|Ù+-Ec>Ó •qÔöü–=Ä¥+!{ÿÜ,ç)È²úRÍ"V7“U™ìèX#qªch…FS¶ÊLNÿ’ñÿÃ¯–Yÿ‹Ú‡gõ^yÖ÷"'0º..Œ×‰”­Ìœø'í0Ä[Sß‘4Òì­&ğì‹ì¹ûi$şßkJ_ògà~ArsK//§&ï€àæw•v¤llO,QÄÿD±4TŞ2™Ğ½EjÙ«h(,ˆ()^»ø?"Yz‘ö—&ÃÕp:ŠŠEV`e¨ü1&nÇ|‘³ş·û!
SĞ¬q–u]†Ë¡Í†(êÈgLK6
¸ŞÈ÷K°i‘áR³h³±ÅFR¾.×ºëˆõ1„1‰…*$»Ğ½ªG—'¼ËÇÒºÆX"ãşô›HÂõÍ*€‚À¢ã¨ßa-öQ6OÕƒˆüDáÍxC€–ˆ…†Ó4³ô Ìé)•?ğûeË8M€Ö•.{ñ¢D`=HÅê½Ãh¼ğ\ƒJ'<Çe´˜ÂOØ)e¨§‰P¨cÏÖº-SJÉ†šÙ	¦b4LÜBO‚Áæxîˆp"bhÿQôú¹ 'é1€†Ñş«1“vÜ¢ö¯!İáß÷Æ¹Ñœ¬ã˜¡J¹
BêŸÈ9¤ÙÓ¨ÒÖ6e†Ã™¯9Í-Ø,	÷à“¹Ÿ ÑûáÒ\‰	ì@“j4µÖ0?ê;AEñLI½´í?4°sóÇX¥E;§¦Âf|”?è÷£ñrÔt)hI¡÷rÒ‚f›ñÿA6§QNVŞ%áÙr¡ÁL.xnËFc#rC—8)_	ã@µ®VmÚäexÓl*nÒ£Ø vÀÓB–w7\ª$u8 c¨€kı¸PóFå¨bE2uáÆ_¦é5’3³à0ÿ¨/¨,.¡.)²†¶Yœ{²†«ó8ŠÇ<QµGÒ©ÚíCqSLÅRéVÉ± ô*È´KWıÀ“Ğtûy]hUm¨XT uå±lí¤£S€+2İ.OV¸B–,ÎÕÍ©ëüí[â¹	n/3Ê¡€92ÔZOÊÁêL7ÜÿöÄ½>¢XÑUr&LµmJRuL„EÙ	 òé9“ìñ¼‘×Àÿè:9Ú¸ÚÜú!$¸piÉiáï8aHRM!µ-<µy,¼¶sğÆQãe­'–w@hæƒÏïÓèÍ¾ü˜,€İáĞ)máL P¨+âà  ¢aMöå­»5r³•=EäXgRço3‘††Ót8Xÿy££kZxşf#7£±uÖRDÆäË¹6°v¦‘ƒ)ù{3j¤E	Ò®ìAı<å	º1l=h“3†±Ê4µÉ×;‘\o‘-ï‚{„Ç©Ú5ı›4¨.dëµb’™9^ÛEó4AŞ³môˆ]X’Í
4pÉ™ÃMEW1:+]3ÆîgĞ
YèhÜì¡±É…Ê†rİWBê±Gğã­©¬Ë^”}_tœ-ñ/zdşÅ­Æ¦ÖĞœ$?B©C`Õ˜A’*”@¿™U:>[Mª„P®wÒQ#>Ø¥ÛÍäÄ>Õõ,yñÒCôÑŒ3ûA4“ñ8Wâ C¢œÑv;pİŠŠb¯Î˜Ü xuê¥_¿îÂbI4
óëÜü@‘¥uÊ¡xre›ß N÷­»V°OÕç™¯¤ÙBÜ Î #úÊRÛGşØ‡˜Ü-‹àQ={%bI©dW:QqNß
€2ø‡ØhZ)æ<¾óG1õğ_Âjl¿t«îîŸ%VuF4âuı xÁ˜É£O‘¢@Ş]4g{p2Ğ‚=ªŞ†®¢
şlò†ïb¨Úê`²_™º`OóËíØvÜ¬ˆVáÏyõe†Ï'œû¬]Q0×ß!8tİÆµÛû‚ğSËPÕƒë½;´x8Tµ…¤w`ú¡Âkâ´_(UûjÒÊõ·C¡¢,z@•!Ïlè3skü'Â4-n£}UÕœ3işi¦&×ïŞ +¤peH1¹Mí¯ä=¹©&À]òx§0äë™}Ö@¡ºl«´ú?WHòRˆÁìSìbß}ú¯4Âsø19Ãs +G­[00{h" >Uÿm½W¢EK»€ Ø‚Â´ù‰åd£èv”ïs/6½i„l¤Ke2>:ªÅ‹£øÀ#´÷@jº•éºXäò‡^…‰J÷¼u°Ÿáp’Z7G÷:-†¾ÅõŒˆr¸Qs}üz]?İ)ÚdCZ€YĞH¦Z—È×)¹LN0¨y@kl€>6½k¾ie(+Hê²,-ÇÑÎ;ıÅì›‹Lğ{Õ«U5nDô¥ŠİïIRŞ*}¿Úvª”À¾Üäèà{œrĞMİeâN‚¶F’¢E
T© Ï‘€cÓ7Ãƒä$q×ïipØâfüÙÈÜ^îæy!r%²kÜéÏs¡S2 
…!ÇÊ|UY~G7r+¼}{ÊøñAŠï\Á
˜¹n rİ8îKš»q¢<t§h@¨Öcs~mB¸†Í¦§½¹Ê áz®º¬.À§Üµ~àv¥˜­Hé4q¸ 4»½k5í2xä­Ô…·mïŸvàíW†Q,óef¢©ŠÄ¨kUşa©Ap™p—˜»ïŒ,¥ÉÅj­ÊI~2Ì—ŸcŠìŒ
Wme&,§M[‹+'‰¦ˆ„h¨]¨#À©ø°ÉÀ:Íçµ>9|–zZ–)Ï¼nPá•š¶#Y€ô»¿¾:¨Áq¥‘"ÃX”ß]X¬Ñdà,3d•P;®us.(á¥²Ó¸¹ù¢±UÊïéÔ:„Ëú²›ÆˆÈøØŒTüZî•»@/©ÖWH×/ƒih óÎD‰—À!¹ÀN
_æŸä&&¦ÍU]ŠüÿD7öı‹UÈC	 Y? ÷m2üÀ:®•uiåşS¶•ú%®¿M³äã";pÜíŸ£š_3Šõ–«k`Ë\=g›œÓ9êU‚ÕTÛ9>6Â¡4R+¥ïÎ<OŒ«äkn(ÿ›•²h¥~›ÓÃ’.
úb½¯]WHs)F»C€QOã‚x'+Oø<°Öı!6x}´W5p^¿å“Ğ
"†daRLÖO£–ĞÙC[æ}C^	Pq²8ãû •°u4ï;ÕşèÌçWâÛXjåı
òû§cõ%éCÒ<&ë‘·íå0š`^²}#"ßóCİGŒ³¾§×pÀ‹¼’<dĞÆ·[/â¦L˜‚ı•!'À«´ÅéRÜÒcNY†3¼‰‘íT	9— é”²kşhp¿ØÉOí€t~e`â”ÅS5C3”B2¸µùˆğ™Âç¸­pàç×»ÓìŒú¯åa\U;æjï¢ôVŸK>¿8<Ô~ˆwp²Vİ3&LîÛ^’İµ5¾ùö:ß¨«nŞm¹ïxÜ“ëóç£«hıÅjõ€VüËLôºo"%<×kÔfÿ](OÈÃ‚B¬:Ì^+¾5Ï† ÖÒc,‡g:®5ÓüyGd×"ôŒ}šeı©› u_´İé­Ñrâì8BA"ÑaÄîÔ Piu´ÚAÛ]½Ÿ¾ŸĞè»²–S¥3›%Šf~gÅ¶K„/ÕÑMĞ¹ó›@Ëc>¾¾İş÷[¬Ÿgºß©‰c§˜{]íN_ìAÚ+ñ]É°ŞÎ€ã±Ù¯¡wÚpx$Ø‡¼Ÿ	çHE‘ŒÉÌM0öû{¬œá´÷µ—"¾¢;ğ³,8ğ«úş•×1­¼€2¸çL¨N—ƒYó)n† 7u,%e@I?ë¥§ÉÄïCh‰¯cĞ¶ÅŸmRasÁï¸(!ørÄÜç$­Òb%Å½ ƒ±$†ˆ±i_L\{PDÈÙƒ¯pD6Efß]s.’$°„{ˆj{Î·Ï|ğÁÀøÀ­Qt¾çüh˜ïü±±ÒiĞØ¤ª|gÉ)¶4íšè!|³(ç¿ÿğÆ?ÏèÚ¹`„†PÕ,Î«ø+úûfˆ™™¥…š6št*FÄxûâîğE‚ eõ+TWsè²˜j†ƒME,Ñ±ö¡‹€OWC
÷5•Şy J×ÒsÖZá„Õxìû.ª*ÍªAYcI±é¨>Ûkî†ÉòÒÏ]òJÇ4	İ)óüE¤Bq<AÏyÎtG<Í"^XÑ‚×Tó±g¾Z ÄYÑMÑ:ç8é5õñ¡S9ÁÆ†õĞlIÔinksaº“†ÉâcÊEBŠ †º-ıRÑÄ`‘O…‡2hS ¼{lÇ‡Ğ+»ûŸµLhì$ªÓ^ûÔ1ƒó¢/kk?4H±Ó`àô~	È¤n9N’YÉb¬¦¸Áò9 Ğ®”Èw!D³âc0ÂÇ‹VĞz»ê9Î¥x²ÎÂ·vŸV¨{àå×6¸Wp ,“µºÕen¢’ÈĞxu¸ûæso‚¿£.ñ¤{¶vÂ{ÎÄ'e#kÊ=l­%®¥Ë")Çâƒ M÷2$æ\€0l<Ï,+}haz
™DÙ¦®¦â=µ´$FwP©™‰u^H6à›IœT“øÊ¤<¥ÔxÒ%ˆzI#³™
[-ƒÓ]uÖÆB£ñ^Ñ1!ân¸–ã úÂÌó ¶·Gj¬¤‹Ê$s”n8p2Šµ,oôy@·x
v€ÿšF­[¡˜¸õ1D¼¾ƒ|Ú¥E‰Nü]kãër›ÑÚá-}˜üO»¬‰#&e°w™‹Cz)I>šz¾ğ&ØA°ç—,Ôÿj(Á^%jäÏ$FÚ(M’äjôU?µˆIM¶îÌ,£ğÜ=ôù~$Ÿó]şJ*³m©¾&˜nAC
Òq(ø™NĞf.yÊ/¶6œ[‘täÏÅUWò›Npß™ŠP94ägjzá8#aßd`zØfÌ	ËM ¶A6÷y¹áJ,&‰¨l½%D¢exMó¹¿,9Ä€ †>§£&1HB‘»û i€·Bk.&XJkZ.ØTQ_Ç;ª¾KMI¶1€Í´‘G7¨AÏW¾Ş2ò_Ü>›âÚ”$³8æ°¨FíQëöˆÒÛ½9ÅÕŸÅMx³ùÉ¹¢•r×4?{ÓØ™r¡@¢Â)«I_‚ËT]¥¹çºkVıTbûÙÕ šıÛK¨ÜRçà©ÂÙ7îŞªkõ1iòúÇ%¦„¶‹üaÍäß»Íx"Òî†@z¹« 5Ù×*ïÉsuNWV½`&¡yY-ƒÿhºPq¿Úå•òö}o×,r~’Ù€½šÇAQ£uJmÙŸÚ_Y›8…º´$Á¾òë·æCä>Uƒ‡~Ê$ì}G»‰B½²¾/š—ò¤‚…Díg¬Û§‘†X:(¾¬ØW'+øóÌ."¡Ñê»KğïòyJ¯>[ 6àHhÈIzğk@è¡)QÇÚ·0)’4ŞÜ„ÖUxŞyu¬é?ê’ÄT¥åŒÖ©ÕüC÷”œ_cìÊKÈì¿<#,UZÙÊ•!øC	b‚Ø¬™ë¶ÊSfâ;[Òz‚p…Í8€FåÀ)ÅBÚÃrÍPQF&¥·ÎZÀlw˜êBøwR4\Í¢¸iº®ÏQK*Šy®/º•„f»SÊaìU¼®üfâßìú)Ú\4Z®ü©S‡I5Õ•R=ä·#‰¢0¶rÙm·æ@›—¯I¢Mbë¹ÊXÓ$Cí§ZŞe®4ÎaÊBBÙI“Á¡Çkep’±ŞòW¼œ}÷…±­¨Ej*>Æâ(Äôª¥q/ïHô=È†3V%$IHH6œ 
R8gš	ÖT'S¨ˆjü05•P¨U*<.–Å ¡è~±ÍAmë?‹·Òf~ı)ğÎJm_ù”o·™MœM,ŒêIhÓ O¼£¥6j$L¼&ı¬ø¯›/¬Ò‹È¸I\ÀhÉ„™tÑ&#z±ÙCÏ¡í–Ôl¡›¢xşà9ëw/ÛßøD1‡÷Ğ¼÷`5æÜÕªf*İYaBË!âéHÈm²¤j‚Å‚åøÃ˜²´€DJR¹tg!t0(ÿÃlc?ádÆi÷ƒòÂ01¾FkU#ğÑ}/U¦ç-MIğ¿DŒåbI7ŠšCÔòªÓ—êyÎ¨k¨UW³¦@u½ÛcùŸåYßnKsE€›¸ßû1ªÍÑ:)ì=ùßş~ÇxÚ[^û¡<È8ø£7§C0”—vä{^âç *ÀDn#›#!É22dUÃ—ºs¨TÛv^s€ybIvàDh]íD­êÚ’™XmlZ×—ñ	Î¤~Ï´†j,¸rB™Up±Ñå—bÆkByH¬ŠLõÅÕn¥w™2oÍe¾ˆCù#×9dˆ¿0‘Çg–Ë<óD/1Ğvı8PMu«?WI)«PÖZàÖ¾íOëú Ü-FD•yK§t›â|,üS=_¤Ax”:™Ã!Õ”ù—wpk7u”%Éğ¡Â~0ñ/AèÊáùñ…F…Àw?´z%€@%¢aA~°ê:ÒmŠ9%8êO¤RM™İñô7ú¼¯""Íö’Ö¬O iÙ5óé?y:cC°9¾„sÖ#ç‰Ênà˜›Q™lå¹sP;Ê2N”iŸ±÷T!\ÏUFŞMP~…ÊS/÷İWˆrÀcoÊŒÏªÖÆ]}xJ>¾Ûkd‰J1(tİ,«I”™I<S·¼búËå$)¹Ø@Ï‘‘ôF—ê!‡à‹n^Œ‹ ßm	5
™ËÂ®Ğbtâ*à½FqÖHÃ	ê•AÄì[5ìÛ>óˆîóéğpx@"şÙü´¨¬éÀ#°8–ÀŠt€n´ºTĞãªntñ‡R¬Hn±ÙKë¯¬ş*—Uù°ïEØÍ8~Ëæ`sÛ.GãTß¹kúÎ2ºõÊâœaŠâ aÔ¯Æ?L‹ˆ‘9ƒ"LİÒ€‡‹2APÊ§ò2ÁóGm¶ÙšÜx‘O5‚_¤g&N,û!˜ œ¨/q	xª ]X°˜†î|ëk|T,Œ¡ Ú4“ÒEO˜h} mÛ­wXoƒ)vĞlUÃİ¨m–7¢` X@«DúqPÎòÀüFä]¨¬Fı>Ğ¬ª˜·47ë¯êğr—…İ›Ôg_ã1|‹…¶ßğ¸µvûŠ‘cò’W…×?€Y¾Caêç<Ï84nH…Áş.‹ùRN;ñ&OÀyoc•à³š9mÌ’ä—ˆÜŞ¶(Á)Áa*=k}DèVÚ¸ø½lfª¬ù¯ê9—Âî)^Æj¨Nğø0²¸âE‹ªq5˜®pgDÄfd‚é/ø*ò€$"H¨V´0Õ~á]×¼YVÉ,wmî`“U&µ“×ğçïzo.‚†šEu…ûƒ·8–æçß¯¡q0Ç³ñ!»òZà †°e8õĞ{‘22L¶Ä,èƒI¥ÇR×CüLœ»ñ•|-ì„Q!œíĞğ²–!×²F\G:FQ}²z®xnÖ­Ãü^©@VüzhãcÒóp²¬¥OjşãWa&U´†ºæV¾î±"Ö9!0q(AÒèõV	–;Õ‰–üótíŒ‹gH±!¼©@’Çç'ûÜ¾ùó¨û¯¥Ø&À˜ÈülŸz¼ÜU®kvÀ7úƒğwl²a	ûÃ™ò¢³\Îu[YÎĞbr&åÀÊ Ö3ß	Tö°‡eÂâw³|XÂó§GëòŒiİ‡ê£¦Õ”Õ{—Ò9Ü, ^r¤Öè¢§¦µ#ìCBŞå²<ÕâÙ(šäV3R`q…©A¾t{u®"ı¢´¢fŸntºÍË?¦|Š¦Ôt¸'H®rZ[VpVG¡857®‡GÖÔQì*0rKş@ö¾×Öä!ÿ!Gày%’oa™³l+µİĞÚ™"?–y	Ú‹ëgQÈÂ‡Œ÷—„Ä'Cİœ'½VÅA‰Í<>s*’/4…¦Œnÿíc‹ÜSd“Ğ†EFè¼kB¹¸(mgañ>D•%	‘ö/2ü1œ7ÅŸ~Šï¡LFIÊ“xöà†ÇíéMz¬9€àúF#Œ&è²ÈÅàïúT	×‹${æjiO»ˆ:…e“îÜñà$šı$e™C^zW":x2cƒ0IsÏtNñG@ÕW‰©_fûˆ3êZÁKèvS GQˆØòÛ*}Fw®æ(ÂêrhäµHÊ–äç°0·*@›‘Ûb¾´&ŞS£÷›f´ŞåÛ@clpæÆk*l»)z]'BÏã„‡Ì³ùqtk{¡g½Âùàòq_3ÏLİÖ.”~î¸µ'I—1|4Öi_P¡Îb¥ä­ös0•§O“kCo®ïñaR—`;ri)†6 #Eº«ıRòışm…¾•üØ`«ªiI¨—‚s3Ÿ.GÉÏ–ÔÚ=(<+¿”ıÖğ°këÖg*šäÚâÓ8ÃõW%rû_‘ G\Îû|­ti4µ.ªŒeùôŒµ¨Nåı“hhtÒÖ °YÇ2´À‡,Õ (@ƒÖ¨*ØÙù—ˆ/ƒ/1 9t‰*3ö4¤‚tİÎŞdjâ
ÕVö’¶eã5“^T2•"šJr@~‰Xô=mT‹
ÍÉ¸Úë,İvx“JYÍ R¡åú–îÖ#bŠDŞNîQ­fØçz°«­Á…Ä5`,œ6/!àƒãÛØE€ªòƒ['·CŞ%¦!ôœÃßÑøS:Ú+¦wÇfÆYévŞ9p–m{mlYÑH£D¯KJç!µ´á.ˆÈ1²Å¥Q½ëĞ$°xÍSÎa¦9¸;/­:‹ÙV.™6	Úÿ”Ò-f–Óè‘ÒT³5Á]¸
°˜J¹ìÏáRî½üÏf´ÄlüÍÁºCñ,ß•‹’(è<³]úc85Ù—2TpŠÄlÁÓõ³ËÒùÀò:©^ùÍùòµìÃME´qÉxŒJÔÎA½¦˜Ä‡¬¨<¾0¶ÑËåa	¬šÉz¢ü­Ú¹iAW=ÿl¤È6_Zàğ¿ßºİºtRt×7ƒ¿½g|uI #
ıJƒ*{Í“A?¤gzn)²‰B~2YøĞ’RÛ_ºÃ‡ÄIIGØ9ydğ« Â«/t¨ p~ Ÿ‘© Hš‘P´mX×tÿóü%˜%ÉU~€Ç¨!œÙÎdXêÓŸÀÉù„ì±Ï¬XŞjIë„ìÙÖ¦"½næSm£–Bæ`&¢:øíF}¶İ£ƒ]È÷ScÉœf3«¿‡-8ğôìåL:C+4iDdÿøæ|²¸ï«Ãø^Ğø¥¢Ï&T6#vœ£ªÈH€ë.FÚÌé_B0aÇpcTËÒk÷8sşºÙQ¼néŒ¤o:ÌÅß['Òş«ÄÕYasLA2÷²ŞHZåúnV›2ƒÀIZ£ga…›ĞvÔÛïÇÚhtk÷)„CÍãş¦ÍÕœ *ãgáRBP1ª€Â`İ'ğIŒŠ«)ÌœD,bˆ»æË!îu¬¸9¿Ğ}@øK–l0*(w2£8mhbN`†M¨ºÖ2ş£ä©¼êF IiÇ¨A¼dÑ‰rû¸¦¹)RWîâÍ‰ßë°	0wÈÃ]§Ïº‘Şw=#Ï <#2`Ş|^Â‘¼#6lİyßÁ\*ŸÑã¯œ¦hA/æ^CÖQŸï{!ø$o‹=r´Gí—ØO@O]S)4ù0¦Ht|ßÊ¯Ú÷±7ï0°&ÆñN¨ÚÒÌ£).è >ş›æ…IVYq¯ÁV@«&úÍşóä`´jáq‰>ïoë	×#ÉÄŠceÅåò¢ü—k Šö3â#R?¡ÇaÏCy jó/‚²<ªuù&bR™ÆÒ›f€Î€?p)<¢Ì‚vO|E-/@(E5z‚
L‰­gë€9à‘zC¹¼-İñ»ìT ¦ì=&j×7ÃˆÂ¨ÎáÑ	ÁûÜÜaj»lÖ²j
Šäºl‰ÙÖUM¬f-~é‚[/DÀH3SÄÿÛµğ(ØúÆ9 åŠ¤<»¾éùßµ°İ;ğà zd
Eş¡šr.(0ô‚CNº_¢¬­J¸É"	 oàºÔ~‘8}Õ¦l$òÜÀ2aº€”§§ô¢h’p0µ¥rêÂ…ô³ÈgN^•Íeô¹ŸØ ®˜L§ïº
D™ŠÒäç£H¾·™ ”q¦;ÓÚƒ[†ÉÂ.Xzér¥Z0nY±iµºT„Bî9±‰ˆ÷1v	ÿ÷ÄiYÚ€Åö¾×ÀÙA¶£yÆš¾–½¹
£“óm=JÄ†¯÷ÔXÂ–é>Íy„4y* ?ØŸç§ZËßÁ¼Ô*¸êmÕ6ÎLI69²óXÈİ“B?Ì5‘c2{d¬ŠÔBñÄëGÍKöúØ—Eg±ÙE2çünÆæÜ8å¾Kãû²“>*¥–Iâ‰_I
ÍrX=Ë¼MIE’ ½Öß†ÚĞ–a'"	ÏÊï¦Â¸šñĞs%‘lİ]¦¹ä=İàLÑ×kBN•À˜6)˜ÙDVîÙ†Õ‰·4<Íø Ö9$º6S3+áØ )`38¤bŒ¶to«.ç½şÜòh'¹[ò”Ojİ®áËDÕş‘ŞhQP dHÿòCCJ:=GøÚh?"‡15A¡8ìãJåÀr®fy^¶Lok¹‘ŒæbÅMõ^/Ç¥ç±IÍûÒ0ßºß*}*jšƒ†ZÊë,lÃUªrÈ	ñü‰lÊ5”KQì¥N¸çÔš"òêSşû°rƒd\äŸËÄ±c0@¦,¿ãŞ¼h%rOã§ºÍì ‘Øt¢H­M¬6ºùùx0—Ü÷¸HÈK.BìõsaÍö>³ßßúš­äy?„( @5N(îN·M$Üüå²J•=ö^v½]«Hs5Ö{mÄ”Œ(İ³~ı¶`µâØ°&Ş¼GDİ|ï›/©™y¹±FiÎ"­:Ø¯’‰ˆşØÑÁeF‰ĞÏu·¼E_ƒM8~x82Û¶SN0rlÔµ¼ZmŒ ğÃÍF‡d~„X¾pıe·İà2¼«•éÑ£8ı»}z›”‡å(1èÎÜæM@|J§'V·x:·ş9Â £Í
…JÍÅG=K
ŞÂòã%Tÿu,,i•këîí‰%&Xâ;ÃaÂäøÅlÛî}
”§úl5"ó	İş?Çâo:£e€úĞôm(¸)Aj&8Še[K\ğş¶uõÆ‡+Ô)1Lµ'Í]< »jåÚN¡TÃÃìF>Œ©H–^¯bÕ9ö¬i¯9{¥à 'pf¬ñ~jÉ¹»QèÖ0‚õV¼
i;=éQˆÔÊq¦Ù©ºT%™«CNÖıøæ° qVñ~ôŸå95Ïá.>¯áCË„]Nóü¢«®+AÊáÑn÷T>£È_
àù±rÿÁá!j{Ê6³H-O$ïÍÅo%kA­ï,0ßİ¦¿ñÄ»vPÆ jšÁ®ò=xzãê¦Ã`®q‰ìYìÒÛ€4»€¶õRGh=ŠùC“µ®g‹.'ƒ[}ïâbAÓ÷ş:ÚDÔdlT4[3±uğäd.ï)í£ÅÖ'£Á$2=U6çš<ıê0öº„[_ÒÛmLHı˜º¤’>-aE„ÖçÄƒÂrK¿o¾%B]›ª…¡!«'ÿÇVeå.‚e—pár¾+C‹OË½H¨"¾Àª “ü€±š	Çİ\Yö «Ô?©N ;Ê¬ëJt_"uºßB?ù?ti4kÊı…9ô4od¢çšOzÏ6 À¼¼,vp]VÇ›¥z”qÍÜò8j”$Ø>x¤ûÓZı£ï¶Œ}Úæ¥Àã v7ZÓƒÊœˆÖ%õ2äšÁOÏmı-r&€fqÕïi£K°Hü/†µĞ"ØŠ€|( 6¥ÚÁ~ Õ±`yĞ—Šùı[æ¤"3^±eÆ±ÒFC
i}”Í¡bákn²P\‚½L}îõ7~ï–&Ìä•Üj{\n|êl(DştŸœäü¬¹ÿ¢†5Ñ¿,G6M(£zœé&|Èi\Ú/êPÚ˜Üşcêq“ƒ<XÄ[|=½ù:	Êï[ÂtÒM-ØïVq×kNòïR³o&ÑZ¢¤<SÕ}3¼²7±©Šü­aÏè}§Ñk- ç1S+<I+{İfÄö?ñ_U:¢¨½,æÍÀÂ×úaÍò—®V„ãÉmg ø«óŸù4<kß)tp=™-îı0€¯áøPÔGø"Û,èit<{.ØşxtƒÁ8Ü!Nß{|¹€Öñ»µª”ú[Q“^%}æŠ¼º"ÅıVI¬¥ÚAÂ™f¹’0³æØÅÒûO;éñ{üª™$šø*«¯Y&ŠåeçnE¹sUùƒ\tTd«$+l¦8æ­~¯Ø^ï9éÒ×›;<bvíöŞŒløwV¦9œıcÊŸP•ÃœN æ[İûöÁ$0¾öüH–%ÊÃ)æUV„…HÂ	ø&N¨xL; D#ÑŠÀ‹ªó {—€ˆRo?6~_f°"Uz^€ií²í¨ÆÅ—y¶bÿ´—¬-ÈËœ*<ıHL°Ö„C_Ş˜¯`…0õ@9N8M‚åeøŠ>/;’ÀK9pÓè‰ˆZV»8õ¶jÕp.H¨2Ô)OHš‹¨²¡Š3\È«°| ½Cç	a/Uzñ«i°9a¤mT«ÀT,M¤Ïz9wÁÙ:Wï aI®ÄN>ÙgpİÊÜ£H¢ş³cf0‚ƒ,XŸ‚Š* ¾ÄÆ¥Î³ıÎ÷?òËÈP
õ
ßGP
¼¾/½yºÍaWğÅ*ùûN7œ`ÂÙi@’s’óRi¦` ãg%‹¹¥êfä~ËTÚÅ@ı_Ac£R; NV¼	ÑVû‰š"¼ÍgÛÉ•œşkÛŒì‘?ìm«ßoœîšuÙ7Â—DìİŞî¶¢¨•‹­æã% ‚‹½äÊ†ø¥D«†mŒ·¸±A?ŞLwT(Î×m=à¹í”yôº]—½ äH´¯úÃ„8óH;%Œ-tçâŞ¢‚¨ÚÃİIÄGò–êùn½¯Û¬Ì²ÔqU¶P§Ó“x9Kÿ.¦"‹Ş°?6Fî˜	«^Oä·‚şÛØÀÕy5ÖˆÚõÑ™ïkÃiàD‘g)ô]DäsgŸüÙÙê­’É(r=<ä˜Æsu‹#¼´\([%ÑÒô\Õ`z/¨|Ë(!£ùñ]ê	ö»qnÍ^‹»íàóS;fB‰ øË9BÒÃ›0g;e2·h“³ÄcRÌC6·
gGœnb47Ò€ÉÉ¬ãÅ|Qm¨1¾'“\bAƒÄ“’£É.æP@ªœÈ>¢†\b|‚ˆ«RÎœÀi%˜–êŸJ—:%ôµŠ¼ñäóÔbg._9VpÀú¥Æa£€İ£Z¾qJÿ“¸wlÛè°ÕÛ8u$K¸¹½ñov¸¾svÉö«µÂ„ªü‹>ßPïXB´¹Uø#$jÌEøÚÑñj,0
³
ì7’¯Ûz!LZ ½X7`R1X<@¡‘Yv9<I/šâö{Rßô‰ê5—Ôî.¡\I@óS¾ÑâÎØˆróD|PCÀ‰!Ó– 97aæ0‘†eÿwº‰]ÖkÚçû¸„•‘]sal^Hš¤ÔiÅÆ‘vzSÕ¹"u`H©OTCë)qd‚
ÈÄ6Ç?ƒ¸>öô´—/y%¡!@×^şè§¹ğT3c³N»@ãñäÃr!Ø‘2b‚”†á”Wá ®“§óˆ—{wÿ¡Aæ™"‰®há­Õ:U­+pµìÙk®)›4dšpı†-«ùîÀıÜszIlGÃA^=Äh<‡^íh«O65­è!U÷áEŒuñŠ¥µz}çôt½Ì/âÆ¨¾d„ÑtPs#§…“Ú|r>®ª¿õ ù,wĞû5ü@©€¿äí×ET¡-ú+hÁ3ñW’à.';™-¡iD–¡Œí_Ô‹‡\åñ»Lò]Á:ÌMŞ7¹ öÿiÕõ‰ÎíâqgDm3mĞËŒ½¿Ù¦8_r\¬¿C}(.¦z:uß};sZ²r—ÂKñÆúì´QşÕ)b(>-zfÆLiñÁjÎÖœõ'<TüıPÏ…z	CêDÂü\ØÍélxëN×Js’bë¿¢¹ñúN©WkD0òTĞ+$Â¶©ıç0Ézj› NØüº÷M8ï»0-Ë¶Ó®ˆ™Ù…àÈ<-7[§â¥¨¾.HzYãÆáŞÙ èB£xñ.¯’¹YÚ¤9®Õ°µQÍûoÌÕÑå·B‡k	ú²+å½"»¨¬I®åÿŠ×ˆ(‡¿+E U¶Ri°Üªº$B(ú°¨7 Í½:E`<ašØs2D—­¢m'üûXáÚe¾J¨]¨Á°UôÏ_¡í
`÷]~Pc=IóDbü~TÖÄÚ1BWçjd­´êUœt¦`0Uş•ı2È;ŒÂ%£ÍÿĞFs”«ÜÑT@·è'¶÷ûkŸÉ^ÓQ•‰Vûÿ*¤ˆ#/X/ËéÒ6\vÊá.¾¡nä6×l£óİMeÅ2á;ÊGµmÑÊ¿ÕŒ;`'ÜÁzƒúlª•ö?q¶–x?rÚĞôÄtÃ¥ÆÚĞj»ı2c8ó›é¼„.¸FŠç"ä"Cb¡˜\­-=6Õ=?r½hò	]:øéÈ& XâPŠf^ †JPÊÔßÜgƒd¬;ìİˆÒ(s=’Yê8¨ï`Ñ`­Ã0çÃa6¦Á™ùuc‡ê©wÖ2âØ—Áµ¡ Ä*Q.,oNƒêİ~™jI>ØE{ì|¯0¡ÇÔß%VÛrøjrŸìüpü
ıô¨¢LI¾{Ó<‡Ûi=úîóşçM¦pöÉ­C‡‘piƒ?Å3Ä«K;Á7¹Q££¤Ã@DPî¸«_9¿„•^İH¶ÂE®‡dbê¢~©4:{d[ Ë½é*Z(]]x¸êi¬–ç©ÉD|Y)x¾ƒ¨7¨»SîÊàj”0–/£k¸úv$/ö'ºÅ6ZÍ)‚!ßôCÀ©Ëï+oÌéîöĞğNÎ"¸gJ²*ÊˆbÔÆÀî-ù£u5Ü‹-qÒpND¦0ã.ëu§#‰ğr6Cj[F¼ƒªÅGğ[Ñ}“,…¸ƒfĞÌâó–µå»šÿ½€Ï»õ3iO¨Æó¶àÔºPÓ7ßêuÆlÿ‚“¸(å¸³˜ÃÊ£Ïìì,ˆ!ÂË$öÖ%…u€
eúî0Ç˜<£ §ùŠ…0é«ÈC%RtÛmº8„we3æY¬b©zf9hl‚=şÁÕ„şNËBaF¸×WöÔg’µ•ExcÊw(Ğ±ßhG II‘	§ ·âê]‚Àh®š£/Ò§%¢ıúÖî	ï¶†•7ÆL…ºÎÿ
›”ùªûÆ|K±-§ºH§fÖÁKÉ	÷ÉÅƒè/g^2|¿úlÎa©Cîgò‹VEÖğÂ¸E‘­Ç­Ê2ó7y8prïá=BìÒÎªº&‡"ø€5³=19MÚÙn½É‡¡Œò5Ö'¶(ôJ¹Â½¾–€· }qºú 8Ér7cJß7ü¸1Ñ³éòLÿ5¾tQ[Æyä;M9jQ‘’N*ò„€ğòg^-|jLL´=]ı¿ˆÿñYêô·¸Ëbÿ¾YûQ5€–›ÁFY€Á‡ÓãÆÔ‡+îôë¿#^#eÿ:iL`¥¤ßŠ+ÀS‰FXŒàGè¬}}j¥.—xª/%$¯ì²ò¹b×¼Ğ),%V4LJ|§Àè.“¼©>8Ÿ•ÎÇˆèT•pi-Ğª¤j‚­HhÚxB'åUk2„YÀú¿ño¬öä™HüÚÍš½­J9u^€,…Ó4Ê‘XLÁF¬Ç/:rò\ŞÈõ,º/ò€;Î¢‡²/ÛÛ.Õ ç5¹ÿºÅP{É<Â–Ä@Lf”lÑpÿª{>¿Ö*³_d œĞ3D®AïÇV#ß=Üç°½ÀÉ ­İ¶T|­ß‚¥Î€áp­Õ‚äÂŸk÷îœ~3À£rI3yIY…În‘<;Œd::0AÂ<³?¾p\+Ü–L*T6çR¯wKK¾ÚßßÖÂáÇ\Y…0ÀçXS‘ºš©Z¦Ú%hDÖPA{5³f1Ô§ïïó$Á\?WPxlpª*úãk».À¦Pğ‡ÜV[Ë:úòM¾¬Ä"K¥s”f+r#ÀeŞÁóŒ??H>N"õ$8XLød<Û‹xØ¥tïªuçÏ¾Æf!]¯Î‘`‹³BK«´m.Œ·ªÛ®n\|¼bt.Î‹„¦µ|ùäò}y=©[§`İXôÿÃç·ÌÔ	ügĞ—FXZq½NÈV	CTiİ78 &qòöd|¢_|“Û;b{Ø€¡ıªÛş­ü¹ Ô¸ı)92nUv®¸¦ÙÆ[ŞjFs¢k/,U|'¿‘F½Ê,?j½ØƒõòĞØÆé«¯x†èĞéÊaµÕøTÎ=Üù­İN*Bª–$(ßöÍÉn%Iö3µP”qKz-”Ão¡sXë0í“•JZ9E\ó]—N¶ÖpQ!ªŠˆoù’¾!¾¸ıíÛ,êùêVXùÍÛS1;iˆBFuoãˆ?´ÕS(U!^zè~Ë=«lÈù8¾&k“©´íéºMöä"}"*ÿç“4<xtDOTº¢œR^‡UFLEÆ%ÉÖš‘ë‡piuq©[Yéa=²j
(‚óì†Ô"…¨=Ö)Ù­8+¥Ü,Ãn€h'¡¡‰âñâVÂ|¤WšĞÓ’È—OŸ³Qá‚@TY‡âÆBÿJÎ¯RÖJÏ</~}8yì&e×Ìõ{™şX¥sé¨”l¡æÛáIXşºC¢İäÒ<ú0-Å§^°ˆÀ‘l®TÏ »b6‡zù+ùöw#üÊÌ%IióÇİÕ7M•ûÇê~ÊûÀo'tg¼Í,µË³z$ƒ¤¯š'Y{³5’Óú] ¦æöğ_°mAz0ãJ.'±C ô2 ÷Ú‡™½én5@Ä~²‹ÕTÏìp™Œ¡@@‚z&Ÿ5KŒ>«=kuÏ0¾f¡—¬iùÏà)®zDóP†ò)CC½51Á›Åo ¯pøC¢—I$½;&ì nÅÃ3úNQåA2‹fiŠK¸73'Pa8‡åƒA“7ki#U”n!AúÙ×şüM~	dKÿ¹g4~ïš¤á^6Ëx|aNE]}OÜ	—Qék RÆÈ—£Lİp×76˜§ÁpŞÃ˜*Ç_±4÷S5ıÏE_|£Ã_ÃCÅ©o»'«Qº´iIr_ù%P,ìAŒÇPXÿ®Z@Æ¢¢¹…aÃVhªofï‰3çÜ—Ì:ÉebÔŒR Çó°3r ƒÂ¹†íÜßogl·>Q!uyí%wåïB¬`“ïºÿŒ<ö›eÜ'Ñùg¹ÁÁuf¸6tû¦a2\‡Ši£êÿššÈ"œqÇ³É‹0*ÿû1íÀ)$PLç ~Xã›^±­õÊéëßQŞ¢#ŠaÜßØŒlÇa?C`K‚à´¶aÿ
B?(­#-b§óäe¨,…‹v¾ùÃÂU>ŠsèîÈy©$ƒ‡“<Æt^Û>Y¼¹C†+8ÿJ¨EbDı¤ÕbÚÙÑ8äô©AH\¼¨s=(¨óV~5¯ ‚#/PÃW>0¢/_€i¥Ã)˜eªİÛCü~ÉÍ®`
ÉËòS™>é³(~{ŠÁ4‘{ºæ,z¯Ò,ïæn®éãúµrVS¡0Ë®FÂÏÇ%7L¿Ö»Ü=¸ãkÖrsjëUÊûåBÑ™Uà>–\‹dØSg!&úW®,NìvI³ºxÛZÛS_—Uó»š:+êĞ4¦=Rû	m}<Ô-°ÕŒ@äIß<”B¼ó¤MBÁ¶Æİ«YÜ¨½È½ã„Şå·Ÿœ  Ö’ÉÒ¼ÕFJ˜!¹wLïs›¤å"ÿqE)_u‡²›VºìE.½ÀtÉÜÎ¬šÉ}³¸¨ùO»'«nÉàñÇé$÷ŠØcÌÛ¸ıj›r9ÔÇq5¯é-¥Ñ|¯¤b_Ö÷’—tkG\#É³›ö·aÛ;0Ã	atY-×t`Â6®d0¶Ãˆ%=Y÷Ø#sg`?¹¥ª|¨”Úû#ÔÛÊZZã1LÌÃ2NšË|:y%Úg$p
€_—µ% ¸äVör½`†©ŠD”Îs bìièUÙ¶oŸV¬-ºûaê÷4ÅŠ‚{½_h]2Ïs:Üìg8µ'Pà6tôe†3bÎ¬Ç˜DCåØ$ˆ j]Ğ#ût\¹…0xPbXæÍ]zş?³Ø¬rGËO×Áƒ˜ÄµÇóê3<ÚŸ¢LLÎ` ?¨Ô.çi²PMqåa3÷!6e(¹A½¯Ææà»“	*P2½“M”=Z˜W™\æ“§®À×v÷<Õd·¹ÇjW{ÿzzd—ŞH€›×Lß»©…ÀôÅßÔmİu"Ş@&ƒ‹î\¤QñÇDl`£ÖóåAÑGFë­×)CJf:ÎçwŸ±=ÀIFµú~ŠÖM-œ ¬7²_“5ß'“°ˆMeŸ(xõ7&LGş!S—¦¼V
DY®SsqşE°İÜ&4YDí@ñEsëş•DÑÉûÈÁSõhCº|ÔÅ6qê»
F)¬‘ò¯x”åÉr„úeã˜û{Ò©gzŒö†ƒ|²ğ®t«ò‚ve@Qwu'vÕ«óã
qàäì<×6íjD–:hFĞÃ2©0ÎÓoŒÜRŒŞ÷!r¯¬Ø^îàÒ5»oÙ@ßúãã¦I¶oMÈt{Š{‚{©&tã_æw†×vSÕ†mùÃ|­ÜUGPg§qÔuñ1ËøiN“':ë‰šg’ñD-6,BOô&˜ü2gÔ ' œ“E†×mÁK›¾Í¶›K<…©D¾	±GeªŞv¬%›I0a´è?Ä¨Øë\IŒTaîššL…Ì$~ò“Ø'I1¡õÖeÄüêü\xqnQP!;T¿ 8şmüç‘›7	ÂÃiîƒA?ôëáeìv(ƒ”y’HvğŠ˜Üij+Á÷Œ‹ou]`)>4‚ãZ8æ²‰ÕÖ9x\0ée5òTøê
ó ŒÎbôöó>G›e?ú@J£GGrñ¸è†W–íAP›ùû“gŠIĞ"Ñ¶>@1°+¾EWËM’Î¡şŸJëØ’y§P%ëøçnUkzVE£lR&İ2àgñíç¿üø ğe|StÌ4>ôÅ’â<«W#h¤TÊŒ]âËå`.¼Cîu’–ä;İ/×ó¾„ó’<ånÇİ¡(!k€®K­±xã½¢ˆMî¼	ö>R^î‰(œSqåÿ‹}4ÍSuI³'&à‰”¬“Y#šäÄ/Ñ
X™ê?ÇâïU?BtDãKê—T×g‹âw{Öxv~ß€’Y‰GQ¿úãÙ*#élùuItdox—5KÜãÜÎâ«³««4ë¦CÃî?Q#Ÿ<°èâº*rƒ)ªúd)›â€h(ödMcÙü‹“¼¤ã U4Õ`5~oçŒáŸ¹¬óEÒ ‰Årşìˆ?…î¼ş2_8.(Dôõ å¶dz
i®·ÒFFÿ]KhHì?•şñ6ä=wª½NDî”«ŸyÉ±^-õp—Ö34h0_©z(=rdœ ¾¢úñMÂW£ãyŸşÅ¾ÇŠıüˆÇ›“¼.Éá
¿²¼€/ÜÓ#X3\]<7ˆ-XkàgôŒÂÌá²=•î§£‰ùÛÄ)/2ço´4B4šà›^©m÷ >÷F8--d¼6W*/jìıc9ôØ¯Äwhı½A_æ&iÚAŞ<\AÑßÏİ•3°ÒFÖ¹½|òË}Ÿ‚J–êcÚ“dÇw¹¨âbZ~æ]_#Ğúµ8=@ó¨NÃpÌ®Â°Yd cğJË@ÆÆFPS› ë¾lXâ’-ª”Â¸"dêøh¾Æ 2‹kİï Æ`I¤ó]²ØV­MHO!ñ•^ÒB|3JR0ÈFàÕº‚‰3×¾‚u6ã²5A“¹ÕÒ.R?ÿ4ÇN‚[b_ÇëÔËzøÑ¾ò6VRVtÊü/:Fñ„2³’ûÃ‘,Üå0pH7ø¬lí©¼îYE–XY¼	­aB‡„ØudÜ"-ûD·×šşv“ğn´ÓòB­äUÎ¬>ì*AÕz¨9ºâ"Õqï|¶TÅ™¤\,ô6çˆg¢Ù¹QÌy´?]}¿E…Ic™ô_Ym=f¾©…R–`fOŠ9îEk¶ç\õá&®k£lî<ÈøØåä÷e ã§Df:0¸_2ô_»G„Œ¶#‰Úlk6kn{¡¶8´SUŒTd5—;­%Á˜İ—ù^VcZÕËÕoD‰öcU¡½€M™ã”G<;vŠGÒX.æ¸>íCAO9hÜ>¹ğm¡[&‰”G×qp‘ó\CQg§áP $Š`Á8±Nğ¿cº¡XğAe¹hïd¹¤›Â¸Tó7g„ç¾˜T0Š gº¬hgn¨_ËDDOŒUÇjşÁ£Ñ0?D™%~ñåóÃ¦}{˜:qĞPFVu1\$d1",<³õ+ï{E|ÊÂÄH_ÀS¶ştHşDìá_VÇGŒ€xÇ‡À×T?çPóV œ¥Ä,.mZ1‚şío,
›L°Ü/ĞxÿÏ¸l; ¤£jF;ñqëd¶2³ûÈ¯[!éœvåŞ«Ç¥²2Çí@”ªA‚yA½AíöîmÀ.ù1MÉõ
R,jb…"Ÿ“±UçæĞ†b&‚KdooÕà‚ÄE¡ì‰x$É‹Œ›5Æ¿Ğb!±<ïÙK¹:Áƒ»Ê8şõH[,ræÕ“LÇ7âNÌ¤dÖ…ÌÊ°+Å¾6ù["ñ²XŒ“[ó¶yŸ™übó(&•ÍÑ£2?¿~Í¹¬™ï¤ãlk†ö½G”·<ˆózYBŒŒp_„“¸èÙ¿ã%”!gIÅEÛ¬Ñ}J>D /·{,æe×·‚ëHípŸ§™Ôï»ÈÇ¥¿™I§¬ö!¸
d+‹q¤)«ØI‡¬WOÀbn¡Is‡ášï ®E°Ëzq¤Ë]ı{rhˆ¼	8–¢€˜.› Cÿ²3û"ööìôœÍãŒ~èÙ‰óğğcºçUÜ!¸`å>ö]¼Åmà<Ë®Ì}2~ml_T	}aÙJğ§#™$¨öÌ0²ÙçÆƒYPÉ
ë˜ SÉ°'×pâ?©ñØQÚj¨LC‹¦ˆàµ3ÎåLzğ½ô¦›\ŠXp_Ş“)Eœ³üL8{Ú1ªÏ…â…ñ]DãÀê%ıµWÄtå÷×„cÇÙÆóÅîy¤N©3h¨åÊèñÒ„L¤Ç úc™wÔÒş$ÔYO­TçbnT¹9‰E±ˆ•Áî0~i•h$bÃ*vüÛ ç	ÛÑÆ8\y§<¨_ …§­ïR~r»øZˆK–ö”¿)*[¢ Pe54‹Q%Ù°ÿ¶E3Óİ¼ÑªlÒQ”j¾Xv>±Ë	†çíLEƒ¿6§)owÁÊB-ı+'ò×ö¸/ dì›€òtÊ&6øøKÉ®Ÿg[ˆ,­PB…Ê«/K±}ì¬®ÂZÿ–öaS¾k{túïıÔüùô/ÑöS„¨H"6»…—O\ÎãT$Æ>n’«¼-&ë~­-h6\õ›ŞQ«zTÕË.=oúùàN$¤‹˜¶
¹FÊRïA¬Hf*N¬ğüqıĞa”ˆáéFà$Îõı9îuÿbI@û—®øEë;7á½Iù´í§Û©b¬µ”Gm.X[ˆ÷"«~Š„{¼UÄÀ$
8¦=Ïanô÷K†¦»+yå‚Zûû8ËRP3§`kö“íãÑtÒêls9§4„ëSës¥aš/×¦i j€`p ªÆäÆ8Õ®#!I?3âd¼-İ9êÅˆFUÿ’YŒ˜¬İ+ÈÏvaÌ´·«½åû×w‡ïU}<Æk™~/×Œ%û3ÄOªêæİD°ít/L½ÊRã„2]j$¯,šÃõå”­dd‡²-&0#‰I‚³Ã0Wœ’pŞÊyb°ÙA'VÿÔÛ,èŠÀ"ë3{kÉKı]Ğh)Ÿø»0ZÒ«qä¼c+ª.‹ı31(Åø&šOĞ­qœE™ñáYÕ»}/(ÊĞ[š·¸„ë}6È÷¼ÑõéÂ›šõÁŸŒş·mêµZóD¸‘«{¿09ËìÔ ‡¶â—„`b‰]KÜîX´SK#?gc–öXvehä8ë!ÒÚ×Ô%¨k IÔ8Zï´Öî¹¼•ùjx…EaF·4Ã•c{³‚o Ûğó§o“øúB¬ÔÈ‰SZ²·[ª1r.¥'‡¬SQ€ä—‹‘"KU¼»şğ=ùÀÆè mVÌ•rS^óäõuÒøFÉÕåŒ†Êp9r»£ œÈ=Ò(îç6ñ¦d
Ú«ùÔLú>Yv°ı¢;.Db	õ—¿GE|8ö—ÚËR8"¤ê¬¹3F²“£{Má7Ï›‘•´‰ó1ºŞ¯•Ò£±ÃËzı9k4UÊ á/øyó‹>zİB…²îiqª«Kc¥=œÚY¥HÖ'·å†ØFãt»ÕWN¢vóø1¹´º>3ö°\°[­Éà	‡Ò,“â¤8JF¦»\4™‡–:ëÜ+r·‘Ğ3êZ‚š½ ˆ¿÷Úäg®e0¨Äö{îåÂ­Á¸Ù©®ÏjJÙÿNwVLv JJ¤>õ1;VrQÂJå	ÕSXÑû.M×Ôì“>ÍêãØ¶­Kmó¢˜„¹?+g¾7ÆŒÉß’¡àš×Œo n.*êO²·YuMåuV+ãZãå7	05m-ë?öğÿæUa«‡Ø½ƒ4eö†(_Í]œ4ö+`yƒp€´æV¦DÊØÎñùmj[#¸ Ø‚>Àş#m.wyü»İà2ù(1Ø°yWµ(3uŠÑB.28D{$É2±yBY/4BMw
Ğêæ´*éÍæ|Kÿ»¬UFFÌ_$İ{’+[Rp§îi^t0rC©†!²ü’ë„ˆÃªOUioê3 «CßÃnöˆbPp#yßç­Ä¹¾D4­1¢î-ü~
j©Jo®¥Ò< Q’±S¾bGx4/ÃÛâœbĞøöÁ/ˆİctwg
wÁÀR¼êI4"™)E(¢Ä¦FÈóY¤å¨ĞÚ›N\tÆ!Ö×k“?t]«TU:9şôxÔ…bìùh ÃÆ/sñ]ãÓ%P²X” À’Yæ“º¹æMšD”Ü5N4Åƒ‰›Ó€º¤&ZøÃI„År‚A¿Äd”ÚLpË)cp+{f3/
@bÄ„K"•/æ‰€ğiĞ—Î«Ç®ïYUMQZ¸÷ç³ªMXF…±cn·wA¡¡!³Ÿáİs‰®“UsYÂÙ+ÚÚS'.S¨¥í`tc&ßpä>Ÿ‹ªpğùªÌ•	dgw£ëU–eX·,Db¦  Ö¡A"CÆûÚ½M•sç—¦‰ÿõí¸6œıÂmzÿmLiĞ´µAm4š _¶äÛC9,ŒÜ`@#|¼Ş>–¾½s†Ã£İÔŸ`5N‹ÓÚ¹kTÃO-¿ÈAÈyd6w™ØPñ´ÖXÃğ…Xaén;/å™ÓÔ-Ô×eO`|¯;ô•¿Á¼ÙÄG˜RÙ@–3ª\#F,Œ¿R± Gèb9Úm%ûO›®&)¬SŞk~…ÿës,!ƒÁº©?%*‰‹™#™6^„±Èa¤á£³ÅY~)HMœˆú¾k¨LÑ‚8ÌuOÈ<ÀÓƒÖğª“ÒÕ¶J |ˆB´õ3}ø¦Ó‘xŒ:*èÓ‹…:£Qaeo\_Ry¹É¥Çô;»Î›ÃüÏ/`ˆëîØ²øh‘~ø7ØcœŸú¢Š¢"yÄá%Ûî#Èë<bndƒ¿]WZ‰5¥G¼,DÒ^lÊò8´–],U#2¥Ç“Mo&ø,cŠ!iÿ+R81Zë9o<ÿ<ò¼•U]±ßô|ùÁ„hëreñ­¾®İñs×0~DŠòrŸü~iDÿ)}dölTÚh%i¡5tã­ğÿüDíÓæbgÌÍÎ'}#W°Ğ|-Hâåçi°Èõæ>éèDU<¡"Ÿgc ’d¸gzÜØÀÙª­œ‘÷à‹#è™‹¾1şŞóîãü‡KÚ,X'{\\;™OU¾-†–/_v8~(YtìşûıQÑû”3Ï¥.9=“Õ}(FÊ&c6bÑq–ù¢"ò¡@rŸúK«š¯1âzÃ§2·}O[IüÈ™Ñ&d#õPŸûe¶ÊG*ÍF‹duh¸9®½Íq|‰yÛŒHçDî•âØ<Éı+Â©¦-ö{Sïp¦Dô×+Îôö¨³Û!9ø€†f"ëD•§öÔZ‡ºîÏt1;®øˆBÅ^|E8¹Z+Õ@©·rkÛTG/
3W¸%Zı½Kd_G_epÉ³,GDö£D~Ã³ÎAä`ª§ö™A¡=Gº€‡–ÿ_É¬hĞí»föizÛ?[[4:¶R¤9$1Ír¼IÄï.=˜ËX«•%¼Ê&Æ\ÓWÃ²£ÿòS]­üçõê QIı),x~èmüÖ=~Â¤#½2ÉbC—LİÏRõ|@?èƒx4œò97ıŒ!1¼«÷	SÜYÃ2à¦½Zü°—5D³˜uÿ GÇ ï˜TN\ò/Û	°wm‡H~p=òhWÊ¢H'‚D•„3™}ü?Ô¯¸FØŸA÷®˜ÓFƒÃ0)ù8K£—q 'Êx3¦°mW_‘Ç#Û&…¥ÓXüÛ4Ãº¶'À¢{|-îlXŸJ#¯I]]XüÆïQşjéÊV,¯ÓßGM30fë)>¸ Ò:´ôß<èûŞ½zpÊHÜÊCD½°IDÄğêÂw=¸&N¯—Àôşu„¹ÓÔR(ûYG.
Ğ:‹ĞİÊJK¾ˆMGs¢U­âÇÅTÎÎ±±š˜B¿)uÚP2ğ¤Ş™Gpk€Ò( òèIRTq£	Ñ¿åiäZCÈ­ËË [8Pá>§•¼ï¾FÚ*¿¼`€\@!=_é¤NäŒÇ$2Ã7iÆÄÊ”¬®qÓŠF›µH“a´h7ç«óãRqƒU „]¡ıÅîà*§«/‚«H{Ã_°ŞöEĞ1	º|¨P3i–»“@.éÕº[öeM“…î`g{8SK‘éz“‹
ØÍïòş¾ÛZD è¡Ğ?»`&œåjçSJ¿òãÉN ’Ò’(`2XÍUº¶.3{%ƒ²˜ì(³Ágœ/ Ã`*–âŸw4æNğcw»4†€ÂI¹yI´²õi´0bæå¹¬`‡¨¶ª9=‰çRÊëùT–f“zÂ¹Iq(a¼äõ’Ü:Ègî,¶ÒŠü2ã›Ó‹Ó–îòänĞy€²²—?7ÿd3€îü?ÉK,uöá;¾cJøGAÍKŞáæ A…ŞÖ…åß~ĞÉX½LæggLaóe«Æy`ÂPá²ÙógõeÍŞ¦wÎÔËŞåªoÒÇ-WOSToğÈ‰Årÿ·<ÎÌİ'L Yà¤w}kÓ,è7µ	-‡Uäİ|CV”JFúä	È¤ta+8ûeÃ¾*+GC;T§PNrq5¸ÏóøŸô&‹w¸ÁÓµF¹¬%2È¦y\á5oPóÓè Ş^#TXŠö
K$§Ôæ®ä
WéDÕ™YæìJ’0tšx«D²,Ş]äÄÂd†\¦¿Ô¬°c2è^>
Ï9‚ G]»11?Èà²'‘…|¶$5€ÔâÍ%t! ë/J÷‡‹…-ò9„ôisj$NG°wéCIÒhÁ0m½è[ {3qfv_3½–ŠÒI€0ˆÑ¯÷¡dæ÷×Çjìüä>Yÿæn¬^s„Ø8Ég-acCûŞa¨Z¹Vk…ÔÈ= BûsIçW-=Ë\÷;ìLúx/¾g—ÁJäßŸÎ¸+ÍÊe)ğLü‰800Ñ£Ê€"äß­Á}Sm\ÉgÙÂVT2©Ğ¦·SÀÿŠ(8ë{Xújg¡Iâ|Ã‡ñf¯ö/×L,}ó<§ƒ=şLL¼wò†8iÄİ&¡Â=t!óN9¨Z56ùéËÉFÁVÜŞ|i”mÒâä>	£¾Édb±¦ˆÌ[îÄK…ş¯àVXæ÷íA1æHŞàÛ,³ËR÷‘ÑEÂØk ƒrÓmâLŸ,5•ÉâA†?òêÀÙ‘wãÕI5ÀcyÑEDà|ÍÙ{şòg›ë‹Ó•9ûN©bá/±ïŸrw^}Çû•q›˜@©¡÷f kÅÚ€i:1³ÒºWŒE# †äTŸY`¦/éü½ÂNÂÛ@3¥&” ÕNé'4 Ÿèn¹Œ¿Ò>RÍŞKF=Ì"nJ°c©½ãÁlK€šöL¦Š(àS:'FÆtH¦Ë3-.›o½DÔÌ­¾Ä¶(ÒÕ:wû ¦1>Y ìwk×†‹ûèwÆbüLºGvwÔgÆ|è/¯ô@¯s33@¾Àøÿœ9ÿ‘'6Ú#¿ZÎÆ²˜…EµE£1ÏpT˜è—Nê3:‘GÄïÑÁD€’ÃŒ8½®'#
Öe:ë‡u/”ô›— ¨ß“ºi½'æ>³hj–¥L‹5‰Jl
+í ÒĞÖ}‡L´/ Ÿ6½ì³¸i¶¡eÀ?ˆkŞÆ³u
´IËé2™ã¥”ÎB‰äÀÍ$<.úUÉ5Şb³ŞK4ÃrÀ'=ƒO.léœ@lzt5Q>@¹‰ìİHÉf™ ş ‹]êü—Ûòï\7Îf°ebgŒˆáà–a÷¨¯¶É1h¡]Û"æy.%6ûˆÔXœmÄ›Qx ààgCJeŞµf{%|R™ÓójÉÅ¨xº-òEc¶ñ&OeìxÛAÕúJ$¶à,2;Àfœajüı3¥;Mâ›¤ğQqÁ™¦eğ÷Ãİõv’†BÓ91Ò[7XªÌ †rnQ4H²Wİ”g”¡·&~çZP,ä@½%öZcI§uLàw==°Ä!Ú«Ğ× ®ÿ"Î‹ğd‰.1ç†wäDÜ†âu÷Y†ØÕø é‰Ñ(>UíwV	î¥wJŸû´µºÀ$êo•=åY¢¤¢K]öF
dk²×3ğT´æWj½…ÚçÔ-ÎYïå”t…LÂ8¼UE\è|sº9î1ß#rœ4)Ã¤•edÛçÎ©#Ùb~ø}TÄõ%¨z¯€xƒºƒD˜ë!÷®c®;ÖÂy÷§å.-æ¢w“‘íÄ}sßˆ¼ ìéõ"Ez1DÛç{5ş,RDØ˜øšõQÿkÎàJĞ‰Hcmò7é¨vu[ùOÉ£‚g’Ìú ‰DvÑ'šmX¢/,ÿ‹à“ß×º[•Î§0À¥Á13èU\,áè÷1¨PUj^qb íeŒ˜#c,!“AhdæôvEH´=$©ÍÆnûŒéÓv®_³u€ts·ÉÄëóºÑó—°¯Ş™³ø¢ŸeBjó2ôL:ç_á[U‘!‡»æ=á0‹‡‡u!°à´u)*Lø«jsµ¼…Ô‹¹\NÄw«şFNzG¢3‘hZŒ+g-FzØÇ:Æ¬ ¯^•Çkõ·Òïl:u¢rª"r§ÅûVî)“ o A¹ŠÍ¦.3~‘€'÷WµËÁVÂzµbÌÎx—dZ¢E1¸YtX·ãÛ- l+=.ÿ<kãñ~oš+¢nöÈ›!eÕ{ùEn	5[4¼íåFk)kKavÆ—kÈC¤ˆó‡…Z@¾©ä@‹8…ª`kßãpÌŸÇo µ–R‰KÆ²×
úSnÜõƒ&®XîÎZ’üè‹§œ¤’§ßE:ÕŞ¤3n\_¾·ÿTTiIÉù”œ<[–Å¯Á$Œ9ŸfÃÒ[PœMpƒĞ~{æsZzvK*­×‘TÍ¾(ZUåÁÖ*Ñçá&o$#÷—³m	ŸU¾ÄàIèpŞôw/2=ÜËTÅÊı Oy±íºz\§Kœ[\Å&,¼sºzá;°ä“î¦%'¬êYª‹rLQ¼1ÎùñÙ~sZ­+ú×ãsØ¬l¢6Ev’ˆ†Ê†*äq@æH\î8Ó¸²_cç/Ş ×ç+yÀÈ;Ağ¶X»	uÎ¸…Á<îB;çğˆ5İªßƒQ*Ñdœ´‚ôTÚÓÔä\‹¯ÔwîY8"#fÒ“¬c°şLZÛ³©p&¼Ö1D!.Ø¸	+'L‡äÅ†–´/0ˆĞá¢±<&Ø»ivzw,ƒÚ¶¾h5Ü‰Šj-²[n»"S¤} hKk›1ÜÁv9iÃÉ£Í¢x
»x¬Ç~é/Éu÷*6™|ŠW€ñúå±+ËS¿ş
a?Ä¶•ãÉÊ‘ªõV£!¹˜ş‘RøXhÊxSâl}TôS×Sº.Óã/,@ïî¦ö0ªêÔÉTõüyòşWÎzgÄäı‚mÀ˜|DÅ¼Ã=ÙÒFqäR˜à~‘+'X#WXdò×Ó-.î:\Ä[-.Öà:É”…2®¢õ€” ‚èæãI€Ÿü9JßW»®Å|ÍâŞ]ñ-àë:‰ù†›4ÁóˆŞ}ÿ´‰z‰é™²önøºxhX¬1[ßËL¡ö4;êMöj±ƒ\Ä6Û%Ó_¨¥¼e¯¯†’ÂÚÔvH±{­¿·vƒ”Ë_Cººÿï§rcºåÓ{@SàƒBœÊ½8ì¤÷²t|®ëÍøíŠ’	 ‚Åv§æ]Í“õK Ô„TnvZQ™áÇ¾«ŸSl}Ø;Ø<Ù9Kg|¿¦h&h‘Ñ¸Ìlr¹o™İ–è$æ”¸Ô5C2—bTƒ~¿s“ ‘YwÔè…\­¢\BK)'ôèk»>Iï®ÿ¼†j5ÊÈÔ8Ã}ƒF£ 5“%VÊ ™ì«[¯=O»PíÍó):7ÄJ',]§dÛ/6vu(MØÄJ\V'ºï&ùœ‡ _o5ìéİaì?Áã
º	E_-9¤¸„)c¦éNÍ˜mıMİ*4_è„Á±î …6*Ö—pÛÄâš8¨¨…ÜÉ1×.+IŠÿËV©+˜Èlü<¸.Qú^üb5j
»õ‚Oà"H$•øz€ëô­}eş/.ºJ+İ<*6IÃ¦ç½‰–ÒäŸJPj“„#Xáp‹aåq›™ŒÂxú3Ì„:Ã"NÊàú—F±(3’Ó,ÊÓğ÷ÏÇvĞäUúTÖ3¼ûßƒob´®Äê!ÑI ±ê^Z4cXc.ı?K*ÄŒŠqì»#NÕV‚ø­úşRixâ§ş,/6£–í¿i„¦^£:PÄw°ÖÄãı8ÚäS,JÒ”¤ónĞ9í0İ cW¡ä
s–Ô:¿r\/ğÿJ¼ssgP¨0åƒÊ¨
µ£¦¦vó	ÿ÷cÄgo–8š[rĞ½–Š§`@"§¨ÜÏ{¡\2¤~ké€]–ñ1l°dç™õ‹Ae*¾äÜcÒ-¸|ÇOÙµZ{‚i¦~»2L*,ãH>Uæ:’¯7ÍòŒPêk@0ów7ü³|m#pd%êÒîkİ¶ştiLi³ëĞş~õ|öª–n…ºÒp¸Ò]÷Å.anpÛ_VydNî1í&-
7ºœ©"‹†35é*+¬o‡SG	ÕbQp’×¦âØîÌiìb<8u(—Ãç„˜Rm/–cFm·ºü…eÙÈ2è3++21×®•gäÓÉ¼32pO"Ì÷-®c3E<èç±ı§6c.û§n:ß=8ÉüßÆ0±,2™'i+Ó<Ó™6Hho÷$t»ÄšÔ›İÅ¦_¤}…E¿úÎÒKèê¥(…J5pä»»aè×o&Ppq×q>Hü‘)w…ÿ	»pã‡TŸ)J4ïv0Ø½»ÃõB¢3uÑtàÙš”tÀº8.Dµbû[Ÿ×•àšÀ”ª¡¤¢‹ËüIZíË¤Êµ+É¤%yJŒJ÷jü£Ç%£ˆW`1¦Ö¬qí§oM–“}®˜Ïø5¤ë6zî{eÜò£¦¶½ö0u_1â‚£‡Âeşm’·-úìµNw#	œ)©46Ì¹ÔÀô«Ëjº’R<F#&ş˜ÄMiòúhë1ŸĞ6½‹"JÃxàéìeí¾K
ÅÀ;|ÆœQÙ—õ'øÙËS¢ ÖXö6âÿèwì2Kè)ñò€QˆR°ıqGä‹gœ²"5rUS}-1Úû„×w¯Q9îåaj‘¤vR(|Ù ŸZ2â|è–&–h äÄÀV	’BÚ	»'‰¶ êm¾óšO‘LÖÒ)­øq<}±˜,Œ©¢Üêv<Ãv—¨¨ %.Q2ï1Õò,IŠÎ<Šçç÷9õõ½­-Y°Ä&œMk@mt¢÷(ãŠêmCŠÜ3¦3òZ7xù¯¾k_,vü©%Lf¶8~§¡ø,q_Î‰^øÖ,É:YTG.¶Ú7§™¤¨RBĞ…›Ù‡5Ú}d¢tòğxµËeß¦ÿıâ°:±Æ¤2'7p²,â%Rè0<QQ€ŞÅüŠU¦•ˆ…Òw‡Ø¤ÃúÀM;şh£Ï`Y7Áj§¤\éjÄ‘‹+[BÃ”ƒ™e]ÎOã-ÈÊıJ>¿2Ø°ì²H½‰­–†ÆLvÍfŠI„
'ÇQ5x€ƒIÕ³x§{×?ªî˜®ñÑş9ŞJò'$¡—½ Sî¥9£µõó-‹ŞÖhR"Ëá%F0áSëbWØºfé1:Õ¯á5Õş.è„´’¢óğqŒR7ÀvÆ4÷Ê¾Ôšd«po’g¡ÛdÕ=1{,xqaE3Õ÷”‹»m»°b$¡¤lBÌæ'Àúà…ÈV£Ê~¨::T™ÿïY*'I#·½_iº¯åÑš…¸(Bˆ%EİhñO¬ÓK…,îÆs,Œ1F•`	šŞËŸŒQhÕu)¥®cØ©±·Z0ºŒ‡¤KÑÒwf‚…3X»Y‚¤m¦Ã“SÀæÒU£‹1Xq¼AšÓÚh['@úÅ!@}SHj˜¡ºD'·W¡Iq¦—=®9a/SFÚÒ½9á8ĞÄ*`Çüºp¿ Tdl
”MÑzLÎ‹ÙçSÛ:úcëÂ½õ;óà)9GpèÇÁd¤±Òğg¶¿|Ã¿"3r-et[tË[§Ğú®³%QÂÆwŒS¸Ó]8Æ¾¡>>ºs^•›d ¤ÁŞ~s®VKÃFÁ4ÈÏ	ÄŒ£9ÓIÍúúMËé26Ÿ'M¿‹C|¨’4N,åˆƒá¥àNùLíîz4*"‡°ä™ó=í8³'|	DóG¯ú%pÜ‡^p€Ìon)3TøÇ,å~À-H€`ˆ¢…’¬´eƒOMÔ}à?6{%‹lúrã¾óÕâ›;*l9ctyq“‡ÁóZYÈ›Šã¦$“Wî6ÖŠ IÌ.[¨ÆÏÉ¡£éùTÀ¢†"(—–»Ğ¹Äé]º`Ó]DáêR÷B˜ }w & Ç"]»²Á‡•+ìÖDe‘°:xßw<Ú|¥óx”ªYÀÿÊñû8F“ğ¬§ñ-’lÓ-µp8ğr	G$OQpo?u9@fJ3°É,¡mH ¸ìTPÔO’å>îÚ’³a³€®Öiaİ•`ñq•2*©ß¶ªûø<ºŸİoÚO'` mŒË$°±4N“ú/oì¾¦X§ÚÁvL¶×ê.T	xË»7X‰œã»oõ–“İ²­.ôeŞš©=âª~¹OÔ&(Òü’[±Êz’[7…Ì>oÔ˜	Ê »R‹]Øí¯ñãÏl[³Ş¦òôKMJ°!qÙË–Ì}pºkËká ï"åØcRç@ œÇ€ãH×Ô±Ägû    YZ