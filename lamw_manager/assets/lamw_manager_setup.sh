#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3338484441"
MD5="26fcb6b9df5c57dd00240683a3b0ac70"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23524"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Sun Aug 15 21:27:36 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[¤] ¼}•À1Dd]‡Á›PætİDõñ9İHb´Rê¸ı¸şRĞXæğ%¾à#Ay–«
µ˜‹ÂŒ¶zS¬7ó :L|àM)*Ì;=OñLíàë¡üçKâ0[¸I£ªƒç‰Ê¾¾xó÷‘qÿ4÷™Ú×;úœÉåõZ4ŞF¾E« ‡±MK¤õfdÆºO:W \k=c)6¡J…tdC=7P¤~£ªb÷"5âÈmti¨bEÁÔÆ]ù¹çÆ³ åÏ¬ ï	¶Œ¯G)á¦7äEéÂ
+'€7½“L\œ¸½	=%:bOŠ]¾èP×º7S›M‹û¾Thå*Ï;TÇéyº“&/î´áî|dnÑçiÚæISë¬9‰Á—·B^!CĞ«÷@Ùéhõ.•7¹çtÉ—&9'óEäÚ(}‚	1ô2åÒúĞ\ò/â`ô7@hHTÕÛó¢ºİ7´Ã‰Ÿ?O<|`^".òFG|ˆZ€t“ÄK¿	”E&…U¢˜_ ÙU
FÔ¯2v²„ÿø}’w†½qÓˆM±0~è%3BÀWëh«İÃ7.Të×†Ü‹l‡3‚bn‚ƒA¡«åÑä &¤ö¨óP‹öğèŞb5Ä¥6R5_4z­«½«rŞ›@J;`Â3Q˜¹ºd× ùíR•Z² ääe,ú_EÑ*V-*éÏˆ,&8LŒaUÌšoŒmj‚æª›5ä–)fÚ-Mû%#lG×‰üú´Ê\W9W@ÒMSv1ØW·h£É°o³HÙ¦—„cQİÈX­®˜œ¨ğAhMu1%z<ˆTïùRëœ®ìÁê¾]/K»±ı)}¤~ÉB§açv¼Øy»h€ğVŸX›~Íd@Ëx¨c€Z•Ø¸bY5ä°´el>>—™-“ÊÖMp D3rä	/j&È¤¶Dæ›³ãà‘äO˜Ú¢ú³?[ø¡-Wn˜–Ä/gÒ«I©1l'8%Üó1.şÜ3 ‡¥èğíöÕ«†Ñ¸eZR¤ ¬³{ÀŞ¶nbsùíLÀ²Fc”3Ì¬6,ûåÚW6,{H,HØ•¨;¬lÈ8F	íÒ«‘²… äØz°¼8îèÊU‚SYï­]±¨WèÍKÌ¡ fÒ(ÔW\cöu!{À;Ì3àjÍÈ€+¹'9‚§æ˜§Í¹İ>”${¬Ú1ƒÔ1ùÂ¯°_ï«¿5ô’Š°Xk¯O
Ë²uÂF˜8¡2…}¶(V
/e"'Å«@Z%âà^iîœÒ8BêÄõ>Ví½EH’ş'°dÎ?ÃmA6oVdî8ïØY×§'”L½´µW±ùéjßÿ‘y'å [CœüG`Øaöø$|¼ia'ùzM¾HÌ›Iìº…÷{k{ŠrÒ€1·Ë•Í Êqıt¤ŞÌZŠ­r1G 0*I†|L¹ÿh¾Ú"=n¯D×Rw®A‘ô ÿør;LElz:s¹RõŸ€¢É,wøn¶Csöº22G,w¾¹L|´te,2_ıƒaëşuc ¯(ı^4’R{Ø]Ğ÷Ò>EÎjFu	Wñîu‰ë§Á®Úik'y‹»¼ƒa'O~D-"ÿR8mÌİ
FRŒ7srrkøµPöuÄÃ¨6mÓVÒòı*
¶ºä<ÎXğ0QHağ áêé”{ˆ3\³¨"v B¯‡ÓúÅğW¤_<'Ğ‡I\ï2•ĞS(T@|àg¾;ÆÒCÃÛ]±Á‘Ê˜Âß'JJZúæÃôğEd·B#–ñxgõğïÉOkkfUoŞÕÂá»œUp¸œp£%R¶»AÈT­ÒÎ‚Œ¶hîNëgô'÷ûtÚ¥{’‹íõÖu„¦§@tÖ+ûüyl÷#æàe³-;èuJmÓMl€?¸¿^”ú”É|-]5hÄÆòªœ ÿ_xkŒ=àgÇº¼4>rÓ€Q¡-jK37)íaW ¡¥“	`îøm&QŞIñ
_:¨Ùm’¦2ÄÅU;É(ôT†ı>ûY1Şû+şN ¢lÃm¿2‰2úÏ§™1Úcg'¾eêpC¶£o‘/,Èîº&äéÇ8rÅq«Ÿ‡ĞŞ„ky‹ıD§ÆÑÍ‹$ÚRóèA¹tùhã®gê‹
##N¢İAÍRutqlLeé§ë@Ğ½
åñ@¸Æ‘FS°İAštqûw×(¾£Á.}aTåÓ1ÏvÒÈw¡ÇÉûóQ:¿µ£ƒŸ‹ÃÀ=ìù ÏûÕşB‘Ğ—Ïd<<%&®ôJ~IÊ*½ğÀ0ağ@KNx¤a°«ŞR3µd±ÖŞi4Hdv@Sq æSˆªn&‰ºõèMEˆàwôğ}8 -rœ0<Y‹I![\>-êƒ­¦‚¡k–`"‘z KîÃ 
ın|9Ö–U©$êªY6$~g»FÁ1!°A+3ÅÏÑ”FÃ4oÈKEÂóAğ8+kœíö”%›Ÿ×£€1•!	=°	$ìÄ‹É8,&xÇ¼Hq¿ÿÅ˜L€‚7’?²
Àè)›%«‡°éª‡Gàèü Œg`êÉöÓŠ¯Á†¿]–åÆg)¹"(hÆŸƒÏ‰|hcƒC“o9ãğ)nÁ™€ØoÒÚR—#iÓêx;šùãJQ™ ^'ñtØ»Q‹Îìš2}óFtQ×çtì3QéQÕNÎ˜©O_]AŒJuB©âlæp×ı('Äã-+†
0H±şª1½¸Ço•¾3ÛO×TÏ{Àåÿ]òg·œ}uky´¾)b0
òÅ)£/Ë¹|„@5Muå¸¢ì…t	Oş»<›{1¡(°àTóÿ±å7¢K˜/é¹EÀÙˆæDH$·q÷|âzÃ¢ße£wÂ¼Ğè›4ÀÎ-n1Â-…*õDh_øL.>ı.=£CÊºë7Û—hºÔş<glÛl«Tvz…ÿg_Ş›]\¸˜ÇÉÏ×Ø»7â:‰\A<?ÍW­\ù„á^DÊ­ß¯1Ç@­¨gÀ[Ì(åÁàÀG¶GùÍ*†×8ˆ(GO§VÁ@Q“Àï…ŞôÙÂê1ìZW¼~4£›SËÖÄ8ÖHëE¯×ˆœºŒÅûÚğ`Şö’%3ĞşA\“/Dg>;rCYi€É9T¢yY’îÉ,ìç§J×7/D/ûáÙM‰´ì5xèaû‘™0°˜%³¢Iœìşím¸ˆ´¢ı1éc`Ÿ+CíàŒÖ_„×AHQÀ­ "æä„&QFN\…¥pIîquDÚ\ë<<öc©ä-*%{!^¬9åq®¡Ğ;
I€mSİ¬ı•ş³ˆÜ˜Mç× º³Ç2ÿ~Š÷E¶a%8²KU ¾øpÑuY;@½¦õBæ‹k©1w¡ªĞ‰ƒ/* C” XD’#¶Óß›:ŠÈ˜JÊ¢
ÄK¹
‰rZôÈğª¶¡ªcë®i3¬}ª''bMÖËÔgŒY3@º0œ¶dU©HDÓ(œ£é`¡å	%£#±RÈ¯n4éå8Ï¶°²_rÙF¬]<tìÃ¸e´·nP‰¥]›Õæu+ş@f79'¿=V5öP•Ìıˆ2—«Ç†š	Ò“hûïÓÔŞC¯)rï}÷ö*ÎaQÛájMŠ¶“´®ç`Á,ÁæáúÕ[Ä¤ˆ°d•3¤-jÅÇ>ŞÈĞâÉë&åE¡\ï]JŠqìY÷Pvk½GÛ¸	¢ Ü`òşhs&ØM}Ia^`&>ß»×\:´ì¯ªqHÂ[á*FHZ„¯2oà€ªò_gc ;bµõt+iw+ì-áB|k§á³„íA'¿Ï8/fM•°ã«sñù	Ğ³QQâFB5º_âv]T=üfêÓn!Èg!“Áeçq™èSú&­ór2&_áz0Ÿ³E«ÙŒX		5É‰ií«˜h¤ò½ZQ½!´iU1`‡Õë'oœÒşV´¶Q+Hùyt‘/Õ‚‘Üñ#EâÇÇ;|Æ ""öøN@qnfGÑ’lï>06Oı\AÌKÑgLÛÍ…şÚğZ-û.ãÊœl§C5€í óøˆÃ[†7ö‘^©™€Q¿ñq£ØƒÖ¼ƒp((7¯96§ôx¹š¢$¸ëEo%eaêXĞäH@û!Zùdcé{pk‹İ­Ù×¯òÀ~á 9›SİÃeì ÖöÉ€ë÷çÒ!‚3{Æÿ#–Œçf5é8dS	§I]Ï­úÑÔävÑ'Î¸Á)8_f_¨1ö4Æ06VºTÖò#µ‹P¯ï¨`Â[ïuAO4Ù‘ˆ²„Ä e˜™yWI–dè&’#¿¸Ÿ€øÔ \z!­ ¯ÆêS©yj¯§ãÕ«~ÈÕyŒÓö´\ÆÙ,ŠÜÀâÇZ7$m•§×¯/æé…3{îŸ
 T`­¶½r-›©ú’‹ÕŠgZ-¶S	shùêÚê² j£N«uÌe'ÓÓ<“‰Oüƒ2”ÿÑô§—˜ZÛ€¯9Çmk…ªF4uwIÔÆíè,~¦V´ì|—Á8ÀØÙçcôèTßõ}ù=›ÏcÉz[2úp*‰)B1£NBŸ3v
’¸;ó70ß›«iÒPŸ˜åÉêã$…Õ ÅÂQ h+[èr—Ã%Ï£‡ø´«Õ1:×Šn¶E-úniüö†K©N¢IEà~¨F‰ƒ¢-âZCYE)›³yZyC¢NNæ 5CmJ<ÿïÆ®ÿ×ß×±’rënXù¹©…Ì¶ú§CÃWÀ«ÂO‡«xõ&?Ùw€LÊ)+VšÄK#ÂÔh1«C­şa¢ª £TLfôP@®`…1Jµn*2„+ñŠÓÔbÍM«Ë1âm<Åç£˜×Ì¸{ ãzÆUcpäï¡¹NÖ}šö*šEv¹óu…ÌıucN‹•œêcW‹v”rxÓ°ƒÀäš…ÿü+.öæ 0›öz†9P9­³ğ=Û®²İuókñÊYNVí†tÁğ¯¹ÑGêÅé¹PÏi_Õ¡WÒNrß›{NDlzÑ :†ã4Ø_8ÑæâÃÖ¶0¤4Xá
1ùn^¹t4à©-"6O½%1Ën¹ØtÎéùRÚÍÙÚ©Rfå]m¢ÚÕl9Ú¨ä' Ø‚¥Ç¨¡”ŒŞİÚúrì»6×ñ¥”º	?·9ÀöTĞÎW²Ã¥ãLŠPñÙE¬‹%ÿÿî‘˜†Ê¢ÈàKvÑÛ%¯¡{±P¢¡Úê¿XÑ5.\ …Àn1P
·«ˆ.ÕrÖkDú})®†šH Öd‰é§›8rãuê=®ãÊslz³™Ÿ6¦Ê
Óe#Éú¨›(_3ÃŸ^æUNT ZCãÑè®“•ömÂG/ô¬ÍïjDlAOÉªĞc—[7DwxÌ¬½NÈWÑt*×²TSi†eO„ûÏBj õAµ«ªu6ÃgT-Ixç@è9IÒ&^Ê•­A
uâ›ru%…	–úıÕÿoïĞ'SYµîËáñVÑ‹Û¤RÜ¹Lşy¥Šš`×¬@ÑËÖê¶é¡p{º//øƒ6š¼q>òáĞQ-g‚SbêiÈ†«yÖ9›Š7é¶˜*¯¼gI;Èó°è}ğLŠÕıäŸK/$	éÁëÖIÀ8{Å=kÍ<ØG®§°‰H"WT\!éØ›ı2Y‚c¢µ·¹Vìz%aÆÛÖÇõ¬¬„ãí)¨SÅğOÅ®T-¤ÚYSY.Œ%ùác)B]÷å°}•Êe†ËÜBA„<Á^Ğ,È[R‚úì‘–Ö[â|-—û­ªÕñmªº×kªäÒƒ:H×ŠŠUøÖQ·±¼K§n‘¦S´kbimf1"ó”ûÿ(ò¨_œ‘İÌn‘è[×ÿùäTÙ$õ¦.i®Éhë4Tyã™¹rŠ·âÄ¼oH/ÅÉ{#ãlHû	Î~ñÇC¼f¡	Hf´ Áš+pj¹I¼QF÷:ùĞL’ÇÏp_§ê< ¥şã}U­h¨NUÔÕk?Œ´^Àá!Ájf@<ş	¢Aø$[nç!.ıÎúyÌ{ '{Û§[W»ÿÚPª³ª_Tñuøºïà5ìÛëÕ#i%QùµZTùø€ìµ¦‹2Şj7`¤-W±l¡Y+(¢‰c!d‘˜­u×;}&¹ß¡™@­Ámº1Kå7:Lq£®’,ö“nó¶ˆõrø½x:ñî¤BˆH˜%Ÿ!ÂX½¡gp±!
Hê=™õ;ÿCFéßí?‹æ/â{ì5_ƒXÛhÈ-TQ³È9çP`D(â€èĞ‡Fy¢  (	ügÆ&¿İ«ì]êQÏÖï‘¿.=/ À©³X…ºC5½¹m˜¢¶	R’,ƒExî,1#_BÏEÿ’Ò9xs^8:pE£—ñA,µ¦Qµéú®ÑÕ©RŠ …KŒK>¿Îz…ÿ×ƒ_aømÎO¢Cï,N¹˜ñN>nï¸B·&-ÙûñQõ×
àe]>ÆG—‚Ú›fS×äªÄEqU§|¢Xò’ºú!S°Ô‡òğ0ˆRQ-¼d¹øU6óÜdá¤lq4Y› yÛ˜ŸÏcªÇV"jÕ ÏvÇìt>½{êN];h!‹YùPdª|	'–€m¡óÚ~–ñg·d³­öÏ¥¡_™xuÁ	ùÇÃŸœ¾}ì¨å×Ãx"hø„¡+äD4'¸Ğ;ûĞÿÅÚWaºpÁ„÷ñØÏLjqIˆª²WKúQ4%|Êòæè¹›šH…ÍIÃê%m¸ı§ıîÕæÛ:ÂÏÃH%Ä<~¬!<ª·aåbCƒrÈ¡@Öà~¸Üë¡äÍuD£;µ5]Â;qº`-r{e89Ä‡Éê¯¿³Òá=¢õÚûa{RúÄ¦¦×ÛLÖŠ¼¤8ÖÖ®—Hõı2/Y´fnìì‘ŒöaL~´ßp•º<‰Ğ­øÿà
L5gær3EP‡mÊkˆ3³êl¾Sáfm™`(s“kP
´5æÀ»ñ’BáTh‘ê8•^l*ÕÑæš›zuw³‡¶&µ½˜’Ù­•ø¬tÛgÔø—éı0.ù-ZûËÖ´±Û)ŠÚ²ë­Ö”ái~¸5JpÉkn $›ÓaK>ßÒ„_×Ü…,-v|Q
Ò`(Ï&Å§F\ç›2b%¬§¨áx®£Õëvß…ğ44÷‹Mn=™=Şâ©r½•õØ=˜Óğ„Ú×¡¥xñãväCL•œÚY}şx‰ÊÛu“/p{Oi´w]è=L!ğ¼ ıK_¹hÉ­0q;‘@§í=fyNjô¥‰£åzÙ©ÊµÌRà%4Ûx÷ş©Úîë8Ü‡êVÊÉ†W¿§ÌAßD<’;Ãl‡ÀÅâUEV/ŸO5¾$t‹V©0!*f5Ëôš§ïx2å/†E¤ß#"¶ÁUhÍ_%¢I‡çcÓÀ%ÔÙG¿ié˜9ö;Ï/şD¾ÆmM*‘îªÃÌ‚ùµ“"µxŠJ˜CÔ²o‡RŒônµúšn²¯Oã<Ëv¬*
Ù+õ{O“õSLúaÁ»½ æ¾–Ò©®8˜Oä)æ…á£^ÉŸBª%
¡”¸£Ú“íîÌŠ$_ô^çÂ¥F«V¸_MNş/XÍúØ¤R×¡ñ[¹=Û`))´©Xj\ Ô"JT¢Op$iúÚüOÑh´®2Ú-d—œ|wx=]!|Ô§¬—Gx™ıÿ*Í¥:£œè?ŞùD‘Ééxç·í~¥àû@º
¿Ñ&‰§àJÛ‰0ü`Iø:#í£<îàÖÊ®°ÅG2¡yå¨¸õú¤Ù5÷ÛYÆ#Ñ÷Èß©ğÏ	R^t~±’ªß]6–»¹Ô
tœ.Õ|¬UÓèÓx	ãigi¥^0Õ8gºGµŞI!·æÈÑƒRz*~†«â„b·ojİW¦õå!¢ÒXN¥±€š –NBÖ¹êKyMˆ4Áëúaækäø{ı·®sCu‰x©¼0ĞµˆYÃƒ?Wò_4[‰ààµÛø¬væõÈÒÃS{±<îd˜bÁ©İ1¶¯­¥E`†„`@İE”HÑ…#Ét@œÒóß²…¨ óò¶š‘*ºÆ¼@Å
ªX!\¤²±•Ñg¿3[1Ÿ-W»ë!gtGÍ„ÙÎõXxÖd‚\Zğ!©å’",¨KôïÁ(q*Œf‚„Ññ2Ô‘Ü~íËS6[d\=)Ÿ£ß@ã°½ßÛyÿÑÍrE, Ù¨cÑ@*«}?ëİó5´”2 ‘ê¦X4^õqİİFX—=:œu]f6à†evíÛÈ²²Ê9#š¦=r»³#âqµò®ë<Ói^e²$Õ3–sM¢t—ò‹ÛÀÁAE‘9ØVoßû¼[Ëÿ|}&J—oI‚!ã[*¨o¡NÏlÄ~0¯:t¹ü{+*ş6f(áƒå`4—‚øán\GÚlÑôøA¯ÉÏìÃºagcMá“7wù€—50¾GÀ½zYÊÑ0ÇzX$e7«RâyÔçÔujµñß¬˜:}32´Ag¼˜İh5â*¦²î:‹iÊ6Şè©)³{ˆm ì`?ïTeÑù=cÃ1ß<–ÂH¡)Ôæ*óîÒ4gnº¶´¼ácÉ:Ì/-Ñ±(B_BØ06OŞAœêÍtf>–±ñÁ,°÷« ‹®…A Æ#â‰ê5“˜o_­{{2ê; E·Yï”Á0]S·^®d-Ç€8µáøòJúáS`7@\C²l*ñu(ç±‰ƒÂ/«	¨?ès=6|ØµŞÌá.0¤kÌğXŸç7U¸úæf}¿yÔM?QJ²vË@a]c”®3Zâc5vÚÊÈ—3º7†W²_ç&¿6ÌL‰OÖ|?¨Ğ€ Øş©’Å+‹ÀÓ}ĞÉãeî±İmÈ÷a‘8‹êÇÛ±J×ŞaB¿®œš~¬é€´—Ã^ÓGfñJ0úöÚ¤×%„ì[vT.L$hdï¿$Ù’¾B×©}P@®Ã>±á:<íµWîğ¡¢vb^:ŞjÚó÷I[®Ëväü‘íÜê¡^Ê½ªéÏç¯ãÓÙù®NZ™,ş'?ê´ß=/ãğ³†_VP-àM>òÊÑ<Šñ”÷ko§
ıÂ7ÿòzfìvï-Ô¦ÄÚDI6i€úO¤R[˜=•„¬½	Ø*ùæ¹òØaäÇ¥÷Ò{×ı·hvÿDnÏß¤é”¯÷>_ˆtDmK–Ff‹b	$`F&Ò\+«t+×V\?u—ÿˆõ‘@nCmÓ‡å#“t!vò/@Ğv­s_^É¯Gt“‹©d]Ä²û¨
Ò¸IoLg¨ûœ%\•K5“…¹X”§¥¡±±úkëóŠQñı‰mD™u&ˆ|/Ä^(urø¾i¦°;°‹&#ŒÒj3—ˆÏ¤òÓ•õwÌ¯ú(|0-„²ÃÜO Wø0Ë0ø2UÖî6¦¹[Òa½O®u?ÈYOÈœ¨4a›é¿Š÷ëùvH‘»ìó=Ú3´•Sšö¨ùBzU €ğ)VËS*]ñÔnæ—W4·r¬‡‘ o*ŠT¢TAt€h"ş¼ª±vg™	¯ô5˜˜¤ÖË+]F¾ŠSĞÅ5øÛÎ–i‰Ëh½Ã˜©–9ª}¨ š¤ôÔxó÷.Û@6m¦½H¢,í ´ï¶ìuwğ†Z=€Ø	üöi‡¸}¾X­İ{üò}(9dDDíñ	ÍY¥áª‹ÂA°Ús˜ZÕŒ¸*³‚wFAW¡ÜÆğÔƒz‡~dåD>Èç9˜R×¾1;Uµ›+9ÇŞ˜¬LIe\*o~¾¯	|ÜVağÃ*7ÄÆœåÔ:ò¾†H]Nuái|~ñÕ;©ïw\Lw‚¬ a°Éå>œéñû£„ƒ2ÅÚu}Íßzì#C™+1RŒæTÍñÿ'£»Rn?„O¡ç nØ“—2FÂ\ƒÖç}Çyïßà‡®ÁñÚMÕìE±ÏFº!
zø“#— 8•FÍäïwŠt~
ç6®¿Ó—´fv”Jï"	P°ìÀ§Ñò ¡Ã%šW]ó"RÂ«³T²|hpK¦/)z•fÖÔ„7ı¥§0+X¼=ùo2A .EO•gc8½v¸I ;‹#@èÚ·|gÜİĞ¦o…C(Ù…ı]Ø#!S]†.´"¿¦$‰EVWäëS2¼šSkJƒm1O”‘gÆÉåˆW-ÎEjÒÈxÌ«Ù€¤ ‹0Òa?DÃø7ËtûÀÃåtÙ´ë ÑKÃê«bÎŞ¤*¸#øi'¹</Vú#ah‡÷AÜ˜ &5fãËtwØ÷>Õ1Ã+€1Ty§-Œ#ZGfVB³$#Ì>p}ï|òØ5m;RI$ÓA4é«DbÅòˆüÅ·&Qà¡™.q¡·Êl9Ö½x¸0v»ğ#"°œÁ{Ô7 !óœ,@ÌÔ“¯jM­±6<˜Kp§¾œ)½{ÚPëÙÃ·Ğ .ïê>oÇóâ¨áNçS¤sòúG”£½ç’6QÔ&-ØÜ£€¶üjé¾Q¥ª;™)îëç	DÜÎcì—Ñøñø@ÓpXò*yxnÁáô[ÆñÙÀKéÁ¸ĞKåU“` º›‰NAMáô§âòG+ÍâÊ5O½Ø»¿Üµj¾œ0Î‘(;²~‹Û°30D~¦ôHO‰×Û*Ti˜„Ë`{Ò€±Jñœšm™8…Ç|Igd³~|l¹Ö[_ 8¡ŞBºç³¢ˆc²z:å}sÁH²^Ô	8­d$_dqáÚxn¨+¶·“·œAıSÄIkÅ,4LÔ®Xi5|ı|n3ObŠ×ö¢Óš>›ï Ë¦ó$ŸZY¿ÍrÊ‰l01š¤»µ¼î½§ì8[X8æŸÔ¦¡±l:t³º\Rãõ¤ÃcíÅøàûÆ>€‹èHEéş6ë~åœ0ù­¦§ÒÁÇêÒÍÕoòºY× ¤û{¦ÚãŒD@—…ì*A[&{·|NéL&	pá†yïãŞ¥RÁùb0€÷\‹Ÿ Uí~¯ãş	§Šc?;åÜY¢(Ÿ>ĞÍ±)e·':R\×Ï­ø$·-“QÄ_¸åı§3Úïˆ$¥”š·ìGİ*¡Ù m @á_ 7bÎÊ£O±.4NBöô½³B?ú1duùA»*ôZü¸‹;ÿhÇóÔS$›İèÙÖ½ï¬éÏ\càËÄÃAmg…şçw(ÚH×ŸeÚíé#uD¸j±İİØºº4ÛdA÷‘’9»—9[G*-ë‡¢aEøBj‚ÊÈËaJ`6Á
ĞMáå2l€Û¿
yéÏEñ³š3½èI¶f¼ˆe¤s8'»%µŒ_è­z¼ñÿ×RÆXŠÏŸJ‹±ÿ<U÷½SB¡
×ñh´ócÚš7Óƒ ‚zÒ[p”“zM³Ø’›…W&‹†®—ƒPÎæÒf¯yd£\´ë‰®&ª·´gêíİê:n½õ !~›hşQ~ĞŠ£ıS¯õÂFšb"€NÆ<q_>ø1ôò¼åelÈyÍ‘“uŸÀ¢ÃñgõGxßĞş°—yòŒ“Ğ=â´é„Û×)	)„†Î¿ju±ñ~úÓŠA×}%‚dTûHAqŸ}ï1ªPzgbuS²"º›kúÈ¨4ş¯YøCÌ¤á#×:ãKÏS½z:”ŞCV^e¿µ¥˜6 ëHä·Ÿ€h·áœ?˜V½ßLàpl›	Ÿ%Şö?4%„yˆ'rdÅo=m:¡oQ£TÆ‚OúBõÂÏ¸»”p(a	µCbj¢„”PRÁ«¹]V!È9]ùÏşOEËlË*0ŒS/ãB~‡@ĞfPO¥ï{«ëÅ„—½
…*,†ü–ŒšË††Ö|Ír¦Œ…$7 Í2PC¸PËlKpz 3¢ı…ó¦ÓI^ÂAŞW¡‡Ÿ–¿zKòV£Á	Åî»ÑÚµÎkV¢§O„‰3¦g¤²$p ¨ìÅğ…ê·¢›ä”y0étÔ2¯kóX8Šµ¤ß¢¸İ±#ıä‡„Ù¹'ÖU¬ãÎG‰ºFòĞë&UH"Ñ>sÓhFÁÂAI>N©Ö~àÎÍáçéFO{="ı'9+?$?j¥Ñ$T§½V•XÙãhğz¡Ì[l–‹hR– ÇA“gÀZ©ëÂYs£ğ®œ›;‡(ˆÚš3…6wÍÇiÓkàÂ)¸Ì¶o˜1”ùlÖùÍÑºyCîŞ¼¹Û,?iæ¿p§¸«4‰ycÌ?
  
˜ìN)­³<íšéĞÜìâëyiñ¶Çµ&6"xe9J¤nä/'œğ~`Ba±J¼yCŸÛ¯íŒGÄ“t
šÇé•”ÿşùÒ²x1=l¦©û"ÊnGÕdãx—âãDåÁx^†["´Èı)ßøsí“D‹gjÁíB¯GMÍ—Á‚]ŠBÂİ/ìZúòÜ^|Zq3Ì8€YŠCÁ|¨h6Şê#äKÎ©÷]ÿÅc8â„ëZJK=Ç%I÷é¡¦{¸Á;\€,Í ë%íï†[q$µÿr1àÑl´EÆ\59ğ'¢ƒ°óXJÖÇÚ½V[bÕ€<(L¾øIexj¯ã8F=cBsr8‚Ãd’JJ;ô©Ã3x¿²D¯ÍæxÉ'
_hùíN*•Á¹K~R¤:ÖXñ§`”íG¸KZ¥.½h`«MøÖË»´F\üîŒÚ½†ì¬w©ø>LÀ0ôM(”5Yû„u¼2¸ÕDËû<Š(JRĞ’KæíCÂ	ÈK+pkë…€oJzkº7©çĞ‡H!r(D¹ïÎ‹ÿŞ±8Çÿ-[¿@q¹ÉOüÜj½İ™Œ÷V¢5ô˜1wÇº£gí!V‡óRóğdX{cõ™ÉëÑHÍıs’¥_¾ìüôüÁ)[ëëp´´Ô•SÜ„N­ò±w¨{-ê^-Î¶\†TÂ,…ÏØ‚#S»ñ©PÑ•¦0?ÇË¸±Yiî’Â­²ÜZ³ëø&ë{‘OzæeïmQ5qŞÉ‹!4œˆ£1¯äp/Ó‘VbNÖ@.'Év‡ÅY¬ÍÛp*	ÂP7åÊ7Œ°˜Æ“ÕÍ`8ãuİ´:'†^Œ&€Á†>$|, Ş?ò<z8<ğå4Ëº4:Ä–v@é®¼nds2ùÓ&GDzqÎrÇñü­¯­äœCIë5_[ L(	ŠÆS±ìPÃ¤ç¦óËÀ®øT^äVŸ‚æEmÀŸ»mSÛ_¢š‰)ˆÓcÂ±ÜS´z,—§…°·M'‚ë8–˜GIVÎ~¹D-àšq9?>[º “Ø“1ù³ëwİt¢Ód*çeGæ½ÑkÒkpH(I›Z cæ#d^W+èÒ}0Üãúúií¢H÷Ô,šåØ(Ì–wU¯ëÎc7©®°Ôa¤£>e]m,-z²ÆÖl¡fë…{ııñªC M™p¹®U3?‰Ê©—¿Ã4‹Å>_)Pw)(f_ìÇÆ»!nåÂ¨©…cáö}Ğá–ÔÆrBx«ëlzÏ’ŒÍá¹_ÛEYSš‚{@!•mÛ`&N} CĞ¤O	:R*Ô‘¼ŞUğYÇ™OyŒ Ã°ßÕ®Ò «@ugK­]‡Ìı0¨NtÄœü;B/»åÀí¤×
0„ê~XŸ9ìû8š­é…éb|Ñc ‚H}·ÍÜ}	Ğ‡ò¢®FjN¿`¶ù¦D|¿ìv_½)åd±ÑDšÌ>ç­l®VÕö[°Nƒ±ÖÚeT*Ñ¼×Mê’Gè-‰•:rÒóî?G¨ğw„‚„–Û†ğ™-ğõ€áÓ—'³4k’¥nÎë-dÄ®ÈáH#2×Xï÷ÂÄé\2–æ+UUWÏ0³q3ÎßÅÏ#9†Dæ”²OY9õ{
—÷YWbrr'jO>cóu
 .=<”bŞ@Î¿du ¸v2Ú™Tâ¾PoÔßV3ÖnZ2‚"•—‰îÜøõQáeAìû©¼²|Ğ˜Û¼m=ı’bëı¯*cÉgßoàŸâ2qˆĞ­CøVá	!f+1ÓïD°UŠÆş¨yŸ“É[i¬ï°8ãè ¬"İVº®uÂ\Ë{sû—ÄèCD«áá‚Y<OçÄÁ
 ÊŒA>q9eÕ$û·M­ÿó¯÷ØN(ÁWâªGğiö@CWÈdïAşdD×ÎæFOr®²<±g&0]àß^¨b2Ü4óD±·£FkĞÿFF9p‹opÕW+Õ#V™„œ)²ÆHçó'O£PÒ‹ËŒ¥¸±Çûu$tGm6·DşãCLãLyà,7 wÅç™Âç/[8ÍT%EYdµıdx^v¢i'IÉ¾­¸y3éâ¿jKÅ³¶Ãæxµ>ŒMÏ>Ş£=¢„ké×54âJN·_#µqÛ`Æ=¢¡Š“‡0}ÇÓ¹\É§:¥‚şP@‰‘Huï"1şEîApõã”	à­è´UÿÆˆU9÷­&ôŠÅ8~ÆıN][›ŒÆ0êğ?s}Š†z8äş_M×Àâ¥’LúÛı`|©Ù½{‘(şò¬m—{Ûô¬}M¹¤¶2e/°U+HÊH»FO‡ã^¢xy¹_õµr‡Ù¦"ğ¦í…T›[ŒŒ4‘wpR¾£.¸Áï‰ğg’±Ëâr€„ñ±6]¸»(oßm4İö­¥ Â·AJœó†Òè5èn?†Ë"Æ*Ó-5Ì¹Ò²è¿iŸ-jz¨8WqZF€3kœpIÆCR´ĞŠÃ4f¦/6/F¥fc}=İWRÈYÈl/®–wG‰¸m^GõbG=Àk²‡û~üaùåéÊ2‘”a\çÚp¯ÔÀ7²UÊşû©ëÌÏ&€Ğ¥Òy{²JïŒÈ}Ç D DÄç˜‹Àx{œ¶èù ùÚ@³_ G6bòÎíŠŠİM¿Ø]*ç•ÙNRï¬Ù­öÜ
*O‚£1µcúAxºu$Û9øê´
§…ŸéVJ^˜ Ï‘-ûè•X"Û³£µ¾ÛT€ãm]ÂÒÉù™çB4¯}{çyy!ÔÒ¡s­fåÇ²Ídİ0Ÿ£*,ÔPk­wŠiÍ2Ë(uO^Ûw	›YØÕªì«°É˜hED¼¦<¡jôÖÍ>ó¬íÎq5a

Hj—?O% ×ÃØ½
=;X‰¸E"Ï0‘• Aè {Ò¡Œ<Ù³’Œ¾Xv·Î7l5"Ò?Õ:Øúø:¨ŞÉr™Ã¸0Ãú½ú=âäIÃG‹G>(–È§b‘%sş†àl“V	0Rôœ{âòÀ¥_¹9r®@¨Oã/(œÅ1gk°A;C¤ê=.˜eL]&k=ÅÑ£dRjŸ™¨`µHcÑÓ*à_à[5@|‘Áóz=@uël¨ènºŠGíŠÀ®¾LSÀ±_PE$
Më5Bzåã8ZÄ´ôeÉpg<{íİ&-«M¸¸İˆZI?{Çòüœì¢¢¨¬gÂßú2Òê+çE½T¿ß˜Ë2–…¹q{ÏiW~
‹IM«ß¢DHH³ŒşÁ€éN®ö¶F5¬¢ÙµqK¾ŠÍŸüeB–-~‘ê‡æ#—t¹é¦tc.…0Má“—e<~]­™O´›ØgÇM¤dÈİ!ü&8ÖŠV«bº®§%†çEß6´áå^G8Xèhc[ğ’¯¶ñOIÃ?¼!ç	™#«H–P/š¦û	@® ¨Híö\í*Ç·…é¸P]ß±
5´“E`	X.,¹È§oÒ¯ãN!ç¼ïk~'äâ½öy7ë~t9*®O%{ú,QgáLí¯ïãıÜG% êCWŸTVñ¢gˆ]\{.jªâ‡2ë§è9Êœ«å;EÖ‡èòË"k2Q1N¥“íÉ¸>#fæWt©U³×¡)İ¹Æ…Ö—Ë«5~ƒeŞLzóUš×G£1=2µ"ØD0„Ñ«Çêù“Ã|ˆ1"\nå1iÜ±dS‚›rÖ¯Ãœ‡ŠÅ€ÈÆ€¦·Q˜-9¦­¨CƒÕûd¤ÜIz±+i¿{_[‡X<?!£Ùp?ÓİI†	PÛ³Ô†>¨ë½n—´hßŞYTªÑQº‰ÎËå4Ú­µºN›È›o»%óp;u7ú–iß­î¿Wf‹n(‚¼êröp•è`Bãt‘'I0 :
*\ùu!ãŠÔèG9hÚ01Úï4&üfÖ›[OüRÖ/Æ_¨‹µ_5tYÏ
®¿X§å™ñ´VÀMI(f›¹VíÉ% lêÿ¤;õˆtÿ¸¡‰Ù³CæCb‡RÒá¬‹HA4”Ü;Ü@ı°3S^QÔ1NûÌ>º f¹Š®EŞÍvLó'ÀúÑâ¯¸ Ş=İ›:ë¨©òê=›Å)~„˜\L¿îê?^İå!á2‡@y› lò&íu‰ÚM5âg€ß"cOfƒ_5ïÀ}n1ŞÍ²è‡Ê|ZÛ
\Ôñ.Z\N#f-ŞÖÂÓ_‚î ±4v…üÌØ3Ì À@QÀà…í¹–“ S.ÌxUÂ§$H-p{Õ!P¾„Eåfø$¯ö¹_ä;²îÀè‰½SGÓÀÓ[ïxC¯Àb¹"9fŞg…–çqú¾ŠH(ƒÏ³”˜'	W¸w®Ñ$|üyí…¦®è£8/'T„nÍïY3ÈåĞ–şê±iuçt¢¯&0O±Ñˆì…™­µ_ÇÖª¢hŠŸ^"LßI—(¾ÕJ•Ö`Í/ÇcëâÀë¿ûz$wa#úƒß_tû„‡†f²PÑ8Ï&=«bØ´¦™f–2Ù]ùı2U‡dr¨‘ávAĞ) ÖÖuÅé!QX¹#¬x2Ğœ0ù=F¶ÜJwulÑ]Ó³õ¦x@"Ú©.Û\Uìp»RB‰<[ÑÈ¸÷İ¶«ßdxÊ
•³Ê±ÌaSÈB70Cœ?>€Ò{FOÇ< Ók¹á¯ ¢ŠÛ—ú—{‚Pb|Tû²»»7ü —Ñìä×*ùHZ¨¡´ì;kø;{7œ©´j¤2
f™EvÜä§(Z—Â ‰Ÿá$¥­æ(ßE5ç|kmošo"8W1¿¹ûš^§JrïZùÃ‹Wê™wÄÛP„ƒ±¼2Ä¶}éú.±Óá5İ8¥ƒƒIÄ™&ıñÀR$éÎ™÷à3p#-nb§aV¥£53oìkû‚³ÄÌ<‹{¶²-·C¬¼d+£¸ÈšzK×Û¢?czfK‹6ËŠ±µ9ù/„¡&­v\Ëby1}ht”ªÄÒå{—”"ÜÛm[>†±°íïtÓ~É¶ìDzµÓø”7]G¸Zß#Fy/6ÒÑLŒß>Mâ‹(}MÇ¦ëOŒU¹ë,wéhH*–³:†ãª\ßmÒ51Ôü\¯ôà¿×„ƒYNŞÿ%o‰³W÷¦ÄæãÏæ¨°t?'ˆ4ß¤hŞfŠŠ‹K™û¬G{M||*cÃRò¸ôĞ?¶ï½?^¯ôÒ!öçõİú–@…BPµ¬¸ßöã —åÓiA]`Äè9½vSµ¡§7qeªšÑÖÌ4¹ÏÖ…ytÀğ0uöï‰n:”&Ïi†=R@Îk³Õ@%JAov|¶04ÈnLÑ&ª[ZC´ÙMË×Iòìg]Cã®"ú	œtÒÁ+³—n|È½ÆYÈP7¿ç°‰iê_~.‘¤ÚQHıÿÿ‡Ÿ¡ìPj„æABsLQkÉšu)èşúÎD¢Åö¦¾4SÕb	Ô ¤ò/Üë#'ˆ|bGAGàÒŒ6‹_‡Ã×ßqLØ¥¢¶f…vØNM!Yÿ.†’‘¸%ÿ‘_L˜ô¤ƒ¼‰´ºâ¸KQûš¹+J@¨‚»x–`ASE"’ğWÅ¡BæŞ9ø’ßoÙjvÑ‡kÕ³°ˆ_¢bmrÉëÖÛÊğ÷•8| bI½{„¯bGì.ÎÜ9Éî°ÃİXQÎôB4S-µ$úÁœü‰&üÖç[4t
„qEaÔÓàpb9–Çh©Ü2$ÿU€ñ8_ƒ¹±vZFR <føoEÓgûOû9dbš‚Æ¬4d¦İ…_ëÿ’¼­6‘øíÜù ,¿mQ‘MHô¿ıH”º{ã¦éËÈ)9Vts¡k»ûİ¥tŒ·Rş§N^Ù6úX€Šë>ZœO/üÛ–ê€JeÃ`^ûXÈõUşQÚÇÊÙØuµ?¬ÆÕŒa|g3wl Î†¿¡,u'T¦¢Áõ>Ìƒx?r˜"”´ØÃ’Ü1j£4÷)ûHtM6 ½ç%„j;íé–Ø›ÂúW½·±H-ÛÍ)ş˜‰àßà¤zZ·^G0õiF%/‘+ÀØB2‚Ë$ˆÆ¬_3üêeVÅcb¾BZ«cÍ²èvÖœü³µc7ÇºSæù~ÖsÍåÎÉ¾fĞú£˜Qï¿ú®î'ê¡İƒæü¥bh™XJ·ÿ\øòt³.ÁPwGãù’@ñ#èÛç¡ I'Ïit”/49´_5÷
*Ù„o…5y…»<X¯ìZ/ac*¦×ÄcÈ©/•5üw‚0~ï9îÄ÷Æ·êş·Ğ7À²zÕ“ÕÑçìfG >}æw³À+5øŒÕ ·†êwñÌ72~«.åßnQDùÓqMœsËÕ.w9”ó§d:€=>yØÇÁ#6”)`eJ~bJÀ¶ÂPEb²û­C~·Â9::»øæWZ­Aë)C=ŞûÓã’æ–SçÍWqkcÒP]RT[mŠI¬\~äW¨^Ë
–qˆz)b%¤ãk
½İTï˜Ny¹GÑ¢n2ísowr'åüúså ÔÅ/ê*2îû‘»³Ş±Üb2ßp×Íìíd°ŸÙí)q?.°XzyÚG?e|ç_ÑÏî>UEpõVoD:şîQú§W^ÈŞÌ—ş8„‰ı§ROüÓò‚V^òğ”ÇLİİ¥<Nâ>_Oó Y™¶¤?+ŸÓ¦ëÚFusÃı.Ryì>ÿÜ«uZ7ÖÑmE“ˆ¢‰´}#n8—ŒU\7$Òe6?¤ÿÚhÿÀÌãáê½=<¤dgî%í‡T”n(V÷ÕYà„ô‹”gç ¹4¥Nßæ‡Ùe¯«Ú­càáòŠy¹^ 9Äç¹¡N@iÁ}‡iç¹¿û<°áó”ı³—R\#r‡ı¤Gîy´éa\]+d-ğÌNq?7¶ woàÓ¡¶—Ÿ>–øêı­ªOƒíº
'^éÈd†ÛW2¢(r	Îßõ)`ëQSÖ´°…Ówü©‡$"Ï±ñ,Ó±ş·SXvF¦¿™ÜèdZ›9Óø†‘Š³%Ón¼e'€¾'âĞö,å·çı^]dSmÛQ³ßF_&¾¾aMîÉıç°ß¾6ĞÇ¬¥ÙÉ2óñä3[šQÌK_¾‡çXi1Q6x0èZZæÚFO×ˆŸN5™°¼fì®±œ$;´LiÁŠ#–Qé©OWòÙQbú˜5-í0û vãØªzB…öœfÂÒÒ©¾õEŞwÉ|ö’"[ˆTâcN MôÛ¸öÏñŸKÁ7wIÓç:»æ »_C[„«\Ÿ˜Fİ>dÅX^O˜–°Ûb9ä&?gÛ(»ı.Ù¢	Å ‰‰ìx?§HàC#U#—T
Û„é%dè¿›ÖmS	Ñ-‘ë°ñ÷Âñ¥ı%~EÚ¦xQâİì|ïqM	!Lú¥+¥’y¨ı¶½‡~f$é‚¢	n²¼JÆ«Î;¶ñÓ fW¦²üYv>AÃ°Í—Dä‰Ø¸ìÏXˆş`?ühgŸ¢¬JyÂ ³·zAt?ìC‚ĞiÕØ”/W¶Z¬‰ú¦¶^~fH»4<À‰w…+_zÈË°d’i~Ëíî2i¥ì ¦š³aş°˜ìy*Ëu† ñ¯O*p ËĞ®Àu¿öúïª8DÁ~H…£Ã¶9Lf.%fu8|eò	¸ñgÏ´ã¸_ÿR%¢LÄ¨8²g]lLÏ±•Ìe24ZÄgwZº4-÷€a²bx7ŸP2µÄœjg¾Ê77›„;ôe0i¶æÓVã«.¨ÁFjlµA¨É¼ş¸UÓó­ƒä©ˆ{­ˆG3¸fI"«4Çi/¶Ñ¹|{¼|ê+Zgı
ˆƒ[úø~š ùXN¨!ì˜qXeËdm8\Ä´U»÷!Ë…ß†šIŒ8gúaÿoggF10ÿò'ğqøÂWË	Eo¼ÄUtDRŸØ? —áÉµtì¹oÕŒ1.<@ğ“Òî/Rõ6¶1ğ…œ+/zamÉ$ œrhXNğíº¦Àu'¦Š?BğªE¬ğ¼†ºş`¿ŸGİzSGÄ!aËƒÕ¥
©CÂˆú*Ø2ÜÅRİnÌJ5l0€ç#BëX„âÄåïsÂ+Ö›¾v©€…W‡£u±lB°‰j‡eì´ÊœÂDè|mñÂ6¤Ç²8‡V íÙÕSÈ‚ ˆÂşDàO»K€•Ï@D¤Jú¹o  |×üjü3œ+¸tŠI¡Nºq—eÅT­²!Ãb?™vQ©¥`0|¶D…r¿Rm=5}) 9cìËù^#€t¸µÃŸİ·Ie4é%ñZu[~Fošş­È®w8hXùò³_1©ìù²àÅL ‰³¢½UWZ:˜Àš~Aw(VxI]Ø¸+_26ãÈÅ¤ØŞ\R¹ÒëB;;lêg€ÍáfâŒĞH©£Ôl pm!Moµû3‘¾…]?ê
‹ñYJâ‘›1qzL¸}¹Î¯bëÍrĞO<I¹ãx°£
ˆ¾hŒ5«‹(Úôèşá¿I;¥Šaë¿FN"Ò)åÊZêwd*oPŞæı5ÇÅ‡›É”Íö±Ô×Ê–ø­¦²ÓZV V™¹ó[ÑïI„¼¾¾[õÔiƒUtmn®VU©¿[ä€5@Ğà­·ÃÑÿn¤sYœpÔŠ,‰ Õû#àÏ8’:ò»$|¦Ò`¶Œb~Œ&îõ@fXŠO ŸùƒçNĞŞ‰Ğƒ£ë)>GêÄ8÷IÈs×AON¼~`³ÂmR4q„u¥?ıf²ê	ÒHM±Ã.{¯Õö^Efù"ZnÑP‡¢$©Ü‚n<ŸQmÊ.U‚îkyc‘Éa“R (¥Ñ¯´ÒÚsÓ*gäŞG6p$o^³È‹/êÄÃ4E“l×ÚÏ®ah¶!XÏÍCZcr°”¬fbš6ÆÊ¸Ù/¼¿9[¸Y^5Ñ—7n'¥şÌßÈûœØÙêOCÙîB6k-p;ZPŞş±‡Ä`pƒóX&O~amôh5Dˆæ'ÙBÕWÇ?r>ÂRBWËR«/§Ûæu°Wß“ÄF”èÆê<g™9
¥b#u3âÓGÃõKÕzÇC½2BÇˆaD)Pn Ä‹oâWMÑ¢Eê£®²k´TNpn,eúmâªø	#9Ğ…–pè$ï¯"Êºğa¶7D“®r9±”˜ªßCŸ‡ÕŞ¹ƒ .ƒT:m×r¸öOìîRD÷µKğ‚×B=è&\0·)¦1©¦>M»iÛ¯É"¬×Êh´ğ]12Ùv–hÔ¯¸@–ãJó–ª[‰âhÎ÷ÜRÃ¤‡66×š¼nË²+¾sR¹­²ıù™öùù®›¹;ÊH‰½:j–°<…µ"Él„¢§nsÈJÂ·u d–¦.ÑÀ,îA!°ÓÜĞš°ó‡ƒÓJ’jA¾…'ûn>ñ›Ü"¹ğ# “r0ĞÍf¾tà4“~ÚæƒÀXšõ/X[<TºñÖ=ôŸì8ƒ£óŠ"ìÛØñ$È×Õƒ¬§Šüz–ß3âg=¿‰Äì;A¼Š¾›3æşoáOÓd³T×=ºÍ{DÑ‡?¶¾ˆ²â¸›z¹èUÉÜ½Ìó8ø»o]øƒ)BÂVÄ<òr|æªz õ,qˆQ‡n«`®‡&dÈƒ“¥"?l²póLe!Ö&Şh:Z`y(Í÷~¦ƒ°ºÑn«^OÇL±–vƒ<–«3YLäQĞZğöVè]«	ğ¶€z)™º†$¡Où>ìI5“«İ*\ÖK$cHWqEÑ„Z¡-»´ıŠFY.@ }ì^ŞhTÑ]»Oj[Ú€Å>š¦9éò6F Ç˜mF5pª´ëµ¤¿0ïÎ³H^×Û½èQo½{ëX«:FÚ)"-í¯\JWP’–ø¬ÄéÊæá.•Ó]¡“Zx®CM·Mí!±ïí`Z¤m%< ôäÌ”|cä[svPd^VmB’‡?v¨¸Yâ³aôZÁôŠÜ†ş²Èğ2m÷ÀÑá	S¢ãˆLˆô\,.·í¶6ğ‡cW„,ÑKı·½€…MdÌKJsâÍQ<Kº"Óì|æ–g)l–IÀ¯øä†0§}BçI7De‰’9)ÁºûqŠf4’}!DZ’':Pô€oêàt„™±îñ¥ZÉ½*Àµ<;­^¹Ü¦â‡Fáˆ™ô™…l‘W¼ºíï‡¬àƒë†Ü‡/4b ¢êƒ[>Éá"yqş$b]âôĞ3-–s?ºA—£şd®ÌM•ß~Ì\`”4¼Ï"EFE!Édœë½’š«jmpPs&>ÃÙU…^²¯íÚè_e\){E›£Møhf {àçT,œV!†¹2yş· ÍŒíŠZå”ZPCÕ0ÔŞ÷—ÌhAl’cğÕö-õ‹xÿÔıÌàè/—•üğŒgÜ"`v"ŒúÛ.¥•:rãÃGÉñÆ9
hyãn Ä­Ï½»,$‡ÉÑV6k«3sƒ¯E¤K-Ww(Ùêé`UJ Äò…ÂÎ@c¾[à¼0‘0Åæ¥Ö£
øÖú¶P‰Î‘
©†ª­>0élú˜¥Ac4iàg‡
üŞş\ö,)H\œóÓ:ÁÓTs<ép[´uÉ fr~×¯DÕ¾ØÚVå?HîÌël?Sê:ª÷0šnŠHQ™ŸÔ«—-tYÙJÈ·LÎ~¤ò–—ÀÔñw‰EŸT¨ß	Ğ`HjÍì~çÆ„¯á›õ<j›ŒhUı ‡éÌ3ê²[AÛêm~kS²–ôôÜÌÇ©»œñÚ›‰6ÒDM.ñdôÔÃ|õ^Ö?¬ÌE,©iµ<JÜÒ	×jL!@ªã	ë÷¾vrt•¡ÒÒà˜p8†ÃÍ
Õ6}W5sæ¤V¤7BûŠ0\¿_ô®}óWkéúèµ/ÅÎÏ_\dç¥Ô$Ï-LÍ–!Æá	5’N²<G-Maô…o/†°xRŸ‘ ±t6&Z„Iˆ
½ä¿	>›[ÁÄNVPáÑ0Wp¾sşÀŒShálÀ³Ò µ®Û,œœëİìXZèÁ¶÷ÿ³)•—şùËÉô“ƒÏù¿º![âVXÎ¢=æ¿ZÜRÕºJ}l/¼-m—¦Ê#úRnãşã½(0ÈpïAjxG¾¯lBÑ,ÊŒO@°IÀ?±Æ¿»Z„X-íaâC®¢ˆˆ„|>ò> ŞÓ½Y)üCLQÇ©ÄÈ7Û§H¥Æœ;ÓƒâìwÎ	½Ï®-É¹›š|N‡m"=ğaV{0½¾óZÃ¶+VÆIÈO/ò¤Ï5ƒ`—™·*Â 0ÇçlXü¶#º]ößÓS kü¬Ù_²ªËV†Ï:’Ó6kŠ
ï“Æ¼@5DúÁX¶’î13»‰›lá·†=ğÎ&.F+V*%•­\«FöÁ‹A½{xZÛ2ÙÂÆ¨Ìß,Îªÿ i¯ÿ>3­MÙRæw=«‰äK¿M¥pà¦Ö:ù6aA½b4ztoÔuRøÕ7QÍƒÔr<j^¿+!´@ÿæ`aT‡Ùw5åßpÏn¼ªãòç4P`¹@²˜;€ašë¨ó²×,NÏ§î†DÁ¶rgÌ*¡_‚ò;w©nĞı<0'’y¼°û­/º™¦2J8|À°îÃ â-à³ƒ‹nMN4Uì…ËÜèºŞÅnØ;ğ ^Ô&P‚Ò±z§Èø±EçÈÖ÷Ş~ÌkÒ¹Wu›ß¥¢ÕèŒ¥ùÖ|ÁJ—RåwîÅ¾¡<'­‡¼Sùg(}ùd#92oÜ`³¹kó·QÅÉ*^I#ö­T¡l†àç”wâãcMv
¶ö©¨¡ó3‰›µï½‘ââ	±kŠf>Hlö2ÒÛ”b˜TwŞVê—ÿ÷ó|¾rib•—²nC–W<Ì ]¦PG–Z‹{g.C£öÙ‰VY7s±mEÄÄ3›ë@½vR/ˆ%ÌÊ–eèvOÜªF 7ÔW|W{ÀàÀ‚€4´ªtÊM+"şG[vÊTS‡´{=xZdba+»ÍO/"‰"6‡d÷€¸&ò~¿ªB¶íĞ°ò‚¦ÎÜQ™Ì?…3—ÿ¸ŒWÉ	=`ªì$şê?ğå¸ô·`ƒL¡©ÏáoÄõÆíÁ†Å{å@õæ¹Üe¿ÈI'7ÕŞm=ÿ¶¿Ğjh½1Z¦Ìø—Ÿ“~¹â¯ânÒŸkcX‹Âw‚›pŸ´óìÍ–9İÚæd°•k—ãÁßŠÚ cŸşÆ­û‘\gGğkêà]à9=§”ú4xÖsÃ,lt7Qî8Ùte›«à ï}-Y ´É±Tz©óLGÕÛ¬®ı†^K¯¼‚ì‹“D„Kà6Úä@ÌøĞÇÙ+>d‰ÉJ¸lN©’pE€ •|ƒÒfJ9øš’¿ÉÀì`æÆ™¨q
³²ßfP.«õ´kÄ–ÄÖgòèF™hjzÜùı}Š„Ó§–Ô6íø}èx¸zŞ~¥ïı%‹IÀ’µOkf?äMÁba…
G?—IáQ¡¹¨V…´)Y;‹˜s SĞç÷ä,ëø;ğ3ÅS{nœUERXŞºÕ;Ú–âRÀ¹oNLËª¿œ)ñÜÑ•ïÃ¥í@Væklpİ€ö-7ğ…œÙ/	5Ã.ªLGr¹eTäùe˜ * Ä×€@ãYŒû´§¥FXå°G~œ8ŠıÒÊ×ÿ~¤åûvu!h³Æ¯£°QXdoĞÓFA·jOçå8¶I	.òC’W$goô¡u‹‚‰id8)Ez66Ñ).8ßÕ:ë¹«eÈU(S2Ûˆ±bls‘,¤±•cæj—®18ÅÛyF á·ï×FQ¤eôRµ—ü)£,Ó²ÄØı7Íœ£y¹· ğ ô5Øe‹±*ÕK~[±úWH•+[^	–ØTT*¡0¥–6D¨YBÓLŸ|ã^ô*ÅHl†Å•„²×r%‹Cdês¥#9¦/ÿeÄ…q¥¥©Æ9‹®Ö¢OU+»xÄÈÒPsñé6ï jL´^>d¥)V97æ³Så-yçy¤cÆv!Í·äŸŞ=éÕAHCú^r¸2‹¬A2»Æ¬—‹dµ¢XjÜßú5
…"bøUbÎ|ŒåÄßP‡Ú¨H½QM>…ˆ2™Ë…Î–¾ŞÅÀ}3ã€3ë§ëS1úßßÇV¸Åô-÷9üÅs¶A°¿èäfâ}|Š®G2=ÕÅo•;,\Ñ!Â„³‰×óaÇ¿nQêÍ•~lÏÇÏ¯_¦ÆÒ¶ûÉÅÍ‚ÍÔÌ/:G‰5~x¸¤)T
ñ‚ß<SÕ‰õ%]£$SuMâÊŸD¤³Úyùû§^/îá0‹Ê~3 Å‰U¦ñÿ6k/rt6½ÆZÂ2,ªx[jµÎWÊme´õ{:ä¿é%üâhkûñü<ª‹$Œ¨w‰hLPö®.‡yîh^öbÔê×=‹1úY;¡4Šº5gG¬ÄÏ«Ú\ÇÙ£: ÙBãbG`9JĞÙS¸’˜‚L×€>—hÆJb¾³°´AWv@ª	/1Œô}ÕËÓúª5‡Él]´x
áYéæ’dG­xr÷…Öu¥O_Ä{İbq@@¢@[—<ƒği´Åˆ5Ç)¼÷ipšELËDË¸øz)ôK—YÆ‡òä´ğ~ yú§ ñæ˜%¶l•E©íëÿä$"e·aü–G*iøì©\:§Ñª«ùƒ¶ëC‡oÌ×F:Éz™&»«y¢^` N·XÌFC]ôrVìh¸ –5?íêJî#¿H©±BÙ§²
4Gk>cÊ¶©–f¶İ¡mìrqeÃüs\ÂÎ;ÅèşPqÈ½=óHìß$ö}TcË¤#.&RÌgğòì;äæH1é¢¯Su+ÛEà¡ø?Z‹©­XFMaûŞ_2¦ÁôÂ€UQ‹tÆ®”êc†ÔU±ôÅv§Í'şïÍÎÆÍì_]¼–®¥[„†IÛÛ¥-ÙÈêâ(A$>ÜO?M…|ñZ4ØVO7Ú<pe!¥3Ø}¹NºhOs.>"0øbÎ¬
Ôrx‰ÄKÕğ%I<$O¦a^§lû)[¢EêHNó’êLĞ>ÓDÊéÇD¼gW3ZL³õõaC`æbašåŠ… Ò¯'‘şQk’cØ1ô¤ƒÃğ¤êsÃ`öD8Áö©aåç&NíÛ@êf0«mº1 QW:s%²J#¢ô“ò ¢¼©Hwé¼HÂ‚ö¯~O1ïiï÷ÙŠd w¨CŒ^îœ{oûÛâ™¥Ø)öşs7âÒA9Q=A#HŒ
NÇÈ‘ê© Y‘„Ì=SB£˜å—6O’ˆ‹[q{ƒ÷g	İÊô.Ë³©T^¸åyQjçÁ¶‰L;ƒE¯BÂ:BÉø=e)m,Óú?æe@õÕÕ~*÷qtf'
DY¥ôÙõÌÅ^uRMN»Æ7¡ïÈ	¢¦ó4.ÙM¢œŞHy£•o×9v´¶şÄ&Éyœ]VÄC*%8"ô%:Æ,“ògî–ëİ¯z)ü±l=àªúŞJ@gáG)ô¡ô'7ïlíd”Z*œŠ›¿ºÅÍÙŸß	uÍ³“­§ÜWmÅï1%ÏóøÍŞ¹1ç°~­Qşo:¤Ôfy¾Ç“ìŠråltÄ>H0Êã¨}©Ô<¸Bôr;º‚óF™ÑZØ®IÔ®•q„X \<,7®3‹ç–‡¬$…&‡ˆ=!4¥È$úÈæ]À—ÒÿÏ@u±¨xï.	aãB÷™b`Ÿ„t[±ão‰®MlfBä¹˜ªØ¢-éU…ñ¬|¶!íÎ‰=üRÊMM
XÂa€ŞHjW	·ÒÚ	c]E/fí˜É¶'I0°¹œQ^´q€?<ı§å-’±˜Ü5ÆE)DĞ`cZÜBÁ!3¤ú‘3×](Ä^^ô9,“á×lFaÀâ‡YÒ»íxÕW¼pïvÇ´`¨¹½ñsËÜ§îŠü3J/(_ÖÛfi”I"a\¹ğÉg½î?³Æö‰ôË½›HïÁ¬dúŠP…êPšı³³_…Ë5Âõ*"rª•Y’œ‘Õ6Ò‡`9}‹½. 6tø40ÇdéQËFccjäUë¦x­L„J4ˆò4Ô/× ëÆëY9A®@»£û^f"ÛÀ·"<R/y©à Äå¬‰è‚MĞò:Pá½ß†Rw†!Q+áE½g>&¾±"àu2:k0ßI~Hğ
F7ğ4ÛÒ½ÁÌmDô†å9Şç»³qPhwò>ú§ğF\]-]ÊZ¿x0Jm1K÷n$ÏÂ4¦‘¡İk‰ëlãìrŸ6½òÙİûœSœœÅL.“–mn–¼ÚÃ@Cö$êÌ[$`…£LïAx{ºV†úC jKƒ+ fØ˜óh¤şH<¼¦[·É¦Š‘ÂÒ—VâHÒp'‹ò,ûŞ÷2%¬FÖwğÎkè’‰‘~å5²³¨’î¡“	å®H¦ÓzÄ'‹÷bø½|K´r@J=Ã@Ûë5<Y]XìõâKÈxÜ@q·ÓÚ°"gÕ­<Îöø¥›Òpìıo'–™âä|Bsèéß:úôë›Ê‘¼ısíÿ2$wVÁW^Œ«
ˆ×ÅÈ2EWÒnÀv‹'ù?}Ò¾F´[3-ÿ|S"`ÕÃG{.‹’šç]Å›ôô2Ÿ'6P¶$0Úâ_îŠİF‰²¬ö7^"üYƒ¢‘Ú½TÉäøÿÏ‘ˆ$¶äıÙ'³ë\‹T"]ºß4+¯¢®54$yCÎzBD<çĞÎëp6˜Œ/
¿èÊæËe—™CE³Înâ=ÇdÖ9ø¸eãPô—EzÏq¤à€»ˆH©Îvr¶ÍJiX>‹sšû+1òâËAp9Y™ŠA2~ã<¨C{béS¹×‰%JJ~Ü³‰p½åÚÀ'Á¥{Š„_Ç•@(Œ@6Ã®9ã«€hør—+õ«¹BçxSØûå¿û;(2ë:%Sš#&—ÌÚ©Ç“Xö—ö/ÎOÎq©÷î^)¡d·áæwc3Û]ä<kùr|İ·/ 22V¼®]ĞÍS‚·Fo	Ä.]Dàë×.k_\×` õ™Óé¡&p«Ê]ÜØ{ô:oÄ¿§QBXê‰kêYoç¨eè—æKÑˆµŠ{Ä=ä}ê#9<P…¬³*¡éßL†¦MíG ¢.™ç}“êÆtë(éWü#(ÙóÿJz¦GİÎÿ5÷6çÁ°!Û‰$n\IT+;ADİ’MBÛè|óó(:¼ËÂa@\‘Ä_:¹÷aœ©`-o$·×-<W=æÕĞšÉCwª' &®úoe¼¢Õ¬±$dxşùg}=ã·À§æÊl¼sğ?:Çs§„ME’+HS[\B|Ã’_Q2H¤>L_¸Ïoè÷ìóîØû^‘”%¹sîŸgc?©>YbÂÂÖğĞ+†2èqáxŠÒPÈ|é 9øÎc£«Ğ²¡vÿ¼ÙÆki9‚%}’8:Şù°\‹Í8?Øv?_¢ìÊv´MŸCÎæ÷°Àë_Ë©°ş¾Mhp=l!êàº2kç¤‘ø3¼T9}¿p‡l;‘ÌVie¶7a-¯ŠŸhY§’µy, beRçŠö¢v^(É"ÿ¤şşñ›D¯‚N[8(! ³‹‹5=ïí?Å9×Mò¦àÒi´ Á(ªH
ç¦„™¨ëğ¤ìsšN ì½1öo+Ï|5L§3›Ìgl æñ *?ïzìíƒ 8™%IËhŞî^†¾[ÇŞ®¤n €ÃìR™¶Hµ>År¸¶iñ&ƒ>¼Àe@şcpÇğÎ3WI<§·;×fÚ±0#5…pés´ÕZò*Íb¨¿»¾»ØÕ-g™<•»A7…è©+:¾YÜİúÒ2È7•Ì’Ï9°î*a¦›Ğÿ>RàQJã÷‹Ušù/œÑ¹™¬µYü!—/ĞÃó9¹iÛí„zú+IÌ=ôsãl6MÙA	q–ß8Èù£%õçNâaÿWëÍ“>¨ûÍ_-œG˜£wÿóçQ$Š:\‘8Œ”íQ¦Ü¬‹î
K7Ú%Ñ0=qËw8â¶–˜Â &µ}ë­€‹™¦d	•Ö&FN—œ£^İØà(XÒb´.Òüæûù…İ9>¡Â÷L@ıJ»pA Œ9Ï·wnDkÃ_¥zúÓ°è»fäq=îï„fï<Ô3oşŠ£Û½¢ëAÊZÎq­s@½ñî:ƒ7ªÌõ¤†ÈwCú7Vhİ•Ù%J¶ba Ò3Fˆõ%{¾øÓ#¦=1ã™„ÅöÔ¤˜¿zce¨ü—øVÅo äoÖöï+	5ºy¾\˜ƒ€-ÏâŸà|ÛDÖÅ.®voEP•ı=«İ{ï–€sU-x#òD"€(„B¡dèÜt¸Pä•À4˜8ÍÚs¡IÈ½2ë.‰Mÿs:sSİkÇm€­,æÎ>Ó«ùEQ¸nËpğÏ_UF£]·áÍÔÂÂ’=–hÆû¿oS‹ÖC*Lßãø¾‡BÚ €•WTR‹%YJâ½+3ş‡êdÄ¿åûˆÚ3µspÆÕÄ[‘-³Ée3âï„èÕÓÿ“ª«A$Ú må¤!ßúã
CŸ<8—ûzük[á¯c~N¹ì³2Ÿ^jÅ§^òB.ù–Ö$»øş³Ó|`šã­+ËDıslÜö“¾¬ÛD	ù+MÇÓ”‚èIP7<äã) ˜8Ó¾ã^gÎÏ/­| ıCNgwYa v6DbáN°¬a‡OOÀöªÚÑ'/™àG×>Ì¹×'snÎlTú‰Z-jÍ„SÈáš >hv$Aç²VĞ=¦—™Àê’3¿äSRO¤%¤jÑ@ÿx   ŸfTmRRo À·€Àe M|±Ägû    YZ