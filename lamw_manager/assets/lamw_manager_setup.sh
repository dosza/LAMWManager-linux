#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3896104620"
MD5="2a2e24c3a6bf40f6405df716a44ed50a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20368"
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
	echo Date of packaging: Sun Dec 22 14:28:32 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿOP] ¼}•ÀJFœÄÿ.»á_jg‚R0¹X.­1oŸ©*)ó Š´»¸gõPC`•.çˆxnÙAÄGÁ4WUñÂõ®×Ğ›1SBàiÔ#tW"¾Ä3´Tº³<5»iqË'›/`^l†ıòiû$X‚I°»Ä:
ÄQªä¹[eİ’æ»);fRZ’†¼Ü[¤224³lãí œÔ°Óû•UºêsKÖf×
İ•æÃ+Ût»…-R/¤e5³®–Ì"Â>™¥óñZ¸†$Ñx_€¼·è>â…H9ö£üÖH'ÓŠóSZ¢— † „…Á˜õfo!És!ŒD é¥¹KUËˆ½Ïºÿ‰çŠ†İ‡'{†L®·@ÏÕ™¢–ÁÍæ÷İ6ÙÁ[5ÕÅVJro![#ş8fÖK@DxUĞWBÁã!Fnˆš©Ÿ~î9cxií÷¨.Lv\¹§—?¯l,Z+ÊÔÆfZãH-ø‘tÛeöúÇNtN×•è\¸uW	ÁƒÆÜmïU‡dV©z0ŞÈNÈ‘İ^²µ…^ø¨4ÚÑ[•Ëçjİ6(c–HVÌCÔÓğ¨şrS”Ÿ)€'G÷VëîñÕ•`|8e	µ˜FCGüR©¹ÜËrRKÖ(kÂ¶fWä°TÇŸ¦\^/ÈKÚ³$'‹Î‘àôyçq9OO$ö¥¤#¨¥¢Ñ)nüéÒı÷“R~Jƒ5cBßpë
¶•ùÿQ8ë»6CGƒMÃ):òğª.V
@§àkj“ra9Á[{«ıÆÅæ†\åo/’Ëç9}½Ïàu(¬Bè„ Hö[µûÆ%#"‰T^FJú¿3•®uPÖu: .Ë2CP@eYYbíÖroŞ&„j4öL`3|ªqe[;Ş•¯¼ŸÔ.(mÇJÄgøÆjÚV@Šxwx!\á+ÎÄ°™q0 ~ŞŠ¦HMCJùsÛƒfk­É’Õ£|‚>Ò&2ìN2
˜+íè°’. İ…Qfi×lš›&ôoÙÛWıx rH“­3·2ïUëÖss:æ¾ë¡ˆ™ºønÒ[¯<rÁ$5š,7‚xNĞ¿°qw3‰§üŸ	ï¸õQ¦:˜ÈîqU¦®·³è¢v9ŞAæíüd@Ó9½æ N».K]¦ğ¨XÌ`‡ÿ¡'ùTØS ½YöWöˆ!•Şş,ö·F"äµ{Ç|¦ \ŒÍğ8L\›';†,)İ3ë*¨ÜÄNôÎÿº’| äí–ÜÒçwßÂáÓé­€ÈÃ=—Õ®f3Wãş°*‡&åÇó:I5¨Às©5uÕ
U >5F„BLî÷n¦TK5LÇbó=>ƒŠ!¡'´ÙÏdş¶ ¢ 
Ìñğ12h‚¢‰Şu’Ö56\´ÎBÇÃ9l$ë`(/%å¾ßÔTQÃµ_`B4®åK3¯°íÖ.Á˜óåO—L³cËlBÔòEøpa‡lÉW›l DF\F®†Ò™ˆÄ®êÌÖ‡»“Ò[ïo]m.¿Rº	Ğe¹'¶­¼8à!şe#œ]MÜúN€ö¦ÙÙe®ÅÈ4ó!DÌ}¼İF\õIÀ‹=›ÊÏtåÃé˜ÆIÕbÎQc÷zÉ.ÎZ½Ì-X³¹Şè3äâÁGH×¤wS¿>ëÑYááèÇÔ%$ó(¨ñ[„]_ª;ÙÛ;V‡º”zÔ9œRßST1Ï
	:UÇÆŸıæìHR?€ÿû„A ¯š§~@7´”…€	05gu’,ánb÷´~O-¦änãwç‡FòÃ9®…øT‹]Ü@3“ˆ5iİXx»ú$¥Â?52¸#ÏÉÙy‰^…¹z«{˜–<3NİHALZp»'æ(H´šƒGeö1gOˆõ'–úoL8k+g¯N›ì JqË‰¡åÿÉŸ!Á¹C×-†{iA¸øBG+!ˆQ•_A¦a’'^Nø{fˆ©Äºy»‘¢½š
=Ö)ª/¸Z™Ş2äY–„±Y¦8€…$è–‡—æ¢,’Ù°&ha~uÂÓÙ·ì©í¡€5/ LÀ]m¸ÄÒô2&m*LyÇ·‚Bä?ÕO\Á‚ÂñJqŠ.]QØŸ$·^ûŸ¾ ¶P‹…ô§ÂäR³»ûÚØMšÖ’ß®' iG'­Ş¾|ª¢~-´‚›”-€:e PAıT$™g¨MŒï¸Å«V
ÀWl“€–‹é;FÂ+¶=¾Dë‡®Ş©D·O´iJbğˆ çkÇC«óä¸oPfFò·†ĞÂ« ua¤Çj;C¹á¿íç®õyÔìmCö'hÒD)bZÓÔ+B2A)aÓ¯Ûš]”Ù©#ı¾¦ø›J29ŠûêIv ‘ã¢ŸQ¶Ÿøï'BĞƒAî÷H€ËñÍ·±N¹À¶Êse­Ï]¡%ê¸ìÌD½d&–Uƒ3@`ÙúMÍµj½NâÒÁoë‘ëŞ?’váR¡èï?4¢ô Ù¥ zyGÃ£@˜\èÉBêŸÙ@h%ÿXXrr`ø@Ş@0?ÁuöU{ilïÏl¯î|ì½ı7\¤MGD|UÄ¸û¢á•Ãú%ˆÎ™miÈÔĞÂİ×ãj!ß9 xG{ºÏòè\½-«I1`Hmoé2`§@ÿú‡ñô4§‹ÊI·*ÀÅR¼ÖJİ½¦Yùæô÷°˜‡Â;™E¡¡)ğ*†ö²Êñ…AÛáâ÷’7_¨††6;ÃŒKm»_p˜é0úá¦C:hü³Lôw¢Ü¾Ş ½–naôë.Èey%X‹âÌ{›à:4aWİĞ{Añxçv²R.«FÈ-qLÓí‹Çx1ÍßÍm¦˜æ‹ÚR/‘A
`RejÓ@*ı|Ìp½jÌv0wvØìë¾_ã»LWçk7Ë` ÒúµB‹,Û­XŞÈ)½V®§[òW9§ï;…ÅËSD`|Œ=	/,GíŞÛÕÉÉyxôöğMÑ	(DÔİˆ3«ô¤ÉWCZxÕœ©ÍfS‚3ß¿V"_@_0M¨ó ú.O-¸l½­Y\<Ô7øçs=å**Éş®
ïnDg	N›Ë«ƒ—3~N÷@+8Æ[]ä^¾Šæu¢g´”ÔóB"O'Œî´` /²¾ùÔ§Œ¨O°vgI^‚ê:QÄç‚²ÜÅt‰“j,ÉØGÈJP~è­õ»Ó@@ÂrÓó:,{@¾Èë±ôéı~ú`­D²ˆyğ† +îå´N'çÏ
ú®ámòGˆÿ(¶Œ-»ôEEK#fwø‘:Ş}
€wè
™¬ÔRøÃĞ=ØÀ*ô
'ç*ÈGüŸĞîôô¾Fs¤†6ïO¾ ŞËhvÄ€8Í¨oi7³ÆNBNöÆàj3Ì{!®Û–\„:‚ˆ_ç†ƒuVe>mDeÂê:%¦s"Bf´†è‚ÑÜ¥1¢ ˆÕ?Ø€‹Düş¿	VD×ŠU¾wÙ_¬Şcó¥*•Ìµax<:1ªêĞÈŒÙ¼~–Û¾3¢‚8ßlBpÑOQ'MIœÅ;˜KŞ^|¹É#³«êÌK=Š_ÏÔX?WÿUIFjp=ôÁ2ª„¤L:Ë¤”ó·Yı”Ûéc{€oç¿ëœ3èM«~ü u»FÕ†­
UJ7òF­ƒÆ3Åë¢ÖÕš£©=‰½¹¿¬›İëÃ­‹
÷<%,üÛÒ`¢¯n3”	é÷ëhs¤XÃ†±›4=ûÊ|,Ó^Jš‚,Ş˜ï- 5ã˜4›Ä`×•²"y‰M†šZÃá€œldšt—s;”¡»€/%–XáÓf.åVG0AoIi'v¼ÅH1CzÈm6¿öÆdQ`İ1•›Åj4‰š•kÑRMDLÍº]šñ¾„*53.2ö¯ûƒWøˆh‚…»7cS´üp/”dú¸XC¹í&düÓ•%<õôíÖ<½öœ$¿i5 Wßg«Ê'³8w	íîğJù»³ØS|ª-ÄXH–+BGizR¤2æJ…Í?ñ¼õ/¯Ltx2SsÔ¡<xƒÓIÀŸ#YŸeÉRZàQ|I´*@¯³³+å;5„–Ş?…­êŸ1Dİ°´Ï±ùOI:Â(êê>c¶©EvtÓY’s¢éKCS%éZÛb¹Æ—+s(Z‹°Ë€Su1ÑA™ñ¯¾Yørl-)’Åü’®pq[Tù;ÿñâä§ËZOŒkX¼Ù~“i/Wrj~lseE &é(5±–íl±$&Şƒ=eŠ¥ZÎàR"6ÑŸ°X3;¤½Áò*Óßò¡Õ¹ÅLÆÊnæVî')M#•ŞÊpÙOø˜-eã•&)êcÙƒ>åãÎY¥K£Ã¹-6OƒƒĞ.ƒØ\HØRBÅïô‡½ùr“]½@î s¹ ¶}rgJìÓã¾è£¾¹„ÊÜ&:	K=ÕhƒÄò'`!ßLøÎ½âœÍP|fßƒP“_räÛïâÅİø¬j$©Ôì9ùé8È{Ær~.¸õO—¡”®×¶ĞqehHÄÇ¬05[C¶ÓğåÜT$ä<F]3!°Q©ş‰¹#íy©ø–áÏ3ra&ü«É¹Êö RÆóeÉ³ÂÈZ/Ì|åöšÎ£œG—3?¯} ˆ+Ô±æ#Dy tÓ1Â¨1f5¨´P$J~¯`Ï%áÙV! ÔR–8™{O=å†üšHsğê‚—”X$ä÷„Ç‰IÂaÊÚˆ ÖKÎ»=Ü¼Õ½ªŒ	V^ˆDèáŸå*Àyƒòdd~ã0áuÇŞõqÇİWVJLFğÕÈüŒ§ı“¤Ú™?Á7-~W¦ş‹Ä•<×çmƒÓwî1À[";2cR mû¸6bÂB„òÕ´ovè¡ÕQ_g3É{‚ûŸ”¨9=Ù9lC›œ&şÁ»f¸“äpk¦# ‚# §¼“ÒˆØ[ë}Ê6§¿‡Ş[öF¯0mf9â¯BÙJ¢%†½;Ó”V0ÚN«CK°n™Æcöıy_ñ¸º×³<ÿî†çä>pâ²óóIá0‚ÅáGñƒÜV
HŒâBAˆoÇsÚeÂÍh˜Ì" *©àM5Ù†‘J¤e<@òc†áv2L!¹Şøˆ~œâO ƒÌ6^GÌŸˆ!ñŸ<,s
ë'µm!? Ë l£ûæM!à”J7­6òş>Ü¶Xy¾‘x—Zò¢ä9H^YˆØèdô¨Ì<‚¿ßy!ÙvGöÎ‚BoO} Ï¼*©äÅ¥ëMÑ4'¢>z].R³C»!O* åêyWÓ	¦¹Vüo2É…K²æ§õ:ÁŠ’’º»1|êàNJ•µ¨@¾úgbV=?"Ù&¡­ÊUªÑFçdTcï€",”u'ƒÖ<Kg-!ÆYá-VÇÂPÓïgûˆİõ¤°*zdd†d–,„Ø:;ÈnJçâíÿ/30ämrM›L1»êÜ¦5Bÿæá¼aIóU¨§!:+—¥}©]¨m@‰Ú`½JF†Å¤ÙÈoHnïğT©¿Şyó>~%á$›ı>~5GIî)Q¨IØ7K[vn›ğ”Ç˜v,ëªI/Mªÿµ¥j¦4ò¬+„•80\D•gØ0h4"j‹_şU’5%ÚõÄ2$"‘<wKúĞJA€’¥>ûŠÍóÙe^ıCÌ…BïÃË™ŞGƒrÅ«Ş	úf@4ÍWà¤9‹¤Hœ8;’c‘’HõÍ:RGV…¬÷BÈÁıMWùñ0‰]ßÀt=çi5¡Tv.K‡Ä9ÿ¼À¥t­6Ï8oÛpG6Gµn’`ë
ï]Œ›G+Ñ£‹¢¯Ÿà”]Xê£³¼DN<€ÃN´÷¿>ƒ@ı^çÑ]”“myˆ
"xÌ¼V¤§Rd³”u$SJLZ«Úû¸~1"Ãc
m;qä¤wLŸ•XĞ¾¹¿?F3R‘›¬}ÀI#ËxØ\xT¡/?'oÍÊ5Ía2õZèÙ7.nî]tjb} )Q‡g³iì$F¸¿Ï“—rˆtØ³lÁö¶Zä?¹|íKß]l¨§×Ò…°8Wlî˜úêiØ¥ztÁøº‚¤WW ‰äÑ?éË‚ÄC×K“¤bÈŠùÙl2ë=kµA¤|‹Ájg‰<œ‚xé`&˜b…ÿ6z­P=ñÚş—é÷£uµøİÓÿ£Á'©aR¬D‚øùŒP¹pù£ÃâpTşbÁèø´Å¤¹läZ¯±!×¼ŞÓàO÷ñFáVjôèbv.Oåâ¦!0åºìgÚadú]ÿv¯¿Ñx60b˜Kbx$›òÊ2 1¿{¶ƒöÑ¸D]ê#-ÎZğGå4o¯ÀôL¨ï¯
PÙVöƒµ¢ºÊnáœemCO„ıÔÒß:§P}&i¨Û=tâVëAnå‘'|s/&‚•Z^Y+VU/ù§1M²Ís\‹ùçíCŸ¸é.ú¤¶»Ò_N6ö‹ËëŸi–ƒŸ[qñIÄÏb³ªy€ÓFï°ËEğ&šC3¹Ïn{ÍBîŠ7¯–ø«R;Òùˆ¥µÈónÍ0:ô1ËEN=Ø\H$ı"B¨şX®a^-aˆ@¯‹gµO1 @eG±á˜²še`¾g|/!úƒ'\°€…©%Ç°<IéQûè¼q	#3ğ4~¢gg½Ê:f˜òõ¢ĞëWqi*O%º&uªÃCó3\ŒŸ£¹ ‘?³AJ¾]'Ğ¶±C‚ƒ‡)]®&x…‘s$'Ôı[ÁåMµM§x’t„©ëÎc\Çm¼!–¼‰”8Š#ØÃ²×Ñp©{¹}TeQ7äøãj[³YâÇ84c×g@â]ƒåÊ”5e‹˜å%Ó˜ü8¦—7d„±19Ä0¡j6dš¤´¬f†’Yˆ"jNƒİ›­:qyøßA¼}FçÑäNJ¶3/§âQˆ+£ãaÿv Œöù,á ÁÁ,%ÂÄ£>Ò™HM
Ş›9,U4OèÙÑÛñwÛûâ„„/ïå^ãöÑë¬@2İçŠfÔvs‹øèÜü½û¾Óƒš¨€@{»zÄBFÇ\÷ÄUZ?İ)È&ë±_ë‘æoÆ$69ÏÉ‚¸9‡h§—K•ËÌN96>ÙKãwF9½1®›xãGÇî„÷sÇa­°yÊ0İ Xğ%AÉiKt)ıèfŞı¸Xy0qA–“4°ù¾9ãé@©]ÃW(†|8ùN@³Å¤}Á°õ)ÑSã’¾Ê¯ûş”óDñ"¡ôº9Nè©?İhKJK+fBYş{Ú	£>–¨è7û>‘cÚàMø%T`5·/^¶DÃymºxÉà=”E¾~›ûré™jâ7°Ï+©˜‹‚ä^£•cdID4aêì</œÈ¯Ù¤§^€ıó (¬Ô±ÛÕ«……Œ7òGVhM]<gŒ¿¯Õ†V­kÂı@{¿UóY»i‚q¿wĞ6'"‘‰k¿pG_ë!è½"v@eÍ/ÖùGQğ‡“´-^úƒˆ3"_à­à‹oøÿ'ÖÛÃ
bt†ËßÙDó©Rp»	ùdâ·Â„Ğ­-¹0‚UºóõbQ@óX¶oÏ±¥o×„›:ãÊ˜TË3îÀ/ùàhÑG+ÃR…r¯¡[e²/Á)ß«Oè{÷£şŠÌtæd)Râ9Lˆ€'|’VîFv«G\îıâÓàâÁÀİe£é–F×•QóŠÕşlÄèWÖ‰â(,ÜàSPmUœˆg4ÓğVmD¿h—iA£ŞQ‰’šÉˆçªh‡Şî_ÜÿSÌN°&¥»ÁG¦¼ƒÎá–èseèiŞnAÜ®’ #²JÏÏÙBµ@@¸®‰…Â` Ô¾‚õŞVÎôµkEÒ	`¼sÅJÕ°¶[İŒúfö(FÄQğŒ¤Å“VÃ*>n1şoJ‡öb@fS,æßÂÃ@ÀÙ¡Ç¿òàò^#D§3é`Ö´N©áWÛ åş¬RÔç›Aaİ?Êà	67’Ñ7 eÌßO¥¢§}9g­Kgmq>…¿G·3İ(‡%TTü:(KÊü‘Ø_B‚#kTÒa39HõXÖíkYèbá«O¬j”³*D¶:¼³è¤õ›º÷q:–4Rì\)poL–UÊ³!ÌrZ_b9İª@Ã>¾YXòK‘ùüIJïº£óäŞ4uÊ„rÃ³üa"ü\Ç˜ E¨Ì*w:h{Ã.VÑñé™N.ã‘9¿õŒÒªq¦u§ÔŸ5¿EßOÛJ;ŠÏÉÒ´1$5çm“ìÑô‚Ğ|Ït:"Ú”9¡Ëœ¯ ÿ¤óÈH„/îBñn®à¢_¦êé:‰gï3/Ş°ƒ¯aŸz‚nÓX—ÿ­'áÙ>LVTã+“‘üGy*æË cĞë|×Ç¶srœS:‡d{¼ªé¥jÉ|A•da>@±Ê×¨^ĞlşH.òûÈ˜GÖÄ+­2wÂ,T†VSCßÉœ’ªİñ„VªÅü|'ë`T¼d³ÁK$Óq_©¦O¥6i7…ä#+ïz«Ş-ød¢CR Ú`Ã¸ùôü4
Î_|óV\ğ8¦‹‰ğ–¬J«­®6âÑ÷-M–Ìï¿š„šíÚL-5)Qdp£/6š-ı+î*²‡È©¸V¥å›£äÜKy]ÎwLHÅäÎ¸¯î5vò½.}#$f€ì=ëv„SYkeuTÔâØ¦%ûa@f¶[Œ¸îxúÕ«-ñ¿¿)4kšA—¥9ïµú3t‰{„1P!Òêõ±¾Ñ½¶ÀH^%f§PÎ1w²ét”^3‹{Sò«“K Íœüa¬4$ƒã4L>so‹/yÔŞ¯)±Ô?Î¼¿öœî±ŠExï–dq­µl—Ò­Ô‘£údÏ¾dj¬$<ûåÅfÈ*²a2j¨±õ½|KDÃiş-Ê1ãJs9òÏäªŒ½HÙâmNä¦ıöÆ5ƒsï594sß“Iã Ó—XŠœ¦ŠQaj°„±úM{šôº|’ß‚Yh¼¼Âş¦ª£ñ:¯D¶¶é1XÿÛ?DæÉf<tÏ{|‚TÑP; , Ñ½íÁ\D†ƒVuŸ/Z`EÊ“‡Á)ôÓ_Øº[
 ìCIìãÙÅòÍò–‡ÃØ“çÃÀ¥ K×kº°ƒÒöÈÃözÅÎã"Ê!]€ä”LúKfŞ(æiÓQúY‘LÚ¤‘³àgr÷-Œ¤²vp´Ø¶œp¾Ã6	t÷Í;ğFçÓ §whÕ¨XtJ­öì’Ü§——ÛSÑ™õÀW)¬D|³­aØU	­„T´€UlÄfx7QŠÒgª‘¯ˆ^9ÆA‡¤¶	F:uv
