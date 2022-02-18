#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="474319272"
MD5="0c50bc114f19b517b4aa3db668c6487a"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="26572"
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
	echo Uncompressed size: 160 KB
	echo Compression: xz
	echo Date of packaging: Fri Feb 18 03:31:26 -03 2022
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
	echo OLDUSIZE=160
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
	MS_Printf "About to extract 160 KB in $tmpdir ... Proceed ? [Y/n] "
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
        if test "$leftspace" -lt 160; then
            echo
            echo "Not enough space left in "`dirname $tmpdir`" ($leftspace KB) to decompress $0 (160 KB)" >&2
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
ı7zXZ  æÖ´F !   ÏXÌâÿgŒ] ¼}•À1Dd]‡Á›PætİDø‡åqÙ6JR%…“Üíß?…–jJüQÈ­Íx!ó7ÖàXÒB.M>Iå># Ğ‚À[æ(Aâ=[${İˆÙvĞ¢9¥tAŸÑì‡‡ x]85Ğ‚]=
ğÀ£í~Â/XW¬­İœ6~Ê“è´Wƒ€ä˜“ïPFD8+DNì1™ÿ;¦ŒT	ägfßR£hHÓEßªi;KG¶âÍ@²›âãØÅ=®é‚öƒ:\¾¢1ÎÆGdj:…S‘OAm)“ŸV¢§†45C·•"jÂª¦ l²Ï”MÏé¾<ÊSº½ìÕ¯FÍn¨Ô­L(ıà=;(Ètä¶•ÿ·bp–hİ2áÏø ³Q®ºG&‰ñg'D<>mE£è^û7óE8Ú®€Lã…9_+ L‡Å>×ñ\Øå]Ää3+Æk°”¹•ÚÒ}Æç (€¸¯àL;Ì¦Ãå*Y-5í¶W}šÌÒ¬O«‘Yk_‹ÅnF(®œ!Rá>aTÕ¹‰‘dXå½BÙA3%St”uj'}è™Î</
:‹ÇÌoY‚Z£î¢S] "   èèlÖÓêïÁOmA+ñì‡ ö¥ûÒwÖ)Ø?:4ğp3|€BfİiãË™Xƒ5æ!+KĞu'ôß„˜¡á>Ù¯bˆ!p'}PvË¢lñ.›ÄqúátyêåÂNÆYizã°ò:Q—WÜ!5><WÚ8OÚ»Ï—oÇ¢gÁaP:Ì‘(É“>Üı“6‚›r™5TÍY³;Ùº"e}t^Ô:3îï š[[±x”U:Â ¤Åñfpd …¨/¿Ú;øìéÒ¥§ƒÕ;ŸZC\»›]CŠ/yJŸ+é‘Ñë‹×2…j«Ò®­¯‚ÔÉıï4|—©úM'ëŠÙKšfv¸À,‡õøaSg3´XUnN½f‚uO)£Qç‡jë&¬@àêƒh»¹<Iâ$àÜµ4ÕÑ±KÓO"ò”×˜¡Ëµ;’Ó¶]e‰->¢©	¾Ä ƒ¦³øW´8j9ÿ–Œ¼µÁbëH™8nÑ2Ÿe0œâÖvYï*÷ğ¹¿‘&¯ö’;Fgz9Ë Jï¶¬d[„yEH*éje•Â]‰‰Ñ-ùÇ®[Z³ÿ“çÔy×¯T&Û -Ie2—Ê½íŠ”,0s`Õù/öèœóy˜v9÷—¿’&8» û0G34ş|Ú—HJá*…òÚ¾õ+fxRn«ØÉËß^)İ=°Š¨°´a†?FÀ’­*(/BñfZ½(mve]™°^Íå—q%‰-'ù˜ÛÀBóÔ¿ˆxsS’\9"İü‰¿EW‘ö!à”àî#b©Òğæ–­”²;­düşÓ› ·… d“3]mÆÇÓĞGCØ{œ5êB±¨úÜ7°NŠÂ,¤Pñ¼Î¸ßáËÓw†ÄæÌXò¸²PæÌ‘pŞÕN+Òõá‘/fê¢æ4‡†çóÑ›Uö#¬(SÌ€š¨l¯§*Lè¨_,4H.Â¹Q)½Oİ‡‚"ü˜ÖbÈ…›ÁÍl•xÊd‚‹%éïNñ³Cálä13L.´ş	wÂQiP™Ì|ÍğÚÛĞtèå}—;7¾ÛDÎİàQ
@œ]‰J§A\æ1ÁšNdnÁU\^o~äPHMo
µª½a‘¯ó ×ÈX¥D‚M^ÒZ ¤ÈûòÅ†Í÷?´”–à¾D7gÚCF9ùäôÎçÛYÈN"¡‹£9öD
ñ ©íˆG§ûMØmCK%ÂŞÂıæµÉŒ{*P|,æ!ƒš…é“WıúÜƒ–*ÜíğèX˜Y<¡P-_ŸeÉ¤o¾¯ÅvÅPKº€úÔÍñ–ˆÍ{t8ŠŞ [/7j8C%¬VÊiÅÏb<g¢Áf‚öq4U-uĞP‰¦Æ¿ğ,‰!·¢ÃÅÁkTk»—ÏI†´ß÷3ç³´¦mŠ
bP7Í;óTƒî¥ZÓëR†<™‚êü®‚œfƒg)©T¼fÖæJf/|>8ŠçÔ`2e& 8õÑ©’µ:òQ~Ú"mWe* #ãÖ×ÿ9.±q+ïf×MNÅyHˆş´ÅIó€kH"AÜØÖ£ıÎAXFŞQ_~8Wø òòYûI"¢ú‰ÆéDG€ Şç÷C{ùÓi«b×õûã_|$¬ò*STK!Ù[R2¾­¬e2`¢õõ:+xi„Vƒí‹n«m-QìD;f£&ñÜ¥_òè7z”6¬æ¸·’é™uÒ÷5a³V™ÿŠk9Á+V¹¹‹àù:MÜĞ;›şA÷ı¬uG·™$dÿ O™çFƒxVù-¥œåÅñôZß#%jÁçfC‡ØDPÌx½åíKßyê—kå{W7ÀKou§¿{ÃŞ9Héy
}î=)frPKØJ@¼Õ>ÉÎÈŠœ«góGs Ñ,ı&‘gš{Ì$±6™H<« ì2ïœE.x¥Eö9…ÖÂYKótŸ»Ã
xÈi@Ş.Ó–ĞòÀ…'À®/»®+jìÃˆ+oÜë!àÀD•5rxu!û£‹øö6Ï "lKrvM¥–¬©¯e>ßKÉİ¯‚_©#ÕOlĞ}YJ¤]ái6@Yã·Ø#ÃÿM›/<*s-Á«ÿ¸À‰H¸÷çV<õ¥óè™ÔÛî8¡‹]—=ë²êç¶Î©%ïò¦ğÛñæLĞ›ïMÅAxøqF×‰XÚÒ.·PBš5| \ŸÔ\È± T04jÜNåĞÔ/²¥ìh]¢».JÕ‹	Ã?Æ§oŸ¿/‘UğÅly›ä°„Sµ÷)¾céL}ûÈœ©şİñZW±ÇQºh.z˜f`º·ØĞvr‘’Öğüö€ûÅß£â}ë¢ş6áóêAÿüµêÇm­6µ¼¹ŒÛßUÕ¨è@øŒ5[BñQb:İ=D!»+µ,TR +¦è§:ÍÉŒ‘| Ì«æÔ˜Êüa
¿á°9äóÁo”˜7ûş¸îş]:[ìz¡ÖqÌ##¥‡u¾;céÿ„%«Ï¿mQ¤t©‘m}¡7é ËÎ!=ya(%Ij†´€İ^&&$àŠ&#Í\‰ÄXÈ^ËI|"lw?juÌÙâjœO	àXXVÏ'æb*m¾  ƒ‘IÚG
p%ÀÙ¿Á6'6)êØ}%Ï©3Ìõód1¡Ü[é‹ğÿ^!é•Å6ñpÃD?ò	^å™’†hÙŒÁÔ
æm~Š‰ƒÄ©u¦öÂÉĞXsR«y¥¼ñ”8Í'Cùá–ëa3ï+í†_Ş¯ÁIÉ“ö~ÊÈ÷zˆb~ÃGÍEsXgc`,UˆÚ]bö†ïÚyñŸ×KfÜíÄdsé9 OµT–"™Jx¤ŸoÂÈ÷;Vhj”/ƒ3V'2f†ÖwÅdÏŠÒ6Q4äY¼ 6ºxÈLAUÜŸJG‘cÊIâAŒõÁw£ßŠ/y÷ÅˆL†Ÿ›;­£B¾9£ä Ÿ¶n›ïm=µw9Èhùùigxàüùõï[ÿæ`SçøJÓyOè”]ŒOKu¼|Í/(î_R÷=÷1@6’‹×v¸Úg”aH‡Pvíõ,»¿qÎ½<4æPúØØ§‘óüë„&Wçiç8Ğ¸y¡´2öÅR–½&MÀ
ä·T¹ÎïŒëœ¿|:Yz–2+Jw›Jİ†Œ¡Š81Ğ’øó¹íMUô}0”5ùp–cZ×íI„5ôk«ä6b<UÎ}ÆÙD]ƒğôX¼ôo”0›À	é ç•kÌÅ­n6Õ¤ù¥ÉSæ¢¡Òè¢
ç’bJ}mOkÉïÓ½xó½Uñ&’ÇQ"Ù“§j×”êX>d©ÿ\_¸Ší¼Î®Ñ‘y¡ Rˆ´à=@¸}'÷b™†`$a¿’ø;kÌÚxŞğŸ”	s|°pÂ)¥rš‹&wFpÂÑÅØÒ[3•«;—ñœÌƒÉK|páš<óTò§‰ V_·$'üvêé`\®Ù®Ê	€1ÌPåU\,3D/",Né¯À%A¦ ĞÑäÒšê©í»H lql#d³Ñzg›^È7&Vg$zt+Qv}¿“îêíĞuõ(2ÙùTyK¼TaŒúãBã;Eö?õ£‹<şgj÷oP=’ğIˆøB¤Ü@¶û)´n-kı¼É¬hÓ&ÚÑæG±¦”˜À?ì—‚o‰±¸/İ¯È’1I¶9–e<  1o—¬Ê‚Ù×Går<Eç]€š\,ÇS9øíkpò±$ŒùgX)+ÕóË:1Ô2Êh¬[pº‰~R_ç+¢F`{ïŠÛŸT‘zÛ•õ5©ƒ!ÇuF@˜3Ô4õOJbãĞXõ¶i¸nÉÖé+Å¡¤Ôb[SšFu\ZÃÈº!ÅµCÍ(d´İvø»‰ÄDX.D€l”Ù{1M´rn>´œñ§gAW]R R÷Üú 
›ÂQ›Û€k¢w¾‘®
†EœˆyêF¿¥0
P—ı+!ÕødŒş†MqêdÒê¹#ÅğjŸ/Ùëwı…ö­çfjÚ¨5ÎÌŠÇIé›q–D­")%û‡qÅÓÓ*9.®¤?í¹²]Mxü-‡A£¬–@³ka6_S•àZÖiVM¾ò}8ù¤#ÂÁ¸WBãé¹„fÓ&(ù`Ú¯bê¿rÿX› °çø"·Æ&v'¨]4ÈK¨´ïG´»Ë?È!P/à³èİYLİTŸ	1'{+Ä‰æ¢`mÜÏ¢^®˜’g¼Û×nˆœNlã&×NÙÚ;äC#I4õ$	^h”ù‚xåf·)LqôDåQ	ãÑ®ê±}ÒÏ…¹goµz¯{?©šöîišY'
GªèdB÷ê§5(Q„GƒB´@Û—ˆù)éÈjá­¢¡§‚BêØø>X–³;Ú‘o˜Ê¤ŞF§ìÈ3Jm†8AE^u&·÷¿Ã—àŞ‹­lÂp3·"ÄI_Ì	šÜcÚ-*
PS	àoHAú‘Â¤I ~½7á0
ÀÆD*£,y{CSÎÓú)ÖeòZtpÉLAÂ-”§ô/¢xlÃ[È‰§Ó –à8‚#ÿ{“¼¸zLjoÜY!{æB{ä%¬ìMÔEèWSÉwg
	#wAFvı'IW¾BáJ'øÇyLN„TX
èE¶Z¤ØO™š¾AËí:2Lè<õ\á×ïüÜƒú˜œ Ë™z*>™3¡·iœMDzßãÆŞ²Á–¦'-ç,‰ûjÈE»eáNxîœ´ äø¹ıé‰ÜT·…flÛNÛUs“sqßˆÔ	»å;ÃyØfU„›’$VjöcŸ~™ÿÑ¡†‚ıÀ}Úb–ÇMéS½A¿IŒÜ¯e‘JQ®ìKóÕzµ¹ Ô ã¼·Øo¸eÆ,kó #ò)Á ¦Dğ<4ÿòØR"GGÈÌ32¹!Íä'iX°ßı M2ô6oiµkó;QÌ=0µ€è»éSŞ¾xêaæg)…Gâæ¹äæœB˜ÑÀ^Ñöİ‹ú|Ï`ÄAêhn¼)Ø,îĞ!bÂÅ^ò—mMIûO#¤BYbÑbvÔ‹ùø®‘êŸ_Ëæï¬ÆÜT ®·µ©“I6)w	n«èC²¼–O'1˜/[EàÊ~‚Â|=bÙEş¾¤7‚_2òU¯'ì\dÆd?Lm.'M»C·VÏo’\¥U+øø— Æúµdãå(†çR	a$d2pwçâŠù·½á³Ü©°ƒQ? <İŸLˆH[Ã6Ù™yGc; }q«T<1~)ò=¥ E
`Ø!Cú6m,TÛÂ»¯l×^ğ7˜Êæ+ÒzŒ?Û:™—rLÇcÊ4÷ ¯„™ú1CU¤
6™›®¾¬7€SĞbÑ›f0°èı£€¥U­yIFSFĞŞN-lŠĞ¹:J…Ö?ÚÏ ÷}f¤QÑ™ö=ìüQ
ü*qG`'5û“y!ü©}{j¦áC1Áï¶õ\1Â;)œé|ùtËê“6»Æa3Óò÷ï¼Õ¼Ô€ÿ½ÆğJ&›ãËV¼É’{‡¿<ëê«:T`*¥”éR£5JêŒRÈ“ö3ĞS\ÕA@÷öuÔwÒßc¦ÊRW–)EgF!¶ÔÑ˜?øl,´[?›WUdåkï9hÚ&ŒOµÿq…Ì„6Ÿëµ«IÕ).öªš¼É;Baƒ¯ûë“+tCÅ«:ˆ%´¬Qº0.Àÿ/ğtpß9É™¢iNÉ 3İÿödçL8ÇNËÈüÜ£UZÆ|\áº‡	t,Y
Ü‰M‹#šaÎ€YU¸°~±9J?r20°ĞuvôÍ ‡Xæ<Êß?AÀš'‘X7Å¹Ş­Ö!d¢‹œ,5(ŸùQ‚¾Õ¬CL—*'d:±2«‡åR®â¦J4r\ŞÓÙ…˜ğr¾¥º”Ÿhh/d™@ÿÜ…ö`×Ûë4mï=f[†1jš®J­®TÿÈÒ£{½Hµ|/p4Œ
Rs©3ŒÁ•-kºñs¾3ÃHœ†§×AÏ¿øÚ>ö8M>-×œ~“n^—Yqşä>Mé¡(71qÇ)ÔH¤XX=cúrœRÓµ$€Å_Éùi|Z30ş¸‹!ÎêQGİºcf2Tu<û¤”†ÜNºÅB.+8êª‚Kµş{œ‘6¨]9¸>côsÀ§ır–P(;BAôiºx±ß–³¸­!Ûúv[K`±»‹ìø:REÀr:o+btjç[™…HKä$ÌdŸFŸn÷.Z¹Œ\Ü›, E«¦g7I‹‚³b‰á~ëåAİï'6LÎî*pœO‘ÇéÌÛt0Uqı›ÎÁøº³yaˆÚ7-$.C¢°GHÆÚ#fdššj¨jyŠˆó¢nTÙÙJa¨ÙRHvC¯"	éyªL¶yñ¦=uAAŠÜdhÅÿAY2t$…Û™Ü—¯Ddüõ*3³
ño¶òW'é¿’AÏB!£LAEOïXœ$c.6ëŠ¤3=õ¨äv+ÜR©í¿ÛV›ğ¬^“)y#õ‰¶k]‡,ó¶àuìÓPÿ¹óë3Y	Ï€"Ê€“S¬¤mÔoVŸ‚CZívñÈ†à¼7¹åæÎ¶tH•-"B¯m¥H„›;©šÜˆ|õŸ†	å4_lXÁÄ‹L¬ÆUîyÒÚ-h¸À¢.¨nÍĞÍøDæƒó¥îÙõ2W0:l%Ø#S¢EsıËb¯hEübúåÉ² 8–„B{Æà¡¾ztdI2PÔ«0ı§PÔ‘à~¡,¦L–Å^¤®“ÍÙ·5?zWåàğ%ÔÑ¼›4ãóß´\.ä’Å›ªËxîLı¯áÆ§NÓÛŞºÛ\„­ğÚmN®Ş''uœ^Ë¿İHùø›![–0Éòw‹	°ıîªëlPœ~D€Ì÷Î ~¨PˆeîzŞù×õ¬X¹´&‡ÃŒìjãA“[­apy~€Ì[8çš¿)bVDzÔ¢Ğ~ÕóÜÊÕ/öÔ‘Á¶6‡p¯(RŒº$ƒác\ªÑ¬és3¹‡õ/Àh„ÚŠ‹V÷NcS6Óö¶+(å¡\{;g‘ù¥EGàt~5¥[àºéQuÙá.uv·qV•ø;KÜz‚4öó&M3|+È¢»åm×gk²t-@â‘ÕksĞ^9Z.â•òÆ@î\•Ã¦ÔfşNÍ€Uo`1Äz12#ûlÜ«îY>Äö8É{a¤¥l×§Ğ¥†ª‘Œ˜Çç©ä	Ó~nÅ†TóP&U¥¢œÊ¤’B›wÎB@@ÈWâäk/kSg!+9²/xf2ıHX•nUÛa.´ÆI~ôş\*…t¢ ‡ÎBßÅ*ı‹c¬ÛBó¤Ã[õ¹iÃ™ïxÄÜİo÷²If`™©A:rÆ Àcè=t…oÉã\9ÇzQòjt7hpdY÷‚cOV|6ò÷;saò$3su¸¥‡<kiï®£–•çìœ*İœ	Û1cÖD[Ö¦+\ØÎpˆ’3,Ì«‰âä'1eiVkiåĞ)QpÈ4ï¶™b85°ˆ¾ßÅ¢QÄFV”.u€0·ÿÏE«T'ÖtİâÒò&-D’¬Ë¤ü«]¾wL.«^œBÃÎ7°>Â?[eÇî 0Áú\ğJí¹|ñ?7?øGñ¶ìÄmâå-Õ]¸1B–çéSß&f*ëMTÓG-£>"U…¾Åş}
œ|	(*—RÜYÊë…9úˆIîXÖoµ,¥5!8ÊßÕÖ%öAr-­Aı\ÃîãcäáäÌ8Ë¨è¨³¿8çÛ]r[ò?Ÿ‹ù—€g^÷¥wQ4`8€8º’‰ğBôGÁ’R¤¥„*ˆrÜ[BÚîf\ff³:û+Í×í Ôœ¯€Œ@z>uÕ¿0& Ú+à/º-åÙOœkš÷áƒ¼	È;º\ <(Z»‰QYY$' ¬¯'d- NĞ@o“`ulñ\”@kU)¡6Y%¨E%ËŞÑ°¸ÁÿAKHx¤ø#EËeİ>,©â.£Dd=AzÖF2±À€æ½ë9üéøE2çt¾Ó†~ú_)Á„Çãû¾£Ù¹7iSq )ı@¶uarzÊŞ4,Áê¶’Oø	±#l¯Ğ±ñy•œ·*i÷°<åÎQ<:ÙVâÌ§¼ûIuR¾m[â‡îŠp	‰v7Œ‰W¼gê2:’d©ÄjîŞıµ”;xîo‘§ğw,i!fi	zM•õ…eĞ’“q@èœ ‹<§Sƒ?„½çQìíşAU»ñ¯Õó_æàÕ@‹qÒÕß¢í²SÊÃê“†UËêŒZ€œpÿtQ'„höç‘­}÷{)°’9®B·±r	öj™.pÛ¦\œÍ>@K«eèƒˆ,1¶İ¥+}s_Ü
3'?Š—G2¹s¡Gám‹Š$àuÜ5|Ø.†ú:×G¸s‚úÛ*è•)#÷–Å™<Ë£cü<azÃŸg³Ö#²…¡ì@/bû¡1øË%^”1<Ñü_‹5®ñø³Æb¤ø|:öªÀˆl½$ó•æöÖ«„V—–a`Vy-Ì§q”¼]†H‰¢OâÂ7÷“Faº¥Á„%¯URS`Pg¹ÙÅéAú|ÙV¾çN2^GÅ¾…˜·gÒ±€‹´ ³ÂÀ¨£©€Wé¸0.©è¨‰Øf³Sn—±Ôs_^Z¿ïR‘=M]²¹› ñY_5µ’-ğP9wÒ›ËŠ‡6DlĞ)ŸúH
ªEïÑ¤î™€'¨ñn‘ğòé…}q¨:!›‘Üœìı|>]mÌÀ¡ì;[@ÃPc*Ë¡BßĞñş•g Ùì¤^ÈÔÄ.{›‘xR„ Å;ö—‰¬VfÑ5|æöo¦ Ò^Bm6í¾+ı6áÚàXÕ›Ï>±!®%‹ñpòaŞ.‡ôer.¿®UæÎ@ƒºÑ^G£¡Äo¶L¶p-Ğ£~›j·J¾XiªLQË·ì¡’è23¹àÉC}¡ê½bö óoö >,]uÒ¢]ùÇË'V¢¼ú9Ø¸ÕI‘ø–ØZw›˜ˆ¢½!“k¹R_q°Ñúu3d|)º¶xš½`"­s¤åk«uîq°ĞDækU¸6N†¿f(Ó°{–B¦s`aW}¼ˆ äÒİHšÒ¢à¾’Qƒ˜ÁÖæÈÈTáª4¡iè¨"2+îMtnoh~!2q’ÊJP¡œÖ7©Xq ŸÑnSú9)•6ĞŸ'GM5†ûeÎ¡Á4†Ä@p=ZŒVJkíÄÃîeà<v! ñ (‚t‚#4 1t³w?tã_®udüÓ.½½¾@VÇ=Ÿ®cåÖ[_Ë_: ¢éAĞ¦ì;İñuvC’ù@ea±j<‘°-;1”IYÊ‘¼«e`«6yˆ ‰~OÅ@˜&æa–@[Ó°´äfŸ}èâòî(=ø)Âª:dBæyTÃÔ©o$
9\I şEnà:›5XáËş! EøÕ•ÔœO:µ;a]z[ùÛ?‘¤1æ±2“%&½¼‰©â$ Üf¦êaÁç^t†…\ÈJŸî1Ú5ÉLHù"+$Ÿä•„ßÍïfnHÓöÎRZqŸLy
š+e€áçêÇŒ1ºoh»:„,l;6etpÍ\˜o éûÙõÿ{¼g‹{SbÉºû´/Ük/ cIÛ®cnmuª$<ÓŞtxš“ùhãA‘ã±r1â¿Ù&7î¸8ß†™’·.Ë¯¼Z%aÈİáÛÿ ÃÌ?dFTèJp†åÆ-àôÖóÜVçîK½Ì‘UrBßU†7Æ†ƒ¤çæ©Ì«èWGQßÜ$ßê6ÒFŠ—¾[ŒïÙXíêÃ‘ì´nhnr-òHÈ/$êšùLÃM8´¨\¯mšú@Æ08ÜE=Q8Â§z‘ÔsuÁ:æ˜ç¡r–r½®ş6›²Š€	KBlßä‹^æ0…Ëën×ôÀK‡É7Œ˜kŒ|“×ìôXª ÇÒŠ;mST€¹l™Èò[sÿ¡¿Šjªq”?`,&±kÖ_Noªá¯w,»³Å…ôãŸ´ê˜µÍ)aIŸz.İ…&×¶¶îÄMóMpSïŞN=„òÅ¾ò~—-éc¸È ¯¥<gZ9ú†;tì\-êKzx$çcåç½g_L{Ô´fcˆ íÇÕˆ>Şd 5eåsgZ„PpáRfUÊ™â§İŸ!Ò>¾†«IuÌUZô!÷ºeŒÙ„zs;u‡§N­Ø¯9›4\}¯ò•6;u_téİÙ£5EÜ)S]~5úöıvä¸í¥ÏÅtg4yÏß3Ìña3HıÊ$Ã¸$Â¸s¬O†ú/ë;âš¥ñdŞŠ}4è"@EÔ¢ˆlÖœjågö&G€ƒ_Ñ49%„Í>ı@­h‰ª]4ïƒ.O{.y;õù³˜6;î¨ØU¸ĞÉ3ì…cÆ9M²pš…‡æGÖÄ>5?•kÙ3}R_Z¬W:qáºÖ·B…›u¤ÑUÉæ':¡¡ÎŠt»äL=™àòpIEXôuu`iÏÌP‚/wÅD}@Ñb–6ï‚1
|.(+î¢ëğÎ´¦*ğ­Ô–g*S½,Ï*¨¦xa¿ìŞ]2öĞL›‰=÷Yìÿ.ÛÖÓ,*¾ÜUí·q˜W˜/ªøh™|
BÈ<Uˆt”Ya8ê)òáLºğ§ëÏán;¼ıOHD8¥ÔdìêiİJ{òéÿvúkëI„˜ôo
6©°—sV~6šé&¬ŠüuÅiÆåG¢Ë‰YjüÑóÇ/ Ò:3VŒi_p/=+àÛŞÕ«Rqq}ßs€Šk‡zê‚TŠu ¯ey[kÍ<‘B”ÖÎƒ•	c6|ÀĞB¬:+bÎ‘Gœ¬Ú7†rïëôo{(Yø¯0˜dW}¬{Û¹Rhqƒr`™ç¦ƒw¿~6he¬)&Óÿ^ø‚vo¼ë]çœÏ&>oÔ4=Ş{ô#ó¬zî£ñr¹)Qyktş ğÏÏ7eé²`!†»wl”º hºÿ#¶ÒñWÕ‹õDhK#:R$ih“Gá9ñÄvQÃæS¾^>A:4±—Œ9B»
ô;yƒşñ¾d%ß!î‰ŞÍFµÁØšL `–Ôı [ÿ×y[~/»@kŠ™¯d¢ô^ymsó§ûô¬¨ø…%¼Onò*÷@ú"ÉZ_µ$±:í».7§ÉÎy¥+üÀ¹5Šklóp¥j‚´ümG…#‡ëš>½¨“JzsrHru;½)«O‹¸4$İK5šÛª¥¦ğPšÊ–İ"’É-ëO\k)t§ñœ+^80©İ†`˜©“Š±òV=Qg½Àá*IITI¥»Šß¶o•(ğQ®~¥ñİåÇÅOOÎ²öğËK~%™¶áÅ˜”^+¯µC©\mÃ.ØÍ<¦;ßÓ›œÄ$"$è•Çä,©–¤^êÛŠ:Ú¸M¥O<»™”Ì‰>şşàtJ%xÃ~tŞ¶Yª»I
9FrÀvëœµkå÷ı¦š÷.ã_ú ß mòl”Òp¬VMMcïïüÃM˜LôzTÃÁ¼é.É±Ğ"b½`¿Ò}%&oÄø«Ö*¨ï¿YŠ’İ ßÜ&(Ûd0£Ì·.)zúTaZºxeÕaˆIÖÒá‚jf JçŠz³¦¨Gûæ­˜/>D(U%Çÿ=sÎf3'v|—¢!xÿ¨>M ¡¤‚Û}&ú5‹ßk@oqÒÊŸÄ4€á.Á’¢U9…¼Flª¸ZCïLoï?æ-g)áHÈOBÌ:Ø„˜*(Æ½X¢‡yÉŸô1LÖ?Rü((ô+V•¾O9})uq1ªğçôZtÚa>“d!«'æüèÛó´OÛÃ–ÆKvzPyjÒœA C˜Q@ÊÖ6<\2^ˆÕY³† T=“˜û6µsUTÑŸFbSë-Ğ$Óˆd°Ğ&tÜ¢³_8¢7á\
gW…H¥‹Ò²IçeSæşAïzê€(J>: ‘£QùGlì?äÙÜ5_J<Ş©M´ÿT{oñ4'J€K\'d‚û°
]ÜSË$àˆc@õˆ×·8'şˆêxÅß`ìï'R“ªMŒ^A}÷­|ñİIñg­ËŠÜq/ó´ˆ~ësÁQ*8­œ!’3 ËÜä ì¥a".¦áÊdek0ˆA‘tB@FçÜh6k_ÑˆjcF° ˆš7Ék¯‹Ã–ô•A)µƒyJèœ¼ˆìåÔ5£óÖ<¼¹[Ù& õˆõU¾¨ËÅŞ{š? 5‚îƒŠÉôlˆĞçG‹6½æà¼_ğÿ\}ÿ!æK6ƒ‹î €‘WŠhªÉT» ™WåXØğÓœ{aw[ødİbâ ©1œ¹lDV*Âú^„­ªçÂ!¥ÙÚ'¤™ÑĞü±£p8êFıw½BÅXNZLY q–¦6b,’É©¦u4÷	ï’‡Ö‘ñ7Å‚5Oé3KÓhrC—LOm^8U:MÜ#ÍM¢w{*üÛ	04¹~-«ŠKÒ¥@¸‡	têıVIz„)v•ı
¡êÈÕæwªA>ç8ºÕ°	Ø£Œ¥÷é­åÍÊ8á‹£F7¢4^M;“½2Éúu×w¾8’¼nv…‹êÎí¯'6
¦	<°Ñ3İ/¸İ9²ıwÎ^#–<v…J3¥/TÑ’CràmpMJ‡•G,Û>§–ä›’éW'ş Äïi¯§R#Å863|¶rîıîºs9Ë$÷æ¤J‚WÿåçLø»B°¨ÇTtÌK.é$"ó†Î.X?©`dš"ËkÏ©ı?_sÒr¾mT²OÔ$¡¨©7h®Ì‘Ü\ªz\¬‚ç/·ÅiŸŸ!Ä´¤Lã†:Ë·[G©Õ‡Ç·áİ>D¼é9CÅiÈy#â "iĞD;T,>2ÎÂSaSi•÷‚W~b¥†•éõÀ! {g¼hv1ïõ0.ıè»³J]SÚ .|1ÀéuU¨Yup_ã’Fì¯%õ,§<@~(4$¯¦	ƒúÑéÃDíûÀ	¬#ñÀª(Á3D·‹Tgzµ6å
Š#)jÃ¼š1É€œ™R ]èÃ—*Oğ¾^ğTş´ÅÌìÒ»5µ¥$HK·I“¨€©s‘ôø²M·ÖÁ%© ~éÕî¾2²¥nÍòØµÁÎ^˜Óªù­°ÅyzK(áÂ"Å`o±`ù¦µE›gVıí·°³©oB{yFô‚p|æÛ]ï¹(,PşaÂ“¯&3´+„F`‚ÍM®‡Ï®ãRJîå,YÌ¤"¨ª¨Ïk_>ç¦Ã×\[ÜnØİ^‡/¿çÏÖ(!s>Utbï#ñ£Îö.2ÅS•NÈsæë)x^8#ôšZ\Õ'³}åä Ç’åLWL‚-e™«i±-®…RÄÎ?gæÓ¹´ ÍjÙƒy’VŒkİyïR'7¯	ôr3|´&ébËìóòË¹â$TÌ¦{==“OKUØ«Íõ³\SH’r)ıçzWmx5w±p¢Æ¬ÈQĞ®ÆÅ¯©¦YŞç™0ŞÜåœ”.ÿ½7¦Ê¾{ÁÏ.ÍYãí›ÄP
aJ§®Ö–¹=çÉW™›ö²Î§	ãî¶I×#wÕ„c[\˜èÛeµ©ÕĞóéÍcx,+ï5e#VØræL•î³Î	¶/š7â“İ2Ú¢2ˆğŸœÒ_‹9Ù3ƒ:ù–¨r1Rk,æUúÆSoKsö"šÚ
±âl†tdÑêXïĞ-@ÿ–o‹—ÊSr·/Hg@–3â„¦¡½®çCyk¼¸“!³¦,¾†iz¶âá*:ÿ$HËú°Ç?Áß‘bÓ=+A@¦G°Íx¸^ñ|_P9ÅŞâÑ` ì¯@õ£ÿaxÓKÌJó'«P@im¬Mòc„»N_ÇcpWJ(‡»h'Vÿ)k1wˆb &ÁÓ>»á–bGIrKÿµg#j…­bIc‹Çàd£Èê™³®o¯™¯©!Ú«rù€ìü;ä1 €Hò²$r­­néÚé†öïQû#ø¸tÏgÔ¿ÅãoÏZ|YNy‰«âAÏ¹E~JÍTV»$¶Róğïl-095qäÆ0 &¶:ü©ÕšÁ~[îóùéİ‘8Œ¾-)eÚ´Ûäàù0í}àĞèœß™íI^_»J·`>n÷õ0ìH‚­ğu¦bvˆÛÚ)‹c4TQLë]îö["ÙAÔT½ˆ2rˆ; ‰xßõ<*ÿ:±İü˜aGQºÊ†	pb{´ıÌ~áòùOJğÒfJ}¨"ŠùîöNu³04•3ş¸TØ'Î=´*ïØğ1±ä Ï×Æ´àş÷æ×z¢¢JeY=8Ÿºp>V‘IP—ÿ}¨óÎYËŸŒm4¤^ÏFıtÀœ!!RñÛ&ƒ%‚qÊÃUË®ÙfH³ën¡¸×c[¥y†f>ùõ¤YvÖï^KFæ²]D+¥º”Óœ’Ş–ÀC…-8¼]BÜª6¦-}F ç“…ù¿­OHKPöã“n¸Û›y€¶]¯‘õÂ§$Xx·¬¯È÷U+Úf}ŞŞ§šÑßÏ77lÉ¬J`‚$¨ğgHw—æÑDƒèÌÀx÷{yêW;üKS6ÒØË=b“Åqg§±8âãi#´ú–lã#ÕÅSIûğ#/ãK›Ìë!jmZ7ÒJwäşHÅ¹ç²ÔUëİøì)¬“°ä…ãx˜›¢ßlœbÀs›bÎ$«ÅíRD])öùôçñs»(êå2ÿóğ£Æê®İÔQÂYõ`È•MoÀ,±åÇ]Ş­®œøÎ¡ù7E¤Ì@¦
qÑ$iÎ5
Ïëîq²¼Èj÷éuá8:ÙzEÜ‰Z§:²<È:¹]ÛCß*@ÈÀ$tĞï››ß!?bŸS§R?6BïrQz˜«$„w	'Ìs·HœîÂ|n°¬s4f±†.R­4_Ì6bY½á$%£·ÅÈ¼Ç8Šàv¶p™Yh FdŸİ	MQ)ZÊ°Äû0XÓ[)Ë»Ä«?ÖsÌx¨:z™B;*²Üù˜aÂ½ºÌ|uí:móÍ(²÷ÜÚ*3õ¸ZÒ–’Ü8ƒ÷}Æ¹Şİkı¢½€ùÏÆ×ç1Á_V<=¶ÑÆv€Î2¯Ñ¢¦†ìıa óô§?d·†}Lä\}ó™1^$@e%l»5©Y¹FÙ«­Z,S/áôÑ)—Îán5Ä¼"ÿ{²d+<E¹q;bàÙÜ<óe*;ÿ#´3zSˆJUDW§~CQkép
7:‘>Û]õ=ü\Ğ¹\…‘¹²%Gèà\Ö'ÃôPêŒ“†¶!•Yº8Ùt, S¦bæÊÎî•Vøı3üGĞÅRL®Tö¶Áşz¥U8½m<†pËÑ*ísPÓsêbÌ½£*Ä…SÇ'®Âñ0Ê¼Öbr9ˆ‚#ÆLÕz ÌÌz­†Î!
«[®N„.í§®N°s„üÛ§™3jò<šÆ&-?o:T69xòë u2ÆQüƒ»È¶{ˆ°ŸËÙ•ëµš÷¹uK
N£÷Ë°E‹1²/“Ÿ]ëP^Ï}¾§ºUQªP«ŞşØÅÀ7S9s)äTQ2¤âÛĞ¬ÿD¡ğ›ußPÔöõÂ_—Õ£«—â1óà®œßµÄ'ğ‹C'²¡ÃúLòCqÑ©ËÌŸAÏQoVùz‡¢¦ø­ä4u’ã…Ì~ñç¬NÿT˜ˆç’.•i>R¤¯F>›†hÊ€•!Õ"øÈÚ|ÉøFİğì=4‰;o“*ÕĞª¥¾Iüİ 7 )Şê™†î•F¡ôÿ0$àM9Ué›¥ ·è8ìú©¬îVp·ËÓéQÒ9ı}¹Ç@IHO½ùƒ‚Ïğ`—‘…t-}/µ¦#.åÄáÜ¯ÊWÆvçcCgØ‡pıt`“Më(Å¬Éâù©c²%ü­İ¾“<À/­cêy}FØÛÍÛ¬ "yV?ÂééÉjD«~<WñÉĞ+ækø¯­€v÷ÀˆÎwJùÃ’$âË:†ñFºé›M&¬¯k÷wiÿlr°£İlâßãFÛ¢u¨Q’-£¦s†p¶Ç#;V¹¢ßÏDìIiJ:V·wV8·69së7–¡\ş¾‘ô‹m\2 ¶½“¯›/kC€5Œï¶}»#KTÑÁì·^¨ å}’eÇ¿‘(ìàÉ\İÀF
Cze.Úéúgµê&09FYŸ"²\óÜˆ}ïË;{EõWÍßLM…ì¬#¨±ğ«ŞĞœS´9IŸÔ!ıÙ’ƒ®U¢¿XÒè_}\£»×ÚÅ§Ëâƒ_dÇ3Ô–¯ç’Î$N±o«ŒC7]Œn¶V6'¥úÎy[{š­y¦°o¶%@zÁaZ@Â¥?Z½ä½k°‚›côôY®B9ãVuUz_tÈ1ƒÉêÏçrú¤£–dlºšX¯˜Ş‰·³Û[dõ–tA»’Ê?WÉí7—'-@0Z•#áû/t¤R,ãká->˜yÜ,¤ÏqŒ¡Û_3ÿ)÷Ç•äB]°ªšJƒtŞO<!}dßĞ_¨¹¡4DD
ÿ™±>ˆÌEVHŠa½5ƒšş0â'ÄnÄ€ıKO.â|[4ş>-4Ç‹*J~¦æ2[Ôí"Ì’œÍ4X£Œ¿
òóË´åKƒş5Ğ—ºrZ F{0ğ>ßÁeK+	×Ñè$²s¥s“PDÖ¸w‡)Ïã0•¤ìmÖ¤4´ıF-–	J.hÖ%®Ú<7ô¯líhC?©R†¯O"3{Ÿ*óÌ_YÚ\@s´„¾Éã¶MÛ:A¹edi\æx¨»IÕÅ”H‚§1u9ìÅıø`VÍ»¤ÚGÌ—ñ)Å†Ü1Í„´ÌFß`¿=ÁªŸuFf¢K¹¥;Œ½bl•Ë1Q'»÷ı'¹Æ”A÷õÑz³ç¯­MºBğSŠ|şˆóŸÀWL"µßššğéZ[{·:"•´k'4;ş°QÂ¥{Sÿ"Ø©ˆºÁYfµ|Ey"¢By¯l·g´ô¼Rà(™­uÒ|@SmŒC¤,‡Zñ^¡$&Í¹‹5”XûÉÓõNc˜²Ó”U&ı¼q´’Æ/CIŒ©¡%ì«‚XebQb°:ê`e ×¶ëæ™i~¥:°(ÆôD1Œµ¤:Á3ÿYãE<â\J·…0ùò¦ê>Ù^6C›ßK)b)£6RÉÊ”¿è:9ì¥.¥À@€%Ú7Yı†÷Èò6ÙwQBßln˜â7'#<©Å<Q)îdùì4áÅ_[`ï-g4O]àÇyJ³¢Y‘%ÃÜö_º&}¡Úmêğxódã¾ÿâğ…‡ò6Jü¦DGÌ‡ Ö¦òğ&$zæÉ£Éúßìñ	Ğáe–O†¥®’6àS›‹îÿ|€¾{o?æ0}x±ænºZ"»R¡XÏ˜ÑZ6,·‹ù„ôì%÷Q–+ıôZô’-n%)…gşê˜1À)2A&|?×icL¾¥lª4ûaÂûeg
^¯ÖPWŸÃQfÑXvÍŠEn{ÀÚÖ~Å´{uíTV^İAƒ±%¨§ ;)Ñ>–ö3·»‘ğñS{]ÁRPÃBÃgñ×İÌ	İÃÄ+ô­Êõx„™!Æ÷
6ÜPºIP6²Ød‘]3I1e`Ğo?Pœ}ÜTï©g"Èô&Û²Ì\
ùOÕ˜|åÓ@.í0á2Sia/Å ™cº¾vî;Ú\H>şïƒ€Àùæ0hsÉşs´Æš`cˆ5’˜]uÊôb_êRav6”ø&µ§)Ù×ñzX~º6’˜€°\®CÕ°=<Ø{Ú©%‹eF0¼i$ı€-ÀZ@¥Ò4\ü–¸9ø0l¦(i¹ÿ³÷wNJq¯—âkéÏ^£ê'”è‡ä˜–A¨'´¥Di1®+Ü[Ì#S§q4c"hP¶ŒMKĞİ=<šã–å’ıqz?êoöe*ª‡{ùkˆsYñdÍÊ¥!Á¹	>Ì©Õr—$œ@Àj‹l+K™7Å×5ú"ĞsâèmE&Œ_AòåÅÖñÅFò—	2çW]ğáëÑC¼<…Qtjy‹^„ÃQ¿v:“T=6şŒ¼äè{ïëğÅ7M©ÕÉ«ÇÖ&É²g…LÔwT·Šn™3ÿ/K\ %kzåd@fä{h¬ô‚5İ™÷'ù"+œøÎ¢¯K¢ dºTÆœoÔµû¦“t­zèé‹¡E .}Å8;;wÊÚ*¢?s•['{˜zœ¼ĞXÖ™ô•µ#†%T½+ZP,˜ƒS˜–EP8gŞ¯ÉÆ€ƒmXfD@€~É¢3fÑuŒ)^ç”‹WMªÿ<ğ¼«ZÜù6°´wÏ›2¸´·`»d„õ-ÁhÍ“=wLş¨–0÷°mfÌ1CyDÒudlo¶Üa’VË:jß¹ì¥ô´èm	$.,"wšÔH!&»·ògğñ>¦«mÜ-~ƒÅlHB+ü»h€@¼kÿB–o6GÃ
BËMw{«°Bèå™Vò~u“Ú¬#Ñ%èt>Mâ¿B5C4g!¯^Ì˜kUk±ÁSë¤€*õäwK¹•Z&Ÿ÷#gŸ=|¾|IÀ»ÚŠFcâIÂ8Ocğu÷;eÅşÇ7ÚyiNKë	@®,
èt²úÆrî.GòÑ¬ôPzo¾SI"áƒ…µI™¸üdC¥êyghv>½ªûßàŞ–S4nOsŒ¨ ½0ˆé­ &ÓL=ôìLYYğ<ËZ1E\ ;$üpäwäü9‹ÂdXš'Ø1!á5„£vÃ–Û}*ÚæsÓ,á¥¥êÖıaÌÇ´ [³µt#Ë8äÎ úc>>m˜F¹D/H–·Ùú…·DìY¤óxG—ù2M-ˆØ—§I9ìv…L3ØÂ«Û‰FùÕdIT·ûİål¤<5›H×”.?/“t‹ÖL¹YU_ÌÖ¬°xÜØí“Ë+5æößğ*ÍŸ©ÆİLÍ?5üïà6yİ4IÚ&É!`¿!ä|šÔ¬Ä(³z(‡ª¨wùØÉ]†Buõ6úÜ„Ö(Jc{âtÄmÙ"ç=¦0šÃÊ’6ş_¥ï|sWnf}¼£»N“MS&y‚»58¼ÏµkÃƒ¾=–³†gÊGÙ]µÒ²jJî¤¢3¢sAqéœ»-NG Nö3‚IËáqoìôã@f6PÛÀw‚_³§ßıpG
ğ¦ş5G÷ÍJ_?k}˜–’ô«Ò*ºüñœbû¦ªØ°(OK$óÕÌ0çñ:wQŸÍ{‰¯U/&S!+èZMy3·WÓg‘¨]Zy?7y¢«_Tq”xÿù%"my""Ğ¸ U*…»í?ÔbA’€#ï¦Üµëƒªüp4”Ã“ô äìG¾øœƒr×.„“
e-1Y~‹Us/d0óBª¾‘Ò—ø‚İH8íŠo~ÉÀ>…kÇ€tİ.Õã>ä@ç‘Ûê7ˆ‰€§
äóš#± eãƒ6½´??¶¬˜€4vì=YşEşşCIWaÉéõ+ğVq4äuM1É_óì‚ºL€L¹ÚÃ"ñ>½KØg¸°—®ø5Vµ±}46Ì"u8ª:Ã—.Ÿ·|¦Qz •ïXäA›«·¼ğí%peÍÿ¢lÍn/Š•}Çãô½Ró~—:…¾É—é‡ÜQD&WVÎsE7øHá6(å¼Ú£Bd°½”IRt^ö³§)¼ğâLaÊÕ;ÏììİJ{´/ˆ|$YôoÖ@Ev,ğäIËĞl×uìˆ†•1-Â¯ªÔlgØÄïâájĞ˜÷D°Ó¬“‘OÒ÷cndéÎc"ÆíKGıE#	|ÜîaÀÔ†üÖrJÉ$ª˜‰}Š#Œ{Ğ‰†B=ŸVzqR'E§’ùq(VDöÏVXèIfS´‡¸ p­.M?»`®`jYßGâIE:ã8}§KlÎà_µ¬¤f­|5D·Y^8“@;ey¾eCŸõë‚[¹¤hÌj¸·IÌs¨›rÍ>e,FnÏè ˆ¸çªäË o,èi FƒcGW5EƒÓëèi3tKæx9>ÈO‹Óä1FBjC&H]¸×¡iîĞXËN•?³°W¶;öXZ˜G=‹³Ïæ<ég
¯ŞNÈÅpŠ@«a‚*(¹úºkÖxÅËÎÁm…Q^­@!ÇcVbÍ ªÊ	V"‰R[DJ·n0‡\+õ”ß‹Gµ:ÊrPt¿ªıi×fôf;Œ¯B†á-®fÓ½™c¥·ûÉà]2	ØLó»¶¢/BÀœDiZ—Ù9„½´°ÛYb™ ¹Ä;İ"üf½<e6 ½ÛÆ£gİ6¸£•'f¨’¤¶É÷BÈtx0Ö2(†ñ}’;ö·´£çÊg‘+è¬Á¯$ í=˜~>Z	‹âˆˆõÏ™ÿùŒüŞ%5§*µsÛ=¶W»vuš¥†º^8ï'n\K|âyX=9V(Áô3²ôluXßñŞ’¸-&¬ƒ'NùÁ÷…«`AùgÄSs¨ÍKÇú'‚ Z*ãš8:Õ“S’²úÎà¶SOÇküCÎ1{'„R¨ÑÁÙ^N´ñ¥¨ëÔ[áÎ)AU=¼)T3ÄÉİoÒÂ/>ÓF×X¿÷ò…ğÜT¡/¢ğƒVxŸˆÉÊ5RÍg;¾`Ì7«\mlaŸ%a’ØvşîîòëŸôõò¥õÆë³¥E…œ—aêø7—½Ü—¤KeT1VˆaˆõpMwÀ9K©KÀ'÷·èèß§_¥„K=Ë$qpzN4Ï/&Ÿ¿¤kŒ^¨ìşDÎİulr0ø
(.ˆOµĞ¢ÖÅûf# ¸5¿¡sEc>xJ«í5İòîw£~¹kØc’»²“ø|‚Îê…ú_P^Æ<K¤YU	Ï"ùñvGïïÿ°Ä‘ùDŸß4„<NX(¶%ì®—nNg(­Ó5äê÷Á:ì1|&ÆP«¸QfÛøuGKæÜ«<¡ƒVMOÔè‡À¯HŞÒğ®æóE©O(¬›gtÛ2>¿‹vãl÷†2÷QJğqDkğk5C2U†'ïØ?¼uš¹Ô\° ±8Ójv|}²¥‹<Çhâ@İ€Ïº’qT!lcØ’¤˜Dî&±Ò£â¹¯:¶5™|e.,5Aä=ŒÑŞÜxîNV!¶opx³P¾~woÿäÜVÆ8Fu±Z®#§LV­¯óğõ„ãŸVT±Â#™³Ú¤”cwSÚH˜¡¥¬ÇŞzÔ:–³Ùe7şeë¶™‚,1‚V¬©Ö`-«ŞÇía¢‡ƒ,¬Äm¨"¨:ïE«õY©¬àºãK)Ş’w¨ø˜™ÿ-Õ‚ÏaG?;•I›åh‹˜w«â¤¡@WZcµh‚¡	7	OBª€ŞÓŸH(qrà=²ér†”ÇÉ¡uäÚÁXMB`E¿p‘eWç‹ÃîÇí·Š)Š…%OÃòt6F•trT›‚‹WYpw'Ñø±òJófüœ}4Ş·06ây`ÌĞ²×pÉrz4­BJ=›¼&“nşÌ¨7ÖÙUNL­‰a^Ta _}‘îÏ¦Ewmâ-:Ï%[¡ËmÈ+t¹1âB«ø®Cô0üİZjg®ÔóC£ö8LøËBÎa°M¤5õ÷ÚĞ¦!•0<r´å±öx7oµƒl3À™¤À <á]òœ7s¡¾&Ÿ |ùã¾í<*“›<EQ$á¨½"Cï×¸8ğHå*t>¹ùæş°UAË¯ˆõqBl•DidÊ¯èıhD@ä\-¨®P1M^0š¤÷åi¤É`NÕ½¾ˆĞÂèğ9 ¤‚Š³]ñL2TTş5 }Yrñ•k]QÖÅºLDíĞSã.3*C}×7Ëh0Ò(GYW»%/ì‘º\AÓ½T3‹
¾»+Õç]{Xçö—ùÕcI~«r³TWè*Èv$óäzø:ÛŠìú¼)ÙQÏùx9	˜JŒ| Ö0¶t+™ÀåÚºFp¡qËr-Â£è<„W+?Q
¸Ë¹|íám?oÈÙË£¹¼0N5^<İ‰ m®wöÄŒè_û|­·õ3vu >S%ø~ßªE;g]å„”•h+H‚Å~e°amèïˆPîŒ°)MÉèÖ:m@|°xùã2lÏÖ º}ÜË÷Omh,İ2ôIšó¶f!¹õï8£[E§Ñ”!²SÇ˜ÄèÈëJZgÿùnÑ­mS¾ânŸ]pé)-¢êmN iı
m¥êúş"e0ûñ>ˆ›Ø-'ÙÅŞC\¨T¡8eT€:mÌ¦ àHHmé‹¡ìí¡ñ¢Û“¼¬+5,dà‹okå‰6óÛOÕ}Á­¸fı ÑQ+Ê¥öDù+¿GÀzTPOˆ©©¶àUE]­¾°u|éš—=0èÍÙÎ†%cîàl^µ¼æSñ­ötã§îêMQŠóSö?göHÁÀÎ¶é2ÿ(æ±8LÂ$æ’1}³.ªRĞÂ$ÂMÃ1}6ÅÅéxK¯™¿]ÀØDæÏÁ$10H‹ÍJÂj©k h]2TcËUñ+ğé¥,Sšq“ıAz9¡6×këVCRµÜÿIµújc!LàZD"%Ô} 7ÎÅ<?HIÛHI7Õıß'»ÕÔîCğBÀ]ìBy<†æm€B

