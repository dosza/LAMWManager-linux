#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1921334511"
MD5="dc5e1d65d8ffd9223f01bdf891d97e9e"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20585"
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
	echo Uncompressed size: 124 KB
	echo Compression: gzip
	echo Date of packaging: Mon Nov 25 14:47:14 -03 2019
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
	echo OLDUSIZE=124
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
	MS_Printf "About to extract 124 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 124; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (124 KB)" >&2
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
‹ ¢Ü]ì<ívÛ6²ù+>J©'qZŠ’c;­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»7úa‰À`0Ì7@×õŸıÓ€ÏÓímün>İnÈßÉçAóÉöÎÓF³¹³µù Ñllnn= Û¾À'b¡òÀ2]÷ê¸»úÿ~êºc..ÆÓ5ç4ø—ìÿÖ“­íÂşoî47Æ×ıÿìŸê7úÄvõ‰ÉÎ”ªö¹?U¥zêÚK0Û2-JfÔ¢éøyl†9<Æ<ò¨å,Ll¡Á†Rm{QÀè.NmêN)i{?‚.¥úyî.iÔŸÔŸ(Õ}±Kš½¹­o6š?BeÓÀöC„Q¢ÊÒ®›ßBâÍH½S/ øû¨uü
¦ç@u2:0˜ä"0}ŸdæDÅ1\‡4ÛQrêìLı"œTè¥ïíûg§‡F#yl‡†Z{¬&¸˜ññá`Ü=ZGGÆ
É‚æ"x»7èjÚ~:ìŒû/:¯;íl®ÎÉ¨3zãÎëî(knÃ,ãg­ásCE¹JQ ÔhX©R Şè4ô‚«"ßa›ªØ3ò†h°oµş«}½V\‹JŞíáÎ¹J¥œ|ó;Œ®¨5Öu\ç¿ÍÙÉÇ7D™ÙÊz×rƒKWH5soÍÔ[,<Wcg”o‚bì¾aèN`[”)Ğ4¢ÿÀv({´qM”JÂ+=\øzº>õÜğ
YE‚Åz=XÕLØ>£Ósk°ï!ö,²<² ‹	lÂNºlí@R™š!Ñi8Õçùä¯dP_‹l?İ¢Kİ'¦ºö'òAÉnÂb*«b×T*‚:>÷cÎŸÖ¥ı0 gĞÌoª 
?l×2j›°ÃÓ3duCMhQk	ˆZNQ9Aé4Í¬ë\í¿t=E«ß*€/€Å$ô,xÈˆ;€³á7X=¡¼éÊ2¾ó‚¨ù4E™Óğ¨SûxŸ/[)àÒÌ4¡²ª†µô7Ñ.Õt¶AäæuˆâÛõÈ¢33rÂ@ZÙóNÍ&>µD)kS¥’u¾ö§µ³ö=Çmxa‡bFx>·C>§N/é”PwIö»ÃşQëW£ÿ ¯[§£ç½AwmÙoòéô	®’ZÎ²ÙË…É(c@8"Ø]B/íÔëuu/ ¦•røUâ*"wŠNA‹ëÇó•ÆRŠ:ÂEr’*•L1ÈÔ¤@¬ÄM±ln
+é¶òÆ˜Ø…i»)¥
>q²ºõ|àyaÁ}*•LcUcÎ÷IÔ©‰2ç!òüVùc“Ù)'\‘•Šlaœ|XßŠš´±äÁ×Ïúø¼ph»s2„88¤V=¼?Cü¿³µµ6ÿÛÜ|ZˆÿŸ<İŞùÿ‰ÏsïmRÄhÎ&í*•&éùàùx€6çš¬üŠRy$ùĞï¹aÃØÅt-_É§–b@ä[£ü«ã¼ú«b~1ı¯£„ãÏÈı;òÿ&{òú¿ÕxúUÿÿ3óÿj•Œw‡ä {Ô!ğQ[ï¸5êbÄö+i÷Nº‡§ƒÎ>™\å£$éEda^qñ¢Â›GaÁÕ÷dÏ¦™$Ä>Yx–=³!'`†ñqJ…õ|Y`5¿÷Í€‰¨NVŠ1á‘_"W©ÊCâŸhšmQÇ^Ø2
˜Lî\æ9eÔ™3˜GH<#³À[€@×tbd¢c:Û%gaè³]]O†ÕmOÿ2E%«ÈYÍ[í­ù+G–_ú¦ËxD{f&L`¼Š2³›3F<Ó¡À™:y«†ıÀ{ÓçuMÉ[ı8°ûj•¿¤ıç%‡³ú³¹ıµşÿ%÷Š…WmÙEƒ:;û‚ñ?löÖŠÿßÜùêÿ¿Öÿ?±şßÔ7Ÿ¬«ÿıg ¹ aê¹¡	©áÈ ñmòï€Ì©Kv BÛ¿ˆG­Áñò)ÑI«5h?ßÙÒHËµÏ¶¾cWªé44!FÁøğ?±<2ó§qgZ&q=Òo¬7šX–[~ø{`›K›òb¥¹˜ØXğRx€tĞocİ¹¢ToŠ{h³p<µGi%Øf,¢u—†XfXÈOá€õ¼°úX=Dn‘æuõ1 ¦L,]z18ÀØ	/»îíñaG¶]’cˆ¡HóÇû¤Ìœ*)9ÍŒŒ'õF½‘Çs:8ÃB5‰ÈØÒ­Ï
‘D1NİæØ¤õĞœ3= Äã'ãÆ¸¡J˜ Ëø¨ûlÜoª±@wì	äPU	¬}p˜€!Dã¤Õ§³yå sÔi;†zëÄ/;ƒa·wbÄK¼YzM©f\G[ —¶îµ¤­[—½Ø€$Ë¸üagšæ  hs7ZYWZà¯rq ‰!(Í\yQ3¬ôx
ñÇÕáÜ•aÁ€\t)yûx“À›á‡‚FaPÀaÑ%O-|N˜½˜|ø§cO=>w…àÉä†ñ™Í¿ˆãİ¾øÕÁ/I¹„ßëØ+ğ	SÅkã%İ•0¿@ué¼î€Ù¹8³§gÈíÅ9¨Š&cÛˆ+åj-7H%QÕÕ³“rÌEjë¦ºß\÷[¢Ãõ‹"½RåozÀ=UÈwi…„Ÿ+«px‚„G(àdqºÑàôäIùGa±?ÇZ$+Úf½¡MÀ5¨)Øx®v½Òöí[íñMu|ƒı¹ÛL·º'§¯ÇÏ{Ç.ìÌ„è–Ç	óğåÉ¨uxÃcÉŒ7uy¯ê õùojÉêRA,>•ËëÕ…Ş”`Ã£X®KñA¨DTÅAO	ëVšò$g¡¶º$4öñ>á•õ£ š‹È‹ ¡˜ğpEy†MmŒsZÁBœò™îœfçö+»EJ %ë®T°¶A¦`áÑûŠœËÉüGR[&íşéxÔvF†	°×ªf!. ±s¤’Ş0íizÃ¡ lû õòi‹híÙËƒşË'*I„¯?èt_¸3Á…*_nÌ ®Ê$nIU¤’İIÄ±w:hwG%/r`Í½Vl4~ƒ¿Ù~Âµß²’î½ïO/w¸,;Oç¶F.^ƒ`Ó÷nLÀE:Aà»ä Ğ2iÿ5Y}j×'½ÁqëèF%ÂjÙpÅV©d‰%‚¯¦Ç¦µRíW1´@§©ıv¹œ­…ª$ëËØ¿
$ŸÙW@^ÖÁåÌjõ@: lá:HT°ËºĞ
¦g;[¥úpCV²İÒnßCL>‰äçµãùÁŠ´—Qw›@­½Ÿqy*š”$ãÑcf‚¥db…›r'3>·MøX.U?nûä;¶‘#9ÙsAórë^4Ç·ş°Mä!ÙDTµ[Ø†™Ã4¶xæyá0LŸ+[rá…{©Äím©MºêrpÔ:ôĞh¶Nö½îş8–£Â§0âIÈš›-Q}‰ÔğÄÙ%Ô$.·
99Ï+f„¤ôå¼-‰)¬Ê—Gb%võ³l\©)ŠIßœ›s*<î~ç uz4‚o”Úö‹$a·]‹^òK/IHj×0|Sã}ïn>z­¹€2áğ×*û¿}ı—_3bâ&Ó¨eƒ+ûÃÊÀ·×·vVëÿÛÛO¿Şÿş\ÿ]`éW3…ùÖIz\‹ÏK$şõàe¾ç2{âP^Ûåñ 7w±Q‰×‰ËJx]­^ÿ2Ü.)00üvhã™sDÓPªq%Ëäw-é’:ÏÚ¿QpÈ ×±?s‚ß` ^K\Âpÿ…\,Î3Ñü ÷	|t:œßÏÄK"j©'ñPæU¦µ€i ƒ·&×Aéõ=†»lã=ÊÙ<£	á”Ü>?®$QÉÏ|÷|İ!uM›Öş³Ğ;µè’s“?°İpFOŸ:Ç†¡Fl¢~OZ£ÑàÚ¶^R×ò‚hşéeçd¿7øú{ûCmìììÀÃá wÚ7Tß‰æ€W}ë>$ä¯²Q*ŠñŞq"?Kßnj1¥uŞ„40,ñ.’€—1C xZŒÇª\C(–6Íà/‘½ôPƒS1ÿğ¹îyÏ˜d%(¹-*©Êâ'WFäŒ7_}#šEÀÊQßÏŒõKÍË#DU.'¡Kb‘Dì!`å3 [TÓÕÀÃ¶~šf<BšÔj÷ ÖNbPå6H ¤MiŠ’<ÆyŠxzm%? ö[ÄõÈx7©9±µ¸ûÀ©¥J«»Ö¹î;fæjÁôZ«N&‹×q›4À˜°'As¿-§Î<Ş7îp‡ç@.ù^NÔVıGİ(¡Pİ¢Ê—Å*•‡ÚA”ßø³F^À1Şb9§áÃ¡?ş„1Aè<»J×=P¿7%«ƒD‘Ä¶TA³ğ†8‘äDGX„J…qİ8²]j»x‘¹€“3IˆŞ4ŞñD+/<åŠ»QgÒ3šÜƒY_3;¢ S\¬Ğ\P\Ø0<÷C…§ïÍL-qğĞ‚$Ãµ8Ç«)	}*Q%êTBÒb}\­nYXt…^?ğĞùq"à‹–øØ°h¹1(	¦Š¼Ød j13E< U¢Ïx˜Ô@ymÿîÖ­ı£@"÷øÕuÁæ…“ü%¢ÏÓ=ÇHŞH‰'Pï?BxQ 	*«»­Öd¨Òsº”ø]–ÂÒùnK{ë¯®bŸ¼­{c¤Ó¨ÉOàÅ~&dí>äÑHÜ4dÖr$wà(Û™4(ZjP~"Æâ~ßŠ†ù$9#—ÑT
[˜W:àEyf‚®9¶šø2ÇzH—;Nñ{RF(&ŒbÜ¿Ægî"0à ßÃàÇŒ^q1Jµ¥yo&ı‹ÌÀöˆ*¸¦¥7õ"’¿ÔHM ÃÊÌ†"*™½—-ÇI#=q4ê¹ÎU|}[C‰ôU€XY1ÈÃÆ\¸±ãÕ©±(O!»Ğˆk*ñØ1‹]ÆÂ³ ,¹°3ƒØÛ‰Õv÷cÃãŸ[ƒÓ!¾äñì¨#ŒqRHYKE:UŒ3gÍ¤iJu¿¬7Õó²Îx-kz9‘¢2¬ŞÉ£Â`Ïy9|ı1Z\¡›—`Ä	‰HÕãİ|/	  OyôÈ6{öOµëªÄœ7ßİìÙß}·äF?qhzÉ`ö»9Àâ’îf?‰6XWÜAì)–µ.;Ä¹s.‘é»
oGLGŞ¼+%—ş&vÖ†¹}t©jQîàM‰-‚˜”«Pšrê¡¸ä#ô2=]HòÊZùé‰ÚugŞ.î©*ÊµíK·i?¹ğ‚sæ›S3÷Uoğbáp'ƒ‹ë±­l®˜u.fLúOòı`ÎŞº‡àåš³\gïh,emF­Ğ &>e+–xgŒ1íÏ?s=G½ŞÑ0ƒZiâ€'ûÒ©ôÀ;åË 5iSc
!mŒl4rˆb1OûıŞ`dÜ"JªØI.›šÄİÚ#üÚ€Œ_¡iÈT,ÌçŞ½±Rãëb	SÓ»
'½Q÷à×ñÂMqƒà›Â‚"±·î-ò%:3á"»¤L¼Şºëe+ë»§\Áœ½Ãİ»y‘Úğ8#ş=ËÉÙKqÕ<úW,î­Ë_¾›ÍcˆI¶,Ì&ÔFÍØzü¼ch+–\nq%ºéûNúŞCV§ü@_Pë=Â¾ÁF¢”3|ï»e@ÆÂB–/åÜwbá”îIñÂ^PİõVZw¹÷h1oÎn[”‡Ï#ìÌ€¿ÙÍ¤ƒ/¼¹‹zb.¨‘m‰ššz{Zì"|DµsI§¹£7ĞB‘»iHğÂ®4‘Qi<1)÷ñ|òUåğ.cËI	êNÑeåá`"X½nCãQT±±`@W‡F>nDƒ…íš13AÃDÓ•OV¶o1Ú )s;RpfÛ[…†syÄáèÅŞáixmÏ‹{Âîãš"ÿÕqÛ1+²û¶““ÒËP¿ÔÄÂ=ş/ë½ÖÄ?Q(ï³]¬t²r Øœo	h)"!R¥XŞ8Ï÷L=‹Â¤y%Vù‚^­±˜!jË{}±äĞA@iükOpg/Ï¤7-ûi^íî¾Ö^ìw´XÊ’v.CÊß»y—íßCùxÃKÓ‰¨Q¦ñÇ×š¸[«á[¾@­¶ïákÒF¢çø¶Ò„­w[ããÎÉé¸;ê'	©Na{!;ùî’”ƒn¿´¦AŸÃ…x¼ß¾õúü<¤€€txSÛÕû€ÎÒ÷¢Î¨ã×ç®· ün©i\ëìŠ…t¡ñmÙEí™8ÂBh!°
v)‚ y¡EÄ×ÏÂ…SGC“Ò–©“°Ùéæ"†úåÂù(KgK|vøebù‘{ H‡ÆlÎF„ıMfïÁ¸·áõKHEÅY@êº'](e§ñ„ß7•`”…eM¢Ï°è@‰’)mßc¡8±—¢tÏ±Æywk¨w»duÅceêÏò§E0¹¶¨VÉ‘½Ì² , *÷jy˜USV‚,aØ{si&‘+3e×bß/:vjµë^¿sòD¿qñüFá¾·Î5saALJ>nıä‡u#7?wPªš´…æÂ€D1GÚ›ÿ‚°
= S:¡ÄC0Ó=ãÿ%KG’ñ¦
”<9H«"•¬ı:ùù­¿æ$M%6±öàë'œ X
ù)ÙØ Urd~ø‡'J` ùÿS	H6w.­]ç©/d°ÙªK `Zr¾''®xK¿BäãQ&¼àû§hRrB/úÂY	ceÒ‘÷*Õ˜µŸ üÆÿá€3ãÎ"JRòÇB“ĞŠ}—–î_0ïK9$uÆ±ñ	öçBãU˜a†`Âgà‹j‰H]"Ä6VòÒ¾8?°zÃ_‡†|† Bpm-0oK;¼Â°Dä‡‘ãÄlæ!\š»ÂihlÆ‰tRq@ğ,uÜB9ÉîÇ(F#Á¯ìƒïŸ:‰æI¾jlK«"«÷ş;wŠ»êDÁ¢K.N~tõ#ª®”1Å¿Šg(„Ÿ©ğ>”îàñˆºæÊq­ĞÀ™R‹'¿3t&oñ]åµYwZÇÆ:è!XËœJªåÑÏÚ8œ¨%¬Q%ŸCnG»$œœÖH¬w<jr|•0É¼‰Bî^ÊZdÙY¥²š”bTÁÕ‚~]^‰ÿµ„95ŒÏVş©Êg³ †	·ş¦×Yô¿í}[sG²æyeÿŠRc’Z @êbR!™cŞ -Ïˆ
Dh’mhœî)ZÖş—}:±û2û0ûhÿ±ÍÌºtUw5 Ò´Æç"B"P÷KVUVVæ—§òß¡á«~’"Á6Ë+‰Y¥nO¿Êø§$SB”lóëÿ&@OhWsáéÏÖêÅŒˆRÉWÔË7P2áà^¶¤_ÿ7»ô~
<z'CN	Á±–ËŞÉrAJŞ èC€Ç¦ª/şk¤µJ=¢IK.)à ³« ¹`0ÊnªÔ\q…b+ĞcXtƒP&Ôù¤^Øc- W1pĞ9Z(ÿyH¦±R9†§°g ÆL"x{Ec;»¬Dû^şö {´Iµğn[1˜öfÅğ'.<ÂÉ€¹pk¹ÁÁLµ[Ø'[ÎtTZ³²ÚºQ©LÇh|cŒÊœ´F×ÍU¡"©X%4·Ôãœ%ÕåÚÉ;¬úä}m°œK4/'6ÄšSiÎ¿Â×Í¡´úŠ«AÀ¡Îe3
ªòP¡Qº:ÆœÊ)U“u4¢¢PWFğ¢FúÚS‹ÈB7#™q½º^­‹spíDkMú²ÅR6’ó‘z2‹”V•è,ŸÈàÓÂ´æá¦‹#¹÷³I¿—Œ&r\H×O„½N‹şhÀ¿cü;D±ğà$‰¿/ã~XMgüû 8;KM'â;^/Á¸_açÆWıAƒË]è…Ÿş«zã˜¿÷óÿŒ|ñ¥8}¸&™ŸÕ(ş‘¡v¼ø†&mÚ×4*–Vœh_U’AÈ«|à%D}Ñ2à|2„s^$üªrˆ‘wÚ»ìÇ}÷e·/°òïË¢kÿ8á}ü1Ç"á°|ğ‡ÚWQéèƒ÷d# ‘¯(_ã_á¯7ĞW`Py(”Õ šß~$&„¾ÉÈi¢¾ˆâ'Cè	ì\Wëü6øú;LGâQ	ÿŠ0,ø.ë¼û“$œˆ?²Øk¯]ŒFDH)QŒ«û2ı&’&mÄ`Hñh'ÒÂáEzÒ¾Š,éÀ_ù§Á`HƒHfŒÆÂ3h<·ôR·éfW‰I³B)F]ú¼”¿"£Y
Øbt¦ÒbäBb`_–'ÕÏàŒÜşmÚq÷/Ö!ÈæÕU$(ë¼œËµ9Š'ònpbª#à]T:+ÔDTÂîÔnUß9]É*Õú	ÍÔø…»#â·Ö‹ò—nRÁÂ³0»P]sdV!Ÿ³*½}*$7:é5ƒ¥'t*£+8—‡ˆÌ €ŸøıxV×a‚dÑíâæRfJ8í=q}×Ãˆ°„\6n×AÌÖ®¥Š·Q\enhTªlclo=9•b%‘Œr‹]~O‚Ú°X%YÉ‹ákiSªB­•»ˆ<'>·ç7õ›Ì »Õ²Jšš=CRTSÈŒXãËÓy¡Œ[şdIÁ òä¶hz±à¢Q/œ$qÓîÑMo}pbÍ*¨,²éÜ¥¸ÈuDNñ¬¡TÄ¬ÿ«Ÿ*4IÁæOhN€Mˆ±Ãc ¢+Âw1X{w€øaoÍY×
ó¼˜¸,ÕçÎŸ±Á×*Y2äûxF *êG÷Â(87C6J§Éét<àÚfX¾§Fj1Á³·…Ó‹éW~Ñ -¤s~gEh“o€}Æ:Ùqh77ßR^^¤a:32p-røÏ«Ò[Nà(˜ÄO6ü¡YÌÍfË(,a.Ë`NeF]2·€íg†84l`)<AqbÚáÉà‚$¹g¹ÄÔ*vV1Kü`¨t4ÃêLî|İöÑÑÎş›nqJÇÉ™XßÆ.h+Œ=ñ“Ënœ7æqt-R‚ÊéAş8±ew–ò©Vèœ-g#ØÏ¹{7®ÔÊy¨˜Zíï¿¥aœÏºe/‘÷· ½72;²[YŒò6G¦É‘aq$fÛİ¹QÖÚ~OÅ}_Ï5wymĞírr¡[æ¶BÎïd¥Ì2¨é¤ê3e»‚ıÆ™‚¶Ì«Y¶¶g~§ÿó€cXˆ¥_Wu•”›ŠİÎRÌb"vçb‹ˆÑÚĞÀÌ$C¯sóâ¥]P5çíåé'U´3Ì£•²Hp»XäRnUÇp°hÄ/İ¾³+¿µsJ7Ûş)R~Ö%6Ì"Æ¹mvÌ
t"qaŠoö¨kEÌ%GÃïÛÁ%y~À
ğ3„7 § ‡#îe9’Ó­'B«l—°¡iNeÅU¬¡QÂjc¬•c r|³U	Wëg÷ùŞµ0^?&/¹ºC´öş÷Í(xK%ÓfOæÙ$‘¨®TbCë³Ë„T‘»ÛŞiuşš,®Ír‹Õ”È«Õp 7—µz	¥üpu9A^Œ\ EÅ,{{` HN¸H¸$èYLÃÃ|¾tü–Ï´q]Zæ?˜ì[z‹¡DƒçX’ğ¸ŸTBºf¢xB"/è®ÊßK¶±Á*éÒÉ_[[²"*‰ï;óJ#m/¾!>¨èÈØ§/eYÓúòç÷Ÿ—­:C«PcÆ*ÓU‹3âf:F@„W\—Ó••ÚúşøÒ`Û—ŸƒÇÒFÍ­W×\¸ôÃl2M÷øèuå™ûÍêås¾ù¥çíñe…cTÁ? ğ“˜bàü}¾ËkKñê¸Æø‰[»G~`njB9MŠõ¯ğ…+Ê"D¾±7òUYE{VšùyÍÒFŠz^}Ñ5İ²c$¶F«Š—Ÿò‚¹èyåâÅt‹M¢É·µ4åsëf-TlâÉŠpÕòŠ´,ìâs]ç„v>ã¶OPº«ø›ÎÚìLìàIyæå{?Zu—V•³TªÏ.ÀPSpeÍ¯Q˜¯ ã’V‡ËTëÅÔ„´€›¶À‚ëba¥ÇÜv™STˆ±Î§t¹\Hô'ØNz]<á´¾¬ÁqfĞ8åKq\+^CŸ4â@vÏ‚‰7(1*IØIÓlJ—Ì_ò{‚YlŠ]8ùãù­à¢¿yÈ‰H¯‘oüF~ıwyde«V—³_Òÿ_}½ñ$ëÿ{£^ß¸Ç»Ç›ƒÿv™â¿­Uë&ş›ıÍpó5æ0IÛíÛánÀÆÌÿ(œsÁ¥!ò`µ‘«+¸ó}îÂK¹÷àËå²´‚D5_ãÍ)½Ù=xÙÚeß·:;hÔŞåÕ¾
‡a„&ŸÒKõ÷íÎv»Y^>ñßÕ·Ö£eå2|¯Õiïğ¨5ˆ[OãºÇ/á ş¶µÑ*x¿ı¦³s$²ÔÓäHVUc‰ëeR²#aëoÇ»ª€4œ#ÍŠfBpëğ¨·{ğê».²NníÒãšƒÉ‡s<ğy-õ&(_Œ“ØŒê{ıŸ"ñ
¤ç³ª+gşŒ®³êÄÀ]2T°'_hƒ7àÎ;ô—q¯ÔÍåßÆ*psâ1H1¤ë»ì”ú"FÉÂSºĞ|$¼n“UcßôÉ|ûıGø=`#D'Æ„ „ÌÉÀQ§†ãäêÄÔo7 Ö ÷0îH[¹{à"8kê'.„~¬‰?pÙWÏ9tpx‡BMSx¹Bâ„‡g“GUEÙC#d°ØËuì6É7Ñv|¸+-1*‹å5¡’i4†Ã^X¯Ÿ…Óñ€…«3¢ŸN®8<äÎ±¤ ¸¹¼°ß^¶Œ™9dn¹‘¡7Ã çƒ»ÀÁìä'E i¥9!c9pM÷Ê«¸¼İj0¸’‡<µ—D_IˆKNÆéç%28à%/:JWù›F’ÜúÜkõÔm(m™c	ûl±Í•òJY
dªË8AeåÜp€ˆâj“hKÔB…Ò7A†¤¹²j#À¯¾Ê¢†VEeqÚS­%7îÊ…•¾{`±òV•–?Á×Zí¤VcŸWuü{‘E Ä‘W›%îÎf©Ä™FñÊ‡=,è;¯òS«ò·µÊ×[ïWMx-È…iaÎıÌN`NGÀg3Ûª´²uÅí#øAÙNrÂE¹kMƒ0Ù$5.R½éîîµ·{­N§õW,UÌe£‰J''»9èOàP²|íäL•tÒ:šå\pèĞ§Âæpy.L›L(:	ûèƒEŞ5©¤DŞ¤…Uò'@c¡RòÎÏé”66åô;ïFZ’Ş 9sZêô}£”YXÔR$ÜËĞ·€7€ŒJuJ˜”¾²°¥è¯tâÅ¸éŸ^£ù»Oî4¡TZ”½o9hï”q­§³'l¡°®f¹¾¥~«+*å§®ûfy]…ŠÁ˜Še@Ö0ì’I-·-¦"E$Ù2–@À—À–‘2ä;'
‘fHO"÷zãõ}dÒÕFÀ½£1U¼c ßI?I­Ï3q½£sêõ½ìpœ í—øMsƒ¨øÆ1&àÒ%&ÕIeCV<ÎMCÇÕÈmN?¯€ou¦¸–Çè*'‚^yùË û§è9:uÅ¶‚÷Ê+EL‡N³2år™êô0´ºXìÒù“ñ­ºoË6 Jü%É‚Ô2ÎwTHZé¢.ÅPµ÷ñšiôCœ‘Ì¦3J˜uõfd™¾Ñş¶™QJNL…1ôsgNòB7£5¹ÕfYQ™ÈÆ‘OÍúõ]€ÖÆÛÁéí7‚»ôF7MË˜äRüÊ—Zt3‹[m¬âc¬N&r€pÚ]ôÎz£`•¸%Ô@Ç¹çzÁhâÃ‰‚h›¡”4'ŞÎ¦‰õMüaÈ!<5€3ánEÜ¬®èŠHÆşò·MÇdõ‹îÎ9úg\Â”ŸûñÉ¸×-XßÕjIèÅW.üŸîL´„$$'trÇÉÀÇ:M—-¸ƒŸû‰¶:ê9ïxDr˜
ÎsëÂšgı¿ğ÷+H*uÜû¬R‰óñ|__C Œee•*tŠüWÙ’ºµíœ ûÔ—û	¡Örüi ÌÓõv]3„Îˆ¸–{+mçßkt71r?èH­q‚Z11"³ÃíÜC×	Œó$
û~‡ñ#F[?Ğ("»ÅŞ¹?"ò Êúõá=Pµ]FN¦w©—Óø:³O­å&"M:c:¶=t¼	Ò{¶³Äm1àİÚ{?Šé*|u¤s†0IÀ˜SØÀtÎ5Ug%üïS”Ü…æ° ŒRúÓ	J{¦Ôd±GP³OÛ[/HÈ©B¹ÎÍ––°Uõ-?¡ucOú®Õçgâõád®;
GÌƒE»¢#‰ªÁ˜â\©\qBtxU™½)¶(Aû°šMÜƒ¥*gÁÇÊ(@OçJ±«`ÒêáÄ‡AŠüXMTœ]8Ú¤bÛËŸ”˜§ÀY‚À
.nw‘ş––å‡8c¢±<‹Ø^¿á›ëš¾¢çæÖ~bÏyKVvÿnjY…¤?aVBôùŞmÏ]ûÿÓ÷¾ßñÿÓX{šyÿY\¿÷ÿ~ïÿını¿ó~Aå:úy%}½®ÜEAÊáÏ@s–£©Ÿ|!Ïî¥Iä£‚2	hæì8Ÿ@²¹±ß:ÆÕ!2h~ÁÀï¡šPÓiœÚ­¦ùè]:ê[rp­×qŒKF®.óY"cçˆ3À†&Ôš˜äÈ²ÆVV%:“P1™‹š„†FRm9èÂ_Öi<r+²'@å²MË1_´>èIxtéÃR~Å°»sÆî@øuäzÆğ!¢‰Y–·´ªœ½­^µßb‘›+%–+Ä‚"&œò Óò¯ãí¿4tø¿y€ÌÆ‹——°rH¥ªt9Cå™!­‡6Ÿ¸æëñ÷¹†+tE¾º…4·ì.•–,‹c“Ùd™ôf¯ºµ4·^L3»R‘"/^¸Ànâ%Ó˜3Ód=œnl7o]UY"õÃÿGÇ]z„S¢c’·°4C¿FíôŞïğ/b¤¤zK^*gXš(w|U<%d‰÷D/y?ùc¼åDï×ÿøõÿÂ*ÃÓ%!(2¦fuüŞcæ¤Òò¤Õ\aå|Õfàøë«lUßíÅ»	÷¹õgÉî#‰#§şöEB ÌÑ*Z5£*|9Ğ'ãHŸªÚBr¥+0’5M™%dÀmò·¼-ŞdaÒ­XŠ¸–‰âP=Êf€däk,%Æ9~uá÷?´IõÁÑDóLoôı
÷»ø"¼bqğÖîQ»³ß:Úù¾­|£©‡ÿ¦êe–ƒØ³(¼iŠÔY§kÍÂ*ú×º¸†ˆ_Ø9TE›N°d³°Ô­)îXÚJ^¾ğdR<NH\r4ó·^]«®™ƒÁæŒÆ~»½İ;>Ä®§S³:>²mÿ4ğ ïkµƒ‰?şËöwLt–ñŞ‹ĞgúÌh5“»Ï*ğ:tæn¦±ËöùÌJ·¤Øğ­ÁQ~¾©¹o–Í}&5œbŞBğˆMc:ğyŠzıòÜLN	ÔîfÂ7Ë2`÷¨+Çˆ[¡sfSú¤Ó“LÖP™†ã©ÇUÔ¸I?q
y¹ÓÚï½@@½.ª•º…r¿Œªµµ‚ê yÉÊ)ì©Øè2×V›«É<¤%S·esS)‹šy+ÉG*úÈŸAlay”.>úİ OÏ,ºSÿ´: ÕÀë=şµ7À8|¦….Ò²z¥ëé8à§Â	›„éÈ8„>«pnP§.š@Óco ûdìl@.µ~ı/”„“¡[Üv4ÊÕ—ØÊtˆpn‰OÍSBËï“8‹—+(Aà-U*“itî«µûuå!œzl~Âzı!b·‰ıä/ö3F2ÿ3o:L‚¡xæÅÛ<ä„ğ¤ç%=œ%|‚ççö®¾Eşª’ˆ’JU
ÎoS)l7æª4‚—Şáí*€8MQælŸPñ¹
P·‡Ts\¨Ô
:Š¼
HnAôdğÑ%¹=Rëà°l–L~2î&ád‚{ P ão&B÷*í
¤9|GüKëû7:sËi2U»(@ à‡7®ÇÃÜ£€šXV¥hú][[¯©÷(ù¶d©ş$vÄmß1Qgœbqg[ÉhÒ\®Áÿ¸¬ñâH'm7ˆ¦‹ÿnëíŞ†`z³·şó2CÜ›!v¨ò!S$Ï¹@]|›Y<šR£Ù‹0İŒ)^’0Ö1óse†.¤-Iæ"CˆA­¿¡ÉÎ…n‰[zùâÇXšJ^Ä]\W”€ªÎU†ÄÏï=dvÈ—XIV+[Z™Ö¾(Cû;D3‚_3üÚ#³<SfƒÌ2Ú…«gDSËÈDgO:±ÙØ,ÇFšZåİ—]y5#Àà7Üô9eÀ,îpK-pI,aĞ‡3n¢Ã‘ŸDaL}‡ü'0¡™gºuã‘ÜP®« ß‘¡úšb«9î¶{„sÌÕ@¥¡§†æÌUTL
ÓŒj[Ù,Çİ¦ÂJnl–¹û`¹?fŠ=›¥ñ­Q¾ÉÈªffÁ"vw^µ÷»í.Œ^§µ×~o•Ê0èûã˜öÃqØ#.ğ£ĞÄ_òG/^­¢r°ÔtÄZ÷Zû­7íNïÕŞ¶Vñ;XËmÂUı¾é4ÆıÍÅõå®J¶ t;3‹nšZáÎU¿—¹ælet¸‘ÀRqiY»åÔŒNĞ!†rzo¦ Şftl‰çLã?Ñe“(şQP|ÑåöÄŒ?ÔŒÿ•¼ğ¹ [B¶ïãşƒjehfv«‚û@‰`gq[é´wÛ­n»V%d|T¹`r'Ö¢Q£Õ^A±’CA9w¤ü`Œv
ñ”¨ÕÆÒ2 éÌî¦‰ˆ 
FUÉH³vœnvü\³DwÖ8Î,õN^´M+r}J€(²>7©œáÀ¿åÑj¿!–…T¦àB‚Q8@\(5À—)à¥‡Ã·½§¦ç'])\Qr‰bãåË‹¶LEĞÜ¥ª­3AäÓØğĞÙí ¯µÿ]8„qçÄg^0D†q"­gØ#–@5‚(ˆ&RÊÔ!‰gFås©'_ä])!½iñGÆ×Èp w by-İqi7ó }é@DsÅí{t¥ÿÑ´“˜ÅK–:œI§*W½C`ÍH–…£=jÌócƒ>gñ¬nnŒÏ"¶ £è…SSût'²}ny0½!LÏãbÔ§h2qF8…å—?©xMy'Ky‹“=?"‹ÙwŒG»xúô)«t.ÆH{›7Öe4/“4·Uñ*½]£nÒ*q½‹ã–}kœEÁ¹ùrŸyyÊ^Üo*şÑ–£V*A¶!\’,]'´ET=®…ÈF>¢Í¬´ºp­ÕÂjZÕ6š±$Ä8¡Ã†zæë‡Mì˜xoCUd(aì…¨ŞO‘¡åxhú[ÆŒÂe: ‰«|äéïÂ{­7;È“´{;ûÛíšk¬ÄPÛÃğJÊB|6„ë•¦Ê\C÷¾É¯ÿˆ‚m€É ©K@MC\ ?o‚j-Q8|ÅŞ'¹XpÔê=WuLª€÷ûxy&š‹©ÑÓÍìŸÌˆ58#Jc6¹Ç7;¯ mCúˆéÎáfZƒ•º¤éÊÎâKèv/<îo¦=8{Ã[/pö£h:IVÕŠ&ımçPğ¹Æà5}:ş)˜‰Õ`èƒ˜‰ÏŒ£-7Êıíï£èŒØB­¦ËwÓ·Ù"ïìLâ{,ªVAÍÕ\¼›Ob…‚H¹QëûA
œ;ã‰€ÒxıÍ'7aO¬Ò`jÎ±µ|ÍØ²?µgO© ³Ã$ÊdÖİy³³»—â:÷ÆÅ¶òQc€\˜b9Û;°|÷¡4ft^~¢®ìĞimgĞm±5E\Ûùb&G$¹#Ü™Åf+İBR'Óqh+|Æê_ä ,ÑMRPÍ+Êw™†›µx\"Ù‘Ä7€“Pi¸QãqµQ}ìÚ)‘z!«çax>ô«À}IàÔPq#şß5?‘z¢<ªX…9·–Ãßt‹3íæ†F²©a–R¼ëçæoC‘´Ña[ÒÇ)ı]{S6,eg´m
	r°ïúù³ı4@Î—Ò¥^ì¥k¸6ÿÌªˆ>âêÀÎ¦?­ß¼¤Âá»`MıÄÂÃ,9¯üpèã-áÊ’Gê&‡`'®èVAqâ	UÀ"ËÂ¡*.“Lå…¹dcÈMÑ
gª.¦X+zhç,á-jNßmO÷·z»×ï•fÓ¬ónÖ¾Ù=ş#ö5cŒëù`8H·wM$mï‰Æ÷ğ;9îô5nÁ Ö¢‘g|Ó>r³‘Ëƒ8Oş‚ydME¼<ŞÙÀ¸…ûaãŒk|‹zPÛuİë×»„âoÍ%OƒQ#=æUa¤eó{Ñ?éñÇXÔ‹fğ&zXƒÊSsFK°˜{;ûú€e‘¬mw0.Z4¸À¹Û»ÚlL5JfİXOı³4ŞéÙ]ø•^šÕ©Q¿.ºÅ6¬¼¼-o8î/p~šUm«JÅz©Ä!şñÛÒ0Î\fËŸ¬Ë†9¨°Zæâ64#CÊ
¨6_#¦ƒ]TO:<Ü^ë*Ó€¡¥j5°¹›‚¿B‰Ssæõ‡iâ¬6Şn#5¶R¹™ª¿gÁ’|ôg†¸ãO¼ ‚6Ã3å7X	òÍUí§®şKÛ&µµîr¸eÜ/8ìªTƒUª…©¶¡Pd­¡öˆp¸³ÜF‚€@êtùì8/ë`<¼&C¡è„ybrD¾4Î¡,µŒ\sğ,;§_‘z ­ªÏ™eÅ‹VÔ~–-$c@÷ÌlÃWö,üãv&æj¬=›n¦_Y¥SØÍ¹ù
<¼IW¸§5h1'!“®*ñÆ¨ü<"¢=„Ç…EÆCÇÊNˆ5¦+Uq¥@Ğ‹(Š„o„¸5@zx*òØŒ”ú±Å¸À¼¬²ø×Hx æ£=3Ê(=/†„*ÏÈ–ZòÍqPó„yéßiº`Pb‘
‚şş^e%B°!°|Qñ¥?”â-Hl„ÎdAÏ›.ÏB«ETå²ZvèhÃË«°I_Ü¹6Ëƒõ%¶Ÿƒ¥f´!%	fÕ”–SS²4¢¸Áº—#Y¯ÖuD7_ ë,õ¨aºí¡1Ç!E!2ïı#Æ€™ó†ÁO 1Yo)çÿÃ+T:ĞÊŞAûA:f÷r^A‹Í¨¸R„qI1Q:˜G¸åÙ¥ bù9Ğb'
÷O8 èGd$
–	sDX¨:WP­jzŒûÓ²¬Œò7NjÖaÆè¿R¦JùN5[Ÿ)"ƒ©,Nqÿ×ä{4‡ŒDí#/5…# ÷ü‘1Šca$XgŞO°	àåê@{Î64Ğß‘O²€Şzo­·–±<K»º`nV‚æ¤áœ°ÄPºY[62m¹ac6äıTÕ®U?†<ÃÌiÕÎÊVÄ¶Ñé¥Ä\U¦[jãf†åŸŠNÑ ó;_9õ›y ÚÆQé£O.D¹§â$2ãûY°;?«5â3WŒ+’˜iMeM¯–œËoM¨ëU	fÒNG?Jbw‹É5Q^)]>‚¦‡$-Mö$ÁÅU—–^"{M-©|Šx—U	„®ÌÎ6éŒù±‘úµ­í—Ix<ğ/"¸ ñqwÃs¡›j
\ıXt©!\Z„g3røx(ë¿"'}l#iºà[2}@q®«~c¶KK+6Bi%MH®™=¼Ğö|¡/îGÀù/Ï	"÷ağ‚O6V—ş¼`†)Ãv¦­˜İûK°’Yf«à´àÊsbwË]ªXr•¸ÖUıP²÷¬à@âM7ÙÛ¶»Ø¬çYûwiî.
¥tKI™,bMóëÌÄ(ÌîÖÀÔ¼LÕ’,GÍL§jwpâü§‡é>Pô@»¸ßPE¶$Nøš~N/…æÁºº+ÂÿıÔŞ_>v(,00Æn…I°¨ª„0¨ÍB¬¹óÕ%4+‘\v]0>í õÚ²xS%\µ‰· n¦¶Ğ:Ãô¦ò2öww^íõZ¯ ŒŞŞÁv®à%öh/fp<óËµ8Rspš…›n#òzÅ®a)i—7ùR;§ÆµYCÈJá©;1Ç
ôîÏ!‚Ê8LËj”XÊƒûˆ)¹}­…•òå6ò‚±Aá¦Ş†í4$}üC´ïàœ‘“=s'WÈ£¿\‰Dj#¶²»Rõ°ccJ‰ MºÈJ0DP†*Ê“;T˜G~‹¡Nö#Ë²gU¶¡¨¢wÎÆÜ`;Ñ9Bœ„‡BT:ã ËcNÁ©e= sÇÆ,Õ¼t‘†qòJxSÌ"¶3äÑï_ŒÿW%˜,LıßÅÿÓÓÇğÿğûFÖÿÓÚÓ§÷ø÷ø7Åÿ+ò÷Ô·¢øqrOŠŸ8NShÖªâÙ¦Ô÷»ººª^—^Èó {õ4ªàRVë¢Û§
¯­BH¥¢ìp\ö†å5Ê‹¾* G¾“oƒi{VV™’µô§Vì_2„w…Cä`ï°Ó>Üı+9mH”õa`ïíAg»û¾¾ÂïtåÀœ…)*ÖE`?W`|& )2Uàv:ÖâoÅó&ã
âÏ4‹i‚Sˆ.)#ñ)Ò£'0…Ÿ ­ŸY³É*Ù{M™Wëºä18¦±ò_¶±epïªTDvM¥€¤1p>«¼fECÊôğÅsTn”£Z»y-<¬gÆşO\ø°&£øã¿6êO7äğ_7îıÿİïÿwŒÿztá£SŞ”ÒÄ€µ$Æ‰q‰×`sã/ãò/ªÒ­qéĞ&®â+½íK¸M•çµ‡ö¿ÂëÀµ¼ğ¢›}agA'˜‰&Ô—`sÜ?8ÚyPûÛèäY‰†Çaœ]WÕQrœ&÷ˆVÔ^-%I ¹‰‚yº”ÿÏTä®:êÊ!äúš¢	·«*uZ;cÛ¬µ÷r§½Ôæ“åÈë0¯À’ÕÑ/Ìº1'éşN3+½ş°ı¦·İ:j¡G·©¹oŞÔ1ó€œ~é:V	‹KK$ù¶½û
Çİ'Â4sŸŸMÊ¶ŠfLš(¹'ÉIr^ù™	o{ãÀ²ƒ!¬ô òĞ2ü'R:«o—u©î“ä¡€Üûš’aÀ1!q±ú“êÚÛ=êæ"e#øãú;DZC©th‚r÷ºs D²¿İtÏÇˆ°+£>©h(ŠjDPñê©…Z0Åškz–İ—Wjò÷¾C(®33<‡é¸|6é/ë)lÈ‹”
8¬Ÿ–ÕXä¡ µÀÈ}G$9»ßÂºü88G¦,ª „^%_œ‡GZë|—ôüÇ~RíO½êôl” ëœ&ÕgÖëg¿F/nÓ@!qrè9j˜5ì.•ì¶Æ<°p]In—SÙX__úõnŸ#Eg©áÚ­ª˜ŒY[3ª?;Õsİ¬-RA~L˜FZ¹ŸEã>>{Ò{²‘kİ6³2.›U0åV“ª'Õzµî:{§™cÚÕ³ñÌU¤š·
hÍd"óşXHu7A‘Ô®ŞŞ\n<ÅdË¼'s0uVBè#ùhuVY´*eİ­YÆÌ±(òêz¼[³,07Ï„ßRAúÉ•eí[»³"»€™İlP?g›vÌî\e^ç¨¾t*Vƒ•H¶#ÛO£ˆÙ‘YŒ‚Yƒ³G3†R‡gH÷†ó ¹˜ÒÆğãh‚^†¼™ğ$•ç-î„ø––gœª:|æU§iÂZ˜éz;Ûm™j†K 4[Ç×^àñ!àC%2m@/Œ¼,<nºp>%j­Üö/‰O;ŒÂı~‚ö7%U,²®(Y'^ß×û ‡¦Äo4ZœïË^{ÿ¸·sÔŞ3ÒÛù¬š7ÁG?Òòˆµ¢ªÀÒ~HBØ¿ÄÔª-l£Z§İÇ¯¸Íe½ìhVíÆÈŸÓsl·Öü°ñ¢a½ª¬¥=5UM<nÙÑşSún°«Ş=c#Êká]WoŠpÑñã„E”TP#=[Åç
¤¬Â½ºúñ'×Ñşáè¸iÖÜ@Ì+A0rLvBªòÁtN»µK¥Š½_¯§ùŞP&LúÓ’{Š(KTœN9QÌ™1ê)tS~àCÍ‰˜V‰Ø@/JO8Ïd£›®t+á¦jfÎZí¤Zë}f%¾áƒ!¢ÒÏ$DÏ^ËÕezQì=bá)ü<ß§èÄ–c¸â%èàÌG¿¸&uì KÚ¨^«g‘ïO<È3¤A… šhj-ñÎãZ¶¹0ãY/–)·Ú?;7¸ç$Ï¸ Êa©W‹¼bwrŒB[ÕhèõŞ3L±j)IÍ$–ˆ“I%á*¡^}V¥œKc*© 'L­ìt»½VgO]tîc™¼jqÕtÔh /R½½:<–üªª(nJZe×_ĞU£³÷ík—u_¢º¬õhtùÔs™¼=vÚ¯w~hâ}vyÕ)iMÃôÖÆ-Ü6b¶Pû
ÚãÎàkV©ğÎ©&•	Ÿ$9õŞiÎaçLÎ&"ˆ‡ô°¨êpòP(à®+ü‰¼ÂÑˆmç7
ÒÙÀ%¬ikî]5YüLSñ€[5ø÷l/:÷¶ÂÕıúCµñ¬?T$ }ïİı`ãXê´ß´`ß·:;¸{tçm§g°.†â0*r¿nëiO¬ÔÈ_}Şñ;=ø.-ÁéÇz½2ğ/ß;=O>Àf¥~ÁÅc|<i}/ˆÂ†ükä<¬§±“8‘ß½äƒs~Ñ¯ÈšğÜ8N“õô…»NŠÜtGşxŠ0y,^r2y|Æ§8jôıè¢[pŒ‹é8ò"&¯œs÷§ìş‘cR¨;;YulNh)1–Ïş1™»Ê„ÃD×¯‰ô9Üdôr9&I4ğl+Ø_WVA™;*6éwïŞ;N¡2˜]eHÉ_lÎu2‘ví©£ ±·­¸Ù;6œ™"?k© N;ÙÖ<o>hø@d*Ş¿@¹>ğ¿#!Œóí{§Ae£úumùH"è
!•’ O\ fRé°{|ˆdÀ¾mC3;İ;‘‹²o×E~Všİœ×Ekšsf/ÁC[rgÈ’•ñÿÍ²uhTûuCSjNµûóR]Vv.ÛŠ°ç§‘7†û
ìûÁGØñ×‘ëËfúò¸91„Ëí«âXÍj¡iõ,&î²Ò"_ ™74İ|Û³b–Ÿ-g£vaç«×İƒŸBüÁ!wµİ¨n ŒpÕÜn²©µûİdÓ¡§Ö%4?åTSDªxg05~uì'@ë\ˆ îŠ_Únj¬ÑËüõFƒ'ğvu-¶èÎDfTx@÷Ğ/ÑF¥Ş£ü¸±ü/i*ÛóÖ4ÒÖ,ãî^ùW|€C!uğL(áré¬y>cñõ8ñ>nò'Síá$	á_6,}»zçÀcü>…) ‡Ïíöçwá$Å+H3£ƒn»)ŸÒf½i3?Ò==«¡}û@jÈ~üË?e-ù>ñfë*3…5æêèLÇ
›µZÅsŞ/Ÿ_¦~STßQÈ~œÆ‰Ò‘¦jÏ¤j+[!À5|OGìH'Ù,ïÒ†øNŞ1€[ßRš=ÒĞ~à`Ç5jÁò¹êQQ-ÒRÒ‘.b8
‹â*$ÕL¥ÃÍYİ€N¨t|<7Wæ·—Ñ2ì¢2L¥å"±øÌ" mmvÀ×Êff­dÛÂr+O[xvå-µ¿=èi©…R—ŠŞ?Ş{Ùîdkì¡n,Í\KĞƒ³b­ZR­ËÊğ­Qtl|2Nû²&X‡ª›wı—²—×
½É[Ì·ô»òÈé†OcÒ"™(!X ”J‚˜) M8 JˆØ(§Îhğ@ö/g;g˜
²yC´f½Ö³Ó"D½¬T_î¤%/{Çã\ı_ÃpãËêÿÖ×?ÍéÿÖ×ë÷ú_÷ú_sô¿n­ ¦‘úítÀ¸D,ğŒ¬Î¿IÅ˜´Š¾ˆ¾/À/¯p‹>Ş¥çh¼­ÍŠüT÷§ì®ğğ³ãp¾U‚ÇÛ²º¤î"»>WbÔ¡ÆY$áÊ}ÑV¡?6T÷+ş uÍKX.ş:¥qÕ?è¦àâ‰ãè`« .ñúS0išè­*!'ì(gC$l/räı"¼*DE—›•Ö˜
%ùàÒR©N!™7'HÚĞÃ9¨6c¥u
5Zi7²Àö˜Â„š	ü~¢~+Í}JğbÊIq®wä³¸R×b…:\ˆzu¨uöü]¶Ë-ëY-Ñ)È¢Z­23­°„f•èÒŒÑ@ZI#²Á1­ÈŞíuô”Cé&s— :›+etihÂbD
¬dÑà6‰ÒrD;Ã«ô“,ã…ã±3l”k1µè}‘™¡tv¬ƒ|:Ü–Œ‰;*¾Ü;1êfJœüY ¬(ÄÈÅ­s‹ñˆt`% Á›®­ƒ|›Ë‹S6‹
Ù,K 
­ıd`í6uğYÔçÚdÒÿøD Ñ˜˜K½œ‡R­j˜ä&ª½)Ï7,]‡cV‰Ïòf·ç3Ì,ƒ•HçB*Ilô.Â‘†ŸLØïŒYZ‘ÑŸ0 ô¦èœ0lÙa/¡fğvğtvâtèË‘°»ô’è~öŒ\à‹[ 
q{sÇá…»q€f˜W|eJÅ¥mí¤ˆÂÁÂé‘^huŠ~M-O…èáÔX·x?ù‰LÒ™\†`&~ô‚ÙÕòÔüGa˜¨lÓk á
˜	”£!r‘ÑGôtùVºÇø-ÊÉÚòj÷¯€©ıM«˜%üJYWÊz¨4´A9ØE„vOWmî03–$T‚³b'ézæ/E>‘?œÖºƒğ~ı?28à#²¼9¾Õ™ÄÙğ«9¤LåKtˆmÃÉ ¤Î·áŒ}ñUCA%aQx{Lï¢bëN/ÊêV‰‰âZşÀe,‚Œ1:·á¬BüYUçÌ3à–®ãÕ|Ú`òh	&Bå9(ëÂ=‹m. uÓcR¬È¼§KÖï}dû‡ZÕ{‹}`ï1cÄ˜g«r	¬ÌßËÂáÿ %6â”Gáxè#@*•v(e=ïØ3¶RşlÙü¦ÂhÃ’H¹³»hôPµıÖdé™-a3r  [ªÇØDizénqdNÃDÃ2Üsë”4?|"İØ.-qÃ½b^Œ•Ã-ŒKîæ†féüØ¬,ğr‡jE;§€¾’tÔ.Õö¢a€–ü.Ó;×Šx1Š«\/ª€´}ÌáÔ›ßÇÑVÈIí'p>üü³üõ4m `\O¹l+ãNw]$â‚=ƒë)‹¸ƒ©8Ÿá¼—•¬¼ÁÊO²>£xwÌÄØæH(“nß›øq7‰Pïª¤éE$<›I0ãM8ñÆä{AÈBtá„û‘#×¹¿sWLùc[ˆ T*né¢ 0P~iÚÚˆ[[À,¸JÚL5)øb‰ìKLæÔ_$0³÷lk>î™˜íb»eÉ;jË47×ÛI¬ğuû©I”i”l=U,œ­§Yà³¶h€4Ù½Ôº™î¦ÖíTìÙõ-&³·Hn¹¸,hXt²™TŒ`3ï$LéŒgŒ•9ùAd/l±*ùr³ˆCÚ‹+ ÷wí…êaºı˜İ˜ò2ğg yÒÌ¾È™.qÁˆÏ	`ÛKKtÅÂÛ\~Q¡e•˜š6k‰D~‚&D«Êß ²ÿ)‚ısÄbºô†°QÂ¦)¼Ú½|å¤ü2äCIå[øJm½ª3£ ©J‰bî*Ëï±øMû$døĞÜˆ—¿3†FÃ"Á"h¼b®,ÎnKè(×½¾óÇÀ„ı¸ö»Ö1ÿ?™÷ŸzıñÆ¿±Ç÷ï?_jşá8¯ı‘æÿiãéıüáù×ŸÓ¿äü¯¯­×³ï¿ëk÷ø_fşO\|äœ ;^VŒ™êÑ·&$Ä3æâ³*kMÏYı™ËU nl.qŠ2ÕˆnŒç¾ëT»ß²ıÖ^Û1U5NTÒ$Ì(Q–îÎşÁaw§ë˜­9³¿;9{É%E'g÷ô]øÙÅß˜ƒ9à["k^.¥ÉdAÜ€ã7À—eUw+Õª“Ê	gó!œ54ÂÓû•¬]GŒpÒî¡®ÀØm·»¯:;ÔXÇ@r@å&|Œ¹›ÈGÃàƒÏZ‡Gp.¹j„¤¬vË#õèÍ…hX†ÔşÂ´©¬œê¬(	‚ÔJÙ#kö–»ËÆ†Šñu2ãÅ?Ï„"Ô%£ïd†’±%•Z¤«ÁÑäXÇ™A®Ù:]z^1¸Œª"e*’“c°Ì˜2L[ §çáóy"'rı%§U§®o³”ê†®TGÆÅñrØL
#ÿşçŸß‰ï™lRìWˆƒÆöÈ®‘¸Î–Ç»
…
U-êšPĞ²-V‹†Ve-AÖ|É±ã˜S4B„a<má(xãkFvÛBŞ›Y¢+M^:è‡S¸"8¬`åWyë¡Ş¨`ÓºÖ%‚™ÑkJ³µ"u»ÎW=Ñ|„½)jGi3QàQ÷0)‰vÚ²<b1‚Ë]3(“…ZÄbt×/ZmÇGßtœ,4ËÊ€za¯şç‹0‹àMËWçßî?ÿ=ğ?‰ÿ“NU€Ğü¸:|Aü·µµşÛÆúzãÿû"ú&Y‡ÓCØØ!¥7bìY0FxÁœ†Ó„ı+væ{	éÃá)|
Ì!Ù‹Tç’ó€ØöûşèÔ1ÒËC+€ç“ÎÒó8‰Âñù‹ıöÛîæóšøáÓ!ü¿ô|¼§è>œ¢ˆ©ó¼2lAà MG5Ğ#…r¬ GHæ„ìâõˆ|ìLû(Iõ¨gJÏŒm²çşè…´{øtR/× Æh–ö€\5šÔÅSt>Á»s¬§=¥£œŸîÚ±A¬š†àHJPqUÏ*€³êkÈà=éÊ ¶‚«y“ø†ƒ‰?şËöwõúê‘ùyFXÿëÚÛ@Hq¤g,ØÇÍ³Iô•¨paô’‰×ÁGCù0Mn1í™¨¯|„Gë´DÒW§f/9Ïk@<œº@]:úª÷'	Ñ{VDe³z©‘ÒqgW¥\upıAF­şõ-¨ıˆ@)Õµ"‚Ü0ÉàP%:k<³%âÊY¤ûÍ8Ô‘ê¯d-H„8÷pÄÈŸœØô<]b(4¶„R#™§5BGuL±¥’6h‰IAQt²¸áe0hWÔƒ‰Õ‘w.NFÀÈE>ŒTV °ôÙñÎÏh]›Ñ[O(³B­XÕÛÇgäµ2„š()–•»|pfd töŠôØêì]>­‰ù¾Y>¨Í’O'¼†Á/U¯vwØ:#:÷ãìş†ãn¼nğñd@×ÉÔ,§£ÌrŠ¾9IàhÓ8ëm›gJİáÏÔŒM¹+=/º™÷çÖ`†ö¼kØN5JX˜ùë"µ1dhq·&¿l0ØßuLÃšW˜Ü\Ä´!5ŸàcŒÅŞb¼`ÿ=«SL€¶?2v qî9ºt"ƒİhdÔBƒsÏ'ÿçÿaÉŞ5×¿8ÿ¿şôi†ÿo4ÜË¿ÈçáÃ¯Æ§ñdKÿ_gAWê«<i‚_–Ï“ÿß¸WH‘ğ"Y¦ş‡çáC#Ã7ÜŠ…ñâóIä«âcŠgfˆ™e5*„Ÿ JÁóüŠ2hìE‘$o“û4—»©}ú}#ÄpiÔÌÚn¥9•ÈUk-v=2'ı|ot¡‚4I ½”¯æ»•™.MÖmÎ˜øÜ¥ü;# '®æ·ˆÀe„0v>ÅÏc†Äümf”‘,^Cvòõ4Âö™e(e«êÂºÈ:§²ù¢,¤)í¼$öE%Ùh˜§™!ÆgÂ:HFŠòeùlµ€òñşMw+fĞ»&EóZÇ´!$a}%Ò(HÙQ³)êµÀ–ï³6Ò[? 0sYºH~şøÉGÙE‘1‚;~°“\—QÑÈÎBãÉ¢¨'³sö_¾hØ©ß8ø ßü¡C¼tˆ§yo¼FÜVé½*-²bÒ³û‹àÿCHDtÇùŒ+(ä½ÃëÀş¿±ö4«ÿñ¸±şøÿÿ2òÿƒ„VM=œÊÿ>õ#rT³’”|œF/Ÿ$öMJ-¾w#ßçëñ,Ã+)DPZ JƒmŠÂÂ!K®'~Óİq¥â á/HPÈ]¶Bœ†²LX…D1J¶aoxî±‹È?³cóÅ.×:-õZºåT”4¤v:OáîeFµN»µ½×²w_Èm©]îyÍ{AÊıáÙYĞ ˆëTİŞÊ¿ÊË»i…Ù:¹©2ª‘ñhd¸H‰‹ŒjLÈù_z1ôŸoÛZ1²>\ÚÿŒµtÀÑj”+	Ps8ŠP ‹á*Ï*ğ¿2ö0ŠDÑâ!-vÉ`sÑ²Ñµ,ñ—²_şn{L¢'Ñ^dÑ#YtÄGî{<A"¯5A"#»8Nâktl­Ÿ¨tHĞ¸³àQ-A°‰¹w’åØ8Òãpˆf-ñ¦DL\z¼	hÅ‚Ç:û\«ŒğŞDã›µ¶É¨”P“^I”'şt…ŒŸß€0ºJ¢§h£®V&íUå“à‚£Z0"E©	zZÈ‰U‹RóŠó•İëÜî?÷ŸûÏıçşsÿ¹ÿÜî?÷ŸûÏ²ÏÿhÙ[ h 