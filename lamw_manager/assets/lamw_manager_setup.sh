#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1640877099"
MD5="388c2d0facf9d094343ca4b240f9e5ff"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20796"
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
	echo Date of packaging: Tue Mar 10 00:21:21 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿPû] ¼}•ÀJFœÄÿ.»á_j©^sÖ^±¡‹&å\^ÃQi¯şœ·Cïø­Ÿ´DáÎ[]˜'v»µ•QLÅk³½D}Ê‚*şëİ±Ë3/ÑçA]Œóïy•ì°•¡ä•Éî?= ?vĞâÍŠ9²TŞD!ºÿš‡‹u¯œToøS€ñ+‰mItˆÁÖ0˜)şÎõéø5´N×y«ùÂa¹Ÿutƒ£lMAÍä¼p—C0!ÁÁš„"q¥¸Ödhü2Ö8(x îş:ÆAŞ¢qíæ8V×7ˆ8W0Šwİ-^Ïˆá4¶	LïzKOÁˆŒi»Æ(M&³{ñÿtTk¿˜”•’³é˜£§íKåyÕ…{	tf;8ÿ/Ÿ=õA Îl?sô7xê™Srø?%2/)V«5Å¿ñN<IgknW;Ş-Mò[¯EA3i¨Í½´ÕÌhà°¹#VW3PĞ4’>Ü…c‘V¼‰<.]½F[—'Ã‚Aa¯%¹V³í­Ø¢dPAD1RT&2)9,©;6kp¼­uBåşì#mozïf°°.,“¯^ó§ ğKÑŸû¶LÖŒ¤¤Õ@ï.KÄ˜2ĞÚãcÑÃ„¨ÿÖÓõ¿û­ã«ª¸?ŞÔº×‘éeÖâñAxa¨7°İÉ›UkÍßŒe	ÏînVoÌßE§
