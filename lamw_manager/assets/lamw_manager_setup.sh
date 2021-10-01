#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3461131389"
MD5="1c16354ce8a75179501ca0ddc44e3f3c"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23584"
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
	echo Date of packaging: Thu Sep 30 22:34:27 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ[Ş] ¼}•À1Dd]‡Á›PætİDõ|Jw®ô­´‘ı¹7b„xB´ğÛ•`é<µğL]yqD>¿?Ï÷=Ù{ÆNƒbìı385-Òx2hŠŸ(fó,	ºëç›õ˜@/Ö‰]5<©wŞ‹<êßevM]¬5qwåcÆ!|Nq–*Oê×É
é*WH)÷¶câ¯n²Æ²Å¿¾§!k	§ŸjòıÚ -Y@áni¯¢© Ü”ş5$=QØS$(öà÷ è*¶hË'÷¢åq‰*8N0&fZÕRn¦§z¿¾éÍ~©›çÁÔ>û%KozøgyÄSx2sHr‹lM=“[û±cw]«O§‰o¾Šç ow'ØÕ¬ °Ãû„p:Ç¸ÙàCAÆûjNk9_¹»]>ûƒçXiËR Jå·w.îÛ¯CÓ™T&¢%k„EÍï]ı}Û®}íË½ı½.†¸j‰	úgŞar™J.Lä^ô(¢ùï˜›G)aSn¢cÙ »³‡HO;ÅT'È"U
ŞNªjdô» Acš!Ó»ûÂ©ôÍx¯	íç\ËÎ[~¨+âX{q¢­ßh Ö_5òÿËzŞ®÷HÓHÙØH`s¦IDmO5u`£ÑægÑ7h/ûYÆn8•È©ÉJ‚~>æ—Ğv»æÍu—X U¡Kº”{C)Á§EMXˆ[Š”å9øN®”\˜«ûŠ²d¸E€Ûpi4¸€›æ ÍEÎĞK¼xQãB”x­¹3m?Ã~¸Œ×*3û­ôY~¸¥&=ÌĞvæåWé+/í¤²€ íl2¬maŒn t´_XÂµ÷Ôÿ'åN~u‚¨ô KÎÙ-C<Q'›İÅàmFï¯ô¤Ô¶ü·+Rˆ…³r¸ş“öÆøû»Ã{F%Ö?ŸÕöö›,–?=Š )»P&G“o¿$ÃŒ•ÄáŸé ®.æ
§ã‘›G{hØö„Su;Ê¿éÿ<W}»€´(%FşÉÂ½?™\Ñ3:IËR—æ(¹ó\P›óFªW€¸R©ól7P¥‰8ğäÚó£tT q—/ ¸&x¤UFã	f	¢l†qÍl.d-„*®'sTÛbfRü’ó€KlÆ‹äk` Šmjoğq½Ä;íÇHú·i¢48ôc,± æ;¹ƒ"¦‰öÕCN/Å.ìb j¸Xÿ;…ì^ï_§nt`o {¦k¨»J9|{›gvìqŞ//ÛÇ…¥øx.‘C°q.âu—ërw²<ÅàÎ{Kkı'tş²0•1›¿jŸQ|ÈµıB!`«¸fõ0B|Óÿ!}ä@ß,õL‰åÕ¦Ò2¤¸Êt ®–Ë@Ùm
AtËòº&v?ïÕû¿‡8o¬›ëíw‹~:|·Õ+}Yà‘±%éß“ãZoˆhm,CšqôjI·äåÁ°uå»º5RÈ*1¢á#<ı!¾„Ç£äÛ;Í*ÄÂëfsª9Z@PE®;‡qC›&DÇ¼µÙß‹Ú‘\>mı0fC/Dt™>Î©Ğ1İ«ÀaÅ7¸æİg{§fæ©áV´]p²—‚5¸
6sP‘£AŞqrÂ•%'¿ )^.Hx¢ãáİšÅëÌÊÛYl~ìü’[a{ÇÖwYAòQ…·CzXÙ0I¨±´Òı¬<Ãil9é!D¡ClU¼%T²,z·ê9§Ør‹„ËjŒ®Bmï<2§y7P ÈÙMp“ğø´—®ÑÌÍ…KM1"õ“ÊŞÌX§¶¸hãœ¹ïÔŠK¦îkwø<Úôš½3Íb¯Öjˆ­—>Êåªšö•J5§C­Ğ›j@‡.C}sÜç_#gIâ9Pw4hÒuœ;îB+Ë Şê½Rı4 ,‡#“Bjy¨¨1«ÉHL…0Ü§éR­Ø+ Ìâ^Ï€x¡[BÉ½××ŒZÏ?ŸÚûK“…¨5š«q"~fŒbæó¢Ti&3ïì YMÀ‰¦§!2ÒB[W.›%¸Ğ¶0R5*>wnZbg¶pé– Ğ¡vi©Lí°SYDr?E4±½y#wî!¥íæ”³?#$ûº™Ïy§7CÂ+SŠÃ~>EÊÎ”ì!’ãÿù÷#£sXÓ(ÖÁ':¢±b‘ï™ÚnølšÃ„ïÈÙ÷O»oúÑ=c²lfÃ|Š0Ø{3#‘Sê ¥Gãğ\7¢ï0r/ç#úm“uXšv¬ÕúF^P¾Û÷˜úíõİ“™0&USZä›Cêö®Ôç;¹ÇÔúTlçaEáÈJ3ÁFh€øŸPÿˆˆ;Ù7H ßŒ×@vEO·ËG™H’ÿñî l—YÔKµdÅæÄãFfÇÌ<ÚyHeGiõ¿ñ¦ŞsõÑèÃô¸"o(8k¬ ŒRÕÁ""¿ø!$´÷·Q¦[¦x
Êà+Q`KõAö{ªzŒúüÄÛ½ÿ‘#ŠLê_´Mf/õş'~w™Á“õC­û!Ò¹ÈªC:œPû%ïdu?”h"ä~‹Ï;kÓûùq`íù÷Ğ²áÛÄbY…²Ú¨•6Íˆ-ş`)œ»vP5{9lF+İ¢Ô+"ÚIãnõ\‡Ò™'‰^>3*÷½ ±;gJÑ¨??ï˜xYœÃÄ ¸Rïó3xU@´à‚›ºcj²§×l½¨Op%ËE‰æÉ¬!ÎNSºãU•È´ìªsD¦YwcÖ3´%î÷üìÍwı²@éš0ÊrS˜†iĞC-Ö‰BÂsùƒ¨@“ÚIƒ`ŒN¾4Ã 5¥¡öï°¤½Y{9ÎÌà&‘ã&…­À\Cåd¥v²§–NWı‹ıq¸3úŸïAMH=€ŞÀªODÂâQ ƒÂÄa”‰¹ÆgıÕŞY ú¦Ê<7ÏŠ“BŸ>ùEİ M³ûè:\øÆt…Ê]UĞ{½e)ÿ’¾‘¨99ãS³”^ÚÓ"*(À~Ä9R‚5 «LŞkÌy!‘z$18u-–p•(š!}éÖô5(4}µºƒZ›©8ôéÃ¶ª¿‡;¼Ì fOÃóRÌ6&Ú]qçÀÖQ5Xùdä¤ñÅÿ&¡ô<wÚÄ\…QœØ˜É}£ö][v?r˜»æÅ‰PÈs>”wÈÊÔ%éûC"5$Õöbt£ñ¼¥Šù· ×E^ämÕä
¹m,Ÿ4u@
¥ÖBŒô³’Ÿí?w†[oÜœ¡ä»rr	¨WÎå)“Z¤qŒ_lwÜĞP××ÂíÓª«,$‚AØ×Ç`î…öÙŸ	ï†íGóÓ¿&;¢¿µ+ÿùš¥“òâ¬=dÎ[zkEëz¿¯&‡"šû+‹‚±w«¨"~™ùP›¥ŒåŞTÏö­¯r‹ÉÉM‚A4Şß‹9iö.¬øE¸Î°Î_W²ç¦ Z»<B‡ÊG9€j&jT´­ìZL½ÿ'g«Ôhõ'«ígñò_ÄA#RÆÏê‰w	[~,±ã¯
±icÛCŞ•îØ¥èL–•Y7f•ı÷Ù$«ÚĞ”¿"và¬†šŸ»B¸åŒ‡èòœ†°)<=;ò0Qq²è7@T²CPF\°(¦¡Wš?Ã!¶N¿2úË5Õ‡VîKéklßö×íg‰yåÜ¬øÇT‚¯o¶§~önÈ ï)ò5-»ÇK
ş _”A8í”ó›RÄA1°Ny´ç/ñ !uŸßíµ Ÿ][íüÉìõåıà!üp%÷—‘—œ¹VÿM1ÁZ(ÏÂçërP~i™WIÇ–kOC„
Š´’åj‹ØG(¡ÉtN²ò¼1§upx®¨C
[Mª§Ù¶#MİD.õºÄ4ÛkœgˆÑûç»$ôuE*?¹¸t@C%µjyªU„QfßI=Xl«¡•§0ıÎ'äë¥àŞİÀA`ëÅE•Mş^§ô¾OÎ4Sä³ÂônšĞb*³®³]zó…/Ô{;ë.›$îÛ”˜î5ñc$£ OD«´äGè‚&À’tâˆ‚ŸŒÃ£–P‚6¬Tüsü)ôì—K®@àÒsù{w¹Í9è¦kÿ©ZÓ„ÑD§×_ğËÙWLC˜yk¢QÑ#5¢)Û”zŸ#Ç„B“.ZC–¦ª«ñ­ñc–
¿òåŠ@Œ47¨ü¨L.2Âã0vä$¼•ígå„ÇñœˆÄ.e¡GºL2ÔGl„–Màº0Ó–ûj\ÕùáÑ]Ç¥É]E©Šô¯vº1Ô´}Ó´*êm3“S9ç‡Ødgz1ãGl1qPpÇr½•V­ÏŠAüqşjiG³´[ùt}F}˜Ço3ÏÓÂ ps‘'“Knø¨÷Bc{¿ÍOV
ö¨÷Fåç\2úÔ«v*üÌ‡ñ8¥NÆl½àQcäÀgÏƒvŸäK-­¾ğ%Í9ç¤•©5¿]27ËıXØ‚8ğaÜ´‚'îV-Ø‘zx_+y@²óüCIÑì:Öº‚(FÊüx<‹¿óÁƒ©á¶qÑšjØxb=5U-"ÿ0Ôú?k"877Ñy¨è
w\8˜»X	Ûf4:…:~Q©CğçÓ¥İ!+îa§q‹4½âÛy%*z@£;óz"?Ñ1ğ?·ÙŒˆÈMÄÄ½â£ÖR_·ï¬WL#²Øn8?­¨åÓ†Â¦ál[3{û52/×1íE¡	*;ç›¸x¿Òtpõ§ë/‡œëĞ=¥Ù=è$\•×'èrÃVr#´äZô³(—+k‡¡òz›¿d·»Ma¢õŸ‰
ûÿË|0¼›Õ§Ÿ¹eåÍ ‘>f'Ú/•#=ò~Î%¿9íÂ…åöM\‰âñÆ›¨@â´X2GU.Æÿg¡úÛjW!½3ê2³õÅá‹_(-m­âå	¸OôD–ÍV=Åa¼oÛK,@ÆôÃ(_]Ê/¶‚ÊMDs—Ş³ğ=8Å!Ñ.ÂNl@4Yn¸.N¥à[Åîıï3/ğêpÄF8i¾š;76IO¥Ÿ¾Û‡)¬Ç'¿ˆ›ü²oÇ°/Y–‘)œl#ö3X·O‡œÿyå…J çhQråÂNeŠ:¬Ò+Ê¢(¾ôÉê…bw%¤-éşÜÔÉÁo("ÿ¤R´pÊ¶ìzÌŠã#ºœ”}Íf²fı'
œÚõƒÏT|µXm¥‘÷ø±50òbtÇ,åì~Ùq˜…Y‘±Í¥øÃõ5 6Ê{¢İrªoC ²1B¡¾Ø
ÈË«&DX ¬’)7·;÷WşÏ=Şß{0·4ŞÀ^™«lt“ZŞd¬—AJèsÏIeÄèÑÀ÷Pâ¢Ş\)°¸İq¢œ/ÃhX QK‹!\C¥±cÓT§K?„Æ|•ıŒ÷%±ËFˆÁ#gCut?G{?yøgÇ`s Ñô“°Ú8äH»2e'†’‰ê¡ïœ+FÖøx‹ß¬Qm8\(9õí¢#İx8FT3½´‘\z³KëĞÇtYZ*ôT.Ëgàİâî'ß9aâÑ]œ¬,k;‹ı¦ØæƒN{Ë™\ˆş#?(GàºÃ+!™Ëß‘^$­Ìß…_ÚˆÙj©V¼÷j·,ZIêQˆò.0nßšıœï		|ßPãeoÂ©8¸XB¡‰'ŠcUE!Š·¤6¸gÇ$T’pşf.®á•”™})û÷N„ßcxóıA@|6³àĞOâæp‹¾!ÌB5q?¡å½²·åGá=DOQ^jR%BÌ×³»Âv1Dõó÷qU«Å…*N=ÄªÊuµ˜Ôàåê†OwCŠïƒbøXÖ€—$ä½ö_9¸§]c>ÎÜXV×q.·©]Ñ,}Ã‰E{ÉC’ğgQòjcM®ÒŒŠ5 â²ÓN.pê“4Z€´­'±¦ÁôÒ¤M/ıB2¹l)µ$}Š’	¼¦ĞÊI¼Î„Ÿ¡pà 2è÷;9ÎDUşX!#¡“0ëTãl×&‚§	+)P4°f÷ì@+Qìçd£ON¤iş”ªìÊÇÂš2…Ú»Qõ4ÄóRxdö~"ˆ"#L¦’œŠŠuï–ŒÆÏ1YÁÇ1P=l¿¹<í&ˆW%™’]V¹vK¼#œ½”ÀåC¨·>™z+Iˆèa#I‰ŒÊ×”™ô9ò OÜ$b$zzq³#(@-·jSî_+x¡‚¾ñœ„!
rzÔÇûõ'ã³I¨@
í¯)ë‘xFcxû„‡¥G ÇF·;ÜqS?+zbw¼Ïkc=>ÈVësºX9ñ "¾æuôKPÙÉ¹M¬AOOÈWò¨jõÔ0ÿe\ˆã|?Ç8Øªx,ñÇ¤©–]×¢“Òˆ+â¼-òÖÒ$#a‘Ñ„¦=¸jõ	µï«dƒôÚ}¬¶#ceGœ$›Ğë5Õ<cB cJç›a¯ıG\/»’/å'w
kÔ“Ô†aM×UÖ,	çşYZ0lu˜®¼;Ç;è5ò'ÍNOÆæBóÚŞ"ß²îz¥&Î8âóÆN<U™ÓÒùÀ­¢e^>Ñ\#tŒ+’¯ˆã`´W?¾™òMµQôAËa dşê	e!Ñ˜«}úoÇL-­W©Î@ãÀ†²`ÚºlWt&Gá†0-ZT$‰¦—!Ùö³şGªß7Z~½àÚuØ%ÙåÆù¸èjÙ¹nº˜zİ!Gd–A/“ úy“sÜd§õ[ÛäÜ¯\
ášàÿ+Zøà <À~A¥Í°H»DPF¼ò;ˆ2ğà¡Ëô†Òrìt¶Ñèfîí'Û©œ)!³†¡n^è"Ûiæçù‚É²`Ø¼¶šøÜöJ=?ïl(QÑºÖ½-ÍD·!×Åeƒ®lMóI½F‡òØÈå#F-^zêÀ[Ôìù¦ì_ŠõšÉ]pËèáÆâH¶ÄJŸša„1½Ü<[ Zy! »½Ìš9Ë{ŒÁr(„2é€ÚôÓşÀ‘šƒ{í€İÄÏ‚«=„
ÿ¦,M0ÉÌš×èbÏÀ§}×/ƒòrI[¶[CYã¡gDe˜É–êŞ±ài§şJéî_nA==XÓš©^oÛP]ƒ,ŠŞ	ùëË*=Ñƒâ±Ê²{êplõ›Šk0DZY]r¬=»Æ÷¾¨8¥äã¥“ÆöÚQàªÄyÔ»ù?ÃÛbÜø	
Xå!Ä²”×¾]h¨7#2Œ_Í)­­‡şÚé“?³€Âó©tû6ör„RÀ¨zè7¾47Q»d{ıçhuVXàcèí±GÄCênı¼)ïş`H<>0 ³/¹›ù±U»¨Ó\_šaÜ@±bÓ[~ÊµÛQôEP¸ô®B{ï‰Ÿ=î×
Íu¡»zÙö­ò»‡œ"Õ<µ›ü ®ÍqvF·°°^^)ò¶”şR¦ëı¼ÍUL398âº…n1Ösúªe¿½šß:V%œ£<p‡Üy˜ú´åÉĞÄhÎ+íQğ­¼GyD´ç/·¬q„Zú{R§C©»ş©_ÖrU‘$£TLqyU[ÌrRÍ‘ab·"ÏLP9Š	%²‚IHpøÇôFé«ä/ì³CÜÎF‘˜a_<"eNïş‚iÚ'Š 7VÓBÕV%ŸèXÂªá¹8ÖÓâÎ_$ÜÑ¶€eåg#ŸÆÙ\õ«ï1#aÑ*é4zãjå¾Fİ¹NÙİ~­/·DÆÅšŸwSä÷f4[ Œ¾±yÃ¡äßÊU™~ŞïwkzL
*
'¤©:–„wMÊ"`I’«Ü$,CxZ”›ĞCôô“N«çº°BÖ·b<WëÓô­MIIl	m@xÂ«ë¹4)«8~h¼˜ƒÕùÎŒX´ç÷02ßã‘"K ‹6ù:Eù¹:}—¼$Rîv†"jq²°X®gLAdZ™¾°Ânäm“Ÿ#4«îf:ñ¥ÅÄá†#,•CÙyd™?×é6Õ€ôÓ×‘4#İ>Ã‰Ğn¤zÜé¨RÂ6Ñbš«èoüDëĞ .kkÔ6¹än[ÅtÆDZû¡ÑÒËĞ²LOØ;¥_ü¥ä×zŞ_úX8…:ˆ©§ôÅ X³X™SHR: úHÜWp;w?óX	ÛpàC>xuqáFX“j°ĞÚó_² -×ä~úÔş‡~JùÑ ¡Z¾7lp_OãB£ì§5³IVRtì44m“mM#DAºø3áŞ9á‹èØYjúS§{/èßn# ¡ì/Ó*ò2‰ÖM&-[İşâRÑ~íqA·Ê~Ö±Gú³>>ïß³Y8šC36\’N+†@'œ‹“¾Å¨èÜm5Ğ9ùòo6Œ/µiÛıÒC+}ğßE4
'œ¢\'½ÆÖ€¸M‘FÍVRï§@§¥ˆàô=E#‹Ø^”˜Œ ß€=oÀ
µ8ß}vkª–XĞ¥7T—ƒ «ï‚µBÊƒÔ”ß)‚º[(—­Aá!À¶B¦«ë´=™gœ3'ì&¶põËÇ´"/÷7²Ğ[0Î¢Šxåj ó&ñ‚-vÆÂ2²İ©ÂUy!Wg¿¶®°Ü·İ}ÛÖ¶¦:èòŠm@ÿ“H Ç£Çqeì:PÁû0	ñ
ÌşRéÖ®¶SqroÈOW’ÖÆöÉY™ş–¿}ÒDh{ó$ÿ‘êãÀÊeÚúÒu«ÚsAÇ<“ı+BÅ¼ÓÌ	}l§f3o	Iúİÿÿ[ŸÂb•CÎó43ÎÙû‡¦dšÚ¦+A	Îñ=[„	
ğé§Ğ°Ïáè³9c_ê¨Cû´ùc™6s)xú=¢öØÉ{&à‘ëè,Û}>øKë·Y¥bö¶ûÇ|T=½é5–S{V°‘Ş€¬*à%Û…ñXLw‹5p3nc!sM÷:VUw.A^£k¹ÑçhrØÓÇDU÷‰	éÄS“|¶ë,böEËº„â(ÅQ°–6Ô``ˆ÷C.í‘ˆÈ©®:åÁ},kÈ®ƒğ97J¤ˆx^ÉçMÄµ¦J¡u»1(‰ø‚Á7ñZf¤Òé–t)½ˆ%|§Æ	mY°çz‰#Ní'TBZ!u‰t>qyz'L¤5ë=bá‚|a¥­’ì$9¤Í<¹Ã¨|#1…–2Sú/KóLn
×À;œ÷Ò¯d—Çø‡††«ªõÅj“,sbwŸ˜gçèÅ+£CªĞø:r{#ãÑsb×SÁç¿³boÊáH-İ²vq|J³†¸F±ÈeaåÂ%”ƒÜ,»¶’j.øk%
ìÔ¾fù…y¯pÌå¨ÔEÉt¥@)ïo™¸T‡‡õ>”İQw˜¼ÎÆO?Ûg¦dÄbÙÕ1â3}-*ã]ÚÈŞ#îGA¯EN ÔYÜ·á8–Kh†Aü°)=Eê•dèâı²ACBMò‰äÿXæ[@S˜|¦ĞŠ9Á ¹Fk{HlmíÓ(^‘ášåè=mí *|–p¶½­Ún3ø(mü‰µ}íÑ$é1¬$9î´˜$T±k«Bé¦÷Lcîş4½D¿äoZ‚=Kò‘¸Ëá“25ÜS±q8(Ä„!9Pñ\âŠeüÉÍşœª–óQ	#%=”TÎ}÷ê>ÉÜÀè‹Qû’‡¥*-x]2Íí×-³ú5ñÆõ¢13©\…\3Œ}ŒwÒÚşKÒÖ¦,h%;XÖ;û7ÆÄj¿ÿ{}£æºµ«2³ïd½qÁà'2È#ÖB0g)î7Ó„é?y1¬d©Ø†@†Ÿ¬lô§'b‡:û‡Ô‰Û±an(ŞŒ}HË«K*ä³ÇÕ^˜ëÄè>è€/¹°­9x;)8ºq¯$]»`RfH LÆñÖ^ğ3²l{èHíèàhdÓéÇ^`kõvÚÏğìüÀ§>|7e>m`î,Bq.¼IÊ41,6GoÑÛ¥= ß˜ä®rÔÆ
ÄœÛW4h04Ùr²D 5Ñßj ÙÍ¨^üƒ’wÕšzUÖ±éÕM#‚ĞLÃ±¹ÑvO¡üÉ ş Â_€Å¬êxibô\íuQ¯¼ÙP](©Fš›³ä’ò
i¢È#ÍÛ¡vã-E™¡i8%®‹­Â¿Ä«ÎŒ¦¸Â,håM×‰Ñ…e«j ŠçîİK…İQ¥Óƒ×Ÿ§¨ª;$g¯»È]Øşå6D¼ûr*¦ÜíÍ°“ibÇNC9³ŞÚçÁ¢áWb^2«¦fÇm¥~Öó‚h{|OÃ×9U€~Ô“ËRëYıA=O_Ç‘ë¼ÔÇdâ^|Í_õ»´óÒ«÷ò[€¦Ì3ÏÅê·¤Bœ«›ˆ‚8Úk-â¡Éao{ŠÂi¼§~&ÇºìAsõ	š}°rî5ÊÙöÒÇ;®öz‡![|BÀçæzø=Ã1ûâ—ã’8b€Âh÷ïk°5J–
¼ ò	2e‹§U*ÀÒ‡uå,<'cM,*tÙå:7uwBÍ
ò>:v[İX~QoŒaÂ]¹­¯û$+TXG%$´gOÙú+Qé­_:g ?º
‡<X†sv5êşÀGgŞ{QÄ¡ı‡U®•×…]çTÙ‘©ÕêoÿL#°ù	²’:	êÓäÌñÙh€ÄGÍÿF”ˆù8Ğ›‚ÏéI×<¡À+
Ø\ÓSññaá
YÖŸTŸ¹^ö²#ı’ˆ…eŸ~#+^g’¬}4K‚²ƒ…j!tëc÷MÆ/URÏ0ÕÌO/”¼ÅBoà„©tEáêî•üu>uÀ¨r“%¡V~!¼Z¯¤ü³ßşğéÍN4µ[3«¤¢–Z?ı—ã:Kr¤Ííˆ›ú‡‹B_3Tƒ©ÙO
Ğz‘ #^ÅÙJÕ¸õbÃ2Ã‘íJ€­«Ñÿõ-ø+bYdê;íHZİñ?YnPŸé)ìr,uºˆÀP¸ùv8åÌ÷%BRÌşá<„Áß7˜òT,,¥'Al	ÊÉ²:B.±àÍŸ†Õ­>û¥­$9Y@É\>*ğ‡~úµ­"]Ï¼mßŠéáFCß7Èn]™¢¢¡ú¾mºÔ¯ŸÉ±úÄ^W×5#}^v¶»ûD
y}ºŞ°|ho'.Ï§~©ÅDâ¥m®.Áù.n ¦ØŠ©ïñ\ADÄ"Ç>lzû§}ØW:úzÇ]W§­úıãÒ„õ!ÀÓÕí“… 8§¥VsåRa@O%­¬*ÑˆÕ/éc\Èa”ğ‰ìã<´ºnÀ=ì›rÚ»‘Z&[€õ‡^Ï?¿~†J#şáŸÔE¨¦Cí¤AŸ”şôk5JÑÆÛÏ@şø;Ù¯iåÎ#Q¾¾Çl?øx¾’®KÙdï¥Pè Ğ©ˆÊœä·¹ıp¤¹¯NÎ=Ô¢ËEıtÚ™°µ5å‹8÷
t
ë$ûm*6£HîÎzäøµ½œœSr×Ôk «Óâxp‚8—Öbé»âZ_]ÃqCsÆ´‹*G=[C`Ú7º´O«¼v¡s‚_IîrUü°í÷0z3ai5Æd ÄlA¢AqÌ²Ó‰\˜âÂL².ÛÖI/¬Š)ÄI}l®şÖuà¥õş›>Ç†›¼ü&øñzÎlÜZ†4’RÕ †å…h=ïM[Fnq±“[ŸGXSğå/ô$‘FÔ£RØ.•º'Mq"Óù,Œ²~çâBoÇÙäN‡O)ª=Q¢ËZ5¥éÄ^Ç•¢öÉ¦¯3gµ&HpÅK|åüb'8¨ÈLV¶-÷ÃË ·-1è©W#:}orL¡ºËo_7(nO²@F³Oå½«fHFù+Š¾‰ƒ£Œü€%øzƒ;G»øOV"'Ö‚µó‘ğ‚şé(í²3³ş°Z‚ÕzEá±'3"0y$vá®&¶óªRpŸ{cD°óàUº#ZodØ£³bò³5FÊÜĞãú%İEV…Ç…Á!ÒUPÄÁ±œÄ©f…7xJTOŠÓ}ÿµ[xû±ÎÀÜxõOÀ‹I'šïPØ@¦ Aï^(^ÅZsZõWEoFÜı¨ø¥ÃiÀ{Ëğóú å$$P]:,€úÚ@êÅ±«é÷·²"%Œf†,Cn5s=O¬ ±£¢´^+“¤Áíµf–¢M	ºB¥Z³‰ÑŞáuë¡¹:øÃ Ø¾ü£ùÄO7‘Hâ©Šõ{`Ş{Ú+Ğ­]şñĞÛ¹ Õ[„™›İŠwvEC¥-äóáp×ç-†e± ĞØ¿*Ùÿ 9Ê<­Ë,\<ÿ*¨Ğ°¯âŸİ	ÁÁ)·ß(<c	8Yd¸`7lIé•ÛBgŞãÚFÇi]xâ®³M‘ a"Õ¯}_³7îú^lçÏ½8ušñƒ·Üİí©-ş¯†òË `ß¿ËÚ€<´<éò ŞØİ4™\ÉL¤'´–“LÁÆ=hÒü"—°½>vã2zêôÂ3ä˜N2Å§(Gæ¬6 Q„–k°»¤uM;æ-ê`Y[#Á2	\œ³6£Ş*dÔƒáÎ,ÂP¯SïU!¶¬aFºÔØd	Àq²ü:G®ìôÖ™igCàÿéĞÌ«M»‰ò4ÇqÖ.7{v îU* †kl¡JíÈËî±ûA$¡|ÀDQ>efè ÓòÄÈ#iâ³‰‹?K³Š—éR¹LkÒl¶‘i6W¼êheq~ğ8D]p9%:Ò^²JÒ¶Mö1g¾¦ãÅ½‘ï„ÔÚ‰JÂLbÔ™OÔ,Ğhwfaïºíb7¹wV¤{Àó‘, ĞÕcó,h?•›`çÎ-ÏµÜ·’è\²ŸûX·±­K¡èWÅ!øwdEÑ½,è©²ãìfbßUÃ ~‚‚ëŠ’@¿Æ‚]ªÄğy¹Áå^ÁqMÌ>Ì\ÔuÍÀÙºÊëÀ‘o×quújK¼|‡Où˜ÎÄ–Õş½Ï?¤e“Î­yŸ9OØ³èÅ\œ‹(¢Añ+e`¨ZÿL=—€@·.ğLÂtb[PD÷º-§:’\­Ş‹î}”äŠnŠ_y{CFŞkL/ÑÁ‡xOêˆæyÌÇ”¦³‹D-ËúvOUná#!@}\ÿë¤½ÿ{Ç,ƒçÍ…’ªšÿ`ˆ­ß©‘¶±sOÛJ>³jJ­Ê˜Qï`ó¿¥À¸(ıd+ƒBÍ”·X®mÄ^ê>ˆ‰Üäş^+|ß¡02v÷Lí‚p•lÙ?ë¥,âaìB¥ÜâóºO˜Ë¸p—U%‘#$e*Ö¤<òÊÄ_ad‚¾K>}¼Ó‡`n¥o ÏEmÏHD~jd'K§Ï%—q¼¢·ñOEwòX2-bñcĞ¿ÊtÉM¥c	s¯ÊuVG~/İó¥¨® °‹òzhºÎ“h¬QÎöĞ4tí?	óòÆ0MW½QºñÉPÿÆúb‚hW"ŸhÛÓ)›–ö—ë—­íÇ=©ü1¶ìZ9d—‡¾K¦ŞîjíÄôÿ$A½?LOÌSZ6×åÿô°ªû	ÆP_v	yX¯…¹9ìV"&š;œŠ#‘ÉE^MŞlySaª<UX= zñ¸f¿•°1ÚØzÄhÈ…[aO¾Ë±ÜŞÚ#¢Z²0R8RÀÃÃ4œwú¯ J$7Jì:&t·ƒS¿JÈØÓ‰İ¤RÈÁ`ğ¬“’Ü–õ~˜ãÿÛ0É!ÊáÀí$´ÅÕ—1¡}ÔY`’ÿæ3HBÄ‡
Ê,9$óq¸ş9ßÆ ÏÈêõD4ÊÕ"Ûù˜Ş ¢p`‹k'
µhôŒ´kÉ'Ö…5¼ÏıßÜÉÁ½öºá'§}YZ2äD¾nmŸ˜<Šns,OÃ<fC˜lTvc£Ñƒ«u£X7ûÏ.ıW˜Åx¦_V[læP~Ç&ô˜ÆtW¼¨³:u‰¦€œó=äÆê†ø7›R˜_å$~éí‚@Kú“Ô®¥oÂ¨¶ìÍR4¸øDá³à-z)óƒ_ôì¦R¨,…B¡“~
ÃE	ïZK¾öY¤bP—§>W¬ˆƒâîúP‘E?G2úÂ<(ÄÓ§ŸD2N¸V?ß ÕÎ|~JLùzüÚ)0õçñT×G¥‹søY’8ƒvs›ŠY'óiÙÛŞÖ¯äIĞ?t)K9ïËO/v M©~«ÍLÙÂò§Æ#ÿãR»êÊ8‘¬.›‘+á[t£Ø”¹â¿ªı¶;j›Ós	%U=Üõî’{FgDï~´lĞE§½+¤Ø1Ëâ O”øìÊ	zî7ƒGãƒŒÓÌ`7‘¥‘ÚBÒïÈ òƒĞµ;)V8Ácı¬ØP«¿ÍBé_}] şÊìİÚÓR³(*É+ãVü/¥_)M LË%ê+¦D(ÅYEŠwICœQ5ÚôAiï`Ãª]dT‰5È»¾ÓºF,ü­]§Ğ(ätâ¼,´jıqï¼(Á‹42[ğ×²-a|{EÿáL9'&C¥‘?¬tE8Áç¡¹Z˜şÀ%S=)ïKçr!Û†x…Ñ4rQE¶&d¬´ãD¡úŠYVhïÌm2ÊO:rß×¦€—A€~ß7Ÿ’0ë…2`£¬4âÊ"ŠÚ“ÿ¥ŠŸr)
ÍÌÍYÏ1jy¥,exr–6†ì¯lùºCRàg»_:kmİû. ömC¥|¼²_çP!¿GÌŸ Œà•ôÀnøªò(Ä¥?É‹ÆÔt×R¸œñ¾3`œä*JeƒÛ3f#õZ¹R8×õ¨›Ï‘ìJ÷-¨ŠOUzâ)à²<+½ãl$}—³nl”ù|©Î&²RênöOB†¾‰ê5m·ÿ82œ(µºã&H±Å¤òòb4KÉıÌÿ—>cå“¬xåß†ŠoC™hîh"E›
Üş» ´÷?h•¨³ÓnRìæ0û(Ñœ¢û)½³Áçi;Öé®*œe€Ì;ÓëSÁÁ|İ÷SÅÉe¥=ŞnÜèDÍİğÄ¬y¯Å0{Ã|¾É*’Tíığ+˜"LrÚ0ùw­„3äuõ’"±m—kY’2	¤N¥Ç—mAUj‘’ÿ*lË¶MÃµ{(hûåÇf¶Ä™GğÚeÇ­»áMÙÉçaèå•;¶¨—"5ÈNÅĞ|ÊVê(ÀZ?|D“Åı,3mõé^%³Ó”V’šÚ³ík–JóÙ,DI\×©{¥¡#–‹êr‘Œq÷ÙÇDj˜Œ«æX4¼úÃùG@€Ši ª&ÑB‚Q«:]"Q‰›H D?Evu†®aß½Ô¦@ş¡ûz|
zJ-°ÿG…]G:—L)l©pbŸş RÓ9QÛ[Xà¼¨®‘yÛ
ô½Ó€{)@œg¯ê:îÁâ‰8bSl[voß³ğEïA1ÎeA¼¢û¡ßtu]v‰öµÜ‰Á‡r·bü‘O¹Á1*•
5×Ü“M¤à-‚½ÁÿOÜn'ÓM¯Ğ´I˜ØÛJá(2Aˆ¡f¶³ĞÜb$kBï¦ø<™ñ½Ãp"»›V¿¾äß†Ô’¤EƒjÜa‹DHyİËX3÷#˜ë³e×ñºyŒrÅä|ñ¢ ’1q\zÍğ¿Ùzèr–K!$„H¹df§KG"OÔ°ƒ˜v¨ú¨ Î^Ÿj±_ öÉaK\mrWİ4&šS+ê<[£+í7ñcoªhíÚŸp	1”‰¢Kj«A;d5Zu’Í\dM²k|©Ã¹)gÊÆ³Œ¯ó.ä¼fIŠMüI%£D×é+|“’ï @õ‚du9-ÙöéLc:%§.+†’-LDgğ¯&ĞP O¾·ôÕåhs*…>µqÿi[n…kÂEÌZFİ=#7Lq9°j¡ß¢FÕ/éÒÒÁ„ñS‹=T´Œ´Lnd§ŒÂÛMîÊ.±Exólåƒ‚½ÅpİE‰fx‚&æaèµ€²È\¨\‰€¢àŸDIi7W,‹éA±S	1`mª6‡7`í§µØó–cCd¸!ó±œ~vhOøCcézÓ£2W­©º+W$ú|j±`2µÚ'éÑ%? 'F‹øç<ÊüuÔƒhUÀ?éØnïúcVnºà)¼•:¶q iœ¢A¤„©æ>WÀd¢†	®¦ÆFÜiá€—şƒÓß3”ÌÖ“?tØÉâÃ1²’Ö@QğJ¡#}””lšÖ™bëüf:MWŠEQüBñæëG¼»ãbëa¢3Š¨|°ú»G,*ZÀ+~»j¨0÷“EÄUgz?äY|ÚƒeÊÛ$²Õ™¢\Çº„rÕ9,B•ùCX.1í‰›{¥$_$QvŸ3Ê©Ñ¹G¸©o¡2˜<±}G‰T£Æï:†WËÒu«r¤ù
2A@ıOHÃ’}r)*é— ±©,â”zğôóßíÍŞJ“¥›*ƒ8Ã*dtçÖ´¤Î¼
t©„>‡•¡[}Oaó-ìÔ;¨ÉäMÀ{f®ˆ.pĞÇg3Âş/â8¨`ÊÁ{ÖHü©h+õ‰Ô)(®‚Q^ö0N‹ÏÎ´@µ–qŠ]Ò¸#r„óº°î_©z
w‘àŒ<Ï<4[à2®{vb]­&$µôCAHëf6^ª:‚™{_ôn¯tHè6B}Fàù¦3ÑÚåWÛ°±äìËG¯ÄŒ>úUv«fcù%N°“÷æÌæš_„a+İH<h­¶Ó Æ-w*ª¤úİ120s Ag@h÷_Àh†å=#æu{õM‘ZmÏÏfá{º-ÚüÆ¶ï|5^ÕıOÛtğ]o_ ¿8#T2Uf¸*
Œ3[š †i <ÀŠ¾â•€M¥(®Hç­s‘qÃÙ¡Ñèr£ÀŒH_™O¾%6ë)¥‰oÃ­úéÛ ¾îY«$W;(w¡7QAÿƒ²şÕ˜;cÀØ8rŒåğ\(ÿÚZ¥O€’€±’¤5†ğYğ¶.Ñ¬‘™kß`¨¢ •LH¡È×:t‘vÂıœ ézãûów_(É×Ïw±Äá!Wå“µ\2#)•Ÿyíà+*{}Qh -¥u¶@	Æ #QX:~<{èu÷ëÔ;.¼è:~Ä³%#€âæîMŸ½O^k4DšCíßŞ¹é”3ÆbÙtğøÿ„1gú³ºôÙ©
ŞëBEÄŸmòÔaİnºHÒÌC]¡3–ÚñAñ:&Œ0í©ÿğ*J‡R‹FsoºTX.ñq~)·nø[7dÃóşBşÎåGŸ~Ö0ÀüßîM¬5¤ÅDÒ$"<ü%Ô@Rèˆ£>GC¨ñPruhÓ~åšr^d-Ã)ŸHÈÖ¯œ/1:‘.€ÂÿõXÓ,”x(j~WÔ^¼+0qxåÖ<±óÔ¥DªÊÙöQ×xgÎé<†árbÆ?èd¼B_†ŠÊ§-f¼“÷™>€O8YÀæµHŞ?L¼´])çˆüˆÕµ§SÛö5¶x®9´k9b½À×#S“o#S/Ú…ˆ“‰×qJ„ÈÅ¬Õ&ûéót[Íb "û¨Ms•™‹ï‚ô@O¸†•b»+nÕÉºúí×aæÜ,,07şüøJr©Ğ¢x¡;tÌÛĞL>ƒÅ=0¢’Mu9åÿ;÷_ËÑP@D±
W'ëä[)êS5erûšŒœÇù(>·¦\bqJ0ZÑ&o#-)»êCDá‡dò§î%ä©T+]¡·	á’p°=T3åŞŒ±.îeL®iÍ.)¢›µê÷«ÉBD©Òíšİ¯>IïDÙ¤éğe½^RXĞ"Ô=³J
+±¥P	ÆÔ­ò«4ÊÊãÙ†»­ÇËwÂ>B£•ªšcÚwØï]äTx5õ²Ì“Œn	šy¦s£À¹Ew‹†’PĞ±-`Bˆ©>†%Ğ'Ä9Ò/Q–ÍEOy8®á /ùú¦w>ùœrA®ÚGYyß¨d
IH:d–F^++!¤­ĞãÛQr[™ÿáÖS-ÒtÀÚäÀ‚ªJ-nğ£åÊY=2©¸v•œ ¯®3ó Æôõù Kƒ6ÊFU\Äğ»Y) Ö
Ø="ÅÑäŒEF­™Vcÿßxælêÿ[
¤¸va8W­G‘&
Tüô_ÓPİ}ÉÄÎãSkP9Ñ%=ÔÆü4Ëez[PƒÓ•C~‚z"}âr…Êó?‚ğìÜ`û’ 2ub9&½œìz/±eûÅºšæt» ¢q'N1E¥şw1mª­QÃTbãmù¦ÊÈ>W İ<’5ëç¼™aB `[ô(“½’ø  İ‡26>û{šgoQõU[Z¢K3+€ô&0!Â*ÒMBĞ¨ÒCl8ÀtPJ	‹M(5ï¶›ß|1%•İ~ĞãÃ;ªÇ×]aÙTz¹ñQ1yM‘jÀ’’šµôú‰õöZ#kÅ»¢ Õ/q‘w*HFiø|Aº¤'ºOKã¸é[9ìÆ6ŸAÇûXk5—ßAª¡šé¸Hºkf39‹‚¨¾çüÛèØ‚j7·ÁğzØ†{ˆ³wF¥¸eí½Ôè<ÃIŞ¤5
vvĞK.G×˜ïİ.Ã¥
â˜›İñ\8]DpàŸ·áğî¶a"#é"X|ò(*ÚŸ¦‹
µ¹H´Ç¦R:Ñ¦êÀŞæó¨Ÿn.)¹?ÿÎ  ¹!UüâjÚnvKÆ[»£`¸Ãä›şšÿœ‘$ç÷WÒñeşIWÜ±‚n=İEhÖ¶™Aa-×ÈÄ¯ìç-q9¡éæèè8¸^Z-àÂaD¦çÕç?ĞÆ‚?†vRK¶2# ÷şî‹’’4Kò ûğ$ïPÓ`›méß}‹ëœúŞfWÍQç%înu }“M´ñı½Sik¿£p™¾¶2_Ó¶‘r¨—IÎE/±Òx{†ğ6İháq
&ÃwÔ°U>å“—t?jõïlj©®p¦¡Á€by6/o/L~BLª´¢Èuì’gxøwl®à‹ê•ºhL7‰]ïÌøtŠë„2/Uml’4Sùÿ5öXlùƒ>Ğ¦òÑgŠCâ ˜òTÿÁå>6s¡,Â|‘ú¯Qšó“Hÿ²ôNmëSÔõ¥hæëı:ÁJFR¬fœí‹ÌŠz'y»/Ù¨›É[¯o³^i—`ZM8Ãa²¶KN%#İ ]=l€(pÅÿ·§`Ÿï–§‰A-İ=')õœ•hõ,‘4ïŒfYª!OPbË†¿Úöş6fN#…†•Õ¼AX³ësÙı×¡è¨°¹$qê°Ğ*˜ÏÍ)¨Ùp#óİ`Ÿ~ÌÇü-š9¡D²ÙÊ˜µ‰Éå_ü¬²r1	ĞâšÊ>Ò™×^rtáÙâoòğİ‘sœSYÕ\ûIœƒÀ#³±È	mÊ,-+í4p7q;¾”GÒI
+$ ãÃÈ¢-Ş÷ÁDcÅÿÁ”XÒ4Z\ã™f¹âÜ—\‘ ·jo¸şYöŠÀ±Á‹Ò5è%!¸§ÃúZO5u@á{3;À¼e{Ú2JB¬í»õÏµ;ê
cu {R¤&âV™ O—{œ?2(aÿd+ñŠ¸gİØoF1õS÷Óè?PÑIÔ|(ÿ×h™û¨»«ƒˆÿ!–”;Èm¾Àê³úõâÉõ  1ÖbÕØx–VwmCÆ—
ƒÀ¦œµu}pšˆ§ŞµP¥,MÅœ¨Taÿşê†GMÿ7â­ïyñçÑ[­¦n3i5/¨²èŠ8œEÕ@ªÂÓo
›&s9ˆÏh˜˜õè<"ÚwúĞ›ûf²Ñ ª:½„HŸ¬³ùz>q6i=Ójbë“ÅKâ\ÆíÅ¦Ru6j`“(¢³øŒÜCC4d+â:N‘¢ç+DP¦õ3ìĞÍpiûµÏ¶?ÉC ïoƒÊ460¾ €ßR^U€.Â°!î½©\m£Ü:Kè‚š\¨Ò‡œ®|€œ	®ÃşĞı4¤;qìÄÊ¦9(ö]†ûØpPı!lÀ‚Ù¾¢ŸıÍWHAçó#£8­¯íœngğ$­1YÁèº{ç}~ÜÙœ;tÆ“ÖÉ\“~Ò
{b€RbPÄJ/wŠø¦ÓÍ¼m›s1İL$ü=2P«qgi\ê&h§:óH‚ÒC8VâÚÙ9‡äx…ö/Á¿t’)Ÿ2x"}†ëg 	Äõ·…ŠÚÄãé®JªÄÈObÖŞ_ãnø-:’‹¡\ã½Ë ˆ: 
¼»XÅ­Ê,æã,©iú«Y]-çC”<]ŒCHC¸TÈ×.­-z™ş}Ş·²©øtÍîÀ8òå,{÷N-Ï|n(sYc³0™™ìÀMùÕG(ÁáÙú¸Œ{eÛ°75Mì[}“âªäeğÿ„,û‘Š>±åHáõ-ï*š€SLo"|\ƒ¢U(®å«3]C÷à³™Wc÷á”sˆ~››JO×Gg›|Üáé„ÂĞJ²;¿› ŒÕQÑ=ıÜd²%·ùkôbìdùp-k
®‚âŒ¿õ—ö¶dîüS!üDå/„Öö¡¸"s(¼„\#5‘ËªŒ½C1A<Â!
ğÁÜ˜Íà77Ê¦ hˆÔè{±É÷Ã©vø~İÃBüj,ŸÓ kSÚ°­³³ WØç¹Å"FäA$j[\ô’…œv'VÃ­jÍŒ.S9“g™6ƒZ€ÍO ¾?Ãµñ§AĞƒ©u\ai,>aó2F'ô‡k2G"je;Dû/ıñ{‚ÍqZ¡Õş<ÒŸÕ;Şày«nÎY1°qqÚ¬òÛáÖÛ¹‘õc¸/¢•‡Äj—0‹ToÆ‚÷}®fôïe_ZÚ+Qæôºú¼•ÿîÙXô×èéı¨à2’rBÖ¦òxBÆD`¢F=%ó!mîúö'Lª^gGÆ† î]7Ép÷W=¦‘#UU÷i/M÷Y˜º¤ÿø†Ï'á™TĞƒÈÌÇVíÆã× Tæ9¸ÓX`cß¦š÷Ä7É¿zIÛÃ›»œÏ›¾/6mù>=æ_R:¿RHG–\ë"x„
(q?çép‚Háeş‘ò¦ò8œT¥äñ7Š8éÑªD ·óâF¢$¦øaà‰e•Š¸[Ù:ç¾VW\_–ÏiñuäAÙ”;…SâõJ†ÁÁBŠ«¡¾ À ™,CÁ&[ÁÅì.ßk-3eúí«í>Gêø¥Y¤Š÷ÛTñòÜgE¡Ô5Şø˜ûş*¥¶i¸MÛş„Å¨ÅıLûŞ'´_|ZXQ°¤W_jQ]úÔhRiNa½€?ÅOÓÜë'aÃB±	kQ}ÀòBæK‰ÓHoµV*‘APFõˆ^^´&ÊCï2 ½÷:†7c kD²pœ“q nq&*R3ñ§CU'ù/pŒ®)+&gªÂ*‰èİN²º7ĞI¥ïö‘Ú{… ¢xç/êÏ­C„d¬fÖ^(GÇä]sPº#­ËcS¶>éFÙâ‹ôTˆâ	”òâ£Ù‹¸+æ6=mP||4€rr—ñF_AáÂn¥ ^Hä×Wïà[7jbĞÉ\òóı·XŸâå¤ª©©'·İôì•])íÇ3Œ=ìDŠÚ~__\ÍÆ5c Š@p)Ş­"Ñë‰%È¹¢¸ /xd9`¥ÓÃ¯.YµÑ>3hdEíÒ-”×-u£“j¦7#^Éöğ+Î«èªíîõ¥pxÏäé)­õÛ'lØ@àÉ©ë½{7ˆ9}MUr)Š›>‹©2óLÂg d™W.»¥iK|G¦]ÊÇ}HpTìBÂåml­€Ş³vÚË©¨ğÜm&ÕÍOtÿD'şRAĞeK€ZÄÖ£Ğ	fŞ%~çókév„?ÚÍ…‡÷\%Í$uH-å¨ÆP›¿HWÉj@Â×Uóª‚é³<Œs˜ªı7“¯8¬À˜o§±7ÒÛ[«“ÈXVÖv*©^<î}U~sıêH"ø^›n]‡5èëÒç_¡Øæbƒ_wcÄÎ›*²3£yOø	 :>vÄKÔÓPna†¹¸‚¬;60äÕj¤†<Q§SŒ@J=ß½ÁK¯ï¨Ò§^Ñá#&‡3À7ßæºKíHX_cŸe[.ûEìXz[í‡Ivp¶Ci`5W3$å[Àû€ÖjÈ nò<í¿[ş ú?÷• ¹J	 …æó[cÂÔbÅM›Æ×Eéb&fÅÉO#ÒS›ézÖËá¯é#­½DC2|¿Wxûg¦÷ˆä)Fd£è[$*Œ8{ô†bu¸X£¯|¤‘Lµş€ì?‰şŒCî´ä‰iŞî–}z»tè©ÂÆ¸ÉÃ6´nü^•>bò xy&]¨â‹%•šë{w°·T@©:n‹ì;!#Ù³éè¿R4Å6FşË«;d¤*ªı€ú@ÎäĞL9Ù{Çç]\ñİ9BŠ¶µ)êÀKŒ¿§ïëà‘M6†›3´4ò·»\’ØìÍÔp’ÕUQà €ºA¤ÜWíÂhùVşFng4¦¬%,ÉÊË«ªÃöbí ‹bÁJéÛŸ ú·á"bPŠ‘x²ñeZùäãù_ÂæØYĞAÍÃÓ¾PÎÊkŞ²Ğÿ¡ÏDlDÈĞPOÀ®†wZHÅ¦¹Æ„Ô3jSY×ß®E&[–òÜŸõÇÚár…igË¸„a®“áôbë¡g#Gğ'9”–æø¦d‰¼ÑHìqĞEËuŸ´U'­:îP`â×© Ë9˜Áv!Êì óãÍ2.›e)ŸEÔ«c3Ña·çI•B<¶Ë©i9åXğì¼OôD0´hÖ\g\`!²ËßÄ ¦£v²CÄUTOWÁsçFuC/Ï<Z®3}Êå¼'‹çJŠ½$GŒTˆ†ÖÀ”ë‰,S7-ÔOcëÎy” \PŞã1qÿZ­P‘4¢]¦–;`ü+”U¶$Ë1rQïQÉgY
;Î°ê‰:K0êN3|3ÛfÂ Î)ĞÌZ nñC¿‘›Ëœ&šÿvUšWíâ(ÿÚæY79Ê5!Ì»Ê)@Möüç¥"Ò%ä#7H3]¨hä>Ûj¬ÖÈÏª›€™¯P+f•\<Ã‡Kovğ@~H©šfOm=±Êj
(v<sÂHÔ.İ
ê)(ãŸ¸n\?Ğ&ÔYŠ¶H2·>D¢ğìé‹!™_±àd«À8úæ~æ$²3<½|˜P©ÄÄ‘…€{oÈ+bƒÇ[´ÕEŞ‘Ü§T•BÉxt{JüH™ì	g8EÑMú¤#”¿bM3øÏá‰~’R»Úÿh"ÿ
ÀjËÜ Z®‹C–ÈwJ~şc¶ÒLåÊñø‡ŠQ¿c5¥ùî\L³S³ªNdJ]…ÇÃ¿b]ƒ}Y¡Yšî¼«éWå7±=¯¯šµÄÏIÙĞGòÎ3ˆÜ_¨ ­¬,LTêù¬^n›W6'_ˆ<€ö;Uœ¼@o/”›îÅ=±‡ûT/¦-eàı±¸C£¶z[`¢nŸyß.Wõıh’µ‰HË)í/®Ÿ™úE>%J¼+gÈ£ˆ¢ˆÉ§ëÇÎa­ç@^yEê4è±ªº4è õB¿‘Î>uêß¢8°ÕY°s%‰Ãî§pÌõ(iâœW-8dµÙ¨å”×±w)à ½9Yõ«‚gÒtEú.†“%ÎÀu×U¥“_;æ6fxÏq©bÆtÉk»ç]Ásñs6j–]Û
¨ —¶„Æ%2•·+	N_ú×©#ó)®Ğ¬öÈ~ğyêZï³ù‡›•œ	M€ÛD¶ÒÜ¢¶	Ğ´Qbr½…Œ„ĞÆ?äûûÅ±—Lâ$“yìÀx÷~QãiYç1·’‚°*ïfMÂ§¦ád\'Å«'ÖyrïË©‰<2³ Ñgû•¶’ÔòæÊÍ»Ã˜Ã¨pk\¡ªqUs³ºW–-_°¤¶³»7,|spÎŸyğ
<N;¹„h](=S“hñ1J¸µ+Rwã…DÚEAKÅ¡´ø#¯äåh(’şÎUôS­Ù< y³‘^ì3yâà/Bİ7ãÌ²h-£¯5mî›™RQ%Å}>nd®§!‡œ:Bqß$ÆBk`^93Æm¼túÑàî›åÎ&,êŠøJüĞU´÷H|®ã,²±P!v-U¥tÇÍ´ìğ6EûNç¦XzÄ)3bKFÃ{ŞßÖ`iÚR'y¯®]*Óƒ¹ßæø‘ˆ &0íUá%w‚:Çcé<i
àmØ¡8®dv ËˆYïÓ›„Ïõ‘Aƒ[1†v[Ú¼ä&ÆÃq†C0l"v÷CWˆ£ù K÷‘H<Ã²Y&¥Ñ†½]“–<öä‹òÂÎ¼5¬gûÛ/::CçŸ–ô™ü[Æõ¦á%P¢† ğ6.’èy“å5Œ!vSÃş»¹ªØ·§—æH€ÊÕ¼»!çÿ”¡¶ŠÕ€šs6|é$U /Ú¼õ™¥Cºxºi<~)o:ÔXµ‘l ¼=²j|=ã†ƒÃÇrİèã®Kesã‹UKÓL[v»šÆ×ˆE¢ğÑñìx~9 ‡‘yÃõÜ5ÍÇäÍÏñU~K-64Ìêg0öxh>²ßŠç»ÆjS‚£qşzÅik²)'Ä¢Øê¹úk¢˜±WÆõìå?|„ÈÌ^?#]2€[”¬Aîw#¬²Šû5ˆÄä‹u<sÑ›µÒŸâ?ºÛXŒTXÃÖTÆÎ>½„ ‚eÊˆ|³0¢âsÍ«¿»Ö¦tŒ PéC{ {HÎzWÍA+Œç:ÑAÀšÇwÁÔ{ (iaÓtú¿ü†Y¸ v!ôáÒz´83„"OBXyB UÖşù×ÌÈi	T8F¹ük†X•İÈh•ML‹qßÅ!+¥¹±E0otŒ¤3®ó¨óØ:&0DÚ]ÛâÇÃB¹Y\7Ûk–~™ÔæUrAb£Æ)x™¸tã(¿K~ĞÆ± >h¤µq_'¦óªkæîh3:4‹õZR‹'o3ËC|ÄÓÚÖz Îúo¼ö[§¦‹eäÉ„7>ÊAº!(ÛQé?8È‚n›©«aíBòá×ÛÃbRzØ/‘{Ó´'½~ûU®Ï€ÎÎ<Öë3õİ–—3?};Ï“>ï%t
KèN
«Ëmµ½Ò€1÷Å}´´ûf³v¡ŞşjŞr2îşêa„šı£˜CéJî—ñ‰Íü"¦ŸŒÏb.ÀC_CDû^îtwÃs°É6¾y{î67Ã˜èû•D££šÁ¶ğÄ¬Œà@ñvG;™‡3i‘á¬‚½“ü¦côà<P/¯è×Ktİn²‚‚óôÎRl7µ¼|L`×Ñ´ªTZ&|;Uq‰£¡ôl¶ÀnıŒË|ÔßN·šŞ÷¹Òn,Ë¨-ˆj¬Õ2¬{uJI*±´±t<˜ ¹¾‹cmhö»ƒª-û±3ŸhŠH¯}‘—ºZšŒécgÙ*Ê÷„×âàÂ=ÃCÀ˜+7èË³ëHA½bbıÑâßı_½5kªnäEj²¸'B«„¥X)~TRAÖÌM0ıèÑ÷=¾¨ai4³”fFãyÓù…¶HøoãCeÎ'S“¨hÈ«hî9Ú{)v2Ïo:8âÌJ›-ÓmüEP7­XBœaĞ*u 99¸¢?yğìvV<V p÷›æ¯Ç¯:'ªŞéáB ~ŸI ôM¡ØÒrİ“¶1¿Ò	¼Íá²ìrˆ(Áù3)oI¤dG9ÍŠˆ­7¶èZpÿ²0N 9(ÿx üÀeW¢‹Bk©};*H²™ØŒ€æ²²í|á&mçµ»²^\ú%çåh}=cFŒŠÁ8¶mDÃt§áà{¬­µä+Ke3IÉ«`ÅyÛ×Fsƒ¬#EÄèÄGûš-lœ²ñÚùá¹ˆ›š+ ×>u@hêR_Ú0œIµ¯y]:×
î’%¤ÓŒ°½°Õ¿Ãn3K•ßDğe„·¢Sg<2‰±=Ô¨Q³B%Ğ·®%ñ¬ ïLgpıpä¯ââû-‡xûÔìò¥Ğ£³÷kTËš&\yê¯…µI»TÏT$]] y‹b™©‹u;•ºyşay+8. 5‹ñ¹[Ìº¶›¨<!—_ 'ø»òxÏæ0÷ìÚøŒı¿Ú~GEîš÷½Ï›ˆ)Rd!?İNcQ%óÚÆùûŞ¾Ò_´–èHJko!Ú]Ø<$8ÄG=¤fâÆTª”E¿6z‰ÒE¢úBg–‚Ô–š[DãÍsÔ‹9Ğ–•K3Ü„2ğÜkÛÜ[¿‘BFø%%N=ÃhDh`Â
MüjxÆR£%#“Ñ$12„E”É²’ñ¬À&®g6ã´ìÕN’ñú˜›ow¾b])m¬Œaòe)fêGè´HƒºŒ×Á×»Áõß.4A„ŒÏ3l~PŞÚ’X¨ÅÿÃÆ,1ÊÇ÷kuâµYxá‹eATÅı‰-`xû"nldÁa¯.@¡«l¸Q“®Æğ~€/ä¨v€­®Éiô_2èÆš—üD’E³„éôŒ}ñü½<³j§ğÆæÖ½ôÄ„º7–5É])ŠXĞ[0À4á`w^]±+Œ“8×_EyG1¼â"lİVùÓ[ ¬´ï¹¢N²]à%§ÇôìˆS$‘M$YRÄG=ƒ?Öäû°ÒŸ•RyC]½^CYïGëÑğ„ÍÏŠİh£  tä±/à¾÷ñÅÿ¿›i,:l0ŠY˜ı&¾b=ôu«ıâç£3İ®ÑOĞ›z¸…ßŸó«„Š-mljeıeØævÃéDµé®ªdªâ°êGE„·ºş°£’yÊÜ~ÿÄÄã“‰¦°×CWo½¯A—;“´Åÿ¬eB#Úyá´)Á½'¿ZÑ}
%÷Êœ_ÇŠ×¥á™Ö®<ª³FïÛY¦Z{´$P4XŠşsÛmRK ÍÂ8Â")ˆe™y–°T¶>Î:ÿXÌnòü*‰Ô¾m‰Í"ğ’\IOĞTÄâPE¦“P^0jÉıÇaÄÉ=§Í"¯ âŠñü¼£ë…8X³iìõ@
f%o¨n5?tÄMLød‰ï†ÏZOWbo>Àü–¶V>Ume‡Ø¢4²ïİ’9}IÑcî­ŒĞ50?<şçL¨.Ü.çg5ÎEKÿÉ>7³I¹Æ¿4^é^ÅÔH.>7ıÛ”÷¬Lom¨×µà§€ĞÕšÕ¾|{ç 3®şˆÅ©92('eº/&XÒò†úeip#7kÅ‚_•ÖÔÀóL:–„èÚì•ú[DPÑoN{4ÿ².?Ìpú	+»ß=%$XS½ı@àk¾Ü)Rß4@²›Xo–"¼d³g_¼2HÖÈm_`m¤6ÿ>4Jß3‹Ò8xz áçïñBòSÿi­¦^æ5 ğn¯j«ÔæS9:†Tğ8XËœ*jyøƒ‡†Õ½G*ïÚ“*·¿CNâ«Ä16İ2‰JËİôÖnŒfÂ<Ï£,œ‰J5!ş4­“}…¢Bçû#ŒåaQÉã“›8L4–ÇbxK|Ä¾ŠA-htüĞı8­,˜¨½E£ ÜÏ!·_1‚IE‰’[J’Z{,Ã(µ]¬»$‡¶Ğ]èªî—ÅºkSÀC{º5"²Îa´‹3Ì§f|! <s|½§‹:""q:"Qä^¨£ šÁ±?	%º4CuÆ’&ÁæàiKëŠ/Këğ¥mænmª^'IÍ8ÿà&±æ3¤fßêù¤TÑô¦‚v¥NL²„­uˆ2	íÁtãĞOW+/¶„¯¤ho„È?ïtÒ«.D¬ãA~½º+*Òñ0´ÊÃuÍêH×İi Üš®C`pùÅP;@6¤$Å‡9Œ¾ùŠ=*“Ï™|N[Èş'€±Eoª;A™Ëà]µ›nŸ½QözF»ò\ï™÷C×uÏäuŸˆš$äj^áÖKïÒvkÈpqÛßÀaè#\œPËu_Í^ü¬Î»¶†'Õyæ(¥™ìnqÈ)‘\õÄ$ ®Y{\[Øï·¬†µ „Ÿ¨—‹\;ñğ>,mvP¤(ûêhbºÚ§ZÁ¦ÁÑvĞq- Ù°ãòÀî-q¦ïV»ŞŸLmÈN‰t-«¿©"Û•ÓªOƒüãMÃ4Æ®Ô2ÑñÊ@3¥@"¢àTR0—¼~	/PsıJ«w„±‹¢Å	))-9²1Joı:>†òïVTÙş½«RŒ‹¿ªZ¬/©÷|yø0‡=D+ò¨›TLJ+–š nÏnİ¥tãÿtÎ„(Ë¨èHWŞ	©<ÀW®<AõØ_vV-C§r¶à€ì?ÎL\û¨«r!Gdm&g^}åWşíÕ"ÃÅR‡ œk¸U~‰™Ğ‹b@)I#ÙuOº¡K´j’ê÷›Xâ,ë{q=-Mà# İZ«à®X ë8±UÜ†–1%LyC[%o†É Í«Ô4s¡ÄîTº€şB¡<şü.¨†DørênÓ.³p¯˜µ¿~èŞaÍÄc“†{ú¸$X~<ª„³(¶˜Ë?IIÍè¤‘od3¨ŒîòÕ«®õ4‘ù°ØØõTp°¬¯µv²?HnüÑnÖS(e´üıâ‡!Ë©ÃKL¬Øç%ìœ>ûÆ‹¸üÔ ÏİGÃÁ8c%Ü–Ç}R%Æö®¤,?kXíÏH«Çƒ˜» şÒ#`ó·@¾®›°&İ™ÕúˆığÙmò´2Òß´Ü”k\’—5t!4b,50ç ÁşL)ÓÀL«·‘:Q°M•V¬M7Ù¤ÄŠ½•Tß<zqT	Û­»˜t)¥«N¼×u%{,T1©°’=¶dq}£Æä@'Íû¦,á„^Fëº*<|R+á^FìaìNZ>•]32ß?Ësü\>¤î¯3.÷šKó}!ø«yªMY¡ÎÖ—oÅzëZ,‰ã†Hpçúv)c"R6IjÃ`…ïÊDåØT:…êû´óå„ôïïÅ¢ÒgE¼›w¼ÀCR°.¨º)ÒÙC5ÜSÅQ$x¬m5Çl`£3ßO 0>-›³ƒ{!6\D§r—Ò“*Ã&3ïÛ¥S0ç«(Í÷™VT
¯ãNnn~»ú)vøÄ õ´ÎQŞ¾œ°¶õé¥ÀSM¢xh»²’‚RRFâéc§Êª4$±EÚòçøœ]£BÂ÷Ú“Ş¦öå·¤d]e‰†UnKBja-İ_ßO¢sxéÉè 9+ÔT—](«TUá'® „y‘n*õSÍ9–tÓÚFPÌ*j}na“€®ÑÎ÷7è}Xõ¡ÏßsÕI¦›W•­1`€œsq‹?ÏW?ïV·q+æˆŞwCÂfâu\^N+ó¬ƒM-gúyêÛ¦ó2;=·*úñ\¤ÆÔ•]Ì4¡±k×%†RË2ÍI÷MïüdúÔ"ÃtÍšpÊO´eæFyâÑØeÉ9î3úäùvú8Ï9‰üÀè<ä	.1\»*uÍK{x/Ìé1»Ÿ%‚Öj¶¾g®ıÜ\À\„øOmÅ{{Œx}SPÎÜªšct¥¸£™Ï—{Ô1C|ie«­^DZ[Ù'.Ù¸9èzìPaÒ“ÚZœúpËb}›•KxEÕC½C!`AÆ7óW‰´ÙÒçWgqÙ[Jm8×à÷—Wã\ 	ä¨ƒí™”Š¤x¾ŠÌÊqîO<º˜¿õíÿÃC7†%ËòòE{â7 ZGËÛıÁ5z=Xrÿk4-ÊA­Şé«£û†Nh¨ãÜd}Iè¢<ìg¯±a7àhóûqŠMå>]Ô„ÑóYş3-p)ªá"Ğ~úûSny¼°¢ÚiÂF®„“ËùEú'½ƒ‚İ íäÕ)ÈÊ|î@ê^á³€€’ÚµÌG_®=¤Æ”V‹‰™wĞ¢Ãe°EÄˆÔç~Î}³šJLì–‘µ€„¹ëÊ˜¯Pq:§d"Üq÷sGï&]ybKßl\ÅopRáé«ñJ´Ic¹¢Üy€¾[17›L…dÔ¨ ‘G&¨=G°z¸Êü.†eï$œæø=QR8¬‡­u­»\(õ÷t
& dğAŠoN½“_İ^ïB?æP´Øü÷íZõZ¢ˆ!Xº4køëQ28,·	ß¾Arın©A8CˆÁ5i.Å± Ô†£vÍÿ%€­Hz5Cç¼)äãí¢²a$p›ANT‚^ÅØ0Úi&ÏnÇS)üÜ,DÈk!ÏsS<ÅãÑ=Î„ô«Éã++öEÛ‘m¥Ce>€ì.†Í^³YC¾ªSq½¾8UUt¤@J3¡,Wä$Jtw::Ùº¤u Ë{×l—)O+8‰|¨ÆÛÀNËö¸§@ÑİÔ®Ç£ÖßŸŠ×»ãC;h q7.G¥a:‰™0ÎêŞBîê5ÆMRBÊÖGßup8ğj„ní´I¬¡6ªK+øo¸+Û‘®rFB
ÜúG1©&×ØpOõpıYÀN¢õPC½ÚH~icN4+\„§pö¼Ê}u>­ªâ¬¥…Ûâ€Ğ   ·° M´d” ú·€À®¬Ù±Ägû    YZ