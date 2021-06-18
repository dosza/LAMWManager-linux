#!/bin/sh
# This script was generated using Makeself 2.4.0
# The license covering this archive and its contents, if any, is wholly independent of the Makeself license (GPL)

ORIG_UMASK=`umask`
if test "n" = n; then
    umask 077
fi

CRCsum="2850748747"
MD5="7fefaa4fa558f75be8a3e6d030010f7d"
SHA="0000000000000000000000000000000000000000000000000000000000000000"
TMPROOT=${TMPDIR:=/tmp}
USER_PWD="$PWD"; export USER_PWD

label="LAMW Manager Setup"
script="./.start_lamw_manager"
scriptargs=""
licensetxt=""
helpheader=''
targetdir="$HOME/lamw_manager"
filesizes="22800"
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
	echo Date of packaging: Fri Jun 18 15:40:56 -03 2021
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
ı7zXZ  æÖ´F !   ÏXÌá·ÿXÏ] ¼}•À1Dd]‡Á›PætİDñrì¢Œ~èŒDÛ]:ã1"AåI™Èï‚Büğè½Ğ¯:Ì±f¢ª^0÷J18²ºÉe[×Àç~ıÖè¡C0³ë)æ‰ºÉê øu½¶Î~ÂÃêvá=³W‹ß‰¢(Ïù×†Wˆäİ™¤üÙÖ7@ØCyO",WÒà—k8¥Îã¼îÜ&]ç²¿7ÀÕMYÆ+vzb2¡òÌ¬Ñ—5B05JjÄú}‹M"FÇÓ£+•;‚RÍ º©Ök¤í•Ş¢şIbZ— ÜÙá>‡ëW¦º;Ö+a½ª½¡Iõá`ËˆÍÎ¦š^U ¢*+·Í˜wş}¹âìGd´bëô…µœÌ4Áé¼ªæîşµµd†WÔz34nx+ê1„]"È™ö†Lñ¾ºŒCX©Æ›Ûä_Ùh2ú;Aá$Ù•üúWÛŒ @û\M7‚CZ]æl8èô«_6xê˜Mò¤‘Pï$aİmBÛ¢Î
ÃTÈXxêÎ»Ö;Ì(ÄÍ›“6ÒˆÏræâS¸v^UÁµÌj&H…Î´x’‚¦öÓpÅÓ$úe•lNõ’¥ËĞqÂ¾´ïØsÁ>âq9X0ûÑsFh½(±EvºĞ/J«DØ2ñ‰İ7\{(šÎ cb‰@967GÇm•ÌHm0ºñíf°UVN€¹•?bR>€¶›2ÈÏY¯¸³d`Å`Ù)‚Ë{ŒÌkæTRæ"ëœ*’¶¿fFØ&– ;`©”¼ÍÖLÉ¿ˆúªúq^»çRdòá.+nl¬×+aJÉjMñ mô¢O+…ùğKÌJòzuxçßkï‡-Ï’{w>Æ*4ÆÀÓØê„ÚLOØÌÅÔ
Â>„&ê{7ºOqÈÁ˜V«{t‡»wK‹–ÃPÔ/c|-"âã]UÖx±Ò a+Iå½è+LA¾j9ºJéb4†°<ht>\oòL&ñâMıÄ@ïÃ[¾.î&íª?Àf£ô‰VÅ•÷@†õÑk³İµ=O`rRúÓçSü1œà”zéN3"$­
g¤[Â+m–ó"?3rS!¾RÛ,}D/=€Fˆ“Ÿi·åÄeX€lµÅe7 ˆœÿk«Åã9R/›øSÌ³ÖfzÅdNı4Ó2u­:Ô\K?œ&±aáOşÁvB‹¦j0í`k’ÈZ©éº‚¥ÛÕà"İq*d)yØI4ÊÎíë÷pkÍÎ2eÆ_³hOØÆöi*y&^ì¦'[Öª½v}-m<´òšî§gL{¼×¦N„$ò-	Ş:.(¢^ƒa;¸(W-`Ğ1àEÆÂ"}pqÒ‚¢_¤ï-q{qš`jçsò­o…«gñG›‰(œĞbÿm¼„3|	İ)ø+æ!J»m*}`waÀ‡U9£ŸIqQ÷†Ì1*éHWwjµf¾ ŠáÚ–Äİ‡é[/óAšNÅ‰Ò…Aƒ|¦Q¡	÷ØÎÖ¡mp(µŒÒxÈHû¦{ GÁÍ´øÙ¸1(bb‰]r¸Ö†Š˜3%o-€ßß|kÅu¼1ó¡¢»%éÀWCRç”ĞÕfzÙÖIo–¿Œçya¾ìÆ'"å^mi—nU]şåmj½‡4—ñ~]¤ØUQÂi¬ŠøÎÿŸY+º°ØŒ’R²K#`okéÒŞª„cëÈ¼v(‰V9AwÌÿº<¿IßıcL¬ıïk’g/İİ*bn¡[=°XZ~¢ZÏX!«”øæ…äçÍ(\r…ÚÍWº¥ñç¦­)+wõôÿ'ú<B=òIXKJH®òe~j–Ù–GÌ‰G ê–Ñ»Á+Yl¤ºÃ€‡õ‹ØüÙ%À8ĞA
°\½LÃ` v=d†·`ö=É0Ñ€ì³2uFÏN³-€¥ëìB­€P¢†°?–SAÛö9š4±"Å—¦tçvªú¼ƒ+aMk±'‡KŞCñ’ìÊè;Î„ìhûi`¸b’j6ïK‡gçÕvMUÑãÚ² 	áÁ…FvÇm·°:±³{lúÂö’Ü?¤c5féˆyG}	^^"mš› b#¶+Ñ9-ó=›»«5…SÌÕŒG´W@[âÎÁy¨ºŞ–d1˜ÆºĞk;yİòˆÂÏ%Ì˜¿4àô»vïøD‹@ÂşõŸí?F~lL¦EÓpN¶n¢ÛÛ´ÖRìjYa&=¢ ŞâU”zŞTMônâÈÙõ¯O¹aP´ûx"}Kçõ5®Läğu	iºÚhíÊ{–}…¨SNôJ	H˜Ô1 PºK”sÇÔÀJWÇ7ïæ`§4’Uœû@3^‹é•Ù|®0Ó:i®ó?ˆÑÿ‹T¨¢—CÔ0úeĞäˆòZ÷·‚SLŞĞšA^'üX@\—xğ ‚{™Im+(eEÊùŞ„+€¤ËFIS#cTj¯³TÈª{p«øóF‹Ÿq´K×iÉ˜ß€ r«©pĞúÿ¶b{¾Au;ƒıTG«mËyU´s®\õ6Ê—#ùÄ.Ü ïº¾Ã&ï‡«Œ˜ŞùSî¨kĞĞ-ÖNƒ®& 9àŒşm>Y˜ÅÙO!İÖ©m×áÒ)Ğ¦¶N…Œ¹\")†X• {Eí¹yFZ=ÜŠºc?İWÓa{Wp$Ï2/Q”¶õõ‹ç8xjwÉ,«¯ĞµØŞ^<×Éá[ïZm,úëÜÖèë–f£0­’Pã“ôBÂîŠÆSÌ³2¶©	°½eƒZé”j:«-6ÊA]B =ÓãWˆ5’Ò3 ¾	¯<ö•İø0	²T–©gÂ¡¥r°@*¡†zlêk0š$øıZJÆ\æAlÑ¹pƒ5Ì‡deY„Ì d&ôò¶˜~B©«Q›`/šœößj&¢£Q…K5MÊ“N)Çk„3ôhùS”ßåÍtŸ!n8Ë\*Ê‰‰n”	ÁÁd'9±»Lc¯ÚÛ^Ô;V’£c«nXû<&Òı`ØÅéïÊYBØEye^Qÿ:k½üZ×QÅ}=­KëçAh²„JšøËøùª¯_WşòR¼N`œWø•ÆaŞA,‘*×ÍöÑ–àBÂ,Y°¤¤ì ­|Y¥©ãw£b…\Òi±óÃ€'K¥ïj¾¦˜g¸”%#*MÑm¨#5£ÉçÑ4HÔ0Åå!3²ˆk}Fñ'o¦€L¡ûÜú¾Ò\ãmëºè05ã®)ö—Äù`!@ú´ò³¼H.C8Ø×ãU1¥"şÒö¹#e¢3ëOLÓ‡[j»BÂéÙÓ¢Æû9))³n|wSÙEa™Xj‚?x"»\>— )š¨ùh‰ôòôñª'h ìÎ§Ÿ5O›TdSó8Œ¸¾'Q'`Ïgx]a‡°½8 ¬¡A5¬¼pÙ xí½Æu^EèqÑ9=ÊĞ%àˆÆ ªÒë¹”,‡J·Ê8Ön£Q¼Şqfµ¢ØµGm·óŒ­¶¨çr3ã±i¯so4Ø°á+åKÌå!ÈÁs ;*ÿŒÑ	0èjT5Çñü&„8cŸÆ€±’¦ÏÖÜIúÍÍë—µ¼…š–Kkşî l÷/¼mU(¾XŠ½“ZÅFâ™.LñT[µ¬!ìÇJÎ…,%ËÍ4j@Î;äÇpÅŸjèpJ\'<"4S×ª=iêâÕı³gÍWË\9«/*#(iÍbók>¯®Û÷ğg2Dµc	¶&‘	‡ÄÚÕ’šu›«†ÜXÊñ©ÚóĞ³œ´ó)ô—„8n9 ÓJp¥£¨s}q»»ø“rá1–gY¡/I¾ß•÷OTèñ²ê³X+v³Ñ«ˆ§ôß‘&Áˆtc¨öÑ˜Ğ\)•WcºØ©¼!yp:ìØš€rÔ¯µ!¢{¿xà´å>ƒßÊ:!IáU“u$:I\-+nú…İ»p„×íx³R<®"ÄzÈŸ¾…1ÏáÎk§¸…ØÁ8»i¼Ác”ÎIW¤û[å7áë›æ6•¸·Vî6dÖG¸µë[_’'9Nlù¡-øİ³61n»û‰@OËv®!Š#Ä?aEqŞê#©ÀÎµÈ·HDê7ö®½ë¼«9ÒR}©¤œ«1^éjÓM`xXr'~ğ%0q(F¦‡q6'ÖŞüMè“c‚ÂKûwR‰íh…õ"åëS@Ëvô±şŠ*î‡Ïøı» `š€¹«= C
ò~ØÀÓ»ï”‘œ>É(€(;ù"_½ÈFÂ	³`ZIçæAédò	áœ¥ö\ ÍE<m"ïW=wÕuĞ¬còr3ŒLêÖá@|‰HÃõ—·‰¼„ë¥¹‹Ô’TD! Xÿ°ê‡Â`U~R[¯K¥gkŒ–0Î¼±*Oä‹z¥Ú—Šıì«Ç#o(ÂãoLÈí”Ö¸]}¨ı©Åj#ş2÷1æ~r@æ $æ$OFQ
¯UOì¯ò„ÊªÌ­ÿ…¸L¾ÎH&MG{¤PÈ+}=¤ùQ'CÌ¶6 xûQ„E»E×OWvRX–àæ_°Ïùãè¶{¶?Äş7§qÎQåƒ‘U"ıwµo„@KÿîùÀwnx²KSÒ:ìlXr1d¼i§hÕlOg‹í©ğ¨×Ê›(;Şª~÷£ÊéÃ±½Z<Ò÷¸ÀDª9R~Æ¯Ö¸—ÍÇÙŒû©†‰º·ÌSixÚ²ö“zah…Ù^âŠ1ìŸÓ{Ş¾6E2ÑçŸ~ˆÉÔ)ÂûlPùÿ¶ã“Ç5]Æ.ÎcÌ]*“3ù÷f2[¿WLŞxw0\ãj9E@YÉê3áHÅö`ŒsK_«ºŸÉà·àêRëP¢‹…n•9Jäê*óaÔá ¦pÀÁö·áÚÊ$ñ±7LôÊ?Í]‘±EK®ø¸Èø•lU9ØºF‚G¼Ñ.!2Mq	>kƒ0fÒÔ+;\ª“4;‘
•mk&F»ŠòólÕç‡½&ØÛm²Àzøáç7IWÀ…Sq5~9Râ)^­Ç9ç>Øq¥•wàØ@èRl ƒ”äKnÆqØèöß{I¯áÔYp®Eñ¥­'Ómk-R*·ªÊ@6Ödxûqüäı§!ÆÔ™a¤*ºÆ`ºö`B­æ%§TÌ‹Ö…loàÏ-M/r<1TËºó?{ÚaæÚÕ
1ù²Êöø|
¦F£å’ÕÓâZ\şù>(óÁM	²@z|u(7.û`7êv«ÍŠXŸ} &
«¸ÊŞ¥¿·Ú®§Ÿıµ»=¸D"g³EŞ¦ˆÕ>)ı7JÖãŸwmº‚VDÿ×ğNã‹´0rÌpåÉZ®‡ˆSïàw•yÕ!5èÂêïPª2ĞGÌa½ºïêTf:zÕ\“,f›ÿIöœÁçø|‚¥à(BêÁ'×’»Ì#üçµùP‡Å¨”²ñ@ó
C{˜‹¦q¯•)¨Ñój(ÒM²“¹=È(A¨÷µlkºüÃKJYUÖô9ş_íYhT~[Æşê¶˜†*ó†Z(PÀ=|ş‘2¼‰Õøİo_ĞÙ5ç°t¹\°ÙÌ®¥ÀIËPZ½jµñé÷Ùáºtß;îÛQAy€†Í79µf×4ÖÓxíöÊãm·ğf*X1£o/7nóu‚•)÷‚: kª®;8ër°'§œÊg*9*×&”ÔĞ/­ëi‹ˆÙ»_•áó¸Â“8ŠCEÉ¿2”èc»]Ò›?@)Pq3ÓÃyêÑCöTŠ•ûóù¼~"]RµòHÅ£9Ü}_³É‹#Ğßè¼7ûáÜ¨Ü™ÀHtY¨âÇE%5®Ká›’ßå3]³
#_3¹ùOÖUÜÂ«™Íf¸99¤G~œ¿½ùòæJ 5K'yã6Ìi½€ëŞ¥FÂ98 ä<íöğñ”ü òÍjİšÏDœGâÃD–ßD…OV»Là8¶j ô‚´`Øë§Š¾½…o¯ª©<Í#´,ïYq¾şÒ†mLĞŒW¿Ï¾3tdyg¥e6fô[Y¦|ã~©­×ò„Vrğv,ËEÇäåºaİ:™˜\Á$d‚S×è˜d+æÄ/>mîò°Q?H
3¾¬ëWÚò.vºå°´RLyœ½”K±Lfù¢RbRÊS
yÉİP¸óQ<W\ÖlÊ—ë¶EÛğ	ƒ†±?öô¾7ıüZİÉ=ØŒ©*I“Ÿ—!Ã«ı°æCèşX‰’¾Xnz“Ş&87ÿTô“(=ÅşJæOaşÊÇx|ş€eGÔLÜËØ'L" P¦¶^l¬Hä°Æ@úh²tG‡?‚PP!pÓóKúRÉpâñgoiSĞ$KÙÏö
ŞÄ©’r¿ÏgÖVƒ¶†–ıABk-jµ:ê{pÉN@å¬×'v‚§ó&àù‘eE\àxÃBšë/F¶2âQk!] àôŠ(OtöÏdhGÏ¯3ß¢Íˆ(ÑïŠH¼ËËSuOÅìòD=¡E‚6YBB\¬G‡¼1xq%_#A9“ÿ&¦'&šM{è¾-Âğ—=(¯Oêˆ¡Óf8HBVÀ“È×.W?¬Vû’	5	–•nl£Î¥†38ìĞµïJxÿ?öqàš´ã]ûYWû“³ì‚Ù4ON
|Dú¦Ë´d$¨K»õ8äoÆñ™Ø¯Ì¢5¸Ä$úU§‰]TW gç|X¨>xJ¶‚Ì7#	_ta IóZ¤Iùàô‰SÕÔFL$ÂXV ¾‰À+oœÃÅš\õ0@ìÙ©SÑ­ìr’U¦î§jë§ŸÄÍ÷N{Ø¹êsşY‡®û“ Ÿ|So]‘|a”¯ùY¯é‹ıµBÑN©ş¿±âÎÓH-Áo!œ©8¿§òp‚!^ ö<Lµİ6f;t hU½ˆĞB®FÅflç¸£õOAÎ3íåº;[ÑË#½{Obu{Ô"¯ ³"³*x´UáºÍò|<SÓø=€ŸÖ²IòA…0uÎ
g—”cøŸBú†&¡[ˆ«¦‚µyÜØqàª;çÙÍIFm‘V Ø;'=j÷LµÑ5 ¾¿“î}o)ı‘AOµI9Z—ßóRôÍ‘’(•"N:QL,¯ÆÚËc+å‹™ÿj—ìá0uö-0,à9†kçÚMô$ c’òÁ¾Sf†p7Öß²û.3ğH¦¥|ÏëÓ•JŞËùñ ¾M-’¿çs1rÛ¦›áqM9uNûewÆFÈëú¥£?û´8ªF—V’(Í©‘ÊÔXIEV½oº—}cñ'Ñ÷
Åù«ÀØ,I¥5nŒòƒ¾ô¡».IŞ«şµ,»[ÅƒRÃ¹ İ3[˜ŸÁ Ùe"æ·iÒ¦}{G~{”!­L‰˜}£“YáŞÙ‰¯ÖªçÈ‘¬ÌN±¥"áY¦'º„‡èO_)	“:î¼%ÑN—„µ¥Æ÷ÆB]K%WöŞà1²¬M–ĞŒ\Ëq‰nÓQY±âd€4ÿNqúËr/Y‘ÖŸKŒ­±gÆ Š‹¶D“ZC²Òñ“FÛvóş<„’Õct¥„Ï.7áëzØ‡^Ãı­V\V¾Õ>˜ÊHÂƒD¤€V{¯˜Ú‰2e-v“ñÃ¾®4È* â²bŞ8¨àŞW2 æ™Ü¾ â/l)F¼ø3zH{iÔ¦ªAûäzz§xhíôàc‘¥	 ZßèSf#Ÿ§B··EçT:½*oÔ©¼­¡ŸCGß~e#¿'Û%œÒn*ÉóŒ|©}ñ4q}D>•o»`5ö±3vçòBÓ)GVUVÄ×'±ÉN9kV…BZêŠ1ôXQª—X“Nû9Ú7<»¨­â¸;²£Ü¬û	ÙÚ#„â¶12¥ºtd0H_6¥uˆê„¢ûm¶¬îÇA‰.ltÇ¶’©\¨ûC„àŞ×ààV8{a¿o’#P£{ìjKÛ‰$¤]ÇÎ~ÊµfIÚÄlrª_K¬t
bï-² m¢êåöš›!®NZAëP|RLf|LOê¹JÉÅ˜4Vãâg2S.äz9æpE°¡ü-ÀZU>ÓÊêïU.^€%]$dãl+Ãsy> îÛcµ8ª×Û¿K†[±Nì ±n6uÛ37üĞëO¢dã=¯\©“7;ñfíºV³\Xw¸"¹©ü_«rÏ*hä¶ÜÛj—ÜPv»ÈÎf~‹ºhûúKš
İÊ³øïRy6ª$¡ÊAÉ!öÀ|`Œ—Ì%_o¿|ÅCDx°§PÄ¿¦¿»«vá8òYK»fQZ^3ä2Ì'Ñ«±Uåú‰a{QãboUŸ¥"|ñÏ(õšíİpŠ‘GsìË›#rKr©$ÇƒŞ[t¸’|Ö|?ĞäÃ$,táãi"Ûã“¹ Kô
§laï¯Ñİ— ¤$ƒò^S‚fW¿HÅGQˆ-âJ{ÁLÁ¶ã‚6O³°Ô®4FiuW˜WèeGĞÓKÔ?Mˆ]¢Ê
RCƒO¿'î1RÄûş$®õ†UÈ0*v®!JÁ"f6EµÌlÎ…dı¼à(môòÏ_"òä‰]‚‘˜M1§l¼à¡`{(uŞrÁ5çÉ÷´J²¹‰@† ”Ì_~¶ğfşó¸óW) J¾¥Ğ’x¡Q9¾Ñ¥ò±˜œÙö8>×†ûZö	™IÃed0µóŞ|#é¼d^!ì+ê]Ít· `}ğ­ùíR%f„]<¹	V:[P¥SGœš öiï)z| D>˜z½}\EÛ¬h‘2Ş:`ëß=DØ+ÁîİÎ÷Û}Ç_¨°eólª;y4fé†2æÃƒ×‰!9çVĞı§ªëˆ#É¢ãN¬gz	PN!2šIÇQğ–ºÌò%óè‚q\sMƒ•„ñ"H†×5	ÈVPüÏ)²C»¶”qçFú*1†şYjO—ºÂú,†¾Ê_Ï¥AÍm#·XÃYÖ¿¸Ñà¦ÔÔÂhÛlfj€$ŒÏ±š»ßÄ…3Ğ‚>µZéû+Â—)ÂïºO¹Ñ'×é”?:,/ò?•XsÔQõwŒ^^ïF"–Ôk¼âŒT¦ÈTM~“î„³@óœÃ"I' 2£%NÖ["iKdN^ßPãIxvÁ8X–Â–àƒ‘,]¾¶Ş¨NíW4âğˆ©ı¶£°)åNl­p¹!ş·eä§Xòh	Ú–QWÆçÙ+{şÀ¨Œ1½áÁÛ,‹[÷ğ“RŒ˜7Š0,ñLÍu:ZBjN|àÛb˜7Ø’#Ò€*<ã÷}š.¹˜0üvßp“½öz®ÎX€Ğû}À}|¤ëŞdç2,»îŒy±Ôí)ŞàÍU‰Fù™°2÷v||Ì||bØãÆákÄ$‹Ÿ×HEÓ èöj­ÙN¼çH±ü¥ë±¥š9~Dv@ôÜõ8·Pî™+‘…zÇ—}P¯)æşşO`Z‡´Ğ¦w¾ştü}1ã_²Ûd»sĞ`ğÉ–2\ÉùåÀM<„ñ0ÿÖ&4|£‡·í2LY—ıÁ6Úh¤÷ÒpbŸ=ú^	éZƒAq=ñµÖVÂ±ÄŸÌ »®é5dlÒ²ƒÃzR
5:úH¼á)Âöì¡ŸÜË‘æIÑĞˆJAßKKµ‹ëÚÆ–ôeÍOf“[ÊvbA6†¯4çLe¨X\i"ÎÄ«ş}÷WxØBì‰7	wÇ«œö§\e¸î3Åò%Yxı7§ğHœRË7‚ÂsÌ»‰ÙqÿÜ`æ«¦~ı­-ÅÛÊˆ©I™Ñ\€¡ìqrÉü@Ä„Ó`ÅyT‚ÀB‹ìw„Ûü~!µA97qFr& óÒÌOÏ‡`è˜uÌÜM–,JûaïâXü}
³b¼N)Ãÿ	 ıâïK¹™ä¹ÒÂZrÄrD¦SËqıŒkF¨©÷åÛTE;ş“>;b2æ×\¥¬½hÀíõ7ù Y§#Ú••}0<Ğ q°‹nÕ±è¶'hQÒ©jØæ½Åb£Ä¨KJ<eşbæ\³„¡íËıpŸoz˜Ÿà54LÔÊ¢,rï0ï«{|œ.{œ¹Úâ”UO±›ÅçÍh@Íıwôÿ	£´	w ĞÍ„+Õ Ü´¸5m’ÀT)Fgábül¾º`d\ãîfCû-+F”ÄLÜkhTĞªí¶	f0kÜ¼—å<ßl×¦µ]§˜?R+˜Ãak+J•f›t¨ÖÏ'év’š˜Ü]N	7lLš~ÓnrĞ„eúöeóïq[ŒËŠ:UZí¡ın£åÑ¹‘ş¨BÂfUß &ï¤|#šD ˆKwÏ$½z±Æô–†kô5oßÜ—éEPM=ğ}ºĞ®R#’ ºö÷şÊ|™Bjá2|‘ëeJÖËìÃ`ÔÒh.ïÂ®ÆßîÆìø°UæTlKÌÜ«Ba%ç(L£W}Á(¸ÈBé|Õ,v‡.Œh´]©r AH7§÷Ğih"°RÎc=_•]*5ßicømËOÎŸ §‡?"ñYšéÁvtÄšÇŸH=ãğR”Áá8ÔİÍlÛ7Í¡Î‰º¿Vÿ”»Qii
ûUeá]/£hˆÖZŒ{ÜHb$Üò
3âa1"—ş=°ÜÊb«*Ü£R¹Íò™SÚ‚YÓñT>Ås]ş›1~Öƒ4€£XîtñÍ\Y
,hôyå¸Ü¼;îÁÆãØp%$ôÔP	Œcı5ÈïàU÷¿¸oJıï¸@¦…Íi Êı.Mû ¾N¹Ù¦*s EÛ$PpÌ–†IHnRVtó®0¹dã¸~M¦9áÚÎöO(eJ}UÌFÃ½úE"‰¨÷ŠÛÚÆz´¶û{•ƒ»$*lt•–®4©°&w’ŞU­`”±8øãã;´
ŠäLTŸŒZ—! ?µjgç ?	€¢¡.5¿.qÚÒ~Û`¢°º€ˆw{k9·Á?9ÃÂ*·Ø‹öF«ş×‰†Ë{î`ê‚¡Ç Yml“/ˆSAŒ$,ÿ ‚ó ˜H´Ø³„*ášK•¾³eñA×5ÿpN†ÚğGò°’Ñ
Áò,€¬À'¶â³”×Mµlìs.Ò8ì¿~“dÿ1{2ÃıSdßBüÂ~9"½“‘In…ù²ùàŒòWi4ï¥º]©©El £ycí²3 ö3T•à=9.c“YPOÖgLö›ŒÊXbL©¤1ÏN¥7n–TC¡§©*Cç„¨Ä#ù'¨[!gÄÌäYÅ²Ú1fYHË\kMWyH†Pg·Î´à üÜ¤ŞĞ@,5I,=û#wé1¹Ü^W3I	¸c
¹‹Ä_qÜpÇÅ~tú;¯¿àø°?„\2+ªw/²=ˆ[i¾@ºî' 4'ìçSüfbCUYj±>‰ÊË3£D¶c#Ñw=‰ V(cùíw8q^ZÉæ	³	õ‘Y—È-ÎDB!ë5¢2·Kµ.ÍŸ‰¬Ì*©
ÒÎFa>ámÚë‡íE‚V2½42¨ld‡Ğ‘"É à1âKøƒ!Ìİ0DÜJœm1Xå€ZXÉB¥«Ši8J¶jRerIü«b Å~jD·bæÒò¶§tí¼ƒ®®HF=˜ş—Ï4,RÇ#¯4`QMaÇ#àìĞP(œÎ@ë—M~4®OÔìàÉj>)"xpÛxGR‘EÔÈè=Œ3¦„Øw%u-²Xû‘6Ç.T$Bï…Ÿúôóò9iãŸíë¤ Õ s<ìˆ¶+:“×Œ™÷G$ô2,èÆL‰§S{±Ç2›g*1~Ö•×ÖãÀè…NDºDãT%É¬xš†3$
I&™à´JSı‡nÒ`¯\®’I”
!«³— ¼É…şæ =LC«A$VIm‡h`#TzşšÁ±(´ÀıáÕIkÁà¦WBpq®‡R¬Mª­ïĞ5%Ö´Úñã…}§	¹¥òG%zµì.óÒó)ëSË¯g6
Šy¸Ôƒ#LºÑ\×ÇE»ÑÈ:ù4À´ôf~Èˆ+Šò®Â˜¶ÇlSDÒŠ„\Âıê§Ù¿6~v™è¸)µ¦µVÕ+ôQ¢à˜ôûğòï•åIR¨ncnhO‰ŠÍw4€FOˆ'é‰O@Çó+4ÅRÍ<	¸35üxÑ(j¹=ÊøjÑó	€ª•G-×&&ßÊpAwíâ–™°¢Ğ­âŠ–A6Æ-¢85MmBùuÍĞôÆKÿåŸÂ{ËBÇWìÖÌÜ®éüÓMè¢ğ^RL‰$ÒËGo'ªŠ<&*RPì€FÆª|M½m{¸Ö8s7İì€¹ÏÄFôv#yÛ…>¢¢L¹š<¬„ÔºùGHù cegAä´@ R[‰|!Z]C½ş¾J¢0ncäàd,ïzêÄ³x1kâ²ğàõ»áöŒ(í9Ve‡sø•™Í£Ÿ
’¦¤ø@‚óÃ°eæâşÖ;ıo"$Ğr5º1”–äê!¯~l9%B}gi‹í>aŒCõ¬-ŠŞ™÷Øvµè¡j÷Pö²z/ìÖ%…$Û›%‡NŞª«©äƒjaWÛªÛyİuƒ çAÓ­Ùs– Æ±Í„ˆ9ŒV¼á©Q–¸YÑKÕà_Z~æ)Ûä½¼?äU´³Ó5R›ü9ólãÏÀ^Yƒv£Y	Ş§O×„°e¢|­Èc¯—ÈÅZD=¨ƒ{ò®xÊj†X©NîÌÌf¤à`ï¼+•§²Ã¬ÒDú”
T^
miÌñDÙâ! ±É™
4¨G‰¼6õˆ4­¼^Ó\åußLÈY]Šıc¾6‘Üj=5l·/“ÿ
ó¿ïNãdcƒA´5Ø$`ıëhäbæÅí”‹Ä¯ (‹8¨²:c~!Dö]ÔŒş-È@9ÑI.(İÄhå!¹_QXŞAkÇwô0ø¿tLá¤%ä;~2¸ÌáÔ$D
ı;QNiëÄÃò:„öçK•a¼Àv1`†>HÕş¬€³æ)„‡ºôhÉfˆú©İÄŒpƒºebÔÿë, ]Êÿtñ—VL‡§«Á°™g»üŒÀ Qq7ùM½‹¶M'³/Û¨!¬3øFzWwõøó&’é["Û8Æ¡Êº+xQ_'b&Ú?ñvÁe9’¬·|q³¬g{ncÊ=fê‰^®âÛ4C@â°6’ºk¦"a{ö®e†İp”D±Wg@´9ÅÛöæYÛ¯şY=•Eù¥ªë1‚Üh-Ø8uÊe*ï¼şF|nÇË¹ø+±YˆYJÜ'¹¸(Øñk*ÿÎ_­ÆÓ&ù-í©NİUVùº!‚,æ+I‹_yˆqÀò'£oúz™î7ÂFqåâØ”à_§ZÆˆÍª“u§è$-ÃYå™Lg_‹<ÛÈÙ9…™/š&˜îï§Bi¤gQ‰æÛŠ+áÛò½å¨Ãd6ÃÒ‡™Yã¥…ZÇ³Gş¸æŞ¾ój½$iËQ$“>œ²ï¶L•«#şè‹@¡1†k=brĞ»7 OÊ¤¾À&ƒ7´Bş[Ù)ˆ%lÚõtÛÍ]Áô}î†}˜`ğ“Ñ}ŒXó‘\f”ÿÛ"inzülÎöûÃeàaV÷9OéşŒGu“ü™7J/…;“1L–Ú’!(±PëmúÕ0ê`ïÕ1¯Ğ:Îô Qô 2Â@}­â‘§Kbli5CõâYJã,#bªÈ‘HÀŸêÇàÃ“¼ù¦v"·k,!‰Ú3«ñk4:âØ}-ó¦U”(Z(ª«PÉ¶Œ$üÆ;›•sj¼Ó{ÈÇ2¬¾›Uw±=¥™,Ü±
U “3”–y*‚ó€]
jèµÓæI¡ıFiº õpz…•Qœ¿ĞæìCOVü ó€ÀÜòÅúc›À|91~ûÈôw~ö\%õBğ)ôÌy7”šÈÏtÁsÏ 5ñ!İT¾¤¶wÆ•ÓqÆ#bŒØ"È\/­33Ün‚MZªï¹Œë&5œ
BlË[ÇJù¤”Rre²ùAïÒ´Dd¡Ğ)<àg†¹ˆíú[9:ÂZ9K¼˜¸wö_´+!KRSç‘ğ®Tâ¢å_?}ÏÜ¡Å®vhV‰ôU	RÛ›Î¡üZæ	sígßg
ê4V·¹¢CfK:X3üüx°ú>Jâ³^Ä±±¤›\=Ly¶Ú»¢L‡P›ySï¦û7Šÿ)e¤5MF:j^cS[ßÊÃ,|cuÁª¾³÷ï¤ÉJ,4ú›PÚˆ7‚©QiÆ&&êÈ‹t†-¿@çÆ›Ò6ëƒ2”YğéV˜?§Á¿N} ƒIv¸}îDû¡p‘M>¿À¤
©‰¬Í}´c¾Ûú‘²"Ê3–gh®º8P3:»8,àú2›åóº¤ôÎ{ÚÚ²`'DgÂÿ³Œ§æü•ùdqõŒlkÅP¢‚’£ˆñ›fÏ	ºUÕJqúy‘Wµ£MrÌÉë‹xQ×?¨ÀŸİÉ(ËùYÑk¹4VvãÄƒŠœ‹_Ã	J7ëŠ˜YYñ¥À…îN{%™¾
F€üötpnj8«-GYeJFş½Î8ÍÕ$Ò“R23ÑÈÙ·Z¢5<¡“?†‚y|}8Äˆ@{3ÔÈ…{–7y˜¯y ‚®aÒ)‰ğß–èˆ³%låÂvš½Á@áÏN7Ì’õ.=M½îš\ÄÒ†¸R%iï¼ùÛW¯y½­NE^`OŸ™×Ä¢¦Š†/ôÇOÁ—™1TÉJÄãÇVÅÕ8’yû BÎğğP¡ÈÍ['	K‡@Iì Â•‹­48æù-?)ø9«2¨Ï)†¡rÙ‘?|ŒãE“(u}6À³Õh‹ŞpÙÀ‹hs)]Ò×Ç'›A_îeÏ”'†X¥öS¶„?›‘ÉP±¹E‚3wP£ˆ-ğy²û28]FÏU
¥Í¸h9kümÄ[ƒ[Ûi4‹¶Ü÷zŠº•egVQ!GMõsW…b{Üº¿•û/¤ÙË¼\]²kSVÉ ¿yNì‡z3GQÛÖ¦¨´ı…x€7Çà¢Z%~::$z!õr+æ;ÈDÄ¥˜ul™9î°=}â¾+ò/$QtÑ‚’ÚúyşasúA®§M´VçË­í’„sæû¸Èr‡ª,œpÔ‡«¢Ë}…S÷Ã·ÔÉ~ïèáİ‡X«_@1Óº:a‰uèƒB´äS‡hÉ 1Ä™5Ò™y	ŠCdj–›¤>PtMJ —ic¯ƒCí€³?ËÿıêkáğmÉ–#¡y©–şÚ³×dDƒ=zT£Zš=X©Ş”o‰"¡¡g,—+”âê¤A^6°®´/â¥Õ'ãã%Æe–Ò>ô›>vÎ,©z”ñöœ¶Ş3%:¬Wµ>Áäq„µóßÍ€“Ì#_Šš5È_Mé2E·³(¶òÔgx¹Ô_õM º`—òèCEÂHˆ_<Ïi1¾=`¤Y5¤7}oÎ¨%Ò&ç’:ıÓÀÛ{ËŒ%ªÄds.Õ&÷uL’GiDœÒ­6%Õ<®…´Îğ¸ŸævÅK0è<‰Ào;¸ñ«¾¦íê©æğrŠ²@ÃÜ¹+o€(à_`âJ]º¥üQşşÌ<–»f9c7n¥›	–ÑfØÎçV_úyñücòÜšfUî]Ø3pV
ÂMù_Ë‚Ôq5ZÛ‚ÀB¦£S| +<èLÌÆßõ@õ—Ö~uwòOxˆ×v„³ƒ¾şÉqo^¼¬æ®	È/ıoÀ–”‹q¶áUcI¨2ñIì4MÍŒŠµ±aà“»ßn?ÁÂg‹ã®ÛŒïÈi¤¿s›3=E,	óÑ d]e$ä´¬É¤@RDw$ñ¾Éïh¯¥Ï·çV·aQÂ”ÕæWËO7Õæ=§µÛÆx•’ó±Wª¯ƒ5åª8×eC¸¾0Š8ª}mşo’&´‚¯c´º<[#ˆViˆïş7‹´2İ8Ü–ßl J%	/¼mæ¾ Ïnúj„ÿ?;±²‰\ÀxÜàuÌ½ïëíë~°ä_8nKõø¾h*—OWZ¯–A ç$Z#h„ÃÒôƒœ¶¢ p“İó2 0–Ç wÀGò9²Ÿ|î…·¤Ó4`DÛÅ¯d³w ÙD!£5¾¤Îâ©4pı)” ÁÅK@rQ
ænßMQo	éD»”ƒÌ^§ m	Ó ½™÷sœ&ëpµ¬ˆ¸£˜e“KÓìùÃÓÁ0$N[É]YøÌ:Ëóhıß‚¥º&ó¿ñ¹Šã÷³²¤K ÙÚrw&È-äøU1›&øUŒ%‡Bò†àV×|¬–±k¸!	@J[!0¼#Pò2Õ© ›Ş»8U«Æ?0)-õ2&­¬ãH»Q™l—«¦ "ÙÂäñÅ­«\š!jH;âf”¸ää{ÈøIñ3Mÿ¨l—÷î)åFğÑO¢jCHC–Çï-Dù0C‚ú¤Â;¹a{§P;İâ~IÇI;³7{‘\hsr$@‡§áE¶ùÒ‘¨¶é¥ÍX¤ífĞ'¢ä´¦ÿícUùïq7‹Œ}ÓÂt‚%F%lå§>à1\OÂ¤4…+êdÛM±üúH©uJç87iÍGÙLÏzşyj®…XJºQ8âwÃáèÜIÄ/ùGˆ)E?u¡†ä&9{Tì÷W½˜ûVt¥û,Ú\µÙ²lô^pÙ7yMù?ì6¨é}¢]”D.%øÀ‘bËüÎƒº¼×³RºÒàûúxÂ¥ ÇÎH5F›4E7ir¿ è©' b`%òóGRâç¶¸Ô·Ä_ÑRØå,Á¹SÒ›Šå÷¦¤ş‡–½záX ?êª)dJG¢Q¦Ó +ù|›m×_¿ÀCÚîW„iiöôİyµUó%Qêtü%tO²)2®B´]¦Ã±'Õ_„±ô¥xf´\+§b½÷~÷ßü˜â1’*¶” sÕä‘–ÃôèU¿-0àUÅÔí,$cNÙùŞ‘ì´ŠÎ6èDİ.#ë t­ qûf KVZ9D™
ÅÁİdz¯]Û³Ôï`Ÿn‰²ø …å>ä¿%²Ò ¢N8uXşOŒ!J:&eíÑ®//®£Ùyîş*Ññ}Còƒ; ()p»[!W;AI¶2%T$
xšªiìØl^Å9NáÚ\còş~pö
]É¥“oyK0œ¶Ì8.|F¾&j¦¦u=Òùş™ûmí-!4Önş•®ıˆ‘Ûé±nZÚºÜBrÖ_^v–MT1ò?Q%ñÇeiùÎW²ãvØ#@¨†¢ÈjĞh32?ç”×OˆAÎtkØI¤ïÏU»ÌÒú±D÷zy$§®¬’ìC)$S—rü?õÍ{lû<õ¼\©7ÃêlCøo¢3ˆË+xU9’b¢Á­j….>à	 8Ê“(³”şg¾KŞîqí4ÔZ-şìnóèÅšhÅ(5»w<B?6ÛZî’×GØZoù³›4è¬.0Ü:ƒV¯PìyY}¨â-´Q>Ş;:0ª/†—TH“‰ß‰tó{`ÄLtí»©!­¥#–®§_W4­Š¾¢kNŞn±(ØÌƒÎô« h®(ƒ¸,ŸmfáwN¡g‰´Ö¨7T	¯÷õªÄÒö}'ÏôcYñmæ¹µ/¾0@»}…&íÊÅ<ênÿ™{K~ê\0jTÛÅ÷ÍÉÌ>¸fÃV±ZÈ‹…0˜BÅ3vÚM%àÊôò	{Ÿ¼Sx!“¼Ãî^ˆ³A‰ñê‡¦–`áôà¹*îËä ‡zÏ¯Ka/ĞïXËN×÷¹ iVšß;è*9?@-×ÔuÈG,å6.ãËYàd8-c0c6áéÀ’3oaåšØ”Œk´êå¨{a!v0h‡íLR[]©DÜH'¶«Å_«1+¡µoÄ	0Õ¬`µòm’ÒO|@ )ânï9”‡û–níyÙ|ø:å÷n*A©ÜÀ2QÖ³&Ô3­6"XÃ¡–'×%­cÉ×2?Ìé†ŸtÙ=ÿ¶jodö/?û+Ë±†ÇùEõ“GıQ9ÜMIÀšu!ö¡\ío|2Şb—;î¨™šŸ§ÂÅùé¨a~œ¼„—öÑ™ê -MØ"Ş;—F3SÊµş¿yË›¯0ü¤ „l|uæz
©”{ü’Ï¿š¬É K?Eù¡Tù)‚„6¡ğÀ%ƒhHƒ(¦¥"LiŠİ`¸ŸMôÈduê¶ö;2ŒânÁß¾ğ‘e.;ÒvÔÉéâà®ñ1õíâò²YDoÚ2V|¶/­íøFœoCR)N	0U¶«Â¥®ojo2Ù0wƒ—{Î¿J°¡w=)ÿiSÁzk+"Ér.kôú€ yùÆT6^:İékJıQÒC9Ñá¸ŒUFCEÿf#$?=±‰æ©,÷XWJx>ˆ‡flÔWMF:zMJš7•ÁAJ{š!).ùPÃèq4¾KAóH+Æy¸YÕ¥à³Uf7 [½å`”nhK­Jèí("Kƒåµ¸Ø*zÁ‡¼šÎš4;·Ã)`w«¿œA§J¢­[@Î×ÅŸ=”OÉ%«·Dn’Ukæ¶ÓÕ Ì«âyì±zÌ€J;§ÕŞuÏ ¹chØÏæ=Å:XVV‘A\VPrRT#¤—Pdzab"ÇĞ“?ÑãÁæÛ’Éî¥Ì,5“‹,±à|T,ÛøµH‰ñ|ïÅdt7îd¹KøÔLÏdÙHƒ’5C2 k-“,•ş"¹Ëæ.š
—Ó	˜ fü:G‰ÑUÈÊAû‹´êS-uùÁUãÙ¸A‹·I!<ãÓP$íx@íşŞîş&8çf<d!¾ìÊP0/îÁ(ÆIïMKóJ‹ãÌ’
@JÜ´v¯Î64ƒ‹	ĞrÒ«SBÔ9V¦irèSŸ˜É5ğ* B"Í#ü·Ó%ÒÂ‘Z ”Îïõ×•ão÷×L®‡#:‡í¸ÿ'–ã&Wlåƒt*ù%Ğ¾ÀÀÎê¼È…ƒB{3ÿ§ÖÍÔğ…ƒ œœ€ú$L"¿!"ûÔZ±Ü¿UDTÿ/:“Â;£İ-™â_ ?Òv§‹Æ­Y–†Ÿ}}Ó¡"C1ß±Jö‹¸–54=ŞõØÂ¸Œ›aëõî&2ñ‹Œ8šª÷I¤ÊCê;*ÃØWAf™<î]Ïş¾ğ‘¾È¿¡euZu¤,_|6¤Û3çbš»•Hsù`æI­úó¨–üj³y‹I¿G)ŠF &3áâ[ÕSƒk·2»<e_“”†Ùqm'ñÔ¿À¼ò/
¤#êOˆ1SÁ %|í®*	‰:6¡×Ÿ-àGÊìY˜¹÷¢2†p~§`<‡]€à0’åÚº0ËM´0yÚ^èÄ[^Bó§oXÑßø¨~ÌƒqÓoOK§œM.CENE&G}9;4²Šm„{o>t¥ŞèÁâ.p†ÉôM÷ûùÑíKİ¨\Ã<“	ù»¦n¤xOÊöSi¬ØF½µ»];æj‰#€G©”ûr?qLGó6ıç±'ÊŸ(xœïÇƒW3òy	)XÿôĞç…†H·«²ëJóûAWÊøTuëE“Õ#™lÒ=¹Æ€Ÿ*>'ÂÃ£°0Øì0¹ _0§oÉ´ûš:,Vêiñ³;JøV§Eg[„õ ‚×Jél+7cæà[·Wnpå’â>Ìpi±{«ORH,Ì¿ØâÌôÃvMØ4<i¤;;C]$‡í;È¿•¨œ=‘k…”şÈ`Ğ1|€l¾¥Ÿ²¿÷	öÒîyİ»sWĞ~0qçSÜ=ÊèaËÑ˜¤ÑÚMåŸ9`¼Í°sY¦k9Äˆ‚
»×Û}ÎcWÌ¬9[VêŠ÷ñsıöèÊšèk,\şÅ´qFã=Õ`¢n)EĞŒ.7€x©eÎ@î–…åÓ¦¹Jkãjÿ›‡n8zvEB©(ÏîÒîI@¤A60!Z8U¯Û÷ÖwJ–å&¾âbAxÖ)76€©^…û«õ#Di—Â,S\=2¥Ï1¢f±£©ÓDË ÀJ¹S:Dm3K~Ö¿  zÓcñ lğ›Kª[(±€s¥ÈAuï¯³Šõ¬‰/ä*$¤ÜiÂu[øü½[º<{|m+ƒ‡Î	ŞÒNùˆñÄ°÷ü8VDÒŞ9[ĞÆÏMï·‚ 5¹kK cÑAS¼›İºü|SfÀ%xÁÈd‰Á%ì4$M&ÖdGx ‘¿œ§oªK´Bø\ÉÃV½:œ j•ÙUú?Caşxãˆ<¼t~M l«!´1«XAÖ_ë‚Ç{+eM{O%c™¾ƒ¦³k ]Ë>N#èô[„2‹µ9dö"gZ@Öïâ´ˆ @xHö1‰mM€åÕ÷GYÁÃÀ?ñÏwSüÕà…™ù8QÑÏbVæÆt… z7E|íÎ¿Â EpG?Gìı¼ÔÔ¢] ­¾Ty«fãáH„>Po›·•½€oøûd[Z`G:Á(ç¾‰ô.'¦‡X¿†Xá&±qü*3ãç ¤­ÒŠTPßş½ø+6£÷B)Ì,’½œ,‡EG%0yyšÖk¬¡°¥°ë7ü‚4^5Ìœ§•«[hôa™!êÁ’ØsÊôáUêÁD Ûf¥S–ˆ²y>z¥=r{^gİ;˜a„dÑêÏ©„:	ês&‚Æ¦jÂÉ@ÿÇÏ©?ñ¸Õ<¦¿¡f{1 ÉYü['JC|?Pò…a'ÅÕİV§Vë×+Qo/ûEÃR„øëï¹…šLë‚ÌP¡µ}R-ÆÌkª7§àKü]§¡ÂLX©–1Ì@Ë’ªxV¯å`âTÂ¯ŒæÿŸSÀ†¾âÈ-:.A3vÃ,øUPºè¸À”ãTëêó•å¨Ô™Tƒğ^¡5w€öû˜ÙuËJY©–ÔÀÓ(ºaÓcÒ”ƒ,aÌ0£2€Ÿß’, ÃÊq×äd\ùælæØ¿Ö±¿ïHg%,Ãv|®aÏA±õ¦µ4ƒëÇ¬kkøºY[‹
…Ë5ÍxÌAK¡hO÷â¤ÿ4¹)y…×2Dc%öqâ
²Ê²Ñö©üOËxÚKl˜¹ğğCRæŞµOo Ñù?6.À@2Ü¿¸¨I÷zÛ­9DE¸%$	I£ƒë4’¸­Ó°J|Bî%ÏpÇI}C5Û®.”¥Cú0şë
u˜àO\:E•9ü#H×Qi.õ+&\½iVä¥Òª¹;€'“VÊ³hHú”İ«a¿@¥Ç)÷ j×i«m	~CÉuè¶GRŒ•˜¹F¹/ŠJb`|ûeõé®Šİpƒí˜`ÌÆÜ$vx`X¬÷÷¡O]MV).¬í)Ó¡×69	npºƒıæÔè…³À¬õ^<=™†dJc Øš@¤Çl5\óXÃ*¾Æ¨ÏNxH‚ê¤ü½U†qæ	A×@_Ñş¯ÖS't(‘²ff[&vWü·†=Æ–Š—mõÈ‰ıÍü2£€€ö‹½G=%Ù{Şà|ííÈ÷ô"NÜøYÆºoB^ğ²ïĞ
 )BòíCF×kVıPÇæ‘CHªAPş<s˜pÁ$…ÇÌ1'Wtøôì'«‘üQ4Úl”W÷ÇrbåÿöÅl0 “¾®üryfdŸFëlø©ïSÂu…ÛãÏ‘Xñ©¬ªÔ££1ŒÓã—”ğzh.¼í"èÊ¥´:#eğğ°7æ°eÒT±A6¾šÈúPo (§vÍôÅÀ¯Dj’eÛ_÷ë1Í|OzÂI0)H·ÄKmÍè{L¹cÊí´jÕ¬®-dGAèL  ßL.áŸDxB*ÜóRíŞöu9©3ıïé«‰·æ‚K<o>ı—¸†Oìë†ÀÂ«cƒAWL²lø0Ùß¦±ˆ‡ôôMpn}|Ş±ßpnãşc\·1CP¬Œ«2´9K†9fDß'*Â5O ´?CQŞ©æm$íÒêèò'‰‰æ„Xr'W«§":š£¥qş™ØtµŒæc]ÿÇ9á¶5óêßuıŒk.fÎèj¼)¨x­à8âŠ;Æ_gŠS´ÿ9äÆ" Yà~^PÙKMË\j·šo\L1AÑ@”ôq²^äô÷U\ùØ|¡kœ4ã¥ëin½ñ:õn˜Pß“AÄ”¸ ªJMIÚĞé=Šï¸Z’^¿åµÜw¸ùS¤·˜Šc‰c•~ØÎrçÅğªáx•Gñò–^g¶yŒ oİ™mÆúâWÕ‰3kg‡/‰  ğHeDgéÂ„¥P÷Æd¹LìC½z?šèVhæ§À¢S¬æm_÷§+Ø@fX¡ØĞRj
†X8,¥ï¡êEˆo[íé£/Œx'$r½…7ºÆÈ‚WãJgcï  áfÑ’-å¼tÈ, !³€½Yãf<Î¸d„¤Àô¤w>Æ{óR… àö¬£[°Vy[£×AœCtçèÚã]¬—SEãPõ™àâP«ĞñµT¼>Qª­ Aâña\`nq¹d3Äå§Á}_u7B	u¸Ò¸üƒ?üR±GJÃ¹¬'[*6ó¤îÒw©¢t¥»øJàQÅy¾¾Åè•ÀC`ÌDËhÈPŠ ÇVE…R®V¶d•É”Õä‡Ïš©b‹–°ÕØ{pº£øÀpswM’K—ÏÓè	=[ô:-±Æuˆş„‡dã‚[Ê@<–øZzU“úvh’À­ÙŸŒ¯é¶ "Ó÷ñÜ*ûk[QÍ7²Mâù•:mÅZæ[–f‘à€r‘k9óä:Õ44óÕ—ÎvÙ+ºK«/ìç;ÓPìçV9»P$¥r D9¿P:ÓœíÔ¸¥mKÓü9½r¾ßè²QU{³¥¦d›ª%‹!Î3İí’<;Këéñ»(ÄyAıÑó* _•|
¤X=áš
Gšt€¤1HîÌ…'uø9Ğikıa¡1$Á^ö½º_ctn>‹+Õ<cø¡BWÈÍ^R±ÉÎ#€cstW¼Œ×G¥}Š…«ô/.Å[¯Lõ­XşŠq_ÑÃK^8dQ‰¨ñV'9w-=VVƒtFĞ¢—Î­[õëÌíl<ùÙw=}ó,èÛ¸Ô™ª®ÑğGîMÕQ0Îâ@LøL¢‹i÷;»N;d™ÖÉTş²~±‘)ƒ3Òí·Ç_),•"©¹g{QğZ!¹Á…Á~m‡_#>ıåøqıf¦˜âIÏ‰ó¶ÁUÅ—É‰(¢[(´NäO*?[7Ma¾—a¿cË‹ñÑrLÕXìxvÅ¬¾kAŠ,\±#Í’9±EñYxÇw`ıÿÇOû|RÃlÔäi<ëÊ†Ç“|„CÊÂ¨@ÀÍ—·Ê‚]ğ/b¨.]´/¹fiòMUı¨u[´3ªÈ4î2dÑ’âUšß¨:n ¿ZáË5C0äì¨…õƒøÖŒÅèÔğˆŸô“(‘î¦¹šAéÅÉ£æÕ¥7g_šMßu8nâ,DAI”»,|áŠ¤(±Á^ˆáòà†œé#§&àş°(t¦²rÜwÃµFôiKCgUÍlŒ¾8#ë×I¡Z ]	„Šø	X5.Â¤¨UTãoZ&ğ\k“AÚ‡¡óÊŸ¦¨°¬¹;#â§ã³\79¤j£»|áp{NÂÅ:;ª_g\ÒÊ$QÏ<ceÔ­`Dæå/–bóè f<@É‰m|¦)ö”™¥%¥¿% ­WSv]XĞ–¡&+Cu´Vbnô)f.Ã½X¾U 4¯xÂßÇ\gDáÇÙgá<Ôx²¬ÓXç3Q.GKŸ­DÏN—‘Â™h™?“M°±GB^Zš>º|U\^–	ş”v|†·µdqE}’“¹¬8kp“6\œ¥^­Ô19>Â¸Jÿ“6oÙ†
Å³M%+¤Z„cı…=¨lã“± ĞFg›½zÈ¤
°CœSs<;ÙÌm×$2F9½¡éNªç4ÎlÙÃ>œZÏòä“Éc W‘Ü3i~Á£hLì‰õuèº)¢æöÖ!ƒÌõGÃ^Ã¤‹ûwÕfæ71h¸?›Æ"¶pxÕÿæºûƒ¬.Â¨•±VLPJÍH%[«6¹$ÒÍOØÔş	*±œ.˜­•LwkdËc/&K¸ÙHmN…¬’»½[Sk
Ëj±Zféïä}.jûPizàS“Ğ‘îŸ8ccìÆ{ô…4Xa±":1ã´yI‚7X‚e°,®Î¯àiò7U>CqÄ®+Mª;kúi¶=7
ˆU}3¤^Óœuoƒ›¦LøA'/uDT–é `ó^.:%c./¤;Í |vŞEn 5¦¨“-HmñÚÙDÌM’Òşókc¶®‘¼ò¡]“Õ~á¦ª0ìhÕ²\q’IoZtÇVIì7=2Œ÷—©|?Í””‡¦ÿşXãÜ¿œšwòŒËË¢àB ßÂˆ}.ÀVëo”¶'¢ÈuÈQµ «Æ§rë2ñË¥ˆ¹†Ä½§p„D“b|R rE×.$¯z¡ßKìz7ØG-Ğ×§¨$Z|4«2ã­E’Îš$İÂ¡D±#L×áÄ¿4FÇÎ²ık#JkğÂa.{¹:‡±ŸjÛNëü@¶ELÇ]±÷ù¢XÑZ•{PëÖ˜’;Jà?u!_)›jñ“¹Yb õ™»W¥Ôz‡¶„˜Œ19Spq¡,óŸcuAÓ	èŞ	ù6[‚úÉÍqÔ lÛ±|²¯yˆ[èÌıÌ°î?Ëß‚{p |Ò±¯¿-ö„+äyM¼i'SÛšq<û&laë¯ãVoˆÌ»Ü½^ÛîQH^²÷£r8¼µ zfbÜ)¤Ñ’h¼~ Òîpç‹ƒ–x¡VUTÖJ~¥%”ç£”Ñ·'_¡î|¤ùGM…’"i`tÒ{ªsåO‚'æÖÊît•îM1ÑÅ>~g±ÿeõ«á¬sš²P°…ãq´üù/ÕÌ…$IöÓ­ùL§ÿ!dÜv™ÿå$ë+ğê8?DOjôêŒ_ÁÔgJÀéëáÖùï*ªòµnÓ{&eñÕÌ0‡ü£úYó>İŞ*ÿ5«˜¶–’Ê¼Á2/fWJê†hV`’/òË=Q8…·5bÂøÛ]û6}Ï£hÌ:õÿAiúx›qÊà¿5İ‚.&4$Pw©!‘;Üó
›E‹cíDuÏálïŠt$µ‚RÁ[IÎ8€nmH»•"`µNk?Tş`LÍâ;3fÓ¼ÿç1âV6”¬U¢ ¥Üª‡òuùUv!§^]¥2ı¿ã+GßU°,E¼ŒŒ0Ës¿ğ<VQYçÂ‚£Õæé“©åÏ5¨Ù‚êòs¢Ãˆ¾ík‡Ò|8ë6Lk/›àÛ˜é"f¾3÷š¦Ş¬Ÿr%»r"×u"(Ş¢µÎ	·T.¥He­Ü.l÷é	@˜í¬<pÀåÖäc“XĞ<K[ÆÀİpq{y2*~NO†)Û'ûıòüÄ«w^²¯pYãóù{bp‡[go¥2Ê\«Ú”1l¯MMDHÏgfŸêcÇØ2¦•<íJAÛ"~‰zÂê/çîıø¬zÁ–©È^íMyvuÓM¼^›Ô54ŸîôgQîX•­rÍÖé‰×ˆé"BA=À2İŠhÃµç{×6O¼d#f'7>ÜÒîîp±•Ğ¤´[êt‚Ïôü¯.^<¤Z„×MSO•ë“]fqÂ¦øú!T¬öÉ5r5Šy”C_B6Á¯c ¤%ksĞ¬¡aQ#Ÿ0h½.µ ùêÎ É:Èj´L	UµXÇj Cóò¿¦—^µ_åÎúGUå™§“Y±ãôŞÃbU&-˜‚D“m±j³Õ?ÕT7èÄÊµİ$ÍÌy˜Y)§R­É6ıùÔª°µ?¿sâğÃbjK:>®}ëDLÿ½î¬]æÃqúğ,Y”2ÖBá®|Xş+~ze-²<£¼Ş¹Åí¼^×±’óUÈ+g|¼+[I*9»•À ğ™h°`<»³ñ*²Û•S<÷ûÅ)ù¦š{J±LšÙ¹¯"~û¦:ñL _sz…6Ä·/£H|˜KO¯Lq2‘'ƒ½Ô×’Ë†Gùhš}£”²„JV2û(éP{/
f†IÒ‘É³RRÊ[áÈu¼áËf1¹(ÔúòŸH¦¡l0’Tê¡Ì2nÍ?2­]Y¶™~ºT<<&õŠEÏn¹ç *^ü…îFm|mŒ µs/³ƒ÷Lb»ô°”ºcËS#­9µÛˆ³ÜÄOİâ’y/ E™ÙôÎÊÇrª“ç®Nõ€OúÜñ×¹G+nûß1û.Ç~%0ö$Kì¨*‚¢@ÅÈ³ ö>Î1¾ñÓ°á í £#¦a @zˆà%mE£v  f(‰‘ê;ÀŠƒ?[e…1“1Îk8àèµêªˆŠ¡3G,H0m^v»ÒJåÕ4üDº÷ŠZz´¾$†O]#B)27ØGÙ!Wë[™$åà¡ wóºïìßäŒùûáâ(¹˜ÍğØ"ÔéTR÷úq^SÎ´È°Æ†rÁ¢"Ùëù[N]S—ÂºZ½öë.0?Ttàn¶hImÀyÌÜ¨.¨?ğÙz×¬ú´Y˜C4¥ÛS+¤DÍ¿C#FÉKà'$7£"¢³ªˆ¢(án£Š<Xñi“km/dKL§¤õh«…%uÜLÔ°îA&>Å—7º©®£qÁnÛR_¹X¢f­ÜªCpğJŞŞ÷€Å>eÙPnĞ¡“«<]gè(¼®eXÌ%©&UÕ}’8nNü-¸õ«ÕŸñ¼n‘\-Ã•e·Šª†C8,·Ş*º{)uiƒvrlÆç6wùVºsìÔ»E××®¡iÈX³ZŠ§ÖpÚöíuLÈô¹æ˜æ”ô{{¯kJq3Q•n2N—Æ\ÏK z¶oÁ‰gN ·j˜_CÖ 7¤)¥º…T³ä«Œ"ì`¡yİ§C#|?ær%×=·A”XMó˜®æ±-™›şVAa‘Á…íRÃö›4Õ|ù¦¿÷ó§Ä^j™Àı©œì´¥j“w¬“Ã)µæÀÚİÛ_Ü àğ,Lƒ{>¸Oí{Œ]€rÃà.V\›Hú¹ùjZY¼7;€«û#V¹xPè8…±I×Œ9íç‹«üÌÁ<ÕyD¶‡ªdŸùÜˆU­óA±EË¬ÎuhœtITJS¾•!Q–,@ıÿÏ³"Û<ˆÙ¶ úäTDq<ê$¬›™^I÷$*Š¦—’åì}Oïä],«… úAè‘tr³møLœƒÑ%ØKpÑa—Ùù¼X—¹]š*+3k¿Pæ7s^Î^lò	ÃÒò0^@ø¾9˜jòhÖ41îö˜WdŸØ¶X×s‹êù
Î€éüŠœ7~• çóÖ¿tüvÊyJém;Óok¼ûú†—çß?Ò…¨QÑb@‡ÿ+Œeîö°dX«Ğ¦%sÿÔhîhÂ—ÒjJi	‡ˆ±å·Óßïäh$
í”¯*=XåŸëd4j’Õuš®z=€R+DUµìÂ`{ĞRLTEf…"Y=°¼
ñÍh	ªØc•b4Sh	,¨$ÿ¼±&$>¤Vp"¨Éo=ì{eá‘¼’¼¢èÜÅü=6Ş2˜c¥Öeÿè&”©*÷™€©ÅĞÚoqÔÛü½6Ômµ‡¬7÷³[ºÅ ×é3h l*tD‘nÚØ{µ+ YP½’òë•æ€QËì‡<EÿİÁÎsûÖ5Ô¬N[àŠ'ámgñôt¤ëK®{M$ãPÔôe¤gşc¥0\ÙFüòß-fßf2³kêeÊ
DÜ	¾;CQÆÈYl”×@|#O5ÆâÛ Ën)“!CC0Gˆ|x bâSøc¼”ùûñ¤îc !{‘ş»yVŸb3¶¼¦¬,æD¨_ö*ZÅŠÃh ]ô€ˆ"¸Tƒöî\G¤Uö_©‰yªÓ{µÜ/DqÅ^JiãÛ¹„ÈÂÀ»-n€ü?DVjíƒ=Š)nó®êFHQncgç>¶;é®ÛlÃäÈR ¬EÁwÊÒ“N ­Féº5j½™~LîXî°$¯Eû—H€Sú¡LïÕœÎ<àÀªVãİ1}ØÀ¾5ıÅĞZãÚ­J"¡G‰AJzú.r$Â/9ÙmÛ Š2°øyL^Ü®[oˆÙ½eµn"ƒpX¼ÁÉåá˜)‚¶“N$0P‚ÖÒ>Ú{ ,xãÍ.¹öuÒÌ5½—ú‹ØÉoeG÷ª¾Œr§ àş¯ÕyÓé»Ó¾î³™ôpQãµŠšÌ]I3—ğÄäTª
ÌI&îÂaQ•Í09şğ^ŞVL÷|O2ˆ	ÆÜ¦\©®ÚÄ"¿ïs7
:Ä\€şÇŠ_É»,sGêfô|¼¤áH—G(5ºüÖÍÎña84Ö?4Ô”âƒFîÎúI3{nUsnúKĞ‡F·3üD¹â‘@í–jFÎ6ànQÁª	Y¹†—¾O¼EŞGÍ\İü„TL”%ëwÛµ®àY¬,g`Œ—Î_ÄÏ\ÿ7¢z‹,„¯ï¨Î<¶^9c’:@gˆ€Åpé÷\ÄĞmc èö·Â¢6rCùK2oıâv‘ÊÙ9fÌ.)Uİ»ñdÖ®r5I|R€TnˆŠ±ÛYõÃ/@æ9»¦Aq:†×'×#Œ¡g¥r`djÙu8"äªêºvAY×UŠúßŞ;MÄdÑw)1U(ÜÇ°ØÛš=Y^,ïHAÆ Ze|("ÅŸØ_j,È˜¾mSuÚ^¸ÓC=)òÛ6¦÷«M¥4Îb¥Å²p6^*¨£q€à¨ë5À0µë\Š©Ï\Œ8¨j§>%ÜÚãÉd»	ĞjËE‡%7Qi¥JLbã áqœ¢:AÖ9»´¼=¡^yÕV¬ß§é•¥É/Ñ¨ÒÉN3oï#%Ş)ÂkªÆé)k± À ;Ô'b¤°^Sën®sæš£Tœ€P
½‹[U ÅÚHö/\Š'"‹”=X£&;¸AÒ Úà#£8u<@è pkßØwR×ò@	â†ğàÑu›ÆÎbS?šN·@š³kúMÌ2¡Â¸ôY§æÜÌ½ÁÚ®t z¥kõU íGD#ÅDç=ËsŸdâæ’…ój˜Àû»HœTÇ9õöüØ»ûµOØ¦…fÌQ:ç×`ïyãq®Ñ„õÑw\m™—ÈëdÑ  ŞyÏ[ø£^pn{[ãÙ8‰¹$¤Ğ‰ŸvÆÀÿ6{ŸÂ™;ïW‡ÿs=P~7«ÅS.°   )Å]ÃÉv ë±€ğU&'6±Ägû    YZ