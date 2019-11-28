#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2842469815"
MD5="549faa7f27304695688b75f7b688ae20"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21409"
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
	echo Uncompressed size: 132 KB
	echo Compression: gzip
	echo Date of packaging: Wed Nov 27 23:40:22 -03 2019
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
	echo OLDUSIZE=132
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
	MS_Printf "About to extract 132 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 132; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (132 KB)" >&2
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
‹ –3ß]ì<ívÛ6²ù+>J©'qZŠ’í8­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»7úa‰À`0Ì7@×õŸıÓ€ÏÓ'Oğ»ùôICşN>š[Ovîl5w6w4šÍ­äÉƒ/ğ‰Xh„<°L×½ºî®şÿ£Ÿºî˜‹‹ñÂtÍ9ş%û¿½µı¤°ÿ›;›ÛHãëşöOõ}b»úÄdgJUûÜŸªR=uí%˜m™%3jÑÀtü<6CcyÔr&¶Ğ`C©¶½(`t—§6u§”´½…A—R}‰ˆ<w—4ê[õ-¥º#vI³¡7Ÿè›æĞBÙ4°ı¡Fg”¨²´«ÄfÄ7ƒx3BïÔ(ş>j¿‚é9PŒÎ L Á&¹Lß§™yQq×!ÍvA”œ:;S¿'zé{@û~çÙé¡ÑH[ƒÃ¡¡Ö«I.f||8wO†£ÖÑ‘±B² ¹Şî:†š¶Ÿ;ãş‹ÎëN;›«s2êÆ£Ş¸óº;ÊšÛ0ËøYkøÜPQ®R5F§C Vª‡¨·:½àªÈwØæ€*öŒ¼!ì[­ÿj_¯×¢’w{¸s®R)'‡Áü£k ju×¹çosvòñQf¶²ÅµÜàÂRÂ\ ä[3õÏÕØå[£ ;„o˜ºØe
4èÂ?°Êm\¥’ğJ¾‡®O=w¼BV‘`±dVu¶Ïèôœ Æìû@ˆ=‹,,èb›£p€SFƒ.B;P T¦fHtNõyàE>ù+™ÔÃâßÛÏD·èRw#Ç‰©®ı‰|cF²›°˜ÊªØ5•Š Ï}à˜sÆ§uéE?H@gã4ó›*€ÂÏÛµŒÚ&ìğôÌBİPZÔZ¢–STNP:M3kã:W»Æ/]OÑê7¤
à`1	=Ë2âÁ`ÆløVO(oº²Œï¼ƒ *d>MQæ4|êÔ>ŞçËd
8ƒ43M¨¬ªa-ıM´K5m¹y¢øv=²èÌŒœpCV¶Ã¼S³‰„O-QÊÚãT©d¯ıií¬}Ï±A^Ø¡˜ÏíÏéŸÓK:%Ô]’ıî°ÔúÕ¨Å?ÈëÖéèyoĞA[ö›|:}‚«¤–³lEöraòÊPv—ĞK;$õz]İ¨i¥~•¸ŠÈ¢BĞâúqÅ|¥±”¢p‘\£¤J%“„D25)+qS,››ÂJº­¼1&vaÚnJ©‚Oœ¬.C=x^XpŸJ%ÓÄX`ÕX ó}uj¢Ìyˆ<¿Uş˜ÁdvFAÊ	Wd¥"›@X '–Ã·¢&m,yğõ³>ş/Úîœ!©U/ÃÏÿïlo¯Íÿ67Ÿâÿ­§O_ãÿ/ñyî] MŠÍÙ¤]¥Ò$=<Ğæ<B“•_Q*#Äñ#ú=7l»˜®ã+ùÔRˆ|bt€uœ€—BUÌ/¦ÿuT€pü¹GşßÜ„d?¯ÿÛÍæWıÿÏÌÿ«U2zŞ’ƒîQ‡À7Dm½ãÖ¨‹Û¯¤İ;9è:ûdr•’`¤‘…yÅm^Ä‹Bsl…Wß“	<›.d’ûdáYöÌ†œ‚ÆÇM(q<ÖóeÕüŞ7&¢:Y)Æ„G~=ˆ\¥*‰#|¢ib´E{acXÈ(`2¹s]˜ç”QgFÌ`!ñŒÌo ]Ó‰‘1ˆél—œ…¡Ïvu=V·=ıË”¬~ g5oµ·ä3D¬Y~é›.ãí™™0ñ*ÊÌlÎtñL‡gêä­FpöïMŸ×Y4%oõãÀî«Uş’öŸ—şÍêÿÍæÎ×úÿ—Üÿ)^µId;êììÆÿ°ÙÛ+ş«ñÕÿ­ÿbı¿©on­«ÿıg ¹ aê¹¡	©áÈ ñmòï€Ì©Kv BÛ¿ˆG­Áñò)ÑI«5h?ßÙÖHËµÏ¶¾cWªé44!FÁøğ?±<2ó§qgZ&q=Òo¬7šX–[~ø{`›K›òb¥¹˜ØXğRx€tĞocİ¹¢ToŠ{h³p<µGi%Øf,¢u—†XfXÈOá€õ¼°úX=Dn‘æuõ1 ¦L,]z18ÀØ	/»îíñaG¶]’cˆ¡HóÇû¤Ìœ*)9ÍŒŒ­z£ŞÈã9a¡†šDdléÖg…È¢§îslÒ‹zhÎ™P‡âñÖ¸1n¨&À2>ê>÷[£ç†ªG,Ğ{‚9TUk&`ÈC Ñ8iõél^D9èuZÃ¡Ş:ñËÎ`ØíñïE–^“Fª×ÅöÈ¥í{-iûÖ%A/v§' É2.Øƒ¦9((ÚÜVÖ•ø«\@bJ3W^Ô+=Büqu87BeX0à‡ ]J^Ç¾'Ş$°çføáŸ Q˜pXtÉS†€DŸf/&şéØSÏ]!xr£¹a¼gfó/â¸Dc·/~uğÇËARC.á÷:öŠ|ÂTñÚø_Iw%LÇ/P]:¯;`v.Îìér{qª¢ÉØ6âJ¹ZËR‰ATuõì¤s‘£Úº©î7×ı–èpı¢H¯TyÆ›'pOÆEò]Z!!ä§çÊ* á
8Yœn48=yARC>ÂQXìÏ±–ÉŠ¶Yohpj
6^…«]¯´}ûV{|“CÅÄ`îöã#Óí£îÉéëñóŞq‡;3!:…å± ¤CÂ<|y2jŞpãX2ãM]Ş«:èc}ş›Z²ºTK§Oåòzu¡7%Øğh#–ëR|jUqĞSÂº•¦<É™c¨­® 	=D<¤CxAeı(€æbòâÅÂ@(&<\QaSãœV°§¼g¦;§Ù¹ıÊBÅn‘HÉº+¬m)Xxô¾â§Ár2ÿ‘Ô–I»:µ‡‘a‚ìõG†ªYˆHì©¤7LûEDEÚƒŞp( Û>@½|Ú"Z{öò ÿrK%‰ğõƒîkw¦"¸PåËÀ•B™Ä-©ŠT²;	’8öNíà¨¤áE¬¢×Š‚ÆObòá7ÛOX¢öûBVÒ½÷ıéå÷‘eçéÜÖˆÃÅk,`ÚóŞÍ	¸H'¼`— Z&í¿&«Oíú¤78nİ¨DX-®Ø*•,±DğÕôØ´Vªı*†è4µß.—³µP•d}ûWä3û
ÈË:¸œY­H´‚"\‰JvYZÁôlg»TîcÈJ¶[Úí{èÉç/‘ü¼v<?X‘ö2ên¨µ÷3î!OE“’d<zÌÑL°”L¬pSîdÆç¶	Ë¥êÇm’|ÇÖá"r$'{.h^nß‹æø6Â¶‰Ü1$›ˆ
²vÛ0s˜ÆÏ</†éseK.Ğ2¼Ğ`Ï£ !•¸½-µIW]Z‡ãƒÍÖÉş ×İÇrT¸ó ãF<	Ys³%ª/Qƒ8»„šÄ%ğöO!'çAàyÅŒ”¾œ·%1…UùòHB¬Ä®~–+•!E1é›ÓssN…Çİï´NFğRÛ~‘$ì¶kÑK~é%	Ií†oj¼ïİÍG¯5P&şZeÿ·¯ÿòkFLÜaµlpeXøöúïöÎjıÿÉNãëıïÿÇõß–~5ÓY˜`ı—¤Àµø¼±DâïYPæ{.³'åµ]zsuñ˜x¸¬„×Õêõ/Ãí’bÃo‡69‡A4¥W²L~×’.©ãùü ı‡z½Ñû3'øâµÄ%÷_ÈÁÅâ0ÍÏpŸÀG§ÃùıL¼ô(¢–ze^E`Z˜2xkr”Pßc¸Ë6Ş£œÍ3JNÉíóãJò•üÌwÏGĞR×±ií?½S‹.97	ñÛgäáğôÙğ×á¨sljÄ&ê÷¤5®më%u-/¸æŸ^vNö{ƒŸ¡ï¸·ß1ÔÆÎÎ<z§}CõhxÕ·îCBş
!¥¢áç Bñ³ô'M-¦´Î›Fƒ%^ÃE@ğ2fO‹ñX•kÅÒ¦ü%²—jp*æş!×=ï“¬%·E%UYüäÊˆœñæ«oD³X9ê›á™±¾`©yy„€¨Êå¤"tI,’ˆ=ä¬|d‹ªqºxÃÖAÓŒGH“ZíÀÚI¬ªÜ	„Ô¢)MQ’Ç8OO¯­äÄ~‹¸ï&5'¶w8µTiu×:×}ÇÁ\-˜Ck5ĞÉdñ:n“ö$hà·åÔ™ÇâÆıîĞóÈ…!ßÑË‰Ú®ÿ¨ûE#ê¢[Tâ²X¥òP;ˆò[–ÂÈë˜ Æ[@,ç4|øÑ#ôÇŸ0&‡b—@éºjá÷†¢duğ‚(’Ø’*hŞ#’œè‹P©0®G¶Km/2p`r&	Ñ›Æ;h%â…§\q7êLzR“{0ëkfGdj‚‹šŠ†ç~¨± ğô½™é±%Zd¸ç¸q5%¡O%ªDJHZ¬«Õ-ËëƒÎ±Ğë:?nBÄ|Ñ-7%ÁT‘›@-fF£ˆ¤Jô“(¯íâßİÚá µÔÈAä¿º.Ø¼b’¿Dô™cºç¸É;)ñêıGâa /
 Ceu·ÕšÌUzN—¿ËRX:ßmi¯s½âÕRÌó“·UboŒt5ù	¼ØÏ„¬İ‡<‰›†ÌZäe»#‚EKÊÃOÄXÜï[Ñp#_‚$gä2šJaòêB¼(ÀLĞ5ÂV_òAérÇ)cOÊ…`À„QŒû×øÌ]f à{ü˜Ñ+.F©ö"°4ïÍ¤?b‘ØQ×´ô¦^Dò—É£	àcX™ÙPD%³wáÒ å8i¤'F=×¹Š¯okˆ!‘¾j¡++¹cØ˜7v|¢:5å)daM%;æo±ËXx„%öof{;±Úî~Ì`xüskp:Ä—<u„1N
)k©H§Šqæ¬™4M©î—õ¦z^Ö¯eM/'RT†Õ;yTá9/‡o ?F‹+tòŒ8!I¢z¼»ï%ä)ÙFcÏş©v]•˜óæñ»›=û»ï6€Üè'B/Ì~w#X¼QÂİì'Ñ«cãŠ;ˆ=Å²ÖE`‡x#wÎ%2}—@áíˆéÈ›wE£ä2ĞßÄÎÚ#·.U­ Ê¼)±E“r•JÓ@N=—|„^¦§éA^Y+?=Q»îÌÛÅ=UE¹ã İbé6í'^pÎ|sJcæ¾ê^!îdpq=–€£•Í³ÎÅŒIÿI¾ÌÙ[÷¼¼Cs–‹ãìí¥¬Í¨ÄÄ'£lÅÒïŒ1¦ıùg‚¡ç¨×;fP+Mğd_:#•x§|¤&mjÌCa#¤‘FQ,&ãái¿ßŒŒ[DI;ÉeSC“¸[{„_Ğá+á ™Š…ùÜ»× Vjüb],ajzWá¤7êü:B¸)n|S¸BP„ ğ"öÖ½E¾Dg&\d—”‰×[w½le}÷”+˜³w¸{7/RgÄ¿g99{)®š§@ÿŠÅ½uùË·`³yl Ñ1É–…Ùä‚ºÁ¨›C¿“wmÅ’Ë-®D7}ßIß{H£Àê”Èà
r½GØ7ÂÀÈA”rFƒïñıc¢ÈXXÈò¥œûN,œÒ=)^Øªû¢>ÀJë.÷-æÍÙm‹²óĞóy„ğ7û¢™tğå‘w"wQOÌ5²-QSSoO‹]„¨v.é4wôZ(r7M	^˜Á•&2*'&å>O¡Ê¢^ƒÁel;)Aİ)º¬<L«×mèb<Š
"6öèêĞÈÇh°°]Ó1f&h˜hºò©ÑÊö-fC$eÎcCªîÁl{«Òp!8½Ø;<í¯í9pqOØ}\Sä¿:n;&cEvÃvr²Bzê—š¸C¸ÇŸâ…c½÷ Ãšø'
å}¶‹•AV ›ó--E$Dª´Ëçù©gQ˜Ô1¯Ä*_Ğ+°53Dmy¯/Ö:(Áaí	îìå™ô²e2Í«İİ×Ú‹ıvKYÒÎeHù{7ï²ıûïaˆ!oxi:5êÀ4şøZwk5|Ë¨Õö=|MÚHtâßVš°õnk|Ü99wGã$á/Õ)ÌsÏ d'ß]’²qĞí—vÀ4ès¸÷;Ã£^ŸŸ§ƒoj›¢zĞYú^ÔuüúÜõ”ß-5-k]±.4ş Í#Û¢¨=GX-VÁ.E /´’øúY¸pêhhRÚ2u6;İ\ÄP¿\8e‰âl‰Ï¿L,?réĞ˜ÍÙè°¿Éìà=÷6¼~	©¨8HİA÷¤Ë¥ì4ğûF¢’ Œ²°¬ÉCôY 6(Q2¥í{,'öR”î9Ö8ïnõn—¬®xŒ¢¡LıYşT &×öÕ*9²—Y–”Då^-³JbêÀJ%{o.Í$reÆ£ìZìûåBÇN­vİëwN~è7.ßh` Ü÷Ö¹f.,ˆIÉÇ²·~ØQ7rós¥ªI[h.Hs¤½ù/È«Ğú8¥J<3İ3^ğ_R°t$oº¡@É“ƒ´*RÉÚ¯“Ÿßêğë1`NÒTbck¾~Â	€¥Ÿ’R%Gæ‡x¢Ä’ÿ?•€dsçØÚuúB›­º& %ç{râŠ·ù tAî8şeÁ¾ÿxŠ&E 'ô¢/œ•0æX&y¯RY›ñ	À_€`üÿè13î,¢$%ÿqüÈ 4	­Øçpi)àşó¾”CRgŸ`.4^…æaX&|¾¨–Ô%Blc%/í‹ó«7üuhÈg"t ×Öó¶´Ã+KD~9NÌfÂ¥¹[ ,á†ÆfœH‡ñ!ÏRÇ-”“ì~|€b4’üÊÎ1ø~ğ©“hä«Æi5CduâŞçNqW(XtÉÅéáÃ®~$CÕ•2¦ø÷@ñ…ğ3Ş‡Ò½<Q×\9®8Sjñäâáw†Îä-¾«¼6ë.@ëØX=k™SIµ<úY‡µ„5ªäsÈír—„sÓº‰UãGM®“¯&™7ñBÈİKY‹,»#«TV“RŒ*¸ºQĞ¯Ë+ñ¢–0§†ñÙÊ?ÕBùlÄ0áÖßô:ûßö¾­¹m$Yó¼¿¢rZ’×$EJ¾ŒezF¶h·¦eI!Jİ3cu0 ’Ñ&	 ”¬v{ÿË>Ø‡}9ûpö±ûmfÖU@¤Ô²Ç³KFØ"ºWVUV^¾œI%ê¡á«~’"Ávj«©Y½eO¿Æø§*S"”lóÛÿ¦@OèWóÎÓÕÖJcFD©ä+JsÇ”L8¨ÃË—ôÛÿd—ŞÏ¡Gz2ä”k¥æ®”ô¨êùá xlª
ñ"à¿FZ«”Mz
pIé™]…é;£ìfFİÈ×émıôİÑÁ_Q&tô=!I=·7ÆZ ®b(ààèx¡üa*™ÆzıbÁ3xÁÛ+sr´ÇªT°ïµozÇO©®à¶ƒioVWápáNÌ…Û,fjúniŸl9³QÙ•ÕÖz}:FçcTæ¤5ºn®x*r‘ŠµQEwKıSQİXi¾ÅªOlú+…DórbC¬9•åüKÔn£Õ—Üun(›3P•‡
iDéê˜pN¨`TMÔñˆˆR[x0z5²7ĞT-"İŒdÆÆF£%Î	8À5=ˆÖšL²Å26’ó‘z2‹”^õø¼˜Èà³Â´æá¦‹#ıÙdĞOG9H.¤kGg?Á^§Å`äó/Ãÿı˜#–à>œ$ñ÷e2ˆ©Î¿ûáùyök:ßñzÙÇü
;7jõı6—»†Ÿşkxã„ëûùÿ?ÅøRœÜ@ÓÜÏFœüÄ¡u¼ø†.mÚ×,*–V’j_U?âUOŞóâhOp1Â‚¹hLRşM9ÄØ;ë_¾²Ûï°òïË¢kÿ8å}ü)‰Æ"á°¼†ÚWQéè½÷h3¤‘¯(_ã_á¯çûôTşÊjÍŠo?BßäËiª¾ˆâ'Ã è	ì\Wmü6ñƒ	ıúÓ‘øFTÂ¿"~ƒ€Ë:ïş$&â,öÚ`ãRJœàê¾Ì¾‰¤éD1R<Ú‰´px‘´¯"K6ğWÁYèiÉÑXx–^ÆâvÜÜ‚á&1YÖPÅ¨KŸ—ñWä4K¶©´¹Ø—Šãdöœ‘Û¿ÍZâ>îşå6ù¼º‰e—s¥9Ç0âTŞNMsÜ¢ËJgÕÓ&ˆJØæ­ê» +Y}³Ñ:¥Y€¿pw„"ş³µ^”_¹IÏÂìBuË‘Y…|Ê›ô
ô©hèKn•:Ù5ƒe't&£+9—‡ˆÌ @¾~<«ëpA²Øö	qó)‡¾™N{O\ßõgÄX\6ÿÜnƒ˜¯]K•ü.n£¼ÊÂĞ¨TùÆØt=•r#‘œq‹]~O/µa±J²RÃ7³¦4„ Z+wxA|nÏo&Ú7™ì^Ë*iæöIÑL!7bE¯Hç¥0ní£%58È“ûlÑôbÁÅ£~4I“Ü£›İúàÄšUPMdÓ¹Kq‘;ëˆœB­aTÆ¬ÿ³Uš‰$`sÕº BC"Fâğ7ğ¢'ïácMï ï‡}¾Mtf]+Ìóbâ²Ì»X|Î_«¤bÈ÷ñŒ@S(´îGqx!n>†l”N“³éØçÖfXşF5ŒÌbJÏŞzN/6¤¯®ü²AZÈæüÎŠĞ&ßö öëd'}¢İÂ|Kyy™…éÌ—Åƒk”Ãßy^-xŞrGá$y´Íbn6ƒXFi	sYs*sæ’…l?3Ä¡a£ óÈà	ÊÓO$É=/$¦vP±³Š©ğC‚¡ÑÑ¯3¹óõºÇÇ»û¯{å)§àb}¿ ¼xrşÄ3\z,»qÑ™ÇÑ­H	*§5ãÔ–İ©S­Ò9[Ë¿`¿0äîİ¤yÚ¬¡bšÍ¼ÿV‡I1ë–½DrÜß‚öŞÈíÈîudq:*ú™.G†Ç‘t8šíot7îFyo#ø=÷}mt>5İ•y¾A·ËÉ}„n™Wø
9ŸÉ?J¹å&P³IÕgÊvû3m™=W³:mmÏüNÿë€cxˆe_×t“”»ŠİÎSÌâ"vçb‹;ˆÑÚĞÀÌ$C¯sóBÓ.¨šóöòô“&Ú9æÑJY$¸],r)·ªcè/ZñK·ïÇlÁÊïíÁœÒÍ¶,”Ÿt‰³ˆqn›³H\˜òÛŸıÕ­"æ’£á÷íp„’¼ d%ø"S†Ã÷òÉYDjë‰0ÇªYàålh–Syq•[hT±Úkå€ßlMÂÕyÀ}¾w-Œ×É«®­»ÿ}g
^¥júìÉ<OI$ª•ØĞúì2!UäŞ>?Ú>ú[V°<ºÖ²·XM•¢Z}¥Ü\Ñê%üÕÚıµ•ÜŠbä
 (*fÅØÛK@r‚Ü¨ÀE²À%AÏb:óeã·r¢ke…ÿ0d`²oÙ-†ùÏQ‘ğ¸UBºf„¢xB"/è®ÉßÛØ`
•€léä¯­-Y•Ä÷y¥‰‘¶—FßTtdĞ—š,‚i}ùóŸV¬6C%«PcÆ*ÓMË3âf6F@„W\W°••ÖúÁøÒ`ÛWı	-¥šÛj¬»pD>l2÷äøUı‰û§çÔËg|!ò•gİñeGc4Á? ğ“„ŞÀùûl×–áÕq‹ñS·ù.M‚¹i
ã4)şÕ¿BÂç®(KˆiøÆŞ(Pe•íYYægMKéÕ³¦è‹né–#±5ZM¼‚¬àˆÌEÏ/f[lL¾­ud)_˜X7ï¡
d“L†PœÏ=Tk«Ò³°‡êºÎ	í|ÆmŸ t×ğ6õÙ™ØÁÓÚ*ÌË÷A¼æVÖ•S©¶f`˜)¸²fÈ×.ÍW‚qI«Ãeª€òJjBVÀæM[`Áu±°êCî;ŒÌ)ÄXçS†\)%úSl'iO9­¯hpœ94N©)Nšåkè£FÈÎÃâY0ñ&%F#	;iš-€Aé‘ûKqO0‹mQ±'8¿Aôw9éçùöW0òŸeä‘•mXCÎ~Éø­öf«ÿ«½Œÿ±Ä›‡ÿv™á¿­7Z&ş›ıÍó5æ0iÛíÛåaÀÆ,ø ‚sÁ¥!ö`µQ¨+¸óÂK…÷àËå²´‚D5_ãÍ©¾Ş;x±½Ç¾ß>ÚE§ö¯öe4Œbtù”Qª¿ïít;µ•Óàmkk£=ZQ!Ãßlu÷ø«ux·‘½ë¼€ƒøÛí|½©ïw_í‹,­,¹’UÕXŞõ2)Ù¦‘pûï'{ª€Íì9GšÍ„ÇÛ‡Çı½ƒ—ßõur›—·Üğ'ï/ğH@õZöÔ› |1IóÕÀ¼è%^A€4“bVU`ı<FÇŸ±ï:kNò¸K†öÍï{ÃîL‰CJİYñƒÁx0V‡›SuàİylLÎœ2Zæ`›¨¾'·;
+ ÚÙg#"Çôñ™“CÎ|Ä)ª‰iÊnØ4À[ÇÃg<f¶ŠìÀ¥p¬´N]æGA¢ùƒßsÙ7ÏÚ pn‡òKSN¹J’ƒûç“­BÙ}Äd°®k-ì6‰2ÑM´ù8pwVZMT+=¥ÓxçºpT?¦cŸE1k1|D?B;px(r7ÂFÁãÎÊşÁ~wÅ2fæ¹µvñ©Cœí³SHš•å„ŒµĞ5#a¨ âò"«Åºàöò€®ˆ¾’¼–â‰ÓÏK<÷qÀ«^|‘0>”0®ò7$E"x€ê÷hÆP%Ú2Ç¶0ØM;«µÕrÈ?×p‚j*áĞºxÅ-$Ñm¨…
¥oğyÎêš ¿ù&7ˆ0•ÅiOµ–"¶«hAò©Óë’´ª´ö¾6›§Í&û´¦Cİ‹xÛ'Æ‹ØTxäšJ•ó‡B¡‡=Üæ[¯şóvıïëõ?nı¸f"iÁøC.Lóp|`Şpkp:B| >›ùVe­+o!ÊvR¤.m,Üph„w&Yl‘•Mïpo÷ø¸»Óß>:Úş–*f†²ÑDe““ßtm7”,Û‚œ©’ŞqVG§VxÌ8ô©´9ÜËMç&6MÂ•úàÅ±wD*)‘÷iaBĞX¨”¼ós:¥M-ûÎ»‘•¤7HÎœ–:SeTs‹ZŠÄ‚{†ğ|øÇ¨T§ŠIé+Š¡I'^‚›şÙ5zº9J¥EÉ0Ğ–ƒ®MæÖF6{Âí	ëêÔZ[ê·ZÁ°¢²§ü`Âuß©m¨§¢g0¦bĞ‚5|¸dRËÅŠ©—¢bK äK`ËHñ‡…È3¤'‘{½zãõ}äÒµF »£ßTlb‹I?É‚Ïsq“£sê¼ìpœ ›—øMsƒ øøŒÃIÀıJLª“‰4Xxœ›¶3%ª‘Ûœ~^ßêLÉ,£[—zåå‡,‡áŸåüáÌÛ
@òÚç(š-0c7ÍÊTÈeZÎÃĞê°¯¥ó§ã[uß–mş T¹ÒÉ‚,0ÎwTJZÙ¢®&Pµ÷ášiôCœ‘Ì¦3J˜uífd™©cßÌ({&¦ÆÂú¹3'y¡›ÑšÜjó¬¨LdãH­²®¾«ĞÚx»1¸!½ıîA°Â”Şè† ³i9ï[zÿUyÛR‹næ\«UrƒuE© œv±EŞ(\#n	Íqî¹‰D8šp¢ °f$…
„¼‰·³iêA}“`q´NËLDV7«+Äøä~ı>…V‰§crğÅÈæè3/aÊ/‚ätÜ…ë¬ïF£$ôü›6şOw&Ú…|!ïˆ(˜	ÜIêX§wğ‹ ÕVG«HSÁyø	±.<vy>ÔWe\ARiÎ>`õ:L\€çûÆ:b%à[VSi B§,T•-iiÑÎ	FÚAÓ¸q@ÙÁŸ…À<]ßcÇñ5C”Œøk¹·Òvş½FwÓ£Hó¡Êš¤h “ ;ÜÎ=DlÀ8Oâh$I”<`´õ"ˆ[â]#" ¬ßş®Ñ³­h0:äA`ağp—z1M®sûÔza"²¤3¦cË09Ç› ©®
w+Æo×”ïG	]…¯Ş!éœ#"0æ”60ócígß´X5ÿû…t‘9,(ÎC,”ÁtB£ÒÀ)‹XìTÄìÓöƒ¦?¡Öâ
•
¶ªµeB…"ŠnâÉ0µúüL¼œŒÀuÇÑˆy°a÷OuĞP5Aœ«õk Nx]Õ§coŠ-JÑ!ğ×ò‰û°t Cı<üP…ËéBÙp•ÌSV=œø0Hq¨‰JòG›Tl{í£’há8xXÇÅÀ],²ßÒÉ£vgL4–gÛëŸøæº®¯è¹¹µŸØs^`ÅÊîßÍÂSM"ì'ÌJÄ}Zú"ñMÜ}ì÷âÿ<|ÜÎÇÿÙxØ~¼Ôÿ,ã¿ß:şûC[üW§òı¼”±ŞPî¢ ğÇ×‚åhæ'_(²{uh çº9Î'¬DGn·qsˆš_è}4êØ13¿Õ,é¥ã%·JqÇ¸yê2u9?Gœv0ô™0kb’ Ï[Yõø\BÅäno}H9<´E¡×¬Óx:Wûh)N€Êå;›•cª	´>èIxt‘D¥8„bØİ9cw â:r»cøÑÄ,K[VUÁßV¯ÚoñÈ-”’	+bAAy€5Khù·ğÊƒ_Ú:üß<@fCæ¥lÒ(…*]ÉdSEIë¡-&®©R#^>×…®ÈW÷PÃ‘æİeò3²Ñ’åql2 ›\"“ŞìUoïÏ­ÓÌ®T¤(ÊÜ€Ö°—zé4á6ygÛMç[7U–HığÿñI4sJLB–eÈCã·²Wûı×'»|Å‹7R|½%ošF0,Í
”¾ªC*G²ÄË£¼Ÿƒ1^}HÌ÷Ûüö¿a•&ÑYŒâ”#3·:~²Ix2EÒê¬²Ú*jµY®­5¶¦ïöB™ÂcnıYŞÄˆSWˆ‘d(w«@G´:‚VÍ¨J'_ôÉ8Ò§ª¶„\
ŒÄfSPEÄDIré›ü-¥q#Z€,L†Ë×r¯øTšÚŒTÑRbœã—ï‚Áû.‰å >8šhIqßÖïÕ|\ÆÍ¿·÷»GûÛÇ»ßwU\4µÛpÂ*‡y…àõ,Ænšu>àZ§´Jƒöµî­#ÚvÍĞ¦,Yç*,u@kÊ;–µ’—/¢˜Æ/ÆÉ»èŠK†bü6ëus0ØœÑØïvwú'‡¸»uñdê´² àá¶œ…ô}½y0	ÆÙù‰Î2Ş{ñô‰>3ZÍ$Üî“:üŸM'·O³·+öùÌ‹»¤ñ/†cüâ©ºY6÷‰´nJxÿ›&tØó­Ö=µ™¨Í„
îÔäƒ½ã#îzÂMNNrWCC¥4ĞÚ&Ó&~äòbw{¿ÿ ÁôzhRê–
sfÖÖ
>ò‘õ3ØO±ü¡Ë\[mRYë‡‰¥ò¤Z¼†G7ÈÇÓ3‹i’œ5|"@Ä5ïó¯}ß¡jjx—•Õ¿/DOÇ!ß|­×œ{G¾CDß“±zÎıµ1®Cº|d3ö|±Ä™O«~û/’s“#\Ùqè*v›û¢zwJ`ôıašäáhÅ)"àŒêõÉ4¾Ôòøcı>*l~ÂVë>>bA'Aú—£îFröso:L|CñÄKvø“/4"P—¾ëã,¡Ú›oÿ{úkJ
IfL&7¿¬d¨ØpVªÒ•[Bd µ«¸,EsUÂ¬æ*D{2‡q¡RWÅ(ní*$± Ñ“Á¦VåD­ƒó¨S1ùé¸—F“	n3Âh‹ë)„½SÖH+¬`ø¦ó—íï·¹O—[Ë’©ÚEd†¨qÛ¹æ…ÚÔÄš*E³©ÚÒ¸fÍ¤FÉ”%Çâ“Ä?vÔ¢˜!ÉÅœâ±¬ÒÑ¤³Ò„ÿqYã½Œ³^†¿L÷ê½íŞl
2©.ğ3D¬9b‡*ï3EòœÉÒE¦¹5Á¨)5:‘¿gn¤Èàˆ„/Œ™ŸÇÿ2ìmIr÷äÙş;zÔèLŞ–P’’¶‰ŸY*yÿWİœĞ¼Î³äç†yD]P-[c¸Døåƒ|ÿøBsÉšµpK«ÙÚcåí~'CÍÁ>ğkÑR;iyÉm£ùÓÙAçl¥@H³Â)‚œlş<[–ßql¬ÕQÛÛ}Ñ“÷#Bí}Íı3NÈ“ 7Ş’¸Àb©†8	ıQÿGAG	yÕòŸÀæh†úÚ0{«cğ>Aëšº|±!ôº}æšÒÛRƒTæÆêM†•ŒUù,'G{XÜ~Zã1|å.š+ötl–Æ7P©-‘T-ÌÍ>"6ìí¾ìî÷º=½£í7]`¼ñ
V¯ÃA0Nh×G}Š£B(ë0
ü%ô‹ÒêUš.sXë›íıí×İ£şË7;ZÅoaÅ—´	—é·¤1îï.¶¬/wU²&Û™Yt[ĞÔ*@¬ú½ÂmZë3ğ»–Š«+úØ­d¾l‚ñ)§÷N†¢m¾N,ï9kù:Hu!Ê`”_t…=1”4¥(.)Â–Ñå¸ÿ DšÙ§İªäşP%ìWÜVº{İí^·Ù xz4†`r'Ö^£­©½‚róƒ’rîÈ,Áíg)Q«££e@KÒ™İÍ”ŒªTæ)İüø¹f‰î¬qœYêèšM()Š?J¨(7¾0©œáÀÿÀ_ç¨ı†€ÒÌßÖG‘à.Pjˆê!à,e˜Ámî OM/Nº2…6^É%Š—êm™ŠGs—ª¶ÎAP`a#Lfï8²ıïJäŒG>÷Â!FLRé×Â°ªDA4‘P®I<3*ŸK=Å"ïÊ<èu÷˜kú^!Ã!zhˆáÉ+K»/\„Ğ^tVİÁ¸GWá}A†Y¼dõˆ³òT%ğªWãa¬Y‡Ã²p4ÍÂ¼`2Ûoğ9‹guc|³£5/œšÚ§Ç‘í+‰ƒé‰v~k >E“épˆ3Ây,,¿öQ½×Ìjò”·8Ùóóx!²˜}Ç¨rÈ‰Ç³úÑeÉé
°yca]Fó2IÏmëP•¯ÒÛ5ê&­7Ö»8.`ÙoÓã8¼0Õç9õOşzS!‘¶µR	7±ØÒnğè²<¡íEÃãö|`¤&kf¥…km”VkÔª¶Ñœ‰-Æ)¶0Ô3ÇX?l’`Ä„Ò„¡„±¡áe2E†–ƒ’éJ…;„ËtTWªÓ•³o¶_ï"O²}Øßİßéşµ³ÎªM.‚¯¤,Bİ\¯4#ã&ÆØMûGFhµLÉfBj‚Ã ùy´-‰£áKÆğ>É…Ø€ãí#Á¢ªn‘³ğ~.ÏEs15ºXº¹ı“oMÎx¥1›<ìšWĞ¶!}Äôm³­Íª=²Aå¦à
¡á¥¤õÃá;ıƒi/ÆŞ°ÍVáÜ£ƒ8NÒ55†¢Iß=|C¡1xMŸ'Fb5ú æŞçÆÑ–›åşÎw‹QtNRl¡V3îº`le7“ ‹Ú6Psµ8ë¦nªT\)7j}?Èpzg<Pö^×ã&ì‘•BÚLÍ9¶ÖLÅ–ùq6Û˜&Ë–
UïÓììÂÜ‡”Ìè€:ÁD9ùîkåËs„Z]g½İ×»ûÇ°{q!-îÃwÀÆÛš"®Ş|A’û ’Í1î®bÃ”ñé'µq˜j«tÆ
^ä0«ÒmRPÍ«íú&=†®P#‘üG@ÏIĞ§ÔënÜ~Øh7º¶DJ,†á|ıaã"Š.†A8(‰@ÚJŒÒ»æ§J_”ÇÑ	0ŸÖ’aø;ny¢¿ÂĞhƒ S'#œ>ÊwîÂüm*²4:lKú0£M£bÉ?ËXm«D‚ì;wñ|>‘{¥tY8x§rWß_X¶GÜnØ»±r=õÍK*7Ü	3gúÍ æ1½yå‡Ã 9ı+/L¨ÛªºN]Ñ­’âBâ6ueŒ¥CU^&9¢gÈÆ#¢s6Î½›bYL·N+°ã·©9ÓZfêVs¥ÍVfâÆ4ß·›µov¿Æ¾æ\]`=ıl{×Ä
Ğö¾h|¿S„nW@_ã0gí5ò}¯»Çni6ŠßSà]ş²©^¼8Ùİ³¥`ãLš|‹úPÛuãÔçœ¸‡oÍ%OƒQ;;æUa¤eó{ñû ís	,êE3x“÷}B~AK¤9£%ØÄ7»ûú€å!¡m÷(.48¹¹Û»ÚlL{DfİXÏ‚óˆLÇIÁ.4Wfµ…'EjÔ¯”‹n±m«{,oËk ‹î‘g•@Ûª²U®T9V>~«“Ü…´öÑºlÈ‚£óªe.n432d¬€jó5"&0ØEåødÃÃıÌHãVŸ†ıÈĞ~ÍíÜì\“$İ³¶¨¯¦‰³Úx»ÔØJåfªş‡©¸g† ÷(˜xalg*n°$Öã›«ÚO]ı—¶Mjkİå¸Å¸_püRiOªìô2Ó=aƒÇ¶‡š"àpw¥Œ6<B÷~i½øØq^ÖÁxxM+Â¤	ó$<äˆéåBYr…8¢u#à½"ÿô@[UŸrËŠ%B–¨ı,_HÎ¬ŸîŠù4FP«üYøõv&æj¬©>Ÿf_Yı¨´›só•„J“1e9ğÌ¶ïû´˜ÓˆÉ˜xcT¯ƒ”YÆÅqañ„qÅĞuQùÉ!+}±Ætó)nşøı˜^‘ ğ¬|¤×‰£1Íº_ÙòZ¬ôÍË*K~û‡t¾gz£œÑ#aDğìŒ<•%ß¬5Oø¹¥fõ%v ¼Ãßk¬ªò–/*¾†RD‰‚0b˜,ˆcÓåYX¦ˆª\V@ËmxEc5´GiÀfy°¾ÄVpÔÑœİ£$Á¼©Qe1S#K#Ê¬‡’õj]G˜ğºÎ²ĞfüsRóŞ?`˜9oşì	“õV4Ü¹‚1aP¬´¤”1»W¯YîÄŒKŠ‰Á< ÷ÈÁ¡¿/€¶„PÄQÂÁ€#‘P¸‚$H˜#BÊ@ó·’j¥¸O³]`<0•eeÔş¤E¤7ßè¿2¦JğÍlXà#"ƒà	X>úÈà·{´È†Dí#/…5…# ÷ü1Šã ABXçŞÏ°	àŒİH@zMÎöØÚq@²€şF½¿sáÊºº`nV…ædáœ°D(ºY[6sm¹ac6åıTÕ®U?Ï;ÇÌiÕÎÊVÆ¶ÑîÃ\Uf|gãf†za-w$:¿
&6?;µ£áÆ€bqrHÅIäÆ÷“`w~Vë‹OÜV¬HbB¤[’5½Zr¾½5¡n%˜I{:[(MÜ-&×tÎ ¥dtùš¡†´4ù“ÿ•‡&­T^ {M/¶¥Ağ)B·ª{—İ²û(#md·w^¤Ñ‰\:Dpaà,îEÂ5³ö=¸1°èÒÊ·ºÏfÕğñPnteÑîØ<FÒŒeW1ƒ)q®«uc¶KK+6BénL8©¹=¼Ô‰{¡/Èïü?Ï	"÷ağ‚6×*_/˜cÊ°Y+f7ƒçş¬dÙ*9-xƒŠœØİrW†9•\%®U)ªJö•HÜ*é&{{éÑv›uÉá<kÿ®ÎİÀE¡”ŞRRg&dÅWX×¬:3êK³;‚50­'3Ó"ËQ33:Ùœ8Ÿãô0ãğ‰h÷š¹VÅé_³oÀée ¾ü±n²Š8úá sGÍÇ.=¯[9÷/jî ¼Só>ıëî|“ÍÓ£]ŒÏ€ÈÂŸ,ŞT	m¨›©íéazSyo÷v_î÷·_Cı7;]¸‚W=Ø£½„ÁñÌ/×âH-€UşnV¸Èë»†¥¤]Ş¤¦vNë³†U£³ vbÄçù1îÏ¢³8LËjAf¨QrÄ”ˆÜ¾ÖÒJùryáØ pÓnÃv’Mı!úhpÎÈÉŸƒ…“ÕÑ_nD"f#ôlewÕ?aÇÆ,TsA›t‘Uaˆ /=4v§`hôü/B?œìG–e#Î›]CQe;ïœyÛÇvbè$…¨tÆA–;Æœ’SËz@YæuÙ"9Œ’ô¥KX8ElgÈ§[â¿5&	åiÃà³Äÿyüğa	ş~ß,Äÿiµ–øoKü·›â¿•ÅûXQÜ8¹§
ÅMœ^gÃÆæü©4S»ººj\†—^ÄíÉ {ã,núp—hö0ìO×V'øJQv4®C{£ºŠäÅ_#ŸI•VÖÕ5¦Dƒ)"Ø—1?aï;xsxÔ=ÜûEò€—(¢Â‡ıvzoéëKüNœ2æ,MQçĞ¸ã3AßuÍş¦—R4ïë7	ÑT˜"[¡9ë’¿|Iéx•—ùmıÄ:V¿Ï~ÔìHµaœƒàuê? B[×…z]dçĞD
ìFÆu°ú+V6¤L¾xúr4š7¯…ç‘õÌØÿ©€w¬É8ùÂøŸíÖãÍGüÏ‡–ûÿrÿ¿5şç†ÿóø]€AY3J_Ôz’'Æ%r¹À%_&ä[&"(Zã2ÊIÒÀ‹AvI•HšÊ+]Oıµ¼§!ö¼¾°ó0NÒ{ÌÄŠV7°9îï¾B/õıò«$šã(Ï¯ëˆ”¾æ(ñC‡‡É*k¯–’.À<¸Dy2İ%ÿ{&Æp×Å)q´fÁ]zªGÛ»g;lûÍ‹İîşq—O–#oq¼KVG¿çé~„d÷™fVF·ûëÎëşÎöñ6úô:ZøŞ§Z ^ş `¢½t«`À¥%’{ùCwï%†Ïƒiæ1ı>™”m•(˜4QuOÓÓô0º
bòPİñÆa0dCXéaì¡SòÏ¥tÖŞ.êèRİ§é}»öGJ†N*Šµ5Ö7ÙŞq¯ğâIş×	¿r‡—Ö§T:4A¹ {ut D²¿Óq/Æˆ°*_÷ÔhHzjD§BY§=µ€^uÖõ,*˜ı"å¿ùEw¸ÎÌç\¿•óÉ`EOaCß£TÀaı¼¢Æ¢ˆ\­Fî;"1ÈÙûîøàÖåÿ™²¸âñÅb<8<ÖZg@›¸d>ÒÆ`ê5¦ç£Xç,©z²Ñj?q,Ğ)zqO § Ü¢†Y—RÉnëƒ{ 7ñãî$õÍÇ|ÄİJ¤Ä'ó™B÷—õ3õ&çQÕ‰[OÎô\7k‹´ëœVî'Ñ¸OõmÚF¾1·Í¬|¢fL¹ÕèQ£Õh¹NÎMgæ˜öôÁl?q©Ù;@3¹—EÃt,¤±› Hj·Êî¬´c²Ş“9p.kN)êº³6«,Ú•éÖ,›}æXìOuóÓ­Y†ù˜›gÂo™cıä6«²ö­œ¹½YG™9ûÌn¶©Ÿ³=fw®>¯sÔ‡:_:u«ŸJ$Û‘ï§QÄì—y¿’y?³G3†RGÈö†‹0}7=£á§ÑCÏx3‘H˜(Î[Ü	QTdœ:|{NÑ1Ìtıİ®L5=¦QI	<><x_O„(`h>^7=8ŸŒµVî—Ä§ÆÑOÁ E·‘ª*YW'oè}€CS-.öåMwÿ¤¿{Ü}c¤·óYMo‚º*2NH´¢ÀÒ¾O#Ø¿ÄÔª-l³Ñ¢İÇ|.”şzÅÑª‘¿ )>l·Öü°ñ¢O·ª¬…¥=6ªšø»Gó5ÏèK„AnxŒŒŒ0¤MÄE—~¼)ÂE'Hšü%,¢´†Ôù*>Õ!eîÕ?»îkGÇM³b^	j„‘c²Rƒ¦ëu·÷¨T±÷ëõ4âÀªÂ„7y6PrOe©‘ŠÃ³)'Š93F=¥“.çE|è¢9‘ÁÓê"À9Ùá	çÙ£üë+Ã
¸™6ÜÌÙl6šıO¬Ê÷/Ôs!*¹À™L#÷´ÒX!EXÿ‹Îàç)ü>ÃÈ¦,Ã/Å¨WKõ0©cÇöÑFõrÜ8ƒ`âA!*<jŠ¦6Sï"iæ›32`™ràxƒóƒ{¾Aò\aÓ”E5(ÚĞy'Ç¸-Œ,mıA«ÿS¬YJR3‰%âdRIø…Jh54(gÅqLÛ
à„©•G½^ûèº.èÜÇ
…ZâÕ¨ˆ§/R+Ï^Hş	-¬7%‰ˆë¯ûtÕ8zóí+cÆ£• ¬õxtùØs™¼=u_íşµƒ÷Ù•5§ª5Ó[·pÛ8€ÖBí+iŒ;?‚s¬Y½ÎOl8§:è/åûõ	WÏÇ¤‘œzÿ,ıØ9Óó‰xÄŸô±¨Æpò Cà®ë\³[çp¹¶óé‚làÖ15÷®š,~f©øƒ[5øs¶ƒ»Eê…~}Um<	hßûw?˜À8Vº¯»eßoíâîÑsœú[áâCÊbrc,sÚeˆõb4p<{4ÜW8ZÂ³­Vİ.ß;»HßÃf¥~ÁÅc~8›k^GmùÖÈEÔÊŞ~H“T~÷Ò÷Ú›‹wƒº¬	Ï‹á4İÈ¾Ñs×É`h;î(O¡%Ó³K.@f#ï}ÀøôG½!CPÍ0Ç^Ìä•sîÆ.àE«„x°‹5Ç<OÛH•q8w¦ wÉëÙ…§L9Lø÷¦H_€ìÅĞ‡c’D¯ÁÆÑ¸ıuEauôì¸£a“~ûöGÇ)µa²[º(ù‹-¸Jî¥İèçxHì‡í]¸Ù;6x”²Xë™ N;ÙÖ"o—øï5hòp¼C¹>ğ¿#!Œóxga}³ñÇæ$D«?“’ O\"fÒV®wrˆdÀ¾íB3zw"-eß®‹ü¬4»9¯‹:×4çÌ^ù‚‡¶äÎ%«áÿOkÖ¡Qí/5iÌ¨93J/JuDÓ¹l+"nŸÅŞî+°ï‡`Çß@®¯P˜]èËß•È‰ùK¸Ü¾,«Ûw¬‘¥Ä]VZñ «ü[l{>XÈÊ“•ü«=ØùZ-c÷à§W8®¶›M”®™ÛÍq>µvÿ£›ìC:ôtÁºÄ§œjŠÈ‚ì¦&hŒƒhÔİ‚ğØ›ÂHëíuÒÀ_oä?Ú„¿°«koËîLäıƒtcÓlÖ[}ÊÛ0p+ÿ”Ö 8oM;kÍ
îîõÆ82‰Î…í(—¾Àšç3–\SïÃS®Â1ÍNÓşåŸeº«·a&?fŞõ¤øÜé~zMr¯xYæŒÚ¬Ş>•*¤,YoVÅÌDÆ'µºeûÒ°3’_ÿKÖRìo¶n2SZc¡£éXA
 1¦PçıúŸó«ÓÌoÊê;ØOÓ$U¦½Tí¹´Èd«„†út„l€t’Íò.½pˆzrÌ ,ØÚüÖiĞì‘†Öğ;®à¨Q–ÏMÊj9"+% !A£@_(¯BRÍT\œÕè„JÇÇóéêüÖã2šC†=ŒB…é0h|şƒÅç³¾VæÖJ¾-¬°ò´…g7ŞRËñÛƒŞ±–Zu©×û'o^tò‹5ñĞ¶	–f¡%ØÁY±Şh=j´de¨kŸ³¾ìG)Ö¡êæ]ÿõ¿Ø‹kºä-æ‹;¨]y•ŸO²"™¨èX(ŒJÂ„)|xšrÜ!=Î$
Oö¯ÿÉvÏ1†¢¢æµ!Úm`¥úr'ãnÙ38çÚÿş_Öş·µñğqÑşwsciÿµ´ÿšcÿuk0ÔogÆMûÃcşL&ÆdUôEì}¹Kh^á}²Gêh¼­Ïzù±ôİò»ÂıOÃùV‰[nËfØ’º‹d@Øôh\OĞ†gd‘<F(ïE[…ÃĞÜ;©>*uÍKX.ş:Õ¾qÕ?èe¸Ö©ãè¡9|)Lús8é˜ £ÂÃ¿ ì¨åŸHo^äÈ»}&U@€$4«®3õ”äƒ•JµEOr:'HÚÖŸs<gÆªôÔh9¤İÌãİÁ³‡ôL˜™ÀïGê·²§	K©-ôbÖÖ[º§ğ†QßĞæÙG«ó¬çoó…˜ÀMnMÏj‰ˆMo€,3Ó
^V/Í7¶(YD¶9¹i½Š€2İÓK¸ÓÇIgµ†1÷LÔ<|Q@°ªZ,8M¢´ˆÍˆå)ãäÊ÷"æÕ96Êµø.Zì¾È;N»Õ±)îÅÄ5÷NÎ³‰º™çû O «
èpq§ÒrO@	@ğ¦kë ßæŠâ”§e…<­I|­ıäìvtÌYÔ§æd2øğH€¨˜PAı‚‡R­ipØ& º)Ï74‡cVOÎ‹Ş¢¹¸'Ì,ƒUÉæBIlRùö—`Ç³´"g?aøµëMÑ-*8aØ²Ã^BÍàíàéZÂÙ0#a&%+ĞC¼Ğ®$À·@2âö æ£Šøiã½¯øÊ”u•*mídˆÂ1®é‘]huŠ7-ªBÁi¬[¼ŸüÌ&éL!C8öxÁìjyjlã(J•Û¬'wx3ŠqCÑúí!œ€øö¿E9yTÍO<.ó¿Ù Ô¿R¶”c­şT:Ú œ@ì"ÂºgNÌlABu!8+”­g®òòXùÃiía$ï·ÿå{ìÂ“[oìÍ‰¯Í$<´@- <ª L¢ClNÄm¸w/ÀgìóoÚ
á‹ÂÛcv[wvQV·J\HôN¹Ğ£ç\FQÀ"ÈØ£ÓqÎ*„MUuÎ<n>\Í§Í›¿èäo»XÔAù0ŞyHn›“rèdEæ=]²öxï#ß?ªôM,	€½÷Æˆ0ÏVµXÿ„ëË¢á##6âTÈÛd ®š*•v(åôíØ€¶2¿ó|Ùüf±©hÃ’ ¯³»hôPµıÖdÙ™-Ñ
~ë[ª'ØDézénq@IÃ³Ÿå¸æ¶(iqøÄŒ Z©pÇ½r^ŒÕîÃ-œKîæ†nÙüØ¼,ğr?CµÎ"‘‡3ZI:j—êzñ0DO~—NhˆkUhŒ…¡Ãš†2‹&`¾¶9œz‹û8ú
9Ù±ıÎ‡_~‘¿gŒkÛ¤•må"¹nˆD\°gp}"ÅC‘w0UG‘3âÆ²Z›Õ6YíQ>\ï™»Â‰ÀÑx“ é¥1Ú]Uµ"½˜D€çÓ!É ¦c¼	§Ş˜BB„Ñƒp?rDDîÈíŠi P`”JÅ=]rÊ/M_‘ak˜WI›©&…z@,‘}‰ÉœºF3Ûàº¶æÃu‰	™4n [–¼£¶Lss½}‘Ä
W¨£ØOM¢L£dë©bál=ÍãÅ˜í´5@ÃQÉï¥ÖÍ´t7µn§bÏnmY Œ˜½ErËÅeAÃ¢“Íl›rà•y'aFg¤œ1VBîTä‘I¼°Åªäo›E°²h["Ø¸Ÿµª\Ãtû1»1ååP»,¸ç¥™}‘3]å‚‘€ãßcÛ«ºbám®¿¨ƒĞ²zBM›µDâ E—N¢Õ{µ?! ıbèƒ„ºô†°QÂ¦)ª½xé€÷äCIå[øJm½ª3£$©J‰
1w÷XTBÓ>ÉŞ77bÅåï¡Ñ°£H°ˆ{¯X(‹³Û±Êoà|òÿFÓIó³Ö1ÿ?9ıO«õèÑ¿±‡KıÏ—š@ö«é¤1ò¿şÃz{c3?ÿ7-ñ¾ŒşÏ2èáÔ;Î³És§‚Ú²gÁè¹…6’wÏšğ†ÔÒî“Ãó:¹¾ˆA;ŒL²ÇV•{–ÔÕ¯‘0Ÿ˜‹ŸÉ2tî3½‹ƒóÌ²åxXA#ŒÜçòÇ³¦÷¼Á˜3§yŞ`LÒ„%À%$vÇËM>Oû€MS„ğ,+ïøây½ş¬)¾¢H,Ä³Ì6œgM§ûl°DC¾pG#vßÚªûN§ÓÁƒçÌ9X8Ë4è©S‘Aí,+é§H‰ÏâçóÊT¶A²di4À€áĞ…T¹Ï€QzŞ‚ŸğçYª¸Q«¤‰eD+8úU‚¦Á½0Ì‹dnÓÌ(«KZÜæˆê¹Ó®¨WÔ#~i H¬KRğ@­$åéÂMÅ×ëê0:u*¥"ïÀæh(KjA%k3ò—æ _rìËŒ©>Ã˜a$ş“,ŞØï0~ÁE
ËÌù·åg‘ó¦ğóñ€·àÿo¶–üß}-ÉùßXßhåí¿àË’ÿû"óêâ™?A76VsãoMÆí	sÑ¬ŠmO/Xë‰ËU¨éh–©F$1¾\§Ñû–ío¿é:¦©æ©JšF9ãaÊÒÛİ?8ìíö³5g±£¡àaö·§ç/¸¦èôüèGú	—nøÙÃß˜ƒ99à<["k^.¥ÉeAÜ “×ViV%[U­:­ŸòS®ø„‹†ŒçSd<ÖÄ‘Æs²î¥®ÀØít{/v©±ÁÚ¯.Ùìa8æÑÃ÷p|?À¹@äÊòäyëÖÊè3¹X†dÏ0m¦+§:ëJƒ æ7äÉ~ wHj¨_'7^LÈó˜`;®(±}'7”ŒUTrh‘nO“cgà;*³mºõ¼bpUEÆÔ¤'ÇÇz2cÊ0m‰¾‡Ïç©œPÈõ—‚U½ßÎbp‡¡ÎàÒ€qu¼6“BÅÈÿøË/oE‚™l’d,±=²kÄ`ân³-Ÿ#/IO…©6uMhÛ«ÅB»¾ˆ…¶ k¾äØIÂ)!a(¬	ˆÄQğÆ×Œp[„¾7·DWyãfMÇ)ó%Ê[ã­‡xo ‚§Öµ.L¶XSš­ù¨cğ°çìrÓS-´ÕĞ›¢×Xœ5•u“’j—¡/ë– ¸ì5pëü¡°@á^ …ğÕvrüíÁ‘“‡f[õéA?ê·şü.JGpWBh™5gÉ8ÿÅÿ†ĞÊ@ûŞğoùßãõ‡yşïÑúRş÷…ä/ùÔ{Cu|Âñı
…XsŸlÂYÀŸ¨0P=–Ã£³<†š<îœÎE:! {îTd¬g—qlyECxYy6Ÿ¿bø^:m3.CZøSâ5åèÒ?À,\šQ$jÀY|”› ÁS6³½·Ù–#‚ÖóßY Ê*¹0ÕM1Û‰®ÆÃÈó™jı4Uâ6ÁM.SĞßmyØÎø!(Bƒ÷éYfJLØëÉÀ.^=Ğv^O}0	ÆHAA<Â@\à„¢IHnBbGYŸ5‘@À*’ºÈ5ß‚˜µ¤%¦Ğñë£.ÔÔ[ÊGsÕW%
]¨ß_§Sœÿ2(0šAr·§ÿÜóóáÆFAş³ùpyşÿôGœzÀ&¶#?#<§œE¤2»bç—’?.•³)œêˆÑpœKrÌ†b?ºFgPCûÑF®y@œ€\EûİzOõvªXIùû@ù««Ÿ#Û‹#eØĞ8’Y‚qlEı…”O4şbí]ıé€™Ô9u&²§sô¡F³|Ÿ­¦±7N&†~_S&G(fCŒdêGÌóáô£ëZ¢çŞ®Ì‰ÁX’$;R›hŸí6Ãhğ‘ùº^7:çç6BÑ
t
<©aÛ¼DŸŒÈ(BiÇ¹.$ì/0ä­ëiO®1üaB›5R $y¢ç;âø€Ó1»ì×Fhb#EpÀñ…î=˜€ôR^Méàág‘¶ó“øJ‹jÁËnèYåq®$¢¬Êwr•c8}bZD
tşÌeÉr!Ê$¯vÿÚİ)¡SÂÔ§ıZ
Ú8ÉÀ ŞÎ/øéB‡œxŒsQ Wá :iÍÃôÚ‰ƒÓ¤aéŸ•HNşÔƒŠàšhI¶aIµà¿^0IùÂ|R¶.guX[|'G{ú€ªÛ^àaÖúã-Ö?R(”ÒX/[Â›İb=	)ÌÚOl‰¸G§ŒãCë©ş†AëÆ°#äV%î,ç0)v¼bä²<=’Âh²Jt¬x]ÅeÉ‹M"‰o2$Y“í]˜s@•´ûuÁ`bu‰›“_0R¾òã]œÑ–6£·P(f•Z±¦·ÏÈ+…¦5QR&à¨öøàÌÈ@‘ØêbKC$°ËÇM1ß7ËµYòé„×Ö_pIôË½]ö÷½‹ ÉŸ+ÈåÑ|ü>ã9ÏiPôÍIG›ÆYŸhÛ<kÛ7\V¦Ùş=ı¹g£…u˜¡7Ş5k­k”°0)œp“ljcÄ¦h]~Ùdp è šFŒ‡üànO!·t%ß¨ğC‚ÅŞb¼`ÿ=«s_@¬¼x;
ÑìÃ7ÊY<2j¡ÁùÓÿŞ5×¿8ÿ¿ñøqÿo·/õ¿_äsÿş7ã³d²¥ÿ¯³[«­5şiŠ_VÌSüß`_¥Jx‘Œ,Wÿıûsÿ>ª‘áî*òZMw_ĞÈTÏÌP3Ë2øšof÷ïKÅóüŠrÑØÊ^’¾M±ì¤wS[ÎÙ¡†Ë^Í¬íÖùX–S©\µæh¯•¸"{™'Ï¯boLq”µMh/õ«Ånå¦KÓu›3&>w©ÿÎ)Àé€ş=*pÙ¡ŒOqå3Ç˜¡1ÿ!7J‚H¯!?ùzšeûÌ‚r”²ªZi]Î2İ|YÒ”8o%û²’l4ÌÓÌPã3G$#…¬¥º|¶VBù†zÿ¦»³› è]“BU­cÚæÄ¬Â, D´škŠ²0K»Yé­˜9ˆ,Û?H%?ü¤Ñì¢È˜ÁÛØI®ÇÇ¨ldç¡a²PÖ“Ù¹Kû/-ìÔŠ6|onè ,„©Ã<[^#n«dï •ŠYcÒ±¥•ƒàÿ#HŒè†ó™ÔQÈûıøÿ‡íG›KşÿËÈÿRZ}4õp*ÿû4ˆ)PuÂªòÏ•aˆKbpTjñğ¼_çÑp]áí8†ÒBQšÒçEC–^O‚»ë*U0Â_’Ì‹tØ*q
™`%iàãŞp'Jó³at&4ÜÍ£îöÎ›.½«äÇü‘&F8¡‡ƒŠ¸ÎÜíôË¢è–V˜­“OUF52—péG“‰ ™/¼úÏ·Î­YˆR­£PmëZÛÑj‘HkŠU’M¢pó'ÿ}ıIşÏÀ¢˜‰’Z­_ÿ+—¶Õ2õ£Hí‹ÔzÜlÁ†œOªÄ_ÿ“ıú£Ø¹ˆ&12A~Õî>qëçãq{{¨	ÙÅÙÃµúñK'
MRHzğAá…aˆ&&•İt%1Îÿ$"F2ù³œ…GRñë‰Î+iºÏ÷&“­µM^W%ú¤¢2~PzB¶†º: ¢’d)Bj©%F“˜uZê¢4ù}€)’{†¨8“*š(Æ+0Ú±O¸™hï¥~Y!Ç$„,K­Ûv8ÌùùùÌ¬H5ğT¯÷OšbA´Ö3Áó)Ê	ÅŠ®yt£ÆDw2»icD:8‰¨âp$Á`Ãœê±3dÔŒ&çAKcfüÂ¨Ì4XÒ7aØ{ÒÀİ«á7aİĞW}¸2p’Ö1œ¯bËxf®Ñúu!s<Z´Bmœ—ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ËÏò³ü,?ÿ¢Ÿÿñypl  