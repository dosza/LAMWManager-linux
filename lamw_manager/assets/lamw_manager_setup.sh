#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1347805"
MD5="99975e866ec0224c2f95837df67bf4ca"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="19830"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Wed Nov 20 21:41:33 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=132
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ =İÕ]ì<ÙrÛH’~%¾¢d‡,wƒu¹[ô,ÍCf[¹$e»Çv0@¢HÂÂ5(@‡5ÚÙØ‡‰}·}õmfn‚’ìn{ö0#lUYYYYyWAuõÑÿlÁçéŞ~7îme¿ãÏ£ÆÎŞşüÛ}
p­íİíGdïÑWø„,Ğ}Bºã\ßw_ÿÿÒO]µtûrbë¾ ş?eÿwwv÷
û¿½¿³õˆl}Ûÿ/ş©~§NMGêl)U•/ı©JÕ3Ç¼ >3İ dNêëŸ'zà’#ßeÌ%›–­cõ7¥jË}FÈhfRgFIËµ½º¤êKDä:d«¾Sß‘ªmq@[jcOİŞjü-”Í|Ój¼¤DÎJ»LLF<İˆ;'ôÎ\ŸâïãæÉ+˜ÕÉx	`ĞÉ¥¯{õÉÜõ‰Œc¸)¦¢dÕÙRş*œ”è•çííÎ³³#m+~lFš\{"Ç¸˜ÉÉÑpÒ;›ÇÇÚ
É‚æ"x«?ìhrÒ~6êL/:¯;­t®Îé¸3œŒû“ÎëŞ8mnÁ,“gÍÑsMF¹JP ÔhŸ XªQ Şôé,pıë"ßa›}*™sò†(°oµÁ«¶Z+®E&ïqç©RN>ƒù-F×@Ô¶ÖuÜä¿ÏÙÉ'·Dš›Òz×rƒK—H5soÍÌµm×QØ’ò­‘PŒ-Â7ÌİñMƒ2	šÆÔöº¦EÙãÍ"Ub^©í©yèúÌuæÀ+dñíõ ‡°ª[˜°µ¤³sk°ïC!ö,4\bS{
›#q€3FıA;P Ufz@TÌÔ…ï†ùYøÔÃ¢ßÛ/D5è…ê„–Q]û3ùN#[ñnÂb*«b×*‚:>w×ÒŒOëĞËAàŸÎ'shæ7d …Ÿ]Ó1´Ú6ìğlé‚¡nÈ1-r-‘Ë)*'(™¦‘¶q«İà—ª&hÕ[RpXL×Ğ‡Œ¸°Ã>˜1~ƒÕÊ›¬,å;ï ˆ
™Ï@S¤:µNÚ|Ù‚L§‘Fª	•U5¬%¿‰r%'³C'¯s@ß®Çë¡lJ ÒLw˜w*&Éà“K”²ö$Qª¬Î×ş¼vÖk™ /Ì@ÌÏçfÀçôÎéê\vo48nş¦Õ¢äuólü¼?ì¡-ıM>Ÿ>ÁURËY¶"{¹0y>e¨G»Kè•z½.úT7¿Š]EèÌĞ	!hqı¸b¾ÒHJQG¸H®QR©’JB,©šˆÍpS,››ÂJ²­¼1"ÖÖM'¡TÂ'NV¡]7(¸O©’jb$°r$Ğù¾ur¬Ìyˆ<¿eş˜Â¤vFBÊ	Wd©’5° N>,‡oE-³±äÑ·Ïúø¼p`:2‚88 F=¸
¾@ü¿¿»»6ÿÛŞ~Zˆÿw>İıÿÏs÷mRÈhÎ&H•é{àùx€¶àZVù%©2vI?ò¡?rÃ†±‹î0¾’O-Å€Ğ3 FøW'1x)ô7Åüjú_G&_û÷äÿííİ‚şï6ßôÿÿfş_­’ñóŞˆt{ÇßµõOšãFl¿‘Vÿ´Û;:vÚdz’`¤[¿æ6/â†„9&ÂüëÉu2Iˆ}|b»†97!'`†ñqSJ,—õ|Y`5¿÷tŸ‰¨.«ÂC¯î‡TÍ‰"|¢(b´A-Ó61,d0éÜ¹Úú9eÔšİ_„H<#sßµÁ€ £[2Ñ1exì@UãauÓU¿NQAJëÙ¬æ­òV|†ˆ•#Ë¯<İa<¢]ê1¯¢ÌMŸÁæÌf!Ït(p¦NŞ*‡a?ğ^÷xE‘òV?
ì¾Yå¯iÿyÉáXı¿Ñxú­şÿ5÷†…Weš–Aı:[~Åø¿}¢ÿßÙÚûæÿ¿Õÿ?»şßXWÿ/
úÏ rAÂÌuRÂ‘A4â™äß>YP‡ú<ì >„(¦~
šÃ“‹§D%Íæ°õ|W!MÇğ]ÓøJ]ª4 ³@‡wàã¸ÄpÉÜ›EiœnèÄqÉ E°Ş¨cYîâã¿û¦~aR^¬Ôí©‰/‰HİAëÎ©b˜,˜ÌaíZíqR6iİ¡Á&†–ğ8`:/©>‘Ï¦¡„¤ñS]~€IíŸ‡^NB0±Æ®‡‡|Ø±é„Wä¢'Òøùá#)ÓgRBN#%c§¾UßÊã9O`‰šÇbìÂ©Ï}
1Ä/VİõØ¤ÿÔ@_0Õ§Ä“ÉÖdKÎ`,“ãŞ³É 9~®ÉjÈ|Õ2§8CU3`­îQ†<…“VŸÍE”ÃÎq§9êhò¿ìG½ş©-ñAd©µÌH9å:¢Øı¹´û %íŞ¹$èÅîäì#^ÆÕOûĞ1EY8áÊº’Ò~•‹H$"[à:a$Sˆ?ªç¦@¨†úÚ¢3Ék×ÄúæB>şt	cÿƒ^ğdÁ'¡M€àsÂL{úñ–9sùÜ‚g6ŠŸÆ{æ&ÿ"–Cv÷âWºÄÕã~¯c¯XÀgL­ÿŸÑİ¦“¨.×0;—Ks¶DnÛç *JÛfT#—k¹A2Ñˆ,¯š”c.rTY7•(¥KU—&Uîo¸XAVJ+$€,ò\Z…Ãs<è WˆhÇÃ³Ó$1·c…%ù8PV)¶ë[Ê¸œ€MVáj7+mß¿UÜæPG&Ø_zƒè`s÷¸wzözò¼Òá›È–:Ä°<æÃNf0^›G·Ü•Ìx[ÏòµºS_|KV—Méô‰İ¬.ô¶@D2XŠ" ¢*cJX·Ò”'95âµÕ ¡‘5†p/{¬Ğ\¬@^ÜH˜ Å„Ò3lja4Òômq»ÔMO×W*v‹”@f,±TÁ
™5FO)p,úòq˜´g“1¤ï±¦ƒµêÆš¬ˆHìË¤?JúEÜCZÃşh$ [@½|Ú$Jkş²;x¹#“XøÃN·÷ZÃ©.Tùr#p¥¦QK¢"•ôæ@FûgÃVGp4£ùE¬¢ÖŠ‚†*Ã äÃÓ‹Y"BV’½÷¼ÙÕ>÷ge§ŞÜÀŠ#À,`ÚóşmW\¤ãû®@º€–eö_ÉªOíæ´?<ißÊD8L‚#)² «K,|99Ü¬•j¿Œa :8åÃÕÅ|-T%9PìfN=Õ"ˆ£à¬è6ıÙr·T|bwJv'³9[Ï_"¨ya~Ş]Î2êîÚÿµ—°ıE§jÄÑT¤T
PîeÆ—VáOåRõÓ¶I¾gëp9’ã=4_ì>ˆæèˆÿÛDnÇãMDY»…-˜9HBg®Œ_÷¸²Å·Ò Ş0¡RÔŞÊ´eît›G“nm\ó´=ì÷Ú“H
	²8…Í£ÁÜl±êg¨A}SLMlÁyûç“3øğ¼bFHB_Î9’ˆÂjöFFLl†]ƒ4Å•*#Šb2Ğgçú‚?›A¯ø‘8:#µ Ø›ï{wûÉkÊÅy1'¿Nı_3aâ& S¨a‚ÕıÃÊ€w×ÿö¶¶ŸÏÿöö·¿İÿı\ÿ³±ô§è–­ÿõ?’\ V¢ó¦‰`=pH™ç:ÌœZ”×ö8B<èË]lSÅcl £â^Wª×¿ÒaG›íg{fĞnÍñ|Ó	ædctölôÛhÜ9Ñ49dSùGÒ‡7¦ñ’:†ëßBóŸ^vNÛıá/ĞwÒow4yk†ı3H=+\ ^ù­³AÈßÀ“Q*Ê!Ş§ôC\ª¡î5”È×yÒÀ¨Wşø¼p€½›İT•ïÅbŠîÿ54/\”–„¥ÿ­´”šêŒ­¾ËXW…¹ş“†Z6ËÆçùQšC==XjëK!Š›Gˆªx{¾xú/CÄ^qÿ­+›¢…‘¼7›@ê8a¯=Fjäj¯ÛîtIäVälDFKˆ¦$6‹£ M<½6âàôì¨ÆíÕ§¦uw­Ú°ßOP¦UÇ8W=K@øm¦FĞJmÔN’b7BŒ1cb4ÇğÛ°êÌåQc»€;p]’ ôÔr¢vë?«O1TÑ-²¡(}¯T6”n˜ßøïB˜5tÌ€ñ¼6>y„úä3Æøµ!v	Ôª×•¿7%)­­„D&©‚îà}SÓ'q•+
