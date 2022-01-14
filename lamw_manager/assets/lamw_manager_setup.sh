#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3958768710"
MD5="414fa1c031a6ccc64e46c81f2c74a473"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25848"
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
	echo Date of packaging: Fri Jan 14 17:21:18 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿd·] ¼}•À1Dd]‡Á›PætİFĞû“î7fM¤Ô/Ø¨ˆL½ÜuŒ àø¥z©‡é0Ñ>ÀêÏ­fîI½	O2BĞgÍßLâ.±"|Ò|û¥–^ôO„QòA'”|nÒÉ‘½cÇ ©ÔÃT™‡ØëqÃ"HCÕŒ6çMÁ#•UírØ`ÁÍ…@úv>¡UhôÛRrÖ$¥4İÀKÔ¡Ûó}Ï¨J†<†ä™‡óï½êÃ^´W…z=.…ò³š€C²ºrò:!l'úDŒµ ‰? €•4¤ˆO`·ÒYË„á‹Xµm‘¡am&9Í0fÚç|ª®>)%æVYŒ<µ¡ÿıy%>ôÂ]5wFZò
}ÕĞFÜ~‰Í˜ì‡ÄA½q=şØÆ´„ÃI=ãöŠeƒ7<Bñ§õø{ùr.’½iE×©W’qB$T¸Ş?ê]Y-d¿]$kh¸ÖQñÖsŸ¢æ/ #ğzd÷á3şÎª´fEÅŠŒ°9;:
`PèEõá§w"\ÚŒÇÖ'R}J¼3?†Œ‘©•0jÁºå•ÃÃğ:GVH‹‰9õñ·ÚïõŞ!#¹—ug„<×iå¢9¨”Í¬QoM©&ˆLÕcğj
Œ¯C®l„31ô}µÕĞ«´•7³€>ZìÔ@–c¢ËñÏL¿w¹‹§nø¯|la;ŠœLËpû¦ä])3^h ´*2—jf X”şk•šï…U£C,yŞ…:…ôÕ­®j\'¼ilÚ¡Ö³V:qŒÅŞ¹	áf6Ìç
§0˜­!×Š*ÎLØàŞÿ‰xñî"]`#Ê<],¬4‹İáãï®zS@¿ÿ@'¹Óä¯ÍÕ¨q:BãíeäÕ<%§¹M˜”Ùú’&CéÃŞÂ¢	<¹—-ñó!2BÅ‹4eù(]°n>ÈDl„‡<¬¯/[ÃxwY.ß#G †ÍnÑ8#S•#¢@‡KádvêR÷2nÁgZõm+`{ùİ©»]èh`ï1œ²1¸k;€7pĞÓQ[Ä95£} úÏ>4Ôõ}Ç`»YÍ©ÒÅ³7Í;oå48ö¹Ár.ë}÷° „†„Z4\Îbú¸ÖÑÊ·òôZ‚–¡6–üf	èy{/„9EmÔ!Œ™QÏ\˜RÌšşÉvüÔGVc¥ÚÀ ú,-ÁÂ–DÈ
m-í–ìB°º¬æ8ÃA_ÑŞd¢¡—KˆÕ àOĞŒ§šîøŒ£Š®¾[Ø"×ò\¡ì³.¡\¥¬í-é¼·ŸdÔæg¾Íî$;ŞÀìajx„şdë¶ÍÁImİëŠ)-›ÙhK|)´v3„/`&Ó¢òïy™“3ı›Û´ é·ÖÒ(ÛëB]ùåiwî~dB<Bôô [R‰¥1æg”´w”îµÍ‹…ö -ù~¨vDª–Î11°yõ×îZ^Eö¯À²y„
S{G]í(c²_0Ñ«J™ÿĞ‡*¨,©®#Î‹M8®ÑGà ·¹Ãd¿Q×µ°V´â
g4O×¿r[€œ8öüÃ|ôy{ùÃía­®áÂ{Àqøª;u(*Ü,·’eˆêBµÒØ/¤äåï:æPI¥ ÈpÕ~(Èòú™„Ï˜¿Åîÿ½È+ğ;<^.ª,ºØÉ ú:½t'S)9±ü^'¥®fQ^:@÷¢/Ã'ø4ãö÷ÈfİŸ°„’E–\#•7µ4÷õNw4ôBt‰<ş)Jô1â¸kX…Y"/ô¬™H;@Î:Y³–vŒ[5z«Û@}Ä€&4	/ĞFh ‹“¢{6ÂUÁ‡¹0&ß´2ºl&7^²áLzDÈ©ãÖyüÜoXıibCç7v8AÚç¤5Ï7“Q¿3´.¹Ş˜ãÆ“}ÿÀf§+³¥M/mÙ"CÆˆëkxã=AÏ=°´×NLºBËÀ/:\#¨ÑcÒ. ñtßsÏ]Ç4Ú¹Ü¥äñz†ÓÖİ/‹¥5?·Q§ÀİÌ¾2‡=a<\ælÕÂ¸ué¿J9iG£õ]>Ü6:Øğé¢‘¾¡Ø(”•ºa˜Â©÷ë‚«Ûd¾_g{&qÜ}-üÌçkEh•-P=¤º¼$ğ‚öÓ¹mÙ2ñú6«Ô#”K²án{¶«ñÅG”Ô[Óˆx¨E¬eÄ“*tn9ÜZùŞTê2D€Âsì‚Ú.¥CËÁ–à#@òI„ùw{€ëHAéd‘uŠ¶/0a‘Ú¾ùAßåRù‹¾;Dte§šÉëz£õøªJòı%ÓàqNôE·Î’¸s¾B³¨ ´Î¾St%´aš¥ÉŸÛî€yÔŒå
†,7~éIªÓ”ùù¶Õ‘—ÆİËmà0Ltû^ÑrŸ[d¥SÖXÎ†Ïxôè×z.Œt¾ñ!íÄ…Ê€mÃ¦_æˆ¬Š.„FÚÈş`œ?Ğ¥ˆ	-	õ~äIúRUäê_0i™éù[êYØJ‰\sP·u”-}ÂPÄaÆéáÏ)İˆ¹DË8—]ówNÂgªĞk¨>QHGŠ$O-^Œß\ôêØSrñ ö=–ˆAëJßÃ?ÿ1“u•q£a„û	š…ŒŒÔö(
Ó½ÒàÄÒ­„§e¬$Á±´–yAœ4à¾áò<¡	‘}M*ï•e’éÖ®ØË%.Ÿv>—ÂLÃ¬<I8H ªã â/…s§øÍL9.quºk]•½”•êm{³ EMÕîTğ²	ª>>Œ/ìO–òÌ>¹å”ˆVë™ŒêPĞîo{.G8»HHV)Gş›ÉY©Œj¦J)ñXa|…MÕ¦jç@ûÜóŠv½	–€?L¦ÛİÓŞı&Mrå°~+lÀÖ	Aìña/©® ·*µÙ­ÚßŞA*wÅíí€İ6Ã+Z×±@>¹mò›YCPíV¢áôå×NoÙ'¼·d—ç%îu‘\¥À(IòõìñÈşlÓ[‹îø:À2Ï¤×(Ê‰§ òÛB©X©XÖ´ZûSoâŠ‚ÂãÊ¹i<­—ä“å\cû©Ó‘xü=‚¥®%	Àó:ùö¼atóÕ¨j¡ëjÍöt¸›â¡"ôÚıä¢b>Uİ`u&W—ëæ¬ú¡ÁÊ…©ÜÎ.ÇLûhƒ0“/å—ÕùÔ)ÁÀ2Âïh²ÄÈ³f£ólµÁE ¾?4Ì›{ßh±œl»ZKtIOt-ÛäI /’"(P–Iï¿Gösœ@UFâ«—U¸4ááw4üà’w±¬³/KÑ—ç™­Fƒn%à0kø$ôm©O  úRC`b!œSÈT»ŞšØ{"º²ìËÜ|3ÿ-^aÈÆĞ®P(‹»‡fL[!‘u„7`#ÏÀŸ¬¡Íu(/ÇLÉdÚ&k›Â
(¸$}gşT´’:lôá½ö<«ùfıUm&ßÿêTşÍ£±ìÊG†ô5lp³-dó<E:±×™¥{Àñ/VˆÌˆYÕï/äôRÈ…B×/†ÿ7!Ñà€/á5ÿ+h¦®AÂpÉ@ üîs4.Ñğ$ 1mPbáœ°eÃ¾›¡¤mAm›¤ƒRšúX‹Bn£ĞË(0iâsú²jAöjêa2ÿë¶¶*NLLJhw‡JvYªàçaœØşˆÂ^/¹şWd€$óòc¡ÎN7?]®ù–?ó×ê<ŞÀÔë×§¤e˜t±ÅçyùİkwgnoKãš*ı¸U†¼M ´foa<YÇNé:É¯¾\5éOß©êa¿¼'²Xø¯ÕòDª°µG¢ÈPâ/:A+æHÑô»¹E‹	ÉÜ? rJ‘æK—JÔMŞ1Ø Hòù2Üc8ÑHßõ;Mx ‹óÉ?"9µA?ìåt·ZEx²ç(´œŸ†RxY1x˜÷4fÀi¶ê€£0Í1=P‹J´êxk­S‚«.m°3ºŞäm$•õŠ†Â¸„^»Ùùh!òÍ×Ñæ£J9ş."Î(¸Ÿ‡õgñÒ>õ[AEÙi³·mL0 ­ß<¹	vâE=ç›4(ÄOĞá1ª>û•¿ó”ğõ,÷*Ylùt(7Pz¨Ù$p£Ó¨ùH‰p)ÄÔï¶Ögúa‹'Ä¢ïP–Sü(ÁkÉ\A)È4Ô°x&İóH[‰õ İ8õÎv"š—VÁo>[\¤ãÌ<SåİÎz¡È óteRÚ°Å2uèyWƒÓ¤¢uu¥)’¡@0Ú‚[~\êÑöŠ'1Œ£ª(-R¢ îe5qÜ%fÆüî@˜0«¥26&WÔ5BIÛ¤¡Ó˜ é‹TÎ¤ØĞÒjê ÀÚ$í<‘™8 97­
t®­1Ø©˜Œ•ûğ ¸FøÛŞq…!¯htc‰2…hízÃòŞ-ÓJÍ'L‚ÿ°¾œ¿b´|±ôàµzO=c_$_î‚ŸA9QEE@T.0Tş0;3öGÔ<Svj†#ÓíócúóB¡“2”8Î™2&ÓìVG¼yÿùğÅˆ<Qb†ÚÀÎ­ÁZ¡‘‡ëˆŠ¨çZsaæË(‹¬–WÒ×¶¶ˆ¯¨_’×±j5êè);›¾û'"‰0t&‡¡Ëı©tiµ6ùwo ­#?UE¨Ã½GéñÈ»ğ/•+oğ…½ ¯©4'Ï"¹çÖyYÖë?l^„ıú²eÓŸï^w]ÏÇjí3›3¤óéøCf*Gkã%+.ãU„ó†ÄMÛ°‚ğCo†ÇµŞÀŸ‚Á›¢Ûx¤Aƒı–t ¢[Ãÿë"¿* ß.Ï¸'Bq[}RÑP
ˆ‡xª¬ßP{ƒ‡Ñ±v›ÓÁæõ±Bé]Æ	«,‘¥&zıaŒ3'»Ra?P9¬…„T0Ê€§10å¬ßé“
&Ôß¯.˜|İ‰ d°±¶Ğ6<,£Ô¶XµvmzºoŞ/]§©#|Ğ§éM½’Ìû²c!ÁøÒhì…o"Ò™î®÷Q¥êk˜cXe'Ş’^0e_%İÕ|ô…<­úÿÏ†Îã
âv½ó¥:¡
şô¿Ûî%e¡ôF?;Ã_øë­G–­+{E=ôR÷û-˜“‚ÏêDµYm³BúÍÙn(Şk®	(\,všHÎç.+!âÔ.1ãç ãHÓ|œ©
gFYÁÌò‹(ÓJ".ĞªBÏú¸ì‚:O½VOéöü½´yì¦ÃSCäC•^C™¾óãîî?«ˆ¡Pß'|§màGXõqiÍíÀœ<ı|ş:”…û0í¤cW¹7‰ë±ÜXì¢Bo¶cMI©÷VìHÍÏqN¢oÑ§Ä(IQ_sâ=¿lÏpå6ñ~mj4Ÿ§F§„÷¦¼)ëN_GéY dÍ`aüN—Š—ò“KÜ9¾¥mš8"èvÃ¯vÉNFŸ[XÀ[~Ù¡{ƒ(…âïëÓèËúEL¼Î=\ê%cEÔ   Ì¸Ú€Áy¥LƒÇ†Ùf¸-·¨º®ÿ®"Y›“îF'«HÍc\û;ô'3j«cõòT¦ŠéqW£§q;€Ï‹í·@®ÍUø^hoNÊ½Yó-‰1¯}=]>¶áDjÏFD³’´ÕçüxÄ_q-Y³úAjªG– ë¡r¢‰1K%!u^‰4‚Ëc³×p*°ü³ıú]Ã¹ÇÖD‰Ê]¿ ›Ü&‰øzLp¡H¤³µ©=oƒ’¹Å%áC&	(Ù¾*:+hè ÅVÃ)ÔóĞßm¹Î;Ë­âÆ±íÍOEÅïäx4a`ÛQS¦ïUS5(› §äN~Y"Iˆ
>v ğ¥@I]%ÎÒ$z¿—­I£(%Ô÷Ü	Z'SÇ§säV@‹†H•‰÷å'”À€-I	"­!ºD¹Ìo¦ƒÉÒ¾vSµÖDAÇaU‹ˆQ60áØQê}^¾ÒûĞ&T‚¥(,KìAÏXµOÈ ²9W¦,q„˜ûhÃW|"*”ÎW®´å¸Öë„ÇDZ±¸ı 3Y¿drH´ÉBøaïq§àŒÕéVŞ,Ÿ ióyG•}í{k
ïcÄrkÁš2˜—ªY22D—8B›[„s…„LÂ7`²&Ùu!×qE™Ó[ğl¶Ä9İ_şÆéDAc5?»Rø˜lÌTŸpˆòçUE7<Şœiİ1æÔêJÒïŒ~aZlZå²	À›Ïi
Å]óiÏ<£µª LŒ'-ÚßÓà= 6ÎÈûN¦™²¬X0:½ø¾Ş­¨MÉØ§ë„“ƒ‚í—„÷ ­Œ;)q•¤-ÌrmB*¡K‹ã·–0ÍÌûšfàdêKê!à€?ãé®†Ktå®¿+öş>§X6pfxÖR}Q‚Î4º·2øKûk„ÃéH!,ÿd›ç^’ò,BU„åM)Ä÷´Şù
C/>@ŒŞ0gú€=òPÔÂÂ@æùØ5ŠŒ*‰ùNE—‡`5Ó—¨ïÆé˜caÕÆ$Z©œTüÈ×TdM«^å¦ôšFÍKÿ*/:È?eã¼~Y¯¦ÛyÉdâÍ–5Ìó$›€¬TÃÔ³ù'÷›u;Àà‹ëó™ïØwi]”_Sn½p0•éº%õ³Ã·¿˜Âr“”Ug,Ş¸S4ßX¡İxƒe§Áööé÷sdıÅ§=’·%qbÖîc;G÷3mkÉ"ÒßÜXåe*?« {<Î–>•Ç%ÜRš”ï$-a4W 5éõ¨C²¹şr?»A­wrÇ’‡Ów/Cv~:÷³Yïì•üÀãvİr/£î¡¶µéš+äÛ§}—D£.¥A8ewöO Sİ`†^ÁYõ"fy#ç­Ñ¢ l~±À¿·- 6Š·‘K3éTŒ  }ÒHÒ°«àK‘R1‡]Ëú«Ä °5@ˆååq ¹fe0ªÕ~w4âàD#Ë:gÕ‹Òjq6ØJ	hŞeèmõSXCå›ˆ^={ÿ{Âí×#ƒÈ@J©~$½wŠå¯Ğl0QOô< hÏ"ƒb[Õî˜ÚhQsÕmÑ·şùawwvî.äFÇà@ &÷/^¯›zª6Úè!¶“èÑûfW@6)Í”y@9›N÷âúîø®%èl"8¦r¼s|’@p ®.C PÑg:¬mpGñ8pÜïÀvl2Ì'‚ıˆ.Ê˜àú¡¬åj)á*îB<@eCe‰”Ï,Ø”±,Ñ¸|Hı)_´$òûµR‚	U?æOŒ4t-læPk€'Eµºh"·uÏe77Šæb¨4a›ÇÛÏQÈ2&4êırëàvØ/ fëš‡=İé}„é6LRÖÃ|Î%9Üê^|ÒÏ(ØT“Åò9’ŸÉ›¾íH„]- (-l9Ä•Ç¾û¨ª´mñÍã#ş³±ŠŞ-y~$Í‰@Í«ŒêÚ ‰d*QÒFò­Û²¨âMFŞÿ(J¢ËºL¡Tğ¡>(Ÿ§ÎıË-¹mÄ qÓ ¡
O>°ïÙı§`n¯ &¢ëæ²u=oÇ!“tcˆ™eë%³æ¸ËèÛÉ©çvŸ¶CŸ
S4 F³_íPá±¦–“¢¿‡Nÿ{¨•c¥ ¢Êk'ìåÑlMX(„4èr“%Š^ZŸ^rŞí’ª—)EJ×›Ü…ék‚A˜~Ø(Hæ€çNº­‡•§{è~ğâGT}p…|f˜IùéËé
š‘‚T.Ã‹qç6p§SŞ¨aCÁ˜ÊFv'ÆŸ”5ÕNCtíÅ¥Ïµ*‰›NIÔŸÚL&oC¤·ósÈ#ø!Äqb,Ó¡Q,óœySlÃû¹ñé$/àävïóÌ¹Ş­5œ2z±¡ÆßjmQn	şé×ş0t®«(‘~Šz£g5‚ápÕçX·˜Ü‰™ÀK•æ³án¤İ)à²W?åDAÁ1g0¡ÃkÒ3f-=V3¢iE‚“¾åÁ™ÁVa³x­¿°M3x‰·¾Ş]w¿š*<@eå+ëÂårÍÚıékvGtêq0é¥—‚IÚ¬AôìØğ¢ˆâ¥~À#£ëXól‚ù•^åÒuêW°Y@òÇœÛÉbá¶EM‡ˆµYµ£Z¬^”ÉÉ—.dôyåF^&JÚmíyĞJÕ´±5âŞlT
ÒR­ë¦™<ÿÙu¦œî†fÂgØ+fÀ%Ê;Qy´Ã×´~x¯V.3k¼wìÍ´6yáB]»
î¸'R·ûœ~ò®9”a>¡ÈEWŞÓïHÎX“=ÉuÛH(ö£ÀùLƒç†›¹¥ØÍ÷]÷N¸v+€E2vØ™ä]ÜïÄ}ë?}/Ç]4eòpğ•úñĞK­C‘]A>"LJ“`ò@ˆÇÇ­oNè5©8„ëW1ğ¹%!-‚:ªÒoÖOÒZÎkG”i5Ç[l¤|)P*ê³È]““b¢+ÎÎÊl@zØ´J,ö4××Ü°D¦Õ÷ŞŸÄµFÁ–U¡Æ±g”=Uw®öå¸—Ç«ÿn7Ş[ºŠZ¸Ñ°¨öüXU-Ä%ë.s?vîï‚	d€ó´·‚ÓIåä¨	
 \–ò9I6»~â¡·—SsåZù‘ÿ’#1[7·&ê¦Şâ
I&é€ı®=ŸÚtP¦çé&©üİşÆI’NS($jûqz€a$š„9 ÿ¤càä‰Šîl™UÁÑÿè.ŞD[=:àêÃ
·š?oã™¦Où@w:ñAæSH›o¨8Ooıafãÿî"XäUa[j!/\{[Çº@íÛáu±Ú ıZyŞX‡‘ÎŸ+9qù!Ékâ‹ÂÚ6İÉàaR>yiİU_Ò%V½®;g‘€ùâ&P¿½<ÄõÃVÄëA~ı7¾éàQaÕ%ÖVÜñĞ!|{Àà*2šG¡,Iˆx¥4ïAµ"¯†‹’òğTİ+E—116²7±k:Ì@‰VŠš­…ºNŒOa¦÷((!;ÄØ¤A°5Òõ¯aìË`5ÑrÉ[Ÿx:6¯ê€ë;„Õ¦Püb-½´`Ó
=Jïˆ1ø¥ø .Š~W»{šÜc&2(2³ä	™‡ïË»êñºf"	|°»/"äå}æõÏ•0£wõn
—l-l¦ƒ/²>víºJõ0ÚbŞ&'¶™Ìc'äÓXÜE@Éíı«ü¾ƒ\TN£@2@´mññşˆÏ%f˜‚9§¸CÂUv€ıK™³M››#dòwCm¬iC-šşİLYN½ß¨¬.LLF°r;œ&Ü…Di’Wû$úJ*è,í;I7q*·ª8^ŸÊ6ş›‹2êÕàgw|ùÛL$„€±ìÕÔx_ÔïePw#„¬Ä–<Š»€{“CÕõ-½G/¢]ã-NT+Ó~ rWİç*{Ö²Q‹ƒj·Z`á· ÜaéÅh:à¸¿²ø¨D€ó@ZÉ¨CÙò(»JöpÍš«WøÃÍ.İXv¦­=p%N"h„®ƒºi	àTÑHcÏ=æÉ1œŞoçÍ"•o<\ ÇMŸîşR‹AÜcfİéÿuıíAŠÄL‹ûyİºé.¹ÈXfkÇßl4¹fùqŠ‡/ï»×~8d7nÏz¥’w¥2İD™Cü7<S[ÇR¼($¦B2Áv­Iêï;p¹3£>)k ßŠïH¾†e‡è²‰ xÿÂ¦_î*IS÷S³Rˆ·7;7­,zv:kÁñ%Ú% ~jçOsuä!Ci¡"g±ºªb8] \I—Æù··G“u!'1q¬B Í·¢O=%½)İ¹`®—V#Cf1b‡«H±”Ğ”RúMª+-G-2Ë·¤†R••œ]4‘‹Â”’f|ÇÔóò%­³Â´A€`n’Z2è±óû­ôÇ¸›ZH7L³Ä0æ×Ù¿îÔ“ş˜ g€¾õAõ€vZ`“Y[ˆ,¯èµx<;+äîªèÿLÆm¸Û˜HQÑtSc¿wL‘KÁ:ª¢¿M÷Y7ó	öB«cÚYÙ#aÂœW+¥s¡FÛáŠ¾>¥¿•3MŸ ß0‡_*°à½xyŠü*Še'Ÿys†ı"Ìƒ§]f“bpÆµ~iıCtˆ;¼ëléŠğæi).½a•"„ø=÷¶9-øRåÆY·ª.–d´ÈF0[·³›ğzËsÎ‘èæåñ©gÊè¿édVªİÔËéÔb	¸¨ßÈH¸˜µd3»jzÀ‚È×³-ll°¼ìŒÔÈj„7»ªR˜òm>gª{X¸ÃÆ,®·;BFnÌ±6‹öÌí& ÃÂC:;›ÖÏgZĞõ3ÉITv¼’['“ãºBÂöØb„¾û¹*Ş!¼p}j¿¬g:v­•9M_yíî…e]­P¨§Ãü?ÄŞúªıã¡°bk¶H]-7á@èµc¡uĞ«öô<€Ø<ï›€ó!„/—PĞ4Ò¾\_ï›¯5´ºe°ü’¤T>T}²ñ°€±¸Dñ­€äˆÀ}²{S‰Š—‰O¡ÎãÆıøë•Víoˆ’õ@+4¼uwàJ1:Ø£A9g©
–ÆMÈ²³¯wBmlû^£	©¤¤š2QïWPœ øj!ãÿáVˆÛâ##{pr±¹Cs«ƒ&f q²Èå2,4Uë¼ÎôE•¿á¾øVºœíı”¹ÊôÊÇÿtŠc?"Ê=§fäœ}WcSÛs€lÏLg™Ñ½½Ü—ŠHjHµxK?!?gE	s²¡ãÀı;ã’caUĞÀ10LAw<‰å'òf{qÈŠşöÄš¹8	pEE–°€•h|Âú÷Ô¸5‚¹SŒ)ï¾Ó6'“mJædàXbÓÛ¿\x(2ÙÛg@ÙN¡)é$øPÿ+ğY4‡ªz´	WÂbø ¹üëƒÀ	74ûWO—¢äåJ-SLmÆ®èBWpy¢Y·í¸¨WáØ±;çÅÇoµâL§s@UôWèÕ—2Ó,(ª²/=I¸&fT0†ïR½a5<py‘ì·öW€î|º."ÈSöÿi{–
³É‘Õ•h¿J¼ÿl¿Íj`×… è1¶Wuuœğ°+tOá¦t·^Îh¨æéì›ú¬NìÖF“ø;1šq¦Ãk0:}9ƒ ôM†a—´6¡x/N. ïYÅÁ;ek¦QíŞJ“ ßVı¢¼,ÏÅx€_îFÜÂ~  p÷ÎOm	ö†X2~€Ó£ ,!ßéá .#¼¤Í	;Ç»Wåò½2şÆãNÔƒWãìöKË	*ÓBãwÖÎ!ÿ…"‡B!@sÄ„$D"ã‡~Ò¢€{BÔŒ#¶ñÉŒsÂ¦óŠ¾èà£¦ Â•·­ÆÔÒ$%î‹G´hºrº;t;	¦w
—ÎBEÅ2»¾ó²ê¹Æ{•`ŞA=ERt¹A·œ-©¹é”¯O)Ö+9çÉ{ßßÓÖ‹>>/ù%.
'ìƒRe~=IÉgÇ<?Ùeºë¿Ù+GKwÃTpØûë‰eAî¨¯é<MNYô´bË+ $İS¿Z\vjË©s/¿ˆ"wÂV$MšÉ³äûÂÎ°2ö%ÿ9No>*ÂŒ´nî­ïš»8LìÅLy(#y„İF‡dª÷NI9 ­.W¹ Ğ\N…ò^ûá¢Ü¯Ş›Ç¸yj‚^oœ¡—®§GÕ&0ŞLE6U!Ñ8«\ƒàö?^Qœÿ‰Ü£ä(”8cŸòk-,	sn8²…ŒÌ)*òíâXj²àŠQŸh_Pv4
³Åµï,*2)på59²{¾u’ üÎB2#zğhˆÚEˆœ Ø2œdú<o»ò"¸ùçcÆsŠÓÉÁeà¾oÊJi‡Í˜Ù€of–$XÄdwI$P­V¤ªpZ¬¬Õ`ÎUF°íò­Ï£“6N‹zqëUö{P×‘ÖŠÔÅ¡ˆ'Kc=|Ä ádC“+¥ØÚÄ<•İú¨ŒÁ²$ÇŞ7SMïr¢š¹¹n[HƒMîßF‘0­1*ëAôë:ÛÍB ÉÙE¤—M«æ4GÁ¯Fğœ»83a\k¡0)'ŞvP4Œ[°E9¹73>ù~Q+ÔX0éÆÆ²7›]2À†D:{&t6¬İï¦¨fÖ
E’tt7®æ‡’ĞZ#‰I¥‚"ŠãÿØÙÉíúæÇ’5ä²‹C
%P@ÈÛi–…DÚŞ¥„¦şá ïÍÙ!Õ]œ¡c$†ÉğÔrª¯iN7~¢´9¬A.fóW¿y‰'!*Hó‰y |ÈØtÄ·B®Oµ…b¬l¬—Àk	`Q9k·Œê’‹‹¼Ï À½ñ,[·'¹‹7”ğ.éàÌF)å)•.#P{õò.¸GØ•T”´
{èà¾²şLÂ¿»0·µ=³¤^©JÈ‘šcÂ†²Œ¨{$
:ƒ^ŸŒ´Í;À€ÖãifI…$Ô=âöæj3áŞ°–é(Ş¸k¦—¾dã¦i~M„êH«mlIBPXyŸ¦Ótğ ¨KªØqmÎFtÔ¸œ@T,Š©BY#ÁnOÜ¾Æ†]ÿ›u°€Æhvl:„àCîWeœ]dW‹kşÎ.C¯OK&®ñF2la<×Jû,à²Ê±Á¤KğÄí¯L5LÃş+!á*4ëöz›€”xîùÇ.é9Tc6³è¿¶{îŒ×Cİó",ß‰\«RZ®Ğb€>ñƒ:'P5PÎ)ms,[CÏ®é–k+<ÌÍ:;zŠ‹ÿÅè?tÃö²ÇÿôŞ³w×8€hİËŠ -ğvb¨ôÚ¯y9¢y­*ñ¯#%ïB:f)‰.¤ˆ:$¬=’µÚ‰’Ï›eğ4š¾Kšz|xëÛ“*Ú2ÓM?ju8ğ4Ä)±cîœ>xrº*¾aP…¶„6o¾Ã”L¿œfYzFß›hyQ]ä®ö]^ğÉëçéêåD…Ú¦|Ö`úÖB)¢¿§&é'Ú+&H¾º# G ‚¦-‰é¤Y¦­ò·ÔÆúFN]Ò¨ÚÅõV÷RÌ±»ÖÆ&4õ7Â¹„ZªYq"êX…`à‹ÑŒ ¥KÓÌî¨ÍU“ŠRÉä*Â½·­¹Ç[7gšrENÛºï^KuİrMƒ|F—$Öé2ÙSÓQ™•.v[1
®É¹bÕ„Ïc»ÉCaw£SÅ+zkz©ŒFò†Æ_û9'4ü^@¢<RáÙŸåjõRüÎïï¡[LoÔİ]†!'8dGqÀ,¢\.§áYo OÒ¦x†¶ş‹ç® û‘^†.ºéï6A´áö½òíÿàlûpyã0œõ?¬ªÒ³mÙ‡çÙŸÖ¥{b¿—/ËŒU,óA‚yo²˜VtˆæÇñOWS’„,ÆÁÛr.eåZ®¦‡Ôe%²Òõ
xOæ±W2ï¡—Ûi…_İæk±'uş’şî©¤ñeu®§E¡ÇÎÆÔ£¼„£ĞıI*ÉkˆİÄ÷‘CÛtŞÓÀ)\’äï­Y‡ĞÌ)ğ“İ‹·¼º!+ŠÆUÌƒêzq(ÌS<3Ûø‰İZ"u›	Kl/•ô-ş”ê|Xc„*	F:0²"ê¿³…Ÿ~êÙbˆÔÂÃ;	ºf<óy‰Üd.ÕhêºFëX¢ğ®oó$Ñ½°ºÑM•ü‰•1“ãgÔÖº»î`\¨<’ÆôU_ÜcdX
Ãà§@„­¬‹5î”VR£CÔlMÀF½Ÿ#=¸Oë¢èK6¤AFì‰økUaêÕ’ğîhp^z]Ã­f8œ˜4m:ê’Ûe\Å5Ù;°Ãôœ¢ğè03âoêÇ\µ¿èÆ§×/j5æPß<Š	nÈ\Íİ»¢’´Äya™¶¼TãyCV§Yé6­øÂ4BK…õ”&y—Ñš"ew‡m]Ö»®µ<ãŠ3™7™ª­P8I
E t¿ow{Ì'KGªË‘û/EéÆ,¨½½&³7èg2‚ sª*áR”%äè ;nvÂX]‡µÄôïî¨*/)R|Åø¬<àØºÛK“Ü°‡}F¦>ŠxHì%RHUØ¯-Ÿ¢»ÅshŸäùPFå(iÀ‰Àì@Ì_*,_×Å40C|Æ5ŞÖŠª?µß´B¯Ä­re¹m•<ˆ}µœ®*ñŒJé3,¯ƒ”Ğ]t°¼Ø¸1¤FÕ43¤%(?>È.â	ƒâH'“×¼™t‚ùiBvF	«%å;1Ã8›òöÁÒY]³ZÅ¢áºW¹ÇDú$‰ Óò?®t(Ä·ÈÑÓ;8ƒ†	…¦31÷ncR­†âÈ)¢W!Š,›3­ÒŠx©s…ed/laÒ_á+jWß–ÏÂáõêÒ³—™‹xajæ–¾ñ6‹ç"ÑJ?®ò C¤7Ó¦¼´6ÅÅõ{’šäìÎ¤Vµ48 FşOÂšfXìßLID·l«¢O"ÀDkåÊ°x/ô”Ÿ¨–ÕkËª€®•´j&KÅÒq&gTsîp¶—X|«ÅKoİW¥¢%œ&SŒc¨[¼Sw‘“4éc…•ít]Ø†5‹cÙŠ×€t“y™İ°¯ófWÜçÉpÖ¦ª©@ÇçæA/4ô"Šã‰äTİˆ>ÕC. Ãı1±.Ş9TER=0B:ò2;ıÅ""*2Œ·'Âö†Šä‹ÍRoBßœ¥
/öK”¡vcHõBy<Ç¤	ß	ŒŸŞó46ó¡º]æ†T“¨Oëa ©òÅáxâÍ‹'Î‘ád©ø*xªV·‚ëFp€xÙÁå¹nq Œ/¡Z¿¾ÿ:Ğİ…ßr˜³èS…©¥­Ãch‹ø[†Uç¥
§ç¥-hÍáÃ…¨HÔ(“èÓKš)¥£Ÿeƒ6Kooe/ÀèìyNÉÔP}¶ÊÉK²eÔs¬ ¿ô‚äA>££!3Ø×&÷©„/i2WMò¦ÔÓŸ Ìå{ÑA>g±Ÿ.İßA-êòÀ	—t|x€–D;) ¢Qâñ~è¨„$É½ÌIòiıû“4çÆ¨ˆ¿]}‘Ç'ç½òV}`y	Î+İP`“wy·_L…Öv¾©oa:ËÄÉØó;ˆ˜ÕÁt=ã}r³ª[ÒnÁ¢M7˜{	3àœá/ö yíåñ¬½vãüºYemóZ>ùS0yt¬JRÛzâ-YÓûM¢ÕXWæG¥©ÔzéÔaFÜß\³¨œ¯Fˆ6‘yJ‰aŠa§:†ô [„ÁF uKÇ¨–Œ›º®‚İeªë¨óú?£4²7sâì¾^3n(³€ÁÌ÷Ú	÷ÁGyü¯u]FcprÏÈ!HZW×Ñ¸şÀÇ(L[© ëÀ€Ów¥ÁÕYv³3Q£×ÿ€L±’Xh©q…WŞƒ)ÏJysÅÆÕ:ÿç™ô0ÀïÂ×$İ»£ˆ9ÇâMyj³™ˆ>Â’0P!I¾|H×±ï¦cúÏâ?ÌÇl®UÉj+Ğ'Co
Õ'ß£@»aÛºG.L¨®LïP¤¯ÇY’!:Ä;¹ˆÁ)—ÏÁ€?<J‡h!‹›®±Ì’‰½aC×W•µJy³;ÇÜy%b¬ë‚Ú£æw".Ÿ¼° 22pñß-E]¥m'&=)-NiuWBE¦R nPeºiË¨Hü¥2Ñ´Ü³jh‹®æ¥•P	ªÜx¯!Ø½©€føš C^ßa9Â/Í©Î™¨}µİC¢ù·½yŸŸŞ‡Èœî44Vå4.‹çÓf]¢./?Œˆ*E0æm3`„yÖ.ÄÇ(h£7ĞÓÊİ=ªõF”Š½T6¾xÅk&.iõælÚdèc`&h°é×pr˜§ÌÂ_Ì¶+A¼]³y%}¹ğ‹ˆtÍ¹œ¡Ä¬£[Qhğúm÷ü6*#hÏ7c¼“7B]Â]q×6!Ò™Ø†Ò
f@­z?B~(—ö2:8w_b­Rvì¥: ¢Iº¤^û›j©gzm×Aå‰°ÕÔ¢ÒÒ “ô¥E“Ôßu¢¨µ”pÎ–$€‡Ï|°¢‹{×NQûáM!t¸ Ë¥²¡w”Í²H—[Ù‚zû(¥å#ôsÇ;Å9$˜Än‰»ÀBC:×ÙeŞğ¥LA‡µûeÏøøï"Û“‡¹,o1òkqÓìêÄÌ}åÜ8N2cÃco÷	²(nÃ‹ãµ¹ö‰À‘0Ş-‹‰V­÷­®È2¯½ópÉË,Ó¹ù¿)YiŒy¾¦~‘iP)à†ùUZLì‰À\…l%áÅÀ›z¹KŠ
[eU©(ä)$½ßÒY2l3v^/İêî£óÎ’FğÀz•<6ğî|Ïx¡tçİõ[ñŸZıú½5æ’ì!Ö+ÇÜaçµ€ÑÏ‘¸Â¾ñŞ/®<TpÌP<0§İŒşéë.½-™ŠG2×ÒAÇæÛÃJ•°	FŞqUü‹T5kÆ,Û±!§Ÿ¦r.ş©ŒDø¸xù‹‚}g ßÁ{UÂ c²”Á°çn„ëà´ƒ1xŒ§#/J)†Şø°¹©è2“¤Øãutfuy ¥ÂcAK1+ûyÍ·ò]Ëçà!UUñÑ{˜ÇĞĞm0j@+€èŠ¦“¡àg~e­#z¯õ]ˆ_Bê÷aìÍKEÜüıâôÍÎ‚øµíµ†ğ
İo»Ğ«ËtY A%R°åi¯ßÄ^1šWY¢ÏµÌw2-Í$D§ê˜Iı+¹kµwJÙÍAï¾Çu³sä†ØkKhÜîEğz…eZvişº^ôÉØ°"L©q']lI—YÈ—%)±„üUŒ:ÍÅ5´öôİsÙÏ<¶Y€Ÿ&~LöÆ#ÓÍ»q »"ĞJÂú˜(±ª–¼á†Ä6œƒHÏís×5oşk’c!Şj€ÄCÍ"jkˆ…Ì®§Tç¬å×Cê¬9ƒ¸*zR^ÚŞü¬ÔbF{] î`¡¤Ã²¢™kSÀ%«úØÏĞ•ÕTÿ¤”ëw…ŸÑŒGé¥ü=/’É†$RÓ©;£ıcÃº/TSsZe…^ÆOXå›~æ¨a)¿—ëÈo,XDêN­ìXZD4äEÄÀì½}¶
w¬EŠÌÓ(™Fa³Ï1'˜iúŞó!»B¨ÙáA(ç"ø»ÍVSé*É»=†aw+ûM)]!«Ó$]l,>t0ñõg#j~Ä¥'©@áøYï¾¡<ˆcmÉ‚Fvn£Ÿ¯›h•—
ö¸U?Kß‘Y1†ğ8³ı m©‰Úó?àá‡ƒßKlxĞĞeaÛ×éÒÍ|h%SàqYÖ»wv;¢bÈ†w	Î€eí"ªuéjàšË0¦°ï.TÅM¡J?&nC’^L¤<#³ZQ SŸw2
ò`&f7©ÇºéÓhR`ÀÕE.9İì·¥¯u*Íi#G“mm Øšx8QwªÊuÊ+†ĞE	™LÄÂ÷9)nâ:d9ûÚZkâj¯ìq:@ãXşcQ´w„È5öu1×­÷	ø(òkA{µöG)¥Nı^ğŸÜÿk¤ødğ¹TÂï¬%"û»/·#Å}Kop¨Iì8R"2ÙÚ>ôŸ?¢ìùÌ‘»€§C¤cü¼/UkXu DH1ì‹ã;Èù’¦¶"† ªÂ?¥TŒª/+ ‚ÊÿÇ>•Y·d§>’èÎÖß“h`ø:âï+á:ÍSå¬÷ËJe`_Gh!M-hZ]ÁÑPD9gw‚)avCçş ]OÇ¬lâq ˆÌa·iÉ~‹Š>ßûDƒûÓ¼Fö—D-~–ÀJKY$‡45<·¬KY§ª9u+J=qÙP„Q©FM»œáÙÂc’¡ş2âš§UÚˆt`/~¯áoz‘I) âÙ"ÓL´\o¾=ºO’§µ)]3öDª®µüÇï{/ä¥R’1m’±TSíXãUGàÕvï½ÆæóA£?ÌSmú¾9ñ5<¡º‹â˜X)»{ô=ÚëØ«|;Â<_¿mF°Y}[ö² QÛ©X¾7¬öF7qª²&˜ÁDÿ¼"õ‚†=LÒÒ'LFÅÑo$ÜŞ}x|½M ñaÓŠEàACf-¾Äœñ‹Ãp]ŸŒ1Ï?y‹q%Dš"+å\Mñ.í®í;Õ	S®ÍŸŸFà|£÷åáğ5r:ó€¶ÇÓê¯B¢âêŞ6`ãÀ{ˆ£îııès¤l’aôY¯FùÆMâøR5FğvšIVf€[
:aı$¯]"ßt³RşR>Ä&üæ“%WCëÙÆt(çt4U>.Èh‘­2ÂLøµ¦ —âÑ¹÷ˆYí×S¯a“œğßR¼ŸU‚7C5HP$3Š”Y®BÜ‹ÿ¨±×)zƒ²±<µjU¥®´{¦ôŸîòf!œÉCƒØBR12Qg“ÿülHP
Ï¬[fßÂl²Wc¸¯FÎ÷Ön)Òúe¥!o*NI”E1³ºQÿ5f¡†Ôóh“Ëv(
@o/ÃÇ›²rT•×Á½(é°p§,ŒÚô³jZÉ:ú“áµNìüè†ÇÜØÅ“–—V÷Š*ı0øáO7>çö“´…fdJ_™v®¾»¼’Ô‘65¸fŒz-;×Êe«3!Ÿ½İÖwªX
pÿû%KüĞùg•·İ³çÕšë1^§e’/n3Ê„ÔAî¥>K|°ö øiŞ®0]*”ğaFh†,m+Û‘¨t9BEÑQeé±wÌ,AÏ+7ûËôÚëi8ĞâCëª•!¸¬ùø¯Ç­Ş¤8ë´n½ŒËqÖGûëv3ı ,®=")…˜}€¨«ÔZÿOa× ¾YƒãWÕ¿¿>“·Îc¶NyõÁø¶ÕÉ6ÃÃ®½ú‚{5ìRŸ(÷K<7."™D2š·)úCZÉ{^ÜaÁ|X•ZÈØ®šŒ#l‚@¸( Áä×í"ëu§ş½:)GÄ„(›‹ŸÁæ¿Ç~›Gü€®bÌ!§ÔU-˜À%´BS‡çoÃ4.aj]8Äº8¯Ú>3FdlùÎ0.é«å­"é4.4|ó¹õåzQÖÉe1×I÷äãø³¯‹£Qïg£?¼„rmKªä„GG["zÍà„zû9‚úèÀjEÂ[–¯µÉ#a!ùÔÂ ©;V~hö¶ŸUîün#œŞše‡¿Ò¹7¨ûËı¸¿²6SŒïÊş±	QFÎı ){èFbñ‹–óe;U²–µÃq€‘nüQx)&Òõˆ²æsHt,ªÖ¹k;óT	Z$úPî3£İÓĞÌ»©RíŞş>&.¬…ZD©ûÖtö ^˜ÚÌ©¨ğ®*JY[Vû’RİY&i)>ñº€æ hì-ŞÆk]/ /	=@¶*ÌQ­<§}ÖïO;[kàJG%dÿÏWÉ¿eÜ}Aº®¯›î’ŠrCaM¬ã> ï1ïbÌ´;¢$p9PŒŒ5Ù.¿>J^èE©¨WOI†`z½}wúUPƒû”¸<UF‡I*¼NêIHj=æ²fZÉïıİqÓ×7ãærjĞ6_%Ùp¡Ÿ}Œ{–´˜ÿßbì¾^!Pá²jÁ52Ó@Äœ[lm«Ï-:©ÃR&œqì¦¤9CÏœ7
zVì xËü@@É0@ê¹ººŠ¼ÿs4Æ9:[%Ü‹7O$—8\â°ìºe‹ ïü~wu~¿ÿÒuï»"¢Ş	A’+¡ğgdÆß‹Vuıiáø(ÁPRaÅÀd|%t„ÌLx*–H¢ğsVS´÷låˆşQ’ÂP¶<"VXÀ ‘uD”\ÈDæU€è\æÌÎŸGg—ı¶y—ñ¤m§fQ–.e:YßoéSó—ß¯_›ÕÂ*=¤èb®ò¼‹×s¨Î?Ò˜ôı…
tÌR6•«ÇIÒpÏr5P˜‘ ğøxlÒíD?D¶TtÚH¥Î’ÉÀ)ƒi;E‰fàĞ¯ËÊÅä,ç¶ËBÊ¸U·Ú3»í£`=nRfhQ–N(ûşp<Ä>®ù½Ö9 .a-#Š	„¦îÉ« øÍWj\®kq1¿uV°Ùİ}èÈp0…/°vÏ½Š/«Õ;¢à”²sÁÜ<çY:ìßb¥?™…¬…bÚ—’çbö‡"m^’…Vßo@ F­#Â–£EĞ~‡.NÇ}Ş©Ì Š¦Ø¿•37P®ùøÑóî,)-ÙGği¿JjÉ ­‹w½'?Ó:ˆæcÅ›è¹E‹³ûõ*K+Ò`iû¹•dŞÔ@CKyåê3åÈvyö<CBÑ·÷"V1õáV	ë#¢ßT˜"Zbà £ãü³LÁŠ¸^¨›Î|Äß´ğÎ{Kz€ï/½öğèw¼©ï8³•Ôlë¦+\ê¬X))sƒµ'’éÀKÁfzNŠüò¥íÕHr±ØÎCfàhÃ* .¾v[ka~M*Wˆ¹jØÖ¾IğÿæˆÆ2è–jÀËùÅaz£áo·/9l>| ÎZÄ)´ó}æÒúßé¢;Ã’UYh£?nbújä@m”ä#gnÂ@¾şìÔõ¯Æ²Kx™
èV~Ã-ğb´Pä¼Şà¹OJ^¥¼Üísr-¤o$ŠÂ=L/8©‡'í÷·ÈBl¬é·±%†³P5ááCI.ùó'+^­ªmrÓÇµJ^†Cì.¦†›¶íB\À>Ş’Û^Àl®6…æûäÆ9AıÑ£x7¯ğßDb®ñrˆÀ˜1&ÀÍ6®À„*³Ş?-KU* ó]#O¾Ép£Ê×¿Av”ª7÷ EÒc¯S[¨:ØF{J2u„ÇUøÀœt´’duj´0]«é¸]“Òv1~Ñ[;eö3úîŸ°§Cí´y›´î1™­Z¹Ğ…ök¸¾õ‹hëHÓrKı’¬&L*¯§/AãËÏM‹j	ßøş{İª”ş!Ä f›É:5ª8\"°eƒª5—¤ëİGÑ°$^µ'¤6ÆÍç&m#Ë—­>z™‹9Y~ø„ŠA öÙŒÒ¯Wm.?{äFğãÀÁ9:çj«‰©Ü.ˆøU<!Ö<©şVN·PÕ.
o,h+} {Óº³S„U™:ø¢Xù¬£“° ¤p?ÔÊ…&\h–Cç°Ò¡ÁŞ’áƒÍikCâ%¿›İwÍ©6¾’mD3b«ôâôÀ0ĞJZ5ÄEm0+ŞM™“Ì¦Šá`Z2«‘t a	vFŠ‹Msà¹kîÌø¦]‘¬-;YÙ@¦eÅSã(ëRJ¢1»ªé?“/P“§ÎÓÈ9X·‡QƒÙ‰¶åBµ£‡MéÏí¬	‚3àT›¬]Æ_G›×ØÃÌ¤¡CÿùøVQ¬êóoÙF¥Ë	@Ôı½X/•6©`f»ÜlVÁw8*uvJù…ÁSºº‘{¹uJ è¦f eº´…çƒf•,ş³hfë¢õqqÑ w&·Ğ®awÈbÈU²±µ›'C-Pö¼Øš'°áúŸ‰cÉ1Í	¦ÿuŒK¶‡fçV6vØ.Æ_qà±Ïï„ Í<€ğ¼+S‹>KY´#áVÎ¿©…/Ğñ·
Îú”!ºlŸŠã~:¯üµ…^(2vÕÄ‹Ö/|w“ÅœüÄğØLš4½óT«u¦VG[ıF¬ƒ–~qkæËµN+#`¬¯Æ/0æŒ£«‚Úk˜K¥%Cƒúıè62‰X)‘RêUDşõç×§ŠÈ„£{Y>¸ÛüWRöåÃñ¨hâ¬»æ½¢(ïµT]²¨‡|<§ˆG_aGl–Es¡^$e¸5Šÿ	Y^EõÎ˜.ÿŞ3‘‹2ØæÙÿ¹Ë¿†?©¹e@Éëè¶±‘EfP®ÎCû6È4¤Ş7¿_ÖšÔVc3pãË²„ƒÊrU”s­jº*QF6Ø(—Û§ïİÏœ6‹¿”Lv.Á!¬ïı&­L»"úyÈ\pïáÂù¼æšq„óó×<ıÌIĞğ¸`İkÄHF-6§£­iå4øR»Eb8Ù‚ıæãb¦2¢:ÁYYÖtú‡ucøİQš-E5?de6Æã!a4$êŸ¢¯ñ»Å"Ã\+;–CûhO6„LÉ…=³ëXD²ó¢VÒ÷å	)Ü¼xƒ]¼àP¦ÈÑ”r†9½¾Ybpûü<MøúmÃÛ×‚$™‰oƒêÀõ=U©èÓ²lÌÜ$.LÃî`Åt‘–“& ÿKÂqÉ@.‹[’KËü×(&(>‡I’ŠİÇq_™¯ƒO)ƒ8ÿğ6hÕí¶ıWê"úoà_¸M%›ŠCóëäøÑ¡êCÑNRÔqIO{M5µËÍÜoÒ÷=ôşjñs’¶+ÁÍYtY[{Ze­£ÇvœÁ¨I»¤õ#Ò I0¼ÉêM6!Ê.õ§Š¬¶u÷ÖØŠG/è$Œ‡mäì»\«boóoäV¶a²@v<´éçëë1Îâø‹Dn9Ü’ğ¶…”¬3À<¥’Ì«Ñaãqê&Ÿ†»Ê‹™"Ğ°¬ßëÍ=)ˆn¨ †Éåùƒ¸ö¯j(*Q(Ş½Ì¸$iKù*Ä eÃ^Ø¡–pDs n÷¹Ì¿l<?&×	r46òWîj%`EAÚ€¾Á)B
öıÁöo%n(ñQĞM©ŠÊ–ì’&~<i¯t¸:5ÊÔ,új¼³N"¦±{äõšşBÈş%×·`X#‰·XúÎ–Œ»ñÊRğoæœîpÁÎ¾w¬ëÙÊ8;Û€Îø6%•A~¥òÿwd;všıKÿdR@İÆÑE§Ü€ìqÈIİØ©„)p… ’üÇ*HÓ­¥Ì| (ƒSJŠk/rTXä±u¼š’—9ê…7 nü³hÓ0-¤¢Âıé)
raŞ„ ¡+ñqm/£™—Ô¶†İ‹5XgèÚ^fWÏ7]²ª…-ªˆÜ«cVò5=ß1éš_¼x/…HáVñÈ°ÑØ]üc¬Tâ©KŠşÙËø	Öà„¨Ì¿eX&Q£ø1í=ÔôY}—úÚkj
gò»“ñÆ*}„e°ôoÑÊú;Zº$½GAõr²èSu‹ûÀ0èİz‘_³aŒıÊ‘¸j€ûüÑeQ¶ÜÂÏëo4ç4d³ !W?kÕ²	Yål?&yG·çÏ…6I¼YÁ~Ô=¼=µƒÓPI•ÁI\u¶¡µƒ~½y½òuL#$Røty:Hú2hooAÏ_¯7åŞëN$×µ™Çi…™çeŸ7/ôF|ĞcVéT®àæıŸ(°7æ3çø7Eáş±ôÄÅhõ>FÓ±\I}Eƒ¸Z“KšlR ×ØœğÎtŒ¥?3$‘Ëw„I&ìßÓ÷Héfà\,¤ØT¬­ã€ÿÀjehÔò§“vß°5Á)míÕù)ÿàÅ€3Bé¯(u<Bö™Ìª—İ4ãe&±Ñf§ŒOõyVz[“ıN4£ @r¬…™šó“cÅ„‰‡u}’UŠB—\IÃ±ïàô1BëåĞ˜â¾ß #d/ò€ipo8µ¼û|ÆÍgšfñ1S´Y8‡ä[İs—İR™r¦'G³~´#VZ/’Ù¬Ñ;kI7‹ˆÔ¿!–!t*?´?ãÉÄ®½y«ìh¨-“[©:±µ™B9÷oFíìÉÒŞpÂğ%\ù
ëàÜÍ¤fTEÎ˜&§°k™ÃPMÅ€ä÷k>$÷õI<x–òxk`F‹Ê_»VöÅã”»8B¿Õğ³ˆÖ€•_êÖ¸  MÒ@ŠéÉwóró±	ÅŠq˜³NwvX6êØxYÁö'¤E?Ñi•åúeÂ„/”L±ØÓØ&Í[—†ÂË ğ†¨§Í÷‰wĞQ ã’Ëˆöä—^ˆ‘¿í'»•¸ĞŞ+{{*,œÅÇı¥á‘¡iR0µctrü‰×^“ìÔk®óùM&÷»‚áC[½{a]%Œq¿p	¯°.:eúc’¢Ôõ.qN˜©snB¶çÄ †ÍÍ_…¤ 
·NÍ!U4ÃHcqC­ä˜&+²ÍÅÏäW~‘ëøƒJØò×å•’– Ø·åL¥Ú.	iWüÕGˆÃ!}FĞÛ„6¦éÄË3L¦¯V°Ø–‘¨*VÙKfõhÕÌ›+¸pğdRmJI.C¡ºqƒ+Ë«ºh¬lƒ˜ó†ˆ7PFTôp¦NñÙTCxÎ!à“‹ş([@*[Í rXfsĞÎJÓ]ş;6Œ*Ak£qO·ÙSˆ´Ö»ÜW‹‡Sy7óÈ8ó“øvªDó<¿\y/ºª¡àü	ea$7‚•Å%  œ˜£€.õkmTj35!ƒÚ]›²‹z0ø@0—Ê•ÀÁ¾²$°ÿd1‰Ş$‰ÜÊøòĞ¹ÌÏ•¿­šIî!Ø/œ(è3š9ÔXg Ü’ÜŠŸ¯z&™":HÙÚ+V³ª«Kj‹$ä_ ¯M}G\/ÒÏf‘J˜)”g‚.æ¶®3-É÷”òfÉµ%«ßåz´+!¯vQïg\/z•¼âØU”Ymƒ…+ŠsäŞ"›ï–³X­| 5gJHs¥	€¸¶Z÷`³*€ŞåŸ[ÏfÉ9šñı,7:»kmœÚwH	€Ğªtæ|(}ûà P¾6¡İ—‘¶Ï‹­<ºƒ~EÑË„º¿	>•ªuuØ¸¨çîˆ‚Ë¼î©ëTzÄ¨Œ«÷­r‹Q¯¨_ï¦{øàÀOã××~ˆÖÂ8ºUVnHfß|7êO7U„5ºW€!A£'s^æG›5ı=òuù1.gOÕvx˜H‘ëÛa„Ú m“ê~+®0dƒÊˆVq#ò³aº9¾Ô	.!ëèŒçYªÄ2ÍBÍøş¬ç06:¬nZü.’Vf ÿÅÖHWô$¶;?‡D‡¶ï<8{’…Ş4Æ“ÄkfyÃïT37RXÿ×QÆD¥lX;/Ù,±ë»&İò6Ó ÒLHÉ‰£­ÒDêFKƒÂ¦-X²y"¿ş*ÿãÂåî¡ñ&ræ¾Û~°68µ|¦S»
ZÙ‘…®¤U¡ïÃ®Â¡ô<”hnVK6ZÕÇ¹A5§€M¡Íœû4eF"ïÕL;ïZ2îX:6Éã¦ÇFö,& ò3@ø'ÄwW4š_‘èFxò%cÆn¼lm6·m »'¹Çß
#”ú=qü(iÔ
d°¥|µbÎbÊ¨ØAƒX!2„[sSAB~‹odd°NGÉ0k6½1.€—O3Ss:Í_mcÄE›/ä½rıÎ¸Fá„<M›°-p"LÁthX£xf¸C°Ú¶Ş¶¾®å£ÜŸş³É¸+B!Õîg s*³‚=J‰_­¥=”™L¿[T­•Ú«ûWüãşÏçÑ¡üü¨Õ°I»6ö"—2CM_ò9°õähÍ®(âcxôr¡'Ï6~¦^ú*îôœ_J…ĞAŒÉ}>#’j8[ö°Ÿpq÷ÒzCÑ«gAşj“<…O¦àiû¢f«ÿ¬:R³ìg[9¢ÏøLY¸U„®ëŞë›Ú2
+³ğ´¶²	ê’¤¢ÇÄ0áÙ¢Q5÷¨{Aª&ËÓİ"Ñ?ªôP}TÓuşË0´<èxc±PR1jIˆÃÌ×|!%Âé Z7U- …Íÿéúæº!u¾;:)½G-\é’]8È°ægm¶¹´6IYò%¸ªœG°Ào)íÈiÿ5wã5ë fY)†«/Cğ,ë£IµAŸîıÕ8ù­SõÃkª½gb>7W=¾¹‚êé¨ãxÄì/º¾J}á¯Œ!t«"Eã•ÕS¯ñá³9]…Dñ¡üŠ ñÉóxF²P"@w¬O¼Y˜:Æ £B„ıd5Ïƒ`ıéëä’¢àÄ×İ!äDòİÆcğúcµÀ"Ê%Ü³åéIm™Qz\¯5µƒ3ìk2!ªQağG€ªßü;İ.“8y¦uT¥D½C­£™İò;Z·:}…DÀİ´d’_ô•ğÇVÍÂS!#¼v£ŞOÏ¡pˆW§6p7°Œô‹NOÖÓlfH1mym2æÁBİyáÌ¼Y9çŠÌ†ÏØÈèl%FnúÊ "r"EW ÆöQÿègH:„BØï !([T¥‡ÙG¬’(Ñ©oæ[ºÅQ%%ˆîNT?ötrÂŞ 2ÿSÖ½9ÀnºéQËDuv;‘jRã³z« ÁÉ»“GÉ»|’€•yÂxrç0B©:.1Q!È¨¯Oµyüp+¼TÔéJÃæQbÄ½DË\'&.Pƒ-À'ß…íÒ„—)^?3ƒ':¸xFšl.ypFâ)GlÂäjŸNĞ8À(Ú‚d´C¢©‡î®kİ¢ß‡‘×pÏv ,5êö›ğÑĞc8áŒkqBŒ…“²X³5MJ¾Ôètá*CáîÔ®Ï
0ÜZpòz>=;ü˜‘eÄİTÀ“âiÉ!™^Å‚¡€XE>,A««–L.ìÕ	šŞÑ·“êe%ıˆŸçïÁ Ãñ0SdíuÛ=à¦M;YÛşV g+2‰°Njûâ2ŸKºÓZzmVÕ©´ ¼w­°ëg"¨^|rğÅyÏAûµ»£LSê°_½Ë°úWU‰MLÚOd•6êİƒ!9:T2Â}¿êªQÆ‰~méõOºÜ@©Ş&uå­Û#¾&å«µZOR«êH½ÓºPÏB‹±±Qò+I5Â\Ù>— CO ÚÒ`CŠñ¤'5<ŠŞè~ÖJÏ¦N“V"$lÿqçë¼ı“¥h¶?x°µ¢ú§Ô”Å8÷ƒ§Bz[7£Â9mf"àÿÙ‘ÅGmQ iWí¦Äš{Kbpç¤#~? »Àüï˜n½İ¿áâº3‹"6£õ[}Û“Î½g)å½ë­'dÓ/	¿é¿hH-Ò:Àˆÿä 9]vƒ®ÕÈ5ŸcxlÏ³”kag(®j¡Óˆ)22ÑG6'èNÊã–úHÕÀĞ0*[»Äc‡ßu"èŸ	Ê	Û‹Š“Zo]T,¿+/…Kiu/MájC)×<f¥%ƒ¸¿º—q4ßZ»ıC.…LõØÅ8¹ª?àİ Ç„lv»)ìègöÑJ¤±üÇS½¯…Ï­hÊ^©mËpzi|mÎwúÒCztñ¢œ«|Ù¢$ŞÛœõW÷hÇï›fiöÏrÑñÂd3„÷Àº:ÂğâòMQ{æ)•^ÊüÈ#mÛ7äZì!‘ˆbKEp#H¹‹ÏŞ_­v?)+j_¨/4&ÔûQÙ¬«é»ğÒ{ÃÒ4vŒ¸ÚhóoÎ{ŸE*¤B.Š€ÖG5 
¤dÅ–j¯GÏ€Ë«!‰ÓFàğU¡O6›ÅNÌ"uêüÖœÜeYryı’!‚ü8P¯s…êË8ëßbïiª±Ğ©¹›‹ßU%. %G³"¡@€f‘uf£=ë„Eì(Ÿc®|7Ğ¥[ã¾…`åé–OìBI#§O.ÂV÷ºqv³•7‡±>!Úoô*j“
¨™ãòˆ!"Ôø†t‡» Øõ¯Œ‰P1®0+¼42­Äí]´vDWêmüÀ×Cú®×-ÓYÛóÍ ˜'¹Á£şoMóİp¼ƒ½EB¶G-xÃÃ\JPÃô9å3‹¡üáÌÈÌmK3´*%>‹;Ì¯DĞ \ ¶¶‰Í_Ë6é¼¼JékGA0Æó“LT©+±tşÆ8¬Âg©àÇnâ%T#Ìj±ë¼@Õ|™Ãus@5çòIÿcMùÏ´“Š°6ö'ê©‘ªÒ‹û:ÇqÓ=‚ìœ-Æ©^‚OãDÑóßİ–È@rH¹­<7ãbe4gò5š{¿ÌR!¢0˜ôYgvó‹Ëæ—Í(k½yBs™Ü‘°W[2%!a*'œêİ…Î~è
N¢#'@ G	§ò?æèı)ÕÄòà(›Æ,¢×–fvØv„WxŸ4ËÕ–ê2üŠ+¬çÙº¨nÇ{æÛ’MO`…øÖ†\ÌtŸ‘¦¨âVó<%šöîà#†)$kÀAîòÆş—tÑãÆa$Y^ZBæİxKµEœ‹=»nQ½lÆJƒQ ÚéÌ,&º1½d8Yï¡[^§§;E?C#‘¦Ëe·"2(ƒ÷Œr-üø„L €@A‡Çıv%+Ğfªèì°1›‘ÏÍê4Jµ]’µC³t<d+®›Ö4[º†Pu#«Şp®yªwÒ74(…g¬nó{ù\.lÀ]ˆ5ÚöÉæhvô1+à–kÕ+€=}ã¶È«jß›}Q’:w6I™Ú˜_B}ø[Ä´1j)÷‚~ø9Ä+TK»aÃªjW¸U‘Åü5IÏ^Ée¶A³]uRjÃŠï÷ ÓÆç
ÖÓ†ÑÂ0Ÿå48¼•üëÓ°ï)êÏ¸&›=†ßÈ`­ÃI]~‡²GğŠÔğJöR–¢:­Î“¡â!Úû­å5™#ÈÜ<üfÿ öÑmnÆü‘mJx}EëB$âô!”6tnTLbÔp©»’òœ¨édB€}&â˜ĞhPŞ)¦Fÿ|ü ^’¶[¨dıJ3ƒ©{>’€„§kt~şÿ,/«£ó]B™æ$ÓMŠ“p9ì F "Êá¢i‰±•¼ÄzÉÀ)üÄDç|øgKñI_Äê©êê|Bü‰­jĞF$¸lg3ë2<NÔ•CÖn_&‡àJW3È¥U’€UŠQ¨9ÄÚÿÈŸ‡P$˜àáR$ƒ°;SŞXy4rØÂìø ƒi2>c/h~!^ƒß?¤bÕ¥b´ôrĞ
³ìÛO½ŠÈÖˆ¦„¨×ãú£eõmê7ñG]BÎßŞ<¨ğ$Ø i]@4™ÁbïïƒúÀf‡©ûÂÉì¼›d‹xçcá_	ã"_›â?$<5pĞÎïO|Ü U¸·³¸Ë&ğª$ìÂD'U•şìIæ¯~ĞûÏ‡şF9^ò
­+OnÌ|Ò8s±>´’ LŠLLhÂØ‡;¢ÊÆ7cVngeäøÙ¸0hgìÑéxW<ÛÉİÕ>ìùO§OCí§S`úºÌ3ÿUøuË¬Ö@\ÍD¢NèÅeªãP¾j¡Ü\Ë¶Ùv G­”ª¤_è¶Ù”°k4æ­€#›l¯]v6\şH,S) tû1
ÊÃœæÍÿÃ<§×[ıIH""CÖV6Î)ËPtõ6c9Wñ‘† }¥—b<VSÁhÎÓ„‰›–,$x«Y–;ã
L~Ì
¡œ—t£"y}—7g¨rdƒX‚¦w¼ÜÓÌö®„±ßQù˜EË‹òb@¿Pc¦0Î³i]T3¿æİm{éÛ§Ÿ0¤u¼»ğ³ÿşK‘ı”.|•T Wö:ÒJê]…{Ê­!|aÛİF"¶]`“ø¼XÌşTPÜB€ùS™Ú N6UXå-]ÛC'GË¢¤Ÿ,«I¿­¤ÿCQÓ 6ÃÌìÜÿ‰œìÒÅÓØKÕÂ/-i—và$_P¨L½
¬Ç”WsZ‡ ½]Oå1/¡ÉâØ‡í(WüÔ2-ÒóÈÀŒ’eùx¿=wÅW4‹ÈWB%d§-ÓÓáÁéñL‹a”%‚¤İ"uD:‚Aè*6{t{ aØW_AÌrv}Œ3RrÒK˜Ø–ŒkÄ&ß¶Hwç™Sh(ToZ9æ£ôğá7ÖNº|ã.P†CåÅeá¨©¤eK ö=í<BõUêO¡\Št°PÀ4ê´	9[ß¥‰¥{ğ®:¤ŸÆÍ¸jz$¸sÃÁàÃƒ§Ï·GJŒjHç±µ²I;(O¬}×òØ„=[öL%M]æ‚J¨{>­¸ıİ|Â;¸˜Áœ
Aªp¶(¶w9;óÆ7omuì¨wˆŒ­Fl˜¸ø©¿Zİóg(€g£«Ø(-sÚ1Ğ~|å^8üM+Ñ‘c­Î¦(­ÿK÷ÛºÜö.tPİ.ïa)¿²Æş–Ôªôïí…3$~k®¼Á(‚q´¯gÌ XÈÎôü#.Ø‘ŒkY‚½…~oüV¾|5ÆÂ~å]~ÔŸškjÿÖe£‚7…
´Ä˜]âş¶ºÖ:ÑDex‘¡Àôêö¯ljÒŠ»‹/ Di,‚?ìuËÀ(?ñU^øS¿÷O¶|CôLaİöıÚÍÛà÷‡ÿ9˜LtıXÑrëı¦‘«ã…PT!iuŒ*f®Cé.—ûÛ‹^t3°qK²à=¥^±1s6%*4U··DÍ²Âä(¯Dïh}€ñõY>í{¼I·ßƒ"Ş²‡F[Ã.:©U!XH¸ÕÊŠáÎd[ñ[án4¢½ Ï@-ø²
‹”N>®­“¢óÑø{pŠéº)ô1Ë¢¾è­3ÒóFóI¿fÌËÊ=ä?Àö›¢¤O÷[æ#Ï¯Z“ò–æ"Ìä}ÕşoÆhQw«9Ù™©=xk}ƒX¸³°,)6„¶(ibdNÈ[U	¦€â4Ñ‰¤<ğü»8$(áIïóh 	l4Påsë;ŸvêZä\H½ˆr:(AEŞM¯ÀŒ«yônXìÇ¼Uñ
ÆŠ-ŠšB•O–t öÏx8Ú2€Å±9±²cê“úµ5¯Æ¨X—Ÿ÷¼vê[Í‰y3«ÕdĞ¾@¨ ÈI6½éÉ8Ş”ª-wû0úİnäq5yŒ]n2q“egh~› W¤íÿºpf‚íÀ»V¢{ônAäŒZ×é¼-;;Kû†`W?Ô.ØÁÂ%–
B'xü™/Ì–ô€<û¶A^eºAØ¸¼RÍ\IkÕ#.ÆLNÔµÄÿª±Şâ¾	ìÿVí	Ì®cè[xŒé˜dr( ñÓ¡œœ|€/õXÆéùï%K_™—95›G¥`F‹\ş ¦Ó9aÛPm)©Ù7 t›ö£s}M¢<¿œ~J§Ft9üNÕÛ“Hg >¬ÄñTÅÙƒ,}œó¯Ê}·] gÅ>¯;öG­ÏPÄìÇßÂûçëõÎì|Ó¼˜ò°D_‹œ%4=(ºš©ç`³6 œ™€Ú~¯*íë@>ÁBÓ“ÈÙÁû6ôŒÂo5‹ì•Zd`uâ6';A–ó¼¦ØÑ.İ½XÚšõ%wKˆC‚…‹cî)Õúp£ÀRÈ’X±ÊÕ=u˜°¾­dNí¿‰Ï_Œñ\ZÀj«Ûğ¹Â™›-‹Š$íïÚ	})Íˆa=‡Ÿ>©Õ^işï‰h­ıkœ«ŠİZQË[|Æö+Ï}G¡ˆô.¯Û–M1Ş™"w¼ûaé”ù”Ôá¢!ö4Ú7k¯,Rèz=Â¾¶ø†İ!gmB³1Ôx uğÉØ’|»}},V€+¤‹WNOÆ¸ò›G¿eØè·$¢ëÆ.oÕ<EÂ™\ÏáşôacBpF°Hæ‚ÉgmÙƒ…õÜ…İË%üÀï î¯¸3”¯º Ø¿¾C²P‡—Å¨×Æ'ú'Ù‰»á/·IÀ¾Ím\	£ZÂÄ¯Aù€h«0çù|ÕU#CÂdƒ&È/K –êÄÌ=w‘Êãá,ÀŒ£v¿}ç,êªá9¬—˜‘“’úøkÔû³¤TòA-ÕÙMB1-LÒLT0n}¤±¤ÏèØCrzTW¶VÖI†Íj<À}pzD„;æi¬û–
L‡da(‡¦ø’¿Ñe$%ÍÀ–Ì_FÔ~úñÕDúÃOëEóT­•’âVÆ>wÏıŞtğ²¶a:ba6µîñ9óOz‡>µÙ©÷€xI°Ÿ	ºè…C·à1¬Š$[ Á¨Yí[ÜR¬­0Ã'ƒ[›ğz‰PBÖ^',K ·â®•ùëwázY[ÍÊ#‘e¢äiµ‰3Z€Ú®ùÀ‡vIÈ£ÛPFù5j­Ú”£Ü)«İ0@øÁJ*ãjttmO*,M©»KK$*[*EøäLİká<YN±éIĞGå%SÍhïğß=±”Âb8‰;5TàZahNè¨P«½¶éĞ1zWVm§¨Š%,t9Gõ|¦Ä¿N)Ë›
gœX›fğ¨yÏ…Z¾Ï†Z¾Ú3ªñ\8)EÁMşëå-áp¹’#$Å&½²]Ø’u!àÑ¹}ªsğdœFª|³¥f§Y»9•æ)´üQ¡òÁM „pÄ×KÁè	5èaE×UMe®^W8~©mó®ŞF~YOÍ¬Ø´öçXGƒ4‹ñc×L‡İ_·M3°³p¸WƒQ­Jñ’un:] õZ:ÑEQ cóa¨—gvİÏò(ÙFuHZ×°ë)õvyÄ’Û·˜æø¹É•¡­iºíOÜ¸ØÓë?Jc©ãş—EÃ¾Bè[>Á$n,jç‘ò%¨u!;úXß®úRuµ¥Le€ş‰i½›üùÚ¿œ&0-¼¼)Z°ÎJ¿“Y ›Q!^^†Mä•L‡Aª%êdûe§bLB"¾oöğÌ¯/š‹ÕHê¿9/	L™8Ï£8åóıO/™«yÎCg{jU±meKôúEÊ|oœ”ZYÃÃCˆÿ¥9|MX§ÊN€g×a“¥µ+¸›?²ÙÈé!ÀNŸlkVo^¤Æ£íf¾mŞ¦äfO ®Éª…µ&¢­´k.Ê´!R9IOã»F£îÑ¨ 5W0rÔÄÉä±æéâıàaVÈe»ªºÈìzdSYqş¢‡&N ›ŒÅ8UjÇÂÕk8hñ:fä†LõüÚÙF_ç`$ã½š.©ô´ñ,ÎèGN9İY€4¶GWšF|i+7–˜3§µìrBŞ€g†ú˜\ÖIŠêí¨®¥Õ*Ù‡'®üÚZâĞcOtxÄÅÖ™,¦[Åêı µª\ôÃ°‡Ä¯'XöÃØïô?ÉA°@÷£Ş’ø¢˜î»¹M!`‰¸Õàë4’—³cWYk[­ZÔZ$£8ËĞó!ê¤Ÿ25Í†î2ÑrP”3ßvµ't2\‰“€|àP` ëv¢ä§RD’m\ÒâDéjşô}LU éz;²ËWë Y¼uÃ›õôŞõtJÖP±¨•é .Z ¥¼÷Ë0úä‹fZ^#SAßIâÙ¼XØNÖ‹v,_òé!W ½ÀeP÷F*ÒVi‚¡¢Wbv¡TÉ©5ÏÎ{!3J{?’Ğ‡Ézõ n	C¹¥á}½|8ªŒ)R}G'f>%ŠÅS†š=ÙÊ.q–nŸî·# °2¢;K)Ğ«©ì; şw·bu«Û6É¥˜ï[¨î3˜¢dµÁÁ7g
eb–ü,İ#ÑƒÒ)0lıä'xÔ#.«Ä_J¤–H)¹ÀTuîÒ¬  ‘›šYæÊà• ÓÉ€;Né•±Ägû    YZ