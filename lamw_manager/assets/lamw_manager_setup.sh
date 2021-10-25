#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1158930676"
MD5="03ca2cf3c7cdaf09bac972c195a89736"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24104"
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
	echo Date of packaging: Mon Oct 25 20:51:51 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]ç] ¼}•À1Dd]‡Á›PætİDõ¿RñáÍ_,¢½ºÔw£4EÉœÆÒ\`!ÈDµ90$€g¾{(‹¸÷3å(ÏxŒ	'qì©\k±7&TõŞÆ€ÎÑİ‡ÛÛw"^ãèıï"D-Áf3+lò«õûí\í÷€ä_
]Á)ßÜïê7İ<w‰Zİg½®ÌÂX¹ißÙäˆ1¾‹y,÷$óÈ	‘Ãõ½sÂÈ'Ìm©õ‘´´paÆ­JÒ±#/‘ñƒbÌeJ¾O!3€Ïk¬€¦ã2yÑr‚R“Û&pÈ­ 6f5K”Dà1õG$ ¦_Ísª1k KÕjôÒCûÅ8Òbû	$wÖeCHâ_cê9ÕŒmØ¶™Ø=£…C ×±ÄªÈ©”š4‘X1bMøÒÊ‡ÈÚ4p6Ø¬oiC\Æ–-2¼(½ ŠMÉâfñ@Òˆ»ÅYçè,$©ÏcjGêğ/µ°P¦şÿ‚Raú5Å¢xXÙCŠh¸ ékZ†v%Ê‹Gœ©n«Ñˆ‡Ñt[?îjd„-è@ÄôsŒ‰|'@İ‘Õ"t'ëouSã~†­O®^r32ãV£XåîxËU–‡çÁ­q;J¹îCHã¦ÓõWKL£–ø"8LİÄu¢}ğ‚ô«9ëÀ¾µÎ¯hRİgWàª t‘Wòà«°Ğª€2/œZÂ©Ã¸Mv…?$ƒ8/ãqÁùw–ñ‰fŸ0~)"š¹S¶™IvÑ.>$£wéá-b¬Õi´"Yß‡À`.²ÉG›ãLàX)u]_BV…ÓÇo×¶„*ƒDZêØ1À¢%³àh=Ò®yyş#EIcóêk5E¼K=(V‡ôÉ¢aÏl²UzQ‚ÒPp<››¬¿Í¬Î?kŸ_Òò÷@–­X%Îê:)Tî¥’{ ¦”ğäè#ÙR9+ğÖïÕ
˜Ià×,±¶õ©€ğ¦f¥µëo©táò5›ÎşqP*
øÙ¿]ë—D”“°Cs›e\Ü†?åÑ,`ĞĞáÏğ#ãL—½7lMÑ^;·(ùÇVŞ*¦qÃ}4ñÂfö¼›µqˆ)‡À®£Ìviv6ÕSCHÓIsvrøœœÛéf3‚¸7N¬,›b=±Şc|Ø¢Aé…¾HûrõV ‰__şĞşîOUå¢IÈ`B±^¸ ÑÎ .¿ÌÕƒèÚâ| #˜ÎN=KA›OŞm “€Œ”(•Î„øÊÏñN”ˆ‡Pã·Ò—›§­~²Ò ùÑ%ò_º}²év
¢M'˜,S®ß«:æVƒ,méÀU+zb;îvœw„ª~˜`¿±gïZ´=0ßSö‡0å+¸ÊP³ñI šIFT"Ä'˜UQ/Èç?ñşO;,(!å¹Ìmÿg#îÊÅâÊ©¤`ÚÕ²!E’‡f•?f±WåÌtg„&—…®sëìø±z².£É eJaÕ63†TR¶¢ÿëYTr™Ï”òİC¬ø§OÃ`­Á£1³ò/fUÓ7‰W6ßŒbÛ7B€z÷[¬s(ığ+è,WJn ‹æOÂ+gnxòŒ¿kHòÀ†¼áŒ(°Ê)"·ÏÇvL0{ê¶A®b­Ù<]2Ïn2ÕûĞ4]£+ª»í{|=äéwëI”HÅ?ïTF^*¯€œyh¹ ‚éÙ%M¾ /È‹X·è'bbˆÙZ`}ä7k¼’á¯Øõ3Æ$ñ|ÊzZğÖœ©©©ã¤nD6G­³«×4A[>pX)Ò¦›•i9àŸ+ÙñÕÕÃ\šÙ ¨¾ÀığˆïÆ•çåútËt/~Q<koBä`'ôgN·Xl”QU"ğËGæïŞáÎ0\¯òrQ¥ïISCCkIgĞ]{GG&Ğ?€{Ç:¬´]›ZÃÙä“îy¼r?¹°w—WnÃCî:¾A\Òt‡sĞ$GYBpWtRÀõ ºNÊ-ÔdY0º¯\øR}ö¶7î 8®9[
ğB†:‘÷ZnNE#zuêPàÛ£G_Ä°–²=Ä-õ=:ïãÂÔL¸ñ)Ô.GJù1KD¼ .±=eL~ãc fDa}Jƒİ’Q·İ`M’JÆ€VŞr/¶…c”3”;§–4½-€Au-õ‰<K“q„jœpÌ®î>ˆHÂˆ¿—Là!ô; ±ú¦DäÊÆ}ùJ•¥M¯ğEá-nÑuO€š!ó½gØ DÌB=zÖ&.Ì+W‡ˆ”nÛjb':øÓJ4 „³w¼’è‚:H¾Â?ó¤íQk§‘õwúİ_´İ‘_Æ"?ô3Z]wöÓ)úSSXCN¬±ŒøJ³ë_Ù­™g²UÎ}„³½R]d–L¹È/E»rb ÓGlØ“S„®T"x2¿Q¢b‰«È#>K×»¥Î†B^-~£‹Ÿ6µÏ-¬.œ§tú	¡	¶IÌ€÷e<ajLT ŠEt`Ê¥YZ¨¯‚¹ÜépR¤’¾u×([%ô €%â
œÄÁËnTÑseF¼ĞrĞ;³)şğõäšå°ÍÚ¢°ZkOéÑ¤%V9ÑÕ6LŸnttmÑÖ¸«ç›Œn#×Ä˜uJÚÙã÷iJú²ùª`~"ƒ&¤Pëgíe„Ó•ll¡n‡]¶µ'ÕP)ƒeÅÍ]/gÓà™H:ÎÍoã®hz¢„`©§ããƒ”ÏÆ6°"şW

Ú£—«ğ¡ƒW,ùÒy¡	ªvÉËAOD€—Ó5ŒÊİ²"nrtuZS7+°‡\ÎwŸ¼Ã6ope^©Ó3ÈÒ.=òÌÊWÁ5âÌ»PÁ!Ø"ƒ€u
öÑº×Ñ:ô
<öwŞÏLÏQ‰ T¼›¡fsÛ(İ|VZv<¬ur&o=*M±xvBˆiÔ¡ïÑ—¶üƒØl)ã°ÈôE÷š•ó[*ïjK ÑÅFe¬úŸOW¤™J›“½}í‰æÌ:6*,¿üØ¼æR}ô’bÉ:uY+#G	,ä<JYíyÅ…<Ø™~,jEÏ|‘±”'×ª=qª½™«zŒw÷µ-,SW5Ào€…¾ãƒç•^Î@-°×Q¸nñšeTV*å+¢ÔÚwnÜš
 Ep«å¬„ÌJ_ÄÄú9"ºäôK.ğ’'åéAsĞ½Ë«†I¡•Æ{«±Bš9!÷F@œš0Ö”Ğê¿_ö“àN	âô¢@OÃä®âä;7ü€ã–“</±X„†§3õÍn>ˆ½ı¯%v…lZ3~ÿGİ(2ËWŠ3Yím92kæ…‡ñ³‚‰™H7–t6D—=f sÊ^ÿ6{¹åHâÑûÉ^¬Í®S_ –¯vXë8ë›İ3L†ØØ·u`ÚÇ¯]ÛâhÏÇaKyf÷RÜõ¿¦X9€¡rô]g¹1ˆàSÓëZ
