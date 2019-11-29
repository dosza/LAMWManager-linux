#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2826726875"
MD5="577dcfd04c147d2d9a27d7f61cb8ba59"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="21479"
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
	echo Date of packaging: Fri Nov 29 19:53:28 -03 2019
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
‹ h¡á]ì<ívÛ6²ù+>J©'qZŠ’c;­]v¯"ËÛÒ•ä$İ$G‡!™1Er	R¶ëõ¾Ëûc`!/vg ~€e;i“İ»7úa‰À`0Ì7@×õŸıÓ€ÏÓímün>İnÈßÉçAóÉöÓÆ“ÍÆ6¶7›Í§Èöƒ/ğ‰Xh„<°L×½ºî®şÿ£Ÿºî˜‹‹ñÂtÍ9ş%û¿õdk»°ÿ›;í¤ñuÿ?û§ú>±]}b²3¥ª}îOU©ºö’Ì¶L‹’µh`:~›¡G1<j9[h°¡TÛ^0ºK†S›ºSJÚŞÂ K©¾DD»Kõ'õ'JuFì’fConë›æĞBÙ4°ı¡Fg”¨²´«ÄfÄ7ƒx3BïÔ(ş>j¿‚é9PŒÎ L Á&¹Lß§™yQq×!ÍvA”œ:;S¿'zé{@û~çÙé¡ÑH[ƒÃ¡¡Ö«I.f||8wO†£ÖÑ‘±B² ¹Şî:†š¶Ÿ;ãş‹ÎëN;›«s2êÆ£Ş¸óº;ÊšÛ0ËøYkøÜPQ®R5F§C Vª‡¨·:½àªÈwØæ€*öŒ¼!ì[­ÿj_¯×¢’w{¸s®R)'‡Áü£k ju×¹çosvòñQf¶²ÅµÜàÂRÂ\ ä[3õÏÕØå[£ ;„o˜ºØe
4èÂ?°Êm\¥’ğJ¾‡®O=w¼BV‘`±dVu¶Ïèôœ Æìû@ˆ=‹,,èb›£p€SFƒ.B;P T¦fHtNõyàE>ù+™ÔÃâßÛÏD·èRw#Ç‰©®ı‰|cF²›°˜ÊªØ5•Š Ï}à˜sÆ§uéE?H@gã4ó›*€ÂÏÛµŒÚ&ìğôÌBİPZÔZ¢–STNP:M3kã:W»Æ/]OÑê7¤
à`1	=Ë2âÁ`ÆløVO(oº²Œï¼ƒ *d>MQæ4|êÔ>ŞçËd
8ƒ43M¨¬ªa-ıM´K5m¹y¢øv=²èÌŒœpCV¶Ã¼S³‰„O-QÊÚãT©d¯ıií¬}Ï±A^Ø¡˜ÏíÏéŸÓK:%Ô]’ıî°ÔúÕ¨Å?ÈëÖéèyoĞA[ö›|:}‚«¤–³lEöraòÊPv—ĞK;$õz]İ¨i¥~•¸ŠÈ¢BĞâúqÅ|¥±”¢p‘\£¤J%“„D25)+qS,››ÂJº­¼1&vaÚnJ©‚Oœ¬.C=x^XpŸJ%ÓÄX`ÕX ó}uj¢Ìyˆ<¿Uş˜ÁdvFAÊ	Wd¥"›@X '–Ã·¢&m,yğõ³>ş/Úîœ!©U/ÃÏÿïlm­Íÿ67Ÿâÿ'O·›_ãÿ/ñyî] MŠÍÙ¤]¥Ò$=<Ğæ<B“•_Q*#Äñ#ú=7l»˜®ã+ùÔRˆ|bt€uœ€—BUÌ/¦ÿuT€pü¹GşßÜÜÜ*èÿVãéWıÿÏÌÿ«U2zŞ’ƒîQ‡À7Dm½ãÖ¨‹Û¯¤İ;9è:ûdr•’`¤‘…yÅm^Ä‹Bsl…Wß“	<›.d’ûdáYöÌ†œ‚ÆÇM(q<ÖóeÕüŞ7&¢:Y)Æ„G~=ˆ\¥*‰#|¢ib´E{acXÈ(`2¹s]˜ç”QgFÌ`!ñŒÌo ]Ó‰‘1ˆél—œ…¡Ïvu=V·=ıË”¬~ g5oµ·ä3D¬Y~é›.ãí™™0ñ*ÊÌlÎtñL‡gêä­FpöïMŸ×Y4%oõãÀî«Uş’öŸ—şÍêÿÍæÖ×úÿ—Üÿ)^µId;êììÆÿ¸Ù+şsç«ÿÿZÿÿÄúSß|²®ş_ô{ä‚„©ç†&¤>„#ƒhÄ·È¿2§.xØAQlü"´ÇË§D'­Ö ı|gK#-×
<ÛúB]©Z4¤ÓĞ„wàÃÿxÄòÈÌŸÆiœi™ÄõH¿M°ŞhbYnùáïm.mÊ‹•æbbcÁKáÒA¿uçŠRq¼)î¡ÍÂñ8`Ô¥•`›±ˆÖ]n`y˜a!?…ÖóÂêcõt¹aDš?ÔÕÇ ˜V0±ü9véÅ8â c'd¼ìº·Ç‡ÙntI!†"Íï?’2sª¤ä432ÔõFÏéàh5Ô$"cK·>(DvÅ8u/˜c“\ÔCsÎô€:ŸŒã†*a,ã£î³q¿5zn¨zÄİ±'8CU%°öÁa†<“VŸÎæE”ƒÎQ§5ìê­¿ì†İŞ‰/ñ^dé5i¤šqQlı\Úº×’¶n]ôbwz’,ãò‡1hšƒ‚¢Íİhe]i¿ÊÅ$† 4såEÍ°Òã)ÄW‡sS T†~pÑ¥äuì{âM{n†ş	…@‡E—<eH´ @ğ9aöbòáŸ=õøÜ‚'7ZÆ{f6ÿ"K4vûâW¼$5ä~¯c¯XÀ'L¯ÿ•tWÂtüÕ¥óºfçâÌ!·ç *šŒm#®”«µÜ •DUWÏNÊ19ª­›ê~sİoˆ×/ŠôJ•g¼éy÷d\T!ß¥B~z®¬Âá	¡€“ÅéFƒÓ“$5ä#…Åşk9¬h›õ†6× ¦`ãU¸ÚõJÛ·oµÇ79ÔñQLöçn?>2İ:êœ¾?ïw¸`°3¢SX@:$ÌÃ—'£Öá7%3ŞÔå½ªƒ>Öç¿©%«K±túT.¯WzS‚6b¹.Å¡Q=%¬[iÊ“œ9†Úê
ĞØCÄCú8„TÖh.V /^,L „bÂÃå6µ1ÎiqÊ{fºsšÛ¯,Tì)”¬»RÁÚ™‚…Gï+p,'óIm™´û§ãQkpØ&XÀ^d¨š…¸€ÄÎ‘JzÃ´_DT¤=è‡°íÔË§-¢µg/ú/Ÿ¨$¾ş sĞ}màÎTª|¹1¸R(“¸%U‘Jv'AÇŞé İ•4¼È5CôZQ°ÑøIB>üfû	KÔ~_ÈJº÷¾?½Üá>²ì<Ûq¸x‚L{Ş»90éì’@Ë¤ı×dõ©]ŸôÇ­£•«eCÀ[¥’%–¾š›ÖJµ_ÅĞ¦öÛår¶ª’¬/cÿ*|f_yY—3«Õé€V°A„ë QIÀ.ëB+˜íl•êÃ}YÉvK»}=0ùü%’Ÿ×ç+Ò^Fİmµö~Æ=ä©hR’ŒG9š	–’‰nÊÌøÜ6ác¹Tı¸íC’ïØ:\DädÏÍË­{ÑßFøÃ6‘;†dQAÖnafÓØâ™ç…Ã00}®lÉ:@†ìy ¤··¥6éªËÁQëp|ĞC£Ù:ÙôºûãX
wdœÂˆ'!kn¶Dõ%jPÃg—P“¸Şş)ää<<¯˜’Ò—ó¶$¦°*_Iˆ•ØÕÏ²q¥2¤(&}sznÎ©ğ¸ûƒÖéÑ¾QjÛ/’„İv-zÉ/½$a ©]#ÀğM÷½»ùèµæÊ„Ã_«ìÿöõ_~Íˆ‰› L£–®ì+ß^ÿİÚY­ÿooï|½ÿıÿ¸ş»ÀÒ¯f:ó¬ÿ’ô¸Ÿ7–Hü=ëÁÊ|ÏeöÄ¡¼¶ËâAoîb£.¯—•ğºZ½şe¸]R,``øíĞÆ3ç0ˆ¦¡TãJ–ÉïZÒ%u<Ÿ´£àA¯7cæ¿Á@¼–¸„áş9¸Xœf¢ù9 îøèt8¿Ÿ‰—EÔROâ¡Ì«LkÓ@oM®ƒÒê{wÙÆ{”³yF	Â)¹}~\I¢’ŸùîùºCêš 6­ıg¡wjÑ%ç&!~`»áŒ<>ş:uCØDı´F£Áµm½¤®å7ĞüÓËÎÉ~oğ3ô÷ö;†ÚØÙÙ‡ÃAï´o¨¾Í¯úÖ}HÈ_!d£Tã#¼ãD(~–¾İÔbJë¼	i`4Xâ5\$/c†@ñ´U¹†P,mšÁ_"{é¡§bşárİó1ÉJPr[TR•ÅO®ŒÈo¾úF4‹€•£¾ë–š—Gˆª\N*B—Ä"‰ØCÀÊg@¶¨§«‡1lı4Íx„4©Õî¬Ä¡Êm @H-šÒ%yŒóñôÚJ~@ì·ˆë‘ñnRsbkq÷SK•Vw­sİwÌÌÕ‚é1´VL¯ã6i€1aO‚æ~[Ny¼!nÜ/à=Ï\ò½œ¨­úºP4B¡.ºE•!.‹U*µƒ(¿5ğg)Œ¼	b¼ÄrNÃ‡=Bü	c‚Ğy(v	”®{ ~o(JV/ˆ"‰m!©‚fáq0"É‰°•
ãºqd»Ôvñ"s&g’½i¼ã‰V"^xÊw£Î¤g 5¹³¾fvDA¦&¸X¡¹ ¸°axî‡
Oß›™[âà¡I†k!qWSúT¢JÔ©„¤Åú¸Zİ²,°>è½~à¡óã&D,À-ñ±aÑrcPLy±É Ôbf4Šx@ªDŸñ0©òÚ.şİ­ZûGDî!ğ«ë‚Í!&ùKDŸ9¦{;‘¼3 ‘O Ş„ ğ¢ 0TVw[­É,P¥çt)ñ»,…¥óİ–ö:×+^]!Å<?y[%öÆH§Q“ŸÀ‹ıLÈÚ}È£‘¸iÈ¬åHîÀQ¶;2!hP´Ô <üDŒÅı¾7ò%HrF.£©¶0!¯.tÀ‹òÌ]s l5ñe ô.wœâ9ö¤ŒPLÅ¸ÏÜE`À¾‡Á½âb”j/KóŞLú#™íUpMKoêE$©‘<š >†•™ET2{.Z“FzâhÔs«øú¶†é«* ±²b;†¹pcÇ'ªScQBv¡ÖTâ±cş»Œ…gAXraÿf±·«íîÇ†Ç?·§C|ÉãÙQGã¤²–ŠtªgÎšIÓ”ê~YoªçeñZÖôr"EeX½“G…Áórøúc´¸B7!/Áˆ‘$ªÇ»ø^@Aòè‘m4öìŸj×U‰9o¿»Ù³¿ûnÈ~âĞ ô’Áìw7r€Å%!ÜÍ~m°:6®¸ƒØS,k]vˆ7rç\"Ów	Ş˜¼yW4J.ıMì¬9rûèRÕ
¢ÜÁ›[1)W 4äÔCqÉGèezºä•µòÓµëÎ¼]ÜSU”k1Ú-–nÓ~ráçÌ7§4fî«ŞàÅÂáN×c	8ZÙ\1ë\Ì˜ôŸäûÁœ½uÁË;4g¹8ÎŞÑşXÊÚŒZ¡AL|2ÊV,=ğÎcÚŸæ zz½£aµÒÄOö¥3RéwÊ—AjÒ¦Æ<6BÚÙhäÅb2öû½ÁÈ¸E”T±“\654‰»µGøµ¾BÒ©X˜Ï½{b¥Æ/ÖÅ¦¦wNz£îÁ¯ã!„›âÁ7…+E!boİ[äKtfÂEvI™x½u×ËVÖwO¹‚9{‡»wó"µáqFü{–“³—âªy
ô¯XÜ[—¿|6›Ç“lY˜M.¨Œš±9ôø;yÇĞV,¹ÜâJtÓ÷ô½‡4
¬Nù¾  ×{„}ƒ!ŒD)g4øß?v!Ê€Œ……,_Ê¹ïÄÂ)İ“â…½ º/ê¬´îrïÑbŞœİ¶(;=ŸGØ™³/šI_y'rõÄ\P#Û55õö´ØEøˆjç’NsGo …"wÓ4à…\i"£ÒxbRîãùäª,Êá5\Æ–“Ô¢ËÊÃÁD°zİ†.Æ£¨ bc/À€®|ÜˆÛ5cf‚†‰¦+Ÿ­lßb6´ARæ<v0¤:àÌ¶·
!çòˆÃÑ‹½ÃÓ.ğÚ÷„İÇ5Eş«ã¶c2Vd÷1l''+¤—¡~©‰;„{ü)^0Ö{2¬‰¢PŞg»Xédå °9ßĞRDB¤J±¼qï™z…IóJ¬ò½[c1CÔ–÷úbÈ¡ƒ€ÒøÖàÎ^Io [ö!Ó¼Úİ}­½Øïh'°”%í\†”¿wó.Û¿ÿ†òñ†—¦Q£Lã¯5q·VÃ·|ZmßÃ×¤D'Îñm¥	[ï¶ÆÇ“ÓqwÔ9NşRÂ<÷Bvòİ%)İ~iLƒ>‡ñx¿3|1êõùy:Héğ¦¶)ª÷¥ïEQÇ¯Ï]oAùİRÓ¹ÖÙéBãÚ<²-ŠÚ3q„…ĞB`ìRòB‹ ‰¯Ÿ…§†&¥-S'a³ÓÍEõË…óQ–(Î–øìğËÄò#!÷@‘Ùœşû›ÌŞƒqoÃë—ŠŠ³€ÔtOº<QÊNã	¿o$*	À(Ëš<DŸ`Ñ%SÚ¾ÇBqb/EécóîÖPïvÉêŠÇ(ÊÔŸåOŠ`rmQ­’#{™e)@Y@TîÕò0«$¦¬YÂ°÷æÒL"Wf<Ê®Å¾_.tìÔj×½~çäˆ~ãâùÂ}okæÂ‚˜”|Ü ûÉ;êFn~î T5iÍ…‰b´7ÿ9`z@§tB‰‡`¦{ÆşK
–$ãM7(yrVE*Yûuòó[~=ÌIšJl,bíÁ×O8°òS²±AªäÈüğO”8À@òÿ§lî\[»ÎS_È`³U— "À´ä|ON\ñ– „.ÈÇ¢L"xÁ÷OÑ¤ä„^ô…³ÆË¤#ïUª1k3>øŒÿÿÂ=fÆE”¤ä?„&¡û.-Ü¿`Ş—rHêŒcãìÏ…Æ«0Ã<+À„ÏÀÕ!ºDˆm¬ä¥}q~`õ†¿ùA„àÚZ`Ş–vx…a‰È#Ç‰ÙÌC¸4w„%ÒĞØŒé0>¤â€àYê¸…r’İPŒF2‚_Ù9ß>uÍ“|ÕØ–V3DV'îıwîwÕ‰‚E—\œ>üèêG2T])cŠÏP?Sá}(İÀãuÍ•ãZ¡3¥O.~gèLŞâ»Êk³î´uĞC°–9•TË£Ÿµq8QKX£J>‡Ü wI88­‘X5îxÔä:ù*a’y/„Ü½”µÈ²;²Je5)Å¨‚«ıº¼ÿ!j	sjŸ­üS-”ÏfAnıM¯³h’Âıo{_÷ÕF’ìy_UEvI·¯%!?ÆX‹v3ƒ {fLB*pµ%•nU	L»½ÿË>İ³ûrçìÃİÇîl#"?*3+K{Ü»è©*¿32222âx_õ	¶S[Î‚hÈê-wúÆ?U™j£fdœßÿÏ0zB¿š·~m­nÌˆ(•~EİÜÁv% ŞáÙ%ış?ÙEğKĞ=JJµTN–JzTQlª
	b¿FZ«Ô%šôàšÒ	2»Œ²·FÙÏºQ*®ÓÛú[è1,ºÃı¿¢NèğB’zænŒ³ \ÅPÀşáÑBùÏ£L
õúù0>3xÁÛ+s|¸ËªTˆïµïö»GO¨~Áí*Ó^¯~…Ã•G80~³08˜©9ğKûäÊ™Êæ¬¬®nÔëÓ1:ß£2'­Ñus•ÀS‘ˆT¬*º[êï¼ŠêÆRóäV}òSs°TH4/'6Ä™SYÎ¿ÀÛÍ}a´ú‚›AÀ¦Îe-U¹©Ğ(S.	ŒªÉ‚:ÑQj«Fïğ FöÚU‹ÈB'#™q­±Öh‰}6píDkM~²Ár1’Ë‘z2MŠ”^õä¬˜ÈóÂ´æ!ÓE‹‘ÂıÙ¤ßËF9H>¤kÇ§?¯†İ¢?ğ/Ãÿ	G,Á|8Iâï‹´7²Áÿ>ˆÎÎò_Ó‰øÇËv4îãWàÜx«?hs½İğÓ`œòû~şÿÏI(~£§'ĞÌúÙHÒŸù#´ßĞ¥Mûš§QÅÁÒJ3í«J2ˆyÕ“w¼„¤/ZÆœO†°`Î“Œÿ@Sñ#	N{ı4 ï¡ìö[ì£ü;Á²èØ?ÎxNã±HA8,ïÂ¡öUT:z<\hdà+ê×øWøôTşÊjÍŠo?“BßäËi¦¾ˆâ'Ã7è	p®Ëµ6~›Â	ı¦#ñ¨„Eü‡uŞıIOÄYìUĞÇ.&#"
¤”$ÅÕ}‘I³‰6b0¤¸µiáğ"=i_E–|à/ÃÓh0¤A$7Fcá4^Xz¹ˆÛñ­ÃMbò¬‘0ŠQ‡¾ —¯Èi–l0ÚSi1r%1ˆ/ÏËí3¸ #Ù¿ËZârÿr;¯n"AYçå\jÎ1Œ8‘gƒÓYtYé¬zÒ$Q	»Ó¼Q}çt$«¯7Z'4Pãî¸ˆÿl­åW®SÁÂ³0»PİrdV!m“^>RšÀKü˜Áò:×Ñ•ìËCDf€ ÌÂ¾=«ãpArØö	uó)‡3%ìö8¾ëÏHp<7¤=­ıÜmƒh×®¥J?IÚ(¯²04*•İ×]OÁ@¥ÜHÄ2nqëïé… 6,ViVŠjøfŞ”†PDkå.¢/¨ÏİùÁDû&ó‘ÛkY%Íİ!)š)X#V”øŠt^j ã×>8Rã†c€<ù€-š^,¸dÔ‹'YÚñAzôóSìX³
ª‰lºt)rÇc‘S\+ÃÁ_X •	ëÿì«
ÍD’@°ùÕº BC"Fêñ7ğ¢+ïâcíŞŞ{œMtf+Ìóbê²Ü»X¼åƒ¯UR1ôû¸G )ÚG÷â$:'C7J»Éét<àÖfXşZ5ŒÌbJÏf=§é«+¿l²9¿µ"´Éw= >ãœì´G´[˜o©//³0ù²¸q-rø‰ûÕ‚é'pMÒ‡ëáĞ,æz3ˆe”–0Wd0§Ò2—,,`÷!6˜Û@OP˜8<9\&÷¬˜ÚAÅÎ*¦Â7	†FG3¼Î$çëníì½ê–§ô¼‚‹õMü‚ğâ±ü‰g¸ô8¸qÑ™ÇÓ­H	*§5„ãÌ•İ«S-Ó>[³_°_J÷~Ú<iÖŠP1Íæ9«Ã´˜uÃ]"9îo@{¯åväö:r8}L—#ÃãH:Íö7ºw#ÛÛ~OÅy_MioĞÍrr¡æ¾BŞgòRnGÖj6©úL¹`Ÿ8SĞ–Ùs5«ÓÎöÌïô <ÃC,ÿº¢›¤\ÛUìfb±[÷[ÜAŒÖ†f&z]š7í‚ª¹l/w?i¢m	NÊ"Åíb9PJ¹QÃÁ¢u¼tó~ÌV¬|jæ”n¶ıCq§ü¨kl˜CsÓì˜èDâÂ”ŸşÜ¯®m1—h?oG#Ôä…+ÁÏÑ€¼0¸gK$§1][O„9VÍ/'`CóœÊ‹«ÜB£ŠÕ¦X+Ç äøf+®6´÷9ïZ¯“W}= ÚöŞ(x•ªé³'ó<!•¨nTâBësë„T‘»[øüpóğoyÁrëzRËßb5UŠj5¨ËÍ%­^Á_®İ[Y²^P#_ @Q1Ko/Q É	r£É‡=‹éxXÌ—ßÒY„>®•%şÃĞÉ¾å§J4ˆyŠ„Çı Ò1#mÀeAEş®¸ÆS¨dK'mlÈŠ¨$Îwæ•&FÚ]}C|PÑ‘qH_j²¦õåß~ú¸ä´*Y…b3V™nò\™Ú^r}\ÁVVZë‡ãCl_zúg´8–>j~«±êÃ	 €Étüã£—õÇşŸŸQ/Ÿò…ÈTn/¢$£	ş>Ÿ¤ôöß§»¼¶¯[ŒŸøÍ·ñ(lÌMS§Iõ¯ş>óEYB…HÃ7F¡*«Œgå™Ÿ6m¤WO›¢/º¥›=F‚5:M¼Â¼à˜ÌUÏ/f[lL¾«ud)_˜XßöP²I'C(nÀ=TkËÒ³°‹×u)ìÚşŒlŸ tWğ˜ÎêìLìàImæå‡0Yñ++ŒÊ©T[³0Ì|Y3äk—æ+Á¸¤Õá3UÀZy%›5!/`ıº-pàÇúXXõ÷Fábœó)ÃF.•ı	¶“nO8­/ipœ§¼)N›åkèƒF(ÎÃâY0ñ:%F#	7iš-€Aé’ûK‘'˜Å¶¨Ø…“?˜ß
 úÉCNDú¹F¾ıŒüÚgyeÎ³_2ş_k­½Ş²ã´VïâÜá¿ÍÃ»ÈñßV-ÿÍşf„ùsÌÆvû†íğ0`c¾Á¹àĞ°Ú(Ôœù†!á¥Â{ğåƒzYZA¢š/ƒñæU_íî?ßÜe?lî S{—Wû"Æ	º|Ê(Õ?lnmwjK'á›ÖÆZ{´¤B†¿Ş<ÜŞİç¯VáİZş®{ü6âï6·ğõºz¼·ıêpçHdiåÉ%¬ªÆñ®g”IÉÖ„›?ŞU¬çÏ9Ò¬h&<Ş<8êíî¿ø¾‹¢“ß¼¸åÆ`òî·¼^ËŸÔ/¦Yj¾êı·!½Ä#fZÌª
¬Ÿ%èø3øŞŠ—¾é’¡=ÅBô‚ag¦Ô£¿ŒG¥î,Âşd0V‡“Sµ? ºØ˜œ9e´Ìû"À690öñúÜî(¬pØ¿×Î6B ÂhLoyòtî#NQMLSvÃ¦Ş8Æcf«È\»ÛJëÄgƒ8L5ğo|öíÓv\€Û¡şÒÔS.“æàŞÙä>C«Pvq¬ëZ»MªLt“m>Ü•V•ÅŠFOÙ4Ã¾.ÕÏâéxÀâ„µ>¢Ÿ^¡8<¹a£àqgioo{É1fæùµvñ]F8<Úf§(4+Ï	k‘oFÂPÄåAV‹uÁí9ä]}%}-Å§Ÿ¸ïã€Wƒä<e|(a\åoIŠDò ÕïĞŒ¡J´e%°0à¦åÚr¥”Ÿk8A5Çph]¼â’è6ÔB…Ò7x‚²GgyÅE€ß~k¢LEeqÚS­¥ˆí*Z|*ÃôÀºä­*­}€¯ÍæI³É>®èP÷"öIğ¢ 6¹¦Råò¡¸ĞÃióMPÿe³ş÷ÕúŸ6~Z1‘´`ü!¦…y8ß³`858!> ŸM»UydëÊÛGHƒ²é„k'šáI[deÓ=Øİ9:ÚŞêmnşK3CÙh¢òÉ±™ƒ~Û%Ë‹mAÎTI÷(¯£S+<aúTÚnÏõ¦s“	›&áÊ}’$¸B"•”È{´°B¡h,TJŞù9ÒÆ¦–çİÈKÒ$gNK_eT­…E-EbA^†a‚ücTªWÅ¤ô•@ÅĞ¤“ E¦z…î!EÎ„RiQ2´å¡kS¹µ–Ïp{Âº:µÖ†ú­V0¬¨ü)ß˜pİwjkê©èŒ©X´`.™Ôq°bê¥¨”XÆˆøØ0RÆœóp¢Ù`†ô$’×«‡°Ñ0^Ñ‡•®åñ4Ùı¦b“DLúIÄ¸÷œ‰“í;PoŒ€CÂv‚n^â7Íàã3'ç+1©^®Ò`áqnÚ:Ì”¨F²91ü¼ÎêLÍ,£[—zååGÌÂğÏrşõÔl }í3TMŠ˜±›fe*ä2-çahuØ×Òù“ñºïÊ6 ªüÒÉ‚,0Î„tTJZù¢®¦PuğşŠiôC’‘Ì¦J˜uåzd™_Ç~ÚÌ({&¦ÆÂú¹3'e¡ëÑšdµ¶(*¹$RãVY¿¾­ĞÚx³1¸&½}ò 8aJ¯uBĞÅ4Ëû–ŞUŞ¶Ô¢ë9×jc•Ã`Æq&§İÇ@lq0ŠVHZBcsœ{n"&!ì(¬K¥!oâélšPß$Æ­SÃ2‘UÄÉê1>¹_ÿ€B«$Ó19øbdsô™D0åçaz2Ş†ã¬ïF£$ôìÛ6şOg&âB¡ïˆ)˜	íÜi6±N3:rğó0ÓVG«HSÁ~R]xìr;Ô¿Ê¸„¤Òœ½Ïêu˜¸÷÷µUÄJÀ·¬¦Ò@…^Y¨*WÒÒ6¢Œ´ƒ¦qã0#€²ƒ?@xºú†%WQ2’o|Ç¹•ØùİMGŒ"ÍG:(kš¡LŠ ìp:±uã<Iâ~˜¦qzŸëE·48GD@Y¿ÿ\£§ZÑ`tÈ	‚ÀÂ4á!—z>M¯,>µZ˜ˆ<éŒéØ0LÎñ$HW×^…»ãƒ7«?É÷£”Â—o‘tÎ	sJL—üXûé·-VÇÿ>E%]lªó¥?Ğ¨4°gÊ"{1÷´ıDÅO¨µ¸‡B¥‚­jm˜P¡ˆ¢›2L­>?“ ;#HİI<b,Bàş™ªc"ˆs¹~Ä	¯ãËútL±Eº"„ƒ;q–d¨ŸEïë£c9+®’yÊ«‡)	S5Q©½p´IÅ¶×>(NW‡u\ÜÅ"ÿ-<j÷pÆDcyÁ^ÿÌ™ëª¾¢çæÖ~bÏy§¸;O5‰@òŸ0+1ôñ.xĞ‰ÿ#hâöc¿/ÿçÁ£¶ÿgíAkõîşç.şûã¿?pÅÿñu*_0ĞÏëİå.
RZ°ÍüäEv¯N’”aŸ@7çÀù’•èÈµãÖ1na¡ùEƒ°‡fB7¦qî·šç£{é¤ïÈÁ­R|Ï3N…ºÌ»
ËÏg€íL˜51)Fg«¬zr&¡b¬Ó›„†FRíĞCèÂoÖi<
«}p'@åìÎæå˜×Zô$¼ºJ¢RB1ìşœ±Ûq¹]1|ˆhb–¥Æ-¯ªào«×GíwxäJ±AÂ
…8PÄDPÍRZş-<òà—¶ÿ7Ù¸2¶@i”B•.åº©¢„¤õĞ×¼R#^>×…®ÈW÷PÃ‘æİeú3²Ñ’Ù869•È¤7wÕ›{GsëÅ4³+)Š:7A4ìfA6M¹„MŞÃ9c»î|ë¦Ê©ş?:îÒÍœÒ'“†ålhüVşjo¿÷êx‡¯xñFª¯7äIÓ†¥YòÀWuÈSåH–xx’QğK8Æ£©ù~ÿßÿ7¬Ò4>MP=‚zÄaîVÇC.O®â¡HZeV[Æ[mV‡c@k…­èÜ^\¦ğ˜[ÿ&Ï HâÄ©_ˆ‘fÈ:U #ZA«fT¥“/údéSU[BH¾Fj³©¨"b¢¤Œ¸öMş–Ú¸Š-@&ÃŠåˆkÖ+¾ ÕM­$#¯h)1Îñ‹·aÿİ6©å >Øšhéâ¾­Ÿ«ù¸¤Œ›oîmîmíü°­â¢)nÃ	ÿ‰æ%V€×s»iFÔvÀµNi•íkİ[E´/ìš¡M'X².U8ê€Ö”w,o%/_D1)ŒŒÓ·ñ%–%ø­5V«æ`°9£±·½½Õ;>@î¶;S§•Ş³­ğ4
 ï«ÍıI8şËÖ÷Lt–ñŞ‹§õ!˜Ñj&áv×áÿ|:i¿}’¿]rÏ§­î’zÄƒ¶ñó'ZèfÙÜÇÒº)å-÷Ù4¥Í§hµ¾QQ›) âl&Tp§&ìuåqÔc.hÊx€´s’»Òp,õ´Ö6ùmâN!Ïw6÷zÏ L¯‹&¥~©"Ğ2³vVĞ Y?~Š}à}æ»j“—µƒ(utBîT‹W£Óğèùxzæ0M„§ âš÷ø×Ş ßáÕ(Ôğ6/«wOˆ#Î|­×œ{O¾CDßã±zÎıµ1®Cº|d3ci±E¬úı?‚XÎE¸²5âĞ)Tp›ûâõî”Àè{Ã,µáhÅ."àŒêõÉ49ÕòøSıl*l~ÂVëí>bA§aö—ÃíÇŒôìgÁt˜yø†âqnñ'_h$D º {ÛÃYÂkoÎşwu‘„+JIfL9&7?¬ä¨Ø°WªÒ•[Bd µË6¸<EKUÂ¬æ2B{2‡ñ¡R_Å(ií2"µ Ñ“!¦V%¢ÖÁ~Ô©E˜üdÜÍâÉÙŒ0Úâ÷ÂŞ)ï
¤V0œéüeó‡MîÓå×òdªvQ€ ™¡ jÜv.…¹G¥65±¦JÑlª64©Y3©Q:e)±ÂIê‰[!Ş¢š!µbNñXVÙhÒYjÂÿ¸¬ñ\F›Y7Ç_¦sõîæ¯×…Liª²Á«EìPå=¦HYºÊÔZ<šR£ö9“p#EG$|aÌü<ş—aèJbgóïèQ£yâ’”n›øN‘§’çqÔµ”æuÅRœæyuAµl…áá‡òıã1²’5kÑ†V³³ÇÊÛıV†šƒ}àWKĞRœÔ^,6jïÎ:g«	„4+ì"(ÉÚû¡`Y.yÇs°VGmwçyWµ÷÷?Î%!GLd¼%qÅRú°bDı…Y§äUwÀ‚4h] ­××†Ù[ƒôZ×¼Ëé¸»İ#°an )½-5Hen ŞäXÉhPeg9>Üí(Àâö“á+¹¨UìÉØ,3Py[";¨ZhÍ>"6ìî¼ØŞënwaô7_oƒàG°z}õÃqJ\s÷(
¡¬Ã(tğ—üÑ+"H«Wlh:Ìa­¯7÷6_mö^¼ŞÒ*~+¾¤M¸Lêø%ñ?¹Ø²¾ÜVÉ˜lofÑmASË<±ê÷·i­ÏÀï68*®.éc·”û²	:Ä§œŞ;9Š¶ù:u¼ç¢å«0Ó„¨ƒQnH|Ñx¢”Ô
‚RÔ —áJˆèò}ä?h Qƒföˆ[•œª„ıŠlåp{w{³»İl<=C0É‰µ×hkê® Üü ¤œ[2K0F;ÇYÊGÔéèèĞ’tfwóDD %£ª•¶3¥oŸo–èÏÇ™¥ŞÊ]³	%EñG	UõÆç&•3øùk‹Ú¯	(!Íøi}ÜJğz$Kfp“;ÀSÓ‹“®L¡Wr‰bãåõ‡¶LÅ£¹KU[g‚ (°°&³{ÙŞ÷%z	Æ#ŸÑ£¦™ôka÷YÕ¢ šÈ	ÈªCÏŒÊçRO±ÈÛ2zµ}Äoú^¢À!zhˆáÉKK;/œGĞ^t–ış¤G_á}A†Y²dõ‹òT%Èª—ãa¢Y‡Ã²ğ´›…yÁd¶ßsÏêÆø,aFk^85µO3"ÛWÓm{k >E“épˆ3Âe,,¿öA½×ÌjlÊ[œìù~¼YÌ>cT9äÄ£GXığ¢dŒô°ycá\Fó2IÏmçP•¯Ò›5ê:­'ÖÛØ.`Ùo³£$:7¯Ï­ëûx]%‘¶µR	7±Ø27xtQĞõ¢pû@>0ò&kf¥…km”VkÔªØ¨åÅGj‹qF›-õÌ1Ö7›41qé…FÂPÂ8ˆÑğ2¢@ËAÉôK…Âg:*ˆ¯Õé—³¯7_í L²yĞÛÙÛÚşkg•Uš\„	IYŒwwp¼ÒŒŒ›c7ûıI£Õ>¤›‰¨iäLĞ¶$‰‡/Ãó$W~`6…ˆ^¨ºEÎN û½¿8ÍÅÔèbé[ü“oMÎx¥	›<ìš[VĞØ>bz„¶YƒÖfÕ.Ù rSğ…F…Ğğ2ºDÃ·úÓƒa›-Ã8G‡I2d+jE“ş¾s ä†Bcğ˜>ÿMŒÄj0ôA´Ş[ãèÊÍ‡roëûÅ(ÚÒ;¨ÕŒ»n[ä²›IEm¨¹ZœuónªT])µÎrœŞÂO”¿×ïqöĞI!m¦æ[k¦âÊü(ŸmL“åJ…WïÓlíÀÜƒ”Ìè€ÚÁD9v÷µòå>B­®³îÎ«½#à^\I‹|#`øÄxWSÄÑ›/HrD²9Bî*¦Œ¯HÏ8©£L[¥3Vğ"›Y•N+‚j^n××yì1d¸â‰ô?( zNŠ>u½î'ívãïJ¤ÔbÎw0lœÇñù0l€%H›@‰qŠ@zW|Wé‰ò8:aæÓY2Ç/Ï@ôWmtê¤b„ÓG9ç.Ìßº"K£Ã®¤rÚ4º ø‹ı,I4V‰9¸9wq>Pz¥ty8x¯rGß_Y¶GÜnÄ»
±ò{êë—T¦n¸aÎ4ô›¡ ´1½yåÃ%ıË Êî«Ó^uø¢[%ÅEÄ#lêÊ<K‡ª¼LrDÎ¡DDû 0.½bYL·N+ˆã7©9¿%tÌÔæJ›­ÜÄi¾o×kßì}µ\]`=ï9{×Ô
Ğöh|¿S„nW@_ã0gí5Ê}¯¶üÒl; -¾§À»üeS½x~¼³+fKßãL›œÅ‹?=¨íª‡qê@rN}‚Ãwæ’»Á¨ïóª0Ò²y‰ƒä]˜õø	,êE3“w=B~AK¤9£%ÄÄ×;{ú€ÙĞ®sW’Ü\ö®˜iÈœŒõ4<‹Étœ.ØE€æÊ¬¶ğ¤Hú‘rQÛvºÇò¶¼â ºèùaV	ÄV•­r¥Ê±òñ[e˜ZÒÚç²!BÎ«–¹8ÑÌÈ‹ªÍWˆ˜À€‹ÊñÉ‡‡û™Ñ[}1ô#Cû6·s³Sğ›$yÑ=‹E}5MœÕÆ›1Rƒ•JfªşEyqÏEîa8	¢¬%3,©õ8sUüÔ×ilR[ë>Ç-F~ÁñK¥=©²ÓËM÷„Ûj;K]´áº÷Kë­p€çeí‡Wä±"Lš0OÊ³@$”^.”Å2À(ô° ñˆ­Óïùw Úªúh-+^”Y¢ø™]ˆeÖOgE;ÔÊŞ¿ŞîÀÄ\µ«Ï'ùWV?,íæÜ|%¡ÒdLY<³9h1g1“1ñÄ¨&"^]fÇ…ÕÆC¿‹²'‡¬ôÅÓÍ§¸ù_8è%ôŠh„g5@z	ã¸¬û•-¯ÃJß<¬²ô÷Hç{¢·0êRÆÏÎÈSYÊÍqPó„ŸYÚiV_Pbq ¢ş[ü½Âª:@!/`ù¢â‹p(UTØ(#†É‚806…eŠ¨Êg”1{èˆáÕdĞ¥›Àú¬ ä¨£–İ£$AÛÔ¨²˜©‘£åÖÃÉzµ®#Lø]gyh
3ş9)*‚yïï3Â\0Œ~	‰Éz«…@ş\Å˜0(VÚº”1»W¯YîÄŒCŠ‰Á ÈÁ¡¿Ï¶„PÄQÂÁ€#‘P¸‚¤H˜#BÊ@ó·’j¥ºO³]`<0•ceÔş¬E¤7ßè¿r¡JğÍmXà#"ƒ	˜}¤ÿû?Š½…?ZdC¢öQÁšÂĞ{~ßÅqˆ ,Š³à`x†'c7^“³=¶†v’. ·Ö[í­Z.\yWÌÍªĞœ¼1\–E×kËºÕ–k6f]OUíZõ3ñ¼-aN«vV¶2±şÈpæª2ã;;03\èÔëk±È‘hÿ*˜x¸üìGÃ>ÅâäşJ’°Æ÷£`~Vç‹ÜV¬HB¤[’3½Zr¾½3¡n%„Iw:[(Kı&×´e€R2º|ÍPCZ{'Áå¡I+•ç(^Ó‹MiĞrŠ¸[U	„½ËÎÙ}”„‘6²›[Ï³øx^xDpQâ,îÆçÂ5·öİ¿‡	ˆèÒÊ·ºˆÌfÕğñPnteÑîØ<AÒŒeW1ƒ)q©«um±KK+¡t7&œT‹‡—:qÏ!ôÅù½ÿç%A”>YğáúJåk-¡Û™·bv3xî/!JÚÂVÉnÁT”ÄnWº2Ì©ä*ñ—¢ú¦äîYÉ†Ä­’®ÃÛK·¶Û`Ö%›ó,ş]ËÀE¡”ŞRRo¦äÄWXÕ¬z3êK³{B40­'sÓ"ÇV33:Ù-ì8Ÿc÷0ãğ‰h÷kš¹VÅî_óo éå ¾ü±n²Š8úQ?wÇ›z^7rî_ÔÜAx§Ú>ı«ş|“ÍÓ£]WŒÏ€ÈÃŸ,ŞT	m¨“©ëéazSy¯vw^ìõ6_A½×û[Ûp¯À£ƒ”ÁöÌ×bK-€UşNVÈFäñŠ]ÁRÒoò¦vN«³†UãÓ81Gâ	òçÑYH¦eu 3TŠ(9bJDGn^ki¥|¹‚hlP¸i·áÚÉ¦ş }4¸däÙû`a§ãFuô—‘ˆG†Ù=ÛCİ]µÄOØs	UK#èÒ.²*”$Q€Æîì ŞQŞâEè›“{Ër0bÛìŠ*ã¼sóæ Û‰¡Ò,>ªÒ™µy%»–sƒ,l³ÌëòEr§Ù–°°‹¸ö7ÄkLêÓ†ág‰ÿóèÁƒü7ü¾nÇÿY}Ô¾Ã»Ã».ş[Y¼Ÿ¾Å“{¦PÜÄ.ãu6<lÎH3µËËËÆEtÄÜ²7N“æ ÎÍ.†ı©óÚê_)ÊÇuho\WQƒ‚ä¡Âqä3y¥•·gy…)AŠ¶áCÌOà}û¯·vÿF‘<à%ª¨ğaïÇıÃ­îúú¿“¤Œ9KSÔ9´‡ ®ÃøLĞw]³¿©Ã¡Í{ÅßzL"ô¦$VhÎºäïŸ\PFÚ^eDGe>@[?²N‡Õï±Ÿ4;R­C§Æàdúx!‹-ƒãB½.²sh"v#ã:ˆYı%+R¦?_<GıZ9Íë×ÂóÈzfğ*àmk2I¿0şg»õhıaÿsíÑÿ¿ãÿ7Æÿ\sá½1(kNéb€:wcÇ¸@)¤³ôË„|ËuAEBk\F9Ix0È©i@³@y ë©€¢¿’ç4Ä×ù;‹’4û†™XQÂê˜ãŞşÑÎKôRßÛÂ ¿J£9³èìªHé+R?tx˜¬²öj)é ÉÃÔ'ÓYò¿çjÅS’²PGköÜ¥§z¸¹ów¶µÏ6_?ßÙŞ;Úæ“åÉS¯À‘ÕÓÏyº!™Å}¦™•Ñíşºõª·µy´‰¾İ¾÷‰ˆ—?(˜…h/}Ï©ği‰X/ÜŞ}cáó`šyL¿&e;5
&MTı“ì$;ˆ/Ã„<T·‚qÙşVz”è”üK@)½·€«:ºT÷IvOÀ®ı‰’áƒc‚Šb­‡Õu¶{Ô-¼xl¿àwÂ¯Üá¥ó)•MC. Â^î‘ìmuüó1"¬Ê×Âıo4$=5¢ÆSqY§=u€^uVõ,*˜ı"å¿şUw¸ÎÌç\¿¥³IIOáBß£T aı²¤Æ¢ˆ\­Aî{"1ÈÙışhÿ ÖåûÁ9
eI1ÄãŠÅ¸p¤µÎ€6ñÉ<}fş4hLÏFˆÎyRôd­Õ~ì9 Sôâ ^¸E³.¥’İÔx 7ñãî$õõµµµGzÈİJ¤Æ'÷™B÷—ÕSõÆò¨ê$­Ç§z®ëµEÚu	NG+÷£hÜûÇ{×m#ß˜›fV>Q³Š ¡Üé	ô°Ñj´|ÏrÓ™9¦]}0Û}EªEcöĞŒõ²h˜…4V‘	Š¤n«ìÎRû&[â=™ç²â•¢îh ;+³Ê"¨lL7fÙì3Ïaª›ŸnÌ2ÌÇÜ<~ËÛè'·Y•µoXæöfeæì3»Ù¦~ÎöH˜İ¹ú¼ÎQê|éÔ~*‘l‡İO£ˆÙ/m¿’¶Ÿ€Ù£C©#ä¼á<ÊŞNO‰1ü<š`è™`&²)Å~‹œ¯€Š‚SC‡o·.#:&¢‚™®·³µ-SÍ€„Gi¼¤¼«§B‹04/·›.ìOF‰Z+·Â’Ó’øç°Ÿ¡ÛHU‹¢+*„ÓIĞõ>À¦)ûòz{ï¸·s´ıÚHï–³šÁïªÈ8!ÕŠj€Hû.‹‰©U,l½Ñ"îc>—%şzÉÓª‘?'->°[g~`¼èÓ­*kaiŒ‡ª&şnÉÓ|ÍsúaÁ###iñGÑ¥OŠpĞ	Ó&	‹(«£!µ]ÅÇ:¤lÀ¹ºñşßÓ}Íaë¸nÖÂ@Ì+A0JLnBjğÁô½ÃíÍ]*Uğ~½FCU˜ğ&ÏJòQ–©$:r¢˜3cÔSÚé,/rCÍ‰˜V‰Ø ÎÉ7OØÏÚ¯;¾+àç·áfÎfó¤Ñì}dUÎ¿ğQÉÎdc¸§¥Æ]„õî³ø~ÀïSŒlÊ¢1ñ2Œzb°Ô “znlmT/Æ³$'äÒ Â£¦hj3ÎÓ¦İ\˜q;Ê€cÊAâmôÏÎéùÉ­Â¦)jP´' ıNq[YÚúƒVï1¦Xq”¤fKÄÉ¤’ğ•Ğj<nPÎŠç™¶ 	S+÷»İŞæáku\Ğ¥%
µÄ-ªñ"¾È[yöâàXÊOha½¯¤)éLDR}@GÃ×ß½ô1f<Z	ÀZOFŸÉÓãÁáöË¿vğ<»´âUµ¦azgãnĞZ¨}%íqç[°%šÕë|Ç†}ªƒşRƒA}Â¯çcÒHI½wšDƒsàœÙÙD<âOzXTc8yG ˆÈWu~³[çp¹®ıé‚làÖ1·5ÿ¶š,~æ©øƒ5øs¶ƒ»Eê…~}Um<ë	hß{·?˜ 8V·_mÿ•ı°y¸ƒÜ£ëy?ö±ÂÇ'†:•ÅäÆXæÄeˆõb4pÜ{4ÜWØZ¢Ó÷­V}^€¼wz½f¥~ÁÁc½?iûA”ÄmùÖÈyÜÊß¾ÏÒL~²wÚ›ó·ıº¬	÷óá4[Ë¿ÑsßËah;ş(O¡¥ÓÓ®@f£à]Èøô‚Dƒ!CPÍ0'AÂä‘KîÁà”Ã?ŠV	5ğ`+xØH•q8w¦ wÉëÙ‡§L(9Lø÷¦H_€ìÅĞ‡cÒDƒ¬ÁÆñ¸ıõEauôì¸¥I¿yó“ç•Ú0¹-]”şÅ\Åzé6ú9ÚûqsNö¥,–Ãj®$€İN¶µ(Û¥ƒw4y8÷ß¢^äß‘PFˆùƒÓ¨¾ŞøSs’„H"ˆÕŸkIP&.Q3i+×=>@2`ßmC3»·¢-eß¬‹|¯4»9¯‹ºÔ4gÏ^ú‚›¶”ÎP$«áÿOjÎ¡Qí/5iÌ©97J/juDÓ¹b+"nŸ&ÁÎ+À÷£÷Àñ×Pê+æVúòw%zbş·/ÊßjÆögd)q–•VüÅÈ*¿ãÛnYz¼d¿ÚÎ×jÜƒïBüÂ¡p´]o¬£pÅd7GvjíüG'Ù´ééŠu‰O9Õ‘ÙLMØ‡Ğ:W"¨³á±7…‘Ö¿¶Wéæ ş£ÁÃuø\]{[vf"ïÜ {›f½ŞêQ~dÃ E,ıSZƒ6â¼5í¼5KÈİëÿŒH(dŸ	ÛQ®}5Ïg,½gÁû'ü
Ç4{8Ébøg?Ëï®Ş„-˜ş”{×ÓÅçÖöÇ7ñÄzÅ+È3cÔfõö‰¼BÊ˜õæUÌüHd|ºVC·ì4ìŒÂô·ÿ’µûÄ›­›Ì”ÖX¨ãp:VhŒ)®ó~ûÏùÕiæ7eõÅìçiš)Ó^ªöLZd²eÂ	Ãût„l€tRÌ
.‚hˆ÷ä˜D°•ù­!Ó Ù#­áv\ÁP£,Ÿ›•ÕrHVJ:@CŠ
G¾P^…¤š©¸8«Ğ	•ç“åù­Çe4‡»…
ÓaĞxûƒÅ[‹€ŒŒÙ>_+O¬µb·…V¶ğÜÆ[j9~·ß=ÒR£.õzïøõóíC{±¦Ú6ÁÒ,´d»1Ø+V­‡–¬ïEÇÆ'ã¼/{q†u¨ºy×û/öüJn y‹ùâj—E¥ÁçÓ”¬H&*:Å}	£’(e
Ÿf·#FHS‰Â3øFöoÿÉvÎ0†¢¢æ•!Úm`¥úr'ãnÙ3ØçÚÿş_Öş-¿
ö¿­öúı×ı×û¯€i¤~30nÚŸ
gğg21&«¢/bïË/°ÄÍ+œ¢wé:E«³^~(}÷¯6W¸÷Ñó¸Ü*qË]Ùšˆ‚ë)šDã /’Ç°Ê[$ƒÊ{Ñ0`š{§õp€—º‹æ¥,Wÿ‰
½jÏ8êïws\ëÌótŒP_Š#“şM:&è¨ğğ/(;jöéíÏ‹çQ¿‡À¤
Pƒ„fÕU¦’~°R©¶è‰uçIÛúsçÌXu-‡´ë6Ş<{@Ï„™	ü~¨~+ËxúˆP±TÚBï(fm½¥ûq
ßi8õ!Ú<Ğê<ïù»¸É¯éY±éE£Ñ`fZáÀËêÉ…ùFÃ%‹È6‡b"7­—1ĞSîÃ£{z	wúä<í,×0æ‰š‡/
VU‡'ˆI”–±±<eœ\ù^Ä¼:ÃFùßE‡İyÇÉ`·:6¥Ç] ˜8£âÍ½gy6Q7sâ|öÈ`Y.îTZ££ã	(t]äl®¨NyRVÈ“šÄWĞÚO~ÁşÁAGÇ,E}lN&ı÷ˆŠ	Ô+(y(ÕŠ‡mª›ú|ÃAs8fõô¬è-jÅ=af¬J6ÒHbÂÈç°¿;Î˜£–ı„á×®7E·¨à„áÊ¼„šÁÛÁÓ	´„Óa(GÂMJV ‡x3 ]I/N¨dDö æ£Šøiã½/ùÊ”u•*±v2Dá×t†È´Æ:ÅÀ›«BÁi¬[<ŸüÂ&íL!C4öxÁìjyjl“8ÎÔ¶	XOîğfã†¢3ôô;@<9ñ0~ŠòlTÍOÜ
H—ûßlöjƒ)[Ê±V*mPO ¸ˆ°î™3[P](ÎÊeë™«¼<–„Dş°[‰ øıvÈ`ƒOÈ­7	æÄ×fZ † UP&Ñ!¶;â6|óM€öØgß¶Â…§Çü,*Xw~PV§J\HôN¹Ğ£çFQÁ"ÈØ£“ñ6ìU›ªêœ¹Ü0|¸šO—7ÑÉßvq\Ùa¼mHn›o“rèdEæ9]Šöxî#ß?ªî›X‚x?H#iÀÜ[UÔFıS~_ÿ±‘ BŞ¦ÃqÕT©Ä¡”Ó·çzØÈıÎí²ù=ÌcSÃ’ ¯³»hôPµıÆdù-Ñ
~ëªÇØDézéop@IÃ³ŸYÒó[”´8|âFP­T¸ã^¹,Æj÷@àÎ%·sC7ˆ|~\^¸ùŸ¡Zo‘ÈÃ9­$Å¥¶ƒd¡§?K§´@çZ7ÆÂĞaEC™E°ÆÇ<N½E>¾B^¾m?„ıá×_å¯Gy…àÚvieV$×5‘ˆ+ö©O¤x R S%p9#n,«µYmÕÚáŠxwÌÄØæIn?˜„i7KĞîªª$¤<›I0ã©6Æ2@èbŒ„üÈ¹[< ·/¦B-DP*÷tQÈ¨¿4}mD†|¥m¦šê‰Dî%&sê7˜Ù×µ1®KLÈ¤qhÜ±ä=Å2Mæzó"I®PG±ŸšF™FÉÕS%Â¹zjãÅ˜ít5@ÃQ±y©“™–rS';<»µá€2bîI–‹Ë‚†E'›Ø6åÀ+óvÂœÎèrÆX	Ö®È7"“xÅªä¯QšE°²h;"ØøŸµªü†éæcvmÊ³P»¸ç¥™}‘3]åŠ‘ãßcÛ«:bái®¿¨ƒĞ²zJM›µD’0C—N¢ÕojF@úSÄĞ‡ç!tQÓÕ¿ğÀ{rŠ¡¤òr¥¶^ÕQ’T¥Ä1…y,^BŸd‚ï™ŒXIù;ch4p	ñ&+Êââ¶D¬‡rÃ4è{_ƒş¿ÑÄı´ùYë˜ƒÿ‚ëş§ÕZô/ìÁİıÏ—š@øÕtÒ¾şÃêÚC sş¬=¸»ÿû2÷&A§ŞóNy¼-{9h#}û´	oèZšÁyrxV'×·>É h‡‘köØ²rÏ’wõ+¤Ìg}æâ{²û4`o“ğ,·¬C=VĞˆbÿ™üñ´<k0æÍi^Ğï‡“,e)ˆ@)©İñpcgâiï³ÓiÆ‘¦päŸ?«×Ÿ6ÅWT‰E¸—Ã†÷´	Ããm¿'[,ÑĞ/œ%ñˆİs¶ê×étÄèÊJbÍ²z¢Ú y&Iø¬‚wµ¬¤×˜`ñ²¦Bäİ^HÕıä¥g-ø9,Ği^âÈ
¾~‚ Ñw4|†Q>+XØâÖFTÕ'µ^½¢Nğãï8{!µÔ@’K®3™ó›AO
®(#lš2t¡fUòP¼4§M`şˆSğEû.ŸÿÆÀlÔmÆŠËlo³Ø‰cfµ#ç›ìl¹øóùä?èqók’ÿµÛwòÿ”ÿqşuÒÿ’ó¿¶ºÖ²íÿÚîğß¾ÌüŸø(ìMĞ•ÕÆ`ãè;SpÌ|4«c›ÓsÖzì3B•jÃ_Úeªİœ‡¾×è~Çö6_o{¦©î‰JšÅ–`AYº;{ûİ®g¶æ4ñ4DÌşæäì9¿)<9;ü‰~îàÏ.şÆÌ³€]‰œix¹”ÆÊ‚¸QÇ¯:­Ò¬J·®ZuR?á»Cñ	WÏséØx¬©£çdİM]±ÛÚî¾8Ü¡ÆzÆÑÎjò˜5ŒÆ<ºõıaôö›ƒ£û8ˆ\:Â3™mİ|_=òC–!¥#L›ÛJPuuƒ$w²×äË~$wXj¨_Ï/&ô¹LìÓ—”XŒ¾g%c•Z¤»AĞä8ÇöëÊl›~=¯\FU‘1=ÙIàc=™1e˜¶ÄCÏÃçóDN(äúKAâVêûYòå0ÒåK0n!‡Í¤P1ò?ıúë‘à'&›$E1lì‰dø€ÛìËç(†ÑSaªO]ú®Åê°Ğ¯/b¡/Èš/9vœrŠƒFˆgØ
kCBq‚ñ#Üqßo-ÑeGÆ8êÇÓqÆ‚T©rWxë¡Ş¨à‰s­K[£-Î”fkE>ê<ìz;ÜôXm6¦è5˜äÍÄË €º‡IéjŸ¡/ó}–"¸ğˆ·ü¡ğ@HXŠ1Ïâ1_mÇGßíz64ßò€ôâ^ëßŞÆÙ*-´âyÿr÷ùÿá#ä¿ş0 Zé+cïÛSşÎ×ÿ®·Zm[ş{p§ÿıRúß|êƒ¡Ú>aû~‰JLsly@œ¨0p–À Xl†¢Üî¼çÎD:R€’şSÆú&u)·ÁOŸÀ9ÂËÊÓaôìÅÃ7Ón›Ã°Úâ'˜ÚxşFH‡>fáúÜ‚"YNã\P2A‚'mæ¼·û ‚Ú³O, uÕ\€×û	ÛŠ/ÇÃ80Õú[hªÄí‚“\
» ¡C=»İò°#\ğCPŒïÓÓ&Ì”˜°W1’[½~£ï„z‘‚Âd„Z¹†f:V£BŠsÕT+¢¤§M¤—òŠÂŞ\o7êK*İ-¹B|*_Zİİ¾Û×›Ï¬ç®ÿz:÷5ß×îä?GµıO‹…u×³ZùÇUNß}¾”ü/cAÃA3LoWúŸ/ÿ?X[³åÿµöÃ;ùÿŸ`ÿqÈé€!Bêù£1Â3%àiL&—ì,2ò‡FVu:©ñ‚wAÙp Ø‹/ÂÑ)ÔĞ~xŸ‘k6Á‚ØŞö]ƒÿNÕQ@²œ=`9«®Ë‘›\)cØÖI	Yˆql]ı…ÔO4ªşbıÓ>²Pç”LÌÌ±‡1š5°å,	Æé$HP©¤LNQÍkét³` Ò/©kR=÷^|iNÆZÂTjGŞ<8j¢/T¾+ãş;FîKzIÜéˆËíE.Ğ‰PR‡}ë}Ş0"oŸGºK¬.¤ì/0ä­ëjO¯0ümJÛ&R $y¬ç;äø°Óñ8ìc f8µš‘ØÈv|®{ B¦}$ ½”—S"¸\¡ím¤¾Ö¢ñ²zV9F‚1Í‡(¯òm€§Ê14:´ˆèüŸËßòŒA„(“¼ÜùëöV	RLÚ(¥¢“úè]ÿìœŸ…HÜq.
´ó2zT'½¹¢a”]¹3Ñ`pš4<½ò	ä…zPÇ$Z’mX’‡-ø¯N2¾0—­ËYÖßñá®>`…ê6§ç(E´ştƒõ
¥4VË–ğºA·†Z_BÊ³öcW"îÑLrãñôTÃ ¥cXŒ1V%î8?R¾D6ufËótI«ér)5Ò±:ë*‰Y*2hI}›#‰ëdq´€Š‰ê‚ÁÄê`Ñßq2â«FªÏ—ƒ=ŞÅmi3zã	…b–©+zûøŒ¼ThzP%ep—ÎŒ‰³.X"A^<jŠù¾^>¨Í‘O'¼¶ş‚ßD½Øİa¯‘ï‡©½#ğ°vÅÇ_İÁå2ÿ¡’ùŠ¾>IàhÓ8ëíšg}0pÅ¿G¢?ß¸hafèupÅZ«%,L
ÇÜ%‡Ú3„©[•_Öl z  ¦ãÇÜÍ)äãä½O±ØŒğßã±Ú÷Et–oG"Z³É„£\&#£–?Î(·ÿ¸m©qùKşo·áÏüÿ>÷î};>M'úÿº¸µÜZá™føÁŠyŠÿâ«4	Y$#³ê¿wÏóîİC3ø†\Eê5H‹aê:ÌëÙf&²®
áÌìŞ=ix2¿"+ç¬—âá%¹Óõ»â<?åoÄm|şêZå~Zneƒ¡5L{­ôGùKûÜĞT
Íÿh…èÊkg-šù€kô¸WW±ûÖk2HYÚ<‹ÏmZÍXf3´­ŠáŒì„0á°:à"ÔòùeÌ0´ùÑ'ANó—B‰èiJltfdÑÓ"`œ¥”QÄÇÌMzÊ
p§„-1ô)+ÉEÅ<Íë&@U‰f¤½Ôˆ­”Ğ¾at]&ÇÜ–Cz×¤2\ë˜6„–_X•èÆ­¦(##ó±47*k÷'Ù1sYÎAÈ’gşøI[%ÙE‘1‚[6[r“\—QÙÈÎBÃÒ©¬'³s—ö_B¹©M£l‡×½V7Qiwmû)a@%,¨æ™P	íR±â¿ÅSÖÆ¢:½ÊNaèÇûu¾7KÖ¯³É“ÍŒ€xëŒ«Ê¼Ûÿcè1FôÄ‰Ië¨äı‚şŸ«ë¶üÿ ½v'ÿ!ıÿ~FË„¦¶×Ÿ†I8"UsUâO¼ŒD\*C6R«d„×(ùÂ9‹‡ÃøOÇ	”‰Ò€ÿ@1dàÃ²«IØñw|e
‚ğÇ´&˜A-“È iV Qš…\Ä·b4s:ŒO……Kóp{sëõ6½¯ôÇü‘¦FB‡=‹úq•Ã­
èEÕ-­0W'Ÿ¨Œjd®áÚ&’Ÿ)ôŸ³˜-­Yˆ2­A¥<ÛÔoà÷E«QE"­©–I7‰ÊÍŸïêëğö'L”Ôjıö_VÚVËHlÔ*µ®Rëràr6é«ûOöÛ?ŒbIå"šÄÈ,,ZÖHîƒî›ûIĞ‡š ‘‘]lüöBßG‰õÓ$Et¯İ""¼(ŠĞÄ¬²“-¥ÆFÆCÄ@J'0b–óMMà+Á;Õ…í®!MZÖÚ&«}XQmêOWèÖğ®¨¨«4YŠZj‰Ñ$æ–wQšş¾KÀDé7†ª8×*š)Æ7HÌÉ€p“Ñ¤)2Je…‘²,µ¾ûyÌûóÜ¬P5G¯ö›bA´VsÅó!Y(Š!Øèh‰îdvÓÆ[OĞMœÄ‚UÑ˜Ò°?M`fõJ2vR“‹”¥‘“~eTf†¬	é›0Ó"äGÚ@Ö4aõĞWê¼4É°ùê`ŠW·a<3Wmıªh§”ŒhˆÛ°îÎHâîs÷¹ûÜ}î>wŸ»Ïİçîs÷¹ûÜ}î>wŸ»Ïİçîs÷¹ûÜ}î>wŸ»Ïİçîs÷¹ûÜ}î>wŸ¯üósÆÂî  