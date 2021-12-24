#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3812588643"
MD5="6ba942cb55160f683da54aab6bc4e7a0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="24024"
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
	echo Uncompressed size: 168 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 24 18:06:42 -03 2021
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
	echo OLDUSIZE=168
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
	MS_Printf "About to extract 168 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 168; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (168 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]•] ¼}•À1Dd]‡Á›PætİDõ$å=´ô”vóò4‘¹cŞßĞµn«ÀñzÀ¢v³íñzòUJ|•½úsÊh©êöä·ô/hÍ6eÉ¸[ËŠiD.èÑ ¹âiK€9UxºúN®@Èq7ìğÉ+¸Š½C1L¾}Şõ‹o±‰\FÓ÷v€>LÎ»Ñx12ùí‘Ö¦ÓKL³Iœ‘·wCE²y—QÓ8õnSÚß€‘ŞãøèËñx$§4ıÜoë%™ì‘[¯ÖkkŒd°fQ¨I;ˆy–†}#Ø®ÃÄ½“]—2‘ÎË˜¶õ¥:'ózÙ•šjkX=aä×_Øx§iÁq2EÑİåÏ"|ÈˆàµN´@jjİƒ@B”ÄÖ¡jÇi´ğmF|Ğ3Eh/ñÂö	E+ã¤1/JÇo9}Œ’½Z8o•V9@˜{u>½öı(ÀÜ«êñyÆLCˆÎæı÷êYÿ+}i•6¾òû*’Îlb¤HŠÿÄ¸Xaº7Ï¥–²d,áá7óü*u7pÓèİtY»½á¼¥Š<İ«üØFø­ë	­Èb§J–Øš|æãÜú¡cî‰¥Pz?×¥ÊHj|ƒªæÀ9H¿ÿSª\</äÏÔ¸ïÑsOÖ¦ì0ñ½U‘ù|qˆrÓ”6úİ{æÁ‹5Š4Ì]Z¸úx7¦’…—1³}¨Í™ÕÿÑ-Ş&ó6Çü6dX^ˆ˜Xí©~Æ7òæUª²9-RàâFKä™ Ö¸òj"ûº‹'—ÊõT7$[/µ©ÛÄƒíx‹ÎJ½¸Í-÷¥=Ò& K_²x­,‡¯¥ùEŞôÑç.`b“óœdß‘CÏ¶½&„"ÀhŠª0€yÒ÷f0~R37ÔW´dÀhÖƒâĞÆÍ@»’°Ÿà%L|xÆNŞjV€	ó°'k‹m+Å29WĞ?ìIşç¶¦57Éº’}¶í$ñ·ó_NÑäz*ª´ˆ’Ôc»œ«Óâu˜şë§Ğœ<zbşï(!öúãÊs©Ò£·~w?È‡hø}¤69%|›#GúŸ™”UŞPÌq50ÆÌ¸¦4‰–1Äé<A²‰âY kÒÙÇ•‰!ez½@Ïò—·fËw-uÇj]§¤B.Ùp.(6C@È©ˆ>}ÚÎ‡~·wÕ·êŞ‚[
