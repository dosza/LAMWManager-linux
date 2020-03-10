#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4044761954"
MD5="27a1a0ca64cc112a9fce964dc38bba98"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20816"
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
	echo Date of packaging: Tue Mar 10 03:23:15 -03 2020
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
ı7zXZ  æÖ´F !   ÏXÌáÿQ] ¼}•ÀJFœÄÿ.»á_j©éŞä>ZU¬ââsúî¹Äıä— «¦…¬•D§¨|¯œÂ¡Ê'§’ù¹Ì¯hÒ”“È×‡W® ¯M®[;yË1hÆ]çyx›‘‰j÷òŠQ˜3–‡è‰(ãg
dÇHvÚ—‡ÛMEn<kßûV,gŸ«ê|‚@*¼C»Vˆ#›‰;Ã{Ì'D¯CÅõ‰¦Ù;'üék;<1ƒ]å¾Š\²ÓÊ›Rİ“›Ê¹ ÿâ$Ær§™}Pmö“=vTu}7 ¿¨›‰¤oe^¹õ—×İÀ³´ø®
"`8§[ŞS.r\Ä¶Ül cbÉü*} +ì8û¦~-9ÈueõƒtxK¼°ÖÛ‹6ÈÉñã9(jœØ³&oíûCx/òã0‹œîy½ÙœEvöoÓ}÷ôTH€Û¨ÖšëbXˆËGü{qŠ®hàÔoz’Ú¸üßë’œ 1CAãÏÌ½ Ëª)İ°yØËğŠ¿Mªoò‘–26b9ÕMz
Ê£%FA¦–™€B?K}ÂtÜå<D¨~òÏ‰\)A¡Ş…)Ù›È¯f›FXYäkÕD]áWˆb‘ÁRIØ®;¢ÜÆ.¹Ùûc²@5H—İHae3+4Pä"FYÅq ªbğJÑL‚»™™E­A; N±v¶¹¡dÙ”GZÀ}2•o6~c±˜‰Ö–ÜÕæ2Ş¢ÀR˜·l6Š(èj&{•Yîpkk©cg‡1¶ñª)(PÏ"í¯x†C šX§OPXâ\â	Cÿ?¹½¹ª¼Æcp‹»èÃ
·ÁjˆG²=ƒqÜŸ˜~r¯ª££X{Mß,#2½¡ñ\å&W“çÖ%èäÃïHÙ¦—ğa$½oL…®#İ†ffk #õè›4B`Í] ¹®9w#üå4”W? d½pT}È^†Î/#çNÑ@ÂådŠ´Ğç{_rç^
|”4‡oø¹€¥óÓ'›ğ+.Ûr#ì”óæçkÎzEI‘9>,ÂQ4§ş§³ÖHıEú“4ªFGmUV¼áöØXí„îyÛßtWùH]Úeôpy5šf#Ş ÕCD	Eÿœy¿“¤)B‹ÒŞ†Á€ªOÑr±2ßç©T™#O7Qun\’bd‡îL¦œ†Êİ“~ßB²²cw§¹vN½í¦húG¸¾`ªFy¥%õ×ÉAX™i?ÿÃù-ò”’7bAY–µ&µuÄ´ozW¯…pşP;éƒëıø"ÖüwdØÔ¯Z-‹â/›gh:TfÊXg»MI/o«0ã¾VÏõ‘¬òÎ¹ßñ±ì.7r7¡“Ğ9ÉPåªµ•v„¾ó ÚÅú}+`lJÀ¸Å(.TT^Òó(_´Ó8oãU
„>‹‡ ‡[ãfa`ŒU| )Wàp¹ìçc5Æÿ]Âì¥˜(!Çº5!Oyî½€ÿºJ+ Íul+.úg®÷£UÌvé™×1YËºÉø·”#‡Wt¥˜µù``úÑx.ÎÏÁíûõÒi#d,I±šÂƒ¯ƒy—R£öÌ¥K¨a£ha–Ù\I^7ñâø!RõağÕıÕ]ãÃ(gœ¬ìEª8ÎDŒ(eÆÓNìgL<ò ¥Š×ÅœÃ´jIFÇ/$’5%fë»3@Ÿ.k · Õùnú¦Év5ÿt+‘KÌã?K1Y*ùä­5tr³oêØî7ÇZ—L9Œ÷wó¼õ9£z< @<ûjd;[2ãüOåjSo´EƒÀ×PõJË5<V«¾pC¯Æ‘Xúñ¦z|4/UWR¸¬b}¾Õwì„•¥E9lĞ+.^\{LxZêf2|S¶[ŠX‚1fŒJ>i¸â&\(A™Ä@İÔPMFÿTê~s†X‹RvV	®oièî8À4¹—OßÇEvÕkQK¥ä@¿hT•“ò•Ù“9ÌÒ)÷TÖ¯`²¦±,«İÙ| $¿â‰œ'£#tÒgHq¾İõ'¶8_oíö%"Ö;³]GBaÇtĞ7íRÄ2EÒ¢x‘¼ª”«şÃ)ÿxEßD0¼×Ì³°qô’ü¨w„#AŠ“Ş!‹—UÜ±ŒÒRsÅŠô4*ŸÜĞÍ]Àaÿwíoârâ:×,íË¶–í,‚2‘&dõûG½+óØ["wÌÁèÙWlıß¤Ò-A«ø	cwå‚ˆ3#IŞƒÌ–ä½çÛ}œœèµ@BXö0¼G™%jö|;ÁÀª[P÷2ù¢€D>ë¦Û¯5ß´Ø@‡tÖ²Ş39'nùçŠÒ×Ï‹«A‰®±°ÓÂú—æôfl¡İdl§Œ²%@Ç9œ‰W|j]V 	V†[ë¾Bmc‘ŸƒÍ«U¹š—Á*/í&S?ÓƒBÓ¯Væ7DğıHóé´u.w÷lW5Ü’¡ï"tBcAqjƒw;cÓ×ßĞi$µñf7²|^KŒõSÓ¸õÆbÅ·kë%ìÉ	H — T:@ ?)8ÎËÚï»+%?R:ŞMÃãë Oú/°ª!€«†€éş?âoŞ€‰¶Ÿ’Û’¥xRåê“!|t Ih?T}+Íù5ô‰°ŸBpòXªñ¯´4öæ÷Öª$éQZˆœ2+ k»B^^
¥½3­OMO÷ò|’7ˆ*’Z^ğ(˜ÄNÔpßQ«æºŠ·ŒÈ@Ö
“çi°CëiÂÜúSjñ¤CÖ#<ÛUç¾š/4YŠR ¸0ó¿úZ™Ò£·…Y*/Ëêç˜j±ÀõS½Iß‚Š»0œâóP%šüÊaªgßƒã–œÌ©`¥ÔD.Ë;˜b®…šà•©ôÂyêËÙ˜ê¡ó¡rÆşx×£®ÚËæ4À ÖQŸ-í(Xñqh= ¸ğâ†÷›‚äûc”˜Ü3ï ÄCœTï’İAŠ¡¹6Ê|âWPl¤F#séVÌ´ïB'ì«òB0ÿ‘G¢"buŸÀùÂ!E[:c^{ªá¸¹oİ)hHnÓüFÔ7,00áo´ÕĞ[Ôqn©;°(äÄ`CDú]l3	ø¶ó9ç,Àì]ME„»ûç.ç˜jÂ$ÖŞçX„M»2$BR±kÙ Ò/]©ê†ÑîLõ–a:cÂ}VÚñ3­Ÿ˜(à÷¸qÄÕ%£ş¡²¸ê~¡])š1ğ ¯ö¤=íß£§¿Œ†@ÆwÁYX1kT5) G¶W–ö€+NB´ d	P.vòôPL–ƒ)e ÕìõV¼núö:]u"½ršœÿ2J…uqÎ¤êYıÕÈİ!öœ¶÷éxé¹9üm9bò2‚¡Âw3¹²·µæ3¤à„œaSş0şËöŸSÅñÏ#7åîp².Ï€ñA™j~òM¬¥¬^ÄoüúÓ-U±%‡#ÃG4Á0A8T·_6cOícì¸Ñ-*F¶ÅúÜÆ•ü°G€`Ü±&œî¨2“ĞÀ	ï`gøõÓèè£pOniW$W‡Ë4#¾ ô¥"j8yì¤Î<3£·ñKÃ"TcªôT`I+Ía6ëë#ÿoó§€~IœŞGŠšòÑç;˜pS_³Á’Ç½Œ,?’?Hµ š¼ØšE’aíPÎü>EŸS«A¸¨òëuYV¼ùğ1Ñ¿­æo®5Êè7SW\L“6Ìô: Áj¹âÚ„VL?ooÂ¢ÂV–üŒWLF‡y*ü¢ñ‡ŒÖ.ÙZÕ§LlÓÙÊİe¦ÆF1¡qìá·ã·rŒBï¬ú~åÚ°%RÂ·ıu×Ü¬ğš3 ş$1Fs:@3İ âOTı: S/hr’cl½8û7ØùÇ–Ô+ÀpĞXÛ.á¦êÚJÊŒN&|	æÿ#?Ã<T²e¢+²´a]šüfúÌ/¯ùU5Ì¦bMª'Qî“ıª=–Âg°— Ì£í—Ü>ê œyu¯#/éÍŸ–½°JxoQİ–y ÊDşFŠÎi«àšÌ'‰.eÑ,ö½ †ª€™Óßìòş5!57”yÄoFªtòq´&—k4¸+KâtÉ-RÊ5I[â{\ĞbûÎÖ8db œÿ¾ŠÙ Ùd<¬Øq&·MüŸoIP,RÛ¼•í\ÇÓÏ'ôn5‚âÛHÆÇO€J#İ¡RĞ\XUW-^á%—Ğµb‰¢ğÎ•M%½5=ÛÑ…V¢Y{˜Ã¬Š	Lé?—:$õçÒCê@æM:E^ô7wi±ğ®%ˆ:e%>±j1#&,)6%Q^®ˆG¹k“…y€¡á–+ü7V±cÁx0”*ô˜MıÉNA!İGd¹~l§MİÇÊ•³9°Ğ®‘‡ŠBX$»©c<*9a01ƒÍHşàYŒgÓ1<ŸÌËëëµ2‘ğL±X–ÊÉ!àéldTä…›¥ç­ëßmÁSæ½)Ú¡¼ª'pörpk1ï)Ù.&5w¦J¯™ïc‚V¨i¡¨Ê¾d{Jë²;[ó¬~}Èã èÿ¡æ˜)@›ÆüI	ñkºF÷Ç¸%˜w‡Ä}Œ„Stêä—’+y@+ëï±¯$ğšŠË+"ä):dínı:§,Ë¬œZœ^úŸg[5
„…É'0~ ¯0O¼K‰×pjºg?¥‹‘dğ1_<J*OV÷ŸDA\úèuP*,¡°fZ´(ü Øi©áoeÑ§Ò=ôwÄ·)Q¾x· F[æ©Â&[ú½9îmÃ£CÏÔ(šÀb™ÿ8Ûígô*/_Eìİ·ñ9ø`ÇúLE„­Rz}å4^,<¶‡¢ÒP4ªK¿Q†³IÇ1-¸ #Gö…î}	M²…ÑŠk`ÁëÈ?ıZ!q˜’Ô ¹‡z	Ú}ë¾è\qOk’®Ó`ûfpáÛ@6c.$ÖT‘áN­ÌÒ¸@	zS{°—D}©Èş3›Qêè`à¾šFÆãôj,°#^¤u"¨ã"ÆvÍV< –q÷Ï‘I!.âÂÉw!‰±TÇ•½Á-³öã—„UKÀ¥ ·®Õæ}Æ6ÕtõŒ	^A;Abíïú÷ÆÊÍ-°${ÖY¼?Hbi†à·Š×'P¯kx‚@<Êi$6„®ş Ó}í^%•VÄËÉøÁ+>GÀˆ*›ÅÄîmB­pÈ°íÃ¢e Ê{ÔAY`Füùî·ŒÕ"İÚ­‡ßÕ@>AeÊæ8¿ÏÕ§”+ ^Qc|ß»-/ô04o·–ß\§á÷4cÌ/¡Aš9 Ì“Ì‚úïúæ¸ù>b™W¬€TÓ—„`°¶¶ ¾‡.ß³/&’O‡(ûy+½$·Áéş1â®^u×`ƒºYe©N'G?C‡Jß;°
q£šÊk]ı:ü)Ïg»Q¿m™‚;UDšùI‚¢/|éøkßiRˆW©İÖ0¨S9È«¢²;î¸:¯†”¬Z³wÚz¥€mÓ×T×)(„O9raZ3R´lìI_Ö‚`^U~6‚Ö(~Ì±
Şƒœ…:\ ®ãrXj‹CæöëµBQŞ¿¡ÏÅºˆà
èÕHê0W—#Rœì ¬ÃHØ\¸ØÆºÈeısß£ù!êdã+A*;Ócœi"CE®¹ò©ÉÔ|_¾‰‘Í-AÎzûÆ}ãLmWv.†U{¦R"’}¦·Ÿ=ÚÈqº&³2KFV¹»Z¥ú³+1uƒ’Kğ±SĞƒ`üß€Œ6
’ÈiÕÛ¨í÷nŞå˜Û±ÍÌ=Ê }Ú[J"ââû²÷9uºÅ²A:øwpaÃ&NZV¶4Ï…€7\„•ù'û*?øø4ò$p0©vô	ó­#`yñ÷–Ÿô)¸Ÿr¹š*—`
œQ_u5TİFBDŞD;Mç¬_túó{Hò0Ú&m²™Ï¡PYğƒÃ¥?ÙÁäÏ\¬~òT»,—4×W¥<fÙ±˜¤‹åK<X24‘…M››.“Ÿóç²Ù»â
ü…]ç__!+Y]´q&`€4q“Åö%xvÂümpöp}!d¤£Ùå¥‚½½Öa4‚Ö6~Q3DXœØ(>ÔPì‡ow^ò/Ô¦¨;ì„$ûœ`J“]§ä™ûBªàÄgÊQ„æÛ,]Ü*Ä˜P‚ng–+Oqúc±)HÌ2¡eú°ø x'æˆøÌ/NiW!µB;|XÃb¦ÀÊ”[¨ÎÔãê'”ıÑ¨ê‘ºWj3Ù¡_?¸¢ÿ’ 2¡qòÏĞË§R×h¼­Éù:Œ¯Ó:®œ_(¹_i?·Íg–ñ`L4•44K[ü l.ğLÒ¦:UÚ"M‰È~ñ¤}…5@¦(=>í¬z_D¢7Æ˜¬}ô|*øs!'Ñ“¤®ím"_!ˆ=ÒÀ ÒLº¾fÓı7æy]Ïëñ]nïÇm…”&ïü-¸ˆKıÄ²‡›>Ù@¸j€e‚—/½¥9y…ğªn¢-IšÌmmøY˜.ƒ“1—#šOÇ2ï¯î6ğ{×Óª/CËB´Ô«ûâ‰e^3[JÛ¶æ5!X–“
ğ&eòû&]8é?rŞBòàÎÌ’¸_¦;É£¯¯`…?9ô/íSCœšµ“T/6¶°“k‹\£àÚCK-bİÛ‚VÀlkNwTwTUĞòTh5|RØY«"@b¨E'DI2ÍNôI«2¾ÕşÕğRsÅÂó.GİÎ‚´–›Û;#ßß×Öõıw±·OpïwyÍàå	öxx²”¯èíÆ$/UÉÇÚßn¸€›[<êˆšW_ŠÍ
gT¥c®€Øë«ê)‡ovbŸò1û :gDåÇ!<z…ˆ8úêåÃ^˜Ş¤~œuM¬ğ,ïóD? Ø/Öo÷k‹ô x„Šë[‚?F)Ç"2WfşSºÍÿ«™¬ğ÷Y!1s3B)AyfL’RbÊõ¾™é>ˆ¡N¦¼Ğ:÷"ñoókÄğá¿j¬PMëQTnˆ[¸"¸Êü/!nDÑŸ·äº¨8F/U-‡òy•]YZgî`lA·n¹	ë¸ìógì–'/tï-m Ã{¶òÇoÚT÷ËÉ6Æˆì5àJà tm¤	>¡•ıÑyV–>øÚÈïÍ¢¢Â„:ï÷ªÇ¶Uëœ2oø¢éÉ´9éæ_“^T­SvŠßÎ?!ªT …qF†yàG}x›Šãê­!@é1ıßÙSÜ§ğó}ï*óŸ5àiƒá@’}Ü=I„ï$*~{ÃÂh^Ey]÷†¿Xcb-B9s3D²û—|ÎIuÖE¬èów|ãº&€e5°ÅloÌ6©üğóæ_ÊwêÌà¿Ã®™2e›F"µph*,–k[Õì~ßı°è§cOq©¡VÒ±ÂÛ&>9Q|I—'_Ï·ĞVÍÛN3Õ&yä	ò¥ª¬ã/˜b@ûĞ~…ßŒ›~fÅÉ8„œê¡ÅÍöw»k’»3g+Ãd÷H'‘å»cuö¥™$8"»FA[sïåX•Å)Ñ3ô¼W\B&Ë7`Æ¼=º;la?µ1q;6 “ùJLökÌ:y[šUƒz¶!B¡Ò3çç¡œ~ÕŞÙUxÀ­eº8ëÕKã¾‘ÃÆ[SVÂ!Œ|hœ™×‡/R˜qóã·¸YÉK×{•šY£–ÌÒËr…øèoˆû¦ÎAêË’ËÖùì‚QxjXÈ ¡3T)¸è_šùuª<İ²bé§Ê‘2qş»Y¼ˆw‰ÂQôÊìE ´m¨gêfÕ;	î‰£4lÉ
’€({ÙkJÒ]ï³-¯0Nó5U&z¯Hw:®«óz,%µW­b–#şhô.ûI‰³-P@
Å£ù4c­Em’9ÏC¹_VŞ*¹Œğ¦¹şò‰‰îú¶›fa¨âF€y Ò¤vbAİ¯Í®;Hg4ø)óƒg34RÅL¬àe¸İŸBÓvzBf5¤Öˆ"ö_ì`cü{îbÒIÁhÙ Nü# ô˜'= Mï‰?«¹¼•µË}—1˜¥¼PO–ó=…kM9b<z`×_H•ª3w"UK¬&
ÈzÙ`ÃÕ®•WRDÀ@Ì}í,ùË=®²)CÖ]µˆ·ÿlÃšÖS‘ºèjéP:	©¤(©wÑÑJJ¥œ)ıáğÿ?Ç~sæW–†Šµ€}Ğ>¹#i™d‹¬çò³V›œ/‘$íà):Ğª$R‰JŒj1"è0ù+]¸¿U`§§eTòÄ(¯ĞàKÁÈu÷:4•ÄC¶sÒŒÆòõìlãqNà ‰£JoÆQÌÁı@ÀWÅŠêÀ¿ºß7D¨8¬ì/½Š´P4ˆ¹@ıZc«s¢ú¶ f›wq]‘ú*5`ƒ‰¶×Åµ­ræïVY“ü8V}‘·•ÍVj‘é‡>ÊÑ’ ıaô"¬úcÇy6ñÿÄ*ïÂZW¨JkÿË?#ì+20î>~¹Y¡0ßåo5YñšíüöŒ•º *QÀ÷¯†x}{oC.©s µæÛ?Æ¼ÃŠıû-“ú!ÙJ)•"X >É¬3<]òóâã´•y/İ1.>÷†åäwãÏyP"“¿|ÔÂÂ~Ş‹kU½D×§ÃÓÊè+1ïzÉÔ—W±2”6õr­3’ä`¹‚òØ'Ş»q\ëÅèşeİÙà'+…ª*#'.}€\ RÕ†TWâ¾NÅs¸(<?púŸj™•3YoÆÒy©çi÷‹TÑèĞHGDß…¥Ú†Qğùjcõ­‰Veú»PÖ5£dQ
W…_üĞçñ¤¸[äÿU§A#%MÒæJ>r\VÊd-Ï¹#§z'	Œ@UÌ&¡q¼¢èJ,r…Õ
E”TÛõqÔ0®!“˜
µÉÕ;­äŸ¦J/PÄB³/~xá‘t	ì‘FO>åè|†`ßÛ7¥ÅÃ‚f)eóeœ_µNåÅÿ½{KYz®pÇ{ÏYC4ÃBîôşJ!ì¾ ¯Xë(JÆzÀ9·w„mÅ’ÛdVTf•øÎ7ZÛŞ7‘Œ’ç”ş©ß(åWÖZ¬Z5»Ö¸(,õ ­4’;ÏŠ w³àÊ·<aöYÛáÖãö5ÃıÓê¢øOáiİPmÔRUmÀÓ¶VxA]Õü	»q½½ª¯•{çç¹­Î|5)hëĞ³A¤2B«àÀù†Ô&Àå6Ş§ƒóO¹`–ÛI1;¿_çw(@p@‰Ü¾Ÿ©µZ8ªÇƒ[>†AM‘Ä£Q!uÜÂ }7*"\!t¸-R9F°–Åºv’Nfh•ŒcÄ+Ö¶s–·åé¬ ‹{¢õ{\rÜær#8ù´ú@9Ú¼{u±=²Ïâ³ú"dÙ®3¢Z¼dùÁ‘WÊé\7>°Eş¶A(ğh¨,}Y0Q÷<èz‘`î
r+‰%-øf ?\íKwš%$œ—ŒÑ·Û¨üÚ#Ò¯D†¨Ù£ª]­ïŠg;ö©QÒ:x‹é:¶ÙL­g_ŒÆaèMÿ pjË ˆ®1¼‰‹øjı‹çØâŸÃV6´­åìŸşìå‡ÓÔ,áKü¿Ò`TáÈ ZóÒÈße-p@ÚPˆc|‰bT–_£%!rÅøı¿¾¤ZğñÑc¡ĞBÄWğDkÁôç½"C’É„¦
<sÃæ‹ilÌø­¦ÈKë9ó ÔC¤·¬¤š+sÍcA€RËñµ
‰òï\•ÊKN(İÖpØ¢İ ÊÑllË~} ç¬I•BÅ>ìk¤ê¥ğ¸Ü¬^»Ë)^)Fµ;oâ~z-ä¼ùVå¼¿âÙèZO‡ïz&ˆÓÆgeRû>‚R}?©•[Ô>6¶L´Lå/ KÒ2ö£n„àÈÄ›ÿt?2¬Ì»
é·Ò
'?ÿ¸@bloR/Jæ+×ƒF?/NË>$äL9\º‹ÖĞ4S"áKz
³ø ‰G ydÃ=IohLÆí§ãœ ‚’„Õ(ø¥tƒŞC)Mšî¾Ã241	M²Î~#Ó#ªÙ§DˆD'îğ#QØ©HÊîQÉ{¢h1îTyâÁ¾ ª!ø-$¸%CÎ¸ËîªÎ4,Ş´ğ•Sk”‹B‘©:O©È¿f£†v¥ŒÛöwµÌN{v‹aúàŠüŞšyÜJˆêmß=4iæ<
®¾ú(–Í/¦{y_&»,§³¬~Øşü‚o'ÉRyt¡ñİ+@¯‚Ñº°3…äîm[»œ°sq;3¹Ïê‘cŠùz{!+WÙzş ¬E/—ÕÁ1^ÃÊÕs}ˆù’€>OÔQ¥)±DŞGw"«j)¢/®º{M%d#D¶M¸^iÓ~½fq.‹b4‚ójz{‘ıãQÉàŒ¡CÔgÿÆXğ")ó,ğAÙ%u%ıpJ‚U5}]Gå(İÅ€\ÓÇ½ÛqÙöº°Kp¥;w¦³‘r|šGi~"¨8ßrï õö¡!ÅE¨×Ğ”SÏş­æ`ñ0Bn^¹6^+‹:
/ø%;Óª#NÇ¾ÓŠ5äfm7â´û·‘3Ÿ@~ÿ½„â(Ct}R‘ƒºÄ¯‰_Š:%`×‚ğ}øbÃ(”.Cuì`gj²‡°g'hY›}†}·Ä=N†gî©§î„ŸÜ/è¢bé7Z×Ù-‹È¼Wš aÌ½HÜn†ß]&šËÛ—j´›²{m3QãĞµ@T•<÷í‚s"ò\f¸?$šê-œ¼ß5Ñé®í4õ#ë^%’İÁBåÃûFG¶-A B7ºÀ’•äïÀÄ¥Ò*"¿ÿ­Ãå1å×ÖRQ`eñ|zSq û×Ñ•ÁÇŞ`£“/Âö¬Ñuif–í:ÿd®(›øÓ¦‡J¢¯°oš¡Éô¸ÜÛq©´"¢Ü÷X£Æğ®$ <g8œ6²ÅĞÖn~‹¥“?aÌ†Ùü¸¢*’@'R¶2{xÑ„6|²­‚£M£ÒÛlp8yß´éU2]uÛ!NtáŒş)E»b¥¡^Òkx+Xãã5]´³,*á!ëg9éÇPĞ÷·ıÊTÈÆ9Z™/Ì]|
¦•‹ë\Ùé©bw x¢åt)óÆãùæ†d‚@Ù¾·hªO!´¸>’”XËë¸Ò yK3ÎÒk,ımTÍæDH¤Tñcú’Dõ¯ÖÖt[È`×ƒjåûCVg²Á²J}ÿÌ§¨¾c·ĞÜ?dCÏñ~/@œÓ™ü´&>9tüÌ¿,|§
Ç¡•÷¶ŸĞÓñÈŸrkö¿Ğ…F¿±Óú:‡aÎÎAC‹òSçw¬d¦ÏëC“lÔw]n‹9JE(umi‚Ô=…1f½zÉ«õ†|8ê.Ë*f˜2‚1ŞËc"d}]•‚•úÜ¢—7D$©ø²‘si“-‹N™$1Tq°s	¡áòFEöA»¡‹R¡Šò©Z0+Ñ²«—Œm¿ò»×VÆm¯"²`4CÍÒÉæN!Z Eó;1¦ÑşÌáú,w.S?ÛXÌø_q}p
ıi0ÑšlÕ
ªš€Æğ[¢¦û;x$¥rÓ¢”v,@]&cu<T†ü©èôÓ§œ‡jbq­›}iÓ2KF-|oÆ	¨ßŸ;Q¨uö%8ú»ş@n¨(©^pE¸½û]UŒùåÜÇWİ4­jÁ@p8ôÕ\‚Ÿ­Bôü¾ô>b@£WŠò†BûİÕ~PšêæôrÒôÓ8¾ØĞ&M/u[o²‘VÍjoM\rht‘¤‚ê¾óµ$FI%”X!¯lçŒˆˆuŒ1›±¿=íèüÓãşTKçã]è j$¶É÷&rã	œÁßÛëúÃìÓ€F³ŒPş©UÖùNï<u#@nôì"jPjuÛ^>Ù¿03;S›T\İG×=Ë´¤&”éÊô&Ø>Ëø´‰Ì 3*Y³sƒÈ]>%¬îó69î 5X»£Ày›²U:êM•ZjQÁ¾w a^tÊ÷rß-¢–²ƒ¦RsÂ&ùâÅäûÜX+q7Kh6–ãx ôxTíŒrçµ!øåÍûT¥İ5[ğö”ô<ÿ}šoõä9`N`ãv’?y=İ¨Üà­Ìôñ¿Ëö‡ÖjÅú!q˜]BÁûHË]&€º°ÎåÓÛk¦¹òÿˆòM×o!.ş¾‘MUÇÛÓì0qˆèwb@¥T<œù6	*ò7…<N¹¸@uŠ
áªÒ;FÖ+×Š(=
¡Î‚ãHùÚ¹)Í¬ëY{Ègm¿ylÿ9Ó~ä?ŒÀÔ É‹¬]§«·uAˆ¦ßUĞĞ™%ûlKìe±¦à8!}eÂn}„É0	OŸñ¢¾PÕ„8J¯·8!cÁ¾+ƒŸQá†]¶sDèï2%!J¦Î0öpßàgrfuğøBûîã7sÑ„Hfl×dzØ!U`­ú«6ú2ğ<NËíê+/lúôÚÁáÿ—Kî…ß~jó¾ÌZÍˆ‰¡I–ıÃ¶t˜i‚ñ*¨;oõ&tn@e…ÉgÇz
½Àgà?M?«Ÿš˜|À:ï'½Ï3hÆğb<°k9b|&Va[nšfîdUØæÙ(ÊÎ”#ªï3U›¨~EŠMâ^­Õ–„(¿D$Ü	UüöòıËÚÔçÏSF¦U&üºOÓ€¿vùu¯|sAHÜd##¸ªrL%ì
5ğÏ³“Ö¨'15ùŞÌŸ§0Ó} S§+d+²vg¢£šSY„Ş|[#¨€‡»A»(Ñ“°;êåy¸’²SÄ|°Ú"€ãÑ•.~¡­ïP‘»ûÎª’ŠkE'È‰%j(d‹aWÉñËµºôÛUùÍ²Q¨tMñqêâ€qeû"›â¤Ë:Z¶ˆ%[Ìr«Çê[ç]Bğ<Õ“°1/¦*jÖ!AA~%Ûß>~X¼§É'†»õàìÄ³Ü’-TÛL7z2IÅëa7ˆç Z¥Hû’…4èÅ˜>ç1ü¶È‡Á	ÍŒ—I’“‘÷ëòA¯7B””” ’ÂòL*Ğ/)Š6)ª#Æ:ğÜÄ/¶$à\¯ÁA2 ZäïCè§VŸ‘Ã<™XÃvÑÊ‹™ıšrò«ÁŒ€p*l:Ì%ß7IºçcyNJÄcÍ*¡†Qõöéc:B¤ RÏGDOM’Wÿ>Öß9O²›•õEŠşeÙÓ¿ÑµŞèô›ò¹èk£o81Å}A¦Q*Y‰òM!AYÙ& ÉÁÆìÓÓ2ëPJp[§Ì¾±Ì¶<±e‡i¤lo‚u™Iwïb¶¾ù–“@£p—Î7]˜À/í}øË˜óÀ›n}¯H²`G\¼"‘ÈU–´€HŸ
,ß<K@›ú&È/aÓkC{æí¹³s5¾Å“¨ÂúG2ˆâac‹æÁç6èÍ³}²¨xRNÆüÊÓ¾IK˜íÍRãF÷2m˜§iBõwHÿõÁœ’%€‰â[ò.Iy^-HüŞ¿RÇuApNW>°'#ûã/êáır3!Hã=›c.ÍRÊ…Æ¹ù	êèÈ¡²¦in±É. 6N C){Ú’nüR	£hÑ>ÒìEŞê©WÊåßlïaÄY1Lšáô¯2È"?"æÊ0½î.}ÚB›ª=B5JT…-¾;–pH Â*€yşhxW­vY: «	[ Å²¯â‡Ò´8\¥VØü¾Sî¾Ï=“µƒw‘ï™AĞNd¦j£ƒÏ@¨Ò^zšìòõuá4S×$/%¥T­{†³^gPçäMŠk‘ªÅ'2’âÖ+bÕÚª,Å%÷÷Neå™{·šï¸©hÕÊS½Ü`İà¨E™‰zö%qp
”ÓSÅƒãëz‚kyòh÷…G€¹—öÏâ÷nüP²úâå8‚tZwğA~$Ã¨èp½ï³®ÙÀ¨^eîF0›ˆFª}yózŠd³Yîº†ÊTT Ò€I¡V"Ä¨°B¶í1!/åmÎ»¸•øğ¼Ú-‹-8ºˆ÷OdO½jk0°¯ÿ_•E¯/o[é¡H±4±K$w£šëÇ²‘ööè<€3ÍsP(Şâ7$nàŞ†}Ñ.Pÿ*D4^â8p¸Ñ˜ñ¹‰”TCèNhC´@bÌâDİÎÉÅ9ş»Xº·¸å}}o	å@7R·æ;‡^aâ@•/Õ¡b|¶ŒlDÏŒ2—]¢ ™;ˆBÍ[ßÁÙ:@G¥Z£z«l})1édëéúcÑÃóÒ#œ`:ajÿìfGRawãYÌ»ı­gSš=âÓTs6=3-jjP¡&?jäÖ¤Áùî8ñQ¨øª_HÒlÇ+Ó©"“E6Õ4ı²HŞ‘æ$"ï=|*`q7ÅÆØôäUø”‹Ïç¨L(î?ê»ÆŞÆ( `¡A±mÙ‚7Éã>“ò™EªÔŞ¬Wé°jˆ˜ t²¾P¢úG‹Âw5Â@ÿ¬knÄÊû'l"c„±¨üÁ·ºY;Hıız5º3+èS}7±£p³£‘¨ÉÛ¢pe5&îØ^˜‘Õ`Ş"œtaØó"RYÒÈºr'âtè)Ë^ÈBÍærĞN‚”!i}ğĞlk¹Ü;˜ËyqÜdšŞÓÔæ.ï'ój6@DJú+˜Ñ¯äUfP%iS?ÇÔº»Öœ)Q•ÎÅ=iÔòp1ª“Ò°s”l£y<8³‡Re>± Fvj43ÌûÃÀ^ÑÑ¦µPåáç']|­uÀ Q—¿e¬ÏF@*–Iömm|NÏ<õø‘F/÷½9x5‰ä3£—	áXQ£ßX8.õ&æÀŞûoY‰OÖ‰ÉİgIõ¥¶!m
½´ÓÈ“PãUF››^„Ô¨ÿŒÊd(ÉEõêX‹­®<–ˆ@‚Ø˜¾…©š5÷´QŸxPş5/¢´a¨¨>µ¢9h6¥ÚíyÃ(›?ùTù×–äl˜õªï<NAâ#“–F§«ÌÄ»ìönğTà#;‰¦5IÇÍašƒŞ;_;<ñf\¬"«
ç R×ğÇ@<8úÌWy–Ôª…AJJ¿È´„’˜ NS¥5	¢üÖUŸÿê>Pÿ¯S{1ÍÇˆ~oaĞ'jÒ`÷‘ËàÜ#¦³µ$›T¯]àT„¯å2Xø+áØióÑş·`=]t<şU‚¶ü=%³“˜D¶ı3YY»İ¬™ºxÏÃ”ÌÕ£€Ÿ”ŒÂ‹óŠ"gú‡Zä	œŒ†ŞP‡wKÖ0±¶ó=äz`-—W$â;+
d— ~“îæm¡i …”‰.¾ÆÓk„vÙ?çjDz$Në± Ş$„¤BæQôp§·X4»
@F‘şqs®È:e³`ú#YÓ­kD^Üù‹¾’³şn|Vp<´ş9;*¹øG?g~9t ¤5zBøŒ}aÖÑ‰&¹˜ØmƒiÒÅd$ø#âhhÑóªæÅ+ıadæ¼Êó+Â9¡d’%o-ğ}.J•û†l@r‚§‚;ˆGËv°pÀ#]í¿/Ç$ßÛççI}õÕöhK H` ¸ŠÕ)^’¾GfE8_Ó¯çÖK®[g„ÑÒ¢-¨
d*Úb.3~]˜eÀ£L·ı5w?ndJ{;@f™4Ì¡±3|=—ña4_H ]à†„‘ĞGx‘“ÆŸ4~ég(¡{ä}`@Ò …k=’Àãct;Á³ÏÃYídŞ§gBWálè²Æ<¼Hš¯øQ™<x±O‹Šà7}‘A--9:c «xÑvF/Ğà¹÷™64<¨aËæ©»àSé~°‹ZsqÆM_á¶¶ ¬›,û§Çt¤¡©ÍİÜùµ47(càb¦…eù“×H|NBµhZ°“t¦»‹òZ»¥Êc]ú,1®¤È!1‡¬R(*D¿hjüšùjÔ8í´#ç»eİ|ÌWŞ®ä™»©ˆ0¯å?];/Û”OvM9äFè§ƒ,!½&¸ZàåŸ„.úèœhòk&’MŠ:$<p#1°JœljİwW}…sì´\>¨àòÈJQCÓÒ_bäàîî±Bô,„Œ4™Òº#‰èašeŸ.hy|qeŞLòI†£øÑlÿz|5•tºRe‹øD”êŸT›6êª÷Ô;±Jy¼!Ëæ½CŒá–5c]³ˆ(j¥N$W²»AèÁ"öœQÂµ ‘=ıT”­iœÖíÙ/s*ÉGñ#ÁR¢$¹Ÿy˜©ç/‰{ª~ª"Ze½5¯:GG÷¢F›°XÌ3 eŸeQ@Lú|hÖ‘¥ê7èûj:ô°`ÑVd©>ûè†Aÿ¯#A°§€Q-,øfo8mSB|¹|ã6­e†ù½ğ|øı®ò§eÁœ”!ª‹X1ãÉ^_ã>»_±SZË6±ôJ3eÑöî–czšmÀá#‚Ø;ÊÃöá£q!dÆùPwøGÚÌœ•ª¦i³]ï·`„e²ÔYlˆ±Áh%áÃÂ|Ó$œMa¹1‚Çš@«á'À—}›¼D¿>®ÂZØR£¸ğĞP<ØÏq$kÀ\vèÍø‰%œ©yCQ¦iÌæÕYœßó~“(Hè÷á[ät¸*\r…¬øÓT{¤²éù7aVËß<Jı²¦Âò2/uº4D×
t¤mzÙ*×[ş‰&^˜ã½Ç«mW}ú·ÆÎpË•p9Ë¤q
o)c2wD¯?ÈáŸ×Ì¤|åÍ~ZÓæ³r€6îlÿHLoİ¥Ù¦nÑ((¡6ú"
RWø¡¹Ô³w˜ŞXW©;U¯Úîs²Rz,­‰è†¨Ú$V†²Û`ë©ëCÍ¯ä¿Gì­•33–ÁPaTàu±É“×Ùí6v‰î.'˜M¨ú"JÎ9d‰ø~lêØ¬ıMÕ,>iÄ7÷åé›Ÿ	rìrœ£°oJÇåé}OU\<rvXQ¤ÎmItˆ×õ\âS;¿ë÷¤+'CİW%Nø°–õ«¬vÊĞãİE‹³±dzè®FS4S"mE˜ÿüÉİÏ.##I\Ï>VğÉ]¹sÜÆQşhùD#×Q9VNi
GÇĞt_Ufxêã¬Dëğœ×E,náÓÉC@”‡.›«Âh“Şh,y ¸¢ßDß[g®x,!kÆ×õ˜Ñ+2F‹Zòl©ööÑ1p&^Hvõ(êe5q\m·W™1“–ÌR+,JßÜ,ƒº¥úa
Ø#…Ú{òt÷`Zåh­f:ËóM¹l~ÿ:/¿”`|Á.H»¢‰Íç·!H¢@§H¬}—(ù4}Œ¿„­®°¿¿Y>Ì#*Á€Ë†è#îºíö»şIë6iê`ÀãpÂKÉ™
aôE~•Á¢ø8È º céx%Ø‚ÂZ•¶– )­7_«<M¸L<)¢öÎ˜±òh5ú=e¿ŸVÁÜ¢½Ü
jÖc*«$jµ{ÊùVL9cš	æ<Ö@·¥\#•0HR~F¨mÁ?ûÊÈÚÿä-ö
ò®ç	S®–,Šzü-]³ÇepxèDƒÚåVnKç	øÔ6U"ôÆVL[1PZsÂØ½bı{s`*6{mHT›>`’ƒÀù²Psjê7ÔBvA§^üó8ªœ¹T¸Y(¾¼K›äEH–Ã—ã9rNÜ_©¨³,Éé8Èğ®-€Ú×BV<xšÔ·ĞWG>µì H¤`Õ
ÊQ³]8ßÑeÎÜì{8¸Â«­oj[}‹ÑL|ëFrÃİŒÏB¢h¾Ø„QÉ×]ß¿˜;‡#m+a6%ÙYÕ)Lø2˜Jòhš†öâşY²çºOÍ^ÆF¼şùÚdÏ-á‰Ê‚÷›Ê–Ö3z¢79qŞ€­úqş(f!âİæÉY…%Ë·tåÜ <æ?Rí«Åàò²ƒ_d¿è¤†’ø¬¼²âIbùá—”tuI¬4é©üÈú¿\kG”äÁ(úã×`T›eÖ½ø’ÒuUjÆèPšK¢|†¹ã°š‘x/$Øš·Êá¾{‡ß¼Ÿ@vFCµğ¯/ƒ>|`%¼?ÃÃÏ‰\ê=DñGJ~ßYNİ€^#’ÆèhkñrG5Õ{.¼ƒe}ò—ïÍ§|56Të¯°°ŞUríË[È‰‡é¾O½Ô«â¸¿ÿšWÚŸñÃ‹[i dPRê½ê†g~>xë¯æÉ·á6´Pız+&õUvVÕ±ØJ½ÈQ Ñ?9÷ ëÃüZÓÇ2¶St„áäb–4]Z4czÌ½1òóq €>Š¤Ğ7M±••î·ÇP¬ÿBrWœ’#‰äÔœ1Ü^hÕ†Ks*¹ó÷‡¶o+8àŞ·uQmUÛó9Ğôîxvéæ¿OĞvÊà'$³{é¨³iºääio·e6Ç‹EÃZKĞuŞ>rã:ò{QŸÛ›y2­hyM„…©ló6'9ıĞ¨©S^3ÿ©XÛ½éğ`.kè¨°ävé€™Êˆz~
Š:î¡Q9:§}®srF‡›QSş¦&p¾Š¶"åãtÎUà#GÛ,ŠQÉ3q\LE‚}æˆô»¸ı‚ã½–³]LUÈ(O>¶»>IÀà£Á\Uxª9w€5”¾±aDc‰;…Ì@Q…o»4-šÖä>.Q†nªTr­yúÀ6½¹ÓQ^OT?÷ªË^×‰ÓÃX×?’ìˆƒİÙ¸&AÎµs£…>éiT!¯¦=oj7ò¶–£°¦¯›`€R(B‡«ô«Ú9pöyú—A¨¦°º5=ë¨B7°I>/Í±Ü¬‹¢è]']zª§o§bù}2BA-ñ9,yc0é…iıjMH2;JU‹CÈ°ìÇºBAïVêø°R …!²5O÷t`¾EajĞà´‹ç4j "ìı¿`fv/¡6"Óä]í^’_í?1ah´1äx¶@TÉ­æ
w<Mæ#q!My§1SKgLß-Á°’È)ŸÜ]!ê[‹kµå0çuqáƒÏ5–>Õˆ·ªÒÜY:ü$×-öd¶Á‰3FsÅ3V
9’¿¾‘ŒLÎñüÒyjµ“Ië°û²'…4
Oê\¼«`7¦ßôÁA[ßRxÌÓ„ÄÅfû¥WY]ôÄÌ 1€ŒJ•“ãrÚb€©/Ê~%HÂŸ´z ŸIXö†ûâí¾ZÕ4<’"¤=‘Ü'tùË=:èµ¯ãmÀ›·½ÚÏQJ´R>‘Šl,òñšš¼ûóög±Í¿­„tk—pğ2c•A¹DàKèorèŒBîÌñnŠÿöKğÄÖ½ƒ­/U.»Nß Î¹ab).ÈÁä`·r!vBó
CâÔ}€ÊŠ®¾İ-¦-h—©0lËÓm®â4vrE¹gy§<gX²PØVÉÚ=
ş§Fi¨ùÛ‘él”ä£š& œÉ#šS h>Låû5é~âõ½ÖQ£2X¢¯MŠ]­ĞH1FŸæqé§dâË¤ÏêÏyµX [Ù[iõÉŒf¨ïÀçî›Çº¶½[9e?“1ˆtI›§º ƒ‚Y‹:¯.<ºgŞ®1äˆ¿v5EŸV|nÁ‘–	ü‹kI~x0Û…ÅYÎ²'„@ÀÍmgR†jÁöÖ2X›Z‰5e“ë»6KbCw{ßÌÃ»²H«+‰×zÊæ´s£¼$î:N[V¹M–i‰x·«;)Ğ­×úly—ÛŞƒ£¾H½üg€â7wçƒS=SÃBY~ÚÅRqJîŠ7°øRùz†¸HÍ’¦é}ìôœ†R8€œÃ¤,€—;‹ áwØ¶ÚÏSaP˜³Ógº¦[Ó)V=]!ŠŒv)ÒXØ9 ‡»‚”
ğ@Ô¾×ôÅ1åÚ§7dPİTEÀ©§ş€²É±°gYÎ{fmÑÄÂ¡í»®†¬?$¢"ÉM
ğ¿\qq K0òËãA~ZF„ŸÂë„åqxùF7ñlåÙ(óÃvœ_™ˆhf{«	¹èİÒ¦œ'Á@9­I‰6>²ÚNZRc¸MO™VØ`â;w½Ctäû•Å‚JN;}ô<UĞ?§9]İ/ßv)S,@â®ÊFnà@ÎZP¤œ$h~&Ë¢e£|s0DfÚÈæSŞö¥{g¡âÏš‘\
âÄ~;$^ Ìnu¾dM­ÂXz]/AD6øì`WBmk.t¿OlY ¡4ë¦îÜAò¯XÃ¦ önmã¡¡ùYÈ‡öºiˆZŸ!Ì©í4½E	{ê`bš›À[ºÛŒÒTÔ¢0ò£å "¼Ú¤öfÂS¬•Ñr™Ye‹¯½âqÂnğ†F3åÒ"KÂ«7»í†šSßÉúgplŒ©Mc–ÂÅ¢<ÿ™K›Zå·«r QıJÜ†ÉG„àŸ¡<&wx¿6á?Pd¼æ­òà/ïí»‚Î¤Ù6‹…l‘nŒŞ@ÏÊ	¿¡ÀFğ:lë@_ekÉ—?ÚeÉ÷¢ùİà'…?5òšÖ•Üñ¯‹_+!ÉàLCİtéewõmšKç…[¶&´ÃÈ(‚òcıúl"GğÃTn¢9TĞä[uÃñ¥+ş¢cKÒUafillS–Ø
ÌV¼Ú&Jø>]P^hO/¯tRŞ•’9oìá€ 7öVqÌº¤ä^ı÷ µ|ôíq³<QµÒûp8ÇX¼@×	rï
äkïÜ]CÜµÕõ¿í¤
»ôp8¤ÄW¡_„"Uzxî½Ÿ2T*‡xÍ÷¿D$‹Éc”²„d«±E(vîMy4ÓµrmÒ+*[9¦¤}±*ßv:–Ê`Á‡•}B˜nÑ<ÚùùP Òæ†ªÊª¿²èQî2mlõÜ£ù†‹`° –ƒé/›˜+¬ºÀ”5ç<:E¡P5®gøeå“ØF¤ö¥»c¥m
Î“ ‹EıÃ‘ñ!"Î!Ù÷p~ØNÅD!ÂµE\ö5ëïÏÍñÆõR›&Ú	"ªzR´ÔáT5.²M¸ö]ÚWlÕ Ùà»0`>Šä—İ8û1îéY,Œ=.öû8AH »aã¡vø„,3ZŠiö“†’ˆ˜²ø`øHĞÅ^£nsQ0Ò8şŠş¡ŸÚ™Á2°™T-xŞŒ]/1T{™“Øû˜|jvâr˜¿45ÒåÅqcÛõ“½ùúñĞè«2¿G'*F€Á`·%Úû\1[Â³ø³ì6*mf«\N‘ÇÂAÆEw$úÖìË9bœ»ë»®h
pq”³"Ğª‹ª„†©¶:÷/]u4å–'g/dåN<û‡Ëöè¢\Î”3+5ì×høNjL7{)¬2÷"ÙREİÿb†ÊkP¥Ÿ½vô÷ƒqTàvc¼ß¼wWRŠû4’­{1’ˆÔ­n®ÓDp¦+\p¨%ÎkÇ…•×gx.ˆípõ*à1VÅ•(Hyó­_pÑ‡yü˜lÖĞ¦ö"ı!öWk@ì”Fª‹‡ò£·®q{g¢ª¦¿GãOÅ«D/E$ñ¬„2Ÿíq‰ô¸³7•q`æ-Âé¡‹Ò(A&àí"•€½ (ûP9“r„zb—a~vÂ)<U %Oâ¤F¼xD¥geˆùRÈ’n1aÚ4fw«×÷%1Î®tO?ñQ7!Waù˜¶´O3ZÂltÓÆ‹%Ç AÓåöºì&­/lNÒI©øÛ/~0’G1ı5+-5Ùnı ã¯ñı]”ò	çq¦Ê„U=RÑvG‰iû×ìBúW0z=g€º—ÿ0Àák©yX i”ñ^F?d¦9Ô×F…´û]è£a´VËÖR© ‚¢[¿¾èñÃkDæQ¼;·¬£(n¼d×ÚP¡ßÕik¶Œß(èĞx½bºsB<ëÎ?U%hµ7t9ÍvAìz¬Ë`ÇŸI¾\ØÛ…Uy®ŸıC|I%üµ=Ê*‘ùf•Ñ`í2ŠÙáıÉyŸ§˜OõĞJÆ?™ÔQ¼¦‚ùÛo½Û>Tæ)…é?¿‰¶@ÃZ µ,÷Ù¸õ4‡²„=(c÷AIdÁæQ¤²gD¨šÊ>[Ù)Ÿ
=Z/aqTO;îy\V\=GCI©Ä€g@²£æuGAÚû™ÚNƒÛ¯h-u9|ö\X¿îÈÕÑ]ØöÌ@.ßc ©Èd´´ßX¯Š*½øPî/k>Ì.LŠß
r2ÃªÔi7ÛÓ )Qñçƒìr×~›XöUõChŒEíŒf³!±TÑùÄµçÊQÛ:ı	Ìâ¤_Îø±ìC-+GsÇ¯Eíã®o"ğ	‡0Íp¼©İ™‡ch3iF‚8|Ì2®¾
31å©u‚"E/tHŸïß~zOå“ŸÇÈS]-8¯%ç³¸ˆiÖÌ´gRèª3¾ Š^hOÒ5À«Xù7yÕfEøÙj×sqêÁ!+Ò±è´´-€nòO&uûÿB¬Mênz0æÇÌ‚!VOÉ“&Éé–n¡ºäI–vJ=Ò¥Ä#$GHo¯ZVB—Å&I9¶häŸˆSg#Õ®œ Ëcø†™‹–>İ
#o¾ Ú(7­¢‘ãÉLøJz·YÜ´¸A­ˆÆ¬-y+##4K'rx¶}]9ÍÅûvÛS.1aWƒé~+mÉeØ“·uàçîäFŞ9te©ñšr·oî5¬CUıE­=8İ #nÇÍìxkXm¹Îwú 2Q·<;î2îÿÊCufSv¼;%¢Ç?®×äS¢É„cœªüfïP\»ı
…¿É&W?„@7+Ós}H’Yí—YŒ!B… ÁÁ·:Ò®}$_º'ìc'pï@§‚¯Qîœğ Jf±ØMwFª!Ïİ´8Ã6GJ§±l˜/µY„T8c¢1Şs^h£	Îûé_bRq/¬Î\} ÑMÑ?rÊ.ºğútEø.ö<ĞõÙ¨9ˆÔ&W ²ÍzF1•¼¯˜Ê›¿Ì1,íj[8Y_ ëƒ¶ÎR²|QÄéŒ`~%RÙSXÖ™GBB3qÒJ¼O¦i>°•ïlrå%/q¸®|DÌ‰3¾K#¥«èz2è@]h·éáj‡ åá0Æ”¾J#<PŠŠ/—İ?™,NpŞåšfø$ó³öÃkXb¢‚‘2cî’“%ê¿?{v¯,Ç
õr%ß"c[KşßtqÿÿM!„s°¼È§Ô¾]…€P\oöÍ†ş>,”*Sƒ%?R>ã­­¾å6nĞ%D´Ë•\ı¢µN½ü$¾¿ÚÂ/Æı€RÉïwç¬eDºŞ<@ Õ¬ßYÛ{§Qô‹æç¼ŠA®6Öt1|cö/„M7zy*bçEo4Ss2Ê·‰0y=Î;¡ê0¶´eŠ8wÔ%xX÷Ø”¦Dàó]"êÇçÔ[}Ùq@Ğ'ğØN³ûÑÓS	ª4ÿùïk °ûÖødF„–‹çS«mşîË{_.ÂWÙ~èü.ÇÇ…i÷Öht‡¦Ñ¨’oŠÍaY²<u=;ä‹P•A9%³š6u6a„>XOl¤pŸÌĞ	õXüÿÄL
·›C¾'Rivp¥“˜ŒæŸQšÍñ€Ã}kè‚ùôóHiáæGGÚ›^d¼V|:I¨ª~/*yªY¸nGšºº	‚»a<øµë¼i/ä4»ÖêÂyQxfj-å‡ÂèÒ©³uÆìT‡›¤½0#”!­•¬O”ŒtºæêÛH'„r÷íScêËÛò²˜¢²! ãè¤£F_·ËGem ²¹ø\vÇÕ&¸;@´‹]?C¹No›Ú˜Uì\'èrSBS¥¨ùàšf%òôeÊsƒÌÑÊfuše®])´ìŞ2à„ÿ"“NªôÀTğ'øŸ	Åœ)jxÍ­ş¹f–¤_|á{ì®Ë´›ŠË¯CåÏ)ÅùÜ˜"õ—Ö§½—œÆ~`~XxC”Y„F¿˜==Wë(Ì
.ıç‡»Ÿkø3»ŞD#£V“É€Y­Œœi–Â_‡µ’¹ö3ªÂB|zó 6;dÿ£X…Š;ô}P×%	'4¢ª–>¸õ½,kÍ¬éÓ˜õÔ±òşãN’"1­
¡¦%n_ÖàU³•&v·Ó£Á™àô4×jZÆa0ó_¡ù+*4‚fP—½Ñg
K]‚"÷ÊšxæœÊ/3êˆÄ]lÁDì-wgN‘JM¢j¢âä@âsöNúâØï„P·Î†›nŸÍ{†ëZje•â–boØŒÂ@í«±-Š@Áª
Úê¾f,¢H›ZCS¶¦Ò6Ÿp\†!·Qã]•¿âR<ç7hN¶3ˆ†(“JÁ3ì`yë´ˆrégÿäÓ]ZÛœ‡œéLql‚ÆD—–èw«üà;?iáwÄG$u`'tÖÌ¼Œ¨zÓ7ıõ+-û‘¬…ø&`h2§Œ2ç>_ÿt8g¥cş4Œ0 Êu›³¬²oí"²íâ]›˜Îâ?“³ŠLk°Ædy
ıE¸Z÷(øÍpt3aÆÖö6ZUÄŠ‰zµÄG3¢’,ğy™q¹æ½5å;yw´W±¥/¤gø;»`
YĞóy;,æœÅÈ1_0Ò(2}”fwMUÿé]µú§ÑXñÊô?'¦dÅò/U!ïûRGûÜÔôÈ¬&!&:%÷zû€Ğw€¥û³mª_z°¥Y+?djƒc$ëEÁB¡Dz^·Òá‚KsAš3Xr~“^TÎ…İ¬/bÙµ˜uT…Ye†¶¯œLDê‰:ŠĞ)^È¼4*ÔûÑ‘ú—O2õl¤yÕ °Æ¡ÆÓèæî„ÎÚ|Çâ6Óİ½Y`ÅOò	0¡‰šÆWq£Åp¾Û¡Ìí³_ëÑ9L_Û¢‹ØmÖI—hv¤ê~ö$ w(Îµüºİ¿¢¨ H‚½Gå‘†E"Ÿ%V¼%Å_5›5À¦æµrŞ]<N½E]ºPå-8ÚT¼€¾â:w*åEnÑm€1>Mø~oäˆşr·mBDª— “¨3H@)›ŞHá?¨_›Qdè¯EµC©GBy‘Ïˆ£âŞiŸŸàÆš:eƒŸdÃŞOòa+®åkˆğIÕÅêÎñÆÆeügàòÚmË”^˜d]ÒW\˜<"0°§Û,¼şâkû®0¡íp{	J ûl0ˆËq*˜çIÔI}¢7€26¨fi8åE¼4úõ»JÒ=(D§uuY_pB¯nŸäDQÀwÊÄ]ÑL«µ²¾iÀ‘²'	ÛÃ2Ó/v_ñ·n—íyöœÚråwöy¾±V\l±Jrº™›„×|
£\àB+×u>WEAâƒé¥Ê.ô$³yL'V¢bèËªKt† ëˆJD‚Şn p½£¬UìKSåUvĞrw4}ˆb;™Ëa:Öœ„Šn&˜i“&?ÎÅº‘\ÏüÕ^* Êj˜ÈB¿ÓëE„õ¹ä&f<òz©ºN\™ş†÷iu½³±­:¶Bš¨YÏ…R·€^OkéªN ´¨}8Á$ı8Ñ”YjbÉµJ-¿áSö#£UZ@ñt’¢Ó—÷#…0Êw¨Àş¯”€‡§(ƒH2üì€k‰’€uæí*5»¢ôSFq¢Xÿ­²
Ä@ÓËä®ÑÀÆ}(†€O ÓñÃÇìöC¹òz‚£ş;55Uí©¨P»ãa4³K‘a=®:wBÄß1.r™Jşmáúõè¤x]àa·m¢V=Ø: ˜ê{KPÀôÈ{WñÉ —xbÂ›å˜eTÙÈQÅP“¦ßé­¹!\õ«ÿ‘ÏéÄ$şSœ
ë›{Åöp¨gQ®Ôe³xéšˆsâÂ¿„ª³•sOòïIpêJ†
 †·Cí\]Û¬JD¤¤ZLdôhËş	Ôbä³¦ä6YrÇ‘R°0\Ô%å÷{™ê‡=Ÿ5h½	%rêë»úÅ©ÉòXÓÉİd™fJòÍò‹‘LóŸÉ¤MÈ‚øTì#ò¼z˜²l…¢Âj¦Ûíˆ× X× &s*.FöÒr£$ñp¿e‘ëÍÄv›û¼
Ğ¯GT¸æÃ
*òØhbé´« IAĞÒI •|™†ÀËªÛËÅß|¹¹üg;,}B~ìâh÷²&~±Æ®+é
¶Ãø]5.¿‡<¦	ÈÔtô/àd÷öúyl::Cİ¸Vc	÷ltšº›èjş†Xà}3:!qÓšà×VñbÇŸVØë/ê©İÿ5NÓFIÑ´<ğÄÜ–\Tü‡ğËóÌ¿F”I”£U½mXlCMª¼9~àcV ñ“¥¬ºHX¨p5²2êötƒ¦î§$Ÿa™ÍmŞ€¢-—ºpÍT9vŸSºCÃš5[iÁu£‹	ã¨×ïpHéªËÄ8³qhş5p)²$íÄm¦>vÿÌÀ¸pÀo  ‹MhÎ/2PS]5Y@Õ§3/à×Õ‘ZÿB®ê¹şî4IcçŒù]æÙwÖ”®1Ñ:‹Ğíj†É~q”Wã¤W½	
=å}‚M~Î¥3§˜!—½\ûpÿd%’¯™=‹ÀYt;
‘”÷Ijç¨–œ-^ouVÁj:HBM.+‘V…8ÏÉ·I	NÀ]J–Ú? 1e9W„Yƒ»©.
/^íS!¡‡lQÀ·„Èêİfòx¼e
Á¦W¢Z@V¡·şŠ[¦oı	‹ŠZA–só!ü~ŞîØû×$kQt&rsÄ,é³ò½¡Eïö
®59—iícP‰ø‰R2Gio7£ÿçä”—mğdHê0¼¼ÏMñØ8\ş#àª Ğ˜›l:À¾Æ}ÈyQ±â'ó²•÷Ã„  ‚"—ĞZ¾_ ¬¢€ ‡¬¹±Ägû    YZ