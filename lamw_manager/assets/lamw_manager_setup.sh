#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3338669641"
MD5="922ee30c8ab63e7c1ab131dcb18c0697"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26012"
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
	echo Uncompressed size: 192 KB
	echo Compression: xz
	echo Date of packaging: Fri Dec 31 22:25:28 -03 2021
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
	echo OLDUSIZE=192
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
	MS_Printf "About to extract 192 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 192; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (192 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿe[] ¼}•À1Dd]‡Á›PætİDõ#ãìI‡(»ª×§|oZ³lémÿ&òÑ€¡å‰ 1LÀ*/Lö«éıòÜ,­(é¼ÍRCI¸àDµ¤2‰6	C¾@ö‚sxş±à„&•kÆ‡µ´İ­{É)È²Şw[ïĞå 
ëx™¢Y­š: jìo“ı>ÃO--şŠ>Ó²Ùãú5Š Øh!T^àÜhå„†R¾ô…ËÒù­û[ZéjûÛä³SŞƒˆ<Ó2¬¤–À1e#'Á%õVwçAÂ<CD“}	”oİÕõr:l
ş»ºdp­òãV^ÃçEi3%k°•o¨‘^ÕVõhÈ	~,|;NĞ«­Qb-çîVş¾o6…ZD·„…³Zb«¾‘O5Ó,¼8z’y¦—£P6¯Tİ&…&«Ë£PñháÖD’éñ‘EœÛ·ÍÄV]u& ª"ë–×
WõûlYú76œ‰cùƒˆ{0•qÕâr+~‘E%}ß¨ÃL!ôCy0í)T Û/‹ˆ^ü ¤<£'' ¾EÎCŒ€øÿ>„Ÿ3ÊóipÇà"hrxf·½ÄºSè¥¦³ÄétÆÌ|ÄØN]<_¦ ·ÁvÈ‰®¹X‘€‚R8gÏ¼ëåõ?‚X¤&ª,$[İõºÌbÎ®wµbMçXt0x$4b×wÚuXÚ~JUÌİšêJäHr4H	Í‚´±Ìœ‘DÓ±&•ü©(€Á."K¢Õ£;ÌÎÀöŸñ2ÉõÒÂğ<<Û¼òz6ê¬s:O¹ZüĞLí>®®S*ó‚šnZm®¶>®ä“;İ!h¢º|k{uÒ$¥×Qx7‘İÖİÎ/Zö^‹½låôı„Ãü³¨Î6›dİD­îS6}¾ÎÅ,+càâen	<ß!d°\Œ¡ÀæL/
£”¹ÄéCŒS÷±³]1f—…ÈØÆ(#¡ƒ—ºÊAå–üşöIø)'_Ù­ÃÇĞş?¦ËŠ…RÊ–"}aúh‰%¿¬Ê{ãÅ÷ca8—}æŠZ®ÛÎ-½ÎãÍG«Mï’»B®FÔ[^5ázÎo’Ä-röó×mŒğû>Id±ZÑÊ)eE‹[e˜ïº-E‹%ƒglûKõ­À‘;—ÁıØÚÅôt)+"71sáÇ -ù·9ˆ÷ÈuúÓ¼ğLbÓ>)3ß†šÊ××Ğr"Í:ç¨}9æõ@b“æ|oÛC§—ô1dÛºı&¥Ñ±ô¦ æuT?ú©K6üL¹¸#¬B%–ÂeŒ¶İ)Æàäï"&;FáC‰GG5ÊE`ğ
ÅÀÍ0£êgü½rÔg¿©ÒQ£oN+¾lk­|ïÖ­¼{ó›DñÚ_zê7²€êÒDÅ±ì/ïmêŠyMM%[@,™®-o0h'|â5h6§d´ËãuÕVVåÅÛ¾¹Rö©@ ºKëÇ®<¸aæ˜–®·jÚºšu=á½„›çF^ÙøT8	{é›çc„ÃÅì•;õÇ$eÁ~Ä—I™Ç‚(ˆ‘v‡Š«®ôÜRâ&š5k"³¸íNÛ-ü1Å[O v5Ù’2/XÜTCîsüpòÕl>Õ‹¼ãÊË›ˆ]¯Q®¨~KKÜ¿8äÁË¿ uèj6kÖ9í34Û{kø"SG4¨¸”pÖÊÓ?!•±'‰68D»¼”zÀ

[>ø[hqğX¢3b›–Sd¶è– )ä`‚=¢élkI¿…fÏ¨L`Û¸ğ|IèĞşBêŞÖeù‡è‡isÑz	•$ãóĞ
Õ«§zAî&1şíVÆÓØíÅ±­÷Ê;Jn—Ÿƒ¢îv£ûàP«]Â:˜:âÑ®¹ºø×©'í*¾å¾UşQÓ×fÙUYè¨©p·|D‰™Hµ»Ç|Ã^ƒãk¸¿^¢‡Z‚/l²i´RËÇĞ†îŒ%`¦2ZE«<ZU	ôÛ	ç¾:æO¿BIC9?Á«dŒd	Û OAÙ×Ëa»c÷ÇñiiBœànƒÎîò\sizœIzŸ]kÖĞcE«ÕĞvÁg pâéò¿šP'’ê¡øÙNBù‘Àë*í¯ZŒhm@‘b(©C'^âûÎ+.ŞÒU×«cW®òåÌ)c&ˆå½*	`lØHZâƒşiòGNqZ1©dûCşŸ’„èZc†Ù/yA’­X¶Ğ¾1:éq ‘Œ(Nœ‹ fÄh ÛÒg‘Šÿ×Àxjş~¡“W'nye7[æ-+Oe_æ‘CXBi8	>ú^Bu%P$K»€ÎİFñnr	-Ò Áw',ù›Ä®ët5-î¿m˜‡qLö÷Íõğ1+ìiÕğøÛdqàóñAÈ‰À™tHıùÀa$?¯€÷`’©°´Î'õ¶p²aŠy1ÌV«´Î½’b.5º3MæŒpÑt9ãC€F®À•Í3Àşp«¼*àXY‘„1iqabá]ÄîàìÚÁ¥µ.YZy Šª–“ÀTH}p‘ÖÚã[÷J&G „5ğ!èM'QPp¨¼^pÒAà;ËNò	±°¯,4å}¢Óù’h:Ú„Ò¸¿ëÔ"]“çqÅ†¥õwGÁå>ÒÅ‹«%§ú6oòÎíßt_€8?DÖÇÈê—¬4ÜÊ¬TĞZQÊ‘Hˆ&è‰Û­ÜHx¤[tå=´ª2^ç–_k ©ŒSz-Ä™YÈC¨³[~ÓÔUÃíC´õí3—Ö«ñëÎLşŠûù¯uò]Ş/Š-˜_
ÉhäùQ#ŞY´ñˆ÷QXô	‡ÍeWÛãh=Æçôşü3¥^Œ.tıhuğö@¨¨,÷p»\d¢dÛ"àìJcêÎNR¥
]™ÆïÅr)&òÄ! Ì0a_åñ8ûÛ}*äùå$cÇ9Â>Ûã^>Å0„şrµ3¼ÅÇÈLú!²N4@`µ­¡ì^X0vĞ7
³W×ÌÖ»ğ¾»…®Ğt·å,…–Å‹6ş…Wßyš„"¤CÔXaæ|w÷§
GæytóTLƒ2t·¹×KC£³eZd¸G´˜pô£Poh†ğÓù½øş‹‡†EÛğö¼mò¯µŸ(7#ñ°5T]†iŠ0´l$¼|0àá1ãÂFOª•§¤­x·zU(¨y1ÉÇ3ËiÁı”¼1Êª!GÀûêE‘	ú¹0ø$]I_Úç°åÔûù*±5£QÊº©Öã‘å?™÷ğím³Úf
Æúå÷×jNxÌJ	 à>Û/\—‚ÛXµ·æÙà¿•:
$¾·ÕJŠ¶…·"
™gQˆkôşÊÏêº7Æ1ò5ïÑ­­ëî¬@ôbÿ\Gª´¦Vmz˜‚^¿íw‚bL¶–ó(ë¹âŸİäíŠŸÿ¢~Szùšº("à,m&ÍÍ%–j™I±Á ã¥6¥+ÄvÜmğ`]R6ğä²ØùSBJMj–Ù)ÇÚÓ:\@19Ça4éjT<Øû¿áË1ŞG4ÑÃ<üC6ÆqdI‰P6®Ú™bÍ!¹ÓÅça¹®Ú=ƒ”_m3ÎqÎéùdP©ÿ¾I¿\Ÿt‚¡5üd…İQ–SXÂáÛs¿#”êè•æ‘£û{sû‚ÙJ#úÆÖQ™·®wD£HèkÜkG‡”? 
ÅqYæxœ“¥G×Kº°õUqŒ·Á€ĞÕ”=©Q>ıLÃgŞ§˜ôÄ‰•bŠŠc¶R/pútü‰›w·×eSJKÆ·€ˆ9úõ¢Ş hÕÂ]õ,[Y22Œ%˜ S´#“Áº¦,ç¬È: «É‡Œ'ØÂP$5»£î¤1 ø¨ºá‹'¹—]¼r†{pâ%l7v<ƒ";oÏ*üÙdñÒ—İ²µLAİ‘+Åaô3±¥‘.¾«á€r-ğ#q]°ÒÈoç±on%ìçÔÃù›¸4‚Èy"û«¢¤@S*—‰¨çÑ'I<fÏìÔ.HÈ2~?ßôêú’™İFhÆŸM:…Ì 5YÆGŞ~ûD%UaÕ^ã¼èµ AÜt<|¯zjÆ(˜ûç®¿BißÕ°*$¶Ûº&äßG¡Æ°y˜Æ\á¨8z.†CSÈ8KU1t”xï\Š#ÛAÀ Eÿí¯×É·u¼|ŠRò5Ö’,ıE´;)ïjôh-ÇÏ†@
çÌWVÄ¨ğ‘›÷_>”³œ§bê<¥«Ç"ç†R|O–€%5şğ2UB«JiO}}Ä«K.öF©¿­m·ÅÇXML„šy<Hüj\o`]ºbMÅ`À0[!Õ	¥¥nà®'·h£€'ùF÷%Ú©Ñ÷ÇhqiöcsÊÍáàNqâ>v^¹´i‘=ĞqUš¤+ÍáW#Å3Ã±/g°¨«²ô6«ÏZBƒŒCšATjfğ¨'ŞLz¾H¯™‰åŸĞöeÇ¾sª¶ÌòW*0aÄê‚i¡¼æç|ïTE/“~W , >ü(¸."ƒ	ÑÔ¾ô'Bï:7Ç—µÈ…Êt€DdÚŠÆ)…W¯Ìğñf&ÍƒvUĞ%Æ½Pïœ™CÖÍõe‹ójs”áx‘¤¦r$jò‰U¯¢ÇãDô½œôü~U32g}66‚zOÉùl‘‚Î‰9|–E›a	 †ïÇÈ¤¨Xm9Ó<“Æ_ÎCbW·~È~âLş
3xÆ%#¿´°˜¯`*EÌ«šºWˆ_26¸**ÃJ¿>—*»Cã~È¹Ô¢\
â}…gÛhvuÒ.LX@î³­T±4ŒFå…ó]2¾Dª!ŒÃè5#æ¸ 8Å!<ëQ(BÈáö$C§6Œöş “Aóí”¤ı-¼\ëÌ\±s@ŞÊ…cö9Æø‘£çŞù½`WÑ˜N7‘Íiq>Ê)—€v(1Á•½iÀ–ïjbV'He·ğ¢T°‚¦IÄSŞİã?tèè# ı“ß íĞ uøˆf6¸ƒi}1ÇÊĞŠ]ºşF¬öÇ!f_RÛç8‰¾ŸÔ}Š©W÷ù.8’o42c ?¨_¼²T§*Ü³jG¦î•ñÈ+Ñ¤Ë‹Õn¬³:ny¹‹´b@Ö#ßDÚÇ{`-W3½îøõ†Ø<Cüªé¸YdƒóHß(õ•0Ù\ºkg)§›×¦‹–*-„:<û@,àz‘‘yñÁh“Ä„r=á´]K«ŠŞ óï·Îv™RÌ§İÌ—[èWôL^§!!
ıä·º2#Wf§ïÕëMp½¡* „Š]sôÀTJeÙR8Û>qÎÃjËskúº ,®ÛÒê"°[üúê:!û©JEi{êôı‰à„Ùn‡iÇsñuyÉ‚}ãâÜ.·R;o*?-†ŠÊ¯KÁ'1É‰B«âj-f¹¸xDØÀã¹Eö€ãÏuàıÇR?X¤dùø¾ºM°µÿM	éÀæê± `Y=—ÿ–1ïI¯'}Œ>ŠÆ¥÷´Cf%_†OÓ‚PGÓñ3+ÌrÌ)İ«Õ¿
X:p1J	­ãë#Ğ„ó/h  ÃÎ(ë»,‡ ¼5îb—0^8½³…q«÷„íüïŒû:Ø%•ğYäp§A¸8/lÏé &úwZ‡ø4¸Wı8Eª6‘@Å]$[ôë¬3Q[y5ó¼m&íçr¦Tc¶Â§Üoø&ñm‡Óib¾¼§Ô•ñgun¢mï¶ŠU©,)bvÛgW}æ…ïƒ»nî9¿›·”O¦;ämºÊ–œä5úLÙ¯İÃRBõf®AÌßœïtü<ÍñMPÎî#§¥ò¡ììKK
ğ‹|Jßv®á#:\ĞÀ	FãŒ²d¯½î%%f«ÃFÒ>eÆ£¬ìºRüˆyU9y;6<'Wš·Ku9Ú`ä$¾ŠNóÜ®@Ì!%°~Î·ÊCz¯=¿†ÅUMen¬ˆ§ùR×7Eäê<‡Ì°ÇÈ¤rXÜZòt—‚ÆFoÉñ–ŸÖNL9k?A3xá¹P¹(
¼Ï:l*î=ØÛ«ôÔ<Ï%KoóŠB>+ÿöÂI¤×Sú~Œ’™ø±µ=xƒÊ¨˜HO´VqĞ•Ã½¬ç¼N ş‡—ø_lò“RhmÉhŸSÑÔ"1'šÖ¯˜Å#1ï)úÏK2ë±‰ôëV>ƒt¬Â%ÃË•İk+È¶ƒ£qUÛªVòE©Í³‹LŸŒàÏ»,BşÊÿÚ©’ïš°kkÒd`ŠfÙb¡Œàw8NÎAnm["]A=N€‰œd·Oj"ë
¦Òİ\0E§•Íj_¢¿†$B¨»9ë(ïJ¶jó{Û¹FcØ²¡Æ–ë?MT#f`/Ş)Š"æíµzZkß­I©@[µ^îF§1=„Ğá½zbúŸMrM'²Yì”¢lÉP¢Áíõh´l~~/ª”Ø:Q€<Ì(ôZäÓ½ç0^üÿkqq$„qÜß˜Ó™e\ê²¤_Æİ×m§vt=ÿd7İíMÅCí÷^.È)Œ-tu0P\´ï**a5¸R‘¡göª!¡ıı4ì8ZĞGş· ‘|w¼IìÃ±Ö7ã['ß o©wIÛµ>ekw< ÷%ÅiˆåVÒc,øí^¨Œ[<U‘*‹õe;×JS–"L€q çmu']ÿ(ßcıæ•lz©¦÷¹óGÊe½>Âlê0ë‹ÿdj¦iÒ-%èÜ}ªuQ÷–GÌo6’9†÷›øKïuÔM’Fú==ÛËÇîÀÉÆÃàröÏ
õ¤@ÊâeˆºŒ/úo]-äø.Á#ü¨–gR@g‡:k6¹^*Ÿº%©x>‰y}@÷V…Û¯Iq³2rı›hƒÑØŞšÍ$ì’E³˜ã~ÀÚMŒX7%VÛEuõB#¨8N*³2ºù¸Aü¥kÊÄlÜ±®8•Òÿ²Ìâµ³†JA-ˆÉ¨¤Ôcˆ"töNßWg³:+sYY¦Ä¯zR¯Øê6 $dFŒ¶ìzw3BÉÊ_aa~õW˜ B•ÈÂBY‡mˆ:5T¶-Á*¼¹Ñ["°¶ªˆ#æ¸¤İvİ#Z…ÏÅBtdıäÀl8•2sA¹üïÚXXÏŒ€—ı*Œ.•«uùë*ë('TŒĞ•x>“Ú^h/!±ÙHI1kŒsgæz•æâ¦H¦°	·?†!‚?²4´´30›O:Yä|oÀâFõ~ö¢b¼{Æ=w[y˜WPúö_ï»g=•|Ï9HèHùwığ¦î3›‚']Ü#ºæ·H²™€Â‰–sİuCÇs2eLÑ)_Cç¥EÿIÃ”ŒÔTÿ~}h“!ï;ÇhM/¨À³İ}¶—çîùî1÷®ñs‘ÊN½/i•_=f@&&˜uöôĞËÏ‰,èøú.£€%¡JÍJH±°«E1%‘#öŒ™<ÏñzìlCÎ3Áü¸O½}3XŞvË¯dƒm6ø<Ğ•±¢EÕáYìJßdA^Ç«È`°kwïNÉğmØ<÷ò&—Ühú-sÌ…ÍeŠóÉ"/ççfD¨‹¢şiÜ%",6NqE@$3ÉoÃÓ-;ãKGéÀ“»ÑÕ(ñ9¡Ds²ë¡M“†<sìH¤@T¹Ğ<àŒèæwËñı;†Ëğ¦êñúÅààQ@€©ï«ëé%H«o?ì"fûÀ…tÆ'”C3h$	˜€m*7(Êu·f t¤K9Ÿ^;Ÿü¸Mq±wÑÑ´ÌKç:êúCŒ\‡+º¤R-ËŠ’ Ü™tª?GCßA;Òø	úkİàD'i€d	³Ç)¤4Rv*ÆXßÂ)ëŠ)E—Œ½#ä¨®tĞ&¿ÕáeF‹¸%ø»j3„¼˜=Ä­¢Óÿƒ Íÿ âEbƒ£DD€s*ıKâ)¯¸¯g¦jÔèªùšÚk„wáÓ*ÿ–ZMÁ‹2Ê€û!éÈ©Ÿ·­Ÿè@¾ËÕi@A)ö®Û¤ßù3RĞeLİ¹í~‘şş¡Áù·kb®ÒÑMê8&‚ôE c²)ç‚>\üøKiÈñc¸ÕÇKçF0:Ïr?êïQ«ÙD†]Ÿ"¹}cĞïøŸLxsq®¼ToXCNæmÜ wd#úYôèœš)T8çÕ²ÏD¼ùY[º‰:.µsÖÑ½ôc®(b½•öãb–÷¼lñhÚUÜôÙµÀ,¹l¿ß¿ÈªQ|8Êåş#¹¢Bhô|áá‚š³Ä=÷lßÜ:®‘U˜×¼„	pÓÿğ–E4a– Ii<¥¹HÔtÆ;~~@'8dæ;7şT?„x6¦4ŠL£µ2Q
®ô‡İñ»º¼5óœ9ê‘äguH¿b8Ø{é.Ïîòè-€ˆÛXÀ¼”ñ…å);%÷k»‘$¨:…e–÷æ"õ´ÿpz$U#¸Á‹í¢=kV#”Ñt¶™ÅtäµíD{ÔŸ®š -TZ;—DÕ\¬}¦j_;ßÍÌ×òÉ&yn.ö6;Ãşg•ŞªºàzJ	±ÇÔÎ3 ›å×;É[Zº'¥Æoƒ‚ÚŞÌËQ~ƒ‘.¿hèüø$¿#sĞmYQÍA­°¡ŒxQÙ(fFMo¥G‘²)4)–\QÔ ÛÊÍûúàÏ®¶mUK:¤CHLXõ3ª;_I:4arRÂŒ”sÊ©|oo50|÷Gå©=Âå¥İıŠ>ÿÑ¤yÿPm)Ã"Íàı÷†Â7Äu¥-€ÄÚ&LòpQßO¶úwËO®;TŠß¹\ã…l†-©êµa2ôuäÑí]ªYGÅ|1¨Ÿf½5Eù<T¨®ª˜L ÃpUÎ)ÑêÉ¿ Õc9>ËgO°ú­H#E6™¼ç=]—lıï~\'ç·“&ÅY×ıº²„èÉå[8ìIŸHk,N &'¯‘Ù…%èÓ2yp(”tô¡^‡U¨iı1uäc¢İó:Ìø5¸¼»€âˆ,EÛü¥üã¿‘3¶p€_[ĞrÈ()×öJD±p'AX&0è¥y•]u‡aG[î”`]2x•P…ş›ÌqÅ/Ï ?®<á'ñ%1ÊRó\°n¹Ô´8ûõ€Îr/ $Ã]ù|5êgË®ÿ¹]‡„ï%Ìàéh`Oc1(\ÀcÒn^O!z²|<Q D’Ï£ˆ‘ğbmf{"V‚±Ã³„ ÿ,~BÈ¬"²Ñ8¹¶:ª9mQâ|ôX–Æ"¦Ú›—m ‘yé*¬1f†M]Õz•l˜Üa—åİì÷Ñ¦¡+DA’&RÅgÈı³Á£©ã]“/ØÉs•7j›FÃ¬±:şşÔÜ‰…éh r2’[-œ	œ›çN64~Óz)ø£xå‰ctHÏÿÌÍÓ¤A§h·çrNL‡Ç^o3ØHäğ\Šoö¢€\×o–7V`œs‘ÁÔ÷óU•y14‹‰à—·|ÏBcM‡ HEÆ¶<§HÒ3çUíÂ¯ÈÖt?KT"KÍçfúJïÍä•¿²hú¨iœ7nŠŒ›mAÿŠ¥éG½n—ÊfÉ»¾lË6Ø¾¸ÀÈìYcß„bÿL¡ä;Ù"W‘[e1:ï#wqódßÂqÃÌó†³r¥nôÏG¦ÎûZ·ÄÍkSåÓ6í”2’µø²™G¶ZÍkªî§™Œ„ÄuVÜƒn@U2	R Û¾¾I]4O¤L„Ùşş'_•×‰v=€OéÏ4í.n±«‹tïÅ{|f3t+…à±Uaš‰ıUÉ>­29w[~¼8£ì_Mı¢Ñ‘l%c¢†aVy0I«ÄLL¬³˜¾åÛ$LØÎ…v-g(ñRÄlÏÂAuÊş°ù*Ë€¿œ'çÄÔÍØ¤4QsÇYÁ³ÏTlØLJºñŒ½‰V®OX÷1VÖŠ±Šœäˆxe×6¹fı£ÜwT¿àì=qŸ^•v]ñ´™†dÒgùi9Ósvz»	²à—£\ŒoŸû]3ú!Ç|ùBàLy~jÍ4¢B÷ûÛŸ×½ŞŠşbEÑùĞ||…éò_ã>]gœïë¦ò|Ep4Pa\EŒo›o¥$71o¶#f)ØŸşú³»÷æEŒmˆÜ½gVpĞÃø‘¹aÅ©6ér3 Áw`0äækeÎü›PY_N—Ïbb–£EiI¿øu6 ş£\"‡!A’´áßšõş³gqMt~‚„ ØY÷¸Y—Œ÷eÔ #/¼ñ£:ÖñCßµ÷Q–Ò{^ÏÁ_„54^ŠÆÇ'È*´‹`}PäÄ)?hlç.7[¼ÕœTJ}cÃ=ìHQÁ8^¹»GÑdôõİUÃ$–]Yùâ„5$¾–Ô¾8î!ïZÔÿXÆĞÈoy~æG0ú¨4Ü©Ñr–0<¡»ÅaY.G;(à‚åâC$³*=ÑHOö3b	ğ‹Ï[®¥½'jL"ş%Ä…‰(ˆIL«!ÂkıUet¢áùş¤W× ^yõ S÷™+WÈ2§BN±©ÅºÎ‡—òSç«Ü;³Ÿl[ÇíjfĞÙÌ2d1Ê+ÍıŒ§=è¡ÖÏ#cië%Ö,·½É!Vu°–±×Š¸¸¬ˆ×ıZ€Ç>ù«¨»äE!*“ığìş&õlÄ1!Šû1|Êe‰‡Î!Në‰ô½ı‘„Ÿ”+˜ŒmótÃî‹½M}ê;ƒ'½Äk¡a«m.M¯oƒâ|ªó½G1Ÿ3ÙÑWx9T"Ÿ(’¯â‚$pXürRfD[s€£ü‹ÔóR<S5•]}Bæ ×Ê{| eÎE]®ÖíTj	ù–…;ú³ã–;«¥ÅJš“ğ²öó"¡”kÖI€ÕÚ6ÉJ£Àä÷P=:T_H£\—)KêÜ m@Š,oà³E€Å0rôÅœD–’ã<
ßÄAL›Cmñœ«[—VìøŠ±bÔæ†ÔI”jŒïãÇÁ²ö&ß¢K
k/1±y…ºdsÍÌtf`joy±9QëçÒ&–æ]u+üpiQs@(F7j,d† Ïq‰œD¨CxÔ“‘i7x[Dá5ãDÂ×s<±Ønß¶šêÇnI‡Ğ½\^›~Ô"8’Áş!†ó>ï|ó†[Ó†ûÜĞ‰Y…Ü.!€j‰ÆwáÌ=Œˆ2LUör¨„)™v6‡ZS²óÕBµ]Ew ÿ=+ŸïÇ™dÁù²O œPb…ÍÊzApKà=Ïx?ÒçãîSN'†Ü™Åd^+nş8¹+§—=Ï>£$;Ù¡¦8Š’Fg
øPTÿ•$ mæ">™ÛG°ÉIè3ıjú >K°uˆ‹Êx9|ŠXÔf.«Thâ¾-øş<²J&\z_ÿ¹¸‡6Éİ–°ôó
™1•Ÿ¬eNáş‹ÖP6ØÃ"ÙÊ4KŒÍÓÅj:¤ÿÀ!uéåÆQŸYµ4SÚ&q’és)>Ó«i²³À—÷m±ŠlN2oÒ<ë!Î–ØªQ
ãFß›¡¿snŠ˜±b!Ş#Ööœw³g†+_P™IVºCÓÕs¥3ùq7Ê&Äß¤Yz\Di„"{ê¡FE7¸yß<Š[~öo™qË¤‚‹E9áê´­ÿ~³YWì´ıt b;Ç8Š'Ús?\9:«fTƒÀj—¼ğñÃsoü{X3.LşÆº2å–¬¦zˆØ—¹ŞÚC	µ‡®Šæÿ÷™g@	`ıjOL×ƒ§ 7‡ÅĞM´ìş”ÕšXñj%ËPQ:¾n’üÔcrá/Œàì‘7©Ğ¿UğQ”/ìU”•¡„D²Õ'$&Ñ…1ÉbVŞqò&m¢‹ï!ºd¿?9aF5#üÁÚœû«dTR:ŠQÄ¯Ğbı]áBíD I/•üy½À–ØA¸I$Z³	JÅ±Û†aäé=1E*{0B°Á‚IŠ¡ßsí¹ã°f³h’GªşŒ‰â½¸Œˆ¡–ÕâU¥ÏJÍ‰’”«şBÃ\%³”z[m|q‡º³ g…nS÷.,(éÍåû1è`AÒQñÎcMCX:ˆ1Ïá—^Ec“G¹#Se¡v…‰¨¬—|Î#-eÿ¦¹\I9M¸Gú~æ½¼á—“\Ùšİ©ÒH–vcê(„5ÊBiñ¥‚{PVÑmt™Z’ÔWÑ?/ª‡£ˆ¸vÏÇç£#­FHÓÌ¯IÎªÛÆlŒ¿0ÄÉ#ÛëÊN2ªaKãggòñéËTc{-Ô\ª»;•‹³¨è1JÑYÍNJÓZœkë
Ni®SªÂCnå|9Oä¹îÂ{éÜÎ÷Y•È!,¸ˆêÕİ|S]Xù-ø<Ö¼'ËGs%øpk4õÿo£ãNÿç¤Xe[?”K×ªä(âÂ"[ë²É $ñô&	&tôZîÂ¼ˆ¨!b‹MèÅ-Z÷'F^öiî[U îû­ÈH^›­Ax„ÊŞj›Tæ"Qß·’£DşĞ1Ún[â§o˜ÿƒñÚ|´ö² »„¼ÀaJàŒÌHú¼œ^Nš_ÿsüÂb< =LÙê5[-‰”æòŠÀ÷ŠÍfíÀ«MB ¨z—±÷Î…ì;:"sÕëzÂI*ëÂ2€'áÏ—Ù~ï	YÌ‚¦âÑ%<Eîf@Ü[©š—òö7sT™ÒøUa6Ìêr@â¶©F&gÛE›â6ü2İô‡ØÉ`´Å3¤’}”;ë+Câ9úËŞ|¼¡®{Oª<Îáb#Qô¦ÛP€~§x›-½:ÁsA ¢„ö$òJK%éL9~DpUÑ23Ë	
ôÑÈªû¾‹òY;ø6¨ı¡ôÿà Ø¼Ò$èäÄ7âÆ§Ï±É…¸Ş¤¡jQ©ÚRïUM®ír¬jG¡ú¼TOT›_+w¡y£b`Œç˜ÛÏ6:w°C£NÀ	îsö¢†D$?N^w}‡1Àm/ø¢ø0 ç!¨áòuåïFé.~ ’Í¸³\Ó“Y²F¸v‚E:Í3CöÍ¶ş 7Š{Sh€†Ü ~Ó¬~Å|“ÎHÉó¯°QXKUÿ.€s#…6Ù‘fi?™9ô:!Õn‚©UíŠ‘­.ŒGˆ[o]·Â» l¼ÿ!
]ÒïAÖ°rúÆT>*½¾§…W…3N08™Ü)Ê¶†ìğ©Šì?²`ÿsKbf[#‘-!^ìú›Æ	õÁ:;ÇğƒH€ÔgYm9Ëì“&8ås²&O#³U"¼–˜•9¬¢ñ%²ÒXò<ï†/
TŞäï&¬Ÿaìş³?­äÉ'C™°.9÷¶HYï¨–1©"ğk5¯ù,š.üŞòv).iÊ—[ÍéCÌ¨“Z¥_\^0™Z"®Pô€ùÛP»K§Ä"ìtVßÆÛ0fQ_y„V±v
Òç	˜YlÑ$İJ¤E·ÃCŞE¶†îvµd1s•µ}—z¿5¹nÛ@+Fƒ¬S\’XT&Ãí•y›f`|hs“jÜú~2µù£óŒæYï_‚
íª°÷ÒKU
f^ÒäŞf¶‹ŠÛ· 1uEğŠÍÌı)èŸšM!%ßààeÍ€%Te‚Ù?P´U‰{¸,“œÆÉøCŸqUÉÈ¯º¸>aŸ€Äğ!UL{T‰r‚®l¡5÷ó§²ºµx¿YH2D±Dí=¯›#^ øAmƒ
lÛì.!ù\üP’JE;Ub/‡–áÅ#Ä°ú]<†k6â/APî ¯Zm+®pkŸÈ¢BZ]Sbã”N´«tC
Úß‹;”A·¨Ñ ’ñÙÂ¹ä$;qRFPè=¨Ò?³Vğ›¹€jrIø²ğ‰Û•.BÏ<5oî·£0ßK¶¯`Àf»ö}®R§{gYİ¹€G–pL½2€†·d¾	%‘âløšÈ% ‘ZØ©5)Â§‚pykév}Q3 C–NğzR›Mmî© #sQ\o®¥5=â%,
—õ˜Ø½Ğ?e¡Æ†È:$PbAfı||;ó”òy‹¿ÅÉùû³$;.ªE×äjc€ûÏaA†»È!xÖ©t¨4c<]' ş0é£îièĞı]}İD‚à^´¬Gd%|fNux1•Šô	ˆ3Û«eõU\™+qY]1&ø	QÌ­ç5àÊQ¬E!½n˜FÆ¨ôdXW|g˜«ğ³Ù»œŠeB¦P¾êàDkì%(GÎ¿±EKÃ(Ï²=½B¶:³Í-zl0‹¯jÇ<Š€çƒøtB¸
 ¬š:eœÚÃ#¿Cêö4VgíÓÚïY°»Mà¬ğ"ã¯ÿ¥7¬ík®;Ï¾äù8İK/¦·D£zã ƒá~P¢Ä/KWk&–Ø@¢ÀœTÅÒØ½µim¼üb…á6ät¤oğ“'c©¦*„7¦•I7ô‡´dA  K'Hò