ˆŠqé?6j:x-²€£ÒŒ½ÙzÇ#L~Wzu $ÕZ¶İFZğ$3LµĞJPJØ*<?@me¦ïõTGQÆlB\åH–åDÉcL™Lä]2!Ié/ª§5Dk zÆwà»hDÅí`ñ;:~àW}ñş¬ˆÕëèÖü™¸>‰AQ[™¶•é­ÚF\“áµ&üÿ v4l¶;!ˆÖp§ç€õ
À“ı5¤Ï,İ9GÇ73ÓGÈ!†<ëAFÒê®Êµì²åÌs²¹tÑ|o3;›ëŞI1‘‰ï¸G¡+Ò©Õ²O2ùåBÖò>&ÃM-ËZäe»“%‡’ÏÄXÜï;Ñp3^‚$gÌRšJaòô©ş—…uĞ,‚_!pA_çp(#ŸÈ·®Ã(Æ=etR'â öñö6?¢p‹‹‘ªı,Ê{=îY¨û¦K@TÁù\¸37$ù«Päñğ1L=7%Qªé_:ÔoZâ~›«¸u]úTC,}ÕÒ;õUA†aT|ú‚'x«}%³(õÈvÖBòä|"²sd&”¬»¬—NfÁéO¢ËÇ£“%İLKÿù Û5 ’¹4?è¾‘Mşïò>dqÅ.·ÆI¯-$z‡çÁkË. á/ÍáÙ/Å?;îğyÒ$ù°ÊUV'3¯”•Yb©§{ 7‹1U	ÛVmñ¸nø½ÓÃğP\oî%®n=pšü®äqÜ3×§jSv<OµD‘¶t–/£¹ëÙÖ†LãáS”f¤KßğFé‚ÛÆä.¼ÄÛqì±»è‰Fn1Â‰C-›|rhQî0JŠ¼7Ø@]’.ÈGâbŠğ
Iá>9Ö*kåg	rÏ™»hdaT0Ú>(˜¤Ÿ\ºş9ƒôŠF}Õ¾š­N
•;	uYgÉŒs1cÜšïgúÖ9‚ˆÒ¢9¿ÉqöÛ	ã ¯V+4ˆ‰OÇéŠ3¼3Â˜ôçŸ9&8ã~ÿx”B­4qÀÓvæÄ0óÀ;³×j™íŒx(ìtfc²†;‡(Éèl0èÇÚB$‹äò¨ C>¨=Æ¯Í8ñ8í{İß&#ÈFrgß˜ók…Ağ¾)U^¡tûI_ô2¹×ŠAúäè±Håä0¾0›ŒÙEî<¾Ù—Ã·ÎB(:S	$¤Lß:ë0í{ ğÁœı£ƒû9‘øÚ¨üò{–“³JâuôÏXÜ[‡¿U
é<_!]#é²°¤aS'$˜Æasàò—ÍN -­ıWêé2>DÕ=ÏJ.ô'‰JuÆEğæ}ö]r>Àæé%õÄkAš1yfCCcŸÃ ¢xŸXÄ<bÛ´©ê‰bËÈöÃ¦ÍóFfİ ì<p=ş¥öıM[4“¾ñN¤Ñò©nS-İ9ñæ¬ØEøˆjçŠÎr_ }"4S][÷¯‘Ü+<k.uÆÂ§¨’Vå¥>\Æ®•Ô›¡/ËÃÁD°nÕ„.Æƒe?d×Çl£|Ü˜ú¶éè–6×A·DÓµGµfºcZ #Ïj 2Ôr=¼Šu³®Bd†sˆìˆ£ñ‹Ã£³ğÚ\ …[À5…Ş«“–¥3Vd÷	l$'+ Wz¥ˆËq‡ü)Z0Ö}Ò«ˆ¿PŞg:Xndå °9ßâÓRDB˜J±Ævï™¹…I-ıZ¬ò½+c0M”ËbÈ¡®OiôşìPpç0Ï¤7ßõ¨\¼V^´;Ê),å‚v®Ê_%y—îß¿LCxÃKİ
©V¦ñÇ×Š¸4ªà‹«@­ÒvñÍ_-Ö‰s|gŠ°èÔJÜÕä¤sz6é;'qí©T§°³„ÌŒüpEÊÆA·WÚÓ -,]›ÆXùi6Hépg¦.$|:O^õYRË«/Ã/MêÈµÊ®Y@m…?(‹Ğ4(jÏÔ¶A	€U°K!$m¶2ê×—mÕÑÄ$´¥ê$¬u²¹ˆ¡~e[Ÿdƒ¢TÏ¿t¬~ò ÉĞˆ!éèO°¼ñìà7÷3¼|Næ¡8ÉMAï´ÇYÒ³pÂ/çˆ20ÊÀª:Úç>Ø@Ü."¥J;pY ÎË¹{r-c’w±š|¿–W¼Äj¾C
aMZÃãù$«Y%'ëY.JÊ‚ rO–‡Y%1qZ%È¤Ê{ıBƒY¦=Nïx¾¿°UìTj7ıAçôWˆÛnóìx|«€QpŞçŠn¦’Odîü´/oF3sw$çİÖj7Õ9oşåİ-©BèİŒN)q	<èÎ’Ÿ]P°hàt'hxvå2í7ñÏïUøõpÂâaìãÇÄÄê!|ı	QëÌ~ ››¤JõwE…L ÿ# >Igå%òd‡oòt›@w&oMWZˆ SĞƒóÃ(W5\‡ò›ƒüµj“{ÎÑD•ï°é˜A&º8¥—áˆ„¡ÆjüØ}•èÄÚdO ş
¤âŸk°@G™vo,>SšDÂÀˆü	—Šî_1åKx“éŒ"ŞSìÏ¼«0£<+ÀÏÀÏÔâíÏt‰ÀY[IIâ€Êè~iÙC*€Ûj‚éº0ƒk9DjZVÄf%i›/¬ÜˆÚv”CÑ9'¯QÇÍËæ×ƒè„NÛŠGğË0'à×Á_NÃEœªj{™ÕŒÕ±ëş;…×óA;õğŠKÒÆÆ'W;â¡òJé\ü!›J!L$v#s·İä5nk…Î‰Z4­xø±0y‹ïÓ®‹GŠĞ*6ÖAùÀæôP.gÖÖD.aœq%än¹+²¹HhİˆØˆq"Ç—©W	ËX3ñêÂıKY‹,­ÉI•ÕüÃ®c”êêZü£˜SÁ€kå?¡d6
sëßÔ:§ñÑ.Ş_€ŸY‰¢ªÕºi¥Q¿IÄ§CÙ.£@Ğòñ¿¬ ä	ß YêÙëÉi,Ê¤P’œƒwÌü]w<.búøŸä¿Ûû¶î6ndİyUÿ
¸ÉI>&)Rò%’élÙ¢M$KK”Æ™‰²¸ZdKî˜·ÓMJVŸ¿³ŸÎËÌ:óšü±S t£IJ‘½3³Å¬Xd7P 
·B¡ê«Ëà§( ;X}Ài¹œ.´¨ô¢.<ÄT	F PŒZéZe'ÏÚĞ12Y\E“w¸ì§&Í(æVèmå´&İÑÁw¨Ü9ú¡½pWÆI g188:^(ÿE4QR`¥rÑ}²ê©Â®¯¬ÌÉÑ(QA —¿9hoR)l6á"ƒioF†/Y„}á×rÌÁLµ_Ø&WÎ”+Û³²ºšQ©L‡èzbqeNZ«éö,§2R97Jèh¾ó–t3–k§ßcÑ§?ÔzË¹DórbEœ9µ¦şŞ¥HĞWlV;9Ûfì==ÛüÂ4J&äx`¬è–U”LékæzJÁƒÁ{<œ‘¡KşfÇáû5?¿!ÛÏ,›TnYp.3¯Â
DMLç9\ºÑÉ¾Æ˜øÀgHÑık=ì6İA¿ôüÛïÅŒÊ?¸yHãïË¤;ªNzçü½Ÿ§¿¦cùÏ›hØÅ¯°ò£ÅI¯ÁŠ²>¡ªÁ0a[ş÷Ç8”¿Q­Ó…#é$ó³'?ò#4V—ßĞ1Ìøš¦Ñä`j&ã«NÒqÑã÷L!îÊšq‚‹q&ÜEu<áØòGœu.»I@ßCÕìwØFõwŒ´H0œpLFC™‚°FŞ‡}ã«,tğ>x²gà+*Üø+üz=ú
R-?ZòÛ$ÄĞ7õr:Ñ_$ùq?Ä~+ßÕz¿{á˜şN{ÓüF£„¿"Ô~FÀé›?F%ÿQd¯ƒ.61Ğ À‘'¸:\¦ßdÒÉØà°EZÈ^OÆW™%eüUxõúÄDôŒq{e%j®mEÏá jñïşğqN„««[‚m¢¤’Ä?3UØP+ÍIS-½:©|Fî¡ô`KĞLg>sıÉÌE5›×«ëUSÒ¡	^˜R™¤/y^jÄ•Ú\ÆBq;*¾êÎæ5-„(ë¼œËµ9vA§ê„rj[ãàQxƒ_:­ò¦Âª©İª¼:V6ªõSêV(ñ37G.|¢ÚKúK7)`á^˜MÔ4œšEäcÖÍVB6ú=%Şà…Qzî©Èj³‚‚áb¨Ï&ÒÈa®ŠK¬5ÑÌ”Qş-’«ßóÍSÉ‚eõ{FYÙÂ@¬	P5gÚæ ]Z-ò©´ğá CÒ&²˜‘'¤ÒÙ‚Œ]V<À«9„0]MP‘âš/òë ;ä’qŠN¹ë´Tî[BÁ/ÏËéuWúÄ4Õ$¬¹Ó-*
~21tNC¬ñ)pnzGãìäÈ|Ã¤µ€¨Íñ…•ÖÔÊë%lµ½ÓÆ­$—"`˜	}|Qg‹ÔÂÍù8|24±7å=ûîNKë•„mi•^İKC‰‡M.Œ}|I‡G'o1K.\áLDÂŠç4+ö+}Ãu³•óÎê$÷õ]ºÜLÛ»7Ù„L‚ÌÂ”¿ò«¥c¡ªn3cg±LvI‹ßÖåoúL¹! ğ;.ïâ&Ğ¾
L„œ½Lr¯§Ì.ÁhA£#4!û=w™aÃŸYlt‡üÎãHä®ôı°)Øï2Ãâ
¼›pPd_ËcaÓóõj{ç[¨AÄv‚«I<~/Úòù>&©‰Ô»ˆ`İªx6öØ{!{+£3míëÛ2±Ë¥NåÈ™ù
7­]ô6ÔQ[„:‰^·«ûÜòÖõ+£|Ò:KşÅ.‰pÊª¸WÕC »U^Ê'µ¸fî—éx™/gàÜy´Çœ¿ A4Nl„}›
Qøï¨Š»"g¹ĞªaÒnï¾ùº]œÒórĞ·q<]À}4ãß?Ã—ÔµIä¼H=6)',©Ğ‡“¦{ãÈ¥Z!!²œ}!~xŞö“Úi­œÇRªÕ.PÅUê'ù¬[nŠ•±5½‘§kÖÑÕáçšwsµ½\-'Wåã:ÛÅõn<\³®ğ{*•y_>Öüåyî¨·ËÉn©·Ì+İS½Oä’«=]3h¨›=åÒUüÎ‚ºÌî«YvÖg~£ÿõ€g9%§_W‹Ï³x'ßÎ9Ùá›|ç®É‹{&ÓÜĞ‹ğ‘¢¯)÷JÛ9ªm)Xùkd„%çÈbát¡¶˜wƒ2XD]$GFà»i;fk oæP·ëşs~üh©&zÈÛfÇ¬0NSñ9é†FQnJé‹âñ¨åÖ"À‰ÕLÑ µîa$
 ‚d¸+¯ ˜ŠÁ*ÓUèlDÖ.ci¨Yv`2J\\Ì£Œ‹MºJXT‚%1d&Ã®*æ0E‚×³…ƒPß±oFùk½ùKshäRÉv)Wy6éÊÂ´Bs[:S’p4‡çGÛGM	«íl³œ¾]&oiîÕïiuâ²Q.EvX)?\]Î¼ Ğ\¾`#2Ë3ôÆ¨WC“.’%µ£ ,¶_|>_Ê¿åó!––ù‡uÛªÚ–^´R¢Şˆs,)äçŸuB¼V‘¬îš(ú«ê÷’‹7˜B' [[õkkKD”x-šGMrÚM¾!ô­lÈ0¤/eEBmùÏ>.;æŸÜÚ¬Yf:=gÄa^±êÙ¸'S:áğÒâ—Ÿ…*Hå·ê×«k>º£¬(Mÿäøuå™ÿÕ‹eLÉ¾/=o/£x4Dß›rJğìÄÏ÷¸¤%’=ENıªTk„ØU“†«J«j~…„/|&%UÛÄ³a05©¢%Jç}^sTß<¯Éfà”c‹\ aJqÄQëª-7,âA=Ó¡À!ĞÓ®Ú‘cL®/S7FÉ¸„zGT^QÆm¼5O`0¶f\×	z• «amY›ÉB÷<-¯@Oü%ŒWı¥UAt–JõÙ,Ã#_•ù…ù
_iøBX/&P°7PR7­UÙGb¥Çä½Kr)Ê9{R…<].æ§XOºä?åÑ½l€Ôf0j•ÁFR+5?ƒ%y˜.&Ş Ähüä”v€)mòsË/6Ù:‘]8ùãùµ`\İßÍr¤ŸŠó? ç×?	çQJ½ŞtwñìÓŸ3şgİÿs£Ş¸ÿsÿ9ÿó2Åÿ\«ÖMüÏÇ5ú§æoÈ€X“,¶ç±Ëa ‡"ü ƒóÁù*`Å¢Pwp$î‡ÂO‡÷áéƒ
mšA²˜Ï„ñé%ï@JèFCQùz ÁA'ñè¯àøèÍå^ØíƒD%*pÜá7½°OoÈ¢.¥nøˆ!yf«h®d xòFî¢Ñ	ùĞRØë°ûH @(5Ò#ÄC^Ä=ÕsPìÛÅğ  ·POOpLw„•°uÔO}Ñ…‰ëğÀ_<oä ğì
õ"«†\!%ÀÃóñ#İâ¡ )WÀ¸+×±Ù¤©D¿8xĞ`>°o:õ6ÑyûÂÉ4ÂŞ-ñ&ÎGÓaOŒbQøˆ~z¹zFF–¹qüšËoŞ´–<³Yæ—ù7ä‘apL&ÌN{$cš2–#ß×¢Ü«3©‘…‹Õ&¼$ÛJêXŠwO?/qoG†—‚ø"ÌJà«úMœ¤H™!P×¸%[6/aŠÁlo®”WÚ(! Œ\Æ*ë8›««^"_±12:¢0¥oğå‹æÊªk ~ñE†‰†½Ñâ±§kÛ,7<­JĞOU0©%¿ÆŒÖ…–†¯µÚi­&>®šAd
<¸“pEa––8¾ÒR‰e@yS‡-–å÷Aå§íÊßÖ*_nı°jc6
2ûÂ´ĞáôÇ0§ûàŞÌÖ*m€ª]qıµVÕ“âñ°²0wŠ¡n.ØxbûšöáŞîñqk§³}t´ıW¤*{†²QG¥“]ØÁš5=@™µ;ÎTHû8-]¨2@à†6V‡}§Yí97ÏåÆmâ8¸ÆAªF"·ÇÂ*Í ^è”Üø92xSN¿s3RJf…TÏ©Ó›ŠRfbQMq°àZ†9‚ü/ˆªWÂ¤ôU@BÂĞ¹ã ÁEÿìa+BŠì
TiR
ç¡[cŠî¸ötyÄ²šåú–ş­g0Ì¨ô)oW8ï›åuıT¶x*§MXËS%u„~)K ­”5"[VÊ¯<<(d6è!3‰ZëõCØh—Gã#“®îq$}&G ÆÄˆ@ô“Œõqï9—§5Úw Ü0À
	Û	ºxÊßÔ7KŸ16œ¡d§z©’Ç¸bÀ¾i˜^X²µÌIös¼ÔÙJV~“ªXõxeú‘È„ÃHñ®şãÌ—Ë
 ÕëÔ2ÊØÆfeÊå²½^€µ¦~ëÒøÓá­šïÊ6Ÿ%¾ÓÄaA¦çR:*Zé¤.%PtğáZã‡$#•Í”0ëêÍ†ezÛúûzFÛjÍ‹õs{NÉB7kj©ÍŠ¢*‘K"µ.ÍÛæ»â€QÇÛñà†ãíw3Á	ˆ}£‚)¦e<ïéıÊÓjt3ÇzƒWÉ	0ëh4š(a·ûˆÏ8
