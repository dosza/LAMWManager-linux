#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1103655806"
MD5="bb99d212a89d09ece86e3913d2e80e09"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22960"
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
	echo Date of packaging: Wed Jun 23 08:27:02 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿYp] ¼}•À1Dd]‡Á›PætİDñr†õaÅÁ…Kü™8¯C.orğI½µÂúqyø"1Ñê1W?æ
†°y&B[ÃTæô˜°H™(éÃ´3©¸xgkò,àg¶Z•.cúR37ÖdO†ıtÅšb7‹Ë?¥aé´WĞãe%¡ë±e75TNîÜ‹ÆÚœ 8g®Ê£=îIˆö“°K¸³À»4#Hox»pBæ×beK‰N‚É°7«N½‡y®ğ0Úì—îŠü‚üC·[ãÂk÷‹¡:k@ãao§9ß€Køff—*¶”*cÉnÍ¤½mŸ(şÒ>ó°p^?Š²ùÛòÄ¨Ë²CHñ¤ó{çuúŞuãuÒ#/#ıã	LıHç“úè×ãe*É°ëÚÙö}áJ¼`ˆİD~;¹¸op…‡g’œ¡ëıÛCiÌkğò¹(ûáÌÌŒÅş“w­Ñ	x²¸aQ´ömá¡xè0Q{¯j]ˆ…İ×šwl#²àŞ¿ÍÂ?ÊİIOg4¥òÙÚxÅäxq˜€¦éBÓ™DÛ>Wİ•ìäb°?Şj“:
)´ &ïEd*¯aÓõ1Ò¦ºÚrh›Æë?ÌÀU=š¿Õ|H°‰™ÜŒıbıƒl\¢íjap½8IízŞÅ­öGÆÜûµâW
aôø‚E…Kp\â;É‡G’¥€ä­^C–à ¼3£Ò²Ôä{Ôí²ß¨Q«ÏŠA/9¦¢_Ôös­"bvñï¥X&s•¶òÛF´¸ŒÇ`Å—ä1L½Ù<.iäsş6m5ÌZÀ£-°›ZPp@ª&›=£ÿ¯à=6d@ ÄWó‹‚Ô=£}±¦Z¡©wüÛ-³•*8¤l\«_­Õ)ÕÏhñf3ÕæoHR¶ƒº†“ÃÛO~©q}
Ó;ŸKm…‡<ä#¾ŞÆ1´¼–O,&Sˆô=tÜş…£l´AÓ‘zŸ1âgÿQ¢ÿxVD	0"•A‚‹qYæ=uŸ–	?ªLJš´$¸„%Æ:£Š3C;‘%,¬ÑTMÜÿŒ‹Yhæ[²íÙG›BCèYÂ$³°>¸K}ÿ¥@Z¢b­‰û	–T§°Ş1q5?x+°Bòà5Á8ò"¯$k–Ã^ÀÇè<PJ‡¦	x¨BıHI%É×m1æ_¸ë3Å«H<{U<¬Î}¢‘œs"Á?Kû‘Ñ5›rG}à‰/†µÎĞ{É4ŒÃï_5ê¸…lÙNLÜ¾]ÓœñKok,Çå¯x	ÙµYvS.
®wL¯z¯·æ ÜµsíÃO×²+û)ã|f€á"ÚhâÚ@Ş8°t;ÃÇ«s¿¬sr!ÚÖšK®Å²y·p V+ú´<ÓGëa®"¤Ò|l(6Ÿvg²kİà¦”\¾.dôî™bÆÉ7dçÏœÏ]÷ù¯Òİç€¼ä«:x¶,5AU!bëĞÏô=âlîb¡Šºä" è	ôúŒïO²Ó,ÁUZH`#Œ–Î)jGdAË3SëFåÆ	¸W/‘QH™˜. ™nS×mÔYøk¶Õ€‘‹œ×“	‡†
ø“Ï;Ïš@ñ†UzA#Äƒ‰Ç”)ËgmÉPï7Ş]}Ôì^:ø!¨ÿC/|¨”Pjá“]¦ÚD¹ŠúÓ'	§—Á™1üÿNñ´D\}‡±/6cl˜ÛMT[ï„sV}ŸÁ‰ToLà
;<*ÛªÇ}ÏÆ
!· ¥&÷}vËInèíŒi¸¸yéä{&°n(Ç†–À¶Ù$µ< ÅŸ<
ï@åä@eÙË)´æàìcı‹ì_.µãˆ^*Ù|³Œù;ªİ˜›Òù¨+»ŠŠ„—™5‘i?°/û\M›´mt2ù[½šzÍ…
^(İŸ]W®h+VÔZIÀş¨E’‹·Á¾DÀ(ºdü?^ôey’ŸÉœ¹lÅCŸ1™Ğeeøp=¥>Ò“õ»¬ß£ ßÀúÌåÙ–Èo»
ã1f×`R*ß“™‚g*	á?ø8Ä¦SY“Ó6Ğ¢3ñÍ*öf	0òI@I{F®ù5922Ñğà¿O¦£)0õİ[Qˆ>ö:±ÊVÙïGŸÜgYk$ı{Ñ·uÈ’Ø¡L•‰l] —¤BHNd¬¸jPy¼	B‡f0ÃRÀÅ`#+§EêgŒÌXØ*CîÆJlT7áİ¡_ A2¾°k}Q¤§²Ç‡’©†¯ê1¶‘‰ˆšG\kœÔKO…ısl±Fb›+	oqşôn<ù§İÚpâó"Qêò¬ûŠ‘«»*U2(g•‡HŒáúÜ¨*ÿã'8Ìå×NŒ“S¾z=—À}Ár±ÇÍåBAÉÍ6*^ÉùÄ.3q¢qÚV"W0ƒÂZEvh¦ø«F]¿P½Àvµ
mCVß©(0·:|D§ütâ<náaÔ*¼(;Tc$v±2Iş+Ó5QÉæ~ÆbI«_=­aÁ“5*Â¨=8¢=üD¤“c9ÿz«5¿Q#8ñkåáœcj&ß
ÛƒH³Ö¥LS½ßöŒ8|¶N‘íáÁC)&V_hø¤ÌKÛ+ÂÅ4íÑÇç¨îjöÖ,o/;Zí_¦:T6èû°¬F,Ørs,/ Q|È=ßƒË£Ä±h÷Dk¬Rk]9úd-|eÅ)İmôPÒryÌ¬Ûé¡›©ˆæq%ÉíÕ~güŒ¾0²,iî#9¬ZbV²ÙiÊüˆV[ëKax<Â^õG²³¤Ñ×Ùúšª“ÃM;SüÄs%~†€P	8ªHoHÛÓï‰RŸ8á¢S„®³ÖBd±¡p…ÎùÓ¥oFGÒPØZJ	_sŒÜ<ú4
FyTò…îxä·Qõœ¹u/èlÔŒÿdm×É9Anôê\õ/RÕ¦®ØÈ.Èºl6˜M¸UÙáÏøËqĞ„
ÑzGsÅO6µñ¢¼¼ÈIL•íÓL€“î÷—¥ÖÜº°	}¥ôé+Ù`ªu°%¹™à!+Hó4lTŸ·L‡ñĞY…'†yŠÚké00§f«ëÅ¡Gƒ®ßÒùC¦xNµ2àÑ%Ib\©³_&"HÑ£ö¹œLE“3š•Ê`ÀœÇÏŠ¿s³—ÎLÎ=Î’¼\æ£óŞ?oú(Ínjâå1¯²}õí'*&‰Ú±,ëÇg™g=prA¸`~`’Ù+!°É”Š±—LØéõhZrœS}mÚ%7ˆ*,œã;55FDy&Qwc9üPAĞri!0I»Š÷†<³“jò‡	ÂúÈÎ’ç«a<JXıøT™ªû?œØ´‹úÂûQ¦¼ş,¡Ò±\–¼=£
à=¤s6ŞêRûÓØ7²;'Z’EjôL¥zV}HéÒGÔ¿‘Qæè*“¦âü08—ÎŠR…ãÕû·¼Lº®óxè_u¬ˆè&å>P^°-äƒ¹n…Í¦t“è©Ér~Tóîw9úÁòÊÆ@kä¾ş:ÂŠ÷Üñ×¨õ¯ÖøœİC+›õ8ò¹Xùõ–„:È§Ëp6/İ2&ÙÇˆİıâ- õ|ë i<6w—Şcw êehWé5Ù®éö:wßíOuh…[ÛÇ6ÇÌí!ÇÎ3™¢6¸•àRÃbvëIh_7Õ=O/”‡Añj2WÒ¨á,±36'˜Õ'xú‘Y×1&İ	‚,±Tq¯öÿ:ÔSÜn¦xöƒ³â¼/ ›1±â˜R§ä8eÛ>Á 3/ÚU3ÅIŒ`uí6,æÌ<£’vì$@F%â.®˜Ş‰ˆØ[ÇõQ|ş‹ ÄòÁºâ
ã¶çÊ`ndÎ2mµù4ògñ†(û´Wë}•±ÔI]ş˜	T÷ØÓMSÙ‘Üc_­¯õnı–Ñ|sš8êê±È9Lî(a÷–6ŠŸ 	bb3-Ù“’áâK3fú»Á7h5…æ&ñÁ?ÈJAuÒbd\^$ûÜWÄD]lÒA$¿ş­KäÃè[ÿ¼P‡ÛYIc\ÿ Ş]ñ(@È‚PFAoo:Äm«7NÑ‡ÇÜœ™ı®r`>ª#©BqóNã<ÖQlÕ¯'/ÈZ«C”»¯XÅĞÇ’ëÁ8Ã‡[°_ÙÛÈlW·ÿ6ç£ã`t€ÿ8>Ì/¹ı}v=¯¼õ›ĞKŞĞÒ¡ÎÇ-i‰k€|Bš¸opÂ'¾<`ÇŠ8'âaPŸw!‘â]^¤„úbÏ÷BŸuşï¢™«½¬í[ûy7Ï!â7@ $ĞôŠ3ûzó÷*¹¦!P-Eh-04;¹%ÀÈğÛ$.¢ñÄ!dÄ+oxrÿÆ¢Ò±sY´Û>½¿Ú=:öo@˜qDpê€ÏÅ-uşØ´ÇK,DÇZ÷e"WEî´™å¶Ë&õd • ùv-eù¬I¥²Ìí0”Bzz9§ÃFàÏ¤öœrÓ7Šˆ$€"¤aš7Dñ)ªºEè£"¿:/GlŸd®ˆ_İ”Z×ÖV,µgÍ	›èÄ÷oØ\ÇÈ·jŠ"}ws<Wc€ôŠ^}8piAüÕ­¿âDúæ1†ª®£Ùt*¸	ş*9YI<WIO1,ı%8Qã¬ş	ãl)¯îàĞĞC¤"ïkµdIÛ_‡î›ªb
&nk<ïsæNbNuaÉt6=p’Ô êùqL@m­1?Êß¡¬ËÏÂ2GÙ†ª°D–²¸"¢Ê¨Kt)ü'P 0Bø½Ô!m8ÖİßÏTWŠÍli¢RCI3˜1©dJ¦ì*äKŠKóØïÊ—hC;Ÿ§-i›"Z³â’:R¹Ï–†2äÒ¸ñSºıšçÎDÌ<7«ˆƒWõ›@²°i…ØôWë¶Ox²ëëòÏØ%Ò+d
 © M¦Jòû*,mÈ’P0(vû‘»Í·ˆÙ2Üä+åµW=¿-W­õeI ñ„!¨%Ü|[+O®š&%4•T¦YúJ©h·<qhZQôåN‘BLşÊ%Õ®·AÛ
ÿ»„5ÔÔ¸ğ¹a2«c2Õs#Ù´‡nÆ	KÌ*åöà…íG1Äw|e ïıË^³²õçXŠSu¹»Ïlœ$n_íª¯go©Œ¡{"-ş¢Vµ­Œ—J?x@ÇãÂ »ÄN6¶è¸ë½ı¿Ú³q TüN(73jÉ^w£ÃWRÏä#±RX¤£Úâ
öü`'8şM;²Hï›ş¡óq{_g{µ˜"1Âª‚U\:Î€hÂË`‹>XáeM¿.SÛE§å@àÊü‚îÏÂÕm&ùÚÙëUÛM‚d$Ë6÷ÅuËºx5o#Fï‚¡X‘àH»­9ë¨!8§sIÈÔòO\y’˜CÂ’ô¸ø+¨Ğ£ïAŸÂWäp`FF¸èpjE]ûË”NDœüëNÿRü{åw7€ÓG.Goèª‡¨á2¶¤#£eÜx$‚ÓİŠcìÀåBNAã¢Q®”˜£8Î@ ˆûÌKäpF{¶=Ú"L«keN  û•£ßÇÎ™á†+9	y(&VÌàPğ”zÖ`ä¶Ñes]€KªS·,SgÈ£ƒ7 &†¹4³Å›ÁU©Èßa&ìÛßm-¯@Gc#ZäÅÀ ¥s€D—ØŒß¾J‚VF=Kİèñô»¦Õ™„kf•fM»»åI…ÑI©t¾«DíüCIs ò}Ó.ƒ˜†Q
7¡MÈö#¤è„ºÍ.áß
?-ödß)Arƒ ½.ºŸÛ	uáKÉd/½'°×
\Y¢esQ=ÃÎ7?F9eèš¬ê; —¿)Éxä_ùÛ»±Ã&'e@…Ò
vo	LD§¥j0s
Ä5`eL‰L´$Ò<dOC"^¾ÉãèêQzòºQşiÓŒUŸºx]¥KÊ\ô.o\p,Åşû3,?`§ÄS&Ò‚ú|.Çšğ­£õÃ·¶„epĞ&,
8U¹ÏHã: [vœ|£ğU.ºİÕ‚p’R5:5òÔØ†kƒ»Ka_¦;=äùc…½¶çnj‡½¢Uº„0ÊyBÚCº˜Ë=®0y$JQ›Ów]¯ÓØ‹ÿÄ–.Q£TY+Oîüß‘Ş0Næ+ñH›Ø„öÌ»[ºT‘Wš‚îó4LçBØjšRÒò²nèqî&î£LĞQÕ½ìEt²aâ+(+¬ŠKkğ €3)éÔ™qfÖna3©ÿy,&ÈJ'£=ı^$rÉÿD_ƒ?N0 k³àMœ{³ôÁ8Õ¬=NF™Ló	¹”¨F…>`öç›	”LEVHÊø€€³¶€S¯Z*€-2-Ú&g‹¡7·ò°ûKSá	eäYtTÉ/dªòıÚ(»Ç!Ûºœ-¯ÈëN†ÅİÙÂvÁP:~³5Õ=#M&+Œ”8ÇÖ8¯îHj@í´$X1·ÃHÀ|L=î¾ÚïïégÒp6Iªş¢Íg˜dFø\/ë¾wi¼ä¸y½ªÚÇÖŠL˜îãpœ{øé	Dï»ñqJÿ3õßVÆÆŠKŒ ¿ßq&V7´Ò	œ}ùyÀ>J™˜³²	Û¿HÀ#9rÙØÓÉi® #uÄ¢s`ƒÚ¢I¨ÎŸ ŸB·­ÜEyûXà³åÕ9ï`k}&>u“4J‹•šBÎz\†òÚtA÷ÀÃwWâOIi\s§Òg~˜…qlõÌnF}/ôÙ§©B%@®ï®·ğ0“æıkÚèÂŸ?3å¢«=\:¼u$[‡?ËØÛp¤ÿóÚq#–Õº—B\³\ø„cÿ!PBäı3ˆ©^4²ˆ¨Ù´($Ã'LsiÌªeo,€—È%Ä¾&‰q I±*÷)ë&}/µ¤á(­ms{ )Š¶«Bàq ¨»69 ÷¶5BzÖïU	’ÅŠ†à+ñ0ş[mş{ÓCØŸW–#-’w&åˆùBûnı‡!:å‡Tcs£ÙĞ¥l„_ÏÅ3O–¶P½‡moc}hğ_ãN„(6¿T•²aSÙsmÙ³ã9Ht¾èczÎİ’î:3ã,É‚e‚©çêZ?$Ş°­tOˆ|3€ƒ.'¾Vš7}ĞáÄ¢²t¥àÇ|»-=9q¢Æ3fá-´z¸6X>ºĞ«®‡›Æ÷NlH •}!5Æµ/p&Ş²ø½å~û€cŞ¤É¾’Q’—úëıX í‹$ãÑsgÅFğ‰š¼˜œØÑYÊæÙŸê>»pş¨"/
Š#9“úûº™'ÒFò`€F¶AœÙh’ÈD¹·ÉÚgœ.{J¾Ij×Ù¬íãê6,qo S­cPôCÎø 9Tæ.S|‚ÎŞë•ÁúÉ¤¶ÒY·<¡ª¼ï-¬ÆÙÛ=(eÃã½1ÀŠŞz]ZfÂxNäsFùD›e³‚K­êK>ŸÅs”rjoU€ÉÿC¶”>=¹ø­t3;§£'¦HÄ•T>½qg(?iÜ~„°=‹%.ª¤O.÷>ãh‰à¶–9`ò%ö‚ÚçÌ‚±V›‘cQä.ŸóxæV%ıø0½ğ_ökœC­Ä°ËÎÎ˜ã<‹»JÚt@é„˜õòq88«Ä MH¼Å°èß8$qK<tãëÙ¨Œÿ…Ñ¨Ëp¢E/07!šõ½HwõVN’ûè=B„VigG<yÃ:2ÕÈMıÇ65¸?ÇµO?BdŸ…Áğİ†Bí´ó¢;¥™ÈóÉ‘C&üíZ’'å¾uã˜1÷¿ÿÉÑÈÁ\…â±B¥£Z³*æíÄBgD`g-`ÿ/R±èz€ªğÑHÑıi;ÑHï(È(ŸªñiöqU8†İ¹ó }°+8uXNq­ò¤Je¨*€_
İY4º=«.¯x€ì¼0-¨›Ş§ş?\ß‰ûCAM_Š¦5Y :¼KÔ	%I‡İ|º‚á0<7s:5üŒº¨Ò]Ë ›n€kLs„­^§°0cEÍ]4f@v8öüZÏVàÅ‡ñİº›	Ÿ”*H)\6ÆÆd*:C§?È«–,Á±QUlå•’¹øû?aàÜï ñ½È*ĞòçOn,;“xÆDÜÓ¼µfÿôPè>Iò÷÷×N/$-Ÿ‚6O·3¡z–Š¬Ö‹%’¬¯¦şšÄ»Àƒ¹˜8Ã	/ÿHc"hŸÚª~Ges/Y_Â@åêÍ Ğâ'&Ô¶óµst.ëEPs:úzĞì¾È{‰#
ÑqrB«…v9äjmàóè`—©'j€m™¦Œü§°j™x™*Ø—sÀRn›Òµ:Opœp‹_ãİÜĞ¹q·¼E1|B0t7ûêX–®i"ÓTÿ-3ã”®’a/¢“\’YõFëª™Y)ÛÇá‘ìJ-Í(bˆ?2pvåïÕ¥put K•Su¸XF—ËÜÏàÂÇ&™h8´zÆá[ÏÌ3’rô(SáDØŞL±ş1©Ò&:Êe«%fÄ¨rĞ'’kHG¾?±Píâæit™h‘+‡}0òq	L›Ò©yñ 8¶ç«W—.9KCYZ/!ƒcÅqƒ%	!Åoº?öŞS…ætJU‰ŸvHĞ½ß gÛR‹!k€DÔ<ö¦Şİf$¥“LW¶ÛİjÓü¢Ñ!€*•¥7#³ó;ØwòC•ş4–ßaU…³è¤KØıÿ®W˜ÃÂìß²:ÛôSâXfÓ£ÀŸ"h®¯Qj|…¯µøvJÿÔ4ªwTü¶Ä·|ÖºîÁ’ßÄLlg’“D.?¨_%Æ…de{®Zá$&ÈŞ ‡‡ú¶n—iTda/å}ƒ8Ã²«\º®=f±˜Ü¡şÔ–‘ZC-•‹”Ğ×¹•2r§*Ì%W­Xn¬“uA“}a~ûlñ&•%H^ÇJì‹´®SÕşPç<´¢!½,l?¿üuK1Şx1­¼«æ¤eıûíİş¨SŠƒ\Ÿ”¸r`ÔÕ)äSÔ>ƒ	ØänHÊEaa Sò‚L!¤51ö¿“V_(À,pZøCÿgw‚W&gófyÊ¸ÕGN'…\ÑÕÉ_ù)(·j.¤—Èê»p|UÅqğ+…ø&Kş9?¤ª¸¾<°Ç’œHÉQ#³»¼R¾€éFßGçzT‹^BÁ.¥’Ù-½M9ÌQL¨¦( ¤ØUAG¥ğ¨*&¸¨cë˜ŒlOâw¥RYX´M±İ®i·É“
ÍR®k½¨İ6hÈ4è<MÄñ<o*š&ßhhÉçG›F4¡Qş6  xªşâ/áûLƒ LJ`›2aœ‚‹•0A%rXĞm1jÈQcGÄÌºQ¹yF-5øušrşDi•KÍ{¾ÔÁñf—åÃFı«ø ë@wğ«ì)¿VÒÇavõ›Ï7#:´;„îfW?"pJA:]ÍIêÔ2µ˜â©xè§;ŠLú‡¥Æq.¶>Ï¹?âCı™ q ¯Dú¦hš$=cMqÔøàÔ%›u¥ğ¯|Ÿ’=z™}3‘6ª`P¸¤‡&²Cø<A ú/©d¬Û	$Ú„?ÀÆ4KKü^,µ¾ÃÌ¼·Æ¢‰€¹‚A1«*RÿÉ)(š==›×!ÆÌ~´ó$u”‡T[­Yôğª/„O•²¦[³¨?e%uu–ÿ°.ÙÙIû4cp‚Mn‘ÍSÅf­ğs1ïâ7Î*£‚0»»äÇÑéà”?ªû>ÁÑº1‹­À³V°ù¥1Á£ĞŠ£¸uM´ëg8›„"äÑÄç%+ìÙ‡üLÂ}ßtìÈ©ãÄ}&B¥ã¹*;"Êjo/ˆs%k«Õ|c+s÷¯ÆÃávÌüªô×jÇ¶ÎZô_Ó}«¶
îf
©¸d%h9&pó`Œæ„@¬QcHó78ü-mÍüİe‚Gí¦Ä2"ŞNHNI¬Vğ$]®ÚR-T7uæ®ıŞ¸¨:˜’äqHÜğ½‰O%Ìß5[Ì\¦Ã9$QMppª˜ZP¶cLÏÿInŞkÀvÙšÂü^Ş\ú¢½Ê=X®ÇŸjÂÍ8czÎ÷/_;Ÿr£¥,.L<;okÄˆ~Ñ6V5¶CªÈ3î%°ê!+¤Æ+AYÛÈm˜q0…ê,<¨¿&Ïl÷¼pÿLs8Zã–Õ|¨üJÕñMz’3¾†Ö¡+F™l¾<½É”Ë¤gŸ‘¢è¨
‚Ë¤šôø`bƒYÏP˜'‡“É¾#¤‡ö8G¹…Nü­•‡…ªøš vaã6Š®“óÜ@öîûĞ—ƒò=Ñ9C&Úy¦ìzÖüšË]XP6(ß¶.%™2o6¾
MM¸ÅÌxŸP]É@§ÛËÇ{ÅÕ"Ë¨kK2EıkáO)C¿_[Ï­m[P³Ì(ğT;+ºÂå1g…¯æWL1¬LB‡LV
şŠñ°Zw=ÀºâÓäÀ´¼­çÑÿƒD!”‡»>Ç™;h±6š¡Åb Ùº¡Ä8ƒ²ÎáĞÚpOàÀ¨íFuÖ¶Ì’ô¬\òÜLç±¡èÊ€òë]é/+&şb×ö–€3d\Ç„ÜrCäCÈRÔ=Çš?úhÀ\ãC0&…M®‘%|8C¿­ã&Zé|ºAPKS¿ˆ{}F¢5Ï˜m—:¾ig´íQ˜tOüõ WöŠÛ;´TõÏúØëª> B.Õ®VÊÚ¯Lêi5a %›º¾-ÀÊã·SùIw-ËÀ†u³Šr1ª¬Lg«§Ï¿ÙÜIôu	*ÈØqyà‹ ÜDLv`0ìK@wC&²u_	XÔ.y%ß»ç˜§Ô¦p4Aî| ~r}åad¼M,Øé	˜ÂB±òxO¯SÀ×X·¬3˜†æĞ	”RÚ%? àÏã‹ÖOí:ŒÀ2}X’ÜaĞÉ£’Â½j—çVâqÀ6åşaÛ¢íw4ÆkÙšSMÉ~Çãıîˆê'(.ÑqÔbW{ ’EÓŒ×–[àçcBŠßë8nªúä—…éW«8ô»×&Ñúó4Y”Àİ&sĞÖ–ŠS¼?Ê¬v¸ÿ5ÂvØ(QŒ*xËÚ¬5vr%\ã <r‚Ÿ'¬Zh4ªN­N­÷f–mˆƒ¥Æÿ]u¨†Ê”¡$GiøJ¢Â)6²JjŒ Ú”Imóş#&FñÈÇ0î9‘^ÇçOhi ?Ê+ÜÀöıoÖ_¾Gyğ=2F¬
~aAÂ‹çd¨1Š¦®!˜Æ_—\dµ×–6ƒR›ág¼î³2Ä@zJ¨ +r’¶iX¾‘#dï¾”­ı—°)&)¯ÚæEÎª¡×j	ÅĞ…$DM¾£;°IÆ	V´È;qÅù ngóãÎ£ŠPÀF‹//àA$ÑU9øYT¤½ÆÍM¡Ò.Ğ‡‡q%,ûaÍúMôC_‰?Ä#6İB®´—µ˜3ôPk*¾Î·AuºòuFœf¼ÒÀUjŸ„×¡©S ±Üİ»;Zº&ò•ˆ®VU@?/ÚÅ`*²ù{Nº™šnêB‘Üm>©$7s•År„Ê…<¥Wßõ´›Î<ÎcWZi£¥ïİ2Ã¢.é+ú?ŠÔ°Ja|¹ŠQä»ÿ—(òxl)ÀÍy2¤kÜ’¡×ñ:½>uÌÖ¤O½úÊH}	S`²z?$G_ª–Ùy º ÙÀ‹Q³OêÕ€‡?ö÷2à sê8³şÎ&¡,fµÉ~¢0ÃñÏÓ¤Š"oôÛñ¥şönCğ« 4'(¸’W9VŸ¼;”C£[–Ìw­¿™¨99¸;0jJ½jrgÜ{™è6²9›šÌâ…?kÇ“#±E-ù^e$!LNÇB8_5F¥½uïı’”@ g¬VøD©Â+É­™«ªŞTãOãqØÓ¨­”¨Nh·v<_¨UgYê`Q½CÙAƒ;yM¿ÁŒD|FxuÎtúY†ı>*]®¼şM7ºk™Û[Z—Ï÷Q«›ö´T¦”d{‡rÙ[»ËĞ[¦WÌ‰¡ô;GLEÛ“­AÅµğ+$ €^±ùÓ\â¦j-3ŞùßĞöÙ2å† 0õ›¢İıU¬tôğtÒ…sôV¾Eûæ¾'ˆ9Æß®Š“[F=H‰¹Íñ1ˆ×ĞÔr¤)rxŸã ¢_¯·GÄ~$¦²QN]Ì¤P?ô*Äm’€aÖÒräõƒ¿:oøVÃ||·§ü/T¯!*8Ã2oç÷õƒ9ƒ ¥µ½Uœ‚tš¬Kõ8y=¨¯öÁvıÍ2Ø¶ù à$ÒºRü İZ4yõ7Ã¤XüÛ(åÖ†r2(åüÆ¹ÛgSÜÈÍ˜ øJr	Œ ³Rm¼ˆÀ¹ç8øq§"qpI5L¥1„‰NV8SûKÓ†Oğ¢ëŸ´­VU§exÔ4âŒÌf;ÃE²°Œ	/ò-ĞÓ—ê{—“ö ìzãIŒ ÷ÇA*~ìY–p¤Ÿ&Pú'wƒlqÛFîp èûúé„ÃQ>UL7ÖİdCÌP5J¾`ó…®-57%Ttí–nƒFíÕ±BózV³	¯yß+‚4pU£~sêçB„Y'ÁÑ&:5ä8zyÁĞÎõÛ-tiÔ˜mƒ^}·U)ÇÛÄŠôè½ìº‡;DTğ¾,~hrlÃèŒzŠR-‰`îº¹µ¦Ø÷9ÜšdãŠ³–^&û¡c´Ñ@S™­_î-ŞÂ–ÈRo|hD-æ”µ¾jmÕDGØRÜŒrµÉÂˆ¨‰wo„Ğ×ÔFÿ×Ø?ïJ\Ûóy•§“CûÌé,ğDÚÏìá±v×ÏÚñ4ÒíEoİÙ0F•àCæ…2CíyvªœÅN7ìa¹úš;çKò:	;Ô†â~<:‚uÇÿ¾˜Ö²„ÁSû­uËî¡›9…ç*¶çí™üW[x‰LårçZmºo7"ƒø6Üú™jj«”5ÊİgµWwQká¬†	¼Gõù5¤÷7FLRó:C-†rºİ‚¬qîn)ŒGâ°Ù°‰¡:»&Ôşq—«Q"ŸÿL	h=	paš0	‚¤6ÛtúŠÚDşÉ.waî5{·è£3*;’®^’…½WB™Òá:®s'uÏÑZìÔñ€ ¦%oLDJ`©Sy±<»R›rV‚¥É²^DÉ…â8„(;ó‘ÜL¸u€ù¢@¬/Ë›š~¡àeÂ@%Á8©Jk);‚”Xb9·”~ÙôXÔn]°ÓÍÜ>Êıo•Xó(ŒŞ{†”£½´}A²îl¸#ël…±ólMºjÆC³]İ"n‡x¾#ôÀ¿ÛåÎä7Ğ²õ&³Xr—Kk2èÊÛƒÛ…	“iS†Š´wà–‚&5$dz¼-u×-—ÄğM’Ù‘Ï–KãsöñbŒjÅî(‘‰U½Û1d,ĞÔ(Ü™·Qló-	I£±ªôk>Èór~ÅÉæõjAMr†D¶Eç¸vlå©ÜFJ—½6 w9.ÒJs%§]• šE}'ŞlQÑãø×5(ñW¨‚]şè‚DR	ÊNvÄ-æšÀœşÕFÜ´ãˆG³ÃûıÙ”ÊõØKWÅ‹-Ò,6‡)¡érÖ¼mr¿í¦nÓ8_Z1g÷C'ÇŠª!ğ
ƒÜ)ÙşCÒ{ˆuşD-¥ĞfeÍ"mIYÎñx:~YêÔ„ g¨4)AEšŒåüŸfz[N6n¥Äk•J'¾ÖX¥­:7/S±³!0¤Öb‡ö—ş§huÂıòÎäzB»œs7T(ÑîğûŞ’|†Ö*³å’Ğ4¨-wêÀ„ ÌªØï¼ïÉÖlHÒc¬Ş­×Ät7ØÀı@7'ÿù1ÜëœÌ5ô}-jÉß©h‹.CïŸ?7GX"ÔÅtŞH@ÄPÀH¿ÓÛ‚ÿ\Ï`Á»»„ä6åÂ©×„Îğ„Èúº›sÔĞXÀØä#‡«¨ÄÄ¢àÒŸ‡l¼Æÿ‚K<¥{?e%fÑ¥¥µı 1#ißE?¢½{h­ÿt?º±Z•;ü²ûW£XÀEi¥Ğ™tÙíñÙQËÌ„ÈCİü;¶ÇÛJµ&—ÙÎê¹„»%Q& h â*o¹ø%¦º!”’–¼çWãq+\™–"WÕ=¼ÚÊ–G¤3²<\<—%&-´”óàÉ##ÌGJÛ~E9Wø%ÑRi+¤Ø`êtPcÂaBşÒ}3™àèİØÓ-·¾ÌÛ–2ˆ˜/?1oÉ¾æJ.~ïêòüÂ‡X$'Ó‹øxz‘1Û(†s
Û}6oÜ¤™MRˆLáWWt›_¨	äQ±côÊ•==#w…YgH
Q
¯†v´K´ª¾©ºíİ™oØó×G”Ô+¦©‹¯Ÿå(
¡»^Ó˜À²ªÜ_Å?Í~Í½ƒŠõĞğ¶å°€·°™Ï­SòpMtó3šO¤ds¢aNUÙœ­íQÃA0*½Ÿ©ç—ÔQˆÄrO@'i‹e²÷ßfyÂ†}Aïı'€_?S±ŒÙ’yu-Èù)LjpÃIaVş>3åio¶äß˜Õ*Ï<_fÓg€@Œ-Ó?×, šiÎH5·³Cîfp)nÔ“08²äsËv“™¨!‹¾Ü¤6‰àN­_#ÀøC„ß-P‘­âŸG}=æîYÕwêÔrùœ•a"(×’©*ùİf.¡…ö2‚ˆdÇ¬¶~€SçHUuam\ÜÇŠWœ
VŸ”’^tœ†nWü\,c<ûoF†B¢ï¦ß–´ıÄ´ª“¤æ?~,‰í’Ÿ@‚(Ëá‰`ºõ$¥Ë¥gÆÒÈ¬á¯È£¡enÊÛ…”&¦íkĞ»W­Ò/‹êßBÕwàª)Ñ`+Û¢b2/Q•ï“bE‘¡Ü4 Ç0DqZg(Ak„_ˆzâ“Ää,T4:5Ê7­^Êš°Ef1 «h3ÿáßÜùUn?`(¹©/nÌnŒ†(òdîKL>ì,É«É¤‰‡¨íüJáóH€f;}H’áÎ1BßYµ½ñ[ù>é²âpÒœd½Ìü~F„,5 †”<Èä94‘[ßcUb{	±W™€:0wÒ?o›ŒcqPò½ÇYšªêe°^‡3Ş­Ó®éY ‚İ¼’æ*!Ë¡0±c-¬•?…_Áæ	.Tœû ¨™ƒÜ¿5(²ÇÇ¢VÓİ 
!¹²ĞwØ3Á’¾è¤Âàr/€Àí©§d™A³y¾ºïªÕTa¥ı§WÛŠ–ğx®§ÚVÂ£Ës³‘ÌrŠ—`Î^sÌ¬¤Q.\‡tà•/\íon™¤Æd$ÖNsb´3-^Ù«¯ö[7pİâf–I /;Ö1áŸrÌã
sbëØ3-
şv%™•{«3¬ #Çù.§Óïv‹'ô;CÍ´>öƒpyé“y‚ûí«vC`‹$afI»¿}@<ğ®öwí­HÆ‹fD¡Âÿ±²ø…T.Á5TzåJr80EÈ.Ë‹x1Á¹fmbõ~eútÍ‘’üë$Ïí?w÷b·×70·²…òûB/øİ±İ¢t“]| Õc Òµ±÷”šº:ˆÇ)öl8È÷õ;ÑœaÒã‹‘MÈ”ì¥«Şê :µTo—\‘•,¦»Tô;¹4@šU¯R¹ıq‰¾zX[ôÙL¿3DÓ%²kC¾Ñ grÛùáo~‰3Ö2©Öˆœ(ëaPîû‰&mÉWjÖ½[ô¡o²•!N£qX0'¥U8îK0z%7ßÄ__ù…kC3eØA<Í'¥²å#{öû	ˆåq&”M›ìÓŞ:š"‡YnülòÅ÷ñy‰BˆÓ!RÀx¨/¤õwu¦§ÙÏ×ûå¢Ôÿ$µO^óp±ØİÈŸß³ğNIIŸğ3!Qû}É­°f¯Ær¿÷J
;×0ZáÜë/C^G‹.‘PßEÚ«“ßNæ¢Æ]å_ßÉ-¹æÂ°Ïá²ŸÏNd`r‹ ³ ¦nB\Ó]™ÆU]EÔØí¿—ø÷i0g+•8Q4-*N8\ÉÿıüÖ´ûZèÆÇ!pÀëZØ£È”ÒÄ«Âj#f[6£®$´µ´şÄ›¼DçIÕ×ßî÷­#] ×À8Šù–ÕÅ¶Ã^$§Œ•Z®^0Wıe„UVØ÷ŸB- ä•‰”ËËHDy—sAŒ=.Û›nÔs(ø;%ı+ÆŸPØf—³ám\G,`ïŸVÂÖc…c³£Õ>”ëòjº¼‚à<¬v¤!=WÖŒx|½Íez)4ãÏŸS¯r±r[\ØbÈ"šøíBi‚Zdúhï„Yf±ûUkğÆİøËà¨ÙE-_m*!‰JóÏ÷
b:½Š»JÓò€¢øÀnîsº®»}Úœ‚‹½ğ¤WòX†R_U³±E×r¥ ™<}#%ÈÙyIÕğ±`2­m¸>ø™?‘9œÑ$[ä%åÎqı_	D§  TV3—c–8gj¿mä>iú*&Å*bg!¢÷şÂKÃ4äòVÓc×ÿ8Z‚®Z¼ì(°ÚÓz0)İo›¶ı0N¸	¥Á6·»#·g$PÇx«y:¼Év©K¦säÿ˜}glôóú‰)âCÛ%´J.Ü©ĞÒ02.‰JzTÔ¹˜©a#>‡ÀBáå}ª!'ï™o«QÚJ»`Ã·X]S
ATB?¼É>ö4…äñ-,ù>oZ‹úhìÁ±8tœ|gøZÂŠì/ÅÙ¥(ZPnÂÔÇN‰¥‹¦’Æ=fî²U8†aªnªá²
¾ëJBá¨1ÖÃçÊ3§}=¥äùT€u % "f§ Â ‰mäyY#û54ˆVVáŞÿ–º­œ¾$˜¿´jn'—Ÿ^pé-pÛ'·9ÜÌ©ÿ)¼m­Ò•8u v yrtIRİ>èåùßâÖxùö’´ûEj™7zS ·€%oOû#V´¡©’fPûoÈÙÃGp/jF3{ŞD×JsSp›ÚÙ8@›EŞvÍ´ .ğË!ƒ6ï‰)ŸRjWÒ’êtBßYdX€D0ëÕÂ¡)Š]	‚Í°ÚfŠìYk‘Pq"cøßû3³½ÓèY"J=Ô~¸ï{4NÏ’± ¨œ·s&p0:gM«[VŠA‘`•„}Y-€ëìCİ­Y¶Å¯ï]›úÿN
#Hûì3¾Ø‘W3I«?—àCEP·œ)T´ù–Q_±ªõ¾ WôoÍ’Cã;âª÷kÖïT&Ô´Ô?§{tH|«¹9o$¢€*´%®NıH¿Z¬S#öLRùˆÁñ Å€¢ûy³Ë°Oú”œùG­à"Â^×¹q²"+NAÂÊGèæñN¾i»ÇÚ¯ìz!³ÀÿTRªäS^SŠ„o›
s@K_†©'Ì½krçÁB4OË„w®Õ4I‰Ö„[.¥_Wï=÷‚¨ MĞÏGC™îÜ«õK§sT2“C\šNL”ƒÇ¿]
«'>*ó¨Y!ÓÜçòŒ2¿XõõfçsM :†ÆX“Ò\9Aúš«•Â¦²²­}Ñ|_E­!û`­ÏOËêùAMı{Wæ'¬,¾.õ\©I)›iANNÓ#ãÁğ]œP~ÃÛ&eò&åV¢m>p¯P§¾}*Á+ËL’€·|Ø	ÈM~0{Û%›^—	™R$‘9—PÙgûå¢e.È¶›gèûë’M—½vˆğRACÙ{áA¿ÿ¨.Yvñ¸Ï$¦×1Š;ot Båã˜‰7¯,D¨1<2iÚ,Gß{7Ğ&J×fy„€æ<­º$Iÿz9¶8æí\ M õãf¯®§Èï»}„AAA:äm•ÿ@¸Z¤æÂK !øFr‡”pšÕd[BAæØ¯ãr§S±¥Ì½]FIÍ~Yú=‹Uèğî‚sõñüùÀıF!ÿ‘MÏ*ÊyØI?y˜íèJ}k+2¼e·Œ¨‹öÎmõ=d­w éW¯C™”Œ¡í¼+mãF“tÂ ;¨î~©í€î€èÄBóF54ÕŒÓÖfAı7ë¨Ø•¥À$Viz ?)ƒy„ˆ0édIuö.ŒÚAı£w*„zw.Š=W‚oYzİnN`,³oÙïùb4Å8õ¡§wë¬]è¶65f³ùS›ûœ{¶)2Ù¾ËAxZ ¦k1"Í1SšŒ:=¾³ÕÄ9^-f#D„R”îûŒakìnÄe0½™&AÊı¶ã•\mÃD¸ò†'#éoËŒC/ßÿOh
r{I=?*oÆq/Hô:íÑŞ6¬µµÊ9‡˜"i3¡©+š*”õ«S§dáØãã¬,°ÏpAa“Ï¬j‚˜ÎÂãà¢Z¤; Tºf¿‹=üY']#Ÿ*‹NK)è÷¬•‹M²p—l‡å¿}%¿8¤±B1^ut:tŸÀÎİ¥Ô÷då×X^Åy‘" ª/ë>y÷.:ª‹oÉ™WÿÖ~ÓY?º//í¬:wËÄ3£ ×ë¨ÃkroÛeÁ‰œfOØUo¦Õ±Á=7_'yØ…&“ie‡éT*MÃO—³†Wf }Šà'ä/rQVH€ì&9ÏíÒ1Â 3ë°_6û‰ÉÂ’buRrÿ¸Oşna¥¨Ô³\šÑ¸
Ï¶”"/»^`ÆYŠ4;ÏJx¥`Ó®âÕÇ0ëHA8]]%‹Or²z¥~¢Û„23Â…úØJF[^‡_ñ;\šqïÑz	·ÈDÚRZ?ŞW=‚½%RôHQy{q ÖØÛùøÔK)µ¾ëEÔWVh6Vy»ó*T'KV8k3hğñœ¨Ë¥qÏğİ(Ã÷ı½¢Ç§²u­ëx»Á}õA””„ÍQugşÈÀç‡¨Å‰Ú`w&2JtHƒaÔ*p\Tºà4K,ä]Â~pÓ—Y6<£MÌN­goÉ©ûÀ2Ïk“U#5oÈşkò°Åhò¶¡nÚg´4¬Ù®Ø5^Ù¹®ŞW>
3ïÛ}Øp@9æ‘§‰8;bì8ni°àÒlƒWñaV‰óq\øK/²oÇb¿ş/£„Ö¨Ìâ÷õ;OØ7D ŞS¿}ô8@vE‚&¸ ËJó™qíÉ^G”“ˆ(J|ëâ’ho á0
Ç³Ñ½Ôó·BG„ûŞ9±/v\ ŸKŠ³2)½ÜWÓg_˜Á^ª$x¬Ch_ËiĞ„#2B)d:’(}íQrbèÆe}óW3‹ÛU ”xn´Èùs©¸úã"	'\_ş£÷‹ğøÿùkÜV(º7ªÖò±âæ«ŞjML«¯ÿQªˆY{å-Å­9Y~K"&Æ…SzÕ-e§eA¸ı4E‡Âğ×Ñ$„(IO+Åõãè’Åá 6¡Ï³ïmVH+ªÔ”–¨,3ÎAkÇúÏæeŒ•7u®®ìğgúÛV`
_E/Ò0À½ f¯~£ÄœT£ /EµÕ){èBi=C>[8x¿7ÓÎh¤ÊG€ÒÍİÓF©›…24Ÿj:\»ZUMº@&»;”ŠvĞG¶±`«¢Ğ…2âÏ,aë$yMÔm%L…Ÿ­ŞÂ•æ´û–’·Œ™Û1MÑÅ5Z^8vÆyv ÈWx5¯:µÇC92ÜO®ıx+İ40Ìâ+×ë5*bV>s²zí­£c[nŠ:À¡ÅòbPé—ğû+X!şr oöá™ääüÔH»âSBËÈÊvyôu
1FÒŠr1PLLZÒäLƒ§~y„UÃsòn@•a=º
¤Àû;ˆ3´šQ¨b Ö„.«¼z§O«4ÑN¥o¢àQ†ù^?Õ…æxÔ‘±ê·î×%+æfê]—•4 ¨ÆAûm³ Ä€¥-i5Š•SE‡EÅçÔ¿*Âu¼JLq`Á©mÀ*{ò^>#ĞuÇÖŸÄJ,lmQq?êÔ›ûwy•ÉĞçòù’ƒëóÁ åö2gr-FØ·‘Ş7yõr2öÚº,İ ´º\ÓÚ- f_3¯c#ÔäEu]!ú¯µµ§ğV‹BõyZq}VÅ®™ÆbaQ´¡&ÈQ“ ¯ÂYÿ´~ŸdcØ‰Õu4—†¹IbÀfÄæ<hJ‚´Z‘ŸN¼"—æÌÃL° ñåÊ‘ü$Le‘{Ö³A¯/0…¶ÁßëªH>)—Œh–âşÁ|t^5ÓÊÂ>¸Î«O*…?
W¬S%à™m(`oqÏ	7ÂUÒ"šóë)Ë7	UñDtAû,.Ì˜†ŸP<tŠapÑÑ˜A²C™X#‡¬tu!ÓÉ©–DîÜ³} ;!Î‘¡làŞ‡­Å¹b!{`•=5ç§QO-Ût£´`2X ó€æ²ıES›F«Qa*èÔ¾ñíå6ÍHEÄC '£–Èƒœk­,}ü%ŠºM U’ALõ]®%Áêôñ%ø¡c5MáZéFu¦G•Ã	¹æ_`”Ù,çŒ”ÇIfä³õ;§<™P¶Èè‡û¶uU=½­–¯^Ÿ€Ğ
·V-ùÉh‡°±Ê­¥Ç·Qg@üÆ·"¬µÇ"aùßèõD2¤åzÒlëq®•^›ŠäÅJmŞ3tÂPFŸ¾ZŒ›®åXmw?¨®·ÁvÓ+àÄÄeP—œÔux/e<¬Şë[ß6gYqDÑª ÿ¤«BT™ªíÔlk§8’¦ßB1™İô@Yfåƒ–ÿš—­7\¸C}ÒÇŠgıo-à¶;ÀÂ	ø›mûm<–ÉïşÇ*rŠñÍÜ’ü$)tâíĞ
:zÇÍ=ˆWm3va8_Mt¢ 5ÀcE¸÷éÆB_ü:
²Q ˆm9óıı…±W³‚ïÛø±ĞUU3LÚ6Sö´›b5&¢¡XğâqNÍb–ÃŸÄ§¨Ôp]İÑªÑïXˆ÷NÛìä-Œ‡ğ˜,ÈÄòF-uWI7•*R¡Ï‘h6Íİ '-.åA÷^GĞîû@ 7,¡á\H|·Ê›Ë,N>²Úç6®ÌŸı1içA=ãX ép”†¶|Ëê¥…öÃ@‚
«òçíw"H2w][Œw—Èâ=Æ4ûKP1ïşD k‡(>›Ê€Ö7,{nXC¹y”š€Gs,Vé.x­H#¬bµ‚n ñ´‘Ì›•¿‰:PÙlÈ—è§!¯30’Q]{ğc4s%|1È}“|•Â5'N=ÉÕÅ"½†Jú/´½¨Üüc:Ú&àd**4ù££§PˆS¬{+ğ¦¹O[p¶ààŒûbUæ[?’„÷ ¦_ÕI~‘9¥ÛµÓĞq¶ó€Ì‚‹†ÈWqÓVŸÌ¾‹iÁÖHXt„.qÉ0Iƒ”€
¨,¹(nûÀ:°ÈëÜâ®³¨»œù»]ÿâ°µı m½äNÖõül·œ~œA'¨4ñ.*¿±í"âĞ«+E…Ëî‹–û_˜¨½Ç¤`Ä•`ò›ÖWÖÔtá¿¼¥Ã„ÀùaÙÿÃjêó éYGåe˜ğ­¸³?Û»ÃÌ7ÇR+ºÄÆÍ[PÁåùëó«æ¸ED×¿»^(>BœØ ”7ı5 Jôl.¹|AË÷JOvÀé¦›Õ[¡âLU™À‡}×Ğ½;e6›\ì×Ak/|ß¸Í9Zœ)(ò%lİñòŞ¤‡‚d
‰ĞîLé­È7|$	ÑüÂh<Û
\±ñ“}¸,Ú~HÓhçÇ››ñ†W#Ñ´oÆ—ò("dcwEIÅ‚è.éG-+úIù¯˜ÆÖ]ı¿zæğ°õCJ)ÖBy#@1=‰•…©Ş²nÓÀ“ôóô"Ö™ì¶ÕUg‘	Ü9÷¿Ì 0ÖUïÃ&ÏSö2›³’øòŞ°ùTñ’Ï¼”Ğ'Êîd¸•õ|¹õ%4¦ëînbèöJ]@wİäÊ4ıX€ğÊua¶Plp0,GÓ¨‚½HLËQÖáPOí—Ë¡H?Êº¢ªI¢ofŠ¬u©jM¾+G ï€†dÓ¬¾,ş7ï.İ$ßÒ
à^İŞÃDå¿,ª½›|8Øk×²È¯U¥ÈËó $/ˆM«mº×e\b»:÷ª+Æ¸1#™q>ÒS{Àê™3Ù|î‰üü6vc!X£U“uâ?ñôú4šÛ‹ßv^Ãğ¸´©h¯&âñ Ò}–q¨Uh&X!}Ó@P_)0XÍöX¢½ÌEé»9FÊá“P2ƒÓtLìÖµSú O<Û8,fc•²µ¹^Šdjr”?şOKı‰q}õ/õ’CZ|­˜ÎB÷/*Bh’oÆ-²‰Õ.ˆ![¿©İÙFsrü¿K¨F;aD;¸«juDfÉ-Ïj?ÿMX‘º1‹pŠÂ·93|µíı‚ën¯Æ’º#%m‰ˆnc1#4¨Ù@ßY#¿ImÓãŞzPXÙÄxòı`\¥ÍÌÃgÅ7òb% „§«umš{z/LH,õ~*àØË¸_PÁÉá·n›Åòªó—­5wY”Z|ƒ;áçI‡Ë ğäLa~åééµ‰G@Z¢ ¤616~'†÷mk"äß3zÑñvgãÔ5zÚ†ŒzÆ—SS£3å[øªZ "ø=¿+°†ì2€6µ%ÍîKğ¤˜ÕÔÅ]‘}}DÌé¯…ûm^H¹ÉôÔ¾Z¸s!„œán½ ‚}ƒZã·TµÉ[îd§Òq„S´¾¿±-–\~Zâ>SÖÃğ{Eòú±Ì¶g[mJ¡ó³Üî´–Øhò¯¢éã•2ó
]ÃO,§Hi›¡ p—í­…8K¼fÓ±à7;q3 Öy£
Óá-Ä@iÆãÓ°¦ükŒ¨½<Å1İíùH»n7FçÖÆòîğ,µ9r¦Ì—{ª‘Ğ¯[Úëİ­v´ç<ú$Š‡UD³)IdH9ô]ñúmíÉ}&šòBtã®ZLyãK'7ÑOãMe'ÈÈvp1!Jê-ho…ç¬q¦Ã
†™ØÕÜP¦ƒyÃDŠ"5e2ßİ„“æåìÉÆ÷¿bòdßşÙó|æ`”í\.üè0å»€¥¼ÑNèjÔ„ÓoëÁÚ¬(=	i¬]J¬’Ù MAï>®ƒçèmZÎIÉfâŒ×3ıÿ>LLt|4¤´ÄÚJ•¥À‚e*± ãì'.5ÇuÊÅnÿş8+Hšxh?Òó€D¿Ü©KVÍLznZ/Æ…DTèTée·¥k÷®·‹‹ĞÑĞså¿ÛQ®V[Ğİ	hFŒ\û÷HóéêL¿m+EçÏ³°x¯…üißÅŸø¼¬…l$£P9µmöqÆXJÍ¦¤ŸĞ²I…_ouaR¸hT .Û¡}tœk“dWÊêqV4·2(ç‘.zLNÅŸEÃËÉ’“L^Ì¢8H4Â
ü–>œ—#»\N€Ùß|¶0«ÎÍ¹‰3ÅT²|ı(! 4ˆ&Š}\Ÿh‡ÜÓèJ¾Ó†­µnSãğ\äÅàwLS«ëÚÖ9 p¶ÿ¯œËX‘äFa ®~Æ¹qï=@b^?¼ßQ¾·ÃİEG±­ñ® ;ìZĞ†xYUXo>¶`Öõ#<$zÊs:„ŸA¶Ş?Çºa[»°í•Á]©!<ï*&fÇ{6B'àªt‹qBºş ó×cƒëÿıŸJ;Xßµ¥âªL Â-ìı=‰»¼ÍÄUÏ,©yÙé8¸ Nv¶â‚Òæš&CØ~¸£ò Ä0úEàİõ\V>ı$éÈä„PÉëYˆòO£WRjƒ2zÎ\,f	ñW‰´Õ^_­xØ÷{"=yË°e’Ù5$Äiÿ@²¹­u†M~……i×ı‡Y{‡á–Aiˆ—@ÑFfõC­@Nï5mû\”ÈÛ	dÑºÙÜ×usD*ªå•‘ó_
»gGG´á¸ÛÅ”w#ß:EÉÎŞÌÌÈä“gúsm_‘‚:DFqK$“%C6‹å®ºmÚXôQ‚¡úçUÂ³qö÷‡‘É$Rv´ıà$ÜÚM«ñâ8nÊ<&,‘†+ıìhoÖVËç~³9éÕ°ÇRÂHGM·9&¾Hdç0Fsô`4Z¬ëõ9(ön
z8.”¬İv©&şƒâWc]¶Ê9A{³Í¼@ê¾€ŞVƒÂ¯Ş»}ej‘]É]Š×ÙÈs5_æ'kÇÆ<DĞ+ \SiOØt­ûhÈ½&Gmd(ô´ZJ±FdâÛ‹ilb{¢’y~ò%O…ĞTì-Î-˜£±L˜»6¸°Âã—[‚Ü6,*)„ãÂÖE‚¿=ĞeÜƒÅcz^ñ¿ı\@«$_Ë‘F	ÏfXX EÇaJx'¨ñúã¢l'(ÑÓ„†-Ä‡—¸¸¸2Œp&dÉh]Ù(ìb¿œ€Èˆ¾( ğŸµ&hŞ©lú[øóÁÑ¼Úì„ÏW ¥;¯Mi.Zb¿x4v_+:<İ;ÕgÛ»ºCŞ5<ñÜÛêPüTÍÁœÊ‘ÎJ,Ië¥B½;Ñëµ7Ú/B©a<!SÁk
	.£úïCii'ëééoñ|?î;3€ãzùİÉGÜœ´D]Ï$Öhr’å8kqã‰øµt¨ İ½+qCê>Ñº­ĞUóDÜAÖÇuÃ‹¬w•P­´-W‰PÏ«–vû7òÀ(‰€’Å?ê<¸ªMõšÔüÄ×ÃkÎüô§Moæ/"4.X¥ñ>/<ü„Ë°W¿õòÎ„IïÜr µô[5Õë]"dÖÃx•Ç×ebÃ#¹Œí¢š2 'ŞCµ—qó_³FŒá×d¾ïì=NW‡“,Å,‰°£N#ó#‚*eÆ@ã\Ü]YR#C°³Ä½<§±í7‰ŒÃ Ãšv)®­ÄFè-
