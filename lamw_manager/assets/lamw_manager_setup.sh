#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2566641643"
MD5="a3029bbedb02b20ac5d73f27ede0c206"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23576"
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
	echo Date of packaging: Thu Sep 30 21:24:05 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[Ø] ¼}•À1Dd]‡Á›PætİDõ|‹Í!’J(Üš€ÉJìÕ½Aêª|SD¤dBhÒËNO€¤£gLiø"»wÏz˜ÖÆ	÷c¬7¡ŒlÖ~lxçYûA-¤†¯-áWú¬8xg×ÿj8¬ßÃE–NÌ©…¯G„¬€Á¶&İ?üeæ7åşêE•Z6'éÙâ+µ¹á/UUÍ>u÷O(ILà³ÃN‹É]W«‚¯yµxiÓ	³Ø¯Ù
OA>=“‘¾ºõ¨Ï£2“t\
ˆÎaqr‚9´³*Ék8õ½Ä£(;Q3–=(@€¬š’]w`?hÕóÓÁ6ß7 g üÕ#Y™«a#ö¸ƒíÊBW£å& ~TÇõ‡cj1
Pÿˆ„¾¿Ã©Ñ±ùÊ7_wY›ÿoœè$|Õ„ê¸ß9…m‹Ívíö[îo'Va’‡½|v¹¡Râ hH^Å%‡–$ğ)æ§ƒ!?½aC¥|²`§›?¼NnQ‹z‡‚€Pµo„~h²€Ç41¡’¨Œ¹ÁvÎÓ¾ÆRql»«f³MlÙ2Ç¤éç-Và|ûÜÊGáCğD²‚P_´åøo8œ.{¨U†¹Åï2SX!Ê@UùŠOèQaI2òkCõÓß…°Ùé~q¦!õ6‘|±Ö˜zH†Œ*Æ&Şá@s­IŞ¿&– Å„a—ˆ3âÚÛ@W†j(Y±ÛÏp}›Ê¢Û†ëÉ6p‡øçzÁ­K‚Õ¼ÒucuÓ»3KbˆenF‘"6h[‹•„ c’ø¶î§rîÙùì7&˜tñğÁ+§AøŸ:ò¼V^…Ëèóœ—©—Ó«ZÛh$±)^Èü"=ËÕ5¯ ön6ÓéªëÈ	Âè9åôÊòm<Ğå™&-ZJÆÆD6²Ëç±½±;şûÖM_êÃ—‹²óÇ»Öši&kÖ­"Áó•&bØß İ#'¼1ÄK‘T¢ŠŸD*…ôÑOh%SJü ğe‚°ü`²À”EYÿª^ŒÍ»“õöyü‘nòå_š’ìÓ¡-¹EöQ÷»lÔ®pôA$L#ÉşâMÊôÀ{õb!ZØ”ñ-bm9“_Q$Àz,ln‡ß/"]’ˆz¯(PS”Vm¿sä×àùq ÑE¶óagÌ‚ü\äÆA¹ÿÿİŠÀÉb·™WH¥d™'DÕmÆ½ïÖÈ¤`•ĞÎ#BêxÛ¶CC.R`4s5:!ÚúßA†ƒ~ÑJ”R9­óZË–Ìµ9âêl½4âäFyG¤Â<j9.€®İ91tËzMğÜá®;œÒÍûéÑsBŒtˆç÷S´¶Ôª?/ ½×¨vŸ‰`ëÒ|UZ$éï@x—Z¯$0‚ŠkÛJÌğ¡5hˆÑ¦Ä2$Ë,YÎ+ø§wd˜ş/Ç¹¾)§.{Sg²dş)ÌQ{¯Ó½Ë€
æ˜[/:cwàŒ£Ì9ç™&Iî··›òj´=CékÍN7ÀK)uûg%}“²| !ïd­ìã1ÒL«’ĞeÌ~xİr ÒIJŸ>5sPß~ŞÙ1ö™ùnÂQyk‘Š=d,$W§Îá{AÖokyãP´rúƒ	f•v“Îg&çÖNFTé¯‚œäÍB<D2<Oz’œYW
1… VIdÇè^y†„
Î1ËŸßÂa{ñÙ·0HÇ#Nàb+,L´$üáLl¬<³T×{Á)æœ;KS÷hd{b¬E&}‡¡Ì±êĞ‰&ê[2¾Ò\	İ¸÷€ ¤Ò@ÌÒÉÔ‰7xÍ©ĞTè¤7kH@¯¦×ÇÅtaÁúN‘i†oİ·öînÂu&1‹T™ï±Û(kW¥Ò]ßÂm$©8Wcœùk$‰¥È›…'yH ã3Ö¯)§gÎVk§ğ›«®	
şépØÃ<Ã¥HÚRéÄÎÑĞ­°- ó.‡Uíç-òë¼”\|3ùpaÀ4²Ä¾ÖÒ ÄôÍzæ¡Î dbŒ<Ë^]Ôi¨!åXe4Í¾—$0e‚ˆŒŸ¸‹Šmª@;F™©£^Ş;Ù·WÖC¼5?uJo!¼hË€¯eˆÄÌÇ°C§ÍV§/–‹®¸i0 Ü)Ğ8™wÌëø®²îËÕW²UuŒ'–XîAßDÆ)Õ'ÑÖèOc;6#úaâÎÜ{h³Iƒ‹¯İÛ´''"ëOnsÇ×­’İM¼ä‘8v¤Ş(¸k6…áK-Âş!ÉÀê©ò†³ËC†ğrvtÔîèz¶¥à”'Æağù²~ä1œúÒÖ[èœÛ=Îº¶(pîÿlóº—}åU*‡íå¶¬k{! û/1áBUŠçúÇ&‹–\É©L©·Û·¦;£Ò'×m1 ªÇ”¹H6º";%‘Ñ†jôU¾' ­×ÉK« ê›`%V_şS«VQ§Ü±6@©PˆÕ”:P¾Ç!ì¸‹Xºòô·äo†{È#ÓSéÊhibø¬ŞZxG)PcëSúy÷X4519HHÖO˜ä˜2äæ5ËÑaæ½÷?[ _+ËÈ´ä>ÉÀ^p}Ë~¡ÎŞ´SÄbñİ˜ê….ÕÇãZæe¯ l#ëPğ&v¿Ú!teiŒ_¹Wˆ †à5ÙÜùP™„Û‘Ô¢Fs„CÊgz6×h¢¸WêLÊlK•£h	?7Ç–twÂÄx{ì12:e´LÛ»MlğS‰#Œ¨ßN\d ó—‰à´Vô%?ÜPÅúş˜´/¹;9“ñ¨I^½©æ¬^]F#å½öÌ›˜wNÌäLAmô(Ù¡pUIñ2µ~]•ŒàÚÑŠ6/âF‰m_‡ãú„Gş8á„¯óXÉxv@$j›.@ŠÌº.Ö Q_,O¦gÖ+sÊÜB)ÄT¢özÓw4À¯Ï+ÛÆBRl¾°7Ô¦|›8*½1œÕÄøS„u^¨B˜SKÄ-MÛNB(ói4J¯&]F±ê$ë‰é{í^îV›¤DâŒr÷äÌ~ jO*«¢ß·åäTÀ/·Ns,M«¤J¨"o2Fv74‹å«Ñ>nƒƒÈzÆHzã Ó¶^4[ı£B]¬/,—<]!%´,AıB]@c<Cìú4Â;ÜRê}P£Ø˜†ô€W…ŠC4ò™b»à±—CBÔš‡I<üWQæ‹½µşaŸö„WÄğÉ	›´ÉVSC {<Œıƒ„&xEl-àÌPøÖıA/¿Îhşÿd¤«1NvÖ«#Aóh³¶ÖÏt÷¹,g?õğ^Îã8d„:?7`IÃ3æBuíÏÇ»à<—H”†Û—YWl»¯£¤İAı_X±gÌıŠeß„y$’4êÍT œİ^D²ˆ	Sk‰Ò„ŸbÆ{İÔ{NW‡WÑ£9LÕcë£Rv7e'v;işy¬s6je=_GQXÃ­*cO—Y¬á‡x†éü£Çj>Í?W)}€Øå÷%nªË¦-è‹r©é)âò34*ôS;sq~öª¢¡kŞåt<•Œ„ovSñ‡‘ÿ£mÃÏZ€ “ñ{)Qm@–¦©tiÌ¥Åœ^ÚwEË£Ù¹ÄÚ··şĞ³’S ı¨¾i¸˜)
LT„®$ÂÓò|±dw¨»=÷ö
Jm|F<DL>}7Ñøqx=Ó/à÷a®™ÂíªŞoŒaønà¡a7?¹Ê4ûh\ ®³jHnd=²ã€Âä:m„®]OÕê-Ó¬¿O÷Öunÿo2—ïÀu¾go‚òP0^ÿıÛˆÔšÒ¯bWğşà2à+“ğ]Šî9BÛ7|‡H´@ß13iYCÎ¦*¹6ÂÏØîÎ•—.PåIÃJš¡¾.Ûº™‰çÍe
¥…z÷‡N¡@Ÿjié·xA¨Ò”P&|ª‚
ÎºÑŞå€­@‚6î .ÜÂàeo“éïŸã$²?î	ÜT†}ÆIl×%ŞlçxŠû— “"^ZÂ,)^€° ¬ˆ¼8Õ'¡>dù>@èÀJ7Ö rì²{Ø”'‘oÒã¹”ßÆdú»>ô}8=¹ ï]ª¾•q#r}[Vï©u :²4˜¶	§”‹Ñª¾N­ú¶EVŸ³,E²y
—ÿû0Éì—ó6uáÄ-)üÁºÿdOÃd½S“WĞ-Ü8Nÿg×¯/[W^ƒ„=—6‹İ¦*Ê€éQaíåa,ÖÙ¨ì‚“¶‹ï³oª„eË_—ùL0	röíÏÛlDãË|àtæ$¦wtòš²2rì'vòjğ¥ÄŠÜƒòì»W¸=n¢B3ĞÓ<˜ïÓÈ3sšß ûÔÊê¥·Ä­6mmHóè´3’ÀÚë­À[ZËÓ…‘,÷¤ƒfWÏsaëì‚Ê”ğeøŞaæŞjŸ,Ûéê!Òû}xŒM…€;U£:ôÕ1Z;[ÎÎëètş‹¶Ë[cl¶Qe0™Ö­µG¥Ut×ÿ!é?Ö:Œ<xñÈXwpnu¥ÇÀ¯€^å–Ñ½p\p.î—ãKÀ–s«¼Ğ¶]tÏí_xAsh-¤yã¤œÎÂ±–˜¯BpâÔ½¥–‹Ãİv‡dt†{”Lã–mf[Ü‚(Nâ²”Ïg7ŒÇ·_7ß&ÖVw•H5Éü7BMêÄC]¢i§C1oŒÕzëÖ~øÙÖf¬ Í™ìX;Ív¼¨Z)DEiüØÙ¼D+)Ğ¡àz&;ŞÃ$Í#ºŸªkéÊøÂ±œ†Ø;–Çj›ñvhÔ³¸zîôfSöêÿ$Öö®;œqİˆ¡ì
çÀ {–€æ­¦ôœÂ#ŸN:¡©áp4£Ô^¿/‹îNûÕÎìla\.6–î^WYì& vnqÁd¨}*Spú´òò°Z„D}¡·K¸Ó£†ô‘µ^R'çov›Â_'Ë Ù¥ˆÜíÔ× .PÖÌ­øNµ²çIÇRèğ•(·wfsv†İßhYJ,_)gğQ•â¿õ£pìñNY3¾\9!^ñµªoLÛóv5’SkOi!=ÚÔøW-&’Úšè“—hYf%( ÊşÔL
uêåã©OyßÜSÛVoü—L™¸’ÅlßŠ&(GĞ°}êp/È½}>¿÷âgŠ:c gàiİ*ªv©okO¤0.Óå¹@(ÃÌÜF‹½&î÷2÷1b‡UáhÙ¿Ïçì^ûV)“`9êT@lø–É«³l¶µMˆCu4¥§Y3Tÿ¦ª¼i³•g*77¶¨ß‰¹ô÷×Æ	å7æ1nÑÄ‘_Iïº» Ÿóá˜×G!SÁ›èáy7®#ëºp¾aØ+û¨vôı5çÒe2×¥#QG¢ˆ$Ìİ#}Ì â5û[iÄÒ›#¤Äa2UµûbêÅ²^àã;CT×N8z»<›ÔVØ½½'™-$.m„Já@Øšé\¬harıíˆ7*JğwBä;^”’>ù qˆİ«9+²¹ÈöI)î‰èß¿¶Tä¢<ú¤ÍÄ›Ì‹™à¦jBëì—c”Õo&”ˆ»¥È–HÉMv•—±UİÚÊïC[¹ª)qqı2l›fñşwô[>€bS‹#ÏÛ4ÊßÖÀó?ò3ÚÚt¯†UŞâóh2TÆ9ŸIµõ–º+
iŞÕFOê ôJ	[7>§4\V@—ù-1O ÒX6ªtC6ÀeªnÃ]˜bñıI»¹bÉ‹ƒóõÍË4SøIHãàı…]ó(\ ívï»ĞC)³+[Py¤÷İ­ID*[Û)ıT I6È _	­62„ÜÂ‘E¬üøfï
::—Ìñšş=µMå¤M•ªõÂ°gß­Õã5wá?¶é­ <Eæ’Nîk4MUuŸ³$²›H´9ÍR«w·Ù²r/Rô7@6TåÄôE/êb\·pí½ì·­W-BPh³šµ	`Ü‡÷¬W±ßÊÎE0fÖ[C¸RfF¢mM,^ÂåØÑÉŒYèİXñ­{Ûn¶rU	!…UPk‰¦Å/ïñ†üé…±WD²5AŸ6¼2Ìì~l†a±9ºäû.¯M_×Ø9üÛÈ¹Mï…®>6åt¡‰–bV*FKik|×ÁAİÉûÑÂ»jpğ5ûZŞø-½ıVv‘;P71NË_—‹R¿=Tõò@ëˆDã,dôV;Ô1<ÜU.ÍŒSñÌ¾>­‡s ”¯Hœ€ÀØN(‘Nhó´HîJ9Ş¸=ñœ>}œC×—Ì‰WFÙå¯YqäÎÖşÂŞ–J#²!^ZŠx•]øiE4ìŸ+°•&ôãiõ %CÆµ ü« ÓD[Ìl‡¬¾:p•*QØ­8 
NwãÇvRyâ x¢´ëÂd:ÂÉÖÖ‡©¹H°oæÛ6Ráû}ØóZº½²äTŒD5¬ô„Ñ¨» ¸¿fû{Uëxû½Î}Ñ1+Qì«)ß•¾(á8s!Ä\è‡‰¹}ì—}ÓG^m‘TÎ‘B7fDj¿5s	_6Ï«\¯hêò›’Ù•¶ñŸ#skˆ ß´H×ã4…p„)éhİ–‘ÀÛA¬[yA‹GEëå“—úÀe]¢°Ï‰ı²°‘ÌUÖ|™5ù,™FîcLñô²kİˆYCMÙşé¯ôF‡ò~Ñ$í¨€½à³Xêõ2ÎaìÈH°$Ù İ£%©Ww%ê¡R],¿>?è
b;û×éuZÕØzp‰sR‚‹[IÉ‰’7ÈVÊŒBş>È_«´uíØcá§ò=Æ(6¤ò¬OA1wÜ°}AƒÛ‚½H±Q—Zş‘Ò•íÉÄvzLWÛ7}¡é
 §ë