Ñ*IKhóëKt[Q‚C*­	Ây¤½„ñŒ§³é$€òÆaÄ¸Ğ$¡R$OVWtF$ E)Š§Crî‡}QBJÇÑ%tùE˜œ[pÜ‚ù]­Vq½ø¢ìÂéÌD«POÇGˆvîdÒ±L;ĞÑ½jï3ëÿ¤3ÉİÇş^ şOıÉ“'ıßúãú½şï>ş÷Æÿ–®ïr”/èç•Šõm…ò–„tÀŸ^Š)ŒËÛÏ¤ÿ+á@„š½é=vCB²“ĞP²!7¶1|¥¨¡äà|BJM7äoŠÅƒ9è>'î:Òòm®ïyÖn+ÅÖÿe<Şëâ ßòş_áÓ³K•‹9I÷9["RĞÊèöÂğÊÙIò]ñ ­ÿ³ƒDcË63¥c+İŒÚ›I¸î¦€¿”gd¸?‡k2à ßÄYŒ#W‹V.‚Ÿs²Ê£úçR8¨dá¶rDx\2\Òyô!¡É^G¿äÃAÌ@)¶”ÊÁD,C]ãR¡ËéIï«üI/m¡+¶ª­`Õ/Ãj…¿ÖW#9Í.‰E§QB4’0‚Â3*‘Kd7wÑÛoç–‹if*S¸N°á¤=	&Ó„!ËÉñ/]ÅnÚİ¦	Ÿ‚¸‡OÚ¤æÖÊ:Ñˆ4CS¾¾zsĞùúd—'¼|£tA[Jr·¢‘qí)YR—ûEô NÈ?Á¹IH€ßßşë·ÿÓ3ÅxÊÀãx?u8]8m»JÂ%Ù}Ÿ4WDy¥7~!*}Q®¯
i'"µ‘ 5‘úA+M2vŒÆ“
ô†p€>„|šQŠ9dS0,¦.·`ğø*0<›öQDâaÄçWõ[g—,l}ELyKñÊ2¯xÒé»ŒŠºä ÄØ±¯Ş…İ÷hÓ0ã` ®¥‹¯†¡‘DÎ‰äİèŠX¦V-´¬W×ªkË–Sx¦jÌµZ;“Cœ«-\g›õ4ÖrôAì„gQ0Dè`ÿ¼ó­õ\aùôÙ‚µ
cõYşÕàİc3}»œƒÑsÆÅUgÌ·A›ÒÅ¦!WU÷)®^Ø{$¦	í[üº^ÏÆå)j#Ã6ËêÁŞq[q‡NX<R‘i hqá²“j?J&©™LSzÄÖÎŒ,1Ac¢‚ ÎyÓ:gÕJBM‘J{ÌliØT5Ùë9?Ü„ Ì¦,5.„1†SFo¬a8!dšægQ?š\?Çñµ@ÀÖøO}¥šÑQô¢ÄÁaí¬¼02Ìç“èµË€Ñ)0>O`\U™¥ˆ«­¸ÛÃw¨Í‡Ş¥´:Up—é0âÕeíQé©wˆ:{2ÔÏÙkƒ^	œ./p4½@ˆ$ˆDÂyıö_ÁHœÌ¸…	o\ËÃœWÓœ½_ğFbJ`èş$É¸èu[BLT*ãi|êiûeå!,ãb”õúCZğåJ“„“?µ	RÓşÄÃGÀŒgA²ÃO>/Ğ"¬ƒ=„·4¼í™«Vâ¦@÷í)64Ÿ R¤fÚ’$ÂˆV°Í¥ë*¢}D¥(³À"ï¯"¼ø¥{[Šóåí­„®":_Ó(²$À’Z©v›
‰0ùé°=Ç¸ìIëV¨É‹ù´)V^×ò:øçí¿l³_N“éÒ%‰›@1åØÈ#şF@GªbYS1.ÿ·Ô¸û¥í¦Š’zá8ñäuÜx\g÷{YÚÒgQ:†îm¿İßRYöZ46E&6K$:u0ÙÊÎ!GğRfëÖ3*»·f#Ôe¶cUÖÑè'·¦œeàxtU™¡f@p‚PaÏ[*Ü-ï€:¼«À‰©2ˆÜF?Çf°”ÛäLuÉ^®eŒÜĞQ Õò¢ƒ˜I*‹8 àq…™Åc)X~Å‚òšy[¼sÊŸÕÙ^(ê„[ôAÆÄ	]7U“}$ı‰3‚á£.ìƒ½"ÒÂI<JÈ£ã‚ˆš¹™Z·î[,;
†è¬}ù$¦“v«CÈ¸lQ¤<}ü_¾ÍÒoR`_´ Èf99ÚkjtİÆf™Ã«Õ4CöthSã…TãEsût3Sˆ÷·ßlİ:ê¼Úßeñh{¿ug~Y;oi§cã°Ø9Ş>úºuì+-!€$ø—°áùÁ–ÎùòdwOº<Ú8#7ñSèAøaº[ƒÈ¯£½ô®e
«0	f´¿ûÆ,jU©GŠJBçĞ«Mü%ø=èä!œ­×9€f!Š9Ú,ÅÈEøX™ÏGbUåb4ºè‡òO¨^wdHrI”“©úXÍ“™÷:ˆß‡“N¨×Æ$¿ï§
—i]qÇÍá¯œ‚+™.&„å¢~®ÌîçÊÌ~ŞÛ}ÕzÓnµ­iCŠ™@b‡{ ÍdÅl5="^š)"·ı:É¿/-0ñJôo´Üd Ç"“k÷s÷“ÎİÙ“Æ˜3«ê|úu81Uù¨.Õ.6¼wg¬¯saŸ3ñ|ò·4$\	1¢B%<4(Ãtê¤PêyA§¤qÓZ{­ív«V¥±†™<·^£¥»€bé¹€Î]ÈX ?YÜN!ƒR:ø-Hg77MDYWõ•BÖQĞÏòÏ·)ú³ø8“êH¬6*ÅÕ%°¼á¹°G¹@Æ¿å×™Ñ~Cü®ø[3¿ØŒzˆYT#¼¶úBEÉÜfnªz¾Óõ&a½RS+¯®(i*ÍªÆ<“‚B·[¡`ÛG¯:{o¾-Ğ¹
Á~D}‚™L”?‡x$&PŒ4&Ì©—>¯ô¹Ã'Oò&b	¶¾‚FE<†'¯Ud77‹5Ì·T:bM#ŒöFWÃş¯dëƒİDùœ	PX‡ Å³ú9ÆÇ‹d»QjªŸy’B<îĞQ°¹âwû£!Á2Ò†!;Ù_MÙP
i[—PY/ÖGÆÓ~ß_U\,¦ü³~7I`ññÏc7aÆÌµTb…§OŸŠÊÑeÇÌ«ëyœqÎªy™”RÆÉ±âI{»Jİ¤VR™x'
ŞöprG¶™Kææ6«W¼©ŞY©<’„†xcöŒ§Œ…	]/ªøFsEİ@—X]¸Èja™V‘iL{ÛE„ôFÃ	m»ÀdçBjLj_˜ ¾ h*ÜÁEÔ=†-|W^„‹’@ó¥0Fm”Aç÷@Ø5bkÖyòÛ?âh„æ b7"İ<b’$‡vZñ¨ÿJT%]aÍ+]AU€„<ŞšÉX·„Y¯®®*á´ŒX$((+Ş!çP©` à¿„“Æ¤RşÙ'/7ºHYqõÃOÄî‚Š}z½l†ïu'ïd ì‡ËsÙXGtÌÂ™ëmDØ|eˆÌ%qîvl!3 âœQÔÆÁ*¹'U7!ã‹^ÔptÎ‘@{ç ß+ğ%[ãéx²j*Y«¿í:åc`gqõÊza¯L‡?Ec‹Šæ­Ù'™÷™nqå–GIîrÃÅò˜TŞ<íU`Lz¶ØÉ’­I,ˆÄm Õ¸¸å$@w™¢T5}„‡Y©Q¯õX¢šÌ.OmvŠ%»äùå	 ÇÀ³Ï¶ÕíR¦Q³c¤J'ØÚ¨—Vj×hy-V‹7À5g£4.©Æ|-¬ø|/böÌp&›‚:¤$"MÎ»`Œ9‘ôŞ‹¢•‘÷<7…TºÈÔæ±»6T^‰ÄçN$|àÆúúúÓ/ŸTá”ºf§Àbåp¦pÈ»i*o¦õWvK~Üx\mTû®DÖ&ÕëWY	UÙ¶–×¼İw$=®6V×IV†¦?#CÚ÷Ø;fgÈqm%FÈ™5 Ãi«`0Uê7M3wÖâ,Åynµû±iÕ¹èøé -[]%Çdşa*kK¼…{!Õ)ÏšÙEÁ•Õœ}³óíâİ`$şïé€§s¥PF&ÅõggïW-D¡"Ú»_ï¾9*Â
·ÀwI!?AˆÏ–`ô‡y2›[‘ÜÉl¡ª›‡EÚ‘oz0¨¤Üà–òÇ“á´NéDO%ô–®ÃDü"ª?`G8ÇèÉgè U7§ôI¯ém/„â«ÓL–Y.ü°¢fã*ˆ&´Â
wÍS_6«€\„èZÒì¿Èe¹UÅ4	y‚í´ikHÂ ÑÛ-¿›"­9;ú-JşLË…0œ]oV¿Ù-ş#¶US6şç	}Ğï¥šÓfMñ;…¹a°~kz;pÙİ·ƒîléM¡ıŞ¸W«Íº5Ìeä+ÒËL5ç¢E¹”x•½1œUDÎcfâì]ã‚r73¸U|™xw)øddáù‹»^jl	á\VÏÂóy²‘™bBá€pš¨¢ù.2¦ªlÑå´áô}ç’¿–$œE–Pí:µTâøm©Ÿdtm6%=OÈ¹‘³õ”–
ÙXÕùáP„p±‡­ÑÈÈ¢2Èm>ÅÜÆÍNÁf$r‡œ¹ıaª8«·[4­eS-œú/Åšdïa]V…ã Ša-ÍÈGf[^oïîÉuT/¾ç´0|O›0Ü°rrÑ.©×…t¡Û}ãópw¹-®"´3=ƒé'-ÜÃ6™iû×ä(+¾1OÂY G*çZÊ’ñËµ0'×t§1¨èÀ°PĞÈ?3écf*1Y¯XY"ÏBºÈ¦1w»¥ìV÷GltÆÕĞP„m¦_Eå¨°sóhÖA Qez½MİÉH¨HÉ¨4Ôa†z‡îç-İáÌ{sNZ‡óz=Û-‘—Î(œ×†a¯ÓÃæÈ¤J×ÃÑ9bÄ÷pyj§+‡w °ãŠ$¿ıC!hˆ0IÈ¡  Qˆ6SÊ?œ£‹PÅ¤c-ùp6Pi"€GÔ}‡†İ«¢d"‹d
Ò”…]†}¥†Ä’D4	†¥'+8ym$QHj0`–Q´ŒåíöU›‚
`Éi2pÆëCµ¬‰ıÒb&öJWØÚ¥Ê5šN¡zç7]¤ÁbìXTÄmdé0P­$ÈdA?ú)J•[Ê…¶ñç:§úÂ·<tl7/|z†Ó3ÛdYÇ¶ÎïˆÀ3)âï_À¨9Ôz*C0DÎ@&”n§	ÉÛ` °‚b¥çœiv%„ĞÌWó ü•—ºbÚoÌ_©L?¤<V ™Ô¾{I»µûÛ?ò-„?FØ\áƒ`ó[m¶ö‘Å¹aCDy˜÷ÁO0ÍñäM~b4Õà³]Á%œ}Ò	¾³ŞYë¬e|ÃÓ¦.˜[” :ieX¦U@b7«ËF¦.7¬Ì†:UêÒâgBëgÄ2£ØYÙŠ0Ö,Ê ;öL2f*Ä>’kIA½N!Qó«íM9‹4—?ëÛájˆ-d8ûQ±ÖŸ•Éùâ#Ç	3„
åïìL¯'˜qoåLhšoJĞÎ„ıš$ş–P38c#WÀQæšäËH“İ1ğÿâÕKK/QD¦ÛÊæäiî¡H“¼İ²L+Œ­$}À¶w^NF'½ğ’tİèí‹ı·7º`™¢ÏBŠ®†ab¶¼÷A« ù2˜e÷ÇüĞú…qÄç	†™Hâv3–¢ê7£(•\ğ^	ÂÏ]-|¯p@/÷Âû7“ãPv°$¹'«KI.#Ra=ÓZÌ®çş‚`VT*X÷¹By9êne#ËâSÍßi¼gn/î–l-l1p“»p“º‹%¸`›µ*—æ.Ë’(¥ƒ·”Ô›)Ì8!˜ÖXmf,¹qw
³{r“·Í¶ÓKDÇ23Úßì#ŸbO°ãZÊÇëÚ×—ä_Óo ³¥¨ÙüØ´•ÇÀ
Q7õÅÅ‹‡]zM$Kn Dz@{’ÀYÜŸ5ßÆ8)ŠĞS ´f*«g@¥1…¯ªB_·Áô¹ÒõtÆ³ªLcÿpo÷ÕîqgûÕ1Z8îì´à ]
`›1åšC‡ı+œ‘pQ%qSÉ8†©›Ò9%®Íb¡(ÎBX‰¼†¶ãúÿõ{Ú¨½i)›gõÜ¾ÔÂByº‚hhŒpÏ¹ÿ‘û¹ã±äãew¾ÜŞ–7ßƒ<à%K(eÔq.Õ(AËFG:ÏPĞt¢A¡©”úİûcuÍúp ©¢åtÎj»İÃZb d2:”ZÊ»Sfoò
¶"ç®—Ûf™¥#ÿp”L^É8¹­Áµ1|¼sü×*A&¢ò«~’øOO?.ÀÅï¹øOõûøO÷ø¯7Æ-Š÷Ôu¢¸òpŸhW¹è‹ ¾˜R€§ªrÌù¦áP½Œ.ƒEBöêY\ëÁÑ¡ÖÆ°O.­BP’öhXú*:jT&TXFA•¶%´>+«£´bØAÑ…x‡—b4À¢öê`ÿğ¨u¸÷WŠ”/QÏ„;ovÚßÓ×WøcÌY˜¢Â iH¸éW*ÀŸ1âÑæ.8ƒ¢¾ü[	‚q„P òîŸ¤[„`ŠâKÊH»©Š‡
¢ËÏP×¢Ù•‡âÃnÑhÆA\€hSy‹7£X38T*2;êp*nŠd\(*¯EK…ù|ñ•å¨Ön^
çQåÌXÿ‰À»ædœ|füïÆÚÚã<ş÷ãõûõÿ~ı¿5ş÷cş÷ñ»C§#}ApçNbí—(ı‚Ü–|¦TÈ«Q‡ñÀ“Ç8İÁ©¼|~_ßZo–Õ‹íıí£ÖŞ¿Zƒwëé»öÉK8f~³½ƒ¯7ôã7­¯ve–zš\Ù“èbï:MJ¶a%ÜşÛÉ&°‘>gËYMxì¥:®Úd0æÅL…KJªxüIß
Ê°yy /¿Œiq­ÎŸÄÂ\0Åy'“B[ÆH”´ğ]@kLšJ¯¨*«mBÉÃK(Ÿ¿ÿ'Õ¼ø«>HM¹axÁ”¥£íİ¿‰è»—»­7Ç-p:xr¬y45=®É–îNÕßí|İÙÙ>Şîììµ›FïM# 7?ÈÙ›/}Ï©Ëğišg^¾mí½B^¬xKĞõrØ~´g§S	bwwÉ?œNGWaL~ÿ;Á0
ûâ «UàğS@)½UkÀÚ™öá!•}:y(áw¿¤døà„°9EıIumCì·s/e_ğ…ô>Œdxé|JÔ¡
Šå;­—»Ûo:¯`¼ÙiúCÄW¯%T
^XÈ'¦ÕıTŞO(£Í53ËŞîK‰9¹ ııoQÛØúÎ,! 	à‰Ÿàï;0·ŞOFc˜Jz(Æt4Úiµ¿=>8\õ¶;‡ÇA Î'#ôa8©v§Auz>˜€Ä&5 áÖëg`Î$·i"N¥Öğvš3§Nv[ÿ­.gš¶t¹Õ¹î íÔ-’úÓ_íIµ^­›ïÈ™lfíÛ&éÆ3~P„µµêÍ šùZaŸq"'Æ’šÔá!eåE4y7=#>ş8‡ 3±5H­#×¨aÏ/òU3hFF×Û´q2ìtİ–J5#zÕãÈTğà}%‘J1|€¡™œÓ¾mn¿²(µÜ	/iO9dŒU4/i²¸ƒâDMÆA74Û \áĞZ5Î·e¿õæ¤³{ÜÚ·Ò»÷„Z0Æ« ºéMRU¹Dø4l×#j£Z_ÃíÂ~.ïvšËüzÙ3\Ì-Î_?n¥ü³3?œmwÿ¦_GjO­‡º$~·ì9QğRö˜;„0½ï›ş³æ1‚æ0®îîTefúŞQk{¨ò"a•SÃ ¯‰IOù”QÊ?CÒÒœŠ£³)Š9=F-¥…'ã{æ¢9q“İêã 6Qš¾ŠÜÒè¬ud_K]u­š[y’Ëaõ<ÃqÀ, öÂ£š,¤6	.ãÚRwF6‹£7ÎÇ]ôY·6ç$ÏÄg‘¶iÈ—üM*IHŠ;õÎ32³ØÕÈ>Ø@)'OIs)Ö«ÏªD	9ÚP_(§gß)ÃŞLu<:h·;ÛGûê¹µ,>.Ûâ$}ÑğË¯O¤WQíBÚú—´¡'9¤‚wXÂ7¯}<[áí(LÂxpù4ğ…AZ¯w¿k¢P¼'\£j˜ŞY¹…ëÆˆeÕ¯ >Àuö²±.ıJ…=`i¢ïF¯WóuÙ|Ğ%qtÎàÀtKÚä|,ñ“’ªöÇï	ä3ñu…ï·*wîÚXQ£(ˆ…M{¿ñïªÊògšŠÜªÂŸ²¾ñJ:jÉøWôëUÇón_ã{çî™	k@é¨õuë;ñ—í£]\;Ú÷ö¨cí÷>>±ÎÔğ¨(ø7M§QÅrÏ‡‡Ü&‚8l	ÑÙ‡z½Ò/A;»˜¼‡Jÿáx}8›»AêÌ‘‹Q=}ûa’LÔ÷`òŞxsñ®[Q%á®qÑŸNÖÓoôÜ÷R@ó¦?‡S²iBx°dzvÉÚ41Ş‡‚»Ä]„1ú}ÊÙ	~:ŒƒXû“³pôÎÄüOÎüP
ÇZõ\ñLh))	~,Ò0'hqàÃS!^vàšLŸÀÇËsRË  †£aÛìKb´I¿#‚°Pÿıúà·ßpßòëS¡+øTæ¥Ûàáx†ÙÛíİãf}pè*et.Í,<Äéš›\cìæMVØW§pò;dŸ¥:“ïBıJ~H]ÄH—¶ÓúøıhœyÅ¤™O §ßn*ÕEšÀ.7-bæG^x³îıŒzlÑ¡ø×ªBòMâZ›·M…æŠ8šµ[Ú7H-Ò¯Ÿ_œqsUTŞñHüˆÑ±•{®ÌÄ
áù *!š”ÁeõQÅ,`pÂ„]_ºU›Íh¨ËØpíÂG•Z>ßÚ•rD|¦“a‚gGéAX\„4S½pV3 :ósse~íqÍ…m‚…é0qöƒä3s€±²xªlf¦J¶."7ñŒyç¾÷Ô³ñ›ƒö±‘ZŞ‡ê×oNö_¶²s5	ğZff®&\¹Âv­ZR­«ÂP_&6<¦my3š`f .hú¯ÿ/¯µã(oÙ_l¸}P|>Mèf¬ãP<ÂØõÔ«Q"´)<°ïéİRÏ”Çxïâö¯»ç˜
ÃO÷Ñ	áÚÌN“o°Psº“”jkZó0'EáØÖôî€gµ;äº°.ÕRdr“ï¾Ãk¥œ¤ªLî°apU6ª_ÖÆqˆ›2ÆµJUu¨"(Ğêe™Ù>9D½¥ø¦Õ<jß‰¢_Ò¾]ù„b7s^Í“êœ“Òòg<*©1ƒËøïfÙÉ]ÿBÚT~Hò
y¸{®ª #ÅÁ°û¥íèÈÙëxÒÎsëëù]ŠŸ_¶¾k½*~k8r4¡N¥jOù†ä	ÇGÓ7êÎ°ŒH³ñ,û2	‚šæ*éeR7Fs¹ñ´JúÁ‚0ƒËÏr¯öÛÍzİ™8_NåT‹ÕT™¯Úåq6µ¡#MâcÌòé¯™]Ÿ?İşÍ>†ı6/ÿ¼öŸõõÇëë9ûÏÆ½ıÏ½ıÏûŸ[ Cıv6@lôH<”Ë°?£q§‡—Q<Òw41%‹ŒÏbÄjòşsÿ`çdn8Q.Y›õòçÂwÿ‘]~ô<Äªğğ]Ù,[B‘ˆÊ?V´¡ÅY$åãE3P[ÆxJ*aïÁÍK$k=e^©cÉÚí5}ây&€$ù,!«ş›6ú¦tĞÎœ2Êöoå¨MO;ˆ¿¨ÁÖnQZú)©A—–Juz’¹ó‚¤ó9#lQZ§§V}!íFS!`©?ß@”¸Âó§„T¤ã3fLÁ+uÓ}7:½Í^{hxœ2ã{;³§ã—ÍŒ~tŒŞÀ¸¨V«ÂN+6E%¾´ßXd)Ö`€rÒy=‚•ºw˜¾kA|‘4WÊW³ø"‡%TrØ´Á1ŸÒ2–yÂ×ÔÕ{ñ«ã;¼Ô¶7ä¥¢ k\$lûÅ¨°«hDàeÜ]¨8Bß‡R©áäw,:1=Äõ±®¦ñÚ–?ÄlÙ,+Ïx£şäûé6M/tEêcm<î~x"!/l0—Nîh¥£|Ù±'¤Î¬éÕ…åƒ×ŠJrwÌ„Ô6Q"»e¨±AÖT)²*ÅOÂQ‹Œ‡åºlVÅ´êàáÊë	UƒëÁé¤+üºa#ÜpòŠ¾„ÔÏ¤k
©½Äƒ=.²çûı¤1ª)¼â¹¨Ü¬–J´š“-c¨“î+UÄZóCD;.E1X´5_Q¯ö¦‹ù\†h&°ì‚ÙSpÎ4Àz<MôE½ûOÏv=‰Â}tS>@\/	!ÖşyY—CÃ835u¹pGQÌ¤âQ¿-Wi`Dôq|ˆ†á *8°w?òYbe—˜‚ˆCï°%"øíÿörÖŸÀ.“«f˜~°.7X¹+Ñspz:Â—l‚Øİ}ñ<x`ÛˆG‹‚ŞÁ„ÀiÜ43I¼+ò®J^³®¦ÚU!^|ÑĞ°À¨<MU±råOÉh¥ª
¦¯¯Ş…q¨çf¶ _’Oú!0ºntœË1;ï¯m#r8n·2şÓ9tc	³™îƒªqª [‘¬Äv<Ó‘_W4e}}&’D÷^"môöæ©ƒXŸğõß¨ÿ¿È`6x…y‘R¥¥Hûïz.Ÿı­Ô…8Û@1¿…ix3Z™~æì&Z-Ôu¿u#Eº5+ÇıœCò–nß	VQ¹Õù[Œàgùóâ³Œø ü:%Í³O¾9p£e§¬b1K”‚H-îïæt…æáiÿ¸¬ÏqÃñ?A±”r‚š-5)°O5tôâÔ
â~„ğ|NNh‚ÌuÊ‡Şã‡Go~ÁF÷/İŸŸÀFğË/ê×Ó´‚R2m8â…‹­LPñu™ˆo,áN¦x,Sàf¥)0´—Â\”¢¼!ÊO²ØöÜ;16Ex
L¡İÆaÒÀ8‡mÒ ÄtGu>íÓù~:ÄSî7³„õ#Œf…ë‘Gñç(Nzôe7Pø¸…”NÅ Ú[/Øl™ak¤__‡RIÚ×d÷S9Í+sÌìÂYÚš³$;d„´…ãì˜ò^2íÅõö$Iä]¢†b;+Oâ’«¥ZVsµ4ıa×ÓU#»–:ÓÂÕÔ¹œªMzËJ£ÖÖâÅ•¦±Æ:3 JŠq4æí†éX#k6dvFŞŒìl¤ŞGÉ±-èÆÆÉÿ¤Ğm`+ˆÛ³ìÆƒ/ƒÁä@–6›İÕÑ%V{„Eu/-ÑqŠÇá5jVI¨j³fINĞÛ†ëƒòWù}†XhÃğa.ƒ>¬•°nÊ/_yB»9%+‰¾C´4¦¬Ş6
’ê”h´á¯
k™ÕvR´T
9
Úk±–Åw‡PiXTÀC\ÌÑ’2¸Äºat½‘ûŸŞ¨›Ô>isğ?ğ“¹ÿ©×Ÿ6ş$ßßÿ|®ş‡-¿öGêÿ§ïûÿ3÷¿iö9û}m½½ÿ]oÜßÿ~ş?õQC5Fë}<ĞX#ÕãolOùgÂÇkU±=½õg¾ l8Õù$IªT:U^„¾Wm#Şlï·<ÛŞğT'Œ2°”¥½ûæà°½ÛöìÚœÅ‚‚Ù¿?=ÉÚ¤Óó£èçÁ!şlãoÌ!¼pŠ+‘3Ó¥4™,ès}ò5nEYõùK×ê´rÊ’bş	ËÖóôf=6,Ös2Q¥¦ ïvZíWG»TY/«t ô~4äˆ‹úÑûPl?Â¾@ä¢¢²&šô¥7+Ú†2aÆ´©âœÊ¬h-ƒ2­Ü''ñ–#€cE%½¿„”÷…´æ½¢Ä’û^†•B,éäP#Ó–›:ÇÉg¹f&›y%sEÁ¤4ÇÇf2«Ë0m¹™‡ûóTu(äúsÎ4\ñfY†÷#Ó2œÆºyÅ6{„JÎÿğË/ßË?U¥$¬ˆõQM#E>`Ãcõ3ôTÚSÓ¤•±k²:ÌŒ+‹˜ËaÍSNœ$<â òÖª)Fr!^ru—:áÌ]a<kTŞMáÄˆ–RÖ_åÚC	Ü(`Ó9×‚•UgJ»¶25¶½]6=1bôƒ)šmÆi5QaPó0)©ºğ<	‚‹] I¥u,V ç3šm'ÇßyYX‹•=èŒ:õÿ|7šÀI±®î«÷§ûÏÿû?’ÿThaRô>#ş×ÚúúÚãœü·qÿøyìÿìKÊ#İ8ŒŞH4Ô°WÑƒI!àl4ˆax%ÎÃ`Böp¸ŸpHÛUÏ»$Ã<º“ÑY?d–‡ÏÇ/¼¥çÉ$/^¼i½mo>¯É_ğ|Ú‡—÷£»xIÕ›vQPiÚöKlŠçáà……~ëêt\MŞ=¯Á›ç5  él7Ü(é¢g_2Åp¶½,ª¸b&fú×SÚ^yÇ5–rŸT=fAIUf}^Ãš?¯Aã¸ñhüQé†ãI88C)ºˆ¯w¿kí°a›¬ÀA¤ L³´¥lq £QÿòÜF0~ R]3Y¡„9ò®·xj	P*Dh<s%b"ò¯lƒo¦ú+¢AA¼Ã¡ºMO@°…T’CÔÌÓ¦ıÎØ5)5öŒÕ$´Ô$%_1´Q¦"æXá\¨K284è{Öfbq¬†
ï@ÎˆCàT7ì¡Ä™åw¾GëFŞºCÌ
ÕbÕ¬÷Èkí8%QR!=oö˜932rEÍÚ>Ú¿|Z“ı}³|Pš#Ÿ9ğæ–ù_ííŠ}Œßq&Ù©|·´óÌ9è´“º>i×GkDß|H ·‰ÏfG»ú™RñM«S,Ä× Òq{¸ÆÂôĞ~pr²1
'|AFuAm@ØV_6,u&\YÍB"Ë2wÎ‰‚/üÉŞ‚_Ñq2Ôº$€ş•êí Bç­Œ‹B]ñ ¿ÒŞ‹qw ÿ»k©oaùocıéÓŒü×X_»×ÿ}–ÏÃ‡_Ï’ñ–ù¯)î¬ÔWù¡0"Ÿ'ÿ¯%W*•à"E¦ü‡=ïáCT#Â7\ë¤öóqêòcÏg¨á%öáC¥xœ_P¹è%é[ÔBÈz½ş¾‘j˜ôÕÌÒnO¤9µÊÍ¨ñZîœæËì;µ«æ[c‘P04An
¨_Ë7+Ó]†®Óî1ù¹KıgFJbÃïQª6HeÜüWÜsBXÓ·.ÉA²x	ÙÎ7Ó([gÊŒ”E !
	Zã"Öêf‹8†¦«(ĞØQraN3C+$Ä¥Ê-ÔåŠÕ‚‘o©woºZ	·
ØlšRÍ3XHÊÚô•T§	ğŒÊ{vU´¶Ø~¬ôÆ³Ò[+…ÍD‘®¤’Ï?¥tVM”SÜ±şÙ=äÚÌ£"ÎÎc¡¥².jÉìÜ…íWm÷hE73ùæŠn©é–ªîyºn.—UÒwC¡²FN<gqròÿ‰ĞÊØŸI•|wx˜#ÿ7Öfïÿ7îã?|.ıïÁ„fu=ìÊÿ{Æ¨&%¥Z8‹_ ÈRÚ•|ÜïaÈóñ|Ôï®ğÌµHRƒeÈ ±Q_L®ÇaÓßõ•à 1|H',DW±B’†¶^_…DÉ$ìáÚğ<ïâğÜ	ÔÌ“]ÍušêµtÉ©huCí¬?:ƒ³/ĞŒkG­íı{ÿ…Zæø‘^å×‚d >:?º¸NM²«–zJ:ùDıhrÍ:Hša®FnêŒš3q†u6¬“©		.ÿ2H ı¼tîdæç8şyçÛgbÛD;µFÅÄ‡­5¦¨rı±÷¾ò¬ÿj‡ ‹$êîYw×&ç½Ei#À ¢øë?Å¯·ÈnGÖEô8D1Şz$€‡AwĞƒ8èBIÈÊ.·“äÃ¯š;*mÄ÷Ş$"zE4–¢(ÚÄÜ»“åÄÚÒ“Q]’1t‰ì¸t{“Ğ ZOLñ¤Võ"ècCn6ê¦N 
P@wzmDº2ù§-•xxı£­UfzlÔõ¬1Ô©z@…¼ ¤à¸G pD:é‘úÀRQ§DIoY”šk(÷Wq?|ÿ¹ÿÜî?÷ŸûÏıçşsÿ¹ÿÜî?ÿbŸÿÔ¬rÛ h 