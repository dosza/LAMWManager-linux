#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="3156683565"
MD5="40d679fba4cad7fe717bb6cbad9b0ee4"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="23232"
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
	echo Date of packaging: Tue Jul 27 16:28:50 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌáßÿZ}] ¼}•À1Dd]‡Á›PætİD÷½~9«i²­(iMÏÎ1Œs÷‘æçv<ğ6zBÍ>—ò0XòL_2è“¶TwÕ=-÷?´*¶™—VšNÌ9ƒnb
›Õj–GºØtGãŠ"!Ï'¤;¦İ–K¤"*ÊyP
±5 }˜8¶Â<öKM+d¹ÄINš4İÛ Ô]İxÇ‡‹u¸ B¦gW{æª¹Ò6Ğ±´	èº´…•‘Â¥Ê£^IèL#ÔV1¿Š‹Njƒ/‚]s@[¸@zİºl4,=dö'†–-@‹UªR‹•—[nÒ¨Ğo>ÿT†ëõ4Ü?¾æ½I–>FÍŞiU%Tš‚˜¸WªÆ§Üå7ËìİŠÜCRíVÕ·KéXK)Ùa$€o,ÂÀ‡†è-MîÿX‹P{zF›¾º–6‡ó„µ‡!|bßše"çË0Úõ6}ä¶gìY‚hB$% Š”¼œë UXdn>–“ 5HŒ ˜õšKM8lNÁŞ>W,š\q½Ë³v…Lv ö ã£aõïâgÍ"ÓÀó” İÊ…úğìi 1KNæ{EÆÅSXF}K[ŠmÑÛòşûú¼ê±"^D‡T9&Fts‡|®ù˜«^¸Ë”èùñDe…6IoşSÀ!Ÿõã¢ú3d[£JI·|ˆıòL³ÿª"/")oBªéoúöœô/©0¬\œ¼Ÿßú™_/ôVà]I÷¹ÿ¥|]Á„½°ÿ@ºOò'9@îuÿ¿±§ó/ 1™6·{«N·ÿÊç§£eÌ0DÙxm{i\UÖLY€ü‘‚œÅ<p°<ŸÉ%Ÿ\Öøñ•™œ?~^_s³yä ÑHéq‘
a+™iÄAöY‚æQ¬-ƒ“0±ü"­ˆAÎ‰L+‹ï•áU‚s_áI§éØèwoßéü	Ç·Xõ]EP'Šá×I#X™ÚûÕ?Ò_JµŠş^5£:–	3ZßƒßFû»•$ŸŸö]ÅNâ€móGº·`ÿîÎ™BÖA=Hí*ÉÈ×d/nd¢Ñú“”4’hÿOëÁÀ·ûd}w‹ÜªÔ%ÏL‹t»ƒÎGµaÂnç°"x¾í„£K‘aO”ÎÜJ¨kÁwUÉß(\Î¥Ÿ&şúç®ï.É$Úyîğ¸øxÅ&°!“Fä…@.‰i7ßë_Õ¤5{,ÃûşRItH–<§Ä™èó„÷˜AG1l„`èÒ”ËÂ¦¹ûÎ2Ûx¦*"“<Á‹ÅÒåA¸7ó¯óşãbı*ª'/ôñgôÆ\7o–nü~Ééoœ‰Uú$Üo™^?Émc©‹«£¥SLÒ$Üø­“ÃÇOÁ;²ÌÁ6§¿§dÔéÆºF³B›m¡]ŸõÄßV„1*ã¿ŒíÕı^z!êâ“ÓíĞxY®qà2¼+mç¬0À®‚pã¿#ÊİÕŒnÇ¦*Ø]+Ï6|«û±`ï}›#©öØ"ãûe·éVËé|“£ê_RUyÙÿDJQÂŠL²èãŸÇÕSØ:¥€¢ø;ñYì¤Ó_ëéLš"u©ã3n¹9—ÒXğ/:#¶·qÊ¢ÖLXİóEL3e3#Uzğ@¤,bÓ[şmsœT)µ”Ã
5>òûa&ºypq_†—æo0€“ÄL%yËKxˆ—¨Ù%e±PO+¶š_a~Ÿ«ÅËpã!DY÷øBãÆS\[éÁ@5¦ÑÛ•e'DLÂK"'pØTØQê‚I‘{rÍ*b¢EùÅ"qÌe|×›NnùÂXÏILíS;YCZ¹Ò%°ß³`)…‡ÂnÓüÜùŸN8ı?€k@kï]8n€fÓòğRp8ä-k»~VEè¸nwf(vL¯c[K®¤Á!´RÂ »^ åNÕspŒ2p
~¼æ)W°ŠŒ‹m1¯Õ
'pT„Ÿ,
]t"•XH"óéÃo:›³µJEâiÅLptnuû‰°zOâ«ñVtA>"Ø({º1ßJ¸në!ï´©&?šl%á—s„Ğ=Fœ±\³BÔØÏÖÚ]_>Kş{ê„s¶4‡şàÍ¼GÎ NÁ‰Ò3°ÑHdP›­)'È¾ú ñ»æ~cWK‡ûè¼_ûÉÌóN9?	¼(å±‚D¦x¿‚%—éç}ê¦<lX“&Ëepõùµé—örjMnÔÜFc8MØøéwç:jz[ğ¥o{’ÓÏâó¢ïU©m|±Á“VÔœŞk.D~pøªşš.\Ş‘04•(¯×q€iº:W§È¬´ØYr³˜:â—iO“cyÈdÉqm¹ª<Ûô
Ï·='­!Ëˆ»L¯ÿöÇÆÂË*±ĞúvîX]BØÀ÷ç…'l*ŞE[dÈtñü¨ÉgSŒ&fh¤V˜&nÓcÀVmL4#Ï•¶,Ll5¬°K’•HPi†>‡½]V†2»Íc^7^­MPà¡K| £œñÆ¥“…èÓM+÷Üa´1ÔÆãÖêŒPfŠZ[é­ğÚ´MÀLn«/¯ìpdÛÀko3oi®ŒiJôñe÷XƒhïÁ¬}Syúƒ-!}Î¨%ÑŒ©ö1Õ`+à?úò17"ûïİ¾šv÷/éj•±Cí„@9
Rë|)ÕÚÒº¢õö”í¿Lé]	a‰¢'‡Jh¤‰Ha£îÁşñ&Ë=–ªC'Ğ ²tP¿
#º7nÆuAºº-3öÙÚW/,Œ«(`˜WïZ2İ_òqÿù…M	4]e”ƒ+ò7Æğö×V½Cu)PÊ´4»¼cœö[øh¼ÜøŸ(ïwİC)ôGZÿD‹@Ä“‡Q‚ó›NRñ›¹*Ú4Oér@$ £+»¢@	U¡?`«NxÂ(•Èfº[m82 aÍõŠ…OjBVÍD76ÏZã#>ÎaÜF”zª"ŞŸxºy¶¤ °‚%ríNÖRiiap•¦¢ç®dç« Æ¡6‘&õpƒi-FÏ¡‚58‡à¯Î¶4ĞšDq<Ò'J$ªc`èw×ÕÈ£4%¦Ïõ!q¸¿—¤–£„¥V	Ó°2å|=!*º9ó‹TQ¡‘{¶HNğH,	:\ÑÁkôwušmQjĞ%Xjêèíšƒ-«jïEp"Pé1KÂstáê9S¨W.××]Ú4œ:±n‡øØ»~Íå/‹úKD|l~ïoˆ€Ñåı%µŒGÆoIİ¹©–Ã&™ğCyH~¯à-ò&™¥aËÏMÏÊçB€ºXæÆëÎö^}ãÇ?(‘LcxŒ
ş‘®.-©îãa2«ŞØAİÔy0NÍ—l×€>3)µ ÙVHè‰—?Ë[…¬\u>ó¢§Ò¾N1èù«úÁÃé¶Œóı61Ê)#u¦Tm|“'8#4õXÓŒšØâ´C—K‚Ø§Áé–Å]FBYIº¦¡‹ìpÃgá›á{òÙŞjÚİÜ&åG.|%cöD	¬Çp×6”pn²GoÏ`zù=¬yì«WÜ¢–…B«¥ŒÈµM)^.T÷^L7ºÕñtœšv¨äÁ.˜È97¹•Y°CFİ}Ê[šKQHJ|‚£Æ®RïC#{D•ÈñÈóë¥ ¬\¿—t_\Ûq D‡ÂX–ê
!‚¢£ÁÚ'dV©?³ã‹…KÕxÍkHÄÇ2[´šêR}úƒ)!šı¤ÿî­Ÿ;"xCäÆT Pv× 1V&.å®B÷iÎ3r]ßï:w³}etÅ	FÙ™ŸÓ¤}ró2“D<ê4«8R¦ø¡-—ñ\ŠrO¼ÍÏ» /dXœ£³íËKû±"|Heb¥´ı•¡‚€e.3	Yó”\X¬,™Ø8Á5®»~·àbúQ[»üØô¶'ûÜÎlí‘ I3t8Rƒó=‰Hùæ=“Û´wT×ˆèÄcæ¤C=XmüîuN[f²$ÿõ©=kJ¥GÅò©µ¡ˆavp×ÂmgÄOyÙ5¤àQêÑïÚçÀÕ²«Â õÊW´†_y u\	edFm—E¯ÿÈ/M†kÎÇŠe¤œ¢ãOGC=öAhRÃ(¸E¦–0ôË¤Ìjl=ïDYS­õ+YªR%«áÌ$d ³Éc/õg›SS¿L—ñ¥>u;‡Ñ¢«¨i@õ®¸€¾#mzõ¿\…6±#üâ´9|cµİjÙ<åcû4]Æ"3B‹æj2VÅëš.ñ€Z‡ã@ndÈ±>„j.òœYòdËíA‹±ìİ*tœ`êÕ"RäÖ2ÊÔ2›@BËßç.››P9øE½áËsŞéÜ3güe¯]×íMµ’h-"«Ïó…ì~ÎbšÈ7ÙtîØe³-²ş?ºŞ;Iûp?¿rÄX#²y6á¹ùb“Å³âÙ°..´èú„AìGDP‡y‹»ˆËhŸã8.jã	±ƒ‹¬ºé€ì+-¿ûVe•zAôGÔ+ré=˜ÃXôÒ"²ŠEÍoË&¼ºÒÒÍ&bÕA@@4Ú`‹Yÿø)öV½ïyvW±Â¡¤!:Xk£ÚJ{bêIÀ‹+ìØ,c÷Îş›š%Q‡8ÔG{æCº[\3ãŸE=„ùÅ„’ş¯	†‡‡<7^è$|1!Â\œa=$­W¼kcòÌ¨ \M`»kW¼g¬ÜÍ¤±TaÆü&¹Ö	'>ë/á”™ Öa¡Ï±»["ÛÖ$SÁîyÂïî]m •7Ò¥Í›ıP=Dà¹şíY¶CËœ?:¬2[–anœhét©‚†L¡©œã¹hgiiV*gøè­~ÍRÅ®£ÌœÌ¨ğ,şvsiQî4©Šë^{I,;ïÂ3Á$8Ü)åü"Îş¶Û×M}–<ê3Âò#P#)Q×Ó˜‰pj£UÆĞæk”pi†uyIƒ–º=š2\(m3Û™’ı(Ø3ĞÉ®M	B{îÖÂô²3?†¡Ú%œòÊ¿YwİîGˆ¨føt@èÈeh›]Éµ^ÈÃ;ì w^»‚\@7%é|µ^gÆ N°# ÙY@•E–çm4ÙbëIsa7g¥4¤U‡pˆd‚™[ê¬SÙ5
‡ïZœDSÜRe:	’H’Ö¾Ypæq“HĞõO!ÄêLlæj>kneyF
İæ-¯0•Òc‰TÊ[§ÒZğŞ0òSÓAÆÀW)K8>$>Z1 ›,8–¹9£wo÷°û	Û½×Ò²ÚØZ¹¯rÌõl‘Æá¾æ£Ÿ£¸R‰PğJBîƒÏu—y.]zºÕ)“ú€ĞNÏ 	2å^‘8ÌÕÛ|ón(ë†	ÛEÉb['Û±xÌjçèn%?7ÅRñÈt*²û®°³´m~Ê'?Vğ/@y&«Ï´ó¿Ê³€¯HqŠû3ŸëÔíÔ Å*ì­FÙÖŒ>ä¡¬!f]Á_"èõ6Ü‚\G:F}Òw‹Ë`AC7Ôª»O½:i@©Ÿ· >²Ä‹îy<J¹yvçµ¯[¬-\	´†l/à&ù­ØH„•Å×|D¢¡/SiûF…UW/ŞvÛO…ÖU~}ñtuËjMdÆ£œ<H=fÄ»õS{Æ”$ÌøI˜²qŒE¥‚‰ó>õb‚K"ÁÃ1!§–zKñƒ	íÍÎû^HÜÕÌ2û”g{9è¨—á¾İv¸P&/DXz’è
æšo a/„W¿j:ó!Ã:¥_Š,¦×HsÎÍoê#N½vÿš¥\4¶ôÊ}İ´²k>Òù<&T­jàè•$K«‰ã–t…zr%Ó@¥'¡ÍÃ7@/ ì=˜¥–qÖ=÷Ê<Œ],Ÿ}›ÎJî€ ‰İOùÆa\…Ó»¬Ï¿oÁÀ)í»^(ıJùªÊµÏÜ×ò_Vü §¨÷ (Zâ‰]L``ÉÖü|Ò™=¾‹d¬#¿Ü´µD¦Á«lÛÆzDaZ8-.^S°ÈdÉûó#ş3óO/µrâ¨BT´d¸¼xö‰¨8…Î¿mêölbuAâ#´=ÿÍŞ·ß—LñSP§ÄÓ?—pqV½k+ ÏãRSuß )`>—N I”R:€MPq^â×9¤##G­jV.Z}DeOã+¦ç€•¯ß€LÒ‰j´ßşÂ?c.2Ì´úø·/’¯G|Ğ©HY"O[ÊwsZ;ÉÃ&]¹®sO:åáv¬nÁåĞ÷ñfD×WäjËÈâº©‘òªoìhÄ‚û¾l#µL†ñYX´¶u³	Å³C;m¯C›è^’ô‰ŠáM#“pRİ3±!I_ÒÂ@ğx¾¬Ë¾ÛaF	QûËØ,uWa1Œ	"
@aÏ¾Û|AxH ­ÊZŞ;ÆN“¶üGAŞŒ oWşÀÿp™_r“/å0õæ|‡ÚXƒ…AîŞtmÍÊæ;É4í *9ÔØ4÷¤óéÛ`Wİ&:£/(©Ç5Å¹\<8>ÙR÷™›/ŸïZœHÆälXo‘&œÔƒ]k9õu(ìWNš¾J¢Ã^´^ié {÷;¢|ŒfJpò÷2ÃŸg‘.–å¿É—©)•¦‡šÄª»ÁxRÌ‹‰xFIb¦wv
ãÖ5¯à@Şé·}ùw]nx6Õ·ôzíİYë¼”43Ëü8ƒÿ Ã”‰|Ğ¶~`UŸ»c±î’3ÔN†Ê/Ä !ğ@ f¾˜
ì@R‘û‡ñBîx(½Â[ÙXW¦tırê-v!ÏdJÀìŒ•Q.ñ19ÏûZÚÔ Cö&	ªËdã¸üªŸ’§Eø¢¨ –µ§[Ï²GÖ®¡V×ÙÎ7xrh&»£ë!µ–±íz1‹+ÅsŸƒGgìÿoò¤Ôy"î¯¬ÓVô!ødƒÄ¹88Kè´D{‰×ÿ¸
~Äe³œ€…hRj"Xä’¬t°gÔù^z÷ßœ(Ó>ÁÒÍ®»À}hğhˆx¡šğ—kD&ã®nÌÎ§ßu|÷;9‰õ˜ÍÑ|ßGÊEÏ¨MıhÂÖ=ˆJt~Ş…®‚òT7yÛİÉN“÷2ë™<†Ağ'~?×œ­«8ŒõİNİ#Ñ¡r·ã„ÚÓ¿@ò#ç–7P¿(Y*$vr*Ê†¨¢qÃç?×.ÖâÜ
R(}ïÄ›l9±„¥úšü¢Ä½ºæÑ3Í $}¸~æp¡ˆ,ª¼i°¤èH9løzPô `úØ¨Qí%"EMÉğÑŒ>çA¥Lï%¯/àz)Xå%üd#q‡‘óÒ\wQ¿@ác›‘YVÃë
J7äÌ’¢bQ=!§ ié ,º3C‹weÏñ!ï0å:Wb¨Ã„§·¥üìì$e$Ä½„*F£Åã=è§ºôÙ	Î…ş Ôõ*ÀÑ<òâ‚“Ât·¾ƒöùAPäxˆÉÈcœ§^“‹zqÿíQ¶‘Ÿó74ş=ßşüLaç”,æ+ü4Œ¨•<¯	Sòè¶É6õ"ó† aıüÑ,ÿÁ°Zƒı80*Ä>i‚;&rtì‚Ì•0CaóŒû ëL+°CM°U¶¶ô	Ó=ûX&¡ÖOPè|:‚ŸÑ…X7–,ıb¿#xÂ>ñ¨‚D4tsŠÆÄµ’HÂÌŠk÷™pW4/`ÀÍ«1,HõË sµÇ›a1ø&}È—ĞóîaÓ®[«Mhºã7À/
6ş~;ˆI3 QjŠv*|wCq¶>wÙıÆ@g”°oå,ó§BŒ;}Z´Gİ'ş×pPÀWè’_ÃIÇ#¼?àãËsT!R‘ D¥Ê–ü
K]“0µ´çbÁ!®Æ]ó¤ïğ×rı‰cÔVôºÎu‘+oÌ»CÕt~ar3suK‡Ã®eY/ï¡SSxøttê¥Å$f=âÊYÿÑ0Ä÷†è¹åƒwî‘rp5C~[º°–n€>p–4ƒøOµ¨ÕØÂ	¥¾&ÅXÖµ˜:ÙîÁÈrmê'Õ‡Õ3Î´=)µhÓW†º> i(?ñT¯zA	!Ù}ê@ê	Ë¨´±‘’Œêãn‰à³ã„‡qc³ĞøÜ{÷N¥çH”¢§‚‡o˜m¥ŸÕ·.½'L‡©nü:€/–;ÉG@EˆŠ8°¥+ÿ™êéñ Â+í’ŠÓ”Šw(µ•ŞĞ<9Z½´ôN¾$a×èÄRòĞ0ì=m2	]z×›OËœzÿŞ°İÀœµdêX v)At\·‰'àWuğ	Øä-_¸#6À(`.&‘Ùƒ99C³…„şA+Z<Lİ—˜=ûPƒ2\ƒsñ,¹6^–¶9U[éœ)É¬İÕ­\>ş/\8 îEèã›,zÀ¸ŸPg5„®H‚,÷0 {[kÏF)è‰:jhiğns9Òã“6³§vµÜb£tĞGp‡Á3Gµë"<˜g®ûMF<øŸ‰d¤wÀŸrßó«¿ˆr¾Íb–]_Qƒ^œâå–ògLöZôŒÅ¨µvuzÂV‚:v²ËoU„ÌƒÉêÎàÏå©ÿ–´lu’KÊÒ›`9äÀ»ç$8ÚäËğ"e_âl9¢Ã»šÇ‚fôuUß²tfğa¥Oµr%¼£çxMyì‘…ñ®›­ŸßzúXÀUĞÜÀÒå†ZÇïW‡³R¿ƒH71ìx)1i3
TÕÓPAÑ…ˆª©!óÛIq¦O9Æ÷L|¾Šrù‘qºúİœ/şmÏœåZ²×†ÔxÙy“Í˜‘­«xråæÕLY¯Á ´¹åúRÿkñ0/XŒ[M×;Ò´/¥zå<ÑŒ‹ƒòUd”Ã‡Änİ:øü9Y­£İF‡Dbáp7 'İÄc9¤È‹înñûÀÈ\±¹."%wZ ,ÏüwV/ë\<zU«®ö„ PÌ·|8²ÌA¤´_İšD¥*£­â»ÌyªÒe$~é|BØ vµ<rŸ•h4¿›0P9Íİ©ìúóœ­I+’úŒqèPuêfó¯îğæQ2£ÄÑ‹uË–
¥“şXÜK#zAywğË8c¥êh\„Ùº<ÑŸ«G"6GèßÅƒ#wèÏc]’°•ğ{IÌ|$S„ÿŒ®?e|êÔİ7QßtN;3ÍiX¸A¹Sdã„ h<ÅœçAÖŞÛÃdIúív÷!(ÄœæÇ˜ÒX›‡PTGl9:àÏ"öŒôˆ@~¶ÈğP—»w ³^JoNÜ“Û“©ËˆrüÈa!ã	æ\ınpäl†ßša¸®TBˆìQ{öì[tI‡ë5Ú{iÖ\ˆÕz~“'; jÒ¦•ı±|ÄÄ1´şIBø%ôqì€6ä{ZvMõW-œ-ë!ñ3r¼n=}E‘êO‰5œƒDûíÚüE!§ÙG^éiÅS¥Â[Çôç+1ôšÈrÆìí H¬Ö]—ôPİàØ¬}°I¥Üjã9äüÆ›$jß‰şö…º’\,Hü‚F$Q¶c.Ş’dU_[î‘½y×.âr:«£·î‚sıHaÂ.áŠV¦1)	l¨ì,º›u4ôg…O(ÕÅ5Vµ2^(Éº¡ Ÿ^µW;ö† ÆP*?Pn÷©=
Ëñ{SJŸzÙxî—b N¬’ûÓÑôD—«›˜Á)Ø-vB¢ƒá%y˜IJ ô&çòPŸë³ÁG¹öŠ´˜ä!SÇ[¬¸äqs	|&I}ŒÈÖDivhyósuì'|{ÿ‡oE„*mØˆ-îÃ^òw¹ÎÇHÊïƒŠÖ8-'Y’F’5°ŸI®é‰¾/Q~aÂÎnXëvm»ÙlÚ'\ÇêæIäºº5Î|° Óu¡ÌÙ-Õ˜òÀ5˜_;!æŸ¢Ğ%À^}(ÄV“²D>àÿÂúñ—mä†^ÊØ=NÒ6¼Âµ•^aF^_¡>&†õbëPkŞ4rt’»f@ ®åÕ#ö£Ãâêº^DAº»¯&l¹ÈL<‰(cjÀ+çí_µí"Hv?d¦ímòêç€}UIDgX
JşBæß£hI×°Ë¡H—uå<8’½´‚-´Ò²ô7mä?6x„wÅ@‡eVØúÖöéú{‡­ß³éI)ÀÀEHø_HU©½MŠ R?„w¡HvŠöT6&Ç ÀT"ŸÛríl¡ÑÙWvªšz[2ºèõb;yÎ¢öñ:®¡^I—¦¿—·½!o†ÇË-öêÌíÒ©=¥4vå³=ø!å(|t5Dß·Ã!…]òt9óŒë`!¢ÎƒèzJ:Îjk¿êb÷GD¿Ø©Ä±´>M2ì!+È4øÅÄÔ¨@šÒ¦9+y›õê‡:÷[½aUŞ¿l®Ïwl6'œÜIÓ3c|€áòR#\ï1Ã|×²vP ÚŞÃÊ^ÒVÔ·…%#0¤•Óh+Àæ÷†^Gc˜¹A¹ÁùĞm°fÏÅU“ÓÖ“û¿4 ş'}b G¸?şg«J#âÈ@—:=ç¢¯pl%¢(¬Ì°İÑÅ;Ï¯!¦µxƒ™Õ®è¸yÕf£´C¤vNs^ÊÕüïVºí'ïÌ©Èü-e+7%X‚šûºjğR^?U^QÂªR0˜W\›ŠãJİú.Ÿ	œ_A.°¸IWê.¤²Cp¬G€SKòO‹hßêq*IÃô2¨†zJ‚ãC×N¾5â×´-¶
Ç…“<©ğ{k”`ùğİÆ±ß¨†ôT|
DÏ;ë·tšãšÎr¬@—Á$ÿBÀç{E´×’šÔ(²¡†$Q!TN»ˆ+¥¿ü@‹Ç Lõ!ú1Ô1²øuÎØ§kdÓéx˜òçêS9Dœ@ùb3-e;ĞS“ÍèÅ‘´¿ûÂIt¡ï{HÓ¼ê¾‡‰´á1Í„'¤îÂøM£­;éië”óü?x¶h…Úá¤xAÅšÎ_ø—ù=0(ä7F;v˜Ps9ŞY7oMÅûF^lß•¡ˆ,*«6J†åGÕÚÚŸ_J	w®ÄNí@ÅdÅ©_›Ñ²³AQô¥¯J›«×ä……%==	ª¡ùe-–;6/ŸÛúsè–2”ğ
QKw¾û	4ıb1èÈ¥™@²ã£„¨ı\µS£÷R§x¥s;Q›t³\o ˆú´øex¨b"ÔËÖeÎ£%*Ì	{ÅÃû¸Wæõ¿&ı?‹yı?`SÎw 9Ä²ŠÁ³z÷5¦úüAõeŠ˜ƒ£Ê‘Ü‰Q˜.ıÔ_»§WcÄàt¬‘Y#|Ÿ!é”h¡œY‘3^P/ïäuôiÃ¨’QÙÒ¥ß~Ò$–åÈ2İõVª>´Ù¦ªÚ½xJÊ„lö.^vw.èõó[&İºô—«ÍBÅˆµLıñ|4€ÄÃmÙ¡&c&×2şc^_áS1(îe'.sd*d\;øì]Sı]æt”iJ¬OË3—úDké€¸’gl±{dÎ8”3£¡Ó‘Ã®`Lä÷"c	?¶c˜Ìah¡>rtñdp~äûû9İB*ÍY¢r7¨%‡6¼vøÇ8pµêw ‚«/í®­l¬TÒo!Üc²xªÀé•ILbºÈç,Ê,½ù<êÀê–›‚ªÿ˜Ë#E+T~¶®va¼èn–ÿääV2$=Í#
ÈgZcßyB$¿»Ã–Ü&|ÕšÚ?¾Ä&Ãõ½îh¨©V ¥UŸcæˆ=È>£1ñÉÛ÷Ú¹÷NP-t\4{éÛhöõ@3æOÖÕ·ÿ]Ö…—ˆ+5b…’~!-‘1ä¨™·kÏwÕ¿Jç9Ël!Ñ¿«0G[oÆÏ^6O9+š’‹ÿ^"îŠÂãûvÅŒù‰ĞäK[oÄm±A{øL\È%ÌÀÙ_ZÙ6÷•k­[ğKô¤Ôó(ñ<Kûnwœ%I¤‚©ôø• &0@v'Ñ©l”=˜ğ?“Ï”Ê· ÿÚÅàA³§‚š¶üÆ¤”€€ #R÷FYóõÇäTÃğ¤ºÆşÕ"ßäRÑ—í	% ÿÙ÷¦†Då}:³'ùZ<Áiµ&b2É¸Äiñy` çºü¹KÍ¢7'òñ5h°Hè)0íäÚÒpNQÙ«ëA;–}¨Za‡ÖTo+ã™@yÚŒhCÉıU™} íş¾È†ÜìÜ%ïƒ]ä^À¼jÌÏ¶ ·ú%5[;X±ø±`+W]Ÿzqı å`]
ÏP\›qİ% ÍRqä“`?(n"ô­ÚçÄ,ÉúdÍy\¨zÖ‡‰R8»º/Ü!'8«$ëT¥4*§Î­ÿ‡)¯é‘Ô–¦ÊW1³\JšKüe[üªÈØâÍ§éMø"‡NÃóÅfß±¿í»ö| IõJ€&öÂj]t¤¾G	^MG’ï8ÓÍÖ?l8~oÚ7ÏÂØözéŸ#ªÍ>È¨ÊØv#rK˜­wW¬×ÀÙeC1Aiº¾ü›åa]‚İê¼gã¡1)Íıİ_F±ÏíµÉ–×r:¬íf¯N?Øªq˜ñî;š£Sæîá¨²Ë¯%õ8ŞgŸ
fæ©8O$SOĞK.¾wÂiB¤=îÃÀUÃDJH ÕÁs©á‘ìÈ‰wÉWĞû
i&QÑ¸?İ¼ZëK­àü¥ùZ¢$İz–œ?é¸ëIı^)+ãºT…ò;^=PqgF¹W‹>_â9C«ÂSì2s_©Ó·Hf²î™•[ÊU¼Ö=—GHìò2ÒÄï¬<%{íÓósÌzlñÖŠ3RÁpt\ú==èoœ¢Ëóåˆ†Â§†u‰£O?Ù¯«µçÂ<¨T×ô©3ûY3îÇlû {kİŠçÕÊ:q{¤ËìçlMÛò7ÌêM Ş5.“i1†~\ç]©Y“¦õCc~¡_z6e±¨œWŠ€ÍQĞ–üÃ°ÚòÒ6L´0ôËó"-sÕä_ÖÃ{Ã,ç›B\(½üœê&{ˆŸ;Ë‘jvøîV$–´. ìšEµÙB/NlB wñf 7ÜŒÒ¿¼®²tÍ—<8ãÉÛ}‹$Ü9²¢2¬oBaÃ…u[N¢ÍúR	±„.Ş¤g@&ÀUMh—ıTÓ­ĞDfuŸ‚?Ãrê5<<•rÕ-HyLğ‰Pñİ;[J—ÏKãËàÖ‰?%½TPŠÚÏ¿ˆ_Ó÷M"V[z®DÍ2Ñmğç	7aÓ|$œëWÛ`¼CŞ«‘†á÷ÎÈ¢B1)
#˜åù~j\oÇİ–aZ÷5Ÿ3×ø$s^=û³¯ ¹rkÍÑ’›ˆïeTmâ¿êZ×`‡æ"2½wğ@Ö8³m ÙŒ)÷òAO€¡˜™8=‘ƒM˜`4§eæE¾+%¯µ€nÜ:R¤Í²p'¥f¨k’ÿq­âÊ/S["*5ö‘—‘à7ÀZœ¥uåô»‡ ®g´'®ô¼ÙrŸÁßÓwQ’Ã%ü¶­]ßt5ğ€Û£2
ÿ„\	lc‘Ï³oÙZ§b	‹Õ	¼,b46ÚÕpu^JjœêH#0÷× öY ¢æ0)ßÔ|FŒïªRàEWSj—i†åºölô\‘¹³•¤­n…h!6YÚîÈ¶ëêUì}3ù­Ÿoœ€|°Ÿ8¡â>ÌeXÒ?²ã©Ày…å]G]“™×®àazh¤Äª†ú€Çè6DFr;Ö?Š³wœ¡©œj÷Üš=]µ±“6¥›LíÉå@<‹3øK}æ·œHOrj«®Ö#%[‘a#Š­úWuSKäOù¾Ÿf…˜{ÎØÙMö¨>s«êÁÑËXÄ„à¿ï*'êEd?YmMï‰ïWÂïæu|æè 
&ó6AÛğv&CÔç’DÍ—noäØ©ÏH¹Ğ:½Î‡OD¼S7ÌaVM¢¦¼~Ì¶ K
NC-P/£âBÈ ‰ƒ¹ëãC&„9.&†Lôô'Ô×¹ÕfÂ*ğ„I 0”í¿Bt¿¨ù
ò}û†Ù!§‘¡I­lØRĞëµ´h^ ›×p¹©—@‘k2ğVX¢
¸I,U&ü½ñà¿®%£
íËŞ5ÈG¾ab”4¬=.”0MÓâ›¶\¨¢”áM{N12‚[uÿÆ„X{Eü­[ğ½ªcûm©¨0qÃÂû']}QU®#Ê–ô9×ø’L_Oé”İ.Vãªèa–U_gL?|(Å4™Â@–¿+Şîu?Ó1 `Ñ<Æ}~ÿø<á{|	úçÂnhñ@™Zj–Õå‘í”„Ê9ïÑÆÓ€5°ôQ>Éà·)òÆÎÓùGì¿Ï½’—R1§Ÿ™ÆTM&äGÃ¨ VÚ¼—pØqúR»@Ë7¼2¶½Ä¥	ñÉÁ„‹ŒÒ1~Ö®¿&#˜lL¯“zŠÒÒîóyßÇğæ1ük¼ìãeÉ*U¿ÔÃØğ#İúz÷ì˜Ô­Ù[÷ä+Óª'&‘ô-–D!_š2,‘‰A³áNxM¶JxùM=¦ÑN¾¨KÜêF¹à‰¼>ËÑ‹é•Qq´aìø+Y‰ÔùâÒ_âYêçøã’ÔÇB¹—±aŠjÊx4n	_{>î¯‹az.øîæº=<$»X"ƒÉnu`Ş3‘RçÑuÖSŠè¡²:fC|	-àuZQm·¢ãºBqğ¨å˜\QĞ‰‚ã‡•˜FzXXïß¥®yk¥V”AäÁl‚ìyTlÎÏİë||ßç~- +ï‘şnbáI§6Z›oÔvjÎ•?	T,­Ë¶B³”&´%²+{è0ï?¡£EsòäæeÒ¥{aù£b~@ir`p`¯ºÙFc‡ë å¡¶¼0¿‚ıİHw'€è½Gñ/â=³ñgÈ¶é¸İÇ¢
u˜À“CìÊıŒWÖRÇ`úE=šË5ÃNóã:)ç3TøÃLB`ÿ…Që¢1”&Œ»2:X™$–o@Ì?‰ÿßbu…‚Å€¸NFÀŠÕ>OØìY§¨«t™{°É¿ra™äĞ+Bô]Ø[—¤Éı'+mBSd4h#¼!Ñû›%—3WŒ
æı«üöÑú¾K`‹°7Â¹EE
Êé éÔ“«®«q(¼šó{´?úh¥E¶Ve¤zfÑ7ğô{O*‹5‚Á–æße;Z¿ü‰qÌ‡@îÑñû\@ÊÓ İÕiÒU»iÔ!.¬¨Fé-';Zaqq'3¯3µ>+ådìü×¦œ!Àx ¡ÑØ»L×ôtò®ÏÌİÑéùT8P°ÿ÷hÊB.¬,N0W’4-_İÜ:7…©tÀİ«Ü6ˆÑfƒP/wv9iÎº†¬¶Àq­	‘AC›.€ƒ3”ãl«d,* *öaò„‡–æz¯<€0İ¿ŒŠ¤çÕ9¯JĞË÷ğe¿D£s•#iÜá´å¼üœÅGˆtÇ˜Õs:eÀóÖèk3!V»(¬(pP”—Á÷€sc¡vÛrB¸¾wåÌX–„ ·¼lºÕ„s‚¥yF3;)q3	.®Á©ä(ãªõ®ã’Ïg3>dàZÉ©r˜Lm	£bş=ç¸Œä“€Ë Ò;ñ(³o&™”œq¹Ò)ş1íÒr˜ÊDÿO][Öî®SçGğ†İÁÀºÅ†ñ²£¨şâÿ_è·*Ö™°½ÿYâÏÇ3UzØ–È„S6VÂæp	ˆÃ]¾ƒ‹Ÿ{Ğ<aì÷gxVDcÑ«éĞ:3âJÒÖêVëHì¯¿
±CâøhÏ4 È‚?‘9N÷®œ­l˜“Í`b„YpÈºd,>uõ&ç8Ğú³ı/Z£Ğ?>B<¾fòCíóõá»p-TÎhïSëåÕ&!ñç”v±Å·'•U´îµ~ÒD^,€’û·çˆşKtJÄÚ©‰–2eŞ»c+&zFİñ‡Í¤"âŸ’õÀêey~Õ‡Ö±Qò‡™Aæ½ı¹ı¸k,%‘Œ±º-Z³‡ÿüKnÏMÅÇgjP€XJM±‡óÇWrXè«o2İÍÅâñRÖÍÌ"€òZtm;â`09\ú¡L—æk–ºV'ˆ«·2yéU]°ÌŸæ‚7ş”4_±Å)™@·ĞXíÙÃ`–Ò!	¾/Ètd'Æ=‰{--şƒÇÀA¬Œ‰D×¥KêÈ:Ã„67¯œ¼{•ÁÏÒåsvîú€ù&M7zÙŸ¨° 1ìÌk/ş6ô(–¨¢ÈK¾ÄGñÙ Š›&c"Zô %$Ÿt
ëz±€;Èıå<Ó{›¸¥Çi½¥|"Ÿ ù–'ìåØ‡×öğ×hGÌõ¾¬`$;¥¡p>f{rÊYL1°ƒl‘¥Ú¼ı³JÛùGà‰²U¶5ç¥¼ğ»KºêÄ‘)¹à}gúİ­ïÛÔC€pñL/o½¸X¦AøÔŞC¡8ô™\9“Éâ™Æå`Ôœ£ÃGz—P€î5øğEB×qÔB€½|vN›¿ç‘¹Äü¼¶Ë°Ôb´	 î<¡Æ½÷Òw0×Fg³²·È<>Çyr4EˆKÖ™­
{×uYèÎ›O6M–hD%Öy®½ß´l´±ªïàeÎıbÆŒëØlV´…¢)ëƒ5ÂÜûÔWicÑg»zÀè& Õ:³ÓD-zÀæ¼’["—†/wÿ øñğÁà:h;NóWe¢|ŒØÜğJÑpZ‹Ê#7€PŒËx®QË.m¶Ç¼5R@ô~ŒŸè¦>.¼5‘"ÂÜ€+˜ßÿÖ}@µh›Xë[sÎÕŞšCÃœ›ïˆ€ÓçàL¿·5£^CíÌ^Uı]ËŠ®#êQæv?t]E	¯x!ÿÓBT¥1jT{y¥ÌíWüçõÍ\{~-93ÒOÉèää•`¦ùİ¡MÓí…ozÆ_bü»? yZxÀÎ'êåsˆÈUu¦¨?f4M¼•P`•wÀò!%ZbÎÃgÁÀ.iw°Pj¢ç^ä—¥K´ğ­>Ñ~Õ"rn-j”0‚sˆåœÌ®&zœ¾æ²EÒŞ ““FR~c"9Ón±îÁO-kÓ¾L=»@âl­¼+lÁ± àù„z­u³-zfA9Qœ+dƒÅqõN›Å>ç¬¸ëÕ.:jæ+<QˆíË[À•ş?m4—êÅ¶Uy×u¸ŠÕÑnğú`tä2½ê(ºşu#Ò‰$ED[Ë-İ™½-Â¦4²ÓéeÁá ÷WV›¨†M M©s½]G’nïïB~§# Ï+e,8ş-ÎœÆ„6]ø8ÁRHsˆCC©ƒã*.ıï¦ÿ"É?a1!ŠD>Tïei@m%z¹à«da”Ev=ÁFä›wÂU»qùNªx@‹˜Ø¦À€ùÁÀ×PƒÖ¾[«Ÿ£_“–û,âÍ¸”Æe_Œ‹·Ò
@ÊbŠÊ­§õ`8~.ŠFµfçè²ıF`¼^~Ó>Æ›JÊ®Tú´V¦ÿ2¡˜w5D«ì×ÃñE´4ÙŒVór{»Û6ºØoÀoS„¨¯üõ8ºS>ÀŒdxú¡¦óœu#×õÈªµo†U0/z@µX’V )Fêç©ğå¡¬b~;p®<(nÔ*¯Äs2äï:¥½M¾äEa'ÉîËÈºÌÙ¾ó‚ô*+	èë'ôº›×Ò5%m»å²¿8íÿ¦ú…ò.„˜DYI˜|ÖºÊ<{I@ç/^ŸV˜¥†Za»ßİl+[ù/XÅ‘éÛKe["s2uWÀ­+EƒŸÌE Ï;ÚNĞï8ß:U·f‘´•’ª«û×ÌÈ<›U¿Ç½­†œ…Ä\Üøİô¼33İ­ç™ˆW’]MÙ,ã[l´\Çfm´ŒÇ]Ú~~®ˆTaşŒ®3ß¼Ú?CéûîÆëïÛ'ªâf	&O¥
OÒCI´ñ%Íôëâ*¾ĞØY1‡Ë1$Ã:•ßƒMj¾ø U°S„D2“†¬4öNÑÈT qÿ[r2›²Â¼Kk?Ilœ÷Åù¼÷¶+úË_ÅİKó¿Ÿtf‡I†)ÆM|{d 3xs„Gš•ãGèÀ™vRÁ¯9«Ìbinğ5š$'‡ñÄÏ?>Nw…5zähM$AIq'é¬çHnšeœ²o¬f4*}F]å‰\8îW$góhhƒÅá¼äÕb!†ágíÂŸe>¬éàµÉd÷½ÍS¼y¯Æ'gÇ–/g%¢áŒ§Ñªòõ ïÖzdıXPúÔHígRß-È¢rDø«‚«ğÀã’¦¹<õ§ÑÀ)çŒ-BY z¼½ål/xvÿrh§…ıOº‘ß"áç—“)5 =Ÿî_>ÕE‰‚Zg‰Äİ¿sÍu‡áY8Í/9ˆUz5f4jh.Éÿ§RØ fhXoÃáûrÍ•‹æ>W‹²\Aë8Î]e;ùÕ1àšßÎ“/3=9%‡ûø¡âLÁ ´(N¾wEV¡[ƒûFé§5ÃQÿæœkäİs«YÇ6îçzDlZºçòP¢ÜÏ	¾Ëa~»‰³ã½   ¢Z²é’«"j<¹¦ñMöSm™4•gĞË$4j«²>£.æxTñ~C{ç+Gió/×™MÄÍüí{~;Î%¡ˆ\ï6ògSĞS#d±ø •ÒGãåø˜3t^XÇ¿8a»y*pkİ;=¦@êx HÿİU }qûzb9¦“:;8‰*ö99èÜZÈGâÒhLq«#•.©uÁ:ÿ›b0­õøD¸È¦¹¯PÇÔükurVhSˆbó%JëÇã'=`ıÒı¨¤* ¹ë}>í‚¿ø|J)áuB9òÿZ4ªáe+†—ÏHeùÉ©¯Ğ8Çñ±¿Sä¿÷ùÂ–j¤‹ShRİÿZ~¹„ycùæd k5äæÜœ*œaôÿ oy&¾Ğ]R„³ã-¶˜mIll:æK•Í=Ã­ş0?Ïj³7Êôğv#HÏF¿v;1}ğ±pMg\(½şHu`"ò–;AjEœ©x@ü£€PE¡®“U\YÈÎM&j-1=F‹¢~IIlév´ïã*(;‰l¬Z¢YG™şØì;¬J-Tò‰Tƒş¶¥´şàÎbîHf_¸ãÜ¤û@Vß,Ûë°LògĞÍÃ¢Òµºf·’ºã-@ñû%Y85L2±5›ê¦Ò1.¬èN9IjhİÂEÒ¨}4~o/EÿøÛY‚5zğØÍÔ{ºM5·ZFèrD+e
îĞ#$Â»8b*Ã¥¬Š³Œ|vÏÅG×°Ú`àA&9¤òO·ÒOiÍ!`©=e…à÷?İÈã(]]yÉ“ZgN, Sš‹RR'2E“ålDPk!ÖiÒÿZãèe.¸Å€La§ùÙ¼í[òúÖƒÔJ´dëÖÍ·-ĞgÓKçf¿<=ÒîA.Oó«¿ Ú†JÕùĞë»ÄÑÙ1¯h{Ä†á»ù.…•ßX~4–À)¢Ì ­2à…N.íP’ùJIiö¥ 6™r İü®
‚‚Ùt•—Çlœ¾˜hÉ’¶D'™˜†¨ÆZÁ"ò© ¶ æHæìPêÇoÌ—ªy|\¡¤¹©HRì”sx»Ç#¾‹´Ì}W‰èÆÚo*Q«4Äz¡GÖY(_Î’–ıÿY±?U¯ùSÚu§©XMÇG!İqû2°–]Äà(Ç!ßh]°%©Ü<6Îâ.>•Òkè6fïEÉ ø“¶ìH15ƒëÛDÙŒ¬?èWzql])Ræ{© O®ã¼€çRÈ­çÚVcoğÎÿØçì]~òN£†µ*%¿¿åšr—tEyştË –·(ßÿ_ó·­<Çq~gC®My4ıUOTÜˆ¶{ìErI«9†ôé°s_C’˜¾æ†UÕ!ì'›oyºF¾â —‚ûY]éêò¯ób	°×·k1ÕªÍímïs¥cgƒp“İ·m‡òœvCç aóŸ/’PŸ8Ûo«ã=i©nšd×ş[ß Y”•4%õóE}ˆ¸ğšmˆ@óˆ¥I©²1ôµ4¶
X©Ä÷ph´$0
~çŞ¹nÃTÁTĞ1ƒª ¬&¯zÛÂv$Úªˆ›örhJ¯QÈ.6…èˆÑ/ëŠKÂıi+ä#ÄÈÅ¬u™:ºñ$#Ê¼>«ü%Í»áw¨şãMóñõ\á6%Ç¤#ZäpJ¾°xÁ?©•!Â`k¯+6ş0fÍñd=´{j¦¯UÙ”9ôÚB+3tãÂX¬]‘Í]ÔhaUàÈÀÏÊ›„	zhƒ-Ö6Ç‹Uÿ==NıÎŸYÙñ’.úLi"Ô“¼Ï&5Xáp0Ò#xKeÈ¾31Iÿzù‘à9ÏŸ™”KsJ‘°ø·>%4ñZPi7x3øï²¸2““œx}ü÷‚ÃşÉ@'£9Xf®·ùâ™9Ğ,azö–Ë„^€/Vµ-bÎ’Q¿8	7ÛãPwİZËTP·Ï òéòn˜İ'ÑQ(øyšv]t¨¾½¾¹˜‡8‰]×’ıfğıÎÄµ¯GÒ{¦¼Ôl¬ŸöB[f¶o¹Ñ~³ÓúA;½eboô—wÎG"Ù¶<¢Å÷8<t„bÉSêÈ¦®*=LàÁ'(ÏŠqjØáF"=¯¬şæâWò6¹üŞ4¼Ğ£gÈ
}œ¦Ç&å<ç×À°ğ£Ã#(Îkƒˆ•©‘yë(#¿—ñiƒ»pÉëe¦3íÁ†;CğóÒºü¾…áŒliÌâXRYP±+Bf »üE[Fû¼Z‰{cè\Üc((bªC´c/Û	üjğ‰GCê§w.«õñ±bŞ dü)*ñ»µy”RlôÛC½/NyÃ 3Ü³fqøù›Y±Ü·»*9¢Ğ<3[Iñ¬Ğï= ;¡<ªLÜ€’>åd¼å»vl¦Š‹ë6ĞLIéGë0NÈ]JbUmŒ¬ŠYú2àÚû9”êï‚»wqÎ?²
Côñÿµ³8¿©Wú’+Ç[Å]á‚ºÌW¬ÖğL;ƒ‘–úøeı<WÛ|¿¯¼š×¯¶ÿëşûIñŸXQEi›¨ MVmôa•|Š*ôó_Xp“²Mò&ÎŠÿZZ´¥SÄ˜±Wëõ?X¿çÕšjŸ^]¨í±ŠA:³`ë}n°À)Hšp¼Ñè“+ÏÉMIR‹ĞÆ¼L‘È¥]³æpáéœĞC ÀfV×—aU²^p-e¥`u„L(á<ß=æİ ÍÍQä¿”­yN ÆRšo©Q?ÌĞ-
9H®PĞã!sçë*5 4%u÷ŠLòİ¦Xéú<`Lç2ìo`PZi	šÒ)ŸDåõ°Ãƒ×öO[˜™ë‘GÔm®6¡è5<QÓƒš)œ4jò)Ø[Æ0^ÜàZ7V9\ì1HÛUÜËqQÈ%>‰ÉÚ»V™UÄGú  ˆDÚWÖù2¥3‘a¹FtóÖØûØ}§j­İ™45*¶7tŒZÕDÂä¼6ïq<»›¥²wn6r¨Ñò›>—Æğ®Ü†1¾Fù1å®¥±˜íJ‰™F
}»9îz0¢-ÏKB7öCà´ü²İŞT}û»…rÚ¿Ú‚=,ÃÛáhşC74|~l0uñ›8‰u|,âX`™Ã/­lP'ÙÂAE¿ÎšoEÎÚ'miƒ¶Ë±ÖÁ% zCj½¬Cƒ‘W%®j)¹y¦á…n¢³§é‡dû™ío®¡!1v%_ÜÒj5;° #¤¤N•÷Hšõ fÁe:Tîüê`åZ¸‰A{,øiÉOÀøyz`ìFñ´™‚/]äzXÕXT®Öv÷®Ç”œÄ½ëRtõá¶õâ.hHí×+1>1Ëñ\^(»tbnçŸ®çîjØÍ{n
IçÈœœÌAÔÏÍû¢¡€Â5	÷Â½%±Vùaz°8ßô.mÊ‰pç%ÖÙ=:3–b÷P2²3¦Yèºÿ^+½%ûˆ²1¨˜v¥Ê÷xíİ…zt>7®ˆôÂ•3Ã´/o³Ô‰ª_Œïí…6¶&9­âÅØ?tÒ×ErÿµCÇŞt¡şÌWşœ(Ü(³l3ˆÔ¨„«dÔ&ÑB6à«æ?XöB$ÿ€Šè`öÚ}C‡ğº.¯ÁUÀ$ÅzÚGw¼«ƒl·9;ã×Ğ$¬;‚(R«Õ½¦Ş-N:ùAÈC©g¨Y˜…K*ş÷ó¯¤á#!·ÿ;”8’Û‰™e$¿¨W¶B©*ÿÓ£ªƒò–¦ÇJ«¸m­\ˆ=_4ú„ºx€ì^ºi3‰7è(ömÑiR	a@ÏL=÷e¬ÎŠÔ>$à¯¶}¸1÷VV?$rÉœÕC¼Æ2bûæ0JjY¡–j½èõ‹ªa”±gS'SebğòÁ¡o6_-Û.£vz¬nq Ï5KÌï»ÏYä`Ï5~«çw°ši¸k™¥Ç
©S‡ÜÎØB+×–Œˆ®8·…qÈ{•zDt?éé?¨TÌmof&Øhëí–İ#±5OãšÇ@y3â)PÖõŒ¤_…	{¶“Éd¢¹rÕ ŞÛäÕ‘Ë’‡GûÎˆËæCŒ¤ç·/@ú½–/}|¬BOUØ|A _°p}®$³JƒÓ2V¨]Ö÷O%1ª§ìØ´0çz´½	zòıwıˆÇuäötÙFö¥cÕ‚ª8FYDÊú½1§×7\°‰ydL‰-ş[ |ÓY½xyF´T§ÙW‹ƒh™ŠXOÒ/q.ÊÈĞŠ¤À¼>fbaÄ#»û"æb2n»üC×Ä¼&Azáó¢üÉÚµZ«;5‡DÔÁ€ª¾òNdRLéóö7A‡_‰D±V‘öŠT´³SÔ&të´Äºvá¹7ÀÑÓ8ßÖlfŠTs"Áhós ÕnÚ=(Ëö¦Ë¨Fì¿2Ã0Œ†™ºa´‚ÀË²šÿ=£|nÈ¯¢@ñe¾ÒwqAF¸;wÌSğµ]¹ÔÑhÛâ–,\Û®R5²‚^[+ÈàÀOè{8Ğ}O…'ƒÄö
í6 ¯­Óê€™ñÖn#§ÂeŸíy™	 (Åú2<ËÏ²Â9›KQ+¼K“Xûšğ,’^×ß$·c­Ùp ¿«DhMZ|/®†nµG´Ng;e:;J–˜fcqâUCô¯/6i
#ÔôÆĞŞçÉöF †š½h¥7Åã¹@›Àwï:›ŠêIqŠäq’BJìò
Òş Lñ?<è4Vâ}şıû‰}B»¹4Š0÷{™ĞıÇ¢MD:ÜŸöZÛïF²mNMô™†z˜<zzâ†;ù.2åTPâŒ˜&§¶}†µ°ÿL*?»ñƒíÉé”©ƒà´ºâØéôAü®vÖ‹»“1—	n"şØL##3w Àê—\çÙ›xM(3%ÖÃ=›Õòä<â÷w(^ÉúÄx@t;kâ¼÷à;â;¶€‘–ñÇ¹HcQEs/–S9.‹Ø@¶Õ	øÓ5²5s›zYÀW´ŸªŞÕ|ŞQ»däàÎÇ kïu4)¬{ÉÄÂÒ(ˆîÇöD(È?Ô_iY›š ¿Û,/ *ğ_cbÆvpñˆõ34<.R&&CØ à~ê6ÕtM™©Tiêg~b€¶Nİ»AÕØÕ5¢ê.åÜÔ~MÅ“4héÚ2)=B$ Z¯öµŒŠ¢$&CµwÑÈ¡sëüN\Õp%|ª@!b¤aÿœ ,ÊvŞ¦²g–ˆĞ=–{Şs[pÒ ›Ù“£€½j!M¬Ú;0_J(ÈøG‹oXãI&=ßí…»X{!Àì»Ò¼9gãä*)ô…˜›„^/Ã½Jh›/À«ˆâozV˜oáL­—[po÷•MR†Î‘L$¸mú…nÈ`ëöÆ*’ÆJR†t“†¬5cIÙ¤]â4X;0ı;¹ˆëßŞµòş’rbâ’•úkØkŒû¤îÏôVSšë…
÷!¶7yçT_–ë?¡“B¢úeóƒ““Œ°ãò!W©æœnÏ³ Y?ã`Œ;Ãµc†^"XÒ5<8#Ğ.l§Yk§¦ÿàğØúhCg,1øªRïsªñıæÁ<påïÍ»ä"ê\tÂÒLJuÜ¤·SUö¸«<0®”jµzEéVŒ_ÛüWşë(¡ğÌj3Î”& Hä3?z/i 8hVx~ÙË˜¬ga‚ñŠ F¦À)y\Ğ,ØŞÒ®É2Y<Áü>‘àFuZo¥’5îÎÆõ«~ÂÏŒ¯°ï­èşR+tpÅxÓæ÷ŸÅ}9Ó;Î^ù
qèW9, áşT5‹œ2HËÂÆœë"6Ù#‚šs‚k÷9Ö”ÉUäfØºQ+:FŒó–Ğàª ¿fªZ]dãQA¼„Åa½#ªÂ¯@ïL‘ËBğ®œ›t-zé““ÃÎ„yVX¾¥3KyfE°Í;rP8ˆÌÉ	éË<¡¢••L”àõAí•?±Ätå8D‹~K¾,%}µÔø‘â·JOÌ "ÂÍ>†6‘&jUû!íF6×q±U÷¬w?=Ú]nHØ©˜ñ¿„ò‡ã	—2‡?I ÊÃ´ø8=@ùõnÃPZé½-çÖïëüiïÊ~1Ôz¡R}Î*:¾×£œÛ×.qCF˜äQáÙñÛ†L
—Åmòİ-İİŸWºå0±e5»­@ódå[Zœ-Q‰ù®Ytú¼¬Õ4Å^+w"~ê§ag¬tåôÁlŠ;òÓ’¬>ÖDqdõeÖ$Åşal§²])\:{^UÅïub~Şi¨‘‹•'“aİTl²|É8ëÖ}R·YoÃ‡ÔkÌ©&ĞÚ™Å¿WSH€æö°Ãş1„›”D”s„FL“&,E°¸‹U+Œ\9 +24G°Oy£
.e½ìH„F›=Pß¡ä¯ı¥@­(*!"‘Ã¬ƒÉï®F‡\`kõîÉyÃÕÎ}mïi¶HNlò?STMM»<7Ÿ– 	€/ºb4u>ó…ÙíÌóf*×ÿpëÎ{Ãi	zO.­òxRcS¥Y‹Ç“ıÙ —Hİ“e¶SHµÄuEµIpÒ¾Ô#¥~%"şR¬ºÓ¨–ÎèµÁ?E®kÏÿ©tŒhş‚Üœ©Í½f×¶çT½qÍËü`Ikµ®U.N“ËÈøûÇøTç‹C0qc0gô2…ßZp‰'¸{õÏW•¿ŸÂf=[ˆ, Ìşª™Ì«,¢ÕÜà£‘´QŸJÈ¬+ÈËêcş¶Eƒw«wÍsÂğoZQí¸ *ndA3buLÓ›§?1×Ë6RVi´ó…C;äÊ#›]GJ%Ïu íÆf~ïC{(Õvà…)W!x®‘VÈÌÅSêæO‰®Æ¸wëÑÚhÔñ^Fûénùñİo`JÈûë<P,v0ú^66ñ(mÆ–×RN$ƒú¥2Š«’9lù²0ÌØár‚s;Fğ¾¡#ÉU k|j'$£Ÿß^@8»‰smWË)´o#`ÛŒÅˆÀÓV .·\•D'ß|­™ CapÀ®C˜‡ry#µU©ï]w´|q™êKAR+ÜQ¸›ıÎåßî¹TóªY?ahõËáëĞä×;ó’ÏÀêÌ
1ôì®«Õ•ÿlJ4ÄS@äq¨=¨ê&U?ÈÒA#_
ó/%‡ßCÂbIìáuõŞ1{vçi¯EÆ¤.Áµ¢AÕh•ÆKÌXu‰Aœ¦àiÜò=\¸³°öñ€ÀúQuK²kS)Ú>*òV!®Á8¡neÒ|$»—.$÷‡}c0™AµløÄ—Íµié™Wzù#,ÂÊ>ïIö±‘Á¢Œ1ˆı{Á½–˜[$wMŸ.µ‰>šİÿ:i´JâQAJ7çŠH›¸:H_Ÿø:ÎñgÔCÚcßóš~#ğ(’ $³‰ÂQñ9§ OÜ”˜‹i¶êR®q•2q2·şU“ûª<~ğ#Q¸l{”ÄV1ß /òÇmõÇXrñY¼õĞNãÀô•$}ZQø"Íq5½øÛÌ‚;kË]ªXi!æ­4
€$§‡#»±Ï¢mÁK¸‰fösª`UtGÒå¥Å•Ê qÂ ¹ÓŞ$€á›:_mº¤Ü¦v³Òä‹Eôä $t¦DY.-_…_¨3Ó3–ÃƒÇY÷r±}ŸZ­IÚUHLš‰S• A6¥+Ü_ñpFmtûˆKÿHeİİ˜’vÏwfdÊx\ôùŒm3wõ?ìÅ"ãÅi¤ß± ·°	qš•ÜÒe1&ôíY2[ó¬‰IÏ¦9Şl3Gpr,c–›„OvÒÑ¹"¶ª<÷ü°¬Öhdß0úôÙ²‹$*mU2`šW:Ë¥s÷³M`RÃ><XÑ8y]$ +–}mAŞCy}…Ë“şû@ÀşõJ gäˆk0ä¦÷ÈÑYìóíÔ¡»†/ÂY½òÖÚa?&†Å8H	·h &áŸh;³Á‹‡t¨ø9jä³î“ÚúÙÃ¿†ô³Ÿ}xj;/WWÎkb9
Æ€Ã â[«½{¤.iiŠ¬¹jñØ‘ú‚ˆaÎÜ£„ë¼ˆ>à´ê£‚ -°<àÅ­Ã–f$gı¹hôQ/Â+LAk³ªrã>ã:Ş¥UÈ'¯l¦Ûd w³Ëç'Ë¾Ú#ÿdT¯ÄÎÿua! ¾Q	gVİ–òTD‡	†°I:¥ñ–¬œ€Á„¹ı)“¥y…ŒFŒ^›Öi”{ş¸‘¡Šÿ…«Ğ#&_åÀöJ¦tAµ€ %êËû|½ O2½úŠWl€ê J>A%¢bøf%Í™Z7|¢†,?ƒ	.íÛ“{§p¸«œKÿ`$téûX_ep@íµÃzK@~É2 ù³+4R_«?lÅ) ÈCA9ªÖ¥)ìa/PÒG‡ù—g.®m´RÇ®|KŸn-nì©7\`rqà_“Ó¦P(ÓQ}1"İ^u0AÙJnëi¨¶ 8-ØØ½ÇÖò({ÍK_Ïã rÜXD3c0q7[C‹_ö¤·¨2ıNJ¹^‚Í2õôø‘ñ8?ÓcúÜIÍBB5Ó[¸†ú¸Ró0$Ô%ˆ–
®gï:ä#ùÔñÔÓ&D—p'ôÃ‡V€Á Õfa[	ùõ»6Lád¤Ej%%Õd×¬Õ/³Yù>İ@n#¤¼xæB^ùh>ÚB™ˆÛÒ×oî íPè?P‡ÚÕÛMáL™3‚P¯)÷~T…]Zª†´E] ·,@Z÷5Ç›_îü™=M¡Ç1d}Yv÷fì›ça¶$'¸ÄÌŸ0EZ„_7pxö×ı8VïùôÉP’$@½u…ƒ;',<Ã=iÕ8³âCBƒùU*Nhm÷~=Íz/ á—.ŸBLú2â?2ßŸê<µˆ_½£¹;ßäEÄ„1aŸÛ’yÿóğ¿²€ı±bFQQ(¢%à‹Ò0Oà§‹ÉãSÊ k ë›•jzâGX\gé¶ÏÄ?3X
:0ÇI  ¿Ñ©É^ñ;4ìGÕË3kÎI]o—Ì0";Åö)ªÔgCïr .wøü•Âa+ŠË²ˆV)QB÷ÑLÃß¥5pŸáR?Dˆ¶!nÊ¤ı:Üô‚V*¶õ¬¼Ÿ~Éo¦­yK<>D^{kZë¢VºÌÉä¡òoNÁz"È&³Á´)¦˜& Ö˜Á[Ò]fÔŠ¶²å§µT•nÁ/_òÚªÕƒĞßÍ>#lç:ğ!Ÿ×NhŒo	©³|sÖM"ƒ¶véŠ#Ø¤6Ù;íºB,å”¦ôÆI&Œù·¶çE|¢©ÛL]=¥g@Eó]Ó7z¬õ‚Ê,‡U{Ì9İ_¨†	”arf\R)²(®œ¹£[ÿ¶‚»È‹â2•ôújFP×(§˜Ñ§³Ö•3æÆÍ_uLSl­Ñvƒ¸÷ÿˆİÿÌ*ÀWT ¬¾%0Åjp SÖjÃaÙ%©è(\N n
\Cë*œ9PXV²bÑÔ–'SÎwõõ£‚,¬X/š7VÒşÏœ%>óĞˆ™_‘	Y÷+¦'ßá'ìáÆÖ„³¬~Yã,ÅYŠæÏÍ–Vt	ÛN•?DÙUÅD`÷Z®N‘<ã`¾İãÅ¼h5Ì£UÜˆøN¹¡•±µ›è<×é _Rñ’Ş]û[eÄlD’3lï9š†¼¹Æ(‚‚Ğ¿Fw­O¤:I÷²eçkŒí(¿,œ©TÔµ·:ƒ™½ãşÆ&\cö»g<cÛÔş`qÚªöC¸­Ú©Û ’ÄĞaÕi€c¢î˜Q&ŠĞZlNñ‡è¨>U¦3Í‘{”t·sÑäŒ6†\´¢ãyXüªÉ#KÇsC­“É‡‰ôZeÍÄÎÓ¾ QOƒv¼Hœ5ıFİ—¼ıt´ßTÕ¡¤T¥£'œü°E2^7‹"ºr¸jÉ+ÚĞ¬;ÛNÃ& Ù-Õ~
"ëeŒ4"E
„=2H.¢8Öj˜Vµù-‡ªyÖ.‰ó¥KÿX:ä±©‚ö6?>Ğ:FûOuë
Lù›/Rã.¤ÜŞñpºåàRJëWaW“ =T÷6“ka
³ê¶Î¡Œ'|h”û²;¶jz­í^‰uW|ã
¦gf¼ÓğÚ¯" ](b)fg9-QŸâßgœÏ-{4e‹M:!6±ÕŞ‚ñGH?I«I`*œş&ÏYW®Px—ÄËn(Gnœd†¾bğ­ä<.ô˜4ŒÍXĞZk½@U¹,Øk»t,€y)jt¹ À)ÇXÏõ¯½M<ÊPÚñ•ı^ùÁ³;zsÏì¦ï×uIYœïT==Jq€S@bƒ5ÊÔÖ.’ªb À=¡f}xÂ=Bn k%À"vq6Ñ1|™Ai•æF¨2¦«‘3§¸wÖø‡|Š•L¾z-#9²ñæsò-&+Ã“$N„e“n°êà?êã&“H}y	Ã$r©ÁgÏˆŒPgïÊÖÙ™jòHĞu¶
}9Ü–ŞÙæo¢“İïÑ8¶%¢‰KF ƒS1`b—Øö={h'p<ë«š»ÏÜ3ÛI‚–R…X*S3…âN, >7û™Ÿk!ûT[Ü¦5¼!=âO(ÕtÁÆw×Ê<1
O1áfØ¢“Õio²Ä4´£c·ÊÕzDãÒ\]r³°ğT½Šî‚'èmÒ¢Y)î’¿ƒnjš, Â>Î¸‰yuhU^&ôLš¯àÏmDTXâÃ<5ëZV“(jï‘-áh\Èß]¥Œ½ÅP\·ƒ<J*ŠƒÆ1tJe‚,¾©ÕÊUßSgÜÃq$Gïsèê®—YÃş¦8Û?jó¤¡ìDº÷9¯–‹G\¥}8#xeKö©*ù¿®…h0µk`ªçÈk8úÀà¦p°‹Ùjß/V^í”EE=?W7Û)‰×úo#ã¼«KVg)ş©ÕŠ»Ãÿ;í££)û[“´gH=´slŠŠÀl”Qv•”31ã;İ@/^wŠô€4ª4›ámqq4™W0º`1ñ
_eË#å”`wÖó¦öf/ÎeÂ“ÛÂºêö(zT3 kÂøŠCÆÂ2Ã<o?‹PéıÍŸ9Œ”!|ª{÷çõVı!­İ~æ ğ!7İ³Gì¨¶aOŸ\+7ïi¤¼fTuÛÄ&Á1dË<;ÈãF‰èÓôL¼ìO·îª:wgÆšıá&ùï@,2fDFÀ¦ûË7â(¹ƒ³à`ˆ`?¼ÅLe|ú6¿â—ìo)/LÀ(Ïú¤_!·)ÛEkXÄmèyÃ‰WYj¸Æ7ƒ@¬1ÙRPöÈP×MRÙ‰`®Ø»ZnØ%Ğ:İ²ÉÄ«´·“w,~Çüen‹ĞH,DBWæ8—Á÷%X"!Ş	0Üv&gÏt>~Ø¨f(£ZÖ2¥ÛŒõhêp%2Ø‚4ÊlnI"·L;–®Å„’Íáµê#Æ
¶RÜåXR     uı½®§½ ™µ€À:*-±Ägû    YZ