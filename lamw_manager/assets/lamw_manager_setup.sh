#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3726048966"
MD5="7fe0602daf13e46501bc153e9e0ad184"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25816"
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
	echo Uncompressed size: 188 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 19:30:21 -03 2021
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
	echo OLDUSIZE=188
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
	MS_Printf "About to extract 188 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 188; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (188 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿd—] ¼}•À1Dd]‡Á›PætİDõ#ãìBÏ÷¼Q[ê½!oe½rè<V%˜¢ÊD’¶ÌÖ †ˆÎÊ½êÓ2§˜ÑB2OgÚxîA}YµÏ•ËO	½4ıà$*ŒÅœŸ¤Opyt·´=u}E‘Ş? !‘…åµ‡ÂaşögÊ³v[>dæ½›!cq“ü–½şI‡¦ë†şnpÅhtŸvÆ´Ù*qŠÚz“ÛHöt§‡APÀ0«Á.-_À#xXäôøç8,aGÃœkbÓ«ë:	SR	5ÔaITh™k\”ä™İœ„tÜcyf·K;Uê;)–Y×ïãÎP.fğé_ÃÆXc…¢mÚ.­gHGDc˜‹$:‚ÀF²’›;751›ŞÇ<åd{À#ì Í^u”Ò6èÂŠ˜ƒj­-OŒq…ÇÉÏi³ôŒ‡ÉÅHáˆ‘ÿòŒÃíTá{HBş€xñ™ÂŸmÍ+6»ñ|›±)€3R…¹Î!8dêëm%dhÇZaÙ<¢¬öAğ*ø1Ù”võXSxĞ×Ÿ³DÛ#© „G8‚¿â(tLÿĞc"æÃ¢P±6ú¸¹z}m'Î´~{üƒá¡TÉ/Õuïš[NmëE¾~\©k=öŒŸ*ÍFxıFb‹Qz>¡7%†ÇøÙMÇvìåİ+±O€(@ œî*¼Ô½;Î½G/o”.öù^•8'eït‰¤&jõ^¬Ào÷ İ´©üÁKÓrp°N|µ~OÑ´%ª³ª7â` $CğYé¬¸ô„­¿‹¶ı[åEXj1_ì–W¡WDËü¦4%}÷ì}6®Y?òœ˜ã:ï¦É¸OŠ¬C‰$;ÿû­æqZæ7oñi&¯SÙ nèS(\¾³üôùÛû[^2Ä×‰8…Ş9Y-Ûc ºI”!Š¯l QêÙ«Ÿêx™Ğç"uT°X¬ ÷ª2…æ(rü¶_‘‰"Éº»«ö(kÄÁµÍ¶ÉN±#1ÂÂ?
Ÿò·ºİ›\¥‡¬‚àLn5´o<>!ó›éÔÂ!Şó¹"ÜğŒ"PóVÁØ2XÂnş÷kâòC_õ²Ğº÷%2_!PPÑ7? „á…_ûÅy½	çƒç*¹l6V&IÎ×¨•^ØËw=Ü“TN2%]RÌ‰u5Ó…â¶÷ßÇŒÏÖ4vQ$x °sı…«MÏ­_@ó&^	ÖS¹™ğOúœÊºÇ»’oNYĞ\êgÖX”´èxÚ‰à$ÿ)<7íRÒ–ªù8ï1 •™õÖP!äÑ¢ ¸ #^¹äoñ©FkşC&™ğïæùìD÷Ãštô¾µü{µbmvPµ^i¾¨¦¼DPN8>!Ñ½
S9ä6ïËÇÏÔÇ^!#"v‰ö‘]›×éİdİBæş<k@Û ĞšŒ_|gş°äˆ,qÏj=âÿùî_“lÎ¶{¹Ğ¡h hjPÀ‹º2î5ÃÌÁ\Ñ~Ët`Õ†|Ûê]£”ŞŠí'zÙsk»|*}ÖiÛ°aÈŸsp¢×€İšÈFBYU)-§Æî¹‘UJ‡Æsö _ïÈ R<·@9¡JÍã%é¨!›ËÅ;§]¿bvu}ùÍs*=+W­5y^~Ô¼#¤*àõss§4$""îí‚j¶f©‚[ÜõQ<ÄÂ¸0P9lk›¹ÇaF†=ûè>S"h[Sä`ÎnğùC‚¡¤Ë¨}'*_'+eÏq]¿jç4%QÑà§jˆˆ0F€¤ŸNòÏ<v&KöĞlŞ-`¢fízáÜh]À„˜y30xÆN?C–´ã§Ãùër^Ù#Á'tÏÄÛ°KÀAN’2÷Ú5¤8îÑ]ù'ĞÔõZ·`Ääç©øeß¥áLûÍ=ºÊqJ=Bcµ²còåÿ‘÷2kò›ß½ãÑ<Š§Ú0ê2Næs‹]TkIš'Kü˜EKWIC
bL°'eê`‘$u=*¦:\ëmÁg«1ºYnÂÜ¢»µí¹ËT—,ˆ®2&K¤Q¾YOaNnBÓr±‹É:m\1à2”z	/~a>tÕ 
´ÚŒÄüQèYDè{×áè—ßñş‹•òMjû#@ìŠÿ{ŠÂjä\¨Ô¶äh9uKos+d;:·Š¼ájn¼’™+SÈø töHÎn0ö-iiò¯õß PbğºøÜò¦6O¤?ÌÔRínãÁU£Y4‹[è‡ºÀª.8ÂKò0Gº„#Ï_Oê46€£PmË‹ÚÃ-èHõø4İÄ/´ÍV8íŸk2·uKE@F©‰£¢”½[0’\xƒØ|Ëî¦çÁîÕ-ì²¦`Öº‚9a6¹‹BÓ$¬vÿä©İ$/YL¿VôªÈ—ŒåªXÂÎo#Fdí:RpÏ_«Ú½5)’ñ¯Ü÷AŒrÂÂ‚†÷Û¨×s­©Ï6º[¬ÊÛn$ãq¸‚óá>ÔdªN	©æÛá½\ëD[·‹ t3»C!{¦Öøô}$ .8]A`ÈK¾“tb8ñ‡K"Ùâ £’/jÙ¹^:ÍÊ§¸ˆ’´Ôk`]ğßLOæjey&\ØÈÿe]™ÚP§3ñ…;[¿‚8šÓwªb9tÏç'júó/¾œ³ÜtÄdrR´gdÒ–Û’¥ÎÏÒ0¦® ˆs²ugf×¹ÊÖ¹æÊx­öèQ“ĞÊZ*ZN®tï?‹à¯ @ëÊWu‰‘¡¥µÂšº™‘Ã°ÇDÑõkîÒÀİÑózÌ{UW\ş¿» -º´]ïÍ9†u[WÛêŞÖ¬/$À_OÍhØ,tdC^PP6x 36-/m!|bCX[CF<œÅsé•ÅƒO
[çú?ºĞ=ÈÇ;ÀÛÚQ8ğš\·]„zQfË´d2EŸü(Š©ölÖ- àM†èû­iq-S£™‚Ùõ›Ç\Ôô(·¶E¦ÍÁç
Ê/Æ¸&±×¨X^^Û´êÿI—……tFtğÌ8@GrôË)\á¶­W†¶íÈa£FG¢ ó	İ@ZmáÅ³ö^N¿0¼vPªí;.0ÿ‡Ç+sAmI
Åæ¢åºÏËJ´‡Iğ_]3ŒºqØ\Â…GC°åF,<isÛ­×ñ²VÅsæ ‘
×RV@&3á“¢3%±àÙDítqk#Æàß6º´ló"ç(#ä«£z ¯ôûëbà¤I‰Ö2>yŞïÑ±@
ÎE#Y¾ÔÿÌæºLªÛwä2Ì#ôëMµNaÛQH6gƒúr~±€F=ÃPàğn‘ÈHÕlBÖÜ¸ˆÔ&è´0¦ÄÉy1;¹×o´Nş‚›@‡T•~øˆüÆ¹=åÌfuä?ÌÅğ!ÉëC³÷TÑHiùT9ÑÙú×â©3Œà„ÑğCÙ].Dù=!û‰·oì.©x¿óš½|Ò”{jººa£Â„æñ4%u9“wÍ½ Èn œõFI\*v½şš±Æ˜*Òèy¼Ğk
as)³Æë®ÈÚhÓÂ p­;››å'pQ®ÿÀÜ«A‰İğZNd×tın¬@ŠJ=b¡Ó³Ş‰3ÀÖäÑbİ¹½8;p¼Hddèâ–ùÙ×7ëOXeávÜ7íêGÕ_äß'GUÍæü„%İ6‰1kãOYî*€téĞ¢V¬Åâ2'6X1¢ëNşZRFÇúäó½æâ óèÜ§mÛ:œhV¼é•O“ÓF]QSVßµõbÅú0khã¬×¾T9‹”	NŒ}¤  )oæ?ìü™ö‡g·êš†}‚yR©W½N¬g%¶µuBé­\Û9¦ÆévÂ4ƒÑ€ùÒ	ÙD3BNš$ÛÔ@#3ØiçŒ«“@Fã1m’0€eëQ%o*&R¡_"b k£S5ì)y¶ç¼Mc+½©µ”#Ø“'«e©ïÌ^¥Z›ÓËbß¾›ëc8ö¯Õ¿çğÓiOŠ¬¨Ø‘™^Ã~3]ä’&½cò éâü˜ØvÅgnGÑØ×dúòÅ0ÿ±x3oÒ+ÿW™Ä¢
)œ
>_%˜ÀKòLÓ%×™nÌDè ÙÎ£â :ÜoÌ8}ØªMÑiHA‰Íè	s&	™.¤3øíìÃô‹¡*‹k Æº&ÑÌyvUèObO¯?Íäø …—¼NHÀ(n[‘A—Ğ±4ÏÉ€µ:ïmMÊg=Î8‘óù	9¬JŒ+ş†¨IŠVK¶ãYÁÓ“È3ü'+"êî ê©•Ş-r>,–ƒcµ‚µiw*íoÚQmÂçnÃ®|”Çƒ_"åf|(Z¹dš£ÔHÛYghßü+e›Ó€¿ó$yéä@¨Q´·swE(–I»®Dd±=1ó´Äß2”Çf·“Û¼LQéù³.ígòdXZÎQÄü¦]€ï)AOÈşŠN”š©‡Îım0DNÿ¦Œ4/äØ¾îÆ†éD{‡ş ‹¬ÁsüKz7Uå'|è“4oˆÇ3Vn<Î6w´£j|Nº„°høäş¥éÎU˜¼çLÉxiùNU°ÑÁ+˜÷#MÀä¼‘õ`ÁüÛ#	xD¯W?üh8R¯‚øÛ^Ğ@ˆ_¤5i.ÑFÆ‰hDm!"!ëS­N†ÕşL,«±&ÄÿÇŸ¯À­˜ÓıV‰}4èËNş²¶ò&UKêh©}Kë+°lŒĞAÅÿz+s
!!ğqPcÔOúqs6Y‘´ÉçF‹aÑY™zÁ‰*aWãğ¨ıÆ*!}s–y¬k$ı
{fä2P*Ùº €Ç1¶;ƒš~¦éäçi"	7E=Ïæ©ä¿öïRÙjûFz
Ëë‡!(Ó6ı_Æ¹Ì" Qâ\yïÎOjQ?Ä¶&¯'ÔşQÁ“$pÁ%°/p¼´(ˆƒä“İR·òFÈ²éÊ$O¡Ï]%t.#şİæIs¢gS)º¶F^â³Ó•õü×„BĞAïâ]dÖ‘X¿oH-tW,Å¢`m„{`´<ó ¼ëì•±é§x-Ñ½0‡ƒ‚¡ÌãX³‘e[Üü“·±– æoØ¬nÊ”Ãÿñw?¦?»»ïÅÓ¤XĞä+ŒmıeÔe2
ø~=g="sW"øõmW@F#fÃkq7OÕ©rOµf—ë‹ZoKn´FâùLı ºéú?»ª¬ùW?C„mÉŞûëK‹:/²O€ú¯rÌ£EœLÛ„â¸ 5§ús‘!GGÍò[œ¤ï¸¢ÍQù¶^2íA:ÄØÌéaÎÖ`JÒ[°pşk|n:ªüÍÊû,×Ÿıã].ï…ÚİÈ¡
Åú¹U·¿£,®‘Y*ïM$7¿G™]×T´«rL5§&w\m-­KÃãEyTƒf¨ B	‚µB\Ê°^îŠ~f–á‰&ÓS‚LFååxLïöİtÂÒVÕ&'2áLò	 3âØ[3Üj,^Ù 	ˆ@=Vó“½rp*ÖêĞ´‹oøô‹8`m\m=S¼)boŸ°0""Õ©pnÕ ”!£/LŠ6ßx€M¾¡ní`€öÇĞÒ@/ÂbàK¨n’¢ï—¶.É¢j‘ºşptü‹¦uD€˜N×¯ÖÏÏA­sêa­øA"n,ÕÁ H
)]Ÿ­MÃâ)ßÔ]´¦‹#›êUQ§‚O7$ò~\`µŒÙ=maÊ¨?M±“}ƒ­±€•e*ƒ¿ÇõÅ%¸Õi9»¡<qö^Îäc®nìR§Áü‹¤n,y,zT}ThUä,š26û¢8:è˜fme{p«Ôáç^\æ*·N À¹ZùıÊ”°€¡JppŠ^Ø‰b×Ä&]P@ğyã©sòP?ês#Aàz)ş+„kte´¤/&H,-›‘Ê¿³û´E´K×‡ì®=f<z'ÄŸ4Æ>“WAÊ»Ür¶+›TxpöŠı•í'·bäËë#“ğÚJğÂÃÀ,ÆàAmBv¹j©{ªâ’òWÔs[[Ãè6Ow4£^åÑ³¹ö»Å9zZF	½ºô^Ğ2¹©®²/*Aÿğí¡hX¾ı‹Z•–
eğ¢I‰¤cq_y€ğ¡ºó®ªöêš íj@½?tÔ¡Mş~X}Óú¶†›ËF/ºOKì}˜I=¤Ü(öL*'cšÚ,ğ­#ìi.ö%@æ÷OCŸ¡2—}X"­{H˜f9Ïû"ıÃô(Må¹µúÚÁ2r‘lå‰•ôs&1¼Uõªş±60æ/2ï‰C¤ı“2ås7wn9+^#Üô?³©¥Åaˆ2Õ¤«aÄ€Š[Fâî* ~XQh”ÎÅÄê‡¸õÎLt+K,VÿW¯)Î˜ËÌëˆixi6e‹÷ÄBôçAÒ„±N­- Yçx
ğÃÍ5Ÿ0§wõg–Õ`Ds§¤	‡Y¿OÖÕÆ~Yù¢´5(á)[Æ.O"(–.í_5aÅ>HœÓ9s"vª8§ÎTŠD’ğ`ÚÓ"aÎwì® Š$¨NV3c#àIé™h“®¹±Üd¿ä%6¹Ş	‚gs«M5¸£Éè{ğ‘69  ²×O—ï@%ºúÓÛÕºbÆøí“İøÿ$ÒfúÈ
ÎBõKñk”R¼×ıpŞ¼DøçeÑÑ4™2ğ²òÖÖ&TéUÃÏÔW6áŒÉ½óóã´d…'ø¡µuL–ªŸ5G¡TH¬ÛÉjÂİZ…}7kîØ-@¨Ú¼Ö;x?D½Å8™&ã£VA¨*}HJÆeèÓhËÒD>¢±Ôd¾0Ÿ§³Sû6ø×,¨Í :³Hªhpƒº\iÏ±¡p$®¸Nú.q‡o~²ë’};hÙÛ0NˆÏèy_Êôé¬K6ãk.bºštƒÌrSƒÊønöŸ=At÷(4\}¨›W`%m	dêöÕãÛ¶•¶,Ÿœ:w ‚iW;ØÇ@|¶š‹•¹²gŒáÒAøÇF¾,Æw~FV*@#ãŸĞ¤ˆè££éVYV>ÌÄ‡åçR^r‘{I÷€Câµ+¨Ø?ø{)WĞYØÙıWûáDÉÂ¸äk}ÉøIYv\Ì99¹ú8@¹Ô<“gPİJß‚R~Š!rbå
›²¬½+ _
°‚GÉÉ4Gi¡çlF,C&ë^lÆãÄCå†{9ØHCãm+áf2{J%ímˆCºÇVk‹Šóôõğ“„‘kW“+ŞµŒæ_PĞåªıDV½ƒ.têÄÔÔF/£şÅö5t±7Ñ§šå«ÊuJ&M—dĞ •š-å%÷©.—âÂ;•hö#*ğ¥˜şĞ‡.2®Õ¹‡ü_$M…”hÈöS) À¬ÊU¹–bTÓ›‚ö_jDşı&mxÂ tÉ[Z£ÀtPÅhoT +¨×ãğE:c\(=™u¼>]#ˆÄÚ¶¿Mpí2„áÁ‘A †à@o&:‘!F½”
-i„;¡}OÏf‚;‡G”ç˜æŞ‡Ğ^Ôü!ÎaGLQ{jx872 G6e$¨cùp\(uÿzÅ0-·•Ø© W•ÂOa1¾“vdÎÙ–?Ùƒ,®æŞLëQª~‹»® C‡ıÄ	°˜‡èøŠ‡Aì$ÄUéùì‡¾	Á&~ïâÇ|;%ëÀzîŒÎ*Ö)9MïgÕæ¨‹·R/ëÍ<_»bZìz/°İ´Øsş<Æ
€Ì¢àË„.VdÛKŒ±ÕnRËõÊÎ{Ûıñj€|HÒUÉh,™QamÀ¦ *—¤‚*dˆ
:Ùf«ùË¡lT Õ:yÛñU w5«ù-ÏîPšç:Ö .`mzÁ8X¹B¤ùc?åOa~ğ >8ÂH Ê-v<¦ÃË.ìô1^Å?²ŞµD‡íN	]…Dè5RÕ}­Ê)ÀD'´Ö	 (*²fyâÆ´tm"ØID¤‘ÎN8{aX$·¤Gj«&lóï¹Y¼4ƒ¢èAÁÍ.&«ÈBiÅÃÖlÑê§"­á^Zt”]óB²À×ºmuH…4·•ÔX^ÜĞµh‘ÇöpcæVU¦¥Ñ˜ÊœN‰ÃWú1Š×Llu¥s>CQ¾Úªæ(g¹Êeø.0S—;*`æÌ‚Û	#>*øUğ€(ˆzXÚ·VşË•Oå²'š!ƒsÖ€Y*íà·Ä!Àâ¹!¯d(¨·WµT§^6ñ£åî 1‡Zu2„îÊlôÛ®Ûk§ABJ“"&€ä›®ÔxŸaèøÛ@QÈfw4°/drçy:ï@4·wÊ/§QØÔ~z¹õll´µé”rDÙıkİTJ«ÍÕ‡Öšˆ±©~]:,µznjŸÂü¥ıÏ`	ï"±¡;ºë`Á/õ!\Ã&Ú¸sN“íH©Â¡gõ;Oz	Ua1~DËQ*¢İ%z–§»Îªx7NEp›~o§aÉæÚcb²×cA•ï.^¯ü;ÄFÆ#ø„IÃ>#|Vq8a¿­MJ›vHq©¸`s¢„×Cçz;òfû4Û¶Cèlø²%ßSä¦xĞ¥ä×æz_R£Ã«k§,®HZóyÇ`ïj("Ê°p°ñÊˆê,¬g—ŸÀÃ$›v‰Y¸¹¾M½³é²¤UMƒ“¤e·¼]G/öbCsR<5¿¡¨Ëº¦PÔd#+°ª—›©c¢sx'Û^\© î"Z§z"W
@/ íE;«¯Gµuj`QÄa,z„•ˆ:uu­ºŒú}mºÚ4uq¬Ç+‰‡ân`Šé¯7ÍğDµ,"û˜X³æá:{@SŒ•–ÈïI@sI×r˜¹“´Â‡áÂ.¿&”{n{_QjGªäTP´Ñm­¢´¤øb=NÆmdÅeÜÔ¥µ~<Øæ3œµŠ¾P•šyà}=¦Ô"~}Yñ¤ûÆ S¿Q7
	¯s‘§“ô¯¨‚$IQã|ÜD¤KPä²vÊyIql-¡Beî˜ì"í§­¦0Í§åZ‡#”KB»òÛ%Û¶)ã†òEvs\ŒR&şÍÑò•P°È™ãaƒ5Ñmëá>º^±ÛpÌı‘—İtáÚ^PhÍó–ÒXòŠÚ•aÉÕœïJ°¡úl“¬—ì	÷F5Ï¨‹˜F!•¶~ÂtàRK•97oßÈúU¥ÛÒ¾iø<u»è÷p©×ßëIØ‘»™İE¨R±ìº“ùtUZ	éJX~¤İ}Ït%¾Œfd­ö©ûŠû9$’xi*­Š[»e}#t	»*spAÿß»%b·–B§u5¢¥ª_fÆŸ5–eÙ¾Â”6¸¿$;Ûüë'‚Ö|E¢&‹ã]/øl
LïÏW5øGçÔ8a}İ:}5Sõú—˜<œÕƒ=¬Úm
İp‘Ÿ÷QèÖg

Å€oVÔr´eôË*}ûìyµI…xa®ó—H,k×M?e	•öCR+ŸÔSõ5æ7Í³úy÷§÷™c¿ÈAGpÕ¸"•‚åTq[ˆˆH©Çü+-KWY·xº3÷ğ{Ä{š”~Ûy[¤<š£hô)¬ª€u¥v§oı•ë>á˜¡‰u•JP X
†~ØÛö¡É•Ÿ÷[®æ1Ã°ú¨ûÂ®YÒv0F~I·gk²vøo®‘S¿Ltªˆ"­K(ãsäúPK)(VS¢6QÈY+LbØk¬#våy¤q»¸gæ.Ü°Ìk'àà~Õ5¶k^ÇòİñQº4¼FYbğu®—­ó€4Hb\3†PcTş¿Ç5‚ŞÜp ÓT¥¹İäŞSú=¦“ÍkK‡q(G*}é’\la5°{nÛ4 ©F „ïÌïs5Ï=Pì!°Û¿FÍ1’]ó[€ß“¬Ş\ú{¬ü›®Ûù`<*."E9oôy½ÚÑêŸ­”O®e &1]kgXşµìä¥=h	QŞ~Ğ\¬É-÷YZ,Ù¥0Ê9òÏnZŞ»É„Ìj·0škl‹YÍ‚ô|È9£QlÃl~`Ñ„Œí¦ONğTŸK7eÃbà>rll-jqø Z¡~Eõ‡\ÚZÀ¸¢ >@ÙI×ù“æbYóµ•¼GôKşñtC­"D~vŸw&¾5Óç8La!mäì³„%¤¡VâŸ ::ùšµ‡Ÿ(˜1ô(´×¹İ¼ƒĞÌä˜³¬côzYa°ö<~k^ŒçW²øûÁ[¾®âòø9U©·İÛ>ï=sÓ…T±Ÿ¢à>d<;•;H¢sY¬š¬\D,4’ÕÌÇ¦“ub‡(jÍŸRÏ‡b¿¶A›ùñµ+¯,ş’±L^!Ë~§RÙKvJBÂû&¶ıëgp+¢øl¸Ù"0qIB›”qv]4ä%æhËğ‘,*â°ŞœÙJÙÏü¢ÇsW‰Õ©‰¸ì5Å—TÚÛN8ó~L_¤´)Q‡”íxJ8€ÇQ×bj4ê¨ónŞ»}Mš‹crµ›á3+MËîyB{ ìRÊƒÀü„aœ t`Ôş›L+-qyèÕ[*ŠTîœïŞ¦oÌÕ>å0lŞb¢s‡Ãs—ic’˜o¹?YÅÌ„¶D.d¯¢Ü,îmÛ¾Êjaç=‚W	äQÂ$ùº{J&†Lnù¬dılqkM]rƒDéFï¤^»šüG{ ëbB‡Ï£V.ÄÇx@ÀºªzÜËak½z$‡ksØú‹|ªyç?©õ0\Y	4>T¹ÛÒ¸-XíVåTŠÉ¹µ€9j‘Ësr¢x×+Ú%I†ƒ/½¥tOîØ¨áGšÏWRÍ¡1Ü²*Hë|u½¿way…\h‚&ÈP´Zl~°Mê„»HŸ°ç‘d¨Ò—ŞƒMhÀÅ•m¡ªëh¦ĞŒ·›A~ÇKı¿™SÑ‡;ÌM±‰NÆqL#±›×=Icmô98ÚÔz,xj·‘š<7ÃºÿlşU‹bÅá˜³÷EN•é°¢ÇlT‰$jgt!¿³\rS[—óâ­Ìi»´+ü¯	L_µ öì°0†FËJİ1a<ƒœ½ V¨ÌØ’‘-[—¤Ä-ıÚƒ¼D®‰OVúñ˜©¦Ü—rÇ~Gz±@‚\Ù.ê…öÏ'dY—Ö¨Jµ —wr'æ¸¿
IĞÉè%QÓĞW¶@ÊCşvúZgZfÕ}j=M9ksõÙş*ë"VÔº? @Ÿ~~zNäşç„êBÕê	Çì4$	¸ñĞ™Ácaş²"Šè2èò<MúÒZ2&í!zI]âŞïP÷ˆ¡w=Š9¦øü2ˆ§Ô{MU¤bŞ/Ê–ÏÊ\Åd$ŠÉô8Û—aÂ§Ï@°³ÿßjwœr´Üùa
Gí¶âu²/zöÀfé™ş  ­W!±ÙÃìû‰ÿ€·ñœDÒÑë“ÚOùÔ2Ê¶Ú@òX‘¡UMZ¦ä£Š#NÊ8²ØÒ;¤£ôÉÊNW-Üæi)ØİXª¹à&)DµrÚ/¢-ˆš |Ó|$`S î¢>®]3(R¥İæ^ôT´#íé6)†M"1aˆAJèÉ½ö<ß‡A$’"Vmr^t£Ágc”ívù¸\N[·&®‡6"ğ¯"#»ëÔ`y€İ‰RÓ©ÓPFqQ@¸‡ñ—>|µÚˆ÷ùœw[œcÁÇI]Î'³ºo#Üƒ×Ëy$üKËË™İaRµˆE_A÷=(3¼X¥ŠÀ/©…(Ù³R¼ÜzR@<ãÂëZ(MzícÙÿ³aeg‡Â-³Üªk)Q#mƒf‹Bwì¤ìr™HmïrIí2¨T¬…dü¬*D| 	XòJ1ØŠA ¸RTÔ(J"ï5-œœˆ?(‚Ueç’:İ)%ü‡L£ ‹š},ê¬C®6’­ÊñRLõpÜš‚ë:©V â€‚2!YÆ@÷ÎvıEKğ‡;ÜG!,]†eÛq…lêwïÕ©+1nÁĞZù˜¿è©´–ÙjHÜ70£l5ó¸¾`5Ê N?-b×`6ÅB¥HÄ ³8s§–a’öøi™×ÑÇÂÍàvÃÇjºUJQı@êã´ışyU—DØší}vOíŞzäó êÂÊ9é¹o[K™³­='}Á»5yš|eDÛ/ˆöS­AÛy‰i£*ÈÍÍ™RWD5PÍŸ\9A!>şòSøğ/=PÃè6N÷B }æãŠ`£„M3²w‰š1Ug=¹/q‰	2sÃÛ®)Jq®]^beƒ ’×÷0‡kÁ ¨š“I÷{Q{z÷M÷²~eŸ˜ŒŠ˜3ñ85ã8Óêò¡ÁO€U?0ÿø¶¶°÷OÍûJ^öİĞ°±ì[¬¸·½:‰œØ‹&zOº)yïb¯Æ ­QYë¼1c‚9\E‡Ê¬¶ñÂšæş~<ó¯[ê!1µK§miªè×P:Í"/Ğ¤%[‰‚éIwÏñ›ÙPŒ%Gı²ÎJ6áÄ¸ı»j°„h®ºN©H¶§tA#“İQHßŸf	ZG¥íìqßf«‘îòƒ›á”Ü)w‘#Äø{İTàÅm€`ÇQF}î2Æ bu¿f%ëR#¦«#=M/‹óŠ¤¢›REÕİ·Dä<ê´şQ•¸h»"€¥‚k$¬D–±s×AÏ	™:×1(½€oQ«ŒRËÿÜöó“ ŠbcÊıßìü¤"j”­°s.…™A¾ÏL†ä¼)RÚMD÷˜d ÒÿKü*¤×©²úwŞ_ ÙcêRóiÕÅg¾6KÃü…Š­ü<ïÜÊşv|p;ÙEtún¹6µ#íÉà6B©»»|â/   øÿT~ú‘B‡’ç|Sƒ”¯øÔ—Ş˜ñÂdŸ±py-¾IFm®êŸÁ[Rş·t6½Šo `ÁC$„RÊIè„ÅVòÏïµÇ¨Gf¡™íMàè’äH5ªÏÌ¯‚|¡2„Ü©Ìóuôe`íÎ¤©"(aSÒ¬»çÜ7'l¢4—‰éQ(²¦jä]…ºä\Ãc´=)êwÆêÂ9ÕäíÆW¾ê3¦†OÂı “>×aJL]¸:½e{ÏøFékd‹ñã»	\«òşaV1xÔZ!@rü\
#¬¦oâ)@€kBmÑO}áÙzå©Ï–·Ï ”ŸPX>Ïïbßê~ûëAáNl§Ò'ô<Õ}ÌWŸ¤[ jÇëi[ÄÆsÖŒ˜U¡nù–8Ò*[IÖµ ø!Œ‚ó¦z¬ËƒFŸù•„9ÓeDÀù‹ğ8½¿—0ÆåXĞØÆ¦F;½Kn!š1s)Dn$Mòp€ã»zn¶Zmh#t¯ù4å¿ÍÁE½½è(O­j…?²Åì7\²µ$¬¦—êfŸ±#/wy(ß,bhšb|$šVôÿWö¼ ŠÉ>†`ZÄ9væÒ€^N4‘Ç[}¦”o­ßNoV'FµF+kEó|<êk-ît­¡naÿÓ)…¹Î…j2–Éî¶hˆ¹“‡hz—¥Í9ÆVŠ¿¥æ¯…bd7éæ–/Ñ¯»àAàÙ‡<Yıâ©‘F1™MHÊ»,D- Ñ9öÛ ¹On[/œÜP¨}]È…“a0ÿôïRÊvàñÉTxSTf½Çê¨sRğ¤˜ß‡ #¢ër9Âk3ŠºÓ¹:ïƒ;¯'c(‘§Épóf#`Ì·tŞ_iûÓëà…Ø<ÿlpq7*ş©Ü£—¨W=85s¼«±€vs!Ò'ª8C4İaSë[/aÛ÷©ÎLıÖ‰Ÿeup%ÒÓgVeÁhò®n…Ò›ÜÎï3õºù\éOVe©_KGãû‚mš‘ïçky+“Ü"çØ8*Šõ´ì‰šAluÃ7Ú°nßÙ]S‡â)@YŒT$Œz•İ))šÏGYè{³`Ï#Áaö¡œşÒÚçJ)[—îó‚<-\!ÙmÏ+zŠm¡­Ã‡ıª˜<|1´ 0k*ãvñ)áœfšĞ‘ZC”òà‹š	¼–ßÈ#Ò „Â}W ß-¼U¤ßİ>ê>Ÿ¨§İü’¾Á îÿÜ©	òúB@qo=ÔjQ_–Ñh7³M¥­5M¿ÍÕÕ•*_üİómØj«——İŞ
è ù—BÁşL€¸Ğ¾‹~ş¼ó¯4İ ”6¯Gò‘²İ²šŒ_ğË­äù©Å3.}¯ò¿€h=MœÊĞ'{5Ä©<£’Wp<ÄZ<¸ÉğÜºå³\Š„ñ¨¸[e¶Š©3Í$Uß"rbÁ»ÅĞJÙZæ$&‹ğÛëûGßŞ0fâ}mn»À	ÙÆÿÍÀî”$ùFl˜«3K#éñÏuü&õlPcn¥·#Ùü4ëÙez\ˆ¤™Û[¹¼ÆÌÄ‹.Í7£(a4	‘.ëM–cîljurX6§ nŸ:ê}şˆ}(”¸5uÿöh¬uÿ†æÄšÀ&Dî[Cõ–¡òVäcf{÷ªâBxÅeT®Ì]=’áõŠZË½R©–e6aÕ©Œ”8ÎsXK	#˜×Å˜é)x`4İü+	èAĞ‘kTK†íó0V¬$äpá•UÆóÓ^^¯HBvo3'A®Ä¶¿rfdªùéûz~³½ó•DEÀ‘Æ!FÂnÂ'·)éËÜ¯öûë÷Ru%ØDùØ©<5€{Ua§©èCÃ(Å pòÒÎët€âí¼¿õáãM·(0Ë‰Ö,Y„ØM,öõcúè2oÒ½Ï(ŞÂ÷Cœ×Å—
×8úöš0––¥†~šÑÎ¨#j“ó¨TkEèËã"ŸhZ*Ílû–1+´pF‰†HBë?•'lÔÿm0<é rñì Gh“’Lúélª—-3³ æípÇ¢úÁÆìê‡8šçğ]¤pÁ[…xé4åî®Õœ>Õ¼1!G– úÜ0â+×hI'®ïr­1	0²Ê¢Ú<”ô~C1(Œ‹Êa0É[oß‚ºœJç¯óTîHÿyºêDÀº&¿ß&zˆ¸â;ı4µyW:Ö×[ù’/3d$–µZ•i—Â}öcé-^[ñ1Õ:|m4±ÊıóÆ¥gV«àŸ‘”Ìv—Ñë9 wDdER(s0|O§ü©\W1dŞM7åá§‰ó+#l’…U÷•œ”èŒbŸÃË¶ê‚ı¼æb•ôpyµù4Ô™'k€÷‹1j¥wrG`v°™8‡ÍzpäÒ¯âUêÊ*ú<[—âÿÀ%ø bj¥°†_ÉX4”¹ä5Cş.½A°ækº¶-Í…0 &%yV}ú™,0¢bhÁ…÷Âß\ï´n/â(vÚÆò£œ 	Ïœ|`VmyÜF¢Ú¨ÿR,°ş]ÄÏ]Ís‡ìª„P×,æroÍs[¸Ëà;.ÔØ´Œùb{4à#kŒ4áïĞ0Ü@#–{«ª#á4ˆR(olƒQÏRKSì§’ æ“…H|”YøÓØ?Öÿ£`Gj-)1İ'R<¬éŸ÷µ€` £eãJŒÉ!À‡yH5Nÿyzm€ÃÅÚ¿'S¥pv àŸ@†Ü€}ãînC†*äWƒ1­b•àQÖ'1* n^§çu°‹yèòğ²X@bG¶oqğIŞõş#ó‚)¯£j¯"Iq¿âÕ){&nÚ§£Êá‘ëh4Æİ…Å¤ êñY”Ø$“ŞÒñe]¯€i£)ÃºTÔW®y…"ù7n
Õõnª¨$Ñ›LÄÎÌ1kI|kê/®HU†•ªnáĞ™&<Ê-ÌÉVüÁĞæK®³#[ó(5qîˆ£ô•RRÄô“òYo¢…¿>kn]š Lıˆ˜oENÆAßÁäÉ"ÆlËd+lş+ÓyA'eŒĞğÉÙc©gÙÎÆæ,ÿ*ç™êZÏÅ>Œ(Í÷0«\aä/IÆ%)S`àh%¹¹;­Ç«¾—
õ{o’ùø1^]@q;¹ËK@1üdZIïÖÒ(B5ìY©N9¯u©Älérz·btö±ŸÜdOÙí‰*óE˜I®”æÊF Ëi¶HCgI¢
è©º@çÅöşj\¦|7oÆZ…CÂî¸Åû>ì‚¾ìrh•n N<zDKÁ‡U[hº~ö­ú9Gµ®ëó“¦z:<H¯ÇÇdÍ<Â…Nû`.Ä¦¤SEŸv^‹Ì±Ä©ÍŒÿ sË\4~Ëõë¥F“?i¨àªå÷+NÀ(äÅĞÅòiğ3t=EP÷	ëæÑ>Ñ»·şœgÙ©¥nŞ–Ÿ;¸MÁauDËñ½ï„`/á™Æå“<ÔO%´N¨F>ÇÂ|pËá@#õCÙÚ{šÜ¢ÆÕUâh{=±r‘¨4Q±, g‹t^Š9Qe.ÕŸªğ’yM2ºŸÅlKúPµPiİ*\u±^!l^é9ÎéèùÔÃĞÙR`©ŞòV£`Lá†vP(3oòVr]i¼½áæSö§â£G¬Úl‚QP%WévY­ ìÙÃX5Õ‹ıQıò¿'Gù}2SL|Ú9¥røgì¦ã3!ø¼›B¥*£ıî[8Û k1=B?>©ÔÊ%:û}Ûªş*ŒwÇ«#æÖ gså¶£!iSñ‚Œ—k×b^ghÛ™ŞÅÕ§_-÷úlQÚÅé˜›%Pfìl]k²p¸ @÷¨uí˜orÜæ3¶ÈÓÁî®Jï>V†£U¦|¯¡šP˜'ã›«R-€W¬¬Şo¤^)Móÿxşa­çVõ°C»€!Ëß>Jª­ÃöĞj¨=ÎgpÅÛÃ`¢RÀÑ£ë¹!"¦V—’F˜ú`çrZ£KZ{±Ğ´Kyë´‰âÕz-ñ)pISw¥¶›Ÿ„ÒÎ9pìMùeóÁ¡ÚE±èËóÂTV*AP4Úh+ş¢%+ê6’è¼ù™Ëï[•œ ‰ôGOç—1C«vœ™«÷ı0já„ÓªÅŸŸV@Şx©lÍéá >~àz”ä~­$–V„¾£¶yã•ôÒ­{4õI è­-ŸÅÿP|k°éŒ¤Ò‘^éjö]—÷4·Åg˜b	dìZ•Ú•š1é7„kì	st`Õú&/z{*h,l$	{5À´,á)Z Ø`°3ä÷‰“çq>{É×X°í¸¤:f??~åG"n¢¡ÏŒÁ-òÍ|ğÑ
9ˆzÇ@”Ûßs”OàRb~í×Xx†t—ƒrh\˜‰§³KkİÛJÍ©Ë—Â®İ4wÜk[å(â§•¶ş4¨òŒüFËzöX™’'LFn/s‰‰5kØÎúĞ¦]³åÍ‹ä²¥‘LõT lü9BñoKM	áÖ‡KˆÌ]ÇÎ±òÒ(¾Ì Q/×aå0mBŒÀ‡’éãßl Pªø§ÌôsTâ»·SÀ3fÕíªİìĞ'+ò€o•Äw‘ş%dìˆış`®èt§Ö|ˆ~ÂM2^O©'˜X!c¶‹}£ªbß²Ñ¦JYc)7QƒŞ\ú“Ô[ì·TiEí¸»{ØS
œ³i‘›J G)ÀG$ë™o|‰æšé8”İ¹™¯ÉbªÏ€ô'ô		D%¾Ù@B&tô7¿“¶znîbº®cÌ(ùµ¬VQHkC/EİÛØ É¬w7¬XD‹°Tğİ*Søƒû³ Üõ¾_d§ã'ìº#ÚĞZ¶Mû”ï"á)$şW…û„õ{Î´&È=q ÚçÌûHlŒ¥Çqµq_5™otœ}ÆäG	qïø…m1™™ãˆÊy}[˜Îğä*Ò„QO3æîø]b¤áôÖ3.ù‡víl’ Ú pñG	¢p*¢cj:Ñ2yÄ€¥hBÌ²öş‡§Iû~à¢Ş•‡D-Õdª5íç¦î~‘Vˆt©ªUt,t/\V ^ÃÌ:çŞrF ¨B ¾_oJ’‚àÈ„Q€1€–|üôc	Ü†ƒìˆ<\òZÛa<+õÃÅ½ıAt((ä©a.†D j·Ñf"+Rœå6.Aà,ïòv/2İìÓäŠh—ÕéŠ`áĞ¤ÿ/¯Ñ	ÚğG’¶¼cfÜñå¥Sæ›Ho9Ğå«Éwø.ò/ßèĞ‰.“µ”oí`ÓakÆ¯İ‘¬uåp@Yt!,¾èGä>”<QšÁ¸‘	-xPµÂ:ŒW==ò-«*p›tçDP 'Ìw,!ñÁEâôq²;a·Y8•xéæÊ ÅÕª%³ÏœçÓÜ›L9l¼‘_£²qŠà›ËÂ)¦™^ÔqxÍœÌ? „û—ƒNƒÚI4àä(¡	¬*Q·îèT˜H_®ƒ¯Ø;tnÄ¦Â|ÁöñzÆT¶ï­­*‹Ù¬%¢©Ií¿–¬”ù€İ˜Ğ8nØ
FÈ4£´ç‰Tÿ0šsÕGå&;Jÿ©K·,¾b5r—n¤áZ.#Ë<½_ÏPæ™SWWè{|Q²~å&X©HxD,Ùé9ş€æ“ó)İYğÊÌS	ï"»`J1
Û1³šÏéüÎù}êb¹lµMUÙÓV‹«ç3©Îd¤a0ï\V
_Vï&µÑzÑ… N\Z•–õŒ$îÌê"° '7ğUëVäŠ:¼Ùª²ı¤ôÚ›ckĞ>ÒN~âài»ñ´Z¶4*‰MNÂ9³7»µ­— °zoìÒ[UI6_ì¯oıqa„Ó:°ê²JEqdµ±¯¾÷6åß<¥AŠQ3yŞu±oÈ€=j­•V<4´ı´§ê}¨ˆ[|Ñ´L[Šp}Ÿ—m¥2>$b€ÛÄgU·5ªtµúÎ¼ºŞ[Aı¦Í—GS¸PMaàÖ…äŞ½}ç]¡¥GöÓùö[R!cõÛˆaÌs–ùô¢DfåOïÎ!˜1£„¢ ¾JÉ/Œ‰ê½¯Ä	/y¶º	°¦|ø÷T•9/Cz-ÔéIa¨ÀK}-æ9ò›è¥$UøI7é@“ß3Üp`ó0>|Kä3^*Z~¡1ù%¶hj7ˆ¹¸LÔ”ôsõŒ_f)	Ñ=ë»ÉEËE5*A»¬¸@›FÓz‹_wTèo¿ptëç r_f½,L¾@4veuULá¿Hk®Õ“·_5æ#2Şe[](Pg=!ÈÕ®m¶kÛ
Ó¤TUé°cL§ÿ›gl2“º¢Ùİ¼Äßtjfö¸·nzKDmeºûòÈ{	•©k¢¾¤†®ù­Ï®ív®‚´ 
¢kõ&Ò6X{f@Ešâ×Íg™—…Òâéà1z–ü „ï·,¯fÖÆ7ùÿÅ0c, RÿóKkPıu&ÈfÇË0‘=&™â‡Ëáä)BmOíUë®¼‰€È d3 Ù½—ÌËPŠäª~Út]––!I>+q`æÙå#šãáû/«,9©Y™c#3& %¿€q"ĞıàD¢P†W±Çà´¼şŸl×wù·\~ñUëˆ9˜õ“êz2“[•½Ê+£UŞÂ26J¼´tIş
Æe»kkB•5æIINù-õt¾“¼}ÙPA_½„Ëgƒ³—*·'¯áyâ2Ô¿ì=1ŞÚ›à¡‰ê°OîV ıÇîxdÖKšú8Ÿ8c]‡xKŠ_Š¤¥As]„Í¤.ûs‚Æp£¯j×Êµ¤İ	²øÂiâÃv[#0á-MÕTÑ5u¬3ƒßëpƒ	5PEÃ)sÔPûÓÎÌÕŠA˜•Hìƒ#k8/<’öks)‘,!~\;lŠw+şü|>Ú8ú3ı;4À˜b|ÊÅ¤ú"5aU&i™9s‡Ôšì¨¥ÅÈ§í%á^o°ÁèåwhfËcãxùİh9ZÉîW–ÍÌ¼ntlŞ+™çNòÚ*aŸ¼zhGŞ†ÖÿzıoWûÇ"ÉLtÊÉò} 4$,U˜d7Æİ1 ]]aû/"W})^Û4y2SeÈ=î“`‰á·á²¾{~n0´²ÃZæŸW-ªŒC9äÌÁVìÆ)şº¬©ß£.½À¡±ø˜x‰g+ö*<R*(üŸI82s<,a¥}´$§w
£sX‘7’jÒi[½PtOÄºİ•0mz¸®‹“!zçÉfcáLè¾¸}È—¹ìSX5àÆŸÄış–G|!=I€'ØÀÿ´—)ò4Ú8òâÉ”½2¥¥%§ Qõ¸rR½(â;Å#¹‘`rAAÿÊ8úë¼gğN€é³õi:wƒU¢Å£kyµßiîıœ±çº"$½Ía³ãk¹›ÏOP<ÛÜ¸,ğ+NK¯–D_/¾nïäàì`©æhX10Â±1z[£Û•Ò€¨Zt°ƒötó1ñï’G#:®D'Ó°é -I™œ 9ôíøG$cVÁ¢ ÊóÂ®‚8-»Óô2aş'`+>ÿ+ÃïF¾|££`‘Ñî´yÆM–èƒN”w&ÜÈıÀWÓß›–?ÿ°w.4>x=±´Æz}ã'bà‘ªvÌŒóğq…e¦tš3„Á4X(²¶;µ“ÀÜˆ
Ş÷kÆHôNìYd ÌóMŒŸ;CpJfFS'ƒİöı›6BØo3¨¬"7ÙIÜ¿šI:JÅç  có\{¸BvßüõúOFA€ñšØÔ"6keÜ*UÇÂÃmÍH)lÙVª•µíÇmÃh.!¢¥İ<wc´zE‚_™Ò19R%(ÆşŞ*âø_ú®#†^îˆo#&Š9Ş@Æ„ÁëŠÌ>{šZK…ZÀyC¸Ë×'òÛ?D¬lÕÅÌL×(|‡|é"¨tšËM@İ d0¼ª©\/ğÂäEƒª¢|LS6²85 ö¹¤ºÅ)6&r‡oî9yøµ6 ²lµi	•k8…’ŠäK¶WÒ•üËÈu©?ÇåñOE¢H|ÊShõ,¯wçªv¬°ßõ-b`1s‘rÇzzğ†—š?'÷µíJyÒÂ „Äd´?‚Òe/øa¢ìÑ¥Æü¬#ÔÒã~&:ÿ	í¡‘¤îÇ¶ñGE²@½I~ÁÖóı‡aJ8éÕëZoUÛµ3Ê´	,¬’Ãó©×æ²2¥“ÿ;İ×ÕŸä«.²w2$GM9Ó&ş4%^¼í” ²3•¡Ÿm«ïmÔJ ˆ9úÛŒ÷ ‹ÆõÊ"Å¾ŒlŸ5c¦©"Ç	Z÷*¯É‡ïßFúku¶Êâºo¢ è‰lAÂG]•ÍİŠôg!
!­h0­»½èÜn¥Rõ9&ƒÃ)”4Uù›lËc,PÛ“¢Ø³/¾Ûit™«˜â³ã2†ş#‚æÜWk'‘»½Ë÷zøœ‹“¤q·u¼ÀB¤t_Qûvóy Êë!×n*ñµ¡–+´-•îç÷¸\7ÅvÂıÄ4¬†İ7æÛğÛ6«­^O÷é35ò"ÍJB” ñ›ş©EäĞaÔg…#§¹DAäej=ó·ÊüÅyÌ,ƒ<úõiâßò-h‘ÎTbP»NË¾C%‹¡¦ì<c^³y¯èvd¢àœ”_ÑßæheÆTÖwd–ô†òæ³ƒçpÀU7Ê]Iêé‹ñ äm‚XI”¨‡‰¢BuÄ ‡BØ­AbZåï¢~Áù¶7Qú(×î³ö©|ß!—MFPâZµàó{I…sº¹lÎì*x©¼¶·Ò–Vó£ˆ*MÒ¸CïÙ/Ùœ=|a.è[N;S¹[ˆÆpC4ç÷Ñx-{S—®•Mù„2
Êğ+âHÕùÊ˜S/‡Ì”æQßA¬ã(T%÷¾/ÔdËÉÒÓqûïËbÒuí»«²îCÆk`n ú?AÆ€xF%R;³l Î53t6‡ö#á:	xÑw°¿@!K¶7ê™İ‡‹¤]¹òÔ]¬å×±+÷7RÍÛ‡y×’n;ŸÚk<Bu¥ ÊÅŸÔÅ¶(_ÄeÙê?åNC@¶nIk—BÈÕûF£1rX,øGæÙ…ÆZÿÀÎï«®3zn¡…%Ç§êàˆE$êø*æ|vË–Û4ÂYÏJ@Ñw?¯	ÿÑ­/ *K¾$–²FÂ§;Áõ¶¿ö0Ò	÷ır¹r{zÍn;ˆÇÜâ--—N
@„½
ó
È¬ÚåæB´aw5PoÚbø3AEzòŞXâI“¸M.ˆÏ¥†¼-¢(S¯’n¢ß(r+£ƒTî:l×z/Ñ¬^jCwâ"»JoÅ•Q`ê‡‚AB wgDé—õ¿ÈËĞ¦›Iı˜ÒDP€ş‚ÚÑÊ¿Q"‹úXï»Ë¬ÕC9>Š{;¹+R`m›6'®Ì¦]İ¯_b$Å¨RQA^&»-O„K¾¾“—IƒñBf¶‡
¡Pc×“ğºËø{¸EÆhˆ0’ª6ÆÂë,ÜP£
^F¬¸·6Îø…ÀÚáğà,4Iù#Ô8y¹«nlø¡©<æÿyí#Û´KIı€ƒ_£X¿¦íóK«6±Éö‹ZAQÊ–¡€Ûµ¸çxMÊ¾f;äAy}åşÕ?O„°ä|íğÖd”Œ”ïÈ÷†‹õ†^·`eÃn¢.ÛDJ…-X{ûìYÆÖ‰j*JH\ØCMTY˜wˆƒ•Íâ…Éú:	„İû_¬û"²ÿĞƒ°€6”Îˆ¾µ—-i{ûDU…¯a—‡µ†+ğ¹}Ÿ2Ÿ·Ú¨ªî4<¡Õ**ØÎJ ëOÃ˜ª‡²È§©‡|õ£oc°ú._–ƒÁ-|ğ{Z@Á…ÜĞJ)ç"è–w†J±u±·ël¦Ø %g¯­ÅÑåĞ·ÚšÊ·‚Z½‹½V“È-|İf‹´1j…óï‹®}¡Å8xˆµ˜â­6X‘]!çsGEåJ £*Ú¯ë¿ékÎ& ¶© E5k–¢•ÅøI˜ÃDùI+9Iµû¦Ã{øŒ&	¥„yHú¢f0ÏÃ¹ÒØÓğl]™«Ü3…†Ü1•&µÄ<“¿(Ì¹D¹¤ÄsŞœ”åŸ#Y“§I¨{;ì€p»Îï×+ò S`£²¶øFÊïÏw>çn¯ß‰ªãõ—W³ïAÛf>H¡\’„K!c&Ó›wO3-í.2+’ÊDgƒI5Ã[§J'n^±áQø~ 7ÉİŞó…hDÁ®²¿¼â‚lü˜,cÆÑp"¬¡ŞÃ3JöcäÁÒjÈr".°ià
¯dü‡ËÙÅ"7³;	ÆƒÁ‚,Z•}a­ZËæX2Éc7ˆ×QDAÁM6	ÚÓí)³ƒk¯ê1ı³sû'§Iz,cò›Á
¶+U£‡+»ù™Ù,ä6şQDzwTÑ£}LÕåÜ’üĞuåpn/=#4¹Ûë»Ùøi¨Ú„¼tƒµ¿òÖ”E^$L”gP}Ça–x2¾‡,\Xà/Q)¡:Æn3ü¨(BÇË%Ö1,mXŠBqmÓö® ÌêĞ„À~çç‰	Ü—ÚcnŞëÚĞ®vZ~ç®‘‰RÙm‚ğq1+‚å"œ)Ë¾ää8!ÿ¼´mæëq–	V¢{Øt9š´Ó×åEKúwÚsº¯–ÃCÌ<”ÈÀ›œhC	®ª;¡U¥?KSööÇ±Æ8{™ÌÇUŒÌí§9«Tw$óuï773tyªÊ Å­_¡À?r#ø?xğ§±{Í£XĞ„È
âœâûÉgæÂCµÉ)ŸLJ—}o¶¢‹¸ŞmJù^Kò:½î$4@PS9xÛ¬Ö^UêÇDï1ïÔdáEİİvéÇyêŒSûÂ…(e¹İlEËºtÄùhA¤lª›1W.&_§ÕLıD9Ù2ÿ‘­KĞÔ¯³znmù]1XT¶'àŸW¤YN6~X†E€ç0K²‡ZğÆ–ø¿9ìjeïkôÃ!Û£¦$ ˆh¨® zØ8ıLyø9¥w¬ÀJ4Åê+ä×ÅüÃ(²4»ª£6Yèè¾Î¢rG6ÒˆÍ[’V±Ö†VH? >dqŞ^‡¥hg»æ"}˜{™ÉªŠjl‡«ôØ:‚½ hîu£©Ñü_<¨Eç”¢Us?ó$üÓÖ”ƒ†_ì²èÓÃñ‘œVÉné¬ÇÇÓ:Ya¤Î8ÇãKI]¸€DU»Ò‘+7õe”ÏTY.m%Ê—¤÷r·[µÍ!B`­1 €càJ©u{Ş_`AXHs¼ 2ìè§²P®qvÑ•hş{
P¹°Ùãæ¶ß£›¿"Ù±¹ıàãxõiÎS›ÿ ®vv.lšaÂ:r€EÃµÎ§ 5X*ƒG›wŠ€Fïİä(»‚ÃÖï9…i'“û@[Uğ|<GÜ¥C&Œër´Å^R¤ 
ÜPñ^÷\öwM¸§ÂÑH¢ùbkA–íŞL,hƒÉˆ0ö\ ãy úÖİ+vgİˆm1×©¾f‚¶3—úËòZt/CŒkVc1:ız+áq³TàÉ¦$ÚĞÙI÷iL­ÿ#¸¦òÖ”>w¹³BÄÁÕçmĞ¤Ò=l(+$Š%->ÑBÈ€Ğ|E¼Öàz~İ;ØFğïŠˆÑ§»m	å#`B†‹ô­´3£ÊüWBúT•[Oºå› q¾`éˆ–ÂıêêX¼¢ãûJC¢Œ4[VòŞ‹°ú)™,ë^GÌ¿5‚4ÕXï­‚”~ØÖ”ãr#–ï°¬w‚œÑ/£¨
Òp¦Ú5ß¹ı“@6÷­¾FM•7~rÄ.ó”—ß‚¯èş{ëÍÃtä„6Ù)E'7“7F¾p4(œòYãŒ2o4tĞT;¼õQŠƒıtöfs£å2¥¹h¥x š¡›	s`U2> Zké “¸ŸßÃù
ğ~£)¹`­”]aWÓ…Ûäxg6£9ÂÌòkŸÌ$†®À?Üğ¹¯§#ƒl–Õ[vo|}z|,3É×+Ã·ßµsãÉ×EŒçù\v%ºgŠb
Ö†û÷2Ÿ2.lmêÄ#ıb&‰óçTyÖĞåƒÎÖv€,¢’×w¨|oDÄMzâ÷ëÕ{k˜ù
ìYàUsÃeO6ËÀõ+ÀÙ¶.Â°Uk04ø+“*¢¡¨ºƒTF~Ø66 €‰Bè°>.7ñÏY‡|SiKú9ZdE:H¶$”;Ø<‘#a“ryµágnÄd.`*l”Î_2Ú5øò(au–ÅÄç<Œk.'¹Ø,=ÏÏƒ´20ORé“½©¥/bÑ=ÆZ[‡X÷G4…ÈëlP3Ìæ×øé(²B gRÀİ–—[ ÌF¯š=D# (1™ZH©ÒG2Ç¾ªÈõ-ÖFÊ|®;KˆÉ™{Éâ¾Kªv8\‘è‡:¢ÜEQ=‘üßv„<Zm$;œ_ÇôF`v—q+ƒ[ıÉY"¸*+b…Ï\Ç¬àëw#ôí aÖxÏs?Õ‡6~°şUiTİ.Ûù’«ô¾µm^åØ;•à˜©ª~Âí1WYÛæşœı…¨…1÷\qY¡Êyñƒç¾¦Ük¡éTŸˆGƒ²¢öû±µr|g·ÌÈèk€}}É Lz‘;ìİqÓ›ã°*š'9#¹EÖ/Êc[•PM§¾º€·jØÆÇe°íÕm=’_³Lã °÷-d†É£®ù!æ‹hàLZJU÷qKY…\ZÑÇÔ5_~ËŞ÷% ¥Óô²‰.JY9è]Ôf´ÈØ	½+PÖVÃĞÊ³Ñé<øéMÖxÜN {A'íVÏ!>$—ïFcA5<=­DÃ,AFeŞÑâšGB«kBdy	s®±i”_°(ôIBpÎL^$úÅkš‰Dt4-Eá<Ö€ÅÊşõ"€@ã-…v¾\C¡M$ÃÕ^[¼ Üß|Nß#WEjP3<#™-dú'¹Öx2—ZóøÿÃLøX"$O)¶!ú{ ;õOn”w±H–hìh¹I·NªÜÄ†×bÅ'GúLrŞ3n Ï0gŒ”x5»)i¨µ8Qê_‚h¡÷‰|^ŠüµîÍ† ¾•zG-a<–ª£ş±ö¦q\æìLŸrièVëš•Ÿÿê)¬m+?A'½is;I c’‹‡[g³Û´‘ùoU…¸$r‰*Ğ!©{y]šÈá3¨xë@-|»Ì*{uÔÃòaimìä°½bUm”ƒ}Ë±mS‰ˆIP¢‡#¥	‡rŠyS2f¨Ù=@Gîê¾u÷ş§ÌØä„jÑºŸü<H\^dpi°Š(+¡4€F`«ìÕÒ.çU¨[ûW_ÃOµ‹ıYÇé§gn™üÜğé‡i¢‹Õ!1“·(|háÍ—4íÛÒ½W¨¥8kıšnÏ=;UG(nÓ‘èm¨4²ã·zŒn«™
0™Q„eAl¨çw>´ŒbÏX	ÌœÈ!8!°-àÕ®ãvír]m÷M¡R®>Cû™ ‘Fó¦NnYG…ÍOn1Ÿ5K½p†’yŒµbØ¯v½¤gçê…JÖY÷£cã¯ó}œÙòÆ£æ–B›)‚8ùm‘Ö%.iyZ›ÿ˜†Éâ‰ƒC¸æìâz1iXüDœ§cš=C9–ÇÂx(gÛU;Õ&‘|bŠ{YÚíqBßCÃ? µªÇ'ÃƒC0ß!,ªOì7İP× îyÉğÈ,‰£Ñ¸F¨* ¨ ¢R«²(àAÀó$õZf´.ƒ‹#jÁŸºtôı.¿÷æ·ØL³µp³é$ôB$53?j¬SpÓÊî*T,k„ÊØÚs‚æRJLWAÆ×¾ñº_¼"Èüc¦Ò´Í£¨ø£ÉÁGÇ>D€õlØ*á"&óØ%~¯óŞ`K¦A€ñË¯=ÆÃ£ÜyårSKÌ	©³j]¹Tõ®:6p£¼š]E€\o•E‡{`ÎKawê+¶ëeõçöğfÊjNŸ]ñí»¼N	Önäï€/È1ÎwüÅs'p>2­uµZ·k,»¼êêzÄlà6ÄvÉÆ7´æß-mí6ÖúÔ›î]7‘O0Ñùƒ,=¡Ã5X‰drG@&HBÒ.Î¯Õ±Xœw’°^¿úcPU= +s	c'¯ù!üNjíi²šhÁ$uCë/Ào¢])ƒ¸\+â_°ÌƒHkÁ:¨e¹fYYñnTÇ_ƒSÉfD}$iM¥Nl×ª#¦±ª&±Ä7ªÁPşnÔ»ü¤ŞÒ€_ŠQÃ*#UQ¢"h÷‡İ61ji›jŸiô$½­&“vWª©¬;l{ÇMÍZ˜ıä$neÓjğ‘k~Ğb­=âŞ`vÑWõï6T,„›Èàq£š¼d%äÃ@ ¸NE¯Ëã¦pIco:ÓzµÖéRWË“ªy­~PĞbtÎúT´ùÿ Jˆß«Và{ØD™»¬V…5êb0×tÓp).ÊŒÓVëº¹3‘ê"v|Kª´¦°Ö¯Ò‡‚²ÕËz›¹·5sN…awx8:}­ò§Õ]–Å‚¬Q”±§EÉ„»ëŠ€¼n¬{Ó:÷{ÈvTÿõÊNÕäª¾ÙË{ß#Ä«;0„šç=QGĞ‘Uâ‹)ããDÆÎ	R-©lŞ*¸ä½Ğa=Ä3Ï
TY9?Øm%İ:¯qÿØ6mfş¶[@ö ÿú{tvßø–vúPòg¿&{ê¶¼H—ôÃœ§©š<õ/oîÃ•¨YÀe@»ª»=cOY(?mõ;(©oíö“aZU³Œ¸ÿAoÀ„.á¥c¸=lr‹Ey÷Ã×±ÍãİÖE.¤9±aé7§E§ÄD¡$?CÇË¥lOl½Æ±|æĞŠQî¨8?uäz¦e‰ßàúİÜTã¨%„ò£4Ã˜{%âU³?Üc¦)ÓìA¡¤É¨ †VG2õlP¥ÎŸ+ŞxYKê¼fÅÇ'zH¸†@)O§UÅï;_Fígl,¥Ç‘…j¦Éç{4¾œlÑb|®mx/‚pkÔOÏoÉ]ºÜ«Æ yu»RÔ¢LÌuù‹ÙºDâBÅ>	?_øÕ|p)I~â%‰y<‡hı1¦R vlxèê‡HÔù0¨éX;a0ë_–·/HVs‡1^*¤V$ìÆvJFQ–’ßåb"/j Ø™sëôÁD¹$à“mğçœ4ÂDá·’Êdù-ËF­ñ]perŸ¶¤;h¾^6:²&sûŠH5’¸{4({Em+ÏkîxèhĞ%´â&÷*y^œh@6‹§ú‰n\UíÙG|Zù"O\IX†è%8à¸zºŒöAÃšÖ8üpõ'¡/ú+ô	ŞÀ¦Ö\ÊLh+Ôz…²GLèìcj,qëÂä\aí½b¹½,Ÿ{¨lßıaÛªâ`%mD¬·öc.ÕO™¤°¶+|ÊŠ’x‹›!lÌşQœ%ôÅÆŠÙJ}|'(ŒTlJö_ŞƒÇ¨ôÙTÍ§ÁğC)hB¿~™W©6Ç_ºı	B½ »VQßœBÒ˜Wœ¦T;í{ç§U=F–nç+hµ>@yÒØ g^ÂVˆ5àv8n3bâ…Õ£Ø,œÍ»()6b|ä"” [øŞÉßªK5ÖjI1DÔ…9rŸÅ³È™)5qğò¤×ë“ĞÄ0r÷ºúš½@©0>Å²Lı»äl»øÃn†´üCw=W†¥s]Ñ‘›$Ô¸¯]i‹^„ÏÃ#cßà!‡¢}@2\÷ËˆõpWİ j\!ôÎ;µò|;mßƒ%?E¸+—·/ßSşiö;µ.%Tâì¥ed42 J>ûP¬Eİ£XúL ÍúşŸqy7·_«¥Í$NŠ¬/½áv×³Q!HoíoëH—î>W°£ÕøF5]“wi¢Ş-³©Ïîô’Z¡	¿GÃZzıZ£iQÁŞJù¿U.(pø¾¼…{'Â$|GUáŸœ¾í?c×é“´â(™¼ş«€h#êÑW	°¦Ø¨ä¢‘y½"O‰;pÎs’Ë)g,&½å—:r‚~µg³ş’p…ûöşnXş„º<Gïë™ìûª½Hª¡ê¹ ò¤úÀWM‡ns‹KóŒå†Ò7b™šÃ-Ëù±›ò[ÉìğsiÜ©‡Ãv"æŸ\: 4R-Íqg?ê{6Ì%á4Èz!R°Æ½Eéı°¥v¯ØT~—
ÊGœÆâúg p%­DJ¢Érs[yÅ1Y­\`vˆÛÑ™–İ™ğ ¿˜Q<ÔL#ÒPähbÀüÆ%Ê÷rY¦û2$¢¦4¦«DÕ¡èùDù#(]íL5D&ÍIW~©ÃØP‹Z“™‚¡¬À~«<9NæÕÿıŠŞü__uS¦ï”äB¶cJi|BmÄÊqMl¥-ÿjVRaQ½Q„ıKN´Cì©ûWzg·Ã;‰zÈbçùü]*êÅ³İN™Ì -[”ç´4¥ƒ1Ä¬úhèZ‚*‘‰Ó•l7œX­ı®ÁÇıM—©ª¯[ôÙìaJ¦:´á…×öõ£ØÏªè#º&j¨:…Ûç6Ô†ó‡«3O¯UÖkÄ–í…¥ßËWß* ÚÆrêÿ„ëö¦Ê®1PıXÒ?}<	¯g[å]ªÛÜ4?00¥!ÂY!~Æv-5_¹fS ¬ê‡Nsv}Ì\Oßç+r¦ä[4•¿•Î½Ä}‰Ø›-Ù6‘!—Ÿ^JŞ£•M€yş<ğ!Áü8tü­,hè²œàµÙé‘å¹,S²ãï ÁmÈ4‰wùú7tR—%UaØ‘ë¹Š¹T~ö/‚y€-‰b+I–Âî¥!û6/	«“|‘ã
ğN(kh:²ºß<ÕeNN0"à†+O.'+»ñKãÕø¶ï÷ïQœé§{iMb¾Ş6np}£5™~»ázLêY7¤êV2•$a|Œì6
Ôù‰?öv“R]$‘Z|gn…§í¦×ÀiA}I· í.‹‚hí¶k€~ıoóÅoM¼¢Zšã8A]ÙÁ·n÷Ÿ26[R–Œã„gçg€•=¦°´[GÊâ„Ë ¼_ç '.Ö ::8Æ9CëšÁè{-^”€Ù.~Æ‡i†Nûæ2ĞúRíIÏB‘‰)¡‰Æz¡ó nÊg|¬Â«ğşd•zh7WZT‘˜÷8±İft7SNßç
Âlñœ_ñ;Š©l		g©¶×ñÀpeºƒp,“
›İREßëFj´‰=Ì3¬>e’6Ë:5J¯—«=—Îc…N¥ÆÏÄxWc
Û8‚G^ƒBò4xZ¦Sùµ¥sÃ9.nfêˆC¤=u ™%§MDzãJÂ«4¨¥gÒ´KÒIF†–7[“å2·€—1¡°|p€›ñŠ\ªïF­ááÜüù¨d±Õô•"š0A	m´IP08ñy1ÃƒBrašS•u+tımÔ‰,í8o&«ÅÌ3ÁD8e
I;è¿ó„ïõÊ!95l
Ï=5¤Qê…pÚ:rM ¯'÷‘3bI»ó‚¿­…¥w- úäyLr]åbe"ˆSFD÷l-!¤ˆºõô>™õ|s".¡hşM‚&=­>6"9R¯ßêÛZËÑÁg;^±L¹cÃ*÷P"®JÜgî}!àÄÜ“EsËÛÙ?;vG¤±öaÔa¨nšÔ¶ì˜Î-ƒ•ée é;`^—g²çİ4é´Ø…»Qc¤»îò÷
‰i«Ç¾DĞ{ô”Ç;ëhCMÕ ¸—Ü>-(¼ê‡Š)(“U×>[â³iìù€°6s_³`5¼[e£¯È$í.°\ĞH	'¹ïj0cAbœs¼<±ñjoÔ²Â+7OuÓ¸k.MŠáYuŞw8j/˜A=í—‚¹Â-ö©ãHüµÓí#µ,æ¸$.Æ".ã¦çÄ®¡¨¾óèF' ÌU¯7lª0|»ÆÇˆyQRÓ®h!;'¬ŞC°ÑOÂşŸÌÁ0±Ó÷âS2Óˆ…^±¹Däo¡G{^º	ª"=•wÅ<a	¼”¾)li2Yßİ¯‚–¢²ÂœŠ>×‰Í‰Q­*MÉäÄ€.|lç©‡Ìdm‰øEi'ª¿ÑLú&õ‹ìÀ>ä…vç¹¬‚´@P0¡êép9ò!(ŠÿšÅİ-\Êğ=‰®©7d9;7›aA¦ù‘bğ‡¥&=$Î”CiìfO®wÎqÑ: ªÚ^Uí‹İä¥rE ›Á?Øçä5ÙnÖó~]Cû¦•O5lÔ¡ÖöæEÙ\ÂmÃÆSG`wò‹‰u­ÃP ‚Tà3EÔ¯ÌÔ¥‡I*3°9}}°%„÷>*Û=š4¶Í°^%)¯î@Æ©1œÉ+@ºuÖûç$3Èİøìº?‰'ú$Q¯¥®T-KÂ%B+\9Ö‰àÔÏl‡‹´{‡ì8ÒGdÿˆ{ïá[ I6ÿªĞw‚ëá¨`Ñeá€³R:×Œ~©R%Îoú%-&N˜.ğºÕpÖ&ùõuQ©Ñ7è¿İ†ú…Şq*/ÒNhysóúPç3GGÄ"~`\¹ÏìW-°¶6å»Ñ±‚: ÿ‚‘ AÑt DM›¦B'ï+Y•–3Ê*3J(D¬r3rU€0]éWl4ùOŸZ§‹,Äí oánÍ’GRSóÆ€¼[˜8Ør$é9t£E!ÙİQ÷™“:¦”¢ëXûnª"AÀ¢y²9ÅIÃÊcTÑÍ YüÕAI+òdÎ ¶
ƒä(Y€Ğ”ê„/^®_ö3g	qE#²­JQÉ„-ZN9M4iÿ{­ì&â¿Eá•Qù¢yLq½k1¯Y|G|g—¶lòü¦Â¤)Õ¥e=Ôq(p_sŠĞÅËOÜ¦—§’5uÌPgÆØğ/¯"ßş`í ,ro™cÜ¤ÿ€¯lªªÈ‘õ½M4r5Û69¤ ¹ı;]¼»b-ØøIœSñD×Izp«Š{{Jwhi´0§Wşf3á5ŸÄwú«j„‡˜<‚çÖì¦ÙÈ5È8~<Ü«,÷YÌÍÕöS:Îù¨2
ğ­†®ïÛTAàyÎWÌÃLÖªd­o(°A±ÍN­Ùw8á7OkáVã¥~óÀÑ “A5/iİ/á'¯„¹ÃÏl´"íÜöSæLHúŸµ+ä>ˆWt*şÕÖÏÆ5 :Ãvóãå$ö<D½µ­FQãR¥…bM¾H©Q|25xpfUÃO™Iş5…ù§av®{×Û}66•Cm/5;BšFĞUß‹ê†+Nî“½ùÓyÕéq6|ø^{VVoû÷áÙ\ßÓSş+~3ENô „Í³J
/ûƒÓy½X3J~É½Ö‡(‘	/0=Â~ŞÛµ¨İ]¢Ğï²(‘`ğ*¨jky˜j¿¡…¡—òÑİùÍO„Gğ&<	ß®æ»‘.ßÀ°Sø[±QdåMÌî˜p75ã1T·¢ÑkÕãæÃ(Œ1.Ím0­¨>„—£s$‰&rãÑ_N©˜@ş\ÚÎûhôì×wgØÕëÎUiv"!¦ŒL<ÿ%ÅWW’
F‘ñz‹ÏX§áußÒşî7Ôæá“sDæ3IT}gÈuõÊùB‹å6éĞ#ö£µ4–èãáÖÍ¤tQ“nıİ]MU.ªvœÀÁÂc¤”e‹òó‡W7÷•Xù÷ÀJeFÚ†Rİ–«şÓr®Šš2ï2”ÊsÙaqP=K¸.í‹B6u;ıú ğo5V^Mà	qÿïúÀ½øÁ>¯¶Áío»é5»ò2étú¯=P~ü§-*¶DU‰%¢`@u¦}²IøÒ‹p\}±
èxéGÌœÄ#j>-G¦±ãŞŸ$W–ô)ŒD(R ;ßc„wƒö¤}?Õñç;Ê»Ö+Sô5U›•fCõ&e*.şÏKğÒ"$uì¾Æßû–4.2uÀ+9>JÙ…ö¶Zª9¯.o´å˜Í/<–NËV¯¥fÁDqŠ—>Ğ´ˆŞrÄ¹Ú¶å0]Ç.9äp¹Â¬•ªo%°ûM:yÎß?Ax±”d×CdL¶¹ë3^§/„¢Œ
ì†ºëïgÿõ/*ãv*=P,6Ènmsu¼«$Š3Ä}‚ŠÃeLT”·Í:ŠÅILÔaßrÔş­Úöğ2ıH	IŒxUêÍ×ƒ“ªhÇmı3Ø‚‘ëÿ½gÌ³ÈuéE5‹³}+‚P€‹s?¾¯zîbyXRõ±ìº*óõL›$¦ŸÑ,ßºä£æïC˜ÿÑ¸Ó‰Ò;×ÖQu 03y,ÌÖİ!óÃƒ¯-Õ¸-ÿÉ€Ik¶@ÑéŒL.©bïoO°,FÌMG>™C÷§‚,¯Ù   hä$üèWjM ³É€aA±Ägû    YZ