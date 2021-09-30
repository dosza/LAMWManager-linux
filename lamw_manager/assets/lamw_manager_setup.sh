#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4098664639"
MD5="787c11e91efa1bef19d855d6cce11cd9"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23948"
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
	echo Uncompressed size: 164 KB
	echo Compression: xz
	echo Date of packaging: Thu Sep 30 18:38:11 -03 2021
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
	echo OLDUSIZE=164
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
	MS_Printf "About to extract 164 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 164; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (164 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]K] ¼}•À1Dd]‡Á›PætİDõ|‚$QLOµj>½3éÈâb' ³3ùRı‘õ‡g7€¹…X·V)¾@åc[aœoÂƒÈáäå/NŸñ}Ù÷Fqâ_c^ƒ~­z$i>?‹–¤tQ6—¡(ÍIš®{
—§vO@nûvË7Mp{SFÑ6ñ’(óÄèjãP2_pïNæÂJ©ÙäñÔQÈÔÕc2ŸV«Ë¾ŠhæïñPÓÄ4·ÕæÄ$Œì1©¼ÿMkŒòàø°;¾Š·³dù}9µàõƒğR;ÀB–OÉÒ:ÇÀ¡_äúiÏ"…Ûı41iU m©Vøq
x¶×ã0ÿÊôó·‡ŸŠE}@ö`s†Ì"ëëJu·%fîT~®Òyô"\¹€`U´!lºú‘ß¥­{
{ée–‡šÃĞå×SÌ·¥'L –3é¢¸Ç¼9=E”$¤a«¦Ç=9¾¬>íYÖ©"x/vO<”¢%âì>×òSP«Æ;V: »j˜¬øƒ§££4ŞyB‘’³2W-ıŸ9ºêâø³$¤šJ;©™e àÚV“1Ó¥`¶ï_kïˆ¢†å8pŸŒŸcj?ºÅ›ÂXÖËÇ›â3+û¢ Èº”/³9è) ”2Ş²r¡\:˜íàÈl,e¶5:ô­9nV!•àA‰?Ì°8fy	Ô-bl…9:hÄú@Å®FKˆÖ(hhÀÓïïÉO­{©Ä²&å}-ªÛ§W1£OÛ9ªõÊgaµ{:m©èW‹Y8Â/i{ =¼8Ìš&’Xİ×ŠS(›«»}? >ÍØÏ\#Íö†L`j¦ ÛÜ­×²Ñ­ğH´æ -™p#bÜHãÄ.OÈ ¿;GÖsÛ-`‘7JAmrµm<˜±[^«¡x‹5yôXÔ~ Îø	xJzˆÔ
º¨É¯91Q¾~ò#ÕØ®;SæË÷½±m¾"Œ)ˆSìENÅ/eà¬‡/ÈX
š-RBı[…*³5ÌXÎpbà(±Hl2¦›C%„ÂËzJJïn4%=:.·IòÖŸt/ÔB_dWæEÁ6ÓïÔd`Ù"t»3ßsOr¶=`”]»!ŠYabÍBK6|.Š]3\EF2 û+$D	‹TLƒÔ›	œüi>,•	Ö+,€*…€@4° ÃÙtìAS±ËvÖÖ¡nüfQé!÷43G¼Æskà]{m’hNM—»5BáaÜPÚYJÖp°ÍàÔ°ˆ#åFßşO#¥ûÖl>N­7Ã$µÏqqK%´T0É†^Ğä²ƒ
¦	æ@´—‰à‰–Öí´‰o2FŒTJéƒgqÕï­ŠZĞgËşÈ]N¢o½Na¡>©¦FYoIÅ;4?êÊ¢“ÚOd-:¸¢”Ê¼›„¿-Ù°ŒD6Œ¨"Ù,Ø6á·§än²C.×Dán€à	£b/³x„+T2¡êÿİ8½Æ\ ÓGb—µfqÃø«½uøŸbÑk§äÌ!qD‘6Ô‚°¼!C¢[ßFd/Qs(ìs^ì&ÄÀ'£³oS3,#àU;÷S÷¿şÉßx¥
Ä®KçğŸl`„{éûôàLí6K"Ê°g„|Üõ’9…ß/I˜ròBè_˜r0(àSŠŸ»]PSò®,WJQp/×òvhí»™}ºü•+½Jç²¿+fà`O¼»0™ò:cnôÁ÷ˆ€ÜF¸eñúaM>¡â'	ÉãP íMyƒãI¥€G„Íz¡Ü[Û,Ñ;ÈÊ¢.Œº0l§6+~z~É™šì#4ÍJfh³Ìdş“a¾Ïãåî#ŞÄÖşıÿêøí÷Ôî“6€òêü¯&PM@ÊºÉ¥:âK¶ªîugB«ï¹–ˆ°9„ÎHMY¥_–jqª6‹W¹”fd0ûNI%¼èÈ¾”@„–
CïU.‘ëÂö»ÕVg]ªR:ªPÖ¢Ñş€®uæ°U¾i8)‘Îğ~äbÑU\÷;	×oRÂÏ¥‚û‡<ò0Sw…äd²sÖbëÎ!UÏhóŒóî€_à1êOÁ¤é-e4`|ÍÑ y>™[™o?RH:é“)GjƒQFÇÃ
RtO®”©šzî©©EÀzPe u~ÕÓÂ¤ñ™¾yÄ–ú?âé[õ{“'†­û	}SË,Ú´ó9Ø­µÅ|{Æ¸±vô.õX P	¥!ÆûQoÕ‚¥[À£@$°_©^%“¨á6VHq5İÒAêzmĞ7ßúá²voy4şl©ÇĞÓ‘ã%`º1ìüÆ‹øÈÀ@àæPûâïÚÇgHv”l2.=+jUtSœkb4Ç9‡ğ¹ŸgÚŠ“vRÂœµÄP‚òç”©
QÖÌ÷x}MÃM’:ì?~ãm<³Ø
`®u}ûß í ûs£`«#bÛWqåî° .Ä‘ûqâ!¹,‰•MMˆş%šÎğ ¬#FÙçqj”ÿˆ|+ÈÂğÌYÚÙœY·G‰K„Òª”ƒy¦­cìÁd‹Âßx›ƒX7ÅÕH÷B02B>ê%f4hãxo\FÕ`[Õå~Ù^ZÁ×„”#k¹^Ø¬`à«î'®üÿ!¹«çr”2djÆ–ùá€ím!-šUõä?(gÉ¤GI¾3uŸ k)Ú H¶	ZöãD~U÷¯¬"å¿0ã~êê/a6¸|I5´Bù-À"ó—&˜gpÚ±oÕ#i‡†ÉVÖ¾[¸ôh’1k#æ”åqıS0ı—h[¼H)¼^23qİè>7¼*Ş¹µy]f“…:Úé¢öëpÌéìM{•<H¢¶Ê¨~€^íkÊÀ,üù†Œ#„¼KOnkÈ-o(šøî–3'Ëç°°ÑhÁ–¶E ÈµÔ¥Ñòôh+d‡İ™r£ŸjP1^Ã5¥ûBhûY0p¬÷ô­%/áö«”şœ2ñ}r]¬wÊ‚üj½Á³ãºšåæq‚ApŞ£“>8Ó¾*mô¨†$Èò»N„,ü4s ŠÆKúŠ¨ÄfM«ùØ&peŸ!¾ÛSıÆß@Şõ©ø¼Û99ä&Íûd1$wÑ©Áh/f>íÿÉÅìháMÓ›îWæSy`æ®¤W_4ØÌvŠ!fs!¨İÑAş—±±CU–ğèÔñÖ[¯gÿÂä9^VEÄ9Ë •ºÀU'Ñ€
ı]2„!]„®óØµ°©DÛßo^±å
êåî‘şL(Ì¶:xßcß²`Œ~'Û—X;øMÆ(ÀÉl9”KĞÈs¡ps¶âÏL¯êuà™Ãéx6M®Ç®›ëßsœ«yózĞìî ×Ÿ·#¦ìælƒ%qó ĞtA{{ïÀ¢a^w„,•‹¹	ÓL6ÂâFıæ&¾´¥×îÓ¸¸zDq~t¯fÕù«Î>6Ji’ñSß{-<ŞMíÜCâ‚p›ëéã‚ 5~ D%_Ö»MÛz$¼”^ÙÉ³!-•øö]ä6¿àc†øv×úä:ı¨­·¶ë…ñp1S1nİ†ìÿ†Ä}„•·Kœâ¼şÌWğ&’©fÑ€±ôÿqg¡ŞZkoèX¬”(‡á=GCŸ°œ°›Ê»ŒóÎt>»ò”ò‰»xJ–¾‘j9	O;A¼F5Üœ,TÜ]øUyÀŸpó¨2\æTòºòÈ„U|h*Á++:A¿"ÓÍá ôIÈ=Eó ¢<qšJØzñ6İäÄgØ†4I÷Ğ/u4‚}Å¶éo˜Y‡Ä"8“o¸‰+;’ Ç9=×ÈK’É¢’ğ‰C3©@§ìDœ„•SÁ8éÙ¦*áF5Û®Q¼–%ôÄ¿*¹s¯]ÀĞÃ²S÷b"`Ûj$¶»œ³ü¢+§šÍ?u>nhG6T­Ì?Y”úá;êœÑA¨ŞGà¢Tı
}w‚ÿbx4Œ]şe&ü:QßKŠåBÊ^;üyk²ÿxÁ¦vó£ŒØxnº”{Fïøv=”ò:Æ]NOWŞnsDÁÄâ„_uE2Ÿ4që*E®REóN‘IÜ¢Ğ1eÇõ3ö×T=i$7ú`D‘Í¸‚Ò:·§²şÊŞÛpô ³4şkú®Ó7‰;¥ĞfÕYªa-»á@¼¡ëÜ‘£¿É[UÆÕöøk÷æ®.,â›“$·a_Vqe*Š av°:;¯Ër8ìl~µ/»Oö^ò©'Fa±È®«Y¼2a_à_ iUıç½–Ë0{ª%ùÚº«è?(`'Di^:Ó*”.ï6ß•"àÃ¿ŸŸ¹q~¡woZ¿È[ÚtÖVşœ±ö/üB:N<›É_ÃxçŸ¸U»o7sdé8^Ù–“²‚$V' ‡úëÑg7µtin,’ø˜ÓLœi„êéc`Û3¼roüpBÆ¨)¬´ìtlçVÄI•´‡KóÏõhR”3İGÄÈëE¼DxUÜ
v:<À0PDªéB{2×ÆÛ+4™öó5­Kü^ŞH¦€g}î;–õğÿóQD—ÍıR…vÙ†O€x®q’È$ ü¥zá‘ŒÒaŸFÿÎ×K‘&Û uÓG„fr¯²‘Ù›,È…e˜ÒQå!¬gÖyBÍè†–¥vÍÛìÿv}Ö}WöK·¶êU%Z£ë…,¹Zp„ÃsIä|Håè	8_sÔÍ„9Ït+K%±Nú×æç;×­ ñßIÖ4ˆ¾†‚meµwôÕïµûºªpe¨È¹4A=2'§ÕÎÌ½(ú"’èó.å°UfÙhø9/slTæ4˜8&ÕØ²vsÊvÍšŞÙxÖÈädèvõBM˜[ôN’˜™ü+ê£
Ònû¿9ªf³¸©»~$ êƒPà¨U·L¥Øró¿@–›|õ0¤Ÿ×™Ìg—«
î.„`àÌ,“?Ú‡r€tOîù%ëHÈÈ¢ÓPÎèğ“ûr+ °m ëîU¶”J‚8CcÈ¸I3Ms~€cCÅ.ãç5³8.áê’8quVàâ§A¾êsÏˆ/I+åÛJ<çpcaÔâUæ9±Äg8y«üCº$[jæ¥X	ˆoÖcÌéÅ/
s^›Ü«L Vzc¨çiİ:céeD¾Iøk)¬‡#Ğª"£Cûyˆ± "	EF sœù³ÁÆş³Æ&\_¨@=;T•M¡Ÿİ{ÇH¶İ35OO¿°Şb“¥JPğ¦[Œ+Ùl< twÀÀ‚¸[åæéË+éŠÇâWI_¸S…3r¾%"“¸V‰§“+óóÂaò®êË×NÇ½\íØ“ªVtıÇT=uÔÂÒÀ¬Iº)İÑ‰aÒîU¡p±}ıp'ßäiñ™…°Äp~+Ÿ»³¿|¨‰rü!â®§Éÿº¿ñÖ£Ä®ğ}i‹ó=b9)â°5Ÿµ(Õ0k(¯i~xs†¢ªØ{Ü72İ;gº70Š—Ï%ëZìÁÉW0r>ø˜©,½sâğÍhw&.î{¼í|6©öğ÷Æ­=¦%«§eşGDªüÄû™òÈ¨`n}H¸c6¡™Çï!ŸOÚà¼Q'ë,§¾ê‹8,RsæùªÉ ğ-QD)Ï‘˜¸·mËNæ´J{Y/ÌŒ^>¹2³Ìå| zåu<«ğqTîpF~ÔRzÌò¾€Ún@¥¥Í>OW½6ä!!¼6	îtkMT/0Î,/˜m…&&CÌtÓÜÉL•'gMÁT£ŒÊB*uÕ£\¡"ÎAºeÓùç¾!Õ;\mØ&ğÌÈÖ‘5iïŸ§Ù“^¬´ÄW¬è€»-½já„»š°v€&Q‡^@	cé´wÁg5;Ÿ½kÆFó ¬<7‹Q;–›şˆqRÚ û¢'}³Ü“Î²GªxÌİÀ¼efI: Õe<ìæØŠ–^sš [ìNf0]®7c«ÓsşykJÀ’IªˆñxŠà3äß	²Â mğ6;> "©ânóè‹®”ìä’XØ	©*£‚¸Ìmø[ó=üO×kZû¶Kñ¸ªŞoõ?8ıA”¬êÛ®Aœöˆo$¹]y‚qTÄºÖ+bÔ`Ÿ'åƒ`ÂÀM³/ÿÀÑô=ÿ¿M"Ã]ı¥.yyún×¦+é†1Ş¦ÍÅ|Bÿ
Õ” ï3Ñğï±Èú3cõ¢ƒ¾4Úôü½º&vUƒ›3Ş‘¤ ÓüÎ#iüSä_`¿…èpØË–×’ƒ–Ì„é bnË.ÅG·`öÌ¹á¥Æµ@_ù¤v¸½¦½‚àpl¥˜Ö¯Q&|y°odµlÀdìÆòùy :¬Â'äÄXZôªÀ¶ÔLFn @7¸oFO¨İt´ÓR<‘t´zvc5ÆAÓÍ‚sëÍ€ ¹®6vÌùıLÓÒyê$°	8˜Ç’F1FÃdUØ2çĞ2xq!Ş»©X)ÒÛ_tï…•É
8Ïë-ãk›Lˆ¦z'‰G!€íl1û>š3.¯P¡ïÚòM%…c–¢Ä…îé‚úmşYÅ ¸ŠâAíÕ8ê“¤58ZÛ±kÙâ‹P0#¦ï	6xíöô/­&]—]ÿPëE ø¥^ºÆ7š³¿ÄãşMŸ—3‚OWÄ êË$…™ü¿ï£ÎFÉ±{%KæD—Á©N/x‡…¿xç£~1¥öAEÚ¯(\BÌœÿrev±NƒDR
:JŠİ5*’²¯41…e^‡İYÖÏ "‘¢â˜c`}ïÃh}ê7w<š“N¦¡‹¿²î½0Eòe<EÚìĞ­³ô?‘SÉË8Xë.Õ—4ĞV–«»äİ¿Uy¢*”–Å}Wé]XÀ&š0±W]xßÌ
8W¼2¦şQ_cSñ¬(™e}Dä…|s);Ú?løŠ‹Ğv§Âš=ég¯ÂöD¼ès½öÜUüXë”:ÑÏiÑ ‰Y`¯bö‰J%ŸÅ×PS-² †JÄ(Xïs<{Ù—Àjã»Ş£n–}Îï3,¼ÿ@·!@éTR’&#È	Ö»Ï;19ùû¾áÃ|Á×]äğJ…1—Ágñ%	ïYlë__Ò=æÚ× Éyé¤ ï\Ã.p¸Z×Úº²uNPï,D|ÃñÍC¾4Ã%GşóºŸ'ìáˆw_?ÉÙC &*n&1­óö°fÌ©úŞ™„x¡êµ¬’o+wJ•ÛøttA—×nPØ	!²ëšk*>læXXÖN¦ù
8Ü
ÖÃšGTÚõ‹×§!ïVİë/îµS4Ü'’Œú¶k®s2¨LïS“–ÏY‘«c—8Xk÷´:N#£$-‹£²ç·ƒÓ¬ ggˆÑbD÷§‡Ö_¼+\Ì€Ö„íÚOV¿\òT¡›¥ûî€KÜÛÂæCuT›:V+Ò`˜9‡ÁôÈcï™ûÓ†åï\cr áÕÜKÔ‚ä4ˆÈTßõoçò0àXÙÁèÊKä´Áv&Xƒ5­N>¨à(Nku–Qs‘4O;´ˆbT»·<ºÌ‰+1â·…lœ‚-šÂYP1[ë”íZò·K8›í,Ñ ÕéÛú`”CZ‘ ŠUXK–‹E×¿™¼Y£~ˆÀQl»­,B9G\Å›¬“óxÜªŒ»‰oC¶ôAùŠ:ó¸±Ì½'VÑƒ‰ë1iş@Ú°ôÏ¿Ÿ=6Å	éÜ{qîù÷gMó_i?ß¬g <—fÊÅ4¸0'l¹tÊÄ’æzŒ*WÖ,xŠùŸƒGx#;51«¾Ô	Î‹C©ŸÇ}µ`S8‚~Y&Uï
ÙLò¸>œZè¶¥¦ÿL@‡İ¼zÛZïg¡²æG€èä*Èõ»òçÜ‘ù19U

ÌnÆ¹ô6ô–ŞR .'²³£a2ß­„rk§nüØ›öd<¢œvf§Ø!ôÏUÊŒS°Ç7á>¸°Öw¹…)ˆ
ß.™+Ij|,£óEˆƒ¹z#²8u0ˆî‰¼ÄÚc¶İ
à Uí¹hí@eV@kÉ–k`‡”ÇI­¡ÿDP¦RğŞ•¸‘âæ¤52’ÖÚNÜ®C¢K»èQÚº®7¸¥ÖÕ
—åD]©ˆjiv­º§ôÈaAÆ#6à<ˆ%Àû¦X)}Ï[t¯T	MÊ§ây\Ÿõ­áe¯h"©eÍG1£|V¦yşI)·@üèüåE¬„{ÍäS(Ôûf3Ÿ°Õâ´I~EK$)³tTğÏº ztcïÜ¥YÍ{Q¶²(?Ûº³t£±õV¬.?1C ½×,_7íõé£¨É	ŞÍ¡ÀÊr€÷Ëñâ$ÊXö]˜q(Ñø!áÁ1¼R#Hl†÷Jş¯¾wæš5Ÿ:Œ…ø·4æ8¸³L'µİ•¢S¶ºäùLb-fjÊÜ8ñúî…\Ô·»ÇXş¸!V>PÌ&I-˜½¢Ÿ‡«ş“°8½ÕÌõş*5Ê{#‡Ïçîp°K?'GWşXü¦ ³}*FV~ã ^¹†ÁĞD¢ç¦ïcòılÄå8µ§°©\zSiwc|òT 'àõÑÅ@ÍæÉôx“¨#7ƒ"şZ-:ä{E#ç*šà;ãÃW¢‹£RÖ²ú¯"|wE`–èüêÅÊh]šı@TÄ_nË÷ŸòS1VPİï1Š~¿ÚRzÂ)ª\H`İ]Ïôúûog·®–Ü–´E57ôÕ8-“} /	ÅX-”›éá¨Êb$Á¹™ç)üèšüÅ_…>Z°ƒ$Ê§
İ:UGOÙpD]obÅ!¡›Ÿ>(>»èñ­¾}—d¦&x§0§«4‰+@g÷ãqÏßXJ¢"Ş os:ÁÁb)ÑoöÌìÖG?$f‘a¿»›Š´ITh"°ÁÆj8c·ÖnÍÁYô/ş†åã=Ê»‚ª5ÿ·½!Ÿ á9«Zéšgh"’ƒ²sÂ˜\—†ü¸÷³ÑQå‘?8Õ–Oáa‘ëÅó×L¦²øœ½3RËEÁÌ^M¬j¼AöànÀ-êåÀn¸ó[Ÿª:¬“&™PV‚”&. ¾‰xõÉÎ¥¯94õzÔãî?{t85››¢=€juë¼­+²ÕÿXõBE‚ŒŠ´uõÑñÈ+Íğ1'Ñ¥6p‹^µ‹À‡DÁÿ³ÂGfvøö=Õx‹³Ø)ô—œØñŠéƒ!NµªZıåÚ[lóbÉÌ…%‘XÑ­Ä3«[Ö;Îİ‚µŠ^äı¾^®¿ÄÏ•‰»*³Ğ2™é»5¸aşŞWæy öJ)†üQ¬üåî5Åİ˜ºsÖµà{#,uâPÛHŠ†S:oXo¥7 õÓ´“:˜Ê“Ùùœ.3g¢äI|íşA}ûø&È	ÄJ¥A™Wóe›D`§"‘#_5MÛ„Rã´¯p“˜1” n`Q™"âêoÚéŞ€Z6İX@­S#¥ü·"¹nSw	 |uaC–ÊJø…iv|ß/wÀ`ZVÑoO4%ByşÀŒ“,k‰¿êÃSj w^D‘nvì&ÿÆ&tÜJ$eD:£*«WTƒf˜äO*ºåA?˜'İ¹gJ5À™vg€¨YB…4“súx:BI›Ğ†ß½/jİ¸]d¾E£åöYW­’N;‰¾Ç3u-Ñ„”Û4e@§ïi¹¶k;+­!–‚Å]<xŸwÜKÒËv¥1ë]ĞU‰–³f…düåã`_bÊ³x%ìâ Ö#ŠÆ4úr+så`|Ny/n‰‡K é©sÿß®ŞIä×yÙ[·ªººö¡+¨4rNf[;` 
u‚Òâì<;Ñö–±†f`µÇ¹í?âìny:Lûg›&»L›9¡¢Ú/1Š>Æ­Øîê„å›Hê{[¢pĞÚphQ-;>;Š g|0ê¯ä'²	Àµ¸ö4z…ş¡ŒêO4"‰ı:Mz;|3[İ\òqo|5È$Ù¢µÇÚl·AKÁz†]'ƒ˜hÿ!Ş§ê¢{•Šşô£r™ĞO¾]ÇèQ,~&q9n%Ó{Ñ ”ã%9“½{;É+Œ2?-¿qkî›wcÀ\UQ± %º»ÙçÉ°¯Ç(³ÑÆ½Ï_B›ªM £êEdÂ_É5Â@Ë9mÜ(yÑï…g$ñú:ª
7suczïtMGÌÔ¸`\‘ÊÔEí8÷ÆAG‹1s­ú:É5{,^J–ì ¾šñvÈŒ…˜æùp$ËZîeä³Íø áğ‘¨ò¨
®Ãà
zÅÊS}Ã·¨„ÒÄaHû!QzÑb:<D]õo§Z
ÿxFÜØ]Rá²ûx•˜¦ÃÑ®®ætÆ'IçrùÙ\
1@ÂËC8BµÊq‡|ûôš‚kmrŞÛoˆÙ
7Û¥kÑ9ywài$ºã”ßÙ£ùêäF/ÿ»ŸÎ%¬!+Œ3!‹tÃ³^¹ë55•jM85äÈ•ÔmúH®Lú.Bò½¶ƒ”£ƒº¼dLšE]j•6¼:V‡UV>Êc®m‰©Ø\Ø—„y³øJµ)gS¶ŠA¶Ëa¯r«Ãéqÿ|Q )T’Èº÷HëGÌ®í‡]M˜ü 8×C‹HW0¢Må<Â+!hm,ÿDbîİ©Brìü†ìÍN rŠ¬½Ğ‹Í$#jB{?ùÿr’t¯˜iÎXÒº9’‡ğ¯o xĞ4§”0$şn¹6½ùì	JâQÒ4´!Š#—¾8`*V¢Ğ–.O›;ıŞ—Ô4À “Ş)‚˜š»øõ¼ò}¥)"ÖGµI&OèÙH$®Í†Ú¸I©	WÀBc˜fôY[CØ×±™c~rÍ#»ä2ÄFÖæ<:Ø¸¦¾Ğ›ºD±zYã=åßx)†9*ÉôEjmRƒ"‚{°Nbø2©_;¦Œ İ¹8S"˜\*ŞÔÂş¢QÄÁ”j’ó3Px8ËpùJ1–‡aà81Ğê-‡Ì j’3şÉna<ìsú¤‘Àµ]Ş€ô†¢»á<w+«’gä§pÖÎTe c…eÛ[‚ÿ3¹ä†°‘‚Â×¢ËƒlŠä®j`10®í°Ê\h%Ÿƒ™a<Ì.»9­Øßag«JÍ‚^ıÿÿ"D[ş¼Õ¾‘ó-°g2’½¾¢;|©‰rŒâcÏ…[;ÊKÀK+à_ ZÙ4Ï	/j˜Î"Êª»ËLîhømvmÓÆ‚QsãI´I´RÓ×ß·.¢ ™7’6k?aõëÚA8É2Ãó©åÈO&Ù¤E‘½©Ü:ğ§{b$¨
<R9…*Ï‚”öq£–|õx4è3–mJ1ÍÂÆ;¶?Ì¸‡M¶¾·åPæûSCHJ’üúãhB‡ä‰ğø¨É%G‰S‰›Ÿ-ªBøPÅãÄ.#Ïñ•_â¯	€ZyÍFOJîu5V™wsÿœM5h—fÍLõU„åGöãß{­2ÙÏÒ‚N:Ùà)½…J©'’óï[mfØkı
¥³pi«€ÇduK4„İ;¦UÒcbÒVgæ™³YæÜ)“]T
øï«¹t28<uÎfºËt²—2e)ôse’whªTÅƒC`6¬A0üü¬ù([ùôÓåíyıËÓ(‰®ÁğS“ìq„°O„ ÃÒá(ĞMf a›¦¨$’$ËL·ıfå<Ô›ïô‰×æ×–Sıªg4nÎQ!)rÒ(bÍ›#ãÃæhUç¨«N hB›ZóT[¦#+2.B‰"lUæ"ºâŞîáM”ì^bÀ©Õ¦¬Ñşâ2E›’
/0Cr†kì„›ÿU›¥¦tÇñ¼FÕašì-ş¢6Ş»ş÷ßuéOõ®°”x½Ë‰QÁ#W×ş{\lF|2m÷w™# £ÒÄŠpŞïúc“,´AöŞHµën¢Ó4´h–Óñ~Üv¡û—.è àt´¶¨ÃûÜû£‡ä±Êy#™¦£…‹ •ö”ÄĞŞÀÉ€Æ;²‚h«÷~ïğ‘MÜˆ¤Ù\ŠvJ%iĞN/„`5)„YŒM°~}Ş@™m„¦‡&şe“<#@È“S!"6áü/+ågR£$MSÈßçtà‚‡s8ğGT2/\t°‰o‰JhèÊf\Ú,œõoG
‹øeq4cÅ×°şû+(ë÷3­Êş°t|ñÁ„x%üLÏ§ãbTCËj$Õ>ÓÆE õoÈ–¥§“còh‡ùÀuèx63•ÃópMN4OÄké5Bt»@'á…â´@D@YD
‡ö‡R±}sí)=+«Y–—§†t,%¶İŸJıéB‘"ÇµÍXòáMµ
™®M†¬M§¹~Ybu¨®ü:|îÕ_Ó¿ì‚à™Û4ª{Ş›Ã±PB›±¯bı…øCÄ²#ÏÇ ]ïštn°mNt(åzÑ$2×éáÒZ‚ÒÓkùÅ­&·†±Ê^úŒH áÅppYR†ëîZ‹ş5àeªı "ÌÈµóÁ>tÒoUÔtñq°—Ü¥óú½·nŞs”¥wI¨å$,MêÛ‘ÚxGÏPØ±nò ŸyŠ!õ“SôA&şİ}l_Ù%­¼d(õ+}—R‚gkuóÛA"ïóíÜ»V0|‹¿KQè
ôæ2qÜóEù)u 0/¶—eDQ¬úö«RyÈô‘+»Œu³ËUS%ˆ˜j>—dÏ@A ßê¸…Æş«>@•)İ¤r!Åpy1×_Ç™¬QÊÜªO°áFh›'“³ÒëİâòCÍE‘0«‚êZÑNÿ…‚H³¦²ä$İ‡ŞQpqİoë»Ù$‰³È	Än oõ[Â-¨úØ\ıAi—T»M}{AğH÷¶6Ø?\ô
4â¥â²&
ŸW±æŠ„9Ëê¨ı©jÕô¨L¥K5[·Ù@»§%¡èd€R÷Õ—iùR£#WKÔJ6òYÍ¼_B °0qa{ïd¼í5>àÄ[ØÎìŞæ¬îµ/ÎH„Ğ$…ìİQÁm‰ÕFß»qÏ;2l²Æ\bAÓWmX»=Ü¨Ğt|YåÀoÑiŒtä1ÍÕˆ¬`$v^g&yf*•l´HXoW±#Qª?£ƒ—z’];V»	Ñ\„[P<ã¦zG¹*g‚‹Ğ¸5Ğm¶WÓSOö®µ}†ÓÅj<5¶{½eM›ZUçÚåûqpO?ACš÷,¡‰·U73 	;vQÏóK’ê-„ôç‘ïµòJ°'³÷{„	ÿéÜbŸ_v©/ßíW:åÁÇS–ci“{Ì&OÖÛıãE¼išŠÑ¢…qü’Ñ]"lÌ¦.ŠíÇo0/@Ü½y\o~~ß]cÁ9øØ&iã\¹’1Ğ˜•ÔÅÈÔ'±”ä5Õ)uÑ/•¨ğlì=ÂWõ³T’J<¸­}#$YóìÖ€Q÷*Š‡¹C”]fÄÎâñŠúŒİ÷ #³_9S«I¨}ê‹ŒÌÓ€—usà52]÷˜ñ‚íÈÜö¨Ù½Yä²hÜQSm“mÙßâÏÃÙ÷Œ¥zm/‘ã~-dséñ=AL¤Al9Ø&XëSeéş@’}KãõûS•Eâb¶“&ÚÌH XÔmS·Ï§r«´ƒy#ßù>C>G8æíª”"RÁÏQ)Brs(œH_±LWÉøìÿ)‚Ì\Wf©¼¡ô)É‡}5*ë7ª1ä¸Ÿãq¤>˜¥âtŠ4ú±ä‹¹O¦Ty*µÖ7I(RÔÒ×Á¨4ÆÕ`Ø¶,¤­TÜçèè)oß%­×cªv]¢»Gpi–0BL3WšĞHj¤6ş¡úÂ1µ—1Å³õ ¬wŠ”²¶ËÆ@5)=m'®İÓïÖ-ÿuRr¾—Æ,JßnøR«ÑØª4³dœ3ë§Ïd«„ÕéÒËsi[‘t’‰Q™!}5;ÊÔ364“¹Ûb²šfÖÁJ­2Ïğr‚ó³4ENöM;£—„PÒ«¿*­»BÓm¨_réD·Tl Á‘YLúõqUğ½°x‚û‡-éÅÒ!º|Ù{^ü­àå’}ˆöç”´Æ®ÜEòïd“ÈfŞ›l.şì™]	“
¿ FæäÜN?=8	§{v¬>6•#:¢ò‚LeÓoÏ9„ŞfÿtnddcÉÉ•ÄÅÍ
?CÄeIá®ÅÑD`ËÊ*jÜ{¡jœõ“XĞsóÛ9"Ú)”¢i|¾_¯Ï.v>ægN;ªÎ°³*wÓff0j†=6’¡ìİE·»‰Ù‰¤üT9snê­2S[73¢ügV¯õ_üò«rˆï/Y]‡æhrM"½æ‘øgÈ`Uf\¿(õ¹ªûCÌG’‰•ÇúMáIy:œ±BÈìı°Ï·@”È©Àx²|Ñwˆë¤$¢Eî=g €jIˆåÔjĞ÷¦(®mcjÿqÒ)¿9‰yğ"f6³İ6¡¹çóI«9‰@\â¢U0÷¹Zj4û8âd¨-Èe#të<d;‚ÀÔ¯ iÊ÷¸êÏƒ°ípuÒV£‹Şå·Ë¼-¼à(©•‘¯•Íj'X¿‡öéèï¼§b©s(Å ã28Âş‚á×-õÓª‡}gP—‘xRoÓ>?æ7µ•''f}xa.´*U«Tpä«—\T¿§Nİºr€Ìg¯ü\•äÇ›«Ùn©Ğ~İTCR^ußßpİ€HV¼©$ûjI.õfÚxªZ |&!Ağ¹O#]‰5-N6µ;¯ÿo`ÜkœJô®ÿšór¨öa÷oêœø­6İ;%˜xªáëk:mz±Ìl[§v¬¿võåùÎ(d–Í•oäÕË½OO ’‡A¾ƒÿ#”3Â	éaY·-R´SS„—ÒnàK—ã÷Z·vwF’&«‘r‚Â¡‹b^¸M
ñˆÇd4gxK¡íŒô—Ã»=p¬Ót¹Õ]ôÄ–]GÅL.ÍØ­0.ª¡°KÀfÏğ5µK@ñ‚ËNßBH¸?ÓÕŒZ£›lY—3nÆ<
Oö¾1şgù‰Bæ^[º MPè	ÄÔ§ÿê‰F]%¶¤±D.# ÛÛİ”şr¼)G5~ÆNÙq•î…¨É¿ª‡‘ïL•®¶¡VËKñwQïÀ·}ãlAä%•m¤¡Y‚“óîê‹Ğà°((¡Ò¹…®”Ø¸©ÈªAæSL€ÓK„1’ÚßKZ£ìò‰qİLÈ¿³ÌøÛ‰!±àLİÆN	aA,Ÿ_œÖ–˜©Ãä¤)¦ìÇ77(·ü!ªÕ²ÁĞEB…ıšGÈíùGó-r/ù<]gâ×±¼Ûf™§û¤j‰ˆàŒë@JÏ¯m©ŸãŸzëıˆ-aàq"gÈûŸ•k<h´‘tÖëïüš8TƒªúÚGwn­eŠå—EÖşd4F¶EÒ‰øàsWo#~BÈN|çÚİIÀŠ¬8ûKsú½Ğ€R¯¢0ı<ZAt¤˜È†á¹^=^Q÷ˆÙèşqë3hWùB\¬ïÇ+Eœ AcJ„Éº|éJìòÂğáø[Ä¶Ì(MfTf	|]x_bm“4%Ud»$ËspÕ~¨ÔÒ=uIˆhyĞbĞ%5;İŠŒ=}KLVmêÿ4]¦£êâSVR¶vˆB{Í~p^·M×ëÎÿšA=ÌUø
¥ÈØâ÷Ê…l€rWÔ®ÇçÄÇ½á¥œHM&né£ƒgoN4JÿmÙìé»<-lvœ’Úç(ˆU!ÅàÍ¢‘0•Ô}Z^çãi¿FÔx‚é¡‡“=ÃYµÇ‹½hîBJ7%Ó›\@üôâ?¸  I‰HëıeÔºYş3áwœcÉ‚”-dÓf¾©HsªS -¤!Ë=—+œ™åBè­[ÁI£Æ‰İ®¾HÊ]MÙ™Ê˜¢~9(<–Ş³°ìSt3‘êÒJÚ·‚û¶ª½F÷ºÉ*¸Š[ôP²Å`ŠqB{ïCÑ€}]-<YŒù<gX/Ÿ#K“±Ù?ânŞ-ª°÷uÊä±	h~ƒ?}ü©>«Å<%QÚªRŞ‚¼ŠÕ[£ 3&hšS’°œ¤eÕKÄ>/¼€Â×*ÊG®P`(Ùö´ÕŸzïùLÍ³(=³Ô©âñÃr™ş²¾åà5xÏ™!,k)B—âà`¢DF4şš}7ÈZú˜‚¦úôi2\Á¨0åš•ã¬Yğn³]ÎñÍ¢s9@ºí—0è ‰ˆÁ´B/½œÅ¬h	<DŠ_’X4ëã™½íøÚ>rÄÕ©Ã{5jÑĞŸ<?}8¡C­14ÓódDç±è¢¡÷à¼“D(¨m·#dK›Mk‹nš_ik7t9»zßW—İÒ¿
XÖ\S3»µÈA£¹îÅÛRİ%Ë²½ÌÑ8Ûgæ7Ó5ÇJ²ş"´r-†Â]“T0T½usú¿:!aß°
´û½i,ˆ‰VĞfš¶»fO’ÎÇHãrÄŸ•ºöä{}E¶êÙ"4¬@ï(üKˆsÎ±póıFW•ñM‰Y™¸•x…æ˜~f<e½voóâ-«~S³vûÔ®Â(Là;A“Ô)Â|ŒˆÔ,ÊRÊIÁ±ò•—W)D(DÔóÇä¼-#.8S§u¸J¸İÊ‰Oñu:té)¹E`îÏä”À5¹]7¯¢"y&-ÙE`éîÏ)°x©*“YoÅ§5˜ÁS¾"nE¿.¤7W—HÂ³óHx
]×xÌ÷>k³.7>D`·_]+Ñø^Qb˜ç÷ˆ†göM&ùPı:ùköìIH‹ó,‰o˜¾5[F<åV¨:ÛKlëéy äf¼9BœN<µå‘‚0Õ}øE!g–éÈ<ak©AôƒÌ§ pÒí–hA{ãC!ÎÄ¦GË
tÕ•ò@~Y%˜\†ãwwéc‰^$ÇMaŞ¬”A9Ñ%èÑ[W¼˜{T<Ÿ*ç§Ä2X¨Só4o$s¶¹¨fÿ¶«d9çïRm±ÎÖöUDr½¬:òršF9¥ìÅép¡>[Æatì94ál…6º-è?]i¶‚°ÜhXœZåû„#xDş²7rÖ&V±3“¤>kYÆÙ}²+‰¶b)Yl_OKü;}]1¥Š'ğ‚¡(öõ‹òmOœ-Óørf±ËòÍ*Iï8¿ùWı%Jx=4CÀf<_è¤Qg³†Èm‹èµ“¸È¤‰Pİş™Ÿ­zcæW&œßR¹ZS„Hºô ”ƒP¦uÛéÉ8¥v¦ÅìïÄFtãİn …?'?0Yxex×QÉ½F‰]©ÜœfŠƒÀÑÙğF³'5ÅlÕnÙyu÷õxß¨õu–„ÄĞAçLKÃÅ`Ü£¯Z¾dMõ1üesR¶pØ9°£s*VJêÆÀÛ³#/½Dw¾İª²0¿ìq4Ì*¡bÁŒU+À÷T+x·Ê&[L¿e;Ybæ.±£éÀçâ<$äC{±‚Âª‰MÄwÃ{4Íã,ú•·J §ôÀåSíºTîFŠÆåÇqiwOè÷÷,n@ÈµËºŸï‚âxÎ¾)€M¹>ŞP·A/ş%tÖÃä”OÖ÷Ô¾æ&÷’×0±ˆ‘÷WÑ}p%‰x'3-’ö·)µôsÌD^X›"@á'aÒ§Ğn(ä»«›aĞ²pú¯ÇjdÀ¡WqÔŒù®ôK¹… WòC—qT%´=Ugbû†ÆUÇ°¡¤ù ˆ³Æì`¨W¸?ÖRu’wÊMÙÃ'DNCã52KÖhšÎ·`¤t£œã~”íMÛeOŸ»?¦néÛ‘gª“¨¿gôğ°Y${²€È…ò±âx›ãÌû®¼g®|K”sõ %[³SX½•ä2çØI¢èz)ğçŞwÖ1(+•–Ò–0×>ÍÕİ¬™ô	±‡G×’©ª>ş)òDÿ2Éİ?ÜÍ”oó’z2ÇE0¾£Sÿ7Î{øJÈÃ)Ğø	Ÿ„EÕ‚¼)Èß%ÖºÄĞ™uëy‹]U­ÖÙÏ‘ÒX©ùñ‚¨=>U}/Àµ*İGÙiö2Ñx¡ :¤ }Ä÷uU &Ü=.È¼3Ê]”f­ˆ,ñ³6˜PdÉğ¥[OQMÛâÉùŸjon¢ïé[Î®æ[¤„ŞùÕZV,€X¯~L¶w5JM.wµ°–MÜ®	L-¬ÅmÃ±ãh<qn×@Ó@uDüRô/tHˆFçÓ±*ªÏÙM7ï|µ5fÒÿa)2B—İ	Gu1
õøô¢XÌ¹O3æœ|ƒ@wûÖv€¤K„õÈ³ Åú¾Qv‰â^ÙYb¼Ú¤'ú©Sñ+Š"İç¸ÙÆø¡î×ÅŠÇÇª7ğ°Ò[õâs¶	øş‰"‘u©ñ¬v\ˆ?xM~è9‚{#Ê*“cšQ§g‚d¹_ ònÍÇ-®G'òjRõ›ˆ9•à‚èP¯J©m¨!A»ÅorÛKÓêŸ"W’T@‚Xk^ÌAÎÀ”ŒyDBùnØknô:q™yj¥$½ç}Ìhh¬ÀÛÙv!‡çj ê;@lÃÈ.\€`Z kAH?ÿ43=gFwfÙdkk~Àµ~Aò(AjˆMÔÿöÑªMhŞôµ¹÷›ƒ–İThR>±™­m;bıòØôi–[Í*ÌÛL5"ÁÛš²ŞzL?;«;ı:ÁŒ¼ùÉÊGO/D5ïéZ;Ã¡…Æˆ‹gBœ™°ÎöËŠĞ<wO¬oiÁ‚w‡¥û½í‡lğcÊê²X‹î1êäMşÄhe@ƒ…î{õ¨<K„™]X–‘#iYˆ<îÒa»Î0[]I¥ˆVª  io‹öZYÇø·Ÿ¦Ğ«ê“îp²˜ á]kx|®mÑæ÷L»‘v‘e[Ác¸Õ€ìÚöáË#³ƒ0lè©¹plÏ>‰O¼–¨Ô?ˆu}¢ŞMµykéxõ·(ÅÀ±Vßê0ô»(ætÆ—†m¥eo¤OdNP¾¼ì·‚4Hö‹b6Bvg+òÙĞ€H½ÖàxŠ›Yã{¡Û"£`«Ú\|OP‘2tD²æ³¦w¾e£8­å1„Z âWŒ#‚òécév†tÎÉãYP=ií>2gœ‹Â|ö±F­x£ÄˆÃ44İÄ;šòUM¶ólº­«L}çü†ÍáÉ|«¥E/ ñˆG¦hÖÔÓ„nOx¬÷fì¬/gaMåu¿7ßÔö‡;÷Øİå/y!Wœ±±Ş4/eÑ^pÖ¦V$Iè%+§ñÓ ^Ë/À±Æ3Ağ{}9]êI5$†]Àvê®ä3œò=Dÿ[ƒIM½ZøÙr¥´Ú³“Ñ!ÒÚm>.ú?¾å*®i8PJ©0,$Ï}Ğ…º´’+å(ê‹šıoÆBH½xgî«ajSóí(ò…eàòøïd'•2ëähÛµ9iäUö7kj˜KGå '¢Şı¨/İ²İñÇe!ÈFùÖÆ6Y.h »ªµ
Í5æL…R×›	iÜ(N¤'=Ô|1ØØè[ŞXq#âêU¹¯–€zA•AVQÏ‡b+0q0H fÿ)í95óøï &kC7DiÉó¨ÕåH ÇZ„J€8¨ø7+0Ñ üÚ 8Û®åš²BbI0šÉÅê3ÿ›åVİ×+¬¾¥bÖ¦ÊøÃøb`ebZRAº}SSöi]wı6ÊPùÒí;\ƒ±a”ähEİ’2vª›UÊ8ÙÛ¡–ÙéÖËjø›o½Ì3<Dq~xÍÄ^ANË‡˜	tÀÍ5ôÖPË,î#r3G»Æ´—koy–E“:wÚ0I÷oùHN{h‚÷€ Ã@¬’JQT…—1Å
¬ÑÇC\]Â¯ñ«½JÊTvÚ¶æ²ÏØÄêı‰§÷µéÎsV+í ²±Ÿ¬a7³Û38èT­õÌN¥m6.qôıúÕÑwÖ€,î¡&áb­ÏZ´—722n/S¡Û©Í3™-­LÁQÜğàjÚ_Môê§Ê“fÎ¹EOøŠTòâ•ñøÈøO7hQN1W$_y	w¨MÆ ®<#~'^Ü,Ã‹´`ösÙc4ïJ—">%Å9r$“Y/˜%'hõpS»ÜıÉÃLÿQ;·,·¥ğ‘€ªèQ$ ßT3¦¯iR·lùG¨‘­H¬8LKwãÔËÏzUT¶|¸½Éş,™÷)ueÁk'‹B ï
KY§èsÉ½\ZàwÈ$Æ¼+¤®}òÄ™±¼È–e4!`£bò~ëó‡á?¾OòpY“®äeÂkî-K›Kªä÷¯9»ÚXÃ7„ôüNàò<a&áÔ}Ü£Ûr«ğ¬;rY$eÕ¾%äÛCùáËq2{¼V×p'êÛJs.XÖ²‡Æu|R¢Å)ö)9ï7]	Qáî/jewÚÃH¶ók»‹ë²@Ì0)ïÙMÇ9“ˆNvİí//TrùŞ^#ÖkâŠ	~IH"?Öc-(˜æ8&µnSÂŒ\*öµôƒ¶ÀcÊ|SSÕ,U“Œ§Rù—ËáõıŸëÅY	'=ŒJ?+ZM}:´ÓvE4tQ8ydõO©¥	5aôäÛ]èª˜±ÆuíiGù¸–Á;¬¾ğ9	…âÉ¨Å×üqÍ¡!‹
ud/ ËY¥ <‡¬+0ñh‚òRâ­„+ü›é¸€'¿İÙáÿI@Ïİ±@Âë¼·ç(ÄB#ºrKùÖØvûô/ùrNJŸŒYA]Úwó@zF^îıÒ@Ñ5ı­³ƒÛœcGE#×øØÄ3`2/BRlYcãÔßÀŒbÀ;í•µ¢·¢ŸÄ Õ.d8'k©(>SWôH2º«höXD%Óò¶¥º$šPßè“PFe±yK¹±Dß•äëiI¢Ù[ßs3C½|4UÇİñÍjF[‚I€äØ–l)ßÈ‡¡)à[•›!êèœı†¦c¸‚à>È¹n¯Ôˆ>;¦˜~4‚xÙ|d×±b K¯#¢m’zì‰A`‹òúÙZß~NÛƒö3p®Ø¶zùóß¨r˜¥t¿iA§«_Á†ãv½<'¢k@®‚ˆãÆWÚv}UŒR)Üé
JJİ4;!÷¶w'%NféòEÅZ4;}™àpI¬ H‚4ËÄ1¼¥ï„ÿöÀü¸U«®IêàZˆJ9;é)ÌÖ†šâÇ3q-Ö™~Ï ˜WÖ ŠDY·¬uÓØ¨¨zàÊŞ±Ä/Ñ+¾q´EôôXyá#<Ø4‹ÿ¹/'àğó£ğ»°Óˆá3†éDÂ_Ğ.ë€Ä#6¸s,’tïH\?k‡Ë×ofb£[H‚_SŠ[Ÿšu¾ ËècÃ!Û>Ş| J üšp§ÒªB«H|ëV‹µÒÒËå pé¦Š±²ã}´l‹©(W+N®€]Ñ(âuÄÂ}û´ü%ËÕ¯‡ãåû]éöHM¿Ñloñ¨Ïu³
T8…C!sÛZs6j#1Ş¼3+!œhh£d8gI¡¦>J&Ó[2{å§Ó;‡+ªLM.™ú’Îá×s8HûÆÎ-²]µ °òIXäÒh§›ĞËœ!6­TÌÆ+òre3ĞfÒÃXìñã'™äAéŞç“-nQb5q.Ğ¦Kaş9 ¶ı&@»Jˆ‹Á„¡¯Ï÷º‡¼ PxÊâaØF«Ï5hª‹,:­w¸™ÀM`›œWî¦4zNS‚x_R#;WıRÆµ9‹åzE³¸Ü—ÄáòQfÉc–i/îÁËÄrü8æ`}‰Î¾	Šèä/“™¨{CßğÛpˆ!F¸
K©{j;’YšOC<¬Ğ­ŠÚL™E>pœªºIE9 Äû›@xşb!ê»>­m8Ë	ëWvK€—l}—ùarÉ\ãƒ]±ÊwÍYù¥”^6ß4â#`˜ÒşšÖú+\KTF½Àö°¦ËèÚµáâ|ÑÁ©FTé#Ş=ôZÔüreÜ=`ü¥l9GÉÎóˆ‰|ñay†mi=Ÿ´ù:?~ ù#¸BÏ^õÅSÛµ…,sTfàˆ[T?)AùG_¼jf–|àOUÃ€İ³ıİGÇÒp@'´‚*¹1™&Ğë=[àZaÉ8g
Ši8ãçÊI#~\;»ˆ°zábøíW›ÂÓ¿n8º9õ‰9~»¦#³^£}É²¤_‚8Ú­¼›£¾¦QŞÕmIL-ˆO$Ùt"¶)®ıƒ˜™}½A,)Ü3¨Æh	Æ¶7f]@5ŒôIäšØ3ógà!PÛ1~DÏ6ôìŒó ¬ÒUPï*!’Bl4dí~÷!BwĞ¦ÒVE¸ıjY!NØ-Êúqƒ"-ƒåİ÷EO	:¨})±/Ï¡WVmè³ê	#Úb˜Ã+æÍÌ/â®Ø$Å%Á
“GÙJP&ì7õpC1Z\Øæ„(8ísıÛø$/µa”³/ş*PPu@ÔòÃé¼cZDâù\x„Â)—G‹ÆĞW†¡]‘Àu~¯A?¢ÇÀS(ó¨*ü.ùl€@!€VÀ8(DP°VVûT„*'<ß/Ÿîìz#äñ—Ua¾:ª(`şP{²Ó°9fhâÄ‹aÅû ”ƒÜ³—»?`ùtvYMÇsåÌ(${2D–¢³;iÅÉ@.&î6ğù[Z˜ì®4øÜëc+%ÈÅæ¿áyãê»çÒ%ôy«‰ß”<ú¬„.·x¨€jö1-‰ó¹¿5åWû’m¾r4L7'üÕÃª¶÷Çòòy‚ÅôhªüçõH:áí€™Ÿ™ğé
òÔ¼1*Û°Z’¡£KsdÆbİçzà×àu%z+Èì^ôGr|XÎ,ï¥QÊ5P>¬¼¶¼ºT–yÑ&ŞÍˆÑ|“¿ŠÑWŞ¾.WvxìÃd=‰•dò·
wÔÖò«@ì¥y¥˜ŠÛNX—Sc^”5VzaÜDı} P§ÕÙ7¿ÍCSÊsKÕÃ4¯ÑÃ=|Œœš¨%Ã<şi ÒàÄÁ*òwàåy[ÇÍÿ~e¸#&T‘H,l1¢ËfOî­À	€˜…ËtwVOŒÅIşh‚Úbha$T&a,;¹x)9)f2Sj”ÀëÉJ…{;†ôbB¿¥‹SçªÄcÇCjöq  6´3?ÆvX7 ¯‰úR$úD—Ÿ4½k!+zpÄYt7ÑÊrf9´9Cj©Ìv®ÌœëuñŒâ×ªåâZµ\:{<êE‘3ï©n,G0Là©Š²œI¶7Ş‡Ä˜*òŸ&Í¸1K—Âƒlå6!:8ÔM”øAyèÀ<?€Çc}Œ‰İÁ¶‚ãàĞ	êqÅÉŸöçu’-.=(×ŠÀ^Kui±Í×b-:Ùwo+Şbñ•4¬0•Mzl¨I=ÊÔ¨œªWy¡Øúíª‹aî…UòF×<DŒÀ@õÌ#Zw‹»5)íË€GıO”ù©Ài
 x5í˜rˆ¯Ø’KÑ†ÜîR^Ån–6¿?îóŠjEÄÑù´4¹gÅ£ïÙöÙY”Ğ®ÊO\Ä¯k)¶v^ŠÙfñ%DÛ{€92x%/·‚]õq¹¢²shÎHZê;y±aR÷İ³°Ãi©òMš4SjC<¨ÍÀ_EKP°¾¾.Àõ{½„
q½Ş² &]„¦ñÌ
`¾ı–™‚‡ %·"=Œ‹ráöö$,S°(	`ŠqÚ‘Ÿq&…^ÂO5–Ì;SÄ¿É%’yC ÌûÍ§t£İøóE{AúÜ4¹·Níc‚Ï"÷Ëzƒ¥ÈQÇEF!‹Té=„®Z1I#ŸZì™™£üÛ‰‚$t—°Œ™“™İ;x¿¬ß¶XfåŒ&ˆŒ"«Pş\8Ÿ@PHî¿Í6Xÿî©û=d$­­·€4Èhá(<¥ïÖÑA1æi½`e¬çî×t*ÅÅ,ÎûôíiåÅ:€;W’Â¹<N’jŸ>Ã÷ÕÁ¾W¥×Z1£«Dì™)Ñ,Éq¼’—HcŠ^Okuæúã²PKy@,š¥2^H”¸»ÇŒh†Œ¡ªÜ³˜³Œ<Ô@ˆstê§ác]–çğ:¤«}±µe@H±Ì„ÿ{lîı˜‡Ñ"Î%
âš/\9ó£¹·ª±4ù:E‹º¤còäÙŞò÷§ß…Ù£æalXıøÂáZ&Rs¿…×uÍ çr#3CŒú"ÿ«˜‘ ñšUaR‰¾=ÍMÉ/Ò÷^Û¿ÌyU2ğOõIw5Ó¥=Wı8*K"Û%©Ã“|ù!ˆcWs‘dLŠw¦¹LYXõ©¿%£…I(/ÑDÎ9¹PÛÖ£êPuİ9ÜÈ÷òÔ{ØLfıç¦#'ŞÚXg¿¿A!¹7)±vÒ+ºˆLî¾ÆÙ +>*uŸØ¢–P/GJ©âŞ7e¨‚5gşA°¹{fÆìx¦8µdT¦j1rÍy‰Koíkbÿ8RYØGüàıv3÷Ñ>/l†ã•E9ß¹òı#Ş™VòöM¸6ù×öÏ–‚1\İWÀW^tÄã÷wXÿÿIğí’¦ïíÀŠÌ“=;ÜÈR$¥\Aıç/BiÎµğ¿–M!³AÁ4qDéà>ÈŒî©Ø`^²œmÓ©bşì~:e%G:£˜Y‚Ì/•Ÿ9‹@UyFİ¢™ö<èhóË€1ì{DHßÄdîÙÊF©å;WköñÄY^”4ùh5hš€%J8m„ú)äÌ:Äo_™µ¾#qÈ®•<·>±ûÈ eôc„#¼EõKõgN¾Àµ’V«ÕÃQ-ÛQ×Â¬o2óµÆŸ¿ñÎb£m®–™BHòî¸Y÷m˜*.LËÊ ‰®%X^†t•qø=#y_då›cÜw•ì(Ú¶8©b‚CA~­e€³¿‹“²g­¦VŒ$phg8‡®@Í”ÈƒOÃŒª’Ä³Äü¹›Ô{‹÷Ö‚·W æ¡æçñRp¦˜‡NÏ¨£’ELsQ¸ã+ğ0f=1‰x5™»?o}aîÑP’J
Ï;tzØ‡·[Z.HrÓ¶µ‹àv|FE5ó¨àNN,i±y!°À×l­÷s4ïyyNÌßH§½½Û·`ïZU@ÇÊU9Ú‰R!ë³–Î¢pÄ€3Ï,g•›²d†‘Qjz(ÌÍşÿü
†<qKGî‹±«çˆ,o¬)¨_HÏNƒí×RZq±)“8«'ŒÑ	°Eìr4ÔâuÚ‰îää9íáSÛ²› yĞ—ÙK8ğ‰lïâÃ²Ş[³»xµ¹T®ÎFA"
Şÿü;·B™ÉÑ‚²÷3óy{Æ—ïpi+Y”>¼uİÏj=¢î‚]:¯yä.Ï×®°ní«t|uûÅºi—ü>êö°íò‚A¥sûå	ğÓ‹b­)†h~ÁÓ›Ãàú<Qz3æà}´şËÄ[©F>Äö/¦°›kFàò`,nÁäfö¿jHÀ´÷kK+/×T&¿N;¤±Rn‡ê½“Ä&;å‚=Á®|}ôÛcZT›£¡È¦ûà¶±™¯Dúxö÷²t´Z¶üø¼ˆ@<ôŸæïQd»ÒO¿dÄïšqx¸Ä•&¨êë-`Ô?(:¢3„VÂvğÉ†d—T¡ìéjÈÀ
‚›å¥Œğ\œÕùüv(Ã{U`Úîiş’ş4ĞêLaıÓ@¢q´fÔOw¶0¯¼	7âEKƒWÈ¸ûÚŒİr ;@pV…×“N»wëIèé‹Jå±šÃ«.tÂBNBPÙ›vÚ _AŞÓÛO>øCäÖÊxyÖvÄ—d£ş§İP[—J®¢>¨"œ8‰ÁûÊÍàµ(7p@ÊÎÒ§JiÕ„ú[LØÑi1Óá5]Xí@Rg´ÏHÓÅZ¹¢Ï”†íÚ>Sd)÷zÉ}:Œà	!OR()rtºÌÊu„n-N¡
æ˜©¿±îä ß‘.1ÑúñM¸3‚¤É·œ§päöAª>ÔY~ÌPğ­A7&®Ô¥00XcûV€–ü˜mdUIkñğ^˜A±ÇNÖ@v8«Ğ‰Éd™l ÉAYEæï±úxL îf­kÀ\_(äAÚq½/Şä”kB.ß£›kÇr¸¶0ÙQ`võ	²â¬Õ—´V5~3îÕ1ôøYl^J«šã&zzk$DbÜôVöĞ`W$£eá§fÔ‚/·ÇN2óÂwX™ßØZÄÏµxƒÖŸ¥ô[Ê'Lü¬ÄÉ|îRÀTUÃ’~laöÜW28ò ~tÈB!Rd†Ü÷¸òv&4Ô6øîÖƒe…Ÿÿ9yµ5?‚U‰kÚ0oÖÛ1NMÑáÒ·Ïà’Ù]ÚÔª•mÊ„şq´î=OL6;Â/êœï 57òu¨vÅÑÿOcy†Ğ¤àÌ©r«vS‰›õhP¾˜Yk8ÎkÀ8'ıóı£œ¬ ‡v¢î8ğAyBµ·{¤fpÛˆÜgoêÜÕøTªƒ‘çş_ç7Cü#ù>¹>ÀEù*GO6Æº¥ÖS/Ò’¶ 
i:Àäi²g¼eõÅ_Ìœ¯Â…¦›DœÄ°5•ñ<Ô;×™U­rÿ‰Ídåö—n$g ;¹D¹&É0œeq`éŸ¦4èøåt+ÖÓ¾Ïè YWJğ»šYq¶(¥ñxx\´%mÖÛä®Ïı›åİ.Inkf´ÌVÌ©ŒÏiR+kQ)ªÿŞ0´k"º_F$ÈÕÕ‹¯„.± ¡b"N^’ÉnÊpıôï÷T3Šâİß4Y@å¼Á¬EdLŞU‹m_Äazı´ÌºdŠ¶æzÙ)Ã¦é D·”Y<È¿ŒŸÎÊÆA5Õ3—¼ÓDï³V¶±“è£R|àóÂ^2qlH€?Z*MîD0àİØÿÀŠ±Å‡“oƒ®Ã™êüŠ)IìPìÈAÊéŞV]Ô°m­Á;Ñ_ì™C)H|F%@Û`8ö2f\N:^ä–KÎâ6…qD¤1Zçİ\ízÌ€ç’.‡IAóäû?CÅ¤0Ò_â”ÀBM£€c‘ëdö?#•¢Æó’'Šêô$cbö M=è€’Œ²K~L1Vö³Ğ‹ï–¿LøÁ‹se;Êf~1l%ÔÓúYTœUO)œ‘O"uê("zVöÅ‰átºÁÌë]i)ÅousÒËıåá˜ªŞ	xnBlAˆä®Ù›¨8Š©vÓê EÉŸºÈ”\)¦
ş ü¢»ZP½/9¢¼T(FŠüÊw™‚f`o°»™-ƒV¡‹¾€ì
`’jÿúa/Rs÷¤P9È#à¦£–@aXM©ôOìœ®ZàÖqFåÑùºE
	åd'ÚªËÃ5BáŸÙ/àGe¯w0Ç»¼×? '˜o£K{>3Î8W‚’éìÄ9$%Îüï‰V€¿ˆ†5ÚW÷w&¬÷†>;huğ„ğ&HY±™EdÕÜ÷ÑÚê™§wÛ‹âå!Îqş¿ÅY"±=ä ”°*L»!zY`m7_Ş9}MÜôÆÊCÀÒß‹^Ñ++"şºî9±*Nºıga:w†:Rñ^5ÙÏüøEq%7bäî$L ~ïátŸ?¾U1åÒ,zı(‡Œ;‹-1nÃ;.ê¦>G…P¤“şue“dÔîÁÙÂ~>Ş dßÓdÓ ÔQšÏGm°rü`\öO,Êç†İ4šÚDâ4[_øÃİV†ŞYhC˜…í0o@€‡x®—jÇ>£Ù.inÊ¦–Õq÷!´û%xs‹“Cp*OüĞdŞ½z­58œİ*ãUÙsn3»\C}òVÕC¥ì'1Ã‚MqÎpôø$ºcV.IÔ¬s¶ZÏæ˜‘-14€ô6êe2"š…É/BÑò0%«!SÊ’%{¼¡NíÀº¿Å0ä¸c_Dó‘Öê³Å.QÄÎ#¾SyÌÜ­uÍ·gÕøPªKI¯dGn”‚0J)‡bëÀ%]Y/ì’s3#ô¢&ÚµŒO´o%ğŒ‰ƒw§_hîè¤¸£9˜ĞçôR*Ò-cWvVÄ½›Ï›ôc†ä}?·ş 8pŞlÆÍÌÒ8Íl¼k³‚’}Š³šW“}²J{]Æ];ˆ¼mbzÆX!ÓŸ²ÌÏórƒÛ«=)¸ë±ô~á¥®}#µ¾‘IˆŠX®:µ8Ù±WòÂk	öáüÅÜré‹©61Iõ³u«ÙåÀÿ´Ê­å9§FÂ„8F¸q¬/o§ÓıƒÕTœš$aÖjÀ¶½+_³ˆ.×óULØ×#ÁúÁñ¥Õ¼‚f½›È|¤?Şš$âg¨û²kIƒ÷.öJ‘	ºØì­r,à×uq¦aº@3géP§_Ò¬ƒ_ôŠñ†º:lÃÏá.S¢Ó¨uPh²‘¾	¿Ÿ*CR•ó‹¬–DD¬‰	[dpÿ–@»û"V.x?èıõY3ü¡0ZØHøæ°p–8œ3ª5¿5&XYV Åğıÿbm³bP¾'I&„m(âÏ³ó¦V’)š›H˜„¡wšÏ<ÄU}$éó0+šB#¢ .z•Ğ¨\M¡ŞåeØô°ˆÜü©ßI¦şŞ©?‘˜ÍùÛ²)Û7yñ)DwtNlî‘"D¡¾“ëu“²^rš,Íx±/3X-¿'ÚG½¢‰¦Kù)¶Ê!HñYAÒã¥™ô"¦/mFõÚ*hkÍ&ÙÄ«!Ô¬?QÕÇ„‹öâÅ0\—(oæU¡NÔº460öŞ¿M‘¸v¨d½Ò¢’Ï²uó
U#d ^ê…O8FE Ş»òÄ1äşì‚æ-Yí˜wEˆî¡6èWå'SDØÕ##jW×îï€>ˆÍ´ Ö‡ÃX©ºor1ÀS#.@„6Föi)ë‡"‹ŞJ3jÎv+N¢‰GÜnOAx8Şe­_i¿Òäù\<wñÇ@O³$œÉÏw^¿Ì3+»Ñ=-)Ÿ5çõõz¹ÕéñêøºQñõ7‹ÙnfšúïØù4<ºoM{!µ&î¸ãÚ9L)z5¼+ÖW¢Z¥Î@"vK*'_È‡Fñà¡Ósê{*“Òx-`Ju§ŒîoıÀk¬]¬z6éĞü¶Ó¹MŒ#IüÈq	–kgâ”	ö‘‘²—ûät%¥?33©Ø|­EâTìMnPQcµùÔıLƒ
û]’ˆœ?ßU/?¯iÈå“c•·>y’ÀÄs[ã|#lÏát+êÊ\g×f0¦ÿT"ˆ<¯‹ Ÿ~n'¡ÍégtÆ¯N\Jš_€ø‘ki>’™ÍvQ²¿¾Ë¶7ÅDÚo!qML0y,üìL½
'Æúá&ÈWİˆ¹¨›ÈatF‘äJ‘CQ2z™÷àÅÆÕ˜0¬zÍ ˜+AıÖ„¨ÔxùÇ–¡ê›åôòo8iS óşÖ˜Iö\·J ƒÖ&’¸(MQ·ÍÒ]ÆÇhB'}¹H¨J.èÑ$ÜÕ0Äsó°º²ÎÚ—§w0³4¡ğáï¼a…H›»Œ©‡²ãÿz£uAlàÛ°¾Á¤(]‰jÄÔyvà§T€Ô™TpnÁ­ğpiÎå]I3½°ó9ø45;ñUqĞ5F3fÅ¨¬úÂ34_Æ¡¡/^’XSlò60uğ'§oUĞ|%Wê.	ä!øQY‚Öáud7!=ú©3*¸veCÑ±{›SŞbrH¼{+Ù…òéMp=ËqL)Á·ínm±‡İ©&~?Š2ˆ­*Ì
Š8‡*@QMO Uÿ7Á¼–1PÍÒŸ&ü1Y$¢
È®BE·Ä±Ä¡²sI\øƒşÂ™+6êÆûDêò„#fe!Ù©CÎË¾6oiè0\qA»g¾½OçJ^|»Äò±í¨ôËèë·åÇß™MZ¼)Ìê‡õYè_µx »Nıù8^çõlT‹.)a*FåPádÃå“Dzo‡„v<
«ŠI‰ğ‰w°¯ºñ¢ËİÏh‚'EæĞßT åÿñ°ƒØ†û”ìR>h7F’§Rô£e¦F]7´ÜokÈ¡/MØj|-“Ş“ SøàÈKp}Ë©&ó1şÁ:úÏüóhøP!Ò(åb™AG¤‚T$ƒ«£MáÍ\óæÀ®$ë)BkĞ@â ù&_­oÙ™4]àÆoyïíHÅkúYíS6?¬âuhç¸H‰kBÎı¥ßå—~Ü¹Ğr<+™¾9xñÅ·Y	µ?¤x²š’æ¡ÍÃvŸRÜN¹apÎ*w¢jÛUWˆ!ûŒÆÁ½¯ÃOäHnÆ¢£ØÈÛ´€`÷d¶Ï½çjş×lÉmùZÎáĞÂñÀûÂş¦’†¹WùK3+"8o!ÆâëhŒyŸôå™;UgàÏšf£»Z’Y ¦õûŸöUzblßoP‰i¶YÁï¸ oFÜ®O8]2B®dú ²Y‡Ä}u²O?‰ª“¼‡¼™Ÿ4I«œDôg27…*ò˜s0u1{%¥›Ç§ oÃõîò¨<¤nƒ„ÀIË1L’cZ&
(8V1´[¢âéŸ”MWs’^aÛd4Š)!şÇ™kR“‘$Ã¾´q#p—®!/İ,ñªlD‘GŒ¼~Ä¹«6zõROZ‚ÚCó¸ø<Óx±¬œs©d¥ÈÍØùFº2mñ›Ò+á+’¢‹¶áNœ7|”şUÙ¢["ŞÉg„éğàjÓ ©7‘Êë*|„¸%1Ú¯Iô‚î‘òy/‘PÊ^Ùš÷DUG¿Ş×‰Fã‹‰%"q¾4¬,Åà0ósÑÏº‡Ï~%“£2‚İ|põo .¦¢>t×?ñ´W‰ÈòB®Ÿ;®±ÇQTY„Œ¦"áyqŞAàøüIDŒyº‘  ÑŠÑ§ögÓ çº€ÀZÑt±Ägû    YZ