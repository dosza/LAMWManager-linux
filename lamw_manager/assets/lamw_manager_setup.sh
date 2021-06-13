#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3874399453"
MD5="2177f5062bb6e6eb3496272d929c62d0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21252"
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
	echo Date of packaging: Sun Jun 13 00:32:40 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿRÃ] ¼}•À1Dd]‡Á›PætİDñqÿ´ s	St4¡jÉ0$¦¨&ÜÙnÇ£ô{,dXXfìÇ¿¯PnövS—ş€ë²zBU,ÒŒÙ"fœ¡šÆÙd’×W=_0ÓTÊĞ1„Üæ¼ÅİKìfßÍ^mè®®èb
–9ı”ZMıq«¹îawÀ²IJkL uÒ†›ªléX`õN¬Ü–ª¬ 8®'¹‘1ñg.‘@]z1ğùt9IUU&9'ar~ÏÁ!ïZºY33“‹ ÓSú–O^éœfÊşªÀ İ†ÿÎ"ä8şj°„ŠéÌÂª¯)3FF>‚ÀÖÁ€o¬ÿa<®?lçz?*pr-N±vZå’‚üçÂ­ ÊÙåÃ{ŞÂ€NİOR\Øye(õE/ŸÖ®ü‡Î¨¢	.ÿä/c“ÌÙÛ£Ä=ñ÷b9+OtUG×ìÕü‹ñ>ÂíPªúÄº$ºDËıZ{íÔÓ4–Ä¤1=d˜“A±8+½ÎÑ·e(~Ùäè
Ä.ÙMàâU?<ƒÃY€©~4œ4—èUm"‹÷P—)YlÕŞØ·ßºx©Ù³}ôûi	KWà«¬Î½…zXt¸¤U‡@i¶NE°ÙÇİç„fu!zĞˆL‹Ûº{À4j n$˜WmÏ0•ø·R,¯¢b7ES…ùÖS›©‹Ş‘éÀĞ³|åiFˆHf«jXÌSµz¤²ÑñéÜÏÉ³ƒ¹d©aægÙ4Èhœ»ÑÉ½ŒmáÒ¾à<®dy)şlce·N±óŸ/à Ã¡Æv'¶gÿG	ExB=Î›ÈˆÁç×pÊüRõæT³*Q]xWÛÃP”!’áœs¯qï…·Ô¼ÑD3óLfó|¶ÆTßÄNh
•ô5—†UH¡ÀâÆhŠ=S¶ò‰Ó•Ÿû‰)Lú¯ĞmÕ®p4C^¦Ø’„…Ü¹4$İÖiÈ}ø¶¦äFo›ãFû·ê´ìÀŞø?y4jÙ®4L!İ4iK|¨Õ[™è0òmı|Òxâï­c€ßãÍ]O®!½©¶h[]øA†’LÚ¯¨?÷w´š Ôfª'\®|¡4¯ÑƒÁ.»!}?Æ¢Øç3MµXÃˆô;dÂ¸¨h6vQ$ıÁ¤«ê“<vùrzÖo_)¡*@€ã{sø¥L	´ùš…ô5ğWdïà˜S{Gl	&ÈÜVy¥wºÔm4p›†Ï=›šÑ;7¡§?+ÎHg#'%<['1KñLîĞÓ¿}Çñ)ş#vé<tëYTş§i81ö	ÅI³dÆ æ"Ó’!Š=‘Í´Ëã¡ëè=	9££¼ïÖ[Hì S9İÔN&„Útìôê¸_4«³Oø~%5o…Ì@;˜·ÈOz|–ÚW	Åp‰Æv/ÛÕ\qéóÏ¶oCºïŠÔ„f¢âÑ@ GzIJkÅ·´,ôn*Ÿ9dû×å'Pí+z'‘8T	7—/f[QÌÇán†«+ï»]©¤k«õD›F£$R<îÉ_=‘†•µ±_mZ¤< Æ¡8¥ÜU‰~Uİ¯+
rÔ’æY8,òĞÔLãë8ó‘l¬â4ÓX„-~ˆIë)ò±eCx´ÑêFÃã|3@,ËkØI)ÇJä4ç‡™ı}Á< ¢@?n7ùÄkŠå‰pR£E¤Ufrùƒó ¹èZC?ùøé""gäp'#°í›Æ¡WU;CÇ	^~~G@YP7f#×ÓünQ³×F×è8¤zÒÎ370)eMº4¥äÌ+7Û}™­ó¦Ii'ùˆ¶	ÀV8I‚–›¤Æêb¢LøİfaZ{ºjY/HTj9ôQ-¸‰Ğ[Ğ—ß›´÷Uû‘–&ëÏŸ±¯v· dSîû2ág”[P™Ms™°96}a]ıÑ•—Pï½[O´–1ƒÂæÑ^ÈĞBdJæøªà;"†Sq#%±u±ø+óÈÜ©	¥ºv`üH`´ƒ¹µ¿ÃX+ˆnExÁëâ«¶2ÆÀÎMË™Pp ñugvÔ!âqîàOÊWÜg¤!0zš/ˆJ‚8øTDÊ¼l3üèá1Ièuò!ìå»Ual¥T¼ A¨U³‚[›¯g´gìi—½p|>²ûQJ.…AÑ¢r=¥>#Œæä¸LpÎ,mŞ‰]ë*ë±5I ”w“µ©IÿVSpr…]¬p—h$Õd˜¨.Ä|;O$uãŒÄòõ¸Ÿ[Kl±Ùª^  ‹o9İùkÚ—QåøkB^KÍx…Rö­V2Õ;àdÄ_ù1ùwØ’=¿¢™/Fë—Ya¦ñŠõRâS”÷>Ê%s¦À©22![#´°§qªŠÎO·ˆºLRfâ§Â8­! £-åißùZĞâQ4¼há®+ëœõ†BÏy§õ¼¦UD; §1–~P)~,«İÒ¸~ÛŠ®}Wœ‡v]wÂù¯Ú±“aò½µ/W£šç…’óh#‡=ê LJ½O":éS0ø ÷Mb…´¬LõÌÂ#ñ{ÌŒW´“ğÍÚév²`	—ê-ôÒÅŞ¹é,t…íã'¯Ài0,5¥‘hXïíÎÌÇÁŒøÔ·`]"'Ùèâ[¾´éç€ØFc1 ëK·|"
ë.ìM3A¢Rh:VÓŒğÆp;Ï6q|0ÉŞÇHñqŠ1Rpò­\âjKR/œ•rzöñ(ûà–*õº”»aLV“›&§ÿB\¡ ;œ:~X©Zußog+6Á§Æ¥ù¤­ ;®K“;c3²‡æ~ğ¾Ş3{ÃÚ2üÜdEôÆs ¥EÛÏ$ndˆ[ê>Nû„FèUK¡!s#ÓNJãØ‘¯&iŸbYÛxï˜ rl}ƒz³Âùø²%Ûİµ´;t„4¿è$‘:'fº=9˜)l®íŞÁÚÎ¢ºÙïëÃÕŒz¡é›ÚÈ:Ì„šº*v»óTkÛ,kJ/ÿGsÒ2ğuÉô<Òˆ¢¤<´’6Ú¦ì°oµ¶ÌWcÙ
ÁIåËJ`+j8ÿ¹D4'YVîšeGgÅ½YD¶„w²Lì²xã°”]«9V'8­Œáuâq9à­p&‰¸[TA2¹Yÿvmå`Ú_Dtø—<édaR¡çu™¾‡\$ÇîÂ”~ŒÜH¬æ›Rå4Àà(xîó\#Ûò¾ Ãk'½¬‚z‰î9´¨²ù”¼ŒnşÚº­$Eû)h‹±€ï¾ó§Û	;dª-ğ]£{æôTT/N@S5)].Ñ-/Ï,˜*X£Ççt\ÜÀL  •¥èU:SHÍVè@dÃ"m©ğXëjSœû6¾»xğ\AüğIã%<€ìñ¼.€gónÃğq…‹ØéÍ—ÊĞÕoÁŒä4’Ç®6ÿ(5E•€Ìh-û¨b‘W¨®…2›×{ïÛ¬&0¤&F)ÒÏ)·;sÏ!S-‚íäyY…ã;B¢uH`+¬éÖĞìÏÑÊ’ÿÒô]u
TÏøvzşfïåš¼¬ aÀ^çv2¿ş(»[(AÅó“åÌ5x3øtŸrÃŠ-=WIkÂVÄLUˆ½ÏS<Ú·‡ †VÎƒ»’)v!ã	°‘QÏÜ/ÅBWHã’N/E/×ÅX¦câhÆşw‹ÒÿÍëX€¦–“~®«ê#¶IÉÄD-´ğ±ÕS%Rvh} $şE«78Ô‡¾ôAÎ!‰5úWx¯/õ…csõ^'B×ám0µÙŒô»U¸N~©¬èr~^€Ÿ-TNaêy¬ˆ$›ã ï¸r:‚İù#|ìÒ1ÁôâÕ¢,ªö’c6E@TÂsô'mœ‚½–ˆK·ú¢vÏŒı&2{”»R¼Fí+!` éCÚ‡[‘7üƒ*jßFƒ&²dÎ®©eÑÕğ®òk>àKfm¨An#Àø¦ÃThÁ°!d «„ğGl¡/ê±@"ĞHr=“&Şów¼OF	³‘ 3~ùoûî†rtõúSñÍÅÒrtüİ¾‚kh±ÜŒÇì¡Yvi¢F©,iË…mÌ`›y¢AW³ˆJÿC zR¤~Y &şØV³'(åpPÁ„´Ã%9.´®<–¤˜(yÂù±€û ãš°Z–ÃÕo™àN¨ÊsısÆ+»4{C¿r[XÎ´¬y­ÜÎÚò¢zó£|‰ ñ&»8p0q_ÒÜf¿fVB‹ –™×g³Áóÿ×Ò¼î¯^W„ôåŠÜ[·|¢‰Î¥i¾,¹›5+R÷K\8¯ê{ñÊ‡uÒsX(¬¨¬¦£ÿ~9ä? $dÄ¦I/ˆ@=Í§=­ÉJõ4.Ïk±¶åÄ–dxß¶ß#@5[´ÊBµZQ4yO…x¾‰Èb°®9ÖÁ”Xmä`N^¤çF8 ŸBŒºB;ßM/£ŒFò^T:¿ş'8¤–ì…·Íı¤Nx à*®W0ğ¬ŒZ_tn—'¸Û_«'Ìïe~öiÚ/8úÚé†6ğb…„ 7±Ïö·ç]­ø#Í¶‡2LB3n>dñ”7%é§1Ê^äÆzä»_J‚¶©ïDÈƒ]EPÏT•š/ƒ	hcX¬™Ñ|N½%YµzáK¸ÀöZ­ uÚÔñÆ“Q£ØMšÄ6ûë¸O¢¾gêd•¶§# I!A™ç6!Åïöœz ¦	äj"K?»şÀ1VñyWµ?è¨æì;ûÚ Åø×aŸç¾ÎÁ^X¢t:Öhø­„‹böm?¿äÔa'tÑĞå¼¸ÚóC‚¢wTÔ vJ™#[TëÈb•î·öFÍ>µ}´Nu˜!Bîë¢Z•‹Â'Í„jw³&E.ï~Q5÷7Qàÿs:Á9¥jÚqMÂº6ÀûB—e´c½¯7ÙcmËöŸ¾…7ıİÕµ;jµ1¶=_,”UJÁÃö;MÑBŠñ8°vz©#Í›vïxbÖˆK‘i­Ñ6'ÿ;tuº õáeİ^X°ßQ†è~7rY©ÊŸ*ìÆÊâŒV!ÙŠÅ×áÑ²q#³£Š~w;+vÎ&©»íP7 ~r:ÄIµÿÏ˜sF{»pu!İ'ei€Ìã›gú×Ğ	N$åíšÄƒÂ½¤jZy*Í¿4~Xtø'öïxÎÏ%ï>ú”gSõtDxÉ•PÌ8¹¯×æ=P¿q¿+S14	/WÏòßºäSRxÓ\AH³tV9ŞËrúıI¾Ñ÷ºöV<€á'÷Gà+äg.-÷.£^ç7ˆåEİöò$´ÑbÌ<bXnšÏ®®»•Ÿ+Ù¹E-)¸Ò£éPÚ·‚ƒêÄx¼È
dÕKQwÂĞÔo•b×VÿÖ Ob"Hy’âİ]…Vİ¬cvB2f søŸ&†è[ùoëÄSìÙ/ãoc˜ ·ÉŸƒà/ÑBÏúàœçA2ùÿY—}%´w-4Q7y‚mÛ=]­y•ÏÇvY¯í¼~iƒ=üÈèı‹mÔFÁJÄ{píëıˆ“‹aÂ#Ÿºí¿´&~êék¹JyNâ_mHç‰M3!~m§æìÉ%
Øc›l‘C…Sà7Êƒjö™/tµÆçÕfÑüeö›ó–GU“cv¯5å’¥3“@ÒÇx âW+^ºîìĞòYôJ„OsF1	¿lãˆ…	ú»cItœÊ–’ß/Xwï~­Û ¾Úî(aû¿U‚_Íª#:ŞÇÑÖÅ?Áè$–r·N¿e{£ÀR­&y’¾ÀÑ°k²¶ÊoDÿŒ Ôº@ÇDAz°Æ9KÅÙª–`gª?A†÷ŞÔauÑïY™dvş¾Önô™²	,Z±]•àÄÔ&øëT3Ù£åÖîH	ZêckÆGCs¸šòo‡¡ Æœª	ûQ‰[¬M-÷²EXyPzÀ²–ş„ûıaÏ2õd%ø»ö~ Øƒ<zl¾A€c+cìlÙ™ˆ#íÂ )ÈEä§ÔuÚY³OR5~qÈùX—òÖ;Ö! $¾a®ŞX'mhYèÖèa¿õàñwï$ŒX‰ˆ–k¤Q¡ÈñÿüE!D¼¨ïĞå–Tß7d&í*-œİ×œR0jÂZ€Å[şØ[8˜jMé7ıÌëâ¬sVÊÚ]^ öµ‰^WÕšÁÚœ“o?dE¸]: 1d´æ:¨™` ·%ôØóœºQêN+×ŸâûÕŞau¿¾2«,J¸x®Qá öÀ
âJeË”ÍÑ5õ‰ùŒCæb¶G¼I_‹}ëµ‹Oğ†Ípò£oBUÿûÊ=pMÀZ9
E¥HQ9ƒKa}®¾)aÌïwJİ¬;–‰Ó)µİJ8]w©!HpçÍ.’e¾U8iáƒ¬Jx¬ª<ibG¯s,«RR0	ë†_^á NÅd€İyx&i¼äúS—},ÉØÛİ‹¤ÓÉûóš±´mz0—‰„İlŒrH„>Åg®”Qƒ`'~ŸBè][õY¼kB%©µ[>U`´ã1l=W›ì“™Ô98¶§ñVÆØ8b²~ˆ«§¬<N²pÄ8™kÒ³¿As}ü_ÊVô’pŠ­*˜E4(zÄ#cóâ4;k<°?„qğõƒ´ì‰£ (»ªÓH°é "‰İı9ÓoâZÇ3 å;4 !ZVu¤ˆ­¬š,—?1lŸRØhz@Ø°W*ÏÁ\ÃÏ\“iÙë+<=§ÖsÇ6[õÂÂ2s[“kŞƒ=ó&	ĞO$§ UÉ…€½¿SŠA¡D•ª£úXS#Ap*›ƒD“SúZï’& ç)‡}$½¤’uzx*±‘GÙäEX—ï‚ãÔè,ç¸Ğ³ò»¯L¼| 8¤/„9pfË{l_7òÜõ(A6kOF:Î!*À‘4ÆÒ¿/Yß3juÚ,²û4°­9]¢2l©k³îO7Tí0‹÷$Ú|ÕËÓ`å`A¤ÒæHòë3}tX-&.e€²7$şe³¢dnç^Î•F§±„n­º^¨0r
8eT»¶=fö4µ™nMî"aAéà‘˜;|NTxfK¥ŞyeóB&¥=›&Õş,15;öûÆÑ}ÓlıWPğ·êÿrW/Ø“sæ«JÁpLË$æp^Ë°²µ’áÕ·„íå½>ğA52Éá˜µ—`¥]ùY¤K.-ÄÎØãÖ²ã¨O½í˜Zœ¶ å2¥’88ô/:[Ñ]ıöÔğÄé²ƒE¯^¥mX$¶öXmßA&”t;MTàj×3<÷XÿS¼dù·òúD"<«¸‘–vOâ£î„ó.E…ÇÜF{úÓŸ[Ç™ìÖ#Œ<ùxÆú€V&¦H´e?>F–u\?ÈÀ)»=¼nèä<@„.C7Ò-‚µ1–ÛçDb—;K¤°‘LYÇ>âKÇ Ô¯|¸ê¤T³’âÃCàÜÍìN­ö…ü©„óY³­^¢±\Fk«W!qfæm3èÑ(KL}Š¥x›EM d/ƒD]öL’e‹QÄ5ïioœïÍuc?|®¼sLÎ´­«×³9koeıá»³ËÈ‘è8ßÂNåœĞrS6Za	·°tÿ-e|X³}ÆbTÓ–¤¸„Ë<$ö‰k;º9*OŒÄ¼¿œéRexİ–ÚÚÅ@İ-ràÔ{uŸÆLÑĞµØÖ8†¸·àZŒ¯å¢¢ôÍ¾â-ÿÅ\fö|ĞÌE:–Uö7ëWQš…¸~‡¥ß+HÈÄ‘4˜O»NAS¹Øó7Ò¾KjªŸ:¸Í5Ş‚UÑZö}&Q´K{XV‹-kF¸$^Ü@\v{Aµ²ãÌš¿'Ôõûèûí3‚“š¶¼7™
Ÿ³œÏÚø<¤´¿Ş…5Ô’iSpÏXÒx N\Ê#Ù¨ó¤ºüŞWŸÿQ©2.Êø“läæ	Ø`eÚPÊÀˆÒø[dú"`¹óÅd!3Ÿ3f&IIè9øb^í"˜J=:/]{e“'xh5¸rÒmP‹€ëqåK¿‡T¢èIto–D™w-á7Ä¹îğc,¤CE<g°ÁN¯ybdXÊŸ‚©ì—÷¸»Ù”¿x‰Dˆ¨ÃæÃÇzÊ6V¨+zV•ãÏäõt‰4mGÈv_‡ØÕY&¤ßº¢k¥X»qºáñÁÑ
ÙFp-e#Íìı~lÅÏ¬g¼`W÷m6e®Ò¤ùİ(
>;ØŒ,“Ww+Ò´¶AÈT6¼,Ñ ìxáç+‡Af“Î¿¼nkÂ&§TÕÄ²b«QÔªÑœèÚè·WÇÑ²¥DRİŞKÎ6ÀáÙœC,G6ÅšòïV$¾¨Ãl`–'#TXûe±¢ª/Xÿ€
k‚“/›ŠQü!ÖµE›@ÊëL“GÄÁÔ2cOæôu3K8¼^­Ùà­/¼ ¼”E—TİmãP Ô¾‰ÿ5{ÇiÁØ¿Àü4xŸëA€dÆ»…ÖÙ–t¯£ø¯B44‰˜dÈ'±'ŞA~­²İj—mSÏFál§ö”'ÄxYq€"€¨È—qQmí7ÂåÚít×e–?÷.é$j@¼ê i^]˜¿İ1ÃÉbt¬şÕ‡úHÿ<mØ‘åŸÂMt!‚;ŒnÆ¾SÉÔl1M³;00uĞ$"åo–¬Ñ‚v¥ˆ]±m7@œdš` \úQ§CÙ··*9µzyÙeîdgîY	>#"n‡zúC×Å•}½yûÖ´Š?ÏbBéÏ³©[PLƒIÅ«ßaóƒŞHUj ›PM&/# –>%‹SP”©ıûZJrÃû¤\¬Ğll6[y¶xŠt Sæ¶œ+…ÜÛ¨=„P+p5Yû;’*ÂPî~gÊÿ’všBµfVßünÅÀu;æ~î041ïö;DöpQÑJ…à.ÈîÉİWBIm.P¦úñÕĞ™^cÜ8d¾Ì\5WwÙbIN¤—¬ôÉ[W=ÚŸÍÎ?'âd%C-”dhET1¤Aã÷ƒÂ;‚; aáŞ
‘¢õ¡Ù»æ‘¬‰qı˜@ÌlşC=´P‰\ö¾Eúò? ü(E¯¦ïíäenq¥¯[ËQ«V¨ñU8€oÅQÓA?LuÂÃôÛH+;¢«-°4š(D½÷İ}ãqIÆÕ/—_•b3Ä”6ÀÒT>3|éS‹ju¢‰2™d¸”ƒÙ[Ş˜‘fîË”E9øLTfäOoj|/j5š[´º¼€nnêÚ_Â~¿;WBg:<¦”x8µÌª¸í	@³mMVõËr«Epå¢¿KòñŠZ(rVÎ†%TqáÚXBzì1?z2ï³!Ù4ÉN–ÔŒÄ i/>ï\EŞ²
Y2úÈ–q8Ö4T¥§€çòüC@†şbŸ‡[Ç5á$Jû5ö\'â4!pë¨‹ÉK}¶+\³ã¢O‹AÁ©ÿAFŒ±aÄ½AŠU«È…wgf¥æÖY™v|Çq5º1„ı¯Ôßì]¬]ÌIT9É~í…²ødŞ´—âDe§Á\ùÜtLŸ-àíDcyëa—½K’€Œ•ï9L‚´©ìG¼w@.Oº
_›b¡³™·d+xâRĞÅ?­m=±xáelw²=ô;à)g—s†Õ’)»F.CÌ¨¸yáağ¾;EÍUa®Üˆ²äPícÓgfè’— ´rWccÔçÖ0ˆêÏD5`FÓ¸)“W‡ÊJ/ªÛûíÂgØ	‰xaü˜iˆŸÿR¯úeFõUÙÜİÛæ&è.ñÄg ÷Ï·Ù÷n{Q} î\8èÖœ&mk›XÇöSé˜êÇ}y.v©xĞôLæ¡ãv´ıFx¯4jk«±S"áQì2ÅôÀ­>®ıà¡vÕ»Bó”})Ih>TÒóÆw
Yù‹ı…Y'~jK¬X¡sH'şS³]"‰R4ğ%í”<$ÎŠi‹zã±›÷#‡ğ¾åOë>?:hÃ­º	ÌåæÆ§”ŸrùïN¾Ú\×``a“±Ôf\×pµ¶ú{Ì+É¡ËşÛFYı[ÓkÖ4r½–ãXE—F<í#&-Ä_¢F=Ú·ÿ¢Ä&Wvú´ kİ2]–æÔòs·ˆ™é–îÔmİ<ûMøÖz®W‚LV}<‰–4LêŒ¾H2Ld³ø¯]S€Ò€¿Ùz>²l¼Cšnô¼| ¤UÈRûõ->¬K)ïÔ©+•£Ë0òxøÕ‰éÆù2™U‘Œ)˜·<x
šÒLv¦@»Vn]Ó•@¡Ã*´	ğœ-œ“âLiÒÕt°ú–Bé‘
i‹§¿Ìğ/}AœWƒ€Êé7Ğ >wïY"­–4úr…¡Ç¥£s¹ö>0ú‡'İA; IŒ8Aàè>ÌM–÷¤”ëµ¹]#TÎ[k?^:ğgoí6»ÏrÂSSêd’dL¨…ÀÈş¹êrÙ-éï»²#é8É¾ÿCNÃìû2òJÀ2ëaÜ›—Fâ0$Ê^KOÁOù z~1…/Ò¼´>Ió½ìWì-gü©²d¤<SBUÒáÎ@jš“+6Á5NÓA'™y1b7pBÊåK4‹­ iy`ì‰âBÀ‚"¶÷L´Ã+:p´³®r‹jkĞ$#Â{KúP­æŞ‹ó¬€2Š+2Í!É€ÊØæ–gUŸ¨'…	r>9´ç·P™òóõï³”¬şú5¦·¨vˆÄ
ÛX¬©».“ã[ìñP™ÑQºöLäŠúææ¼šŸL¿À‘Am„ı[ıšy]1¯g\ëáj¹ÅŞ	ñÅ1€,¶"”ex¼´GOwdiA´—§Sn‚›Ğsê¤W³©±|¹*n¥u°*~¶táB)	x
ä/5E¿’‘4[Á_ÈÜÔ¥wÂîÊ¼Ú85È t9­_,:ÇC÷u71Í¨ƒÑ{² Ñ&N„äëŸŸQ!?7nzâ·—äxe©«b=æQ?åZ&>‡FD;6?rlJš¬yÔS¾WÌÀÎ€ÜÒ‡°ñú“¶7ü5šS$Tq0nâI¼;	,e0¬(¢İ€ìwZÉŠïÂ«!ÔªÂĞ+.I«ïùN3©Ù´×ŸÚ²² ÕÄŒÄº±Ô¥P¦p·4hƒş?:É£"Ó8¥B¥	NLÎpü*>¶O±æÇŸîŒ„.3DQ Ï¯$zèÑeènÙ\J
õI´"ŒBÂ šaì<l¢¯Ÿºôg«¦¨T£®-j±‰ğ{kIN4~¸ùnïÇxS0È<e2ììkÛŸŒâ+SúI½»°W–R º
[´o¼iË‰,…I’´5¾Í³Î?Â5¾›{½…= ­Ùi('õıä¾{ºâ×U2@@ba+G•uÜã–];®%O0w×ÁÒ3·ÄÆ-“ş¹°IPA¦J2î<®İÛÅ&g¶u
İ*f}[Ä†SÉ¸gİvX ğ­„à¾!E×›k5xAğ3eÄyu|L#ß6…ÆòWX‘Âí_¹ Ÿóyz(Å31n9ûëb‰î4ÃéÎgt€¸ö¯É¾…qÓÉÿE#<L¬Éund‘	şÑÉ"½½É`)<çC%êú$}—±Jp4ÅFãFh°¡]5®•Ó¯ÉÓ”õ™øqoZ,š.|—Ñ(„`*ßá	-Æx·–ÊK'gOmF~Ê€t)ÜV¸½_C$Ò	a¨H*(6
Ù@“©˜Ç¨j‹@ä˜Ùû5¹s6°©ÇÁyÄñ¿Î0»ÕÛhÜ!ŠjêÍıÄX¨«øË¸°İ/¤
k`’b½u†h[›_T¼\}eäÎÄ×¸j$0âµdH¤F(wËØü«DMÈ\Na½Ğ ä&¿ˆÒté\O‚ÑîVŞÕkÒS[#œ×„f&$æs—Ñ,~Ö”Ë0¯V})Bø£?Ï:Qöf]ex£ÄâàãËctù[Óû¡èMÉ¶­ÃÉ±›"kõ2+øyRËDw{
å”PÿŒ„‹kMNâi‹êmœkµŒ¯¦?1;	ûR¾²¯-Ã¿ÔçD]œ·SİŸ]*ë °+s¢ ï»gëÿQÅıÄ-¹1±~ìÀµîL‚cü1Byù•P/µòĞg’šÅår8˜êô±ßC;3XDYÍ¬¬¹Åmºuví"…/›T;?ÌœèEæ¸O§^Ä’)ÑL¡é—é ø:è9©¢×ä$>Áv33•OêF‰3Ğö.Ü‚û¸`(×ş:qw’1]«ºãZİYı½å"Î2ªfO_Ü1Ÿå„ŠxÂO™ó’ˆª'ÑïÇ£u©ÊÄkó³‡c{Q7µdšÔĞqÒ·­ŒA(Ïgõ“vÙ«BF¥„TĞVúÈyNí¹nÃâ–Ï<Â¡$­ŞNşJ ì3:wSa“}>PNÏ‹M­í!8‘ŠQDî•…É‚©»­%r@>§h‰ìÜC Ù†e›(Yš£1ølçËgø£I\ãCA;ƒìh­)²ó'³e34hÂ‚I®Ù3/ånÆ¨¢ÃkW²|ohúCÌ.n}ú’ûÈ&¼Å´ì@&m0XZ/ÈefüqZ&¿¬§ 8¥©¡DêÖ5ôF7`ØÖó™#¬Ëø@ãIš5“dEJ_‡/£ijû$)ç.ò«ST­'}5ÿ€íÕSÿóĞ—¥<ÉH"V[íõ[z]Eq'UœWîĞ-ÑĞø	 QTÁ÷ÖŞîƒ©i²bˆJv7'‹m£äÀ)Z*—¿„ªĞºi‹¬ÿĞæïî6¶ÃH—r`×ŸaR)L*×«òdÛœÅ‚ÊÙıûÿáÁ[[Dã”éÜVÅĞ~^Q.¢&â¨ØF“^~r¶øë` nİ>ËÉ<ëgßâÀ·ÚZî#»Í2Òª›ô0¢Š*_Ğhv¦{¨ÈÉ+)È¯7gJÓWÓğàv…\x“ ]uús§­˜SPº\q"7múNœu.9Õ?/Ù‰os#[“";L˜©:áúq^’)âJöxùÓ}ƒ/ÎIJ
ñâYù°åÉAz9°$<Hı8øÛ×>¦ê?€­¼V+"X(Ğ:vVWÛ?”áT›Xu®KËL†@#û,âµşÍ×K„KŒıÈ–6 åÕ áBÙ\f8>À;”W2/Ñ$‰Í¢š·	ü/í¸¡
ª‘ùƒ°ƒ*™
~²oãGj‚!ŞîR¼² ¬Pµ=2!dkh|«¾C^np¹!î¢3õ²Léo)”Ù»Ÿ,ç.ÂÒÊ0]ÙàV‹<Jß5è¹Q°MV‡ä:S¹ŠøöÀwl É)Ùng•f´×2‚R1²6CyÈ$ËØºËwIi¢)	[FU²j'!!tÿ›1‹7íaâøÙ}«QkSó§N3Ääü\…ÖĞˆ-œlÕå4®Ô“jg› =œò–`&üY? Îó¤‚áTşÅ'??Éå²šÙ:êŞ
¡N•eWÉŠÂÈû§8–éÛ6Øm:ĞH¶BÌ1ÖÙ?4?@<ÇßS)µCìCRE™bêùL«ùÖk¿ÅV°‚²\ıeYãnÿ³Úµ3¢?¸°BeGÄL»1“›³?2uE?Ã(^8“ë7)¯+rÑQÙÅlãBçÎ?¨QÙá¾É¦jBÌšºÛÑç½ÉŸ›:}"ï_Şß˜{ã<~N@YiåZ ÛMzÆñçëël®•’ò[”ÇˆSw{D7ß o]³$Ãxµ’’L_‡€v£ÖVÙ›`qrc*ÓÄfÕÑ=Í¡üòkŠÖ<%ĞÆ]Ô–z¬ä³“IÈÑŸöº<ÖÁ£—Ô…îÃ?·#¢ »úUó6)·á¼1bVãìafs\èõÿb™¸iÎCµ#s'øÕá™Ş¡ÊxÄF{ÌiÏÄW‰ Èû·|³Æfá…P„ÀÂw¨r»ö@#^’>oøÒF@]‚i;¡×<_-no2”“7°6šËï™î9vµœúÌE¬BiıØlÊ¹}(¿8PoeŸ¯ï9ú“nGÀäŒ¨U:>ÂK„Pˆû@ËÒ¹?…ÖrıÏ%FàŸyšx¦ÏcéÜÁ/ÿ3eş'şºAÍÓôşšî9ÄLWàwòÔx*Ş ¯X[	9Åé¹Âë^³â!ãut¼øşl‡k]C8K’œìeÇ!ÀÑ2ÉPnã®<°ÿÁ™+]Åq·'äğ{ZúáápirÀ›YŒ%#8Ô´¼£hº(£ÎĞÙÂ€I½ƒ\-ÆBòÕ6³3XôòfƒÇ_S	ÄK>b9ä“B|é‰ÓÆÅ LÌáÊE—­IÔbËøuŒƒŞn×ä0jv­=½A«•ä¿„êc”¤@´7õ¥ÃÂŞ1L©Û|Fâ/Ê{í³ã™új-sÌ:FãnZÉ©a–	XÌEú"ÊgÙ6/ô®I¡ÛÙæõˆ—.	ÅC§^ ù$•S‰€Xe+Ïi?İä¥œæºb[YKç=Iqõ[pF‰÷üÃ¾oƒ¥UˆŠc}Ñ[0Ã™’•U€ıYŞÒ`GY|[°}®Æ3Xoï.ôdí«ªÏeT& a»6ŞÏrö†në"ÊÕC,Ä7ï‰}Vä4Öáİåf^ši"{JA´t÷osGY®²hİåTüÓ(32–Y˜«BÇ’Üİ]¾v4ñŠgö²kmK‹–f˜êÆıÔÓÆ¦ Î¸zBËtœ³ÖRÀÎteŸoWœVXó![ª¥–WN÷Š,ÊÂ+2$’şğáywÅ:^Ãè|SÍÛk‰~üë¡Şî-x@g—¶J:3ğ™…5ƒØò³‡ní|GÃ¯Ãÿp™K^q7$ªwa·Ito`$€ãš¹_ŠŸ³[l­'œ¾äÔÏ`Ìªd›÷1ëü’NÄËOÌBµ‚ä(w{N(AªÂv{Mre~$Â†R½·)¸(î9¢‡ğed»ĞÌ+ĞÔt ’¬$EÂ'Nc×ø¶DM«jïmªÏ*Ú
\6œØe?72oÏö«ƒ¦6(X
­…W^×½8º…xE¶gÔÀ,pò!ÏşltEJZŞ0Ÿ«Z©>@É„b1Åã%CKk:VUYY tırèf«š¸DìtBZ|,³î¼óÜßñø˜G3Æ¥y²şdÄœW®?wŒ5’éá1ï'aÛÎsá@5èf©Š ©Ó«$}ğ«.›¥k]pºæá¶ÍÅ|±}Ğş ÇBß½ÌãTëÿÄî¹ˆ”ÖMU2V¾i&I¶İØm1‘*aàĞM§öŸÔ5^ÌÍT4f?<Á²üugxí÷ìÆµ¢ÍTL;öa âœ#¯ëw[)¡8r’¼eÉ2µshıƒY¬¤•“¡49Ob,NIK0ušæ½R÷|qàšúèò
È¥â§OFş`0åú[S³ë1à"H:Ğ2ğÏVæ0~Ñ­TÓ ÑŞŒ¥c¥&®Wzo·(ñ}„Sdê’S	+òÕœ’o;ğ¨"ñlòBM#]~qç’M#sıFºM.ä\î* N«C™â¡ãì•˜×Ø|š„ÊÓJ¾'ãh•LÉ=ÏG$¡qe !<[Rê?¶ÄEZÅÄfiÅßj»>±foìÉöC‚KëFşÜı»ÙïıºÑªtÆaÍnéôüh-ÂQùãÌDHÄ7p“gª'ó2¶é °vß8´Š†¼9`gÚN§W£òuçşfßÎ#!ª³£Àw±á+Ï×äU§ïPğğC@×ƒ(™¹¯2¸½87Åc

›äõV5“R÷‹F‹¥*“ÌEÄããUKØdÊH(‘ü÷S"¾!am*_Œ‚]$Ã/V6"şY½ëw—ÍÁÀ\À[k›Àæº463ö7ôÍÚï˜K.½‰/Ë?0P	ÑZ÷7vÍã{@¾Ğ:.§›ô;Ó¤)6-6tµZÍ(Ü³ıDˆ„óMµí9îÌüW36$ÒeĞHÂvİÏ’« gûÒ7 È+Ö•t'›ü<ÛÓ	Í^o/BJqş´uLB[Ñµ[9êä©›×öŠil=––Æ²€n{j|±…]B^¹ãéÈjÅXqˆ%>3¤ë7:—3İg»+ "#¸MÚ`WüúM÷› Å4'aV´‚MÊ®á=ˆáÀ[ñë8ã¯#ü‘UÀÌŞ:é¾ŸQnK](Ò‡g|§q<o½ÑÓ-‰ËÚ+bĞ/ûh{¨^ûCP'9Ù)u¿¸û<e®vÇ‘±#j¯ 0®ëñ¡Ì¿ /à¾d14æ˜Â'-8$âØéiøÊW…úÚ¯¦©ª·Ü)Å~ÿ1Á«78>–×§–GCÇ¤ñKÈÈ[pÑ–À²ÔnÙ—ÕÁ„±î~	|Ù©²ŞtÀïHù?ğúP¡ÕT¤zRßÊ©ÈC˜¨mØÍĞ\k‹Ê4aQö‘Í’XŞ`éÙì·„}ÉqôŞ„¿„QÙéy®Ú(ï™Ì,3JMK£Ú³åõ-Ú°İÇ_w“umÎîfíŒÿ"–mõò—Ş~^	”£Ò½Gc9@r.êæ¶i´2šqĞ…úy)£e&—Ç+«G³š7GÖô;1úáğé=UÔ·ï é¨ãÎîHh0²hêÌgœË-;àö”Ï¸á „››^(#…ÏÉ;…p.4AU4¾%$.ĞĞm¡ùü2‡ŸÅıå>$F!XÒòp9á8º¨¡ÂÇ¹A0	Ò8E#Sì¬±2Qş:~zÒ«›¼ÍƒmU4ƒ¯ëˆšÍq89ZØq ğYH‡ñõi]¯/§NK}Êiµ—‡CWni»(Têƒ3]£bø;M­)“æ¿Ne_ö.Õqnº´=Ñb;_Úµñø5Ê¶Å7ÃL¦UqdÃ“Âæó%JS8tàQPşÖ_°éL‹ àN¦¯$éc?Cd' §Å˜gB¦ß~Ü` @èÛmÌñÈ&öNÅkà,stË€ÂÖ
¬6W23?èŠN
œ/¡¤¿;Ğg™	ÓR¤>,‡SíVºò%W˜#ÌZ¥X¯ÕÎ|X‹ÀqOt¶y’cÔ¹áY9TEj,ˆ 9‡çC)Az¢„+U™z©_åŒî¤7¦ÒMâ¢Orûíª ZÔ-PÓ H_¼f¾hø­ïÌ6rU½…–í sÖØT‡åÁ)‡âm…¿!i%>6q¯FXÄúØH6(Ôj+y)F§Óúí_·ä…ruò´Q?¯cM“[Oµ–]|ÛI…¹båZ)^¥¾ß;v&«Q-™Õ¸›49w}İáÊÿÑaãø°z9¿¹´ÀQä–uŠ8á«Š“xÕ¯œ…ÖÈš¯Ò©\ÿø„¬g¬® ×÷ïdb˜Bû¥7{İ•°ƒ>2×syó	öN2TÃHÜÆó®ÈÌgÈ=ËãV>¹ï~nl–±åO(QnÅµƒmÓ*S(ğ…½V3è(î^nñ’â!½<\ÈH0ÁÇ ›(õDîÆˆ>gK€xÕîôHA Ş¿Ç‹uìFÌáú\SâeäõëÃ²ófí›ÑÅßDû9¬9JkT–º›KàP_õ(\Eù|¶’Ò5‘¸ B2uLk“ô BæxÆ7ˆ
mÃŞBjiz³H³¦y4kiªg&·€ô‚î$äÁMé –x¬jpËCp¢ƒ‰*ÇĞeleœu¹Ö¦Ğ’×Î¥‡#óÖ7ßô†¨ÚÚt\±©Àï-çÒËõQÒ¦:Õ|&û *çP÷ÊíD\^^ƒyFQpMRLŒpĞŞ™»»£ëXÚ qáú›[Ë`”)íØ]èÿ—ÈÃÃŒ¯àlş5}!¾›ÂÜİ¡Ş<o¨|úA<ï„ú˜ZØòçÈ„Š3­o¸ˆúÏf»uñ;¼¾Hïp´×Ôu‹æµ§¾Éä°FK× öÎ·L3øU]t¾C†fØ·!#ÆÖæöQÍn«L3„f€‘¨ËàşZ‰½2+€Ro¾R~	œ¢å•¯ˆÒ$^jÒ±0t.Wè'fÿ³÷Tæc¹£ªÜúa¸[6ƒÉBù†,ÎU+8ü¹w"Sß)«8 vÁ:øåyˆ—G¼)wtÏ[
’ïf.ÖÏ ­÷Q#œVn÷àŸšZ&tí ê/1?(Ë›ÚÇ¸?>ÒI§òØšŸilGPæ8MzÍ$A.1ñÈ±°úµ¼0í¼&ñ|	+´DÄ²D÷Õ´@-9Î\õË‘špºFàPàNéµ²Ş2g3w$ˆ¼)<X1íê	Ú_<øvĞb’–*±vLu×4…é€ip}ÂSÑ0^É)jÁÚÚôŞ÷Jï¸cáa‡e¶ÏÒDñ˜ĞéS=`‚RÙL®¢wùÜ·+@D İ¢jÚ|-áæ²*ˆ€ñ¼ıU¸ŠúãKtEaŒ‰FcáÊrHÂ‚NqÂ=ÈVŠgóè/Slr“EpşMÔ-HH2{àh	š°§™4¯Z¿L\íÖıM¬e^ ÷ôĞ³§Eıó‚j$X`Ébú÷şxõÙ½3Z\c¨Ú+¾ÌR·ó«Iíÿ‘NÁ#†NÆ°ï3NbÎ¡vQ1pª%¿ƒ.	½-O!J»hóMœÊ+}P–‡ÈÛ/wõiiº¡-Ğ.œxö4úyùÍÑ
J¡Å™÷B³Ä7n`(°^8Ş5 TÜÒAC; £K4Å¹¨Üø`ëÕ$¦Eÿo{õ¾~¸®5ğŸŒ”ª—å¼Ëß
!k»]ÖÇı‚DY¿U=Wd0Ùäëßf”İ¡0òåÃîZ•¸ ®Ğ—ÖÊ}Ñ‡ÌÚN4mƒ' •E¢3|ûı9{–¡¥ÖtîD›
­;ü(\dÃLÕÉ&D¬§±Â†û~„Ú¶@PîH±kH†Mº‘Ñ¡|©9–rtN—ì%ŠÌÙßín»ß§Ó4bıPëŸÊ|ĞÑÚàà5Ù¹ã¸>/¹5­L:Í¬f2­Š:nsOSF)\–KO4‚õTg‡â40¯9B8Ù÷A¿Fœ<Q´¢€3õµ´b=!óÉµtwÜ^_±İÒ UZîã<jßÛ£ø#ú8İÈtíËjïí0©K c Y8¿ùN…´5¯	9îätËˆqkQÿšÊìÕFUÜÅ©¾ ù·AFæ—±¾%W#ªPõïÖ×”c6k±dKÅÎø6’[.øè‘«¯‘ÙÛ` ¶oLj¦xaõ´Õ»°¸vzn-*A·û>¢^aj›Ñ­5…ı˜8]	*<I¯ ª½¢Z™¦cWıïØM{ÊiI*É%î’SÑ2ìC(GÁY7Ïÿõ“ÛÆäq0¢Æ_ZØHo ÒšcËe¶íºrûp*íñã«»ñE?4«õ–5oÙ)¸é/Ü±ì,;7»Íæ¯&Í‰“u#r™öš±m5×1¤ÒHæK…íĞ.yÂrPxŒaá.[sÈĞ„«F‘˜lNHbÙA]›)çvu¾¥Hş¨§Cˆ¸zö[¬Á;ÓÁvZNş+•û2–Àù«)'°xjk¾
 yå‰Q‹ôQïË™/‡¸…ÊóAÏÏ½}¿>jA ÷6fHáà?ëRP¾­»Ü€(îQÍOæµÊâë•bßĞ,w|ç½0¹l‚S¹|mªm+drïÓwÔkåüˆ5œš¡€A?F¯òØ¦{_ôUMƒ=?u“€ÒÈ“92T–²Ùırº{WÇvyÆ…5tK,êøuNí1JòÙ8Ş†ºÀDEÊ<¾:¢£Mñ»fšrç‚İJn‘w¬sÌ†Ô“4Fí¼S6”êQ²î^6Ğg !xéÔã	ôåQR-´xœgÙÈI ‰ôŠÈBÅ_Nã9co;ÚC´º™Ğµh«Yº#”JÜŞMèØÄêz6±hûZ5$şvPR÷ì1‘òİY/À9¶â Éñq‰Ò‹®@ZãjüìZd&9†¤d4¥œù_Ò³#‡‰h·‚Ÿq*í!ÉÆÊÅ‰§=‚³éÿAê²Y36o¥şÇHı¸,30Ü¡kÂ¹£›ŞÇÚ5ˆöß'´øläØĞÒTš”Œãä3>—aZˆG¢§¾xmiÃèÏ¥ûøù›ŒûìK‘¯¼k¥Ş<]é‘Ïà_½}Şé¬dÁäôIßD€K‘ècùgİY³ÍAXÚ½Eº´w£D•iÄauoSÄ}¨Zıï?çŸ¨–_öCKÛVLiÉşª\Û·ı’¤…iß%!ÖßBb\ZHEëO'íL°Ô£@$Ä…‹7ƒôÉáeÃ¡‚jK§-½K5–$r·•¦5ÍWa_“Pçš	?•†F‡¬¤<™*wLTFh´´&–/¢~Òê1,,İæ2Fß=äÁ2†¨ÇÍªp–Ï‚lI_ñ«¶ÓerbRÒw(nÃ„ãAÜÂÄà „Ô·†•ïqc®·ÆÎ":LMM¥jù+é…ì9U°*×*yl8úiÀ9²†õ¾-9]WÈ*ˆ»†,7L9!X…7>³š0’¦ÇV)óI$š{,ô¸ošÓ\vRl5j9ìZšâzÎ³j„u]½~$!®¡# (áÎŒúÛnçÀ¨$Y±ƒè²'ê÷@ó«u%uu…üïdã¡½®-)@»hWHò{l¸o$£)‡UxËÑCŸ€•„*h¿ƒ…%$XO‹ÛÇ/³À½.t-Ş}ÜÓ”/í„µÏË–ámÃªü™Ê½YÂŠX_ (RŞûºõ©#ü­ßí§È±´ÍˆàdÓ™õê²0`Ù?.¨ş=BG§OxmiŸ“?ì|y€ºÕ‘í¾ŠR9¼â:b¿U÷Î[N5oÅBø40D·é“ê„ş	&ÃëNä¤XÎU@Tš®û»”azïÅÎTæ†©KÀ×—Şšø³ñº^òœ8 x&	Ö>®–3¢¦¯m7•€ 4ÈÔ¼4¥Xã±–øR‘Öñoo“!Äğ l!zÇY™ÅHË¼°20ñÿ´\µ×5û¢XÍÉ€cÏtö1Œt”bt5f
ÈË—y'orl^fzˆñ$ÔT6ºº+Ñ]¹¢ãnÙ´÷`MÖ[­ÊÕk:ÑLÑ¥”Ö…6%h¹ÁÍˆğ‘„Üò]£†™«eô3š<ğÄ,‡5ƒg ‰"vw¢1ÖÖœ6’¡÷´“}U3mœÕ5‡"à°ùm¯RD†«Deœø`d¶Ì·²Y×%åBÑÏ]A£A¹d/)Úõ^ıËşrlLÉê¹ ¶!µ$B¦á†¦
¯Ì©A48JÇkÃçş¢Qc:GWpw
Ü±Àµ\Nv9šƒ±eîn1×•Åa¶Î@ š†\æ^—åN½¥YAÊ¼Ÿ¼ÁŒŸ*êâ¤!:gã¶;ôªÜ&¾D½¶ãxßF-Ÿ°ø’Ÿm¿Ÿ]A<ã–öÒØcc7«"3£S]™3!*UÇ_²÷a¤4;àØn­H¿Ò‡„O­E˜ÍJ×.~]]&aËb¬]Û>VÛ†ñÚt|/‡Ç>¿Â%>M¦ˆ˜O^µ­4Æ¹ÖĞ°AUjØ"`R}ÉXŞİqb+W0ù^İ~~á9‘x&/Å´ïñ~¢‡âŞí„…:GRƒXA:\šaN®}Èâ¨œCÇXø[¯!gÑ2N€y
†-Ì!ëî½_ÂJ\L«A{Äœ‘ã=œË¶L[oÁ0¼çĞ¥‘ê’û!š-pôÍg	9ô›TèôÆ å•YsZ¿ÖÍ/îñå7¹µeqş»b`‡'°ŠĞY"q1Ì¾*†ü»OU0½ø´ÎII®W¿Om¨’ùâ@O_Ø³‡?³üóÃ³½j’ZWÉñmª^ú< †É„Ôö£½±™µWúõÔ}¿ıJƒoú%è³iğiµÿI`ÌpŞpù5ÉÅ¯¦ï±ßÉ"/!|pÿËÕÛÖ¨¯{39
“ï¹Z?µ®BLüÎqcš…ÿ ?€¿¼‹üI`¬şÔ[ qÒ8©ºR5ˆ7ÜàS»âOÌB«å¯YrŞ§I9§‘$Ë“Xyèa› ¢È=1zó
 
4ÜzAÔ°i—gÜÛE6u¶µnt	dúkkvŸ$I6ëÜëİu$
«"öUÎ~æ",aŒìCbk³(#‹•ÔËÖş•Aõ#&Ø“¬&ó¹Ì'5*·#Ğ„¸(®a2å#Ê©‘Ê’~Dd²
IyièK‘&‘/J&‰§Ìi^$à­Ö’jWEëñî¹ùé¥lÏ‹­º6¸Õù TDïEf°"):"7k&Hh×Që=åÅ.Aùz&õ9v¨ü¡ôlîn>~]=”•39¯?,±äÂ¶#ùgñ)´Í‹K$ù÷ë2×°ª¡çg£Òº†½ã£ÛO«Hà‚ù\é	—rFÈµ©ÊqœNÊ—µ0EÃ™ËaÚÇ\há[rI
j|ålósœ…QÏm"Å ·:”GÔ!Ài±Ş5ş»€€Æ”·¯t!×•»òQ>°™‘˜qåwô&ö1·H_Æ­"2iM¦vNjã*¯l¨Ô]‰®td±U(†Ásmxq-z	¾İÁ’«q¼qQt”Km¢$Úz÷û²±]8 g³æ0’ƒ$°Gñİ›œå¾Ö# ‰Lß=¦Xe¼Qf@ Lõºğ×ª@|?£ËÁ-·f ï°|¬¿¸Ìš½*š8é6Dó¼ÀÄ¤t8FtPË¯ŠÆ!>İj1\å]´‚’9·|}9pˆøAŸäÙÌ3©VYyÅbA™ĞhĞ™LöŒ*h*óÙM¢R šÎ)S(üóµH©@Š¤Cå…£:"t^æ§İ×Î âj¶‹=Å÷ë0bâjmfİ’ú|ö?]½ÅİÔ‘]ë‚T£}=€„Uc;Oí™åÒ}R7­—b·ÂêŞ&ˆR%”KùÇÔtCí·ìªJ’1¹Eõ$#YyĞ ‰­äó+qUNŸkŸDY/'ï{€œ~üÛ£tû3.c{ñ®$
 ŠŠ/£ß’(Ó"–µ¾A’Q7 -h3ñ£¸V”G}N”"ØÍÃ}K	NäÑŒ	ámÀÏñ–lâF>öª¦_évPÛ€aã†äW]lj)³ éÜù™c±™_ÍoJôúİİä}§ÂŸÊ2;½“N7Ğm•2†¼.è1´=ÃCH{Û©ì^5~]TPºmï¡²åE…¨äÀèÈ8uzÇ~qÙcg¡“ âxq)ñYëU9ÅxËï”Í=3)¤—§ò:^oK½úJF·œ†Aq U1ú0h­—[½°B¢’Ä3ş{Rh¥÷iH‡²arMÓ…‚¤,?ˆÿº&zdú‡9U?ª± ìËùMÌ„ÅÇè©wM}&‰Ù;uÅc´÷M @:)á±2¹èR÷$ö—ùWØ Ÿ.¥|œÉjjõ‚³°Qš	N±¶Ñ©ÃÜ°@ĞŒÇ)‚4–©Ìªûj£jÖ™øòOkuMã·®'Æ¿³Ù'µd_WöÀÄµ 1 ‡›DÛS%¸3ÏäËå^äD³®Y‰äÅT}Ö¶Ş"KŸJ®p åíÑ¼ê„[kÏ@>TbÁ&»¦’¾­‘36Ü=˜™üòwl$§WèòŸ†¡É*í¹ü6ÃxÍ›ä4›ßÌúÑE‰»ò3¡hñW^z¨!ºğûŠF®Æ gÈK!<T³dwêçŠÏ°ëÔ•éGIâŠ—¢Ÿdì¯‰f¤àºk€“\u7Ï?¦Úıt:L4üÂÏ)tBS%õ‚ˆk‚óÉ5Àa5í7¼Ús‹ArQMæ\²YÆà“'ç¸bç”Ğ·ŸMÃuÌZÕ=ÆVä0ğ ^±‹õkmÒÑœúèÈéD–¹÷…¡§sĞãÈÚ„40µc…”¨qvA%|Ëc`;„<ÿÂ¡ù×Òğ…¥“+IıØqI¢s4wµ	}oè‡²Ä£,#&z¿…g]Ëç²eí5ò4mÀ-ÔëƒÎ“Ì9hùëBùê@x–kI‡f`}wuèËgq*±F®WG©}«´k®wìj€Bœ ÕZ¬ªv\¡]E”õq¡NEævŒê%¶Œ¿Ş@„ƒ¯¶!ÆtÙ–ásbºbz‚nÏŞ+( K’ÿ4.ÅÇ¦mKª‘İÓeŞî›@Ã»}5ø•óÏ¼-Å÷L,9Ôå=ÎP`W¹pã4ˆÜŸ—3 OFi_€+Yr†!‰‚ÖF×î¼¦—J·&²Õ²’iÇ‚ñü„o?Ç´-†&ÛˆÖì0Â»tÅë7 Lú×y¥k¸ ÌïÀq,í}¢ ¯ï“—£&Ñ–=ÉĞæ4Íy™¼’]ÚnÓw¥Ã§É„XBSnÜ÷BÒüæ*ËÍ·&6R¯ÎwKŸ¾!à•=ÙVœe¦cXë„æºY*Ìvãób‡İóıYYcÕóPÒ?:¡Éyÿ-åÒMæ¼ß@g¥Š³$m‚ÏunæZ5¾¨rï¼M?j„»‹è<- _AYW“+1?ïİT^éëo¹9n[ØëšoSr4=*3ÛğÁo‡auçÒVA·AÒ¦ô†éä¨Œt;4¯Lu1ô£pĞÑN¿ºœ¼k™iñ4¯E&éP TsÜ¾|¸™zàsEMvk`½NgO‹£uŸ?y:wóóø„SÂwæ©¿6ƒ”IØÙ+r¥ÚS4Ï¦îŞ¾¹â?UÔ“ŠÓ[13Æè»Áü x>i™ÈşßØ?|$L|t/Â–åroAª–ñU5ÑÉó“jw½³¼vîçö!|ŠŠdïO3ôƒ%†-½Àğùy>Pü\œTï&&·ş^@Ç*jôî–‹'”Ëîô4¹¸ÈLşú•KMÆ†Š¸UÈ'›0öa‹ò°®&¯¨#D‰l€{(Û¬Î'ØÂêrjN“BÌéUÉCy)öĞ2]RPú=OœÊ¿áu"×0c©.($‡k®=oªÉ—á¥Rx†ü§hŸŠ›ûú ¡eBEœ‚Í‚´’/ÁšøÆ	|“jËÂ	«Z#«­@;Å6¨'ñbÈ¼ÜnzÁ ÎH®‡kÉ	!?ZLÌ¥K¶‡tËmOÍ—ìKW.UU¹Í&¨F‰Ö"|<.bç@Ä<uE-n/s»8ØòtTt€ĞŸµ³ø¶ƒ¢Ğ]Pá+~åÍØãe)‚jù_ÚŸPÈÂnD~w*Á|¼Ôg&Lîÿám#[ãC€ç‡3RšÓ±gUæ·†O³~®då˜#çNyœ»áÒØ’Öq§	#á×ÓµÒtÏ´N˜ïß~$<™{ØÚ«Ğˆ¥ø\§ØÂäq®håš%a›ßàÿA¢­»²ÌÜoV1jÇr3Ç—&ç›šHÎÉƒû3OÛ/d’—“ñ³E’(¿­ly#öÁî2ê…=ğâ¹‘¶¦Ò-ŞåšèĞ‚ŒJJKÛe}“şšÃì&š7±HjÁ ¡»¦‘œŒDÁµKO ËBê[k>^ Œ#Ú!ë¦äìuV”ÑºtQşQû[¬áçd}ıÏš"js‘‰#"ZŞz´ôneUø`KF'š“İÉ‰¬pú¿›#Jì‰‹ÒËhLM+aõd"GäRÂF°îÂÛ·¦!„#8I_Ğ¢~›¨Á=Fxe›ìº³H;n_ã#ĞpÛÛ‹™wr¾¶ã{7ùñJ)ESŒ9àT5Ë~.GuÍkåÉ•¶í¶xªs¤Çp#÷½§İÌ=M—”™’3ZL¶JF³e ûO)Ï£´…ıØøó®­¥õ<½í]Âj€
MÄHƒ&__+¯/¡…¾ºo–ÀÖeà®ÎO	ªúÆœJ`gÅVè5¿ØQÛêTÍòºH‹¨Mã­)Ê(kû¹ ×şQr­gzımši‹í¯ÛqÊŸY–à}ğ^îÌoN2¹Ğx?Aà"B ï{¬Œ¥?–”S~­OÑ”Ğ2è³<ı&;VÿzpŒøh8RRïÎÆ3Fbäg¤[èİÿ›4W;®²Ëâ]}cŸí>4Ñ±—Áy2Ÿ¬…ÏÒÎ¤Éëiæ¬€8ü+S½ä³ö FÉDş¼'©×–ipn0ñÂSb(½8Å‰ç‡İÁ4DÃk/¥,úy§£Åê¹Ãdc˜â·Ğ	fr¼¾PZzjgT/n<RCëDØkT-ûBPíï
l‘9œG—ÄìYaÖÓÀ¤r ğ½;¾ğ(´{…æÉz•¥Ä©p £5æ¿zHáx²~Ë…a?ƒ²1};¸Ê6hš¢úÆŒàa´÷ä7ŞU“¡‘ É.¨·È]¼½º¦Z»éòŒ"V WŞ‡ÚŠ¤'leã`‡)'Lœb%¾pòÇ–…Hu¹.ñİ`/ëqŒıƒ¸Ny˜¼é~È‹Ø¹W{ˆëêísy‚¿¿/É&¹_Â»®îÇòÜóËIÅÄ) _«ˆÙÕXşh]õ~•v‹à¹…m!9á]Æ¶’Ákê.0¹zNÑ1Diöú	)°¨-•ÆÕ ³2Î“™€½‚?ªn¥Fæ9L¶fØ¨£ã;md–íã—’½SLH¬ui
3'x…E| Òhê`è£"vÓ¹ò$IèÖæÇGfgšÎ3‹ §K¥¾%wPº8‚m.òŠp­å.ûôÆ¨åt	&ëa}3¦+è„g5ëéâ”:z©JŸqLï«EeA-ÒP^:[¥~5ë(†©ˆ·›6ÏµIû£Î Œòaphe—1l©^ş°¡˜B\ß²„Vù‹EçæWaÜáï)³áÆDÉ·„ìû<ãfÑË|Šç´Ê¤”ó –›Ù>jş®Ğys! `6÷ì!©/×[`¸¿¹ë¡€>3Qƒdd:Ã$» K	<áÜ¢'Dâ¤3CùŞ»ÁÖ„&¼ğdt:Ì~ô—Z½şš*Çz#ŒYÍÎ)­	5à¦¾ÁÂ¸z«í‚lÅëcrş!_Zº1EmJ-Æ> {SúŠßœ¹¶ÂHtAåX]åùMy×û¾;Åçj+:‘8KV#I™MI¹SÔæÙ€|åè€‹”e8šç«:ÖÌ>×Y“ÄèyaW›º"HÏ]UÚ9°·VÖ5½†
óìC†M°“n‘O
¦ã_sEh@Ëîp{qôZë Á–³©`âİÎö·Ş¼_xˆ’ñAGĞ;GzTZ¬DÓ`½Ú»JP+‘Ô¯­„Hkâ^³¢ªÖz/szPŠ¿¨|£K)ükÛã´¶Úê`T
¨Vòïtê)ãD6!kä5Ñ?Eşå{™aÑÜšåš»£5r‹^P ŸI6\³ãJÖü¯e*ñÀ:6ºÜ‰aŸâD×8«Ê‰İ'Ô,nƒF›BÙ˜ª™•
ÔÅwÉ	”ĞRŒù%   uüÍ&ƒa„ ß¥€ğ¬R¬<±Ägû    YZ