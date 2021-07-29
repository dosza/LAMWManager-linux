#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1994003912"
MD5="279c6bade574ac9f0564a1c116f304df"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22532"
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
	echo Date of packaging: Thu Jul 29 19:20:28 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿWÂ] ¼}•À1Dd]‡Á›PætİD÷ºkĞJ“ŸS‘JÜéê1j,+ š‡ªÉï¦¬½A?Dş^µ±ä<ŸíMØÑódœ';—jõúÂË“ïfÁ‡ñÊ0*M	çÌ¯ââ‰ŠøÍ\…¥sT°œä&DXM_ôZ‘H›1 3+wÂ‰Ì¬m ¢h¯v¶øş›@ ğÁ ˜:`+­öÙäßaˆØd¨›Èà³ º@2–Ğ¨9@ÿBt… ºoí€h]¬JN:/Û›Ù`Ê–4Mµ,}Ùc‘¶G+õl3ôºwE.)‚+ız³x6P¶ßôvrÙ3-BH¨	ĞBrÏ¸ç(dy¢§®Ù¹@¬Š­–_¥#ÔûĞ§®À£|Z}Êà²V(ƒÃÚ–"°¤Ğ¸6Mˆrÿª’êœÏZ¼ÂÊ”ûLí?2&ª(G´åy6˜ßÅÄ@§8ÿ(ŒÚjI³<?Äß³0"ì