«ÚJÁÿ-Üé`¸e9"íËoş—ïúÆ‡•P¸J„Ÿi˜sx'Ü~®Rããq'ŠpTLlÃƒØßù£«'¾ì‘šFk!ï0Çˆ*Wíj}¬;wl=Xé¯ìwé®1AOÍ½C©š¤‘ĞDØ~Ôgƒ’”¥èn]ø¥<å3&YÃg0ƒJÎ3Êµ½şôT¯û…p.Y›q°¼îõfPbü\:%.³S8L€6K£vşM2<ºY©Æ•®ğ-[.3€Å¿k¢Hê}uü„/Zvšáj¿õvğVŸ#AàäñH0ÓŸ£¡mzí•ŠêVcG¾˜=4
Î§j¿İ”¥RõØÿŒ7vgZ¥JzLæÈüG¬vé'ú”Ÿ†6~Íœ²ëİe@’B@P@•ÑFÙ'õë0h	Ç-iŠ¤0=#h~s½“víáÑ©¿~!Á¬X–g_€ºªBEfÜˆxáq1B%ŸJïµ?bD~¹ä;U3¿—BS]ï†ŸFv2s)y¨ˆİ«”yg?`H8½Âs¨ïœ–?â{æsyL@…¯G8¬_EjÆ†DÆï#FT±|FµÜeêúr¦İˆËRğE_LiÅ'Á\êM”~ÈXUÇû^·Ò´ÄßCô²­0£"æãVu	*Âæà[~dV+`*vÚvõ‡LŒê¾bšÛ÷ şa(rŠš†©7¢œKVıïÛÃÊUvi«Şñ>VJIiŞT§õ%€),G‡SøVxæÇ<¶#Ñ³§£”¥âŞ¿Ñ‘hâ+ƒ"(DDÍâ6~¥|héÚ:cÀ+DÖ„oºm+]Y4eì›$ö …Ğ'h¥à­°ØÛÔ‘#b%Ì+¯Û`˜ìÌ­—XtwÊc÷ô–Ø•Ãé´÷@‹™Á@}ĞcÑX
RT]P0;%ıswxìg]‡æıd)7Ï¨ÛŠ%:T,ƒÃp\q›`2Ş€=«¤K¶!”§›v[²è^C>Ã…PRNµ ¬—!çÅUòÄhüû—ê—IDĞkÃ Làê&,w°Xò;%}dÖ®5#µA§Éé˜ÏT‰'Vîñ)—#b×Ö|zúzä%:ÄÒÌõNôX»Èğ=œÒ5I*5FEø÷;üe©ƒ@!?Ît0.s4à%+åw:LJáØ`®ÇğTY!Púà2Å#%jÄhôğî–kËÈ–Æ”4Ù×àÄ?;TzãPYï‚†éFÀúÍC HV
&a@î_v­(¤=bI\DÒíÃF	Y $ ª€çÓqìåè›Ëõõ5|¢X¿A^bâcÜò5ôx%¼nË_ åèH»*‡V˜,Õr$Â·W÷İ#-•‡ÈöÈç¨ÌïaÙôxIÂµoh¸3Åÿ„ZGÓ„©ŒxÃÎJn¥µ)÷yÑ–Ï(e%Zaá'£u^bŠ²…GQ©ÅbE:íêœô~…]€EEûz ²v´P¾ğş"9¡Ñ×yD¾oç{Nã«1|²ûoJ„ 
şjSàE³Ga6CpLúÎ:®@ˆn,ëşW¡ÊÍ&sI—Û—\»X¾Õ¸ÂWÊ.&Ü·kÆ§ç¥”…d<xi„!ş‹ôÁ>ûâ¥HpLszìòPÂ?	ˆ‰ùg-ya¬f@@àY*º^{c—¯Ôiÿa^._k~Ã7Ò{PİAU?ó.L‹¤>Ø6œ=)¡ï½—®Ñ×ÂWÂH‹f¾µC7¥ò|‰u?Bsn)[[?~fßıà İETêüG§÷‡A'b¥¿ˆ€å¾0lÔ„’Ã¿²ëŸ7^Ò¿à­Üƒâßª¬­ ”Æôö;øi&9TvòçÍ Qò„Sé¤I0;@ÂÈ(”KS? +Íÿ€îñt^¡; ~%i~
Úé‘Ÿ©ú²ÓòBŞ¼<ÁÌ.Aˆp¬ µçÚo±Ç«{%ïÎ|)²1à	›Í‰:.H7[za“"ÛsÄ´îµ +Ê@nîª¤^İ»í³r®M,i ·„YWşKŞáçóW½1èuíÉÀH,E¯‘ìß]ãß{TWyã°|§£(( ¹²;ĞÕªìÆGé.••Zş cñØRXL6“$œOpß˜¡Æ[ŠÖÍ~fËi=KÄ¥Åg}†f~ªÙnBóÁ^Y?¬¿ı;ÒiÉD(EIé±ò·…¤Î"b'@ŒGı‡öÛÏ9†R©‡ÍPm±ôJ¯Å[¢÷°R,[¬X:·Ì…#ÕNºcËYÔW§&†l}o±»ÑŒaîÙ=wÓ/Mú‚y…\°¬/%ùÀ#®»ÕCNâàìG÷%gˆü 3§£d}ä±Aœn,¿ Bæ_h†K`õ\SÒvMÃv-¥|/ı–w@o‹¾·Õ¦âóIt±,7:Š±=åMÿvzgDËOº¡‚)ÙÚ&`ïKåşFU^™jÚ(ˆK_Å~Xf&¨	‘éíò›,‚ñÇÑ0xí1ı"±ÆÒS¡+.9ä4Æø(è”É¥ÔšÕÃÏYÒ"Ì‹;]F›Ò>‹Ö÷5	ÓSFè ÈÛäMHjf•´NÁ÷õ\ËòXäcÑ&Wš#*‰XÃ Ë“§$óËÚ3ĞmïüĞ@Ê>jYù%‘M±	‚òÅXØ y;dŠQB]Á¦â_Âü½8A€`o.£ã;r»S „ó[×¿Ëû·‹•‹v ™PÂŒØ´Ôùp-“Ÿ*+èÊö.î›'pE6"Üi;”:5O¬îÔWÌé¥:¤í¤ì‘‚ÅM2vâ±l¸Áê…9VÊ¯›?ªëæ?:‚an¤¨Ô¡—)¾„Œ‘RbŞšÀ²)ïS­İŒù«ø§÷†=8Ì+Ék”WO	AáÿVP´\Şêª±•LãÔ	v‚¹æmcÄ=I‹1Ç–på6¯~¸¸‚„RşË0% ø39ß“İüA¿5Ãô=h}÷«¯23Y³óœRúõffb} –fœ×ÄvBÁü¹IÂV–ïEÔ—çğ#]fÉ/baàÿì«1¿¦Æq-‚œ#_ˆ¶òF¨Ô÷Ãj©2îy`%÷éŒ¥N¦@;’FïC„æèd1ÎüÑ9¾ƒé¾²“|j÷ÛÄşy¢\’øçJƒ@è’b‰‰¹©å\*¶`ğ§‹k JmYÇç~g”qÛ{Ü=…v…æ2ÅoEŒõi?¨)ß‹":ÆŞâ.àQöúÈ¢ZòvOèP*Èà¸Šü«õ|€øûVÏS^$=Øş‹„<QÊM˜WlÔSûö {l‚“’²YÁ•ÙùAÜÓà³¤B.Ø¶·°sy5éŸ}5s4æ§;ÏÃiyŞ6U×Û_^§3šæÑÄÆ!cİiı›Yõq€E`#3>p´é“Äc¢c¿¬©šKYmëR„”ë®¸M©‰zÿÉ4+ÏğJãSÑ¿D¯ÉxÕ³'¥Æ¦¿g¢µçåOä«Ü_> K3¯%;()s‡/Ùñ+Å³‚î(wvèE<e&ô§j^“k·„×¨ÍQ~êmêÏ˜x¹'^¦j)×vù}t
ëq­!‡å¼Zì#”{%-Jt7Us ‡D÷2¶DZ´z,q ›%l2_µfV“vXÑ‘¹‚\šÓıœnĞ^+1ÀŞ°{ÂøE¬GYxËÇÖtvÚ¾W9Ìü@rÊ„µòv	äÈ1h”K‘\&{°.lÕ„¯?H;ß²©Šô êûY;)©¹¦qV%7ô^¯L$²såa“•¶›Ñãi…˜ƒŞ‡İ×™MëÏ¼-‘Šı;?E-Ä°©zØç´UşcØä2°«K}V"Edßˆçš,ÎbíaÙÀÖ¸‹ÉÛrÑ‹G5ßÑ	}'>û„ö=8=/®½Î?E.6û!Ÿ0 E9$˜?-Zf²r ä¬Éz»k•ö<Ÿ°½Ìs°Ü•&ˆUÙÒÚ&H¬ö¶eµ×æ­Áè} •Ö<t>l0ÒÊ/^@#¼si~Ès:®Î1šrXN_^Æô:)lşÃ­¾5÷úk<”Z‡p]Oh:úÊ±Y†„¡¶ord`4Â’ÖÚÁ,¸4Â±J×µ¢J´î¤šó/{ãk¿bHµÉ…
‡(¤t¦f²aô*ŞZîvƒÙ¡´6l*J=CÕsíJŸùy€]{ï­»Õ·Ê«·1…5…NÍü±½~n_uœ3TŞß—ö4Üˆwp#à¦upÜoôêºC›ï
8ÿ»É¨Ù¤ º=^ ¯«Ù˜m3æAò…U…ˆ§®]ÀÂoæÆF¾‚VøVYÙF¢˜§úr5}liİ¦¤3:¥ãÃ¾]ÚÖ[Ò3&<	G'@™ZÌ„l´ĞDT0ô“$×­JÂ{
*‡bco­;Öö=›+Htñ—ƒ9æ”ÀÀiµ‚×épÕı$üÆ5+ø‡œ©sD‹·±,Ø¼ÃÜmXµX4ÚÌŸíöOQş0Nºi1¿p¬\iCöDDêñæ#+Jt;’p{æGbÁ>÷v€}3=ËQdæôfĞJ›½j8Æ@ü+õ$4è’áIÜb³ˆz{b©øV<Õ’’¦+X`}‚ÔüYûg0ù°R
’ÅæÈéÀËú÷plÛ?-e<rö‹T\YHş‹(…ƒq—?³2±à}?v!Êmƒ“b‚¼N"FÂïòÿˆ
ò6†Fœç¶æÙÍ‘ºs×åÉö²õ²¼:óS¦ü<ˆ½¾9zÈéÁ,›„%j‰¤Ot¦ïx txáwwtõªbTS´›3>èOîaˆı/­ÂHÃReÅÉÿ C3r1GšU òÿü§â¸›c<÷µÉ^Ä&İ''…ûK‘ş[W962SUÙ³u ?8ÉpñàĞ6æ˜0hS
KU=0±Õ±dÛyE¹Ó÷é9éÂ¯ıÔXº²´…³¸…²L‘ìDB)G»[ãm5»öÓqÓ„…Á%{(s„‹€’].ÖIĞAOÃäYÈ`İyşÙĞt/÷–xIE!aÕ]øgcåRšeŸ­¦ğæ¡T4"HæfÌĞ¯ƒ°Ö×Ä qÃË92Ê§(„'=‡ôÊ‹ë—6xõC­tgi»qîıòµ¡éaVlH…dOßZî•×²« ŒŸ´ÖƒÖÍ<†é‰Ş4õÌşD” ÒMÇ`à«sX¢âG­¼Ï÷®íb]y‹õ<aKÑmR´p£ƒÒıÍjà”û’½O%Ş¡Œ),®h:Óğkñ¯õ®'w‰<y-Š3¡Ôûu¡Âƒ#òôs’ÎldÊ}ª¥¬Éc}g“Ñ—9œ««:J™ß:
ë›pÂVçj`ÓSœû ”(P	8ºšû9š>lO—LTÓĞ]Äµd¤‡ ÖÍ´¦Û:kjqô¹—h"’|ãÕº¸¾¤àW+°n1~Œğö 3‚ëŞÚn¦uMÀÖ5£J©®şÂµèH|º~'h…iÃG¶i’,ÌZÏ‹d•˜Lø‰EL›;ş‚FDïN&ÓKLÍÅ¼EUÑšQ‡ü_Á*‡™ ^jÍ»«11·@íº+C«î£Î£­öÁOÒUì¡<ä|(3\‚SO·º¥l†OïUl¿ß~bkSqî5DÊİ«ˆÚ´ånC&=C\¶ÌüÓ·…ÿšBÇGàS¤ªĞJköİiÁpÛŠ’,€™«uÉÌ‰R  ûÎQ8?l"(a†¥Á;ÿë0Wyt~sÊ[,Ú‚h[†FŒÍ@p’é}b/õ$–P»~€I²Ø·Ù… s§á;x‰È¢¥záëY~¡ÕñÃ±­~§b&íË×• °…8¿¢”nÜÃqŸ›I–€!SS'ˆ¬›+ûÒïH´â:Ö	
Ïp<}~Ÿü—-OüåeèŞ³J(hu²Cy+jX*ª“º*ŠX›s/áG}O}´â8Å’¹òQ.Ş?ä5c6³®¤<?,SC?".é.cÊßº`â3öO…¹ìş$ÃR¥“ÿ¾Wo{Â¿dL¤r•›m/h>#K©Kw6i­%PX6İæ“f8,Ğ£:¶´•Ã3¯ÆD@')/ù(É•kÃx‰\áÒÀë,÷¯äª1-—1YY‡T#‘ÙÑÊMaÆAB‚tL”7é¤´l-â‡H0ô‚ıši‹ÿhö¡>fêw:ƒo›õ5B}ª³#MÍO®¯gj®5nHîÛ—Ä¾xçJ¤[îH­ƒ¢&³3nø]s°oÈ©Öc?hÿ+¤—"¥ıKÏee÷’(†Ñä"‹ƒUÆ_IKW½å—ƒ)Ïp[b<Vl‡T®7>^,QU8#ç¿M§‘—n”…sxÂÒ\ÜRMŞl¼F*Jï4ô¹À/Ú’‡Â™{@Ò¼‹x¹ûë=‚S\Fï:ö€WL_?„ŞtóSÅ³Ä„äUDŠ[Êà®Ø?SN¯}õâ|Œ¹/w
<_ó«bå+|–ŸÃ¯Lå~3‚cÑ–
gsLÔ¶ãÛĞÛ•%™G,‡»õÒgóØĞ¬ğ]"—ËÀ‡(w™È–Pâk­Ï™ĞÔíuL^r/ ?cOZT;…\RNDÏóB2ª6‡®”è0)q=ëÓa¢Gy¯0›îÀşŒ–Xnı€M]«…Šş–á‰;uXj±LiÜgÊòİ²k„ùzüzÚ®*ñê7*·“ü DäÙ1`ƒ9²ÑÁ®Èú_
d6?¤I§÷\E"şùpPljvÏæ…/Ä©¿.ÚÍY(±æbpÒ½²€{­lC9ûµÔ;²§E{]X{´'¹FNËŸÅúxHÆn²U½å4¼Œ—¦^¼­ÙŸãÑ4)ÀjäëoÒÌoĞˆŸ¨ÓÓŠ7Ëv(i1jîÀØ}Tî†Jª‘¶åbÛ `_Ài|'È‘Ş:|UZóŸÃ 1Ñ8^Wªê…y,Ò+ÿ˜KMæãÜqÎüøÌAs¢ÍB$í­ZÎL =ß¦Hú59ÿÍá£qj}2â>ëE+[şñv‡§¶ŠüÔ±¤µ…µ,Ò[7’¥º#·Ú²W¨%~I§G¸?¥E¸ßäÁöğ wY5R‰Ä ã{WuÙéö!‘gg%ÆEÄŠwX	"ã×Îz	ÅÕÅ•™  
ÔÚÉß &à¼¦æà¼×~¿iH€?!>o&ätÍÆÊü$ÄdåY¥é2Q&à;8èWÎ ¨=Ò´U‚äŠ ®èå°ó]“¼'_r'Ã®ºê5äN†¨û 'Râ‘äãñô[ü9!p°N[àí4›Ó¦/ÏÒŞl&ò«½8EkqQëräØ$XKE\%½ßnÙg©oAqòØ¢ÎT¡c(ëfñyè#='61Ûöi)¡øL=@×—[åY7-ú§’¨¥¦A‰¢’}Wı?Y¾ş™Ó÷ÔãV£æ±óö¯‹&¸õŞ»¢o6GÕvì,s«nµİ¡íkzëšEöi†-Ìt^GbXm!‡è—§-›.ùÔ—Gf4éaØG®LT:;_$›:jôã"I2–vê.ã´2×àÒò^ÙÊpJüãU*¦"ç6¦ï½D%¸G-hŠ‘0±}ö¢eì²ù¬/0C¼ül­şpÆ>ö ò|•X¡^˜Ô®aİˆËNã‰ Dfú¡_q)MİŸZÎˆí)fQı=àéY‚½pxÜÈ#í:†U<Ğ\f»ª
ş£ŸOó¯à?ÚZÒáÇ±m¸÷ÿŸ„Õ''ƒ.ôÃÄÄ»‹"£†$g?ç·‚Ã4$¿,†[-'/%gîıÀ›x\ühûß•
úëìqúÉjZOïB…uÀN€0ë@½ÿ6„™¦wx?æÅ®£	¡	Ï9¡ÒØFşÙ"ºIp¤^2í1§¦À,ß˜]–U·ÍpPÖ³¨ªbÀÑ:h[Ú›^A­õ{§~3vÕnG™x~Ì‰Ö	I<Eg¦ÕÓÙìB>Ç:v"Òe›\O)v#?Vˆ¸wÙÍ!‘(™*}ÕÅú“ƒ°B\wÍ›¿ÀZßŞ=ãÉ/>3-9®W¿$.~|bg5F‚û±l’R×ßåéNfRcÂƒ.ë3ÃQ¶ŞõÅÆ$Zkù–0sdpH!=ü46ğZÑôã)³Ğ”O¯Ó™Ï›œõÁe{¬XCå’¼ÓÕé%<‘ï†ìd11æ8Ñ’ÛÍ°I‚wûáëô ›ïÀ¶çøûVkÍ‡?ödô9²1Ù‡ØIáÜjÛ³tRO¤øÒ*ı
TS—¬iq6.8tYOE¨×•ø¶ZŒ¸!Õİá<ù0nŒFq<ÙĞğ»2¾·E(=\;ƒêİõ1DEÌõ¢yş¸¯ø(ŞïMĞrKî@R/åìsóvJ±.†­!YÌãà”²pÍ-6%º" ûAqƒÊ74Z°úŒŞËä½Du*v ÅˆÀ˜ƒ—§FN¬î¯Ô´KùÖS5©Ôr;Ôêì7ìè^/6Ì’Ù†Ó¼R*ÛÍ‹³ÿø¡Rí­­·/z½»k«âoqH¹ˆ%aMÅˆy:¨ÏşÕB’ádËYUÖ¶zÔ5„Ø/õš{ÔS$ô™m pşÑ ®&¨‡ºøº*†‘ã÷ç¾•%sleæ¤ôK–”÷èÌ‡Ë¶‚<Ä¢ê^	&"1*	aÊ!™;/ ôšyèè<vÅ@…ë·YVf±˜<1×)oòD,Ûn*úôKzÀÓWä r{Â&v¸í2ó-Z{1"._çG-ÒgOõB–ÉÂr‹Ğ RÕüÕ8`PZüXºOv?ì†8‘fs“±:üMùè¿óV´³p27ö.4Æzó(L˜…¿Ä$aõ­5èõ{©å­zäÉÛÁª^¶Ïå›Ç¶óÉĞWÛ†¶Û—Ù“PŠ•ã0+–l[TÉtXï‰dê>Š9ãxJ˜x¢ñI¥+ãs¿ê›6ºL,_½)'Kr‡³Q–¡„AxîÒô&Áicé&a–Ø¹ÅEàÂFœóAüíG.ËŒ¦?Îc§"òhÿ0ƒ³g¨ºyÙ!CN®dôŒ;]ÅYåØË~d¸ I€2£,ä®âk¬1±„ÕÈ÷=O¦˜' ë-íD2B(nI¥(fŒfãtkv‡¨šJÜÖÏw&5İÿ{†‡¡À5HR-déòî¥Åv”~Ü[Í»î({Šëˆ/¬{èŸÄ6Ş°‹YÛœBªC=t]&k(áEï)ñ‚\E>'›õ¤ƒ©“ƒ.^áÄ«¯¢©ÂNİ\†–Ú™Ûû+h=ê9æÎíü™ˆ1½˜©ÇÆWşØ9¥ÏMe”lÁ
†FÂgì#€—µŸaçY··óÈ¢r_fºŒ b˜Æ>öOÕ@,´ro#ŞlúCĞÇÄuªON\3/D©:t8²XoĞ\Ù4+F¼#¤;Øqı1;„z1­ äEÀ]ì…ÑĞôUİtcCFAE¸(NÉ×§&É²Ÿp£KÑ–4åÅÅ_¹Ûe~$÷éAi;c‘?;­âSaïÉÙ2Œ½Õí—„·ÛÖ]`º•T>Ee-dáÌ”÷ı…¤†: Ø"••O1À®IFWäÍå³ÈÈÜcµî4®©ˆ½Ñ {’nÃm.œ0&$+i˜·Sœó“¶6ûŠl0–™EE3¼‹*ú¢‰úTáÖM²z­dj¬B2&­/GÊ™Içz;fıjæ²Ë~=ff…!5-(¢J ¦G@€¹B6BxIYÁVúiæİROÿGŞrB{i¶«šŸ—4Õ¤gRY¶îqÉ3mæü¡§ÁQxPÿáD´èL\•úLcıÒ|à³\:mÅ1 ‡í#L¼u9+¢FôM iñšÈ±P>Hà—®È»rïv‰Á"ª6‡-—fìÿ›pú¬†ÑêåO;(µÃY†¥ÊI€HALo]Œ9+Cà†Ûå;|§==ØsZw1@<§óË=½ÃÜÿ|'”UÃí÷¥¦Müşe¦xCÿ6×¿ZùÅi½†5öOY¯G<ÌEvk½CÈ7hAé?JäÅeÙKSÊ.×;¯W
‹ÇÛÇŒ¹lK$ÇüÃNÏóDŸ®À€¾ùC™c>Š¤ãèüÂa¯N7Â¯Œ®QhEu5½D„¨ºÚFB¹EKÿå–s<-!PÛöÍ³â'
ò ­ø’Ç*MÓ³TìÓÜv3I.=ŠšwÑ»m¹âÉcè{|³Øf¥»Ş«?Êx<uÒË¤fCçŞ¯‡ËÒ’ãµ 4)º’yK,·ÈëíäY3=(üÄ\úV9ÇW6ä2m¿—`ñë‹À—‘+@8£™"üZK¹Ò
c@ıc£4õGTñÊ‰0ßDÍ¿‰Ä;q ßÄkL)Ôü÷©g°9+*NU)Áá¶4oº ~2ògM†E·áæõ.÷÷*€í•uwÅWºW@ê»Bôbï^*fÂ\ï7L‡gõ	ÆJ 5¯…ìË£Sƒ¢æêlÄîácí¥Ü	sÜ>VÌUÇı!½”Êú÷k‚²çì	ó±kO ¼=¹@ßza“„„ıÅşŸí‹’üùÉDå›clé]!Îk›_˜¢%ÆÂ:€!ÜEç/ë’*åâ­r>”×TÂÉmŸ×CWyµ†Ò¦Dä7Æ¬U!urhÖµë™æMø2Ñ\ÎmÈWóí´–Ù?É>XQùé3;Ã:fwèğGq2Ãúû?¾k
ÄzBœšô¦
n9HÃßld|O“Şh†;~±{Û¨w6`ü¹Ó/5èË†YZĞ:ñjn£ŸŞÙ_8¤¿Öøÿ¶SFO¦}æı<-kğÔ¢EB}¸é9QŒıkô1ºßFû·şRi³PKTpÿƒßèÅxü¶óV‰¸JœY=HyC¨òˆ"ÁÙ¦+Ddá¹YÊ\Yú	òÒå›ÑÿNé”6ŠŒFSäùßæä÷X”’Ì_D7N9%õé…læ:b›Lç{ì¦r‘l}«£Qc¤*²«JÓ½3+€éh&íQÊD2Œ^‹H:X cæ¯³ˆe„ŞåÇf)U4¤ªëŒwlf'rù„l¨ƒ ¼Ìk µ#{y "Eúİôî¹T*’†‡¸(–kä*Ñ*ÿ†Ì›ÒˆÔ˜w†$ê#g€_Ø¡Gİ—DÅ{KeU•H8"ÓKÓ—·$É9cr§hBª9µÌ›ø£W!(ÛO8	P#æ†G‘È(½³ÈDŸt ÉNªWŒŠÑªı,\( †¤€…:à¼Ğ"ÀQ.
ºiWv3ù¿ÓêÅ­ƒTµ·ŞU¥¼ì¡5?À¢LGÍõèƒmtz*aó°—kÂCÚl”eü|ü0k7¢Ö‡´IÏÚ#³½xHo 7¥mm
}äHñj—-œ‰ÙñkÙ@­iÙad$À…—‰TëËùK¨iRıém_¹ÓËÇ’H½#z0×¾6›Ëx/ĞgpòŠâş>9øv:¾±®OıÑM‹Ä˜?4–A¬óõ×X€$á#Ø<Rº˜
ÊvBıëbOCñâLqi(z8, 
ÚƒU‡bì„¦Á¤ÉPAâkGr_Éo CK²hå¢ÃË¡q[hd…Ÿ“’6&Ÿ‘F™]Ÿ‰çû^>Li=ü*;±_p¾gBlÙIÈI÷ÊYPö|»Øˆ—vTa{F@¶?D–á™`JÂ›qá´-ßcÄuí¼¼Û’q§¹'ÓHç—4#Ûs>†ÆW§JGUj¸Ü‡ÓÄÄÁB_d$¨q%ş¬rGŠ+³Ä˜×Ò-ÜÈÌ(ÅC51©dD~ó×@­¬9“fÎ)ÓWÃoÄj!vÕñ	UºëÖ}ÊrĞµ™şı„mÿ@hQxz€‚›íñWKŠ €ì2°—KŞ±]QÂ‡¾æMj?³Ô0‰ƒÃÉ½rè¬Õ,IuŒ(8wª1¹œCv,Ôò{u¡àËù	Az1ÍkFyãdùù*—ŸÀ45ˆh‚—İƒÍ.c›¥·ó+ı&Î‚üÂ&¸­ì™Æ™_CÄ,^ñîhÒÉ+˜ÃğÕØõÇO[JØw°,ÿâçcNHÃ+Ë\ä·ªgA§ö'ujÍ2íp‡	ï¢™oƒÜv•48ÚÑ»yDD&®É |ÓpıEdü À~ıpan~ÎŸaòÿ?–åõú/å[”ù$TíãØ-êZcj‚–¬qëy«9 œÖU) ÖşÜà”€ñW\çuN²CÒ¤ÏF…65¿¿5”Ë9°P›á=«O&FDİıIE†ƒ™8Iúæ(çÉÖ'Z~ìItÈQëz]òlG…BrÍ¾Ë7HƒL ½_^ùuTbup
%‡ÅÈ,f:±¼ß]¬<iòYòb_§*ÒæÎf§]<V€‰Jù­÷1ûNˆ¢cŸ`x3Yş,H}+¡Ğ½ôíìaãŒ2¿Òâ°âHYÎóŞp_"€yqÂÁÁöƒhÀH¦ZãfÒ2È—#ÜÚy5o$\ùß±$ŒãÙœªOÑO)íeıübùĞz³ít?í‚$Î„´Ù÷O©!× ]±…ÃÅ$;ı8–L›d>KÂá
Á`€İä÷‡©sÖĞjú+³Ñ:Y2=¿ŞBÄA¦i€ê"T	à9<+B¡ ´DNRqÔq¶HV-İd†ZÌ/ş"Ö»4Â4 /óä™+Õ^;½ø5º¨²Ô»òƒR"ZtT¾T~=Â
âù…X é=?Õğ¶åŒğò–šz¡£Y¡—«<‹:jMÍÔÇ(Ûª“ïÈ”°‰â.sœUrÔ›7œ‹§Ç:F·±Ò¥¿=§ÛpRÄ[¨ :TnÏ«º¢œU=§’¸/àÃÆª=@;AÆ¥“o~µ÷)¬t­o(Hâ^Ôo™og¿?,'í\c»<©p~ŒySòôjÌÈÖ°½0V¸µtÍ€³K6ñgJçUÿh¶•Ô¥tä‘G†_CG«'©¼†ZÁ›jb¸Õøwğmgx MññĞ¹œÀÔØKğ]ÍT½¦lø6-5Á(Q7wÏišu£™’ïAìüzûÕ°ÈìÜ+AvO¼^.ajÓ•@)½ğDë=û;u4¶a•z„º´ñ§@’oTÃm2Ÿí+®­æ$CáŒ ×¦ásÉ¢Ò±(À-ÿ¢‰eú~Éy@ÍàÛõ‰,ÑãUXi¸èŒsÃ!?%I‡<mƒlÛï*‘6€Şr?™·Â4rrXûÇ€bä.«¤q­k`àB9rITÆ18ığFnO‰=•²n@O¹(.¹4á÷F°©Í¿ªúDôµ¢:Ø`W¦°Nƒ›éçN¨¶"ö‚)ì/UõûÜ¬‰f*u*ó®7ÜÿF¥õ—‹¿‡¢»›ux/èbHÏìZÀ:&úÑ8’µf¸nLQè#åC·q_B¬q.D†rxz˜;µÊ/:ÛäÚÕŒóÒ.ÿÆHù_/kcKh^)¾Z‡OpaÛ>98±N&h-ª´›©Øá¬îCLB»ó“şb©‰¤	­>–ÿ†eİ’Åê~cíİµ	® g½-Ÿ¬m\ËL1	tÈ±…ÕÌ4m†Ê¥LË»¹äÎ¬ÚŒßZ"-âÖ’£èE‚ñÒÿ~™z[ï r«Æzt€tµ~E›’w{‹İIOTo›“áßj‹şx¥şR>5[d:L*Crª¿ïe`·×†Kçjƒ¸‰Oş‰Á6½5mHõï ş.
 ô4é´ôZĞVY`JN7ñÕTmTì,×SfVºíÊ\YÙIFÁúfFTŠ@1º¡G6ÿÍÅrà}^Œg3Ôâû¶{S•öVojyğÇıK8¿)…4FÜêïú “‚¨‡ó`962‰¹Mß›d‡ì.îj>^,ÊelS|ÿ„E@© ·@‡†pˆºÛ]©·U[±”=åQç%àñk…Û,Jã#ŞLëô¢;¸³9”â&,—ù‚ËÄ7j]Û+Ñ*îşíÜİ4ÔhÌ£3HBwv4á±OÚ§•P{Dm©jx>B±P¸¼p§ü(iò¿‹ÁÔàÏk_½§ÓÊ¸m°)äÌkµâF `ĞN6µå|Ğ˜XUhıCyüÅŒ„*fıõì“_öÀşüÁ?"ÃöçP —µ#p·ÔW‹¿¨W
sçüš èÉìy SS‘Ì^S»ˆ>B7Ç$¾×ee~‘šÑw‹)$°Úüğ‰3ì{•ætKˆ¹soWt”³Â˜oAÔVÇã•Œ<pe}:S©#‡«\ K¿ßÙøQÓhÒŞòË•z(á¦‡×¾îÒO\Á%âÊê4ÖRÙŠ£ñğLÏ»b.v^Ö %€u­q8O†n+¥1éGô‰à¯ÍO·ÄI­YÎŸ<ro<Ü WmY´¯½bÍBR&ÎõS­èYF‘UÑ°º!tYº!êê
Ÿw-—“ˆMËğ]/zòG±¥Cl7 Ì%^µ»s9”•t±u_IIˆÆÎ€øè˜ÎŸ‹ïÛ„ÒæMÊ©Ërt2¸x>.×ç+]
i£ƒ½~íûu-v;<:sU®ñ`ùÛP_²AmÏyÛ¤+/¼–âŸ%[^PÔb„xcØì òYÎg™²{5°0&H¦3UL÷ô1àáiĞ6q33Ğ÷ÕÕi'W²ç~CÚ“T#°¤!ûø¶w©¤K´Qæ[+Å2˜ÊÊ]9Ö”jˆQC6byus„Ş:B°À°âm¥!ˆÆ4=Ÿ*¿J@Ãì–=%âİ4,ã©~üãŠ\-€,gG;lú•©|€½16^DTÏÌŠ?nıòÓW7h=§ì¿	ôjÔ(Ã1îFj>§VUÊ4á§c´aözÚ2¤òÏ€dP]nNq#Ké=uËb…¤ ÀÔ-Eˆ¤d5ˆ¾Æ‚í:{XõÙy¦ 5]‚‚N¤	F…“X>‰*Ì>’)lX!+½»?îK¬Ô¼Éó‡¡›	•<lï-ÇŸi­
`å§ø÷ Ü*˜ÊQÖàÄsÏÙÿ¸UìC¥¾Öúğµ«ê7ğqººÕ–2i¹$Gènk˜x}Po Â‰ÓPE«E³Y‹U¼‡;0(2hˆ/kˆQ°´Oğ¦#à­÷¬ıdB·ã†0ÔıgñUÊóÿGÌF¶ŸlO_K/&a
îf{šÖFFÓï ˆ¾a+;47_—ııw×‹£<]KéĞ •†ˆµk_y#¦Ô½åİ”é~şû4÷}°2Òséá±€Šº5IVO?L-'0Ÿw¢Fœ¦?‹ì4.I§Tâ †AQH õêãgÚÚuM·ø<ÙşRÒ¯\˜Z@QlğÆx‡÷ã%q.EÉ™®Ïó:Ê¿-,ì7åTúŸwwë{D|Ë;z n­8‘ŸùÔíØp‰FézXĞÆaèÒÁñ*Ã¹wçŒfÅ.ŞNÅÂ¿÷Š]^?})_8?Ôî:5ùú/2Ó=Jnó¥ıêí»ŸwF‘EÙ¬©È…öKoTÊ1z‰šäˆf$Êúô4ÕDÁÕaVCw—¢µ3I¨×d$ÙB/rèi0\#¨özÉ2É¹ìI‘8‹º7	c¿3~YŞ¥!L!ûÇ )Ä)N’@A'/»|âHÌ)(9ünŞ>4ššâªx•„	Xá,›3CŠùsnÔCPî¬
z ºç™º“ô­½öå»¿âój<»êåIß.ú-|d@3rÎ*cV•mÚ0É<®Ù!êVTPzëOàX§–	»+£Q9ìš?²¨óæ ú ı¨eB9ëİÂ'”B‰ø›<á{R×·Ó£rdjA×^= œBïØ<!­
c¸¼Ğ·ˆ}ÅÇŒx,ÌCÁ»ï‡”ØEÆR°òòcäõŸr—2¥Rp®Î’³™ºjè,ê	?œ¬­tA-mË%Ğ2¶aÕÇ%™¯yöC¬Ÿ=[¬ß~+gõWC±6´Ímˆ6¶Ğ³õ	aÆÄk%ƒ¹³ßáè¼fØ8e)5×é.^cçw0EsåX<<Õ­á?›7b¬3`”<;úQİöÒ~°» *Å9ˆ[Ë‘ÆÀô[Aé#Åe¡-ùZø¥y7>uMû#â©LµâŠt5kº\!ğHÃ—pÂb·ÖÏ% v­Ï¾ÅYÅ$w(s!Ò´$!}.lå°Ç%°OT¬E8!qôæ$iàú†I/ãhaC[ÂK&¿2»J*Z7;¦P­jÆ+LÉ­»Ğjyø¥ªB¨™”ÀÄs7ll#3ª)ìİ2£‘ó˜òÆù›mwdúq­PÌ¡k0ø‘ß5ÜV.İaBé%‰…ò-u‘‘™tWtá›ŸHÌ‹+Òªèo¯óMI.ñÁ¼‘›T3=ly¹ôÙ9ïä#»hTbï¸›ŸD ¶9ı[FÆÙÂ•ı+®Š£çü ½“Wù+Ì@Á>qÕÌ}ó÷r3¯kŒa$Jf’xáîŠ`ãÁR
 Ô`‘‡i‡Ã,`ÏòL9B•*®Œ¹ïDìo?:ØÁƒõÅ äâQúÒc}›ûoüBO]i´’Šë8€mİ¶©.úN4‹‡°7|€ÆÖìÎPXêL*ÃÓ:è!X‘…†Ó	¥+m=¡.ÁÙ†Ne¾y´B„à ·%µŠÇ-_–*Ü€Å¦BØ–^Æ–Ke ºö,`¹‡ã]K²­Â®ÕğŠÀ
µ³ŞV üô±i…Åï\AÚ&ZÉÿeö`“ü§Hó¤m«9
m9‡|c[¹§AÔ¿•£½f4¥Wî)»(´-¥ÚVòÕ_‘wf‘pr©0¡¶`v¤Prxa_>3Sc€ŸúlÌ%ÊO]–Í¾ø< å‰.ßÀú8ş¤û +ÈRÌôÍ$<DÌ´ÊfÓ=–¤\Dõ JÑP³ªq\.r…÷Qa(+)Ÿ.–N”ßiX6Ip|¾wñ“—RŞÁö³ä¡OpÊ“ª­?±tZsïÙMPÕ—ŸRhvôÀ9şéQ*yTÓÖ‰àqáE}¤JH‘œ‹÷½ô½¸¼˜mìw¡E"Î–èœé§>B±)ÏS˜¯Ú!^·l¾ZJªşZl&%ùÛ:>¨~»ûpJ0,Ú†<3Ş§GßG†é¶¬u¢†ËJrÄ|Âx! ùUò‘¬´3®å¸!¤@‡İ»P‘Z1W°‰¨—¥€­=¨1U‘6dWt~ÎÆè¨BDõ‰0}ûÕ}n½‰šÓ9th²œU—]T"’åÏĞsfxc˜É¼Áæ†]vp†%3ÇØâaOù¿B”Théş¿ûÎÈØ2Çº3Š†Ù°²¬Şİ˜úİâgwˆœ>9V8eRºäG¼5%|Ğm`xc¯×ñuM+˜~¥dh01vı&Ïû	v1r‡Lå^8¸!Â©¥««›XÅG+‘§µN?sşe™èµ!ô´«‘²›ô-‰2´¦}*œˆgÃA.úëåmEœe…WìŸZx¶É%*Ú´6ãC2¢\$·Æıï+¢ëğiğÏnÅË×|)³\“;6à`­å±-úQøÕğ‡­–`¼’n1ê!°ªUµwÏÚëäŞ¹â¤ñ¹rX¥^åØ¸×~ıj£¾¨¼g²ÅˆU\”²"…“h×Ny\Ÿìç!±qÁ÷¯D`¶S3JÉéüÜncq1v…‡ J£Ûj€I#Ï¢F7è<»uyÅŞú8•>‚~öò%<òØ4UÒŸZæ–P]E×«¯ıÿä@Q³šq•D¥GQ¤7|åaƒ‡½¼ŠşF2´+6\Y¾ÖB‡)ÜUï8O“İúCsQé™m@ÖhZ}Ki© ìİZ¼,$§óÃğ1x*º…lEKŒf+(Šºú@¿•WÑ±ãt†œçÙRê^q¢D`.l"‚Nà0£!œ~¡}Í•ßíyFünÓ¢2§}³^¨êĞ¼­;œ=Ódw‹‹¡tSõ©yeêÃz¡¬Ãé¼ÏKoÇMA¬ 3pÖ$u{î,àòãAÊmã¦5yyæ$Ñ‡Ètü´ºG‡ô_I 8ƒ ]&NéX¤pµÀ9¨.ZB\âÆÊ7¾Äâ§ÿ‘:„½b;:&Û²=Ê…¢PWõÇÎ{…nédZÄÅÑ}¡å6“³Òi)59ÆLè8^XÕ4œ9SÌÔö…&ÉÄ·.Éáqb„­­É“[zDİ$f]AËÜ9‹!Ùÿ£=“×a[K${ß[)³óâj[¦- »}Ze„`à-nû>·9¦~æJ{ŞfM14gI~X9ö6Cë¶–PoœÙÉaĞ®£ßŸWÀıÿ„§“¸23<©Ÿy1;Ífˆ	mÍC‡S$6š„êàm¸”§è±ñ¨6pÑAåè1@ÁâÕ"H?R?Ô m>%ÉÌ—ScXÈT]Pès{c«‰ÄúºW+´mÕ÷ø=qq–¡B/öË¬¦íÚ‘ ıAÑÇ©KšËIäşu>›tìYñÊ#ˆêºŒY‡Mäky†§µY|çAj9ò(ÑZµÚ†%€Ÿï÷ÙÏ]X}Ö_&Y'ğ¶”ª{Ã«àıHàÀgÆ7=ŸX%ê¶¬GPIi2 ı”-yNm÷»Š4®+h#ƒ¨^ü^IùİrüÁC(‚`/Ÿ1ü„O½¦g,[ùÆsjG¾Všh äÎsşøúDøüévëa¨‹ã»ğ–‰’úú!,Î¹öËNÖdº6ä—»öUåcØüM¾‚ã±=Qu °+Ã¯¿CqrÓùp¼,¹7D°Kb§H5®:•øûX…A$Q[pDÛ»°Ù¢]C†s”ic[1ñX%…Py”ÑCÜ%-[×}íq¥ùNÏ,Íı‹ò€úê¸£tKJÜ¨VÔ{Ñ9]'‚ºêY•5>’'”‹ÿ›’	·–IvOıíó=;˜nş¥[­kÄ¯ş#ÿ`ÅÀÜŞÓ^	qm€	ÇXßy+¶;¿¥»S+BoİlÛè6L'Ô¡°f’ “û;÷¨»Æû%Õï=°Á8ÃN–>×æ†¾5·qhÛ¹C°3>eÿßãU—${4SÊK¼îïøP<MÅáQ!Š5Uš
œŒ+Pñ‘%VñòŒœ"Á(¤Ù;„ù¨ó`6Ÿ†Nš§¤TéÚajm}[¾è,”zˆ‚ˆÎ¡şb¯Dö|ÛE@Yiaåº÷ƒ­XÜJ¡ÅArğ„¤’Ã¶”%š‘©ñáb lˆR8İ… ÀHwÒ_êhÙÁRs(ê’…Ô¯úwÚ“hr4]zİV{Y„R%’o\®áÙîÍ˜BÓ‹-´õ
A+Š­%M[„ËH8³ ÚDÓÍôöuÓ ;QS¹&•™èá¢µê&mRMÔù‡øHØv>ê>l,=–å†ÿ¼‰@k-3MO„Ÿ±/Ìv†~rƒ¬—ö‘Î=W¬şZ ¢lt Vò†qoç·Õ5µKEÂ3ömÙ¾;9„«êÇRZU›ËµÎ Ş¡Ã6ß éCóğÚt¢:û¦¡šb^üW£ª„qšö9&ÈBPŞìíş¶Ş& ‹*à®úszJJ˜]NîjŞöw¿¾:ÀW©g&a[¥Í;-X¼züØiÑ,AÂí¬ky5ÖêÀ	ÀÜbûŒ„ª¨¼¨…%ÿ*á×âFñJøœ@Ç²[Mr‘O|Axê‡)‰mM¥éÃ×–ÍnVwÍÎ$ÇÒ!ÄTÌñXÿŞšÓ:ÈºbßV¬ë”[[=ñº3á2–p£n®­ï^„ÌR(å’t[ïˆÕ˜Şv×n¦ÜÃ¢Û))ÔÑ’ŒÀ.œ~Ôm$™¡nÚ÷F= jåzÊfcÏò”ŒÃm ıu7i¶ûÑ^¢÷/^=nr4U¨Ä]!„MÓŠ‘hi»’†÷'ÕÛByöP’Ìv±R çÄ²-‹(ÿyªÉVíñağ N®V*<š•§ôÁ~p`Æk>é>»šãmÇŞJ5Q.ÿÆÚ9ÃJ'Qsm³pÇùÀ»ùŸy¡4:•Øzğ’H€2…kó0·ìf\ÓOóïô‘Åÿ81ÜÙ—øáï#¿š ßèı¿X©ğ.7Ñµ:™¼ÅQÜ *Àoû {#×ä|«<­Ã@—®^ô<­c‘B9ÅQˆqz¿b$ùíé¦>OøXö.ôôªaÅ_Â4NL\ãyÅùU r³3ü{låtrÛ™^ù8oàÃèŠÔçÀ—¼Ò2<ªu†ÙyunûAu(–\Ğ3R¸QWd¿p}Òâ­Û°áİ[C.ûkuu…ˆk(ÄãR„«pË½?7Dd0ÓE
†-›ìÖ[uœ¼²#İseÿ(,I	PLùE-v€	Âêsà·A4F—Ë`³ŞWªÿ™œÆ±òå‡ì„İ®)MæĞ¢Ô’¾`A—Qêl,‰4jœ…³³RXK8v’€ã†i]¼´ÔW·[Rßª¨N]‡{öNMU@ ¿ßx@*î4O!1¸Ã¤è˜ÙÈÍ8ú˜*,@û²ö†~Zƒ»ƒ$šÒº¥¨c$FÚilòcaï¤ÚFVø¥®Ÿ?»»©KÈNBôÇË1h®P#F\ÎmMó±$u[é…¹eÈaôµßãHôÏÇÅÁØ+‰¦ğ|çoXÆS¬õK	
vß1,SÊ¹Èv‹Z:"š¨<‡f:àYå÷Xö¯iÓåØœûÂ5‡Ş_uºHô :"È{7O¨ê;…QkvöÛş‚«5L4ô^éZÈ(ªñšqm!|œğw¢ıZ„zò5Œ‰4ìŠy³–®‘g°È§å6±j¯”à&”RVÅ"Mø†,‰²ë±[İ»)	n +—i«‚İÇó˜Ú nÕ—g¤sºmú>}<ñÇØ…‰¨}1''¯ñŠH›ïKRÑvPÔ”PõŒÈXAr³| —€Í™£`¢8½p![²dEoA ¿nË~Q[WÜNÁ¡¬O¬rÍâ¨+»àv¿(,³HO‰p(N‘
Ù—¦+B›£ŞË«@¯°+ZÍîİYâñBcÊëXÜ Ú­¼ÛâĞ˜,Ò5Rp´Ò¼¬ §Êc™qùÙĞ€|)ğg¬ë¡—:¥(L®Øe7‹zÄXiçÉ5ÓEO,˜§z³È+¨¸¢„cW´·‡£x;kSÖx˜æ¿Ê/èÄ/ñ-¦)Õ|l›†¬´´ÉZ9üé»°Á#ELGŠ¹r¯»xmGÌ¥ğİéNu,xC ¬ğCë?l!±™ïÃ ­x!ã¦bvPN¦a¥RÕí=s$Üÿ»†V:ÏŸß/]\ÅúX9l&îl¾ıwdŞ<S)â ú*ò\ô¶g°½ÅŒZN$µ2SwéÍ°g‚˜Nv6"}›¾şü|Î*ÆŞÖ•E“9Mhµîbô®ÚÇÂ—î+SµDô'ouæ.Í?îáóØğĞQZ!ÿŸS®šÖ&¿CKH.Lşn•ªUlÕÕğeQ#R?›ªaÔ¦Ş¤w]ÁÀİÁUİÍ\/‡Ñê›¤bHD®~dS¼¹¤ÔJ;È)Ü¹Wyow:»› L~Ò«[®Ş;osü:46[I3w¹]ëÜÙëB53k<±+¹±^¨P²#ê³Q}‹Ú÷Èa‹ƒgÓæÂ°€ØõlHºqù+İˆ„µéô`çë•éõœÒMÄø7ìm¾l$W³Ò63.½}·î4ÏuJ« ¿Ñ¸TÛçYxå/ª—1¯^ŞÖ Dê^åß÷ãó:Kx ŸL!ñ®„‡ëáûï
÷PTûÅÿUEÆoÙ	‰‡S
Û¤,ëŸúm5*rç#LuNğ)Ö_R~Ø$êèÉÆd€VÎŸ¡ÇÖ‰òŒ¿ajÇ*|Ü|s«èèjÚª|<øÜ1%¤Ñ×kÒ ts’˜+Á;'Uëw^‘jlu­ £q<BL21÷jùP\MN wWÂ¨õ±±ÿ®o<¦ ¤YxÂëo(Ï§'?µ£Âêİü¬ú+ÊN~ÒË~ù”*¨¾7”WRÙîÑ‹r{Õİ2A¿2Ì]Š9K×\™ÁÆÀSëğ[’É•šèeeÀÖG3x)Ph´®:
@Zj\gICmb.®nè¦oş[LoUúİõÍï %%ğ%YUŞñ—X2îrxH§€n°\Z †‚YÄ..°ìº;ó‘ ûM7>„ÈßŸ*Ç x!G¡enÍñ‰»µ;$o&ÿ¢¸å¿D 	ïä=w;ÛèMgOĞ¤ÌeâØ®
ÌX¼50?`x{»Çğ–9KÜBï«Š¦îæA×³½€˜©©|­$V¸w×ıyÚîu&	b=ü±”awœPc	{x{Dº¬y³Oj-œQ›ôj:¨¶£<öâ6·ÄC3üY¨µ~zŠbñ“ê«£ìó:]^<cçÀÍ‰?eó!w ËËêíY0…İXÛ<Vû‘pÆ3?nH`Áüæqß¥©MñŠS´>ğÿ0e‹É¼LÜ)âĞŒZõvèz{—‡6wz=Unµ3¸*™¹¾Y6d%/åÖñk ¤Îš“™Èâ	²#¼˜ÄÊ#³!Ä D¾Ú†óª0ƒ¯_®n¤/[Wq¢V¨uÏìvÈßm¶ê:|òŞ>?îĞaó6˜?ÔHu6ä§ëC“ç*(v¹é†„Lª’Ö<£Úw]Åõşóó¢1hÂOï6æAÙâ½—Ô[è/¶Ü²|âêJ¶V‰Kê“ëå«%õ“
nİÜ{$ÚÉF`H‰Q¬ğl=Ò“N6¸˜méÄårmÛw®¾WÛR=ÈsŸ˜åñ‹]4ÜdO÷€”o>o7úbK<„ñ+²ßê»ºQû	 Ã/±ı{è„Ò$û*×7BQäû»¦Ãj¡*êªDq`“š‹xpØÚ*4|4¯ÆÏT7t¦ÎoJxyŞÇY°[rÄı}>jÛæÛl1‘»jfş¯LıµÁ Ú×|æ³L@H—Ã‡¿¢S.J
õ¾Ô„u¿Ğ‰0Sl	Éµº^sğá¨éÂ«˜8gICŒ«fÈÅgìÅ~abÆ9¿ò{ ¿–Ğw^ZW9u°ØbÎ~­õt+üş/€>xèEÉò—#îè™ŞH„Æ]é!¡,	Æ¯+Şõº }Œøj?¡NÁCéÍ |Fœ{+f7HÿÇCã¯Ô=Ç¼á	Í–EÈ3B²`mû^tòyÏú¯
ò…Ü:ò…ÊœÜi+Ğ@›_XTfİ×ãÕÁjOø^Ò¶2aW&äã(vå~ÍÖ«\æ%¸×íIB¼‡+@‚8‰K7]ƒà»/	¦’ Ú³â5Là“!Ìãğ {[°.S¬	ğ]¢MèØ
>àÍ $lælñH¼$ÕLuq—,N—a?”i,ÕÛæTÕLPÙQ’¡½£ìgEüh¿¯™–ÑŠ'áüR¾©å¸È‰¡œ¥·¼Nî¦«hb&\¥7QmF7§Ê-U)N <5Imn:" ô·€ÀŞe¦ã±Ägû    YZ