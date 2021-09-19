#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2534970342"
MD5="0fbbbb9872cdcd6783dbcd51e7067e33"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23812"
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
	echo Date of packaging: Sun Sep 19 00:08:22 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\Â] ¼}•À1Dd]‡Á›PætİDõüÚ4š,k1ÿlÔdq$Txæƒ”Ìd½2Wt!!œc‰Ñ«H`aµ> o	uéÃ÷ŞT‹Ï5r™-ŞzÈì1q±N|äáB‚Ú3k¹0–D­îG2ûó}†Ù¹)ÄXrÇìásjr—4V]§šÆNk¨¤BOH×ø¼¶Çu.º¯ïMâBkyÇ*Ñ1æè«b|Öéğ>4Â<Y"ÕÅ.ŸûbvjR[ëYBú}ñÏ Å2Òæ8Ø>K{èX¤¤z¸Ş¢ a“*	é	1
ÙiÛ±ŞEÏÎå!É¤û`Y¯(#†™¦¯³¨;W>§_lU@ƒ|ÛKHèg F+¾Æø†92YT?ÈMßD‰m8Çˆ4CKrSKN—'v‘OœÉ+¿J8O©Ê'˜8{U¢[&š)VË|XÃh·İU¡n‹½t“ÖN†HÎtğ½×'Ân$?…Ï~…û­pDÓ TÒ'øÃ{ ÎğÄK-1E¢ìÄd>mH †Hñ ä@kÃ" Q\WY›cs»§vÚVêyZ	Lå‹Òrë¤]JS¨/Õ§‰‚.C~ÙÒš‡ùÜõRAZnÙU®H".á:Ó3_6¬n=e?À{ÁÖXA:Š–ç¶¿YQó©m¤¥¤˜9^$ŞçåtÁ?è0vÿ`‚×•Â-K9Êœ’ÊÅA¥˜!BÙ]ÍUÜµ^ˆÕzŒ?e(*Qxé.Û`5Ù3Ê’õoXË88ßƒib=Ô ¥`&ºBb‰×ıKtnuX†PMB‘Ì6-¶ -’)FPwìœ¯×ÚïeR³ŞÃcp‚¹‘yñª®ùvØ}u@M?ğ#×ùxé’É–8@Òt«œQƒõxÿİ
;Y¢8*²ˆ6Õ¦px„:H¯Œúªƒ½¸!ŸPiãØfä#ş6@#>B“I¾<˜;x½†UCùùè;“>Í±˜(æê ´ ª™~’œ‡(4Îı8‘Mà”—1<ÿl—àÆ¼Ûåº\k	¤o•…tãœ”hŸçxfŠ‡)Hø{ZÂW#©I\–2®ÉoÈ‚éÇn†)>ù@?:ˆ$_Qà3ÑÉ³Ù±àëÏ{d7ƒaC­Àó,«éÄ+ra¹p)*Ñ¸×#rû1ËÍëÌÄ¿ßíe·@Ã¸²wó(û ÜòUÀÜJÕƒEIO	½k¯oIp}Œ–Ãd.¾â6bşä ğV£VÂ¶³†í1B	xß”Esİ’²ÏpOc)ù’Çä¤qa½ÑÁÊüËòÃz}ˆïÛ‹ì¬z!ôZ¨øÚXïß¼j¤ï¦È^¦XQj±H‡zaëŠÇN»ÈOï^váTæúVÏzİùdc”=`<ôíı`·N¥„Õ#€`†ûî'Ù~aÿ’H«šÛ©ÜÓ†:çáèx€%±øÈÂx_q$†wŠ°®;Ş8wÊÂ	A‚Ó+pØ.~‰_:²¹é”;İ‡çĞ/ÿ.pûÍ_ĞğNıX4üÔp`~€VtJi”M~jñf!Xb®‡xğ9i²XNäÇ4ÅÏ]¼yêmpş—*bÁ˜Â  w…—½ƒC2¿»ÇJ,³ NUAâó2Ô&<QşKZuŞ¡¿O¼ç¶î®äNb«|·ÛÍ{/”5¥O´ÛöÉ€½z‹Ş€¹<Í¸»Ãµx¸8hşNËôˆd>Ë<ˆ¯=”M£jkëJ‡aÊı9ä‘³i—×Šp—Í)×4šÚ+}àhò‚yÎÚpqôë+‘‚@s²ÄF¨È163IÖIxÅİê¬]=ÄœKÄšC÷$}¼Ì÷#ä¢­T‡Ê›‹¶Q} [!àı6í†oøN·fò±şÊg–YäË‘¿âxÕî<İ¹K±×«Œæ˜õ¬¦8¿yÄ’ğ’gBeX´ğHĞ³¨„G.1	iáû\ıqÿñe/&!IvFàí¨GšÄh¸Ô‡iæDQ;ñ±B€Õ=CEÈê÷/‹^´¦ršdÌğ¸S¼Ôr’ø–øÖN¡¨ˆw€ŠŠ#|B²»a›múÉán?Øgıod¿«‘ÌÉd¦Iß{d
&ş¯ÇooÒ±ÓIh¡i…Ád‚8$¦ïaü°)	o¼‚jÃ©ìD’i†‘­bucPú‚µFíŠév`ğçŒ˜ôS(~ş˜N^-§aGa"j"ew†`cÅ¡Õ2ßÓÆÒÜ‡©
Ùs¥D:0Ö©| $—EM‡u†|[1„\±ÆºF—%âŒ†ÇvàÑ€ä˜×ÌlD“ãƒšö•Ø™ ¬»€«7¿]<-DŒN¼´ÒÛ¤âê'×u-şÃ	Î×¹q²tHÄsjtİ­Ó^Ô~J	>å\ààè8-¬¡ ÜìŒü;ÆâØ7H)¡8Âú{6+h—½‹ˆ¼f‹ˆ!=ûvÎG“,©Ó³¹™"}É°	X£ûŸ†X®>Gß)Çğ<¾£Ö2¥YUµ¤©©1ˆÍtƒ;Iılô\ `màµ‚Û{èÒAA.©èdˆúXÎ[oø‹ÛÚ¿çeì˜ßÑwwè÷ƒc¶ù<òmö×¸ò Õ™À1Ã,¬7(ú\Eõê×†äÉ¡ÁÃœŒ¢ÒGo
J5šF`~àÇ’6I¢_ÔL	MŒZIóúÎ–æ³ùD 0yAcÉ¼•Ôq{ÁRJœ|Ö%iŞP“JøÓ1N3mê|@ø2ıÖ2Õ*‰2…‰€£&µ	÷‰ò³T'ÁV“°ñ£o[£6)ñëà-¬®%Ú3fLF1aÎ»•…™±M£3~7„8Í5Ùş§.‡è¬@LûvœÛ;áQ¬ˆGÿeğ°ô„¸ï·ÍŠı#–Ü#ªºÌØ,r•“bñ°çª?\…@Ù|¡z úµâ›fdÛ2í½ªhdã °}ÎTAJJyü}d‡+S?ÆMSÎ8—¿òï t³L8VdcP ·¶ûçã!W`ÆHµƒ¾ˆhc¡'ãû?8è6cğol}m‹´Ú'È½­7pÖK]—
m Ğ7T½W;œÛ ™hª;¹VoQI2sBş86 ¼úÕ•â*öE,‚~™q›9åtİ-ã¶ƒWˆşw_Æ¨4Ç;˜ôÄL÷ˆµ²Í£ìûÉù(5V&#¸O&ĞVdÿªÀ†Wü–/¯E^òq`~¹É×k¤âPß"^öVvó
ıº¶íägš$¬¶‡¹nd´Ã _Sz5aÉZš¯âzíÓŒ0fş"dÀşò§›Y¾Ö¤£÷şˆ<p¬TË€%İe§+;“¼¼ºSwâ¬‡Oíj'î}Ïqä[â‚rz‹¾œõLAÖóvÍi&AÊ†$V˜|İê°S#q±*â`©&®8;°´b‡+x¢‡ŸŞÑdHƒl&¨*íStG ÉMà^æk±…¿™ÎB0	Û¥'ç4ÅEjİG¯å(š¢êÁØñgJ;`ÉxäÒÓ™oS”;´O£QĞ<ĞêAœªk  Yrª$¤ØK5ú…ÓxüPª2©yİù«çc0½_7'%1có«)ğmÙÆÎ<ÿP´èŞ| İG5Ø}}^1¶£-eéëU}R3qÕƒZûo›Ñ/çª<áù×sÕ5ìHŸa@71Àş@$¨	ÕIÉÉÁøWhY¡ŒÆèı!)3L¿<Sa0ËÎÓ¢›‡ùÖHŒ#WIXÁîh´ÙÜ5«×A‘cC¼O @Ä›’üßüR,Â¥TùCOU.òV¾ßúƒ.Xµ²HÈ’Jz´çiñã±¬¹±m	ñ,c»rTMD³fy/At¨WŞ§IÌ\šP1DEJƒm@Ù¦åS¬ú€Îå*Ñ¨ı.›L±”{-d©`õD†|.Õ¥9ø0GQë
´gyøÔ¾'MdevNªEª£`ë½a§He@=ğ±i·Á2 KîÌ}ÊA\íÈ¹Æ$âQO§mÅóhÂE™x„¶?›“!;èpÁ¬ìG\X0 Ê~1IûHvö€º…Òïk°1ŞCh¼Å‚Œ“q„ 
Kñ­+~¥:?Vm+m%œ}Jl°£P€àJ+›¡"S³5OKXd=-o0áëÎ!x›ù.òT´O?álŞÒ¸ ÿk½ŸiÖ^Š]ùŞÏ1™înÖ»’6!œü>_lfÃ$]Mî´`i|Ícdş‡æ¯VwfËÄKsVuĞÀˆ-ê§Û‹óe²…Ìª¤m:[šVMoªúæL”]½9ĞERÅ#$b <ªömH=d:!ÑaÌ UÈõĞÒÅmá'Çæ [X!lD"¼ÌÉ’’¼<?´œ8.pïŒ¹˜hÓz/}h¡ÁOSI=wnÊmÄşœÕ·ÕÚ³ãâËÖ¢]%1«zhXÇ¥n²}ğ/˜m„´S¨‹ø£<f{ù'qÿ	«É±ÔXîèŞ^µY"£Ä>-ÿ!nnï` ov£Ó°“;X×…5'Ş}j€Hú*¢ì_õİ„ÜaÓéï´Ñv+×Ä%È]Ü ò•{Çkİ÷ë^[à³8÷ÅÊN\»E	M;ÁØ/~'É|„‘W¢¢ÁÃóÕá´ı{ p?4ß¼!4w–8@îªÆ¨[	U„\ó±ü¼J‹*kèº¦lÛİÄ²EU,[‘ëä#Ñ$x7’¢1©<!ëÒí0Ù<‘úpª^-€ı!Œâ‰qkøŸ/Ğ‘Ğ9¦ıÂë]üõJê/ñ'jÑq•)Úzòäp)õBèãÂ¥¥“êø¼ßÔğ –©D4åÄİÆµ>­'n>)ÁûÙÎA‘Û”c“4u—ˆ¹øÂQ=U—é>ÚuDYT„>éP‰ _ğN=Áèã>óJ€€æŒNëMe4.§ö[•Tv1Ó“§¡$`B©-í‰Öz2ìçı´8Y2bÑz{»v©è©CÈ‹æD|À"®Š†O^©ÔŸ§3lÜ|ç_SPgÜoéş‚»Ñ““’ÃÙ¾Ë›€F_â™F¤³GÙoØ±Ûã~Ñ3LG•PSª•¸sÕ˜ÛvmØİ<šF¨\Ñx%vØ„kc3ˆ¬„¢¾4zŞü//Ó°?5‘§šô_l^cbGNš|¼ªG¼ ±™şPv$&óê„Ì«lâBPËõ`ìeûc2SgÚí¢®ÊĞIhÙ¸.*,RÓ*·ÿ¥‘ğ.7ë9ö^®Gq/+1O)\Ò–/Òªà,‚kXã1K„ØdËïËàÈˆÌNùÂ„Àªã)¬¤-ˆğ Óİ¹Qøç<¹–ô…ëq,O}ÆJ5~N»‹á4u%•%x(§H+ä<fı -‹(HB´‹·¬ÀLÛ´›´™)Ğ¥ûá3‚f&m]:£Hc9N8²¬-q"µ ›–ç’y…3¹óGŒiÅ‡óÈ{iÖÁ–åÛ<±“ÓÕj}û‰ràíä(¡#­¢vŸX`I®o å¡ºî‘]ºŸKNB–ŸRaÍ\™¼CJ,æ@Ş8¢œ×‰DêWKÅ‹ä›Yä¦£Œ“êp¦µÇh-ôGa	§y@­æ‡:hv_:ŞšK¢—uj÷Äòæ©&õ1Y£I>“eĞÀÏ—¶JbŸV‘¡N2”¿£¾4n©5‚ƒó-µdÊêÉtbò3Uõ¶1ÉÕ=ª¤9¿œ½ñZoº±u,Èòé¹ÒÒxøˆ‰íÄ _P[UW¨ac3æ€·­ci‘\—Á¿$GqšqêÅµ|Ş¿ZÔpña,™¼º‡@{4ú(ŠÜÀ:ıñº&#J }ª´PjÁ'vw™z¸­z[÷èÛºúWàÒ'ÜÒdU÷hTìíôz½UFbë³vÒµ3¿ôUòlÔ¤7êãÅ§<©W±˜*†äúú^70êƒIiŒhŒòF8Jû‚Á5ÿ':Á¢ùJ›kãš©ÓĞm˜“,¢G¤Á%?cŠº5DŠHáàu!õÌ˜ 	6™gÚˆ&Âdj8ªÑfÕ§®¶?[&:ªËmÖ¸ÒÇü¯è\«PEZï71'‹}~%j
Hõıo	ÊİÆDƒü^ŠÁ…ºé%ï¹ûÔ/Å Í1Qr$©óöĞX8@´‹&ßŒáx="ïY¾ùÊÈi<†$:<Ì9K‘>A
èDÔJÜ$²Lc‡ÚnxÒy+*Á”Íu¦·^¢…1£9ÅØ†³„‹~•TŞ!îêññ$³Æ˜İÑ-‚8£_t|2»æªğƒ`JÓšÈ¶Ò§^f¼²¡—%ı,#ŸÀ2Ùu„mß‘ •›úÇ Wß˜Ø
ÿiûÅÔ¶™ E>’üıêÅZf
\í‚¨i!m€ÛãB›:Ş(ì¼æuH¥NÄ“%4£•é†íJĞ/ÌP¶|®5TÜÓ–¿ ¨\Õt%·Om«\r0[ÑÄd3M˜-6ÚVìs‘‡SAVG{wáM½ÑH*òèÇ?"-æŞ0aƒQ·ô9¼‚5#Ã¥â˜×‡Ó¯w])î‰.WÇZ€{+ó0ÉÖ6ñÌ:¶ÏRù¦¼oè_>9
6Ì¿¸97?¡¼áZĞPh ÎYïœ•¨H+4•ÿò|ÓÎ^i?æM“Ë9*¥SÆ½zˆ@ú1µ€S¾wo¥V÷ˆíÑÿú÷ÚÏ1B*”šşUpfFó8Kgg÷U31Ûzk…ø¤ª†fÑëìm5Šb–õ—)ìd9SÇèàšqb›1[`YZÎ¶¡yV)õxš¨>‰ŸuÍ$xª‹9Ä.™ét¢^JŠf¢;MÚÀsñÎ__¯ÀÓÚÓ°#sÜG•Š&µ|?UÀ›MÏs…sg¤/€³ÜŠ@¡K\Ò!‹©ôx´îÂ…ï®Ötwh7é@Ağ#È'ú¶x ‰‡Ğ¤Ï¹FÑ)Xñóœ Ú¢P‚\¾û¿JµzmAVoår;ï?=tì·wP[5ûB[É”0hsµYàí´å²sóâö‹!ˆ4?½¶¢•ª|}|Ø–M^>ˆánÙ¼ê²¸0¤š™()¸THCÆ,SÇ~şcš d«UsÛEzvßÛ?ÛN‰õ‡ûéÑı¢…@òÒ¸ğ’ò6êÎåÃï*É£Iº°œß;éÔ¹¯o6ïÙd^¢ËCb×9ÃEïâj²¹¡óÏ9â4ğãvñ[q”ñ6}ÂBn~N•©Ÿ>‹­tÅ~ÿ×A§;İšb²  ğĞQ1ÜãõqÎŒõaˆ`á|â5~Ê =8&feo|è›xP‰ò‡ˆ-.ª|UºœãÛI…Y‘@“ÀV.4 E¼f´æE—'i†B$7ãµT>…ºŒ j(¥©©‚õò h´GÖ6t/Q¿Ç®ÈœK÷I9)ŠÕªé±j^âò‚‡/Ä¥‡ŸŞÀL'Msà	?0¯Ğ[”È1qv!Rú!ˆÑÿÕJÂn&4BoÕš—Ù5`5”„£YÌ’$ç~l\ÊJ_
ŞZo$n$Ğ£G.wÖ«±æ6·¯“!l†?
{À)0ŞŒz™ƒÀÚTà‹†e4l÷¨ªSL"5¯¤øÇüy¼œC/r€FõjŒŞnÄé¥ô ´_ÏÓşñ}¸õêZ‚O¾uù7º@øNômBe‡LE©c6²/s½‡9Òúç¾8aZö€Øï""ù••Àa {Iı@,3§ƒá+Š6Ş.+Ñ?¾â«ãà#ŠÂÏõgâv°O‰:Î£ô‚w€ç:ªÀHHØ˜¬ˆ¤WéxYL×WºÎQƒğGÁ»Â,D5¶S3-_QáÁ0F¹lŸL.|OvÍ²IVÆ\OI»4+¯D^Ü;ÿ€Yò'[oêœSFkB9ÜZĞö˜¾³#ì¹`õSı[|	Á{dÂ;46öĞ5MÉX&ÜtÂmŸÜˆòp±N®Sğ X(k” ˜Ç¼ZW¿ï•¿©Xz’lÏ²ìblÏMŸ=4•×~ÅÂãêcç7ìÀ±"è¹°ËÏFá×œºÀ
Ï@àÃV½åY$Y£Ä—[›´|Rë£gšÆL93[—&Åf`¬Ë8À35F!)¨Ñ¤@Å_²#‰$¹Òºjt„ûÊõÖ—†›Y÷ñèÌßî¿Y#€­1k&Õå7ÉÓlA‹°Îˆ…œ‚š†Œ‰añª²sã²W³ÁC! r¼Â×‰[ï™ŠÂT\<^óÎ|]j«+ÕCáÇ»È‡nş°úßs#Ø:³ÊêvR vu?™{Ğó)²´@x·‡!¨`[¶ïëÑ†¢î±óûË•c±ÉS'eÖ+<–Uy5cÆŸ–Pï^5	©ØlâÙ3•¿Ï¸°+ÃÕ&•xlhÂ —Ht=Ú‘¨ÄŒª3¨ĞÎíğblÍÎóğFßúä­ºôÙÃŸQe½•ÒÉ
î+÷Dgò2ğÿåÖ)3£Ìu¿FR‡)ÑÖüMŸ"ã!õä{òõav”	/µ¤Z …Ë5Zƒì{J5Öq<‚…=WÊ1¨ÀªN€¼Ÿâ [†uCûQÅ@IÜØÑí®–Â”\Í7ìÖV%3÷h~Š|úÅåˆ*û¾Û¥Ø'Á¬šåÏ4o{|ÈC }Æj_9Æ«c9•Úo";p_GgªBy ‹ûXtÄ›ÑOÑôÖ\'jwfXªÒà¬ÑæùS0Nd­ÉUC…î;C7ñ[#» ìqÍÎ
Wbvéù¨5;Î+º…Ÿ¾Ôµ©¥ù/÷ô ]}™¨«‡;UÌ}‰Èdš®ã“’†{w4±™¤«í€\¦ß½ğšİ9&ºô^OsÅÙ$"h†#¾±ˆ/ ­X¸õkkV6;ú$Ç%RÏNÆß¶ß‡ Ï$ö9!t¨–{9ñ¯qp tçx:Ï‚(Æ®csõÅ8é°0@ñ}+ubŞ>g~‹¿côó±“}G{\µâÌ´v¸ä+„rVUİ4FA]ğ'åœw™l5·b,ßÈèÙ¥í×ã½B±Ú it‹R”JÂ6°öÏŞ|TvÇ+5 Ù¥Z9Ô§d%ò—,İü–ıì3R0ò¡Jó
­‰Óvô%"Z‚8%;xéVxóğ´>FÔSê5Nw‰ ê ÎZĞ‘îu	fe„”ü¥©:)|şÿãà?u×ğÿîn^s÷Šºèıècá³»È~}7ãÜ`ÛšŸPŠªÕïäQ˜¯°‹‡¨\W¸“YŒ£°iU	Á´¡p•L_ ï«À(W~è)_K?•¾:ƒ8õTM<£°§ê{;}àBåª+«qyõ_—¡qXISóü˜#+F"ë:àÛz¶¸kÍÿ8ZLªoŸÑã6a`ÊóëêàÅæ‹*mPş/ìèjVˆt
à†ŞíVÓ'¹ûëÜ¥`–®õ‘”ø	§®xX_h•» ÷]—ù?nÄù©ó ¬·Á2Ğ†ä;,“qé‹®ÿÉ[Zf€…êî‹’©
Š¯•wA2<ÿÌ’wÜ”³Wœ.Aò˜µúŒ%(ÃsìtCw`º)2ÍÅ Ğ¾5`§ğÖİx–]W¬Ì‡|›¤êè«VO¢>£Q…>;ûÛ?ÃD±AÌ.Ê£ôy™BüÜîF³´•Vbé—Ò¤E–‹`h°ÿªvÄ¯F´O¨¡Ìµ›ıwÑ°.ÓzÌV’7‘î¶²XÈT(Li^Q¸¾!èóŒÚ;WÙM0êHÿKûì)ßåÎèPÖ'ËF'E	*¨K¿ˆ£o+Ü·LP_Š’#<ï[iüõ¥ÚRCHÙ“JI´æsê÷Ä‡%àVuKJß4Ô™>|‹2ÌNy¾,m¨
‡Jüÿ²ÿ.½IÖË©Åe4Afiè¨oíÛ—é#‰ê›g&Mo sU $ÛH^…ÛÃ‚¼=9Àw|"èö¥¦O*û1ŞÀåÄbßPpÄË×_ÄgOÕ„—uD8¿¸;ÎŸj|jIêÈèé‰¿dqç«ãİ#‰ü°öRC¸^t'Øíµ¨±ÃÆ}ÑğCOèH€? ˆÔ&Ó<ÅØHÙºYªŞŒ9gº*†Ãn°neˆ¼Wç§¯9xpF‰V6ªo/ÛMßc¯œ{fñ¢ÖVŒ¥ñ?ùUy¸u¬ÒšÇ&Œ’ßf_Çâ•ˆó×@øRŞ×xSÁo^½ïD)òß}ØHLø(ÕûA7%X¤ü®lî„ÏöíÜŸÛ‰%şàÌ°b|½R‡Ür¹ùl1Ağ#»Dé.şQRr=¶+…::‚çÏºTòNhÖs`Ï‹I,"»¯mâ¡;kLí÷YÅÎü>ˆ„Wì3CyıÚ,'ıé®Èû¨C2{p ©nß–øMï®Â/Í;]Üç\£³]¾ıRZäRü–]XrRİ³ÈiÇç»ğk‡4e¦íŠâ|Ş Öû ’¦ZR»dmw@«#GpÈ¨È–2ËPÿ9ŸM ‰Mƒ5ì`Yî.å76ÚÅn™wú!œå´oÔt9¸ÄÉj^SÂX ÇıLœÿèÉ«	ÆÇè×Ç›üzi“®ŠE±•dâ?j¾\ÎÏ3'ˆC Ósˆ®àü@¦.éG 8	“Úæ×+‹‚öjµê0ã¿ôÄÇQÿ•cìíku¨Èm·óTDÊ-€ĞÕò()kéã)b’¤Ê¼Zôy—õeE	•Ú+ëñ¹èìB«P*½Í˜´EHÔÆxPs\É¯ß1?DÖA‚èæÈ_}bVÕ1°<ƒö»®xÀyŠã<ü¡_ÜA¦X;5Ò.»ºSÿø!ÇH×óÎğÎd}]YúÆ=dhv¸w‹{…ëï´ÛLštä,ÃëuÿÄFE—“^¬%—|—Íöç’[êúb]p¬Å£OÀÙ°i1×Çëu!¢®œ‰¯}Rì`fÛ ĞZó y;zß ?’Ià9f7ºgºş ¸ÿ%¿S úÔ¿Ÿª~ÈßıÛÚ‰¦#ÆĞA‹„ÍğŸ3ªté§/Ñÿg6:Û1Sú“@zæznÙ9ÔÑúêkÒŞ’eXQÆ&`å-N/)6Ôí2ßa‹˜‰/z}ûiÇa˜:ôbˆ6ö¢·œdCs¶ È/ë—*T’å|E´*ì•%vÌìæ„^,ˆ~ rV£ Ÿ÷Û·[\òXÀ|>•ÌÓ}Øá™öF¡iTMÇ‹°»×µÛÀu`KÕHriÛ™ù+hFÆU¯+äê3§b„¬–tàÁ©´VˆeœÚãà¦ÎZÿFˆŸÎT>îéÔ°‘í»PÂõ²*[Ã|Ê} İµŠKh€y4u(E4#–s¯Êí"˜£›±s ‹Æäyô4F£:¼ nŒ^ÂÎk˜ÖÌWE­4{½Ui\†®]…€R;¼Ò^01F:Y0V¥—q,¸`¿õ|ô‘ÌwÓñÆªÉ;zpÛéCL‘pÑºúécğÃèõÑ¬¤8» ’FdsÑ"êÇ¿õFù{« ²O’Dšk¿z¯yna!dİ%¯Íç«Ù
LZ6' D<Eê÷î„“/w°ƒÅz5âşà¯@rGƒÀ¡‹œ†
ƒN"?+÷Àl ‘~:wİ†Ğ4¸3»­1ÂQª;ëäC€÷m‡~`ß¾¢‰7íÒ4XV–Dş’Só!dÁ#xöœ#@3ûYÊ[e`ƒŞAğ–„uÍŸ¤†úÿÆÙî!ÙJçÍgÚ“×ÌQN. BºqfõÂoÂÎÅhI@$%–ì˜°Çæä\İuA¬§üh¹àÔTÉ¿“ğwéÙ%8×v©²¥"ıJ»9ä56é·l3£„é“ÿg¹Då–à'&Õ$:¯­ÉxóhN%ÌŸu¡adÍYÒÎ¬0®Üı”f•D‰À£¨Ö‡ö}©T.¦”Ü0;éj)y¤Døáı_W&õ@ÉD[°Âñß$MDh„ÇSÛ¿ÈX=ãûfÅˆÁÜPÛwnKH$ÉéÏıÆêıälÛM!oWx9V™^!}›ü2cfùN¬‹b&e¢ÈPUâk\©›€jéç¨îÎ£"ºÎIrä`ø*#ƒ`Ã9BÖÈ-ÿõËÚ
‰7óµNÓ[6;8Š€ìY•*rST&iîò×Õ‡pŞ,«™ÏËœ–ÿ¶ =s|Zõ‡}?-”˜±bÖ{¼z·õP?>,Â#vØß"½–*¯?ZÓBnDÂò>ÏÀQH¬Õœ÷‘¥ùqºáË>‡™¿ìÛ¹%ãĞxyË€Éféëš<¨1ZÈ5KÉ°ÁÆ·eoÑ²7©€Y®‰eHF¦~3Fp¬¨%D€ VÆ=Õ®LÂªˆ¸†ãá*qŞøäİl ÕÊÒØ u¹Üª¶©ôb÷`4˜œˆ(µà¾Îoÿı™û“UŒÆ;/Rªt¶¤½Î‹Gq"³Ym¢Õê®–4ƒ±y	óı‚¼QŒ>ĞyïßN$­ Í¡âr³°lÉ_&/~Ÿ½,‘ËÂ¨x›V]DèÈ+Y#?”úã›KxúFÎãa‚^Aû=í–¡ZRÍ\ëÚ°·ÉìŞ=
ŸDãø¯ä 0¼iœÿ>Ë*äå¦äíÊ•'”ÙÛ«ÉÁnà‚ÍôÿültèòT‰Q¦˜×KÄ` Ş9+ázÈöéë,\xS #cã‡‚9$Û]‹Ô€pY¸È™áPóú¡ÔÅtvüº’BXp	_B€U¯è£½²"ÓWKE½9@®ï.³% &´şRÿçğşI8û†ÁzÌÂó¯7)%+†2«"õG«*?¿µFõ¾GïÒŸŠÙCt´«D’iŒ¾Ió\´±U½z¹GG –uÊiŞ|«FsGÃ~&İnùa‘£qèê¬CLDşâ¡L>–•åÆ&4ÃÛ:xÛôpÛvÈd›†ö‘Ê°	+ğƒœª™­«WO{¨‡J:¿°ı¹lè’–Ø¸d4ñ–—[øgØ…˜‘#”Hm¦"?oŸ©6¿‚9Bú) í¨å]/Ï}ÓËıÏnÿ5ù.|8ß‹xúª3]w„lù3.2èPãæê2‡¥sÆ8ßÀ$ÃÜÿtæ¨†e_Œ‹Ÿê¦Œ!–PTşÁ¿B®Š´HS¶«ûÅ{Y l­9f€3•WMÿ•x9?G&‚¹²•Pçüp™E¤’DÛŒ°fĞñŠâ¬Ç#^+w´Y×/+hAht9[–¹rÛŒàŞ–~kuZß§ªüP¢ğÉêœaÇHÅs-Å¸eô'XyğÒ ¼iòõ	™m1ÙF²© œêìĞë¦hbA’çNJz‘“Ôİ*š­Ë­ü#v?C¡º}W5Ğ¬p•Œ˜æƒß[vI•Y³=.¼öÁØŞ„ÛŒŠ_
aß
¤-¸ÏÛ¬o=Lt³!%ÁdSã×`¾·1,´…ËCz	%ø$µÀåÊø½œÍ{6 ^«ä`¾ÆĞ†¶«ZÃä3ò0•¾Ô·óÌÊ:Xñdû-5Aé,ûÀ<‰70™îº	H£
œ9F3¤éÃQVEÕL¼Ÿf ¥zóh£¾¦›¨eÕsÛ‰MZòC
µ[Ø½Ì/-ïh„wãfÔå—b2Õ¸’ğ•[ê`tû\©Œñ…k7Pè_sMâˆUİŠÄˆÅ!9ä+ÜâPşbÔà¸8³¦Ór;;¤õâÆâ6	W8ù†<"´Ó“€œPØây7äx`¬»:ó"¶^Ç”YÌ²'¿È75§Õ®ö4¿ ¡#Ø|Xf £ç®2Ò}êÊ¿eÃv©Yë ÷øÊešìê!Éœ°Ş®ŠæóWRVw9FBZ>[øÒë|2á8^vÜ¦@ô^¶².2¿ìáuûKÿk§“‡>zÖ¸Ã’‘÷;‰ªb
C4YÕòZˆüWDîgïXB+ÊÕk Ë ‰q)È4÷P“¨•‹]>›u?Fs"3w—İéÕ”ßÀi‘ãuûã#ÍíypŒ·Ë¬¸ûH geÃÜSMÒDı’ &†ÆkË°újÅ^s%˜Y«·#–ıZé¥Èeÿ–"ü\×Ù=«½Ê²S·šÒ½>ôğ¿Èf]ûì¥ˆ	F‘ãõ˜şBOëŞ¤VG¤¯îĞR…Î"queqş¾ŒEn¢˜-îÖ:Cü)N»”ÿÒñ=Z…ÖÂ3«]¾oÈc‡°z™ZşPİ “AR¿.J½ãmá°ÏY	ÂO¢Šµ“d·Œ¤’@^kÜ…¡;ÊZVP îæ†ÅmÜÙ…AÀŠÃ2€IÅö¢ç¶À‚—<ŸÑG(ê²7™C(y)jle2TEÂ2ÙWxc˜FÏàU\‰~(Á×.°ÿã)İ@<Ñ«"‡I“ïÅ}ƒÛånıBòÄcoær¢šcïi<Fˆ²#2…M¹;B%óléüEtÛƒ¶¤£¦Ãj\4`óZ±@*Ã§†<"0ÒÕ„eÕnN¶ıµ»«w¡ø.§evu„Ö/c{ñ5Qÿ…BÃ:r^Kõ~³|ÇBsØ}C),Uƒq°¿á@íòø
ÙúÁ)ÄL¡B7È÷˜H»¹âÿm‹ªîÄ>îûzıØªçô¬%tí(Áÿ.ÿl&C8Ñ`yÏ±±æØò6•P¯EW˜5ôEë¬
úPıwtüí¸úq•z"ÒnWôZ2N#d£Õ¢8¾µ;¯,Şûe³a—< ü¿@°»G‰Ãô÷	 …‹/+³µKá÷PWØq8Î†¼
½GNË¬ñÚ©§Ñµ?äŠÚM449Zé¬ŞÈÜ¶XŒ
¹şÈZM6fìçk#
•©ãYDÉ1h˜dê2ÑÊ9”Ä•F”…cˆX/œ· +CA#0I6¥<;OÈy+—Pÿá`EnıqÊ°‰-7Zú!­k	mâæ>öò;ø6¾äÀ%Ç¬œ’ï´ı¨ZIæ›ÎÑ‰µÒ0ÈÔË4Š¹±Ê´
t^˜]©KÔ¹8CùéüÉhÏ0,ö?ƒå1œõñ^LÈëNŒÊª¼mÍS’Xª‚Ö¢L?í;ª~/Û/Íô{î×X¿ÊŠ«r1Q¨¬ş
/ÄÖ¥§Öög…‚ÔîÙÙF|£¯îi*Ùø¼÷ÆıÂ5©ÑáfK×”GXÌ®**ÜÓ®V;^–õ·òÁl_^­ hy,E„¨•L-B=vqäÃ±Î”EQ[srzY»±MÑ’Ç«Ú;8©(%Œ/}•¶&)Å³Y£HÀ,/ú1òî|rrÉ<›¿òÅ•5–O#gĞâì¹JHí£üY,—ã¥]æø:37/á™ÛŸìV”1ÛÇGºØ‡øàü‡“u$%ğ(më–ÙÿnVIâĞ¹äUeXjúZçvnÚæÜå‘µY™2™\Êşu~~Ñ HÌRÑßÆò-ÀĞÛ¢»fIƒ°ŞMƒ–<l[“»¬X'*àÉxÖ7äaÂ?ªÃùî!¾{‰‘¡ğ$/{’Çf?`wÕÊ>­İtxÙÁÓø§{ ´àİqFüë+†ƒæÍì°¡™ı3çÚ.S²Fu;­¼‡¶YD&¸æUîäùEA¢•ÈJ*5§Aï,Vf-¾rŞ±N72ÑèÌBİPŸ•A/©Ejh×ÈàÉ¡ëiÏ¿‰ê]"ºÈD"ƒÕ…ÑØÉ0˜1ºor!²±oDÅFıD¨\n'YMJ´] .¸wxUËÒÃ1ltÒ/@”BOí£	~'¡‰Í©jƒ+t:cÀÿë(Œ3SR xWlâO\"
|Ø¬Ö„Bú™–‚Ôúá"”ã™¨G±×…P€àb[\Oïğ·+¾I§ïş.ô‰Ql”G¢ùíÑ%P:/şÈ"×DsèÆòkş€84îˆ-Ì”Ñt¦Tú÷4¡Lj½ŠUR†çb:ÛëÜ¦‡,‰#ßS&ëüì¿ÖÓ”:Ì›`Ä2$ºáKı1AˆÆ•*äÅ5T4tdH·v"8*R^¾$¤ •c vÍlæöúCìØeÚ=V„½¯q´()é©¯…)u‡¤YÕ¶Yãó4N9ÔÍòc½H‹œ³ÒctÍLÓğmĞxÜæ(`Ã¬/·ğ—t®ÅÆ?µ…Â“ÈëŞc­ºN)ğØufv*¼%>¦Úó¦€7ñÅ¦3¥ª,#ñ ŞÂ1·]÷9Äğ¤¼úãË{?azgaš¦o??}¹=Sb zû@±À„ı‚£-Œ!$‚kÃæàè‹&%;;âfÒ/”¬ç;¥¼^‡Ù
¨Å‰šÏ+®N+K¡±×v’ÊÌ# -[9î`êÄ­cŠaå–.€ÛÉı›Ó€Å—Å!/ ¾¡g¾‡µ'¸‰rO—…f&ÕÆ}”P¬²;ˆâÈ1àkáí¹OOLäxäôkQv¾¼m.Âx©B¤;KcôöeÍ‡d“R=@{8õ#Ê«+-¡€2·2ú:ª\áÉ(Ì¼$ã@¢Ã˜la8×  „«ŒÜ-ÄI´W‚*Õş$öJnjH¾w˜Àà+~‹±©¿ªÈi.µÇ(äÉpEÓµğbïW‹`¹6‰IS Ên6¾3V¨Æ N÷5“L<N‚2R{T)Ou½RxVÎ'áÁ3K3­°Æ|’¢¼«YÊlB€ÏLq†ú‘²Íÿ+a?A-U²Ğ	í³Ú‘Å1­ÿJªq«İè	ÀÄ9¤¤õ>ÌíĞ-GÔ1›¿É}Q^èyÀEæFÊ6¶‡úQf)×¡ÈØXó,¤OGÏï×PyıûmáåíßX,Œsoa´'Üå…¿fS¹Û§HÃÙ¦ŒÏ¿®47¬ôá¾Aºˆ=f{pŸ| oÏeM
Pªxl˜µëpxW’A£õÃôkôÓ7©bÔ&À¼èİÑehc¶=—76Uñtô½7zâÇ4 ¸;|tzézÄÙ•“á‹«„‡èöbCDzˆ6ƒÈ*ƒ¼_X.Ä­xóbA¨~w€Ä>·í(GÓKTD¥hïè~D´z÷“+µé!.e=éšÇÎCÿæf…Ò–'=ÕfômZ•í†9e~‰ ¼ªÏUÇ_¥úİô?Ù%ÛÍ¾æ¬4xmú³™k¯şV»ÉÃd®Q¦ÙGXoKg#:¾’¢Rf¨«É»
]fš»uZÛqºéF(5ÿ„œæÔùÊ:f£G ôÂ—$èÁ]Ÿ}óÕár<4¤\Š£3OçL£% î?ÔEÊ|ˆJTgôd
î†+Ó*4ÌÖ]X®–ô¬Ì·VŠ]æP®¤†¶‰ºTºh'dÙ#4pc›ÉV6´
•ñ)8»qÂpWUŸyNS_õù==OÄ?Oó›!í©.¯0ÊaŒ&¯Øk JÁ¨¡¸Ì}Œ[7´?­ró4ó¢ä¼‚øÀ\^µÉLK[<1¢šdV<QB¶)–ĞÑ=ê¸İ«9ËY@#*ê»ïzÎlğã¿+X ìÕÅ3¤hÃí™>A\G!¦2;ŠŸô_/ÙßÉ‹Û5æ>É‚Ô;G¹n—uÜ%F0o^‰‡˜ò†è·È·éôFgùÜpœşt	ˆªât:Ït>p‚ŞíW+E"-öxfãÆ¥›Î¸#'±°‘i%µV­Í¥cÅ‡¸ÔK[!Ü¿À®£ ã¿ù’š?)Ës[î}ˆŸ‚üzNfmô.\§yÍ,JÌ3^‡¿v#Òf\Py¦´óÅ×èc¿MBÅWşÁŞ^ë——o9Ê[Æº0æ½·¾/ı¥Z©?G¼ÛTò9Ğ
:ª×ÿh4daÁæ¡z3Â>ÚıéÁ-XÔm.„RŒıè1I€o^Èï€ $dY:¬zÛå×İYŞdğéP^“$DÉk,ÇrXr Ò'ê‰\ïŒNo¿0Ğã©œ®(½níf>ÎgdjÙ'‰‹ ø“·îEĞg‚·éDæ›UWJÍXebRêˆt?ú({÷ğ—Ü£¸9pƒí×8íç·ÊÏt7‹7&cÔx¾)Ì;îW Cå †½ÊØR|$‡Ğ>øÄ\¹ÀáˆÙ[1*}æİboJ-¡M\zÂäˆ¿Çˆ\°}eÿ×ÑÄeC€„g„ÆPfÒiÿ¤AÆ˜Qw\
ì„ÉŞ$ı7÷•²CğjE®€U€‹K©ã²¼'ôx¼ t£x»…Re·BøÂá\™Ô;±iN¶+W¿­_öÙtÁ×—}5Z8§@8;F‚êê­W…aUıöoŒéo_‘¬«D†Æ>É¦¯¿F§
äW¸9^Qwå#-b@UV·Q%¤‘÷«@Ü.¤-dÍO^‚×Ø'”á•—÷ñØx§Ó¥÷Š0åuEZHÄ’–Á-o8”*îµÚÅ3…~„•o™×18áqÚı?š5¢|ªi!ykÎá¡ÑŞİÉ{VÉ¢Mi¿üĞ6§^!Q;¶¡Yof…zî]–¡ßtñV4†1‹jñÇ§‘0,°Û“Ç™Â¯Yä«( r&†¡W@ ëv,İÎ9İ?v	Wßõdÿ‚A§aÈ2ƒ>Erd©“¶œÚà„”“£òÔi:3€§AèàÌzàJ¾ìÇeWk˜³Ú¯ò¸µ¬÷)Ò·O\(Û^WpV…Gíw‹5AvùçEO/¬ª÷	5á p`õ×œñËA¨=ìœ‘ù©¤îO6À‡¹y›5•¸“µµlFÆ®>uõç¦v÷MûsÍB&™Å0*\³ÊÊö”ù÷²9*¹³Í<Î—8i’¯cÓ‹ÉÉR1œÊO¥&nÁ"8½mBsj¹Óùùõ×ş•ÛºU’¼Éòæ€OíĞ½ìS”îæ´H‘vc¼up8uH­Ú‘“2¨€ÄuPûcöíl'÷@‘bÇß°c¶£sü.Ñ-'N¥œ,±û}ÉDœï·³+Ü#'-"]PÛúyŠşÍºÔ Á°­B:ÿQ.4:ä‚<3‡{k½<W¼bòKç£`Æ7l;™2X?Š	ÓÚh4®÷T™näeê:mÜfÿşÆÿ‹¯ G
Ô\åÑvÅîÃ¤_‹ì®­ÙñşóOúeœšÀë"§^¼
Áææ®M¯!±
G~Öğ¾gñø)²ŠiˆúÛŠ“~%#Å92–O°%Åô<ı•^¦İÄ€V¬Óü¸H©lÛ¯ÈB!ÍíØÄfùÆƒ·±'–³«“ç Ï¾ÙĞß„ Á‰hÿõ"’F°ŠeFF¥‡é;…	ÉH‹€8DFeº]¡Ù˜™< Í¡ß¦(“,¸%IÔZ¨eh™|/P«½×Â#²UÄ¤ÿc'6ôŠ‘NVá©	ğ<PE9µ·áÙ%ßÎV“´â	Õ{ziO
ãËèìq0¤mè²·ßª,áÁÄIşÚÇI<¬ØÏTS«bÁ§WØÌD¦Ï‰Z;Ùşc$¾O[54òÅ—Ú{ş¤8ÇÿYEkoöPõc)-_ÕN\IóàÁ¦CÉkâ¼ÑHÓgÂ‡ë±ít$dcõÄc02ŠM†^åŸ#›»ƒÕs+@¹×GÿÊ-{3\½tnÒg9‰*ì*¸j¶1æ¹şÁ<|7k¢_âÂ”Æ¬ë~¤.ı|ŠxYÂWyGÕ¼M´iâÌØyš$²øîç'}öa¨£YİªÓI2”^¹Iã™u]ø;c-i„wÂ¹nÂ(hm!_¨•ŒOÎÖ£dÍÅ—¡†úl0Ÿ„6âY—±Á&ílûŸAĞ”6M¥º¶Ê6û›![xMSÁV‰°.Ëe½|XÛ–VêÔ_™&`’kŠ>hùDWOïñÇg^jøÕËÓsšVşÒ8ß8J‘™¸†¥Œ@ICÿ‡øè4Pa¼ÁD÷è›­•g7è8¤7¹yv[·ƒÿê;x$oª‡€§TÆÓüÿîşS9™xßC«Ğ]}ãI²í«n¹ËZpòyÒUËQ”>6Ø üXæ@¢QÔé‰Éfú—g¦ôóÈ ££ô‘`­ùËB n³£å˜u÷V>´oÆñkåz¤/¡Š,·ñÌÎÎÙ]t›°ã«ÕÿÂíhÒ7JìØYÑúªáOiNÌ%RÙÎjy¸¨‰§ÕU­1JOJT—q´`…Ş(K1GÉ¯¹ï²â”%--ªy÷ìğ…;Á KªÅxÔ—Mß§NÇÇğo
ßã2Gû5;8;A0›VF¬#£Ã¶é{Ú¿,“• ï4c7Ÿ&ÆĞ¾¯7ÍĞüÄãEA88Lãq`µ@¸OüC¡ò^rH|î¢¯rìø5[0k¨¬I=àbv6¾[[u‹+dBÅ8r]Õ7ôŸª+{MŸ(EN¤qsã:Áîª†ØüŸüDfï£Íèm•]ƒŒs#’ úç±ZÔ%yBTynmÛ•Ô³[ĞÈ›$(©ãÉã5î&ÎÍÄß(rèÔ­Å[Á¸Æ©xÍí0•6ËÍÊ”p\²ÄpcMpÿÊ?gåÃ÷N™bı3„ø ¿ˆ_Ê«’>·Ü´ï<ÌÆ‹O/ánª<Bğ`9ø†¢]iŸ2ƒœ{§™®6§/…=6ÖY)©¦â±€“/iæZ(„šnô‡Ö®¹O‘×<Ä@Rûğh´äˆKêpĞÈÀb˜÷Pº1z6¥KÚ·â§±X¿ØfZU?PGÖC¯|^µåpÜqÑÆ›ùäº G1'åInÓ¤¹¿â4v¯:ˆNñå×Ïşäš¤JÑ\òô¦
zu9ßçCÑà{Ñ"fSÂëÊİÏ‹PyŞn).à-ÈÏ.Gı­B_ï¥{1buæ°Ìb¬Cë}SÒ¡VYlGC)Æ7ı‘d 8/Ï²„¬Äq:OfØbÊ®%’Ïw•ñ,_Ö³B<kö×ÌR2	f•5]Ü	]ßsŒó²mƒÛ½‡Ÿ"<j"aQMEm5kÜûõQ¯fßx“÷çÜ«ìg¥êŒo¤÷×'9¯hÎîØx7y¤'™Hy….¬±ÜµÏ¢Î»5¢q#^øZnèQ„54h©–• P¢¨æÍòÖL¡öî*ƒÜãD6jâW„QÙæÆ'´L‹ÇÁçñR“³çD²£ÓKSãNÈÒpÎ±	ÏËÄD 9fØ.<ÿ-|´ÕôÔºÈH¼YªÓÛEeÈe&?!¾yŸ¶xl|!µG(†­qc9xèó¥¥îF£Ş7¦âx„„ËL±/òxq—£Ğ%†„»›ÔâÎñIxZœA„ô¼É÷×£	xK‘Æ¸L–gçúhàAew©¹g¿-@´fvµLs,ä‹wëÒgrqÿ…NĞ²B$[X‚ÛØ¾êı÷ÑøæBMn±gçÅ¾†¨`¿½GA•šfy†»xµ[«Ä²)qŠ¦'j¡›r6J%@úŸ~û½¹ËÕS'„4Ué[0›ñ¥M.äp`¦•kÆÿÛ»&™EJ‘—bğ[=drnÜÌÿ4X¸y9;~<äÀX¡Új•a›ÁR+¦Gôöã»Á¡{ùûs%ofØ#•´pt¹Şê3‰äBævéİ™Kß#'iû®#I}™â	#ñIFù½g#…°‡z¡«{@:H÷"Í^’[YtÑ8„!™fÈuÏñ/İ²	3´¯ã¼¼‰RÙÀ#?; ÷enÉo€Cç5“ğŞİº£†šXaâæ—×(¿6õ/BëqŠE(ìÜ£©@a-ìG˜ µ”/	©Ü¤vÓÆGd\«Á±ƒär¹à›Y1Z9ÇòJ+×k;”“°%
s"¡©È7WCæ‹şàMÅ¼x÷€s4D¶+ğPTX¥U	îx¢l:WŠØ8é·œ*²¯X8‘rciÊ!T•­®Ó)ô—Déaæ»Uï-9kæ™?Ø«½¢Z=Há¿j´p× 6Ì|$Œ©®|@fÇŒ‘[§fUêÑ°ı­›"èÉ¥B$bÒuRü"7Ú?¿lãÒ€ ¹=îyüØVœçt¢ú³DzÖ›áG 9,3Á¹É~ÎâVŸ—É“ ¹8»ı¤Aåo 0¥‡—÷Iî÷—šc¢K0[Ÿ’æ‹Â‘†Á?GğGb«n	û[2+8Ìüá,qyÓN˜U±UÊQow U!{›Éø’>;>í6–YÅW=‘‡ï~§¿P+G¿¾p8jô<o3i£˜&#*ƒâä%»å['tÂ‡Rq‡W*Ñaıqüå`G’i>g˜e¦õ«šU<Î<¢Ç,ğeÛÊ¥“_‰b¤i	îÉjUÁ§®§]§õ¹œõàëò]…]¡RÚ0ŠäU—;)¼d01.åRŒƒ/Šé)%ÍU±p+gÖ¢…~b£¾³XE5™_ê0ÕŞ¼Ó{É3ù·/-g¸9³Nx‚œGÑÒ0$Aˆìqc£®?x–¹.zf;8ŞBÃêåìã±‚Ô¬d`3'‚kkFméã+1´±ˆÚ´vQ;/Ùî|›
ç·‚jÀÎ¿ÿ_EÄÊ!­&K%'ÇŸ«Ñ¯”œL+u¡ úd×ËFÙ`ã úŒ£´fwÎƒAXÛãŸ?FnC°Ç¬Ù-ùñÚ æq:óÔ…ó»ƒIÊ~tQ÷§0Ö$íğúbÃÆNm,áÍÄ®) §[Í´-+â$C†{#€D¶•7Èg6[î
°Ôpğh…K+¹9µk#Á®ÉÒnr4t*âVşáé  ,oS¢^5Ğ6!Ö7sîCX@œ¥Ì ÜÄgúè«5L~o×½T|cAtm–ñOÜè^LÌ‘Y–‹1Ÿ˜«Ó1À¥´M¬š
tâbp­°Ì]~ÕB+i;ƒ“]Çæd¹êK'Ü§¸–ü°CHûí£lŞHOè¬–¢0À S/)¤¼ ¡»7~»è	$6mNMzND¶F„çM[ûO¢7pl~ulië ïĞ5o¶·Ï£©r¾cT"õûd~1#Q,É.QM²±li%ùQ—yMA Ö^ÅÍ›ä@Pâù?ÍUà‡æ
¨U‰‚¹MI³T¸ã7‹"c+q§b6š4N¾µ0K"Qk ƒ	@ÁRåŠ½è6'¨d’ö!Hç hïo[Ñ^Šèr WÇi(óuuÔ™)ÒqFBjÿsØt0“×:7­V)¸Í<Â“¢›Ì˜Ké³£ 0PUP¥`TË%{"|ìFƒ‹mö¦“<g78	`ê¡ğ0z_×³"æÚôt[yâ°ğeV ¾ƒ°µü°:+İ6³tÚĞ9 ë³6ö	yĞ~Ú‰Ğ%l–<’ÚÁğ]|x*Ôn¢±ÕëÀ£;pÑ?"vŸ—x°(¬N7¦@E(ÇÜ,“(ö1¡
lŒg¼ªEÑ\®‚ù¶$aÛw´šSÛ„>IñÎ‡çš _T6°?fÂ"‘^LyÆJˆ+œ2mF%dÿJ O›%vñº¡B†é;áß¸Ó»è#_ Ôù¶¦t;m¾C>”
Ù•
‹‚2âT=cwÌ
M@‰A£>Ñ)óT¿êéäº\ØåJz„ÇŞsÎ²`fs:°
€DĞüàÆ«ÔÁí¥%[w*ÊãRĞ,_ÆäPÍ*ëÔ—¶éUf‡´¼ñ\_İ¶àH¸èïc·C¸ˆATÒ€=à†atİjëÛ‡Óuä@p8M„N“ÊI÷Tƒ	B¹ç^2(f¶ıq•øC.Wî–”åØ°ÊÄêëb  §Bñsç§ëãé$õ‹ïñkN¥Uÿ7ªˆ6<"ÜÈFÜ‰0Vv7MÍNùAî´4f¬£°]9a…^$šSCgSPùu=,Äsìß­ÍDÀó%à6ãƒµ`a9boèlÍ3Ë6ë^Ÿ9êj{)pë'ÃûºŞß7åg¹e’`İğß^fÜ×êÉ¿eé~‡ŒZ‡¬<ŒJğL}–ëı'9÷ÊhuQx=æÎ–q b„fÕ¢T9ım\¼<´Ï_6uFE÷14ô°»õİÔÄé=?r¤»•3„Ğ.¸Úì#;yÈ‡ãéÌ.×IïÚãº_5õµv*şJ•h«zÛ+iV "%ğîÌmD“§¹yı+1±/I.Ú«dÂëú
aihİõöùLyc©yøÎ
é£¯1Æ;E\ÛF÷4xGŸÚ77*í¼¢y¿ñ‹×áÊ¢ççƒû"‰a¶{_LØ.ÁÃşCCp¾Ğû©@ƒ‘–K—şÊ›Ò}7 ¥¬–ÚC3Z¹p.ğX.œ´ ÇÂr&ªÏ(ıŸÎôk¨Ú¿€îŠ«lJJ^•¡8_[/–ŒÃp(\í†Ö9”ÂšLr_ğ£%i-´qÓ‘(›\¤ g]mËò‹¯šº”‡İ¿­hTà1…×ışõøS„Gœk¦¶E
œéOî0Á‡i¡
Guí:«|bjjGhÿäÔºü{ÿxÙúñâİzÑñXö’œ&øŸ?]6ˆÛD€™ªsÕ]$ÔËğ·[‘{¨ä
Á
TÎ¤‚«Õ0Ì‰ÚˆxûcÇÏıc»{|µÊ<„šl6Éİ2jiÅeû¿^Ì+Úï²¸M¥LŸ9É^´µ‡×°H“XFÊÈGè»°_¤’‘ÓÒ–¹ZŸ³kâ‡>ñ¦7wŒDyhLi©PIÚçºİnïÇ¾lXbò›z†J¶fwåNšüÚJAß2S´îñæÛN¨`ñ^Ç„>İÃ­5À:We,"?(e¬ßpÎ­Ä®f,³EsÌ`
ÃjÏõÎ¦Ù0"Ê;C\QK‚KÍîZ~¥YïkE§XÈ~‘l½ÜRl¾Wü{€ƒgy-GÊËp®\üì3­Æö76°Ù	.½Ê´´C!‰‰O`ô@¶”ƒ×Iw\ ½ş´iUJë[Bf¾"7òÙƒì²i3·°0Ğ$ÿ¿|
g2  Oû:ÔÄ»DÙµ5ºûğ¦!–~Dì}2P…‹#>lÅäè&E”oaßùÛ´3­ÎÁæ›Gõ‹É˜ãK|ö¿)Œñ:€<D¸AON2a`Ñé§Íò´j>xêÅ\¨1İ†1ªâáUø¬S†}Åİ¯ÛOiµÖ?ÔT!0©€•¿UÙiâÊó ±zi.Àè%PKM&ûG[Ûuó¸²®âB¤À:öJ#Æõóúé	N[
¸·ÊªSêI¡ºR}¬Ä•p]³ôçÑÚpiEş)ãê¼éóùA£Ç)çÌ‡8†=E¶‘>İNWºiZB¾ıVVØ<¦Í"K(†ÄÍ,)8ÇÜ@öY³,ƒEï¦ÙıÈ-é»{ãpfYÂEöÉ3#ê"9nKÿïÙu‹Ä•ÙmÑZ…î'QO•æ2ñü+˜¯0B½@4I’.±‚À†( ŠıC×Í½Ö”ûµøûZA;iò,êŠ˜!ÿ$KÖx‰{§bzmÔoòNha!a›ëÂXŒQ×(ğB£°YÃ…—œá&Û–Ø“#ke^¥{X+röÂae@üËÀ„ë"j„{´ó?÷Kö
qz6æQ§Iˆ’|9og]±;’'ğcğÃ×UñÑ2Ø®Ä¾]
czU))Á§ôq$¾aƒÔM§rîœÉ®;4E«‡İƒêëkc]`~á‘ãAiR]äÉOÑLwİ¹¨¡xÄg*È0öİ¯,ĞÁ×t’é~¬œk˜è>ãbàrıâSøæW‡À$‰&«úÙ¯ßrFµ‰¹“ÙÇ/mµâ5ø¬ÖÜlÎ±E¶JìU;Tc0ÊàêB-¨=06êØ’RÕèyŸxœ-Nºy¼µzğvHºíiªH%[dK}'ì	KÜÚVFúÔıš¡A–oMz<vÜu	•VøgªBÎáöƒ¹"7q:¸Ê9'‰ÍL}T»8•šwy®›j`Áá%P@?¿D­ZiË £ñJ•Ò6çSl×}ÒÁEÊ'ú€J{›S%™Â¹™Äåéo Ë*©†.\n¿ÿk/Æ8±?Ùcâ- h˜)z«7k0N‡ä®şÇæçÜ&ÛåÉê|Ç´­Çèëøt,€6ğ|:‘Ïjú­õÁŞú‘kmì.e-ÂÖRÆ¶å8°(ıµ	®†d®b%¶³¢iê,üÆJ›’Bì1ğ‡'©Õ¨¼¦ğp•[nK+MzL¥éUrL‘ÏéßÅ»*şª¹SrÊ×Xˆ.û“ˆĞSÀş84·€·½-›ÖÓ"›mJ“¡Òó4íx¢à–é¦*ä;Ú‡xíoHbËm"«Üà:’EïMŠöéSşş'0ç9³ÕÌ\¸«÷†¸ŞFm1<éÉ
,A’‹³0ù‘~}ºcö?¢ß:,ï$’s£Ş‡U­(‡K,Ûô&W›<ê:­ÍùêÓCóP:__ÔVŞ‘y‘‹ ©oñ‡Ç…`£Io8½ø.‚TƒDùŞ‘è@¹…øµ9B,:2%PìûkMBG¶jCá–e|#ta®à²çMH³¦œ„Lî%†¦æ>ŠÂõOç²ì ¾×¿&’ùÖGŒàÁ,éS“ùØ’º”GLS5ÏLéÁ&”ƒ®äø…bDQ8#]šeN"ŸpˆâñgšOº¹İSO±IŠqiôÈ‡ùë°®«Å‚s÷Í"FTÖd¸b¹öC4 ìêNÿn,–'!&ô\‰È*^×Òáá¨Ìh‘fA&öfM(Ş<œ\çFÒÜÕbC
"a%§cH_„ü¹'
Ş¹©Şïó]ÌI~Ó	å!H‹:¤··C
i\ ô,k©¶¦%^ëz¨m×£6U:Jÿ1â¸–I‰°OBQŒgoÊP¾Œ
œĞj„kŞÑ¼¢r«µ‰cjL»¡HíJı¹ê¦‹ˆ¼‡UËËBt˜İäJiê’x°¦ÈA@ß¼cÛCÒÙÊY®×á+ä½ıìÇËa…·"¤¾OÊ˜"êh»çrš{Åëèöä°˜¨]a )S…V\åC{Ş«ñ~ê’Úæ­Öæs©Ó›n‡]Ê~'û½%“÷Åj‰­p4ïlC‰Sâ{› }„”½p$D"q|´k&š„u´¥ôøÛÚET9Õ\DÒĞíñ(ÄíùQ°ü[9ÔÀŸXJe›'†Ûjÿ:œ.V€…8Âš9E5«æÍ¹'.‘UUßIay|›Skë@ÕK©)v3°h‡UòQ	 ¦>›jÆŒÂéâ¤82gãìÈºE~™zw¹«ª§Üù~¡âH¸o-Å]¯ÊoĞMİëºWÈå*¶­GKÎT¹ØB‘È>ú#½èó¤WÏj_!ÑÑä<ŠG•á'¿àK6í*xÃ9í0§ÆÆ“<—Ä"²ºØÌ×­kÁ²£;Ïw¤Xi:Ğ}Ä‹„Q*U¿1I#+©wêZ;-Rºµ²ñ'*òşl ”êY/q5ä#2ÔCéX‡­Â«`ºÄËqN×š:K%™àï -mRüR×ÒÊø.¸`ÈÒİ1álözÊW¶V’¨LÉŒ¸PÙ+p˜¥“”Hšñ©ÃhñXO²ÁWçhhC wŸT	_uÀ´ÿĞm|§Å¹ ÿ‰G›+Jrá¬Vö|Xk˜&ƒ;fÕlo€ÅV(wÂ›c¿}#v"yïä’2:k3F‹Ò£îÃƒs3@æ9³®À‰úS/r_«I5èW^ö’˜dHHl@ğK&ö@Ÿ²ƒˆ-8½ØçÛTËY&‚ÚiïM_ªÈè¦©ê…XUÂŠ"¸Eô¦%e·×&=åx©TC(¦RDÚ²®1§S8ë+¦ƒ?× ds@‘­ÜÄŠçˆØ]†í^n¦§z®ÑìÉˆYŠ¢•R#Ğ,Ã±a‚%ç};™êo!B¶ÚE!èÚT/{˜lºXeÇ?÷…ª—/ä8^ªÜ"`|¡ÁìüŸÀ)ßÜ±-S± Åg7İ8ª±àH¨¡§YË	˜ƒ¨P­Ô+ƒŞãV÷ê!»›ËA—µ8 'jtÑ0Y”D*}1Û Nï5"±äe	wšI¬k,eZßL‰ørÖ­Û÷Xš|¶¿ògàş*ŸşÖWh’è¡9ùÉëfÄ­ß9À61\t²NSÉzìÎ~bğ!Â7u¬&½˜áSÖf_^9D6vHÕ·±¡ª—¯I%˜õk®ó%7jÆ:Ÿ­­änÍ¡ÙÎ8Ñ,œ|À7¤tÿB"ÙQ^î,5*=zŸBHYUQºh¦mäè„ùçLÓ-ÑÅŒ>İôN[
›§öAá§å*­Ü5]†íO¢ÈLy˜m7Ë±”dğ[7œ×ËP
ÛP°«{Ñ²éÁ}‚°ÛòîVKñ~Ğ(+ÙÛÌ)í.8è(M„ÿµÏc¸ÇVœ¾8¥_%¿’5
ıiÏeFUÒ¡8m©tÁ¶”‘„Cï÷zgDÑWl9Ñ—¤6ûõ@!r? l×ü&óé+ŸƒY¥×s\~YRì½Ów@(nmDªµ”á×¾JôçŒëå‡ÈV£H2bHwrÛj‰˜ñ¥ø)ßhK>ñó½æÍ }œœEısÊ½9ãÃøn2Ä9ÂÍ”UH‹ ŸÂzt$s)“ âÖ°”ã«J¾óMtTı¿,êóô§ÆÇsÀ3‹Ÿ ‰!Ûé³6‰6«FD­f×iò” å	BÍ»±R;/*Û@õ¶ë‰å‚œÆÒM©î¶%˜ºÙßÆÅfÀ1ZÓˆ(e@W\‹šÌàùƒš\ W¢°Ÿ+ƒˆ4S©V_B@êH‹	l s;­}ø{ıØÿ¡ËóäJÆŠØ_ä»GllR#ñ¨·ÂÁ)2´$¾‡x*Å iŒúqˆ8a–sNKk²'„,I5¯1uu‘¶]®$.:Ş‘t%ú)^Êz[ˆYh}ÿ82ÄúãŞ•ğ€£‹².óE´
WAÿx:”g@çŸÉ‹.àIetÓabĞc£ÇJÃÙ9 ®&p×ö¥¢Nt[ş)D¯NTÎ½;Şˆ”T§Ô{‡5îµ<ù[£².ƒîØ¸ín™^ïS²©Şƒ¸¡ğ™¼qÄƒã¤ª"{ğUmÁSkb»Ô\¯‡qoÈ*¥# ¸Êè GŞ´ş¼ªæ J®ÖËJol´3V§û°}bÖ²±Ü#”½¿px*EZŞgá­Ê€Çó‡ĞåÔØ¿µdéÅU0OÿëŸ ‹9*¦ŸË<ì+wKàó¦$è.zÁ‡ÌVòm8ó>o‹Ån²3Í¡Ô"¼´Òà´l8l ü•ŠrS×šˆ>—ÅÑîCz®é‰£›î}ãGo¬¡•\‰kç$²‰/é0j\ÿ‘ ›úöM_¤@–ÜháF&Ånš"ì øÿÄ¢
äö×Øc1ÙæÜßœ4@ƒ€qcñre‹£JÕ×³f›áaˆ”n‹é®LÈíÑ*§U¥U¼’àÙ€ „\¡¨I°OIz–{Ôge6•àX 5ûĞÂTÔ.­
vbÙuÂî¥¬µßR$¶@(ì¡,Šä”šOœ41	Øì¸îWa1ŸëÃÓ0)ûé6	K÷øûğ¦9ºQâÇ¾7©8¹TµËÜ=öİûˆvÇ<şÌ3ù*›1‘q*ym°’…Ìuí;èÏĞMÖÉNŠ´é˜ş[g˜kŒû5”¯\^mÇÇlFƒ×H6g%ù&Î¸ßf%å¬‹öÿ7jg,q”4çA1Ub(ÀÉÀ*>!
&/üåÜD”õ¹Ã½L£MÎïÄ`ÇĞ±Š§Œ!Ş†>xğ$\Š©ÖK(¡©A¢[…¹Èöt%«¦~ŸE}5QŸ[H90´Œ9Ñ®÷›ògAû>é¢"qíğVeƒµÏŸŞÔLáüúGwÇóÉ4Öú?V”Œ7Ú¹Á$OM
KÖ†œ½#'CYUCÄ‘GÜ£7a. [š¡¦»ò‡útš¯xŸÀÄ~vOÂ¶léÛõ'õ»|–¬~mßÛCªÇëNy úŞÒ©”ç\š(ÙÖi]Cjòƒ-Ãı± ‡Å#ıÌx2ã›UfyYÕòtnØö×%_7LmjùÈ‹•Mˆÿmïğ	¶`gqÕ8…ë´)«g®KİŠzDÖ E¯³bQ…E½‹›>§L&?æúd<‡‹Pá¬ª8 j¶oÍÉ=˜
ÉÏV]ê°–]ÙXÉnæla¹z-“²
[W	9røeXIO»1pš³.B$Ù:”™¥õqwkN¢lıV­±l¹Ú=×È[Áæ½¹R™ÃqæÛìîk'«`Àóú¹÷Ó:·£^«6‡,g&S¿Ì›c)­“í-]´hëA¦»]åp9:ZEØ”Soí`Rç¤ZÍV«#O8õ¬ 5¢p¹2È<§‚Ã¨	¶/ƒnĞwãQ³A\:1²‹+LÏ€Ê½\´<_Ï¤ıÊĞ—túÕ{úúJ`‡àZ>æ`«¬>HöOXoø'ICÍô2ÔÜÎş˜<±—÷Ùçq©j!§-Ï­OPô!qÔÔò›¢½=]c¾'³&Ğ«ĞÙò&’*÷ıÚ†œJÔÉ}6+2ŸŒT|Ãß¨ºhƒt^nF]¤"şG° Û’æ†™öqIù0Ø!Ìğñxİœ-à1C,Ãíá&èÊÂ›=Ê½=ìNºÇÊ €^‡J™À+lÊ-¢èŸ ô‹˜KùæªÏ?Ü­NKjºãg\î®äp$T~ƒÙûfh"î‘âG’óÛîcıø#9ş÷¸¸fÃ¯à„è÷ô™ªâ“” ŞÕ ·¿ÍJüâÀ‡×•ˆ0¼ñ{–çÛ’xÿüèM<P°Y¡9{7ÅI®÷%#Sdhè3Ì\ €äZò¬Ÿl}ÉÎõöaşÇàÆ8kF›Ù£¹P£BŠô Sg¡Å®¹ÚÖÜ‚KÁ®i•è*3çi¥¶éÙÉ…z¨›ğ6T~—eL¬V`SÍ?¬û¢ÑõË»{€@I   5
pWœ^N Ş¹€Àïı¡ú±Ägû    YZ