#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4130555228"
MD5="b3509c6c92226f01886870938fe7d3c9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22532"
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
	echo Date of packaging: Thu Jul 29 19:02:18 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿWÃ] ¼}•À1Dd]‡Á›PætİD÷ºkËg©r)z#‰ÕnÇÏÙ¶Í	¬ÛõÕ*ƒ‰¤™¹ğZ“¦t$np§G<Ok» ğ½i«Äëç‰ë³|ª//ÍŠ]02JØŸİ÷­8ÚÜ.”¯jâ "R4] ;DqwªÆ£Û%r@Üä¾ó@)ŠsÁÇ,’¸ä‚Ğ…|]VrùÄ<µ‹q@æ(ßÚànù¨˜ÍÂQYI¾^	6ÅŠÒÄ¯şE76iÍÃ¡ Ë¾¢æ¿ˆ²S1Äl<÷{Íóy‡½Roù/z9şnŒR-‹XóÓjúe%®,ôëóÔËurõ(¯Y‡|dD‹»€í¿´èİ›#>şïm!óİlo!ZÓ4‹19Î•ZYNDAdï‡óvÅmg ³D˜äC;`;÷[¹½VÉ9IÚ!±¥Æ±šß‹$Ñ\´ø½(Ôi}›¾ôwC‘*{JMw(ëÆ¿	>õÉ«,>
