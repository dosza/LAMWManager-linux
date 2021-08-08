#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="4189614374"
MD5="ae65b54725eaea9ddc8bcbedd3f8e5e0"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23880"
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
	echo Date of packaging: Sun Aug  8 01:41:35 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]] ¼}•À1Dd]‡Á›PætİDõèÓprÈpˆı§eÙ§L«Ê"Œ°BĞŸU?@ï©6H[Â9¡‰ş—'søWé>“¦`)©¶¯$·I(º´ô´³‘„v˜¨y…•nÉî\&³ñ¸<âÖZÊ‚¬@/Ã†6NvÄ}ªgL99q>ø?œûÄM˜/É6,Á Ó”šÒ_C¼Ü£šïv">¢İ! `)új+\ü,6š%¾f¥î¦|îÓ¥#şİŸ İ[‹ƒ^ğ²EÈrxév‚*éÛUpwïL#Ïj–ß¦‰–ÃÚÀÛ3VT%è(*n>#İa†á¦Z;Æ¡r'á¤À4®æÙ˜]CGC'aÈş	@Ì¤Š8¿yÿ}Ó+‚ÙwVîÇANU]
.AY˜R)»n{Õli²åEïFZÃÆ<×V^ã6€±ãW;M7|zxšI×©ÅEÜÆ‡xMä6xëş Y]AÓZhQ¿n”"6è§:rÜ–º6£ŠP‡9QEm"^›öŠ‡wŸ{Å³Gàñ<êNF){4ãYë-ÿÖ,Ömª|ås_¯“,^ë¨ˆ Ú>6µæáÈDLö$'Ïh{¡Õ¸xïFˆ×÷½å;v°Æ±vzN”Ÿ»²°ÚÉ˜xw…{MÂøî†FI®suiÜÒZÎÔÅÇ@x¹‡»Êò O!A}3š-ôl*Ç)prxÃÙ^E£pm0“î`>³XgÌßC¹Yítâ.Ú<É'gc›¹FÏî&6ñìšÓåMF,_N¦¿»Wuƒ}2¶Ñ'£µÈÉÓtŒİK1YèUÀ”s9ç»Ë±Åˆ$×é¥sz]bhµW©<­rÔ¿æ;üİ…’>ıU¸)G>Ø+µr Ÿ¨op ÕÁ³iFÄÛà¸Ì8ìıE+ ¾¼ÀyÓÕ€©	a©6¦«3Xà‘¦šb¤»7n®!­ òDÚk¡t·k³¾Àp-AFÃŞåM ¸ˆíÀƒ{ç1Á“µ7Á&Ñ0oûşvfÆ_ºTF'¶|Şed,¤ğ¨ëj{æ#°ş
†w–Œ<¥Ş0,a÷¨õu—ĞtŸ¢RÖJ¿J¬!â2Ôİ_¿²Wã–tùˆHÜ/àè+”İíŒ­‹3œ”·bXn–ùyÅä‘Ñ€Qx†@YÆ‚‚ø¬;e-ªu±İW¥AÍ´`óåÌ”HÑÏîyñ¦¹Ú8İâ£€RK¹óV,Õì®1›°h.¤-ü¤ø–ûø ±‹©1–7g>ù­D‡†ÃĞa¯¬»F/¥×ì“JjßLÔ–¹ö®^Xÿö)Ù2oVö ‘ø?®ë.ÃEpBêjæ×n˜"8åûÉ¿(§í{ƒ9ù|tô*ÿJ‹n¢çÒâ¶ÒÕ|Î·ş*‘ÏzMÈ~@I›øGš©G®˜ù"Gş\É:¬Ù3Ïš{+tà²ûá…Ècøâu*Úô-ô.¢Su—Ë^»\ŠcşRp'ğ#µobüõûFØ*sÊĞ]&j;l-€DÉ –RN†„!sÆ……´u˜i˜d·4Íô'Á-Í0ùR"H¤E›ûh§?Ü!0uèØ$ü¤6J¾z¹Å„lÌ	qÜé+÷“œbÇ“È	Ïì(>ìÜN«Wd—äójmÄœrØŠŸ¾‰‰–bÃxPŞMÌ:š’Æ	Î^÷ÎTSõ1©ûrÉä-dzìo’¯7ã^5Úœ£GÅşÙg“<kü7¢Ï<ˆ«K€±ya§³Ù‡\Ís›Ô?Ùd“Gó&²Àv…7¼Š±h+ˆkİ·À¦àjõXÚ7Fçu@"¦3Š%âXĞ¢ÙCï-Vƒªv4¼a–ó½ñz’#†ğ&ş£˜ª —N©p0Q˜õ3œT)l-ë”ßQÍBåº–º1æ¤¨¥y/@,	rHìE‹Öüæ…fBÑÊ¨‡ORp#Ø+:+é’66ı—ë4iöá¬Â7ÂÆl‚W´OEÄ@7C”òÛN£Ü˜<½Ùây™o(D5öç=ÏF¯mşùµ_®]†Öã«&İšç%T‹°}ğYUàÂV$¼÷ÓIœ‹>J H·ùígU®ß–h6WTè«¡¦m…ì<SSvÊÈ†[ï÷„¥h²İUæÛ„¢ÚÁJ®;OmD²Y1k¥¸o²¯†Ôåˆ“ÆC‰ğèyúH°G%¯Ây¸cW®Ãš…oœA„u^yKWcZC†:\İ5{ƒ«GGzóD!Ìúƒ«G²*Úà3¾Rò’òæé4:˜Xû¼•Ì×}øßÙ`!=¡9ÚhD¬¾©QÄªn<äÓğî¡uFÖg™uf¡ ÒåG~ÖNLdŞ†ñõnô0+¥ÌéFÊ#Ë?œY!¿„¿,.Jtº ÿç7?¼4=Ş-ÈhÿøPSğ!S´êcK˜öe‹;f‰Ğ)¦ ±äªfPG{ó¯{9\7d4Å^6 KÑÌxL–}Gá1›ı`Á´wĞ`şb4£à®;Ÿ¤}½%« ³cŠP«¹cÏ™úmFTÜ¤êÚ9?7´eào´]9´ )"İê»ág'w[F“½qæ_båçR+'ÆzÑQ€ à¿œQ+€W`RlPŞ¥DÆw¿›œ­YU(¼"èŞ£¯¤wĞ6P„uÃ8 JPòúŒWú´ZFs¬¢\×fÆ×—¼VÙ'3/®êƒk—QÔ—ÿ$5¯í¾eİ ¾—rœDÍë™ºëÃXxÍô­gpn ğ+•ÇP†˜ê Ë=±@‰¯1¦Uì§îU1%}uf+pŠY¯esúzÄŸ¨@LázÎÕ`ÉÄ­Ù¦`ùkç¦(ëÈŠ9)$úáÀ‡ùÔKpO¯x'±…ö€­¶uÚ!xÑZ&ê…‰ïâĞZ‡C˜"€¿ıº]c©Ûe@b–A‡•(asr¦Ök&}ˆÓ Íªk=ëâÇ˜¬„(…#@wW>,P-7Œ§½¯ˆFvÑ„¯½NAdØ˜…å†c2¼OÒµ«B¤ItÕàvU¨SÏL„(¦U˜zŞnbµB@Şb“Ÿ	ô §,ù±¤èêuX&öRÑŞ|w¯VAU€ø¼¬x-´š“a{·Å)½â*9.P/ïäcgö<•Á´É&}OW!Svp®	…X;²ÜµÚXye¦,ï{½µ¹ÒÃ“±E4 ím`€<ÖÄLcÉi\g®¨øÈ‡fÏ¹¦ÇÕÀ–Ów‹§®ıŞˆ<õoƒ;e±'çŒ>1œm¼/ïJÛ/ís¢ÕÛ¼}V`XßhÏ)½îQ[)İÀ£îkD2ÈRF~¾"³<i.¿ÄRÈB3NRzÜ •Ï’'v@•‰•¸ç[;mGN{H×³dÏ’úEÄ„­Äàá&Î¹2Eğô½N™n)YáŞÜÁVä ‹‡ïÀ•8&÷×@Åê‡F˜…úİç5”NÉ,‚Ğ=ğ¥qW½]›?(Ï’²Â·o¤½¼ñ¤”9M†¶šŒ»A’OÉ*ÁÈƒÚ¯M=´¢J£›d×æQË™Ô2`şôâ8kùïN¶†³ĞÇ¡ ·&_A´#‰$Í¢m0Q0êÀ€„±š*­–…VrõI3IhÏx9F&£:¹Jï{]Pzõ	¿ô|XªË_³ÂîÑ…	&ÒY1œ(‹í`éÙLHBB¦×ç­ˆx<Áb©¦LCû¥‰p©€quÒ¼4O!3H ùïÊ­ŸNeÙQ\ùğ$ì©smFŠÃe{‰—ò,Áy‹-ÉHò"›GùæĞèhí0Z&óIQË|@š±” i;J)5şT3z¥dW‚56[‚)*’X®díh"Óñ)e?:ÒêˆßvM7É88Aâ?¹¼Ú5Ş^AvJß¸ğÒ%zN^‰c3-[.”éú³A?-œ¼·[›¹l£< àî%ÂäÉëÓLÿÇË²İ'ŒƒàÃ÷®¥ó¼ñ¯feôğ¡~	×)–Êç+7_rIîéJ˜µ¡d¨Çƒ€ÈE:ıiº½;ŞdËuñ	Ä}¼®½ø,w„,àû6Å²Á0¨ã](ÅîÅİs-®Ö¨µ.­Ÿ¹5&ët	Ş¹AnÜÕ“g©²·E>Äí›Øğ·IœŞÉù6Ö:B³¤ÚÊ±ú•_¥"$HKìÕ2½PÖ.•İ©¢ü´Àê'Û‘«Ş
cæ‰xáû/‡[Ø×¯³égyH§0o}şÕ¡”6ÇDr+ÿ‹İF	Â‰‡/UŸ¥Œµá	T˜¹Â+D+Õ7ù×oÈ:uÁVs
aj¬š8•¬îD|zg÷)>’_¼ˆ>qÏxÕc‹­v5Ã[;*V	üe;Šæ§—³|ÿœUŸ0ÀíY´0âeæ›î'dF’JôßİDÿä¼ÍØOÄ³Ògn=øû%R¤9Œ¼{…ƒV¶1…îÀ‰ÖDÍÉç£jk)«¹'A±…ÓÎp¬ 5¨¹Í9(±1B"¶&Z2àåYŒ-©şQb]¨ê8VÒïE àÊ9|ôfD.şsü~¨¡]Åîg]ú€\r"ÑqÕ}„«¶=¶ã·³ğÅXÿ…À9˜:J†f`˜aÆ	ï=~ˆ¦@„Èeıjé,jHZ_Æ˜ùİƒ&Ùé&¯¼~ŸçöÁëL™OE
$Z ¢<ÿW²Ü¾ù†ZĞ¿^‹6JÅDG*Ï¹VÙÂèÁÁ»…d=/ËbâzO7,İõ„AD@c¦ZÏ2 OgŠ¨Q+MéÖ_øg3xzB47ä1¸¶™ê/UL7Pßk
ù¾ÈQ¬†šÂ>pGĞVÑ@ÄÂ”ü¼~y®]“¤ÖXŸGº¿JgOg’ôT¬	¸Ñ}°lô·ÚfŠ›5ª¾°!e]|¸Ç~¶ÒÊ-…ùcgªÜeñ7W¡­
6!ó^êm?Œ°ìİ§3ïİjÖE4íÑš²Ø·§$ïæöŠFj®‡kõ$©ë˜êÍxĞ7M©'rØÏCÆÅjbTdN+BŠÓ—RİÎ@õümÁDe±ÌÜ‰¼¯b\ØDĞa’ xÛSwú Îi1ØŞYl ø—aiåeÖ¸€z…)•„-_ÅT£d²SÆëİ]#
°ˆr‘Sõs47²_D£ÙÖ(Ñ˜Ñ¯KõaWNgx Éê;ôp ÿ±?”•ºAEhñûè”Åâ“9P8+—ìşPÏº	 Y—d<fâ J
bƒP#á<	ôï·"”•ëöt3 HÙ)åÒºÿzs¢¶b>'šÁº!Òv°Yš¼1Äš=Ô˜sÈ^Ä&ËT:XŠ)½Û4,”ÂÕHë:ÊaûÕvR£R²˜®ú Çhëf2æn!=9K $ì(*`{Ø ïu÷‡ »iû x¶ñH¾­üØ"W_p‰	×Û:÷Ö¡Ò°/Ùçò•z@jŞ >ÌAUë ãÈ ;o=ùNí-02ØK´]©·4éş|Ó‡ÄA3Œ-™Eş"j"©~Œ¶®gî-"FIÒ{¦óˆ¤`¿sÊZz«•Özåi]œ‰2zèe^ä[Ö¦£úzˆ{¦Ì—ƒı{¨â‰óyÄê	j‰qrß—
O¦à¶¤hèæÈ Ç·ªjT9pUbú¾‰^wÃtSTÖ<j}çÔnL0!•ñ.—ÓíÌAèö]÷Œ¦ı8"ış›>Ü›ú ¬±^Æ˜"„›ïañ÷²f‰ <õ%¾@ ±Ÿ;§¥ÍCy‚÷§@xµ¹ñéİ°'X]t Ö£ºÑ¹8Ò$êE¿A\ß½z°şûíÀ‚öv™™·ëŠè_ÓÂ
||r‘É}]ª&v‘;4ÈºuÈ”NõY&ùÏ ³Mâé§#…r¬9I]1%Ï[ŠÜÆp¹Ô®=œ»äU/¯™a³+²ñf ÒÂ¼]Vş6*'qƒ€ûpÿ¤-€¥º	µ1zEäß÷ÜôÇçV×ÁseÏ.DEM VygŸ`]`w6È¬f—‚Ç¸Æ’1û÷ÇºÿF>ñ;JŒU×P2ìÅN¹~WÍæ«ÕKòŠVgp•Ó/>Y¨ÃˆëLhW‚nÓÌk%´æ œ`¦³…¹Iğåñ ¶æMÒ˜ˆ u6‰óüÏç8Y½ŒÇÄÓRşT¤‡ùG¼çÇtX§‡ oÚâW&p
´b±²<3Oí8öDš{½„Û³Ïër'ËTjÃÓál¤qZ¶ÕŠ.–Ôà±¦ÙÚ†óşïØÊ­Ó2ÂßXß	-š±K?iÑôT²UªÆ~6ıÅ·2¹/İÅk–öÂâ’ò].ğĞØ‡Ğd~ßl¸rœ›Yš4¬6–‘hŸD‰Û	j´¹CUíLgœuˆ‹†®*¿«v9İ÷1ÄşıFøv?Sr„Qì£AZs¥ÇO`¤ªkâ­íq5Tv9D™—¶hïlólúœĞ¬f1GEˆ[Xİ´“*ö¶hqì¶qGA\éN<u\OŸ]J Í7H-Á	¶·'ïÌÑWÅ?Øñœİy#å5`¼Æ,õPĞ±•3z¬¹ñ0ÅêÄ0×{|}…ëİhÆÖ:•–‡³Wy‹Âúr®“§–%:ê8ß×ò‚=Ş³µÇT?•@â=œôW(<^¾¿®ˆ$z‰‹?‡(ÑÅ m;†S ¨..o÷‹w¿ì®øÖûDç]Ló­µ]vZŒŸV*‚ËgaêöÖ….©Á[_«r'21›±Àíg8·A‰Ñ¿XH÷›”D€u»öğ~_G,·˜çú±å{~>náoÆl%1Òê½9yB«¢1|:1¦A‚<UÓ¼”âÛq>œä’,ó
/dß’ÏµõxŸCãÃÆÜ0µÃs:ÙFt´rÃÀêé5éÖÔßt>J©Œ…U{­I
æº4J^f}IÙ«^n,İ±+ö@²^*»kgi;{´!.¶Â¬;Sq+&'(b®a¥@º@õ4>ªUıáÈƒS/.FRımMecvÎCÚÉwòDbìœÃ*Âó•ãêy ¹mŒ ’6Ó›„å„[šiNÜ$\÷¹O?ÒÊ¨´q…c…ÃÓÂÆj¡Kê®»S8•gï¥Î„4õLFöQÚWŠ•Òÿ5Dj À¸‡Ô²
5p#àŠ=D½(ªósvGs:¾jV… m5eÓ‘díºeT„Û•ãÌ+ä(OY2;8ä/@ñCÜ]ÕvµDNâÙMıïmsÓ£°ƒ+Õ)–OLñòg¯_ ùÜc™#8‹®$T:HÏ?´ª^'‚`v/ú|dĞÂôòÚF~¨ÿGúóÕÜú®o¯ãÍ€P)«Î;Ç@Ñ­¹pµª®±ZDZ‚4(ÇqD!ÈÎÒ-ˆş%ªõŸ˜ ŸDgQ×¢G®ğÌÂY²î0usl”Zê'ô5C‰9oLÀ8	šĞMÒÉ/ÛúX®C¤B«’Fˆó<¹Æ¬DI€¶†:ÜçŠ:Ó£i+¾¾­;®i»(Ôç;?î@× µ/üèœ“ı¦£¤0K[Ù0»{$Dº©V‡¼$L+óz‚ÿY>SŠ*kYOxLâ>íBü—üV¶L˜ìG¸Qáš/§–lÄPgß(Œ BHğ¡¼µ(ñÛ¶4›5ÄzšğÑYñJØ?H<i|rÀ½”v_úîĞ™F§ÈcŸ›j;E²¹VwÙ±‡LG~ÙÜÒ§W9OÍJ5˜^r±Ş(,‹6Aİ)†		®teù=ËQ‘6çZÖ±tgÈËŞJü¶D3¦Mş8öŒCÉø×Ósk¾ÏF›F|AX
ü /#)FØ¦YkÒãã‡º7I ÃÕ76  /TuèÜÔã°R˜úC'`ÕõÃVZOnB‘µu?/´™TWÌ,ÒX[a; ÉYñëVyôıàX,jÁj®§óq‘œñğ30#oåÀ²0ÇñßpH…2Øş˜¡¶¯ôûü[ö¸{^H°qÂa.ÕÍåŸSùh/½¡ÅÂlıˆL»Ÿ=-ğ#¹·‘3‘5
YŸYùõ6[çÅ6~“h¾&˜XÂZïGZ50XDZ²ãÊ"¥éGoÜÄñ4-"ØS¦ä·õ5ØOQ	2æ¤J«è¥ø¸KFÇ`LKËÔ(7NIìWg«Ş_¾Á˜?„µ%³Î„Xâ&û¶t³¬øú´-
gşt'¶g $5ä$p¸dA®¢ô…Ğ×øîP’zYà·›;@ùò«@¢Ô¦ßğxcÈzÈG‚
»[ƒî•éÚßw39¡„¾ÊåÁIR\ëİ™‘åÖHñøê™œSí÷[ï86ıè­ûWğkpfQ\‚ ³M!¾ÊşëMË„Á‡#(­*0úìÄ—*++&1Â,*ïÅçD+;ˆ$¿£\#³<ÓÌvæâ!3“¯ŠIMnšÿÏ©RV\	¾ŒW¥»@«^Ş-NLÁµéíò'â–ŠÄ_ì/:gØMdMàLÜÙ
èayM8åD*ºö*\}­J«`Ùñ'‰Ó_@ëÎa¯†NOÚ×û{¹]xô±ÎêŞŞKÆ…Ò¤æòwR$&wqr*øuóÜ˜Œì–tàÕ '°4fê™Ì=|J:€»Ş±^PhBJ%ofŞE0k(è"8È<‰İ>øn~"Â9"PN#¡˜hNwïáA*À<•%ÎÜ–Bå‘ ÙB3"£QnwRYği
_.æÏLâ:9Æ/Kù¿}X”a‘ÿÄ›ƒóN_BïÀÆr{ç}ğ-@8sVìÎl&ì®­¤Åï}€^'ñBY8ÿC“ûíÕ cQö;Öé(‡¡-\†)hg]0<S€•¦Y€wâ>o·•E»ˆ}K%¼™¡Yğ³™îË	1qã\wV8ï»²¦ ²Á>,ØîaÖ…,~#ö	ÏÔ¦*ÖŞ$ ›¿/Ç<0¦ ‰\­Ï…=gò`ye9œDºÀXÕúX.îÔm]şù¶–³ŒwyåF¯½»»2“h³ºCù¯ò?³Ñ%#ÚÈÙ¨™Œ§äJ×??Ä#Ë“Ä-u%É3næ¨ÏçíìUÀ©vWô]Ì1=mä‹­BéP;´Öœ³ÉJn£á…KK
>ùÆ2Q¢A¬Åy7ã?	™l?©ó×8ä£zÔaîX'@ìn'Ï,¥7’b˜[ÔKg<³_ôÖá7«'6áreÿ¤íHEd×^Qã›VCØµ%š–ˆøãÊÒğ)M mªV¦=ì"’\Ò&Í¹úmŸÍÑ„“À!ØüP¸R“cìµ°s‡PûDâÛlËûH˜[JqÄŸª‡”r%Ë1øLMõvÄ’c=Ã	øEøoë¨é&ënâ¼ÅŞó"/¤HînZÏEÎ.øOÍißÅˆ9qéÚ‚z!´Û•Ì”àßğàCm¥ØXOÌù>l+mØHO”ß?:hkxô íÇ’íìÈ}#¨–ÄKÁ›Û»‹÷İî{Ó†÷_Í–l(|…‡u|Í-©¿Idù_œãjç(„F†ğ•/²iğ¢]­İNZŸ ¤w›3ş¯É¡æ´0ØßÚOU¢†ˆ?-DÑz’ã•,fÂ^2îĞ«á^øÁLj	LóK3Œß$Ä$%&ENØ4Ï²ñ½'¶)Tk¼Fa˜RœJjĞó¥›Ö¾ÇDŠÓ²ß'ÕhHÔ'y½à-®¹öğA£ğÒİ1I;;ìÙÍJ…[ğyğw]©òINzi¹ÎŞ6¼Lñ’éYd èİÚª`m&^â‡5]¡@nÔôb?¤7iŞÙÄÓÀ)hÀ¡W­ÿ#KÀşùïòˆ2\¾¿0™’s½S¹üÑ7[K¿_ì€#‚¦4õ–öÁ#ú¼Òm÷Ç‚n,9¹rÍb¬{ŒvÍÏU¯ä5ˆÉÜ>*üÑÚ“ïöŸßõÙÛ±É)'Ñ¬İ“Å¤0	Š/-r–’‹ğeıòõØz˜LLv!öÃFg|‡‘·çGÅydÄ@$
ş“=ë]%ƒÈäÒX`lw×ÔLšÛ.Œ‘6³Ãm¬X›3\ëXÓ–ğqğ)J€X Ç¤IÔhô0lª{ş}}\Ğd)õï:ĞÜ[•náÅ6û+‘cÂï+‚	.öÕÅÆ_J¤›/&øÌ°¢Àü=s­ô&|9g×{¾End„µ–nfex/ıU'÷$ÔüŞ"ÏÊÄ|{sËâÔ% Äş˜ôí(JGõCZü?Ö(åÈ#—$—ŸÕd&÷–œ¤ö£ÖUÃÜ¨LéIØ)c_‹£íÌp ia‰Ñ%-â&S:–ãsHˆèú©
[7cãï{5%¹$7ä‹‚ç7²[/¬«Ag)‚ßÒb&Bšwº‰±‘¡ºìštºÉ€†9Õ“vÑe“êêTY r³¯ÂO# «¨†<öû/NúŸöTBİ”mÀŒ×:Ccå<]7b–¿¥d
\ˆrğŞÅ§™‰U:!?'&´¨Iú?a‰i’håÜƒU¡ğ²E»CÃ¤ÅıÁñÅ}(4J¦E—fŸ5€bx:7ïLqÙÜVLÏ4a5‚à…‘f÷~-Úú½•væ¦ÇÕâ––Ëİv9wà8£¥çjM„ƒTí"F0üŠÏ39çÓŸ*¬ÏqÚĞ¾#kîêÓO&¹µòyÕ²ÏÓ	~^)fı,YiŠ`ÇìhÂúdoU‡ß5Ó‹˜x+¿F¶1+Z;ÏÓïÇ¨PÜ˜ñjé6Äc78‰ò²y=r@&„.4ÅØ,h~çB!ëˆ;{#KA°ÊÂ3âhßíÇ1ëcd<ÓG'>Î²Ÿr†Ùú$¬f5x|ò1=jÒÃÈAç{@VÇ¸g/%—Ê<-ˆ>š[KYe¬Ó­ÆÉ#ÒÑZÚyÎG2±.I{ãgÔ0ÓBŸD¿q Èuˆ÷ÓdBC:Ø'3zşuãvªá†¬¹ÛìOY]™B³z+ÏÔ&²p¸ù°÷Ôõ6‰åæ2Æä·éÃ6È°‘«òÒàãˆ·Ü —¹ps‡æd¯}«»â›À³¤ïœ™ëw¤<NZñï6o12IA4‘ócØ´ånflYNµ[ñ)oŸ¸;’ş1…Q”}ĞgHı3²È)íğn2¸Ozˆ1Æ4t0•_`Ÿ7ÃÑYÙëêÂOA<şñóá ø>ğ"Œêı>ş|Swb	iFK˜=Ne2şş1ˆx5e_…ídƒoxhJMŒdi?¢Ñé<_£â–ò½61>ılgÏÂ‡ŠZT–K‡ó[ÁFl­¦c˜Ü\)ÿ òœ+D›^u<v:³][;{X?z´]Ó0<ú9òO  ×*…ÌÚ@à¹E¼Ä°à;rô¯2Q$şR"É–01ì ”I"*Iàß€S¨oIzµµLW7åªvª5†ØîRvK;ù¶ :ĞŠ4LK8WêF¦öJØ0·q#‡{Ôá!÷øeùJ&)c‡¡Ğº°Û0Úk¢t;Ÿ–÷øE ùwf4\¯TÍ†é¯‚¥´JlÙwÊH \X……Üä£{ûIÈÉQ
öŒÃW“lÎ1.†Ws>€Í\1¹7-tNÑ.âÄ8ÍŠƒ_ÕëÄá®¹”&o×¿$Ê‹&¶“-ZÎ	Û!P™ŒPíÖèõA(“9$¬—oiT_È=Z](	R]çüã6!0Ï‰IŞ«P>JèÁ‰şY/¢M-(ÕT¶áîš”j&‡rîB€2¨âæ™_¾®^?ê¨jİ(@¸›à@³ à§™GëÄóÆ7’xåi±İ>P¹ŠF¾çœ}JÜíõ¥±ª¸2+æ;¬'&š@[MpºNÑØ¸ñoÜ0ëU¢‡Ë®İ:'IWpD$ÜÏ6gŞ,[0İ,c½Vú]OA„2&y$–ÕP ´¤æ×¤ºe€Y„Û½ëÉLhßnUzëEÂ8,;f..*a¯ÅK'§`&?BÏìN™Œw+Ò	Êñ‘´ˆx${åKäsDnèÕ¥¶[Ja#U´–j\’°ñîÓ¾Éwæh¡‘…:ÏğNˆ€<òl/ØiUÓfİc¨A¡º2¾üÙÈÎ	±ïû…»ë„Ğc’ÀõMÆ "ş°üÈ±½Åõ·˜ò#l%Í3ğ4’Áóõx¥n8~a%ÿüör#3»teÖ–KÂtƒ`Ë<¦Ğáp”ĞšşàÿÌlV&Öìæö'Óx¦ˆO$ÈÄëõ†«™ö±óÁ?¦Õ/ÀYnL;ÇÁF”Ä2…ªºP½…÷ë¹f4÷Şöù¸2älXÌ»õN½ğUO-·e†vu°Nwòf17F<áËéÇòõÕ4:)ÑdÃ{ı­ÖÈ°3KÒihÌ¹Şc¬6rßrY6˜d$åÑ÷f%§yùg$™OB~÷ú‚› ¼h7²ïH\…_3Àx«ØEŠô‚İo´¦¢²¿»GC
ÚÅÓO¢u¾”e`z*¹Êé×CÁû/ó/{z¡zkÍ­•üls±CÂÜSçŸBUÆú­yp+Q}ÍÓú@/H‘›åúnL¨§¥’3@“ŞÜëŠõq#Lad‡È© Têöm¼`=" PÑÛët³~´štêûó8Ø­3N;Œ™:üã/IM…)®¬˜c‚±?õ?ÀÄ•|&XŠ_z¼'äƒ-¬dœÑ]Û$eÂ¶4­Bk‹„ÆGBJ+øÓ—»­×ŸƒISŸœrmöÔ÷é~V³õ|•ûè';ğs¤”uSA6¼PM2~édµÏ3_×w¹†-btÅ£´wœ“æ'ï¤»üM‡7g§¹i‡	[‹â|0:úScm<Ñãµ«]µÕ,e	#ªtLÃY:Ú´9¢:gÇ´SKD^pûég²ƒœöT‡eK H=áG Z{zÒ%gÕ8¾´‹ÊÏÌ#Ÿ±Fnö*W¹ÍğÜ'÷1¥”\4Á<H¦6êÄ'uH{d}Ü“¿—w’fƒ>øiÇ=ò†aìÒä³z?-³uIXwª÷-Š'Æª·ñ¸>ÙGŞ«°ØP7†ÊL#ïÇülœüï#bOqÌRª ï‘?ŸEÖBfwÚŸÓl­åv
¤º˜ö<oŸëÓáHÅ¡]Ö.YföŠÚ Ù¡4SŞĞØ\*´Örsà6;rÀsUëÌÏ,W¸q¯ÅÚt8ßsÚRó+¸Å™·Ï8¹•Œâ`A'kˆîqŸq,r`È~Œfœöƒ†ÏôôNL•U©™ïæ°Õ[qÎ7¨ÖÚÀñ¢bDæ™ı¤¯÷#®J_©éºykğx¶§·ßT_€v¶-Ú¬1¥':iÓ¶L\¡ó[ƒlUk6ïKí“şÂÆ‰¼ãoJÂ¯J2½oF’°¼ei(GU”u£PæKîË§öDTˆ s—»>eÊ™%øL±+Wæˆ	+G‹ıNË¼$˜¶éæ„Z×¹^ØrÜ?‡}Û^6”î²Aƒ–Ó+Ÿ:£|†İn÷Ô,ã€lİa©,ïµsœÔö¡_pI/$„˜ñRÈSŸ.qj4pˆãeDâû9î.Ùiƒ3à	ªâ•®y“[5S)wú#s…2YgÖíX	¼ò¾
eV.»Ò´FHĞ=a‡å 9âoƒÙÔ*£ï5ÀQA:·§óJn0–6u@p‹b€¯‚œ½ øºÂ{_ŞÍÊp]L­/³ÎŒÉ	ÃÌÚ’^‹tâ—+Stõ_Zâ}¨¹wÖ]³«´GÛRIzÒJSOã.»]‰ğØ DÃùÇ±û	­îé½ğD
ñØù'#@ÂCIi?h(‚¿p&Ğ© ÀÉÏïàÚ€¤´ªí{Hé”÷³û0ıñ˜ š
	ª<’D¥Ü’‚¡y¶
œ2‹a¥İ³ª¥Ş¹#…ÅØ<Ş•(©J2z#™l 3‘4ƒ& ªK¡#´Úsî¹÷:/–•&u<gôşxgIã÷ø\œz6{ZÂ±k•Ô‚`[t¤GÕF5µ® ÜÄştmãÌ;CÕÁ÷WsBºËÌ×WÇ`ÊÍÄÌÅ8pe}éN\ííĞ´v–}	¹ÔvÍ>£pèû»‚´€‡ˆ¨ñï(ãøP÷yQÒÌ„“¹B›°·œÏ„”îû8Šâ¬ uhf6·Gï8¤šİ'“õâäÃ9¬¾º û&çĞè&	§¯Êd–¡î¨¼ÃA ?Ç?ó9½ ß79$8Kß[uhÏšÌ
\ñ$yÚyä¹îOé6¯\µ@•šì-.»×®mó&†TËê”¤e'KË¬Ø—„B]Ş­,³|;æ|ØhÒğÓé£¢#Ú0¸mÁ8¨M7Óí‘â¾>j—¼ÌE±;İVHŞ”è»wïqÚ8Z70zûúÇ1‡@7·ĞàD&$Ç¦ÓÅÜY!“K‚Å½šp×dR¯…w-»Wïea¢ãwÌÍap"·ìç©>Ü#vøé{ˆ·ÒÒG[êàDoqîÃ›­Î=Uü¯B¢ã{Ël]]s¾
-
Ñ!Çò®4ÿóĞc›–4µªXÕŒĞghò]€ñî¯%p‡ØŸ:	`9HÀó,$hË[<@êÂàµ¸¢§ğZı¬¼BX«Rlı—Ä>Á_hL@Ø“Ù^ô¯	¬3@±Ğ9Zô¯’ŸE+6Pˆô„,Ìğ½+<ÃLhÒ^?óGLº'‹·;ŠzIí$½¿(ÿÂÃŸè‘‚Î3½÷æHXÀZÃŸ{¥yü¹g™ŸmCCÖPîocßË bK;ğcµoœ¾57',Š!p	İ]LR›=„Îà²ôŸ—9yĞ
àÄ#	à&ÆÄ.®õØ? 0Ç$€x3«0­¥¾Yr¤Âø*#N¯XW¯3Ö 1KL+<0Ä˜ñ¾K¬W§æVàûÀ°ä[Zµ:Õõhw?Ørs­Q/…øšF()g€a‹·j5ü+ˆ²Ãh¼xN°³Ia•ö§’Ezvï›/şÅŒhF)@u7œİ3;ã{qU‡cK–+Ÿ!Ğµ¦ao¯ÚÍ 5ö(n•iÛ¾ø¬µ¬L}Ê‰’˜â“ÂUÎoI.Ë".ÂÔF3ßÚ¶†K·V±%("éîgY—*Ï£{Ñó».ËD©Xö’“.ÙÕ–“–…ÊâªükàdHŠµQf3ë¹?O¥Ï©â9 ò!îR¾‹­šŠ(˜0òíB¯ÑO¹”¨U¸Éğî4ç6=şm"Õbê{Ç^Í®â1æSÏ"àK·^·é¨”Fmıb½Ê=ÏOµ+ã¸×ì€…'±£}y	ËE®ĞçyZ/[Æè¦9L÷êŸœ}­ïÖS•g¹*s<ÑG|7ÑKbÂë×œÛj£^4R#˜×]2­ò‰À°—RdıÜ-ÏŸÃTD’]½“+DÏM]álêàîlå>7‘ÊÁ#“å‹»‡9›ş¹A¯ÒsïwãrâÏD2íX è'°/C›¾!E‡ošÆŸşQ…-²&;…îêÀ¶³ñ
r¨T‰sº]}±Ã4²`KÕ•ïõÚñ ” 7œ€•ô÷;/’é.×„m©™ÖÏYó×½5i}ÑèRvxm_È©uËb?İRÀÕfÔ¥&xùus£ â$MVAµa;ïv3F¹M>ÀSÿœú÷(Fm®L¡àù›Ãíª#=³!nu¡Krh›¤º`Hehª<DîBYê¹ät¤ÑeÄ`p–‹¥kšØ·ßièŞlœ<)+¼ä§*,ä0²	3¤y‘UŞ—3´]Ã›d¹¸Óı»ÌÍÊjlånx<Xîû×yí…õ»DpY?$¢±Nh;ª·X_€C)ã#½Né	 åöïÊº \a„vjjLZ/ìNäïá*!Ÿi}?e¨ÖÜÿóU#—WjV²5AdŠ8m“õûsA7²#
Rë îÛ¿B5ÇG%b
èãF.vˆÇX•øR÷Çlù×ô9û’Äê"%Ä9™7hıågÒ"ş_•€‘4T—'Ô%|´;4eQ;CÅNºIh0±lU ø°‹Ç‡Û 3ñ%¢WÎŠª¢e{íBåO§ÚÍ_³§õˆ-q±&Ágj£§Ol<ğo|òÖ[gÒ#ßƒıü{˜®ˆã€WrÌéÃ’å{«0T“íÈMv-^ŸŸ,ôü,Ü§Ô»ÃÇ®Ìç)8Øª›OR`JïÖ9°İà.~î‘Á‹£C&F)zÆpz+$‡Œñ,ü¥‹ÃdÉ1A$(;·Æíøİ%¢E‚Š2	Š¨ÌÁ»H¢UhşÖEö6†œf‹+¬ÃÿnÛA@.#’-òúß~Xû÷¸–«Œ4…üŠjÉ_CB3ı'ñJA‡~Ğ Ø‚®£.8hÚdP3){:Å]|0Ji u¶áˆíàºK£Úàœª¡ï]±dñÀh)àwƒÒ&S<ÓNB]×õã/^spY»¾UÊ"`Ù†tÓ±Ö1I€.o°ô¼§ÕÉ¨=Štlàçº[‹§´Í\´·?´¬l§IÌ¼Ëÿª›ÃUîú¼8o:e?#dß:DÀ]
?¶Mö!lv˜+Ç¯\ƒg,Ua™Ú€q6D
Aà((„¿øRºxËbiªÅ£§xî$¶Æc((lk©yòÁZŞcu/ÿÌs©ªëÂ SçøØèé#guË˜¨*ª¸JV	i•¢>X'¡mÛPàß)h¸nÅôJ/ÏS‡3&ÀŠó3…jAür¬§å+:|ÓªzÃ±KÏlâpb•3Xû™·°„K‡rC&8Xœ™!±ğÚÅlA=<M'ÇÂ7õ&q2x3Gçœ'-R—3*¬ºÄ5‹ÎXé7ÆÇşm~>!’}¢`Y¨MXGÜ¾;ÿìU¬#?7.ƒ=m> 4 à8¬hl°š’Æô²ú|¸²”y·ÀÊcƒmUb«´˜+ $±_N4{Zó„ƒ~şH«WAYU+â•u*¿É-¥B")‡.²[Î-ÂÍ˜6T #rw/'s†S;÷‰B×NıŸ×ëŞˆ?Kî›®nIQéÓb^fñÀ–/Cóx)Åİ „š5j‰AGRf2Z)Öå uBBPbŸz[
ş¶TÊO`oœè/ïÆº$Â˜Fãë°I’]O@û^ílÏÒ‘fNàJTBË•"ªÖğ…,EüGìüÌhª?z[cÍÉã×q¤Rõ¸,ÓSóO¬¼ùÆï+YÂ(«ÑJÉÄq‚1£üÚÄA¡MäxŠ;â0¼\ä
-mâ_7ë,~‹Ş“Ã¹Ê…ô>çé"A£<FH«D¸ï	/ƒ×®Ó¼Oˆ¸q
TƒûšZR7È9¿Š¼…ğ=Hj.ehm¢½Æ/˜×‹1‡*B\Ò`!I^yíR†]ş`†ÃQW¢•W{:<JÆQóàõtÏ—ó²sìr½²Ü3Ù5Ñ­ Èh?EşméÆdÚ–õvôÑuasLĞ>öÌ¦Ô«Ù.‰ğµ;1W¡©£é5Ìı—p¦~{A:.ãºñ˜@_]ttK@÷Éû³šÛËøÁ^r<?¿(à¬D4L¢*ºò™•ĞïüQÔøÿ½(8ë¾`N_>û½çô+”ÔŠğåi ırÙ*W²-//ÿPë$u#Ñ4N|8·ÑŸfæşĞD\ÖLí€ƒşQßÛ[Pàg+<²m»oØ x…´æĞtÓ9U:G¬º÷Ñ×ZÔ¨u§O÷ÀQHÛéWèÉ÷@rªõp8H¾ymWx<Ëšú7¯õã‚ïºØcÿf§ásx»ö ÿfJ•@u.‹åÜ•"¹°˜ì!šm[À l¤èˆ(qùæ@=6Á2véüuíVwh¯ÂòÙû'ä\ö‡êm°R>7F˜Š#'àã8HÿÅöoŸKÈH	°vQ3Ò™¸™ÕÖwœ‘ü:¯¸Ü‘[È/HòŸ¾§ÎY+ÜïjˆîÈf=x¼Rïğ
€&5”%Q« _ö¹t´!¥ñ9ğéÆ[³ßşW?†,¸¹nyûùÂô+â†?³ ¢¢½drs%ùEÿéİæ‚¶-¹›Ç¡õ£«gÓèOx$;É•át5Aa™ùÃŠQ€Ë%aÛ×!8ÿ&ÄvæŒrZĞeK³×íÉ ~8ÓÔÖ9¨DêN®z]WŒy&ö#“DÚ$³a(—xB„·!•Ìïë47Fï)ô¾#®rÛ*)›À¨ÎY­2oÒ' %ìH±=:?P»¶/Í’Ã_üb47ØîšÏLP‰_iohÛ0WD´]b&—­x†
+¥‡ng	Mø‹“«ÅP“¤lÎ…Ş2>İ·pc‰$SÖâJûß­ğ‚€%:“6Lp•Z¼épóbØäùUP~§yÂ$¨CHY
ü×ÊàEa¦²13EÒ«ÿB¬]˜aá¿h¦P<Ø„ò¤‹:°d{x˜Â!aù«^+J&àˆzxñØºÜVs¿Šéí:·+\m´ECÃ™ù¥ÎÅ<Õ—rê¼0-Šs©6vF‚?¼ªé®”Í ê#ç>\(„Ôcñ²¿R²û…k[j ¼\7€6u¢¸Ôõfpì|ßœ³Êõ¥³D\Á÷¤ƒ¾±· H¦ˆj#Qî:7˜×)£g÷Ùçû¿6¤ˆgB?Ã·1V@šöKW`	ĞïŠ
b"§­ÛlÏÆ2âü]ç:cş°¸ıóxïS~|7 4®n•K»KŒ”…m‡ÒQòæQhWú9äö¯RÜŒsÂ`Ã“›ö
Øàq³4^_‚›„¬™ƒÔšcÏÀY7Ù‡¨¶â­ws^LÀÜ+ö˜uê&HÎÍ`†”Âfd"vŠ‡ş=!?*Œ'PµÄ‡lrŒƒıÉFŒ7E	ÜsÖW9LhÓÅ¾’>¬ÀŸ¢0z:)q’‡ÂY²sŸléÈv-YağÁ¢sˆ¾ÀÄˆF4§@õ±ÉèõcŸËÛEb…½µĞ™`’ÂV›|0î,ÆØâEüæéµC‹™õQÅºÓ;¸¶³T¡˜4tá¹N\å¦T…\5¸ÛŸ·“7¿9Ïğ[äášÉ§¼²oÈÕPB¶çêK´®¢~I¬û2Ã2FÙy+ıBjîTö‚³Ö83r%xKÓq«¢$`måd»:¹nşE`²3­›±½©wİŞ)AªÍ_'óe&–8Ú¸ü’Ÿ•ÖâİP$|¶\Ö ‰¼š¥ãÂ†Ç1™…n›9HRöÈÆúE<wÿ`„fYÀm)We¶8Òà ‡!L‰äÃÈÂ­úİ ZtÄÕNÓ?•FXaÂdÌ(:wî…¬ô&ê‚îåWÁjGŸ¼¥nJé‚³’Iİrà]¬œøgup£ÇîÄ18ËÁO#k¼FÍfÍÈ>j÷x–pÆT°Åua I~y5{åÒ­Ù7¢®ááŸŒ/×sõy›Å]ïÎË³Ê‰Rğ1oƒ{85Ùë¢êÕ…M)U¼68IŠš¡×½Ú§ C¼k’­ÎˆOE¶@ÌÒG†­Ò"üİO¶Şø;Çİ	ÂÁßø•ïş>,:#¥;gÏÅ$O eÁá.|mÍğ› ·
ùŠa/Q5¶¬"Ç!F—Ò¤¼€)É¿E+0ómR(Š³…P¶”n¦šp	Ù©RCºYêEZÀ²5Wà·M€<ÁúÊEËv™ƒ9®N¨C-Šf^büHëLñKˆ9ıg²ã.Tx¤Œà2CZÀS‹Xu€Æn¶·>ôÈMÏæKy³IÛû%V%ÅÖ42¢w~:/	=iK‚éî”N®8x|sRLúË±ˆ|7Âv#út¼û¯€[5¡jå•÷sÖ;×JSè1+}'`¥îß.¤ÄÂ¢“XBn’ıàà.bÎÖï¹6'«v.°†–¿ àxd³$]Wr®÷Cz½J…OêüQç«y[OcOÜ¦2˜ôê³ød÷¼ÙŒ5§ØÔ¥ë–)@EtUy+}²†t­ÔĞËx}[/ï'GeáZƒ¬ÖÕßmŸ¥ÿ™?¥½~Ší,5>Ü6ò•S÷a¨#Jí›ÃõÀ5²É4VĞ×íRTa¥V¹lu á©rsY·®éu<ÜŠ€…çßèş“‘À¡ÙªØ5ÿØ$ÅÈücŞğÊ‘MÈ3,ƒİt§
¹krkÎ*õ?#gÁPÜ:5à‡)¯ÿ}~hé3¢7î)À£p¨ñfôC¨)—Ök#şı‡73½á©’p&íˆµ8W6Q‘Ïeœ=µ?PŠìTÿ6KSY¢ÍR±Ó´%ª~ôüŠ€‘ãÕq"{aj
G¬H@2Â#/Ô*ı7Ì‘û»2Ø\%ÿûİÁ6YŸûñ‘Öõ±x>Õãß
š5Ş*Çq_V³o¨'`²1Äwø[i“‰RQë¯0ª¯ÓI5ÁÎLh$´Î3–f˜ •mŸ
!" hÕƒn'ıº×¡B°ñ
 ~]HV‘B¤Ømö¿Ø‘ãÅù!t(Fo6hUâ­‚¾5„ŠègÖŒIe¸!Ò÷DÜlœıÏxèDéDÍRE!û¶=÷AÜ:™ãêó—ğø„ÌÛ@8ªÔKÈj¥±ú¤„Md#`´­itfé%j3?†$#ç¹ÕşBVtaYµÎj¹a‚øUH!¤,ĞOÀ+[®A·fà1n‹Œœ|š’Ü{ƒAú2¢pÉ|­†¼Ÿ»wtº°ª&høˆ@Œ-]ÌÛy¼¥¤âëhˆ¿imOæ°j®{¡h
oÀ¶|ğB¯s¼]ÛÉ¨\îC»tâÏY}e1ššäğöÿ€ªZíæn÷ûcsx¦tÊû+.İ4,Yß­â2HpáFÀ²¦RXä	3°ÔâÖ¸Ókjè²ñ½ÛİCXáß0¾‘ÙÔcdÉöcQƒØÓD¥„Bl~­€˜ª-jÆW+¼øğã™µğRE^qúbM›ÚnÅ÷AöÄ2Û¿^Z­!²vê˜²W8«évcJ~é—~³]Åé²wóÀ²H¡uU¢Ìª–“D¾'UäÜ¸£[¦ÍòIs›ŸNŸéÓ·†Cj…œ…¨¯º´f ~ß€fÎ}™îÂ~*‘äEJ>L‘‡¿YgF¡¯¾‚eç#6Çóñs[­v‡ŞÇ4ıPµÔİK
Ğû»çH—Ñ1“úøñèÑëê*Æú•SgT>¬Ä“(_³ÜCŒ¥)}TpŠ2Ïæ$“·6×QŸ±Väy¬äZ3“™à½w*ìÙìÿ!IÓl¼¿(ùW	/‘¸M¡g%íçnÔb sĞ;‘t…%[éc?y}@ByâMë~Œ¶Zİ$%¶üoTRg‘[g^ŞÖ¿l
á@Srj±ÅîSõã%ÕåÊŠÌİ.Ç
,WZQã{«¬yÅƒ§ÙiH D˜ ıİ‰pœ¼ô÷¿ˆ÷Y‹+©gÔ°0‘ ı‘¢«—¼)å¾“YÃüŸÙ<xXT1şĞ)ôylÙ6Š.^¦Õ¤ìƒ7¨S ÙR¸ò½1øj@7¥Å¬_Ù‘RœßÆ4£™òµ±'º?àk\˜9ÒDñß½ëãË‰™3OQc úqt¦½ÑiÕÿ˜¾¢ó¢pÖáˆKO¯·Èm²Ÿ-Ğô‰ßÔhç	P:=W›¤{ n‹Èûq.NP­Mb.Ï÷o/ÍKÙNX9J	Û¬;ë•àÓï‡Î0ñ(Ty­C<bVcÿÈ@ctñ¹ÍzÆÀ1'kÖ¡z—æõØ€SK$Õjm=–4KgçºJÌ-/;.$…w™š¿ÚËbîuvíç JTèøv›.d°Å‡F²uÄ—z”º‚L¥‡–-"TZâv:t´Ø’\¶^Â·Ûá­f’6nŒoªë6`2y¯€Ü¥™Ïo³¹ÑÈ…Ttxå&ş’Öl±{6>áó¡ Í›6€ìPüºóÌfô_/#²¨/À_úk8¥†©:è¬mf†Â«éÈJ²	ÉJİ—J ¤è€#öw_k­˜úkñ¸%0‰‘VŠÇ^qøØ¼uçNc øa’aÔ¨€B	¬İïºˆ<‰1`ìëg…ˆCã­¡’µ‚:ŒêàÖ’U”†
~Å(é>Ô8ÑÛ=”ÓïEà p®}–O|åöˆˆ˜Ák¥tD?rÉ\KPN.5ei½ÿÆü°ô	¸"*$«¼¸)	=%mQïè×Jy¶0‘`>8ÇÆÒ Ô¶×YgGqkIS”&²‰ÕÊİ…cå’Ñj
Í,ñmP‘2bHDKr²€9ãÆƒ	ÌioC–·8hæC¥véÃQœƒ)ClMñjşŠ|ÜôÿË|¶İõèÙ2ô	 ¬Ur5Ñíù9D™™µ:LKÈÓÁ‰:=h·r6é*«‚3OÁ÷Ñµ8<	²…zesíÙİ`˜T(f6£R0á˜ª‹R¥Ü¦È–Ãâ“p´…k#Mè‰³¥Ío~Ù•¨C“­jÈUdós]Ø¥ 'QˆJlÔ ]ıÃ^ßõØ©t~øñ…I‘fëçMê2ù×Ã`Ä²îE<‘–uŒUÄü¨k_«<HW1Pb^Äir+0x=¿Ğw>‘6‡ø®ç¨FéîÈ¿ıÇLÅSR›8kªídÅGA\¾Ü'› éò[@R¥m!}Ds÷Ë¤æ0¬£çâôI•±š3ò•õã
è¾Át
úş/ro?îÃ
¬q‘®zTÃÍ¯öZŠôåºÌT™}İ²Et0ŞtŸPâJ÷fL\[	¬©,îŠˆ•àOv‘]­5…6˜¤=ZÿÂ2;M;Í´+åÉe¥^N÷¬”Èôè-œ¹cr`ƒÂ“få:Hi;ßB|4õå(»Äı»ƒ{éO"uuƒ4$ç|˜­´B“wöİ3ÅÛn/w±dS,ÏÑ5Ë8ÏµÈÄ.+Öµ+ÊBÛ4´dt{ß,Ñ§İ­°óæãÖl|(]=6Şğf&Ò9R:Ù<¨­ 58}Ğ/òMëã¶Çùúh¤ÓæôS8w±g­ìjõ,ŸÄæß_77Éaÿé\ÛçSür»:uĞ%S'úQ„ÖŒºåØ=Æpú ±%Ê7ÔÙWyZ4»Pä3íì³‹Y p}ãæ4Ã¼/S
Ÿœ®R*êÚ¬AŠ÷#.•lëv,$\¦%n/\Åæ<a°³uëšµ“í¢7ŸûÜVá™CÈ\°æäÏÕ¤yJZï³9ü)9|åĞe¢v»Z]äQ»–ÇBQ‰4ƒ“W¡,6Bf®q.¿Iõt÷+
°V¶õ/‰÷Ewfv
ØÛ& sñë’Ñòú1İÑÀ:lÑÕ0öâ/]9Ÿ•z=§úòÎ!(^ÇiGe<@ âÔ¿¥÷šÃ52¦„/šB…Ñ¾OğI„o}™U/×õ”‹P®ëK·I/~,õ©¼ô¨'N"?e†İ·ZÌ"ÒõJB6ö5ŠLØ2ü¯ê”–RîÅù‹õuÚd¾ÏpB½ØÀ3ÊŞÍ£1mÆĞ™ò*ú?cç£FÂjàeé‹´æSf:÷Û5ÃÜ¤ZEÄ^ˆ¨A¹_ CwÆ—Îš›•wŸ.±$=~8Ğ~ù'W©¥¢ÁMÎd·t$¾=ÙÑ‚c‡-®“¯*´ß™jöÍ¤ÂA“ğÃJ²kÔ!<}tŒÊ?‚»'Ôâ™´¢c|‡¹-JºÂ©Õ¬­™jRöÕq‡<‰J‡K4gã®À5øg‹±zYïKó9Ú^òÅäiZ˜ÒàWè¬÷X†6ïW7--œîfs°®ê\ä_˜ÊÿI<òÅÛUé €Cuzf*+ğ†;$¹}G6 Â¾<Û¹7 LãóJüä ñ'”òä»Xf„µä)×7©H¹~®.7wZiäÓ¶¡îŠ+É&Â},—±íKÔ£SB•‰Y¥M#•Ò#­Ç«¯!ÎÂ—;‹ƒ3ÔÒ¦ªÌÚo$¾=Åú“Qºô"Û:ûcÃdÂLdc™Ïrv†wF D“ûÒ‡„GóW¥¢ÏKÛpÃÇ Â£ÑÿÂæ—]ÿş0síÇoRâ¯Cb‡şÕ•6ÍáèUÎÔâ×®2Y¨ƒçR[{X×C/„pNxúwõğÆ
éÿ4jJ^LUU I’Ñ·HäÿrĞk×Áà5ÈfıP”·g’(°Å®ac’X9Ê…µ‹œa ­à3Òû >:Ü¾¬P‡Ë&Ùfº£ç×xh£7ÓL.Ï&N7¡Éãqs'w½JÜÎï–eCË’c™gZ	RkÄ|k”FÏï?ƒ8Ø,í"bU'üÑK+E#ä1ÂÂï‡ëI×·8
¼MÏ`•˜#‚r@lÁH­f³Å¥]e˜~×ù“e€4qŞôĞ»Ú‚†dK+ì~ºW; S[n¸ò$ïpÁ…—ÃÆğáÈw8è‹ú­™8¶B4Î'`V¦EÇJ¢£J7løP1A ”X¿ãz@èyÃt‹ìØ£bíĞ€r^
¥zÒğ«ÊI‹[ºCÌ(¬#öåÖLnè(3ÿ#™•p¾œÒcÍí¥yw°`ø7p¢úw¤—LGûü	mÙD/®h`ÄZæšc¶x^€¿µ87êSÛ î £úbj±ÿãŞAKÉĞ3VR®½,wY¹×IQóîm¿ú3ïeÄ{]ĞÁPÖïâ“”.ÁjÄ›^ZŒ¼30b~†?¬¤m¢%­³;|Â‰ô,ƒ3ô5õS*ø–¶_¸b´7A4*}&b~dÖ8£ñ:µaïï‹)t|ÉjTÏQ$}ˆu´ı€¾tÙJÓåiƒ?m“€PÉ¦rœ­"Õ3”yVKp6ÚÜÚ°¤ã ZÁ}tOó7l¡p'Ùo£Ñ‘¼u¡-Nãiq¨W±šl6šşÙİ´dr2„+‡´NXs…’>¢z425é¾’ç}=X<U†6‚bÇÉWÇ¯®PÀ[u»©¡º‡cêC6Œ¶´3Œ?{)Vı±ÿ‹›÷ßZãem]ú	E_&ñnøl´.L¾‹ĞÛ^)ŠsÍqdÅé…KÊnLm[bABpS—Iü5*)¿1°ÌMğ¸ÿ8Å‰XYfe±Ò×¿ µ˜cK`@\™ücé‰Jxè+_`»Áoƒ-<m‘\­åí!"İ¼ºCoTÙ±¾˜•VºKç¶¼6ı"$;Ç<Ò|A£ær¤CJ_óEiÏ–MRa­"Ğxnd0İCğVAÏ1ZÛÊC @TA}võ}Ê|Âe ü{Â„$*—êW—4}¾±9ï¢¡%¼WÁ ¿m×’nş“¼­d áª¯‰~É
»˜}‹m¸|7İï18P¢:/Û´Í^Õç0qÀ(œoŞ‹Íòˆ2±ğĞ’_Å;]¤ĞĞÕfÏ5åj÷ğ3zCÎ¼ÚÀj¢ZŸÈ¯¤çS:Á­o!,ÊJÿ2|!‚ˆM¸à9Œ¹ğˆ9Èû²c¨éY¬á@Œè=‚0
‡·ÊfßÇãCë«QEÓÛ¢¼ùôıŒh‚N-]¨aö½5Ú,-iY""3Ÿ´‹â[’ÆÌRù;‘aŞ³ÃR¥¨”CßÄbPêU3«ïĞ»7†Cƒº`‹ĞóK„ {š]Ñ¶IiäW2ş^1	ÉrUfi5ıHšÃFÆ¼nŞQ ‡ı¥ùøL*[A+ßúH¾#É±ìïXî×è1aQj‚ìµÚÌö?Ë<ëîêšÀ1¨Y½¹»ú›]©|CHˆ×Í`È={®ˆ¾ijUïK,.Š±8@ÜàœPÕ…¶Œ~>pG=¼º~ÎL„¨ºe[×~%<1éí§µ”ÚÃÙ´Ù|”B
Vì0¡ßå•šÈE\Í•™O³ç›f<bí[YäiVy‡¾Â/Cü§åèQP!ô
ü¾A£¦«f'ï¾vÉÎ8…)`Å €¯>Q´éı?cGÄ´ºNõ×Íc—°jÿ‹í'niÍ­àpuQÅÃãj~¤ë¦äµrƒû_“¾OdMìDG†$ijÄ&Âù—Çæù½%yÔm5‡ÑÒïÈ}äÄ:É¡½fzt²MŒ:dx;í˜jÄáõÔiıïskµÖ÷2)Û¾Û{Ò–vF·›£h†MîÄR-¢YÄx«ÏÛ¿#ÙªÂFGû¦x»,£ÓµPS $×#’íä7ÊªÆÏí ~RRŠŞ¢€¦È%Lçş›ÏM#Q™PE@‘ŠcœF?İeWÂÖ
¦V}ÈNÍÉØNzHzªb²wî€€¦ÿK‚¨hQõc”ğVÆß$Ë+¼¾Áp7 ÿÊ;“ €/{A‰Âµ-{Y\9Èr?^„!¬E©º+#Ş~Ì5†ÿšS ~Í®¦=ÈRƒü¸MLBPL¯öí—Ñb(zŸ{óü@mòşÊĞ#¾à}À]Pµ äqè@o¥ÀÕ¡—üÏ~\—×R\knÓè"NQLÊ¶h6G˜8i¾0]ù^ùÜŒ.¨âÇè‹…Ğ¶ÕdTfÛõ“å iû6Fg´]¼‘§gqJ–ãõXÛ~ŒÍß/ŒË<Kº¾.P˜Mœše”`OkpØ(ÿÕ¶ø¨¼ÊC”Îù{¯yxV‰0Y¦]Sİc¦Õ m]#4a¶
²u‘ÈÖ2™–wH­aÚ›û“Uù¯-° ñíÁ,e¯‡4¦ˆåJ=¿*Q*†N*Qäé“$ hğ‹mo`ñ½°S3î·­­¶®(K)A_°büÚT'gO¡qxpİİ»#&?8lÒ»æÙWtTª=jm*’Ùì4Hò“J‚¬a]îp¤FO'P¤÷BïpéXÓV`}¯ú¡ßµXÏêøÉpk{ÛTê|Ü‹`bú¨r‚]~Ôí	nC£ãï,©'8z|=¹İµ›]£ŞÊªêºN]a„Î
ÍşIöÕSğ–ŞŒb°‰×Dÿ¬şÎu•7ü”CE_Ä‡„:£c7œaÙ…32Æh°jy·íîC•Ì§ü ÉRŠç%Ô=d—¦Eú©YÕ¹ı°H3d` kÀ0––‚¬Ô—ŒVY€†Åï!¸m8 ÈV¾kq™‚*¶‹ŞAŸæ0Ü„`8è®¢êCL×}Íå.Dss½¬L3ïEi¯Ù‡t	y1¡À&¶Ñn¸Ş›Ü5hĞaÍCèÅ {ëT‘m¶€oÁ' º«vÄM¨¾›sğßpv%É<ó0ÜÜ¦ı”x‰ÙíAê=-äü™È• ¢Ô_3ˆ”¾”_²•Ó94£§pºïŸøÜ™‚¼’d¢şv–­wİÓXÍ,Î®şPÎ¡5½ÉzÌSi|),åÉ|Îè÷•é…ï²)«ùêJtád[…;>Şoãx£kTFÏ?â º4L¿Ù~Àû8W:3a·K–:ù¥ÿa¶‹š÷Eˆ{ãW»Ö…qq,µ8‚ƒØÃY}G>00jÏ=³G¯™ªèoìz8ô}|ÉÅı£ö:ÃT¸‡+®48ÌA¿|y³YŸQKuº½Ö<
g¿¯İúôÆd¥Ä¢$Ä‡û„?UDèQze[ã ;l¹Z;^eØÄ`y	8Äë8ûh½½VåøuåVå²{÷g0;d‰MÔ´ø¢•’ ŸÔó‡â‰¢Òs\q=!86Ê¡rQÈúãE}îQˆµİ1ú`à€èí?.š
ùÂüİ?rğ”K­®*`¨hF;O‡SÙ•ºD,íêy…ğµ„y¶
sœåJúR’ñÒKĞn|5*/R·‡4‰«7tUÖC³ËwcP#á­(¾£+¶ ”v2FUÆ¶Ñºig=<‚ra}Î]8z´|Yë‘$­`80.<‘)ú°ó(‹Gr_½;W,¦\a~,ÆoÈ›…¸¬Êã>Ê‘ÆR¶ªŞ»W
ÈÂ¹Hbë I7ëK?>ÌhF™Ó†ÿ‹²¦—a®´Ç8¾)J°ÇfK‡¬ÖyÂ´¬8ÇI>ùôåÎ±­û9¸ğzÈ[Nh£æ#"}Í?ş¢#ÚöãİbK£¸ª“¶˜x33äT¼—µs¨ö3p lŠøî	?é±!6bÍÄm×]ãùz2Û/(ŒH:úq-B´±Ñ(	©‰Wûƒ¹n± ò(»Ö®ÓşH¬ÔcÏ6~|ıÙ…’’æ½V×ËÙçêzúìx³ºŠ¨)Oaû£ KÁÒcCßñHk×<¬!¦·€ÉÒ1×‹JìNsnŸL/k¤dË€N¼íÃÈ"K˜³{²“„ÍN3*}ñ+Ü ïªë>Ù’r}ä6Mxr;¿âLşt}ó]´n€lgóÖµ‘½ru‚–çäşŠ™—O[›˜½Çç´ĞIç™2*ôIE,!
¶[Íİ´å^İRbkw
ëtã-Œªy-ì‘I›/ƒıe!¦ ¬ëˆlFÌÓn ¾<èˆ¨½E¼x«¢Ì>_6?İI¹oeŒ„Ïh‡rú*EM‚/ßÖãø~ŞàNÙw²(c‘EüUÈ	?Ûó«¨#fÿˆß¨ØŠVŞk~2Î%J‰‚)xº-EÔF8"İµ&¦z^Ÿu—Ó#bc=ç·’L¨¾’Ùø&İA!ï¦Öû5ÔE’íH;µİHo—ÏB÷zP€:€BÉ’Ò]h¹òQ[Øæ·ÿ#=&ı^]Åƒ ¶r>Œøƒğ»n¾Z# Ú»±ßçÎPÔ©A¾{n¿ï=2”³ú_?4\âz€_“AØDhaŞJZ ‡¥W`HˆÉğAÕª	ÏJ:ØäVEŠùË áÅFˆÄˆ°“»ô H¹\€çæ ¡wŠ¿Ó qGÌßRuÀ.óT‹G{·*´é©üšÜ¿2Dwû¸&[0PË¨pa© sİ/‡¢*`LÔ*UJ³B°°ñ†X­i‰( YÏ¨4ÖRÕÜØäDF‘`%¶;Œkj´ßéG'€½„Iv¶šR›Á¾U£vÉnPı´2ÿJ¥"èÆªROä¬¥;ÊŸ$rÆì[ß‰¾*¶…fª¶átW€¥œ:ºYÃ‘
„©P%c'çSdYV±‡>V`W{Ùºûù\›Œü¨c5¸Ã½hPÆ>·j#'¨2üjÆ´j><ì,RùÃInÿ:euø/wâœTğFb¿Pâkå}*{m“\áXÑô>g¶ÌY-õÍÍúŒÄCÂrAsæ‰‘ú´æqf1EÜŞ
¨*:Ñ?y`E)‰ic’8²bK§õ“–Ÿ8ƒC Û™egvél°_‹5zåm4Lo¶½#;x¦nœt–œTRª­9â	'Ï;
ùlˆ$àë"çú‚ÔÚÿ• :5fD¯Ódƒf©¤hå9Xë³P©ú‡[]é)æ.Øêˆ9úÖ£³¸_±ü	Ø›'zêÆ¢gtÆv$XrÈaÏ œ>Ê—·dÇX%í‚ÓºåÅäa[’	²²¡ÛÜtòõL&‰`Ÿé"N)\®5«Äeæ…k9 ,İyŞÊˆ•âE¤x·İï‡n‰½…6ÜÉC®<¤ë	Ù±™YqTÈË=ûi°0S´:_˜xœ+ŞN Cw©¢šv´3ûòòÖXH‚q}ßŠ;—äå¥$7$%nÕ-	¥`¥_xA
1ğê©ÓÆLDòÄöö¯!—‹Aß~…(M„ñÏŠw=&ÊúJä¥+ÙYˆ-\îÅéÖ%uI,(Ó Ùêö9ğ {>AŞ>­¤TÒqÍo…„7cêøHAÇÅÅ‰z>$ H|ätî›³¾«VÀGã­êcÂG7‡ÃŸ½	 áMµBÍŠ¬3½+ÀĞöM/eõr®9EìŞÄ)–/å:Ü·qE²áÆ?vp·¥hM­M¥ç´¯µQaF=?´å(mc}-‹†8ÂWƒÄx0êÊ¡nÆ»l²W0ÿÕs‰,ò#•êœ)<ü1[º®j^‚‰äQáÃ‹óÁ!xÏUo¶	˜hlåeÊGúó#>²ï‘»å´`L?GØxœäŞ,hĞ¿éèÂœöÏnIŠ×< ÅYÖ~y­Êp7äQã« 'F! ]4«mXù’K#“Mg©7bü2EÖŞYºx¤J/JúNÏ\6
¢ˆCVƒ‘Îğ3P4İ‚µ"—×¯»=94‹›>ËÎ0Z11<ÊÏ3(Hñû$m‡-Ë 	Æ<$§Ç)’üØ½3s…ætĞ‰•İëöË±‰£NCÊ¥'‡ßE>6GÏÂşÙŸ™ŸiàÀµxljDÆåÜÙ}MV‘4KÛò“V"ÎÇñC–ˆ/DÑõ(æmA-øCÃ6ùOGÌMâLµv²n z®Œ?W5º4õY4‘ŞÓ;ÛcÚ®u”RU½Ä7q¨ğOjlAUN?**ïGŸoÊò™YÍ¸Q…Ü7)–Øg™‡	†Pg_1á8‰ÔøÀ_TÊÛ¯9£İÓ²İ£•h± G(UH‡n‹³-sac„º0mİÔ¯ùÄ¢boĞ/è£»æD¨òb‰lùjÛ3'9wíÅ
İÛNLvÛ¤P¼½<FÑÒ„îÙ@,Û||Ëdş„Ùd8Üì<ôÀˆÄbBTë¡Âl^¶ ü:Nõk…#&QdÑ±Û#y×&#'SÕş·ÖÈrÀ6YĞÙ>N'·©8EÊxZœF²ş§†!Úƒ/IJá\ˆYÛ‡s+\p”O=}“»Õ“ŒôxŠ„¶}w¦c1nFğ¹Vë ÈS^Ô
RçLo@¢¼u”„1ä=-x?uíV5šéM4w:ı[6D­ËÓM««=^sî'HMèëhb†şüntŞõ;Ï¥¶‚î÷«yMÎmAòVì€²t$æ ÓøEQK?,NG`C<Ôd{EiPÑÊ÷´o‚îø÷¯Î–l…óøv~éÛm@¡|˜ üWÕ>]ŠÉ¼‘o1__ò+‘ş­¦Š-a‡¶·SÛ)OE_Bl
ğ•Êj%:šÌzl‚¹NI5+qºtÉÚ   ^·‹;Ú@Ç ¢º€À…JáÁ±Ägû    YZ