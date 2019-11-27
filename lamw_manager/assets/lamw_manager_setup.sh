#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2057373809"
MD5="55558d73a6caf93468e60395a883f8b2"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21242"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov 26 23:02:35 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ ;Ùİ]ì<ívÛ6²ù+>J©'qZŠ’í8­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»7úa‰À`0Ì7@×õŸıÓ€ÏÓ'Oğ»ùôICşN>š[Ovn=ÙŞ~ºõ Ñlln7'¾À'b¡òÀ2]÷ê¸»úÿ~êºc..ÆÓ5ç4ø—ìÿöÖö“Âşoîlî< ¯ûÿÙ?Õoô‰íê“)UísªJõÔµ—4`¶eZ”Ì¨EÓ!ğóØ=rxŒyäQËY˜ØBƒ¥Úö¢€Ñ]2œÚÔRÒö~]Jõ%"òÜ]Ò¨oÕ·”ê>ŒØ%Í†Ş|¢o6š?BeÓÀöC„Q¢ÊÒ®›ßBâÍH½S/ øû¨uü
¦ç@u2:0˜ä"0}ŸdæDÅ1\‡4ÛQrêìLı"œTè¥ïíûg§‡F#yl‡†Z{¬&¸˜ññá`Ü=ZGGÆ
É‚æ"x»7èjÚ~:ìŒû/:¯;íl®ÎÉ¨3zãÎëî(knÃ,ãg­ásCE¹JQ ÔhX©R Şè4ô‚«"ßa›ªØ3ò†h°oµş«}½V\‹JŞíáÎ¹J¥œ|ó;Œ®¨5Öu\ç¿ÍÙÉÇ7D™ÙÊz×rƒKWH5soÍÔ[,<Wcg”o‚bì¾aèN`[”)Ğ4¢ÿÀv({´qM”JÂ+=\øzº>õÜğ
YE‚Åz=XÕLØ>£Ósk°ï!ö,²<² ‹	lÂNºlí@R™š!Ñi8Õçùä¯dP_‹l?İ¢Kİ'¦ºö'òAÉnÂb*«b×T*‚:>÷cÎŸÖ¥ı0 gĞÌoª 
?l×2j›°ÃÓ3duCMhQk	ˆZNQ9Aé4Í¬ë\í¿t=E«ß*€/€Å$ô,xÈˆ;€³á7X=¡¼éÊ2¾ó‚¨ù4E™Óğ¨SûxŸ/[)àÒÌ4¡²ª†µô7Ñ.Õt¶AäæuˆâÛõÈ¢33rÂ@ZÙóNÍ&>µD)kS¥’u¾ö§µ³ö=Çmxa‡bFx>·C>§N/é”PwIö»ÃşQëW£ÿ ¯[§£ç½AwmÙoòéô	®’ZÎ²ÙË…É(c@8"Ø]B/íÔëuu/ ¦•røUâ*"wŠNA‹ëÇó•ÆRŠ:ÂEr’*•L1ÈÔ¤@¬ÄM±ln
+é¶òÆ˜Ø…i»)¥
>q²ºõ|àyaÁ}*•LcUcÎ÷IÔ©‰2ç!òüVùc“Ù)'\‘•Šlaœ|XßŠš´±äÁ×Ïúø¼ph»s2„88¤V=¼?Cü¿³½½6ÿÛÜ|Zˆÿ·>İüÿ‰ÏsïmRÄhÎ&í*•&éùàùx€6çš¬üŠRy$ùĞï¹aÃØÅt-_É§–b@ä[£ü«ã¼ú«b~1ı¯£„ãÏÈı;òÿææævAÿ·›Í¯úÿŸ™ÿW«dô¼;$İ£oˆÚzÇ­Q#¶_I»wrĞ=<töÉä*%ÁH/"óŠÛ¼ˆ…æØ<
®¾'x6]È$!ö	ÈÂ³ì™9	3Œ›Pâx,¬çË«ù½oLDu²RŒ!üz¹JUGøDÓÄh‹:öÂÆ°QÀdrçº0Ï)£ÎŒ˜Á<Bâ™Ş( º¦#cÓÙ.9CŸíêz2¬n{ú—)*(Yı@ÎjŞjo5ÈgˆX9²üÒ7]Æ#Ú33aãU”™0Øœé4â™ÎÔÉ[à0ìŞ›>¯³hJŞêÇİW«ü%í?/9ü›Õÿ›Í§_ëÿ_rÿ§XxÕ&‘íX4¨³³/ÿÃfo¯øÿ­ÆWÿÿµşÿ‰õÿ¦¾¹µ®ş_ô{ä‚„©ç†&¤>„#ƒhÄ·È¿2§.xØAQlü"´ÇË§D'­Ö ı|g[#-×
<ÛúB]©Z4¤ÓĞ„wàÃÿxÄòÈÌŸÆiœi™ÄõH¿M°ŞhbYnùáïm.mÊ‹•æbbcÁKáÒA¿uçŠRq¼)î¡ÍÂñ8`Ô¥•`›±ˆÖ]n`y˜a!?…ÖóÂêcõt¹aDš?ÔÕÇ ˜V0±ü9véÅ8â c'd¼ìº·Ç‡ÙntI!†"Íï?’2sª¤ä432¶êz#çtp4†…j‘±¥[Ÿ";ˆbœºÌ±I.ê¡9gz@
ˆÇ[ãÆ¸¡J˜ Ëø¨ûlÜoª±@wì	äPU	¬}p˜€!Dã¤Õ§³yå sÔi;†zëÄ/;ƒa·wbÄK¼YzM©f\GÛ —¶ïµ¤í[—½Ø€$Ë¸üagšæ  hs7ZYWZà¯rq ‰!(Í\yQ3¬ôx
ñÇÕáÜ•aÁ€\t)yûx“À›á‡‚FaPÀaÑ%O-|N˜½˜|ø§cO=>w…àÉä†ñ™Í¿ˆãİ¾øÕÁ/I¹„ßëØ+ğ	SÅkã%İ•0¿@ué¼î€Ù¹8³§gÈíÅ9¨Š&cÛˆ+åj-7H%QÕÕ³“rÌEjë¦ºß\÷[¢Ãõ‹"½RåozÀ=UÈwi…„Ÿ+«px‚„G(àdqºÑàôäIùGa±?ÇZ$+Úf½¡MÀ5¨)Øx®v½Òöí[íñMu|ƒı¹ÛL·º'§¯ÇÏ{Ç.ìÌ„è–Ç	óğåÉ¨uxÃcÉŒ7uy¯ê õùojÉêRA,>•ËëÕ…Ş”`Ã£X®KñA¨DTÅAO	ëVšò$g¡¶º$4öñ>á•õ£ š‹È‹ ¡˜ğpEy†MmŒsZÁBœò™îœfçö+»EJ %ë®T°¶A¦`áÑûŠœËÉüGR[&íşéxÔvF†	°×ªf!. ±s¤’Ş0íizÃ¡ lû õòi‹híÙËƒşË-•$Â×tº¯Ü™ŠàB•/7f W
e·¤*RÉî$HâØ;´;‚£’†9°fˆ^+
6?‰AÈ‡ßl?a‰ÚïYI÷Ş÷§—;ÜG–§s[#¯A°€iÏ{7&à" ğ‚]r h™´ÿš¬>µë“Şà¸ut£aµl¸b«T²ÄÁWÓcÓZ©ö«Z ÓÔ~»\ÎÖBU’õeì_’Ïì+ /ëàrfµz Ğ
6ˆp$*	Øe]hÓ³íR}¸!+Ùni·ï¡&Ÿ¿DòóÚñü`EÚË¨»M ÖŞÏ¸‡<MJ’ñè1G3ÁR2±ÂM¹“ŸÛ&|,—ª·}Hò[‡‹È‘œì¹ y¹}/šãÛØ&rÇl"*ÈÚ-lÃÌa[<ó¼p¦Ï•-¹@ÈğBƒ=„Tâö¶Ô&]u98jzh4['ûƒ^wËQáÎƒŒSñ$dÍÍ–¨¾Djxâìj—ÀÛ?…œœç3BRúrŞ–ÄVåË#	±»úY6®T†Å¤oNÏÍ9w¿sĞ:=Á7JmûE’°Û®E/ù¥—$$µk¾©ñ¾w7½Ö\@™pøk•ıß¾şË¯1q„iÔ²Á•ıaeàÛë¿Û;«õÿ';¯÷¿ÿ×XúÕLgaşõ_’^ ×âóÆ‰¿g=x@™ï¹Ì8”×v9B<èÍ]lÔÅcâuâ²^W«×¿·KŠ¿ÚxæÑ4”j\É2ù]Kº¤çóƒöo2èõFcìÏœà7ˆ×—0Ü!‹sÀL4?À}ç÷3ñÒ£ˆZêI<”yi-`Èà­ÉuPz@}á.Ûxr6Ï(AB8%·Ï+ÉCTò3ß=AwH]Ä¦µÿ,ôN-ºäÜ$Äl7œ‘‡ÃÓgÃ_‡£Î±a¨›¨ß“Öh4¸¶­—Ôµ¼àšzÙ9Ùï~†¾ãŞ~ÇP;;;ğp8èöÕw¢9àUßº	ù+„l”Šb|„wœƒÅÏÒŸ4µ˜Ò:oB–xIÀË˜!P<-ÆcU®!K›fğ—È^z¨Á©˜ø‡\÷¼gL²”Ü•Teñ“+#rÆ›¯¾Í"`å¨o†gÆú‚¥æå¢*—“ŠĞ%±H"ö°ò-ªÆéjàa[?M3!Mjµ{ k'±F¨r$R‹¦4EIã<E<½¶’û-âzd¼›ÔœØZÜ}àÔR¥Õ]ë\÷3sµ`z­Õ@'“Åë¸M`LØ“ 9‚ß–Sgoˆ÷¸CÏs †|G/'j»ş£îP¨‹nQeˆËb•ÊCí ÊoüY
#¯G`‚o±œÓğáGĞÂ˜ tŠ]¥ë¨…ßŠ’ÕÁ¢Hb[Hª YxCŒHr¢#,B¥Â¸nÙ.µ]¼È\ÀÉ™$Doïx¢•ˆrÅİ¨3éHMîÁ¬¯™Q©	.Vh.(.lû¡Æ‚ÂÓ÷f¦Ç–8xhA’áZHœãÆÕ”„>•¨u*!i±>®V·,¬:ÇB¯xèü¸	ğEK|lX´Ü”SE^l2 µ˜"*Ñg<Lj ¼¶‹wk‡ƒÖşQG ‘{üêº`óBˆIşÑgéãN$ïH¤Ä¨÷!ˆ‡¼(€•ÕİVk2Té9]Jü.Kaé|·¥½ÎõŠWWH1ÏOŞV‰½1ÒiÔä'ğb?²vòh$n2k9’;p”íL-5(?cq¿oEÃ|	’œ‘Ëh*…-LÈ«ğ¢<3A×[M|Èc=¤Ë§x=)#‚F1î_ã3w˜p€ïağcF¯¸¥Ú‹ÀÒ¼7“şˆEf`{D\ÓÒ›zÉ_j$&€aefC•ÌŞ…Kƒ–ã¤‘8õ\ç*¾¾­!†Dúª…
@¬¬äac.ÜØñ‰êÔX”§]hD„5•xì˜¿Å.cáY–\Ø¿™AìíÄj»û1ƒáñÏ­Áé_òxvÔÆ8)¤¬¥"*Æ™³fÒ4¥º_Ö›êyYg¼–5½œHQVïäQa0„ç¼¾ş-®ĞMÈK0â„D$‰êñî¾—P§<zd=û§ÚuUbÎ›Çïnöìï¾Û r£Ÿ84½d0ûİ`ñFIw³ŸD¬+î öËZâÜ9—Èô]…·#¦#oŞ’Ë@;kCÜ>ºTµ‚(wğ¦ÄALÊU(M9õP\òz™.¤ye­üôDíº3o÷TåZŒƒv‹¥Û´Ÿ\xÁ9óÍ)™ûª7x1„p¸“ÁÅõXV6WÌ:3&ı'ù~0goİCğòÍY.³w´?–²6£VhŸŒ²K¼3Æ˜öçŸ9†£^ïh˜A­4qÀ“}éŒTzàòeš´©1…6F69D±˜Œ‡§ı~o02n%Uì$—MMâní~m@F„¯P„ƒ4d*æsï^ƒX©ñ‹u±„©é]…“Ş¨{ğëxá¦¸AğMá
A‚ÀGˆØ[÷ù™p‘]R&^oİõ²•õİS®`ÎŞáîİ¼Hmxœÿåäì¥¸jı+÷Öå/ß‚Íæ±DÇ$[f“êF£fl=şNŞ1´K.·¸İô}'}ï!«S~ ƒ/(Èõaß`#QÊ¾Ç÷]ˆ2 ca!Ë—rî;±pJ÷¤xa/¨î‹ú +­»Ü{´˜7g·-ÊÎCÏçvfÀßì‹fÒÁ—GŞ‰ÜE=1ÔÈ¶DMM½=-v>¢Ú¹¤ÓÜÑh¡Èİ4$xaWšÈ¨4˜”ûx>y†*‹rx—±í¤u§è²òp0¬^·¡‹ñ(*ˆØØ0 «C#7¢ÁÂvMÇ˜™ a¢éÊ§F+Û·˜m”9©¸³í­BHÃ9„<âpôbïğ´¼¶çÀÅ=a÷qM‘ÿê¸í˜ŒÙ}ÛÉÉ
ée¨_jâáŠŒõŞƒkâŸ(”÷Ù.V:Y9 lÎ·´‘©ÒF,oœç{¦EaRÇ¼«|A¯ÀÖXÌµå½¾Xrè  4~‡µ'¸³—gÒÈ–}È4¯vw_k/ö;Ú	,eI;—!åïİ¼Ëöï¿‡!†|¼á¥éDÔ¨ÓøãkMÜ­Õğ-_ VÛ÷ğ5i#Ñ‰s|[iÂÖ»­ñqçätÜu“„¿T§0Ï=ƒ|wIÊÆA·_ÚÓ ÏáB<Şï_Œz}~R@@:¼©mŠê}@gé{QgÔñës×[P~·Ô´@®uvÅBºĞøƒ6l‹¢öLa!´X»A€¼Ğ"HâëgáÂ©£¡IiËÔIØìtsCırá|”%Š³%>;ü2±üHÈ=P¤Cc6g£?Âş&³ƒ÷`ÜÛğú%¤¢â, uİ“.O”²ÓxÂï‰J0ÊÂ²&ÑgØ@t DÉ”¶ï±PœØKQºçXã¼»5Ô»]²ºâ1Š†2õgùS"˜\ÛGT«äÈ^fY
P•{µ<Ì*‰©+A–0ì½¹4“È•²k±ï—;µÚu¯ß9ù¢ß¸x~£pß[çš¹° &%7ÈŞúaGİÈÍÏ”ª&m¡¹0 QÌ‘öæ¿ ¬Bèã”N(ñÌtÏxÁIÁÒ‘d¼é†%OÒªH%k¿N~~«Ã¯Ç€9IS‰E¬=øú	' –B~J66H•™şá‰HşÿT’ÍK`k×yêl¶ê@˜€–œïÉ‰+Şäo€Ğ¹ãøC”I/øşã)šœĞ‹¾pVÂ˜c™tä½J5fmÆ' ‚ñÿ_8 ÇÌ¸³ˆ’”üÇñ#ƒĞ$´bŸÃ¥¥€ûÌûRIql|‚ı¹Ğxf˜‡a˜ğø¢Z"R—±•¼´/Î¬Şğ×¡!Ÿ!ˆĞ\[ÌÛÒ¯0,ùaä81›y—æn°„C›q"Æ‡T<K·PN²ûñŠÑHFğ+;ÇàûÁ§N¢y’¯O¤Õ‘Õ‰{ÿ;Å]u¢`Ñ%§‡?ºú‘UWÊ˜âßÅ3ÂÏTxJ÷ğxD]så¸VhàL©Å“‹‡ß:“·ø®òÚ¬» ­ccô¬eN%ÕòègmNÔÖ¨’Ï!·#È]ÎNëF$V;5¹N¾J˜dŞÄ!w/e-²ì¬RYMJ1ªàêFA¿.¯ÄˆZÂœÆg+ÿTå³YÃ„[ÓëÿÛŞ·u·mdkWâW”Av$yLR¤äK$Óİ²E;êè¶H)I·•Å‘Œ˜$x P²âxşË<5óÒ½æáÌcòÇfï]T’RdwÎ¹–-¨ë®Û®}ùv<=—J8ÔCÃWı$Å	Ûª¬&^0dÕ†=ıãŸ²L5
Q²<Îoÿg˜À|B¿šw®¶V3š”J¾¢4wpÜ@É„#€:¼lI¿ıOvåıx¤'CN	Á±V*ŞÙJAÊŞ èÃMU!^ü×Hk•R¢IO.) ‘Ùu¼c@e75êF®¸Jo«ï Ç°è:G? L¨ó!I½°7ÆZ ®b(à¨s²PşË ‘Lcµz9ÏaÏ@‹™¼àí9íì³2Uì{å›£îÉÕÂÜ¶b0ííŠá*.<ÂÁ€±pë9â`¦úÀ-ì“-gJ•YYmİ¨V§ct¾1¨2'­Ñus•ÀS‘&©Xet·Ôß9%Õ•úÙ[¬úìÇú`%—h^Nlˆ5§²œ…ÚÍ#a´úŠ›AÀ¡Îe3ªòP!(]cÎ	åŒªÉ‚:ÑQh«Fïñ¢FöšªEd¡›‘Ì¸QÛ¨5Ä9¸¦ÑZ“êA¶YÊFr>RO¦q‘ÒË ]ä|cZ˜Ö<ÜtÑb$§?›ô{Éh"‰äBºfxşìÕpZôGşeãßá âˆ%øƒ Ÿ’øû*î‡µdpÁ¿‚‹‹ô×t"¾ãõ²ŒûøvnÔêš\îB~ú¯æc®ïçÿÿùâ7JqúpM2?kQü„Öñâº´i_Ó4ª8XZq¢}UI!¯zò—õEËx‚ËÉÌem’ğhÊ!~DŞyïª{ôİ—İ~‡}”'X]ûÇ	ïãOq8)‡å½?Ô¾ŠJGï½'›Q¾¢|…¿Ş`@_AåO¡¬&ÌYñí'bBè›|9MÔQüdèã=ëz£‰ß&B§ƒéH|£YÂ¿"~BÀew’„ñG{ãõ±‹Ñˆ&Î”(ÆÕ}•~I“‰F1 )í4µ¼8Ÿ´¯"KJøkÿ<‰ˆäÆh,<cç–^Êâ¶ÜÌ‚á&1iÖ@Å¨KŸ—òWä4K¶©´¹Ø—’ã¤öœ‘Û¿ÍZâ!îşÅ6Ù¼º‰e—s¥>Ç0âLŞÎLsÜ¢‹Jgå³:ˆJØúê»¤+Yu³Ö8£Q€¿pw„"ş³µ^”_ºMÂìBuË‘Y…|Êšô
ô©p8Ü*uÒkKOèTFWp.™ ?ñúñ¬®ÂÉbÛ'ÄÍ¤Ì”pÚ{âú®?#ÀòÜà
ô´ÙçvÄlíZªøwqÅUæH£RecÓõäTŠD2Æ-vù=½³‹U’•¼¾6¥&ÑZ¹‹ˆÀsâs{~ƒ˜hßd>²{-«¤©Û3$E3…Åò_~À¸•–Ôxà O>`‹¦.õÂI·\àİôÖ'Ö¬‚*"›Î]Š‹ÜéXGäje¸ø "fı_­ªĞL$	›«&Ğ 10š1b‡¿]ñ|kzx?ìñm¢5ëZ!`—¥öÜùâ3>øZ%%C¾gšB¡}t/Œ‚Kqó1d£tšœOÇnm†€åªadSğxöÖ³pz±!ıáÊ/"ÒB6ç÷V„6ø¶°ÏX;îÑÜÍ·”—Y˜Î|™?¸H9üçÕ‚épLâ'›şĞ,æv#ˆe–0—e0‡2c.™[Àö3C¶`)<AqbÚáÉá‚$¹¹ÄÔ*vV1%~H04:šáu&w¾nûädïğM·8¥ãä\¬ïâ´€OÆŸx†Ke7Î;ó8º)Aåô œØ²;¥|ªU:g+Ùì†Ü½×Ïê•<TL½~‰÷ßò0Îgİ¶—HûÛĞŞ[¹Ù½,NGyŸ#ÓåÈğ8’G³ıîÇİ(ëm¿§â¾¯QçSİ]™çt·œÜGèy…¯ó™ü£”ÛQf 5›T}¤lW°ß9RĞ–Ùc5«ÓÖöÌïô½	àbé×5İ$åÖ®bwó³¸ˆİ»‡Øâb´6403ÉĞëÜ¼Ğ´‹YÍy{yúIíóhY$¸],r)wªc8X´â—îŞÙ‚•ßÛƒ9¥›mÿ˜?)?éfãÜ5;f…y"qaŠoöW·¶Š˜;h¿o#”äù+ÀÏÑ€œ0¸—åHÎCR[O„9VÅ/'`CÓœÊ‹«ØB£ŒÕÆX+Ç äøfk®ÖÏîó½ka¼~L^võ€híÃïZ3PğJeÓgOæÙ"‘¨nTbCë³Ë„T‘û»ø¼³Óù[Z°<º¶*é[¬¦LQ­†¥Ü\Ñê%üÕÊÃµ•ÌŠbä
 (*fÅØÛ0åÄt£É—=‹éx˜Ï—Òoå"@×Ò
ÿaÈÀdßÒ[%„<GIÂã~T	éšˆ6à	‰¼ »&—l´Á*ÙÒÉ_ÛÛ²"*‰ï;óJ”¶—FßTtdìÓ—Š,‚i}ùËŸV¬6C«PcÆ*ÓM‹3âf6F0	¯¹<.g++­õıñ•Á¶¯<ÿ3ZK5·Q[wáĞ°É´ÜÓ“×ÕgîŸ_P/Ÿó…È”·ÇWAÑÿˆÀObzçïó}^[ŠWÇ-ÆÏÜú»pä×	æ¦.ŒÓ¤øWÿ
	_¸¢,!B$ò½‘¯Ê*Ú³ÒÌÏë–6Ò«çuÑİÒ-K#±5ZM¼ü´àÌEÏ/f[lN|[ëÈR>7°nÖC¦M<Bqî¡ZY•…]T×ÅpNhç3nû¥»F€¿°é¬ÏÎdÀUVa\¾ó£5·´Æ¨œR¹1» ÃLÁ•5C¾fa¾ŒKZ.SlPphPÒ6oÛ~¬‹…•sßadNÑ Æ:2läJá¤?Ãv’vñŒÏõ3ƒÆ)5Åq½x}Ô&²ó°xL¼I‰ÑHÂ>5Í Qºäş’ßÌbTìÂÉÏoGıİ$§Iú¹(ßüP~ã³PYÙš5äì—Œÿ×Øhn6rñ¿šËøKü·yøoW)şÛz­aâ¿YĞßŒ0_c£‘d±İ°=lÌü"8\"V…º‚;ßĞç!¼Tx¾|P.K+HTóe0Şœò›ı£—;ûì»Î:µwyµ¯Âa¡Ë§ŒRı]»³ÛnUVÎü·íæhE…?Øé´÷ø«ux·‘¾ë¾„ƒø›]|½©¶ßtöND–Fš\Éªj,ïzF™”lÓH¸ó÷Ó}UÀfúœ#ÍŠfÂãã“ŞşÑ«o»È:¹õ+[n&ï/ñH@õZúÔ› |1NbóUßë¿óé%^A`jÆù¬ªÀêE„?ãë¬9ñ;à.ØS,´AÏpgŠúËxTêÖÊÀïcU¸9•ûšw“3§Œ–ùHØ&Æ>ªïÉíÂ
ûıG¨v°cz„xƒÌÉ O§>âÕÄ4e7là­ã1`<f¶ŠìÀ¥p¬4Î\6ıXóà²¯7s@àÜå—¦œr•$/&Z…²‡ˆ;È`]WØme¢›<hr:pwVZMTË=%ÓhçºpT¿§ã#Ö`øˆ~:¹v y(r7ÂFÁãÖÊáÑa{ÅB3“dn¥™CêÁ ÇƒG»ÁìE€f¥9!c%pÍH*€¸¼Èj±.¸=‡< K¢¯$¯¥xâôó
Ï}$xÙ‹.cÆI	t•¿‰’‰Ğçªß£C™æ–IKØÂ`7m­VV»È= ÿ\Áª¨8†k0×Å+n!‰nC0[¨PúO÷h­®Ù&àW_eˆ¨SQY|î©ÖRÄv-H>•az`]rB«J+ák½~V¯³Ok:Ô½H·}b¼(€M‰G®)•9(zØcÁm¾õª?ïTÿ¾^ızûÇ5Iè¹0-ŒÃ¥ÿyÃ	¬Áéñøhf[•v@¶®¸}„4(ÛI‘N¸´1wÃ¡aŞ™d±EV6İãı½““öno§ÓÙù–*F†²Ñ@¥ƒ“İtm7”,Ûb:S%İ“´V%÷˜qèSas¸9<—›ÎM&lš„+ôÁ‹"ï'©œ‰¼8Ö(t ÑB¥äŸÓ)6•ô;ïFZ’Ş 9rZêT•QÎ,,j)NÜË0Œ€7€ŒJuÊ˜”¾²p štâÅ¸éŸß §»O‘3¡TZ”m9èÚ”bnm¤£'Ü°®V¥±­~«+*}Ê&\÷­Ê†z*z4Ë€¬áÃ%“Z.VL½5ËX_ÛFÊï<|Rˆl0Bz¹×«‡pĞ0^ÍLº†ÃÓdwô›
MŒ`1é'YãÙs!nrtî@½¾7‚tó¿il Ÿq8	¸_‰AuR1cÓÔa¦D5r›äçğ­Î”Ìò7ºu‰˜¯¼ü€e0üS œ?»b[ÁH^ûE“¢fì¦Y™r¹LËy ­.û£tşl|§îÛ²Í'@™+=qZÆ…à
§Vº¨Ë1Tí}¸aÚü!ÎHfÓ%Ìºv»i™ªcßÈ({&¦ha~îÈI^èvsMnµYVT&²q¤†VYWGß´6Ş·œo¿›V˜Ò[İt6-ã}KïÿPŞ¶Ô¢Û9×j´ŠOX0L$pØ]Äz£`¸%46Ç±ç&ÁhâÃ‰‚Àš¡*ò&ŞÎ¦‰õMüaÈÑ:5,3YEÜ¬®ã“ûõ(´J4“ƒ/F6ç@ŸQpC~éÇgã6\·`}×j5œB/¾j¹ğº3Ñ.4ò‚™ĞÉ'ë4£³à~é'ÚêhäáÑ”ÃTpûƒ˜X»<ê…«2®!©4gï³jÎÇó}c±ğ-«¨4P¡SªÊ–´0‚hç#í iÜØO †ìàÏ`n°“è†!JFôÀµÜ[i;ÿN›wÓ£HóÊ'h #;ÜÎ=Dl 'QØ÷ã8Œ1Úúa"ˆ[ì]ú#š0³~û¸FÏ´¢Áè…a„‰‡»ÔËi|“Ù§Ös‘&1Û†É9ŞIuí”¸[1>x»ş£|?Šé*|ı§Î""cNi`Ó9?Ö|şUƒ•ıñ¿OQHšdAqb¡ô§¢J{¦,b±GP³Û÷^Pü„Jƒ{(”JØªÆ¶	Š(º±'ÃÔêã3ñúp2×…#æÁ"„İ?ÑAC1&br®Vo`rÂëğº:{SlQ‚®ş`-›¸K2T/‚ÕQ€±œ.•WÁ8¥ÕÃ‰DŠüXTœ]8Ú bÛ+•D‡À)ÁÃ*.îb‘ş–N•‡8b¢±<‹Ø^ÿÌ7×u}EÏÍ­ıÄóKVvÿ~j9€¤?aTBşèÓ2xĞ‰ÿ#æÄıÇ~_ şÏã§ÍlüŸÇ¥şgÿıÎñßÛâÿ¸ú,_0ĞÏ+ëİå.
RZ°ÍüäEv/O"”áœ@7gŸÀù’•èÈ­ãÖ1n‘Aó~Í„ZvLãÔo5ÍGzé¨oÉÁ­R\Ç1n¹ºL]EÆÏG€L˜51ÉFg­¬jt!¡b2·7	>¤Ú"‡Ğ	Â5ëD\ç*-Å	P¹lgÓrL5Ö=	ï.’(åI(ÈîÎ¡İ‘ˆëÈí
ò!¢‰Y–¢[ZUÎßV¯ÚoñÈÍ•’	ËbAAy€5‹iù7ğÊƒ_š:üß<@fCæ%lÒ(…*]IeSyIë¡-&®©R/Ÿk„BWÓW÷PCJsÏî"ùÙhÉ²86)M&‘9ßìUïÌ­ÓÌ®T¤ÈËÜ€Ö°›xÉ4æ6y§ÛmÇ[7U–HığÿÉi—4sJLB–fÈBã7ÒW‡G½7§{|Å‹7R|½-ošF0,Í
”¾ªB2G²ÄË£¼Ÿı1^}HÌ÷Ûüö¿a•Æáy„â”#S·:~²IxREÒj­²Ê*jµY®5¶¦ïöB™ÂcnıEŞpŠ#§®#ÉPæVhU­šQ•>}9Ğ'ãHŸªÚ‚‰äÊP`$6k™‚*šL0)‰—¾ÉßRW2¢ÈÂdX±q-óŠ/@¥©Í ÉH-%Æ1~õÎï¿o“Xêƒ£‰Æ™÷Mı^Íé3nş½³Òîîœì}×VqÑÔnÃ'ş–$ó
ËÁëYŒİ4#êlÀµVa•ÆÜ×º·h_Ø14C›N°d«°Ô­)îXÚJ^¾ˆb’£^Œãwá5M,IÅømÔÖkë&1Øj¶Û»½ÓcÜİÚx2µiğàÛõÏú¾^?šøã¿î~ËDgï½xúL'ÁŒV3	·û¬
ÿ§ÃIçíVúvÅ>Yq—”#~ïEpŒ_ni¡›esŸIë¦˜·Ğ<bÓ˜{¢Ñx ¢6S@µ³™PÁ­Š|°Ò•4â¨§œÑ”ñ éä$w54¤áXêq­mRmâG>C^îíö^Â@0½.š”º…‚ÀŒ™µµ‚Ú ùÈê9ì§ØşĞe®­6©¬±¥ò¤Z¼}n‘§gÓ¤^ĞD\óÿÚà;TBïÒ²ze€èé8à›/¢õšcïÈwˆè{:VÏ¹¿6Æub8/_À´{±ØØ€"Vıö^(Ç&35pek“CŸ¡b·Ğ¸¹¯!ªw§Fß&qVœ"Î¨ZL£K_-¯«áPaó6éô:ö“¿vÚÏÉÙ/¼é0qğâ™ïò'_ˆ"P—¼ëá(¡Ú›oÿûúùkJ
IfL)&7¿¬¤¨ØpVªÒ•[Bd µë ¸4E…sUÂ¬æ:@{2‡q¡RWÅ(ní: ± Í'ƒM-ËˆZçQ«`ò³q7	'Üf„Ñ×S{§´+VXÁğMç¯;ßípŸ.·’&Sµ‹ÈPã¶s1Œ=
µ©‰UŠfSµ­qÍšI’)KeàObGüØõQwˆb†8sŠÇ²JF“ÖJşÇe÷2:Ìº)ş2İ«÷w¾?Ø<eöRãfˆX3“ª|ÈÔ”çL–.2Í¬	@©Ñ‰ì=“p#E
G$|aÌü<ş—ahK’¹' ÏÎßÑ£Fgò¶…’”´Mü¤HSÉû‡¸êf„æU%#87Ìó$ê‚jÙÃ%Â/äûÇbIV¯ÛZÍÖ+o÷{!5ûÀ¯FKí¤Yæ%³fOg³•B!Ír§r²ÙóPlY6~Ç±M`­ÊşŞË®¼jïîœrB–˜¸ñÄK5èÃI8õä'Q“Wİ1ÿ	Ü`F¶a¨¯³·*ÿè´®©ËÒi·İ#°an )½-5Hen Ş¤XÉhP•ÍrÚÙo)ÀâæV…Çğ•»h¦Ø³±Yß@¥¶DvPµ03úˆØ°¿÷ª}Ømwzƒ60Şx«V‡AßÇ´kÃÅQ!”u BÉ½<‚´z•Ã†¦ËÖz°s¸ó¦İé½:ØÕ*~+¾ M¸Ll¹qw±E}¹¯’-0ÙÎÌ¢›bN­òÄªß+Ü¦µ:¿ÛH`©¸¼¢Ón%õeóŸòùŞJQ´Í×±å=g-ßø‰. DŒrCâ‹.·'f‚’f‚ ä%ÀEØ"º|÷4¨@3{´[ÜÊ„ıŠÛJ§½ßŞé¶ë5‚§Gc&wbí5ÚšÚ+(6?((çÌj§8K)E­‚¤3»›&¢	P@U%¨Ì:SºYú¹f‰î,:Î,õ^tÍ&”Å%T	”_š³œ!á¿ç¯3³ı–€ÒÌßÖGá Á] Ô ÕCÀYÊ0ƒ;Üšte
m¼’K/ÕÚ2æ.Um‰	A…0™İpd‡ßÈ%|áCŒ"'Ò¯…=b	T#&Í‰teê“gFåsgO¾Èû2zÓ>áš¾×Èp`ˆ"1<y-cbi÷…Ë ÚÀ‹ÖªÛ÷èÊ ¢/èÁ0‹—,w8+OU¯z=†Àš‘u8,GÓ,Ì&ƒ°ıŸ³xV7Gã‹ˆ-­yáÔÔ>=Îˆl_AlLoH´³t\¬úM¦Ã!ç±°üÊGõ^3«ÉÎ¼Å§=?š³ïe9ñôéSVí\ĞHW€Í£…uÍË$=·­¤*^¥wkÔmZ%n¬÷q\À²ß''QpiªÏ3êŸìõş¶B"m9j¥nb±%ÜàÑUqBÛ‹šÇí9a¤&kf¥µ…k­VkÔª¶ÑŒ‰-Æ	¶@ê™4Ö›Ø1¡ôB#a(aì…hxO‘¡å dºRaÆá2ÄUêtåìÁÎ›=äIv{{‡»íZë¬ÌĞäÂğJÊBÔİÁõJ32®cŒİä·FAˆVûÀdl& ¦!8L?o‚¶%Q8|ÅŞ'¹ğp²Ó,z®ê9;ï÷áêB4S£‹¥›Ù?™ñÖdàŒW³ÉÃ®ÙymÒ)¦Gh›E´&+wÉ•›‚/DBÃKH:†ï<ô†=¸{Ã&[…/pö£h:IÖE“ş¾w,ø†\cğš>ÿLŒÄŠ:3ï3t´åæ¤<Üıv±‘[f«wİ0¶ˆ²›IEm¨¹ZœuS7U(®”µ¾¤8½¹3&Pú^×ãæì‰u†4™sl-¬™’-óÓt´1–-ªŞ)(¦Ùİƒ%x)™Ñu‚‰r²İ×Ê—çµºÊº{oöO`÷âBZÜ7<†ï€·5E\½ù‚$÷Aœ6'¸»ŠSÆW¤g|ªƒD[¥3Vğ"‡Y™n+‚j^mV7yì1Üp…‰ä?( zN‚>¥^w£æãZ³öØµ%Rb1ç;Ö.Ãğrè×€ƒ’¤u˜‰aŒ@z7üTé‰ò8:aÆÓZ2¿åg ù—#F}vR1Âé£xçÎß¦š–F‡mI§sÓè‚Ø_²ÏR–DÛj ‘˜ö;>ŸÈ½Rº4¼Sº«ï/¬† Û#n7ìİX±úö%‰î…™3ıf ³˜Ş¼òã¡œşµ$ÔmU]g®èVAqñ›º"ÆBR—IèÂ²1äˆè„…3Fï¦XÓ­Órìø]jNµ„–‘ºÓXi£•š¸1Í÷íví›İã?b_3®.°†ƒt{×Ä
Ğöh|¿S„nW@_ã0gí5ò}oÚ'na6ŠçßSà]ş²®^¼<İÛ³…û`ãŒë|‹zPÛMãÔç»‡oÍ%OƒQ3=æUa¤eó{Ñ{?éq	,êE3x“÷=B~AK¤9ÔlâÁŞ¡N°,$´íÅÅƒ'7w{W›iÈ¬ë¹’é8)ØE€æÒ¬¶ğ¤8õ+å¢[lÓêËÛò†è¢{äÇY%Ğ¶ªl•Ke•ßJÃ8s!­|´.² äè¼j™‹ÍŒ)+ Ú|ƒˆ	vQIŸ”<ÜÏŒ4nÕiÀĞíØÜÎÍNÁ5IRÑ=k‹úÃ4qVï¶‘[©ÜLÕß‹ $÷Ìävü‰D°Áfx¦üKb=¾¹ªıÔÕiÛ¤¶Ö][ŒûÇ/•ö¤ÊN/5İ6xlg¨)÷VºÀhÃ#tï—Ö[ş ;ÎË:oÈcE˜4a˜g‘/½\(KÆ #×ÃÇ#B´N#¼WÓ¿=ĞVÕ§Ì²âE‰%j?Ë’1ë§»b6Ô*{şq»s=ÖTŸ[éWVívsn¾‚Pi2¦,Ù´˜“É˜xcT¯ƒ”YÆÅqañ„qÅĞuQÙÁ!+}±Ætó)nşçz½"áYp¾N¼qlÖıÊ–×b¥o^VYüÛ?¥ó=óÑ[åŒ‰C‚ggä©,ùfmrPó„ŸYÚiV_Pbq ‚ş;ü½ÆÊ:@!/`ù¢â+(ETØ(#†É‚806]…eŠ¨Êe9”±,éhÃË«É <J6Ëƒõ%¶Ÿ£fìåÌš•35²4¢¸Áz¸ Y¯Öu„	_ ë,MaÆ¿!š#IQÌ{ÿˆ1`æ¼ağ³'¦˜¬·œ¤áÎŒ	ƒbå8 ı ¥ŒÙ½\xÍb$nØ`\RLæ ¸Gı}	sAE%$ä‰„Â$Æ‰9"¤4+¨VŠû4ÛÆSYVFåÏZDzóş+eªT ßÔ†Õ>"2€e£ôûg¾·ğG‹lH³}ä%°¦zÏTûÒÀ¢¸ğ~†M ïğdì†@Òkr¶Ç–ÀĞ|’ô6zë½õŒWÚÕs³24'mç„%BÑíÚ²™iË-³)ï§ªv­ú™xŞfN«vV¶"¶şÈpæª2ã;'03\èÔëk1¿#Ñù•3ñ°ùÙ©m7ú‹“ûC*N"CßO’Àîü¬ÖŸ¸	¬X‘Ä„H·$kzµä4|{kBİ6J0“öt:¶P»ÛL®éŒJu9ÍPCZšìI‚ÿŠC“–J/‘½¦;Ò ø¡[U	„½ËŞ.Ù}„‘6²;»/“ğtà_94á‚ÄÇQÜ/…!kjí{t=ö#`Ñ¥•oyÍ0ªáôPntEÑîØ<FÒŒeW2ƒ)q®«qk¶KK+6BénL8©™=¼Ğ‰{ÎD_ßùDîÃàŸl®•ş¼`†)Ãv¦­˜İûK°’Yf«à´àÊsb÷Ë]æTr•¸V¥¨~(Ù{Vp q«¤Ûìí…GÛ}lÖ‡ó¬ı»<w…R:xKI™,_a]°êÌtª/ÌîÖÀ´LM‹,GÍÌèd÷pâ|ÓÃŒÃ'z ]ÜoiæZ§|M¿§—‚øòÇºÉ*âèıÔq5{ô,0¼îäÜ¿¨¹ƒğNÍúô¯»óM4O\v]0>6 ²xS%´	\ n¦¶§t†éMåeïï½Ú;éí¼:2zG»m¸‚—=Ø£½˜ÁñÌ/×âHÍUşnV¸Èë»¥¤]Ş¤¦vNë³HÈÊá¹;1GâóîÏ!¢³8LËjAf(åQrÄˆÜ½ÖÂJùryÁØ˜á¦İ†í4$›úcôÑàœ‘“=s'7ª£¿ÜˆD<2ÌFèÙ!ÊîÊ~ÂY(g$‚6é"+‰ /
<4v§`hôü/B?œìG–e#Îš]CQE;ïœyg€íÄĞqQéŒƒ,sŒ9§–õ€Ì³ÌëÒErÆÉ+–0wŠØÎOwÄ«LÊÓ†şg‰ÿóôñãü7ü¾™‹ÿÓØXâ¿-ñßn‹ÿVï§oEqãÓ=Q(nâHñ:k06[ÒLíúúºv\y!·'ƒìµó¨>€»D½‹aª¼¶*ÁWŠ²ÃqÚVUÔ /úB¨pùLª´Òö¬®1%"èOÁÖ¿bˆù	{ßÑÁq§}¼ÿ7Šä/QD…{ßuv»oéë+üNœ2æ,LQåĞ¸
ô™ ïºfS…K)š÷Š¿UÏ›è*Lˆ­ĞœuÉß?º¢Œt¼ÊˆÀË|„¶~b­«>d?jv¤Z‡0NĞàxê÷¨Å–Áu¡ZÙ94‘»‘qá|V}ÍŠHÊôç‹ç¨Ş*G­~ûZxYÏŒıŸ
xçÃšŒâ/ŒÿÙl<İ|’Ãÿ|²¾Üÿ—ûÿñ?7løŸ'ï|ÊšÎô1@­'‰qb\!—ÜYüeB¾¥² ‚"¡5.£œÄ5¼¤—T‰4 Y ¼öĞõT@ÑßÈ{bÏëû»¢8yÀL¬(au›ãáÑÉŞkôR?ÜÅ ¿J¢9“àâ¦ŠHék?´x˜¬¢öj)éÉı+”'Ó]ò¿§bwÍQœ²GköÜ¥§ÜÙÙû;Û=b;/÷Ú‡'m>X¼Åñ
,Yı§û’YÜgYİî‡İ7½İ“ô=è¶´ğ½[Z ^ş g¢½t«`À¥%’yù}{ÿÒÃçÁ0ó˜~ŸÌ™m•(˜s¢ì%gÉqxíGä¡ºëÈ†°ÒƒÈC§äŸ=Jé¬9¼\ÔÑ=>¦ºÏ’‡víkJ†N	*Š5ÔÖ7ÙşI7÷âYö×	Àt‡—Ö§T:4A’\ „½îÁ$9Üm¹—cDX•¯…û?j4$=EQã©PÖiO- W­u=‹
f¿Hùß¢è×™ù<‡ë·r1é¯è)lè{”
8¬ŸW-òÈEĞZ`ä¾¥)9»ßÃºü0¸D¦,ª"x¼F±O´ÖĞ&.™§ı¤ÖŸzµéÅ(Ö9Mªl4šÏtŠ^Ü–€áä€[™5p)•ì®>(°p?îNRİÜØØxúõîV"%>©Ïº¿¬Ÿ«7ªVÔxv®çº][¤]÷˜àt´r?‰Æ}xö¤÷d3×6ò¹kfå5«`Ê­@OjZÃu2n:3iÚÕ‰Ù|æª©š7foÁœÉ¼Ì¦c!µuÜER»Uvk¥ù“­ğÌsYs
Qw4ĞµYeÑ¨lL·gÙì3Çbª›ŸnÏ2ÌÇÜ<~KÛè'·Y•µogÌíÍ:ŠÌÙgv³Iıœí‘0»sÕy£>TùÒ©ZıT"Ùl?"f¿Ìú$Èú	˜=šAJ İ.ƒäİôœ6†ŸF=ãÍDV a¢8oq'DPqªéğíeDËDT0ÓõövÛ2ÕHxô˜F%%ğøğà}5¢X|€¡ùxYxÜtá|2JÔZ¹ë_Ÿv…?ùıİFÊªXd]Q O¼¾¯÷M	0h´8ß—ƒöáioï¤}`¤·óYuo‚º*2Nˆµ¢jÀÒ¾OBØ¿ÄĞª-l³Ö İÇ|.”­şzÅÑªÊ_’¶[k~ØxÑ§[UÖÀÒUMüİŠ£ùš§óK„A®yŒŒŒ0¤uÄE—~¼)ÂEÇëü%,¢¤Š†ÔÙ*>U!eîÕµ?»îkGÇm³æ1¯Eaä˜ì©Æ‰é:öÎ>•*ö~½Zä{CU˜ğ&O	%÷Q–¢TœOù¤˜3bÔS:é2^äÀ‡.š<1¬.Nb8'=<á<{’}İreX7Õ†›9ëõ³Z½÷‰•ùş…z.D%8“IˆáVj+¤ë=bá9ü<ƒßçÙ”c¸â%õÊÇ`©&uìØ>U¯Æµ‹È÷'äQáQ]4µx—q=Û\ñl”ËÇ[ë_\Üó-’gB›¦4ªAŞ€Î;Iã¦0²44õŞ3L±f)I$–ˆƒI%á*¡Q{V£œ%Ç1m+€¦VvºİŞNç@]tîc…B-q‹jTÄÓ©•g¯O%ÿ„ÖGŠ›’ÎDÄõWtÕè|óÚÅ˜ñh% k=]=õ\&oÇöë½ZxŸ]YsÊZÓ0½µq·h-Ô¾‚ö İùœaÍªU~bÃ9ÕB©Á :ájãù˜4’SïGÁàvÎäb"ñ'=,ª6œ¼' Ä x†›*×ìV9\®íüFAº˜6p	k™Çš{_M?ÓTüÁü9Û‹Á]„‹¢õB¿şPm¼èÕĞ¾÷îŸ˜À8–;í7íØw;=Ü=ºó}§g°.>1Äağ¨(&7Æ2§=Q†XÏGÇ³GÃ}…£%8ÿĞhTşğ{ç—É{Ø¬Ô/¸xL‚çÓíaß¢°)Á¹éÛIœÈï^ò^{sù®_•5á¹q9œ&é7zî:)mËùã)"´±xz~ÅÈlä½÷^à¨1  7dÊÀ¡¦ãÈ‹˜¼2pÎİœ³KøGÑ*¡ìbÍ±ÏÓ6RfÎ)è]òzvá)Bş½.Òç {1ôá˜$ÑÀk°q8®b]QX=;î©@Ø¤ß¾ıÑq
m˜ì–.Jşb®’yi7ú9Ùƒ)öıÎÜì<JQ,‡õTH §lk·‹ï5hòpî¿C¹>ğ¿#!Œãí{çAu³öu}ù8E«?•’ O\ fÒV®{zŒÓ€}Ó†fvº÷"-eß­‹ü¬4»9¯‹:×4çÌ^ù‚‡¶äÎ%«àÿ[+iTûMÓÙœ¥ç¥º¢é\¶·Ï#o÷Ø÷ƒ°ão ×—+Ì.ôåï
äÄü%\n_¿ÕŒí[ÖÈRâ.+­øóU~ËÍ·=,dåÙJöÕ>ì|†±{ğSˆ+rWÛÍÚ&Ê×Ìíæ$›Z»ÿÑMö1zº`]bÇSN5DdAvCã×Æ~sÔİ‚ğØëÂHëOÍuÒÀ_o4x²	aW×Şİ™ÈûèÆ¦Ù¬6z”·aà"Vş%­AqŞšfÚšÜİ«ÿŠp(d^ÛQ.}5ÏG,¾'Ş‡-®Â1ÍÎ’şeŸ¥º«·aÆ?¦Şõ¤øÜmzN2¯xiæSŒÚ¬ŞnIRšÀ¬7­bæG"ã“Zİ²Ò°3ğã_ÿSÖ’ïo¶n2SXc®Ît¬ ĞS¨ó~ıÇüê4ó›¢úNBöÓ4N”i/U{!-2Ù*á„¡>! d³¼+/¢3 ¶6¿5d4›ÒĞ~à`Çü5jÁò¹éQQ-²RÒb8
ô…â*ä¬™Ê€‹³ºPé8=·Vç·—ÑœiØÅ(T˜ƒÆg?X|f‘1;âke+³V²ma¹•§-<»ñ–ZßuO´ÔÂ¨K½><=xÙîdkì¡m,Í\K°ƒ³b½ÖxRkÈÊP×(:6>§}9¬CÕÍ»şë²—7
t§·/î víQT|>ÉŠd¢¢S<b0*	b¦ğ9àiÂq;B„ô8—(<ƒ’Ú¿şƒí]`*E?D'Ì=;-B´ÛÀJõåNÆİ²gp<Îµÿ5ü¾¬ıocãñÓ¼ıïæã¥ı×Òşkı×À´©~70nÚkğg21&«¢/bïËXBó
·èÓ}RGãµh}ÖË…ïş”İ~rÎ·JÜr[6Ã–Ô]$Â¦‡ãjŒ6Ô8"‹ä1By/Ú*†æŞqÕ RwÑ¼tåâ?Q¡SîWı£nŠk8šÁ—âÈ¤?“–	:*<üsÂJö‰ôöçE¼Ë ßC`R¨AB³ò:SOI>X*•ô$£s‚¤Mı9Çsf¬¼AO–CÚÍ,Ş<{LÏ„™	ü~¢~+Ëxú”P±TÚ\ï(fmµ¡ûq
ßi¸õ>Ú<Ğê<íùÛl!&p“[Ñ³Z"bÓ˜µZ™i…/«FWæ[”,"›Š‰Ü´^‡0ŸRİÓK¸ÓG—qkµ‚1÷LÔ<|‘C°*[,8M¢´ˆÍˆå)ãäÊ÷"æÕ6Êµø.Zì¾È;N»Õ±)îÅÄ5÷NÆ³‰º™NÎ÷~< VĞáâN¥Å0::€€àM×ÖA¾ÍåÅ)[E…lU$¾‚Ö~òv[:f,êS}2éx"@TL¨ ^NÈC©Ö48lPİ”çšÃ1«ÆyoÑLÜf–ÁÊds!$6)Œ|
ûK°ãŒYZ‘±Ÿ0üÚõ¦è|bØ²Ã^BÍàíàéZÂùĞ—”°G“’è!ŞhWà‹[ 
q{cÇQEü´q€Şƒ×|eJÏºR™¶v2Dá×t‡H/´Æ:ÅÀ›U!†à4Ö-ŞO~æ“t&—!˜	{¼`vµ<µ ¶Q&JmÖ“;¼™@Å¸¡è}ıöON@|{Œß¢œ¬ªæ'	H—úßìôjƒ_)Ê±V*mPN vaİ3'f¶˜BU!8+”­g.óòXäÓô‡ÓÚÃHŞoÿkà°C|Dn½‘7'¾6“ğĞ54ğ¨‚2‰±]89·áÁƒ4 3œ±/¾j*„,
oé]TlİéEYİ*q!Ñ;åB?pE‹˜ÆÎÆm8«6UÕ9ó¸cøp56oş¼“¿	ìbQeÃxg!¹lzLJÒÉŠÌ{ºdíñŞG¾$Té›Xì{?ˆ#nÀ<[UÔF`ıc®/‡ÿŒØˆP!oã¡¸jªTÚ¡”Ó·czØNıÎ³dó{˜Æ¦¢K¼Îî¢ÑCÕö;w’¥g¶D{Èù­o«şb¥ë¥»Í%Ïn|–á.˜Û ¤yò‰7AµTâ{Å¼«<†[8—ÜÏİ Òñ±yYà9ä~†jE"§8´rê¨]ªíEÃ ==ø]:¦"v®U¡1†kÊ,š€´}Ìá³7¿£¯“ÛOà|øåùëiÚ@Á¸6-AZÙv&’ë†HÄ{×'R<)pS%p9#n,«4Ye“UdÃñî˜‰±+Ì‘İ¾7ñãn¡İUY+Ò‹Hx1’`:Æ›pâ)d€!„=÷#GDänğ€Ü®
¶Ğ„R©¸§‹Bn@ù¥ék#2lo³à*i3Õ¤Pˆ%²/1™S×H`f\×ö|¸.1 3Æ qË’wÔ–in®w/’Xáuû©I”‰J¶*ÎÖÓ,^ŒÙN[4•ì^jİLwSëv*öìÆ¶ÊˆÙ[$·\\D}ÚÌÀ¶)^™w¦óŒ”3ÆJÈœŠü 2'/l±*ùr³vBÖMK÷³öBu‚k˜îN³[Ï¼j—÷\›if_äH—¹`Äçø÷Øör‰®Xx›ëÂ/ê ´¬SÓf-‘ÈOĞ¥“æêƒÊŸş1ôÆş%B]yCØ(aÓÕ^¾rÀ{r
RRù¾R[¯êÌ(HªR¢BÌ]cù=•Ğ´O21š±âò÷ÆĞhØQ$XÄWÌ•ÅÙm‰Xåú±×wşòÿZ}öãúg­cş~2úŸFãéú¿±ÇKıÏ—@ö«é¤6|ü‡õæFóifüo<]â?|ıŸ	dĞÅ¡wœç“N	µeÏıÑËÜˆß=¯ÃRK3¸O/ªäúÖ'í0RÉ[UîYRW¿FÂ|Ö'`.~&ËĞ¹Ï=ö.ò/RË:”ãaµ t_ÈÏëŞ‹cÎœæyı¾?Ib“Ø/7ÙL<í#v>M8Âó®¼ãËÕêóºøŠ"± Ï2oXs×<NûÙ"`‰†|á"
Gì¡µUV«ÄüÌ9	Y0Ë4hË)É† v–ôS$ÄçÑ‹ye*Û Y²4`Àpè†BªÜçÀ(½hÀOøó¼UÌhUJ-ñ±²„Ô×oD}G4Ş°*’¹Më¢´,iqS#ªg^òtÑõŠzÄï
„Ä“vIÊ¨•Ä™l-ÜY|µª¾ S¥RJòêkRC¸PJi›‘­4‡ M_øÄ—´/²¡ú4ÃHØ'A,mš±ßaó‚kV—óoËÏ­ÎËÏÇŞÿ{º¹±äÿ¾ğøë‹úKÿÆúF#kÿµÑ\ò_füÏ\<ó'èÆ†ÂJc®vòÉ¸=c.šU±é%k<s¡
5á/Ñ2Õˆ$Æ—¾ëÔºß°Ãƒ¶cšj©¤I˜1¦,İ½Ã£ãî^×1[s9
f{vñ’kŠÎ.:?ÒO¸tÃÏ.şÆÌÉ çÙYÓğr)M&â¾i5
³*ÙªjÕYõŒwù'\4d<O¹#ã±&4“u/uh·Ûî¾êìQcƒµ'^]²ÙÃ`Ì£?ïá=>y„cÈ•#äÉ³Ö­”Ñgr±É§aÚTWNuV•AĞäÉ¾'wHj¨ ¯“¡ò<&økJ,¨ïdHÉXI%‡éfğ48V:RšmÓ­çÄeTS“ëÉŒ!Ã´øz>gr@!×_sVõJ|;‹Ó:§KãêxI6s†
ÊÿøË/oE‚™l’ä0±=²kÄiân³-Ÿ#SIO…©6uMhÛ«ÅB»ºˆ…¶˜Ö|É±Ó˜Ï8h„x†m °& ©àoá¶}of‰®ò (2ÆM?œæÅJ”·Æ[5ğŞ@[Öµ.L¶XSš­ù¨cğ°ëìqÓS-´ÕĞ›¢×X”6•u“’j—¡/ë##¸ì°íü¡°@à^ãá«íôä›£“…f[Ğƒ^Øküå]˜ŒàÒ„Ğ2kÎ’ƒşÿŠÿï=˜+}eì{Â¿ä›yşïñÓ§KşïËÈÿ^ñ¡÷†êø„ãû5
±æ>Ù„Õ²€'>Qa z,†!Bgy8<'4yÜ9/=(œˆt\ Q 0^ä¤}ºßªäNE’õtƒ¬*p‰Xw˜öÂÅyÁvÃëñ0ô()äÜ
yò#ê÷£Ó!¢{1C
¹Eø <á}4‘¸^üÎ°'Ïë@4Nº7aN¬z¢}º–æhâqüh„±0¹pgš…’æ×qTfK5¹©|¼uG1f¶Úè² %¦Dï!£\¨©w>f˜”?”œq¡~/%ˆ÷tşËX ÀhúñışsÏÿKüÇËøÿ
ı_‡Ï†°±íÈÆÏ)„ ç!©Ì®Ù…ï%ä‡Ëú|zÉ/¢æ8Wä˜ÅaxåÎ¡†æ“GŒ\ó€ôŒrÅ¶¿ïné§ÂÙ:Èä*=„UŠ°ºâŒãïrÂ8°¡ş’‡>b[Q!å§¿ØC{×Á´OŠLêœ:…ÙÖ}¨Ñ,Í†kˆªO!ópÓ-ÖÓ¿Ò™À	mS&iÄT§qMòu"’$áë½Ú»4$¼wÚ÷$—s1éŞ£‹ Ø5]‘ëÌëàAš—Ã ¹±g¢ær"¦çi‰äuNÍ.	E*Í‘&Ì‘\ûY×Ÿ$|¦<+š(³z©Í†ÓÎ¾N¥\u;ÓK<	_ßaBbK(¥¶^4§6¹`È™$Æ-Ã“1Ÿˆ»XÑYÄ8`±êoEm^£éXzÄœ=£`æ:SÇótI, 	(5Î4Å*EqÀ8ˆ$OH¡Mõiq‹‰—AN¤½a`Ì. &VG¡¡ù4zçw>ôúş ùÜ,½ó#ÚĞFôÎ
Å¬R+Öôöñy­à} &JÊ>Ò>'ÎŒ¬*ÃÕït®ÖÅxß.ÔfÉ§O¼¦ş‚‹F_íï±Œ„{éÇÙ-Jã£¸€”Ó_L
§[G1lÆŒ¾ı”@jõ¶3¥îpcsw8ŠãîÁ}m$úóÀ6Öa„¼ÖX×fÂÂSá”ÛSC†¸9ëòË&ƒ-ZLP7‚d‰»·^ÆM/ÉY'øc±w ì¿§cu‰ˆoGBl]b<a‚İŠFF-DœÙú¿ûæúæÿ67fí¿šëKıßù<|øÕø<lëÿëüÇjc?dšâåóäÿ7øJ©\$#ËÔÿğ¡ã<|ˆjDø†‹X^éfÚ˜âùjFY¿ìñ½ãáC©xœ_Q&WÑKÒ·(‰é]Ô
ÿ1}#Ô0é«™µİ9Ks*•›ÖíµºZ§/³ïäq‘ï):±– i‚ì% ~-ß­ÌpiºNsÄÄç>õŸ(‡¿G*û ”qóg\ñÈ1fhL¿ÏPIL’ÅkÈ¾¦@Ù:³ ÌLYU«°@c^ä®RİlQ–©)q¾
4¶E%Ùæ0O3CË:M),Ôå²µ‚™o¨wo»[1»
Xïš jÓH˜	
µp0Ó¥-6K½ñ¬ôÎ
df‘¥û©dçÓO*eEÆ”÷¬¶O¹.§Qeç‘ĞPYõdvîÂşK¶}¶¢›ùöŠn¡éªîyºn^#n«¤ï†JE‹¬1ÉØRË-øÿ‰½p<ã*
ù¾ ÿÇÓÿÿ¸ùäÉ’ÿÿ2òß£„V=œÊÿ>õ#
T³²¼3sÅâR•Z|#<ïF¾Ï×ãE8†×x ´@”¦tOá%7¿åî¹òz{„ğ‡$bbF¶Jœ†òL_ƒDqâpo¸Õñù0<zãz§½³{Ğ†iï¾Û”*I—LèpA?€"nRwëš!wÉKJi…Ù:¹¥2*ÊxD.ŒàÂ†:_z1ôŸo»Z1²¥÷ıëî·ÏØ®a<­F‰„T{¯’(e‰?ŞWŸUáÿÔÙ?Œ˜(©Ñøõ?3i#±Q?J°¹«Ë}€lÈÅ¤¯Jüõì×Å’„C4‰‘şùyTˆ[÷½·G‘×‡š ‘‘]œ=ñ$éÇ/(4H¼‰Yğ(hâA°…¹÷’•Ø8ÿãpˆñÆOŒrz
AÅ¯Ç:¯,®|á¼‰Ædkm“×U‰>¨fH[Nˆ?]!ÊB]Ì¢®©‰ÔPKŒ1í´ÔLhâò.ÄÉl*ŠTsÖ§ŸÀhGÂMDİ|`”êŠ
9!™_QjŞ/q„3çäçS³5©§zsxZ¢±Êy;¤Ô%#ºæÑÂÓ¼“Ù·ˆ>²m¤‘‘(p*Cì÷§Œ©;AFM¨s´0fÂ/ŒÊL|ŸÕ!}ÆX€}Ç5Ü½jƒ:¬úª‰«†&IÃIğ*¶gæ­Şä2G£E+Ôè¼4€[~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–ŸågùY~–Ÿÿ‚ŸÿŠÏ½ü  