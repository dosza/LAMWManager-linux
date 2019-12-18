#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="328369752"
MD5="6d75bb8b9301423e076050092454ecfc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20312"
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
	echo Date of packaging: Tue Dec 17 21:24:19 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿO] ¼}•ÀJFœÄÿ.»á_jg]77FÜœ·Û`ÈtBUİêx
ßŒ.¡8Àq!·°ìpÚi°=‚ÂÅ7¤Ïò‚­¸YWPsƒ>'ˆ…ùÏ÷V‚oæR :“‚s9brÓTØ µ‰—dz[Ø†Èp¤èü‡Û|1²@%ë‘/TYãMgHnïÅV©`õÇÏ–„Œ‡‘Tş÷I½G7Y¦;Ï æ*û}øCˆ¡¯lBmYmVÜ\nŒA ;‘`Çı	*ˆ}Mõ4ü™{+]Å ñòà¼VJ"Â ÙŞwñ%tÀ°â*XJ+u½y©-"¶¿«¡şèfçã2,“»¹/ã´—œ\%¾†”Éq—.øyg|¿öcxÑ|WÃz7÷›U4ÁzşN»Û¬—Š#×ıÏÂêøØ¹oã3^@oå)u„¢;Ç^­ši±ËïaòªoU&·jGÏeùÿqN!P<ŠhX¹›ó€%S—õQ^ñm_q/Ûq˜D8øgnÄßÁ›ç©06J7ÇXÆ§–¦ÌMÀl,¿@CûJ~*ÜnÓÑñ3‡Ğš:<”ójÜA5ÌCä¯¸Ö©%Í’‹ÚJÍìÑ{¢=ÛË>‰ÊÙ®ü€¶í,Zî³éâf›w2<ÄÉ¨‡Ö¾Òü®Àñ]‰8ÏI[	…sÀÒ[4Å9Ú+È}ìÖyèñÔQ§«c9/à³²h-Q€àP4?¼cK~²ÿ~V-èÜµ;Ê«&—›øöğÔ¬¥7±ªí-ñV·k¨x6~?q‹„7!n_d…«ğÈHÂ"àh¹$¯‘|i³Îğìé€3_ˆ¨#ä}Ñr¢³°ˆC!İ†Ï¯ÛôdzĞc,6Û™
-a9âÂ”Ó[ä8÷š<¾gõLfç
v^%ˆÚ’WAeu©yo!œüØA²b˜³òp;òV(à¤!=PâŸ·….›;kN`_-ùw:Ç Ş/=¾>L±H£İ0‰—ü)á©¿¬CM×<›U^ÍŒ]¶HCãùØ…kÛ± ÊTªdŒ9!ÉUŞ³ZÆéƒÍ¨´4¯ŒGdœ;+ŠŠÌg”™\ûºJ­_§¸í¶ÃÙtí¨;»ÿ7EÑ$¢x ƒJÖ{Ş®Ö½”òŒ¹mÕCzgx› k‘¢©ï/ÍŸè1£ÉW÷[3t’´•q\˜töAîÿü3ÙØîËn”íªX‘éN˜PU.TÍ»ÖÎõß¬¬N¾à$‰ê=p—²«/æ·•	İÙõşssQ×ºìI!»éDÛ
÷¤;ºó‚ZÊ›cå3wƒQåÆBõY»UmãÏ)ß/b5fyïZ€ñPïpTì&16«Qô–İdU­ª¯!¥&ôùı9rBËúº¾cÓÕ,»:—¾7'®äßÁJ{±g§ó vB±‰½	ÉR§e­!Eúˆß°í‘AP+#GMı½@E\89›Ã5^-·—âA…{Aï$»Å¿–ù–*Å@ÄP•Š$¢=‰NZ¶AEfNZ¨ø§Ë‹ÒÍÉµùq?ÙnmDI5-Q$•dğëNœuÈ‚;4´Û{±Ô8(=•Õ§Ë†çßìòõ„:õUâÒ‰ÚˆT-wÛã©¶ôÉ¨áJOÊ¶òXût«¨V,õñ;i‡r]$~dø\Ãdú`§|a3æ£@XlÖÃwM…q&*Êÿh²!jåÑÌÚ÷é)ÇQ@î±5å˜B›.Ê?ÉRô¥mó(2jñ}Ï®óÙ?iÁHJÆ~æ?Ü.K £ü»FÏÕ>üüê¨°\¹¬ş%m,øfÕˆz !eb§’æhU±¾ÜÀ×œ¯%ºÖ£8¡˜Èäıë–J4(K„^dà/ô†Øö¢ıÖCqS#’ğ|§’0™Áƒ‡åÇéÙ¨b‡Õİ¯‰;ÄH 8K$CÁß¢G…õ±PÍsBŠ,ôÅ²½™¼—»Æ†±¾Ÿ®ø¶jQÌ¬ùï(Bú!ó!©2[Wƒ£@~ñHËÄ1š©Z bÂÀYÏ˜%¬6ÿÄíº©ê©ù5¸†Ló÷d“*XSG&wEî±Ğ ¯—Ã‹ß!äßº`qQ\N(Ã&T¥]³Şu¾´t"¦Ujİø´Ša•ş\eòE˜—ûaÃçì•c°-tßó©:iøNµ÷°B3Ÿz)hé4ç$1·jhœ5Ğåe¨`pf„“®iSMV¤¼¾[òÈ?`2‘ëJ|öF «­¿âr²246ä=CÖ…îÍó¦¨w;éá`X`@‡/oGâ9y¬pVõ£jÉ¨ï…ğ6pS.ê¶û¤¸ëÀçjŠwMkèh&&èİ 5„qyBWq‚4ÿKÃ32øÍ¬İ‘«ã9bp$È¹ˆkÖ‚´;G4O _’#Ñó¯f0ğ¼7íÿ×këåk¬Ğ0N\/†ï½æG_#L÷;¡iƒ+Lbdå3êÛ°iløYŠØøiÑTüøFÈ#}K†X[‚‰éŞ˜—â(ùtølƒÌa­".İ<P®ò$Ö„¦ÕØ·‘HóWmá%@fî 4§ÃhAÏp×Qß—ˆù­¨\÷^¹®ªiı£”@Õì³àWµ#­sni|ZÛ«Ú.³—+ºËoğF“–¤»g-­ +G©íGï1ÃH”Š…Âá™šoDƒÏ…«9¦'À Åï*#ÆTÊ+Maó¥@ X50¤?0+j»@Gšã=ıFHyS’wÖ!d#ĞuHë96é3±R¼á^µ#‡@RC÷{no‰íø#‹ü¥úA„WTÒtXÁ[,½w¹ ø¿‹MôÁCP]5Æóx’°óûdŒ”‰lÍEÖ«Ñh¹©^
…À„ü«š%T	¹û¾ë8}íêÛ¾œ™/šbc#.0ªa é/oòËM7•_ì[[Ç*êûË#ÍµŒ¢ßQK¶¸De¨uNÈn›ÉE§¼écÕNóç)ÌPZ®w¨úùÛ¹5fÙğ5=_¨‚‰‹š&·º€ËMœˆ¾Ú¸T£±ô[8™‘
İÅ"†Tí½â4Ojˆ·Âµ
—Íß)E^¸„¢–²˜§õ]>ròèò7^¡Á
€âI9äbâû! ”x'¶WRF.˜0ÇWÙ¯2İ¥YÖÚr&Æ*‹­¼zØyæ÷hİVøñ=UAäH"ı`9æBm¡±èú£Àé½•'Xæ§°Û‘aëêM#åøè)Ó Å™mh-æšùátSöôö³XÆéş\ì;Ã2½Ê¹3Tºğª:^(¼ÊM ó—¼•ñ÷ê`.ó²
¤;úûW’GTğ+Ëi¹y¢uzÔìs«VHé[=Œ¼$OkŸ ŒÜ[ò±ó¥ÎëQ+(ÜfÊ°¹êeKİ™"2 3—— ÂÁnU=µ—àİ(Í3 •-‰ïŒ*1›‚.±pÛ˜jÿ¡³+îcÙÜòôG¦9ydŒ³İg:WÒùÓõ&Ll~H9ôôxlì—n,H6åõ	Í9®ˆúĞï.Wç6}³µ²RU0#ø=è«Õ6GT] Q²:k}%Œ@5?vëõ[è¸w”ïëôª6=yåĞÉÉärôsrF—DX/ëäëo+#÷»›éibm•³bÿ¡A‡,7#¿bÚ®;xHb)ˆa«X2ÆƒõSˆÔ>ZËŞ¼œx bò¹C	/Í¯2M¤œ6
±§¶Ï¹Ü—oR¢ç¬>å”_T8ŞÓqN¿@È/Å)GõÕWeÓABÚõ'âÜ˜y/ï.§mÃkI>O1|=éôG²œ³eĞÇ²-Ã"š*l±Z¸¹øôc›ìµTƒ…[$g!âİ—T
Q[Øô½ØVĞÛ‹Ì§¸W¹”ÆäÌê½Nsz§£zv(ÂàÆ§ÃÚFD3õ­(ó~Dæ¢Øí>Ö½>6Ñ~èèŸMŒ9Û‡:=gÍÎËV¸ÕíŸ×øƒ¡ÊPÒNõx°uÌù¢"Mº—_v2«qÒLüõ†]Î ÖäAv&wb¬Öé«^"³İZäÌIBâÉ¨/,Š«t•¢ÇTÑxê¤MÄ~ÇÃğóR
å·tÂ=lÚšÂuÓ?‘ÛœˆE!Ú¯Ë_¡Ü‘Ff-È¤,¤&¯ú©éjs[§ >¯Â˜Fn6Ø\Îíî»iV˜s€‘z<pç¥[¬ZibcK¦¤ÅèJs=^ÜTÎÆJ4n4ƒt³UİÕƒ	$¢Î!IgaölEqñı´‰¦8~ŞjÏ	‚¤³Âãi’.’ôª$G]Y•›CÊybÇ‡>*»ç‡Áª!*wåÙ
î§L%Ùbxqc9’CéPá%‹¾PÈs/z½¶Æ#Yß]«‰à—ßé3Â€’Y¤W*›9•^#%{¾§.­Ùo¸*Ì 3_QOÛ;®È'—ªãìa'²6wâæí÷ƒ°ı,‘Õçƒ€0Ë?\×Í£ˆÑš–ZİTï/eR¾Ì÷G:ºr3¢@j,‘ÛßiæÇSße¸Ù;5Ì6­iönFİpj4OµŠîÌ)êa¬A‹€î¸Øƒá¸ÓùÑ·Õ²§¨ÇæÅÇ®ÑĞ‘Ñ“¶±.‰|}ûê½å[‘ÌS¯«qéŞ¶°‚@ZGUÁG[‹ş€@uÙ€ï©¢Í	‹v²Æù„0ğêÙˆ”¢>Ü©4(GQ$ğÑ[ÌzÑ×Óú(‘¯rµ1ÖĞrn>tW¤uhs” ôKığÅöÏÇ*†#¸–¤Ô¦Y0ùqïã¿Ô?H3o¦ÃØ`ôuçıÎVÊ–¼úd¾“È¬©LeçjZŸíæ·€™‚Ê}ŸuÑ>ˆıW‘•‡²¦ ¼ô 8¬uPdHgIÔxZµjRA×¹NÄzÄ§ìË$¼:®^<¶º¡‡}<ç'iÈæ»ëºKğsI¿2İ¹Ë=z£‹ÙOûæÓ#7
2gÍˆ×KıF„BlÜÈ›ÿjöêjƒ‡5ÚÆ ô àG×0¼µ¸uW›{¬µ­\u o?x_¤†˜ƒxåóÙ’›JÅEÂ„-Ù§æmÁA°ÄøW….ĞˆhmíóG!¬k²±jÈ£ÁÊ_´+÷™X]»µwéº(2ı‚E×-4LS§ÉôúiJÅº5jàĞ%ı˜¬“°¥ÑÌ‹ëCìñ¢wØÙ@–;·Ê•ÿ®âßŞĞå·Ó–^UğrÑ©Ã@¥¢STµn¿é/0V£ÏÑxÍ]Bí]À•ÆPN–<­?W…Ôœ}Ê¸Ä*X£Õ¼@,œ ½Ô9^"EU]Ÿ:‚·şvÖ€n4ïã|‡w¾–Y£'ÒA@KÛüäæ»§×ş¾­vP«àá9Y&õ36{çrì–uYS·©9gÍæ×;¯A¨ÍØ"‹LAÒ…“Í¸OÃ9§¨óíVO×Ã¸¥ s4Sêª¡ÜKçµ|XÈ#W`;ß$2WşéÆ¥ „/–ªœß¦˜Ë)Yë²ó…4yµìÁŸ,dƒŒÃ
rGX‰ B2/r½z»å¡r(àg…¢†%ÆHÍé1ı&mn°:ï¸C»„×Æ+Ó¥TëVağ3á;Ä³B]E˜¨×^¤…‰];×jï¯ë-.;Då»ã¹pùÆûƒ_g>w%Nxq°SÇòØ¦„¢Îû®¦‡yÌ“ĞAc³§¤à Éyñq9sÛj%ÌÛ*8,7PÀ¿`á±Û‚˜fTB—Ş†ú²JïÊÊ†éOÃ™¤ï±+©²ƒ´ùÇ?‰èîÀI·L¡6–w^&Ğõo
ñí Ğ”Ä[É¾-^İD¯§jùJN‰°pDŞˆÎ±×àİs†gwV- ¥(‡hÖ=W‰ÀÔœŒ~T“AVIºé6-ÿ»Ü’`¥†Ÿ‹Íÿ˜|²†HEÙbß1é)4IGÈÌšÛ±:µB3(b:u<}™¯8z]Ó‰ÈÃ@/p³4ÊM„Ÿæ
i‹}	€æÀù?ÉµÔ;-^nÒÙÊŸ`Ñ½äï)Í3¦±“U¹Dì.¤üÌUY§^MvâjİÆúaVRú³ÿˆŠ0xéƒ¥ÉuÓD‹
ã3p­\ríÙ”Ïq†¯%æ) ,å×Ê¯Ï¤6dş >aÒªOß«“½áÂê6räÙ$ İšó¥·şAéíg
%ñ¸ú“‰êÒU.Å6¬2)ªİö÷Iªˆ?^¹^|„¯Hu*‘ïù'šå‘Cl~ÅÃ¶î}ù1è­'Yz¸¥§„AlöÂq¡ÀĞR+wQŠ—?¢,‘Æ|wä-Eÿ[%–Cµª¿¸/ÍB°ÓCó®ã@B}â; w§äää_ĞN„Ü}e{v…><§ƒJh§dœ‘@®şŠ¨}´š¸RvOÑÓºHy¥Y3egûÉ˜(Ø	Õ¸ãòÛÖK+ËÊ;ãÌhµ!vO‰ÕuV¸ÛTÏ
‡UÑp‡:Koñ?’£ëE‘Yß8ÍiÍŞ>q_‰3ùŞ¨ül6Û'cf÷:³’
©£×i"ßÔi4©î›	0m4À¤Pr>´p§ú’›¿¤NâDÔ¾Ú=ï£»4sàğŞ£"óqb±Gˆ42™B˜‡¥›¡¹§£yaárGñî˜—»ã±Í„–O¤ŒgSòVh#X«-fz¡ÏÔ“HLÿXo/ä.f¸ÂuKûë¼o)gÔdÀŒ)ÏãsªÉzÙÓ;+ó;-‘yÌ›ÀÏÊ‚Á„ ñ(à8–jkÚ‘œË•µ"}}´¤7.Eº,o}±så^Ûså‡®t9B¶Àµ ‡²A<vTWdzy‹f`gÃ°3 DæÉnÕíòæeZ]Ù§	?…Gm
ôëYîMZä>æv	£.{´d#Ic¢'n’ º\blù•… “PWÎÆîy¯Ä¯˜ÿÎÿ(—Áö/ÚSØ‰"Òç³5¨Şòò
À‹ÒëâúŸGE‡ÌÁRw	Şó%¸Qä45-nZrbƒˆÑKRş¿Êf£!&U ªğ8~¼¤¥şsÍÀWìp»¿C(älQZÄUı_Ôºƒ<TŸ[RhÜ“t‚šäßhì‡cÖG#‡¤‘ùgœh^rŠSµÌàÆGªÍÏ}ğÀ[¹].U˜A73Ï™·w‘Cü”BˆÅN—Yé}é.á%‹—Nz@Ò»Í
G!‹ |N)•‘*èí0/g£éê¼_†Ä£ïİ)	O›bmìÊ-ÎVÉ’Ê¡½wjxX³V‘ñ(£‡úÜ6ŒØé›‘$¬¦â•÷Û9a.8Šlÿ4UÎ›ömM{'«•Ü˜–·Oğ¶ÃÔY
Íít¦¬‡ ÷[£>GVJ’S­_›
û<H’ÎÍtœ	?øÑŒuxÌÅvPÜ—[¥05¼ìÃ¨}xNŞø/ü¢n0N6’g+Ôÿ
¿EÆÇ2ˆ6+ZŒ¢=ë&~c³¬¹sK%_ÚG”ƒë¦ÏK¤Iwûà¾ Û²º—ä!ú/éùNbF6òMşÌ3KJb~œÙ8"ZHÅüvşÏÛ‚¸f´ı†FÈ7òj¤^s¬UÈ±Háiùé¾!£¨¶-Î¼< gku/­¦gûƒÚ=92{£¤â!8|)“Ó³®“Šxxø˜G[ÚQŒêV<™èóöqãØ.Ñi_Q1ö{ŸÖ
ÌÔaDxQ=Üõ]µ›·LÉ8ĞšTµ5NÄx¿Òt“ç]#Ï°| äÍ7³Úñïvï6tÌaÜP+–ÀÇ`ôÍlÂ‚Qı‘^>Ü>šÜ†­Œ×¿™ZDâ—=ÿUÕƒlj‹FM·›©‹Ÿîú™u¨sÎÏèAñé XŸ‹•€‰‘&6¡–z4O
7Õdn
’4”€tëDµø7 '8íz§À*êf?álş Vn0Ÿö§9Îé#G­¬=íy_’ÈäíTy;1)™œó“?´jwòÆâhJ\XS=Pı[r”uMdò¨k™é–nÖbŞÇ}ëŸ\û(FÇÒø² ˆÓg€çM}è‘º[”•·à^×¯{xËK…!Wršü‚ë'UÒ9ÖLKØµB)8Š/ÍuÂàšdlMWïÓÇ¹×îâÊ–{8¹ÆSÛdÛ-§³xşğ;ëHÌ[$ÓoıuÏğu	€˜°Ë4%e‚Ó¹ïre”F¬Æ¦·8áÖ Aô
j}“Ÿmä7ác÷g ª¿Ü0f=¯Ö~ÇÈË1B§ÒXØä¤Û-¨+t¶€şúM´¥uÎ¼ËĞŠÔ ğ•ıL?kòöºí:„ÑËbV•D=µŠŞV³¯Åvõ(ÕæT¬Ëé¦ìYUo×+¶; ZˆËƒ:¹ÆÀA+\NÎĞÁ*sâD¼ÀKçğÍƒ‰£Å‰¡)=É%Vxƒ™Z{cğŞlé7íUËÓÿÛtI£¬g“^·<+¯Ôæ•ÛãpŞ¬æe.¤ïĞ–ddîc&nÆNƒû¡‰¼ı.*¼k“Y..Zƒ	åØU•â Íwˆ\Œjñ[]äh©ÑõÏš±öTH2±§úˆ¹¾Ç•ØÖ3üfÓ,‰N†fS]m§TüOöÀ6øøåBãÛvy9O·^œ÷'÷Ğdro VloZ¶šıº9nÍdâò8ú˜4$äÃğ B´%¢ş PX=ƒA…‘0;Ğ†<$ÖˆQßªHÚÚ¼yn3‰¸sÑ4Û7-pÁêÉüÉb&Vf ¿aÚ›Äøé°bãÛEÍ‘xlJˆ¿ûakû‡46`OR±ì¼—µÆâìZ© ä?XW[£â…ÆÇA3Gå*owB¯Š²¾8îîöüqVø÷g£1ŠÔBÏÔ‹Ê%‘$ÁK>_7–¾ ‡Kxÿ÷Ø„pî«&š
L#d"“]N>>ó§A¾ëÉj“¦3ËæUF·e¸µÖ*s“şôÏ­Ãßüâğ†h­µ^•ªœ\Ğßd¡ğÄw‘±moß8•¦Úœ’V&{j!?=ü)œÃnÒmÎI/³Vº÷~e _rƒ*7Ë=îğ¿æÑ0…3éÅés_ĞÆHÑWw©°–Ì¸ıiğZŞ	Ñéj)^”–àv¨J*+<4ÉOW	ÑpËdİ¨(%21í¦g…Ÿ¢_~‚—2ò‰`ç£àÉ›G%5l
Áe÷qo ¶¢Sf>[®£ôû®«†X³—/™GGV?é¬6W2ß¶¦œ(X·¾ãŸ×vOÎ„5=ü«oÚ_$”û¸¨şñ¹äé*}_\I¹ãV£¨ƒmó‹L(Vå‰´b/‹¬Îöä½|k†ˆãü69]fÎ¡cø&ğJ­øÃ—Û_ÀQêFS ‡¤ûE?¢VŠ.zk4(Yròo—YêèBIÖp;è! e#/+%1’4ÿ€˜ÛÿAsï#“&ı©'Ù÷[ò4ËŒ©gØ<N±•(a2Pƒ%wµ~¿´‚9»®´&*§ç78şñÏ[ıµÉ®7ŒD?ô^cmË‘ xqlP;ğg1CÜ£¬ù•”DárµS?¹zW”t9C®DŞÈC|^$×‘ÙY„±nÌş“°”éÑ·ëú“h³×k„A%h¿dP’ŞÉÒ?"¤‹z'äùºÏò!şm—¦¡=7¨ø½šşÎ|ŠA‚aqUòÉıŞˆ™N±tş>#6(ÏweR|¨BH}bàªOÓ¤Æ­­ˆ±’ìâ©şÁYr©ğæ'p©s­nŞÙPƒè³îe¹f®iØŠòIo»R~.ôHó­äÙ¼<„`ÅCCÓRñÿ«r¸V¿Ó™yGyìÜĞsÿ€¿CjJ;‘f÷J‰a$ÂbÆ;nÔ0lf®aËÓ³îÄËk|óÿ…DQ¬ofÔÙêC+ ğrÑ–.HŒ6ò2õã-_Å¿GfZ¸Zî=Ó¦áº>Œ[^ÛÙÉÑ[,‡Ù\€aJêê`öæ8W|Æ¾¼û´=nùÍËs}eY'Âvxoô‰-•HŸP}õ#$şkvìlQ¹ÚÇmFûÕ¶ZÍ:JX’[TĞĞîd·ÂÙšfoÒDê9^Ğ56Y¤ìäQ¥…‡«	ã',u†	ÅM¢p•g£É
Û9Êzªjh’Õ`õÔÄ˜_6ÎT³ÅßYB¹zL/x{ÏgJË\HJØrM"&B6€æ¾
aÿ©?gh?A·Î¯ÑÙÖJˆÎ3B ¼ÉÖK9ğìÌ³¦i3êC-ÏÜ
êÅ¤úTú'ƒ¼\°[±9
¬éó®<y/Ò’…b0	n[¬Áú}"
«ªå}ˆİ‘ 8\&~	Ô`6ˆWÂ¤¤¥PCeëÇºªG³ßç¹^œ'+ıH8i4şñc¥GôW7/FUAivXÄ	}#é*MµªÇ‡Q“c+s@¡b1Ğ±,©²‚m(××¬Ê*-µæö¨i*O“|¸ºN)úJíxØ¼põ&°%Â™õ}azÌ@F:Ç¬rSÁ‰ìzâ‚5X1ÒÚ#¥Åÿ2Ò-Ôê÷l˜>òt»ƒ1»É¸Œ´Ão7~ÛÀ ÙûV•°rWçhœhnUßüZ¸ñE¿ö>å{I9ÿÁ»Œ³òÏr%Yƒjİ[î¦Sa\µö\0½ßCõÛèùÄpMH"T1.#ò…Ïş¸ÃÍ~vg×İÜù’mU¬–0ĞìÏİ‘}Gu|Öu	*XÌÅÒ°uv›«ì`ACeÀ©öO~”±÷ôÃèŸ9(W¶p’B‚Àqá;"£¶zÂMéHè~ëÇjçşğ] zŞÏÕİS«MZ.­61ìa`=™¿—'†TÁ¥ŸuÿX:…ŒFÓ½tå(Š4&‰@+ùÙ<¢Ö¿şÁ$‹L¸Bº'[Š|=Œ»‚ÃÃû$Äë…¸Gû~6lN©_e'V†„D(:§p^Ã|õ­à%ÆªèAs(˜+È¶OH#b>c5=9ñlÿÿ±¤8¾É;İäÒsÜÔAaâĞ+Eö:Ä¤~Ñ}Ñÿ>¯œ@;T”Ê¥¸"”©4­0¸†A‡£^±<ÅA‡üû$os< ÏéØVn5N±>~¾à¼ÈÑã{îgiØ<­6&õÏ”o µ=héb­ãÊïqœµ
,÷S¶n†a#Ì'±Ê<qnÀƒIà3ëÍ‚ÜB”k¡_ÀğhÁjSğİŸJë§Ù.{Œ!8a5rCó{†¯NVkÑ0\ÛKıô‰áQÿR†FH]š<ÿÑ¡'„
Ñ:;Óéšıí9ıİw~Éı“ç 0ÀíÙôÖU.óhZXzåòD<{IããÖÅçä•xÔaµdÏ‘uÿ©‹Òñ:È¢âKô;òÕùùµEjÃ(…«aÓëuç}ÓI«’­
Qºsá¢g—8#ÈoVhH}pû~¾€,&)l¤Å+À<¡5y±	.÷È0»
ƒtÛĞô*ü~i¦umràX$IY\ ã¡û¥*d¾&(ğKQ³F_Ï±«.-xˆ>‘í{êIìN]³¸*ä¶¯]Ä†h&êbs:ò['ªºøY©4å%L‘ºÈk¶?à7,!å÷Ö„•UMÒS(ÁÂüR@.Ñ¥+[Ô·Àkø\Î<† «ú`ÊZŒù«p¶öÖ$.èêı£fùš RåF~zuh¬=íÛÀ§hMï­KûºÖ¢Ä:À¸óø¢}Â7ÿÈ#äR¢ÇûÉtHÅÿWöÏ%ª¿
7«ÀÖØ1ËQï§’$S|ø^ÑæºxlcûA/û€$ZPß~>ˆZ½ú‰0ü­ÂŠXB,Â§òÅ¹vÇ÷ıâğ©~—ó_õòVXX^E£Át•ç‡*¯eru¡¨`dpôÚdõq?n<“ptö¿ø˜Jv.V—"™ â¾7jVN NEˆ•ÏD7ìpÎğó ³Àr£8 •¿‚]}ïÕğ³àå¨(³XÁÖÊ½ï’ôW§¸ö'$ 3Ì¹ã¨É¥¥¨ĞHÆ’§*Ø†ù¬øXŠèG¥­(dãÍLnÚ+–âo|\(JAd¡×õtŞ&	:³A˜áZÈÌx®|ÎÒkÅ>œ´ÅÀbRÅƒ^›5|’FéßÓµŸp„N(:=WÀ(°Q‚ĞY“Ùƒ»éË²NwŞ&UBŸËkàå²s4ÇÇx¨½I_öÈ	<é»á G]û7VŠ=™ú .Ì¹hâ0ˆ˜\ü¥»»--¢/íö . ÄM=ÈÄ£ÙOD@umµ½%wãS7j%üRÇtaÜàleo§Gï1Ô“4¥¨Gúã„ÏâyN¨¸ìğùlÅgª•*VÒ0mç®)mÊó+“÷ŞÃ¦uÒ^=C—Şå‹Zëİ‡ø t¸rM5^q¿õá€(Ş©Í³ÀÂ¡¶wæ:'Å[2r¤8j,S—ÕÒ=23Ğc“+uæãÍÉã¸hÀgµ8•(å2ptR41'ly"ÒÉâªçt4¯„ôÚù8—é™U¬…i#/à¼ÿ`1®õ;Aşğ:8ã¶	Z
ÌŞç\’J'ƒ¥ó Ï±+%aG;›e`U1X}ü‰SytÚÊM™2^kXD¤óBcò	Ğ°/İ»Ñ”ƒ¥zCJw‹>sT&~ªºĞ…Êà1n:º|¯bi“×. ÏæwºæÚ¼·P?ÎµT…6eÇF“róÉòã½È“¯£KÆ-!ü}%ÉFì¼$‚Ãìï³ÍD¢^ë}úÂ:F¿|BhçÓ}Zªàaz‹Ó‹×>t2%°&Ï2Pı’(‚V½~Z?¶ƒåmşœáXhT*V¡˜‚©ù3„Òã’Mbş’*{d5|l‡0D³¾ÙğoxÜ„~,»AÀ*úZbã×|.ÎDáùXºùBØ4èØ"­eáHş¦²ÌøÌëÊVòş¨µç#“ZMµ^â¦>jË­&5†·hg¼uLOÎòWáï¼î+Û‰“Î"ÌÂqµjÊu9ãÍ?+ùÒ³rÂÜ¶•t—•ğê}5be›´éX½üt×LÆ×ü¥--SwN‘IOG‘¸#D)Š)mlô–Åbe³İšùE¢¢'6°45ßvıÁW.ëª9õ‡w-†1ó9é‡$¥ó×n—'¼bˆÅtæs­ş>Ş¤şn·Óğ‰œP{×½ã‰¾¸	Œ`{§™ë1ò¸‹ÿqƒe·õğbNy›¡²a‚ÏiM%<DFãIo	LŒsi‘jƒß…Şohâˆ­C6qzê–f®C²3f~q|&Ùwæ:Ò§Š’n96y‰R¦[¾F„› Óçr÷Fe6èãèLá¶­ï;.TÆß`×H!V7îÖR!õi7~à%k–—ÎÈuŸİl0Ì¤8îAwšÖ&³äD4u´0™í–w×¤D¿_M~ó+k^mşY›Ç¨ï£ùz²ò=¾bpjQIOs íÛ_•mYÀH¶5bêı5œsË(Iq1C†5ìr¸[èAK7½ãªç¶µg‰÷¤ïkËÕ`ìİB»M5@îuÍªš|ïá’9i!0Â©›°ËØcÙ¸B*~íM6ªªø‘5­²OæLL~ÒEZ¾èŸÖÿ,kcÅ ?ÄñÍ|/€ße­Ó¸ƒNïYN¤‰€Â~c&¶–÷ Â¢Ö€f±Ò»Ë#ê£ïùIQ5ŒpÄ-ôƒş¤ÇÂ?í˜e œÿI‡D¤
Î•¥wé‰ÛÓGI
‘‚˜‡¸Ì¾úÒw‰‡o1 j€Õ@7 êMu“iT(Š¡cA~‡©qFıÕDRˆK.ˆ=ïYpãÏó½rRé2,êtµ“àîZ9Ã:ÔšÖ'®½r»ğÂ±óä4òâdPĞ~ Ä±Jz«ÍÅ
UÜ	$o nñŒgU¾EÏ wĞ²	—ªŸ]]”•<júL¹½[vÔIn(eèª”Ä2Ùşßc¹˜.äBÎ]:•G±@>¯·vìì`Õ8:ûÊvL|…íÌ&´—'ºfÉé¿}Ø{: &kå
 ü`ÔÕâN0oP´»í°âq”©°ÛƒlÊ¤|hÑŸ½æ8™‰“È8ûÉŠ_î™˜®şñpã¹ç
ò:;´Ç>I”$¸iÍœ–-ğ3óæìN†ÅîÛNîÆĞŒ¢f_¼êFuzµ¤}×:Äua(0<2Mgh1T¶Lû¨)î¹§±Æ]¶%®´Û„x.qíŸ|ªÎı.‹ã´$F9Á°EÒÆ•±O<J™,©Iñ›»¬vÂŞø İÚsÚM,œ(ĞëÀ2±>D3vJÊñ•­âb,®Tè
)¤^÷å	<Í^ rÊ8ÅXq|ÑvÉyëÄÆÀmÄ9º¨D7ú–6ü+”F=-à6=Á¯6˜*ÎGä`bååÔ,ğ”6‰à5ê²Ù®”ÕòóË°ğdëóY,EgîÎÉN;„ƒÄ,Ç>¤ACQh†Ÿ(ñË¬lµÅØÚ¬3×Éÿ 3Í>ñÕ{ÉÎÛLÚğUKkN©ßãL=AŒË'ÎQ,,5·ßò†$¬—²Ù8>GŠĞc4µ¤ø8`Öóc±2%¥ÉTFÁĞ¹	[ä¡ù78?Ÿyz)<¼ä‰lü§˜·UÄ§IÒÇ¼¿Û ¬şjŠ:xíR„CÇÚ|#X8ƒEtøG²n¡¯•ÒLîRıÍ¯ä#WL•:ĞÕÑëı}$‰“IÎ?ù¤ Ğ´¡=ìnº(4ğØ«8¦õÒ7zNƒ=j„¶¯<e^#jJ„j’C >QÓcŠûùmÖ
» úó<õÜ59WÄÏxd&…úæ«XïÑÔœ€@ÜP”b×À•µ÷Lå0¾¶¢ÉèºüíM×·¾­¢¥éïVO9ä¡pK(Aû)öM²
Ä”V&±ÑJÜõ;±lz@Ñm±–Mİè{Ÿât—›¸Dg«ÊxêªÎèûtGÉF¯rØl¦í´61PÓüÓÅÎa^&`¤D{@^.‰¨V1¾ZÑ|‘5‰nÓ[hÑÛ1dRX<”Š‡@³È	*½5®“ìüi2Ç¸£–Zmx¢ø~ABJºH]UiÌ³šl}¤"’-QGIª.ß”’¿”;ªÿG‚˜±8šh²Eºo¢qUÉ% Ñ×å”˜õ*±l®Æ|»8Ætxa½>ÌOQ x}åféÓÄ¥d°¢B\#u±^Šßß‘à¥¶W&ğMdˆˆL:²  ı‹UÆ[¨©,ºŠHRVÌıY.Q™A}Ü¡yïl>€´&¶œZ5e Ú{¥Gú¢¥ÎÏ…–ĞrySğa°ç|¡¢juÔÕT¿š ¢×ã5÷Ò¿6#®f]à>”°<ÿ7â±[MD©bc–+DÒâ+J$e9ôùik \¶Ù)m½ß|PªèFã@¨Å;s¹}—¯ËÉ –HÎó2$a¨5o£á¤¶~öŠ-İ½M^@§GV2,ğ­	¯…â‡™‡Nˆm®¥sûFÍş˜Ô@H0G ÒıX{§@ IÏÓƒâ^–9Ùœ0´Š²öy±ÙŒ‘À!Ä7 ³³‰©¯IÀÓb?\#ô,ÃcH$ë:È²ÕMSæó^sŸ="­6ˆ„†* Ö´¬Ü ó'³*W•¦-LÿÛpŸ?÷U9¿ùg8?_lxFÒ?Ô›LlåârÖµ­¤Óè‚nÀ¦c
’} ó™ªÕd¹Ï{_b\ bÉÅC4\¡ñàí9œã§„FÖÙ®Ñ§¿¯§h"§Õ(1¹×Ë¬â;ªGW\ĞÿÑø
î½Cw{·³|"v|/è¯«İ,@£_Œ@¤Xf#s#ƒÚC§·Šü^ıÉj‡9A%·Ë-„|ùÒÔêw¯Õ 	èæ•‰Ó§‹Ÿ§¿h(EÔÃîÇC—òZƒäîÃ{œ£%
²øM-aÈƒ@PB¦{6ÁäzNÁR·I0‰u4/x%Gş§ÇSúlM¿÷wĞ™T¯Ô¸%ùÚ—és(ÎĞHæmæ~Ú°û±Ä7Q‘°åtb¦cµBºLÑ#{t¿“«Pe4q<ßR•l»ø|uz›hÅß•¿¬d
/ÿCûÈZş,uØû¦,,ƒ5Ü¯ÊŒ£¾H—H^øˆ!m¦÷Ü%`	ëø/Ûw=!TĞ„
E–óŞyú\ñ°šZ‹™­²Òõ„¡G)×Ò¶píüò~ß1	I3è4[Åİ5[=ôÔ=™TøÆŞ[rí¦Ñç
Ö¶ïºŸíIµ»8Æ—êëÁÃãÌúJ 'şº:t’Ó85µÚEUêÖÇRQS	PğÉ"ñó{(z¹æ>âyS•VÊ¾’^ñL½“‰”{B¶6ÁW”ÅÉfVÖ+¥ÙöÂÏÑ=£ş²neı]–FGµ³İ1ıèÒ×‡JóC×ÓÈ"ì²=v9h2Ô(GKT.i£ĞçÌkÔáªïf‰ĞõÉr³­`3r ûµÍsAiNàÒônjÉlS —+ã¾
HÓ˜¬-Ô,1ÊÔø¬¶©>H!À-ˆaÅüÁ•Øõ‚C`nÆ æ@»á6'p³¼ v®û;åYÁåÛ„‚|QíÎ :İ¨}¨rÚ¤ÔœüÏ%8Ş&ù“˜­ò9Š»=l³MèEnTİú„¥½{io|2ÖD×´ ÉÓ³+"w³¼‘H]â–ªıÃV¶zÅÌñFõçó*àY"F'‚1"­(¸Á|u³twÚXLù%)6Q"xö¶Hô3ãDŒ&h– ?M¹A0xèbQãR"íE¢ øíË„“!«”şürÁ|­ßjë’–‹²$=8iJûX³îIPeè °zƒÁiÕ$NA>Hw5Z‘cnH}ÖŒD«kVŒ1J½²åâèßg‡qzi4ñ
UV¬+Á3S!±³	Ï;)ÇbkÃL‰õ×¸büzñmJiÁ®WûÔòµá†#…òvÔØ™•ÓËpÖ½öMŞE'€‰Ü1¾ëè	£Ó®?4À$íåÊ&+¤WlÌñIóêÎÂ†ßöiI¹iŒ²‰ñ»ò"†÷ƒêeì¤“	 Û"bvÉ»K _GÇËùò%>OÊõ×¶g õ	ÈV ;r-E{·Õ‰Í¼!çñ}¤ ²?A!R+ÛÏ·–cÁ;ST¯a>†8¨=ã2}È#Níºe¼±,®sÒã'o²¸>1©îÜ22””ŸW©İ_ÑêW1Åîo‰iWÇ+nlşğ´úv×ì&|…N1B<.”Û8=7É`µa‹ôcRz¨«dîæ|NŸ`ŠÆ•\v5Åªá³Ñ¶­|M#‡¸u£gÊŞsn4Ÿ.bç¡;zvD½ĞğoÅyØŒPâÑ;½sO•{ü"KztyŸ_îFfúŒ¤`†ô`ãùôvŠy;ÄK C‰ÿEŠÔÿ	×˜“¥¦˜„d@”^^O×p~ÜìºÔÅ°åÙ¹aª[Ş<_‹™!åRjŞ	=zkñS@ƒ¾ÏbIÄÉmk[)Rø9ÍC„Cƒ±s#:'ÑÎBAzŠ“ÿaÕDåô^-ÙZ–ò».Ğ$Ø¤‚·{¢V¼¢ª¶ôd-_Û»”³ÆfBOÔª7‚M;¸ÛÍíØ^yP£§Nâÿ£ªß¾-Z@sâĞÊ®È§ŠfrVÖm]Qº(#§ˆ1ÃôTö‰¤#KKá™Í
{`ôºÜ:ôe}¿6à	s„Ij ‚
ô‡G
¡5-ã÷ñN¿Ï'9ûXÙUîu7´ÿçÇiÜéƒÁ0ÎŸï½âõ=­ÌÁz ñó^P6Füú¶{ˆÍÊWõ‹‰Gƒú}~.,28™/ñ#ÙâÁ£ï¶˜úFã–ÎUÕ§U
ªÈe×w¦P¨TWU1üñªaxYÖŠÿOÈˆ(òDÏòmãGëÒ*ğ¢d[Ağš»¯ğÉì<+·ß·Óî7ğ¡èÚğæ.kè¯œ1ºè‹¹R‘«±ÙIeÔáWÃ<!ş¹¯_`9à¦ûªVòæIwògP˜Dª6ãoû ·¼BI¾X}X‰ĞÚxÙaè™çjb©à22ÓáÄb²‡xç¶[H1,Ø?îBğë’_Í“ÕqÃ ©k³¨ 3€!D d“BT]W¨ì;º]Ş™İ€½bŸ)¸8‰%¬)9ÆL·qi’Cù”ÃÉiÊ8s¤ÂÇ¥p"II:X;^ü¦P>i¹›&mÜz r-½ÚöæDü‚e–Ó gù¼ëÔ™z[®OdP¿)¢‹ÈD•Ë˜«)Ù^Åˆùˆ3)×7ï?œ°yêç›—TŸ5¾xØi.²ĞïÑPÑ¢GèÖçF½“å!T¹ë
8¹çaÊv…ÿJ+dşæÍš‰âozĞq:³²ıÜÉ¡ D%]íÄçò¼©6CE	¸–˜õù¡5BA¾j.“ ™AOÄ¤8HEĞ™'úÇ¥Üd£¯e»:v°=|"ÕwuÎ^ˆ;- Ÿj¹)B?ö‘¬+Âßƒ‡p
<h€™öLyK\h ¸Ş!¾ÕÓĞ‘X¹ºmlˆ^hğ
NeÕuçˆ€CáÄ@ {d|‰<‰ƒÛHv´pUè¯±ÏÌ+V’!}°,"Î`sÓ!§XOØJ™5i\båğd¶U™ÍxcM”Ïl§îî&tµµ˜Í¯^{à'\ÕºCâLßvdT
µíÒ•Gêk,/ü#Dı½ŞÍ½½Ÿı™Ÿ‚;›SìeêR¥´j‹?G…~AFÄ‡ÄÜˆ›²_?Ø&„/ç“³óòQ%Ò:ÛÔ`ÃËÂàêl)²º‰bö)K;¬Â¿Œ	4ôÖ ş”3Æyı·ûwm¸§*ø».,[ëÇ	e%UMñ+*q¯Ó""y;¨åº 6X™Í­ Zt×’œ÷cõŒß2w²o*¯tÆ^T=]s÷íåÑÒìô÷'eá%CüÄ˜.´htÇ	êP”0‰­—2g³L\¼äòQ&ñŠ¨ÉÔ¨C„?>gô6¶ p_EBY²j‡ÍzµïÀå<$RYÁsòc!ÙsàçÑ0Wİéá·pmú'RÚ5ùF’îÍA5şZÖ†l—«8­÷Í4–\¦-€^ğ3MÆƒe w*cß»×6ò†„•Ã’'â[ç÷%)Ÿ´¸§µ7ğ7¸Æ¤M¾t±mœŞ6‘d’¶ŒîBó¿œ(Q*:ˆÿ²'º€}^o‘ú'ãşÌC)µÍÜYzÃ«x+{¦>³ú’ŠÜÑùÃ]¬ëœsi+„šÙ÷€¶P­µ’ˆ´f±êâĞùb²¬ıò…m‰¶Ñ]òÙ™y‚ò“mwQÜÿX>À:£xC-[p‚PÊURTœo¾ûßëºs÷¿mÔi•¡ª=Ê‹ğè9Ì7´—ı$uÅ“0ÔMİ¶^¢Ælı½`´r2¤ß¥i3¥Ïî&Ñ"ÉğUTŸˆqº1´Ù¦öSR’>õ¶Õ;Ğâ†</¬æsqcbAÍ+îáÊRúØÑİ8%[8wçÌª"Cºâ2ëa–ªÖ5å`ïH½¥Då,3à¿³:#DşœNÄïï(
Rí@*½ú3úæEÀâE§ò£ß?«@c€	Ú˜÷®[k#…È¤×Æ˜|­ï›Ê¤5°p¤A![OMõ÷Ş¤bª_8†òµE¸kŞğŒì†6µµ…jÖ££ù•vtŠ¬£cI Òñ÷àoÉ‡…xıi]”Ş
¨ŠıC…tŠŒåy¡aÒC¥ºÔCÑÿ•h¦Ãpjk
N~xñşQ S³EÖÔB LYf–÷`—¯^œ?¦±ë¡Ãøëñ*Œ*„hË÷ª›U°½p“0ìÒVm~qĞÉi0İpF~ïm³â~~¤òÖ²«TşZHY<QylÆb+%®4µULl‰oY;·?˜¾&”¬Û„-Hu!êîX¢Åeü!0oŒ“{Tæ¶üÏ"ÉÁè*şò2œ[£xw#Z6‘ÖdÀœIÏ²ğ©i}†¼Z9RTşÃâGÕÓÄ(+¦¦¼±&*V°´ñßÚ×J¼ºåüsBJ°&´x‘^xs€7€3=–ˆ]0d”,"(bôtdoAÁœ“X;£…ö*ávŒ[À|’ZË¡/áœA%"ª¾+ûÙ™2ˆ¯òû‰ Š(&fÉ˜wº%Ù0÷N>øÜ,{+%kÓì5Bwò¤±Q)ä§:«—Bö!r|²Z¨eÍjÍ®!Å*zçS	dx?«q[É«ÉPİ@€/¿‹y"İ›p’¤~:lpŞ€œ(:²‹‡âX£&‡Bò¢6hNİCä•¨î4vÖ4’1ŞOìñ¹›}}–U­e½g®oº*¢U²|ÖhßÏ¿”½\‚”%+ëüÔåf…A?JÀA)ÌàV1bªıP™Oq®È²¸İÑ›4…›6Ìà¥ãP·ÿ&”VpjÍ€ÏØVX`²º$T­ˆ—iƒ|“Ö[Bßb 7~G)W†Ç¬˜ãaPãá]¿ h?mS³I/zŒØ.×Ÿ8m.§UìÌƒèR$<½lDÎÙ¡©·ÕßAƒs:³–8{¹Š®30ƒ¼±Å,œ£·÷Íú Ì–œ…05˜'¦•Û¥¤ê£ºõ\œı˜¼)æ[I»ojß¦æ•J!H§ïUºï÷l{¯gZ·Ë’ãå‘Ü—Û‚4,$$fáèÛ„#Æ¼„Ôğ`›d:`ßK	­$u£¶eõCä©—g6ø§ª O"ìm©á”B¤ähïæĞ £›Ã}MÍ“pı«şa¬DD^yR¦Ùzw“9-=0y(#µOÊÜ[ù-$C¼Ğ@Ô¡ĞHPš=w3YO›F6]ûbiØîºkÒd†ğsíê
aæ}·&€Ëfòc›íê(Œ—‡¡ùRÈ¿¦ûs¼e^´à¦­ÂõõŞj`ÒÇíÅ—§æˆŸÆ£·{âj9»àà+'ÂüªPy'ÍkUˆ›Z2	‚(äÒÛÃgDäÙßõ:ƒ"ÎßëÎí.²í’‡^W4bÃoûûPz~.2$cğ©j}úÉ™ycÕ9¥ûf-ÇÙ^Ü0cSƒO'ù}Æš2b*~”\3(i.åpÌ†\®~eÌÿ×¨‰”ÂGk
Ø¨#Àq¸+M@YV£¿“›6Üğš™Æ@F<…ÆrŞG<w$œ4~¤:8KT1èÈ‰3!l~»m®¨]tüÛw”gÍæ¶ãi×ˆœg8IcS¢`]Ø8ÛxÆt’F”Ìî<ñ%¦Çk£,­6M¼š›SŞ˜ËådØbëoÆK·…˜e@HÃ!èiÚ*şŞ3¼§ÚEØ¾¡Vñºx”/ÛıdÆ?jÀ‹¨•c×²Ôy‘Ï¤¤Ú+®n}ºms)Óö<ı!.i¬.±îQ¼òTğj÷™½C¿t“Q”,ş»Ïî‰ıqQ÷mèçõ¹®XÆƒÈÓ(í¶ˆÚÂ)ea}c¡‘Ù¦J³ÙIZëUÎ­Ôÿ‹sF&ÄÅÏôîddªPdz	 ·’ºïKƒÅõ–>MÊı«‹ô?oB‹³İ¬AMŠ÷\ğÕé,ú7È/ÆÌVN¢#Æ9”öŞûW
3$°òIÓ‰?";ÃUà	£R)U >[uìaÛ(¥ xjßÒ#İR <ì\¬( jóò±œ÷!-qÉèpÄnÇ8K ‚h	WdE‚pøĞëU6}J"éğ¢(ùZ|ş×ïLÍóÖwŠ³_ä«(!ò”D§Oàc tz.¤™¯TÃTPGÛPlYë9¢ş± DÚÖ¨5ÛıŞ¹Ğl[U+®oâ©fëÓÅrËO©G–AÔ ­£Š+>F¼âK¨Ê1Gúš±7iÀ;Ú:÷#ù)Tİò+)ÿ;Á|ÅÉ|É<Õöß©7É47Âe3õeR7İ6+zÑ¼·6`°ÜF³ˆÉ¡­mÅee•¦ŞkBÊ*ºÔD]^6´DRfàh|¯pÁ	Âëé-]”?Œ%ç²¬•_g‹èLuÒªiæ«ğ¶wÌ	±Ç6~ûÖ¤MWşŞ×ĞQ’-ÿÕDNˆk€TíÑêh!]ŸƒBj<
ÓÑly LÀş€™<c…%°ÖøzÊdg8ûšWŠHlIV“p3ôÁw&üuµ¤›©Ùy”Ô!øÖÅğŸÕÌPÄ¸\ÁÓq¢Uô÷­SÏ¨Ç^øŒoMÎz—ƒMiı¾Lì¸e'Uà¤Öå¸å•›Í¨ª²³z¤µ!˜ÆÄc¿Ô°ƒ6¡ÚµŠée

Ç|æ{î2S/¶öW—Gí%:£¼˜ƒ,[ˆë£\ öinÙ9ç…’ B•<w­‘h¶g
úhC<[Â?W¥—ÑM£±˜{kÜÈäÆ__¤æc‚üË:bo,dÀáó]†H™rÎ±å7r˜PÏ„‰bOÙ¾¦ÄĞ"Ièêªc^|ü„àÚ ±S%÷‘×€Úãù|Ø¿4Äk)c0 ÕğÙíğ{½Üb¯ÆáÓc§úvX×Æ%‘<‡ÀƒŸˆüBƒ®üOa¢úè5i€\]Š#Íƒş“Há@«æÚ­GM ô¤#28>ºSb1ÜNÎÊ9Ùb¥ÁtëÇA-5^QQ——*pù0Ÿ&¤`1Ry´f­ÁÅ«-a2¥Êx·;àáE ^6o†c)ksF#t
¡Ù!:+Yšš) ŒçmŒv+É'N×„h5útğ-H "W½¢›(l.SR'D*y×;ÕƒÒ;şeJÃ1cóQ/TË½Ğ&:‘›NR²ˆ<M¿‚Ïö^ahû‹•(:£ &9Èy!sñ},j]uĞ£78œÖšOy·Vxr¿÷CK…î­ÇÅx\]N“S,U
lÿb²e¿şB]ôµÒRåO3Ò'Ê&XıA]RÑ0ç|qb|¦ÓËÈş7yº’°n@cÁ©…ÓŸnr\r¬Åó,Üs¾|r·ÖsÅÌnqîd¢œ´"¸êäYX¬®>©Prp·nRIA5eÆP!D1Ğªb"°TC¸åÜog?½en2~½É¼<¡`İØºú.Ã‘©Bd’µ”œX•Àªn­µİERáÀçˆ“çÛ“Ao'Øóñ6÷µ°
ô=¸,³˜¯
¨Ÿ\Îq\Æ¯=1\Å#n‡\ïğ/²Ğàl¼ß’‰2(U”Ê$cÀ{´ùlßDâ\¬>,Rò‡ah^í@’Iñ«‡<®»÷­Â‰dhÕ+¾¯î‚òLeµ|rv`
“dXØ¡Şóª»áê4ãı<\ÌëKà—ìDŒaAS$t9)Ê… ½NoÛtQÁ'+µ’¡¯Ò†Æ1ŞåÆ˜‡±Zš¼ì€6È¦õxè®¶Ø •_+Ê³Ç"¼(5~^˜ÅÌ:÷_”i¤’ùöÆEl° ±ö¹AŸŠ‰6ÌåÀ°G\VKå;$’«’ÁB !°=%Ûß	ûbóÖœˆ“ô%³øSç¡öær<ÏF‹|	©ôNÛ>?ó_"që‘ÿ¸aM}¿.éƒÈvŸ¹º0¿ñE÷(˜@™Åól}ÜaÁZå®3ÄD3©<Eì×`€=ºÃM RMİ£c[7ÜYÛz†j~ÕÛl4L¥5¤ƒ§…°!ö´ü†õDØÔõß\’DŠv‚9B3ìxKvC‚)>PÈdŠ"›ÏzVë¿êÛôpª ¾.’ÉˆAê]
\RŠIQuù¢Çú é9xËÕŠD†…©Ğìö4è|Û#/mX]uH=SÍµĞÕWÂoJ„Ù8À3ÿ|`æGÍ-÷Ï–İSÊiWºè‚šœu;°Çqøì]t\£«µ˜-R›úçXÑğ,µPtBQU“bfïS,|B¦„éã\e}«¡UçãAÕ0¨I	8¬wb+lõ}àúQ´ºÅã[óÉef’ÂQšQãM0RûÃÈıû6ÓÙ@»èt`dx:¥W1;‡C°¨ŠĞç$<-h›¿©ÛéÕ…*ÎHq~aÚûñ "wOÇŒí“eÙHHúP¢R®gõ—Ò@JĞïÿ«tŒİ;L›ä£»1î<´£İ¿ä‹E1y(‡zìJHns6.e)+ˆ›Gªp§éÂØ  <”un2cÌƒrúwÃxè*¢Às®[^©÷5-ÜøÊñA›ö„&Ô%É×î`R"&Nùx¼¯@Íƒ‡ìÆ=±lwGôŒv½ÁİfQ:Án¿>àt†G#+¸ÄGÔq]uÀGñH RÊÜÍUoàø2;8.ºf>"8'ê+´¹uå›mxtjnú™?ã¾¨‚6  <»2ëHÄMxgR·¡¾¥´+<ë³=™¤ÄèĞÒFÇ¼OòyIjâ¼¹[í–[=“ˆ-¶²ŞT‘dï‡qV˜s?ÿæÄÌö/´ÈK]'~p:ÚÁŠÓƒ0W­¡>Á ¦–%IMeË¿¡‚_kÛöóQò‰î.0¿™Ê$¸àÓM‹Î¹ÉrÎ	oƒô®:‚F5İÃŞë—¹ğg#Ó DBr÷
ıy êa:ûêÔb=ø,³»’Õ0=˜å—<ˆ;šìE#Uº¢CÏoAC¬Hs*\„:ëoLº¬8¸ñõN?ƒı5Óã>u`i+(®døf®ßJi/£`ÃÅØ‰ï[¾=)¨ù)ÏøÍ÷v°“®BnZ®::‰&Ğ×€ş³šÑc½ÎÀb+Öe™ ñÎÄË
=ö–P°Ù(ï Öì~Ïëû>ïDeœN.˜ìÒ7tÅêR?8íê;Ï£¶ U¼wó¤¤ıOù8.ÆYô¨ĞÔ5#Ü­jö³E6&‚ş¼0ãÚ£>Ü‘m˜V [$áGV=9la9uÕò™80ÛBõW2© }û¦ûÌş®Qá&I4†ÀÛyıË)QÈU Ó½ïÄa¸(¾Æ`Ş1“+öÆ€¨Áy¢ì—5¥;lKô1ÊC=±ê–c-Šˆ‡†5+PN£× zQx¸BÎ6jwÍÃ7º/	MïbN³ÌË»½Ÿ¼øÌÿñh-:¼K¾m°¤Nh®O«F½ÒÍTÍÌƒ`¹u/i•j1´^é}IrÌFÂSfÀ¤Ù4q `¡uS†.Æ€©ÕE¯¯’°yÑÈ Æ§Z¥ÖE<–Ì…¤L3J"½Is`psÂ0kğ|l¾ï
™ë{å‡@;˜²„™S°6=?<A	¬fåYf`Ó$öy÷æËJY$$2¨»–§áSû¦–êÃ$¿/e†Ğ£–;¤§K´q³ïÉfyg}Òí”9Š×ß£&W;Ù+J
<K¦§¯Yû"ùÅ-J°YÆĞè|ßÖÔä–È5ášQ|l•Iı¾VÜ<b¸D›¹;ñ hhY¤“gØWu§‹Bi«Šö@¦Ø’> ÂqOõr¼›±U4IÉæéZôbT ‘ì
Fw{-4óî¶MSÄøpø;£´ñK«f.$?ßãx=&|ÉÙ^á5ÙÙBÜ»ã’~è…DL¦&‡lØ¸¸Ñ{Ğ@Ó^Lí Ïƒ«=|-uDe~>±Ø$>bqıÛÑÀ9Ş¨X“ªÿ”x $ÎŠÂ¬³Q|“ãµA®õ`ÊJZË9v`jãx%§iz«| ÓÃ¯6÷ÚºôCï„ Jt{ÕòE®^'µ—;ÀG>I4ÒÏkÌ´ š—uÑşû¿ÉmÉƒ?Ÿá-wôA>¹Hü[!ËZ?‡Î+I„kM¹vpwÒá¯	CšÁuXË¾Éüh`|?í´+¬µ— +qÑ5Å·mGøs Ùâ7ú nåts-oQ¨ †Ñˆ©\bD_M§ÉöÒæƒ4ˆ‰¡Ã—xèE—5:Jy 8Ì_rX?!Û7>†#èrƒ6¤‹â…xjí[äM{§é·ÿ¹ÛÀÂÍ5r åxÅ!òuœÚù" ÉgÔPqøvïÿüJıaGœ¦+ÂŞ,d¸º‘Ajäkìë05ìó2DUÇû`×X2Mğ‰›j<šx·şK!Çy¾µIê}"$oh©¬,	`È!uÜ}póóHŠÔ`Ó6ËŠ‹Óïè+ıÿ,ï¶³X–fRª®!^ëÎúN¶:)Î­pû<RÄÿQ#Ï,MÀû ö.ÈJiæ¥$®vçˆÇt’Êâ²=T…ŞÎ~UmÏça¨^öów|>ëD‚³å¬±äŠÎ]ä¤ñ‹]ª|Á¬µQ­”ÀIöX%ÅÀ€VÿØwô­E›âfªçU~ûÊ²9ŸG_Fú5š°Âø˜Bï*c	¥;—5ı¡\í5•“şÜeŞæÍ‹ûnE>x§qfšz#òè˜Y°    ğÁ..¤^g£ ²€ ëšŒä±Ägû    YZ