ïÅu¨+é±Q( Î\9Ô@¦_!å8;¶XédÆ%H÷¸×PI°ßìÚ†_T}®¿İİ“öÿRÛ~—ì}ÏÆÓ)*M“†ÎHáï#ç5J¼qèài1	ã„;„mŒlâºs»ÀG:™à_a¸U9Ñ0¸çÂ9§hsî7Ş‹Úª>§…£“Iu?âë)¤ |²†^¡Sõï|J*ÒÑİİÈ™¶mÒÌQ]å5w$«ı«íÌRN7Ehsè$g-É(3É!jÃÍÕ*Aˆ•By”àÓPÔÑ‹™–Â†­qg‘NÄ|a2Ê€V3^¹!¤¹<Z§£]¼ì{–iÅ’©!ŠPìÖ›*¼ù¬D_+W`[ ‡ä&"e²?Ô;÷HÇ «ĞiÄ§µ½éÒÿ?us}€Ù‡5KŒîQ<Na¤}åÓo‰™Na5àgê÷å×#€Œæy†ôù¸¢ŒQì—a½¬¤«cº8çÀ¨/Åäây¤YœsÁ*ğw­}ç°‰Lo>´7<äˆÜÅÔ{Yß ıO=¦ù1œ€Ü6±}Í {\y™=oŒ¾v÷¡îØxôtúŞå¸IX¥Ë8I>ÚÇùÜz¿ÏRÍ¼€^¯šçxgÙršyò7…z|æ›üÚ\Q2*ñ	î<à×µë¾b6ÇB¤šúå†åìË‘²ªÜÊİ §áİn!~.E„üpædÈ:á>?s8üz¨lŸœ]J¡J!9«™Ş%BÓËæŠ†ÔÅ.QªÄTFw8YPæ(®	áÇ7ón:•2™vİ	¡íQ©·Ó³×¦Ùn´¤×íªçüsD¡”é—Àmˆ‘A8oê¥„~Ãue›$+t–=ûøP†}J"°ïÀ$ßÖWF‚ÃXüV·vÀ`Ñz%n½ûâ2'z}œ<f¶â4îy‡$ıçµ
ïî_¿íf^)Úòkı¥SŞ“3¼t–@—œÈ„Ù½iÄtU7Tà%ˆhıGı‹2-cq‡p§$—=:m'a0]Inüüsnôı#jÑ=‘¯˜øÈş^†Õ¨¿~Š!]Tùí=ìº™ÚYáÇ W0èáb6›¾
Eë-ysr*çË%»Ûœ72]äo„Xwfñn5…øB$¹e\N-ZÈãBñÎµ'ƒ§4ÒÆZ\sØ¾’9;ÔvÀ	¸q¿KÖYb¡…¾P‹äô´€à Ku'á]Auß¶Ì˜«)ùZæó¼ğ(…üÒEc›á)Ì–Ø°c|R.R«ÿ• àU9ıÏQGpbzr¼œJyô.à©%ukÀ &I¨‡°¹af®°§[H¢º’–.W¹hwõ œ§İyË'I+'$9¥!Ã½–lf|Y5l×ƒĞĞ’ßˆá¯™aR˜½•ø]³<iËÀÃ­TÑp¨â¡Ê¬§zû—­µÉ:†€YÊ:’.58
DÌ8ÌÙPà>æûªÒ­l"}”2éè.xrĞçiú[‡MZg z…6EìWÔmàm» ÑL“÷bŞõ€Gñsàì«K [Àc4|ˆ±›"¦÷‡{&Ã_Æ0vYÎ‘vƒ ÇÊÆÖ*U'ËÁ;õÁ2 ‰—Cz&˜ò^%Ú¦<y/®Ä\õœlˆ‡°ı5¶6NPbâOÕ—DÊÌÇNş¯"Q”^L$oæ¥ACYsÎ¿M°’Š™èe÷fqkï:à?Ôñ«¯!;_ÑjT‡»ÑÅdÏ¥€A/2¨V÷Æa,Ø³Üƒ@	L¦¹°\ +o²õ‰}yjm''wiêeõÉº¬x<ïôQˆ5É‰¿•Ùä7àäs“edûNK—’2ºTë77Saô°0¸ş°¸1¬õ‹^“s2à:<_Ma/¢1J ó¶¦‹eÂ¸äôÜÈÖ‰ÔKg¢#»¡Ü«	‹Iı«äÅ©%\AûĞ
õ¤¬¯¬z2Ÿ¿2Gğ‘Em¹
½Ğ—c®¦Høä¢LµÔ!'wêoæ,È,gÇ]ÚŞ†òã†`‚Ş|Úòê˜TQ#—t'w…¢=_öVà¬1<˜YİŸàjJÄ r±åßŞ6	Cdú›¥ÏÖYô\A™İìê’Åø¢î-ræÕ2Ì{w¿¸óÜbôƒqºñùSŸ Ö
2Ãì--]+Óp0¯şÁª˜!Æ’¬ºxvu˜åwèÎ-ä”®İ½nÅìï¨ûˆAö¼”fè &NC˜Ğ&ª¼ºùP`ùÒÄµ)Êôï}û¿ÕJĞ & qÊø¨Vİ7"yxh,NñlJ^~Ür‹¨İjÊr1<T€fZ1îÀBÎ‘&¸U¢İ ”í¨Í¾C]xâW3¬]XÆÑİTNÒÑºÚ;&!4ŞJ@PÅª2~³ÏÏ¡Oòãî™Šo–çöä‘N:“`Nùr“Ç6T(y9îİ×ª‚W«P“§õXüV[e‚XiiW°rBH¸-FÁı7BF™Wã÷i†w?¿TãŸŸ·-5l³.E@W×	 {l‡ĞAo¼H?ˆoì5ŒUŞ¥0µ§ ¦§ZÇÔ¥‰2ªVjGÿK|ßÄI®/ëLƒuşßUØ‚¹ï×Ài2Äìãqw\Ù I* Ê4»µÏ«¯u!Ó‰€äÄ”4?u­ÆmĞújûÏë•®bÆknóQ¶º,õÓl&©ô-„ƒ-ÜEC§ÈJŸè”îâÚŒ3:Š×‚	îSûKÉh^ë±Ï»ÂEzøE[$;õ»&ÒÆËÍğĞ2·o´}Šh9ŒxïE)ª½×O£™Ä.Èª²Pñ’·Ótál÷	ËóÖù—rÁÔ'Ğe¤õ¥ÕP')1´d±3<ûÔ1$K«:ÜÂ6‡şıÈ{-±¸êz5¦q—êÀÏ^+væ{®û×'–Põ?ã4Ë(¯Rä·–ùìá­†(ør¹„ òXwÃé²a@Ô4í£¹²HÁŸ{«›CTûÒŞ’—ò\eNbBy™ ´²0•Ÿİ>Aeı¤Ö ‡|N÷$OÍò­L¾‰´KP‹t2½=`ÔüFï—¦‰C,X#@Á6Ş˜¬i±BÓ 
iÇL<.ş‹3ÕÌÆ"'ÇC2Å~nOm<g¢Ö³âá›¢½%
İœõááaÊCºÜH”&ã»ç­`òàûñhrŞ]ë5EYèK½”‰ŸÉaˆ@@²‚'›:Áf‡³)fKÎ³Òí›3ö£ÜaOsd¯74Õu¦ÓoÆ±…÷ãwú5ÿïÿÙÏÊßßOÙ£f›jøn¡ş€åe&úQ¶0z“ ŠX@·ëŞÌ­¡Áöfy³;“ìhOi™‘„V »¡¬ÌÌ±4MÔÉ7>¯ö*åÎçŞ÷Ùcßµ¤%‚ëÑ	×VBúŸaÉ?qÔè	t¶¦€^`v(ıœ6úÊ9(êâˆ•î¾¦½0³à™
Lj²¦-«h;ß7Exêƒ£¸gƒ^ƒĞ×;@ó¾»V´ßæ¾wÊ¦S¡Úoœ}°ğÊüĞ0Ã™AÄu0‰ÇüªS[zÕ©f3|¡J¦»jëĞN8_n [œ_¨2BÁÑÕ,B?ß<vLVoşŸ³š=Bªš¾KµàøÂ`\–”Q	#l°n¥hôŸèÌ&bI§»²ú‚F|èBğpõN¢LÅ´—Ç-[Øã°ïs¨®ÈN%š­õŞ6´¹à8DÂ(iy£^Zd³Œ´ä#œtY1Â•"’îVÓôHøN‚¬ødn:¾÷¼[,²ú#Öˆ_ª«s‹ÚJ@ÿïÎ¬@NµÇ—"€¤r²E¿J³úÇØ×ûéÍ*Ôğì‹	=™¡‚¾°+T9Ø2‡Èuq_Œ½nz9š3VjÜìoï#Im$íİ´$ö]M¥?”­ˆ‚7#ÓcõS !>İ¹<:Zß˜¿î^¨¦lÏÓûi&^)	u²Â•k©NÊÄÎåücæ%é&`wğMä²Ñ¸sŠÁ•œ3¡^i±P1oÑÓ^M$åF½±K<q'©-CG‘^Ü¢ÏÜ’–­ñ"6H=€ vòÜ¶MúI‰Zö'M26hK>ºhê‡Éé`
LÎ1{†ÂŸz]«—“<‡h±yßzP0E‘Nñ˜<†‘½ŠK7«³èkç‹S·
ëZÀÍ(/qE(íÆ®„n ¡\î‹.Z„5tT>úÙ^QW³<r´dîM©
˜ø*íâ]MÃK×‚Z0‡³¸Â]D+
~‡$JÆ)v<ló/5ÀU^…ó¡zsÀß÷èOòAº’½Jy¼m†ú?`§ëPwS[í³ş§F—àÅ’éöî2Ş>Óe¤âU&³K€e³ *0‚/õ¤™ ÄûIp~é+İ7’dWûªúı~Q‰*Ğ>¾wAë.ÒÎ~¿%ëLYÜÚ>ĞæÙcµÛÌôF"ÊºYjy¢Cß”~¹Ü"O·	¸A‰ã+8nø[a08
U
zÓ1	‚éä•‰]· $Ú×C8´Ó¤Û°ç©`Éïºm!pzğÅl8n‘mĞvvûJI£bZbr¹×]®î õûÍ©ÓqÓÄè¶sú­ôRbbÜ5‘$X‹ü"XQéß\´Ìı¸Y?Øb¬úÈşë/1j7CÁ¼çQïï•â7ä}Ó$®ğ¿V`YÕÕ6Œe~Ycß¥ßš½àıÂÊËqı+,€:`P][kûÀU@!Ÿà>ÛD=]Ì.Ñ_.¶†¡**ÂH²c‰"M®?¯Í;*dî¸öèßå ÔÊ±ÅÎ0L™Íë?XŠ’=®íG9®~r¥¨’ÎºÔ’-hbawwP^Oí‰@B
ûËKrĞRÛ ¡?ræQ–Ùî•væ/\÷ñzâ}¥ÙCÈ0ô„§_äÎg0üçÙí”+†”£ÉµqÁ¸6m¸·SSÏlÁ©#íOUâ˜¡7±…ºU&ì•Ÿ¶³SDéãÄ	Ü¨îØ8UYG‘#É\6Äg3|˜¯ nƒÀ¤Lıè¯‰ÔÓ¹­k%¦Ç_N~©AoÏÚnO“ú=#ò¨óÀüü¹ğ³"·åä—Ú€œ.û'Ís ôÑÈmå¾ÆÓVõã«:®ß^âÈ†‡Ê.u'H¦ç!ß‘svßçïı².ájMìF”œ¹84¿Õ²)Û,ºÎšÆÈï7K/D{Â!pŸîá6	ùíœzt;’vîßtRÎ©Øàø	X­#yFyx¨ÖãÜş($ÁÏÂ³‹fyÏ2¥ò’š)—gµ0Á±ÏÑ­F*«f¤pÆ¡3ŠÍãPÓöàsRûÀîj¤:±E¢ülY¾A?î+”„D–OÓ†6O…ªƒñÃwÇI&g¸óöÕıñ
ß‹R˜ö^‡Õ¡ÉÚ¥ÈeÁB‘¿Tˆ¾ëålC5¥ÉêàµÍ[ô|I}ˆ£¸ùš
Ğjv}1C@ú[àÌöŒYÉBºèÆ²[ÑË¸ÕÒ:™¬pe‰L@Mê	æuïâıóbÄzSòp÷·XxjÃnóc L®êDy¢ÛäkB]£â91õBÈš„ ©ˆíôâíƒâjËËM`G‚‡‘ˆé‰nác Ël”KãlıFy{-İ|ŞÀezûA=óø¸b´ıyßŞšñ}«´1á×ï!LbjÆ½	´×Ø.ç½"+Ïux•4°a× Ã† Òå'K]ƒ°<«½æ¨Üß›,qg .k§=GäwIÔ,ª¾*öiÌ|í‘¤Tw&M/ûÿ‰ş^óÖ#"~Ó$û)‰š¹ÃÑïİïÌ>ÍJR#Np¡—‡l«|æ©-)¶)ÏÉ/[°”C¸Úæl³kÜ»ùïûH&q³k‰MÕ£U0Û=š€T \Ë›[“9Ã?Ü´/%b#VÚ\"ààöìV<8•]#z?”ä4 î__´òS1Ÿ>Ÿ-¬3ÄÜmKšİ¹ ¦­ÿ~ÌëA,vè³úè¡¤öˆ‹7Š˜æÇÜÚ!FkÅj#iŒMAÈFÑıX¬U·|ÏZ9  £iÊà
+ƒi2ëhÿÅ°ïàË®©¦)®ùÔQ¸úQ:fŠÈŠ¿õC1›mİÁ	{¾z¥÷“ÀÊOx .ı-²fXàPyúyÈû£Ã½L˜¹$‹Ë_l²Š&6Xv»¶ºîÜMq{h&°yeM´9õøM>eî1^ó)Ğ^çÕU¬…[ c¤™$,àÛ³…•l‘ğ «ì–W‹Ù#ÏŠ .cÄûÇŞß)t»)İlR"RræĞ8cC+åÔsüï‚¼ß3[¾RŒ e%Â¤CLˆ‡2£"”¼Ni\Å‘vPˆ–ßÚ›Â53œ¶Š¸xÂ–ú2Jvk6ìBù•SŸc+eDò 8éâï¤è˜ U¸ º¹–ØßTUqãö«NÂHDĞ‚¿ÔaIW	Y;˜•ré›ÖßÅ-Y’½™Î·ûÄŠ¤KèĞnQ=¼‹ËTç½zã.{1HÍ™ÕÈš*LØŞ’	8Ü^X©ÚÆ&|jâ²Í“RBÊ„jìÁÛqìhÍ²>4,-–±csGfÑD·
8¨œç¹uR
B|4K¼çñ¬`uŒšR¥ÿÿ=+	n+´Búv<"yjÓuÀ3AÇ;†V'2'Avr1´)"Í8ôG5‘$ÀüÖ~Œ\™Så¡‰°Lû!V¢uÇ‡—^1°>ó9ÌÆR`Êø¥´İGš	¸WTş«hºZ¶›QCÔ€‰ ¬8ŞŒ~~p
î8aT¤—•Âw„¥¶Ğô[ã7¿§"ï$B\·—<êè»zmÚqÂ; ìûÄ¨³;ãºíşäc}E„Q%ÎH®>ˆï‡)ªV$d‚‚ô×ã“­)§¼€ªşI›H>ô@^¹9É4ı®ÛıŠ¨[¿•`r6.Ì±,0®±Î*×<Cç¦ÛFÔb¯D3’d3V/Ìküëódğ­ĞVÆÂ{eikiVaß'Á¾fl¿¬²˜vÆTEä.LmrC†¤¯›D?¾îL…9¯™?òNZó'cuS. ÁõP¿vd¡ßN9åCMb–®; •+.Îï{á…ap‡º=Ç°]2²ù.ˆÚ%$âÓë²çÌTĞUŸ‡z÷')8w#*$&Ì°9‚¡oO'7Kš?Ê7+k@azâÕ6Æ¦»“èÌ˜ú-m¿¥c=‡*õu7MâE‰ø•è\½O;üK'äŠ¾$ºãÒÌBw›%‚çã‹´½Â@Vô×jëp.(]WPà†ã™È Ğ Ağ÷I»¶%u~•d÷"„ĞÕví!­Ã&ƒ^Ø«øÌøÒS%¿bùCæ›R¦°ä…‘íébVŠ^Ù
{©fklë¬û!d¡t8»(gÍ'e,'ÎÙ°áP¡°-Q^¤Ø¬È
õå©…ôY(ÿÏêåÆ04İ=¼÷p†•TÅóáÔ)wA~È”¬Qi$šú ÉÕq@$Èå\fOŒ§0±ŠOş„OV~ûdØÛq.˜ÆÃü=ºTj¬46@È²”L¦Ğ_ÑÕÑ–™íü{Í½’‹7UÓ_=–Ä÷‚fÁeÉRÉŸV¼âîèBj2dP".¶n/ta®dZJ-Ú­5?avˆl¶!~hfôU=ªò{*”Ÿ®ã¥Ï2¤QĞ7/b¤ŞBjE™ƒã¶Ü5¢Ñ”µ .ã6NêØŒ§¤<‚'% >ÏÛ[[’œš§ÈZ†» ”}'XMß+$ÂBÒ)9
njÉµz|‘ùÏ'AÉ%Í.CsòUÃ°e*üÑwîe¥õƒØ,ÆUê}7 ùKJ–Ìÿ?6²#ÂŒeûÃÎ·P#èüÖ}¡3|¾Oj\wtã-´1'è”^Gi%	Æáº"ê¨úíVú[‚]äSõ3B<öæ^‰¹N'Ï1»şÁ×–ğa³M „v‹ O;ë¾	fŸâ‹_ò…'Ç0U.ûHİZ×Ô²ĞDTÿ—ëóİ•ğû]¾¨ç-÷Éâ=æJBâôg´ù0ôíÛª¬•RîRç÷aÂ£"/®5´†2N–ûûLVbô%~;g©ôHïe°gâI±lD…‚ĞrİnmCíL p¸N´Ï‡«l@Şüïğd±v"h^Õ’·º’”ùÉ^Xßô–ºå¬¬´¾E„fÄ¤.°2’Õ ‰!x¹õÂÖÅrÑ€j	Ütz«¤+_æÌpânx?,¦Y4²ñéÿ—Ã†"a#@çÜãÜÙ—œQá ]5*í¦oR°*L"øm„Ÿ‚.º©Ä#…:ÅíkÙ-g xÛª’8jüCNä¿šï /gîcKít£r7êŞÜsPÜ<xzar¦	+µ{øİC9³üöH¦ŒÎg`sxh«˜8›ğ-uğTéÕ_-ì÷gxÌÎÈCn QÍ=ŞpÆ¨u”F°ûEEPjkÜGùÓïÚ+¨_Øtâvxãe³ j‹æğ³&ùR‡`lO]7ï›ŸÊ9®	2½ô¸içæ…™[şX2ûBè{§1ãôNÿbÜˆJuC1ä;>±†²¥¤œTë•W)} [&q…V"|Àşš, ¹…Áäuˆİ©[¼²‰$\‡KÜïyşÆ;tûéyx6£¾(›%H PàßBQ•DÒ[äŠGh“&ôÑ‹É[¼ r÷U†«ô°J2pÆ28ñí[du%õ _"IQ&ÏwÎ|‘Ô‡æ¼uÀƒ}œ¿x¥Ú­¶“a0@­Ñ†u1ŒSá*‹vc}gaÇq9ÂMéx¿V@9İ\®2ul¢!—µÅ«BáşÊš•¥ÅIJWæÄ*¶Ïşcy¨ŠÁ{Wû®£CZMUŠĞ)ÛâÔØ‘«sU"½ecíÛàµÜ·a.ÄŒ~NŞ¢é42äùŒC±.™×fob¿1}€ÿÀ{ÁİcÄ—ÊòØML?hHmÙFì+ÂcZS¨Xp:y5•´h2ÇîEÈ%#÷éƒ¤ÕJk²˜vûâ¯	?~}|Ë†»ïÉ˜<c¤‰+GË6ˆàs…Úî{¨{½#Dİ|û\ŠÈ™xù«ˆB¦v~´±*/¥µ |¦Tİ¾®*öø¹¼Ñ†a¿~£Â#ï{à_|Ec¡pf7RSÒÂH4ÑœÃ¶5ÓÆ×Lq®_jå,f¬á	YŒeÓmqKËW;BÉ»ş‚‰¬?ç‘4ÜÚO}–Å‚€'enG<Ğ£¹€¨Ebò!§ı-Ùˆ_Š€n¯×¸®r{M!CFëÏ ³jyrõÇÖŞ‹³.Rv“Â1ÊMgÙ]cVØD÷¼7®Â‘w“¾€²Aå:BbÓ)Úî(£Ö¾*n/Êà¯ôÄÌ<ß€VéÁ v$Ô"=®¥.QÆm|“ØIkS~¶ô3n…òâ¦¥Ş(­Jà}‰fÆ§*#¨ÓGÕcZ²ñÒí×(Î?zeAÁ·ğµ+m6Û„#ÂnÊ¾›¶—¿G7–´´øa£½|ÑŸ— Õ‚n¢¤Rö€R^X•ƒÒ—¤–#rdó‹Å-]|ôÕƒŠ—³×¸ò•u?÷BkğŞa¡Üc[;ˆ4oLßô¶ëÔ‘[Ô+w£›âÈ´ØõŠö“›ëÅ™½Mõ«s»Yo$ŒèIYÌ©M‚¨
 {t,EÆ«28kı[†ï‡T_z`¼&eİ$6òYéËÜ 'É5ŒsC¸9°Ÿ ¢*i=`p¬Eb{[«“mà,ÿ}„ĞÆŠ<ƒºÀäCSa°Xui“&tÀÀõ+ŠtÜ²…z@FçÚØJºå8çZºcEøÕã‰h€ç*n·dTrâùÅ`rÕ`Ÿ„Ëíq¥²S!¯íÊGI_İ„ÚÉƒFé¿c>¹v¢I`+Bµ¿Ë?&£İ4-\~¸ïíG]ƒ˜ìÅAJÿQ¤r/fÕ÷İ·ıõ…*_võğÂÙc°L-ËC#wºJÂÉ>ŸÎïÉœ·O%_0Š¡”ƒ…yz	bA>7¥mÁ—C÷WfÅÓ†d(Èá¾0/8ÛÒí;!Uá<‚šƒ
<sËÜ1£l0B À yG.-¾Â°ŠŒß»ju–ìY–Î“>í=œ¾Z¬üàz‡ôñô°²ş»)ûŸ‚7õ<Šf	øïº¯£=0³d&(Ia+^’jt/|.n{°(;A-ôošâÙİ¨S²èÿ¶l‡/VÃ«×Œ0Iô ÏSz#RKdÈw8§¹®FİKşx°»Tâ1â»5Áœ^¥p£Šú1´Ö]¸/ñ¾fY8Õ‹ÇâHî½ŒVP	QWµ•É¬gk‚^]¯	şCÈo°ó%$½+Š¸“¡®g&Ÿa7qL!YóM6h•q.Læìü3Š¸S_/ß ñ›H!®0t«<0Bég¡O•#xw€K}Úæu†à}Ø8>{:ÍLVeØ+çài¦Pá¦¦æØ¬Õn1ŸÏ kğ•ÜÂ}’eŠüÕq×(KäB%jşôq‚t»î,µ
Ì‹_ä¾¢Şş¢4 <Ì9Ã*T*éµ"«¥4avêÎır_cL»«ü ü”¦U>è Ê;>ƒ|ìŠÛøàî ÷ª‚ôÀ²ÕëjÈ©…~!|ho-%Ÿw¥K=n‡!Õ
ôêüšÔSgÉo´Ù•1ÈÅáÙâK;XÒ‚Y€1ºáş&v
%{È¢÷LCH9³G!™ßh‚‘H'lM‘=©0€}nM¬ö“í r–ÚÏ»MSü{"NSÅ;Ä(ò\¹i­Ş´Tkä¬¶ıàº õ¥,É×¹gÏuõ^²ÉúU€—üùµy^îßf¹NIT‘ªÇ÷Ûoh…Ø|CoOÜ~ÖPçÑíÖâ82Dà"+v^ËRŸJé)ÕRCé™*;Ë>)Pnm[ª1|Uq)[şÆÑ …¤¨/¢o*l9ñØğÀqN.ÇÜÅ{µ†³ñ|Ne9ô4”‡8÷ƒœÆ4§ÄwÌ–DÀ„ {pé|èÈ„(EhàË÷`ÛIµ)×£\k“àÚl2Ìtå üsş»ƒÅª«Ç.ĞÀDà¥¦¶ïXœ¶ÈÏ^,•f/$c®	ˆÌt•¡† âÙgŒÑ¸É´ŠäS0üSv2‘^Ÿ²ëCúmF÷g¸µw“K<¾­¼¿Ó?Çg¹,¸¢l¡E^2Ì†“œç¯@2Ì)ZrI×"d…°‡‘ÿƒ£> 3Æ=ÁõúÒ)_øÁ‡	ıéYÄ”[eÌ9ek2aŸØ~ëHGÑ×˜ªíhFŠŸõ1fqå°ü{Ï'À…Èóš:l<-‘=}óàıÖı¾UE˜r¿ú…§sóÇ˜Œ(Îì8„œ<0ùìY‚âQ‚²YŸ‚QäáX¤wÉÜÍ/ª#¤'êaZ˜ÄƒGfË]ËGzq Ú<ópg ñU&ÿö`Œt6ògøùíe2O­Ç ¬U’*èé§LynütB¦'úœ@¾ù_–Ó9ou”"Ç±í(ü/şœÑFU,¾ª\ÅÃb­%=È\Qù”Ê8ã}éDî®šÿq[C%1T#9ë^ĞÏ-¹íŠå\ow˜HA¯ ë_¨ã%Æñò}¶ÃF«—ï!!f°+
Pßú/öÎ³èÂ·
'h»Åq»ø2QúµúChyŸ]4æ$Cqß
Œ€^üFuÀLydj	)CÕÃØi»i×”f¬<4_ºŞ¥œÃùC3%a¬éN}xö¼\:O(ñ!¾°s3ú‡]ËA4H9Jõ%à{º³ıÙÍ*çÎ;zr­Ù2¶³Xî…ƒëÅø…s,¾º=°‰¡«cQG0ÉSe˜†1æPùÍcLÇ_õø‚ßã1ÑBi¹©P1y†Çü8¨Z‡uQà•(€Oì\šë°+yÛ¥:ËÚŞäâ°Iı«y†Ÿ	ıã0‡–H'3•Ô	şuÚEÉ6c5ËLë'N%Z+ë!jp(µÎÁëıæÁ‰ÂdDã–7ùÈÅùßÈpO=E[êdc¶Âˆå•oWF»gÎ½„WV+/ä/{ĞËQ\e€J‡S0kÊ\ÔÔ™?v'0·Xr/J.z·Zæ+ï#2’„‚)Àoxßé‡¨Y°qµåB€c­'ÚNFöió_¿íÜv×s¢
v|Z&\=
Œ?M+É}í&¼¬k$}D»]ÈÜŸ6åé*Ê)‘«-Òd½tİ5kwØb™Ì)×E+·m¨ğbKFV¼ÍQÂÌößr»èé\÷,)¸tzglÙ;@ü×qÆ9°Üâ‰¦*QÆmó››E#ªÑ«)Zmê§|äÕ•Ç²Ö‚Lˆ	$£±ø÷~–$qe²+h¯,»ä½b3<‘å?°ß09)a¶ÍÉ¯#°;Ù8õ´Ü¼Ø
à´¶Gœl6‰w?74Ek¾å\u|"¥3qk L_TGzÈ&íøqÿŞspCc}ÜÓ¬ábÔ;r§¥tºlé<Z÷å°3Ÿ˜IIî|š#5/CK¼}S(ƒ*‡ŞÌ—¤ªùç¯ü•¬‹r¾—@E^‡^M·bÕöTˆşJjXkê¡YíåKŠø^	ÂÎ•Ô–EjÖ‡E/Y//ÉYÖÓEî¦”d¡„2¹€7*C:àUD4?sü§‚ºÜãÕLY…6èc>Ù®y‡hª¯L\ L¡FÂ¿UoÀRö{Gs¡ÿTÏÆê2Ù™Ò“·ËR>+yVñEt+Áˆ´/Rƒ§j©hL‡w"7¹TsB`Ö!ƒëÉÀm~e™Œ×¿9€·ïóàIĞ‰ÄkÉ@¡¹›,ã? ßfş›T{¢S¸ÀÈm§j'İjuoöû4VV’?~+¡Í*}D´-V(§òÔ,ê 5^í]šÎõN]•‰¹Õ*À¼¢‡Í:ş‰¾L¦>³| !Øày$Gz‹C? ëÄÈ½ïåúZ_ğ‹k~ş"èÑ—§Qç»Àİr¼gMˆÃ”£Ìô—ñáÉÄ®¶ı;Ò Ñu±RÖTh&¤`‰ú¡ö¸qEW×;»j5”o[ì÷&ğ&rxûÓCş=~¥?"7'R™úØO1ÕdköVXÍ¿@Øîìèıs š&(èÑıVzH_šÒµû9çr®1ã{¨§I6s;<µú1&]÷G¡”"
Æıpad‘TA>åõ_lG®mÙ’Ş
P¤“RÌ–V°|dÀFdHï­q÷»™	vÔPZz>¸„†]€)Ú¬ƒ9suü¾é‹)éU÷Cşğçy…R¾÷½öTÒS,yĞ34J“Ñ
nŠ-5|w[8İ4I‘KÃƒ 	È­„†  ]mßOÈ´­ºîÂì–™¯eFTşkìúÁİ¨pÍ…B¯X(<*öÃ 
›ä£×0‘@ñïıßeõårªÜ(‚çK3ş Ía?T@q¯)û:Üº%‰C^ÃèoÚdjy`«çôrÔñ˜ıqw;“^àŞèÑPËò…,Dë®UQÕz8©4À0&DAj‡5¶Œ?Q]. ÉmáÂ‰9[QWsÃœA"ÚÙ}é¯ÁŸM)KÏu6õ	4ääÇâéo( ±&œé2=¦
(àK·@óî·¿oñ“Çİïéâé3D$Ü/÷†}‰pf¡$WÊ<5údêÅ¢SWˆ6®…OÆ¹-1úhô˜Ëˆ]ì|[Ü€)‹Ú™)cUfÙ¬X¶ThØéË h–”}Ô¦:iœFUí/fŒ€,‘A\ï^î_bÈ‡ñ.ÜÌ_gåŠua¢¹ÅqqÓ¨Ê’~{¦ÿdºHøàf¼OƒºLøÊXÉU¯Ûâ¿ãârï”jç ÄbãõAxÑÛğÈ¾­Nxgl©8×µ“—×ñ¢8Ä2ºRG¢á>™ç‡ü±hX½ÓîCûX_+09îJd”%€Q‚"¶=U^ø:I•R˜™$Lm»ĞÍ•üã-‰© °j‹Jıß²‘¢ºš@Ù ÈyÕ_ÔvĞ°d’Ñ?’ú¦=W› 1‰¾²ãh°%#<$‘š¡fAH”l±V úŸN¯
(cÒù·Û-¨…2ßW*Ik„4°t·ßüÒk”ÍV'—$Òë¹¦-°½fò§<hNcijÙŠ$Ôşm]§_ö²Hã
«Æ·§
òÓû@p]‚kõÚÁ¿éƒÉ]ÅJ; ÖÄOÙ€“pã	„}V°B#W‚4%¼t‡ƒ‡š_1m¨ Ö41Í$aÆFÜí98µÏ—4]F|»Çˆ"F:ÈrZ`øUõ¥ÎÆ€pîf€bû
Ñ…ş¯PuUÌD/3âL©¬nÖşTø÷µêœu?v«„r/¿®+ëŸmz-ü‰jÆ ¦ç1ŠÍAì0ƒİ:“­NÍWç:÷ïÑª|ºÛPxİæ¨0U§It"íÙ¬¾¥­”³©ØŠ5ô’ü…âØK÷J(«{®EuÚÀˆ£³ËÃŠÅ¹êIŒ[Ó ˜‹1Yˆ±€ğ‚¹ùœ5ÉôV‚1*Ğ”n#ìÚ‡læÚ;ÿuÀz4?˜äÌG=h©]#$1AKIÍ‰‹ÍU'!ÄƒëkÙk“kaöÁ	šJwİĞÜ3Š¶¹ÊˆÜÛÚÒ‡¬iRP6œ>İ„ ª\x—.3ı×÷ÚmPT—£—œˆ±£ü¾İ8Ë™=÷<¶ÔŞĞÒXªq,Y:^’'ºÊ™•úÉ İë¹S<8rö2eupg‡Ÿ*H¾Y2ò~‰^Œc[Ê1SEg7?~×<‰8Ğ£û'P† Ñf1&;m;ßzN-óò"Ìm…Óy;èß7Kßºé‘1~ûGPØnuŞ-õ½&HŞSLÊ¹òNfDBtá\²ªÜz[›çÍ{Â’Mªø©NÖ@æÃ(r'Š¿~*›0ƒÈiuÙ©íıdŒ¥EàïD-† ·ÇÆyñ>ıx×m¦>¡UgÕßëÖğxdáz‘­Ñ*J˜½6Ö•Fáh¬±Ÿ¯tˆÀªolÙ(I"	¡:şÔÂà/ÄtµÇflâH/ˆ­–åê½ğıúß½¦®{ò‹Å$¾CÃ“y §òŞ3×:Äÿ`¶:Èäi7ŞÈğö-KkßòğÙ¡•'1Ÿ1%‹Ÿ¬£ë7¨†µçÌE"·4yÄX”Æë÷À9âûM¤‰`lÏğÁµ~“º_D®/l¼7näDW'wÆdzbš¿qçqƒ’×ßsæ(¥q‡‚JSOóË/i×Ê’Ï6ÁÅ^óø„åF (ë÷Z&]E´^†®BÄSÇÇòe’]WƒwUÔ o’8§€İ† WûbX{WÃáËÊ^î/ØÕÍé¦i[”Ku=¶?]ü·çC[B9ÓöÍ’m~^Û¥³«]ğ.¢
ŒñºŒ^Èîë½­vŞÖLæ€€$ÈS¸¿`l=HyDä´Ë
NJåfD†ÙÁ¤\‹O$­©K˜mÊÇõ–k¦°B&\ADO°[3z¼î£G™¾ ¬O?Óm¢¿™¤Ş®ƒÔ!Ó2ïïíüŠ¤9,@î––%JÚÈ¨Öb’¼ÃßÖÕ"…4ş2y|\Û!ÎÆèÈ£ôÅ—†]âÅîÇJ90tĞ´ø=ÚÈğmé„©Ÿ?©È’áuQ*ÜÁ&å³IÓ´xkÇÎĞéª[&bh•\³5[k¨œÒë=ˆœ2Y"¡âÆ5Raù‘_wÀ«	¢X<u‘©¬6ua¶¾‹E$ªO=¯÷Å¨ĞòLzWÃ4~×.ö|òƒóh©ÎüÛày»ÅúJ¥ÁÖ;€ãÍãtÔƒBê©³ÿÃ}[SŸPÀü´Ö¬‚İå;Ÿ¥•ë%jy¼¦Ô¯…³X£n^äù-#-_ÔC~•}j/ìáåPõ¢½^&ˆcÿ¾G²Ù{˜­Ìëã†¡UséyÕ%N¯sîâ0J â‹3P_L_ÄÏü„Õñ©Ÿ,õSû
ó{Nç 2ÄµÉñu	ÑÆQºIIs0òC´z¹®™y RSƒ:,ó’oºÚÃ¿P…÷Æ3L<çnayvV¦-©t¸~²Nh~†K¾oü’ÖŠ"lö(°åµ& +wqæ¶Ær¶{lW0ä¡cR$Û¶á:±{™)'D£‡õU WWÂ¼h|òœä”ååÃşàA•ï<a}Gt˜QÿÊÅ´¢ìÖn?+½-™²:¹è[…Ò¦I¬ş¼9¶@ûZÕÎÿ“-ÆÉ¸Ø}\×8sé!‚¢rs+¿öjJbpl@sO­"ÄHö¦0oœÇáUV1=”\9Å~×PÏWÌ5rßRàÙK›§ÄŸ•Ô~ryW¥IÓDÏÎ;Åcÿù4ÖâŠšsø›“RÌôêíØ™åaU½™JvNGYJíÿPŒ†V
Õv«o¹œ}_¦ñµû¾¶ºıGËSìN½dÁß_ÿ(g˜»XNstÍ80à@)
£‘P„nÙZt=º/³9MAUÔuïJ”Ë<¯)óLÍeD+W=˜6C(.×b"Ç&ãàO•ñæ"BØô…‚¸ÂŞ™‚à´púnb¶J„.f¶0¨†T)K»¸Z›2V~vmI2—^hà‚dq´_c÷Siìæğc(b4™®T¢P1]¦!gÄ²ùÈRZ8Î¨İ»ïÜ®x°Îñ5fqÏlÀ¿î„â¥•Œ>¶ŸîS:õªæA &ªm©åŸ†ÚşĞÚy{åú¾Ñ÷îæƒ[·Ëµıùú	Œb­5ƒ¶ âˆLJ+/5ov\
Ä‚9°°Gˆ½"Y¢Ùj®JRö³öØD²Ü`3İ^N3™ò(©PÙt¶ß2Mà£¹3È•p Ò¾´t‡·?Çœ6_PĞû'÷ğ#£ë=ğİÔJŠ‹ÏIğ’˜î`d}äIµ‹õ!&,‡+ôƒ³—ËØëÇ¢išÎº†]fœ°ÂÕœO"ÚŒPâ7qVfQ"6TŒ'Q	)uÏéósr—VñÛôEr‚ûnJwÓK›û/İòÉ‚¹;}	8DŒ°É¾Ãab	ûÉòb/ˆCØx µL‹9ñEáÒ×nÓóàÀ%w.Åğ|ÁU´Ã¯
' šZı÷8÷+oÏkCB¡íW9ƒ7ğöÁHc²ÀİøÁ/4–²Â.{Ä”:ZÖMÊ•'/%Èí¥ÛlQO¦Gv«Ò²™ÅqHÒißÛhøFMÅ“Á­«Â5ÙÇ¬­qRşÁ.x¨Ã&I>¨y„Cº3Í*%cíjøşY#Å’½¬¿›>\TĞƒ¤i½uÓûË›‚´ï ³Íìv´Có(xŞjX§ó¸!Ğ…$ô´øûdİ"ıàf\1«SÕ£Ñ–ƒ9ÒïhÛ‚Ïÿ(ƒŸ¼İu +Şë"Âİz.TÄ×
6NP@xN–åÁm~:âWCŞX-ÿŸ’Yˆ»gFE±ş®ª>È’Q[°’Ü—)/ù‰€£¯½*´ÜšÊèù>*ğõóU•§±°7Ò %;ÕtéÍ„*Úl2ğ>«Â:%20´U7€Õ
‰.l7Ğ³T'ÉOh‡¶L4_ªÎÔ# òkí¦ö‹ “l|#Å×F®½Wa»Ñ:±$êŒ)àá8dœ6-m~<ü ’¹Ÿ*N€§NnQ“bÅm¢ëç†•¾Ñœ-_²ÏñRºUò¥šH8?ØÍJMnMİõâ€¡›¾ƒn~xïEáTÃ+ÛˆÑ˜wkp»=?”Lêi¶~¹‡‚nêaÉÛPæç_	ø
7xÚvi~W{G>-OÅÙ[ãÜ<múY3íN§,rEø%j}s¯¦–¾füÇ1’õ¢yŠĞ\ûÖµ¥ìª—yßüdü|Ç#Ï6J¼¸µ©ZÓÕƒˆ°»`ŠçÂ5õãQÚ—:Ùí¯6¹¥³åRÉÂ5"h€0¨{.ë¹í#b€ú[º“¥Nø¶£W–)\ií¼ÉÁ@Vƒå†“ÉÔ·†±>%@©¼rt¼Íî0#ÖîÕ4¤+’ĞeÛÒæÛúì­= <zfŒğÀ5œˆ¹&|ú
±‰‰·~–BÔt;Èk\&ÄBtı\ÉmfâLNºöƒ”1ö5ÎwQ¬¦#ø¼\ºVBï
}³uòv$›àÕÁX—zöŒp|† ¿í½£œa	ìèÕViçYH±Á½+Yy¶‰“¼…4sÕk¹é9ğöWÀÅÀ@¼÷Ğ—øœŒñ#ğğ¶·÷hZøJHL“(·¼¾^´±D‹3ÖG…‹ŠDbj’º¬ ÁØÄ|V6&½	¶ÕŸ7¾F º,Üp§^.¯c5Â·Î*VKûvDİ(†›N˜tü‘ÙÔôºê‡áhÜ×Û3£a`ÊuÓ5Él³kÒ‚/ÓMö‡¬Înœk’ö{Ác3îÕ#ë•ô›¹ÆÕ·®½¶'ĞûŠ|0R¸İö!%Î,Æ­ç‹—QIÀÆe(Ã/»¡ëã½pW¿P8â:Àú®3ğ5s¤qáxÀxFÕl’¸{vÁ} üg´ÀŒİ&jké¨¬h9ÙØ,D×Ó&ÄïóN¸¶ÁÃÌçÏÈ!¢jéa	:&ËSP–p5ËP”ÑÍ;`N!Î~°“‰$	¦øq¯l*õ§œuÕf’·ÿù>Üy–n-ê•7¹ç×XƒšnüÌióî0iAy.c
=ÀNR_éä£äĞšodhæ¶ñáÊ>á+ë;˜ˆ{à™Æ#Ç‹‰$è‡@„ö½ß9¦Fİ”öy£
ø ŞíöÌFPh„°3»Èx‹¶·‰¹U•—³â×*OÛIş‚¡íZoà~`Æ9(ğ„=®*ÖG7U£Ìe1’0‹<ŠÖ$…#®@¯å»_Aƒ«hs_ËÂN†Áƒ'GYºìù©}\ĞB‘úZ¿CËx©'hœõU0m_×w =ÿÀAôµÑn™=8­4®çn_*ºÍÍÊKA¹“(*i‘àt¥°{ò“ğÙP¯õÏÔŞ®’¡lÇeĞ]$Œ‰Ù2‰x‹R³|'Z°)¶âÚ#Ü¶–¡zJ‘¬8*ã rL   yÊ¦šq®3 ÷Ê€ËstN±Ägû    YZ