*}Aó9rn¡÷œÅ›\rùQ½êäœ;o£í‚ì®Dà}2ğ/¼ÏCmè»\-Š‰ü$GMåR×å·Xf~ÍµJÛäÔ†Ù¦k?oØ˜³¡ÿz‘…|ƒ½òÁÑ;4T™Õqè6A&¹*@ñ˜OŒ3€—y"¯ó+~Æ¸pQÓöä™èbv*ı5vçÏ˜èOı³L|èìõ°ÓæÉ^»Fqôá`ÁÒ /z-h]ØH´Ù¢—ú•J±¤(˜ëáín2|¡ª¶€ ¤àõ§õ´ÇBÌvOÌdJÌ¹aÈèPà\Ö/±å Âé—Ş¸-QŒ$[c˜RÆq¥J»×<}"h}À	§»8‚àOà_Ğ(”œ¬Gæ÷2?;áêƒ)‹™€ğ2[o¾ÁÿŸoò…´£ÈüãÇhòŞÛKD<×”?»ÌA ~¦õ“ğ¾
P ÅešÒ±ñd(ôâ@+'®.'!§™‰>E¤ª>äLÅER0´F²c¢eQ’ôË$•V¿¬èDÑÎÜÂŠz¶‘
8f
‚¥òrNw”!EÃ ˜šæ¿	C•33*+Í-¶;ÅQs–Í:`Ÿƒ”`š©H _áaû0QÌĞG-Z¬,Ufş¨f÷ßs %,e<…š×VƒhMQ<okäf«^ÖÊ‰ 	lœ³ª°V^µk€ú·zn1ˆaåÙ±!”™}n¯1ßÌºùè #®b™ÙÂê"w€Ôv¹uû¢Ì¸’=¶šòôî†Í€–Ğµ¸‘+¡1%8E¨ñp2é¤Rw¼ÜË•ğ‚âF÷ş¼«6¿N`ø¡kdÙ!$’¦q±¤‰yAG±ÇŸ\vÑ0ú•éÍ÷à¦_&™f×jôŞç?`¡èWhÇ€ú»Å|Í+CØdÔ%¶Õa¢ïù$_ˆQ˜m¯x:"ø‹ò£™p¸p	è‚ZqêîA¶Ã_Ğ¢	ĞV{®±Yù¶{…fŠ¶hö‚2Y¯VU@•QbmŒçÁ ïyŠo DŒÍÃeP	i«å!½D_¶ØóY¨KÈ'^1ìê.éİÎ¨šlz~{½hàÛ,
öÑÛUµ•‚Ş!@rN£4¦¾ÎØ
m°î=ş¾”(2ÃÙ‹R·(¶•yÇ.Å&²f-ü„]ç°
Âš§RŸÓÁz)ª¨=jNæTå~m,62|D#&"í‡@__	£Ìk}fû4÷<Lú0ôèÖÏğÖ"^ºèÍ`ûææª¡$É\Š KC##É0­ìÈú8käı×:,ø¶ìú´?W#Ú%S,Zşÿ¯…€\`y‰Ó[¡çæ;É
=m¦âIä±'æt•ózXÓ¬Ò‡Ì«<}pGjÚÉÇ:sÍ™KUäíUÊÆ1RoJ#™ÿÒ<kğÏdí…ÑwZç„b—L×§J#YpÒfß"Ë·Ò„É§]°íü†ÿ-v€şÎËe	¥‹Yjã~$ã\³AÉöU.;Ë@@èí'Êş…Š6é®¸Õkä×#ß¼9S£’÷éEÓÄWU7÷x¾Ÿ|ÑOŸ.hˆIîNéãùuñáœ\UÅ:O`ÄÁ‹øfİë~°˜d¨¾ş5œÂçÛb’"ä	ªTtZ^w‹,À³½-QJ>½ª¥OÙêß´9‰údÁÏj;¨×ÆºR$5ŞÂ··£8ÜóûïÕFïz‚S«¹±…í¦<×tg¹ˆiÚW${ıD€÷.yĞ4hÈ+gÁŒ[šx]¶˜°?l]ò¶{?4ï’iñ[?û`ğ§SÃ	ÿæ¼8ë‚ûÄò,ñLSZæ­*e·`p|×k`ÏÏşøCôËêË|ÙËBmñQœ/É’ÁîfYyˆ¡‡4h‘C¹.Qê›PUl}´6*^K±J¾îÑ‰¢Ş-»3WÖÜ•{°@ÂÆ›*Ñ®ÙJ(m·¡wÊ{
Aı{Í~ÛQ4õQ;ÚfßÂ’õ<õàM¦•Çéö.À‹äB“­§½~°¼m€™GÀÃ[ÆuÛ,œphÏS'övùäÓA/P{p‚ê?§f©5§–ÖÕ?¸÷I;7í-³EN•µ:6­ã¤™2·‡GúåÅ3¤w-[‡Òp×ÑÃèÂ’²ªÅØLıV_„ÍhúAP2s0Ã	¦ïaƒî6æ°­¦½qÆy±D“Æ¾}€ŸÕ:»³Dî|ŒP¬·ÀÆÿókîñ…é}Ø‚ejÁç€å#òv¬Œ™fy˜ZìEïMdÀ4±]›·„ù¸ÿD£Kí™†ê{Èö±}F‰¼,<î©Æ{¢ê²HNğª4pıyc–³_±r©jıCs	ş7·ÁŠ=®ûÇ£¿u V¶ãx¡•^_Ïc
mSg;¯²Xğï¼»E»Y	†W/O¬„36tÒ¤A/»áˆ‡Šª7z!mŒ¾Pq×‹·ª÷ïÀÓ1mxDÎk˜m:§Jm:QCÈëÜÕç©z§eézCÜ_şÄĞWÑrĞôß÷¿ÓıƒÓí)8şÄŸYo;öF/DŒÜòp
:ù•IË±Ánº,7ËÏ5Û€J&±à“/RDÙôn8tË–ºáŸè¬Æó:øn}ò&óóKlÉ‰'-¦¢!hmwt&”a_#t¿OA“@FÊø¿š>Æ}¤÷<1-peû5ï¡q«†Ò³*ª}n§Á{äi½£­öHëÓÒ[¶ıxyo¹–ï"=¼
ä&ÿ~3¦Ó©ƒ_%°äŞQ÷—§PóÖ‹‰ğRQ˜w+î÷n½A/ê7*ÄÆnêoËàÀštLVöš¡x •·î~œiŒS§B	UÆ~UjDDó¸nùŠ O¥àT¹>úQ|S¤ï¯{ |\‹¬røMEµCAï GQİcJØ8zæÓ…ÙĞqX5ëzôlg§¨ ~Ó}÷\µÂ,€¥(ÀSü*øúÀ_.†Ğœ"™e¸°qb²•ê} ´+}¨?²GëPö†Ù°&ãå}eŒâ6À?´ÉOÒ5?ö¬~ÓxÏÖ?ÃRe ±‘·
—®™¸÷ÛùÔüiƒ-âÌ°Ç‡kâ|`Ï¤\òJÍ’d€¿4†ş9¬á:P­½xb¾-BÅN;Hì"×³¾à÷pÿ/ ¦f¥p¶'5*ğh'ĞÃfÊí¾ø‹ôö4ozÕá§+„3pµq]İË/í|«¢åÂKË:'H¹~Bh»YİÈgùãß±¾ûN¼r|Ğ—ñï‘æO_Îï›õÅ¨¼]@Zû½æï¾0´=6²ÑŠYhÿÆ¹Ó¾56Ü*(vº¡Gæñª]‚š+tù”6OUüZŒâ6¥Ù‹Ğ!mu"ÜèŒ6RÊÃ¨*ŒÀ0Z3Úv¹%éÆû'áP‚*ËC—”ÿVÊ†üaÓ‡õü½ÅX“¿d8	ngÆ÷”É¤ïN˜ºšÄ2ÎpÈÌ÷A——ÄKç{ˆ)n<–fR2æ¸BëEI™çc™ïC7ØHí]¤PìgaÍvrÑ.yh`CœSŞd±ãY§®Œ´C6±ÇGDËÆ_«µ£û[+¦¢·ÌØ{VÓªoƒ4c5õĞeQ$à·ˆ—¾‰w(
ï/Nˆä;Kı9?‡kİù3ÈuÒ·æN¼ÅîFÑ£¯Æöõî ‘Z.7?CšÿŸ:IˆO& loC´Ou
¦¤\~ÆÒ¦~–vnå6‰;Ù¢ÛõŒõ t‚ÌZ’m<fÒZ¢#oÌÃ˜V¥óÛëÛm¯@l~N”ÄSêmmÓ2©LÕ‰!õe¼Øg¨‡ë¸äO‰¢P„Ï4b;V¤¶µnÿ¾Aà%ÇO1òF¸9Éÿ"böÓ©½¼'ZQ'èÀOujDı¸!ç?ú…‹>M	"Õä´»oSĞ‡,7öĞ"Y%‘Ä!($ÿÎOœÛµœÓ8Êñ!ô‘1ÿ0ì(3;İG…¤(5Î‚8é¯‰x÷Xim Å†ey•Ø_ØLíxĞçr®‹}rmÏÑ#=£ëdEo–.33~¿v(ŞÉ´N5hÚÇÁO¯¹É”ÌAA¬EPEÿíŒù&WÁø´¦ØçIÛµxÁ•ş®§û‰09$ˆoÃcğl€W´®Üeƒï`tT-í™æÇüöX5qìõê˜±¨ Ã“"/ƒé†Z‰Gfg£SÄ]ßÆd»à"H§Q@¨_y&mì°ôÿX(#ˆƒ¿è+ä&n¿‘H>•c?|+!Jİ1+	™Ñd\b<ÓW$GÃé;
LÈ½•¼r”íÉç’e¼•å(û©^½ˆ^ –¯î½5D>ÇVs>£oØÜ‡ÇîÁIpŠÓNŞ¨hçîñâÍ¬-€{·£æ*‡£éÎZô½åR·w$¾ğòËÑ6ªÏ|J–@áFÂ‡gŒß¿$ê[Œ½ï ã„U{|nŠ} æ×ÍÔ[`?†¡Ã›ÙjÆ™¢ïyW@ŞT_®*Ä¯y·vH«y›N¼:àV1¹V¤•à3Bd¢árÏf	ü‹x…`jè³KÁ%s‹Ò˜~Ş-úâ×á‰@Jg¤õ~·òşgqEŸ…®øÿüqÀ Ì^ÕgéT¤3‚âÃ¿ı fUá ß"i'%(µä•j•˜{ß¸†Í7ä!ˆá{y £ºçÕÒÅÈÏ¸ÒÁ“1¾¥!Ò|:)ÁŸaQZ0ûÿÉ•xºÚÙ2òZã››ğJDõ×V“Jöš¶<¤½’Y¥BÀT-@0èçğµ†!!~CLG)|F×t‹¤÷Õ†u¨lëÃÒã¿ÿÅœXô<„éØv`yÿRĞ²Â.ã"Ò»¯µ’ÍBÏŞ$ÑGuÿ.­üÇÔĞUp†añ¼i\uyáqõ¼[ÙÙš¹Ö¢AË«Ëwnì‚ƒÿÀh´bÊ.…Ok1Â€¢®*ó™œb¬Õ?ÇŒÁë„ï`l†1-ß`†j½ğ§ò—©¸•ÄÒ‹ºT;6$t½Ì3F¤]$÷” ŒR}kü>ÃêL=×¡·rÎW¡’5+ÔĞêæ‰±’6´Æ{]ƒêâ°E¹ºvŒÅ³·‡™ôS-=šçÓ©‹È¯ì”Ï¸êIFÄ†øğİºÀE¸ŠDç$ó§Õ
œğ7&gÿˆ¶·3¯d3aéF=w9'ª(o˜u ¾Òü`OA²,ÁŒS®ˆH…´JCpß'’)Ÿ øÁÃ­ò]UDì¨iq#4ÏKeè-ÃCQOí°îÈù 0_ğ&‰4¢ğê‹å§se|<±Ÿ$R‡<é6iÂ`˜š|^vşòãÜë;|š¶ŒÿCH…VÉY·ÊC·d£µ¥Ñ<6­r(°ºåC¥ğB{ˆ/D8ZhA$Pn<*—ó!ÉàÉC­éˆ…‚raìá™ÄC–ô°Õº2„ïŸúŠÚ¨Õ€ÂÉÀCœùÎƒE>”+2.ÑÒúM?û®ÃlÁzl¸4–CÔ7<Ê3È‰À¾w«ÂæÀË³·Ş{O„h6:ŞHpÇMvN7iK¯^¤¼y+ğ¸@®®gÄ%öäŒÿğÛ!dÉVÄh$¬V®¸–À÷g0’=:Wªx`Ò>|Xw'#$Á;,ëôˆ˜ªÁÕŒpnıÈgP¢ïƒÀeÙ™¿´9îÕü¹”\ĞºzÙÀrÍD0ÎnÄá ÿå³ä8X›j[NqoØNÕr?®[u”òJå‚~‘?ˆHüÑä¡Ì’Ø…_Ä,[xÊæs³‰]d
ç“~¢ ?KLÿ¹CÂù˜:´*#=¥‹¯ÎÚçÚ;Y‰JšÌ
µÓeéà‰‹p¤¤òqlP%¥¡²É¯ê`s!BŞ¬2ñXutâµ‹w&²ÖFàÄW†#«à²|\òª,üôçEã ï]óîi Pnx:Ù)t½Â#šÚ5é×
ˆ©ƒN(µc®”{ì*ıÆk#wlb:»%ï\x9[ÄIò¸¡e/ö)E•,Ã™(ÚÆƒ|-z ?@2_ˆÊòHÂva¦—ig i
ûÖæxØæn¨ØuÏœÒÆ)Å¤Y}córàJÀi7L³Q)>âµHl;Îhœä®¬U|á5:‰ˆY1â”÷SÃ;ö½´ı	èĞ „0Rø3‘Q‡(
p¿õİ$¿Û†’lmCRÎ="U#—§Q"ëhŒOŸdºdj"…*°ô®‘còÚº©–­„-
Ò«ˆÎŒm²ğtı§ÛÈdöyö½JËg§ûğÚM©ä€ñoª¶%x=R3§å3ä˜ú@¿ß-·lwµ­jß·,¾«´ûÙÄ…XdÂ;²k¿GëÛ–ü¨¦†f-_×¹Lñ¿ƒ<½ø[„hşÈ!NØßŸÃÁ&1xqQ».*¸d@ã‘!€Ìm¤BŠòa.?=_ìõóO5ıV¶C™6lnÏ†9zaúFğÇAşEcjh>½ê>sØ5/Sh'iO5=pğ%ay¥~ûScÈ¦é¶ùADíH­+Ò¼|‚¶>`Z ¯ô­&/”}uçBvkôq¹»7·óÂSZJûJSñ,*İ6Ns52"øy°í={EBAx¨È¨ÆG)¤7Çó8"0•~PPäƒ?ÿ|øfg•}Ì¿J†®>…ô¨=õeÖ1¦Œ5 ÚuöœZº‚+?x®'`f7TğdÀWjn†Ñ±9ò~Ğ§hH*©™­×æİ£{ŞíÓ:ë2»ò©ı¤¨3åì».-4JŞb¤8­İœRofJ~à0ùÌUzoàç4¿âO r°àLÇ­o¯|$€_MÇôæûğaLfp¦.ğJ×±Ø‹æuiŸ±÷±kùQTê.H
wRÊA®XËñß‹8‡â*ÖüpHÿŞÛNKÉ‹#ˆCV.>íÊ?…[Ø4bÉÁŠíu³ÃÙµtÒlŒG¹@ ¶ŸÚ›:,LvÇŒJEÿ¶®ôW°ÄõÄ …á²¼ÁLÄëKé–bıtzEÚˆ4¶9¿Ù®t Û#N–àŒÏ 3şÔ§÷4FvH‘ôù—Gş»ÖCŞMhM=¢’bP'ã›”&ËCYb ¤‘ÇÍF¥öBP¡1ÇYC™NŞÆ‹t_$:Ø`—u›¥m)Ø^ ®}ğ_š3.ÀÓğä#úP8a ¤²²lºt†ë–öÚYñ¶X÷'ş:NFûº7CÂËBšyuvÏî9±)²su5¯'%‘"(²wRBF´· êÜ@åA–¹ö¦,#şñÒ!+ƒ7ŒcMªdêò¦;ˆ7×¯¨±qÁVÇ6;k®È+FXĞ5Œ™4\Ùk<ĞÌ?±¾añN¼!ÛåæUÂ¬ˆz‰LZ…˜)5E8„XƒÌJçlŠOu3OãWÎ&h1ì/`X6áŞÖERL»<ã2ˆ<œk-EÉ/ün
Ş+†¦¾—›]êNUMÒT{Ğ²ˆ:vp¨” WGn4¤ÁqúDMÀ_|3Òfóšqq¶t,¯ÌÃ/a?‹ŒÉ¥'D¿2øzSç‹…îñŞÓ™Ëãåïe„Ík l/„†‚ê/Õ÷(&ˆî5ÄèV¶*¢—ıs­öËàÃjøu³NwË2º*T,ê¬âaQ]=²W·Ğc_	]!*(ì²ğÇ]VØ˜2‹SĞÈ.m7ÓÑ 5M·Ñ#½ii·Š/¤ƒ‘¹¬¦hÌªÎS"9ƒdŞÖ$9£eşÉ“àVíû’Ñ”QJdÑv$F®b­ÒäÎ- ùğƒşêØ?lBOFQóE-)wï,§V«¬½ç†	LG/RqÖşğâQÄIw®EÎÿUÀò“ÛcUV@Á©ç/
ËÒw=Pñ¹qõ!0«vÂ;ŸIÑüHÿŠ”Ü7{àÀ‡tMÎ°¾†=¼¹C‚°P¥iRˆA}eÑ—›¿–ë,´Wú‡zJd °[óbŒ¸¯ Ş­ñ;øyŒªÒ¦ÚµÉ’wñÀ09Ô•â’3±"–³s¹À.öaLÀË-ÙwÓsWçİ¨F£ÂNÁ/`ĞxZ¥•ÛŸmêd¹z°§§a÷WË-ÀÊ6÷HÅÒ?Ûê+ñæ<”¼^Z›0	/Ó‡½CMM‚ìJ(MhÓQs£D~—I|aTOŒõ-æCÑã47ğvÛ]ÖL‰#+ |Ïïä~Æ¦4Ñ¨‘äµ“Aô…!¦¿ô±[€"ÕŸ£8IÙşÿÕ	ÉÁY lµÕÏØœç¸È ˆGüÕãrÆ­-ŠÑİ¿x7Úd2)¹¡(ü&ÙÔ«ÿXŠQzjI]ú=—í¸>?·Ø¤«Q1SŠ~£«åßL§ªÛœÓfw^	ÆU£Sg˜›- 4›DQ½ñ;ÕÃÏ¼óìw^èÜ GÚÁ>ğ‘¾´”¼Vƒ¡pM£Ñ‚5"£y[ı€Q’õå³ù ªÿ¦Ü]©6\©Óï<l*’Âm^HœÜ¹)âö¸¿Á<ƒî×T>«›Dt&XsMƒØïA¿)ùÑkIH QĞT/uİ9rrx†<¼Ò„¥BÁyJŠéÆu5ÿN†Bà<ælãç#ì8ÓÔ		¯‡Ú}¸ö†ee´ÓÉPÚé@[É²w ^ı]R;Ãye62õö¸‰ÚIHßºşs¯jë™`Ï¬p¤ÖTù*#¶ÌOz+†— %N£ÑÃ˜²Gş+oÓXå_œ)Ó`"C÷Åûlõišè£‡êØÜúc*ì×ªmÆÃ¢Ğğ™áæ˜ËØË°ĞXÃtÈƒB]Û–f]¢²;
A0'ù&.+Ø±,ÌF™¯à‡Üº…	=-½ DSf¡'`NÕ†o^(Ğ˜^ÊME£Û½êGÛÎù×yÎ†+óÛğ77ªBä‰ºÀÖÇ:ß3¯Iµ¤šG”L¢G$y¶§LJeÇF¨Dé[¬å2Ğ€]‚Ï®úOıÆ~Z»ÿCÒõË‹ÂË)lKİj˜º(ç¤†!XØÚ“¶ÈşBç¥m1H_ÃMã¶’©€x6 ¡‡-—ò"îî07üK¨;èxÉèè^6ó1Òİ4[şÚÀ0 @|ô÷÷¢k¤Şíhp	.p!6»–hº¶®İâæŒ]Ë”A@š²ˆify…`0ß.àhóÅ ½4Ö(#µ‚"Ü‘4óf¬]º‹uön8‚—ü?–ª!wó\bêÀ®Ö¼O·ø£İ¨¨
£³lrxïúp%J£”ÿÀ­ „­Â9åEf$_7 YV*_ª´³ßç/-c¶¼jÑõE~I®Me ƒaæ–B¨•ÇE)²\±È˜-ù½TË/Y# ÖÕ9Ÿ×^6Æq>!Ul+Cdƒ!tDyUoKŸâ"­›®S`§ïÖÌ«+f5%{ŸáÆU	Ùµ7O¹ÿ<YÇò.& 2w¢×ÁM:mçç Z¤» ˆ,×~T ›’­ê@µå> 

9¦LP>QîŞš2,l—G—ßÊpéĞ.#ry&º¹Ë³i†/kÜ]çÖ÷¢Bú,âÄØ6¹©¸µêÕ(^½á¦òÙí“§÷9×ƒí©¿o# L#@şo¨úu"EBT¾'NÜlœ9ñÍÔO‡®»véŸç#hâ{¨€Ø„šÔÙwığQğ0ƒÖßâ ŸAô+‹Ş€ráA¦ã‘j'Öå°üY9Utÿ{‰ÓO¯&!şÏº P@E/yS=6Qn8zâä©·Êbp8	î—›àt ½Ó¸½Ãz\İ ñ«F¾Ójç¯` ğ¬§E1´ªœ«'­Y6Ê÷ktÚmâ ­Èœ_£ÑïÛeSÇÇj8}¶Âgñš–O0¸EÙñ4*ÀóYôgWcü¢ŞñàvÙNjr_©­ñº^ô€Nˆ
R»öe½hV©«Ş€»ãúâ‡8c/¯ˆ°«/EšàhÙpRsúU¼·¦Ú=S†Ï–ìëX çRœ4€>ùhîküm˜êQ M—7#‚h¦P×ÌQëü§x‚LÉZ àgğ\„•ê" ˜	’ĞŸIæÒÍ4EB ‹Ü¨*öÍ~’Mš)å?¿uò€ãGÏ³äAü?,#~Ä™,zA;ÓÇa
wÛåK Ú$[«/Q>Iù:oJ´yŞK0U¦jÚ£¬^9N\iíØNÂEœådMDk­•01ËÃÌ¯¼P=B“'ç®ûJkqüë;(Z¿6tJeïÏsU²cël¿ÇWŠ­Hi($l.±Oªø¬Şà†%)7*Ö’8%˜ iÔÓ5ëìUB¯Xè>Ğ×(„ˆß¯Ì*Ç<Îücjøbä%×€d—6,Àí:ÕoJç7C¬rÕì}7ÑAğş‘²U :ÅºÔ «Ik$—ä<´&`nÕıP:¾ßEgÓq’\)‰ñ´]s¾AŸíA¾7`¦°«_Ë‹„t)–³Ó0ô¸Ó z¬À‹'úsØÆ7š0°—„›ÖP4ìHUS¬ê-˜¢ZÓQYk}Ó'÷£‚6¿j³Pøùc¹³/uÓ¦–´dXè€ÿİšM­¦	Ô ZP!r.•1C›’fŒÕô‹Ã´X°m·»²
	 R2GŒìÎMe&ösf&`ºF˜ìƒÔ©#VJ[lzÔ"1ÈğÅ¥=²M¶¬Ï ~Ş‘ò>íCU{iÙAâyÿURJQbµ›Aİ~42¡U@M\–x-:Bÿ>ë¾[ÇQş»½g6abÃäM«§_ŸµG’Í^óıA¶~HBßÑ´-¯‰H¢À(Ë2‘Ö°é"×¸5V×tsÚà	êWÂ˜h+b¡ëÈw|¶g&›wHé21tFÈÚ¢^A×›I-GJ¿Ñ@=AŒ~©è›ÙîıÉÔ=ÌP‡¶
Sÿ÷ö[ÇÀß93÷5g¹şT/\J‚º¶°à6åõóSmMâåÛe¥á5JãBåk€›¡š¼!«ç$ƒ<ÈDP0;ï»;fåÇàGiQ‡ç_¨ ã7é‘–¥AZ’‰¹Ã:êªÌëq9¬T$ª©,Nq«Åˆù¯$ÁˆïÜà?¬^P•ªôIê97À¸zUÏôN#ùIšUÕÑ9á·HËš¾&jH–²‘Öx\“ÈŠıÂ£“HÍLw×Â–âÍ/ğï€nÈ+EYV©ùbç¢uY´œæ¿ƒèxÉ‚6,W“
À|¹pèbS
ä ıRÚgíêK¢İòp#ŸXà¶*)ç)å¿³YMİÅLarRV¢½~ÛÏÖ†zu>aO”x¥¡Á’c÷¨¤ÄVœo<ÈÉ ¼¤w:šÊzwAW™`¼±jü§zö{†Ÿ|."¥°··O	ZÌ?¼É:Àéú³|9a_8~İJŞ®Q ±ÉÄµ]«’œË}È¤{›>öşëK’İ9ıñ#²|V{(Læø¯£œrø
¢j²'»DZóÁíËv@X‰Z­ñøà‚#ø·ÿâµAQÕÊ9èQ›«¹Í%ÕK¸%Z@Ì¤ñò³àBfËàòrúLÊ/\ŸÖ¾ûÜHw5f­÷V›1Ê•±6Ïî‚zÇÚ‡R<áâÖd(2)ş	¯ÈšPä˜àâíçDÏÕ˜¼­;íMD.ÍT×Î8Š¼F/PÔS]Ï“SRÄÚ4ë	İ¾ÙˆRLF¶ù½S%D%ïê`‡°AÎN¿”7ÍéÇkvPp€¢yŠ%UÎD=™çĞøŸ?K8*?@ã§ı/w†ªVşF/‚¦]›‰êö~¹^Ñ¢kì­ÓèC£ñ`Flú çù'qÙ ï‰‚zÒy8!pˆ-T°ãp¶{ŠÇQêT·}&¤Z£'ÏÃª?r}FBl5½—È}‡éíakr+N!5N)ê3÷¼]uTíòSÿo‡ÌÚ~ Gˆüìx®*ú$¹wC’Ê4s¿Qô–¥6ë§df›±GÓh›.š¬ÉOà1=ÅÑ¨{õvÛjŞ’¤u@ã¢©IW~Şjp&—\ÙíîcÁª>µ9œÍÏ´ŸŒö´ hó²ÒTÀ«¢=àƒ6›"JÏ÷ğ¯q‚Í†ç¹VıùõÊzÖF²ØØùæÆÈ5nxÆÚ-¡Ùá~u!A˜·T‹Å±-¯F[B°•Á
Üì8ãİ›ˆ=Ã¼ô½6ÿ3ïzÙmÇb.ÑD ÉÙÌBk›sñD­œÁ7¨œÍO¤m1ì™”jI‰‡T/ØD¨öèÒl_]\˜;aÊ.&w)çéÒİ"€uj›Ì>á^Ç×ÁÙH5¨Fjk'ii!GÂd¿FŸc»;dÎ²íÈ*ïKz3­ª8Kc=»vqÙÎ ÊfØ}\j>@íÿè>œ°¦qH·¬ÇqÕqùj%tÆìJô‚ŸkËÅ˜@yp×`q[ö¯5Ãû6½éKNƒj%pkÀkF—Ÿ¤õÇ {İ>ÒŞ˜Q}[aà Êstø¸çO$óŠò¶1Zy´›?C÷‚}ï¿ÁL°M]ÏÛuş¾“Ò×íPS~Y4QìÛQÒ°4$ı‚ıà(Û4B;f^«hT¶QqL.Šy\^Ái&œ‰Çz\Xˆâ&LÓÆ\Ì‚SÊ¸äãnÓÒ‰´#@¯kCp›¶ÎQ`
	Ó,ªßìE{úşudÂrQ§	y†¨Š§6¶ÂÈ/ıÀ%~w%¥dfçªç90ìxüƒÁ'SæÌÆü¨;jıˆ¸¯c«´·92DâPÂ¸«øhÌxåÜ~¡ç¼vÔ~¼vĞåUxï²¯ø}=ÑÊı÷1TØóvRéqIÈºo¼¸rHF–B¢ˆhÁ3æé’Èòæ0Š¤`nÑ¥?Z‰\*İú*‰n&²`0–Ğp?÷İÇÿWß"ú8ÿ°l±•ó÷£KYY_1U)–$XQÌgÄ¤FÌ
WÄÚFéG£‰bVRè·ÛÀbÔ+»äïb;}¾>fÁwj_x’öd·Iíìê\¸Ö×;ıë| èõË5›»š«·émc{Oİ¯«ˆğÇ”âŸ+º)¯pR®±|P|Ï2Ùæ:“±H&%÷i;úï0±°-ÙYJî9NAö¦|@çèˆÿB)Fˆvƒh*«B¼#Ì•b†}¿ _}qs{[¸ª ÛL_2‰ê?¼-`9ã[­Ô¼è·¶â^©ówÚJ,ï0"èSÑh•8Ë?R{¬ T˜ªY,ÓVù}t*ôÆ°€‘“úÃ^Ğğ4s%IÖNï˜‘·ÍQá‰zP%ŸLPlMŠH›Nß!:?$:Û:İ©½ÒèÙ8xÌìœ×d	‹¤î=¡ÕåÕo^Ôía¿8/ïdCÃÆK~ôœ~ª&afÚTd `}Fz¸G³‹}âî.­G:‰xğRÂT¸nÏ7q¶§%¥UÒ‘`V³THï­ƒu¡÷ˆØ Ñ]hX_ŞÌ.jòXk4Vz¶¯n†Æ»d:ç‚¹[wuş²/½……ãV´;{ÓJƒeæïêÚÍ£Œ)D(B™tÿ²×¦–?¬g+Éåì¼ eT!œªÈ¡¡Tèz!âşæ%Pƒ [VÙ[§¶î
ÕÄ\ËŒĞD ©`#:…pŸ¢.ºPZ³ÁÉ[³¢d;‰È¤X%z¤)ÆÒİfrX\aPì7‘ı“+r:,—}qIQVOxG[T$x µDµü“(÷xEÏ¸ĞWû°pÎ{·÷½Õ!˜ÒñZÉÒ½m¡§Ú†›„ŞÅ~	7«À­Š”¡¸GÓmÑÈ0>BZ8é³Ş­Ó ´İlÉIfH?NÙœ°ñ
×¬ÉO=tcA5¯ß3@½¦Úÿˆçc^o[ ¼0¦ëÃQU‡–?†²Z·áæ?®Íñ–^â¼Crşœx°øŠÍş|Î‹ñç®<cšİ
”A·çtO›}3/³ädè)şÔBzozŠ¹ÌÍúgädMMÃ(íä>@¼Ò=Ä‹+/ËvøvY1®,óhÉç¡³Ò®øO-a„†“äE‚’d,èŒÙ¢­¤\ì€ƒ…¸ğ©zZ¬‹—Ü*tŠC£xÃŒr9ÏAS­ML)DãW(<—mVÊ•çø‰^xß¶}î$ª!ËnM†ÂÒûÏ¢öl1èšÔ¡mãÙ2›fMªàÑt>‰1A9Í»:>Rwı §æ‡-ô@KºEƒ;ÈÉJ¶©!Ø‹Ña°<×&/vÊ²NöAî¬1Ù•Ï’† åHÛ¼tŞÆ~(
/~‹Ó­@?½ŞÒí–cS}µ?\Ú¤oÁˆœr
±‘ ,è¶»D²íw¦k¦|ÈpñS£É´.×Ñòn"IF­ÜòÙ‡5èd¢°ÚJF84Úƒ’ÓGˆÕ±Òğá›ióü–$QcÏ‘&ÊN¨ö’èŠ—¬Å§h,É?Æ­ŒäŸ&•“ì~Ï¸ó®Ø§Ã‘‘›¥‹NøåùƒwÂ)ÍÍùÿ–škŠ´š¨>cŒT/aÒ†•È{»c§]R×öÊÃËòz“>µAB¸q¤†²ø7êàê¹Øg 
"çc¥y—,N‚ù<ó“Â´)¥™œ|–ÔÄ¶}šÚCŸF—œ³®ÁWÆj@«¬É·³ÓÓ»|ĞszV½†QÚå†è™ü(Äïáİv¨áÎÿsé€f=8vºàK³ÒÿêQNš…Ò€ŒÉ8CÖtÊjc&ŞĞğ£W^çPêÿj0™¥sÜ(¿9Ã¼612¡_HÙ[ˆ²œÅ“]ÿY´ÉĞ2Zˆ¶fÁVİ¥V‹OAˆıç¶?ÁuâñÃ‡Àj2÷5’Û˜¬ÉãÜ](+Nã´@‡v~õœ:§v/Ô%qSæã¼ˆÃ®Ó#mí‰³å—P}QãÑº"ÖºëzBs¾¨³(?±xÛíş2ÌÕÒû¼ãs“"e–Øñ8(;ƒ„~»˜š‚Qa`„j4İÈy`ne‡uã	€zˆœ¢í>e‹Éö7†-øóI5´¥Øpn ­R	ÄÇƒ.Å2b²³yúÊç'ş*Uºïä>ïhp`w™BÍÑ|°¬Aƒô{Ù &³°· |yAZÜr’¿Ä{fëq&*Iœ†Pb©©dF =Ë	Jîú½líüµ£ı„†zØ{*O¯ú+š¾w¢Èàym[ëóU”ìĞ¥‰(ŒíiŒ*ğ5«gF¶ÛÓò€ûéóE(²;tü0ù4w#Äk'¡ÜMW¿ª–ÿ¬¤Õ=;>Ö‡ÂÀz¤SìO÷æÉÕ§d&-óhŠ¡TèXçñ€Ø(7YsÙP@5†“ZÁã´ÀãƒÅŸ÷Ëö<U–HĞÃ‡§87{Æ^ s”€Ÿ?Š!cd¶•|ãQ7ôE—rTâ›fÇÊ¾îıˆjÜ/_d­Á`5#­*lKÓ÷m°z¥ÄòÛˆg	¶¢ zx¨ÈÅ¯Õ‘'d¥I§Nlœ cÖ³V$q½
V—BM¾Ë‚kÙ3wÅîÉš„¢JÉPÕéìÉGOùœÊª·rñ{/H“©û×œóOÕe`ÑšBÈ?¹åÔß¤­?Í]å}ÔBâ]=n™fc;-¬Ñ-ŞÌ¢µÅ?d^ÇÏ	V0C/:ˆ%ò‚~7iÇÖ—ÀôÆæ«l¼ÔŒÇÜŞR¼« ?î÷ŒX)ì#_ê`¨>¶î~^.Sœ)¶Ö#×iæqÃX-…kŸ)Ï ÿ'6–‘ø,Yó`h 
¾‹ñ¸*<&êzÄ—÷ä’‚ŒÂM/) Š_Nß v¦ò_, =‡E¤¶]Ø~£±¶Ã–÷œF6“ ìÅ¤7€^?21&˜†køn\Í7Õ”¢»ı¾¹´9C]™~Ÿpë„hú]sûÜ¥ÑfCÔÅ€joÍŠ<°&6Ètª!¹f‡~ˆ¥OgĞõ¥SZiqš8Ÿ­bG.vTG„ìÿvoŸË#ÄMøuèü,¶æ6é4÷S
g*“5)kÍÙ?@ç¶,×¶ÜwI"±øé°w¡ÍÖÓ‰¼j5¾Ó,¿D`¯¯àßX«ğb¶®È’Æ6µU%Èkg5¥Ÿ‡ºç®Îi\ør:·Íõ¼³Z>Ç>P+{²23‚âû8€ ;¹8¥ç©¨nÎú(â%Æ³K?jò¢*òhDŠJÜ†«¸À5vÚ¶*zŞœäCt,î×(©s·€çnğ´‘âÍ ÿZ{c)$ˆ¬ßR9r’UÍŸ¼Ã÷íÕ‹Dxtï8ÜşP9“Ü€ZH5x}ş>òğÂñbœ|TpsiL‹ä½*ÛÚ‘Sr/üGX¬rq)Ÿ:Mpù·vØ¿8s^„Šg&&æ»ûµxwi¤s/Q(„kwàDwPÙKQ=®­u…àú>w¤–¡(ÙBP Pró{³ƒ¾6Vú1R@;æœ¸Äò&2 ‘Ü³°Ô}¼Öí[,¹q^şE0ˆøjL>À¾+8Qå2P Š9	Ë-©d×bûXÉ\5ã±­ S¢»­I*­.Á0û]
ˆô\™‹ƒKªŞöÊ´—ŞÆÙIR¿µÛ)^=³O¬“ı¡‚Ï^ófÖÃâ¼¼ö­,¾ù8à¨¿ğv]ÇŞ½ş‡/¬dø!¡×½c¡Ğ$Y(bBÈ¤;E„œ;ã,ØFµ®%Š¡#L@`°G–Ø	ãªäiÜ8nÑ†amß	­
|T:_*xcSÃ§â‰¿{şd‘®“æ¬g‚æÈ{‹ı-¤T¹üÛ¬KÍ“jÁG‘ŸÇ¦Rªy,ÏAy©0Î†~6~ËyÉƒÚŸ¾ƒÙ•-1šÓ3j6ÇU»û,æQ°¾¬O(mBPÿ}Ø l¿÷—€ÌÆØJ]»€C¦ºíøö)¯ƒÄMr@ş{ ñ×âŸcŠ_‰¯E]ç™\GØP…@*”¹GçSó(b¬X1íğy¢Ã¬éü¥ôŞ¿•gnWDâØÉÄ35çŒ<Ì?ÀŞ9ÅŞ2[qÖàİœíoü¿‘jÙ½Œ™K`¢7#™©ïïÛ¸áo»’:t¥º#Ù/>nc¡@ªN?ÅQ(ÁVxc%¢M¿ßñ;ê6B1›¾ğ,EÚÎÓSƒ±l-¿¿¬¶¢xˆğ mçÃ5ûoõØ‘õFS(HÚªD²Œı-v³1òƒÄ°Šğµ+:8_ù¶ÛD‡Ì!'9ebÎöQUUmñËá<{’ÂŠê†ìÜ‡Ò(ÏñÏ’ş¢¥L6‘¸Ã{1m’-[|F¾ªk™!“7¾W…¿„~ÔÄá‹Ú²RK/k­èğ mŸéI£ƒ¥íşxÿ¬é5×Ù°»{‰ÇÍø/oWJÜ$Ã‚cª¯¸‰ô–.sÅË“®zFãÿò±ïmèú	U(ıæ°•-G÷N\ØU=…Ñ‰éÏ«N,Sâøyg±VNŞ)385n`Z+¨0·m–fë?4!ñ™¿íì/¦¤X w™j1°w²T×âc¯C;‘:óZ–"çªãIt/ÆŸ%·Ñ‘U”WñÛc«B’ÆÑggZ1Z’È*7“£Ø$·³C‹˜`ğ!áuPxE>½MeK¼òAuĞ0^†å@À÷v8’¥ &Á/yÂ7 –¡¼¹:y&'ãÃ*VÖöLX©ÔÖã’
üô<¡Å‡	¢i¯p{&ËkzÄa·¢‰7Q±­>¬Ï8hæ³üÅüfr>´N¥¶ó%»–Jnwİ½qı0#’Şiç½’ÇB­Î­Ÿ…NJI&f“,@Àíÿ„ğª¤sŞíõ¨²Vœ.Õ‘:/Í-Èz…ÓĞĞÔte’¢¹Y0©°7­®;‚a2•‘)„×EÚÖ}éí(°Ü¾ˆ«Ú˜é"`]õÎ
ïêÅCÖKá–ã~Ìèë8ë¼š„H/™yzZ­Ï,øÃ÷™§ñ>Ùö#g^P·îi¸Ê•Ãc¾'?aüàK2c,ª½ÂŠz ?.Ú}îª…"Ø>„ªSŒ²NÊ 'z;Z‡½ã”áåå•*Õe¥‰¨,˜˜öµ¾AÙ¾µ`/@«m•áá¹iÁŒÊì;˜ˆ^†0ÛsOÀšgÙõï!Ó¼ÚøÑü -Ï…ëÌT'/2“™ c#p=J°ÜM3›4Â8Ù)Ì¸|bÎ¥Çñ ­…CÔ‰àb4Š£Cæh ‚U ¦š3`C'üV
ğş{`3†¡Çé«T<İNÑÌÿ@<LL<°èXú–¯k}ıD—[Gœj%èd9.À?×Äg·`­}£xF?µó0ï0
R ¨¼¥¾8Ñ3ì‡’™	AßB3¹N((o+,fQ{İÍNÆ˜­ù	Õg#%µò¯š¤åš‚ü Å¥²ü÷¤’½Ÿ-€–Ìjxëûe@¦¶–^{ÌÔ«ïàwî@Í ùD#¦Í÷¼şË’¤¼‚jj«¨\‘ËWd&©©+×U;­ØÏ•ëÊ|™ycnûa¼¬‘%ì÷¦A·Ùe1{@!‚ğ­¾—gRèMF®"ëdÌ »6·jÙ4gÇP¶6|i;$—hÜC¦ü=Å;q¬L­vµ<¶i öróY$&‰øÉ—eİ>Ûü¹­±¢ºÔ|^S~«¦¯¾aB<åMLÜş,~k5PdÈC_é‰¸DŒÌâTãBÁ=¿zä§úÜÏü3B®-2á#ôb¸Í4`4¾¯öä‹¨æß×ùm½X÷‡šotÿ\2ø9xmÖ•¦æ›St-£ş×;LUraøÅ”GØ¢Óàş94)M2ŠëgYX·˜ïoK'¶,õ5o Ä‡Ò3¹ÃßôVëÁØÃÓõ4€@¬ñÊH4õ}|vWao¾ÍôÉÃ>ÂãDÍÃL‚¥Á/¶8}İ
’.4æ‡˜S8Ë5$¥†3I¯8åIã½`0ŸÆ5ë˜4·Öâc¬–*½"A+Öe‘éŠè>İµô5İ§‰Ó~¸V›Šº‘E¾Õ˜UM¯‡=C_p–§~87;(~À 0‰Q“ÅI”hÂa”VĞc—ºŞuå.­ÊÙ6`Ù•Ñ‹
·¶¿n­ÊK‹õC›`jc×í‘3Oï‡¼JA õqošÛm½m}-²„
#Ç J™_4‡äf35<©µ8ƒi[´#Ûì}}A¾­ç7?åU_Ò÷S:=9MCç D³©aøû_!ß:Æ]ñ46ú‚%6Á38	9%VOp0ÀŒåÇ‘ˆ—ª¾OÌ?É4¨ÄYª=G¶™\éI¯¡‚ÔÖ2Ìï™¬2şšxü„ôv×JõıW^µz*¼ÊQ&Ş4ù6èÌ˜å\ç€Jı³Ãf}ğJöTú	'©êÔ‹¾ètIØÀáiê‘e®Ä,âÖY¯"Ã7´Ú¸b:(1Ë¥‚»ËÙnñÈé„Âº{‹ iW}¼äî¸}_†\â~dØä¦¬àr>ÑR›²Ñ5ïqÏWÚ2»(ñ0QJkhOvİƒÇi=KÁOÈÎøtÁÀ\,V:çò‹^¬zÅ§m8
¦Pª·­˜e.ışæ<Ã?Ãš.€«Æ“z/—aˆ'®ØôyĞ‹Íf{œVàÈTU¡Öæ5 ]¯å ÿ•©!Ş°äÆ¨RKÌ5˜^éâBƒô¢.qæULÿ–„›‚úı¼Q« $P‚ü”ğÜ¥›³y0òõn4é:ÊŒL ÈÕ½›˜z¬;²ª¬ E|ˆc¼Ú­ÊøÃaKè\ â»ñ{¤"B§†Ody;/°©Céİs:ÚHI)8#ËÑæÿBp†¡GJ¤ŸËÿ×’F/ƒÙğ6ÓV›3Òg%i° 	¢«®Æ‡Ó7ø[ÿÔ‡<·-I®„Ö€sô3ÏM»a|YHˆ!1\¬ åJÊÎÔÎgæÁYÃmI;z³û]šó“”ªñ¸Lá±]ëIº•9“~pf³Ãû¹“º8QPâö H¿æœ{	TÊÉÁD3Â›qBw«çö=D+Ì*euäyDÖ³-ùPÏAëf8÷+Ò¿_·Y'±âHLÄ>Ün(Ù–¨éZ6 Mu1æû}»ÓjßŞ¯Ö[æš£õHãV_ÎV¸QË6£HŞüz>É
~œûÖS~?¥('>(ê»(6B[ˆWzF‰‡Dá$R»Ø§ÆŸ/ÎŠ©y³ŸÑ…¨M:àJUÜºqßšÃEïJ)Ù~ù¹zµÏ™ ëj’Ûš ùÔJÊ1ò°@Lpwá¥CmÜ™Ñ¤¹¾SqZû
×€Cù£¹±6ŠHÏ: »
Ğ£‘µbEF,¿ÓŸätkÅ©ì]¶î$ÉÛÏ;VCX€ÖyøZŞ£ÇD¸|íBTHò.ö"ş-fÎì*œ2,~ìÀ¹.„ÒßôŞëç V:R>–şk¹çL€.…a%ÒĞûxöàô?Ì`V|mjLÿšU£èÊ%A:'¿ñpıı›v³ÌBª·§pù#à6©$„Öc×…­7§U	×Š»»²8Ğª%4ÃÉî…ŞJC~£ÉÌ£ôZì]¼>›ÜXFñòîZŒCö)*È898èJ$—±E¬İrYÙ7tOwI@‡×#	(ŠBiÁ·ãVj>CÿèUB~C ¡_…¨ä:A	]à‡LeŸ[+Ûš&¬ûÊ¢sãDës÷GGÂ4Äı?› _¿AÖsQr¤ıV ÜEFÿDŒY‹ :§8ÂvföÁın á>&²×Ñ+PE_mƒ)Òã¶kBŒ²u{pOèû³ZQó‘ÃQüwrP¹‡$lôç¼Û·œ>'¥¡C/ãÁ»2	ñ{·°Åµï3¡A@Qí0¡ß¢¬ŒŸå]0€Ş™TÊ¾6Ó
sgŠBİëôÅŸ"õ¿‡z¬ÓE6¤YÖÔB¦à±ßv]ªÆ£á¼Â½È®Oıh&nkÑèyµÃ&wnšASH¯E#At»­-k+ò[|S£‹§,‘‚*1€øZ¡:Yş ª!JÀ:×UMı²ßËëÓ˜õu‡¤•zQæ1ëª×‹ñ!"±³Qyó“—ù¨Ç5C9¹}ÍÒ”Dô)®¸‹´Šn!İW3/˜9éˆ.ºå5:z'97îŸß“:ËÊ¼†_ë:…îY_2C?]:”;‡µãü[dú¨Ôn$çŞ‰©X£Ü‡¬Ûq4K£"şKxBÖ€%s¾h¸3¿2‰ä(ºIØÔ$œY´U*-	~˜çà"¨6…ÃJV™©àpp5¯%ÚQkGGÃvTuÇ¦‚Oõ¢jË;dÜxa€¸ü—M©ø}bêRá6eµª¢\%/ƒ=n»ìŠ·ò¼•Æ—#òÊÜb	’Ÿ/8Ñ=Õü¡%†|î’ ~ìs	gP÷õ%•€MûÅõ3É£ñ€nDku ¾‰@j˜ó|9²F6ÎÎÓR,ùÑïQÈˆ=82ÒÙXû­}¦áú2Ë¹;nÿÀ¹ÿÃ•’¶4q´³•¬©•Ûf*öôÅ_=Ùp\*¿K|#òHÃİôg(Ÿ>a‹Ğ?
§›E,—ñ¹[bm9MŒQ]…
;¶z³¡CĞöF¢U²íÅzøJ2Êâ2¥P„Ãk	Ş›ŒÓ†kœ9s°LS"IõêÜ«2O‚¦µ÷lc¸7·İµÎy’"¿	æA0š´~Gé.Œà_íú­¢X9øª½Pü"Æeİæóe;dè;>í [äEla*ya2¢s.à(ˆë3ø3;ãmò1'¹ø§Œ|ª5fHI2õÜŠöÉÅ{Ë…—Ú_Åãz3‡´O"kø&à­³3f›ò<±ÆXp½Ä2ÔŠ@ß4Ğ¾EÛwß¯p£	W¬\>iÜçpL
â¸Xè\¾  ³lcŒK\T9w»¶Ûuƒç_.ºì!²ê(¦ÁÁoûÀ0‘{kó÷G“9¦ù¿ŒÃqÚ£›È³x‰éqD±„4÷¤SQ…w´èÊĞrµOü^ï~[Ğ ²ˆqÏ¢;Æ¶ÖH]ïÖqáñA´ß!DvõºÈ†FÆˆJ³'Â´BXÊ]S”õ
´2!Yö–á—‘©¾’³eSqmç¬}ØFs‡ÀÆî›•Ã™úÇœ,ùøSÿ$@*óõ¿éöÖ4i©lÈU)8y£…8İ/§u™«¦ïÆ®se6Q¸Wà,â}u·¶TƒŸpHë¿XM(¼I5î€tP9G`›| ,E­U|¼ÒÌ½úhÀ"28—B\Î¢~ÚbĞ›|ÉCuÊ[PjNBãÚVºuQaŠw²ªôì¡Qå²LxAØ©•úÆÖÂÀ ®!Iª›‹¢ycw5íÓºUevpóÕÍÈ­:ó×ä.nGAç;w!X ª7Íaj•#SÚÍ

ô©ˆJõM% qÚ¿zİVDÂÿONÒoà?RËxiuVD“ v4¿ù¬Ô¸¯²E=q6ªkŞÊµx•ë,59gæ˜'æßôHq¸®ı3ÔQ©ï‡X8ëÓ;‰ß=g€s; ÆiÑjÂòop4¿
E3nR­D"ôJQÅeg.5ù®¬Š}´v<˜?bQlhÖ‹Ÿ´Çz q/©Ñ ’Ğˆ	g`CIb½MF'Ğ)ğiJ–éBÓ¼ªŒğÀÙ)©ììæz£Kg÷ÂÍ8yç£_İ¼¬|Óù¢İğá­Ì“pÑ‡Säcc>ö„< ¬Æ)EøVóÆŸ&®‡å+B7İ1İt™Ï'9¾ñ’ı¤ˆÖH ¯<H,¾Ì`Ôq=ó½™å°Îÿ%6¬’Šß7ÔË">S„+píëºG#ƒ ¨A&àŠÙ	¥áÿWïĞ¿.ï#˜ğ!QÌwXïÒÔVtÀ å[w‹ÕøU{]u”û{]F{óë’îØEÈa–»‡rˆ3m³S ]ŒCg›²bS*—§gD*_i5WÊL“˜ï$¨Ñ>k*€«›g]ıpÙM÷×G@ySª|ª+¦Ú¥eã+éjLß¶aø¹•Âe¨ú«@${Y Œ	>IC«æhĞí2½ ‡ñûL€J›2¦t!Äß»ù^^ıÈkÌÓ,×ÊÒÿm7oÈÿŒÁx²¤¼¶å<B©ñÉY
â$Tñ %Å$+xoÛÏS^Ñò¦İÕÆût–Ô¸ü¼LµnŞÛ¡+?Lv_·íÀhHğMú{û]šÔšâ`‰E.bÃh÷­@¼ã%F«f#>C™ª$ĞVÀ»: ]Åî˜:Åj¼k®#ÇèOŒÅÔ¬ëƒ|vÚ”VDM~ÜtÅP8´hw¬–ç•²ÇŠ¶ÅŞU† v5˜oŠ·„a\'Qí›¨Iák+†fNì=gÇ´8#(ì_ |9`t'érLì»K êïT‡òxöå&w‚t¢ŸĞbÌã$ÖY´éPå£ô{½m0ï	’Ç*µôd…·í­qÉ69«fyklÓHõ©‰q9fİ&Ëÿ0Î½Vór•³B.) c<›’,gcMuD§ûkîşX¯å¶Ã{:iQÙººÁÈ>Eõ9ğJÑ“zD€Ä4i«…uã£è¨ZäõÈEÑG°ı»ìİÒiy&6O”|~Ü"„rw+ÑUî³EŒ0°t’k›¡fïzh€A„yäy>|YmêD‡f‚•fTİ`ğQŠï›²|ÅLQ‰N¾¯ÓôQÉãÚÖx¨FÀ„>±=C~+Èäí8İñ$ûâƒ¿b‡û:›0;ºOÎ!8¾pbÂDğKùà;·¿‘j-5¬æŸ×!I”¤TzÊ™OlÌ²ı§™‡E“:…ôë’İÁâY|è­Œ\f»ä…Eÿígƒ%KêE¸0¨ÀRnÈAAØ¦4ğÚÍ[ñ”Ğteîbe_o¨f‹	åñ:bø=/no	6D“³G¡È™Y+{Äº*mB ÀÈÀ9ËÄDxÅjjZ8 2æÏPà+
ım–^/ß‚ö¸½¨xŞç>5|;¾‚TÂŸÒÓQç¯«¯z7ùù|(ú è™Á´şiuœÜµ37v:.¹tÏıÇÛìÈD{¡‘š¾§ÊŠ„.?İÑ¹ºÿû%€©¼şil7;	q¢°V• WÙÌÚ.#Z:”ù¨!M(2 ŞZk”oIÑ#}5Üc·è(¢¿™p·ï«eĞ±ğµ>éåA.„xŠÁùVje€¸lÚ2“ÅÇ†VS/CÛD0?ƒC¤ê(©Ê…Lk†c`µG“@§±jÛóœÜğgYŸôµ”n¨)Ce:#o÷‹Hs®+V|9õ5¤1ùAsŒÈš‡®C_J¸ºÖêÍ(hMÓ¦hœÈ¦ï¸~Åü¦	ËßJfõë´¯9(0é‘>¸-–l{‹ÜZ>©Â{¾Z¬Gó	¸ÃsŠMUì/–84óZVh¡7şvH†;áBG5úb"¡4­_˜IŸ@(”±#‰ÇÉLÍÂ˜•ôhmïÚ[Hëùí·)hâíüQ€”v¢¶7xû$¡¶']{Cn4o›ÇÊ™O¯Óşõ­Îùx-ÔÃsíí¥ú¼¡JPdöÒ…“…9#*PßMÒ2¸#|JrÏƒ3ÏÏÂÉ~ÌıÄÈ7›/ãàö`1”¼Å(?Í¯h¯‚æJ¥.†_øğ‘ÌòX“’ìI oE¬ôš·üiØ©Ñò‡65ÿú	ìnX˜Z›dğĞƒæ+ún²"Ğ V5Ijçƒ[İÊ“–	>ˆ87<ãôÑğwå@äØ7¯§ÆàÇB+óŠíg †™µ1Ûeá¥™¾›ÏÎèq(…!¥?ÇÂ<œf ªòy—Ãı19hH;““ëS“ûˆ¨¥ÜRğ×E~Q¹näª V+á4$üHÏÜÈœ0÷`pî§ Qß¡gÒtcÖ&®r´dYIªrÎo]àÜñ@F0P¦rAEyeæT8­-U]˜ûnu|úÄ¢É€ú÷.€&Š¡4$4æØÉ[‰X÷„ıJ‰ƒ™…H»3]TloÜÛ( ÿ3^Òş`•D6ÇkV©)ëñ‡‹Å'&éáYô‰„÷…¼Óèxo¡ãÒƒ…‹ Gç0çˆ´ŞL6şI°âÙc§ğ!Qa	+¯ƒï'xjttæx—æ˜Lú ³Ø¬€³oRˆ¶6Ÿ®Ô³º’8ÌÇu+j†•ª½,Td4;sl‘8€Ã˜,ZÊœ"<ÄéîçÇİ•§wofgş$‘Ã$ §ïSQ`|b²Æ`CÜŞÄœlõ½¶r×?­¬v*‰©:‰¥bV7º{#&`«ÕtzĞ¥\z_à'ï€næßOİ·TÙÓõÉj½†UÏ˜æ—Ë+’JqQ\†¥éKn˜ÉØ)¦qe}ôn’HÔ]6qüÔ&
x©E2ÜI ¢½Sêêv¨E<B•šËƒ´]Ô>]zà–W[Æª…<ÿºäH3ı|âxVÊ;¬šÁZk‰f=çSÍ?oäî`š%C¬Ø‡ÌRë |ÿÁ’ÕÉ5Óüÿ`ãgíÈœ¬Âü¼Æº•!¸n|R|¬!?—(üÌ@ªØöÜ¶™ş/ÂX“[†~m¶rNyÔ³Á‡æÖH­æÀÅ5&‡	²ğØ–\CJ2òiÿõõ	H0›k>ç“ ä€Õ«:º'Ü¦2FCd‰(æ8mî_qà„¤ç/¤M…«äHkÕ»7‚m¯Ëgê¯.Nş“Ç`}Nö]Ñxh|Şİg°Cˆ8U›P_É}¶[<#Û"H½75a·y#öÅo‚<ÍPŠ ï´}*åwEM­áĞîUQßVÅÂ¹1çV4h<Ml¹XĞÒs6`I¥ÈàÅºsÃ”Ææ¥Aº™6g›Ç(º]½ĞN‚:0v©¡¶r‰µyù&<î–¬¾î İ9»# )x‚¶#ğçz’\ö‚ÈïÛdÓ«D)ƒ¥†´ìÔ-Y®ü½&&}ÄØ"Â‡¤°†ÕìÅR‹FşIÍ»t§f­[b£…’âÓ0÷V/AÖšPsI³geôsQ`Û†töC=¦@ÿ„ğœüé<B>u!˜ÜIorDYV†Cñ|«}ôø M0µÖºiİ¯ùˆç³ÂA†r9.¶õ‹£ï\Fu²Eª´ l‘`•EM2-ËgDÏ >IÎ¹´ùa&8]_ÅŒõ_»–Â^MH­9Ï}ï"îøQ[´ıx—8Ö¤“mÂš.‡eô‡:8w)ß“¼=˜CóYcİı(<Íü" %’q#3K4ˆÖø—€»ÈéGF1Sæ£‘ÍŞ\ é!k+`CÛİ×LÛ–…=¬E•Œ{ÀjVÀô»z^-Š@4öñ2›ß‘à£Ç­]ZƒC¢I¦°jwğs5êE
2ö–¯Å²¶—ïvMÆ;oòf†ÒğâyÔËHBôáÌ¹¾¶ñîiéùMğË,èêêCOüÀf£ÅµÙëğç@0ƒÛb:›a¬øVºàşıƒ6´ iÕƒ¶#["¬–ó!§Eq÷©ÏŒaÉ‰ŞUO/ n3`_U¦Ë¶¨ºÍÃuk¬&!¹4/ŒÏâuÄävïh›oÄLRõø~alPˆĞVÁrÜ\Ã[“Y4Î	'…S4˜pô¸‰ÈI
uşCQ”+K›U3Ú¼µöèÔÅÔ*\*¢5Öfö,!˜İÁ†43’4.I¹ğ{™ƒê¡©'ônŒ¯(P{ïBjÒ‰æ"P&ÉNZ’[‡¿‰¡‡˜§df•‘`ñxŞW]ëx§iäâKÇê…Õşi?&oJH²3`n!›äÜynrÿ+¬Ê7@ğÖúZÙûpnE<!»	æ¹{ÓË£E!l9U-¯Ãe*ÿ¬9A‘öˆ_pØ	º;koFL,’‚)cMk%&£dòàÖ×*$aL&ùŠàßıÓVXˆOĞH€´”9e*Ã#¨Ï¦¬ªTS†J£sÕĞÈh…SÇ"4‰6¾¨C@bI^ì9Ôt©ŸçÅE€ÒüKgVØ5òdHÈ_À½°èa¿vÆFâ,½wÄ’Ü¯›g_V˜õ¨³wÚ­=-ëöóuÿDİ°¦‡Ü§	LD‹Ş¤Í°ßïr—;âíL.b!º>­"ıîU+h!%Ö…„L’_9µ .¯¸Œ°×çGøÌiÌ¾rD’Ï¢b[¬ÙºRao^.ojö§Qä·mÑbl½¡N[ç±“&l3Mä
©WñáSÖ~ÜÆäö¸>è.„äe$öºÖæn[_j®ÀÛk í«=§šß¾ÀXúÒ´’åQn©ñÁ¤,_gı_Cm®<©„gjİÍ¡Š—xœMÂnŒÊ6RsØiüW¸¯Ø	lÂï¥ã™T
j/Ü¯¬'ÁbP?)ìÒSnìáìµ2Ù†70)â­»øT¨C¸Xääœ4š¦ìC Ïõ5ÏóÒó{y÷o'¢‘ z-õÍDl}Ø¹ÂÛˆ¯²CnNÏµ’áÅU åèZlÒ„t…œd¯‹­óR.ªİ¾øáıPV—®¿¾ı„Ö‡ªz÷²¾¾TS ‰•ıVX°ÉJUÀ¢'WH¶=Œã¯ëwEÁ'`ˆï•›=.‰ïG?tH.gF¤mÉ¬ÇÒå,¯—¸	Ÿ~éÎœô½È3V|	"ïÆó´s2'1bÀJÔé<C63	zĞÄÕjt0˜T[„YŞ3x¿ËoS5ÆŸ^Â›L¯ëé¢ã9ãÈ÷sìÀH)¶ÂIÈ¶ë5`‚w¤ù8'¬¡ëH°±*™0ø!£w»ØwWVk?ı÷9,`¨Ü´Ïwo–Ò#Áöæô‚cªR·€“Ìt©Ó"ÒkÙ´»e{¯¾	9b]4ˆ­2çp'œhCXÀã!yøS­¥=G¿ZÆB÷šıZº¬Scí.ÆdmŸÈ)¯ÛÇ*ÄZ[ŸÚ49³Ìp1^û8£goœÿşÉÛØÛ$…Â¬c˜nı)hû]vh³Ïk›õ½DìÄ’nX@­Äé‘ˆŒıù-W?AëGÚÔÆ9/-×âéã™ns}zi‚:d„Øí×S¯¾~E[Â¤G®ßB¸`ÓM~¸8p£[bÙWvFÆøNñ0+šûg!JéÔ±¿-_:…^WZyDnŸõœå°üÄEÛæ 7À€¾°Q…LÎ[¾ŞClß£$È/™9×÷?CvÂÒásè~\¤¢Ä•»o ì»ÃzÅÅ/¥Š,4·§afp¬›Y+vÙ£o\¥DVÄOæ9i.6¨ç(2Z"ğì&»©U—b"å»Õc·&bnù-òû4	Òö$‰`ñ~˜ìA¶QY=ıâ·9Àq¹o|¥RàÙ5Áš´"¾L5WË[Dê0Ô_ÖíŞ¨‚©™êİ¾5a¡=^˜F{¬JƒÎ#h´1-dŸná“|Ähq¨±*ä»|c¿^ŒcP`û^İ~ê7H£‚•Y®o
2ƒâöÖH¶Á*ÿP»LHK9ùZ
°nöµY—sJP^‚–…XEïcÅ”ºq“óóÇ,jY¦ü+_‹—oı‡Õ‚Sƒ8­!°ÈD[KÎöÛ­ÑUÑ{II"İÂPñ†¹œÇÖ&S(k!xYLy…\%B0–…ñ×@v7$sMô©éó¢«AY((ºlÌBÏibosôĞèÀ)Ôvßİùò¼½rŒòšÂ#Ô]ûh~‹YäÆ¶„jŞ|‰©Dô‡ªùE?k§‹ëå»È®í$ó…°24ÁFg"j§¸{æU"’6GgÊĞâç «Œ­™Èo}·«[™D=Ú\\™ÍT‹ÄrR"d)O’B, #Æµ7zü`°>ë?{Û©ÜE   ÓÕôVÕá¨ ß¯€ğJv±Ägû    YZ