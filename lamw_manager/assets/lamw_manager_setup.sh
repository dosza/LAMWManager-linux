#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="1805360694"
MD5="78e23c14e9b4141c1a2fb98859bc181b"
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
	echo Date of packaging: Fri Dec 31 22:26:10 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌâÿe[] ¼}•À1Dd]‡Á›PætİDõ#ãìI‡`ıhÎ¶ëHTqqöñQ«GCœ(ùr¬J·+Ã$œ!74*PÏ‚øn´nxùô…ÁéF@¶8Ü[˜|riêÀ‡‡©éÁRj%8;Eh»Ãáh @rÿ–c[Î¢KfÎófAğ¾^3m›Q5ğè-´µ”=ª•Ş<åì£İÖfÖohğ½7œ	UŸòÍ`Ì“yY«ƒBE‚”ŒT†Î@Nç€Ò»À¹PŒAW¸ÏEˆiäc9W_šs*Í¹×sü“ğó
¢°(îÍ¬mÅú:ª-æƒòUh˜°}G:Xğîé>nÊ¯
f?ÿÄÚ;«Y›2ªJ_cêË*hl€Õ•2Öşü8´<ú&,|­r,Òa<DÎÀP5VÒ5{=¡¬ÀWäÀµOâuEfyaBBÅQi¼›¨Qˆ×ã­&mió)˜ zµeˆ	àğĞÉŒL±ïÅŞvMš-Ù%âÔSpÿšXv&9jNM‰DõÒôÌ>¨…K‚qu=mÔ¨709WºİaYåÁ9(VèXÖ;«×ñŞO¶j(†÷¾;>Zæ—:oe¶«tY…sM28Ïöê²jó(»{?[GI`cï °ôOGT¥§X!gíd• «Ğ(fY~ÃªG¶&°¾i‰ó¢Š+/‡›VAq¢œ˜´…hx®[g²Ûïª×Éáâ¢h»ÍjA¤öCÚ‘²täWu)Öüå¾ë1åøÜŒKÔĞ	ïK¹®âò¹Ë•Ë’­¦ç>áH^ï¤ò_;³Õ¦y¬/¦’ŸMÆßidF’½pw3Ø·©mÜ;8Û%pˆ2„©¨m´gÚp±ˆgÄR}Û^:ò=h	Ô.d®÷İÛá·JÖñ,§2©*Î$œJğ¦÷¯Æ…İ”ÙI?ÂÊÕşğA½©ÖA$3œ|‰ÏÒæ±_q—rT-À~&·À`ªë{Õ®Ÿ{(»	Cè¾n÷BºBd!À"-t¾™¡hš^}té–ø×j^’4I?ş: Ñ®ä2ß0Jı_ñsíĞ¡—-Á—Ò‘b¸¡ë:—Ëè‚ìgçCx¢lqãÏÎ†}™¤Ô‚À«õU(Cv„í¸¿J»`šË°½ğQ(ÓKMz³GbOØ%æªŸ=˜Y±í*™‰Uøˆ2Kè_1“iõ¬
š!Êİh®”ŠU<‡o@JÁ¤}İbÙ›ó/i}‹rtG,Èò«eAyRÆâÅD÷)Ú3-«Í$à3G¦WÂ(àè-]Õ„ñÖ<[³P®Õƒ8Ãeê´MÙIéML¤¼ì¤¯%¼µ”eØc]¢kŞaC©í%q/ÎH‚.1†SêSm¤İ¬Ñ¶ç…¸ó!Hzù—ŒDPw¥éœú‘@}-'pü][¤Îm(êç½gÊQ¶re—thUv
y•— lÑt-¢å¬´SÉT6Â¸õ~ÔÙ&jTZ†GşÅ¿êC¯dÄ½³|4Ä„
>Ê,”u°O?´t
µK£0J;ö¤7aºZâzaÕøµYg½2lÒ8¨dË@2x—uàèTçĞwÍ“˜®İBğ:æ:ÏÖw¸Ñj5îò¾ ˆÙ‹”CÿuÕezìu!Åü)øO`şúPI`H¢ÏïÄÑ•éœà[èâ¼Û$u¾¿µZ\Ì$pt‰O$u<²S+ÉLuA»ûR¤òvÍCÙ³|Ê=64§õo"ãçà­½Ì>®{A-€1!ÎzM½v—(‰Œ¡£ıûĞÃd~¶=³bª$kz\Všé7¡H`Ìëp¿ b•±û ‰T?a[¡7ª]OÑŸğÊ¬÷:(*‚øIî*~¡ÅD‹|*0 5«Š ¿ïÖt×9êØ×"š6|[ ë¬Ëøbõk6P½]#9 Ámqâ™JÕ Š‘ıêä)—áË[5kÿÍs?åØ—=‚t)Lšw‰i›ûø â°ĞÒö'G]wcÁ9®~ç°Ö&
ÖÒ];…=`‹Õfo š»ºÔ&÷…\o“çp|8ùÂG÷»å††·8°L=îÔRf£˜‰Ş¡}Íµ“B6-Î Ø÷¸§H~¹Õd%Ì9!_¡tf–İnHÏ6ÀAoxGûT<<,Úë¡H¹„rnô~VÎ‰Ò5zD6 8Í6šEç`·_áıU9Ai²Ñ®Qa«…‰Ş[³sgeT3¬@&f®&zsè
œ‘Ä–ÆÁo.°´&y:‰¨DbéAÉàõk‰şN`’òm}Ô¨pûä$˜ÑGF•GH7+áaf D¼[_zS3ÊŸÒ[5UÓ¯ë„Qa²&›]l+^j›ôëçHêúßS¤T¤5ÅFP2İÄXŞ\ÔìTåŠãÖ¿iìÅ~‹r?ZçX|:UN‡5ÙøÜª‡ëê•D…œëäîĞ†BĞˆlvxm7û ÍE9ïbÔÇ×Gp½.Xù:VK3¬šíî ¦¯%ÁÂ~§+arLâXâ³©¶ğİ¿vKÑar¢H¼ç»†c×VÇ¸rØîÉ„Vİ‹9WSŒ´¢$ÆÖ´:'Yqtİ¡ÁjàóÁqš
Cb©È‚zºV“Päî²ôÿêV+1ïÒà‚ã7úúÊØ±c‰R¦ñó¿a»m€hØYØ¾b8(èÎ‘Ë©7CĞõokĞÿ»3“÷
[7«·ò7ÿ—e|Øòã	7(îâ°‰ãÚ›·ixÆŠyTµˆ1@®Ø¥®=å^6ƒ1’5 ?òíü/oÜk1‰Ÿ6ó‹PÇ“k±Ÿş4zÍ§N
+YaùïSÑóÀøkTÏ¨Ä&è¬EU‚²+“=æí¨-Laf£t0>°56ùC+©ˆzêf€>,€
ß(îi'ê~µ2¦Ş‡÷6Q›ÿâ»ñïL(Ø'*s¶0'©m«&k §ÔûÁ%¤ÂSİìM…¯ªBæäJã=Ğ‹L}U|+ÚÎü°$aüøw4Rß)‰ÌG§	©D8KeF Šëº`!±²F<§Î–/Ò"NÅ0è=ñMò\3Ì”õàé)±ƒ†'›]Œ¯r(¦ÒA9…úş9j6œñ©ÓZk¡9£á,ÿ®Ó*áİ©©úšÇ‚ß2I4_œ-äÊ^¨‰úŒÏú$ úõ*«Î/0üæ(q{9îVµf£ƒákJÀmÚ$àPO%êp‹]äÿ$¾:=O½}YŠfîÿ¹¨ÜÓŒâ8âËr@G²j[—œ~à)ã¶ä¤H}¬¾, È¨aŒËèyûÄû–nö¦¾LK7}SWzdµ¹öN÷áÚ_3y0#‘ĞÖ¯å$øÌã‹pyuUV†aòŸ?uëæ°ÀğÓh½:¤h‚3™[Iö´˜®˜ ÄĞ¾ô %Bğ<Aƒ“L İ2MX¬X|0‚åŞ!Åñˆs'£Ô¡³ÖÏôCW ğ˜JU°FÆê×´¿½G#*¶ñË÷ö$€ÍPÙ5ïv7;ıâKüƒ~°m£|vDLw2ş£50¥ æ[-šŞñ&ĞìÁ+Â®åòí;«³‘ù’­ø÷øĞËUÜb(Ÿ^¾¤ëò^Äfikm˜ªÔŒ®½]­È‰ÆëH™cÚØøi2õ‚Éš²r‘kñoùX¼µ|ÏÄD9	{L©gÚ|ÒˆÅ¨Xæ%ösµ2NkdNæÁÛÆÀ3ZXlä[&q‹e`?$÷Èª³mMqÆ}%ışcˆ´mOñ Ì7¶2Ï8P6õ©5ÿ0ÙFCu	¿XŠ +Ù‡ÑÒFM[kÉ›{İ>íµ±ÎÍò$ú"†È;Êá\N´øî“ŞVzAcVu í³Ë ´W1ÄØ“›ı¾Ò¬“q…¬YH¾›­*#“¤> Á¹û9?[6ÙËXÌs7¾Õâ6s>ÚÖé·Üıòøš?[xï‚wNÅ–áóô_?0;JOÇÄÅÂZ7|Œ)ìÂÊücƒŒU äÉ{=‡İú•?ÌnÒ™Ñû JÃ©DaÑ…Áƒ €’–ØÈ¢T.ÿËU*h'"¿:RÔ]hÈËt,S‰Éhú —o
 *Å[UmHÿšp±_N<xd¹ÜÈoÕ¹ëÊt˜|{=õ?>:µ]Òw;tš†6ºlãNDÃé©w5ôüsâ©çlŒÉØ·0åß&77ş—Úó<áâéãĞÿ§ì¾”ü9$Ñ$¶/[Q([9rØkÈîèPŞ—åtşxrÃìñSƒíŞ³uÿ†|d\ú±#Ü™\·7…G5iö°¿æÔ7ƒas€Gx.§ÄêÆ.CsÊĞòıXÍÑšØ3§¶¡/ÇP)@ÿ°×¤såÛÛ"¹n~0U!Ò8nÅå^7Dœcvµ{Rş½#	ğr'ñøm|èÖ†xûæo…pº¾c™3&NÁHÙû”4éj3Œı B|F*ì{4AºÈ §Ú0™4ÊÎ¤
RÁÏ®Şœƒ=(¸?8f$C 8Æpâä
ÄèeŠ±±vğR^äëÑ¾E€‰÷¬‹¦7¸,ãS¿¢_šMã0pí®HF¼>]Ü~ó¯qX– d‰p@ªĞãå}N­¢„öÌâHıkê“Ğ,ñ—z–ÁàãMƒ>µ¶ÛÌúlğë2Æ£Gö¤ŒÆ”ş-$¶÷”ûâÖìl8,ôúÌXM7EÏï´ÑÍ8j†5ƒ£ˆğ©bªÈHÁÈN\P,¯¬OöÑ˜Ã(è1ı{šTõ¥uÛqDÒ#&ax~dÜ;‘(¶H÷ñ 	ü9ÁGİ:Î_y¯ıS#7¬¦Ğ®„"ßa:Š¿'³>ƒ$Ã@L¼ÏGàÅQL7#ã´†ÓëlÕ(x…ÕSÚæŸŠ#<¨·Z} «s`3ÂPŒìîåÀÄ0ş‰³lAÌxM¿ÿ?ôš–
ÑéÔv%‹2wÕ¿’ÍT·ÇwÎíbPøàOdª	
ÿÄ×Ø¥(ªPïs{d¸L&
, Æ_Ïoƒ‰suúIĞ81mD Ê^<rg«Â…VÃ_£ñì^šõ–~¬M ²è|Êï(@Š{MÈ‘®n.ª^îf3ïê¥ëO`e_ìºª,´R°hş–àv×²íöŸë¬È³%ˆğv#SIÙE'*ìg>ÓJ¶Ÿ§£`æ=+ì~h»p¿ñå
ÅşwŞ©”¦FğÜ$³ß!šÒs®—y¼ÛĞ‘@¶ö8w³fî«CÄs“0ë}fGÕ\f¨Šı>*~„ó°8§ÎE.X„ì^¥á$hCÓ?¦ˆæš„áŞTyo?Â)še0ƒŠš/‹…¨!4#ùözÎ*B&Û¹>HÃØ®\ì¨XÅC#š¹jçCWæk¦NáÈT"BŒ$!C†¦ÇœÆğ¤
/…§âÓ+;ù@ùIÃ?8zH6¢³ÊunWÂ¢"èŞpKj "í–aÎ)#ñÒCPö´üöÛÿÈˆ–b‰ßwâûß„µá-Q*/q[Úó4 çIw-ôÑ?˜¬jnã€ .é´	®[˜DÏjz|ø*íÀÌ/«eí<ğ!gäàÆJJNË^[}—„ÂäÚq¯Ú@d3ır³ÚbĞ¿Ñ!hIMÀ.U‡¯—s[)oqÚÎæ–:P¹¢ü(Fdh3±=
[ ¥&!„U>1óyÉ^ğ‚–¥4Ëñ¿J„÷ù'àÍóM _–.Ñ¹•âi:Yçì˜†yê	ÇĞ";ÏàîÃõı‚iÑ„W˜ ÓÎ*˜RÉÛL?(<—›Nğ eìôÚKÔÜ’z§s#^IÖ?ø¨¿ª¸šøÄéqÚÛç–•œ¬)4o.¼zÃéíjÊ^ÇrZ¢¡ç“k´JÎˆ!\(—A¦M“qNÎ_Ó£Şş¹x{Ğ[Ïy¦Ëg(<]×ÿµèOxwhj¥‹z¢NŒM]¾7èäPpâ$_«F?‘\ƒZËGQĞŞ:NwÛÏïÿÊ¢ÿ³
7–ÊReo,	ˆh¦j°	¯€%kw›Y’Õ8Oı˜_ãƒæ5Šf•zw<ˆ½Ò4	lÎşãûç8ƒ‰Ÿ8nVËèèøDÆùÀ-“ë½ŸödÊì@gS?îK¯¬XÜ±Sävì› Í(É"±bô*ÎœëğK³lüà1İ¿ J™äcl”“GØ&ÂUÑÃ¶0êô®ŸvwÚõè£g†ºz¯Q¬Ç;roÆñ›'æ§ÊfK§\’:ç"¶ĞLVW£ µ
½ªç€z5VukÜš¹iKnŞ$Ç¯¶)ÂÊM§I€aèpÍÔvv¸;èóö~î?m…¢a¦}¶‡FQÔ6®µ+ßoµ(DÇø±ÁkEYƒÀ»Â-¨ÒàØ$©Ö!^!·{ò1ÃI`ûøŒ˜D}å<rp pm‰0£.>QæÙuÒá#/„%y¯ñÒ.ûaÿ5—Ë¥ ]·’Jr>º„0¥å0á÷Ús}
d&/ÌîeĞ9DİZ2éWÁ)¾hL¾i½€İÀE:âË’EúIÄÆ>Ïğô5+u0iN¼Ïv}#Wîk’w¨Oİ	²˜yŸ‹ÕÉ—4#j9İZlYĞ\O1^PÅWPH/Ô"ŠßıæQ@ğáå¹Û8°{ĞB"‹âÊªâ}dØ:ú¡ÄÎ8 › \ÃwŞn`³©ß<himÈÍË/JØ;”€òd²rEójæ€ÚóÂm¡!#Sæ)-10”T¦üÀd>ó'`¯<€¸cÁã€n…÷_Ïì€cFÁ6–RËßŠHù8uL¼„Ú„‡İUKV( +gªÛE$b97<°‘M*#b-‡LºVm	5u«™‡]dN'÷î·%pl½Ü[¦ršvL½Ù°*ª¯ ØKñ	*½IYG_aí !0Vğ1Ö”G÷>Q(€õ”xnëf Ñö4‘øf½øYÌv—C! *Ü¥H{8rÛhÛšæB=«ĞH$9ı{¹1Ñ_íÄ.O4Ìºuc‘D´®m—…~HÂÄiÄ”Ìé÷ º¦úº&ü@OoëRr¢ÀwÀA~”b÷7Î“Ÿ²ê˜LBÙÅˆi-"NˆêcÓ‰?U/;QVÏ¦ÿn·Oƒ]Ë2gtö2d{,{6õè7µ±rBœ¹\hØÃã]¦ˆ¯1`g¸nø5FcfMDWM¦Ñ¹Öİ…”ì¤Ë¡0™"pbæêIEª¸UBÂ™„¶+lÅºC¹Ê¢™ÿO‘ØÀQğf®s’Ìfıÿ{>>›5Ñ.cçs5äı5<eÔ›cÔ`Ë;Âsäïï¨¶yûšŠé¯ö€ÆK)0—i†%µO¬£LÍT»Y¢7ÉËÆ	mlÆmUº 7ÌÉ Æ,GotÜãá)N@ÕêTñæH›6ÕÚTƒ½èéµÚ®¾I'¦Ò·Üjïá‘3?Ë?2ÅØÚ¤=İ‘IâØŸ(û9”çÃ[EŒ…¹_~¶û™t-Eb^‘5Ç!FW¢az`ŸGUÌ²Ğˆ˜”lC&„–\°ïÇTˆá+¹>iĞ[™
[VàŞ¹G1¢èÊŠíïô¿åßïB[^â\R‡˜Ó˜øÿÿ»yn¨W/¥[/äÄúÿyø±.F=H·\,€
­­ó1ääÿq-è›ÌoÎ‡ ›’‹G•ù<ª];î½Y7æïÂA Ûö_y±°]û*²¥$ÒÒ¾şB}HÙ;F¤éûV ®)_,X$Ék:œ5QøM8’ğ•yğ%K­ô¯4'¿»«I>,H •Q{uT¼AKµºÑâO¶ëÑ$Nhİ\5fÎÕ†sÔA|Ì¼`¢gyÕAUÕËY_OË¥wç\
õ^ØÏ³˜¾¥¢¾{ö·é–ÄS««\n	Í¿i@‡7"–‚/”8Ç¢PÕkYÿÊÑÅgùmdd¡æï9:õæY¡VJşºçİæşXáx,ªqş#ÑióşÈ-àc9i™ì²É¹HÂ±Mfåç®[Â·ØS'áµM– ÷}\’‚G¬Ÿ²6~ñìTd£PÓèŠ€
†N1Ù,µITÕ.Ùï¸XVo$×kô˜pùq¡€¼˜¦Y¾ílÔè¼ôRìa!T\„ÖØ©Ì½‡ ÉÕÂyÇ¶Á”Rôïye…Í¸òÆúŞ“)ĞZ­cQLşqöüáÕÊ0Ÿ7•…e(»¡£™ß)ÄIÕb_q7°
Ó4I•Ñl3è‰Ğ$eÚÈ÷¼øñº»9†+÷9"'ø\µ(…¢Òc7ém¯%5I’å‰õõûôû£•]ş€äÍ^ÙQï‚Ş»í ÅK{A¸‹õjOí ÊxhX£AZÄoxÙê&-Œ±¿øüár¥BB‰–…¢_¢êêQéP©=•f(âÜ/9F¹yáˆÚv«:)vµ(ªÒÉ¾ ¹ó›èî.“9Æ£óÒÒ²/¥—©0gdp7C&¢ß‡„Çã]-”^Ç°†Õ¦pCíë©o>…ôlAêNu•gı]Cã%³q°ÊĞí1~u’Sòe$¾ÍÒ…ÌÛ6ª&¯À®ˆUM!Ä‘öã½Š O&Ô¦‹òŞ¿oIæõdÅ}?Ò$‘¢O8"¦NûıC»°êo„t¸*(“V©aXÕ‹RMlÈN%Ì+âµ8ñô>(`PºÚ:¯ ó£!ªe•¤"Wqà:ÑdO3á¼Çà$`¾&uB©½,g¤0š¥O]ıı kÄÈ‡i™1¸Î?x?d™u¤G‡ƒsAîğºë¬W–Qêã¦Bß¼‚.ßºÈØFuÔO©%{ô-­Æ“£Íú‘˜ÎÚ\^çpÆOZ¶`Ù‹7}ÜƒDÔîjˆpq‡]YÊ6<”{ ítÕM•Æ},Àiˆ¶>¹ Côü)è' ñ—U;v…Ó¥‘Rq8R~FP±`}e¢%ëøu€@0•]Ğ§Ô?^{y‹ğ…°‹|Sÿ	öësÎÁ´²«D5Óh»¢6^ÚÈ‡ÎÕ@fµv&`	9Ş¦Q=´¤Ç:0Š°ŒÁ0Ş¶ğXs¸FƒL$•½YgS¯î/İóÈ2û›36k…Ï½T#W¼  uËË}%øèä¯pÆP¯	d6¯\Ä;šâ$ÚQ DâëR~`øÒ=f¡ë%ñû§äŸ}Mƒéj¬ú·®æd²İ$k.â‘?¢¬İsì}úÀ£kOë¼wIåˆn>ã+;vË,v>MÄ]Uğs¸>gÏlu©¿{º§×õ™²ŞÁ´
p«18WYdşÑA¯r˜eQÖZ-Ïj
RZŒóœğD©rH5´„èMº„Oìõ¸÷2X¤è»¹ÊC‡Ùm‹¢}ÁíAyMÅ±ª¡¼t¸$ƒ\N•¨qEp‚w“Ù® V½ÃVRWæ!S€ÔDÏ”7aäàQ-Qºù­ì-×1i÷Úñ:Œ.¢/ÈïË~ÌÁQ†ÏHşÁM·¸{µ×µÉzMˆL™–õ÷!æ8N½Ow¢š’|T`Æ‘	Ø0É'ñ ı8…aš(Ïí”l6qê* å
N†‡%–ó”¼_„‡~Ë Œ#ïh@9Ò®s¸ÆåFœÇÏ-«fÚ¬ég=;
“Ë‰sALàª"Ì¡+Ÿ‰¹Iˆõïş[V0Ÿ­ g"ùÍ¹_³»B'ÌI³Ú»#“£ÓÜ)ä3$ì`{ÒüFv&ÒÊp¡£èãc©ŠKâXÙ>:*§Äce“×·9=š9¬ÉàÇƒ‚Jœ|›ËC•p­cÊ}ùíèx ö³±øn&
*6ÒÆÓ‡b'\×öEt£™´ê'7%ÂÛŒi è¥@¹Ã6Ôš˜G‚2”|¼Òçcåùàä…Yì İŸ¾Š[[Éñ¢=zF'ï(à</w”@Wyk[¶²üwwÛıZ!TºÜ¨Û»-î©B'ÊİOì¦V€ƒ­¿*ƒ?/î§4â´ŠBãº´¹B®ém^?cÿÕÉ]Àâ\J`ºÜtxénÚt]Š´}uÑ¿N.L9¢Ø LêÂë#,D Xæ$km«pçØ¬-8â C¸Ìù¯Æ¹ä®‰%Yï@Vóı|g:‡¿‘ômñuN9M¿ÍYØUtN”0«*Ô´CËëcWÍ×ËK3ÎeGˆ"SjÇÛë-]Jø°¯ê	ÄmĞ¿kS%&•õBâ«†^ø~	0¹íFéå‘™3dcp†£’nXp6/…¹8U5 I8’¸ò¿¯'­½0üD¾vckNf`!]šŞgâd´ ‚šÈê£¦^ÇÇ3=÷Œ0ß^›ĞÙâ1¯ìTE)n•R·Š‘}ÿQ¸©. ©uœÕ?‚ªÛ£¬R©¥0ê|o|›Eg£ö¼fO³râØ2Bîà¸)ÕÊ;å˜±aY…Aî\®Vş*Ísá¥=PGÜof_R¸RüûÒ¯§tHçI$ğ}†…5Ì‡ ı>æJb)öKÏqB·ôz2-ÂGF´[ôóÅŠë3‚B9=‹ïG×•nıÄœ™iHˆÕ+îº«{ú°á´kqÀ®ÿbğAÓ¿u#õã]YÆÊ5–{Æ‰•%kBğg<<J©)¹2èãZ‡=›HÛDâ¡?-Xín*9¸¥"öÓæ±ÿµHFFœU3nÑEÂoF·ÿzíD·Ó-©ånBAJÕB'Ií–_Qœx­#SõâLôÓÅİÎ#Ö4â<°AÓ«á•u˜L<5š˜x-{`ï-¾sÂp’U Bû,-úÒP”œ<
ErQL´©¢ÆÁ«¯°€½öøº`O5$ }G´÷–°à6ŠğÁ Måm|XâgûtØ”M˜Ÿ¸O¹/+å‘;?µè7en•°–ÛÔ©:–'—è£—8õ×Zèå ¹v}A$¤OC=hË`?v¬‰rACøú½•¦³K¹…©·£á0ù«œºØ{ˆv›)ër
BŞc‹÷æ}nØÊ·xb§,ğªˆm«Ğ©œùÜ)m Q–Ó}xş@¦.ı¹}d`šU”²ÜÛÓò' ‡ıñıÄ˜:_3*€<<ã\A€—cFd;&ÖÊÊFõgæ]ÙÛ÷|Î¸÷e°Å¤uãf `º©-®K^TI(¤PˆÒ¡Gšy Ö‹‘iÔÚ"·³x-ÍçãÂû³íÙ'Íè+±2^ı@Ñ¸¬óÁã©”Ç[<Ë0I`Öê€(`šy1\†ó/ıÜ\sô&UÔÀİ–ÄìÇ‘H67â¼9Xm¹«j@Ny©œ¶_¶dûß±=,)Š˜iñ}â‰%[¡~Œ‰=İ õõ†¬êNÒÅ«Ê/h¡š¼ÂHäÙÕVñQŒê_aâÔ<Ñ·ŸA _P€¸><]%{@NÌõcÃ^R:ŒÔaú±bü,fŞ‡„y gßWÿ–rS«Ù~ñ!@êIé^ÿ'èAŒPz[ªË¦;ÍnĞ	İÏ4Gã‰WÎAÅö
¾5=?bããé^ÙQÑó=¿
““!p6Xõ@Í;~Ÿºêª²Ã¡"¤yaÚÃnøÃYâ’>ÊTäÇ}¦êy{{Îõ‡©üQÚC²dÓÜmŒœ–şñVMqü>Q<²,¾µai­Ôµ9‡uuşc.«èŠF_ ’–EÕ9ÙUÁ—[6ãó‹8Ú0,ô 1›ûéVëNÙ„xtT˜ûy$€ã<$r•ÄÎƒÑRŞó’Úè|HÓhJ5S„.»ìç¨fĞÑÈ¶EÍZŒ^ê¬›‚U¦u´zµ¥i¸¢!NÌvËÀ¥ò‰¶zkªï·©ùæƒVÓ«éOgn…õTzëš	î–vÏñê†4İÈ…#×(Í×ÄóP¤‚¹Pi'fE–ğá6j„<ï{õÇÙ–c;öƒ!ê¬tñBo‚¢î‚r¶Ülæ6åÎéHÙÉ™,¦y‚÷­šQ£A]j(kSVf©å-Ú‚}òä#"ÆıŸpı;T¨Ô'7|‰_¾¬º‡Œâ–{pÂÛ@ø$	]³™BíJâïî\eÙC4¿%Ğ;ÃØa'É‡k´_·>Ş(}8C:ë¦ÓGw7ôL^ ÓúÚXøIñ>1‹ãc¤í©D¢w’ôİ®c£ˆÒ¦I¦à6Èğûl:¾Z§€Ì$»E¥ÎKs‘§Fîï^ ãû(I/M|9Y‰Öl8€3ãŸu^›¢[[|ÂWªzRª‘£/õ…mª:—Ä9¼köçet–Ì˜û.ë’ñÁ0}É •qÑwˆß1‰Ûšâä/;¶öX³Ùë·	â-¢ËµDZÜ®şqı=\Öe_òÚ Á0¹İ¶–\jÜ9J&[8mHBôb‘lÉ-æ/„Eåg—,ŸÈwôõOé6ïSİóîPá©$,}0­2›ÿß³erbvŠúÇ×Â‚íâÈ?ÆG,ÁÓ©>ğ4c¹{\±;aÁÎ¬ËƒŠ¡ifcù>î9R4õ¶YşI‰ÑóZ¹”æ\%c¿VÖ«ÌóìŠñ–qªœµ&ŒÙ8â“Ñ]µ—6Ç(‘¢)…ä¯{±»Ã}¸f`8À “Ã¼Ä´åÅ†€·~-É”ÿ5ççEÀ„? 'o%®Wlµ¯7·å¬OÉ%(’Ÿ3ìé3ÔN­ª_IKñOÀÔ`‹:O›ËÊæË"Cã¥vÇ%Úÿ_AoàZSÁy¥/ÒæŞ‹(]†"™’Z¥ú¯¨ù'¼,z©¶´}y0Ã{ƒöŠ„0~s£&2Ô¶|¢øÆ±¿Ñ`‹v'=Fä÷Ü"1ë¡àŞ™çÔ9Œ$Üè=Ê‰¾ğwW#/–8uÔŠ)RêújÖÅDU¼ãˆãÈå#qbÏw]úÅÏ9‚Mİ$~TKÑœÌ±pXváÇe§KAàsûüÔÏÆè…«tyËÓ–‘¹8ŸJ®6b$ïåš‡÷È“7¿Ø¨’Û Z´´ÈÖøJ#îñ×‹E³k Û©Óé7øŸG†k!Íô‡µÕàj=ø@ŞRièºİ"	ËF Å~˜. ¿¡M>Íêì¹QDUMwOİ; m)AfŸø0„9¡G:ğ$<˜©~ÑïµŠ ‡UÉw'÷æ'±ª½pu›çQ£¶ˆ^MHÍì=:ôT(Wâ0ÚïÆ¸" }®tÂt×Å™/æÌ¼™ƒ5y>æ 1++ö6æÉ¯?|\H,é/îD8nvãĞu m%/&´R\:@£ç¹W4ó*ó*,ÚMªWî¼0‡ÄHÙ:hÈaÎà†|RŞ¸SbO>"ó«
¨†báˆm®Y}¥åÜ”õy—\/§’^{2*—_@PêİiœìäyöLvôIü^Vf-H*Bù0à\ßÛÁï	Š|³Sµ6ß%oÏ9J¬û–±—]´£ÇÏÖİ#´	éc¥W{Lm–=·ğ!WŸ¬«;şt™Â¹`/ÆÒ8Åe·¸+¢ææF)Rg"»’şÕŠƒ$ğHü9½pğ¡söT3ñ»#¨´¥ÿÉ=æ[l—&»1“¢U&I!.7yÆX˜–´¥¹MıøpR‡Hmí¸ï»ë9SŞ¨#	ç§1ªh^  î¥NYucMµoOyÊƒM=ˆû¼”	º€§€ƒÜêl}†âX.¬«-ªzŠ+]ğSâS-†G©áúµ…òÒØp|ñğúg¨½´ÎÎã¿z*§’	‰‡å}RE†	ŸM¡‚nöèÔL|3ıqí0Å"|	­³¼»Ô~à²:zÜêäo$$Ğà½-
€ÔÇeÑ‘Àf<i´Š]ÏÌjZùúûlB°ƒ }àî2q5At8à=EÕK‰Şf}•£İuŞc-'RºØlĞ»ÜÆZâJ•º´
tWàÊ
XäŠåLMP—U½Ÿƒ¡¶ğšû ¸&]ãZrÚ¢†?Å|³§„ô”EMØ<ıwğFúğEãROĞ Å¬qÛÍåfÏB³‡½˜“˜}¬J½Ûª8ûñP õÓ¯ÈK”ßÔ`…”÷~›4@Zá##Îm×U5o‘zÁ|›)ˆjÏhñ5¡Õ1AßYÄ²^Áƒv}£z5¾X-ÂÁ"ú]G¸ú‘¼zŒ‰¼´¿õ]–ù>Rx¬’’ú÷k¼÷À
¼ßŠÁç kZ[Ú±G$#ñ%ã³¹dî™?0é!sù•^¼f2 ³üµ95Â0ñ.Zœ|ÿr¼—jÙÅ’X!4ù_›}s^rİ‡—‰RştÉ·§ƒÏìÙ…­ ?'<*æ[;LVç:z£ínNvsöd@KÇ(ˆ Ú®*·zÃôJBäÆü]üÔAëöNÃîˆ—ßÅiŸ¢å@°d8_¹¬Gğ5zNêú¿±9ç…êå9„,•»£¹È'QJó¨ƒÕk·Ièr»eã·Ü?íW¤œPË§·
vs,¼§gHN ädÆ£ÎY ö„Ü{ŞÜ#5G`¬ìvƒÖòäcÒòçBò¨U†´|x®É9¦ph¼¢m1‰=øcœæ	AƒüÎİWfÍ„2ùi/ƒŒsÄ{Ú+ÍZM2-SÊº/Eçù¾£”§Z‹¾:CÊ¢%L4ëÖÀQo(r]Ç$¿o(ó¯ƒ6)ü…Cxä¥³ìÍçB-š½š‘<|Çé9`™= ~õØzõ_C•æzÛ3ì†*‹gIÌh‚ÒöğST6»¶%;—w¬v œ—eVÎ‚Ÿ‰mJ¦32×ÃµRZ1<£·NÜÃZE(uÛö™E”ÿ‡Ö÷ÎHÇQ•s#-ÿo>¢‹ÄU]iŒ‚÷éAŒ`€¿—I’*Ù^;jÚ>şZ©šQXÀ­ïujD$tE‘f2§/KÜ×†Ó“Ô`Şë>×<ãîãÂı=«ĞïC(äªQƒ{Ïú³@Y‚ou~ÒFs dç”Åä—,X90Y\º›à2j¼HÉ†¤*TîŞ7¼Æ ûÉEGUÛı®fÕa•°Ñ"İ²E‡Qª¬•ı—EGŠó¶X±Ù›òJè·ˆìÂ3R˜¶“ü²ÅşnÂğ ½‚ØF£Lm¥xÔTŠ¥ôrIó7tYòfæYÌƒª'ù’¬dnÿapÖøÅÌ¨İ<tæêÇŞP[&µ°à;	ñ8®Òs}+m„p>e²îy‚ä5×­Ê‡ŠzgdÄæeºÓ&³ËZŠêŒ5àñ\WJ€‹-‰¾}ÑM·ÏEªx-Ï}»âÿŸ’/„«Ó¤@üı}„»=éÚ£Ç@ +öMT”;Ú€Ò½&,×†÷•œxÜæÂFAO¨JÖğÅğ·/UM–e—	FSB2ÁUÌ•wgÃCb@íbÍÙĞw–=œ¬·¨³OJß«¼8‘Ó­Oÿ¤bàGc€÷_ŞQŠœF$ˆ›DärEqÃäôÿ†ê—Ç*p·˜ò÷‹­µw¿kó^éÆ!$š|BôZ.?ÜÒD¾}_í.Ñ‘.‰‘\à>&ƒê^±ó—A²–ÉÈı&¿lâ;|÷»Ğ”kŠŸ¼Öb0qHZÔÙôsÕß†æ‹™JÖMòtõ ®ŒRQˆğŞdŒ’VÈ¥—^ø\Ó¶r›gS©ãSŞd—f¿²E¶ÉH@«İp„x+Ê…ÂUı‡t\ÜI,¸İ"íÏËd²\éj‡Ñ¯ãÈ£ÿÿ=²à…fQ'ş±ñ³K8pS£Lò8xû‰=5#7-
ıõ“Ù©Ü5Èûìo`®/ÊŞP—-İ£Ğ)-ªÃG%ÄèeüÉ«lµ¯ (àÄªdÛˆAİ¬ÅHã–{ÆÈRx_iÅ’7A·ÿ²Õ–O“»‰Ô+Ù0QÅ°ƒ d‚l)Ü±±lkÁ@zqD=“˜ÖºèK2š~òÿÍûs˜Ü‡SwşÑDÿÔî!C4¦ïÌ«ßG…W}L–àÉ6}ü‚XOm¤%şÛm²ØÔzÁG|B?ÄãŞ^¿)ö˜‡ˆ„„ï ²œ3àé¹á Yî„™üÉéÓ*‚Öì„Hƒ%Ã{øjQvy Ã)qy_Ö;¦òŞ1‚TqJñdZDôEâ5úš‰Ÿ
MÄİ%Ş\¯´­5 êRB&qÖïbRƒ7ár<öµ­5ÜA~­vÎèÑ™&‡3=ûùª!,òûsµ4U7fëñØæV–ù±[»ƒÄĞÊQ^+%tMAw?Èáq%ßj?ú¾İ£®‰“M¦b„¢cõ[~²•c¥ÃÔÔ»¦CûÀu:kc™@’e<:¶L>H4’¯ÔÅ!¾û×Ç•)¹ ‡fTªø÷º¼ùsá=&Cm8Öû-)áSªÇØ*F!tC-Ók0†`)V	£ªÿ6Ã“Ö-şşZ¼\Yw`Œ·ˆ¨çdbX4$¡î}ÑEwQ¾ƒ.¯9ã>£ôÒ{¾.pß$ÙØ¹áË’æ×y,MxÆªÑ<²oBê‚ Âğ“SÊLò?°ÿ¯»9P`L>N›N‹>–@/Eø.W•ûK¹!q˜Sû_f~Õô>&èÜæ.Ù°lÈ\B5ÖpM»lM?sOæ¯·ŸJ½ÕÂ–vëÆÆğôš>+!4¼;¹;!Al’—‘A0–G¶|¨l”eˆûñü³y1Ó­Ì—şñF¿iÛ{€(ƒ°l©|Õe“·¨°±Â”>’D£jê!S€<ND`G–¦^Ì™[yKRö=)sô` ä,}²CÃ^ ¶¬­àVmz%“AÁó¸B×x“ÿ´ÎC¶Ó‘;J™²©AñÕŞ—Î„/gíh©ê²æçh¿Š«Ô3²´sîÛÙ_çbê—I*Û¶|†š™Ä{ë­‘ÉòëÖEå¤×vhæ‹P"9Í$¢qvÿ¯ìsmŸ·1¡kÜ 5'mØ¢te¬û&XÑİ•áùBxÇ huHÖô¿ÚXxx,Ü)œ®•õ®‚QÃkU¯öh€³ÛK1H9j“­äÎË=)^äş#U›ˆaZp=ıù$õ#;eó&Ar¥ÄÏ©zzšd²—zrßÈ7ù­·ÀÅ¦ø2ÁÙû~¯r  ôºå‘fşpù­Î-~n!d¶Ø½ÓuÇÉ‰Ãvø*`/ÄoéºÅÿœ„è–[KßÀ¦V#YaÖ'0oÒGgÀı@Âï+Jû¹aŒêP¿I’Fô Ÿ¨NdĞ
—DåÒ-nmêŞe«ê|<µE=‚Ø³"pFê_4Qô ¬ÊIGT”ÂÚùÀ‹R¸BÉ™»Çãø2lé[İ½B]Q›fQüç°ÚÕ!)µN±QZ&«ŸÜl |>‰;*BìbÌüP¾pÁyJ99Íœ=+ÓC?»ód/1„ZŸÊeŒŠ‹ëª
n˜4W
ZRlš,™œH9±Wô“£¢·mq†‚¶Û(è,V¾È‘nğt"rUsÓMÁÜu¾ím*bàˆWÈ~MÑZ
¾¤#KªÃÂ°ÎTaKİ®½Ë€˜uüÅâât†ß‹Xİ½ï¢˜ÿm2¥‡Gs”L”§œäÇÄOE)U†{’š06“qbsµó;Û+Ûâ‰²`Ø¡Önâ±Ë»Ñößç2¥G·–(èİ³ëH—xÏ0³Õ|
û_í‹ËÖëü/mÒªÓ¹û:Ç¡ıXlG´Ái’CÿøL§‰$Ç´¾nRÔRj›U½—4hÛ­¥eÑÖ@ê”¥×X†ë)&Â8•Ùü–F?¬˜”ø mº¯3mU¶›ÆöQ•]mTß|1}O ¬K@M óäım”Zß£Ë	ìÿ›—*ªláĞ”Ñ{·«<!l)cˆ©©…Õ)—j¶*íğv'•FÄDÂ: 	§“Nª:x¨ÈÿÆ·CÚš¼\&vüi±¨”o œ&õ&Ø´okwÔà9é­>mÉÊ$`åŒL^uªáä»R?™9×NªØŠ †¦¼BÄbiF9F!T áOºĞİõ!Í‰£3P~²†¥Hb9×ì¢N4ÀØä'r^ãŸ‚ÖæL&L!2¤&{G²A“L`ûG.ãCµ‘œsCÀõ…H{G€µ°—*_€KÒd„àf+ÖCµYÓwCÊ*@ÀL‘t¢BùNS›(÷áwt9jd­ü»_vgnV):€´Òù”_ÍAÜ‚û‚äT9fHŠî†À¦9‹¸ıvĞú³¬'SÌs\d»PjWğ‹K~"1VÎZ<ãW•U¯±bp—m¨Îì¹98ïò»Á;Ù(‘àlÆ«‡%ĞiÓGæOMëèğB^ìßºêè4ÛïøêXŒ±KBßÈ_èÕ$ÜdÂàÆo×-™œo¼|Â€&zcñq±~´¹¥²œ«ÉğşŠÛêÏÀ‘›_…æŞ¢ñÙÜoo85"é4~]ÖKñth—UêllùÅP«£C×8»Zv¥¼ã«³¸pÔÚ·ê³}½h"¼€SËa¹*œ¼üOÀÕ‹»Q_àµµ?4áV†_jîòiñÆOGØ1%7UËñjyóƒ@”±*b¿ÇÚ¤=3ÏÛ—êÜö‰-bÌùB¶M0t‚½ÌŠÜ¶õ,‘ ›†;Î<…ıŞˆú·î
õm§›i›‚«t­kÜG˜wnÇÂÒ*\z%î;3Ÿkn3§F; ”ÿ§`G“ç„¡«âƒîÌeş4¢P³«İtZÕ/dö+¤QáT-'‚kfŠ.ã—åøÇ?•ìD=ĞQæ÷Âô:0¸y\OÈñw¾ôÜØFìPE\gª}ä3ŞÌX ¦>VRX³m%‰¯¸ÕL‹_ºßŸ¹CI]&Šú2ÃéTø!ÓÌ9Âì§5?•LÔª´îæI_I ÑeWÒ>Õéì<:y­P¶”fqï'©Ì#öëØÁèï;Ë\\yy¶Guü«…9®9ìØëšØÑ²†Ë×#ôhA'¥ÓÒn<ÁÛˆÀAÊ u®Ö¨5AÒ¦Á+ªHØÅ"epQşNp•×ì3 @”TKMGQSH^èµ‘}Å¶Ñ–™ÊD%Š—l¿˜İ’¶¡ÊWÃ½|2ë‚GÜ³7ÌÿüBøÄ42*À®$AE‰áô²ã2Q²@6A—«Á ı“¯ÎÌ¯ùQRÂâÑ‹hß&õ×Ö˜Ø¶sm±!¯g[´H]ˆÜRÇø¡MµÛ‚$ƒ³kÖpR¥"JÎ(}İÜA4´ãjæïf¹&lOé ×Ü÷ˆ‰Ÿ^É¤Éø›å‚ídÊ)5Z¸©ëE×q"_?i~c³).ÓÊD´WÀ)$j¯èıÉ¬ÇZ0Š,>Ò,8˜!ÛMıßÇ_œ°É’QÒ’&Ö¥*bóıo¥ën-¨]Q|ê’=£D³ÿ&Áw‡Ól%&.ªøWFóµØüé€jÊQş!×#Ì‚ÀvçoĞ=…íw +X(•0px1ôIü7YƒV‰¾QZšŠìx@xb¹-ŞêN(«lÉ§ì/öA4	Õòh-•lÕĞ½úZZ“NàœşÏı˜ğÜĞäiÍƒÂ<Šv‰)ód%óÒÎÌoòZ‡¹ı»K ×íÙ WTìÈeÎyÀ^÷¶%ù9y$÷+@lÂèq:İÔç¶A›8ë×5éxTUšNÚMH¯¾G¯Úñiÿ4Í¢oà|½v2ìhY'{ó¤;ã@õ$ÜááßÆzAšzÉ0Rø_o_>à.â×QÓŠ›ã&”“w…!’ÇUc‹ñ-t»:mÔË!€3ğX^#yT~×/j÷ßÿ`ÍŠ¹§âS;;+µ„éé@ÈYí‚yv’nÄ„LÖ/À‚«eWÂ°uıwöÓ:©í‰*œ$”ÑòvÄ…{›*–ùôE÷oJ8ÂÒp%G Î¥	¨Z9k~´HöÎlÌeÀ1 Ç%ù¸„}dLBÚp4½(KÙW XZm×gëÇUév»]ÈT”Åğ7òy	èa^¼Æ§9@UO÷	¤Æ„ãĞ°ÈîVÔœöGÎ!™·´†·ü1ö+ÚœÚ­İ,àrˆRXDí]¼ÉÈq vƒ3»Ÿpÿ‹Iò–_L@=vÄ/æÏïÀ°UMıy¥KZ~xÁ¥ÊpwyÜÂ8µF	THoG¶ÏÚ·õ‘¤“~Ì¹‚%Ô*Ä($¿ÎHÍ †	ÒG_,Ğ¿Ú„DöÊÔ"š5 ƒæFm 	‹“å*/% Údtİâ€§F‚ÀÛ¼jßq”³or"‚§ÃÛšç1 Df&ŸÄx@nÂy$ø£ÏÏx¥< ©ƒ ]»C›Ôv(©4DÇHéIØßœ†˜.:oa-ö3Ÿ]	İîX+RG_ö…›ãÄ¬9`&‚ïâ\jN’ÍùÑÚóa>/Ğúæe\>è1'T[,Š±¦š‚Å8sHš÷è†qü¡q÷„I§/a$ôüĞùN[u-3Ùó>Ÿh«&÷”¸8œµê½èñIğª@wTêr¶¬ŠH) ‘ª‰K:jpTQ²VØççF9°t.¨²ğ‘•›ª}p“Ì;òoã	r+õ¢—­Ğ«J2­/àC·¦°çÕz2äãa±rîÂËŒtM"èÖï"í@ğ‹µÚ$€ûC<Ê1m‚r°Í¦'={Ê·£d´0KŸ)ºĞ“6:ü£‰@Ä¡õ1KƒCóõÂÖ‚V4
ş˜…¾KdÈÓs€Â‹”’
ñÜ%m{çïÃCÇ#Ïútíûõ6guÕT¼óî“û5Ô®w)¤óä1,Á‡p2¦æœ§ŒM;y›ï,K<C‹sUúy’ &@ÊÚ@óÔ¯ı¢èw=³ˆ‰ö;¸°fpıíÅ„[)Ñ!ˆµTNa× ´Jy|*d{È°JEÏúå¬ãLÆµ }<éÆşdoYœ6•G:câ 9ÉµøËkû‹J›·gLP- ,-ÛÙ4NÛ*‚wºÂªI‡°NsápJ;²İKn´Ë	_O2pdÌ6+¡{•NÖLÌ)²)FÛ°A–¨KÆÖ@ÛZ$!¶Íß%¾`ØK1Ğ¹ù‡¸½Ïô_üO¼pxæp¡¾pıUÈ½XüRb÷À>ŠA£pÅYßöÕÿ€”2`‹/‘êsî?_é˜ÎKÚâb9ú³¼¾ä¤¶/ª¨cÜ¥Â6;P•ê -úÙ“,^j3aÓ²æŞäÿZ×ƒmÈ ©«õâBo­n€ (ñ_ø‰)çÖŒÒ/–”·Îœ_¶(yX=òÛüS	·!e/Œn‘ÿ:á_xÈ-†JVçK¹Peh0QVS
g¥/·K¿¡j‰êón‘‘z»ÏÓã3 ƒÌÓ·ó=ÒZ¡¨HÎ²v ªÅÅpÛ$÷›Ë !|“hŞ4Xy;Ş?óOÃÏ^¾Ö»ÕØ^Ê}(E5««L.Ò ½» XÅ<oëèŸkómìoÍØ˜ÆkJ#}YØ½Ä†¹(ç [¢Øï|•'` ‹ÇPŸ“ÌË[ÆMbêšsHòï¥€|¯ÓÜ{$r(mN:ßT	ÓÎø1—Ç(à=f×ç—ÕExã$¹Ó«é…šºÊº×aqÿ"w®Ø8
yUKîokXSÀ«¹$ñ¾u>êï»š¹•]+õ°{ÜnWî*^›¾ 6“âìå¯à¦6ºš. |ª¾Za>Ê¸)ˆ¹:ø8I÷$¼•S1%àœÅ9ïñEÑ~‹ºÍ¡m«ŸZ*Í…se³ô/Oç”»ï%'{³&wDÎ6GZ„A]n][}³ÍNnQá*=×è†åA(šÜzärbHë B?ì*"0åÎ,†Ä±‘èWTø)İøV²[àÒıdøJì¦º:„Ø3S›İ™Ãni!Úï¸/¦Od~XÒÒÖœ‚88%:…ÏıÏïÀçcÓÙ)$ád“©´½Ñ^õ);ËŞãÈ†_A?Ì™Úhôx£tàñ»$À_?=”¶;‚3â/ob@LÔ•
ÙüãóÔïá|¬LHÇ_M¾;©‹+«Jk™ÔÉ }V·ååÉ7Ã‘‹°ƒKÌJn²¨Qx’µI“4¥¢ú½»·i«yS†NˆÓ’mßa
ô¼%–`¦`6F
|ç?ìÍ¥Ùøœ$ËF†ŸÿÄz¾
â‡m°5Ÿfñ|Ã$
Åİì1thhÙ@	‹+E$ÖƒC¸ç®ë‰Ø §ÅmïD0_İct{ĞÑ0ïû}ÔPHšÁ3Ïa¢n–á[Ó7OWo ­¸1¬¯µÆ’ÿYĞV+…ó¥î8…Ó°ÈCè	:nÈFó4Ö¥ÉÆë,»85h!–ËöÖK¢í;5T9¸]ÖíÕÊT„DàïïícÎ—ïï
:…VÊ&«ÑìMI„œPµV;aøÙpçökˆ ÔH‚XíIIŸ·AR§;!¡s£I­Æ]FTö1(1ú¬Ù¨høÃón!\7°f,21ìê[G³ıÅä„DèÁ—É7ŞÚ
veY	ÔSéËî7Xæ•_í-WÇ„jP9.A|;»_!|çe®%…"…Ç¸aŒV•@«Ôá€Ø¾úIÛ†ŒpKµ©>ÖRÿ“w÷FlJk¿Nöe:X€?n0KFM=Ïj#±Ø(îä‡†Xğ k×ĞGB ×ÃÃs6Iÿ#<tS6[@ü™º6–£sx‹ìñ%ûú­¬¸Wbò"ÃñGUırêá¸5<1÷i¬qXôùG™r‹)½/kÙ¥'Ì@‡ÑÅb©¾‡H4O½‹x«MK×¨yˆ (¼ÛNv•İ·µí¥©ôÕ05–ÜãFI»~w¾(oôÒRB3ĞL»w¸ƒÚÍd—ße"æ¥¡¶,æ^Ü'ZÏÊt^¯û§¼à÷'vŠ®gŞr‹Fxj•“ÈÀwh³ñ–e@»ºe4¥ˆR$ä­(Ù9¼×»S×­õŸV â‡ÀgF½C{ÈVR¯é 0jzí±^– 8V(ri!íóP5ÚÔcê;¹¹…É½Œã—Ûı# <-=}’YI&†ùÒùcÔûC²èõ@JwÛï	3:Šc·=p3÷ü¾3²w*ãş#†Ôl]iZl HR‡£Ûì(ñ‹÷agTkHµ„âŸê]7ª¬®aåïO7)’ØHØ·Z€ëÓ¼ÙÆt§¢£íÚWR¦…İ;Û±ù›€È©Ñ²åxC}MÎ‘'¬²ˆ—25Îv Û¤yø#n¢<&.â[ÔÑ·€#XVĞŒzâ¸ÃdvX?¬Ó‚¤´EC=KüR3¿è¬_pxÚ™·¹+®šK¦^cMµÒû\˜¼¦‰yK1Ù-RÄİkpcª†Iå‹ØĞ9X‹ÙÒhxR8öŸ4uƒí²j"0Çh±I”¤í=%ºuêOÆ…-ÿÊH­ôØ,úÕÑÿ¿5ø­,DmÒÀ(Êqw:’ñ›Ì<İ3—ÚöÎ¦©–Hk»c¾Fqs 1e1Wğ–ß¸×*s”¹¬à
…j»wJj*°w¹;…™˜‚=ê4qXw—§`ù)¹fæüƒ-Vq!ú&{rSU‡h#J»¯ê¡¸W1¥{âvc‡dEùú'‚gY_†êh×#í”#¯àŸ¢IÊy“WšåïÊm`°Şü‰°İÿ´5c9g‘Œj½»Õ]–ù-â §¬ûü+ñkÑm¾¸hU£äfç'HO³Â
qÆtÆ{lqIqGNg¯œ9)ÉúÅ££i
ĞS¼†q²@µ£·Â­°?ò¶^sJ“ğì$½|Lïãª€ûğ{´•¤•è!Qùij,+RMüAÀb9wd2u¥ÎX	EXÓpõÇµ¾‚'Q•æ/¢8]Çï*Ã?Fş–»†àË'>ëE#7«nºOaµ´‚SdœGØ@"j{r€äÏ»¢ã$İÀ¿¬ƒÎ•ŠœÒ­Ék*2eqÁ·åİâd–{úKšNµ…ø×p¬²AÀ7èh¿Şû:¬œù7 {Á)?,/Ö£ ô>•¨:ı*÷íióŞ$3º<å³Ù›^×úÎ¢{ÍtF×º¯¬Øş
GºşóËip°]FtZcçéø*½‘Ø„¨˜xŞO»LÜ\”Âpº0%İv±z¨S5l¸}‡kI©Âw®hN¥ƒ+ÄûĞ^q\øF×c“_
½ÅÂ£àıã7À(JÛ–ï0r+ëÅÀ¸Š÷?ÒP¬ö¼¡²ŠXº·J4$VÿÄß<¬‘ixRì'qÄÛ¡NŸåBª@	Ã„ºÇ 'ø¿—h™ëI%.Œ@pcØƒ-§ür'½üy;¦*jşehdc¼#¢è§o‡­)NtfŠD»¡õUÓ­5ŠJ¨Ñ³tø<zƒ¶mÖ—•dÃ/šÇjƒ¯+“ş\bScµÓÊŒ6{ÂÙí @"ÛAg:^ÛÒl³A$Ü”+’Ü°ó÷çA>_ÿİ…®oTğXx5E¯ãÔ+‹¤Â=xC%Z2=FRnÓI“©•¨µÀÿ,âsÆÍªôá	>86e9]^ÃÎÊhºIè˜ah)çeq1†mIúÆ÷ü|šÀ˜¤ûK˜ò-¶ÄKÏğÊ°õüQeÛ±Øm.C²N™xm=´(uì†ÜÑ¸†ÃC×)l‘®š‚TµvëïÂJj¥}¹B°×˜[¸õĞu•	İl7÷2ßÉäı]<0&<jîÆŠ˜À£7şQyïš1£”ivx=ªşéÉİ!·é+¦vä¥•>JyÍaKoê§¢¥LYøò•Šä¦öÏiÜÀ‚`Òë,¦oHç1Íê8 AgÅ¤ü#·£,§
v+Ì¸Ñlmn3È0>M³8I¤pğì#µ ¼Š@ß‰U¤È±¸ˆ´?v…Âğ»/bRyl-çú‹ÒVà×ÛE_ÛÀÁ‚e/NËÉOj¶øÏƒÚ	|FŸr=´†ëXSƒ1¢Ï0AWÈÒÂ¼Û˜}BÖ¦fÚ.rW~DL–S ‘é¢m~^8gƒıËıìïy„ú-õ“à"‚ò5ªva†>z¤°–•ş²ğ­Hg#ØdëM´ bŠkT«Q qº|HXWµ¡‘˜ÈjÖˆå£üOÃfS´ş“"”ÆĞ7§)ÁlE6¡l$˜‹Š×÷½M‡u•®2:£çÀfôVÂÔÕ”fœ2[#¢ Éo)…ó_©+yÛ-«›¬ÑZ”Iw¨ÜÊ`,÷³¸î_Ÿ¦Æ®=„B~ßır¤b•Š½€”¼UÏ+GÓ¦‹6¾™M­)nBÙa]Êµz?cd <~±µ¨ÚıÚHP —ÑÍ:SDa¢
†¤ =‘ãct=yÀê
OMÙ‹©s.†§3*aÜ+øxÏrfNbØŞ–1X˜ËÑÊ/(Àò+h,w—qEP¿W³‡tVëş~Cz5Ssô}_ fmäg«j¹ºÀAÇdO`§æ-Ç•æ?xëÕ{LË¼f¹eûÙ¼PöS³ƒr×94âVuÈøa‚ÆäÛ1Ò5²qR•û«K7‹ÒĞv¨²UÄØ.Í6vùÓõÊh¶«SÒXöR/brU®ÄÔÃ‘s	9Mğ¦Q‰¹:á·8÷Eåk+äD¥—ô](úYÇ»>é-?e¿ lñAù ”‹T+@D9l=W¹ASÔÚÁHƒ¼D?x­ä5wÀgóp”~ON–ı›|¼ÔFv§ü¤E_Ê.R™ó®ĞG/í¸2ú%ÍşÆ¼J‘ràÒaìG@”·x|ğÇB†öÿp‚{céğØ¨?‡İëlúîùø©i©p
áçu©­ò1<‚—œA*®ëDËÄŠv\†½u¼D´Æ;®ñ)$£I/Dùb{¥ªã‚lXµ8h *›v}gø\õpVOJ[Ç€Êy4™yQã­^íÿ[ ñ„^úå4!ÿü:5ãb““Q:8ßÆ:/êçÍÁ¼èX´J­‚3S	SP
Ìd<*@=p§ş¸«r1·˜Fş&Ô‹Œ½¨Qq+Mx1ëPç“î6€ıKåÖfX~§
¢Í¬ÅõY8¤÷ñ¹óxc™H?ì!2ŒòMÃÙ‹ wˆ+ûFüğ>Î·ÏTùÔb«Ñ¹ƒíå?G‹~¥€ì|”ŸY½Qn¼u×ò×[W²äåFå« ¼6'ÙDœ
	oªL‘¿=³¸g°_”İ²Äî±L ~äv‰köù©Ç%Re^Z™Š)¥¨©Ÿ/vác²¢µê‡5L Ã7ß`¶U²	­»+´#‚N¼§­’|$…2Ç <šZ\ñ{š€=ƒ²CÊ0´ş§ñ—ä^>nøÏ—QÖÄ“6¦–=™ïïÜEAí[ô*ÜHš8Œ¼THü¿P²–æñ0''ë\b•³h—”)2?PôpYş#FÜgĞÓ>Ëà^â9IØl–ëJnî6×`!jJÜ®}*“”w–Ôì—åh²Ç6‹&SeßMbŒÁº??v7]‰ÄÔº™¹»!ıÅOP6<ÚûÑ ¬‡ ¢SLû»~œ¥M2ÁWexë™¶AwÈ±ïÉÑäëlÊ‘˜_Á	˜h¡€-*/ò¿€§ÂKi~ì ˜Í}zò“Ã˜C^xÚYüÇ±Äãe* U/ÈÌ~4+ZÍÉùï¶Š¹ 3§l‰¢ğ‹V¼%à’5Õ%²¾Ütşß
ï…²$È:UëA»ğ…Æ¹OãÚ±›üQÁ¹ª(ÑçM³GZf”ÓKpx§zñ\¶Ğs“£;ZF&M³±Ñ\T	¼Ğ,òœ2bPä‚È2Ë]ĞËp5§õŸw’şlK¹#ßrjıµcg)FFAê!’bkÙYü	ĞæåEÿM„%é•\£"¥E‰5ÉÈ!Cî(T,ş›éƒNUê\!t]ˆBş²šÂÓÊı_D¶ZeÑHFHw2„ÛñÎ…\Ó¶MŠ>[ï!ºÖ=|<WñĞ°™uÍ×bC¸kê&¼á 0.h¸†ªé¬ñÔ¥×áJ€}€¼²û0”ŒÑÍRV¸’mšîîªJ\Võ@Z'ÖN<0³H-ö²Š[gs§$]Õb¦ñ9‹üæä3ÉíÕéês‚å´jŠ¦Oæù¯)D\jı§&æİŸ]%„½“Èÿ—ÊÖÍ"GænêÖWçıd¢v¢È2j’óš6c°9/´ò©d RÛ¼œOâß
m4Àı
¦ç)<½#K¸Ê­‰©ÜÂ[HÄkà)+æXı©Y³vŸa*4.I©3JİNáĞ™#Ld”*—û»/*±·îÉé—¦X-Frù³Å
’¨S¨?)¯$qõjÙ4Ti–ÏÈ´ÚGÁë§_p;ı
 5§»C¤À?²ÔbzÊm­ünÉÍpôÃ„Br÷êg7K”®I“"¼,†