DãÂe³sÍn|Æ^×7ÇÕ»n~7ì±‚z}“ğ)ÏK $TÊÖäŞ™’¸˜¢ã¼Äİü6	‘’ hªË‘¿e<¨wf4­üÉš-K~k…s}]ú©amˆõş<èøã*ìO&]c¦Ñz¹Z¯Oê]*,¶"s®‡¦ŸA+ÿü!Hüš§úª˜‘ }ÊÏ¿_ƒ–Â.AœHChóÉ¦2ÿƒswÜF„K}&$ólı¾Án|÷ò-ë¬ËáÛƒ]¼Â]¯ZÒ^èxıiê}0åò9¤ÖS€Ì]•æä3³úè«IZĞ BÀŠÙnßÃœÉÁ9iëa
İoæƒ¥ºöŞnpH‰ÄÌVUvPl§<üIw÷]†¹ûyéfFF²Wçğ-ÆòˆğÈ{K2“È—ŒjäwM5´ı:€ƒ½V§]9½ª²cGtcu1½ ¯,$¾°(d+”<xÚá;ï©‚‰LšLÅ)«Èû‰éˆ v3=Sv w¿3@Å•„cğã7Gª˜=¦[u‡³>Eù@è+Å¨ôUğüQP–{OÃ&©ı¼°r¢"8vo€DÀÇj|f/éŒ½Qºı	£³ÈXå×÷€|9LCHYZ‚9‘´’µ}¯Ñ¸/õMŠï©òÏ»±VD‚<zÌ°*“*h¹š˜"Ó%M †êßØ­ûê|1>@¹Ÿ¾Àmr8şÅTl\Ù —,ç¤±»ğ5Üjnèùã|şv­’V
‘®d9¹Ö¨0òFkPÛxİ{\–?+;ó‰­}i5“0ã~PÂÚo¨ …”ğíG7DàØ&Å¦ŸŒÚ3}Æ×,¹]pÌÀC*+§–s>T!³Q¹Õb?ÎGµ›”‡ÜÊ©ğQH¢m¹ßâÍ_å¨gg„µNØäû;AĞ³=¡whë²4-!#q­Öqò²˜qö1¾¹iŠ/¢gÉôÖ.`tÿûÇ÷>¯}‘w8	3ß& Á83k?¢–-Ÿ‹¿‰1g<XjW†dÄ#,ùnX•ÚYÇÒuP·Ê ¯¡aŠ¬Hq»>PO\Íc} ïÛÏâ¡öæ}5ah6V"ÇÙiÏîÂä=”Öm‰ÏÂz|§	¶ksJ/kŠ›ú$¸BÃ!à¹Û}É^YP5´)(MÉv:Äu—B]ó,l?0¯d­ıw`£¦xZÜ´L³%>±¢I.Yü'ë¡ÕN¿øÅ¦€45Ì°¸E‚å9 º¿jÊÅ¶E
Í×€Ù‡Æ7prù0ÜÌ”Ñ‡¬RŸ.ê@!è—ëš?AP_(CCSş›YÎ‚®ˆ«ÎeU!( ‘Å$e´•‰™qÿwµIx>
­+óNš•ƒ_4t%õä­SóÍZš-ìÍu^ËPç‰j(.+cÉù-èmµş¸6Q$*âU9Ó|•º9bõ- »Ã/À¬rÊy`k©~Ÿ†©ĞbÜ´)ô*E^šã>ƒ¾¤…Î=_Ipv¿†ÔRÆ) \Xš4%Ô	Ö¯L¬À”*–4õoCŸ{<pŠ†Î~iİğ€§*ÔO?“’ïõ•>¥DĞÃá2TäH*‰ÅZ‰ëOše[`ÖnUÙÇU•İpu0 ã.°~Ps±%Ã†İı%8„r-©ãd‡Pa¤³¸«¼‡âM×R”¬ìÊ¾K§ÜØa„$›-¨7NÛ‘q\£à%ƒrôñEİôW<z¢šĞñn=pÖøº ÉyÄ‡ãw-v¦O»'hÙv·\€ZP‚Ûª8ÚWü‡@X77¿ª­‹0ñıàëÏô¹+ˆÈi‹5Úfï‡nq»2?pT\¼şiòw˜ÖÑı‹8q`¸1±ÚÈ¾}MÍÏ%MâÅÂôz·ç&ÒZÁøÖ^ù:;É¬Bíç¼Ó¼mIôùÇéç-}ï½Èêİïp¥OÌ(Ò)Ã6‰n×şÆXÉy±B¬ñ‚ù¢wàèO:¶{Ôôf.ˆË	f»š¯’u1ÑÚXŸ5ÔÛqŸc†œ/ –i¨ˆÖ–.QP¬÷|÷.Tœá½VÍËù0í’ÜÎÏäkêù‘×¹¾N³ä”>“_SÀjçîËD†Q'”ûÁH}Õ	;4gvíÛR”/ûØ)úĞ_&óì
\sU¨D:ß/÷§#7Ì¼-cœ{ µøÕ©™¹É¨˜ğØ˜·ËÍ/óÃX—ŞZ@¶¯xMÉ;ş;4·«£4Œ/°w—ŞJ¡à½$Ú`)hÔ6áG1®œX@BFLeø—ŸêşŠt‰bŸ8Fƒ{Û o`"3^À­éŒÿŠiï­'U9Ş@l“Á|$ß¯;¿´ŒG"ŸXQéÏ"„¸=}{t]á0s^A_Ã Ã2¥¶
öÉ©„ÿU)ú·È¶¦qµÙÆ«~<"Í‰DÖi¬kÍ%\§à ªÙR†¡,—&8ıR\ñºPM§YĞh¸u	)bj2ÈNM°9½Òâ]’d–”VoaT?}%ÌÜÚ#?7$ ¾µAbQÛÉrı ËÑZêá¼õ\Ùòƒ º³îc¸ÃCø²‡Úœh|UQQhZ!ò->Îõ€>íš7«õkŒïxQŒ]»9ï İ*^SËÙÛú~.½'¯ñbåŸ–#ä6ÒNNoM7OO›°Bš¬Ä'·³CÔBlú+Æ%yü²ÛòpX˜BÌášÁl¨ğÖº«ÌÛ|•ìÎ0c. İËl®6ã¨[Æ°7Ñq,àR0ªgä»&ò3v©,l÷˜Š BC™ëöÛ'ê_¶×¡Ìø".!
ÏzéF=¿¦”:Ö•{Í©ÚŠ0ÅDS–tt]Ãİ«×Èo¬oVü¬8è ÂÎãŒ©+”í‰æ¬8\¥FŞßé•lÓ.ë	¿H×›à¢ W÷}Ã>vbkz=JO¯`Å ÍÌo$\?œl©Ÿ8ÇøÆ&x¤å.ùÛ7‰'ôş Ÿ›®h5¬íBD>İéKú-›±´¬"‚*áj–¤™wY“{ïñ¶x7p“ªñ‹bÔ‚ó4‹¥!gù;.P$\ÍóX‚+ËÇ
çcˆ!¨ıv0E]ß
ú!ÍÅk“/eÊx ãéì®¨Ş$3~¸#F6â!Á#”Æ'`k$ëk8©U5KÆxX1J*xHs‹¢ÄÀæd©'Çÿ²Ska>Z>¡u4GôÈO“„gI’¼§¶F½¡D‡[•n q‰£ÂƒWKz€ıLØ,9Z™íß¼{¶jõf=µjL1s(>ƒÌz)$ü2zª@r’‹LWuÌ‚ñÿM; Ÿ];·K¦'Éu¼j-êÍ›ŠÊÊº³{¿±¯šl’)ã'};œXİÕèK{Fÿªû¸ ŞQ—Ê1@B4Â“j÷¹iqRÊIèAsÚfz,:Ã=	Ğã¾ÉSÑ	“öŞµ…¼œ)}Qoı=~÷I›pÏêöı¹Í5ËÑ0Oça®ö1rÌ˜eé¤j£¤UİG².È`¤ÒkŒ +9·¨O'a;)=÷-Yfô“ˆ3@MÃ4>Ç bìÙš7s3O•¿EÂ‚³ÙZê4:…
êŒüâ©éÆëW=…«X[r¿¬.Zûçi‰¾Øúã©ºÓwí·9¤Ğn†øâ_bÜeÿ¾‹äĞ¦ˆ‹Z•óÂ´ámåo*Ò} |SBMZÒÖ$Kj’tú•^’à›pÅ˜¬•7ìûcZ¿Ï3°ä\í±{cüƒ¤ÙÄí†êJt‰8†|l2ı	Q•ó¨2J,QwdîÄOµMPVÉÙÿ ª+£ls9Fmu¾ÏM–İÆ÷ÈÚ¡v”ºÈàÜ¬±[¤„†¶Î£ >ˆ)‹œÔ0œ,‚(+†ÿg]Š“¦Ô­ì=íš;`LbA€rzÚñ®ê7ñO–Ü´¼Ï	½‹¦—O‹œâ¬Á\0ìŞêvnË¶ ùí^h8ã¦Ç?x(’›]Ÿ‘J¥”÷ù­Ô@-u©Ï†{eÌÓÆa*ß6
f[µH	‚÷_K¬Õ!(ƒ¾${ßZ‚Œ³i\sÜ”?MÛ ÂjÎ«¿ÇæØ]38´I¯-GD­ÏNékùĞ`±Ó0û•îsÒ(şl>ŒÑ"/LââyŸ:Ü›üº)2š	@¯œˆc¶rŒ±,iúXA Ø~¥ææ 4‚‹Vâæ~%ƒü)‘®°ùP²LñÌßq4Ükt÷¿¦,_ÏxÅ”{Ù\îÖüWfêC]U÷E´C÷–íÚdm
ZãMvğ=–¢Š>ùãõÑ_şïşÂ¢i]ÊXH¬UØ˜„W®ô¥Æ·ö§Ìı·`¥ıW¢÷…cíCUV>òÒ¬ ±Ìë<s7Y¢õ¬áŒS1˜*¼wCqş¦ÚBœx%‘&®lw”Ò¬ù®+Ù–çyNÀs<ãhBîÿÙm1‘U}SáÙ ”ƒ³‚‰Xç“Œû&­éB À>ĞŸëö¦ñÉ@ÕD&&Æ4éúË¨
áõÔ_'çT1Nr<ı°˜4–ÏXiŠ‚’õ“ÆŠ`ßò›Åˆ^gèCˆÏ“o–X¾åà¹Iy¯i”¨†E1…ùWØ„ZùÂã.üòãæË]ëBBÍ]¥ó}ÖÇK+÷êŠ“Ed!Ê°[¥°",.hBÂÌñH×KñæI“75–`ˆ‘I¹	úèàSë Z´Tq`\l²1Ví”Š°PéÕèbŞ´I@Y½	Ë{NDĞ,)™¤©á1E}3TÙGY»ı~V}ˆªØs3…‹äöÏv¶ë€ÈòÊBÖèq²Ñò+U
UÄwÔ9ÛNÛÖÜ×îC4úŒ-‰ÚŠŒ=¡uĞàüSZÙ¾.‘,ÜÄ‡
 JÀ©>T ¸¾Îî…g;d¼¼{n¡ƒyCİ9÷vñÂk·¡E³î=UÎÄ jÜåB“i½ürbò6ŠÙt¯_2êä9WÚD_?F½£¬=}€x$4ıÈBdI$ëe'l¡¬c)“/(šÕ3¿‡†>*ß“¯°{Åœ:‰Óo¤“UÉ(¤å¡›;à6:¡<ÙóÅtjå~Ì’J”KtU\OKóÅ.Jş†¯prp`3pÏÄ¯¥ŒätWgx j­Œ»A8Eh÷1×ºûmş]Ÿ×“Y5s\¸—À`;•¾l5‚ÒÜæïe“£¯’ééqBü°7ïíPPÓ¹Z¾Í5§C˜ä¡½œ3Ø,“‹]L›-Tdª•à«zˆVI…Î|VWñfeXàã™Ÿè•î6TzL®\Ÿ<¯‚€şŠ·p&ŞğİÆˆ®l@ıB<º`ãå)?S“œõÊ»o§½‹Û 3
.#ÆgÌNt/ê”§ñÃ™·^çÉ(¼Ó_Ûˆ¶BBO¿SsŞ¼@…
q¼‹	•d &OTCå¿ÑÒ?;Ócp1¹”ŒBÎ¶ë¬~%Û6MGÚÙãrğõ]¡šÉl‡İ€.<:È„Ù•%„hâ ;¥Ë{¬;äHAIwD50Á8oJ÷>H`óHÂñSRÑ‹“şQÉ†ÍÕQj,£Sƒ(XGkŒlYV˜àU“:ì t÷O!Ş¬¤jJÇ‚À ©}‘˜dò—I	yk3~Ÿã7F@Lç”ÍÄÆ»WçŞ#¾ÃÅc½³­ï&5¹K¬uÕ3íFN¦ìP*§ÑKfOÌ~eÏŒ–8à.ıÜï£ü¢Æ•ã›±ö¸|ñ\ãäÍä@<GÎ2r›yğÀ§úï“í >Á-òÏ,Í¬A®{/Š\suµøj.i^×ÁÎ–µ&`àjôõ;¸¸ê“(©Íš¯h‚Ø{U£Bî/2è=¦æ¯ˆ£ev(‹î{®Ó&!Q·a{Gp$çqº„OR¦8>^¤{Ğ—Bûévıót&xâÅÙb†vfó¯lx˜ä/™şÈ;›kŞÕ`<a”æÓåB¥ìº2¡GqÏ¥9‘¬‚Ü+¯c\°­``ÑM1 &g½øÄ0‰ıh~ø¢	/‡\æ†êkÂ÷”ë†]ÏX“Ëµè‡ğŞı’„±mğå÷x7ÁÕz_v^\Ğ‡²³ö>÷4õ7óšFo—	•ßb¤.É¡¯ÅöƒZëáğRÍ¶Uq–x¡÷=dWcù´kĞi­k[I¿fõËa’“y°tiìİ+R²â9ä.«ƒõUê»YŸ}¯}‹+å}Ø=øfdÉr…÷¡æ$r©«ş
™=÷D™¾"a(¼À9÷ä×ŞB[{Aï[CkCP—OOU&½ve+$½ujc¡ˆ.hºÓY”7‚.î\Â2‚ u¾*¿‡&j§!pS{ê~¨ÄÇ§ÃXN¬½Ö(’½9Éó{¤¥ûUğÈ &‡VWğ¾ É¦ù™ûr³qß— “¯¨îı´ğÓiøí,;›dßĞc¼İ¸ëdV?=S~´ğâ)»ÔÜ-©x5¬üİH½Šlıp½v ²Œ¹Î_šÍóRÅÉyFœT<00,=¦KH®G†¸Wç™¾J¶>“['Î¦—qÙÜ\ Xã³1äØTo#ãjm¹·Â™éY¿şİpÂÙ´–u¡ Æ°L„´ü;Óî5O*®1 ™irì×Êrº6ˆËötxîyJ(ïgÃ¿Ğ¬*²Ê‚`Ï]E¼9'=^ü·l’)mXL,Oé»¢FêíËRÍ[Â¿Üˆ’u9®$k#ZŒë`%7AšèÙ˜2ç½“õº¦”ÆCæı2²ß>”Ş¯—Mêm’K|,ş0
P»µ‡3¯,å[¿8Šó+¯=Ù]N%Qé‡*Àğ×2O¸µñ1½†ø>‰zÚÙy~ıÄÔ”÷?†r°_Ï¨ßàÿo…IüMØlÍìZUzY5>Û ÓîîäIÓŒ7èi2ÕŠÀtÜpM/*iá«ËÌ-£/ÔQ"fû•{„È|¡]L{KvµÎÛÓDĞ"ŞAxâÜp /íãœXU‡\´€b=„ÏŒ‹æº„MÓ*=!¶¾ ÆøYmGÆ›GÌr²kS:œkÙÌãH¯»¤PSô&åÅ³ßôÌğŒ*¤û¤©ëtRŒø°Y÷*­ğÃ50¯Vp~tëŞ\çaO'Ø;*;ÅÀù]Gf'±…,¡ì½Ù`Åôà¢¨8²½`$›Ü.emÎ SV“v„^ıŸI–iLU]JÑœ©^a¶>ğ§;°şìı+Æ4õùáşüñ/hZBEXRytx+Okj6~ı:Oö ¥¶:f‘œ¬ƒS•îi*z
é#7–…“ÙÄÍ5øé€•%	ÖÊ×şôığ‡±˜£K%ç|ï9¾udÓmòxL²‹Ne†„®Ø¯ÏøZo.Cx
õŒ<å¦“!9ìŞiá7»ÜQ0šúªÑ¥ÖŞÊ3÷\1…:÷î’%ŸN_ÂöÉAİŞ¸óaoÈzÿQM¶)˜û:Jò:óïi|Ôœ*r¡øyë@Tu…X—‚Ãíõg O_Cï¾"8^ApD5}<şÀx„Š°zIÑb¬ëgNøw²"™m\Røê]ƒã1İœx ceø£÷™#Ğ[•i6fvÂIK‘LİĞ§Œ,9ˆ›'áÏl«Ó)Àÿd_)‡1|–€Íëæ,q
Ü†’†l§;å¡ğÅ¸ÆÈ…v¢bMp„kº[¢îÉŸYêñ*ïú­’³¹À0 cïœ…@´“Èèâ%ñ:º[
qá^@xï&‡ƒş¯vñqMÛ¸Ãå38¢ ¯IwkmÍ<å
ò'N%½à::@¼"‚šºïLı¤$.Z€Ï8b?ıÅò+ê“S2‹Ìáj˜\ÍÕè•í™Ï4úM})$•„¤²
½´(®Vúï´áâC8åYW·İâ®Ìòøü»b ° ˆ¹ ñG0~æ‡§ÿ²öÀ¿pãÔ°j[tÑëIªò=%]f’‹Õ`sşv3èèûš¤hÚÅÄï°Êg…²/Õš{ìÁLèiev$—ù$—hQ¤¹ßu]~CZ#û˜Ê‡Ô7wø2¿ı5·¸1*²OI¢34C%+88à©u@p}·h´ç×‘¦gNäë¼j/¿7¡n™{±ÛVd2òLí{owtßÚRt¯úTHpİ}ø…$—+'$ì# &¬fùË3-ïC,ªÿMù6ú_Ğù%@fMB›ª’àùÖÑ#ÅĞh7Ÿ…à§Òÿ‹¹=İúíÜx›¯Ö£*r-ù¾†61}Å0–¯“ü³ŸL=Ü¤¢‰«u‘‚Ìü9Ëı04¶¬j—eóc‡À^w3BÓ­´Èu¡Û87®z]µ‡‡`5ğ¸J¹åf İŒúd^a·3sÙ
Ñ!ç¹ÉV\İ3°÷>Å€&-•~_-G¨Ås6‘áƒ¢r¦NX$Ø³É¨°:ø”?×E•§_ÿÆË¸ìP
Ö3{`ô€‚#0{Ñ¾Îåg²ÚtkÙµ!`º.åºWâ^î|:ÜÙuÉØ)÷øˆèÜNµÀ–î7–š|x¶ÖÙSŞáÚUã‘,…„åAoòª#¥¨rÍûmŸ×±”ş(IÊ€o˜$i<r'y³y¬g¬(ß–S%ò1ãáÌ, ¸ñ_´"eä±û¥NÁ™Q»<ššÂEöoN¡ËÉo£ùŞ5µ{š°^ÉXX×$¹¡3INR7M^
ÿÕ²qW
†ó²†Š1åŞ„ımûJ]¶ZŒLkËÍv×fÍ àÙJ¤›_ŸÃ˜k;ÁJ¤‡c¢˜ûˆ	‡íóÒÚ4Ìı€i9,®ÎI¸pÙæù=r\Õ·£êcË†o Ÿ³ëÊ’©}şO44—¸Ñ{ÇšOj¾£cBlLœ Õü}>UNÛ‡Í”Grº$ü§UWPÅzs3Ì¹_rÉ¸×=îjN÷¢Ë»ÊiIÜ•i.zûövGg‰üÀÆhhÌ‰¬Ìw#½RN”&m%jIÉf^Ò9&:‹LĞuÆ†œ|O¶È_7>ì  SĞw‡ŠıÚqï$v%u~Œ¹)ŒGG‡Ÿ°çm#Uv1,Ğš§PfR^ŞâÙó¸/c5”_‘÷gÇ+#ìóeA©Nh¤f°ö`Ü(WÅã=C]ƒie³nZ1º=Ö'?¤J#®Ü#gÑq˜oà=`›Ù|òNMK	Ö§ÃHÁjôbÒ!£èÏ™Ï/ù#±*wP™Îi|h°Üìq‚RŒDäómCĞ›¸ÉıRò3IØr©Ú}h6*p1ÿ8­èÜPÍyô¦èâ¨ÆëâÃçª±«*ªï^Èú<kôObùFÕWÚså‚³g!§4øl]¯¢»<.RØrø=lS¼ÒUPÿ²µb/"¸¿€¾%¤ìõkÏ'R­=¶û•.›z®^Ù˜v	Ad«L—–>IÄSõZ#ì¨…Àò·Ü.qVıŸPúp‰p¯c0’ùaX|Aº¢ºvm©f?GTõ6A>jü øHÛX·Á•ş«iıı7ÃéÑ®qêíši-ºÌïŞ3ıîÔ½¥Bj	ÅI¿>›Í…¥°ÒL¿Zä[­ +>w _„ää©U ƒçW¶)¿Æã¢4Ozñp¥Ú[«|Lñ¨%-.é³ô»¼G$/PÃeÖ×ÅI÷ ½ĞÆÌ"ª[˜¼÷pqÒì|bïë§¶—2Ú­Êç¿µ×ÊépXe<8K’¦ƒˆbş‰ÛîT:øX1CV-ĞhÑ£óõÉH >ß)”áX†­êhÍPBRP<ém{i	I3Ky•…ı¯&.CJÇ³ùÊîå5gƒŒöŒJ`ñwÆíòt’Ë¢ÛG`ÓQ²Îå²sD³1¿cğÓ_Á!Ûæs^ëtK[XŠÆSØTï!½ÎÓ}x“¥$²«é“?AÂ¢zLÊ %(’Û„m"n!Ğ69¾÷[¡Ë&5m¥^;Œ!B%cˆ‚ˆLâv6e£åJµlŠ»7…‘J¥›–ì‰qb-yÁ“{as–%eJõIbt–wwaSuÂŸ%à&d©Îè§ÂLZzÖáô]ŞôñäKsLÉ×l€Xåë¯àGñ*‰KèÊ¸$ˆ`3N£ækJ¬ú ØÿreXdÖ¿†Ìæt¶f€LÆŸÌ`ÄğéZ·.©÷‚€&–¾´U£±òlà‚ƒ÷(œM…×MŸaèNö0	ƒs¸£>zˆ![dIÔ­gÌn¨éî3Œõrög0Ú  )ä¨Sà³¶ù¥õÎåûHªor?Úêêœ*q¬ÆüYÜl ƒ9]~'§;\|Al³œ?¡ôç’qh§C0°2+É)¥1^)ÇyÍíåšÂAß‰‚g#}Òı:Âa	ÈmÕ›#áiB¸ĞÓşnVªHÉ^Ö¡¸Ù×ê6lBñÚ0çˆœÉr(¬?ÇİÂ—BkA¨SŞá©EºRº¸=ÇÉáï±
Ázì¨$tEìB~¾oDH²Z-i™½²Q´ë:,N.ô“€ZÉ—Öõó4ñ¤ä©im!8|ô&L*:â3f1V¹àUì¸Ä’(y¶g‘şÚ²yy‡l‚)u·§‡Ÿ	×Šî9Y_”±	<=>ÕÁp¿¨˜–ˆlkOJÔzò,Á¿l^È9;ÕŞµ©"£'Ÿä_Ğ½UUø†YZ@á‰şïÜ¨0%_iõT×,RëMùm3n€ï"Ö/ĞtÓ«ïÅ'¿‡^°S3g1¬v4‚fgÖ³<W=Àú›â¿¨\â3=zbÆ"vÇ‘Ã=òİ5³úÛıƒ^ø}×È#ÁMc¬ï¡Ö™HÇ!å$V5JõŠ½-LéEA€$±,2´ØÔ¨Ğ8¤àıÏ’ûIğñHˆÂÿ2]û°a"ç¨CUjô}§V£Ö÷+úàn°@ÇÔĞÊBIk]ñ`l (ftÀ2¨v;·Oºº8¨¼À¯fº¯#›<§…K·išå Yw‡<ë»=ÛŒ5îé2ßÎU/:M²§§ïœäÁKc™X™Xîo—Î!Ö4ÌÈÇĞ@?ål×'ımA{vPò"I Q"Ãò™]”áŒî€„1ŒŞ¹öîcÎ+¢Î]Š3d™0SŸ«§9®µ‹¸‚°9I(cnËè©†HÓ?„¡NlëïØ)„½ÿ6Q†GsS’¬#péP–«&Î×Sa”Îsq+/?t°íºªÕKğ>sŠA…±GöœHf9*a86ùÌÊñPfi7/I€\€‹$PÒcc|´êL•ûa†³zš'&Ñw«=ÊšñæW>/¶š=—‰}ÍQysŠİµ‹åÀi9Ñ†ÚkFÖ^¿´¸\dt"±¨ï"¬qp–ïh¢Vëõ¸^MĞ¶$®wïÎÂ8*K8äÚØ;y aÄ&¶ÿ)ıPª¿‚×Ú$Ã4ç!“Ö¹ÀµïÖÖ›UîMè(A˜Ã]É¡Şã`BKj5\ğ‘w‹×½õ  &Ì½3ÿ3gdD|İŠ’uFÍÁô% =1‚¬yxÅt½İ,ä³Õo*[5Rÿ6+~¿’W­=içËYn/XS~ÀŠL¯z¦­é×æ,9Qgc¹Ú	M©ÒD»}…„0Â‹à(÷|÷İX"€º‡4ğšM‰æFÃo4Ñ†æ 8a™oı¯7˜Gı~ım°«¶¶z ½F“©|
@Ñ¬[Ñ³§ë<çEä_.­ÚÖW»óø¡:S¶‘:4ºÑØMbG¬=yÍ—/ÖNYˆëÄşê6óÌ-  –fn¤¸îH #>]2Àºô¯ú«Mé{/âŠ7‘š×2:NÎH¯í—ç@?/;I)6uÊ7Rt6>	yaÊ’Sä1Ò0KÔ*¹½RÑÈö9û¢*‘!ËóÅğr`òSPJ1*õ8¶[ùìR!+|º%UØŒ%W|l¸_³}NqÀäs‚äŠ_‚Şd“03aa)Şl×d,“ÎŞ§eeJVÕñ¬¤ò¦BR&ÿúw=H8“Ò,uZ8vEÔ*Í¿M~ê|
Å‡¹ãÄ¦9:çâiKÅ:Ym¶Qüp6îN–W¥˜aßã´9’ÆC¡I@×Qôz$Ïño(ºDüõœ»G„¼9¢ÇÇ8¯5ƒÌ]vEVt)r6ÂŠÆ?ÛÑ¡pªNco‘>¯]SÜZŸQPóf]œÿMxd5_à6÷	·Ş/Ãïró^§èü‰xíğì»½)¦#YÜ÷­ÚP÷A~ôn¨üxªWË	‰Ó-àå"íÀçrıDˆ‹>bg¾™?'Lf“Bµ˜~™è	)[œŞ«ƒÔ7b ÏeI†q ,·ú°tsšÆ›	IrÌñEÔ¿Ãy[¶£,âóğYüÌ1ú¸O½"–¾Ì
…Â¿`c¦¦¾äğ4I­®ŠÓj§áŠLõ:µÎü&dv9İu(r,:DkPÂ~L°\E4£»oFçËèYÒÎY‡›Ù?o¯´’´–şU2A¹e!Õò€“~íÓ2ğ‹4]8x÷ç7J·•@åNÌ€‘ûÍ”ù¾¯í:9*s*÷ˆ77¡R”Mz†OZ½Š-Î¸
Áëƒ¹¯–CÓ–®å=Zë§é Ôx$Ãqú‰BnÃÛ¶ICÓ>äÂ)_•BæŒt¥¨w »½ ­ãû%ïˆgï/ âB÷ß~Ÿyê ö ¤zå¨ğ¬Ô´\¡\¼¨ğóæ]ÎxbÔŠO–%–*µOks--rAÕ[¡,µïa$Öóµ"qm·¾Op®ÓÌiRYˆnÃ/”ªŸLè5ô@¤ì1öà7E”Ü0¸sp”}
[qÊ”:»¹Á¬*=È’ôfb—¿i¶=x¼¯Ú·QšÔ  u‰Á@:&Sm²“Ôª¿Bb6·Ogì—,)åáú)t}uØÚnØĞìoü»}¨#=ô¬6¾ÒD¤]@ó›	²ïÑ©v’¾ô ÑY¢øœMW‡{ò­WHyv˜#eÍÌp?–cíŒpCŠu*Ş2ı-"N¾ÊQµøIôî@vU¼’OŠâì©U?ÖG>êÀ8r£œú°:»°å@r~VhÍ	Ó k›]A€ŠbK"Ê2#,Ó2_˜„³1%şÆñ†‚Ü±ç¯26;Ç(×9^ÜÁS$âš§ÀH08-1£’#Lfkw¬
4œF1,¬ŒÌÓğUy79ú‡>ªYA—BËèfÇšó'ƒçıÿD SäÁ£y× ÁíÅ!^ ‚n¶r®1zĞÍ9œ¹$¦~`¨Û“~nÕˆ<ˆ+(éS9êº4ÍnÕÅĞãëé“sp’IcF=áJ’^zLAš¯–S•<•ëØ$}{ì}	}+I’ec#¿TlØ÷Î	œ$løíI´HE¹Ø 7¹ğwf~ÚàëGUÌ'8ù´%‚3dš¬üÿ¶Gğf4Ä¬‚b#f*D\Ş±(ˆ9ä‰{ïXêµí¤['©6|ÖIš°ÎdËÎúV/ˆG¨"Ši:ÂÀôµšu;Sç:ÀÄKë®°=BPBßxDùĞ0Ô®lüYLÅ+§âÉYŸrJg\…‰]€wÚ¦ıGeO+18:NnœU”gÓùéüúŠF	Ns„ñzÔTÁËöoÁÉŸ©®ïTvK•_1$qˆRé˜Ps¢NĞ÷îQ™ìeB%™Ò?Cé£šûÅ¡îh9ÜÊDÎÇî24!ò‡¸—¨ID”N1øl¬•—À“ÿ¶M½¸Ô[ÿ$¼ûŸJxğğqPUc*O«nâzÿ2‰E¯hïXRlcüßFûÑÃò(­óß¥z*w.¹kˆVUî‘L1ä#™Iø%ÛW\ÖÊ
ĞÆÜûšJºáÜ–;³$ä;•#©ğÀ O†|D`aº
ÕÿÇ;R7Pæ[¡ı«ó¬<gx}Yè€F1
»e^—¼ÙÄ	÷¡TËCIJ˜)¯R’Qwø§½›ëQm{Ùpüµ M—BN¹Ùåæ0˜õl¢¹CªÿÙî	ñëÉş€È1ß;önïS™¦ìÊÎ‚‹$B£'\èºxS+Ñ=C.¤ê¬x n%¾šµB°YyÒyj“*S ·a;L¸(ì¶É72&»”Ëıò¶üm1Û4YéŞîï@†èå®ñ\A¦{˜@fá8Şƒ„Ú"t¨ XxA,Ë`·€Á:)«µåÿú–üß»Râ~K#}’qz˜Ê+¨£ÎløtaK°Ë|ÈA&š²©O%Î7éMd•:|âÅK)fUÖˆU¯G¶/hô¡Ø6(9xÊ¨âÿ“ „¾/AâÄ¸¶n_«Ğ|Oœ®R9º-?Ù_Ã†\Ub™bDbÎéU|9¼×Ú]Ae-@&TIT:l¡“­õ©z¡±êÒ 4*ƒV!×áP™Ar~>dRÀb ”®Nóâ8,^¢ñ¨½i~ù¡T?É9¡j·´¨lÀ—‹…D†JğÒ«İ“P£H†­*±ú›0$¤áºIPäû>²GG¨U‘4 "°ªÑèÍÊµ ¢ç¨|jÌÕMMœÚ„ä ¼‘‘c
a(|¶Hë÷FÑFòŸìmÊ\"†JôùçÖJ÷˜óÀ`øí®ıP‚å	È›Vğÿ1L ks®kÜŒÎ…aó@,úA†®f )è:7šÚÀ¦¹O4]?NxpÉ	wpqÿËíÑ ÓÁesöL)YpôÒ;VŒ¾UÎ:(Óæ}‚‹*ù˜BT»ŠC`Ú	“™@Œ*4fo_@¬~ñÖC®ù úzj$]´d:/äÔoö‘K/Š.?†§b·å¹¤u¹¨æB“šYˆIXiG“­ê¤ïÓí+³§>Ÿï#3,şæ§uVÙÆpß½7İ¬’0J’fefÊín’aiÓÁBæ2rP¬VT7×?QgQfÿj…%Hˆ3àŠ0Î(1bŠ$í#w'H{öU|ÿˆÊDâ¿W6¥zÙs¢a°Êvn»İkå‚ q¨Ëó;xÿ§j7ååĞF4áÑKÚÀ8ËzúËOì®	?ukûi¹£Ì~YÔØù®ŞÃ6İ²ôƒîO¼šcï-8²JJlõ©Æ*ğ´ö~HªAÈÇ>òŠ‘·+ó˜¡Rû[Â®Z@üŠ2ıÿ¦¦ y<“¦8øª9i°S1Õ9<Ô¡^iQU­ó‡;MaŠ<tÈÒ×ê?q°¶-®Ùá.aŸÒ+~¹4R/­JÀó®©òÃAt"|k8…‰‘±7 0J>n3I;^cÌu$]u< •¦»Ñ^úPbã&¹›Üåšå‘ÖÛt|ebXJL'r*Ñ‚zİ6m	µ>æWb¥ÿ;º”árCBÜvÚÚxâÔlXÏâ¬&ÿn(‡¼Z×.Ô_ªKn±Â—šNt(‘ÈÜ ËuÈV¬Qê·èÍ€mÌ¨Oo5â¦«zµ¦’…g ´I¯Í³ß—¥$æ¿’WyöZ·QLg®¢'K¬–Â4e¸N5ö¿7Ó/……˜©î1pŒ]ü/A	
Ê½ÇWÚôÂ'­Î,„Ïf]Ss»Pc¬F){¥7Şâôî7ò“†«mnK Ğer[Y~–ƒ±_CuR|mÛÏÒÃ¶Ôé|v;²[=´'Æ«³“<ˆ
¥}®K2ïˆ/|SW@ûı¦W!Z•/I8u7GÏ Ç¾VXùX­”n\Ü$·Lº@°Şâ!c«J‘gåSvˆuëá©œ·´…",7Ø:ŞpväGØA·²¦<)€ÆDü¼h9 ìmhÃµ&-[$YÒ_´‚ëO1%ğF®çnô9Æ×¹`¿ªof3.eîq0S=O¿a8ùRš³‹ş§G.Ëv1PCöŠİ‘yAíšŸpÈ({GMŠ½aÊ'#ªfRcÙùA¼ `ß}áÒÉZ—üzƒå5bè]E—Ã5ÈıÊ%‹âöjkboÂ÷–]¿¤úÔÁXB¼ë´&ß´÷Ìj™üU./›T‚ÍdŞmÓWâüzBA‡2éu¬t@Jíã-5E`g¸ƒ°2GyˆEˆ£úZ½"'z-¾U–„ŸY)[ÅxõüëÏ$ÔøÎ8g‡;óÇûj7£§dÍîM·“¯Ø;³§*ÏÀÓ	µN­Cf6æè§7ÍJoNªö8 ôê@´:DØnM{üXÕwÃ
V£Á1ä >>^ÛÃñôüà —è1/[ûİ ×UÀœó]Xw_"™’Çş HTƒÙØW•£¦CÈÅèö!M* _8îÁÂ°’B÷Ÿc$ğ)ûôÄÿÒ‡‚«şâÎ&ißÊ«½¡ã½œ·ú‡¸´}i'®¤æ§%Âws[–¨êÉÄ3gÜâ5#G{>Ú÷%õ¬éQÛıVœÖö­ìï=”¥1ÊGìÀöãzy,ºÊ5ã}k+Ê–à!.•mºyh«ùl¯&n`íS4Úv+ú?`YEã®µ²è€€F°	¶1('ó`öË­5díM¬ªdF	#Y½¹‚åó„=HÊç*ÍŠşNéôEÿb8f=ÅnÏ™¬R²‚¯_•¿>Ñ¶uè+YêDpÃHı¦Võª:+“]bw_îPMw"ùŸEîÄšvii¨ÖêQD"›ÓF£ñ’£R)BUJ#óìkú_é››]!ÓÄ¦¸Õ†ëşñÙ¾Ş>V—Z¸-"èê™7W2p´`ËuÃ„¹¼şø¤ËçfƒÔ”V>uğ+ßXÏÙ¸¬Y´=s[Ã— ©·¼OÏÉˆÏËâä«?EÃ§zß‡ŒèŒMUw¸ËOÕ¸¯‚Ä3ãêÍë!Û˜ dgwÀPÙÏâèI½Ç“v_ŠIw*ds8£±rÛ-¶ÊÁ·Ú¼šp¸Ñõ¼µôÖJw[F®ABÜè§!ÀªW(©>wó,]@Lè¶ñè¯ÓµXşB†
½ìNì±‰şí®|âøè;s†3”ñuY§MŠ•7ÔY%äEìQÇøxêj.„V‡U%1Ê‘³`Ş8ğ|´»Uz	î‡Ídök2ôä!ñFpû0‘…Åù#@¦´Kö?Ê„Zq€½¬û2Ş?±I~%R>‚N‘i·¦øm	òªJóÓ‹P1ò•I5ZÏ$ÔvyGC~{ÄYÁÓ?Ì˜Àî™sé˜}µ7Ò#ÆDĞ´ÎşÕhïz/0…m1‘ÿH`€®D5d™=÷»
™wÏjÍÎdğëÂtx*‘ÖµÖ`nø!Gš”4?³)J¨ızVîÏ•
Ò°:Š'B~Æ×bÂÀ]İşÀ430Nş^SKü_gàdl(qpPO$¶ùTÃ[´VÁy§^U ä—
x}|mÅÚuĞHÕ.mJÜç‡zËÎ}Ÿ‡ ä=>Ë³Kšø;Òƒ¾jO¥µ+²)ŞT‚3*<p"¤(Äpfã=U-–+ô1v(2¾Y†¾¬z#”—1Wñ‰ÉFF,Ìj¡&¿ˆ¥—sJ¿ÒÉ±¥"Îèsô’¸‹Ñô´’`Ó;hu“9QFYêÇœCF±©¾Tö¼QvÌ[RäIiĞuÛ°"lZ2³¤ûÀÄÖĞöì¹6cP8G±‰”‚!8îµ¦¸üN‹×ƒ÷ÕVĞ*‰_uŞ!*ÒÖsœŸÁ5,by>Çbß‡Ï+~Kòhpz£~¸‹àE )M|wiÓÙ(°Ü«g~²¯ò\íâ«”Æ‘še3®ˆx…¼!şCÄ»Ouñ. ÙM/Œ+Jãš¯¬=—÷Y÷nMçS¥àeŸ{h½	×©­oA_WN7† ïÎ‚wàÀ´†Xjd7)ëù¦	kgD(XáZ’êQM€ûp–lÅ‰?¿ƒLüe¥Xº
®%É#|œïœÕ„´Ñ}ßfZÖoâ†â'—LSÎ°š½pÊ1-,rf$)ÖÉ¨¥ê6ÅÑ€İl/è€¼b¯ÚÇS§ü«|ï
i6Ş‘]hÂ¬vF™ˆ–ß0Êmg2XêÉ”U˜Œ=Úâ»©\5–£Ò•:B'”+mÀø[÷õÃ=€ú-¨‚f¨¦ı-‡Æª¡İœ¡”oÌ3İèiö—…K7ñ ö¡§]9á´²|ë08”#ÇGyÇË#1Æ{_(pìÇÆË1J½­}ß½äı¶m„Dgø!2j®U¥ª€êåVãÄÔ‘Ê­¼S€¾…Dº†î˜Û§äâ/¸Y‹¯ÄÑ@
«ì“Å0«éŠ°ì©GJ9.mRóÑPˆŒ±ç„nä+º0qríÂõ@¥i0İ¤FGÌroêAÛş˜ufëûÑİ¨A{¹rR
ˆÍW/T²“:ˆšzÕÛ%ì7ü8·š¦Y¿3ıS·‡§ÈD$³R¡S IP#Ù¾ú¾Ànª¶´RQJ}oE^ç:ØÖ*BïcH+{8ªÂŸ‚Ú¨/öÇöé”Ö5x§Â°Ğ˜m nE¸§(ßr\è²—‹QMx)Y¿
ZäùQáû‹£¬¡ĞÚªİUA¢¤KÚæc²=ß°…¤@K÷_ƒkƒÀ'æÕÍ®ï¬¥Æü8 hJµ³ç‹XxĞ`áO«™l#ò¬ß–hÌ
ò-â²±uÇÛÜ{şĞ†ŠıËÏ£dUÒMì& ÍØİÌë8ıpÑvBE¨
ğk”l±ª˜ĞZ|X~ v™±„qVzqÈK‡Aôm‰ó7¸7Be&ÑIyf©~iŞ,P+š£ßæAèb¦û  g6³èØœÆ„@RŠIRñÜÉŠĞ“
ƒæ)qJ}æŸ?‰Úíw¦]¢5^?·ÂyÊA·Ü
.¨µÙéëšš¿—E ôwŠü`÷µ(§Ğo+÷êK=ëkÙ‹Â•ğ²k	ÊeGË~şÏ>è¦É‹OûÆÆ;³ è
¸Xj'ªØsĞ-;óc›Ü2à~Ü‘½NK*e3NÙ;œÈºˆÔ^îWÌ¨w€n—pÎ³‚¬ØFòûÃ³†J:M•. ¶#Ù…ğVºàê|èÅfmÔ<Œ°s]Lî¿qÇL(vô¼ª£§ù+”[Š%;ô3ûŠ¾[ŠW¡i­¸)¤ÌÌÿ{$sH†dŒ;]Ğ´¾h•ˆ7	iD¯•Ş¼²Šê’´G¸U“DRWx§Õê6aäØ6£p¹»C˜<KEè°!·Ñ>vgÜÄåù9õö¢Ü¿7qÃ$ˆî)yÄæêğDìp¸õÎ?g9›¨*K¯¯»¹“Ë+¡ıüI,ß~q]–qAƒÄåˆüX™å?+OùÊV¡ Ò~4ñÀÉª<£ò>;|-¾¿m¾ohX Á¼gOZ`7ô”î…b¤tÃÍ.Ø`ÛÄ 6—anB*‰{ì¸ìqSÿ±ŠnËjïînx_ñA6)XÑÑïËÆUÚÅ¼=NK?^Ç(
ÿa¥Xp^¡eÖq—#QÍŞFšTëš™6NÉ™YD{ÍCé9	và/ğ</çË.†•…y›Mz}ÃF4ä¶úö-—¯®Ş²”Ê\›IŸ•†ê"˜ƒË:mnP¹ÕqÃÚº³kgú‡¬=Ô“Ín¸j9óëkWFt2ùé·wö’HğÂáçHv§´=cóÚv4]ğÓP]06óîF4Ãíza3ûA’ëS÷Š€ü¸I¬¹Û åX—…ùõ´†ãõkŞd¥ë´-â±=à˜>ÖXÍ˜¥u°íõZõ‡øë#/¬UwRÆ»J9 ›¢cîGĞPT+”ÃÀ8÷ìÓ‡HéûF7U8>H°Æ'¿^ØŸëÅpÔ`3ólŸÁ\lEKÅn‹gm­¿Ş5¡`5àµÌ® ×F”oªãdßYÍ÷$ºEïÿëRü]ãe¶mş=\‡LÕ¿»hc¨öÿ£ûÈ¯=Ş\çOQhJ@ò\S@a ¤ç¢ÓÈêú-üLë1-…».Ûî>ÇÖÅêäË³[`ÚškĞK?Ãø¾[fø>””ø¯Òšé$’”,Z—”-ï²š§¸dı+Faí‚øÔ){8ëøĞá¸Zˆ‚m¶GÅš(Dƒ&MfÔwƒ„B ˜ÎrÄËŠBŞÊ<f›·¨Ö¢vVéøÖGÕª˜[ÙJà]U$0Åù”ááN	º7 ŠÈLsºÃ˜>Ö8—ƒ>‘Ä3½I2UEO/ë¾êrZØæ´àDMÕdDZ¡à²³G¬Œ1¬àibÉvş"|‚äşŸkGÃ¿Ä â¦BuA˜-3ÚxüÕ2NÛÚ˜Ÿ^]b¤ÂZÅ°§eé	 8¡©2ìùê¾‰¡XòŠv‰“hÖã©YÄ5ı>.PâÜŸ&,r‚ÔbÍk’±uğ¸;À´Ğ™MúVD”s‹­ğØÈ– Şš]h•–ÿşÿÁh”Páe‡’“Jx5½‹d„d×¡K ã¼Î•ö&ZõªdƒI¨ætà¡%yBèş‚ì5©-OÔ}±†`’êäˆ8AIñ.õØ®uâùL,İL0ìëò²ÊÒWº¾1šŠÒˆŒ’°À/‡;‚]33½æ`ÚgøŞnDò(E“xRcèÑhâ4½ŸV©KGå¡äª!%=ÍNí¢Ên ¨BÉ6_²×ñt'¹Î¥’Şàyo=›Ÿ—]–BÁ5ÊÜÎ$yá >¢ãÀ><ÒªŞÍÃ¦RÕŞ|wÿ€x¬y‡ §.±‰cÌû]W—`;#˜"6-uú7…Q¤gŸ¢U:¬ˆîÈÖc:>a'»”ƒĞöŒ_/ÿ­•è;Ôëô|8Læ+Ö¢+­¦Õ€¯O	.‡JõfÅvCı_®¨!è½şHMúÒ¶Vş`~¿º–hÅ_mÏˆw¯e\j Ó l/fû¬ƒ7¯HÓL’b÷cåÅw¿Ø™Wø°ZO:+¾tÿËˆÃ=Vœ¤ù‰&Ü:Ÿ&N®åã‘ğ®‡ˆ­†C²™…ìf›,üÛá‹‹6>—Ÿ·d]ªEr,ªaš ó©¨±p.¾Rbc{cÄçL^ˆï˜ïµ£5ò Qû¢åÆìÒAš”5¼ÿI¯7©5”0ö©M!ôR[RˆšËBËLĞ„¹E{YÂªş¾s, Ÿ0ÉÓà}c$`Ù3òÇ¯˜µx±›YBfäGHÑã¬Äk6ÉÑPK#è|Ë.D,àëBáËFVO‰^­ÔD–B.ì³,\ö!N¸Ş²8Å„nËµµ=	/ß>cvŒWÇÈ}Öëk;=+Ë¼Œg…ùâ€’`]ho¬OôÌÇ¦sñn»Ô:y²Ş¦ûîÅp ±y4ÍÇŞ iıÂÌ4K¨‹«>dĞ’õ¾ØP$‰•EpnÀaeİŸûÜüà|°ì‘üüªÃ©IrN©²„qŸ¢G¼æ#İP$ÂÇñY˜‰ØÙ>ı0Ø[M[|r?JLªMª…MÅ¸PBàÎñ1‡™ÚÈz-á!ø$'XÑn–3:À¨© ñ ¥÷Zt…•õ 4¸ÃC­¸¶ów\¿¸.yb¾Ä®F4{h«ÎåÓ“yO8È£³÷ÇÆvÌÄÀÊİıÁ·•]Sú7ÑXÈÎ˜µ'ZÔ)PP>ïØ“ÕKCGAP,7)²ŞÛ²¾ÚÑ„~[›©0Á^¯Eù ßxÖS(…ÒQ‚9•á¿Š>×€Á…\ÑG¦¨ãnX[_†ÕljK0$¿™\gk/$ênWE`+vn~>8¬Ü»91H_OER 4ìƒöX½yÅõF¬r¬~º¸_ÌO6
­Œ§¶™àÙqÖÛN—SÜKç+9]ú'+0È[7„­Íh\rÂT(>T¼-%A£(®õz6N'é‹\{í[ˆJ@KÍDmbÍ‹<Ò;À¾”ßOwÉ|™üôä¿2öÛ^…=%](­Øñ;u_}„IŞÂ$/x0·2Eu…£Cèò¦áŸ†	O˜Œ£Ş"P–í?n>î‡¡Ò¹7ˆ¶Gd¢½Û0H„2l»ò©C6Œ|ÀLW<*1f°Øö*îd˜à>SœŸÀw¹È[ëÿÄ¶P@¨Yİg_gÔZíhb¯á`£amG`ÛÁÍä¦Úì:ª¸ùÙ¤û¾õCd‰Ào$¼\¨wÕøBe—>fß8îô‘‚gËö'C¶µÆ†"5ÏZveûØÔK¥¾•wqàKé¼Ë Û‰)èİÎG$™N˜£¿´ y­Òù…d_"¢E›¨Ù
B/ü¯ÍçtEx•Ÿ‰ã p$tSØâáBw%8fÃÀ{£IŠª,b}'¾Jwí®döÅ¿­«ÚïÀÚ›w¯?Û*&I•éóBûàæø**Ğm´±b"„7FBÆ;ë	ÊÃ±±—š¢‰‰ÄƒØİ×…œ`ø	hç6€eü	¤G¼>õ{ê³W\÷âNßãª°cÔ.²mÕû*!÷ÿñÏ¦×}ì²H\ì@§}Ğl¿4 pæš²Ğì'Z«Ù†{#•İY?o‹]»ÌÎùšF‹*fí"t¯}íÜåÎ- †]†µˆÅu¬À'ÍG	Ò~x6Gœ2ófïÿÇó&GVôƒÏ³Í*\#¯G³%©‚èG
Gx¶÷¯_ƒ÷>t£’¨ºIMáÓÄ¸€Å@ä„×S»¶Ós§sãXû°ppô¥òEè{QÉÙ+± Ñoó–eÁ„ì[$¸Vy¿¹½ƒš˜Ğ|VïØak€aL÷˜‰N.ø»ê^Ù1x™_ C†h·Ù×ãÕpÑÀÜ,=dÂPüŠo†áî`©íºF×@ 6³BjY„92[óO?ˆYÁ­sû5Á/v¾,È"'ÿÎVÜ4	ş‡%`¬¤Ü¹ÆgE@şZK¨#‚›÷OãİVØÊ|laûE“ñ€I`á\©Ê”ÿ:8à„ÛoP™3œx‚ç=4›Ém‰£H\‚şQ—Î ¼³Ï~]jÍI?Å•ƒËoUÆÑUr?õÕ®vÒó™ÑwÚyòk
+nB¶(Ÿ­Ë”¿D5í‰A<-3%†c&™/tœ†‚AMÿ…4X;n¦­•XM2|Ğ©¤İÜsaØ‹ºÁAÛÛ©Ãã^œcä~{iWïr¾C±ä`¼ùÿL¹Ñ©•I¸zFnYÁ–Ár<Æ„Ulv•xS'áup%Ë 9ugš†×ß ÷UN¡a@A
8±ÊïKò°Üñ©[R«¡ÌdÏı2BWtM´ºQÉ^Õ©^¡BÏàğ&eolÑZôçU~…ÁoT\Ú5ÿCî+®Ğ¥Îwˆ¸i˜sÕ—ÿËô-wüQPåôDì(ÇèÅ÷¼ÊŞÛ„êQ”›j„ÜíédßçWÒTãKï+¤9aÑÃÉdÿ£_jœ}:Áá‰¹Â©¸¹,ïUuO&U‰k2ØÔ¬å©•„ 33(ñ¶ÂŞ®¼3İyİ:r¿¿ÈÿÍ8:ÅL× ”Y$Zr-ÈÌ¾P_é£JŒ)õ¿6´°¨^9ï&}ôe[N´_,v£ ÷óúM2•8uÃ%5–øiËD*“½êŒı-òâ{è…>„sí“Â°|¸2´¿>ÖAüWİ¨!!rÑÆä›ïnÕ	Š6:"š³½Á–[İNu¼yñ]xŠ\ï:ÇÌéı[ÌÁ‘ÉÙx‡‰ï¡/ÁÄÉÚ9üĞœÚwë™e”«ŸÔ0Î'¥Í’yølÖòï·¼-âÑ`»•W/ñÜ&R³=Mÿ„$ı (ŒÑI”ğ–90¥4%/Ğêu´g Ü‹LvWåb‰,gbBU~Çu*M‚ãCÌ¹˜dÔÜ~á’ûiĞ–‡$·Nt1c’vĞY±XÄ—	êÂZ`‚©>¼!±øeiï«Éìá×PÃ³
-V‡ße¹ì #ø¹~œêÛÔ\¬D¥ÈQnîG(Ù¯m~Ÿ´Na{¸ÂÜáèF÷À¨±RÈïÉÉzøõô¿” QÛ×ÏÄççJŸCvq¦ ¹È u´ç¦…waÂĞ%€ì„İ”Ûk4dÜƒ§ûÆÌYzV:ÊÀ§·t Ÿèu•LKyîD
‚wùoMîÈ°íùÅ¨àÈq*Q@òúÁc»@•ù­œü` ‡›!,’w|z*IÈ)	L?Æ9BŞ…6¬8I¸rY*E hî‰%jì^6Áàñ
œëüSëNüÖe¶n™hg˜é]2#<xÁÆƒMİ•Å~µË¹ØóÃ›_Á‰?Î†o!~r€$+¬Q0{=¿ù\Øµ´ZÂzú™‹nÃ¡©öşîŒß™jN™)'¦J>×d7n&†tÅ¸Á>ëÜ}Ï]´íÄ€@º•vÚ7°cEÊùßÂÆó5›âÉâÉOÊ¯…¼™YXáû¡.¸v‹À¯¯’5À‹ÑWT£†MGïøCh=ÿ0oü¾å]…A!5-±§û9w ‘ÜÈëİó2¤Î×w–…/›kScVâ]Ì¦M›ü*ğ~øÜAzÃ‹õóõ P¼î0<³Q[‰Şøi'! *q‡Jæı´dx`¡—xK™r›	p`g'õÁ[™lÎ#¡œÁ„Ì5$r^Æ6Š`¢sÒíÎìKe–»•3©"óàtè; å¿ÖŞ€êÖÑs™ö
v“7§6üŸèºàÅ=:U š¡û2ÒY†âÏ€»Ñ1€4j<÷_<¨ãsÀJ$½Æ]O×³6/™xQijê„Äk=Ã)W¾÷t@QcPò„‚Úö\ß\>|ë±9ŞlÌÆe¡Xí¯a@;zÔ>~µwï.-ì¾7Ä¼W@·àD¸}m èmèv$zÍZ¾6¥lOâ{¨·5	¨5~¨œ¦ò¨“+ç‰ÖêÙ®S]ª;Ó¨ÊÛ¶-½ê*Ëÿ‚hA¨ÓH¤5 ÀñgSŒœ†õƒWí ·¨–åá‘f*-ÕS8¹Qo‘(ò'´¶ñû§~º6Œáı=†Ş[bm'	ŸÏxˆ¦w[,½™¾Ç±øÁáOæqŠ¦…Án,“ÆJ<5ËvøP7r{Ğ“/ØŞe ËÑ7º+/	3ŸÃs× ‘½gÍi4Äß<r]mıBê)Í½!Tÿsõu$”»øÕÿ¤¬ç”­Ò{2}¿· – –°,p¥ä{Åâ4—Ò5Åj¢Ù-Bñ:_Z‹/şx2ÿÉû­ï]^Å™k/8Q£¦Ã«<—şRÀ€_ilM*°Ùy 7“[ù.ØÅşÎèR“¦cÚ($¦g§®#·ã°”q8ÀY5}óN¶k\†/¤DîÚÎı¨‡Ì_r+åZyé×èJR×+ñ*•stê‹ÚV­ªoK˜UZ,ÿ$²ß§ã¿qY”>´±t’ƒ8ÕFÕÀIæËÛµêi>wœAÿâÇšõóè{Ú—©©äğ‹ô@9œĞ~²D‹,›ü¡[‰zµªeóÛ·6¬igö"Íƒ9Í\Sû%syi§D?jÁj°¡ 9<±WµaålZáÃ{z§r½7Âİ9Lß%ãàíó—¡téF_K”ŒùNı‰±Œ’ƒÏºqHŸCÚÛÉN!Ü°Â&Apõ¬gÚkÖ§i)T1·•?†™Q”+%vm×=«XâMçËÎ<âôşÒâ…ê=ÏRğ"øƒÂ…ò±7Q5Ç+ìõàÄ–d›jş4
 Åt±hÙXüE|-ô‡Ãb¼_Kå¶y= [î/%È>—–‹·˜ğu¡8Ûê#‹”)9„›²ùö'ÿå[yd¢äÑ9‰&jÚéÅà»¿ç¼¸Ök˜Á•Õ3¹ÖË®í§yY ŒåÑèÙö;G¼dÀÙ±D§  ³ÓU¥ÔÚ¼c«¯lı±œ²”m†RĞ¡™èä%ÒûÆ ª1yÔuXåªö¹KšØP.’ï=¨©«vŠØÂÈÓÆÅ [ê®>pÿ#9Œ%ÿî?Éìq\º¼âíŞùuÚöXéÒ' ILÛ¡R›·dî@Ã6%£@ ıƒ1Ìy¸ë=§¸ü(X5/›Û;ß‡“#	"»ÿ‘’‰¯$–Ú±ùwŒ!¡È[”¾†ˆiv¨Ÿä40Ãwy½ÍÁ:»ly¾¤ñ{”?fû·Š°~T0«Š­³î•æ«ÔÚÔY uúò±(%C@,ï'š‘Ï*¨¡–éôıNâByF¸_ş¿ÉÊı•¤cÈCÙ‹†‹^¸œ&‹ÌÈEùön"ÃĞAk¶‘­«G/Ø§À®Ü‰t.Êi4bQ
êÍ„œ7Æİ­-3McÀBû+)¾ı%GF†ÖœùÊñ]ÙÑs@/Œ; )Ø3ı·6ZÂ÷kØG}_Wqšv6I¶ñ[ø'±•U,Rƒp3ö,ŠH.à|„Ï”¾VŸ†TÕÃ•VìäÃÎ;è*V3j!Ó7€ŞG	¿¼^Il¹ÿòz¹\1©¹ƒé–‘îÔW,˜$e3Á);UÇãëÖ×¸İ
GäAmá“péXU¢øÜÛa®›
±W¦	Ç¤èXm*•–Ğ¾âÛè`S¼m0Ó›]4^€¥KÄ‰ïl.wï“ÌÅeÕÁÀ¨ÔßŞ
øøï¾*So™	FEÚìwnG$†aƒC”]d=7~FæøäwÆ”ÀrèŒzB‹Ánm§â|>¾Bp•ÂN[IÆÎ|@ÉA†$9:2G>éŒú  ZcÉo1~ß<Üò¾^réÛ©z–¤®õïg-ûêmn¢eÛßâ…C¡ t«ÙI–%€ïÆ¤TxÍˆçV‚{Á–Ö…‰ÀÒ<ˆg;\ a“ztXuwÚA¬a²ü!zÔû=²Şw®òú~'¤uÛU‰„˜}ÀäC=ÎXr£ËyN'«©„Q«Di[>ÇÅÍ²òŞÀj\—ºG‚çŠ=#r"¯JÌR!¨ ˆ¾ùêÿLù:)÷Š‰’]F™Äücşÿ vç<r—@a^}¯7òŒ-&Ï&Õû”R}ó<QTñ²vµßUZxuˆ væ±èÀŸšÙ!+°Ú`–‘Qîuy! =oa¬8æJÄríŒÌ¥ĞÜ¡İĞ¦¾ c8'5-äßé–fÁ®0%_m²ÀŠŞ[<ÏØ¥	ƒz:VPù¦tQÙGÖ´îeµ?åS®í­á>Æ:2#M.âº«’'ñ.ñ¬ÿ¨'È÷Ú |ëï‡C$TúE‰À_t[*¹+0À„@y}´—7¼xÛS"4IKôPv˜_è)6º÷jˆ u2<¨É‡Si/.ßx0CòŞÅ,‘§[W¼CYˆ_+ñŸü²^	’š¿‹Mcßu²_½»™Îyç-·B§œ<ªL|êù¿Tü–Ğ¾p>‘´Õ7Y}eV"ğˆ‘÷Î™Í×Şìşç=ğÁb™äkœà±5‹rê‹¡Q>1Ñf¾E\¿èL“²‡QS«/"Ó%ŸÇ6„Ú¸` ¶×½h‹-ì2QÈ¾7‡ŒQ
S,'NÌ9rÄœ•àr”Ã¶Ÿ‚>·İS Â9èùºˆ$9@ôoÂN«j½:¥—‚ÄÛä«¡rÃ?t·.ó(~¬šGĞN3f˜2i˜5ÀÈsÜ†ÌWŸ‚>†”KŒ¹×1yéæâ0³ùU z9NŒ9áEŞ¯ïşæ#ëA,‹ıµ3Àƒ]‚aúb5–6oWåœ‚V^ã>
‰”nI\/òjÔo~/UH]cµ)ÿ à¥aïñÔ±q-”ÏÂÏ­Z8Î›¿‰IT/c’ÖÇŒùn`^ö‡’Q¿s+<†1Ç$è–üğŠ¤dt¾i£s[!m’4)ÿà6§é\³ÖÀO\eâàao¤Uº%[ôÏªµŒ¨®X~¤
‹áR>å˜´m*¿4Hjê?×‚ÍÈ7@x“êôº?Ê´‹Ûrâ}¬oU+ÀÅÎÛ@Õ>cp6#}Ÿ+‚íâ¨!İCŸR°¥öœE,‹Z]A5Ÿ5, Õ«×rícdœ3	P'RM>QóNĞä©ÂáP™n<|2Å™m‡Ô%ß6P»$, EHt¥@øèÅ¡`CúÿÄt¾¥jãiİº2şŠ²…–Îyÿ$ÒÆáAxD¥h×aJz«ÿÏ?˜ôîÆV3œíü€¼C=²>l¸UÒ‘¾ÊÚüAµÿ²šìW{èÆ7÷eßşô®Â6líäX×—§¶Äi¼qîÑ»ûÍ=³“¼,‰x­~nW¸‘îÓ/°‡~¡?È!ä3Ùn×¢ˆ+9wÁÿ4|õ”˜Ã¨S :O'lçîîØïx®aŠeLîT©ü7zg•3ùq£G‘Ø:TéYÜAš²Š?â,®S[ípÅØİµkäK$;Y
ÁœÜjü†Š<ˆ"ïétÒ†I ¦@‹z&fZf_%ş˜£XB
÷8•È'EÕÖ|Sºßf2íaZœ¸KBhUÆG¼DŞSÅ¿Kkx"ıÙ"ÎŠæ|Z){C"wG|Ê¹R8•‚rÔš¯:ÌdÆ×/@ä!Âœê§"Ğ¹Fâg2Ÿ0k-…Gİd]Ç&Xšx¶4~[Û:]FW‡8BßùäÁ¹û;¸Ÿ«ø·sqh4½Î;X!íèü¥…Ä=xŸ2ÇÃbg~²QÁö¢}Ï½q.	%©Å
/:¹­Š
ò	¦Åˆ]¹”vÙn"|r„«T5?EºM†ÑI˜[&à3Ìf>–{4­Q%®óË6UëAjüÙõ„¥x®ÊÄd/ô×‡³l‹¡B¢øÁxaŞê¾©%
i0[ŞMë.½¢µ}­ÎÍI%TN$dR9XIt@Õ|u|ï¯…ılŸÃF¢KSú‘Tª€EsÂæ‰Z2øó9ƒïqŠÇâ¾à;¯Õæ2"Ãrº=*ËvØÂûÅx/g/şZ`¼$hÙ¼òeTh%Ğzù·‹sfQ±Jfóv0eï¢YŸ !VkRbfzÔtÑ‘D\İ¾¥É-¤µ¾4’…à @îÇWX½Œ¢‹ìra4õÏ{?c<¿‘ÀeöÉL„0¸n',H€sğ•$|´PÊ§—{CUà‚ˆådÉ¤WĞÃÈIC2ø
7ôa )êê€ë=Óù¤CŒW?©ƒ{t¡	YtÂBH¼3®¤Œ8 :ÿ¦	Y¦ØË˜˜ŠR¦çş!¤{·ã›À‘??X@-õÅõ|"…ÓSvÄ4´ìªc¤d=t$c&d_d‚Æ4ı'XFyK|g[só‰ŠL¸8óyä Bkd©Y¤´˜sµæ$ğ½®¾!ìM®)­äR·c+nìLWÌğÛd®­#F0“Ñå^qŠ…FÈCh€ß¥ÉÃ}R­Å¯	Ú¨§â46o™ö6ûj:]ç<½ *×gÓo<Ø±<½Vƒ!T6øädñ~³Ôú™$äqÇ!%‘&kÇGÍ¦mëÙX÷¾¼‰…°¨ºÍ\Ú]µnI { ?*ägıD!âL\OÕh¢·¯ÃI˜GğĞŞ\‚>5¡ı=|É{K¶µM*gdûwÕËØ8ÌÛê²m7	ê¿–o#Ñ€Ózßâ†D ”Şvìˆ2¡îG/¿ñ ”ËskŸö¤Zş6=ÍM`œ}¤[ûÊşß—ŒüÈ¦~€™%ºoqUÜPÜ ÷ûjœí25ãÅ,,áW€,EìP®:7&³;àşÊ[^§vÜäßlüîºÈÚ%Ü&_F!ÜÍ’ş2fÒˆ`ßI,2crÑÛåÑJ-šªz²ûÀ”œ,“Ì÷V7€÷ôyw‚ ]­|¼N/ûÌÑ{Jq]™pÍ…//Ò¥—
È~z4­©<X¼LæQe"äôŒA¡‰ä´ñ'á­IIç´øtéréÓêj[‹£!á†×> ÚGZ«c¢»Pç*K¹cö¡ó¾¡f¹¼ÛÁú¿×}¬°Â¢õLÙéŸjgx%YÉ=i    ,{9w59 ±»€À Ãy±Ägû    YZ