íc’ø €<(»ÜÒñMép@}ş'†*3–ï–ŞS<S"Zº4IÒ¡@´‚á¥éÏÖ»ÃôşÂz´çûÒ{óÕHwÃœ!ĞW²gÙ4oyªY³)Á)ÿĞF¢W%‰q?-1şy+„¼·¿ˆ2RŒô¾5î²ï§=ç>/p·íÍõ8…!#!>tçç)ÿ-?¼ĞXJ@ç9¨±Ì_#Ææ´ŒÎôšÓ÷ğ}r‚ãèYµ16ãyb‰¬ñwõy‹ 0e(é‹³Uş¥;CÉa³MÕdaÒ¦™Y-“o&-‹q¥% é%æçB¢±OıÆzÓôAâù-[~$ÓúK‘çud
ŠÃ/“­£ÙÙTgË‘Š©o`êKrf:ğ‚"|Âr9ˆi,×«YtqUäÙ#˜J^²˜VUÌ£ç–+ïD&W0A%Ë‰ƒª1çòçÌÿş½3ø)(8İú®²æ]¬‘ÊcXDĞ_S¡#K¹ïãï×n®,;lÌ‘¾ÿó­S)ğºã…ç. ’ñR7h…$·Šl×À%ÊbòßÁbx|?¶êO” Ú)çí2åFÀÿbÙ8VüÁ4™®ÊÖµhœÄ vkO·ê^û%ÁÓl`Ş0Aşèş6ê@‘¡,Î:n²$ÿû®¼;÷èì”“Káçº·åã”vT8Ù¼ìF·ƒ%ÚÇÜ:ú^¨ÚædŒ«AîŠruˆªisÉ†<æñ$nOÛ>>V7 fe’ÂŒÉ«–”Ä
ìH^üv¢;!Ñ$ÏÒğ5ôŒĞ¬ÓdŠòöj¦Ñğ¦æÏÀX4[Áši"ß {ãQáFh¹ÆŸ~@½49GŠ§ƒ¡
/ëß½’Ÿè5l>Óel¦İ1&­LÅY“Ví-E00ÌXšÀØ©Q/8ËÔ)PG‘¾‹Üxà«Á«5ãè|âŞ«6/¶VªFå¿c~Ç’¼«äÃî#„¦cÏ°á?æš±°(%  `[aª³D¸ƒ÷}³ä}¡˜DK)©hCÑëîn~!XŸ´Ó·¾"’Èù™
2SÈ8hOÃ‹} ÀÆ™öMÑ5¤KC¼S~Vß §VcBïê™‚]7pÚ÷ûÎ0¶TË‰?}x-×ü­Î¢©?jğqğ§eÙSÈé®¼{ç•ˆ´ì¶30°…Íµt©My“œ¨ùR;ÏQMˆgZ­ğØ’3heW¤‡s-Ö&F<ëtÜ_Ğí,üÈ#Ãèc'BáÖFZ§(›!µ'u–ÿqì´öFßÜÌÈ’3Ò.²p²G+¥ÅådR0së¡sµ¬ÓndL.Ôò«¤¯µ÷ĞKhÕ•j.*’…>İut# zX·ï£%–Ğ¹#ißìóx½ÌvøZ÷ÀŞÖWnô£r{|§¾ıTúŞÉÙF¿üfyS%4P]ëâ}(*Œç×D}%cn#|ª³CÖ:íjÉ{ã… ‘SÓ;&HG p¿ÌIYTJ,IIÛ·ænªÛß8ì¥(iÎMøÑC2Õ¦Š}?À5ÌtÛhÈRg—wRùİ1ÔOC²mã¸<m¨ÅiœÔ]ª„¶›.‹Ñ(NŞ&·f£â=éz¬¿ çgvïÖ¡›D¼‚£¢	X>şç”=[G]ˆº~H¹öıŸİxÂ(óUa–g¿R§4¶æ],ö;ÅıC‡Ì\ uÑt¨]*.»I8–Dèºè/7†o¯lİ·7…åv^ƒ)n¼åc©ËI%G)]>òXO%ë›ÂJÒ
qÙ³ä†c|à²Ü+&_ûéìÈMÖArùèoÚ±´P˜¡H+Ôä‹²å¾xÕö>ÛÛî¿
­û¨4Ç GJ‚ğƒìHäÌóreu1~w›ï5Åbô[s²°Ğ†ÀpƒıËÑbHbıPZKRwÛNV±Ïèúª|NÊo@!C2DZ=*{~õ:!B²’y»˜¼šÙõG¤‘(ĞØ¼A5#Å×Ê]¼Gn¤Å2«ñŞş`eW}Fÿ[DŠVŞ @_?ëA´\³tvŒLGt1æz:øŞzZŞ4ÁnãbÒcµ¢K¢Šâ…wZüÒ>Ê;rQñ[×'¤:”ûÒ™YÙ…ÊŸl_lÃ.º½¿|¬‡¼Ÿ@ø›úöÃ®x€<{y6½Hf}¡FÏñµmBR¾'³ÌGÅ½»â¼ëÈ\«Ã21dkº;9L–oâHªCUhùñ]s†š#Ó“\ÚÃ^(Ÿ—6ø;\;ïÍ”³ôAãïØX“Å	á‡Ø…hr vòªÙÏã"îšp¶ÇŒçø,Ş¤pêçJo_tĞ­Õg-I^S(0/OÖ)h=æF	£L.œéÉ(ÂûI:ƒ ¨²âï’+É¾;Düx$ÁØürÃÒº(‹ŒïÃ¬ĞÿÌ£0(WôwDoc‚„Ğ×ó¨HïÃWşzÊª«ï»ÇèÍ›óc¨2_êµ•¼9Ã¬¹ÓHL@'×‰´Ez©X85fYÇ³Ëh*¹µOÔ+H†Ï]$ªÕK½2ê›!LD¹Ğ§\;ì«P&Mç„¸qräª4€ûnjé3¢X@²Ì‘GƒëïÚÄ¿ßºØR‹ÆUÉ³Î¤ïÃû2ÎNÔHJy­W1¥Ôdj^ÜlCTBé™¨©Ğñï…˜se‘ëU±›É4ÖÌÊø@ìıd$f8áĞø¶ìÔAmĞ	!F©×®(ĞZ¼_¯.aNp¿ª¡ãnánvù;®R8«$º7,Ú¡Ş¦¡8Ş`ü •ß:Á“ -]ïÍ÷êó`X<n‘>­§u(BlrÑ˜6Ûp)x XFói¬`&á±:µ	ı´d0GİÉÎ’¶mÂŠ­ÎÙŒÍ¬Ğ6ğöã‘ Ş)eËé7G½cÌ8Q®³¯—Æ»~†£ë÷n×>şuëÖ¡ñ³ñRdº¤]uãXŠÎ¹^ã¶hLEŞ?şâ’ÿÙo…"'.¶½€Ší€´cO+oúÂâŠ£ïŸ/ğNHBZ§¿×tråm Ì@Ã²Q¥)$y	S³€ˆ'%bAÏ´Uu`¦p`7‘"ü¼³ğ#¯ˆjØqYdakõmL˜‡“	5<ˆsºdß	x$x£NL„7\÷Ğ»ó6ÏÀš †oÊ1{³KôÓƒ4Ì¿ñlÅã*ö%ƒúáYz±LIDL‡Å2÷š5œÜïÂÁ)ÚŸ.c½8…èàı¾ƒù˜ÙõŠ3Y<*H¦vÓä®¿Š'>Á%V Š)§²÷éË¤¹zû‰m·&ê´Ì›Äï2b\ëóÔ™• –š¤Xı±ÏÀJmşBu…ğ(ßLõÊ§Âqò›ÿfzh°·
*xäÔfnùL‘›¥81ÉN7v½ÀàğMçÙ83¬j½åoZ€"ÙQ§RhB¸— q]Eé~['|üöQc£¨wmª…ØóñÉÏe^ù*í¹±×¾}¼pjk\qŠ¿cÒåÆ¢”®ÚT÷•%¤ğ5êö&Øâzì- ××éUWgÅğÒZ/áªaysX¸Q‚g›İŸ0{£h>Òú$_Å‰rú´"Ü¯jó´AXCŠØ),{œj†ó¢œşêføuíõì7y?óV>ÚœÆ~ìº`×Å›òMú¨zËO‚ëzö½€y»cD[UR4£;-`¥»P¡Û*;ó!·îLIHp›#7¶¢óZÑg†
ıŠa
T¢€[ş7LŠ¥£<3”T§§äR«b¨É n“€=ùwF’=;3£Ş£É›mÃÀ*'NÛc`fJHá¨H•¬X±Et8á¿DÿÇx“Ê§)ŞèÆkˆK¯,¨È÷À8#ÇÖ†®§I¥-)Ô$¡G èc´jb2ª¤“’´ğŸ‘§Pb&ò
FÁ·Ñİ†®µe!¿1•—ûÏÏ•yYûãCc^µ²‚{œ3 ‚!†â/Ü™	vvŠ†¤µH²öÌ
/¥•
1Å¹Fşlo°¥õ¿—`–"2±Êö'5&¿	Ò¯H44¹Œä*ˆç.PbÙºo4'éôB%ÆÈ'³|(¶YÉ5w'ö“V.`LnmèÊÊ•Ò>RÿÌ¾ÇTGÃìÓ “D”åÕä]mm¨ì*µÑ®‘.0ÔÚ…4A>²Äú”®™Ò	¬¿­°¨Èn‹iüâó±•+#f]HN/ê-öšöµté7¥vîrÇÅ‰Ş"%Y.ú+OõßÕÃT(‘€Ip5İ9íÒ¨{òºIœü|ƒ…I}şÃ/NF_ë&ğ+ç53’pÈ$ÓŠ¹øÕïo<üĞ Ğ#ı$Ä¼x¼wt2×%6cÒp‡»²ŒkÃ"nnÎ »‚²Pª¨… Å±,NPÕ¥¥eì+Ã}c¹	»ìcÆõcAF)àA2ÇfT¾|Êiké0´™^‰­Iğ»ÖZmpc;ô¦ĞOÏP9ÀÅâßùû€9H öm×Y Rhã˜*^v8º@ÏÅ^ çú´Z~WjAHÛœM¡ı]üW"”9¿X'ˆ?Ô_›²³™G &æã½Å£f±5ZĞN¯•ª:ySQ†ô'ü-a|†„ïJ4—Gçîµ”¤ÓÚ2-¸/_¦öw	ÄvğÆmu–ß¹sĞlÆÊòEQµIí¯¿Q¬û(T‰ßÍ€ µ·íÜj{Z‘'‹3³4@«Œßù¤Òòÿğ/D/™©}mŒµ•iüŒ’rÈ­·µk"›?”ŠjdÿN=Àû¸	ã@šüNa¿Y?ªŸwÆl°Ä\İ-´•c×G”+ZS¡P2/AÙq´êGó)—)3ŸƒRÇ~ÖAy„S¸î†õ®,Q(Ä0Ôd)ƒN õÍ¨&Sk$pŞrs\â¨'ÚÒ¥²Eõ{[R^Â×"7H‰•`5ÄÁ¯Æ]‰…ofjÑ¶[¤öıí„FY÷PåïÚ5ƒ$ ¹Fvoå²â
0õ‘æVxš \J’+€5E½ã
~Hèóš‰ìÑP]ääÌt)P—VåF#]`hN€åL8œ]©È³O]Ú¼v:Œö3×nÄíûÛò/±BÍ¬¤òˆÌ×ä›Ï ˜iŞ!˜EĞ´ju@ˆ¾s°fC×ÁÈ19ï=eYIvúc£ìg {ÄÉ³ÕÿáüQ2I¯âÊ&n®‡›)P1¸”ÉÈ]ò	÷ÓRİµ]ãˆ‰|î›o…$3¦QıGd†oêoØîŞp_’õ§a"¶íçŞúñ(õE*AÚÂ_€‹²Ş»ı€œk´]g(Ÿ»­Q®÷~öQ6GiÌ<BXm¦¢á¦XŸ< ‹·†ÉÃÅËEõØ5Ù,˜ë‘V±Ù}C_˜]Ì*yÔ©¾—şÙÇ¬¤f|³_…¨ Ñ
&6ÅAb°h­ş“Gæ¸¦‡Áş~Ç£Dâñ-dŒ¿Ì ³ª{ÌÑÂYrÑ”^Š(R–Ÿo½}–bHåQCcµ&¸T¥GË´F­££`£åDr¯m£óİ$·"ÀØ¢BaÓV³¹Äh„ªşÕÁLvü×©©(¤_Åİ|Õ³Ü6SÉU52÷ºÆ[õÙ œ#÷vzH]ä.ğ‹’Â¸öã}dlmJ£páP ƒB¿,'Œ¯È—I„İgë˜—œJRD›Ïì4†“c!½2½¥V… …¶B´7ºãºzïhÆâñg)D+¿cÿ>}Æ¾_GgúwRŠõÃ~«<šY¸¦+¬_g$öEÑÈÊğ»ßn[ªM0¨üâIíû–ğZšG#AœÜŒâŞ¦#ù_ ;ïÍó+èêG ùù*•R·¬œÇ/Ğõ¬ÛäOûÛÉ7ŸE×ÜŸ•š„°~;5<£•SO@‰gƒº'§œVâ«(ïŒ¯ïdƒgy»ªVÉÆrLuÙ6æY ¹–¹]¥C3y·~4‘<ÇòœxêuEinš†‰¡ã3[	OØ|LCLzºî0o÷ª»â´$Gü‘®Ä®'TB?ë:uß¼qïckízc‚(Ëi-LhKÊ ôt 0³I |¥ëøIô·Xsó=Ä¢=¹ü>!:qS*Î)äG$ZĞÕÂ`!¬q_õm²6¼Nı çÒCúÚÚ}UòÇ¼o°Kı ñ9æ’Ê\hr´È7¦cBèfÔŸ2t…Ï•¹v°¬‘Æ)Ï™Éä‹ÅÈ.7…_X±táú÷NØ<ğ²ŸŒuË¸˜lCÌÏ‚”£;Ga˜o¤-":œÌ’Ìšà¶4>¦@´—áwˆñ´*öl/xX`hô:‰û1¶|ÖÓJ“F/í™LAE”Im®~Îœ/ÉÊ‘ƒBï_pÀ¤×ô¿ˆG˜g8é\'ÆĞ}ÿKñ„yk¤$ÓŠ+Ãs%r«Âl,†ƒıS[æ­zdÑ#¸	ŞU’*.÷MBU]éUŒúÌ·_:~xˆ¾­‚7pO1‰é>ÙÕYãqêèÜĞë¢ŒÀn-¨Çê¡gQJÎ>OŠ:±"ù ¡)k8«Á¬Ä±IÅÀUX//-	RòŸ™a†xªÔ…çw.0e,Åı „ø×0émqM±óò›H£iÁtöğ<Ù‡úY«ñ¾a
Š9ÆøŸÆ{½3¤X»†9ìhDÖ`]Ú3û‡C!C®xé2Á:Î¶¢úä¹Õœ©QĞv8pp‡ç¬s¢£ã’F_±›6%£) }É3¯±]Áşn5KZŸ\Î†RøŠ29Ÿgø Q›ä
ğ:ñdó*šrÒ¬dİMÈğ«"ç† ó[{O{I‘]ø«‡B“¥¾	?‡[ö±Ÿæ[5ø€±…çKŒt>ç\\:†¹¸{<­§Éâs	X[(˜ó™Ä_—ŠÒ</ÿàÖDWáIÒ/©’°ô€šgnû¯%y>-~˜ŠódÓœ/—çh‹Ñ{G’:@å9ptÌ p¥“ü)6‰Æ›®Œ:Ò‚ß‡,BR eÜO.ÌöT[Ã—û«P’e³à¤TŒA‘*ĞQU
‡ˆ…§{Â®ãë*÷¯ãyèeÖ>Ñ=7vØ¶4ß=&YUõ ªV’‰ôÓ[ÀÆy£9³ËíòrçÆÄK÷ˆƒ×ÑN…/;­{ÒNO>­šûKDlYĞ<{~©^
Ä7m&ÆõQ‹(;B=·cò–=ÄCšx	áHÎĞ‘İE#8úó³~H…Õ ¿c6€iCÀ·HoÑ›YÂÄv"ı^¨lÛ|`Ê¥'ıÌ¨Íş–âÙ1ñ“UdéÕVsG}¥7•omMáî³ÆBrBÂûƒ-ARz^&»¹Ñ>/ş÷9øHQïÖ¾1 â‡‡×q¢JÄØù·Ş:©?¯t£8ğÌêúæÊW‰ƒÈ¹¸0s=0 A™˜S™]Ëbwşß­8Ö¯fAå6à–Äo![ö@Ş¹K—ô“GğŒÿô:Á%÷ì"°ÉB|âÇÎŠHÑOí¸f‡\xÊv6Ê2i{ wÆFpù_ë9Qn%á@D­M8£ÖÔ!–¹²:'ÕÔûğµ…1¸:X^$Û“„¬?.›îÓÜò¶ÇÒv=•Üw£wƒş;¡H‰3$f/ê^«ìµI‡}AÍuñjIC¡•˜\ÅçŞ†¼æÊw‚‹QQ›…rŠÌ§äå2blj•sÖãV¬øßW,sŠx‡ıöÑJçnãƒlÌäS²‚ì¼êÕ9–Ñx5ñ>v|¤z­	‹˜ÅÃÛ~M´¯qÊncL.+†Vfç_g>ôìŒ'-ÉÆç¯CúÎ€ÍÜn×şCÔÍp”³C0™oƒP?@Õİø3_Åˆ,¯¶ˆéì”§óLxík;Ñ—×•&ú«ÚCªı[-ZÚ=ŠWG9İ¿¿‘’øfá¢æ?Ôæævg51Õ®¹b‡˜ ½wÊ+ã¶bf"GA0Ût$äVÌ•:ÿZØe$ö±«¢Ï4Š¦	f$TšÌÀÚò°=­ã‘Ø/ÃiÍzÈ¦9£Cü¸Pk"O6æÀdYñõ,ÉØûİ Xv`k‰‚§Ä¨PÄ|ÔüœÈç´Ê“$£@a´à‹ºq]£š~î, Aû¼±ºáET«Ò˜yt;Aµë®‘2ºaÍSªde‹Òmï]ºRéGíhª»óÄ&ÑßŒ+R3ËAP˜Ù•ïl‰n³îd…-É	Ä.-aë1*ÀU¦ÿ´<Ş2"õ—Lb_M¤•É;¸ªg˜+g.!PŸB6ÊîÆ'YÙ^9[fƒég™œöûº¤%UvÒWI+eÎÈÍ ‹|0jÕ+Wl2jhZLg(OŸ)8iƒ¡x |EåM(aÈø»WÇò-à *×õUƒn¿Ş;µ`<V-›˜gê²A ×¸Í–ğCYiÆË¸¬m>nd¸¯¾=V6”Î8M8&»fÜÖ é”F3º½*P¶ß
?M45·Ñô£À´á{ÌEåö³g«6*ÂûÚä×ÔüŠ½ıeÂjÖ–bú®“ôd9ã<–c hòÑçšÚİ+5Œ?<kÈZ•ìº_0CæÒ®É¢ú¯˜Cİ9Nğ™7£näÂu-V¾ğ#©Ÿö™ EW=Î‡İ'æ"v.ëJ$ŒàY%&“‰ŸÖ
äAe¹“ Iù]{xºÈ—Ğ!Ú@Yœ*B
]Xˆ~)‚wğÖ táP!ZŒqŒDb®5×$½€kğÉÁn¿2Œ$yÜfNšalî5ƒŒjóÀdEEüÓŸZZ Ô–²ÁÛ›T¯úp½¨›\§+\”uDäĞ2
ÒÓ^•+švGĞ{ÄÍ:ƒÎ*Ù–ğsïPcİykK `Ñõğ:6$š„ñ1`'!öõ›8eßúKµû?ëSòsyğ`Niå}¶›Üma¼ĞÍ¦níIŠ v÷”¶œÃ—L‰Ñ7ˆt š9‰¼ï&ÕğöÙôã(õÄÜéSû°àÆZ÷tyA$±>Ÿµ|®V¨™ÜJÜÉêeùE‰[Ø{hU‡Š†ï#¸ïHüÈ»ûÎC®F(r;³Cå’öiA@£ß¤‡ÿF@ÅµéÏ2	×³¦l ¢dÑJLª§Æ™ßUssº,'¦üæñw°4É +v¢œÍœÙÈÅG¸y„ß&û£l£‘6’pö:äƒ]²­|SDuëš4K–Ô'÷»óºğDSí±Å+úÕÖ¾[b¹§G\îÔ/fğW"/f]¿×³E>±Çi„ßëÁÍìùz
w~İ½sRa( «TØÒ,µœtUöÀ™;=B™áaèEÕ
<`±¤E¨îÀ*In½ r¥‘)<¦$ÏÜC‚ahÃò;Ğò¶ø;ïOÊ1É­¡eäl¯®7:õ´Zd?²€B„ëóš+â£f÷rjí\ ß¶\Ô†ˆj¤õ›ªHw2 K-÷ASåñµ—.İiĞK²…ğ;m"0¤ËAÍ©G…¨`à„ŠŸ»)±= à¢‚yÍ½†¦<åXùJŒü2®O†;ÚO¾Ö«ÆŸI$¸ÅöÊŠAXÊt¥”>Ì­í3Ø
Ğ”ÒæØ©#õq:bT÷b(Ü¦Ög&1mùã\P_º)ÀÎ0G»Ûi½‰0+À^{%¨¾ƒš¶Àõ )¶gWP@Œ=òQ®í¨‘Ÿµ§B·Í^PQŠ	3‘ú$[íX'0Ã)÷®: „²_ øºx»zcû- £º%‰4‰ˆø÷Ó:\’Îßè^jPp— ˜IÙêUEb¿¯fÔ« eÿØá˜µlêµ“ÿoù×Ó¤tgOf¢­Ô%Nöí”°OMŒ‘i>AccY)"L&zÔ&¤ü”î&Ùé´ÃP1ù­Ûc|Ã¿-Ê8ünÄå¯9`´u<bN,aÕ¬ı8ÑcÖGëtC½…·‘‰ìõKëÀjXÕÒ”HÌsœUy§¦ô@‘æSLSªşğ§x¡/Ä¤glÁœÕe/Øä¸B¹ÏyÛÒ™ VL6ÚÓøùÌ›_á:îîÚ…P|ó5ÍàõÉB§ ïHŠqyq2ôDmI1Šù	Ÿ·—†H÷ó¶(¿o<V9ñ^˜2gÆr<úˆ^Jt0|r_H=ñ‘§YÁCˆ8%é{®<Îi¨L…ÉøÚR¼ Là’x]í³’ßæÔ(VFG„ÌÙ]—A‚«8ÀB›ug ó¥/¸tbÒİÒIšog2&§Ûæ F0·S—¡ô`Ñ³–ªîƒ÷CU€˜§NĞßh¼ùI3¸	¡ÍfŒWcCšì˜ªÄ §à‘&?©¯.¶†$šËÈú(Î"` ı©ó{ÎVI–àëWœK.@ÑÈsc«SÔi¤’£ú'Ãû½ã’«­AWîdõŸ¢ë.†óL¹WÔ>$9?¸9êßŞyñÕÍÍñÄXËg”+ š_@Àì¡Š¾Ïğ0Iml‘]¬´bş¶Â[:Ÿô9ŠãL+ÔŞd_êPÁ¦šĞ'éú¹i`¯Õ#©@÷©=µBcÙ7q¢9ñèLÿû±£y¨ö“J%¾pÇP<şçˆ^2#„ä–Nì~Öe÷Zz0dög}*«Š# \å•â²1óSjı#˜ Ÿ‰í™­©JB“‰i¯²®´I»±¶)øv›
ÒTaVš6 PÁŞ>ëı‹L?4>ø±EU‚>)õï.2”{âÈk'òµ2P,GÑ¨MR’¸"$ª¡`%ŠTú¸‰ôd^¤‚	ÍFº ˆ÷¥ B –šsÈ‚B—ø;]`«'Hç³¨½'*rùsG•XÑŞ4±l`ò­ãhŞÿğìSoyS\e8,(a¯±^Ú›ûüKf/ty¢=çp‰J]n"Ë„˜rPø×„ 1?*;|c¤G ¨Ï€™FL{±Ägû    YZ