#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="172053781"
MD5="606c97f6657f8968721594407ad67272"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20220"
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
	echo Date of packaging: Fri Dec  6 18:04:31 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿN»] ¼}•ÀJFœÄÿ.»á_jg\`U^&kÍ¼sK×9ôŞ#ïGSìC551ñœd{m,0GW–«Z(¢2”Ğy¯îæŸi%)ÆÛhÅ¿iõ*t‘ ç‹~„¥ĞCòOiğM&ä †ï˜ì/ëW=3ºx0¥’¢‰×Š>úâÕî¶ñT{lc4TÑÌÒjBo•yÛ]Î GÃü´¨bA"múİš"qäxÔÀïbXØAóg¯§BÚ(kôÒ²ì<èÏ[¶0¨ş<óÙ/9Q¤é¾¨>,)<œñŒ‘Ÿ{Â.²%ÊÖü ±®c±©ÿÄ‹“ñ(ª÷Övó˜@«7HûÄ\€¶éLVÃÿ´½‰æˆ¶´5'f¥Ñt¢¶aƒıú#ÂÖ÷&<}İmê½k„î­³øóIs½3¼ÖâFq
/ XÃäÚŒ.ÎN;‘b(ë¦äT‡q}ÅNÿ¿GöÈff|8›pö"~ùwEï™•îBİØMÿ«éÇş78^hp“l!!öÎƒœg[Î—ô8‚²„ôàöû’ÀW©Û––œåºˆ^{%@fİÚ‰il…_œMªÊƒÀÈªRŸto¿Ùı›wj`î¡_‘Åµ‡ÉĞ•’cZğK*øËK“2àv×œ\ïÇnQÒö"Ú[nÄšQ5Š­#ÅE^ufGòA£Öİªƒs
èÁj?lë¼'½NböÀ2o“Ÿµùç½ªÑZœÊlÍS3ŠÍ;Q8lD]UãŸó÷„Ò	¶Í5WßS ~^>Bj–]òQé8Z+Œ¹<Ú@erïŞ§äò3/mv­şDX<V.¢¥aƒ””TÈ|QE*(U/ÁD‰~PtÏ}7t˜­í/Ä¬hÊÄ^=.=d3’*x¤DD,=¾­—Â_X
d›))vS‰g¥r×qçÓÅÚyZŞ{»\¯6^dHüÓmèôïò±tØó®ì–¶gptWBYºQq"*"õåÙıYø1æá¬Ö0ùm‚ëŸûØhé¿Ò­9¾İ]ŞÏ‹ tÃÀÜMûSOc"ƒ5òN£#ï•QP/jÙDÓlfä¡*7pîSÀ;ÇdƒØÜaöÁÔ„Î[cPq:ëºÍ²9ªS­@‚–ÈúOËš;ãDeÉ;#Dç†ÁáÙ5v€S„³ÎÓ©¾ş^HdoÕJ¥^DcP×àÑfç¼&ã!üìË^8#PáJ÷šÿ²Öœ2ÆBØlw“š ¥z¨½Ä0»N\@\ÒTêâƒ¿˜®ÿRR±˜ŒuˆæŞ—¼¢#lù“ŞŒ¿Ãe²°×ï<ó3<L¾êƒãzĞÒÏjšFjC¹Û¥O­¼¹>ÜRÂö£7i^İ
øáıv@‰!•^©ê‹åd€™xïÍ„D/ÌD¹<!Ÿj€<poÿH"»Ôë¿)éµ=ë!qå“ø\½óÂíCøà.™)=álQß‚r	âgB-Gå±Ò8Ù0¾³‘ö
³…HÊ`)]Ëtâ¢AoEì„D
7àX ÚÀœÜC¹¾)öÙ¥HÜ0q‹Iü‡ºÅ	înD•ˆíØ|ú°íoèoy8˜B™¹¶üæı™áèÓ“aÁN¼FìlŠ0Ç,üu9¥»nŸ×Vš:æhî[æ0Ô©ÕÑòT´tÔWv“D÷¹‰µŠºÑ]Bc¸“p(¹^í¦8ıO­¬KåwÂûÓ[Óš¥W~(ŸXw·
Ä›N¼¤nz'¥ìk;ı¦>ìcNÓ îàì¯»')éRßE¦ÖÓ\„çsÏ8á9W0.ª„˜ }ğş`¹š<i… Ÿk€÷-ÀoWkîø¬’@†Ü8‡B{
û01.%h;@Ñ7â¤œ¡B°èš/¹}‘à¢äåFvB>ÅdõõÁ€ÅN“•˜ÚSÇîÓü7j÷	Ï)÷¤©ğË8GYU…Â.Ü„õ¶OºŞ.%W/ÂãÖİ¥ø¢rÔ4ršĞÌâ‘ò!&ï·è_îõ
--S8£×Ö÷âäƒ¸È¹Rçp, ¥GÇöÉòòôş•1y)ªÜ½zMïI@*m§±|è'KşTêxŸ…Ü&4«ğNxR(ÄƒÆøôÕJã´AfEpKs¸¤m0|Ë€…Œ²gxX6xÎ98ã“ÎÀ"aı4jºûÕ–>NQIùÎÄ53óÜÌrAùº) y#(¢²¹šÁçËÄq^>oƒékl»SÈUÁW€8Gq£[ê–z7f~‹RÎTĞ¹±>å„‘øvÚs$O*`Ëÿ,GåƒQ™æı’–\LğŞ•ô§z	¹=6BsÏ×Ëı‹ŸœáLÄáUüçg"æ31Œ¾käR ‹ ’¥ú|`VÑÄ%Ş GÇß¶kÏH9)$(k;6©7Æ8Cè€ñJ]õšS.ë¶8K-¦yìÅ‡÷6
ZÙñ›‘´I¸ÕòÀW{d°¤…^êÓ‡[¤/5R¦JÈ	§—ã­»­²ÓcĞü8½éæ„WwÛÙ±\]µ½ò">²Ì»ÇÚ¼µ”ÅH2l®BÄåö³“W®&î+ZC’Ïàø[°ü¬FÛ'JïIÅ)|°ˆ¶Äº-…Œ'ùF}öo^Š¥Æ¬¿œì¥Ù2¸(ê8—ê}àÃÉ¤âçÖ÷”>â|Zô—³¯J¥·©áòhú%ËÚ¾•v´ïĞf.*ùÔob{¸áñ$˜VlÅfv½É³Ñ®6ÏNN– %­Ò‰à`ãi(AxÔ¦Kºİ¿ñğ¼V¤aË^TÅéDì³šÎ¥®j(^6‚U ¼0D¨8o±>Öl; TÀ›ƒ—¤ÜÇÁiDÅ!:5ÔïX]ììS§O:àöÈíOpæûBŸCJŸ*³;2Ê½±ŒÓ2” ã“]³rhW	|N{wÎ ±/×ÔŒ£/–åY*O3J½Ş7ÓEõwáj·ÎÚöâ¬^ıã†ìÑ+¥BEÛànQèÜ÷Ôg3<ö«Y=¯Åz®lZPôñê¿53 ˆrbn.lôÚöçlN©é|E æ’äË™5Ò&¯MäÚ¨ï‹X0óCgFVv3+uïÕ#dÄè
eâp`ø ò’Ñ=qîDHY^èúë[şM)ñNä‡ÖhºlC)e›ÊÈ¼G©ä Ê/Ì¤ñ	ÏAØ+ñµ:h÷Ccßpª¹¶[N“©Y¯†!èNw-áÓ1AÆŠ:|Œ~ğúÆÖ²°Âà©N“@—ä1‚*#ØPÉKL"ˆ(ElŠÛÜ„ªuÕk¹–£ï~c^Õ<‘Å‚ë#î“T­ÒŸÃñœ®F1,a%3k îŞ1¼ŞäTÕ×·LÅİS’­&‡:s_¿ùßF|ËçZgÖ,´ôˆX‰Ã]’˜öS$Izz+Oç_ĞófÑú¬ì:ë¿‡6‚†zİgÿ«rMŞ`É|?¬¢¥ˆßÚÜö²²Ó’|ÅÔ{o¤}í$ykĞr³İzÒ\<£¸ëä×ËÚ«ã1QË?vXºû`ƒpƒÿvÌb©îV@ı¼~Bû¿Õ+AÉË:(Ôæ8AÏúóa¢jçı6ĞlA†#|B›¹n®¡äcù*®Ñ×Ë#.v*<-7mĞn:re~é"ØÏì'[=BlÆ2^±’w· hØrbÔ¨Ú&…„˜qe²iæ+`.Øxïù²t(BRh™à9²pqçÙˆÎ»LŞÒ¹ÕZ}Ùo¢bS-3áÃ;"ÇdÁ4¡AÕ²±¯·è<è,4/z•ÌRÁ:Ü9º ®z_êœ¸ä÷›÷"óæ)–LSqx÷ã$FÎâG¢ñå9ã¾„Á×}'Òta•s#ŸÖßlœâáÉı2ğ||3ãgËÎ2+4ºÚ»[ÒAÕa¼SîÁİ/£W¼Ö’v^ƒ¸Â°6‚êKfÖo‡€æœ<‰a.ËúxÂs»÷c!¦Jn€Ö_u/ËÈ.MÂÜ¥)ªşš{}zhzÕ”ºÇMÜª¥0›`n$+ÕÃÖ®ü•¢7Í…è®¯g·Zd¶¥+£1a7Í^"rXÖ;ìÙı&šz±¬ÎJ>¬À^×%¡ªnäE™òë-HÈR™ë»*ÿ_Œ‰Ñ­ËZÏÖ(ViÔG'aÄôu$z»´7a·TW.#¥ ã×!Å<ÄÄ† @•Á±¤8á¯Æ^>TëfƒÌÆØ#öÖˆøæ0©)¢5Ve$vÏ]¹ÖçNNe¨Kp^ºÚË‚(~oãrÀ%;‚.!œ„íi$i¡ÿ ï¦H'É¨:r[%[­ıú³#¤ñV"8¹.€>],[6e®~K{óV’U%9¯ÿmf!PÛİy\–[*™–¨vhBÏ9U—n~aâåÙl)ÓÁW½›oÄØ“Ñxöç{Ş8F´§Qruş”ÚH† íŸ¤”çPŸÖSº›Ù_#)ÂÀÍL<Óúh^Qìîàï÷Æ­m'Ë‘dÅáÁ`GhvÉLpäî"ÅXŒÔ…ÏÓä4İŠ²Àp"uõv(»ó5XıÀ$ÿÄÁ¶½‰7fÙÅ›ÌàyÎf5I¦#êÏ.÷WíZÇÚé˜}Èn šø$Ö VÕ^ÇG!šÇØ»µ‚Í‹˜_€€øP%u{—>äŒ†´åÚ£Îo™G˜(»-yB©›İÈ´œDM†0Ùñ6’óâéé¤•¶{iù?iôÉÜ	>’OíäCæ:¢Ã?†egôu4‰ğ+Ç–AötÁ¹\yG×³Ä·±`ÃZÇïÏÙ:·¬äHjr×ÑK/-ğ¬%(9ˆŠGíŠñ³5İ˜‡Ã§‚@’{¬ë®xI¹œ‰M 0÷bÓ<K+¹¦oÿ›
ÎGÚL6æ×Jz¥îæb µ­ÑF°ÁÑõu/ÓÉÒı>j[í/Ö«üØ}‡oÄÛv;ÔxµîÃ @u¾8ú7,˜Ò>™Ës@Å*ç£3½Pll`úŞ“?ã›6¥?.Õ(›tÅİHÍ
ë×İ	SA¹ÙİßaèO9ªŞƒuD³¡ÖsK×údŞô{âÔ€Gè¾˜îX1é¥"üÀÉ7½´•€óš¯kLéÑdUÛíQ±ÿƒ!-A«
_»$O·Ğy ØkŠšÜi1MÃ‹u×d°mW²ÑJD®0x;ë…B„í*H"”a<¢âñ}ŞIµ Õ³­tÛ ;ø`)R%]x¿ œtá¹
,¶wyQŸåPÖøµ+L^ôPP„^ *>Ï}jYµ…Nb¡¨*p7a5ÓŠ/â‚®½®ª²Gú/¼W—N»=Í’<ñŞÏA¹Ê#·Ğ$ŠµœeÀİSäˆìwß5}eñ»šöù"r]qƒµm³£–›=º…ºÏŠÍ·:ZfËRË}ãçÍCÚ0‚æ<ÌPÿÏ.…#Ñ`:JŒ"œÊvªPÏè‹àßö—Öà 	 ¤Ú l¹²Ä}EºŠ¿şö}°şŸ…FôºO±5O9Y3sŠ>~MB»-_ıĞ>2†„¡P¨ˆµxULyÅÀŒ($ŒÔ©}g– CråæÛ/eÔøÂ”xY¯#’Ä	(Ëå,ã\pÍƒ„+ÔFå*øFÆú
iZå½eäé,M9âPÍÇå ï\N?è÷pV¤‹/±XY6*pŸ$ÛØT%È¾q×İ®ùa%`Äá
Œ±c|ó0»>úHËùæŸ¢!â4pá3ßL7œ¨	Î³Û#`æ6 £iùÙ†Yì<Û±Bğ:üu¿èÃü†F9Í%—ë65Û´‚¹(ƒ6&6K¶8oäíe‹Ä9Ñ6)AzPFüs¥¢Ç'M}°ÃkW®_ë¹—ÚŞŒs¼†;é˜*Å±™ŒÌÌ¸¥vTÔÙØK~áğÛ€Øe€ßòïÔ_Vo¯Ït´’WæG…¢„ÿ´Ëàh$=XøÊA7ÅàİŞaõVÏ;âš¢ãy.ëıGãÅ­}U2ßˆr«aL¸ƒ$k®©íã„VšlÜ|÷ˆİ §~b¥1)Reä}i¢­¿ğjÕ–Ó€„c†#%$K{.p”1>bÂéãƒDv?+õH;E¸õ 8¥N“ïÌZ_Ş³ßøkíìª¾ğÚTÕI<À¶ p;™W=L”ªö`µ%úóğë¹&˜>›tù‰®«/„B|«ÄÛš©rü!ûX¿:¹`èy}©9€ TıAƒû0Ôªæ,¹h¯X@ÕòşdhÅÇKéohó§,YuW®]$„qS¾ØH›¸ÑU:½4‹ÂÓ³ ~â'g01®!Ÿ4ˆ€/)G¾¶Ø£îˆg¶½âÖŞn¾™À@}+¬FoîË{,€¨b–?ó¹
i­c~åÕ6Iøaœ	Ğstl*tYDb‘‚ôwhÛŸêğºÊ	º1¦P~8›­ «Q2H‘¿’ğF\ÁOÍªí<U}/óõ]Ç#Ê`Å‚ªvh°|8úDµ¦'	§ÜÚÍ£~œOïîÕ•ÀuNáÕÈç½%÷$EEü:~~Î‡^UN‹äZ#/Ú|xçû±Â,¶F¿<œ¨í¤iÀXş¬ÒİÑJoÎ4r.ø¨š¸|nZZ÷F<5 :Tİnº-Uñ>p:4RJê­ü´ÍÓÈ¨Å‘<ÄË>àÛ?]„¡ç®s4Â	ëÚJC ‘á&&¢Häî49nÔ;¶,‹bğª^kE£ÆtĞrÂftóWb¬NQe4_ 0"ÌLó…°Âm´$Ş ‘3¡˜‹ûÙªÜ—Ÿ{NÏ 	ƒ•_îjQûàIĞTÛøÎèìä•X^”…•¹Û%wÂQ²h@S\ÌeR9­”\Ö‹òf)V‘S|J-ÈXùvºªFAäÜˆøıºö Z˜kúÅgKS)©‡Êº¢LÁgçYŒ\Ş\]aBÀºVóx÷Ó)KP±ÏÊÿªG_ªähŞ^z¡!òğ›k‘Ã‘Çt|áĞvdÿ.e¿z'4 GO¬ĞÀºífm3]·î‡ÎŒ-!‹•z±I°ÏXOjzG´páJögû©)ˆ22¡Z®é y^Ä´în3¤ q~›Õ=²p˜^ZÏCÓ2ñ¯ü<A
Ê|¬¢¼w8qYmŒf¯·“YÕ	ÃpJD
ÖZ
¾¸Á,ssŒİ[®ÇCw1ƒßv£Ú3œÚm¢<…ü2u&@Åt’’Û,>.¤züÃä_øş ™¦ É¬B1ÈÖ¹óEõ+mz±õ‹òjˆÈUu,Ï/hiûÅ%(‹Ü{)1—İ‚Tİ±lxF\™šzbğÆD7 N©ÊvF“@İ‚ÿ†µ×f¸<ü²Z§4PĞsS[™« ?+®Ë*€ërvW*)&¦gşÛê2Û?µw¥†£3[òãg».©ÿ ÎÑÙ²HÕÍš,‘FmFÎBIÚéíSêÛÈ·®m‘Áá¥ØücØ
<¥^ÔIL»İÚ“ˆUí3#ÓŠ·ß´•û)å8øi gø¬®¢šhŸb-/Ø‚`EÑÓp†0&¸ER|ÿø‹—zuÈ›{_§£š”s”ò¿…$•h?û»P?öËÍÿ8sÊs½7AÕ"¿4VÃymOœM21K,Ê;ÿTš[<²uK ‹GÃ7”ıVıW`xQZq1Ô/-¾£íƒôpÜªG¥Y:Ìi9s‚›Ä@aïOzd†¬Tyh"jËu•ö9•¢£ÍŒ³¥ü¬¦û§ÇİôP>H*
Eø˜Z˜ä0½-3’=ÿhÌRÔŸwmÊ°¹;Ø&ÕÓbœÉÌ³$üœ‰m;?Z›Ğ/PÃPÙå‹¦aÊ,¯şûø|xœZÍÖl•×oéÓé€ßÁ(0¬IRrı÷®– ñ3W ¦™9ø¦l¡¦æ‰>Ë³¹«ğò )“}ë½V‰[°=,áÉáƒª
’%ş°`u•Ï+là/–Öeñp\Ôf`Ï£¾'N¤~èxGÍµÈ(áv±28b¼şZ«1ŒùÑ»!e:·ğVÄ¿óê/Ù&*¡èı:&Ô±–O±ÂRJÉCD©L@ÌŠäƒÌ˜ ²;{':Å¢çÑ>¶¿€áWŒv#Oığª´×)X~Öˆ“ãÜšÛ,vCòŒ¹C>DÓº´‡¢V5|RÁ³œrÊì™²B¥ş¼ı›sh¨Hc[ãÉÃŸµØ‰Dnµ ìØ3Slæ1³\0éğÎŒÊ ¨Š/®&U®r&eØÒUoóıëÉC»xÙİ|ëëKO2k\!Ra‡èÂ4İcVÊâò*¶ÚÈp“èÌ#»ĞÓ,-¥jg®`÷´×Cîµ«îº¢”Ò¦+·îêÏ*ÇXõvğ#LHÖ)¾ ì^ej<,×ÊAî#8gÿ$zPëß~¥ô"°}Ş"áÎE|[i-¨TÚ”3ÕòÍˆÖø1ƒQ€)¿ZGsñ%üW±n’¼	vgô*uq Ó$Ësh×®ä`JˆWe…('2#-fy¨ü'|açG- µubĞ
±¸d¸€rÎ‘zÖ=.ÈËxSÉ˜HRÀp~†)% ÑxUn\ hò3¬*³`l§›ÓÅ3ò˜	¬ÿ¾˜Ğ|HM'Ñh(`ñ`eøÈÊ‹/v‚~k³GáñCh3àØâQ	“ˆóğ÷0Ÿ%6h¯PVö–‰Û44¬ÚnÒ¾—i)ìÊçnS·z/‘Évµy¿¹Übd(ÒÚwºåşA”êhn+ë½¨©Ã…ê,òIĞÚ(Ò=vºğN–rH+½İŒ~FÍ›$´ùXÆ‡µ¥<¿­Á ©?OêgT€ë’3È°Âu~"Ç	U$½¿n‘X?o×¦ªÀ\’	¸ÙˆÏ‡4KÜ“¤q+x²P{•p'GÔ@&}÷«nf™‰œ-1·Âj™µOãGY;eåÔ`d'q¶â­&–ëO«õ=’á,5e8V‘ú˜	ğ&1¼Ë¥¹iYú{v¯oÊÕ§ŸM¿¾¸ç`K”Ë©^Àh=o¡Ó¥%ÌQûÜÀÇ|MĞ«»ŞJÁsşWoH½Tâ‹Åµ~ïªğ'¯ò‡ö§ÇøUÿ·ÇØC=×÷šM‚æ5ĞQ6Dİ;¢å\ü&Á°~õAs tÌ4(7³ó8é«³ÈßÕÍ9Ëë<‚]&)ö,—´!fOdâ„•¬úËå!•-&	Ï(6ê^\ÃNæ©œ?Ã¤O®EÏ¥d¡¥7èŸŠ.ÀkĞ©;ˆÌKN®ÉisIuSèswµroˆ–´¤PWœEä+!«Ó[Dáº ¬Kóù-§Øs°bc`D×¯ŞÌ(s2#|ıv©°À<jcD±ÿŠ}»PzÄñjwx¾´x*Gªºc#­QF8’ÍPtp‡×†ÔœÀtsPøKNšd|Â‚17ÕqÎmŠ(Í½Â¢ò ²Ş oâÚd„÷’jB§ù¦è•,;Óab£ÚjDf<Ût3wÎ^¡]©¡I°-’=ÿ>A´DÛú¦Õd8^ÆEg–%óÛâ6h]ùö½¡Ÿ‚s‡Á¨¸ 4ZĞeÃQÈR½›Ì²©‚ÄÆQ³¨ÿü
«—>&íZÅèòG&Õˆn1£+nÑ?ß»ÅÑ àÂ(‚mÑ¦CßqwQ˜¨,ZTC™UDğJ* gçİ›q6SíêiÛ‹Dúã¿»0	¹Ê:lİ`Æ/åE&Ğ ]ñçn-®Ú
¶Àµ'`yUæ@kíÏÔ®W3é\ËÌ:Jí¾tôûÍw`Ğì™İRÀƒšÄÕŞt·)£ÚRØ¨9ãíÅÆ£ @…QÊùz
dÑç …áM³ïz=Sš}?¼Œ†›|3kîºˆå3}/D¢Íúo-[[OpÚ'k~Vj=È]z-cPÆUsÁ?i<İ0³BÁè:ƒ°ÕÕë4Ò­y‚En¸òˆu;>h±ÏÓM×:×?“†ƒ­¯0=%}8ÆíÛC9÷€?—¾Pí±H–’*k<¦»¥QJåÛn7"–€wÃ$q$GX2î§ôàõ‘óŸ{ê×xhÊ2±!ˆØÅ)Û<WH“$]y~“&UÎ´è¿	Zd*_˜Of[ƒ•à‡m]C¬Ü9ŸåµîÊ#@½Bö“Rr}šÁ$uÄÉC@Ü‰Ô?÷5AQïfš(­1í@LõŞßäâ*àC6TßÃ+µ¯ÔaAx›Á½¼×%à)[ˆt ›µ h¾Ií˜]e¦²f%9~v0ƒíØ3hØ¶şš}û @¨Sùãâ,_tcTà[ØN£Û¸?xĞîeW‘ÚuäñJRbƒö˜éµUtÛó½4X‘ÅG8˜´j¼g´"£µÒjS¡.á»ƒÒ¦S‰€×sŞ‰ÉóìÑ2,,´©<œ,3'£Ã›qslñİ>çˆ=å« F53¨×h¹Üß”‘ò,È-Œô=lnøƒÀœÕø(ú•ûP€U¯1ñ„€ üm¥ï‚\Ô8¶ Õíí}·R²ßuê;T•4:Ñ¥Çœ/¹(üPlÓêúZÓ†K‡÷}¡Ä¡àßù‚¨ã1 ø@´X×ë6ğc$ªVì6w3QÃzÇáêTG2]Ï(Êœdü×;„WĞlãzZ(à0($«Ğó1X ½¨¦V…adÁCñª½¬ĞuJVúğ|jcL÷Ê@«!ÈÃ¾Z@Ä†@ô¡Qİ’"%=›
‹0uãÜ(ÀŸæµÉm¡Ü¢)‹ú£oŞâş¹½aô”Úº“²h”<d­)Y)„|İH‹{L½¦Ëx•i.üÅ§[›$„·:FO$kæïyˆi'¬ĞC2ÔåGJ“ØÇAIYHÖø!Ã„è]à1AæŸIOVÊp¡Lok!¸¶ÙñRWW!·•ŠáÖĞg‘{fóÓ‹/Î-9¹W\¶‰¡Yis~…Q!R€nïpG-L4Â®VY±ßè?°¢ edÈÓÆ†’/ˆPV¹fò<ŒQ›Ç -œÇ’-•Æğ¡¸£›IÑª@G™}°|ğ¶úkë'[A!”šÃ‡©8; TòímërÁ:‡ÎÇÍÂ¹ë^¯àÔº©oÎVüÌSW„„!Sıb?„ÃFM%†ùZªâR€®i¿×³j˜ÆC8È°Ş8¯¼f&í#D²G>8œŸµ ĞQôã£Ò˜¶°ùX5jDNf8ô³—]roRµ¬¨ºƒÇ	?%üŒšõVÛp4–Iøzbÿt™ƒIFtM~ã¥£=I0Î”¥/ ŞúìfJWèCŸl¢Ÿƒ:àf”JCfQ¸Yz7PÍÂ8,	®è‘ù<ï®·vÆŒãª¶g-øé$âO™µåµ4áY-ÿ’8¨ëÆ¨´VÈÄóÊS€¶”Õ|¶WÛûµe «¸W U…>K
Ã=k–Ú§®s4÷'úï¥¥¡š6Ğ“Ô“³CÍzìôõìN¹#Şc Ú”“bM Â¬"¶€êÑ'áÕ§Ì s¥¢!Åeaî/ÇE»Öš–Åi!Î3™gQ8ÀöÅÑ•N5:u[K«>œ•hêË[Û.™O»Äêi»"Ò¡‰ÔĞÍqJÔ<}^ºR¸IÆ+Ã4«#)Pm dT)gúxíDn­ó¦ºîQ[ÇYÇ ^04©¹%ŠBª÷d¡¼æä¢õ
î~W×Ï¹w[¬‚Ò£:¨l'I3ô»uÊ¯‹v¥°»ÎîDKŒ1bûqÛ~ÿ9 ÛV»$:½åè9”7‘×ßeÁ¾±¿Ü_}f‘}rÊBÖPÁcÉ·ôŒN!ê ûIåÖ†_€H«×QyS—Ú¤\»VúÌc$¯È!%G2x¥V˜¹²Oå‡}€‘õn¯o„>h£O…^ı0°TêÂÖu°G˜iTJÖsô[öâ]ôğæRäãÁ©VŞûßR6ğ²nìÙJcH¥,G¢Fúl‰WTĞ}õĞ1bá GVsn2ÚÄŞ~ßy¦	Ï…›'”¤_"SşÎYc‘	Şà)]ë˜–¡Ánµ>ä¶—Á6Æ£fÃI—]ZN	©âéÎ%ĞUçO¹JØyãwäíéQR|†ZNÒ%z‘^”-W`7‘™ˆ!Î‹~Ã+11ŠñïÒÛ ¨ŠAöË™ª“cJÿ¾Â5û`Lù¦áñ‰Û:ğ~¹Š½<µŸO8Q	c7÷Z´Æ™~ü°·ã¹£äq¥YP *7VÿEæ£ù€pı¢kã8ÇÆRÈÑƒK™'Å~'–Cd²GCGPe˜lı)Ü‡¬ú(¥Òó Zÿ.³é’?ò`3ÍÌY.`Ô`×²¤D¶;nô[;{–ãw¦¸§®LâïEv*¦­í#ë_­ G£’¦ŒB¾S‰•¥NjâÄGµğeûJÀc>c‘Y¹W2É»ß ¡çˆü]óâÄøJòö-ou°l*»ßcÀct™T³*úµ(ËŸåCªR6%&2ÏìíÕob¸¨ƒùxÈ%·ğFÅ^©SçvÃÖEG$ôÙ)­‚áÂti ;•Ïo®;D±4[ šıÅÄ½YijgsZ!±&‹~«92F´\ÜÆQB`îpWÓÀúö²Ãá*©êOŞ3™¡L„Ç1U$ÜèÃ¦¨#Gê«Êî!Pvä~Ãä¼0b(•4ÔÃ3\
yJq­}¤AVxj/Jœb¯o‚¬ã¢ENMœÔ¡Èf4	V,RiÁ!b¢¼Ë›Z5V~>ƒR½‰cä½P¤‹pÿäo÷Ï•lãSäıPŒ™,ï„9"rªuÁxÌè¼\SÚõ¥ç@Æ³xÌu>=$}çÆ‘H_G‚ÖAÃÀ{Á¥ú‘4¾÷L)oÂĞQEµJ=†AâÊM†"³Àu­;Í°flÑ¢÷¶ëwÂûôí°ÇIŸ;¹w ’8Îg(Š„ı4{Ègz¤ÏOÑM·ÒKş!ê™[Ü IÚ9®«ø«,ïÅà‰ƒ1q×ğ¸#@…—Ñc6ÔŸıÆ—§ßVR-25Á¤Bÿ”cO“ªtÕfuîd£´ßu_Ë‡ÛôDÑw” í>=ÈÉÈŸ€ôq—L®Ì%pYº#¿ª Oª‰sòà¦¦Èû‘t4¿ç7*AX1Ò ˜+Ì¹cÊŞ§ptTmº2]e!«º¸áÃ ×Tj2=•†ÇıNúMiÓÓwï¸_–eR,ßÉL˜L!5[×Á¼0$İNº£]Zjëªìkì†zO–ËÊ+i¿“¤ŞPŸïÁóˆSÖü÷ÕcÆØwWjéÈv6äQ#±‡.¬YBö=—çYã³~sv·ÕßÔÊø°#Â1!:](!ìÉMÉ±Y¸ˆ\*<¥„;­Å°§w’×
‡ÊÇœ­vêds{~Lñö4o–âù6^$Ÿ5´=Ò«ğVkÍ_qN€®"±ùóÀ\ja¡0†3áE£böö”Ëä5÷{Ä}e´Öyµ!û&ïí:F®@ÀJìnæiÉ:ç=!—‹ùGò«ÔcxtUÒhQ3ò7ÅíÙ¾›¢ÓV6{,c¤îÆ’ÄË]8M¤t“ærZ{±µ[{Jd}"‚–Ï¬€Õ|óÎu•¾:Ñ	¶=—RØîSV	}ëÊßıš¸‹S21‘é9È,è«àq¸à>úCtü·D”’òCÀC¼®2J’°Æğ4jÛåE¨¹yÍJ5éÑ‰­HûüÙ[»g&+KÜ7ÿëé¸½(w¥øøÆ”UÀpm„æ/X.Q;e_¸–<w¶ä£¯Kª:Æÿ`fà¥ï/«Bş™ÔZÜ¸Ê¬ê›ugÕEnïìMU[„ÒE´
bÉòì ]­UÛf~÷xÁµŒl³ÁAƒJ°>&°õykvmKÀ{D
Ÿ0É~èÿyQºÖI,I(óXòd%šÎ
vşŒÕ¹ÕSeßyÎ*‹ïG°º'¼5ÜqÃ=hÙÀ‰Ys™·Øf½&˜›%‘´çji
2CİT‹6ëçºx_‚| ;h‚r¾<èFµôèwØ¡¸"v†÷Ûne±c$BZ¹öú¾Í±™´Kdp˜)ò½qòŸoüÓïW:õ¥_2¢4²g(İGğyJğ‚/q èë@Æı† E…åµÚ,„5Áû“Û³†Uû?óáŞ¹Æ!!„ÜŒû¯m)ŞX•T‘sCYyPáüÔwco"À>¤ãç|kÂ4¾hZòÉLCU%Š¡ıÂTÿ- >œbå³™zÔ1‰XÏÖ˜&¢9¬‡³õØ,‹¸ë”ù}ôûUKœUñÒ>Èá´IO¢İœt'>’fN8§Z.¤8!vËL¥ØC•N0B—ç_øavAâ§Å1~ÓÖ C—y¯&9h4²ŸÑ‚fF3öõ†s@1ˆÿÔ‚¤ s(`aîƒYP?£&ÃbxY/ÜÕ:SJ(O×¨ÑÖ¨™a!ƒc„Óq¿²d6ÑÈ¡Ï¡ÆšÏ°Ğ–Øº¶Œc~‘PøÆ1¶?rÉ‰ØSÁÜ>Š–U2á4~:neìôém8eÔ¨c_ì
•˜“%›©¾ømr¤qŸô÷EÿM·}ÎëÉ`Ø¡`ÇêŠ÷1Å¼ÒõÅ»M™s¡æ@{i7%¸^¡y©`×V%ìµ.0Ë}§áâštÉU–—Z­LÊ¾lFµÎX_8ÔTME”UØôıs—)f¹ÔdeD]C/.œƒ:‚²Ñşî-/‚Œd8èpˆx–ñ
1] ·SeÏÑ‡ŠÏ¢×Öå¿ùMÃ×6¤3 S¡Çğ…U¡íZª«ÂÖşID@øÄPŠš“G*“]†J®Á‘)¸åuİÔ1CøA¦®“¨n;²Áf¨ÎT#~c¶“D6c¤F{Şërsáßaê¶*š—}ğRb·Ä’­ÃešÅx)mŒ×çÍÅÔ¯¯'NæùÊ´¡¥€H*Öo©²²ÛÊ‚¶£å è‚¼ve–¾âÅ0g7‰'|4S÷&ÑêHÙÊx”õ¦"‹ÎåvµDn>ôfÂ×Š9iğÙ|¢¸ÒñOŞÙsï§í§,ëcÿÁ‡›‚¾Õl™—İ¸L`iàúáu_]´Âñ½Ä¦(7YqA5¬S\ÙrzÚ@ #Ëü¢9ªg"~«n…‰ÚÒX¨bu	ó\¯îÒèÑêÒÏw^OtÁ*œøsó²M(¿­pµ#—ãÈ÷X[“Ê‰P¯G™åáÍU“­¬aDOwò»GFÊ•R&A)‡Ûáy“ÒpøwT„v0´ë!-$ëvU¢ÁCMä‚X|Lğé1û{Óè}­yg©½J‹y©ÑŒÈ°Ÿ‘ûu”5Ç­ö-ˆÛÎSl¼2¡}‚“YĞe`ÃŒÃ.íÅN(¤À6#P©ĞÊ~Ï°Uè=ä
îB~XFÃxÉ¤î†gº%5fôvĞ=*^iK8í4ˆòSÂz„sÇ\`×+»Ôd5ØYsĞœ üÛ#8ò²FK»üÃß=è¢TÆ7˜.SJVc(êorNl¶½‡îB¾n(Vğ„ç:ÅˆV¹E6 Xµ ¥&;1Ï Œî&¢amÈÀT@€V	T ²Â‰zd—AsøÉ^—~9!M%ûÓNõVâ/ÀDŞ•úÕ/¯°¨£ªkdØ)Ìj\aÂ©fgÚCÁ¸ËÕÉy‘<¦ŒÏ÷GPëÒ=pjÉL
0Ò›»œİh)
Úø•€í|/Zî³¯§çe>3úZéãøúR\2 Ş—cŒÙV™Bú«Ñ¥g[2°Ú¼qà K‘euF
Ô¡q?i+¨¸ıè5·öÜµsœ^Ğÿ8Ç¶!ŞÆ+¼ÇIBgvà¾€cp¶G»”ºr*:)<m¸À<´&…¦æáÃ¯-Ï[ÏûÕ½Å;ú‚¥À7R_OŠÁÀã¯ºÿFÈéš²‚¢J¿§ˆ>Xş™÷¾-Ëã×ÈêóŠøÏvÀ<>È{òXxÕœï¾úõ¼|AD¿´%r«ƒó‘&DË2§ Å.IÆ„Ğ‡ }¤Ö2>úwBP²1	ja eqa4±öæ
=¶ĞVì…÷À{!ÇÇ·g7	†t 1 X!b¬ùáûNK2Pu¨§P —6Ó/°“Ì¶KX$'l|>÷ä•Û[c{œöìZÔØ†Sã€’¨czé˜lîKÁ{ƒ6PŒÍÈUhqu“Gngñ°­ª¤”¡ºñ+ÈÕÑÜ`´3å3*{ÒH{3Ì‹¯ÏAÅù°¨`˜j›Pèf`İ…cw5ôH¦%AY&é×ãïÂ@­WL+É,/ÍÌQ"Òv^Ò¼S3Û<ad´9¸4ò™q›ã›&TÓÚÉ°ß×ÓëBêÒ€¯‚H¿(\j ÁìbÆU§Ğº…ZîE³Ìô¡`…G‘ğ¬¹³	µ¹)AŸÁ06kq.éü&/??oAšÔœÊÊ·5=±ÜãÙN©ßJG@‘¡RŸ &+€ñ!…n­#İVÀøZ¸~H¨Ú?©oíşq¬Õ'D÷^Ü³mÙy~pwIsc{¯h%B_ÛÄ28lpHò^PDÍĞ6Êñ/PÀêxsDWıó0‘ò¼GGªEÕ·´–AVıjŠÔ*çJ4„]rtÈÿÄŒkô0¤´%ª©@PI¤LgÖ4·à…¢Evùç•¯c¤ØCİzˆy¢˜/ \uBzÃçš3£0ôaöfÙ¦¦±ëî8b¨ØÜf†
—FCó›ùäEbÎÉßXKû Bëš·3æ©IpV2yüU*?“¿pÉuÒŒy+İïi´İ{—ü…à<\‚‡İ|ı£Sö®³EªÁ=Q0õÿd:y–ËÒuLB½åg©-Ìşötí¤Fàì¬™ê,¯¢á¹mû…œ\Áé%Æ4>ZÉ&ÑK1G,tƒDÒ9Æ/öõ‰ H546i-ƒò@HW±DD«‹¶zËà~* ŠâÀHìÅî9>(ñöQp×+Ü×¾ŞÀÑ6P¡?Rrêe[˜WµIü•ôï Å’ÖéÙ*È3}ê¡µûõŠËKâ«hš~°%CŞB5¶è/Í•ãy‰0ey‡Ã»tbÛ“h7¼Õcj°Â¤V
) ã«ßnè]tR±Úœ¥Ö×Ğƒ#åO†94ÍÚ
€­.ˆ§ÌÈ1É1ôâLS¶;	Çöó„åÉøaÙs„:¹uvGO"’tÏL<ã“Õã>ªÉÔ­Ã D+ÍeÕÕk-¡àì[>Ş±¢"@>Áj‡+c9¹ÖÏO~*¨Õ?p\W›È.¶hŸu²	"7 ÚÑ©ÖÈ%²«yÔê $ÑVÁ¢…Q˜d•­7?]m±³ÇˆëÜî´/7Åm Ş*AP+Ûº¶”ú˜¹Ë\™pg6†Ä9,t[ìıh‹~ƒEZS® ’@Ş»"»©‰Ñ›ºt¬åìéLæ#–÷n›İhı¿üã.oë°8o¬ëŒÊ+v®pXëØ^8ïÙÉÊueâ¡#íÀü
<zñn°
j\ÚwPo|ò¨¤c[d^Û–¸û¦5¥ƒÁÜ'¸eŠ)`îËò´´{Ã
÷3§®5ÚDÙáÄnÌXKß|™EXå¾/”]VŞÆ'×{w×é§àüşn~·0Pô‰øY|vªtnM97¡±Ø;ãT‡zàì`…”L #¢Ú•J˜qô7VYÂ:÷şÛ^½Šä_À]­–*„­(ü²^f1•jIa“‡ ÆƒÄ–÷»çMö±ó2Ôw)—âÍšé£\•Ï&`‚‰?ÙÜÒe®ı&b¯)ÀO¥&µŠ»ğ· ¡¯G<Ëıéoª-Š&m_EÍÔÅ|Ê£n"í.ñï;ÓÅñŠ+·9€Çöo›,Ü€I{+²q„ßìzoÍÚ€b£ÿºLéR·=š£õŞ·Låºpwo]”¾‚š£@e&»²íEì±ã®Â‰Ü.³VwÈÚ¥¥æ_ux9Ÿ3dc’øgÓêídäıÈ'´û:clµ4cÃÜO÷7J×CjI	^¼7ù¬~£Cˆâv
½¨×#Ü¬!~v-ïò]/°Q ìW¦tt?Å^Ğ€GËë&ÇáıƒÒ_…E8±È€÷†SA“ªEYF\ÍYÛ-ÍD<¼íân¾Ÿ¢ãUÍÏæÎ%ÎX¼~ª)/Hª^’£x!h5ÑYálÔÚŸç>åÈŞ¹ïã<1¿p[½<Ş½:ó¤#¥“¬\Šl’zm<±¨õ(3Ùûi­ZiEÏ¹„˜†KïPÅó¯m*[ö5Æ%gSùTt{_­È>î²4æde×è¤<óâÿìél©#KêA¹æµbåÏT³˜:\ ‚<Ä¸ ÖrB=yDWçù›#Éˆ³iCš>–~ªŒz³¶	¬l(¨*10:iÇ§òAL5Ï;Ròse=Gk€¿_Ó0—Íjñ§g´\¡¯5|XéÕwåä5…c–SÀt÷¹4Z‡6/GëS9ùÓ×İõàô> ûbækü|ÂÙÅÚñÎQ„&Üj†Ùi´÷ğ~Š–Rp¨>€¥…ÆÁcv€|•hB«è[ù`LW‰ÂèZ0jË0I™Í„­•µXJ"mÆØ¤‚_É‰@!.ª3ËSH©§<ûì}ôR¨©Ô<’©‰¨B$+af´-ª®…ï“:³]ìÇÔËƒ¡*.Ä;{bfêĞZ­J‹ÅJ©Ô[;ÿ*gvŞØiÎõyÜN˜ŠÆRPÿpt ©&„‚©FÔàï[:=˜A(]÷õŠ*Æ`NŞH¨§ÛŠszPÕ	©Aº-[İ¯æ-d®8éçdîäa÷a·°^ã0¹¯ü	~1<<øÈòóÖ`¶$òÚ&ÄñUKUÛ9%„×ßÊPl^ılôÑ!<„„ez™÷åõ®K1	œ¸HOßu¿“h³~Kø>–Wıv¡÷»[·ÿõhØï=É ‰ªq
fÑy—££È¡<4>º	fØI….m¡â©'¤«Q³HNyüÕŞJLn=Ï.›ªò¹ü›(%Ê˜œuÃ´k” ¤ˆ>6¥ÛÓ^h8óá†×@9ùgouJŞÎ^ºq&•h;mz+E?é©O};¯ª`Üó—tølr°½×z˜¡§œ¿Óœ±Š™¿…]“„;,f>°dQÀØu\•8S`=.cwM¢Sˆ@ä=ü½˜ŸåÕz0nñ.¶Od«oö§…˜^),.¨úy¿Ú”İÏªQ¤F›®§Ò¥xàG¿Ï`ŞÉºi×_ÄÙ…î°mı,¯ã´â¡"¯w~ºšf‹[X~û³ép]Ã¢ãîVï	&cMÙI‡³Øˆn[ÓŸü°zù‚A$Ñ s|[²\wÌ§;1^¬O­f$µrxˆ*ÉJ	à¤D(r… ómÊTS™('±‚/'ã_zDmQoÔÓ$…·ä)È—Á£XYaù2Aèù½4a±##•7Ô9³KÁ9™*­Ñ°!ı@¢³{~x$Ñ\Ë²Ëó¸‚[îp‹TqêÒ1¼Q<âsq¦rõ%=dÒ
¬.û—f:´ÒÙ?]pŠEşxmbÄ™‰®¶èRœ)ÎÃ¼£GóÏQ¾çÏ…âmW¢ùpw`sö¤Yæ;Ê®­1Ä—H
5Á=€tsöŸù„Ø÷rÉ¨v
Ô¶ VP¤vš•PîZA>@=á!M¨o?ãWe7§MëÎàøz…x«oz×NÒk‚¨!®¿W®÷ïçfb
ØvB·ğB%WÄVìcN½	ĞOl#Cfñ's!/_0Éa8­QT|D“·É¨Ö >#€ªÄB_
ã6&ßÍPA/Ù‚¢µˆª§r'ÄNŞE|¼q}îãxt“ßÁt«=­|}³´q»ºÇ!qk^ÈŸÓß³ü?ñO%ˆŞ®ÂmC¼Ôì3÷taPåcP¯(úÆqÄ›¯ş€ºe8G¢³w¿ÇìµfOkqHšæİ1kšâ½ZX+vÑA±œ²²öŞ/´õ¿Xû9wÕøQDjx‘Ë„ög|“‰2´Ö÷YŞ–³àíu¡¿î@ÛÛ5t·Àˆš×‰…Æ„.Âã–ÍÀ.Hªìé¼õ¶rf»¶ëLT¬_­_ÅÖöı˜âSuo24vªÔ›j7Í¯X3fÂ_/Isµ•+/’Ÿwˆuq°,£5u†„ı‘nRÕÍë5o“µÄì`É‚Yd‰ƒêìdÃ ‘SN¨lÏ‰ÊXÎ™ˆå :>½ÜË8xHÑOqªÜ>{©¤İSë:Ÿ«¨ØI÷uÊ)·Ó$U|Pk}é¯O¿â.è.ßËDíGôîG½ùBÇÉ0L‚å¾¢Óß0mqJÜFKµ»¹†Sõ~g4ƒjªUS£ÑğĞ%¤TFœYnRZìR£Ê€y ®“ştõË%É^¬=¸IäÏÖ+‡­j-–uÀ§#øñØ¦7Nh.£l·TÕùsËb"C}AF½³¥Ò$PªŸ³Í7­×«Jbæ°ºšı=Y¼†iîZtYõÁN]Wíç"crm•í#V®µ$pm1^‚s»»×½Ù©nu‹{”h”ÉÌ€š§¢…anıŒã;[î§¾;6Tô6#µÙvjè!)ÈHAánÿbœ³¸@Ê‹.˜5\Vèú€ì-¬³á¶oŒ';åVÊ¿Î÷¥O‹=FÛ,ÿ.¹è }eôÖhàÏHó84ùd°f*Â’nnºsü~¦Z?¨îÏÜGÑÑ;®“-ÙfC°ˆåÅ5ÒU÷ÒÑ™ Ô>ÃÇvRí8ì‹µIx\ëFÉäf„8ï¢gã4(—¹SõåÎÂé{ˆ¦únÙñ¯á©ïï/Â`§</Ô”NçóˆC©¼.g‰:ŠÕÄÆÊÚ³O¥òš~ih'ï 1Âe·Ó÷»lÔ ÷õé#Sluïñ„¡#2Ä’âfï£Ÿg2öD³(9^½~8Èê%ÚÏ›í)NJr(\å•Ëò¹iW>¨¸»-wJ‰Ã¥Çv–²|ÛøoPl|ÜŒ7hÜ¡£:&'zÓñ*İ6ô`j$Ğ•Ià¾İµ‡*È8ì1¹R’åƒ¡¾Ü9
¥Û0ı±·ûFbçÜÜ‡V6Cê¾Èƒ8úï§`FÒ‡ÆÖ@Ae²[@•½©çŞ×3h·…ÖôğHßˆ2{³Ô¸¯Zºs|c•#OaUu.R€÷ŞÅ¦iæèã¡àNø<§Ljs‚ÖFç“²‚)üˆ29QùDx³¼ãæJ7Í“Ÿ_–rÌ¢l–[ŒÆò0‘Yiw/¡íßû
*ZLÕXÄ‡³†qª[
ÈTæ3F*ñ7…½YË¦
«åA1U<Aìc7Ò>{=Päÿé<£ÅƒF<¶ö¤yD"ªßNı„¯%ºTEº)ÇwU5¢ÈˆVÖ?.&dĞlH5Ú	
v²D_»Š$şæU"ÙæY—¤Xà˜2:ØQWCÅş}7>Ğ£"{şvñ÷²Yâ‡§œNzİùˆËíÚ	c©æyMat=Kl‚y–Ë	¥sııÌF>ïs4î¶ÚÒt›´8,¶y‚”Õşƒ|g®	´o:É“HâvüJ†×át;)Ö}–0;KÚ_(
¢¨×øHÙ,Qô¼m6ÑZ üMsQBW/¡ìÃ„Ñ%ğSÛø}Ë%gKõèåiâë½Î3è¿2n{·QÊ4Ô"jBM(ô a	›RIğäı,º°m7™ò¥<«ç„Ç˜ËšúàË>ôZ¯¦€©"çg3j¾ºlC¹ùå|Çµ/özèßDWÛ´şÁúé?·úï±TylNÒÿ_¯TP¾œNÅÊõœCìÑ¢Y¦
1ïØÅc+PMÃŞédfÈ2X(=
¿æq›ñ<Q–¦• äÀIâ‹Z:Éêó qÚÂA½¦‰‹É_¹¡ºÀáËŞ¿yç:Xõ­¹TÅØ;m¸ Æq}Ébş—6°uõ¡ï‚ UËR8¿’“éÀõ©&¹“AÄ­³|ĞmeíÄSÔ}\X7qÇI!'…O²}P*6{Õ7Årf+<LÄ%9zgXá½ã–ê©÷ö’ä¡(±úĞ'uç‹§÷ m`ÍI6$Z­Îo±ëqú¾‡¬ğDŸOè.xF‘kÂy²øsÍ—ãzÀƒ2Èù©VéÏa.8Ûûf»a²ë³w»Şj•z
EÂ¯ÊÖ£‘ºço ˆ—{Ä­¥RY„õVÒ¶ø!½ÕK ]N;åk˜û¤f>†.A¦>N2À»uów•ÆŠw¬‹ãøC¢wëŒbjX‡C¨±‡æ¿‰„ÍÃ>ÅñG¯EÓÄ(íôöÙ]ÕE×‘9ÀÉ_¡†¬°ŞSÔˆ÷Ö|°ëÄr‹¹WI;yR®!¢ ¿väCäıÅRk½_Åİ(Æq_Ù:Aki-[]óC)”ú—£æÀ¦	¼~;ÅhÄ¼$Ø>á–Ÿ—[Ì9°uë=|ğTlÜ8×cá-Hó²óˆG¡€mxÌ¿œ1™ÿõ‡ó¼cLè³vlë±rÈ¦xÑ)GQËJÙß+iáOìÏç;æ
Ñ0)²BŞíÿ•ËfuX
:Ûu­©9Ñ)ÉrÃ`İå¸îH	Ğ·±ÕQLB~Âğ|?\˜ô>ß~Yz9Jø½Ã¸y”®.+/`¥'%%1ô|6|÷ß²
5”‰ª	1ÓR·d5Ş ì……%4«$4Û£Ìà+1 ?øîaçº©.5û§Á°F49r</ŠGüG°Á„§œR•lYíÍù&íÖ…Z}1=ÙK‘Ù•ª2*¬V:–„cáD}Bu@é•‘ôGÓkÑ’áRıÍŒ’nî& h#(]À:]@âÑRÄş“H!®›*cJà[e£¦cául%¿ß¾ß[aù©º„Ç·ì¯±u3?ØLsË<r±—VôÌT¼ê‚ÉtæxkA±õ¢›×2usY(¦V/:Wî4k»ÛÁ»&ŸÿÉ®˜*A64ü0õİ@íö·™Õ… ø0/‰Ÿb-ŠşMg¯õ“ÎT¹×]¬ğkàX£9V8™sòµÑëlÖÀRN¦v+F’(´W‘ 3øz¼“ˆÇÖd.>·ÁƒÎ‚YOÙŠêö¼œ\vXáä)ğ¤$JC-Ü†+øIHü¿e‹ ™ÑNÍVW7ü´'hXhDuTÙçÕÕ¸©ïYªBˆ›wØ‰ğ«qê÷®+wŒñ$Á®©)Ræ!z¤øÚcµÖÎ\æ¯¥XP©Ì;²¹Àp¤–Ş€5A7„H¸*>¾Jªø²GšM}Ca-<óoS’4v‹ß;tÀ¨€]”‰¬?¤`LO‘†N•¥œToÚae‹­Í§¤–WuAwëQ”8Of/æşŒ8îùş Ëw±Dyı;»Sğô‡ã}7§Ì×Èf¼s=ÚœÃê¾â"æÿ§Hr!Ur¦â‹ß•GÀWyÛÖ‹(è
Ÿ‹lnTçŒ«qš—c¦!òõ¶¸ƒ¸ñœ<oˆLQjç'ÑDïrú½h(Øœw6yäbkÀÑÖÆŒ°%ô2…éS0ŠÅƒ¾¨¨„P·sbn«ôÃöÔ_I{Š)[áù/1sX`¸ê%¾¦å8 FA¦MÔá`©ùoösåo9À£ÊSOá7:·­DIØ|¬uIãéşéß4†î³a§S7Ó8Ø@ÀŒTÊ¤#bA¢‚; IğA\àç÷5‹•³ò¡gåNUîxjÅÑCÆ^a;™g\Ó4w‘ŞKüé€+dÿ*–¼hv®%KÇ€;f§±ßK“cèœÄ%¯)9µ#5Çâîæfk.C©a°âĞÎl=ŸœçõS^ À‡`A÷s×y¡6[R—öø=²Ü<Àb$ÊŸÃñ^Ü‘< 3W=ÇŠåÖóé7a´wÅ.›d›÷Õ¤œÖ’®²õğ{zØ’NÉ7lşJÎ‚rL-|^\o:«$·®T7mÿıt8ÏmÒŸ…â­â–öá+fù°`!06¬z§¤HÄâ4I`H–$là%gxÎÌAÓºÚEX«Kíˆ‡ñôÂßÒ.uœâ½Ì¶\1€å¨`¼f!,õğ\‹k5.Fâ_m‡°ch ÊV{H#’Và|eÔÌeŒ-¿ni§*›‚ùZ[
8>[ËøÁ6t{,©DöŸÙzØÖnì×qO.7j°Ä!gJã#İ÷>À,ÎƒX¥Go@Ö»âWÉ~ZÖ/–ä5¹ïÛ‰dBd‹ùl$(È0*-õ¼îˆØCˆñ6Á4H¿vgP1¶ñ¿ù2 u¥7ø¯$ß'á±®~o\>+ÃS(¥ø¨I}+µe·>7«c>éÂÍ:Û• õOµï%˜Àãx¨R›%rn[‰½%4p<ÖVU®9ÅÕ—EĞñBÙ¦‚Écˆ$³ß¾Ô7}*	HSÑ‘,ÓZšgxÊ"ì˜!-ÿ~c¤O™üBçúö:‡µ¤ş^xVºóö‹ÔStÎ2S;r 5s«+Y„}4'G¥İ‚ôÚ¥r›E\ªëCçº€åØ÷ÉåïD²|¾Ãµæ\îdÃÜë?ÏL¹”))-ñ:>ÿ°Ò*™ rÖ7/½U’L~J;oìX™„Xš{‹ñ±Ê	Oïœ¦»xŠ‚4Ö¢ƒLıqt•òm%í€´]£qò‚„”*{»VT;r0	ËÇr)÷Ö‘Ö~Ù…éfÍj×_|@æ‰÷XĞÖ	-¿«4	LÅĞ3‡7_Aş`—k®z˜‰×Ä©o<³¨;[¡>u¸¹v2RpL î¸s”şPñó®r¿Š·/|¯ræiñ0[dx‘"•+^5¦eº¦½¸UĞŒ@Ò«[E(*TÅ.'ç+UÙ„¥½é‹=¦[Ç¤ÔAxQÖvÂZJ?œl–¡ûš93ÈÂ¢à¯/lqüÍBİ¯ğ;ícÊ3¼ù©âRB)Ó¸Ú–—•m}|_ÍBö78Â1vÎ4Ç—ãš7Cg×`O²gs9“:êÍˆ¢É§éß¢›êWªèøK6õÍ"™ê´XaÈ1ySª»Sñ]Ÿv9ë¸ ğİÜ­üAü®nTØúÕM¹3şKÓô©K×c«„FÜ|–4@VáËOo8–­ÛA¶ëâ‰×3ßDZÀ0
®5$ê®DÏÜüÕ_Os¿¿P5UÌ0MÂ2†?bœçÿ©".ß›8|ï¶&:À,’°L-N#“$º×ŞPWrQ„S6¨„Ÿa­¹O8Á‰)ög<Ãşw»rNy¯a«¿ß¤£ÔÀ=©Ç>ï[OyhnâkĞo!$Ç`0é¤Z„S/œûœ)ï¼*znÒñ©»«W—£§l8äbµØ=ú±İ(²À¥ßMsjfu×ì[I‘‚Ì¶-LİÑ¤tP‡rú‡bã»6k&›wi:’ü±qXò…ŒÊÎğ¼›…l£9ÖÂøİDÖ¥âËŠJ» ™.í Ñ/¦øÚ°aìè*ôüœ–/ÅÓØ ¾.†è‚Ó˜à¢öQ³Šäñ
Q,u¬Í×µeµğ¦
­P½-æ~Ï*«8UÚÓñÿ|&2Åë¾«@<Z˜åFm¹æĞ‚~dJäi“¡ İiãQ€wİc¤,ïı]ÜĞè+¥§ú‹öÛ’®Á…™£bD;·ñ»A˜úùİ”›ıã'n‚c›e, ¹€Ôñs+%ÚÉnÃU¡S¯™ve4ø£efD/ÅäòmLe<Sš´LHà²Òv†Rzk\Uğs=•ëIE!áëdWœifmå¥6ĞM­:øôøêÌjùÆëYÄ1íÁO¢Ş³	á³T3ƒïÅ6·*Æ&pE²ıôBT-¹š;—’µø•2
®˜m’{—ÎÓ&šhÕê­)([ÕÑï
Œ7ùºğ»Î€o¸cômÎ*?— Å íÁCWk°É ~záèİñ¤y¹ó–ˆılAØX6Å„e§ìÇıºˆ”»>!ùNLi&Lã´ef¾ ¡ÀÜ‘4â£=(.ä œuéß—=à  C¼h…8…{‡ ×€ Ò~û±Ägû    YZ