/ê8Æ•¦úêkoRàn5fS¬«U¨¹›º¾@ÇÅW<›&
v¾ÜIbş§Q®{@‚àÍ®ÚâoÜCÑË]qM¬¸g©ÜÛ×ı‚Òè?ú((üÕ{ü$eV¸&çê†6¢G$1Ş`ëö¸b×ßèPı—…_tX‰¢Y‡9²zàÜ@Äå‚¹ ¼{|¥¢G1 Ô¯³‹/š€C‰^Ğ„}ºóY<>DÁâêÂŸª´‹‚€àª™»g%Ë¤Rí.Ò2,}µéQŸŞ(‚²ÈÒ¼vF
{CH³›®úĞ‰9õÀ7ñíÕ°¯2òÅ„|h3ä‚¼m½Nî!-–ã–„,ëğEñ)¼õú]Š	œ@aŞ%Úu®¾Œµ»2+–ˆÿ»AO¹ÏdƒKc?d“^÷Ù¨èó­Î˜œ¨{‘ŒuMJ#Ë.ó®O$¯!21$´ì
Rb’ÖHpˆ;Ø´«–Ö¦~ÊÕ=Ş {W—yí³'†=‡[›âÇ¸Kô|ìÚ¢p¶ JI„Ñr9u¢N• Ût*C5}{=e¼’Ğã~ÿUv¾/:H³.yp˜vF¬ì„‚´ïMh‹æÏx¬ Á0\³Cëyo6tè?æ~"háİÑ,°L4è»ûBûû&è[ˆáì	iÛ÷6
J¾ƒ ÷*>è_LœKQC¼ÑØ4êà‰ı‹ó±U6–Í«ºƒÎæLíóÔªŒƒøxš v¤`±î§YÁãY=$Óò]×[Ñ•FuÓó}uÆ:^öã†êÊ…î7ó|Şvi"µÛµ3Ò8ÂHW"¶B©õU'eı*ÔªTRu8P:XˆGåÆ È¿›¹Ec³¯ó¨4•$%Í€Á€Z®•TCé"±IÃpn|›gyÎt¤@häœV/¥›3ïL?u«¸ğ_Éä¾	C.+oVHÓ“ ppáÖ/ëÙE•—æqƒ5İ[·üéßoîº±·¹ær¥£7!MÎ{çÅ9àz‚†—"ŞVVqjF”»ÉÓ¡f6_(zgÒ«¯¡Msm+!ŞvÙÃ±K­õ5¦ƒL£NÉı/½¿kš¯w(6KÿDÁ˜›Ñ§˜*rÍ¼ßÅnœş	Á›aÓÂ‰×¡}pÇéìÎôÚ&tlÇ&ä„ÚšÊ¾¨jÎk–ë$İ5~”$XõáE27ıØÀmq€W-,æ×ıK‰19=©¯òXsÏ¨a®¶+z.'m!MæÍêÉÖ¼'QÉ+úZP‘¡PŸ'n¿ÖÍÒW/áõşH'c˜F7ÚñPÿº%<M-¨_¹}	s4çœ÷ynÓ¾ã¸êvéwšeëÁ7ÌI[*Â'÷?¸>ÇDHÍJhbÙ=__cïˆ]T±ÏòØ¸Æå_obo(ß!oÑÿROyTÖ½Zêç®÷Ì~ ¥n*\±>Ù>.PSßº%ú£K-â„yB wQA7u1½şy¬Á£@ŠÀ£S&¼Ør$°;l“f Êˆ°†•ÑK]ôo§™ôh_À®f½ƒ—.1¥OæÕ°’;ı×ˆfĞŒjœ(&ÓQ‰càÛÎımCåq‰r¤@×ö?ì²Í”ŸÓ›ú‘ÂjÅç… =¤S~‹*ü…ßcèÄöDğlƒ)ìÎ
º¬*"'ÙOMôNVl6x×ºšk+@éq€Ñjòã|ğT`TkXê3ÑIO…ë¦÷hI	n»Ú6©LÙ„Ğ¤ªû/6üşp7åñğ‚Ôw›ßD0•ş?ÕşØ³£¥œ„_ÿ';ß¨TÂÂ5Fã†r‘àöŞm\JDôŸÁıİ©S%çKã¯äú  À:‰‰Ó-À‰ ©ŠB­+<¬Š?îï¬N½cpaV62…Ø'›“`Ão&˜İÎT~“Më™•¿/ ]1yh7£Z6FÄÒ¶×:ï“á+3Ü½d¢òa}•Rµ¨ZùÕü›M
W Ìñ¡/ºãw	‰â'ø.^y÷ªCwÑR£Ø:–C$#)ÄŠĞ€Ş¾Oµ·Eñi]}\Yét:u-ex.b¨~Ğÿ]¢^z‰èa}kªæ`(0„8dÛEö@c÷ùTáY5±µ9=8I»5ëIøµiBÈ[†‹óËyº:åE¢kàˆ9~~Ä_&’èCöÿ5§P¥‘/hÉ›íH›@Ól\Ñ”ï·1›£å¦œ ¸ìĞëe²ùZŸ9‰ƒ·-È>Âı›šõpÿ}{ÿçñı¬7ª#)Úå\—¸Ü9ZF©‡€É‡õ*™qÕ›êw,áI\ÅÊêË£8÷-÷l´œ˜ğk'#7j&Æ‚“½Ëe«ŒLôË—Ãq´z»™JŞ3Œ	«^JP¯|¢xµsafJjsÿ0[:²(2§„_…‹Ÿ¼İŒæO‹^<a{¡E°V|kÔµKÒìuŠ6ECMM[èhx‘xş?T›ş\ÚîáK—¾z,È’!¸¤k1Foú¼½/o`ú·»;ÄÍ±İ†Ó€’!IØó+E‰›‹ö«Ò/Ì¼~êßÀ¹s9h §Ÿ¨Uf ¨±µ•ûEå©y/ú¸b)&ßÃ‰°•8'ûÔ¨”å®1[Lg ÅFˆâm wş.nÎòûjÈ+iØÑË(µi»¶gŸt
ŞvÕœ	 <»ìß†NºéBø—+»Í/ı!6vÍ99¹njhtÅYõ–—p[{1Ÿ»÷Ğâî\k±S;uùÎèö™)eFNw¶'vTê)±‚x±½Ù…{ü+Æ‹SƒŞËX¾ï¤¡c˜µêKá¤Ü‘½’g4\Ã¥¸İ{^]ş¿ŞÄ†P”î—€Å&¨™©i–·¦ò.’tî6¹Í/²3©„ß:¯ 	’æƒV†Y­Ê3M‰m9übuğt;O™>X«Iòpe§Q¿\ÌÔ¬ß!·ÆH
Ö à¥•&ZšˆW^ßP4œ-rúáhÎ+dÀI"ßäEÿÕVî­†Î2ú½£#ÁåÃQİ+ì·£~
0ZD¾ë{ÈÈ°	Óx4è‡ü%LpÛØWjËÅÙ`1LI¢èİródgˆÇpV“Â¥á8^²K¸ÏbÆñ<A‹ÈÖqNÈ/ew”%!Ûè;GŠîÇê*R¨~Kò7ê:f†ÓŠTØÒûTÈ‰ØØpD>IÄ*zøg¾¾™œúå^‘?¡
ATî–ÃZ¤¿ Gõc¸î|¤„èèPÅ
nğ‡|¯ršòäí1:|İ¹¢ƒê”^Qƒ>ú ˆ›|:.“®Ñù§m*`8KßBÇ%¶…ËÍŸ~€cLª
{aû,m"àK`ğÒA‰¦`ã‘üÊeÃ†£a…à¯‹ µ°6—§Ã±!o¨¿@Ş—`<¾ƒòûÄ¬/=.¬•Q*‘È/íÚé×Êÿ÷&‡êAúÈ=Ø)YRK}D¥ÜCY²±Î¤O4È|Õ•±cNäï¿jwî_ğ<2TÒ~«h 2¤®ææõÅ> Ø¾$ºş½9¹e?ÑÄ¶íO<–²ê½@ĞSÏ±Ğ(p
¶¥Ø§EñfWÕçŠTÃ‘£ó®è–î§rWø¨îQõ—–×MZ,_"…1‚ú)Šú)rD×€»;;OøÀg5KFûór$‹GÈ><†æ¼"XŠl§”Ú@î*å—büªŞ¼’QŞ9MĞéMË?Õ‹LşÕFıX#—! YÆ¬Ì²úÖ¶â4I6^RÊá¸c{õÑ: È=e2Pq ¾|az÷ñ}@w¡U¨#ö§Ëöª‰w-yßE‚TB 'bÊÃ7ÂMc!^hÀ+İ:~]Š¦í§aC½â!MÚSSÓt®_#¢Uk¾ˆæß—H&˜ĞxÓl3ÒÒ«”;Akn2fÛhp¥M•$@n]|×maqÿñDÉÒ#6…îäRâ˜2UJqD¹[økâ¾šî.l¡ÛäÖ	i­xúºîè*p[à¾ˆ«¨xk¡—]¦V„˜ÕÔÏ…6‚µ—ÿöo™ã GĞ¸E¿XJ0±q?¦AÚódÎ°MKD±[Ø®LÊUr™å/½¸ìÕz ŒaÛÚÖÛC$å2aè•‹W[¤ùü”Ó»XÕ@>–n¶V÷¨+‰uÄm«ÃÍjq:ÂØÿãÈ µg9m>©]!;şS1Ìˆ`@	½ßÕi§biÎ¶ü+{Ö²³t("‹ès–'–ë(ÙH|©¾šPˆ£®,XùÒ¥ô
‹O…\Ï":;¸î9‚–:S+§^™óş¤™!	8˜Ô‚Os+°ZßiƒàÊ©5'Õ~ëD¼á¥ğ-¢æ";w†‚çbıJ|v˜,Go£ìmŠ×\È°8ÈR¹q–)N÷Ÿ×uŸ¶t²lå˜®“ùuÖlàrK3|Ÿ·13i[ôâu¶-ÜÄ"®„fƒWGÈLHúnG‡É C’!Óús^Œ7Ñ5…%Ù´€*w ÅØÜ¿&oL^¡tø1J\3³•Yg˜ïõq–OKIı;0L|ŸŸ M;ìıåSí‘”N ØTkİbûvxeŸ¯D;÷?wÕó×á±‰pl62âg…c|÷­Ù¾ 8(--8-¢¼=!c¢EJç,Ã)ŞzÙ£ˆß¡úiÈ\6“hsñÄ"d×é™18´!
øi.¤üpÍÇ„ÒF¬d}f1EhêD¿€í$I–İÔÚiCª1ÑÔÎâc…¹XZ™€ïß|5¤ŒµZT
w‹¬ÿ©ü·¶£¹°_Á_–/XB$-§Š¥ä¢t]Ì6îİæX±}ÈËÒ6UÈrÌÀõ™ Gò¶:öço´n±Ä|Ö$ğoÆ#ù¬ÏWŞßR›™	ÉáĞjŸ¦ƒ^hr{í ›PqÿzÉcg¤ÑhB mõ¥´Iá-¤ 5!
G"bßîãaÙ:mÂ?(	¡ÑÌMÎd3ãKğ[yÚuZ}Z»¯ü!İ²UçA~ª1w¦M£Ø 5êÉ}7F^æŸ}fAÜ|ˆİùJWSd ÔÈUFH”—·¡¾ôÕ¨î—»…ä]høÍGìrØ}nş8£ş$ƒ@=ØÕZ£ıÏ#^ ès¼.>GD-Éˆ–¨;ãÑ_;
-y‹Y¸'(¥Ù&¿5ExİM~ã²¡ßZ«å•k(ªÈXŒ:@‰wlæƒÔÎß‡Úş¤¤%{²½á‘?ì
×G˜#‡ø?£›†]‡®ƒZ¬[eI¾Áe]û¹¡¯áp/êü«ØÇO’h<ò†é»2€Ñ@+LïxûĞÃáŒÅ‹õïÿÄßTª©õIülcĞkÕMi ZĞcfæMedkíĞÃâ€sOk»Ê‰t[]ÿüâKD$dË›©ºRF=¸£Óm{*‹GE*!Y+(…}¡`è	`[ËÓh¬
/»˜(2êm–ü^”ªlbGK'sOræG‰€À;Ç4ª©Ä_Ißk:ñÿ €€îgºzV©‚2\ª™¤kb$ûw'¯Fç'*N‚İ`ú«4ĞNY.§NàĞ¢<÷ØğÇy•2©a³C¼ãhzt*øk©2Éùéªõ°]ºÅj§$",2]y1È‰lŞEññÿ+L²İ„ğÓ»ãN¶Ü«À1fª,±†Ùu}õ¼ƒ[+l¾Ãƒûfj²FÓZÊFì‰-À{Z<ÇiCú¾¥HZ$úÏ[±…P—ï+>JÉò­¥A6WN«¾õ‹$»gp ™ÖeE"(Tø[’vØèš|ŒJ>P£ª¶fÚÙiš–âö¥ó¢Àó¾ñ±ÇVù¿³+IMüÿqìÊÂ;e¼›³l£ÇnîŞ_u¬}cää=c—àÆì„N9Æök†0€DÜ,í0Ò?³ ZXyuÑı‚2	&:N78rtö‹Ï‰@ó³¼~t³Nî¥½c6û}¸¥…ÏìÎXıĞ•óš’ÙM™iÍÏÜ†Œ6rBŞ—İd› *\³í`<™†ÙxåÕàd)ÂÌàmüÓ%ªb(ƒÎÉ5:¹ç´^%¹2CXCÜÓ¸+   üÿ¯Ò£g|… ÷Ê€ËstN±Ägû    YZ