#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2579404097"
MD5="dfa83108bc22d71d6f154e1171f80828"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22668"
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
	echo Date of packaging: Mon Jul 26 23:00:01 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿXI] ¼}•À1Dd]‡Á›PætİFâÉFÚK0Í‹{1¨+HõÁ¦&àŒ'áN·[®‹ÇS·§ÀtGôlô¾ˆ˜PÑÉ$¢a ™¯vâ2M>;šºÔ¤sŸ…ÌªÿRTWJÇó@cJ-@òËîW"@Öêw´‰Î` Û!ÌâgWwgKÍÑ€§¸›rfŠ5ÕŠâXñ](øòõŞ-v\Íq®.XµĞ9ÅŞ]#¹¢&ÚˆEĞâHÊH®x/@Áñ@gTÚ¸‚o6Ú­>,ËTˆlFr0˜¢Bó"&SÂ/£cDÁ¸:S¯ö5WÜİ¾v±âÏ®´äz÷¨»b÷¸Êµ$e¬%{é}¿({+(ğˆ4¸i'Y.ìxãr×¥ÅIh1-5Ê@É×%næÈ‰LÒ<H¿bG¿…©®CïT—Á,ó²æòDš¿1SFP ÔãÄˆ	,¿q—²K€JiIu€2ßò²ÕSíû !Œíğ“Äæ)„-Ëz[ß5_.Ì©³âÍå÷3o´Şš>æ¼!@W/ÈŞZ^ëG…µ•:FÇQ²©Ñ|lå¸²\®/¹u… Ïè(«şüÀbŠ/ÿ*Dâ)NäÿSuZ×¨5€1be<ı¦ âFş¶şêÉĞÅš)sÏ:‰æ''¤l­ÃoI¤şu/bHÌÊ^‘c»ÿñõã!MäôĞ¿ÃÀ#2t`$ÁiŞA¡­"WèütÿL°CFCÀìaàçñ*©–ê€…îRn6ï€v.¥QW·i2ü‡¦›kÉy1Òâåqn+‡I0r—ÄJ·S2Ğ¸t(ù+4Ã±	ˆ]ŠÒ#HˆÌÒÜ7ÏîinX
