#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="70106860"
MD5="3aa159b8d5aa892eaa1dfe67340f960d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23692"
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
	echo Date of packaging: Sun Sep 12 17:01:59 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\K] ¼}•À1Dd]‡Á›PætİD÷G§ÕÛP•1Jë¤7>(Ø%¹ñÄÇa#¬Oydo¤?¹Q1|ärëà5`Fö]†ü$±ıd2›²jUeº=­ÊCµwÙ“R±úõ†4S¬v^0@ƒ¸÷>Åa:ğ9“y$Ş0ïV¡¢$³´C$v`È‰;t
o¹­<)½´Ì`,Ãëg®úªzÒõÕB&ÇX¦‚¡vêfóÿ:€_Î•â„z[Æ%Æ¿T^²X¿áé¨2G\…õ‘³ÁùCQ‰Ò;Ë¥§C£ëKÂ¾Õ5‡ÜRÎàĞÓUrï"J¼jŒà¶&Æj1×doq§s§hùøˆhi¡?Z#¢t
¬d¡‚¨+è™tåú)ë¼ô¼ı<è4HKÈé•ƒA»‡;İ–+(pıÏ:Dÿ;İß”ÆÆc„ınmUo§4I…*iõÌ;;M´Í÷4/äÆhÃ}-¶ä»mz­–%ÚëıÓ4”‚Sp…‚»@É\Tz	3şşŞœl6İ{VópJN§\ ¨‡Fæâ–‰Ø‚°ºgmªt	¡SõĞ,IoÚÁ5­,G~¹}{Q¢ÔÖı×b, J©Äp K!ŠoĞƒqQïã¨Æ¹÷·’NÌèpŒ‡ÌÂGôşPDxR×RÎ¶íÛq¸óKõ]¹âÆ{«@EîĞeÙk›ÙäĞªMÌQ“b+ì^Aš³Ã¿rÂÍ¼e0Ğ ã)O®
í­üS5 ¥Ó=‘MûsímX#¹@bo–
¼Eö„İ\·	µ»ra]‰ v^Q3C—?J>8mİ‰í^ÅR€É²½Äå},È%
üÑã¿4B…??-&P•œ}òV‚œZİƒÑ //LÒU+QÆğiKİÛØã÷¦hù~;ø=Oö4…[±WÒœ¥ÀÊ\¨ gj ïƒÁuÆz,~áŸ[8ãÛ(`HPnR‰ò/ w2ŒeŠ=‚`¢ßn¯-—g|‰ı4¶˜á[©rƒ^Nƒ)%ãá™»ÂhÂ:Ï×ßæKA_#cï•Ãê²%M<`a¥
b.ôz+›ÅÉçè:¸öS
¥{æ2íx!“h‘şò*€rBéî"¤ë(*&8è¦›OaèÅ8aNÙDÔy†3)¨hŠeéL%{µ4åæ¬Ä¯fğµERüØL²‚„1<ÌO«Š¤,Qı‚à%šÓC_?y•,FÒº#zä^ÚÉãPÆ¹+%«T-LIã1û?’Ëbë×€Æ«qeÇ%ò³ÿ#9~z¶;UAQ›Î|{˜ÔP“ı˜âNìÎzh.	Ó×K¼–NIû³M‚}õ½’İN¨V|4M¸|Xë?yÉÌÅ	dCÂRcM÷æåÈ³âçêˆ¶Ì¸I&*ög‚§…‡ç"~öÿ¥²?Ë!Ú9Áò”T­Nˆâ8:P(ŸàUÇ-¼2(Ao;°Z¶!{YÄÇc7?
9åv§[İó"26£S9ˆÉu7¢ÀV¤èS–ä¹Úr‹–)&g‰‰óå\1ØCêlÁÅg…Î)Lô ß;9æù×­=÷„ 6Z¿ÈøéÔ…ËÿXEkû\)1Ì”©Nğ˜)t r`hM2ƒ3Æc–!)}<M¸^1XzaÁrzôÊ}Şpvü	¿İlåm]©°¼”îÆzçP?ûñ†¹8ø®y;+úö˜F×¨»Ò¾:Éwè‰u¸ÌÆ½µïÚıA£¿åIœ‰=µ÷»¾²¬&#üšAâš³=O@Y”JÖ-H\³Az±,í¬*pÈ®éƒG„¼ŸÑiÆÈû­¿‚©ŸvõbË6–ÜœûB-
47‚F¿Õ“Ÿ§-ÔMB;úzJôó{o}ëœR£ñ„ïkzd¹óû_7rVúü¹‘
$_·>ÚÆÂÜ ¼uÛdƒÇƒ9ãì,ñ¥ü"N\g*wT‹¬ià-EÜù™íõI‹X=Šl³ÿÔß7è<\¸ASÉC EÉ¥Ç¼tJ@^Ù«Óo}@!–÷Kí)µY†¤GãB`<Mm
¥s€Ò/%€ƒ“ÎtMqğK¬<ëj &ü³*€UİŸğİéG¼¸– Öp€¢¤·|ˆ3ZÊÍS}&­{H<ÉQˆÂ€9³ş”¡c¨öSÿeíµ¯ğnÒdM7i¯L–Í½y Õ\©êÙ5Fšk†¡ñeÖ[‰«fÂälpG¯b†ÓÇNhdË™Máu˜+–ˆœi`´9*ÛV˜ÿæO˜q{şÄ¼t°x£Ï	«Xw»éC0™EŠ!Üzf/„B–sËÄ2”®z©ò›¥Ä%Ş¿k|¼º(ÜØC,F 1´2“¬…¡îæ7òPz
Ş05³ÃàbÙD^–­èD ‡(e«¦ù.81º
AÃj¥b©r_Ë-ûgfnGˆ´¶ÿPğÆ–™[#ò¬©;W˜d>=¯Ï{r×J·e]tÍE°+ygDšº$µ•&&®,–Çf§:î„zUÃğ#¹f«§oi/êä"8t+(ô|ßÖ¼î(#å!Óó”Á¼­ĞV¼ámÏ*g ¥=AìC”ãsÂÓ/Öô_[xq²¸QèaÚXyN®a_}‹sŸºMä¥ğZ¿HìØ¤Ë¡ıJ4#ÁË Šd82"=ÁøÅ«BòõJŞà¸bî>Hç?ŠºÄÊË€¡/Fj‰À½ª5@–:ò3xµğ¿C640¿b±ØMúõ7%G5¬7NÇ.ÕÊwnYøyİ‡®Sì»d´·ãğˆÜ¸kçM˜yÃæ§²Ë$'@u)up¯Lº’ôRºÖ·†L÷Á"]4ß+^.Âµ•1uÕA‚dìûL:r,­c—"0ÄfZtíó¹÷wÀ§{Ö+IëTût@oÏ­Â•½%¸FE=Ú‚·È§¢ÅÜ×Â7w=_5¢'AfS>&†Ü¸Ën¦Ô”éè´5‰ƒ9ş³kü`ÅyÑÄ Öù-tÔ®Âõ"›CRLL(;gmP¤bD W9üP:FÑsò
˜ŒªKã¢ ‹ÈCe'’“Ó’\ÍÀ/ßM "[™#ŒÁ÷¬¯ãğ[G‚`«¢†Øì©/.P3à€z°7ÇæäT4g±€Õ¿p«Ã®bŠ´C CK¬³ïæ°:„ù”ùOû. A+ßßsÍ>àêqçA!~~½J¸Ñ#èÊñdÇÉä¾Ø‚ËŸıHìJæGÔ!£®'È”×äîzV)4UÅY¾Sâç¨–á<lGçëƒ‘ŸÛÎ…²Ò+v{ğ«µ½3Àïc!âºg°|8²—½‡¬°=øIZ~îDõÆ Ş¸ÌiN‘%Ï{–J»
™2Ö
ùÑ97)õ6DOgM0M×âñ«bmş%]í¢ÂpJ
^\‡£ÖòíÚ*ŒÓ4´æÃ­Î%âüÜ/ó*q”Ïv™„üÍ*@¥ÿOnÉ·ª2íòé”0\J¬´¼:i5PÓ9?‡
KrnÔë ˆÅúÈ…ÂcâÓs½(lô •¼Õ$²~“ æpê…[…téÊŸx½ÃÅâ¢Ow°0½½cÇ·Æ™Åˆ>>.ëšÑ0\ğvY­GªÑ‹²â¬çÄ:;a¹!7yª±ƒ;š_`Ûé›ÍYVøCRÿ)½ß»Wºƒ9‚éÜO^!2 u,)Aø´ğİÿ'Q2ºö#*7¦ÒÿôPvÕæˆÌí»Ğ@ÎâESBñ”×H´;ƒk¼oDSo©Û<‰^Ÿ°˜ï¾ÎoéÇ$8ÄäDNhúd“>.™ğ|Èş'ÙËÔK»øéX]ŒéšÈ‹²ñøsŠö	Q¡ókE—Î,¾­@Õ«é¥Xªè^Åx¾Óş——¤³çÎ-ØbªøóM‘“®ïœ´Nv-µN?†ÀotI¢¾+vÔf£#ø*EôPd¼ËIº½!ÁJß»ßx
šşã92¶BáŸOÌùœúñGøJR—÷#tõÊ&¸,â¹hÜœ3c²j.ü¼çÌ¯İ¶§ïåŸ9¿|#‘%áÿ†häÚX‹ÛÈ:F–¶Ç
	c}‚úß>Z¡ûˆñ(šP©Gàa&^W9éP(U‘‰3Ü†Ù\XÙCòfİÙ:ĞLY"…"cF‘´ÖÈµÄª{’¤ëN’NÔÙR";•0+‡D,? Ã­¼'p^«İ‚iaD¯9{bQ¾ÀuÓL±œäÔï*ŠQ 	mñ@¨{†?_' µà]é–÷µ“óXÖ¥"”S`¹±±N!bG³¿ÅñDõPß‘jÎ ] à´”zSÌ<vLiÁWM—yºİÜ&¿`Á0qá‘à»™}aZ,0[PÕ'=ò®ş–^ 
¥GM›/ÎÈî§”ra‘…‡Ğ÷€útVĞãùÎ<a_ÙŒÎª2˜F”ÒğÕP@Ö©€’ÂMÓùÃ¾òËõ’_®÷__‘Ê,µ»‹ïhêuplMî’³äsG‚Ùˆ"›jlxĞPXHĞpäğÚK”|ÖŒùoÙF)“SèĞ—óO&£L/oÑ›½:šxÓ!l ^qa-º2}Ÿï2jÈCïÑÇN`øçh¨®2­HY…ì´é91Ø|‹è ;[»Y³b8Ñ48Y ûËÄPô4O®´t–QW˜7«š«O°R¹cHFS)3ª`ŸÌÜúÊx:@S™ iÉóAa±øM—Â ¤°#€¬¶zËPCÖë+"ªÑi{1QØÔNY}
ÿÈ@’öih7ë·•Cúø¡Z¬YŸ¸Ó‡)¢“ÖAª{ÿutC0Ç«“‹)A3¥Û‹uäÂ RRÃÏÿ ï¯şğ“ ²ªN—„ ï?l‚üõ¢‰Eöq$Yq½å.ú3ƒ
ıC²îêœ£‰©¯+Ob]H±
á†nÎ@½xaìZ½èXA«¨~f^Ç”ÕÈ…ÉN» s5DÎQ©;ÑEö†^D	>ëÓhgÕªEEš±FõÙ­	X–8×ÚÄ‰4x$RÑûå%/c%Œ„cöÀ½UCË/¸ôpE§¿„
]T2èdYùxÕC ÕaõÊÅ::¤ 7öLša2æW®¬Å-h& Y¢çn,µm·ÏÓ^\»Íè•²©WYcSş ˆrµ#dğU±	>ÅVÙ!M+TO=lWÔÏÙĞ;ù¯†çZgêt_—Ş<ø?ÉŒ†É7ÿøßäé´áó¿²2f8ø‘‡P´8ûA/¦ûKŠæÈ¤£¿Œ¬EÊeÁ,³ÁDU€_ƒ÷ÿJyP1>b—A„ ˜ûòìÔÙ×´‡µ[ƒÒ¶ë˜-£hşblS´ŸÃ?ı—>Áˆ/•±ÏeÎŠÔÀxÖödR8à!>ü­5GIRäGã8âÛ0÷JíÏ€6®f£²ÉÊª«°6ÜYo:ƒÕ|Üs›ğÿ¬õëMA"6hùGõ˜ºÑÈ nT ’}ÄN§Æ…G !Ğ–é)ôå
l—Ğ9W.XYTİÍk ºòĞ,Ù§‰†"&yÜéøßw¥b<i @¸t»Ÿ‰º›ÍYi—9“=‰ß]øÓsßí|dÉìæŠEá(Æ\k‘¡´C[‡‚wpÎk6—aœu!Ruºƒ•Úü.LŸ›• W”ÊäÊõ"cò·Ğ¨Ş+¹VÛúö¦à–Ô×Sz§Áæá”ïÆ½gåõõ¦~+N„)ÊÜ°wW.9éñĞì¢ã²¶İl^ó>™;º®•@é¬‚.¬ók±u„šŒùN‘zèsÑP+Ñ'Ÿ”¯(‡sĞıt°%&@ã_ÆWq›Vœ¼eª”ç—Èbğâ;÷q/q/Øqıõãø*$å¨È'¸¿ZkZ"ib³(gUÿ¶1$†Ô+Ù†P_fî=ŸÖŠšË!J­çøqÁéä ¦”&ı9œYşÓ`.›n¬1ÀBÇÅÇÄÎeÜú–=PFãa‰uzûÍ|”äğÍÀõ¿œ;-ry3q×Á<¾Ú]Lšz<ãğ?¨©·¾¯"mBš€Ps‡¾[;»=şkAû |"ÎQ5 ’2ë¥~0(Ú*+{}¼(iÍpÑQ“.f±T¿ Çò+ª³z­ˆË[7ô•ì_ì+i=ÅtF,cğsî >8´=;q\ŠX‘1H›Ã²A¾æ#Óï‚!ZšMZì5 Û±^Ÿ„&zı?ù:ãş9Ú$)I¡À{é›æşeaòâáXµnéˆ*E‘6yAÚ+÷ï+qŸ€¯ÑÏ­H
5õ=ÜÀæ|I¿È)<f­7Úµ±ÇkU|×ö~õƒ·J¼5İß‰êÂü«ÏoíáNq”Y¢W.•ƒuÍÉ²»XfC,+×Ÿ{ŒÈ_z¥ÓT±Ât¤Şğà¢HeÚş©†Ò-Ø6¶ïŠmÓ–5ñJUœq­¡dyı¦;A4ıqß …O/pŒFğNŸØRòOVºƒòcÃå'€çŞaâ%'íŸ°‚NÛçĞµRá±’ß¶#¿pä›½2°Ük
’İnJnç®ìZ ¥$àë×e&LNØ1¶´Œ–i‘HEŒòğ0Í´ä˜§4/¤ˆœw‹[¸EÁT=y¸2mãm–şß”bñMKSBsè¥“T"tğ-ÑÉ›—`ÎP÷DÖ‰	„…/ê¤Š#Qü2ñû¯3£%)\B¡/=¨Ö R…DªQE[ÿ˜¢!•lêîà'gj	Îëı*’@ÂTç7Âf‘×ÌÕâšq©fÿ	í•/¨¼:ºäìü8\mU¥Bš:ó}ÃsöK¨W¤ô#àiGKKıf¢G=è,è-gı8EEğt£µ»^†®Êı3¤Ô 	NbµÏtY&ÁÓIg-^<P­Ü-?“™rjQê¥5W0}ŒÒÂX“§ègÌäAâ;9£İ<G,F™¬b5kõ2êóÚ™óË)Ó&‹w0<Ü²ğrÀéaPêô¬U´æ„Ñ–çÄsYñQ(Òµ©ÓóL†§K§ dò–œ¸ëóXú©ïœ|g•Ÿv|R¨áH³ÒØÉ[´ =J?8N[I´¡sá÷Uğ¿kxŒu÷$’ŸÙ	¾ÎBµ7ƒ”/×*_ò>±µ=L¼B«QÆ ¨\’‚;ùœ?³vÇ”Ç÷°ğ\œ×êV7l¦ïî×Ã¬q­­tk_®ÃR‹©#BœRU6æûxÛ±†Ô6æŠ›d‡UUÛ3+9Ã`ÍÖ.ËÔyÍP½£ş1ŒUÙ`ª#Aò£jrÛFÛhwVi¨?'4Æh.ö£†kY¦-‘yvÛV"zgğAË 4…]
”tÄ\+>§1d¾ŞÍà\$0µ “»g—¤î«¢Qå¦ÕˆœÊlˆ@Şe!Z<H;!˜9 ƒÕ£n£»7?™Âåï‰:±z-F¼Ç‹ &¹†V§1*ñB=Ùšf9“ÒÜå‹t¯Aì;Ì}5yÄÎÏº´ûÏ`äÇâªã_l³“!÷Æu2ÚFK]02ó¼Ğ*3ŸĞÆ4INÃ\C°ŠK¦ÔŒ€´ıfB\½Vƒ«ÄN!ìT€S›­‰)RÊu½QdÁ’¯SOÍêX;9~Í$tôMjğP5SC´¢Û¡E±NÌÚ7áäå–E­ÅgÍq#r|µMÚeg\ŞV-OååÓ¼<”g{ÿe¿™PkÔt aäZ6rJˆŸ0UQ~aíè…Ş¸Ğ!†©$KôÁÉs£„|S£d€<™¸O7µ¢ÔAÉÛ±:ïı.:†vdÆ©ûT¬4'r
Yóöaáxí÷h,èî1şHzÂÄnpÕ÷ğÊnÜ}Ê›ÀÆµzĞ¼Ş¿¤ßíPŸ\®ÎèË¸}án­ƒñŸøPF ñÆ„ÔDÍ)¡§·O.€‘aêu,\Ü½qìR±†õRC²Ò‘fÄËÒÜÒ€ñ*ùûªÈİK"†Öô³t	.½,¦t+kM{r€“Hyµ_5´âÁ50# ¼mé*Ñt{Ş0Õ°}‹XG?}³ûN¢ãd‰å±€D½6^æ:øT[Üd¢eRP{™ì&š¸0‚Ïj€r°éÊø·i‡éYãç ¥Ï#ÿR	Lô‚u"’Ïe…»áxrÎ^ÊD¢–e:İ‡Bƒ?9İÒnˆ1pS¡-5g]/ñJÌ›³X=×g ÷³¦Ë³. ·àÆiÔ‹KDßû’å¨ÙMõ`|©A×ÂH¡DXàÅº%Ù7ã•–ä0»è(Q¾’AÈÂÒMğ"‚T”¦Ü‘!Çc±±ÚS‹iˆÓÆµµÉ‚<6¡»dîf9«mXµò&¸~½PŸÛÂ‚nİÙzíÑèÿ%¨±·‡…†}ğzÚ #÷¿Ç¯ ‰X™=8†fEšœtd<æÈFÍ¢~Cãj:Hmœ);7{l½›îhÒ—è6Ä"Œã‘ƒÇr©ª|°1§‰ÿ™Üb¥}&ÂÕ}Ùïš6%LÆù­°äÃĞV;¾È¦³
îJ×sø¤ŞÈ¬|Óªï<i½C¿ZÌ9„İ¡°ÑC€ür6LöèK·ò¹Óšqäó”®³'âM0´v"(¿ŒçÑ^Èü3è):MOU¬ëÈ`ìº‘ŸH²—H
.aHÖ'i_¼]ÿ[?ƒ¾3ôµ_ÁZÚè¤«˜kc¢Pü¨è#Û¾1š–´ŒOĞçŸeÛøËy³L¼¸NnÛpÑJÇ/Kª{ö¶ˆ{Ìå]m³¶ùŠì›• 7ŞÙUKøÇì:„<ÁGƒ
N_®ğ™9 †=Hr1kA¦òpšÀ¬ä˜å^Ş3+øñÌ÷ÏñØÑÛİœG´í+¦I,a…å‹´Bâ\´³.ÁEÄ€<qı„'šœHöÜPŠ:¨›‰Hgß”÷<‘f'ïª…¢’ç3iŸÇTvd‡>%Cf²©ı®PÏfs®.~àçDÛÇq“±¿N§¡I»3ƒÿZ,‰Ö³Ÿ—‚¤ÁmEŞqõRÍ<;ÛşŒZ` ÆfŞ\¦0á‚ˆ™`½–«ìV¦yùgFÍ±=P{,Ñö¥.%íÅ:IÊ­jORü	5“\(@xW-÷±–pÁ
>máhÈ¡!TÙsWÚ¯AŠÍV{0oA´ë÷œQã‹^WL«„w{I¡oË"@cM×ÆX
u^Ò\÷˜%åó¨4&#?Š(6µ@'øÔ‡ÊAãı?V»5€Îú?d¢tÔ,¹²[™ö¾•ÂW8M½÷úñÙş 6£Yn›8/Ë¿y“ÿ|¼¨ãÒ((­±I2Lİü×]ŒÆá×îãksãM°X+%	KMšúí0İ'+
„Ñ7T`Ùeo}¥XV!plSßX…r¬©ïOvò_0|£¤¾%•Ä'“mÓ'¹o4À9$f(÷ĞÔ»
4§ÓÄÕÖ	vbiY/º×/\;Iƒ ËŠ+*Ö<Æ&O½À^[KOf{h2Ş’p÷"‰×¡ø¢§l@%0×wœ3{
ˆ¤òYc€‹Üo«W!æ{âPìÃ	—‡NF-X¬¼Ì¡Cñ{Ç£ì€™ÁŞÆ}¸´Ô‹£ñİú´E»(LR
t]ÙcV´¶ê8|(³òiŞ"	pƒpÌùA˜‚_KÿMåÙÆ(iÿÄÃ•
í„9…Eçñ‘r_°_N¿­5à’àšÕm•ÈçËÔNÈA{=â8×ñÊ 2™~ƒŠ^gØfèGÓNµÁàÁÁ9*›¯#=©v\) ¶}“s†>dîLÈÈŞ§MÕJ°k2Dç½Î$m%2Õ~@IÖé*óWÂçFd'šNbø:“]êâà*L6¦7Ü¼Ğ}Ù¨íºxÒ$(çè¶;(fšuóÊa·#K§i&û'ñ_YT®w[£Å›ñª¦ì5{gÄ7ÿÆ~,ĞsyIlFÛŸsTÑÊ‚d¢ÙsE‘KñOÁÍŸÚ_íÿC·ÂqBGÌ•2±[ñ³œ½èÃıÜ§vF’a‡FN¬}Á‚VpÑÖÕ„ešy.†“ĞµÁ°ª[ruñ€
8Wšlaô±ä€yÓ{§åâÎ÷€rC PôK¬ï8¼Á/._‚ô0Ë±˜ìã»˜HétşÛ/¡‡#OGà …m*Â)(Ÿ¼Š¾ÕTmÀ¯Iµa”`¤ÉW¸	ÆÙºh¾Äêğ‰rĞ6ãaÒß—6iİwßë!i‡núÓ}¯}Pá;ÖáIin¬s®D6j‰yèïç¯ñ&.¾0v³†¤w7<¶!Ó~K•á«¶ÕO¿Ş¸_ÇîÓ—Kû&Uäa›#øZ§€òf¥±´ŒJ!›?4@<FVÆöWÏ ä]$î£cÒ¨2ägUÕuÌ=Ë”/"ıf‘­´í9y¤R÷æƒ§o6^-UĞ}³§âÚMq¼˜(µDŞÛßø6!©½[eÊë–çgí$|ÙÙØ]4(*)OŒ6Z*h?ú0à8w0[È¤æ•yí¾óu`yI¾â~Œf*aUÀµš÷‹Õà²L	k¬úôQ_#¡¿(¶8m¨İœV(ôœãhŠ™ğ\VÜµ¬‡Èj”;ç4êÕXÕxôö“N	¡øâ+?’&®ÕŸ’'5İ—ª[V*–ã™OBTáoh·šÜ»²”ê1–Xè1”Kù—Ü(-¤O_/yĞ¤ö¡Ñ°ªM?™8õ‰ºTéñù;uTâëéÅÜ{Êë¶+™\6@@Ò(»/:vzµCq_|¶tŸœÊ«¿Ñ¼+é/]°·[9µ·húÇ–©ƒ‡¥Q$è¥‹W·)¯9/ Ò¢œëkØ»‚ßNãÈÎã”(Ú’%Ô>;mË(Ó,”I¯½ñY2-æP³‹+E÷òô ìÊƒşzJõfCx¦8k¨™ÆV~î[Ê26öùvS¹ğjİÁ	î\!¹È¹0+D~IŒQçêÌæVÄ5%p§d| '"rIfÀÄÎş°©´©°*Y JM!7¶‰Œi(ÅÊìXFD¢ª©{¨¯
õğ¡Lˆué‰0ŞÈ?û’ƒ]î5§^Uõ!èûƒP*ìè\ú¤ÒĞ¢¤)„% F'B&msíx¨p-S·òahøÉ½ÂÆkİr<Ÿ/Õ6¢xÙ¤!h]Qm¬¶çlÿ‹e{LYâĞb&˜Ÿ¤·	iüù\²ÉOùl %)@¾©5õòKÄhÈÅ:†Â3…—mrşö
’VF[ô/ö7€	ÚÓØ<Dn³é .tƒ¡kmN$³n4G»Zä ËÎ©Ä¸Œ¥%\öÊ±¦°V“âc´ .Àü£Y£è»³¨YòÜîêåXàú%s©4È!Æı"KØÁ,îlø„ruY%t„‘Şo6‹w@ØLÀ¿*¾)"ECõiDµÇ~®µó£«ê°å›.Ö©dÑØzòPƒ±³ryÁO>?‚lˆ¯coÌÀÌÑÄlÖCVÆtã|n¸ó#Û¢’kFQ=ëa¯rsöÏrä®ú7aÑZ„$^İgÏS&|ŒwpT—ßˆ£n„æ§ß„o¤Ï¢RKËw¯¸^}ÏÌô†*ÿÆù~8&ì %ÿS‚/şÇÂòÂÎ|a¬B,=Bj³Ùx%óp¹}úDƒ“j¶é [Ïv¾<í±Š§À©š_¸pLéL¦8@·0üŒl-X¸™5>Ó¢¼ñ§"^'™e¯›štØòªìÔ‹FEÿ‹'Áº3¥IEr™¢Ÿjò<¥pé]XÍaKà+›lô²™Õs†dĞ¨•ŒcnÁOq¿f¢õ£$åH~8YåYNÒÎ¬¶Z*ÌL¹àÛùº’>E5V¤Ö!šÁå®¹\éj¾ÉT'È«°5§†n;ê¼DÒ­ş?.UD ³KòyÙÃ}‚ò%Hõ¨w]c±cõ`_ù–™„ÒÃ![a_]¦îõ;TMe¤ü¢û¹9G%0ˆe!òV¸î=*2‡”ü	.Oúø»k§Ù9s!ÔŠƒ3™ş, ®yèú·èÄóU~¡{œ^åê	|1H§¸€?¾:Úûò)P™âÉr/Í¤Óùôÿµ¨#¿ØÖõ½Q·‡,b:ö\ø¸7N€ÀV3¥§(¡ß\µsÛóÀ%š;îík$é/gàiÙìÁ3×HCDÊrúL:SºşÖiø°Ñ”#~mÌÍ#ì¼öÀ”65G	tibÁï¢DËÈq°K¾å°.– ÃÄ+7Ê}¿dÒfÜkÿÿ¾ŞêÆŞÊ÷Å­¤„<ÀX¤Ì›š=ÓÇX?A£~H¥Äúîsáa0JÑôo'Ç…wOÜ|F1%Ô÷›œÑı<åWrü¹´`‹µöc	¯„ñs(ãft€–Ìİ¨¿jqêï‘w<,O)	Ëº—­ı^àƒP¹vOP–ª#Ç«Ÿ¤zâ¸Ê8F'}Ó)‚¾­`m˜I	KË™ª’Ê“’£‡rËŠJğ)P˜çV†–[ÜïÖ1/#N‰<?£–ÂNĞ¨¼¼Ş=ÜŸø–bC«gz\‚©Úhq
4ø.z›‘­4Òtˆ²
¾²¾òpŸS†!ù÷6)¼ù¸mæ6~ÕOl,ÈşÌ†0+å[ï¼ì’ñLË¬­p@Û1$å°xvµÖ+mğY.éˆ©zFTl£9vÕ	=Ó“³áİ·¯RÆÙÎŒªÑJWNaˆE°2á¨ıÄx	sx_¤s0¿ß-KĞÁıİÉ—	• T6ãXup8ÆÇ,NeÁ£6p©æ²ıSx¹ô“8«ætõÌ5ví¹™Ğ×SºÏ¡Æ˜(+YF>ŠÇÓËó	ĞÊÂmFL4]²ßãAšßÂKRÆ€Ï´á!`ÅU|f:/ÙÅ|¢jP„\Ş»PÃÙ‰dcö435Ï²f»£XÓ­5¿Äßİû‡°íÙâˆé7Â¯çlß5©TßƒÃåÅĞ#×ÒşâÓÈñ,“¼Š:Sºz†Dé®ˆÆ¬G;€u¥€fÆÕî“õ¥¡„‘Ã_š¼à¿|6ô—o¿R<&”‹¨3êKáËIyÔ&C8âYN']sË‰·¢y--TÙp‘’Ğxú½@:Â¹XU?Ğ‚ùgNÅ Ó+îŠ5û¬“1NúÜÎmj‚¢o–J/[ı!AÕ)ÜÈ(­Gj=à	ÃÂ¹îv<¶Ö>íï·ó0R:(úÌ.=˜®usiU•V=†´›û9Ú(œÛ`^Ë}BÁvØºµ	PXb±¤zÄîa}Æ½´Ùì®ì­”ïKŸZ'œ)š»t:f¼*’„ˆ‡3ƒ.Ïõ·öåOiµ¯¶EœTã‚yÚ«Ş"lëş¾q%m¦:¯uO¦á#úá˜ºİÚ½§htÎÌŞ66¶M }<ûıq§-ñ“mÍ+åteê_4.çYC8'õô2n·-¨×PQ¾3œ{p -ßcÜ¿ªY«VÈ"…¶³ãO¥¹‚	2‹	ŸtœA@¸kÇeÙ‡†U_/~¹(¡·uû´£8-¬n«‰^`Ù»+bƒÕâÎÍ'±"<ÚO=ÂÂp«õi‘ÃÿùÖÍô ßÇüÁZËT‡ ò_j-:@_¹êóĞó¼újb~âªh®¿„ÈÁÕè¸DkA7ûÛØ7ÈÀ°“L¬÷“üöÌ ô™0åh¬tQ•rğèÃ¦ 7'=²‰o–[üo/Cf®&K¥Şvt˜¢ógW00àpOHôíújv¿İQŸF'²â3ÍÙ¸A©CŠï*³ ^ñuoù‚ı¥C¥ :¦˜DSJXlH1É½4•o‘şÎè2=¬N÷q·"À'–P=Ê•¤¼k~ÇL§~Ãş˜­óQ-$†fü·Sè7=ÜRz[°ÜŸE%K§ÇdF‚ùÖmq‰Fğà\OË‰Š´öÃo”»r:÷÷ô9e“ÿIœÇû,Ú3‰¯3»JCZ0%§š‚˜äíƒùÙyÊ6È`şÔz‘q¼Ã7ìĞÄıMÂ\6õÒñÂ³$¼ŞÓU0Ò[ÌšÑ¹@J¼®m–ˆ«¥£`*K®êSr¼7ÍÔ+ÎëÖ©ÉÙN*î¨ß9‚p¿Ú(ƒfWmZ!yŒGõ2 ­·NV˜ğÀ+ÏÒU°ŒŠúÜÓz‰ÀjB¼‚úœB”¼N~\.exŞê?™ñ‘Pd *5˜ƒ¥'¨H!ÁÒ5Á½êå–ğS}+	b/§è‰äf*ço×ó\D-CtœÓº¦Œ›şzmCøÆ‰{¸È)P×‰<x•›@“×O$™«…l‚¢o×ÂtAgZÔE`»ØŸÑé>à¢°Y±dÚFFTuà`
Äxe¶™î/‰íT2ózÜCT¦x‘#Ì—R¹ùÈÑl¹´i`qPW/]WBœít¡:ÈM'Ië,c^o,t±k’#'ŠT¿àË>vz«eR(^yÚ:fQÄ©iËmJ3ØQ /ÒW¦õ×¥?ÿZ%÷ĞòåY,§½ãhúæááYÅ)²V«n(DÕwÑWš¨µƒîQÍ©Š’ıÍïoh†¿‹’+q¾ôGï®&f^€ÄºÃ)]êå“İ±¾q¾ÜJ'¼ ¦}ã—®Â Íg¤t® N«¾†ò[¹Å]<´É|1yï
t­†Áˆçğã¬Æõo cÍ7_#õ˜ZŞhö´G4Úª¾İRO;ë.ãL¶·³1Y80s®uÀË
ê-W•^AËL[`¶à¤}¹±nŞëØ§1—™ıj˜ú‹é¹ÉÔî‰Á(^Âõ7É©^ûƒhı¬Ñ„Z´¼¿9	ÆxNòsÄM¢%«=6“ªJ/}í?qˆÚZ½ ›F;•Új1
›³OÑQİ†Ÿ z³
‚i:7‚å«ğÄ¨ì?±4˜Á¥K)ŒÅâ»yx;Qég#©îz‡âš`Ì´ş?~U-­¤)I¨‰YÜRå:ÛÛœÃ¦f¬v”`à&LCR¸—ğ¨½x8ßXüÅÚ…^½ÉìvI!‚ÉCá¶Œ?O7ì²'1ú#ÏIÑÑŸ'F¡™«	ğÅ œzáÏ_cÊT$‘øÇuÙš³ßhJ—ZÁ]Ì`=hTsZ³Yaø3ª
Ø€=° vĞ²Ùıf lóE«9VÎ²	ZK¹Ão*$4è«ü•ÿÚ¨ıªX­ß>°`ˆC[–¿>§şsëf¨ØÄ[XµırÀG®¨ts.	6åtİ "I»®B#ov,j.7ˆ©Ka±•Ã3»Ğ4³ßí_^ù`&Q{Ìºö'Ñ7É®-:#Xëj†Óû`»‚­|h˜tµ½R¶™7Â–L¾LÏ…ifÒœ.MÑé™YªöÚR°C!ªETMÁc ÌyK3 t6
á€­cÉ„ZˆòğuJ¿PşMc’I›]ÑH»‚ó²¬}§L8Ñ5ğgL,[ˆı:9µ‹Ôy!ÑçŠŞÒµƒ1•Vu{ødµW£!ïáó”'º…¨Ò¥CúNQŸÓ£š²’ûˆè³d „áSÜæ#ªõ—;.(ëèìÙgeİÜ Ya.^ÁçaÔv¼©‰&$ãÛì¡ÿ"Ÿ×~8¡¬rcm½g™‚tµìÑ©® Ó°±¦°Vc6™.•}áû7ÿ„j°Ğ< ÿ’S
ºL¡°¢×.Pô ¸v~xz¬”fV%nÃ¦îWÙvó?š¡Çš1"<w˜&EŞR<xdŒV­Øud@ŒÖßjÅQúK:M¹¢VùJÛ÷†²D¯!,ls£;Ç JÌÎbR(öÅND¨Ş›ö¨ßL2µ:/ÙŞ¨øPK`Üe(eÙá0b¡ò~@5CÆâL2Ï¹·‚›]ÕšÌÜ8íú2!ŠôèÎm¾õ1B»ˆ˜Q„µ7*ŠelhİTÜğ¹.Dª‰séÀ£íè›¼_9ÒGøúÒâ…øç\´0™ªÁúB„Uı¦B†³í;°îm¦oÕÆjU¼ë":foº­^Eğ¾ê	]òÍn;ÿ›ÿ9ô_ÍãoãJÅáÛW±òoJ9ÎX7¹pÅ]3ğè—Ì¿c8	B*‘‘.B=ß:®w÷øÄVyçµÅ¦WøÇ¦²òï›Ò†Òéx—ñvâÊL“ù–uÈèí!ÁâPR´†ê#ppÎj…è¹KbÀ
=C}+f“¥9D{¬´:£û[uĞ½xyKHôØ¬ö}‚[É;ÈS}oMÇşñ‡g†ÃŞ6zˆwc}Ö§ãQ ã ‹,ò†§&İñëlª½P¨Tª=°-B-5üGÛİK†7Ó‚-:¬U×EÎÛp#e³sÊ5¦ø?–ÿá¾îÖŠÛÃ¦ü;tC œ2— â¦„ºE¡0®oàÕ¢PÍ·œ@eu¤Û8¸ÅÒq¼¸X&cÊ±elÚÛhZ/•æÓB)ìSs¿Å‚|ió4kÈÖŞ#µÈ^ó ‡©H®ùWÃÇ<1efoÓ§ õ¯`îVò*l™z]`…È6ÏÈ»ÿä@)¨­™î¼ƒ˜æ5Õc?bt²ùi¡‹% ‰.÷égFeJÿ“ßHû r¯@ãQOü|ô"×‹Ğù?¬d“bBY+E2Â_f*LUŠ~š©n¯ê8Â9I‚öùïÛ„IEÕ¸Ù¸‘ÂÊt@"	O¹åYØT²…7ÒÓzÍË¸knŠÉ<ğÆn*QKğÎ¿wxÀ³¨º®Y1–ÄSñH2gÀÍ
ãáÔğü²æÏëÛ#IQT1I•m%Q]Qi“nç0©F¯0/~LÁ1¦)û Ôëy=Î«›	µ]0_Ğ!Š¨ä‡¸ÛÉ©øaSåÚ&ù2\ü¸AMİ
5¹FíŞjPmU.’µ­Ù‘‘ø‹›ú¡‹{>úòÖÛÙ"cŒˆïÜÎS;>I±	SWLÃ3ÜkÌ|8·´ëâ|‰ØÜ0TsµP¯àdÏÃª¥äÃ+éPÍHä;|LcMéCk¬ºCÏuûª´Æ…|´ê‹o¶ ŠF²=rZyåˆmÓ,ä®«
E³Ü"DXœ"öh„:œ‹jÎò1Üå}o*œeİW•lr=JYÂ ‚)Óõæöİî2‘=j¬Êƒ›cQ‹9Ã½ú³·á¥Š_‚š*hõ¨ìlw›X´Š(x'û‚Dê š!†wÛöu×•I†jì°;QÔvçQ°ñÅfÿq¯ğ(òåá“&.Ü×’V‚ƒG-Õ“šÒ#w5˜aÄh´Ğq*
	®†K±äiMÄtÙTŞÄf1©Ç³>2¦UU wuôı 8·r¦ïOƒQ÷g¢#Cl«zÒ«üÁ•÷=“cŸÀQO ÁŒ>¶3ãGb-~t/2SZ’usÚÑDmÙ*¸Mı–x÷"“dŠÍ6ÕÒ\jÎô6æ(.Kç»BŸØ9ÜUæ›Üˆ²¡“ËiéÔ4GIbîsüû›2OVß‘Æ«
'O(]bÉœdÆôWçŠ´®òè¥·ó,}Ú®$å~ˆ0™uûè©Cì¾
nÈ„£ë¶Tnï•Šj¢í•é8å*•sShCt™–€fIŠ0VäíD!”²‰üã5ÉŠ‚>H¿‹:·ZÔ@»‹œìZD )nÚ`1b[óW£0AiI!GJ,6îöO€ªo¨L,ãÚ9Ö(ƒ&‘"2Øñ³ü»¾Äë×­@?œmb½zR-t0óôK·0z%\+ã÷È¾/ªXÖŸRQ©j#¡Œ2Å“¤‘É8D<Ë?	eìL;Õ˜‹°t}Y2Û&eğÁ[ù/‹ÂÍÒ‡%úÎ1tİ¢Lé0T'ónd¶&‚‹PÒccy7gâİ«xwÀ¬1R»Ò÷üs©7µ;ç0›´]d„iÑmèag£Ù0pbáWº‹6{R½¹»K³¤µew¶Ÿï®• ¡[zdì`ÿaÆ^g"É)¦º*øFİ4Ò÷ç†şq@³‚¢3•Ëà6ñ:éX-ÛÄğ’’N[mÑõQÒ2Lñ„ò»ÑRİ@‹‰¾8‹•³ˆÚÌY•ÂÈLAúr˜b®Œhl‘Ô,—ƒ: Ü÷¡0½"òp
âh€Ü³w@LóXVµáklàM”à¡nşU«Ù©«;/‡që×£Ğ"aó$ö"å^
>éü»Ü´ë,8^ÃJ&˜P¬µYñáø	¸úÅ2¤!lôŠµúòùü\°Ÿr0hãàhJ¸z·XSgÕöQ7âäWä¬O0Û„NPÙRìä"2Ñg\»vÒtã{¬îF:À'’7¼PëÀ¢ƒ¬qIŸ›Y5á¹ôRÂ…nªÑiÚßàÖùVÎŞÀîé¯ØšŞ	ãÁIíu?q’İÓAX05I\)&•BÖyu,ËqŸã„õN'¾W~~Údìş5ÿ,05î¶¯áü½¤ÚúP*'œ˜\éûAbTAé@RHòîqueæoFğgNÚ’ƒJMx	‘•ÓÏ`6ü¬¢Şñ\WC%Ì¿¦¿×hÏpeÂš³¦ÜöF*‡¶²‡râ.ºÈñ½:{ïşİ®öö+U“Ë'ë
é]wÈ%;Ùíì—‘$ú*Q¹‰Ë=ÿôW;4Š•b¥™HŒ?.~2k
rWŞÏq|ÇjúdîÃÖ?‡húî³{ŠRo½0ÔG¿­~BÈÑdTÿY<Ï~·„Ï´ª§s¾¾ğs[óğÈ=kSä,|Ì†ûéÅÏáÙ 9×RUºEs¢÷4ú»†Ø`G–JGæ–2×¤k¨SGµöšŒ7emêÎ•ç±†Si°†ïôLƒgñ‹C¹ëVİÚåÊeüãğ¯ ß¶ù =3²­ş™ı2¾‹Cõ¹™¥cš©E’œ…:¬iâû
Ç\Âå-TŠp¿1:Ã<T§Ò²ê4ñ9Š8`}?1ÌkÑkBíhìUj:D¿‰œË­Zšà®¬S« Ø%²‘KÍŸK_{m5Hù{jCxğI¶şg÷Ä¾A¸+ï’¢ct¾XDuÉkæk÷¬[ÜÏyhõ~QK¢G&­,­„êöı¾ò7è>Ï˜lZÄ#c‚£Û‹4qv}L4I7ÇjÕ¨|à`ş?t6óq‡·/hÏ4¨çñ±yåwi‹ÇIÂö
ü…‰øEËà 0…ÁúAş`×<|Xæ˜z5¢®ÂwRô ®;¼©ş\Ó¾æ©®Xo˜k;´ïªâ9#*hÇ{@˜;iD›¹Ï’0‹ğÄWy°î²ôÃ‡Ã,O«Ó£7ĞÓÎéfº}zV¦(Iï‡š´oOBê	Èa×1—„ÛäÍñüÖöM½x9vmEPR£PM[Í‰%_SÍŒ}ı>ú¤b|éÖ\›Wkzhj·eC^(Îh Ò¬%{à<2ìÍ4†:Eµ€¶£&¼ıK1W²¬’Y-hxå%×Y‰@1şÁsÅ·VÏÓ¿˜·çà¼õX·Oùùië*²LÔúY.ğŒ:Å_­¬ËñRM—Up‡«!ĞqÙD™ªpyïˆPÉş»Ñ76X-Üh¾§÷xpÑp²}
¯ª¦NPD–=`Ü¦MüRšY½èŠÑ—Éw<ûe`PYÛÁ—ŞÌªë³[‹9%œÙÒ< >SD„D¶ò¶Öº¶oœ_Í$şqxİÿ~ V"j[T¯‘4É(ºClU‹¨vD^0¢ê¡L5œ$º÷¤Ú™ïH­[ã~Ç&X/<:0ëÉQ’¹qÒk .j†_I<—Ğ?Ù47ÂFAÿ¸òŠ*¬b¸x::TşG·1dvÇßÉ7ÊIÜhêy›ÉãùGëØË¢ÂÍeÕ1~5Gt´¤LU´FÂg4àeAş«2LÇåkkÂõèDü(ØÍ@ê’ÀáØ¢gÕIúç].â? Ò>Y%¢ª<ÓÒğ˜0dßš"Å\ˆø†îx[ßìşB~şË¤Ú·OdkLjåõAQ ^k¥Í‘L>²<>?m	f×B l­¼'“§oy6ïx…êÿ˜)İqpÄ-yi	J¦ ¢.Ú!¶ñ„ùõ}cL
 ¨¹å]ÑÇÓekFe½¤s
Fl±XœdK5–º»(Ê4k^ 5^£òÉD‰F-¬zŒ'v¦êç¼B÷kh07ƒªvÑ
‚R%Ø3¢•÷Â&‚'ş°9úÊ©aušèÓ{‘ø8À fyÁT^u®wšv‰ÃıIÉ¶VZÜhJ­³Èâo#nØÏ<Â—Âôc–ª #2Õg¡ÆşÆY¾µ9yüÂ`F,—ìG?ÛPÓ™É
Üò¸!Áâ5Ëİ‘!àPY‰mO»æÏeCgeY2K
„kÍe¶+T_kıĞM^/„ŞÍÒ–ÙÔŒ}?a½4°Ş¿¿ÔòÂª÷w!º<ÃÄ	ÁîMüeVh’)ÎOö.~òSxljÛª—'salØss8ò!’ìC~ßÅ»ã÷ã†ñ„”m°•)ùm|·¼úˆûœwÄ»Ñƒ¬7…•†Gˆ§ı%˜ÏÃrÂ)ÍxçÇS¯%¾/8iÒ”/>jÅ=LVcŒzbB@ĞAcˆÀ­‘X£UbæÇò‘ü¦‹ŠŸFˆïÓ?Õ%Û*Õ¶{éR2bÒ6‹ˆ? tAéM#tv”4‘w²vcÔÂ
â1¹@–vŞ¿^Á9Äô8GÕ|ØŒT%1åë+í©Ç“Ìån¥ÁB±,‹ÆÁ,¥ŠSLÿş‡	„EpÂ¹©×Ú:Öc©×\v˜F=á
(øa~øÑE*F®˜SìÖŒ;K(ñ”CE^Å¦û'LÒ­³=#»oŒdC¦s/†‡ÆÆmş-ôpWYò3?†;10ß`ú1Tñ£trßUÅğâîD êBø‘Õèã9_,sz¥Í;¥½­Ç©À˜«{ ÛE%GV (¯3Îë’œãª9Ô´¬ÔfÚbì[•[J<Ñ|Õ}¡ø'«‚EÙ³²ş{>rG7VË[§TGı+¥òÒ†Q¶5íšK·.…²-"Cvş÷‡İ‘KêâÓfĞMƒ«æ•'$AçH¡.Î9ÇÂÑÓ’g§æ8YUÉo't¨Å¤Mµc>ù	ÁW¤m¨,¯¬#0lÂø'ì[(ykUFŸÍ`ãĞ—Ğ€”œX=³BPã3v¸ñÉÃGú–l	£¨†×w`WD^Hšê\R©z…±lS´}~à_ÿÏpå.\#&[£sâk’uzQ‹¾Äî0?ÂrÆëúˆ¬š¡àon‘æ8ØY•K:‹9,È^âæ3óÒ#¬"sˆ»*÷A,¸t]Ê-uDF ã¶æï0NÉaf± ¶óÃ†·!-øl°Hß·äğm­D€ïu8¼%<"œÎBb%Ìø»ÛÆ’lÂ:—Å#ª	 Rß\¼»´K®_AäÍ0FÜ‚|™¨úÜDÕRpJiDµöÿ×­„AÙš½>Ú—¦{=wÕÿ<İš÷I¨Hàhføöv éî Â×åÔH.ª·SuÚ}ÒƒË$²“Qk<a6c¾Ë‘p@f¡{ÚàÉ=ÈuêŠwöÌd¶<ŸÔîéZŒî¥{ÍvoaWŸÚl@>¡œeûe¡zŸºÖt,Z½z€I”|oú#t¨â0h8O{<Ifß¡†égƒÕáƒ=bYPÜöÄ¶£hA%<lı~BÔAJi}ÍØ”Bt193Ôœç¦Lu)óÇ9s¾åöóQ“9,—:şİîOSâÿÚ±Æ\dşŞÂ¨ô®½½y§öÎ=Oê‡)2hÓŞÜNy«í^îX¤ƒC,Üûñ;Ì;e»ü$îOŒÇ‹,»[VûÛÿıŒÚ«ÈvÈÌI4†{„ü=ÉÀ<ˆjKöËIbî \­‡sÚŸu?Şå("“Vl–:ËÚQï =ª}ƒõ€®Á;B•Tæôş—{áş?D¥EaB…g(d¨_TFå Û- Ôb}5¹â¬ù×Il‚··Ç"+tA9sÅµ:o—Ê%âMíŒı£ÕğR9K‹Üû´Ftù¿›íE¹×‰¢±‰Xê…à‹ªkó~„¬ÄHI±rˆzx¨âû~ƒâ,|ƒÅ¾ßBøõD-•1”k§`£yî§ïïµÎ|!X¨—­r8¢¾İÇ*GLàµÃ¤×½ÇÚîÆ­c~¶@¾±„˜ïĞ”¼Õ1»@/Ò,c„Fb;nãÈ|4F¸,rñ!Ñ¾-! ÎÜJçèÖäòªç­,şéÀõşéf$ê§ğx~B’˜u6D¯áê"qş=Ê1®t \-&b [£nCäá¶ü	D$ao¹ÄÅUésE÷Ë«°áWËŒ5cQáÆV˜MÏB¸a|ç9ÍæÉÿ0N«ñg6‚øúF{6·oğÑÏ’FªÏ›§×À‰‹Ç9n[ÂV€4R—†ş÷×ÌCîâI¿·4ÑĞ?2Âr¦OÄX:ëÕ+y4q…FôGç2îFB"Xd–pı{Ğ€(iX­ßøö5¾»­ı+xä|6Ÿuß¤4X(NB½ğlÃŞ‹¹qp@±2,%®ùª„IÉÍ½~ü¨'wöã”'°Í—ÏägŠe8r%%<˜)]n×¬ÕbŸh ğ‡-4ÔGRÚmj®•w1·VĞ£i¶o*1<Õª+DC&‘ö\üÕ‡ÀäŞÚ ¾M^Öx/4˜Ùû †|0†<<I¢×‚
•;sB¸İä¸ôÊH=¸;K%8ş‡A+š7ö>D£ ²›[NCC£VDÏsëÃ¨6ªÅ¶GäÕ	¶Ó-±h¥£î9rxSp¾A)ˆ!rµ
¸¤> Q½>ô˜%·ÄW ^
âØWSiş£’Š:‹pŒègğcT²C•Ò)€å\ÍÎúDXbSµ"qß#~´±…kâtç»€!)p§¼q­;!^ØÎì$äH’ˆA	±¡‰¤;a™¹TÔÔWàß†Å®Ñê¹ƒßh6OájŸÔVùíËû¿GÀ¥­l›+tÇ7å¬ad•a‚sq]gÊxW©R ÂÄ³˜ÙÔß2HluŸ×m­“÷fÔ‰k˜RÓ÷nÈ^0»îĞÆí\sVoóŸ]ñÄ„CWb)†ëÆ’îM êD?è«˜]|	Y;zuo~øèú—zùŸş¿Cë´«º¢\îĞ+;üÚ˜NúH B–KñpOl›:?¬ñ‡œßğ-Û”Ğ–±Ö+8T[{¦bÖõ9º¶^Æ5xİ7Û¹WÒ6fW)t¼Ü7IÓşHšs"`$ E¨¿GF˜ø~ªa şGå¬£^B=Â´³t§zÅÀyX<J9[,Ùh%}‚Î˜$Ô`ï´™N¡´ßËÈ¸`ãYW?¸©'ƒhåŠwõ{m¸ìÌÖ­EKMê »´í‡Šù`m<¾|še^î~íË®áÉ¥> øH–äCcĞ±Ei‘kÔŸë¼ßğ‡®«GùÕ@w½yí•N×€Í ƒ‹UmÚ8ˆq!ƒ÷À'¥¼F‚û{åbŒ-¿ù-Î‰²NÛ%}ó.l&F9‚¿¥‘¹Z—ÛNGJBÓ’ˆ’9O‡#DÆË#fÀF:õ*d•,àF$ÍÒŸ²'àÆ6¶_õß}Â[Zş·¥– Ü;Úâtäj>„n}Ù„É°M¶'±_Ùh«;•04äB€¯&a’ÌhÎW:P=o¤éÔv×Iµ–±ëH€j¶?´yˆ•Ğ ^¦ µ»/ƒ¤º?]Î_ÿÄ¡ÜVÙQ#ş›’I•èºk–taÔ»£‹_í`ÎÈ/I1aWŠR©•E—ËÉ?´IJéüÑ‚…QQJò§yÕ¶'§†Æú’ù. ¥=eåŠÂ·‚>"<—·ãz(+nŠ…|2çÙOIÂëÙ’è¢gx™%û'å'Èüïşq–kZ™\´R€dÑ€üµsq'é¬+ÏçòÀhm|BU ½¶ÚB	µ*ò½úEÈ^—¥+ò§¥ç%4£ÓŠzjÛ/ë(„¶- ²Ó-L¥ÅWö¸)àÊì[!Şr~N§·{0Ÿ• ™”İûfáfuºc±0vqì´¼TEOc¿•/r©8iŠ…Ô–I­IjGnÁØ§EwVj&-b–éO°Ğs”^F}@½)Îî‘ÏJ•º´¶í{M4ß{Øœ]àé’-kĞè®íÇ¹ë~Üı(ç[G9Jô9’™çäÓ\6®Z¨jøNïµ½XÑâl–SıOÏ·× ãëuîJÍ!ø™i!¶YM>kÒò£CÆ-ãš|òò×ZqfN\üKB…åS¾ÌéöşFw?GµUéæ_Yàe§+dÆé}&¢ú^Î0óp5!zL~®-*Vx&ÜèĞ®Òa5P‰BÎĞ.XMå<€ZœXÅ“îwö®_c†-­´Â÷:%Şåsò§k8ÇpV¶Ü01ÑdƒÄ«?mpŒè_9š7ŞzÄj®`şÓLË¥«;vY5æ/ô)¡\ÜoÓóíD1¹ß ¼Ü‘šÒ\Æ[uÄ÷8Ò0qyv`‡qÔ ¿a¥À4½#›ŠÚ&}¤JÆ>vF¯ÿ;–TİUëÈ&púåeX¿âSô	>-ì‰¡†]¹1—]° òY`¸¸nöì@™xŞê³÷æ¨`\1õæ”/YÊ8†o¸ãu„K‹ĞÇfá°˜x2º²?Şà—Ç³·Ô÷h©i#¢¯6X¥m¦^ıŞ±²=n%H¢9×c$:ú,…áèY¥}ÈO¿-<\yå€	Pg7(#À\š-à¹×»ŞÃí™gº•3¹¦ ‰…ò¯f“× ¿«:6­T©¯Ã qïÔî \m@Hû%M‡ú¨´ &’¼Ï	µø.ìÎŞ<ÈØÑJaÜú7Ó.ÄoPëj´#_ÿ®†)›
Îı“è`dU€øë¶{“ÄEYŸXP´E<¸§É’¶/#´e	Ô ƒY*|aß¶|¼ÌÍW¼™Ş6mÔgDø›Õ–é6‡œ©4ÕAEuíæKmÌ¢hœşYY¯~±/— ê<íd¾®àW18¸–6DÏ°„wEu¨Å ÉUŸ‘ÒüÄ»ÊåClLuªÁŸõ¼˜&öáš¨P}³ÄÌ	rÅ4.…‚¥û?¿ôXKüê:m[wTÄ{¶Q–3Ó®¯¹c1ğyk2Æh	Ö¤¾óø=ä÷tÄMïè–±f M¾™—9@ÖkòM· ©Nc,’éK]§Ş‹}•yM@
e‰lŒ?ZIyHaår5ÃeL*€)˜» ãø÷›â9G¡Ç…¾qzaŠ{ … Näå•„áÊÏ‡…,ªÅDvôë­	7è\Ç‚¿—Û‘.‚æõ“BŒtc¯:qØq oÜ%šóå]-úløÆÊJHél÷†Ê70ñ¨q«U1X_Ã`Ém	†òKM"šb—í‘,úe‚G™U‚ĞÒ«Uƒº>Œ²/g?P-ëµÑxI†ºó²´–@­W'N*Ï Bv‹Kì¶]›ı°Íuä-»ùUg·…™Åu¨·îÄvÎ…²¶‡ˆğÄÓ-Èm/!1Ë-BY*Q™-sæÛ(Zj%<G’	_%u“XrÑùä»VEnGÛÍ7š¨S‘0W Za"^Â^òÀİòU¯BÖµC‡•kÍ¹şñ;–°¨{á21ûÄ–Ú3‚ÙĞyÕì\áÇq¢É×O3È^Ç=ù8<h'®B^Ê¶Ó¨AÿÀ2®¥5*™XŠ%°ğ®Ää¹0º VÖå3E&~õ9lÉ˜†Of3­©Fi²ìê›%Ø~œN[|˜kß0g/´H=‘Š–É:^6a¨tmÑxÙ”±yé:Ë¿áD‡QÆ¹8ÚÍgÑœ+„Y‘ÄÌísL½ò¥Ù¡P4@(NLÉ/Ø›|ÈÜçóª¿‚S áôå ±Â§Û AYZ‚”j7&¹Ü+sºâÒqd2[B€[7ô];fæ»/lçíîšüU1ı şi§‹ÊY…%|V2‹æ[1×	ÑgS„­ô¸™¾ö{À§š0PkFßø¸ùÿ
n,}BQ–{GE±´6h>¾Hj±]æ»^Î÷5Ú€lßœõ¬ÄÚüv¬€PìÙÍdşZ|ú«<Xô´@,]`yK4İ!HM]I„ï7©Áƒt£±£uˆæ>T-DI‰ÛÄé<¢Ó¥QÅµë-«¡6r£ŠÊğ²ts8§ƒ‹*éŸ‘¶Wù•Óçw;ä¼ùùĞtÍÌæÌfF×+5ióÔ-
âqÂn@MtlÚoSx«aJô¸ïîÆiákå€0-íés>‰Ùì°×ˆòñmş¢uƒamüˆ~QÔ½ä„™œ —MÖV©ñGĞ)wÌà !½ÕÖbûw*×S„i˜H¼ª©#æ—.j	af&3eì;À4ÍÕ±qÖ&ûØjsc)Ûq» ‡{ØùÉ—œ¿¸Ö8îäé¸+ËNò’<"7ï/’Şh$C ‡8¯(Fùì°šª½¶7jÏ2uÙ²ºòÇyèÌ†8á¾7:pÀgØ“F­ È·c/«B3*DC‡6¹ŸEâvO¼nw÷}ï¯ğÁ"Ï&Ğû“¦T­«Î	N˜LÉZ#ŒzäŸèK‰/C¼˜êHÎD³eñy>ÚL46Ñë³âšÕ·í[õĞK+ü»å]ú™—Zr6ğŒy×,Fø;ÌöÉt2¼W|Ú¾Íõ¸úk`yjÑ5ì‚´16,ä ’…¤Št¡eàµÆGÅt¤ñnwâú„©¦™Šµõ)I©O¯¤½å˜–²•ôş†æû©årÇ=İô’ÛÙÒãdïqëtTê³°~‹‚0&`ë¢ÛñÆ1kC p&{\¡øœåDé¡ı¼{è?ÜØÕ=%ÌN—Ì2wsmn”Îs÷Î¾æÀkîßv¨ æjh©{5Ù“6H`0&ìë!SÚo'—ÿâ]‡ršßyè:0(¥ºåwòé…h•@¶ì; $JVÆ¤tªvÑe.Èc‡ƒu‚ıìª¹Ue§†›+Æá!#Œ1<ææ8•TùY\œ¢¹¤£ôş†ØG\›Ÿ‹!‹íÙñYŞÄÍÏ=F¡i—¼-Éß¬¥¦ôÅæ›õÚvXU¤ùãÊ®^ìy2vgŠâ‹E!ÀK²Zì¤~ Ëo›ğaçÁ.í&¥‡Òwğ(íêùİæ{e—'ñ¨†Šº±Œ	+³?ãsæ"Ùãáu®yĞ£Å°AÓ_ÿ°,±E/wAà]ï½úé¿ê$è;‚R<Úè¯¹$çôÌ£²ĞäíEpuŸñNd`½,‹ı¦êès'_}7¦ÁŠ=gİx›íâªmœsÄ2Æj?EMtÑk9[Mc˜ÂÂéwhşX§…¬mC§÷¹×5ß“‚»†/?³Á)eï¨ş:·¤z	ÜßÊM{Çó´­¿çŒˆŒâVìBÓ,Ÿ¶TÜB\\BP´Í¨_wJØ1¼ïbHE&2Uƒ"’xÖZa€ŒúK¸+ùø°¦½ÖéØw§>àt„Ë§S¦Šğ3!’¡%6Qçéó¬Y;S¢Úû».Uh¤Ê½ª$¼j2Ç]ã\+¤ ÙÌ9)H"À6 ·²@k[r·éìÈ¨‘í¢7ä2,Ö„ı=2“{Ìgó8ÏÌ0|}Ó¯Wùöeká÷Sş±–¼z2ŞZÑk'Û“t¿ƒ0ÄFsñ) Ç“z·õCÑûNª¸1î»R¶ öÜ´VfÉ[„´¶âƒ³j5xè76W¥¾Nxóø·é›æÔ=ùız’Wä˜"ıÃI³İl¸uŸ®¾z5E³ ÀEì_SéX¯ØC ,m‡HŸª[Ò!^¥âÅ¶‰3³úöxø]ƒ±9Iwa´+¡ª ¸¨¾±¬½-K™ƒ(ü.–3•[¼`T
ØI.a{,zÂõDß3êkÊwŸÎJÒ¡³’+dº»šZ6lìŸ%ç'ô
Ğ/Ã$éí£µÄÉzùJ-ÊM‹óR­áÿD=%y@pU‰˜t¤#5Şë‰Ó•h³ã'Î ó·!DÛuïsÓ°˜ËÀHÂ/5>Zã%Óƒe·åˆÿXŸô¿ğƒÑ8˜góNêQßø(\öòU‹<yqÏRƒ>‰Pê;´ĞfÁd*ë|(x?¡C†íŞó†\uêivŒ\síG!T=òØÜHÎ>S¶_•uF£Q1>¯9èSè‰g}Æc`Ëâ1¨uqó_¢!|íÚteü³#öœ7`{˜—âPçî-#â1/
µ…Š-G3:¨¢VP7@›kvG60ŠW ú8)Ÿm†·2ë[ms¬yaª¸ù4/	?rz™È’Vîı£k\ÆĞn”Cınu|Ì|â ú/Ó©‹D3YpæûÉìD	©Q™ì‹ !n[šT¨¬õkšÅà!ºë‹™¸áë],H9éˆfü‰¥iI8ö¶*Éï8é¶¦FJÙbX9E6~³Ö©‚uùÚO+Ô MıÒ=ÚWN±ğßµ@G=rP•gÈ‹µÔ»b.C–Daz“şğ“W§n˜™èÙÆ#Ğú¨wKÑ7 ÆE¶("J9[¦Ê1¨Şn>Èø€Æf^¤n>Ÿ7Jhßİå©|(ºà-]åÇ˜ô÷ÏQ-!KíüjÑY§c<@ú¡ş«ùn¡†˜æÚu<êGªMºù
C¡Ô ï<…¡:Æ¶™ûc˜˜Ê2%y·f"r}:0Å¾iÑ	¸EÄ!¡n9Ï†®4}Á:ë}âF¤¿èßté¡[kÈ³1´6ÚQæ#Ò©¶¦}âJ$z~ÀO—ÎòÚ•SÀ­¹K°ÊeÊPöçb—™:ˆ
¨iòş‡íÔĞJQÔóÆÚÑ…”„i­ÌõKh†¦· ¦u9yºƒ,ğb@·†ß
CUº1üƒğ˜ãÍ’)¿JŒkU[{ÊÿKn…È*Ø*)Ô$¤­ ù¶Œ®uº;‘ŸQÏÊrLÅ×O(Èt@ôTH!Õ¦|yßRJ4Õ…RÒ¿İo<¡Cˆ4¯„êóOíùvÔ…¼×à³÷MršÕzOÒ„"¡ÕO´Öæ«6Œ¾ç;°òÏß ÜíácÈ´Ä~ Û‚œ¥÷nøHÖ.:×]ÓÄ9ë˜Ÿ÷st¼ØÉâ9ëÍº:ñ‘(”{îbìîZÖP š'‹
M‡·Ø4ığ‹ÚÃvÒ66[ú(<•€'’4ni‹Ÿ,8"ËS²gH{49¤ò¯øŒó×­0-Ä~°µ¹_~—4èÎ²nœ?İ9«òÚ  v¨‚°IY#&ÕDø”X˜S®Ròœ>pîyé£%Íü2:LyY²4ˆ$müĞìıÊ*€’š6•o>ã»´¯â«v°¦—^uNèë¤”ÚêìÀy›*¼Uäh£ÌÆ¹b‹Hôn%[ü>¼j¶­îlš†ÊUâ‰Ü[HqLÊE«WkŒhö·}Ì¦}áÿÿ-#ÁŒ‘zÏl]ü>3dIÅóP8TÉ&û¿)ğ `ÒÜ¬¯_lPİ¢mltı^âªÓHŠp D+ëôÄÌG”¥&Â5rÍd]ãƒ‘@·ÉT
ğåhXy×:HÒV/—ªàØ¼¶±£¯¥1‰»dXN _£ÅømE„f>Bº±+<ˆG.?¦n :Vİğ&ı«µ¬>"s/fN”ûC4(±¦õÀK¬Ô™nØÆÒ9ï²™Í¥Õòe‘Añ—J<+è–6O‚÷[À7ï0,”Á!ßQƒµÂAÔØ7ƒ¡öxfÉ=ä[;¬ÿªyÚùmuÉƒ.?Úv[Â¾3"‹iöºÖ*drºjˆ¯€İKw)ß´Ø³<#ZûÂ°Ç³c³Ë‡*§Î"sMcÅõ‰GÆ`vô
LşÅ]Äç¥èiYMƒ×;¢Ä¯=zÙ¶"©âz:Vq@ˆóèa‡ö¦¿°³í‹‹œÕ¹œ¡j–ñP4PT¨mfUæ’ÙÀ?ÃÙÓIó1FO;«ÔJ£u³ŒŒNv,S} ˆãéH?«eWxò%ÅšMa±eº”UÆ*±][k
@Ğj 6ôƒşÙC¤—l"RC†?7çkxâ=¾)U?dáfĞf×$Æş‘@ø7 „ŞODŠ£
,=ò-‚ƒ”;´»ˆJá%½Cc(™C%¾WÒ›“¿ŞéoÉ¢V¢½Vó±hJw`˜êX ´Â~ÑèuMn‡;è?.&˜¹k	£KE6}Dáş’ZJµÔwŒ–Ğ)÷»ÿ~‹?YFt0r&€ò£iH†T—²c”RQU18u*…‹ì¸êı¬À¥ş}9
J¬~HT³³²ğ÷eæÇ‰#ok=‹/ãØkÿL!ƒÏ²í>©#F$EöDN²?Û¦9ôR û0æZµfÕ¿9µÍ©-ıôÑt¸$ïDú>a–®<óã>¡*0YËOàêK„}p3z%@ÏVRÏÁİ[Û Ğ?şÊü¸CvmSxh@R ˜ ÀHAÔñ™¹öúè­ùœ¨»Z:  õ…ÙŞ”K4 ç¸€À:‚´ä±Ägû    YZ