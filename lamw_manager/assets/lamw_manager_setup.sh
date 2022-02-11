#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1942072223"
MD5="07408ef711fd5ab4c1e18115ed04cdad"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26384"
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
	echo Date of packaging: Thu Feb 10 22:06:37 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿfÍ] ¼}•À1Dd]‡Á›PætİDùÓf5)Ğ‚…õĞ1®ÁÖÔe›ß0Vƒ«J»¨¦gÊIG£Âr `|áY$ƒ#X\5	h!-Z^2j‹1ÇDN Ò´ÕaV=ñ')Y¹b›öÍõ	ÌPW)"³{tH9	ÒúM‹Ï9·~Ò¿Í»¾hR³	^î°€*ë¥ÆÒÉ)UĞ93ÙQâæJßGÇÔÔ/\å•Ú&Ì€EH& Ifª,ğãH&Yáµ»f"7Kÿ§Şš=î¯–ûB V²¤ÓC,av– $Ë%UÆÀ+d1­l+Ü_›…,5Ÿ{EŸÅÓå\x=Õ?Ï±BAâÑ	}ÒÅ™h™ˆHd«júPd´im¨SÑTÚUŸŸbÉ}íšÎ2?œùÃ=D‘åµ®“9¤½T^Ú="±V3¦ÿ»±‚Ïìw‡¼ö­Œs,W×GƒÏC\pÛøp¨MÌû]¾ÒZ$…Ú´1»Õ×
‚˜i‘_W;ÚCL~@CöÍœ@XÏZXĞL<TÙ7™~ıÕd£?« câçŞÄ›yñÕq´\è;rËl®ı…2’ÿÕ–úº3BÜ¸s¿SÛnâ)Y"i“qBÙÖQ¯°S¥®0{LÉŒ–¢¯¯ß4ÍÒÃ–^µğà½›«‚ê5ı’{®?0P:ËÒª¯Íÿë<¯»(ñíÑˆç|JQÃşñúäJ:·5yâ÷{Ö	ğ wJ¹Ù!³3›òb*LTR‹õÂÿ·ş*D¤¸Z1i„øøm·«ë;‡V‚ƒW412Î'œc’Œ(‰p©<èôç¹u›Âc	÷ka³%áwdÎm´¸‘ç»Œ—“0KÚUeo	X#¶Myq5ûM7Ê|Ğ<÷Ö^w?’aÆt)i¦±x‡3/Ó]^~çå!á²~\ØªaÑXQEüŞ‹æD|DANòjU¦ÿê%ÁÙ„í.šï;C ÜOw—…¸³Ó/±;|ş³g¯òµÓà8¢TéxÒ] ­ßjtJ¯Òôœ÷Ã"`à™#ôQ§eşµÆîŠ“%	:ô«
AÁôÀ­¶A«ø¦vëâp'b‘ºå—ÏoÜºÎZˆèfHjŠIÖß±C‡/í~vÄNûd^e	ªÌ¸»ØÑY½Ù.ªm¿&Ç‹°Å`F–7.öÆÍlÀèÅëGİ$v|?|ø çwäCù:ŠÒÒ«'BØx?.]‡©$¨ÃGºE9¸ãF+x`ËÂTWrå¾3¸+b‚Ï€I»×ÈüP¦à/õì³„$\~ä£2¢WÌw%šã-O}Bà²“AQL?bêöoõÚ)mª`\œŸ Zğ¾åÂP;k3|¿ùPšE|Uˆı <‚ŠáÁ¨„~ŸŸó<š0àÃg±‚ÔX[ë…ü$QuVEÖ#ôµ´îUèêÏĞº€ÁÚ;t`Å]päKm¢,´ÁÂÎwìİ
†İ«ó-2ykÓñ.^uÒJü+•D!‹˜Ib‚§íÂDjË‹§ïFKÜ\'„2™hŞÙ•6–;êZrnçgñÒüô'¢#ï¾“bB¨¶Z&EF„5Ş«!ÏÜ#¶ÊRŸxQ—)ó]pC® ­¨;joÄq×&ÅÀ³Äù®¿“×FG:ê–#w2=”–ô¹€±ıNØ´¹û½Ğ'tm´›Ql">q&—Œêµ=ìW8Œ~ÕenØ†Š**óö`²E®ÄP¼hGyÖ¿Ş‚O,O&5K%sø8ˆíÀ%†<’$í=à>##¸dsõ›r»Åj‰ô¦fA 3>pñDT¬Âù™}”Ì¾;ú65fBh›Éñl+!ìøµ,gQ0	ïUzpuXë@6ôLl¾åºEwŒ4P 0ãg–Æy²ë”vœ,ùibPóÛ¹Cì¥f#…6ƒg}´#€%c‚ŠÑTÌ§íòd¦Á;^)¨ï‰õ:â÷4Í²¢ÑçèRP<g!$VE½¦C¨2V¹uô¿éü—_@ïL†§`¤–Ù´-†$õMÉVqBW;P½Fr	“|»´ %ºÚ–PÀµ6)ìÑÆ‚¨çz9s%Éµ,N­Óëy?hrÏµy»4ÖoÇ¬2¿qô#Ş²Cñ57Òzœ‡ŒBâa—Uø'¡Ë$õÿ$QhúX™ÑÉ5ïÎÁÍq¡‚Ma­Çùµ:¹ÇÕrEêìªCğ™ÃGÚõ"¤ó8-*YráÜlõÀß¦]p¨"èx ¸dù¡ØyÙ][i¯`ÛG«úø®f€e©låGée^<c%í©Fß{A¯d¼n÷‹ù:
yäz#8ÙYÜ:ÃÒKmµmßéÄoes‡$G()J"qx“Úû9Xó/ÉÊÄ4–½ûÆó1òiÜ â)±7)vÿ‹×$…b¸ìÔœ™lõ\jæEœ¶Zd˜İÌvj	](Z²füFÙôŞÔÕé¹4«_ÆÆïEbí±{oR)éw¨í‡@pÓ¼Úô›¤ì|:ô˜®Ä$(NViç#1ÖÉİàa2]ºZn«ö9ÉÎ$m%—Sšéü+0L×„	¯-‘o«o¢õÄì/ÿ}xßÅª2›®â+6ûğ!š¤W1¨ä÷ğ€ı6İ>/xxZ+š/Wr?’*rq*:ã6D¡M	µ©WDš§>Ç%Ô’Ó$m#x#‰l+æ¶]ƒ×@)eözŞ‹9¿^HŞøVqA°İTäÜ/ ©ë!Ş®}Àûv¡˜0hG:}mÄØüƒS&ÔiÍÂB¤›Çr9ééTl¹±OxÀ A­FZ’i5EnSö|[Ë1¤lm€zÇÙîÛ`´TÿÔü¯†ô—+ï!h=z@ıbÊMËe¬-æŞï?CÏ|Øa¦Øc¯‘2ˆFæ™¤Ğp¦Hó1"¨ÚY€à(Ï¤î©ÒÈ´VFZÖñÁt|µÌÀ­ç(uÛÓ6„`æ
·ÿ0h+“€:.;fĞTÔ†¶5Úpsúñ¤‰šÍ”ÌU†£tzRš3*ê~İƒnl<%qœíÖLÉæÕ¾¥<¢vÖ&•Ú…ïl_G•é·ÎÃ
ËB&İÁ^Ua¢ÂKë’ÍUI	ú—­ÌÒñ@y‘ö§o™È¸qƒI”¢­ÜJ:JØ:¤æj8ğ{ÁŠ>U2 ô  pÈ6õõM=ÿ
02ãCY:=k¡[B1³<Û²íø Œ
¦ü¯Ú*üìsõìÏÕÂ”ZV¾$ –ÅïÌšÇsïO_Cê¯)<8·fH)ÕL4péhº"F®f	$ë®b³ğ×Qğé:i{:8•2óÊâ§«øµõ[§¯·–e¸t]#j¬«â_yN ®­ê/‹€(Î…n…©ë	‰F¢bG&C‹-.ŠÃ{÷Êİ¯ı”´F<ÒƒTdÿSîÕÁSõ¦îô|ÊÍÔ‰W{›œ¹ÖP™¢“¡«·¦¸ìM·„ÇlúM†LM<‘cnñB†¤šµ¿å´-Âeı¥ñÙç<Œ¸»¯àL_*©‰=XqƒÛ¢²Š~K]|òê’ƒRÛñ@oQÔ(Â eğ#2ô÷nÂ>ÓÌKŒ61œªšm˜¢İ€t;ˆû)¶áöNO;*Æ¡ÍL2ı}7Ø*ú‘ék®¹{ñ­„4i#?c¹Q"®ß…
Òuûø¡@Q2wûAe-Aè&íˆÿ´yBT ­5 ïÎƒ¿8|S#Ry¶]´2ö®¢ëäŒ±È	9ïwoªİzçØÆWA3ßÜÇ…"ÖuÔByôU?¿?Ûš'RkA9Ù‡;1ƒx´™IÊU +PgóVÛdÁú’ÿ²‘Ç>øØ;Ñ¾ÄÖcıXóàXû†V‡é*œËÈq»Æ¶êö'Ê¹™”B‡ìÃ´I†w5ÕSY­¿Ğ Æ)“‰–Dq_ÚÆ9y•=`{¦=¿ÿ’[‡‚¸×ÿ‰vÖ«Ğr·¦sŞf«'ğrH"Éƒä¨Â‘‰«L:È¦…İõG
=4nØª  é¨å_àÏ®˜‚PÊ} gĞ˜,ºŒvä‡Yâj2k)‰³<3©ÂÇ¥ÀybâŞŠùÛX&ÚS£5·:ØÀ
ûıÕJ]Ô ÙRÉ·şÖh§İ{gI¶ÎÎÅléXfÒ •j+y,çOn:dRİã”5ƒ TÛÅ”É8ÒrôY;¯Éqi¢ì…<’€VŒÆ´”`clr¦	Ê¹šïîãä‡h¨âÖÁÚ°˜ ù±–©ù¥Š¢+‚ÊÒÚ•İ3Pls‰ÎgQ×_V<†-Ä{2¶³‡Š'–8nïøá¥ ñp]}[L§8%o6ÑtÓBÄrÔ“„œæ¢Æ´RA‰™ÅAuàêºn¥e+O®•§Î7ÒÁ’‰ÀnWoğÒ$û“g¥vÓp(J~8«­xLåxiâIò7‹(ÌnëÙ9…2i
Ãwà0Y~Yü˜; Œ“¹;T¬œ4æt*™AÄpy€“oäÎÎÚ‡‡e'‰x7h–"_` ¡Vzè[nĞF\jLÑ °A‰ä£PÄ€4×T«k›Å¥’Y£O]¥}æ=Ãz” ÿÜIõZ¯g1E²@ı±+—LÚŠq	z
“ÌüŠìãxlÂ'lÊtrÕ…Ù4ßoK@‡óyñKƒ7Ó±8R¶„ü1ˆìRÛp}+İ$ÕäŒµUö+ÍW³Îy+şjÀö¯“4èâõ@ÔşÈ‚ñ|ş¿&GéYÊœSeî]†è oÃ¹eq#ÓU9+Ï(#’¦cê Ğ´q©#ù: å®ÚÂå *’#¨éÿÊW$‰‡¾Ò ”=lBHÏ>—ë>pQRù¨œŸNZ“äÀ…ÇRÙY¦1oZ _â:li¾q¥Yş&ĞÉM™´ıÏ[D²ğ]p•B·REk`ÕÚ´uı]™¶jšV¢t@õ‚Üš*ªwR2AY½<R•9º‡>İ¢ÈG‘eUj©í]}4ck1¬ŞiÂfI^“T|êƒ³®óÜúÙØÊzáØ<Ú$Ö˜±‹gJQ*Ö¿Ÿ`_“,‚)B»¯ W êí“#j©/Qâå[…:cãD_ZÀûÿş~^—Eh·>¬hò® „¾ùB$|bñ¤°EG=Ñú°dsT_ÿEnÄÅ«»ÍÅÉ‘F`K8ù=ì-‘ÄíšìPEŠ‚#ê”Œ¦ù†j1dÅñ©ïªcÌNœ°`y¤R8æ8Ím^C"kÖ·„÷97³-uLì&†GnøÙXé`¢íj¡Íğè>l©ÒÈŸ—H°ÂûÜ­jÛAÄÍÄd!xà}”ßéÁµÓà¨i2àìgb“õßXö´T£ñŸ™m›l—ÜN¸ø¶.$oE˜œEŞ÷–C²Å‡™>=+>Ù†A2$iä^ôÊâÒ¯kûMr¼ò~W“>d}O@­­\br³ÖÄPû•o?D°]P„dsáä†‰.ÓòÅ8ZLò`‰oÈÊ3¦aOØöLøCœ²¾Prv-î²ÕH(?>A²Š¶5­fYÀ¦<Š7H ¼ğ^îğÃ/p[M#VÍ˜ë&à?€J@ ôìÉ±¦üZš4F#{¢!Ã¸—+*³ø*& 0Ô=ù%–”³sŒw°O7¡"÷5ıëíãÕ©{! üuLÏ±,º2rß‰hGÖ`kéâ-°÷/2{j3[âÄw\2¯vdı¯ì#Ü»kùtºDQz°üü}9¾âhoÀyğÕ÷ÆÊõÉ$¾n•¬[´ˆÍ†ñòˆ¾]ßÄK¢hïË£9¨…ã²vÑ½Tùâr¸~{[¬zÀ¹‰]Òô×ä^É5öGaÄ©şX‡‹Î­ìe¸æ–ˆšõÃÎ«ê·“ÌÓtÔeg’£5ˆjîCcâ´*ç»¤^>/¦è66!a9`7j{ÕÒ×ø°Ùp1¦dnøÏÄ«6`½h×‘NëJ8Úym¼ºë0eØ2?X(/±½Ob”²
—Å+a®ê¡}±>‹*¬„9Áİ©àyGœşİ9jâúÿ¬üÓr!=EÏûìbß¬˜øL‚6U¤"»m=‚øÀQÜËG*‚íÏ¡éİõy	òù,}&¾½|LOvÁQƒŞÌŠ²Ù²dßaÃ\ÎAæ™^Zœ¬ôÂ#•kZÈgk¾Ÿ§f„by<ºÒzUş<Ü´ =½j7æHg‡ÓGR>ğQŸ„á°¿
 vû³ı¡«ÃßhŒÊ	¹ÏáÍ²·;ºïOåÔˆ½”ç<ïÓáüŒ„7†ãuwkggŸÔ1SoRQ3uÙÿdØ)Ò…