%*ŠçòøÊ"æéÍßKh»­â|oÂªæ(>;–éúŞ<Â(…Î¨d¥›¬Ğ Õ>fkÚ6ÀÉ#½/üt×{9l-ÙvD’»•S‘£ğÓ}ş˜ËfºähUo"3Ü ¶ÖX}êw©#!‚rÖ—G`½½“ˆ»$aÔ»†âîÏÒCím#r€V”êGÜ$KF?ÇN(-†nÀÏ)m ,.hYûÍ+vÕøÇXÑ§Œz1°†ĞõEà	yâ3WUùæ'ÜµÑD³ÛÔölnŸˆ¤«™KGØIÙ¤êÚ§öäĞÁš}’Õ¨¼ÉÑYşñÎ¬oÒ­Øé§\îˆ«€NF§Nh	;Û‘í8Ğ–4¾ Ø÷{L#·ßÙÛÇ7w•¡^æYşàù—/º á2Ğ ¤õM¬lIKœü‹{İ¡R#xv˜8gœÔ	ÉÎ5‡I¨§ö(@4 ‹Ğ“ŠÃ…Ûå{#³¶LªKy¿dŒ ±í×ÅjøBz9•a¥Ç§òVÑOf~zX‡†%«‚»E¸ŠV;Œ'6§G°6õ’7ú>òuÓÍVÙzÜ©êRv$'½¥Hº(Jó5±.õÇMó_Ai;jñµ¨—‚Ò=gªThœ‚ d4“%Ø…¤JªóeG[—’—G¹Z››j%yÛúsÂ§ÕåkZıPÄJ®|¡h¥á–Ñ8	¶‘ià¤Lƒi#H–üï8¥³«ĞuM Cñ›ŞŸˆÓqr'.èÑ£vçâ£=‚Ë‚ øú™õª:]L§T÷t‡£oòHÁ˜!­ù£Ø#TDš#§Ø5àù.s»‘í:‡G‘Û¡SeşRG÷Ê¬"ê#½´ÛÙ+Á(¿ŞZ³­}¶#&iäè;ç¹ú%*¢¼XQ£´\¤
»Æ‘[û€ÏSËrÁJùÆ4*dólu÷Z»d´…Ào)[Íe¿ó7ìN›¦·æ·É¥Æb‰ø{QôéÀš[bTÖÎ~Å¿ò]Šáî+\ò4ñóy•ë<mÃ,øÕ\Ç1µœPJmÜîQœıáMÄóBI_LŠ¸¦´Rï`ƒ¼Ù “å›Ñ¤ÁÌ km¯È>l€r×*·8iL¾I-‘#nî»T ^½¶ÉÉ—Ëg1+ˆIÅTñ”¸ˆÛ&«ci@8”†'‡SØ€!ó¿ŞG~(ë¢9²6hYÕ ô -cş
§–D …CÛ}JS‚°½ÅTcóÒ©úŸ£"Ñ…#vÚ7·İê) EÁÕig~”×-†:Õ˜"À¿a¹zX¥X—xoO5xOµ‰ì"tò(.æpCœÖ°Hò•7+»ş·Ò$€OF–ô »2Æ:®µÀÚj”ïÄvnWüß}¯f;‚®]£°l‰Iw¾q+™mk°Éª¤²?0j%Äpï#ö6 /“(›€"´¦l5®Óo|fğ@ôHEKT¿ÅLLïIÄÆ"®r¨®ìr×»†şì‚Îé*4FmÜ¨Íäù`P37Ba.ó%g¶nËV‰½}˜¡»3<ğá‰7H7llDé]åà+0-ñÜ@r-ŞbŒ§ŸweìÅŸšÎê&ÂÈ	™&y·B(ä•)L~\ª£l¯şm£÷†d†­&} æ6´6ø®Å\ÉÚoüîéˆø‘[òÇuátë%”š·˜ÄÃ RgıïÖüè×u?¶L†*l·.zÁh—Ù{Öaî2 •GR4	RÊ!I	lh7úY³i“Ç~½<q°=×	M`o§¡2²Qeac§>„à>d4¡Î3¶cT®ëRrÆP[p!Şç©ïvuiñYD±aÔÔ<â¯ã¯ïSÏáKÿ%±¶dñzˆÃæv.˜9í€…áğl¿´©$P×A†å–e¾£AÜÒR:·Â8¿ÄTÈ÷?­Bú9æ÷×ù•ôŒT¾µenÙå=uÉTİÌD~””<ûøğ‡cÕÔ<'ú¹B0É\S~\0/ö%5ÇªBÿ¿V‘“îµ¾ôÍ›´Ø,îYè&©ô]õ€ Vğ¿ptØâàÓb'/¦aôıjæ`Qµ‡uÂÅ³¶\*üU®Ğzåoß–)§=îm£QŞ
¬­<m0*%=>>
Dç¯	Ş—ÿù–
 NÏÒk†õ<Ø—ÚÁ´U ZqÎ*Wƒå¬g‡Rgñ®<V`îô6ˆ]_¢¹¨Â’ZH=tğùê€°€;³S]!:;áâf£ÃœWf‰ş,¦>Ğ;Rä2¼ë-o›¯¾ÉPğF^ÈL“bªŸŸ÷ş,ÕÊÜü(ìj®ÕËEKtL‹s`€”g8ÈJ¯³BÊ€b_H&QYk‹.\Í	³áË·ŠşDdÈã<¸PÔ\DXt¬õÈÍbxètb_Ê·E=ú¾Àâ°­ÉDIñÍ>óøB¿6[ŞèÆ 5lµ\`OGïoq°áûoW}¡BŠ°ıQ7İ
/gô8ÄáË3ŠïTW¸ï{©Deqİø¥"Îs2Üz‚˜­üúÓKgñõY}F[hÊoÊ#·÷–P¥ëK5m,=4¼î>W÷ë,šŞ÷',WòÓ¹ˆfKŠLÎWÛ>´b–!¢/ º€v(Gh ö"¯XüüHòM?M¢z•ç5Sp¤"–à/ÔŠøúğ¶%x	¢ gƒÓ.dX[€áw<ĞšTğix$!0²‘Ø¹¢èoŒ!>oºÚL›+93Ä&‹ÉjÏÚäÕĞ4ßfï¹Ê*}“6ÉXæëºÙ¾MŒÚL#™3ÚàÈæ×AªcşíîQ0L!p6å2@2Õ•sT§Œ{SÃ·øÎ78ÿ×!Ô‚ßMfJ›K%nô¤/ö[°ÙÅzÃ1€à{yÏJª’A´9…*k«¿°Ê.·‰i+L<0\'W‰²Îø‹ ÇaIŒ§n#ã›ô¡k!g+®müêô|^kÔ]‡—Š£;ÿmxzöÉ¸×y¥mbãí´­½¾"YË¦+D_™Àj³?ÂKØp›íd}õôW³
ı“İÜM›3Œ;è
˜RAªò’+I2puLY·ÄPğ ¸4ÀùÈ@yG^L°â´ÔégõìNJbøk\{Õ™>ì´m©…mëX#êı¶ÜÉLöMğ%å`ax‚ ™úÌ¯ÁÔ2!OÎû‘÷­O£¿½Y–½S“nIkÎL‚YbÚWØ	Ä*"«5—%5cQµ=›ÖÉ^Eb´‡&ã½ôöš˜E7wÇeÊ‘ªL»né/7Ôp•üŠ8ÍìUÈoYË}†Ä
<)cwÀ°¿ä?ŞYŸ4^Àúuğ€M†DŞ‡TD¿(€‰‘éVùÉşD]PÔ'È·g-Í$øN5ŞHMW±¾L5™ƒ$;¸:¡}î¾˜	À·9`Ã¥vºW–ÇOé†4g«½SÍ•7T¥OÔƒ",˜/¶"TGI:DM\
ÙÔÖã6EqQ)=ù›²ñ·¤££?ê¨†%ÉO§Í€Å^œ?úÛO{ü‘N_h!ÑNb¢8¥°(<X¿r±h0îqÆ¡‚~°ÔÔÓŒ s¥hq	†
–c9yæòGÁ¿ÒWèvQû¼{-5¹¾$¦9P¿M§G¦‘nYm–aW7ËCÅÓ"§iX…a¤˜ªœ1Ÿ Wu]EmYA±íÏ*!­ıx¥rüH×.(²ÅQnºI¡Hz7zEÖª[:{L›#gıÔÓb¨.Âµ2òĞq
¥ª+İa'“c>Æm–H‹„ÚˆªÅDG!ÀIàÙªH`‹iÖÄ¢¤'ê2‘‹©aqsPA‡ éIWí¶‰}¼µébì¡D®‘Èª#!e{ñY\cÏ{°ùŸÀÚ§.w§ÉG2]"g<8ø>©|yoëaÙ<ç*ÂúEğA/	¨°!V¯@Ò@:; N9érÕ3O{Wïµ¹Ì?¯#ı)`‚AP†³Aåáı¢6ll8Ì}Øş®Ÿæ‘bX‹™Ä’Kq1)ìª´ü”óù÷ÖˆgcBà·b¿7‰éºšè¾=‚'¢¦G\Ï–P`‚Q4FÂ¥±Ç• èŸ”EÁ­]ÙˆÀ¯q»º¹Û}Ú.Q?;ÇøŒ„eĞœ85şHsvh€(ÃH†àm!(ºÒQïıZ^†J$=B¼HF^bÓ:ä&ÿ×eğùÙëxğyJÄÊÊ.Ä$J]PX?QÓh}¤€?ùsŞìr@ ^/`7âş&.zx±%ÌÒÉÎÎÃhÅn(¶n‡|K
ÿ¥»«&qŠn>_@“6<ÃjRÑ'¾}Ä™ÊGĞäÉf\Š÷ Ïi×á´Í‡ÎÜ	ádïà‰Œw]ş™ *mJiZ|K/ÌB"ˆBâÈUÄ.±±ªY{Élo#/Ò2™„šRa8t(,@—§Oè |EÈ‘Şä*`1˜àRÖB9û¶‘e’,vİp·¡â>, ’5iK^q›ìo-¬Ö~ƒ™‰aÙî±ñEí)s1È"R|¦ÛO4q•ñÿxu,6Nÿ~°ÑS  ^ıŞºÛ^5ëmöa#‚^êİh­.Pé±JŒ~¸°97#Ş]w¥øfÛ5©¤_ı~ŸÊ7Óqï¸ú
¥F3”2¹Rá?	¾]Mğ{[Æx	 À¹¨ne°R®˜z±ˆaØV(ôä`1YsZ¨†ÓÓD—_ƒVBòP J«1g"1ui¿Î_¥$”¨±xaÖ1ÁåhsCX‘Jª/N:ûÇ0Ò1•¡(¬
¡KTïÏB‘è+è+ªMÅßÖ0’©¦OcAù‡Á“V7ÀüZ—;ş¬‚ÈİT#”&áÍ¶ÓyaffÂl£ÇİÙ[4×ÎÔôk_-S^½„`ÙßY6±6VÎp­‹ã£‹ïºË¡5M“§z–'¸EµP­THfK·«iawt6"û©Ëø#¸]‡İà½øÀCó´ùÌur¬-±^Œ†÷®t*UâùğÅIÄËd^¹Aü\födÌõh	ÙÎùıçWNŞ+óaŸLÓZ‘Q%VÔ›ônÅÌ#ê¯>]á¹iHë¯c ÈĞ¤Û¯¦ÔÜïvĞ‘úv¤†/DÖ|«G¼ßRQcmKËÕ³hQù]{l$œàã6ÏÛ™Ö1Ÿ‹»¨4VCÈUa »ÒANŸë’è•»{j@F3T´V'@=páÍÃ§'Ö¢ê
òõÁ¬HÛe0ÖIXLTØÀ+ĞBm·”è§Ûïì¦º#	;ë9œ kÅô÷‹&£øsùÇà\^U PĞë?€dU-ÂoøìC$·@¨Úq?@u¦U(çŞá:UÓ—¸ñãœjs±·"b?Yó*:í‚¶ºH—Y$µ1‰Öóø¦ŸWCö–9ƒx×¨¡ æ¶İÏ}C•ÿ8_‚#æÇú—¶±Öj³£µÚ7€[Îİ¬F][Oª›¬MaVÙ¶zv65¶Ô²c†ğœ¢ô¨}g/PÒ XyêËï{‚íÙùPNL÷µ"Î
ÈuÀXÑÉğn5º6dŸ®"5E^
ãg¶il‘¨F1cFˆı°â¬–sƒ×ô»³ #äp0‰ºã•{‘0A{†TÚ]ò¤ÔË¬Át‚¡fƒ ÆĞåXÌO]HîÛš‹×·¾‡PÉ t™ã?7!-¾*zÇ'Í,0×‰-€å3I‹¡-w€Î–ÊN12RMX•Ø@y#ßØÓŞCI…q†š>­—2ÓRÔ¥Ÿ›ò«ù:˜Šõ>ø¾Ä(ŸÇ÷dy³Fêú¸z¡ìç,ü°eûÙ¼é jb**2Q]ädª–;¶hi¯V5úªA5Kû1€=éÕÑµEPp¥’•ù1ä7 E9œS´W+@¨Tt&Cäb#9@}À»‰5kÈ8OÏ¸˜ İ¼QR>BzÇ‹ƒ¹©q5»†A†gFX3OHáC„¨Õîf§ûiŸûÉ8‹qMzÌÏ
;©zÑÿ€ù‚®·±E˜¯J­•ƒ¾YÎºıš‡5Òö{¦ƒ!…³O©ù=Ã–Ã·¡Zí7[œê>´GvIöŸTlÓ—8c;'[3ı¹iØ‚)Éàã¦áIí=7œçr‘ú³lÛpá»‰ã™ÃQ­áÃº»œ	„“ â_á÷È	E{àçX½gÑYë2ìªPPˆìé­ºÀŠÑ-eí¨ÂˆX>•¤FCã:}ö¨|ÅÁ[ìyš«iºrj€Å6ò‰1*‚ë€Ã$`oÁ-²ŞÁyÅw·GFÂdßU•jøD¡ùìùx		'z=£¼ë?º)Ä˜lŸÚí	fwp?òıîió‘3¹qÃN€@|Y¨ĞO‡÷?},Ã‹Önt­|‡ü*®‚†ó¬Ù˜-Ùæ‹¬ÒdÊujšee°b×¿Ú`l²É2‹àèQ-hÚ_ Ëß‘Y£$ÁiöU"ÎÌê9¶ÂwJÍ¼DU³lw÷ÿ:<âí`½ĞÑ<†e¶WöÆi¦=ÜÚ=U´ù¨z$ãnÌ=+ëW½¢üãYLsIÔÆª”nóÏ˜ÖË«äòÑ‘a¶R‚}Y±ü.ZJ¡UgNìªœá 4í“>É`¼QŞFi]»¦qpÓÖ7óÂ´ª‹0>˜½‡[½gÿ¸Pı¬"jëGša·Ú¯-ÊZWS­8§Ğè³¹F9ÿö+pşâÊV»¹eÇRÆRĞõ.;pè'Q‚I§U^îëé'›tK¤	ğSa£ĞÛd«3É««ú“ú¬M‘’ı}@ßÓÇ/ÜÊö`õ<ö¯ÑöˆÎU¬Îf˜°•±}5I*áVJ%Ë©]Ğt"<¹ÃˆÏÑGÑO:äRàğMî«óÌFGØ*™“ìfˆßQËfP	T}²ù'€ÂÌhysáäŠî-tvQÂıYfŠF-¥|FŠÂUı¶ô0DGÖÑæwüpŠiÄ-"&yk¥6¿Õ#rNˆû
EÓºN´I½"°=:Òørû&zÎ!¼”=ÚøúÍ<¥DôìÌÎ½+É¢Œ÷}^ş¦è¦eQÖGë[ø‡“mdòJ+h¯v€¸°hE]<d$Ée<U•´†ÓÍ‹ß~†üÙÖİ»¯–5½Ed#¤¨Èõ1Ë`>´©Åçx‚ó&¼¾%Ì±âÒ¸Ï^œ<HØQW ¹é.N3ëà.Mª“+Ü{Kçødºí©ŠM<°¤”¨Ñ€R7×‰â*
©jŠ½a§È—$½?sÇù¨Jœ^–õÎSÿô€Øåá1¡e¥¤_WÍ!ÔÀ‡/ŞëC}<g«%âqlçã ÂØñÆéÔPÕÑ%@Ù(vïĞ†]“´ ü™AvP(iŸ¬ÇM}'æà¼‘?/ÿú'$ôNmW3C5İ<Ù^û¥ÔÖZ'Âü:PĞåóÖ0ŸïfÈgCÔMbıë+ºÊœË ,2™¢ŸJ½íF>ljnN;'CñkÚDá—ø…{xŠïGÂEBsWğ" şÓhğQ‹»€ÿV)AK/i§Íéóï¡@=Á2ëíï¦1^aÉ óFN!æ,|×rË•ƒ"Ì	±ªÒŠ€¤húÎØvipµ™èñ"àztÖ,g9	ÆQJT¬V´N3™4o6˜-*(Ô4ÊDCı¤±s&ıÎg”A-‹¹ SS¿Ó¿"7'â¥´ˆŞŞ•7ÍD¯¢ß,(ê}¼Ê¼hXD{,p‚çŒÅr5|Ã¨†NÍšfUÔ7 Âa¶¼mR¯¼ö±+¤”çÃD	,|H7J=Ò8iâq/ç3^-ñZ<«#gVFCƒa¡„ùôğ¦ûtx«C_6B´óFä‰%B0Ği—„Š_¾.$îG'¦ï0Ä)–8éş4ÜÎ5•9Z9ù1zğ;@pynÀk+ê%òls¨Ã¨·`V=Ür2îÕßêÂœ¬Fy%hÕŠq“>˜O’5åë§F2ıìg¾¢AğO~,ğªø°½¹Ş½Ì5©ª ¥ ¦6nD*'È(ÄXj×¿\Éğ^&¥á\¾S•IkƒüØÍ‚îÌn*¡c tãP~iš~vãËzaY•J#	Accbç!ÅNT$/š“#	¬øNT–@òí`ú%Zìó	¾â\ d
l“t2Â«áH±–ŞÜİÓ)ØSæBéŸY‘q4Á>=Ï¼ëÂÒsé^6Äğæ8æ5 Åèhhİ—ÜuÜCª&Bòñu-ä·›õîö°a¸ór¾{£ZOİ!MÌ|[¡,á•8ŸE·Í1bìùËV7=s‡Å{2Ã¹ö©9´Ú¡ÄÒ\>Ä§óSÈ•¸•ª$õ¶×4–å˜uWhÑën™…î®ˆô“‹W-&ì“Â£²‰wb
V=ÁÃ”†jš„ª:ñaïÕò ¢™£“c½¨Ë)7múy8İŸ‹s/ÀŸÈ©işSÎ`ØÀyíîû”)ÚLí®ºK;Í%ú4§êÜ÷ƒT„ö‰X¿4ÊeCwØôANô]ïT’´ò¼(Ù
áÃº9†;Ûãã¸§[%+.
E¾@Œ¥õ®m"0DôÉ-®!{;`B xU-1ºójË¯×w;ÀDò•ÈĞK×ÃTDà3§úè5º'À“(Š”ğƒÉBG‹‘Cß€¼hñ>túzë'®‰dÚt”ëÏß}ÿS´¦ß°«2ÏÕ¶òõ*¶G¬6tb¯ñEDÆ4ûWğ‰=}¹'•%£eúâ<5Œ¿Ç¢€”Gjà*\BG)¦¶À#ú*cğí7ı1ÄT‰>~‹\{ôè5^Ñ‰¨É¨Í™ êC_Ó¹ñ«?{¦q%–İ‹m½‘ŞY¾vÌ-¬P}+y]–éôO#<v…-ÑjÀ<°ú<—Z‚E?Ì­ƒ%œb ®|œf‰_§Óõ‰uçåÔÑõŒ†æI<tå•òœUº×;w¾àz”Â<ö>Õ¬03V¿6İ±zh#{ô¶aƒvÃ'‚¿Š\¶@¤5y,áÆĞ7û*C¹<4ƒq×úğ®×\NêÄ½UË„ğîÊÕì@ùğÏ›^¦ú]4y,¼E%%[=2}B­İğ^xğÍ½ØñPc|ç_ª¡şbDMjª Ñ‰S— ÅşA1Ë)"¦.éœÎœ<f]uEúº¬yAJ‹vNåÜŞR…U5XÊ\?¼S¢"È«N»£Fen,G}™´’¦?Só"˜¦àî¹;Që’/¸r¿ëšz¯XÎ”`áùÃ\Î¸9îã­ñÔŸBÒ°¡@Œ´K¿À7e~ÜĞ×;©c=›¼^‡Ï¶Ö#Ş§aÿä•Ä-YŒt¢Z”×'’8Wüá+×ı¢?Üº´G›ïD J
ÚH:Õ&IÆ¬ôAëÇ}¤ÖAà?p7UO-‡tREœ¿Óí{a	h^¡¯ê‹o®(ØÏä‡d_ÉeÙŠ0÷#Sı}ÅıT:éıå:&Ìï¿ªÈÌ¿ÆSÓúM`·Ûœ^nÕ³Î4Øq™yf‰FÍÔ¤•—É†©‹Ë å!GÕğˆ¬ÀÊëf½âû£ÍîT'´íUş;öR¤øĞl£şÉ„—ĞÑì¹q%ŒÆĞ8$âñÕ#Y2ŠX|öetZkM{×{×'¯{ªôãÏGµÕa·Îƒæ$ºèwö“ÊĞ4$‹âªÛü¿<v“²—¶}Í*¨„‚êím‚$M­‡ÎpbÏ!8êÕ  şcÖr¹Ët‚˜é{“ËøP5«¼{‰óc…ÿórWöv–SØ%¨t!İ´ó¹ŒK\+Zw>?Ö/ÆqÌàÖ/ŠßÑU™jùT<ÃYÊ“å”8ƒ|Èşş~ÿÀéEE€+÷¶ ÙCLµ8Åg‰5³k§ èöîZâ	ŠgMFM*Ô3@>,4X›Û‡‚£÷ÿŞCÿcà‚Š]zö–’=ôYpç:Ş™¢öğo¨–y:`a ”.ÜÈ`ŒÿSj´áÔˆRßnÌ¢Aş³ó]Ê"­,g[İİtªÎ@'Åa.D!wTc÷æĞ%©èƒx¤mÊ
ÅLİÖë¶ƒ¬súâÆìë´>gJå–3
:‘
É£YH‚˜QL‰Ï²#ÌåpµúeCp+Õ€Ræ–L3´ñ<ËóÙi¼Lc=É¥pÓŸH—™S¸©n@‚³Ğ8ƒö;B¥–µ¶Îz|zãİ~š8Èon„òï§Ã 7í†í(ÉM ‘.Ô Á-ç×@Úÿÿ~¦#`ûşyãÕ¤Wô\€tR#bÇøè•%CJªV*Ûo#N.œ©lÃ$_# °79:<î}‘–M³R|©urÖ¶ºõ¤—Áü`5WhI?hm‹7)F	‹Sâ¸×“‚=µ“ú²ñ	]ÔÚ“‚•u„,¾lUÔq*wÓÛÀI.$QïñD®DÆ{ú“•Ù)öšŸ›°>Gr;ÏÁ¥ÀL³G0¬©Â-„£´¢«ˆÛ\Üóëùî­è£Œ]ß¤¯ÁkÛ{¨É€èÁÈAˆì¡C5îV4àüà½W6sË2ÉèäİµÀlñµ‰bEÄ"
ñ?	šMÿuî6ĞñT7^.Lƒ|-ïÃÎÂëe©ÿƒa©z(Rs8Ø=gs»"0b?·9€»şgÑSüXÓø¿’ú°Šé¥ÿ(ìğ¡ZÚŞi
Ú‹ß­ï¹Bò€lĞ„zò«³ xÈi«ÿ®5OxD-È’á–vVHº@9>á£¤2ÎÏM¡+ÉVvÎ‰<ÍáŞÉÜ‚&Š;?3õ\Õ¬LŒêê’ÂgV:UT×[o÷s	=¯LIy‚ÔQ4ÍAÚÊûåÂÈÉğß„ÁZ£"X'\½:Dä¹ì®M•ÊÍQƒ*9tD†æ†ğp^¤X¨mBá³^‰Än#«]½1'ltQ…Ìç¡s»Ìtul¬ÍÆ¸fˆ2®A@œb-’§ø’M‡,?7N§ï4rZ¤-Œ²làõ9ÛDIQtÖ)JlÆªS¦Hçƒtc¼n
‘­Îsi,%/<âë` »‡›Ê ˆe‹ä:fŞ£+©³îí—œïÅÉƒâÃVGT²Z'!Ïax£¤ššXòêîâÇê:uÍñ@È·×‡’åÆÕ¢»$4 SË¦²r¥Â(ımÍR™]f×WÛèg¯&ÜştÍ+”>¹Í¤æÕƒsú*yušm^Óú¢d. ”íqÎÏñêYer˜–°ŒD,y©ˆeN6·Ô–}—ñAUÎ*^a”ÈÆ`²ÙşVAï™Z‘Ã:pó_åœ75öôØĞ» ŠŒ[Çì_l(bR¶ƒ1RZG~‰*0ö(¥ÿYä†Ë±ŒKÀ1mŠ/âr†¯øÙÑy#õ]ŞOÁ>ëkRÏ»ğ÷JÔ:ã«‰ÎÔé3µé>¯ë >¯ºu—[h	€D,‡FtÉOŞ¬,îÌUÅ?tøEÎ=+Ï2–âæBá<©#RœÁQY,˜íèüJg[ú8ˆu·;2d,6\ÔÅÂ8ÿz^ë}öLÙ K…‚ÇõÆ¡¾jè^w	#åQÑ$ôœæ‰ÇF>ZÔuäê÷û§Ow¦PEÉ¶h4`ib¡ƒè(jÕ	Ÿ¸F/Ø²ÎAÉ"¦'‡ØíôNVÃ¥§x•i‘d
èî¶S?ñÆ‡tûå
Pã¯…úŒÍlìN
§£¢dlÔ…¿ktŒF¨ê­	v—©bé5é`æÄHúK¯İº~ãŞ	u´KrÆ]ÊÿCËÇ]Xß™³Â3İï¦Ó•
W™*YqWo®¢Šs‘%ü!, )‘¾Ì|š7ï:97‚ÿeU)Iú«?~ãBúÔ"F€º]ùŞÈÑQ  ]=Y6ÿ¦
HE{ƒ¿&Ì$(]Ü+cü»ØPN)¢/¨'å'êÕæZX*³ğN¹#(É‰?´ ”Â®®j‡Ù”Û­vÒ&¾t;İuÈW¨üñƒP­ğ…Xİ`×’]¬~‘ám‹o»7‰Šïx1IÆªÆ yİ*#ù¼Ï	\*ò¸à¯·àXÙİyf·5)ÕéË~G^ÃFŠöëMqİ£
c…TW²¸Æà–Åipªíêİmò¨fÉötßÌÖµx#íÀ`¬®<¼ja9x3SÊD¬ëìLKi¦ñ1~R\-v¹™˜|«L½¦ñd®aÀ‡C·ÅÑ¥­ÖpŸŞ®è+‹œ'­Üµ4r`úpùg³[¶ò UÅç¡Ú÷¯5¨2áJPs¤õVgF+‰ï€=²¦#å/*NVˆª·¬›”:"À‹²"ïFÁ——4il–~IÙ-¤˜)¦@*÷Ğ'‡å›–=`‡ãówøo5¨$4éUh~º¡A0*ƒ£¾v‹#–±óâÖÅ¯‹¬š=ù<…ø(—­×pÎN’Ğğğ ğîgËåÆ‡Œ„°´Í=$r9&i×#Ğ(RáhˆÓHGÀãŸlæBMS	éø¬ª±œ¾o^úŒ-ïŸ£°¢zZyùH·Nİ7ğLdîP,’f_˜¯˜ê;Ö­æ`€xUÈªi\ÚM¸[?5õÜq6,}ÛÚÇ,ÒıØ*ô•]+ŒÄ´Ô²˜†´[uw1Ä¢>Ã†Xô.-¿7ï“‡¡Æ‹3üƒ9Á%ƒ$V‰Y
Qá;È'“WG
4õš¾]¡ìP‘Ù<½81röšoÄ´(ŠîX(d¯3(˜¯ÌP…ÜšMKo¶_æ¨—=²Kp¹æ?@æ±1çâcuï™_•k}ÉãÖ”ZKº “ÅM©ªC6[°Ó‚ÄÛĞoì%l'¡àŒ ~¡Ñ3 {¨rµ¤J¯]¼kˆà˜ˆ	ÚlS7z{\>è¤DÓİ’F‹ö^é˜ÊØÆ&úÆˆVse›­U¦¨­ ¸<‹Y€—!êŞ¸› «òĞs—räÖAû¿ë¯‚dü¯Y
Ğ¼§Í°aöø0ÈZO°®L„¹b¡ù®°¸Èmƒ&ÿ–ÎWÏï«ŠâÛ‰ş	¢­Éüƒ*#×éI[ÛšÌŒ|ĞAb¨,ÿ^@¯ÿSÃÖP¾È«àË ÒvÆÆt›²õeö!‘~{Ô÷²d™Ñ÷dfÒèöÿáê:¨ê»ıÇ0®j¹v·ó+	ûKùäŠlg¤¨È;ºÂ1qÃÈHù–Îˆ­ìıîÒ¹•N:4y8°BÕ„™¤êA›¬­kŸ‹Büæ³ğ:ÍD‹O³¸û, Œ=gja5$eØ_¬a-®K¥Â3ì\nıÅ6jQŞ0DìŸ°Ó²¬~U\"eøì© W&áìpâPíëE6“­‚–é-WG
Z{ü8)ÎìÚ,RLJÍ™’óøÎMWô,¦%ö½°†VTñVFØuşùØkBƒàŒzwú¡f46îÒa€
ğj=Î³vˆ£lDãÙ~¯82ÏCëWÙ‰èĞÁ?söo€Ü ó7K\v“Å‚ŞNV…ğà4@¿	ßÓŒäƒ§šº7zË÷ÙçI8ã£&ï.îOÇuĞg×f°LÔW6Làö±µÕc‘ÛÒ`ú$J\şµU¾È¡k}+sÒ‚‰ó©|½gspIh­7¢Ü{ó¿?\I¬èïİ?Ô•hÄA¹ËØvÃko;‡§ !„ê‘Ñâ#ÃI‡zLv*¼²M]É[jyŞf^­§:•äsÉ:Š0Î¯¯1;ÉAŸ…nYãçC‹xõ©¿yT©U"Ë'Ùo™ƒ?õ˜÷™Ğø'¨ PTL0øEyFR†¨ú °«ZßFKüwîö°_î¸7Í5fÜ”µÙ¢™õÉI£(§ö£®û>³t~ù*j^9•ıa7¨ÅÆéğPÎö,2’ÙÄGúC°¡+4ĞÔÕ3¦»’±§,!*9…£3kq	?/×üˆ'Óz®˜°<®¾ŠÇÈ“£ag³:ñ‰Ë³û˜-]BHÿ[¸Ø	©UğÆt©¿Øÿa”ï¥«’ÎÁë¾%³ÇNõíeefĞZ ©çÎbo›Î°`$ÓmSXL5xûï~3ƒÉ°*jš¤Fz™ıå»p‡GzT’ú˜©@HWæëÁGG$H€÷spx?ú6"øÙd˜IVh&>sqnƒ½r‡*zuîç¹À§QwEÏ¨´@ÿ¹ô•U@/?ãğuøÕXÈÌ¡â&rÈxë[­MT«K`â!}/—CLÅ_¥¾k áXHÑùúŠ¿F?Ä*8‰#ˆ"x]ñö‚>ŒSÉäælöØŞ ëv^M)Èµ šŒÄzG¨òçÈÃ&Îé{õ*øÑ¨ Î­ö+~‚­‰êÈäu½û!Ynûnma»*U±ïföÓğŠQ);1Ã–ú‰”ù:EŞc@¸fô:€Ó¤K¿·X²Ã zæÆMW	>Ç¼ËÓ²Rì0µÏ ø3¥„èK«(öÚ8Ñµæ¤çº Ö.$Ù>ÌXmŞ”J«¯¸¿}¢ñGÇ>œq6eï†¦<¾³+|!ê<Ãf’Q=¦‹ğC@Œ`Ò×|•Ş6#šçª¦ÒlZëª°}?pµÆòê–1ÿ[¥~XÑò×ğî;Î¬"Š¥t_‡ya®`qxªÛ¦\<¬tåxõQg£tÀJ‚Ş¿š$„wf¶&€~‹=D4MZ3 ¸…Îš‹:™*İëq¶<Cˆl¤BZÙ¡nÍB.ÜÀ+Wëš·z¸Àğg
K(€«Ù.òí.ÓşÓrf
FG«L¹v²P¸ıT¸Ûò—›³P{á!šc!Í&Aîß¹…2N”èø¿L‹Šå^Óûø¸=,Œ³•ôÂñA•-·›µmà›¯C²÷2mƒ(±ü^]øVÁÑ|8ö˜[£2¯G_`r>üHs)êñ)d†*%n)5.¼UAÓÑËà#LSÓğù·Â³ºq@Û88ìqLÙ6*ÛÇÒ)¾İË’ÑÒUç“$Ìœ‰@o,²0Şd÷<l#İŞgŠî'ÛwTã¤ùZ¡+è‚öˆ{<ö¢Jyòï	¥zA(il‡¢9£êâkÂ†«EB¸úÚÊo¯ÜcÍ	äK¨E¹9=ëìUd1
‚@hX’GÔéş–¸ª4íXşóc°uØcÅcTjÙ2OÔV½…Æ“õP‰R¡°˜CÀÏPº"-œ«Ö(¾Ø¼Sú—ô2uÕ†	Ÿ›Âã­’ì	[JSM°†iìÌ%º[Lò1ZçÅ3fÂ&Ôÿóz¯’µ°#O¤ÚÃªÄ”SİnÛäF±‡bØğÁ¢ÒÂÊÜ$.BöÙ7€^¦±ÁYô¶ÑLÔt–“µ›şkÑÎ}btï5Ö‘I)h²•†'|‰ş 	m½»Õå¯ŸŞd8Ë{¹ƒ¡LúÃŠjir‚x$>ÆùÇ(2úëù ¢6×b¶ ÈDm9Zd·\±VÁØvg”Û¯u­v6ü™xVÉ»ø2|•/ÓÇ£±äŸv CÜ‚*ğ°ÀN,Z:Ñ(“±%¢Ö„g	RÆ"mm>yGqª{'K®İâŠ¨50Ÿ«TÉ^œÑœkèµÒˆ»mâ øtßÈ+',Àcµ‡`([~ª ‘•3Ëƒ¡PÔ’º¢éÈ_®æÛv/Ü °Êàÿ5Îƒªíhà6m19ó˜‘_Á7YÁy¸ÄìªĞ Dr®ÀÑ)Ô,cB+¢ÏÛæ=Î‚{ÀÅ¢NBoiy¿÷RCÆöWënP§®…/k†xÖÛ^äúòs¾ÿP˜üçÄ'z®ó
JéO½_˜ˆ„±o‘¼¾	÷qÃÔ°ª™—¯qyšäÅ:§Wf3Š¢Æ%s÷WZKğU©Ÿê0î×{s¬Ëf’@«Q|ßd(Æ%ÙªîKŞ¨êEÔ. ëš²ªl%ú­Pka Ñò„Ä£…\L×ßØÚ¨Îõ[ióPmË˜Pe¨áé6É0’I ¯7ïÂùÓ~%¬rc_®Wó£?İì;&ò²o|"+gÒ­ÔUâTÿnƒu'®~K²ëi©ÚˆÚ[a*Sœ:~BÉ	cúÕn•Ã!É7Æ,OÉ€>,²`Òd—›Ci‘ÄƒHúÁjAü}x‡G¡V.a•WH¾ÿŸºG;æã*+ÊÈÙ›b5&¬Eôl§àîŒW·ª™~o¬3øƒB™ªü"083³©|Y	‡Á£tşñL¦56…]YõÒ™|xã¬@viÌ#ŞbnØ1GPå”Ë±W60X33ş˜Qı§_»ˆK±.Q5§ˆM¹ĞFE1ƒ¸£¤%C¯Ù¡Âh¹çÖf^¤›`#ı`LglG\¹ü—Ãxly&;¸É~m¼•'´õ¿/¥Ì#ŸVÌÛÂ›ëÆoõ²¢«çÈş&öÈ1iö"&C˜2~’RNª½Å5Ë}‹R”¿VÍ17º™ô†¦³rKÜEåœƒh´>^ü~gÊ}±Cë±ŠÙÑÍ31ŠÁ[ñQıé”ĞøUº´İMyd½¿Á°/_{ÙÄuX¤EÇQsì?§¯şZŒ"Dı^¾Têİñàõ­;ùøk÷—m‹ “ Y!¥Ó¶•:+§`R@n¤ÁÈßæì„ô‡¡&iœ³©lpñø5ûö³àÓKˆÓQhĞÉ1ü7n™@º›İH$½85bá..h›kÚ,±›Il*K€Â0>eŒqŸjJAÀ)Şõ1ƒâ„åÇÁROßFü»,7z–vVP[O.`2ô‚r¯¿ƒü€%°:ƒé.S.D‹âm%?J’ï[.¢Ä‚Ö?¤º^*ùd}Ê°º'yúÛèÊ¸0ù‘?,‚pÅÔéIj× {ÜùŠïPèïiEWÊ³âÇÚ À&8|/Èt Ô` Fsg©sY+ ì€ lóÒ±Ägû    YZ