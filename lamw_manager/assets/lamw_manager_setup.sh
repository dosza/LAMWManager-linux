#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1133053987"
MD5="49fa30ca5232154daa472e9afb1f0fec"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23828"
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
	echo Date of packaging: Sun Sep 19 00:13:10 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\Ò] ¼}•À1Dd]‡Á›PætİDõüÚ4ë^·ÒLP4ó·-:äÂQó0ñ-ûsÒ•Z`›ó¢<ˆGşc!VÑ©«­×Ì–HËÊl©Ç$¼°«.OS]ºLù^u‰IuTXo,ß#å2•=áNõ ò©Q9F@†vMİ½ó¿~öÖ5@•ğöİómU¡³£iû¯4ãzØu‚}iáav*üÛğG·™»†,- ˜G¢® 6’u´…u õà–ã1ZŞÒZDc«6÷8¦´—˜
,rÖÍYæ6ûxqí1»î"/4í¼ÉÅ¨&kiªŠ$`~_TˆE˜ï"\a£…¦&×ÒrÑŠàOPL>}Ä‡#%ÀôÁâÜKû£±œÚİÊÖâ§'Šà>ítZÒ z.›QÉß=w[›´æŠ°@tjˆfµQàe‹q¶sìAS¿L&Du¡õñïBZø%E¦gÜZ_uÒÕ„<ûäH¬Ÿ|“ÑÕX\sßT—`tİ¯Ş’BÙÓ“á›) ;‚Õ­Â÷üC8ß ğ±ä;¾}0‚°-g6é§¹a±Ïæ¿… T¥tJ“Å°GŠ‹Ãœüßƒ¸tb˜}Ûú^`ôÚXawñà8gm+u‹›k*Ïj—Qƒy€|bŸ$r<ğ=~9yß`è|:ù*vp¼Ü ôö³ó^~ŠÿÄÍ,´O*‹´÷ô$CutÎÔÌûûFb?n‡P'HÏûùW úÒbê Üß/XT*±Ü!I{ØÑòi
Vcÿ a°’oÏí%VR-_ÙùV	RçÚôºŞßóhÈ EG®ERS¹ì´,èüsŒ©úmn¹>½ÓL®—Zr
sÚ.µ¢Ù	ìÈÎÊ;–9íÎŞN³vªuÚw;Ÿ› a&²7{Ûƒ®JÆÔ2NÅ5ÁX³2ù.Â¡Ä{çZI\RcÏÂ†ñŠ’—3$uL’€$®¿5!69yñuQòösë:z ‹ÆÅÁT,â #ÚÓ¬êK¿½o­$L‹“Á5%	èû6fıÊ'„.	õ’ş½[™Ö.‡z©¹¹•e! Î¡n–éÑã_m‰¡i¡Wkï4Aù/‹Ş9…äylá¢EiG¶/à0ÊS¤¼Ç’,æ„›‚‘>u§…~MqR‘¹T›áª|­F²Ìßn¨8+^**”-29ÂejşL²„’œÑ0Ñey$ÎEôU¯…œf£A[]/mó‡ÒÒçåœüaŸ4*ñ¾Ÿ:èØ¬÷ öfO…^×píKD<E,¹]~ÙÚ¯ÈIJ€úv4=FwáŞØ†ê™6°œ§ÏKhÃšÇ=¿91«wKË2ØY	(%ÒáRè!ƒ©L'·{ô'ÃFÊ<TšuÔé1õv ®\6íú¿Zq/Ğte4i8;=áÙ+6;“ŠN,ºYÓ|‰°Ş3ú	Ç+[?+•æŞõ:¶ÕDŞiñƒPòpÇí_qˆ£}Ã5ô
Ö5ÒóÕõlo”ÖßÇÖU^uíØÆ47Ác91>LşÅ3*Šıó¾·I•pã[‘#F)ÉiJBnrÕEÏ@g5ÙÛFÕS+•;C{ÊL}Ÿ×ûÅ0
(™#I–."½3Á<Ç+zY”Bó£Ê‚í¾ØØt@\cı-D0¤t`o›'ğÿJ U§DÉ¢ŞÀg=cÃÁ[ Á5ö:¢ö¹É	—B!5qÂÑuLé>°òlCçP€ÔAçñÙÂô•µP}¤Ö¿ÕW \l½›²1º^]o>ÍpÑúê§‚mŞ÷SF¸­U'¶ŒUƒ™AôÔ›RÏÿO1öT€3R2‡ñışBÿ‹%ŒzÁa|?³•€O2ˆX|æˆgšÁ„Ÿh\E©ÁöÆ»úÛjüÁM©ÿdş@6ş@tÃØ›ºkqq¾ì§î¹Ff­[<®HBÔgàbIá¾Ìƒ~e^üŸã'¼Ï 
ê`Wzò®oPzá€¼?ç:¼¨Oï3tA¸—ˆyå D”r?”X¸Ñ‚ıöMsŞŒM˜Ó"[-zÉò$æœ!ƒ b™–ûdg”$Á_ğ{aNèø1<lÃG;Ÿh(_ÙäöCEL$zá…KğatŠ<:ÚÁµ–É;Ï¯^È}èÏY>NQ2c|Æşh\â&Ò½)ØO–2£PIwæ¢‡.×-ÉQíÚiıY¿§¥ˆ’Az‚í‘èñEf¶¶7·¡Ø~Ñ´UöP¹ÿqê5½$¯Du¾!8÷Tf#ØE-…ICù¤qø´;zq?*PLTX£r™ï—Ã¯‰s
fœ7[‚”šL?cmŞw‡Ş¶}ÃşÕaï¾V›}Y˜Uy•¾\ğ2Y£:³GX£I4ÂZ‘1ê†¨¦ƒÇFˆ»gšA EŞã#ån£÷+»/ßÊ!ôÌ6­ŒıƒÃÃ,RÊê‰,Ø¨¾KŸ˜´1oæ¤4`?8*‡¡RÀ–ÖÕl¹Côõ;sm¯7r¹ÿÎoOïÅx³ç¡»¥Û£Kt2•Y('‡ÖpICJ5p£Lø–|Y@X½66›KIÛñ_°7aµ«°”ƒ`LRbÚÛ¼€ÅHÁ=HSAû}¥)`¦ò_!mÓ•˜]ÚjŸ=±Îmß	Sä¥ÛùºpŞn…—¾Ö~M’	7‚Ÿ	ãî3_Ì³=ÎgÙ€ÿªğÂÒ$I÷1Nt1Ôˆ–µq4·ÇAˆ_}FÕÎÙùdd«jß Ëÿîû{eÕ±pL­6HRSº†,’.ïÚ`ºÊºÓ@ºøïÒa¢©ÄPû"|	ãPÚş:~ã¾ÎÇÏ„H½éÒæéö÷GUÇ¨®™kâ¸C p	vÊ­ü[w`á|·‘DÛŞ¥k·R³Ò<O=]ğâiS˜i©Ğ+PXºK“üz	»ãÑêâ¶:¢èÁyŸ'}ß'”iŸÂĞI*}$Æüè1|e®ïõ›Q£=ã™2˜A³âÒJSç,Àº®(şÉ6IûÜ×0ŞdÆ²$”³#åNJ‚R7e¯µsñ7pøEf‘5Û‰ºßñ‘é'÷¹ö¾Ø`M3éòe4
½t ­” úax³¯HşÇ{IíÆ¤©1d0‡ú!èÚØé›d.©	µq„y3Æ¢ÉÌkM?ñÍ,DØãWÙâ×Bóöj
0‚ˆ(ÑŒJ8W¿0³|ÄT'<Eş‘2D,…¸‰ü;Î!ÕshÙ¢RÇ:HÏÉc2Îf=
¾ÿóLÌ•ïöd0‰vÕäÏ>6|E_NXÿ?ó:‡TÓQ\‚<elú‹5Uğ„‡n”´h{,!ô¹8ÕÒŸ¬gõ³µBòù ×³P^(‡÷T+±ôÃè¨§	²XPê^ÒØ‹ğ67¹—,>"ªf|7àcÿ„‘!g_Â6k¢ü%ï+mRèÈ…¡¦YC/èi:áª2¬Y`oÏ°ñòİgkj'ŞÌ]òëŞ¸nr§È+xt§§ØÿnœÃ÷|±bê@TT+íòÃr„ï¿Šƒjå^‡6;ÁQß1½C+‚,sé/ÙĞ¼2ÇÁoÙÔTÑgD¡Ãó¡¡¿áU&Õ²ø°÷7½®GªƒÁ9(ÉèL4Ü(ü$VÏ0¼DOR¤ÎÏÛKI~Äá¤¼-Xè«òo=ú#1ƒT3w€u±f7L…ˆ×uxçÖœ8dõJÖ&c¿eÉÚ@/
¯¦Ñö†xIš¹5ŠXkìišg°¢ˆîñ%‡€<b22ÛæKıˆZ²‘™›«çVâ+P£Ñ±ë‹ŞöKå¹£‘äÂÄ2”°”šy
Eçw\N¬ë¶8?Ç{hªğ²<õd€ºË*RF.#õŒ8ÎNUø®-‡K×piß†;ÛÖ‘ñŒÿ¦ría¿çTú^JGÃl™$>£õ‡`¹2àEçtÿ [éÒO¤wBN5×ÿ°
ŒY*RP¶NOSî×»s­ä*Ï,öÄĞÃS±5¥„JY#yVÃP¼İIoÊÁi–2ö¦‰§·¾ÎÉ"û ¨ÅóøËı¾Fİ€°çéyI.oïß=)Úw;]Á jMÍH¢*şÂúóŠ±­Húü&ø¼—ÆîIÀÁ›)›-SøÍD‰‹‹.©MÓƒéRämtŒöŞµÛNlm“S]á»Ğ	b0-İ£6-Ç&…›¶÷©büèãNAÙRYëXjã\RğÈã#-¦!Éƒ!*»Òìöîs˜<®#Ÿ0àèTW—ÂêøXÖÙZÇº)Ef-lßD’Âòö$dê¯¹óë«I%€s ¬Ïç.Ç·€‹Ø'd{'hÛÖ*´CÁYB½Ú)Ş×ÓÓIÑ“Š:Ç¤œ'ÈŸ|FXåéíëhäüÜl5åÄ ˆìån+xr&Ğ ô¬¯UÃ)¦ OıçÏºa%C-;ûPa¨¡ñı´Júÿù‰0ÂŞæ „®Â~±É
Àœs¤|w¦{¦÷m’ÌÑ÷ÒMCé~w‚F=›×eÄşn^+òÿß0ÿ`šNOi‚Yäé9~ÑçÜ„ÙàéDµ"“ßĞš3W°”ÅK~Zm^“¹ˆÕÙşxİ9ÿÙxPfşåyğ»Ó)ãUT#>Âİáöÿ$Õˆ™Hô0uÁ[oympê©¾7ïã§q3&ÿI@ÏÒôÌ
IÕË®j;$Ù„è2ÈPÈÆô¥õíœ,t‰ØtÛÀe^taÚõ9$BÇş;–œ¿O¨¼+¼ebòì6V5¼oÊáëù 
÷c§4B5×¸¸(ÇİË
ÚqÒóUlC?EôÒİ ÏyÜtÚĞ‘¡voùâËd|e-qğ¬ ìm	Íá¯‰ÆÔ›®¬gt ¯¥+§d~NìNB—b‹Ò‰¥ÀØ¨Â‡Û®ä&:)˜Ømèp&~ø¦Ùw²6ÈÌIäÃYœ·¼Ìu+«I,ÏpÁTÖÎÅğÌo“§°fhƒS†ærÚ%+ˆ{êØ´0‡<É—óŸ+Ìno¹yŒ¥\%Ejª.=æ|ú«”µw¯
, /æ3óí-ÕÆijbhe5´Rw—z)’uĞşg¨…„À3MNµ;§[yµèmª$Æ_&ùò-w–„ÕÌjÍ<Ç®°mSÒË¦:ƒû ¸«‘UºŠN|´ÖšpG)ä@ybùû¼‡³tfø˜Á@É³àf…ÖF„Áo¢mˆ‡ô?KŒÒ¹®M½µq,–¸è3-„Ö|Ìª`•+U&PèÔ¦»2ÔrßÉrğÑI5»æpaFê(FoúÕ¶Ü£K€dÖzåÃ¢0#É%¶Àğ:ÏÖ(ğ-aõÉ$#H¿Á¿nãÅîÇûÜGW`¶Ê´‹HHš¯4ŠŞ˜Ëp@ÑÊª‡¹äá”lyÚ ŸL°×¡y EüC€¶:ÃH?«2lO¢ø·ÈËĞebe}<±ÍÕ:äù°PSV™âúHóıA!†l~vbÕÍixQ! ıOZa¤F³ii~Bw<Š1ŸTüŒæPıãÀú-§=2­Ùœ\ï¯Àû.äh+³yƒm<‡Û‚á@T•‚¸WPA‚ì[{œ»vêf'ÆÅ”¶öEX›hy„øïßA¿v>Œ­Õ”ŒÈL£†4Ø2½¥Vÿ«d9šeIé ïö6ï¤ÑiÆwa1Z3ŸÓšˆ+»ıYV£½'—qd =ëVu¸nsW6‰YÅ”[ßéÕpö,~\6	H¤æ¨ıbOqqÀofYh˜bÓf&c_ºV<[ô@äå	öf(€½øÔYˆìó¯c7T×¸X‚lÿ]_6“YL.ïkÊa¢€^1Xáá#“©÷iÌ$Ñçä»ÅˆÓã6‹J¸ÉÃ•nsó_(Å•`ù^›z»3@‡¢ù‹'1ü!„–û¾ "¶ÈyŞÑIĞÛ½VháÀ ]:÷87*ÑÙVÖÂuş¤káª„K¾_%ó;«AÄ×µ#1µÙ¬„Õø¬#áß âtfBÓø7ÉaWëÅ’ dÆD‚>ÖRai¡¦¿ÜOÔ¾ìeÊ
Ú¬èq8ä¹¼{ĞÂæÑË†êøáØ(Lá2˜Õñ®T´ ^¯øÖâr‡$g]ix÷&he=U5ŠÌ”¢«ƒtkJ)NÅ.@¢ÍP‘RŞ¹ûãCŠÓ0üË¯alaÏî´MaµFÍ³µÇ8Ñ›xş&½öëcy\…Ö}<İîòÖ©,§è”`j«åsçïmÄ¶%ğ !×ğlêaåÓ^;¾¨"£PfÃ¨æÒMh9¡İfgÂ›0c«ôÅ–p¦(‡#®.—‰e¯Ïµ./oôp»ŸŞoEà:‚3^ãÑuŠºÉbJd’cÓ*ûä¯íUVˆ …·îU§³–<â‘ªc˜9*åÀsE\È@»‚Çº+	æ÷DÉ2Jd G1ØLMşnjùÿ	IØèÖm•èèîMæG7ÌÃrGOñJ¤Şk¯è]±¢=}O{Å¯Åœû1am” )ã”¦~(JpãéÉm€ãÛîh›w–3¢¨9¬`ú‹Ü½´…= Dp¿CĞ<t×cXá¹D¼hª€¶¶Kã¾ŒÍE¼eçß·—ß²sKà(ª—ûõ$¸­o0’,Fó‹V'u5ÆÈjEs K@Ïj™qš|0³ğâ5aÔfr‡g@ (ªD[,pÄÙY>tÜPy~V¯k1;–Tm/¡E—Ï)ÿ»ëÎÄ™¬%2‚uåFgîº0È¦¶L—éÅ®l~”£´ù«Lyëƒ9iú©ğ÷LzúâÇ|;:É:^h¯š§ïìgÚQ‰Ä®`y&øŠÉºÌ¹ì¢UÕßp‘âäó¬b–mjFºì?¡qóÖÉ´Ò¦òæ-±İ¢{Kí€bÎUò¥ÓF?øWÑtWß“g]{Rª‡»K½çöaÉùS{dH†A&$ÆÿÌĞY±oÌ,mğÉıˆtÂôÍÕçD†ò–b)”÷jkéK,É\•2¹‚õyÛ³o´u}uH¶¦±W4¢hÍè6¯£l›A[UOZBÔ²1³’ê|±nIãùÌP’Á‰ß11í¯kÍ‹ªŸÅŸÆñCåˆ™ÛzÉrÆ`Rèº‘ï¤NÓ¿åºõç°ŞÎ
öšæKÙÜ½µ:y4*72‹ÌO¢d>ĞA
X« ­ìzéÆİüš{¨w/î}(ÓÎ.	}êå†¼u(Øïy™Ç>­|gáàö&ö(ğkç?‚D³›geÕ€‡	^vñ3/l{:¡(%ëKOÿ\{j.´Á/o½HÍ«ÁÕQNÎš"ß2¸NlhcÄ £äF¶È·üò,l›D}n¬¼RÛĞGìôvÙĞôİ›½HåBçÄ§GNW™2qlkã}|xÚG	(ÿÎá³ÍTù 'E—¤Àó‰Ù(WÛËe™P£lßG“<95,·¡M!Â©—’¢DÿX¿‘y—@¸šxéñMãÍG¬q¨³¬gp Ošhh§ï+Ùeñóİ¯ëƒ4.êŒ~ AÃ°ê0÷ñAv…Şa¼¶Å
!dW,aPi¡·9H6o°|ŠÚ}ÖßÖz†ÛoU¹:á’æe:†ùUã×Ä2•#FYŠÄu°!<\i–)Ùîñ™°?—ÙoöqT§Ğ•R1l¯‹‘½Rè&î“àÏíNßJ¨ˆïıÉ¹LØ±Ï^(¿ŠÌ9—EÖ÷°ÃÚã½ÚY{¯ØaPü'S®®=¾ı:x×j/zdIš™FµÓ\êBmGH¯Òö7İö/6°0´¢,]áİ†—ÅÎğQ½+B‡ƒ£ğ*v`÷°IfñıºÉ,ü3ÄIÏ£˜ØœÛ~ÿrÚ@åø®ö=·ó ş±g‡c¸µU“ª‰@u^L° Gq=14‡7)gÔ~ßÍ¼"vFÊrK¬+{Ø¹¾qfhÚ3NöSßÅÚğCÍÖ~söëÖ™ƒ Óô+[èbbY9<Ã²%ãoZxÂè‰¥ÁEõ‰ğË‘‹KÂK_¥pÄÌ×=3.kx¼ÃYv—¥$¤8'¯Hªİ‘°K¹±.ÕªŸ‰úìbÀ%-ú{«MŸÎTÍ9õD†Ÿ4²|-L¾T¼d>Õ
†ÆÚ²n>…OÉÄä’Ä‡ÍÎkWŒ‚_EœÑI
\áuš7ÂÅñdà)ånç~*¡Ûœ¿OÒZĞ#Gàù:cÌ4‚HœÜ‡iâ6ˆ$À9ìøª½µ²‡CÎ´ÂÅ6Šb¬/fÚñÙ5Ä)Ï #*”‚%u!Ör”]Ï½?¶éğfå±ùƒª	f^û†¢kŠª†Gvf$á0×æğG]67>}æz‚yşÒYxÕá?šècı2"r‡–XÒ6éÌwIêØ‡æh4r*íâĞmù/ä‰¤¸¬9¤^bbfSd÷êó*¬WAöØY®?€TÇKÍ¨ëÂ›ä€Qgñ¸º÷ú]„Ó…Z½ÒÜÀLKáÓÈ«áèí$ÓQgÑ6^ıoHZxD””˜5äª¶ù¢‰è=VßYU»ÆúØÂ×ECÀ9¥Í¶WxÚb;»%¸§İ|RñÛS%Ü±ìpûíK’Õt)¹—äe‰eLË¸DéP+Q@•e
ş‘GQI¾vçéqlæ¦‘baE!=C„î”z62®Uw-’öüEQEnY™c2C¢Ï_¤1F<ùİ‰7o5€*ÁjáŸd˜)uíb^.µÂ»Ûƒ˜–p-?(¢iqRG2µ›äıßF"¨=ùùsş€õE¥ùw[Ís±ó “°8Ì¶;%X>hKµÎ÷„#ÎíÅÔ†Š‘»ğ¼8Kè"GvåË¾zĞbÓ+âtÎ>[ØÛ\èü×ëoeB¯¿º•¹¸uÎ¦¢*şu×lÄåøg°³Àù\^eÔLç˜Ï B9kÇ™ãò­°Ó}€ÀÃ‰ö)ÙËh(s£–NTå-‚ßÓCiÈDÕDIÂ¢?‰·!ºE™;K@A²ŸIl7pó0ÔÈS—“X`fG
<÷óqÃ®³¯•LYvpD¹I«"Ì‚£~ıvÒ:Ñ¡Ár–Sº$3‚˜Ü|<¥ YbVÆï´¹ñÍ\3Êê:ot½¾ò×‰ÖãH	:;SÁ›¨9ë§ëZÌò‚Yuşµä#í§qÀ¹û±ä&÷œ;ñ©¢vò ?‰šÔÍY§G=êû¡™?‡£fJOq8¢ÁCuùñNUÈ3±”PíÆk»‘e¤By&IªÈÖ?…âN&š`Ê£›–ËÖ6—–é¼ûIÎ©Y“<€H¸0£q«z‘áÎ–>ÀT×³/ø Ìn"ğ|1f˜J<|q*¹Æê{!Dë¾Î)òu{£—ì>¥‘%ET	^ß+e„ãnÒãÚŠõ?µ±WŞ²Ì ßÄ¨;SÆ"ß-LÛO§M·X”>é=yPßç¯qU’|ş_Ö?Ü9ÌXÔúÈ‚şc²™)­ÅëOwÒ7h$íAşÏ¢Ä´„,ÎsÌ±5“AT÷%k¨1ó”ÌìÈÜÍÁ†Ãõ¿ú­nw)lèÏ Õ 	xg\şl!nn"v+‘Q‚ı"h¶ÖèZï¬øµTê˜¿+ê ¢Úò½2¤.§ÖJ½Òu½d…!£²+°_5ŠœjÈÃSõü–l§!	¯ÙÂ9wïbã°\i<ôÈxãö}èL*Ô-üßƒû<ÇjPÇ‹0J¥'L`/&y%H€IÉìÓtĞg(º‘,®D"=õÒP˜IÎA^Ô—Y‡ÏËiİÔÈ® 9¬Æ‘ÍI,–±Bê	këZ¯I°ùç×ªTRğ`#
«‚LYºëÓó8sæ‡>bØ…“BÿÔFğüşÙQc4BÍ´£VÒ,ë=×Üs:•E»1Ñ€ãtÛL=ùX]jÊ=Ì©?6®&§Rà£c‘ J½Œ‚ygKR”6…+ı“%êF))¬Ú‹ş‘S›ÌVU1SUå[…m%Ì[ `“a‡@¢XÜc‚¯ÑSì|÷_£éF˜ObI<è0
”a‰(ğ%ÁNÕL¹i±
1=Ã«Å>N÷ ¶D^MİÂ^ıtú1åDÙ$ t-jÚFaÏø‰m{†Ö¨ŞÃøgÆ°¤ôW¯ë«‚)˜¾Æ(vbøi+°İ²Õ¥°6Ğ¯H5‡èZBıcš§üw(ù3ßX+*ËjÊ«Õ†µE¥ãïÊ¶¿â™;y''õãîËAã™5F~Â/|IcŒ#r˜”H¼”¨‡uy9_É$ cè£cJ7›~ı hç›ÏoyçÁ£tPvœ®eµm«âİ`Å^@’›üø
)W‹–5ÈµY ¨“°¡‰&x0[Ş¸ÇÉL¾hj­ıTq.(Ë%	÷d,ºÔØÉüÒ¸ş;´ã”S=´ƒÜ\›Z+\.°ƒãsÙoøı~ÌuW²Õ Èÿ±À®Ún¸/›f`='bUˆfînE®ª³+ñk€4bC’i/+““O½±¬]Â¸[ß£úvK 1ÓjdìùÎ¹„-şÍó`Áq¥¦ÒÛxm´’
rÍ@‡«š¯h<İQRe¸½~Íñÿuvü¶‘¡œ7Šè}£G×ê¥Âı‰˜ÂÿØ—İÒ}IÙXùğâúÁÒ²Æ‡ˆú-‚}ÈÌL?íïÍŠ¼ ŒgYOüº(Bøjùì¨˜ˆ~Ox’ÅV±ûCÄŠÄ
I`]ƒ& êó&$ëF‘G!›EL(AÏ"[:áîl+ïŒÊ/ÿ	”¤À¿FpXF¿°€¨Nk56è¿³òƒ=ª¹49Iò¶›±€ø“ğ[Uv4G­Ÿ.ÆRkÑ?Ék½;©ìCŒTÖš9æ‘Ò)ÜcsL¢¡úc]1SYª˜Fò­`¿EÕZr-J{ÿ9Á#Š#¬L ¤¿P¢Wµg9ãm§BNá­^§Õ*ü	ÔKÂÒIiø£7™áIµ|*<L'SĞ·Õ_¾»<"T½ÎãYš£ñ+`A&Dö-<X‚—Ì¹ä˜>öù*å(ğ¿J¹:‹¨Ã6z,]¾Mº™	/gïŒıÕÎvY¡ÅÙzZ•[\+«î2	>]è«$­»£ëRÛ‹“÷ú·‡tu_Õ[$—×y+¦¾ÓOöñq¹"l#v-ñ ªãhÀ]aXŒ“*Gûé˜‚´»ŸØ…Â¢r»ir~59¥t™„aÖSÉñQî(`Ã!‘R¡Ó[ŠĞµç´ÿ,@D?[bİ7,¾)½áljá¡/»‹÷êŠp¶\Vãm…oÏ“NğXÜ°”½ë3dÌf1°·ã×.:%!¢€çÁj­xìl©ó¤é8,@ÙäëÄ(Ü6¬zÛâE·ÔEÇÓêí­+VÀæjD{y$Vß*›@Á‰3è+ı†¯GÕKZ×ÿKìó :qnmê|rSNôO‘|B„.dkpş
“UÄ÷Æ-×íp×+{j]Ü™ô÷£¸Pí’Úb›üúCˆ­Êê?ØH²Yî¸ßâĞ?tGüX~\V–f \¾ôêxRÊÕ§¡óY{Ê¶ ’Øz³N4]dİ ‹ˆuQ•¸%Îv«P”]Ñ1E@Cé¢œ“ö\—3)VVSÌ	Óõ?|~PD£Ëöãø¢à·’U×7è pC¥l¸óÄ\l?æ“FÂ:¾î `o¨Nå2z#=ì¢ÕÉN}û¼-¶uU¶ğ%,`1dÀ»û4õw>Û? ±¿0àÅD4ÉƒÃ,¶˜gë-×iÎ!e9_H–ül:œKÈğ‚ÆW?¦[”OW©í3ÿíÿ§ªş!.
Õ£%j¤õ§0f’½Öâ´(Şn[9‘°(¹vÒZ`ë“#b÷Uƒ‡€EáCÈêÒ!Î7WKHåçâÍq®³D¶³´Üñ‘bÆ§Ò–©'ˆÂÓ_ÖÅt'´ı„qu "œü”ÆM«Ì©]¢¢QXÚn]@÷äU­ğ9¯aØ´çÙJõRH{ğxG$CÕNKØ}GÃXçW'cª‰NV…ˆ?Í˜·O4İëyÂ"æ¾Sİ-¡’°ÁÙ%şyPœ*>¾†† E‚¸ú³¿»OamØBz+:¾”¸„-¼¬'ÚA7±w„õŠÎ¬Ñ=É})#%nbN˜_A5&»¾ôğø*ù°Y\I;*fIé¼F\ô(«&¸æAóƒv‡Íî!M‘kW•¸#mÑc²ë{²Ù$Ç8äéğÂí§mª Wò¼{%¾ò­·G.,[3
–¿–´0ŒÔx±¾ûNy…ûäˆÿhÈßöÃ;È249MB‚»ílë5æJ@yÔ7! ì¯@D!§êQ˜XÜüï°Ô=´ƒ”ÖSB-3£~—ŞN’‡È B±ÔÀ6ì&æ1ó	¦KĞ qq\‡º†ş	‘ï¨IæÜ¾Ü¯Uè
³Zå”éSc[[—µ*YAŸáÛ:óŒ¨ÖŒâAìB4§¬í$ÑĞÔÚdl.I4Å~4 %"s´oZP¿‘:ù4•x5Ö;GxXFd%†+év‰"Ş_›ïä>(”ÖhĞûøz*ó‡š)Ì%§Ò¥ï~yçELºè9ämŠÎÈ~*ö®>Y?÷",¦ÿ*WicãöûOà³ßØ?1M„´ y\u İ5øŠfãšLÓæÅşñSPÊ=Œ¶¿]QhYŸ”šr7+G~{e®i½‚×Òál Çè}²‰œ»ÏÒ7Ÿ…"ö.4I.Öíöj#“ÒJIp;D)õÖ·˜áäòw†9‘Mbœer9RÜûøÎJ„Ø”Ø}Î„:õÄdÙæâè(ÃÄ—˜üCZ‡.‹4¸‹b^è; ’s›²jí5å€Ñs{­4K”[;·îÉû*µ,ìñµ°+›KäŒ‡c[Œ€Ï:’· YS½ß¸h‚xNºFìiŸ€¦I¥ÁJ.î›ğˆwË‘t&VªœÈJÏâ©e?Ãÿç6o¶>€1aÂƒU„kpõÌˆ±˜9Q¥œ¢"W­i´Kæ’CÕæò•p«Æ
Ò„˜¯<”‡ŒEQúö|*"È2—ï0}£¡œƒ¨\•@à¼ûsåœBp8ãÌâh3ÉTˆıÏÁ·‡åâs’IèÂ/fÖúsº¨ô¦SÔyşGÌÜÎÄî5@G©ñ°;µ—j„ƒÏõ‹ZóG?O>ê	iPOqBvªz³&¥°ŸÚÃ¸^Ó•¦8\”,hñ'Î­³S6¬ï&ßˆí+PT±d”¯Pûåz€^1öŞ<»ÏÄğ•ÿøc«&jPLğcÒnÔ¡Gø9ƒA“„èü©lÿÃ|W²ÊØÑ×%¢°ä°öŠÏC××}®/ê¤Îí»À}wçÚry¸×Wpi"{Ì\|ºË‘iV¡Ê2dQ´ŠQòõ ;ü'¨`‹lÏío˜Íy@	ü),Rß\J¨¸I£¢iú­¯Ç÷‘	ou”A_sTCòr*õ‰Y(¥õ%%†ò
ä`+µË%Ş]hcc!„œ^Ú &‹ŸR‚Ú6ôÈ›PLè.­‡7w7EŞ‘¢ö_ê?Â“òâØ>Põ­®ñˆ”(|ô<¥B’¦’7M^c8ÛæÎwÃàÛŠ%Ô-¶æ|Ì7ø ëÚ,aÅÉ3jVX@òÿ3ˆ‰5ò¦^Ñ¤¢LwîA xv>ÖdtşÀÍ·l#ed&r1²[•[mRˆ|M îàE“©°¾ò´ã:ÿEo¼‡ö´lAßwÈ	#$}Íz‚#¸lÔqrrj´Å«–ôĞ*ÓÉ”4­ÃŠR#Äêv +I`_¦š½õ®¨–‘=‚Ç8V©›—u÷xnÜp`FC.±# yí@²
äv3˜TmöĞÃÑÍ’¬Lwg™pMòwªĞïd“Rœ^^.Ê&Æ™*ÃIÀŸ™¼*q~Oû[ Ü„h531öƒª¨<UŒ#áeaŠÈZèa^6’J"‘:4{6ğì|áÆCG7ø¸Ü%Çñ?öÒƒØ(+Wƒ_S±¡–ó+Ç™«ÀXËšÑ¶{*ÍÕ¿ˆ#dş”½`At 5WBò³w(‹Êœc³+'K+»i3a÷€†õ”ŸJÖA`wT&æóf?5¥Ëÿß¶¿>]MaKÈ!n`»Ó,z{L‡Ğ
øi¼ê¢ÿ™Ü¬—3ŠU{tR¢&0êá”&]#¡ùõTm¬„îôNhÆé³‰wŸ—¯-	bh=ŒĞ#(I.·Êç³=+Z«FL²‹ç©ƒ]PqˆE–=˜3Æh“ÓL,l“‡7çduë•éÙş¤d²jK¾áÊ8B–=¸ŒitW©Å¶$dˆH3hÇñì&ªà‰ĞLìşz øZéM‰ÖõÔªï(‚µk1}„¾X~ÌÓ\€°M%’603v
³‘÷ˆ¿ŒºnúOã:ïŠÆq×õèx)¥¹œ	J¶×Hµr‰É*óñx‹Sh“”ĞVâK1ûLM#>³UâØñé&HîÕH„v»B÷³2ÇÉğùDÊ÷F*£øGÜç†/aš•½0´Ì$Ğ£ÿÁ•óªo=Í¡åëíZG2yû³œ]pã»RBï´ç4ky‘]Ÿä2yzõÿ[l:º˜8	ÚzÍÛŒË¸ÄØŠ‚ÂÒ¥0“ÁĞkiåûÃnª¼(o£N®-S\êfÕæA£Š8€gŠ|¨GÊ¤|s)uşéòB¢ùŸÇŸ‚qh.>Ãá”@Ä*–À7f¾?„¶HÍÔ‰¡š‰'0pæ_ÖHEˆ²ÛŞØø3Œ¢gŸœ¢zş|¥õsw:zç‘l˜sLÌ°â‹-›g…ÀX.‹4ÁTr‹Ñ[SAİ‚Úÿöš/¦ÍKœ*ıOµ_Ñ<|¨°K¬µ¹äxƒ÷eÚ‡Ÿç,JîOÌ#óg,Ö7~CÊ¿Ó²·h'
ûìDù¯Ä€Í·³à$áŠP½~ ıÆIOÙYCN¤À$ŠÛ¼WU‹Wå~ &lŒ¯µ)‚-÷Yìêş:¯Ù,RTÇú×m_'Ñ«=\ ØŸ2~¾ñ3ìäôe]LŞ?÷‡‚>µkïóM†:’æ¶ÀÇÉütØÔ
—cXáM\Çfv”’…V)+¡òvx’à¦õ¶-µ&9h‰²Ã&
3’j;º ¥v–˜qpuZ•!ñí}x!ÚŞ×ø?éš$‘ĞSWL„µÕ/åT¬¾!¯p'ÔkB×¨ÉÊvŞı‘§ÄGŒ)½¢\êï¶}óş­Óà“¬i?îe8Uf¨7qx.ù|jİŞ¤Ôˆ¾¹&©•`’u5Ú…œF.ÂUcD-ŞÏĞÑ8ŸÃmĞõÑi|60½;’MÖ­fCïÎWÎ›‹Ş!íc½E8ˆDó<2Pÿif	±²tEkb]*‘8Ûn>¼Î{&ÙäCšæğèÃlkÏ—xÆ7{FoVLø—eÃç}ÀÊ*™IqºĞj‘bğ'^œ­6}ìËn­½k f!ĞÕÔ¸åîÎoÊA°ÎU©ıåDƒIç˜q	ïàdŸóYF1¹b•=g&ŠáÂğöşè£*–"Uƒ¿°^lé¨™à}Š¯­ì@;:6ÈWùZ„Û"k÷Ås[&	){®@V9n)p]ËèuUvV×m’ŸuO/´ÑNš[¡s¢?öbÀøy…<xmvÜ`r/€ ş3ŒdÉt#0j‹dÆ~·¦ªş™)¿õãÃÇ0Y«j6qLZX+À“	hÒë‚ôÁ2N¬üwÊ¢ô0ŞÏ3–¥óY 23…š*‘ëÕv Î!<]ZÈ“ 8ÜT²0ªŒÒ%Sl9LjœEŸ”:ú†.âb9CJDÚ¼¬+Ûüvs¦Õol1<×vØ»Õp)Æ¨jV¯mY››@§-İñ’ÕDÅŠuFºR(ÓqÖáD«pä
	B¹¯Mµö$Ü[‹£åN_–È;¯GéÄ¤BfÆH$E[~JdAy$a@Â:ÕtëÃızç`vÖ0píê¶^ú¸\SËª¶JóEe‡—vâhò”‘2Ì'í~r7N[ ’Ä/^ÎÀ/gÑs~ÓVFmG]Ş†¤Úõ£Ç®ŠªPÂlzÄÄ7Øb#jİî!y1AÉ9µTÛog2NáJy®êê?F-LîRm.–L°¶ï‚^sÚ%±ïRÕ¥I[q¿Z’ûV0^ŒKyuX®O¿bÖóŸ> Ã‡é)g¼¡¡GG’c;İ<˜Uë|é+ÏÂÅgŸVXZıÇ,W§RŞe)*öÌA™SeÍk¯ÎNlƒù¯"g~Q½êÿÎbqrÉõÜ;^xà@‹5 ‘2˜™}q–#s~™>PH14İXÇØë-ø¹xŠ¿Ç5ŠO*L,¶¨#òq¦“Ï‘Mşƒş!0è¼_>×­ºå]RQâû¡3¸¹.~ªüÔDtÃ%9ŸùKx!JKùˆ?ß½“Ø´4}m€IÁ(Gè6ĞÔhÉ" Ô2Üû÷±¿àïèßİèÇVÏ–:dŠL(<je4Õæ(Õñ’–5Ï¹åÓ¯$ihCmîn¾ˆÖ­şÒßÀÛÚs
·ûÎjé‘uù^Â7£Ôİ€ß“ sXVY	uiñ}4©n9Óİ”Æóêø¼I§iL¡fë´n`À³\Ô4\_ç´ç0ï%'	¤š­jXÃÜìnÍ€V;ÙÂw¸ bÚf£{0G	0pUÊIƒ~}´ğå>Íì¢4ç{»ı¾¶—^èR*P®Ï˜Âóh$\Cş?ÁCÔÊà¹Šüvì×EÃ½C©÷ºbY¿=·n&U3‚ƒ¼—KÏÇë"C½ì$5Áf$¤ñÃ™ş·¥­Gç±îcˆ´i~ =daÌ™nfÆ0Æ­îA¿”æËéœ$?— h×¸-õ£İ÷AÕŒÅ:“z[c4 sˆìŸ\½µ,$V©=8ßc,x·Q)¢¥U¥ÿu™EÖNË¸?§xUŸ¦¢êÿ¦Üí£B3»ËÁ×Ú7‚†‹%é1mDÕ0raİ~P˜aÇ—¨÷Ï–5Á
²IYŠIFíWŞ¼©_æ0hE­]z`:AÅ=1÷˜~ª%ÂgY_„}„ÒfªzÇø–Ëg*Å%Ô0I¦ddá¢Ñ£Š,ÄM€ÈÃ2}Æ°FŠlN#ù”!*‘HÑQ+½5áíÎSßÿ§vÁôgCµOÍäB;r‡–s-=/ğªpölØé¬áOŠT!PÈQ ¢,[»S3ó·pBÑW¿¯³×õ8n~é³~>šH@ˆvÆî«ãxá»¸ä%Ü%K¶HAì÷O›wÆ¢ƒğµ-Fşbè¸™ÓîÂƒ½Öj.«zÛ,€+›^ÆT4ÀIµ¼²4¶@8-# ˆÓ”¢y'°«HÕÅCdÑŸ
Û$Õ²:¬•0Õ@şT€nxí 2;ºw¹»‹Ü¼ÖZéñ]yA¢bº+Ns‰¼•áq¬Q¦O«Æß@1ï—ÆÈÖÁ­®ÅŒÌ„ç²Ñ¼¼Ûß ñn„QC¯Öjw8£•Ä$¯‰…nCÍ¢üÛÍNâ÷/²4f¯s8Ÿ¢~Hh|å—·‘WZ´Îœ×: 7¬dóõ Ÿ`J;H½>”@ÙYùä•ˆ[";/ìS17B³
w4q„vÉôšoÆUÑKÁ~UE6Ø‡ˆ–	B˜j¡†7[îNk©ŞßZ]h<ç8É›EĞ¾‰;‚®¦_Fbè;éà8Æ˜ İ;	¥A—ŞyXŠŠ;ba[Ñ´±÷(ÃõÔ“…öŠäxr0¦eõEAåï‰Ç"‹cÚûÚX4HëTmıÍã§İú{~wK´P;¤vz˜OOdnm'¢ì–-ÑO´/v—Îµ=!Äõ^×æ‰–QÓxßİŒİ#®sqEµ¨C›´˜-f²¥¶Â!•kb‹æœuÕäBw)¦±ÿÒ²÷Tƒ¯®ºd*Ã‰cèÕ\e/|lÁÛ)yäŠ6{sZˆú2Ú™ítÑ¦¬“ê•+ˆí¤¤Áu
!(¤ı¦¬˜Ö‘÷ÙÏôäcÚSšeLH¹_œX_ÑHO

ûNM=Üñ÷ÃòMqA ¡Á‘Óc‘´!,•ä-MŸ5I«èÉŠ0GLò”o•dĞ/ÚK’t|U)	`ƒ«¬ã(yÜzoÎÿ¹!½ø«‰’ps÷â$dúÔvÊîP52TLwUMÕ;Å	¸«|…ğİ0šüBùlx)qÁ„sÁúHê0D¨q!(¡Iı­‘×‰u%(É€bÅÓ…ŒøÊpœ«Ö	ôw+«¤Ã×ô=Ñ%)ïƒ—4R±˜‹¶ûï¸ˆsZ„^<ÿ%†°_ÈoôÚšÖŠÎ-2˜YËó¦Kà¨vğìÙMgfšViñ©3[®ŞıŸÿ~DSÌÄ¹šï}!S!· ş¼ƒÒ%À4ÔØîùcùAİápµrzåú˜.ãMYş\Ê·šN&üY¯å~c¨oÚŸ˜Pbfµ‘4@ÄÕÜbı‡ XGal±š4ñmY4ŞÁàÅÚù®‘–Z8åÁ•o¶jàµ]‚„¥^¬°/Ÿş8°¾K|Àv‘U Hæ%èÀu9¡öY²!³ĞÔ)kjyŸP@”i¬§Ù?ßºî>ÕyNâ¡ááEfäÀ8”£x–ºÓ‚à’Ùö½düi°Å+ÈVûæB‹‹DmÜå‹?a¡ğO“EúÑz	ş#’´®Qó03Ä¾˜¼ÆixTô×Ÿ%Ü	@ë>PÆ.â¯ä_m‹@EŸõ”5ÜDÊJ‡OMß)æ¹g•&sDÔ¢¾'Zk€Eä5Ü¿êt„¨oCN’9cúHanéùÌDwóqŒŠxãé€Kı,iÃ:Œ>êPøµ\ÎaÑÒ< dÛ‡eäœ&8PB$3áDó`&´U—­Ş›ÉµÕÑ/ìòP“àôêáTç‡ˆİôú¼D5ëòùËl“ zòÄ‰ÀBTf4fÅŒ¯T—¡ Yd|Šf	)¬Éˆé_“!PçªZD5Y)ß$]àÔüÉDô‹#&åkÊêUI­0FŸ3SŠl©«-è,Â#ÈSRãÆ0E§‹¡8†§Ÿ*ª‘è©ÿk†iïñå>ïÕÔg4{Y¬Ô´şÖûØmÕı	¼¤ó‡æ¾Ÿ`ã{eÅ¢ñ!L”†GÒyÁ D¢p+<ÅÜû SM…©AâÆUÁ]Zk<_ß&-µĞt»zßø¸rĞÆ“[—Û¬ÁîiÀÀ¿Uü÷iÏÏŸÇ|¥ø¾"Mp'd`ÁcaçÆ(v)ô®lyó±S¥5$¬>kD~x›È‡Y«THòûÙ1äº–™ª‰Ùı†Ù	½†Y"@ö½SfSÈ9Ìì.µL™#á¹œŒOG‹ïÏAã¬»<Ìe¨œ’M©h7GŒ÷ ‚Rû›sè| *!°$^Rï]>“:µ»eÉÅÏ?ÃkÙÓ8¥è;á½šA$ÿAĞ[9Û7é—˜ªa‡J¢Ê–v^"*èà !C)ô0‘w@# ‡ÅUï1}XƒvÑ÷åˆE¿7í?ìúoÉm(2°µv7ì\>ñÊ!˜YNiØèÈË0¡êG¤Ÿõ9+>2ŸO°¾ÿêÛBæğ.Eeˆ’A1ù™L&Ilb-ÒbDs 1/’t$rëxA(1SÀB‚S¬¨N>âÄÃ¨Qb
¸Ô`ÔP¦à`Bm Ã‡_N ãÓäÙ©&C`hÃğÿ))9z"»Ğt˜Õˆ„HRİ
Ğ/íßÊ…1FxF†&+LÈ…TTˆÔ»[¸è|Ü•Ïó†<i%°ÍqùºnŠ‡WŒB%œå§HC'¦XÀ@R_‰<ˆĞ¢0§éµàI†¨İv…P¯ûÎ¿º\¾^aõAËz$¿àÀ?*ÎŠÔÚ–¥£eNf4†×”ÖÂ=ÌÏN¸ı*õuU©#›€»
&©kğ@¹zÈù\¨³$Õ0A)ĞE°ÄD‘BW!Åg7]0b”ÃgjÀ²Ÿ_: Î¨[ÔCE›ÍoÌxËèC Ía› ´"#+ 52çô¿æ\‹¥•©n|5œÈïÈ/¥ZğGFj,mX6tM-£Êì§¶GÑ9ÌÖ<HÚ%!
c´PµPä8ÛJËŒÉ,Á€ªÜ˜lVÕ?Â¤V7fPkÊÖíÈğM`Nä8e±²ün0ùg9ßü «éÕö0Cç=š¦¸!Œñ
2æ“Ô|Ò¥`$Î›Ë„÷®œ‘hj’]Œ"ÏÔO¶p³gú@(1ŞÃ‚H¹iyxô>R˜ù{×½7Aá¿îTŒFˆN¸ ŒvìóMj'¤LH§O­LnøüQ$5{Ç‚TİQ¹¹…ãúcü–\ˆÛJêQ¸@Ùt_|ÄÔÃi«º@|{ğ5Ò€õÆm+tï	6`ó#ğtv•›ı²%çæÛc{Ü—ZÅ%êMZ)ScRİŠgêÙ'ÚàóçèP•–øÚğ-zë¥ÁÖé´ß	ã3ê÷€ÒAGÈ=İöz=} 83~›ÂFn^—3ºãÊİÊ<³cd’“>RAR.U­¸Û!éõ²åÆ‹Ïd1#0Sp44Î2“s¼~ôˆÅmxÌdÊTb‘èÇÏ zRoiGfn¶¹Õ’¾´#é*ùõ|ü“­§H¨ëLF·¿Ô\EŠ(ñÃrQ2.ØÏ•(µ°RW‹su§EË”îN‹œ$ØÑ,‰'ƒç/m¶>—ogwyLé|j<Ò}ZÊ»g*û½Øš¦!Lê@ÏÒÇw¢ZL^kWxô‚¦1\:ÕBáRŸg*àf·¬›œüàÇ«î®¿Ìï½Ïæ¹ÉQ¥KG¾d4ø#R{b~Và ½24yüP©Ø>ÍN;l©‰‹4ÊiJXrÃjUÜ)!Ê@Îz¼ üMĞ÷iù›³ÌçËñzØën¥5@P$c|ô%’5}¨•è®ŒŸ«„–|\êÉ¿Ú”§ˆ8é”À÷DŒ‚Ÿ²„ş(šìä’“İ<n,£*Íöë¹! ¼3hy¶/È9|¢€ÛÜmÅ“¢ĞÇr¡Vd>š:úe™7•¨Ä¹ŒSÑÀ¹2<^½›œwW¿¤ÆyÁIÏw‹ ŠY‘Cdìëkõ££{Ñ>éÂe¿¯=Y+Œ‘Î=¥c—ú=“FŸ³4<ûã]şrÁ·´_€õ6ª¿Şçbu9"«ëO€ØŞßª­¬ázã¶°ü|Şm(ûÉ|šÇÉ)+Ú©ô1Òú	¡Q8$‘sı™R¾›]ÄÎç‡1(sÆšYá_kß¬f~w-ş‰úoÌ†C2Íñ"xˆôïİÎg0¿'ˆ¬[±öm£ºÄVZV‚
Cñ5Övş…İ±4„„ò¢¼~„-)Ìà‰ğò´ [v×P¿ ‘ oò¦÷$¯6¼éÊ€ŸÀy(°M1¹Èõ‚»ç6¸Ãdú•YˆDáqãQÃeOHÛ<[8Õ-ô€ÁÆóÑäsùëÛÀ^û?­6 j³Jâúğ›ğS`?aî.â¼ª¬ceZ•NmgŒN©t®¥dGö,ˆ-"Bà–a–øZéIÀ‚ .¾=üß¬¨˜Ë|êğğ=æ¨”Û0r P½Í¹iğsHÿ¿†,= 1L¥œLi†BTp’óæ¶+Æ7Ìb”%„:5-i¦mÄÎk„ş
×yu¹#ÒúQ	o‚ııÈéSLìeAB—RÜZkG–·Jë¤ZXx¼ïÃaYØ…¨1¥/¨Õ ’‹É»€J¼õù_ º4Ï3•ab;kò·ÜºÕ)‡–BúÖ‘»IM-Áu9BŠ¥*Áµö¹œqÁˆáïµ¨-oÏea	ÔENıK^güJk+2.¡ÚÊğà-”É#HJßş;ÜÓ“23ëOG³Ùàu^²P¿¡İ“!¨éóçLOLº4W>«&D¶½>1?­½µâ>eÍŒÓaƒ1¬$¬$õzêÿ/£?¶]‘<ßíØuñ7/ÛùÇÍ$Dõ3¤<ƒg½&¤Ÿ0ñp–1uAã•Xİ8¢‹×4Ğ›È ¡1İ;u×a`áÛ¸k{îyƒH"”Ù26q‰‘1øÒ3šàñ­»ojÕFûJ9vúñµ
pyµQ×ö‰²@waÓ†üÔ·¦Æã¥al(3Xÿ§ …²j©?`´Š4}OQ+gÙk–KŠR–Î6Â¦ûàß°/(+›ÒùEÍõÕØD°*œçá×ó"(§#ón*÷˜ƒE¼§ï¬×Õp‚lİKÙ¡ïD’µ¸ÎÑ"˜T™‘AªÏ %„C7ê°6
&ĞC<À*‡›+£VÛ­vz‡@‡şÕGiGP,EõÙù'£ç©7ãÿ«"‚}ÿŒs†RƒÀeô1¹şô¿^’õÓ-ÚÄhO'*Ê9a0"m´ô˜¼!MüiTvŸˆ‰†õÿ.´©”?AqúÔÂİêÁ#=Ë3ù&¢ïä
bÃs_f&:Õ--_oó–úlú#BµÒ×a¾kŞäôû¦nC0i/9ôÖªïv¹ı]ğ¾t/û¢‚®Ù†È´ÉÜ&™|FzY(‡C
–,-C¡×Ê¸ÿ£cGœ}½7‘ Gş‰Z5H1·ÁÉjÿ–Ådº½ã|#d>wš´ÀUö;Ú½1²,*ùvC:SÏF½ùÓ˜õLh¨2†ÒÙ|l…_ÆºÀ„NFÆÖ3øşš7ğ&a#£şkãešØ,xü³‰§F·hÆ¬Bx2¸ØÁŞ•Œİ}Ä0Jlv2òJ-Woª½Oˆãe`3^¤ÅÀ>[ÀB¬3âwj¬iˆ}ŒI£Ùòòª	£)Yì¦U…‰Ÿ-ä©šÚàX–^epdİà¦¦B"Í´‚24«'µÉ%£p…•zhn‡,4‹Ç&Ríc·\—[\ª¶‚µÿ^÷ÀMPû,hÎ^`…T¢YÙŞˆô`ë*¼,·_:ÑÌWùr`€Ş\|¾ñŞæ Vb·/Ü=ÒqÏ‹ÚıÜ¿OV7pÍ²¯Ì£4òY×F7×»şlø¯!¬ ²qr¢ğxÊ¶š!ü	,k"ìõ•]²Ç”ljğ´Ô^VÃ=HCÜ¤»Ã}	¡içyùRÇ*|/3Ñ>¬×	ÒòF	?0Lh;f½şæ,Ê›×®c5/évá­JÔñòq[˜ø†– °>™s¨®x·ñ«8N–J„€)‡¹ÚÔ‹lI¿à2f³æém¡6W-½LyL³Œå¼êvŸI2Ù'_,ÏbĞ¶Y”à–Q³{V´ëŸ¯<ÛQ¢çŸc·ÚÉşZ›ì‡;êzBy…ıŸ£X9ëx•›ÈıÚ¼ò„† íÃÆ–Ö×‘ZF±Gû÷R³Ï›œ“É›÷ç=¾ÈvìºI ıìY&IÖZ##×í¹´c19Á†PGÏ¯ÖşqÚ9‡¤*L½ÅqœØn½LÄ=bsA=ìM€"U-…%™ê¬Şòéèuj‰À•­¯»: àGæE1ñB‡8Úø×À·fÚö_}÷u&oXñH¼T#ÂìÍ&_z.èvÎéRRWTuNºê+w7çÛ ˆÈcf©ó‚ÿ!}{×­bO9/ÆÌ DŸëMå<ÀÍTø³Rñ„œKzİ‹=TZd8(Œİ“›5¥ıÓ@–fB4İJ„éâáóM€æ{YYÅŒ·Ï¨}²ÊµÓ÷'ÙTm|xô‘R£xN‘Œ/³"ÙT Jœ?J¢´g»‰{gÕ¹¹Ñ˜Ç ²Ú@£¢âhG>Å”[‘
*+wº€}vII~{4¾V¦¥hÎK L2ŸuQ’ğ<Á<O»ã >);_gÿb‹¯Ş-'9ÏpUJé‡/›j¾ºšnO†é±6ËW¶B‚sd6\ûˆ½ÿ¿škmô=i¥Èâ2
rÙa¢îúm\2Û÷VÙÊ_;…“Õ {4U*ş¦6½¼µ*Ğ&÷‹„®”98İ"Ê÷aˆShøwÁîT<]pƒÖuÊ&µ4.Áná~ÿ*åyZ½è¾B€ÈLùªpÀÖC-T¥—µgë¸ª–jqM#¬F['ñkŸ/‹HÆ,øg‡’÷éis†°¬¶bê-·FÓŠš äxÈkş;ë|)3_èßÎìcê‰,+æ¨•Îœ°[R­—P‰ùKÔèëÓéÁZñ»båTRª2HğBM|XâÅ«•()eªšeOQóQU¤ÁÅd8½·_ ‚Y°ö"róiƒ¹=+¹nêT“/¢“#šÍJj=†òº¼!…0ùnÆªOÔÏP/òíÎµlõ·vã[æÙ|®ÔÀ­VÁ½*Y¾=Âç0\VoÆ“CU¯aĞ@\§!^y"ä¡,(féhU­ö–"Ró4³ÙÍ|Â8ë¸*\P¾H“/‡¯ÈYLUÇ»§.Ò}Ág19ìÒÍş#×	éÇ-£yíâ½&¼»— q×$ÉâQHlÍ»»OÇ?åÈTkbÛõ1ú	ÜÑ
ÊÍ¢rvUk=Å³ï¯ĞbÖêñºl~šÜj…=%Së—1âšLW1#ø‰(V2 U¯aö˜ÁÙ‡ÇFF£»®ááI«–ª¢‹?H‚û?Ãø‰‹nOVc§£;‘1¤Ğ¥¨š.E1×Şó¿„œñp×$Üç¤w¯[ÊÚybŠhzÍ"7Œˆõä¼CŸ±BûbûÕJ³càh'{ÙUr›qîìfŸ‚‚âR#AÑïS 6F¸uPY¦¹fiæ¢)Ñª‰<%Åm9¥—`Cƒ¼yíÊjYù¶àøNòÈèé/>Ê¼a÷’«b‹=¨ÜÏ—ËÌ)—' Ù‹ë&¶"}fä¯™]Ô“~Qş³˜§Ö_’ô‹ªyô(ìqúªáëjıc¬Î­ÚM¨¦»!ˆ«UÎ²tætài÷‹WYCÒAxE»°:–x}$"•‰¤éJI…Õ^GËàÖİ=5væ6‡—Ê˜šÍÔØˆ1ümiPh ´5: ·Ì]ù4û¨ÁÜE8êƒŒ7yB'¬¼à bäá	µ„³dA±54zŒé\ã<uã¦!„wÄ2nh©s±µy‰½ÓÏG €ã„È¯ Á+ÀÇ?Â•KM¥J”Ÿ–9É–_~‹dpßOØÚ+G¼öˆ¸àÿ0+Ÿ†¿^ÇØrò>½¹ 1ì˜¶xzçáA÷Œã‚ñıì+(ÄƒB,çÛ*¨s”ë](Ğm	6Ã?Uøî¥I'Àƒ<­•S¿Ô¶¸±Tä º	oÔòyôÒYÁµ!<8®Û¯Âá}–¬
ïy ê Ş*ŸóDséŠ\î¿õ¥±e£OÚ9y²§ YmÁ˜1Å,Õ_Tp3å¼ªÈ4²Tqü|e‡}Ÿ<Ó¢!‚49­’|?lJ–½¥}™oÓóĞid«ã«£LOË²‰f¿o‚Vıı?Çş*¹¦ñÿP3—{?Ï‘’Lì*¬#×ïØÛÍ1ë‘ˆ><€1õğU‚¦amÆ¶9±{oXÿê–Î’•¦Á÷Õ¤×B3¹\Œ!X$”o€ÖJ¶GbŒH3k°y!¢òzOÌFÏşŠÜëÓÅ	…ÇØŸDoMC~yÃÚ´fw9ÕÙƒ9?î•Œh½ãuj¬süĞ©É<{/Tîuğ¨j@€4OJó®yMQ$FK)¡ÇËÑ×Õêj¯ŒOş†x¥¨s…ò]£†µÔ™¼Å3?¹ğ”túnüÆË ·¤hEğóÃxnÂ4N
O„Ø4ÈhÑ7a$[ B58îT¸¦Ö´­æ¸1ª!°ß|s‚:,`0bßİuôI
ê¤z#C~œ	czïÑî¦D3A¸uCÖ‰D¼¸ı€øªà^í¦ú€6ğe©$Ê!ó¢íG8(àËzÀy¸§úåÉÂÏf£¨®—ş¸`S£Óş·êìufĞC9
K~>8\0Fª `s!î––ÄSm—u#« Ía3jM/üÖ
,½-mô•İ³Îù·Â;´W„Mõ9¥"áì€Áx®Q.R‡Ğ	™hX?·Oº.,[½³tI­–ü)Aî7ÌGä°q€jˆºR  ™ƒï¢}lwÍÅØæìes.×¥µI1M0‘Òö\ğ²£6ËAtÉIô!lMvû!ş¬š»[Œ"Í½Öˆ€“‚™—È#z§‘BAü1œ\U–¬ó5ƒ.§ª|´7•0)ğpZoBª=¬ÀŠ™™î"$A3µ´Î'¥”yÆªN¦@{úbg„®‹û²¬ôŠ‘Å`*01¯ ñš»8ñåÔÏ,.~°.ÇoÆ–M†fU/Ã5ˆù„üÀ{2„³ßÙìÏ@åŠÔˆHíùótTïnIŞˆÆG!!Üš“©E_ß%)‘½eÅYÅyáşÆ8D‚õD—¿?_<5ĞõúúG™±¢¾sSi§Íåø{¦“ âÉy ”Óeä»|öªXn…ºaµ=¸×N³ª(˜eÔ?ßfèåÉú¶Ùj¥Ğè°a1’›ÃNÕY@UØÁ¹ãƒ‰8š &wğ»¾ö°Ò6eŞ¯§Ã3›]Ónºƒzn@@ Ã.ìxÛİhj¿°%9ºa¢4@d¤Í‘1œŸwÑ¦äoÎü¸eWÁs@{³'LÛî¸öíT@FÙ?IàÏtÒ`v~MĞ­4øğ 7_îc'BQ@Œ4a¶Ò€‰$ç.«ˆ2^¢ Ò>¢s^¬/ûWò„f£f•¨ùŞ0Ôà‹+µÛ±È+LK“íâ1Vı[ò–ËÖã’8à_(ƒÉÊFCvs›¢¶Óúmhl04[ÿ8sÏ^âŒææB¬/[2ß^ÙK5ÕÃ	¥§!5ı¥ZnÓCıİk–@çÒóùÅüÑÌ²-?õÛºPPİe×Ş¥uM«'°4[Ğ5RŠ.ç&ü}áã@â2ğĞƒğ6Œöt £M}Ş6%`LT;3Òâ	ªi4ÔğĞd`æw4äEö¸Ûµˆ<ª1_
 !]×¡kaáşØ±‘Ãà ‹E²
¨ãiìa^¨ë30kT{w3¼VNq*	ÄfKV	‚Hû»*$Ÿ•³S¸~Pù)R^G¿ëÆ-ãê^‰l} ‹MÓ†ˆ#‘Ô›’É=[bê’—Ü0÷#“
8ÏZ3}âŸÃê–×0÷WFb:••2—´…3/ÕÙfJƒç˜c=5—P?áà…w!¿+ \=2f—‚¦Mriş*éTÖı•®àÂŒÀÍ´ı»•‰°š·şVÔm$Ú
„ ú	AİNUÊ`k<æ'>goüj(»)ÀlÄ²—šş‘Ù–îJ·LD"ƒşçş–‰‰7ìrK~	Ã¡®ÌµzÂuMò~Ê”eè°I1ŒÆšäğkG×æ¨[Ó(V™eÕ7*9Áùò' L·£lˆ?iHóf†áv9½8¶Â“–”nK™Áa´L‚Ú*ŞéÁ8.ªr3t¥Íb27Á(@ÌpÂÅ˜XñJ"B”áƒVûı’ƒ6şƒm Î(÷Ãıt¦c'1*DDf•(!³[Ó.vo˜u÷2JmóbßÇ¦Êã}Æêä·³„@Î™ÿçÅƒ>W‡÷CÙà`C W£rûÃC¨·t8çÌ`&öÊ­.‚}†A“N0·Ü{“­¹©Cw~Áå<Ú~oË8ïOyL·4‡s^z“!Í’âFmµfŸØ*¸ò…N³šÚ±ÿkM³£ˆ‡zÅı¡Á®ÚìnùHa¢@_õ”w ó¶…1ı»£ÿ¨RÕŒnl'üêrÇ|…Bx3ærzée†ı äà<ÿOØÃ4Ø=æxGTæ_“UÅ1>f™ ÜlªP
¬³Zl'…RÓ~˜lV÷üCdÑ–=ÃªÑ;Lz#´NÚ\ò$×À%Oz273õ¿C)²ô’K,ÌŸxâˆ@¨ÙHæOi½Ç«‰#ádÂ½a!Å–«|¢M°FËü‘?Ôåâ‚¿D¤ëvn72@CCŞbĞ
À÷Ÿ•’$ûÓ.Nõ‡t9†E™ ]î(9
²$ïFLÀ%:7²y¹(Ìe‚¼?Dƒ8I5TI~À!ŞÈy™°`äD÷·Õ–¥X_!ÈíËèIÉ¶;JˆÚ0~ZF H°éxÙ¡²ÂP®;!Œ…TÁmíë:Ö²B†ÌEo]µzlõi­F!Ï”…†z	,H¹ &“¡Ìš·òÕËNâ3Êø„$…Û1Aœæ¼jp‘o²Å×‰ÆáÜ³`İª-­;MÇ<öılØIÂÔdYı}ÄizN=û•©í³Ÿ¥	ø@ ÜÜÂ3TS÷I¬”äòu:‘u½´¹ıUa$—+!Ç]¸µlw$ú0uû0ñ(şk17àÌrM› 5¿$¤¡›»‘x”û{¤3èUÉûª¶À3V‹çÍ|©%º¯¨oÑ zª‹Şò=–0¬ÄıºøghäFÈ¢Õ]ô9GXuá~–µ/çÌ¡GN-|ø‡ôÛÛ©°^‚îéWÍ× ¾‡[~9ñ:–9õÖÖ6†MiâêÂn?·‚¥™¼‰¿Ü5g}Ç?ã:j¾"åpÆçixÈ‚_ÜŒ^ÕÙ/q@üÓÁ>×µ‰†ìøóºqAÎ±ÁH$4šÃä#imåƒwZ•{FØ‰µ‹JŠÚ¤±xGô¯p2¬#Ş´ÎY$Ï<„´¤N®>ç	`ú>Dˆ×ßs	²Y!óÑæê´x*™fÄ
åØ"£b<?_YŠuZ^œAO![=an$,mA#¿)G˜È¸pÆÙüF¯À)€s–cHjêà±†%øÃ¢‰$`Øº¸×ÖÓ[†?šR_	vmc‰)y£JˆŸDnªQÂ)XÉÚİBmÈøEp<´QH©#:8W>@pWLP·úOD:_¡ü7U‘Ç@s©˜¸úZöÊ4’ 4Ì;–ºßXøV3ì0Xg×ÏŠ†ôh#ÏVl4L%qR{
ªhµÚóÊQ<oé2ÄH Õ¨Uõisíf÷«=É"dÏ‹í/An¼6M¹cc%Ù˜¹Æ•é5:ıûYEÚÎ#2œÜJPk` f<8û8íÂ™Ş“î¾ß€Ê2rİ\GHB669<Kø,=á·nv=îEŞ	Øºßü(¾‘AˆcïŸÈwB‘øä™Ûş¶»Œl?6»ÉL=œ//s=!S¢Š[[ Årê‡‡·˜ÀU2Æİ½$k‘añä—¡{ğsÂŠOÀÑ÷ùß·3£cO§‹/™
÷ÑäKöe(h]>ıVÑˆyLÀe‘ß[èÜ ¨Õ¬b±5§&ÏLèª”€ĞCä²jD<ä8ási€Ğ)$éSÃ7‘	•²u3«Ğ)q@È‡»ûâƒF‡`Ú8b¦&Où¾òÄF ÜÁà£ZÏAi::šÑº·x?8; …ÓÆa¶iLôvş'g¾PUîkĞpù[Pç¨šÜ%&°ö©	,é¹~İĞÄZjØÄlïÅËîp¬tj´ê)DÇVWë<q¬ÄUÍfú+1Òbv¼'*sGä¹×5lÒï<ÆGæüq;R"yşÔ‚»­Aœ_}›­R‰ùY¶Šå±ÏC4{4ñâ‚øLµ|¾™#“-É>øöD1i˜Ø•0å³òœ“`ëpU7ûá]>-onÓğwÇğ÷
ÒPC\xp,âÀ•ÜP)ôáo=d½ÙãÚpqx$×Û¡fyÛ„bÖİ™$0MúgÖÄhsØiOt	L¤“m9<!Ïâê©š¨çdhR
cjq¶«©«ğ,İô,1yV’èU.lrÌ¥îêş÷ó‚¸­m4Åi<³i´jŞ²QjlKŒx×@Åëü2¶®AdèC!ÛuƒI3ËşıIF0bş?ƒÍ#™{¿:Ô}l"¬óyM„ûIÄ·jjrQ
‡±ãaî‹F<Şí´SÕá…/±f­B2Î×ZgA&ñàøÔ¾hşÇ‹¼cIe€qç¦ãğ/êd 4\Xâöÿšü[¿F[•PÌkûq§-uœ44ØB6 Uw|LHÁ©pÁ†“6Ro¶ˆêµÔÃ)Ô¾Äz?KUàƒG­;Ë¬>Êû‰ú=°*İB›BÑ5³€Õ0ìˆã Ixã@Š|#‡t³Ìd1 ‰75|
Wéšıú[®ñœjä0›™pCïğ\A(\Œ%Vÿó³ï¥“€Æ¶cxÇVß²q…C¬d¨eC„[† V#C¢t€ÿÿ‡áUc*Ü9ğŞ1ˆQ¹_Œ‰˜±ï‚È¦ÈÚSÒìÍ§Êo]áìríæ	¾1ùçù
„Ş7FªSÛ»¶ÍtZ3(åyÄ8Ş	œ×–Œ6¬o ¾L­Ÿ8ôï¿¯Î¾è¤n›)7+Ëå@Î"2?–]Yx #Şê*Ç?/ÿÛFH‘#¥HÜhêBt)ò´(İ’™œ+ì«ñ¸e6#ä3ö¿¤ğü+Ì1I…È¸OR· ü÷ÇoÆÄ™{Á,œKÔÇÅhÂÆS_
°÷¢Š¸ƒ‰HF I4o*L",6h¾¡1+_Ñ5‡›Û4f!TZ¾3Â‰{6¢ &xaÏfÙÚÚú©¨»çê    ‰ŠhVÓml î¹€ÀBúÛş±Ägû    YZ