¦*q8¤4õ•8Éa.ƒëíûè¿§ñ‹1?¾Flš¿=æ„h¹\+>ÚÓ=»~Á¹¨‹ÁÛôt¤ºx\^¢¯cœë(˜5Š¾'ëãà‚)À:©X,÷Ø\­°wõ®|…¾3‹â¾ÀyZ8F¦Zóû,wFJáZÏ†¾ä–ñƒS€T›ûõc¹YVõ*šJ{3ı´I¿UÁ'/d) líZ±ÿEò‹×D$$º_¶#UbÑ(1jÉùaşÙÜéÅÑÉU\xÎõÈI´YX©™2nv`_)Œ×:L7¼uÂšÑïÿƒ0	£¢œŞZ»‚Ë.0Ş5œ<¯ßö!ÃşŒ!Ïª 7!ŸAt8öyÉuö%—³eüh·ÚÔÓQãÂÅÿ­æd’$»Î¤{X56€YşV£gß`AÍÔ4uNFû°VMvÇ l~9Yud9M–Ä02(ŒÙz¶i œ_¥{íá‰;QµÛävãhĞ†ñÅ\xd•~Rp{?ÿM^&ô?'XS Z|q™íŞÃÒ8@{yñ°	ù<çQ™*<ÕMÇ›ª.6çû››£±7`ynØÛûŠX~Rm°™Òx_9X'ÇÍMC^T%Rğ[ÚW€)İÃWÔ^j&]â!:x›Qw·XJP²ÏÜÜk‰4«ï3-?¾¬Kr¼š7Š J¥øQ„å“’µ<	J3UhËkÆ çö:ñ',´Z4ó2w©ëd†fğw«Hæ\§Ÿ<Òó °ı¶ßı‡Hİ#ÊÛ£<ªË\‘’Sß|E(eLÎw5@şTØb01šó˜PbÈy£hÙ—è¥z)ÊàQ‡ÿ¤FÌ²¾™Å8ä¤ëGîÍ[ë2TöepÌŒç.Å¼ˆã£3PÊ¼áÂx‘•WÒeN.áëùâ(èò¯jZhw'BKİû@¡]E±¹`\g	0ó«Ì,ëƒ£Ìp•ÆX—wt¤rG%_Y2æÉ%¤Ü¡Å>za9Ó Ê˜–Ñ×í¸å»´(^déÕ«@RK[MVY#<¢ ùĞjJÿß—$®IQïèdŠ,åİŸÔÖt;7t«g(ÙÕï!nM¨˜IÓsz«yµæ[YUâŸ´½&$³Ä¿Ä8êR-RWŸLñHC
W¾{íôÕ]aZ‡=Z¯û_SFŞÖ
…¬Ş#îY&»…ÿIed¼ßFXÉ¼ã)gtmLäK¯W@c/'%4$5/Npvòñbˆ ü~ıİb.¡Êğä[Ë6XòØÔ2TCGrD$@N(•ÏØ[>·IÙğˆøïõi½/>/ı•˜a)aWöhÄÙÀ’1Ãqv†Ã ¥ä¨„…ş¼æ]è[ŠfVíÆ­ù1ß»L}}’ªä/–µ™vJ£úˆ ÉÓuí0iêş¡öÆf©A%ª5×dø
dšá	…Â}ósÒ>o[sM¹Y½7ô^HÅôŸÁH´ğŞp¹¿y–/2ŸŠG)ÑFlõ°nŸ" ZÅE¡
úñ•mÒËúE}q–kÒ×V…ØĞÀ™mï‚åÅ*c{ÂĞs›ncµ Øüª!!,¥=½+3ö7KEŒx{ö®¼î&&şf¾¤¾”š?‡ÏKr'è·¿8ŠŒ ŠÈwıÏ•ŠlDFsÅ{‘²;«§›¯ÔUı…fÛîöÅ’ş3ÍcÊL!²n2ªÏ]©É<ïuá•Æà$äW—V+âÅA>œë iËÇàÃ—´œìŸÙõ\Ì¥ˆ££Ìô0z–³æc÷¹"£M¦5iùß¨éÓÏ¹¦¡ÎPÍÅLÚÁƒÄn=ú´ƒ·8Ò#òf	8X¯^{’>o=pYñÑ¾mÈù~Ğ‡#iâ[Œw.Ú£Û-Z7ÊŞY¸{¤Z®±_*üêœúXYñ{>œN¦«ê{Üæå¯ç@A°½‹ìQuÉ¨‹–¼x´äƒQ#Ç±€ôZ®BÛırRbÇMÙ-Ôé{—°©Lç,‘—¼I¤wï Î{?ã_*h†ç¤íÇs“b!±«Àğ>QÂÙØ.Wƒ¢¨óBîC)rU3º©ÂEÖ¼¸9VG]‘	W&K}2ğ*ëyêÀ™ı`©„x`6Ld*é#}³•v…G˜Ñ2mpwƒ„Wt=¿Ş8cñ6`¤ø˜ù#AËÂaÎzy?ú£yNñ\K·Úáp©økpÌMßÉbµÊñ`f!ãÌ*›@'
ï¸^jÍõX¥1r^c‹²ãÒ`ÉEUk„•²ŸÖr‘*8üÁ‘²+yGæÔ`‹hß©<[0òÓŞf©·¤bŒL!üD…9d„	åW²À€¤oŸó·0}J¨½§{oÜ\É¶ŒØ{t–Æa{Z€˜JB=ÅFo~añúÁ)Y‡V ÿ[¯Ş4do6BÜÏƒìSbaOù|`æ	>+^}cÜ[Œˆ“W"`ùfÛU.G1ç-­b¯H½³ÂC“ÖùœiU ‹À‘Û\€H@Œä¡¬wó·! K·äÒ¹ŒĞçÉ ÷g%¨MAS”ç$¥òO­p¶F<"v¦}sáM”?,Ã§÷ß%‘Í¸ër…sãë@ñyİUsÃzçHŞ@´Û¡A‘şû¹@+Ib‰ée¥0'y	çJİú@nv@QÔÔšn¦ú'Ëvó*Šªú‰åB!Mfø˜Awğ~vÏdh “¦.{ç`·´ãƒtøÈÖö¦_DÃFä•ç™RqˆÓnŒ †jä+Dv!øU#Ê1zË&`}˜Kˆ^O'G]Ê×rµX0Ã`ş&Fe×ÉC6úï‹z|EÍÀ °Ç7»$<îLàÓ¢×»BpËÙø@zÛÂÿ*}u²p‘aÿXèê o&A;‘F§–5u¸$”%+À8c–‰OUÏÂõqøİNğ#¡ Ëf†ÕhmÒÒY
b8MR‚‹»çQPíNÀ¡8—|Ë¡2oj}X±Ñ(z¸—µ›/¸B4Ix<Ş[cPŸR­¾ÿD‚âÁşµƒRÚ"5SXi—3(6)bÇÍKÙ~n<-e{íiËGİò3Yé½^w9wóËm%hkfñDˆÂ©ó'ÍL0İ.Ğİwn$oxİ(rw ?‘ói?±+ ]óº‡9 ĞÎkåÎ¾V±Îö°ŒÎıºì{k_ã€$¤LGSkTçÔ¿şÙ.«
ô@ŸøÃõ­5ª,ŠEx&`Å›;‘Ma(5u~#tèõc.dùÖ2t•Şwò’`DÈäzh!Gİw…jDDsËïX“c3T)‰h¸—ç¸À.Ø¬bW yÙùWÎ´ÙcÁz.‹ÎZ=à"%Äàá¦DÆ8Y¡Sõ¸&ï ùùm«¨†›Ly¤“¿dF¶Áªvq[ğò´tSr»JËj:“(ŒÙîËè]®\X zÉÑgCæéÏÉ÷?E± bFº¨xi3[+qpš°JRàlèãçıãWÇñÚö})  è‡y3({ò´Úô˜¼Ì.:ıÊÓâ6ïÖÿ–ÚÉ±¦ÍóxßW¢Œ^ÉTÄÈ?1¸,ğ
6^–^˜ğÚ¡zG?Ot¬ÌÆU7®`¦Qàf «+Ó°ƒ'“Q¥BVE<<¨aÆ¡Å¡ú´¡ó‘b³ë'‰$
{Ÿ, Ş»èJ¥?·†t(•m§l=çEú¥e¼š–=~3ÚD¼gzö?Íç*¾Z³óÇ»!ÈF@¯³öG/µÇ™œªº¼6Ïa÷„šAŠ]H/é,N™]DÓ„”he™åáâ­‰>h‹‘Cò‹j­o?bÔ&L,ú·Ã¾°mUF’ÎHéBf`Yòì@’¢–)O5Ëã¬Æ´“×Ã	wĞFBúvõeÊšùwi>'lõ{§g9Õ<èëÉç˜ÆJDÜèk‘JÏ0¬Şı/NÅÖç±%Æ
mÂ¶gËw`û°<C”¨Ø30â¡ÿŠ»•¼w“(ÉË CßaË C½ˆpÄ@ÙÍ‰õû5†!SÔŞÃµ+Œa·Rtíoõ%Räòâ:¬Ä6Rxøñğ² ÉĞT„7ÆÛÕ:&÷ug>ñêN eôE·æ³‘LÈ¿‘ºıõi¤PZ¡¹øäÅkvÈÿcÂZ×hXçæ@×ÕSqšølO0ï¨/–Lç§ Š@î—šôáÌuXêp fÛ¶à-zŞÓéH8z²#WŒûôú?xÏ.¿¶‰ğl"q7‰|Öt†DRÒñÓ•Xcê…û5JÄÙ4VŒÊa¾ñèì¸øo¬]íÆÃJM}:dÌÁËXŸ¿|¢¶+’óäw·Œ H¿ÜfúBè§œîÅ9+Jœ%6¤„®üy2k¸óˆ¶Ñ‘ñtÿ*r9õ”06‹à¸Näëuˆp³Y‚=ñAUxĞ—©Uz0õÚj;¶, Zâf/}úŸü¯¿I <÷I»Ğ»²R{?%á!s=#›šlfƒğ
hÌ$i€Ø˜LŞ¿h’‰\nú8ÃJ‘µYf…¦ÔUêH£:n[´³¥¦P'0şmí-”ÄÏ“BCUºlHŠcË+à`m‚ÿÂÊÈË•….*EÓ³¢;)¢ÙZÓ§îb-ÚTÎĞ´”§ÈvÀ>Ë‘~^)@Ì.Ìá¨aqA2¥¬lQ73\‡£tÀ¡ğ|åÚ /6&_úZ%¿ßÑ£ü%Ek3·ôËöß|àeU©&7¶­è¤•£ˆ^ä_o‘LäD+ÌÜ6›°óF Rl¼>èÍ€³ oúë¾N×P¡íM“Í>e!~ô´É,dnôz£â4Yé7/ZqpMÉ©£û»"w!A6ÿ1ÓIKrêÎÖVÍ·ºk{kô•ë®¨g (UËø$œfî‡ĞI C¼YG€§¼[ÙODlÏ}Jì0+„­‚mKíøØ×!ÿÒ4JdìÛ7˜ÓËúM^û<'lÕ­‘öqE° µòHè‘‡Ipv7B=ÂûÌÀ¤™±õ Fá`¤¢ƒ\Ô+ån’ ¥ùğuİ3çpîoğrî¤Ln?A‹2·™Zrƒ$fê-bG›Y.ÛCâ:”¥ZñFã›Kèq6¢sÚ`XWòæ»íp0â‰.äCwCº şĞ‹Œÿú7~ca©^>]',f³$5¨Æî·Ëf§Öæ	Ğ„)iæ7wËÀnİô]®IO&¯bŒç£àï‚×® !è½dfp|R††QŸÇê¬d$tº÷wY{¯s°«jà-»éı@^oàø!²½ŠÎß¶«ñ€Ä\ÉË U =Aºm%X;yku ñIH·¦2GĞ.WaŸÈ'"£şØ»“£<{¸TQá„ÈĞr4™ÑÀ.U£ÕªY¨;½ÿ˜ŠßC¦ò@|­ëK‡Úò™ºû¢S(’Sâ¶"Ò$OÄ«² à¢{^Âl –ŒŠû’nÛjË¤¿Òæ@3&¸•<Æ23ÆÄcØ¸•¤7]†¨¼| ÀœH…ñSñ
[†qHÊÄ,öšë³xK->Ó™Öòê PÚ[OÚ«ú” ønè4`&h¼…¨ğôåxáå5%t©ë“s­‰Öcª»9y–_¦8®ºÏf³Œ®Cf¶fºÜ5ÄA¿>±CºÄ´4‹I÷¢<O zø(%læñ2c¹7ÚW5èô4³$_1Èeça›Ti¬“ùªã<q œ(Tàiùf’àÔ]º¬ÏµvsäW8€_´*0ÀşrÌ7#ƒ(	èdï{>ëRßğB•Ç¹"G,P›èÌ
ä-ê…}w;†Q(œÖ€ğC“ö‘IXªÉ®|tUoFÏTÜıı‰gmµ%4!İã†Coİƒ>ß:Î½	*¸,8S…´Ñ”¸ªc}ª©ÚZşÑiòÃÜG6
EÉXfŠ“Ï g¤MÏ½VU ìÂS˜‡êı®»’p1HBbÓ~=†–sfôçl…¤eú©İËÊÕ©¿œ¾šµ°(G8ä}Ô©8qå'bW¸ENßâöÈEF¨@ô?×ar¢“)ê¯°K`,Ú¿ï¶'í³¤†}èÖ‹¨’²ÏÄ['ü˜Ö¥r .ÎBC­êEMÒ~àÌ¦ZõåJõöGÅWn¼+æûÜ2²ÊéKğ±´½_•itî êàÇéC«¾‚^Z€„WÖ”PÁW•ÄÕ›.8©eW•x³š¬kLõzR™¸:içV†m
µ†ëÈŸ{hÈ!ô¯#ôh€dÊµå¯HÀÊ1qˆ¼Uv¬fbl&„b~™f±3şÖå}¾é–^'JÙJ½mRîNw@¼{$›şlÙ«-¾€p:—Lè&Ã'%–¯z˜Qb-èÎ3_ÅvlÜ´çö¤gV›¾d~W†¯Øgà÷=“Õû­Oo±+ï%×MBŒ‹3œne,2Ç:rq+ÌÚTªH_Œ ’ÕÊÕÇâ=ù³Ág¼™ªV
l¿iæöG9‡ªÑøöUÀ&/z»K&áÏ»®j†b+‰3Q™ëıc-—<8g†Ÿ‡Úø­—.H  Å=Çğ-Ô˜Ló@ÿZ›ÃÙN.ºûõri‹ûy¦}¥Çdß7 ë=SPû.-!2ŒLÚÖ5ú¬º¢äs„µÍ|QèC„–ºñËâPâ™ä|"âÍQ´âz4™èÂÅ+úË0g>”çÍÚ³77˜4¢ÎG-¿u+°öwüi ÷ø_$Ùx‚.²ã"M†d -†8'—ŞâlwRbŠ 
Êåô‹iä^´äO S#Zàìøô:ETÍ¿×ù¦Ë¾¥øä¬²æ9R\]i¶Í§5ªó¥ŞV1ä¢µ‹‡ŸiØş¿^5Nn´©‡hØ
P‘ÍWªQ0‹TÅI„<†3œã¯v˜8¿ÜÃIGYúL£¨Ã°Êkœè¦‰æ}¢òÙ«ıÍš£SQ;lzœœ,¼D[hp*3fR‡…â; "ôı™ÂNç`9;YM SáIŸ²"}#'G½õ‡Á8cqL7K÷@øÜÙ‰à¦]ªŸ<¹'8ü ºGuÙ«(Íów)¥õ¢‡0^üã`Átfœÿzò•mºÿ‰‘l^ä{Ñ¸šMñ#ªdĞ¨‰c7E…İ¶#ö‰*û–×ènİ»WŞ½fÃ2íús»(+ëİ1~M>W¤vœ¦s¢4{™µÎ	!”OÌaPÄøê
M9ò¾cF$ZåæoV?}•ílgÒ° m|•Ü:ö6´bğ‡ıØ"Üƒ²k’1îÇá»&0>oEü÷nªÙ>ñmâKjá.*í3'›}€¿ã²Y
Ó{t­ÑÇüƒõ^^¡E+á†íh’ª©"bÏÑ †L×™h‰ÊäÉÜ=‹SZã´/ÍA8‡7şÎCüôv Ûg+×¥º1Å˜}ıíÃ“m òàXÄGs S<ng|ñ¡cÚèÔWA–›Yö~[XëiºAÆ¥îpÇÁÛEI²ÈBˆ9t+ÿFç$§>~Üf„mäğm>ú~´43sõMí´a{*A}—¸GŒ¯¡K½ÓãxŞ"8
Ji…®LıúV9]^0ZG9„1û¸
I‹À·îâˆùåË‰ĞÄW^Ğ¯íoÃZJÜ‘½ëqã‰¼v¹™å˜IÙ pBRí’Ù:®ùyİ·.újXª6İBã,l¯µl)Bå8fò6ØëÁ¯Geê{®7QÑ›>à&œf‡*£ê¢=ÈaR¹0?;:vèV€x±&¤ˆ1n||tÀtŞüë¢báğõ^ÑëúÀ,åkÌïº=íAÎD÷.‡Ojßû'ÒA¢¹ú=·tˆ¯F4(ÑÄ•î”ùWcò}‚ÕÅ~Ş':²–h=2}>²—°fñ0Ã—œD‘ê˜úÆ“ŠPdE³§DE¦ ˜%d°.s€‹¡M¦U3Çº>ìZÀ<Ôæ’`/[Ğ‡ „FÏø&²,ûm1›U’”WAÒ·«;‹Ÿ¥ğì)ÌÑü»Ô?“bG ’Æ€‰NÚr¼üÒSM£•¤«têH_Ç~0BµPšp"<ÌØ]ÇáCø€Ï³”²"’]uÅ' ¡«İßĞ‡ë‰%JlŞp–òØ©?#›„_=Óm‡O²^¾œ¡àüéŒõ½ğ¸²³›`Ú0ïö$‘~}DÂ¬¢¶µğs• >>æÕãd’ğ©—‰“8$Ûšf]¨l£	ÄE¢qræ¢â*^‰øàÚ[å!Ïe9DÚH[á´lœœ>€oöí{gA—µ_gtS
øÂÎa%1kP -ÃN0+óØÉ]bÓàİ+s½İr˜85µ¹­¥.<•Ùó×Ö®xªŸúNpmœŠZ¥‘Œ$äf=š·Ç¶NGz\‚´Ÿ<óC=j¨G*H®&
Ç†ZtëSIĞ¤Mp›q9°÷Öğ.à±Ö–†>‹c=ƒİ+üıXÍ×
/ŠÂ2k'×ÁPœ;j¬ T¿=Xz³à+­ƒ‹wµ|üNŸgNá•¢ˆ¦£
yoùIJ;<“¨¤ºôì¥ôÈ¼Ë©û¨ºÌ`ÙÉ:ø
ß=¸J^Â‰×*ıø€+º	a¾‘úóê/Ñ}šPB(d%Æàù˜jËa¹é HË¥6]iƒüVq-•v÷Î’§/¦è ˜ÛaP/áòî´å «©ÚÃÌé·ÃùI‡Ñü:vt*‡¼1i¯BáF>_.{MùÙ½­QØê!+‹B™~–ìç’C}†ŠJ+Á¤á¨oK~wZ¤&<À™mœ¥—*}°
ö›ú©4²<â¨¹§Á’–R†Um Q0ÑõAÓÊ’”yi­õI/g€oG+¢eo¡
3½5Œ~Š¨ßÄ$„ ºİù/úïMÚ‰½3òY}›F«cTmo1\•y
EÛÕ}«|t,0·ÎZ F,Jf¥aw€„7^ı4îWNZ‹JeœÚ°ÎUĞÈ5x3ãÚ>”}$t×u±"ä“1dM±¼yòT=T|ÎÁjçIÓ
‹ùZ ê>‘n^nÙ¯è`uï©&=Pbï³'ùeÛÇpFÛæ¨f…fdfË0¯Ùz¯~Š4Ò!¿LKÏ
‰äíËü0|g™ «¢”Ù¥°O»ÙOæ´ìRVGIµ·hK»C½r	)ôàiM<?4Pışµi&M"¡Ø?ôÁaõ,0¨Â×ò#çî˜»	ıış€¦]²"ÂIíFOp(Üœt:=¥“¶‚îäâIeŒq²Ò,ÎÙ4ÙuQ‘ŠÇ®xv¸cf¼ØDTö½B|[èäw¢n†\±,—ÃHWDÌVúl¢…\‰-›FÈ,ıİ(á+‚ş’+Ö¸ h´¶–~Ÿ óQÛÒe‚Ä§)¸°iús‰Ó²
‹&Äœ<» …o2öƒ$äp -¯‹ïcVÙÚ'ğÍ*šo>FD~“Æ®Tm=(=du`ö°@·((¸ñ%œâ)=„“…È.Óë­Njã\ñC(\NæáÔellü3+Û•ëCß•ç ÄèõTzVÙ2¥AóßŞX0ü”€©µ™·9
¥>N,¢ûÒììy`1›¥ıq^,¿â{ÁciĞe[ªw!rÙánsQïtÊÎÑÜVŒ^‰ÀV<Î¬}qÊ–®Ë„}¯Uÿµ‘.ŸR±	7É	…ƒÎ¥&*Ï~ë02Nã†|PfôÓUÍŸAp ÀvRÊïÖØ¹„R¡¦G‹Iñğs‚›Ûpé>»9
»ã/ïÈºøŸãTÜnt5‰N Å=¤¢ç’—Ûtòşd9s
Õ•£Ò¶–ıÄı?6¨Ëì’FQ¬ÿû8øòFFt8aËÕI/»_ ¹ğıöI&*W"W?“×V¿7öÌU¥³™Í}$ñK˜KÛîÕ@?Š«Ğ!7yæó¥”`ááV8Y'ÎrÆãMèxWYë|ƒxcêûosDÓ4ká)»ïOìDçœŞæ&ˆ¤ñD(‚øİ¸âì
 Ç¹~V*ÀUFÑ\f;ãÚš“SLlmY¿ËV0ÖëÛY{pf˜Şù’3&¿‹p?3}ÌğZRE}¹’¥ (GFO¹o«œ§³+,¡(ö:}„:@ò­Cş‰ù
xĞ“íÆ“¶zQMš0‹>¼Ñ+|}tèè9¾ÄøÌrìÛ¦÷tŠòŒ_úÌ©AÇ}¯°)!ûùšÎVoójŸÒœMÅl•k5ß!²Tù-á‰ñ¥^ÅAÎqÆUÔºş°à”ÃØRÍP¥f‹q´æøgz‘£VRftÁ:Àí‰­m â¨ô­µl¾Ña[	à?Oº½c´ıòU„±Üå€#u{lS	9&Ğ·w*%¶²ƒ€ªWÿ[U9@áXôÕa{¼{½ön“‡—¨{G!4y¯„Í‚-ĞSæÁl !¦¥}XO¾3Üøšß8ı¬¶JŒªë_8W$+ÊAÌ…şW¦&îõ&Gv8SÎ1˜ş»±‹:nú?0oÎ¾§Amş ÿ!á8„€ğr¤ñ³·T|)C9Ô×D6TñÖüpÛ%KÇ9á9!€*Dô€}2™¹§U§˜_‘mi]Åö3ÚGÄÑq‘+’
°ÚÉ×½ö<ßHíá®ÜŠâ®¾s¡?QÜÜ‘ëŠªl‘³Á„Ğš›*otTäùñËÍœ“í³‘|¢ä®`ÌWµ>™÷òŠ0´S™Â†¥1{[«eÑi·¨M¼…Ü Ñ5üÄéá!ÒKY_!]Q«4Ì–ä„'Ú°9Óš=¹|¤c¿“TŸQ¼<éw»é&Cª%ò™X¾r—Í¸]Ê€(ëNÿn<êpYİ#Â¾M}÷éÿä§¯NÒ'Ñ0×»31”`Ğ7¬H£<™Dé’•=‚ub[–”gƒ©& ğŒ_Ÿ°±'t&oYtl«ˆ¼‡¸Á|¡²½¿ı–cİo>†‰½¼a5cæGË6¡§¤I‰ßEr¥fF}4–Z»¹JJyœ}šÔk÷Şx
ÔèO¸Ê›Ÿ8Æ£`¶Y°s„Ñê²çx¸8e(œ÷Ùšp'j[ÓÕ”í–¡6ô¬ÍCdQX`ÿ‰J‹Î`[ˆË]‡µ•5Ã £Æydê|ÌF…2áÍ&æ­?ì¥˜L‚èËró÷V)üµ¾¬‹-Pñ$0†ë„7tu³Ih ´»«Éğ-ËDÕò.7Cjê¬L‚¶¿·*ù¾“×ø¾)‰(õS†èÃ.™‚?éRi)P]Î¹„‘„§*3
Fò¶GrÖÄŠâTU ¨ñã½t®k¦ûş3}‰†Œ8òâûp¥GeµU«4Å¦kÅ¢C¸¦ŠŠîH½­dâÖpÕXr ”YÙøÏl<¯\2–~é\0UÎIÇ—Ä*ìë ËÙìBß§C‰^E¤å¯;ïk¶ğ?ŞÊóØÖô­jt“òœŸb3ù#­Ÿ>¸âæPºhFK[täe––©Ÿ,o!R•¿Àql¸ó[0‰”\µoÙ%úPÆ&#¸“8—ÅŒÒ8PàÚ-/-p‡ÁJíW|˜hê­Öø%3ğöÅŸañ½<øûENbÄ˜û·ãİ®åI'3°˜‘¶¼ş¢“4*û/X¸ïÃTí¨ãô.í"îîZ DúSøÎïO,N^Sğ-ßW9s¹Ìù¬²ÖĞÒ{˜I¹°Ü¯”]:ƒ›D_Åß"²Â,¸´‡4ÃQ²Ì]£Tm×÷9p™æ<©á—µÔ™d;’[ŞtIP8yìNèÍNÈ‡c_:jUÎİ}›ãkuªÆ[L×'¦Ñb‹KÅb‘" 26™§lÎïµR][P#|t½ª:˜°q±÷µcqú–x,è}*9Q.qÏ@Î3Õn¢øà­]*ÏêÄŸèaEà|aÎÆ<ÓX¢E/¢ÈÖÜ²,C•-RóÊ¾d¿Ø!á0Âáx>Öî…qË>Ag¬xÔae%Ä	Á){¤€²K'ÈP` røvsêÇ½¾Å¨7Åb"Š7ş-V—y5P¯j…¨¤©»ğ`Å7øN 3İ.>ûî´¤Ø5¨ëÁ«¾¾R&N˜BÏŸšb’¯²vŠÚêÔÜl¦ê&Ö!ª¨¶ùE—a"!‡³9¿5~u7tñ½	—'xŸì{–î!Ï]´u>:Ü%:[$Wk°¦!*\¢»2˜læµ€xn6­¿'¡câ§ÔT&—·œ+ş76ÓÔ™#İ†HÓ]ìDüŒ¸%y±e–ÂO€ÚÔÇ»–šfÁf’ùôª5z¶¥ó¥ö:$TÙ¼˜Ÿ,EGÃŒª8H~À¢·Òüá/C…ŸSª1IÙ¤¨³$Õ\[>OaUaÚ~Wƒ”¥%nïÉâ\èZ¡ÅÃÙúms¿4e'€%
¬0ÚÆ}Î©Qû”éĞ_sXeo0Wí›¿Ò¾MN§‚ô™o$­ú©y‘­™p:®^p°d.C‘ÔŠ£+dìKÉ¹N’Å<Ò¿Ğix¶Ä»™Ìş<EØ¢¿ù2U	RPFã·ã ä_¥Ëb‘	¨Î£<>Ds9Z|"=¬·d´bAYÑˆ‹(¹Šc#Ù"lYëÂM\°¥OùÔ¦xu“ı@ï}¯AŠQÙ¶¦zYÆÂ .«ˆ=®$¢ùÀUç|ÇF»a}ßÖøŞé\¼Oj¼;„PAså¼ØM ‹Á{úıÔöp«^åãFV.\æü-hæ€Ùsó<Û&K¸2"Rˆt²›rbìñ	FË÷Ì×PmÜçª†ldu®x§–}>*4u8°XËÎ‰uˆ’í¬7y>¡^¶ fñÎ´&UñÒÄKÓâbWşíBñGg¨î¼ånÔ±š+ì´ö:iJİEH‡QfÁö›ïLÖHD	v¡!…–”°5Òà¶Fìó‡ÊWŸ€¹DO­ú5ª˜ó}¬şÆ<Ş–£ë×8ï!LÊµ='çìf#áH²[‚åÑ×®ã	vqFÙZ–Œ¼Ç\-9ækg‚ùŸ˜pzYF©eæõw»ÚØS(Ó:âS…u('yØUöW°F0“ğ¢_Üª½S©)Œ$œJô$]ùêGæmMøp‚ÇU³‡Q©¿¶Gù¡¸Ü‡Ï!KåóÿEùÙ/ä°÷2±Ÿ<®VîÍ~=¡Êä8å¨q~î€¬W˜0gÖ¥­Ñ¼ï‚|§<–ÿoŠ	ã—ÖZ:ğf’œg…è£ØÎqB]•-Jxh£K’EˆN›Ğ6òÕ,nEÆbÿîµ1¾¯Ğ$6çpÇ&¡y°¥÷^LØÃLMöZÁ|µÿŞ$ìx!…ûwfKKüêZÊ6IİœÏ¾SL¸ùOgz™fÑ ï·Y–Ëaó§®ƒ
‘§&Âòˆ|Ñ#åª„ìc¤?gòŒÃkºX—ÅƒB]>Bõú}ó/à¤VWš¡]X*4G«—`1û÷·<!¯I)a jµm…@ÄrúL%®´ŠbF8X–¹³åƒ»-"x‰lvæ>°uF„cV·â+Y/"YÁJ<Ã~¤ş.D»e–¶À†
Fø“Zr«ÈH$„i[…½ìR^úi$#&htªŠæWšó’êT*5Ãé@Î]/[d'ÌX’ÉÁ£*Òú?‹ùUkõ[É³Áı,ĞĞÙûŞçÿ?åsZÿÓD4ò¥ÁıK—È™Kıè°©Åõz´OGp1¶I`É5İvL©¾KµK ‡Œ~t•¬™Ü=¼øš$_¬:°IvRı¼w²{€†E¯Ëáûşôæîä¢¥ª­›üÛç&åÄİ±¬.í¾å¨ì\¿3š'ñçÅ_&)Tó”U¡Jp¤)é(K¸ršfâXú9Wü¥ú£Øûc³ªÜ&K0+rŒëÊQIy‚EçÌØt_LÁÀÃ×Öª5¯£pŠ’lÛBûD&šÀMü"~5E{ç`1UQ—îm cQTÛû’”z·QG#c™øÕ¹’¸Ç°ätS€) Õ÷rxH+á¼õï1—Ë\»vtäGNeâÃH–»±‚ˆoôE‹¯¹=Ş¡’9)o³ÍRß‰ršÆv›öˆY	Ô¿FR†¸bMáú‰ØEt	¦èXfònÎ$—9=ù¨ÖxÍ« ' óu=š¾®‹õ¸‡-7 ¢eó-„¿ûÿß!oá_	J‰‹q-_s/&Ì½Ç•†]Íì"™ÁlªÕÀDÃÄG&i‘ø.°P9„Ëú|>6Îˆ«ªº½ˆ½±>éKaŸ	X=nòlS©¦‹Óö…èövÊw)‡Khbt¹
Rò
È¾¨/7ÔBœğP‡O¸eú\d¨şYòcä%lceUfg´˜tĞî4Œª®gÏÄfB8CY°ì¯j5tÉDª×ÑIÀÕ¢N˜$<_áoèÑÎ#àë·+Ğ1qTÎğ²ºòŸq/¼>Cß>MÃN§¼‰àK!½@WÒª2~+ôšF¢%]Xh®¹¥rÃR»šgŞºÄöNk^p.QôIwXô{ÎWŞ"ÓÕ®Ì7LJ¢šŸÚ@ˆajÏÅ:Š‘¦Ós¥²fõœ£½¦ïœ5
Œ¸H>Dfç;ø€”*éï‡pJÆà­_@}£—Ù”	Ãì>/zWDu5„Ïyúëm›ú9=JøL‰!2ÿ"¤rÄ>Ğ¬Ügxhbïeïeö6¦%ãG{ –û=È-"f4+6Pé½’u°}ov E/¢^ä_Ô¾9»O+{á±ÌS'8‹W\åÒ¦¸~È®=Uº,ÓWƒ‚ZJ!(ò2²•ÜMìÎÑ»ŞËBP½YDq5!'Sì†±ªOéŒåaN+”"(L9¹»\J/äVw0E6¶¦õğQù²’©L™Mœ6UĞø¥FÉ"ï“—ál®z¨Øp¤gxÉñ–jü{SÎ*÷µe)µ€ß- HğlF»NgìtßÖRná¸Wªp X…†ìÕ@pnxqy°HUÅüŞ—¡³"áÆ2ˆ¦ø)é.Á¿`ÃkrÊÏàBs¹5¡äµc4Ö‚»ºDÀ´ÜdMÅÀOıY˜¸Ò—sÿ¾ÎpQmn}
iîº­”Ûé‚_óIş¡
˜3¾•+‚¥Ó†Ô»!“¥¬oJ$‚K?í³éŒ Ï¤öH4ÿûı5µÁ£ú<h=‰x·ò	VúÄXYƒù×WfH­9¤6ôö“_}kÃl·©¶ãÄ«ã)SvYŠ–Õ™€Ë8£a³ÖşÇÂ×üV=,ºe×~T(Šÿ÷/âb%ö•ZfÔéº‚f¼ÓRÁÔ‚L¡C”^tnò/FùX'”¸o´… ÃUHÖ;3Á”½°É£c¼óºƒİLõ¨
Ø	eê·íoÌ=à}¸ŞÅğ³5l……Û›öEà^ÎÛ•òÍ,·åÇ tüôÊJ	€óe—1Ş¼dvŸ„ç‚¼Ï#s{pËĞs}:Cë-¤¨¯'úAn1V"q¢Ç©©µ¼m)À]D^uã=5¡^'ŸâáZR ..¯G¾¬+‡l:DPmÎÌoEëóYâµÓ”ıt [ÙL°œx€í_ó^Å{pÖë›\8¹rëÜ¨%U œD¡‹ÀÜ…Åş¶ÔYŠgÅÖÇ„LVáˆı°„âRÌ­N	@òyÍ–‘V9¨»ˆ”Ï÷'‘+ò¦Œw¶µ¯-K§c3®Oa¬Öä{/ºİ÷Êx¾“Ñí )JOáJ¦[¥ÖûBWŞ…E~20CÆ“J&Òñg¾o›ä„õ·†4_wM”ÒûÇZ£wI#¦E¥
t0xã­&/‡Æ2+7«]&© A¯r±4Q q	yb=¦‘ä§ê¹ 5Q¨9š4íı0v~¿Ù‚Ï=Ûm0ù–ïMËPr/¦m…‘ÿSIOtVjH_×³”Ù‹_ãV¨ÄW˜¥Y1Qî‹+8Ñù€„[UjUi•ÔFúH[JÏ[ÊÒ‰8Ôy@²¡öûl 6÷cÀ·póÕÎÈÑ¥¢ßÜäÁønëÁ:ËCñåQW‰>u°Z¬R.¦>ôÎ‘!iPåsuü”éÓ¸uIã¼É×UçñeîAËE¡9JÜ¯ob‚XzÅF4¯!S gİl¦«mVDß;€zë‚zek)—¿EdÇ“ôiaUÓŞù²Ãôä7ç†Ú¯RÓ,Õäp,x
ôcZeæ³«€9[úJÿz(—¥ß‹ ³_¾ø1ÊÊ0ºõ2Àu×£U†!Ê3R3… Ş’ÏütEQ<t¢x!ˆú÷R4Gæ.tU¤Vœ&üÑ~íµ#¤[*í+:«–\©†%í}#ĞÄ*Ò÷ƒeNF}
{RB™®¸PÏˆÂÿ ºLoIĞô}c;3j$Á´ú[*H{RçÕ#¥çm"z¥¿M·Çö k3æRº–v=§Ú,ös+-[ÿ-õ¦£¿™‰¯Ê1Âb9r³dl¾ÁñYæ”	ôt¨	Ò—òú8£ŸWÁë)CMç’H‹ræ¦5{ƒrˆ#¦Á ŞT-tm]àEFDÿîwhš>cŸ7¿#pûwKÜ9pĞ(DÅâf)L{¸ÚägùÓ¹úä,("Ã|Leã§´ f÷Àş¯êÛ'ÊİˆìS7İsŒ¨Ø€w¥•‚;-t2<a´“ªó|—rÆtÅ©Ä×ŸZˆÊÅB•Èñ¹17ä¾!x§İ,á&Fx—{˜ß\¾j4›Y(™Ÿª“øúšH‡nãS‡ 6EÊ9÷ã®ßÔî”2}R£ a7V¾÷óMğw£ÇQÓ‚&šÁüà|ÛÔ\á.ÀA]Ü¶rA@äï]Æşb¾åöëq‹ñ‰"¤‹6³»W©ó}4`Uí·ë[ÿã$G7g>NÿñÌò
önW£—¶Ä˜a$ğÀa}IM6’DäjíL¯ÿ‹½ÖÈ)ˆhÛàEåGK™O¨^ŒHe“7é†L\8V(ÄÿÈ¿R÷å½uÚÍWšYCÍV¸ñí·Ç³	½Áf0§½:Æ]«ö“®Á^ù<åîûİŠ².GóFy…N½áC›S¼-^ê¼şX1B»‡YóÚÎÁ¨uê#ú¡Å†<Zì ’J'.U„ŞĞşŒÍ¥¤‰#¾Î8vR¡{™œ‹åİƒ‚fE[ñÏøôÍPã+İÃhÉhC¸×ÍœmŠ¬oh±Ù®0…dÄøu'C_8@ˆ®=­ï4×nåUéúNc¤Æ¤f°ÍO¿ĞÍšY˜æ*¨w]ø4goÂ"“˜ ÿÁw—û?4\;½×E’¤Ë]Ã]?ºm2sºh»5=İs`k–n À‡—ëcsL,åèÛØhËeÄ*~d•,‚3êÿcQ3òá!ŸZ.¿Ã8óü”wr‡a3#ÔÍò3vwÑˆÚ6uİ4ˆºÈsséå·æ¸Ú…caWazeJ8²A"ï³Äã1Ÿ ‹JğÍB)c ôÕğ“MÒµkçiŒ2€´Š‰¸¹•é7VNx†¦+[æd…p¾C}Öy¶Â#Ü‰ùqK}é9o4$ydåB¡Î¥HË”˜vkÆÇÉû5^ÿi|¤øâQ$½CO?¸ &»S¤·Pú[0lá®ˆ0Ç¶ZŞûÒ	t/‡PTLŸÌ!4a|8VÇñå09<)YĞ¤c¿jN8=¡øÈú1Ù{î+4)_óÆª]°İ½ï¥Ÿ6ƒJ @2E”ñŸq†ÿjÒUe?2ù¿‚ø	b‘Ÿ"jEpù¨g-GTû¤Ma¢W…÷½¨:á›ó€±”<Ã¼Ù‚^wWÊ(BŠ0¾2?¡"ZB‚@bÎú œ›ÇmPÊr}R.&šÎšÁİZßT±¬|eÇ&‰Z…ÓSÑy¿Îilˆ!hÅ¾=ş*¨Ù¹›DÅêr:˜¶‚f,GË6Ï@ã;´F@Cøár¶ø¾R4°³&+`wäí‚£+Ì+¹ÃÒ|H˜,å•¨ÈU™Ş-=>àš&µÅrØ0àÎøDò6ğ©À´´Ÿ1ùvXÍ	c@xÀÒ×£p,Çb©™ïˆŞsTÍ}}ˆ×şHh¸™´>5ÙsÀò]Û«¸m÷ö/ç6¡ÖeMgæY¯„•H¸¸|³[.$MêúLÈ{ï=öÚÄ,®ëYÃ¥›Û(¾*¤›¬+­btP±íJ\\õêÑ¥†¤¹œI7LÖE&QéA¤¬¶}–??gº.ä´DÙ:ŸbUöƒ×N@è•…@dñ§ADŞøxàrŠKÃ*›Ÿf}Õ3æ²}$ñÉ.ºü4¥&#Şì±?Ò7ÕºoP©£ìÖüX$êÊªÀü(Ñ¿•ÛaL¦/ñŞB‰,ÃœbîœñVZÓ Únr*,¦8Æ?~èÛ‡F×ƒb$.µ‚îD‡qªoü"7zÉ)ñşÍûFÕh]:œR	öàãƒÚ¼Æ×®˜ìEò_ÃJ¼>hD±`FM‰p¹¦U*VK°Z4®,ĞéFì¾7cV‚G«åÒµïZúÛ=b%²hqhévæ‘~­}…;Im2~WõÅWù6úIÏ¸ö_ºğè²§X;Û¾¶ë½=•Ğ|!Ûµå³Füs-fê«|S4}ŠÀ§¾ÅóĞ² <Ô¯ñP+“ôÊbqçÖËÂjO•‹Ã¤]Ûà8tÛh>Ñ<ç"ŞÄ¢?_GLâšéŒƒÉ³œ¶á7•…d+ıM¾yî=¶õõH;ñ –ˆR‰Åº¢šİÕî›®Ú…:ˆß ¸ªÉ,Ó„¬BKc3?5«ê8µ‰BÍ[‹wu/5D%ŠBù
s=ÿV [ó Ì©5”Y¡ÆÿœXªoò;	WU¶-=#7” §Ç§MõjÒØŒI}ïqg»ıMPŸçû’L›è,°†Å9Öwƒ(öƒö…¯„;¯‹ªÎÒşaãÃR‘O`MW‘iæpô}H·I[ùş¡äâü5®'ônL›iÆóæÚüIƒÒØÆıM?¤ôÈÁuƒì²vßHRŞù<Ïr`Šô+Á¥¤¨Á1ên ¤]Ušæ~×dÇôòøsµVé¿;¼8°ŠÌ}6Ñ_Cùi&±[;“tOÓWê¿Iœ•‘tLGÉäu»
œF5÷|€ªDÑ«æÊBlßVÔüÿ3ñTüh»Ú4È=s8ñ •dlÿ>‰ø8êW1©Trã…”dÜèWá[*,)Ä†­LœÉ.11+ëù«Í-Ìaç„År×›è w©¨èĞü <;Ã‡“¤Š9Æ—W‘jƒîx1V[„,UÇ°•Z] ’\¼#X³MT?]Wìõ˜ùªğ •»ókcJ¼Jq4×¯sØšîé¢ Ä¥qQ=})8îÁ¸y¥y3UäœÂAù‰z;LÃ‘b	FmÁ^ŸvÈ­Ñšp#&ˆ¤¦Ìß³ÚÂu¿XCQÀÁ[_°G8Ò4•x‘Õö¾/Õ5Ş33U1bá®ßÅš~6rGXzdòÁĞÌz æ" œŸ-çU6ÿ7X Ôuæ¶ç·„°l^R QÁ—C¬?
ºorheQ¼ÌÖ±~51éSî’¡²ÜÏÿúˆÙè¹rã‚èŠª,}Ş’2awD’{ı›ìÛ}‚gUŸl0,«£DÆÏşàm„‹z`æÓb¢«ˆÅ§Ş»U]Í<*—=P¸9“~àÌ	³ZêÁ½K<±æ6ÃÌ³á&˜túo6 A(7I†t‹¤ÛÕXŒÎÛŒ;F0Î=ç;XÔJ~ñh.ÎùcRœ²vm£=gU,9¨dÎÚ|Êø¹Øy1—×Vg	[™Ûºò´YkÛ µ’8
²à0·WµŞÍõàûK€­*f»¤U$
_ñ×±P‰{ÕËŒsÿÕkšã½r1ĞU`î#Šx/H‡¯KL’zÙ	5ñQ(­gL_ñyº´™qf*\9K¤Ø•^G˜+]„/ª&‰¼ßahĞÅYåáÒ3}È_«¬«ÖzêŒzn¨ ³ßÀúrí5	ø[¾{±°'X³J_!B	şL®i;!ÁÌæ¾ ¹¾ã`Å:•+¸WUã"¼¿{ZV¤^Erîf9öS}_IÌÁAÇ­ŞÛ ì…¿y5¯Q²ÿM8ÀpÌüx~à±Œa[4x6@÷î9Äw‰–yãtÉ*Æh[LDµ«Á&ÇáRCm8i’TÈ£`ÁyÎ?fùAFxåƒ1;>r}ùKLlÓÍZ×!ñàP‘g€½ß…x ˜lÌùÕ	H*fÌÄ=kÎi)ç³¯Pn¾¶Ôoï¹Ji—ÅˆÂÇpáµj.¯@F12ıW2/p·‘-uí‹”Ênª»Ç=‘]· ‡ÜXzG5Ñ @-™ürôœ´+qn$$ALufj0\—kuÁ£|â=÷öÆ°tJ©g)£Ò'zNÃ{¼ÏFß%ë.yÉLxD©cAéE/K ‰ëáN"Ğ²’Y!Ã²Çm6‚
B±ñÌfUa#{óP?ÉŠyñ1‰!:Ñ‹ƒÁƒ]­…y‚Ç¿™¼Ä2ìÍ›İ¨×Mç¹IÁ—jJL‹â'•ÆøhÿZÆîÕqû õxÀ<¦¦äaA¶SZûâ‰ÉvÚú‹ mOnÔãÙ/£İ›‚ùM!|›é™¬£@Ø¥|¼Æhúái‹;p‚_ ƒqóÜ°zŠÿÙ"Ó­çÊ×~l‡x—9ó\¿[X*2¦İä/m5úú–'zs(p7Ùˆy]l/isğ>uL%JªçÆ ¿k¯hOèÃP¡@Pß#@Ô äçÛôÕ?o.²ËU£¼Iİ"Ïú UÿÈàR.ÉR®<@Nå›€—?eî^P –ó¾•Aíy8õñR‡»Ëæx§£"zå7›>×ì&v[nŠŸyÑM¶vÄ±Îıè;0:°ÿIà@ç*4MÉ’©ÊĞä@^È/³|œÊ!½ëYNWó\¡uéŒ¥ÈÿÍå: åÆ©pÅFÜó.S½hPÅ¬”­úÑ÷•‹y|Ï×~õz¡Y!âTJS(äMÛ§6hæ±4øqdKúçÀoâşxØÜç¹ñŸñláI’ebmR‰ıÖï=i‚»¾`c(EÉÌF×+£ïïc?24ÓÀ¾¦ŒE©.
tÿ{ü,Ÿ£>Ó©ÁÃº”0¶•	CTa2¹_ là^.|}&qÿ.£ê1‰«lË/KaƒgRòÛ¯äªÂp1-5+eÀ7Ãö;Ã<"«DçÃkbX“McüxN›ygèòë rÇKÅ÷b¿¦ÍÇvŒO5-»'k¯®‘¯èñ$ÿS¹ùwg··JK÷ŒÎù6™B3ñÉ]dÉ¦yÕÔÕš(AÂä%5¹Pbü™×`§A{‡V©ÙV‡yióÆ“aµİçÅò:pAô®´'qo38/×ÆsÖÄÍ@(«z†‚D°–¤S˜6\€SHY‚`ƒé¾Øß—-›|µãòª BU$3ô†§=óJˆgbWeÂ°PÜ]W(ö->VÊ¶GHŞ¯G=-`¯©¡TÎõfJï_$ú—û$Â‡4­$p„tŒ5”,4×ÿªÍ-hÎã‘cS…Ü%_bVúaD5ßè…XCyËf+µ‡-*»ÛÈËØçea‚Å6 C:ÿğ¿O”Œ—`*D¹J„a	´gË‚—İl‚?½3½M½òj/Å”¢ã&¬§Ä’°¡€&{•‹Ğå@do(@óğbğS±¿~²”“Ùe¿{lêÕ¼w'î vÔBOÂ`¦y[‹*Yö¿>ûú)Ûw_áãÜÀ€0ì\Y5nÜÀX,s¬˜>w.¯&QJ:xĞ/Š9¼­µÒƒQR’Ö‡9Zºd÷Ñ[‹¨ÜAåÀi³…›‚¶¢,ñó¥¹Á}úÜß*¡épÉúOy6QˆËJÒ4-2«V;T%q7Hk³3ÿüşWkãÌùƒP¯—N{KGÑŒÂV½Å¼©Š—q÷ùØˆÙÃ`åÎÑ®€‹…)Ùše•7¥.´ëqœ!…JüÁ©`Úïñ
ù…Û.øRªÜí©P;0/l¬ÿË»Ü-ÚèŠ›xçynî’Îİ|€¼‘1+ûá•»L2äÄûtœõšÕ$ƒG{ær®<"œîd‚tâë^á_k]g_t'†rûXlÚä½‘+×à`Çn¥ÈïµÚüà*9D<8¬ÇÑ¹‰úg\×RãİÏ\.ÍDBÊŒWš íXO¾Ì®,ç@*~!}S¶<K8° *g†U²Ís'îd®µàš÷ii´Zsw©Êí
n |æè,™üŞŞx@íÚ +]ÓìÃqv-k‰­'ì{{zyHôøøJœ:Œ„Ş‹wŠgA{èë_}Sëy|î‡!A·’Jdç0¸¤Òàh1y2MÑhï+uüg[Œ_"|á{^±9	u^øk\EdvGTßÁ2ıÈĞŞ?èïãõUİô¨ó©Ç'ôÒ4ùŠ\jbEq ß/Ÿr¢»Àì
Óí_^Õ2^ÆÃv'x­°‹&Î$Å±¥í^Dğë|éguÎí¾l5:²Y½‘ŸÎ,%øsÚ”e¸)O£@¸ò«‚oşZN:€Ñı¦vIc¥.»µÉ‘Ù€ÖãFS;yP	PtüT;œ?³-B³j`Ï]¨ª-·±åèpqò¸GJUç>l‡'"ŸC”Ïx¼ L¡İ÷ÚËLh™Y´*AÇ~æûBb€ïYpµğ&¢D—Š%Ï¹‡%ìÙÒb0’áÔíl-”÷5ÈÑT5²=lBR¿ÁGQÏ„¼7d½p?]ĞA¬[ Âñt@@ığbğjö¬%ˆÌbjùù'ö˜Õé£Šşº†Å}*(F{m#È¢ªøg!¸ò«Çiôlïş~<oí^‰c<ìèšıŒæ4—)o‹¯™]u3”TÁÿ¥•!ÇîmƒAIfXû5óBÿ¬wõ£@XOVrÌÑ|£‰¨ƒB÷ëÔ!?C`/÷4ië&~ïrA>&ÒïòAãï}vuxºs'ı­iæxo+Áµhs+ÀT×ŞÅ+àxHÿ+À«Ô†„¤y ·õvcêiN¯¹)+ë(ã-$2qw™ªæNnêŸâÙšçóŠ¯‘è¾„ab4Vš—Åh°/Æ:³½¿Q°éb­·ªÖ¡‹?€@]Zy\¦#Xˆ~6f¸Å+?ğDğÕ"³«~+pSÍşeóì›‚ÿÍ™A?uš*IÙíwA¢ß–×\dÖB¿').ãä‰şhoF‘H¤ZŞŸ÷Útÿ”$ñ”IÒˆ Î C›·<tôÊ˜Û"—æ˜àÉZ—Ïj#¦àĞĞ¿L$t%ÎÚÃpW¢>ÅYãÓÈphƒ»æĞ\,¯ÕCŸˆÙEÿso²¨0´wmÄ}ş7ÁÎ;p?Aú0À
2íŸbµ@‘k²8Õ²kº*à0òJce¢ryGÜÌCj»cà“[‡ªÖhÊÂºŒÀÒEßıïPëËvş²j|ªi0òg‚qs¸|ƒ Ôc^lK¿³êæDUG?û€+¥:“ÇÛ±€ÂĞ–Ií'Gº¤TÿÑîÆ;+`ìhÃ(Ò€üğ@-t—@ªÍ´ì2Q$<E=²0¦VĞ‹
 Ÿ†)‡ôkÈG®ÿº\¸&Í-C‡Á.şÃ»
oÛïc‚ÜrJÍ0vjuØY›Z:‘“Òı©ƒudÿäèû7s‰®N qÃ
Ş‹¿æÅ%÷íêq8ÖRì…
Ùk85TC+-F¶H¶ïş™…–Ÿ§y€¤eeóo±ÛdJŸÊNAÀHËüë æS¹ğ+ĞYMIĞ‡÷v‡l„Gfõ%†S˜Õ;ıD6t<_M!ğ}.–Vƒ´eyi¶0£3qñïR•{J‡SØ-6Ş’‰MËáföªÌoéTB’aCÜ§Õ¼¥;–ºÆ°šÅ™Ä™2¡’‘¼´àe}¸]£ÖšƒyóE[¢ß¤ZİcÁ ==¸-ıºÎëŸÈ–å]HÕ›ü$(ã)C©EkN†pŠŠ½+Å"”Y949¡j%¶=ÏÈ)íÔø9=™ño¯Ô[AŸ°5Fìu½]k€Vjø7y:.…D@œÅ©šlúL"Ño/ @èå†ïµücZ¿V‚aïæs5 à•ëİşE¹ Ã²S„w€2	ç*@\«1šÅM¾×ªà#oÿ¤„å¼e(½8¡aÄ­UÑ9fTüm(#~€=„ÒYid	Øin…´€3†®ı°ˆÛã²Õ˜·ú.IZ€Y7s¶¾˜}ğó†ş«&ş2ì¡B»¹ª¥Ö“à'Rº_{.¶K®: ]z`–fÕ“VšU=¨ò€™d¦ô]Uı´(ØéãıùÖ9:"şóÅˆ(,î¤ÀˆM?#IéÄµ©‡¸)¯{²ËûÀy]ÚsĞÏ»¸xo9ª0ğ¤²ì]këÇ‚áÉöÖóŸÃ+ÅLŒ%¾emB"ÅÃ²Ä:å¾sífyzÒµ~fªpN—ÂY~À8=?¥3å|]×2üªL¯ÓÿŒZo-°Ä÷'©GEDï-œEà‡ü´dôÒ`Û°.YmóÆ™^Xÿ¢ëO<ÒÇœ”7]k4›>òº¹`ÁDw;‡rh”ğÊ˜z¸™€«”g>™4¨0Al<ÊçÅy6¶®êH”’yÕı÷$q”™¨QôÚ/‡º-3îùÍc”ú$‹Ô•sÌU_›½ Ø¿ÿÄäÊkÎ7 [?· wÔ¸/¦ÊQü%îÎyæ‹z±ì¤nì_›·º>ùìòRcÉÿù-ïÎŒAúX)xÏzNëŞ”ƒ/;Ô§ÁuR ¨ÀOhFç›¯·HèIfÉCo-Àƒ£Kÿ^Jè(âŞBâ%i/gú•{$<ê<©Ûè£=1Ækòe–îŠï+ş£XÚ¨úğ¨Ê_Š„W±¡şU~±™0~¢o ¾€‡–“Rùu÷‡åØ†g¬|6–AŒKÿ×4ÅnÁĞzY˜A¯öÜ¸½t^m»ØøP³S(¢ÃÀÛÃôŠõVj]ä;]ÛfHaI”ÒİëCÄ˜¬jw¸W¤è^©œş`#E®`dÕ|9gw-gÔÁ×¼¹	{»Ô›ù¹d_Ü¼^%Uájeæ{Ô«{¿!¾{Å´%7BĞ¶_¹]‹;¯ŸïÆìŞÉ‘f€O·ä–=ûoÖú;İ©éRá wÏ²„ Bæ¸Şş0xvÿ©Ñwk ÜæHÉcÅ~VÒK"¸œ|¬÷:ü)<­íÎ4øÀ ø>Y§?Æ¡!9Ñ>æ…IÊæ2¾¬+äÏqhîíwF¦¦ÔÔE‡ ‚©`úZÀÀØ¨jL5yØúÍG›EÑ	öBÄñuèÎE«|‡ØÎk®d€16Ÿ<«ûg9»,;GÃ-t•óq£Gõ÷)‹í´Ú;óÈféh5Ô)M‘ÜÅÅÂ]fšµº¿Å(«gUÉJK1OÊ4ÙÙ'¯]ù”Ä¦ˆàÙ¯İşAƒŠünÿ¦1BUu	üdç~(1”¸c†y™¡3›±’Ôím|c>ƒIxÁ8q€ÕÅnTÄ{>ï¤±â1©åe_Fı`ïb3ìâ'÷ÔI
KVÜşªÛ¬m>ªĞ'üúE>¬ÚTÜÛ&¥¢wvíªş¥:M†.İK§y¤ÎË“±_š6‘ŠC„½¯ÊpAxêr-SÎ6ŞY<#{Õq2«ná$ÆP"HºçKÊÀR|•ËÎ©$ŞãÒ~›Råò´´=^G“©y­ÿıduÁûN’õyaSáëà q:\½åZ[Ëù]ı;*=Â1j'tM’şúoÊ(s[–ŠÎ.«ü´mÃ±\âÒ©å­¤rÜ3Bp¢;‘â+µ£Ã%9ÜÓŞÛfÛbØo<1s!uVè¾ôa==Y×ÎÔR»æ¤”È2ÿÑ»^0\%å-Ì™¤ÜnõB˜Á4¶XÔ˜rf“@‚$($ˆá"}a%uî66òÒ4Édá¢¤<;ŞæJörş¤µ)ÛöpâÃ„T»>ôeÅJüèƒ2cJq8"Ù¦çŸã¸ˆúîgŠŒ[Àğÿ¹FuVè†êˆÄG¾¨wÁ¨¼Eú1İçlÀ4ç»0’Ğ.@e‹	GŒšÙÔÈ¤Ï\o>Õ­+{KƒLh¡i/aßé¾Ä)¿©^QÏ$š_)X; Éğ•ÿq­é»Sm¾»G‘tG?“ÃvØç\€Eê1‘šêÒQ"İ/šªkÂ Ú¤ÌÆåÍlˆg÷lwyİÛ±úĞOö,o8!Î\éìzç{®­)W¹1	qd‚^|±ƒ"İz/ĞÿI‰Ö'.*\´l“µ(SèTÃS±ãï8Dá°&l¿×_:¡8uaé#FÈ¥]B+Qtu¹C
4L©<w‡$P'àW?RÈËÔ±f>dv]a:w1‹3x‹£p&NÚJªgYˆû?ı
óğLV":5Ù4õ/R%ñ:ŒD¿‘ªŒc—ëÀêvgéğŞƒŒA2çÌ¹Ÿ=fÏn½hOËù«ı{µ²!1|™¤õæ×Vş*¥N(Iª1Êô„†Ç-Ç¿%ñër·_¸‹û1¤­ŠTc·èJÆhÀa4[$ÖoYÃx G‘¨2ÖÀ‚dôËv¹B$šNo÷ˆsèÁ®yO:²!Öwƒé¦GÇeäÊïaä°b—
GD`PÚ4Ş#R—{JmIÛñrÚèæ+8‚ËPCtËX{Ó7¯H˜”’0ıÓ–jZxÁ²zµUaúÚ‹h$Êû(kô’Ñ‡+|.4ß‰@ë¬N_¹TC„ØfOÓÀò=:\b«âL§S†®:3ëFXİYI°õŠS,‰Ÿ!ƒœé 5\qP¾KÏB„ÔxÅñ])]ú)'´©>—Èˆ@Û_/4(½ŞzÄO2ä€jíxh ¾Fn‚‹$×Å(ê%ü½‡òzï£T#ï¸´N3ögª@êa!¾1ŒÆ	İš2é"DL>»iµ³V 3
8j-!ƒÒÛN†V†Õ!«ıŒŞÓ`¡¢©l†Ğ…ôÔ[dñĞªU1ne<]4¾´Ow›FÃM—Öğ+6d/ŠeôS	Ü$ô{òÆ¼Ík÷PÑ~6@†{„Êúñ)ÌÀİ¸.ä.²š×cïbx¯‰½*(¿EŸV&ìKØişP‰œÄÈ¯`‰¸óHÍ*Ó8ˆöYˆÀÀs½¸ô¦Aû¢Ûè˜#5›-CceA§opÚ¾Nï
8ÎEo«úD;ÖÊHÔ.ƒ“cP«[f¼›!Ôi–/uOƒPÀ÷E
˜R©ê×/EY/HÂì…Í	ÉÃ?y÷ƒ¦o"ÛÔÖ&	 –(¦4Ø¬\³^*‘¬ÕøõBRe´ø\.YR.DÛ¬Õ`!M§mÚ¹ç]·'÷ru;ñ­¢¹ƒÂVóøhll–O=TºV?‰¼
BÉšr6q‹–%kß	JÇÂ>÷F ³Œ¹r
øuæ	Q:O=r‡E(“éàŠöEˆŞuÉ`©õÙ3[>©(¹WÜ?ÿÊ–³FYKnÎe¸\çÄ&Ní	HK!ÌÒ!@A
L‚?'-àoˆ\¼Å0·à+Šoş=înŠËRríp¨‰âğaMdjb™ç®"Ü•ù”àH`0NÏÙv8„45{Æ'u<7×0Ä¡ê‰í1Z½´º_LE½sË—ãÕ‰èôÅÓPêš7Ö@N¤1+TÄfbm%LëÆ*OÂ!ĞÊ¤®¨ôû'­BÛnëbóöú:²¬ªyéS´d¯bûAŒåB%_ß
1{'å*g–®	_Kò#çõ«—Éüız›¡É’,¶³üX¨M°l~Ò2„€Ë×Ò¾§qÅÑ°Ã–%jpI¹ÇØZÌÌš-Àb¨»÷¾ÏÀWG}ıT‹yoÓiİmÊ—âJMoÆÒ§=ò6
ÍSpÂ__k%íN8ylì³“eŒ¶¶úN¢Jà0Kë“ ³ÛÄËY+šº*SÊæÑà.vw±šBï4„^˜t!O?€ÊRY×‘´9ŸÜµD¢Jñ§ã—«×`oˆ>.‰)”IæL@-Xæ‹ËÕÚr¿HvÇ5Ì':«â&€kı²4–Å:ŞÔÖ‚–dÕ—tiº¦
èÆÇT0fx—¦)[“@‘k‡i#ô±ZgtÂ½Ïõ¡ÁßDU6Jkç˜¤‡–›áSWŒãBåÉ»²ä»çŞìIİ\{élYbtûı“ü˜ô,È:c
 æTÙB}Nôíz}    ˜'±’•Øƒœ å°€ğ•nM1±Ägû    YZ