t-¨S)”„#¯8ñPı¢”ûö.™ ¾%4„ÊªãoÀß]j}€Êç¦\¡şe{³­V×{ÀÁo¸¾Çî.Õ`,ó™käåÏ[Œ8¯ÇÇ¯úƒD0çƒ#á¢ ³nuÑéµÜol'Œ“ñ³"Çp"…ÆT>?PY#ˆáCrÛ¹ŸãĞ¼ücVérâõâÙæ^X3…‚#{úeü4Já_0CÂ ¢åG"S²-°İş»²ûg3Ö3m	}çH)»ú”áÉc$IÆìú`G >CO.\îaD˜l5«í“ïÊÕ !O•zÄ3£o§ùúÀL¹ÿµÄ$â»Ş×%şî	ĞOª`(~lXƒü—_ê!tPrGŞXUJ×ßü]‚ÀÒ5òDõßEšÓ"É&©BÁ“Est9æ†-2 ãF œÿQ]‚½DìkŞ™ğOé“¨ €Æk8IÔ$q.œó"‡!¨]õ‹9œ¾J{Ò“ÂÛ©Ïµ¹k[µz‹Â´¾ü1hHÕBåKÇ¾y ƒøı1¥ƒ4¼º©aqPûT;®0S¢œ¿#ñˆvW½Tÿâ¹-ñVÓ!…oÛ@¼˜b™å-èä$Q
0\õí­¿tš:w‹T*Ç‡Ê€…ıÇ	tÃœ³hí	åâPæ†ĞdÄú5RaAäAdå0ß%qn!›LoÂ}×šè÷œÜ‹…6®Hˆ¯@¨|h[~ûš°äd’w£eD6­­«™X%¦ßZs'ôåÂ}ÑrqÚóWQ}m,qå}»í_+hšŞÇÛJ«´=i/	²Ÿö+_…Ş|‰®_2Bòí&\ŒLb=~zıF¬§mj®´æû*kyò{N¦)y2$×Æ­ÓyÑğ— »¿ôÄ’)u rÇ¸ıÆµ{jG}ç.?çİÂ¯ç›Í²ç£§fBN$hˆ¤³–Öhå
{±×Wƒ­×w¿F'±€Rlæ°%}k~t¸ğB‚+ËRˆEÉ{ÁğÅsv](y>?mŒğ±³ºš´K¤¼Ñ|Ø³jO%CŠ,TÿíT=·\*a‡I9Ö¨¶Ş¡áN£JågDÂ_Û)^ÉÔ<réÅèûƒ@#‰§£|ôqR!æ“·ô`D†ÂKæĞÌÚ€H3X¯†Õ‹€‹ ·#&í‰örçqé`Æ©îù+omÑ#ÀUêX<É¯7*@ËÛÀ9ãšY4Æ
4Sƒ „„P)XØ=^#|r½	Y9
úZ\Ûá;¢ë>ºmĞ:'›E/
8ìşÀˆ¹œB;'Óµß¾\sô",~Õ¦G|-o1Õ®7JCUK¿§ã$ÏÍÄ†(ÄÍÖÍ‰'bõûñ©ó„ÀŸïñw‰%Áöé=oãgbã·§{
µé×_\µôSñ:ªObU®«r<ùV³­í÷B›ôÇ'ŒN¾š¦XÍ?œ’2h!/°4Ô71†»,Ë¯²NH^ç²LO<ÖI¾ÈÓ)êøAVbİÒô‘hæ†hŠbrŸC¦î?³µ ¬İ2®âÈ±ª/ÆxĞU‹è}\êl¢Ğº<Qªh|×Oe\¥MAJª„~5j*[áÃ®üK½!8¬ğë“Êì/ãôÿ$™ÊZÛ;–‹Ä:ÚÉëP'Œ¶ÎR»:¢S,òvF–4ØOŞÔn¡8ZÌ¯96²Œ•åX·>è’’ó/E˜ÛA’ÚŸYH^róJ*=¤Ñ 4·ÑmúNj¸:›º¯J(9)),ÕŞy¿ŒZ'÷¦¦=_¹7M/µ”1÷Ê±ÅñËIO“¶ŞòùM¦#‡²ô²”B1ŞDÿåıR½ée¦ÑEª‰/ôÕoüD‘Î¼ÌaZÉôş)ó£p÷àmh;JäÇRˆÙYEJf•ÉvJšN6,:èn!—èdÒbÕ´å.®ôäIü~ éğ19Àx"4©³¢ú19	‘ºwÓ,`*akNZ 
N_“bÆ’ON¦bûÑñX¼vƒj®†LâëÈ~yåÓòøè³|ã_„Y¡ ›Ètj'z	bÓa§0ÙpoVTã0ÁphJ£… Dw"MºèšQÊßq™´#ş3Y§–V?àoîŞ<
ªi€˜2ÂyI_·òB×ühYîÇÊ¥–·ı–%y$¯H³m}$±ÛGGÒ;XÁn>S.½îqöÒM!ƒ;òP‚Så…¸­º k{‹¢”°PğS]kb«ø³†í’şCí„Ÿé”¶tm¤-¢Ş8pÂ\6¼õõÚÂVƒ>â}™üş ŸÎÜ^:êìÙ÷1pÎ±¨“cõ-§Ö>0k¹O¥æ¼o
ôëg¥5“ñ@m&ÍÔ«¼CêÁãø:…&Án'ŸÜ(UKÏÂIákã ÇuÚì`ÌÓ™ØÈÏŸ%gs§XÓ…ÎsH½öûÔc;šµØUõ[ÈãÃqÇíWÒ¨>ÁÓW}9H.Ÿ3gu*&¢›èş+yJ*l>ZÒÈn¹0€›ô|Tªä–×n½¶îÔ5Éà€»£èŒ4yÚœœƒI¶ÄÈn\«ø ¾Ñ­ó\±¶ØÕ<J±.ªšĞ‡[QMËdBC3­2-ğNu@nL$Î¤årE6æ-¬]–ßs«yg‘êjÕ)}YrC4=ãvßXÊn¼ûí—øé«‰OÄŞƒQâè^Ã Æ“nz”|îEém¶­ëIá‘Ùß‚ğ¿Ÿ2‹Á.›™ºJÑÑ“º#ê%QÅgú¨ÁÓÚ{ï<ÙÓ€­¨Sl0O+^Úiİä`]âÎÀ°}rbÂpÁõ«5.ærÜ°K¶Ì3ï£A­Üˆ-H¸MVñ@å”×-Ñï¡ªçg Õ‡¸ñâ=Pd„ÛdğN‡Èh(§µÈ6õgÜùZÿ›O¹1ªıñæmrø÷Nb íÆtCäyTúŸ°ª_C…€I_wÕaÿ‘I‹i*Ğ\YK¯;MëŠÂ —O`m\D³‚«ÈSv½yOË^£,¶QŒM¦.·OŠÊ—Šé×õˆUã ($´åL`4Yg
c¶éÿ'…ŒÀñ‹bäWDì«]ÑØ¾Ï$<ç+‹AP¿“‰İjA£0ü.0DÙMR3rëSI É;á.apL™™e^Œ¦îvPîhµ$!
8óy–çéHŒ©5õBŠ‹ÌŒm¿²Áà©i¶wØlèy©ÿ£Y‘üt%q×éu…ŞYa²Z´¹«½3:Axü/e®gYü+Qm­vÚ…+ãâaÛuœ\×íı'—Î‹ß—l6&Ú‡ê°îøÇ¡ÜZëè--Vg»	ã›ôå±®“š­OğæÍWíNè+Á~{ïXÌ ã™™]Ò}O`0Ã-§DøóËÏ‡kŠNu±%ÚÃ®rsSv*Ú*!$"{ÓÇ¸ßõeåS‘İáNnàë¬ÅZˆÃºñQÛ•Z‡Rî>¼v%»5ş½S1qÖa/œ¥Uµ$$:>d²Ld&xõˆn§-›XcÕ˜7”ßú–û@*èîÑÏ¦Âì,Z’…6Pû‘ÒäÊšO§²©m…o>¬–ÓmlàÎ&Ô>á×¢ÏÚïŞ¯”¥Ó°h¯+[7-¢³O*Şeq‚(4õüÂÓÎ\,ğ]{ÿ"°rˆN«ÿr\‰³ÒÏes2êfoß–²~Zg@Šê­=C_´™Í-°şÀšÎ7Ösø¯Vœ¯aˆÏv'™3Õok0¸âÔ*)ÌqíI‡şŠQÃÜ0ÿµ1³i‚SªõºÖÄcTËö‚+Ï†Oy "ò÷ÈFÈÌÜ‘7¶ı¾ì|ğ.©È­r6@’•agÕMƒUC©°
Ú¶ê%À†O5˜™iLnu=Ğ
¯‘¹5ãåİÕÙW9¬‹®{Ô-+Ú>K¹ŠcÁóh$Ãã6æûáÇ­«îcß©C³´óµpŸÅD!Ù¬íi|İ6N¶3N
“V†½…ñëJ,~âB°¸­¸¢í#‚GqåÌüæ3]$)tü’m•Èº)“´í‚)!™º“Ã23$a:°¬#µòÌ„û…”&Ã–±9úò¾EáåƒƒìZÉÈ×|GÏ7`¡?µÏïe3èî4–3­WN•³à¶mØÂHEæeÎ<´ÃrPÂ1™ŸtÁ 50.…½@F=*M÷¿,î8Â›¯ôİäO ^Ãã³¥ŒÅ—šT§€.RŸØÃš5Àb*~™îâ)”S1# '^Ö@ÙIìVÛ„íÁî‚À!i(ŠøêÅ-OÉïuR”mkn`t£½ÉĞı0ÄèuE¿İsÃ°:ïëƒpÁ"ô%£[ˆğêÁ\³jfôÁÃQ¦Ñ‚JËO‰aG¢¨…-óà¦Wq0ÅßŠˆ(m&ËAWFSÊ‰3 $X«»@	r>P
lû)Pƒ3BÈ*§÷¿ü[Rh^N—Z!HXÄ*Q²é?ã\òÃúåòò!Ûø«¶o#ÏÇÎÔœA™©µ3Ù”+_ï£I’‘"ñ+‡ ¯ü.I¹] u	A¾»Q³–«İ#½u¢úşÊvÕLd¥Y™H£ÎC’FêÁ7¹kGtn‹)F­RèÄÂ_ïnÌ‹D3wUoX”ÛI¯ÙqÜJµ(şh…‰zÎñ]ğ› ¾'0|»møÉKhhI(ìî¼İä©°óÅôâ é©^»ÆŠ4D›Õ&¾"ªÕ°UéUı"Û†‚ö!ØÍ—5çNN2ÁÌ¶yw×{Ü»ZâGÑ è°hçx ¾ôúÏÛ2:seÛÆ8HğÄ‹Â…d³ılbEş¾ÑÙv½ÿá!ÒYBObÛªú#oQŞ–6
r9Qäq«A¢iª¿§Ó\åhÑwÒ±ëK¥·L
rpıÔQnHî0©O:Ù°cµŞÂnå:.æ©0%}3¹eDLH±o+`]Ğ;¿ğè!?vœ³È„³îZrwœÙÌÚÊû4ÕıÙ&0ŠWùë4ŞxçÀYrOÏÊe~O3»;dwÈZ1˜Ê ­5¼Uœ’³o¶=m©èŒ[øŸA¿ÂùàjVˆµ=&¸¥ò(Úréï¡ZšÖğ n+RZMbø_°ø283©«‰Ù5%
òb#b¬Eœ3\3iŞæ”!•JşItõÁ8óFÿ¨ú¦¾ÖRI}ÏÿV<{¾¯¿±!Z‰
sšÈ¢>È»âı0²o·WÍ?'„"½Lß³rÿ ÖÊã> ¢n¯.˜:÷Æ©mÛ\·Óç–£tû$–…k+Ì©)…èI$r¤”qÃ Ÿ5‘c¿=ˆ
.¹crk¨è	äåèg{–$èiRìÃóÓ±ôrØh–yrœàĞbµ[ˆ ¹”_rÌGàŒ‰=æöBFË[ù2yîMvwãk­V€®–ÅF<`„‚Exú{5¯ÙÚàğÅiÒØ…åÂË&ë¼yŒ~ÙñŞ¡Ù¦wd©(GË8°ÛS6Iç,-µ…®<±Â9F™!ğn™•6Îñ¥a|1ÑdU˜>sò“8\ÉgÏ]	›Ñø’Õä‹æªÂxåœqÚprôˆÆ%ï:)e½G«şÔK6Âñ³shN{eö*È •ÚG Ò0yôò]¿Û- ¾²V•²jºŸè®æ_#	òødÜğ¤­à†Ù;¤õ6ùåOçŠÃ½P1ü`2ùÇº7±á‹…–ìfÒ?ÂŸ[ƒMLúÈÍzc¾p‚ïÜ¬øç|=H£k ÛÜd Q‚ùWLAfmœ5ªˆgQËv¾[É6ÁÍ‡ß{I|Xö‚–c†Ü!ÆhBıÕä=S—çy~ŒŸwE<V×ocè–«×á¤|¶ùı66ŒXºs#3 _HIø'netEYóÔçZÙtùf·Yòìì ˜”©«ìû	7ÊG=¾DÅÊ„j„İÕ7¾ğ!~ØÆ„‡üÉøıï0—À.GTÏ«Y²w9!ñuîÃPsÎê¿t?bÉÄwY¤Ìjzîö¸[Šz“"¸Ù·}“%ÒÈğHè¥Çg¶@ı´³â-bºÖ¼%„8/Ë¿fx˜k2[ÄÔhS`aÕĞ/WÑİùHBÓ»O‘o’¤È~½\;/ıûçÅa’P‡Ğ¹­Ä‹ØÎèÍo%İ¹äÔn.õ¾C§ä¸g‘yI…w ¸#p„‹¨p§F¹LzÎÚëĞH†ÑòôÚÁ>Ö©0€*¤îÇ’W9‘_‹vú_×’¥ãáP×8M8ü{Gƒ¾ ø€3Z/(Y¾1gglg'—püízŠË’¼)¹ô&q áTµ[ÇÓXbP63(ÖNû¼ÏöûıÏ„PYx…«vÂ¹Å§*×äŒ÷Ûnó7mÔ‘®®gmàjÀ€!Îj^(WL«•Ô# Úm–üØuyªCá}©º¬A(ÚíYÜ@ÓWöa= QP™Şşê•0—}Péê1a½< Ã¢—=3?˜¤€¬u¾ûğä¸›4Ì®X¦¡c¼hcRÓ¸ÁOŒ¥€¿Ú/úŠœàBœÜí…3r-R~‰A„I¿FÁT°±³,—÷æ!Rç2(’İÒ?¥lü,7?Ôç@2 ¢:ÔıZÈÅ–ÚÀS©#zFÅÄzXOÜg8r:µ¿¨‡ßLJ71…y¼™Ïİz¥^ÎhNU_Š|©ñb>çü1vj¦n¹ÿ^I^ôúà:<ğHÁs´Ã0§õZ¹ÂuMÒõ¶â_@¼&”šf6ø”*b¦ãï9œ¼šˆ´¯ñÚåù‚ÜVmÃ*ş2ò€hÑ¿…gL(J`_-ËÃÇ¤Õ³x
Š>4_ìL÷MoÖA÷9úO¯\¶BéN‘y½¾£n¤½¸¹ı‡‹8DŠÃ\È0È´ÉÙ?ùÏ1YeÛ10./T %¢T¶[f=ciUÖCv&­v8½ºë
¹6]ÁK‰6àg°÷UMşllõ]©4ê¯>ôy9éŞ_¾îI2“¦Ñi
)P@Î]×}³CúŸÌ'e¸G`›¢1”¾Ä'?xb€PY4mæoö¯ƒ3ø«  tœÒF	Hû½}Æ÷”¿5EK2|\úÂJ8ú_RŸ›è”¼À‰cŸ<iÙCNÎò¶ €Ì¬ØŒ:ßŸğÎ×Fì°{ïËêÆ˜¢Ëd“ÎHJ_¡A×ô‡ÙA¼=AUx°=ˆ}œiuN³âËÜˆ Ë«ˆ¤>®'ê%GíĞyÖûdÖ;Ï­Ş€¿Èj´]O»FyxJ(õeD=¯¤7VDÏ›è¹nI‚œ×¢ızPS‚1ã´–e¡ÍY²ìüœåôÂ“{°cÛL{q¾Èò<ou“An±Ù³ãvW8Px.‚rÓGkÅ¯3F‚¹Hàš"‰ÌÕ™¨*û“û¤Vékn‹X¤µŒ‘+×ŒDÖ¯…LÖl•®‰-÷õ~&¿_Øñgøna2ÃÎâfƒ2]'4ù+“‚Î™Ã›P,2ÀÆºÁµ•cùğÿ-±ïçŞí¤cşãxãìíİòõ¢DjãŞ!^ÁJåA'x4aç¥À"º ;&%è?XÓ"=rJ$ÍÏõÙ£5<ÚÚC |!ödëc^Q[§hP;•‘Cd&ˆ±,!#~ƒ¼› †3{;E¼ş€Ñá"üR\ÎuóÇÆõ ³<™Çïdùµ©ı¬ók¥®"‹Laî™xŸÆE å ûUø^f2iÌÉ!ú¦€ş€ÊÇfjü°<+’#5œÂƒ¼÷çö9ûfæ¿¬@ßJ˜¼_ãîÇ@¿¯d±IÍ±Û9b-øˆCˆ‚DÍŸÒòe¹ë„_jêÈ'YÛÍşè-)bäjÇ5î¦CFMä q]?7FÎ´  ”9¶ù„ş¬G2KzuŒ,#¶òÀıTáË¤~«xéû‘\NOFŠêÅsDïoÇİàÌFÒjBÖ¨ö.íì2@Ê¤í”l!!G¶èÇn»¿<áxÛ ı!-Ÿ®ÕĞÖÿéÿ{-ô=Ö§¬×ƒMˆÒP$Å ä/«ß«áÀ‘šEBGõ²EE6¾nëˆ9€Ìá„ı¶=Š©å?2ıüÖ¾ ¤Än„íÓ 0 €jzˆoÀyûAè(î.((…ÚÌˆB„-ÿ´Î.¾g¢°Õ8ñfß0F3¿ÕÅÎuC2§ç÷D¼ÜÌõA/_F‘	£Îk\şcd'ÅÚ›@Ìw>v]~J×å¶aíkˆ¼œSÚ9ÂK7·=DØAa°»©(d‹'Em­e'ÚäÂ•Ğ4ÍÜk©® …—.¡ì¼9³8ı®=(ÿÕœĞ*ûÑßsM7—ƒSZîZvÊ«İ ¼$!:œËU*Ÿà9³{èÔøïÚ ï¢¿bn¶3àª¼ƒó‹w‡§µk•%?(fÜ‹ŸO“òhH‚ƒræÙ"“f£ºßÖéPÏ«lª	÷Ÿ.ñì
5úìC¾3Q”¶2ğª€‡×îœ îGy0D›föãñ ©ÏÿX¼ ”ØäÂÿQºÀ½ÉñĞ:ˆìæ¼h =Lg¬ØTèAĞÿT¥YŞÜ¤ZvsË‡âZÊóIY5‘³bb¹fõÙG÷æÈz¾ÄAèì÷ÈAŸ»—Ó$#hä2C!3iwŸ4ˆE	µãÅ¿µÓÀWvÊ½Mg9„füŠr‹‘—m¼äÏ°EÈ;Ëw¢.9Û1Z~ŸseŠïş^QŠ;¡¹eX¦fò‰ôÎF´‰şÍŞD±gâ½¹´nFCM¼³mó¾TtjOÆµ#µµÂËÈ2MBd±’`ûã7ú†}ƒP7* Ó±‡ïÆÓ1­¿Ë¨’›c¡x%®e\‹,&»\‘2xğâfx-/“>ñ‡cŒI"Wú¶ĞéàÎWW„ökQ šñIG¯Åç{*·}ã’?1L'–I%àÖY1x<á¯ƒmÖ/şİñj*E<;„DÎä¿×òŒƒŒ(ôÂğbÄN²ã•,Â7Š;·åıÉ;³j°—Pô CU!²q5«lš™ÊÇK´ví±‹",E vÑÃ×±Ši‹ï”¨ƒÿ)á²»AåTê¬z nf…)¨‘Â_³Ÿ¢(°ŸvöÒhbß
L^×/ÌoäÚnô¹ÎU6¶ÆŠ4–O¬†‘j=ı‚³æËú¥¢¾Æ€¢¼É€¹TEûÚê#ñ~„sµ1ÔŞ`ı"”(M~iíè¡=Xê5–€ ê¦Û
Ş£ÚÈQ¨óªÇ>²Z’B½²‰ü(0.Ğ'úKxF¬@«¼w´/ÈTIìª_Æ×§s4Ûˆâyf:.ô+Ğ1]² ~Š¢2İBİÛuvy#jËşòÁ[9¯òß1RJ^[æâİ£dÜ›ÄÅØxœ¢6¥_ˆ¢.š&ßÇ+ˆ„Tó¯*!şxÈ?‹ÀW<¼Iöpßyör“z¤¬Ã­%
˜œDJÒqœ¸wûa,cºÊ2|k	+FµÄÇàn‰á¬y3ôvvàñÀ½<Z‹Û†£8u°™rôl¨¹arG```o0×sÔ¤™†üK=-ÕçÊRœ´EÂötŠ˜$ªØcµkáy-ºô<Äö"`\u™QVƒ—'›aÍeòÊ<5ğ¶x75rùÚ¬FäŸØT~B#CòºÒ#~Ù?ØïURP;r¡’ğÖ¸µ·ıEìJwm~ßŠ Ì€½ıêVd[^Ù³Å;Y|%ùtĞ§[^u¤*†:FF É•{·p>ÛŠH"€ø`æ*P¥¦(qa´Ä[Æõ‹vøûÚƒ-‰Ğóêúš~t}¢¬ú´ÄA+Á9§(K:^è$pÍ¶D›A*¹†4îœ0º¸Al1áŞß¨¾…ıõò3ğè»ÙfÎÔ–é¿Á;XIƒIL)·’}‰Ñs®ä¾ÉæXÅ|%¬r–Â¢xÍUŞ,ªb³6\íS° c{§âğêëñ×+ƒ~¥Jb…8~ëƒ_/«‹ÿƒBî¼ç'ŒÓp, ´ßU.¨—¹øCP|	'­/é}¼M­	³òÀx …<›‚üKİjÔjÃfY…‘h37µS;ÆçàÀÇnpÔÍr?ÎU{¯ë¬üõL‡,4§%@b¼—ƒœdkÒM9ÂØß›¤g2Ø¦àİ1ó\Èi7¯h cÈ‹£?ó¢ñm¥zÔÑmÆ¦¦Ó°Lg¸`B5{[Î­¨Å2˜4êûæ7K«ïP›$©Ò¯úáí¢·Ñâ2U'÷V¨±bÃ2&¬yüóìó¡øU¿ÿĞ÷htÑ·\NAÎáedƒ:÷‚®¸
ÑQ»7tfˆ>9Y1ıü$ëŠ[)ËÏª@–¿0"@›Ü}®Äy\Áş«íÇûÑ
x|_ )¬?.õ„Ÿ[¥.^ÇùCdmdàTOV¥YÑ*ë®Ñ%$ ô¡ò›‡5£}‹wƒ¼¼Æ¶ñçº.Ìmk‡¦§½ÇÔÛgØ›ç!zëÁÉ¿´s¤`ÅguUğúş¿Rz 2ùr“m	dÉ†µaÂÈ =(1}Ğz2óŠNP)çğ7°óà}Üüä¼Õ“%…kÃ}Ryn?fOA³C¯‘Ú‚W„)fe9„†úŸÜA,x^ì½—NÃqìæ¬<´t&ÆòĞ>°ïâTêl´yhJá¨L)‘˜`Q2Ó<¬ôññ¾ÏÉY+€„¥/¤pª‰ÜĞéˆqn\/êHI RHã/èÃö:«XWóMgñ’y:—’±£HŒıFæ)Æ©JDË¼H*ie»åÓå²š–­¥İ,à¤me ’ärİUdÃÂ/I©³¿ƒMúK®ùFG9èBp	Ô
cnº6æŠËÒ\”ı„adEaÛN;wCh£Ö –€Ød‚‹¶g^üùs0È…î$6+Wş“~í¶ƒ(©¹6å·¡a‘‘Ô—2ØÄ&,Zš™¹uÖJ .Ş ›Ÿ"ó„—‡Ò µçÌÁÛb»YMòNÎ_B:ÙmœXiÄ	G šcd‹"·cÿqø¢©Ë-ó`ü1âwJ¬˜wT‚ìhÓÆêö·ü2å¦©b¤@{Stú¬°ƒä¯\ê`èmŞÌß9àdáÑşÌ4J¤ƒÅ×Òz{h}£%ÅlÃ…ˆ‡¬Šáø¡E˜˜ãt]$“¼®ÅG uë54T»ô-—•%¦ª8ıßŠ@AEé›Ä.ÿ<ù1fvö“Ÿ'ïo«9‡P"¢&îa«1^,†Üà—éÎ“É¤§lGpşÔ@‹ìVÿÉëU3„èÌ‚t~è§©›O¥z2Ø×äÑ/ÎÁJğ¶*]q'Cì	¸VZ÷ OÍşĞ¡©•³sñ-Ä|7İ‹Â\5¤yOëB½÷$ş" ãwgâà¼iöÜvGX’÷3Ëk¥0éÄãà.­äD–!Gxá³Û<šå™›w58ô3ú& ¸dS5Wí¤æ®ßEé®ü(è¥©»@E7Ö\6rÿ!XnàÇ¦šÈß¤æÕ´f~C‘pòp*kaŒ,Õ@í#ÔòÏèZkÏt;°ê¸3åY¾VYÈ“Fƒ÷S7Ïa¥ÈÆpîçÁ0¨N·ùÿ¶Ë£§SŠ BÙ’ÔWÊ,’ğ
¯s˜<øHî]âüúˆú|+¸‚ÊÚïşL'î‚—±JA‰L7UÉ¡ßäBe E¬ç‰#”Ø'\ÎRÉúeá«ßæ{Ád¾Ù_åj}ƒ	Ìæl"?^iï«Y6£	†»cà¹™*1•r Çß¸§’bAC‘çÆÇ—ÇõM®[UÇßr³ıŸø»Şbõ~ÃÛµóñ±øÎÍ:ÇÛdä@2—p{}êµùs©…½ºœSùÌÁ‚ÙÉÌ6BãOOßÜ5Ë²†ÓŠ¯B:ßİ¶ú&çÜÂq–ãÚ¸`ÕUşæhúfÓ¼Û>5‚“z@,ƒëğ‡¼f Ï·^,k—f¬VKJµ¨aZâA>ù›¶š…‚k‘†Âx)Õ¾ F‘Œç¦«ø4ÙLÙ³d†wv¼ºëH»I®Õ-œ5¿ÁY
ÿP«Íøê§B¹Qïêa:n‘b/`.JÍĞÜzÂ`êªºH:l‰sj9É­½s{ğ›³EGóËMÕ½eÍãv0¬+İë˜½Èg×oYv¤ŒíNÙi\·{ŠÓn!vË/ŒmÃoÙt0hÌ^.3ÛvŸÇ¥“ Õ#©)”'÷â2fXáBK›ÕØİ®Í‡yÌTÏ¶<şó³b†øš);ëùd‹ÖUÅ+šÃ¡_".¢“˜V®¦å|ôÅ2<Ei‹‹±oøB Ìï$ğJ“§DNiÌ!G–ñ+ê„s2§·©W,fZï±¸A!|Lwòg‡´Å}ÆmY…ÿ%…ÖjY°ÇL‹Oõ–cüû4G²&ùnè³;…¸!²±"[‡¾^+ğ·SNè¿‡ÆdsUàôB‰àiğ½˜ÖHû3Ì²—¾©;C+¤…ØóÚ0=,pMú×>sèN‹”]ât¢Ûçäû¬Ú¾‘½pŸxôİÔ©ø…Œ’ßqÉ%O©V^°å-§Ì>×ÑD.¡‹İdÓºA´|2O–ûãc¸8:¤x³»x0:
-NeU^RÖ:ì4ôŠnØ¾èâ‰WDVCÄ¢@Dú>‹jŠ6ÛË=JQúdl²B7µ<édY¾ŸÔ[ÁŒä¸Äø-	ŒŠLÓ|òSÊ.pSœbD[] × ö¿0M¢‘?ß(	r¢Ö.´IŠ8fSşÈÛR½aáô‚ÄÃ¹T’^…é|†HnJÉÔ0DéßO…JL÷5wOp”‹ÉOaìkjZ¤†ëÖøÏ®ÚìÑ„`H~iNíµuh^hÏSõş)¶Ä/è¯b’•E”w»wÌ»¥2!ûƒº’–¡Æ\öµŞ„Åª„×3Æ«P/äˆ}´VzY[&B1êÊiÿZEƒ¢{°1„‘‰µÀkÅ´¸üe#ëú—‡fÆú\pèØ:gzñJ.]"NÅ²H¸ìëÃÀÎRkv@¼¥%t&`‰œ·ƒ‚ówÂTh¦Ô,27q™]0·)ş“m†#ò.Ù<“¨ğ³·ó0å•Oö=,J–úç1Ê:Æ&ĞÂn½(º´á`¡@\ÄYr]ŠÏa¤Œ(6$R¤6Ğ/È½f¼ÿ1îÌÿ–Uj2š›. f|»ü}ÙJ‘°²ìO›¤)2=šà>;îú\IDš†÷ÒıFW\°£¼ø%ÌÚ¡Œ;3ÜHFÏ®mÔç/æì@ÅÕ²ıØ¡F^ş Ÿà~!4êİ Õ2%ˆ#‡XCYÌ´›3¦Wö|b¥õF]û%'Îb•;9O}æ‘~-JKp/åÒæïZq¥váë ŒÑ2à×¶‹»è(*tfãO©P¢s˜K=èŸ±Ép¤àö§¿·¥’Å¶vS};8
qƒR•2‚õää„5x~6Á0v×Ÿ“î_«”š'¥w}ÕÛÆ ¨ÒÄ€@ Ê‰”di-`2[ÙÅcã1µêp#FëíûNÏÉ¼Ô†»c5W°0ğÏSôàäôæM‘Òj1]¥Ú[^çeõİæ\­ß¹t­öfJDŠ~Ü[óßbø >*­zÅ¥\X0ï¥ØÅ;sÉöaQœÔNŠĞ'7M_9r,%-Yf†>“=å>³ÏäNxbP4XU‰ÃJ†H#}ö˜>Ê+Tvò¢¦è4`»9\y­ĞËÍ Á"m;dÇšóxIDq4¤Èã«„P¤‡z†ASõN–ªÄ5FˆàT,ıwÛ¡Ò\=(Ì…ç~<4»`© 4Á'x“á³¯ù=:âM¼gmIWvös¹¹ÉÌB±'}^©Ñ9Õ€ò
‰^İõİÃm$ë0•-ó^Ç&{	î¼ßíHŞğ.úŸoU+½?zŸ,‘ª>$wåw%	æL¸§f¿]¸ç<èhßsé‚ gÊöZ¯-™3$áqŠÏ9ïs×³¾3k©-S úÜ`ˆA7Û™‹>§¹EÃa±`±{ù%;çÃ I2x¾)¡ãä:;ÓøhÕ% ˆmæ`ğ±ÎWŸw˜ê @£A@H6»@œ{Î%“Û®as$I/ 9TÚøNònyê¡“©š…¦º&Ù*b~;5Åe·Õ¥“ëV§Rpk›ğ¯‚8ô!jVˆ*«À¹Ar1¯9iR%)‰w—dÒÌD¶‰Âm¸awå&ˆÃÎĞèŠõÄ4ky÷>ˆGãÒ/¡Óğ~ñ7íùD-6÷ş·½¨ÕiHn…z¶3ıï¨ïLä,]XBÓå¬À¦åß„ƒw^Ÿõ^%÷>Ï9ê­ÑIûrã/Tu'@×™ë{İ0 ¬Ø}®¡–ÈP™[ƒHRÿî¶ú²+Wê:¤x5“ö³™RD«Aš  wÈS+º5nwıŸ1Œ!°é„ˆ¨ğ­õ|ù+_²o,<ëA¬iÜ$o:Z"J¦o `¿ô¼
Ò…š úZ?ç
W¨¬}!ÖÏ ŠÖo!‰z^[ÿÕëì¡àdvd¼¹N¡GbR'ÑˆÕ_Àd­q#ëâ/ÌÄšHÊ»p£S3Øön´ [Ç`"å*& 
éQ+îÁù´d‹‡,L³18ˆ8Ò÷ñFåäUm ÙÜß³C!€o¿±’é•Á† ¾è!Wr!’G
²ªp¼ ŠÁ‰5h4äqƒ ¯ıEî(#SÏĞ¯Ü´,&¼œ©†=YC*Ù»g=õ¡¼&dN<á‰4ßŠwJ‰?‰S;²àì5ye4ªcÅ*Y¶ÕHUñNü9—Í9ïÈF¦:ìm|·›Ai-…i&Ã¸î Ôå£ş»»[ˆìsT
À•ÛØ|!;w6öú¾âÒ€ÊĞÙ´ô7Å€Oª´ŠüT*ùíM©˜(.~; [¯ò†ôKáÂÓõí;İ÷„ÍxœË^ìğ]Ô2öÖëÒçÉ.K3kMğ÷Ø<ğ˜ÌÒXô{‡mi‡qô­²Ø¢·Ú—é
ÔP3¤,\ìÛğ™ñªğ›Ys“¸-7ª
K53lB`@À•G$È¸ªªöã¢¿à±å¦×Îü@ûJûD?‰úå"ytÔ,¨ÀkÛ–Œ[¶Ó»„ï oDsÆ^×ö„dd§=VEd\µàã–Dó÷*ÉÃŠj¼%ãàÉ§3ÕbGŒùºÎ™¤à+»?¡áZÔ ?÷¼.9¥Õ!ÅÚ.œ«r„üTkv©dmÃù¶T€±˜mr!}ÙˆFÜ„=\Rp{Q¡|`º›ƒ›î¥bôÉ€0ÌÇÀuÚ6*É†0jVĞä ?À¾5•Š{|C$Ü&œ	›¡i>7ÛÂ]X'ë5§xtÅı~æ8&¥&O˜ŸMéIÉ£¾M<>O¬³¬3ş2?ô"•1Z\¢Q”Í^»Bû³;9cGİé¡êÉ©¸Yªï‰CŒ4½Ï ZB1Tğo’Yºe‰–b•Â%ÏZt‘s˜D¸²¬{Ş3àÂGP²ÓàXƒ·$Ô´ÃPÛMàuÂ•8ìÌU;ˆâp¾ÈE+;gE;‚x„¨©Ágc	º1XrïU^àØ.pCjk6ïÅ2£.ˆ?ÃŠTÌóõ¶+
;/zì®=¦±“1ScöEë•¡éò6RüêândqÕ Âp©Î$®5È©'nöÍƒ›ÆU¿«öŞ'øÁˆ“KšZøäáœkïë°VÉz¯|_ŸD>­ı”Ÿ«…Ö"½ƒ(Ş–|Ãÿt
¿û%<×BCf‚#dø—–jÔ	‰|°›Æ:†cÑB4,b³>ş].ÛßıÀïM .ÒkjÆıDg
7ZÛ¦Gä•K÷°]èÈ!ÑƒÀFé7Lì9oïÊôË ãüµšs¶`Ÿˆ¼Òè=ns\S~·82;k 68h¿y‘\{€jº™·V]v·ˆc½	%©3À2ÔØ¸£Ø®‡Se¥ñÎ9rõâş1îDÄû}sÒˆóo~sÆñ¼`“ÓóG©‰Š<Ç¯ÕÓê¨•LœıL@S‚ŞuÂRfÖrKPÚúÁI¸¥$ĞZïÆ5 Çœ•õ¶’—â.ä@•käó§G'¬@©á5üÙ¯q­ĞTŒÆZxÈÙvYÜÄÀ^ì•âiZí»1…Åi²Ñ7™¦h(b¾‡eï¶›ÙQi›Åª T‚©‰d˜ô=Ÿ(Œ4Ñ!úJq·¨ƒ—âÇú°kŠéôäüĞš~T½\ä-YÓ=a«òßhÖ Åƒü±qç•Üéî\;5K<ì—şç //{¥şx÷;ŞV5L^™ÁU-T¼KÃÁí¥&æé›^8šZÇ8êô—Fcú73ÑfêÌÂÔå%å
W‰»šVA“ Q¸ëÔ	ÔvÆV%v÷ı´8$ùkqy$¦í™^€D(”,d%®Iş_èHæ?úìˆ)² èë{<¤ÈµİéIf†~0lˆ*7¤ôÛ¾Ğ™‘JG±IuæS=^C¤úr'8k+úEÃ¢ÔÙ9ôe¤\,d:8{_Ñ|úd¬DÿÅ÷Ê%Aec	j´™|‡0éàê0ÉK}©I4¹kwqÏgm©à&ÎâcbfCÉQ³L;¼ç§¯´KCwÄİZô½*šrYı¾ó|krÏŞs×¯o9êT>²tXŸÍŞ(M8;Ä>2¼›ìm¬˜ÄÃÈ£)‹é©D3Ä‘
/6(›M7ôtŞN>ÌbU|{KAĞ¶t÷}N;ÕìI„4Áæ­í]ÅŒ,I Ó´Òkv©ãûy>´sã‘-¿TqšCÜšqÍövM(İi	ÛJ<¾¸ƒiŸÓøÜjOéFávEdü/_Ì:-KŸ¡H	Ü:	ĞIâLr2´Bm€4SÓ÷o•ÑpŠåîL/*j1¨ß?·é#Ó³ş?›İÁ¿Öïìæ†ñK6(Û	™]}Ó~LEIËù¹[¯Í
ò©Á’Mb cÄå/” ;w2Õk/>	g¸Ì$æ-{/D¥Ñ.wŸà£(3t(N‘µxåqœ¯ËÂd-ÓñmÁ±¸ŠFUGT¶¿±‘S¤·õN•ÔÕC·˜âˆ,ìâ‡a?÷µŸ¾ÓZ"çÿ¡üÏÕ¡sıÈœ˜:ŸoÃn®j[ÓÊŠ³†Yñ¬†I(.|]KÏÕMƒ»cÅ-œòÛ6Ì‘‡dkv İëìêã·$ö4Gµ¢ZG%ëtPíë©¢çE¾±“Ş?Ÿi¯på]¥«ªÅDµHİ¸…»²ÎìDÚ4ã^AÖ_¯HRşa’ÇıĞ
z’qßƒ€Ùu—s^áwOşFÈ…*Ø	½Çá47 Ñf$=F-xş—¼—ÁÏ8£™2|ùTZeiql*Ú]öâqLH;Ò0ÆÏZÑ¬Æõä8 r çvft”"`VõMŒ‹’¾¥ˆ¦&RªØ±’©R†
-×ŒÁKÀ€¥UXõ/J‹\ËÇšÆ¨O9p6Bå?İK~^"éR¢Æ’šøûò¥l;ô…ÍwÄoã¯°t=­ÇWÏ Ñ®«§àùÿâ¨P(s®Ãdi7iF ¹,FŞ£]ËìSìfgğ9%ğŠÉ	ˆâ 
¡,ıZŒµ,ª‘j"'çúUY¯Aï˜Ï\mÒm}ìvjõŒ6“},õÎ*ïÂˆ"ªˆpÜ{ğ¶CY’AÿÃôl•õT1¤SV2‰Ká^ğwI±`]2îòü?—÷­3êS†Hì€²†œoô 3{!“êÜÁÛà éÊ$VF¾*»çWÄ°Œa´­^úpáNtÜ´ ¼ï§Ùf%r_S³¼‘¶¼"ÎàyE“P×ğáèZŒ¬÷ÚcÒäh(ƒ^øßqÓïNwúE’)y‹ñkZë€º†ïğw¸0ºé:–/-w¿œ¨ƒ]¤œ<ğ=>TÉdŸ•$”s jË3†‘l–8mJƒî†é“¨Ş²İwÂï¦ÿ5€–ô×å{/ZXŒs!›’‰¨Ÿ–@·úµl‡7%,Í˜¿ˆÅBÀqÇ^ß ·b©ÃIPöâ{ `¬¿ZËcÊŸ8õLò©¼ûN-.¾£¯±:aú+Ì&)ë0`ÔÈz€ğÌÿ%
t )Xü/º‡§Õ+JvÑÕ
ùÒC(ë4¾ğ~Òõ‚yW>~i\ô–ÖVc—›8Ì¹§‹óF­+Æ^ÛÍ [ÍZ+=ğO\÷õ”ª!Ğó’²u*ö_sŠBşÑÙwğ'™w’ÿêfNDjmoà~J§qƒW„ø®«_B¥ÒQ?Så†q.ÔÈåşyÍ¯ÉnzÓ—óŒÉWL»«ç‡"$È˜Ö‚•êEÈ}9¸ØE¨2ægH\foW\Û	'™1EZÕåRn`‹o4Œry'oQØyG¥SÒHzç
™t—±ŠÉlÇ@eû1iÎğ`òóº«U È'×âö5Ãº¤ÍFq¯lƒQÚşPUñªz”$¡]ß½`É‡;ç© Fõ#®³½²Ä Ÿ<™©:í¶€ç È¿¨ß©LN¨5•¨¾‰Uç\hÅËWkEÕl¹ï´WC˜³?,R.“>}^tŸ_öæaœ‰–9¯ºûĞ²5[4<·èâ­p_ù—C@
ä{’î¯l§Àîdù:Šg¹[%d¼¤«E‰@ÖÎ/¹gJ‚óÁ=‡¤w¡ä$m‰>s(§C8–•àÌÀ¶àÆ“Øí`Ímí¶Q‰kvª@R±1m€2©|ÅóşUI)Ïº@—‘äH‚z©ia¤™¡ÄHúÔc—L+–>¬’×dÏ5p«„I}ôiôıŒ`,[Èl;“™©sn.‹„lcç­ö8²â°dûÆıÊBŠXßí,¯"Š
#B”Mpaâq–K÷şµt|¹­]]ñ‹)kù·:9ü Å`ÎruûæZü;b¶ƒ-=…ó4 bú îü&X{2<cı"{È÷ nÖ…$r¡—ã¹¦‚tşÚ8¸²›ô3\“íw)ç›6l›eœh±+Œ7Æó»Ö%|kĞvÕ«íí`.ÅÃ™Œü¸º\®Óàá0ŒÌ\H5h]µˆİñéjƒi…ª"<xÿ ¡ê±2Òwe˜rê<ï'…¡¡¦€äÖõ¦°wü$l)²m¯;÷aÊŞhÅÊfŠ§VÉGŸ>{ˆù°}¢mtÜW³>-şMLŸÅú?±P[èrøMÆÇ‰Ÿs°¥§‹½†×Ç”«µşTC·±æ-'+»†•ÇIZµ±´«&—§|d®=™ìş9)dtá®Ú!êù¶,9±$VÒ Šû4í}g¢üÆÁ=§,(qKœÇ¤	åuJıtSÛ3F0À]iÄ&?Q¶·ûÄÙnÆ›sQ°Ïİã`:FËàÓ·sIÉÍø‘ì°­P”Ê¬–U0¡/ô/ÂC\tÀy»baÆßÀ5ÍşC-˜d¾Š¢6L¦öç—wÿ,úíWÖªg7“é²õEáSÌáàmÙ¦2œÛÓÒx`M!ş²÷¢K½WÀE~ÊOÙI¦fIÚıa¤_­#Wä>À-.ÿ°V,†8ÂaeÂrŠ´.ÉÖP†.Ö£ +z	°Ø¢‡XGeDeH«ue[ÁÚ7R7¼n vìG›„iy© ÇİkIî¾@ô—-å:©ºåÅ5;›MFd¥zŠ3Ê±ıtš¾fôª-w ÊU\‚Véè]3V´±a—³?³k²êø#¿{Ü)éC]†XzãXC”(±<w­ÌN>@x`8è—b‰s‘¸§ú£ñ$!»ã%ì¯¶eTt©íqOôèã1—üÔ,‡W‹ö«9Š®Œ†¹Ğ²ĞggœŒëg‘~S_EÑªfsO‘¤)ø„b±æuÆí£gåğ[€ "Š?ÿ"¤%ÀfyAB*ûÑÓ‡ÖÖ‹¼Ïık :V3%'íkò}q¦Ú¬ï³zeæßÈ9Eh°”}·äÂİqğtP³ıé]–O3×/óß·QÆä(‡•Æs®Ö:ií=ZªYË¤o*$>ÔB"~ÃLš,(~ÎšÄ„à( hÀe>îñ…Kü¶”eb|¿¸;Dúf'vŒ]Á‘*†È¾©x”/îæÙOÑ†qlgtû»ZšÛ%E¶ ¦.×Ï˜èB¦/=<eÁø†ƒ†y+·6B=^©•¤M
ù„` jÂ9"|Sé«nán¯-‚ğ ¥W–ÊM!TQ5Ñ(+‡T6“K¯—½“!”¥.['¢Li^ÁC¸FW™½ lÒ'ÚGßSh!yvú²#d˜Û#¬&º¢éÀ²Œ–“$i2DtªSÎmÏŒÄÏĞ«f~b!ã6ÀNíub†–Alxü®3°Çj|pK‹ßLf¿”& P‚¹f»ùh.y+e¢øÍ)¢$pTG’‡r{Œ «Õ“èéeÑj	ÊÏ¿Š­œé-*Ö
ÿ,İp~3»CÛï××…1Ôö–·	ã:V‰AšAµŒ† _G#ß  »‡åLlŞH'Êro½n8«‘æshğYA‘ûÚ<x†‚wdŸãy*©oÇ]x’”¸˜ÆËİ<[ev¤ÆnC55yiûÓP¥«Æ²WdŸéãDªŸn3zìœİ€ùÅ¤¶g&“Ç%_«=rÍÛàVÀZ¦¨cÄmSd%~ÊÏP[¬®å Ÿ¨d€uĞü¾®9&É0^Àÿ·eo0! "SÑ·@2¼)çdC rß…şß"Øf.İW)«„Ô„ ˜:ÕQ¸˜è@ğ¬“U¦hûÃ¨DP+}wËrÂ¬ÇH›œÆBŞTna"ëÑ"Zª‹4´ì&ÀE¦(XÔCÀ6­ÁXí.ƒ´Äbğš]y¢øeÒ§iŸ0×bÖÆHsIÊqDZìÃ^©(1À Öµ¥9Ùÿ¼œªsŞ²iÈ–oZ‚˜êÖ
Æ¾)ßæ]j„ZTUõd't@–?ÿ» ¹§æÓäÆ\e+²d^Îg^‹Òõhå¦'Ï‘P"“¬1—0l
v4Eì“ãÏÚU^Ò‹/p5üíéà©Î˜–®;JF$FQ­½#6Õr…êCbÄ{ Ã¸£Ş\/AÏøISÌmâ«^uık4>ƒ8øæÎ)½µ Î a²jí2(½»wqÒjZ[à®«j&-^ºñTĞ*@Şá¬ßÈå!ˆœ†kÁ¥UW£ÒÌ}ğ>àÀ c¬^<^ÄÓ{Î!Ó«°íşXŒÏ¬¬SèN¢R†÷à`Ş6Ñ 9û÷µèL-_©§}ÓK¢¸”0áŞg"‰WùPz$çLK!¿›A+¼¾H¼N#¬±bp—î¾¥œğMfF•ëZFÄØûÅ«wdQ‰ifÀ´-àróƒkÃtÇìu¢#2*„ËüïQ.˜î:aƒ1z„	ÚÁşãóVv¸Né–d@¨`îö¼ûBG9XÁiŒùÑK”Œ´ùÜ	^XÓ¼Í±„iˆ·~Y7…A5aiäÁ¨ŠŒW]ĞDÆõr˜KJÔô¾Uë°KoÁşÖîÍ¬İ$JäÄ¦lŒnîk“@)§ºHSneu4¨dª©-œ›\)wî¾¢ÓöÍ™ò¦P‰®WO}x„BŞÍ—üIaeÒ½O¹Ê)ùÁ¬4(ÁH‹sµÌÏ2ûàÂTæ:§ÇşÅ’S "u?¹H;!üüÑ}¯¥h-ú±ŸîåÊ‚xÑ€S=Òb•úz«qmiÉMÓDsÈºœ1¡£fó¼öšFİáHÔ`ö—#,Ñh¸òNÁW<OD§ckå…FĞ	é-»MØâ;õ;±Òº‹1Kàô+ß3N‘âh3ûF–«™ô oØk`XEsÔ ¥•]Û,Pæ&Lı­ê¯ÖÆY}Š
ş²Ló§ÌDØí7Cb¼ĞÈFTf²|ÎÄ¹í}­NJŒXo-û=ŞMÕ|§ˆÅ>şŠ9õ#Ç_ª=tß°>Ùxæ)å\`ù¼wd	0Ò¶mGv×·D¤†fä–.ˆ²°……¯zB¡VâåL¢‰áyµß1üìJÄ|ÓZRAÅÍ-X
ÅÍòGI~ÙaÈï^pÜ ²_=×|Çóhà¯z&aÖØqöÅä)R ‰¢ùh‰»Vñp9…tD`æÚo{ª-û»ÿ:˜6‰ÓÙ„W*1!!3µá6gFr½slÛÌx“AÄ½vAIr]vFX-*Çaî¥Òù’<úÇq¸ÂUTÙ±´(³
Kdçô›Ğ+UVÜ›ì³K¼ĞpòŞ†sZ©9Gü”İ´w1³à‘³÷lÕEf…8À«{?x­ZÚ3Nüeïa0˜ñ>ƒIìG8àzNc6 ëeÍ‰^YhÍÜŸõíâL³Š´÷]	~‰Nd´6ûF¨u,†ÆÛºw³¦¥ ¢ŞãÜ¾åÀçÍ[˜4
ltF¿1ÑíiŒ×h4€o É5stR´|­¾j{W§³Y³2„qü4ï"\á@Šÿu Sê7˜S@öäh}LÂÅİNèõíDd:î)j1·hì² ¨zˆ­<Nøª†‰6p¹•4®œŠ­?ÊíâçĞ(´dG¿š²Àn÷¯ØLfÒx7kcÔŒjNy¦ãğõr$İéùe0Ü‰xì!§¿Å\Î.u>#ã›!N¬õ
Óİ»‡#ÖUÃNæÔAZ¶G.jõš{Øèµ'f}O%ME'Î8!Ú…v7VA?Éæár@ñ #9éº	‘m‹U[	Ó›ËešÃ€±—™–Èõ£â¾;Å}Q†Â{x¨Ï´ÜÃ)û~¾È®"Ùš‹XÑ™’…Ò)n’IYwm’íĞÍBû9`Ñú,)B‹WL‹¨nÔ¦øm €adIRÔ\ïÌ¶V»S(Šƒ”QÒñ³¬J™<q³?TmŒ‰Ñë’*…Ïñš¥tG…:ø7$M	üyØ¼â+q‡"±#ç6¶İ$ä˜‚hè–ùäÛâñ¢€1¢zZiÉ²¢tõ˜ÉŠ¢°şRúùÙ"Jšq7	-5ZÀoÆ¿R"j?81†F¢a‡Ï˜—î¹ıé…¶tEˆ(•—,…sÉĞ#!©¾bì„ò>BJ«´-—
 Ÿ7›„%‘8¹¾èÂÊçŒ•íè˜ÒSùËÕSÍm?Âñèû""şğnÑãñâ%ºà‹7.(ë-–MÎ_M™üØgç9<º&VDÂ¤m­Ÿ	>ğÏÈyàkàØnäDiG}É+¯5BymÉ•u”Mjğx'ÖÔê[qhy¦mâÑ­®‚Ú!‘Ák–iÎC;óØÍ-ö[¨ø~“oj.‰ªwÌ2‰ây°¤ù	ÕùãĞN¨”p63s]œK¶FÂoÍù*ˆâÅŞJÁÈã;¼ÈÓĞ¥pJÌÆP§Ù®ÎÊ£;m¹û¿ÈÜ× z‹U:¸¢+Ü~ÇõoÈÏĞí7[Ç­çG”‚¢5¨¸áñ%“¼e1JéZÓ4H­T”á¾?× qwÕÛĞ€fb:
|Æí/à  ARöãÙ-ÑòŞ{	“hÏî=0;'£ØU&Ï½Å¶´¬£Æ7çª=9¤ÍÍÚ¬ĞÅ$"vóÁ§={ä}RÚ¨çñÎisÇ|Ff¯EÎ@w¿¥ÄGş[`½Vnä(ÂZãÂEÍÂîˆ.{
Ÿ ¢²¹uÎ9`½ûú~/­²7…$¬Ï¡¢©¹o¬é4ÈiÖ¥8§zĞVã‚'Z†“ô>-_ ¿.—úæ!§“Y]àä4Õ“É´m„„ôşû.Ö`!TàÌ×ÒÏê+Õ÷ó/i…lËı*W¾>`¢«9{CÜR¤¹Âñ¤
Sr­fLü´ù/sé=*HXíÁ¨Ê˜GGmÅEa?Èq;WÙ|V^æPÖ+
ÜêÅ	^uİ‚XÙ«2‰|Às½"_!bªK¡Ìù%„Ú×cYDû$Zmá¶²sÒÎÄ9m_¯G »P#¬†‚#÷MÈXa6W
É¹Pªz›g†‹‘M½
6‘B7:Şn!e€¢ˆQRÈñ`æ‡DJQA¥—É`áÍ‰ø€ÄèoS’¾Vâ‹“daO–ËŸ„™’qqìYcØš}GV¸¶æXûÈÅ‘ßëıYÂ0µlò$B±óÂ¸¢ßÄ¸®™
]Kú†'üûÏæ‡“™ìÙd¾z#”Ì|¹XºBšpª;1š*[E66y+°YÔú•ËZSŸé½pÂOJH^~KÓÀR„(:öÄê„Š?—Ğ˜Ê“TQ¾L9ÓÒëÑ€¶eˆC°Æ3)XEÉ.ÛÇbZ¬•Ë"÷î1ëû‹J$‹%Úa#è©¡·Øiÿï	¼š)õ–Væø§ÕÃÌ:êoÄ$u‹£j¥Îh§U…añî¬’hºEåÏÜ¶¿„K¯»7|	m¤úœÄôP¸ñ–;Òó±Çç÷ñÊYÍv-ZÖ6W~²©ÊiêªUvĞSïŞqÔˆrk@ÎïQ¯AáÄÔ%6è—ÇÄ%±c†ÈúóïxŸ£L™~C9cé–Ûƒ
îE…*iVbêAáâdÿ©ewĞçëvˆW¿è¥¹Êz7&Ü%PWÑ}¹=jà¾
‰agRÕğ[Ï8}g½İry×íı.8êuÊŸºAQd7¯;eP˜v½CÛ!Õ h„º·_:xÿTãk%™š*ÿ*šC¼á™œ‰æy‡˜ì¡©œ´)Á:m² v	<ì¿óà¶ÌÑ•³âX¢'=¡ë¾‰ÈÖ›d¤ßÕíMÌRêRT4Wv"Í]6×í–Ù®«İ4,#©N.øÌ![¸?|§İvÌISXO7	<(ôB¶»Ê€Oî¨uà¢¥YìíyÊ÷áo€p-ÉƒI¹AÈ,,UäO4øèomâ¡Eñ$_ÅüZĞˆÕZïœÌÍ§I…\˜à[‹Ó€Yœµ ïÏœ!‡\<yf;Ú*Õu›k.±¶?àÕ›_?ˆYò¹|¦Ò£š+ñ»œåØ‡ñu.sd3…Ó÷Ôgõ<ñT)îøÂMdOH“P}…ƒôÂ.ÈÜ>¹>Ü‡Âû¢6cÚdÙÊŞ/êj,¼ŞÚ!hğ*ºz ’§â½A‘M‰Ó3ìr-!Dë­É2„ê@ˆ$K3ìµó©»l/ÍÀâşfĞ?~vV\.yoEE_¬¹å˜uğrZ=±“O[û”Zú¦“Ø1‘©2
ïïvTJxiz
<Ì¸¾7{ƒõ¢vÿ4óØ¢Áµ2ãq@‘ubp9–¬›TÌ¬$Ü¢± êüu 7Úq±†õğû:T„Y2“J$aqœ}İnŒÊ?½ª$ûy&¾åÆæãRª-Y÷-[5_™›gá‚uµx¨¼yK *éÔ*^]Ì†ÕìÌ3·ş¢‹Œˆ9Äƒ*µ9ÅKO]§'ÖB¦
¶}»n.Óö>7ÔBaV+,Å¦l(Ûîsæ/L¬×ª·dÙ”yÒ‹º>b¬äfêªås÷µœi‚¶:Ç¼ã ı’ÿ\w(<âMr°+L×ïĞ,K 6ş…n4p5ãŠ›í¹gl¡gP«ıíš‘İşoµ{WÒî„ ú»{gXÀ¼!¢GËc©ÔÓF§Íd[D‹]T9=ÄºdÁ@ÚV¡ğ¿ƒÔâ¿nÂÎ÷xÃFO…cãa€Ÿ• o
4ÄS¶,7KVc¤ë¹³<6q¹>ŒÕ%uB	y‘í{} DhOnÎĞoÎO¥ÒM€ø@KÃŒ¦ùÑ²L sÉûw4¼á€ÃRŒ§ã-Q¥ë{t>±ùOfœ’PÜJ¨!BİíR¤ÊE"˜oïp™ò˜»H<U¾` ÏçÚE¢İh¬~I·{€*3a2#Ü@¯	ÊºÆ1¹&Æe#ôi¼óºáƒ{á@äv v4Z½zá•[<µ
“TÛxÆ@¡¯Ë£…ÔKÛÃâ¶Iºu³]Éôu„,ıHëøëy"U1¥oiå…†ÎüøsÈ½#ë•%3µ H‰kËúé@Õ¥¸òºãšâ+YÒ®mÇkg™QÕÜj]èäk{.ÂâX…Bî®RÑ@B`¸Y‘N#œ\İ™ Øl,ºï1×Ra§2L)şà‰ĞŒ.Ì,3fÁÛwq#¿Ø˜šI´_ï®
÷vOZÆÜ¶rö¥† §!3y±ÙO¡W†¨“0ùüæt3C6¾ä¦T@òL\š…ùŠN8U¢#tpû9Ğ¡µn·­È¶†Ù¸œ€4zä Â8Ë¥§cwÜx
V	ˆL/ŸÜ|n·š¥SU–M
…­/ø«R³›Ää£GIº’mr=Kve¦od³>	 2{Ï-E#«§ş‚ğ!twÔÑGêSO
%–yº{>¨Ìn{¬X†¼Öîİ|›—ƒxN__ÈÖÏ3q¢>„&	…XäçD`„-Şß?yZj€â§<¬R\"ïY¶JÇó/½$-'á–¥Äƒ±eˆœÊ¡÷P-æ„2h™_M¢:%Ï\äìw½Z,,Ø †g¨¿š[¡.Û~Œ×öM¤T)XÃ
@9Û¦2i~VºØa#7ÛnZãxTÌ­«ß·æeX¥g6Ôg£¡òYˆNÈîÚO
ƒ(ÙÕ{¤‡ÔìşĞ»TŞ-';~„û÷YÇc¤tôèv/;˜š¤N¬Z·+„vœëó'y©Æ/¤İ¿¥6¿¤çÉÚ·wºH-c>|Ûí#ˆ&1íMíD
B-1D1u¢Œ0ÛŸóg¸œÀ¼m,=oy¦úÇØPtÉZòü[øÌ*õRlgã?¡œ®Tó”„uF$3#DËä)´“Û§·|Y:ß#æa³!né¿ŠÍí‹‘:êÑÈÎ_©Á•æ¢,îx€À†r³¾^M¢{Ì£ùAM"²ü›<ì¹š4Ù°¬XÇÛ‰îöü á1Tìsúæ;‚µ‰Š$æááC<_99L'ıJjÏ›şƒÓîÉOªŠ?I)!WYí‚%9‡+Ä¶ÉtVÜ12F÷fæ:óvTcîyağ;,Ò‘ ß	)ç‚§ıC¯‡'¨Æì³è¥Öá„ìˆˆ£i¦‘Y¤»
XÈöâáÚ’jªñGÿëÂ×z E£›Rİñá÷Ş•Ù¿ Ô”æíïşÓ_Õ,»Xé±^Œj³¦åŒóŒ3à×gÖ›PDm}N‡ŸøÏ‹¯+{Ò›Û9¯Q2Q¥JÈ?úx ¶!QBØÕ{ûk¦m‡5/¶á¥aìªeC(r"—‚Ì~	†¡)€Õ
=Qí–”¾)GRül'kFj~QÁ¼M~V6w'ªÍEÑ·rÛÉµÚ=Õ'5³p´ÍÕ‘7óa¸|_€ºNû'›Ë(›zï¨YB‘èm7¿!„ ØNCM£ú6=zº[ÏpLg¯´¨7ç„r<ºx{ÁtfW·ÊNˆ,Ñd«+â‰(ì‘x:’û÷}s/g*ë‚›×säŸEèåİáŞœüÒÜğñãT¸§É{pùæ_‰?d9Át¹EèNhEÑWÑõÜ7í0øÍ^ò‰/Úš„÷å<B_È3©Q]gôTS:eÓ¥«É·4(üœìÉoİëµyló    -b”7nw¶ éÍ€0ÌˆÅ±Ägû    YZ