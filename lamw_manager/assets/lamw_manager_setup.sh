#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3608122813"
MD5="6653955ad65a38756b951956ade99d4a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23632"
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
	echo Date of packaging: Sat Aug 21 16:19:09 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ\] ¼}•À1Dd]‡Á›PætİD÷EéIë}¥q~2ˆãiÍù§I‡xV\ÚùA”ë:ÎÜ!í0Üã§.`İ/‡ZÅe“§~`—\ô`ˆ["8İĞ
3+S¿à3¡m§Mâ†ÈQŞ¶›Ä-ã,P"Ü¨ùï…ï9n‹NLVÌËü2®W['¥9K¶ˆ,æÄÆ”æ—
ÿë<˜4\LK€"7¯4ñ¬TWd
H H=—±Å˜c•]gŠ¹Zê3­çÁk‹÷±’aXôÎ ÁçŞŞxØxå£V[n™Ô*IC/¢t.&£&„è^L4*“Ü¡Îº^c€ÅJ`–$ïêj Ç~¤ñÜ«ò(ˆªÍ{}çå›80x’,*JiMbT”\ô/x± µÚ•fİ•¦mh¯‰œE£áD:Î‚XeÃz¸=¾3´@L+Âşà~ïçn´’tPôVå„rïRlsù:uvA:yİì­¢¬bª´4Ejû¼¸û Y@åBBî6ƒ\-[l>äÃ[gôÉÄÜYÊ®ÊµÑn4?oäHStp;Íòí­&©Ùz4À¿ŞuÊ$Æ–Mâ-ÜP-9oõ±<™x¶3à4xëë !»›<B”B¯Jás2K÷0A2YO<‘¢ÏNddT#õh0MÁ+ïä¸µxxÀ/>£»›ÿ5M¬(¾¹f\f½E†¯Ùã·Õˆ*ÒÀ½XÚW.œ¸ø!Ği-,,]åõ
(¢¬¿ëü,úğAfÖ¡^hÌééGÈàĞ{8uôi¾c±ók›Ğ†Ú3‘”ÔÿVšìlùb»¨’"8æe U:ôr©|ÒOlE‚ÎÑxşÙÌ¬Lªèõåç	….“
1ğ@;¼BP1Ãº$½Ç§0ĞÅiöZ ÚğÙßÏïøëL×UFõlğ÷šd°»İñTT[¾Ÿ¾á<ğt‰/úhìCğÕV(u7í*GpÑ:vrGK<:ÿk’iô÷v?b”^k>êNƒTŞù$}zyfJymşˆz“a=‹îDtÏ–²‹G#+I)¸ªĞ«W˜´¥Zì;ÉfôÌ¶la_ùF8–_9yä7ÜX|Œ€|èÈ*IÁŒIŠ¦Ypä‰3ƒŒ>Ù•§:¹âøFö%(øà»Îå`1ïO‡‰ö­ˆu|=À<i÷&İÂáß5íÚz‚RµÙ‘"€|©ÛÈ¡¤‹' ÿğÓ×wswQ!• %\¾Õ›:ó×—ò²Yó@­ëV®‚¯ÜÙ4Wl\ÿ'¾Î£¿óo^íyòâ;Á¿£k¿'¦öĞÒ¶ûYÅÑ>¼çK§³2‹é7´QX£.ÜÂÙµqŠ4w³
ê”u"´££g…“Æ[u»˜¢¤QÆ2ıÍÏ™é=‚›¬÷ºİĞ«0‚ğú‰§ÕE}”ÇXül¦èÆÙnˆÑ¾àNáÎ(–³1uĞsŞ€‡gS—ƒsM+‡Yíÿv?¨LgbK
Àâ‡ïG§)Ø‡O$ªì<wÑ‘?²Bğß„°	âì¦/FPúÙÏk@gVZRtvÿjá¿[IõN(½=‚ÄÑæ1¸!ÍRYµô¢À.úJ¶Rî”Ğ78X¤HB¾ıÈuUİëÏÈ…Ò¤!ä¹½4¶eSAëœŒ5Ú‡aC>u›ˆXÚl¬EãbÁ6×¶¼Øœà¹î¦àt`{‹Ì4ªò'´¥LËª&'4Îİ¦üø¸T›µàŸJ¡>Ju¥ZtLh^õ34µDEí2¡rÉ¨XlÚ”±A£+lzT*aø„
c©“"\-ª:¶ƒmÚh-ZÍa!h¹–»·\û÷§/éı‹5ãÌIÏånßèNC/{óM;Â=˜æ"<YÓ1²õ}ŒŞşšìjz› ašıâ¼À"±œ&±N€_±Õÿ%:1Ù×  —ù^cÂ¶PËÏ¢t4®ç3n+@Şf D†7ûaÏ/èOuÁs£+ :pôó§¤V‘Ÿ£¡û€¸çŒuB<”à™µT-ÉK>.ŞìåÙ`Xøp®_´ÅªÿÔ’jè„ja¶áŒsÍØ.!iOcÿ©ãğˆ:uV\ò6Æ+Ånäà!FPW+VKPæ÷cœõ`3;wš1½GÎWH·;¥_3pp–í¾÷— «c+â¢ÏÓAËÊ¦EözRt¤\/Mì.ç?XªÄq>lÓM9t‘›8Ô&¦KÁô;ûáaaÜ"B#àÜÚÓâß—Öİ~——ÔNİ3˜>¼´ÎÚÚ e)ÃªœĞ|´À‘ùš’œhfĞ–+CÏÈ¾ ¼›†	XîÆ&75šM7eÕi÷.şs;…äıı»³øMX;ûE,¯­R%1ÀG\Q±YÌ1ŸZ²9 (7Vû7¿owv‚W•ÑeÈ~(œáÏ:Ë8ï¿Çn¢…–hPÏ'˜æ\ş\Ê^ØI~$ÙÆ@÷9>}Áã–œÚ~áçcNRîÚTEˆ''«¡Gn.¤CX€Z4à—†şã™ÚNú‡ô8ñ+
™.„¦Ø€ë¦Òn©Ò|·x*‡xè¸±Ò³úÔT`Äªû2©‚—iMïì©'¤;
f¦®ŸlµaÍ¤tÛ$6àM¦s{^Îú{]„ƒŞyåÃ\@òbZDäì÷Ñ›õwZâ® ßäï•‡C4’J »|L¸8²GkïxVŞæ|v7	ĞI/2/
J¬bU’Î©*§e<h>ã¨™º:`;D½ş‡OÈB~¼çürHÙäSıf’*#ÂÇâÃ:4ÁŞ ‹_¡éÔ‰•
áhpº£¼‹]¤9>aE;3‰ÄL»ÜWÆèß±ãÉÜN9Wr^ºVÇêç@:!™#‡ép°/W(f„‰@ıÎ¹ÊJRƒ¨'”6ÚdµİInùÅq´¡®‡ö Ï¾*ü=Ç­<şª‚£¥ˆ}j&Ùó¥ŸØ2_K„º5òŒ2×7Ûg×1İu[Õn[êÛßûÜ¼÷±Jf?ì£ïXÅ­WĞ¥î¼~Œ‡[(¾7tRøıÑ6Àæ[·ä’“M­šƒ‹N¸¸¤wÖúºô)õ,Ëïì¾İ‘È5•F_·~:)S²
j~’ÄÔ½¡	qVõ§E«·\Ü¸›-¿7cĞ»F™V3}àa,™Äd¶‡]<à%…””x›¦:`ÿˆëYôôĞ[G İbœ©?–F/¡™Ğğ±Ÿ<–:Z@\ä6»ìÙ.5«è yìx‘UJâpáŸ+Zí$Ó&lª{>•Åè^‹•dÜÚ£­5m(¤Ãµ3Ï˜3‚D•œäÁ`C »¬É"ä]MF·NÕ2CVå%Ú!AÙÅñ ¬÷ˆšÕ<êÖ øCùv¹•ÜBynZ=wÌ6RİK÷×:'ÖYÿåÈ0ğ
Jdæà$v³İ#ÑÖ’ïó€^,âLˆòºâØº[Ë•ÚÜ} Ã~™x#×Ë 5Íy^ à¤3
`M>IQT3}¾rÛû¢ßğö¡áúğøá|·~Æ2J§Û¨aÇ
?°Íîs@6Q[Ä!W²›»äè«@cÉ¤)›‰;âaq†ÿWÔ˜-'%æLïn¸9ñ€“`ÅXJ!Ñì7~_a‘6A*>òë‹Ğ±Ñ êjÅ˜pU=Ts™=#çûf¼¤ ³WĞ	_5n½§£ZÅ6Ä4ŸÜNvEUCÙx|¶7ÅH;ÊĞk¼ãÆ¤×úOÛ,ƒ«¶™‰ûÑ_FšõÎ’UH&]&ŒsÊ¬Ô¤œÂ@Ú¢ûSSx‚ŸÍ(õû‹Ò¹òğÿCŠ	şDu•ıSÂ;zp¸Â<õ„·Ì.ˆãùDCT©ë§™"’ƒ9¯|ucú²ÜÀ~Û¨Î%‚ ¥Ò¶C":õ‰‹ÁäR³í’MœŠIG¶KH rïì%u¯'IfN¶ï&H‡¹C­d^l3ä"õ2¥7I-Õ½YaäoÄ±ÕİX6iJŸÆ28;HùúŒyøÜ)Ù©ÒPÂ`ò…9p?[$\ş÷£®²öğ/ §,‚Ü‚…î­¡xOŒ9–Ö»¨ú^‚äU ã˜¡¶úõfVz¾Î<òµîäìÁ´ÌÉ¬:Ü_ì¾†"àë5zS‘K_\W0Ús(!Æ‘sDãÉ¬Rğ<—¯rÆtCõ~ËÙÿ
/?`yuiØ WQèkØU©İüOZŒs{‹N†‘<‡0!Ÿ¶Ğ4çwlêâDtqj–êr…¶áO#Óğû,f¿¿,“Ş±À,ÎÔbÎîqÔ£I’JÎPÚç„qÅuPÖ{ÈSçíŠ£»Ò#‹¥ÁRíRÿe‘øŠ§Uÿ?½¶üâ©~«÷tlÅ.+à:™³Ñ„Ã&Bå“»ÊIÛÄ­¸©Ã%kÿºédÔ×¶êøÔ#i™!9_ä´ƒ‹@ª-ş:¹ÿ™KÕ•dy3y$—He6¢óF#U¿>Ÿj4¾©û–lŞv-òDÖFQÉäƒÂó8Ù©	W#<H«ü¹³õë†µëÏLDÚ‡ËÁÏXz’ËB?áîRîşyCç¸:RF{Ñ*Äà™—5Ò-‘*ä@ĞIıÒ—×J4–(„+ÌİG¯¾i§k)(Dôx»‡OQŠ|<›­µg3J'‚ûï”Ì^r“F÷4^…bÂ)À-5JS}\%Æ¹=jÍğX¥¢JÊ­<áUJ¿¦ì>›_İME™‚)R—µ.(Èçmˆl+æFAo‹—£î€ÇJ"¡ƒŒÀG&Q¼ˆÁ9P›ãDÇ¤L‡Æ˜!bÅKóĞ¦—ŠÛÈé™¢q}2ıOşikÁ€XËA·%@’‚,(Mç¾
íÙ÷ÁLs@qBœéŞ³yi«,€1ïu—ò~é¼'väæúWm±g»înôœ€78õ²´y¼~äc®·B•-Û$Œ²ŞT³lPä,˜ø›°I7Ãï—BbËW
êrF¹ F¯©¿ Z ®;`1pÃ&mØ—±Í¸K4†<H¡ó*T-Åçn~;[WfÒdì`¾!–L«Â®ÿ â	70äì UÅ%‘&Á±ûTLM‹ş¬¥‚cÛf¼4ZF!n*â©”†-JH&é«V’ê-ÇušÁ&ƒÑÃq¦¹@P÷Ø¦
!V=î’{ş÷F~3Œt¢g|*5èª}©-”tàœMüè9%³}ÄwsX`&ÁlHxIÃ¯¯½?é8­0Âµˆf@UöĞiGöGlPŒûÀmıèií8~à¹˜Ÿó?7	üÏGÿt»Ä„š®Š~â[É%©ãÚL¨M;§&q¸u¸IÉ˜hÕRH ?\”À¿neM¬l=ÁóC	£¡k]…ÌkSµNAJ¡áå°'…Ùş—'
41Lƒ„Ï×ô2í×Ç”å“Pê?AÎgAÕa6h¨ÕØÒÌ¾¦ø}7–¢çØÚo‘kÙzéı;A‰0NÒM‘¬,¯ìå“§ğ~;ì²Ï­³ïı0ûíø|¾ÉoWöÀsA\#‰B0oÅ¬ã~)–Ì¸YR•XŸˆıZª>ì”gèKs«=@,9O‰"¬—éç9¥u4Ê¦0wCÍë«Ğ»ƒF		G]Z_Û¯hıíò63Ú
4“‰‚+ZìNIßáWoò[*GxÌBjÄØ5Ë¹ò=63

°¸«"q¢ÍLrœÇEûòg¹[A¹õéE;ÒEøa"ñé.zlÖ ?·—!`"- ˆ <SŸ°A×HPÄ:mÈ5 -Ï©ŒskªyË¤f3OÜŒàÒ4İç?‚êw5š°Q¸Ú*/Øû¯Ôİ©©ğwV$L.ùÅX#­” Ù–cèÌpVÜ1PÜyú“'ò]
yÁ]ÈA‹m3ZBÏ-zäòc«.Úß}èBQ£ÂÒºjmÌFO!~[tmpà|½êv_ğ9°å+uÑü\+Èi&9.ÓÓWøÊJ©™¼lƒ7¾…&~(;‡k„/yšèë”ÓÁW‘×åFD»†|ö·Ñ¡İ>ŒGH«¯ÖUO£ı<tÃ»‹‡€ctª°X¬iÉ«0-¾rÀpáÒt~ÈLÙÁdø†¬å¸1Å…²ï6r©Tß;÷4®ôHÓ§pÜ9{ÙÉvÓÎ_ Ù›¯}Ò+¶ÌéH¼æl)
aÛYúÉÌqÖNö8‡…°˜=íb£äF)ñeˆ[öY(ÿxÎ6T„¯1X(®áÒ6SÏûÍw˜Ã D‡yfµ+^C•}H×ŠÈ•3b‚×N‚€€ÉÄíêì–½ZÖïÖCišÏ@ÎÇŞDÖX«x3d1íöñR¥9îr;¢ú´Í2©o·ì7ö6“ÖÆ•9gååvâì\èoÖ³rĞ¥âŸğÃd‡5¹½®WA
_eÈ
F‚ˆEôÔ gû~˜üÑ¼´=µÙQåï>YÌ0~;Ìç¥¢”bİ(î4Y¼õŞ"	ÎÁWi2¶¢¨¾ Ş‡øF‚‚ŒØá Z©çÓ•;~(rLˆ¤EGª@˜mãwü¶ù6ò«	¿ÄØÎ5zò+ÊX@*ÍÈ<ªtâ(°’@úvüâxÙNæÒ\0ñe =ö:­ô–Ç†3=À6eÛ>/Ãr¶Rã×ÈcG,õùµû‹óti‘nº)Tğƒõï¾é¢©ÒÈ5É|9vãîôãº$PÙWo…h¼J‚„Ü—ÂóûÂÏ/”/È\ÇB ½~'¿ˆmX(+>,Úz\û€^¬nEš,®nNPæMnŠ¨‡+j6«}M»»8Š‚ $ŠÅm:BoÀ$›3zÃupïo^ŞòÂF\¨ïáw¬*d¨³ŠÁhƒ"à3ìI¥‚°T*e­ ËCûW¿ÿÕÍ§éƒéz EÉºÉq„Ò*âƒÂvRd„ f¿¥Ü'ıs‰ŒwĞXëPºßM¨”V“Š7¯¤kºñÙğĞ:<Iô`v,Ö	ÌùÃ†Ÿd•3e‰ARaÂ-µ¬›tbÇóı™Ë\ŞW Œ\nòÁYÜçÏ)lİ§)¦#eÕ'€hIªp<µÛöFÀ6f
´w€;{,•·vªçÖ,	hj·Ïıp1øu#ô‰õ4éÃ7ÕŒ¨MN+¯#Cˆ!JTh50¡: S®ë·Pè÷Ñ#VM`xë‘¥ 5&R9š û4íHà*™©™ïäŠ{‰)ÒØU˜²™’à}$_èŸí×í¾úäË[ùà¯ØrrZ#êÂœ·yDÕb¹„Ÿ»-²Ù.0æQ‚àwUlÚ3 Ã(Ë˜h?ò1Íâ4uåº>ù°Ñ)‚ÙÿÓ1Öšr3 ±j¤G®‚&[Ö `wö5’ÑÀí%çeT®ÿ$FÃé°”ˆ7ì"$á;ñ%Oò	Òš’D‰-˜Ó‚è¥j9G$IvD^¾şoÖ
 ¦İU&¦Ä¬ı²ıÁä¦´¤´îÕMHC›WÙ6ECë÷àyj8x©²piéÌp4M4rëJœìø—vÆÙ:ÑÚÆ¶®¯¢ë±à~­Ç×pš ˆ¬å¨Ç;µR÷®çÂS¥‡œR–4ßüÊìão‘GÉ¸À &§f/£Ñ}îˆX‹Òº>İC$İ*×‹›Ï¸ä’-™µ¢ö†_R…òÔbÁs°_Ru+©J»ÖxusôOÇ8¨´¤ÔĞW+£q'¼ÎÿWÑbÜÚ‰¹8Qİœ0;Ù2%5Tv
¬vÜ•9ã
‰‡ŠDö!½ãÜPµUM`ùÀHW
ê•©»w¦æmM¬D€ûyAƒ¡‡àµ3yÔ÷­‰'JT¯“ÀkÜW<Yâeş•É…ö²³Q]'ió¦Æü4ôüËŸÍ.ÄKl®tÒ‹>„j!â`ÚkİÛ.Ø¼»’]‡ßháÍG™>?]©få«ğZlMß£Ù]«Z9õbŸà}ŒŞ– ‚îÙŒı³îi‰‰0ûé\/ªªöE›Ó®XÜšĞÏùÈ-t)gÜ3°	åü_¶œ:¦5“²Œ1ÈBœøİ$œÁ6c—„Il€‹ŞÒRrrv¼xô#^­e¼WMJ×(¿u
=gµ¦íïiĞ­`jñ÷#ŞÖ Œx«ˆ³{Ò£N .*øHçäĞNGDáq,;qêo'–.ĞÀ‘²UhùãU¶«àF~ØùÕ_é‚·¶ÿ^”N B¡t4Ùğ¢	:<æ9,¿f›„KíluÖÁ·ñ÷Sçsnr}º3læ-=é½ÿİcàÏÃ|£`Ùı‡ĞŞâIEraWTĞÊğÚâ«ÂÍúËiò|NƒÓŒ(®Ç zoëÛÃ&İ/»YŸ9ü<¥Ë0IhÇ'¶|Kú§ÏsÑÔ63¬…LÜü©ï9ĞŠÇ¢ı–vr½ôœÊœ´FöØ°c£e>6¡K…,¡k¾åhcĞ Lytİ9æ{#Cw½€Ğäc£4Ùsše²â²t•ìÎŞµú·îñ©DVza"3YƒÖtªRPÍÛµğì¸Ø°Ûm¸Fø9:~"`ûøñ_p
Ìj¡Ì‰Ë
8Ë·¥ŒÛK C¯&·	Sã› ÁÿêyÛ§îyMYä4H?S+{Œ9S³™ßßæ*ÎúØ4™}‹¬ğ0xnHÆo«5¨¨\­¼
Z;TUs©£5C%aÛ¨´üp<š5AGp2Ôíƒ{Ï¸klÑÆ¢ôÓ8÷{
h×z²-ìóÉ­b‡áFÚo­kêI{æ»6gÈàjtaìÒ!ú"J9…¾hÆúNq,Í•+ˆ%¨ø’Ÿ«ä<Å•`=ÒCêÎJ$g¼P¹ŸÂ,`ĞzÅÈ?Ø…zt¢ÉbÏBmgçÚŞT%"ÙpÜßƒe?Æó™†šøLåªö³nlSøÑ’#oµ„„±«ÿQ®ºÅi¯„S$¼]> ·À5ó,ÅALŞAm’aU\JCóÙ(ğ¨˜,/œ¸vñAÃ’Èd§œZ¬¦£BÚ&¤‚mäÜg'ìM^ùZ%ÕÚI~r˜AD'Âk*ìqÓ¥e¢«W…šˆ\Ikoz]\·-QÕ—Ôm$]4Z4l†ƒÚÛPDÑbZ–Œ2xR¦´GX;­ÌÓ¬V×ÎejÙ"°ørÿ+ËC7uQ^jhÏˆ·Ğ ìÜ~ûkÇ°zya@#w¼]?éf½ô(f<U¤ì¸úíçÙ*{´»ö¡bîŸIèjû£

ñTXwÎâ+íAr™’h´p6ñ³‰$˜\‘3€*-Sµ3¥‡ûppŠ.yÔ]Úãnaşä¹Ÿüâë•ë€ÔLˆSHr¬ds¼Ó®…LIİšÈt!z˜•àÅ rUª£áœ­f¹¯¼{.\±fkeÎã$à)ãÔ¶VËÌK7Ÿ”<q‘Uè]p$İñk–ÁNgUæM§¡Aà¨ÕÅcWü?UÜŸR×0Ô*¿òÅ3§¯ÕãâuÉûç†Y´ûpš]]lÌx3h:’Šêë —Êo3±‰ö @ÇOğ
ˆí©}Ívñu>wà¦å<YºÿÌœ™d›Af×	‰'h¯
j
~ysµ3ƒu‹SmÆ“mË:â×0æ$¡ı¿çËjÅœ*ˆ=ÍÇ½4©Õ„´W­¶YkúOt
†Å¶¬2ü,Š»v¥å:=g©©‘kàº¢Ñ•á­åÎø>4¼£ÁW××wlkJÜ¸éäê¦~¼ó6öeqáœìÏI§%©ÍÁBp¢Êƒ¿*ãŞáŠ;d	Ÿ#OaÇ¼³×>&p2a/qú`e¼)yŠ,òİLÖv/o:-Fİ2{}c§Ó_#Ú×^% x•^€Ùûô8ÿg
rñA~9…ö§ÈñÃë¯õ"?sÇK„Ù7Ú1jf]k”F`K€Mš>=Eë	ÁW(j8»-tkÁ8Ü-~¦ŞEø°âb¯2e‚újëG²mY‘<ï•Jø]~!4+Y„n²ákÿD ô[IóJfÈª§C”íz§+*Å!J%ˆ>·; '¡p‡ÆCkÖÏe­'¢Ü5R,_C†œ	AˆdV—Xt6}+]fQàsd6ØFkaô˜ÜgÂû–– ²2İ%n‰µ0«å©ÇÀù,Îwsöõ'HšÀ
7èŒ&¾FR|=İ"AÜÿMjrŞ*9 ¨‡šr–Ç­´NV¼Ş›2†C¸„_ÖÅ³¿şbwHíÇ‰[Ì·ß |q;;
Õ¬BŒé)•»*(¿0Å_~DoäRÈj ÅoQX…ÒB1ÉD¹±8%şƒò¢…vâª)åç!ü+EKĞÄµ)Œ·èM›[I)ÕBtO1¶næTÀÍà<ü„Á¿ŒÌ§•Êë”ràÑ‚XS•2mŞ)Ÿ|‘RâAâ.x©¦ÂìEÑJ]Qg¥}tEÿYÒ(«"OğİæJìi€2k‚d´8[û-"”9iN·~cdÃƒE´Ÿ¼1üV
:ìñÂ 5½Ñá÷§d|·SaœŒ‡ı¨Ì—)î…:GTm‡ç–,4v^úígH¬w¦Nv€ú¼×©†£tÜêxÕÓ¥ B-Cæ*À«ÌIıqØÃ¾xøŸ4ÖïúV‡,šf7˜­»nwÓq@Ò	Çi2ÚM×İ‘X‹)ÓÉîp„^V(eÀ
Â|•K£ãŠ}ßù2£“T™>%UW–» +NûQø È£NÔø¨™oÕî›SÛ=¸Z_
Ãñ;B¾T`ò7|hZ–H€µÉŠz4Š»â8¿ÜÔr.cû?jÎ¢î^|²%ÅB¸Iör‡Fa5= !a}?'´„áÍÛ),»(•ä‘1gÏ5.¸\	ZĞSÔÆ‘6Ûš• ZÌ/&§ƒs´²”Fş¦ìÏenÇfoË!yd=º¯2x,<ı4ëjŒ 
Ÿ—‡.L&^Ãwwë ~à–F¸ígÄIÀBc`\Éaåú/%„ï]LüRŠ6?¼ïhPr8HIzîí:¤X§~ª*z}üçÉËŸ	ş8f…¾0¿éƒDiµqœ…â’9Æb4(kc{ˆvõ Q¥ivñ"¡Î–ó¢R6&D¥äNieç(wÍNZÇè¦{FÂÔ3Z…‰ÊŸÄ;Ó—ÒÉ¯UW]AIÄ?d&¿ÜÎ&äíªXığÔÂ™Ãíñ½mgïïscíß4½û	¾qùRï¥Ég`ßW¶Ô„8‚•á¤¨;/¥Éï}E–´(,ĞN{&ˆ/¸G^œwb´ÆwÄ%ÕP]Y¶¼/_xõ.Lò­.Ğÿ€b™âµ´zvôÂ@,Yğ7;”{úr8l§ŞÂ$!5=…ö14¥oa+‘v#­Ü½)Ö¡¸w
WãÕ>  «§õíQgŞÓæP´ 4ä“È³L|1‰w	ìZ> CÁ3ØO"C©Îzy›Õd‹¼ĞTVŸGS®O¥Ìø@Yê©ú	üé«	D©jŸòàşgÆR½Æf¶j˜íNğÏ%ä{kTûÅK£•Ã|›@´Fß	–ó}Œ)E¶\œ“§Üt¸‹1ıŠ°3w˜A)ón5
/‡æs#sÄµ§ÜU3è¯œÇ¡£y1WID>Ÿã’zæ•òDú4˜ÌÉ ‹[*Ö}ô·.ï‘&	Š#¾NŸº)2¡7¥	•ËB·~¯rMÕhU{z_ÚŞ'ÂKĞÍŠ ´ÁˆíMIbzT•UœìsnÀS;`_I„"Pç­Àíˆ$ó‡²ac‚?ÚX?ş2†>stmá"ÂWk]58‹]™À†P½Ü[VSúÅ4Öıš‘³áîå¥ŞÃ™¯:ó¦<eLrö½ÄE™©z½¢3q<b"aø%¸Òı¶Ñ%×©å£n«Sƒ=)¹b¢hJÆcLå™ÂsšU9öjjølı·P\.mı‘w>ŞÀpGnîK<£Nˆ¦;İ„Ó&eŸ³^â-â‚ërS ¬Õä±Ş§M@ ³»eI™äUwüËoW‹aû®}\Ÿ`h®M£·)\ €Q1†JêNø°€ûS$qWÔj à†ÖÓ0)CÌµßı^ ¼Íà‹Ï@+IÁ‹¬?ÊÒ$·ä™´>#¸E R£p4ÉÉ@i—*6¦U,®!'/-!a¤zk\CƒàcPAì©˜¹òE |gd.Rİf÷IÂ–{‡øIÂ²ÇªØCÒ!"gGMo³ñ*)“ˆÙ½ı9v$ÚŒìT´Á›àÑ.J§…œ¤ùE¯>B¶5²,À¾šäêMf7âÏ^9Ö¢As×6Á«šh÷F™«#[öó¹v; ¨M;õª÷|ÏÖfYb§Ta²È«^Wr{³{K"†èuoH´GÔ»Hõ^x»%-Î«øJLôºfÀBdåwj<}{	à#2³£.5&ÚZoG{Bv|ôÏ•™1µM?“Â›iã =ÌíV¢u‡öfl²Ÿ¬3öõ9EÏÆô»l<±p§ãMNÎMæú'ÁÊw
¹H#ï•Œäƒ-ºü šŞÛ1D=g¶áŠ~•¢¸Í¿Şã²ÀøŠšúÆâ­’«{ë£ş¨t@’	úøRÍıi?•v¹¿Ø9Û„mß!Û¾¶À‘,OŞò«E-’®ƒ+ÜòñE†¢¾ÓùŒbCĞØ;m1PYô,xáÒ¼ÿDä\-‚pš½÷ß K¾S£•ŞÉ3¼ƒš¤WğPŞúBŠF3œ‰k u”ïêS•´;4D=—ãä“êîÌ’Qmõü	¾¼Û–*ƒg,‡¨Ú?l)¥Æõ|7şá¦¡3­<+·©iW{6ê/ñáßSšUKìÁc©$j¶oÃ0}f_NACáÊÕglŸŞ‹•hâÁ8RCÆ~JTÔ?çÖJÜéNbĞú80$Í>PÿG¡W«öJ¼jŠíüoC(Ët|"ÏÆÌ]Q%ıráÏJ¤§+‘ÑhÇ7\ÄÃŒb‡¯0Mò'€¸ÄïÒh;¾)ºzmÓÌâ]=ŠGúaö#`ı¦xa¡D–lŒ ogLá—±NA×áNIft€ÄÉJ.K(L•F§V!„eNF)Í{Gqç'eŠX‘á<°€„îŒå  \²ÄÁdY¥úNµgcŒ†×¯gÿ`¨ª×Écöm‡gîFÿ¦ Låg(IU( $¦qm×í:JÇ†Æ¶Xö9ŞòLt2aŞÆö÷*İÍÜ§œs‘ïŞÖÃVı6WÄEÄäìÅçyA¼½µ-ËèŸ/²î™”ÕæâŸ êQ¿Ş$âbtÜísÄHb¬ŞBJ~Yóòo57ºå$%ŒNîˆÀiØ‘$5Lc6d€t`yšvö,.“ëŸ(GqÜ«6aÊD÷4)w²¡õrùv¡Ô “”Ãm`÷€;€ƒõÃ.(æ!)kºÉğªò@Ï´TÀyRÓßMÌTÙÍ­³©|Z–xàğĞ[ç./U
qîsÇ
›2y&¢í)èøº‘©HSÛ¯q·–ló·8DÅaMˆyZğ§Ó¤å0fğ‡áH–iàÍ›±P£©¦<Û•*k<vÅ!cÂi—…,\ÿÓÃ“7öé÷Ş¹ÎÏçyB[Â¬6ænEúù%‹úXzm‘ŸcâÑl8!„B7
0ïà]ş¾% gI0¡V•
”§?ì­½h–}ã\_ß§ê&ï3º]\zlötƒM'38­¤‰ØYóÜ/ø¼ÛG@1”î}†.·¨ŒöüŸ”¾¡³Z
Ûª08>@u±.(&ÛÚ]:ª~I.%Ò@€„E¡IÒWA*çÜLú|˜Ÿ¨¯v¹t‹UjX×Äpß¯¤dz|e`ü[¯ÊĞÓÌò²‚Zlß„Öûª]ö$]zùäöÚÎ”ví&Eš†çŞ7œ÷[vmÕ|bÕ;;ñè²Àİèñ¾IçVC“È9@]¿¶üû²{Ó©5@ÛÆÎ“’:ÄãĞÖJ‰5)ªy2™pQT~ù£ü7t;5³i¬m,ój?úâÆH9‚
<t*ğ‡tWDWğX_£®éÏ.7–´‘TâÜÅ˜M ÖÃ†tsoy>ÎŒò‡fé£3lM½
ô0nß™b'¡bÙG-¬óH¡“ş`áøîPöÏÎÈ}å
/€Åñ7}Şõs©lµÛ*ôíì%J4wQê¯©Ÿ‰Ë:11lÆmuGPi;Ç
€¬ÿ‘¼#;7MêTÉbußª]8Ç<bŞÔpó0ğÅ›(¬…ËC_Ÿ(­lµç?“‰ô+S ”Ö#8Öı­ö†TšˆÂñlS;]²Ö™úò1ykñ€ØIÔ)œ³[id‰%ÑøÿBn‰Cõë 
»İXÌ9;û¸ Sd5	`bëŞQú¢º¡¿¿‹ï–yÔth(Ç§|F‘óÛÆ"ÜÚ¤Š\Ïx¦IùÒ/î{§#É°Yÿà¬8=Eá•ÿ†INU>¯ÚîVvYEÅÙ¡[§È®LÍS¡o-Ì¯lˆ‰ÕNüï†O”s«tà“	C\4H¯ó`³ÒP¯Ëû]Ù¿ÇÙÅ!Å&wkì.tÛ¬„3ú‰×8Ò`ED1™«Èe/+9FÇÍGÌ9ÉoK®E>şÒ¦TZAá'¢FÀôé=¢	Òb(wz¢‹ôc %+ÙÒÉò%ËìUªb!ÚÎáSîŠ~!?®v#W¢0E Šà¢`yC93æšŒË¸Ç|{E~Vœ©ÿ9c1F¦SâK§¡üdÂàñZFy.PC€NÂ5Ô„¡º{±0]a9™{eKÖä3FeYMüLá‹dI‹û©>’ñ„ÑLF€šõˆ¿áƒÛu-GÅ«$§šÊËüá‘(Üm½àE¾½/óR—²”ÇhÀİ…jçÊl·ÎÃR±ˆ}Ø»‡ËbĞbÈ@§ úŒXsáS|TşéŠàŠ¯üõms }Ø1ƒ„üV¢ˆDÇ˜Ï/TÜ“p¾®ÿI,\òµSK¼½ƒ_FîŠG‹Øñ

PË·òh`ù¦´øéì ñ81M4ÔåLê÷Êlğ7$´±ÖŞ-_«`‰ı³o¸mûçÛâ\ïñË={CªöSƒãMDÁ<ƒ ñ€d£*%6ºø5BÒzÎHàpŞ †‹§8ÔĞóê$×œa+¦‘¬“.‘Vk€Ã LVâ%[‡û=Á{:É°GÌAÃAnpaÚ§èÊì`œ"`³.\ƒˆ E>Å½ŞÏóéDñÒ^ô
 üĞY2Íe	Ù:ùÊAÜS¤…;¦ù'OzN¡ˆ©Iù@M"ËtÀÅ[’œé˜°±Ãœæ¢ig€}0h †t OñÖ«x¤À?Cà9‹xğ(åÅ¿z“”Ö­Çz S”ø*ù¿s+vï øsÒGMÒ­êúõ­Â4´•{>@±;£÷}×A‹VèÚÀõW•7›»eíÂÙ>ãı]ğĞ<Oö,üÙÛc«ˆ‚Óê)b3‘ØaûgÚ®ù¸î½wŠÊ7ZãWHÎü<Îˆ±´bhVO¥S­Š¤àË-—~ã¸døF =S56[xá±|¥ûyá7’{€vì‘T<÷*[ÌûWÇ‚õ­†z>`[ğ‰d%Ú{sEb*]YGÔóîOºƒ¬uı^™©Ö±IÍ¯«çZ ¯¥ñ?FºlÃb²™`ßˆÒÎÜ`ü˜eB±_“\¶ŸÊZá¥<1k­vî»™›i¤âÊg†·µ÷.|@&¯ÌFÁº}ËşÎw_Ñ:aÇt*dàì1¢ªš9#…0ÿb¬ÑTšü2œ³– (¦Bû&›KÒ¼BX˜lP=Ö…¢Ì¢ælojñ œ"gŞ'ÎIÖš!$ôáïS$ójF ¢ø»U9Ÿ²/ÔS¾ãú(emêS 1|â?ä˜KùrQeéJ>¢™rŸÌöêÇåÜ^”H´?LrÌ"YÙkì0®ÀÀÓi¯T”€ÃğAş~OJD´NÛJ¾üÖwjf¯O•g$vÉE¹3-t‹c3{‡j¸‘€ğ™2ö×TA®Æ\îr;NBÇê6óL•åƒÛ÷½Ú|}:»‡›úİ„&ö›(ŞÄãß!‰hY2Š[fXĞ$º$ŠeBëHPBÁ3Z;®üIë‰³a¯\í$BÇBsœW€Ò™ÚfwÖÒ+Ú-µãß= #Õl÷2½+':3µë ‡æeÈã2 û0Ì4vé©?&­l½|é·ÀrØqf*fÃ>9õ67g—±?6Û¦a6uxOâºât-ºK+BÖ0WÛHTo`Xòä£â9€n†p»K„òLİ&R"m’…Œädóü¾œRÃëàSCÇ¹æªÇ’r^º“¶\w(şC
W’ªÈVZåt³…gÜİzåØ^1ÿSv"Õ6ƒIZBş„´0uMõiFŞ{ã>Ô$\û½şÆTëÃµÎ­ïx4³ƒÔ’@²¡™îÓ.—9‘ì&<›¡eúŞµH›»B÷ÃU^À¤K_âGDÉGÄsdJ0T9kiTyôD’iqôÎkåØ®ÁÀù	';tÒ|óşsãöº	;gÜ~³Ëãí’‡Ö„—•h¼|øÊò±Ç)0z·p]ìoí<zÔòbiŸ’O"j×Šø4”kİMF„½ã;>,;J×Ä…şßB
şÅÈ­5àE0E8üù§Ü’ÂºóŸ9=HOs‰TkfSæñì‚á2úÏ~Í]M™YÃ+`J‚N‰Ô^MÀw¯ K­	ñ sŞÿS¶­÷zI+” gaĞ8xĞ½¾q±FÇìEéqíºLHÑ¨'©–y«	èaï7ÊÒ’¢¬/ÎuÁ V2«møıy6ÑY .‡'^^R¾r¥B\	=Ffz$ñ–È[“"èİ™üö±áàí³¢á\à¡B™‹÷Æ<ì—ú_º-[üQ±O…’³ÉtoªN1ş²}Ù0T¸¬?…,ñ´i
-}ƒ°ØK±½°I°Ÿ2´W¯]¢Š:RX^Bâr|#/k‚´q56ö"]èÛXu5·&ùº¦¯îw>-	i<Ñİ]—SQ.wÊ©¨mZÊĞ)@¸ÜµæJÕ—¶”iN1óKf*ÇÒ¶)³sk(X^ñğ<°~„¾[€Ñ÷‡"Œ2-0H ¿IâóÍÕlŠzŒv)·1iîoV¶€.Gòc±
ƒó% :²ØşY¬éÇ«É?ÈÚWs¾Q§æ”2}øãJ&{´p |ÕBîqLÅuğwY¬n$°zh.»³2]Uñ·¾rŞŠg©yz´˜
‹–Ñò ¿#<Õ“IÇ#Mm}Ç]ÂÈ$òÓÚ×Ğƒ†‚²P—Xêğd9Â o±¯ÎÎm:ºéİùOq¬è¸&llª‘¯ ¯…]ÕVï›>d@¥1g»ÂB-^ÛÁı6n¢oY7™\ ïÉWzn_Æeï%+­QËXúXµ‘€/usålîÜ£#DÄÁAa­¬
<‰hÀ®˜>¬Ÿ;ÜÉ0MY…m1¢˜†ßä\©¼ˆ,dÂûÿ“M±Z&u1Œ„VÙÅ(¦\ü*8“–Ì—P•DÅÀòf¨F·›¿“(ƒ~» ŒÃ°¾ViTgğùİ°>Ûı¸wâVsmúİØJ:–
ª¢{‰Îpã}ZD2ëíF-°òë»À5‹í»w©\ùqW9÷½“Ãÿ*¦^ëëßav		Ê×ñœÂÇótë/t5×?CsóĞ¾ĞÅ‰şCoÖy%wˆÓ£ÊDeşU5"wˆËş8T¡Z<éˆMHè`#	ú+ÃfÖñ³Azøµ´y”È‘\.Ìâ[-Š@È¯‰WMÉëô‰œxšT:Â b”ì‚öV²ëW6Kœ'° Ñ‘+^xŒ¶ÿ.a:ÃgEu0½Îb¡‚~ò¯– …=fúĞ4Ïº›¾J?3XŞô™;•¾ÌŠ4<Ë¼"3º<ë‹Œ¯°‹W˜ıme\Yñ36gØÚÂ’8¤»Á¶V¯9W–öMÑƒWÇpÚíÓ…f=üÂAŠVÊ™²¼!†;*Ù
Ù9Ì‚w¬©M5×„¸)ÓÚho‡²ÜCe˜î,Ë EÊˆ«|ÎªÄp©µÈ0±÷ÿQ®ï–dÜ¦mİâ.¿¯MËbå\Qy£C^Üg”+Íì×£Ø$é·³,÷+ş©7—ksKüˆW,š5ÄæA¶æâÂvkHMqòÙKwÒ97c`A«Şç˜­{z§­K>™âGYch»«@.gêHôu=$Z´ÿüƒÕDWkÅÊÑ­ÍéñUj)VÕÉì´ö„&»€ˆjÿ›EO©–N‰z´kö’[—ò€x«9Î§ë¢%†&“úñÜÁ8?ò—4\_°]}œ,X¡#}v
öò@`õ¸—=q‰ùK˜û§ Œ+.høëŒ-wP»‚ö/I¾ihŠyRZR%Óš	nŸO°baMÏÈ÷ıZ>=Y¢óÄKŒ¬òC
3/WvrP¶Tæóx¦€˜lóãtfï03Œ€3†ÜÀy’^9.Ï‡ßgœhFİQj‹ÎxÒD*N8„Ş}3M˜„û­nx!ûq¾WÛ‰ÁükÀ÷WÁ}gˆÒ<3îàø"eBùHÜ	îŞ6‚†xÒ—÷ÖbYq!­ïóEµ	=U'HgÉ’TgĞdhŞh¼W.$=D_†ñÃPöB”·‘~ãfUİ.(Ntc¤Új´‡”KÔæ ÅÊ²é\ÓŸÎû»ÅÚ^³àlú »§âÆğ ÍƒÍv$&m“f·RÚ2q“Û8XFÆ¨ôz©Ùš4ü°‹‡ÖCnÆñTÙÆ©!½`ö¼LBĞ<úŸ²ğNß»(çˆß³Ğ?ª‹7ªOÆ–€P®ßwn ŸC}~MR™®äÉê™Àzâ7ÎcæXŠ«9éUë°ĞÖ|Øº¸-Ì:pY|‹Hœäâ]ˆ,(´ÒmJsè%°„ À©j˜âŒfâµÈÃ<Ó¬
 -¤^Øcï#xSTTŞ£‘Áşı}Âúv½‡ïŒ “‰J">ä^‡èu)MÒïÛ8¤+B@U+s|4ˆ'â=©l¼iJf¨ƒæÓ%ÊzÍY¾ñ¬‹9Evq±ü³U¿ş•»µ>‚âÄqïË™¥O²xOi’Ñ™ˆçjÒ/¦/‹#NèÔ(Åc;{Ê¿Aæe«şÄªz%yŸ’û½¶	„©â;=©=ïEÄ|Rô¯P|úDŞëGŒàRÛjL{AˆwBr¸ÏÕ;îôMLÆo\g€óm·°4AïË‡¸=Q
ß'–A×–~"I@x‚°‚Â ÑÙÇv;×ÙÜr2º¬×_µˆ+Á…•‰¦×’âF3 _±jØh§Õ	‚èQˆš
³ÃıìóÓäâVI"µ¥„"[ëjGW¸wKá[cu±T˜Î˜ÆR'9;„¼œˆêµktxùi:y€ÜÕ]ñ«w}³“9®’kƒJ¼…»èq°øŸV_Û£ò°ëãñ“Ï“ÔQ ƒ9!¶H*ş…Í_vNod¸×gæŒóá[Ëå¤fQ*¼+– Å;D»–qk+` †õ&mÚ¹÷ØLhÕãrÜ \! ÒPû¶IíÒ¢]p—¯@÷öÔÂ&5·“ş?„½ĞÅ%Íßæ©tŠ»åÆ÷lo9´I´ÀGáº¹©Az‹z”#ğ©GÅñ?ğFåS„4;a*’Ák,¾:a¡‡ÆİÎpÔqæ#;/A²tVñ0Ìåw—~>s -ÓóFÛ¹°Ÿ‹–Î-ñØ½Ú´”1ÿ·¶N¸{kŸˆ˜±c¡h÷jrÙÿé~·f-‘×j¥ÔX!£ı¨I¯\a7ë°M^êEàGUpwtGçxç†¦¾„¢ÆL”
ø‚LÕÎ«*ŒIa œ–¼)Ü¹MîfE™á½ä{û.Ú|uÔ÷LLo»
bú«rV(¹€ÊÁ„ËWGI-á‰o3ôh'¡ˆËõ%«køìŸëAà>~V¤Æ™ä+RíğePŞj(´s¬âŠ„«™ˆlb_FÏ@,•èÏñÑBÊW<Æk²¸}*¨–O©XÊ`1cáCé¡ë}-X£§Ø<êb°ğEe[·ë¤ğ@½†¤2ÃC u0˜q¹‡E0lrkÙIáKmµJ¬«çÌX*o—2~Fú´©‹bì¿÷íMs¼ç’M˜Œö+´-,*2,›<&ãíî_D&€–›ÅÃfQ²ÂÙµCD }êõ^Ş\²QßÙo Äy¸’ÂÅ¢"¸ejS[«”sµ•«Â§¶ ‘*x†Ä_ÆÀ„Vz`‰Î@,à-É¤@¤pµø<Ğ¢V".îº‚åJ’˜Üÿ)â„#&òåëR~x§ï÷,MÄõu€¯5\ô8;iïAü¾ ÏÚªşœõT¢î˜è²ĞX<
Õ|›¿u¥B4¦¢ )ÛI+Ùİ‚íù¡ Bc1©‰•Xº¶ß:‰G²€ö<­l«}°È]ô&©ß"Ğ3h¯<\Ë2”R^2u`iôßz½1pdDÔ»‘dC‚+Š}¯eŞmœ_ä¿OöN^iu	!ƒ*œAè;U±Û:6°±…"‚qƒÄ|Äúõïís•»½¦–C×ˆú’îºØÎ·æÛ4„Êå*/¾¹Z¾KtÆ©}ƒØI÷%°íÚSYP{‹Šºˆù!’ştğ„ºbXÌğRy ;Ğˆ©îc ïØ¥ş$Ê0İ‰©[¿7LûmSÎç<#À/|ìlPYoÙ¡Z†^c¹3-¡wQ?2^ç«JœŸ£¤/â­g^ó-÷å¶Ç–¤n1ıäI.Y ÒWı }æhıëà†upåîé¦ÛDÛ’ôšiâSm’çcQ<á­Õ™£p¯H‰ºnè!©å®fˆ&ĞG¬ú©‚)Ææ¸Rÿä}bĞçN¸&VÓêèÚ}x=—ÃX¡sí‘<£hĞ tWµ
ÏÎ‹±€”µ,	»ÏÏÊ÷¼Ã|&Hñ\cM>ßıvÚÜMªHùä@‚@¢ ©éZ2¬e{|#ğÏ-º?4d,s²\oO‘ùr¡Œ“Z¡WÆ8Ú+³¿ïÓ–XÔË*3·ßF¹ÛÀ'ŸïAp¾NB”—X™e†"$½â·]J¸G5«üšƒèJøÀCzJgÁì›Œ$i·S½	WÈ'(“X|ß‰EïˆìğÇ?Yyè/XOhøö6U];"‹›5~˜–LÿãæJ¤n²‹“$…¤‘BËkš3õÑDÖNwŸ¥zg×Ôô†6–ÉÅ£d]`KÙO+ÔÑ‘6äˆ‡E8:||4~jJágôüúÓ$ïsàĞ…´ü~õ²„µád1È
¸·2oE£¯™š¥Ğ8=Î·š#˜ç*€!ùÇM­$–r`™jFV–³ê±ÛÊı-[Z¡‰»d®pM˜nC„¼zß7È`€Ş|îùü˜r×va‚¥ãİ}¹Æö=Xî?ãÀvm­Ì“İmÅl ·c9xËP}]'ÅI5€³mÃ‘yïÙL^ÿ¦ )ŸmoİÉù&1v_®>[QªfšSÑğùm´Ö?š1³c4u»÷`¥;m˜”ç^€¦ ´+ÊÏé?şò™ºë>•êÀ&w(n‡/<Ø[	z÷6ä
öÓ]àbÖ¼R6ôYëğ†§ù…a5¨E hĞÒg?$oq‚ç®·KaxsVÙZlÌÚúbv'j^èù­fş³&şîcáòåçºz¡+˜³WÅ1HùÉ3É/M´½8^³e.²c 0.-'+x›!ÚÊ‹YDTıÙı×‘|';Yßˆ~Å&²¶Šµñ{>2™sjÆ”ö?[tñœhxSÁù³Öm¡N´‹#¾ÅqtbÑåæÎC{Ü<D…$ÃüŠ|s»[8¢^w¦fJÏp™Ã‚¢'Å™@ŠÕ¹ÉÛQßĞš0m	Æ÷•eŒ”½&S¨.ê!â{|•‚y@.´¶İ0±ÿoS‹
Ö+:©}Y†töc8Íßİ`N&Rqîıª†ú}M…[Mø(#ú_§-R°´63bLËÌn²õ;ÑšTh§Ô‚÷õÎ‘zµ¯HdÑ_Û.„ƒ—¯½§37~’)ŠsxsÖ– ©ÿLá‡_¨Ğø”…z^p)z‰`ó¿ë}HÔmÅm¬±Ù¡5ÿ‰¨í]ÁPrb˜ªCGÒ2`sÙ!P6EmúÜrÜ ²êN9eUbåm}Ìû1†GÇ¾ëâÀQù€´ƒ…5ª²}ùQõ¬ïˆñËµ{†UÜ3òà·©`üáƒÿF¸¯óoïèÜøš¾O¨•Še'Å×qÔ7Ğµfô²@IˆSP`!ê@Z"½aƒ¨ë£w\„œé+,]ä<|X®zQè“”~¼òÓô)5Õ‹ûĞ)¸Û^îoŸ‚0ƒÑ©ÇÛ(OôÒgh²¤(MÆê­<2uãúæ*JcÑ+Êl',¿+¡½ÑijªüFØšÏIø]¯2e™øDÉ5ó—ÇÅ×ÅÍR°wéÏi·•YCğf¹XG}ğT ½™Ro›®Üg!õlDÎ'Dfğª…Ïîºg¦`ÀÈ“İ­âD™Y yxÈİZÀÓPñ™‰€Îy=$J›¼PëDN”#Ò’qé$ÚÊçl ™ö•zSÔê7q2¥NmJ¥`„Æ¾Á—ÈÏÉuôó>%ÉøÆq«bL+ÇgëPh6Ö~Ï]w:×Ğs£;€Û—–=¢ÀDåœ<?†ë&3˜Ÿğa& ˜S9šf¾#l8µìğKÁ$’h Íd£+²Ô•Èæ¤aQ“¿Ÿ£åQ<<µUƒ1v¾x!G9°$;XÑ²`Zl+iÏÜØ€Ä kÃNÄö1§'²AoK*¸^Í~i,Ş¹8ä›ßA0a‹¯×dª9·˜±[q4¼$&VrYŸW#…m¼ĞVöŞ	m˜4£±Kãî;o>‹Îé*u@˜íœ¦Íkõ¤›"Ê.|mYk¡Û&"§©×sIÜºÔœ=g¼ŞÁ¸ó™ó•Ì*‡¡¼%6Ò‚=¦¤’Âe©ø‘‡‚¿Vº1t²ìÈèÌÓ”0Sè~ğm¤æ]úåDÅÉğºçÚ%
{2Õ#-cJíîl²ãjù~b;È<Üç|C’ñsà¦<³Iz:[Ö’#“£5F(Ï YÄNjÖ”8[P<¿Ò'>r!+5ÆƒLîÕı?uïñø´ÍA/šë0†F;ùÄ!]¬!¬öh¥"ıäƒB0/ÄÀûòÑt‚×h
[käI#‚·ª"èÏ(ê’@u?ÅléÂ_«Yş-".)Y'fˆéRïFÇøÛbçòÏ<QàsıdûÑ!Œ«€^`”å™òÓ T‘té°èÁñ%éºÆH€çn¿²tMïìùW”J¾ö1 ³5èŸË`Š¥› ­AÜc·ƒì‹]%H0¬¿¼-®-ğG‘œD$¤Rv úæïV„5-™+HI`ÜTåz)€g"‹Ô%ñ~ìh8è"‰X,SÈQî÷ã•Ôµä€Y”â¢r˜îTcÔ¶üNõÒ£ğ}L€)µk–¡4î¹³å
Ô–›cİÖéa*¥†!§Àî="*_.Œêk{`²Ä²4üüí¿Œxáo†“ĞCB_m&¹`ùÏ¬,«ÈGsV?õİ*u¯¥lÏ’ªÓ"Î-³TˆT*èƒ 4‚]¿éˆß%IÅµ°øìïågúMÏõ»
IAeš°PVOu©©gBƒì˜å´³&Ô
8ënTñ·¤PÇAÄíŸ1Ho†+Õf‹%ıÃ­ƒÀŞUæ)}0•7;á8'´tÒ 
àmkıæj"÷á¥d¨¢®şD¹ù–íĞÏ§¡}IkmŒífï‚{èÕ»‡{wõ8µÎZa|veöQü`_K›HQ4jOàGÑâÉlbp"‚Ã†4ˆĞèÁYl½´ÇØGäÌxX¯­%f¾åWdÈóİtPš³oX?NGV:ËƒĞíí¼Ï×M›²ºùÓúƒ¢–·µªì?ÎY·ªº†fä%êWƒ*/é†-»š˜å5mCÍi¨.×©YS©6 °­½ãWÑ^Û(‰éCŠkã©+wº"pZsÆ±Ìgñ¯bÆ‡ù‰#>4d²Èã”m·;†qÄ)­° BÓ‰pĞ¿nŒ¼cà^æ‰Š.D4Gõş+c‘†©M~Ïï2;÷çB„UÈÎ;?Ñkõb‚BÀÙ§ş>Q¾ÉĞ¥Sn±äe0F?a9íÌeujW	×MJÙ;ƒ±zn6¯ÔÀ4]ñ‰+Kğ-DóbY2È&5Ì
eI»™‡ô¡úJ'?¼Å8q»5*zåÌàµ-¬%ÊÉMT³<qA^W5!]’ƒ_
LKA?Ö1şXçöû…¸ÚkÛ8ÈIáô §q€´ö(8h²eYå?Š7íFH¤ÈARèXşĞG°j’'c~€çŞÁQ[¸Ìy«Ö iÖõbM÷ej<d.-PLu#	ŞnÍ7^HêÕĞ5Èû9ç±Òeˆâ4w”aÔpÂ0eoáj8à?ƒ(w rÑP¸°âòrG3%"uÇX´XİşëÔ4Na^r‘¢‚©'3€•WĞ`ÑÈ.Ì§ˆuF{Qÿ’	œ-Ô…Y—¯‚û–Ôå~<j0ÇBLı­¤7Úz`øî¡IËvf¢LÜ†gî¢}G4…ÉÁDü½À(¸h+‘lÜs2ÿ_Â&ë#Éû4|ô„=d†x™zÒM¯õú½‚_=LõnjÌ8B½‚ìY=}1Y5ç¥‚±ñCŒäØ6§¶ü€3ğ8wÈ¼Ôô!«>JhQ…Xºu.ã&¸mIU©ŸÇi›kÂB|¡öñèÄïË”§wüz»÷¨’»Š±^‰yĞPâ$(fî&â8ÊÜ[Äu>­M\
âfO$·ŒÆ¶	9%…/Zb;¬a*‚Êt_å;ğl%´ûh×‰.qAèLƒµ,Z/mô
…ÄøqQÖ™MôÜl¡ì¿ÆÈÌß\ZÎ¤7õ˜#bÒ:ğBD‰æP¯œÙˆ—§§ûÇPëÉôDd‹7¦ùoá. ieSb<ŠdûÎÓ7?À~ ÚÛ†á&Q¢4D®Õã|Áiø;Hæs"Æ3œ=¼e/ûÊÉÛ‡3Õ‹o;"*zhlô0îoş¡ô¿UÊ4^‰a)ŒïH,eæN:$œÖ»	Âbı+„+Ûj¦l†Ü§ä\†1ãDÇE[÷{Xö‘æÕ/ ’v üé¿Xt£+v#<J¾¹º­–V ½È@–ì-{«£™¾ÖüõV±îd_Á®:*_Åøôºä"œUĞ¬Ğÿpv^¡$Ê…FiÜûÎ¥nÔZ¾‹á€M2Àzªá ¢ù<BcP]Lu%d™·÷.İ¢·N»±C­¤)Aò«¹niıı5â²	d’a	'–§QŸ¬„¹û¸ Í:wŒ®pR±#s·2¾<–k¹«.ïÈP=Ìì~2q÷$¦äY„‘•}%µşñ—4ƒjŸ!c÷Q/QqŞš”ú<Kùm¶­¨±O]¸@*0¤p¤—ã*1
¬éÀ[´ÊPÉ0ä!¶ã3ç"¨ï>BhvKÔzYøF{©yı ä±‰õı¦‚NÃMÉÂ™ÖL1Ï[b¨­µGa\¬Œ5Y1”úål$ç"æ}CGîGöa2d	¥Ì‰ªõSU†Ù\¼¬¹
ş†óõ¹òĞè`kıŸ­HÆvdÄş3#©‘½úm'‚b 1 BßkÖ˜ê!]’?ˆër'š	2¼)L	Ê2Mkæ¡¦Ç#zd÷1=İ1è÷}9ò+ºp¼ªL‹‘1R;°„!km&dŞSÊIë%ZVÀ¯wv°üß a¾ÂøÉÕ“®¬Œëi§‡cRîê±ÿB¢rŒéöY—	’|c79i¢ywFŞs3*ü@#y‹x†Iôã°'¹x#‹èı²)og+Ëº´„îJ«UÀ‹ş`'ZùÔÃ>Ê*ã2@j-<@ëÕ´±‰+¬âl¸¦É˜ÜµN?üWôµd)¦Ûeè«üÜy"2&CócÄËša#ø¥‡¨±$;˜¢8.ÑI.¼¸“Ä>%Ã ünĞvö:–ÇĞ¦±æåCÿÎ$nL‹h>çÔ,JjÙòÕWÙá^$FRØux,½°Ç#)•–q¤]¹¡1îüíË_t'LŒÄ­"øğ%¥k?jĞñT ])
5Š³ 'hUo,VQØ¥$;VÊ5ÌÛ·âê0úon”¡Ó§I‹ÃË=%±!®l2ñNk—í¶ú%€+=%ô›HŠàw8¼¸²ú,‰Šê¦ˆÎwÇˆëH€Î´`_¸ØWŸøÍŒ{”zşr?…Ì>tNn“Ö±tA9êx‡¸sÍ0†úa¡Nø»À#¤šº¯A.ü5\S.3SiªêñÆ;òŠEW%}ó÷¨’!§v:cßŞK‚Ó¡¢¢uÉ¨ØÛ<µ/$1CŒógšq-Å×p?¬“]ÆK›å ¬VÀ¯äÒ|mé§Üàú~‹õü¸÷Uü¹féEr×åÖ2ÑIB95FGAJ¿öÓç/sâ…Ê	D¨nÓ%kj3E…µA¦±×~––íÑâûˆ\ª®¶ùq²dæXH2ºóZ¥2“×\ÊY…i{f¨ÍR®Õ;_H®E©YäÅlº‹¤aÒTiæ¥VU—ËÇ¤5>;WLf˜ˆÅó{B+8*1+¨?¹ €kH Êl¡b*'»Å›ée|"§gKˆ×˜èt<ò±¹5ö+¸ü,bZ6SÚhğ„÷!˜à’şûñ´åIùÈâ¨¹áşXU\j;øj«‚ÓÂärN£e°sgëÍjÖ9šJû³¾7ª’í=oñ©}P!	#é¡Œô.5UÚÃ“j¥AU}4€T¿ MOR÷ŠnZ@‡ğÒ ÃŒ $,ïIC?=&ŸdcÜ'Ü#g¨TÅ²‡<kùÑ†€QFoÒa /G TNLCodˆænîîøF–ŒnúÆK¥7>ÉT‡ÎP¨Ôƒù ˜õ%hëí´İB·g©–*2AaŸÁ(„å_øi/a«_²M‚>U)¿@e`[] oc÷­íkÇ—”½ohxñœŞ œ¢sT»¨#‰XÀÉî5¶w‹]–Ö<Ô$ Q3M¡Ÿºgv:šØg”‘,x80ÿëˆmËÊÙ¥líñØİ1–ë4ØÈ×ç^–Jí!)ÿÑ™¸¥§y‹ğ[Bª…«°^Í±Ò³2Ú~®Â3ëÍëkr¼e/í½aåE¶î@„?&ÇCKÖØ@×•d@‡ñ—áµí)éT:ä§v×Êiñ‘P±ç_H÷èû(tKyh¨I(„ü3Qnér…Ñì5”<n1ŠE<îEÌÉäÔßJ,æHã2…óÿÛJ4İ®^<†OB«Q\GçÏkÃ²gñ—7äY·£•<2á)°KêpbÕû°²~Ù>icøGD²µ8q9.Këğ¥©ÇÕßìÉè™}uïÊ…èWü5N0!òÖôK(I+4<yÜí¾U¤d\é!«3Ü±òÑÁ$ú¨ß®=4{MÂP¹INbŠÚÉâÜ¶€è$óÜ²ë)CãO—Ì>Àpcô¡\¿NqÆğ`%íå£×nV9ñ>uW¨ËñÄá®Ø(GƒõJj¦ı8•7¬à´¹c´%;Iıu±ÊÑ!‰5ÿ[Nğ†t7rìCA¾zÅ9S¬ÊİS[‹u9fi³†¶¹û0‚\;\W9Iü·%AëvÂ©ïÅ3®ŞsôRl [È”²·‰+ŠÀ^¦mH
„A_ ÿ!%RÏ 5{Ûì7-¸	÷¤¶Kça"-R +÷ lZóŠ1ëµTv7¾QùoÂ†f]§¨`4C“vÉgòÛø–(Ú«ÀRúKeGtPÈª’° Xp9DEqÉİ'5‡…R—i„İ/^,öèb  tÊŠ# ôÃ“_g@¼êF )EŞò?ïšÁÆS©õ;äÃcJU)@Næ:Ä7”Ml)ÎÄÜò„½A¼°v1ÁßLĞ'°x°¯Át¼6ú¥`ÜRòíí+ÖcÃqŒ(q¾3|`$2µŞúX•bŠtfÆlO!İû´šA¬¬ÅVr…–˜AVø®‹Ufşw­ÕÎ¢•—WÜ÷TB8Â&|÷ñÅ¢€${ZóÀWAı~ûM×·ÄÿÇµì>Í HÎŒ2á8´W„îÎâÁÍŒOV8^G)ûÚGuFò_¢xhJÏ«É/5Áušl £”ûnRåVÕ™ÎĞ¨ñeİ º+ÚU³Nlç3Ô…Æµ,¦*	N¤ê—;­Âİ7O-ğ©@Ÿ¥2Ëõ¾+ËAoÃƒ&„¿Ä	€]¨µìü
ZÆ°¬›7Øde×¨%Yƒ(0ÄSÍ;—ƒÍ¼±•ôzuäX1ºĞZ#?½Ÿ@ÈQ~Ú÷´û*<šÍæ²ú¢ôVH†ÿT™õ")›ô»¸ª¨M:"èzD—_ÈÀ¾–ÙE¡ 6ğË?èã}ÚsÎ!}¶m#o[İk~à{ÍŸŸQõ”‡Æ0’~lkşÄ’ÙkšÌæêËNâ¥Ébêe€ÎFZºo±ÌH†¤Ô¼š[ì¦²2?AÙóÉIFjöÓc ı{—ÍZja¥­ôÛÙÛ%ô¨J$%Š(Rõ™ìßhdz®ùŠÎçÚ¢òïlN=›<âˆ\,Uâ2­=šŸŞçfôÑÓc;YÓ<w6/ó1@_qè£ Í={¸ˆì¡Ìµ"3îˆ ‡©8˜«y´O=<Z‘ÍÆ
i¡Š”¨˜Ã™9•v;™PÁ\\ıbuñï\s,òŞ @tl']ÆŠG3â>ø\A˜~¸†åÚC<u–ÆÆıb÷TŸåêGÂñ~ØCwoâº]šòNw,ÆÒW“K+"J»Ç[9µQ|‚òØ¯lş|Œ(Ì²ù©øA£jÂ‰Œ^†´u±Æ^uc(8w/Hµ_ê€·’¢-“Á4g”'Î,ûİÖs¨V-|i‹™ÏÓÃC>ælQOï5®,èÀ(»(ƒ´÷]ä.÷qÛòƒsåChwš¸<†Éz‡²bßÉ.àÿPáb®tè+zØŒn$²Yîä‰ŞRpÜï –øçlŞ‰ÏHõù×>¾M,Ë„z€ÿ(ı²‡Öl°¬ˆOVÌ´ÈpE"8ß¢L«Æ¢N§Íõ¯›Ã¢±î³”šQÊÕR„K¶ŠïSŞ7°1JÜÇ¹(Ö[&Öu‹4€'hG…áhi”¨Ú§;Ù)'ğ~%ò`¦òå ÙkŞí½J<è8(}±2¨ÔsAP Åu«r/]>ÀYd±U”ØıéÄT‘è:iŞú8—mîRZÈEÍd I_îevÚWjõ@,+(*¯âe{’'ºV·£Çãàßj@|	"ÌHv&ş']gÖFcA!yZc´’é#²&îÍL;ÍÆÌdU÷&•Ïµíb<öZõÌ>]WnÏiÓfÊ5€w5WäÔ#×·5ÀÓ©¤Q“j¤N}5É`»0r9vsBâ-­¾°ÜÅ˜>¯I+zÕœN¨L<Ò1ÀÁËæ† Æ>¯C>îÄŸ6C%ÙÿÓò¿ò#†d÷¨0ú;ºgó®ûæ,ßàslJ‡®²zl,ƒÕQËeK^æ‰s’0‡ëjÓ·Ãe¢i6„éTöGL’&D:¥>„¥ëá¢E×†/â­Y>À1§ĞQ$Ó@T†INMTÔ*{¡dzYk8	+wBãEÔãÈõD/Ûòùÿ‚uƒÖSşÛaxSÎ }}ÊMí{¨X  ƒ§9É”¯†”ƒö…FÏ&ÎV§ü©âš‹·Ra
g#G‡ÌofûdLEõgğ-ÄS*y¢ÃYAe%‘N–ÍêS §3Œ
–ÒRcô#€ï%[şCúZØBZM˜ÿXö—y'ø-a„î©Ä»µõê!¶@~„ÿğR>{èBJ8Î+Nİï°@µ
à¢-9®<e“ı"3á{²g¸Áè¦E8š2¨)Ä·÷¹êÆÁT ÇÑN[AI©Şğù3¥ŠÌÔ°|(ÜÍÑpœ¡“ë˜´%d²»z¦³áé¯µM=z;+<ÑÔJĞ³Ú½üØy.Ï¥Á2
Ë@iĞÓÏDWgâ—®kÍAŸÈ¾uåq¤cıµÙÓ[š`‚ÎêFš#®†ëO<¢pÉÖ7{*”²
     ÄnzXñÜ¾ ©¸€À&éæÑ±Ägû    YZ