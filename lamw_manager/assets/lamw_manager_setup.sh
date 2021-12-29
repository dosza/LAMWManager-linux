#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2930544849"
MD5="1dc3e867e991b70c10f6a2eceb516561"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25596"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Wed Dec 29 00:05:32 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿc¹] ¼}•À1Dd]‡Á›PætİDõ#âdÓÓNØq£ü,{wœåQµwæóÙZñQ“D$ÂîÆ†­àº1Ì{É›&ï”Š•4yÂëù)®å u1Yöêÿ¥dWWiÏ±UÒXobSb2ºŠâŞ.4ñÎ‚ı·$$µ6*¦™};Y|±“›¹L^—GqÅk™’Ö¢No~ãÓV¢éÔöÔÜÒïè”@úiYñ¤‹\Z7?†h™™Ëšë­˜}†…ãĞ.ûQ£ÓO[šÕ§ÿ»)ëÏëóWcøÆeÀã'Ãn-ÿ^³C$Ï¢ÙÏˆ7¤dR»¢-é
‰FKñEˆB„fúãSÉƒ^Íş·z:0GÏ¯ºáf«²9MşšàíPHœ7ºS9cWªj†¡ZMG
¤/}ßÊ_5æ¯Õ:pıµ ^Â”ûømİiØç/+ÀÖ,Sk½ËÕ¶,z®‚hEîûßQ|ÓOİi¾&Õ‘âyY¼§zàGÒ°C;Ï2ØÄ¦˜ÒüÏÁZq Î/û÷E¯¡G²İ†R„¹œ0ŞüÙµ,c|=í}:Zœn)¥<úEZ™Q´æ„ÈSe=']yBŞo€ÂÚ™m†Ë(°¸†£âö' 8ÑèNñìÂsr$o–xøC	;ô{:—+£CP­ãµUhŞ‰”J¬§¸ÀºÇu]±úE.u³‰¯É îšæ%“4)|?±Ù<FIÃæJ%óä˜|øR*',í„äÿ?3²×’´–#•¬Lrşñé+,;L›Y¢S€Î’u°3¦>ßÁ×z´,ø•^“éq{.nhA ¿_CDæV¤IĞ0VgûMl¸8á —·ØLû"¿Ôı
t.ô¯ÿ:Œû±ÏÚå ¸ˆ`DÒõ²›Ä¸åğ~µ<ò)$-Í+øˆõ©Tğ[ß±`IJ€ÀÚ »2Úä¡ú8ÜS,A	Ë U•¨Ah.ê.Ú2MKŞ·bP9}¬W“•?:˜‡qSäŠüßí].F€oÂñó‘°dÚ²¬Sé¸ü4lü,ÑI°!IbL)Q¿¶'S€ÌÇ&8Ó¯ª²VøĞZôçI¸¢o#%Fº¡$£éÚÍz•eÓ@K–&EOYdR•eÁGYå3Vš§÷×2PïôÄå€':a'5[ZË×°r¶ŒÍ›ÎJ‰¼‰vº»÷¤ÿ¦¾Qö¦ôÅÜ&€üDƒÜú$\>÷•2>»œ Z‰*Œ·£%$HÑ‘“FsŠrHCÔ]ÃLMcd›o_Ç¶Vğ„šNµxú;Î²!r‹t«L.™€Ó¥ÀçòÍk˜¤¬h~@ùŠ(tD^CúGÂ‹\Äú%T ˆŒ8$,éş®01+ëïı+o(j-4ş¸$€ßå§‡°"ş%Æ]8Lˆ{èÄ³SDõ¯…ëIè¡ßmğÌ£8ÚÛC¶èíŒM·ÕBÊfÕ¸mıi¿]±vNÔ–ø-^9óÛdÜq:ô˜5ç5Œ‘H­ˆ»b<EzĞÚ>Â1_ø–¸G:òVMQÔ„ÆÜ¼—µ#%{7é~¹Äşş©ïLËF@™Å‡mK6œ¬`Y£é°QW'•óT®e"î»¯iîw369æVI¥|¤Â bFÖ€êá‚€B•ÅI»"ŒÆÅ"NÑŞ¢=†CîÍÖÒœïÃ“ÄèNæä+µpš‡©j()©Î©ö/¼~ˆõmTw×†!E…tóá7YP¶›YíMN·)HsÈ·™š€”J\R¬„0ã~’ßÀ®]ÎƒM3°e…‰…nYßÁºÁ—Kw
ÏPrÄi»©×İ’Jã°¨nñP£Ğ¥¦$'˜ÈĞÙÌÌÍÌÊf›ªñIšÒ™Ñş&º$y¡¯ÛßûvŸR£}Ñ»Z›–*ux }#2“0I‡ÅÊºP×£FàÚbÈ€Ó¥R‰ù‰œ0?GW
<)
f“×ş—®µĞLqò
hgÅFğ/Cñ*Z
WznAıÃÎÅ[Ú*P†İYÍaè9¹S¨µÇYŠd^†·%Ü/ªƒDMf‚tíGèÿ)e¾“y9‹PLÜíîp@Bü
Å±ïÿ¨pjnV(ğ>3µB“1Ä†
C+½#wQ*ô}U/›hùgqŒã‡3>SÏª/¹#%öcÇ_:aµió7µGºb&?MÒ*yíq#ŠU#º³ “½äQŸSS–‹ç}*È7ªº€óÈ¤ğ§›‰e‡JÌ¬÷Mc°•m!´®TŒğ”NZ³ÛC¨ŸÀF+uIÂ¬«÷T$DÜGGy§$Ş]3‡ãÅ9t3hÛ›j§®ÍL	¥]\ï÷úòªƒc}n=ûàßPïtÓØ0ıî‡Óû0©ü4^(ÄMù÷à\Ph€uô°fìø­u£¶9R-›jl@µ¬3ì&:Æ†£´[«ŒLJÛ¦D?v[ïÿÄÒ-üb-"%³pÏ³Ï¨ˆ<(|âÜ—˜FU¨hHö‚ñÌV¦*M¸†6“÷N4P¥Å§óaÅìåéûVEşÍtÚ1%¤£pĞÅ£aÔô;Ùªb¥=W‰¹ÅdF-­/xõ×”3Ö¦StEç0+0îvgÊBıìt0o„PŸ¹«/§R d:*7ëÇ!´;î¨MVR&ÆÊêé%ƒ.ó‡Àô=¤h¹v˜“*jU•AZ›h=ªê[ë“ \SWŠ!Ó¸8ÇÛmˆUıK@†$-²q¼
Gq°NÇµb~ÏşÇ9“«ªd>äÀ]bí©ÖÑ\¼sÃD)Ù©à˜
RJ/q^1û:®´–úoûğ¯ãEòsªİjú2L~Å^`/VVİ]NùÙ¹â xøş’ˆ™0h+jscTß:¤F^ÑV·G¹f!P>Ù C0µdú¿¦]ÊqvS$qYı~¿ÿƒÂ§u¦>š˜ûC,Ñğ—·ÊFsärí'#ŠåŒ6y-%ù¥y$Aº‚NR¿°_åËğ·dœºlVúG„8Şmç³fn¯ ô®•P›ïD…côMÔeĞWÙ©[~î"nşaäsñç!±0Ş ë[Şc[¾¥3æÏÌ¸ [ó9'äW¤Û•ÛÿÕHIñ‚4£%ªÀVEr}hDŸ,q_UæEM«ôä,#2
1¬Ûç@‹æ)À„7™>KqÜ&)æfÏ+ÀÂïe°½fj=¨´µDpp‰ÚğfÖÒ‹™@©çòB[ˆê<k¡gaÒ£.¢²|Å4¶ÖmÏ+f%FôCÎ„úª~y`sÔ®'ÿe2éÑ;>¨b¿åEƒ]?2w„Y]êÊéâm5®ÖYpû@/HBCÿÎå«P‘G§ï™O†áb	DÈ `
À»„†2‰ÏCçŠ™8'ï­rSxåßı÷
—é2OB]ÊŸã”€$t'ú[>5ªşp„U"T óà¼ÅE{Úq0Í]'„­’g?’ŒıÆ.¿J±Œ³+>yrğàpxö½É•šìŞ×ŸÆôÚ,’İæ*Ñ.Ş<&~Å©HŸ†>ÕwäêpU;Ğ*Ç{–Z@]pDùĞŸ¬åå¢oõögx¤gµbdo„_gª6/;ø%÷ŸZªÂ±–r§¹>Ş¾w{ˆG€€ìÊ=g›òØÉDjé¼şã|ÕxL„qÂ›9 Şv%¼0QNÒsŞË¶›ğƒ=(‘z¹ğ`q“PT®wI +5v“Rş8^nqKªøıÒt‰,ğ`;ø…#V½,³cs–tî«·q:ŠÙo· Dİ÷@ÜXæ UTë—¬YûÏÌmC 3ÔêÛØ|ú&†Fë!±³É÷Dº?Ñn=dï+ÍbÏ
ª´‹f}ùö#ƒ=d]9L‰eÊ™†J¯ÀhzÅŸÑã‡*–{¼ÌWiø•,7Ì“Çè’ì¹6¦J²İy(*æLjûï}4 s3'CşKFÕÌ5ö’?‹´Ò{,Fp£î‰	¾Ù8ƒ5©U33¨GC‚ûÒÏh ÕûâU•Ä˜{'htTœò~[8|v_wç ×l¯5
íäS Î/ÌÚp÷YPéÆnÕÚE¡}sıi©([¨Øf[ùé¶f`ëŞ-–\NÏ%»¥lºJœÔêŸÎÚkêPÜú^&gD®;w2t»™
=kY¯T²äººÁ°»ùv‹çä¹‹¤Ïã»Ş·àjršÑ÷£–ÎqÏÇ¸Ç?Ö¬ĞzR¹à;²E#ÕyüuÌŸxQÅ?~$„¯¡-¤–=¿v£6µíêõ&®•ÔPÒ™WE@]—3í’w¥‹¡æ½”ácİò@@m,ØåŞŒŠÿÇ‚\î —ßy«èEC£g±fãµ2ïkMå—eS	â3‰d%¡jÃZl½ÇBÀgûù°)lĞvOÙ3;‡×|Îá¼}Lèİ¾Å§ñ¤ˆùûì÷ô¬ş}ø»Ø¼àEîèVóË:ç^"wFÙgø²"ßaccP€( R€ëÔ€BBbfS?·X*…Ô+6¯y"" -E_îš<ˆa…c­ùWÖ £æğû )è•¶;[­Ë8e
×Ÿ¹ß{4[__üÉÃÙ‚Í–CÎ¶Ÿ{>ny¾Ò¢”e$ ‰Úşl•lOVf¶2héš‚VÜøû^oõ¼£U9×˜ËWŠó…!-M6¼t b|GJÀhz¢@·Œò%>
Ş™X‚¸µï¥/Eà‰¨5À
bY[±,Äæ³œU5 mª&HõºoAScaª3ıI.¸i³<…Ğà}MÓA»ŠÒĞfkzÍŠıéo3y¤Òmm×z‚xŞúc‰8K—3îš`‘ îÃäK)nƒ> 04åÚ¢ cö95uÊNÔªŒrpšìñ­æpYÕ
ÖÒT4¹£÷¤¹s¶ñT4—«Ø¹º`-­E“!õØA¢ÿÜú ‰œB®¼ ,avTÂÆÂï…ì‘ì)nkÆ<Á±Öœ[¡Ô_iSw€pKpßıºCš/úŒd®ÑD¡Öà5NoÏĞ{[k‚0u¤Ø¯KåøCv<É.:‚Qö±ğ-ÏbP¢Ä¦6pIqleguåUw¶[ÆrûK%¨Ë„	:µËÁf†Âï˜óqåëvNŞ6lN²‘Æí©ÿ‡yØûküàÉÜ0Êçº&}IGÙ@Q•ãÜE¼øã†ò•« 5Ü6¦`ñÒ)íòU™²Ør&jâvSºµ³5ÁòïBp¢ÖÙ[À§.Ã‹	@\·rtW¯:õù¶7ü©¯ÛW¨ÓkqT‡î¼ë»m\ƒZŸ`=Ü3ñÅLïç[âƒÿ0¾P7×¥T¨ 9U›Ã‰vs‹üURŸ+óÁª  „rÍ¿º „ˆ>s¯Èi½b¤Û®İ×³·RÏmÄµÌCRiZThfi±(óg¬wóßáS«»zt‹nÔ¤1}ö|¶¬ÉƒlõÛm`§ÿ±ŞM‹J[Âàjø¡aÊ¿¥Wc®"G¤%ùqù‚k˜ëıÃâÜŒÛ0ßI°Úl„tËôAr ),ğg\÷z¤¼ó­íQˆ2!!VÁc!Š‹F{dqo´cğÀ?êSr÷‰Qè¦}ã¥J¬…ÿF™¤IJ¾ªâ[Ì0Óøº3³4Î#ÿ5òûâªkùOïAŠ
„¦„r¬›63†Ë¤Q®sPi_ã5¹ã.}úØZ×h1[´aÕaÿgAh0Qˆô "›
ïİ›B`{:ÅßJ£n Ò) wøSŸ)hŒŸçRn¸æ¼]]¡¬zíX—1w³¹ò¬…åºnzx¡!Ü†ª’ÓCE›§Ù»ïº›§)`Œız4`íû"1´/\ŠEÏ„QÉx(ÕÕ>ºJÔ„\ ¯a’@âN–‰qèÍ‡IFEZ”HiFÊY$$A”ƒ¸^¦	”³=Ğ:aÆÊÕà«àÒj3_zôs¼Z‡™ ô‘3˜¼<¹jã¸PN¾í°Ó¾'/ĞÓ+fjiÊ\|LJ BL¾»Öå~q¨µ8 íè¹"ØVp´nÕğì9‡
N¿Ù@B5&.ƒ®[¶< H?SNÒg¿ Ç	mwM4èíEêõ±ó0)Úğß<Ó©û5Ù*ğ~)¦ÿVøº»ÅêĞî.îOFK3²&ãˆJú—?{­”Ë€í°/ı>õW?"à°N™é•­Æn~³¡öRMÃgª-H!óózê-3(5WÛ1¡=DÏ2¾å]sÌw#(ubDY¤áz–lüëğ¡ÂşEÈ€´°ÕôëG@Bà½.4Èy–ï‹9R"åèÈ§«gTh]¨ş]»(åbğ‹ş?$åiƒÖc#CÏVÒ¨Î]¿ ê	¡ªå7Üš!gÈŠb¾³»>ÿ­GútÂe£eê|8 E"Ò‚üÿjpÕüKÜÚÉ˜‚úüºçşßıQßO:"y°ÿzeÅÒzN¿¡åò´3÷hÔrûäI™`œáeÖ+0‡GÒOyk”x®yáôxn:úNÁ†Jß;RelæJNÓ×Ûœ™êİrKğš\½OQŠ‚ONş—¹„1î˜hT67‰ØùX‚ˆQ¼ O?A__4&·mæ6¿€OŒMu«2Å—ÆcëÊù-±*®¡NHçº±RÏóNRˆ“‚ãoÉg_jÇşËÙ'RÛg&Ë“Ñİ9)ÑjníS;A¡©A%Á±^>‡]ú¢#³¾L=t¹Æÿ'’"áGó»ˆWmJ„*æZ%úgN{,,Ë›ŞÈ±S²ºüoÊÑDo4?Yã¬6`m‚¶¸$‡ºäc¥³d5d¾İ¡šfK×¿Wj<5ÿq8Ê¬„Cï	f¦T~Û†™PE3Ü—F*>Ì›–Öí6êÂ¥Ø ) >a)ßƒşHQ5ÓKxî¬bMÉSŠbóØ”³G}Ø.šÙşw¿(¶Ä"k`!v.V¢7‡9‚½õ‡ÑV%‚Å­és:£ø_››¸ÅClœz(!F¯9Z’Ö1ú¤Pñî/eêôßØÛ=-`á88qLİ_õ/»õìøÊ‡»³lêµbjMtÂ?åòµLÔtØh<·ÀÙ•Ÿc&//x iŞ Sƒ«GÛù–ï›4Àƒ{A™N#ùmô$½|à9Ã&;Œ¬4u]“ËªÅ›Âòÿ@ìA|Ã²}¬EvÏ‹4¨ZÁ$ 3NpŠóW÷Éê‡ø‰G·ìôDU'³ç©´˜û² ujµ‘3>‹ñWë#‰¶7áÁZÌÆ”gõõ,RQ¸
¨Ü7¯¢p¡S«‚†¬¿-Ñ´’VZğ×r ¨óÍJ½­8üœ`à¿“é^ºAu=Ä­‰Ãø³Óö¤ûûn–UúPÕ:¤úüæP„su¸[¢£éz{Ÿ&œ¡¼‰ÈGbÍ˜ÓÙı7İÒèÁEú¶«ïıîêÿÑ"!qb¢ÅÙ ‹T T;\wî`­ö›Ù!kùLPÓ»p¦U{)Tı±]ôy_[’T4ºï®by PêÑøR)	Ã&mÊ+	¢Î—°XafMÜÁÓ,Øó÷mV6`{yU-BøhÈmÔõQ„t	N)b¹œ$×›¼‚?L™ ±û(’QwÿóA/øª|£ÂÔè4GbMğ¤º{ä\Èœm0EŞë5ÊRÏkÇq‚bË¢öñì=9Êˆ/…S–ĞvX—RmOkµíôiĞˆ½HYã7BGÇûqÁ
fØ,ƒÃ\¿ì4³çp	À)è'ÑÌ8G{géK°{æfÀS÷¥ğ™û“ƒÓ8øçÑD2¨ØØ‘+„<wIßşf/¤ºê6h|úS(5/kÚÊòÌôv­Îx¼nQ*6ÎíÅ½·%“-…@z.vŠÔ=4a–Œ%¸Ï¾¨Jíg¿»#p¾€ÒÛú¬ô ¾ts[Y´rÚ;ÚÌmà„¯EÆ¼˜kşrÅ~TÓ6¬Û]¡ë¯Ø¤T¸:»–RØmÉ×ñb3ò'ıŠN;=A`ŸÍbêñ—ó(:„ÍWWD@©nëæb¥ê)ñÛ4²³'fŠ8:úK·ÍNÇÿJóÄP¡Ã#åè¯/R?ÿÏ	O<FŸöhzº›©–Kü“§••,y˜š¼N´kc5­°İòú'/§€MIÉÖ°tZ
!‘>ÏrY½}u×yí-çe@Ë:t~QŠ'ÚXÑÍç;„Åzë(d~·È¥BÕ(CešVâ“õŒMeÔº8â€m~x„ÔõÔQG€ÉL>¬mÿİ«½L*µüàúe¢äíå[x{ê1ØNN6;ëwŸÇŞdš“…²Ú<«Ó÷cá y!X„D6 †­Ó t_æ±De°´ yb¤ñêÉ¹¡aÏ3ÚdMk¶Hß:ÇÛi¦­ƒÉ2ÍyˆDÂmQÉâz³õ+Göp‘‘ßò`<uó‹nEÜ¬ >9aœ­ù(¯ÏµydõW±xƒüÅÒÍ¹¢Ù¥ŞÌäæ×9SĞ˜‘±«Bå¤7ˆ²´0 ª;Q`«zm¿1UùÇÖšı]Ùb²ãOî|œzÏœ;ß&¶œ¬¸¦°{Û»™¿ÛÚ–êÀuªF°ÂpÕCTˆŒŸ[áÃB	ú—ÇÅp»Ì&+ôĞ]ûø¡ø!6í~±ŸÅ$U‡)[œy£õÀÊ÷f’¯écÒJœè$Sa&{*Š)«xêGÖù)™ğF…)²nÊ…‡ı¹šqRğºwUetÄìpXñüj
€ŞNëÒÜf¾«MDÖrúo¨,@”næé×ÂÕ’ f»#²eTdƒfºÁ0	½CÉ‰‰ÚF~œÙÔİg5Ô»˜.ÓÙ–2REƒ¾GiPNAî{«ÎsK½ˆŞÒÑan!, üŞ“s€í<Zw¾	ï‡øÚ(=¬Bêºr)lD.JÈFgE	ˆ¥Rß¤\$A&]L^š`ğüdEQÎŠ…Å1ŠgµfdnŸ¿L™ÑtçC(ÔìZ§U”œ›§í'ÊMTi2ˆ›d£Ãc~îÂÆï7Á92‹¡sÁíıó«ğØøêTû‰£¬=eÃvXVd›”Ñ.¯‘‘3\³Â­Pôj<ÆÛ¯-~«+|©Õ É x^h5Øl{ö|é/”âQe*ı44V€Ö†ºjëQäé²;M¯ÔÙbpP‘ï^FIî9à”Ùı8".J–~WSÿ§}ã °müÉ
¬¥E->„PŠ™X¹Ã”úµ
mç³¿5Í*Ğ2à%PzÓc+L©øœ`¤C­ïX„X/#V¾Ô$u'|ë¡ÔWz#kÚd6Ä¨G&ÅPÒjTÃ²6Ú$ƒ!	‹<	ÊàJI—uX$b×¸^lùfÚh`<³Â ìã®>€Z@ôU•°†5uBR@°ÉjI&2¡uºJcœo¨BÈ¼(…–\l‡£…ŠI<ç"s¯Êf"J!´EÒ'¹QÏ_ÿÊ	…ÑşqåÄ»öî©`ª²I’û»\V–xs)œeøÙŸÔ·JòS“€=Éİ$ç¨8ˆ â€&Fkt~øÔ4q$u²øOÛº2ô$Ñs»òVıú!fI‹°/–ê¢u³èZk$3_Õ*¦WøSñäÔPg,èÒÆ‹úŠÊòhy'Pè{¥Óì:p`¬g=…@Æ¶è^{Æ_Ğ)§ÁÑ?™ë¿ÿïá¼ØÜäHª¼ÈGa1.ÇÚ6Ú,Vÿ«B“Ë²núäd^\5MDo™¶èXXb5U>¶î6Ò7’“»@%]:,n¼¶¢+†‹f–3ü ¸?ÊWmWLZÀ!øK|´«µPá¯:á£7jëï’‹ézgcAÚ¢NÄT+kJŒP!§^ƒQê¶Hw1
'“/#àïÕ’|œc]ş°fÇ*¿ÈóÈ¯Ï{g_\ó/"7 LÃÄ£{©ÓLæüîje$LUi„úwïËûî!!Tò,)r>rÁİŞÛ6%é“€ÕÙÓjqDÃÈŠ1I^p­jP±5£ÖD´¥oºFé§ï®/S0İ‹ÆT;åz	øì_!Uu¨ØÔ>›ioøÖùÔÃ³o¨lö±'ÓÕ “nâ¬VeÉpCóÂâ ‚l½TH‰Ú˜ĞQÅÎ±\Åõ:Äp©¥Ó‰²J.io7ÛV¥ çxÏAUşwï¼6SóŞ	”­ß´˜´êã;ôdƒë~_Z8x­İHÚ©Uø¯Ã"ÏºÆQôœªóÓ^fóã]ºt S}d²×çQ¥Úd, |Ìò«K?kË2|È-½×¶~ígğØ¨&Û´TmK5U™2¯}ï%y³´³¾Gÿ[¢+gÿè¸ÓÙñ= Ø¾ÍA‡™üs€å  ÷¸¶XUr"3 tH‰¿Æ–İDåcdÓQäâ=£û%:—6˜r{Àm–ñJö»š“bC‚¿	79pä5Š\ï±È–‘¹¯¹½~¹hf§èøvÊÃÏÜnKd)¦».ïwôšWf:§.©ôaZåÛ*Ô2^©z~R6<‹Øƒe”F” ‰âòKÈÛCÍ1Ü¹J¨7d†Œ^«&*×ôÉCòÉm‰’jÑ—k½çáLÌ­¶[°ù#”ˆ¾åØÀ„ú*µDÂ‹Å‚™.éê‘qO3Cƒÿ tÏXí‰¥›Œ)cæ°ó‰]¸é¯/|ô­	³kzT\D›ıÿĞ¾CC]ë’Dué z%1B£ZEÍ²HRšË›d«Dâ®·$r8F0MB£åşl:<kRù4\ĞAê×-MƒÓTvå°‘×m»
º8j%%<”YÓ'İE™f/®…ñJ´d0ÈaD–À×üÒu£ÁÎ—úiFä¶sé£ÅÀÓ²­ÂùúM»ëâ÷ò VV´”Ş/3rk€àeò½DòVèÌ=–Åİ´¦„8B‰¥ì¨ÀÉUŸñ.¦<}7ƒ.ä„ğíÃÆj~5FÑ¸PÎZáöl”–Ohn,­ÕÄ#ó”Ğ/ìs›t±Á(Ë¤´±]\0¦oÌatü(Ò¹R¥w)•ĞšåR^cS\±§ljÒ	IOº5µ y¶nŸµ‡]Å‰…I+wVÁCyY.zsnƒZ­GÙ„/YİxjâioÛùûjáƒ–:™İE¦Æ÷ê-êÑFÚÍla+Tj”¼Ç­jß RXNk³:äŸ1+Òv*î;h³öâ	üŞ8>EöU—{¡×‡ş¤ÆãÚ4¦“r\Rqˆ‘ÛQéYıt>ÎJÿë¯eú8Â+"©)tù”·ÚÛ½[$ïpä¬ûÃã–ºËîFÙCq[p.x‰9ErŞU²» èB‰°™»S(‹o×¾˜Ø7O9Kƒƒ“mgmPÄfBVÖ8C0d0<ÿ½°w2MØÜ0Zf¹Í£³u¤æÔwuÀu-\’ãÔ%Ş`Í¯3ÈD¿Çfû¤ğ^qúc9–ÑUm¼À¶Ş½3¥êˆõ›æ´bøYÔï7:Ú—Î"ê}Ó8¢œºèŞš;ÎSbL±’¡¾…ˆyHµ@i£¥ú•şÅ^¦hùÚl»ç³Ã™ÍÁàLqGLT©–n'Grjü>ü]~ ÎÙ{Y(„¸O6&s–vZöï ËÀ{ŠîUæÅ±o7­×VyVÁõ"Jí!dºÀòøêy…ÄµçpªÖõO²Æï `4øGğİê<î­ ™iÇµcÍÍStYñeb–.{VÆá²9œxùo}fÊšÕ–Zvx´Ú¦gÒİ)L®ë·|'»vâ=EÊ“z¶½úbÃÈÁfmÀ~Vä¬ŠIò*Ï¢v2~Ãh¼Áÿ]ÿxĞOó½F™Ò's»•8š™ 2øQ!ôZ	¢&(|@±<wNÙâ« f^‘ò:sŒË	âì{šcûV]¼°:Yy¯S¸)9~îà¯¤x¢\'Ÿ‘ö]Å¯ı¾H¥réŸâZÔ57–á
äñnL™FuY³àZˆ/RLq¶)×wN£¶¹B1°í§×E.zfÆ¦PFæëus¾@
láâ?ÔRx8`û›*B¼½qô…%ÏÛHÿß|)p¡ Põ€à=Ü/Ğ¢ÿ¸w€˜±ÚÃ—ÓßF€oX/Åõ‚ÄÆ@|QØŞ4Ô•CQ$Q^3N]ºÊ¶PZ—Dô+kĞïÍ×¿në÷â½suû
˜4C÷ÆÙWµn(G§ùøMÛM}OÖnRİ^KÁ7T¥¯Ûq†y3a›ÛTeŒ9a–°<}èT¡¤‰ œèÔpÃÅ±5"M=Îxi§@	Àİ¬v‹iqáa8Ïp²é¾ëÇâ‘m;éŒl¨TKÃEñ_«>)¹ítD×.zâ™]oBØËr$;_‘‘ûœ|»ŞG?÷$àñR aóG3£2¥%©1v2³Z:¬ğÌ>ç—qq-¿em[ÁC¬–tÉDÍAúÈnş}‘ºšáW(İÚU®ù¼_4ÔçÔè^¡w²~vM¿/sµğlĞåÃšaxgo:üò½A<¶şñ:!™,´Ê'*(­õÎk$ğ»*b—ÈÍ*dnÄ×Ì¼.´‡QÔ«JøªßóT¾ûöØ·ëÅå1LyjBTe€\ğ„«¯S?€ê«+%9¢ZØšHÏÁîŒvŸòÇ…y÷±bÍÒ»Êm²·s£¿‡c©ĞKÿLzÜ¨ıªÊ£h­*ßÛ=#ÒìÈã<¥ „Õâ4Xh™i®ÒÕŞó³&Ÿ
jk¥4Çÿñ{†øQ¥¨Á5f“eœË1üeâÄ	îÃ6À¿
ñÅÖí¹›Ôl„aªÎ‹vİUDá'YÆ¢’r•’‚ĞMezäG1gÀ½n2Vã\‹…”œŸnj1`İQQ—¤qUÃ› Æ¦¢Òş˜©ó¾V5H §/hÇWQåP‚UÅ—8³ìè}ªŞŒDXÎSpÙCGËÅZ•·ÙÁmæëeœÄ9™,~rÁ:¨ú{9½Whw´traõYtš)IÙ—%ésÑ =9ÚönSêoA(1]?“1;¯SÔÿ–-Ñ= ôö&…%!$›ûEpªĞp¸*²i•KáoÊ,Ÿî'[œw,÷{†÷±9|$Å¾T’V¦vl’6ly¤êµõF*æ7Ãjìêô>ªÂk»
dŠ¼ö§WE÷¢ï2ÁŸX¥;¥<ºš¿à›ìl}9àµÂéæAã1ˆ¦ Tˆc"UdEç†Ëd·’×pø7ıp²g9
äD1ÏÓÆı&”ÆùŞªß@ï>sÆF¸äjû0,Ê Cy©¼j}ˆãğÓ”Ö‘³g‹d2É¯á¬cˆ5Ë8¹*¡JĞïSŠŠ³È…}w
,R¯¶?ãİ"6öİZK$„Óğˆ^.hÓ˜°N°@İ)İÓnñ
ê•(”o\_ò‡O}2Üêİ`ªñVcÍØ<<·óÅ4L-‚ÒÉj¥M+otéi$c¾rî7~YäTş+Še³$"÷ù„›Î¨Å h7¨zus›#ÿM0¨ºj	-7°ş©J‡yZ!)ªzŠ×¾’š '» ñú´ñTÈ°îËeö*wHü8‡²U Ä¸(VÉ¶8¡Î¿‡1Šqú’Õp*ƒ‘?Šc5×=è7GF4i´tG;±åï%àv©èOP¬­4¥YëU ªË>v²k°ó¿£ÁşËÂ}jÎSÌ[<µf>¦·UwA[wV^ Œ°–6]“<š4¼¬ØIáM+ß)ÄRĞ4‡…£èÈĞ
hŸ/ïÎìÂ›|Éº¡ÿÄË^\«Ü÷l€~¥Zö"¤.O_Jë÷Z?u—‰È¾Œsçô³Wêd¢¸x‹\.-®İëĞÃÖbmIùMĞÌüwœ©Ş@Kˆâ¿©öÉ[ÉU?×óÇq+x­³¡5¬ÎºHÏ®;¯£ÏÌY–&u>y¯³º×)#Á	äZwàƒqÔİàŒà6Èl§ J†›èı†‚b~ÉrFâÔÄ¶©ˆ¦,ìzÜñbªp~PßË’TÎF¡Ü4¥…0Æ ,ßWÂ&k~b"	jõ"£«ĞöñEèÚµ2ë‹®RQq	:/û å:Lv…‘7ÒÌğå…;¼´ôwb!€ËÍÑ£'%h‹ÜíÛR+øÈJŠª
Œª=ã#øzô«`u†Èš](¢O×ƒ©×½UçÕ\5*¸.o47yàøÕ\áw¸X/%Êy° {Ò‘)R{ÖbÌ
,Hš>Š@ÊÕƒ½Réºb"r¥(X“÷1éesØ¶A­b35‹®‚ôš ‘†`Ü$%-Jæ4B7÷él_Èô|rìAEÌÊfÇ¤9qåu´ïm\O¼Ïy0E¡I¯4’aÌ…×ro&6jjU\“¨·(”@ÜP\j«Ö-Á9…î… b-Ÿ¾Z±-mËzşwP˜©¿µœİ;)I£Û}l£Ø²§!Ñ6€"©%H¬â*dû#öı[au@£x¡UÕñ7¤ö¨4SıbÖ² ŸĞ:bŒ‡[„–„í­—XF/½°+UZƒ´ê‰E¼¤rùW*¿¶%j¸Ï(M"FdX;%Eâ¶Ï[{7ézoÿ ü„­ö•,PÃ©Óhû–î¤ıÿX~½öní
aâëîëÅgÇ:×‘g7Ï¬}ñ¯†ßItÃ™YÀô,Àµt	ƒ‡õÄ8ºj‡yïg‚—«œB•ùÖî2„|0dúÖSÓõµå¢×¦ÍŞ-@iKñbØû½ŠD“…ç ˆø–À/eSÒ9““zCj¨˜
{XUhf[g–¾ÇY›Aßæì\
™•âsº³äÑdŠ<®õ¼MËıîÄiuÿTj[¤ÄÈC’niı„ÛÁµ­¤+ìOµÑ	ƒ	:ô ~Ûx¶íä]ÀCÈ/Èá±¼$ïo´ÿî–¡gß±ñwÚuÿ-4ö 
O';jÍà˜>ÎàAe¡‚1æôvôHNÆënüf'“ÊÄú]Åx…{ÉR™]İ†U!˜£Î¶Z*ò¾õÅğä^Á­ƒ‚·÷è@L²£e»3ç£	ÂÑírsŠ‡Ÿ C¦Õ #À®käÆ.¥Ãë³æ“½trå—_ÖÂ¶rKÜ˜TÚ„ıµIB%qDP&˜{~NŞì'¾í…?c->¼d„J@·SĞ‹2­6#¸è5 ³f¼Í¢wÇxªf¦åô0şP{¢,+xÉ“yutø>F]Ød#xQèŒ5+¢@8_®›1²”d26d>¶£«H9ÍÁ»	cü…Â_dgD³Y½÷ö4İˆón©,pS?"OÊíì£
3ä¢Ìö^Û¯Ê§!@_şÀª(ØmqE^~$&£FÚq_´¼‘†ŸÕ/>Æ®á¼üêçb?“g3½½Ôı%Ç«â"íµúší/¦_²|5ğ„ÑµMÛÀ@D1‘U’é‰­}L]¹Ì~ú~!÷Àm-j¨ş˜£D7Ñÿf°çöZ y.½|I)$¡‘êÃ¸•ø”ÏìnS×´}|xà¥R|ŞYeæÁzé¡ëPc)RuHšàˆ…áe[O‚œÃ	 ®Iõ øìxÚ€¾ÍşQ.\D”@‚„&‚Z/™ut2”bÑĞJüEêX;ŒÃ½—Šu¶½ÍÕpi’\ºrb(ĞwF5öÚÛD¹ÀW_cš	dÑj-+wYÂ^i8nñ?XóÜ"$‰³/¢×öjİN:€ô¤Ñæ„³øŠ€˜W¨è-ÈAå|;¥ºÀ/XğCèíÜº•ûtş[#¤+ı…«Ì¢şƒ¼œ©qªÁïç²À‡øªÈoÈPæ°£7íü.tSZYùç	Éş½2ºµkìü´œœ;p¹7ú²“È´²ÛQ¹„ÿÙJÄRÀ—Õåõ€^cçë°¶IÃP˜#Áh »Ú2jÑØ™êëİ fÎŒñ:#½g§ö+`’ô9¹˜Ñlë7Ô8Ù«r^€³§æŠ±0ÜÕ	åŸÄ³Z¥‚ø¬ÚíõXç?üë¸"… :k©Fÿ.ÇÛç™šßzş)¾un
:ÃEÛòrıÅ\wGo-°œíj×e²3<hFÍ1=³O¦r
(.óŠ¢§ÍâczuåCœq*¿@O…ÕıÊˆv×\³"#	Á0GØ‚Öh0…ô´ı\ª»ieø±\˜£ÏØkrú¨˜İ€€õ¬0[b¬‡,Å©_:ÇìLbÁwŒvÆ…†­ïyuÉ»¼¢V “Ç®bÏëO´[º¬>?U{¡Ì84~Œ5²¼V)ôöOMR>í¡Äñ”˜6±…ò÷TˆıÎí¡Í{4pVç©¾î/3ÉĞ-¥òÌl…ájS–Z÷’/²:‰6¶q6GÌPÜ…XëGÊj¿l`„57€ú'vİ‡®À‘òˆOv=W“O¹®™ÛĞb‡iu
›Ys
=ñßfñÄoNÔ†'¡ü ı©(ÒPV*c-Ê*Ë¡×ecj/,ïËS:rYUò9à“XAd­˜J™Ta =À5­Ç§®tÙØU8Ø9pb(à‰Ï’”»ùpŸ×¹RåÅLï3,uêFğMyÏøcÑÙçÃÿlmø’}@ª`ğê½ÜF—A<×Œ“¾K-ßÍ©²”‹¦»8«Y—¬Û9¤£÷µ"Éö­›ø±ëÓ±çÀ©-Ÿ·0†A‹Iõ4ú1>µ3Â9ìn”ñ1ø¾ò¼ËJŞ¤­ÂCÕù!`Mãa%Ô%o­ÇƒRyÄ…¹ÉxÆÒ}
*pŸ“·äØKˆ«%æ;³!í~+yèqŒ—8³l¤ˆß<Ó±9]ój,S"³ Ò	r¾®¿›ÚÑ:‘3]Èü„·O.d¬*Öµ»i$°Â‹÷ğ¦£n&UI¸Å0ÿ¬ ¥+ V›™°Š®=àR=)<ê‰İÒŞ—Ã^KÔí|õ/ó(£Ô~Ê¹†¨Ø'ñmÉŸ×¥ÙÜ
ò¬¡«p8‚SÙÒõ<u“Ÿu.¼Ãh´ËØ=w —Fæ£ï:ı«öÜîuÀ®eú‰òPG|®-úÖáMÖ¦&ôÙB„n7á•'Fœ;å¬Ñ­{àêzFeIˆ]³Y¨D>Ñ9Çjôd®şº•^Ï²Ç ZÏ³¦_Æ€Aßˆ:j~VÚ^­a%^Ç˜½i"ä¤7™«Cö×AZâÄüqwëU§)fi¹‘ÛA¬íÈù3j„îşSs¼ò<ív·á²ç¢‡\Ò…W0AÜÔ‰LØ?S[2º‹ÖÄ‚è9.uôBŞÁxF]ì‘©—óÅî™e²œk»‡¹/¸ûœ õH~ŸÇwu›Ì±]§û’ÙÓ—pE3]|cµÄ/«?~¡ÑÅA¸kVÀ=ÿÅÈÃÒÆÁñö_Ø!ßcv~¡äıì»|O$ÎÁÆl)Ûö¬ÔŒwy/\zÛnr%Ğ£Çú¿©`XN[Êê¢¦ÚÏûËoÅ™wS¤U<Aİ«ÇY£ºM-İÖ¨jr&»§Ü©=LøŸ’§KÇeÕÿ…uÚ/|7ÄtÓ·¯°Èç‹ËÕZkó¤ŞL"r'Ş“1ëˆ_ª—u¥3K2lœ‚‡_ô3Ö½FM…g‹4¢•á#23é·!:'ß§	—ê=2ã,ŒëSP¸Š#¡a°^†}ir=Q^„¸]_ŠÈ_Øc…ïÉ¡R=­œ©ØH7(Rr”klĞ½ä3Bˆ…í÷”C„~5!JA¾½ÉL»—”«®Â:w«şèÚƒÀäRÍ’«‰û¾œMëã’o¥$ İR‡(Š„ZCù+êk‰¿fø²¢o âÕUtÇ>í¿H%bÃ7°BL6gÕGw‘¢¯±§ƒ&F€ õl^i’¥fGkóÅ5úUVVMù¥.jşİ‘—‰ ]ÅK7Ï`™¹Ú{Ç>±ïÚü[ÌÀˆŞ¾MĞŒ¯t?©Š…y^şV÷G£?ş’ºêaC"·Ç´¡Z?oËXs0©¯À‡"É%c‹f¾ñ<¾j„?Äbüp „ı‘W;<Xõ±¡¾ya5àÎò\|öÍïq>iæĞà²Ì„t¦TçûÜ˜Äõ~¯T¯ÉœzZÙ=¸4Ñ¸:ğ3N˜pÖõ}/úM1Ç6\¸	®u„Iüót‹ïBŞÒ4Ç¨û
ƒ1m^şw¯–ß­”yoUB2¶ªˆ&Ëú³ì>ñ°–âcÿ\Æ‚ë{¤ræâJ¤Cè/âQ@J¦¦Î?[!Õi†şPÿëÿq#Çu×`î¢ÑÅlb·öaK<¹«Pˆ$ì_ÏÕƒR&^	áÄ|ÕAª­ö3³Ú¯Ù3ÀN<[Ì<"^[ ûœ´ UÔ˜ÑW‡Š´&TË¨Š‡8ïmÄ-ƒ Óˆ* ÿh¦¤eAKÔsC—°¯¤¿¨®ıı~>Î{Ó)Œç~ndÚşN±Á›=Áœ3‘UV,¢ñOPt9ÃÿWè^"[¹ˆŞİL}6—-¯Øf~f‚­Õ»*„0¿ÛgI8_îË#z€—ÌMĞ§ó™§¤å€å¤w5Î‘»¡——'ßÚs[9îà›AD¯Ê—à@nuÑÈÒP!2éñÒD}òù™
d\x81 ã„DL¯äzµm ÒÃ×œ‚ÅŒ	±–¸
"Z€ëMW—›¸Q.+ëÃÜ Åä+t„‘Å=:8”4ïbòÖÿ¦aôÜ¼‹i'‚ò  u(®$ƒuD	Úcş@G/^ƒ¼oÖ„<şœ"¬›Ñ*mØ¿?ur:BÚ)À!Ò`E‘şgt9w•ÁiûşKaöS{•q|#î~÷oj½KÙ]1y¸¤&¬!©ZDæÊ—¦÷	Ğ!qA¾F»Hvh§ô¸‘ÎcU6—õı‰Bzw€C_ŸÕe›ÄÊvAİÔ2Æ¿%óYrpÜ‰i¯sÙ±ö…:FTğ|ó‹šå×ˆ„czhJ= ıhD‰Æ“Åw)6¹Ø×¨F=h]Û±£¾­I#¯¡æÑ3oô+a%â’?#Ù¸sÄ»¿£©Ó×w-~Ş›/JwÔ¸ó:_ Æó r~>OÚTĞGØI”¿†ŒäÇ@r“AîàşQÃ°°»Í;wÕ}Ğã¸JàLÌ‰:ÚmôZ~3
R q™sî«¤Á¶ÕS¹üwBşLf¬Ìƒî|U ƒ$¶sÕ/î^\c
ÓM0¥Èo‰/Ì]ÄC  ¦ÄĞp²–EÏ}ø½bÍ#KßŸ¼ûÄHÎˆ× –l+›‘Zß"<Ë~Üï"ÁÎØb¹v¨ˆğœN1±İï„²®¶
¦°­˜¢ÇB[™§K»(4Jõ%{CTÆv¬#N:Sg&<Rh2N5¡…Ø­ì´®¬S¿®^J¹ç!\qm¤ÙNŞqôEqb	)<íû<¾c@¶Â!|åOÛ˜Ø/¦]´Ö»’®RÚ˜pÕ¾y4¼Æâœ\% -öN‹rùÅ)ñBPó¢­SÖH¸ÌÅ8`e®UÍÅ4êÖ²-ô-İmş!jAˆìLúµ¥ºX:µªŞXe6—*†‹Üà%=csâ¶ Å{ĞŸïÕSÇ+•l¿«Õ®ì¸/,ñ(õA½Yä©a½_`ÁŒÕª²e¥i–ãsvÉÍO	Ïëä F„EÀNöÆERÓààç¿¬ïù,æÙRL•, Üà!m„ÆÇ•ËÀ§üŸxd“tùöÔlZ‰Å‚HW‹üêâh:§”a™"!CLŒæ¬Äv¦JB8oº‰´b§“Êt¥·Ê™¦‰LqOµê•2#ø‘ÃÕeOË/†.bá
!Ï&l@§ÃtÃÁJ¢åK¢4KÀäNR¯ŠR1Æz@­RÔ·#+>S!|±ğm?–ÕÇH+ºësĞd ±ÏîÃ³/òA{¿§ŒJ¥)îUîh‘£Îä›ıÈ²v¾…BÖoh_sı‹àYôŞş[H†@T^Á)TR³èÔËş\¾öq¯®P½,Nß5ÀTõ^XL²ÿ*°ŸøÈA§r®ºnß-µ­â]@á`S3t—X#rc$ˆú@ò¨´VC´eX;1Ÿi·ÁÒ¥”.¡|ŒèÃƒ~á‘´q4µï¬‰î’G¥ğªóâ…dÛ[òí!%£÷ó™rA©_'äÒ/İÃŠì¯¶ªTéSLLËñ·FëVó›îu7Ì§ÓÈé—°E¯¼©OÍûœfRéï
Ç?Œ‚›z’vƒü•â ”?Î¬Wy|0îq+?\8s8Í0µH,ûü¾¬Á~‘%˜Rn†Å˜_8z6œ+‚¶—±O¦Óà~Ñ£ÂFSpƒDÅ0ªl8	»GÈ l,’Z-8k´çV>Ÿ© }jë1ûfÄQèş²¶™Ùi_Œ¥’äòÕ/fr[aÿ	ğJàÎS’9*F…A–´YäLŒÌıÓË¬2Š(²÷©»¦‡ôşØ7&6i­´rÍU‘p0ZD5´8ecßËº]:Ü­ì» zÄ©`òæã°n]‚èÀœ†QoÎ`Cè–öÂœmlö‚şîókV¨ôqQxr+·.íğ'ØşSBÑñrš]¼"#:t:ËÙ‰`Ø#©cîŒF&ƒ7¾VöáVŞ›‘6ŸQ•Ü®Øxm~7ù3Ú³£’l!P¸ê:²öƒn ¾m™R'è.¬‰eÚ'@BN4C?…Ieıªí´éúØ×)Â÷N¾ëRZqWĞsàm,o˜Ï@äç¶á’{j”d“!ª¾h5IÓ,nº¨9p¥C}JQj¦úRŠ9Ÿß½Á•Ê—g ³$¤Òò×ÌWÀä°¦Æûê¡)¸n{(6…êë6ó'qÈ(G³!ÔéC#áÁE}”š5Ë¼ì²ûO_„AtæMúZ­YÊİ%;³+øfWSÍú®±wd`DË1¼T«8~Û ;™áhGÚâlÍy€Néû.T¯š˜ãf¿Ö3¤W:ùDkW“²%|Öš÷Ü¶¼/0¯_dÏuã¬	ß¢îØk»¿
®Ãş©ÔÛê‹ÀtH‰#ø”É®à	¬Òsì6øLÖ^SòJZÈå¦e¨`ÉïoºÇT¨2Ñ{ÿiãøÇ¯6£¢ËZA¤
Àÿ"¢½ÿi	ÒÍÏÛgâÿo'48+Û©h[°	Up]p²–I˜@¨ñ¤8»¬Vø
G“À¼õdÚÔÔE9ıŒr/ug›Âù	ZA·³¶"óÁ×PNŸXÇË›šœˆs^„g	X/ T»&²O‰o­nÅü½àq÷FËÎhşYRƒÁÓû1û¹øµc†C]ÁÍj•ØÂø(EÛã¤™ÏØ`H/‡½4¼s—â*n§šQ¸jaƒj81Xç¸):Mğé@v“–1Öª—·ÂJÿùô+g	VŒ¹çº¤U‘“Â„“Æ¦òîœİ]¹ÙíRÆšI§¢NßŸ‚}Úfèçùµtğfpy…lÑ»L[ğğ~¹&"Ò#Ù1³&´¤óãÕ%'ı#	d³@ŠğÇƒú³q¹åCU—dj</¶'u²Bÿ]6a&–Bë¿ 4:-JÅÃÓ#wÛ2K86yÔÓ!YjAt‰sŸ@ gh½…SàØd˜p»6•?ò^zqº­ª«Òç‡k]á$uVOwâ]3ïÄJ;Â-£M+}Às]ğ‹V³›èM˜ŒúÉ¥ŒK¿!Í¨×?Ş6Î[ã£Ï\ÄR{6/’ÉÇ²r	õ1­›.$V1“:PöĞ È­B¾kG¶”é5g´@%ÕøÙ@È#É=xGÍèµ„q¶‘CİàBóJ$|RWnÉÇ¸ñUüî¹©¦ÎºÀ¶%6HdlH|\‚áç§.Ï»ÕùÀ„Ààšov9T°|ÜûY©›w'õdA@T8>qHeĞÔNÉ¢ är@«û}0TY‹•ÜÒMùÇÕ€¯·"á¢$ÒsÚšC±«J¦2€—£ŸCøp" ’®3KI¾ökQûs–›'‚eá¦ô2/¯E’u÷¦è‘¬^¤Ç–e”“kÎRât+M^0÷·40ÃˆTr›Ì"zÓÙ@1¯ßÒãvÁÀ±ÈñM²”q.Ø°„°ûA&¼ )Dâ0a›ÙÑü]-yİrı¢pÆ—ÚMj:ö!-pÆ»JS”î??ò™Íß™¾˜„
‚lŞ7VÅJşLÜrµ:‚š#HGÊ]o'Í2§&³ò.z­Q¡_Ò!_b˜ßLb}ö\L.Œ0_ê…oÔ±qÅİULw1^Z‚,#¥m·@óÊfïS8¸:g?X¿¸’ÄP)£|&ŒKº¾´ËÕòŞ}5áb­ Y/
‘ßao:{p1¹Y8Ç›½<õèõ0Û›“iõLØŸ"{“íw´5Q>×-e nàe•Ãh÷Ïåı@P<v*
b5/5Ÿçp\/c4¼Ÿœ[l†yì	ë÷˜g—)j9iVÕ2t¼Šì,dˆ—º0qXİw¯Ø¹0ú˜GŞ·á0á”YaÀ9†²ıpYàVÀÂ€œ•HPœèĞ*É²t˜70ımÜ´òblÅ³—pvnñó \÷¹j‹ñoÀÖ`†Êà@Ä˜U‚rÁ›rÉë¯«o[y¨V(Ÿ¥¹æ?óº%or§È_‰ %â¼JMô2#A5ÄLZO3®Nªs0Z3µëúûÛŞè*ÛöŠ^E_Ó´h²?”Íf¾¶Üã•¯Ñ’„$:7ês4Q¶xÂËXX[‚¹Ü¥üí]*LkøW˜ÆT`±j”ÃEvcD²ÙNÎç†¶_\Ã-¦æ£ğRy…Ê	ÓŸ¸•u=¥+‚2Szp½¢œdQW¸œ Ôe42Ğßı	pÒ9Èc@e`Ã+=q˜ırânâò¾wSö«ÄòÎW´­ÔÎ¶‰l{0SÌŸ['Ëº/ºëÅGöàZµ_A ı~´[¦ û|pÑ®,ŒóØÏ©èÿ×¶¸¸	Vñ˜=ÏûïZo0éµ[?;1Ÿ(ùŸKL}:íZÚq'b
dÓW7AœÀœB=uc‡NØšïMš)¨ÃV‡wÜC–cu+­Òï FO’Óà‘~a.i°}ehÓØĞ~ÎîÃä Š‡0…¼1úGØ¦rhuçh¨Änw½ºu…1?¼ÅÇdZ94SE„¯Vì›Á *ş*‹)ÁÒ |½œ –û´ko¹=öØIAc±¬¼LéÀ 8ÿ~g|ú’o]„m®·#yí“4Â¾ yê+;ÙÇ Ô1O´±¯IâOß0E˜û8AF¢ìğ9ùîíf:%Pz‘ˆWç#< 32ı9Q‡Î¦½ö‰as—ü|Ê_ıaë®”Gâúœ7E±ŠN1ÅÙEáåeæõ;²mªˆ±iÑÔŞFc3Ë• Í
—hÇ%€Ş› p¢ßtø8™·4	íêT'¤M€ /«Û@Û/g|ıÉ:–UGã&Ò•ñîT2u{!²¹“¦ñt~eh~1ÇéÓ“¹æÈ¯ds’æ%îÍV~ÓšÖŸš=È¨Aì:å*‚¨iôí"[a¦‰WÊŸëAæfÔ&ÿìàšG6'0Êå8n–nEâ„õ§Cl Ñ °ä(àÑcº	Ñ:õÄ‹÷¡µ;[¤ŒÜO“òĞ‘ô4+ÂIPmãõ>F±ş<cH[ŸQ¤b/3%ì+¢™/†^.ñ'0Rİq—fŸ½òŠ¯xôR‘+2­•æ  ‰ôrgCÃx››Î ¢bşsS[ Ò1|æ1€l0²´WÕÇFà•úö¸”9û…LiİyXÄÉ)‡<wkœ8–JT¸ÍSdD¦&v¾R%xªu~Ì>»I°
~¿–·ê/µWKJ;V.ë­/[°G>…û{š¢~³=¿s8V'ÈnÃÑaÜ9­ŞX•˜ï˜)lw_Ğô{zßòL‘àgª‚æÉ«^çzÓNFª§¤2SÕŞ—’Ö¸J--!~qúf€,h¡Á(JyIÙ¸ëºYÍàH‘zŠMŠ*wâØ÷Û´“°U¢ªï×aäzJôèŒÓ74RE“#zc!ÁÊÔÅizï„fc‚úÿ6`šT©f7yjˆÿâ™Xö‡óög÷6;lœ]ûk¾¯íó…b¤bCˆ€4Şügxl—tç£ë®«hwÇÀÇÛsôÊ9LxïÍçV¥˜™v»^7¼4“4¯:’‹r‡ï
trÎ0A:?CŞÂ!RÓÄ’@Kh6¹ù¤Äie{w¾Ó€Nxoo™°°ü­ïáD’QîD%B€^Ñ¯IĞtrÒãÈÒ¸&áô%¤_»ÄA¶ä"¨¡ì*²â…tŞmŒ‹0 q\çäQêøk’ÍØl¥®Eà_R–µ6Q+ÇI/Ø#‹¹ß´£MeA)Xl€ÅĞeæ{ï,;=4)ñBéôx.f}OHvÉTÛ	aÀüÇGÊ%/ß<àN5¹¨œ ¹ÆG.2Ö æ·ÒV9Ä¥äı+äÛ†ƒ/#š>;Ot³:ZêÒRl6~Ø…bÓÌVÏ`ZìğZ&5
‡Œh©ñ%qn“÷™åzHÊdÊ‘âyÈ$×¼ªYËß†¶“Âğà9bïnyÁøùbÄY]#¡¹ÿÃV¸‘ÁÄ€Fyı™ØÔkd¤dC<Ü¶n´álÅ¸§§ÏÂ[@™âW ä>ø9ğ3Á:t}p•óşaü¯¿ÙY >?È(Ğga¨â:‰À®*¤¿’¥Û,M‹ö”eÎ Ô§t3-^îå¸Ê9’JªÜ_"e\2¸•¬ÑÂ'™ŒqY,$–U­ÙÛVo{m€¨M¯›]i¦%L¨pËS®œ«à£aŸ¤ÔŸHï½#¾®w‡I3‡ë’mÙèjvÁŒ0?|N°û~ÀÇi‹ö®„ıú4Ğ•Ë¡èÀ—Ğ^ ê'4vãÄex¯¿50”nPãÁd8zËw!R%À|•ÊˆV$×°{°mpÍ^8Ş¿Ü…)zbÁÙ{ºgÁUù#;±ø;=>cÑòğO›&)ôJk•¨ g±«×ã‡¿ù¯ƒ×:ş2Âh¤MEz×õ€úñë33Q†˜7Éría¦,*ß gDÅ©xKûuÌEQ,i¨ˆs  +nTÂ‹üR™»ô°|Z‰çY×¶ÁG›=Ç3˜›I\c°şfH´gu‘~bë¸åReÍ³PCŞDÁ[ÖoÂ¦J­<,8~]õSF{©<O,–èmË¥•¿/Êg&&¹¿g&“ğ/®­}ãƒ–®è7™Jkël4Áù"@¼]ê6ÿ¹×Œ#w4l1‹*âW«¯wæXÚèsK/«ªÈÀË8dÊbÛñâ,Èå…ÑRr‰ÜãïğíÉûH¸x153…©F×LUY^¬%sÀÖ)8Àah9!—¡õ‰1„½‚§™äöTE¿å«Õ ®MÜï•ÇG”nò²äà&oa”Jfv¡„§äÄñéBŞp’œaÎ¾ä¥réååLÂÜoÃù%31±ÑûMå‘ækÖcáŞ)Æº_YÄùg¢”–†G§÷Ø#ágj›Â_êøGOHóÄ^1ÛÀ½ŸôB×ÃjïÈ°Ká’qxñKWâ°-„nq:¡A‡åÑÑØå”s‰pvÑØëâı<gÈ%«;G{Û6M+ª§9•øxÆMŠPğÌ‰}×GQ8©áêªŠ%_„NŒ®°9ú
Å˜§;S¤n:<Ê‹ˆˆŒ¨j"IŞÙ¦m¦ ^ ÍÏ0E>µŸµ²§;,\“V
'I~/îFÈ^<‹0è¼ØB‚å3mRÛÆòÔ‹éÒZ:ÏRYòµÎÒ„HÊùú(ó9´úøÀOpúÆ¨á}€ìà#÷·ãë¦)~3²mPõ&4E¹¶æÙ ¢Q7›AöTÊ… wÆ}ïíoÈ VYV@×Èå@}fÿáËOH¥0‰«:‡xÌF¬<N¶õêe5Y€¨Ø8ÄÇz–0ûÑÙ¥?´ZÑ&Âgk?`Î%Ê˜h-2âŸ£ü¾5q°_f’uC6™ËhæPiâ>°PÀìŒE$6)BâïBá]9èŠOI±o%Ä?ì}ê}ıb‹V§QĞØ1oKëÑÌZë9Ìôà÷J5fæÁnõ¼­!=
e÷S>M)®Wfÿv
«ş.äA´_V*nP ü,d~O·èåïä¼*ÙèJVŞX©4Î´3nk‰–½%¸¸`hú%íYC±§ö¤Ÿ}oğp“™Ê5*°Ë¥b{/	r#—äè<aš’ø
5ö~+Zf„H´àr5Š,íŞÏ¯.ô!òQ4Ä1Ôô<<»Ó1jh[!ğy¯¹sòU4²YÑ»ˆyùLUTišâI,5bœÉÏ' {QVK\b;™Ãõ‘t£_ºà?m$»†sBğŒF×¨Œ;ßªéÁÑ–^-n~jK“I s»81ƒœ¹At?“L$ .6 ÿª¨zş³ª«8ùl¶sÑGŸQdŸÑË]°©Š ¿@>*µtù×OT=Vó¬¢‚3ßÑ¥ªâ ¤V0ÂşÉ² úwüEËôĞÄ'?v†jÍ™
å]!mC‰5–×}RH-ƒ›¡¿¶÷àN]ÅZ¼öüıs	p6O"z
¾ª£0öN7´ ßÑ‹qD?‡.¦ˆ§MiÉ>F†ÓûˆhD§k!µzÑ	«†ïu â
,=Kƒ±àÄPX$L“É´jNÆr~DØÅ8ën¢·Ä¯dLÉ6âöÁs£‹­ñsœBµÍç-ô¼GŸµÙUŒ§q½ó7§ó|šêÄ›5!ycm¸‰èzÌ×¾Ü7r0 „»H2¸&ªÁ’R·àæ…Ññ¾¾Zb°€İtòp^U;qÛà¨ó?ğõÿ  _s¥=r2£æ|Fj}†7÷€£ˆ\](¬T<~†:Ÿ±±MiäEM5uày
`ÑÈò·ŸcSm"[í3`m
·ÔS‹hšı%F( åpZ] _Õ
O‹h& ³'‰Vÿ‡V°¶.eÙP†Š¯@6ij[Ú?ñâ¼Z²[Û<ÇÀ#hÕ"õè$ÃÛÏZÚÏg¡=Ë2†Ârè•åH™WÛÏ4©˜'ìrVè‚:‹¿ıu¹ÄójÏ `"ôáz™óc3¦˜axš[•$€Ù*Í*ğ5pëŠ#×=È†pÔ„œa^œë0­l¿fh€÷»•€$Nw•œ/€eê¡¦Q ß¥@şÌÛ¥¡²/’ÏZ È²^npæMü¤ç²<¼±:·¬5ıêÓÕŞçÃ]±|1#±k=_/HÒ#Rõ]nk’ê²ºqË™¦`h¹:Ÿ8!l5“…{Ï” iSßÕÃéJ}ì¶6ÚykhJ$ï=N²	9µrßœÚ
2éjçJ+%ŠCd¥³Ë–:RKÇë¦ÍY¥Ù°ÎV-!0ç?ºÜ²-¤) Šu¾ù¼Mø /2\è›º‰SÊí:ÉˆnŒö„,î˜ƒ\¾Öy¼ûòVÑ$pZ8Š8—y~¶º]Ÿq@ÉŞ§‚¯¦Î‚FÂ@%JlX!ã ”ûA»pBoh—êØ½‰úk¢¶ ·Ğ6š¡û«áË¸ØhDq=Q÷={W¸‡ºôQaÃîB75²â!GDz²S¹hÉ|G‘Š)«\%[O +…Ó/şöàˆ”Yœ·:P„;ò~ã|àxÙˆäs¨<J^Q»"gá-Øçl©.Y˜J¶\q·½-<$À´‰"N>d+pCÊ³Ğ€cÍˆ­ôÀOàYLI>Â/Ôb‡¨÷Ìä£ñËäúwÂ+#ãù¼³…?ÄœìWßM@š°ó™i‚-›çıô†” è¡æôgÿHà2	‹£\(Œ%hD¿Z‚æY—©j|Æè%@‰m$ik@y¼™Ùˆ'ØÉ§Ş¥Æ§Ú7ÒKĞfIV™ò8
æ×¯hqE€ÎD¹«Ë´ÙKã‚ô"7dÖ­ûÏ¹³Ô‹ÚÒß¨Ü-å*?XØ£t‰äç_…İ`ô¾ö—;û„Q!ÃTÑi—¦È{bíº5c¾Vn®“¾6`kbşPaÎL-3µ`õ7s`WÂÎÒåÍ¬†<BŠ	,Áöƒ¯Ü¿Ğ6¨à~|éXâüCukì¬Ü;dá=Œ"™¼¤Ó»É&î>ó´„Êôì
ñŒb+™+DıË‰†&¹f¶“'V/ÉÎ.F†Î»l°—cÍfÓÛÜ.7ƒ{öœÃñ‘xX*Ö¦éA«µÎa¡œÈq2­®SMª6†Šôå“hkùtËÓ¿Û€Ì/&ºÿÔÙuİtà`³1¦èQ)ãnG±TÚş]—[ız€l,fBM4»x$ÅÚÃ’µ8`Q4*vy‹Sá¯ÀÎ5J ~ÜıÒå×zëA‡$/Ã¯8€ï9ÕÖe½–³¢·©@±°­ŒdÒğgp¨›İ»QßÎ.ÔïJµ’Bq£Ún?Ó€3pÍÜ@yı¦ŸY÷ù¢.^ûN^¶bÇ‰iÀÜÄŠzHÔ¥4‘•i¥×_œéR×ß‰x8œ¼¶:fÆƒ.æ}>kî4eI'ñ¢w‘-PT¨çí$‡.ñğ8ÓèïÒB@@uÿ¬OkÒ-x´÷ğHBø1y„"avD’ZA‡QqvJiå¶‹Z¼¨ˆsS<¹g\éW8¤åÁ’í:[Aö/«e…ªéH^<w?ÖŞ"¿eÆ¡—ÇÃ£Ø‰m÷0yÖàHÌŞì¶Gb•kñî(Gß“giqìDºIğtOM¿«]f®ø6^Ü89xaÈ³IE}óÚÂr'„øp˜B©Ä:¿ñÃšrıÎÑ'u•†{FÈ)ŒÂq¸0p 
(èº9‚nÖÁ¤Ûl[m•kò^–¿ˆÑè4!i[ĞÀ¹1ÒJ¶x¥çy(`{¬Õgq`—Xh+¡W‰!d~İÈQ"«ÁlTwîF:O>—Í”sV5¨væ§úÅÌ¤ÓG‡Änc7jC¿œJuo©/‡‘*Z¸Œ/5w÷}ú3%B¬¸Ä¥K†Ó8
Şg1{étôEs]Ğ)*>—O‘‡h<Ò±8IÎ k÷Q‘„ÈÏŠz%•õ6e3Ö×¢]0‘ûH3¬wDQÇ'Õx±Å –w’Å]Ìy"¯=’ÑÉM½o6KíŠ9„š¼D!6
f±Ó£YWT¬ì¦ó#Ó‰½#{Eo¿[Ãp_ÏóğÖ”c:%VMÒ@öâáãaRÑµ¡À¥Ë¾i¥‡—ê“9âz‚*¹‰V2
¨”º=ÕRñ´‹‘kNÛ8Úª«€+‡×¿Òg~*?¾‚ÕÃ‘npÛKw ke:ÓGòƒS­‰HÛAîcfXd‚‰[sHÄV”rp‡RÆÆ¥¶Á”/(xUnäŠyñuÎ>mÖj¶eD™¯ŠòÓ0Í5EÒQ¼¡N–z/öjÇru/'‹×µnÑ>
Ì~Îtê)F¯YÍ\šìq
X„¼õ_üÄ^ĞW¸F˜,ÇŒØê g…|Cô…¢¤@@W½›¸ ,ªÎ‚u¨W:Ï·ïÈ®®ƒĞU[øgı-æó‚{åğº“ü–F°Á¼ˆ÷¿šƒ9Óal-œ¤bÒ¿ì‰C!Ò¦§búÆ¦UÆ@èÒa{Höã©ÈuQf {ò‰,°ƒ„_°ó9“Fp=lıa÷X
ã`	X\l£ ¯\¯š§ÆdÇH›Öö‹§YÄå]¨Kƒµ{_Ò]ÚÚgwd>¤j?—Ü_MîÈÁtS31³LEfÃÃÙÀ’VÛi¿G‚6¨	Š‹,?4#^Ôìo¹åşõ;/âÏ²“k[[WĞ4‡9Šõ‹ óŞàé"£}ÿWvÍCàÃ‡ë,æö!SUÈ Ÿaôâ“jgqfS¿>-EÅ.îÖªå¢¿.eykûÌ· ‚Ø,J¯œèÀ†´„™œÙh5 JÅ+úêˆ—=š‹ÂqAj+ÁË’•s¢ÌûæL“¼.‡ïÆÌ24˜ÆOáÚbW@,lr7Ò"RÒÌ@£ak
DV%şf®â¥jŸ[¥ôN¨4œtÑèC".œş½˜_0(˜¡[—5Şy›ÃØ§‰KBÆá!ù=znú”ÁDšìåƒ¤¯½ôÔeˆ=ùßQçÿ>;BÂë˜>¦úlU~ºc‹Íå3cÈn>âÌû.Şİ¾Åñ1æñŞÃ #IÂFÅD6ÇêéÖ¢ áÿE™”²ƒPä¼Ü	¹0 ³‡98º¥şº‚ª‰£èŠô7(Ì_÷SR™4ã¿“œï…lhFJÅÑ“½@[i‰
…FÄ¯ÿ¹[ùïåâo\İ-ß†ì÷XP!ãûá'fh1æ¬Õ®½y7hsÕ€£WùheÏ+x!­ÂÜ¢ÕM’‚I¹NxP²â\ñÇ>İÑü©!ò×[:ôliˆúû!3[(<`YéÚÕl8^†Pœø£ÓªÛZÎI×óï
nIÁêiàhy#KŠ²-‚5cºd]gtä‰ó«…¦ş4õ @¦Ëw'pá«×ÄFì¬vm ¶Å~‚‹—˜ÊMKødš˜ïZi€F´õÅHWbL!L~¾ïİuòŞ‰ÍŞ=¯w”U¥VGqï‘­·¹N¿+?—è¶ÕDôvÑ¿/½WŠy"YÏ
±»öÒÍ^íûA6×HÙ¨?ş;?§ÆVèÄÏÆ5)r±º/}Ûy¸àØ>àÕH²7Õïİ‘Âú"&¬Çsàé<D¡„^QV1²rW‰,Àó2bY7&
îaù¹·•TbÉe4Ş âzÍ’YRêWà¸âÀv,èv
xeÀú·a¹V@ÇªŒË'-»~¤°1‰Pö¡BûÃÀÉÿÖ7Ö¬nÂ³İ@ ’µ«Ñ˜vPZ¬ªäï*Xá•ÌÌ™B]¾È0¾p;íşq¶ùÃt&şãfpPÚåÉˆÇ"ÂC~ë;…³bäN‹ëæ >Ê
à<~«rÿÊ]×û ÏòÖFGÕÚíBÉ{(á°dâ!ËywHøÆ±Ï¢=.‹X´;9ìğ²(‘:C}%×kÜ òn:T ÎõÕR—õ4²Kú@fåĞûPgpıs·Th?;¡AX°Ù×–Ù–hÂ+<nL¤•ŒZ[OÖ¬«™Ê¨„ËñÇ%Ô¨QH^ õd£…÷òuôÌ†ÕñeVèê[{"E1HùÁã†#?~æg5Ö«ó<¡FCW,€_ÀJJdrÚ BHäÃôtr9ŒŞ»¹eg«V‚·ª7ªS\ßö™uvEÕ˜rÆÂ<?MÊAˆ& Âf”@§r;ËI}kÂ*°%ç„±†\iƒß,FI«Q÷*ƒf—#†}]%Êô0ËÃ~%i{â¬Lo€³iş}ÃĞSyÔYÁyÀ+fÛèÈëÄ?%õó°(Æe¢³.=ºß—¤$TÀævosû^™yMí4ÈÆI“ËJ oÛ/ªğdÍ§Ák`Hßlï
;UÌ Ó2#ƒnÙ™"JSQëïS\Ì}•å#¤Xæ?A+®¼¸…Æ$ä-æ™Õ{ö‡¯
.í^¼e6ƒcFÛÑ²(û*¬íÈÓ“+”À5FùCÖiIû²+ÚœjÁLGøÏ1ğXVûö`Š—@R.qü7Lœ#Cfç®X1`¾°¶º{`ÙRu/q8Wd#˜*Dôª5» ùó3ãğbà6ÀÜ î^NCÙµ‚Ø	¤UgóbÅéâIñuÅ]öé7±?O gL­ôQH2	–8¤ %Ihÿ”M‡ôSV»~K7åKĞÓåùMçnõdóšq˜øZj "Š.[_2™Èˆé½CÂ¨ SkOLã³‰t®AäÑÛÉ¬†ŞİŠëÒ‹bjÖôÎk Û¾â“·íOÊ”’æTûë7©|)Û³}Ÿ¿Ñòı­ÜŸÚT\N#«wàå<qùÕ€Vš½Æ3°;ÜÉ]šA}ôÛlû²Ì‹ıá;Ë:²hÙÏq9*}³65[×ö°ùN²µÑ–±eU6"¹¡×Ú=_–‹1_:ƒ¶ûVCmKu'³ó¨:^¹¬Æ&Ğ	Òe‰ñw§ÙLnĞ¿Re¤åÎ›¬Ì+¹$‹¼Bmü8@h¹÷;St`0§ÖÔm«¼7Ø{¢ì6m²-”2 Yašçò½5Z-€{‘ØñM,š§R˜ÖÍ§àZ>?lĞÒÀZXe
DF»b•½ c.WÛC_*J}K”nç!ãºş•Ù´5:À
à+áü*ÕÃ%¢€YûöV»*ˆpµº Èı–H­ÇŒj_¼ä·w~pêu†Ú“U™Æ²¥T4	VÅ´AÛGÅ-ÀUqp˜.Ã8åŠ  ‡úàK+´~¥ÏëæG‡çÜ1äHËşä9ºrĞ"ªÏbŸÆ»T.H©«fY$ò I˜î¡¦f‘i·9î:€
x„Ù‹òb={*–»;ƒ#" XğIº…|2
7­Ö¹Z¥øñ«HmÕg'3¨Å!ñà¿Çˆm ×éVGêŒ;^è@—ŸÛ É+/ì8€ì<$]ƒ„áŒ {JTÈ!ë1#~Œ ,Œ“(_lQ;ÓĞ‡;‹‹Êsÿ.ÓñŞ„¼ôQî³tüÍ7I?xf]æ<Ï/jX”G¼©°-‚Ìé8”­¨ák4İju|eÂR˜ôzäm˜¬u¢ßÃÒœş¶sısÙ.¥SU_ÏÓ#;|èÍNßÈC­¹NğÜ`ğ‚z›õN»ñmW›i†6‰Y=ñ»1mĞíQÅÿµÿÓcæª”Aw}SÈËV<`S8¹Š—mb“¶ó¸õ‘Î& g`¨²ôö‚ˆ
GOPÿq˜Ì¡hì}O"°E@ã°	,M6|ymÈèqèŸø    Ù
÷lgğFK ÕÇ€G€ü±Ägû    YZ