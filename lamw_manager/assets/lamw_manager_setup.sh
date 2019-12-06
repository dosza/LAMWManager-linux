#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4037521974"
MD5="9a02ce4be3eddcc4e8e6f1abae28ac1a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20192"
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
	echo Date of packaging: Fri Dec  6 17:52:43 -03 2019
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
ı7zXZ  æÖ´F !   ÏXÌáÿN] ¼}•ÀJFœÄÿ.»á_jg\`€Ç·ú è‹GıÛ·£ö#D§¤ãsÖÀèİ‡ª0µ8[wÏI§½|ı¡¨J§á.€¦ƒò\”gYœšœ«º›£ÖÕµ4·Ä%ŠeŠ\‰á¯Id„FK€qÎMUÌ_Ú2Áµ°HÔÖÂEó3ÒªÃ{â
WjcÈµé o?ùÜÖ<Îéx$qø:7åG•‰ã8Õ-ÿ<*mVÿÆ¹˜ÌYŞØ¤JŒJ×$Ş‚ëçD›óŞ¶ÇÙñWv§<½¾‰Â&åW€M¯šÓyIo^®pæ´Í5YŸÕËÖ°,ˆŒqÉ¤Wd–8Ş÷°åGå†	ÊŠòHNéicúmÂEÇAğ]+Å‰!TĞWS³¨½PşVšdOÚ ­æbR»úe+›EsĞsñËQìá¦oœvC$Zê–Ø#İ…z®óË×d\,4j&ÉÙ	odvûÈy+?59ÄûÈµ…Á&Éæ¹;à@ø ORƒrItLœpŸ‹MsÈÖ„.9L…okÖ™bhûjC?jÜ+>¬¾œî`øÉ#ÒK¸•KBâï²ô»õúòˆ(¿yHÓŒËèpºõÅtq8í)á1õ§(uÚ«¼løXÍ“xZİM)zø[CfÂ¥ÅfÊ…Î—Èùœ‚`oFMg¡‚U®J‘ÁpAl¦ñ%É5$Ğp‹ÒoeİáMS™5ù36Œ’ó<K{’ª)jÿûöo\*g	‹cCy¹FE*{Å`Š
7P†÷°L:“¸M¸—“û€švÙ™”nGŠöõOTEú^'uXcı5¥§,S«~©–¤"ä9Âş>¯ã‘ºJSj
õ—¶9!e›K9¥GoKŒ5Aj6°1ñ§Dı³NBÍ&iXè_äDwùDöÂhv]©©!YèåY]¨--©‰øA¸†¯%-l4¡,&ø‘g“±È\,*[¤sùY[š×ê»V,MÀÜ‹âu—o•è„S¨$vÇ·HSş`ÙE¾ë–7=e¾Õ5szïË;¡ÿ2ª™ÏxêİPNg}ØÚLøgåó(yt,*âÍ	‹xmK¾ZbÔ;#Øxü*¾ À€Nüˆ'”‡¸mT9j–±Ô6 .+CŸÎ¯k0;¿v¯$ˆ’Ur'Ìø¤/o/Ìô›cmBnJ{t'LÉ…ÿ¹=g¥l‹h€?ò5Ô—jÊ1¦ˆ½Aª†Ò§´lg{pleŠnwJ	ıù¤‚a¼3R(N!—ëÑÃÔù÷ÒçúÉ×dV³<t0ÒğÑ¼®J_]¸?&_ŸnUn.?ÃÀKZRÄ®§©5f[j«|¡ÔlØ#ó‚«”V)¸Ôü)0¸pî‡”A
Tm‘b}E…~á ÷¸¦óæ»$'x»âšîX#‰W>0Ê¤Ív!Q~;‘y´ïİ$5Tæ aÉ±ĞÍzâÓ´#‚¯Õ>½ûg"‰³Æ}lXŞ;:Š×`7˜bï93;JÀè(<Ïn_!Äüóx³fÇ$IİiOÑ”–{Š}5à”³YíoÀ‚hcãæ?ŞÇÌ/9LíÃz¼§‘@cœ¶ò.G1ûÓ)×£¾Ñ“UÑãÜÌıÒÀ£Áí,¯¦.É@
SLÁ&HšBc“¾ÿœÀì¯=÷I2¢ÊIÇG¯““á(´¶Áÿ>Çâó(°\©"=±Í¡	1Å–iÖŒ=9"’YÃ™I»\•=³‰!yvah°Vj7‚æ„?(¾^™¹›Q"ø„?p˜ÜRÜËÍíèó˜sIºHŒYP2&óT»~%¤—wÕñD™ ß|ğ•TİĞíı$9–¬*ñ1Â3ÂÓÍÉå†ˆF©Ÿ>:ıJv½îíÜ«Ä´DO8ïå_ Õ¬àøj´…ÁSIE*¨‡J„¨2Û¢P¡w¹¿ŞËyP×(»í(tdı£ õSêŸö­^Ä~!c'=İ~ÚÉ‹PÑ©›6‘~+!»ó´ÿ‡ÄR
±AŸ×ïcN¯œğız³~µÔZ7	˜
 ÄÁ¿ªHªß”* Œ²ıBbHÑ:ªè4sP3…fÃ†ˆ8Bÿ¤|ŞÉ¹Or¡Ã)€Sñ¾^Ä‰~Qf5c7æÿ»®Xï²àÃ¿<R(x'h"S#Jê‰2¤e¦ÙQºFˆr™˜ ÿ¥ï`•ğ É0¥'ãJ¶Úíş¬aûò-x›ÿ>N‰sÀ¨l¿‚À{A ÀŞ£“€…±—¤üc'5åßÌÈ*›¶"¿È„.eZ ğO'(/pŒOg×›L}.­":‚4hÏIò=QûäÃÑ%}Âşü&•Óœ476îšßOí öĞ9sn¡mÊAÓ$K\¾³¦u­Ë^ÛF.,§¤'¶’‘Cj´ìNãéP™ZWùâÒ¤i—­k›ˆÒ{rÄò’ÀfU÷¶™
©fN~%Ï£8t<õ–’¥F‹!Ño$¶ûñê²\jìWóé`}@í|z[3EÆŞız‹QüeÊeu-ÌPùRt´Z|›yåt6ÊµGË0xÔ,d7HÕNyãw€ƒgšw%“¾_p´ŞY›
|å{äš–Lİ3¿7ÁĞvU)N·ëq	wÚÎµ ;l¨%/"%ìšbÅ—`{pãFèŸş9ïHËB·LwùÖ÷
‰Ä}Ù®o¢AÏÜL„şx¶Çóğâôş^C ää	ˆ±i±9ÇPŸ{Âf0±Ñõø±y æR›âë…o„éŠğÄ˜ıqGyL¸(Ñò³PZŸš›Âš1S0b$A¹Vöü¥ö'i´ÌQaŠ”äÈ¶ËÅî÷¯V$ñĞÛÈDª<ZÜjÆS¤R±>Ò9:[İTÙ¨˜¾…¸–;¾ÜZMéÏâgŞq{÷ëIÏ„Ì:ÀÑb>õ¬I€?ÌÒİõndåäÊÚSx3û.©"µ¸mŠÇiY9å†¹nº-«Œû "69•»Î„ùa±	Rn
&*Ã”Uh“¬ú5Ÿk(i”ºè„‹x–^šS f{÷\\Ó==Ç¨QT* Ø!µGj¤|	'cF†kŸU¦KHLú~S¤\tÑA4ñ)Ég½ª³¥	vØc"£)v<WÇá\'E¶]Qû…ms™âšP{«œ–xµ®ñ“~Ó“ıš–9³ız¦¾‹ğí^%°/½9*¯4†MŒz¯_º”«¿¯|´{û`·=µ@f	$}¤:÷ŒL ô¥nC¬vÅæş»	°Ü‡Ş‡ò²ñğíîZOîŠ6¿Ô-¿Â
¤º»Ba‹šE¯Ê”İÈô¡b©SŸPá¦‹ÖÿÏò~ßŸßšı
¤-ô•Å‡Ø­º­_ÛûıHë[Ü‰1+æ°ó@¯ß„E<›ÁÖz. 2ºp~/ÃS_>øß×a$Û<49Å‰Œ+®·ØÁ†ä`˜¶EP¹ôàŠ@?Ä°.c¼€-2–ú¨DàŒÕ²¸ë	N1.óS+yh¼bïIKV7Şåj1ÙÛ[O\mL¯Š~î¢…ô—™‡Ÿh{6Ûƒì“zŞ[Åğ¾×}ñãpüì²°D/›nô~çæÖëDifŠã½¤ÓqWö’ytLøšÌÕÁu 3T*mú[Œxè™.êosØßHy0˜Âû¡l¦+1¤íKŞJ^\±©s’ÈõËËo%Aö5;è·ôşBL1Ø¤-C“ÆZ0è>†…ÀDxJàCä­ÌH*JL}ßÕáí	–aÀ–3p„]Uqûpoƒ§J ¡[	}Ä[ì`œîòƒ‚%¹êMÀŠã¼ÚGˆœ~ªJ©XÒ‘¦&äLTÅXJ7Rr?u;cÉuPÉ2Ò›CFÒ©]*›£6R,:"!ïVğ5¼¹2]I`.€Ä+[ìø¼¯İ-«§ªf;øGØ÷mÜÒZ:A'©uZú¹Ñ]Û›ÏüÉA–{Êq¿¨2ñ`§åâE­µÁtâ/ˆŠÖŒngÒa³æ-ƒb‘3Å¾“–lÍğ Û¿è‡t¸Ódpå–Uä±quà€pL5ŸÓv~G€£Jêİi)ò<Œ©ŸÍºUGÊ?ÿ}¾„kFDº%ù\=9b»<Qd–ŠB(ÈS^Bx/˜C¢“cK¼&)¥!¦ùğÔ=Ê-ÆôëÑ\.YüëÆª“½’Q‹*ÂY.ô!Ÿ<Û»2•U¢a_ŒmINº>O;Ás<g˜ª’v+?¼ÙXQ§¥äğ¥+’\×£[4dPŸy cÊ. ƒï‚‘Â§²øKqT¾§Í$Ós™Œßb¸!I÷ª¼RáÔÇûQG¯ğPí=VW²€'´uôÆÖ}Öd{4t¶‘Ÿˆ÷ŒŠrsuª¢´I‹¿Ç²EÿÖ9=í‡äoµîã6FºoøVÓ(–vld‡?{¼zè$ÿK,Êd8w<FrÊ,|ƒÚqg38R!ùë™x-¦Ò€ˆaÒJeªÀLÈO2ıÍîÊÛÔÖoMÙ´¬/S \[úô3.<XèŠQ!D¬3¹A™[äŸ‡<£;>Ã“ö3İœÃ…í´ äùKrşymùy}àòô…ËNšãkyùsÿj}ûWùŞ˜õ¸`Í[Ÿøë÷Ñ—~!²¦Y\…ŸxÙ~pùî|ş(dJ"´»¦æ–8èRÍnmıB°œ×Ù£KŠ©'âqÔRîÕ{“¸E‹±Å®<ª¤}ÒLÓWÁğ—_‹Í1ÎğCëZ¢Ğ¤¼)9ù"Yø¦?˜S’™İä•
œÑwKjXÕ÷ı®Œ)¿ÉI2†Ã~î¸ËÁàÙŸæõäŞW9ØÜeLéöEĞâ8ôl˜+qí‹ùåa7]Úim´™ĞÓ¾œ’v%çìŠøQú˜…ÌäÔfô•R•9¬ôé^àÓa^À ÌÂ‘«záÉÉ}d£²ÇçS1íY}ìÅ…T	÷—Ïb!pÉaäùSùl*nô«cw¾2tŠ»‰ ZõÚÕÈí£ëóIÆÂëĞéâQyÌÂ,ÿVşã‡rêr+Æz5#|Èapn©ía½Zñ·éæHRÜFBäfuç«¾õ!İÛ—õtmŠW	ŠN;zô6¸!¤pET¶å(Û’€¹¿0ı<”Ë Î‹AœMûNó¬¼íÍëè„GşÏ<ìı	7`¹úØuü9“@,c‚_nÎ¹Ì{ö7-)lís†A#C­/¨Ş&Õÿ’ÔVÆGólpÿs1aCQi<%i1O0¯]Â¬¤oi&À¢ /gˆQ¨ÇÕ3¼Å	®ñ°\İƒàÍ–o‹ìï¢æ5Ã™AüY›¹´€u./à &¡öù“ZôÚÉƒ\m´üÿ¶¤GëÂ9æµ Ï­¼…™•ÔÓ´Êä
O;±z&Xh ö/u`Ë Šî
ñø§“W'·qâ[TPL¨ÈËl0•g`	,°g¦(HQ)ÖÒXŒŸ[ğE+ÛHMÉQ†ôªµ'³Ì¨}ûƒ(É9kĞ¶x/!Í¥¦Ä0ìóânP1Êv©ŞÑFä±˜óÄ³ût°Y‡Õ_ÿ,<4Ó¾IÆ Ëœ‚ç³¯Âo4`s«±%ª±lP.ì½ËMÌ4qz;Â”d*ôoZûÜ'awq'èUt$†V5‹¼n±4Ñ /ìQ5²¤Éù€]HLoj82A-Œmò¡ O‚]ùîîës÷î)“ÿ}¢äö…õÑÈ_í5{œíÜêîõş‹Ãì1cûè±"Q$!!V%„3ÔµVãİ;Ğ®*D8mŒ;Á˜“ƒ×Yçl—Kï àAš@€ˆŠø–k6Á\Ú€1"c‡äÄ 1ê®jğfùÒ«´¯-’‰ÕæRJ¾ƒÛ¬Y)bJéPš2ôu/ëïªŠwêY1:Êeƒ½ğ•<$÷Ò½‹ü‘™0ŠÌµÈÏ†ÅŠ1åêBGêgTıÑ8hß±£ğ\îˆ®«ÔeÒ<.)`d‰ÇšÍêêµÒ÷”«ôõ×ÀdJA¹hÙÂ¾9êW&ZÅŸû§\rM¿¯a†µöºPêf6üñßÔIEúúò¯QêÑç‚‹}>Œó6ü¬‘º«”NVŸÿ©ŠA1=&øPßÛ†GFr«ğo<~~$ Å€nUĞäËAÜcæc:÷‚‘ëp)s2çî¨êR={”Ì££Ò®2ï¹¤Ç¯|ë(±ç¢Dmù¡Qá‹y¨ÙrjØ¼ÇOÀ›®àÍ(ŠØøÓ€€“MÈaŠ«Üt²=®‹œXf+«Dˆ2éS¼%›%5|m}UôğÓ˜Ø°¶MX”KÂ…Uø?–{’üÏ;¡ Û¼N¥›;S´j€v®ìÚ¾Û•‰êlEÄ€‘ÙÄuiwd¿»úµÿ#ÛãÉvQG8Hİœ7Ñ«-Ù×nÊ—õsÑBæ+Ùíœ./8•iãÂŞ½Ñ?(Ö~O-›­@Û¢Úo‚´Ü3\ÿ¥jÄíjg–ˆ—‡´¨,÷uµ $uÕ?Õ>p{ÿ™‚ûRè¦£1Z–‚})x–8Ç5o<„ÜLl:=¿Ÿû‚.@bCƒSÿªL ÃÈÔÛQVâ7µ°‘‰°7Éís£¤SÔÍÊúšgXdz¯)¨Œ‡x95Ì…#Üuz»ÁL5À} TÑ™™úë¥dı×bâ ú¶¡ÄFb>ÔNêr˜‡íâÛñ"p7¦;Íæ˜Ÿq•ß~=©_°Ç£ø(Nàÿ¥ôPî«^ğ>ËÙys]I2«Q¬€E0Tdõğ¸±EI¹PbOFsU½E]'1]#*õ1Å‹ñÈg—0´ó×GÄ0nİÁjéœ3‘™:ÎmyÂã)ûî³Åñ‰ˆqÂÃ«|ªh¿‰ó[/¤zÖ‚?P“Æƒxƒ] o„<ÁªHê†0F×¤*H2óŸR»#\ÂˆY¨’h8ggRZºy±°®àPpBzS.…ß›Qõä(ao1ùkôğ¨	¡HøÖ&ï/l	EXôo2Z~=z±îıQç¬ğ¥DÊ}y:3å,ıÊ@ßˆ X›î^ˆä¼„l­Ä}ê–Òwpå‹|WŠv«Ï­–&%`,·!œ)£) ®ù¾*âŸQÚZAãUÌ¬›R
Ø%B‘ºDÜ#(PïÛ£´–(Œí;à7õÅ¶ñ´ŸúŸ‰ÆÊKßY—ìÈu2Q×$]næ²t_'Çõ’¯s±6¡a«†¸v‡[%I›.?¢	æ­öaç´Æè`æZ£m„ôÖä{â3n[Â˜ÃÊÑ“¨Bìí5HH_øï\åÙ¡’˜(—>nâ§]j!<aMít™xõ¤JUo5¢9Œt£í{¿À-+òÁûÉ Çû‰“+Í³;…4«··&V±OÈÈù(/í²tõÓÜrØŒd¶ìN¾÷BNJ‰‡i`*‘²HŠƒÛAáS¤ak4 —¹äm“:—vM$íMéJ¬Î˜Î¨Ş¥‹zêÇ£s>ü#·ìb³&CŒ½ö>õÕ*§4.ñ`bg[3¸_wºŸÖÌM^×²¸§ğë¥`'èAlÔsÅ‘Â]dÏ—H¢i’¬–Â\íf®XD¿à¢/ëµÆıOÜtbmR½‡¹¸»Ïã^ødÌí¹Â.¤Sº¥‘Ä*5t±«][ãé#œTx¼ÚŒ8«í˜qET÷M_À¸UO¤8. ø‹zÈe
H«Í=í˜8JÜêÅ¦ÒFìƒ£eåßªßqç†m üK¢^V‡ ÑŞ@ÖÆİ_<}F-v‚Úpn~<ì/´nRR`ÜÄÁõãšª“y¶p¸§³=i|@'¥üŸÔ–ukâ©uêœÕ.pÖ­…cÇ™ÅûdöeãG£$á„Z1&rµ ×°#gô*6§~ÓVºä°¬;æTfQ€	hÿYƒóÛ":¬¯£§Áñ“$àã2¥NÖœ¢ôÓ
8ñ³³İŸ¦´ìPÓ£@ŒµJ…G‹Ñ©ëÒ)•Ñ+±kpw*~ºxªIçWìŒ›8#?+^wìö@zœRb«?QVÏ‰\:ß€µ¸±è³jÑ—À$!öÌêuÙ€}²©¾˜¶“òÏÛÌ}qá‚BÿTË´”gs¸~câÏJŠD©UñÂCÂ	f;H÷xàL®-‰fX‘Dæ'I.éên¾ÙÀ¼¹3õjÄ»Z‚YsŸ‚0Êç286ü)äşÃ\¼XËıÇÅŒäQ¾Êø››qâ3şA¿c>Œ‘ã!²Fü[w±E[^õå2Häì6ÜNĞÛ"i;Èç­¯B=“k¬É)~¤á‹;y3]£„;‹\B]pIû&8E,¹l€a051ç°æF‚‰µÓÑk& YSÄÄnNI ˜jXc§Ü‹Øİ•ÂÂ{%Â¿\Kev™V?¬MCöqH2­”Fá2ÀNâ„†Ù`‡.`61\+íÉÀ¼ùDdazQä¡Q8] ~_Dy·ÍµúÍ¦ÇöıŸÅOé¾1©œ”¼veTJæ<iÆ¯^¼µóÓŒ›Øõ =Tœ˜)x§—‰•ë…1)%Ã¸»{eœÅl³íôªs.‡Ãy}xZÛ§‚¯Î1/udáøËÁ4åï§ÄİÉZøé êÉó»>Ñ]änãÚ*; E“Tä¡É³l‡§±ÀÜŠo£K£];º?By¹C²Dû
à ,@èÆ£O€rV·h£ej x…ã ´#Q}¿58£Ğ_g—{P‡ ¥öçü¤Î9GÍ˜¸pÊûh1ùiº>Ó3Cîf5ôµš1pdëÛVˆ²!im˜¿+äÈw„ ‚ö€Áa“ŒHÈ=kÊ†¨}Œì¦N{R½V£Oå÷Jú½ExÇğ8òí$wE—7¯Sîœ'ÑÚæÅ!î\“ü §¯{<X¿õ¿‚%è:É	Ñ[=í'_Ä›†O1d“ñÎ=,œş]Zk?ı·™Ö«SH>
õùNÆhĞ¯ÇœïWb¿¬8$	‡Rº1#0â%pÅY–èƒÇoê²]Ä‰âQ/´Ä”æ{4_äùƒÆ°y:3{=Éiís/“ÃM{
ÇËÕŸTúVXj<ÊŠ4Ï¯?E³Á‘óøëÂíxf' iŠs}¹k÷&¬LO ‰ğ
ï¹Â¤Ã——½˜Öo77ßÚs,<%$=¢¥ğù')ÄfºóQîc’@¯xö1¶éòCTœ21¡@C1NóŸ¾ ó“XGà"®9_8ÑåÉ¨ÜÄ*H_«K¦ó:½}€büúSŠÙy[ qP¸6E_Âü=â5x¶ºÑ6›†~ô`†­íÇêİYøn)
–_ˆŠ†¹÷üúÄCê^Mèmxñš%*ê­~¸õ£˜UÇÅÄ«Á1¾%…5N Wö†9æO?(²A%TßakE±œ«'Ş„xßñ¿²``¢"d%%ø×Œ¹†¸¨åİ¢S|#¦AN¸’®ËÂVóâIyy\sÄhÊ	Ï¯ê7J¨oc‰¨ÜI²¨®©øü+,çVÛ^Ÿ‚vŠ(Ğ°ãú…a0¹»8_Z®€!óxÒ!÷ãÅ-z¸S,å­U¡“Alwõ9¬{Àašü%’×ôGHÊyî=ı»)‹nS)kæ­£{E2é{bş	Æ‡ÿby}W6áK´¸ûpˆ3ÛÂôà 	›Ï3›Å£Ç‚
GCÿ…_İİÜıSšXØ÷¢Ü½Ã@ZÑ¢CTbGÕw.áI©BŸÎWñ2‡FQ¬3¡ê}?Ën©­bÚøÀÊ æ~Zîk­›¢Îp1/6%)ww°sr×‚uÊ?ëğÆ]zJ££{¨6€V{+’v"A›ŠäF´õ }a$IˆPZªAºÓ±º)UĞ.Cn¾
	Ö5 >]ú×EJjÓFDhY:fHCáÁ	ı˜œ8N‡5©ç`-ŒÓÑkĞ2DÜÈ%†ÆDì©Ÿ×dÕa; sQbƒ.¢&l£bqÆú”ü)ï­§â™XšşÇ#iGíxøs`èÎ@|âµiÔÎóê’ç ;vO»º)% Ú0&¬C“ÿªªÙºŞƒàe©¦jô/±rtËêMª7šP9KÏ^(¿w2QÅD®Ï
L22fîU@E—
G~ÚÅÁ[FR"t)Uä¤0&ô»²?sJ’ñÊ®VÒº.ûıL‰pe¬p†Ç2n‡†ˆ½ê«±^éY&èöš2„CªŠWY8Ô©³¢a&‚‹¨ÕX†—0óYÄØãlÛ‘ˆ"ràÌh¨¤­~Ïµ¶¾ëq¯º“88ÉÃª“IsoĞÓRŸó¾‚)˜Ë9ìß~Êä@XÃš·±cy„ŠRtYv(YO ”O>R š¼î¤Q5y/ŒT Ëƒ¥Qï‡00›KÈİL”l±…fÏÒ\…‡v qq™+Á9“NM<,{Hı³S8q…ùÌØ5Ê£=Ó‡S(Ÿa^‹õï“…!”À©ÜÂ;‡æFŒfmª=ö¦+€ı1’¿ŠdHˆè;ôíPHl?¾¾	úa¦152<dµS•Œåm
÷².¥%˜ „äu'„ğQY©U Oâe—À¤*,MT‚eLÉö#¯‡WˆÿŠ³®·›l´ÀçtF4YP"•ŸÑ¸][theX1ÀÍºø¼{A¤óá–$Šˆö^@ïœ¹“^!¨ˆÊd‘/ÛÏJ„yéd ²HòSAA	Œ'‰PqFJu™åÚtÿ*ÎİŸ	ù‚Ä%nbGÖ€N?ÄØ†>—Ùm×$
Œ!JçïpV8ÜÈ¸ãâ¹ë{ã„Ë*7“¦¼ãİ:vO‡á.§\E7øÓÀ=Œ¥dRÉHæ|Û®ëârÆbã NÅ@¬ÆÂŒa•ú¦e:”D'S”»SaÄ„vì¨êºy·ªSèzú<géŠ“Kƒ­ş-ˆuW•Ñ²{·@nOxGèjYƒılc‹Òˆ•ïœã¥‚¬ÈÕfÓ41OeYé^¢ÊXãpÕ7fü')2,K%>‡0^Œ‚Ú„.Ôk$Ø›’RNµ1#½ÓêsÙä¾±X×m¶v ¬@·qS5û‹x±®ŞÛÅÄİ.”øÙàyµs×Ï º!!.ğû;D#×X¿€Š—šRfDâlòÈµúÓjS…éëûj¢!ú¢GMóû¼wv°\T¾­lu|ÉE²ÍÛ*a|¢íÁ­/²ÒÏ8QÌIeØ“°Î„çb'Œ=É±À:Ó}èL2Ã1YYEv?p~’e¸ĞqèxªÕLóVJĞ—ÄiÑêØD?d"¶üO*/¼÷åNQÔ&d%+ÏÇÛL†H6T'¡O1¾wï«¯Ï›Kòl¥MsîUG-ó">ëBè“,Ä@¯#Îz .¼2G†dâëêŒm2‚[†MBVÓÕnqLBÃÍga 5p¸ËG‚´ ˆIu® yô<¡sW°£ª×Íº+Uvy»Ëè9ô|x®Ü¯ŒMk§ŸDó‰ÆS½aLDÚBğW
¬Ü;›!ÇÏ$éELœ¨‚dXÊRJË¹jÂÎù8\”a{±ÒqÄ‡2­ÁòJizÅĞG{ìVÁFıïÊ4(­ç`Xpª°µë«¥Hx”9ëäªÛ¥Káƒˆ?_$nß˜l=_kvÒ§ÏÅ	‡ o'Ï\ÂæO¡qÎ!ê G@ğ0O}*=ÜûF¾m@ecÄQ&úí°bµG_Ğ"ÑâKy–MÙ‡úhš2BŠ-GwZcºå¶‰Oú”ç»cAÆâ	_ê~z,{{$c¿ »/ÜXÜà£X_…ìÂuä
f©{­Î‡AY¯HÚr®l#ˆ—LÕ³x+|`kĞ‚—çz¬=ÌèuvŠ‹ğ,»rÅˆD	!1‡Uˆ–¶–<™ %ƒLû¨Ü ›ÚßôÙ-'-ø<~ChK4u¿lü"Äü»J°ôŠïä³eJ¦ËlÄfEe™WÛ(˜Û ê£İº›Ò.Í%‚íxÚ0…øñÄĞ‚&Ñã€fNI‡¿—ÔÑ¯uEöHù‹>•ŞNgFŸŞ4¨ÉA§Á=B]îÁïz^%	LBDt–ÒbJŠ|XÈ#r«-öº¶Šh˜YäñY34Oú=vŠ³ĞâE¹ó äÌœ- A@LC‹?pÅ©•İ{?éä%¯/½»ÚU®Wå1üÑ(c*Ñw¦ôOao+Õ:í[…‹>:ŒÂ¯q¥:æIFfEfcÄÄÒÌ Ó¼%ŒŒ«PBùF©5áfÓrÊ½wOn\0tÍbÑ¯˜ñdu7@xóHbI¾$d¸©ÉßŸ8
^  ªßü\Ë÷G²å,,zûşè¸X¨ÿ+–wbŸÇn¼{DeúM$C‡–k ACÒš!)‚u7Ö	7C=Û¹0×±ûÊù"vt\Ä2À{N:¢¦pÃ–zÚªk…½ôÃõJ	ô‰ƒ5X*x*×à¸Û'"¬àÉİT‰MÈõ	áùšûÑD›•K;’„èØıEòÎ+øX¯Ê*yüŒËîkY»ÜxxåXÁú-(á/…^††İ+ËÎ§ºÙJÖ"9_*´ÀØâ0{"Òš|P¯0%ÒØ+Ša=JÔMß=<‘NÙq’ÚşFı¯e[Z¼ézÑ:à?§0vĞâû@†2ó^©‰<Še¡2Õ&ã`\_B&§È…_5áÉŞê·*_A×ˆ$}¾Uf­ê±20Ûõ*°ğêC’<ü’MùBú‘¿pWsâ¸z5"1ñ}Ãå7õÑ%™²a3NB»1 .CÛN»ïÚCµ+[b…xéLTY-G<§©Ù¿ ‘b4¦E¼Şú®«ƒÑ60›æ÷¨¤Ëi8V*ñª’ÂDêaáÇÛÂ¿UÄp5`*6óĞíò©3ì’pt9È¤ÿ•ï—X·O•¥$h¸éÓ8g‘è»u`ÏÆa8ZM˜†Ü¶¹ÉõxNº_¸“Ş˜¨ëoFkn.ÁÖÈFÉ7¹uÒ¼èÊ®lÉ©Àå8ƒšKsÂri‹®ËãàÑ“uN’–ùWÇeD4nD¾r„İÊf‚ıqXy@Ö‡
•gÄdvXğ[C7õ{óÊBKã‹¹åÕº²‡æÑø©DÚ£G" á0Ç‰Wöãâ’ñâD|çHì™»l´›ôC‹×b6‡[ë¸TU%Úì/¥ß‡±Ê-n2÷j\?çªÄ ëwâ¿‰]çFN"‘RŞ¯@0äÇaÊîlïg%ÿ±_‘%]¡vµÕºÖ²Äœ‡§=Ånb¾Ü	)¥=Ï/p$Úèı>œ[öİ:3§0Â.÷>MTVE
Y_kbÈ¨¸Áÿë†âÈÓÎÜş¯x0m$½=2ƒ¤%€ÍE½ŒŒ4J½™|Fçàx5w'˜½àr›6$ôdïn•Sò÷1/Dè‰¢R„¾mYTw¾#OµŞÍ<<šÓ|>!ØÌP@ÂÕ^şÈØ,ç¼ÎWL…í& B«}a‚5‘B6uñ—d `ÍJ	q®	V£~×Óei;¸aÇ†¸b6,á„Mãüã/jrOı5•e£íW¾¤U!é —tÿõ6t³CºM¯O'TŞÿGŠP#û•rc5Õ
¶ÆêTÑâçH²Ç|”k~£×ÃdöTª¬¶pHVht,:xêu“m:8~ƒÖÖ"á8Ê9B4F+L–ÏÛ„s»{‡Ø”è}¤å¬—Ájİ
äãX\öì‰B€˜
yªwO§çüî3açwÿÃ1oşÇ„5Ô(»úÚU
nÄ‡©2¦¾ò€‹ào‚çİyuÏº=X6io€eı8‘b‚=¤á¯íàW.kùƒ/j&K)Ê'ásÍKÀ ™my?ê;¤T¿h-ã…ş‚Õ"±é^ÄCz'­Ù~Vé?û¹¶Å®/´‰ç‚A¯pz„añÚö¸¸iœò­›úuï¯Â4ÙhğEhÖN¯Í–sÁ-êr`Â~lXy·ĞÇÕÖkôOïòDõwÍV£öú–Êİac,FZè
‰u¨œJ86:*¬ÃaI¾Ñ° Œ:¾†~GoŒó|ÇLOÜ={+ÃVû²@(]@A»‘9Z´ãæ‚Á.¡î@–fMÜ9¸(e6cÅ<„[UJYR-Ö`â#‰¥ÖyınDqİT¦HfÅ‹ lœT",Æì ¸½¡=åsù,IíCÿ“¯šŒ5-tûy1?šç3Öi²M–­ä»•šğÀÆ·§ûíÎòt&¯.ÄğœQjzO7x,o+‘×M'æ÷•bT™ÿp×îhÕQ§kò?7ı‡‘¡—Ò:mÏR¸Ê|f–´õÜ£k<²e%i…Ğ®•oğ:ˆjÏÃ2OÎa™µ+@ñ¦
y%­Ô*5ğ<6¾ìŠñ§ãålï¥¨kÑ­·£!{Š„a¬€Å¹–Œûº‚Â<ÎX2±ZßÅÄ ëaÇ”€Õ6·>DR¥*[¬mªå¸Dût´ºPwqˆ—Ë@UÖ€ù£Qdôäqj:(J(Œ€F•bÈğúÖë²š^™ÂáÄF;eûyñ®´¯ºwÈª »-Óé†ìö)Å>’!úã¬¼X+Ì}L"a%;qQjÒk*ãİ	?ùhnƒÚ*Wà±¸ÚD¨ğ{i
°nß*O SF}j3R"ùM?¸œz;¿Í¬Ó´ë,LI×¶naï"ÄihüÛP¿Ã&—£°²ƒ¢o¨š¯Ôà©FPyIß:e 7y€XŞgÿLf•EŸ
E¡ãA¹©’(ªÀF¡€àİğ)9¯¬w ! 8Ìøœ"ş _"÷s5¬è¹À)zíq­#±ñQş1ÊT4ïj|.¥|æ_¯@€â³ıt6/G”…Bßd%œGLÒ¾âr¸é<8€ìñ—fK… ö¡KäáAçŠğˆ¨2ÙíŞ'šÙEÀæIVræ‹f¾vbËp‹Ö%[ğÃa¹^~Ş?Ş*ùJ˜³÷a"–¡’h»(Ú[÷‹Š•&t‹¼ñIxN.méføÛ²£:+(Nª4è¹Úš¸ÁVzt=ĞèªÉ¢†ê7f+áØè4_Ã•f`‹+‰R-ÔsE£Å0H3ãşòé¿ÙæÖ¼ğJÀ,]Ø•dÉ5&ùÂï+¥ÛƒìU˜>‡!•Ëu¾Úöà©ğü[Å¼ûb{0 Nkµ>5ù ²Å,®§$Efm€úÿùb É’¨Bz-2	1ÃßÍ`Ôğ%(.a9Òô(€T°LÊ‡ÕÖÓ7ÙÒKm)5—†³*ë‹§\u„hÒ²Ù«ÿ¿òÁàØÖãì†6í¸c9=¸²P6ü³÷äÓ"”?s#êÉ¾÷.­_å¶÷¯ù£·Õ‚ğO®o95™9v×˜4Ä“»ãáô}NÑâ ÃÄ±?V7ÃØƒ)«ZÜÚÎŒlÍ?—ö€GV–cGŠET(Êûçˆ}l'Äœ´šEBÃíº»½-~qœÏæq–»¾×f•'@ÄEºN%_lpeu=ğ#I²Zxê`&t¾C‰{(ĞPø3‹’úÃ3ësmBÉÇ)ë’cÍÊ Å›¾3æß`şÎF’l¨Û|) şj¢¢˜ÉWçPõ-5öµ³RYxD¦Cú•K¨Tø‰1f	A{×2}âæã+:YˆĞ»¢lR3&š YÀ>/c,Ÿ¶ó*¤
“xæ&œáñjL#/é†š­0;ÑÓ}ª#ÛàErë×ó¿ru3·LWi Œl?Ğ ¯½¸ÃTfj‡°‚~ö´OÀYÈ°ÿĞEò`áKÆ­Ÿ?ÖV||kÔÈ–n9œk6[<Ù*‚&èrÌ6c~ì*¹-Ôn*
üq^[ãÊ½+a¢KÛéü¡ı‘ÔŒ>D:¥¬FlşùĞÔA/–Vñá—µşy¤vF…óÌ*üå›pKşÒ ¾»ÅÏ5s!Åu$l
oÚHa;³Š‡ŞYÛÛ‹¹bÎ»Ø,ôMt6ä9‚¸{ˆ¹Öó²/oZßt«ñû~EãSó¹{ÜH“5±5¥L’êÄÁåkÅØT´‰~§Æ,T#ĞÕ†ÍV k…RR-™ÍÒ€€ù&ÿq–Ôkir[t"äzõÌÑª˜ÔÛ2½m4LRà›€,]d<$oµR<ïËy²Ñ­uFQ£”¥F1Š ş¼æXt3Â6ø0š±kçRã8B…õ§LÆóP(|¢NkVÑ†e-v Ÿõ¬®i<)ºv·Ó¼ç×ÄîÓêßNËUü 3`8Î¹Ee|~S±@<"Ş¸(È¹†Ñ¿9o˜e¥/Ä3ó…;NuÄ¬mè“(†'€Õò6ö?8O‡€ÍF¿*ê}ÉmŠãê1âH†àu²O‹çWƒÇÚaMåï»[q¡ñ:C‡<Ïİ¸ÖçFZ!F»¸—æ>ÎÃÙÑüe.@f_¸BQ2òqç³ŠÿØuskéI[Eb¨ûT&{(AÄKK¶E^œ€ªÈ\€NhANcM‹ö9¼¡“*¨^5¥	¥#‡µos²+*3s?	k(sú4+ÙÏØ³½d®aq§¾d\H±gøÁûı^qÚX!l”!Ëè±ÓÄ¥Â`¾Ì*¯¡/×;U›'&q†ƒaìù'™Š¢ªè·Ôºy	¸ƒ.¿/æ¥,#ĞAğ<q”¦¾ãm©=ŠN&‰õeêEójÍ	lŸÅú“W+ZŸ´P±õˆ¬tÙµƒV:Ò}^’¢<(-£{1S1d{K²¼;H¦¡Ãˆ€í›º^éÍk¯0îâ¶ ÷Ò¢ÎÃÄÈYûO`9×«fÅ;&$à|§YB˜‡;eö¥‚¸˜í-%5èÕ—VoŸe\K»¦v‰( 5İy:H À´ÅW„ÔÄ†äê‹SU\mQ’´GĞ$	ôkë¾v°z™–Ò£+n)©JŠÈ¨Ê3÷ˆè£w0T)a¢èSG0+ËA/õürÜÖSœjnX÷qéì¬Gü„Ò}“ÄÈ½çÓ——Ï´ÒvHËí¬Ù	øÍUœìrŠ_•>8ß¤› ªo^¬/ªG2ZĞzµbEi&›9AêğÜ›·5™(è¯2yXTíB‚¼Éç¦g&÷´dnÒø?Jã½t3©“³‚$+•ìî£Æ'PÕÚ™Ë¤Ÿÿ ^ÈZŞ©mhP
«XïÃØ{/s¼\üg³œÔ£õ+æš$ êçÏõĞÈÎl!Ê¿Ğ}ŒM..;x|ÛùfêÑFßf&ëÉ|ëOHòÕEacÑròü@S¡î¨¸0 6šßõJfğ¢MŞËÙßx;X¤#½8ò2t&<<uıëÿİyp'ÂİaQ—¤1_œÄzüãò?„¥|Ÿ¤|gÁkü¹Ö“šwGó‰¤fîçq¥—7ªo¦J/'w`¦Æ} oÿ<‘¶P,ĞlwÊ›YÙ†š@4	µ.Ş{˜J­õWz{çüòßÇ5?Á¥/L1ç…A Ù\~H7‘Şà9.lç8Ma˜ß¢D½-š©ö]‚0\i¨%—·0‹½jb§³g°ú oŞ_Œ“ÍyUˆùçàÊ“¸j
+m_m“‰‚Eÿ\öÃ±±øêJGA=öÎ±™$M^+à=oy_açOCv%t`Hå² ‹-¡ä6$¾¨“j®ÎÎˆoMÔ~ëòzÜÀŸÍ‚Æê®ı¡p"eú€Ù¤ÆJš)EŸsc‰<PSš à’…iÇ^¿ƒg¶4øF¿oc%è»jï ºÚË05ÓÈ–ŞæP1¤^R°YR—£^=5)L_
’«{‘jBØ ‚ÊËg/UrøQ@öSGšó¼^î=bYC6†Şæ²æÓÂÊğ  1—H†€:µòtÇk<Ø7]Ü5uöûïú_½î7ßK„ó°À®õk‘|Š´S/mNR0ı-øäÃ‰-œFæF<Á£bÍ­!VyqÜëvC{4ÜÌEQu  }4mÉ–KÑ²UŒ	†”ş=ºd]@ø¸”&lb˜ŞÉ]dVLÿ¡·ÙÄA}fİŒğí¯†Š-pVXEá§,R@-X ÓSešüƒ“Ò½_~øU¶"Ç=¿¦MvNÌ’#¿“>£Ì³šY	øHÃfOó´˜Ñ"ğS’ W#4~™.Æ†ãĞA[‰™r/ø£f‰¸Ø•§u¼GA—øÛÀ»+bkó³-D=økÀC#î[e3Ò(0/…9ëE3RùÊñ‹Êˆ]üÔ¿~tòµ¹6e,@&„ìqß´}îåâ”‰wØÈXè¾Â¥èn°^şJ7|0¥^¾?qC¨ñ¶s_d:Q«î”×÷µŸ­¼ñİ¤hUkÚe	û§{7ßŒ’IzyáK{gÁ¾áKWît¸f›T6Ã‹iÅ¤ï*Ã†È…dıº•¶Uµ3y…Ø¦Ï%1jæ@x™E±z s§ı‚%4.œ.$ÿ¿îK# ˜9QS¼nz†²™L„ê&¥Ò7EEP4D£
j¤Á™Ğ¨:wÃÿS¦‡ëaToªòì•ßüzi€-ÈH‰’€ÖIt0íf\@c­÷ÄSÒÙ£fÕ¼ë(ãL¢„”…açÿ1ºgÖE-—ò!µ™ïßir7öèu\zíwÖrXgğêORµ!Ú)Ø·ú”wø@äø$°Áñÿ¾ÉÓ<	:´ï$£l•(jñJš4èÊÄwÚÈq±¢ë	È?NYı»*`áª$gºÊ­c´ ×ÿ·—ğ¿›ï;iİe˜ÎNİƒB+îq!†"ÈG°ùòœ7ÊÛ•KP=™e7–\)5<`Ì×Çmjæˆ×q?>m”m {Ìİ9Ü«ãÈ©ğúŸŞ8òáêV'îXŸ*y¨…e‰ñİÅy;,Pù‚ˆ®ş’hÕ	r£ĞöPäFöQ¿ûæ»Ğ Ú|ÈĞP®À¯ØtN"Yİ½pË]íLxÜïZÙ ++§nÖ58”¥lîEƒYù6¹ÅW±Q!æ(œcÍ’Êíæ äGç™£ĞØ“¶Y5$ÄˆT6*})hšb‘_'cõRÜj"JˆÔóc	${¯OÒÀñ>6ÂA,0;|*W‰#e…N-MƒbÒ–K.O)4yÃK]õ`Â¾ëW	c›××‚ˆ¢/dØŠfç[cÑP€s[Û»¶Gİ4Ö¢MASªU@n0sûDÉh)§9¹ÉËÛdpÆÛâˆŠ"ÌY,LKÚ¨;F»ÊX®ø²bõ¿u.½'|~	\ê+ìÆ–È¥›­(”ª@Bí'v†m?ıîg!ñ÷ ›>WàŒûVc>ıE(ìÉ4É}`líÒ©éÂ@öÜS²&”	N.M+µë¥>‰À„’¤éğ­Š‰‘Üû³f!åèÏ÷Îø#É¸FB<Ämö­³s©-Œ\ë]¶è×2»/…Q:óğzÏ”|Tãµ\K"6<gÃã=ß&ğ~*ÛF{lÿ“÷”|B,CèA ûé%›ûrH#VHeDå9È<åÖÿaYO–Ë¨Ù­ñ…ÿKBG^áı°yÃ°R„!p`±¯(8¶4¢A7L£w¸õ9•Õ@Í»Ú˜BäÜIä!³|~{÷S±©ée>’EŞˆ<ÕK—_K¸2èH|BÀsjƒF"8^•Û››¿_‰õXÉ‹–rØğ "€â FC$	ªê¢fµp¤ÒJw‡ƒÃvY`=¾óàÜ|”·ÛA]+‚U-~î‘
ƒ·(G«îy•Õ3¥Ëer½Æã¨™¬ø±ÁµMå„Ò™	’}â1t…è
Ífì9§Šoÿ DşPÄ}™ÍIÇJñÎÿ{×­#¹“8w„fPSD~º‡dô±% E¢Wâ‡HÀ[wv3Ñ9ÉvÜ…áy¬!ƒZëşL›u©ÓR©£‡€Îr] QnÒ‰‰)ø!x!.˜	˜Ysr°	 5ádÖqCÆË‰ÔWmïJ*}ŒåÚá“¦UÕ¶w‡ŒÆCù ½uÍôa[üíš¼ObbÌ´h'"Œå(DOï:¨ğKªÈ™'©<ŸF<±(Ù\>¢»ÚÙ›*óõÃÆØƒtš¾jŸ+£"ƒµ¥‰‡S‡zPùæFÿ˜›
]w¬½±f˜ ~„ËõG1@x¨©½0P?û;âíy52·¼?x’0í)ˆÅLDmŠ…©Ïä'Y>záU_¬;Ğ<…ÿÆkŞ¨Ÿë‰¯xŒDµù_ñÍÚ3•iáÆpÛâé™gø'£„^«d©ßÿ²HåÄW
áÖø›T˜èXe› ±ˆm‡ŸPó¶óŒYCÈá;õ›-Ò·i u¬á¦hQ«8Ÿ;}Üdâl8ª"l-øˆğ)Fëp´O%yı)6"–'h(Yó­ÑÖù©ßŠYÉ=Ü]vLsTÒY¹¸`ö^’[ı÷ÃÜ‡üD=™Äf{iæˆ£¦~¢‹Œp¼³#N½5êİr¡šN®,VÏ”{ˆ@&şæB
	ygûÿÆ·”¦\×ÎôuË›8WZ>¸´HÎ>«V" †(®ÙA×¬şïš<ªßjŞxDÒ¾S¼ˆ~ÄD¢©*-Dx¤4j0j‚Ót4K¤²èşÔ™Ç©™®	†¦^¨R½ú§?"Ú&|SÚKB¢ÿ‘{h\\ë5Ğ»a±#»¯ùİ¸ãã¿áv2"cá#ÔCQÀÚæFİÎ9„ıF‡¬@=j¢­——‹áÂC „ùóËG¯Bó!KÍ—œÿŞ¦Òœ`µ%O‰¯ú¯ñÑd|˜ğB]æµ•òj°POsûj´Á€¥JØs%Şr£ ×¸[B³ú=ÜÄC@c,Ë¸%hÆy¦ü.‘äÃtqøÇ¾GØ7WYìj˜¸Wè%ñq‡ÖÈàm ¥²]Dïˆ%¡`¼µu8úçÈ×(fu­°°«”!Z÷Áòì/ğbnàŒû½§,²´i@®qÓ¼âWÆú0Ë8l$6;¥¶|£Qˆ6	â6øÖì•Š5ÀİzèNĞÿ|Ç¬ïõÜ¤Ja;wCEÃÌ­ƒ+âĞ'ş5Tø-(_Ğ@¯‹Æ¦Æbˆíı¤=Öş`†DŠl˜vğ‘Vø³¼jeBÏQ…Â„R}¼º¢’yd„VTÚZº˜çpÌfÈI7û•Æa8Ù¬aCt?Õ"Ä-9Âƒ¿1A4ÉÇÔ™4ø·°*ü€â.†[Jd|éxğÑò0¸ÍB²_œüÓÜ-ı~û¼ß#• 9‘ÕüªR½òïÊ„ÔÒğ€õ¨ıCvñ}}"íu«ÊG‡aÌóHøTÅ‰Ú'–æKÍ•ùİ+? ÷Q™Cä
r‰Xü’§G4Ÿ,vìbÅ 
(¹âßÅö~Î%é0_2/åù D‰ã&pÅ±YŒØ›‚j7 veôñhD]ı2´/İD¼ªİÆunÙ¢…Ê°ŠÊTø½<›‹d–={jwo×ª
ó "Æ{Tç†øu¨ÊĞ°¨¢BÅ»],Ói¼|_yX~\±¼,§ıiôW³n¶r‚u‘Oj’€@KjgÜoƒÒªwP&äLœrëOö?¡)_;Ö–ÜiÙæ>‡7Æ¢à<F>dÇc·X6Ùµ@"\%û‡}èÌÜÙ+E?.(ìà¾p(f’©V5‘SŠÎ¡…z•úæZäÇFF:LG_MK,rhÿ¯9-¹„wÊ ª§æ›3éVöÈÜfÔìÍ–l¶üÀ6ZìØÇˆyßzò‚dóVn8ä¶2°öEƒ$˜.öÎ›ìp5…½z6Qê3¯k]÷IyÁ±s•n×,c¶/ÔSô@Lâ=ú‡Ê`‰pÔÿkSğnQ²X”CÖæ“¶äñ:İ¼‡Ó“%Ì¨Š£ğäù#ë#³Z‡Ù *@ª!ŒnŞà%cobp­€ÌªpÏO	ëGLK ¤É5$ÊSÀ‚ıl¬iÁÏ(-hÓr;o?•ŸgA>(cñÅ.ĞëREOLFğÃ¡[Ê™°ø·mÂRu†3É¨éó?*@‹¿q†ØTÏğ­øÖ…Õ3~Ó}“Îynµ|=å}Õ´ëíàâ*7a¦V=~fÇ	gã”ä¸­ÑT±œšËCqn€­òK®÷V¹¨¨˜Áb—/{†W.F—¨}%‰¿‹3®(igj6ä¦}Á) 6ÍqÒ8³|Ïv­Çnİb°Ø/4SÖ¡Q²½¤şXNÑ âNÑã·¨
ànWJß3Dú/2ê#¸úŒSi®SYâƒ5*HMö?~¥Cõ…O“Š°@ÆSW,l)D‹Ş/Œ\(l²ÜM³½š?Ÿ`(Ê•[Âé(Û´
@ı	şhàóÒ‹4 í{ïTUÃ«^§%m}0_ë¡çÉÉÒ¸œ.ÃÑûÂM µˆ—ïpnÆ"‡ß?ßÚ#ñ3ÂÈå/ZUÍù¸F'Íì\/{÷Ú[wMîx³²«aÆ)qé€CÒJr§Û²‚Ø2‹'çŠT)+URc³Ûs³×ŸÕ“¤YcÉ1²HŸëILdeAç`"8ºtjŸ¤ Œ;j”Šreb¯7ÕB¤pi5w—k›ÌägÓ×›•‡:Å¹£Ú¬ÃòğÁ§`±—Ê˜´:(êãì+"ûÌZĞK¨#OÒ„ï{İï6‹W,?Ik¾#•ËZIé¹Q[ÆÇ³sı‘–É~yq{[©wÔd6Óş£äá“Uê…À\ØXaÛ³²èjÃÕàÍ·­fŸ;õñ|—<™mdøoÏ1¢5ø8Öª‚Äó'<Ç—ãb·7]9´ÛQ â<DÀşıÔr¾ù	ûÑ$rVKsï¥İûM•´(ÂG¦ëÃá{X¯ö@:ˆP+B…wî×ñá3µê¥  É-İ]úç€1†ã·mA;–Í<ğ2S"›Î–™^uÎ’×bº,®ezÓc9fúÛèÈÏUˆŒÂRèİ°}Ú®õûÒ©±3õŠŠ;}Ãœ5ÂìŸ>y4u‰¡åÄı8Q¹İÁÛÖÏ–lõ	lŒ8·–2aßh&ÃNh$Q»‰¶(M#>ÜÎ"ªÕr¿aB„·X_¨]œ½ÁWÍ÷Sg²aŞ‡Ó˜â›ß>:li§‹¼¯©ş§EÜ‘C'µi±s.¥»|HB%óù…Ôfê0p>¾<®y„gÆ~
ò×(¯€¹ø\c¿w‡u¢t7øqï>0w4BwÆ%ò½Óù°í3u·
jê³A›>÷„q¯p–T¿(Š¢”!Îíp£Ñ•*’‚oN";çØyöºK#¾øÙ%ŸõÜdÉ(-AçŒ^ş0jğo™é‚Ï2 Rkçİ¢d‘±4Tïı§ßÚåéæ!èÄ¨‰,#Xs‚Ó/j~$­0áíïù§PñH2O?;ÎHYª-\=º£ˆË+,—­+‘A©˜~ŠQ0®*ö¹:ƒhŸÃëz>–KÆ<ìbEæ£¶ìıZšŒ´Sï1eXå#mÈ–\fßªÙM¡,¶ºN5ôÛ§²E’¡ª~¶f©Êc3Éà«ı‡=ç¡Õqˆ¿’ËßU©ğGM@.VUëŸÖ|MáœC=ÙÑAíª[GY|XOø¹Ú.¥è½¸Ä@)kë#˜ÿÁ"’ W'8œ×·Ì®‡11¼_fí‘(-íã†Ö³§'zNQx~ÊKÜ{àŒo—ñÊQI/HT¨µ4¿úóúÛ}'—ˆx2¯½Ã7·}…ä‡k^"Z'6²ïg–é‚ºâİŒ+ÌÒ•Q¿‚ìkÇt¤Wòİ}´µÁ–íª`KÜJsc±š#…;oDI}Úxã\b÷qñRxôGXe;34Í™C¹Ë'²RµÅC
©Æ¯*UßwØLj{
V
VœQD!È\8µÅÀ—3ú’:s‘ïĞlÉ‡/¼1&íT1kl:OÑŞ.Ü¡W÷¡ˆé)ˆfƒ­œÒü$ñø§ĞÔVSŒC­ûŞê@"Yo.ÙÈü2)5è˜üş«Í”¿áŞºh)-ì×”äK·	6"J¦•ªô_ş—(SÇ	R‘÷;:¼2Í“J<Mi˜tKñ0Hâœ²%é%¾°ç_Ò
àĞ´•PöØYoİ„Œ´?Ş4¢C˜$*pv@dëà¸,ÓNHQ#ïxı
Që<gñ“WÆ<9ş²ÓÕTàp@`“7‹ØÃõÔª Üş	˜¯lĞ³õ K1îœVW5Ù™à¥ÑXØÆ‚Áí§xr+…dP×kÂ@Cê#(K@m{ÌcHppÂD¤Öiÿ`9QÍ‘êÉõÌÔš¯HÃ+?Ñs—Àö:û‚U­ĞÉ<¹É–]m™¸ØÍ¿4Å	¹5À¾½¯ëVµ­ÖIçòÚÀd|}Ş2Ş,—êäÿ´Tx¥øè`-çÜŠMë—2ú/å¶ñ>E2v­â¶nÖ•—‡C©Ó¬i'É‚ÿWé‘ò.íİ+„z($]Üï/¼#“ÊÃş„şsÙÉá¸ïÚÇ¨ë™6nrûŸ@ğèI”qo°)×gaOıœ[P²æHã£kêw²5ƒƒ*4òèB0§û5–á7.g?‘É×¼)|–TüuTÁjb ªÀ‰p<™ë„F]ÆÚCÛ÷*hˆGğ-J3ëÊì†³ZRÍ^QÜ›M˜È:%ÚÖÅ•i­B¤,‡MM|=_ß;të1è™_tz¡ ´˜Ğ(ĞˆT CeÜYÕ@»õ5‹ˆ)ÉåXÇØ3 »w ¥ÄÕ	ÛĞ´´“Ÿ*ZyÛJà±¤ôY9CçŸÈgeü,£+ãŞä’¢4Œ„Ö¹ƒaØ„Ï§3¡.«çSÔ;PÎhµqO4àˆš]!àØ½Jb·äoïpD–¢k‹DØí[$±vCÏÓÙ@ÅqõF÷:¯z•ß†Å‚ÿ(/­ƒ'µæRKõSg½ªqãP-S4.œ{ny³}ö¶—}1=¾´ÊKü¶¦õ”%ÇèZ;jëa ŒU{ET°*ÅCà˜æjZ/èÉÁ1"PÑc$¿#ù@Rz6J`*‰Ë•š²~ÎL¥Ş ?õÍà¥1ºIlâ¡mÕàˆ»K¼ºÀéØA!R¢¸.¤æ¥?B0Ú¯QN\ãv2…5×ÑvTr´‚¾›Pä~‰›—RrâqÙ…«à]x	€üğÏ nÖâÜÛz¨–[fı¨Ø˜­R6úJ?EcõÖ hùKå’3Sg’³Ôòàİ7ÃÜ–z?nÓ‚ñ‚ŸàDJ<´ÁªòøX×6ÚkKsB{€Ä„õ ‰lNy™xd¿ù@&½9Õüsƒ4¼pw7î¼‘‘@'JØ–%Ù_ùı(¤ûE…yB9çêafX(¥çcšIQ¤çê;ÀDÌDC`.s9ã)]çˆí{6«úc`î-wM°Î;[2Åw£Oøñ’úÌ&wYÏ‰€rİòÅñ+ÄˆJÖı2èÍĞ§Î/D›¢BpíôCZÅ”€¢”"Ç2ğ™èÂú}°±Ü?;ë„RÒ>6¢Êˆdº5«Î…%PK´B{ˆzšŸÀ—ZÿŠw§Şâ²…=Í¥³™ş°'H-­ƒO‘¤ üå‚'`y•pù8mÏÊ;†D;-`ÖÌ‹t,¢¡^»Ús‡¤~">©‡•&ï<”°"J:&E‚AçöB!8ıœúm˜Ö,ø‹“B-…PK8ŠóqÔL-Êqú“Pßš.+³e¼£ÊO½Íl}ˆŒ®K_¾ú¸¼KÓà_ã‘uà¥ğÅşê6’›Äà½ØÉ­µ¢€¢)‘z{«‹~©ÜBãÜxØo+‡,áàõï76Æ*±°9Ã¥“£hÓà:ºãéšíîœ^Ğ•ÉŠÅ8w%±'øÙ®ª›ìmÀ A.ôíòøÅØşYas=şÊœş1{}M*HOt‰I|9ÍÁgœÀË•ÜR®@ŸÂQ¡­ÿöyhjÊ`óbh*÷O_1¬ïÍn÷»µU°œ¦”ıÒ~4ƒ¬dÃ9%â£†K dr.‹<°tHJÈ¦ß>Ù2¤¥7¯KÃ‚Å”6ïŸ$ıÍ     sÜ¬¬+[º ¹€ øëÉ±Ägû    YZ