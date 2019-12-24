#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1113448579"
MD5="b69768293699e30f34c5ac3672f0154b"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20356"
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
	echo Date of packaging: Tue Dec 24 00:12:04 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿOD] ¼}•ÀJFœÄÿ.»á_jØ h%3!ÑFáá‰C†Y‡"V¾pÖîŸ	©GÓ‰At2éKÒVMGwÅÀ|ïéÚÃüÅl~“àxº´	¿± ÷Båâ!¯¨ÙÅÖí„,Úd’Àb2tlbWK`•Æşß/~ïfF3©µ¸º€º`ˆw¤pö½ÎÚº³'¬Ê$‚¶Üçö)ÕÈı³¹ÁÀg0«²0“»eÀBjİ3ãX:Ğ¡S29;&Æ"âü¯„íŞ±ê¦>DS:„ÄÇ9	:ú´[vğÚDŞQ„c'¤˜UM„M'`š Îì1ÏJbhwpDíX#ÜùÕ]I¸éŠÿ
Óş¦¦R	Mîø­¾˜:a"¬¸éûùª1n>§IFeöUÌlı.IÕC¤$FxÓ‡óò/
ÂFmÏñ=é¬Y–•±¢‹ÜÄœp“Ã¢#â¨‹äFã„7£˜yDf¾3Ë9ÄÚë_?Ë­0ò	ãÑE„ªŸÒëæ˜ö©%J\„&2òf3&fï(CÔùÈ]cˆšaÄáHiˆ¡Äl;fÜÀµh/œ×¡X_9ó‰ù;S£?íšº½ó)½ÊÙê`dHÉtâO0ÎmUî‚š|×JÛzâÊxxóÁ7uZÊ­K
é},™›A¨ıµÀ„E©.Zôpø<1¼Æ-0ˆ#cÖü’ş=Ja’éOò']Î ‡ÇÒlsgcB-DD•1E[b*óbH×T3nÛtGC™Ê“,´4ûRA]¨pM>r†øcÕ¾}áÖÕ&	²… ±e—3ÚX(híº)àÏÍNİ–jÕªË`r‰´9Õ®?i}ûÚK2‘Ùj l	ÃÒ<•ÛÊ3yµ®¬4f¢H6ã%…P? 7ı…!åOe/İS5—Œ7!|?¨UZ×Íáşm†uÅdöpaL’{È>L±>éDĞbá2Wš8î<ƒŠ]µ[ÅÕ)–Ÿ7*eÚÒ0= «÷%­ÑJ-³@Íµ O—Ì	Æ•)aÆkqiêl©ÔI¶
¢T×r
Ñæõ6;]f›ŠtĞVZ0‘BbÎ³Øn-‹$ŠEOª‹;%ÄtS2ï§W}·¤S÷‚QàqF½LÖ^ûÎ{«ğ2”œÔÜ èOzCxÔìHM³S*ŠĞ›3){ës8ã^OL<»Q5Oìïuÿ‹â=a “ë§
~p9‘õéÅM 9“&†4p¶]æ¬uF2vÔÔŸtädLh¸BÔ¸:8=bfñØRÈÍ(¿Ô·íAz+—A!ˆ›Š¾êÇüè"=y?I¨ÖÅI…?Z¿ui†ql
¬¿FÑ«qNuEÙ„™'C²V\«W‰ùS}‘`;¢Q†±ÂÛQM87-¾qø£·ê§5„²sY:ıµ´sÁÃ´´uÙú\ï” W4’•‰¡¿äÆ»mªày¢©g6æ¤;M£©×‘]ÍN4u§p"çÉò¼É»~k™í¢ J¿…ìí»gYˆÕ]Ø—÷Ø\DÄôä¢ş¹k³¯)îÔÔ6¬øF³ï^›¡æÅ ˜Òöaä2’ñë’k2Ÿæ&8õä]4¹Ñ,OCR¡ÊíÇ¶7È¿n¢ '°ªı8°å¿‰õZºŠóosÂ¿Ä#w&×ºeO$\|^¿IHÁëë›¯©áÚXB	L0;qâ€û6ã˜ÜĞüKÂÔÌ&RÙà€2r¸Ç›Q-áÄJmoÒªÉí/C†Gü€•µ°•ãsQ4œMˆÛ·ûòkÊşÆÀsÔ!a…`©Ó„ÎÓ¡¯ËÔÄßR ‹½+:eSÜ…ˆB@jØ€è •ÖdÌÌã¿ø¸7RñœH¾’â„B¶"S¼vØÌÀ	=€×Fuõ@Ú^v©ªÀB~;µ$[w-H^± :’©Ô„u¼ó„AÛ|Ç*Ymë8EÌŒ¹ØÚa—º|r†&øXA|‚OnÎz17¯ëÕ>óoB*¼0 ëñ’\€èTæ¤ñÎˆ	ßÉØÍË>È	yÏ5MŸ¹[]İòÑ¢sÉ‡$íVe	.˜„ó#DV]÷a¯qEt¼Ä?F‚ëŞhYt-©eD6b§ğ¤İö^+-ÙyÖW•ÂJkLÄ€/Ã¸59áßíôÓ­˜/U·ÇpŞFgÿ¿£”;ø
«­ú[×ìDŒôÊµMÍ;(ÊU·"xÖ&ŞUrÿç\i'´vVß1™™\WñÄqáCh)uhÖûı²+ıÊy.éF–‚ÊG×”Ó6Ÿ–iH NñVè¦ß]_;ÇåìÍU
wĞdãqLHpı –åæòÔh†· ø¾*–¥ØbÕÅBnËFçt¹aU•T£“ş“¢¯Ø·`‚Zcm4ëk‚ó_jZ!.HAèÚuJ¸†—¥&Ä¿±ù §´†W2wi”ªÆÈÉ¬Ibkå¯:O+?†	=½ö ò)îó<âbóÅxv”Ğl¼Y†¡(t/­ğÜDƒ`08ŠÔ×°sU—Ã¿«?9¶aw'%acm ªš©ÉRDq¦‰`&äaÔ +ã;Yµ¯bÒP·0?6}]B „ìN¯Aom7ğ¼Ä÷€„P/£J6PÆ_¦MädoÛÃøû–İ<LBKBŒ]Ñ· à_ÇôG8şú“@«4rRáXÊ*Ôòúÿ™³İ›"Áé’a9\I“õGÚ¬ÈyùïŞÇä”oc€.ªFéEqÓ¤ŒP”]WÈ]Qi*úçVéÜ^+İŞ 7ï)^ëĞU(²Dİ#ºVì6÷ä¾Àµf>õº;g:¦ÇÔœ*€XaÅ¬·¾8F¶gFÏ%(ä0wo/á²š0d´CPœ*ò²Ù’TG+¬­¾wsFÅş¬±Vè$§\RooíW;e øé$ æSYI8Ç;·*ër’\Z¤}Ï 5´‘¾1¯GÏ@”IÁ¥ho§ÑPèßo/v†oĞs$ì»Šœ‚‰ïídjO9f[xîJŸ;On|P¡l§™*™8‹ûq"¢´=]
ä3İƒ—œO™ÕàTä:} q”sxóîÕÒÒFèäM÷g‘šZğ—İVØ“°œÍ¾ÚØ¾JÔµ½ãOåpß
rFäşŠ!$9
ö?ÆH¬_Hã(5ëLé#{tT›ÔD:¤:y:ÍFéQMp±` S:Ë|mZ£¢®ãDÙS§El8¹fz=%±bØ“ÑxBMÜÒ¨5›¬ŞÎ·Ô¡³*şEWHs_‹Í²ÊÁ-W7ÅÖ²‚nÀH±K¸¬G¹t5[@¯wY+ÿº³®bÌ•gKU
_ÙùuÀq'œ …J½KQ`Zİ§J÷|yÚnDİç¸Æ¢Ä—Ï	sJèCi1ñÚQÌ ¦‰1Ü†%|Ú'{CCıS9ÖÚÆklµ¾Gú‹5µ!ÓÔÅ,ÂíôSò¦7¤x„håG¬Ì…ş[e®\q™P£§€}¬ÿºs^ß#Ú|£á
+»>tGù}gégb_(^ôê4-ÃMiK<?{ÑÍú™é;2õIS;F§÷“Îš÷b®<+íÉ’Ò¸ÙvØ3± *2İCe‰‡Çµ!ñWçcSÛsX •:¼ÊÎ]ÒœeÉk5ÁV¶—=Ê&ØşM«íHÛ,=§%Ä…¬+<c×ÖwO‰¥6©‹ª¨İ·Ûı'Ü™½©©¶g×iH¢¦¤ü÷ú1ÃN1 ˜Øó£QJ—sRQR"Ê4ÖOôûéè–³b¤2G˜[GêBÎÌ¤#õañ’nGÈ¼¡¡¤P(_»İİÂX§)MC³¦9hãRs”ğâ…èİÌ-Ğq¸ÚïwÅ¯‰’H—J¶b{·&¯¾ú>§ë0­t$¯b\ïâ/=…³;º[4.ã†M#è|¨HŸºü'šìû¨FIÊÒ
{ò´ÂÖ&Œú¶<~§V²vÕƒ, ªÀÿñZ…P¥ÉÃıª¶®ˆ!0õÄŠÃ´v*OM|Şeí¸8û›)5ªv‹ÌôÊ²M~å¥œsq«±3bŞÛ‘I«Òº‘-ïÈø¡Ò/vkº˜ñ¬……Qİ-¸
QÅ9È¾zH”Õ0Á§ÖoH(YLÈ·Âô 8Ò|ëü³ôŒfÑˆ\ÌŠêjÙZgU¤@‰7°¬egÉ¥wDKd:ğŒ­›´jøwØpåğ¬Øğ7Æt6mzçÁeÜ@‚T½Xs¦Nó ÌcsN©`hšÎöŞCòó¬L'AZ3~ì¶xÂÀ,X5CtÃRKk/«™ªæØ¼+f‡2Cí¬‚¥X¡%¿ÛınBx:@ÍÀ˜~ê5­^Â¤HJËÖè¦!“6Û
D]ÿ¼è´È¸KJ£Õ6,Å’X¾ö)Â IÔµÂæ„¶,~
ª7ÿ/°#Q=ò´_c«¿â%dPc0¤Ş¡±4ËyĞÖ±°†ãÂğY*
5÷”ÅJ"Zi‰‘:ûJFÒéá‰!«š’û1rÏü:a´³Ôòf“ÇNl»ûj”.İ_Ï5n&ÎMñßZ²EéÑGp{¿dIP”yu‘¼ó³™+ƒôşØ«¸=6fcŒöH. 2¬yƒ (scq	ÄI¬xªr‹we=ië}#õ?Ñ]Ñ„áŒ`»C6d|T£±Ç¹fç°|iGH‰ÛÁWËARş¹Hs•o³×2Æ‘T¹æüÀ¶·ÆmQ 5±ÃiÎ*Ÿ”Îæ¨/¬Osõˆ»D$.¬¯aåZ±ÛCò© WÙq,À¢ä§ŞodŒ³
ÚíîˆB8Ç:É'  G,õ}&ç*ÅÊ™â
-n^03’=–	ÃænrÖ¨Z€Ê[¬UŞ€PooÃı^”ÿ†Kl
 •é ß=£ı,l#×¡ÂŸGX>~®<õ¿‹OïÚåv-ë·Úÿv/{@'J>Ò¡kÔ>yjØTçàÚgABïñ^¶ª¿Oeˆ)AA}å½Ğoô­=8º8¸Ò£n==Oiëä}!^Óa_ØHëEš•Š¶¸EÌ-ìÎvbñ–¯œQaØ×áoŠß„*‡×Ìö|‚u5¢bZƒ³,Ë‘@”q1¹›‹Ÿ…Nc’qêÂË¾ëà		#Z+YyA«ƒú!¿æ”Ïäğçs·ë¢3}­€àhp]ä‘©ğ<«¬hxÍÑàEµ|ïñïu×#ì w^Şÿ[”ğ‚4Ñ2¶
=¤Tš…YµPIßTAÛÈ:—Ç'úÚ»ó¨µZ?¨“¼ë™®0ÕzÖåØ¨ÿ/Œ<Zk'B…AáhÜEpèIGˆU42Y$ 3]Âü*ş"òÆèØì×(›ÎMU ŞÒ98s‘N‚ĞªRFÒNœ'k–mÕó¿ô :
‰¡ˆNÎPÃïÑÏg'FÇ‡®ÒVLoÍg°£&Xì}kÌ<Q ìošWi}[BÖ«fßë7J'ˆ©ôÔüPõ~<ƒşÊ
+;ğ>ûÛ™Ó’·›¯\2êá¡•> LX‚ò±]»”öNjE¢8‘_Z11£Ôñì\—Ÿ4v@Î¾‰€K2
d¢_S¥& ·‚Ú”-`„—ºa¡Ê{t7.Ö#Ñƒ	8ófHİìƒP½IÖ#€-&çùÒÌI¡9<•˜×X-óxv¤ !cÛ{8;ôã£ÌÂ«PÊÇÆ4kÍOfQD{èÏ¡Ü,£zÒenê†4Å´@ó>Ìöà<•¦hÜ¾êA”DF7à[rQ%\0}Şë65•“ôpø¬)ôLİ{Í‡Äº´g2ª£×*ìkmBGæA¦ÚÁË'ÙâL˜3b1’¿RĞ~È8õMş^-"6¼jVõ_ÏÖ~A²Ìmn’ó‘…,š	äYæèyg€k¼†#t «øîÁø,‚lqÆRmGú^ı9Ö
ÿü*Á&Å÷g.¬M(Q ßİu=8ÙR±ƒu“Âşy¡%éwÖÂ-ïÇå[yãîZßûğÆÜÎåäÃtú.j™eĞã*u6Ó¡!67¯?¢ŞQ]yBB€ôLs­´Ì¶Şm¦Şıâ×†kíº|Bn’~iù$G¹TS­*¿íèrW?ß%Ú;d#z
¹HO.æ™_Ò!ñRt}mVi8ä)kJÒäÊG®ØqVÕ©É"ÉP{‰3ğkRœLP«7„o³[l0XawÌÚ :;åS¶ÁR£ƒ7 Â5ºé;ÁÂR$JÚ‡C&İÚöÈQ€‡RË§ç‹!uU¡İéĞC[‰%.ÌGq2åÒ_ñ€Å&)‰ã‡†‚î?¢Œ‚îo—éC–ãù¶ÁFP½aB$Z—ø»ç¼Š„ëûcw,¾hM½µé>b™ğôÉ¡=VŞÕl ßmr(è|mµÖGÉvvãÚ»3GKw9	W´æû"v]ÓÃª@Jˆn.Íö‰Ÿğ`3ç¡í†'Úd §İh|Z7˜)ÇÃ/CíˆJêh;'\”ffµ@Z®„W–ékD!Òk®J2lşFşQÚíj–©ÁÒ5×.ÍœcèÈa§Æ
z0¢CZb—±5Ôß#¸l~cÖ<káŞÑgj¡Ğe‘ûœWDšzgYÈ›w¶€Õ¨œ¨I!ŠÒ3„€i/¹ßH@²÷0§H¶Næ˜AØZüMâ`vQúã™=»ÂıÃ.hÇÅÖGF:„Yëe2¢-O¾%{¦ç]\JÒDÀW?>Uƒ±¡»G…LğCñpâ¸v6T7í|:  <	\§‡ÂIúŞ íÁk‘ûˆ› ÿ…sò2>ÎRÃğ²ø¹·4a–İzbi||V;+çsËÚáIíµØ7•rø8{Ø Ò’-B¯{ÒÕÖÓõ%:rrŸÓù…‹û¼ä`êFÛoC)·bM±ä!ªG¦>kÈU/!ÚO´©å·HÉSNÿDŸx-‹õ ´á’µù>±õÊİš“ñdMqÀäDÌü³qÿÃ†ÌĞ³Šçé1òUØ~İvé°¿m€=0ÍŸÄ¶€0|œ
Pœ|íÓM<iå?ZÇ¼tN×m¼!¯òñcm èwÄknÿ–¤HhßÃ	÷S¸¡µ-3»%fá%¶Ñ6¬çàW`%dk„4°1-ù&±yq7YÎûÆÉ0VmÁzB3`é•ôÌ®:¾©ƒV<âŞ¾+E·Î÷|¾_„ğíÕyÏl¡ÂWóğNÕØ0Ær,wÕ‰K\Ó»lPì<›T·C5iÙÙ×|„5<µ´ù2š7×›]½WKèF&«Ó	RC¶.÷-ÉÀaé×c}ÚÇü0{½Ñ|8{íp tWWNÛ3®)áóä:wïX	+á¹Í,hlë3í»pùiˆ¯© JàüªP®ş1ÏÅÌÈ~Ê›—FÂ0—·z,zãG³äÏqÀ+V‘¾Ò`¥'JİŒı­Ø³`_(ÛšF-éä˜¿AÛÕM!ÅV›>\¿X»€Á*™!`®f®SõØ}2¥5¸ËáİÀ.ıj¾§ãµê™uJµÍ_êö¥â@WÍ´eG2&.`}ô#&Ä’dÉ¿ñ¹‚¯«%ßßª+€é’ØéI¢(&¼ ÎÎŒMvæ(á•¤M¶`·)9ş¶ËñC}í=k^Â3=¸#£ÑœA5õ–¨z·†ªßjSÿ3#ÑÈÖ‘¢CáRnPæ–VJõ#{:‰í¥FcÑrĞïßÉL‡NÄ™Í÷“U®cJ1¸4ÀáÃ‰Õäs_ïò¯Ã†·(™TÊœZÚo šdÄTÌ<¼ùF¼#ªTr½ÕZRbè93ÄN1MóG©S°l yr²r£àN[#ÚD\«c?¼}ñFÅby˜ó|fˆÏì_àq²p®¿±šAÔ8™ÿpùµĞs,@¨‘OÕ,w%‚H cÕ<×5µÖlÿïDUŞrG[²!¥'¡½$GŠm9÷+GCMIÄ!Ä:×ˆ$…Š~âpÃ‰Ù‡+ã½Bãc2×Åä´¦š#Şİ–÷Ë5'‚tÜS«×¢¸>Æ<•lf½PüRäùhyepYÕ2ÁYÛu}r@İÕcc”5æLwÅp Bşk~ª&|vÎÏqtê5? –x2FOóÈğz@–íæ\IÍS2Ê£‰È/,}¼ƒOR dó:ÃâÃÕÎÉ§€ÏUcm“ç¶ÍŒí\MÿD#A¸¢ÖğÄ!goŞ~•£Ùr°¥×ÊPÑ‹E %JW@~ª¿ªš]¡Œª` ¬KºN°¢©Pà^])Ó]Ç°œ]ç’\ NT¯ˆ-=2g™LÈ…£­Ê‰ÔR8^Èå”›SØB5Ë~Ì¬èİÅëübY¹[v=iY;=WÌq…sÖè6à}^¹è¬®úõ"aC\zwFøÚ÷;*·ûwBÑ_,ùW0‹y?–†§Ê^ø<½‡—“A¡gR‚n±ëÇñ`K¸lQÒHß­Òôï(a–‚½-Ã§Ä^t«ìz×
¿t«! éãl+:	ÆSøÎ!v$%Ò6˜ğ´Ï¹c,ug¶İp
)MÑÏ¸x?ûpl¬Bü˜‚ä}é¸¨5-­ş½¢JJ“È¡Óşw‰'Óf%û%²7u¿¶TBØ¬õ	±OìAõşˆÚÉí€â@²›ÑrøXÃç–)SŸ$GbFdÜ6x9²¿{&1‰Ù ÉüMü¸öoÄ\u÷±öşœ½·
ñÔÛWÇ` :NiÀe5}ô5·­g÷Hc)²¶K´—Ÿï¢²ø\˜&¡hPbpü2b“±1ü|í¡™?Rót„ÎqÖZğÚ`ŠK(e:B›®Jœ¯)!²çL±y¨lÊ„3:3t×jšêş
]nèõä.ÔDm3ï!mÂkØTìÜ›êbšA>¢Ç3øÜ{¤Ó eR£>iĞ÷£Ú>íÔ)"¥AÊ‹Ğâj–Ò»öœ”%±s'/‡ŠåìøJ´£ÊjÿÁÄB2’&Ğ ³×Èrô5¡™r+ş|ˆóäøÃ©”¶¾§uøxô£Ë­%y2ódÈ'q<_€?LH7{°•ì\ªPI™hÔK¶2“J‡Hæ]şş¾ÅóÌ–—gÏ´:'êY÷Ğx+aÊß—R0³•ØWç=ßØ¹ÜêœU!ÄÖª³ÙÉ”ç‚e[¯å¥'~Ü	„Úd®±Ôi%Î³ñ%~÷ËÈõ-J>×³{Z ò{•åèä wi¥¢THÆğ¸@ŞGÓÅçĞ@"ÄéùYwa>ŒŞ¿.¬9qÜzu´«„Æ>+|‘Lp%Y™hâ,±gqÑ$|ÿÒùÁ¥r‚w!I/@6~š@dşa`t©}]4ºuc({!Al¼Aç‰ [™nÊ¤$q&Æ²–0½y´1LËEü©ˆ»ÃQêæoû”­öÉ…å÷ú qsÆ›’-HˆÉåÆ‡ÛÔ®ç­¾®©éïB†enë±âna<)6së‹s7Y¹pV¡!k&Â+ğ&àÀr€št§À	ŞÃ¡l‰ÿZh£ĞIÛK€a£uéª’»3­edf›«©yJ—ÎÛÃ“Á6¼«—5¤W(çFS„w…nJ÷r!Úí@ÇİüÊÖ{ätfæMd¨ª(×ŒıB6;`Ëm‚îIÅÓ¶ºi º¹2X#÷2¬ôµÙ±‰Ìh"»Ñ¥Ÿt|¶QsŠÖydg€ÈQÛ  ºaÂ‘¨¾àåI¨]&¯
oz2Æ©^Ó¯¶
§A¹ûhaür¢`³Fj~ĞY°Pê™8æŸ»YÔ«ÕYÙpÙ÷8}Ëƒäº‰V"v‰•ŸRË‡peÁn! HKÉ|Í®ˆÃ½SÖqÂŸƒQ×" R'§x**Q¹öo[ìösJ'¢qr;6âDÆœ?ZâÆ<ü±3%¹T9‡ì«b Îü@Ç”ÎãEğÇ×ùU­ŠâáTâKè^ì›¶ÒijÀGÛ_È¾BfaUBˆ iªiÒØ:åq›¹îj¹Y»kß“U1P÷Uÿ}ª·&×g({eÍGTXsÊ(7ÎÒ‹2Wôf€FV8©z~Vsc<JNpPÄÌàŒªZˆà®Û!ìˆèQ,¬¤GÍ-„c¬ş"»»q…—ÕÕêC¯'İGÆÄq4„Ğôà(ã¹c[ØÜ®×%ñáÑc£øT¤\ùÌòé,e^ÎDøYÆÁ Œ ³×1÷Pe„ßjCõü[î±ªÚ>iNQñÊ}ïÂ/?ïmØ\X…rO/W:DQÛtşCoñª=‹Õ÷–A;ÛÓGŞ²6Ú€1".™Zò$ú­Î¢©ÈÒfG–IR…ÑdŞ‰_[sùØ ¹øÕŠlc
œ’ÒŠ<‹SqÑÊ±Ñ\q¥â›¢êt˜véc/ŠùU wT ¶RŠò¯Wpá¿±¤Ğ—“"Q<\AM‘4È–Z?÷2È3Ï„5Ä=›Ô²JÅ³L&ÀÙ&¿	½!ÀÆ8šê›EåŸV½æ›SEˆññ‰Ê‘¯ëÜóÒ}±yvĞ&©¼à°R
â;Ğr`ÊÙùÇ¸M7‡š 4¶ƒ¡dßï8§‹¦·ûÛ.–Õ‰`‹q«v±áÇ~G³wÁ%)[ÿ Õ¥”¿ÑµuX%6Şj~L!BtÒlT@ãÎØóñ@|µçj|k—Ï(È±2A|¸’ĞÙ&Çxûİa3íŸw9,ÎVñ ,më¢ÁİîuŒqå6’ó!J+"Â¦˜xoˆïP	:Ë+&òb<­ùşË™e©£^*Äqí‚?‘â™fA_qt^2âÏ±ø7ÅHd'®·”F®Go7h‰i½û]šÏÌxU~á¼#`j4¹»S’#lwÃëFÔi“l®$µ
0¦ät(¥–0ˆ_eS‡Çò˜­9ë$b€şØª×zíèq[¥qØx±ÙûÂíŠš'àÛJ›æ0,.¯åAùô üîDÔiì’úÏuóÊ•–’6å³@>u×Ïu8ˆëe;‚¡¨Qev±Ä(Ïè9`ÁÎ ı=Ğ†&Æ‡ã×±%˜•r6BS_€¿Û0¸şs–…ït–}ß»‡´ízg²8°Œ»º]X¶-°ùLİ?R‰@š=ïx$eà×å ›ğí&½øã–^”úqúbÂ×è°ŠpìnŞ_x`:X`†.ßØ¦çÎ<”n$‘xßÚ–İ%ø‘‘.3Á2¦B^åk22¼F„z=¸^wAFAÎÉ3 ÎÁˆ
#;eë¦h8îYë<¡t°G	å¦:C¦‚-"5´áDÄ™ÊŞFÑ‚ØÄ‰½9¥EÌ,&µêz©x0°Êí-*¢Ú¢/ ÚÜ´†çëêZÅS jiitõ?ÁBá®È˜®óâõRÕ½Dh™Á^PbSèûİdaŠ2ÂïFÍ4#3	Ç(ŠvÏëÂ1g–ş!
F¥èz.3½#+0sit¤kšAP1VmjÙVæâb•—\k-Çä›J$2„qªáñÀûÿƒ‡gMµŒ‰?õ"ºU4
Ğuo¡mt¢ä£²rÌv~bÊ×¡½Š¡»°éşê–¤Sƒø·½è9&s¿'	\„³Ÿ¦%Ù§xäßçÿÈMË®ùõaA7ˆ–-H$}Käh­–°Ø¬Vê]ÆÁ* ¨ãá3Ú7ãÃ¼7­¢#„z¥Ò‚àõ>Ù‘x„:pfÑ÷O·¤ƒ‰mU‰ïÿípI~—Ej¹2à„Á”
5F¨¤ù6x×ˆ‹†ì»Y«lË5ò—>dpişûñ0™ŞPfmuqºi;¿ìïĞ8°¯Õt,îS·Ïùã.•¡š"µ]{‰šO{lË«Ì™úÀ%í×å%³‚½KôO…Sä	Ü¥xªJ{OÌ<ë]Âp`zG—ê"f;*`Q×æ0’Å Ûê?‘Çºƒê:rB\²¾â³ámşĞŒ%{åÅMí.+¡o¬Ï@›¡º¯ûŒ,ÎpÔaTJ~Úpà­my™†â´_Sş¡lğX>G÷êe«@ĞÕÑîMª”œ7ıR¸P´¥gm<¨ Şê˜­²£ç‰–¢´Õ‘ÉÑëœI†Ö‘øçLb­8äh"kÃè{‹mVz„Ä„i¥ÈÇÏå&¡É‡|3æ4kflò\¶F A\t˜<(+\¦—·Çô>4´áÅ>sºÙêùäÌğ¡şË!ó…¼r”¥“×ªá–‹EDØ?ÂVéw¶é²Ï8šùzë¹¼Í©
.ÓSÆÉíqë"şÃäYçS„ªtfÃ9Ô™b«¦ÄÑ”…·£õ=ú8­¤ˆŠÑ!CÛè:‹>Áş3sİÛ{Å°VhS÷EAÓ6"ôòiúN
"fÈÍÚpU	"Ñ†tz.zÙ\z%¿…”6wµW{òkYÿÀ@ğÇUaº?ßÅ†%ğ³fRû¢¥:è~@¼‹î’³àŸ‚-s9ë÷ø·Ï\,ê{†’uÉZÊ…À(Òym;•ÅÈÚ}¤e¥m²_}G%‚q¤€Q“+^¢ßêé]°â=ïjPÕNÎxğ1œ[bµ(Ä›¢Ko(h"­ZäKeašÆ(dr3NÃVU¦î¼5Äb+O"ú—ÇpTdZrh(ç5O]&m÷gĞM"%‹oCW7¸yIt˜X ‰Ÿ¹ª¶§ŸÙ.ñVB§Q°T}Ş°Ì³º|Àîå™YäŞ^å%•;ü:„„@¾ıº6eön×Y’d9ï-ë–yLû41Ş®îPŞ<#QçfÂF|Lî•Ëw‘¡¥±óù@ŸÇ%–-[¦0=Ù––Éä›¸¿×Nêe`fxñQIv…i¼˜NcYÖhƒeÂ³bk’ˆE¢KóÈPùe%ğœ+ƒ"ÂU%È˜ÓfêÒ¼ìî¿95ØOÓdÑBú­¹œ„…Öİú~ ï^Eë¸ö´ğ@¥Ü»Èˆ4ş³G_l8N±É¦$_MÁeø[hËÚ@xV%Ÿ‚`úC)ûjkû¥-2T-iì×$Ê3)!V1›§»w5HÙ@7ìH|8;;T»İb‡@·÷Ó‚§œ˜>Üø~"à‘FyÍ[é’¦ôÆİKâğKt(ñìuÛ"^C:,hjW2	bñn¸ÜLK%°Ãae"Bu0ö„3D,Ùıø.N±9ØY.ëÌt?KS=ĞoøœifÃÄ(]B½‘uåİ+§5!}{“4Vç›ˆÔº)(Ÿ%åS:ë±…Å×R¥R' ‘bİ^ûHYW«>3è—R+ïWÏÊÃ~
µ¼˜ió0¨üAh^©I‚Ò¥À"É[>ÏÑá[¾|ÒÏ\!pO‹û"ùgõ–Íùs zMp‘ƒ¸ÁzQ0HXRİíæUñFgÚÈc;ğŞ™“TùqíÎ¨³Â±ÔÆo™[ÑB%yET×ˆyÇ„ò¡¢™Vúí’[5èëèkÓmÛ–E„`°D¿ÏœL‹ÑGî’…+¬²ZT8i‰WgN4QO¼–!éº/³-}Zå4îIª<%ìóæs$V¤8ä§}Íë÷)LÏîÚæT¢#à4°|*ô\Y@·èä vã‡võš¢“‹‰bßßö:ç¾)àÙÃ;­^Š×°°4İHU0ÑN\T®”~ô(6µíĞÃvÛôˆí¤ ,;ŸÈJûA¯õ9Ïûäta²¦tk¦’«Qó³9ä¦Öc$ä3Ş‚‘]-H” n’qY3fV·±äCqv@0ÑÉu]Á‡ö†Ë<Zƒ/{ô-t¦§·kü–M-'8µînÜ„µ´sÌn¦ÈtjÑ8Ôò>¾«Œ·§M‹SxyøáÒ¢fbÂ)}iŒ¼™åô8Ó‚p­Ê²¨!£T±5›WŠ>Cßæ€Q}8Ô¨¨6Js© {Dqõ#²ÀºµÈXÉŠNXÛÕ:ã|Ğ¯ñ8t-áq)çğ€¢6Îw%¥íIiÀÊîLZ7‹„Ub+Ü1÷+)®2ÉÕƒ¿¢š¶’u9Ævîø	É}xÑ`±|İ¨©ÒôÏŒŒfğÄx8Îv©]¾ŸUC_ÂM}7'~ØÕÛºŒv€ºş®É”ÖÌS‡gõRiAÖ´‡À÷$ÄÏcn”Ù¯¬ŒTc\ìu'ç¦´Ãİ-ÎZÿ×$—*Ë`ü8òNê+Rğ[~|ie¸ó,Åwm{5’”¿Üıf—Ãµî¦R£~‰÷p= Ó„¨ËBâré]-CİÉbÃ„vo\¾~(™´:/ÌÃlˆlTæ¶Ê›ÍetÂ-ÎƒU¶Š:’ì{N{ÅÆCÊî©›"¸?5fÛ'e(ˆ¹¼pæç˜¿ğ²øA:nGùÆcàÔÏkïªmÉ×z‹vaIsï“ë2ûí,!ğ®î6í‰ğåy’ÇÛNŸUw@Päİ§äÕ1q7\N×T‰œî7Ï–ŞfZ‰"‚iºÖlàÜwûæµäøm|q±
¼H‹•'î•éÁ¨jcEµìRª²nT+âeC†yÔÈVF€D±ròX’^m“øp“¶3¡u»H¡!]¿,f(û¿¼“ç6ÌÜì€^lEtñ§§ØJÃC‘ºdg•§¹ãI³úKƒs†L§1J^ß@¹„\‹vóÈüa² ô!QmÔÀº#E:1Å”¼Ÿä9ğŞ•^RwXQ¸·¶ <`Ùc9¸D;ŸsxÕ¸wB¢Äà'\wêŠÇS¹åûª-õ:¡º:ÖÚc=ç"d4º†¯æ1Nñyë‚écÒåÇÄİ°ënphw|î4xpe¹&L“?ôïıEÿŸeq '&noŒ(fÙcóLKÛX±é8n¾¹x^Jı»uÓ5!£ˆğœÙÌtê}™²k×)±	a 0] jdbiçÊ¿ÊMÆ6^[.†~©İ[{É·¼½/) ùuşGs–}ÙÂ ¥‰lÉ;-Álı·4°æE†µ5
“ãE„È`¥YôãŞTßˆ1'5åæ¼LªíW¿…Bãäı‚ÂbFz&ø¦0ã¸ÚÒ–;ŠŞÊeæ9£¡¨?TIÎU¸”OöbIÂè¿T¹Ç½g1;8•ÿ9ı• é®©¦Y»¢ø‰…¬İp‰~}†¬R2ğÌ«„¿Ìà­bÒKú)qìåıÛ0Â2´.ÖIˆî­a‘3†ïMUÃ=-F(š‹<¯kmŠb;t–¶ıô÷ÂFfˆÃ™»9)—½+…ñË/‚¹d_{º1T¨mã²Š¿sm¥ì@wá)h™Òl	°Á ÑtüÔMM+¤s™¨S¡àÇ¾‰:ã©L¢]i(#"ã@¢|XıD]Oıo$À{ø]‚æsZ•îÒU.šB_—h(%Æ*Fı=Øá:ãúv #$÷2íÜÕ]›cŞ4êÆF‡TI|É_•áöºÍïoÏ7­Tü³ê†su9NÏíö¦Ê$Î„r¦Çé¢ìBÖZÜæqÒLòmì'0Ê­äÒÿŞZ~'q¼•Õ€óKwPc¡ÙP@†1O¿€şR»€·±½©±:ac•bC¼ÑiX3i¦y¿W§Î´øAJDìzDõ,u>”j%4mzWóV+[xğ¿Èsò¥^;Ä¸ıf¨'ÎæİXdâ”Ö/ÁŞŠ-Fn“œíØ
÷€WèÖÏSa¤e&‹T¾ÀjéÙÊ¥~µOnTĞ8»µ·ùÛ£ïò¾ùƒ´ë23RÈ@Å^mÎwÜgâ+_ú†ÂL&rM4å‹BRmÙpŠ°òu°]bµá¦ò¸Q…ˆ·¨S»ó¯È¹RßB¯lÕ94\ÙçüÀ\âÍkmâaE¾“^¶‹Ÿ xÍÀ"ö×Rİ|ÊÙ©6å|„‚!§f\âó>±Œ°Åƒ;càyªA;ø~å!ÁyYß)zi®Ï¬r!®-vÎP¿ìbgøÌ{¬Ì9‘Åó›|P!øfo)¡–ô+$[RTnóf×óÖU°qz³}cäN)*±¡¼UMà.rIêé=\xÄ›ğ{ŞEi˜ÑûÈı «‡ï?x¢QN`hu:¶V± l¼ÍÇÉ/’\OÊl_¬š~šˆy.Ò¼uŞ ëÊï5gãQŠ£>†(©Åô“¦’²Ø¸ ü8ÒÑªÏ¨­¹9¸ºŠ…)êë#‰‘”±8¿T…_zé†C^¶|€T¬;´†UR¬Y¥b2;–ü±²ğ,ÔxrèG•r[6£Àa0 BùN¦Äş5° N‘ƒ*®/¸+† ?i;/×wÓÎ4e•‡ì˜h1õ[çe¯dñV›ÙÊ(lÙÚrtSãRËWML^
qÅÃôJbÕñ$’ŒnÀk”œ7Ú¿©@nû( ï‡Óó/\ôß´c%*Ì€Í¥‰Çö¢O°LƒrTAòÜŞ„¦Ú‰#>KdPº|`Ìƒy?GÿOÆg‹“árn¯EØ†‘»zŠuı²Õ|aå¤6EHÔ‘¤Q¿r£É¸gRËÌ¤¬¡×šV3#¦úéÊ²ÖÒ\L›±ÉcÇP‰§È²ÉhÿÓMğ…dO+V”Şıké™s©ÂQh5mnœâ 8-„läT0òËY‡#¸¹äùD\H«lç–ò!È—W6d¾¿Æs. ¿q?É_…û¡Äi›Ì8Kîñ¼~j~9¡S‘¨yõ ¸H­ÿrpDŠHør6!¦'«dKE|Ú7{ÿ–Â"iŸÏSÕ—³7Éâè"µÚgw^–Âæ¸®]Èµc'¤jë‚e«­ÛA:|¤c/S¡/m!RP¿w@¤ĞßÌ¢vâñC#?F‰Ÿ:E\up—K;J©_|ZŞ’x§şêuÔ¬P2<×æØy¤ußeG@m¶te%‡2`Œ—#¹*qº4‰WXÚ®â¦3·Ğ·‹@c4Îúx<ŞúSÍN’t}FD×5OÄ$h¹$äó¹¢=%jTıÔ"õ¤’ßËO²ÀİÏêŸ«
4…kpı«Ğ«|~RTŞæ1›S-·EG!µ:€8oc.‘äÀ§m2ÎÇ¢„ì©,óûŒ»«(Ê/õE5’ı/W§Cã“„‰_Uæ×]™˜/ÅFÜŒí†ZŸµ”l½V{C>(T¿UúĞ"±Jİ<t~«>ñÇl÷WÄoDÍ)Éğ‘‹9#¦j¨dIw{LÚâT(¿IêË‚JwË°z<‰Õíö ·YÜ¼`‡avb	†ÿc‘Œ‘všfü '/+\ë‚}âvV¬?9Zˆ¹mšósyx¸şËé–7ù<
¬¨›~|‰(zrİ=À‚¸Ò¤Õ	ğkÁ&o´Á²=ó6ò7S§uÀdF4ä5Iˆh¸fXê ¼Rg6PZF:Ñ9ğd¹‚q›£â«EÚ×ÑäÄôn=ÅnCôÂO(<¶X¥.]£?nş¨ÚC¹O]µ1ŠÏ«t—…V¥‚
œ'¶h Z)À,ŠÕ}KWÚñËÿ›NJ©ô$ƒö|mx,iV9…xAªĞöœ§fêŒ®º„ u™-şĞ„60æÈ(5 ¤óê»oDÄr*åŞV<|zÓVGõÁc*“œ³MG„ÄQ4.œ7ñi/…Ñë] ºœ É&Qf»<ÔœyìïÂ¯«%*`ØÒ®k…äMÚ@ğ¬ry†>ÕË—ûa¦Ì$ºÕëFU"íàåŞRsèOÖ+Yopš¿M.¼0€`·ËŸ*ex#r&+\9J„šgœM§Á–t‰¢eHT÷Œ³Í‰ôbj}´^ü^ ÎP§C´.Ì\B©šOÈœøó]-Ú¾Æd¶WO38×©‘`v¸Jd‚±ş—qö1,9š°M·?¡=m‡„&Å8Î2P»-(y÷»şàe‡xÚI}¡êÎcj|	7®°Œ‰ÃŸ—òØ1yG‘#òşp˜âòß¾¤D+ Óñx]ŞjK°…‰H=0>×…—%¹á@ŒmOìú¸ßeŠŒDrS=5ßƒWı’ô‹{¦j#â]E9%>S`…
³¾º.êt®ıõ§¬~œ¡€|}ù–ƒG+¶qæ¸WJõgòDóM¨LóòğÙ‡\½"—ê9gĞ}¦şŸsƒ”êÖÏ«=ËÂz,’OxÑj+r)Š„½ˆ+=F ÉGGädO]öÒim—§À/áÉPÆ.HIÚL+ğ‚A¯–ÿH,B¶QHİLk­§<Ükz&}ÅNC•À±u1X‚i7}‚À [©„ìi¤CA8§ ·Qm/ŒD’v¼¡söWZóBC,Ÿ½î
#ÈĞİX‡#¢¬}ƒB¶<
„` h¤EæÄKï&Ãpı2¯š{° o`£WÅ Çµ³Vò©&Ÿyëur½ÛëTYtÖ­_0 ¼“Òıƒ]bb¿ÉörT¥$ÌwÉ‘{It
Ì®; ¢W¡n¤ïõ“N¸A„ìè Wğ€~–$_:?CÅ€	¦@/][Şãzí{æHĞÉâ#IDÄ~2À£—9›²hó‚„××…ñ&•fr‡¦æ‹-“jk>ä<Hœ$ó”{@†v`Z¢t³åÁş8p”5ødø»æ¯ªøÍ³/ËQ³$ íİ´°íÌ”ªs%u4vµvíˆïT.èuç·ƒ‰Æ/ˆA‡bÈ
hä©í·ÑSôyu’ÑhÇ–(Ürn™¬ãü­VuŞEi%Uş…gp"ã”aÍÇÍvF@Fµ•´ÿDıVÔÿjİ(,…Âi‹øÖ®'Å„–ñÛ¸MáÁxî¸O ¦˜× ”Ü‰èÁ³«÷A¥!}š…R¶¼KGº½:úÊÛ­hıM^"V¯n›	¶ÚğFg¢2ıîÆˆôCaÉIÿê3ÀGÈ`j[1_UrT|;«#ñ–«x¢€6¼ÜDîŒŠØ›úóàå.çar[O¹²¿£Û‰Ş¯—…Àär²v\64· ‰ŒÄ’%bïßÁüX¹ê‡[ÖmÄˆ$5©Që‚÷øïàEüø>+
_¨
X˜ç¯ØEµœäbIEo~™ûó]ä‘Pû?ø>5b«e“1¥$9+¹4d—£š¦êŠa‘ßĞÔL-¯OfÛßÆX—hùútí/€Íğ à#Òı¤µáÛ¤Š_ÈÜ!ç&.pÖ@r˜¢üm"dU‚»3;mw„;£†-…²r‰ÅLeü÷ËW.^èU˜K—fÅiÆ{µ[£Æ3WÆ‘­º6>;tömÇe¸’(QdŒy¼;Åì,ÆøíüO¤«¨Sí‹ğÓgÛT3x¢DWı)êœ‘T…(¼Ş³(¢¹1\E)×Ucvà¸ìàÇ$¥Í{WW“&urkùC?0Ÿç÷o"ˆ^k*ñO²ë‡»ô¹““÷=y¿æ-ÔP.œ7¼KÌı‰ğIÚxxªàpe|„æp£sT«w¹¢Í”ƒpÚë»ChÇ&!	î“'ÁaDåeßlİ gøË^<2Î¼4ªË ×Ê(ç‚›ˆÀZ—³ï'C`@Õ¡cŒ½sB¬³$>)Aia2Êh¿9\S„ÓMO‹Y®(ÄÿdCí ĞçCwÀOó×şÚ”½Kµ^×†û#HØ÷‘m9Ta‚aí¥s§É²8ïëˆ}p,lVë†—‘N`'ŒîV]Ÿy„p{lG…Ï’7p9Ÿo)Œ¢8Eûw-”3D¤*ìcõZšñƒ†>:´éû´6¸pÏ`QõÒô…y+£Ê¯›#šç©s‚ÂOöÊ$\‡3å—t¤k¸¯»à&»^=h‘ 2ò[Fòş±õê#ºôu§«¦¥jqñ³ßÔRøx†«E‡Ø=+ö–Ébt"6šT«<f n@x+oØõfÈ°+®#À%3k¦b¬iy¦•İ,ç’’R»ÁEp&Û·± š•áuWÖœViº•Ú3	oáD”âĞş9Ø…à³P¡õ€ç5a´~cêQ²(˜gxo a„ıLh#şUò°œ,!;	œŞRÀ¤¯¼ºÅ6}Õ«¼ÜìÇ˜ë^Æõê÷Çe»š®Bñ‰ÿŸªàÄ˜2Pu{hÖcÜéØ#.U`IEfIcg\”ö.vg©ƒC·E§±³ûø5`LÿßuyBùÔğ	~(UÎœğEI­²nQÕ_—Á9 R‚ˆPH¤ìWf j¾à¨VCnUåĞdºö½2AX5M.)³„ÉÚë«í¹9Ğ”…ìªkb×ÍM¢üµPY°]Ãb˜N¦­–«¯Bhg[­L“ ¬øÇÏıôYŸ´*5?¯‘üĞäæª½—Æ¾¿íª ‡jH¡*ï5Üpñ´ú-Ú¿ã,Gñ¡õªnÓqí·`ÍyI­³£ÇŒ‹zŒˆ²’njšCX63¢Ÿn%ÙkÍıkıìUoÂõÙç>›¾ÁÛĞ$6Î”µÒ÷°‰ğvE€›æ9ˆßLÂº”qî³u`?·ä.¶’UÏ?ƒ¹ 	AåÊ…ä3çU"»üONPøÙ–>82ÚkÂ¶tœ7D±(ÉH2l#÷ù;¾‚ıtü´ÅÎêNß…´rwŠ¶n2Ümw;Ó•_(ÎùĞøIÔ=mã8VVÉN•ú´²e$>N NÇ—‘ŞYÁEMu¹xh`Ï+ª¥ ”Â§V4ÔîN“lfH÷¿ìuƒ÷{1ï±[€ûI
xPJ=ˆbÂ‘m’ËİDWZù)1r­G©¦'êÇíÉy-3İ¿Ÿ[Ï¼ÒxÜ>X ™îl‘‰îŠDõ3ÒÃ,¹ûy\v ·>°9†‰Æ’œÜw7®üâ=í«wap»	ŠË‰ö^ö¾j6’v§¡ú)RX‰¥QÀd!í£‚Võ¹óPùVéÖ­Ñoe!¶Ì–?VcÉÙ¹âV|ÿ„¹`cÎÒgºzû'°2˜µxÓªrÃÎjÄE»«Ë7ÏO&1Îˆ™œ¬@öü=Ãlà5”I“ŠİpÂÔ©oˆ–Ó@fçD6øz0UŸ—Ñ“×IÕ†çíDÈr9dˆój¶ãoŠY	Ğ£ë+w¼bm*FMa§õiY€¢à™ğ8ÑIÅ—£oqfäİÎÃğª{Š75ŠŞôNÒ¤şwÅ0-‚•ãeP9"ß“(Œ~SJ I©I!š®|} ÁI¥”ÕúÂeûSéÑW<’*'Jz“Ãã =23v8ˆõÕ?‹¡Ò’_“šÒ©Öxâ;	Ñ<şŠ–D[ÿé]Ôe_­ÿr<ÖZ°.0ºø†ğ»	æk¥iğ—»T(SÃ˜x»¢`|Ï‘¶QÄKœ!¯ìq±ğÈ÷¥nçåa¡ˆoƒÛê_ªq;vO˜ë&Û}¯š—EÇ\ãÎ…Ó…ƒ:ş{9óš”1ú ğCüF”˜@•[õ—,†ûzµ´²æ)™q}«á‚âJ/¦m¶øêwß¾CBÈ*öS² ‹tSÓ«@ÑŠÛŞšõÄDÊÀ»pè›Iª×CiTh±‹?Ôm B»iJª†Qrw5f£Ëx‚¼ŞäÊpÿa1P„)—È¬êáX- ˆRï<òiLÍO~ˆ’¬ª­îšu:ÎÁUYFïƒà™€®wä·%MÎd\ù–ŸcŸózßæ¼K2C†Eé˜âÅü-rO[	 „TôÊ¤µI•ÔÙíÇ¼¤/÷e/ø8@îfµ¸¶o›°¡ı Ün`í‰(›¯-nÿ4Ğ–wĞ'6P‰İBˆğ©ÅC® e"z€E‚ã/_BâŞ6`ÌÃTu0^ßµûê6’H…JDÈï”ŒÇÄ6¾Î­úğßğœDşp›Ç¯‚iVFb-*ì®ÿ‚ÜMÊ/ki^åÁyÍİ%çàÌiª'+%yo‚gE8Rü!w;„Y ³[`ÚZåşZbMşG‘4g3ÆÅ£yB[€Æ£©{L4<Ãã†ü_ªŠ˜ËX×Ä–¡ép‚A7VşVoQ–æíÑ‘“½‡)-xúçĞá‹1™Àï öHö±ÕîÎC‚«ó¬†j(n¦üÇDV^¶üë¤é$"{]8dôG²;éÂŠ;ßdˆçw±±™¹À‹RS" «¼v6±1Ò„S•şíÌë©ÆDzú>p#ÄPøu´HêuŠƒÈ•ègxáÔ(ÄjL…á	bº#%/°;kµ¬õ;ƒSë@%¹ô@ÁÇ	û•À‡–¡Iµ7úãOjÃôéöµLç•ÌVùNÊ!thv{{¡€—ì}Û‚m–’°Å¯˜a3š ¨•Î*C¿÷†Í1ĞAúÁø†Tò³i oIÎ¹Ná Àıíôÿ§Şe7úŠüS;Öw¹ÃÒ©Ššo#´ÓŞº)`dşWòú¼%(„rk7%?ÅcJ”‘»©`NRXµÕuDÇµ¿£ˆIÌÇ‹ªä÷7ùº
‘÷”‚^æ¬	>ˆ›èOÈ+À¯Áæ™±.
¢Wå^L#²|˜Ø:ğïÇsS»=ÇÓÀ ë ö_mVá6ê~+ÓüÒ›ó††8¬ÊWÚåk=Ê–P£v½q=+Í^ÅÏ7I¿45¥?™{°•çš¹;I.<¢±›ª1:È—Ğkìœ'A”¿'VuÄÄüÆHÆÖ©\Í="x”U%¿ªò¢j,ƒ#ûŞôÃ«GÄ¾ËèÛÚuwû–íé€4Å¼Öïò°ª.àøaïÈÏ,üG‹Ñ‰Ä·gGº–ÒØñP¾™ÛØ˜o?jŠ7HuøLë—ÓKŞ£Q¥möV ¶yBPéö ÊŞq—î<úrÀT"òw«Ñ‹¼Œ=§A¯^)hÍíÕèÈ÷pÑÌNd]qíW­BÚ‰c‘WØ4¡‹¨ 0t¹~BŠÕ}JŞüò}Cğz<XyìiÚ¨é•WëÇŒ¶ø“rÈê<ëÆ»¸«mÎBç’
û24ÇSN´úï+ß}ûBI†ûéğ<ªV¦‰Œä®}®I}b~ÅŸ²:Aù€mZË¯"lÁô`†(·•‚haqu¨ˆÁ7ˆs­U=é°ƒ4¢ÛĞPBŸ¨›íA`OÚe¦$Åæ38¯^gÁ’®Ø|TâÑx¢¼cF÷Jò< Z<æ¤$óD–mÚ¿à—]Dú”C^g–xvM[Çí/ç^˜~§›ñá½aÿĞt¦Ã>\°ÃE.PV8eæÅƒ<½ƒàJMãág>‹SÛ×çĞœà¾%“ƒ}¦N%	_×°ãòĞáZ(\`¡ÕGC5ƒ€-ƒîıW’ØàÄlY;eè|Õ.™ééÎ¸Ü‚rÍ,0§‰È¿?ıôÇüôœbç[v¨c:&WÚRŠT(à	’ÄSĞ¸)pûš¨¿‰ZP„µëŒšpÌtDâ¦ğFŞ°’I6ÚàÚ^µ ùÁPâ¨–KË•FÒlçı3X§]9Ox¯|Å†ü,¿Mñÿ Ç®H­†båaœ‡³FèÌJ6úŸuÅí$u*4qƒæ‚¾§D_Ï¾çÏÙ¦i¦¿zäX£¬ƒÈÆ¡¶ë9)W‰T—|qëÀ¨„=f¸ôşp~›Mf4]Š[€¾IÈ¹Sè&=U»Aw2ü´šQkäÁıÓ¶OeH´ömøäf„}±UK4SùßÎ|D×9°ó}ô.™Uû¢é™„Ëf¤fğ.‹ııª1”æ„QÀ´eÙ°‘ÆŸñû9ZÕmƒ‡“W4»vÛTI…o¸Ùğ*táß½´[¢ï~ñWâqYˆæ9ª½wÆßD|£Ì éÇáG³S>†-¦¼êÉÄ8Æ
)êPú¾PñpG<Ñ“VHÌXËõ3^e~jºkMÓ×0KæpéåêSXÙñ&š°[Ä¦å ğï\ÁK ïçÉ¢ša¯«-êÁtË–iUÑá‘™ ©Œ¸$P$E‘åhÛÕÌßoÈ ³tíÄIxÄ^×Ğ‰v´ë—cyÆ¡”W Ï|]ég‘aÊ»ø	ŸÛ¡g$D!2uĞ` qÃj>BR•z›6
)w’G³à6šhœOÅ	ĞòÂ4=íUu\VğJ‚2ÜğM94­‹î¥Å¤¾í­ırâÎ©»
˜+@tÀj£kC÷şTqüà‡Şig`¥¢ıÚÎã~/SòùP·IÄàOnî:ùÙüZUgêwŒ$ºÍv;‚9Êu•H*~ô	BNæMw{²_Øáeùœw:ÔpüK¨š‡óoé€®Ä(ÜRàî#©U*ş“å\–àŸw".„ä++`Zfgª¦¢,{ø,ÍßŠ˜™¸gÃÒ}	¡‹Û–’3y?â6bö1'"‰Ú°4B ;»Dlªì0 ÊIC»ŒP`>¹é^½tŠoº›Zw^™z&²WW<ÑÙÆÍó£%¯0÷3dŠ %-Ø£ÊÓsq.¥Ñ2:çÄqYÒˆ¸XF5GŒğÏXÚòuöqå.*Ã\£#Cª¸löx‘Øü{Ôªñ¥š3SX$LÜz÷;È“\ÚúçXúôëOyëÓH]ViÊN¾@i$Üòû‚åˆY€]3ÌÄôäëP£P™Ç—ƒµhY~YQ¾«‚ÑÀ
ésgA$qt¶¥CE}¶Š¢{ÖRKÕ²˜Œç@¸Œt	¨+häÓm¶Úo-/àĞ—Ù{³$.Å¸´pÌá=¿5ÿ/öce1PáõïˆA~>Ì( n¨†ÆãóÕ_ÉcôÌ·Ù  Â½Ç³«åÑ›Æ$=(d°+!»İ~İòi4¨ú‘e‚)Åy‰Dr¬AFUà~±»Šwó¬BsÛ*@šÖV¢çd-úÁÃ>‹‡y_×8[Äİ¾8Ñ½dş^DúàM®½b¬[ìQïI"u;5¡ÌRÌŞüY´[Ii¯'ÀBóÜÓ\û¦O?s8››ì²¥ÛİWîÔ~;¼]Gcl<ÍÉjäSV‰†ù 	´`D,w³ÁÈoáiÂªC)DFaW•+<ï±á–¦´­º´éLï$ÀÔÑ¨ ®^Fy²J½CXXhgş½uéA¿òæÛ©>÷-ì³ı}hŒİ¸ı,N>À€gşÊk"Nw‘]*q¥›ÜCGSæ8Ñ¢¡=pK˜½ş-µ¤>3‹\uûeç÷LsNp[óM'?çélã™Ê¨Hƒõ#­@x Z„:'ÈG^xø:óÎ+Àb«”3øÆqä†Â›%ŸÎ«îÊ];-Ô.€	NÁCŒ‚É†mD+ã‘Ëtµ0t[nø€+©A°¡
°s†¹­‰5¿ã¸¤íŒ¾‹Å&å™›¥üÕq˜ö£'§É£~¨Z¼	p: b¥‘m–`³:W“Œƒ©È?ÏäåohME¹Á-É?O”¾ôeÃ•~ºJ*M"5Í¥Ê‚}Nô[(%KÌÿyl¯q•&ùÅhçh¸¾»eµûÕ¡zÌq}FÒm¨{îÚ˜ß\eœ³Ó=ÈiüºÊ<Gb,­;ÌMºE8$.–· Tøo?BXŠ„‹ÙÇ ©,à>Ô_ÿ%!*)V«Âe.0ï/ä‡¯Ne;#5£\é¿v¸ğJ®_×ŞvJ²îÚµ1ìÿA®•9Ò"iî'Ò,nÿTfæ†­F/”ßŠƒ){=qPK³—1CšGş$¸¢yº3Œ–7VE!½\{Õ˜Ğí‘£õ’Xr”ŠŒ.Ám!úl³Ç†)Á]œu¦#³VwZ,§Ú1vçÁo®¬eDÍ}VÎ6	w{Ğ:àRƒ$Û@Æ`› 2‰t£O@ )qeŠxl‘\
s	C5óÖMXˆJÑ-jöÜØ.½m81Ã‡,»(eUúÚ<9}N&§ie}ÛºeÿB«o„Ûşéæş—ÿá/]8ç	Õ_|xø–¨.z¶6¶Ô6,óSs$à=…08è8•¾à!›’·`¶1GnŞ‡·JjzÃyô
£¦ğ1¾Y`.|~¿‹ÇT"låi6t†{F‚„ÕÈ±zEÙSyï–Áh0º B^s¹ºmt[`"yK_t,ìyn£S.Iİ
G‰öy,h:“›á"y*Ğ+¿	ÇÊçê÷^±lÏà‚cLÚgÀOæXf^›ìÆÁß‰jò'Ë–ªÓk%`G@Tä kv; }ù°óO*?ı£‘nkN  º ÇÑ à€ 3Ê¥±Ägû    YZ