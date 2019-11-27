#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1086234423"
MD5="04da292c51587b82583bf7e8c2d618dc"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="20867"
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
	echo Uncompressed size: 128 KB
	echo Compression: gzip
	echo Date of packaging: Tue Nov 26 21:34:03 -03 2019
	echo Built with Makeself version 2.4.0 on 
	echo Build command was: "/usr/bin/makeself \\
    \"--quiet\" \\
    \"--gzip\" \\
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
	echo COMPRESS=gzip
	echo filesizes=\"$filesizes\"
	echo CRCsum=\"$CRCsum\"
	echo MD5sum=\"$MD5\"
	echo OLDUSIZE=128
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | UnTAR t
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
	    MS_dd "$0" $offset $s | eval "gzip -cd" | tar "$arg1" - "$@"
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
	MS_Printf "About to extract 128 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 128; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (128 KB)" >&2
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
    if MS_dd_Progress "$0" $offset $s | eval "gzip -cd" | ( cd "$tmpdir"; umask $ORIG_UMASK ; UnTAR xp ) 1>/dev/null; then
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
‹ {Äİ]ì<ívÛ6²ù+>J©'qZŠ’í8­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»7úa‰À`0Ì7@×õŸıÓ€ÏÓ'Oğ»ùôICşN>š[Ovnmo6Ÿn=h4›[›È“_à±Ğy`™®{uÜ]ıÿG?uİ1ã…éšsüKö{kûIaÿ7w6HãëşöOõ}b»úÄdgJUûÜŸªR=uí%˜m™%3jÑÀtü<6CcyÔr&¶Ğ`C©¶½(`t—§6u§”´½…A—R}‰ˆ<w—4ê[õ-¥º#vI³¡7Ÿè›æĞBÙ4°ı¡Fg”¨²´«ÄfÄ7ƒx3BïÔ(ş>j¿‚é9PŒÎ L Á&¹Lß§™yQq×!ÍvA”œ:;S¿'zé{@û~çÙé¡ÑH[ƒÃ¡¡Ö«I.f||8wO†£ÖÑ‘±B² ¹Şî:†š¶Ÿ;ãş‹ÎëN;›«s2êÆ£Ş¸óº;ÊšÛ0ËøYkøÜPQ®R5F§C Vª‡¨·:½àªÈwØæ€*öŒ¼!ì[­ÿj_¯×¢’w{¸s®R)'‡Áü£k ju×¹çosvòñQf¶²ÅµÜàÂRÂ\ ä[3õÏÕØå[£ ;„o˜ºØe
4èÂ?°Êm\¥’ğJ¾‡®O=w¼BV‘`±dVu¶Ïèôœ Æìû@ˆ=‹,,èb›£p€SFƒ.B;P T¦fHtNõyàE>ù+™ÔÃâßÛÏD·èRw#Ç‰©®ı‰|cF²›°˜ÊªØ5•Š Ï}à˜sÆ§uéE?H@gã4ó›*€ÂÏÛµŒÚ&ìğôÌBİPZÔZ¢–STNP:M3kã:W»Æ/]OÑê7¤
à`1	=Ë2âÁ`ÆløVO(oº²Œï¼ƒ *d>MQæ4|êÔ>ŞçËd
8ƒ43M¨¬ªa-ıM´K5m¹y¢øv=²èÌŒœpCV¶Ã¼S³‰„O-QÊÚãT©d¯ıií¬}Ï±A^Ø¡˜ÏíÏéŸÓK:%Ô]’ıî°ÔúÕ¨Å?ÈëÖéèyoĞA[ö›|:}‚«¤–³lEöraòÊPv—ĞK;$õz]İ¨i¥~•¸ŠÈ¢BĞâúqÅ|¥±”¢p‘\£¤J%“„D25)+qS,››ÂJº­¼1&vaÚnJ©‚Oœ¬.C=x^XpŸJ%ÓÄX`ÕX ó}uj¢Ìyˆ<¿Uş˜ÁdvFAÊ	Wd¥"›@X '–Ã·¢&m,yğõ³>ş/Úîœ!©U/ÃÏÿïlo¯Íÿ67Ÿâÿ­§;Û_ãÿ/ñyî] MŠÍÙ¤]¥Ò$=<Ğæ<B“•_Q*#Äñ#ú=7l»˜®ã+ùÔRˆ|bt€uœ€—BUÌ/¦ÿuT€pü¹GşßÜÜÜ.èÿv³ñUÿÿ3óÿj•Œw‡ä {Ô!ğQ[ï¸5êbÄö+i÷Nº‡§ƒÎ>™\å£$éEda^qñ¢Â›GaÁÕ÷dÏ¦™$Ä>Yx–=³!'`†ñqJ…õ|Y`5¿÷Í€‰¨NVŠ1á‘_"W©ÊCâŸhšmQÇ^Ø2
˜Lî\æ9eÔ™3˜GH<#³À[€@×tbd¢c:Û%gaè³]]O†ÕmOÿ2E%«ÈYÍ[í­ù+G–_ú¦ËxD{f&L`¼Š2³›3F<Ó¡À™:y«†ıÀ{ÓçuMÉ[ı8°ûj•¿¤ıç%‡³ú³¹óµşÿ%÷Š…WmÙEƒ:;û‚ñ?lööŠÿß|úÕÿ­ÿbı¿©on­«ÿıg ¹ aê¹¡	©áÈ ñmòï€Ì©Kv BÛ¿ˆG­Áñò)ÑI«5h?ßÙÖHËµÏ¶¾cWªé44!FÁøğ?±<2ó§qgZ&q=Òo¬7šX–[~ø{`›K›òb¥¹˜ØXğRx€tĞocİ¹¢ToŠ{h³p<µGi%Øf,¢u—†XfXÈOá€õ¼°úX=Dn‘æuõ1 ¦L,]z18ÀØ	/»îíñaG¶]’cˆ¡HóÇû¤Ìœ*)9ÍŒŒ­z£ŞÈã9a¡†šDdléÖg…È¢§îslÒ‹zhÎ™P‡âñÖ¸1n¨&À2>ê>÷[£ç†ªG,Ğ{‚9TUk&`ÈC Ñ8iõél^D9èuZÃ¡Ş:ñËÎ`ØíñïE–^“Fª×ÅöÈ¥í{-iûÖ%A/v§' É2.Øƒ¦9((ÚÜVÖ•ø«\@bJ3W^Ô+=Büqu87BeX0à‡ ]J^Ç¾'Ş$°çføáŸ Q˜pXtÉS†€DŸf/&şéØSÏ]!xr£¹a¼gfó/â¸Dc·/~uğÇËARC.á÷:öŠ|ÂTñÚø_Iw%LÇ/P]:¯;`v.Îìér{qª¢ÉØ6âJ¹ZËR‰ATuõì¤s‘£Úº©î7×ı–èpı¢H¯TyÆ›'pOÆEò]Z!!ä§çÊ* á
8Yœn48=yARC>ÂQXìÏ±–ÉŠ¶Yohpj
6^…«]¯´}ûV{|“CÅÄ`îöã#Óí£îÉéëñóŞq‡;3!:…å± ¤CÂ<|y2jŞpãX2ãM]Ş«:èc}ş›Z²ºTK§Oåòzu¡7%Øğh#–ëR|jUqĞSÂº•¦<É™c¨­® 	=D<¤CxAeı(€æbòâÅÂ@(&<\QaSãœV°§¼g¦;§Ù¹ıÊBÅn‘HÉº+¬m)Xxô¾â§Ár2ÿ‘Ô–I»:µ‡‘a‚ìõG†ªYˆHì©¤7LûEDEÚƒŞp( Û>@½|Ú"Z{öò ÿrK%‰ğõƒîkw¦"¸PåËÀ•B™Ä-©ŠT²;	’8öNíà¨¤áE¬¢×Š‚ÆObòá7ÛOX¢öûBVÒ½÷ıéå÷‘eçéÜÖˆÃÅk,`ÚóŞÍ	¸H'¼`— Z&í¿&«Oíú¤78nİ¨DX-®Ø*•,±DğÕôØ´Vªı*†è4µß.—³µP•d}ûWä3û
ÈË:¸œY­H´‚"\‰JvYZÁôlg»TîcÈJ¶[Úí{èÉç/‘ü¼v<?X‘ö2ên¨µ÷3î!OE“’d<zÌÑL°”L¬pSîdÆç¶	Ë¥êÇm’|ÇÖá"r$'{.h^nß‹æø6Â¶‰Ü1$›ˆ
²vÛ0s˜ÆÏ</†éseK.Ğ2¼Ğ`Ï£ !•¸½-µIW]Z‡ãƒÍÖÉş ×İÇrT¸ó ãF<	Ys³%ª/Qƒ8»„šÄ%ğöO!'çAàyÅŒ”¾œ·%1…UùòHB¬Ä®~–+•!E1é›ÓssN…Çİï´NFğRÛ~‘$ì¶kÑK~é%	Ií†oj¼ïİÍG¯5P&şZeÿ·¯ÿòkFLÜaµlpeXøöúïöÎjıÿ	´}­ÿşÿ­ÿ.°ô«™ÎÂüë¿$½ ®Åç%Ïzğ€2ßs™=q(¯ír„xĞ›»Ø¨‹ÇÄëÄe%¼®V¯n—~;´ñÌ9¢i(Õ¸’eò»–tIÏçíß(8dĞëÆØŸ9Áo0¯%.a¸ÿB.ç€™h~€û>:Îïgâ¥GµÔ“x(ó*ÓZÀ4Á[“ë ô€úÃ]¶ñålQ‚„pJnŸW’‡¨äg¾{>‚îº&ˆMkÿYèZtÉ¹IˆØn8#‡§Ï†¿GcÃP#6Q¿'­Ñhpm[/©kyÁ4ÿô²s²ßü}Ç½ı¡6vvvàápĞ;íªïDsÀ«¾uòWÙ(Åøï8ŠŸ¥?ij1¥uŞ„40,ñ.’€—1C xZŒÇª\C(–6Íà/‘½ôPƒS1ÿğ¹îyÏ˜d%(¹-*©Êâ'WFäŒ7_}#šEÀÊQßÏŒõKÍË#DU.'¡Kb‘Dì!`å3 [TÓÕÀÃ¶~šf<BšÔj÷ ÖNbPå6H ¤MiŠ’<ÆyŠxzm%? ö[ÄõÈx7©9±µ¸ûÀ©¥J«»Ö¹î;fæjÁôZ«N&‹×q›4À˜°'As¿-§Î<Ş7îp‡ç@.ù^NÔvıGİ(¡Pİ¢Ê—Å*•‡ÚA”ßø³F^À1Şb9§áÃ¡?ş„1Aè<»J×=P¿7%«ƒD‘Ä¶TA³ğ†8‘äDGX„J…qİ8²]j»x‘¹€“3IˆŞ4ŞñD+/<åŠ»QgÒ3šÜƒY_3;¢ S\¬Ğ\P\Ø0<÷C…§ïÍL-qğĞ‚$Ãµ8Ç«)	}*Q%êTBÒb}\­nYXt…^?ğĞùq"à‹–øØ°h¹1(	¦Š¼Ød j13E< U¢Ïx˜Ô@ymÿîÖ­ı£@"÷øÕuÁæ…“ü%¢ÏÓ=ÇHŞH‰'Pï?BxQ 	*«»­Öd¨Òsº”ø]–ÂÒùnK{ë¯®bŸ¼­{c¤Ó¨ÉOàÅ~&dí>äÑHÜ4dÖr$wà(Û™4(ZjP~"Æâ~ßŠ†ù$9#—ÑT
[˜W:àEyf‚®9¶šø2ÇzH—;Nñ{RF(&ŒbÜ¿Ægî"0à ßÃàÇŒ^q1Jµ¥yo&ı‹ÌÀöˆ*¸¦¥7õ"’¿ÔHM ÃÊÌ†"*™½—-ÇI#=q4ê¹ÎU|}[C‰ôU€XY1ÈÃÆ\¸±ãÕ©±(O!»Ğˆk*ñØ1‹]ÆÂ³ ,¹°3ƒØÛ‰Õv÷cÃãŸ[ƒÓ!¾äñì¨#ŒqRHYKE:UŒ3gÍ¤iJu¿¬7Õó²Îx-kz9‘¢2¬ŞÉ£Â`Ïy9|ı1Z\¡›—`Ä	‰HÕãİ|/	  OyôÈ6{öOµëªÄœ7ßİìÙß}·äF?qhzÉ`ö»9Àâ’îf?‰6XWÜAì)–µ.;Ä¹s.‘é»
oGLGŞ¼+%—ş&vÖ†¹}t©jQîàM‰-‚˜”«Pšrê¡¸ä#ô2=]HòÊZùé‰ÚugŞ.î©*ÊµíK·i?¹ğ‚sæ›S3÷Uoğbáp'ƒ‹ë±­l®˜u.fLúOòı`ÎŞº‡àåš³\gïh,emF­Ğ &>e+–xgŒ1íÏ?s=G½ŞÑ0ƒZiâ€'ûÒ©ôÀ;åË 5iSc
!mŒl4rˆb1OûıŞ`dÜ"JªØI.›šÄİÚ#üÚ€Œ_¡iÈT,ÌçŞ½±Rãëb	SÓ»
'½Q÷à×ñÂMqƒà›Â‚"±·î-ò%:3á"»¤L¼Şºëe+ë»§\Áœ½Ãİ»y‘Úğ8#ş=ËÉÙKqÕ<úW,î­Ë_¾›ÍcˆI¶,Ì&ÔFÍØzü¼ch+–\nq%ºéûNúŞCV§ü@_Pë=Â¾ÁF¢”3|ï»e@ÆÂB–/åÜwbá”îIñÂ^PİõVZw¹÷h1oÎn[”‡Ï#ìÌ€¿ÙÍ¤ƒ/¼¹‹zb.¨‘m‰ššz{Zì"|DµsI§¹£7ĞB‘»iHğÂ®4‘Qi<1)÷ñ|òUåğ.cÛI	êNÑeåá`"X½nCãQT±±`@W‡F>nDƒ…íš13AÃDÓ•OV¶o1Ú )s;RpfÛ[…†syÄáèÅŞáixmÏ‹{Âîãš"ÿÕqÛ1+²û¶““ÒËP¿ÔÄÂ=ş/ë½ÖÄ?Q(ï³]¬t²r Øœo	h)"!R¥XŞ8Ï÷L=‹Â¤y%Vù‚^­±˜!jË{}±äĞA@iükOpg/Ï¤7-ûi^íî¾Ö^ìw´XÊ’v.CÊß»y—íßCùxÃKÓ‰¨Q¦ñÇ×š¸[«á[¾@­¶ïákÒF¢çø¶Ò„­w[ããÎÉé¸;ê'	©Na{!;ùî’”ƒn¿´¦AŸÃ…x¼ß¾õúü<¤€€txSÛÕû€ÎÒ÷¢Î¨ã×ç®· ün©i\ëìŠ…t¡ñmÙEí™8ÂBh!°
v)‚ y¡EÄ×ÏÂ…SGC“Ò–©“°Ùéæ"†úåÂù(KgK|vøebù‘{ H‡ÆlÎF„ıMfïÁ¸·áõKHEÅY@êº'](e§ñ„ß7•`”…eM¢Ï°è@‰’)mßc¡8±—¢tÏ±Æywk¨w»duÅceêÏò§E0¹¶¨VÉ‘½Ì² , *÷jy˜USV‚,aØ{si&‘+3e×bß/:vjµë^¿sòD¿qñüFá¾·Î5saALJ>n½õÃº‘›Ÿ;(UMÚBsa@¢˜#íÍAX…ĞÇ)Pâ!˜éñ‚ÿ’‚¥#ÉxÓJ¤U‘JÖ~üüV‡_s’¦‹X{ğõN ,…ü”ll*92?üÃ%0üÿ©$›;—ÀÖ®óÔ2ØlÕ%€0-9ß“W¼%Èß ¡rÇñ‡(“^ğıÇS4)9¡}á¬„1Ç2éÈ{•jÌÚŒO şãÿ¿p@™qg%)ùãG¡IhÅ>‡KK÷/˜÷¥’:ãØøûs¡ñ*Ì0Ã
0á3ğEµD¤.b+yi_œX½á¯CC>C¡¸¶˜·¥^aX"òÃÈqb6ó.Íİa	‡446ãD:Œ©8 x–:n¡œd÷ã£‘ŒàWvÁ÷ƒODó$_5H«"«÷ş;wŠ»êDÁ¢K.N~tõ#ª®”1Å¿Šg(„Ÿ©ğ>”îàñˆºæÊq­ĞÀ™R‹'¿3t&oñ]åµYwZÇÆ:è!XËœJªåÑÏÚ8œ¨%¬Q%ŸCnG»$œœÖH¬w<jr|•0É¼‰Bî^ÊZdÙY¥²š”bTÁÕ‚~]^‰ÿµ„95ŒÏVş©Êg³ †	·ş¦×Ùÿ¶÷mÍmYšóÊú©Æ$µ@€Ô¥IA=”Élóiw·è@"U€Â  R´Zû_öiböe&öaö±ıÇö\2³2«² ¦5*Âf!ï×“'Oóé¹z„Ãwhø4OR\°ÍòÊ$ˆú¢Rw§_ü¯¤Rb”lóËÿëO`=¡]Í‡À|¶Ö/f´(µ|E¿ÜÁq% ¾áeKúå‹«àç( w2ä”k¹œ-ô¨ô¢.bª	bà¿F«ô#š²`IéY\G“FÙO•º‘+®Plåô6İñáŸQ&tü=!I½r7ÆY îb(àğød¡ü—ÑD1•Êe?>š3UˆàöÊÆœï‰Uì{ùÛÃöÉ&ÕÂÜ®b0ííŠá'ádÀ\øµÜà`¦ZÏ/ì“+g:*Û³²ººQ©L‡h|cÊœ´V×í]¡2,R¹7JhniÆyKºËµ³÷XõÙµŞr.Ñ¼œØgN­9ÿ_7¥ÒêVƒ€Ce3
ªêP¡Qº:&Ì	å”ªIƒz< ¢PWñ¢FúÆS‹ÌB7#•q½º^­ËspãÄhMú²%R6’ùH3™ÁE*+ƒÊø"ŸÈâÓÂŒæ!ÑE‘ÜûÙ¨Û™Fj|H×ˆÏZ§EwĞã~‚û½1#–à^’øû*éÆÕIï‚¿{ÑÅEúk:’ßx½lDÃ.~åÆWı^ƒå.ôÂOÿ«Ã„ßûùÿ?Cù¥8]¸N2?«ãä'Bíxù…&mÆgšF[+™Ÿ:I/æªG¹„qW¶Œ\ú°a.«£	ÿ@Uùcœw®ºI@ß¡êöì£ú;Â²èÚ?œpJâ¡LA8,Ã¾ñ)+|mD42ğ‰ò5ş„¿A¯GŸÀ r(”Õ€5+¿~"&„¾Tät¢?dñ£~ˆô(×õz¿F½pD§½é@~Ñ*áO„aÁ/¸¬s÷G“x$ÿ¨bo‚.vq< E+eœàî¾J¿dÒÉÈ1R<Úiiáğâz2>e–tà¯Ãó¨×§A$3FkãYk<·õR·ég6«Ä¤Y#©£/}AÊ_‘Ñ,l	:Si3²Ø—%ÏKõ3˜Qäß¥-ñ©±A6¯©"AYçå\®ÍQŒ8Swƒ3[ItQé¢tV#Q»S»S}—t%«lTëg4PãWî|ˆÿÍZ/Ë_ºMÏÂìBMÍ‘Y…|ÉªôJô©¸ßSÜ>ê¤×‘Ğ©Œ®à\î#2 á$ì™Ç³¾H$‡nŸ7/²ß³SÂiÈë»F€#Üâ
Ì´Ùp·b¶v#Uò«¸â*sC£SeãzëÉ)¨+‰d”[Üò{Š«‹Õ’•¼¾–6¥*ÑF¹‹ˆÀsâsw~k0Q¿Ér[-ë¤©Ù3$E5…Ìˆå9¾ü:/T€ñËŸ©ñÀ±@NŞ‹¦—n<èÄ£IÒô{ôÓ[œX³
*Ël&w)/r§C‘S>+ÃÅ_j 1ëÿÑO†Š$`óÓš BC"FâqD´eøïßï0™hÎºVH˜çÅÄe©>w¾øŒ¾QÉ’%ßÇ3U¡P?º£Kyó±d£tšœO‡=Ö6CÀò}İ0R‹)MzN/	Òï®ü¢AZHçüŞŠ0&ß tÆ9ÙI‡Önn¾•¼¼HÃtfdşàZ eÿWW¤wœÀA4Jm„}»˜ÛÍ –QXÂ\–ÁÊŒºdn»Ïyh¸V€}¤ğÅ‰‰Â“ÁIr/r‰©Tì¬b–ø¨t4ÃêLQ¾vëäd÷à]»8¥çåL¬ïb´€OÆx†Iƒçy<S‹” r:PC8œ¸²{KùT+tÎ–³âo¹{?©ÕÊy¨˜Zíï¿¥~’Ïºå.‘÷· ½·2;r[9Œò6G¶É‘eq¤fÛİ¹QÖÚ~Oå}ß/5ymĞİr²ĞóJ[!ï7²ÒfG™	4tRÍ™r]Á~åLA[fÏÕ¬N;Û3¿Óÿù€gYˆ¥Ÿ«¦JÊ­MÅîf)æ0»w±ÅÄho`fŠ¡7¹yùÒ.W5óöêôS*ÚæÑ¹²Hp»XäRîTG¿·hÄ/İ½³+¿¶sJ·Ûş9R~1%6Â!Æ¹kvÌ
ëDáÂßşÜQ·ÖŠ˜»5hß·£JòÂHàgHo@^#îe9’ó˜­GR«ì€—“°¡iNmÅU¬¡QÂj¬•1 ßlUÁÕ†YÀ}¦]ãõcò’o:Dk|ßœ‚·T²möTM‰šJ%.´>·LH¹·ƒáÇÛÇIVG×f9ÅjJäÕªßÓ›ËF½‚¿R~¼ºœ‰ /F¾€¢b–-Ú^ €%'—¸H¸$˜YlÃÃ|¾tü–/"´q]Zæ–Lõ-½ÅP¢^Ì9–<îg®‘lÈú«ê÷’kl0…N@ºtê×Ö–ªˆJbº3¯49ÒîÒèñAeG†!}”UÂèË?ıøeÙ©3T°å1fí2Så¹8#Ô1‚ExÍò¸œ®¬ÒÖ‡WÛ¾üò¨q¬lÔüzuÍ‡@7î‘iú§'o+/ü?¾¢^¾äÈ?–^¶†WÑ8¢
ş!Ÿ$çïË=®-Å«cñ3¿ö!„5‚¹©Iå4%ş5?!á+_–%Eˆ4|Ã`ê²ŠhVšùeÍÑFŠzY“}15İ²c$I£SÅ+L¹`=/ \¼˜n±½h`ò]­#MùÜÄúYUX6É¨ÅõØBµ¼¢,Ûø\—À9aœÏHö	Jw• è¬ÍÎdÁ•W`^¾Ç«şÒª r–JõÙXj
¾ªò5
ó`\Òîğ….`½¸€‚Cƒš°qÛ8ğc},¬ô”m‡‘9E…ç|*·‘Ë…‹şÛI¯‹g¼Ö—8Î§z)NjÅ{è³±8‡Í³`âJŒJî¥i· ¥Mæ/yš`[§bNşt~+AôW9-Òßjä¿ƒ‘_ÿMFYÙªÓåì×ôÿW_olÔsş¿êş?ğßæá¿]¥øokÕºÿæ@³Ü|Fc’Åv{$vÙØP„Ÿ¤s.¸4ŒØmäê
î|ı]xi÷¼}P.K;HVóu0Ş¼Ò»½Ã×Û{âûíã]4josµoâ~<F“Oå¥úûÖñN«Y^>ß×·Öƒeí2|û¸µwÈQk·ÆµO_ÃAüíöFoèàƒÖ»ãİ™¥&W@²ºG\Ç*“’mX	·ÿzº§ØHÃiV6‚·N:{‡o¾k#ëä×®ÖÜè>^â‘€Ïkih0Bùb2Iì¨nĞıR$^A`i&ù¬ºÀÊÅ†=ß[õ’À]
T°'_h½NĞàÎ”xôW°Wêær/ìö¸9•º=Zw’1§ò–ùD:Ø&Æ.>ß“Ù¹»OğÙ¹'D)ñ…—ANmÄÉ«‰­Êné4@¬…ãÑì3[{v`é+õ3_ôâ01ìÁùâ›—¸·Cù¥-§\!ÉÁã‹ÑZ¡â1â
Ø×å:v›D™h&6g¥İDe‰¼ÒÓd:Â¹.Õ/âé°'â±¨¢Ÿ^®8<ä¹a£ ¸¹|pxĞZvŒ™=d~¹‘¡çÁçƒ½İ`vr‰"A³Òœ±ù¶'í@\]d_¬Ï¡è%ÙW’×’?qúy…ç>x)_&‚‡ÆUı¦‘$O„!;¨şˆj%Z[öX	jÚ\)¯´‘{@ş¹ŒTÖ~Wa­Ë(ÖD³!X-T(}AòÍ•U×üæ›Ì ÀTT¯=İZòØ®½©På¦ö%´®´ü>kµ³ZM|Y5¡îe
¼íãEl–ØsÍR‰ùCù ‡=–Üæû òóvå¯k•?lı¸j#iÁøC.Lóp~A{p:@| Íl«Ò¨Ö·U;ÉÓ	Ks7šiI[¤eÓ>ÚÛ=9iít¶·ÿ‚¥Ê™¡l4Qéäd‰ƒùÚ%«‡m¹œ©’öIZG³œfúTØV‡g¹éÜdR§Išr@‚ñ8¸ÁEªV"÷×Â*¹ ±Ğ)¹ós:eŒM9ıæn¤%™R3g¤NŸ2J™E-ÅÅ‚´İ=øOP©^	“Ò§ Š®IGA‚Dÿü-İCòœ	¥Ò¦èhËCÓ¦sk==iö„u5Ëõ-ı[ï`ØQi(L¸ï›åu*{c*·mXË†K%u\¬„”5ËÚo-+eÌ”‡…Ì3d&Q´^ÂA#¸>Z™tuÓHdw´›ŠMGÀbÒOÒ Æ³çBŞäèÜzÃ` 4ó’¿in ÃNîWrR½TdÀÂãÜ4L˜)Y"srø¹&u¶d–cLí¹^¹üHd0üS œ<÷%YÁH^û
E“²¶ï¦Y™r¹lÍyZSö{éüÙğNİwe›? %~ôÄeA’;*\Zé¦.%PuğéFë‡8#•Íd”0ëêí–eúûëfFë3	=ÖĞÏ9Åİn­)R›eEU"Gj½*›ÏÑ÷5Fï6·\o¿zœ0¥·º!˜lZÆú–âWÖ¶Ô¢Û×c•œÂ`ÇñDN»Øâ`­·„Êæ8÷¬"F!œ(¬+¡!oâíl:	 ¾QØ­ÓÀ2“UäÍê1>Ù®¿G®UÆÓ!ø¢gsúGW0å—ar6lÁuöwµZÅ%ôê›şŸîLD…zRŞ“3:¹“I/Ä:mï,HÁ/Ã‰±;ê9Gx´ä0œça/!Ö…}—g]½ğSÆ5$Uêì]Q©ÀÄ…x¾¯¯!VÆŠ²NzE®ª\I=ØÈvĞÓªÆÃ	ÔüyÌÓÍ#q2¾ˆ’1~ä;î­DÎ¿7Öİt ÈÓ|d‚²&T€I„nç"¶`œGã¸&Iœ<Dúa"ˆ[\†Z°²~ù_¸GÏ#Ô¢Aï#…i„…‡Têõ4¹ÉĞ©µÜD¤IgLÇ–¥r7Azºö–Ø¬Ş¯ı¨â	]…¯?àÒ¹@D$`Ì)0“ó—ßÔE)şó…t±=,(ÎC,”îtD£RÅiXìT$ÜÓöCMÈB¹Î
KKØªú–Š(ºI ÜÔšó3
ºp2×="€MÔb‚†êÁÉÅ¹R¹Å	Ññue:¦Ø¢	š"„½ÕlâlÈP¹ˆ>UúrºÔ:\ó”V'>Ò8LôD%ÙcL*¶½üYK´p
¼%¬àf`‹ô·2ò(?Æ“å,’¼ş‘‰ëš¹£çæ6~bÏ¹À%'»?O7‰@ÒŸ0+1}ypôUüÿÈ5qÿ¾ßğÿóôy#ëÿgıicıáıçÁÿûı¿?uùÿñÍU¾ £Ÿ7Ê×»åÊ]¤şôg9†úÉWòì^CTP†sÍœCç“HV²#·ö['X"ƒæõÂª	5İ˜Æ©İjšŞ¥Ç]GÖJñ=Ïºyäê²ß*2v8â°ßR­I(6‚,k\eUÆ
*&s{SĞĞhCÊğĞ9„9 ü²Nã‘ë\ù³£8	*—ílZıL`ôÁLÂ=0EKù!”ÃîÏ»Cé×‘õ
¬áCD»,=niU9{[³>j¿Ã"7WJ$,WˆEL:åÖ,¡í_Ç+~4Lø¿y€ÌÖ3X0äPJ)Tér*›ÊsHF]>qí'!=âîs-Wèzùšj8ÒlÙ]$?# #YÇ&²É$²×›»êíƒ“¹õbšÙ•Êy™°‚À¶'Ádš0‡MÖÃ)a»í|›ªÊ
©şrÚ¦—9-O&!ŒH3d¡ñëiÔÁaçİé.ïx£Ä×[ê¦i9Ã2´@ÙñUò”É/ÁxüñêCb¾_şå—ÿ»4‰ÏÇ(A9b?5«ãËKÂ“ŠxÈ“VsE”WğU[TàP_«&µ—)ìsëŸÔ —8qšb$ÊÜ*Ğ­‚ U3ª2—/}
FúÔÕ,$_¹#±YÓTÑb‚EI±ôMıVÒ¸%Ë[€*L¹K×2Q¼õKmHF=ÑRbœã7ÂîÇ‰å >8šhéá¾aŞ«y\ÁêßÛ{'­ãƒí“İï[Ú/š¦6¼ğ7Õ0/‹¼CÙÍP¢Î:\kVi­}£{kˆö…C5´éK6¹
GĞšâ¥­äò¥“ÜáÅ8ù_ÓÂR£¡¿õêZuÍ1g4Z­ÎéR·LÍzê<ú$vÂó(€¾¯ÕGáğO;ß	ÙYÁ½—¡/Ì!˜Ñj¡àv_TàÿétÒy»™Æ.»ç3+îRrÄ‚1ã—›†ëfÕÜJ»)á†½'bšĞaÏ)êõGÚk39$Ğ”Í†
n–UÀŞI[[ 2£©üÒÉIæj¨HÃXêIµmÒ×ÄÏ¼B^ïnt^Ã@0½6ª”ú…‚ÀŒšµ³‚jùÈÊ9ĞSìúÂwÕ¦k{Qâè„:©¯Æ\Ãƒ[äãôÂ¡šÔÏ«=Z€ˆkŞáÏNãğijø–Õy¬DO‡_DëµçŞSqˆè{:Ôál¯~®ËW°l†A/"	"Ñ#U¿üK«¹É,ÜÙÆâ0W¨¤&7Ûâóî”Àè;ıI’…£•§ˆ„3ªTFÓñe¨·Ç*áPóÖëéô‘:	':n½$g¿¦ı‰‡A0/‚d‡C¾ÒHHGuÁäCg	Ÿ½™üï™$b®j)$©1¥˜Ü|YIQ±á¬Ô¥*·‚È– j×piŠ2sUR­æ:B}R‡ñ¡R_*Åhní:"± ­'‹M-)
D­ƒó¨Y0ùÙ°=‰G#$3Ri‹ß)¤¾SÚH+µ`˜èüiûûm¶éòËi2]»,@‚Ì5ÖK`îQ¨MM,ëRª-ƒk6Tj´LYq,½p”xòÇNˆo‡(fH2>§Ø—Õd0j.×àÿ¸­ñ^F‡Y;Å_¦{õŞöû’§Ì^ªs¼Ákf±C•…^òÌd™"ÓÌàzJ­Ndï™Ä€[)R8"icçgÿ_–ş¡+Iæ@€<ÛE‹“ÉÛ’¤ôÚÄ'EšJİ?äU7#4¯p–ŒàÜRÏS¨ºe«·_>Èö7b”IV+G[FÍÎkk÷{jûÀÏ£¥)i–yÉÑìéì¡q¶~@H³Ü)‚œlö<”$ËÅïx®lÔQŞÛ}İV÷#Bí}ÇöÇ)'äğI€„·À/°ÜªQNÂ^Œ¨ÿƒp2²ª;âŸÀfĞÖ­çkKí­‚Î?:­k¿åK‚tÚnul˜4•µ¥©ÌÊ:&ÅJF…ªl–Óã½¦,nl–Ù‡¯¢¢™bÏ†viL@Õk‰ê nafö±ao÷Më İjÃèoï·€ñÆ+X¥Òºá0!ª9Œ;äG…PÖašøKıèä¤uTš.sXëşöÁö»ÖqçÍşQñ{ØñmÂmúcÓ/hŒÿ«‹-êË}•ì€Éöfİkj…=ë~/³Nke~·•ÀQqiÙ»åÔ–M®CåõŞLQ´íèÄÏ¬å»pb
Q£ÍxÓåhbÆ)iÆ	J^\P„+!¢Ëw‘ş ‚DšÙ!jUp(ö+’•ãÖ^k»İªU	•!„¢ÄF4êšº+(V?((çÔ¬ÑNq–Òu::´ İİ4-€‚QÕ‚Ê¬1¥Ÿ?ß.ÑŸ53K½—·fJŠüªÊ/íU.pààèÌj¿% „RsàÛú î!¸”áóp–ÊÍà6ÀSÓó“®U¡­(µE±ñêùÃØ¦2hîV5ö™\äXØr“Ù>ìà»¹„`ÁAÔG/‚ÉDÙµˆ'bÕÈEAk"]@™:Ôâ™QùÜÕ“/ò¾ÔƒŞµNø¥ï-2è¢‡†BŞ*ŸXÆ}á2B‡6Ñ\ñ»}à}å„Cö-fñ’¥cfå©JàU¯‡ıX3Ò‡má/óœÉ l¿Åç,ÕÏñÅX,è­yáÔÔ>ÓÏˆj_oLoI´³ã¸XÍ)Mû}œæ±°üògo¨ÕdWŞâËÏã…–Åì;F‰!'?.*ÇWcd>€Íç6š—IYn;‡ªx—Ş­Q·i•¼±ŞÇqÛ~{89G—öóyæù'{½¿­ÈØF©„›†Xl“nğàª8¡+¢°~ ŒzÉšYiuáZ«…ÕZµj2š±â#±ÅpB‡-õÌ16›$ùè…JÂPÂ0ˆQñ2™"CË dæ£Â
áÄ×êÌÇÙıíw»È“luvvZn®‰’@•‹pŒWRãÛ\¯%ãúØüòoã(F­}`2H6QÓ–_0Bİ’qÜ#Ş'Yø8Ù>–,z®ê:;ï÷éêB6S£‰¥Ÿ¡ŸÂŠµ8+Ê`6Ùíš›W0È9b¦‡¶YƒÖ¥6é ²*øB£BhxzíEı;ıƒi.‡A¿!VàîÑáx<MVõÊ&ıu÷Hò¹Æà5}:ü9Y‰õ`˜ƒ˜‰ÏŒ£+7åÁÎw‹­èŒ¤Ø±Zm¿ë¶ƒ±E»…ÙXT·škøY·ß¦
Å•ŠP›ô ÅéÍñ´€Òxó77aÏœ+¤!ôœckaÏ,¹2?Og“Ád¹RáÓ;ùÅ4;»° ¥°: O0YN¶ûFùê¡VWD{÷İîÁ	P/Ò"İÆïjŠ¼zó†$óA\6'H]%ÁTş)Œ—Ú0š»tÆ^ä0+ÑmRPÍ+ÊûC‚+Ÿ‘Hş£€ ç$èÓÏëş¸ñ´Ú¨>õ]‰´XİùöúÕË8¾ì‡Uà iVbœ ŞŸ*Y£Va>%Ãğ7ıâ´şrCc‚¹:©iôQL¹só·¡—¥ÕaWÒ§éÚ´º éK6,eIR‰ärpSîüù|!÷JéRwğŞÒ\}ÿ&ª°=`½A`ïfÄŠß©o_R‘¸á^˜9[Ño† 0‹éÍ•õCäô¯ƒhòDßÆğ©ëÌ—İ*(.B ©SWdÁX8TÅe’!º4†€l9":°0côaŠe	S;-Çß¥æô•Ğ1Swš+c¶R7aØ¾İ®}³{ü{ìkÆÔöóa¿—’wC¬ mïÈÆwğ›<tK¿æw€9ÑÈ÷½kø…ÙÈw@’'Ç»YÓ¯Ow÷$ÂlaÁá' œII¼üÓÚn:è§8çÄ'8|g.uéy0¯
+­˜—8'~ M½h†`ô±CÈ/¨‰4g´$›¸¿{`XÚubñ ÅÉÍ%ïšØØúˆÂIXÏÃ‹˜TÇé]:h^šÕNŠ«Ñ¼R.JbNóXnË;ĞEóÈÏ³J ²ªu•—JŒ•_Kı$s!-vnÒ dt^½ÍåfF†”Ğm¾AÄTTO:<lgF/n•i$ĞõÄÜÎÍNÁ/Iê¡{‰úİ4qVïFH-Rªˆ©ş{-©‡{a	rÃQÀfx¦<%±WMO}ó—A&½î3n1ÒÆ/Uú¤ZO/Uİ“:xb»o<í.·Ñ† 4ïWÚ[a;Îeû7d±"Uš0OÂY Ç8TV.”%£€‘ëaã‘.Z§c¼×Ë¿	=0vÕ—Ì¶â¢¤ËMÏ²…dÔúé®˜Mc9µÊ…¿ßîÀÄ\§ÏÍôST»97_«4åS–g¶{½mæI,”ÏG¼1j‡‰ˆ×AYÖÅqañ„uÅ0ß¢²“CZúr™êS¬şö:cŠ"áYõp½‚1*ã¸´ûµ.¯CKß¾¬Šä—SÆ÷"Dka”3$"Œ	]¥²â›ÅAÍ“v.¤igh}A‰MÄˆºğ÷ª(™ „¼€åËŠ¯Â¾QAb« ô¦
b`lº<KÍY•/r(cÙ¡#‚—WVSNØK6+€ı%IAÈ¨£½Gµ³ªFK‹©9QÜ`Ó]ª×è:Â„/Ğu‘º¦°ıßĞ˜ã¢ ˜{ÿD`æ‚~ôs —˜ª·”s¤áÏŒI…bm8`ü G»{9÷šÅöH¬Ø`]Rl x@ı}	kA¥%tÈ1	¥)H‚s@H¨şVP­÷º‚S9vFù†Gz;Æü•2UÚoªÃj9‘$O ²ŞGº¿ü[¾·ğÇğlH«}L`Oá˜=bâ0D†6ÅEğ3¼Ã“²	(«ÉÙ[C{’, ³ŞYë¬eL¸Ò®.˜[” 9ic˜VE·kËF¦-·lÌ†ºŸêÚêgâyg˜9£ÚYÙŠØ6ú£Ü}Ø»ÊöïlÀÂ2¡ÓÑ)Öb"Ñù•SñpÙÙi2Š]òÅÉöš“ÈŒï5Àşü¬Îˆ/¬+w$1!Ê,É™^o9ßŞ™ĞÔ’Ì¤;‰-4Iü-¡ötF¥`tymWCFšìI‚ÿ»&]Zzì5El+….àSäÛªN õ]vwHï£È!ŒÒ‘İŞy=‰O{á•G.š„8‹{ñ¥TdMµ}¯‡áXt¥å[Z„g³”jx<´]‘·;1‘´}Ù-ÙÎ”˜ëªßší2ÒJB¨Ì	'5CÃ¸ç,ôÅù½ÿòœ r/ølcué÷Àf˜2lgÚŠÙÍàÜ_ƒ•Ì2[§7(Ï‰İ/we©S©]â;EÍCÉİ³‚‰µ’nCÛ¶û Ö‡ó,ú]šKÀe¡”b)©7“râ+¬V½™Fõ…Ù=ÉØÚ“©j‘ã¨™éìNœßâô°ığÉ÷[ª¹–äéŸépz)ˆ/›*«ˆ£uSÃq|ùØ¥°ÈBğº“qÿ¢êÒ:5kÓ¿æÏWy0,=rÙMÁøØ€ÔıÉâMU`Ğ6p¾™ºBèŒ0›Êeìíí¾Ù=él¿92:û‡;-¸‚— ÑA"àxæËµ<Rs`•›’u½7°•ŒË›z©SãÚ¬!¥ø<JÌH|AoŒô9Ft‡YÈKy”9%²#w¯µ°RŞnƒ Z+ÜÖÛp†¤S„6ÌyÙs0wÒ±Rıe%d©PØÊîJvÂ‹Y(e$‚.é¢(ÁAÁ8
PÙœ Ò;ò[\„y8¹,!Îª]CQE”waŞîa;Ñõ@2‰¤¨tÆA–9Æ¼‚SËy@æYêué&9Š“Éé–0wŠ¸Î/wÄ«LÊÓúáoâÿçùÓ§øoø½‘óÿ³öôÿíÿí¶øoEş~ºN7^îâ&O¯³êcs±©ÔÔ®¯¯«WÑU³>d¯k=¸KÔÚèö§ÂµU¾R–+ĞŞ¸¢½ã¯„
ÇÈgêI+mÏÊªĞ"‚îlÃ+˜Ÿ@û÷[G{!O‰"*ìüpx¼Ó~OŸoğ›8eÌY˜¢ÂĞ¸ã3BÛuCÿ¦—RTï•+A0ŠĞTª"[aë’½ÿøŠ2Òñª<:/óÚúE4›¢òXühè‘B?-0—ÀëT~ÀYl\*™¡‰4Øòë .•·¢hH…¾xÊ­rTk·¯…ó¨zfĞ*àC{rœ|eüO ùÏrøŸOôÿşßÿsİ…ÿyò!D§¬éJ_Ôy’X'Ær¹À%_Çå[*"(ÚãÊËIRÅ‹AzIUH†ÊÛ MO%ıº§!ö¼IGÄE4N&„%µn€8ì¾E+õƒtò«%šÃx]ÜT)}ÕÓâ‡&»É*j¯‘’.À<¼By2İ%ÿg*ÆğW=Í)Kq´¡Á&=¥ãíİ¿ŠC±½ÿz·upÒâÉòÔ-+pdõÌ{iGHjq¿ÑÌ*ïvŞy×ÙÙ>ÙFÛƒvÓpß»i8âå€œZˆé{NÁ€O[$ùCkïºÏƒifŸ~_ì•í”(Øk¢äŸMÎ&Gñu8&Õ`…}qØ‡4Jş9 ”ŞªÇ-`QGûèˆê>›<–°k dpJPQ¢ş¬º¶!öNÚ¹ˆÙ~Ş‡å‘ÎP*š †\„½=>„Er°Óô/‡ˆ°ª¢¥ù?¾HzzD­PùXg„:@¯škfíÌ~‘ò÷¿CÑî3;<‡ë·|1ê.›)\è{”
8¬Ÿ—õXä‘‹ µÀÈ}GKr¶¿;9<‚}ù©w‰LÙ¸‚2x•|1­³ M|RO†“jwT§ƒ	°ÎiRôd½Şxá9 SÌâ6- /Ü¢‡Ù —ÒÉîjƒ4€UüØœ¤²±¾¾şüÏØ¬DI|R›)4Y;×1‹ªæ¸şâÜÌu»¶(½î!Áéå~‘ûôâYçÙF®mds×ÌÚ&jVÀ”;-UëÕºïeÌtfiÛÌÆ_/Õ¼2{ÖL&2¯˜…T×Ê¤n­ìærã9&[æÌsYõ
QwĞÕYe	Ô:¦[³tö…çĞ?5ÕO·f)æcnÎ„_©aıdUUûVFİŞ®£H}f7ÔÏÙ	³;W™×9êC…·NÅig ©vdûi1;2k7P k'`÷hÆPšÈ )m¸Œ&¦çD~ŒĞõL0Y„‰ò¼EJˆO@yÆ©jÂ·g#š6¢‚®³»ÓR©f@Â£Å4>R+‰Åb ºæã²ğ¸iÃùd•h´r'¼">íhÿv'h6RÒÅ"ëŠádtC³ph*€A«Åù¾ì·N;»'­}+½›Ïª#|«"å„Ä(ª
,íÇIôKN­&aÕ:Q;\>>6—9zÙ3ª­‘¿$)>[g~ ¼hÓ­+«ciÏ­@]Ç-{†­yº¾¤äj0BÏÈCZCüQ4éÇ›"\tÂ¤Æ‘°‰&T¤ÎVñ¥)«p¯®~úÙ÷L[s8:n›57óJĞ#Œ“{!Uy0}ï¸µ½G¥JÚoÖS‡A_&­ÉÓR4E–¥GjOyQÌ™1ê)t+ràCÍ‰œV±œ“p=ËF7}åVÀO_ÃíœµÚYµÖù"JL¿ğQÉ%Îä$FwOËÕezë<ñ9ü<ƒßçèÙTDC¸âMĞëUˆÎRLê¹±}ŒQ½V/Æa8
 OŸ‚j²©µIp™Ô²Í…ÏzpL9p¼ÕîÅ¥Å=ß"yÆÔiJ½äõ	è¼ScÜJ–V@Ã¨w^`ŠUGIz&±DœL*	?¨„zõE•r.y­[œ0µòø°İîlïëë‚É},“«%Ö¨Æ‡xúP¯òâÍÑ©âŸPÃúPsSÊ˜ˆ¸şJ®Çûß¾õÑg<j	À^®¾P·Ç£ãÖÛİ?7ñ>»¼ê•Œ¦azgãnh-Ô¾‚öÀ¸óœaÍ*>±áœj¢½T¯Wñ³ñ|LÅ©wÎÇQï(çäb$ƒ8¤ƒEUû£€ÏpSá—İ
ÃåºÎo¤Ëe—°¦}¬ù÷Õdù3MÅwjğoÙ^tî"M¥«úõ»jãE·¯—€ñİ¹ÿÁÆ±tÜz×ú³ø~ûx©GÛó~8îXl…!–8‚Š|r£/s¢‰ÊÅzŞ8=î+-Ñù§z½Ò¯€ß;¿œ|b¥ÁÅc}:Ÿ^İ ÇõöÈe\Oc?M’‰ú&˜ËİŠª	ÏËşt²~Q¸ï¥0´M§ˆĞ&’éùÅ ø
^à¨Ñ!`ĞÊÀĞÓá8ue`Î=è‹Kø¼UBììbÕsÏ)	†sz—¬}RÈaÃ¿×dúd/º>’$x1Œ‡ì¯/« eÇ=Dúıû=¯P‡É­é¢å/.ç*™H·ÒÏÉ.,±¶wáfï¹àQŠ|9¬¥B8íT[ó¼]Òûh@Ó…s÷ÊõÿHa„œï08*Õ?ÔFã—bõ§Rä‰DÃBéÊµOpˆo[ĞÌãö½H‹eÙwë"Ÿ•v7çuÑäšæœÙË_ñĞVÜ²deüÿfÙ94ºı…*éjN•ÒóR]Ñt.ÛŠˆÛçã`÷ ûÑ' øëÈõå
s}9®@NÌ‘p¹}Sk(Û7¥ä]Viñç ­ü¦Ÿo{ÖYÈò‹ålÔP¾zİ¢|
ñƒCîj»Qİ@áªMnN²©ûİdŸÒ¡g
Öv<åÔSDd05auN`­³Aß-½&•´ş±±F/ğ7ômÀ_ êFlÑ‰¬ğ€î ošJ½Cù‘±üÒÔçÖ4ÒÖ,#u¯üGü…ÔAâ©;ÊÒØó<cÉÍp|Úä'[íálÃÙ°ôíê}@Ø‚É©u==|î´¾¼G™(® Í|Š^›uì¦zBJØõ¦UÌü§ñéYÍ²{J±3
“¿ÿ»ª%ß'n¶©2SXc®ãéPC
 2¦|Îûû¿Î¯ÎP¿)ªï$?M“‰Ví¥j/”F¦X!œ0|OGÈH§Ø¬à*ˆúøN€[ßRš=ÒĞ>p°ãş€µ`ù¬zTTË1i)™ 	
%úBqjÕL•ÃÅYİ€Nèt<›+ó[ÛhÎ2l£*L‡Nã³ÿ°øÌ& %cqÈ{e3³W²m¹gl<·ò–Şß¶OŒÔR©KGœî¿ng7k nlÍ\KĞƒ³b­ZV­«Êğ­Qvlx6LûrO°]7wıïÿ.^ßhĞ\Şr¾Ø@í: ¯4>MH‹d¤½S<‘T*‰¡ñ9 tÂ¸1Bzœ+Ş#5ÚÿW±{©Ğ}0oÌì´	Qo+5·;)w«Áñ8Wÿ×²7øºú¿õõ§Ïóú¿ëÏô¿ô¿æèİYÌXêwÓcÕşDÂğ8?“Š1i}}_~À’/¯p‹>İ£çh¼­ÍŠü\÷Yªğø‹ç1ßªpË]Ù,]R‘›+	êPãŒ,’Çrå½h«Ğaª{'•°‡º‹æ¥,‹ÿd…^©c]õÛ)®õÄóLŒĞ¾#“şš6è¨´ğÏ	;ÊÙeíÏE‚Ë¨ÛA`Rh@B‹ÒšĞ¡$\Z*Õ)$óæIf8ã9QZ§P«åv#‹waO)Lª™Àïgú·ÖĞç„Š¥ÔæzG>k+uÓSÚNÃ…¨ÓQç¹‡ZçiÏßg±›ü²™Õá›b`YT«Ua§•¼¢2¾²clQÒˆl0™i½a=¥6<¦¥—4§_&Í•2úÜ³Qó0"‡`Urhp›DiˆÍòå©üäªxéóêå;lz_d§œİšØ”›@	yGÅ—{/cÙDİLçÇ°C +èpq£ÒbO@@ğ¦ëê “¹¼8e³¨Í²ÂW0ÚOvÁşÑQÓÄ,PE}©FİOÏ$ˆŠÔÉ	y(Õª‡mªÛò|Ë@³?•ä"o-šñ{"ì2D‰t.”’Ä¹‘Oa	v\G+2ú–]»ÙS£‚†+;Ğj·ƒÓI´„ó~¨FÂíMJU`ºx³ ]I€/o(dDò çQ¥ÿ´a„Öƒ×¼3•eİR‰H;)¢0Æ5İ!Ò­µOÑñ¦ã©]pZûï'?sÁ$ÉeˆfÂ/˜]oOÃí8'úÛ¬'sx;öqCŞºú œ„øß¢¼¬	ªa'qH—Úßlwjƒ¯”umXk†*C”H*"µ{æøÌ–K¨"gÅ²ÍÌ%.OŒCZşpZè‰ øåÿôv˜À?&³Şq0Ç¿¶PğĞ54ğ¨2É‰89·áÑ£Ô3œ±¯¾ih„,
oé]T’îô¢¬o•¸‘(N›Ğ£å\FQÀ"—±5FgÃœU›ªëœyÜÑ}¸O—5ŞÈßvq<eİxg!¹%lzLª¡SÙ÷tÅÚã½lÿĞI¨~oIì}/‚¸ûlÕ^õOø½,îÿRb#.@»¼Mú!âªéR‰Bi£oÏô°•Úg;(æ÷0õMEK¼Îî¢ÕCİö;wR¤g¶B{ÈÙ­oéşb•é¥¿Å€’–e7†e¸á×)i~ødzP]ZbÃ½b^L”Ã-Kîç†féü¸¬,ğòƒj½E<§8´jéh*Õ
Æı-=ø.Ğ‘”kE¾KE‡UeUÀzóxõæé8Ú
yé±ıÎ‡¿ıMız6P2®‡“V±•ñäº.±`ÏâúdŠ§2R0]£ÈY~cE¹!Ê¢ü,ë®ˆ»c'Æ®O!p´»Á(LÚ“1ê]•Œ"ƒ1‰ /¦}’L‡xCr e1zBzäIÜuvÈíËi W`-(Š-]4rÊ/m[™ak˜_K›©&z@,‘{‹©œæ‹fvÁumÍ‡ë’2iÜwlyO“L›¸Ş½Hb…—¨£ØOC¢L£äê©fá\=ÍâÅØít5ÀÀQÉÒR'1-¤¦Nr*iv}Ëe$Ü-R$·‹¹lf`Û¯Ì;	ÓuF3ÖNÈœŠ|Ù‹H¬N¾Ü,‚vDÃáÁÆÿM{¡;Á/Lw³[¯¼j—÷ÜXiv_ÔL—X02ş=¶½´DW,¼ÍµáuZVI¨i³¶È8œ I'­ÕGå?" ı9bèÃK„º
ú@(hJ‡j¯ßxà½9åPRù¾ÒØ¯úÌ(HªSâƒ˜¿*ò4¡‰N
¹Û„Xsù»Ch4PñÈàse1»­ë¡Ü0	ºŞïAş_­õânRûMë˜ƒÿ‚ÿ2ï?õú³Æ?ˆ§ï?_kşá8¯ıæÿùúÓ‡ùÿÊóo>§Íù__[¯gß×ëø_gşÏ||ä¡;^V,Œ™êÉ·6$Äáã³ªØ^Šú_ª ÜØ|âUªİ/Cß«¶¿Ûû-ÏVÕ8ÓI'qFyˆ²´wÚ»mÏnÍùØ3Pp0ûû³‹×,):»8ş‘~Â¡?Ûøs/œãJäLÃåRšLÄ8}|YQV}·Ò­:«œ1#˜aÖĞ
OïWV°q±ÂI»‡ºc·Ój¿9Ş¥Æz’ªhÕıhÈŞŸô£¡Ø>:y‚sÈU¼ eµ[èGo¢aJûÓ¦²rª³¢%J+eŸ¬!Äì©*Ç×ËŒ—ü¼ŠP×”X¾—J!–trh‘©G“ãg¹fët™yåà
ªŠ”©HNÁf2kÊ0m™‡çóLM(äúSN«.u/?C©®™Ju4`,WÃf¯P9ò?şíoïe‚…jRVˆƒÆö¨®‘XgK…ã]…B¥ªuM*h¹6«CC«²ˆ†–\Ö¼åÄiÂ+!Ã°kN¢p‚á »m)ïÍlÑAW÷İx
BÄ4•¬ü*·jàŞ@›Î½®Ì¬¶8SÚ­•ù¨cØövYõÄpmÑ¦¨5>N›‰Â€€º‡II´+Ğ–å‰H\îF@™(5ĞÆ"AŸpı¢İvzòíá±—…fYéQ@'îÔÿéC<‹`MËW=ïşıwø'ù¿n?€µÒÕÊ>ƒŞWÃ[kläù¿§ÏëüßWÑÿoxêƒ¾>>áø~;BbîÒ›pÕ#8â5Z &À0ŒÑXOK	]wŞë 
'2×l6½—qÿ•·ô²½zˆãğÂ‰nÁ¤JQ*Âª¥²¢ÀbÜa ÿdÿJìH/½/kÁ+æVÈ’Q?ûèñİC¾ûKöh“ì9á}4‘8^ıÊ°'/k0h<tïbz¡ÛbÔO3ÒÂ!NR8 /,VŸf¡$9ÃËÎŠ×úDGšÖ«é.V•K6yGãğ•ğNbÍ²pØ„¦$“q<¼|•­VC‚óñ«yåh³Ušb®Ä»Ó]“ÃÒå¾L¦£Wuø	^Ö Š¹-Qjñ/ÃÁ+ó•ãe<ÙJËòAh_bÒ±¤ÅÍ!¨»4•+‚MÛªö#UOŒÖæÌ²U‘g¶¤83»GšM£ÊtqÌ³é¤K˜8J%ÔøÙjÜ¥ßÄFÉ³-~…Ö<l\ØŞ¯ó_ùF3Lî÷ôŸ{şo¬åğ_7Ö7ÖÎÿ¯sş[B‚c^-`×‘K
ÎãéDÃkqÒ‡Çm}>½d/Zõ¼+RÌ†b'ì†ƒópüD^>Z¾Ûı õC{Ó<¦È#Ğ)¦¶èlQÄÔ“Ç‘-(ìâ‰`T#3’ıV2#”p‚pqÌˆ]TvéM»ø’PÏô,6‰æXHË@|¦£jòAÒm£Y†JÕĞ¤>™öbôà$¦ÛYb¦;¥Ïƒ"“¨Æ@p&%è¤jf•À™õ5¤vÃøZ´•€XÁİ¼Iä9?í|W¯¯>RüAFXÿÛİ?·v
&€b‰b*şèbÔ|DåB*ÇE½æFâmô	ÆP)¦‘7gw&ê+°¥´––HöjÔì%$Ò¯äêjÀê:®ÃÿÚáhBkL¼(Ze³zi,¥Óã=s”rÕmO/ñ©ÿá«İ_A)Õµ¢¹a-$KB¥Ğñ©ùD¬œM§˜`¨C3Õ_Ğÿ
.¹B¡ÆŒ¹Aİ7ÙAÎÓ&‚!– Ô¸L5O©™Í;ã$’$"E3—Å-^s‰¨JÏZ]0˜X9•äeô! ¾¾ta ‡œïüŒÖ½ó„B1+ÔŠU³}<#o50 ÔDI…DVØãÁ™‘œŠT”£Ûíãı«ç59ß·Ëµ9ò™¯aF°PõÍŞ®ØGz—a’¥oÆ¢U¹Hœœ²zÇšÕ³Vôí—6³9Ñ®y¦ÔÇ¬¦&àöG`¸éd¹ÖÂÌĞ~päÔX	/…SÖ.¢6Æ-î×ÔÇ† únb×,¸âìànÃ}Y°Ò©ùFŸ,öãô÷t¨O1Y qĞ2v!8Ç%z"$ÀñÀª…çANö_œÿ‡-{ß\ÿâüÿúóçş¿ÑxşğşûUş=~üÍğ<m™ÿ7YĞ•ú*
ãáWäóäÿoİ+Ô“ğ"E¦şÇ=ïñc|F†/$ÅJ@÷tĞÀ~™ñÌ¬ÊàË>Ÿ «‡çùe¼±EÒ{›–XÑ»›¦Ó?¦1ò.šYÛó‰4§~r5šcDkÑJ™S‡~¾7¶èÌY‚ñè.ßWóİÊL—ñÖmÏ˜üwŸïß™pâj~Í¸êƒ|Œ¿âŠgNëÅü‡Ì(ÉE²xÙÉ7Ó<¶Ï,(³RAU),ĞZy “ôm¾¨ ÇÒT8//öE%¹Ö0§™ñŒ/$:-%.|Ë«+ßzŞ¿-µn ³kJ ltÌÂŒHXªˆ3MÑÚv°Ò˜EHï¬@ ìA)ı 'ùùã§”TeÆtîYÿÀ½äÚ<FE#;o-•…¢ÌÎ]Ø¥Ñà^­¨ãÀƒ|{E©é Uæé:pHVIß*•-rú¤ÉÿÇ0èÑç3© ÷¯óŞÿ×gßÿŸ66Öøÿ¯#ÿ?œĞî£©‡SùŸ§á˜U&¢¤$üp‡vÉG¥7ß Ï»Aò~¼ˆûıøE
c(-’¥é·Ç¸/&7£°éïúJHqˆğW$(‚¾X!NC[&®B¢%Û@îEuà¼ŸK½Úqk{g¿ËŞ¥È¥Ê¤K@è@Q7‚"nRs;K(ÿ&/ï¦æêä¦Î¨G& ‘a‘‹ŒjBÊù_	ôŸIçQŒ*D¿ûÿiç»bÛ|a>”­F¹’R{X!.J„ê}¬¼¨Àÿµ±§U$ŠX´Ø&À†EË¾uu‰ÿwñ÷µŠ=%Ñ“l¯ •dÑñÕ¿Gxôğ=]¨	YÙåq’Ü$èÛ8Qé q &Ñ“(¢µEÑ&æŞ,'Ö‘Ä}4kMF0%râÒãMBCi<1ÙàZUDĞFßl´Mİ@ ”ô+ÃÈ?m)cÄç7Xm-ÑÓk£®w!íÕ*$lÀ{j…ŠŠ^©,	zZÈ	‰U‹Rsåù*ôş=ü{ø÷ğïáßÃ¿ÿÄÿş?ŠQ¹ h 