ñÎ†s¤—Ô§Ñpcõ€
9~gA&e ŸÓLöb†­øH=Ü/İf†Óù6 Ò"(Ó¸&îŞ3‡¦ãÅ3ª¿Úœm°§iİeéÑzåÒİ2½‡w©°™÷_6Yv–&YÃfŠé©´L×s'‹wş z!Şsç‡O¹G&H:·\oí…h¥·Ç¿uòõ:'Cõè¡ÜHıÍáßÿ´:ìyUşHL¶û­Î(Ş8‘È¸Ú2ŒBëYq0;õrlXUŠªáIÁ4Î¨2ÑÏtÅÓ—PR?˜¸=S–Y2>¨ö\±âæ)ó„f¨›ô‚lş?GSQ>:·ÔM‡ù¶•ÄèH]`œˆTHX²cÎ]ÿ+5…xîÊê]ÁhÊÎ“{·zİoÏŸQoPÛÒ<3OµCOï˜ ©J)õĞûêàñdã,5ŠK –X?KW"ZE£ÿXt÷¥3IñTŞƒnìÑñ+ÀâZ/ÈxMm-t3q3üÊsÂ‰ NÌ!û¬oÄ¶<*XpØ‰î¦æâ,?˜	Ò°¡'—@Ç¾h‘·1ÛÕãÃ{…ş³mú ƒñ­gvOïi&øÇ|ÑœìÅ,Ñcó o‰k“ S<TNÃãşµr<şcçÚ$¬Y®-Ó@8iı÷zúÎW’OĞsà_‰$a€iüŸo’ß*xò ƒeî××š›6†ß»
ªû|è9.dqµBWTŸù€ìº¶"¾³uŞÍ:qİ63÷˜ğÓÛ£Z}+	€Fİş%ì\l«ŞV9#?3¸r_T=Tîg9½ùIT†Çå›K^üÒÍ€„<r¯Œ<‰Äµ à*!€å{ƒ1~íÁJò“Ì8­‡”gù“ÊFŸ„cûU$,ä øÊõ€ÁÄ¹¿ü“’Æ›w|…¡¸ 'NNÃe!í ä,'üèª¸Ş]»Ò´Â>
nåú³crÍ+"%K¶KUØb™#õ©#ÓÉö5‹C?¡g®	UXõRç÷›úë+ßŠS¯¸aŸ¼“q­ÙO·ú?”:OÑ/xqBeÍˆÛ¹ßxò;å1]“çò%z«¹_Yu8Ô½^‰÷¢Ò²ÓA7_Â&°P¯é¦•FZæ'q) ´dü²h'áxÊ53Gh£=o‹qŞ£z-ùf¦–ñÿßÏ¨QOHLûñ>ÿ9×øj¡,@›)òOƒ´‹ÃŒõW
Uc¥Rÿ ÷ûô2ºÍÿË3ícHÙÊ]yjĞw<LWºú£ÿdìƒäÊI¥1•³ÈLÍî¬hˆÆ•2›$Ó4çxo„aœÑĞ2§—èÊ†#« àKv|¢é´‘Üœg±¤ûé8¹£¿Û7XÖÜî<DÏµš†Š »!üv\x¬Ìåf™Yîå¶„/m;w]'äcşï°„C¡MPØ›B¸¢ôF	<FÊó-2S:ç‘«"ãÕ1O&¥‰uNõu­ ;bµM•×ĞJÃ†‚½+º$éh[ÃzÜ×eÈI6„¢Ä ‹KXœK¯ ñ=ÿûRn¤c]<6¹YØ÷U–nJqâd2íÄ€SÑbc.…\xJª‡œùwĞÃ×æóºÉ¤yÏ¶YØéo&ØWç'Z'–^à¥ÒAeÅşæ´€úÓ("XÀÔà³˜¹yE' Î	C °'NÂ%>v}@K¹ˆV›W£…n“9Hp¥š!Ğ?HûeÎuµñ…ÎøFL03…¶µBˆ‚™D4Ğ—?oMVö-^¶ÖšÓdk«j<ôâû;0D© DøyjıÀj ğ</O·hë(Î‹³O®ÃÃŞÛÉËgØÕõh+ÇLõ,ğ0èÕÀLøèä~0şÏ‹}ª:3{†¢ãyYÏ›^]‘“Èqì?+2­wø°)V»ñÚÒƒXŸ·Â5ƒ²×®—ı§Óp£ç À@ÖÃD&Dñ†rl‡ù-'tK©iÁvà€+&äœâ¨?î²4±IQÉ…ØepAï×] å<ÊxşåU‰sÀHX`¡Ë¼¾–I3´!Š8Ø?};¢ûN­Û‹-{òú€ÊÖà³¹2•Le.¡X¾_#ş²Ã\ÿÅ-°ŒøDâïgD1±vSmb_š2Ã\ï`Êh ]UØ8Y9³|hÀ*V^ öÿGYÏ`uÁJ¾'€M•9î`_îs–\¶Í°J÷½ä€ñ(fëˆE¢£^*X‹Úfá.)	)N>êp3ZM–ŸÅoËÆ‘µzÁ}ëË•oq-¾°	gI„u'X€ß”±R3À7‘uÜó`I~ğØÜ+¿,¸bîÄ|8ï£÷R#k£qŞ¾¸/›_ìİyÚ³axLzHâŸ•ÒlYUK¨N’DIôGró*qºŠàdö³X‚á©B?Üè#äèõ÷­åóc¶±U~M[¼w¶Sæ9ë%ÀIÈšz2úcñùZWÅò]]üQ^™ˆluoŠ1:$¤)å.¾ê´—4ÿõ}ØŞÊWş¾‡òşˆƒ:YÍjS)iQ
t¤şJ‰µ¤ön9°HB®æ×åÙÌ+Wd.“w«J–†`IØa£ÿğ•ñÑª-ºnO¿I‰ÌX‡ï@>ñBåÓÓLf.ˆÚ•i––Á¼´$½mÍz{Ç½"sÇ'j3	œ—ADã0âDšvË&É¦	µXH÷Î9úÀİ±)÷èà£«ïÌöÛç0_D>…Í"±á¸§ë¥Æí/’9zº‘Äw 5—“(oÅ©üØfÏºŞmä§×òİä!ŒˆèqÖŸ÷¶¾‡Ï² ñÔyéTMhU SÌùtG/ÿ]ía…
Oîœ[—4mú·FÁì´µjü.ÁE˜İ^n×CÚ>ÊÔeì9HÕ¹ô_ù;hŸKDÙ–;à½[H2’‚Š{¹í½W0Ùx2’>ëtuzÕò@ÁŸûüû¦aÕ­ÍSÕX˜{b}Z‡ˆehQá€¯!I^’Y“-Q‹~òok“AáheÖÚ]„äàÇ¡#ûBÅ‡Ë¤ÑvÏZMkåz.´ï³¸ÓG“¦…s‡ÿN6¹™9\}¢È]-#=ß]®m^! D6…RJB¯\’XU…ó7OÙ#şMÉŸÎËùÀ´qñ­œ$f@ÀA.ÓÑaÅ‡0”éÉldÍ¡¬36c´Ûpèp#6vì»·}Ùg†—èÖÛã1}
)­P"…GæoÕÃõûˆ¸ 7›¾òÁ»“‘¯“WÃ0‘öÜ[OU¸¸¿.Ò#ÔRôı1
Ã×I717“3¾ˆìÁG±¨«}íÛ:U×¿zù_­2'í;úêŒÚjY°Â\åEy|`é÷{)Wè£G©m4màÛŠ°F÷²Ğsu$w‰'IO¬œ­QÌ’mlt‰Móµ4Äâı€ƒÚ™xŞ™4´¨£éPËºzà4˜šÈ¿%OÈnŠ.şƒ$'.ú…Do—xÅk;,Tã·L8´y=Ş³œ¯{„¼‘É:€£¹	÷dú•Ù
Ş€ÃŞìi¹cÇc­_Z›­@¹ÄÀY–A7±Í3öGÿIƒ¤c©	à´å?¯ÿNEİÔ,"ñM¥ÄsÖQ¹h":8¼uYÏü˜ÂM:¾ğn \D’6k±a·Ù6 v°VÅ4µmï*]díÍ¹n°<u>'R{úXmXŞo®Åh•rPhç•7AñxÜo3my¿Èò“Ú/ÊëtB`»qÙ|kÛ´*!ÃœĞË!øgÀkW¬Ñi;ˆ çrÔZ1m«uI•7Ãñ*!æBÕM¼!ˆ;ÿfÏ¢’ˆíéwº^ÿÜ#™;ÿ‰[Ù¼Ég,ÈşÙÌ
È@ÛÖ üÂLŞz7˜[pl­uœiTÇSW˜_Ğ>ú¦%m'g>AV.YJï¤‚Tsı\É(¼;‡Ôí±Œ2¾°ùQT¼UºmÉß„ğésI™t}ƒĞôå	OŒÂƒûÁjÖ­íøE?}za¸%¾h*ÑÑ<ÀC\xÇÉK QVÃ39×É¤G;8T¤Œ>ğ€·ˆÍÑ}9E\†ncW¼~¥²û™±VŒşÄÜ®¿‚ºú ãf>_İµÅ1Æ9…dŒ½ªQU˜.g\±YC´eŒïĞÒ¥ (+ ;*{ıI »ºAa®'•5İÀh´ÍW
1ndØÂC]@O×uW®,=IPUß³ cü_WL-®¿o¨öï†ÁÜì›€ğñ©:­%Ö'èt©"'XòÄ4ì¡®Ì¯¿÷‰°Š=µ»k]²øÀ|;èpBIc=‡n£
<Ä¥W8‘…P>Vçzú—T–W„$Iò—Æ†ñx#ÃnÂZ‚'Ù+>
3­‰ì»í=¥èì²M(ïµjÎÔöTê8ƒ•ÕÖc™Ñ­0pÁ#{S0Ÿ.úì_zJXßÈWB¯¢Gg¶‚)öü&¨>B
‰ÈPyÊ›ü“S=’ò=	îä¿‰Âèé«E1õ(í?Ş#ij‘‚	\¦¾=®×“ƒy]ø31‚µ3ãıXÍËïãøÎûÛzîg ÿÓ{¦FILYÀ0²E¹WsFxŒá˜d+ß/½Ì›Î›U_b'²iŞhé)…Y…œÿÃ‹Ş3ÎâÇs`]îÏY} Ó×=ÈTkÆ/·^¨úŸºÙäoFTxÜ³d{9q¨
Ü«ÕH«ÖÍ´¿IëHÔ*={»AïjÃîÁŞl(í\ş6ù¯(T'–«7Û«,üR¦p$<9¦ƒˆâÚûONª‡Ááj9åÑëŞ…Ã(ÈÌ@‘Ú ´@šG9¤.:„ª_±óuZÛ“ow±tÌ¼›H÷¡jÂf^nlæh+£NMGÍ_ÎâôÜÃÜIn’@Œ0#–EÒ´\Sqú¼MºfÅæ¾Ùï>­Š6ê£GÖKv˜ÕU0›½˜’¾ÂD³´7œBa÷’Ş«dÔ:_[ªªáxíjñæLô«Mèù­Æ€B_ô»Õà;HŒ5§¥„#zÜÁ@7|z¾«*[}uJwfQ†‰GÛy¤Í=yùÎğƒ€Fy5BìF—†ÿäjeS^äFAË3ãÛ¾vÔe„ÙO©ÈT/ô^râİP½¶®DúFÑv®$õ¥)£ÊrÊf»íD3ûÙà^€pË(ûÅM~AÇ €ºÙ®hI¿›bÛ\/·E
²Íó¦ ™ë}XLşñ]:ö1Ò³M 	=³À<"U§xmğà,{Dñ;(µAÇÒÈ%íÄøÕø,ëúX»,‘ÉÕ(çáûÇÁ’,ŸÄÉ…}°b÷«tzkİ|&ÕÔ°Xéyİ¸Ÿ’—5ÄJ—x÷+ß1,XİĞé¤ˆ¢Bï÷‡£˜!«)<©QUØ™*¨Ş”ĞeGã£50µ°Ü´›:‹,*az¸TFm1à‚X«åê=»)šîzvçììÖãĞ‡á5t­xtŞ³Aš m’ÂØ‡Ÿ„‡«§Ãê´ÖÀ5N`—Öj²Lè&hİ$?yëÅã-¡Ûˆ‰G¾­ÊÔ{	»„î’í$—\À¼ißµ†Î;”÷õ}Lâ“Óÿ¥5ä‘Œ)‡>¡yêÓåDWºf¼Œ µ<Ğ/#+Â1ïƒ·DÃsÂÌ\0 Fû‹ë=ŞÀ#VS èıïŸº®NÀcaÎãu­ßyã‡ƒ
±X« U
v9
èÜiû`ÍÁÎÇüÏ®#¢V×–Ú.Õ}‘r—É>@ZÔ¦F@ãÅµR7§!]
¥—åª[eƒ´ÎçVÎüÎt8¶†8÷©Ê¡ÙöÈÜH¬â1×Ö28]T.ì»“‰‹½¼	ó!;"0}„`?rÆŸ57¾}>W/ŞÙ¤¯bÁy“~8‹W0Õ¡õ‘µ [ëXÅ÷ëk““D‚(ÉLJeÈbµú *¯}…[5ş?±5˜2Á_:–G=b~+¥šxQEQq/¢ô—±zUkb¹(s;ÏèÛÒÁ‹¸Ğ§,ó/\/g/J;VcI½wÖìIË}ÀrìwWüK¼÷JÑ2‹^âºN7•¯8xöË„:vÂ¼—ÁÒÙO5ô’w&s`€À">·`„qKÎËZ¬Bƒ¡ÕÛF}
Ël½Ûï7öúhÜQc—·'î2v¢Û§hÎV³{“@y¸F¡~–Su4ğ 	ã\Õ’SKc5rBjërƒĞµÉ®"íCí%üÓ
J¶)M@öo~Ïn7»p–m¦µpåDÕµŠIÍ’\º†ğßîP„ ’„Öµ€)ÉÁß–‘ù?H¸ãVéŠzWXNîLĞ£@Å—@¥Ş_,éõÊ©–KV„ßƒRKä»ÊÄ‹G–U!pİ¤…)g]eP1h©•Æ¸å`qÃ{~ˆÈûâÔ#Ù¿F6(³~‘±xB3k—€ÅŞşÔ"‹léûÚ,Ròçb‡„|ì}ñÄJ	 rîæÓ”¹…,¼?aåv‡ÃH×°ÕÇ­å˜Px®†	šÃ<GŸv”ÿ–ÁôkKT‰;!¹G™Šíé
í$N¼:¨aÏ:aµm‹E°Xc:h*ˆ)úø¿³Ädû0^…¢%)MÍÔZú(Øëƒ)kR!ŠÊñEmr;Ö1[N.G¨€Pd‹O’Æ˜i‹–ùjør?²0ÿ	ÌÿF•}ÚÒ†J—@“§-‚O¬çßé2«š×™­v¶ßLZÿuU“ê¨æÌê†9i’]aö_8±Äå˜ğ›Äöš¢œáŠ?›÷!ñü§õÕ>©C×¨u~óœøCåØğ;_\Â,c¦Êÿü&m|ŠÑGÇ{úÛc’µ¸*ıKJç?K nŸº+¦3ãK‡ş6M–šŸ‡p´ıÕ’®¼5±©Ú °şSMv–Ç&¸¼åº»/Rrx]1xM©u†ÔÿK+ˆØpÁ{&´*Í=^DL'‰g ·|Ü‘n>ö…æÄAê]O´hÙÿ¹xjQé²Áp¨7CæÂ­İÑVÀäM6ñr…iz£µCJÒ¢3ÇAÊÌym•rs®¸V>õÕ#©„X4Úh#ñ†Œ¤*Ñyu‘À{Ÿ©Ä\‰ß$à3¢<òü|é"[o‹»•kÀ™…@'¥Ö“¸È})Uv…Ìrh|q™¢_µ¦îa8axÄHd}V;Û²JQÍ£½ñ‰KŒµŠ„–¶üYGƒ¤^çkœoâU·Ìµ¿°h¾Ñ
ùìû¯bİó1û ‹÷ÓşÔÇFlÊ4Ñ9šKrô­')hÆz£Ÿ~Ïák{OL`€ƒÛhõadW~x£&Ô°6İÛŠ…‰ÎqšìDÒ$£'dõüC-e»ƒ@>şâ;ˆ¤›Aıß| >¦Ğ ?/±÷?ÿkU$¢ätø0uzÅ[è„>•e…ş“÷´äj²31c“ÉëìVa$¥à‚“8!ÏÒĞ‡½ÛÄ(F¤(¦¡Ë™VÈÊ'Ö¡õáÿ¶ø7ÑB ‡êodÓk0ÎO²;óp¼9ƒ»hıÄó²M­½=‡zÇ!,±¾H‘=˜ãØÀh¹cŞê÷Z®ùÕp–ÏìñB¯ÂqøÊØÇ:‚Äó#2q!lµÌ¾ÃJ’çmëÅ¥‚ÉÆ§×<k]öãoejÿHÏéx‚ãó ›bB__Ú¸˜œÛ[LïÎ5Dº_[¦Â²óCàÔT-3zÌ*ô­FHù8ßK*¥çÜÀŸ}3}g	 NÇXÿ·u¸‚eˆ wğË~à€$Ú4§®bB#õäjãjìr“6oj–¯+†ziü&œÀØ³RWH¯µê)ïÿ[œ4ó×²§âW¬?é @€ˆCr5{¡ø/?Î¡]V	`Ôax](4HN:ò6Ñ3äu®W†¤âIm¦t©aˆşº|­xj§XÄªUÅÚş©İÁşKÇ›•Æ9™¥ÆsUL¿JD@ğÑ&I< ÑŸ(ÏF_@6ü&síÿ¬Ê¿ßwä¦~æÏ6«CZ .@úËÏÙ`İºy)ÿßKÃÂ2øÀnx2‰(?*`Âé8>®`ª0 {¿4İ¨ß>‡¬Êd±®›¾màê"¿u¬ù}vD†TÁyf‹˜İ¢qÄqk£.â{.†‡y} w£FBod¿®IğØ²ÉoºßxNÚ§jmäZ"âK?¼eİh+eÉr9«
àƒ‡O›„b­Ô¤#íÈP³ß(TTï¬ş6ğ.Şg6±îñşxÃŒ«ü>ê~5«…Ú×|¶ÂBañM™ß›Ğk3øÆª'îŞ'%(ö|¤p`ö·åí0xÜ#c%¬ï[-Ø™¾Rµa¨>ÓÍ.J½ÄWí}-ŠïÓy`ëƒA;°¾™sİÊêM<zÔs[œƒŠuòqÛòa¤'Œ—Ö†ìƒ)KT]ékuZ¨°×¶³%¦:ÉÀí¶õ	Áá¬za†W‚.§É…9;à×öŒJk<Ki'ˆ™ƒÅ™&/(X¤m—(Z^“øt×ZÚ¯7^˜Â˜åœ¸ô¥R<iŞôTëÑÌŞæ8_Å€Çü˜¨í×¬Â9tàºãNÆ§Sh²íª•¦Š¦e!»†1)²ì~ÄU9JÇpy(t6·éÇä@{'Áï7‘ølêU¾V¹MÌ¦$Uş[oTZË:É¾¦dƒ@]„ä…û6­ÖH@H
ˆÑÏePU0¤A ¸/va~ãÜ4&VÑõßÚá¯–¢	†-ÊJDyåªŞéuˆlÊÓÆ£ìÊ*Åœvi#jOŞ	ì„
£P­b4l‹kNvŞ`tªXÀ.&¬¤<¼õ`fµà&yA»2Ö\–8‘­¶˜[‘_óêŸ'PÀ…Mû‡ïÅ5êşHI0îße¡]aø@î”ßxàlp‡e$”ùg øÍù¿º*A,`L +¾t½	6`%È°Ÿë‰÷ØÉƒRÎõ>É€œ#È£Y³šjoÑÕb±woW 'KÁ›#NrÖrı‹@9™—C †ÎO-¿ë3ÍQ†ô¯Èà,jôQ=5h0}  .®•ú«bVƒôªÇ£¬
— <İ%0{DœÍ@½uK€u<âí:yï¦ä‹c‚h~²Ö¤×if^­Ó†éÁ1¦ÂrƒHĞ zIİÙ®üRn–f•ófşÍƒÅªƒÉñ´Ó˜ü[-ûMµN|}¾îTçÇÈÿXeÚÖ,Ê‹‡véë¹±`¤6ñ3µ‰¢º»Cá—T\%©J7üøğ·N¸çÑå[¥ÃF‹3óFĞdü.š”˜
éõº‹x‘é‰,t‘Åo‹Š—‘¶a†!±ÚZ@MB»œñiZik+Íè²Õx{şÍ¶HŞqIv²¡zw8®Ó.Ä%ƒ¼¡—¨¤ß Ê'Ù_´n¥f²TØîèŒ<§!æ‘äyÑõZğ_Ö?®«?¿Ğ0KšÚ+ßiç6ˆ;›	˜Áî…ùPàcĞ
	%'Ö‡ŞüG¬TÌ7[9Pûº•˜ ´ZtÎ`mÑâÓÜ»6´{‡†’Vè£-=úËòrÏS9õìlÓtp(½/>K¡¦›àGÎ<¶m_‹=õø—KS«qª®V	‚ ".V†pŸÊ¸ªtíÁñP(3£lLÖ6ÿT‚T†Ê]^pP7é´Ú_š/W%¶óüùáÉ¹h¿¥à•7¨ıê)§;‚k&­î¸‹~h:pš¨ùØu25œ9wşŒÆæÇshõ*Z¡<I]¶k‹ŞÏ]FD•(i6²İÃ<`ÌÙƒÿ¦ ãZãĞcü2ï‘Q­vŸÿ¸Z’Î]ã1bí=S…N§œÑCÿ4ÕÂ’y¾ÎS/áN>I}û l¬)4«ß¬ı	’TÁYC@öØù‡ôãlpPZ~•!D_‰4–"ø.åCßûğ­;P´XèÿNÍo7æ³¥â¦ÒÅ,[½—Ù§¤ö¶<n~&–# ?>³AÿÎši¸WdvÕ,LVn®u[%jÌ@çäUè×¨¸F¶‰I«ql@âÂÒœ÷Æ%scm‘¡™\Éƒl~–ü¿¾$)0_bhBˆBå.õ”xé5e›4ÓFbõJ¿œbş'®‡iÏ4zÂ»RÎ¡€£%/‚­æ±l‡l]f´Pı¬ÖQ:-m±>†UE8˜¸Š.$Ë“c]3‚€¼ŞoÓÙsj¼¤©¼R·ÛA.È;¥\°H28—pÁfêz’¸N"Mgì	É ‹˜:ËÊï[où™T« u:n[áÓÃ8?!¶¹B»a+	 ¦ãdÛ·7ë˜ñ6ÚBò9|Íî¬[•šHÀSşâ  Õ<KÎ®Œ-¤E×²æŠÍ¾Ök¤S°iÇ#›ÔòÒY“òUÏH¶2¿wş)]{Àtı£x@S˜’q¢4­¼>ÙÕÌ,¤œgÃÒR…ÊÓ4şöÒ³l­¶ŒÄ>ıßÎ‹uUN‹3µ3ç&÷%©âtµËĞ¹øÆ¤î‘­lUr†ûºÑE§˜®Î“Rªùğ·`âG|/9Qû@R–fWGâÊ½O]Ÿ9@ß¨Íà=Şµ&ú²aš z£i‡À:8rI>™O>İø>qáx_f[{™çü°DI‰†š‹ŠíğÑ{'t¿")ÏxƒĞ}Ly
J¡Q<\„Ô<^zJÈ¸•¤‘ªÏ÷*ÿ÷Ó;e°•õS¯/Œ‰>Y|5¬Ş¹ñ—®ä¬/×®Ÿ‹„¾î°gUNœ«BnnÉ*·!Z4ØV+ÍxTùÆ´îĞA‚¸V‘÷ŞÛ€zR|:xkëÓ–j<|Emä¾„ŒÚxº)äçì+oíb%3H
¾yİ?GzÖ|RÌµ1Ï¢UQ(yĞ2Æe2ø‚æøí€®Ê ¨)&ÂìïÉ‰˜‹>œß™öİdSB¨î4®+g>Ÿ¢nÑã‘T
¦«çdÕûk#4à×Ö’[˜°üÙM&UõôÕ†RÜŸZ C?[s`âBØõ`¸œ—®š›l†í{É™Áş«3Ø÷u¸<¯Ou‡ ³[µe…Ğy³#zM­İ éëÕíÜy«C#?2ôê‰¦ğãiÉÛWyz¥jİ1LÅ£Ròé`´ãHş0o¶ïë.Z:ñn®‘È=":Ç.·©/m\˜àO%Wnhd‚v÷Êòğ}¾j—cÍu-ùm»Ÿ\ú¹ï¶o$¢Ë¼ÿšETE¦ŒdôöÅÚ)ñmxÍêßp¬üdaÍ¢ø¾Oûr°´nl1ÉE )ó‡[6¦	El„è¬‡Gª‹ê`ü­_ Ì×Õˆ¬€íYï–xØ<OÍØ0N¯w¢ÖMûQ}0ÑmiÛ\ ;ŞS¤6Àğ×Æd€y)ñ7p¢Ñi¡—™µ³è]Æu²@¥Ñ÷vœÔ²¸z´½~§­!ğJ6(G–Ÿ_Ó[&º2à÷±ŒÿÆV¤Úp)Ùx^óšDpFÕŒ!üö°*qÈ
¶€Bü}q;¡"}V‡HşûáwÜ_§…ÿa|?‰&êl×%ö´ß–Ê9ÉzïR7´GlAN¸H
°Ä§§ur`åÄ'éÎñİ«¸«á®ÇçÙq!ı”X%,¦œ°ÌŸbØÇ1"–I—‡€r5óÿ}&Öë?W<öwNKSqxŒÎö€Ùœ¬˜bM!Â×—?gTt±H´Ejô¾‡|ÛÚ°%efOAßX¦æg/àğı«Úàñ1XëNàÎz¸“,ØŞ_",.2ßÔkG'gkSı^<:W¥áÇqCo³Ğ'0LÏÄ^†n†anc(¤ÌàåÃœb8ªêÓ
·Ğn«¨õr½ÄŸ@êCŞü#/ïåp‚YÕ~ï™¬ãÈ½ùWÍÂ ±¹×P–´OAÚ¸%"ïËhökU—»şÛ¢Æå;'l8Üå…;zşS•¤‚sê‹N#ãÀ…ÙàüÀ"¶uÉ™¹>2@XñêÇ‘2æºô»£Ù­°±%…3ÌL™ÿÁ3ë’<Dó²	Î·6¿[„Õ
45lå-&z••Ãy™²ÌäA™”mâÿO×Ì/Ag ‹»¡Àñ¦îL D€nCLˆå+ *„¢=õâHœ½zU¼õÂêƒ»iÔıgChv^uÒşõ99ş7eC9V‡“‚8,hŞö¯yR8Jçd ue» ø³Ï¥6<•@vôŞØ8ã©Kz"·3oGÀËø%±}¬-Ç£9–bÊ@©ù¾˜ĞàQ±é8=Ÿ'a™äŸ—†+ü8QÇËİ[¸Âé(L‘ªc8ONÆ#ãJ£dÖùşËn™éƒL'ïs›œaÖz9µ”%ÿ–Ö.êÙ«pR°ZkX0róÉ.şşÄòÀr (%ĞŸ U:ûIÒQHh&güiŸÂ!<„Èg:¹=˜·–®bÄ{gÄšÒä.>@ED}ZExdÍæÒ†„ÚêRÓyÌöÆL¾İkOŒ÷nãoz]SÆú²Ç›£“†¬5* ¬¤b(yM;aèæíBo×ıòãrÏo,åıüy—ºÀí¤oT‡„Öf–JóZ î8gŞÙç­©QQ§âMó8ÒbxMXHÕü‹E
¸
¥Î7â^3mÃ³ĞcÉÕDÕYæëÈê=øÈ1¸¸Ãí,[W­,Şó£¢~Ÿ¾ŠÅ{Ğ3Ÿ?#šwçÎç4¡bW¿SéµùC–ç^›kçö<¨#U°[j.B§JİÁ[‡Ú(º]bçˆ`$ôm%ÅÅ<Úá¡ŠÇ¬»Y].ÓC³º­P~7àı8É®˜Q0D,½æwB
V£RøÇ™Õ_s+Ö´†\
z´k¶ä˜6_æĞã´h·¸³2ôvR½ˆl‘/ïlà½@€\OLÂ ¶ŠÆôMÓ&Rj+W	ğNnÿ˜â¶üh›ëúÈíÉ‹nn,œPÈ¬ÿòîğ„¢jõ»‰.*èoÇoFYJ~îpÇ"Oå7|E-y½–\Âfwp¹…xi4l‰F6EÛƒ¾«P’jˆFÒ=¤¦²ğÖ¼EYH5põ¬guÄ9™`‹l¸+ZÇGU§°/<…¿¹ÿhè¿ë-_k÷OßpD0oöXÊ²6/³Æ»©‹ìGñ/D0{³¥òiœkD¾>·ïÍ¡{ÓÅAÔ &´=ñI&HHU=– ym¬9ø¨fİ<lÑ!®4weĞÅ¨øLV ;³y´	ÇjVOgTG&Ôñ|ìŸ†(È.@şúÍşTË†]dIúÇ©¥MÃ4¦¹#~tgâ!–‚hŸıéÍ%U€ÁyÎ…óêa;ğ‚£‘ÁI>›6ì)l¼6™ò`–ö5Òçš’¸Ú`ŸÊå08ó£½ÈÊâl ’²l#i4õÉqÊ ™ºõ¤q;¿hM€<
0ÙŒz}¤}µ×ËJAq£cN¬•O­ê³ø"Ò.Ê¹}CZ4*Nq\mÑ·P«äÿùX¾«ì~Èª´ÁÌ)]6×5Îç	Áxğ82F)w…t¾²ÖßAzÙºÑ(vÉ1ôŒµ7üA~ë\TÏ¨ˆÈyL}¾WTfäıráÇë<Â‰ÖöÊ¸o‚ô(„ĞªZl<A[Bôy¤˜ãvaŞióE0•¸?Æ¬»[UL}}JÒ«:!¸
¼ıAÕ§=àºæÑ¢óÆòŠ&”vsî=ªbñÄşı+"ïéy®ãà.DİÆ2&5;Å­.Ñ&®ƒ	Å0B‡Œšïû ØÀVG¡(§\ß’­?©æ4eÖ—X]ØÄÉãá €•¾ğµvÔPJ7"j–ã‘R”Ş=•txºzÂÀ&ß.]3€1¤³+ĞAØ#‹KjLFòêˆ…z~?ğ(ÍËç«æ!sü7¬Ô³ãÔÛš‚BO‹ßùì%Š§–¸(” àùÂ	i]¶R›àÍ^ûö²¹r¢7Óò;Œ
1†`r*¼Œ˜ö™ğs*f7‹ÔzŞ#Ò¶É¹Æ*ÛF¨½€ÈÎÜ9İ¸Q“ƒ-Hg_n˜ºŞ7)KùøŸvÇÈ$¥œMbP.IlÄú¡…ƒDR€«À…Îêt»Šı6^ÿ	yÎœ—uÁÌUìºÜûĞnÑ,«¤ìL6ïDIì»§ËM(ZE²@¯É6±¤w!à¹Ğ3²+öû®?¹?Ş®QW†ğF3œ ¿KÉŠÔTŞorÃ£Ô‰¦D!šóœÊŠømØÖ![ı‹¹›Dù˜ÅÉ,ÜÎŒ°©ËV¼º†pŞµmî;³º'm¶¢²½'A!k'â5è,ÆÂlCë.]~L®0ãyhÇñ„Q_ÅhZCÄ{£ÿ6¾×[W“€µ-Ó<‚
d×Ëj( xıñôlÀ=>ùß‡·Ñlh‡ê7 $ëPBˆ»	‘Émv|•ØÇXMs<÷¢¶v§WÖÒb±õK 4íò°+a$†©Ç-gÂ:JİĞ¸>91©´XÓXŠ—nÙk†?êQåÔ4eı-§†Ó&WT÷^İ€Ñ°;¯·ŠÀÄí$B²Ù'‡ÿa#Nµ;Éˆ‹*~ñ©h™Qn8Tvz¢»‹;èx•ô8±¼|WdÔr
ş)ş“å,¶®—¢S2P«ÂµPd\4,ºÍ-r‹Í·ÌzÄU‹åVÑïÕ¸¦r•«WÁ¦„|3´õ¼óÃÔnwFúa¹í.¹Ñğ¡xæpJ£¹ª3.^D!sT¿:Ì1<œ5ïğ/óaññNgNy¨{º,T%½S§Í½®c]”â|çÄ¤IKu/`c‹
XtÖß©ä»˜O­t6ì,Ï¶É_ò|<è-wàòŒyg|¶ƒ k=ƒêµ˜ÓÔøÂ6¬ŸF¬Ô¨A~°=™aÍ„/ûÉ,7Çâ{)
gaáß?’&À¾)l?#Là	¢Šì¾æ¿~—éZD«øÚ†=±x¢0wêİs¹Öü©±í7¥µ*ÔÁ÷¸öyl®JÙ?r°jì³Zü5#´—I(HEÎs²Øx¹,Æ‡JñK óĞğÑçé!—¢´«²“¾:`­î„aop FzDÓ8#w_MA›Ûés[—p2ŠaAÀîvZ¦¢_3{NË÷W(]’# É))å°rÏ²…ï:Ìğs[ô€"ÅEÿß÷WT9xŸjÔT'ûI•",»ax}Ï•ú^ü{ò¸ÿøWus”yqs'í„åã¼™»óN†Õú‹6†¯•oGÁ%Z¢Øl]õœÿğ#³¶Ÿ‡ËßŸç¿×üjëZ)H¨^\†wH¤;~üM´kL\©tÚÃŞ‰{$ò^.VGÓ¥(Œ,ŞÒÉà­ûyrÑÂö×ª¥Mßªe$0ŒÄp³¥ë(³®ÿœyvJ+óÒ¦ü+c¬Pa€ó[äBbƒl‰Iq9Î.+hÊ:À=Çn^îŒ÷©Ÿ²‰²éÏ‹zÙ¸RÑÉBÓV˜¤ù´¼aj1´Bv%3P¦Èç:ÙÄmøÕ@%‘÷{0ó×ü€ô7¸KOÏ£1ÄáÍàP{‡skI|ïXèÇ\\¨¿s@1¶DWìù=¥ÑÊÉyÆ#üªÀÑJhùF®BÃËyDwÖÊâõ‡†Ïw5šH‡*¯Ÿ¨Û÷»£ïA™ëºÛ0£Áó¬ß.rì¿²6.¶ÖîP`çÎÃLc´g„¡Çt<¡“Qää¢vÃu›•ÅªJTf {–;OÚ°ïWÓÄ*pÒ"JÅ…B%ò=€\"TŒ<ºXÁÃ°"yÆ›û R¶1”huÁ½¹Ò›t`ÆvÔF ñF*‡ĞÆ2ß:;	İh@`¯bnP+Û
K×š=ãœ'Ï…ƒÌÒ÷áêH±Üc{1ææsÅ>€¹†*ÙÒéÎ—Œljx¿CRØ`¿ÁÄ:=õæœ~[Cµuy…Ê/Ù¶A:¶¢eöÉ|OQéÁV¼#´]mÎnò;vlª¦ù$§AjäÔ±—iè"wY¾oy©é0î›Ê¾ÈaŸrË£m4 ğŞÁÖıFçzšx„étA-a7F_\Õ€&ë¢œ1ü‹Q„W3Ú‡ÍÑñ~‰åõ7g{Å³³T]­o³¾yòf¿2¹Ó×¹ÊC<ÛDLÆ	"öÕipÍû?ÒU=¶‡ĞA`Â®ïĞrBñ—öàKƒı÷ÆeY›³İ«÷İÍ,ùOy2¯Ø6M	„šØ)5ÏÊ«B! |»>ÉİÓÅ‰24Ğÿ“MS$Mê_Pí®ioVØzgJ=àÈö™4å³kÇxĞ0zzc¹FÈB…¹iázÕÌO[cõZ%åh G¸Ş‡Â´Î`Ó0ÕKtê™PôÿšmyÌ1À„<ë2.zÊOb¶7±9vzeÚkùÀ£³Ï[ÒÌVÌ”ÉÑCæv$GpRĞkÏScôİE¥}Y¯½ù‹KU;¥ÖÓIÊ”TğøNŠ|Œ§~—ÂŞ?a¿±UÄ
²f:Ù® áÅå­Yoÿ»«şgù#‹ıæ|HÍ'…:O‡…öÔM±ªÉ8Áü—äıû+ª-­ıWÚî’C×lïİÁà»Š%\n^„BŞ@;…XHõ{q¦QÑ®¹¤Yƒ¬?c1!Sr¯„JJŞ(ö Ô2¨ (8©ê¤¥Í^ûÓ×ÆäÙ6IÈ¡)c\„„4À²ãôx–œ<½8K=\S,=3oÅïœ†"ò
›bJß°r[TN—”ãVñWW•»µ7ö3NIn1;ŸØâùø;;6îWb#Ç*ma ‹êR	Ç <8FŒIOëî‹ÀD¯Ø&·›ONnË\¼!»
ØÖœrBUÇ¨º¾²®èØ5à¡6°ûÅ<L–/É€hmˆe‘ª†,G#êZ£+OùuS¾H»‰4û5©×–EYNë©ò‡ƒæ[J©IğØÕJ²ü½
€†	hİiÿ?sª[V/ö?mÛôà´÷·D¹Ø¹,×ù–şÊf–×S‚.äŸ‹ç´Üe?3ŒG‡*¯¾İ¶„wY°5êÏØ|°”o9< ×_ŸğYëõÛb—>eÁñ¾»D%¶{£òŸ¢ôô_$áõÅÎy!]T&<ŞOO}6Š/7KêË/û|ÂVİ1)ã#›¢)ğPÜŒU2w–D/ hŒÍşEÈgÚƒYxÂNòÕc§-QO	ŸÁÂ«r¼¹«ûºµISmÄ½ôÅ9³¿éÎÎTV‹M\“¶F0Ö,íŸ]pÖ6Ø¶gWv‹1q›·î6)Ù“ÿI| zŞ¯úH]ª+Ë¸_˜?­ØOÊœY}Ì{àSÍ›Z^1Öüâ°Ï Ğ(²_wdÉ E±I~åqBÇbG<I{¤xµ£Ğ¡ŞDª(”Àîaµ9Äéà…BeÂ¹¶îñJ³LÀ‚šù†…
MDEü—„íl¯Âƒ`¶6–m†‚\.½á’˜I,ë	•j	;e(´ab’‰áQ$uÜD´uÃR­S®éfÎ«"T–#2í9zérÙÓlÌcw.ø¸å‡k1 2¢K—Û;„©fjiªVX÷£ÎÆPÏ@üÖÌØÎì/PÃµÿZ~Jj¾wı>Õ~-Då'óé"¾•şNxÈÀ¶÷ãc6ZkxP†RşŠÖdyZ¶Ôø¸hôè
etVo÷ä¡I‰[ÀÀ‚q{’ïÜ~á1~.÷²¡QŒq	D"^œE<¥HU‚€E¶*‰ÓiKÈ²v¨w;ÕæÜ_”¹ºPzœü€ğ_é/“°Dcöªí¢Ä§ÃaèpÔÍ¼¢‘§áPc ˆÖ¤øÕ*)6<‚VÀĞOÌÁ¤3=Öê ÜAôGñ¦‹¼ºÓH8¶¤’(‹³2˜Úˆ}A}aşs}¨^kØhı›–şíES£s
 ¤ÕËÓµ)œœ°yl®~Ôn*{²0°Ø‹Á['¼ç ·“¶Ì±¦¶#@Äôì|NR37§så‹û•¼‰‚${˜£™Œ”ÉŸã$JÃYøï&qTÙ0ö:yF9„!Cj%RÀsğuà,oJŠáBıº‘°ñöËƒµÓ)fÏ>AˆÚüUø‚²¯Í¼` æ ×x¶\ò² –‚’³²Ù¿Øø0¥Şl{Á4„¿³—TôLñêow5øÒGâÚúğó0XÑú©Ù…¬Ó)Óª‹ßíTCnÈ(ƒ› ¢
ÍŠLV¶óÀù_Ã\kì Rë¤=‹¯~2J×Ğ¨ŠDkx( «Î¢y²e¹‰+ÿ_@zç{¿@L¾w„‹éø("g	 —fÚÚÑVÜàtj”öKµGó†nÙà4üPõ¥Ìÿ\ò›şn_Lh)¿³Êö»5q°"oÜ”ÍÂÄ“7´×á¡LÊy»°r •(‚À™¢ìÀã9”ş+7vhĞ²Ğê@p»9P¥ÂB5Ãû´ˆ	‰¡‚f8¢ŞjNK8,úÿ p\·ÿ_wÒæ§åb;vî¤¾}´5”5²³‘ş:e^B™§6Ë¶o‘ôî¿	qq{$T*}¿õ*°ÿ2»š¡µ(røŒÊ0S4Ä6F¤¿¬„Ê‰/Ñˆäõ9!"ÇÖñ9œMû‡Â:¦€Váe
ç*`d­Sfè­¬
×ë)ÇøJæÇRÈG¦”R±Æ+i¦
ñÂ	Õ×íG¦«‰\-ñJ	7K/æûe¥#˜ÌŞ;lqÊÛâjVú 9(…áĞ oÕƒÕ'|òâx¸ôMPÜ‡å/¡ûUŒzÔK()œš‚E¤\L=!Î–ûÖ×£cÖŠşF~¤²P‚áQµç!(ãş2F`áñ1aÆWIü"¡ª€}xüXBsâ)d×R4xI™ç¬UwÚµ4û$³‘¸ÕJ«8²y$òd,IIùmİç abÈgEˆV?l {5É»LË›°¢UdX"oNm‚Û®¹Ë=œ Ï!MÛÉ#e;Ññ3‰àÊn¶ûÈÇ“|’s	GEZ­›<ƒTˆÍ1¸¶#øÂ÷Qå’€‰§´=9|H5:yÂñƒO ¢¯MÇ×?f“«ŠnbŠtó½Šb_ZÊ4Õ[P¤s‚ˆ19ıŠxâ]™7&*ŒÙ²Ê8ŒÙÎºC6Ø÷Ùø\¾ÄÌ7Kÿ{¿º	Àù¨A?‡7qSô]ê~¶1ìWı€ñÀÁ‰[Š¦V˜ïl8_E|ô=g¬ı²Ì›C1÷×€Ñ_;ÿb³ì½›^úUwöêNa^ÎxÈaƒ
! j§bğbèUW“ãxGG'EfWS¾\Ë`Bøiğ¼¢,:—œ‚mf…1¯4tâªEù%¨Jœ+``âÍ%ÏÂq= êÛš*™Ç¥Ù©kqKĞmÑÅÉfÌ%1€³];¾«]K±^"¤§0)„&ï»,]²µ©£ùÇÜ'q÷¦€W IW‹–Æ²ÜD£ç*WèTP¶Æğ"ìGš¤"XŸ³1¬¾CZ“>ıöşÊ•&…³¯úëñZ7Nwj{V=ö3áú—"ly„q`€Š‰ÇÅ¬ôáêÏä~çô<ŠnM\÷ìÀÄCè«,2á21ŠYªO„c±êi†4>9dã×OU‡Åİu¿ÓzŞ‘ÍèĞÁ¤ˆ§¹5@¸wÖ<‰`î*é<àÄ"c–ªä¡
’³Iª×Û¥ÈİqÜß½´àçÛL¸«ı\e¡#ÉÜRĞZCÍ2s¡ÏĞ\©h'TêLD •şp¼#„-Àšç°x	V±¬×£Löheq»¤ÑG†®](¦»>"Un	]ŒÚşƒ3Öß  Sè@Ş©`Å‹ê2’íN¼Óé7:²ÇL´Ó§¸|VÚh¼c5¬x£WaVÛ”‹Z|$ AA'ÓŸT%õğÆFI‡Ş½Å ˆÍşG‚b¥jqW’ğ·SXs2µy$Ëï‚0úÛÆÃl&Šp¦[Mõ\ÌvÕ”6¿>;ú~™(eú¹F`­0ŸiœŞş3Ñà«XWWjÃx1Îk	jmûz±6Ò$PÀ†ÿ	înG%™„ÍùJ£ ©NPn$=F+&-8œr8VÓµWiHL'‘<b2G)w‹dMQ”—{"×Òõ™µÛË{ÿqâ¤ÆE	zİú k<Réıèæ‘ë"àùSû¡*%LQNmææğ…£‹îùÎKme°VŒIøbó¸z’i–pÀÏvÏ1ÕòRùèŸ®KÛÀ˜)	vÏ“ı0 ·¿\×%öÔ(ZxG˜ˆäşÅ#‚Ä›ß£¯<ÿ+À(Ò‰ ÷¼>s“÷£x±X¢+àÒVªülVéô%DÉ)­dÒ‰àùzMa'ßAÆêR.tL]Î5{'Yóè†bÇ|&1ú‰Yè7všºÕ}eßJné(½“Ğ½ !TûáÅ—›â9‰õDpØ‘ŒÊ»e`ªØ@È'.í9Éç"zªCıäªu6	Şšoí-âß Å¦Ó(÷ëò©óş­¶Jwú’ ®n O¢nc!Š`ˆé(t²éİš\Êßú€Çüò_Y+©<yàã}ç#âª^]ÖÀ0ï”Ùö<E¥•FÏ™nFlŞ0ËZºs©`¹ì±Ş¶\Òİ@‹ÏÅ[AÑ¸XÛ;+Ÿ+fa ¨°ÉH	†ú!œœoªpİÛµzßµí¿?cšw%Ç(}1ï	jqİÿÚÉ¾ãm6rPŠÍFÈ9‚_}ÜĞkÔöşØs|6¢êĞÅ…ãœhm·“Cç)EŸ‡ÅÍDÂúş›Ã‡y\oœä±ãwË×m•nh©bëÀgDóròåZ€‚TH[9eóe€
÷Ëí·½±3¨¬×QjdBã7a»ğ9W©å·~Û$©¦¾4³'¼ÕOœï_àŠìa¦+²-&i•§|¾ÅÑ	$ÑçÅá°˜,4.âb_ú9ìa&[L-`@†tÑŠ)¾1
\†09Ø0£ğİm®µ
±ÅÑR0§ûüÃQ}g~1VhóEcöà[Ş…~¡ñiAK€U˜‘Í(ÃIïÕWt‹œ•>2…9°7uÇŠï¨&Şkv$	G®ù£n@,©G¸íÆ ›jÆúQO›L=0ÑÆ"±_›Ğ]D›/&­ÖPû¤àYòà3ˆÔgd(Ã‹˜æ›9½a‰jÇmöÈ×_‹®â9VË»?ñİ2ƒCˆæñM]¾İ†4
Æğ˜ÀBgü™çìØÍI€u%ÄöqÈaó®2^â®zÌ““gve‡«'öz¹ÃaƒĞKÁ’–Æ™Š^°ZÌìş`N’ëèa.ã¦'1Êùj,ræ¶¶\ÿè" –¡Ç±,åÏˆÅ?~ÄàĞ@‡(z¤«bDÛå¬øœk‰ü„ì‹K±8D­éĞKÜ³Ù+‚Í®u©×½”šß‘ğJüßq{äF˜é  ÓûSR.ÚØöx¾q©­¡ùÜ”é¼“ìªŠ[÷¿ínÄ·+QÔh®UFôÁÈ¼hò,z”Ï¶^@4öl B¤$½ï!-QtïÀ&:Aª®YyÔÕØ9PŒJDq-Ææòmò.]wï3îôy¶P[88üóÕşÜg·ìT³2Sm üæÃûãÃ˜°@É Pôÿ-[vB–6ï½®AVT«µ±ˆé©Ä%Î`y.÷Ó&<û£Z “E™IæãõÚˆ+CN÷ÿ8nuÊvKÊ½&Umù¸:Í0LO€ÑÀÌSsÇMC°øò!òœ#±#–CB`‘o\oò?¯„6`ÈeÀ-ÿFÆ‚Ğá$A@	+jP(beè8lH8û|ù­
Â¡¢£Ó:(x¿~İÊåÓÇ0]Jn àÁÒ¸WCÆÊææ+;4ä²«yy5ù‘8§¤¢Ìé˜Î>D¾M1¡‡¸¥õÆ”ê‘Gr)ÈÕ.+¶Ös÷XQÂÄp¡ÿ´Ìz°jÙÙè}>–:Y}¦´+,¢Tz·4KÒxŠò²šŸ¡¦Î:R@£î#ÿTåJQ±Ğ]“•«kë=½kĞW¹×\òYÇ]+=@Co6L¯vásòãÔ­ñœw«µUJ	tıœäz$@bGÁK”½ã¼ ¹>øQzF¿äf+zûú'~>ÊĞËgu´È‰ø!'©åÏ& ¶aÀÍ¬f©Ì>vVa ]£ÃdÈ#Ÿß=:±¥Á;Ú{lÜÉ&Pğ¥Í¤•‘ro 3,ßp(FW&¨"¢eJ¿Ë=ÊïŞ¹²"Â¶‰-ïÊ²=³æ¡zÿìÀY9÷Î¨ÿ ;õáWm×Ù`^áfÉVy³°BKUöcÜÓEHG!Eës!ZŸ	+È2ùJ¸É|DoòEÅ¬àËµe7Fjÿ?ı´ß½µ:Ìš_Ã¤²Tú„“+¾Ô©ÿ” SÜ¨6“Åø\Õ:J¿#ëş=5½ì•§¾1ïÛ¨ÉN63¤Q`e¨ğòÌË’íŸÏåpUzü§)uèƒ‡:)}Ğ&åî"@“à9²ì¸È¹2[ûëƒĞXÃ°w±¾°°êÂ+~KÓ™¡°§jÇ|Ù÷T‰Iû5iGüÍ„9€/ïºÜ=>
bWE7‚ğ—wêìº>+ñép–¨¢ÈTH¸ş¶±Ñ2"™ÒŒ€¹RÏë«0>º±±JÉŞõİRÙªÉÎ!2È½–àEj¦U9k÷:/ìÒf$Q©ÁV3+L¾?
>m¨CXÀõÎÇ÷ĞzƒáñÓç¦ûÖ…¹¦ŠŒ-õc¤¹.Wô±Kx°‘Z7•>H‰”öwP„
‡ÇZ…r™›ËB´öŒ8so6Ê¥ùÏÍ‰jK¢æw@Ú(²Fkñ8Y9Å)q(Ûb%¡¯ì-¦t
cy:jÙ‚î(1¶´‘ú½xƒÙ4„²³A3m¸o·Ê¬ønmHĞlïÅˆÿÃ"£µ´GÓ4ş+†>òø­{%¦v%”aÖK¦$wrfITy‰cØ%ÉÊ˜uAÎ’§ñ}¨»3AÙ±<Êœ! %c®³‡²}x'*­zK"AlÆÕí×Âk=J NZö2¡eä¸ª¦U%àÓ=·ÕİÙ½ÿÏƒˆ0DQ­3£'nfÉ·âÏ¸Ï16}¤yñ£1à5Ø$Ïâ„ÊuU‘Âš¹‰æßPnt²AÛÔ|‡8yéa>W'„$&…ÉÒ¯ü¡‘±¥50yî@.ûhBÒÄ)ŠAÎM˜w’&Òw¿ˆ8
Œ„µ«˜qé¥ ?«@šÏaš e÷ñ€ˆKsHøk-‰„Òñ¦S0Ú	Û>ÛØÒbãw®ûRdV#*·ÙÈb±Ö5»l°ª7
åNÀŸ4"K‚Ä0ŞöªŸq÷a¡ñãY,šåª«¾Ãƒìldc”[Šò˜0s91‡Èµ¡ÈAÙÍZõÃqÏ\©ÊºÏE
º‹ÈQh9·•ŞÇø°*¹’ ø÷h¼­[áoß´	èVGY-èË‡y¿¼úÇuÂ¯a¦è])¥¤Ú4˜®Š²at í6qòš¶Á_Ğm]•Š³,ÿ÷±~ˆGÙQ~æƒ*´¹- ÎëiE2Gr1šQ"ä¶ıV;~çå}$ÃÍá¤÷Åà?h:¼Ñ$ØÁíËiáÕ¶x”ÛåIY\2Qÿ1‹¨½Ğp·ä÷	ö&¢Õ?#oì•ùo›C¢À\~Ş¡%CÖû`©¯'lùˆ!5²¦UtTŞ–µïóÈê<• ø0g¾Ç	J÷*_ôœb¥h©†ÙÑüCJsUçHÀ´ÖƒLêÊ·¤)zQî˜çÃÌ‰ÌcÜ1c‡k†Îo‚¼Ÿ¯1°Eğ}Nß]}]µ¯àªÏKÁ8ÏŒl©†NI×ooàBœé2NèÁxfaãÄrQ3ª¬wòokW&ªçŞHšå†JÛ
8<3_Ï¡O”¢àY'ÓLÁ­‡ÄšKÉj—v>DbèáOˆÛ”µÇôØÄÙæ`¸U]ú£Wt¨ òLkG‚Gğ«ÃT<Q ³9jB`’Š}–4m`Ò/å29»"pXÏ“®V¯`M R¿,_%%
‘ÚS¦UŸ™Ò©Qñ7Â#°3€Ì(í""ò·:¿ã½_Yş¨zl—VÅUş†™`–‹€¡~ºªDæ76kYRœæ£â zÆÿ/3²e7‚fZÙî~š±…im¸Ø§áe1ÈK1ºHÉ›ÁØ÷ÍòĞrß[ "+ëOv‚è1ï<;VíkÆŒóœõª?ë»Æ”E€Şî8 ±A»øG)UP½ §£‚úÖúèµİW´ ˜vŒ‹É*TpøQ	½¬×rì-ñ…¦®Ùæ¥E<ç:}–Ç4“”Î©ö
…—ûL{™Cî±‹½Òìâ?àLcĞó¿.°Ãæ†iªKÓû§;•©¦R.†D°Š“öağ»Ï¬’¬™Å<­çN¥¬Mä}f„äñŠbÓ\cPEtÜ+¼i×˜×w!İŒ×e;/V2™mQÚïbGwæuá¶ß$fŒtLÖì=h£õq</“VáM×Â¢¸AòpCPí\5k´MJ	iX`Ä)%¬¶›¥«*«9„)>6’İóƒ‰mÍ“]S‚ğwfªŠjÉhÇc
@ÅçÔ%ïP¹m4×†"Í¦€ s~òö4õ^bÄ2î˜ao‰1K7*g¦'QHë='óSù‰p~çĞöÓkÃŞµ@+5#˜İèW6²:KNfø¡ƒ¦-qyöOR#†j¶CMõ¸ûánÓÄOaçL%RŠï»`ay¾ÏB¡˜!U|%BÒåal”Ôsèi›BôŠò%ñ|Òƒ¸­åÑR<¡5×ôè"ÌõŠı6hˆ pOÀ–ÎV0åËŞZçRgêÉ¯ÚŞ\iñe•@3
Äå>Ô¥ã<÷8kÛdÛIl½Oàª!	ıWt.½¹f4‘Ğ_8`Q7kÈCà¨{-|¼4·|ŸÄ¹õ Åò€Ká˜- ÑûõÏÜ
óµJAÙ¿¤4ŸŒ’ÎomT/f‘çïÉÀšé›7>3"À&v“·Ş5ŠãÖ6Qİª¯Ö²<9Ò*(‚rïO`$š[l0®şéì÷ví&—U»É¼‘H)W šŞüò1m¢%Ø||)Ù;W»ìƒ×Äk¸t¯pİäúä§Êèº<»¾G¢±I3^Î$öm38~Ûy?uşLuÇæLenÿµ%¼•˜Â¾ÍV­vlWó‰rUªÒî‹Ñ¿vÚù´ˆo}o(#j/îAQO'È}¸
Û›˜2tl
3MÆ&Ğ¼ŞŸèA¸­Ãö”ĞNJ Ÿ\ÓèóoÓB=Dê'W…6æºìfCÃöŸ¡ƒ°R¼NB-ĞuÃB-ŸiçEw7	¶ÚPêl³ıWOeè ‰—W*dÖ:QmÂ@Ş”]Kbå7V
ˆî1)3®†¦Y2·ƒóù=^â:Aü¹zVr§¤½m
µ×ÚšPY»÷Û5ïàjÀÂA¼Š}NÆ³°x+&0X¾	|Kşa>ò¹ÇÃnøsÍõ2¯î¾•ú£Óÿ²Z`©„8_oÈ¨t¿Š—?ı“Æ×Ò¿$á9r™›–ámD©¦¹`ã<C(÷äSaÌhò¶]’ÊiŞo¥D ¥÷~«nES6}ƒaÁ.*xõN3u'¿X¤<¶]Æ¼){×‰êî9ì¾&¤ieÙ¥	#â›JJ¥nóûà0ÇrEœx6ºd€ÌÅù,’—â2ÛÏTÊ€MÊ>ÿëÛÑ8|Â±ÔJçÇá¾»W4æo*À‡sÙè0Ê°ElıÏ»«®­õCŸM¤íHÑ¤áõ?{†ĞÑY—àVlÒ  ğŠjH#†/nvÙ}V$æ©»"y‘ÖRò÷‚JÉeNt2QèŸ©¾.bKE‹¨DÛ‰õv¡‚s‹9ÅöZ‘°FGgàr Şv¡WğòÕÎ`¼[­}û7ô'š‹¾İ]ózÅ3šİè½¶éè­; #tŒİ+Ç?\˜€0«y8™ˆÖsŸ³…s‘1­±eP”ÛİÃAcƒDh~ùµ‡ïTÌA¡)Âò%È×²C¥ĞÍ|3êŸ0?_`
,ïîûL,+ÿ”×?¸û:_L=m ovãEÚYË¤Ø¶×!¨§~Åd’ÊÎ’Ò$¢­«ñ¨dd»P´Ì¬¹bw£ÿúğ.yPœÆÅ;ŞlØEl5º æ­Z òşâ3áHš‡‹4G3Î¸Ö„q6 ı&½Ô=>œŸñ]91*”Q©é
$eËß|ëÛWØ0õºç¹‹,®ıÚ?%áê½²š&Ås„ €r¿«’Èå¶v74J(€ZìÕÆyã&³¯\5ˆæV…7‘ã˜câ¯P§ÁÇÁŒÚ’åùr¯½ûZ2ØH¾·ÿE&)vDåv
ÑÿM¤^v\ùÙ†„¨š_Œf‰?˜oà½ìV³w‘Œ}ÉRRÛÌp9Æ9¼S÷æ=Wí—5¿ştG AËxÌàÍ"`^£˜1u÷yşdÍ—ôıÒÄ¨–•Z)ĞçŠ'Ê(ÙïÁ+ñ`Ú™àzÀ©ìè²wûÉ')„/_N ¨Ä‰’½’nLû¦W¥>0Z„0åR*ç0´ó~Û©«KmÇÍ	ßzÊ/Ÿ„Ï¯Ê_2trLŒüÓ?v»¾ø´õk¯õ}ò<—ô”“
»;c»_Á{èÖ’}é‘İyRÅœP]{ºëŞİ“GWLïVƒµù"ÔbıˆÚ‚T «§zµm‹ğ‹†yGÎ­0.å¶Æz5rÄ×.­<|öÔ¥bşÃ w†ÖÆ2Ee>œí$øG]ın"W¯ƒ¾²å'÷¡Ò=ÁXÙ¦²d™ŠSİ¬Û¦‹Ä_tq…Ñ\ñ¡vé~Â1…W‡ĞèÛF8¨]İ°ÿÒNE.ÄRŞWÒ©İĞW®ÆÃ?©é)WÏ« °ËX—8o’xŞãjà…şÜ2 61M xP»ÿîŞÖÛ–Õ£Ó;I“i˜*6_¸í8"¸R&ñ;gºÀ¶èZâêú©ıüÍuáÉşNâ,8"|Üş’ŒÖŞèèw‚ùmd¶‹=¶tÀj€GBi^ñXÇ€Œ%¨ :°€m9Ş®Ñ§_×ÇÂF“;ÆË¹N[Ù‡ßXÕ&u¨dc^Ë™yA|¶]@è1qšÁ·ú2‹ÍÔéin¦„ŞÙ›FUÃØ´(-§bü¥ªÉüW“Ø¥Õ™Õq¾ã+FŠÁåf“Ø…‹èrëõœqÜ‰º¯ô.À´Š¢NJeĞ] Ë0Vå•¨»‡w^c-ˆº?+ğƒ÷÷ä:öé²¨™ÂŞä:	s1ÏËĞuäl‚>Õrô:QMÔ¤GÓÅkŞ‹¬ª<dÔ‘?®ÅŒÿÎ¶Ú‹æ´bÚÛY
…Yí*{YºÙ(«t7c„Û|£|*Z3n@-| Vl£]İ½’O0¢8³º
-¥f J?\CÛT­ú>åÕ•ÒÚ$pØ+I¨Á¸|¬²šV9÷R ©heÍœØd¿‘â)hiP˜3eCù8Ö|ÓZ4F³bÃYEQ¤vÛa®}-‰’r™È!­ÄAcr¡Iß@…håy©ÛïRy°ì>íÚÁ“˜®-@aÊ´ÓÖtQ\¢Ş
Æ¯JFL/]QÓ˜yæ´H    õ‘¥ rÏ ƒ¼€À¶iQ‚±Ägû    YZ