ó²Åòc9G rç§æéãõ*E9Dyòi¼ÍÉì–›ì.&¾¤Ÿù9¯ÏP¡å¼­èûºÉ·u¦^—•¦~ƒ²¡€|;PÏ»Óå^½`¬z„¾KqHÆE’Îz.½Cix„Ş„¬XXSu²—•„¿kEE;fıIŒıÑ¨p°ÉÛ ÔÌHy±r—
+3Sš£P{˜5#¿V)ñ¨jp²Ÿbİ™ŠåMÉea²GÁwª dkóàíƒ/		›×:9\ÄzA£-Ëôğÿ‡¢oıc-x{¹•-!!ÉÒrL«×%ûob2u“Å×e4	<–™§ãBãXÍ†\˜¹ã Š&BYˆ„»Tÿ÷Ü$Ô{OK·íWÖô	*gŸEŠÄ9@TBÖ38Ü¸î:Tp[ÅÒ’§­o"¯ƒN	rsyÍÚ¡CdŒÖ±Ÿ¡]*]æ([­³º¯í§h'bCn–{>‘¡!+ÁÑÑ¦êÇü¦=z—Xé¥-Ğ
œ€ˆú(æÑ „*¢^¬4bò'VS+d
±ŠõÚ-€rÛÍÛ ˜ßf>k t·ƒôÌ@¤<NÀr&'»pm½œ%–‰ Á+UòùÚg6íó¤ñ­û<}ìì’ô†ÔéõøNáë‹Ôöjµû#±'»šPs»sÀ`“ä^1^£$Èè}
òà¼’ˆğïÑüíY¶®WK	wgÇúÎ»g&v7iå|ÿö^‹1 ô
½Õ06zã¬£µÄ×j1Ş:lr»eôl–íÍE)û|%´qÔLqÍNÇUş4f˜ĞnÕLc£ó%sßî.l«2 —`.
|:>ú›éCi°ÁNÕUÕ–gS>€¬Áï„”°dgŸ–­s4°ÚÎ :n­QæCÉ(N
53´Otñ¹)Â"ôãæÃùhù÷¥ıI±ËîÄQ,³Í¼fíîDrTOŸ´U‰ÂCušP—}DF¸×]’>±ã Ì,!NÁ>ÆF è0U''Æº=Üég§µCdú·.G®¬UäÌ'Õêf‰ÊíğÍt€`Û‰9è¦Ÿ¨Euiı{ƒp&r=µ•g)únôé…S¾P±ëã}"Ù/ÑÌ°V5#píNø:d¨­-3kY“G‘ç^XnH|uÒb–Œw€,ç*Á™Q0¹êkÑøwÁSwÁÅMt?¿µå^fw-ÄQ
l1Ş©ox ?¥¡„FY=ïtãp¡­“aÆ2Ã]5ïÓÅ%L’Ş„c¦Ób•„RĞqŠˆ‘gÕ1XŞÍ`ãş+V¸‰Í€í¼Ûvİe±(„ßí”“µcCê"n¶µ'†BÂæ1‚®UU¯õ'u^œÚ>·&?gœnfu$C£¯ËTò‰»Š7åûïèŒÏÍQşà,*¦Ú{Ë¢1Ñ5ª
™Ğ&~Ü"Ô¶9Ë{x(øİ»Æ+Úà€Ëhôc~F˜Œ…1§»å7¿í&n÷£,,Õ8wç|:cıbb@F»Ç—ì¦ÅÃáŒY&mß€¡¼ĞÃó¯“d¢•qnê-åœ´r£ç”d¤ıï"çwãZ°á›¶Ù#~Ø Wü.…jª·1¢}p*¸Ÿ{“å²,ˆ*˜Z¹,Õ§€h…'pôôÜ¾~*àÌZT X~8.7—•1üm#,®Úò¤€zH’N[Óví3­ªÙ9|	µX—4‚ñE+J/±¿î© óö¤WùŠªÆä‘ÒÅöî×ì: ÏÚˆU£9ñŠ+OÜ[›C_€Úê=Öóen\é/Ffèí R7Ëß]fás•hT2Cøn£t=ö¾s¿õ>Ué%éß'ºê¿çìœPbš F<ÅÊ©Wf¸¾¶Ğ·GzYL2šL.ÖñÀ‰ŒŠş$È(i-r ;sÆÎ’~„€Èµ|ÉQNÎì€‚|ı‡D5¸–—u6tdRÉ²ñRŸ<Ç»<Ù×êQî¦ªé`yö×¯'Ø^,áGüÙµ„ú1¨p‚_b›¦C«ƒ
§´L¸­vk³o)‰"röåÓÓvf'6n…-»tô!1;Òô?ÁfMô\Ÿ¹ËĞÏ ot
Úk†=ŒQ&<¤UOÏÙ?|ÉĞjı±°¢5ÑŠ£uÂ;ºÆTUş@ğtx-ì Áõ„°f†"Šâ·ÍV¯B…©æh3 ş@—«->el ë=}cÕ­ªë1W7*Ş×sı[ÂÔ^ØÉ;%GcF4Uf°ûiñÉ~pº°ø´ÙT,ê°Wã·«F½a%ªqÉk(z†q‡¬¤•÷"ÇÁíšÿ4vIy·LŒ1³,é¼PpÇ§öCCŒö–Uˆ#Œ¤Ös+û±¼…VM±ùükI½0Vp
²'µE…6Hoëö_7ıv­%—ó#~€;¤Íşò[±².{ãP¯é’f;;æ:šëFÛ ‹°ß[¿Šó©†£w“fbªÊpYºA6¾­_'8g÷÷v€T…Ô×'$ñóZÜ±şbb­“kX¼¶˜øWÚH+.@'HF[lOfÿŸ¶&Å~fÖ“%ùSşÎi£sšb&O0Ó>f5”7–‡?-1ôi“d#+c [ÅçıÂË‡¬îâ&BüPÔVüTöÒ›Ñ	gF½ŠKv†¹Fø	«QCŒÔ@§
`+à;–,ãvæ"— M c²Šÿ ¨­ÃÕí³ÀTK«ù]?Ü›§{¨k}!q¬Cœ#!Ê¼@°şÁIènßû‘€ùXzÓYñÀey¨“K~SĞ=âşˆCXÉÿ:}ôuò&…sı÷
¡!©ÌZÒæ¸¦{),ĞtZ¼3§VıãB…ª],ƒæ¯1@O…<zø¬è‚@íÍé³UtFö¹(P"½Î¾âRné?AÁŸÕÄ4±q\GÒÆÍÚÉ*m-Zf¶*¿ğ»úµ<0ÿ4 É€œû/ir
eÚÚ4Ó™Æ;VÉ1dXSÅ½I‚y)ğÎµóü¢úS’œ!»7j°Ì3œ\ÑÌ¬ö A‹nÇGTc’º2u3Z{ÜŠ—úô07Æ†kÀ„¿@o[dc°¦šç]¦	ÅÈµUİ˜å“mÛ3à.às]C›Â2jK¦dÜ^´“òå$5:Š1&K½%ÿæ`¨} &{ÆmğzN²Ò]¤ÒÄÿP
¢Ê¯S'3ë/:¦Ã1ªæ©îÙi=Õê…*^/Ed´(K ÿDËèî¢õP]Ó§W¿Ò0ûÜªAÉ†Oë ›‹çãL7 rËÔàÊàìK€/cL“ãinKHW«zîvûğ<#Çª™ƒı>ƒ´wA®9µ4‘À6ÏNø†m,O Ë¬À8ğF]tÆLÄE›½1Ãï¿Gİ˜a>R²°-J2I6M…Wå1u8{oÏ‹îA‰Îqİë‡iL¸’ğ75øuŠYT
çÎT¬r²šŒ®7[ÃíF<Bqß8‘(ªD‘íhËH`^ï¯¡?RôÑ„›m†nÉÒR#°m§tx•…³PmM`IáêöT¹l•7ôå2ğR*ÒMÊt"`ÅËA†˜^şîš¹FÌQT$us*—iy*ßªı3ªh¡È6`M«9ß?	Ê 1]¬âîCò£=cşâzDxr3ØW°÷Y<¬hªÄ¶!pñüzÚ~qİ¥X›Ræ¬şØÙaŠ7ÙTÇÃ¼5¡g_´çµü>1·p†5 C½ö~k¢Ÿ¾b	ˆÓƒÄxw?èö/kÒ`²N^hOXÍeÊÌ|÷[¤»u·NÂC£®%#`v¡tÍ«´ü÷Š«¢ù}z§v°VŒä­4d¾•´øxfû’U³şD]ŞĞãÈcì‰§”Ö@½à]‘”rßÂªvIÉõÓ[“EÔÚ$¦át|ØoI­Õ¯YFÄ¬ï±H2àÊ(@óò â5äì[?ğˆşñ}(³Dj¡8Y0êN¿^qı¶şN„ã&Äe¥,‰“Nœ·îßRRÎ›Üïˆ_—µùlF°ËU>íqlş3kø {`\Â<WĞÛ”H›‰v1”c%hÔ »Şã†ÃóèSpE9ú…"×v‹*rb ¶![œ²÷^<<Öpk’1£±'Õ?jX¢‹¶Å•ì—ö|€¹F'D~	yg9£RòŸ^»*f|‘—Ğé„§Ì=
xÙbù¯I!u)¥SÆVr$œ @ë¢ñÃ]´nß:"_B>Â‹“Î2FXvı êON	%úİÖÛJğ?u)›5îN–œY ìMí³İ·Š”­÷‹~ÒòôD-¨®¼2(„Nƒ~'Äï±ÉtúÒ[)¾d[)!a¢—ƒœõ $ûç)…ö½¦×•¨}p‘à½.^É•©†¦$]	ˆælT¬Ú"	F¿É¿Ôtâ$gÀ8f#t@:Ã–FéÖØÆ¡d|¤nÀ·fv@™ïÊÛ³WÈ×ß&0¯ÄL©îÓ£Û$RuË›zèş?ŸÉÈÂq¡Zµ5<ø]ª¤uşvŞë|/èDÙzÛŒQIos!¼ÏP<ß\Í¶©4ciÌØvŠöŞ#¨.§¶è/l!‹k!ŸóºÚ¬Ó‡¤cY·±mdùC‚¨5Ë~$1Ohpg¶÷`_iÈúÊÍ-£é(ù¯h„z¹ßÒ‘4Á#€	îJë¬,Ë‚*é´ºL~O¨^rÏ5±:²¹Ø*ièƒH§M%%æ7~D¤Äq>Ê‰’ÿİY'¼ã›n†ı¢® UÙ>ù—[ûOè9°÷:ÓµFMÑ•G¨eEPÂL±< £š7ŒrÓÌxJÙ’J»ŸXÊ
`J£w¬p5“ÆdAsíõºx‘;È¼t&„!=ºÊ	=ª•Şx¢áXøñöD¹îZ\ŒûS‹i¼
YÓ£ä
3¬æÀ»½d´Ôg"ÈN¥tÃÍ¤×û7²ÜaÈ7İİ.UU±´S—âu˜R³¸2æz[''£ãpÅ::ç ãuxĞ™Âák4b…~’¡¯<¯GR›TêüFñ‰RÌû]2=6Òn¼Gb™…ê##‹ŞfÆµ.¨sRõ^à›(œ"åqß°’wËà ›†üíñˆä£—ì#WL°5L‘åßÊïz„!I¶ùd(š¯?ël…oBPŒú7G$öÃ¼æş\î¨· (ÁÛ·5C˜ÕÃ=[UİåW—$*NVÆ™ÎI·¬¾—ªÆ)ïd§aÙ}ÜRü÷£‡‡[„-Õ¥ŒC¦ÿÃÁcâ$(¶‰2P5]šå“Ø‰J‘ì©VOïè×[”£ú¢l¨.ç?ËŞoä™£à†u»Ë‹õç”3d-S"U×Gõˆ~ /Í®ªûéKªÄ’ÌûH=£ËAYè'ÒË—â¡­[IRÇG9?€5<Â½íÆæªù C<³¶9h¿>Üii#-g-[ƒT}¨æšØñ¾Š&š¶	‚ÂÄt*=ÓAÓíEáéÇCı6¦Å'ùˆ™rÅšÑy½®b\
bp[:VÖmMğ?Ptö>D	•dgLo]†ö1)i®cÜÈƒaÊ1Ù‡ûşTu WİöÁI °wb+@×ç‰Z.e­¬=›«—	I©_Cc+’3r.,0lÄÌœ#DìÁkÆb»°È›Ê¨Ié÷€ÂuöÔã˜,é^Ãa$è¤Pâv‰ZÖb•3ßz-¢QFC4š:J-Ë`êĞ)ÃŸ ğ6¬zFPy¼‘ÚÛqD’yw`b]2[Hy;Í7OÛ2ÅVW2Q«ÓĞí4*7éğ÷óôBû³´§õŒçiÉxcÅğ…76„Xö­9ÜI–yPªræ-‚!±Öá{#lÚÛ
e¶Å³>§VôD_'°wérpA‹$k›$×TfwÓß€[ì°B±‡»w>ğ‚@^Å&j»êd5¤ İ¤5 F#´E»¬«ûs¨[™´%¹ôÎëS„ûFn+Ú›C´!z}€f_B>˜õÈ6„WD{¥Cò}w\B(€Èà?›6é_˜V¼.ú.ûGZôßŸq¡ùèáOÿ®0^`®ÜîZË^75­LoÑŠBÈ£‘ø \Z˜&-y™²E$E“˜’ÇxºSnøıfeËí£‚dşåRÏcˆG%/_õğ`÷ª*˜³½pŒ™Î$Ã™ƒ-Õ†ÕoØb'±UÊÊIÚ2ì%yx7§ˆªò½±Ìnfz}A‰îÓjÓE4WÂPv	Íš´u/åÕ¢¡-Lñ ø‘7YT
Ü£eåÖØ©KBú¤q1ÉûléTo˜sqCC˜Qz¢ÉTIKA~®§O®cióê…!Z]×<ç›l>ù,>T%©Hvym‡F¬§l!µ5Ptü9lJÙÇ„q»Æë@³<ájƒPvÖŠ¦l„ÿ9LVy!:µ9*ëÎ’QÎ³ÖLº``Ø:Lƒö-c°…sãjtÑv£¹0œøİ6xŒ—•îfèÑ²I25UU¡…¥>DB}æ»ÅŠ€Gö#*¬¡äa´ù=ÆÖS:/KF6Ï¸­Ê›ÔÖC7˜ï•ğ‰¤­NëSP[OÂü:ªÑ`OOs½—qÙ²Ó‰EfJ2áıÌq²¶´Ø^«#šÅ;S“.sû3îÒóş‚Øú±B7~ó†ú‹pBÂ’~2­Hîùñ¹èmˆšGFÛè¹‚’Í´º\“Ğu4şÖİôdœ/%åÀ”Pı¶{çd°¦1…kŠÛ=Ë /i:HÚMm\ìô¤8‹…Ä…£ë¢ƒÂSÉ²øf^ÆåÉ¿i”(kXHõ€¸½–
7¨ºcAGYí,xy¦5…#ä–W•}r ÖoV½t±(§ÍÊÜIı2¬ÍO4k\ÙÊPèij®µT“ç}4œloMµ)Ä[A=-Üpù™ñ¿Š\èï(iÑ3Í¨K÷Å>{™[‹HöŞİ¾FÉo¤J˜øªP*©9ƒ:ğ~ÃÅÈl_å£g”´e—13p4-jD˜·s…Fb%¸6H§î`LŠ“0z0¾cï³:ÏØWcHƒù¹28UíÙ\š*qÅ5Ğ™;J-Æ–¯'¿_ó^~È¶ê‰;*RğZjx"\nPãdéÄ_òoÑ—«¿j[ ğÀ]öèW¡ï›í«âÖêÃ®x‚+-càFéqÔl—ßÂµO¾raùå’h%øJ’zçØz¸˜U‰Ş‡T†°9”QF†ÚB:w˜jM—ëX%¸Zó|aÜQıe½Q ©rpxo[Êbò,NPÂÇ:Örp°ïËÒıü·ÏôZˆš÷i1oÎğ¬;±©</øy›ã“ö 1ÇÈëÆ¬NÜ¿¡¹°»u ¸s™†ú_NxÉïÙ9Ÿø]ë»=#¼ü0µ”ĞÔ šîŠĞüĞ)]Ï(ŠëËdÌ¢–ë‡d´Á W5Ç}lQÓêÊÇâ1qÕJışX
l!ÚB›ĞyÓ´.!Wº~#°Ô9¤Hš˜•-O›±O×wø¬ı…÷n±ò§¤.1Ë Ü{ûP¦­{ßÀ’C˜–ÀÊqèbc…™›÷ áI†&Ö?µD„léu;·O!;7DH"K.7€mÄÄú¤(KÁ7JYí8iïü¬]:mM
Ôå‹ìÃáè*¥«“ùg}VìIa/ZY1éX|ğ?"\…u“eoõ·“¥ã‹8åıııùŒ'qú"Ô¶îhTÚrø~ß,&³i»¿iäšu%f«
Ïuö>ßJå±x‘ù5T{­mÉUÍÈbøM#…Œ¼CÅÉ:C±#9Ê(<CÇÆK—â,sßK•‘.UëzîO¾Gsÿ#Ó•î{ˆ(¹ùóıfa$õò^ Êşã|òù>iŞ¤]Gımö¿hlpb{io-hN›-ˆ”!®aA*—ïh·0wş¬ÿÑšìçÙVÉç—ê1&b;¡ñ¦dq.é˜¿‘´şÃÌê>ÂK³R]r;…‘<ÔpOÒ)›6‚SÃÛc“á
ªúµFäŞW¶…}2_ªY¾së¬U\íÉÂ u°$Ç ç7Õ½O.	—dlû…=ÌV1.@ü…OKCN¢-6OBbè}µï‚§Ò×ö%*±‚¯Q'upwŒ
Ø^¢ Ÿ)‚<÷×B/<w…%vËrU1½øÓ[G”W…c,]}¤ayPcğ4ÒZ´÷b}¡UPNGò ÛŸÚBSçÿÇù<W¡³`:ç7r÷«X&É5RU ©Pxµ*dì˜—X;ş“3âî”ôUnFÅV$hU^	µöœ2«ú*Ü¬jÉÁœ©÷ajN½gŸelòå	¾‚¦¦)8ÊîKèzî'²Ñ‘ù(·Æh­
×oÿº¶õ/†í¥H£*†'ÙùÂ< åQ0jÉxŞ?¿‘…ı‹jc±¬<?µ._‡ïW$‡Cõù±ã«›çê—=k•4­.ŸÊ£daŸl¢æè(:a0`¤rªb²¢uø%âYdºwXAÔHÿ]ãÿár²-?mã(ğßa¾[F‰ŠU‚8¦\’“qãtÍ4‡«ly´>Açr3Ñc)EŠş8u§*àÍöÖ½Y½ïW/ò]iTYTƒÊl
šî´—œxŸn—ˆœ"°*
	'âë“ğg @î[~ø6½çÏÂ€ğÿ‰ê¶r—')ú©y:Íß®µM€MB¸¢ûT®ë%¹šâÁµÂZš<ÄÄöM§3ùÕè\Ó¤2İ,qÅí*t‚Ó£:°¸üFYºrŸıúÛÉ— º>ğ»%ÔQÂ ?ëZÖEÊøì2:0 MV†,û³3hŠ
