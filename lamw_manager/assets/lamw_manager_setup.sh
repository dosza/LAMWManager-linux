#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1016312941"
MD5="ea9ea567a4d42915494970c72f7855e5"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23904"
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
	echo Date of packaging: Sun Aug  8 19:59:33 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿ]] ¼}•À1Dd]‡Á›PætİDõë—Ÿ¿&Ïú£šmµÆÕsk}ÏüÒdbİûé›‘¨cnpÖûë”z%$pÒ+ñXKxø*‡«JÀ¹¦/
SZÑ|ìH‰ıRl·ÔÔ)é5«Õ»6¾é0µÜ?ş‚ ú–×J@fàp^qê”üÿİ1r½¤½¤vŒÎux ˆÓ¼	Ê:¨jhsÈš¨s9…xf˜¶oq%¾n4ßóîÉö«õe¾Ê£üæ‹KÿÎÕ¯„µı¯Æ&#½VRÿ„É¸x ùYd²)A­&ÿ	-=4YÄø†/e•wj¹KàX­’i­”PG¦¡õE°­TÅc.cJ–¹IáP<@	›_ğf7›ÛeH›/„öô]ò¯±!Òÿ@¯Ş1E™ü‚3Ü¬¹Ü	PÂØé å
n›vrwg®»=½s´:–›ª‰ÎX×Hv´ÆE¾•`ÆètP # ¦§úDËÉ1ü‹ùù6Áº4	´Ó©¾=Õş=”Ë
 ;Hâ\#\R¹òt­üî|Á—¾JıÖáhS¡\Z,{qk|ôi\Hûyè¤‰˜{‰>³çTOETgğ)Aü6–Šö‡…7µW¸¦¬fúP° >…"™Í©#U½çDš7Ãù|[àºÎ5²]ûYVmú†K¹6£Ù2$òÕ“#’i{úé>Äb×ÒUø§xW‚:·™im5‡ˆò,·^ÃnYƒé/ D¿wò|]7:,”EvÌ|ÇuÌë4Â¾Ô³®âm¶†~°’1rÅ&„™Arú\wf¬“¸¯3¦¦±—¿4W“GIŞÒ†}¨ ­Ğ ”©]fv‰Ô\ÿjÌoç]÷ÀğÔëc¬ ,•<jß(SŠeÜAYáb¢ŠL§1{d9ZÙñ3‡qt Á~`Aå¢Í§«úíË‡‚ë8o|â,@İ7<
