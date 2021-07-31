#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="492718015"
MD5="4026717fa4ad31797054c83c88af1215"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23424"
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
	echo Date of packaging: Sat Jul 31 16:22:13 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[=] ¼}•À1Dd]‡Á›PætİDö`Û'ç„t"1Ø„àHIÇŸ-}vÅäÓ!s2‰…3²¼^+ùÓK"ï)»“Tmœ‡W’_*Ú£Xp¢‚H–S¯1şr<ªT÷\§³k	ñHUzå/pÇÿŸşˆSsO°¼~ °*,íê[£`ÀÅıüŞş›µœ®›¢GÙÔ9åJ¯ISòÇIÁ}ƒÌ‰ùeƒ•²šnü{9jÈÖÚ$Ö½ê7ÒÅ2ö™`o)0ä}W´$e/ïT‹0‹,Ô|«Ò¾İa¯õàò9KäÛG´ª¿Ç.æ¶/9º”7%tÁ~i"+P¿Én
8lµÚÙ¡âü{?T$¦èZî¡³8P´]°”¯	úKiJ=ƒ—íó5“O”ŠÏºŒ9xB?/ç§v ş;ˆoFÍ«‰ŸP­˜g^ßt\Ê¨{ œø}Ö2¶}ğ±s|µ<?Ã	½
QO,¦Š¢oJ+y˜šM8Iãº®y§!|+ËBûvA	äë7£Ş‹¸˜©”D³&}÷‰ }-ü€UL”Ëµ8Ós¬¼ÌHşpnùU'¥z‡3£P„©Şlsr¶òá “¦Şk: }.›­^™÷Ùyn Ó‰PÕæÂqÉÈèw§"Iãéá•ÑJ×°a×Ìµ¬”–Ûö»¢#?P©W¥2¤£êú4_§ö„æşhŞõ‹¼šóHñÖúH÷êßj“ÜßÍsëö0úô°:ìî¦î³3íÓ#Ê÷Kƒ´×$Ï×‡âµ¾ÃÂ&Ò0Ú	µyùìâ%‡i6°×=ŠÖ«çÑsŸ#˜‹h¾À­÷!æ]ñT’ÂˆµYç-ĞVÏMCá]x	¬7 cƒ™pĞ9_³–Ø’Iz"’‚‰xÎ< <]mô‘C_ÙãŸ#ÃÈ´cSŞ}¢<y@)Z?'#Ã°86ØznşoªÁ×†Ÿ6+”b#À"ˆÆY|Q{$è«ùPÑ¤4~k' ?ıƒ^oıˆÌùï;y¢<gƒ2ãSw1ø?TùËuâDêş
0íT¯Y"÷ná¼äõ8KìÜâS:vš‘4µªõm©÷fxÍîÿ´:PõMpTZã§Ù_?=ºjğÀt½©Ä”J°ÿ@ğk{4çÆ~û+‹{ ã[¥èÖÃ”ª«ÆµÒÍ©J¤t°:bbŸú",9‘Ø}³*IÒÙå’"Ó
Êo(/ûCÅu2“NˆqFÎ'«|é+ °ËøIş™~û¿i¼©Ÿ÷¨“¬¶O¦_]”ìIqœÒ2íigş?7¾Í#Æ×™õy‹(IˆLŸìmcèÕfã68úè— Ù|%‘¹(ßëÔ+= ğ¦‡w¤N›…–êæÖ.úÜ{ÅÿQ÷êë’şA?¯¦"ÏEÄ¢ìÇ,ÊL¬–¢Aqú%P‘rÒáüMÃÛ„¾[Aê=¶jÔi—oGµú1®¡Ñ–öã_›ò– Ôó³4W ÑWâ ®vü>ÈUt!0‡¶a:¹†ğjÀQü#³ù_ìN„@pM©Bæo9iUá›sùş8FÀ(üfã±x€(N/’¥š•“£ƒ½ÿm’‰µá³xƒ“~=–}#s¿±¢—ôñ=şG6N®N¹‡û„fÁ;¡;ªAÿ`LÅ°|Po¾°Ë8 ¹ÕöÓ+j™Í;’ªìƒÊ=èíCÿ~S„à%ÎQIŞ©íá¬ùƒì27KRŠà ğ4ı"÷Şq¯ƒa~ãÔqùãìK±NÅoÊÊbS„É&ä ƒuf˜ÅÄ{J†+¬d²ûğzdï¥[h˜BÎ%«\äÂ™àO­Meûµòğ‹—>à¨nº_Wİ¤41Å¾y˜"ç~Ë– ù*mú!&‰R™'†âaêÒ¥ãÈ¶ Tå4éÏà%Ó`ÂiYâ•´©·-€G-ƒ£+Hä…ZÄaUÒnRl~/á‚½v¡$¼eNiSgŠÏG„yÒ;¬Í'îó2[øÑí m¥_³´ÕGaP8f¿ÉYxfô
‘€øk}½ÿ¤w4kÈpˆÔÉoí¸Š;g*«ín§æ\ƒÊÀ€&}ÖíÆKF&vå3Ò®Ì4Mßü,k’y-™™hª°Nê¥ò±x'MÌïK@:’Qş¾²ØIö­ÏZÃR5$}•`ìé
˜{ÂtÏ[Ÿ‹Ú}¦«UÍü¹(7¡ÖZğïBFªÖ« õD±ŒÄ4²‚¦Øæ¡\Îl4(àe\şpõV‹æ6à0s#Jã#!˜éË”TöVç(<º	Ä“.ÛÂÿvz>pxÅİKˆÍ¬İ ë=g¡ˆºn%=ß–‘{Êód6 hôwí†îVğB”óÓ’Ÿò"—}+öŞö¿Û?V_sÙÄxĞÍò•Úéïéè‚°6ãÀ´©2dàŞ->İİÑ‰´¶Şå{°/œ:ûMcq¨GÅØüİÄÉkã…<õÂî5nuê.Ÿm?ì¡é6•¯ZÀ<Õ8š=’WKtzUú!•XK€‹¿XPiİë¥İÂK±ïùN {tá§Âl3wq
2sHÏ¿|Öèº@öö<Ë´<Udªr	İ›¥	Ôœ†»ÙŠzkË„2ÕY~uQ¥õ»âÙfğ•Ó¨Dt]ça‰øs÷nkİİ† ~Y¿â ‰¿Î(¤hÆ’t}¶ø"Ôh€*ë¢M9í~Åéo"Ì,ËÂ UHÂ*ëÓ¸SÅ¼û~îø&'foúíš­(¬ön’Ämõş"½r*âCöi Ë¸zŞˆVşÄˆXÉÀ[…48^ª¸>WM»Â:€3Ÿ¦¨Œ‹*T—èm¢¨·äAF[rˆ—Oá2´ƒşáŞL ˆ%œ›Âj.1Q°Ÿn<ğE/sìaş×İıÆ&
)Ê¡mó¿"vx{ÑhıjX¶x¤4ù¾†OT‡ö¡—|Üò$À»4Qe%S—¾Ô·œ ÑxáŞ”_%šÕTˆ49åZH »[0}ÃÄX¶r?%Y×ìá”¤¿>ÀS±-ËSÖ™`jñ}ï@VeÕƒd²ŞZ:OZÑóÜU!tù¡KŸL‹LÅ}ÙÙëä	àıûíX;hÌ	;ùH cP'œ1@Ô¦¼Ân¡Tˆ”¯Äc®¬H®w¥zNÅj]Órªˆó÷°œËòîÿÆ0äÄ[ˆ,T–UX=rßbîr8Ë‰e2€Ø€8	"*´|Î\`«>8ôÔ?ıë‹Ñ³kUÆD>º¼,èl’ófÙ/Ó»s\ıO›PîŒ©¸ò¿YOU*å[„5çY£X75NÈ:ÃĞÿ`å=*°‡øí4Bç”"/¦føkì‹-^x3vÓ&~Ö++^Å^×ªúAêyËGcxzèwië¹~ÛÍ)8ªĞ…ÍP¿°†Ã3Œ˜s¹®niØ§Úc˜üMyDÚ“ºÆN¨8S@œ‚«R¦ê&¤q–ùg:ôøé•¯ô_6E2oåÌ|-L	Vº¬D8	0™¼r˜ U…ÕPé!d—š¾’}’¨#ôÑ~N_„Î8/~O+ê·"ÚB~};·[QfÓŒ4ì’ l9ô§7,ÎÀVPt¾„Ö[o˜s«°„‘Y·ïÔ¡~1¿Wœêï}Í+6ÓM,ıûw/Ê2¾w:”œ°¥©ØÉqÛ³ƒN@3ÁOJëÃƒi_åwˆ'-ğ›	Ô„1åñª±ß¾g®÷‚­Á¯f¿Ùæ¸‚m–`94&¹ş°q`E4sıÂXÏ55UÂ-’ofö?¹ ¦Â¤C[,ZùŞ°IœtÅ¹ÈÄê^:ûÀÚÇZjS%€ËéiÓ"êU1¢ŞfP•…½
#ÆYŸ|â›Î!unÄaíXvÜ 'å	·.v<»#ùeMC{=–3ÔgFé[¨iTŒßk³Vp4ıwı ’vu{¶’€¸÷^÷ÿˆ(È™:<ßä@ç@´"Nc$aVæj\Õa¥PÚV°‹>H‹!¾;âĞnÍPc•ÁÎ&Ä«ËgBP;UDµéÜ“—œYá>Gdµš]°¸†>AögUQ£Ğó+Şlæ¢øÜ‰ëUzr_äƒiYRä~ÌåÀ†5Ø&Ç¿Uåİ¥m èkØ»·ènÉ"Úçç;Á ä4ªÀû(oøRˆp=Yf˜CÆé%c®Î—®™ÜF÷A$Îy…m‹'©¢Dˆò‘šhƒàÊÖü×g‘¡®.hˆ¾LÏ°ÚPCŸ.Wñ§.´ÄÎ	úw)æ¿@l52:}ÌtMU‚2‚½yô±mìúXhÀÁ?9dÍ×;ÎÑKÄ 7MGc‡oÈÂÉƒnfRY—†:@ÓÅzFæ<Õ%4'S&œkŞø$gklÆ‚æ€cƒ¤.PÈ¨ô4íĞHÎ¿¿"Ò¿7GuAeÙê7µÆ†üUUŞkÊë³yD|ÿ*éĞW(º÷s•Ù„æVy`h ‹k<up…q2YÒiû©ıÅ×¤î—®l¾Ãÿñë;AGñ$<¹vÊWB!©ÒÓÛqËAd#åÛjÇ‹¸û¯ š›r©igy‡(ŠEwÜú2KŠäDYÊ“À÷Ré[×Ë8ã–Ùw#Õç)ZdßN;ñlPß7Fèú²{j4¥ıİŞMâ.¯6†ŸÓ9³ öOhªD¥‚æõtOÊ*R&×R„ì—êË6è{÷.ZP'“7æºWŸê†à$$œêwî ]V Š£¢m³+8÷’)©óaı¸â…Í>îéöÙvâ¸Ñyš´R¢t·3é??‰‘®Â™îd³N“Ìlğ3÷@kÒ”>h	
&Â]M`®}Qî…Rİƒ³pËŸ @\È—›!I>i¨>2ƒµC<`F•Ö³¾Q©âC õ]ÑÉV™zA;¨«·±”²ó×÷Â®ì©lNÜo¸@>3Å3GK÷9hUYy. Š}%¿—ã*:
÷k:ëq1ÌlYã³EK<¯IœŠÆæà¶¾UŒ<·³NF„u0ÒsPL+g–—”÷(ğSm8ÿŸ!ä“É`•Dû·*¨L}E(éC¬ĞGLOÑ±!<Aš‡w!+ë-¶2 ¯îšÆPìÇX®KbìÿxËcïHÆğe¥S†02Sp×³¯*t7¡ã‰Ò?hÿ°€Û;¸ÊmG¾U
·œö¶m<«ìÿ !
¿z8:U¦#%;Êqÿ
€(„70GVs*0££zõ{‘ä¯xã~­²7¬â¡¤E‹Ò#†ç@b)ª‡²véuÂ=¤ŸeÒiPÖ "3ÕàÎrî™ÂËéçˆ!õ¹ñ7áäæÄæ?f‚»­+d ŸSö1]ß7ş¶5ÃñÔ’¼]ÍIÄq[U
	u‹îşbiK¶Y’sªÌYƒ¡¦¢¥¸z}¯áp¬pÀ‹ï-²Ùõ­¼Û°ˆ¤,Ÿ0,qèú6ƒ˜¨ŞSs–Ï•m[€÷áqOÎÿ—!d£Ã{BŒÌDw•N4%õbŞ?{
óË0§ù#AÙÎI˜³ä³¬cºÊ[¨ñÚVµ;ŞJ62Ú2ÇÕ‡™è	ãè¥Ë õ´§?Ä[ÉFı¨ú…+ºîÿ
ŒCãç½`Ğò…T›>Õ¡))d)W4©ãik¯™û —\bZÇxåu1¹Õ€r•ã1È ­@ØEEnz.Â>v .gõYL§ŸöéRA»)ğé[¤&TŠú‡`æ…#ÎŠZ
Î4÷ÒààŸ«Æ¤/63JÅå¾ß1¼(DÏÜfàQÍôZ¦ÉìÄ[š \]ê»B¯7"`†Ùsù¥çÉÉ*:¯¡Ûb†‚ÚC˜J½c7µt‹äpt<\$S·›ô ˜íZ·›+¯’8;Kí61fÇÕ­y¾êî™‹œ˜ø'ôì‘”qòƒqö$R$hğH=i€ŸÂ§Øå3º½¹<WÔ¾6­*Çg‘—t¶¨âø!”wí[[í‡òŸp	ûíæs³ ‘6 ?æc•Â¢¼…‰@†äÿ¤”x¾:2‹Nhµçåı»QÍõŒì®l½-ótïfĞ÷N=ÇŸ`É(g)¯zßÒ¡·º¼¬! ¨ ³|úk/ÓsÓ´;oG…ÑÔôVGô±oS¼jAN5Q¾…\è¡¬Ö¹ëYíp¿Áa…8CÉ•}ò^R²Ùÿ@u@l=³ş¤|?r±ºe¢‰Å½à[Äì1Û@GÁÙ”Cç."‘ñ‘ñæòÂ…ü†m·Ø×%ıvüÒ‹¸á0Tz£ŸW"Ú§Ò„Š¢ŠB5?É„¿q^p'HsG#2ı§Î>üsÀty¢<â+9Ÿh2öÊ­ÀáêÁV ’ÊÈôÍ5_©8³“¤¥ÈØ-Î>®µ(Š4I
×Ã–Smï´,OI˜€ËBò´ëõÏßÑ2“`ú6µ‚¶‡÷½¯Há˜c%UƒOaHY8n*·Sb½êˆ
ZxäĞ¬Bo¬l	Ağumí'¡4zòÌñwÔH<ı[ã*’V=N­NÓ‚ìÊ+Äõ)Q˜¾_Ó{'¬l‡¨§şI¹°owãñ@É;ÕÁ½Dú€‚¾Û•lÈ@bşT~ŠË7ñ¡¸¯”Gÿ~Mu*xáNàt“-w(šD\U'ºú/™—ÖIÍ–sÙxßİó–ÕÊÖ¯ZïØµë¦BEù0§—õ´ zQ½ÖKe!ƒÍùú«ß†Ë'ÉÃšNëµ¶»êóQnÌBufíåøÂ•òM€³Ô¡·½¤fPÕ }À*}ÖC²„‹AGJeÕÅ|~%õÒ‘õÀ€a÷ó1G7ÈÏ:4*ÄB«¦„¯—³åFmØåJ;€ß4_?@aÃãšü9oÀdYLÍ%¢®‡¼2j*ˆ@³ƒX7ÏÔ!|kÊÍ`}=2Êçú9Y†+¢:¾O˜6
!{QUÁ¹AõÕ(ÀŸØÂÇÌu
T¦â^v^V¥’	6ğ\dä‘ı¤ö3•àè´îTØø¬tŠaØŸ8&Z‘$o)ºX<­Ø
–.=G©‰Î¸‹pÍ„C†¼›Zêòp»F*½ï…†ÿõÜXdlY¯?MT/·dÊúh´«rÁó1œÈÖ€•qµpÀ/h›—ı–]úJ¸8B®C„b¨®Ùa©ÇCœº©îÊÙóèh•£lBÚğiÜ&‚3âj²J”z"kÔÑºÒ¦	¥ûäüPhi_êû 6ók†§d¤\½0±¢iŞ|Ëı™ª_Üd#®åÓu]–Ù’Ê3j¤ıÈ.«äæˆÊ×ö>«Ô´t_
ğ-ı¼–¥ı°ÔâÜ˜×Qõ	‚Zo¥q5ÌW%À¹Í˜jSÊñ~ƒ–İœùJW(VòÎDQ€CZL¤WÍ©^J™›Ä÷a·)|É¿ğ‘É ş&[
`½u¶€Ğ‘¸Ôl-^.ÿ¯A´ºÁü3&ª?ú²EüÏIFŸ¹@6Íúyã«ï¡µ·ušõ5ˆAçılÃå‚ÚÙg©o7 (Ñö &TFƒå£NóÌäC²dPQà(š^ ÅäO¬mF4é EÅ…İP"V[Šù
^;Føõ!W[P#ŞÛ‡‚'?Ğ˜×¾ªö:ˆO.×Ê ¶õì8Û°'&«´ešÕ9âÊ¿ı£Íİ¹yï«T’ƒ|ö/’[…*ıcuî‚Aw&$ ¤õ†B"‘?²Æ=“ÌŠæµr
éíRç|ç:dÕ54Yõ¢èwí}FU_×¢	ì&Ê}` X/€Ó ¹?NFNs¿Öë&ÂuN¨E9Â¾‘ÑN1ç¹O¬[Æ_T'h*5iÄ+ê"XsªY”»·Éø¬A¹”¦„~Ó2Ú[ûÃÏbDaºğ;KàÏ@‰¿Úœˆ´MÒñ~‡ƒx Œ¿kX|tİ5sK„k˜ÈıX§;Öä”Æ¯„7,²½år%oŸÃYKQÈ<	ÿ‰0%é¼'’´á{Jù…ıëÚĞ%*s‘N7KÎ|’%¸¨ñ6¨¤Í†OÜæ3Ş[‰à‚éíê§X€H«Ây=nJÕ[Öòş‰ef´àpk%ƒ%_|PµÂdLRVÙ÷6À–®L8áÇ"ÊDîµ‘Å÷FTLŞÉõÀ¶Ì5æè® f`ù™ô§aïó&ÆNzëL1ØÆ=* §‘äGïÖ‰ddã®ì¦q&›ÍÓ#ü0†)áNu‡ş`í{»o¤Æ:.‡ÚH‚¼C/e“¿™}­£t'³†KDÑâæŸ¯d-ó™æ¤uj")Ù’ÀCÖp½@ùğJÌ«IXè¡qxÖÂÊÛÂrNho®®Å'š­8†¸a7KÍÛyÌ±[ÕÍF•oXÔ`ì«ŠB …×Gñe®k„ªÓU©á¶UT°:B°9&ü{ôÇ{a+Â@‘p$¢îÀâm…<ğÔjB€×M·8ËXó»£üV}Sc™3G’Ïä¬Po)İu€OVéû=S&Gã;¸¹ß€UûSvÁ>ùTçGW>kİ`ìÎMu…cáÍ)´!Ğ¤¦2µş¿èá˜¬Éùù€h”²)MjÀšjŒ[Îãsò‰ ,bÇÃğ²{ï<Â–¡? ¤ÓkàÕ©üáŸv€c
—|CA…=-8W’U±Z5^‰QŒgò®O_©GBÇÙÊï_Ÿ^4}ë0eä™rÄ™¨§K»º¸¶s“áZ-ÚË™³::‡ªùŠÆ»Núd¿ù÷ıÌrtÿí˜²şuÅ¿ÙËë®¢ûÇ±¼s•ÿdã	Z¯bû*âÓ«ø‘›cçÈË9$–fGÖ…Gê5dè
Švæ/
ñ•€bF‘3y½Ò—˜I'Å 	‰'øæŸjÎ‹ˆr ûv÷±L`@ûÜèJ{B97Ëà|Ÿ¡*…È³„P”k}+Ë)·ó"ØÀˆ£ö|.œÈ³OŞ ¤9AR¥¿ÿüºx¤:~¾ó{¿éZ€ãbx»;N`Ñ†ä-:×Ãm=]Ï±òB’,B!²RJ%†7©„ÿ§9<“$)“çœX"ññÜ‘€çĞ>·³Ø²hwáé¨…Œó:ÏY¢&JöZRõøôe²<+;³¶Å€ï¦2Ÿ§O¯¤M*·š<ş9¡M±Cló“ğ©ßÖÏŸ‡9®Ù¦ChÏZÖŠ9©¬uí†T$íâtƒN‘m&v^š«.n+ƒÙ™*¯÷`6âÂ1ócÔ|+.ïL%m­¯ß="z†åt2Öu<3J˜e(Çz»©lÒ²²¬–h†0á×†!8„›I^¢şØŠœAZÉk†e¤”L¯`ÎT½Wı(eÎx›¼3¨$<V#º„Eñšä=l!º„Ú,hæÀ_sDÆÂJ›Şh–6LxC{â_¸ÂÚƒ°óx¢Ù6˜ç©ı¡Ôu¿B=V*zM$™Ó@¢mOn£ÔiD*Pò	àìtÓ”ÒK€’Œo5½7œ.ˆÕ¢RYÚùÚÜÂ Û&ºúïhªÙd *I {ÒfÖa#»ùåÁ±6		q!3Á(pS°‚¹©IÂ90>»¼ºñ ğº„ÖÚLNöÓp·°(	Á‚`Èoã×UÒçüâƒiÙ˜fWõÅÎEˆëÎ¾HN~˜´õÈ<µÔAÚ²Œ˜1\ÒÍL:Xõ,6©'6±z;1¾FcıíŞ’nµM›îìÁœaÎrà¸ä{×_EŸí„ä]fç×XP’f?NaÀjÈğk›óT"QÛäëkÇù†şÆ0„Ìº.Ì÷3şw1ı—ÆúÍ´'É[Dµå¬Ü•ÜVgWìCïö·†êğ¨YãéÄ~­~Ç4TRÓE‚© D4d*ÊÚœCf°„>"„x”ßslã<D‘&8o³–$éÃú‡Í3_ŸùòÊ?´ÏÄ»¨ã@ „ÆJÁRËíº`2˜ÔŠÜ=ÍjWí0›½‰>Ömİ5nàØúú¼ïÉÊ'æ7†ÜÌüIÂöQÅjoTñ	Ä9Õ®¹Aìq…{<*éW»İÒÔh— í…[ ÂG«ş¨¨qCíYRÇ<
?Ë„¿,b½vıìéÏP_¢_ˆ±Î3B…Iò’kƒ‚X!Ã\„«ôâ¼GH„³ ¾´òê4P2q0"–?÷½t™‹%€…ŠAfÉ´ŞRö¥È2'“#Yà“ø¶<Ù’§_j›â»¹²t-Á>ç¿øsïdª9Ïºx•uµN[…ÿ$F8Å4àJT¿R¥m BO·ø5İ\Iş¾J¬hëè÷öL>÷ár‡êèŸ€ŞI:_ƒä4$;-X3/'köÔ%éÂƒ7òmc4ŠCàŞ&¢1’ŸqIv†$ÙÂì†4QÖ¤è‰Â§v˜}İ¶º »İ·›<hÌŒiHa¬ÕÙ<rmÓsÛ¾&a8hai£ÏšáXÜ7®.æÅĞ«Å ÀÁ­û5†VskSc·}z—‹Z_z?Ø¢3ÉAMhËí$$‘ÈâG¢Äx@yÚ£„
i‘j"l¶bú
¡2Šî5nïÒuÈ$’ã‘±>“;	®·œ×CTÎÛ $Ø(•ÉØãŠ[ÇÂÈ±ñDæ>Ãö±Ÿ= Y.úúñr"'Ä²¥6ÅI•I¤ßçB²©®ıZX£Ü-¾ğu~R‘åĞşí3öè!Ôâèâñ¨ÕKÉ^êF7/¢Ä†7‡×Oî¿¢Æ t›x
äúåe”ÑÙwm9`ÛªÃ°•ÃkîËzé‚/óhAÑLÍö
î‡B'óE½0ÙyÙäõ<Î%ë¨RS7»Ÿ¿°WM°Š%W´^µØôv%M#Fğx¶Å+^¡¿Íù˜Wa
™?'Ş¢ŞÁ\ÿ‚(BÛ(²©ÿ e4‹„ğa‰\}‰O«ï4eäs"ÚYé+9,WégMÒS
B—k']¶q¨õ%çÂú¶ƒyYBqrWŠ³g#Á•SdMıšÜ´®'¨7ó3o›¢ûlt/íh²–]gç¬sâ"¼T4ˆBE/?iäœP¿aæî‡ÿIDWÙîù@ÒíäÚÒzaó²u‹	Hâlå'[…Á¿’UV~Y•yd‰¨ı:u$â@!Ò>ç…vSØ"$&=|[m“v€[*ÇÖ—<nĞp®F[9XbßA3‚R­|À‘µüà9‰å£a Yüë—]Í< ìº½4»”Ú¾¤ÁUGd”Å(œÁÈ%ì ½uµOÖË]}•L¾ë˜õìjÎÖ#¥6f<!ğ¹±õWU”VZbºUŞ‘Ğ$zWÙ¹€áÊº)ëÒf{æiš4Tÿ]óbÂÅ„jqş`}ß‡Ï›ì`ü¡à@·—Ë ÔeÌX±B–F?m]Is®r~¢=ì°!íòº5äí5şšÏ°D‰P¢M»mR¥ƒcéî2øş.Ì´!o
ŒØE ·„ÜÂÚRæ^íøÂjc«cõLDœ
rP‹Y¥#´hwÚ2 •úFSdì^,–î¹£ëãr>Sy-¶ø®/äMqãî——²ÛØ4åqÍ
0´\’ÑnÉwó¾Ñê/YK#×Í´ôO%I";ÅğœÏÛ7qH›åM{ğ>‡^~Ñ¿ó¾ã÷°`V&Ãº‚|:×\ìŒÎŠ0cïBƒ´¦Eç/í&ñG†£ú´~Eİ°ƒ]úL4pÕqo~ç?ìí^xÀ¸Ê¯@zPäWÒlDŸQª+—™›Õ§–F6rÅG^º÷IQRv™Y?oÑŒls<~a»öp,ü|V/ÂKêa•ÍCÎ^dL÷ßçkìÕZT¨çZ ±wÑbğ]:;uçkÓCf•<¥‚mm÷(¬,¢C ½Î©E-tßà+o 2ÕÌ©qFÕşLÿ]Œì/¨'ëíQ¡˜­¿±$5ñUb@ŒmîªŠŠ–İZ ÄÂj´’A÷úÊ]ª•…­1§á"]€úÌŠ6.÷ã§~A2õ5M* €Õ¶Å˜ÖER/9>Ş"™Èi’k$´Û.‘ àXcyÿØ>GÀ$%¨,ñ¨s+±ßF°Q€›E&áßÚ•î{OÎh¹êÃ*Â(4Káh7 WLÉCË©
‚ƒáZ\¯v,Ö9yL¤P35|ı6‘û	G·=¤äc}>˜í–›rMşwÛ«iyÃ ±Î¬¯ÕızJÇx²KĞÓ8¼µFqšÒp-í õœÃšwî”sÏ¢¥#½ŸxÖªÑŞJ#Y÷ê)…÷‘X”deûp‘ª2.§Šılsüv[éUlË=EçR’
µ¼0qÁš°zLu½3·U]Š;†·%='Ä|´@1_¢RQõyŸªYA¦l¨zƒØ"°,«It³Ô æ¥ù¿”Mu¶FphÄ×[P»i¼—9Šÿ6É™rºƒL™W¡–É®LZYİºn6vi^ş“h?ù_(µuRÁÇ k,1ÃÇqØ¡»ü& ×£<22i‰ôZÎ#Ù¬t3xì%½ÖErCmğ.$ÙFóG‡[“½}y…qÙ”K…J¨éğz»'‡Ø-?í_ÜŞØÑÍ›0G½8!ş¬´Â©]7
ˆ§l–r§?=^_OşÄá;òÌàj‚Ã8Ìí,Óî–  ÆlSşuîá1HÙL«œ–içIÀ¢+²Èdvb˜{y%ºMƒ‹ˆ+(ÅÀ.şßëöP}§ÎV½owÙš…'ÆÌÒˆsI(…AëLºÖ~c—FùûªF“‹ DË¸µ*ol¾íöÕàE¡
gÃFÓ³4E åªƒ,VØõ„P.l#³‰•Ú‚7e­Ú-E€¹°('¶	)Ò)~tDbo'Vı‘c±Ö[ÈsFEŞíTıñVq´–¨w°Šo¡­m	zPçãŒ/´Æ¥hÑ¨•4–şeüëvèƒKóG¿A*†àÚ“f<Gü©Ûï_ÿôü×rå—Muó:€¡€×•Ÿ$ğ.ŒÿãÒnf2Àñ›Ê¦'X²R·$î‚ûšbuÆ¬Õ¦-¨/'
‡O˜ñ•÷T#e¹,u.·á~Ó.å‡m}æ©z.·ãZºA9Óº…£iÎ\RÖÃîÂŠ¡¶æ,wsšåÊtRÁ`Ğt6_‘£$5“·;èšÖ<ıèøD=»oøQ ¨ÃAÏäMjEx	‹?ÒY‹!æ­Nû~ïzNiœäĞğöé±j[ÿ?HÀ\æÁ=³Ü¹ŒõÕ@ÑwãPxÕi…´Kèoıa¸2ñÇ±‘‹ÆÛéĞ°ì·Ÿ	éM|rF`½[‚ƒäğSâ={ ¸–{ê—U¿W±¨+½¯»Ú˜gÉëŸó†¶1+St"¨T]åw–Ç´éU¬¦«·Œz,H,Œc
|@Œ?ÖÚ;}ØM ¤p9p;IArÔx'¾X2"ëaY1+ODX/õ¿Úµ…0íÿ,Í}Kà0ƒêc©âŠ-Ç²|x—"ô¨_	ˆÀé8ÒA§6 ßä×§ÊbÀ—ÅµÕÑ†\·ÁQR3—j~£*ø´Œ,õƒ´ùê©ØO=„üæz#»i7Óa±¸ñ×¾å9Y‚ìÀ‰jD³ˆnúb]aáıc`£6°X\»Úì‡q»¶HP˜İnÌ¼ñäv–ö#:ÎşKÂ}Àİ4&+º¨¡:‡Ñ÷}s\gÍMTà¶¯¼HA@È0¬€ÑÛÿ²ÖT‹C¦É°9lòËe¾8†¨ì_}¹“şÈï9a*ê „!u¼›nÂ„nLŸUªa›i Úù
+ßÀşb0…¿Ù\—dèˆLióÀ
{g/Á†k*âÔKN>aÅË@5™	š4ëwDY4Õ›q^û(`ıuCE+ûRPsAè ÒÌã1Š|o…b¢³º£¦1‘­ÚÓš·³¬´5Éfàh4K©Úãw=†§7{>V9ØŞÙÌ!ĞêXì‚BŞ¨6úL\Tî-#ïÎL¿çJÊ'\³åQ?’yW œÁ†¢â9‡Êt˜Ö\Ü:SÍU³íÛ­=\!,Ã•J¸şKW7éwøIïšA‡Êr~…G^]ïÈ“ší~ÛPF+wÀ&+_Å‰×¿2¹NšŒJø°(^º¸sƒ^Kv·a…1{h¾¾´&§Çòµ­Ì_ÃùûBÒÂ~
´]«$Ô½2Éë©-|Ø\î¥V©à‡Iy|¼Œü!~9ŞägİÈÂ&ÛßÊ‰jàªø¼ìIòzŒĞnÀşxıs/_·6få‹óüh×_ğd»¿}(çê8]^ë£fˆ…ª Â<rÚd¹wüR•³‚Ÿ»‡P–æZ v¨Óùæ5TAäç¨,Õ>hu[‘¥9jØII¼U”yğCñk_É™!ÉúíÖmjK*JY§IT³áÀ´qq3¥\š³Ídº7İ&+yr–şÈ”ŸË¡lÅ§ĞhiÆÁQ7) Pj\½Àìñº£½Lx|ÿIT,Ç.Ì0<QÓè>)Eç´âèf!jÎÇqsâ™TxªI× &Œ)+¶š•b+št×îin}luİìš.›«4e„-OqôMC¬ıØê«JÜ‘Và0+Vô„ij¢İôÊ)óèT î.¾r#šèqŠ¡¡Á>„á™G41!È§2kÓŒÈ±­p“#(9[l*8¡v‚zŒŠ.ÆRsa~®<3ÕŠ#å<U³±spïÑª»E×¯‘“îÅ$¼s ”˜jhV#À=QAÒÇÃ%WŞBc¹pàˆ7Ü`Í¼zì–ƒËZu!¶Aº®Ñz¦Î“wÖßälËT°U¹*_Ï¬û¥ˆqmåà/ò{‰4ğ©¨^–C&Ô{8È› ~ÛÒ•`-ÒLhm„F“P”ö§0çw‡‘–ÉCñEYê‹l7mÑGºB(ğ"óéİµ]Õ@0éh	Î„ª#YE{ÿ{ËKÚ‚!Vµ˜³1”pÏikÙğv©—bÊşÑP{¡^o  ¨ô¹Rş†Ö“¹­ƒJBÇ{OÁÀZæ‰¿Ó¤â0!Á¤œ+cQ0¦jó¤=>ÀÙm&«Ã´XĞ–ì†ôÇıÚÖØÅ–ş3kj» ‡ …"”0—ĞƒñMHÏËäivâ]k†~!¿X]®Ä<#µ¿qåê`Î8´hEhOMß‹%ìWI™ğ6æù­ ÉóÂoÎ\ÄJ‰İÿÓ˜3›>:ógÈ÷÷mAKaîI@,ö˜iá€x™SJ´…İÌ¾òŞšôhdjÓÔÖÀÄHü4_eÙ($É>„X…•-Æ­7ã°‰Î²Ôm%éê–÷#ôç¹,~É}/Äªtnƒ'âŠšNıfÔw<áèfûÙàxnMQi‰ıöÆÀŞU3ÙÉP¢EÒöê'}¿ñşHµVĞøA1Ö¹	ko>Âãü	öìe!hÑ#m(X?;]˜ï§)?,-ëq¨øĞÁb–ÖgÄémQ±¼ßÓÒâäN.©¹ Ãñ[²ÇY€ËÂø–·Á=5LØDâ-ÌÌW±	%\¤^òÎ|ÿŞë^8Ö<ÒÖó;Kûxó#¦9¡à¦íàLªÙØZÚûâg„3¥_â¨iisó»ˆ·ƒ¸Y@Şˆµ(ÀZ^L~ƒõ˜…¨–tË¼À&­á'¢§áö›-A•¡æ¨Î ¿.¨÷‘÷u±9ƒÆ„ïã<ĞUş’*†{°:Rÿ1E9ıÂ±l¥ı¥	l’zzøá@u¿éF3ƒMá}à*‡Iº\“½VIsš]Ó{!ı]x:‚
ñ¦û›šé/ô$lâ®±a¦PòõQİ;ãÚ+xÎåO ¶—®¥ ºP—1aÙ$nõDé›äÃX{#ää[f½ûy¯Ä‹)•Íb$2®SÅK<1Vj¿A;^)µÒíÎ ˜X•şâ•fRÉpÿQDutr)ıªÖ,–ÃFWtæí´q‚*J\İp½+‡ Z2Hâ:UOó¡ÁóM€
x§¤C®eß÷>å[¨²(óÔ§÷õ£ş(…Î [“l³_Fİ<Í¦j3"ïX¼7mI£Äõ:òddW´>Ö"£Ç¢bÎ¡(ä6v>èP/Ş=ºúfï?ç­ì	X2–â4˜òô£ ƒÏè»e†Dï6^WTi’ïO1c™ŠDÜ³nÌáñEé ¼/´ù	TøÄÑ¢ü˜îñ£S®£ê3c&`9,"}Z†½6{sò„½²!½¯ş13PgwÈóvÇì˜Xë>j–I>¬üfÀZ»1Oì;U6±z]ïPÉ+ÂÖo=½6}ÑVcT1­+ÿÇ¯ú7²ÏæA³"Ab×¼œ@7xÜ»ˆÅëúÀÍp€†ÕË’ü¡XœÔíaá{W éXk_$;ç‰°ªæè‹s–ŸÈT{]-ígÃ±mC›ñKı×'†¼'²+!bĞ·%àuì/)õã¢½®42Ğì% w² :E¢N/—Ùºoæúé[Å*ÂÅ¿İ™_l¦Á[O9î¶5wá½üDn‘náó&×Z*ÂÉ´€_G¿ê³„¦¡ıY1‚‚}*d¦ê»¸•x
–¤ö(fI1PxÈYvÔBQ<İØ,®h.c:ğuRÅä»´ÎµqÂíÑ_(ô¶N(\i“÷uÙQ¬ÙĞ©°Xß›Íº—âµ³{õE“Lúf=r€°zÏ•#Ù‚|6wÀx“s—%·LuÛÌˆœN¸ú¬K0–düu¯`'g†I÷è$½·}Gš`5ÔüQ*;ŞWáÍŸŸw/J/VXZ‹àÇ}£  ×7­·o–!Íö0——œÎ„ ÓugSq¨>ø.!Ë¬+¯_%ÁÉ°‘ªÚñÅ§æóf!úÇ”a °:×E¯y-¾ú?›C4é:õräfÙ6í7öK÷¾Ú+ªçD°yĞ£AF†î7æ¦9¼#j¡$>‹·™p*í,j‘á©úµH%±Á	2c”š|ó«ËóÁ,pz°‡á™î&ç
|¹w½ÙßWM”JØ¼A…"õuKÚ[ª÷2„ZCu½.Í15©AlXjÌ_Œ‡ËáõÛóĞ4ú¾ûœçVÿ¬™4‘„#Ib·:‹¿ÅÀÂå‡Qä”/Ä|¬a“áêĞi|¯uw[ìÜü?’è±f=ø¿@0;ÿr­BR—
d¢ÉYì²ß\Üıyò&ÿX/%ò]_ä÷ÎÎm»œeÌÎgµ‰"n)3s×¨é¾€—âêV2•óšFy°%†uVjª²$`K„"dMŠéÔô£¥—| ”!ÃĞyŞëißa°&]u¯›àP5m}mş3ßÓtYuŸ^îÅÄ
e5ùËv¾>jİ'¸Ù­~E.Ìª’Ë¿G×§S6zÛ2^Ê$d5öÇ{sZ#VP…e”B$UZ¯v;SxÛÖA‡óÌ/2'´ù€®ÛC(ÇÉ¾sî”Î$¡'Vïf“!ëïjH¤óe¼EÆfÊßE1"ĞuÅªágÃŸõìÖlOI/
v(Ğ¾rc1P£v¡CÌrÀÉ”İÁ@zHŞ§a
tñoĞ5în¾B×]ÇØéEYí;Œö‚Ö
ü"ÙÅÓk8é­§ò(Dèê¯*pWjÉ‹¨rKfğ±¢1hÎ‹’ÏxØh©}.ÎÍo Ú{æ`l0 ‘·`ï&3WfËÄµ{¢˜€O¶ˆYúŠ”s~2‘Ô!é$H¡ÉËHö8®³ùŸ]:’z #~ædjù¤á•ßçùë ßfs%‹X?â<Ú±zôXñü°%“›è¹w&}ùm÷:ñÒP{fÎã1ïé³åS?ÎE‹;µ1°\Å,KÉ¿3ãÎ&E|…ş5«pK|\x,Ë—5:OõÂóßÍq´]:‹Ìà£`<¼%¾Oÿ´E2ˆõ»À8°“?+„lä›"¢Í:.ÿµàã4dOi:0øsè•*65ëÛæšè%ôıü‰c«2Œò8Ñf÷jêªPÁ¨¾ò|Ç†„»"åÚ¹4é¯š¢ãE¿Ã¼¡gHÃh—ûp$¿‚dWƒHhjB4{¤ˆ‰^Âœy^Ğ1~x	ã@ô9}ËïS
éµ‰H’‚‰òoï¦f|²óÏ=²âú>™$–F‹‹¦=qyF†]/‘ƒf-•ô½­‹2Ö@ÔÕÚ¡|R*ÑÂql’]guÇkdP-ÄéJ!d˜z¹Täïó²q‘o‹ÑÚd1ÿ®·Ê»éLÆ'1Q,|³ezøÜ<B ÌG¦µ,%³.r¿×ĞåÆ£ıìb8Í‚]œ7.lƒOn­F¸¯Äs‡qÛ/\ææãô³*ğ`†z¦3m‘]”Xáã^¾†ìã8|Ü_ó:ŞTmÍt†¾9'âşP)©}Z=&Åğ7Cm·û©­R…È´Z
2İdØ‘³%¿mÇ6£xIü­=ä¦-rÄâ¬—§ÊÓoàäÄ“¯†ã³-¢•¬•Ç; nıØbò Fvv›lÉÄLd7T{ıÌ©[34±²f2
IÎ|l‰õ‚ÕrÖ…IÚ¨$`AÒiÒŸo9D°
„q½Èä¨±áHğvÆÓ©Ä&êS‹ß'ƒÂ&'&›lıBGÄÌ1øÇİ@]9´Øs³
íN;åğ†¢ÿÔ^‰Y;T¢ßŒ«õ°›|qÉ`nH{võÁÄJ9vo(©ŠÅ›—€¡taW®fR¤SDÊ“$v•Q
B 4LwF«êGro¤ªÔİçÑœJÏÛ1‡ÌıŒü¢®äjÔ”.?2€2ŸºãËÕ"oº°C#m[’ ÁÂÄÿD6…(¼jòsï=+¢¸$ç‡%2gf¿ÈˆÍl\6Ù<D¼£ À­Ğ­•1ÒRµíÚ´‹ƒp˜F•Ùp‡©¯n şÀœÈšš¥ÖÏJº]M³w:êª†0ºVO_¸ÀB·5ÃûÃ+¦şÿ€‚Š~MÄs‚C(=şEÅ9Ÿ72J8 9îäı{(9kü C¦®M*ù©…åĞş‘oåÁ8úQŠJU"‹«J„ıÇeÆ#œ÷°	İÚ8Mà¤“†¬»º=õ1Æ¾	Zö ™Î,ç0LÏİt38F*-§?Ê^5db@ÆW¯ãîâ„J~EÉÊûc.güCñ7M
®-dšòEšî^¦1‡¤Á÷C¸•¡á÷“5_çJu÷B9¿-—ê¿Ö	¸ÍÅExØÑÙÍæ_Úú3Æır"8¸‘hÜºIZVÜóu;Öò¹RFóO“»Âı…f-&ï(z†;qÑçfA"•ƒí•ŒgÕGBL3ôxKWôÒáRù¯¿h¶KÙpÍuöa+¿ªáŒ‘·şÙ€«•‰éı²+0p“?>–EÏv›‘Z:;ŸFõ­0 ¨‡9L…¶e‰—ë§¹çàöŠğ}¤Å¢û¡yp*œf ÿ0
ï ¨ˆlì.qâİõ}*tË@‘v“06 „_PŸmİÛœ=X\W’ËÌÀÌàâ–ù" £Dü¦*(‡ÜôÆ9X|Ã´Mºß9f ®æ$èl8’‡²İ`4dÚu..íÊû¦VQÙP”IÒŞå*\¬–nh=$†ªã{l,h†ed‘©«7ä‹‡­'ÇC}Ìã\zlîûÂÕ.ó˜¯]“¶%§^F|jùKŠ²µ5Ä>råºv‡gïğ8ùR™!ã’¨iõLÇŠ×’
®dş4ÉH’¤Ğ
6Ü¡"´ëUßnL‘™Úáˆ¼øêÍo_µÓê‰şk>ô‚”O+:ÖU‹#Y}$.Ê@ŞÒ,W;{tHüÌùÑİ	’=ò…Fw(øëÚ<Ï+ÜYï,J AV‚i!ğù»^Ó¦¥¢?(ÿ{Ü"Wd“ËÄàıŞà2Dì0%ğœ²fÿxğ"@EÍ¢İ9£ùn¨¬ÈN`ıò£1«¥^-TñµÌÔİ–5&%ÛÕ¤L1ò;y,|d5ñ•Ÿí‚=‚¬ÕGÜ?VßÏdø°]KPÎ]FààTQø ¡,C{):ß^ëÈÕY¦ğyNàÛJw %,O(¤Ÿo7âT«¿ª"½ÿT­¿_Ç{åtÂOvÉ$èã:í[ WÈÔ=~µY[WröŒ&g•€Ú?Á‹Å˜|4—<ĞÕĞÖë¨[‰ğG–#šXmÿÇÔ2ÛğünÍ:Ÿãô´S¦5:Ö‰j¢NEGÕœ”>1ò6ZËzïØ©d¾Õ_ƒmşÕ·"°–[o"¸'#ˆ—QGÂ²”w¤®.ÆŞ™0j²ŞâÀ;Ó\ûÌ“ÀñNŠ¿¹G²:¦ËïÉ>ä)Q…•6™•¶ÏÀ¦åñ•Ü¦Ö£X±°eu7ÊæèÊò^o
€ÕëÒøˆ –mQ'¼İ‹ŒÊmEËà:iİÉÆÊÁ„Ä7¡Ï£İoÙ±:Ğ`9Œ4±òtké²Û9ïe?“yû]ÛK³X¼èæ gKRìõ—°?W#¬öİZsâEŸİ­Â™ÃcVû‹Æ‘*–-ÇÅ¿ÙhÆ|I4>¶	šÁvl¼80\©Y!Øq~ãƒÀW`ÒkŠgÎ6Úô+İùê7‰p#&àB¨8øÌ6Q)“m‘PÕ¸çäıv×Ş
Ã¡@sÇüu uÁÓD'_ùö`É(É§m˜å®ãsp\42¢#ı<Lˆà3´Øònucêgİ­6-£Y´U0| •1\¨Tmİ³u	Ø»Ş§sFõbÚ]®ĞO¬*Tà§Bâ¾¬8º(4ê*»êÅ›í¥Œ÷®ó”dé…Ò±]1?x”¦ú­ˆ”päYAÈ ß
FõA­a-ğÔ“€o¬\ŒCBz@üÄäÒ@ï¢¬¾ŠLfsÍÑ>jxÚxî\>ùæ(àD¡+['ù6>Êƒütÿ`‹g¬î½ÕüÜöÌeá0—õM$œsyƒP:¾p'êD%N«EÆ½¬’©ÄaNØ5ŒXÃ?dÓUÙr8dµŠ‹®“f¤ÌáµĞK¼•ÿx*á–Íò›íÓdc$+Áuñ{m×(<‡_‘[¹OÖô[¨‰h‹bƒº¨tÏhQJ¸™‰öŠ
e³%€9Co!À€Ğ÷ŸúF0û\`GdäÄä#!–y•æSS‰ùª¡zë·ôÊ'òò‘.XË±Î§Ìª ìä¢|¶é§Ü¯±¿Bû78 zØmãUs,ÿˆ u[scş¿
H 
!0áZIbûJÖBÂ‰3€¾ç-u–·°²<å6_¯é„^Üî°*SJHù|æÚrĞËùd`nÓq†I,+mÃ©y¼ï«R?GÏÖQø™Fêèx nëQTiƒ¬z<–, Uâ\¦&ß{ -¦ÄmòÁzµê„_£-ûŒ{HK·İÛWÈÿ¥Í9;nŠ2	¢œŠ!H‹–íæeÚ	n~6¿ykêÑÂÛÜ]‡Û4²ÆÄ‰ïª¶v‘İ6ÒË¸>tˆ_
(¹óù¼‹õáH\oªvg’WlX7øiò×íÆ%Ó¶F.ŞÁlöwï¨¦¶480-³ñÂÉ¶[Œ<päYOŠJ!5éûÂŞÇ;h+Ÿ#D;÷ÄìÜG^\0ÜË/Å—z¬7#³olZ´‹]³¦½Aâ8é´ùÕvÎÆçèíŒñnTë›õ$!îû|ŸƒØÀæ*w‹ù²ÇénšRGÄ%Øë*zÍ+	5-óĞÇ~[½Gf9Û ÈœÄù¦Ìõ¸ùÈ÷*Y/‰üi¦øĞ	ÅÌÖç‰ÕË*ÑŸ™K¢|cZ•3$¬j‰æ™+q¦³x>ç™cF
¢©··¨zD'ÏÀÕÙÛ»¿;¥ìË¥ÚÅÔ:öˆ³Ú«İÄMv«_o\T´B«+ Ue°Ü-š„|ê]=D>Ìü‚p
8
XnÃS¿ÅÊõu/©HçÁd¸c(¼ÿ5utšßWQû÷ßõ/¶ZSîëıô Ì³ÔçğÓ[»<Éx>|P$šìLdæ¢«È³%HÿL³
í=ÇÉ×]ÌËfÓL‡-—:2ËÛ&8²9•h<Ú}‘}$¸æGt‘„Û[™Àë•Ä¤ò3¶ÿ@`ÙòZœï«­Ôş­Xæ Ü­µ,aEJ™zg£©/9\ÌŒÊöC–kÁE^OFĞ¶ß¨Y K‚ªÏ6}8‹¾y¿¤SÍİ§ƒ:çÆ9}2€ª¶7‘çæÆ.ˆ%.bh
y™&>\¾¼œ›ølåDÈUíõ7†RCÖ
5ˆ†_^9ƒàì÷&f†<†ÙÅ9§2+­‘â —æI`öcşÀÃô	Uü²ò§-™ú}N³Üş/]ïÌ™2E'ªkî3Ôà¦É0ª—ŸVTŸ
ÕúÜçs9/?	;¯ŞŒŒn—6	á˜Üj¡å½FwŸJEïÉÃ]Æ´e‘Ä;Ro1fó =¿ÏÕÃ{xãÚ^”~Ê*R©fT À¤Ä6ÂñÁG.béÔ²<òû²œHdá>YVÆ!D¥İD60#Ã/Úù1÷¶ÒñÖ/µÇÉ_„i`ê×ĞÍyX_Ó+OĞhÁg²Ÿ5.R o2çáN¼ŞpRvµ•<1yO¼«Ñì¸›(¿Å´o;^JÕl©ìÜE`×¡¬ôøğ¼çr®Ø†X©Eø\ëá–!Áƒ;ıãÉi´¢’Qìbõ{;Í˜Ô=I´€‹	)C¤~q“ªÛ!0…2ü	é—œ«‰Ñºº›û›*‰¿„!§
Î(^–ö­ô©>./™ü®Q;DP
ÜKÃ»Ù»Éİ“shË[®&7ÂöCJ„YEâ¾n“:€/ŸÍ).˜¡Øì’AáF<÷àÃ+¯ˆxÚç˜üÊı‰-ıæa>¼Á¹ö¶Š*ü·ô¿yp&qÊíÑªŒqr¸—ì®æ´IŞê#4!cHc¿IĞ 'Ô‡\Ôò…û,q;a_“WÍSÈ Ñ?Û«v­	JşLö®èãmÕ-åf0äxwŒöt4-vÊP¸½ö‹"L»™Ôîn¥½T!SôÃ¢¿·¯ï‡‡nÄßVš¤¬ ²uï§D^"“rZ˜ •›ñL òÔk{Á	¸:µRî-éÕ]v15m›³)xcÈ%öëtñEÍŒÎFƒŠ—±šÍIÌcÌãæ²ø¼öòîJ±’ü'û´Œ?³ŞC{œ^qŸÅÚƒ
XK`Ëœ>ßUÜ½?…5ºq<>)òëÛ"avş‚†IÇ¢õvIq0Ÿ‡ÕÛ¥K~vMÜ{q	¡ş8ÍP¦v|½®vwËaKÕn¦^BÓ3Z©FZÃÕüh-Yõ°Slla-ÅÊßi¹tÙ5v¬—xJÁ°jIÀƒŸü¹Ë3L
;'BLÀí‘Şô eÌ_bÈİ“™Şóôçxœ¨Íuª—(Ùî°Á–K«cvL®©°¾ğ&¥ó&Ê5\Jc¿¶€zÙ‚T\Ğ)òÇèg·¥Âª¼—×¤d|ÆÜ¸"&øÍ“Mµêî˜šd‘Z¹Œ‹R—…·‰gå3i:¤õã“Ñ›*•™Èã‰3 ,Ñqk°}º“-àQgc~X$Æ¶»ï'	<e­B)$]Œ€‚wLu8‘cÔé{
 POº%Ñİmé¦ş ®A€	Şš%@	àô ï¸ƒÌ¹Ç›x¨ĞVq§³vY¦"‡8g¶‚Aw)$ğZ€¢[ŸM,îÓ|'äÂìši,ÒgM½Î ½ ‚ÿsÚ(&ÉÁI¹g½TfZˆ¹6’•Aò«ÆÔ1²‹YÏÿ
7h$Ul÷B0ŸPÿ,^šê¡OPD¼bà±X‚š˜o •‘ÒåZƒ(wjÏ»ÁŒ).Áëì¦Ôñàl=Ñ:dc¯Ï¡ÀşcR™ÔÍäNaœ7¸ë&PNcĞ:RØÃj­äŸW|I\àµòQ-vÒ‰Ü5ÓFKÔ–7ÙT¹·Í <–îE6™ 3ZÒäËòÑ@cÊ”6“º%1ôƒ~òm%ux-ı¶3b_ÛÎ	úS	òWpÑÒ,|V_ÃU0µ?X` €aÉÿ¸²z×Ã!aÑ{{3'À+…²ú¬ .¦ñ¶.ägŒ«X:;/‚‘\R€/a˜ $(`O%¦U}¾ô>—ğ0ëêr„âó&‚\@_Ã˜š•
ÆÓ¹h6³*Yèä¿$ã“wg³HúOînÏk§Û*e·r!°gEW¹°ı7»A¤çãîÿî\Äü1Í;…1X[“{sÚ\û0H¥fÃş"á<‹Á,#ÿ ±1°D[d”åâü…Ÿ¾÷¢npÿ6âÎ íb)¹ñ¡ãˆÈMÚe=»Ûô1Ñáx®ÎÖ1›l‰?ËÙH‚š„˜µ¤¥«¨åjÑî…Z\Ï·ÿñà"aâ-`pUÒ¶Å)ÀÁ÷Y59œ¦ÇŠÀá¼…Fm7àm’'M›6„Ñ†ÄÕlšüŒ]’‘ĞHJ^]`9³ˆ/‘b®&£Áó”±AÕ'É«Tí´é°~{;¸ûLcj)+ı"›Ìóû‹LxBëÍdy;ùãÿN!tãÿßÍ•¼ñ«a°`îç±øQ½vâ§g
9(n|ıÂÄêÌşeûxÜ™X
âŒjŠ41Ë¬°‚0e©§’ÚİR²¦-Q©©´(%òÆ‚£!`‡"òÕ€°îJêÓ6. Øİk@™5]sÇ8ŞhåÌªló5‘:ğºÇÃ†õ\1›o¥UŠÛ ÛÄLµU0„úŠLºû+°¼fø»ú”!?a–J×ê×"o¶(4üIR©İ7D,îöà¶$mCÁğÑf™ôBÿ¢*3Šß	)“€=òB*u~ßYtS*š‰X•¨‘ÉİæàY6lù
0·`úßQ1®}^5ÛÁcQ]Tºl;ƒµî”Ê€°î®®ô½r•œ‹sc/~'y¡z[;‡¹˜e£ÖJ.~2óã;Gr$±\gà0~¶â&3(œ‘Ó§(]h*P“‡¹­œVÊPüÍTOÉâË:¦œÃîAO·ßSªĞä©5½…Á$ŞÏxV¦¤Ï1ÂçgNP`ù¸áİC®É_`²Íów×.Ğ¥²ÿbW|Á:,M½Ò…_Öİ z• ¦¾gú†’ˆ¦'	õV`ùËó…†vöÑZ¸—³2ÜH'¤)¦$uçÁ0=ÀIå±LKÂ°9Y£¸¾eµájûİQéœİm§;Ş•"zJ4ª…ò(Rƒ0b¿5û•Øşg)„ÜÈ&ÄßW²lş²1’úé£å™&(ƒƒ´X„mù<X* @+~ú3­tÅ›ë(ş»Z¹KÍ­š•V†ºÖÀ?²Ës¸–±Êáš µÿcÉz§"ËàÏ¢ô#%”Ğ„$[Œç˜§¢«“o#EÂ%àKÈ¦Úbp©[óøÇî0µE£øŠ’‡ÿ”<ı5ë(¾ŞÙKOàİšq‡‚R]ëë(E²ÿÀÕëØåJ2!3¢™G¯|í»Ğ$)øQ²ÇQO]ä­HJÓAMÈò½¬‹öÕYñºßqôøŞşU#!âºûª÷\P„½QL¶pêü\âPœ½/J÷v2_ş\$¶_0F[ÑR.®=‘xÕãÏço7Ï»p!‘{±¼søÖà]E×ªdxÌÄB‰Ô ‰…ÀŸj«ŠNğÛÀˆ0ÿzYÏ»şì_ñÏÔŸû‡Ìdâœô¢ÿSjÌ—#@å¦F{XònÒs¯Z‘Â4«î=ŒàÏøÜÚjà5B,ÆFƒ³ú¨%¬w ñ.r?)zbÇr	dèS¦Ïe4NN!Œf }BÊâ}Ğ„°m§\%ïïx!a¬s¿.´€Ã§ÒÁ bs•7V {ò@­¹¸•0“MM¬Ñ÷ÔèÎZId&ø—ÖF•f	İ0Y7yÊÂüb¡ßôR¹KØ£rO©&)îø2z“?İEMH¨ôX£1j7©~·Zƒq¢»<0ß€Š-P~$ßIñ¯%!v£ŸQÅ³ç7J&‰{ç‹>Šˆ÷Õ¬êVçÑğ$9<ì™œ¡…ô®ò&ßW6ÚÁÃÇ#œ¨–´Ç­U>EŞ³&X†øu¸Ÿ²ÖEØ2#·<§“˜YpÉ’„‹LS_uĞÜç`öMºŠw©²“­Øzé±X=Ô|¿c®¹Å(‘®.Ú'^J¬hÎ½l¾FàáEy^b>b|ªŸÚûn›:ú¸Fz½ ]TF#RL†nä±ÅMƒ\É²Ñ!@”+
ÛÅpĞ]™£a	yÖ¡©ø¥jÓaÍîº_?ëDº©Z3ëK/'@EÑ(vh˜­­zØ§ó¿ï•’èñ¶Fô¢_ºlzXTüØI	[†*±2Ã»Ñ]wõ\ùÚyÅ5Ëlì×şBq¿ºaÊn^ğsß_è§àÍËĞi¾âí¼íãötÑÔú2Õ‰ü;ÃÅ·¿± -ò@Ô¾… ®ÆËnrB¼H™¿wø2ŠËÿÌp.8W3l€P°ÙórÙ\£§	?CÉ£kÂ@ˆŸõ2t4Jñçšn´5+wƒ¨‹-ô‹9mÊhK}§ôÀ†?úÔØe Çú hÇ	ÜØ3©Zhå¨æ²DÚ§G_òÊ2ıg+fuŞ3•ÿmÖd]Šğ ë(şğ`òWøÁ›É2¿ŒÖ{ŠÙs ğ¯IÏùëƒ¡m¢lñêE¢~SbÖµ‰b¡•OÌÀ‡]•µ!-BÎôúlğ±šd“¯·‚ÑÚëİuïc‰_ KGí¾¶°#¦ñßTm‹jÊmc¡qÁˆÇ¨pª®&4@±\
DõdpÁ¬ÃçPíñ!bîjÄl2F˜š\IX€$òâÆ‰¥É3`]¼¿ãs;wÊ5~‰}i´ï<~k	C¿J+ÁÊ™u™:a.ŸOÕ61›^q¯Î¦è6×çÄnc°é´¹x†â¨¸c5n gğ "Ñæçbi™Úé+ñ
¡Xq“r`óhS¢r°ÑõÄIÀOÔ§RáZc/s,$ pı2hd×7t¢d}>F]±(u]oÅuã)×NBĞÙÀ†¹s€=BL½ÖqQ¨C7¦¥Õ—ócUyÖW¦îóñEÑ´Û7å‡¾!Có4¶Lı[jó~¢ıIlçÜ‚Ï¡vÌAõrã@ˆ|}• Ï4¦/«Îõ°—×ÜÓğTDÖ6¿mÀ ¤QgJÃÔŞè›œæ~ç6¢ƒß£È§
•Ş7-ÊÅ{4fü‰ZZûj®ÿ3\ã­½»cA—y›¯ñd¥5œİOVTöZßù-xÀJöWªºJ*õıpsu)ê#Y¦UFÌµ¡Ÿ7"|²âp½ÇlIE¬Üv»#F+_¡<ì}ğWŒã°/;n‚j}åEÈi;ĞŞÄÄ¡ähö{ÜP3ç/÷.ô$ª«…·Qi’H:ƒKO fµ9ò´&lIˆ2õ-Å[±@>Ì€c	•à±‹¿éÒ¶“÷	Ñ|º2ßÈâ*x
‚ãa:7‘ÒZŞEÇ®K¦°Íó¡š
O~Eã½|İr”ÙìC<´‡"[¸I–@o…†§Ûg?¡4¢ôu–¤‡ÀßZÖ ¢N€!IX›RuÒwÖn&Fç·VZÁGÖ3ÀïGŸi$$!GhRe†¯3=t\(zVâº üxb HkRµuŞ.=c¦/:ïË"&İç6)ø²\ş‰›k$Ã™Á¢A¨2ƒ¾ÿ$ÃUgË-V¦¶ó%=SŒf»Ãèë€Lˆ°©Hù&3”æHÁ…4"İGê7z/öòÇ>Ğë>Ù ,³~Mÿaœ»({ÒB]ÛvspVyÂxm’uAm`3Ü‚hˆ?[û¥ŞHŞCOåó#ù¹ĞZ/#hÖ%!ê¤aÑZXÓÁóÂËqN¨YşÌäÓ_Ù/|Iht¡?]á¢şÛ	XoÛ»>!éÍô°+Aáq(ónß=U©¢±şl.êš¨/¯3ƒÃ·™²oØ¥Ÿ0ÍƒmN~`µò¨qìOiÇN˜ƒ›Ôo^^ŠÊPGøt›v>3zD|_]‚ÏÍL ÓÙ[\ü.RøÛc`OËÆB‚InøÅ'àÍZsRq[ï'âåwhóÑ¯p¡dRânè×'·‚w­/®y¨ëõ%¿£sµşOo‹6ŒSCl¡ÄÖ\ÁÉíı	ÿ€j…¬±Ì©Lwbc®W%F(`Ö‘@d¡úr`ªĞ*á"ƒ­H§’/_¤¥/„¨î>c•çpf’[Ãpy>r™¹.PfÂ'µî‹ Ü÷¬it×çú60nté N5Ù!œ_KÎ±ü3ë<ÌÅË(Úy²	½|íÂ¶@`DŸ"”à†0ÙÚ"&İ|6ûğ+ı®™´~—"¨~Ê@MF9UK	R6¶a Í'Öò5ûÀ£4!³˜ĞFUTdª…¹ã5S-6‰I,:õbO0ë>xaêCÀ¨&ÙO§ôõ’--mŞ™=Æ5rsi#¾òŒë
Öä·iX(zÈ¿3úœ.çùê˜€rM»‘ì4qæ°¿IË±3XS{¶_Íêûoz t‡¥²_gµl¤¯"¤¤zü­£@¶uR¢½ä£ääSÈR=£ìÊïb¢56_ç»Ô€œ#ô2Kô/mï‹ùs²§,ÚxBœÆŒÜÕ†Æ‘ğ	ú˜IÉºx6v·kÑûê^só©L‹~ÆqÄÇ4ä­ñ¾R½ƒƒ´®AÅü6İM°ÖÕí8wË•(–S5Ğ$¢2ACêŠ”o?²P”¥£w”~+ºãÕÓÚÁ{ÂräˆS“‘õ9Ø¤@(.ØúÁ‘qMì' ğÖFhËtú´}T8³ÛN‰9÷ıGoıx”ÔíÏ:w¾oåM&CÙAÛQü'èj &>›5!@ë„+kzqQ}œÇÇ¶ğÚOsŠZÓæ=¸Ç„‘õÉw¨ì¡ÚºñX†âFmIXÅIÊW¦‹ÏÑjÅDŞaÏñš·[Î¢tnù}qS”`û´£{ô(-:íÆÂZhbÄĞF¹‘ßÆÙsÖ.wï›»Î{ò<½×³»è$ÿşeÀošzõ!ÃÑC¡ğcB‰™£¬¹2DÁ&²Hï§ÏBYÆ¢şæ8ÈòLPRÊRY};¬¼aC íÄ({h<ß»]ûYMú
1&ñu¥\¨©¨<ú#¬§å«¬ñĞXÛÎqñ¥ğÃ8<<ÎÒsÉ[V³å¸"ÂF<èƒóãJ¦b7dd5Ÿq+Ìn{0jÛx³pÊc½æ¡¶í²ÁÇ{ş•F…“®Q•[pZ›{mnßÉ.ätk‚Ğç©òAX?”lî¡(“Æğ£Ub#Êµ/íßjrÃ\+ÎfÜ¨TõË‘<;İŞÎ"ks¤DZç„Œ3hRs =@xPd§-s§¡‘a¸Ä‰+3À¬Ç/ı[1#Âq,ffÊcÀÁüƒ¹ægı®¬‹à.ê? 2ÍwQÖ1±ĞóãÓìcO²r0¯!´#¾T2lBî|$Æ5î0ªª‡#f2†¯‹´ÖñFPÌRòæ¹³€@Â`Ên :ÇºËrs.Ì£Ö=ÂM“ÊÂ ·¥›®F±;ñ…±lŠ\ì<üŞÙ2È#AÎ©±§SÖNÉ,#¡—æ×\û°@¶ayÂ1JÎØÉód‹ü›ò·k„dŒl+ã²y>][n?­—…İœMc\›péX¡M®°û¿U„ÉjåØ¦{8›<&„Àœ<VpÜu–ÎÅ¢Ê__töôõcÙ	–ÉæÌ,FkuUF‡üõ8t˜‰Eu…€G×[vÚbüZhÖy°R¸=å‹@Âï8y2umU_D*á{ÀieÄu_ÏİVD
ov ¢ÙKÒ¨J·pBÑ¬^[†Æ£W‘Vá2ğ9l;ç=#mŞj~¦ÖiNïióğ¯J”3ùS8ÄE_v]ïw¯7kÎ‡rúÑA±`‹Ø<ºXšWÀtãN`¶şáÀ—pG{âa$Ÿ4ûòòzD5,É2šf™ f3ÂgàX5àIN{›È4}³”Ôx
.+,«€
dOÓïmD#@`öÆB–ø ?À*Ùô^ÀiUÜÖ‚±Z?€§ÙÄµQ$Ë4{É[Ö©÷x”×²]óÇ•Œ¤°W&Í`gõ<O².+ó¡Îğ²Àºtº©ù];Nëşıÿ¦lãVvômÙIê €­½Lp\r7í ó:Ó±#Õ%"AR     ²úhB»³} Ù¶€À†Zôe±Ägû    YZ