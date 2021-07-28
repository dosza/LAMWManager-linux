#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3412897447"
MD5="ead10b616910be58af2b65a3f0c5de57"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23356"
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
	echo Date of packaging: Tue Jul 27 23:02:50 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZú] ¼}•À1Dd]‡Á›PætİDöo_‚r¾5¿]BmJ‹ºíM[†=©2ÌïÃüïK_*Ûr¹I‘îá»™2Îšà®šÅş÷†I¸¹×3b,Jµø²d(V5[ÃL_–7-´àÎıõ.„º©œ!IÖ{á¦ ~]ŸsÔbmVå‹:ôMë•ûgKg¿\ìZhT =%XøôOçæÏêu€È5¨sĞ$¥1ãĞøŸÊ‰<¸Ó¯ƒjñ»72íO`ê™k¾ÀVûépÃ8Ç?¦$Š–ø¨ewÃ?ÓõÒÖ–«ÈxÍ‘ŞH»·ÄßQvš^ÕH³QL_KŸôØß$¶åp§×ÓñT²Bã»IÔÕ
Ş²µğ{>ş{A‘{é÷‰f£àåª,n¸ªïŞHs.°·»Áœ‹LµH!tÛóÜZÛÁÚ‰Vñ×Ä2ùbMi; Ç`MDŒk'\áÔûŠÀ¦~ò¶¨®9`hÆûÁ4×!–"¤öÛ¾¸`ìPWv4B ¼úîàò laõ ¨Ç#D%­vÄ6ìLvšÚ³.+\E¶:Ah}’ê #ŠxÑõWúV ”%Y|öª›Ğº'Ğ1xNÂLüyşİÜ]:—ÿE5tùE¨iåè:Æ^ˆ¢C |Ø£ŒïQë|v@Öèu_qÂ)|2¾PXEÒå+ÿ™ãY¯ Ëù>lÈGbT
1EÄ&‚N“ìÛûÀ+JvŠä6 qÙˆ”$NTÖ¯ÎˆÎ÷lÌòH$84{f6m¾ãÜ'u€'gÌ‰l6Ïæf–¤·f|ô~zÛîÆiy-õïhIy|æt§9(š®ñ,â«ù´yJ6ÓgÁ-g_yN–‹Gªd‚s•R¦3X±§"I%Ø¬tŞVÂUıéf‡ëEo¹·¬Œ®Nå¸şèÔ¤e ØÊŒq¨äè!HG-cå%Âüİ’È^"LåŠ/ÏÚ_õÊÿívZjóQ:jaÑQN•£.ÆçEw¤t+ÆW	ö²¶kş†¶p‹ÚÁzŸ
Gwù_sk³0Ãná™IªíCYqËöDß»}úF”¥™üê‡T‘†<„¬¥fø¤ÓÉÍ…C!Õ„dì©Y˜)Dñ+˜iY†H?¼¼³è—võÛÕ}/Å‚#3tf¸‚p?¶2e“G°³!zM7¼¥:xd	
Qº^Uºÿf?©Œ>m^ÇA{HFOÄÑhîU­K]<ÒÄ?GÔpÅ«lô°QŠ•Ô\¸³s•á3:bÜ£ñ•ÀVÅ^qJ‘X+ÿ®;ı‡Hg‘îéP¾‡í¹ØCóşq"‰Àı.c‹sŞ‰‰Q'Gı^HP¨0”Š2G=Ùdyo¶)²ÇuëÈ_àŒ˜Ã÷?°4„•-f§´æ–bùÃO[_¯E<9Â¸aÙÃyÑÅeˆ°ÛkˆaÒdÓÛI)2ù-òc'>}4kô6vÅV•İo·ù6æ {QÜ#U9­s\†‹i«tYåĞ‚V÷!mP¯„döÈQ>¾.AUÛßk6´á	Ê2‹ULO‡…î«şãÂÉîİñğÁ]Õ)p)ŸÓü»ÅlSô¨ß.çÛÿ±qFïÂ|øÔt¹ÇÅƒ:ÉÎÉ4@©£Û>AåÚ´*µ~ÚùQÍùÉø…]Ê)3¨ÚîßLMB{\Å£ÔÁÏÛ/(ƒTî«bOßIµ-ıvŸ+	T®®Hò:xJ~…(Y˜=‡2Üû°bPwÀmôaø÷	Éøõm^úŸ,\¼ãUÍ‹^ ­’Kb	ÒæãH®ñ_œ¶6É»µ;sßOó4ÏU6Œ$ÔB`±œÂYÜª+¯ª7ñ{£ôhÂ!¢Ú'ú/QYïr“¬¿Ól¶›ø˜0ÛTVh±õ»Î:¯•·¢¾2Ç»<ÂCıÖ¯vo… °"Ö„£ÈÓgˆá7ğè,eæ›ü9
ĞÕÛÿZ8Î°jï˜u<D€;ØEfëèÚŠ¥’1°2\¶	•¬ÚğOSLR=a_
wî„¢æ:fCşğ]àn¢çÇs° Uc6e!ÌDÕµÇš¦œp{¼ñø &H~«ıĞÍO;Éc:‹¡ßŒ=şí‡A[BVõ”´"ìõXƒÆñî»üoÄ9ã—µ%ş9ú’àû[.
ót©k<¡ÒG™÷¶ÃŸFìLkWL(¡7_ñ:Ú­¢ñ%v?·½d Ï	ƒe;rª†H&—ñÆÁSbä*SSñ:µ•tAEúÚr×ÿàBs§
$0Wx‹4¸|Z–¹X•„ÅŒå)DL¹«pò}¿~I..èß·³Üwb*YœõÓû´*¥©Ôx×ô"ùdS~%1hß·9åAÑ†‹{Ä½šØŒáìcÅ zHAà‘á•mi“ÁUÆ·>>Îİ~”™$çÅ ‰Á`Hrô
ç¢m›—NQÅÿ·b‰_R\’­¿krpïJñyyu(Û»1ö@¶ã¨…uL†\#"‰‹0‰!é»åô85¹€ŞtmŸ‹·ÇêîLİÃ=‰uõş–Ğ|QçÖÌj]Ï…GT¦Şâu1ÚÀd\ğ4ë¢>_3Xp~MŞ«ZŞ˜|õF%ùZ*NõÌø¸TLˆ¤!yUØ5€¨ç-Ê®Nµææ´@À+Ö‡ıkºÄŸëk.É#g,–cº) ‡o4=½îYÚ³ãïómÇüZi®‰…*Y¦ä¸»]³ÂÊd¼éó´9³=Zs™(/q†àÆÚ•Fe	këµ ‚u^PW²ş1ºn3hXôL‚)_taÖÃØu²§Ó‹G³´y‹£C Éş"(Ä$nñÒ'pAÅrv(léi{Ö$B«õ•²mf¦SXT5J¿ğÚe…ÇW3!ƒT§êw(×~–íÕK!´Œ
Ü¦İõi‡@š|]÷ªÜÀ÷$h[øÔz±ëü÷0¯ØïuÈYe©¬\J!„¹z‚ßíÜ›'‹e¨¼Dø(ÀÛıVr ¼† ›ŸLÊ¼oñÀÑlô™ÊÑê|„Vb?zÃšê^+GÀ£}íÃ	v/ÎCj¨İ<wQÿÂ{KÚ[(Â¸}3œÒŸá6{G™Ú|9nYtàŸıüËÍG£È¾&°·¦›OIè¢LaA©Úˆ§ÍFg¹ŸòÌòÄİÍø2Si×ùox±<¾ğ¶SäÁJı˜ıW“?z}i×ÙÜ¾¦üÍ~ïAŞ¦\”C·¾4¦³Å@O˜ >ÁdÄÛAîÍxÏ¡n9äêş¯ÏÍSy‰×înßÆß[àªİïPÁ­D+J’şÓpXæÆ"ÆŞØØúñğ_3ŸO¼/Ñ°Ú ™”ÀŸY>ñVÕáÌÛÌ¿‚JK¬Û€óÖ€h)ÚQªßä‚³xâş³\Ş{âAj¾¼ÈİÉ`&³ÎìöpÍ†9—D,˜"SG´¿­z·àßT£0=ÒÖ2ds15ÙÂ¾F¬[QLs¤	O€ŒKø—¼|y4Ãm¯øxÜ»SÆ€2¯ü	]Œ!Öú¶o%`·=“g(‰ÖT¢Ê}2t©R.h§®\dKAö")|ª’[_ıœ5ËøiC
k	» ´™êÍÍ§‡LÌ¾"¤×é¯[«Í E‡€E5…*¶Hşc/Éy9HJÿjĞDÛEÆÍ+ÆRR†5»é3¯^ãgàêß+g&@wâô>cˆñõ¨]('@{(…«ä,Àp‘ÃšxRÀ6ÁÂµª†CG@%ñR«:ÙéC±W§5[Äó`	9v¯ä{³ñË6à&|¬Zò‚40ï’ÈÜt@ıò=îğ`\'ƒ#Ik…ä7€0&oÉG‡ëDâ£j‰/'µnÇ¨¶R åÿr°~Ôïá%&KTè}‹Ë © ŒıÅ¤*ÑWa,^aÄã=ÌÆ”ãÑšä÷¡ó¤Îh‘æ¡´Ìcˆk8d&qĞ<îh¥È…M5 ¢oäÂLïE>v×Rk§Ù‘*,	>&yŞ«YèdT—V­ZŸSË'ÕÏ^¥_ò=`4.?üò+V»!’• ˆ²ÆJ;Fv¯¢õ@¼3ÚSKL³[c_»ë!Ì³÷ğgµâ’ë}¼ªSš…‡‰ ÕõĞÁ·tì“œ²ÜÈôP“ƒ<N/	”fsÀ>÷sQ‰Z°=—Ïş†š„ûVÙãH“AÚ*s# üV·&¾şÎGtwB\÷TN/‰úì+¸MÍhÊ—_úØ¸ä»?"‰’;ÍĞ†4’•¯hWÁV9éºÈ¦¯v|‡äêÈ°3ò‹Ê¡s&|‘âš"²È˜pòÿ˜[1jÍïúioõµNÙDf_Å2Œ+mrgälEr/tR4ÚJ´S¨Ò´ıT=9 ÒªŸ:C^5”‡E2’MÛÑV àóº÷L_DÏná®+(£­h`úHhA0¶‰%‚Èá NdÖ¬q(‹İšâ‘=˜ì"½¨Ç0Ç,øüp[ğ>âKßÀş†,×şÿ“Ì¬”¸ñà“‹=vÎ.íßµÍÆ ƒ-Ü{³”niÎÈúéfÚNÂ#ÒôêÖâ|µËÄjBô8ôsB<švT _àù—4MK6àÒ@ö¤£‘Õ'û2Gßà1İVŠ3J€¤\©ïÉBµóXqÿ
À{€
’¯í™«¶Å+|v• :E%×º…^ŠGeû,àäØ’‰ÒƒĞèQfp	wÖÆPß[b0ÃÒ¶HPtÃ‰nÍİ`ütÎg¢ö£{c`(°Ò£×¦À=Ce8,4®®ê¢å?YµãuóÆ§–­ÙI(í@,DQ]Na_ª_ a_­İ™ÂÅ¢±(™‹`nˆêSƒDt™³äÎ„	¨'fÕ#u}9s™Œ$F¯ï$P£€’ó¢±ÂÉ‰lÅÛc2¥˜îı^Ã¸œ=rü\m÷\¶ÅO¡}·ÙG4Çí.Fùjä®ñV‡M(¸q­Ò"¶-¨8$h¡\l—(´W\pø¦hÖ˜/ÇæJ+”ásÜk„mB2>âcË%?k¥DIÁ­~z¯Îªö˜`ã[>‘ØUbYŸz¾N‘Z¬2ïºg35u3ä®ï™kŠm¼µˆ2©Ò‘;·lÒmôns"Z)l{ê½÷eÒ„š/¤ó>RŸ?/KÃ¶){ÅyxÔ"¸ÀËZ²ÔÈuq_Ê¼O‡ãĞz¾°óF3¦."m´
6¶™#&"<ïÛ‘–@ûø «¤Gœy£ËKvR¼·bg7q°ô~y$Ï×)Ã‰7dƒ°cà%’? Ï/mwM·}"ŞÁ?XëßŸÖÈmÿ k¼aéëøUıL3b=ˆTË¤¥Ù
®u b†–ö\åÔÑhå8İŠ^½ç†ŞZ>ÛÈé¦ˆı¯RÌì@›ÕkŠqµ.ÍVG{O@ÑlV‡^ÌyÃŞGlt6˜1ãÀ| 9ü&:?,;È¾—ÅRNìU&õa\"OGV|÷­~twŠÌ_EÓ\ı9±×‡â¼RLØwH½İwøêé;>¿®¯ÄwÃ±»¬‘µ£ˆ®¤¤ò‚zÆâBSCN±¿æï‘Dd™ó®ãÙŞ—™b™nê“x|ÒÅ‰I¿«pØ6úztãcsVáïe¡w•á‰VhO)?ƒ'$ÆEêO%µK…â.¸íÁ
ï=(ÙašWB¯w”!ƒjg(Ù¤Œæõ¥¼f¿zÅM”ƒVa¼"ÚÍ‹Ít«?´ÓªåC	€±ı?¢›Ó!¯"ÓxcI11BQcÑWª	¬ğrw‡”{¿_Ûh@*»¨%é]ìš¢Å ü2—ïb+ëÈİ?2P5Aªùê)#„"€ß|ö¤D+E+9²Î”Fçç¹6ÚeSùúğ¬‹7!8õá{©?qã§uZ ®38?=3®0LÛœæ‚ÉK`zİÄ
iÿ«~-´²#äc:ñ>„ïNŸH3´k{QV†lêr¸\VàÛÒrJâÓ¡é¹ŠoúB<
jò®aNàC¡ÖYzf¨º»PE¢1Ñ¾.×Ôøß±=T=†“ˆ±3Ğ¸‰ÓlçõÄüêÆû1ŸVS÷+÷~•À–¶ cs[oÜH€…[‘ö …ÊÿÉÚ¥$*:‚ºtÛDŠ«} ˆ»³RbÃ‡m‚X(Ü8o¦"¯ ’,İŞdú8µ»’ø/õŞùŒªY¼[ßYà’ùB´.Ißò|õõåôÍ¿Ki³]ÎGîr~Ÿ	(gKÖ°)î6}“wª´2Ï­­2ä[J®)Ê®)Ññ«Úo~Ş²‰´+‹ŞI?p†ì¼$6.g§î$y¼F¬MÕ£yÊKøÃñ®;i¥ ¬ËâÍÚéÓ}´Ùˆ“±5d"ÊrzhÇNşï¨çî—ŒEæyô–ğÜhˆØ¨£DÁw^(bŞÜ›ªŞ6<8Û‡¯DÖşÒ‹ ci‘dÒFòëu†¦}5¿hºç)sgg^â(3¡ÌÆ
åHÁkµ­<U¹æ€o:­9şpµ]BòÃn‡3Z£}ø_WÏ¶â‹’«>nœ¿”İZpa÷ùäVêOu¹¦’¿ø	4kµíG`¸H‰µÔ&X’š‹æ^1÷ÃLI^ìzäÁ¨	nÑè.~¤Š.:Ø{oÓû¬$xŠĞ3FïÓ…Ÿ/¦ğİçüzùÿ)Lš-ü.QøVáõæ ;t‡Pe¨'ß}İPX¸³¬{P?Ö‹^@×±â|êD…ızåfyîör9å0Şy4
¶“§-fŒz\…·°¹voG›¡–¦Ô-ÄÄ4Â$ÃN %$Û¾h‘¬·.àk•ÒÓ ì¾öq¦çóÎ©"¯ÃË™S[®OK±"7pÏwe²òµ&æ0›ûvÖ	÷Š‚ÙÅªPz®F‘[¯Úòš%Ì&ø&­r<ÃoWêäÏñÏWT¡ßNÎuKÛ9l-ör™¸úÈ´@í<YÊÚÆÑe°“âüĞjúU÷äM4cÚ YMVç“´X#1å5ı>§Ÿ4>6´HD¾3«x‚W.È³Îi`oÂ°ï±»A.Ï£)À¯	¢W¿‹õÂgl)Áò™®]Mİ<Ç™£ÃÚ¨4Vš(L#È•­kÿ)?ˆ²M…gëò!5P…Ò™«ÄÊfŠDãa{–¶0<¥J`Ú‘A7Ú˜P0ÔÚ'·Ô';0YÓX¸ +Í\˜-&Ct°}ÌMs¡óíâ#g>e*<HşS¢ú¼Ø¿ê“…I'^ôtûØ"çúš5,šß8}ğR¡Z[Án¡š‰*ä'êK…*p<djä¾"¬QR)!­÷6lƒ(U¯ÿ„
ÉÀPs‡ÏFº#»JJKşk[Fv	S"´MˆKNğ/³9B²w~æIîÃø²æ—]¢°‘ppÕ.¢‡ªÜÔCÓ®`¶œÅ
ƒØ§0äCg__Ã#æA*S7ò‡Ÿˆrîñ®€²Ój4ËÆi°¿*P€°ÀÏvÅ>Wã­d®	!¯iĞAíâ,?JÜCGªAdøn…:¡ø0=ãœªx¹É³¦!é¼É·#¾il@óÑ»\náÛbáU›9Â1ôâ‹½Ÿ_ªœOI2"j¸ ş´ß3´‰cĞ¦B®¢%©	hJpÇ;rF±J¸µñÄÏ”§H#nJ1o…V1ˆxŒ%Íğ¢9ÈÔL°¼´åFÁó{Ğ‰áIÔÓOÕwîÌtEƒš‚µÎ_tšòóåK´1À¾Í¸eËìqæ—¹Engp´Í“Ûv¨0}Ê•¸²p×'²m‡Vb»"ÊI!A·ıÉÖ=üİt‰Né÷':[!²\¦@xR¢­>;æıàrÁ}ô?Ç4®{'Êb!åÁ’ÙäúSªdØ9Ñò*ÖÂ8Ü2Õ¥xºw\õ‰¦l]_#È‡É–9rdJ¥‰àÔc“ıİ±ëÂØ­…À›–B™¥ø%­ÂbTAGQCb?hÛ$>e~ÂÒ±Ã–ú–¶c ¶QSîŸ‘vñT]ÇV>üë‹æÎœíö*¯exMcâª	;Ş»[‚•~Úp‰l*
?¾ H®áÜ«¥MÆ;}œó†B
öwß0; x"ŠO¡#ÏHÙÅèt	5õòó½WÑÛkW$l^±RÀ#+íÊ9¤1<ÓÓèÏ‘Ë'l
ìwZ Õ¨­ƒEG‹mT|Ê¿¶k¢vÍw«š~‚«C"BÏÅmZ<.e&H¸·wúU3YV!mS›ÚÍüì'á`§œ~ç@Gj¼`Pd¡K]ìb¸§ènµoWÒ¹¾˜æ÷}á»øä›W9 $éªMíÃ¡4´ç\,2Œü@) ÔOC)ñ2¬´ ¹ÓÁC>rÏ1‡Ÿ*8¬rœ _­ß<†×¬âÂÍ¹D¤—Êh°Nµƒá	‹Ô-#?˜T-òÅéV0š³ó‘› 9ÿÔèNü­)•h}ÇuñD"!
%ßà¡qf"åê#9O/Ç”Ñœ°‡.VáèxÅG‘şŒÆ˜}üRĞMñ¼è_ØïÎË j¿‘ÌUq¼zÏo)”ó…øœ¥|Ì^ '¤ÉS>¿›ÜP½õlRŞ	Q²è8)”Ë÷z´£(­/[W2G;ı­µ_lù?áoàó,ğ¥c÷'ÉÉ¸Ãå¯ "AJğûÿ78‘›çy->ïUÁÂ¾‹ƒ—;7ş³P¤ŸÆv r8‹é)JÜ×Ê“„/hf§M;5¹<‘2‰¾%rÙiAwÕKÅ²Q­9Õ~›Ú}rö¸˜PÕ–ù­Èi l½tWR¬é ’ŸWJ_ÓÚÔ?şQ[Ò·“¢½Œ qˆµféU0¡I<¼&ÔÌì-Óİ`	Ü®ß°şD²¾°ÀNC,ƒ­¬‹JÀÔµæÊı‘Ô}œ;Äß¤9–â_Àíüÿîujğ=æSS›•d[Är•ôuj…N_5CÄ›§ LK­«˜'íÂÑE6Àe…]ıe¬[>j_
.W%åj˜Œ¶–Õ$K±-ˆ…÷|&ìvy•MÂİ†îåŞÉ·ÎBƒ­ˆSòD}›áùEVÄĞš1Ë„àÆ©äƒà¥wC?$Bzã»Ùç÷q*.¼r¥œ–¦ÓB©V#¸ŒºÍùËóßÓ\™ÉnM%½ö¤~:7æ›áÆbnµ“Êúü˜®¬`B)bÄ\ß…#8ÊAÉ^3»T&¬^ÑğTÌ$šU‚Ä·#$´•’éø=pêƒÌ6Ğ¨ålŸ»;ÏT(v,ÛÙ¿LSs)‰­³Ç\ãˆ òóÕšé»ê¢7³ÓiÈ‰û¤ıRenØÆÛ_^Èm)g1b^lÂõ[Xeò7ùÑSÚó|×ğ[ßÃ1[O	™UA`®´zïù)kKšæò?@ºª'(nSÆ9õ4õ¥nYÇi«\’ïo÷Ä'%êNóªH£Íšdè^§Èºçæ]¯Dgêqt­ƒ~Ï©AÈm‡e¥âoĞ­[û¬H§Ãá ªn[eëŒ†Ê®?GU=-`4à½QäşK¯:7êEuİ`‹÷:Å÷¯µr§_¦ú.íMx'AÚ&	7‰[Éö„íÅsCWczúÚíÁ¾ÂùG€Uëf­àWuUSÛ)'(‘´µk=°(×,ĞWœáõØ¸ğ³T[gøR¥™ˆÆ2Xu”ğÙv‡ly~IÑÛ¶j±c)!*˜ÖDı%yßğ4z‰ûw¨§¥›q*äs^<ªºAòöš¥rÁË÷‹1ß[×ü†¬%]4n¤÷$"?BÑî0×çğ–0onzÃ ^4ÀÛ%E&ìV—Gt47_8ì^™Ôd>=ñŸUÇ:@+¦<>ş»“s4<¢’z}&:ÄYŠV!õG¹t@zFÄ0—	 ÀIˆMx‰;'’¢ø]Â?;½ŠÛ¢EsFÙ€KlògWcéÊ‹Îğ…-Ó$úşğP£©3S|Ñ`ô#áløõ ¶1ÑßòÙ£­™¾!î:25Pd'Ò%×¥?Q)û¡yÃ¢lh­I˜(˜ÌÀ¤*Õ;Ìä8§F½ 3D 6“‡6Gº±†¶4è²_=Ğ°Ã¦)ZŞ]ÈÀ‡S{páñ¦'Õì¯UŸ{Ä-Œ(Û‡i,«Y²‘u’¿Ó	7%3£.é—z°{0®ŠøÀÆåÙ¾1Ü^ÓZH&:^Ç¯ïmZoT~ „ç×²ñ)Á'è³.:Œ¸¨|#Š¯öú[iÆ>‰­ÁÍ»YÎr9Ç`4_ÚLƒi:V;%ZæÉŞànÎàË¹g	á-ŸÄïway7Q¹à @áİïïpãO­áúíIU‰NV$ª½"§U¥Iã¤å?XF¤„¾‡óK³7¼³ÏmÁŞvØ"£¬¼²¡®è§çÏ*d¬”ßÛ2voW44Í0üÛdwÇƒ¶=!)q‰>`•¤ùXÖ¸6.•â“(‘NÈÀm¿§~RpTV éney¯bãŸëi­7ïŒ±º¹Ü*úì¿¸o”•ş‡ñõ!¼gP×¾FG´¢|d-bHØ3€{>pÎ‹9KHZğ€€C;iP&mCÙ‚cò†Ş¦jz‰ßOì.ŠËš‰Ë€Ö™ê°>öĞâÿ¶ÆLq‰}÷J/Í)ØÕ¤úÉ¿'v}ôÓ ò·!5.®Ê•m5/ìËkàp¦^rmé"éXª1Bm+Şœ4ÅëMóéVº;%W©cKšmCÂG„L†ãÉ¢Çñ‚òxÎ4á%ıw®(¯kº$e[jêNV#LŠïìbCš ¢<ÄáRë§¡‡6ªr{œ…;@g;äaÌz¥]÷›àZîFm~à1'$T@wDóO‚‰ØI^R¿ÊTîÑ@Aòk¨^ïˆZpbàÿSò¼8¸üÇn©+Wêu*Âkş«n¥|iä<Ò÷L$BY ÂvN¯[¹Åà×ùŸòGk2V æRü
Š÷3ÏÂ›áb5_Ú÷WıZ¯8ƒêw7ƒ!ûÜÎÄCÇbS*ì	}ÖåÌøw53¾ZÉ ¦Ë•Ç¥Áç¶÷v	Üéw¢¹ Óm˜7ù"“oø‘¹ThÔV«J‰³Pî¡â´K= R±
F¢bMıs}IYP>&E 
¨§Bˆ—WNcá¹nÜD•uìtz‡ˆûx=!{ÁÉ
8'Ü¬OåaÓÈÉÅ+§ Å
o4.YB÷Ë Ü•¸‘:Óğj›Ï€kVjßÇeß…&‚+­2s!$p0 ¶iX«4Ä4•f*ºí¼»!1	aqì¶ÓÉ,Şÿ‘j­ÿ i8+‹óiôşg²šsJP¯k€©±Q­¶&òÔ6³‰¸…Lñ0ÀºLSIk¨¿_*]7EDÙø#Ëağ‚³,;Òü:Ñ=3¤jû–7›lµ¥2/pXW•¼S®¦Ö~˜é{ó7˜?Äy˜Çìà¾hÀvpçÿA½Ñ³o"íÎB(<dƒ‹_J´œÛiW÷§1ûòŞÇLŞIÒÑæ±IİÜ²iq‘äi<;İñåwU4E?ŞL^$›»¶Àı:“Ó€’Ú-ë9‹„çô@Áµè…¾>•dêİeÑ‹Æö7Y)"(íÕ%^ô¸îëı“Şj1öT+Ïc]	Tå«é 7ó	;¸è80³N·G©'„R=VV’kÙÛ…\•-¡¼¤Ôr¢ßlê°`ñÕ±´À¾EÛ}ğ}¯6(1´y›Áâ;lHÔÁğá“ÕàÿÄSıæ,^µ‘:èJÙæñ…cËÌTn™Şq¯°Ïiõº*’Ç_>H\eo@ìéû2[·›jbúÙpÛ=@<—õ/=Òå:2ÃÅû<Dï¿İ´;+!7¾ÑZ‰‰–êÖ‰ò5¸Şp|?ÑCÕÀ3äh‘L	Î6 i>ë †øgrkë#u1)†p¹h(é°¡5(4qºS_X Z¼5Ä}á·³ÿÿ";—îf¦UL¢@xĞ$òëò›G)¡=É@Y¨7÷Sˆ|9 54JÍ¹¬Ø>’´AÉóCHHÙÒ¦Ib#°™şu£ùû;¾G:ˆªˆ½°„ªÒÓâRå® ìÃù±t›B–}À£´ ıİ\Î:³úl{%îô|yxˆcOïè³‹…Œ¿‰, Bå¹dvZ@ÜzóßÁÒñ3²¼Q¤ã[}™ü×ÕèßxEtĞİ–2HMêŸxœñ+ â‚½gäÆã¥ ¦Š1Xò;İ…Öñ“uØÇ}œ{Ô¾g`$õ^„?9qPÛcÄ¬XG«ºŸ%»ãV•M©)—·(ô†Éc+ÿÕ=Éííß‰Fó‘ØyJƒ÷:ƒ„§Æ¹ílDÇK+9Ÿ ´ö{ŞÄÊÀr–¶Ü¥Îû2Ü½ù=Ö=Ñô§ğ9ëI(w‘Á	˜iƒ[â¤ZÎò¥§M,CIöÇmÃú?
KRÀ²æ±ÀÊ(›b?-¤mÑâÅîƒò5œ­†¢"a‚¤Ë!ĞàÆUis«Óì»pH+ƒş£ïÚ2+—åÏnÊSÏø\T,»—ˆú{$¸Ãyc.—X¨®Ô…¯1ª×Ò[Y«FLìsãô¬ƒëˆ;:ÇğÜÃ÷álAX :$-wL­HŒ‘Â¹Î³"¼ü¼üºn,õQgáÄÿQÀŒ—âàÉb±r–Ö¸l!’ş¯ºÖW ¯Ì‡o´!‚5ó¿/µ¤¦q;EÕ@¿ZÏe´[¶3à@Æ÷{Æ_\÷¤ä€ÂÔ!! ò›˜gBÒÉ*yO¯¶M<ƒBÇR"~á’gĞóøÛÈˆu—1€DE³?Õ ‘ÈØX…¤ti¬Ò²†Ê£y9 Òô‰ïğ|î˜´m–£ŒH»­×äĞ4ıX5áÔT.Ø‘Xóe(­í
5i.pBotãZNÀ’t|¾TXñ»ê‰èVQÕş›k`Í
.6Ëš.WQ@è-VºMÅpvDşõtØ|ŠóÍ‹\(™6Kz.>¨p‡?Êş«dç Ò# ğˆˆ_Xñ;qÃ^±½%Œbø±’ÂSÜ©{ëdéTZ‡¬î_/ F £/È…V=Ë=é]"`âŸª¬>øË ÷®cŒ‚^İéõóbÿ¬ÚaLLåSk;“ç0/¶ãâá3á©çBÔJâ|V¯ëlqYûÑÄë™(øÃûæM~¬SM]vrN‹#¤XÈ&“FYÇ’™•K?(²:ióMî
5b1ÜøísŞP_ãlå¡9BşäÒ6XQiÀsğQïn§aMó”ñ¢1†ì‘¾kN•ö–te)YUÇk–øŠ×5ëŸğÈµ.2øáA×ù³ò5BI°âW]Z×L·PıØr4bV7ØË{Ìs%ï^Q™ˆ€¿£ª’ÇG[3§Ì]íS 5äåáI·ùéh½yJÒ“1Ê¦Åß-î7İ†f¿ë=OôVrxÔÖfnÍ]ªÀdÕCäúÉšïK(ï)/V—0||%™ÒÁŠôŸ¤—Íe.t@ÓJ.`l$ó¤ÄSƒ‰À„ÜáPBìÿÕ\
DğxwjòØèß{à_‹SVÕï÷${
5a9*ñù¨°Gê1!›l|
sã5M…€I¤6Ã­ü=ycÀŸì¹WÌí 6ëœ?»_[îÿßkJ¨iHØÈ¤¬ÅŞ!ÃªfxÁƒ Æ¨ìçmj[képIÿá2C‘VòO&ñ“¥Ã—=À}êÜŠ;úô+òäm–<]«mCä¢[ëâ4Sz%Àü È6LœeA£dc•^ºXêN~²3s‘¦N±
ÃŠòƒ ü¼õzş¿óIcTJC¢æ)òİM,ÿ&RbY¯FéÉ—R[Fÿ ÅÈ`ÇYOHMò	äG¼œj ¬UØšjº¸ÇØoæE“{®G	Oœ"(1N#ˆ8Ÿ&XÿHÖ"í“åè~éÌHÍ²It†GjÀ¼õµ«×#_%iİzRIeõmJ¬Å)<÷€
’lºg‹Ò¤Ÿá÷S`šˆÍÂ¿rdQ$Ò5Iö‹áZ²ºÄ~°:A¨Ë<KšÎş—QyĞöP9o¡¿7íïÒ"ƒùæ%ÿ-»¿ÖZ4(=
ˆbóÀÆıˆ<ŠjsÄ<2ŒCx3†z`.á‰%ùêÀš‘=±±.¼<U<·ß 0rhUŸ5©æ2wÏhÓéeuâïÈé'?ÿ¹_ÿM*½‘ˆÒş8\¢ˆd²h³+†3‹Ã¾	¾?‘ı°Õº €x4š³şåÉ½¥P<]¡T¶3KûòüÛ¹¬¦$Ø…n.Ù¢šËúwÑYøºjz˜Ï8B#Ù{ ¿Áàpêjş`m€_G=ò³ËXÎĞşû­spº¸Ô³›‡0ß§ıÌğb… ·˜Üçı¦{f<h°j“ï½ÓÏ4ïyœÚCtlğø’äRTÁ¹´¶ÔØf¥S\»º,±°ø"ç“fî‡…gÈÊuè÷{ÒñUsI“qCdÀ.Öâ§gBU±S*TÀÔÜ~¾C±¯ÎÇF®	£CÙÒ®•]ê@2××ïOê—ô›Ñ¡àÇìÿ·O†£	\¥?îh±ÄÎp9Àiâ>ÀT$+:ÏÕ@9«íÌ™·Añ</Ä"ıNs@9pË~w3có]—şjÑ-ÒıQIã-×D®äØ’`|NÍM£üÏòó==6däM_¡ìvM”¢‹"$,–'d8«»-ş3	ÿ2­G¡~	ÛI›^0,R¦ìR£m#*|´cû¢Á‹Ÿ®
òz*Œö°çwĞÇBÃ lŒŒˆ{<~íÜKBŞAUş€Ø¤ÍV†BÆùñX+)„TI«vÌ3´ğt­Õã‡ÇíZG’ëH\ÜuLE6„År´3ê¢	7½Á×Z5ôn4|]fèö~ª…È#ÙyíxP"¨e€\Ş ê0°Šúùm¼ÙÒÿB`[70`ù–ÅÃŒ\ÌÌ™1s{¿n™ı¢Ï·+:Îëàxs6$Õß¾x^Ó1TQ‘xxßÀ¡=™Cìüy”¦	PÙ»ñ¹¸O!€Âı/.
Éæ	ØÌÂ|™#¯(…‚{êà.fH•ø¼1ú™Ñ˜ÿìÍA?Bì¡	¦Û3¬N7<âO\MÜY¼Á-ß?^»r•Ízæ£\ë²ÎnT9—XS#’œşÅ0-­áá[ÇbÀ2\«çâÜÇôéóSƒ¸h¡—!c#F? ·¨ù®o!Ìá[líÜV•`¸)rÏäùã{O¥ê>èÌ¾vUÓWøpõyœjs6¢'J­Ma€lá‡¸yìJ¦õ!Ë[ZîJÛeR-íØ$äædÆMM¦‘CHÔxBòÖ«²‡‰¤h¥a·µ±P~‰®‘hGÍ€íp:DïƒZ§‹ôS„4)yH~HŸvnW§¿t”ì6Sä{ ÷½§Ø1ªiú-ëŠ­eF<jš‡+ŠvøYSk²ïb³GgŠ—Hîu’‡X\»,k)Z¶D²õã¨úÎz4ÍBì£æL„-Ç›j`ó¥e°ÆùªPç©½fµ–ÓÍQRg®µd‰áî]Ücç˜=ˆ8$$¹í§Ä¢¯ÖZï”O³GRgkBNÏÅâ’vK¿ïÒl&´ÑáWÂ¬îôIß˜äÙÍ´Œõ°–ñrçMQØşS=ä“i<	™Àr2Q™ÄUó+ŠšSÕ…*ÂÜGÃá±‘‡£5Œ#QVL+ú9X #Å;6ú¦‡-ÊW^7.²-ÔÕ90Üh=‘ş‘À)S”Şá7MÉù©ƒÓÍQd83„¡UsÆBDÃo	(’²ªölù¯¤8… Ò†Ó\‰™é~ñ<1YYº{¬mnt”)ï	˜Kã9„šÅ®øöf<8ŸnC«G=óö^pô!œƒ[æa«Ò‚Ù\½úïu5Ãc#0”«Hì«Ïª+ˆlÕcáK‡¼µ'!ï­øÔ­İ&€’aJ]îiVï¢C/\IîÊÎK;Ê5KŸt‚‡z'Íşd¾(\r\‘1!‡_Ôx$ãœÔ{³4e˜È¿ÃJÍ­úâÆ‡†¡NÑEWMş³‚ãrL‡í ½%^û.ÔØüsx÷"ÆHûäók"U“QÑäVárJê’¬Òy›8›×[ŒÍÑÕ0a“€uU›Ù‰Ş“ßL‡²Š‡ÑÿÈöŞ"$ìGŸªM!ñ¿ÕpiæqÄÓÌ	ç4’¾Ñ²³ÇÎ4¢qlÈÔ|3˜Ã7L¿dS`p~·¥	ljyÖ$Á
r…§’èÖŞÅ(z·PÏÜx29 ÒĞfª›‹01<´‘“iµ5¾1q$h{HÆ¶ÑÔ6´h%Ëœ—
ËÀÙ$ª›†EİP“Ò’d&Œ !²Ş4·$,åw)Ô*„B3•Jt,ÛU•ã°%€h¶úD0üê.­ÿĞËz-kÊ¸1õúPN­!½ ™²3e@ä1€gzyTK°xyÆAÍ/}åãğ	pŠ`göŸn `0gQi¤•» Î¼°é°«·½ûú?¬{¤õ]”'ËDûˆ¥¶³íóÿmª©Æ<·İ·¾\j”çiÑu<\¯ÈÆ—¸°3ØÓ–¼µò½ùax„†¼àÇ’Y„Æ3"ıÉ6D×ôIKú¡¡]súm©
±Ãˆ²»¬ á/v¯–ıpÅ|_øU(éÄw‡#]FK)Zç'¡ËZÑQOwØ.´Î|‡¶S-O$ü=[Ê€	ÀÖô óúûœùt4p£{FQy³!n´ã¾œ6*9—ö’ùîĞÔùq]gëaó!İ,y hîÙ)D²8
}†[h9Å©<7ºEfäbßêo÷PIf_}ÉN|m¼ë/ÎqXá·k=q&Ä—Ë¿ëeiäîÃÆµå„¢*¨?¸”û¾ÑjüótÀ<(úwÖSÉ	X)ÃyØh`¨Ûåú‚‚ç·wü,ÁéQøÕ¼1¼êãŒÍŒ,ˆ±b*Ş‚´Dhı©´ã4(ëÏ}®9w‘ÁÕB^[ÅC—îlı¤qûãë.RšO«D#Wxœ §æX=}B…ÙˆåB3…®|ÃÎÓk|¸_à£Z&€Q]êµI´
dÊ;ûœ‰Fñ{ŠÕº3ü‹‡É±8Q`)Xû•ïÑõŒ§º8ıEfÒ#¸MS»_CÚIñ06¤½²V*Rä;ÂªÏÈ³,O_åÜÿîaš vıÚRSj;O½—+UÕ'3%ÑVI—{cñ—oOÕÆM‰z‰Õ{ãÕ¬_½/>ğÔîºlâØ_ûŒœPŞòİ;šaŞÇX8o§àD]¸GÄ˜9/E©ÈüóãqF‡QƒFMS\×İÍ»öÊÈn®@×ÀñìPip˜iQh¿ÎòrE×)|ãGÛ5‘ì®€•¸	ºøÎWËımÌßi–™9+¼}nÖÍ!Fn™\ó[‡ê—)9Ö^ü›]eÙ™ï8g…¼ŠvÕ²ApT•„â:{Æ¯ó•Œ~Xá)íª1‰¸±rëé½+q5•úk¿ˆm0ş”C€ñ}V#ïs&qÁÒ•ÜLü ¿ˆw¶èˆ©Z-"y·Lå6Ó_
î 'CàUº‹^İÆhô®m±½k-(ßÛQĞŞ}¥ÁnóÛ”øZçaØKP k¡×5oŒKd<§©rC¯ç¸•nTéLfªPh¦ìÉîŞS‹'/ r’dçñP;Öƒ¹‰«5ob³¡,'· Ğ†sµÆğ¤Ğ2AN(Š;7‹äÒêœûë*Ï%x×>,×Û-1ÌgÓP_•ÙŞØy)Šä“Åçß‡ó^ÀòFq.[ò=6g{¶†›ÛÉ^gı<V×‹T”Ù·öx–ÆqááP+4_€àmwŒ}Å]!˜/‰/Š¥ÍÕ}ïß^´ã,›ÂDÚ;}ë…‡,û¢İ2ƒmEO(}ƒnûšY‚ó.Lã2s¼°UbÊ½v¢Òb:«
&j™P#Ğ¼y9Ê=ÿv}ÔŞ\z8w	'#YZm}ÚıêÔŞœ+qÜ»~‡úm…LÃÄók¡ÊÜn¾ÍD´WÔÛcòbœ2±×Š“£´ˆRN“Å-âADáñAwJâT×!¨RàÒ]ö's¬ßôİ+a>.ƒ„\–Jo?ÕğXêë½`ÌéŒáŒtdJ˜÷‹Æ‚ÇmÑL2QóÈÂ·œ‘Ÿ‚©¸)mcÌ³Î¸ùêdÇ.İéõDxŠÈ´Ñhİ  (Kç¶ïÑ?†åhe¥‹é
¶;çw–ØSGÑÍg~ú^Íu‡“RVğãjÅ~„g–x5NÖÙİp5îuÏV/¡Âórƒ¸`LsĞ$Ïhóh6glQõñ2\ƒ4ô-9{”b_¶­C)å­¸êqHiÈïàP8=.¢ƒ™¼5E„;‡ÉY 4`k¿G=!”‘¥Êù±m-6ÚışD<4i™‡6Yf€®úù¦§Z%6fE`vóÂeDÙÑöSƒ°uî£NôÇÅÔ¢°!·q.–M+ùä×ë‡x	š½nŠH«æB¶ÓñŠV%œË×D5­Á(<ñ%)+ÇÓæó‡óBóRÄÜ4¬_ß€±Ÿ:¾öé,$•36_‹z¸_YcH{nşÂÖ•û‹Ùëì ¥È:Êö=9¼@²Üé~"]PªÉ$µß¡>Iµ–÷9Ü÷¯x5!!y “»¥ş§î®
¥ÕÜ°ºCÚı´­[
D4ÿ’€y=İöğÒ!«xpßâhIèWÄÀ+`c-lªLËùò;<lPÔ7•dOÉû,N²?9å•½†üøncÎB›òÅÚÇğ4'˜i„‘eà²_áE7Ÿw²TsV¯ãİåìœú3°å^V;š‰‘nîš©W17ïÇ^çäÍÏ–¿Å›“f±û…7¹]^.}u+º¤c:À°İ„ÏıbuLÒÛ¾*Ğm@œÿ¹ˆøõîĞ¨Zú:3n$Œ(€3ö—Îyê|áF¶O^ÖZ#)–ıI2|ZI³Ejá“_©j·“Ô9·lr.Û2nááŒÌ‘Ùâ‘ÒŒÀ|@ïü#¿¥¯§É^V9‘(1×*ñ*yÜ­¢«™°¤lÆ Ø¿®·Vf’·EµÅ1Ã”-äÙú_Ê‡9å A¡{û½ÅàÑ@ˆm‘šC’‰–¢A38¸q@l8Ë\f“°Ş:K”ØÎ+šÁ'ÜĞNª­%œ:g¨$´S™ãø^tN0bm‚®ÁjóRßYÒN+Û‰è¼-7½úãı*dKs*ëNDª±7‹·5TîB{¸—&Ñ9{ íaÂp?•‡Pñ7ßà[j‡’ëÆ¦„wˆd FØ/îhVëÑ}$ÄëÎ5ÛÈkŞy(“âuUª>W¢’›·†ştÏwyÇ>vmG é7‘Wÿ>>Y( ış‚»©Ì`™nñ„Zz¥«işÅö¹¥ÖM*Ûg–½OZ0r#X£4&}nüİ„Ü	gL‹b	Ô¦HJìlH.Ôwí¼S
ÌÍ‘òoz--YC{9¸Ô/Vb4dwX¸{³Ø@,æaÄéKçQB*ÀõSö‡œ£lÏĞW@tÈ) c†ŒôÈ	Äo€1©XğuqÃ¼“’o$‡ËÙ°ç
›JŞ„joWSî=Ÿ]Ğv¢tyRÎ©uåJ”èY†““Ë¦­F¾)ÄdfƒÅÀıg¿Z\ò/á¾¨¨oK¼ 1
÷`ıbJ1)¿Æ¨dRKT¨ÿéœf½]\s˜µ|’a:„xŞÄò¯]¸ólø4ö„ÎŒÇ¸+k t8ÈìÒ¯š²¡œÚÂZ®‚J‡¼r¤w\¡+N%;tmt(”şĞD1{Oc$"÷bd-°15s;-éÒİ¢%¼Ş§·âtµê0ºM'?U’ú\*-Ò2É¤Z×‚ü"Å«NÅ³öDM%blööYÆïô7â"ÛaÆ—A(ÃÃş’g[Š…¦^œ3Dÿ\¬ºµ1¶¸ce…u @¾Øİ—º„r™åùÖš’ÛÂé[£ê£¸Ÿ:y°ãZºU–¤PÏƒ…ù7TûÍßWüd 	òg.e@G]Ù¢)¬‡fôÅ×>ñş¬|Ø
Ì¸(ÁGÆékİèèŞpÍoİZy‰2(j6"b¨4§„óÈÌ)ÿ*°Ş–Ücá”ZinÑtÃ¾G·²d]G<¾s d¬C›¹‰=¿ä™Ê«ò¨ ±¿ûù›ÂkpÌƒ¼ûù+®7éU¾À5¹+ãaˆOü·“HTÉ®Uº‚ˆ¤º„[–¤Ë#´XdôÌ+š‡f ±âqz±Ü”s®Ç²´ş‹Ğ ´ö_…Á¸ÖŞ–m·d#±ÜPzUam(lQåÌR‡õ}`k­Éb°ş÷5dé%šcúê¦zû×
hÑ‚ô–4lß/s2ë(ÆB9BP@“Gvqmïl,ß¦=A¢ FıUD¬2ˆFˆ¨œÈ‘|…!èv%Ÿ	h¡õ"ğçWD$d}Ş´äïÙõ>ò[ÀíçYÆÈßNÙª
‘ëÈ7äF®JXÆZÁiSââ#Ømìú/PÓ8Rtgó`½c°Á«§î¥·$ĞÓ×C¯®Gûê÷‘óBátB‚Öº2ÆbäB@¸‹W@6‘åòŠÿ"AÌ‚üÎÖ2£Pé¶'ˆâY ÿ¶`ßŞÅ¶>ƒÉúş~
¼: «”k
ÖB}´˜lS¦)Úo¿**æŒfÅÙû•ØTŠl—Àı³dÛºE93ò‚vü¦±´‡Y·ÅÙêaæš&´İ²ÙOqµ½äÀ‰C»44´ösCüWáiÿ¡áí>İ[{ìÀ¦‹?6Š‚zÙnÙ‘ë"¿M!o‚âôÌM£NæK_Ç.NÑ¯o×JËK«2N½:ëÉ±Pš+ã×áÎ.¨²!·uÇ¸&Ó%RØ~Ûìò<ãOqGïj~Zg¹÷ğğgp©ß.‚úéÈ% |5ŸèÄJæ®4i„È¦ÍµêNJlE‹–ffÅÉÇá™cz>8ØÁã°å×,Ò¨~ó,k«UÛ7pãvû€;†•æO¶³İEq˜Á¼‘â$*ŒqXâtF2ú=ØÒU· kåã2œ{PÌc[sœŸ•Ã–e¨‹7prÈèáÄû&ä,_Ã>kJW“„sL™W\üµÏúİØv2‰ùUT“‹‰Å[q)áüÆğ“"­±˜ä©†6±0ê«—‘Ác9=‡wŒw }œ§³|ËÛLŞo‘û‰uòGâÒCÇjËşv1EülÁ0üDF›d±’ñk ¦ß‚£qü>fÿ
êDÚ±fŸË9½‹XĞİÏÉwìmà¸KsHRE›YC™7l´C¯
%ªkX‡ğ‡]Ñdæ"B°Å!€>³m€F}°`èı_Şä±Cä¦2ibAÍ`Èxn®XÛÏ(£¯Öcc}L
º—åõ¤Sè/>Ñ'„« -ÔoHŞÊ¹ûˆXÍïï5êÌÿ|\
í ‹×²ªX§nŞ%‹"·j?ğêl42ñ~ZZa:/ucÕä­»	}Šf^Æİ˜I'–3UZ‡Ô 7ëˆˆÊ‹éK†ZÃj$Õ uÈâ•½¼^ÉFXdÜägÖÏ[fhI°Ú¥£Õ¥t“ø¤Tí<Æ3BP‰^~˜Í0Ï|ÓĞÅï­¬®Å;hHøèÓaä]e |lº&,ÜKI÷N©nEC³¼u,Úç½~öaâ¯˜šñH´{æÇWÊ¨Âh<úÇÙ(‘³^ 6¼ŠŞ.æ·,øW»S¥`‡Î6cxı–ĞàÈ«ÁÀ¨Oà7Şe[ÈÖ%ó: mQJŒc&æ`'‘Ã‚Gß4eÌe@ˆ‰à¤Uˆt‰Œå£"ôÂµ=s=n_Šªõ.ÎzÉıù°ÌTi´•n?Öi~1º—u9ÈP¨//mµ#‘t!Sw›r@4I°É1/ëé°ÏsG'ğ5f¶=ÙÂK$4BL.õõ–míOû¯Vë7Úd©<+^”zŠôYøŸmlèÒÁBÑF«G¤ìŠ>Áé¬ªù¯ĞØ¸îIöğß„d$$6«èY×{f^^+“S…@Z„5©ML-õ–HC°H†ûFEÒŠÿ0B—~$*w–…ÀvOŞyîøä–h…ÃêuâV{ÖépÇ¾o!`ÀéÒÓÄj«oƒvµğÿWü;3Ì%ù-SmÜİxıùµ£ï.áÉÀ†@O4«_Mùu{gºü¡æµ›0DŞ45ŸŠıÆœ˜Š¹.›A'.Ğ,Ö„½9áÛ&¼ó×9?ôœü÷
·ÃÖ&'ï&ï9[ 1Á·£ÏC.>Fm«ßáî:V¯é‚Iz÷ÜSê¾ëÙ²C†pzÀ‘6€œà>1ÅôRÓ866í;Çù0¤›†vn)ô*&8nP—I_Åü§,N+2ÖƒHx5@Dù‚œ1´9ec“:Bjs³cƒÍLğÂ´|<o7<5ÆXŒbKzŒß9Ï;Æh—3•‹…å9uäêÆ…¸hbççn-øÓë²Ï¤Êñ÷Œ48ü6||İø
JÉh¾¨WÃóûâÙ+Œñ•X.‚Á=Î4$I
”çÍñÎ•›÷½M+P`ù¬´=ë”µ²òÂbâªdUØ²Êp`b¼lcË˜Î½ı}¬¼#×Ñ(q×ÔˆÜë‰1Ø£¦'"HIW¯…&·Ö›yÃNŠüß×]?ªKq~¼@Í¾?nÎäO””Ü™–$é|féÚ]Q©i_òj@¼çÚ2\Âk´Ÿ1}DÁ’ºoTæ&x9sUYC½'Y‹¯XìÚ&)Cä
nÉ¸S­¹Ñ4Ï¨;ø#PPÙ2X¸RjñÅ£Œ’€·ßÂË|-µPE%¹=e_Ölæ¬éózgIMÏ«é[‹UI÷ıR/>ÛuÔ–Á¸fÎºŠTÊÉ@Uü
Y• ºPB‚™è_É¨§W1¸²‡z½ yÊmüQ³•gïÿËŞ§;e‹it5w¬ğ;UJY:|ƒ5á;ÆF©KÙ¢„A©ól²Ã¼@‡Õl©t˜SW%œ DÉí[VH¯lí“õ%ô¦9f6bnÀ ã“ûÚŸ2Š­]7g‰Eñ¤h«Æñ†ôFUÒ¹²éÍ°î.}øÖ@Fß©x
qĞf •½Lv0¾t*øÖGÔõz]<oß6Yİ÷#Ôp¸r-YÓ@àjZ<¬VâV“ÿ6½Ğ`°àİô»ˆS›‘Š…U-Æ.Vû+gÒJæ	…$^e¤Ì:‹àÉH  !±zıÌòf¸ÆUºÇyVd¾r‘Î‡LªÖ›úóã-°?rDD•×ËTDÏòM
2@OŠ¶Ş	^Š”Q‰úhû—dÁdãá¶M*’ÄÍHÍü³~—´ïZ#•2A èˆ¾­`7ËÕwÙ'{ºU¢—yñŒş±Zé¯ŠLœ²ÚÃ²K•àìz$ŞLÿf^
üWŞ±€÷ó	hùpuÈôfñÓá³G¤AåëÖ?iúp¦×¬»üüíJw$5wšëÊ&Æ—\)´iQ5/Ìµ»^íç¸Ã÷N„ñ´4šo{±U1¼'|ªû[Ñ8´À‘Ê¥ÖÛòò¯û"ŸÏI~Y€©aeç5^WÕå×¬À¼Ø­ã¢èúRj=BEF÷İ*-:M‘eNïQ¨Ë¶ö¤X™Ëšš<š1ói«E„u·½&5>UK²û/İÙÏ6	Æv#0àÊv¢Ÿ+¾§sÑİÓ¿¤ğL‹3j/‰td—±öğÕî	èUj®ÆsµÄø(˜óWñ‡%ÀßiCñ4Ñ¤6Æ(²ÑSB¹¡£KXµ<H…dÿş3ÇèÈ–Lõã‘D¿Yù|É×á§V§RáW’Xx×ÏØÒÒÁÌê‹A©ƒb[ª»¿¢ã¹fu¿ÿ9lRDÜw:@p¦62^”<R%µùÑĞõg}ZØ¯ÙrÃ®ş¬-šZÕ ‘³í?íïå#%n«¤†%¥êPàiÅ“üB;÷§GĞØÄ8g”™‰­;hık®Vò­g®§®s„ ;~3ïÿÉÁÚÊ!hµ(¥ÿİÌÊ;Û ÃòÉÇ+Š%]ªÕ{ß4ı\šjÚÆá±ÒPÜ¬(&øò67š­µi¤úpb82ÏñnPZêÿM+ˆ“îŠ¨KµØ“ŒW;ìnKéß< Ÿ-ğ*£88èÍ%
®«@4'F„t_œÚxş1qlmĞÅ\üÇ¡ue,¥bŒ|…/	æòGàü/ğÁ¸`Q‹2c¤±¡=…º³/=jÉZ»ƒÍg÷Ô@¶ÄXÔÎSä·Rø&—:¶ëHdTŒÌy‡îïD½ßÑòÑŸë•½Ë	ĞŒ^vq÷A"_«ÁVFŠFÎ¢p‰ájôQ]3n#sö¨åñql{¨Øu•g¢9Pl¶îş4p‰Ÿ†Õ‡'	gM™…@/«91´Ù‹ÅÃİà`9ã©gSİ³GÕøï¬ø¹Ëü/¬Ã,Q”»vk8¥œÇ¸ıGÀUõÅ[Î9k°úÍUSèû—qöRfäQÑdÈUQ´s`½şK­&’n3æ©¼0Š8»‰k‰ÁZWÿ`9’‡|cK/tâÒ†¬ªİ˜º-n6€(	çTúÈŒµÍÿªö™TD7*”’Ù’;#™®)r6¾‹Î[şÁ7[êb5
@bĞe:CûÖ˜ÍAãD»[¦ÇV9|*0«DĞÃh^Zé<ğå~ƒI<³N\mAÏhF	…Xâc!€vÎëä+Êm.X˜®?ŠV¹R:"©•DN³7‘ˆÓ•;e›‘]ÈJ\&Ù"R4jE?’¶#ëH£iB÷³‘‰CĞ#üï+Ü4V¶=ÑOÌ½ö¥ñşò[ÙŠVVãKÆãlÿãˆ§8XštHÈ"Qg.ãwJF<1`é] BWS:¨/£
-T¿¹ùxr$ßıHï‡‚3tÜØŠú­¼ü¼¯ñ¿QquUr15Êş”G¦ˆQİ¡8K±.Û#½Û¸»IQŒÈºêL¤­Ù½|è'%r”»ıUïatúãäÉüiWRUò^8­ÑçAï°°Ô·ŸŒ:}ıŒáŸªkã,\ÿÒCt‰H3hEE“…Ññárş÷kúvâ7¶ø?âî€â|’‰Ã˜„rFŠ˜Cı¨³°Ô„8:OÙ6kV‡€¥üA½Û¨/ª’d¥ yú´3O±“^S—ÿî–ˆì¨çÙ?´k£Y)¼p0Ta¹‘ÜLµƒÁ¢gIPöYÖixÊ'ëñŞİäí‡59ªz™0:·mÓZWÅQ1ñxƒ.9øO±g¥PÍê¥R4í¢Ê^20:¸âJe¼ ÈEà<y¬8rµ¨M&Øèz>UŸz­#	dZÌPsXzÅHÁ¿4]ñ[]±a/é‚Êfçu sD¹öMœç\®d“¾ÂpÒWß8{ã. ÷Z÷‹Iµ›Ø¯bõ/®ö®'M‘IÑñ¦‹[‡VĞH«t»ß¤Åã!²ñè†Õìê±×ú¿ç©¥ë½äl	iXH›»¯ÆÑ¢/ºòŞŠ”¶+˜mü:	Å¸¶şğCÀ·ï¿y3¨9NK9½BŠ!8}ù‘
R²o•Ì+Û»UÂ¬ûx,ˆP™ï´jpú2Ìmƒ#Hc±¬hœ4Ó^æ¡Ã!‹YøÜ×Eâ}ò´ú^§“£ş~ì(p¦/ñRQâ²ĞÚ3áH
Â¶7ÛŞp!Wºÿ[0˜ˆa«á…[H¡ó2‹™1BìÏÇúƒ§‹8ãùÓ­áî@R0DA¶Ş+lş¥î¬É$<Ê˜yÖ£Ã²l¨3r–}bmcüş—£º"—ñş‡'Š[~ge„Ar]=k+a¢-
>7ğ*/ïümr
ö?ÚçAá®9gj£¼ –«tqa§ÓõæßÓ,– „QÉşék&SÒ€x?3ÿu¦‚y¿®’ñÖU{‘@„‹Z2µĞI£.CûÿnaÎecû”dØƒ°&öŠ2`/J™·[ÜÓåWÛ/£pCºMWNáÇ¸%î5BÓ~Ü[·öo'À{êGxŠlT­ö\tº(N®-5$[š5²T±Ò²¸{ñŒ|«‡,4'ÍÕ½ŞË¸ˆ6/i¥Ô]úˆ‘#F/Ø0›«2—Ï<1¶ËQ÷:‘(ä.	¬.ÀÄQçÀó‡Vä©/rÎÇƒ¤Î|àÕÑ±ø<ßĞUé‡Í±ºÚğ!ª»¥È+R›¡ó	»üh•ğvé[`o{«›JŒNzŸ$âòœ«°©o¾½º8¿E*jŸ¹ûõPUÒd‰xO™2¯»mi4"±'7s…âÅ ¢f«rJ f)¾—3U´‘$E‚,½¢ëéebN’Ö•
£‘__gW/¯Œs5ƒO°ıI4£İÒbô³Ü³!çÍ;¾k
º^Gz¼ÖÅS	!ÇIl‹¡^Õuè;":“ÉuÚ±QÓG±Y
GV‹ë§²!R>îá±Ğn_~W\17Hô`å:vV¸e‡e‡u¾=v5v¸šÍ	QÙFÇF^g&ªS@LTïqšµ;¹ãK?;¦ËhÈ,ÿlª2®íş®ÖĞU¼“_-¥-Rq¸ù³Ë…-óÖ“p ä<DB9ë5F´D¡,=±5'sòãÂ½ìj£ÉÄ‚Ñ“Ğüƒ’¹Ğí;8!öqpDêğğ¶àÁenh#'K¢c=‹‘F*ÆZ`/3šŞøÕ¯7$”‚4pÅGU…WWÀ¼§ãÎ!~ÓûŠ'”uM®\b¯½$^ºˆ¸¾…Bhy©¸È‰ò³1YÎ>–d¼“ÿt£Î‹ç”P¨q²’}7,ÂXäg³éá™9RÎû*^F÷#—=UoÍ³lŸôÑ•>÷K4ê“[ä”±¬¥niÈcˆcÛÃŠíÆVbòç,ÕÁOWs¨)aTC^9Ô1¨â6î•åywì£n©H¿W›“·“E3K7ö]c9¬ñíÀ1Ï.›üÊa=­§¡¹?zŒ h §}‚T	Úø±ÅL…™ö¸º+vË;Ôƒ3·9·‚qm&û×"´ea2C¯=˜ó©-ÜLFAu³T±æBM›É›)ñbI:‰ùßâ’ä[FdbjÙ?’7ÛOÁñQcöÿ¦È],Â2ÉA~8VcQc¶‰è&•ÈÑÖOáæSüW+€1Zğ‹}Š‹nÏö­†X)gµLkRÒeL\”KsO=I²Qc¥ÊÍ4‰WãMœÁEıĞNÿEÿ•ìB =“%Æ¢ú}Ğ½=ÏQóâÔûÊ}a>é®Šcl£f|h­Ã·êòf÷tÑHZÊ-tˆş3Ò•™³ ôâÄj°}ô(¸&­$WÄÚĞ*yU#
[+Ú-2zÈıM,ä¼ ›àw1ºÃ+Pqjù­ÃLšæ\ŞÉK*s§S-œGÎİEüêxÇ!½7hrüLPîJ¡´{m‰Ğ†–††»ªÂ3æ&!ï©iÙ*„8w@ŒòGeİ¿I8c–LôZ´L¹›B2zm³B\â&ÂZÃ©¤
1•rö:€Ÿ	'ås³™X®+ìn[ûÓÙ™Æ›xF…y¤–u„Ö®ûK9“:Qê(¿UVk™b5l«_7\ıà³A±|kÑh!ªvpÿ?Ğ4°0Cˆ¿6‹­PKì7êK¶To7‰Õ?ç	o›—úƒI<©ÑJÉu˜/Ğ.·¬í´æå¶‡cÖô=ĞˆTn´´ñBn³Q#Gó é… õ®)¡eÖø×ö–â•Ì… ûH%6[ N¬Æ;Ô°‚Ñ¥L¾´¸@z)ôÖŸ_@:íŸ›a¿T.]ÄÏW*ŸÆ\J W·îı‘HJúXë¤~`Œİà¯Äßîÿãb¥ãï¦Q@¨ùk¶RVßÇôÃ¨šœ¼õjnİ9Bƒåà‡udrÄSz‡q¦ªWECgõ\¤AÇ#®¾_ºnId{ÜÊ\ÁEÿ¾•ˆèc5x0•U û#º¨âŠšw$+>ÓÊ* sÏÏÁ3Œ;ó!§Û=^ŞKjš 6Á–‚9×ôK2[„í¡’+Ë¦¢™Ï·1SŸxÄÈÉß™ƒ Æ_W²òÒİ‹‹tãÎ)S|­§è.é"‚n®P@€™XˆZı=`;İ(TĞÓÇ^Ø6™2,`›…9Ü¨ŞÉ^òM<=5¾Òhé"ğ>)ÄÕ´ÓLÇdù>‹”©^ÙÁ‘b²D÷Ï¤Íc7é—Úw£Y5¡-Íæ¡lJ :ˆàHOxnE5Ñ.AR#scE-+ffõâge¡‘w'Å0$.átF)ææÎ²‚yí‘3V>Ó­‘HËo[dÔe€³Oi=.%D	µh·¿½b7¿'†FÛ¸Y[K3¤ùG^*ÈÑ%Asú.Ë«œì&e_ÜN'ë·^«ĞÀ[Û&,yÚæöğñ*D‰b[Ø±Ş/Ïß8È•=,ÉRWJ3?ò¿fiõäW;œYWOÏ(‡¦Tíô.W8‹ıf«óM	Ñô™\æ®ÎÅÙ,[ê¨eSî-˜=ìÆº¡âZ‹†”YZ4rqÌò€Áéït¤ŒKŒ-€àR*À¬èQ‘½áíl«­‹A<—·pëxêÀqß÷‡¾2¢$wı¡(
…mjL¢­·…Y8ŸD×ÒÃˆ?¡»Kã|ß†óøşYyÍá©©?—utILô	T—İ‚.BøşIõà)r³Ö?Î§“ÒÅzÌ%TíÊuÃÖ ‡¸2Ìâ‘óÈ?ÚÆñÒYJ@“cXú!^õÁî.¬'÷kød2›¶×sA+¬½A¡7“¯—9-µc(Ô‰-ml'ÌôÏÒ‹#ügì¤må¨Éıyjî»ÉóÅ*³Xw¸>Š1„ôGn:ğå¼HBZyvõ6“¬$½6°›£˜×,ÅyÃ§”^J 6„Ü»>†ˆX¾EjÕÀİ8şCbòyc > ˆÈM°úâi6K{Ê³æˆ4·gš%Œéú÷2ot&z'ê{‘"QÃN^Û•‘$kVšöXr$g$†¹zïK–xÈtGXşhWŞ¢‚J{Ëxı)zÖ+¨!´Kúû7À©2´æ‹ò…‰ŠR$»¢ŞaÊZâşá#Q“ò¹{‘4Aõ\ê¨¨ñ¶ñ­•P›Ú€k²Q5SáğÉï}’ëfk¸ùìíÑëÕè‹Eôui]JVş'‡=‚ää”ü°b£ƒûgC¶Räqe•¹ Cøi³±’T„OÕ+±¢’ı‚XÙ†¦>Ú|¦ıÔ„ôb4ÁYÈÙy’>›…á¿›ñõÿJ¬ë­Ûù.“Â- ~Xìø=qå"43µ@`z¹-‹<k¹ª!Šw›1R’y;ª"*UÈéB6[ã³(°)PJíK¸;Z¢ïŠEÑC´¯*<Oü#¹f@œ=à Ì“MÏ‡¸ŞôMúëq¶o¡p[”2U´ó¸Ëswoˆ sQùëZeàÃ¹>C!bZR]†€ÑâÆı‘¤Y˜ïcÖ7¼ó7³…WŠ|æ‡7aã3YOÙ”¡IjÇù4tbI–ã93
‡.	çé­u³?€îİk£”çü).üÛ8HNœ×uì±ÜpèÊòK/_ßÚ¤0—"«›=	LhÚU )?`Ø°êƒ!È¼Ó<3_ÑKÓ¨!"eæûøQeÙsKAÌóOŞ¶â`Yjÿ¯«ï¶sìæY¹„Ò,(6(âÃºÉÖ³½'ñ9úîZGØZÛO»h#`[Sly¶BæøºŸºß`g"JfÙÿğÒ®3ºÆÂ>„y&ExÉ[úÀ^d’(Íc‡†_Ë<›ƒÍÑgºw©híjZÔc²ÌU«„üìüL½{èÖ·G£oˆ{ÚLğ`ÚÍÛœ0Æ4_…ÆØÚ¬òghêû§Šxg½]¥}‚ÖµM
=“y“´·p+â
pÎ…‡"E;61^ºùljù-;Ñ)n¡ó”Ş’{¬	Kì/wF¾”õö>3êoÀYø'@¢Å­EàU·ılê<8–T…VQlB2†y7f5`†šûIC”æÒ£-Š©åë2õîF¦F£œJªïnzñ2³/ÙĞ   ô/˜pÉ –¶€À?âú›±Ägû    YZ