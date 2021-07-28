#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="955346651"
MD5="1ba4aa4808be8e6efdaf537cb57d112d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23336"
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
	echo Date of packaging: Wed Jul 28 16:15:45 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZç] ¼}•À1Dd]‡Á›PætİD÷¹ù&í5WÖÙø¯gÇC`ôãE©®ïu v &–_YğH¥šskDDb×FF#±¼dğ/$¯ıSÕ|öÈÛ|w{36Ğ§§a©o÷;iïc,t7t^:-ª’
ÃB@Ø°Áw	şö£1ÆüŸbĞIâCÃs¥XDR#Õ8×îEÛõºã€¿ƒ&;Üù7W=	“Å³#Ğq±¾©¹Ï3ÀVGã4Tk[Š~Y²æ&,KNPs=ÒpMG\à$ÿL•Eªâ­ĞßÎ*ì {‡E©OÛcäµ†àÃ‹GÎ7så”=íğ¿B1 g6¸Ê»š¥7Èê²€’á˜GÂœœk{gf·É6«Ûl`ÎÔ(À.6G
Ebœ.Jâ¸Ö9Åô[±ŞäbP¤ûÈíÌ…8—ÊÜ6AÃ‡’«VƒªÈ*ı˜ú‹SîÜÿtyQgœ[¼ª—)€µû·m¶Dá…ü…ÔÛ¾Á°Â†WAM‚*®F!vŒ­O¿õ fpo‚ãü‚=<Z¹á'ü.Ö÷÷<ÌL@{ÊJu¹¥P)ûufÖe®=âµÌÜX$ùRfå‚áEi0`ĞµÛ›bÇ($Ü Œe¾:¬Wl–tz%øhˆˆAzUjÎ"Š@öéÉEe  ŠãÕi·àÔ¥æ÷hüX	+5“€ š;ó*;šHƒíñ—8×şµÙ²“ÏMti?+÷"ô0ê¹á0O_Šñç¯èaÂ¦¿()qde¤Rôg6Ù{ë
ë"tû™!t(Ÿi¤s5/­&ó†¥e°Ya)O¼B¤îm*mmî¥¹¸ø"R9 şÃ÷AF5O÷= ì¡w$²1Œİ„W3/ùjØéX–5ã¨*XŸ2«FÉ¾l‘S=55~ßœRˆ)ãKi‘pí;ŸU[vˆl!ò1'Òl*HC°¸_´h—õy¹ÇoÀƒÌìDYvŸCıVxÏâH›ùO¿}‘:§¨%âœ<¿¨ñRÀZÓ¿–—ì¾tgsÜêwq«4Câ‹LXéî¥²ÿĞã@d5ÛYë;ÿ"‹S4%_›§›çx8»A•h]÷'¿„,s•™•ÉpPUFLèY±(¬á°Ï•¢FZGõÁJ¦eı¢+a2_ÔclˆÿÓ÷mF¨E$âÕß9¥hQdŞYfÍú¥ó¶ª+Ê«ÂLE¦3®P¢Á2šÈà
Øm³è·TÚÁÛ© ï<å–j+„‡{´}ÚÕ7·^F¯•òê+]Ì“N®„nHªZ:jLó/L¸!6dø‹%ÙmX²Rà2¯üô“Aí~nu7U×/òÜ.{¦ES3ì+l»2é‰€ –=ëğÈ»±©‚´š[ ·ÇSÜ]êÅXæEúFJ›¡4:ÛÄcÅW
ã¿°´’.=BX“ï¹î(:Oæ”´qê8Cê9hÔ¶ë`âz‡ÿÁ,‹[Izyu«+ÄúW\@6tØ——ì–/ìma}HU$Ö…5‘•¤I
“šú: ,×şW¿« õdJa8k¶K1Ö¦“&,».µ)OTŠÜlègŸ¦X‘Âÿ=	ÿ_ÔoØV#rÙöZ]C"f4ìÃşˆ…yw·cŠÚY½á±Á‰¶NÇãc]f˜Ùv‰ùAXwWMñV5Jkßdûëù	£¼…F¹Í8!.&1ÿR'µğ½—Õp×ÂÑ;µ‡Ø‹R,Õëû&8Œ£ë0“x‡‚0ìX %yp|J>4å™Iğ‹´c‘ÔhdqBª½w®^.1{½}_8Û"ÀïÀ{œĞy“®‚{z2Ë>yç3ñ)\AaÓ§ºHgğœØo¤lBòt4Şƒ/Ië=ü›¦×›ÊÄ|Ò®'Fõ4ÔÀcE®aµ1%µ“.›kÎ¬jnSê¶0šŸÁ,	T©vNPŒ5á¹<;z¨••µé|ùt\"sgéaôæÓ¸)^Ôª	pĞñ¯„¡Ùëg®½Ûºë‘Ê#s2Ğ¼ú-ÜŠ¨µ[tŞ ê—2JhîI@XÕµ¯™7
˜ZaäQüÒúÀw9r:ü¯øö÷*û ­úı }jğÑ!…*;¤5 !%ĞÁ4"-.¹ES¹èI¼öÜ#‘Æ§RÿMSû‡õU¿Ë¹¯-ï¯X$Û{-2¯çôïÍöËî˜ÍÏ2bz1.Æpš™ 5„±M¥‰Hú°q¡´Ïrj4$ÃcCy½’düÜœ­’y/À×\l]ò{€AìÖo´ ºœø‘x<¡MÔöSÛTÉÄÉ®)§ìÕ§³j€mtè¸%´E3ÌğxIÏH0+êˆˆª9\±‰ªM³ÊlLÜV+{m~óøñÂ‡©Ù“h'1¥.÷ÆÑÕ.’ı"ôCìÔ$s¬GÊby•ßÌ¿zÿ˜#”		©Øùª˜ĞÕ¨H0‚EpÁh»)
i¥·Ù,'éNÏ{­=`ØĞiÙ¶{×àåmDª$	Ñ²©öööBR$Yöi|‡&€tÜÿ¢»[ÀH
¥ÒĞßÒgÉËìœ†k1Ò­AÄÁßÙÍ
Nâ°«MZzQ[NH‚dÊ¤;jí@µbiHO ^¹"†I8B(cª(Ş(&Ò{FR½/\I2?ÄO2‡ò£®ÈfOïİXÇËü†ÿmõ$I1jğöì2“ÌÉâ×{±ÌëØ™‡¤ıFKqÆdö©˜8ııøèvÍR˜0¶RJr+Cşë­7x¸ò6‰Zº×!?q¤ ÁG¾äcÀÂFËcú»’ä	.»œ9Í³–w˜&¥üPA5+4
zK Â™¨{€íÉvlĞ »àY¤rïXªU6iÆ–~O1±à¨w= ¾ Ñ‰ûú"z¨L©lñÙc|{b§ß‹oÍHÀßPí´ôE¡ö hå#3Iİ–	›ˆ”è®Jğˆ;…O­OÎZFÊQÓÜHµéÍ2WìluR8ıFíåÓòÚOº¨úk˜wÇ·
¼“@x•–iÅM€ßÄ;í2Ë‡ø{cİ„gWZØ[=zÚâ…µk"X@ƒÌ»JYH¡9LÊRÈ…ºuÂâ¿aX1s4gn@„Ö¤êş©™ÚË?‹áUËı°—Í¹´ÊM‹k1¦SÛU
¼|¾]ÖjfE™ÈtºyúUÏ0|lKÉÍs
‘ç{¾ŞÕ9çr]òz£Şşˆ­Jõ³btn +Ø+0lûq{¯É,«‘ÖA7Tú—mº+nåÎ¤ƒõ`0OÎû]ŒUfÔøşŠÛ!bÛú”Õ=§p Ò–¹(`” `GcrÆ¢?0iÙV¢ÊX^ı‘sMäÌ¬·ñI¯3Ú‰¿.æ¢z 5Ğ%ÈH.h.¼Ê’¨¥•;$ˆŠJË`´öååfK’>¨Âş¬^	ş¾òì~leó¹õªûüÛ¯:XÌ~Îß.<œ¡ŠÈ5®JT!?wü%d„Ç:–ã,¦|å¡,B64ë†ß±i¬Šá!ó‰ÎŒùÂO+[‡Ù7Kíà÷$ğRNRšTÓğ¥bCÄ¯ }vUÅ5<öâN$2¢ˆ+,~.ı:ÜµáŠJù|6Vû”iÊğM÷šğJuÆùTÁ­CC¥€µ6XS É"“|ÓÑ˜³[•f+âŒŸ¶›‡ušÍ¥/Vº`dµ! a‹˜m¶™)"¶Ébß_û5™ğè%ÕááİØ§’wíˆ—í_9óµCzvu¥YK±’Q0pB%+nÅV%jDÉx¿*æ—kL'Ğë¿Û®¶CR>Œç,x·Pº<©Îr
çÈì~2¾@G Ûºh{DÆu–;×ZÈÿÇs…ØùE{ÔÓÁ‰V´=ëÖ/Úµ<„¹Êo–²p/]¬ûfçi9¯'ê}_)Ş&oT—Í;/âœ¸ßÙHƒÓ˜›ŞÁ¥•9^OÇj|ôX?^Ür7jÔ&?æµüt™î}%ÂœVnÒŸÄI<fn#˜XÿM]â6Ê¬8ŒÚÛ{ß¼+è.3Ÿ°
e´»LÙ;iU¶ãáW¸2V€Ç•«¹”	åìèÏ•ùrI†æ}İZ×XâáfÇg’{]Æ şèÜ0
X\«ëÅãéœ{D²ç6àº4Ó5¨ÓJÌ±¼n…­x„ú4Ã›2.9KÃ¿(öÁjº8#fo««YïÍ¦#à/GŒ/Fj'†ß-­¯WÓb–«;£ì}²ÍâëCuI“JÊãnLÄïà1z;²İß:\¿‚W›
ÃÉ&ÿÊ‰İÇBÆ°[ŒR¾¦PD÷¹¸:İQ©OœÓ˜y°øˆ¯Nó»ŒNS‰£aZ¤2ğP·BåõO§´€ÔŠ7M-XPL}r„rÛt¥¨bö[e¨"rñÅ8Å¶âÛÉ8Ï(âIPO†r£mzÿC›¿Í€z	²u(w]\; û§ğ¡y |"³é”%äôİë!OsNÎrûÜ$å˜K:†æ'Ö³kLò(u=,ü?`;@ahè@YKoY«[ïusŞğxâRnrœ“$ı¾äÕ¥øŞ›%‘à¼CŠÆ²VòçoåV}7mÚäF«7Št=‡bà‡„â%6î“iÆ°>ÂÔfÏæö	Û®>0õ˜»|¢ÜnŒÖsnãY<Û€f"bÏ…ÛÀEÑ¿T"‚X®,õØ÷ñé¢ğ«va 3ZÔÀˆmí±
ZÁT„ ¬¶æ?ŸT63Î$eª,šaCÆĞª‚JtÑ9ß÷“ãó	pI/u\ñF
õì¥Úÿ'.qLÔÊŸœöj½|¡Ç>?ãl(_´Š¦õjtŸ
ry‹Ï&#Kîèùá/`Şsà&ÔîÎÁ¦¬¯!+×I“)zz>ı5	”åÄ•[†së_„n_Ïı9f*Ÿæ ˆp¼ôd²†¥Å¶F´@€,)Ö+ ¯7]m%h'›L8'(MıF:Ï7¡aCzŒc>T¢ÌöÂ³lîÅÍ9ê}1:ª rÌÌŞÄ!K¶³†;xï¹=Ç‰²úL¸„ú q!–‡vJSTáº¡ŸgâFKÎ3ñyˆ5u&İØ10áâ-n8¯ªµ.ö¿d;ÃiíL¶ÇıV©Õ¨zÃµ-·Úø,m·>¶DäJXxŒV,¬¯é™ÙW‡ß~×P„H—F¾£IY,µÑà*&¬Wõ{Yë×ŞÕ0¶å-AÜŞÍD`Ù„ïXM™¬£Qè¹Â> BHó@srÈš;ºÒÖªü:â(›ã$JRø[ë²å%\¶&‘Îù×Ùáÿá	7d&Ó/3Ç»tú¨‘Í§ó±Ü‰U0½‹r‹du@ÍÀu´pW›“~ç¶µwAç§l´yÊ`î¹ßYl…%÷ôùlpàbcÇÉ	"ªğ*&?ì9B`…ŞòŠ\<¿µ Ãš·ñÀ®­ª‰}…fºó È<á’áô%Şƒ:@ñ3;;›º¥Ø¬f÷r¹ĞÊ]ÎL•†„]¡¥^~/y*«˜©êRXê‰[ói0hHb¾V ÇøŠúx¥wÆÏ(
&VvwÔSv%Ş96ÍÎú½›¢öŸom®F¾Ìıjs_óòÉ¶šq%
úÛ¸Ö)­1xÊÂÎ ±ï†^G],3Q_†ìF,~H`Voür{1ïìô#¨ßê¬ã{Åö_™å8ëÄd¼5	];…ŠÔKêçeİÛæöyåâqà0¸pàväå¸N©‰ô¿·JFÄ˜cÀJ¿Ÿ¦Œü·t&ÜÉG|¦ ñgËßÏŒèyê†Ü¸¡³J¯kĞªÅbå'ãÚzf*åv…õ5ÏBP'Q¥à~t¨¾L™|â² Şšpğÿ!W—>]¦KQÙˆê,†ÓWEPl¿VO¸z>F*Æı³ŒÑÄ•ÏÊs‘z€¼K´ŸGBß]ßWG^~pJê³*!lèmìËJşÖşŸ¯‰@t=ŞÕÃ(Bï2l`µº;QÿMR{,\
©Ô5%z'‰ËÀí_W¶éc”\MËÖU’°¡âDÂºğé˜Äâ³8²Rw^£EúU¦[„òxŸÅˆrr‰úY<ŒÁ1%§CDi¢8Íª£à|e=m	?kqùù,3¯½ğaz§iƒbİd±â~ĞÕc*BĞvû{jŞàU¨·ş5tÄ†×ú°!6îÈaççX“xò†ŸÿBõÆêtµUÎÒÆ­Æ¿%šzì;bt¸½€WÙßQ™_îà-:äÎTÒÂ¦è¾r­AH© Fæg£êç[{Ê…Xû¦…ˆX³Z]”‘Ë™GA( bg‰7pàkôK)À(Û47\Ø‹ Ğ>õbÅèó_2
‘.ÆÇ…6[²¤Õ,Í,fµ=÷?—‘AQ²º^·}Aè¢=8nÃ"¶û} ¨á®¼á%¶é%nI(Mr"¸ŒwO™¨£‰eÚ‚eßü9Ê}TŞ‹¦8i-èáí^°æLtjö¥‰šTñ¯{ÂÓfMìU„C×Šİİ":ÚVèÕIU”NÖÀpš'[×ºüû7Ìög‘ŠÑÜ/¯Ø0¾‰SÏM‘ˆ •{î=ËÇİX"_ ®˜ûÜ!Ñ0˜~hñkÙ¤Ò¡Z½ÁKˆõ¡ÿşëËõW¢,6.uÑí"–Ï‹ÎíTfÑ™®¶®É5vWŠÏm’™¡w'ùÖÇÏØÄÆa‡}*qË8¡ı½™²9xıÊŞ˜q)ªì:şFb¿İ³ğnq!31˜SÂĞõù#2³û.‘eP¦a×ƒWZ«??¾-hßl–¦·@*ÒĞw¾q,-¸VI”ÎVjşP	_D§"Ìsäì>gÄùO*¥Eh(n’K—§UxòàYÿ2Y]n ¹­ˆ/şã¬WHÖ>3Ç/3ñlªs>~l§¸°’äŞ·’ZRs²Dœ¶÷Ç	Øüãç˜ğkN/}&÷‘É‚S¬'rı^ÀC³8½úÃ< œæeÕ Ò<¦ã)Â°ĞÅøš†TÿF%úH‹Z!m"U6iH±òvZìğZæOo\ÜgÀ5‰İ-J|2àÓR%¼(fB0•´Ôü|´±µ,y[üúğ‘¼N'©DY	Ó! 6øqeâÚfq%nb‚oÈDP¤MKg	hÑ’’o0(åAp9S?õİS"´É {Õ¿ı¨¦Ãx@²´­oàU/
hT¶À>šQ«•hW8GkÉ~.	„#äÿÃ5/zğÏG¸äôÉ÷69úApä³cuV‰ïëD	?Ò~nøTan¦ëUHgI z cO>›nzÅ|ÈÂ0KÁ‘Ïg|ã-æúRşŞE‡bJ™å›$ÔÒØ)p>‘ıfY£†éİT4¬\à¶ ªımÍR“²Â.U	Ëù, sY5˜ëütŒ!š½ ÆèjÓÄO‚€J»ûÓ Œlî!¥ŞûÍ˜Âg=¯ _"Qìz,‘í,,LÚø¬0EÕ¼Mù6YĞzTœtX4ÚÓA~š6ÆW­~‰ é[Û`8Ë
ñâ…D*n¥PçaË¢Zôÿ’Îÿ1Tyo£î¶õ¥W‘{™êæduõ°öĞÆˆ>¨¯Ëß—.;o’†İgà’`ÎØ$|öï<ÎwıÆ&¶°umë6i"uŸâ36¦²fL¹_Êi©Ø—õ¯w±jh¢ıÈ'±Ê¿ÚË¦¦wıÆøL½¿ÛNÁí¹{—ÜéS§ø9EÇ M­bã6¤uanfYà‚o:O×5µÊ¡ˆûUÛ–Ö›é¦ÊÛg‡Ñ*é è”Üî>âbP“QX&_·]™ZW/T£cCg¦¤ÖZJ×I,4–UÂ à"çÌ.í`“±f
W°¹2ãsÁ÷|dˆĞäHì°¯ÊÖiŞÛÑmìÒXœ"AÁ×ØŞX–C|všœîG8Ÿœ›×O¨Ãü¢9t±ô›¼âc=˜ğ»©5¨™ºm knâîĞ4İFã¼İ)TSå¹G°;·ø°KÜóÏÛàõxŞÅ+ú-|_q_¹¬íÇAÀOŒ·+àş2äÄèÅî7+9Bîñ|Xö_s¡4BµÓ˜çaÇ°ãóù%í[Ù—ò·MHÇà4>îfE§èViIxÇ“¦FcR5@ô‚T:èmò·5±^¸Åy¶eïÇ)ª`™0D°¡cß	åéwMv.Ün8˜Nå„ [ÎL4JIéf©å€W?–<¶¥ Ì{üÍSµf|Š´ŠÀsè™Î>ŒÈÒblX°>ªµ uNäW_JËäpHX]–ße‘ÍÅ1Õ=¢’iíhÅÊ©„	r{æŞ{¼O:©ŞXTÈyM)Éædñ/.zˆM\¾ÇÓò«$je»ØS¡ÀÇîœË±om†X»<
Kå„/Ë¥jGğ#¦«>;ÁìWhï÷íCˆYç+2~¸
Ûáj0|0•†:»ÑqÜıF:n´õ[ÇvbÒ¸ôIßÇ şg¾mòÊ€¿I§®`ÎcŒQGº0ÛËö'ù v<»K)’ØcwJ‚C(ÒÕogŞ¤¬3õñ†Ó5°€™€~†R=½Ÿ'BKºôá:@ØF—" ÀG‰X¨6¯z¨*Üp!M´ó¢iXéèRšou
Áš±ªÑÒş™“ÓtYÆ^Ì™a4©…¼ğØ6ÀÏY¬×‘¸iŞ>‡õ'VŒàï• &=Â¯YŠä%.Ê@>»ZşCøÚîÏ4£ã”#x•áÓ‹X¼í¬È<‹1ö5ìşhéŠ"°Ú‹›¡²4 ¹^ÌŞò‡–:UÀÍ ÷†Î_×‘Ïiÿa8)æ°KU6×¦,\†µ•¹v0hÚ!}/MVh<i7² İXEœ9ºmÃ÷«c$#$9¨‚¸ë–…ğÎôd8_ïb#Ôö‡{PymÖÅîtŞ"ôÅ”@ßÁ©zÀêŒ‰F}TÊ§ÈÆK¥ûÙ¹ß®ÿŞğC5zÖøÓJ?ßÄ ÛA6§ëÒmôJœœ[ôOfµf/Hªr×ícò5:˜ªæİé¿üå‚qÚ×W‹†R<
3ƒœ/v’a€½Ü*Ê¹BÍ¬‚ëUÚzFs'9ha¯Ai¹ÿÁÇ¹6H”÷ÑMª@<JÖæ¢â59†’¹p¨x#qZLò•¯2…M™4!ûb>¬Ù¬ o0‘\[8Ï©À½jŞ[ú÷Ê[),›à³ü™ ÅÇqÜp›Ğ³»÷®àÓrÃtıå»ƒŞ§\Š9+7&c²“üÌµƒÃÒët÷Ï(‘Öôê2ÁÖVT¹õíQ:fı_²ÏÒø~4é§Vh<`Eƒÿ\Dêñ¸¡n„®hÿ…ËWf{‘[µÎYy:èM±ï™H#%*6Š›c¤RÈ ìNsşÆã¾b§İ#Tç½YüÅh<ˆ­L‡Àµ’/rÉÎœ^(ÿyÆ¦™©ËÖÛ&éX'_ºœF3‡F Ìß!¼ÖìÖk”ÆçBÒI_2'¯9ü­¾{ùhq h#Äï_%–EúCÎ—WP&gvám¨öªØÇssi pJÍ-æ#Ö(Â~ïIi=øÍa’ÁUÓN[‰ 2êLÇÊ½‚%ãÙ7N—ˆ@7ÈÇÌê­3ëÑ»Úé±×­ZÑsW“HÙnj…ìÂ­"]¢°U`#¾¾ÀÏùºZùKäŠ:\ëåz ÷ØX¦n’ùC¢|\Ô-Ây=¹|à$	® Bì©Si<§ò¦—¦Áds¢á»ÏÜc\£½|o6ÌˆìKNò1í ¤ßPª7ßÙ‡ÕdzÆŞMHßF®<ùàEÊ‚zhÎı2sgñ=°^…¾z¾9¾…(ã‚T€÷€Qdé*îˆpR3ı“oµQ-DZã9ÛE\¦Âˆ]J’Œ¶•“a”{³–3tfæMÇ¢¸UÇ§ŞhJËá³jè"ÀøM%wHïõçz/ì2„ÄôŠAtŸÅ#¯:<z¿pGNïÍ1°°£fK¾™»=Á‰=]OšñiLùiˆñ¦ÈYó$4ìÊû7æörÍØ0EıÚ`K¥sJïáÄ{
N–Ğxô Ô~
®8X>—pá (²®Í:üû?òó‡Øhú#Zs&‡œÿY—ØÚÄ•úõ»DÒSw~Hh ©º!YN9ÆËL£’_jP¹kŠ­,aÖ{µúR†šT{Ëu™Ù20f{œ€		$(9š ì‘ªÂ2¶"ß}Y³qF« sá‹á }5Ê¯ò[,œª	ÙDèûí¡EŞ&V1ñë$ ÜC×Iy½gşh)¿åoãî>%F"×íœ×Íì)—0N­QJ¸]ºGJ2Ûü¿©ÍŸ“úmüË¶QO)‰°ÿ¢Yò‘cn€á*^‡€&¦»±Añ¯àšV‹7Ù«³Ü	_’ŒÔ‡í¦ÕPR7"…,†OTñÿ‡Iåğ„^èèaY
-öº˜õŒç<§B˜ù‡r…·âË‹Ü‘—± V½ZÜ æúÿŸÇ­Z`ó³ü<P ÖXı_¦€t"öa«1‘ë¶ƒ=ït~0ÇA8vñ²È·e‹Š¢Ö=9IÖÉm„¶ƒbÜ”6rááºÿé-÷)¤ï0Oõß>z‰II Ò²^˜Qä”Ÿë¸IFé[1	$úïI¡Ä2Š¤Œ°˜a´ï@K åU[bĞã¯æ	d…ÆLn Ù0¼8­H8«¼*çW<Çs×ë¿YÀ)>´ôlÄ¨ùChËjÖùd,ô‰şóV¾ÊÁkÇ\Î'ÇÅ„Æé}óæF=;ã®Šô2ÇñÏğSÊ9¶wç€e4K*ÉÃBn–ò½hcò XT}çø.¶<i‹·°—m
6{,Ês¯Q0è¥pfÈƒ—èĞ>±é·ãÚ¯4
…ó¼€šİèàÊŞVx2øj ÀÑ·S0–d*™ŸTÏm CÌ6,GB‹À|°.!F¹?ˆx˜¦~5XÔZoËºĞÛÈg%$·¸ïkeŞ%±“¥I"¦“£H•Î>Má]öŞF»û@\hÀe6p‹˜¼>ÿaÎ!ùéO„È6Gìï!SüØ^òÌU,»W‹Z¹Å4VÚ‘_K¤`}^Àì¶ö)-S=(Îz
¿ì'İêÏ…i7Wd°ô%‘6‚cîïœÉ§YÑìk0Ş÷e=›7ÿß¯Òq6¯/©Zƒ¤ƒ§HÏºes^î“ öW†P	± «û¤Ùha˜æ¨LÛÕk¾ÚB¨7ˆ™˜
Ê²1R(ı¾Ù4Í^—aÛöËKÉı_Kç‰VzU:’iÊß§ï¥•×gIóuÌ2$)ÃÛÌ#Õ8Ö#®*‡¦ŠÛmÕÉı	òyÙ¨Áøl7İÃ¾N%§p´:‰ä²ãè=§“äNLÉr1æ°çÔCÓÆ²RÌsš;jQê÷Xácõ„HñáŒ`ô;Ùv%¸­Ø¾,Ì (ú-èŒ³Ì~åYc÷Ø>¿©&RuZÛ)îoQûDÁÚˆh/ÎH¸ÅĞP¾}”±ÕFÏ­s$6•LOe°K}Ù†MßWÊöÄóbÚ¥ Ó¥ÑAq¢Àâ0Àª0Àï›;çöÄ¹ˆr«
·©wIéN¼—ôZæÆYy»Àç“!Ég"Êã¶b3gDÇü‘ïr¸ñ´ƒ Éæ¹5­¾Ÿ›ê<Ó$T¶bŠ°¶™å,@'úBİ0Ævôwƒâ}ú¹~)2i–Ì£Šß•ŒI44şfÃe¸RP	¹bÃÖğTò’w@E[Uãq¾3˜ñÖRGš˜úhj}éC>3¶—)z+9¶0ÑÄùw{!Ès4Œ©ê¨¦ ZŞ%{XÉãñ,]¨j_*FeyÅšÔÏz
ßµ¸”ÙÉY„ÉìÄ{({;ê’!¸½ãba²€!iyMóÔ²¬—çô%ç¦GsëV„Û˜l{îu‚½³™ş>H»Ävù|»/š!Ìi0?^ó
æh{ñ[d½¢^pÜnĞ†ğÍ“[3Äºú7Ó¤Š±sp¦A,jÖŠ÷Ù?YÛİäø‡¤†Y~N1Û£¶·-D˜Â¸……L	A%Ã£KhØÆä©@LëÊïÇ¬Ñÿr5•9U¿,ê’‘bÙVï(–kıîzWf ,¯²=1åŸ¦Öës’q6x\Ìå°A®½ÊörZÀ¼+æLŒÄE8k<ãğ%ôı#"xÉâ¹wùä¤/e¨5.˜‰?³¬}E÷ÿ¸AôÂEX«Áaá5êZ<š{ŒbÁœ*°„I<E/û©=uÛ¥`¢œÓªàaOĞ¯züq|şjÄJIÚ2½?t»T»ƒ‡£ğÖáøHïäCÃ*Ä½W"è£Ã}Ó;ädAUd—%ÂIÿ©jC¥¡ÛMş,°²Ë;¢Ó¦åä¬ğ0İ–`;îàûXjvF'¦J#Eµ¦e;`lp$a)ÊX*„3¶Cß)ª…h·ÿ~5faÔúøùEş_o\yÎ<¨ÆDßb–Íxp ;ÉEÅ¼B0(8_RÊJ–û×zvEõ°ÍÒm¹Ñ,×şìÏµ’Tz1'Ùc½:CTA¥/´°o‹mBÜÜÊ‘Â?fÄaU‡îÚkÉ-fª'^
G‹TıÎô±d¹>U³åê3èÕïuşAõ]ÆDœ-Cš¹‘úMÃ#P¹DFakî½ïõw+,8E¢–ÔÌIòE4÷á' \ù(‚ÚUC&Ğ¹ÁŠç#àëËòûÕ·æ}<××÷#óş™Œ3¸ïË»°ìÖó±ÕHğ~´5¥âß ‘HZ)“\á$w[?ÇÏ,otló±„7{hY Êò~şŸïù µ—U0yõ$B_úµ”TiÒ_“Îœ˜ƒjé¡mko˜A9
Ó}ÖyÖvBnhå¨«V8‰Ù¤#—v
¶(m¦î¤¥D&SÆùmdL¯#ìx¯·ÙÜähl_u£®·Üà~ÆÊÿ*+ı%””SÛ†Á‘²uKü&ÊIBNs:Ş“íîıÑ	…É“ga(}˜v':!cD51!Ğ¼\pdæöÄ¶o†æî‰¥U<H	 g©#ÕkŒ N ºyºöLÉ1Ì3ÌrÈwÿÀğÈh]rBV¸ÊÈÉ.Šå©
àXÍÖÉ jüÙü=˜x>ŒØ:ºóz$\•B‡y•½Û¨©ägX­;rı„Ïîhôª-ùÀ†¢{tu¿´¦ºLÇæı–¹E5éú*¦o«4·¬{Kø¤DìƒÓñÀ‚“VÀ³•n×áÇ­ÚMNç9W¦ÚÍ—şiàºó““Ûb™-à3„ŠVzÓvDÅºìì0§ªÅ#ìÕœ«`JuNÉßp¦5^¹À@!@¿~+U³c½ 0Ê¦Ã·
Ê(–hƒ´èÅê\Ö®dŠQ“o¬¼‚Ø†ôõJE„»/&\òĞwá|‡ÖçC/'È*ƒô•İçôœH¯ô'”R!,Ü3K¹	)'œé\ğŞúê„BÓt7¼Õ#òÏ"Ş‰\•b>åMÚuzBD>½Æ&ÍÔkŞ¾ƒ¢fµA¸¤Âš‡úEÑZ$öæË‹‚ éWÃéA¤»#+à¢0E‹>t÷iu±¦Öš Øm<'ƒoJ0‚ÂÛd¢Ågpà1goÑ(c’"•˜u2ï=$–Ì®ê×Öx¤PSÉ|Ñt¼Øè|¸±Íä>ıÉ7äó}®`UMlª]ê*³tK¯Ô§”Eî%É¿§ƒĞ‚¸±—@±±}ø&éÑ…›¿îUkÀ ²‘ÁJİfH~ˆ.ê5œd‡úØ›¥Téõ­òÍ1î˜YîõâÖ|3¡Pºnjç,² 9õQc"Ùô§À®sîİÊúgD"Ù¤³Š1'ĞÎØİ&@á.qÊBÅ]æej·û89íÂ„ğAHá«È…l¸s‚«óaelˆ½Ä¯™äYí358¼gÌEåÄ5¶(.ã³¦¬+ÚDUôŸ2ê/âºYğÃxæ Õ2¾àİ‹¾éÌˆH»ÃÊTS-NnøŸëZ®{Ü 6’•× qˆ¸Ïù;6æÿ¸Ší“¼“pÙQq3«şòM$fšYÕO„ZN×™ğ>%‚-*g)€wi 6íj3?O‘½JåÒİ bÌâ·’r]Ër¶”ìJ¢m2í’&TWb…wªŞõô¦ÛĞ¨¡"^vÓDMå˜Ò)£¼ÚYäzÀÚk|Euõ%Ç¬ ¤ZNQX-Æ°úè™Ë7+6\\ ,Û@«Ryd¸Gøµ™MTÕ¥>î>÷›o¯BÒxıf¯0™ZÅ¢5É-†ÊÖx¾PË¼ØùÃúqµ–-¢fn2jº<)L9ùg_a¹Ü3£×“gÔ@O›US<}uØÿƒC¬“lìÑÊ±ùâ¥aùF8ıDªƒÚâ},‚^ùiÇŸBÈBÛG¥Ôf¤ì	5‚ÈY8ï`vÚ4å¿»ß€›õ…˜¼ìNŠì&Q)Çïƒ0af~f³ˆöABùÊxŞ7œÃø9Õı!HÑ€òÚ£w›7Ïøw@Ö£F‘vKŞ«¹¼¢Œf¨+*ó—5LS‹ú¸‰í éÈušâ€¹ 6R¦éUX>{½x L)]eê³RM¦ï7<SÄ„[`cÕ”¹	å‡¥J7Ş\Ûü†ÿO“&,ÁkI¿.©©7€ñNûd'‚ŸG“X‘…ğ7ªLäjöÆ/]ºÒùÏWªçPnïj„ŒÜµ•gH1W*L°b÷‚ŞïLL+ç–ôßùÉí
	~Àw«úÌ|Ÿ¨<í¾}Jò²»äò¶-İè²÷´ĞÙË±ó +í@F½QyîÍÊ?/<Ùi‡œ	±‘›ÑFÇŸIûx¹aåuá)Û¤«ŒZkIİ}3²Û%1}Æ»?—Vtg$òl¶8%6À×e–Y&	êĞe÷  koO,­ÑW„ AJ	ïŸXYPpïtnğ-*Ô‰©˜#]›Ñ¶D(:_ØíùY«JzzİpL*~­¨‡Oq¥P[H›™˜œsŠŸµj.?R@,*0ä­ÏwRºfÂ£Ø÷_	7¸\òúlYGØ)Şä¡pÒ,\œyõ©öL°ê²Õ	Á²\E)m½?™Wp˜¸Â&!>`ˆo­w*:q…=ÏH(ø`ÏËê€$‡x«îÌ İë½Zô!Ò?÷ûA™¶‡¿Ø¨lJ´ÒŒ&•¿ÚP[ÏÒ½´‰Û}I$E]‘âv³D£ó¢ ®KøÔ®*.1¢øèã`J´WvÖ¶…°ÌQébîj¿²„ÓYÊÏeù{ÕbÒ•zPñ¹`ùg+Œke>'uÑ~”¢µıÓ×ôÛ'µñIMüf6­jÊa°Ş=Å«MGøæŸş±zE‰§˜­†[øYqKásôBæ"Äš§4ìı¡PhJ=ylÃáõjbë§²ìÑ_³Q~·sŸ´SÇ¶Á¦Àã->İk‡v³Öògı§C8]1
b¤ØÌ:iÔš’Eßnpxê!#²§ÄÄMÃ˜ÜVƒñ7]hÅLmæJ¼±®HéöVBÀÙÓ+³cBôTp*£0ÛN`¥@aÂ…’œ¨6¯Ô0î„lúåmGT¹{zåC(b‘‰”·” ¹'/=c2{Şî¼If”M€–A¢Æ®ÛZÃmî*wşj3¸æÉtÙ5kÒ¨.Fû_Ó¶;&9ù²KÈëÉ…\ÃY-›ñ {­è0„®?$KÈ¼šÂh§>KĞªœ;˜X•<Û?>¦ò	áá9m-ë•££¨‡+OiHoş;Ê¦–ÙïoÎG>Rörç¸ÚK3±-&4/Ú§êYÛå¸\¶ÕÔeÕá2m3å‰³ÂİÏqÉÚşüaïMÚ£ïÛáå“/"2J 1tô›êÒşŠşÅp{{İÇ“$œ†F|õ¼$±§Ë˜»›Ûo,;òK{g;I|ÈıVåL—úRkÃ?ó¯‚HXsá6Wçõ
i\™å?vº1£·SN®uÕW¡‚ù|ÁV”¯k¸H.Rõ¾.ÀÒú§~D[’á´±ˆ²œÑ€×K‡-4Ö"NÜãá¥’‡Ã¡åHœ%àùîñK@$ ÃKóXµ*#—ÇCE¡øÿÍ†ğƒ¤ùûŸá{ışñDõÄ;àDš…âÄMó¬ÛÑÅßìB‘Ğ Ó¹ES¯9°‚Ú˜/œ§Öé6ä•àO»	¥2‡·`"Õƒå;İ¥­Éã“Šw“_‹œPIüµ?"MTOôv*¤lîo.ÜÓ]4ic²íDm„—ÓóÉş	.&*®ŒüZ½Àb¹‡DJİâ};eìP›qAt”½jJäüŒ¶Õxôü³¹GGWÁz©IÊtØ¨gÌA7çxTÙ;ŠÆpæ¢â°/¶Cjú¬°…´¯JOkdÅöu€3Ú×h`qÙk#¾Öe€ÌsR&ÂnÏIêŠqıZiùüºNfv>¤¶`³™æÿÜÄüKsÚ##øÎûÿU­œ¬KÙÿçøãÊØ%ü
ŸÏ¸zÙéTdÓêxoPAÌéÕP¯,¾•šÿzÈßbÁ¹ò9nßD9W‰ó±ñƒ“sÆ¸ÔCh˜…°€ø–HæD›‹	ÀhåÉ92øò”¸0G
„'¯hcùê9€º;¬”ÓË¯HG«–®…¦ß*÷#6<–æ«S3´Ì¨­ºbÏŞÖ0/p6Id±~Lqu«Å›{(GvfòQúÛCJhXÍcøe>‚[Y(Óäùo"E90ÇÑû¦ p­ñ±<	áoŸÖºn›ŸeiUèÄÊÍ»šÙ¶a…zœZ5w½éƒÂX,BüÀ©[\Ö¡ÚúUõí¹ ´ÊEçWOÜı,
uµx@ó>ŸõúÁîWŞBÂ9+tË
Æâw^åÚ8@·­JkpjtàgO·ù£GøF&¡A7:wJïoêÀš?õBŞ-¼.j6ñü^ƒÃV?
Ò•Moš¿ë1#{Â9w‹ 3TŸ¥/,zZª‡}}77‘Ğ"Ôî	¶øğO·AÒ¹¹ÔóóxŞ@Ìx§á‰}œõßá3eÚ9!æ-ô4„©n£úÛyÀ's×Ê-Õ -Cú

pjşÜ¾j£ˆ¥Ë9ë 6wªm•zŒWş„`%EæÍ6nØ*Ä:xŠé'lO¼M#ZU iFíG ¹g)ŸøÒ$µLœ¸¼¼2¡ë¦?r-Êå¬ }@Ä–»“Ûÿz†78•B©Rã”6}}Æt}„\‚ÿ¯m/S¥t3¡Î$­ rœxYX¥§öI“‚ºæ0Ãçì_×ÅFh{ŸÏªp}ÕÃFChè¢DgŒöÖé/u.XÁœH¶F’C,wi‹¦n×Å áI5Ğrüıµ"÷ªssÒ™% ‡£Ñ0@3¡„æ˜ ¦ Qí‘àî• ±/]qomqêô2sŠ<r`dàV‚J>] ††³•1Qî¡&Ú‘<Ë[pĞp–
‚ì!)\°ĞnğA‰¿£¡p±N-%iÈùvKU!Ú_[ÁIKnE7_°çûÙ¥5.€£ôÁjùŸšÍï(O#XÂÈœ$¶õx/ #toË´oÕdÛÒGxÂ-®(lçHr‘2–Ş#…Ÿ'¹I£³Qƒ¿­î€TÉT›˜—Á[ÊËÓXvh,şvpÜˆ4`¿¸‡Çv˜#ımv©~qC‹Vî„6!ërBÀ‹»²Á”¶¸ØÄË œÓÕÑE¶”5™®	ŞÔ{³Ü³[ø‚Tµ|K«Œ„Ù3ğŠÚª!†ô´ÂöâšàJTÑ”×õaÇÎÎ†,»Ö}G8Ëc:Û#ê˜Lp÷é…‘=D–ŒªKøìá˜eL‰ØÔpƒr|`¾°”¿‰AÜê&÷(»­ĞÍŒÏaµ@Î ¡F 
 ;_F•ÉqËÖNårõaßÇªInøk×K`ÜöiK÷lL3B`å02Œ8"ØëÄÅ1ÿgà6ûc][V!ÚÇÚ¥ÒpıÔÂö,ò¿­ß×‘J«“S)?Ù„OD53âeiBL7›“
Y­})$ºd®¦ïã;Ş„CÏ;È!¢ÇãÒ \q?Á	¢4ÿÕNqëc€æSéô–_ZuCkõÚ5Ëº¾¨åa<+‚Ö'XÿÕËª¤4Ña‚<´ô†pvüÖüôwuP¹,[·_Z3r:qJÃä=U—üQß±’yY?)îÀrštq"õ©§åÒ_TÃÅJã#N-«±y1"ã&÷eõR,)İÌgëíÊ{È1ú >†*ó™9*.ıQ»m¤—Ş¶¶JĞH÷¨˜]^wÕÌvP`ò–§å0~©p«F;K»øÂ”£†>İÅ&ì+oŠŸ£É'İ±@kÜào2Ùv*Öğ%1/°åñ±=Åì–‘Òc ï ëİWRœø	!©"J'±üŸŠEUª…°LJÅ\µ¦²ILAÑğÕM••6j§g3¹°µbu±Wdû#¡IhË|£xg–"Ç°ô`sL‰İø«‘jXÄK‡Á‚…û–âG*\«’D‚V
?ì“ÜWLîNzxˆÛî¹'Í‹'kŠèÔxæºrXúòR‚”F"ÂÇB}çÒÑEÊôxNŠ1ÍaÁ9V,œûTÛÂJ¢ÉáüZRK¤ Y®¢@¡oÕ‰P2E",(­¯8­H ’ùÃQ±õ<vM,Nfã@Ã§7ÈÉâsa*™ü£8øéÍ9I,l%/¾%kˆbÊ)´ÅÀ;yµTf.ÅÚ‰böÎ©òİĞv‚° ØDî´d„²ÆİwÓ}@F:¬¸ºff.å(äJ*eÜAA&¢ïä¦¼ÜÚ$Ã¤è¶Q›¼¡w-±Y®«Štï*qË«
ØY¸ïIvËÊ|dˆW&ÔÆ„_9â¹,0¦»i}j]0Œ™z™®çk›øS–ÌÁ 2È€0Ğóø-C.™Í ÒÁf$ÏåY—ºyïp«†nñwDVE>‘%ÒŒ-‚:Å idÂ	S7tÓaf	¼f íÔ²Uq ypºâæà8ìÍ|äeÂAú™Lu$}Sìv•">¬”/>ù“
Á§‰lcèBé¤úWÊäÚaÍÁª×#JAóId:n{€È¬#Ã‡Šz`üéN:ÿÎ­ÀBÅÚÇA&ëÈuØ>ÁæÎgÔ)u ™n’of¥È~ûˆÓ¢.;-¹"5³öxÆA˜éVÒÇ Ê ·¯.Âß¸áşş7mî*qY¡S=G'
,aSÈÁd×zÖYÿn9ŞïTÀxº«VÙ(áşÜbUıÁ›èd$ÚqmyC‡jgÜj£ˆ ÈEö¬Ï¦vÖæÿæZNÉrw‹¯÷e¤=/m¨ª]­µ/Ù5‰íj«•º†hÛõ?Öl½\ª 
°Ød¼°AÉwÏ=bĞ}òÀê%ôÔb#¥kñe÷aDA¨š4Üã`ö£µÂxQ.šßH­VÓrÔ0^cv³COå_e‹i†¦ØL¿å$²“*»óìuTbœ¦‚—ğEÛq‡a5î<~MjÆÇĞkšÏïûÉŸW?Ë÷f¤¢ƒı27]Ì½e1jM¼á¯swY„svPïÏ"2öõ]†Ÿçae¤4Ø¹·[V,ÛÖª÷÷MVôdZƒ‘š\jèİa¤àùşHÔ6ÈNâVı1¬Z¼NU%ÿöÊœáÃ#A~ï~z>e©©€Ûİîw|]‰qü¸tŒb/¸Ÿt>5\k£brô:˜È}Él\Q¢Ë:ü‡GwFwÌoåi!ì]›ü•ú®buš¿ºç´¾Éê†øö'û»môİ…ÌS:ŸwÛ]‚üØ:%“ĞÎ{Ë=¶7”Šr¹GƒLgRˆb({íğ³<| 5ƒïkj¤­2ˆ ŸË
c—{›¼Ô[w~N”z‚óL<âÉ Â0Ô„{Pİ¡‡Úgç¤v3üyˆêÂá&’&5€ât¬ì_Âv~²TjŠ†{z£/Rn öd[È½qw½Â(XÃxË@Ô
Ïóf°¼İán_Â€²E¹>@÷ñD`§ÁŒÕëfŞ`·­Sh+€¨Ş¸H,äÊõ°’‘;Á¯¿çjÛñ£‰€]uv8fÃögUÍI¢—àa¸m8bzÍQéÕĞ©?öW#”§ñ7ş3;m_4'Å9¦İmÓ¡5âàë6ôõf	|h "ûsÑÍÜçäeyĞ©ğÍÖ/¡`–ıŸ3(to	›X|C7“²Êáß•V ;	mvšÌÌ’e"ßfÔã_)U“TšKåÈØ¹zG,EW|ùoH§¥·$@¹|ì9ÁËx—u£$}”–-<-?‹[«iùÙö¢X/C¼©l&›QÇcG2¼—X´qş¤hÊfT÷³e¡n$qÓ¾¾ìŠÕè2>•‹¡ñ;\V$œ›t–Àk©½*ß1¹ÍÖ¡×WÿŒÒv&¡\oUsĞwO‰ôÑİ1Ê!İ#PÿÅH][ì€B!úĞ
­ë1Hñ[•UFP#Œ¦(iË
çÑÿQÙ‘œ2ş¢ß/lŠªKÂL~ëäÖ‡J½.r¢ù· úw¶ã^ÎB¸…”ü˜áÎ«sÜKÁ,!Ê¤~Hig(¾y3×M±ìuj9'Å(°Y1À6&ÖYÙêÅæ±í€d‚•Ê{b½ƒÔÀ"iÙğ¿§’>tÕ…=7Ãì}¥zôÏÿÖ4¾äß¥‘OÒÊï°7 ½ë~››¼X¯ÇŸ¨ş‘sdM0§ÿÈ§lµ‹Jã<GeuşhˆÃ!o¦_y‡ãY¼ù½B9ñ¹áiW=õ'%;İpxˆÓÌFè1#*º_KÀ¥ağU)aM[núrsšDÍ$îV:I`,±¾“¸-×‰ÅñŞçd7®Q§á!d³£êA5l%A‹£etdª=]÷îFõ¦rSŸáŒjšç‘„òÀÑQ¯A'{´ˆº`n„,0”Ş!ú@ø×³4¹	Ìô@¢P8:PlKO:e"£åÅç':¨?ú)Ë'¾õqÔ`SÚaá‡Å)«§=š'Ï«"åTM¸Ïÿ@/šzüX(ÜÜ˜¾„£`v`ê†÷ Ùe&uóYQÇ¸ÓÔÓ5JúÌæ#=>D¥Ô’ºM’'ô†$¹¾‡Ê®m¨äõù
ÉEØUç¦P4,É›G›xx¯`ÛZ+Z1äÙıùó‘píeÏWZá©Õ+€‹NÛmÔŞ¹Æ¶åéíF×ÌU%§NFÍ5üıUKìcLìµÏdöf´ÌÑ“ @ñ:¯'Â	^ğMq‰mkÄ£úJ#ªÏxæ
xálÍÇ`	ĞC£0¨Ÿôi(ê­±'÷;‚ù™8V	Ÿ‰›'–Frì¯_ÃÅ Öë%öƒ6T”$8q‚R¡©A™°9ñn·[¦ŠÕÿtï‘{G¶ÃÆ}åuÕ(uúMs¥™Á P›—s²FÊ¢@ˆ€dZïg{;âÜˆ ®¿[“úèŠy¨L_\äŸR†G	s	çõqaÍ|“TÖr€»ÁŒÂ§®”ÅL’xñUTI$ESXc§IìFIñvmÅSÖ‡èæò{Æ[U¢©C¾øA	š«åÊƒlí?ü-iqÄŞ¬ØŞ§%¢°G‰éå'•+tíÑ‘í[¡&‡7§À„÷÷7:»>7¦¦°¡Íöf!Ó¨2ˆ;µÕ{­ã1ç«>È¢$²û„ôÕnuOz!d×±o¡m¤LÂ~e®\-¾ÎÀäÂ3á¸ó¡äºúkK9:ŒÃj1©){7Û‹’YÔ1±v˜ÖÖQí$¿·UŞÍ·op“Š'¯5ù M6«o³²¤$i(5¹étoü²Ÿ4eq¯¢¨)ø-ÚĞ‰aÆ\ga‹º&G{Z\ùÒÿÚËA,/¡g÷¦Î¸a«ÔmÔ3«âüç	êÈ1O|ŒÌ@˜f[­œ¿ùBÕÚ÷¶^Í
Pué“áwjfçÇxÓïáA—bh İ3äs½?İ/ÖŒğ,ô†ÅEEÓ3U‘.r— SYm’—Õ†ºÆÙÃv€:T6­wåxìpÅq¸¬Î-ÓŒ!q*ÔK¤mô’Ì{'_¿b¢õâ—İÛ™ÀƒÌ¸ä:ñÅÂµ¡&„=şj»ÌqŒ&TdÕ’5N—†¦´ìšíÏ£Àùng€LgèÓ¢¡lzRKòeikJ¹Šâ¦"”ÛîøS½âöÂŒ}>ğèı^ŒdDƒ×í€¿u2Y…åú“åfŸ£3Bo×8t±ÆÍóÙúôÍ¯tÑª=gLš[ö3ÿ`ÜÿdºX°ùXï¼_VÁo¡’›ı	ĞÃÊËø@æî;kØßßBè§ZUæRGYù±Z¼‰].Ş3*ĞÎ»#…^6¸šºQŞæ' ]ÚeUf‹F¼4q×àÑXĞû+ò±ÂŸò‹kÈò¯G¢+Jóå_Æ:…t‚@m}QtºîZ—o†7Ü…³6ÀÀzjÄÌºSlaÑö«(§­ñ¥»|ÍBj©
ˆ¯Ÿ	3T6Ê|gŞ¼h²öšíD`ô¢i"àºèÃCc­KsphÁ©«éÛ1 šƒnü½Z™².‚UŒ+qAŠ’¸%FGnú'T‚ûufDIv_QÓ‹ı„=c	™İÎ²&†WœuVÈTÃæ1¡¶Šÿ}IŞĞxäá¶\–-&®ï{Œ”íT~0²Ğ1ªUäû&ƒµ•ŠØİWŒ‡Ë]g'$¤•Ë•âw<)=ó|~,ËSyÕ¸”_\Ÿ2MGj–ëfZ_„áóéZùkn¾}Æ•„£â($náñ¶G‡ûq½©<?’³uèÑÊh»]åµã<m°.”ÃA­úŒ®¥æmßä¼_¡¹s.I“çJƒ¿v›ù[HP<©YX2²l0j>,ğºz-H‡Üsjô=êÂ•b´\à¸!„w¤páÌ(.ÙíÔ‡Y{\ùƒ‰:Ì56˜§„~™¼AˆÊ=K6k2H ûá5à©N,(:tÈS‰êÜdÖ[ôÊ'³…†@ó˜gúõ¢,)ÃJÃSò‡Ïs“H9Dg€± Q—]‚lùÀ»V’õíÈ#%’”¢W®Ú¢M6O0F!>ôê$	/9§ÎKO€Æ/]GæuÏ¢»¾Í´s XnB¾|Ó®_PCdÉ‚VšÒğ}½ô§ÍÈëñL+_³§øÑ~ˆ{º.ÂÈ?Á«_^Á^Ğş`q;¾ÿpF £É¼Ø”"x£/‹ôàf<ëXNÖCÊ˜}í×˜z’“ÿÁ&=“\ìÌ´­¬|e É¯å|0©A~Àı¢Šºz¢ı[¸@3æ•”·ì\Dõm<ÜNÔk–?ç×­n÷ıñef«aágªñ#Ü­ÔÓ»ÒÇ9Û[ØÔÍWôU¢È®wmpG1K%MÜ>ë·ÓXöù\KÜOæ9—Ëü‚ïÑnÅB¹÷VV¿'ñrœ:FrÛeš^Ì2ù®¢ãRíy{ ›n€HAÂy£¸·&I¢}áò ûóÆ%¬	VÜ<Ò-î­³ûl¶ùvUÅÄ„šíØ°s²@èv`Ûƒ[}ßz®’'5CåƒY­şu%P)D¤ÿ'ö }Å$_¯|èúâô¸ÊÅ»îÏ3Ö’S"[ÕJÜÅğ:òƒ’$‘!±Nó†šVÓ‘O0h±,9E.ÓÍ &»Piü»×]z.1SUo”	¾ «şğsN?úŸàªÕb@3Ù°3;Ó3ûÂ)ì¥kä´/`äšx UåN¿È"˜	í>+?3Ápx@Ó'TGI²¨şSÁL+hH¿ãZ‰^g•BÒÿ¼ÉF	håå"Lòê–=>!¨—#Í^{!ğ$¬&~?™0+,a;Fá7œş<w)ÀÕ9NK³»ûk¶9ÙûmÂ3>ÀfóÒ%¿ËòOªcÉó5J¾ÒäÔ(ÒÛˆßSR3J™¼¨ÄùW›€_oÃXGoİ·P…Ä¯vĞÍñ™9š± qÅ‘‚°x˜¦¸§;8aXë¸İ»:,Y°%—F-Àğ‰çû/§^ÌÙÙJ>w/¡6øÈ…c'»8:Å¢R
M¡p“d§0Úo©çĞãJ­Éd±pSV³Şdv°NÊBY9Éèø‚ÛÏ‚c¨Nêêoƒ¾)¤”^
‡??tm­+¤~p‰=4å
dão½˜İ4ùD-ELx¯(ıçg„Xw»Ú	[án.ÄÔÜŒAĞƒK¯ŒD–±ü÷ô‹ä17l£ÿhSMª;«Z)òÁ|’,Òş0I:MÕÈGQ^Í>­
'—UÈ½p]ğ£ÖM¦ø¯u|M¶ŒìÈó0ÌW`v™]/ÁÂcÛeˆ5Àÿmô[*ÑÇòĞœcğ–S 5JGåô¥Â$‹ğÒ™‘®¢AÁ|ÿ¯ÂkŠ³V…diOîş™S“¸èL¨VC´E*ÒWÓ	ë+À™œ›àOßì³íÂ7\^¶`½fN—ØÃZĞ0é¬ŒŒ€ï}pÛJîï0×Iÿ‘yõ¢Z,‹ š˜¹‘b}¡½ûNwLs¼ïE—SöÏvJò
¾?2…î!ÉvrVÚj6Ì¡	ùcGLeVæ|ï>9#ën•™ \*	‹øxèÕáì~z´}¾–eâ˜ÚT¬°L›Øšşn†~ºx[Â|ò²(îfšşŠgh²Ê4ÑÕ_á3Uïó\§Ö!»†Ğye‘zŠïÄHs*ÑåÄã¶¤[uKyW¯ÒX;ùÓ9aš5Ú­q¡zÉ¯‚ÁŸZèÿ˜.Bù½b‚–8EÔà÷VR+}f¹ÆåÚÜÈÑ1AÏ" @÷ëf%\?¼tà;eà£(fÂËìEİVnYO¢”–È›o¢FÊá¦¸¥-"b¹)~,mg¡•qM•Lt;[ÓĞ[,œ_«Õu8Ûâ0]È ÉÙÓ({r+«/v>.¶è…fŸïmöx¹Ó¦ƒŞî…YªŒyjZûÖñ¼ŞËa;¾ÈöÈpt‰Ş‹´Ğ:[™e¿‘-¾¢$ÚQ·†³ÜÀu	"^ÃuT[<Ğ=xÓUÜ›,…®	/¬èIã:vƒIøÎ+>¶¼rµ~[ÈĞ£@·ªşÕOfˆ«©ÖÓ +Ò´¥ÀqîRnİåÛfñ/:¤ô/Ë¢Æä°@ŸlÃuƒò;NÅ+xÂ—-³/oCé©ıº	;ŠÁeØ%E×óğA¾$7åBZ¥ùÊ_Š™…fÜúïÚ×føÕ;Àä°¹(Pû¨(nAÉöŞ68»š´-n&«dæQ?Sùx"¨ø™Uö;G[À|nç¨J7©]w¤8Gº¾Ÿ¥íh¼¯Vª?Ş°+Ä¦[¯Æ&$¹OĞ ×6šÖlo7@7Vâ\q[Q§Y0×?XI”ÅBĞ¶ÖSã›e$ìl¹/¦£V6p°õÉò>oø»é¥©´-¸£ó§ïOæp30	¨uBvô[2àegóçBÇw‰£Ÿ3%K>PLBÑ¢T–)Áú™¸RQŸÖXÁ0O_¢^g•/ª“ÛÉ|xWdW3·«TÆ
Éô³ÛÓRtÿÚ¹Ä/ÆFŸX#³»™s€~°ùZ¢Ì ºt|XÏÆõl¸S¨ñëñº·éqü™Ø¥í	+#{è0êğL\"‚¾í+ü}˜wnóKŠë³˜?º¦gßBzcÏï—[Ş¢Â€-Ü¤d"AqP=bU,3JZ®_ÎÅ>¡ÒR:)÷3N‹*“Ÿİ ,ŸæÇ/ı‰ƒ‘´Ó’3	TáŸˆÑøMÖÌ³
h*#œ÷x‹æDÇÅ<EÁ<'Ú“!1ÖëğNsG
ã­2“¯BŞOšÑ[‡æš…À•ËÏì/-ğÿ1ºş:ã|DyŸüi††Ú	«ÚDh†@º-ÿØdP,§c¢™KSE/ _
é¯D_¤…¾t™ñÓ/QëH±ì«Oì\ZŒÒû:–“ÅëM†­wŸºc1WUë6·¿îrÒã¾7C<_$CcS.²,7Qc_dÄ4¢	aEËµá=¿ø¾¶èÀGr¨–!“¶"ñö¨vâÇÏJLƒçÂÂƒ¤,Ö()Ó¾¼gJ3ÏôC™ÂğpAæ\tŸâ&¤‚âFqÏÿNUqåü/à’ò¿ĞÊYH1^çÈ‚îÿaÒo¦ƒpìì°)œbÇ=`©
ÿfád²°rtp&7Ì¿=±yè½¤O–T¯q°&ÏóÛŒ|³¾ªCvÈäî~Aşdk÷#®N%œ¡bÜ>›õóÁ\ÿBà;ÂÏ”g~-¤S­`qğ8?!ìLpİÈÏãn¾ m']òÑlœº7ñ˜Â·"i5
©§ÓïO‚éØë$•{Œş®µ=sØß€ıÏÇŸ=£ê!,%Ä}^ÿ¯Fjñ)ª@ç°øC+ô l%°¡ß1âPˆlşw1ÊÄkd.°úÀ²¦€¸-Ğ§¾Ã/šÁ›åÃ<—„NóŞs«Hhù¡ÙáüŒW"¿'@ ¶ŠjcPÈgXo—ô5¼İ­»R€:9GLn”öüO9S6·ÿ¼ùĞîí×«Ğâuñf2(*»-
]Ìqï5Óµ«H6˜bJ40Î/Ôä¶oòUiøålEgG˜B¹zæ=‚q°Ìsèƒb§ßJ³ª“)«o)ú…põúø2µ	¢®zXÖ:!Sr6SC…ş»Y6®n¬ë°`]Cš2^»¢^ú®ë(ã9Zy¯
5^[ï44K9“4…UÓP˜Š¤àÉìO@8)YãhXåN7§×ªOıxŸEÈyÔ‚)ËisÚP›¡¥€höÈNg¬[E{ßæ ûqZÑf,ñ®àû/ó Ú@È½|zn5bÁ{tL½7gŠªµF²úëUDÄúÄÿèÇ2=a©a­d£mi›#áUğ“Ä‚MG¤¥Ÿ EFxÜ~©iÄüÔè|ˆ»Mõá&JÛ¿ÕìÅ+û†”|iKb¤­ıàÍ.Œ#Áã·ğ[êw’Äm!tó%5m0ó¬2fù2ĞìŒßDŒIÇ-¼®Ä¨§Ô.3¥—’}İ³£ãhºòÙ~ÜSÛ™bÂ^	0—äºP'l¨Pc86g[¥¶°Kı/‚Æê­Ò§dx¿oŞ$ø¹ÕeŞDÍšZHMP¶“ßƒ|³ñO®¸F¬Ú™,»:€ñVü`üù#“P´dÓÅ~è][òTÅÈ§õŞî¡8S„]JæH—ÎxËt.PïT²‡F°UÇ§KÓ‹6¿r€â‚dá¶‹Ÿ'`0{Q•Š„P,¹Ã…JZ¼¥m–„¿Êc-|½Î|ò5DÁfo¡z(iïÛ,…n©có÷‹`;|pvV~b6¦o.[jâNhV`)'á×æcóIS££wùæ_ù-3Y˜`
sÛ¹JšYØûì7š£·×p(=4g7öÔœ<µ<áømè|À.¸JØf¶d~a¹÷W
'ÎPÓóHC“Š¶³ã©tWC_°`¨áø/dÀŞÇ]0.-ŠÆÕMW$ Ö•™òF6FNLª[ƒí"(†}s“Eú«ËôºTEËÜHn«pY2)qG˜a`÷ı¥k{#yß¿>~µ-Èz¹=;nÍë—Ûı\Q€‘Ä`â"vÍµÅTŠƒşzHb2TØëW¯ótaE\újÊÀTû+(UéÀf !˜÷v‚-_z=ÕòW—‰ÿ=+fŠ¾W®wk›ı¿4Zt­í¨Q²…z9e™×©øÉæÍª û×—š†ZU=šxyÀñÎÑ:šãßØ®´ÿ•h¦Ô=·üëâi¼Ÿvjˆ >ÍûV\¨ç¶YÌ~öb·9})ÜÌÌtıòÜ™‡lô€QÛpÂVÖ¡€è×{¹™@Cjêı¾àuy¹ËRK6]*8ú•ÉISğãë‰fTnß{pÖóüÅĞÿÇo’°n¶(Ã¯{áîfÊ_t¨.è¾’î{˜Láì4Ã/Ê¹ÄıÌ¾Çy"A¹@Í2°H‰ı{SW#Ó	@ Má¦‹‰İñ˜Ò<"ƒ ´Û¬‰N{b~5„œF…%›ÒÔPA)bµÎ|Ş$JŠ‰îî+~>p~j ³› Úo:DŸı…vu;öÄIÌOTËJà`u›Wú zN›zt)İÑCÜC’_nò¦ÒóéûYXèĞ!x‹ïl—Ìd"JIzŸ²ÈW6‡C$>ÿ\.4_í¦HT²¯ N•´““0è¦j¶€‚êG·×·ÍÏ§ôL1Õc5¥õjc¨e+şÀÛùK‹­•[´ûA‹ˆ1Gª"u8`Zj2ËæÌT6µPøû3õ*ƒ_Ã.çR/°0ôİŠrép°Tê5Pqy„æ¯“YÅ¤ù*qn”H&Ç"şilË™¿D‹fïÆ¶‘t¨V«"OÏÎŸ£–£tËıìµn<’[ªaÅ³šfíû}Èñ
käãìKú®$‰:’jiû}Æ6lY0ºì‚Â¬%Æa^Êq œÒLLÚ,½_^êÌˆü|>À*8=½õÖŸ­ëŒŸ<b0Äğ¦\n(6B©ÅM`
½°ïåfc¤nô£µÅ¡!ZÛHû#s‚°KÚ«†ÁKİ1M6ÕvØô’r‚¦‹s—úC§?‰h´Éoö‰àúèQÃçå¡³èËqôœ=Ò-Ú ŸÃ+!ev–#7·Ú{fg~ºNƒÛÅºg[‹	¬A³È9÷`§„
kÙâñÏ©F¬œòŸµL5«i)ï¢‹¨‚í'¡„’Öm×W|öYµ&é¢´!ÚRiÎ$ ‹±«zoîÓ±X,xÍ9a¿«á`dÜ¬œäèAÖëbP#òT˜ÀÎ4wV/æ]´Ğd=¥é¾1åö¸çó´#uâPcM€ªcË­QÁŠ…6"Y¯õ÷Fğ¦¹n,şG8U~Ji| “Úçü(¬*çà	øù0‘Ã‹Z}Aİb[4!· ‰æ—ß™(S_8-±u(WÊ£3Q¨ºşú¿zóÖlª­HíÓ-!î'®ªL2¢ºCôìÑQsİ°¥PKƒ‰KæW>Ä&j	è*±¬«8Æ.Zâ¤+P<Ö.d¯S=š7n6 9x//tnî Á#Áåsî4bÙ½ŠÖ[h¸ÿšà5°zNÎ¢Ÿëœd©¯4ÑÔu}àJ{I#À‰ ÆÈò;S˜1ö 7–I¡—O»×#:KÄ»uÖÇªêÜu<tm8›biÖ½u°‘Ê¼¡Îf»=ÂkD…õµÈ®çN§ƒ
Jzº`ã’v`?bÈÍÓCzôÖKPWº¸¡Ú2xø2zExo”ŒEÖ‡:?%N›AU«)ë;!Ø}ÎÖ[dƒ†v ÷Ho	ˆ‘&2ğïR®eıûîş†—–L„l†—ZİtÅKe_ùEYOî„úFMĞÊ¯äÁˆêõyUúŒ×èŸÄTeö³qvÖ±+Í†âÕFË±B€…Ë¢>0Q¶4Z’¾<¥[;(ìL6nÕF^şdğ©ñzA-apP‡ÂK¨ØÎDúv|ä¾°`Tio¾ªVlyHêµÑ+š´‚–®âS¼CSLLo;‘{Ú>“û!.[ŒøE­[¶;)IÂ¿·zßg
Î	=¾_ÇINN*â²Eí–x¨)âÚáŸ®3‹?ßãÃ;dÅŒÖGş”Ó³×)ç@rñÕ_ØâB+‡˜¤YX-ÿíxÔBŸ®Ï›¥Æ97€0ÈÑõ]ú­ªNJí©|ÓÈ‰â8íÜA‹~},ÊOøUŠ"gáıœÜÜîR‹x#Ú¾3\os®4Xj’?fŠxa%İ'RÄ¡8®»p`E>!ùzÕ*÷m$¤X%Ì»ÍŒ'q·©Á,I3x»¦;Y¹VšöHÈ¢°ÀÈGƒîX &6ÁiÖ’U–ìÕš7)c½™ñ¸¢ aMœ•&ÙX
GifV	Ñÿ8=º§ıç·dİ-ÃìÇ'
ûê   ’ÉE¥DÅl ƒ¶€ÀqáÈ±Ägû    YZ