àÎhÄÏAÀB0½5\ô‹æÃ?±R.ûs@R¸¹3–=ûvµÎlAQI=VAá`‰j‡4²§åÈª÷‡ÕsxÅw(²ñ¨\Ş`¿ó«q7³„iGÃüs—-•u‡I¬7³’ Ù¸ÍŸSĞŒÜ?…r&÷õ2ª¥Óbı÷Äª^É»ÿ’şİ†F%%ÊZ‡WZi@ßã­ÜÇl‚˜oİaÍ‘z%x<§ñ¸pçZQ#Ò^Œ!d 9jlPÔåY(®ñİ
“K,D]êZ=­ì-~ÃíªV…42ïrëœÅU‘J!%Én³,İÂcÛ{xz¬”æús¿dş4,çŒ[ ¡/Ñ°U§åse@4İ{å‹ß íoôû&¯Ño›ı[ªå³S/“sçâ„µ 'Ï°°€l[È/çœ7ÊÙ’SPúáàt8qñ^G	¦ò$¯ãÖÎfi2W.(f!š¢Ê^8älTYz³2ç6œpíbrğñr˜«du©gğŸûˆ—T#Eìñ³z XÃìæ^û'Í¥Û¢‘»÷‘½ì2«¥g•"êÿ Næı›Â¨#=P8#r9™EafÜnñ]¤õ5ĞÁ9öŠ.%ÿ/?h#,ÿ+À1©WR¬£\ŞS²œ›sÊaFÂƒ D9cCÁM®9=zO~¿$3NüŸ?ùlİqİÆ×iÙGO	öçÉ¿†ûı´WÔ¬Ï»™1æó;&NÔ<j‹BÈòj%½ëŸ/”ÇsGªz,"}t»I
9Ú)Ì÷hÂ§ßÔb©ù÷êÊ*‘i‡Àä.®Añš=œ˜2&dR"hNËaèŠÏAç^g£QJfù«ààîL"œìÿÅ8C{
ô­*˜Şicèbª¾ó®„8>Ë€eµ_,_µ3’_ÕÙ8´µ£[VébpG_âš³ı}K~ÇîO f|È¢bGÂœœŸ%cB¯VÔíb»-`Ù×És=yGB]zÒo0!`^€wÈã*¥Qø¼Ç-Yößû
èìõBÂˆgšóî”_5hº1Şk±#²Á<•’rñÂin¦#ìŠ8‘#qåö”ö.)»ı|·åTÉâı¶£„µk.s5;Å.•8&ÅŠzĞáŠË¦1$ú7Æ¹_şéáAyR

ìsÇK-RqQdVñÙn=„$!†ÛM5=¨šsŸ;å©ãÀ?P&7Ø±Âñ9dncï¥¶İ±…°|£İÛ}º¿±#É…|€EÃf?‹úéÚTç niÍóú›µ*¢5q=ÒDx¦‚kû"[ÑºÓ‡ò¾Sê¯Üf.DŞô£7EŠÈ·Ë_ĞÒpX¼^—FŞõÓÂåˆg†JéX<d8z/ù¥T)gµù©Î}
dg¸kìü—oO…>GY3C÷.œPÑ;vtôës’7ğ”uRi†‹‡_ÚkCäá!ã¼Èë^E\ O²wU jïö4§şÍxğò|ù‡ ÀÒW’è\ªëQkˆ2zïªFŠ™°­§H^šv2´ÔÔ$&^áBpMRÓÛJ`qcMğ‡É¶{ø°¿r¥’PeÇâêvÀDë´~ÿãèÚwVü.±±ò-Ä8Û„^v‹#»FŒİè#ÂÛ—_¹c<‡èëâÈÔ/xig­ÁøŠ^ao½°.DÉ¦“B#àåèÖPœ;ÕÌ„Ó§WK»Êáy…]“Q‡J, PL†æš0'®8]òfÈK°Ğ÷Î½·¥Äk/)ËŠÂ:ö	‘}wÀW\E'ÎK­ sMŠh…IıÏäÀz
¢sùhG/·±Î¥6Ğ´2|¼¼}ô!ô»!„"ÙÑƒæòÇ?ˆiTË·Z‡”g•THÉåÿÃıÈ{1ÿÎòàã¸jq,9Ö}­Ş-Ô ¥ÊŠ$¢XBµ^ÍS4ªIİ¯ú}Šø;ÁûÁC·ZAksæ«¯İ@n!‘³Q¬2¥1†ÇNWÊÀàf/N2w³ÄûR ©–±ÒMx.ù(~¬	¢ä¥6¿|”•ÕQ^Òñ# d|]i«r‚'jEJ[Ö	UÉ²Gb»1½Y>7+²~^‰«"Ôq6™şÀÉ„`±5–â#˜i‰™•·Ì/æáæ¹—¹<Œ‡¨o„dÊóVù.ò4‚Å†KÅ-f³Á yŸA«Û{Hm:BE>®>‘‰ª+üüí­"^à ÌBÎbš›tJX£å	ù¬æÃŠÍêìaHÃ9—v®”2ÒAœ÷~ÖÜBEáóQ²
‹˜kLÖorÏ`nUjÜú‰·«F8¸[b¨óí•-¿kü×o /záKxˆ!*ƒ6ÁØ>1%µ{IÄ—˜š{Äı_ª Ÿ‡«‚¾@Iç5¬©Ïö;NÔôÓ[ÆÔİ0Pı'â96J@1»ÑADŞ†¹¯û°`¿%¨-5äŒl³)G»?AàLµD¥Dˆ¬ÈÖè¿j¹d’Å¢‰äŒÉJ‡áıİ+ub	éÌÖ®Ôô¾bĞÁ<ì DØPk>‰’W˜¦‰µŠ?­h=çÁœùJĞ×²±íyÔ¿ne·†òa>Œ°Â¤uÏ@c·{cÓš‹p*«¦X¢xQÍOîƒ+hVÜ¶NÓÁ›«s…ù`MhÉCµßì´—Œe²¶Ã„ L™?®{eá.‡£›ŒQQc-…µ¤ö£×şî˜“­+˜‰œ›ğœ«¼$Ùzhß~™±‹|Æ½á•ô_fƒº-”ö@ÜŒÛ¤¨¬·ÕH¥Ìæ“MÆ|lP‡¼
 bfA¿zç¨}c_[Uh¬j6¼’M©í7¼£	$7 L;'úôpz÷k)x¹.ÉÕ(ÁÏF#.…¾e(w—ëŒ²ç–dÖŸ{kJª¼Â…r^™¢½û+^-f?òÆ0Y—•ß
»èğ”ò}õv±Ç³EËECş:œÍ™Jíı°²QÕ¹«ñÀòïQ»‰rúHôÙëÙå¥ƒ¯¾fŞâ7\eÌeªz™êĞrø3 ílgÖg)|çkß^p5Å–ã)#BÇ&a|R‹ìÂÌn/Eı‰˜<ŒJ¿Şb‹Fœvó<®UE–t˜ÜvµÛœL=[t¼‚l~s¡OĞû%¸V—°xS¯WkÉ–Nã±k’¶+f÷;<K”æbéS,ìïĞéşÌ½3ÒZ·lı8’#Œ·ÊIø˜qæ5ßYŸÆ$ĞÕ7s‘:>šÎ†X?İ†UáèRf¡]}2!Éo~^…6ùÇk­9'è¦Ì–éŒL°Ù×m~ı.2¢Qó,j;×ÛÌX"ÜœIÎ( g<ú”v>“‘1ÙGËõ#[ÉÛæ6>Ÿ×¬ŞÌ±’L`Ã"õúi®'^	DÙ|İi–ómüxrhé;\¶ãb4@ `Ò6çáù„
›jÀı
MÑ¦Ã:‰ ,İ¦›ä4n±uJQŒ\’Ğ— ƒ=Jİ±òéé-ÏÙßÄQ‰ÿ
ÏCŒç¼ì@0Ä÷ËàË§ğÓ¥ğ¿(-{…Û<mŒ ÜÍÛhp•OH%A›yaßÓ¨J|…óSÀi´4LaX¼ÁzÉd6‡ÈV¤EV%ÿ±Ùµ‚JswwJNÎİd·XHØ]VÈ[jÕ¤è²b?¿ŠáÎ°³ïÕ>hà¿y|CÉ1¨‰iş“!	34)ôŸz¬v‰’æí5ª¬œ8‚÷E[&Ñ-Ú.G×÷B¾Šoø4‘ÇA?BŒÄí5˜)¶õî¯üµYF¡¹˜¹‚Ôîşrı²Ûo&„´·r=T?‹òÑºĞrúT/ î”Ï›ÎÊÔ6'É©T/dû½ÇÒ¥eºO¢¤™yWî3şz	°×zÁ„ŒöÕ´ñSµË)#
¡ÿÜ“Ğñã²	q>Ó”í,]QP‡W]ØR¥Y½¶(ÕÚ¬ötÜó…Eşu%Ê5=usãäÿÔUX•<–WØBP:Á¶àeŒËÇ2Æë³+°…aÃb;ğeä–‘a5e8Ş~¤Ê®M{¤tÔøTU£€8Ï×hçä¢$™'5äÇU6‘ç`W˜ğ€'½§ÏÁõ:áÃtA:Â¸N4U]9ú,n‚2GSrö„Ÿ™"-¸ûm)³Ãô$ôÂê­Rtye‚ô.\¼‘Â•0şËÁşØnº­–kT'ee¯«‡ƒrIpp(äVÏBè.ÆtdÛXÊmôÂˆã®J¶cv,¦™šYyËxËÀÓãaOĞÈS–©‹Yô/¬§°UPÛ§f‘¤öLB3*ZX´K|œû
•TÏ<j#ÈÈÏüFŞ´§V³œûN=Uö\½ñ¯",š8‚#öĞÒ_Ê$„ÿ“ú JÁ¨Á@ Üºq_'O`NvHb.vöEšVTîn_Å$YL!8w7>Ÿ]O¤æ6
!Ù[}–©Gª–øÈqß?ŒÜRJ4­K‚p’§%`Uéa2a2!a_%¢~ •ºl,+¦z×sŒHÅ¡ğöútV¤©( :»ÜÉbtÑUÂ&Dû’FËò7IûÁÁ•KZˆ—è
°Z¢€”§ÛK`™>é4 Õ­fªê¹Qö¥%j¦óE%Í¢,ÈT‘ku_7¦Bjˆw~¦÷"¤ş8CÁØwÌnC‚Şj‹Â‚8ı“Ó³‡ÎŠ_5>¥u$ÄQP‘š(ƒ/ØêÖ+İ‹•ZÀ¢ÁuÃD$%¡ä[lmÔ½Z›¯b[—g„M¿©ìî•»É™¿b½½îiøQŞ•›i  ¯V%BÁ© Œ³€À²LWñ±Ägû    YZ