#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3727652176"
MD5="87a091a89b2c8761affc4597162df47d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="25800"
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
	echo Date of packaging: Sat Jan 22 02:36:10 -03 2022
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
ı7zXZ  æÖ´F !   ÏXÌâÿd†] ¼}•À1Dd]‡Á›PætİFĞ6õ.L<)MD®¼ëâ/oÎ­RõËljËÂÎ+@™¤áÉV—NıO»¼EÍ¦¾']25•E"‘{Ò:Fû¼mâtÇI\O œú3=eL¬n°ñi%šßA³·^òÌ-ºÉê«:Õ®^ùÃ	ÄÇf÷Jï|/¨˜…½p«v˜—zõMÍï¼Î«Ó*[Ì&Ñê*&§¬]‰–=Cóõ_üÇÀÅøNåo­ì‡/=!wL]ı–Ó>ıîN%†Õ(Úuiè³ño¬N‡”ÛÅJÉ	äïÕ²nÛ•3jÁ¢%q‡oË»[§%÷¾‡~»”º+£şp_ßYı2¥1$Èï`-g¥Â?æf.ºÂBx?ı‘•]ŞàğŸ)×ÕİÏğ›QÍ²ËğÑ}Ì±—Öé3Ìá/ö UXûÌÖ¤*D¸ëÙÓ²$¯ÄØ'8@šëIÃ~×w‹xç€€Y¤Kß%ª‰ş-0 *%İ©o<!É‹&/‰ü•z¤ë
ş¸bˆªÁùéŠdlkçšğğ¥´½Æ:Ã­ë¥I÷)ç"Ô¤ëË…ÔÆ“÷ÈşMÛWîQãÇ#’¹§8«RÄş6Şd¶ÌAæ¦Šl×)cö›¶KåúæDch÷ÛÙIbr‚”aî›aÁÜß ú0Ê¤‚ÖU#ƒLCÌó·eÀh¯{ÍØv¿i-óUÿÃáXœL%Ï…ÊèıÛD–Íé†•\. bÑßs¿"ÑK:ÓjúúâßÒcè]C9`Š$±î:ìD}Ÿ,x;¦‡¶×.7¦ä/>âMœºÚ»ï?¢ÛJ¢f&u£ÔIÁI%©†G¾`Æ\•€k&tŒüw²·Û”!@ûuP0ø‚qÏ¦¸İ#UteØW+°ş–:gò®D¸r_(x+cy!ÿ¨ CzØw”ñ"°e>S£.¸5ÿ![V7Æ®/ÅsepGık’yMŞú‡	«Z¶çÈÛNg7}}éŞ;l»‚(„u:7L¸!4¸6¡gìÁğ¦Á>Îç¤Ğó°‰ƒEŸQêdäÖj şÆÛ›˜jİ&(AKŞ÷Îö4bÑv)z±äóÙ"Œâ£øÃ
ëíI;"Ø¢	œ7Â‚:Õ·Oóş6pº	ø5|ÏÈü$ş9
t Un€p nUÜ8èæˆI}­öÀoÿ:K³±Ÿü'‘,Wø<N–––V/W)§wÙ÷ÕşË˜Xí»f£ƒRL¡Àˆp–ƒiêf‹ÉÔH)q/º[yÃ¥Ögi¹P50d
pÚ“D»ÁŒëwWNçæÄ—IŠ5Ø¦Ë÷ëÉè£`'´×e]•ƒA†ªq†'G<
5™wÁÃ€SY;ŞÂb¸ø#%<„Ø#âÄVr{–Kçìp±EÖÚ2¶?Tõ$>5kÎj{ÈÇ¼Z%÷ù>íşÛ¿µ¥~Ã¦oÕH÷Ãà¶Ê6§9–×¼'[ymœYêÃà†ùpi&²9y)6pÂÊÎ†zYy½5TXÍ(ßu°Ñ¤I`œH°!Zëm,Î@J9†Í¦ãÚ¤&ÙC©uC(nRR³ÎüÀ¢[êkÜş©p•ßo9E‘:++jú‹eœÕ?IªÒEt>›äÌrÚ'}:?f“¬NÚ‰B[·»qÓYºÉ
İÜaû§G¯¼8ö„'gºãÖ+'DˆıÏæÇ›å7á5%nKš"¾¯è=!º©9h·ÍS˜ßbSôìïtÜgy€ÄÊ×J¦¨)«5³•£MŸ§Ù°”åó±…¾Ÿ#€AÈ÷µ ó|Ã¼ŸN¶Ã˜ùÿØİÒãàk×ûv¸*
¿7<•©z±‡É.p@&¸•”³=!>¿OEÙ_:T¯ b÷İhÚ$ıYõ+åHV&œ®Gô€–úD¼P€ãOP4Íx~º‚4¾bU”S?ÉŒõvé„´‡”[’‘gMË †’J!Äx½ààÑg\ÉÂÂö¿VIÕG51ëÔ×ÊT‚à"Á«e¤HRÑˆ½C&÷5¨§6ú¼…¯kÓ:?ZúÀáèLğë»n…öb!QG/õê±ŒÙÀFùhgßª—áµ ‰Ğ/š ¬7-¹2Ám#'§HJôU¸î¤ü†?mÇˆ¾ç?Ì)ùMø¬ŸY[×KşV,;éWæy6Ä»%—òVà¦ú…5‘zc;[Åác»JB-jæ”¶2#d1/X»Ù:•âK\Ê|vc‘UP÷Ç3#¦äâ=ºë•…SÉÌÛß‘$ôü™Æéï İ]=3£·o­ü@şÚã9ñ'XHÇÔSK¬® õİBù/˜Ær.Ÿåvğç•z›+>÷µêÈïõä¶û<Ã*¨‘kÏ5·ìÌ‡Âê¿4cò²şŒøÎÛºK¼¾¹+¶wA
9Ú“K&§ŸH¥b“»Å"æÔ‹HÎn5‹sÂX`Åó^¿<)¤z8ßQk™íŸÀ@G—ÍrÎ1Å¦·DQ9ŸÂ^¦C%sHhü„É¥Ïò»wëvyÌŒá¨[³}%ÕÅ¹?E©ŒFmºYÍu>S“a<®-Ií­ù×î‡¨®U	H/Ø]Ã’Í'âsµd£… 	ãsË·eLÏDw"¾FïO«Ú¯ù´äŠeèYm'ƒ­äµÖøÍ“´ŠõÁ·>{Ûu@_7%vi‡Âê×“Šï¬ß?©½Ä2/»½M,¿§%±Â‹dî¦lqŒC®U‘š>9™Pó,á­”½Yìcp2Ÿ=c–ôı†#j"X(_ÂôôZùš}u\ YúB |ÿhRİV!8~8CJü"^˜“DoÑçä¶2AµãÚœİãƒÈz/jèd®Tø·À k!Y7•UßT
h6_›WïşvŒ!j+EÄÛ—¥1 !ÄSšeâÚ»|6`qrßã‹fvûP«˜íÌ6àÕ6 Ô‰“Úôû4SFòÚ*»n€È[iİ>SÑ¶Jè™í9p¼M•àø<]äßsë9xáèØXw|ûoÍL4eá—ê>˜6œô’½RÉjV	dõñ©"®H"×óÖ
<¿'èX(½«k\ü£¸…ÔÕÀï¹:R’½«o™üc®>ìhâêĞD%`€Ô4HOJ¦„ïW±”Péå~%„øòH~íõŞò½\T1·¥¼0Ã˜€à1kÂı‚a	“D¥šÜhXiñ¿…Öà^EĞ¢Â/5y*®h[oœºÿ§Ä'	¨Şü£+EØ1«ÆâLcÙÛP¡ÆowüN§î¶!šy1Èçî>¹ÙyĞN”ùƒ‡_Vıè7U}gå¼¬İçËúÙüŠ;&‰¤Êû³>³‹QëĞı}FØ«W"ÚàlŠ[ ú‰}8éoÃª°Æ^^Ù­eúb ¸z«íoA]¡…ûîo¼<7¸ô²•ùb=tÇ(3	ÄˆôuQÛô¹³¼‹ÍÓ¶4Î}BÇ¿ÿ~šXş•šsC_U<í%ëf
³iÓæUíè.éKGùğ›ÿáXxsjªÔ«>Ô?(ìòU!ôNq¬ikÏ‘n+An+|4§ÕIGgÆxİ¿XoıKün´'Ëáƒ§ÓÇï‡™ªÀ¬û	HsŞßSpô¥uÁl#á‰3¤Y^´C3¤<Ö;xËMï}+s7¬Óï¶ş‹›tœï*iSš{­Êw7?ì4Ÿ8ï÷ñ§ÖĞ]:ÁÆy¯÷È’õp¿œ‹h¸€goŸ_şêîZJüœÙ•‰¹GÜ ÜŸA5¼¤±>&‹3ó~ıqŒ¿íéÜÀ®>X÷Wq¯("œ€UlıSQuĞ†4ÙÕ"µ_äı)+lo s9çM“$ãamcñ˜¹üë§T…}Šå˜Z¢|rüûké¤¡=“L·l>j5ÉFâÄ–îªÎ¦hJš)Ñ?Òß8Ğµc÷c	_v•ïAîòD²4%×dŠñ¨ ©zÑõ(Ï#ÙV–yÀûâ©Çi%8<2¶Ylã#MÒ9g›7g¯bp¶¨`‹õb÷åKÏf¤Œ…("XûÂó¼lIg'„{° J½~.ÃÓ]®‚?^K4Znõ Èzïçç$€ø+íøèvã´÷D®(ÁJ`$öjÙÁô»9ÀUM<nPçqåéâ[mDSêÎ_¯1õ²‰®K&0ëÁˆğˆA;5§a:5~2ş9‰ĞcÅšÏÎ=Ï¡ìÔB:S~†s/dÊ»äÄXÃÇnZÿ´x(èGÎ=Ï
,SÓ`¢²åÄ\”uã"øq]–áPá¬.Ó¿[?ïx™J—Y÷èÆgÁ6AƒJ„À¢`\IRíh1í_÷©İI:^:Q	yUÉ‘%@€‡¼ZÏÙ^®›Z!À‘ea¬h]¦¢§¯r&õ…-îğ1òµæ	 ·•Ìş©œ\Ë9<œr:Y /«1r±z0hDÃ«°¡Hé'âú¡»õ§(cÎ)h0àÌ ú|IOş—T´Ø\ó‘¥Î$æœ}@#.R û½Æ¯òlE&.KLeºò©ÇAã°vãFî–é¾ oµ=”‚ŒæO^QìnÒ˜v‰voƒ·F6ãœ©~¥–mĞmŸ^§ö0·Kf5*&ÇÇ/nPŞZ&æKõ’¥yHÙÃ²P£Ç‰¼ƒŞîG‘±u ht¨:´ø~râ)îr;5ÄF¯C$Œm#OB@£ˆë7áXò´–%yqˆ’]‹V,ÖjæİÌƒ[-Š1‡qÎôÚ[ƒ”ÎYÔ”=°X;jÁ©ö0.w#„À°~CÚ€[¼"tı˜K×1iÄõzzğÑÂ:zÍ rt÷ûp­93™,!›ª“¹'q+”ˆ.PwíQy5Ø°ŞbjÌÖ:™;9îNà¿yç —ÛAVÃ•ÅhR'¹ê´‘ä –†é!Ê-Üs:¥ÜcóÍ¸º¬ùÄÎÑªÎôw­ä¥ÏQqÎä\ÌpâÍa^ŠK[ßÜ	×Üó×<  Ê«Ùøã©7x ıutfÜAA3æ(öá›¿YÖSş+“n]Vp±@µı†A‹üÉK}•ğg¼ZÜ˜V,¢”±¶@8Gğ+S¡õLû¹=ºw”µÏ–ó»úø DÕt_
{«|f¤<ƒŸ¯½ıGÙ@ :2ç TîfèV8Æš±^÷––é†Ùı2›Ïb[!^ò-3üÊÁ”ğôUÚ­ÿ!şÿi\c‰!:ãcfrıNåójb±Óï¡Êô‘©ÆkÛîVĞ,J9Óƒ–Ë?`´Eì´€bPn¸=™d½m^Ù	OœõŞ£ä4…mp(a^_3moAíÄß)XÜAr'êç(â+R;tÛ~«©¢—Õµ­xãÜ×Öå”œw½²	[6¤Q­Â"µİeLvQ1¿ó2aÔÈxQŠ•„¢ M9 @Mçç×Döw°±Îc¤o91N÷¬ÈŞ©—i¨æRædpn1ã•ÇĞmW­QÔ&nÔ™Q‹c$‹b·kdîd¹ºÒ4Ç†\«Tà™Äƒ“‚»¶MfY.à‚>Ë`ğo£l2ù×Ä>¡ŒèË=Q„Ëú˜J¤w®tÏ¹ˆòô"]M°€Àélz»T+Û¦îøˆàf£
sğÇÙ?^6A&Î¨Téè(vÈt÷H-‚z¿SWƒ uiç1şæËÑ bLµİùtfà™}¬2>ˆJ‹[ÅÆ§Öôi¬k;^O™ŠÍFÆ°ÃX÷×úúÈ=«N®—f|º[kOg£ÇrÅæúæ(8‘*º¾ûÌÏ!]U¢òó¨œùwõKQ>(•ÉùÃÓZT¥M“ª„îD#ÆXl´{`Ïƒlœ]¦³Ğ-®\ãcõ[]eU;"™š+€'šq%gR»i«pˆÿ¤(î]æ'ØŠè&à(Z'®€‹s%>µVw}©Ø[S°‘šE°I:¬¼2¬ğğÜÛ’\<qLç0Ûègi«ùÿ÷Y”kÇ\v—ºêİOWÒ~"eí¾“yüø/šú…ÇgL_C~>YaB„3n–šÏÌ*Áw¤ÑÁÂF¶^æñÕºÚ$¤‡&±E4"6¼tònÍr¢¨ãc´çéÖ'G¬òN~Ñœ~\U/öÃÄ}ZHÖ±ën™…pê/İ<Ğëh8]\ÂöFóÄÊÇ@8ôa_Ç2ß;¤ó}§\~^ ŒÛ—ò'ñ±Kz¶ğÀqxŸvMNz€×Í+ôîÕoÉáµ?C†ÅÒT/µ±(ÚJ£º÷Ív¤­êóÿüi7˜£qƒ‰uülgñMº+é‹0	MúJ>çq²ÓÒ %FCšÌêù1zÈéÂ.ÆéjuQEÄ`‚ÅñXğ×*gq/ÏnÓry„´´xRĞ'Şìœ­AXÉ§ºû<:RW#ó«d£ç:˜ë(BSDŠ÷¯Å¤…kmğ<Î@ü›8æ†óJ2‰B¤Ë•ó‡û} ß>^¨zç{$H@òvãıÀÙòz–tàò‡­ô,'DËoìn¡<Üš! OÅA²\Ñ}¼õèØş‹V¨›9£¡„#dÖ\v¬?Zå‡Î÷ÿòH_mºÃÉíMên—‚@Õk,[İmµâ MJ›4±s·T_Ì¡}ÀY¹{fÙ×â†\d·¾ãºACÄº ƒöe½`K€¬üªkÎL¡é¢ßáÊÕ­†Qˆ"¥OI4úây¹J«İ kj„×š××®@œ$}‹Á¥gÂ´:86»öÜ¸e .
FDÃÎí_¥É g?Â;¥?µ°:aªïş½]…±Œ€éJ.F§ğ”"›Î‹|KıaCdĞ<—¨ÜÎ·8}p'ˆ¡NªŸ}{ñYæğ?2D@ULTƒ/şuZbå'ò@FÇù|1A¨Uˆğ³!cÉ¢ñ16HÅt";CNÈ”ÏÛ‚®˜kóX&†¡ë¼BŞRj.S©É›Ç¸ˆ†šNåÃÈÜoØ9Z¢ï‘=æ]µÛÜ÷Å``Ò 
Ï	_Ïl½=üÔ•İçÙ„wL˜õC†YrÛ/İ†–[9"çÚŒoŸœQ;ùõ·,e³²DJLYJCÙÜö©Ğ§[SÔúÎèÔA‡C¥ ´ù½Œ­ùroı*#âdÿ©‚5¦:FÖÒø4ì0¾·«‰—N’5eœ‚H†”`ÎOŠ\º™Æü~Œpb¿)œ¹ ¬h*Ş"A5(t«Û %£ß…,£¹Lòíò´¤kPÊDG¨[€GîL°Xl]§©D‚~Æê·ÍªW ÇÎgKÚá½½­ğ[ìğõïxÜkª {G"»ö$)z´0`—‡²˜z‡Æ×Gš}Ã³éˆ»6f»`(`ƒı§Ájyş+àçóv¥‡Ç\ ÁÅcÂ›âF¥yFÔ×1%dVµÓ °¢åªn‹Gám½\«m´	?P%$Ş¦1Ù8Y†ğBŠ½lLä©_ 6–Å¡şùcå;o%ÉDÉO İ<¡±~<Qƒ|”yp9³Ca&e¬Oh¢;öu4A‰Ğk‘kxÓ	MQ,%~ñÜlìÜÒÅ¿8n2;>»éXy,?V»Š!jô7ñş/Æ,)‚+4İ^=¼/¬ï§t8Ó>ÔK=Rgç«G·ÔU1ÖÛ”{‡8í£(:Q2òcË3k˜ò[ŒÁ5ı3É¿¹nü`¦&Uºd÷Æ—i—œû¼°KÂ=J6¬K`Ğ¸ÙÒRëÒqğ<Tw7DÉ¸­¿[L¼¥B˜ê¥ôDxÆtÆòšã‰ô÷n±j¾Vç…ñ}ªaÖ6)&è=lÁÀ_½Ña¥¢çV?üØG0uT«¢o¸÷0…EÍ…ß}’N¹r#i{Aàµ$„îjP/¾%vKÿÉj¹Örlk@¸rï]9Ís®Ç©ùIB4Á+ì0wuohJ@‘ù{9Š;#ÔíÑ%A«¢97lÙâ¶Ós‰¨Vl8£íóÏ÷Üèà‡îÑÓ‰£¹?¿*Î¨½‰L"+vtJ°W¥êŞbb®2tçÂ§°OR:1hKOœ¨™> ß5Ô<¥TäéFy¬s-Ş»ğn¾9¡syåÕºV¥ÙÙ·1ßı€ğOÚ[ÅpB3ö™¤¶0#h  ÌM±&(‹Ï"HÍ³H—Ò“Ê°v+b¹¨
­´Ğ‹€ÎØ%ËÃô+£¹u/Ùáeğkz„œ¸¹äÄh‹&*,` |2±Z ?>O=>f… d½¢Ş2L{afI. ,XüO"	‚
ùx!*”¾ö¦—çîç“} â¬>Ølpô_¸ş‘Ú-Q½£¼=˜RC¼Ÿáÿº’µÿ±Â1PdÌ{6Ë	„bàp_çDeêû^¢0Ò£Tw„l·1$öˆxª{-¨CŠŞ‘ÂB² Ç<
5ò¥JÁ7¡G6ƒVBD§©î³b‘£?åòìIKÙ­wzW<675õù.fkÀZ6„¤£Å$Q/E¹¥æGsø]åIâ¿YÔ$5`sßã·¥eT¬¬ê„âîHçU—Ô<ˆ»PLºµî1/‘k®ı°¢=E,…³ƒ->Gm‚Ú tsî¤?9n(§E¤QNìC­Qäı^‹½#›—áİ-ÚPtï^Š±ÿljI¼:ÄÉ;ŸÕòÁ-­Ü‹>6~@)mó7X´çE«¡¯¤o¶¯CKÛß8DÒ{Iwè_·3İpVê‹[Vµ-pu¬Ã*Ñ&j*‘¸Õ²:‡
)Vt\åÚNëéöî,ıĞŸ‘ÇåË·@¬WAè’AÂš<?Ãè€ÊÒü˜¤|oÁi$5±ÃC?÷M}Ùgœ]ÛáøPEdµíü„V²|»¹Ë8^TÌ±ß¡ìj8MyŠ!rÜnĞÙ9•kÖ>ò»cˆÛG]„!ó!È>à®¹Æ2ÖMI®±Òó´Üˆ&s#£<Ñ‚ù@°5u‹Ú;‹8Ö;ÈÙÜ2=‚g7¹#×µmµç¦NSnûK`Ğ)ÄhrfÜä¬ıËÆ	ÂÖ_ O¬$;’ôãá¡ëÊ?9]RˆÏ•f/”R0qëşx9CÑŒk~ƒ#³$¤¿GÆáŸãŠún ¿8=÷M*ÀAû¥¦£âF|\-´rlbôpÑÔ§?|ŠÂlxĞ]¨¦¿n$[Ç¯0)5œ±Îqó§Ño×9ƒ¼©øZ~còÍ©ÕèæĞ¥«%µ”Ï"X%Öy‡Ö™Ûá9ÜS:N'j9é‹Šıˆ>ãxh/ùÒ5­uã’+H…3µ'½÷]É&”)šÉXnŠ¯ÄPÙül-¯ê¤^Îoµ³Yº8c‰œÁƒä
Â¯{Ò¡R½4gå¢ñWú]ktŸ–Ö!ùİ ‰¸ GüÒ;?¯æ¬{.NÍ³ØC6¢?U‹Âæ+¾Gô=İ†ô—“‹^?-Sß-»"ËÅ$ƒ	Š}ÔİSÙÍÇÀ~"àÛÅT¿7Ç„ó7<ÖL°”,ù×¿+ìç/ŸšO=Ä(|õ‚¿;¡ºëø&›‡o´ª>\1Ç¦(óc¶\ ªÀÙ‹¤Á?Mš˜JÏêh¯¶A¥ó5[Æ‘c‘×AWÊ0 5=Uˆå7ô™+_ìò© şˆqm$ı"]İ¡Î0n_±öÊÑE™n·®ÄCV+ZŠT¨ú®døÛŒUëSˆ'(¦VÉTç.<ÙÀY–Å,:…Ní‘§º„š¥»r-!Ôf=7á³
ªA5dUdï›ø³Y–6²y,`¦h8şÇ5'”’Z÷j²³Úªû~Ğö]Ìò[¿r*’|ù`xTëµ(¾û¡áÙ²¯£Ö¯–VnÁ'iÿ)Kºõã4…²áË…-éaóŒ©×}ÉÉÇ.Eë³	ˆò¿‰Aæ}Õó{b-_sè¥I„¨‹ÿÅ›6‹<ö
*â¢pÓØ²ÅÒ®=6&˜ŠJæÒrEßeæuû`[1~)³şfáÂ‚¼/	÷	ÕUv©F/4öOÊr° ©~Tù£\Àcopy/çÌ/bcM&}×È~¹¿Ï‘„GÊd\ğhB—şTôs ÷ÌjÿZCrmkçxnœón`ÂûûË¸j7 4Cãœpj+Ê{`QÖœ´u¾è}Wr‚éŸ’tÜçÉ“÷¥‘h‚åm
vj8aîš÷%êiûÅÑ¾˜³*+ãÊ¶ŒDùmÉ2Â§¶—£ŠÂÙâÉf`è(©ÚxÚ µûà2À;rŸÓLDoà*¦·+ÍQôê]‘!²wÃÆ¡…*İ_,`ìrìQV¢ÎŠLe¥ØnÃm6›\‚4b¨%•H%ña¡XLxıèŒXˆnòs¸ætá‚Nçÿ¯Sù]›Ì>^ZL¤à±ÀÀsg7Ü§§h½KÉ{Ì¹
¢Ì'é*{Mé'ÏòöC!éëIÀ¯|B§
ôsˆüĞûUÈVTÑa‘…¡˜ò÷ş—cw—íÉ×ÓT£›•N-Õ4báèúvÜ["~v<ÔËrà…=İòáaÎ„YÖ]Çî¥±å…,:¢¢ê8S&™júj÷‚ƒg&ˆ•ÈÊëî‘4äae>Sê	Ûï×Ï¯Ú;Ğ¸öÒç)¼/(¤ûO²î”Â</±ÇËpL˜U=3àÁ ¡VJÅë8ká.—[C1˜õá æ"_’…H*ä¯ÅÙB,Œ•¶A·4òª…©dò[|;h5NåB<rL†gzÔ‘ÆMaByÀ[ÁÍ	e–Ö¬H©á9÷J.Åå™¯ ‘´±L!ÅğtXÓÀ<MZ6lhpßÎ/°½²= ?9‚)œrk®’±jŞ/Óyğz?º\qeè}±”pÆçÅ´¿‚{€ÕAJœw”ñgÕöÈÁMâo©Üµj‡Ó Ba-£n¶8ni2ùËåÉèt¸½“Å8ÒÇ®Ø/“*D–Ë+5‘*¨-Bª.Xòä¡_Ÿ…,T·ƒãÀrqT¯€Ò¬MßP_„ÀÆ»G4»{´ ÿ†±Ú4×´Xì°¿ss÷¦‹¸¶fRğ
çu#X¨o]e…åuÍá,Ut-‹dä­Ò$ÈìÏ6<û“§éğw4Î†ù´ùj[$‘–ãn\Ãp€=à5lpŞÊ‹í
—´~G«{;á],5øÿgµ$¨6
J†×Çè×W¹-±›€•»ã{i8X¬‹I%3xèÜCshôµV…x®³ÜDY^ƒÅ±9;óRˆ¨Z’K=K 7	G!§#qÛ€·©“s–†z†‡ˆU@è•4>tqºyPj’CpåŞ2ÙYõê·üŒ;áÉ“-(¼ûóRÒÌ—c€,aàíŞ°{‡zZrŠSD ÃŠbêàˆ²¢—×Q„^ÛÓG=éÍ¹²aæõâ¬Ê¥c38%f{.$]Wİiâÿ' €’¢Ñ-pÄd>‰Á=1©Jíj£	°6a·¾sª\¾wìForÌ±<	©]‰îİ€q÷{NÍèúJàîô72Ó®³ à#qĞÎRåDNw+a@¸0üæ$ªÿÛ5»å‹=d=_¾ãv}»¦J-‡1¯+[g¾ld&Òº&òİxµA íşògY}yéœ3.x‘dÌÎö1LA¨¥Æ`#öO·ù‘q)uÁÅğäW2!Cûü±ßõi§àX™#‚Èú¥o×²í±gXIçèHéÔle)-‚¡v%µ—³õaÙnDëÙk#UHA”µL©¼ëªŠå¯èı™µw÷ºLÿ*MÙ›İa[ Ô$nRjJNVruªº¨ä‚GÎb²¨5SºÄ4³@áÀÃààõ›¥Ñ¾q¤ÈpE.¶T|ÅT¦B£TPVêÛ:øÂ˜í×˜"×h°H¥-“x·?6V¸NI$¢
7«dÍgTRÉÁGÕ6¥ãW'¶Jÿá2\Ø…9
zHdÚ‡¸şÔk³˜–EŒÍŸ[ò]AR{&v\Qšp¡Â¿ge ± .Eh³Šm¨×ÂS2vW)ìµ½¼b¶{·l¢íÏY O"zÕŒjÌgŞˆC´¢š'©ÿV7˜ÀÉ.Npàß¸€ÉFU%Ø{„é§¡]ID4t'ãQà$5T5æÃl:­Ö3‚6Şÿ¥G~+ËÔœ%¼[’˜ó<øş™ƒ.wåê•'>KE
UWE¸çÏõd"—åm ¿4ÎİÚ¸À¯@ñ26Ju¬<À¾çPéTCúõ»zÁêQ7}l/f½ÇæƒClTñşk ÀÉ]ÒgEõŞñnÿ¦ŞŠ&•VtS8`¦5<¶´i„h³›$:Øp‘+¨óUªßYlòÊÓèrÑÍlø®W…ºÒmE¡“XE§W:¼ÿ:(QrR>Á1ZŞTGT6Q´œ¤ÕB-;ÅWäŠ0E ¨˜İ¡!–;Ñâø›İî„Uj ©+˜‡•Z‹Õ™z‹«Aôâdı’ÌÅ“V¿¿¶ssn!ÓÇ9ÑUÕÑBDLü¬Ï8İ™½¢_k¡NxûRF(Ë«Ø:“æÔs¦‘yú@…h8Ô#’ïbKÍözÊRS¨H3yF!ÌØ%&i8Æ¢–àI%ynÊlBŒ}!êıÉæN›’Ïr\mŒNø:Œ:ı]›}İæ«½:nîÊ’±Ñf;(VóúÖ!÷	ÙÒIÈoÀE»|2 %€İ1ño„d
å5Y92cîo×33Oè:„üYìÖ ÃR¾”QuÛäã.¢KP»¹’çG3IÿB50pm¿®,ÅÙ¯_š"A¿n/%E2Õ›?‰Ù¼DNâlÙé¾/Èj°„Ê$pßìÎÇA)Ì¼ı —ù-+áü¹õcmwË³øŸpq96…t<½}CÏ§	_2a6k¨Œüı™Ñ/çœµÁ²,	K“tgxUÖ§1LÉâùŞ)]@"J‘SR÷÷%x÷As(ø¸VO‘-²»§c"Ò‹”¹ìW/ËlO·kI%6¾°¬99Ìô’	cü5û­…Œ«(ÊizwR¡Ñ„åÉÃ	‚°~ÇáfzˆÂøl.ÿUwRê—çnB/uå
‰›QùËq´†ó,ğí ©D¦	A¨òŒGmCB?Ÿ:C.Rí8H6cxñæÀ‘äh§’˜Gúæ’å˜ÁpéµÑ÷ËÀ¾êµË×\vÊ¥7}‡óyF¹«Ğ ÷Š&¶ô^0ˆŠ\ÎâŠ`=$æŠ«Uä7ÎéüŠ’ù<ö$ğş3{ãÃ5lä—ÙÌ0¹/{Gz«Ì²â…I½€<nÀ·3–6O5RnašX=!aS‰Ê=
ß³óÑ€æpe÷h$5sbî\ß‡s_I€16=•¨º	!Éğ¥ÜHäíAı[ ÄÀì^èHM’ v(šŒè"ä» Æ¶îÌy$ÇyÌtöÇfä÷áe‘ğÿEàW~åóŠs ¨sæ’Iq CÑR“;$<>%È¾9Óv<‚éA¶ Ü´ÈŒ\ïŞĞåIÁ-3•®‡óÎÜ%¿®¦ë<ºYÁÊdõı¦ËıMTz·ûÙxC†ÈÏü5Ğ†ş3òä§&ƒó‰¼÷±ÆPrÜÅşsPUã¦`v~°Şyøˆ/3ÊğáßJ:úcûH*YÒR‰ŒêôIŸ&i]O5ÇåT=f^Ğ¿â.y ‚sJÅÕ0rí£‰RvæÖ®bŸÁÅA7¤Ö¾¼£½P³:{Mî5œ_AMÏ¥
‘:{rS'1çîVÉç›ÕÖà~ôo%eN-"ÙÄNa<JKB§Ğèñä—«{7Å*í¤Äã-NÙoö*öÛ)µ$<u7˜"8£ôì˜P·š¾ ³J­öq9j#XDŞKı{@£
»,ÊŠ6Ä8’ï‰*öÖí™ßËp£Ã¡bÔØÒZeÿ?@”XŸ]WäZw•Ä¢œ„FÕ+ì­ ôß|½úe$¦)ê%Z¥}ÛËLgŞzM0FC—.yBá^ÑøÍÏ®ÉëgA¶12sıı+=|n¤¤|‡”;Õ½ÎŒ¯¢UToJÖsÌü¼s7e¢ÈJù,n’ø½dÆQ¶dwŒ«¢e†‰òò`»jóì†PÂ’­S¢VíqPéòQıŒ9yÈÆ¥ X…0~Ùq¹+ïíÆ—Ãˆo?r>æÄã^ ×UĞmÂğ¹<NW¬$Ç¨êìBQúùç]ï'µØO<*‚¯)(Bç¼ÁŠ†æ8Ü9¾É»b¤ÑµZ	ö%à°cgíŸBŒ"ªjt½çUş5MTä(B°y_lë¥k¾Æ=¯zÈ§É‡üL6åÌ%À†ü‘3Íî4¤g³Xô;XT$­²'¸íñ§Ñ¡"0ñoğ9¦
z—V,Š•H¼ûêk±uBÄ
³èz_oé‹¶M°P%Rpñì»„Nåø´ı0L_N#$ T¶@¶Ï’lü~Q`‚§M•ò•9- ÙOñ¢ıÿ]òjbé1c×°Ô¯W¢Ğ3vš']ÓBEwGÊ9ÛN%M¥§NŒ]Cßh°œîspHfU™­ólı]>‹;-ÕÃÒ‡`vNÁß½²ÃÙ…ıgRŞª8@‘äÏåNï©O7`6˜-É¸¿»i*§š5VÛ–	‡“¸!ÕÇAûev%Ç&( G%àjæúkŠÎur¬!!Õ'üÌÌ¬'–\Lö³=™íoæ•.ˆp]Aü R¼ÛxÉ×& ­ËbÍÀ”+­iâblĞ ,Ñe_ª½¼ ¥™ş'{¿áÀNş(¨ıìõ'b+KyE¢ç~VK½8\d|4K<†Ì²2wkœ¯öËü/‡ƒ°ÀtokXÅ’| ¾KÂ‘ÁÒĞ-Í $Fv»Z¯¥`^qß²Ms¥~SqU5ó •s-"¯$
°Nˆší—t<3\™‰ÌxÇğGe8Â¾OBƒä#.<°EdÊAÃˆ.;‘™ûøŠ©n-¬¢}@.2ŒãØà	†×½>Œ!ƒ+ØXõ«•cø•ÇF¦îÅFÏŞxRH5Ÿcm<zK° LñÒ›ô’øñ8ÕieòE^FÜÍXÌR1ãş÷ªl¬
¿baVz$faÙ5æòOOb©»L˜Îœ<g‡¶‡ı<ÔOŠŸn­cõ }ÒÏ^wŞ|@}f’bÏ¯Æ¢iıÅö)ùÁ§½Á$X(ë²„mµä”Wp“°5Ò N#ã÷,ñô3	I'¶8î~†×T>£|r›m°™jîu9¡/AøwóBæI"©aa¤Uì´H"Ö*äÍoH¿êuQööØÜT õ	/ù…Ô@¤Ê±õ£é}!¡Ö£>Ò´Å|ˆò5^Æ“K£C%ş¦Ôüîã²;¤ù/#½GŠÓ_øÚï«!ŒK™Ş«„Z#GNº{Æ±gà|N[©§ºCGnâ£#Û¡UY–çxÒíQ²©è´?|Ìü—¸ßœ#«¾½Ğôk<Eÿò©(¥ƒzç’«ìœ‘Dw½±)æ$*!u ©èK§r”ìóqÿ¼w@=Ê£íx²Kó.À¹	şøŒ$’¸_qâ´SŠäÁz&˜„´@ü<Mb¦Œ‚nE±ŒB×Pÿ¾-õo~^Y<Ä¨¿GSÄ‡Ó!Ÿ0#dŒ6ø®åñjÌ¯DGÄù@ı1{òœçëÅ-’°˜œ¯%&öˆ•KDcaY¯áIØ•ÁfŸµ9óĞÍ`Ò¦&ŒŠNCØ:¡±“±VÚ/ëá:ô¡Èpıà¼ì‡‡!šâØŒå¹ØÁã?¥ÑRŞQR*iYwşˆíğ\ÅçOˆ³Ìgb£rØñ‚‡<FuÒ³ÏK¸|PJ\’ÕA+ÄÙ?8Œ—÷Ò–
bëRv*ù‘ÄºÆšˆoLxÿü“ÕÌ)È¼ôM˜v½[n8·›•ş—bÒÿw¹g¤ÀÅè§?²n“ÍúQ–,eÑX
Qb
¹’­T–XÏî¡£…·
¼
ñ²:ÂƒCï¥,TÊæCU­óTmFbÿÌx&·ÒmàµUö»gcâôğ¼¨Q÷ÜÚK“ªÉİTP† I¥ŠH¼Îé¡!ö’7ì˜ıû{gÜ}\ñámÌÊ%gÿƒ”àb–êÂbiô&¹ârU¶=¡M9Ï8O¡+É¬šŠfœ)9mNæ°5£VG“~é|‹}<f'yÜ–JíMw£&E?ôqÑ— 2ògzı%€9BÂo/ûæã|^£fã}¾&Üj^~è:È(Øn*ú2ë•R¼«7ƒc'y·f|;>O¼^¹¤l^—x¶øJ|±G\˜ tÂ%vJéŞ.‡é†GËƒB(šJ¡ğAgòØiÔw²+Î;¶&Ğ­™fÊQqHsˆ PÎ¼JŒWÙvgyiµ†0îkJ¢¸¾îP˜!“f‹£úË«½ƒ»®O2ÅùkWpıµÔø¤½¬9ÜÂ×µ<ÈÕÑ·ÍxĞÂA°WbM†˜Ïk¦L™alCĞ™–¾AªxtŒ(€À}&:˜éÊ„ÂÀàÖÊ—ÕNşíéfJ~Ê\¯Ãb€ä²í›H<Ó¨©€sâJÊÔ/s³ÀI¦Éôf“†õqêà’@óÂW¢¬Åª¿%[šèÛ^T;uiÛRÂ	Fq¼èIå“"UºûÂç­¹;p.M—@®•\ºé˜©øÏ´ø¨é×²£±W{Âek„ÔŠ-cğQPv?æl¨è
½Q‹úÎ>×çë”ª¼P{`¡ÛŒù¸Å†üßJY]ÛUU>8ş|«DMgÂlÌíú–ÛÊ7MËÕèä8*O9AWZºPİŞ¾!“Wãq¼H¿”H¼Õ‡Ùô«6¢„ÉO<©Işl‰AcEìÊ¯ÍÈÉ÷±CSIöÂ¦é4û¯Ôw1îR„JˆD¢#ø¶7£Æ}æs€šPF¡6\Nãş+
ßR‹–zı§ÅØ(u‰vƒ)õ“+ßn°1X©ÿ²j¶Íß|şzäÚNŸØxøpeƒÄášõı»À™Ù…#p	ø!å3ÌÇ^x›^
êæãô²iR³y>£ÊÉ~C°CşŸğåˆcô:ö@XÙp,t?ÃGZÒ8¤<bxûú÷ú_L´ÅŸCÜÚUÉ—“
M«]Å3Lù]n¯@‹ ‡.Ù³HKˆ*k†»{’yXOM³P!`¨É>r”I	¯"É–ÏWËŸ‚Gï‡Ò¹.9i‚÷ø åd*Ú¯ºqöšÙ¼­£[~ léˆß”¥ééö­íŠ­ˆ7ÆÄùÚ­çÌ`NG3½Îâ›IK¹"2]gçï^æóâiÀİ ÆàkÄ.kéaÜçhM€%P¢Bß=´úC©¤Ræã/0¥„ŸÃäBÙöOló5>À¢ù¥¦e%°MzW¤‰+«æÙpƒ¡ÎŒ@.ÀPE bT{(~  NBáÀ	h¦¾îßœÃÓ.;¯jíÄ &Î$Û\NŸc »¼¾mŞÍ³0b99ç£9[#Y(¡½¾¦qnÖŒ0¥øØR›ÓGsªÄ¢rß-g¨*°oH¦x=ëİ¿b{Wb,Å*`‚…H6ò8tª ƒ­õOÉÜ`,j€ø:w/ëÃ ºÕ„êÏ®o»Ÿ&hİ¬ñKÛD&³£c¦Æ/Xò—Y3¦ƒfÔ¤XÒ
ê~“Ş]'HŞå0Y²ÂX'kRÇÁ¨l•ê:ôA¯ÙÜx 1jô.7Ñ$,áÉV²,Ú«U&DŸ#ãi/èÓºl˜O,N>	SÉúSï»v;˜ÿ¥^GP‚WÔ*¾Î½‚·Z~Dj{ROêÔ|r¨¨ç cèá„mÚÕKÒÈ™ñ•y*·S_şûKk÷ı ”y™¨4Wº ±ÍÆÓ?æÁÿ‘"i‡•‹7<Ö¸øòKºùPLÖùİ·‡®FƒãÀ³ÛT÷ë¼0…ŸÌ¸í)@f>¸ÔQ6£Ö>L ŸMŞ	$ŞLß€zSC®!Åh%úZO5½Ê}²nøµ.ŒHïÈ/ùcîšGÜõ*:dd^ËµÈ¡©]£Ó-Ôâ+€ğ’Ò¸óƒŠİƒ$F\J¢Y)Î}.ˆ½•h`Aã¥m^áô4ÿn\4Z®óà‡:ª±Z-¿é=/½9Õóª5‡Åş¹6àÊX«ê™™(Ù—m}Şğ3·N=³	ÙepúáœèPk÷&/f"¼$]fIL Â8"§åpÂˆA•Ò=Ì _w`<ñ-–Hviû¯mænl|³bEqŒ”ŒX‹^íS:˜¥H|¡áĞ»Å%l©ğ3Òt½³X`¯›jGXêza-Q{ä‰,½[¬îFôœÆ 21QÌ$z¥f¦£cN‡£ÊÂšê¼ÔÒ¦åG·ó#ê‰IA¡İêŸÏ²™˜lŸÆ‡ôªDø-~¬ü˜=LIE °r$|@Ú"!6€Õ–ºçNl#"¤]ÂÃü³fÛ®jïWLçQpÄîFı[ÒÓÚî4Vd˜Æ#êÚùDÆÇÿ+#`«ĞóaîÁoŠ("¬Ja|‰h1)³ì+dÂ2œáò’f
€‹L_v±ZNq?7%_ï´xô0.û¡¿ªÑ„ñqj>o/cëÈcXÛ_p¥œ¿Û¿Áp§;¤ eÇ˜D÷‚-G7Çş÷ôàÂÄàû)pêqHHâøÊ SŞ˜i,ıÚ^Úç¡µ‘¤ï\Û`:ƒy p†Ká?P›Í”–V:˜ô q¼j©£År´Üápëé›f‡5±¡^…¢ÔJcFôPÎd^äK–RÉ‹Ì Èˆ=€L/È:G…ª‰«/Â•áå³	Fâiq;İbe/«}Äk«ÚŒÓh2¥/“üË›ıY½^M±ÏÕĞ«j€ÛgDÛşfÅN™£†FëŞ¬ÖˆZÁqpÛbR+2@›ä2\hc¬®öjöÈ&ºìy”~Bs)ÿÖâC °Î;ã\ÔV²W_¯`§—R!Ú‹¸1¯–%y—”Ìrs“„©ß7Cğï“ Nu¼ã‘ÕÊ8Ì’¦_VvÑ-QßkÁ0V1Ò·şå`Ru[ãÉ*^Té¡üHí4r!T#¼1üv,;T<£390ı‘lZnø…ú#åjÄåÍŸÈÈôgÁİS—¥Y)K@¾-å9öc>{¦¼ô¼^¸Ç’ê)´{‰	 ‹9ÿi¿gÚĞ}Ÿf4³Éê“s2Îšû!¨¨ÛºcŠb P›nbATŠnÚ¿ë"Ï·O¼ÙÌ ÑS˜ŸşWw¥!ø§tTû\Nä	Ù(¦–Ù¼§oÔåCâpQS›RÎ¿„İëŸ÷a\6uü2Åz¸Œ/5ÕA¦ÿ¾<Â2$!€,5u«·›ŞÁ%…Œ²¼kÔmŸüòŞkı\é÷º°êº]CºLX¾OˆA)}ûù§!¾<ÿ;‰,xøfbø?$\~\@(ÎèQ¼•,©®!ÚjªÕÒeª0'¹´y4û¥œ^ÂzH™™ïAËî•ª1yı!"©6ùœ©hƒSAjmEà“ŠÍ–ÅMC!?ºZµDiµÏ¾˜÷ûRÛÖaƒìŸ¬aW8›$#ƒ½é‚Ÿºß Uş`İ N¹Ğ{,c1€ëN4…íUH	T„s'ï0r’8:AWCp×¹ª|S*]“3İn%ƒ;0	à"-æ,Ô+Æœ]á¤ñêOz5ÁĞòd>pâ\²3lcÅãéi	†^n2İâ¡(Ae5Y¸/ğ„šY]Q#Å[Õ45E7c«7×M% „¯@óæî—ÇaÎQ4Ö˜{.•0ŸÄ7¾"fuÎ
72V‹Æøo„Aƒh&ì,¤¡İB¸Ñ`×¿@¶çkŸı9w9¿qBı9#'—ìœ{‹
&uÄjÂ<ª‚€Ñb/²ºÇS-»ŸFĞZi™D²WÉ+M÷Ësµ³	8®z¸6ë²ÁˆIw0,ˆÙaîÁª®ıs#÷L´¸İ¸™'ç4Ô§÷ q€/¦Ï74(	Ågª9”‰ìıPÊ‹1’	©Ñâå¢GÓIH˜]$Õ…tİc]5[ˆ²OŞú^ûÇÛ­€~§í‘¨4DO\Ùô±ÚášFXªÖ2må¬Š¸)[ÉVåØ™îF	ğÛ–NÍÿ“¢¬*ş7< 1€ä‹¼£O	H@>ˆã¡ï\Ğİõ‚Î2óšERMÉğòº.¹U”¬¡ˆ$8«,úOkç6¼|®,dóq…h8V„Ê!zÄl:#İ!õİ’z÷Š°üôf”DJ¬6Q–3SöH^ Ä³FåÑq–ä]
NĞ0Šü=}CS`æ,pŸd‘!Œı¤Ç7Qt+teQİè…§.÷?w÷#¸s„ãs¨¹DğCÑlCå,–OpAõ2ë} Ù†QÂ0¾J\Ó¯ÍØ‡k‰è×˜²WY£?î.>B»¯qîZªA‰æÊĞ5¯ü²6‹!u;9³ô”ë®“¢ªÿj)…½€×rFÍoßaº>—Q2½¾)xıåàõß¦í­YˆEiEA›õ^äjqávBÏZœ4äçè/şq£ì ^ğ–N.¢Peˆá5ï?9–#o¯¿Ÿã6ÔWóÇ]ç†®¿a™S×ìıK<›Ş¢™Œ½´‹»/€½¶ğJC³³:ç9ŠÒ¸yïû~È+xã©ìèv…GËT›ô€­Şù<ª¶Ç_	G<BÎo–şYãÁÈ7µıŸÙ¾(Âæ£p›êM¬Œefr;r0œ.ÕÑ‚áÌÎÎÆ"Õ+(Ç:ïç¬[só,ÍHñÅàë¸™yò˜®%,mc.İÛ¡}5ÆCÙtŠP’$6G¼¹İ®#®*õ!)VQ"Øä6|ø®HOÿÌ,°˜×ÕÄa<ZQÑÜÊsù=ŸR[Àí&®ùWE—¢‘êƒgRHê¼mGâÃ‚ò$Lï¸:şDI;ÍÌš‚ñ!²ı²>¾5Yk¾X—Ò(¿‚–ö÷µĞzÚn4*À·»-AK€}ˆUc†A5Ä%è’³7aaÓoCT"ı˜«:êõîxå8Æ<"£¦5„®b \ºv@J¶àDjjÛD*åüà@šTò-9jÌ± n]Y¸šc²úbrÌ÷¸Æ¥:ÌDæJ¸¨b}…Á¹}Õ3=,.|½\ñ=½` ¼â—úŠ?¾¤îşÙJ	Æ¬1úñì1YEéAÉµ•kÍhÜ—5„ì/s‹_üÒ²t‰øùLeˆ¾eX1:½^<VdG7õĞ¹ÑãCËy8ú+ÔCº’0°xøf#I’ŸÜÏ…˜Úo®OÔø]®
uûFI@2³j¦ÍèXP—ˆÜºva^5±Ö“ñß´fÃÛ¿5g(ÓP"ƒø˜µ¨æ'`d‡dË=9»¡Áô\Œˆë“¯ÔÚ±¨Õ®ÓTVÏ+ÀS°ÉêvQJºOÏ¯y7• ¯ÙI[X†<Eš~ôÇè§‘s*Û	Pqoyx?¾
>È•ôÖ»FºÄ›åƒô£)Á­•W¸€? êş&Ç²* o¡C^>¢µˆ˜ó3Ä…îè³ƒ1wË†áÍ`·3B˜,BëôJ‚Ş>ˆÏğRWXëÜ×ë»ÈäŸ(ØüÅ3Bè´Jğ0·dQ2É9Ş²÷ <ëNŸª‡6-¤£zÁÃ½
Œãì¢©$îøÔ;¨‚á¶,7(£=ÍésSgû¤!”û\ZHÌ¹|açèì5Ëh©fƒ-İ¦ a!ı±Û¼¶©P1(«õÈŸr¥¸P›'1š.·	X¶®¶•úv€™"Î"MoMQÉ¼æ)g¶çÏ$óÕM'‰gã²Ó »zşEº©`ù™Q+æg7¢d{5ßk©J_<µ¨~İõ™'jmãŠ‹÷ËgÄ–‰nôpWÊı (µß©÷VldÀ’*)ÊB\6ŠA|ms©ËT’ÁÅœ â«ˆ—êJ ø¼…«ZÚãJîXi^°µ?¹àI_ÇØ)ŠNVUYˆ%åMÌ3¯]_êåüéœd3Zß6×€…íÛ¼L¶8Ì{èÑ]™•Ôú©ğ¼{ÊÊº¹T*¤—5ã Ãéh<ëé?#zô±<­»œÑºkb‚»F)ÍÑ“®k¬~kxI2pSÃÄdà8>cêÑçRùˆš!ávR´…ñî¤mñ–×ô–›u­’¼pœç•?j}ªqÊJt‘‡¾ÌZ¾hLÜÈ%fSJ,×·
×mnY°tb¯s¾g1Øi‡\ïÕ%£á#ä¨ÆWgNšGxgé¾4MüxÿA¯õµİÓCZ²dÁ˜¿„øslf¥J´ü–%é=h™dwîï™$Ÿ§&õªˆ¤·_†ùÆI7Pµ‰Å(¸"o§&1•„X‡vßs¹‚q2±ût)"~
ÒÑÀ-ËúûŸ)¦ÏõC‰yïG±Í»0ûx5‡ºhSÁ——¡Ê@äá²Ü@\f×«ì4ÎŒÖ2ïoš;û“¡¼Ï#+(¬àæ(ª{NÏŸ>£Ã:™ÕÅ•Ø{“`Òùl+y“FÌ!îR7Ìzm|Œ—NV@xR)tÎÓwúæRG×Å‡NJ,º£ÕªËˆ&í½Q9Ê‚m/\o%‰¤RÙë P€Ÿ<84øıj¡×æ±Á~â &ÅÙëD#âşçÏ¶ÄŸA+yvIo¦…ƒm‹+®^b\XÒªàÚğ!¦PMM&baıÁ®«*õå‡”¦[pL&ÿ¯bF³Ÿ+³„²å31\D8È¯A1¬ûípïÈúa_¶Çàò¢ºz™mÂR"Ä¶:wòUå%ùó*¨DoÜ9ôˆÎÖŸ”6?MÙÅ-„‰Î’å‚ày™6lòY®nHÙãH‘iˆõÿ¹ÎèŸºRÔ#‡µ6FŒ…,	"t¢ëŞô}”hX"KI]'aS(¨>cp¯´ª×oOŸDe}3çZ2\¥vNú¢*ú&¼lY
H/¤T²V2Ø’­ÒFIÌêŒ1€Ş¥¿Ç¶Kş/Õû§x‹·9ØJ]ÂRJñÅªD
gŠÃ}Ñª˜=5ª*Ip<¸¨$¤oøĞ¿JË˜ø'¨Ø[LªJ,&à¿À™éÛÁmOZTç±šn(è-qæ‹+~i0­}Q´$b°e|ÖÔ X~4ËiÍ.æHßÇš'Ş*ñ7`ÒOMCÃn-Ù,kQh‰ûÿm¸nÀ¬Ò¿É¸Ş!xúc…ã§ã›”ÆÙáçŠÀÅÉ‰‹W°‘tÏV×)/ï/aÜ€)@m&gESÜõ}Û¦>R£W°‚zÑXTØû»?‰m£,Ö¡~ªt‹1YOtÃ1yZx$N¬‹„cWD¤YÇbRñ>)`
àĞUè‘g·íğ&ê„¯¬6cÌ1£596Ûæ¶ªô}o:Ù0ô,çQx=Y´	ş†'Œrµ¢!ÍDĞ¬NÀL’íx4)q42cE¤×Éû?m¿TÑ|àØæ…
ôÏä€´9d(áÀçó¢Ô5O—~ÃGmû»G¸q5¬FˆæÊ•Ò‡ƒU*%íKæ¹õÄĞ‘Ñ†­—W Ühœ@‚¦®ã(&‡Æl"|`¿d$úS’(töZùw:³›Å+ì¬±»VöË/té¥J´oán§}F·I½‚†ÔËV@¼s™NèGşî
`1ì ‹é>¬~8óçÿº¹è¢8mw…ÌÉ,Ùj“ÿ1€ZÁ³o%ùb@@&ª…¿FyQ{åÀ§ñv¶×”dÒeu}$3O_`a¸üÓòø<‚p·X}pEi¦%4>`&aˆÛŸÍÔ€>fNôk¬ãğoÃ¦0ğ­Í¹À“súòİ!8<IdMtÍÛzáÃN±0»ÎÖÓIm®+Ô›{ƒø´]î{Äí‹™[Ñ¾”òDA!)Pyï;]fé;&&Š•K°Y##³ø¥„€ÆûÖ†74"¤2>ûià‡+‘”¡ĞªÏİ!jSi®•°caœ¼fe7ÿ¦ŠßtOÃ”¢ÌÕmÁ.Ó»´İG^Iıç‘N~9ÖM]¶Ğvœ]}[2BŒ$ÇÇ°›62Çß™¿w}´ÕÆmŞ §¡k\pÑŒ…”
ú`DrÌiY•?Ãş¼Ÿ@êÇÀ†>Í—nÈ)ú	VY­şó"B$‹'2áÍKjhofÄ—{Duœ‰¬ˆQö¡cµ|†ğ³F{öls€é<Jo$7™MrÏ4}ªâh4Â%z%ë!:DÔ@lãŸ_&IêJ“né%\ò–p øU‘]e$\`Ñ–âÜ…ş!}¹'¬>E3Q aT;¬Ìyäy+[_aÄô©:jšRŒ8y?‚l|+Y¤úbŠ²`DOLgJ—b'¦è-ÖvFë|‹â7C1ZÙ‹"±ÆÃÒ`dtÊÓAi ×Ä¯ßî§¡øÓ@Ÿ·Å3ÛFsµ«^8 ùëÕ	öAÊ51'nou-Ï¿œ0ŸW‘Ig–L7	:Ipô²Q/ÓWdDM­ğ×m=Ö”µcSöwÃ¡).+Á}ã hè:grm÷çÜ¯_ª$²áPƒü/î<¶ü@½½1eTO.rq§;Ù)#ú.e)”…§¿½ô¸ã[r|5Jd(J~ø³£ßJ ‹æzÂ¤Á»MdØ­®¼(Ë¢|÷R0üK[
iŸ¡Ü‚ë©¬U`É“ˆ…¾%ú©şÃîmı:hW±"$…³õoc·™»Î¤½€¯£F´ß$á¿"¾É.Í"ê5‹â“´¡¬³†Ù¾~è¸Ru	1
Ì%ºâŒ·„Ò–Ó¡¥êqŒñüÜ0U/á5EÆüQb/\”ÑÕ(ì¯	TÜRåŒnp@üğ¤¸LâœuWñ"B*›dâJ'›7óCÚ©µS˜ïöõñşâr)‰INnAn6ò.ÉÛ‚—K9ıYP¿Tıµìy®L ¡ô»ZäeX÷+Äü:¢ÊXssk§bÔ˜ şu ¡åŠ“ …Ìü+çµeå”Kİtmz.(İñ~N?våŠñÔ€A`
-õò!cäV·	EqÅ›í°ğòJWşÿ2?ÁÌÈ»z=ìòbWw»sLÈ'€´œQ*J†wÅ$İ&¤õìÚí‰ŞØõâ“(ù^æ­Ñ3ÎâUX®!§‹Ë/Å#¾gÒëJınå]ÊÏëó£8ÁÔ.S¯R¶ü¸‚Uj‘q•lxv™;R÷fˆîÔƒ‘!]¿FouëúY)ƒÆM
×Ñ€
Ôq[Ş%|Ç/ÔadC×Fk¨†úY±§p©H6	âÅöü\(¤ÂWú^Ğ’0µ5V@àdZ„ny°áùø#6ò’~İ•+:|Ï]™Åƒ~ç~}?ô¼Z?qÎ¶j?gÌ1z¬ğò‡&AşqÒ¨¼^ (¶å»ùUúĞ}ºq‰>å8T×÷êŸºÎ´Ñ‰nh%\˜aÑÇÙ;½ÚíÊ{gW‹TbÍñ²Ä»xD»š(ró±TÈ±üõ;¼¬VÄ»“6­@¸=.¯µı.ÛüÍ¿ùØ—T«gÈN³Sg÷#f$Äàµ”©ÏAi<|ÄÊ˜ÿŠ›õKÏæ]–üê_Ÿë¼ÿÃ2œ ıº+p¶©tb×öKZÑZø1ùp† ^NzÎ€Ík@ã¨aê³¢}.ˆkİDdôµ_#ëödŞ\b½ÆĞİ-)Fl@®¬ùÑI#:fTH}Rš k3è{¸È’ç-@qgØ®XƒÁ·¼t™F[Ki+´j³t'{Ì£±¬PaŞ¤l†7šz(F,ß­ï—§d%Cè~º¼ÌWUÂïtß$'ìcZ@±tTâÁ…;r…°M¯xı%;àíëèh«¦ªN•È|kA3’d§“Nó˜;…"Æÿ¾öaÆŒŸMrÓìæŞÍëtÉµ±<Úx€CZŒ×åûÍáÏ®,ø‹¸¥2™”ic?´*½àK—aæ/ˆ.8Êd%D–7yçÿ–İ kÁ»~Šæ¶u=ÃŒ èÙáº¸8Ñi„“°TnŸ£;*JJ£‰ÑÓ jès¢y7ác®À©­†{¸S6G[Z!ì•o8ÜB	PYVÉFĞ×´¬âtËÉÈR€ÑÎ„=·µªJ£<örªÇZ«Xô?¼ÙR©SSJ¬oâ¨UÓ­gn7ÿ…-Sn’è{m“|‰ÃÛ¶a÷UÎ¹Åâáh³6X%–VH[†E’âaAèAi>Sö­]ué†¥Hù•Ï.íR5h„’§6’ }Òx[dt‹çcMGõØØ§û‰oNvÃkh¦#—5å’B»?
»‡–×E§&3îSQ
I¡àÓ´6NX«ÂR<ŞÅÌÇ¹º¿?…a‰E¬ÓV²…ùmôkh¨Ğ;—ËHø†v»¼t˜Rÿ°n†9Ç«Ö7ÃŠâ:6Z­ÛĞh;¾¹"œĞc'O§Föº¢	õú¯©„â,Bø'®kçZõÖ"º†™ÍĞ/°`>Z³Ue.ñ…G-^¼:3=d¤7?z)I¯9‚Ç·±ŸIÁ&"o5ô-ÿ»¥vÉù
±!±3®»v“€6`¯[‘zHîøe™`++oêçù6tx$»s/©a£ËzÁ‡ü¯¤%lÈ½§cÚ?¾YPÄüá°É¦+™²W¤Qÿ‰~ö 5“'ùqò«?vŸ›{€!`Iù4w´ZÜy†®%Ñ¬W%6‚XpŸ€3ÏAd$Z|Ô[.å³.p&§ ÛšbÿáëïÚ¯¼1¹O@ÔÅÚ‰‹5«´p÷«DkíŞ-|d‹ÉNmĞıâÜìÿò?)4añtPXÖ-‚rI(¶Ä G‘Ja@ƒÍ–0é²ÌğBs:şá™ Ó°h¨H÷è<GÅ5Íİ®å J»øÊg)n€ñGTªlZE²ÿ! øŸ.ån£ÅáH‰bß§Q¾Š‡vEO?	Ìã1ågdM8ÓGZ½‘N›çûíæ´¥,·é9–<Ò†§]@ëªuEÖÄsaáU‚<Ğ‚R®ˆ 7›Ó™ô—ëÑÌÆÍ€r-
Š½QR‘÷[‰ı~ÒñÔÁÛí¸)à*ÉæÍßÅğ‘`vši¼÷Äµ`Ê²ëı¾3B±TÎÍ±Çô€lËèÌ‹jJ¥d‘œî…st>Ïó?t§Pú¤ò¦ªş•„îıæQv/³Šş jóÙjYæ×˜_ÓÜê÷¼®¥fæÁzn'C†¸Ã[‚Æ1ácƒL§­Şè®ËñÍ‚ËÈ&Qj£TÄ™¿ÈnZO(œ™é›ò¢¹¦º£JüÄ’‹~}ßr©B_uğ%ÏÖsÜ!¿Øº<ÏVN‘…Ú·á{rQÙ¶Âk¦Ís¸™ëp¯õ6YË#üh¿@T9ı¹tbĞ
ĞéG£:ırgˆy¢­¤i|ı(á|„ğşmÔ÷¼M©tçä•^±z ~i\Éq}è2D4tÅ[¥:Yë°À2Å­m<ı•øğBZÄSì<•6‹¸í‡p/I-ÀûWƒP úİVàßÆr©&zõT!à×äDrzÓ[ß¼_¼/Ş¬T¹jÊÄ¨A¶²Ã´A/ëIB%5gò‰/£ç¤S	mÂ/ŸÖÀ™Ä Mx`Ér;³Ÿè¤?¨Ğ<¾v–üén¨R¾›-S»1O¾Z²ì­îËœ;Şu½3Â¼²=¦°²³§á‚õY7Dß­(áSÇ=3Ÿèq9‚¸Ó®—¶]âôrËÃfP¢²qÂ3FV¥8üßyÂ6€e¦ÉƒÅ”oU/ÿcîn_zJÇ DI uÒ1ŒTš;6—/I(e…lôÒ›
¯ğh›uÁL>±ƒëÅî^ö/ülÍİö%Òø'¾Ş¤M_úê‚AİÂ{Ë‡â»×ë¶%Å¾WVãš"m–ïMJ¼ç8p>|9L¾#NøRƒºb5‚Ëz’êyËÙüÌÑm*fv|ˆ9°Eá•äÿ¸[ˆÕøş_nï›¢}WÂÈëÕ;BÙ,ƒ-DşÁ%qÑ1PúnWhváß ¬K””"ãt–Gá`ôi¶ê((`:Uıi¢ÕUääY¡·p2…îßjO*ôê¹¶óİ¦¬Ø¨^ãyåŒQ.ÉŒ;üSó5u¡åÖ¥Í±áÿÁ¡Mı«¼º'güI¿%Ÿc]é¥¿gy¬±>]Äâ¼(D9êÒ@àmï«½™oVÇŒ„¹uluSóÜÎ²Š)÷Î;¯á#hŒ¨¾™WÑQy¸ÙåÇØ°¼¸)çœïÙßLpÏëeØéÛrx¯bÂK-Â~q
Ú~špÛ'Vdc/õ j¥­KêŸ’O†ÔGß*Å´ÕUUd¡®¨è =¢ZBi*5G¬Ã¹eº˜zÆBU/+Ã±²pT]!¼Ê¨"ŒœH¤nˆ°‡»5beT‚lZÀèÈåKÄäK 
1¹÷'ø> x™´D4¤v›u1Áì·ËÈâÈld¯c Å;.r[í&„é¡’OCl(vù¶såèzJÎ¿¹CbÓ§1l]NbŠ+ØWwËÿ³ôhlù‰EÖ}:[zé|öã‚…‚æÁm«µ¥ÚÖ}‹£øµO(º×¥ïL©Á¾K,<|S7qñ\eB|¤2É³Æä}k0Ú·+õ‚Ùˆn)ô’İ£Z˜3›Š¦ír=TDœpìs¹,;'_µ‘h	ô_G3€¾IËØHÎø½t2ğÒ¨Î{Yù1^Ò¤¨O"	Íüh2Ú0óvâìˆI6´³GRÍ>jú'ß} j•¥‘ÿ¥®ñ¯Z‡›–uÜI¸ .%öV9ª‚4ˆ¦‡lL?3ù}Ùª•Ù>éƒ­øVINßÁå¿l•éªÓæÆI†Wİ¯ÂâğRu†É°>Fu?bcSë;¦`vmd¡n<ìC²«U;ŠoUØÜjKéš{õF®Ô–°µmäoó¡|3î°zZùâ•¦ÃÎGej}|K.|‘ÛZ‹Å*dC§Z»5Ù©¥[v/ˆ®0«H-ë`7¼ÌÛdóÕÖh›çÙ[İì¡Y7ÜÒïZ¹ôÊúÑ«p¯úLhTvŞ(zım™Ç¹¼&¼JSXÑZ›¤‡KòÔ8zñãĞ‹d÷6>¡ ·ĞÜITÉí­µ|%xÕá¹±A¡ÇÂûóä1ü 
™¶~N—ä˜ÔÃ"A¦ÛC±»"ìOWkCŒaÓTƒã·Q} û¾hÍdİïT'Œ ®É
2µ’ ªP>N«*¡–Í{ù ¹‡Ø•:âb~[hÆ¯¼¿Ár…êx²&KérT„ĞV[1ú~±ænôš ––Ÿ.«¢d÷[CÈy÷ÆikÕ9–Ë¸©ÇÚœJ]#ÿàH6ûø´çÌ `Î<,>4˜êınS!&2}õĞ<R'§—êojºqÍEKLr´8@—L:İ"óR*EÃœcÙ3fí‘¹C#EìéË1#Ã>c(uÚåŞ¥”öú ¥Ón¦fµ:ÏXfz¢®wáÊÌ=0M$¶«‹­*Iimñqâa‰Ô9PN»¡:Å  DŸÿé¸ÿÏÿ7¸fäæ‚]3ƒÖw?>´p¶¨©êí£¨İÓ}gã>ÄU|I×òêby¯èóvo“1'B¬Ú¼AÓ§vªc`é’§a7T']Lå1=J!¦¼#øµØ–auÒ#úéMÆ¹9$-ûnêîĞ¡ûÆxİb˜DáfözàT$>í¹nëê¸ƒd-H\¦ÕÅ Liö;TÖóøÒ(“>Ÿ¦óMş$tÒ/øœ0Ù²ì„5mÃÅ³ Bk<»Ï†Š,T“ë…Áû>/,ÊÚp~-Ÿó†2Ó¼'a@'ŒQ4#v_:‘{p•"ü#6=3¯\Š»üôƒÔ X™qÂHO–nãµsø)œŠ´mô=ÉåÃüÖøXHnRˆCö™~,ª£ØXÃßÒƒ
µ+Èç.>ü4$­Ó?Pª[ÚòÙ4%¬;«õ_ùqAı!‹×‚Çy2U‰PIëôÊå±?´æpÿ›8Švä&»ùvóuª\Î3È™¤:ÀSÀ@vÑ‘µ«Èñ¹‰G©³İ>Ej<ìò{¨Ğ²·d9z\˜¸[ Ë×baM8M@ˆÓÔI
BÕ‹fÊš>FÌåtœ¤û{aô§óøÆÜ¸¨ãl–Îøˆiz-€â¶b
u»æ°‰¬¨Ë	+XS|*c-#¶ù¦RtbàüvŞå	¸šŠ’y)Ø·sæD-¿	9Œ”•èµ¬«˜Ä<ÔÇqµ…iZwñÿÄ`£‚Ïºû Z˜WVåñW#GÊ4bykÕâSˆÂ¦fT+x<¯$ƒ¢À`¬5Â²mDJxËğÑâæ—~ 7“[N•Ş0QäãÏæ±c<~Šï×u\ˆnÕŸ¥¦
«LîD†!ÈgUö­¨¸[áÖæOŠÔğÂf@)¬HÕËÇ8=Ó>º‘¬ËxÑØ‰Ô'º¾x´W[sùB6(¼€L„ÌTÑÁßŒwm	Ê†Ïì](eI1¨o—æ$ĞÃÛ4««äZë“mçQÊ7ç‰ÌöŸØJn-7É³¦cÜôCñ
$e´Z3ğ÷:tº)Vf“’d`wE.«À³-ˆÔj16eŞé¶‰øïÇú<ÄÄ¹p|&/¸äR¶“ıÚ¨Çì$wæccq8<e­Ió ¢è…Ç®˜3oeKq“`:bb÷¨ª_O…ÒbŸviÕ¡z;òm%;©úº“ÇMèqöşšù'pö-²ÂÛêx•jSdZ¢ƒ2„Ç$äv¢[M¤æ¨ã
ËÏ‰×JÙnÕ¡üâØãva2ã­N«şpô/8ZB[¶—q¨ÃNÖ.Åö¡“:ĞÓKïâTTšÄæ j—H{ÛP³ÂÆ¿ÃDt»—–Q¡OŸ@WsêP-Œş´İ¸  Îıtøÿ¸Ïíúøğê?à[ƒÇRçwÙÇCPˆ8£).‡)*L84´<vÂQÎpˆ»\f­Ìäˆß2ô&Cam:5™öƒ5{œ*]U4y'ZØ•ÃuŠ„-¦' éãÁ5áOK‹&¨æãYV7”ıíì\.MâVÉšäñ­!>Z TVÇ›Òır$Ï*}<$€Ñ&~ xOâ‘'tfÙ`€Áx’µ­2@Ír£Ávpñú ßÂøĞ—™‡ç¿ğÈGÑ­óe/êÍM”æÎ7~,&ˆyªLâ
’2A–%spæÒR÷‚ê‡ë’0ıè2çv?È †ß?EÍOö.~Gì-¬w1øº€>ŞÏîTÅV6Èõn4õj–nM¿†¡*cÉ1^=|kB‰ÑCêf	ßoH4‰Y2+ÈÇlĞ]'œ,`†Év'U Í_•sıšÉä-¾»‡)ñà°Í“h3ci€L³ÕlOr#¦Iä?ä¡ù]èî(Û¥ûOR[ËI¡¸©Å”Íd r?D§—ï˜¹1	
 ’ëõ‰195O5}ßó8öú4½y‰JWU–›õ‹H'mY5`tp%õô—‰—ë€d‡ç§r‡ÊÍË– õ²ÃSBœ¶İlÁ-2*¡«1æôÙzßê2ãÒÔ®õ	‡ ¸ÄË€z½¹ÇY$01e¼·èf671íQHZ#!o£Î7v‘+¥¨e5Z®ÀŠi	|« ëäaè~åZdé®"3…ˆû%òåŠ£YKl4§”´)èÇî“\¢@=qO)Ô4«/°£º›]Ö_ûíİNsê×°
·Ş€hmf…pƒİ¿aºÓeyOYıøÔŠgI¡)ÿ ~áÚ?³Vü…Ë¤ıe—Û¶_šÒzÕBÒ ¤'
ÛésEiõ+à¼–I»Œ ·‡‚­¿ÒÿÏ5ò.™ÔAåûe;Æt{Pù©Èk.‡„Û¢X(3“üÒEîIš­áFÓ}©‚mÄ|WFB»ã}¢Í5É¯ú
"¶J$l?'> yèÔ*Ö–G+ñ˜í?fî`]0zúkŠÛ{Øê²Ê‰Ğú:*÷J×
Û{±&¸±ø„ôÆdhOÉq·çl®5¡-ÒÄ	_æf:‹îM­“±-ÉdÅn³¯e.—Lş\r[À´µ÷†S?ÊúL5Û“.“f>Œ0ıeìtUaĞ3=oSoğƒ°},”&¦$ÁÓâ»×˜Rq©üâu±YGH¥w.N´B~#ÖÓRa„6–U¢¡}Œ««°T?¡ Šg	·oUd¤¹Aö½•ÿ|¶gto¨’Ğş®ÜCëY¡"±‚cĞœvüûss$oĞ-A‚NÒàEŸÕIùá5\ª½”ÿ5Õu¤£@Œ!Şa/,q–gIŸ:TPùÚ ëˆ@‘ˆø´jÉÃÑ‰Vù$±Sëñ©;ß¢f"¢onvÀ  Uòı„j‘åzõÊDûDısÙ$Äk¶ñãß¼@±¹õ¿¨Èoõ6´[¦?œ}Ÿ€ĞÂ
?·'±v Ì(F˜.“™c=ê‡”tòÁxNHºx—ä»¢"„c€¦ŸÊıÍd
OšŒÛôËùb¿OÄœkŠœGfãâøíAúzò³ncÄTfg‰×fj¨;"°ÓTq°,ï’„}9LB (‚!«ãÖóQEAùX‘Ø Ëg\Ùğï (‘QÀ ®õCZ|ùcä2š®âÿ±ï¸¼Qóÿ]989bğcF¼{ ›÷”ã­³&»oR	VK6Ãıâİ)PD«ÎÛ£¿Ü|õ®6Id¦î:²P– "Ïn_†jE¾èj˜Z›c˜†(ƒ¿ÕäªD*Å&ÙòƒşÍj|è²*ãœœºRÔ¬r¦ú>ˆ•kbS<bõµ’œ¥bï@¦K×‚‡ÎI!0÷“Aß")5;œî”(t"É²ãÓyĞ-NßmØxÛÔKC<…ãìµÎé¦œÁêsÌ¿ğÊf'›û` ËbNá±d…™G’Ö•åĞê(ª‡û´œ·ÏTé+JÉ„¬ÑÍ	[‰»ò-”“‹ÍÉù7]|ıo^:s>jØ„ê®é–å&¼ãéÜMª$ê-{§Ï‡Q¥%†ÅlQÒTŒóÕ{ZÚ ›[°i>'E8ÕµCqÏú*îè»ÇKÌ*äè›¬Æl¿pRËö6¢6½uürívíÓñ    ÿò‘¾ÂO£¾ ¢É€_—U±Ägû    YZ