ør±¥ÍTR>öÚ?+3¶r…¦WB~óÜ$„ ÀÇ!;Õ¢#-Ca™2Í3ØöİŸÂ,'ß}|¬€­•¸Drß¸DI³Ç]ŸçdÙ†œmxw“³…ûÁ1(\´éu{~Cš1šüôŠ§¤ñßXĞŸ¼tu¤^Î-"IV£ö0x˜ÀyÿoÜL¦ÒS%áø™F
Šø›ßë«{Ì»3ÿ·F/}š/}W¤4áĞİŠ4Ğ³İ?ıUÊäÔ~„ymÃìÂS7eZš+•cˆîuÜÀ¥œŞk´ºàüBSÑ8İ_G4ï–Vh€É´H<FB:!ÄfŞµVL¦1ÓD±N»ø«‡ƒCÖ– å¶Á»ÚªŒëÄİŸ¨n‘Àtrp–ŠŞw›á—;®¤¶‘‰kÂ7/ËèY¶ø/äZiA}2 dóy¸–/*QpëiwEÛ®AÜStÄ,ı±1'hş*VùK–¸_.öÖÁjPPã‚ÇÅXÖÃw„ƒ€NÀı6Ò²CÒ­Kûš5åÊIpÏYpÑ.«SÀî=¤C~ˆtCd&Ö\Â7Ä(†I‡ LÖ{±n(*Üã½6óLwC4Vİû|ÏiÓŠE)Mã]l^b¤2nà›7mĞã*xÆ´DË¦ÓÕ.Ã|N:î¿aI/Ä"û$“7Îaê
XR^e
eAlÕ½7~'¢ÅœöâMN©V0ğ&ì™áqÇÁdÌJk{õÎ¨öRCOd˜çz&Ñ$BˆOÙß:İñŞÊÃéKÕ›œ–n‘XuÉšÖ%Â–ÄñètÍ‡)3cxŒˆ—šoämjÆğsW~C8u
ô\™Âñ¸;û<åİót­Wà€ËæsÌ¨ŒÏ ÷vĞßCİ¼Ñ+MÍğ€)ÈxˆAˆ3aËoiJJÜ!«GÄ7ÖÒèÆŒù»
áfœ_[‹¶)@ü€˜çÄ“Äk[åŸ<÷Å'/Nõ•$R²?³6¢³§xq×Xmn²ŞõÕvgÙN$½Œ‡–½.Éã©.7g‡×ß ä+f3Î±%bÒ„oùÜvtzwgwˆ,^D$£Ü¼›¦îÓ…eV¿¯´<Óœ(fn¤±º·ÊÚDµäL<LÌ
]¬ºIößŞ3×„Úe§"İqA/Ò‡„Yg^¸kÚj¥©n‚•xRv¿ó¶ÀäJq?4¿S\‰ªÍKº…QÏ©sTM®®GµXï³$„"nĞ2ı×ÒàF2hö{Ûpw…îÖŸ®y½ı,½Bâ³÷a>‡ºÁÙñ¬2¼™h—Cf¯¯‚Ô¿‡iNt¯A"c‹ƒ´*—9h*Ô‡B»Òx$vº„^v1håo´~Edq*«üV—È.“TQU‘IGé½§c{¹´eœÓĞBìè€„¬%Š‹Œ|¦Ê¨H…6.ˆøŞû’£Ş:ŸS«°¬›]Í«õ?ızË6s}—Ç™S}[î-¿`İ¼K¯`F>eQŠ": Z„İØO¥´—ÌPŒ¸àwbL¶œ‰‚ñ”J+o2e4,¥)wÉîó§öŒ#ànç Œ™ó,px©¬Ñ€/£Œ%Xßé`¦2=*¹ĞsgYİÏÊ0·ËÇÅ÷I*ş+(ÏØhÖ@äîQ”i­Ÿ“dÅØˆ»´o°©«ÊW:º–li±‚nÿiH~u•1(ƒ@ tÆSóö©Ÿ¬WøŠ8Hm%SÆñÂÉDg	&pKæ$‘x‡#5áËx¬Å}÷,=‘`ÌÍë—­…üÎá­Ä1åÄ¢G…ß$b8†O€Ù„K.3Ë&HWQ1ì{ë õQö×Ğíòb*Ü:ø›±'ıÃ‘á]  EËÕ(YSõbNd¶:ÜÒÅh[à7íFÚœBbüâöl¹^@.-å¯mÛ¹ÑÛ€A k5 ?BQH&“¥Qô`Ñ¥´«o»Z;w×¬2¶š .eh£u.âÛÚë•´¥äõrÅÜøè%2d½–qb«Õ+3î5^“‡Kº€GĞ¡ õm½†S(ças‡çOªãY¢²¹+ğ)‹Ñ‡«ş˜0t®98Õ°«_öøÍû"rò•U Ö±ób0=x4MçGÕ J$wl¢ÓñœĞå“À_
]­¥ŒØx?Ú¿½µ©¨÷$vÁô;„Îù´lõ(CÅÁ7³^:tŠ‹¬‹ê^2Ş	ØÙªÙ4Bª^ûx%A2”fQØuS« t©¡XbÓ’bŞÉC®gç`õçê=Ä7Zôª—c+Àuş¬š?‚z\6ÚJöhGƒÏÙ ¨Ü{Š)z/'WÃÀÀ“ƒÄcÄyÎ‘^º9—a.~ÚIàAµiÁù¯öe |ôksÁ:uµßs¥/Qön¶(6‹¾\ÛÙYÆZÁ+…ÚìÜMf”3Ä8(¯‡àµ#ÿrÁ—u<÷öäéĞ[ˆ\Éğşò8±âÑ<Ø²Ç@BéÛã ½;BŞ>s×ĞÊ ğ¸¨* êâÇİ?wö±Û'ÀY?¬RR³ÂO»ü;sÇím»‹ö*,™„«ûvµ··>	ñ#êöhçMú41;21²4şÒxçHbíÖÍJ±IBSoP²¸–*¦@ Wó…§ $µ¢€¨bÅhmš=/86#¹Ñ¦iç"ó–ºË ªCÇËë_¸ù"_¡f@·Í¿åÄú,3/·ÍvXÃı·üD•Ç³B†$:ó³2æuD” =*:yò·x²´PÇÃÓè‘£Ÿ7‡³¨œùûj‹2X½å·u›c•;*`¨Oe^ñ\½®½Ã»€M†ÃŠ?d?ØÜÄS¨‰'èÅİ°ğ9_w95'‡ŒV/ÊÌf3z 4ş.­„w`¹½c½Üg§ê¥Ì€—{òÆp=8qÑR³ÓíôBõ¡º[±$î§óª¢.Ó–¼¢ñ‰B¶Ÿ³{1ÿùúÑßQN²2Åš‹yê‚/ßu4oÃ¼IÆàWû®ÁÒŒ–™Tbó¢8¥Ùúø ÄjK{8¤­­ê°Y»Å^U‚ÕCTn¤ëúZ„Çk$}ä`f©>$â­ååTºÎ	[;öÚß7ïN½¶|=>Ÿr«ÃİÕO¯½3	J÷³ŸeT8‰ñ‡~e-1×bÏü5•hn­ÂYåYÆØZ'"¥Õ:ƒ§p6TÒ˜!‘ÂªÏ¢OCƒİ(çÉœ1’şì€Û_gŸ§K…ùœE€‡K " úVùîéoC¯ç.§øşª|ò‹«,¿®+˜ºõÒ~ÒöI§é™8Öş„g½İ&UçP¯"IÃÒeÖÑá#ñ†Q$ş¶‘h½L°eÉ,'ÛÄ½ËlVxù(\[b9?[KØZÀN’ù¥ÊÀ—Ì.f^!SsîÁ¹„ÃÛÙ—Dss±¾Ç¢ˆŠÛÙ¦&40LøTÀ9‡yÓ/ò}ßÚÚ®P²‘ëÏ7M£Ğd0Ôş.7q¶Nl¯õ”p—Ú»zúWÂ‚h3¹†0dM”x¢t¡¹’ âúùâöØ.iO9/	ÖTu™I¡lÅà`§üªCI¢Ö£rx¿ÆSX¦SØL™lqéÂXS†ªH‘¹êÈ	”ü¹^#¯,¡õ<«ç|†}ñ˜“l³ElË,]
À¹´šÚ.
*µfıV/`ƒ£¥·)6jH(NiE¬¿Á&¼ˆÀ>¦Ç¬âu@¦f¢¿Öæ	¿´
&pªÓhãOÏï¯@fÓEß}¨#øäK„8üLûhëlDÅ_¤mŞûXrÌÊ³°.öEMLe•bú”U„íìP²ÊµÎ]çİèˆ³{èu-Öß}ÙÿxPt™/‰m#‚¢v] 0ª—¡¥üÏ+nrBC¢c‡]"~©·ğüÓĞFEÕ³¤M	+¹çøë_ÔwNª*ácuoÎPÎüR¥ÉX\EE#•Z¼ß"¾*S<RŞìoHw}tX·µP{ÖMõŸø'µş‹$tZª]ï¢oÎ^z§bv(?Ö×Òµ§ÁE\àÉXu}Î5¹Ä ueûû)GsÉµd‰fçÿ°|´7àS1n	L>µİÆ&®˜ùƒGêé±¨_‘©B+fMŞûƒâGo…ˆÀ…hMò×oé2pË/e†ÕŞà]d!H@âÏñz9Òâ?<)ôø	«O©Êø¼rÆp‹Ã%¹Øˆúª°#‚è(/55i+YÅ^d@€WÄ{›ùdªv¼xïãÌÒºˆ©²Ö3æ¢Œ(sé§fÓ¤4*`Æz·Šñ@è6Y4Œ—@=E/•%pªÁõƒ-–¤†å§UµDà8XŞ½¦oøÚ¼ÿ¨|Ys‘³Æ$P:cÓV‘.şÒ#ª`“ä­&“½Š“,JÌŸ=81Tlş|Š:RIç1®ît–aˆšÌ½ğ¡Eo8x’u§;z´+Â—ŠCrB‹“ÅâÂç´×ôï•Ÿ¡ÔO’­í$8N¢í-nW ŸÏ¦~Š–úøˆún"—ôÅò\ß.g­tcÙ` 'ªÖiAKİÊyÅ:¼f´W–›ğ»gÑh9zÕˆşè(z\ùq›Âz%®ÑĞÜš•r†˜ì4}µY'&&Ñù¢±de4íÑ4Ã EXÌ=ëpsœ•,ì+êtŒm åÓÁÛ47]S7D¨jOI@ávªÃğhÌ¨(8¿sÖR%7šš™d#š2x^øq§¶ƒiÕVãJ¦:Ğ0—ßFZNõGÚ—°Tgü7?à1‚&M$˜_yW.Ÿ—‡“¬Œ¯zPyŞÏ€rK›ÙÂ·	O€­˜~-¯Éaa®ë˜ıSÂï‹– !ïìÛi´:eıAíD³µº'h,#?FòVt4ñ©J×Š––8‚TYÅá@ÅÀÊ°' $w.!»º´ô9ubø.®Yß0›Ø&RÀıG™Í-Rl¨OVNÊ´•€ ¸j³Ù|@¯z{,lS8äÄœ#½ÇI¡(İÿ	K;öÚ…Öò„«a“”uà§øV©Q7Öh[OZ—…Óp	/~*ùˆ…¼|Í²İŞ,Ë÷œ_—VckôwÌ¾+R*­‹®¿«®^ªT%rX£®”N|E+—ÖqÁn³%ûÕ&‹îB³-Æ¬M˜AâÒÔœY@àJGàÚÓO!¹ËãûçkŒy›6[k†˜r‹SHj5hWêì/Éµ1XO¯øÇÚ4‰9e³ùõaÕQFwğ·	­Ğ6ñ—œ‡Îf^ïñs @t]×ß¶2W~"¸yîïYúmYA
pš4Ôë	rÛ î’ÆGæ¥¸.öÍ˜æPÇrí>bq˜Và¶Åg§ÿÌLç¶.ÎiK%Ç½2—ŸWêV‚[hûhú“Bê•é™§[n¹&~B^ƒáŠX::åÍ
	ş\CüU.âOsH×’L«†ÅuŸä‡±µ2²!?»>‹ZøÔ1Êì¤»OÖÅ?)ÖÖ"Ş!Ñüè_R;S»‘Çå]îj8)çÆ°D8T^È‰:³ÇGÉãòW¶ÿÜó	 ÿ-‡³JCÆÈ¨½Gš>Rã’Œ´êmbşï¡,D7 3,ñ½Ğb¶ü‚lJøº½®åÙ\SÅÔ;[_l~]!O*é¼= '€‡)çßeKª‹î¶Òa»‹Äjüâåô„°xØ;Œ ºû˜õ=öŠq9´>`S–L/JÒ5üèßU[GÖò²ƒÃØıg™ Z¸¢ù˜hQŠÒı9ö*Ö±¯	[-GãqT2öÑG>§¹Ø±¸Óöq¤²Ÿ»…ÁW€±ˆL·¯‘ìÏC°•z)6áš€NOÙ4Û&.R%‚e¶xù¢Ñœ¬[5ó¿ÑÉtù0%œ»ÃY33ıÛó¹§Vv ;xôëû³.ÎÑ\‚¸NÔ&To©'ÉÒ¾öÂ«fõ^Ú‡93òRòÅ¿w¥ı™G%¾¦Ø©—>‹€Úş¶)hmˆËK¤™Ú
ƒµ­úË;.1qßpî¸„r–8ªø„­Q:éÊşƒÉ½Y¨kƒl×‰³v€b¾Ñü^è°ïãêá[ø+c­>o™Ãö™zkêu<ß—pZeØÕ]Ûk¡UÉ=LÓŒ¿<‰zPK‰¥BÍÄ/NÌo=ı­9¥*ƒI‘_LÕ³~c·#~’FŒFİø€”@cEF»ÜÂg._N!i…¢Mö^pº~p$>f “/„JƒWw*2.˜³Jœ:˜=Šë
Õ
[lõÎÜjªœh’eÍÄ•‡8ö2øó¼~àöz‡g-˜i¦†Ø©u{¤÷ş[5X—``YàõÃú7Œ¢efè¤mÎ{ÒùstQ³ºœk2! ßQµuH`ƒ³‘ğ¨5r:*˜Ú9RÒc¸Ûù	·T¿!r(Í?Òå×¹	¹ÌÑd+„5œé¼{Î»äÎKğšÏà½gXªfkœn‰“ÎmpğQN^N2¢wÎš/!E<‰`CYÜj½·¸¿ã–bHyè¢À‘,U ëüÖ*š‹™ˆIHµb93)jGÁkW%»C®…ÒJı¼ÉnÉÓ}¦’íü@®Ù•Ê‹ˆF÷SÀãÍV@·³¬&ßIØ™Ç‘9¼ËLˆ~,Sâ	ÒG$±CIø{3a:$x÷›ãA3Øá:2sicÕ‘Dõ±[X$­RÄ,ê¸"Zƒ¶³GÔØV–vñ¿ËÏL‹—â”iÀX€Â|ò†1ä_…áD,<Ì¯—Ñ \{çDË*2Ô¼ãë£Ãm»rPFÓeÀñ®ÒtüK—ò³ fÅş÷@(*#ùF³Zâ:÷²›Ş¸ŠÜÀ<šä‰ÜB‰s#NR"ósœÇDçJ u¡äN˜# j‘#ı2Íç†$ëŠdb˜2h…ñ2Á"ğU—Njš¤UˆS” ÀŸÔg·bõ|ô˜S?È†Ñ|…=Ó¼½;ÍoÛqÏúæôiÙM3Ì;†êh@"±ˆ¡PCy®8ÀÂ;I*§w7„—%-µ£¯r½âšò ·}ú%Ô&š&áè¥Ü±Lº›»xh-è~p«¼?ÂlX?ƒÙÚÎ¡9¨›¬W4.ÂZ#Ëø€)×ëWSsNÆüd­Tş¶®R°p·E-úâz	>ä5pİ,Ş,|¾µ¸•Ä	‹—{iˆOíc—Rx^S^ó’ŠT¨–]ç¾n« -3ç˜xÀ
t¹Ï¯P¤óŒÖ#x'!İg¥ôÊ<„£*ò¤rÃm^<{Ñùâ¶
´Swùôòİ#	t;Za 1&«šıÊ'e`Gôò×kÅ­+œf=–1¤zvÛ©€J4Â™ĞÄD‹¡©3Œ©÷»c!2Õ9%(9”Ld(&Õ=€ş7ÜÇÒ¤AXzTqz4İ¥HìúˆY6Óf…dÂ®@İ<û§İt©¶çĞÜŠ^I…ÑÛ¡$j=¼©z‚	²Rc«•¼ÈÿeªüéØ(ˆÛÌuñö¥uÎt’:=©»”‚iPûŠªÅl‰ºd¿ÖQéKËî¹œleÓ,”dÄ«Ü€¢ú¯&|„ŒÉ_oQšé&Wöˆ”DS^í ÂÁ kiÒ`»KK°6ß¦›BİÿvML”XN¬
—ß}*’ÉóGOP,¡Fµ`5t=Ñü6N6<l$ùéÊ¢™£ÖéÍŸuxÕ[{Ï
¦ÿö÷8È®ƒ	;+rm2­3Âæ—>ñ“Øš®™Wüùãã§E<xk9â¡ôğtQİç&
!4ó‡;z·ÔÌDF)_=ÖF¬Ç¼LƒJùE5ÜæÌ	ÅóD…Áƒ&÷Á¼±`fˆ2
Ù{áû1ó0=xøƒ’R÷*;G8ø`séº`Îµ/QxIô$>Ú­O×Â*…01Èñ4sQÆ¹'µÓÑ:Ğ_ndÌ{ÅşUx¼;Ö}ƒ[OqÃ¥¥;©ƒoá@D­¨
k€ÁÒwsÂ¡¶BÉŞÏ5İÇätáò£›`„ÜWñƒÔèÀÙ?l&¨Ë!e,¸rûÈİåP„î°ç%}¼\TŞ"XŸc±òŠ§ğñ³]ü5}ƒèg[¯KÎë] G#	r<—8Oï@FW­²IüO™[ºøæ‡½~ı~óÃ´­–§eöÁ±û-]–×l-VZ¦ç¦)Úºæ¨;è6ãÙçFXaŸ#·Kü&~ÑA-/h<4;µ¡ÌH‹”èyÊ¥#Ğ çäï+â–…{›œŒímĞxl³’–…š{æ
ãpá=i\¨»u‘­¾0õ[İi¸Vü,ğÙ±ïâk
}Ú¾ë²éA[˜8¾af§Öæy$œ§2ÏjçòLß64ªÕ¢†©gç ŸP î£EY„²ö1 2µ$Õ<Çµ}¯C3	ğÿFâ0¾TrWš§Ú1ÛY=;N¼ l4Ï'¿ûzÃ÷ö&8Ñ×Î†>æÇ‡àYİ{{€$A»aòı‹©M>}Ûcİİİ²½Ão9ÙGØCÑX•²”c1dûç9’E1ºYœağÖÉi’ø4×ÿà¾ÿ†|ZçñÑd4ß°©éùör—²jEyÚ-şf¹Jz¯ Ha¨ô—ˆZ‚tqÇ·ê#rYµõ¦oœÌx¦× V®Jj7´oˆèPË­š	©XP/6@¸¡Ïœz,¥s‚$cãÅˆ¦æa9×S·¬#²'ñÿsiœó¾fpen
eI}k¼¬‰0¯7šLµøm =Ç·È)o,¹>†‡‰Ş İ¯óF,N\D.¯4ïBÌÜó£a¯9²aù	³=9;Şä¼B~\ğSĞ°YµÑQ0ğöì`ˆdÁá²*ì'ı¨Î-§}¬øßišÁõééª€é~>WĞ¸†oôhü]áÒŠ/C“õ-ÇJá/{çjæ9{‰Ì±Ë¤’àJR><zrğÉ¬H&ÊÁô–¸è”—‡Ñ›WÃbºbeƒ}’ X	H ¦„«{y@¿*¼aÇPû¯ãæ.ßÚ'yÈj_\Ëø·C#îrçÔT x–H÷šg™/ñt?è©ÏĞ.Û¡ûdÁWåÎŒ°"3»ÛR=Ò–AYvátßÀ–EWµÃ¥ÕU æÖÅF-•ûÁ¦Ì”Ó“m¬2…yp+½
ğ²ó&¡Û&}‚¡õˆ„>_˜¥^~Îwoœø„ïÇÅ¥ğRFƒ%2wcíjV"ñÿ‘¾¼ÒsÔËiQ·ÓW| Õ¬ˆ)g‡÷ËkIˆQg@âÜ°Õ¡GmÜ£ré®ãQ“‰Ñ¸2`Á²2Ù•ÅY·”ğÓL,ÙIg‡”A²#ƒü€¹ê:C1şÅŠÚÒzÁ›O…“".©å¼3Ü³éVÍµ²²¡¤Ş …‡…5Ş–5V1‰ƒ°ó É’Á‹ÙS)l!€u¨÷Ñ‘uLÃbQ‹^´]&Q(†Š„Ø•EZ‰|5 j	¡ô£Ô³Q&¸a‹¿·/B‰«7µ;H¶‹Ïm¡"Dè)ı÷ÑØIÅ÷Œ“à–9jòİİK±|y¥°â§ìàÉ£ıĞÙÊşL8.åÌ9ÕEË?£ìÏNV“üÑ€yÒÇ¢ßl«	®^;Ø'BS ´rœ2ÑgIy·Iå€‡úşdB·A‰“V˜®Úî°4ïF8Q—.¦R¤èº¢4Ö uÄ–¾H>U;¢‘Zğ6¢…b-èâãËÔ
­U4g…¢Cjy‡³¼z»ÇOJS¾gd {éÏ¡•üÌ€Œr.cÈ¨åÆêc©Õi4•ï	‡¼:Ù›Ş‰Ğ`ó“ÇÓ“DyÀEÍ9k…£‘ñü)™à4èm*q¾/f¸ß#M²^Ò@4‰?%ßF÷lœræÀ^öP@0zX†;Íû;÷ÓäXÎ†¥ÔŸíˆ¦ğK|Uyiö­,öæ ßí¼(âuDGè™?¯aŞi.Ğ…ôÆˆÚ}8³£‡‰«œCÑV˜O&¢ÄÎyu¦T¬¯–lµéFYù³ÕxâHŒIèƒhÃ7¦MYö¢pâ>ø2´8CZ…ƒÄLİšõÕ_`• ‚ïÆÊw.Èv”R 3vÙ®']Ös:Ì•Œ»P‰Ş³ªKÙÛ‰JôIö%ˆ®S2 F°òÿaÇü¸0jêÎ>çÂäù ;32GáÙåÚºğ·[:×ñás†ÓT·¯1Ã%pŒš^!aA¢v¥îs%ºE?„l3daíóJò$è :’
Tˆ€/E&]¸%(•†dm@ÖÏ¬Eà•—hÁ&ÄeÃfZTy ¼1ÉÇMÆ9åÚD"E/øÙé]›hB ıà!ùe¿ó
ŞDÅİUAcA°ÿ²0én½HK´*p2-ôè;Ô@{¾¹€šñ,ò^ƒ¡ç?äŞ&Ö@^øËÂì
Õ­
èL¹¨ê|9W¾è¸5oïöÒXh†Û+®?–,5¬%Á;cBª?p÷™Lú]!z!Hò…b¥'½ÕÓĞóñõ´¸tdRáj?ãæ,èxÅ³ÿ5µÀÚD`>nGwbÊ[l] <cÿ‡»³ÑÙ47KÒò?ÑÈ§?UÎ‰uˆÈ,ÖI¦±}ïm¼µvX‹Æšcí¸0v
ë 'ÎÍÑãœ	Ú}g…·%º´Ô#|Æ/áYlÁ|ûÇ²µ…ùŠzî¸ BºPáİxŞ¬Ëk»§™®¡­4k£Š{}ŞJáÌ 4Ú¶êçVDåq¤ÀC5Ğ:I‚ 3™LÕÂX‹yrZ+#õZB[>7»Ìl:bIvRƒtT_d@áÉÙØï@JcêG™†ôwj©å:&#ö0¿„ˆ­¹wÃGË¶pî« Ã§…ƒ¢:8‘ƒ†¶­¦è¹•d2X!Ğ+syëÌ¦ø's××·Êİ^dZŒ½Ddkå$‡×lkšt8¸âQ†A.(¤·éÉ<5(™Ş'Ê©Bš”§üX³›ü&N¦¶×Šg}ÿ&Ğ¢1î&¤ÀŠÅTĞ;@ÍcyÿkQØ%+Ô-—ŒÓıŞüğûL|îÔ•é	ˆY0®úJ÷IË‹ƒĞßÔÇiciáµ¾4‰³âñÌîóSgoUzA ’}ãÄ¾fS
œŒ¬u¤¥E"¼’&{»øFqĞp!šøy)–M6?¨²¼XÉïE-‘„áîï,©:¸u2êh±‡ÀOÙÑí» 
·[ˆVÚôå¸²Å½_uÂ5lQğB”Uó‰ÖàÃ>Ò…®RDoG
w¾cµÏBï¾F¥æ:CNJÉØŸß““ˆXs¦™ßÿ¤ÊJ’äÊ1Q’Ãyøß“F– ùl·`ª{Ù-Ízİz‚a©d€'Tä«ÿ|¤I¨ _øWİ
¬f=9<Öò&§£²’#uX?jSØM Ç;®±MAã-LÓ…ğ@çŸ{~Û¬ÏHÅ®<A`Ÿá’K(¤Iî=í…UŒCé
Í¦R¶?&¯/Wİ
ó
á©	î½Õ\öDÖé?¶*;/³û¦P»Á°u+x``¤—}À@>½*Ã‚jç/œ>p#µCûŸ=±ş\L¢CEØgš„2…57V³¼EÜü´âõıE„èClhÑğó]DO	¸ÿlœxşÉJzù÷CŞ”ü«G4šÜ|Ub0¸¡Ï¼ÜÄn|ÙtŸÆ[Ğ®¢;Èé[‚Œ`ığ‰ñÊcu®¬‘ô	GŠÖùZÏ4İFµµ¶ÔË‹ŞT ¸ôEÂ#¼ïRáJ`İñ"X¨µÊCPâaõÉFb¤VùÒ½‹×‘Ëšš4S¼j·[üœ’TCï÷ï;[x@]ˆP‹%ÉÊsBÑ…Îİ«˜M[Àöø>õ°{Øí™¸/
õı"Ÿ¡šÌ5v­Kõî‹Ú^”½Sèèkr…—yÌØoãà¢ş±Üú‹WzÊ‹)®Šºm«¡ƒ@I¡Ëú$õz·PFÍ;§fÎZ±{ã^İ:d¤ÓÚ~ú§S×Iğg+ü1<1}Ú£pV¡.8$Ä/KÊˆìF[Â
åø§íi;y«qŸ[©bä+W}™Äì;Ø£NÚ?wB©Š(ûn5‡÷–kƒJä‚%qá§Âˆ°x$|ùÇÚ r2ïÿ}Şí	8ûN«*j×¥2?åÒS[Ôß*IQGÍç+”Ø»î{½R×`¾"WNåĞ;73eú9Ú¯Gõí!bæZÍÂ¤ œëš=€Ö1ìõÆås8Ö_°d•Ê¹N9ü¹f"ÈÙô_bñ‘¡¬.^|ÄœReON‚×P 'eî–9ˆÙ.sê¿oYÒ@"ë+¹éYõ=¼S£FÀ .¿ÀH‚¬ÖiÛMÃ˜n:q0—ÓQÌŒ+‚•°G8?üÛ¯)xõÚÃ™«‘£”ç¾×†jµÀë¶O:Ìäb˜©ª‰‡×LŒIo½8óì,Q/´Â¢Œ,D‹Å_şlW€E”$q^(dûé¼˜ã<X‹P÷Ï8ßxqàöÀÉ›;Ô;­5yQˆs4ØéZ‹:ñ#2£«5ûv„ĞËhÑ°)sZé1Å'[è]çM G|Dó¾€5¿ìK8O„ûËL‚iİgbòÅ éßIøìØì¤A5ñ 43ÙRœ¦"ò·—.A³ğ
Şc;SÕöz¬3 êIz>D=Gão¤kÙÚ~JÒÇÑñoXg.ºÙ¬ÓÃ›6C¿Hò]¿™ŸÄpû¿HnÃ	œ¥Ì)0šª®2‚w°à¹¾‚©wómHÿ:pémbˆ!{A¢ûšƒ´eU5Ú×x¤füÏÿ.^q×ıÌº´Õ¤_İH(F[x˜Çî_%ëëTğÓ1¤H}àcB•ÊD.¬Veõäè´®æ©ºVF¿kh¦&êü¢~ñkq_nµíç1rCƒNút7%Æsß–	e¥Ğ;{ohgBåé5Â‰Zâ§¼•®—©LÚAÂ)AğéqÿÏmäˆUşí"¿ºK4ıh›%X4ûß!H­Û.”8|š*–eš	Zk&Š7…]Ä¯Cöä˜§îxpƒ  &WÀ4Ğó9"ÎGÜ"·ÍŠ_?½Õ½H¤b›LÛáÏ'·”údJ>ë¸?*ÔF®ÊDÊ«}Ø]j8Áı”ü´8¾z1×±Æ °ÇßÚKya7şÑÎLög>/|Åö`k¸—ø$¸ŸÛ/ö2‚ÉÂ†9E xbiÊc5€ğ€t—pê§„0ŒÖ	½ ¶”ŠVÆú#§õò%vœ‘[ôĞ$¥­ÚPÑ×œ¨NÍ5ø¬-TÅ'å€ ş…7¬qõ^%]
kÁ½úß©yY ¹¬âbG¬„¥èBƒ´¦'y 0$ZµÍÆõlŒ&ã/'jPï©	Ï‘a©Å]¦P²‰u¡¾7âKX"Y6Hî’oHÁÏn*¤Óñ½(¥¤Çy§mR’ÙMWÏ›ä¬Ö*cğ<-Â¶¼w«ù(¬Şs…G&>DÒà#Z<X¸Ì
…„ïÎa¡o(E,êÁó«êÍßTñ[Ä{D¡ŠXò10Mø–§yx•ldµÛvÿ&¶¸â~÷okeˆ¸EzôPÒŒˆóØê¡u?j°i<6Nm?ùµ}iw–ª‚&¶İ$œêÑ«DÚvCkSDûİÃ¾)UñÄ]A÷¢²L¥lO“5Ú‡ÁU|ÍÔ<ŞªÔ`¬ı'‘(mËk@$9Îº:{üL/t‹¶Œˆä<¡ä’s­n²ÓÉŸªÏ.iWæ”k„ãéì¡ç0bõ)ê€x¾áõB\›í¡Õ¥!Å/ûíÀ+ûÃ×¼– SDË…Ë•·Gzçq£ßTRû{¯túkİ9f¿9ù=Äğó{NûS”iôj¥é;fDêB¥&²c8À.³>Q…µmÃ}î6<ÿ]F²¤BË+9ÿõÕÁÈvOÑøYòB–>Ù·Š¿U?(fY95½¡?”¡v*s‰ë\Ï•ßyqMÔú?£¶°€¼=f·ĞuÀa ¿z‚Šíı™üu‰«VÕw'š¥“2‚Ö,ÿqÔ4ÚíjX±Ÿ&¶xïEÜ¥zÒMéÿÕb= z±¾äEšfe˜`A½	´yßeõ=»-ùåóM¦Íº²(€™aƒ½Yd.ôƒŒ(gš2z$IêÀ^O£¡¸™ì§V=+ï¤õëûØ]b…Ö èfñf‚äüÕ¨‹Vå‰BYê„Ÿñ1-ë>Ñ%G që(4W‚g‡8´{VÌ|ÈBã‘ÌÇU÷óŞYÇá¹rÁ×A
7ç~L© µùB×‹eÓDƒR»$„¹H>”éöÁ!˜ä0QOWmÒ¡ˆ¹ç™nÎŠ¨J®É•ƒ‡i5C¡–5ÖéÌÍ9ÎÍ,±)ıO]WV#g¡w‰b?$¨²ÑIŒm™9„eLŒåOßãÏnà¶uqşÉÄØ"ù\Ã/Ã«+ôşç	9Ş>J¯Sûre®õ—¦6Å€_£O_ôÏü7Ö… 8Ÿò»§¬™h@¨„ÉØ
0Ñ¬¥š“ÌSê4w€ü%b]ö@ gë J–XF¿È£0ê“&WÙûø¿¡~øø™úÌ#O7Ú§z'K,,âètoĞä›ReKf‰$§R–›ødÕJ^ËAÆ62Iv€ZÂD¯Ö´Ñ¯®àÑrK~lUäÈ`º¶0ÄxîN$:åCêüæ«WŠx"”Fléql6í¤ØöÓïó…CÂ‰:ùpìĞfY¬Ğäwd¨+2.h‘e.7Öh-,Õ3Q§=Ñ¾Øe™İ)ßSÓt.´TïSĞØ|0¢¸=z7û*ç|sëÆœï+â™Ôëœøj×fÏŠ4·ªºG}·Â¹b4°dÊk[k ¥èÙu[MŠÎ‡™İ)9æLšxx@ˆxNhncÚwäQ~ºtÉ6ÛÂ¡ÁoO˜„å_•£ »Ù´"o|­]©7£Ú¤„¿ÂÜ¼Œ±"Ö·~b4Û8JZ™³PA_ÅÔkeñbˆå¼¼‹A6r‡[aQçnÏ¶ÈÍnG«ÈÒÆN
œ'äh|dP|¶ãí4§»IŒc„ÄW6e¨#Ö×éPÂñ÷ †ÎÁn	İ&øüLĞÏHxÄ´B×“¦®ŠÓ%*£˜6‚‹d|T	CëLÖpğúã†lJ~R ó%öŠm¨N|æ$D¬³Xk=n´zÙ˜zôî 4ASÜ¸ßTºŠoşA6q“õl§ò†~u¯qÎÍ?~!×<#äcÛñnM/“N†ı&”^²óØg=Âì^:l	ì£èÉ·O«éµ#ÆwÙšH"q)ºïu*Wz˜{¯.1Á¸£zz·Bm‘ø¥ø¹(cL%Träîó¨,$\ç Jû^¿dş¢À2SÍ©İ»ö£¢®ê9n$ÄÒ5V¾yñ7È	16B†[Ößsö§× WğÛfİ_/"
“³ÀìÄdÁgÿ ¸Œ¡a“¬îÀıuÁóöEYŒq[3Bt·Ğ¶¯¿Ä8“ÚÌ¦Şhö1BŸ´©9™l	
âìö“åºB$9ÙF&iê\1QFN˜?]É×¤’ğ÷ÛÌÜšĞC³	O&b71Q)ncúÿ³¼¾fÁSößfØvcšó†ö¨SêŞIæ?sptŒßÃq×ã4ÿ‰ús8gu?ßì˜w‹Y¹à#= ¿ ­ãúËÙ4*'GD:¡•¾z¶ş(ü2B%’è
yİHößÑúñ¬r'-ÛÛGziqÔÖé‘VŒJÆè¢±:ôaC÷¨ÀPßß¡c®™…Şã×z§E3¯Ÿ›ï}OÚDW½ˆj	4õÖ'?A«SjXxèåãX>y,‚rÒğsëÏP/3ëÔû»â
Pfv:Úÿ†?v-2EY7®:K?j$ÏÇÙƒ¾AbÄöVêÙnƒ½/†ü0dÿ ¹W~?©™°ô|¸£ñYøí/û¿pMÌ¼ÍÙûdß; ·ei5y³¾/°ßOİÍaùZPû¶ñTîV|û¼z,7³¿çûqíƒ¿D¯qÈcè'iIµ„ö¬œIô¦×ÈOm¥6ÿ.aĞGç}¤Hu–a™0“ÈùÇpª@ÿ=C
¯19ä7XTP…Fk½ˆäÁ\Îg¨?Z)Ìvvt„ns °q-ŒŞ€}ŒJSx&_IŠœŸäğµëVâx¼ªiçNãTæQæÄÓğÑ®™Râ VVğËeÏ´HÑuÜÌıµ˜%¤FWHŸó õÁGDÂ³¢Z¯v„ÿ	<ãƒ§¸]@ÆÉ£Xš#´ûQ$/y¶÷YWÑëtZ^O³c¢^(ƒ·ö»¾‡ÍíÃò{Æ•­')+ìâ­†Ñ7©œœ¬8'ğUxûm¢¥WeŒÉ¡d(#½šQ‡&àqr=ÿ’e>¯áç)Ê®ú®7^Õ^QçˆC³9HÁHw{ò—-“¡¸xLäè—D€y÷Œ"cëİ±Ç/!É¶L:.D¥µÏa.IcË\cì(Éš³s)j÷‘9Lo4‰x­¡ Yÿº~ÓÀK¾SßZ…ËZá.‹¶z˜ß¡)“çÓ²i$±;9«%
ÛctæPPILïÅÃ…µ}%]WF™­rğÓWäËWGï»¥]O÷JÃ•÷ç	IBä½¢Ä:»#œ€	fîmÚ–3DƒFbX”İ@Ö8•,Ö³Ş„
‡îî‚Jx¶“q®Ú¥È¦àÉ»!º‡×`}Bøóà£œu«¥3 ÏÑç=§±Äj¡‰:yü¹§ßÿ2TıSS5«÷ªËIå—~V°çTlzå „ç¦,H^+^T†|ŞnNùµjî6k#]Äç‡í„æ×ÿñlsÅp¿÷o¿ã	ZQqÇ½rlÚ>ì_‘‡¥P* ém…ş©#GJ,·Û]¤>é3CÒ3Ùæ6Ñß®!y° \×¥ÑHS‚V=Ïih‘J4üMP ƒ½s;{?Û”YŠÁ2áÆãê¼x¬!ìÅ¨yÂ‹•9eTµ$Eª*nRéÃx<_º‡™+Œ>•ÿæ:­Á*¢‰òà-Ãá5UX¼ñ¸¼E´iÛµÚÔWµÊ\ Ô+zêQ|ş`?j;µïa6Ñ ¯T$„[:~B^PæĞ>ct#%èe½³Ál÷e¬Ša1ò¢8±LAF=¥øDPÊŞeq4Ãn&Äñ+Qø£f†ûòQ7·ù ãÅá¡`£Â˜‡Å~¿Îğmz89d­dI+=€ğºf#3e†¶øQéşQ´YV%qËbÌ¢«ìÅï‰–ìtMî À|´\ØÕ!ªÏNUæÇı@úãˆûßé3ù+_ŠÒæÅ€˜x9|‘;ªxgE¼Š|øIb©icÄc–ï(wØö_¼œk9y†ì¼7‡ÁÕÇKtÚÉŸ	ë(N3¢/ñ%ğ"fEô ë<jò¯ú ¡ñê”èí’v+§	Zs¿ïßƒú¢Ó&p¿I@îÜÂpxš½6@
dK§küb¼Ì:orËÎéUÊâ¬FÈCã§OóÇ,ÑÙ1a’ÇïyâšÊö ¸D´±É•AUKñí×Ç‘¡3Ñú_QON”s¥¢ÔÅÉ`y§Óáø(m;GfCúêúÛú³>‰‘…Ç2Ô÷Ñ#Û“ß¢¢ÇÈ‰ÙZğÙ]|hÂ3EÈÇÎñriDCpÖªŞı†{d¶BëUÈÓ¨{<	½“>6.|0õ)3IÛü©¹¹UÙæ=~Ø‘Ô"_vôvğ”4+ıùïé€¡¼¯yıÊOœ Ó~O'*ííÃãVzˆ}z17/X^ûæMğÃ^†ÿÒÇğ•CUøªìğœb'Ò«nwq}³·ZYÖÍõ£Òv–jÄ]Î˜0xü<ßIk°wha,—bÁ¡ÓJÿÒÄ#$U÷´²ÒıûRÆ‰Ëa¢¤€CîyÎf“ùŠ–¦¤—[û@«Ô‡ß2EÚ@ä¶Á)vª¼NTõiæÁoÂye
IZÊÉnkŸ î<$y~Š¬Wğ?{¬yáÌı y¸é–yM±Ó; A1‚É¿U*¸¡åÅ²xà½l³4ºNû¸©‰Ãè³ş§%Ï¶şí\F0†'î›W†“PªÂ627Óº¥Šs¬R\XÕ :Aì—£$†¥Ê»Ê:æŠ(ÙeUJ¢dìÒ’˜¡G5İÊ÷s£¢Üíß/y’£ˆmoCT¹LÛÀy À2ØD/”;müñïK:HBĞ 1©·¤u¡Y”4ßÖ
WCßTü	›­03ÏXû¼fê#LzEÏq—Iè]·Ö2×¹ŞûS/û•§œÌä•kâ®=Yo}¨Ã§ï…È<E„:¥D³E­y‘_¤÷¯±M[<8©£ŒŸ%uòÇ¥œ¼n©Ä%Sò	,çŒÃ|Ú³K­ JÿK—¦APazòh¶áİ…zœ—6÷E;~¬®Ácü¼NÂ‘5­l¾~ñôYÍ9h`J¬9#è±³UĞ«º"ÂÂR8¶g¸w*Wà¸C´°ÙÀãùQß5ç”¬{œV„ÄšFJIQéĞµ ÒşYIÙ©9ZyÉÇ#§V	¹Ä|k^Æ¼Lú’îh¶Æˆi.¨9÷áèheC¤+¥‚O!ĞÆëoU„†ˆ ü6Üê‹¬ç®‚”É­Giiö‚FÄpTxá®±şÁQtş7öˆ÷‡@Ú 4cc'ög’dên_›hb â9,ífN×pMxz¶5ƒfşÕn¢yäÅ¸bş»­ôõ(°[¡xwúùö0H(éÓ’‘3(¹Œ‰ç\‘$¬Ô¹Dé‰+ˆÉ\[g2¥˜µBÏñ3Q‹—„-.%G'œ¥Í]Ëámi<AÉ5ÉäPë&êyï·Â÷fÎ)ÒÏëN¶1Ét¸SÓÚl—Èê¥x“5õådÀ¨
Z>J…ğ*2Â9bMåÁ#À Üípzù>rğĞ“¼Š#^ÌLm(äæz¸RqFÈïL°5au]G—/’Šjà\±`Ìda‡˜Ñ
3VæÕnåRâJ¼WĞs¤—!…àat7ãI+Nƒ¦ÒÆ)Çš1¸êqjŒè‡M½û=m0¾‚C8•ˆ÷äuÇi_g'@ÛtgòçÊd™VGıò¦¨cüg¼-á?øilØı:¯kúÈJï?îe“¦¤¹”x9æÂ‰·¾ÔkÛQnY;ƒ¯§ëV,¦¡Ìq‹ÈÖXW,ÎÑõ{¯™6tğÔó'·?æö=~v‰l4#gµ"â¸WqÌ¼:À0¦šgı|?·u½Y\§óœƒÿ¬¼–=sŞâ<èßI¸xƒË/û½'‰×i¿ıIû‰•­_™{×jª(¢µ—ûøŞ—ğMÚ!>¹ƒÄµ@÷NšÃB+ÔŞLi tÑí±nÈÖôZtÑÄ=8`ßD¾ìœ qMLéñ]¢TB@Í{úec|æË„œ÷…PÍŸ×Ø…pwôÃ©œÄ}aÕr†Oá‰&`c4Ì÷–,Çí¦Œ˜E¡¨¿áÚÊ;µ=÷|ôúúÏ7Ë:1É>©ÃnHho	•q.V¿«ğÀğ*ğDˆà«–ùª?†æ|¿ŞôZHÄOÓ}ã)ê»ßwTyŸ‘ŠÎçOşpE¡%­-Û»X0Œÿ£Òá±h9yIƒ‘îÊÇ8á”øOõ@Ÿ,ãtQÀˆ§“Ä.œÈÎçÀºp;ù\¢ÖŸCk:şƒítÏ+ K…z­©O*Ñò$i,X™å/¿pgBõQÀaÙ¤\iš%h4ì[4¢íãÛtg:ï—/À=[ 	åüü_ÖíÇõ¨Å}ï]4	†ü<Jj(zÇ¹Ğ…58BĞQìi³Àâ6hq˜CÙÀ\fëSFIW®¼õ"¯G@î±S†¨	„}èøäå)r¯±yw¥şïqÌrÖmHE[dºÆ%'¢{ÒjÕ*;5£¦-6Š;ñTãÙ(èÔ»bXP«“ÉäµÃ“Èà‚ó6(F46Ğ[mú[ù…¤IØŒ#?#·8Y™4"ş¢ıC\e—yßts÷1qw7¯S&yÿ5Ì8[R8¹áZ¡i†?èˆâç¸ó–;†,§¤‚Õ$Š‹ %©¿dmáTädË&ñÃ/7v)(`êCdmá„?€yš„İç¾:q,æ^¯—õ$Ê3, sÏXFpVÆñ5ğõI•‡Ü¶g]u’)–ƒü_©…*dX Ë>âÍ»ÒwÎ"?zê){M[pØr¤6åw•»^ ïŞÄˆºRäDéöO£nÓ†Ğ9Œ¦?xõ’H¾oD­I@èQ–ÜM1]ùP_ßW7šª;4É³À®A…}X7ï\JÃHéğ;³(„cİ…²kœ‘ÃÚ3>™ÇCÀŞ±{Ä{i"nLşLå%£‚VÕ1Xõu|-C¸bHnÆ]Ø±Y7Ãô%²ºG„±€ŒğWÎ=\MC¯Y¦ÇÎ;~`Î?‘8ğOğ«±ˆJËMtÜ†à‚„`]£Jµ—{“57=&mÈÚ“¼‚æŸİhÊ®İşŠÒ7z[b5e‚’•<Ö‡#dXÜx­|ÇQEÎ%Rÿù~#Ö|FZQ\Ê)%i9xë®"Ó{eéú—ÃócWÆ_qÖ7ŸB5ƒ7ÆŸèA16Û±dªB–
­¯îõ4i®fbuÙI_åc'ö©À§f×­Úâ ß{sOÁnÅ±ñÂõàª|ÿvZÖmßµÚT½I:ò6ô¦iTÉÏ(ĞJäna:d¬RŞ£Á©4*oB©Œ²È#Ü®+©`ZõR'öğf/&lI’M}pxt;VÇ*ë&@ïb£-ì‰«ÉWÉ;t¼µ¨ÿ€¶ Ï·4ÄÓŒ¸¶xXöƒÓ0Î*
2šÎ'ÉÕ2›¸QÆ@4åÜNºA‰§Ø¯¼¹…Nq‘‘Eü3ÂQL6déwšå<P‚4¤A‡U`ıu«[x¨å·/WÓ
5ÚŒé®zş±´V-Ú0{üäÔ»ç¬¡p6ƒ”ÚFVp6`}÷ÎpZZ¥¾ğ­c,“¢Îà	áíó¸Òô‡†vÉ>«_2àW~¬Kˆ¦?(>´ñ™>+“U‰¹ğ0ú`z¿Í6]E#ë¼F7ğÍŸsséí˜@“!õÿ}‹¾Ôñ[¸Ã€ÚTÀ·¹gÁúœ»GR¤­1Ùº»èwÀŠæ':æu3~‰•[?]Û•'T·6B¢Ïó”)¸ÇëIáÑ‹ÛsÁé°¸Âd@ÈaÅ«¯Q9Í[6‰–òSÀƒŠÀ@ŒvKæÌqvM]S{ÑËvéô]ñØ>¬\J¸æ©t…„ÂØ1"qõ'F¶Ärèfzw8Ôx_|Ü=¨àXRm—Eà%«Ú Ë~æéù@CÇÊAµ+«aığœ~xx ÅØËPlyÙòšj&ÓZÈWäºË3Ó^4F‹ÓÆ¡6-"6œµ•F&HÌU;Y9òü'É9Ñ»íÓacXI8[£ø7nŞ?Ò“J‰‹nV0]Q±qYˆ¡ ëŒÏÓNOmPb;Ô Ü$êü°gò@ [ççÌxŠÏ(9àOâ 1…¢(PJ§4n«²Ë(6Doá$I—¾·Iàà“‚óûºú*mû`¡àŠŸÓºì†Ä¨<Çƒ@ü-ùÅê©ÊE¾‚
‹Ãó•@ˆ„y6:sF”Iâ•t<êCu'´äC§‡cÇT\O–Ûe«´?,º²Õãå9%åW®E–A9H_|¤N@ïèë‚iwĞÜíğäV¤sü×ôO¿ 9áØp®|_‘P3-–’:à&¹²¼#ß3wÒù¶m3ÉCA,şJ]h¯|ÈÉê¡è£±”®7%g‰¥
°!áp,Üş”ŠÉä·¯ª¡¤Ô$ÆFƒ–ÃÑœZzÜ>[5ÔŸŞ3…§$¯ŒæJ†
ÇííŞÏŒ Ëª° 9'²şğ`*è¬í)´Ò/®¦K‚—@ŞE2gdÀC­}"Kx?^2ŒuÎ^¼-‡Š4‡{éKrNæ‡©6ïÁŒÄoáÙèçs¥¤k²q·e²ğE!k‘ïk!>ÃnK\,É·|I/è%!t=z’FëˆÅp^MúYÂª&º`î³Äã`uìøTÙ˜šÿ„–A»-{|ĞŒ Sb@>h=,7Œföæï®g?©½@yê‰Pè‹zÁš6ßÃ¾ˆ%èNF…TÇˆÍÃt¥Ÿ)şÙª}×X¾•‡³:1×u ô½EWâ8IøÇÖRAÖñ6aï~ı	ãèÀ*Éh"×¬ÂóšPâˆ–4E­Êõõ¸Ïéí-"§L®û­°ÂÙkÍ¯–"üQN–D¦;wÔËWwÇlòÉÕ@ñHÓ|³¯îv/öSïÁÅæ/ÕNK‰-o´Oé†ËéÔş´æ@”imVAN/uÒˆfÅühê&Æ%'c‘Ò‚‡«‚oîfÌ ı*´Ô néS2Ğù0”dÌyá9¯hú?Í¿d\Ãàâ½ó¹c!céıæ3n†iY‘™.òŸÍÓ¨Iöw&ÁÂ„ÇõS? D8²·bSùß†‚¹¬z¯!}«^Ì?ş¼Ô<İîåGRÿb¾ŞZÏ4¶- ¢6"LFTœQû\#ÄÎ©:¶lWtÚC¾“±f$;Çâ;5³xzLÏ•Œi;4JI(õÕ}ïLƒ¼FÓhy@$*Êæ¤"¸”Ô;ğ­í˜¦l¼kBü=^ßÂ{¬t¶yˆğâ/ŞU™Úì—Wœ-ü$ŸJéÁÛs-¦ú13kØ‹Tj •Z\t œ´¡$ö£©'9>¼•ÕÜÒ‘ı²“PGD”73›¦YŒø	 br½Á7ø³–¨KÇ`–áû«Ädq­1ºŸ}ÿEëH¾ìvÄ·°!İ@^ÉR‡ï*»îHR„GL×u‹1<=~4
]ItReQt² ©ë.îÅoB³›P!§×*qÃ	»B5ô3¦C›aL&İ”–í áx¿&G˜Êv¹–éİ)VÃ¥ú%O+=óÿ@O`Î­JSb¶~²¾±vFè éx+®ô‘ŸäR½dXT»Î"`ßc-ïÉÄ+Z©Èø=¹æ?—ÉXĞ^¸#Âú„ƒÙ¾·1¼ªı<É˜¾{Ä!pö¹;X½(iEßÈ¾*X^ısÍ‘T£bw¯b*±üŞñŠJ,b$çüëëJóèX¿ï¡¿é{˜ ÃÌ|şØÿßÃG{ù¢›j%"WµÚõêßö@§½€Í°—x§4”=Éå+:ñPŞ4û“Qˆ2¹×à*ŸÇÔ‡-¿Ôb'˜‡“¤5~	W‰Ú•ô<d±JïG”EJÄdâÙŠ³¿Œ,Fsê¡–ák€‹³p¥í™eTt)öšÎ­1²76J®/6Ú(ÁÄË®Å&CTä¨6ß	:q»|û’ÃroJÖK2c™miu*r»c–TÚfØÇœ°Iièx*m‹¥Ÿ§X“Ÿ —®M®ñ@ÄM’5Ên¤çÍ¶·f©Tvaëö9ÀÓ­”Ğn–±x•Ö—6t]"]œ›°ıyP³Æš,Ü\_F•P»È×jÖ#¤V@Òr>ÍRÂKCZËº»íÏmªİÒïŸ?:RtP.…}=ÜÈ°¾í'mGˆ@ŒT—4ƒ{Èà~ü£È3q8Û[tı5D)â²€.}B})(n‡º.âĞLÜ¶ §è*‚Ò]Š‚Ö!3¾Ğ2«ïÙQ“v{;¹7Şm@9=‰Ov\4X¥¹F·Ü›·†ÍÚCmjB²İª"kH(ê©ê6ËrÆ1¿aFÀè_Å79tDKwÀ³ñ0râäm«øL°¿÷D›¿v6	> ‘ ¸„ ½œëô 	d:Ë9îê€œ8vs›©øT²×,Dé
®È,—ÏyCûfZ19ãC²ûyo°4Ùue_¡E0tŒ2©¾ã ±5URˆ·òlëÃØœl§3-‚n9¿‹f´ ÈEYVféÊg¾ê"€´6›ò~½"r™0RÅáˆ[ôà.‘ dë×FCÆÔ‘DK¥Ìã©+È;ÿnë@Å®ã÷kO,Õˆuá Ã¸îÛìúş'pê0‚O¤µB4s!C–Ë¥‰‹bº	àLÿ"IøÊÂq¯†¯äÚ?ş£”Çq©q¥AìÔè¡ƒlyTšL	7Wê¡µ°?Œì8Ìğ'ÂH÷£˜æŸ;T64áõ­ÃÿïN½
ø‚9!Ñ?7\á@¨²+n•“ôÿJ-À1}ü•ĞeÉC˜>~Í®£·…­[İ%İ—Áêò$K”!H6Ã¹ˆìÎüöW6”)«ğÑaõ´—¶¿àeŸ¸ô?Òa ×>-õ bt#_/OcIÉ,u¾’>3ù½¥Á§_¦ÿS)WÜÜ£;„>^©Po×ô&æ½{ó­w ‰ƒ.
¸{W"GyÃWî![C+iü_.!3Äüø“Š¬©&C
ÎNšÃİÖæî6à´r^Q—#ŞjÊŞ¿nÁâSş.%İEÁ‚{^¾‡û&Ï‡'h±w½·:ó²‘ ~Îj‡…®2$;§“É‹'ªE˜ö±.Ÿc«Nl&Ò.z„ %Ğ:õÅmº‰ìšÆ/1¿Ufí^ÊzäÊò©Æ›»¶¼›Ië)\¾çüÜÊ¨™ÔÍ²~êE,5ºø G+/‚îşÒËŒÈ&Ï:Hî~\xKâSkPJÄÛÂéĞ£Å|2šQH1UÑ¾4­¡¥ÌÁk(M3\«²“û¦xÚœ!vL«vÂ]È¸·¥¿¤ú —¯,b>¥èNDgù.|£3I¥æTşèØßƒí	ùòŒ¶ …»®m„˜œğqrSÄ•/\:¥¥E‡	¶³¨:2‰ZŸ%i•?w˜k]ì¶Õ>ÒïMÅ˜”8ßw¿Ë\…~G†Ax’Œî]!–«'~\«Á<¾“ümóóçƒ+–VJk}s0!Aİ]‡šérX"Íóğ‹ÅÑ¿Ë6jŠAÏ¼[É<?[®n±)³‹/açÀÓË§Â`~ïKÒ[öQ&+(¯n¿NEE£TOõ•8{lò?BâMr$¾Aun$¸>*ığv4«ÂÄÂ-ë2(-ÎsY$“¸Î”y(=‚&ãÑÕè’øîuÃrÃÓ‘D¼+H™Úófë±27ÕOíÃF$>EÖ(ˆåŠÙZ››Ô–.=„ZDZ¹‹yCíÅqÊgk	A/{”»>m›´ @°+Bˆ©’O§J!=É±šn'Ú¤Ä,A°^\Ó¶İ?|”ÃUX,p;~	¶K @Qô	¡â¸oK!v|Hg$ğIlI«x˜q€Z®9˜ÏB>Gã£U„uXßÏGÙ¹äû«Òô?m‘HZu¹Æé:]k¤†êúa„‰¸lp„òQ›èC	Gì'È];åx<¸bÉ2†u+z5~¼î“Â·…¤ªz·:Y—~„‘*‚4MúVæÎT$cq	ºdfŒN¦°Jöƒe‘yÏ™EÒÜ—äyÚ_c@ÆuQ”5aíbyø	åqkJÁ¨†”ÜQ²m³”î´¯4–U!eT©U[ƒŒ:ìûÅ´ªÕÖÅcO½Ñ›¶0ÄßÇÕïÊÍB'¤J9ãzbÜÊ>~ø€-¸)ÿ+Ê²!(b®ƒ!ëY\®¢şÁ9¡rÚmq_›ğ²T~hîÍ-htòM^r}¶æ)d.tıÙMv÷ßgÔbBÓ|„Ë…`¹È/ğc÷6˜.ÎL¾nÜÊ±Ğj¨k¦^UL»¹1ù´çÚÀ“­ïhEú—•3ÈL…›ıW+ ıÈQ?¨Ÿpækm!Ó*D±”÷ÛŞÜfD¡/4©}.<HÇ–ËEéí<ÓaR qĞNQ×¥0Ì³ìÿÍw^‰¹¡}6Ûó£ŒkÙeàÈü¯ë3¨”ó²¶‚NnÃìwôÉ£İ¾Òf‘>XvÙş#± óˆ'ûº~Ëls„”H _8"@»òâªMzàÌüİsû¦ô!°íë1xÄ“X(Ç0QÒÁ´†ğó©kÈ4=l[+ìP ¼Qî\¦É´Cº]8²{Öb ¤bŠccËÑiƒ®9Ø©ÁbîÆZ*P::qŞéÅ[gƒ¶€GSW+®¨–§»ø”ğİTÛ?ôcP´ârBá-J=úeûƒ¤dÖÀ•}µ›¼Ç(ÁĞ|t2Bİy‚·¬•ï1C»kLÉ ·Q#Ş¢Ùˆ5§á_Qi3/} d9€¶I—^çqİPÍKŒÇ|OÎcÅ|-¢:MÆæù¿FYjü˜ñ~&‡‡¡†S™‰¸h +FFÓgÕ2»ƒs¤£5‘oE½ö^¤M®ó +¤ı-Iİ¨á¾€3‚+ˆ Oqœ`ÊíËïˆÛ/V’Ÿßùk&¼¹™¼ß†ÔsJÀ©”º…u›?I(3àN¸ÙJÆéüªæ/½T ~ø|ºZ³ñK&o9À´kZ]ÜW¡}ò¨M¨^Áæ¦õıàãù†êò"~şIØİéÂ:¯¿1_ÒDœj6µ ²åœÈ 6Ø:ˆÍ±uNQìr©dtq·çp.¤»t$“«ğ&0‰XU®6:ı
$c˜ƒz{j¼@TjŸı.ÓK§LŠ²Ì^­n‚vL8ÔE"ÈA"dî× w»8—NĞÉMã›!ûj‚_gğè¼T2’eøø]ÿ ª§	•§çx4-0ï”K`ı»ÉçëUHEª6|Âù›KG?ßí•‘ C™Õ¼¬½¢]§,LŒWş±,ıÈªA7 ûi"u@^v¼•3½ŒšdÕÒM –°Åö–ÛøjLR‘ãtU üj„Ö´ù[n¦åJœƒLßˆBu¸×¡é‚õf–éÀ^ÓOú½~>*kFFÍÎ’{,>“„9§8æú3¨VÔ!Å‹:…Ü¿ò}6ç?Ê­ŠKÆKš]`â„ËÈ™/f´ºP3¨e ÏèsïÍK…ÓB}OÑ”E è/¾vmóúYæ¦ş	gt©t·I›»´¸YWÜ:¶Ü'‡àfîI/Y³®Ô‘’æ­•¹m>™QãÉÖ€ã¹
7ÕşBBÑ½‘ÇØŞîú³ØÑneïªki2Åˆ8Eğâh|°‰ë¬vtCi‘Œ™~°Ñ²ÎViæ9ÄŸŸaQTt¥>¿¦˜©SåPy†8	œğr¼7ğ••NèÚïN$îô
öÕ§½fP	âÃhÔÖ†;ßğYx¶Gº-g]%5òÛmÖp—yŠš)SChîáşÏyú T²	êÑX¯F„]Œ%HºVh÷	İÈ  ûÑnªÓÔåˆ Š4Q‚pzÜÒ«„IqÉ)P³AÂ¾äl+½8xCÔğ±‚¼X÷¸F´Ÿ–  xöt¡©oƒxÇ<šG¸‰¬ñcåu:¥v'!)Wß¶xhO3-Æ2÷â ”	8¹Ë€iKy^mØ¹£ïÆ†:Ñ*]ƒa@l_508¶ÕED*¼\Gg8Gt§wã;¥¸êi±DvØFq2îÄAÜÏ¢ŞÍ'Ñ4İğÄş*' †]6]l¿¸ÏìJÆ\Ö‘D{·‘¢šÌDíR6V­¹˜ÀV`ÉæŞßJZ|	.R…ªP|Mş
Ø'ò•JQ6ğutOÇ{¥A‹/.ÈŒ´ˆ¿)9ˆ²½28ûÅˆUÎw~Ï0Ã<«/x°”4İ÷ìÍƒÎp%®[µñîS¢Áš”bnˆşW™İ” åq1±n¶ab
‚Üƒe‹XŒpæ,[g5âçÜ9Ğ@Yˆ	yî¬†óMA
I€}vä«û<HÚ$uB/ºDIÛsBÜ¦S1È6?õØ7EáÎZäÂoÑ}Ó/@P’79%ï{l%İüöV³m:•úñî.U…ÌÓ3y,h²Á´@ÿÌ¯Å'G£›JË©hÛ‚íİİá#Xg^-#¿uzsfÈ¬ç»+ŠÁQíeX¤D÷¸J±víÎVın"tbÆñ$
L$ÑüÖ´K‡#ñ¹†$‘RlzKSÈhîÚ«0©Î»#m¬ôˆ±7¤Ö%lh,Zï!ij¥sóråg*Ä¤¦[^ˆ°iA1%§ĞW€š¹µ<)œ¡†3˜´ä ãkXcèiÅÆ,œ/óÁË¦ù¤Ê›(©“ÍpÌ›”lçÄrªÖ²@‚Kj¿—¾]G—1'äè3ı^Znüh›ÇøºÃ£péMYügØœ\	ËN©D˜}•aVÿf0ú<	ê›»îM¸Qî¶ôUÛéçÛjë< 0Àmàúøcß­ø[JòªŠ6cˆPÒñÆ•îÚº†˜ Œ"…÷>ŸüI…›TÙsl¤¦æøé^¦o7™êÅÍâƒ÷ğÌéÅ6œ ºuq¹3¬l:{Y¾Üğ¼Q/÷Ù¥°š“(ï…•¤Ö¿Ûï.îÔ€$TAqg—WhÇîâ9"ªœà=F:Ò g™²Ã¹:ŠbéÒeC´¨ıƒñ^}U“MT|!c—÷éÚé—ÄsÍ»¿ó!-Å-]uÏ:6Á¾
	,½ÉL&FÆòq6¾•ˆb)¾âEdEßú§gu U„û,«ã¦ÉéØó¦á'ÍE!nè¥wF-,áÇÀK_Ë2;Õ2Q¥~çrwø.Ñä˜‹…‰d-ÿ„h³ßásæô	â3
N·¨R¡˜ó³ß”\[cr¶4¶çr‡VÆ›¸öşõfè­/ŒJ
5}$öÂàÄd2àŞva<ÃÊêÿA‘½3CYL úóİ¤­¥®(Áú_0†²KÚP6Õ`gšo3Ó3¸?M¿.Ñó+$¨o€3E”ßQ-ÑÒöP:éÀN‡|ãEQ\èÜjKX§±±±Oå~›DW!Ö%½e¤C\MTX‰@
ù@€bGƒ/ L‘p*<Ø§¿!ÃKdd²Ià’1@èrÑË<BŒo³¹(ÕørDîTÓŞ‡Í“
kvï¹“¶½ÈitĞDÉA»mŸßãUm™­_­AZu[b‡74¬˜/:°/û¯Õ?–·óCIñ–$¹s°Ï¶ƒÄULsæF{W`œ@C‰t¾CËPzWL¡`støâ,GtÁîş®~é`ZwËüWçk<º¾MŒG«o~™MÎâ+\óøâ›İÖyŒ%šÍùòÄö…7÷JÙ§pX‚ ÿy7	Näfm-»x_1bAû¹N½NÀ¾ìsSDîk$1HBÄ›á)ÉR%]¿‹|Yè¹‹½u)0½L8Ø@É±~ù.ÖòşcÅB°æA8o—®wø1‰¡dÍ›O)£ŠRçš’:^işàÛvğáÒâÍ3qª‹W>æL¤¬•p½}¶ò„şÜ€â	çİ ¤¥Ãÿ—ï§å1–§~"›ŸÒÚ} ?ƒù}ÉuÚ[_Ú‹jÖ€…ŠW*3ä|›/Ø»C:	°Ÿ›-šoEÊ&¸á¸BZ*]İ‡3ğÙk¨¨çï•Ÿ]mìz@»‚÷Æ6DZz«ÚôÉ¢9¸0âm©z43;4Yj‚ ¸Êco¾sc¸˜èk|SU°ĞÍúÔá>Õ	
Ş9¸)Ñzlİİ‹hø
_b{êÅVvüF«É‹ƒEbËğK„ä*ÿP£^²äx/épiÛ»¼´UrIPâÓìI•¸I1O›@Õ"ÃFD¹ fÙG9åÇ0 s‘\Û¾ägè×üçlâ°8¿—æÈıQÕå½lœ©ã£àØ“VÛ0¼à¬g04=fyGÖóµ)Gş	î-wM÷( øKBÄæ<{‡¬^sßm¶©V¿c¨rŞGä-}…‡e`¾ÍŠ‡VN   7’×¨æ6" »º€ÀÖ8å±Ägû    YZ