JZR=‡GGl
Ê€ÍÍÅ/î…BÑ¹¡ÒdUv¶	¸NĞ‹N~‹ç¯Ö9Ğ£”±zãa•LW¹Y&é¥æÃ=¸'qÈàÑ_¡,|VŞm‹•:3°¨fäWÄãôªLcNg˜Ã)¡ğG–òt¬~ì#çhğ‹°²‹±-ğÍær©–ø8ğôçœ|U¢é%Î„|éÁ“4É‘H
ú²´¤éöã?©m §yK¹@Y	òÏªG<şj^©‹Fyá¦óŸòêÍ£ŒBÈ—wìíÚ^VJÙMÀû–^KÆ<.§Q¿æê´voÆyQİœÖ[ÿ(S•ªfÍEsÔ\qˆ`©ˆÍ¨Ÿ"˜¸R«„^»@ï¶ufOÔ ^´ş‚éhØ†_h¢—8™¯éğ,Ğ²±!³Òi1ğº¤Üú½œG³=p¾ÌóüáˆQô§lg¼¬«ä.'Åt¾90­İl ô"afdüS[pÌ«€8!yÄ9ˆÆ®zÈ”i1f£‡´¿½DÄ3ªâGyÿŸrã~c\R:£(rÁo•œz0kšµü–¹™ÎÑ¹™‹×p”ÿ^ÇÄĞª4GkTP],õZ­Ü8f6qµ{ñR„ã=LõO³ÎŞİÈ†y|ñÌmÕIuÑêö83TÆT÷„q0ü[u¦Áı§ç"p­Ëæ Ğ™M oş¶€#‘Áü	Zm'.ˆªz{)'EZÈÕ"Ï’Ç(½XQmÕotiìM6‚ÃenÃqwåï—<pX²	pCößHf_í§‘óKXÊ>Ÿ\8rÅ‰À¨p‚Rğ¾ŞåÊ”µ­•|.d¢‡:øÚdÅ=1´Ê‚ax±°¸¯#–ä6EPÚ‚i7VXÔdjÅ;Go›¤Â¨í¸gˆöz9$°Ü“H îY?	gïU®šG56Y¼™ÄNlàŸô½íÙ^ì`Œx©¬2cj£1”Ù¤5Å›;g°´ü„ÎâÎbùÜ¢6µg57„Ll y_YğĞ¼¹gCÃ÷nE}"xFR /fÆãî] õæÁh„Ÿ%n)dŒ£)5x¾¹AÍª\Êh½àó×% |ä	ş‰ê‚??nõ:%ZcÓ{œÎ½}7Ö7|&¾4ÿÆc+vMRiÖbk
­~T­‚ÉÙªÉœ©Ôıòr¿­_4"ËğªPY[k´Å×$é¿„,(éjŞX€¾$:^­¢<úá.ğKaÇšÅi¥&©*"ê1Œß«È2eÊ”åƒ&R:Ò‘KhOä‘¡Ô}èÿ…¯nÜ”tš±*ŞB÷÷j„K_Š÷Ü‹0kÔT>'h sØÎ…âqr¼0ğI°?şØ€şç÷uL™chJ" ,DI¾p6ê/0#“½úÓö›Å~0%#îÒ²£ïù›öj£UÖRŠ"OcyT—ª•E,.yÚŒÎi†;F¢› ÈccE.ÎIª¨¾.t•2—&6xMHUWg[Â.z$ÊÀL‹Dåx”éº¬àXşjº"•%FhãS¾)m`Ì‹úŒ.¿FH6î1u" \Š+,Ûä&­XhĞ‡ÚF’|¨÷&İ2†H;ÉT$Üüª@º`4'0ê‚é±|ør1ošÙ¬ÔUsØ£’¥Y4ùã!‹½÷–Æï=-‰¶ ìø¿¡Ô±"¬ğv;˜âMì.š„.LdúØß»¨K{ÊçI´²ˆ¡öıL¢¿“ñâ2ò‰’ÖÚ]†ZÆ.şù.¶Ì·¥4§©$ğSÑFYØÃ	…õ…aÑ‚8’¬¹o>ğĞi?ækVáâ2O8ªtÀ±Šè5½d“×Uà[íËCàÊó5 ‰H:zœå„#kí­w×–§)ë¬—$WõØCïßJºÇèÛpı{%{.ÕÛ,ìe¤'„„OóB8\ÙQ·}¦ 8E5m:‹4¥9<ÑğÔ‹1e±ÏÃFŞø¸úÛC*xÉÒ9ñOü]"0•Ï’#ŞäÄw—Ù}'Eé)ü^…+ˆ ìì4DF–©“#sâşkÒC^:§Í}ƒÕHañ'ÛMâètU—{,BÀ!ÖÌfÉ:³K ;·Im"$ôCzùHÃ*ÈâÒ¦‚I+óè×jŒÎË¶Ökï>øçÏñªÇ@-µ¯ÊKÁh˜hU»cSƒ-ê=ŒÄ1r8Ëåã¾Íwl·"d~B]Ğã©y†ıßÖ?¤Ùâd·Äˆ%v¥¥‰õ³ô™…\5$ìc3SÉtÕ÷èBœû×÷Ğù6dót’˜H³ÇUê=Ìmô9•NÄªÚªgÎ‚¢ƒ¯—¸ÏìlÛ¨T»fÁ
üù|>ø³CW h)‹pÁÇ¢â†^ÃM%¥ş[ƒ]w{ç-ä¹YØjÆácá®ÃâW;Ô‘RGœ>º[àó±ÏN°ÅÕÏ€½©Åºàûb&33yKİ„*:küæ5Pl7A+4.´5Ev=;ØFR{õQyõB~t°;À[V]§üÑ )5sá†{0ù[Ò½&°ƒ8Ú¦¯ÅÎó³= 7ÕLÆ²úÎº¥ÇCò}ú¹2Ğ(ÅKØĞpÇwAÈ1<©Z8wEnW€iÏô¹DŒĞä“Ç"'i•A”˜}üLtwÆ¾VEàÈn›i³9a#¼çøp[w NíÒ¯j;3FÍ½ØŒ¡K‘\%g\“½9Œ/ÑÿÉôäı‰ …Ì¶¹şO,Y1È1X~Cé%•ŞS÷%óƒT‰ÑÜáÆ(y:5¿SY÷‘Æ#Æ—””ç¿Ğ¡Ù´ç9óO’¼
(Á@bEàÃY ïæù¯¬±OĞgâ)Òƒ+?ŞÂdtXc€~<ƒUÿ\ÔÙôŞLî6©É½rdÕ½î­À¨v|å„;l–ŞJYáŠGº»:-&loÜfxëÑ ÛåTâp29ËşGĞ‰Xœ"fª¬NiRúîƒ#†ò¢ot	l·E7& ÑşJá³®;V!e5³ÌV2æ4˜E7"
§Lİ/êşJ¨<¤ˆ8VÆ_¬Û¾ö-o
ò½^“Œ0aØË\Y‡­ĞM»lsæ 2mÅV= Ó«D}s,8<îÎ:çç@H;zÓQ&„–`1«o#bÊQÑ[>'špSåÚ_pôë«¹Ù°±e¨{ ¬6Bw˜êw½è¶ˆÈ	ë¯í-'¦ÌÚˆ~ôŒãôû	5YP`3İh%Š‹Æµ{ä"CM¹./¦V=Ìák,¢¤Àkkû»;™I¸Ğ?²AÚn¡4„ÑIõW>™÷`Ì@”U!„"®\ ~SŞÓÍM›Vv§€ö	wR}ı0²?%L6CQ•%5¯ÆÂvß„·#nl @Ä‡ZCan”ci;Àº&à8ˆ‚ôzò¥ùÅ4ŸĞÁ<z0Ä/¤tÇïÊcŞ9hZ´>Ê*mGTq<ºûêõ&X›zzÂËwûêñØy¨TÒ»Mô”µc¾Sï ‰ 1)í+8JV3|Mø¾qÂƒó>lT”Êz‚öÒæÖßd¡r,ˆ.†;è%";'ëŠÑn$©ê±YO}™}8s‚R…;…ìE+é¸èûZ\(¬‡hÒGM
2Ğü¯åát‰TvùÈqêOgˆb ¥êş¶C‰
›Zµßó÷àvhóIA¬ó³‘ÙôUYÒtÖ3šÜÈz“¨}ÙÈ,›XCÛV‚ª*ÀMs	‡LJ¨€ûv#ÿº‘g§ñ›&Íö•;øãÚ/¦{ ‘ µA§±)¹t™ğH_ÆQ?»<¿nFÏ (´°6kÂ ByJX ¾[hQ!“é^’g€i!µlĞ¬ı–
#ÿ¬nVÖıj1<§'Çí¥ÑçÚA÷¤ñ*®½úè|	lÎ_&õ8]ÂU¥®wûˆ”§ó¯Ñe¬Á¦VpĞd_âñ©¬ñyı¹5â'¾  ,ÑcÙºÀA‹ğ­/$ââ¹ªãWKpVı³gˆÉnù‚Ñ –“‹¶½¼•½«²Ì6v—§‡ı@ğW•9ÑR3¸”Ë†£“ßP ¬§h
Ği¶åİÜ~·éAÛÄØ$y®:ßU[i0#åÒ3WEc¯Ügª¨€ÎÏB¡«ÚR»òyŒxêSƒã2§IÖ³!2½µÊ»Ä ‹¹ÍÀ‚µÀ=ÖRxÛ„â!Gõ¸~ÔÃ˜Æ´….I>ËìKj÷K·@ñän½²Í›@á¨÷y‰œ!“a÷¼özA¢à7Cç±öÎ>(Í!üX ì•(­îCÂ¯ï§³ÌBj.bŠ£E%(Šof1˜²ßX– ¥qòºlFîáp‚zëû	£Şá%Íü
.pv¿®õŒõVE²$4§µWúÕIÎ*t¿¸Ô…šó,9Ák/Û0°7•¡D¨e¹Š,1JŒiYP·Lçû1ÄÙ<ñı3»|±ß•ÚèA'çg”«„€êÊdmºÖ”ç¹­?iPŠØïEùAT2¦ óç\ÍèVM‹¾2¢YæJCÑG…$7+Xùß
“5ëg£¥6ä,9YÎ¾GÃ8€KíµŞBoĞÑBŸtÏ8OŞr3×°ùÑwb·K|å3R.ìòbˆï¶»›Z(;ˆ®cfÎ´aEi%zC© ó&ä/ô5;ÁHĞÿ´O{Ä<‹ğJ_y|U?ñÆ*;±br¤ŠxI¡<Nş¤íáû²Ò=‰ÀÁ"3ØÏáèGgĞ©§tÓ!$Ü)ïÆumìÆm¦*Öƒ¢‰v¿·Ç…5LˆàgT£'Jlo‡ÀÌƒŸ|¦C]U‘:¬œÖ}–{Ù–ª€­}Ç±xëÿ—Ë‚UTºû@,ê“0÷ĞKOçé¦tÂD
ÍÎ‘Ê9«ˆ¦/ı¾¿½VÔ§îª0ÙïúJ€J¾°…QfFæá·mÀ ×$‘2§t•îÇËv‘iBı›ãrZÿò´Z\ñ-]l}*­&(³{Ô¥`aÀi«hô»àW>ÁËú«Ë”y„¬i‹Eä…¨'”8V·àI¿Lmº9@wK¦»´Ñî´©¸xwA÷EÓ-]8ES-AÃÔ˜Úf@b#hcñÜÜ×“@WE×hÈMÙ€ƒ5Ë%é2ab;†L—¹¬²3Ş•íè!Õ¼¥3ùÇÉª¬M}Rui™ò.À‡å[ÊÎ~5¯:„L¬ßY‡Ï&O#™î-4¥8Ş7aÕfıHFØ\äñ¦Œ¯˜Æp<ÚKOØÿOSô»å0äàÀ#PØgÃèm‰ â\	·ÃwÈ¾%J2o:i‰â04*]„ú™Ã©;U»eŒaØ+@¦Cå¿¬Aõ°Ã»¯&+jCƒS®éS(æ™‡…_Õn‡<7‚ˆïfÒ#ŠÛ¬ø&=UP¥$“ A±Êæ¤ÂêDâEVĞûürèÉo$ÆZ<'v`?·-©&Òóh ‚Ö\ş†5Ÿ¢’†Q,ñÒ[x`"Üx ÈõšõÉğœÚñôÖ°æ±ÖÚĞşW"ùšêóSëŸ@>ädàĞ6×RB”O¦&¶–v´Ò}òRÀ›¬à;$¥îXBB•Gtv Kzr˜rv¤ÓJù§çQğ—##Ñ*óÀİ7È©x¨Æ/·Ø›L6_¸Ù€A5tX‘íû9o¬¯şíÁ(úJªõ-éj÷«æ½™Ú×ò_„6I ©¬Šó°^QÛŞ,=—°Nâ1"ğuÛ	ñò×<Işa¶lNIèW‰–ŒçÊOœÇZz´:Ê´¥f9u9ªN€sta»Kré¡»Çr†Ñ…¹.âfÌs‰	ìûqÏfİNJS±:Ìu:È<ŠŒ2ÛrMĞÿf€®w©·Õ”•Ijy<bàî(N_¶=(/S÷úí#<:Îàö3¾€t¿!ñkıÃñ›ÖàY˜552“?íaûşNWx£ãfíR²ÿı3/Ú óæ6¥˜{+Ë¶ˆxP’y0ôÁ†LÏ6yS²¾İ…Ùßå:¨AËœ±"\wy8ÄÁü\yµä¬ÙÍ‹ Ñ‰#:#rÀRëiáºI@aj£¯	rÆÒÏZù®%¨˜·Oîl	 ræ'Ç!6 şï^(0–¦ó%¾lMÖ[vØUlÒZJ»Û~u—F*áÈµŞxBÇ‹×V8‹9í½)EXÚêâ+‚ Ğ ¦šˆç=×½~fP½+ÄõÊ‰·2AEMj‚{<Åş)4	ßÏ/%B¿bp2ÍùAº®_KJ½àµÁ5²ºEå•‰e1/É¸ç¥‡$¼¡Lá"wÃLÓéÿg$œY™}l:;)‹&8µÿueg&ñu?ÀL Iª „À¸ô~Üq(…½9BjPYl»N¥¢tĞuCyIkÇ¶>›‰bö‹‡î5'=`Rç/u`W†¥c¹¨5ˆl‹Öí¢e¦ÃíÏLÉ°Ë3yJ‘O7u!æ X2ãYLIáò¬,êÓëÚ'…&eLm|/( FK=¢U;ìF‰¾J4ß]>Vµÿİ¼¡ÖİmÍºœİğ¢ãj»„ª857¢¶úp(²3LÀed…jëÙ’WlÂÆó¾ôÙú!¹³ß¤U‚ÙäÏëêdÑzLœ E@åCÇbÀÙ‘íÂIa„ìšğ3~cfWÏÑ¹…¹Õaß¶Mãè1ª÷×xÈÛ™#g4Z\n]?è0J­Ó´jÿ-ƒëê7…±ã)š"wmÀoX>fL]gVdh¸ØšÿŠ?×’y%D^Œr€Î"ıêøiÔ¡rUDRÏµyÅş¢½­† êêôŸ*qÓ¼zì®¿r{êK1ÓÚŠšõ¤ÂÇö`¾+@ş!Eˆ÷rB8zş§‡[ë>P½²TjİÅãa¬=`(xhN£¢4ÁÜ*L}äµ§­É[‘ºVj‚Öy5›ËóO¥¬ëçcÁ‹4­ş¹˜Ü2ÌŒŸ×ûâc ƒNò	EÉâ|oDnèÿ§ÃŒÚvÉ”)×¥õıÈYÿŸ ˜œQ@+#·e56.¼”‡[ÏT}!ş ›ğõæeÔÍ[Ğí©CVVœñ»c«EEº»`¯¶+Yì;ÇNN‹ëôÁgptGój•÷D¢ZŸ›n2ArÀ,İ'-éPİÍYLõÚüêŞıDÿ›µ½¸>ÌV£¢ÿ@ÅKMM±h©Åu RRÑl4 ½^¤&“OS–ÌqÌõæŞBbß…Ú
Šp<ÚJ¢ÊİkãWÒÅrkº™İ'›™và^R wÌŸu'¦óH~L0ã\¥İ¯ƒf·e1;M)UĞ³ºqw1™É*	÷D[.çœŸhƒK3§áX–ı‚üöì¬NÎëÈ“÷<ßêfèÇ>ğÉ2äá+É­Ée¥çY·ğøí_FËîRæß0uí)sä6ƒƒ^_Sî¥5ìv)+õò¬Hgr°8[qÕºmÔì¿ù”†]™X3Ÿ5â’2CšA½ÿ³m*Fµéõ`„şÃæƒƒ¾¦Dìœ¬ Œ.Å³zãC3´¹¬9~q®dC~£Ì½…šèc=i½WKsœe¹qğëĞİ
ˆ‹MvšÈø.•Ãw÷qXMŸÈœ³u<ã-zÊY åyuQX<‹ÔÛ	y÷y;6ÒÈ ûYİÉs/ÿø®Ä÷Ã² >6ı
ùka}ÀîÄ)ok“˜9ÜÕ¿K¨4cöhÅ(Ç¥©iÁkïöäi£rœU¿¸–2İÄÎ’L®s¡ä’M4ÍİOH7ŞùÈVÔ"†U³á¶¸[õYwï‰Z<s9®´YC^»‹¾ãŞëyßJñéş^+–¹ÏC›ß˜ÜTsrRÚŒğêCPHJĞXâ¨ Râ{|ãÄŞøª^ãf“¼ ÑèçÜ“$r-BkGÍ™-,åŸ/1:‚à+ÅïäÈ—ÕE¶zGO^8>
ÎªÒÓHk,ºŒìöIÎº’Úü·°·ûiM˜…]˜g3
™.–;g!–Ùô…%“2ódû°^EúÀöƒxQñ)Fú®ßréÈGrXå„M1ÖrÅEzEÊ¾„9%»’GêêôyQùwŒI,R0<*§K¦&¾¾/bò<Uâç{(ØßŠ£r^qİ Òc.¥(6uíñ/:…LWŠ(Lò ÑòGxßÿQ³ÚˆˆGË–^$gŠ!È·-eÂ£îe^'‚d(™\ií)‡„sãÜ¾˜¥k½’½º0 Iğ¶2’ÍÿFÈŞÕ‡)ì¼ª©9ÚÚªP\Jü†h'¬J]›g²ıt©:‹½"“¡)5Uğ}”ï¹³ŞœY˜®Ö%¥²²RÓ8i^é¼¢8¹?œ‡fx¢6ËJ]ÒiB
uA	ÃEÉÇ±)à`0¬îë7 mÿ5è¡ÖJqH°T‚£Cî“Mz(Ò¦›>T0¬¿·ä;‰…\­„ö{Ó+‚ºÒ	¦AqdéóB:ªğ—£¢Ïdäjãâ·Š5Á7ÚtÎxgğÀEs²Ù?LŠ£/€=‚l´š£î-Ë–A.§É3|cÙĞ|àOšš½ö½‹ *É>]ô ›”-ûµHÜEÓñ€uÒˆe1Gá›ÜJáş¸ï!á/3ÂàÂ ÍzÄz“šµQÚMòÎMÏt¦&Hô8äòNÊ?ã£!ğQ”Ö2¢Ñ.ïg~»
ŒXi;[Dî†GùÍ?[­´ãå/ªĞ’@çê İ 7¾o^ºgb-fc)˜XoÙ=v=;Ë§Gƒ¼ÖÅ÷îr
{“AÊÑèzS·.Gî*upPé7€ÓÔ€¤ü·ïŸâ‚Gò@Ãkıá‡…Ê[«r÷û°ïÖzãRÑ	ú€À@ıÏa»A¶ô u(ÈV¸ŠP8F!À™X«ÄÍ:‹=ªgáuÙ[Aé¼7=gk¯ééÊ”¾ôäÍíü†¾ğ³ˆ”S±,N1IêUlCÑ§(¹&Ü‰i¬¤·w\²ÄjÜUÌhêCI¦ÑSüµÎB Z×æqÔòãjtdŸkjZ+	RxŠª´õeïÙJæ‰aLò.­v8>ëçx1¯¼÷"äÜf wå5Åb
G¾ÎÌšÒ\L’1İ:Šş3¸è½…Äÿ‘ «zÜ¾+dñ.*XÉ%no áöÖ.¾îv@ê¦\áƒ‚šÊµW–sle.ò-A23PÏèãù!qõğ³xrÇ{ÀƒšçVDü ¬u®«–C@Xÿ›5½‰îÕb<$8'%ïÉöÏİÿÃ=é‹Ğ³d ú®&T×%×çéì†‚ŸÚ”pÒ‹ñXĞUşíëMÇ”ÒºX¥`^¸øùÒæ#~å†-SmÅ½‚5?¦>*3s±¾ùÍŒq¶—5+áÒX7›Z;€£tüq ‰jÇW¥¡@ÎêÕ\çj¼6İ+>b÷Üƒ¢2ì-ÏK“yE„JÍ,J™‰èë\	]¯„èq
ÔD0ğt‚>„zğK\büi€z±}·^E\9;?ÓVf„–?9ƒ˜9L“bùçEö3hUxÍV[*l£wÿ8lnÆ#N8+SœTHWG(™T©¥’Øš`	{KÕCNĞ¬r´]DÛqô§$ËöxuÌŸ©À'6<”#Âş>…N¬ÅıWPR³,K…+“„åŠ;`=<U®;óÔU ¤‡.åâ˜+)K6üóDO g•p°šÛhŸzGòŸ­€ .ˆÉ qÈ§÷­ÿ²çèï¼Â¯"Š…g@âƒÍ‡?%E£LÃAÙ ´VÒ•y«Ÿ‡¤[)Â»‚©¦Ù³µ7šÎ/£~¤b],üşE ©ŸÜ(°âòş®w(×ßoØ<³Å¿wëÑ‡¶çT£¥ßÖµñ˜Z?ÔJú;¿"ézo)»@
+ÑÕ{è¯±å/‰Â8ífT_"‰š†,Ø;ÆQ·ˆ—L‚¯øë]	¥¦›v‹o[¹ú"ˆR‡*¸áLr¤*ŸG Z9¼9ƒŠf ?|ŒêB2J¼Sàâşêî4EÙsjÍ€ô¿ˆÛMd™•›À¶­8ê+ïMG·o|µ;Î±ÿÓÃúX6¦*‚0ÔöbÜ¸¥Æ24UÌîC	aMsYXE²óJ©¯ ¹âl%şĞiÆîh¿ÓŒèhÓŒ#Ã¤™hA$ì*Q;²˜¬ä/â^K­ËxK8ƒ§.j³+!0ü.‡ËåØÓ‡T‰FrqÇÓYÉÖ{İ´¶õ·ÙWml²^Ö+àÅªNµ³Çww‚nñxuèÎxôIm-b)¸_lmØİ[İ¬[íÚ‚Hb„í¡úm~È7w"`€4Ã0jÄaeù™	l/ŸTYÔÙ¦3¾lòå1=ö¡Eµïbü¥±zÊº‹šÔYçº(N|¥b>¤ÒÙ
GXã>¥Âaòå¡ÕõpJ2Õ>4ŞMÅ=ÏFã6Î‘WFÛ}‰`º±5ŠUÿ÷—üÜf-0KSÛ^n‰¥­ùÒÉ<‰PuÀ$ÃÒ«å6›U¬éÈ;M]ÓËwÓß/²ä$gQ!òÂXwdEÛ2J}€¾¶ÛM‘C)v´ÃB²Ìõzšc¦Ç“[÷4¿Ş¿íıÔlY®l.ş^õ¼…7ÜúºV È3ŒÚ£^÷Yëw«—3®}û€–Ï'$›Iëâ9È.|´®ÕîûÖ½ÂêÂ—°ºòsœÂó37”•ÒŠÊ³³p/Ç»Å•D'S*"TÃfÜ:06İÄ6%B£Ñ=Kä÷GhÑ|[¢L+a#ğD?š`²nBş3Ì•Ê¡o9ÆˆjËõ…fË´_eÜ§¾11ŸæğäÙu rÓÓ¼È¨,L¾êÓF/óÜA<EÖ±•“•šA#•Ì+íØĞµy»ñ¸İ.a>˜™Ï–€¥Ü˜w_CÔÀÈ2©nM¨6²Š‡dÂÇF…Óg^È©v:²Ä	˜<qq†­L¥'lí+‘ZH=šG©í˜I² T5ã¨4;ğ×ÈßE-]ZÕ°Ş™f'pB·‘äRØÎ®­Y8¦JÓh?An'‘–ĞŞÔ"«?T#Ã¶(âÚèV¬¬crA~«ºª‰×_Øg´sQC½D& Qˆø6±ò‚YLAÖ¾ä4;ÅGuˆ=İR˜±{;}HìAÙ26‹	º`:bÿËÖ@L:Ø Ë=cç7ÿáÆ‘Ë¨2ÜÁßS¼g •FİçìT¸33G9Æï ªCOQ©ïà˜ˆøªßšâÙ²şÇB´Õ>“–ªÇºÊ¹ Aôáàåg±ƒğã×†a!JğcJÈ3[¨õ«P©kŞ<Ñ³ctX_Y’§ííÊâ|c´%O`_."’Š™Up¸÷ÿ<G@¢9ÿôW™°â">à¸o5ê]¤â­·@v€Ü8&ı‚½´&KôÅó…©rl‘¢TñÖ¬n«êÏª
¯mš·Ù oı[èßA)$7Ê†Š§gÅX/¿×ÅoÜğIøôÔ˜L¢şáì H,'¿÷'iuÑı¦+#‰ç?õĞëÆCƒ½I};ÿrÜÊ\-Ü|Ù­:×+ŠœÁ­±7˜¯abU9°Ÿ«È‡½ÉÊõë*nÔw
UL%t #‚Ÿ
Iê: ®'1Û™¶Şh78M±ür+¼Ö¾åÎˆ|Pwâã4ÁÊivJÉˆ`¦/3áD…¾åaë
÷ŠÆã2ÿ3.Š$ğéCSïÃ”ídCK 5›`œRµQäRÓ^\píAğå:ÓF­tŞ^ÿ˜Ã‘ª3(¼Ïpå¶áø¼V²|ª¾9t^àøĞKØùÇò%b.ñvåÂyp€9ôlµT§t†µÅM<áÈÉªœ751CZs<FKTÄ–h¥”`åB}½¶PyV*x9Ze'¦÷ÂÜÂkmcÛ>oz\ù&xòqMIˆî.­zÿ¿8cfTŠX¢­€‹/\ÍØŸ¢šÖŠÌ8ß§S½ıqe“[Ã
î¢6Ó¤ ~ûü•]ÎÀ]aÉ^k,K¦1YH/˜Ç¾Âşh¦%M<'¼%H‡Áä’Vë·a”-Ø4üÍ^Lı|IG‹ªbÕãFm˜À£Ù”ùÔİÃ{úº]Ö!0Ñ
„gy>_”<;QG­÷j¾ÊÑ€¤{û¶øô çft¿Óq*î[ƒª">È!1ÛÛÜ€2­ëJˆz±pI÷½;¶{®MNNÌ¶xR#un)c/K¬ZeŠuR˜ïÄ™àÅ&ò&‰)×°¦ˆçù‘ğúêqNu<GÅ=PÎfú³@ráàßWûŞ$£d:±Îô^[ Rı×óçHX•±öİÆ†I>óâo`K¬İ;]ø ôJ‚â¥µ °JX×v›¦ø2Ì.b¦à[£fÂª`·üS_Oûû÷=vı©+ğ8‡Â¼ç0—í¢b¿æÍ5l_8Lõp˜š—³rDAfÕÏ!qó“ÅHM]¨ùe„ù½áÅ½ÚsnØÜ½j 0Ê¶¶ÃŸ© íNV÷=Á?xÏ™½<]Ó‹é<ê-°~©ò6Ö…'®“ëÌFcßâ_€ß,®Ö6ñè¯”ÅUÃ°¼àÎ¦AÀØŞ†ií  ôöôHşËJ¥kzJÔüŠÒ“U¨ç'ØF`â¬÷$sp7P“ì+†²•x?~Êy?¯<jĞñğ üÌÛáè†¾wX³ªŠ!®k‚‰TÓ¤”`hIÚaKÖX|€ØPX|æ Z6mP'ú/ë‘{RM[]}†²zÉï%‰$‡›ŞÆ*+|úº
İH>3ä¡¾Tdõß—lBóä¿aÿjAÎ+):çE´wûH_’&Ï(ên”&P²ºÏi2/ÓŒ3J1ö Ó‘‰ o‰íJîñ×¥ÎĞ™Æ»S #Zò¯¥/ŒÂò3Mªûÿ‘bÊÃÇnœƒy;¿À9åDY/sE·Ù"+çéó’»_tçøQe!ŸÈÜöÈã7×TÖ¦cû¡]98†*kræS<¢ş‰!¨9İ†{Ò^6á½a–ïWÛÜL:^‹ŠO,KY
0¬àäRy‰Õ¥~(ŸgCÇùáG‰9ÓÂy·©Mi±jG‡2‡ˆ¨AÑ0ÒÓûå ö™j?~ÓéH“MÄ)ìŞ_=–ôrlAv­÷5Júë	ë4z6øÈæ=ùˆ»"ŞïùKgr,5ÜDï÷ê-«]ÓÙD¯äê¿÷¹ËTÆŸß`mæÌS¤©óRù{¿¤‰®«‹M­‹5kÜ­Ïõô$°ïßĞXW·½&|yRC³0@ĞA!ë„œ
Èf«Sëã¬8k¿QuÄÁq_û¬¸"ÆĞ4ÏäÅrÌJuxî¦ÿ­—,S\u]È/~§NÿüB¢€š*¸ôI†­jÕ< ¼öpœ‡D5F^Rd¡4QQó°ŞöäËŸo<]­º¥ÖrâÀğÕ$rÇX
ˆìcºèëÒo•jğmuö†x¿ûH éñâXŸ[¨nVä¾T÷S7´ÖàÂéPÔ´)K€N°ûÁ¢eÊ’p”.iºÿ€½5¹B)*×'P§ôïF¹'M½L’öhæ“›ï{´æ©,È©£ÒÔ–=ÒÀ¹_öóĞÔXn ³±ù^Bgô¶i& @­BH¦oY)RĞ‡W…ø\nyıî¦;c;`"ŒlOá³CŠ6Ö)a‡ƒ¬ªt¼:É,z[QáÉJ»N×ÙÜ!ÏÎ‚ú2×rˆ‡hæô0üXq…çOñhş&›ÈDwwÎ†ƒĞÒ®MnÓ«Z€„vfç`7	Ñã4õ|ët@u7gÅƒ=D4fDF}Ä\¤İ±°ğ#ùhÚ|`º18x®?…FĞÑôÙÚY:ö‘ÌPÖ ÇW¬_ÆE3¹a™ß:¥ƒãd„ú`]­G'¯òDïy¢µ\ˆxP±[÷I©¼{˜dQ…($AÒ=fŸıAßÍ*”¹æ:­Â$ŠÎs’Êä
‚lÅ¯šG”óÔâS M`,ö;ZŞğLî’í]ŠˆPs/¬c”Bm¹ŞÍnJœègüÀî×éãÿxÖ\lmÅ®L×0ÈEö’ û•ü«©Ó'üºÓÄ•°k•ŠÎİ~|˜¬‚7¾Öéıœm¦CaÃïkTûî¤"¸ÔêcRc…¾ƒ;ß™Ä?~hÎ“ÿTYı µf“`¼;šuÖl1uÿDiPı,«NòPôZ¥¢eÌv¿ègßò2ÕH¿mHvğ7~kÊ™Ds¬¼¬É0™o0fÌØ€ïš²yˆ÷=£P@@›ÈÊïÕG,êhFvcj­qÊ_{î·Òu“¡‹§ip?P'²(*B1^ƒWŞ”8ñ¶’ólÃÊHMP.ÿ…
ê-y3=Îì)7ûÒú†ş­½5#­Ò©2OKÚ·ûV”k	Ÿ.ÏEu“V0ÍR6»™1¤¿}ää3Jö¼ùl(1²Ç²´Ò&á2<ÿvÙ¶ k»$5ŠîøGry’«õpà„’ı1ÏRËD“‘¸!ûÈ¾^´ãtU¼ŠLµ§Â*…¨-·ê’Ğ*ªÏQÙ@ÿ`ÚUÁ?ğkEèª~
2kŸƒÚJ©ê•/B’À¸ã»ªmõ¼>),;N3"şvı|Ašª«@JE‡R¼³ÈÔW¡(‡3L~t 2¹K<5?T›¦Ë›´Qø‡ä€õ»Í6µ`VÄ?@nøœœó`J êMµ£2(Ÿô	†j(Û}Ír¿¤\À /!İ3ş÷†wmÁ2wzP„áâ¸§§ésbã@£}k=ÁÏñ†²ÏŠ,}mş?(¥¤	[ú<41„²šÿù»›ZDYU¥æÈ‰M#îíd{ëòlhÙM…–ïV¿KĞ9‰D¢N€´;Ú½X´_8F“¬NŒş,DùkDåËXrÿ^Ò&gëÿhVâİ†/UÌÉ„L›h„ØíÊõ»DPŠ_áàşàŞhCÛÙ“i“†­;‰DF©¬Â12âĞHRèetC™ó
†D«8M…#„ù!¯æ½ôº£Ïa´2¸„IÁÎIIq”¥$1}#…€o¾A™fÓxÂöÿ“Ó,ÃÊ`Êk~¶ã(çºØãÂf„ŞY2v:_&§7âí^!j™¨›äí±˜"wyÚ~u-Ï0×r“QH&Ø¬è´wuµ¬¢¿KÕºh.å	švO	ó@L9ºâÑÅÜRHnT‰µ—p9H’©ÈkQÔÚkÂPh‰ÅcŒâ|[kfíâ¸hG&ÑÍ±Ügk”WÀº{1u«ô8ãÀt¿&cí0Ïû˜Ïæµ.l›_§C—–Mƒ…¥ÏP®ñe "ƒÅ‹T*ÉË€6?vñ^§ã¿2+[“Ì™©™€ÄtiöÇùú3øÎ°úõÃww[;s¿erFÊ1—X[m/bŠ‚ıª½«Åvİ"£uƒJáTU®··únà&Æ€ÒD ·$ìßßEÂ1œ“¾F³kw³üH‰ÅBÜJîãüQ±rg2]Q­¼M™Oø4”ÒäOzß ª´Zf6NıÈ¿Ó#èäÓ³õTmİ£õ1ğröİà;ŞŞä¢}aF§šøQ`Â •.SÇJŸöÔÅq]O‹X[§‹F49)rA'Xkx‰‰99Ú5÷/¢Îú†€V7:rKåNáå¯.Üó½ñ½Ë|û« GÂH_“sëzYqfÈêVYAcoYİ.È·ğªÍ²*iôÀ=Ùs*áºÎñ*t&Ã)—ÔĞFöj“~X/$ˆ¥è«œpÛ7œËx*÷&|,kaåˆì—8ÚğQÉ’Ü(DÄºŞ–oD€š5R±³é‡ƒÉÿÀäÑX¼ñTrr~ŠŞtô¢DŒŒ!ãAæ‰Õw×(]	q¨cì*#Ú‰bûølÿ¨ôÁ8B|Â	 Ì 
c+Wi_»dN8:@Œÿ°v?ŸØ]{E³¹ò]MŞšFÙàV½ö<å,mp9û48xÜ]FuXúûx;DÏÜjïïoìü¿“ï¯šÊÆÁ×†¢0>8ÚÜ~2õÉÀmÌp`4@ĞùAŞ>¶Ï×¿7-¦%b6›Qğ~´}V ºf¡"®˜WÛ$x‡¦±ÆoEë6Œ³êA‹t ¢#³ &s†~Sİ
¬¶rı#,\‘OÆâÚ„$‚˜‡o€~Ocø—óÏÙ.„¿;OwĞÍ:ìĞkK˜A®ÜzC™¥µ·¦j0û:Ÿ¯’5h.:­U•.ãµ™ÒÎîïƒ¨}Šâøœfê@ÛÍ7úc#:ôÚ4‹#°eûI‚ˆNãŞ=ù^Ã&?E‹ê&m³/Ğ ÕÚ%ëiKQõhrî-Ã&(¦SNèäÀJ\Éo/>ÆÆ
[Ï|Hüªš¹AT-{§øü‹%kö
§÷õhòuõ¨ @¸ëŞGN%“ßĞöÿ-ƒŒæ.0ªúâWÄ’gƒbÑÌ*Ùì†_Sì'b/½_ÏH°_“Z©òö£´Õ~å;KôRÚoŒÈÈË)+U‘‰PlXÄá`İ $_q‚"–:JGÚ¨ŞMß¶üLß^•—Pâ…ßY
N-0j·O3$u Lxã­Í>ÅàâtÅC9­d½ÏÔmg³·›OKÂgPï	@£µìªÏ;Î%¡ıEáj¶¦ç×êQˆ4<BêWƒê«ìÚ,B³Zí¨Ğ‹:"ÚÊ¼)÷`j@ŞJ2d~Ú&Y¾„Œï±—êMGÉáSÌæGÀ>«â ·!©L4}
 g=dv‚;\Š³¬·ÙFåtPÆ×D0t6!ßÒ.oƒR4*EJÑc•®ÏOÙM8¡8:MV›*>´9“gSYœíR„¼ô8Ñ¡ä:‹º{$=¦áO©ÖŸ&NiæZ%qén\°Ÿóèp†‰#¯!\Fpš›€89ë¾–mùE†N*‡OÌ;S®oş¹%5¯¡†–Ó IyåŞH.P=ˆéâÄ‹ZWI|#L\Ú“ø™@q m©jèeZTë¼êÅ©`†hàp)…vŸ2Ítà~ ÷E@†™µ¨b×08ëà-4ÕÍh1˜Q|¯í<§OñSÂfp‡“Øö#á$vöuOW(u.ÊÎB@¼p£13±ğ˜i”ÕQõö®®Ò×@›ÖI(±Ø' paI[0ã‹nÈ(8‰n;Ğ7†W of?yM-X¸§‡ NüîW…ìŒÌ§Tüß\ øB§W­Ë«|u•,•Æt™Âp±!$•âÀO´TÀß´ÿ’1È#PÓlæ?1•Åå¸$KF·<™æ)¾oŞÙJê‰)4£­šö­±6‡NÁê   6±6ÿ!<ª¢ —¢€ é[<×±Ägû    YZ