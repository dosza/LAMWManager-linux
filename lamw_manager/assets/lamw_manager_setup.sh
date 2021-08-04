#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3700757623"
MD5="dbe63ac4c8c66f8ffbfaa931d036abd6"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23680"
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
	echo Date of packaging: Wed Aug  4 13:11:57 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\?] ¼}•À1Dd]‡Á›PætİDõåğÆ›·ÀO­× ?:/ªgŠÄrµOS¤ÙiÂü`»ªGÏ}÷ğ„p¨íÿqë‡f”®ß­Ÿs×óÚéß&@Ô¢¡[ÚÉ¶5ÇqùK—¤İ,ÃµD¹÷é«Xñ‡˜á'o2¾9ÊAÒYŠ)‡1â½|y\DÁèUFÙZ¾şvĞ†ÚĞr¨\äÑ³ ‹ÜS!{Âk—r§‘øúÃJ”WBÕó˜"Y>zå»V•D¥Ï]¯j‹qT 9±GÕÎõğïLgB.‹¶øö¢ ÕHE°VÒqnar|¡ÇÇA‚çJĞóâª¿Õ‘q]¼ ¡ğ]iúP’$l½f;Ù¥‚­yØ•H²¬Ôû.„D&b';jÆÀ+}÷ä’ô=8qšë¡n,\!¤˜J¬QÓN÷.ªBª×eí™ÌA—ÅÁû½íçøà‚Ø¸=ÛwO_Q»Ø~\fÃÍ”.õ 
Hi;îU„«íû\™Cë¿?o&ÓÙ»ö†&oÔéIAˆå`ûáêÄû•7*òA&•òU$ÍİaÚ)Şc}¸OÂOy†Ç¥ºEXĞ®BX1õµD¡ß„ßµÖ¤#glNëöO®<“»ÑvFáì<{+M¿_,™“,Ä4}	W’ö¼ÿr&öÌm„ÍEÀ¦”è„[ópÁw–¿á$ûÃ˜qCåsá—?yÙ[_KÇ´¢¤@‚‚tó_Ù_SœÒ!¦%âÍ—,‚†ç¤³°[Å‹HË±P¦¯lâ@K)oÜ›v…ëKøâußÌ`k¨}KğÖ|ò¥Î´ë´,Ÿ»<á	×h…ÂòÃ‡·h¥¶ ;]²7hg®;ò$ucWÀm ¸ìWF¨åÃ~qS–âåÀHıeØá¶‹:®‘g3'ÇÓNG5õYd8¨²,jNİŠãCÆK&õ³JËãIu‘2c0HÌçÌ€»µ
ûÉ‡£9AÄtêËë\ÌÛ·İçgfYúª9 ½¼ßª°QDK›ùš\Uöà’û)ŞöøŸV9f9×`ß–hñaÓŠa>42´CrØFçá•sÚ^Ng°†°ï;®Œâ/Ô)C—KAŞ©²ÌwX&É­ªÎQ
":'ÙP¦flÙxUT]ë âÏaÚJ1æğÙÄªŠÿ­{Õ_²àì#£îìXJtaNÖWùa4	äëÊkÚä¢°íŒ¶I†Ã†Ìé-´ö
œwpÜRã@¦E\ö©sÆ9PjLÖwÉSgÃŠzªx½o‰É8=xßäş›L?mªú_ÉáÚ£Ö[Cê €üÒ#S
€9X¡£¬hâVxõÿÕXÎÚ_våª!EåpÎQÈå‡Ó6tò¶´Ô ©½ï¼0€¸·CÀ„{cÂèÊQNn;†¢w¶G{‚WşÎ¯ŞBúrWNdî52Ä5SÏÃ*ñßg^lOnÎI=%à£Ğdü`Y§ÀÓ5Mı´$µ‰¹Ti;<·[¿=ßAüXÀ­(Ÿ7Ë“â!{\v]ìé@ßv—³Ú`¤E×q]NN8Ö:Ÿ7vî…J7bs§ŸÏ²µ·šÃxëğ*YA€ûóå.xë#‹-S3>‰ˆ¨=ÊYdœ…ñÛ(
1I§õ¥ëX…¾c…á<Û }ŞŞcc»}ÇmúNàeÔéx†ĞÜy±“OÔ÷£lA:QÆlûu"ÕÌkdKJ k’‰ßZ©úçæ‹0•h pÙ²Û!5}ÔL »Õ5ÄK¦Fº?WŞ»åxîÛ¦ª#"Ô˜Î·ªá²zI¶CçFûÑa¬Jr>Ÿ–Y†$ÜéÚ™Ñ©ı‹+êRÄÕÈa*O1g šRşÚkª¢°¶ø¾ö¿µy€Ê-?f1tbäÑÚJ÷±­ö…å½/Í«/™®³‹bÙ‡ ÜòÇ-èAüGå³8e
xÃLÌ%òˆŞ³#?›œß
z?Y®Çl[(„Û{ÛxâŠ°º–rõãÕµ¯"=?şn¾(h½sÂ#…á©‘L¥KÍ, _†¯tT9À›9t!pWçÄŠ'”?Øh=é#Òy¨üÑkwYÅ]àÛF©œ.ÉÒŸXó­ø{&‹¤^Ú–»9¡A”:ÜÒ"?ÆÔ«Öş˜Ï×í²¥¢´Ø4
Ñ‡(›j vppA‘ë¹ª2Q¸hQ:»óXíÕ=IÓĞÛé÷¸xvôqAjÇúÒÔ÷”Ê/£ óØ_ ~“”<1ÍP\Ø¶ƒşzjxïgã"tíÂ\ğ•d¶¿Z±;9lq]ª­ùÚÈ*†XÍ
Õ ®RCó
®AÊ‘÷V²&P•6+zÙ¨ÂşŒ†Dê%Q»úÔ“°÷Ñ¢ŠhÈ71-¾3æÍ™ü\Ò»Ç>pí^·îÙ¹Ë\Iæ“F{µ*+ãÖt#‰Öü·Z¡‹ç´z;\ÊËô1Õôw,±VgŞptÜê?cJĞ[¸Ni²Uy~–\jT´r&®"¡B‰£ÔTc#èŸ€¼²¶Ò¹HW0_ ˜÷§±ÎŞÛ·XÜÂÛàònŸŞX©¿"òëíN;YVS™›¶uœ14lñë±õİ²•ÿ¦½9Âm¸Ö±Ù‚[%Ãå-&ØL^¹´X¼Ñs¦‰,ÈÿmZÜê>JiÜ~Ä¸ä~ó©•+€›Ÿuù†ĞÖ÷«ô„3sÍ M,!÷ìì!š©ğÑeÂş"6/^â°IáCá3²º¶0ÿëÿÅàÖjµ/è”‘Z“k¶­«éI|öãö>ëesîmñéÃ€,L0ĞRÃm)7ıû·‹ƒ¶®Ì;åa£Ğz¬iº~Œ¢¢²>;nËf•ª¤sQâ
e•´‰Ÿ&¿‘‰‰Á«é„š†åevY/ä¡Œ-™Î H3)Â]ø!Ø0ú”Ïå|—c;KQ¸%¡Ö&¼äğŒ®òM¾6Ôô!—öŞ2ÄìêŠ#ÏD´¼-Ø^ÕÅÁP9@6yÊtŒ<ÇyJZUÇa%XØ“3Ñ¿Ú
¡\¿µ…×Sª WŞA%î>YN&[ğ¡sCTÏmJEâ“…%5ãOú}À ÕãÈDİbòé(ıÆA’­{5×® C‰¹YëwÎÅ´Šº3.««5©!s3xˆÓ2ySş ”7„Oì[b÷CùŠM
²Ø‹–)ÎÉšı-wô:¨$"„¶è ĞU·«7BÆ›Áy/¯Á±/zË-±©UB„_f;GÑ°-ÉíjT>Ö”·fù.È Uù¡TÅÎóöŸº$Vb>J:›MœÌÑ»ƒ¤mq&ñyN8Ñÿ½KT£$G/”ìò dÆÎG¥zps?Ã7<×’YIì†-¿€½1Kqƒ•µ>Cœ’I=6KÓY^Óº«SÈQQ&jrš M?Š"¾ãóÛ	Ö¦Ÿ60ª¥’„Ş×NJÅ÷Bhtæ,×r\Ì]%!o^µâÙ
 ‚Ü½^aß‰	»PõzP44ó{rmš‰õšâ¿áˆùYb×;İÅ¬xlñÒ” üJnßou­ÆÄlı&¢“¿®÷	ı–MÈ¿ûV–»1•MäåoRÕN!s7oµ”—’İ…¢ÕõekI10m{hô´Á°\	3‘ú×Ì|PÕŠ	M¦¥Ø±o_9â¸V[
Å„¹¼Ë¯ìeİÛ	dòœN"išíÔeÚ‹OÁ¢ŒUÂ¡ç‚ÂòAÈÓîè­ÀAN;Lª3(\æ?q«{ığ_l¹/ˆ¼óğ²„ÎÏu‘&(’à'÷u|èÇü¯"aÃ2q¸~W"äÎ9¸7Ÿ‚ËXàn+4¡âÑY‹'½±#ß @4Z›ü“5kí!‡‚jçœ<|(ßÑL qO0°Ê}¿9ÍåkİÀŞï[:|‹ĞßÙ}Ñï^Õ×‘g#öÂ‚ïV½
ü%”Ô•¬.È^Ä$í¼& hrmß¿ë©_Ñ|ËÌ^¤ëˆ8É¨u×üã¢ƒ`G²h:¾8‹—¾Ø)<ç6Éd×‹°º ¬wC¨üÍÂ	®p²2dŠi²%~„Q[gğİÀÅj"~|dM€³{÷átÊ\áƒ/'¬ ®à—…?@]Ïƒ;ÊKl ­œRİşĞÍItŸIàÍÔÆÏf¼^±¦øÎ¢ß‡ã(—û
*Ş…Ûñ­¼a?¯ã¡½tB´ÊÍaYïnrwã‚¬>]­&± eR:;Ï2*Èó/§C²¯èÑº:»¾ğÏ!Ö~¼Yà¤%5õógím£‡å®A}æ\p0kt·?òà–CR*°ø&ù&ò¹,óhYxï{é1T5 ²è5îFÃğ‡_{6”ÅÂ2*ğˆŸ@híî[èLû “ÏèdøÛs&ˆÔì¢òyõQÀÁÚÛgÀ[ÇaNV/~?T6§8FwƒÙvÿÔìı«ø1ìÈ¿–Œı¬iâÛ«(›b˜m¨3îW¸Û‹êHûœÊítÁßíD>sŸ3´Ö³Ÿñ‰fx/öÜ·K?”Q{9Ì@bª80ù
O²ˆ(ûG&Ğ³¸>é„ÚSÚtOs=dEÛºçñ¶ÖŒV¥5QêÓ×.6'ÉÇÊ`¢wŒÒâ*·LöH4áÜu²ë”…DŞáá}m_‡¯D\ËôÂd iÔö/;˜àÜ}M)jC6}bËt•ü—ÂçĞV2EsU=Ãï!Rÿa$ÊWJ8àà¡D¯~<E+,ŒÂÿı‚l‡B„Õ8×S$tÀ¹>}0ó‰Œ†Çı›`·Z_hùç6Øz$<ôånP£mÃdüo%œÁÉéQ¼xTØÊh?Á´9Ø	|<Oš»ä3äìrÛˆ¬(Èò0²Í@À»ïÒ
¸ñ\Îb}Ã~–9—Ô;©5e^ËÅqï?oäIÏ0hßy½µÕiHZ‹“•òÌØw`‹	5š0Ó:ì"´…³Ó½ZF-ìßëIb® O;0Ã…½©Ë¥İJ„ØšmÍ}]àÂhìãÚ%!ƒİ "4#h|S—4´±Éù3dÕt3ˆµÚÔ°.	ÏK¢ßÕÍˆI¥êíÜ<Êç,fÖâÅÒš²Ïy€óÇÓ-?eŞ–&PÖWÆ400ZåıŞ¦Œ£mğNt°ì3¡ï»¯‚¼Ó·ÿÓQrú_—ŠĞ&¤~T}Ç™<ßŸ€åÚ³Ø/*·ø4O}¿M†ÔecH]ÿ¬Êl—ZlÁõv}ÿCÉAe`0e¢ôüèˆ!Q˜nC‹ $†p¶¥½s3²gã‡aWÂQ¾¿~43¢ÉÊõY.PxA3Úåõ­pôË?ÍïT,8 ‘3Uä6#PeÊyœ1½¨ŒBè™iE‚2!8õÀœ°%îÄæu\ê2#{'T1Æùr[6Ëm¤¦=öjâ‹Š@ßBÌ#Ša$ñ³ãü°Ä´¦ŸÍc5ÒË7¸4_=@Îg¦­äxíP×Ñ	œ-+•ªÏèGà2ÄfWÇÁ¡nß
š²‹ÈB‹\Ô™g8y,ŞëÌ¶(oqñ+o–YPanRRh·xÌĞb3cN` UZÍ 1n›l›„Y@Sø_Bº¿©¶™—Sr’NØÕYÏ"şÁ«GB5W¶0´Íp{‰—òÅhÖ(“¸èáV	„¥1=¾LŞÌRö0èd&ùSy¾ÚÅ»£´`Ì±"ö^[påÿ±NqrõõEÇœám\HiHUÇI»ïÛ–ÛrÒ Á i”Àü0w½<3ŸÓàLØÉåÊ×8DïR2‡lÕÆH’ıP9Ç‰Ú!BçŞåC`·ÿšûæa?ıÖzyõs3æ(•c>Uè@¢¨hŞÆ°q‰@~û8£eÔ5œ‰şÑr Oÿæıjef)0—÷öÀ8ì­¤ø@m+ÿ.îy‘ìp ;øÙÉE7ë°èäóï®¹Õp½ÄPÄÂá¡We´@€RrÊ¼'tAëëZa/šÿ7şùEL±3[Æ˜_és
J÷ÅT¨´níĞÇæŒº?‘Õè2Ï
Û+)»	’bÉ%/Ş†œ¥‘Ò÷J
êÖNÃÑptËxzPª¬B8_ıÿZPÓÛ˜DA\(ÀOÊ¿õ 1ğ±]ú®YSÉ²ÄOS47…ˆ6á9¡Ìàè§äÍì‹Ç>p´BÉ{­KxîfÒk!2E¹QñÒŸQ&få`U™{QåÑ‡zÓ5Ú„B\<ï"L4¬F¾3™è¥¼¤ø5~³bD¾š0á:¹§ÈåhcD´ñK¬W¾TXôé„¦]aº¿4 Å
Lçh>d PAù
î/}SLA%KÆ5Ë0ı·¯–x(kÂºÂÑDuÄcèÎ›Ş‹(‡ÿ‚i`Mà3	_vbÖƒjÃÕ,å?¿mŸl©¸·R÷y°r‘„…}qÜ‘õDXê±1ªv çû“KõÅ„ª$Èöè€VùÔÌs<•… ÏDÍ%+¡æ
9yƒzŒ9è… Q?:ÄJ„ËÊ¸Jzôp¡eé^×|cy­w{Ø­¡»/…g Ø£¡,= ]7Ô”âTì™GÙVŠ_ôVü[ÿĞd8R7«ÖT#áÕ]òêS·©ì°åÔ¾
Àgnh`õ’êÌştSM’3
pïó{B”ìİÊßxÄâúˆ®ñò
N#kJÑ¶ÕRã)Ù¨å4j=†”œÈŸÒg‰6¡iDû#¼ÉË¬Ñd)oéj½o;)?îğ´ ?RF#$~ksJÉFAI„š¬,æº_»ZÌ`éq\6uY6XTqOMĞ¥ïËq[ñ€Éc%ÜíÏ2‚.•J+ˆ˜.Nù»ú‚ˆùÔ«_¿
˜ÔïSÜe™½óBrŸ?‘Š\R— do; ÅwİE'""PÛåÙªùÔĞÃzF«K¢ÇÃq_»/Â]œ/wg?–;Ä•4>¨ ö+iËÂ¡‘8“LäÆ%Lö”ËÍ8…×˜Ä–‘ZUeÓ~÷éBáéa4$&— Œ<tX¡Sh‰¥ºğº¨Ù²­©ƒhË6©ÜÛšåŒ˜}“øcV1÷&d¾Ât™‘iÂI*ğ/Bq,3¾¯7o‘—”Ã1H]¤g¤R¬ÇDŞc3àtvrA2›}”Ó0$€º²š§À.PúV•»®¶×0çošõÌş:ámAõ)6˜÷CÍ]¢]èé.¯ÿ‡“³âÁçb‰¦Oİ”ÔSçAóÜøt–£vÏÁ¦~>d
%ˆ)`N€HhrX“üƒôÙÆF³SàÍIæ÷Ä„/Q­"È.õ>Ø<Ú‰s¢™*¥ÔáQÚ_bLHÎ]ÆáŸQ¹ê	à»ı¡Tç\ûf>€²‹§5¢ÛÑ:“ªL/êÌ¢ÿÌníØsúÓˆ™%F†ë{	 IÀnäB‹ö¥€kw¿¶)Œgd~·¢OùÀìäyø 2¶ !¨ö‘è„t–õÃ*<Ú6Ş‰M/ü¤ĞŸ¿’ò` ¡$ßöv9O+*•ÏÙ‡;ˆ°•[wHhgƒWz·Y¬!w €ñÖÅPZ®ƒçšqÂÜ™ë¯‹¹ªÆdã1½ğ¤(Ò†¾çñ‡1‹'ZØ	©nœ@²æ¿û»åª¿†±`´_H>cnŒDl<ÕûEOãeØõ~ ã#¡XÅKÀ§Õ¢†õÆ±^ØY±Ì‡´¼	U{Â9“RN¶%y×qâTÑÏ‚ƒ-„Áğ5Ö’â¤Š"ˆ:=¡O;µbªHFâRzìƒäÇÜ³_Rì‰fB1›³l´ºu.Ã°Ç™â‹“Ó>wäY`³ïíÑ¾Ş³ètsyš8$^Àji™1IHÁ|Š~ôHL¶cÛøca‡-V™ğd¦´U ¾ŞZs‘Œö/¬›LÅ*\ICnpß!³şA‚Ì‘§«.ˆ5Ù|¿›Z¥
–VÄóø*Ã·Jáíœi‰’MñàwÂ¾Š
ŒU„Ã«‘U[WQ¥±_,d}»ÀU` Ò’X—Ù€g]d{Ó´Šç–X#;/Ä¸ç|´‡^1:{ì+EyºXÓ\øÍ­föÖ;U\&*è%ãûÏ©jñÃc“jùîÉ|àx=3WÏú©–Ôòmİa)½qœ°"Q\û%Úİ,@¬cYl9÷yàÌ$ï	§lÅUk¨Ã]½ñ}Û3°4ÜÅÜs×éÀ~ãÓOé¯?'‹íìË[íëP¢„@ğ½M’4íĞ ?òûdPâkP?n%~ù¶ë0ş»¢*M?tÛ%©íÄÉBA:”ö‘âÿªíÁK f×b¿Cé"»‚‹ËşëTOBaw†çïóTJv{ê¦@•KÓwJ|)Ü§”¶='ÀË\h:E"EpêÍô³Ÿ˜ƒ”*#¨6%+Ü»Ô$Ü<Iq}›¨Š öx] øj¬Bè¤ÂƒÕ¾‡¢Ïß¿03Ğ«)&xw8}t”o®K8™Ì™/¡3é 8 IU’j{t`%¤Š#Ù‹ÑÂŞ46²:õÅ.@ÈÙ /!öÒKŠtW‚5¥ı§ñÔÖøãªbèğj/C?‰Êé)¾šRqt“v)+û/¿'	]Y2o™èØq‚ÛK³¼¶@óyhà-%şØö}™ÑG8¼â¤÷œiaÓë{úÛ„šÒ³Ü)Ì 4Ã/0ï›Ÿ*İovÇØcŞ€EIOy_!šº§—„(ÔDU$èºÄÃtè“½zÕNš8n6ÖùÄÁ³W¹Gš=|¤°ûh|!ÃÇ³9`-çÕĞúEF 7®(Ğ‰ §(ÅÒËL~. ¡ŸV'„íÙı	ŠøØÙ½W3»\ê»›M—µı=ĞŸW=ÅWìÜ3İ[0L3”¥uAÍóÁ—ìRLşò=mqô–ı>óºyLĞîSÁòrê||éC‘şWzê©2°dëÈZ\¨'´œ rÙ¬z…âjØëX‰›ÇØ¢çnÁP£\fú©FÏGIBûáìä86,ciskãiûğÁÌ ŞÎŞ–Ä¥Â“e·éWh0¬F‚ºµQã&éÃ¦>‘m£oóŞwÁW»•îë®„@´Ìn™I@Ï…‹\X@&Dİw™ÅƒwZóŠúˆß—­$ Íeî½ƒiIF†,¡e›yqrÈ·ùMÃäÀc?ÏşÂ(<Îı_ßÊªµÒGd+íqØ •-ùº ñOÜÉvëk<eØTGî<
1N×åÌ³pâÈÜÛÆk¥S¥*%¶ó¦
¢¸‘QÁ8?ÿm{™Ê2Su¯s¨;'“ÔêdKl¸T‰±›VM_ƒQÇO¨iÎ‚æÛÁÆv¤âşœ¬"J¬ÇjEY6|G†`t8·é7^y7I0¯;îíŞq#2A×æÿ¿h”°µˆ MñÍ¨-Hçı;4-äŞ)%æªº7Üß+÷H}.N\›ÃÌ7%õÖJ„~y‡ÏW_tjbú œ$H§Ÿ*‰€OOrÉÀ‰€>˜<<Ô(œmìèeÉ~d¹búg+P€ØDv'2Ôì™m÷H…U½z™â,¢cV%x æšÊŸ½µß/ÄtVKÖ¼º&rn·¸¾{gÃ´³B,}›Lÿ¡ùı#Cyñfm ©†“t¼O˜åÚ•A{Ê¼„¦€öœxª¼éqÔ!M"„HÛ¡^Ï¢ o6¿¦y’üîé¤ÑJ©µ÷âl¬JıD‡&àHÄİÿ57T˜ÊÓ{EÚ†‹ÈZK¼6£A™:q)Aê®˜^8Úc20áØ¾‚È·¢\uU¢Zf]c‰S*qLÁ²}#º€€Mó$Ôªâ½à¯Ï] çP»ª6ğÍıù¿f‘P¬•L!ïóc1\ŸL/?–@‰DÁŞ–Ò´*c!\9:ÎoGëu“nÄoú»™vãl±ê8bºkògz£Òéà€b»ış9½³U’»Mî”´ˆ #ä¼íLÌŒ|+Iài¡FûP{(ì’4i’ƒU2GY4½¦·@–ESÌ;¢.sC2â cl×!]û8%6„Ñ­ ”Xiıâá½¸ïÅ™û-Ú»6Àœ-C™ÓgŸ´r >Ş/º-9ED?óø¼›BgÉ€¬²¯ƒÓ,ÒÇçõh<$	tIİty|Ñ Ì§´fªÊ–oJk¶ÇVª¿É×yñ²­*è½8ãê"7!Ÿšv}ğñò×ƒ1‡Äïİ†Õ†€£Áædrçë:Fÿè—×şcÃB¤é®Y4-V“[’+i¡-‡Úİ½î¯O-Ù‡
á½aôk›äÂ,	ûœLNöX!“a®ç9a°¤sÊ„çfR¤¹‡
ÒÇÜˆ>ÖšÒu…®ÎgAzVYÆ”]øMŠ8ª¸£]ï´lÿ¬°Í9ë¡ëeIÊK²ĞM¶>à/°~ò»|my*(RŞË® Ï‘d!˜@é•Âıx{Ø4Ök;m6ˆô…QYıjÜ¶D+OE(ºIWÛ†ùÛw"^q2~—ú8·C4bW$æ‹®„!£3¤Ã¦1”lÕB””QİºèÏíğc†‰`YzÇAd?%7ªÎBsıFÅ»¡Ô{âwãÇ!H²jıª}éA–Û°ˆÉü ‘˜¸D43¬S•Å«}ótq]7§Õó÷XÁOİ³fHµ8z™(û•y%ê®KmåX%Ÿmaq‘9	ZøùÌöÖ^‘„aä­†Tqı¿'·Vô·+Xba(Í^€I·
Ší¯Tš!é6Éˆ×Ü¬Z]®Nd±úÿæ•*ú‘	SËŞ5'Ç“½Asú™Ñı'÷¸qƒŒ’Ê‰)ĞÕòŒİjä6€õÿjœËä_ú[µx œÂ%Ë|—±3â=¦•‚ºX^9‰‰\ô'Í"]}4meÈ‘k0Ú|È$^N§®æˆê‡nĞÅ.46¯´23*é"Ë=ŒSÑ|ˆ¡)–§ÿÍ–¦Øƒ)jSg\Ia |ÜØs’³ç6óàÎCÌ»ã/Ö+}'ğˆõÀÎMÔo˜Ht‹YlvÕÊë¤·iYKLôaI² 1#^t†‚zğûéte·¢à6şK‹m\ÓqòZ]ÓÃ'İì¿˜hviQ:†©-aRG`è•²0jş1ÕN4á§vÄ¼İÄ¢õÀ^¥×„>ş³İõõñï4î åAq'!;Ã(?æ˜–(ï…™Opj)HÖÓìƒùø›ßzw4åÃÄ@@›Û»adal™áÍÒÍäß¸Äˆ´=WlWÙ¢Ş6uùÄ<­8¯¹¤8³J+¦³ıÉ…GD¸2â_—Cé{;2®±hwb\•dÓeX,û83
Aì7ÏÆØ
/şj~ü© ¢M:¦ßêÈ{ôÈ›‘&Òš»îRĞ	¸I¨[˜È›öÍ®”	lEä˜mIƒós¤ãr¨ñIMÎs{>Èt÷vj­üA	úÅLû¬a;w&}äÓ€Ì¥¯ı&u~ÿŸöİÙW¸d™9ğèB|–¸Çcm¾â›”©(·¨
Ğl¹QÆ}¬°üLÀğc¥)<ÁÚedSï¿q¶Y+ÉñPÆš ÔµÖAA?’ûH‰IkH	}e[‡ä»Póã •Ùàö ‰•…*±í˜[Fà‹JÁZøiàt²ÍõE"KÊÊª3Tƒz0ÆO¨ÛÌ™Ÿ,AÛ\
Î¤Ø0ï®^ù8ö¯P¡Yµ'mä%Ñ±o¬Øİà*ˆÁ—¦Œ§š:ãì2å E~Ñ
!âÔ`–-€éQjØ òªÑ£%‚â²Ã?wİpL/Ë[	mq1L»æ~Y+nï_Ş3”Gú<Û£à5£DOƒ1NæD:FüêÀ¡€»ß—Øv·>½êq…3½~šE+†Ø‘ÿ 6º|ã·«©¼ M^Éí&WëĞMÒ­Jw=‹‰ƒÄ;ÌèêRh9Ş‘‘UÄ¤JÖWS<½V:µÎ¤ëO€tˆ_
!¥@ òÓ÷ã€ÊãK¬G´ÆjÔ<rëç#g¢ğœuLö]›g'¬[Î®-ã%±ÕXœ—lÌÅkC¿ÍÍ^:€Š#vÙ­R©„‡ş¹g0WÅØ)é°é‡ÍSH`.õÔüİa
‚‰œ×h˜C5öF»ñv-ƒÆ‰O	D_l€¥ˆ‹•Do­,˜t´‰Œ5Py!¥vWÈÜ]”"û8Ø•=µ ú×eê1¶¤o¹$3Õ"m×µXGëùèÍµB¬ ¹«hhš!ë„gÔ´½ÌUÅïªÂwkGbÁœ›}ş­ Ø1¬SM.Œ.Tk{±1Û·z5ÑINª‚¸`¡I’u±i:Wƒl4¸öùL6|Æ6´{àL8³Ôèhp%¡nüB2=ÊFv$ïÌûœ8'ƒä
@°Éá¶Ç˜©²šœÑ	ñ<åıÓMNÊ¨ jUW1³;¢¿Zß>iTğ'w…ÙŞkÿ=C¿A½’.ÔMš6ÂJİók~²‚=Œ×¨ºûØ/YEbSj¶SGÀO1Á–Æìûß´)J,tÈs±Ş¡—ñeÑòBJ4?¦'LQsÎ¿Ğ¸H¸Ê… >pfù@w/zÛöX<MÙı˜3TÉzaœëKòˆîÅèã¡Y%9R,.ÕNàÂ™¶y„”I\FÚÆ(_Ğ¬qå¤}çÃúÏ~)¢\3•<¾óy/µ¯š¶x¯â„1ØŸ\cúvd\Í“xø_th/ûúÚÌ–êà¶ƒ;WÔ}I1ÒŞÏµnzV“«·ûŠ×Ó¥€å€m•èmîz5«º~Kü#Ô‹¼(Â•pnœFEiá°¸b·w\·6ğÔøçMAJ²J«]¬¼d_„ú \\nÕÚhHFH˜8û™'‰­Y'6ÙG×Çìú«¬Ò+¤Ùk¢¿·ÁÇ€>Fë ÙÁÆ€RÁĞ®5fÆ4^¦ü*ü¼QIà+œİŞ3{UÍüå»}uíëB³ûƒ‚/†ïUR¿2u™Å¸  /?1ù€&t¬íT,"#èÇ„‚_S®çÈ¡/ñÿ ›Àıy¼üjI2%MMÅ,×Ï}¡€>ãôÆÇSü¼„Qwb÷ÈÅÿHLœÃ‹‹¥5ZVZ)²ûûÅí”Ğ@¥7­êÀh0Ãû(wâ=$e	Zİ’‚+•ò)G2*cÉ'Ò6µ«qK6¬x`w ©fc”&Ì²?€Ÿ6.;‘ŒÇ>mnzI¹/—»B2àü"l>³°¸¶*“”WÖê»-Ç,$œ‘RcVä¾HSÒK“¢¤MáÔwBŒ×~æ^©í½m]©áŸ_p˜'ËËá­ĞtYà]«Vnñs.£™Œ£+°ÈD£pAkÓ´çıLÚVö*mõbe‡Á°ÕtòSƒi´¿³/)ĞƒY¼şTîÇ&Jò¯&°8ÌÇN»föw¤“¤ta¡Oªûô‰øÖôú`x5mcG<=LÍŞ‹!«)Å·µnjÔä*X„ù?Û­5¢4–Œ£¹åˆ?A¶vòï•y£±rx£(õL^l¹;9¨©².lLlU»pÜhïô8(\o«
ºŸzŞŒµkäå›>7Ë‡êÄ¥fw]ñ
o†ËLúÕÎBx·æÏ|¾3ƒ>çæÊD¼„^~íå÷e:/J¨¶?‰¢ó×EM—Á 1Oy>|Æ?Â~“& hM±Lv˜L‚WŞøEü^4ûOwİ­ñ¡œì,WËZÌ±véë—[™e—¬Òï®Ü 81ühág¼P’¿¬òl8ıäCº
ä»şaà²P`Ç ¤¶PÑûp,šÎ–üàíußî æ¶¯ò”Ñ³›3ŞM-+(¹(IrÓhf.T½hÓ	6şiÛq¬ú!MşÍ@twµ¡d*œUaò6ÕvLÜ®mS»óö…Ë6?×Auªb²ğkõñ$é.è¨m|,lxã£†…°J_wU ÉIÔB¸äÆ)ûùÿMX´PZMçuõ28‘&l´—µ«I°2lf„¹Î|RİØÃ‘”5±„„A±Öğ,‚ Óƒ‘c§â¾¸²­HÆØ»ºân*t¹’!ŒÁ=ŠvŸ]Ú‹˜…^m±È–{$½Ç\!#Uò_¸	)æ-º_:””·'â»h{Ø5zi¥¦hzW›måÃ¤{ˆğÏãfô±à…–V©tŸ§Úµ¾änÈc~²Ä–…©ç“×âh’Ÿ‰‡òÀàé&ÔGö¨í9=foW‘fĞş¤#ÍÁõ¡åwğ<L`O`Ù.®è éu6 ¨SQÊ0A=lQı›–Ğ7òÏXÔ38­ãÜ7¨jºãH‘ÕÈ}j®Z´İ	…Íú»!®Ñè>‹	ğ÷¬•p{¢Ö„Èh«Ï¿ ^_ú¥ñ)ßtäñ¾YP\¦3„6Ê; Ä–‹ò³‚YĞ†ŸGı½pU fÀóÿç:Ì?º¤.o´N¼ÎÁ‹+QOœñ\Ç†y³š| İ.{…Ü¼\AĞø~æp¾6$MF¿çUR47*ÓÀáT§Y’2…­ÁŸŞ]²#ìşMMY½Àim†ĞzçÍŸ GÉ!·Ûå­6N›ŞÀÁäÖƒKoeaJˆ÷Œ*Ul!zF“®¨ª~Îª‰?2jÔ/æ·Z~e–ŠÂ¡rd€ÙÑØÌ}`à1%[Ë˜GÔ=›KcÈ<üàØ‚†kŠ÷º¹ÌN”“%I·ö]ÿ±w{e5„TaXú¡‹_€‡Øõíù"D2ãü WÚíCzt²ñl‘JÀ×’f‚oNİ­“P¨>jàS×›ìß‰›ÇAº‘¿—cäÓ%à‡Ï¼ÍÎtHËt3Š
…±™ZšöéøTîìÓgµ…@ªào¼móta§»@ÍaVfÊHR´´×Üª¾ˆ=È¦Ğ§q}¸“õj`“gíVrİa†&§%ÒşXg®æ·áq·°›Q8+c‹iDÕNq?i=ö+D²Ltl 9öbéè~àzMÇ›>ET-ş°Í(í€`ùa-*£màÆÑ à¨­ƒ:¾tïWnOJt.£wÚóë>ÜÜKÔõ¿,¸ıÉ¸°nC´(M¡¶Ş—[Æ6|m[¯İ…iõ–¸n¨ìõdÛ]Ùt}Ì³S{®TE”ê‚éÊï²ÓlêË£”Ãéèi+=:ñâØ×cò,ÃÉ¦ãà:‚À“H×Í‘ÃÆà|gwÊ_AmµK4ØÃäQàió§>ölùQ”I3k7/	¹¼Óñq£
´³„¸JøªcQsŒ„JŠHYfQû=‚ÓzZzEƒçGù ú'úÔ“s·ìa9&&~Cxà:IĞş› ùà¿-dF¥&û±zG&Ì©BÕâµoöó–ÁQ1âQ>(OV¹0SŸ(¢Q’ò:5ºî‘ĞHÂ
‘H‘«1BÒ'äìÓ,)Šnƒîà<jÓoµ©Ü†6ÎË6“GúÕ6U¬‡ÆWº4­n˜;ïBİŸdÅ¸äñæË(0K¬œ¾bîwá3é÷ À—¸ƒ&õğÄñ¹¿2g‚9´?~„–›ŞÚïG4›¨ª;cIÈ¤,½|Ä]JŠˆğòC|ÿš˜òy"7ÔØ[fAèÿº;^IÁ^‡wù×^!K­ô"7ûí˜‹˜ÔiHHñU*6	ğV¨€ïüAş¤÷ñPş¾Ys¶96krèj5)–F“á÷™k§,OJuXy[B“IØq/_íf¶w78°S‚j·w·/µ¿h|
ùğD@Û_wèt`õŸ"lıÁ©Ê¡®â?#¹u› ß‚-¸ÿc:qvÓ2ğmlã]ãƒĞÏòn«A,{ÑßÃpî-ÚPxânD
3ü,äà]~”IåC|êöÏ¸™Ö±\øNâº·/Ê>ÆÂd›öóò6öÕl¬•İËÍæC2Ä“ÂAª¤m6Eÿ)üëMÔ&&z*4èÉ-†½6ôk[À{‰ºl5èàçE 9ú Î2S¤ËííÅœJ·îğq‘1‘ZÌÕª­W-ùƒRè´·K…pÌPHÑûİÃb ÷7D/t÷H¨Ï‰„ıNûÙeÉÜ…ŞÀÉ2å$ÜX—*û:£O¢ÍhÍç2Á…'g¶­%F¦<É¶üÕ*°!…¯×Eg"ş~E4±m±`Y†-‚ï¢”ùªÈ_œáYó¬Z-=o1İw*¯8Œ$i†(ÔÜ;,vUJ©Øç£K?£ñÛl¹ı Ğõ{j(¤œ®›:‹uRğq|ÓŒ©¼ƒòïô êNÆ¢‚÷£Ÿ9m%¡làKudğ4Ş=_ ;……–ÁJØ›(ÃÛÊÀt\1è·Ad2ŞË*PI`EÃFnŠ6f¾ì#FÓ/‡p›39…÷.Èã"Z{1X•ÄÓYÃŞúŠ6Šl¸º	.Õ'òÜ*÷k†,ít‰ù«>YÂõ©¦‚í¶—µ2Ï†‰díê›ı^sŸšì’5˜šŸnä§)ö‘|}òfÓÆWën]h+Ø•ÀX†âæBuAõ{ö
ísÁóÂÂ3õ*˜4¨P@(¼@? nö…g´2K(åâêcÇîTÄ¶T½=ÿ’Ó¼q m³2\ÍYvy`6>\#i–Õ˜/>jTê°Üc¾Ñ|2&-€¨†_ß_¸›'ßBôÛ,Hë‹-mH¤ö´©´Láhío“ÎØ>Âÿ…[#
n`I¤ÀÕÙDdü1ô² #ëÁú†ÏEOùÔ›Z=˜¹ş%éÌ	#êå¿s]¨qfìa“ÌäX	€ş»8;Äb³D¶éÂ4ú&\9<’ğ]jOz.±>—²€& q80ZøÛñÙyÂ‡Í@c’BCr½¬‡¼˜3- Ñt!¢…ê¿Q»‹
^,Çé££¿ğ¬ø W»Ú•ÛãáÔ¯{:ï,J‚fßõdĞpDäõ†|î’uİ8jdĞoçÛ‘³<*¦@ßƒÚ|rYòDÚºC]jî~ZQ7&ëxy?lfÒÄ&~³C“TTåÇd_VşÀ¾NR·ÍÖñ‚üÒúİ¦ô÷>•TrA¶¯äì>ëRÎˆ‘ñbÒÄlm#aÉr"¾À»HÊ»ŸA¾€ÿ‰ÕmÛâfD=›Êdü=Vr-ŸKÃ#~`7<ã“»ŠÙ½qW²æÓ	4ıÓiMºøa(ÉŒ(Ê²ÿ0¸BõÉeú±>ˆ"Ö°=ç`ÁµÅLTT —1ZW!SàXªí°±z×«gâFhów–<ª”ÄÁÜƒŒr¬ÿ×§¸µÒÎÛ¦EÉ‹Ç'ÖÙÈÊèˆˆÀ÷bŒñ§ 8Î¥
ùóíİ=ã÷†GCÕŸså5ÅåIş.âxø3ër¨·‰ÆzZ0ODŸOŒÌ\y›”.™ÍË2sR	~ë|Iğ„æŞ×^QqF¢È/Ï–Oê±Ù_¯K%Êa§úõ–SÊ›=§³N¨åŞ[&ûˆÃ^B™µ¥e—}íŸ ÷DKh2Û£`’ƒÁÒÕ‘"\Cš&’#¢-õä8ˆÆ=u:Šœ[¡e$>ó×¯fó‘>™£@IGšB1u®òsÜ·môu)°4³aÊ8mñS«óÏÂm˜–›}ú>Ê¤Lâo*¢–rñ×^ÿƒŠ!”y¹œ `òç¾¢u‚ü.ÆèÚ{¡nŸQ’ß´®\æ0ø¤.
,A®FÏÄW†d÷C€N=oÿ™ãŠ–xJ§¸®şÀIÍŸ¡Å±'{(šƒmªU,|×}PÕq•ı6äºr5£Z,ı$B}'"goó½§(…·eÉ$¤3õ,¨K€èWÚãZ’#4ÿ§¿ˆyËÌ ü¬‹ÏÄ•vfP s®x=¥² VxhQ!äı%Õ–góáü}DÙ3Õìã¶"“k:A£‘F4¾ˆOĞªä­Yşp¯H½VâíİŠÕ¬WhÄ]¹¦“º]ùêœù]ö¿Ì…€3êı'P¢ ÂæxbqtoÍÖ¯g¸{¡9nUÇsr^\,ßæêÂ©U>+3õ®™“ïã}Ç¬s¡—ºJ
mÒ¶¤IZÍqE÷ñ³rx¯<ê(ï!»¨Nn-Ò$Œ .ñ1î¢mÏNı¬6ùNˆj9çÀj°-‘ ÷†søÈ%yşÖAp}If'¼m\©€VÊ*+|2>mY:ûË~@Bw†R%d'êå¯È?q]l†qı2„ÀÂ€ÜÿZU½W†0ì‹«ÑpCŞğ`ãL,ªë\¤²ødAÚGmÂmÖş°Ìk^°×wãÒ<˜0÷r*›ñº×%û£=ÃpÜ9ÎO®Ã×Ík3êCÇ,ıQ€Ãrşç|éğBë‘å3ıºsˆÎÔw
Åë¿@/Í¥÷ğÉEiôh;#‰Ú"v†¹ŒæşÜ‘j˜¸(ØÂÌ_ñèutV«7T7Dk›MãNÎB¬F$ˆr&êW=%„Ù-›”qÁ²™£!‘IÛ) œcĞØFQeû9Ò×˜ïëkfŠë©úÈ+ÃÑö•3J’¡À]éa*+÷œ^T‘x!_Ñ¼T™IÊ€‘Ãs‰©/9@ÈxÉŒ0ÂæbÇëÀndØ\uá³Ş30ÕD\çâ¥¡``=`ıĞÑäo(_y”³CœvB
^ñÑH¦¨Ÿä}L&½Ré7‘»²ÓX®³ìµ“Ù9*è¬¿R4½FÖº|~Áº±ä2äÚÏáeğŞÜ‘BÓõ`'0
Ôû¡ÊCN9N-ßpå­oô¨%/ŠC‡"ìNéP½Pğs¾oÓ3–aÈ|³ã<êö;³º$£8Äç´MKHG§Æ¶%Í ox?‡!d\NğØ¿´Té(ou`|o°±©7Àœxv_úõ•N„[·NSM
<×(âÌÌ<C_ŞŞrIUs„J¾GÎßd&€DtøÆ‹	¿“”€ÛbÑ—'fkßœ‹Î:>Ø;âˆ¤Àÿ–ƒ¸L¯V™f5\P£!?Fœ–wß÷,çî¶È¼ÎÛY¼oß7©§<de‹S>ğ¿'ƒq²e÷&¦J»°#Á?ØŒ’L€µ¨+ÚŒ'Áí—¥+<†gÇå›\¬ y;—äÇ¹5ó´Üfmx\GU½v?›ªWÛ’»DM‡¦7ÒÙËˆ‘yş’8•cY;µ÷Â3 ™›;±©à‹¼8Ç<Ğ3*5MgX'€N OƒZĞôÇ¾µ¹W4°Äi\8‘57ö¨8›vĞ9ÅÙØñ@û“i˜xãøŸtOa¯aúåÌ_úlÏ?`á"­»ëW9}K·=6¡BD>åJ×1Xr¾AzK'Vœæ¦ËïfÓ BÇZ4ş÷C£Ë­m| º_«”/œYf†,¥2\g¯¨-Ô‰ùÁ—/®ÅÉif»£–6W3wq	fû>şó	Úfè>É-9SŠÀ]bú¾¦çêéY
wÃŠä7´¢¸¨j ÄİÛÈŸÖP7Xœüpƒåáâ©‰eml®±ÓÈâ´´ü~4~Ş8‹Óç7Â¾i+7˜ëNnÃ:cá²j‰õ4MìohÈq¡^:£œ'w­ï»(ÚùqHğPİÒ(o[C5˜8DSp
É¤ê —˜X¤Üša‰%VTõâj]Fßo&ó?XĞq¶èøÓ]6KëxÑl\üÔ;»AéıDÆÓ 0æºôüJ‚Vm0“¨|“â§İóº -Ú/3 n‚Æ|¦õaËJi%Ëı4pä¥pºÜ“¾ã€ŒX×©bŠ„¸<VÚP]øèúinŒ—á‚ùëÇ…Ø`‘ZËŠ‰„å“\ì<)K­;v÷² .XÀ9…tÒçf•3[%’½{à.üˆ°ñ$²Û6±„¬¬…UŸWp½ 8>[±¸€E&ŠI¸—*®\S–rŸÇ5í“W¨…Ø¨íöx?¸²¯Qæ3Q[õ>®.ğ)»äFh¨ÅYywú–!Lë!U+_é¸$š­%-?ß<×ü Ì­áLÅ£èµUbz:şjŠÉo>ÈñíùÚ6+ Ì5kè¥§Ø0ÄWreHåÕMî¦©CÜÔà˜A…ŸˆMN}±…ÔÈ’«÷Óe2°½‘Q?ò•”ÕLJfév	şà?p›şP
Üù«¶S¨>H¦“ŞèaULQ,}5Kõa&th/¿«¦3S|IEï¯cò õöïo ô˜G‚şÅ˜zóñ·œ`z¨•v¤Àwõ¬P—Å«²±¦ãÃf< µ¥AªI÷DÛåC‡å½íW¸ÄiD£— w/B+—¬jÈY)	_hpI?‘vgf‡Š™ñ~öBï+ı«ÈWî)'Fu
Z‡{æGV\Õw
l‹ñ¬%½ÿ ²Ú#mIß¿6#û!q¯BNêóªÿŒõ•Fº‚”§…œ^H¶nğ®î’Y9Ãğ“ùï¹.Ö¦µ³,ˆs\ <ÃHÂT{íñôÊ:ıw¯œ(Ã„c¤ˆëkIdù!íišósÑ\‹¨	ZŸo5ãpıÈ<¸ÚÆó¥T‡ùBƒÕTÜıÛ#$¿äAO˜H»y‚óàÌ2	aÔµÌ«‹}ñÀ=*Ñôµaø
W‹jù™Üã•l{eW3 ¦ı
8t­¨Sô÷Œ¥fê%Èaåô$G!ñÜeW!%ƒ#ïJO˜àÑï.â™-­°ş¢ğ$ÏİÌ–é=Q;|æ]h·9Œ‘Î‚>¥KÿZ÷İ$ñ3SPö¦Ï˜kÆœ£›Q³IÌ~e@¼ZRg)ÑPR\’d¿ç‹_°:§-¯zRŒ\àcs°£z Ú†±@ùzáÛ‰lgØâãÑFAÉÌãgŞ¤ĞçúëãcO9CDpŒAª¨‹Y»OĞø‰çºÔ*WL¬§uïºı85FØïÊ†·×Y·y‰$a ®ªmn…EZ&4ƒÙÜèLŸ¢JşF2¡3i.sİò'÷ç Föˆ”fŒıYÆÍÇ6«ú©MCCqß€³ê-ƒC×µe»ÉÌ|V»ö…%½ì$µ8Ï"H~¤Z¼` ×{eÒf}™hN>ı”Hk‘®L*(Am¿	®ÊÚİËéä@h¼ÊC\~cø
¢”vJ—:ÙÖÒhÒF	Ûó>,CÄ`ÉÑÀ­!%ğpŠ™´òô6êØ’·°0‘V²¾SìÆ™ ;8Wk¾v{qy¹¼<ù  ‡|Ş
º(÷y³“bê¯izg¥“QÏŞ^<	yCôto}B³ƒõ,éF=Ñ1•Ae"ñk¥›ûŞ²¦‰&HXŸ¸rJb©‘AM%Gl´2h•…ù„›=¯zYı·	­ŠëÇFèùæ+½\?H^t€T¿|WœeJßÓRB®^O¦Z]i`5ÌkY~+”ôYz”lØïË,\/æC‰M=TÆúÁ)ÿ%8†¦OÛ¥(S·•o2‰W°!¹-TT»Õ„k˜½Aõõæ¯A¥Ò4{4¬'Ï3Fòã……Š!„kZkPYŒbğÑ&¿õ'å:Ñ%m·+¥©ÏwE¥™²ÿ£/ªä|¥jwx4ù·£—®îEc<‘ËJºÒû™È ‘Ù6zôïÃáåt¤ã–Ê uå@ØÈT–RöÚhJíO@Hò=¬Û
¢ªp£	’¸v=ÿßtÅ„ ’&[0&`K*LÒHLW4.õ“SÇî?.åŒUÈó,†ŞW×’$*Ÿ¦¸Ùût`O=ÁÓ¡~uo"e“;8IÊ®†DG§—,¤½¾şš>…\^ñäù/©É,;šÿø†±Ôm»lQ­"i¢+¿å†1ˆZÌˆmÄ¾=êÇO,¿º²TÿÂ(J’3obªĞîELŠİHSç~fŠñ¦ıõ³;6ïÛÚÿÊÿg¦¤Åß¬#şëÇ•ø	˜ûe$bÔIRÜ°²ÀrGu{9éão¤Ô×óJ3—Ì w®ş/ø1eCY^†¡²·?@W%	Ó•TÓtL‘¾“´HÒƒ”Â%Oa«{J"mnô“Îä¦¸¤úğ„ù‚nº‡I”õPådõoX´»­­3M@Ú%n¾LØ­4²E(¤¬—»CkÏ¼qæ¢'—9FÁ,Û|Æy±Ø™µm3ÂF?3}MsE˜ÖéT¶
TzE<ÛQ€?qPŒÌ÷Ä“öãÍ@0œLéBçtÅ{µ$5°ªV­·RİjŒ;4§úÒa•8½À@*âvÇ6Êõr¯V¬o0ŠØ’Ìi¬vTˆÇú^=K L!*¥í¸¯@˜ğYRÎâZb;˜ğ“ù1ORM[ôqkGÅÄÑ†¶$ñ}øL×ßR@ÖS¼ëÏ´©ÿÓN(a¸‚Ö7y¹„,Œ \9+ÍÓ¢¨º Ä]Gi
íYÛç<.ÆÓ5Œ¸ânKô	ê÷$ÌN“/ô?ièÇ€XpÛe¡r\7x.Ï(Lù‘U»Õ€Õ×f{ŞšÓúÌùŠáÒ¾å[hè`.çÎ#ì.ıv´
|S>CÀslŸS ğÈ§,xS§úQàh7Lš¬éB şŸU%ÙüÅ*‚|³ñ{L…gAvé^R‡I:ôòƒB³ª»™GEİ–oÃ B¶“ñã^1ıXplßAÅ‘èØØ¦¡5æ'İZ~ ØÛpì¶”MèKM÷@cßÇÌIü¼ì±?­ëég´Iá¢;oQ¤†í<±f>‘êÃ“j6ëKp¹\b½y$ÍÉ)†‡ ;5¥;0¬9‹)eŸG¾õ Œ00|x}#Úœ®W¥å&÷ÊÜËÁsÕ:EÇÌ¯Z¡…Û‡üÌİ¶YX<Ai»Ó«pR( I_R€A£ ËÖ)r0É7O¨õØÒÏ¥pİÀ®+D'ªßBQõ^a¡´·2óY—Œ¾[„#ÚoïŒ>;eº‡ÿy ÑS‹½Ëú~Ö]Çx¯ıÉ®1G«C½k¾[éBe%‰›0Xj™½‚§Jˆss94Höç“–²ñÉğWZñ5	¥¸^¡ ¥*Zc© q²£§²ŸÿÆ½Ù1¼&mÚPh”9QÊÓÌ*?p æÒ§´š U	`LSÿ¾ïs°úVjª‹~Œ'Œ=[]ÂÖ,ê_vDcKæ™P”îñ¡ù5Ò•4Íf0Ê_ğÒ– Ûğ›yA¸UöïÙšm{tH hÀ²%,EHçùHlˆª0	›•?¿Y…|r„aL–2ŠciPp°..*Ù×IÜ>Ø°¿âygqñå.¬¾p•|‰×OCãD´2jrø\zĞTöŠ.áİe°ÁyËMÈ¶r~ƒ0Öíwû½o€Ÿ/k´4£bÓŞê›Lb}-$¤#i¦™¿z
T„wÛóŞX¨é?ºF|ÑVòÀup1+·şF+ ¡ëˆ>ò“Õ¨sÕ<¡Ø0²™iÆ.)³…ÃWnÜCbe„î÷Éš•hüqÕ!+‹ôœ^{,57…¼İSŸÀËfÌ ·¨¤¤‡8«Ò%ı©PSê?W9+‚¡-D.ÅEzÓ®ÌãmÓ°ÑOZ¥É½à‰Üä:E >é=–³ÁzHd‚äWï}\œ!Ok± P0j†mmÆœ€:Ò2¢ÿàùõñ(\¹áæsb¼"VÚâì,1z¾œ¦¡sMá-¢Ö@:>Æïê ÃœDÉÖûæŠSÉn¸2%JÕ ÊòÚ|’i†½6ZÓòÛ_[$ø|zâ’¦¾-÷œµq Âs¦d«ñ<?móm#~L&¸ïOÍ½³?Ø1uÌ&$~ZŒéÖ"”©8†§öL+¨x€Ka–ògd‹‡óÇ&Ëá8Y‡ï
Mñ`Ëç¦[0i<
‹äxÖğ½¬\ÔP#t.A|¸N¥4‹ÏÒyÌ…Á†WƒŒÃ‚`†>³ğÕâ1ä‰/#°{ÁÙŒØ08 [ÚlêQ!(3ÿ?Kšo	mY¡ U|ß¥l¨~ ö;jÛ–3®² Sx=k°ÚºdÛ³YzY6Çô ÔÏ´	eÔ£‹%öPæ4†ú“Â°î!ü^i“ëw–ÖÛí^Z¬i[Š†»@ĞhHsÛÓ¥*O=áå#©ÃZYEHyßZD†a7©_ø½K¡Øş&‹ì"¯6 (ÅÈ¡D³â;”¸Ø”[ö³íÎ<Ö#şù‘›Xtº{$HİÌïV	m3w¾hÊ¹/ªêf Îö~+°B7K^“0Ñ†Ö‚Mö’Ÿ Æ”	À4Ô2ûƒJoıéÓ2ÆùJdÇxóüúŠî7w€Ä× ^š`Ú;ƒ¤ñóœ	œóÓw^ğ7›Ùî<¾®šWhëÍò9jßk3şıÿS&dÄ¡ÚGqw¢'Œ®=ˆF®ñ²bƒíçzgÀŸåÄf¢èÁ%Á&æÊât`“âCêšëEÜ$ãş•â“CxŞû“àŸ
¬İ?aZ³ößü;I³çA‘›Ân ^ZÏäÒe’&˜Š4”âVÙ£pZâXi6¾LÄ¸idÄ,.Pâ<dà‰'@ÌwÈœëï¤n’×¦ÔŸ¿·¯£•m¿;­Î-9GôeÌIa~E Ûét ƒÖø:?©ÙAxÇ«Î®2tÔ=JtÎ*™´óóïƒß§ÔG¡7¯šr{‹‚û*†Ä6â…:!éjIó„Á$¾«N–ÙèlN·ı®é-vÜÔ¤ªÀ³PYşˆ7xv‹ŠÆ<É	t
‰(&¯d±ŒÜ,k›ÌzíU–gDòØW°X×;:å@Á¸Ä€$ŒZÌ½{›ÿé›Ô´ş}!üT…ÿ–kÄdHºä*ğ—iŒyz{s,šŒêé_ş]ğ¦÷‘ ²˜R2¹ÂæöMôí¬´z[90æw•» ó¸ÖŠÃšÎlo0¹¾„üİÖç_F´)ò§’¡Ö‹Ëëpª[)	¿í&saïªê
[µcÒ¶ÜÈ=GB—òÖ±µË:{´/±ïX´­>–%´†È-ç²G-¶v)~—™~¹1’]¬]‹ĞyÂÓªcéâ­ò¾#o·ñ'­ğ€]İÖ0»ñ]0=&¹”zÄù´7T\wGº#°?\ÏàT4™4Ó²©“EkÕ3ø›ËòŒ ~äóÙ§±fæğÔqxµ¬w»­’ïBC
¶+ÉìÀwm nUÏ†àü$lLÃbÎŞÃ§ ¹¬>·c‡2ŞlŠêí‡‚¢Ä¹çÕû¤cfE¯irh`zÁµ´&­u•¯]ë-Şğ …@Y¢~¢ÿpçUSâ¸&ìÓ‘òCÈ$‚¥^¿]ÉdÁ£Öõ_ñ¯ RÃ¥Ô*2*Ã¨\Î8³uıÃÅÁm¾Dü?3âÇâ‡{–XësUşïºVen1ÜüšÏàLßè]¸¸?#œ±9Qşy…p6Ér›ˆãÏ 1«|T–ıò»Ë‰zıìrù/ã©¸”Ç\ãd1%ˆL—Ê©’ËZ«YœDçã“äUj{hj|hÎ\ ç#È²!İYòië<Uå¨°ò÷.qÅ†ˆâ(L›2Òz¦ü¸ÈbôŞ0äàT%°È0#}Éªc yÎôË	øüó‰Œ— J¬¬ù|üúÃµªæ/Ëa'vƒ¡ºúX;ZúZßVÒ@/~§ŠµŠ·ìİùY¢°ÄOåc6tª+":$&¦ÔH]™#]æËƒ4ğÑ%GÅqÀÚŞÉkj6>4sÕL+bhOÜoZ~H¸b‘äûlçŞáÓ/˜³B¤ÒOı×­ı]‚ÂÂ¥ËıYÖiCGäÿ­:šà¬™5]V
<÷3ic¼
àüğ}s:{
v7fD Õ\4ü$#`¿aÖ¤£T
Î¯s#´Z§Ls‚¾*@ˆpT÷R×b¸á»ƒV“#úHkéK	Ÿ–Å®ç¯æu¬Yª¶ºo–s­Yi°]§i7ãm×cÍ£ßÒ¼•VP,–çt³Ùü/úõø*œ†…Aá b‰ûÊ~Äºà¿úÁ¸¤8Yu>É1!³FÕwŒk’LÌÓ¦Û§LZj·QHYBØvôrXÃ³Ss ç×:Sè*0š	ÆÅ¹f/C˜¶Áİõu çæ Vé7ŒqéÍ©Ùğ]5yÿ´’ÏùöµØŠ†oƒ?ğ¬[«Ì·Ä©İ@ë;Ğ¬sáH×,uh5Sf„,\(F¯²Ù–„ßZ_[Ãá¿ŒIs3»6¸?ônƒ€}Ö÷û’°ô_½ÒàƒÉÁy9la†SÓíà¹"Ìq7-ûJËÕeîWŒx³á^LğgnÕü.³ö³aryTÄ†•^·M\é­IW¨@ÁmAñM]Æ—Xpu±yÊiˆÛfà0Ü"é°'õ¼â†¡½¯NP»g¨òÇwˆ`ÖqìN5Íé¤÷¶wT)f`0›SæÔ6¿m+¢zaà]!©3²(ï!+¢S.¢—‚Ú`#:´Ñéı[ÁĞ0‡C}@½QDyéÛSŞğ“ßÀJ'í’–¤àéÛ„³JG¦Ö,Ó<ªÑzşrh_ñ%pî/á¬)¡Èå:`]vÆ@˜
àdhÿÀnGâŸ À/TıÍF¡ûËé?E£ ª7"‘ª«™Cb%sâd´$k£`šuùç «ÿ[1_gãS_åõ#àbk½¼GÌ­Rê&FM®šPÁ»ßnËXh“!İşç‘qäÎ/qXd×üŒHíË¸Ã7¾æÇ"+à9Q1K&ì¶Ûhø£·B?ôLµKƒÉí-(ºkµF2‰=kúã:0BZ™/b–Ï]Ô·. @R'Ì-cÍÊu ãÙ&Ûè”@ã¼G)æ×™´.­|UiÁNSX`äÜqŞ!»¢£÷Ö[UãŸI×N ÿHÏ	åb$_ôü5¹h'IÖ¬>êoÉv£MH˜TCÊq>£HØê:3Ò¯áŞ‹DI—ãÕğ}x‹’	ízÅızÔ²ÆLÔËüı¯ ¿ß_UVI[©k£­ÿ"•“aBŒImÕŞš )9NlA
»¼òæÌ"h°¥»íŞØ¦ìf“¶›şSôú£}v¡ì_@ÑıpıÍ•}ç©d½ä|í!üÊëÛª™ßÀóq\Rsc`áK––î3}®:†sS‘lROIE¾EBcväû”†Ù|E{Ğ™¶ÉÇø(NU
K±%Y±×è(´<yÎBÚ5Ÿa^ÅtVªBÀÇÔìtg<†:±¾¥í êgs'šëtéã¾DaY¨×ÎıÆTÍªÙ«Å8Yíæ!Ëäl¬€-DtôO¿Ü>Ô3Ô¹Y°©Ã·/ÆĞL™ì„³©…G¼çïğİ4ô¡ÁŸ"ÛÁÀH2wXû`ÂZ‰¦¶¦…Âd‚6€¯±1…gö‚N;
@ô7ñÕ?<ˆzœÕ$º&÷ „¥ñVœG|ŒÑ4²•—ÇAÊ,3ìÏ_ÖÍç~°ì2‰t]¯ÒåTÛÓœ¦K‹ËÆó¦BKĞS®“¹Åç0Rpg ;u
Xl”dºuî!`¥xş8d¢ÜA„¬´ÒC¥p4ûÑ+µùUÊƒ^”6=üSLé¨B0³yä8KZ4Ï½İ­›L¤k½¦89Ôİ5^×û;¦,hËéULUÂÙ¤xŠ·/İ²»yõ¡©şÑªJæ\«–ï!GwéÒsêhŸµ¼V¥à«³µÆˆA”2Òûè7ş§.D×ì¢Ë™Â©á·ÃĞ®0Ş	Èk nàÊ-JfÄy“‡èp»1láÙ¬ÓYÛ$ù‰Œª ğ Ô†Ğ5,pÏÕÙ_UÕC9+»¤G|,(>°fK”Ç’‘ìØHPK3~ÛWµÎàI¨åO; 5ËíÓëÛV`áÀzŒO"aánj’4í¾¿–ë¦òÅÂî»²(ãPˆPSÌÃå8:Ô¢SFoŠ¢‡ÅÀL\â9 ¨j5s@WGfÃë5Ëùî¢¾½Â‡œZ˜;kßâ"âæ¨kˆ–`½p	Şš?G lÙœ–C§L­eiŞìèğÂŞX%*]:%ëñk÷âÙ1<ß­ûæP‘¶@Ø ]sø‰Âë§J›PÆgzZÑJĞ´6?|OWÍJx@’¤xÇò¨ÈŸXË{:$éVäaY€jV‚ÆİœÌŠThúp’ïHê{‘øãÔ7lÊ×>şÖ8%$˜«1 "Ÿ—ö†¾b_êqa':fäuu2e‘%UcÀkî×Ñö½tàšÛÛÉ+FzUb×N±ƒf§·Ö+Îòe¨ré=ÌEİPCåÇĞDªCÇË¾%©º,âñ^F%Üó¹•ª‹Y°o‚z	+ÏšJç<ÂğXo V¯J›×ÜîA{e4s9×?.Í»'4U]é™LÒüSí¨ RCiY¬—TztÖÁà¸TXŞAºÇh€:à&!qÏœ&f1ÔMíÜÌ	°)òÛüò¿9LR8&±—ßŸ¦ÿÉ•¦ÙöËe™Âœ¶¯Ç‡Ì«ØR›2Ğt÷|dMoÆ°`†Â½ãÖ4ÒÖğó´²ÒU­ÊâH«åQfQ§{¨¢•æpÒ|aQfQ„ã’ä÷X~nn*LÌÉõĞá…x«„Í=æïü¨ÒøW“áŠÄM;™BÕ0´î»“:È±ì§lğÃ©PCO2¬†Ş–n'¥zq™ıäXƒ°D¢‰q\T/]`KI‰ŸyhIO»9çÑš“Ïi»	Ú1§@Ìæ’ü-øİ4øsª›«N×Yiö®Öû¡¾$‹µë\½âN»¥¥Ø$œ÷c ˆdû½ëìáh
í5ÖNÊ³Äı1µ“˜&™[>ÅDl²ÀÂØ‚.–Î%qße²Ü?3N@¥TDiqÍšHş'^­y­Ş-çvÖÃùĞh’#Ná
¬|F{–É!—´Ùí˜_ÊÏS/¾j“'T®?Êy”Ê<³¾œçº0³8÷¡Š]ŞÊ'a£Ü¢6ô=éŠúĞ\¦+«š{¨ü0ŞMˆ]o×üv¦ë('¤VŞä¬4.BİÒPÑÈ°u!éx]éœŞ¸Ë–jkDÜH
;-û?aqG‹ËÅ‡’…ş!V7Ãu¼æÌÅVƒBàl˜ØÓpË•¸©cÊæk·’L«#	»'Y›ÁŠ´ÏõVÛ0%ñøé?µFHï¬e§/ıšƒT(Í<4éÿ·%¡=‚¢Æ‘cò–Árª ³]€¾'È&†¯Â”+s¼ƒÔhù#îä‚Gr9â—Ş9q©}›‘'¯Öÿ¿‚g§èFÛ•½ê©Xc\‘r€$úÖ~ 6uŞŒŞ¶æKğ‰2dtl¬ó“su£ ZÆd€ñI7l!Ï€&Ê0Íê72çcœ°Eqµiàµ—@ì"˜¥Û{î«Ï5Œ(óP¥;ÂS´ÚÂœcŞıÊrÓ˜‹·$ıR5ø^ç&L¶ŒÔ)!àcƒä»×ŠIÓõƒúÜÀdz|”D^]Îğ\õ» ì—xh–ÓSıV°PQv¨ÍÎyÓ¨9ØÉ#®!è%ıuëø$ÅX~ëXNı¹d^±0	R6öëª˜c”[Mqš"YIcïş´@Çÿ·kuwÖğÓùôBì+º^¼‚8ÄÿuóäIúşiÀ³G£p·a¨eÓŠøX\D wKw%,©úw$ymvğ’m']¡ôQyÃ÷gU÷\¸m·Ú“@Á®ÂcSæ†KcXœ¨ëÊ±Ùƒ
*0mk8¤‚Ü#††IüµË(wB¨Ì¢°ÔÅ	]¹!‡‘–"T¶¤::“Ê?wrF°)êö—lPü$u MeDl]bÎlßä Çša\ÃØŒÒşÅiEĞòí‡-ºÏiHªĞ9Ai¬«éâ²ê\Ï—ÎüLÎ`ñ	 ¶â|/€Ú¬óõ×SàÀÆePÓÿB!Ëíf5²Î²hıÊŸÒÁUÑ^ºR‚½¥©P¾ÌŠjeÚ]8 <­µßé¢O¼á¹tŸ*¶Ivıª²MñìC&ñ·Xe?ANO´tÜÉÙ"ñv!x]d˜}Ó³»Û?Ü‡\§PÈ¯$©•ÕäOªƒ¶'X”®"4ëõ‡gªv-½µ³Çï/Xãµu4ĞrÚ££´œêŸVAW\Ä¶£Q¹™Rn^ªå*~?ÙÂ˜Öü5iùXXL*ıßÜ˜µ{~tö³´‹ïÊ´9G½.2B}ñÃ;Ó¬I­"?§·,´—‹3p5jËjZûZ?!ÜÚî)|Ç‡xMbã³ƒŞÜ[ÙŒF8Cøı+AQb_²×çs	…µ”j†‡­ßšH¢“bşá,‹V™ÚA.ú)œ ü:´J™u‰úæwJ«¦)¦«nŠ¯À¶x‡ÑddÄ(:šRüÚ°èéÕ€âÜ–ç-³É¥Œ¼Ğ Ó0–ëh6w(Xİ<¦æö,i×A­9ó £/ö¶9º‚Ø“$¿9÷mÆğğ
–¾S³,òv+,àŒÃ‹~ÓpkF–½ğ®~|{ü¬óÓÂJxJí”¯Ù;'YöÛ¨çâ­¼Åö¸JYëE=X.“$|x>}™G$²Ï®õxÖ)Áÿû9ëÅ
\Àm…‚š'9ãZp5µ–“j—¥x›t•øäX   ºq|{ÃH÷ Û¸€ÀìE—±Ägû    YZ