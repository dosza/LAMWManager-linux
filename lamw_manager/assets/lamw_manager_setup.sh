#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4060017608"
MD5="9971d06e45e853e319a2025d38a7ed09"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20440"
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
	echo Uncompressed size: 136 KB
	echo Compression: xz
	echo Date of packaging: Tue Feb 25 02:12:34 -03 2020
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
	echo OLDUSIZE=136
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
	MS_Printf "About to extract 136 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 136; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (136 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáÿO—] ¼}•ÀJFœÄÿ.»á_j¨Ù`/‰<òrS*}¾7)È1ùö7 …^l'İ.í*&@¶À5
‰šn–ô×Zÿ@]Ì*ÜgC?„³ËgÄ¡Òùx?jt rsş?Û€“Ï¡óMşä*ÁÎˆ·2h×Wè|,ÎycXáÖ5åòílú1åãk³zu(˜Ü)œú³yUÌÅ“ÀƒË—C›×+ÛÅŸnİséQóÔ¢’d¥ÑùÆ|I38Öü]KG—7×\;@z6pÌfIyÛiFäÍ™Ò¹{´bóüàò(k5šçÓS-oâG½9¢È5+ßğ^‡;¶'§ëéªIôoF‘w+åÚSG!ıåéÑOÈİ=¨Òí):f& :RÄùê‹1nR¹rúkÒš'›>"óútíÌºÌ)ê©¿†H²V·’çP®‘vÇ­ÄÆq÷yƒÃ’ }ó <S¶d¬2’œ3Ô@€¥`l–ÃõãÏİ³8T.¡'&mz…õôÆÈFñ}_s”#J¦ønOğÌFëë
v¸$)/E1©+êuGÙr//uui6ÈzÀÓ~Lí›SÒk­ÄÔ¬Lö”°>ñ?İìz¤šVöÉ®Ì¡W½¹ïüœÑ6áüb…Óö={µ¡mºƒv±·P:ñÛ¾¡$-4CU0Çœ@Ò¥4Ë“dÈéüêwuXşˆëŸİ#:İşz~¯öÉ,;{nd¤7aR’dĞºJ™[¢Íœÿ$Z¸ã:F^Tìÿ(hf:#RYœÿJË~§#jÍ<	 ø1ëWÁ™KYÅÇÀ1ÔïxŠ½’çP'%!ùè eÉşTÜäÈÌÉÚá¿	eÆÇwi¬Nub"+M&W»môûô÷ÆÓİÖu³½5›‘cß]hÄêpÜQZ},!ßà¿7z£-ì~·4g$Ã˜¢Ù`³¨­Å›Âee_¨ÖÍmÃ§]‚~{ÒT:×]Dè¹™§=„ÎtÅÛüúèDIÛ»÷KÂ¹üğüf·ñ¯Õ%$ıßF˜ÒKUEÛ’·4îîÉ<,(ÿLÔ-W%
”nO@-¸»Ù0Í|£W^œX€oá‹ËŸİ3w4Yç4Vé8õ#âHH2çjE5œlå7á)Ü:
ñÀE;µcPõqÃ‡ÇyÖk)œcü’Õ…'+F™·¾Í_yÖĞN4¦¥²$Ac¬Äá:¶¹Ï£ñ¶—+®OŠŒ(ˆô‘" 'CjmÕË=ÌÜ××ıMîÓ=+ƒ¹$2GXwäŒ®­ÅÍÜ¾7qPï.ƒËîrT^KˆÑn•c’ª	Ş;·
ñ¿wõ<ş(æv£ß|°ió/Q™k•öşV¢­Ÿ{<sm9•¼X5ùRÂ³VÖF9\sÓØ«¬ÅWŞ8	A"KëÓ³.K%¶Ó;U„¢š¹pZï÷;øÈt–¯
a…„]sOfºlÙm÷—ÍŸâ
 ¶ffˆçl6ÉÅøhDP9u/ZeAëOâê_•°´
Ü—’°,)åw–#ßdã¥-	gókVÁeÅ1T—tD[Ï|=4>v¸¡ÜeWV3˜ö§':®òÓ ]JÌ¤}\¦aÖ†4Ò2Ÿ“8/şğYpD‹´¨ÉUHâ¼ÑxÔ9xX7¤ê9§j‰üU^(j@ =¦Ã¡¦AĞş»k`'/òõ|Š»¡ên wÃİnx@†ß@³©ºk¿_ Ñ÷nÖßv†¥@Láíz¦‡æµ¥!6¶½C´¼5bQ4q‚–rçû ˆ»ƒbğo{:C2Ì,¦$•"öä«ºP:`XåŒ lÿm7ÃÊ]:Î‹£[9½<(e¡œá¯Œy02ÃnÇPŠıâƒ—½äcµ¹øİÉ´€‰Z¾x¢k9Óª…iM—3O«İ5 òËô70)bçO´—º‘ØD¨NüSêµhL›&¹ÕyHQñR¼{]	ŠÇSpôù-ü¿N²ò¹ëâÕ	k6o5@•5EÌ¬ïA¥fıÙ$µd²¥záƒ¼jîEÉÂŸk“ö“Dåğ4VÂ8À Ôodº²RÜ°,ªôûâ@/aMNÙoSk«GŞt»© Éû³}²8óıáĞ wVn´é†ş1¡4Nl¹¸È»¥øtûÇ¸d…vtVNò–:Ôügôí^Èƒşÿ—Ä½/fv®ÈZ;w>.K|Ô&³ÛCZFê¹×÷M(¶¨¨W¾³m1$[óÕô“î·SZk›*9U/ÿèYáúF	ÅúaÊ$Ïïé2—$a²À~”!·×#KÆa¿;1Ò¹Ï8AÍAøÍ¹Qá`²ôÒ,òXŞx i6¡[T<÷Ï›Çøx›ĞŒ<æ›…H<»‹Şx»,"šÏïĞšô½×$äŒ!M@Òåï?JäVû÷<©±Ğ·‰c=‰q^R{eñ)æm!Ÿ±RúÈL–ÍêèCP»1p{ÿÌÒ$U'«äÎLé„•Ï¦j"/z™ˆNä0s•3aµÎ¨Qrwøa¾„Aëp˜¿ET¸Ğ¯Í Úú2¯'wŸÊ›–¢å‡FD‘ÓØñn½[÷q¯•¬‘üŸÊúØQÍÌêòæ¥>oÅ‰X°­Û¯IèÛ<!ÌÊİ˜±¾ğÜ`ëa´©#ıÅV­%Ñç•³ÜeU›*õs£Ø»IÕ,›o#ã‰½&‘ı~'½éhŞ÷–¡Ck—½xâµ@~ä¾\ Ô\JìK »‰Æ	,ys^ó F¾Ò•¹j«ácæE^‚ÀìâHİ2èš‘H÷ÿ5–ínÅø*ª¾Ù²Ø+á—•dî‡wökIUª÷¢Õ‰ ¹?`à’›ÿ¬kÌ²Âµq{cmti©Uü„ÔĞ7W —Cëõ‡'diUÒææXL#üÆ¹l®‹©;7IÜÌ`²äéKÁØLœ0y»ƒìî‘µ¯S
ë´<5löãàmKPÃ‰U×’v†:ŒíáröPUKEãÜ+×;<k°Ü"‡¿Mú	6ÙÍ“€ê$ØXÉ€jÑ4–¢†›‹­nÀJ®øÀùe•-óWØ£—ì1îZOUÒ³àï±'İı4ÿsÆ Ëòes!lµ˜Í[ 6Š2
é¦?’§í©P”kÂKõsE·_Q¦€š”j`e†ú¯^øêüj‹/½ÿ<‰?L<?­ˆ+c¨xÂ¦æÈ„ U6©i=#	Ãfš½ Z~°ÔÃ*4;†•9l‡/ø´ÀG1PÂ[W'U	Pµv‹ÙÀú‚šwÃ·ñø0ïg«[³*¦aàßŠ‡ZDJ æğç#¸VZ6ôX#‹ÏôMê¿·{d±øúì,ªHÙö«òìAì4†MÕd-Ø49ŒÚøè¼ìüÂšŠO­c"-ĞJÈñ%D…]û[á)	ûÈuíÀÌ–=¦¹9)‹~Œ^ÜgÁZâ‘shf49ÑDB‚\‚{Ñï;²a™äµv²ö@§Y˜ÂÖ.s¦;8ï³™c¿¥%^CuyÜ­\±}[N}c¢LL–ê½#+-ÜùØÇ6¡ÇWîB-Îu_×ô8tã×Ç#²+¬•çØÛGíñÏï±bs¿¶nªˆşİòx VCGq‚‡½‡Öıİ?fIÀ¢šÅ+§y*%ò¸§bé“åFßÆ†³rºŸÔñ²¿Ÿvö‚ò	„°G’(¡Î˜›·ÁèMvô¸]nNàé›H¡ÎNšİ˜'JéZq«ö»»
À0y¸ó¬\«ÉUë›ı©ÿ7ëÖĞ.6i'‡H
/¥½¾İcÙ€ñK×d•­rQÂìŞå”4w¶±”Î#*Â#>KÚ¨*Ö¾jŠ'b.Zİ§#êÎ›C–Ê?L6Æä”gâ#I²vcc(4™*!§™ÊÈ->)’vïªoYaó"ÃZò8vôŞnÇÅ‹V,œGâ>*ìjóaéçİ,­ºÎïÇìÁFM–T¬’øz,”—óãß°T»¬ÿÖæ­4ìô51(°R=Öò
òêô¨fsx)úÔùñ€t±ßa”£» ¯é’&IÑ¬…¾?Ç4Ï„ÅŒ¨²ÜmöO³ÊêY±…ÒìÑ¦t4;#µg~û4% ¢èß#RzUm:E„f¦w7Â…¨ÍÚ™no(ÿç­²Œ‘´ëâ~¾ÇãYnûşZ·D“V°×øWx'˜.AË$oF½}>)dÎ³ª‹¥Ù"àø"˜¡YêŒ§ü¯â­ƒJbË¯ö?Ş~Ãés£’65D#È>%}^û›½á|DHfë¡í­‹*Mı¹;ã%CĞ(äNyxN"ï1xhU°ÚÊkOÀˆ¸:òTÎç+«İå39£àß…ì3:ü]+¯…×l	U?§l±/uc$â²Æ²]¡_T[”= zNÄúÕZt »‰çP|d¤¢ ÷û¤PÛÏó«h?àå$šyšNPØ,Óhç7Ô tÕ@´ĞxMÈñ÷Ø÷LsïG»©†ƒœ¥­äÚ?”œg”Ê?©²0Ê›È>JdfB>Í•¸„R€§sÕıİ³ß'¼ri<K{Gâ„;;0 ù¢~‰«<)7eé†I(SËÕ÷øF• :’h±)‚êX®Q‹H~	.@€âà[+KÙe µÃ˜rkX×ä›Lâá•íQ¦½ÒÏ–ùŸG ¥oèíäYj)æo¥ÑÑMrH¤ ÏXE‚9ôˆñĞï?ÜÖU©,É¿ÒsÌÉXŸ3!¤BG¤VÁïÒşæqm•-`Ñ@ rB2™²h~8+)€”E[/×Ç¯¼Ÿ•šù5Ü—6,Øâgú…æû¶½Êï[ é:½Y€zÀ~æ§t®€‘È2C7°¥p|I¦‚AW›Á¬wáNÀiæùqvİ¾zÁå™&»ë¸ÃŞ›Î<õmbN'BØ(±î³Ì,ò7áÌuÎm'?;+ÓÃg¢ñÁeoÂÀÄÎ“¹ÂËí¨F7ş½ô.!Æ_Šâ}âš37
r«¢•·«ÅŠœSÊ°UI¯ç+,•¡'8ë’E¶¥Öj#Ğ“Ñ¯Ş‰…`¯ËØ±ª†¢©Â£˜ã`”Ø²vèn*(0!©_úÉiTcEÅÇêíŞ™b‡»Åä©B}Œ'˜IşŞ®MœÕÈ	Ï8<5 Ë®d@m ½öÑ^;\>ƒQ´$²&„™§ú¤Š§š:Mÿdì­oë„ÒoŠ÷'É\ôIÚúşqê³Qé­æCšŞÅ¹l§;¦ÖbÁo[ë&TÅ[8Xİ¦Ó¸,¡Ì%¼4EnĞ’v±ÔÄímİ…§Ïó×¡æQİĞëŞÈº³…ëàF”4°Ê6Ê	ÜGûõ¸ğ>%-{—íÀTÛœÑ±#¢Å9®†?y)1“¦‚ú«÷Ón‰AøÏØŞÃiipN‡òI¬Æj]­A"Zı†¯*Ó”&Ş¼š9ø×bân¿y¨m€[B?nò¸§Ã&ÉÈ™$Eê}ŞL›úCô8P¾{ıNJ*WØôëß¬×Z_N=“zºÑñ­!n|)o‹£*ãDå„ê´î— xB¯¹´SoÄ°½é= ø¸-OlB³-ñU_^Z‰½7óêô›rË£F„ U«ªípBvş
LiÙ¿§šlr!û¾98tx,€‘òEJáşÇI,7§»XrÑ!µj=(yµççïéÙ•?d±Ú=şóìÅ,­Ì_Ú%fë*lß ›è^¼`!”éuüÉ)¢ÊI
ì%Z@A=ë\Ò¸µ{„¹šYø´®WDŒ‡Ú å®¾¬Ï_8Ó¨|ÃD_”o´ŞìÛl2µÀo³o~jAdîüëdV9ôÓHø‰öÛ~É]’ZR7zĞw¤àœG
]¯–8—½—<[ÇŞNıN ûnİ==¶Y39¥Ê®Ænå£çíte·P?Ÿáûnñ9G6ĞæÍ†IiÈL3²ú$qûâÒkİïŞ»*5³ï‚}Û=)íó!°°QJíóÕ°?S·ò#FøbXjt¢³¤C³¾ªsÎ«yeŞ.ÀŸÌ¡¼q“åå+¢©¬~ÏEÖ¬uLÚĞµ¿1Ğ¾û¬¦å¨¢Ñ‹Oo‚ÛBäa$˜2‹èÏEàv+XkÉ_*C4sª¯s´ìâjÓ.E@Œ¹í;\¦¦O'_¼P(æğ9ª6o½SÇî,)-ÇF1 ÊC>oiÔÎoÚôË™eøíC¨¢óyíK¿£|B-X„í
XUÿ]…:'½ïgş[.íÿ^&h]êÀK‹©™Ÿ¯rtgÿË‘Åf*nÿ&l¤åJmPà¯œÔh™Ğµ¬!×ı—™ŸÅoiÁ¼…Å'¿—sàÙ•s9PíÈ¶P#”w']7š‡Œ³º“¡äÂ;aŸ¶xÍ3Jw(®1ãfc“[œ`Zn%?1I[Ë™-á}cøå$İi*Ñ×Aô¨]÷ÚS]>U[²,ë–¬«éq½Î{æ“Ód™µ9m7’* šærğ»l7ÆÎÿcuÅ™º›1—puoq:OFÅ9¡4¤üsKp^6‰nîâĞ§Z<h5—z¾£ÌEÅaiÎ™ÃL°©?¢ò‘^ædÇÖ¸Ãng(X2>kNÚ
Ø¡tZùIˆ@Ñ© ôôiO‘Ûà€²?N¯¤ú“/lï™c	;>ß1‹‡£Æ(´É?Òİ‘Vx mx?XE|•)åÓ…“øÅQÀô—­³¯„„ÏÄÏxâŸ˜f1 «ĞvoêÖ$øèÆŸH‘îŞ>h¿:<Êÿ	_·ïfï/w˜Pî>‡Ma-”CUsdØ`LJöµ|óm•ÜR`I\Ù!?xì¿åš¡Ÿb­#¬¬}*@òDQåÎÒ»¿‚¡“?`~"ªVUjJ-I¦w4>îM×‚<»ğŒ2ßKëI¹Ml(}áÈA¢G…¸Éµ§ŒÇ¬b’Åá^YGÉm±u‚j7f¼ÓÄJ¯m¹JúK¡iñR#+éç#bÔ²°1Ço´h³ƒ"ëÕ¥B¶æ¬ÖfÏÓ×nVâk~Y0…[2foä?ñòSJÕI!&³ÛP,‚ıl[~*–Zy›'A|¯`‡Ã=yÂhA ço=Gæ´îŸvFŞ—9¦ UOÿ!†ùÄİ#³pÖ„q†ÅŞA !âklC8·|›-vıÁ¾Ú¿rQÍg=cMÎ
ˆVI4L´J®øgjÜÃ¬ìÅÜ0’/“Å•ƒ2hôe¶ÀóY…"ıEw_ÚBOT.İ«¼*ÕËhÛM¨˜hO+/ÈÿĞi7ÍÁ7©Mÿ ºBä·¼-1¨´GØÔ”´Pş»€%)»~G¢Å;¹¤¡e¸(PŞúŸ§BÓVì5m<f 7Œ0†të=Ó¼fkâğàaµ·Æsçbğ£P•ée‡»»M£|Ş·ë¹Ï [€}Ş^ç×Üjòp9ğ/ÿ*èpò«˜r«C¸—AW·
Êu bà™8™îu1‚Ò¬(:Ê	%æ¦Â?VäÁßf(ŠÍw	£*ÒŸÛ(ÑÄù~1Ÿ„ÀN¶"(Ğr¿OàlD½us½,ÍÇ ÎZÕÕú©/³|TôÍƒ4¥³Ìoéøì*§ô9Bñ	'¹†æA)väF,3«ÿ˜BE‰+KAËÉc)9¬öŠLä
goŠàœ0êé;!µß:P@ƒ*eúÃzNˆ-’ßÖÖë‹/¼«º¢k\¤øŸ*z™–[Xı=`®‡Øsÿò!Öz5×€µ³„A"éÆ³üh9îı¸ö}í:ëDUºß›,~bÏ>¢ó½Bg©óĞĞ#ıá†:±%3i[$û™»4ÆåÁŸ&‘ö?mßÈÑÑ×5C}ÚW	Œ&ğ^¨Yh¹úy(É	å• wÁIIxCˆO,İhí¶ãzWmT€¨0Ó¨GAÒäëXº¿Du™/¹ÕnÃíÙ~@~²sn&”eºAÕ(%É÷¦t)_:pL
8cR!!cPŠí`ÇıØZUM¦×W,EÓªâ.À]ÀR(”Ÿ=º€gğ/ùhæu³Q¢_´E÷í®ÁÔ°ÎØ"8ãf²€è¾q—l—SĞV–Ë2!ªÅÆuïxÖU}‰ _k¬1OP±’0­ÀíÃH5¥«=<Ûª]FÓòÎ ’^2'»zÁ·laUïÆrÅìNxíË\ËU(ş•5¹CH3ÁSë‹3ËÖİmz@°÷8Ğ0Òü &å›(%óF²ÚÈZ…[ür—ŠÂéW`¥¢hé…u«rÏŠnJn½RÏˆå#3ï%”{$UÃxk}§`J_!ğåèÃc$ƒ€T*Aò$dÙ)“ØşÌd›güÍFJÒøæIğ·A°ò™5*UP?¾ÎcÒ¥û[ª¤ùéè’#=håğ‚’»^i¶“UÂ?tß[ëßäJ4Í=É_G€6¼VıïàÓç&¹y$û%Å•ÂQùˆõ>ŒÀÂ• ëœG>µÕ=6ğ¡x…-×¤ãsï³?q6§Mñ•#ijâh|¸)$|,Ğ„Ei÷ût»
.†W™Æh7-”35ÒÉaØnì~ïja©Ûfºş²¦â5ŠÒ}©lßĞçIÏu^æXÊfJ9zòuû©ÕÕÄóÆˆûûÍ ÿ˜$›Œ$¡Ü€?¥°RPº‡:= ï‘Y€†uİBv’‚¾£"ó)óƒ5Ä5F/JR’U¬ÎêGG ÃâË!(¿#£@îÇ†·¶ ‘ƒ3ÂÆÁa…J¼ØùT¨rA©J‹4ü}`×)É,Ã¹ôèjªGly6Ôêx9aV‡ádƒ–‘eyEóGs²[[Ü¡²v‰ï[§ŸÔ…Hf¨‹2 r;×ù	- ªd}.$í"S!ŸÎ´ËKœdÆÕƒ¬fÕ’Ğúu5¦SâDÈ>3¤Û@Lìn¸oí¹ *L+r ×¤µ[•l«·¶4wV‘Ö&<]+±ÙH` f˜~áû „¸8ğÃkfüÿL¸Ô?ĞÜ‚¹ÄfsÑPL[Ú¬‚9ÿ=>FİHĞ¹"½7äŠç/9ËâGFÄAK/Ó9Ğ5&Ğî´{=™ñ&U“ÆCázÙô@Ëq¿še.•û½(À+’íì}î&ÿ4øú¯€³³q±dÆÅBº„Şş¿C`ñ÷g±rN¢ïé(=³¥–ÄäqÿAr«§İ?·²TÖ\ã±ö¡LV%Fç	şn¢¼Õg¸§)Â“ş÷¨[şùEùÓp]Qr07ğÍæïNjQóXº;nCı[ãöVeÌ ÿc$ Ä˜QñJª˜>Ü…êüßmL46î8ğ©Vœëuòƒ–ªØÖ™É¯©:p<=ÿ’x¸,ë©fáY©Ú·0F;êœÜø×št¬ìˆ§Z‰Käw…e?h“”¥è2D6Æ_ÁÄ‹!kl“†™×ËY«7Ê B
¤båKV/!I¸V9 Ô­œ´€„‘İWa1-È?®´B¡×[÷¶ï^_“›YQp•>PûÓ¤QÄÒâÕ°d(Å25™eµk¸RîÃÊ=Z×­ëÇ^'e4¸QK¥B]ÁbÇ0$8;&ıåÙOS„ïQÕŠkCËÆæã;ZşäÜgÜNå'XÀÚN’ÆŞ(ky™öËv‚lÓ›£‰H7wa	]Ca¡[H]_'¿n“|Á‡Š*­[¬ë…‚¸'-|)C¹Wv®J¦¸Ÿ¦YôJŒ§FçZquD¡„ÿı²ü›»4mâ^iWTÅÔ‡pË¹š|GA°ÃµO?Fá‘«9wë=$º+¶J {6áËÈèhv‡W¾|<µKğÅÚÚŞXH^~ºhİ:Ñ.¶-{kuSûÇ`~Pu8Éò‘†Q6±ïi¦[ø„”Zz¼WG„ÂÅæ1,‰\&ßOÌÖ¢T¦>ÇUÉûÓ D
.¯ª°'ü:3Q<óØP|¤ÕEE/GS-'ğ¾z,< ØØ	%ucƒø—•	İ¢¡x?ê÷%ß©®ş?İµ>êU’óƒô‚ğ¥çuGıô d@ª¸†´™±µCm#!Ç æó§?"³Hdu–z•ªô‹§ì‡í²LÒ’»æNéŸÌßO<4•V=MO›[¯3©‚N|Øƒaö9¤îê=Ò™«›>féS#.vÅñ"ª3™\dÒîl,:ı—8<n•vnøºØN¬&ôóaêÔ©)!]BŞÛb÷×Œ—˜tÃ§*W<+?uÊDxBŞ÷®–®¶^µbwÿjd’W¨h‹5|2Œ‹`;´V³SÂüuOiœôk(?8sc¥,°	QœÑ˜uk;"ÖÂÑ½Q'^C'ÔSxxVw-ã•ÏI™É5¾¼©ûÆf¢!qXÃ[U½%WC'°r=PêÙ›AƒJ™6‚ÂØ(m:¦"ˆš–pd}Ï‘RNÀA‚U?ØıZu²ğ }»/…dõåÛÏÄÄ³JœÌ÷}òndTxòbí®Š¬Õ
­§VÈóT*ñ¦<öF NÕ³çÜ;¹Š$Äã.W@½1›è3A1ÌÄ W#,îÀ6Ä>IR	Gp_¼I0nÚ´‹Ã3ˆJBº6ËÔM)QäÀ¿±üşd<.ìÀ£ô„~º[¦õ³P<~'x«Ââòê3Êƒ0Vƒá	pi,(A©aÉ
«8Ii[;àŞšáÖ·c·6/£oš«Âİ¿|µÈÌËõì›•JúŸàor5Üo9WÓ£ZØ©/0+¨7oí†®ªæV¿wœÕÓÖ3p!šŸ2¼‹áÅ0|	‹Á_§Nûş¦ÒU 1¹‘Ş]§"·É÷Ø•<—;qÊ’f¬ËTÿÙz®7õ×Â xõÖ½î±Ï—pwÉ{ËÉû…-2h^%®œ…Á >:W,İ&(Œ-î'!Rõ¸¸&XO?¼ønœ«ó§@¬ê¨äJ5ı¸Pm§nJ_™é›€˜=Wx‡W‰Í1‚åœ5XÖw{&{êD‹t¦ê­zË"i§N–`y]3aGíXw¢˜j"¶Ñ“édSuĞÙg%ÁGEmd€ïD#…#šB¶ŠóÕ>ØmwÙ wöMñ)˜È+ƒöFq–´–Kæ-½vç²ı½XÃ½ÿÎ`»¼Íô÷‹¹ÿ_&Õ"†d'<Æ”JAüQ»´ŞW´ıÑ>S`vşå×wƒ¨‘Âq÷Ä½İaxÿ“”ğ^Zç¶)R¨÷¶?¬nC•¬ÔYpRF…Ù.	ìÈá†‡û,h“õUc,qkæyñ«1@J¨=™U¬±k2ä”)Ö'"s%c{mB[Ofñ6€ã Z(+œğ–LÄ\èà^¦¶»A°Õş\<Ìïòãab«õ*LM ã"ûªR[Xc›®…ÿaT¤š\)„wvB0xÛÉWª†]ıõ@™ïi©£ôk†¤Ğ
ƒ2Ñ9§ù±1¿ô{7Maœ‚h°¤DØËUTHXc´!ÿÒbÈbãó2ÛkËÙH_s?µót…gJ$Ù"aë-E9Í¾’Ø•ïjP_E“e0­@ŠÑˆË¢ì!t•B¶âFŒ)èvg´Gq/•àÈ¥àjm]é Îñˆv#k”.*äµoÜ¨ŒªÌUº%æHdqD(¡(IGêô^äu,`”4T(Z0‹À'¼D‡şj³ù~M„¤z+Á]^v^ÄøÌ6<&àşÆÙá²ĞÄ¶c»®–éDB0Â‹¦ØêÌc ‡½ Ş¹ÄÉ³kèßNı¬uÎpx# ¸2?:•Ò³nôNÌŒ@krCŠ''Ò¯“D9:è“Zn÷T·³McàWKo%X~Wy¨–©E·Ÿıšé6!P_äDtùQxÑó—¹½Ğç¥‡rk1Òh Bi¬9ƒzG‡¦å{îÜ¶ˆi+Ä˜İÓ&á%9ßTv"ûRÁrF6jöÊ>RªÉ\[rÕ|I9OvÃ¤<Æú6$:DŸÆ6Ğî&U³¬|‹ÜìjÈÆ?.PÚÛ-¶‚K_~¾fP\¶âcZ´?`”P¤6ÈíµÅÜ%â¦upnÃ¡”7Ù)¤Xï–fŞ#˜EççÕûr„§çÁhD	l÷,ø4ª.ª~|“ ?z"ŸÃU±/«ğĞÄâ–ı€Á šìls?BxiËo—aFŞm“äµŠ¥au7â ŒÍsóŒÄ¬¿Ì§büù•­QÛN¡¢’æxğPı•iºy²åF÷Ÿ[A;QÜıÕ||è“öÂ,R¿ĞŠšÇ:š"¡1FQ§Ñ¿Si}á°©Î­$vÊ#ã“c0»IÑ@6Ê|ä9eØıs±@S&#×ÃÙ>Î5Áybs¬›Ş°•ğh^ÀêÙRìŞAÂº™d>}0’sDO«PeA:« u°O}÷ùÆ=h?]b ô\hhq¹¼âıÛ^ñ8’'9ç]‚¯¢Üİ‚}0§\15®:¨ÖÿOX°½8µózÔÀÚ¯N€‘ŒñnDq†Ì… 7°èFÏ«DbYúˆ(
,Á[Èk¨:[Z\|³ËöeÓkR/"[;wñ%X=ÌªìÎ·)Ø+LëÜmêâ<û™Å¨V§55Œ‡ä9+O¢õ‰Q…ç0ÚHÒ UÎ‚Ì¦Ÿ¾„8Ìj‹Ş'üY7qùó‘L
Bı¼˜÷–ø9YêÇb´\¶bo-Îç½xM”Wtmq‡š.²CÒ(ùi’‡ÅATëƒ¹L$yk“WDí¡‡«ç€Î‰ÑT
%¯Â ÈĞ€p™1 ):PYX2#ÙP;± Ÿù8$è‡-âÔ¯–çŞ×!øËª·xD:Œ—%š6¿´¬FõØş Â‘ùb;7§W"»"Ê7â›äˆÕGù@UŸ¨§Çã6— >æ`én½jjæ5EôroT 9Ğ…
i*ıe.pİïÍüáYêÚ—`UÆ"&UËÆ³Å¥Ù+œÀàÂ)ëÕøøúŸä
pä×º×g§®™…j‹Zğ¬²hz —Ä]Zÿ›–·V.wÙ½åtíûÆÕÑ•à;Ñ±û:ã¬½¤¶rÊ|r›ñş	g¿¿ï¯h“Ğ9Œ(X¡Ï,
É®ßIµ-¨âÜY*Åü4¤q(.E¢ô³ŒÆ¦‘bÖEe'y*lÕ‡BlÙ8» éÂ.²×G²ü`×ÇÕfOşO\s:×?hG<ë©°jÁâ0¦iˆ”œù¤47ˆJÇV¿ıÂV’Q#)”ñ,`òÅã½@Jš§İX(-ÆÑÀŒÏµèV=¢¾(ı2Ëº*›w'°ë¾ éyĞª¬ ‘Oâgå
ĞŸcõ‰0‹¤Ÿ»OSj€w&°oLŒ?6§?İóßÕB<«á³øASçØq»*jm®Ë•tµ+î&’Ÿ‰»¤MÛu
šÆl@:¶„Røù}Kè~øhF	.Q.Ä¼ô²¢¯¹`.\ÑKáßüÈl82‹v(+šwœú£íF#)—H˜¼¹ØÑÕJõî¾…¯½kù!Ëã?|ƒô! 7k†õ³&MŒ…ç†8ğè°§0íÃ×{‘{EšıÊlİƒ¤‚¤‡u×ƒ5Ù$JÓô ZŸ26A«¨|’Tü&ŸÈ˜šæe+£T¤T¨×@¢®ÎV8ÄjÿhUÀÌ‰„éS«»Moêúkôgš£·=> .";{@Z1ÉÁ¦z1Q†ñ„Mäß6õÅH¹¿N°Ù—V­I€ÄŞ+­'ìœtz‘O©›oöÈ'2e  “)#=û  É/z#Víjjê»©ªqâ×.Ÿùè}xş4›fãV+q‰—|¦ã4ŸÔi2}@à®©!œpE]ÜBâu{K‚¤uv>b¹56¦Ë—Ù­õ‹§Şî‰-¸dW¦z
¶-¼aE9Ÿõxc!Z»tÖ€ºY)­Î<_Oz“>÷$iaõ½$]ÑÄÈPÂ9‰õÛ?‡"óvşŞñ+cÉo:•ŞTñ@óüÃß<¨Ä¨€Ú²T¸ßİê_‚:oÂF¥·æÅ¸+KCëTK†
öwAB‡ÿB„	ã9<’…V%’Ü%Ÿw§˜Ãóÿ'0Û`Dš/d%1•F $djÀ2y];AÛF>'ü>+CÒ¨ù t]0„fIx•wéYs0áé„éøÒºÜ/!4wb%¬´B*º*¯ˆ"ü§Ğ¬ÅÛsµìRM*«4zvtdôè¾Š0p¢ia’=»°İÃ×“mîv&yôFÁÙÚÑ^¥Ó•p[Š…èGûÀ ùÊ³æÕ´ŞóÙÙ«²°’Ø_+(ë!E^áˆJ†± Q!b,<ÈmÊ£X.„µró€EÂ¡ü&¸ˆ^.¶aòsåØR (r5Ô³µ*â~*üLc¦õ ¦" dÿì/¯3˜ŠBÂRYKFM™ûVı°˜•èá~©<\™KE˜ö°`<š,‰÷Ù–$íIÒ³ÒTšè?i2%Aİß¤Â’<”9„UJ>Äót$Ú‰´pEAtêœ6j^Ù“>½ú}›ÍğB:ÿÅ©¿mÀF¸ ‚vø‚?!Q{Ø©#ú,ZT¸]ó<¤ÏX£ÈíèÓE¹«fäˆ¸^Ï.¯ÊâºÃ½EXE«0òÅ¦“ã€O>UÚf´˜¸¾A?š@ï‚3Ü‘Z™ö§÷IÛâ7V2˜”Å4ƒ%¿ÛSI½H©ú}ÒnÈK½B÷TC-Á&ıŸy%šÂ{-V¢×+>´—ş4¨›<*Û;ÆD:Nµ[bĞğ“„0šëªê¼iÏ j?Ù­ád”ı‚Á99«D;) ¢|mqƒUÛ:›æ—ºÀ›4¬ÖSiòàÃK§t_F–%T#–r°Î™¸üÔGzª®5Eyµó¨ù²¾®±»°õ{ÆDÔlÊPÅ»`eòûÖTª.J±½ªeõ†0dçåâ‘vP+ÏUEûÚ§X¿=’J8•µê«¬\ç¨–†=‚ÌOoŸ…¨FGØu—‚uÿ¬CŠÑm•÷Ö¥ë©Û@µ
Eßˆ4š¸°İwwñH¿ËÙx5‘x”æç›ÜĞå¯®
€µò[Â+ìæ1ÍìYÙ¢1 ¡cÛ“¨‘˜ÒÖ²  ©C5Zõ/[|ŸaD]Æ¨5œ¤dá³XÏ¸|©B2BÃ|ßêŞC|êD¸Şk´àÁCı´ªBÍè¢÷°oÒ„=¹áwj#ÓˆˆÅWù?ë38nä9!¡ ‰côJd =[b—¤#Zco#­™…Ãä;M~ñIIÏ]˜ˆ=ÃôÀÊÓ«/K(º÷àÑ*Á2ã‹ˆğÜ½Ø°à'ìóšÑó¥f	{——9’Ãa»Ş~Á°­ê¯8…4âjËÑNsĞÚ¬Ü·?v‰––µ½Nøö¿]iøHfÖ0 £ß¸ZØ½¤˜ü‹`>ˆïŒLÕ‹ıs\Ì3j¹²½”ûëùÀè%Ã„äš]ªWq(ç²Qè­­NåÄXuèfRüÍ~ÂGí‰óL	«®]YÆç£VÖÆT^ï¸~Á*ÈRT3³ÇæÄ¬”¹3005ÂYõú“Ù½ôßãûu×ÂËñ´TO†ø˜SYÆj²RùÄ¾°ö8_{ƒ:¤(×Äq%|°­Ÿ2üèH ¤¢Âf‘ít£ıiJ—Ò½d(Ûã 0<PÂêyÇĞm6|Ã€ÛıŞ%ø V
Ï¾»ã†fß“oÆæ ~¿ abcüh–”ˆ>P}Šî>–Çüä€šyÊ‡"Ë.ĞÌpä£<PZõM“k“^’)z ¥Ğˆè:Y/ıAgÚĞ÷\çò«4æµQˆÎ\jÁÕ­¯W%yÔ_ä;#Ë\ÁÒÏs„0S¬à‡6wQÁÛ	†YùÓ0ŸËtÀ#Ç—ÌÕDî[q7>IìwÍ![î)[N›±:z5„ƒF^§(3’müe¬ƒ2vZ”½Ñ£ğc-x©Eà>±tD—z`ÒL:O¾¯cQ'G˜·şÆNvuˆíIÏÑiQ2—Šöd…8	œ+OÊóI&0Ã°Ç YşXê¡Ë Uæ¿v!{1›ÿÇC!1ÁŸ(v‹aàM}úÍòÃÔÅ=…aò¹ìFˆRDdAf­z¤i(O8	´ëFfäÙ#Ç±ıSx)á÷S¹?p*C³v¢£ÅåÀL@dĞ#G1¹Œ¸²nÏÃQE†ídó2JšªùÑçè|røƒ'a‘n±*+3,=QÏEÙßÇoıÔRÄwY«4ôŸ¥Vkgí”:ë´ö” uÅ"£½Û™×‹rÅí\
D	‰ÓÃÓë_ßÈã#İ/qÀ>å>¼™ßÌxj@)óæÍğy~ÇuÔB@6bCßñ:ÑoÖ"ôÉ÷äUkDJl²¾Ÿ²
­“NZ6w»€c¥¾›™¥¸4€O¿h‹šW|‚Ì¿«e« šÔµä†'%}¢şñé‘†@Eÿ‚D½äÔ¡+$íØ€ôıKÀ=,.¦„ˆ«á•‚—óã?u¯Ñ¶ğ‰÷6ğS*¬—P·uÆz•MèV×Y™]íµ®=v,Íé<€ ÎNÆµyHäbüíiùˆÄg¹õú{e\DNY~ú#)iG÷6¶4$6U¶b½ÉÕ_÷õ‰ÎĞâE^Šœ¼¹š5$j7 	>_(ƒtp’Xs<rêÔC”Pë]£åúßTàñ~ ©(I!½úú’V¸ô3íáDÉÒNK‘É`ÔüdãÕIz$—ìÃ jÂ€ÑG¦ñ Ùn¦gzË*J<¬Š¨7è'®ZCş‹Òh	Fg: " »/ŞİJ¶ü°Éı¹øPİ¯ˆ	Ì¹ ÆR9òïÙˆ»E|sÇ£¤îyî<İ¿‹ÀáĞM`è%gùqÈŞ&{>ìï2R°@ÔÄ.“‚~fî_³ƒƒÃÿ?§Œ®½5?.?ê-*~TÁÎıªó²ÜŒ»ò"Væ)Õ°p`uÌKƒûJûo‚>ûÎ:´—'1<@;á oêĞcİœÕúã;xŸ„ÚøÎS•ÃÏ,?˜nÊgŞonk ¥	¥üt]ål/ñ—Á’Œ$>À š{@Á£ÙcİfyÀııûƒ
kŞZd,=]R;²ozV«sË3'×Àæ
 ön1®¶5jù÷lxIªü×/ZÍ„ùõ9 ä+[%/îa€=±·afÒÔœ<Á…KöµuìW±©Tt+ÌìØ‘àæØL”üû `¡µÆxĞôœ²¯¨ûìQµğGŒè)Ã¨—ewoY›¼Y‡»ÎÛª6iÃWaµWøfÁğ×0ıxl3ùOËˆ‹Üz.éo£ÚÚhsq/¤a|€¡í`Ñ*ôƒ%Ê2„Ï÷	óhOQõ'=G¦vø ÒõtX›Ûr©ı.g•°¨—§-,S5Z"‹ ¥ŞİÔò§HÕ!Éúü!›ezCÄ»fÌ"ÿ‡Õö RØN)¼:A™>
µmÖÆøA7Ï1»½)İ°0CÎ‘Ö¡‡^\\éÑ²„)ÙÌ­„!6#%Oäuõ´Ç¨Àd= ÷uÁ¼+ŸKĞø Bo PC‚ä&&€7l`Ç!f™§Á|3ƒÄYşÍ¶G'„«XDÊ Kî–*¨p ácOsÜÏ—|g1ÖõZ_â5ãç÷ü±4#aõúyÛOl1í ”¥89[Ô<—s1(×µ°M§)I‚kf“M%h¦ÿLDe_!	S]"NêafykÑSíÉ2îº¹İE·2İõQÁ©ÿ©¸æúµHÃ0•“±b‰5=D´[âp÷y	zú)fÄ	ôœSŠiWç <)§ Y¢¥ò*^(sÑ4DBx«Æ®;ZÄ gˆ“xÁ	ëˆfZCŸÏ³æÙô–F }:Y„ôóÏiU®á—šM³ôÈ½	w?¢ïVh¹îu#ÿNûlÓ)F¶jV Š¥bô¼QÕ«(nHDo,ô=’Cü_¿-&Kª´jîux‘5ñF²ì\Œ›ç¢sëÄá¬Œ’f”¦*(Î~n~Q÷[Yµ2.İÂÙÓ¸wsÁcìVqç×À`ÜœîÉi9Q§ÎdBŸqK*È_\~«9»;gA)¿Ñ@F“ßrã)!ÿùè¿†D»Òùö¨Y\“_zkĞ .JTWáPÿX„lø§8iínŒ·Óæw):¹Ë”cq¿…=öv+½Ìw©Vãás‰Ò
`¢2ÔI·ë-¤Ùs †lí6-A5^ƒáŠZ+İ80â÷-„`Ğ€çÜ÷™;Q+:OÂ{rÖÊò½ã¥qî²iiëV%—Ê7B»£î*^ÛîÊÂAĞ¹RÃ æ^ÉÅ£Á¬Te¦—Ó7©±$'Õï—¹ïv!lÆÔ1fÌKç«öy‰½ŞèûâìqäfüÒß¢0|(DT°UŸöÑMÒ‚·µÏ¸Y8Ø5CÜÒÓl«GM}c3{™íX]ù™œ8©æD€%F|’`±R§áÉİ¢9¬ëÇ+GÅEup›äóŠæŸ°H#âbú“šPàùró)iW1]èˆßœJĞ¢P~ÉšÑÈê¨“†»»telÖ¢¢‚½56'!'Ğ­©M³…EÌ‘œR·ËÿÌÂš­ş#]ö@ÅÉÁ°£=åxeõÌÅÆk‰£Kô¹8©xWïymw')Š×†æ„Ôd:ÄøKhƒİî HTÍœ®Ñ®z	1
½rğ–âsLë#±·â¬"ï65öb˜ ht¼¾îñQDû›áñu @”çir,ã‘K_Ğ ,GÒù›{O!G,j]è„ÌÏ+ÙÔåÿ4@çŠ€õ8=ÂÌÖøôb›­üß6›ín›-‚-î”µ*¹†…w¬·×~Šéø©^™G='ÿ`/ÃQA#ØÌÌT	‘JÛ³IÚjæÅE‚±4$©GZÛVd;$ÍÂÜ¦¡—‚ ‚6“jÁnÈÛg7šÄæâVëc˜°Wê¨™şÉ-¤ò…®sP´h>•S‚ó‘E{À‰ŞôX‘WRÂİÖ¡{jæAŒ¥ÙoIÅSäLÿ˜ÿÙß&*<9×sç¶:Ú?¥‘×³n*Ö¹áñ6??Óìèˆı©áÙ£4:¬’7?ë©"¦ä¥ñÓÏX²µíà5å]Í™'Õ“g¾ÃÙ9ËX—oyìIH£·Z©În;z±cçŠ§Y#H!Àç‰©²’ª¶ëÒ­>9"Z•m±Áœàÿ¦À`Ã5:L
ïC9´Óˆ0…ĞZÌş8-O¬Ëæ“öMxÍŸ§0î
ŸeÒ(µ?¡-´ŸlaßkÙ¸eÇ%Ä%Çÿ’æI`´` ¿c–Û\yPn_HcOõr„ÊÚÆŒ¦İFâE*„<¶Î|™3	«=ñ‰~È³	]E§R*‹—ÆŞj'¾¶·s¹ëÜİ¾Îš{-uæ|À–ªğ´öÚ"óvÏI:`ÌÍÈ¢Ã‹S/ëofÄã—«øH»Ş0Ê'¹ÇvÁ—Á›adg@®14H,ÓZ199“¼õdüÆ	Doü%‹„ iÿ®}ÕİÕ;(É!!šœ!Ş ]Î|j×Ì™ª
­^0{§ÿHDÅÿ†ç‡ö¥íMCs÷û&m¦ŸqV‡`Ğ¿¤ÎüCNTeWY¬ü	ÕÍ>3=Ù!fáU"±iTÛÜ¯-¾SC`·X8x.hñB%~ÃuN¤³&}ŞV@‡{+!ªpIEïÀÒœi¡'J‘OÄÅ3
Hßô©%ê)ûWÏJâÈL†»øÜ(GÿŸ!ƒH¤Âã_Hñ+Zfõ»¯¯ø+Õëñ¾°ıöqÑÊñÌ»1ÛS€ö¶U@ §AİWÛ†=Îf½F®ü.ÓPpª»ôf_ªŸÙ¸’²êüvhû(ĞÕIÑæ–|‡ÀIvâLx8R&¯Üf9r¢-î‡B7,¢´çütƒ¦Su?·‹õÍ9¬^!¿ÙÆ</à€6¨ÇÚå2ñ9ø}XYÉOÈC{õîôëá«R-ØKü•p”Rz0ûM·A¨üFÛ×aı³C/ÚX¢’/«CØÿt[l+³­o_­ø)Z?¦ŞpawÀ}$’ıNøqíC”Z	zŞ¹Z;œ!ÈC†xüÎI²†73*ƒ²ê¤=¼71v„Ck®0É1éï_ä!&|V3`¬K¸>•,+K•êİ' Ûkë³«Š€~½/êÉ
EÊÀ)©c}Á5õ"XÔJ±Éïï.ÜÁdğ½IÂóËãsõ™ğ«©¬>åœ/Æ€—c8QæI¶kÖyÈdß>#e¸™q++E‘–$b†KyÎçZÏäP*/f¿éiîüD9uI…ß!yC‘x«‹y°4ãwäcÚ’µîw]h­¦œÁIÈTœ9ı|>Fè.xgÿä¦PŠ’U1‰¯“AüšÊÀÁ•³üŒ.ªëTßd*¢²Å¾À<¯(K–ò¨¹¥å}XamÉü ‚»ÍOE¡µ)—N$<Ó¹íSÀwr·K‚üÎ¸±¼ë-d4B×..!ß8yGo²QÙol>Rïô]à»ËûÓkRovH°¹9æª¶ÁCÔrÛ†øJæá¸7vZÓÚ•ˆx—Û°âÜğŒu’óü—í  4‡OîĞdˆb©ö[W3Ëp²·	Çİ
×Î@ÜTÉ}œcíá-¥)Wdò™‘Æ:³tÀ¬äÌĞ	'"_q!Â”Ñ	qwcÁ÷ôtvã‹u´zm±õ)]¶§½=kĞÎ>EíJ9 N¸üão¢ù„ˆOÄSáâã¨öJ™yL±ØÍ½Aˆ¥²6Ğ‚©Î<ex´F•© _:‚+.è(ûıv©'£+‘~fu(š‰rFÒkÇrÑ¬
špl*ÙRˆ«òÿ²]ô†Û7®ä•ky½@³°èCO¶|ò¸™vq¹í­€}®‡àeç÷¯ô”Ğjh4I£è%‚LÏ³à:‰Jñb\pbL!*§öÉ¡äÑ 7\L¦ª,YÎÍ¤{DwxÔ{œAøÁc©€Ã~’ˆ³İ’=U©e#Ê=!Áö)#I`K>…U«îŠ¶ˆ£«Á¬¥È³ÚË.´OG†MÙIøó Õ)ÍC‹ñ ¾V³È‚…Ã]‘A ÂÏeö´]¾:¹ÿ!uë_
ÙsØËÔLI®bKteYÆ‘ÕbÍ[2:æ²ËE¯å]x>FÑ@ó®Uhbtz÷ó%æÓ+¤|aN*ZEÓ½¯›(õ‰ŸyÄF$¯Š7A‘µm~0¨Z 1i)¥Š€ üÀ„Ê{‘}›PÎ/­-^„¹ÊÇò:ØÒ`|WêÏ\ş'ôø8YÀ¸'i7Â¤µªfÇûàòaÃaIÃfyğ Ü)şaú‹˜àòŸÍHjúwRq“ªu3I ³(üULÂ.¼qCÓû	5C1N2ÌLl¹á~áW™p¬cÆF°Å0¿ï-L O§OTÛÑÜ{\=#3Ùg@Èæxl ¼Ñ¦¥®üKz_¢ƒGSÑ4ëÑ~ş8ó®óo$Œ'µûıøÆ‘ı6UéÔMå+|æ¿mÑI‹=µe
ôÎ[PåJ2‹O`æSèºMÔ$Æ«4ÚO´ „ÔU¨|quğ\¢@s³nY&Íš\³­Ã€Q€sûdÒ3¬aWÔšÜ"T÷é©Ÿ ïÁé–}æ¥ùâ’„Á'#–¬K]`
éã§3ğàßŠTÿ­ÕÈ›¸Ø%Ü¤$ÈÒ3t*›sWuWtİ m@M?ÓµMÓ§¡õ‹6›8O«ŸÏ˜ïõD‹Ò;48ôÎı†šÄ6Ú41£":ÿ^‹¾+Xy=)ò´œ`#›óÌ%ºÁCA¹´[ŞXÄC*“Xé-iÆ1ÏÄğØ]ÏÕ®±4g­Rm÷ÇQ¡æGÕ‹)%‹Í¯R“9²ûå0£8çS±[VÙ-¯ğõˆ#Ÿ—Poë‚»t3èúgÁg>†NjyOGƒíZ´:~H²õ'GlgLÁvDÅ—jí¼èşƒ¡xëlîH±Úú"j¶3Ä˜Ê¸«ƒ&ÂÕD}½ºŸèfi„I¢‰Ïc:û”T|š°Ëä§OE^xd–öMDÆµÕvÆël¤¸§µ³ÌâE›Oéï¤Ÿ‰3‚4eÅ”¨Sè«°qQÆy9˜ƒİOlyÎÉœÿ»/cÔ…*o7¬èK
Ïx¨­±]¿^]*ô'FÎ›]Í)Y– Eˆæs¡ïÒ/¢ôö’8	²*”İ7;È”Ô!÷€‘êºg'_I»•=€*‡¤²& ë¬h>Ey8•ŒHDÒ„€TÑ¤MX¡¥‡ùÊ8†Ï½G»¬‰Û] bÔÔÕvõÄÙ»3†,tM¥Üs=aÚöcg“†â³4ÔbÛÆÉ*`İĞ1--âH.÷ŒK6Ğ9$ÉÃ\'“€ğó±/) {ÀšmØŠãH(t[õƒ°h¬§y¡· Ï ‚–Rvìâ¢¸ùÔdöø"èvû5OGÉì¿úï½å™`å~†ïk-{r#Át| CmÆ¾ ôcOà ¸—Ñ‚Ÿ¯HË£ö*Ï0Peò´XìÖ^V!Œ7­Ù^àˆÖrD0# “üÔ´\‰@ä¦˜”1éÍ4ìvZ¢| Ì$=ÿ¬r¿WÑ…u”/“3ëSïÊYUÔO9äi¨¤ü>$•-d‹DIÿÂö}{üV½&={¸/?Ô:b'g9ÂîjŞ$Í€Q½7÷âõT†îp·İÕ~˜õƒ0ä½•Å$h>óZ<FÜ¯§T¨ZA£²¶­İüè^©sl¶Q,ót{İ… “İõˆ¿ê9ûàµùwt‚§»µ·HUìÓ–·§Sú½¨%(;9­¤\ìHaa İ»åg-´‘vü‘Zİ8†L˜¸s•¼g*½Ü&¯Y} Hr&»ûşÂ&Q…ıeaÑlOí¡>Æ±êb§ÑCÿaï	Ô	5buån1ÚMwä1Ÿûwbg~6 
å?W&ø_6¯qé’~î+Zãİ˜Ä¡Á<ãø“!JtàÉwúó¸—/òıÍ§Ì#ÚwÓ—WUé¥ûeFD@+w2‰2èd‘[Ë^“É­7¦ÇfY3€áìˆy091Ig»†&ƒ<jEÄ¿¥3¿ã …òxèoÃ«l 2ñM"©“#²c1‚v¸†øX9y!ycRu¸Ê©…OâŞAkª‡¿}Ã–ëz•ô…‡¥úÃ‚.R'‚ÒdòOzÉÒµ~Ó@í%œÁM×ÃË¸}òD°N‰øGí52) •¡9eê¥Ä¿B²ê0™üôÙBÅQ …¯ä.88]B8Z„¨JÆBÊØm›s+øà¬8ï.À™lÜ²ÃÙ½¬@ÿÂ)/¬1|“HßªnÁB/`æœkuÆÛD:&ğHA@/3®îi&mZûM¸ƒØšfK<¸OG=†ƒ`R¬Ç[mT±|'w£±î+B	ÁX©œöµNÖà$@¯ L‘^ÏbìÆJÙÆˆê2“¾Â“‰ØŒà‘JU©GnTû’ş†±…O×õAv–
¿07Ó=ìè*»‹·O€…<Û ¨ôwà1—ûQ7‡>ä åcƒ§PşÀÜş á¨ñ—DM‚èıœ¸«8¥ÅdÎ¼([ùËêëDãÎÌÇ‰!ÀišÏ¸‘AW ôwÑË½›ËP¹¦"F(1ğx;ú{ÉÚO±N-‘c’ÿS&à Éy÷5 ¡è]^V™ÍLkéS9°ïÀ~Ãÿq{}C/RŒßS A#ÕmşWù¥ÏHö9œÕæµàšÂ´ƒšâPxgÙ[ã² Sv—å3§Æ¤¢¶‰³²4nA:oøèø¾b³c,Ì–_Âí
ãb­ö0çèèÚexY[*4Ó›Õ!ĞÏ&tÖCYU[dĞhcU½H)ÅÈ¹ò{I‡…8šUI5¢#MZa"€†ÏŞ¦²VO:C`LsÊîêS  éa¦<sâ<‰D±TŸÉX°YÎŸ¶‚Šâs&7~×9”x³7ƒ×|¬7‹ÄHæ¦+È7;¨vìI  ıĞxö-ù(iÜä3™ÒHgbâCßPQ›’W1‘kO ·Y’Çµ9*‡TpEÙOJ‰Z]—›ìÆˆHGÎn+—	-’Ï¦®EG1å>ÿ\w¢Ÿ‰.œoôE¼_üö;Š>ëL¹\zõ7©¤šÚÖË¦ÒhìF`®~ŠË.vÜŞ2C7›gøs…Ã¾× …6¼±{ì»³TÒÓù'Â‰-4‰a ¾X-çâo_f#ŸÈ¥4~Yxaˆ’.ü“Š¤¡m[Ãa»Ã¬ÒÉİĞˆ¶"“·À¡äı*â1Ê®1—/z«z²ãzmî ‚İª®Hd xÍ«â&‘R)mÚVÎf<HşÇCü/ÚsùÄ‹…ÚÒKĞ¸'S	¾¡çĞãA)ÁÀŸM~Iásbl«N›•Do{s›²ì{~Ÿç9;E½ûrXi gY/%3)ˆı¡»<Ïq™ãÂ%‡0I¶e×8w²/Ú—S­óõ)a…8?5ôjF×¢]Æbš³Êw%eKWbkæv§&©Gˆ:¨)JÔå½/¨–†ë¿SuIVÌ\œGÛäúı[9÷ä!&Ø€œ¿emÜ)¹<È0¡ù`­œñDƒÆ@Ù¿_T2…˜ÎpOW2>	YÅMÀ2ıVÍ)Ğ 1ù/VŠ´Ü5
Qüi&[İ¦$(M°–32mêjwÊ™¡dZ~wG‰–h¸eÖT7Ô•t×R6¾¦å\ØÁZFåˆêè>p#±?`’Sè»!·Õ$mZ–E>îl?‚íí-ÕbÍ*âŸg@ùumô*ÄÍk¯ö‰Ğ]%cÇ¥Wjs: .ÚÃ åícÕÎO$:,Ù„Œ/˜ÑçSÓ<†L½õïúyòÌ§r>)xwÎ„%E{+©[ãf~xü- ùJm‹”©Á®9)Éù‰¤vÕâ1ù…1=šš
	ãªVQ#p8§GÅš`ó1Û¾ÁåÌ#’Uc|ó6%¨†cJ¬şŞÑ‚İjã´¥9CN0uí0ÛeXuí—ƒiz®•Š!b°ˆÉÏt+4SùzPñé–îËøjå>a'å)­­íßTF|*§Å”ì-‡Oı´­!mÚc‚?‡[åoô-BA€‹z£®ˆú™7#¿%X¨†Â ÿ[Şe×´”J¿ªRÜACãÏ8ÜHg™H-»Šá"0âşª†¢=h¯¸¼JIq!#K÷È¶&}uzßJ¾¹DÀoÅzöË^ğIàÜŸ}¶³?f9½&Q	áJHo9ÄĞ½‡‹˜*º„ñêË°50±J„£o·½¤Îu
1£ÄÁ»ytƒâ½µ	£‰3•£~\M.İ÷	bæ…LL‹ÆGÏÔvŞÆÌl›ú'4©0Ît÷?[p·«Ó“¡•D= /Å¡ÛïŞæ÷5`·ğbÀ] ğ’Ô'ÏíT/¢jšêƒ!Õ¯ö)`S¬ìsm>7åÉ=.–4ç7@	b|\_ú!C#N‡YñBãÓş­âÓÍIlrØõzX´jĞB:·HN`m¢ñ}A¯YNÌ#ñkj»Y¢tR­]ìyÓVùŞĞX¨r¥Tù:à1áíÑPôòÍÂÚ!ÜÆ©r‘Ë˜ÙÓ·vŞ¤?f†æwÓÏè÷†ÿ8Ïv²ï¿*SîöHËñÌ#OrGH8Yºº˜›7Nº6ÃIÄ‰„‚¸·­Ò¯õ£%Ì“e„·P\
rÈa-¡sP‡$¢r:›šW9›åQº¢ÛcD9JâhÜ™üß¤Ær!ÜêÚìéº­l\–R*k;}‰SÍ,Ö‰‘ì‚ƒ@àgvıƒ“;]?ª3¡b23É©]fKà~É›»àóaAuş³+1¼Å	ä¸÷J£—şL†¢c½u€"Y¨Túbó"pìÔ±êe:‚-.3wEWSlŞ×úJ§)ú3o%@‚­ÉÑ}äi;?(#¼ˆ}ùÇ
DSß` ´0™F tõğûºfƒ	AÕ‰hg›ï’À˜MyVY”ÌË…ú‡àNd®°›UËN{ß23ÑtWáaÃşö  æÚR¢Æ€: ³Ÿ€ ş`°±Ägû    YZ