4uhug$g]ÁÉõÁğ:ºÎÚÄ6—Ùy˜ÛÂ±†©=y?*GŞŒL›˜ğ2®B­i~åî;şRmè‰ôTĞŒo°øW4jjĞZÀ2{c'G:¸DË ‹}l¦‰]Ü'™WôÔˆ6÷Fê¬oÉh¡W™‰†“Ø³¤ mŞã8‘ıv£¸‡ÓóxaªÄ ¢ÑË>X©ì¢¿—ÜšôÍ?KA\ 4Ú3BÉWä¾&LH,‡ç;?:ÛÏw…Òª´œß×"øÏë¦à|×Í!8‹{o5ñæ‹íôùYÿT¼2ÂÕ6ošêŸùŠ·löŞ2%ym”!Ç>¦Ô,¼÷ã¹UaO§92†ßƒ‰Çgî²ï­Æ·äBÓFÈîZdõş…#¬ º e[,æ´­ Êø® “È7
D¿Cÿ±	Î]=TùÉÖ¹I´éÜ/tºùL¶"aøgÿd¨@ÙøIøÍšmîñ<”–[´êHAÍè‡¹ÏÈ ü¸×òu#ç€ui®½§–×6¥¢>bpº„i
ó_Mg²ük¸-İÙC®ïµÍ¸Ú;à`ÑÜâ‰WRP¼Àz‹‹è7÷`ì’µ¾ô‡çg?fíÌUâCyŞH/{GæQV`T•\pÛ0bŞòr~&XgKUu²fp|uºšv]³ñÉ1F“÷=Ûu¨9­Úª©¾úéâ£§ô´½X‹ =siUY¢ûv¦Ñ3ˆ“s–avvP†MÇ»T!˜FƒÂÂUoåÆ›u‚»†«í®Î‚[z|ƒ¼ı·°ë×h©,†Q·&~i1õÇ–" Çü»ñ#óØ u&\˜Í.<à"6Å-éÂ¥İ£Ö†ú½Á$&9´s‡àëşÀ¯QûD{¹’)•Ìïx¥£>H$	Š‚hE`»ím˜õkËHƒ@Œ~Y¦QFEiD%ÙsºNæ­éPıUÿAŞÎõ‹Ñ’×If¡÷$ùbbsK|­õpÅº€TK;¤g/Èq`|æ"v©¦&,vğ‹Ê0™p—Ã`À£˜xÈ$·æ#Ø…¤áÖ0y[Pùä?™²Y IrvO›8/‰ØÃ½—2µ[W¥c‰G³Íô™„)Hpì¡¥‡3Áü®‹K]lO\!nh©ØŸÆûV€‘>ÕglàpXfm/n×/Y\X¨Ì[*O_ç5(ß‡Åqy©F§ØÁnKOEa6qätã…e=m§Á¾fè)šÍ;›’—"ş†b|5ÏCéfë×Û;¶°J\Í·’êMğ‚Ş%&—u”<i×GP¬íÀ1çi0î—eWªsxUÄIî3
ßW{ó|CÃ
XsèÕìhá„Ì›ºsF’;yîyÊ+wm…Ö”¨±¼_+¢Ÿ¢ÁÀ è¾ML%¡é‚´aT1İ÷İÕmÁÎ¦ÓN;|€!ô¿Š×O‹HúË*´¸>5z®$€ÛQbßË_ì{™Úƒ½ÿÙ6bì{[¸èñ H¢á0úiÏ4èß‹Ô"•÷¤k•oX€Ğ¡ GU+a¾~*ƒšİØw‡£:úH÷ğç2•E‡ıáTÀôkføw½g¤¼ŠW["ZÃ_oÂ¸ÒËŞ£÷jW¿Lx¼ğ3Yæ_†V øÿ`^Ò]	|[aªuù´VJhi¶^R
ÁgµF©v4äØf	¨)ïG£óŠãbTÆxi`ƒm³ÛqÔ.n¸òBØè'f=¡G2À5ûëöùÉ¤iÿŸÕbëe2¬àäZW“<s¯kAXLòR8ÂÊ&íh}¹Ï_Zâ9à<ñ‰hü!GØ–c@“©z”==«}]&Í÷e3$–YZáT*ÇcÈ"ªĞX4ø4îMw)¤ÉÆFòwUøÕOÙQ )>eË,ç)é˜ÅàG–¿Â!Ì‡ºK	_øçi
¯«vŸj¼µ‚lƒa3DFN1í*­]¾I$}_Ên:m,'2^ÖçŸ02rçÇ¥F‘¨4˜YÒÎäÑNä©‚¦,YtÜ³hf—mšçdÍ7*vÒ¤œq·²®xhU–¿À¥€ëål‘b&§T—ÎêÆüÇ¦XkÑ’ÚåødBt·õü]¯Ìn=ÛJÎ×üø›á¹ıBú®¦ëª‰§Ğ\Ik31£æ"¡Ò~ò<Ä±İa„?¤ÃÿºUÂw¬Ü¤kÔ8%™‹Ë”Tveå³)%ôŠ——‚è:ƒ{û‘È\û4.’·‹¹‘S²š Ö6Ÿl?&´QmŠ˜¶‰As~sEÙeIÊ¾»P«Açÿ¢Êˆª.¦ëÁ,8ÂRøD$¶´÷‡7Áš+¨@,ëÈZB÷dõbÃV¡H™y0ƒ\PíG‰Íäz Ğ?0¬P²¹¯:Ñvh…s+>Ö`ZÜ‡ Qq§0=O¯º­¬bTL¨2~b†ztÁÑ~æğ½n%}èp@ˆVêàÍ‰~˜Uwi&ü3ÔvÎú„¥ëƒÅßög:Ÿñ`á*ü÷Pü>¦C›Ù«8!½1©üz]×s}õ»W›É®ñgßåµ&¿²×ZMÜ²š_€_Õ1>½v—s>‚lA,Ú&ï·+À^qnùuîêM×.•Diãe”Ê‹6ü’'{i[! ZG.™íÂ¦^>…NÕ?øà0}¿­Â¿ø@¬]4ÑYBo[5¢Ï¸bpêstœmë2B»Š 2#ç|«ær-¨©I6X,‘ç¢xxûÃ²‘_>ìHôRsš•KXüRÖâÏÂÏ½ùºÀ%²Ç0ò}¯%¿ ¢”8€ùàG~¯×ÁŸ¬w}á:5¬¸¢=¶c&¸…Äó$ş%6¬1å9fÍë¾ÕûÉBñc°íÊ,¢nX£XñÅk0U›68,™ä¢Ğj9ê¯%coÛ~×JwÙPÖ?p"€<õ$iûh\7‰X¬ü$@İø#b„oE«›ãYËe¯áA>ìrûOZbR,dYÔÚ^±Ò¹¹_f´©¿¹ÿ‘&~ôô¡.†T€¼±ÀsJÂåA„Èf%GÈ¾eãßŸ+Şså-Ö½­çY%VlU†tÌÃwîp¹|Fãh?Ç›ÿ5¯bÈ‰‚”ÌÎ¸µRHÄqìÇ†,á´Çã1&ˆS½:ƒ»ÌF6ùPPÒB¢ˆ°õfXO=¤Î¼g
ø5ÍÂ¯üJj³S_0_D´½Ø ¢ãUá>Ô¸Ôn˜ËĞÃ`â»ëÓ;ºØÓİôÌÍÁf×€i‘=ÜµQ_ìBğ„´k*‘ğ…_a^Ñ½ú36+œ
h/™O~õÓu³.ÂU4Îá†»	È^‘Tï˜J	„9„kñ;¹©ÿÜÌGà]…{ù÷rTŠ'ó~:ŞkuŒa·ø&Mg˜˜ı'+”éûÿMB“cÇ0bÆ]åVø)â+aB6L¡u4»&ápõ]£×û¨#Ü9PƒZéôçğCİ¦`×D¼&°(&bn³™ÓoR ß0õ•¿ÿå1@ˆ
ˆ‚‹Òx^m{Çí «¤ÄÙ.¦¤¡E‘Â7ŸH#2L~¯WN‡±Ş>ÆŠª‚²TUl‡>Ã/6/a ª[¾ºöû»,ã}ı­“O8ŒÉø¦*e‰Áh<éz0J/{Ñ¹å^¿³dß›¼Õ¸ÛÍ€Ì6û{Fïÿ¼,ĞF’.%ŸeîÛ5é)ıØZ.~u¬ñN‡ÙË›ud%êD2º°ÛôáéºSC=ÃdpoP	â}‡"<F„1Ä¡µMÄ¤h[ğXÜ]ŸzÚ—M÷hbß²iğKî„MeŞLd/œ½ĞV·aõŠ½¦è®•¤°¶Ø5dpiç¾kbNı¸(Ëúò½[kÍ.<rïV%Æf¬¦#1ûZ/•UÇÛ©Ã¯]»½X\ÉîcZ0·dQœŠÏ±ÉˆnIÍøA:°ÿÁú;vÄ²\¿+·	“æ\åÔkxû–vŞ=†ù @zó˜Y'„ıİ¤Åù† ü îŞå9çï3ÃŸ4@‚|”ƒ!Q”™$öƒüÜQ¨¤¥«dDñdÜ' “P]°zÊà2}{Oá”IÖØz]WËSÆ:¥V½Áòâ£ài¨q¿ïõçkíÛø±‘f{67ı²‹‰jh:5àEÒÙI]Ö=Æ»œ,„Ùı<¶´[v'®Ñşsw…0Î-†f·‚à{…i’5ñAÔ>xOï«ÒÈĞ¨§N†y~¥"º'r¥Å^ì·Wõ,isjİËá;L+X2Fá;‘š»µ:jøıQ-Ğ*3JŠPŠÍA8ÿ‡q!­Zf<÷qŸÓ#»«‘RXMc S«†”2ë³Ò”µ†»FŞ˜7.°†ù"{ï”1ÑERĞx4Á]S¬;•Bkè#ø‹ ÕˆÒcÛŠƒìãì¾ßhFú*~90Êó2¢^)¦ãöV45ãôŸcÊ &•¼õğø×¯üşµ×ßa¸W·&’Ä‚ÇkF^sœUPùˆıót¨Û'²fÍE¼öÏÀ‡5ãç®#lOËºox~jw-…œ{¶Öå(¿„	,¨•w(o™o¸<îó‘'éôaIYÆæôçáÅªKÊeè #;ÖRuêĞ!{•õúd<±’1Ò,Ú5"S0±"ƒTà”ùQ{'Ä¹WjŞLB‡B}cp5X
E’®•pŠÁz¥
“–Ô6ßWÓÅŠXf‘hfşœI÷m¦ƒSNu° lã|WmÆŸÇ’cŸÛÓ@ûä˜®Sa,ƒ»W@E¼ºaR¸ˆYæDÛcú)À–oÜúœ<YlN\ÆVJ ‰œû¤Ç¶ÀŠõó“yİˆ[½3­òûAn×x£şŸœsêA«’ÂÁ¯’×Ã
ÛÕ;œÎéÖº`!›]KA­—dÈçµ_Ù²p°N"Úç‚¬©Óç‡k+[Uâm:üV í©Rmx …Ân˜LBÜ8à·½§üwÑMÆ<óP`oh0Ó£´ÓıÏ{hğ×ÔÜº);
Ì9sóÉ
s•µ£aZ2Ÿ LÿJş—ÖÊX¬éá6ç=ô´ˆ@¯ujFËë]ëÓQƒ˜uŒx5ÜåvóÒtç†úÍŠkò–G›83_ñc¥úÜ‰óÔô:©Ğvûj+§<Ó±£t¹5˜Sn”Ù4\áOÉ#ÆwÑèÆKE/²ŒäšÃhıÀ“‚,¨Ê^Ğ°¬¶•¶|4İ¿¶2ÀÓ?nå9AÜİqÓdŸ¦ö¼=i…·)z'¾ŒïÈ#Û·¥Ïq¢IuÂk-aØdb¡k=şè«@ÏóoOÚ¾‘ä}BÛÖ(=â85£î}ü’®ÒÄÁ9ŠÜ¹D?„ñ®À}ĞşQî’µUŒß¯K5!€G@‚ôŒ.¢iÌ7>Îá–.DÀÒeù| ı™iŒ&lF/ûVTDP~âü{ö`jqƒ¹C+ uœø¤.òNPß\^NEèÊvµÜ¥NÔ”EŞ5Â«Ğ:ŞWÊŒà½Y&+%'ç²’Ô*_5@ßR›°(«ÊVj(úRL(ö\˜w’Ğ¸t¨2Æ?•×¢™‡ŒÓ¯‹õş¸ ,r.783F÷SãèÑUõW­Ô<*Nz™º¾IAˆIô#^(±	˜TÏ¼êŞÊ@å¸š³ oIw1ŒNNÕ9(Ä*ƒ~ü…‚S°Ö_–«¸Ä•FwHm^8ÓëXğ7uMhEêg;sm( &tÍxéÌÖ÷Zá€6oe`ª®íDùrüÚDÓòó:ó2£ RUT ”¬$Á/hmÎƒ3|•ˆnKçA —õWÂmç—=#³LI¶ìK@E`^Òe³3¢«Äoˆ°+ğXîq™«ÿ‰Mö¼.,¯4®H „¶&*“Zb™Ò9uLœl×«–Ûi¶¯ éÍ{ı9«+îŒİRİÙ&ıP¦,,°£.ÀvI¯mí$=æ¹°x÷EÆVÅËŞ`Ç"Î9a:vŞ€h˜auƒ>-çÎSHl
ä:ûÿïp’Šâ*Û´‘HùsÊtš ŸZ@ù'>|BD =ºÌÙİ;çZAR’ÌÇi_Šiã~È–g9r“úVˆ¶Q×áÂÖ{ÃãÛ¦˜<²Ä@7Óíø.•Å¹=g3»5Uo \[ƒIN¼p*a®Í
]Ê~l›Œšİ?veô@O’®ş	èkÕ–òƒOÀ•¢ZõÛÜérèyÙ1úäáÎâ,VQPb\†ĞÑÊT	×ï6%°í‘Ï>ĞÍÃÁ({ÖsÂéaNTMzú„š&¶U’Ék{É²ğú×ŸcaÄSîé´©êtSÆ–I_ïº0ûg:Qè·b!hpìrÒÓ÷ vÂÔèÅõ4Õã«]ÂùÉ£İ0ÕÈ¦í®p7LÁñO
WŠÄÂjç®lœ±#ÇŠXz2xAšÃèn/Î*‡ó›sHj–à·OÅZq‰Ì¥¤‹ÚEæĞéš´Gƒ®mÇë	×ÊüÜ=|‡©ÖÌ101õéû´1£â‡µô¥ø9ª)f~$VÅgx2G7s‹L¦óÔbè:–şÏ¨»¢zÙZ¯gºoÚñ^‚G'9‰l§¥Dõ‚Ïı»¢¶~ÛA"2°÷sæõÿ>O2(H8I$ù H×*•ôcTspiu<âr³‘v%¥˜xZ}”#¤¯x® _!ƒmEˆ3ñzŞS‡é¹ø+ÉÊÌ”†QzöYÓ~(5ÊHú/Ü¶ËUíßAğ2÷Úm·3TÕÀHtíš0¯L2‹•.±ìïõµI&ÍJGÓîx3eHeIO±Æ…‰Ì{90>Nò O~¾©<ä\-jíÜËNšÆîó¢‡s™÷Œlâ5»^ZšT:„	$ÙÆªX`Ú
×©îøØqâ?öevÍg1.8AQ t”ˆêj˜u˜ÒU’ãÏ›ë³P#W‘òJüGA|˜c’)¸¼õŞ†ª¹ÇÔò¢Re6OÇ<DÔ0ãn/éó2´5‡z†—¹¥'^æ$%?<à]§ckET(ƒ÷NÚ$Wùïáä9¬¯CZi˜ëöÄ3U¨å¤ôÇ–§¿ÁÖâ€„-5óŞçõî Q+ı99‚¯I²]´¯ìC?æ¹ØUGÁ(Á«ZÓ[ø¤AçLíx¦ğ¼K;” $û‘² &şp—Ö÷xôÒaĞì)å°½a†Å×¨Oèfš"vPxõ^´¯a¨]fU&íüÑ½ ·ºàşŒXğ,‰öGÒ4Ê¾É=C/"V&PÉ¾Á”§ª	SVÎª,Õ‰g£‰åqwÆ.òœö­f“t_q¶îÃùbmü 4Š ]¯;Y+#pîY0ÊèAnê%Ôš”ŞÒ_9íÓ]²î–§RTÒŠüè_3´ÖÕû;„BÁwN*ËrA„É›D‡¨ìw¼6£Hc™şC…ÎÄöBÄïL3T“ :oC¬òúÃDƒÈØœ3•í“ÍÒ$…ß2™éÑ¸Nˆš­ôP¶ÓJ"Ó«+e‹Gû*.n¾ÌXìE4$Xë)·=•>Î‘Ğ|Ï|€ñµLÇ7®zdyY‰”å
“”+dqmîU8±ÕtS±ŸÂñ©Ì…¶Éä!‹ïlÚDÊÊ_e"B3X6vMnïœä–&#Rğı’	éˆÎ)Úx»æÙ‰	­\ÑärÙTwÈOï¯PT›&l1G7—²Æ?Ï.|>ÓhPù‚0:İr[H29<ŒKhxÌm»ˆh ¹½úÓñîj?· Ñ¦ªøc"Œê‹Å_ì~.dãç;iê¹‘N¨ˆrÆk
ô¥>Nû·µª¡÷œ˜qïLşŸç¤ù1Ì# Cå¥'’ 3PƒŠôJœÚK_¦&„¤u­ë-Š@‚à­ İã¸£‰_¢ÊA2«'£õøˆmşĞAé·M–›à—Á˜9ü¬¼Î"†P¶E›}JéYTÎÀ£¼ÍÙÔ;£—¿€UØBIo‹Rğ™ó˜¬w­‹*^lÖf¾çM *%§„×D‚ü¾İI¨é¡ÌÒ<“Õ‚D0Fšñ }À€}¬Ùç÷ª¶1(Œ¥UÍ7Ç¦:oJ’¨W‹{Ü=ÿÖÈ:$wXWWĞ¨)dôm’QÇaP+šsŒµŞêÀÛ*T×¬#[nHn„¯‡ü"§¯×Jàn¥´¬S€³Káa’C/û>˜Ğ±é:ûŒÒSr›Ñ4Xî…%V¸%•›±pR¢’Ö[º6íSèdù/úlæËh‡Q¤7Ú1{ò¾-–ÓKóOÍÃĞ—&/¦«30˜ƒ¬M¨œÖs;ùÈY<'Š6wNÏÖ	@qö İBÛ—¶«kÄY÷Ç>‚şrÌ“_šÊénºµ\4¬&|„-Ïív1/Ğ7»tV—ì¦{"rùRêƒ2=—ú2ˆ`Œ‚1¶A¶şšdÍ} ,:kÑS½?ä”†Šá
7	k†•/y%Ùp­ò]0Ÿé4Æ“¼°á'pÜ&®vîÆ©’´vS`ã|Ì‘`SDš/‹şPò/ GwÓ¾§ôF<­?n‚Â^­æ
"Ósr×ÁÇ“|7¤Ñ„@ıç¨>ºDyƒùiZuRåÖ*çÊuÀÏ‰I¯é±t0ªd×‰Rş¸:¤’˜/3™åÂpq‹“,i,ÑÊbíSµä¦HTºÓš÷»ÊRuJşåì;2¸ë¬!)´éBçÌæbÅ×Gb«.ÜÀK)1„ÿñ>7;â1ké®Æl<Ft<¹i±	úÄÀE>ß¹¢’km~«Ùk„	úÜÓcX­Ë³áeíğlÀƒ4‹@Û~ãÖÓWœ [sØ~oÍèä!R›«ëS6mğ[°“„îÃå¸ë|3?›ÍÚ9ÄÆhŒ0$ù‡$<´è¦#m`5ÚÊóv•R¾_íãë8\'‹çp×?Rú™’İQÅ£(»:è÷ÓnÊT:°ÈKúA½0
"·EZÅ¥™§ÓÈGJè’¦t.œiÏhÚİïû>è2ß®Ã°½Jï©İ4¦>mÅ¬ÅáÛ…r^ò&[ËE×ö †×òIà¯¥|këÖE¨ıŒœúû|ÓFÊöí²ã5Ú tx]·_µ¯#
U>Ö±S–§îì¤æA\ï­«7O5@³FİóÄ £o—YçM…SP'=ü´àë“µö
ß[“ily¨¼Qã7ÒA¿úÒ»…ïLü_÷mg”ÊOêùUŞH…yFœùØëwP8(ÒÕÓsë—õğ2tÓ—‰Îk>¹5½Ümgûg¥Œ:hîé±ÈÌ¢¥m¢Z:Àı»ìó%ölƒ³¸ Ç_Ÿ\äLº~ªLñBc#}ğ§°ºjüôéÎÜ½åÖ|ÿX˜1?_nˆØP n'¸5ØZºæ’
¦—Ü®pCÙâ à#\pN¹úQÔDÖİ™ìI£Ã2…PfÅ÷aôµœ$¯_@µÚµ'6.ooCİ°R-giOÅ¼Ÿ‹Í¦>Ÿ):¡Û}+ØÊd&ËîDÓİƒÛÎû {eßCxaŒ·Ç#9ÂÅÈv®ÚáÚ¬cåœ&LæFYÈÖL§^£HR²~QaĞ¿oÿCÀÓ>j‹tÃ“u#¥¦ŸÑİÈ.ÆÎ¦Î4>sMê[´’Èáüy ^Q±3LÿSs.#z¡İï%ËƒY­Jô°^Yİ­±6x{a÷}´˜­-Ëgú“2xäïú—™[m×Z´õÿšwæuÿçÛ?Wa¢Ãî³.DŸu×Ex(xTd.Q‚ùNÿ5%\Û˜3Lb8¯jŸ“ÕV=Y«EÀ§×ŞbšY«új‡¹€x³•[:»WüfÈÛ¦¦;5İéê€á\·\˜äQíÿæ,)GİWN1
”Eã%ÌT„]í,ó*T{ˆÈZÅ ˆ$]eåj*«§¡7Æá¿¢V*v3ªQc8•ß;P¨…3üÎç/5è‡|­Z-®Õ+C3bWKı4í½• ÈZG€–%!0©=²®lÄäV(òa68ÁSiÍEh˜Ûxò¤m¾Á·O“¥ÉÙ¨šs	3ÊmN•ŒdWüæ	Wó%$Âø}É4ì…i‘!úHìPĞÜT,½İâQ]“åIÀVZLm’¼Œd8†áXh?²ïSò=ïqŞJÃÒ<”W/Å´”9´¼:¨{ºS¼­k¶`$è¯“·ü9”5.Ûû³kÃ±`ÕòA€µ–X÷K—&ã®·‰•!x ¢a7]µ°‹”3ë¿vødjİ™ïM5XZÈ„t*¸ÎxÚË&¯õ	°e±¦iâµxÈ8eÈF‰w0»ˆó4ÀÙÇ#`ÍçbW/uÊ†Ãª=Q.69&oVrÙ‚'í¸ÿDºéS,Dn&gİX’£wkKl…òüçvŒ<lÒá­ÿ–Pvêï`åÏØË,<ôÀG#ñí¢6Û{b4X^Üğ4IÆ„G;eT<l¾1Ş¥¢±…n¨FÎg}7ãfyı¾—’e>÷ëwo¦„÷ıÉ¹8)r—Û›ú‘ĞBü'ˆ¨T[$ÇqË´ÛVH[”Ã…“Š*+ÅªXŒàdë.rn'Në…uOÅ×ÇŸóã,ì)n]§˜ÆÆÆÀx6'í™wá»j3ï+Ø“¸¯Hà²­ÿº¯[è¢}x17o¹‹áö¾EÚÉĞÇ¸•Cby7cXfvº5’õó-!Htƒö(gEh«®+øK%j9G=Ïaò¾xÔİ(° :¹YTE²y§üf\öÇ›DI,œ§¾}•å
VMëŒT¨–ÜBPÉ™ªÊQ™¶f	~]İOFÂ@¥,:  s?¯Â*Œ# İV E‘ş^ÚD³ÁYwèöIå$ã¶ç-Ã9ì—gç–İ‹Ê“¦œˆ,¤ÃÀä<¼›BGä¦Âÿ°À–Ìç¢$ßtøï~RÉÆHœÌÙËî«Ü6J°–Á.»ÁNrùãÆ‹ÏñC3méÓÔ˜jÛ
³¹ÿ	şãè­ä1”8?Ú:&ğ«á`0†^
º¶VL1*¼ƒZk9Öù¯¡î”F[±tpŠdàöš¸1Şk½3çõÚ:_/s|B?õGœBI*ĞR2D¸ùãSDü7½ mßò­5mP5]Î.UH‡U ¸‹±|	¢òsbv‘RèCÂúÓÜ,$”É}¬Ú#…D]À0S­‰È¼bÜx‹½eÀS!_A± öVMÛ¼‘ù;ó-w°…lhCÓŞûAdåÃ%9K]W¹c^
åzš¸D"„Ôsê)4L¦*Ù<™
Ãm]ã2Ğ\ÏL•2°¤¯7ôñ°eº‰İ·Ë{röcí¥3WÅiEó6PÀ*îXwo›+ˆl\Äª¦€6Í1œ,¡ìàÃƒÏmF˜¿·ºÊ¼éh#`~¼,wû±p…l9êWÈ‰Ğf:ªúÚ’hqò9}jY*àäòğó`ÿ£jã,„o¥SšR¥i™øˆñ’3é„ä­%SBbtW±w¢®.b‚MbK¦2ˆÛÖµ¯æYÒÈûP˜MçæÕTŸÍˆy•§§Ïm1 m¤Œİ·ò¨TpA§¢r(A($)PììN=‡7“Èî³jZñ2t/İ’g™ÉKõ‡¯¦…X'÷;3CNmÄw·,]Zå·y.Öc}€ˆı+[%ÛãÁ¼õôA
çşK+©Ÿ†¿ã¦ûe2}73ŒñS±©æèà··tvgjoõšşÙ/0§Fmä:W}ş2ògìÕ‰>­ƒ¤®*^XèP6gŒ]Ä7Œ‘IK§Ñ9»@Ô cÉ˜*/¡òAèjü¦ãíäVí²ÉÃ‹!i»†ø#™¨_©„ÍÈß/Û¨HlGÚEóŒè‚5¢RQğ±úwÛH­õ!å?¿‚Cxs°Ä5ôr—4]íF°ØÏØ ¯é~‚èæôÏaüÂ÷æG+É)Uı71meY5^ÁË˜ùÃºÜ¶j?#®¢¤ï^ÖÏäÖBo*Éğ@Åëº¿öA¬ÚĞrjıè¦µ§sÖ¡‡~?°¾À; °©±²´Ñ˜Ô5è±Ç˜²=‰D·ÛìïÉ¬[¶^âÚ©Á)Ã³÷@¨¶µ¬7C0û‰em{Ot¼0Íp-´k+ñSÑÊC÷¿0ÑÛ‹`áà = ş†V‰ö¯GÜëñ^¿V¯LKpÚÑ6Šåš¨I^ä!»³4°§“VXZ‹NïÚvâ•çÿkÇº•h¾…fÍR¼NI^,¼SƒèQ›ôZgv+tú5¯r7TüÍ*“¦|¼[cñÿµp£ÿóˆ%0øÒLsVoqgE¿v%îœüº´gŸV[ñ ­~{,·‚!PasT¼İíŠy?ÆÃ1ù€FLZÆ˜ˆåVÜcíKŞÆ½q´µ²1›“ÔÛx;H ™Mò_YÑ3tÈ²ßïK+I>*Í@Ô¾²š[fæ¯¥§1öRˆ¶B"†jÅ5¡T-¨ú2í8ƒôAox\r¬ïyI‰¡u­>–O®5‚gí;‘[L„ZxÿÚÈøĞz­ªî«“Z}ĞsM®ØÒ´òA¦À’Q^ÃnmOÉÜ‡¨°¸”SšÊ'ë$›K÷hš#ïÑÀC¶¼>(Iœ¿D–pasnjxQşE 81ñèydTÓÇ4½Y*v†Æd|®ßŠêöDN‰%‰B\"İ/ÊR¾·sØá d!rÚ;gj-ÀòF£:Å$qX*]ÄXÁ(YÆÎÏ‘ZÊc:ç¨Hk=öúßf˜¦Ušgt…Ñf<‚ŸÒØØ	Uk™ÛY‘›¢ÕMŠ>©ÌÀ¸F¦eÈ:/“*ôš¿ÏP”h¼&'ëQ}7Ë˜táäú0ÿf.9+ç‰3§üŠÉg °¥‹=2|î²èù¸úğµÚ¦iƒĞTÙ¥‹â÷ f1¼¤¥¸¯ñßOÁ-tˆd_J^›z¼êËr‹3Wèô8eÌvú”‡Ã
0áMRßàÁ¾q'„§Øy8ùï‡a9hÍiì5ÂI
[şR±âÚíµ¼SXUÕ1&1^zöNÃ/µš:RÇê…îŒTGËç¸õÚ c/sG/»q$öãÖY¼#OŸ{ìaî¡üÕKÊ ĞbG²†…˜ÍµöVãû?¶Ü›^‰TuËO™ İ4XÖÿ˜Cb¾=3‰]¸1€(„‹Mš6ØÈştiP,¡Ô0}¼ªFƒê"˜Väa/¯Ø£R0cÜx¤%°H'´õ¤)n;­aé¬°¹Œ@³%5¯¯ğhÎRNNæîªoÄ¤%³ÈKÁò¹ç C(Å
#@O5g:ø4öæ ùˆ*	ïTÇJŞ
uKsëQÿ£8ñCà|§s‰Ÿ ¨f–ø@-©U,¥ŞQë½ù ŠZcÓ*â/5RË€js{|~¢åf‡“<Ã4Áå ©QÿğC‚rX66äV®?Ñ…ç$ä-Ô³$Íé19j@¸_˜yNrN§‡‹¶„£n@QmÅö`_
‘OïQ‚¥ÑËÎÚXãÇÃÕ@X¾€âúãÂak\ÁÒÓïùÚÁ÷^GÀÓ>«İ½òDô41›MÆÄ]$PXŞ ÑW|s£“ZŠG†²É÷šã¬!89ŠMÊôé.’«ñjÖ®v°–ÔúÀ×òS
VÄD{%}`}ÁƒC¨R8b4€Ã»uø¾¬î]aVçç%4BÙuÜàl7«ìtAçó–šÇÌd")p:b™FË°è˜WÿËOş2yûDš¶‚/"3ç›¼¢fŞó`‰]ÿïu¦íÕ
åìG«?« 5iñÎÓ“mBÊdGá-ÓÁíL¯ß†Ó%?DÓF:åÎåL[ÔöºÕSf—Tóçjİ}™ÿˆÊ­lNcĞ^TÁ"GL‡ĞcO÷êJmÍÈiãdµF Xk†ñrÀÔÂÀ<LÄ!n¼†f×¥F(3'•ø)‘¿ÓîÜÈI­EP‡fçBèTúó)šO’5rØ(îZÏ‚	à…©ZIˆ¨Çñ
Ï`¹z¨œ+æ¯8š'¨5ÍsÊÜÇÈù¹%R«íªˆ*®Ó•â’œ›0xQÙjÜOP‰ÈÏ–¡,‘çöÿÜçæ<|p€YËA­ Â'Œï5x±ˆ[½=}£ºÛ«_êN'K•8y4o%>K& kª³RÎxÉ É<’Xó*h«õ5ŸÜ^ëP¹¦ØºçFÆ›ÉÇ»L@ksN¦¡O÷ßâªÈ‘fÆjT:NĞõË©©‘p$`[¼Òf»™ğka‡oïÍù¾†*Òö•Å‰V™äG G·3Zè2êné8uà“4ÊøÑÎÚ+aåb4œ¤jõX–ü±•Ğ`†w#dğÑ#²Ø¢ùA®m¾Bí“ŠÍ8KA\¼÷âı-v×arãËÃ&tN¸½§r•Çİ“é½Ãx¦‘ºY“Y5¿P:ÈÚtSÈQ(]yİîœèâ'kÑ©f=`!ÖÄïKŠ[&Í?ˆ
Ô‹}ÿ6œân"ã€™¿F[üŞM‹¤e¨È±ŸÛô8HÆáÑ'¿¹„ßÉk“Z‚¨å]ã©çñ?,¢äl]?³K¯}	G{›ŸœşF%Œ0ãĞ,œñú€ô¸€Ğ7Aœ¼‚÷.‡ë‚ÎÔ€j•ĞüYi8üyyè;RwØšI‰ÁÄÂV''­• ã˜SÿßÒ¹/fjûà}nĞá«ô3ä+ÿ’[5p&-îëpjpŞÈ4-ñÙCğB6=8ôLÊîn³ô›…DL&Ä5<·£ù˜¾ª4}+'d´ayÈ˜‚™î5´¯õıĞ¸çko|Ÿ$ºÏp÷’ìUÒ^Ê¨ç‘ñ17¹r/ğ&2nÓªÃ¥“$?nvêûÕŸõÏY<¼0÷TY'IPÇmÇy_2 ;RTòÚÌ[ğ›³™D/ZÒ“[¨´ñÚ4têSöÀ€!Ì±£ù(šu];9¤Uîj ²DÆÉµùJ00_/P™sÃüšõš¸%PJÃ³Wxz×hŞ1®0ÃœyÎE’QÂˆÈ‘fJAIÖïeû¤f«@v;{Èªc'3
b¿>§Æ’k¸ií€j«ûK¸ü€÷_ ©Å¾G
Ñ]˜ª†h!’PF¶Î“…BšÆTl5wiªş?ü}K’Œ1ŠQƒtV²ú‚’£Ñ·­¯ÙàVĞ ZèãÖt.y“†ÖŠ(ÓŠ¡–Óa¸k3TËDC©Jgè¢Ğ­7¢G;¢ïlÚšÎ°bg¾D¡ò½©ÈFÌoõcgÆìû/ros¾r/¸–-qäY*9d–¹H…B¹¶5húÊ#³X@¦%€k;ºÂ¦ÜÎMG—­ãòf¡ xÌ®`2Úÿâ-HÁİ¥T£…6ÂW£Ãb~rÉ™›i1şè¶ûØ•» ™=uµ“U0”íÙ@ds-¦ø{öªéâL6hÜR€UæN™­¬‹Œc Ğ xô¢ÛŒít!bìÎÆK—¬€Šv6ÕMúø§Š`ü½‰ÃWfÖÏO×§kl-x½ıH?O¥9[ºÿÈN
¼jYi­ØaáŒÓ;Öãáûyrü_sãZ¦ÈÔxÊÛ;	Ò¶&'\{îbŠ·×û‰m°Ğ›ññËeõrµD¾É3‡iıü¢N¨Dš%;µ~;ûº«Åœhİ•2¿I>#6^Ö7´±Ê¤è<˜ãA”¹è4?@¢—xî3(V'İúôüR%"SiØ/KD»9iL¿¹ş{Xîzãªªır}Z˜f@ùÕ]@¡KJ¡^yq¶¶œi-Ï« „ïe´1HB7–³f9UL«ÿ_²;ÏV^V›5Ç¤ÈËÉVâ=ƒ@^„R÷ ŸÀ®	ÿv°ÓÜ¯ƒ6)B'´Ô+™Ş¯EÍÉİeçÃSìß>Ó"Ë†–¶ w½¦.Ì!í x²ÒM+ÂÜI”Úìû|5Ïá6>‡åÈ–°öÄê]’•£ÿœ°]8ëõXÕ”¹Á$Kğ)Zj·B‘±)”Ö_Z)|(­±Ymuy £dHòm]Œñõà¹U’?†´9•µÑš“BºBÇìj<&6ÇQ¸Êƒ
¶ŸúäECrßÏ8–ÁÇu'fİ¦_~ÂvûY¥r€¾tTBÊ—X÷0$E 6,ÙHóĞcC¡ÅÁ9‡S£XOŸC*BÕ3n™j¿—}ú>(êyÈ•ïBgı‹ß½wõ½øÏ¼9ÆŠ%æs8Øßš¾Ç¯/ìPŒD\ÉóÁgX4}² =©ëº²Ó:—r-„¬íaÒÚmŸ±+¶©è5kHú!ykØ=
s¾³úòŞAÄrú~š¸Ÿe®“iÎzK­)÷ÉûSÎPö×rwS{¼vó­ş‰~a°"ºÚ¿M «KóY½1ânÎò;ôâzÇ)"WNYĞƒÜäÁpµóËˆ3¥mTº×Â'xíb©ä9oïÃd{c{ÊÓ˜¨q@„ÃĞo‚uƒsYçğ†-Šı|øòoØ–ÊæO”ĞX­¦ÇÃ³ }ÔfnÒcœşhêÉää¥ŞY!­)P>g¼˜úÛî.rÖÎ…(©÷í²yOÅ&ª9ü?«œpìª€dËŞ¥ÆÀŠò.ö¿•ãu¨±“‹áÃy ]‘4$@;qğqõF4/<M—»NÏÏº{Ô–l&÷`²f¢º¦RíÃÑƒÇ5awgë®ÃÂß,Âtø<$rÕÙ°£ogNIî<A†ÒË-r€C,~ışÔ<rš,ª=è1'|®Edb›‚ü ·Wôp½æiG÷d`Æ†8ëbXË#‰t×.ÜZ Æ†¨¾E•TØÈÊ˜Ì“[õNˆ.ş ñ«~š%¸t]2¹ö„ÂKS:Oím£YÇŞÁïš%,‡ñT5^íò¯ES,t—xÕnw°ku8úÌm–ñ#â
[JâÔ~‘Bö—Ü£;±CIFØŒ¢¹Q8ö"SßrQ'¥q`É;#@íuå ‘¸ zÓ‡eáİÓæƒ‚çO( pş2üÜvO‹½›¹‹BEQ×ta;ø÷éf¤(÷†?¼»ÿlêÊŸ»ˆå'Jšad¾
çŞejÈo¢äô–¾ÔE§î{øëU Btg×µT—²pù
Ø&F´¤óø‘r! q}­wêoÔéüè7~{¾æ¸‚õ¡·\`3ŒİÅİ˜ø!x>t¹‹Ò`\É¥9Ä9Ÿ¡|7Û®Šå†W‡9«è¶}=×%îK}
e¯ğtÖ¡’ÇUuaï»“[ã0Ç*§-Ë‰V­ãŸÕKñ‹sğÊ¤1pÇE¨mÄ˜µGîi<¬I™)nN*¼NAŞeR¡UÊ|l×¶ÑwÈ4ÂDDê^VH6‹İ±çêeáÖuKÉ£}3zOV€Á­Oß¸ûß-úL}0OLh®³ °TÓÀ²Sê,y$tˆ­{˜ù‡÷3;œkÏ^Nc4°v·áq“P`EÖò+èÑë$gÖÿa)/ÙB%úåeâ°,_Ñ	*ÛšÁCy`q"¦¥ ¸è®g‚nJë;C&”^—eÜsœÔ48œıPJl…\û¥ŞÊ»ÙL{½‘‰Ú;Ş²fuÈeo®×“ÀAæ¤ÉÁå?×¢=FNâÎBw¿„%¸O¦8ÍWvå:ò.ûÄØ[šzÆıŞ ½wÔ°`¡és¯xş(bŸs©°íe%ğ¹€…+gœƒjûÉ´–-”¦Ï8`Îµ)+ëEO§ÚjÉSˆ¥Aáÿ¾™³…äûTËºæMcNŸÍ„³ƒ<Ù,ˆ³Ö¡¾|áX)I@Ù/5íõ±O<öVq;%æ¤Y‡š€šµ>|üqqÃ’l€GYIÈëí®Ïúçiç?©ÛŠƒ…·“Xã*˜?ÄªmuÖ‹U†û÷<ìi•^×>€‘ˆ£.'˜)Bh·aœ~übò¢ëL×Œ)ÓæßN»«+!Õ›\¦äÌä]öİÂSƒ‚µ½¬™‡ãT"ç²OKÿíeß”¨M‹KA#7ó„”£ÑMš™'á%)»\$˜ŸT¹‡yqš¢ú‹'®rÖ<OR ”‘R¤uÚq´‘ÿpØÎÛa^«¿RA‘`Yüxœ%yt
än«ØÄêúırÄ=œ¢›]Ğ$Ë:ou%õjûß¢¬ÓQ6ı_¾f»1ì
Îñ)EÏÒ_;ÖÔ:?aûŠÇ™-Â!éXå;P×‚óqp9R]õb’bŒw¶‰«f¤E6M3` Ç÷S Şx²¬	CX(a[Ø{ÌúJÙ€Å´é=*(=Úó™*Ù™ğrŠzdÜtÑñ£{ ÿ|¦	«8ã$í$¨gÈûÑƒ¨½YÒ¹½c»êÛÅG·¥<=DÏcèÇ³ø±ãŠ+Ôsà˜cUë›BhhÆökcºX?˜.…†ÆbÓ®M,Ód|*òå‰:”Î
tÒåƒ ñnˆ}søš¬ÏÙë¼RIoª^Ó­ÒŒıGuÖ³ô²ÎO¬wTûâ¹!óÿ$gwú†lì‘ Ÿt(AûGÈ×H=¬F¹Ô“ q,“_Œa––ö+aÅ…>·[Kk˜`$$oµ7u•	V±Qÿùõ  ú¨Jrœ²©,¬bnhÕØ:Ÿ±íp[!®¶:}ß¿šÜAíª±½ÑÂ ´_
AÇÙAƒTåè#	—\ëX?@ |jY'± T›Äã=ıÄÆC í2¢F±U2jY¶¡¬æÆ0OÙèõ¸²Q›˜Ï
_æÉ•*ãø~IhÊGì†‚TòEãPVr[6¥`úÄß~Lâşf¤”	ë·uöÙÊ‰oBıß·T¦>Ó%[[õ‰‘`Á5‘GìW r¡8ƒüê˜bjç×pøê~|À%3l¯ç ›c#/ö1xöòÅÕ“Ÿ:£*a+Dj§o7hİRëBÓpmóA*Èá›6éMó¢Fá°Ä&ËúP³ÁÖCœKôÌ]2R²ò…b¿	ğªE8Àé¿4Ë„ä~Û7ôê·J~£P[ïY‡Cªh</Íß"¦…¶µWïT±¾¶õ#H^àŠ»Ÿ£ÅZ ş»)é°:Á¦ÊÚT ûGêú ‡¨=.íıÓ*í,êS9ôú¨ÀLjÁ84Eb…ÿ«§ÁyF¹ÚËÓ€Ÿ¥ÎDæñLpE¶€qhñ%4ß¦ÁZıJ4àS˜öª$9 ÇcR|áĞîÿÀ§¢%ôGQGšÿeZ½¦_°
ğ[UFxæe£Yn½’Î›™Æ,bft8%&õ}àx”ç†ÎÒÍ5mèAPÅ;ÉŠ‘DÌ‘c¬Óß–ÙR©+:÷oÓóƒŠ´:sİ¶>¢×
¾UQ»òwĞŠ®q‡í EjaY9á†‡ç:Ñ!‰4±A†PHÙ}™.Ò9Š>ç­‚¢µÊ¾¾	bÄ˜\I“(çÈc§\={‘®ˆ¥ıìst‹ùy~Dd÷g((¯\ôh‹®æ6à"7æÁ€”ò‰gÄ!I	3íğ î-Ş¸Éóï	;w¸™lÇ$Ç­š	kî`‚^Y
ò~"½<‘A“.”¢ü‰İ¤¤¯Ç2+¶Ì³Ëqtêé)¥İ:Ç»ûiS˜Ôâï=¹şÏ·ıBÏÊ‰%„pé*%‚ˆ¦Pƒ y@ùö{äLş·1œ–ìØÖ9ABEÆáÁG'Î#V§Hç">øê¬ôœ‡ê˜¤™Ş$ÑPAlH®L.Ø€bØÛñ—Î¯Q^yeË[ø%KP¤ÑTÕ-Ë‡qˆë$p]Ç™ “Öx‡ h˜9Âe¤cm¬8ôòåïjÈµÒ$tÓıë»¤eæ^€{& Ûá<{Ó+óßù¡73íÆ¸d&|Ğm$Æošœ0PîĞ5	­m¯æsX»D½@½Ğ+ş¹™–oÂO‡‹µhB 8z2,¿ãÜƒŠúGLI:M®˜êXuï€§ñh‰oï^òÃˆlê?¿"ëfÙôuL€'¤{[©=‹¸å³¹”8Í-j)ÑÂdÕø…nm~(IsÔ±É8p¨¢r2«Gë5‰ªUü:ö €ÂMs»/¬¶X%4nĞØ„í,ä	sL)ÄBãu®·{²42Ï(Ìh0L0Ì#>iãªğ²‡p¢Šæ6ÿ$
<Ÿ6U7E È;…°æÈ‚ş/:èÀ‹©as}İß2:¦ÈOÍ! ex‹wÜN$7qÃŒ]›÷áPçCN#v¡äëùT®@å)û‡'aÂ50ÏğÈÑÆ9îe(ªĞlâ'oØè¦²‡ê)DEí3°“Rx»úšnÍÀ¯¡ıŸn[n)¯#Ärƒ8Ë0šâÑ)/w*YgÂ‚Ê}ô,æ!Ïß£[_Ü…Ë©£İA‡ã9É¯ò‚B…¯í°€må:WÁ„kcPs-Tù‡š!ï<¯·Ô{ÿ	ãóhEí´è”¡ıºĞİäq‘¢¿sÅof:w¯¾ër“\_•Aé·¤«ÜÈSdÓ¿^l«¦î<+¡ˆ”fÙ}5ƒÖJÉ[©}mzÒcã°Ò(§ ·ıŞ	w¿äx†å–,l&V‘_#âFM‘^<?Ñ­8Œ&ˆ¤x
rüw/_¸pC¡or–×“[9eCÎOfÌ’‡ÌÃ´I;<UREoRmÂEÏ%*îjà.’ŞLŒô…LB«ˆzğÖ“U’;¬ŸE³~BØßÍEw ZU‰·Gi:t;÷Œ{õÜ×!æ¾¿¡øœz– œg"%V\Ş©–\& óµ÷°Z4®y"‚°ÿ©âÔ5š$Œ›ùSı5¥]>	:é¯Ë|Õ%PWËœ÷œYl—rĞHu8ä³?Ş3ÇÕ/ĞvĞ¡DàBRÑX	 A±-a©àŒ%….’½ÓiÄ+ñÎÀ,~Öâ_Ft—k+É°ËDˆâªÇæ×$9Úcf÷ıĞ+^S)÷úªYÖmƒ"äl˜PÙ¹»à©Fóªyàì@_7µ¥İ(Jsø<fö8ã®0ü@–N‰æÁ~ß!yfES¹èÑ·Ø$‰ª‹÷nAÖœ97jj¦‚ãdaB²Ks5’
€iÿÄWÔ§^Ÿã	ÂÕÚg[34`;!;+Íjø*Şè¨0•B¸æÙ0/%5™Ê<_/2®jÂºcqÊrµLºø	àÃÅ—<½î‘×jZí#»<ô€_«uXQtY:‚GíŒC:€˜¬Š?ğXñÆğî¨+”æ	ªUş›Î2¼ØhŞİV +ÿ¸dDÚø»é¤“—i…ÿ
íc;ş)İŸ•u.Mùh4¥˜Î ÔÏB¾ñø¹Â^Cİ(¸÷âÉW1÷y ”{2ä¤Øîı½/áÏY`–?Ğ‰ÇZß¦-Eğ ~Å.‹û¦$Ÿº§·_Ñ”İ±t„
ı sØ ã[ù)Ãi…/ÙÖäbôeÓzh›ê#Íßç¤¯EyEG«¦-uİîÄĞ‰L¿Á)ÔÅ—ÚÃ¤üÒëë-«MrÌé¡’Šf“/õ|U€>9ôûo–i®9oÉV¡uVœ ÛŠ¬ö×HéùªõóË	|(í%êÖŒ¼ÌÑİ|v¶L¹6éù1xË~ëÜ"âo’p ¢¸Ì&U›[ ³ôà^Éxq4`çsXéßXòó2(HïŸ&$z#Éê(ûä…	\CÍ @,$[šg£ó…)ŸêšRœ¯ÇŠ–ù¿Jõ“˜¿–)*SÏÖE‚ŒAÉašïa´'Î.¯I…:3­‡ÄÜNà³ã9¨k †Šº•B¸™-ºd\¸m?­H¬óÅ#ŸõÈY”øU*qâÕ¹W¤_nıÆfø#È:B~º]k¸7üt£{{“A'üâ·n M¬°&éÍäğ7?°€jBJvš˜ñ:o{‰ˆz8i¹˜˜TSuáuì†$WY!REL²µq˜6su¡õ®Ê”ÄæzW’?ŞdØ!…»\ä±ÑùÀ£´˜-òq••áE‰Ïü–­[¼¥t¶í:10Ó=P£ˆ®†£XáŒGœšEè {a÷è÷'Ğ´Z,Í+
t¿™ÆØvâPúg¹®¦2«±¤™¢uv9()ûXñzœg¥CW‡ıè®s¡Xöx|»‹5°¬Ø
¿Dş+aE
Ïµ•‹b©©ø7%+HBL>èÉšæäµãÊÜØ$,|°}9U)>Â>®„7ïï”é¸e48Íˆ6*!ù?wÔ8[¥í™\ˆ–×F}‘†Ê¤¢¢-áâóÎ‹<=WñŸK„7.¼Ì'ùË?ÿ… k÷şåÅhq8ŞÌ²˜‚Kes²®Û¥y|X@º­7Ä¿¹ïX;~~åF¶sºà®;Äu#1Bš¸Ôùø×;ÓJL~Z¡½Kò×¯Fv-|ïÏŞM3İ…ği …A?%¯°ˆÕƒF)€jôu»»Íò9ì¦õŠO^x¥S8œÏË«£x!•ïlKÿÖ}aÇ÷ùdúTV¢­û¦Òå‡SÅõ”l»tÛWÅ“¥4ÏÇG„ŒÃ‚ìœu	f>Õ1×æ1ô7™ªnpß2vQz“LÒ¬+»’µK/İ¥}Â7ÙöºãR¦ãÃv6~?]Å _!yÃ eu<'üî‡|cRµ¬¢Å“¼òGbäf-Â6ÎNİ}Ù‚>PA½hQSA.sSmù6ã–.‚ÛüÓÍ²éÂbi´:ºü]= }õ§—)K,oÌÁÛj{Y—ãYRœõäèı*ÆæÁåëãDò{£nmŞ `n“~ÍPbÍUáOz–•˜mqZa¨Y˜aœıµêºÊ+Ú/YZ»ÚÆyÈd¬f¦)?7K$¾Uóï©IŞ#Ø?0*’Fš§èÅ)˜€/˜iKë×eÉ2vÄhÀ­'¯ò}~êãàeı[F§xÅ
*'S—¶ÿ
-¦óXÀˆC ?–<ÏJe(ÿLôÌ÷ÀAHM—:›°rúˆªPŞ0ûH7T¿s†Æ¸Ë•h.ˆí²»{èà¼fTİAÌ?BêJ Ëb…Ì{‰xı	÷  rf¨¤ıÄ‚,pÚ\,¼ılvS-d.Qè0NZÕ»h6àšåÕğĞ…Ñ!Ûã±<¸
³K^‘¨xŠ1u’elç³8ª}Ò|$ë}N"~u<÷ğ>rb®ÁtD1äBß6‚¶ÿÙFC½1‹œMƒ»÷Jµ›Òàììx`KìÄv±móğnº_¾@€jêU-,P™ú;*¨C¡™|?\KÃôD8ÖPiô¾À ä#Û’@©+ıdŸ´ˆˆáQĞ&¼iGÍ¼lJlå+ …£h+Åã ‡£È¦ŠdMX‹}²9ÆçËî§‚¤s~ˆôQ½ë0›^6ğæ?p´UTxóªÎû‘|"/ÓÅ’;Ëe›‹ŒnŸY‘fqÂ¡½†94•Åob¯évªW‘¹8g/rÌ¦-øÛúÕß5òx®Q«iZÕ	YÖyŒt„ÏäˆÙ×
AV'Ö#=gPë¶Se4h¼,Ó”@ág)¦d÷›°'*Ok\t^ÖIL‘=Áx
F^&ä‚Széa|é­ÏØ]»Ä4h¸!Ã¬ÀËìvgÃ?“œUñ"6''1$œ¡â¬¿ZîGè/sÁ”krŞãü¯xÖ$Ø´¸³  ôBò-‹¯H«°ı|A„)Š}ë8¶ —Mœùa@¬¦ÃÂ°:ÖìÎù4fdçÚVvšŞ]%ü§Å”¼’ñÃÄª]Ó»ëö|®‹/™ Tü*Aª’ıÙì8[öé=ª¸Òõ‡GŒ~›‚ÜÔLZn¯ë…IàYQ¨ã
WuâLAU®Îh¼ì=ëc‰fí¦²QµX®•°û¬òşè[’mÈ¹opù«tíàDT²Í`d#¬óë÷µsôîê¨Ù1å×Q§›VyÊveÕÚjêvqkxÀ ¼‰¯ab3dÇÀ·šOYäåÖú„t‘ç‚&šÄ¢»e" -2q±ÉÁ¶:g©zƒîDÆè±ŞéâfØ6a.µŠ ³LÏ‹z’Ö°¨¯S[›y×ëòTQÜö³–Î—YlS`‚´áO‘4·"ÌüdB’I0dŞ¦Í»ìî£åqÏpcF¯9èï$İy˜PëÇ 9ÎÇŸî>±Š©¨Ïu%!4jeãR’ç¤–r?.qRªø§ğ¾miòè§RÁæ¥‘6ôv<OäŠRÛ™# ’ªu.´iÔå931äCåWæØ×#Ùª¹ÒX"s1#àµ°=¢C…n±Ñ8f!mš]¼–õ*.ƒà"Ÿƒãë}2›~átÇ¿˜‘#B›y{6¾­TÎTìu2ØE\Œ„{¸~Ğ?ÅƒvˆÊÔ›MXÙôˆ¾w)İ+³ml_gò mX9E5Vè5» ®@±' Ît³hEĞnÁÎKş‡Ä"Ğ|²J'a€Ïo3‹4ãÃÕÉ}Göİ$B%+˜[½ò…(7ƒ²'oÂÇáñ&mV3[´jøcÿ¦2±·özËIv¹ä{XQ10¶_ è½ˆQüUîua$)³k¡è—ïŒÀ;Deı§¨|%­È%<^´ç»³u6Ú{/'û²À”|X‡c3—rîccŞQy×ÿò¾néf”XM×Wİ¦ZGå,p€_Y\Ì†!.jÁÃe÷[¾us<–“²¥¤È`¹¿uÎÅÕUN<×£»éÍ°òiÍõìiÿ–Uÿ™ï¾Å³éöœ®³6ğVôØ?WŠ)ë‡X]İà!ZĞßãşÃ|GÂM7éL>¾½ÍŒ
êò¶jSµdŠ¯e?I5Öeê&à@â#õ¿í¦¾ÌÏÁSH!Ã¾ËÒÃ›‘qe\ìAŞRÒÁHa¼õ%	ü{‘çÉñzÿáº¦ğ½Ö±ñ^ñ/Àdg|»ê1š{Î¤=«µ›Á["H¢ˆJ
³ıyÕÍãK8µBá÷ÒæÂïöo;<­ªƒ³ÄÍç
MºQk×ÿ	6Ù£`ÑåÕ§¤:ÔsÙÍ¡óÎ`P–;JŠu,	”üp:Go¸Ú÷ §ŠñéèOºNÑê<Ñt~Kş7È«uÚ–ù.8‚#ƒª…Â[çîU5ié€hÙ£õ:‚ù4w7åÄ65[Ö:¹ Y?XÈÑ4Äã‚ûüf£o.­‰¡Ôè ¬±Ò²ˆ rú–©D>~£s6®Ãˆ79`Q <°D±[Xµš†r»Ø¬+§¾n´ƒOõgÈ{p%Öa²P=Şo>(a˜ÀrjY¹’RAôtÂpgñğ˜³B­#¨:Î>…I5ôI‹£T›|¿<íí¢N½µÏï¡æµSâäM]é¹«½ÁÕJWwƒgâ;åëv:ï 5{I1ˆÓ~<`ÎÖ;D*zŠ¢•bÑ²R¡Å"H>*ıUè@xJÇ'éßiĞQˆhB¾4ZõÀ*Ïª)\=®ĞÂÁõ°ÈqPË,¡¾êz‰B	^í½Bgëœ1±cãÊ˜_Ó
 w²dÍ0ÿŠ–mê.?jôc¼9Ï¨Íªç™¾Á³QÔu2Â”—Õ‹0ö8 Uúnøu“£§tKñáŠiİr‹O¡-»ğÖ‚”wÈØğr­­Dš¹-±ö÷Æv_8ì?¦Ú‡“ĞÒt…íiC|¨8%S3})s(!¬­©<ØäéÎıõ#¬¬•5ØPÑáØä†«C÷/`ZŸº(Qnh~Ö
iŠœ˜5’àXeK©•8’¹½³ùöt;uPIÀ­,c:s’­õï¤WÊ¨\Rf_UL”ûô%Šy^Nc2ñJ5Æ£z?•e¢Gñcğçmƒ1zys¡Ö¥àwğwÌ«£\Å Şiq*©ÁÀaÇiáàs¼ğ&Ã!“¯‘P¹œú‰Zÿi§Dw^şÓ.N3®Ó{ÊJ[2t êWQG«+¾W×y¤”„«Ê¦Cˆ‰Ä`N£¤ò‰:­—›@#®­(qC…*óVlzé)$…ºš¹‚å,q¯ã…X´½`…Äš&Óg–ò˜Xßk‡ÿ\ä†HÀÑ"{©‚yŠ,t¼÷~pßŸù¾¡2]¤İf]¡Ä¬º`MÚä’·‚[$“A©hÇÍV™Ô.Óˆ*C}îDZR²‹Şpge"ïfgc#•ºn!d>İï7¿‰ÊÌyÑ«:~ü$PØW¦Éº;òT É^Yªyf`ø·,Û!	°¸Sï)sÖ5NÚàâ»6
okí”®_.á®Nã´mÜ•M8``c®ñ & šzİ1éK,8£ Ä?+UgÖ\®Lõ¨¹RC‚8ë8Ì-r–…G­£:]Gëi›½ózÈØHâÑz›ei2G¨æ›¬şÛíY(G"´¾íİ…fğÙ]¥€›e-ÜI—ãœùy*ºP/ŠoœB­"ŠT×Ï'UvæôÆ|œ—S‡ZÄ:”& Œ[8Áà€Í`h>ºr]†C¸Ş5«oËâÕ”.fj¾Æè,ú=QÊz¤û§$…Seö­ªÃ4ÃeÍ=ÀAĞø»~â½î®¡ /^,r›¿­f¥´Ñ1ØÌêF¤”Él.ŒÚDÂ¹ª£[Ï>}©ŠğùeFF‹€"ğ«“Á5fD`Kr$Ó¦Ğ"_(ÓwG:Jq@˜,uèPp…÷R´m›ë¶µ>P¢õzï@8»ğÆ÷X„{ˆ¯%¤åXX ÀxÉŒéÕ¡"¿8á¶byNÉÕƒÉÃ¨)~»ïÁ’%ñºè/ùä*Ô>jàQÑzc	KÛ¥I·,cÉËö_¯*%2Ñ¹ÕŞEô¡Ô†D†°Å¢()M–UúrwÃU“‡UØrqÒ}¥decç¡é6‹wÄòåøXóÂÃq[£8‹·_‚äpAÜ%ÈˆH"Ï=p.{Ÿ¯#Ä®ZÇ÷%°kj41ªZê¹•Ù[Jç-Éö°g‹šÏ€şÆXIş7ÜC•§ó¤*ï—¬¿¼îÅrãÖì	æ#Z=´Ï%‚±±B÷L~#\,zê¸ˆAé’ŒÅF
:³‚¦ˆ»ïÈæéQb+QíÂ…	ÓiNÃÈ¢
84¹sÅ¦!sL*CB·%ïŠ‘ÔE”^(ÿã•Ğ¹·şQ û °n»]NÆ	2*­}Şûôç,P¤~¦›‚0S`åpÏ‡.ç<(É–õáz#"ã7±ç`„<öe`xÕKQŒ=m¯Ñ¢üÕ¦87äî¥µÇàV¡Nî„˜@{ä<rÑ@Å†ğlI2"Ë®È¼•1²CQuW¹ôé—·Ò#}Õ¬Wÿ‰-úÑ¨ÓE¥¬ŠÃY¿Õ‰y¼nª³øª¥>}úM‡ê‹"˜¹†+È‚{ÜX^Ùø£ùªRèŠWosWÑ$Q“¶•qF ’N5O_³‹SÆãfCTÿİig—c.?mìÈK¤©NßîI>Ç\ÙŒ¸&pf]áïk»òœÃ¹üE1{®Pg`yRÿ‹Ñ8A»ë«àB¿ëÍ=H2X#âlÅ±w$;?w˜F×¶ßc«şÒ+^K»Vë²^Ó—Ë¬ƒdr¦•,ĞZ4åéˆCf£¹_{¡Å	è-i¦áBGKûÏ-´D dÖk4æ‰¥r>ğ©}P àƒù³^}"à…’hFĞ†÷5ŸµFtÙ”‘[«Yrv›i™Z1 LàãÒqÊ(TéÎùLW˜Ç^
Ámm3ÇlòîŠ,&µwİÂfî-}±ÊiŠ0Å?©ÜTi¹Ò"ıvgT.]ó;33Ú×Ë/‚ƒöïãê]l¯¥ ¤»vb‹¢X"æKÁ²¤¼éş&'ßé2VLµfD³ŒÀÚ#Ì	Ãy”$Ùwÿ/|(ÿÁ»ùê*¼|%JŠÅ÷r]ÑıïE¹âaèÏ‹“c!¼M§ÙZP‰y+AôÇÇ\‘h­Y#ú’P²d}y½d§”	)ªár¸ìO“µ] ù@İº[Ğ¿³/´r÷³s`òG×ÏÌDÓ …ãhø¹P¹
‡Íµû'¤ãQ‡Tó¼`ıdÈèwë°ÓËƒ"d3ÏÊ&®;ğ†nQK÷Øø„œoíØã´¯IŞ\:%á]†õÿV)C<ÙdßTõqÕµİïğÅò0JaÕ}:û…óíº5–—\°Âl×ÄÁ•rŞá©âºfe—¯™IfÿV:*ğùÛUŒ?í]k`ïG“åXƒşÇÔ”.=fS›..ØïŠŠ¥"3Ÿ¥¾³(£3»^¸–ì ³q?,ØAÛ…Ç2“Ø:¸}œğ¿GÃø‡eÖEŸ%ªBd¦ïi+ÕÔù%TĞ+[b{`NÑi‚´E„½•ÜDØß"1ÉÓÜd‘RÿœÔÆGŸ„ö» ŸbPj3ïA‹»GN—õ.x´B¡03Shl½ÔïÛÛjÄB«8Kñ3*7w…¿ù¡Î£ÚrÍDH3ïÕ|Ì²ıy#¥0µüUè4ºà¾^–‹¯ 2láÜÙqòñ‹æ<O•J·x†İ’Ov¡œ`ü¼ Íì:Ô“;B˜åĞÓıån€İtiL©Õÿr´Šr†…•;ÍY§‚ğºSóÓ	ù¨|4ÈÛ_Àø‚Aw|h’GùGZÅºï×æjàA    *|^ÄEgp Ş¯€ğ¨™@½±Ägû    YZ